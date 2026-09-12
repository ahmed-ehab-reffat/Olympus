# moov-ach archive manifest

Archived on 2026-07-23 after platform acceptance.

## Raw platform trajectories

- Archive: `actual_trajectories.tar.gz`
- Original path: `problems/moov-ach/actual_trajectories/`
- Contents: 14 run directories, 112 files, plus directory entries
- Original disk usage: approximately 17 MB
- Compressed size: approximately 2.4 MB
- SHA-256: `d767d1180b0729ac7daa3d93eeef6db56460cb6337679ecc8d880ada4e4c9537`
- Integrity check: `gzip -t archive/moov-ach/actual_trajectories.tar.gz`

Restore from the Olympus root with:

```bash
tar -xzf archive/moov-ach/actual_trajectories.tar.gz -C problems/moov-ach
```

The compact human-readable run history remains in `problems/moov-ach/RUNS.md`. Git history before the archival commit also contains every original file individually.

## Retired duplicate and planning artifacts

- `problems/moov-ach/PLAN.md` was retired after acceptance. Its unique decisions and outcomes are represented in `SUMMARY.md`, `LEVELS.md`, `ERRORS.md`, `DESIGN.md`, and `RUNS.md`. Archived SHA-256: `84a710730a1dd3e5863076e7a2870f98ae1fe195619135943692918d976fd7a5`.
- `problems/moov-ach/reference_solution.patch` was removed because it was byte-identical to the canonical `solution.patch`. Both had SHA-256 `e5d189b36ca0505186bd7093f5ba0c8da11578db0e929c02edbd87364991282c`.

Either retired file can be inspected or restored from commit `543a814` with `git show 543a814:<path>` or `git restore --source=543a814 -- <path>`.
