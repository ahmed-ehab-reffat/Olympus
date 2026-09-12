# Statig local transitions archive manifest

Archived on 2026-07-26 after platform acceptance.

## Canonical accepted package

The live package remains under `problems/statig-local-transitions/` with its
canonical `meta.md`, `test.patch`, `solution.patch`, `Dockerfile`,
`solution_approach.md`, compact lifecycle records, and verification scripts.
Before cleanup, the exact package passed:

- artifact audit: 197 ASCII words, 349 production lines, exact file lists;
- all four patch-state gates in the network-disabled Rust 1.90 image;
- 46 focused reference tests;
- 23 baseline tests and 22 doctests; and
- all 33 false-positive mutation checks.

Acceptance was confirmed by the user on 2026-07-26.

## Raw solver evidence

- Archive: `agent-runs.tar.gz`
- Original paths: `problems/statig-local-transitions/agent-runs` through
  `agent-runs8`
- Contents: 39 run directories and 312 evidence files, excluding four
  `.DS_Store` files
- Original disk usage: approximately 30 MB
- Compressed size: approximately 4.2 MB
- SHA-256:
  `b7e1225486ccd3c4ae59d833c793c52ad6e2350f7a548ca51743649a8e16255a`
- Integrity check: `gzip -t
  archive/statig-local-transitions/agent-runs.tar.gz`

Restore the raw collections from the Olympus root with:

```bash
tar -xzf archive/statig-local-transitions/agent-runs.tar.gz \
  -C problems/statig-local-transitions
```

The compact run matrix remains in `problems/statig-local-transitions/RUNS.md`.

## Dirty worktree recovery

- Archive: `worktree-recovery.tar.gz`
- SHA-256:
  `7d1559d24e0e29ddef40f44b6ceb7fb5aedc90e2e0039dd892aa4e167d84de39`
- Compressed size: approximately 28 KB
- Pinned commit:
  `3780eecdbcf4326051c38676d592c6c2b4a3bab5`

The archive preserves:

- `probe/tracked-and-staged.patch` plus its untracked
  `statig/tests/transition_boundaries_macro.rs`;
- `solution/tracked-and-staged.patch` plus its eight untracked test-harness
  source files; and
- `tests/tracked-and-staged.patch`.

These worktrees were not silently treated as canonical. Their diffs differ from
the final accepted patches and are retained as historical recovery evidence.
Generated `target/` trees, generated Cargo locks, and `.DS_Store` files were
intentionally omitted.

To inspect or recover:

```bash
mkdir -p /tmp/statig-recovery
tar -xzf archive/statig-local-transitions/worktree-recovery.tar.gz \
  -C /tmp/statig-recovery
git clone https://github.com/mdeloof/statig /tmp/statig-checkout
git -C /tmp/statig-checkout checkout \
  3780eecdbcf4326051c38676d592c6c2b4a3bab5
git -C /tmp/statig-checkout apply \
  /tmp/statig-recovery/probe/tracked-and-staged.patch
tar -xzf /tmp/statig-recovery/probe/untracked-files.tar.gz \
  -C /tmp/statig-checkout
```

Substitute `solution` or `tests` for `probe` as needed. The `tests` recovery
contains no separate untracked archive because all of its source files were
staged and are present in its patch.

## Authoring-record snapshot

- Archive: `retired-artifacts.tar.gz`
- Members: `PLAN.md`, `adjustment.md`, and `false_postive trials.md`
- SHA-256:
  `317f55a2cc0996dc72c755ff6327bcf2a6728aab41e28fc470c025817a10afa6`
- Compressed size: approximately 28 KB

The accepted problem keeps the consolidated `SUMMARY.md`, `LEVELS.md`,
`ERRORS.md`, `DESIGN.md`, and `RUNS.md`. `PLAN.md` and `adjustment.md` were
retired. `false_postive trials.md` remains live because `AGENTS.md` designates
it as the repository-wide worked false-positive reference; this archive holds
its acceptance-time snapshot. All three records can be recovered exactly with:

```bash
tar -xzf archive/statig-local-transitions/retired-artifacts.tar.gz \
  -C problems/statig-local-transitions
```

## Cleanup result

The following reproducible local state was retired after the archives passed
gzip and member-list checks:

- the eight raw `problems/statig-local-transitions/agent-runs*` collections;
- `work/statig-local-transitions/probe`
- `work/statig-local-transitions/solution`
- `work/statig-local-transitions/tests`
- `work/statig-local-transitions/source`
- the empty `work/statig-local-transitions/` namespace
- Docker image `statig-local-transitions:verification`

This removed approximately 7.1 GB of checkout/build data plus a 7.72 GB
reproducible verification image. The archives and Git checkpoint are the
recovery paths.
