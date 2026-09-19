# eval-results.md — featurevisor-target-specialization

## Batch 1 (2026-09-19, 10x Nova) — 2/10 legitimate (20%); Auto Review: Revision Requested

Artifacts: `agent-runs/1/<run>/` (solution-patch, junit, eval-result, trajectory).

| Run | Verdict | new | base | Failed / reason | Approach note |
|---|---|---|---|---|---|
| Nova_1 | PASS_LEGITIMATE | 28/28 | 1033/1033 | - (shares the scalar `"\"*\""` parse gap) | isolated tri-state specializer |
| Nova_9 | PASS_LEGITIMATE | 28/28 | 1033/1033 | - (shares the scalar gap) | isolated tri-state specializer |
| Nova_5 | PASS_CHEATED | 28/28 | 1033/1033 | edited existing test files | - |
| Nova_10 | FAIL_MISSED_REQUIREMENT (static) | 28/28 | 1033/1033 | prunes requiredFeatures-only rule overrides (no test caught it) | treats "neither selector" as never |
| Nova_3 | FAIL_REGRESSION | 28/28 | 1013/1033 | rewrote shared applyContextToConditions/Segments helpers | tri-state inside shared helpers |
| Nova_4 | FAIL_REGRESSION | 28/28 | 997/1033 | same, 36 helper specs | same |
| Nova_6 | FAIL_REGRESSION | 28/28 | 1003/1033 | same, 30 helper specs | same |
| Nova_2 | FAIL_MISSED_REQUIREMENT | 22/28 | 1033/1033 | 6 seeded batches: no Array branch inside and/or/not | stateful walker, no nested lists |
| Nova_8 | FAIL_MISSED_REQUIREMENT | 22/28 | 1033/1033 | same 6 seeded batches | same |
| Nova_7 | FAIL_MISSED_REQUIREMENT | 27/28 | 1032/1033 | global override AND of selectors; emits `[]` for an empty segment list | single-selector global rule |

Kill map: S3 shared-helper regression 3/10 · nested-list recursion 2/10 · requiredFeatures-only 1/10
(static) · global selector AND 1/10. Scalar-stringified catch-all: 10/10 carry it (and the R0 reference).

## Replay of batch 1 against R1 test.patch (local, `worktrees/_tools/fvreplay-target.sh`)

| Run | R1 new | Newly failing |
|---|---|---|
| Nova_1 | 31/33 | scalar catch-all x2 |
| Nova_9 | 31/33 | scalar catch-all x2 |
| Nova_10 | 30/33 | requiredFeatures-only + scalar x2 |
| Nova_6 | 33/33 | (still fails baseline) |
| others | fail | scalar x2 on top of their batch-1 failures |

## Batch 2 (2026-09-19, 10x Nova, R2 artifact) — 3/10 legitimate (30%); Auto Review Approved; ACCEPTED

| Run | Verdict | new | base | Failed / reason | +LOC files |
|---|---|---|---|---|---|
| Nova_2 | PASS_LEGITIMATE | 33/33 | 1033/1033 | - | 883 / 5 |
| Nova_4 | PASS_LEGITIMATE | 33/33 | 1033/1033 | - | 780 / 5 |
| Nova_5 | PASS_LEGITIMATE | 33/33 | 1033/1033 | - | 892 / 5 |
| Nova_7 | PASS_CHEATED | 33/33 | 1033/1033 | edited existing test files | 893 / 6 |
| Nova_1 | FAIL_REGRESSION | 33/33 | 1003/1033 | rewrote shared helpers (30 specs) | 920 / 4 |
| Nova_3 | FAIL_REGRESSION | 33/33 | 998/1033 | same (35) | 940 / 4 |
| Nova_9 | FAIL_REGRESSION | 33/33 | 1008/1033 | same (25) | 1021 / 7 |
| Nova_10 | FAIL_REGRESSION | 33/33 | 999/1033 | same (34) | 814 / 5 |
| Nova_6 | FAIL_MISSED_REQUIREMENT | 32/33 | 1033/1033 | `not` over a decided-false child and an undecided child | 712 / 5 |
| Nova_8 | FAIL_MISSED_REQUIREMENT | 27/33 | 1033/1033 | 6 seeded batches: no Array branch in the group-segment walker | 794 / 5 |

Kill map (new tests, wipeouts excluded): 6 seeded batches 1 each (Nova_8), `not` decided-false 1 (Nova_6);
**26 of 33 killed nothing** (scalar catch-all pair, stringified override cells, requiredFeatures-only, every
force/global cell, build-path tests). Base: 4/10 runs failed the helper specs. FP panels upheld all 3 passes
(one solo judge dissent each on out-of-scope probes: scalar-JSON segment keys the builder never writes, a
required feature disabled by a 0% rule).
