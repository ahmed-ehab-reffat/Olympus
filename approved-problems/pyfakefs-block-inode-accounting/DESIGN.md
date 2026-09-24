# DESIGN.md — pyfakefs-block-inode-accounting

Repo: pytest-dev/pyfakefs (Python 100%, Apache-2.0, 750 stars)
Base: c72885ac79a45f553fd76a06c2735739e289ecbc (== upstream main at 2026-09-20)
Hunt log: Instructions/repo-hunt-logs/REPO-HUNT-2026-09-20.md

## 1. Title

`Add block and inode accounting to fake filesystem mount points`

Verb: Add. Subsystem named: fake filesystem mount points (the disk-space accounting kernel
plus the `os` module reporting surface).

## 2. Shape classification

- Shape: **O-Composite-extend** (refactor an existing aggregation across packages) with an
  O-Pipeline-hard flavour: the accounting kernel's contract changes and every one of its call
  sites must supply information it does not have today.
- Definition (SHAPES.md Pattern 11/12): existing shared machinery (`change_disk_usage`) is
  re-expressed, its callers in a second module are rewired, and a new reporting surface is
  added in a third module.
- Pass-rate target: 15-30% (sprint ceiling <=40%).
- Best agent: Orion (long-horizon, commit-and-implement); Nova will thrash on the six charge
  sites.
- Dominant verdict predicted: MISSED_REQUIREMENT (a leaked or double-counted inode), then
  REGRESSION (baseline byte-exact disk-usage tests).
- Solver/our LOC ratio: ~1.3x.

## 3. Public API surface

Exactly the names the tests assert.

- `FakeFilesystem.add_mount_point(path, total_size=None, can_exist=False, block_size=1, inode_count=None) -> dict`
  — two new keyword arguments on an existing method; returns the mount dict as before.
- `FakeFilesystem.set_disk_usage(total_size, path=None, block_size=None, inode_count=None) -> None`
  — two new optional keyword arguments; `None` leaves the current setting alone.
- `FakeFilesystem.get_disk_usage(path=None) -> DiskUsage` — unchanged signature. `total` is now
  the mount's capacity rounded down to whole blocks, `used` is the space the mount's objects
  occupy.
- `FakeFilesystem.statvfs(path=None) -> os.statvfs_result` — NEW instance method.
- `FakeOsModule.statvfs(path) -> os.statvfs_result` — NEW; today this name is forwarded to the
  real `os` by `FakeOsModule.__getattr__` (fake_os.py:1460).
- Mount dict keys: existing `idev`, `total_size`, `used_size`; new `block_size`, `inode_count`,
  `used_inodes`.
- Errors: `OSError` with `errno.ENOSPC` for both block exhaustion and inode exhaustion (the
  errno the kernel already raises); `ValueError` for a block size below 1.

No name is described as "same as X".

## 4. Canonical output form

- Blocks per object: `ceil(byte_length / block_size)`; zero bytes means zero blocks.
- Directories: zero blocks, one inode.
- Regular files and symbolic links: blocks by content length, one inode.
- Hard links: no additional inode, no additional blocks, while another name remains.
- Mount capacity: `(total_size // block_size) * block_size`. `get_disk_usage().total` reports
  that, so `total - used == free` always holds and every figure is a whole number of blocks.
- Default `block_size` is 1, which reproduces today's byte-exact accounting exactly (this is
  what keeps the 20-odd existing `DiskSpaceTest` assertions green).
- Default `inode_count` is `None`, meaning no limit, which never raises.
- Unlimited size or unlimited inodes report the placeholder figure `get_disk_usage` already
  uses for unlimited space (1024**4).
- `statvfs` field order and meaning: `f_bsize` = `f_frsize` = block size; `f_blocks` = capacity
  in blocks; `f_bfree` = `f_bavail` = blocks left; `f_files` = inode count; `f_ffree` =
  `f_favail` = inodes left; `f_flag` = 0; `f_namemax` = 255.
- ENOSPC leaves the mount exactly as it was (no half charge).
- Mount root directory: takes an inode from neither the new mount nor the one it sits on.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- *Iteration termination / accumulate-vs-recompute*: "what a mount reports as used is the space
  its objects occupy" — states the invariant, not the update rule, so repeated appends inside
  one block are covered without naming the delta problem.
- *Unstated inverse*: "takes one inode when it first appears there and gives it back when its
  last name is removed" — both directions in one sentence (L9).
- *Adjacent-vs-all / rule-resolution*: "renaming within a mount is a removal and an addition of
  the same object and leaves both counts where they were."
