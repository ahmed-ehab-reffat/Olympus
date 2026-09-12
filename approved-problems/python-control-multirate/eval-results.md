# eval-results.md — python-control-multirate

## Batch 1 (Nova x5) — 0/5, on the 140-test artifact

These numbers are STALE as evidence for the current deliverables. They are kept because they
are what drove the solvability fix. Patches saved under `agent-runs(27)/`.

| Run | Verdict | Failed | Failing tests | Approach note |
|---|---|---|---|---|
| Nova_1 | fail | 7 / 140 | direct_feedthrough_cycle, offsets_reject_fractional, lift_signal_labels, linearize_between_base_steps, linearize_before_time_zero, phase_system_rejects_fractional_index, nested_multirate_offsets | whole feature in a new `control/multirate.py`; `int()` coercion for offsets and phase indices, nearest-step rounding for phase selection |
| Nova_2 | fail | 16 / 140 | state_labels, hold_state_per_output, unspecified_subsystem_timebase, unspecified_dynamic_subsystem_timebase, base_is_greatest_common_divisor, neither_acts_every_step, direct_feedthrough_cycle, offsets_across_three_rates, lift_signal_labels, lift_multirate_keeps_state_labels, phase_system_rejects_fractional_index, continuous_mimo_subsystem_sampled, nested_multirate_period, nested_multirate_offsets, static_gain_keeps_period, feedback_with_multirate | hold states named from raw subsystem outputs; nested scheduling from an external period ratio; no `bdalg` integration |
| Nova_3 | fail | 11 / 140 | unspecified_dynamic_subsystem_timebase, order_of_subsystems, neither_acts_every_step, direct_feedthrough_cycle, offsets_across_three_rates, lift_signal_labels, linearize_between_base_steps, linearize_before_time_zero, nested_multirate_offsets, static_gain_keeps_period, feedback_with_multirate | contiguous state indexing that mistakes a hold register for the next subsystem's state; `np.rint` phase selection |
| Nova_4 | fail | 5 / 140 | direct_feedthrough_cycle, lift_signal_labels, linearize_between_base_steps, linearize_before_time_zero, nested_multirate_offsets | closest to the reference; failed only on the five unstated blockers |
| Nova_5 | fail | 5 / 140 | direct_feedthrough_cycle, lift_signal_labels, linearize_between_base_steps, linearize_before_time_zero, series_multirate_rejects_other_rate | `int(round(t/dt))` phase selection; `_series_pair` without the timebase rejection |

Every evaluator recorded `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`, `primary_category: coding`, and none flagged an environment or
verifier problem. The artifact was not unclear, it was over-specified: five tests failed
nearly everyone and not one of the five traces to a description sentence.

| Failures | Test | Stated in the description? |
|---|---|---|
| 5/5 | `multirate_direct_feedthrough_cycle` | NO. The description says where a loop IS algebraic, never that one is rejected; solving an invertible cycle is compliant. |
| 5/5 | `lift_signal_labels` | NO. Lifted signal naming appears nowhere. Four evaluators called it unstated. |
| 4/5 | `linearize_between_base_steps` | Weakly. "The step holding its time" is stated, but off-grid times are a corner nothing in the library produces. |
| 4/5 | `linearize_before_time_zero` | Weakly, same clause, more exotic. |
| 4/5 | `nested_multirate_offsets` | Ambiguous. "Sample times differ" has two readings for a nested periodic subsystem. |

All five arrived in rounds 11-14 from Test Fairness *coverage suggestions*, not from the
original design. All five removed; the solution is unchanged and no description clause is left
without a test.

## Replay of batch 1 against the revised 146-test suite (measured, not projected)

Each saved agent patch re-applied to a clean base tree and run against the current tests.

| Run | Result | Remaining failures |
|---|---|---|
| Nova_1 | 2 failed / 144 passed | offsets_reject_fractional, phase_system_rejects_fractional_index |
| Nova_2 | 14 failed / 132 passed | state layout, nesting, `bdalg` integration |
| Nova_3 | 7 failed / 139 passed | state layout, `bdalg` integration |
| **Nova_4** | **146 passed — PASS** | none |
| Nova_5 | 2 failed / 144 passed | series and operator timebase rejection, one defect |

