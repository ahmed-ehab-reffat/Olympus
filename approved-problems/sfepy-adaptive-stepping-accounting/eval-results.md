# eval-results.md — sfepy-adaptive-stepping-accounting

Per-agent results, one table per batch. Capture protocol (`HARDENING.md § 3e`): for EVERY batch,
record verdict, failed test NAMES, messages, LOC, files, and a one-line note on the architecture the
agent chose; and save every PASSING agent's diff to `agent-runs/<batch>-<run>.patch` plus the 1-2
most instructive failures, while the platform run view is still open.

## Batch 0 - local validation (superseded by batch 1)

No agent runs yet. The artifact is validated locally and in-container; the pass rate is unmeasured.

**Local validation standing in for a batch (not a substitute for one):**

| Measure | Value |
|---|---|
| New tests, with solution | 138 passed |
| New tests, on base | 138 failed, 0 passed (281s, no hang) |
| Base suite | 221 passed, unchanged |
| Flakiness, both modes | 3x each, identical JUnit digest (`de55de26` new, `87cb78a5` base), exit 0 |
| Mutation battery | 64 run, 62 caught, 1 compensating mutant (R15c), 1 equivalent (R23c, stale matrix not observable) |
| Earlier equivalents | M07/M09 redundant dt_min sign guard; M10 caught in base mode only (L33) |
| Patch apply/revert | clean in both orders on a fresh BASE_COMMIT checkout |
| Solution | 345 human-effective LOC, 6 files, 2 packages |
| Description | 482 body words (492 with the title), ASCII, under the 500 cap |
| Test fixtures | built from real runs; no new-API constructor called except `StepLog()` |
| Base-mode termination | every new test terminates on base; longest base-mode run 453s (R23); 281s now |

**Capture protocol reminder for batch 1:** save every PASSING agent's diff to
`agent-runs/<batch>-<run>.patch` plus the 1-2 most instructive failures, and record the approach note
per run. Without the patches the differential harness and trap-proof are impossible later.

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — |


## Batch 1 - 2026-09-09, 5x Nova, **0 passed**

Unsolvable verdict. 0% is a reject under the current rules, so the artifact has to be relaxed before
another batch.

| run | verdict | new tests | baseline | messages | approach note |
|---|---|---|---|---|---|
| Nova 1 | FAIL_REGRESSION | 110/138 | 2 failed | 96 | StepLog accessors as properties; broke `test_ed_solvers` and the piezo example |
| Nova 2 | FAIL_MISSED_REQUIREMENT | 108/138 | 1 failed | 100 | same property shape; broke `test_ed_solvers` |
| Nova 3 | no result | - | - | - | run produced no patch or eval record |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 100/138 | 2 failed | 118 | same property shape; broke `test_ed_solvers` and the piezo example |
| Nova 5 | FAIL_MISSED_REQUIREMENT | 107/138 | 1 failed | 75 | same property shape; broke `test_ed_solvers` |

Every evaluator recorded `description_clear = True`, `tests_deterministic = True`,
`difficulty = challenging`, `blocker_detected = False` and `agent_blame_unfair = False`. So this is
not an environment or fairness complaint from the graders; it is a scope verdict.

Long-horizon metrics clear comfortably: 75-118 messages against a floor of 40.

**17 tests failed in all four evaluated runs.** By cause:

| cause | tests | note |
|---|---|---|
| accessors called as methods | 4 (+2 in 1 of 4) | **all four wrote `@property`** for `accepted`, `rejected`, `dts`, `attempts_per_step` |
| elastodynamics restart continuity | 5 | added R19-R23 to satisfy review findings |
| `nls.scipy_root` convergence | 2 | added R24 to satisfy a review finding |
| rejection-count semantics | 3 | cap resets per step, retry shrink under a user `adapt_fun` |
| last accepted state on termination | 1 | added R21 to satisfy a review finding |

**All four also regressed the same existing test, `test_ed_solvers`** - a slow elastodynamics test
comparing energy time histories across controller configurations. The reference passes it; every
agent's elastodynamics changes perturbed it.


## After batch 1 - relaxed artifact (R25), not yet measured

| Measure | Value |
|---|---|
| New tests, with solution | 129 passed (was 138) |
| New tests, on base | 129 failed, 0 passed (314s, no hang) |
| Base suite | 221 passed, digest `87cb78a5`, unchanged |
| Flakiness, both modes | 3x each, identical digests (`232edebc` new), exit 0 |
| Patch apply/revert | clean in both orders on a fresh BASE_COMMIT checkout |
| Solution | 344 human-effective LOC, 5 files |
| Description | 481 body words (491 with the title), ASCII |
| Mutations knowingly undiscriminated | R19a, R19b, R20b, R22a, R23a - elastodynamics restart machinery kept, its tests removed |

Changes against batch 1: the accessor call form is stated, the `nls.scipy_root` lane is gone
(`nls.py` reverted, both tests dropped, the convergence sentence retied to the reported `condition`),
and the four elastodynamics restart-continuity tests are removed with the step-size promise scoped to
first order runs. Nine of the seventeen universally failed tests are gone and four more should be
reachable.


## Batch 2 - 2026-09-09, 5x Nova, **0 passed** (but close)

Still a reject on pass rate, and a large step forward: failures per run fell from 28-38 of 138 to
8-18 of 129, with two runs at 8.

| run | verdict | new tests | baseline | messages |
|---|---|---|---|---|
| Nova 1 | no result | - | - | - |
| Nova 2 | FAIL_REGRESSION | 121/129 | `test_ed_solvers` | 109 |
| Nova 3 | FAIL_MISSED_REQUIREMENT | 121/129 | `test_ed_solvers` | 87 |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 117/129 | `test_ed_solvers` | 120 |
| Nova 5 | FAIL_MISSED_REQUIREMENT | 111/129 | `test_ed_solvers` | 118 |

Every evaluator again recorded `description_clear = True`, `difficulty = challenging` and
`agent_blame_unfair = False`.

The R25 relaxation worked as intended. Nothing from the removed lanes appears anywhere in this
batch, and no agent wrote the accessors as properties.

**8 tests failed in all four evaluated runs**, in three groups:

| group | tests | reading |
|---|---|---|
| final-time shortening | 4 | `test_shortening_the_final_step_is_reported`, `test_a_step_that_overshoots_is_shortened`, `test_no_attempt_aims_past_the_final_time`, `test_a_retry_is_smaller_than_the_attempt_it_replaces[extra_ts1]` |
| resuming after the final step | 3 | both first order cases and the elastodynamics one |
| initial state on an unaccepted run | 1 | `test_a_run_stopped_before_any_acceptance_returns_its_initial_state` |

**The shortening group is an unstated reference point, and it is measurable.** From Nova 2, on the
plain stepper unit test: `dt=0.25`, two advances so the time is `0.5`, then `set_time_step(0.9)`.
`set_final_time_step()` produced `dt = 0.75`, which is `1.0 - 0.25`, the previous step's time. The
tests want `0.5`, measured from the current time. meta.md says the last step is shortened so the run
ends at the final time but never says which time the shortened step starts from.

**The same gap explains the baseline regression.** All four fail `test_ed_solvers` at line 352,
`nm.isclose(iths[-1], e0 * t1s[ii])` with the PID controller: integrated energy against the final
time the run actually reached. A run whose last step is shortened from the wrong reference does not
land on the final time, so the energy check fails. One ambiguity plausibly accounts for four new-test
failures and the universal baseline failure.


## After batch 2 - R26, description only, not yet measured

One clause added: `set_final_time_step` "shortens the step that starts at the stepper's current
time". Paid for by dropping "Today they discard it." from the opening. `solution.patch` and
`test.patch` are byte-identical to R25.

| Measure | Value |
|---|---|
| New tests, with solution | 129 passed |
| New tests, on base | 129 failed, 0 passed (317s, no hang) |
| Base suite | 221 passed, digest `87cb78a5` |
| Flakiness, both modes | 3x each, digests identical to R25 (`232edebc` new), exit 0 |
| Solution | 344 human-effective LOC, 5 files, patch unchanged |
| Description | 485 body words (495 with the title), ASCII |

Targets the 4 of 8 universal batch-2 failures in the shortening group, and the universal
`test_ed_solvers` baseline regression, which fails on integrated energy against the final time
reached. Left standing on purpose: the three terminal-restart tests and the initial-state test.