- *Falsy-on-invalid / arming-vs-firing*: "running out of inodes does not stop writing to an
  object already on the mount."
- *Default ordering / canonical form*: the `statvfs` field list is spelled out (fairness floor,
  not a giveaway).

Codebase-inferable requirements: exactly one (that the unlimited placeholder is the 1 TiB figure
`get_disk_usage` already returns) — and it is stated anyway.

## 6. Description draft (meta.md)

See `meta.md`. Target ~330 words (hard cap 500). Plain prose, no headers, no labels.

Framing constraint from the hunt (MANDATORY): the description is written on the ACCOUNTING
MODEL and the mount contract. `statvfs` appears only as the reporting surface in the last
paragraph. It is never framed as "implement os.statvfs", because issue #86 (closed 2016) is the
maintainer's own bullet plan and names `os.statvfs` as the deferred item.

## 7. File footprint

Sketched against real source, for the FULL design. The CORE SLICE (Step 4b) builds the first
four rows only.

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | pyfakefs/fake_filesystem.py | 3313 | +175 | ~140 | mount config + validation, block kernel, inode allocate/release, statvfs, get/set_disk_usage |
| MODIFY | pyfakefs/fake_file.py | 1512 | +55 | ~45 | old-size threading at 3 sites, entry allocate/release at add_entry/remove_entry |
| MODIFY | pyfakefs/fake_os.py | 1510 | +25 | ~20 | `statvfs` (and `fstatvfs`) stop being forwarded to the host |
| MODIFY | pyfakefs/fake_filesystem_shutil.py | 190 | +10 | ~8 | keep `shutil.disk_usage` consistent with the rounded figures |
| MODIFY (FINISH) | pyfakefs/fake_filesystem.py | — | +70 | ~55 | `add_real_file`/`add_real_directory` charging, `reset` propagation, nested-mount attribution, atomic rollback |

### MEASURED, not sketched (2026-09-20, core slice built)

The hunt sketched ~275 human-effective over six decision points. The core slice is now built and
the hook measures it, so the sketch can be replaced with a real ratio:

```
python3 .claude/hooks/effective_loc_check.py problems/pyfakefs-block-inode-accounting/solution.patch
files: 3 · raw added: 259 · human-effective: 99 · padding-floor: 82
   31 raw /  21 human-eff  pyfakefs/fake_file.py
  216 raw /  76 human-eff  pyfakefs/fake_filesystem.py
   12 raw /   2 human-eff  pyfakefs/fake_os.py
```

**raw / human-effective is 2.6 on this repo**, because pyfakefs's convention is a Google-style
docstring with `Args:` / `Raises:` on every public method, and the counter strips all of it. The
hunt's 275 assumed roughly 1.3. Reaching 250 human-effective therefore needs about **650 raw
added**, not 335. This is the one number the hunt got materially wrong and it is the FINISH
stage's binding constraint.

### FINISH levers, in priority order (all inside the mount contract, none a bolted-on second feature)

The TOO-EASY "scope-lever-doubles-the-collision-surface" class rules out bolting on an unrelated
capability (a read-only mount flag with `EROFS` was considered and REJECTED on exactly that
ground). Everything below is part of how a real mount accounts and reports:

| Lever | Raw | Why it is in scope, not padding |
|---|---|---|
| Reserved blocks for the superuser: `reserved_blocks` on both mount setters, `f_bavail` stops equalling `f_bfree`, `get_disk_usage().free` reports the AVAILABLE blocks (CPython's own `shutil.disk_usage` reads `f_bavail`), and a non-root caller gets `ENOSPC` while free blocks remain | ~110 | `f_bavail` is already a field this feature reports; today it is a duplicate of `f_bfree`, which is the degenerate case. `helpers.is_root()` already exists and the repo already branches on it. F-33: it changes what an existing reader means. |
| Per-mount name limit: `f_namemax` becomes a setting instead of a hard-coded 255, and it is ENFORCED with `ENAMETOOLONG` at every creation path (`create_file`, `mkdir`, `symlink`, `link`, `rename`) | ~120 | `f_namemax` is already reported. Enforcing it rides the same `add_entry` chokepoint as the inode charge, so it is interdependent rather than parallel. |
| `statvfs` by file descriptor plus `os.fstatvfs(fd)` | ~45 | POSIX; `os.statvfs` accepts an fd and `FakeOsModule` has the `allow_fd` resolve path already. |
| `add_real_file` / `add_real_directory` charging, including the documented `lazy_read` behaviour | ~70 | The sixth charge site. Also the wall that keeps the tree-walk architecture honest. |
| `FakeFilesystem.__init__` and `reset()` carrying the mount settings | ~50 | `reset(total_size=...)` already exists and drops every setting today. |
| A per-mount usage report over `mount_points` | ~60 | Additive read-only aggregation over structured output the solver already produces (PICK-FILTER scope-invent lever). |

Total with the slice: ~715 raw, which lands near 270 human-effective at the measured 2.6 ratio.
Build them in this order and re-run the hook after each; stop at the floor plus a buffer.

## 8. Solution outline — pure-function helpers

One helper per behaviour the description names.

```
blocks_for(size, block_size) -> int                 <- "as many whole blocks as its length needs"
_mount_capacity(mount_point) -> int                 <- "the whole blocks that fit"
_free_blocks(mount_point) -> int                    <- statvfs f_bfree
_free_inodes(mount_point) -> int | None             <- statvfs f_ffree
change_disk_usage(usage_change, file_path, st_dev, *, old_size=0)
                                                    <- the kernel; charges
                                                       blocks_for(old+delta) - blocks_for(old)
allocate_entry(file_object, st_dev, needs_inode)    <- checks blocks AND inode, then applies
release_entry(file_object, st_dev, frees_inode)     <- gives both back
statvfs(path) -> os.statvfs_result                  <- the reporting surface
```

`change_disk_usage` keeps its public signature and gains a keyword-only `old_size` defaulting to
0. With `block_size == 1` the new formula collapses to `usage_change`, so any external caller
keeps today's behaviour exactly.

The inode rule is expressed once, as "this entry has just gained (or is about to lose) its only
name":

```
def _is_only_name(entry, after_add: bool) -> bool:
    base = 2 if isinstance(entry, FakeDirectory) else 1
    return entry.st_nlink == base
```

A directory carries a link of its own from `FakeDirectory.__init__` (`self.st_nlink += 1`), so
the repo's existing `st_nlink == 1` test is false for every directory. That asymmetry is the
lead trap (section 11).

No fixpoint loop and no recursion in this design.

## 9. Test file outline

Path: `pyfakefs/tests/fake_disk_accounting_<hex>_test.py` (random hex suffix; no `shipd` /
`datacurve` substring). Matches the repo's `pyfakefs/tests/*_test.py` convention and the
`unittest.TestCase` style of `fake_filesystem_test.py::DiskSpaceTest` (imports, no comments in
test bodies, `assertEqual` on tuples, `self.assertRaises(OSError)`).

Block 1 — imports: `errno`, `os`, `unittest`, `pyfakefs.fake_filesystem`, `fake_os`, `fake_open`.
Block 2 — builder helpers: `fs_with(block_size, inode_count, total)`, `write(path, n)`,
`append(path, n)`.
Block 3 — assertion helpers: `assert_usage(fs, total, used)`, `expect_enospc(callable)`.
Block 4 — tests grouped per requirement.

CORE SLICE buckets (this run):
- block rounding: exact fit, one over, empty file, repeated sub-block appends, truncate down,
  truncate up, `st_size` large file
- capacity rounding: total not a multiple of the block size
- inode lifetime: file, directory, symlink, hard link, unlink one of two names, rmdir, rename
- ENOSPC: blocks exhausted, inodes exhausted with free bytes remaining, write to an existing
  object with inodes exhausted, mount unchanged after a refused create
- statvfs: every field on a configured mount, unlimited mount, `FakeOsModule.statvfs` no longer
  the host's
- backward compatibility: default block size reproduces byte-exact accounting

FINISH buckets (not this run): the F-10 cross-product cells, `add_real_file`,
`shutil.disk_usage`, nested mounts, `reset`, argument validation.

5-axis coverage: every described atom (positive AND negative half of each), every public API
name in section 3, every branch of the new helpers, edge cases (zero-length, exact block
multiple, one byte over, single inode left, no limit set).

## 10. Forced kwargs / signatures

- `add_mount_point` and `set_disk_usage` gain keyword arguments with defaults — non-breaking.
- `change_disk_usage` gains a keyword-only argument with a default — non-breaking.
- `FakeOsModule.statvfs` is a plain instance method taking one path argument; it is wrapped by
  the module-level `handle_original_call` loop at fake_os.py:1497, like every other public
  method, so it needs no special registration. Confirmed: the loop runs over
  `inspect.getmembers(FakeOsModule, inspect.isfunction)` for every non-underscore name.
- `os.statvfs_result` is constructed from a 10-tuple (verified: `n_sequence_fields == 10`,
  `n_fields == 11`; `f_fsid` is the optional 11th and is NOT promised).
- meta.md names every new call shape (L72): `statvfs` is an instance method on the fake `os`
  module taking a path, and the two new mount settings are keyword arguments.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | The accounting kernel takes a DELTA, and blocks are not a function of a delta: `blocks(old+d) != blocks(old) + blocks(d)`. Every one of the six charge sites must supply the old size. | F-1 | A1 cross-section refactor of shared write machinery | rounding arithmetic through a shared chokepoint | #2 (same chokepoint), #3 (the ENOSPC check reads the same figure) | The natural edit is one line inside `change_disk_usage`. It passes every single-write test and fails repeated sub-block appends and every shrink. | "what a mount reports as used is the space its objects occupy, so writing again inside a block it already has does not grow it" | `repeated_sub_block_appends_stay_in_one_block`, `truncate_down_gives_blocks_back` |
| 2 | The repo's only per-object accounting hook is `add_entry`'s `if path_object.st_nlink == 1`, and that test is FALSE for every directory (`FakeDirectory.__init__` already took a link). An agent who hangs the inode charge on it leaks every directory, in both directions. | F-12 / A3 reuse-the-machinery missing-arm | A3 | object lifetime (which objects own an inode) | #1 (same two methods), #3 (the leak only surfaces as a later ENOSPC) | The byte charge is right there and looks like the template. Nothing in the failing test names directories. | "every object added to a mount, file, directory or symbolic link, takes one inode" | `mkdir_rmdir_cycles_do_not_leak_inodes`, `directory_takes_an_inode` |
| 3 | Inode exhaustion must ARM on allocation only. An agent who checks inodes inside the shared kernel breaks writing to an object that is already there. | F-15 arming-vs-firing | S3 baseline preservation through a shared chokepoint | when the check fires, not what it checks | #2 (both live on the allocation path) | The kernel is where ENOSPC already lives, so that is where the second limit gets added. | "running out of inodes does not stop writing to an object already on the mount" | `writing_to_an_existing_file_survives_inode_exhaustion` |
| 4 | `_do_rename` (a different module) removes and re-adds the SAME object. An agent who frees the inode whenever an entry disappears, but only allocates when `st_ino is None`, loses an inode on every rename. Fixing #2 the obvious way CREATES this one. | F-9 cross-stage | S2 composition of documented rules | direction (free vs allocate) on one object | #2 — this is the regression that fixing #2 produces | `add_entry` already guards inode NUMBER assignment on `st_ino is None`; reusing that guard for inode ACCOUNTING is the natural move. | "renaming within a mount is a removal and an addition of the same object and leaves both counts where they were" | `renaming_a_directory_keeps_the_inode_count` |
| 5 | `FakeOsModule.__getattr__` (fake_os.py:1460) silently forwards `statvfs` to the real `os`, so a fake with a 4096-byte disk answers with the host's 25 million blocks. Nothing raises. | F-9 module-layer resolution drop | S6 two-evaluators | which layer answers | #1 (it reports the kernel's figures) | Adding `FakeFilesystem.statvfs` looks complete; the module layer keeps answering from the host and no exception is raised. | "`statvfs` reports the mount the path is on" | `fake_os_statvfs_is_not_the_real_one` |

