# eval-results.md — sfepy-modal-analysis

## Local validation

Re-run end to end on the final image (exact pins, editable install) after the
platform pre-check fixes and ten rounds of coverage suggestions (108 tests
grown to 185). The solution changed in round 13, when a coverage suggestion exposed the
load-restriction defect, so the base mode was re-run against the final
artifact.

| Check | Command | Result |
|---|---|---|
| vanilla suite, offline | `pytest sfepy/tests` in the base image | 221 passed / 0 failed, 15m44s |
| base mode after both patches | `./test.sh base` | 221 passed / 0 failed, 14m56s |
| new mode on base | `./test.sh new` with test.patch only | 185 failed / 0 passed |
| new mode with solution | `./test.sh new` with both patches | 185 passed |
| apply order test then solution | `git apply test.patch; git apply solution.patch` | clean, new mode 185 failed then 185 passed |
| apply order solution then test | `git apply solution.patch; git apply test.patch` | clean, new mode 185 passed |
| determinism | `./test.sh new` x3 with the shipped patches | 185 passed each run |
| editable install | `python -c "import sfepy"` from `/` | resolves to `/app/sfepy`, extensions load from the source tree |
| effective LOC | `effective_loc_check.py solution.patch` | human-effective 453, 3 files |
| mutation battery | 8 single mutations of `modal.py` | every one killed by at least one test |

## Agent runs

### Batch 1 (6 runs, before the description fix): 0/6 PASS -- UNSOLVABLE

| Agent | Verdict | Failed | Of which LCBC refusals | Other failures |
|---|---|---|---|---|
| Nova_1 | FAIL | 5 | 4 | empty-solution response |
| Nova_2 | FAIL | 9 | 4 | damped transient recurrence, normalization invariance |
| Nova_3 | FAIL | 10 | 4 | transient exactness, 3D rotations, 1D solve |
| Nova_4 | FAIL | 37 | 1 | modes stored row-wise instead of a column per mode |
| Nova_5 | FAIL | 3 | 3 | none |
| Orion | FAIL | 26 | 4 | response arrays transposed, transient exactness |

Root cause, one description defect: when the scattered refusals were folded into
a single `ValueError` list (round 16), the linear-combination refusals were left
out of that list, and the only remaining statement said those operations "do
not" hold under such conditions without ever saying they raise. Four tests rest
on that sentence and they fail in 6, 6, 6 and 5 of the six runs. Nova_5 failed
NOTHING else.

Two lesser gaps compounded it: the mode arrays never stated a column per mode
(Nova_4 stored them row-wise and lost 37 tests), and the response arrays never
stated a row per frequency or per sample (Orion transposed them).

Replaying the recorded failures against the fixed description: Nova_5 passes on
the LCBC fix alone, Nova_1 drops to one failure. That puts the batch at 1/6 with
the transient-exactness cluster still holding the rest down, which is the
difficulty the problem is meant to carry.

### Batch 2 (5 runs, after the LCBC fix): 0/5 PASS, but close

| Agent | Failed | Failures |
|---|---|---|
| Nova_1 | 2 | the 1D pair only |
| Nova_2 | 2 | the 1D pair only |
| Nova_3 | 5 | damped ramp, base response x2, normalization invariance, nonzero EBC |
| Nova_4 | 5 | the 1D pair, plus three Rayleigh formula tests |
| Nova_5 | 3 | transient exactness x3 |

The LCBC fix worked completely: not one linear-combination refusal failed,
where four of them had failed in five or six of the six runs before it.

What replaced it was the many-small-pins shape, and one pin dominated. Two
tests, `test_solve_modes_takes_a_one_dimensional_field` and
`test_rigid_body_vectors_refuse_a_one_dimensional_problem`, fail together in
three of five runs from a single cause: the agent refuses a one dimensional
problem in `solve_modes`, which also breaks the rigid-vector test in its setup
line. That reading is fair against a description that speaks of vector fields
and of two and three dimensions throughout, and a one dimensional vector field
is a degenerate corner carrying no part of the feature. Both tests and the
matching refusal are cut.

Nova_1 and Nova_2 fail nothing else, so the cut takes the batch to 2/5.

### Batch 3

Pending a re-run at 185 tests.