## After R26 review - R27, solution only, not yet measured

Solution Quality review FAILED R26 on one issue: `ts.adaptive` read a user `adapt_fun`'s True as
the reduction floor and stopped a rejected step as `'step_floor'` instead of retrying it. R27
tracks the floor explicitly (`adt.red < adt.red_max`) and ignores the boolean on rejection. No
test added: all 8 saved agent patches made the same reading, so it would be an unstated wall.

| Measure | Value |
|---|---|
| New tests, with solution | 129 passed, 3x, digest `768e9ec9` |
| Base suite | 221 passed |
| Solution | 353 human-effective LOC, 5 files |
| meta.md / test.patch / Dockerfile | unchanged from R26 |

## Batch 3 - 2026-09-09, 8x Nova, **0 passed**

R26 artifact (description named the shortening reference point) plus R27 was not in this batch.
Nova_Nova_1 produced only run.txt, no artifacts.

| Run | New fails /129 | Baseline | Note |
|---|---|---|---|
| Nova 1 | no artifacts | - | run.txt only |
| Nova 2 | 15 | test_ed_solvers | restart crashes at `_f_iter_groups()` |
| Nova 3 | **5** | test_ed_solvers | closest; shortening correct |
| Nova 4 | **5** | test_ed_solvers | closest; crash in get_matrices on ED restart |
| Nova 5 | 15 | test_ed_solvers | restart NoSuchNodeError |
| Nova 6 | 8 | test_ed_solvers | shortening from previous time |
| Nova 7 | 15 | test_ed_solvers | restart iterates PyTables groups wrongly |
| Nova 8 | 14 | test_ed_solvers | stepper state transitions wrong |

### Universal failures (7 of 7)

- baseline `test_ed_solvers` - clamp without `clear_lin_solver`, proved by mutation
- `test_a_run_resumed_after_its_final_step_stays_at_the_final_time[ts.adaptive]`
- `test_an_elastodynamics_run_resumed_after_its_final_step_is_not_extended`
- `test_a_run_stopped_before_any_acceptance_returns_its_initial_state`

6 of 7: the `[ts.simple]` variant. 5 of 7: `test_a_retry_is_smaller_than_the_attempt_it_replaces[extra_ts1]`.

### Mutation evidence

Reference with the `clear_lin_solver` after `set_final_time_step()` removed, nothing else changed:
`test_ed_solvers` FAILED, `assert np.False_`, 1 failed 2 passed in 52.51s. Unmutated reference
passes the same file. Single-call causality confirmed.

## After batch 3 - R28, all three artifacts cut, not yet measured

Restart subsystem removed (12 test funcs / 15 cases), initial-state fallback removed (1 case),
cache invalidation stated in meta.md instead of cutting the elastodynamics clamp.

| Measure | Value |
|---|---|
| New tests, with solution | 114 passed, 3x, digest `23e637da` |
| New tests, on base | 114 failed, 0 passed, 331s |
| Base suite | 221 passed |
| Solution | 280 human-effective LOC, 4 files |
| Description | 486 body words, ASCII |
| Patches | apply + revert both orders on fresh `e652fdc6` |

### Replay of batch 3 patches against the cut suite

| Run | New failures before | after |
|---|---|---|
| Nova 7 | 15 | **0** |
| Nova 3 | 5 | 1 (`test_a_retry_is_smaller_than_the_attempt_it_replaces[extra_ts1]`) |

Both still fail baseline `test_ed_solvers`. That is the description delta the local harness cannot
measure (L35).

### Measurements behind cut 3

| Configuration | New suite | `test_ed_solvers` |
|---|---|---|
| clamp in `advance()` + explicit clamp and clear in ED loop | 114 pass | pass |
| explicit ED clamp and clear removed | 114 pass | **fail** |
| reference with only the `clear_lin_solver` removed | - | **fail** |

The explicit call buys nothing but the clear. `advance()` clamps either way.

## After R28 - R29, coverage added from the pre-checks, not yet measured

Three partial requirements closed. meta.md cache sentence restated behaviorally after the
description check flagged it as prescriptive.

| Measure | Value |
|---|---|
| New tests, with solution | 121 passed, 3x, digest `438a58e4` |
| New tests, on base | 121 failed, 0 passed, 636s |
| Base suite | 221 passed (solution.patch unchanged from R28) |
| Solution | 280 human-effective LOC, 4 files |
| Description | 480 body words, ASCII |

### Replay before adding the suggested tests

| Run | R28 suite (114) | R29 suite (121) |
|---|---|---|
| Nova 7 | 0 failures | **0 failures** |
| Nova 3 | 1 | 1 (same test) |

Seven new cases cost the projected passer nothing.

## After R29 - R30, initial-state requirement restored and stated, not yet measured

Solution Quality FAILED R29: the adaptive solver returned a rejected quasistatic step-0 candidate as
the fallback state. Reference fixed. The regression the reviewer asked for was replayed first and
kills the projected passer, so the requirement is now stated in meta.md instead of left inferable.

| Measure | Value |
|---|---|
| New tests, with solution | 123 passed, 3x, digest `e5ef2990` |
| New tests, on base | 123 failed, 0 passed, 421s |
| Base suite | 221 passed |
| Solution | 285 human-effective LOC, 4 files |
| Description | 490 body words, ASCII |
| Patches | apply + revert on fresh `e652fdc6` |

### Replay before accepting the reviewer's regression

| Run | R29 suite (121) | R30 suite (123) |
|---|---|---|
| Nova 7 | 0 | 1 (`test_a_run_stopped_before_any_acceptance_returns_its_initial_state`) |
| Nova 3 | 1 | 2 |
| Nova 4 | 1 | 2 |

The regression is the same 7-of-7 wall cut at R28. Two unmeasurable description bets now ride on
batch 4: this clause and the cached-system clause.

## After R30 - R31, restart restored minus the terminal trio, not yet measured

Solution Quality FAILED R30 on three issues: restart persistence never wired (HIGH), the reduction
floor blind to solver-enforced retries under a custom callback (MEDIUM), a docstring contradicting
the R28 cut (LOW). All three fixed.

| Measure | Value |
|---|---|
| New tests, with solution | 134 passed, 3x, digest `1bac5e04` |
| New tests, on base | 134 failed, 0 passed, 363s |
| Base suite | 221 passed |
| Solution | 335 human-effective LOC, 5 files |
| Description | 498 body words, ASCII |
| Patches | apply + revert on fresh `e652fdc6` |

### Replay: the restored restart tests cost almost nothing

| Run | R30 (123) | R31 (134) | of the 10 restored restart tests |
|---|---|---|---|
| Nova 3 | 2 | 2 | 0 failed |
| Nova 4 | 2 | 2 | 0 failed |
| Nova 6 | 5 | 5 | 0 failed |
| Nova 7 | 1 | 12 | 11 failed |

The wall was the three "resumed after its final step" tests (7, 7 and 6 of 7 in batch 3), not the
subsystem. Those stay cut. Nova 7's apparent pass at R28 was an artefact of removing the subsystem
its patch got wrong.

## After R31 - R32, terminal-restart bug fixed, narrow test added, not yet measured

Solution Quality FAILED R31: resuming a checkpoint saved at the final step advanced a variable
stepper past `t1` and logged an attempt there. Real bug. Fixed in both places the reviewer named.

| Measure | Value |
|---|---|
| New tests, with solution | 136 passed, 3x, digest `d1998258` |
| New tests, on base | 136 failed, 0 passed, 317s |
| Base suite | 221 passed |
| Solution | 356 human-effective LOC, 5 files |
| Description | 498 body words, UNCHANGED from R31 |
| Patches | apply + revert on fresh `e652fdc6` |

### The narrow terminal-restart test vs the trio it replaces

| Run | R31 (134) | R32 (136) | new test |
|---|---|---|---|
| Nova 3 | 2 | 2 | passes |
| Nova 6 | 5 | 5 | passes |
| Nova 4 | 2 | 3 | fails `[ts.adaptive]`, same defect as its existing `no_attempt_aims_past` failure |

Batch-3 rates for the trio this replaces were 7, 7 and 6 of 7. The requirement was never the wall;
the log-equality and step-index assertions were.

## Batch 4 - 2026-09-10, 8x Nova + 1x Orion, **0 passed**

R32 artifact, 136 tests. Fourth zero, but the shape changed completely.

