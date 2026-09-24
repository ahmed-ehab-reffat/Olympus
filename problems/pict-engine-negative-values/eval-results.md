# pict-engine-negative-values - eval results

No platform batch yet. Local validation numbers are logged below as they are measured.

## Local validation - SLICE (2026-09-23)

Image `factory-pict-engine-negative-values` built from a pristine clone at base (no patch in the
context), Dockerfile with `COPY --chown=1000:1000` + targeted `find ... chmod` (coordinator rule),
cold build ~10 s. test.patch then solution.patch applied inside the container, `--network none`.

| uid | base on base | new on base | base with solution | new with solution |
|---|---|---|---|---|
| 1000 | 588/588 pass | 28/28 fail | 588/588 pass (x3 identical) | 28/28 pass (x3 identical) |
| 0 | 588/588 pass | 28/28 fail | 588/588 pass | 28/28 pass |
| 4242 | 588/588 pass | 28/28 fail | 588/588 pass | 28/28 pass |

- New-on-base failure reasons: API tests `undefined symbol: PictSetNegativeValue`; CLI tests fail
  the stated properties (missing child negatives, seeds) or the pict exit code (two-valued seeds
  assert on base).
- JUnit ids unique, no `::` (588 base, 28 new).
- Effective LOC (hook): 252 human-effective, 419 raw, 13 files.
- Mutants: no partner rows (naive CLI port) -> 9/28 fail; one partner row per child -> 1/28 fail
  (only the wide CLI model; FINISH adds API cells).

## Local validation - R2 after Auto Review (2026-09-24)

Clean room `worktrees/_pict_cr` (fresh clone at base with .git, image from the submission
Dockerfile, both patches applied in the container, `--network none`). Build 51 s.

| uid | base on base | new on base | base with solution (x3) | new with solution (x3) |
|---|---|---|---|---|
| 1000 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |
| 0 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |
| 4242 | 588/588 pass | 33/33 fail | 588/588 pass, identical | 33/33 pass, identical |

- New tests (5): public-header client, lifecycle leak client, two model-tree exclusion tests, one CLI
  constraint test. Two existing marking tests widened.
- Mutants: old PictDeleteModel -> lifecycle fails (80 live allocations); old pictapi.h with stale
  lib -> header fails, ctypes marking test passes; user exclusions dropped from child models in the
  negative phase -> only the new API tree test + new CLI test fail; user exclusions dropped from the
  negative phase everywhere -> flat, tree and CLI exclusion tests fail.
- Effective LOC (hook): 257 human-effective, 13 files.

## Local validation - R3 (2026-09-24, tests only)

Same clean room, image pict-cr:r2, `--network none --memory 2g`, one uid at a time (an earlier
three-uid background run was reaped for low host memory).

| uid | base on base | new on base | base with solution (x3) | new with solution (x3) |
|---|---|---|---|---|
| 1000 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |
| 0 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |
| 4242 | 588/588 pass | 37/37 fail | 588/588 pass, identical | 37/37 pass, identical |

- CLI tests no longer load libpict.so; checked against a base-built pict binary, all 7 fail on base
  through CLI behaviour (missing negatives / coverage), not on import.
- Pairwise-join mutant (models with children and their params capped at order 2): fails the new
  API order-3 test and the new CLI order-3 test.

## Local validation - R4 (2026-09-24)

Clean room as R3 (`--memory 2g`, one uid at a time). uid 1000, 0, 4242: base 588/588 pass with and
without the solution; new 39/39 fail without, 39/39 pass with, 3 identical runs each. Lifecycle
mutants (PictDeleteModel no-op + PictDeleteTask frees tree; root-only params; params deferred to
the task) all fail the lifecycle test. 253 human-effective.
