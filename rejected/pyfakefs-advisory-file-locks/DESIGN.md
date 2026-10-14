# DESIGN.md - pyfakefs-advisory-file-locks

Repo: pytest-dev/pyfakefs (canonical, Apache-2.0, 753 stars). Base 796c48eb (main HEAD, 2026-09-22).
Second pyfakefs problem. The first (approved-problems/pyfakefs-block-inode-accounting) is mount
capacity accounting in `fake_filesystem.py` / `FakeFile` size; this one is concurrency primitives
and descriptor lifetime in `fake_io.py` / `fake_os.py` / `fake_file.py` / the fd table. No shared
kernel, no shared feature class.

## Phase 1 - repo understanding

**Architecture.** pyfakefs replaces the stdlib file-system modules with fakes bound to one
in-memory `FakeFilesystem`. The filesystem owns the object tree (`FakeFile` / `FakeDirectory`,
one object per inode, hard links share the object), path resolution, mounts and the open-file
table `open_files: list[list[wrapper] | None]` whose index is the descriptor number. Every open
goes through `FakeFileOpen` (`fake_open.py`), which builds a `FakeFileWrapper` (the file object and,
in effect, the open file description: it owns the position and the modes) and registers it in a
slot; `os.open` is `FakeFileOpen(raw_io=True)`. `FakeOsModule` (`fake_os.py`), `FakeIoModule` /
`FakeFcntlModule` (`fake_io.py`), `FakePathModule`, `FakePathlibModule` are thin adapters over the
filesystem; the `Patcher` (`fake_filesystem_unittest.py`) instantiates one of each per fake
filesystem and stubs the real modules, plus any function imported by name that appears in a fake
module's `dir()`.

**Five subsystems and boundaries.**
1. `fake_filesystem.py` - object tree, resolution, mounts, fd table (`add_open_file`,
   `close_open_file`, `get_open_file(s)`).
2. `fake_file.py` - `FakeFile`/`FakeDirectory` (inode state) and the wrappers
   (`FakeFileWrapper`, `FakeDirWrapper`, `FakePipeWrapper`, `StandardStreamWrapper`) with their
   close paths (`close`, `close_fd`, `_is_open`).
3. `fake_open.py` - `FakeFileOpen`: path/fd argument handling, wrapper creation, fd reuse for
   `open(fd)` (appends a second wrapper to the same slot).
4. `fake_os.py` - `FakeOsModule`: `open/close/dup/dup2/read/write/lseek`, `dir()` patch list,
   `__getattr__` forwarding of unfaked names to the real `os`.
5. `fake_io.py` - `FakeIoModule` and `FakeFcntlModule` (four no-ops today, `__getattr__` forwards
   constants).
   Plus `fake_filesystem_unittest.py` (Patcher, module instantiation per filesystem).

**Three entanglement zones.**
- The fd table: every os/open/wrapper path reads or mutates it; `add_open_file(new_fd)` also
  implicitly closes what the slot held (used by `dup2`).