Every axis differs. Traps 2 and 4 are interdependent by construction (the fix for one is the
cause of the other); 1 and 3 share the chokepoint with 2.

CONTRACT-STATED / FIX-HIDDEN check, per row: stating the invariant (#1), the per-object inode
rule (#2), the write-survives-exhaustion rule (#3), the rename rule (#4) and the reporting
surface (#5) tells the agent WHAT must hold. None of the five sentences names
`change_disk_usage`, `st_nlink`, `add_entry`, `_do_rename` or `__getattr__`. The fixes are all
repo-internals discoveries.

### Architecture-jump audit (HARDENING 3a.6)

The jump that defeats traps 1-4 at once is **recomputing `used` by walking the mount's tree on
every query** instead of accounting incrementally. It is a legitimate architecture and it has
its own walls, which the contract already covers: a walk must de-duplicate hard links by object
identity, must stop at a nested mount point, and must not force a lazily-read real directory to
materialise. This is recorded as an accepted second architecture, not something to wall off
unfairly. The FINISH pass adds the lazy-real-directory cell, which only the incremental
architecture gets for free.

### Scope audit

Every metric the contract names is scoped to a MOUNT, and the contract says so in the first
sentence of each rule. `get_disk_usage` already resolves the deepest mount point for a path
(`_mount_point_for_path`), so nested mounts inherit the existing scoping.

### Format-noun audit (L24)

Nouns the meta names that are units of the model: *block*, *inode*, *object*, *name*, *mount*.
Extents stated: a block is the mount's allocation unit; an inode belongs to an OBJECT not to a
NAME (that is exactly what the hard-link clause says); a mount's figures cover the objects on
that mount only.

### Tolerance-fixture audit (L25)

The only "allow one, stop at the next" rule is inode exhaustion. The discriminating fixture is
the N-1 one: with exactly one inode left, creating one object must SUCCEED and leave `f_ffree`
at 0. That fixture is in the slice.

### Example audit (L21)

No worked example in the meta. No numbers beyond the `statvfs` field list and the two defaults.

### Float audit (L59)

No floats anywhere in this feature. All arithmetic is integer.

### Sibling-API audit (F-20)

`set_disk_usage` is the sibling of `add_mount_point`. Both gain the same two settings with the
same meaning, so there is no rule scoped to one of them — F-20 is deliberately not used here.

### Stage-placement audit (L57)

The description places no new stage "between" existing ones.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = the resource: **blocks** vs **inodes**.
Axis 2 = the operation's direction: **charge** vs **refund**.

| | charge | refund |
|---|---|---|
| **blocks** | `file_of_one_byte_takes_one_block` | `truncate_down_gives_blocks_back` |
| **inodes** | `directory_takes_an_inode` | `rmdir_gives_the_inode_back` |

Off-diagonal cells (the ones that decide the band, written as the cross of the two axes):

| | blocks | inodes |
|---|---|---|
| **empty object** | 0 blocks | 1 inode <- off-diagonal |
| **hard link** | 0 blocks | 0 inodes <- off-diagonal |
| **directory** | 0 blocks <- off-diagonal | 1 inode |
| **rename** | unchanged | unchanged <- off-diagonal |

Every off-diagonal cell has a named test in the slice. Predicted failure mode is OVER-firing
(charging an inode for a hard link, refunding one on rename) rather than a missing feature,
which is what makes them misdirecting.

The FINISH pass adds the third axis (mount: root vs nested vs auto-mounted) and its cells.

## 12. Tier + category

- Tier: Olympus (one tier).
- Sub-rank target: Good.
- Category: **feature-request** (net-new settings, a net-new public method, a net-new reporting
  surface). Title verb is "Add", which matches.

## 13. Predicted pass rate

- Predicted: 15% - 30%.
- Reasoning: three independent walls (delta kernel, directory inode asymmetry, module-layer
  delegation) plus one interdependent pair (2 <-> 4). The tree-walk architecture jump is
  available and lowers the ceiling, which is why the estimate is not lower. The feature is
  globally coupled (a whole-mount invariant), which is the L2 profile that holds a band.
- Sanity check: under the <=40% ceiling, above 0%. A competent implementer reading only the
  description and the repo reaches a correct design; the failures are in the wiring.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (below)
- [x] Existing-PR check: 0 hits (commands below)
- [x] Closest approved opened side by side: `approved-problems/afero-overlay-deletions`
      (filesystem abstraction, but namespace/deletion VISIBILITY in a Go copy-on-write overlay
      — different capability, different repo, different language). Recorded, meta.md kept away
      from overlay vocabulary.
- [x] Title verb-led, 6 words, names the subsystem
- [x] Shape declared
- [x] Public API surface lists every name (section 3)
- [x] Canonical output form spelled out (section 4)
- [x] <=1 codebase-inferable requirement
- [x] Description word count under the cap
- [x] No headers / labels / Box wrappers / code-as-prose in the description
- [x] File footprint sketched against real source
- [x] Raw and meaningful LOC clear the floor (>=200 meaningful, 4 files)
- [x] 1+ pure-function helper per behaviour (section 8)
- [x] Fixpoint / cycle-trace: not applicable
- [x] Test outline 4-block, scenario-encoded names
- [x] 5-axis coverage planned
- [x] Forced kwargs documented (section 10)
- [x] 5 named traps, each with a pre-empt sentence and a catching test
- [x] Every trap names an F-id
- [x] Traps on different axes; 2 and 4 interdependent
- [x] 11b filled in; every off-diagonal cell has a test
- [x] Stage-placement audit (L57)
- [x] Float audit (L59): no floats
- [x] Sibling-API audit (F-20): declined, reason recorded
- [x] Unobservable-interface audit (F-21): no rule quantifies over a caller-supplied interface
- [x] Absent-key audit (F-24): no namespace pass added
- [x] Placeholder-lifetime audit (F-25): no deferred handles
- [x] Inherited-aggregate audit (F-33): `used_size` IS a field the repo reads back, and this
      feature changes what it means. Named the reader (`get_disk_usage`, `set_disk_usage`,
      `FakeShutilModule.disk_usage`) and both keep working because the default block size of 1
      reproduces the old figures byte for byte.
- [x] Attempt-vs-effect audit (F-15 accounting): the degenerate attempt is a refused create; the
      mount must be unchanged. Tested.
- [x] Qualifier-attachment check (L52): every "while", "when" and "so" in the draft has exactly
      one possible subject. Re-checked sentence by sentence at meta.md write time.
- [x] Representation-pin sweep (L48/L49): `statvfs` returns an `os.statvfs_result`, which the
      meta states by name; assertions read named fields, never a tuple position.
- [x] In-process validation (L56): no test shells out.
- [x] Predicted Wrong Logic < 25%
- [x] Predicted pass <= 40%
- [x] Category matches the description
- [x] Not pattern-followable: there is no second accounting kernel in the repo to copy.
- [x] Not in RULES section "Features already used"

## Phase 1 — repo understanding

**Architecture, one paragraph.** pyfakefs replaces the real filesystem for a test process. A
single `FakeFilesystem` object owns an in-memory tree of `FakeFile` / `FakeDirectory` nodes
rooted at `root`, plus an ordered `mount_points` dict mapping a path to `{idev, total_size,
used_size}`. Around that core sit per-module fakes that translate stdlib calls into tree
operations: `FakeOsModule`, `FakePathModule`, `FakeFileOpen` / `FakeFileWrapper`,
`FakePathlibModule`, `FakeShutilModule`, `FakeIoModule`. A `Patcher`
(`fake_filesystem_unittest.py`) swaps those modules in for the real ones. Every module fake
forwards names it does not implement to the real module through `__getattr__`.

**Five top-level subsystems and their boundaries.**
1. `fake_filesystem.py` — the tree, path resolution, mount points, disk accounting, and the
   create/remove/rename/link operations.
2. `fake_file.py` — the node types (`FakeFile`, `FakeDirectory`, the real-file variants) and the
   open-file wrappers; this is where directory entries are added and removed.
3. `fake_os.py` / `fake_path.py` / `fake_scandir.py` — the `os` surface.
4. `fake_open.py` / `fake_io.py` — the `open` / `io` surface.
5. `fake_filesystem_unittest.py` / `pytest_plugin.py` — the patcher and the test entry points.

**Three high-entanglement zones.**
1. `FakeDirectory.add_entry` / `remove_entry` — every creation, deletion, rename and hard link
   goes through them, and they are the only place per-object accounting happens.
2. `FakeFilesystem.change_disk_usage` — one kernel, six callers across two modules.
3. `FakeOsModule.__getattr__` plus the `handle_original_call` wrapping loop — the seam between
   the fake and the real `os`.

**Test framework and location.** `unittest.TestCase` subclasses (via
`pyfakefs/tests/test_utils.py::TestCase`, which adds `raises_os_error`) in
`pyfakefs/tests/*_test.py`, run under pytest. `pyfakefs/pytest_tests/` holds the pytest-fixture
tests. `pyproject.toml` declares no runtime dependencies.

**Formatting template cited.** `pyfakefs/tests/fake_filesystem_test.py::DiskSpaceTest`
(lines 1790-1930): `setUp` builds `FakeFilesystem(path_separator="!", total_size=100)` plus
`FakeOsModule` and `FakeFileOpen`; test bodies carry no comments; assertions are `assertEqual`
on the `DiskUsage` tuple or on `.used`.

**Comment convention.** Source files carry Google-style docstrings on public methods and sparse
inline `#` comments explaining non-obvious decisions. Test bodies carry none. New code follows
exactly that: docstrings on new public methods, no inline comments unless a decision genuinely
needs one, zero comments in tests.

## Phase 2 — existing-PR and publicly-solved check

Canonical org resolved first: `gh api repos/pytest-dev/pyfakefs -q .full_name` -> `pytest-dev/pyfakefs` (no move).

```
gh pr list -R pytest-dev/pyfakefs --state all --search "statvfs"        -> []
gh pr list -R pytest-dev/pyfakefs --state all --search "inode"          -> []
gh pr list -R pytest-dev/pyfakefs --state all --search "disk_usage"     -> []
gh pr list -R pytest-dev/pyfakefs --state all --search "quota"          -> []
gh pr list -R pytest-dev/pyfakefs --state all --search "block size"     -> 3 unrelated (furo pin, skip_names, actions/cache)
gh pr list -R pytest-dev/pyfakefs --state all --search "disk usage"     -> #700 path-like shutil.disk_usage, #87 filesystem size (2016), #95 hard links (2016), #155 too-large-file fix (2017)
gh pr list -R pytest-dev/pyfakefs --state all --search "free space"     -> #122, #95, #155
gh pr list -R pytest-dev/pyfakefs --state all --search "ENOSPC"         -> #95
gh issue list -R pytest-dev/pyfakefs --state all --search "statvfs"     -> #86 (closed 2016), #473 (unrelated)
gh issue list -R pytest-dev/pyfakefs --state all --search "inode"       -> #1321 (thread races), #496, #556, #25
gh issue list -R pytest-dev/pyfakefs --state all --search "fallocate"   -> []
```

PR DIFFs pulled for all three OPEN PRs:

```
#1318 Make use_original thread-local     -> CHANGES.md, fake_os.py, fake_filesystem_unittest_test.py
#1322 AI-generated possible solution (A) -> fake_os.py
#1323 AI-generated possible solution (B) -> fake_os.py, fake_path.py
```

All three are the `use_original` thread-race lane. None touches `fake_file.py`, the accounting
kernel in `fake_filesystem.py`, or `statvfs`. Overlaying their changed-file set on the planned
solution footprint: only `fake_os.py` is shared, and there only for the `use_original` decorator
and path helpers, not for the module's answer surface. **EXCLUSIVITY CLEAR.**

Publicly-solved read: issue #86's full body and both maintainer comments were read.
`mrbean-bremen`: *"implemented in PR #87 except the support for the os specific functions
(os.statvfs and GetDiskFreeSpaceExW) and the path-specific part (which I won't implement until
there is real need)"*, then *"Works ok for me as is now, closing this. Reopen at will if you
need more..."*. That is an invitation, not a philosophy reject. #86 names `os.statvfs` as the
deferred REPORTING surface; it says nothing about block granularity, allocation units or
inodes, which is where this pick's core lives. The mandatory mitigation is applied in meta.md
(framed on the accounting model, never on `os.statvfs`).

Issue #25 ("Improve handling of st_ino") is about inode IDENTITY across moves, resolved in 2016;
it is not inode accounting or exhaustion. No comment anywhere links an external implementation,
and no snippet in any thread implements block or inode accounting.

## SIX-CHECK (CLAUDE.md), run at scope-lock

1. Literal name search (`statvfs`, `inode`, `block size`): clean.
2. Namespace expansion (`disk usage`, `free space`, `ENOSPC`, `disk_usage`, `quota`): only the
   2016-2017 PRs that BUILT the byte accounting this pick replaces.
3. Maintainer philosophy: #86 is "reopen at will", not "prefer not to". #722's settled
   `st_blocks` decision is respected — `helpers.FakeStatResult.st_blocks` is NOT touched.
4. Closed-with-implemented: #86 says "implemented in PR #87 EXCEPT os.statvfs"; the exception is
   this lane and nothing about blocks/inodes was ever implemented.
5. Base to HEAD: `git rev-list --count c72885ac..up/main` -> **0**. The base commit IS upstream
   main. Nothing to overlap with.
6. Existing-capability functional check (run on base, `PYTHONPATH=.`):
   - `set_disk_usage(4096)` + 20 one-byte files -> `DiskUsage(total=4096, used=20, free=4076)`
   - `FakeOsModule(fs).statvfs is os.statvfs` -> `True`; calling it returned the HOST's
     `f_blocks=25871072`
   - 900-byte file truncated to 100 -> `used=100`, no rounding anywhere
   - `makedirs('/d/e/f')` -> `used` unchanged; no inode notion exists
   0% of the feature scope already works.

## PICK-FILTER gates

1. BEHAVIORAL-F2P-GAP — PASS. Base gives an observably wrong answer through the public API, and
   `os.statvfs` returns the host's numbers inside a fake filesystem. Not composable from
   existing primitives: there is no block size, no inode count and no statvfs anywhere
   (`grep -E 'statvfs|block_size|f_bsize|inode_count|max_files' pyfakefs/*.py` -> 0 hits).
2. SATURATION — PASS with a noted penalty. `statvfs` is a POSIX reporting struct, but the
   accounting model (per-mount charging through pyfakefs's own delta kernel and its six call
   sites, with `st_nlink`-guarded entry hooks) is repo-internal and not a port of anything.
3. UNIFORM-WRAP — PASS. Two opposing mechanisms: block rounding in the kernel, inode lifetime at
   `add_entry` / `remove_entry` where the byte guard structurally cannot reach. Fixing the
   directory leak the obvious way breaks rename (trap 4).
4. LOC-CEILING — PASS. ~268 meaningful over 4 files; the core is a missing capability, not a
   surgical fix to mostly-correct code.
5. COLD-NOT-LIVE — PASS. Nobody is building this capability: 0 commits between base and main, no
   PR in any state, 12 months of commits mention `statvfs` zero times.
6. REPRODUCE-ON-BASE — PASS (probe above).
7. DEDUP — PASS. `grep -ilE 'pyfakefs|statvfs|disk.usage|inode' approved-problems/*/meta.md
   rejected/*/meta.md problems/*/meta.md` -> no hits. Nearest neighbour
   `afero-overlay-deletions` is Adjacent, not Derivative.
7b. EXCLUSIVITY — PASS (diffs pulled, above).
8. DEFINED-BEHAVIOR — PASS. Block and inode accounting is standard filesystem behaviour;
   `statvfs` is POSIX-defined; the maintainer invited a reopen. Nothing is NOT_PLANNED.
9. NO-FLAKY-REPO — OWED. Baseline determinism is measured in the Docker clean room (3x) during
   this slice; the maintainer has disabled the unstable macOS and PyPy tests in-tree.
10. REPO-QUOTA — PASS. 0 of 6 ours, 750 stars (niche band, not presumed globally saturated), no
    entry in SATURATED-REPOS.md.

## TOO-EASY pre-pick guard

1. Single guard at many sites? No. The kernel's contract breaks, and inodes are a second
   mechanism with a different exemption rule (hard links) and a different arming condition.
2. Single-subsystem fully-specified transform? No. `fake_filesystem`, `fake_file`, `fake_os` and
   `fake_filesystem_shutil`, with two hidden-integration walls (the `__getattr__` delegation and
   the `st_nlink`-guarded entry hooks).
3. Hardness depends on the spec NOT stating something? No. Every rule is stated; the fixes stay
   hidden (section 11's CONTRACT-STATED / FIX-HIDDEN check).
4. Port of a memorised spec? No. `statvfs` is a struct layout, not an algorithm; the accounting
   model is pyfakefs's own.
5. Survives being fully spelled out? Yes — the difficulty is wiring one invariant through six
   charge sites in two modules and a module-layer seam in a third.

Death-class taxonomy: no match. Not a support-matrix row, not a maintainer epic with open
numbered stages, not a reverse converter, not a removed capability, not a textbook algorithm
with a sibling implementation (the accounting is per-repo, not an algorithm).

## Phase 5 — failure-mode self-audit

- Bucket 1 (hidden requirements): every test in section 9 traces to a sentence in section 4/6.
  Re-checked at meta.md write time.
- Bucket 2 (tech-spec tone): meta.md is plain prose, no headers, no labels.
- Bucket 3 (tests pass on base): every new test asserts either a new API name or a figure base
  gets wrong. Verified by running the new suite on base.
- Bucket 4 (over-constrained): no test asserts an internal name. `statvfs` fields are asserted by
  name because the meta lists them.
- Bucket 5 (too easy / under floor): see section 7.

Real-revert-cause walk: no hidden requirements, no test.sh trickery, no exact-string assertions
(ENOSPC is checked by `errno`, not by message), no code duplication, no scope creep beyond the
accounting model, no regression on base (default block size 1 keeps every existing assertion),
no AI comments, no weak assertions, no dead code, no ambiguous bounds (every boundary is an
integer with a stated rounding direction), no flaky test (no time, no randomness, no ordering,
no network), no pre-existing test passing in new mode.

Confirmed-blind-spot walk: "unstated inverse" is pre-empted (inode give-back in the same
sentence as the take); "default ordering" does not apply; "reference vs deep copy" does not
apply; "cross-feature ordering" is pre-empted by the rename sentence.

## Why this is not a duplicate

Closest in the corpus: `approved-problems/afero-overlay-deletions` (Go, spf13/afero). That pick
is about which NAMES a copy-on-write overlay shows after a removal — namespace visibility. This
pick is about how much SPACE and how many objects a fake mount accounts for, in a different
language, a different repo and a different subsystem. No shared trap class: afero's traps are
provenance and shadowing; these are rounding arithmetic through a delta kernel and object
lifetime through a link-count guard.

Second closest: `approved-problems/tifffile-ome-pyramid-validation` — unrelated.

Predicted iteration cycles: 2.