**1 of 5 = 20% pass**, above the solvability floor and inside the `<= 40%` cap. Every remaining
failure sits on a plainly stated requirement: `series` still refusing different sample times,
the block-diagram operators taking a multirate operand, and offsets and phase indices being
base steps. A fresh batch is still the real oracle; this is a replay on the same five solvers.

## Round 28 — Solution Quality: late-bound closure on nested nonlinear multirate

Solution Quality passed but scored comprehensiveness and code quality 2/3 each, both on one
defect: in `_multirate_action` the nonlinear wrapper's lambdas closed over `model`, which was
then rebound to the wrapper itself. Late binding made the wrapper call itself. Reproduced
directly: nesting a nonlinear `MultirateSystem` inside another `interconnect` raised
`RecursionError`. Fixed by binding the inner phase model to its own name.

The defect was reachable from the description, which allows nonlinear discrete subsystems and
says a multirate subsystem repeats after its own period. Nesting a nonlinear multirate is the
intersection of those two clauses and no test covered it, so this was an open FP orphan as well
as a bug; the missing test is what let the bug ship. `test_nested_nonlinear_multirate_response`
closes it, checked against a hand reference rather than the implementation.

Intake result: the new test passes on **all five** saved implementations. Every agent handled
nested nonlinear composition correctly and only the reference was wrong, so the test costs
nothing in solvability and the tally below is unchanged. No description change was needed.

## Robustness of the fix: per-test failure tally across all five implementations

The replay above says one agent passes. This asks the harder question: is any single test
carrying the difficulty, the way the five removed ones did on the original artifact? Each saved
patch is an independent implementation, so tallying failures per test across all five shows
whether difficulty is distributed or concentrated.

| Tests | Fail on |
|---|---|
| 128 | 0 of 5 implementations |
| 11 | 1 of 5 |
| 7 | 2 of 5 |
| 0 | 3, 4 or 5 of 5 |

**Nothing fails more than 2 of 5.** On the artifact that scored 0/5, two tests failed all five
and three more failed four of five; that concentration is what made it unsolvable. The current
suite has no such cliff, so the pass is structural rather than lucky: the seven hardest tests
(`unspecified_dynamic_subsystem_timebase`, `static_gain_keeps_period`,
`phase_system_rejects_fractional_index`, `offsets_across_three_rates`,
`multirate_neither_acts_every_step`, `feedback_with_multirate`,
`multirate_all_direct_cycle_never_algebraic`) each split the field, which is
what a real discriminator looks like.

It also shows the band should not be relaxed further. Nova_1 is two fractional-validation tests
from passing and Nova_5 is two timebase-rejection tests away, both on plainly stated
requirements. Dropping the first pair alone would give 2/5 = 40%, exactly the cap; dropping both
pairs would give 3/5 = 60% and fail as too easy. 1/5 with two agents close behind is the right
place to sit.

**Standing caveat.** This is a replay against the same five solvers, and their patches predate
several description changes (the feature-request reframing, the negative-step and offset
lower-bound clarifications, `lift` added to the linearity list). Agents never see the tests but
they do see the description, so a fresh batch should do at least as well; 1/5 is best read as a
lower bound. A fresh batch remains the only real oracle.

## Round 29 — all-direct cycle added, lift labels re-declined

An all-direct-feedthrough cycle was a real coverage gap: neither loop-named test built one.
The suggested `ValueError` assertion is not implementable, because such a cycle raises
`RuntimeError` from the repository's own `_compute_static_io` before multirate code runs, and
pinning that inherited string was already ruled unfair in round 8. The stated half was taken
instead: a cycle with feedthrough on both members and alternating `offsets`, so no phase has
both acting and the loop is never algebraic. Intake: fails Nova_2 and Nova_3 only, 2 of 5,
joining the existing hardest tier rather than forming a cliff. Nova_4 still passes 146/146.

Lift channel labels re-declined for the third time: it is `lift_signal_labels`, one of the two
tests that failed 5 of 5 and produced the 0/5 batch, and no description sentence names channels.

## Batch 2 (Nova x10, `agent-runs(37)`) — 0/10, and the cause was a contradiction in my own meta