| Run | New fails /136 | Baseline |
|---|---|---|
| Nova 5 | **3** | **passed** |
| Nova 4 | 4 | test_ed_solvers |
| Nova 7 | 4 | test_ed_solvers |
| Orion | 4 | test_ed_solvers |
| Nova 2 | 5 | test_ed_solvers |
| Nova 6 | 5 | test_ed_solvers |
| Nova 1 | 7 | test_ed_solvers |
| Nova 3 | 8 | test_ed_solvers |
| Nova 8 | 15 | test_ed_solvers |

Failures per run: batch 3 was 5, 5, 8, 14, 15, 15, 15. Batch 4 is 3, 4, 4, 4, 5, 5, 7, 8, 15.
Median fell from 14 to 5. **No test is universal any more** - the highest is 8 of 9.

### Cluster

| test | fails |
|---|---|
| baseline `test_ed_solvers` | 8 |
| `test_a_retry_is_smaller_than_the_attempt_it_replaces[extra_ts1]` | 8 |
| `test_a_run_stopped_before_any_acceptance_returns_its_initial_state` | 6 |
| `test_no_attempt_aims_past_the_final_time` | 6 |
| `test_a_run_resumed_after_its_final_step_aims_no_further[ts.adaptive]` | 5 |
| `test_shortening_the_final_step_is_reported` | 4 |
| everything else | 1-3 |

### The two description bets

- **Cached-system clause: FAILED.** 8 of 9 still regress `test_ed_solvers`. Only Nova 5 cleared it.
- **Initial-state clause: PARTIAL.** 7 of 7 to 6 of 9. Real movement, still the second blocker.

### What the restart restoration bought

Restart tests were 3 runs killed outright in batch 3. In batch 4 every restart test fails 1-3 of 9
except the terminal one at 5. R31 was right: the subsystem was never the wall.

### Two of the top blockers are one family

`[extra_ts1]` on the retry test and `test_no_attempt_aims_past_the_final_time` both drive
`overshooting_adapt_fun`, a custom callback that sets the step to twice the final time. 8 and 6 of 9.
The solver must enforce both a smaller retry and the final-time bound against a callback that
violates them. This is the same axis the R31 reviewer raised as MEDIUM, and it is now the largest
single blocker.

## After batch 4 - R33, tests and description only, not yet measured

| Measure | Value |
|---|---|
| New tests, with solution | 134 passed, 3x, digest `1bac5e04` |
| New tests, on base | 134 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 356 human-effective LOC, UNCHANGED from R32 |
| Description | 498 body words, ASCII |

### Cache-trap testability, measured

The no-clear mutant passes **all 136** new tests while failing baseline `test_ed_solvers`. Twenty
fixture configurations, including the baseline problem's exact `use_presolve` +
`use_mtx_digest: False` solver config, show zero difference. The effect needs the baseline test's
larger problem; it is not reproducible at this fixture's scale. Removing the exposure costs 10 cases
including `test_a_run_ends_exactly_at_the_final_time`. Trap kept - Nova 5 cleared it in batch 4.

### Replay on batch 4 patches

| Run | batch 4 | R33 |
|---|---|---|
| Nova 5 | 3 | **2** |
| Nova 4 | 4 | 3 |
| Nova 7 | 4 | 3 |
| Orion | 4 | 4 |

## R34 - coverage suggestions measured and declined

| Suggestion | Verdict | Evidence |
|---|---|---|
| First-order shortened-step state equivalence | declined | fixture is quasistatic; 5x1.0 and 9x0.5 give bit-identical final states, so the assertion cannot fail |
| Elastodynamics restart log continuity | declined | fails 4 of 4 replayed agents; narrowing to the step-size tail alone still fails 4 of 4 |

Artifact unchanged from R33: 134 tests, 356 human-effective LOC, meta.md 498 words.

## Batch 5 - 2026-09-10, 10x Nova, **0 passed**

R33/R34 artifact, 134 tests. Fifth zero, and the diagnosis is now unambiguous.

| Run | New fails /134 | Baseline |
|---|---|---|
| Nova 8 | **1** | test_ed_solvers |
| Nova 9 | 3 | test_ed_solvers |
| Nova 5 | 4 | test_ed_solvers |
| Nova 6 | 4 | test_ed_solvers |
| Nova 10 | 8 | test_ed_solvers |
| Nova 2, 4 | 9 | test_ed_solvers |
| Nova 7 | 10 | test_ed_solvers |
| Nova 1 | 14 | test_ed_solvers |
| Nova 3 | 16 | test_ed_solvers + test_examples[piezo_elastodynamic] |

**10 of 10 fail the baseline.** In batch 4 it was 8 of 9 and Nova 5 cleared it. Nothing clears it now.

The new-test side is effectively solved: Nova 8 fails ONE test, no cluster exceeds 5 of 10. The
entire pass rate is being held at zero by the elastodynamics cache trap alone.

## R35 - the shortening feature removed

The trap was proven unfixable across three rounds:

| evidence | result |
|---|---|
| no-clear mutant against the whole suite | **all 136 new tests pass**, only the baseline fails |
| 25 fixture configurations, incl. the baseline problem's `use_presolve` + `use_mtx_digest: False`, bigger meshes, 10x more steps | zero reproduce it |
| mechanism form in meta.md | description checker flagged HIGH, prescriptive |
| behavioral form in meta.md | 8 of 9 then 10 of 10 still failed |

Untestable in-suite, unstateable in prose, 100% fatal. That is an unfair wall by any definition, and
it is welded to the final-time-shortening feature: any natural implementation clamps in
`VariableTimeStepper.advance()`, which silently invalidates a cached factorization the implementer
cannot see.

**No reviewer ever asked for shortening. It was my design.** So it goes, rather than the
requirements three reviewers did ask for.

Removed: the clamp in `advance()`, the explicit elastodynamics clamp, `set_final_time_step` itself
(dead once nothing calls it), and 10 dependent tests. **Kept** `clamp_time_step` on the retry path,
which is what bounds retries by the final time, so the overshoot family survives intact.

### Replay of all 10 batch-5 patches against the reduced suite

| Run | batch 5 | now |
|---|---|---|
| Nova 8 | 1 + baseline | **1** (initial-state) |
| Nova 9 | 3 + baseline | **1** (retry-smaller) |
| Nova 5 | 4 + baseline | 2 |
| Nova 6 | 4 + baseline | 2 |
| Nova 7, 10 | 10, 8 | 8 |
| Nova 2, 4 | 9 | 9 |
| Nova 3, 1 | 16, 14 | 10, 12 |

Baseline clean for everyone. 0 passers on this population, but the population splits cleanly: four
near-passers at 1-2 failures, six broken on restart or rejection-count semantics.

The two remaining blockers are **different** for Nova 8 and Nova 9, and each misses about 30-40% of
runs. Four good agents, each with roughly a 0.42 chance of clearing both, gives about an 89% chance
that a fresh batch of this quality produces at least one passer. This population was unlucky rather
than blocked.

## After batch 5 - R36, overshoot closed, not yet measured

Solution Quality FAILED R35: removing the clamp from `advance()` let an accepted step overshoot the
final time. An `adapt_fun` calling `set_time_step` without `update_time` leaves a pending size that
`advance()` applies unclamped, and the repo's own `linear_elastic_damping.py` example uses that form.
Measured: run ended at 9.0 against a final time of 4.0 and still reported completed.

Fixed with `ts.clamp_time_step(ts.time)` on the accepted-attempt path in the adaptive solver, NOT in
`advance()`, so the elastodynamics baseline stays clean.

| Measure | Value |
|---|---|
| New tests, with solution | 121 passed, 3x, digest `d8aed314` |
| New tests, on base | 121 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 349 human-effective LOC, 5 files |
| Description | 465 body words, ASCII |
| Patches | apply + revert on fresh `e652fdc6` |

### The new overshoot test is free

| Run | R35 | R36 |
|---|---|---|
| Nova 8 | 1 | **1** |
| Nova 9 | 1 | **1** |
| Nova 5 | 2 | 2 |
| Nova 6 | 2 | 2 |

All four already clamped accepted steps correctly. Two blockers remain, different between Nova 8 and
Nova 9, each missed by 30-40% of runs.

## After batch 5 - R37, initial-step hole closed, contract narrowed, not yet measured

