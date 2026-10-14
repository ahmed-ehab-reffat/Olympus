NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

# pyfakefs-advisory-file-locks - feedback

## Status (2026-09-29, factory MODE=SLICE)
SLICE-READY. Core slice built and clean-room validated; no differentiating scope yet.
- Repo pytest-dev/pyfakefs (Apache-2.0, 753 stars, canonical org unchanged), base 796c48eb = main HEAD
  (2026-09-22). Quota: 2/6 with this one (first: approved pyfakefs-block-inode-accounting), 0 this week.
- Lane: hunt #37 (REPO-HUNT-2026-09-29-C) Fallback 2, advisory locks + open-file-description lifetime.
- Slice: 4 source files, 317 raw / 273 human-effective (hook), 12 new tests.
- Clean room (git clone at base + test.patch, image `factory-pyfakefs-advisory-file-locks`, --network
  none) as 1000:1000, 0:0, 4242:4242, 4242:0, 0:4242: base 1421 passed (1415 as root, root skips 6
  permission tests), 0 failed, with and without the solution; new 12/12 fail without the solution,
  12/12 pass with it. JUnit: 2399 base ids, no duplicates, no `::`. git status in the image shows only
  test.sh and the new test file.
- Reference checked against real Linux with a 46-cell oracle (`worktrees/pyfakefs-locks-tools/oracle.py`,
  `cmp.sh`): 0 mismatches. Base fails every cell.
- Repo lint: ruff 0.16.7 (format + check), pyupgrade 3.21.2 --py310-plus clean; mypy 2.3.1 shows only the
  pre-existing pyarrow import error.

## Scope-lock gates (all run by me, 2026-09-29)
- PICK-FILTER 1 (behavioural F2P gap): reproduced on base. No flock/record/OFD conflict, GETLK echoes the
  query, write lock on O_RDONLY accepted, os.lockf forwarded to the REAL os, dup + close(original) +
  read(dup) raises ValueError, and dup2 onto a dup'd descriptor closes the ORIGINAL descriptor (new
  finding, `add_open_file` calls `f.close()` -> `close_fd(f.filedes)`).
- Gate 5 (cold capability): nobody building locks; fake_io.py last functional change 2026-02; 4 open PRs,
  none in fcntl/dup/close/fd table.
- Gate 6 (reproduce on base): done through the public API under Patcher (probe1.py, hunter's lock probe).
- Gate 7b / exclusivity PR-DIFF: canonical `pytest-dev/pyfakefs`; PR classes flock, fcntl, lockf, lock,
  locking, F_SETLK, advisory, dup, dup2, file descriptor, open file description, portalocker, filelock.
  Hits #646, #1075, #985, #989 - diffs read: no-op patching, constant forwarding, dup/dup2 add, close-order
  fix. None has lock state, owners, ranges, a description refcount or the dup2 fix. CLEAN.
- Gate 8 (philosophy): #645 maintainer leaned toward emulating "at least part"; CHANGES.md 4.x "mocked ...
  may be changed in the future if needed, see #645". #697's "low-level OS stuff we cannot emulate" is
  about ioctl return values. No decline. Semantics defined by Linux.
- SIX-CHECK: literal + namespace searches above; philosophy scan above; closed-with-implemented: #988 fixed
  close ORDER only (our lifetime cell still fails on HEAD); base..main 0 commits; functional check = Gate 1.
- Sibling ecosystem: no fake filesystem ships byte-range lock emulation (gh code search).
- Local dedup: no lock/fcntl/dup feature class in approved-problems/, problems/, rejected/. SATURATED-REPOS
  has no pyfakefs row.

## Decisions made unattended (conservative choices)
- Kept the hunted lane (it cleared every gate); fallbacks not needed.
- Blocking requests: the fake has one process, so a request that would wait raises EDEADLK and changes
  nothing (documented in meta.md). A refused flock conversion drops the old lock, as Linux does (checked
  on the host).
- meta.md does NOT promise "whatever Linux does" (L80 unbounded host-semantics ratchet); it states each
  tested rule. The reference also rejects a non-zero l_pid on OFD commands and F_UNLCK on GETLK with
  EINVAL, untested and unstated.
- Other fcntl commands keep base behaviour (0 for an int arg, the arg for bytes) and meta.md says nothing
  about them: that is the planned F-20 cell (documented in docs/troubleshooting.rst and CHANGES.md, no
  repo test) and the one codebase-inferable requirement. Test lands in FINISH.
- closefd=False file objects: closing one closes no descriptor, so record locks stay. Left implied by
  "closes any descriptor" (Python's documented closefd semantics); replay before relying on it (L100).
- Base-mode deselects copied from the accepted pyfakefs problem (proven on the platform): TestClassSetup
  (collection errors under pytest, reproduced here as root and 4242), test_write_tmp_windows and
  test_empty_path (host temp-dir / real-fs comparisons; pass locally, failed on the platform host last
  time), test_owner_and_group_posix (fails as unmapped uid 4242, reproduced). Reasons kept here, not in
  test.sh. Base mode also runs pyfakefs/pytest_tests/fake_fcntl_test.py, the only existing fcntl test.
- Dockerfile: `COPY --chown=1000:1000`, `chmod -R a+rwX /app` (4 MB tree, cheap; needed so uid 4242 can
  write the repo files four RealFileSystemAccessTest cases open read-write), safe.directory, uid-1000 user.
  Cold build 19 s.
- meta.md is 565 words with frontmatter (over the 500 soft warning, under the 1000 reject). Trim in FINISH
  if a precheck flags it.

## FINISH plan (from DESIGN.md)
Full release matrix (owner kind x close event incl. closefd=False, file-object close, hard-link path,
dup2 implicit close), EDEADLK on every waiting entry point, twin entry points incl. `from os import lockf`,
filesystem isolation across Patcher sessions, F-20 other-commands cell, ranges (len 0 beyond EOF, negative
length, SEEK_CUR after read/lseek, SEEK_END, EINVAL), EBADF per kind, flock conversion drop, GETLK
lowest-piece, rename / unlink-recreate. Mutation sweep, 3x flakiness, LOC re-check.
