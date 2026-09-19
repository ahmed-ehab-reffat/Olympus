# eval-results.md — tippecanoe-tile-join-size-recourses

**ACCEPTED 2026-09-16 at 1/10 (Nova).** One full-price batch, graded after two ENV-blocked contests were
upheld and those runs replaced. Every failing run failed all 49 new tests (mostly stale binaries), so
the failure reasons below come from each evaluator's static source review, not from the JUnit files.

| Run ID | Verdict | Prompt tok | Src files | New failed | Restored build outputs | Evaluator's primary finding |
|---|---|---|---|---|---|---|
| rd7ckrvd | FAIL_MISSED_REQUIREMENT | 24.8M | 4 | 49/49 (stale) | yes | inherited `tile_size_desired` summed with `+=` (F-33) |
| rd776s2t | FAIL_MISSED_REQUIREMENT | 13.0M | 5 | 49/49 (stale) | yes | strategies recorded for a tile that shed nothing (F-15) |
| rd78nq4m | FAIL_REGRESSION | 15.1M | 3 | 48/49 | yes | segfaults in ordinary joins, `mvt_type -13` |
| rd74p16c | FAIL_MISSED_REQUIREMENT | 21.0M | 3 | 49/49 (stale) | yes | inherited `tile_size_desired` summed (F-33) |
| rd75za6b | FAIL_MISSED_REQUIREMENT | 10.3M | 3 | 49/49 (stale) | yes | strategies recorded for a tile that shed nothing (F-15) |
| rd7bc7cz | FAIL_INTEGRATION_ERROR | 14.8M | 4 (+13 golden JSON edits) | 49/49 (link failure) | yes | const `encode()` vs restored `mvt.o`; also F-15 |
| rd78mncm | FAIL_MISSED_REQUIREMENT | 17.4M | 4 | 49/49 (stale) | yes | `+=` merge (F-33); unsheddable tile's size dropped (F-15 mirror) |
| **rd79de2m** | **PASS_LEGITIMATE** | **9.6M** | **5 (+17 .o)** | **0/49** | **no** | FP panel: genuine pass; only `-M` junk input unvalidated |
| rd70n6gm | FAIL_MISSED_REQUIREMENT | 11.5M | 3 | 49/49 (stale) | yes | strategies recorded before knowing anything was dropped (F-15) |
| rd7fzd6r | FAIL_WRONG_LOGIC | 17.7M | 5 | 49/49 (timeout) | yes | one-feature-at-a-time re-encode, killed at 1785 s |

Totals: F-15 4 (+1 mirror), F-33 3, regression 1, quadratic 1. Artifact restores 9/10, stale or
unlinked grading 7/10. `description_clear: true` 10/10. Final Auto Review: Description 3/3, Tests 2/3
(directory-output `-e` untested), Solution 3/3.

## Long-horizon floor to clear

| Floor | Required | Reference (measured) |
|---|---|---|
| effective LOC (Counter 2 / `human-effective`) | >= 200 | **294** (460 raw) |
| files changed | >= 2 | **5** (`tile-join.cpp`, `mvt.cpp`, `mvt.hpp`, `README.md`, `man/tippecanoe.1`) |
| solver-median messages | >= 40 | not reported; failing-run median 15.1M prompt tokens |
| pass rate | > 0%, <= 40% | **1/10 = 10%** |

## Pre-batch validation, Round 8 patches (`worktrees/_tj_tools/cleanroom.sh`)

Pristine base, platform image, `--network none`, `TIPPECANOE_MAX_THREADS=64` forced from outside.
The script asserts the clone root and HEAD, checks patch markers after applying, and requires a clean
`git status` after reverting.

| Stage | Result |
|---|---|
| apply + revert, test then solution | ok, markers present, tree clean |
| apply + revert, solution then test | ok, markers present, tree clean |
| base mode on base, 3 runs | 36/36 each, identical |
| new mode on base | **0/49** |
| base mode with solution, 3 runs | 36/36 each, identical, JUnit 36 testcases |
| new mode with solution, 3 runs | 49/49 each, identical, JUnit 49 testcases, parses, 0 failures |
| `docker build` of the submission Dockerfile on the patched tree, from clean | ok |
| both modes in that image, `--user 1000:1000 --network none` | new 49/49, base 36/36 |

## Test-first and mutation checks

| Check | Result |
|---|---|
| Round 7 binary: `tile_size_desired_counts_a_tile_too_large_to_shed` | FAILED (6841, the tile that shed) |
| Round 7 binary: `bounds_follow_features_rescaled_into_a_larger_extent` | FAILED (minlon 60, maxlat -51, stale) |
| ties broken by per-layer position | cross-input tie test FAILS; single-layer tie test PASSES (gap confirmed) |
| desired size recorded for any oversized tile | all three skip-without-shedding tests FAIL |
| `--maximum-tile-bytes` parsed but ignored | long-form test FAILS on its size assertion |
| Round 7: Catch2 `<error>` masked by the old adapter | fixed adapter reports it FAILED |
| Round 7: key pool untouched / booleans stringified | respective tests FAIL |
| Round 6: summed inherited size, assigned drop counts, point extent from bbox | respective tests FAIL |
| correct solution | all PASS |