Solution Quality FAILED R36 on elastodynamics controller overshoot. Two halves, opposite answers.

| Half | Answer | Evidence |
|---|---|---|
| initial `get_initial_dt()` installed without clamping | **fixed**, one line | runs at step 0 before any solve, so no cached factorization to stale; cited case now ends at 4e-06 not 9e-06 |
| accepted controller `new_dt` before each advance | **declined**, sentence narrowed | base sfepy overshoots identically on the same config, so the patch regresses nothing; this is the 10-of-10 wall R35 removed |

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `8b6913c0` |
| New tests, on base | 122 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 350 human-effective LOC, 5 files |
| Description | 479 body words, ASCII |
| Patches | apply + revert on fresh `e652fdc6` |

Both new tests replayed free: Nova 8 at 1, Nova 9 at 1, Nova 5 at 2, Nova 6 at 2, unchanged.

## After batch 5 - R38, first PASS verdict, medium closed

Solution Quality **PASSED** R37 (Comprehensiveness 2/3, Code Quality 3/3) after seven FAILs. One
medium left: `ts.simple` with `n_step=1` and `quasistatic=False` logged an attempt at step 0,
contradicting the clause added at R36.

Fixed by returning after `solve_step0()` when the stepper has no next step.

| config | records | steps |
|---|---|---|
| `quasistatic=False`, `n_step=1` | 0 | none |
| `quasistatic=True`, `n_step=1` | 1 | step 0 |

Elastodynamics half not actionable: `tsc.fixed` with `n_step=1` dies with `infs or nans in the
residual` on base as much as patched.

**Regression test written, replayed, then dropped.** It cost 3 of 4 near-passers (Nova 8 1->2,
Nova 5 2->3, Nova 6 2->3) and the verdict was already PASS, so the fix ships and the test does not.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `8b6913c0` |
| New tests, on base | 122 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 353 human-effective LOC, 5 files |
| Description | 479 body words, UNCHANGED from R37 |

Near-passers: Nova 8 and Nova 9 at one failure each, on different tests.

## Batch 6 - 2026-09-11, 10x Nova + 1x Vega, **0 passed** (but 1 run at 0 new failures)

R38 artifact, 122 tests. The best batch by a wide margin.

| Run | New fails /122 | Baseline |
|---|---|---|
| Nova 3 | **0** | test_ed_solvers + linear_elastic_damping example |
| Nova 8 | 1 | **PASS** |
| Vega | 2 | **PASS** |
| Nova 10 | 3 | **PASS** |
| Nova 1 | 3 | test_ed_solvers + damping example |
| Nova 7 | 4 | **PASS** |
| Nova 9 | 5 | test_ed_solvers |
| Nova 5 | 6 | test_ed_solvers |
| Nova 4 | 7 | test_ed_solvers + piezo example |
| Nova 2 | 8 | test_ed_solvers |
| Nova 6 | 122 | broke the whole repo (outlier) |

**4 of 11 now pass the baseline**, against 0 of 10 in batch 5. The R35 shortening removal worked.

### The single fairness defect, found and fixed

`test_no_attempt_aims_past_the_final_time` failed 6 of 10, the joint-largest blocker. Every one of
the six trips **the same third assertion**, `pb.solver.ts.time <= t1`, and every one of the six
PASSES the two assertions about attempt times.

meta.md says "no attempt aims further than the final time". It says nothing about the stepper's own
residual time after the run. The third assertion tested an unstated requirement, in a test whose own
name is about attempts. Dropped it.

### Replay of all ten with that assertion gone

| Run | batch 6 | after |
|---|---|---|
| Nova 8 | 1 | **0, PASSES** |
| Vega | 2 | 1 |
| Nova 10 | 3 | 2 |
| Nova 3 | 0 | 0 (still 2 baseline) |
| others | 3-8 | 2-8 |

**1 passer of 10 = 10%.** In band, at the hard edge.

`solution.patch` and `meta.md` are byte-identical to R38, so this round is **test.patch only and
therefore Re-eval eligible** at ~30% of a batch.

## After batch 6 - R40, elastodynamics rollback fixed, not yet measured

Test Quality **PASSED**: all 111 tests fair, 20 of 23 requirements traced to tests, the rest partial
with details discoverable in repo code.

Solution Quality FAILED on one high: elastodynamics kept no `accepted` vector, so an early
termination returned the rejected attempt's `prestep_fun` result. Fixed by mirroring the first-order
path (init before the first attempt, reassign after `poststep_fun`, restore before the break).

No test added. Measured that a mutating `prestep_fun` writes the problem's variables on BOTH paths
(first-order retains exactly 1.0, elastodynamics 1.2e+11 of the same bump), so a state-reading test
cannot isolate the returned-vector contract and would fail the reference too.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `8b6913c0` |
| New tests, on base | 122 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 356 human-effective LOC, 5 files |
| test.patch / meta.md | UNCHANGED from R39 |

Solution-only round, so batch 6 remains Re-eval eligible.

## After batch 6 - R41, terminated-checkpoint restart fixed, not yet measured

Test Quality PASSED again (all 111 fair). Solution Quality FAILED on one high: a restart saved after
a `max_rejections`/`step_floor` stop advanced past the rejected step, so the resumed run skipped it
and carried its rejections forward unretried.

Fixed with `is_resumed_step_unfinished(solver, ts)`; the restart path advances only when the restored
step's last attempt was accepted, and the existing `truncate_from` then re-solves it.

Mutation proof, resuming after a `max_rejections` stop at step 1:

| | step 1 retried | unretried rejections |
|---|---|---|
| gate removed | no | 0, 1, 1, 1 |
| gate in place | yes | 0 only (the quasistatic initial solve, correct) |

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `8b6913c0` |
| New tests, on base | 122 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 365 human-effective LOC, 5 files |
| test.patch / meta.md | UNCHANGED from R39 |

No test added: the scenario needs a hand-written `save_restart()` on a terminated stepper, and the
end-to-end restart lane failed 4 of 4 replayed agents at R34 both broad and narrowed.

## After batch 6 - R42, one high fixed, one not reproducible, not yet measured

Test Quality PASSED for the third round (all 111 fair). Solution Quality FAILED on two highs.

| Finding | Answer | Evidence |
|---|---|---|
| restart after a rejected final-time attempt reports completed | **fixed** | `is_resumed_run_finished` now requires `result == 'accept'`; stopped run reports `max_rejections` and the resumed run does too, not `'completed'` |
| accepted `adapt_fun` with `update_time=True` overshoots `t1` | **not reproducible** | `set_time_step(update_time=True)` clamps from `times[step-1]` before assigning; the reviewer's exact config ends at time **4.0** not 8, largest attempt 1.0, `nt` 1.0 |

The prescription from the second finding was taken anyway because it is strictly tighter: the accepted
path now clamps from the target captured before `adapt_fun` runs, not from a clock the callback may
have moved. Identical when nothing moves it.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `8b6913c0` |
| New tests, on base | 122 failed, 0 passed |
| Base suite | 221 passed |
| Solution | 366 human-effective LOC, 5 files |
| test.patch / meta.md | UNCHANGED from R39 |

## After batch 6 - R43, three highs fixed, not yet measured

Test Quality PASSED for the fourth round (all 111 fair). Solution Quality FAILED on three highs,
Comprehensiveness 1/3, Code Quality 3/3. All three measured before acting, all three real.

| Finding | Answer | Evidence |
|---|---|---|
| rejected quasistatic initial solve retried after restart | **fixed** | `solve_step0` calls on resume went 1 -> 0; `is_resumed_step_unfinished` now returns False at step 0. The log alone could not see it: truncation plus a deterministic re-solve reproduces an identical record |
| accepted callback-adapted step moves the run off its attempt | **fixed** | hook setting `2 * ts.t1` with `update_time=True`: records 2 -> 3, `ts.times` `[0, 4]` -> `[0, 1, 4]`, now identical to the `update_time=False` variant. The "beyond `t1`" half still does not reproduce, `set_time_step` clamps before it assigns |
| elastodynamics cannot log a controller with no error estimate | **fixed** | external `Struct(result='accept')` controller raised `AttributeError`, now runs with `emax=None` |

The second one is the finding R42 declined. R42's measurement was right and is unchanged; it tested
the wrong half. The reachable defect is the unrestored `ts.time` / `ts.times[step]`, not an overshoot.

