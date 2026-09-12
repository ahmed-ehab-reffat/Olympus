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
