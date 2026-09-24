# eval-results.md - bayesopt-search-space-migration

No platform batch yet.

## Local validation

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-23 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-23 | Docker, uid 0/1000/4242, offline | new on base | 30 | 30 fail (AttributeError set_space) |
| 2026-09-23 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-23 | Docker, uid 0/1000/4242, offline | new on solution | 30 | 30 pass |
| 2026-09-23 | Docker uid 1000 x3 | all four cells | - | per-test verdicts identical x3 |

Hook (slice): human-effective 140, raw 256, 4 files. Mutants: 11/11 real mutants killed (1 equivalent).

## Local validation after precheck round 1 (2026-09-24, reworked test.patch)

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on base | 34 | 34 fail (all AttributeError set_space) |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on solution | 34 | 34 pass |
| 2026-09-24 | Docker x3 runs x3 uids | all four cells | 402 verdicts | identical across all 9 |

Mutants: 14/17 killed; M9, M14, M17 equivalent for these fixtures (see feedback.md). Hook: human-effective 140 (unchanged, FINISH owed).

## Local validation after precheck round 2 (2026-09-24, solution + tests + meta changed)

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on base | 49 | 49 fail (all AttributeError set_space) |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on solution | 49 | 49 pass |
| 2026-09-24 | Docker x3 runs x3 uids | all four cells | 432 verdicts | identical across all 9 |

Hook: human-effective 218, raw 343, 5 files. Reducer/liar mutants: 9/10 killed (R9 unobservable, see feedback.md).

## Local validation after precheck round 3 (2026-09-24, solution + tests changed)

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on base | 57 | 57 fail (all AttributeError set_space) |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on solution | 57 | 57 pass |
| 2026-09-24 | Docker x3 runs x3 uids | all four cells | 448 verdicts | identical across all 9 |

Hook: human-effective 231, raw 359, 5 files.

## Local validation after precheck round 4 (2026-09-24, solution + tests + meta changed)

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on base | 64 | 64 fail (all AttributeError set_space) |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on solution | 64 | 64 pass |
| 2026-09-24 | Docker x3 runs x3 uids | all four cells | 462 verdicts | identical across all 9 |

Hook: human-effective 234, raw 364, 5 files.

## Batch 1 (2026-09-24, platform, round-4 artifact): 0/11 PASS (10 Nova + 1 Orion, all graded by Nova)

| Run | Verdict | Requests | Min | +LOC | Failed tests | Approach note |
|---|---|---|---|---|---|---|
| Nova #10 (Nova_Nova_1) | FAIL | 108 | 13 | 644 | liar_coincide[False], gphedge_partial x2 | no dummy dedup; GPHedge all-or-nothing |
| Nova #1 (Nova_Nova_10) | FAIL | 74 | 8 | 636 | gphedge_partial x2 | GPHedge all-or-nothing ("same incompatibility rule") |
| Nova #9 (Nova_Nova_2) | FAIL | 81 | 8 | 503 | gphedge_partial x2 | new TargetSpace object; GPHedge all-or-nothing |
| Nova #8 (Nova_Nova_3) | FAIL | 79 | 11 | 514 | gphedge_partial x2 | GPHedge all-or-nothing |
| Nova #7 (Nova_Nova_4) | FAIL | 107 | 12 | 721 | 4 reducer twins, gphedge_partial x2 | reducer state not continued |
| Nova #6 (Nova_Nova_5) | FAIL | 73 | 8 | 547 | gphedge_partial x2 | deepcopy constraint; GPHedge all-or-nothing |
| Nova #5 (Nova_Nova_6) | FAIL | 64 | 8 | 484 | liar_coincide[False], gphedge_partial x2 | no dummy dedup |
| Nova #4 (Nova_Nova_7) | FAIL | 66 | 6 | 519 | liar_coincide[False], gphedge_partial x2 | no dummy dedup |
| Nova #3 (Nova_Nova_8) | FAIL | 93 | 10 | 631 | 6 acquisition undo twins, 4 reducer twins, gphedge_partial x2 | consumes RNG / state reset |
| Nova #2 (Nova_Nova_9) | FAIL | 73 | 8 | 408 | liar_coincide[False], gphedge_partial x2 | no dummy dedup |
| Orion #1 (Orion_Nova) | FAIL | 126 | 15 | 777 | gphedge_partial x2 | GPHedge all-or-nothing ("only shape-safe option") |

Kill counts: gphedge_partial 11/11 (both cases), liar_coincide[False] 4, reducer twins 2, acquisition undo twins 1. Median 79 requests.
Probes over all 11 saved patches (worktrees/_bo_tools/probe_cases*.py): 0 divergence on integer ties, queued integer retype,
numpy/negative reals, chained vs direct changes, save/load after a change. EI/PI with every point out of bounds: all 11 raise
(same as the round-4 reference). Constrained suggestion vs a fresh twin: 7/11 differ, but only because a rebuilt ConstraintModel
shares the optimizer RNG object -> RNG plumbing, not a model bug -> NOT a fair lever.

## Local validation, round 5 (2026-09-24, meta + solution + tests changed)

| Date | Where | Mode | Cases | Result |
|---|---|---|---|---|
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on base | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on base | 72 | 72 fail (all AttributeError set_space) |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | base on solution | 167 | 167 pass |
| 2026-09-24 | Docker, uid 0/1000/4242, offline | new on solution | 72 | 72 pass |
| 2026-09-24 | Docker x3 runs x3 uids | all four cells | 478 verdicts | identical across all 9 |

Hook: human-effective 238, 5 files.