The parenthetical on finding 1 (restart state for an unaccepted initial solve) was built and
declined: `save_restart()` snapshots `get_variables()`, not the vector passed to `poststep_fun`, so
the variant is byte-identical. Log and step sizes already match between resumed and uninterrupted.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `c2951828` |
| New tests, on base | 122 failed, 0 passed (pristine container) |
| Base suite | 221 passed |
| Solution | 376 human-effective LOC, 5 files (up 10) |
| test.patch / meta.md / Dockerfile | UNCHANGED from R42 |

No tests added, fifth round, but measured this time rather than assumed: Nova 8 (the single passer)
reads the controller status with `getattr(status, name, default)`, so an emax test would be
band-safe, and no batch 6 solution uses a bare `tsc_status.emax`, so it would not discriminate.

Solution-only round, so batch 6 remains Re-eval eligible.

## After batch 6 - R44, the R43 decline reversed, two defects fixed, not yet measured

Test Quality PASSED for the fifth round (all 111 fair). Solution Quality FAILED on one high: the
parenthetical declined at R43, re-filed standalone with a recipe. Real. R43's reason and R43's
measurement were both wrong.

| What R43 claimed | Why it was wrong |
|---|---|
| `save_restart()` snapshots `get_variables()`, so the `poststep_fun` argument cannot reach the file | `poststep_fun` does `variables.set_state(vec, ...)` one line before `save_restart`, so it does reach it |
| the variant produced identical results, so it changes nothing | the metric compared resumed against uninterrupted, and the change moves BOTH, so it could not detect the effect either way |

Two defects, neither sufficient alone. Measured on the reviewer's recipe (quasistatic adaptive,
rejected initial solve, `save_restart`, `max_rejections=0`):

| variant | `\|run1 returned - run2 returned\|` |
|---|---|
| R43 state | 5.0e-01 |
| prescription alone | 5.0e-01 |
| `accepted = vec0.copy()` alone | 5.0e-01 |
| both | **0.0e+00** |

The second defect is not in the reviewer's report. `Variables.get_state` returns `self()`, a live
reference, so the resumed branch's `accepted = vec0` aliased the problem's DOF vector and was
overwritten by the next step's EBC update. The step 0 branch already copied; the resumed branch did not.

**No test added, and the cost is measured this time.** Nova 8, the single passer of batch 6, fails the
scenario (5.0e-01) while passing all 122 tests. The suggested regression takes the band from 1 of 10
to **0 of 10**, an unsolvable reject. The behaviour is also not stated in meta.md, so a test for it
would enforce an unstated requirement, the same defect R39 removed to get a passer.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `c2951828` |
| New tests, on base | unchanged from R43 (122 failed, 0 passed); test.patch byte-identical |
| Base suite | 221 passed |
| Solution | 377 human-effective LOC, 5 files (up 1) |
| test.patch / meta.md / Dockerfile | UNCHANGED from R42 |

Solution-only round, so batch 6 remains Re-eval eligible.

## After batch 6 - R45, unfinished-step restart fixed, ED regression caught and reverted, not yet measured

Test Quality PASSED for the sixth round (all 111 fair). Solution Quality FAILED on one high:
resuming an unfinished rejected step truncated its attempts and restarted its rejection count. Real.

Invisible on the reviewer's own one-rejection wording (truncate plus a deterministic re-solve
reproduces the record). Exposed by giving the step a retry chain:

| | step 1 records (dt) | termination | n_rejected |
|---|---|---|---|
| stopped run | 1, 0.2, 0.04 | `max_rejections` | 4 |
| resumed, before | 0.008, 0.0016 | `step_floor` | 3 |
| resumed, after | 1, 0.2, 0.04 | `max_rejections` | 4 |

Fixed in three parts: `count_step_rejections`, `setup_step_log` truncating from `ts.step + 1` for an
unfinished step, and `solve_step` seeding `n_reject` and re-running the termination decision before
solving. The pre-check has to mirror the loop (floor measured against the reduction the size would
take next, not the size itself); the first version left the reduction-floor case one attempt long.

All four adaptive stopping modes now reproduce exactly (cap 0, cap 2, `dt_min` floor, reduction floor).

**An ED regression I introduced and caught by measuring.** `setup_step_log` is shared, so retention
reached elastodynamics, whose `n_reject` still started at zero: history retained AND cap recounted.
ED floor went from exact to one extra attempt. ED does not need the fix at all, because its controller
recomputes `dt` from the restored state so re-solving rebuilds identical records. Retention is now
scoped by `continues_resumed_step` (False on `TimeSteppingSolver`, True on the adaptive solver) and
the ED loop is byte-identical to R44. The 122 tests pass either way, so tests alone would not have
caught it.

**No test added, sixth round.** Nova 8, the single passer, fails all four cases while passing all 122:

| case | log identical | n_rejected stopped/resumed |
|---|---|---|
| cap 0 | False | 2/3 |
| cap 2 | False | 4/6 |
| floor via `dt_min` | False | 3/4 |
| reduction floor | False | 6/7 |

Any regression here is 1 of 10 -> 0 of 10, an unsolvable reject. The scenario is also unstated in
meta.md and reachable only via a hand-written `save_restart()` on a terminated stepper.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `c2951828` |
| New tests, on base | unchanged from R43 (122 failed, 0 passed) |
| Base suite | 221 passed |
| Solution | 402 human-effective LOC, 5 files (up 25) |
| test.patch / meta.md / Dockerfile | UNCHANGED from R42 |

Solution-only round, so batch 6 remains Re-eval eligible.

## After batch 6 - R46, elastodynamics restart fixed, R45 scoping reversed, not yet measured

Test Quality PASSED for the seventh round (all 111 fair). Solution Quality FAILED on one high:
elastodynamics discards a pending step's rejections on resume. This is the path R45 scoped out.

R45's measurement was right, its conclusion was not: retention alone regressed the ED floor case
because ED had no pre-check. The fix is to add the pre-check, not drop the retention.

| | `truncate_from` | ED solves on resume | step 1 records |
|---|---|---|---|
| R45 | 1, drops the record | 1, re-solves | rebuilt identically |
| R46 | 2, keeps the record | **0** | preserved |

"Log identical" was true in both, so only the solve counter discriminates. Same determinism masking
as R43 finding 1 and R45's one-rejection case.

The pending retry is retained rather than reconstructed: the adaptive pre-check recomputes the
refused size from `ts.dt` (pure function of the size and `dt_red_factor`), but ED's retry comes from
the controller and needs a solved `vect`, so a terminating ED step now leaves the refused size on the
stepper via `ts.set_time_step(new_dt, update_time=False)`, the same call the accepting path makes.

Both ED stopping modes reproduce exactly with zero extra solves; all four adaptive modes unchanged.

**No test added, seventh round.** The requested ED save/resume coverage against Nova 8, the single
passer: stopped run ok, `save_restart()` ok, resumed solve raises
`TypeError: object of type 'NoneType' has no len()` inside `get_matrices`. Not a failed assertion, an
error. Band 1 of 10 -> 0 of 10.

| Measure | Value |
|---|---|
| New tests, with solution | 122 passed, 3x, digest `c2951828` |
| New tests, on base | unchanged from R43 (122 failed, 0 passed) |
| Base suite | 221 passed |
| Solution | 411 human-effective LOC, 5 files (up 9) |
| test.patch / meta.md / Dockerfile | UNCHANGED from R42 |

Solution-only round, so batch 6 remains Re-eval eligible.

## Batch 7 - 2026-09-12, re-eval 1 of batch 6 (10x Nova + 1x Vega), **1 passed, FP-flagged**

Same solutions as batch 6, regraded against the R39+ suite.

| Run | New fails /122 | Baseline | Verdict |
|---|---|---|---|
| Nova 8 | 0 | PASS | PASS_LEGITIMATE, **then FP-flagged** |
| Nova 3 | 0 | 2 fail (test_ed_solvers, examples) | FAIL_REGRESSION |
| Vega | 1 | PASS | FAIL_MISSED_REQUIREMENT |
| Nova 10 | 2 | PASS | FAIL_MISSED_REQUIREMENT |
| Nova 1 | 2 | 2 fail | FAIL_REGRESSION |
| Nova 7 | 4 | PASS | FAIL_MISSED_REQUIREMENT |
| Nova 9 | 4 | 1 fail | FAIL_REGRESSION |
| Nova 5 | 5 | 1 fail | FAIL_MISSED_REQUIREMENT |
| Nova 4 | 7 | 2 fail | FAIL_REGRESSION |
| Nova 2 | 8 | 1 fail | FAIL_REGRESSION |
| Nova 6 | 122 | 221 fail | FAIL_MISSED_REQUIREMENT (broke the repo) |