| Run | Failed | Failing tests |
|---|---|---|
| Nova_6 | 1 / 146 | phase_system_rejects_fractional_index |
| Nova_7 | 2 / 146 | lift_rejects_nonlinear_system, phase_system_rejects_fractional_index |
| Nova_9 | 2 / 146 | lift_rejects_nonlinear_system, phase_system_nonlinear_model_behaviour |
| Nova_1 | 4 / 146 | nested_nonlinear_response, nested_multirate_period, static_gain_keeps_period, feedback_with_multirate |
| Nova_8 | 4 / 146 | same four as Nova_1 |
| Nova_3 | 5 / 146 | the four above plus phase_system_rejects_fractional_index |
| Nova_4 | 6 / 146 | those plus series_with_multirate |
| Nova_10 | 6 / 146 | the nesting four plus two nonlinear phase_system tests |
| Nova_5 | 8 / 146 | the nesting four, fractional index, series_with_multirate, two lift rejections |
| Nova_2 | 15 / 146 | continuous-subsystem family plus operators |

Failure histogram: static_gain_keeps_period 7/10, nested_multirate_period 7/10,
feedback_with_multirate 7/10, phase_system_rejects_fractional_index 6/10,
nested_nonlinear_response 6/10. Everything else is 3 or fewer.

**The 7/10 cluster is one defect, and it is mine.** All four nesting tests fail on the same
line, `assert isinstance(sys, ct.MultirateSystem)`, with the agent having built a plain
`InterconnectedSystem` at dt=0.1. The reason is in the meta's last paragraph: "`interconnect` on
equal sample times still builds a `LinearICSystem`". In these tests `inner.dt == extra.dt == 0.1`,
so seven agents applied that sentence exactly as written. The tests contradicted the
description; the agents were right and the artifact was wrong.

**`phase_system_rejects_fractional_index` (6/10) was an unstated requirement.** The meta
described `phase_system(k)` as counted round the period with negative steps included and said
nothing about a non-integer step. Coverage-suggestion origin, same class as the five tests that
caused the first 0-batch.

Both fixed by ALIGNING the meta to the tests rather than deleting the tests, which keeps the
difficulty legitimate: the last paragraph now says the single-rate path applies only "where no
subsystem is multirate" and that the operators "take a multirate operand, including against a
plain gain, and return a `MultirateSystem` keeping its period"; the nesting sentence now spells
out that a multirate subsystem makes the result multirate "even where every sample time is
equal"; and `phase_system` now states "a step that is not a whole number rejected". No test
changed, no solution change.

### Solvability measured, not projected

Nova_6's own patch plus the two lines implementing the now-stated whole-number rule
(`if k != int(k): raise ValueError(...)`) passes **146/146**. A real agent implementation plus
the minimal code for a rule the description now states clears the entire suite.

### The fix does not overshoot into too-easy

