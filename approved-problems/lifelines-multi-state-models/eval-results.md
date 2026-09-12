# eval-results.md — lifelines-multi-state-models

## Agent runs

### Batch 1 (2026-08-08, 5 runs, description revision 1) — 0 of 5

| Agent | Verdict | Failed | Of which unfair | Residual | Failure reason |
| --- | --- | --- | --- | --- | --- |
| Nova 1 | FAIL_MISSED_REQUIREMENT | 16 | 11 | 5 | ever-reaching returned a scalar; CI formula; visits summed occupations |
| Nova 2 | FAIL_MISSED_REQUIREMENT | 19 | 12 | 7 | ever-reaching scalar; secondary estimand shapes; visits overcounted |
| Nova 3 | FAIL_MISSED_REQUIREMENT | 21 | 12 | 9 | ever-reaching scalar; wide-form conversion; multivariate metadata |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 23 | 12 | 11 | ever-reaching scalar; CI; transition log rank |
| Orion | FAIL_MISSED_REQUIREMENT | 20 | 11 | 9 | ever-reaching scalar; return structure; group handling |

**0 of 5 is not yet a solvability verdict** (P(0 passes in 5 | 10% true rate) is 59%), but the
failures were not scattered: eleven of the twelve universal misses were the single method
`probability_of_ever_reaching`, and every run failed all of them. See the diagnosis below.

### Batch 2 (2026-08-08, 16 runs, description revision 2) — 0 of 16, but near

The revision worked: failure counts fell from 16-23 per run to 1-18, and the best run failed a
**single** test.

| Failures | Runs |
| --- | --- |
| 1 | Nova 1 |
| 2 | Nova 6 |
| 4 | Nova 12, Nova 15, Orion |
| 5 | Nova 10, Nova 14 |
| 7-9 | Nova 2, 3, 4, 8, 9, 11, 13 |
| 13, 18 | Nova 5, Nova 7 |

The dominant cluster was one misreading. Six tests, all of them about a **censored** interval
followed by a gap or by a new interval at the same instant, failed together in the runs that
failed any of them, and `test_a_censored_row_followed_at_the_same_instant_is_allowed` failed in
eleven of sixteen. Nova 1 failed nothing else.

Removing that cluster projects **1 of 16 passing, about 6 percent**, which is inside the target
band. See the diagnosis in `feedback.md`.

### Batch 3 (2026-08-08, 10 runs, description revision 3) — 2 of 10 pass, 20 percent

| Agent | Verdict | Failed of 191 |
| --- | --- | --- |
| Nova 10 | PASS_LEGITIMATE | 0 |
| Nova 7 | PASS_LEGITIMATE | 0 |
| Nova 3 | FAIL_MISSED_REQUIREMENT | 2 |
| Nova 4 | FAIL_MISSED_REQUIREMENT | 3 |
| Nova 5 | FAIL_MISSED_REQUIREMENT | 3 |
| Nova 8 | FAIL_MISSED_REQUIREMENT | 4 |
| Nova 2 | FAIL_WRONG_LOGIC | 5 |
| Nova 9 | FAIL_MISSED_REQUIREMENT | 9 |
| Nova 1 | FAIL_MISSED_REQUIREMENT | 10 |
| Nova 6 | FAIL_MISSED_REQUIREMENT | 14 |

**Solvable at 20 percent**, inside the <= 40 percent cap and above the floor. Six of the eight
failures shared one algebra mistake, reading the interval as the root of variance over hazard
rather than the root of variance, over hazard. Five mishandled subject identifiers reused
across independent groups of the multivariate test.

### Batch 4 (2026-08-08, 9 runs) — 0 of 9, caused by my own false-positive fix

Closing the two batch-3 false positives with tests but **without matching description clauses**
turned both into hidden requirements. They became the top two universal misses.

| Test | Failed in |
| --- | --- |
| `test_the_wide_form_records_a_state_entered_without_an_observed_move` | 9 of 9 |
| `test_a_point_mass_start_makes_from_state_redundant_over_a_later_window` | 8 of 9 |
| the two confidence interval tests | 6 of 9 |

Three ambiguities in the description, all mine, all genuine two-way parses:

- "the root of the variance over the hazard" reads as either the root of variance-over-hazard or
  the root of the variance divided by the hazard. Six runs took the first.
- "`from_state` starts from that state" never said **when**. Eight runs applied it at `since`
  rather than at time zero.
- "the time it was entered" never said whether an interval that simply begins in a state counts
  as entering it. All nine read it as an observed move only.