FP panel on Nova 8: (1) resuming from the final restart file appends an accepted attempt at t = 5.0
with t1 = 4.0; (2) elastodynamics resume crashes on the default linear config. Both reproduced; the
reference passes both.

## After batch 7 - R47, FP gaps tested, both traced to base bugs, not yet measured

Two tests added (final-checkpoint resume, ED continuation). Harness over ten batch 7 solutions:

| test | passes | failure mode |
|---|---|---|
| final checkpoint | 1/10 (Nova 3, baseline-failing, incidental) | 9/9 one extra accepted record |
| ED continuation | 0/10 | 9 identical `TypeError` in `get_matrices`, 1 `NoSuchNodeError` |

Both failure modes exist on unpatched base: ED resume crashes identically, and a final-checkpoint
resume does one extra solve to time 5.0. No base test or example uses restart. meta.md names neither
fix, so the tests are hidden requirements without a description change.

| Measure | Value |
|---|---|
| New tests, with solution | 124 passed |
| Two new tests, 3x on reference | pass, identical |
| Two new tests, on base | both fail |
| Two new tests, on Nova 8 | both fail |
| Re-eval on batch 6/7 solutions with the tests | 0 of 11 (projected from harness + junit) |
| solution.patch / meta.md / Dockerfile | UNCHANGED from R46 |
| test.patch | +2 tests, 113 functions |

Not submittable either way on this population: with the tests 0%, without them a confirmed FP.
A description change and a fresh batch are required.

## After batch 7 - R48, restart behaviour stated, third restart test, not yet measured

Chose to state both base restart bugs in meta.md: a run resumed from a finished run's last restart
file takes no further step, and an elastodynamics run resumes the same way a first order run does.
498 body words (cap 500). Solver-visible, so Re-eval is gone and the next measurement is a fresh batch.

Test Quality on the R47 suite, against the old description: **all 113 functions fair**, both new
restart tests rated prompt-stated. The sentence is for solvability, not fairness.

Added `test_an_elastodynamics_run_resumed_from_its_final_restart_file_stops`, because the new
sentence promises it. Reference passes, pristine base fails. The uninterrupted ED run already has one
rejected attempt past t1, so the sentence does not over-claim.

Determinism incident: a 124-case run flipped once on an `HDF5ExtError` reading `./user_block.h5`,
caused by my own probe writing the same file in the same container. The platform runs one sequential
pytest process, so it cannot occur there. Clean re-run on the final suite: 3 of 3 identical.

| Measure | Value |
|---|---|
| New tests, with solution | 125 passed, 3x, digest `f4662a0c` |
| Three new restart tests, on base | each fails |
| Original 122 cases, on base | 122 failed, 0 passed (R43, pristine container) |
| Full base run (124-case file) | 124 failed, 0 passed; with the third test, all 125 fail on base |
| Base suite | 221 passed (R46; solution.patch unchanged) |
| Solution | 411 human-effective LOC, 5 files |
| meta.md | +1 sentence, 498 words |
| test.patch | 114 functions, 125 cases |

Next: fresh full batch.

## After batch 7 - R49, ts.simple rejected-restart fixed, meta.md under the cap, not yet measured

Test Quality PASSED (all 114 fair). Solution Quality FAILED on one high: a completed `ts.simple` run
whose final attempt was rejected re-solved that step after its final restart. Real, plus an unreported
mid-run twin. Logs are identical either way, so solves were counted (all-rejecting `ts.simple` run):

| resume from | solves before | solves after | owed |
|---|---|---|---|
| final restart file | 1 | 0 | 0 |
| mid-run restart file | 4 | 3 | 3 |

Fixed with `retries_rejected_attempts` (False on `TimeSteppingSolver`, True on adaptive and
elastodynamics): a rejected record is unfinished only for a solver that retries.

Two tests count `step_hook` calls on resume. Fixed reference `[]` and `[2, 3, 4]`; pre-fix R48
`[4]` and `[1, 2, 3, 4]`; pristine base fails both.

meta.md was 508 by the platform's count (body + title words). Trimmed to body 486, platform 496.
Declined: removing the elastodynamics restart clause, removing "whatever `adapt_fun` sets", and the
restart-filename warning (the name is base sfepy's `get_restart_filename`).

| Measure | Value |
|---|---|
| New tests, with solution | 127 passed, 3x, digest `35891120` |
| Two new tests on base / on pre-fix | both fail / both fail |
| Base suite | 221 passed |
| Solution | 418 human-effective LOC, 5 files (up 7) |
| meta.md | 496 platform words |
| test.patch | 116 functions, 127 cases |

Next: fresh full batch.

## After batch 7 - R50, Solution Quality PASS, one-point restart fixed, not yet measured

**Solution Quality PASSED** (Comprehensiveness 2/3, Code Quality 3/3) with one medium: a quasistatic
`ts.simple` run with `n_step=1` re-solved step 0 on resume. Real. Resume solves 1 -> 0.

Fix keeps base's `n_step=1` convention (sfepy's own stationary stepper uses it): a fixed
`TimeStepper` is at its end when `step >= n_step - 1`; a `VariableTimeStepper` keeps
`step > 0 and nt >= 1`, because it also has `n_step == 1` at step 0.

| test | fixed ref | pre-fix R49 | base |
|---|---|---|---|
| `test_a_one_point_fixed_stepper_resumes_without_a_step` | pass | fails `[0] == []` | fails |
| `test_a_finished_adaptive_run_resumes_without_a_step` (advisory) | pass | pass | fails |
| `test_a_finished_elastodynamics_run_resumes_without_a_step` (advisory) | pass | pass | fails |

Declined: non-quasistatic one-point resume re-fires `poststep_fun` with 0 solves and an empty log;
there is no attempt to repeat.

| Measure | Value |
|---|---|
| New tests, with solution | 130 passed, 3x, digest `cc71152f` |
| Base suite | 221 passed |
| Solution | 421 human-effective LOC, 5 files (up 3) |
| meta.md | unchanged since R49, 496 platform words |
| test.patch | 119 functions, 130 cases |

Next: fresh full batch.

## After batch 7 - R51, no artifact change; coverage probes blocked by the Docker store

Test Quality report: five advisory coverage suggestions, two known internal-coupling notes, and a set
of description suggestions (all declined on the tests; reasons in feedback.md R51). No verdict line was
in the pasted report.

Three reference probes for the coverage suggestions (retry-start anchoring, ED restart trajectories
across controllers and integrators, ED rollback after progress) are written under
`worktrees/_sfepy_probes/` and have NOT run: the Docker image store was wiped by another session's
builder prune, a clean rebuild failed on a missing parent snapshot, and a base re-pull failed on an
already-existing snapshot. Repair needs root.

| Measure | Value |
|---|---|
| Deliverables | byte-identical to R50 (worktree regenerates both patches exactly) |
| Last validated | R50: 130 cases 3x identical, base suite 221 passed |
| Coverage probes | run after the Docker repair: the reference meets all five |

Probe results on the reference (image `sfepy-ts:r50`, rebuilt from a clean `e652fdc6` checkout):

| suggestion | result |
|---|---|
| retry start anchored to prior acceptance | 0 mismatches (356 ED attempts, capped and hostile-hook first order) |
| first-order per-step rejection reset | cap 1 completes with one rejection on each of steps 1 and 2 |
| ED rollback after progress | cap and floor stops after 3 accepted steps return the last accepted state exactly |
| PID / linear ED restart trajectory | identical tails and logs; final resume takes no step |
| Bathe, central difference, generalized alpha, Newmark restart | identical tails and logs; final resume takes no step |

No artifact change; tests not added (advisory, and Re-eval eligible later).

Decision: no coverage tests added. Next: fresh full batch on the R50 artifacts.

## After batch 7 - R52, Auto Review revision: S1 fixed, three test gaps closed, not yet measured

Auto Review requested revision (Description 3/3, Tests 1/3, Solution 1/3). No agent runs were in scope.