Nova_1 fails only the nesting four. Applying the minimal gate fix for the newly stated class
rule (`or any(isinstance(s, MultirateSystem) for s in syslist)`) still leaves all four failing,
now on `assert 0.1 == 0.2`: the outer period must fold in the nested subsystem's own period.
That requirement was ALREADY stated before this batch ("a multirate one repeats after its own
period, not its sample time") and Nova_1 did not implement it. So stating the class rule removes
the unfairness without handing over the hard part, and the nesting family stays a real
discriminator.

## Batch 3 (Nova x10, `agent-runs(39)`) — the meta fix worked; 2/10 = 20% after one more test fix

This batch ran WITH the round-31 meta corrections, and they landed: the nesting family
(nested_multirate_period, static_gain_keeps_period, feedback_with_multirate,
nested_nonlinear_response) went from 7/10 failures to ZERO, and
phase_system_rejects_fractional_index went from 6/10 to zero. Agents implemented both rules once
the description stated them.

As submitted the batch was 0/10, on one remaining defect: `lift_rejects_nonlinear_system` failed
7 of 10, and Nova_3 and Nova_4 failed NOTHING ELSE. All seven raised `TypeError`. The test passes
a plain `NonlinearIOSystem`, which is none of the three kinds the description says `lift` takes,
so a wrong-type argument was being failed for using Python's idiomatic exception. The reference
only satisfied it because I had earlier added guards converting `TypeError` to `ValueError`,
which is the tell that the pin fought the language rather than testing behaviour.

Fixed by accepting `(ValueError, TypeError)` on the three WRONG-TYPE rejections
(`lift_rejects_nonlinear_system`, `lift_rejects_non_numeric_sample_time`,
`phase_system_rejects_non_numeric_index`). Domain rejections keep the stated `ValueError`: a
nonlinear MULTIRATE system passed to `lift` is the right type with the wrong property and stays
`ValueError`, as do the incommensurate and offset-range rejections.

Note the contrast that decided this: `phase_system_rejects_fractional_index` failed 6/10 with
"DID NOT RAISE", a genuinely missing behaviour fixed by STATING the rule, while the lift tests
failed with agents correctly rejecting under a different exception class, fixed by RELAXING the
pin. Same symptom, opposite fixes; the failure TEXT is what separates them.

### Result on the corrected suite (replay of all 10)

| Run | Result |
|---|---|
| **Nova_3** | **146 passed — PASS** |
| **Nova_4** | **146 passed — PASS** |
| Nova_1, Nova_10, Nova_7 | 1 failed each |
| Nova_6 | 2 failed |
| Nova_5 | 3 failed |
| Nova_2 | 6 failed |
| Nova_9 | 7 failed |
| Nova_8 | 8 failed |

**2/10 = 20% pass**, inside the `<= 40%` cap and on the hard side of it. This replay is much
stronger evidence than the earlier ones: these agents DID see the current description, and the
only delta between what they ran and the current artifact is three test-side exception pins.

### Per-test tally over 10 independent implementations

| Tests | Fail on |
|---|---|
| 123 | 0 of 10 |
| 18 | 1 of 10 |
| 4 | 2 of 10 |
| 1 | 3 of 10 |
| 0 | 4 or more of 10 |

Nothing fails more than 3 of 10. The 0-batches were caused by cliffs (7/10, and 5/5 in the first
one); there is no cliff now, and the difficulty is spread across 23 distinct tests rather than
concentrated in a blocker.

## Final standing (156 tests)

| Check | Result |
|---|---|
| Solvability | Nova_4 + the stated `*`/`+` rule passes 156/156 (measured, not projected) |
| Pool tally over 11 stored patches | 113 clean, 19 at 1/11, 17 at 2/11, 3 at 3/11, 2 at 4/11, 2 cliffs (7/11, 9/11) |
| Both cliffs | the two FP probes whose rules the meta now states explicitly; every stored patch predates that wording |
| Base mode | 3814 passed, identical to vanilla, both apply orders |
| F2P | 156/156 fail on base, 0 vacuous |
| Flakiness | 3 consecutive runs identical |
| Effective LOC | human-effective 392 |

## Local validation (current deliverables)

| Check | Command | Result |
|---|---|---|
| Vanilla whole tree, offline | `pytest` at repo root, `--network none`, uid 1000 | 3814 passed / 559 skipped / 11 xfailed / 1 xpassed; 6 failures confined to `doc/test_sphinxdocs.py`, which needs the sphinx `generated/` stubs |
| Base mode, unpatched sources + test.patch | `./test.sh base` | 3814 passed / 559 skipped |
| New mode, unpatched sources + test.patch | `./test.sh new` | 146 failed / 0 passed (F2P confirmed for every test) |
| Base mode, both patches | `./test.sh base` | 3814 passed / 559 skipped, identical to vanilla |
| New mode, both patches | `./test.sh new` | 146 passed |
| Apply order solution-then-test | both `git apply` clean | base 3814 passed, new 146 passed |
| Flakiness, new mode | consecutive runs | identical every run |
| Flakiness, base mode | repeated across validation passes | 3814 passed every run |
| Effective LOC | `effective_loc_check.py solution.patch` | human-effective 378, raw 677, 4 files |
| Patch encoding | `file solution.patch test.patch` | ASCII text, LF |
| test.sh mode | `grep "new file mode" test.patch` | 100755 |
| Banned markers in test file names | grep for the two forbidden substrings | none |