All three reworded. Projection with only those removed: **3 of 9, 33 percent**, inside the cap.
Residuals stay real: multivariate log rank, landmark cohorts, converter ordering, state specific
risk sets.

### Batch 5

Not yet run. Required: the description was revised, so batch 4 is stale.

## Local validation

All runs inside `olympus-base-python` with `--network none --user 1000:1000`, patches applied
to a clean checkout of the base commit after the image was built.

| Check | Result |
| --- | --- |
| Vanilla suite (Environment Quality proxy) | 537 passed, 76 skipped, 11 xfailed, 1 xpassed, 0 failed, 776s |
| Order A: test.patch, then `test.sh base` | 536 passed, 0 failed (one deselect) |
| Order A: test.patch, then `test.sh new` | 191 failed, 0 passed |
| Order A: plus solution.patch, `test.sh new` | 191 passed |
| Order A: plus solution.patch, `test.sh base` | 536 passed, 0 failed |
| Order B: solution.patch then test.patch, new | 191 passed |
| Order B: solution.patch then test.patch, base | 536 passed, 0 failed |
| Reverse apply of both patches | clean, worktree back to base |
| Determinism, new mode x5 | identical every run |
| Repo flakiness, the 8 unseeded-RNG tests x10 | green 10 of 10 |
| Repo flakiness, before the deselect | 1 red run in 22 |
| Platform Verify Flakiness, before the deselect | FAIL, `TestGeneralizedGammaFitter::test_weibull_data_inference` |
| Repo flakiness, after the deselect | see stability runs below |
| solution.patch encoding | ASCII text, LF |
| test.patch `test.sh` mode | `new file mode 100755` |
| Counter 1 (platform auto-block, >= 400) | 949 raw added |
| Counter 2 (human-effective, >= 450) | 470 |
| Padding floor (pessimistic re-count) | 375 |
| Files changed | 5 (2 new, 3 modified) |

Every one of the 191 new tests fails individually on base rather than the run dying at
collection: the test module imports `lifelines`, `lifelines.utils` and `lifelines.statistics`
as modules and reaches for the new names at call time. Verified by parsing the base-mode JUnit
XML: 191 testcase nodes, 191 carrying a failure.

## False positive closure (batch 3)

Both passing agents were adjudicated **false positives**. Each really did pass all 191 tests
while breaking a stated rule, which by definition makes the environment wrong rather than the
agent lucky. Both are now closed, and each closure was proved by re-breaking the reference.

| Escape | What the candidate did | Closing test | Kills |
| --- | --- | --- | --- |
| Nova 1 | `state_matrix_from_transitions` read only observed destinations, so a subject occupying a non initial state without an observed entry move was reported as never having entered it | `test_the_wide_form_records_a_state_entered_without_an_observed_move` | 1 |
| Nova 2 | `expected_length_of_stay` reset `from_state` to a point mass at `since` instead of propagating it from zero | `test_a_point_mass_start_makes_from_state_redundant_over_a_later_window` | 2 |

Both slipped through for the same structural reason: every fixture in the suite started every
subject in the initial state at time zero, so the two readings agreed everywhere the suite
looked. The new fixtures break that assumption on purpose, one entering a non initial state
after a gap and one integrating a conditioned window that starts after the first move.

A third defect, reported separately as S1 rather than as a false positive, was in the reference
itself: `summary.n_transitions` cast the weighted total to an integer, so a transition carrying
weight 0.5 was reported as 0. The cast is gone and a fractional weight case pins it.

## Mutation proof

Each row is a plausible wrong implementation of one stated rule, applied to the reference and
run against the new tests. A surviving mutant would mean the rule is not actually tested.

| # | Mutant | Result | Tests failed |
| --- | --- | --- | --- |
| M1 | product integral multiplies each new factor on the left | KILLED | 26 |
| M2 | risk set closed at the entry instant | KILLED | 3 |
| M3 | risk set open at the exit instant | KILLED | 54 |
| M4 | diagonal of the increment matrix left at zero | KILLED | 34 |
| M5 | occupation carried as a column vector | KILLED | 25 |
| M6 | length of stay uses the value at the end of each step | KILLED | 4 |
| M7 | ever reaching reports the occupation | KILLED | 6 |
| M8 | visits omit the state started in | KILLED | 5 |
| M9 | hazard variance without the finite population term | KILLED | 5 |
| M10 | landmark occupancy uses the risk set convention | KILLED | 7 |
| M11 | transition window includes the move at its start | KILLED | 3 |
| M12 | states and transitions left in insertion order | KILLED | 36 |
| M13 | sojourn measured from time zero | KILLED | 5 |
| M14 | weights reach the counts but not the risk sets | KILLED | 9 |
| M15 | states taken from the origins only | KILLED | 143 |
| M16 | initial distribution counts rows not subjects | KILLED | 3 |
| M17 | log rank variance without the finite population factor | KILLED | 4 |
| M18 | reported timeline drives the integrals | KILLED | 1 |
| M19 | mean sojourn does not cut the last stay | KILLED | 1 |
| M20 | state matrix always keeps the last entry | KILLED | 1 |

