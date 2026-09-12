# eval-results.md — metpy-parcel-trajectories

## Local validation

| Check | Result |
| --- | --- |
| bare `pytest` on the vanilla tree | 1633 passed, 8 skipped, 2 xfailed (the Environment Quality command) |
| `test.sh base` on base tree | 1624 passed, 8 skipped, 2 xfailed |
| `test.sh new` on base tree | 152 failed, 152 JUnit test cases |
| `test.sh new` with solution | 152 passed |
| `test.sh base` with solution | 1624 passed, 8 skipped, no regressions |
| test.patch then solution.patch | both apply |
| solution.patch then test.patch | both apply |
| reverse apply | both unapply |
| new mode repeated 3x | identical (153 passed each) |
| base mode repeated 3x | identical (1624 passed each) |

## Mutation battery

Fifteen mutations of the reference, each run against the new suite. All are killed, before and
again after the Test Fairness rewrite; the table lives in feedback.md. The five that kill more than ten tests (missing cosine of latitude,
ascending-only axes, clamping instead of terminating, Euler stepping, stage times) are the
interdependent core.

## Agent runs

### Batch 1 (6 runs, 0 passed) - artifact at 152 tests

| Agent | Verdict | Failed | Failure clusters |
| --- | --- | --- | --- |
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 25 | termination semantics, density, all-NaN warnings |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | 15 | density (per-step vs per-sample), bracket scan order, step zero |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 5 | weights type, keyword-only track, pole |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 14 | density, step zero, pole |
| Nova_Nova_5 | FAIL_KNOWLEDGE_GAP | 52 | sampling and the reporting API broadly |
| Orion_Nova | FAIL_MISSED_REQUIREMENT | 8 | step zero x3, all-NaN warnings x2, density, start width |

No test failed in all six runs, so there was no single universal miss. The failures clustered
on five ambiguities instead, each of which cost several runs. Best run: 5 failures of 152.

### Diagnosis and repair

| Cause | Runs hit | Repair |
| --- | --- | --- |
| step zero after an impossible first step | 4 | meta states it is always reported |
| density counting convention | 4 | switched to elapsed time and stated the total |
| `weights` type | 5 | meta names it; reference takes any of the three forms |
| all-NaN slice warnings raised as errors | 2 | test module ignores RuntimeWarning |
| bracket scan order on a descending axis | 1 | meta says the order the coordinate stores |
| three dimensional density | 3 | requirement removed |

Replaying the six patches against the repaired artifact, every remaining failure of the best
run maps to a rule the description now states outright.