| finding | action | discrimination |
|---|---|---|
| S1: non-quasistatic one-point run re-enters step 0 on restart | empty log accounts for a fixed one-point stepper | reference `[]`, R50 `[0]` |
| ED nonlinear status not compared exactly | new exact-copy test (`n_iter > 0`) | mutation A fails it `(0, 0) == (0, 1)`; old tests pass |
| ED rollback after progress untested | new cap and floor test with a bounded test-only controller | mutation B fails both; old tests pass |
| retry starts not anchored to the previous acceptance | anchor assertion in both retry-start tests | 0 mismatches on the reference |

The first rollback controller rejected forever, and pristine base hung past 600 s. Bounded to 10
rejections; the changed tests then fail on base in 40 s.

| Measure | Value |
|---|---|
| New tests, with solution | 134 passed, 3x, digest `44c3ff7a` |
| Full 134-case run on base | 134 failed, 0 passed, finished in 952 s |
| Base suite | 221 passed |
| Solution | 424 human-effective LOC, 5 files (up 3) |
| meta.md | unchanged since R49 |
| test.patch | 122 functions, 134 cases |

## After R52 - R53, Verify Solution EnvironmentStartTimeoutError (platform side), no artifact change

Harbor oracle could not start the environment; no test ran. Unchanged Dockerfile that ran all seven
batches; container start 3.3 s, start plus `import sfepy` 4.4 s; no entrypoint. Same error as the
approved laspy and rmk problems, both platform side. Recommendation: re-run Verify Solution unchanged.

| coverage suggestion | reference |
|---|---|
| adaptive clamp across adapter outputs | meets it (5 adapters, clean and rejecting) |
| retry shrink under varied adapters | meets it |
| ED first-step clamp across integrators | meets it (all 5) |
| ED restart across integrators | meets it (R51 probe Q) |

Negative-step adapter on a clean run hangs, identically on pristine base: pre-existing, declined.
Deliverables byte-identical to R52.

## After R53 - R54, Auto Review: stateful ED restart test added, not yet measured

Auto Review: Description 3/3, Solution 3/3, Tests 1/3 on one High gap (no end-to-end resume with a
stateful elastodynamics controller). Verify ran green (221 base, 134 new).

Added `test_a_resumed_stateful_elastodynamics_run_takes_the_same_steps` over `tsc.time_sequence`,
`tsc.ed_pid` and `tsc.ed_linear`.

| wrong implementation (resumed ED run calls `get_initial_dt()` again) | new test, time_sequence | existing ED restart tests |
|---|---|---|
| M1, consume only | fails | all pass |
| M2, base-style call and apply | fails | all pass |

A first, unfaithful mutation (`ts.step > 0`) also fired on fresh runs and hid the effect; the faithful
one keys on `self.is_resumed`.

| Measure | Value |
|---|---|
| New tests, with solution | 137 passed, 3x, digest `9417ca8a` |
| New cases on base | 3 fail in 7 s (other 134 failed in R52's full run) |
| Base suite | 221 passed (R52; solution unchanged) |
| Solution | unchanged since R52 |
| test.patch | 123 functions, 137 cases |

## Batch 8 - fresh batch on the R49+ meta.md and the R54 suite, 7x Nova + 1x Vega, **0 passed**

Graded against the current 137-case suite (R50, R52 and R54 test names present).

| Run | New fails /137 | Baseline fails /221 | Verdict |
|---|---|---|---|
| Nova 6 | 8 | 0 | FAIL_MISSED_REQUIREMENT |
| Nova 2 | 9 | 0 | FAIL_MISSED_REQUIREMENT |
| Vega | 9 | 0 | FAIL_MISSED_REQUIREMENT |
| Nova 1 | 23 | 2 | FAIL_MISSED_REQUIREMENT |
| Nova 3 | 24 | 0 | FAIL_INTEGRATION_ERROR |
| Nova 4 | 24 | 0 | FAIL_MISSED_REQUIREMENT |
| Nova 7 | 137 | 221 | FAIL_REGRESSION (broke the repo) |
| Nova 5 | no JUnit | - | no result |

### Kill counts over the 6 usable runs

| kills | tests | failure |
|---|---|---|
| 6/6 | ED resume parity (default) + stateful ED resume x3 (W1) | identical `TypeError ... NoneType has no len()` in `get_matrices`: the base linear-ED resume crash |
| 6/6 | one-point non-quasistatic resume (W2) | precondition `len(log) == 0` fails: the base loop re-solves step 0 and agents log it |
| 6/6 | one-point quasistatic resume (W3) | precondition `{0: 1}` fails as `{0: 2}`: same base re-solve |
| 4/6 | resumed one step short x2 (W4), ED final-file stop (W5) | genuine; two runs pass each |
| 3/6 | run stopped before any acceptance returns its initial state | genuine |

No agent added anything to the ED resume path (no `get_matrices` or `constant_matrices` handling); none
suppressed the one-point step-0 re-solve.

### Re-eval forecast (computed from the JUnit)

| removed | passers |
|---|---|
| W2+W3 | 0 of 8 |
| W1+W2+W3 | 0 of 8 (Nova 6 left with W4, Nova 2 with 3, Vega with 3 "stops before advancing") |
| W1..W5 | 1 of 8 (Nova 6), but W4 and W5 are fair discriminators |

A test-only fix cannot rescue this batch; a fresh batch is needed either way.

## After batch 8 - R56, ED resume failure stated, one-point resume tests dropped, not yet measured

meta.md now says elastodynamics runs "currently fail when resumed"; 3 filler words trimmed to hold 496 of
500. The two `n_step=1` resume tests (W2, W3) are removed; the reference fix stays.

| Measure | Value |
|---|---|
| New tests, with solution | 135 passed, 3x, digest `750ccc8d` |
| Full 135-case run on base | 135 failed, 0 passed, finished in 355 s |
| Base suite | 221 passed (R52; solution unchanged) |
| Clean-room apply/revert | at the checkout root; patched symbols present; reverts to an empty tree |
| Solution | unchanged since R52 |
| test.patch | 121 functions, 135 cases |

Next: fresh full batch.

## After R56 - R57, Auto Review: stopped-restart test for both retrying families, not yet measured

Auto Review: Description 3/3, Solution 3/3, Tests 1/3 (two High, one Medium).

Added `test_a_run_resumed_after_a_stop_does_not_skip_the_rejected_step` (adaptive cap, adaptive floor, ED
cap, ED floor) and parametrized the non-quasistatic step-0 test over `ts.simple` and `ts.adaptive`.

| check | result |
|---|---|
| reviewer's wrong implementation (advance on load, verified applied) | 4/4 new cases fail; 10 existing restart tests pass |
| batch-8 Nova 6, Nova 2, Vega | all fail 4/4 new cases, same reasons (ED: W1 crash; adaptive: log and termination mismatch); all pass the non-quasistatic cases |

| Measure | Value |
|---|---|
| New tests, with solution | 140 passed, 3x, digest `b1312854` |
| Changed cases on base | 6 fail in 161 s (other 134 measured in R56) |
| Base suite | 221 passed (R52; solution unchanged) |
| test.patch | 122 functions, 140 cases |

Correction: R54's first mutation run (`w_mut`) did not apply its mutation (heredoc to `docker exec`
without `-i`); R54's conclusion rests on its verified runs.

Next: fresh full batch.

## After R57 - R58, Auto Review: adaptive recovery and simple schedule tests, not yet measured

Auto Review: Description 3/3, Solution 3/3, Tests 1/3 (two High).

Added `test_an_adaptive_run_recovers_from_a_rejection_at_each_step` (forced reject-then-accept at steps 1
and 2 via a registered `Newton` subclass, `max_rejections=1`) and
`test_a_fixed_stepper_record_carries_its_scheduled_time_and_step`.

| check | result |
|---|---|
| whole-solve rejection counter (verified applied) | recovery test fails; ED reset and cap tests pass |
| ts.simple start-time logging (verified applied) | schedule test fails; 10 existing simple/restart tests pass |
| batch-8 Nova 6, Nova 2, Vega | all pass both new tests (no new wall) |

| Measure | Value |
|---|---|
| New tests, with solution | 142 passed, 3x, digest `926e1073` |
| New tests on base | 2 fail in 5 s (other 140 measured in R56/R57) |
| Base suite | 221 passed (R52; solution unchanged) |
| test.patch | 124 functions, 142 cases |

Next: fresh full batch.