20 of 20 killed. Run alongside nine false-positive probes as one panel: **29 of 29 caught, none survived**.

## False positive panel

Each row is a divergent implementation a competent agent could defend, applied to the
reference to see whether it can pass the suite while breaking a stated rule.

| # | Divergence | Expected | Result |
| --- | --- | --- | --- |
| FP1 | window matrix via a pseudo inverse of the earlier matrix | caught | 3 failed |
| FP2 | occupation reported left continuously | caught | 2 failed |
| FP3 | timeline also carries the censoring times | caught | 119 failed |
| FP4 | empty risk set yields a null increment | caught | 50 failed |
| FP5 | visits count the moves out of a state | caught | 3 failed |
| FP6 | summary indexed by the pairs rather than the names | caught | 4 failed |
| FP7 | absorbing means never the origin of an observed move | caught | 1 failed |

FP7 **escaped the first pass**: it passed all 152 tests of that round, because no fixture held a state that
subjects were only ever censored in, so the two readings of "never left" agreed everywhere.
Both readings are defensible English, which is the textbook false-positive shape. Fixed on
both sides at once, which is the only correct fix: the description now says
`absorbing_states_` are "those no interval ever begins in", and a fixture with exactly that
state was added. The re-run above kills it.

FP1 is listed as caught rather than as an over-constraint on purpose. The description pins the
window matrix as a product over the moves inside the span; the pseudo inverse is a different
computation that disagrees once an earlier matrix is singular, which it is as soon as a state
has absorbed. An agent following the sentence does not write it.

## Oracle cross-checks

Every reduction below is asserted inside the test suite, so the reference is re-verified on
every run rather than at authoring time only.

| Quantity | Oracle already in the repository | Agreement |
| --- | --- | --- |
| Occupation of the transient state, two state model | `KaplanMeierFitter.survival_function_` | exact |
| Occupation of cause 1, competing risks | `AalenJohansenFitter.cumulative_density_` | exact |
| Occupation of cause 2, competing risks | `AalenJohansenFitter.cumulative_density_` | exact |
| Cumulative transition hazard | `NelsonAalenFitter(nelson_aalen_smoothing=False)` | exact |
| Its variance | `NelsonAalenFitter._cumulative_sq` | exact |
| Its confidence interval | `NelsonAalenFitter.confidence_interval_` | exact |
| Two group transition log rank, statistic and p value | `statistics.logrank_test` | exact |
| The same restricted by `t_0` | `statistics.logrank_test(t_0=6.0)` | exact |
| Three group transition log rank, statistic, p value, degrees of freedom | `statistics.multivariate_logrank_test` | exact |
| Sojourn survival in a state | `KaplanMeierFitter` on the stay lengths | exact |

Structural checks that no single oracle covers: the occupation sums to one at every time on
the timeline; the transition matrix chains across a two way and a three way split of its span;
the length of stay adds up across a split and totals the width of its window; ever reaching
never falls; the landmark rows sum to one wherever they are defined. The reversible
illness-death fixture was additionally hand-computed at all seven transition times.

## Test coverage by requirement

| Requirement group | Tests |
| --- | --- |
| Export, labels, state space, transitions, absorbing states, timeline | 12 |
| Risk sets, counts, ties, gaps, delayed entry | 10 |
| Occupation, including the three reductions to existing fitters | 13 |
| Initial distribution | 4 |
| Cumulative hazard, variance, confidence interval | 12 |
| Transition matrix and its chaining | 8 |
| Landmark, non Markov matrix | 13 |
| Occupation at a time, and predict | 6 |
| Expected length of stay | 8 |
| Expected number of visits | 5 |
| Probability of ever reaching | 8 |
| Sojourn survival, median, mean | 7 |
| Summary | 3 |
| Weights | 10 |
| Caller supplied timeline | 14 |
| Validation and rejections | 22 |
| The three converters | 16 |
| The two log rank tests | 15 |

198 total.