- The wrapper close path: `close()` -> `close_fd(self.filedes)`, `_closefd` branch,
  `delete_on_close`, `_is_open` (checks ONLY `self.filedes`'s slot).
- Module patch lists (`dir()`) and `__getattr__` forwarding: whether a name is faked at all.

**Test framework.** unittest classes in `pyfakefs/tests/` (base classes `TestCase`/`RealFsTestCase`
in `tests/test_utils.py`, or `fake_filesystem_unittest.TestCase` with `setUpPyfakefs()`), plus
pytest-style tests with the `fs` fixture in `pyfakefs/pytest_tests/`. Run with pytest.
Template: `pyfakefs/tests/fake_filesystem_unittest_test.py` (Patcher-driven TestCase using real
module names) and `pyfakefs/pytest_tests/fake_fcntl_test.py` (the only fcntl test).

## Phase 2 - existing-PR / publicly-solved / exclusivity (run 2026-09-29)

CANON = `pytest-dev/pyfakefs` (no move).
- PR search, all states: flock (0), fcntl (#646 no-op patching, #1075 constant forwarding), lockf (0),
  "file lock"/locking (CI bumps only), F_SETLK (0), advisory (0), dup2/os.dup (#985 add dup/dup2/lseek,
  #989 close-order fix), "file descriptor" (unrelated), portalocker/filelock (0).
- Diffs read: #646 (+43 fake_filesystem.py, no-op fcntl class), #1075 (+5 fake_io.py `__getattr__`),
  #985 (+20 fake_os.py dup/dup2/lseek, +23 fd table), #989 (`close_fd(fd)` so closing the SECOND fd no
  longer kills the first). None has lock state, owners, ranges, a description refcount or a
  dup2-overwrite fix. EXCLUSIVITY CLEAN.
- Issues: #645 (2021, maintainer: "it would probably be better to emulate at least part of the
  functionality ... I'm not sure which part shall be emulated", chose the no-op), CHANGES.md 4.x:
  "the fcntl module under Unix is now mocked ... (this may be changed in the future if needed, see
  #645)". #697 "low-level OS stuff that we are not able to emulate" is about `ioctl` return values.
  #988 (closed) fixed only close order. #1074 constants. No decline, no roadmap row, no open request.
- Open PRs (4): #1340 pre-commit, #1318 / #1322 / #1323 thread-safety in fake_os.py/fake_path.py; none
  touches fcntl, dup, close or the fd table.
- base..main: 0 commits (base IS main HEAD).
- Functional check on base (probe `worktrees/pyfakefs-locks-tools/probe1.py`, hunter's
  `pf_probe_pyfakefs_lock.py`): no flock/record/OFD conflict at all, GETLK echoes the query, a write
  lock on an O_RDONLY fd is accepted, `os.lockf` forwards to the REAL os (`fake_os.py:1460`),
  `dup` + close(original) + read(dup) raises `ValueError`, and `dup2(x, fd)` where `fd` is a dup
  closes the WRONG descriptor (the original) because `add_open_file` calls `f.close()` ->
  `close_fd(f.filedes)`.
- Sibling ecosystem: no fake filesystem (FakeFS, memfs, mock-fs, afero) ships byte-range lock
  emulation; `gh search code` for F_OFD_SETLK + fake finds only pyfakefs copies.
- Local dedup: no lock/fcntl/flock/dup class in approved-problems/, problems/, rejected/.
  SATURATED-REPOS: no pyfakefs row. Quota 1/6 (this is 2/6), 0 this week.

## Phase 3 - candidates (from the hunted lane)

| Candidate | One line | Verdict |
|---|---|---|
| A. Full advisory locking + description lifetime (chosen) | flock / record / OFD locks in one per-file table, owner kinds, release events, dup/dup2 description | proceed |
| B. flock only | one owner kind, no ranges | uniform-wrap, ~120 eff, dead |
| C. record locks only | ranges without owner-kind interplay | spec-knowable transcription, dead |
| D. dup/dup2 description refcount only | fix the two fd-table bugs | ~40 eff bug fix, under floor |
| E. POSIX credentials (hunter lane U) | owner/group permission model | maintainer declined (#431/#585) |

Step A (death-class guard) on A: (1) not one guard at N sites: range arithmetic, owner kinds,
release-by-event and description identity are separate mechanisms; (2) not single-subsystem: the
walls live in fake_file (close path), fake_filesystem (fd table), fake_open (fd reuse), fake_os
(lockf, dup2), fake_io (fcntl); (3) no hidden-spec dependence: every rule is stated; (4) POSIX/Linux
locking semantics are knowable (and the container's real OS answers them) - that is the known risk,
so NO trap may be semantics-only; the band has to come from the fake's machinery; (5) the fake-side
walls survive full statement because stating "dup2 onto an open descriptor closes it first, exactly
as os.close would" does not tell you that `add_open_file` closes the wrong slot.
Absorption: the repo has NO lock state, NO owner notion, NO description refcount, NO range code;
FakeFcntlModule is four no-ops. Nothing absorbs the kernel.

Step B: lead class S3/S4 (machinery-riding: locks must follow every close/dup/open path the fake
already has) + A7 (determination channels: every path that closes a descriptor must fire the
record-lock release) + F-39 (repo helper bug only the new pattern reaches: `add_open_file`'s
implicit close).

## 1. Title
Add advisory file locking to the fake fcntl and os modules

## 2. Shape
O-Composite-add (new capability spanning io/os/file/filesystem/open adapters). Predicted dominant
verdict: MISSED_REQUIREMENT on release/description cells, REGRESSION on the dup2 slot bug.

## 3. Public API surface (all existing stdlib names, made to work on fake descriptors)
- `fcntl.flock(fd_or_file, op)` - LOCK_SH / LOCK_EX / LOCK_UN, optional LOCK_NB.
- `fcntl.fcntl(fd_or_file, cmd, arg)` for F_SETLK, F_SETLKW, F_GETLK, F_OFD_SETLK, F_OFD_SETLKW,
  F_OFD_GETLK with a bytes `struct flock` in host layout; returns bytes of the same length.
  Other commands unchanged (0 for int arg, the arg for bytes).
- `fcntl.lockf(fd_or_file, cmd, len=0, start=0, whence=0)` - record lock, LOCK_NB = non-blocking.
- `os.lockf(fd, cmd, len)` - F_LOCK / F_TLOCK / F_ULOCK / F_TEST from the current offset; newly
  faked, also when imported by name (`from os import lockf`).
- `os.dup`, `os.dup2`, `os.close`, `open(fd)`/`os.fdopen(fd)`: description semantics.
No new pyfakefs API. No new signatures (no compile-wipe risk).

## 4. Canonical output form
- GETLK result: `l_type` of the conflicting lock, `l_whence` 0, absolute `l_start`, `l_len` =
  length or 0 for a lock with no end, `l_pid` = `os.getpid()` for a record lock, -1 for a
  description lock. Several conflicts: the one that starts lowest. No conflict: `l_type` F_UNLCK,
  other fields as given.
- Errors: refused non-blocking request EAGAIN; `os.lockf F_TEST` refused EACCES; would-wait EDEADLK;
  bad mode EBADF; negative resulting start / bad type / bad whence EINVAL.
- Empty/zero: `l_len` 0 = to infinity.

## 5. Blind-spot pre-empts
- compound-order / pipeline: "exactly as os.close would" for dup2's implicit close.
- rule-resolution: "Locks belong to the file itself, not to the path it was opened by."
- adjacent-vs-all: "record locks ... released as soon as the process closes ANY descriptor for
  that file".

## 6. Description draft (meta.md, see the file; ~430 words)
Paragraphs: ask + current state; the three owner kinds and conflicts; ranges; errors and the
blocking rule; release and description lifetime; GETLK reporting.

## 7. File footprint (slice measured, full scope sketched)
| Action | Path | Raw delta | Meaningful | Reason |
|---|---|---|---|---|
| MODIFY | pyfakefs/fake_io.py | +150 | ~115 | FakeFcntlModule: fd resolution, struct flock, dispatch, flock, lockf |
| NEW | pyfakefs/fake_lock.py (or inside fake_file.py) | +130 | ~100 | range normalisation, owner model, conflict, replace/split/merge, GETLK pick, release |
| MODIFY | pyfakefs/fake_os.py | +35 | ~28 | os.lockf, dir() entry |
| MODIFY | pyfakefs/fake_filesystem.py | +30 | ~22 | close_open_file releases, dup2 overwrite closes the right slot, description refs |
| MODIFY | pyfakefs/fake_file.py | +20 | ~15 | `_is_open` / fileno through surviving descriptors, lock list on FakeFile |
| MODIFY | docs/troubleshooting.rst, CHANGES.md | +4 | 0 | doc |
TOTAL ~370 raw / ~280 meaningful across 5-6 files. Buffer above 250.

## 8. Solution outline
- `_normalize_range(desc, whence, start, length) -> (lo, hi|None)` <- ranges sentence.
- `_conflicts(file, request, owner) -> list[lock]` <- owner-kind sentence.
- `_apply(file, owner, kind, type, lo, hi)` replace / split / merge <- "replaces whatever the same
  owner held".
- `_getlk(...)` lowest-start conflict, pid by kind <- reporting sentence.
- `flock(desc, op)` with non-atomic conversion <- flock sentence.
- `release_process_locks(file)` on every descriptor close; `release_description_locks(desc)` when
  the last descriptor of a description goes <- release sentences.
- `FakeFilesystem.close_open_file(fd)` = the single chokepoint for "a descriptor is closed";
  `add_open_file(new_fd)` implicit close routed through it for the RIGHT fd.
- would-wait -> EDEADLK <- blocking sentence.

## 9. Test outline (full suite in FINISH; the slice ships ~12)
File `pyfakefs/tests/fake_file_lock_<hex>_test.py`, `fake_filesystem_unittest.TestCase`
(`setUpPyfakefs`), skipped off Linux; helpers `pack(type, start, len, whence=0, pid=0)`,
`unpack(bytes)`, `assert_refused(fn, errno)`.
Buckets: flock (conflict, shared, conversion, dup same owner, fdopen same owner, NB/blocking);
record vs OFD (same-process conflict, record-record never, GETLK report per kind); ranges (merge,
split, len 0 beyond EOF, negative len, SEEK_CUR after read/lseek, SEEK_END, EINVAL); modes (EBADF
per kind, flock ignores mode); release matrix (below); twin entry points (fcntl.lockf / os.lockf /
F_SETLK share one table; `from os import lockf`); blocking EDEADLK on every waiting entry point;
filesystem isolation (a second Patcher session starts clean); other fcntl commands unchanged.

## 10. Forced bounds
`fcntl` functions accept an int or any object with `fileno()`; struct flock native layout
("hhqqi" on Linux x86-64), returned bytes same length as passed.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | dup2 onto a slot holding a dup'd wrapper closes the ORIGINAL descriptor (`add_open_file` -> `f.close()` -> `close_fd(f.filedes)`) | F-39 | S3 | fd-table identity | 2, 3 | nobody reads `add_open_file`; the real OS shows correct semantics so the agent assumes the fake matches | "os.dup2 onto an open descriptor closes that descriptor first, exactly as os.close would" | dup2 over a dup: original still reads, its OFD lock survives, record locks released once |
| 2 | Description lifetime: `_is_open` checks only `self.filedes`, so the description dies with its first descriptor | F-47 (state the repo never carried) | S4 | description refcount | 1, 3 | fixing lock release without fixing the wrapper leaves reads through the dup broken, or releases OFD/flock on the first close | "closing one descriptor leaves the others working"; "released when the last descriptor for their description is closed" | close original, dup keeps reading AND keeps its flock/OFD lock |
| 3 | Release by owner kind x close event: record locks on ANY descriptor close of the file (unrelated open, hard-link path, file-object close, dup2 implicit close), NOT on a closefd=False object close; description locks only on last close | F-10 (kind x event), F-20 (closefd=False close must keep behaving as before) | A7 | release event | 1, 2 | the uniform "release on close" hook is placed in `close_fd` before the `_closefd` branch, or only in `os.close` | release sentences | release matrix cells |
| 4 | Locks keyed by the FakeFile object: hard link, rename, unlink + recreate | F-10 | S4 | identity | 3 | a path-keyed table (`wrapper.file_path`) passes every single-path test | "Locks belong to the file itself, not to the path it was opened by" | hard-link conflict + hard-link close release; rename keeps; recreated file free |
| 5 | Owner-kind conflict: record vs own OFD conflict, record vs record never, flock separate | F-10 | S2 | owner | 6 | one table with one owner = "the process" makes OFD vs record silent; one table for flock too | owner sentence | same-process OFD after record lock; flock unaffected by a record lock |
| 6 | Range replace/split/merge + GETLK lowest piece, len 0 infinite reported as 0, negative length | F-13 | S2 | range | 5 | whole-lock discard passes single-lock tests; infinity stored as a big int leaks into l_len | ranges + reporting sentences | split/merge/len0 split reports |
| 7 | Twin entry points: F_SETLK, fcntl.lockf, os.lockf share one table; os.lockf faked by name | F-31 (twins), F-9 origin | S5 | entry point | 3 | a table on the FakeFcntlModule instance is invisible to FakeOsModule; `from os import lockf` stays real unless `dir()` lists it | "with os.lockf faked as well (also when imported directly from os)" | os.lockf lock seen by F_OFD_GETLK; direct import |
| 8 | Would-wait -> EDEADLK on every blocking entry point (F_SETLKW, F_OFD_SETLKW, flock w/o NB, fcntl.lockf w/o NB, os.lockf F_LOCK); flock conversion refused drops the lock | F-10 (entry x blocking) | A8 | blocking | 5 | the rule is written once; agents wire it into the fcntl path only | blocking sentence (general, not enumerated) | one cell per entry point |
| 9 | Other fcntl commands unchanged | F-20 | S3 | sibling API | - | a rewrite forwards unknown commands to the real module or parses every bytes arg | none (documented base behaviour, the one inferable requirement) | F_GETFD / bytes echo |
| 10 | A fresh fake filesystem starts without locks | F-12 family (class state) | S4 | isolation | 7 | class-level tables (the FakePath.filesystem idiom) survive Patcher sessions | "each fake filesystem has its own locks" | two Patcher sessions |

## 11b. Cross-product matrix
Release (owner kind x close event):
| | os.close same fd | close of a dup (others remain) | close of an unrelated open of the file | close via hard-link path | file object close (closefd=True) | closefd=False object close | dup2 onto the fd |
|---|---|---|---|---|---|---|---|
| record | released | released | released | released | released | KEPT | released |
| OFD | released if last | kept | kept | kept | released if last | kept | released if last |
| flock | released if last | kept | kept | kept | released if last | kept | released if last |

Blocking (entry point x wait): F_SETLKW, F_OFD_SETLKW, flock, fcntl.lockf, os.lockf F_LOCK -> EDEADLK;
their non-blocking twins -> EAGAIN; F_TEST -> EACCES.

Scope audit: every range is per FILE (object), every owner per description or process.
Format-noun audit: "descriptor" (an fd number), "open file description" (what open() creates,
shared by dup/dup2/fdopen) - both named.

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
25-40%. Semantics are knowable and the container's real OS answers them (the lean toward too
easy); the band must come from traps 1-3, 7, 8, 10, which live in the fake's machinery. If the
first batch reads >40%, next levers: more release-matrix cells through fake-only paths
(pathlib `Path.open`, `io.open`, `os.fdopen`, NamedTemporaryFile), F-10 cells for os.lockf SEEK_CUR
after buffered reads.

## 14. Quality gates
- [x] Phase 1 5/5; Phase 2 searches above, 0 hits on the core.
- [x] Title verb-led; shape declared; API names listed; canonical form written.
- [x] 1 codebase-inferable requirement (trap 9).
- [x] Traps on different axes, interdependence 1<->2<->3, 5<->6, 3<->7.
- [x] 11b matrix written; each off-diagonal cell gets a test in FINISH.
- [x] L96: no frequency words. L81: the blocking rule is general, not an enumeration.
- [x] L57/L59: no stage placement, no float.
- [x] L72: no new API, all names exist.
- [x] L99/L103: tests import only stdlib + pyfakefs; base F2P by behaviour.
- [x] Platform-grades-as-root: locks do not depend on uid; validate 0, 1000, 4242.

**Why not a duplicate.** Closest approved: pyfakefs-block-inode-accounting (same repo, capacity
accounting: mounts, statvfs, rollback). Different files' kernels (fd table/close path/fcntl vs
mount accounting), different feature class (concurrency primitives vs capacity).
**Predicted iteration cycles:** 2.