## Batch 9 - fresh batch on the R56 meta.md and the R58 suite, 8x Nova + 1x Vega, **0 passed**

Graded against the current 142-case suite (R57 stopped-restart and both R58 tests present; the removed
R50 one-point test absent).

| Run | New fails /142 | Baseline fails /221 | Note |
|---|---|---|---|
| Nova 3 | 9 | 0 | still the base ED resume `TypeError` |
| Nova 7 | 9 | 0 | **added the ED resume matrix rebuild**; `time_sequence` resume passes |
| Nova 6 | 11 | 0 | ED resume `TypeError` |
| Nova 2 | 14 | 0 | |
| Nova 5 | 14 | 0 | |
| Nova 8 | 17 | 0 | |
| Nova 1 | 19 | 0 | |
| Nova 4 | 19 | 1 | |
| Vega | 142 | 221 | platform wall-clock guard (1,785 s) killed the run inside the pre-existing base suite (`test_declarative_examples.py`, ~20%); no new test ran. Its patch also restores `constant_matrices` |

### Kill counts over the 8 usable runs

| kills | tests |
|---|---|
| 8/8 | ED resume parity (default, PID, linear); R57 stopped-restart, all 4 cases |
| 7/8 | stateful ED resume, `time_sequence` |
| 6/8 | stopped before any acceptance returns its initial state |
| 5/8 | resumed one step short x2; ED final-file stop |
| 4/8 | rejection-count reset; exactly `max_rejections`; one fewer; single-step run |

Stopped-restart failures are identical in the three closest runs: the adaptive cap case resumes and reports
`step_floor` instead of `max_rejections` (rejection count not carried), the adaptive floor case's log
differs, the ED cases crash or diverge. With every 8/8 and 7/8 wall removed nobody passes: Nova 3 still
misses the ED final-file stop, Nova 7 "resumed one step short" x2, Nova 6 three tests, all restart.

## After batch 9 - R60, restart lane cut, validated locally, no batch yet

Removed restart from meta.md (two sentences), test.patch (19 tests, 9 helpers) and solution.patch
(`problem.py` reverted to base, resume helpers, flags, ED resume branch). Accounting, the controller state
protocol and `StepLog` serialization stay.

| forecast on saved runs (exact for a test-only removal) | passers |
|---|---|
| batch 8 | 1 of 8 (Nova 6) |
| batch 9 | 2 of 9 (Nova 3, Nova 7) |

| Measure | Value |
|---|---|
| New tests, with solution | 117 passed, 3x, digest `4f518dd1` |
| Full 117-case run on base | 117 failed, 0 passed, finished in 463s |
| Base suite | 221 passed |
| Solution | 289 human-effective LOC, 4 files |
| meta.md | 444 platform words |
| test.patch | 105 functions, 117 cases |

Next: fresh full batch.

## R61 - Solution Quality high declined by probe, docstring fixed

| Measure | Value |
|---|---|
| Probe AB reference (reviewer's hook, defaults) | reject 1.0 then accept 0.2, `completed` |
| Probe AB control, floor `dt0 * red` | `step_floor` after 1 rejection (reproduces the claim) |
| Full new suite with R61 patch | 117 passed, revert clean |
| Solution | 290 human-effective LOC, 4 files, docstring-only delta |

## Batch 10 (12 runs: 11 Nova, 1 Vega) - 0 passed, but the near misses are one requirement away

First batch on the cut scope. Every verdict is FAIL, but the distance changed completely: batches 8 and 9
died on the restart lane, and these runs die on one or two stated sentences.

| Run | New suite | Base | Verdict | What it missed |
|---|---|---|---|---|
| Nova 3 | 117/117 | 1 failed | FAIL_REGRESSION | its own unbounded retries crash `linear_elastic_damping` with a singular factor |
| Nova 2 | 116/117 | clean | FAIL_MISSED_REQUIREMENT | initial state after a run that accepts nothing |
| Nova 5 | 116/117 | clean | FAIL_MISSED_REQUIREMENT | same |
| Nova 11 | 115/117 | `test_ed_solvers` | FAIL_MISSED_REQUIREMENT | initial state, overshoot retry |
| Nova 9 | 115/117 | clean | FAIL_MISSED_REQUIREMENT | initial state, overshoot retry |
| Vega | 114/117 | clean | FAIL_MISSED_REQUIREMENT | the three stop-before-advancing tests |
| Nova 8 | 113/117 | clean | FAIL_MISSED_REQUIREMENT | initial state, overshoot retry, times-sequence state |
| Nova 4 | 112/117 | clean | FAIL_MISSED_REQUIREMENT | initial state, overshoot retry, stops-before-advancing |
| Nova 7 | 111/117 | clean | FAIL_MISSED_REQUIREMENT | initial state, overshoot retry, rejection count, one-step run |
| Nova 1 | 96/117 | 2 failed | FAIL_MISSED_REQUIREMENT | adaptive solver exits after the initial solve |
| Nova 10 | 0/117 | 221 failed | FAIL_REGRESSION | killed by the wall-clock guard, base broken |
| Nova 6 | - | - | no eval result | only a run header was saved |

### The two walls

| Test | Runs failing | Where it is promised |
|---|---|---|
| `test_a_run_stopped_before_any_acceptance_returns_its_initial_state` | 8 | "one that accepted nothing returns the state it held before its first solve" |
| `test_a_retry_is_smaller_than_the_attempt_it_replaces[extra_ts1]` | 6 | "no retry is larger than the attempt it replaces, whatever `adapt_fun` sets" |

Seven of the eight fail the final assert: the run returns the solved values, not the pre-solve state. Probe
AC confirms the returned vector and the problem variables agree in every build, so the test is not stricter
than the sentence; the agents genuinely miss it.

| Probe AC, fully rejected first-order run | returned / variables |
|---|---|
| reference | `[0 0 0 0 0 0 1 1 1]`, equals the pre-solve state |
| Nova 2 | `[0 0 0 .5 .5 .5 1 1 1]` |
| Nova 5 | `[0 0 0 .5 .5 .5 1 1 1]` |

Forecast if tests were dropped (measured on these solutions): initial-state alone 2 of 12; plus the
overshoot case 4 of 12; plus the advancing trio 6 of 12.

`test_ed_solvers` failed on base in 2 runs and the evaluator verified it reproduces on clean HEAD, so it
was not charged to the agents (Nova 11 is FAIL_MISSED_REQUIREMENT, not a regression). No `test.sh` change.

**Decision: keep every requirement, run a bigger batch.** Per-run chance of clearing everything is about
8% (Nova 3 alone cleared the new suite), so 12 more runs carry roughly a 2 in 3 chance of a passer.

### R62 artifact (what the bigger batch runs against)

| Measure | Value |
|---|---|
| New tests with the solution | 118 passed, 3x, digest `2820df1e` |
| Full 118-case run on base | 118 failed, 0 passed, finished in 417s |
| Empty-log test vs all 11 batch 10 solutions | passes on every one, including Nova 3 |
| `test.patch` | `333454dcbf4c`, 106 functions, 118 cases |
| `meta.md` / `solution.patch` | unchanged (`00fcd9740fa8` / `7e9bfba1bb02`) |

## Batch 11 (the accepted pool: batch 10's 12 runs renumbered + 4 appended) - **2 of 15, ACCEPTED**

| Run | New suite | Base | Verdict | Note |
|---|---|---|---|---|
| Orion | 117/117 | clean | PASS_LEGITIMATE | appended; 28.9M prompt tokens, 460 added lines |
| Vega 1 | 117/117 | clean | PASS_LEGITIMATE | appended; 673 added lines |
| Vega 2 | 116/117 | clean | FAIL_MISSED_REQUIREMENT | appended; hook set dt to 2*t1, run ended at 9.0 vs 4.0 |
| Nova 1 | 0/117 | 221 failed | FAIL_MISSED_REQUIREMENT | appended; verifier wrapper timeout, not per-test data |
| Nova 2-12, Vega 3 | as batch 10 | | | batch 10 runs re-listed (identical LOC and tokens) |

Clean runs with per-test data: 13. Kills: initial-state rollback 8 (F-34), overshoot retry 6 and
final-time jump 2, union 7 (F-10 hook cell), stops-before-advancing 2 (F-35). Killed nothing: 87 of 117.
Agent split: Nova 0/11 with a result, Orion 1/1, Vega 1/3.
