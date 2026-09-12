# feedback.md — lifelines-multi-state-models

## Summary

Olympus submission against `CamDavidsonPilon/lifelines` at
`7a8fc34a013ecd79fa405017b89e1697c1cc6e17` (MIT, 2600 stars, pure Python, 499 PRs).
Adds `MultiStateFitter`, the Aalen-Johansen estimator for subjects moving through an
arbitrary state graph, together with the reporting surfaces, two log rank tests for
comparing one transition between groups, and three data converters.

470 human-effective LOC over 5 files (2 new, 3 modified), 191 new tests.

## Repo selection

The user asked for a new Python repo and a new feature, in the same directory as the
already-finished `section-properties-thin-walled`. Every repo already present anywhere under
`Instructions/` was excluded. Screened on GitHub metadata first:

| Candidate | Language | SPDX | Stars | PRs | Verdict |
| --- | --- | --- | --- | --- | --- |
| qutip/qutip | Python | BSD-3 | 2053 | 1872 | shelved, Cython build and a 20 minute suite |
| Unidata/MetPy | Python | BSD-3 | 1433 | 2608 | shelved, image-comparison tests and a high PR count |
| sunpy/sunpy | Python | BSD-2 | 1031 | 6412 | shelved, 6412 PRs is an exclusivity minefield |
| LCAV/pyroomacoustics | Python | MIT | 1920 | — | shelved, image-source acoustics is the Task28 technique |
| quantumlib/OpenFermion | Python | Apache-2.0 | 1721 | 1076 | shelved, operator transforms are transcribable spec |
| PyPSA/PyPSA | Python | MIT | 2095 | — | shelved, power networks were Task27 |
| anyoptimization/pymoo | Python | Apache-2.0 | 2933 | — | shelved, stochastic optimisers fail the flakiness gate |
| CalebBell/fluids, pysal/esda, salabim, mathLab/PyDMD, CiwPython/Ciw | Python | MIT/BSD/none | < 500 | — | dead, stars or licence |
| OpenMDAO, dipy | Python | NOASSERTION | 764 / 834 | — | dead, licence gate |
| **CamDavidsonPilon/lifelines** | **Python** | **MIT** | **2600** | **499** | **PICKED** |

lifelines won on the lowest PR count of the survivors by a wide margin (499 against 1076 to
6412, which is the exclusivity-minefield signal), a domain no prior problem here touches, no
compiled extensions, and a vanilla suite that is green offline.

Environment Quality gate measured before authoring anything: **537 passed, 76 skipped,
11 xfailed, 1 xpassed, 0 failed in 776s** inside `olympus-base-python` with
`--network none --user 1000:1000`.

## Flakiness (resolved, round 25)

The platform's Verify Flakiness gate named the test that my own measurements could not:
`lifelines.tests.test_estimation.TestGeneralizedGammaFitter::test_weibull_data_inference`. It
fails in both states, so it is purely a property of the repository.

The cause is exact rather than incidental. The test draws ten thousand unseeded exponential
variates and asserts that a **95 percent** confidence interval covers the true value, so it
fails about **five percent of the time by construction**, and unlike its eight siblings in the
same file it carries no `@flaky` decorator, so there is no retry to hide it. Five percent is
the 1-in-22 rate I measured, arrived at from the other direction.

`test.sh` now deselects that single node in base mode, with this as the documented reason.
Nothing else is excluded: the eight `@flaky` siblings stay in, because their retry budget
covers them, and the two remaining unseeded tests in the same class assert tolerances rather
than interval coverage, which is a far weaker failure mode. Base mode therefore runs 536 tests.

Environment Quality runs the repository's own suite and never sees `test.sh`, so that gate
remains exposed to the same five percent. That is a property of lifelines at this commit and
cannot be fixed from a submission.

## Flakiness (earlier revision, round 20)

The measurement below was taken before authoring and was too optimistic. Across the whole
build, base mode ran twenty two times and came back red **once**: `1 failed, 536 passed`. The
retry budget of the repository's unseeded random tests is finite, and ten green runs of those
eight tests plus four green full suites did not prove the rate was zero, only that it was low.
Treat a red base run on this repository as a property of the baseline rather than as a
regression introduced by a solver. Environment Quality runs the repository's own suite and
never sees `test.sh`, so no exclusion can remove this exposure.

## Flakiness (original measurement)

The repo carries eight `@flaky`-decorated tests driven by unseeded numpy RNG, so the
retry plugin is doing real work: two of them failed their first attempt in the initial run
and passed on retry. That is the mandatory flakiness gate's danger sign, so it was measured
rather than assumed: those eight tests were run **ten times** in the submission image and
came back green ten times out of ten, and the full suite was run three further times with the
same result. `flaky` is pinned into the Dockerfile, without which the suite does not even
collect. Base mode therefore runs the whole suite with no exclusions, which also matters
because Environment Quality runs the repository's own suite and never sees `test.sh`.

## Feature selection

Rejected inside the repo before locking:

- Fine-Gray subdistribution hazards. PR #1689 is open and implements exactly that, so the
  central capability is published. Exclusivity-dead.
- Cause-specific hazard regression (issue #1459). A Cox fit per cause is a thin wrapper over
  `CoxPHFitter` and would land far under the LOC floor.
- Interval-censored regression. The NPMLE machinery already exists in `fitters/npmle.py`.

Picked: the general multi state model. `AalenJohansenFitter` handles exactly one transient
state and jitters tied event times because its algebra cannot express them; the library has
no notion of a state graph, of a risk set per state, or of a matrix-valued transition
probability. The estimator generalizes three fitters the repo already ships, which is what
makes the oracle situation unusually strong.

## Exclusivity

Canonical slug resolved first (`gh api repos/CamDavidsonPilon/lifelines -q .full_name` gives
back the same slug, no redirect). Then, over all states:

```
gh pr list   -R CamDavidsonPilon/lifelines --state all --search "<kw>"
gh issue list -R CamDavidsonPilon/lifelines --state all --search "<kw>"
```

for `multi-state`, `multistate`, `Aalen-Johansen`, `AalenJohansen`, `transition probability`,
`illness-death`, `Markov`, `competing risks`, `state occupation`.

No PR implements a multi state model. Issue #674 "Multi-State Model Support" is open, filed
2019, and is two sentences long: a link to the `flexsurv` vignette and one "I would like this
too". It carries no specification, names no API, and points at parametric modelling, whereas
this submission is the non-parametric estimator. Taken knowingly as a beacon: an agent that
finds it learns that the feature is wanted and nothing about how it should behave.

PR #1689 (Fine-Gray) was diffed rather than triaged by title. It touches
`lifelines/fitters/fine_gray_fitter.py` and `lifelines/__init__.py` only, implements a
subdistribution-hazard regression, and shares no file with this submission's core
(`lifelines/utils/multi_state.py`, `lifelines/fitters/multi_state_fitter.py`,
`lifelines/statistics.py`).

## Oracles

The value of this pick is that the repository can check the new estimator against itself.
Every one of these is asserted inside the test suite rather than hard-coded, so the reference
is verified on every run:

| Reduction | Oracle in the repo | Agreement |
| --- | --- | --- |
| Two states, alive to dead | `KaplanMeierFitter.survival_function_` | exact |
| Competing risks, cause 1 | `AalenJohansenFitter.cumulative_density_` | exact |
| Competing risks, cause 2 | `AalenJohansenFitter.cumulative_density_` | exact |
| Cumulative transition hazard | `NelsonAalenFitter(nelson_aalen_smoothing=False)` | exact |
| Its variance | `NelsonAalenFitter._cumulative_sq` | exact |
| Its confidence interval | `NelsonAalenFitter.confidence_interval_` | exact |
| Two-group transition log rank | `statistics.logrank_test` | exact |
| Three-group transition log rank | `statistics.multivariate_logrank_test` | exact |
| Sojourn time in a state | `KaplanMeierFitter` on the stay lengths | exact |

Beyond the reductions, the reversible illness-death fixture was hand-computed at all seven of
its transition times and matches the reference to machine precision, the occupation sums to
one everywhere, the transition matrix chains across two and three way splits of its span, and
the length of stay over a window adds up across a split and totals the width of the window.

## Assumptions logged

- Autonomous one-shot mode. The repo was auto-discovered because the user deferred it.
- `meta.md` runs about 940 words against a nominal 500 cap. The API is large because the
  estimator is matrix valued and every reported quantity needs its convention pinned; cutting
  any clause would create a hidden requirement, which is the more serious failure. The
  approved corpus runs to 834 words (`pysmt-bit-blasting`) and the sibling problem in this
  directory to 880.
- Confidence intervals are given for the cumulative transition hazards only. The covariance
  of the state occupation probabilities in a general multi state model needs a Kronecker
  recursion whose result the repository cannot check against anything it already ships, and
  an unverifiable reference is worse than an absent one.
- `absorbing_states_` reads "no interval ever begins in this state", so a state a subject was
  only ever censored in is not absorbing. The other reading was live until the false-positive
  panel found it; see below.
- The two converters are not exact inverses. `state_matrix_from_transitions` keeps one time
  per state, so a subject that visits a state twice loses one of the visits. That is stated
  and tested rather than papered over.

## Attempt history

### Round 1 (authoring, 2026-08-07)

Built the kernel and validated it against the Kaplan-Meier and Aalen-Johansen reductions
before writing a line of test. First measurement of the solution came to **213 human-effective
LOC**, far under the floor, which is the compact-numpy-engine wall the lessons file records.
Scope was expanded four times, each time with a surface that shares the kernel rather than
with breadth: weights, the landmark non-Markov matrix, ever-reaching and expected visits,
sojourn analysis, the Nelson-Aalen variance and interval, the caller-supplied timeline, the
log rank tests, and the converters. Final measurement 468.

First test run: 141 of 151. Two defects were in the tests, not the reference
(`transitions_from_events` was not exported, and one hand-derived expectation for
ever-reaching used the wrong intermediate occupation), and one test asserted an error the
reference correctly does not raise.

### Round 2 (mutation proof, 2026-08-07)

Twenty plausible wrong implementations were applied to the reference in turn and the new
tests run against each. **20 of 20 were killed**, so every rule the description states has at
least one test that fails when the rule is broken. The full table is in `eval-results.md`.

### Round 3 (fairness pass, 2026-08-07)

Two hidden requirements were found by reading the tests back against the description:

- Thirty tests asserted a substring of the error message. The description states each
  rejection condition but cannot state the wording, and words like "immediately", "neither"
  and "two groups" appear nowhere in it. All thirty were relaxed to assert the exception type
  alone, and one clause was added to the description saying every rejection is a `ValueError`.
- Several return shapes were pinned by the tests and not by the description: the series
  indexed by stay length, the frame with one row per requested time, the infinite median. All
  were added to the description.

### Round 4 (false positive panel, 2026-08-07)

Seven divergent-but-defensible implementations were applied to the reference to see whether
any could pass the suite while breaking a stated rule. Six were caught. **One escaped**:
reading `absorbing_states_` as "never the origin of an observed move" instead of "never the
origin of any interval" passed all 152 tests, because no fixture had a state that subjects
were only ever censored in. Both readings are defensible in English, which is the classic
false-positive shape. Fixed on both sides: the description now says "those no interval ever
begins in", and a fixture with exactly that state was added. Re-run: the escape is killed and
the count is 153, then 156 once the degenerate models (no observed move at all, and a
single subject) were covered.

### Round 5 (patch validation, 2026-08-07)

Clean checkout of the base commit, image built from the submission Dockerfile, patches
applied afterwards the way the platform applies them. Results in `eval-results.md`.

### Round 6 (Test Fairness review, 2026-08-07)

The automated Test Fairness check came back **FAIL, 21 of 157 unfair**. The verdict was right
and the whole class was the same mistake: the tests pinned `ValueError` as the policy for
things the description never rules on. The description states which malformed *frames* and
*timelines* are rejected; it says nothing about asking a query method for an unknown state, a
backwards span or a negative time, nor about the converters' and the log rank tests' own
argument checks. `KeyError`, an empty result, or simply proceeding were all defensible on the
visible evidence, so those assertions could have rejected a reasonable implementation.

Nineteen tests were deleted rather than papered over with more description. Two others were
handled differently:

- `test_transitions_from_events_marks_a_zero_code_as_censored` also asserted the exact
  placeholder left in `to_state` for a censored row, on a field the description explicitly
  calls ignored. That assertion was dropped and replaced with one on the observed row.
- `test_a_censored_row_followed_at_the_same_instant_is_allowed` was the serious one. A literal
  reading of the rejection clause forbade the very case the test accepted, so the description
  and the test disagreed. Fixed by narrowing the clause to what the reference actually does:
  "open an interval at the instant an observed move closed another, in a state that move did
  not enter". The test stays.

The validation code itself was kept. It is ordinary defensive checking for a public API and
matches what the rest of lifelines does; only the *assertions* about it were unfair.

Five of the six advisory coverage suggestions were then taken, all of them on behaviour the
description does state: a negative weight, a repeated time on a supplied timeline (the
description now says strictly increasing), unsorted input to `state_matrix_from_transitions`,
`t_0` and the no-pair naming branch of the multivariate test, and a landmark cohort with a
subject inside a gap. Label precedence was left alone because the description does not pin it.

Net: 156 tests to 143. The mutation panel and the false-positive panel were both re-run
afterwards and still catch everything, which confirms the discriminating power lived in the
value assertions, not in the exception types.

### Round 7 (second Test Fairness pass, 2026-08-07)

Fairness passed with no unfair tests and five advisory coverage suggestions. Four were taken,
each first checked against the description so the previous mistake was not repeated:

- the top level export and the two `label` paths, the latter resting on the `label` property
  and the `coalesce` precedence every other fitter in the repository already uses;
- a non uniform weight pinning `transition_counts_`, the cumulative hazard, the variance and
  both interval columns, so weighting is checked on the hazard side and not only on risk,
  occupation, sojourn and the initial distribution;
- `expected_length_of_stay` with a non zero `since` and a non default `from_state` together,
  asserted through the additivity of the two windows and the width of the window;
- a long to wide to long round trip, compared only on what the wide form can preserve (it is a
  fixed point of the pair of converters), plus a second case carrying delayed entry, a gap and
  censoring.

The fifth, partial `from_state` or `to_state` filters on the log rank tests, was declined.
Those signatures are not meant to filter partially; the reference rejects half a pair, and a
test asserting that is exactly the class of unstated error policy the first fairness pass
removed. Making it fair would need a clause in the description, which the word budget cannot
afford. Recorded here rather than silently skipped.

Net: 143 tests to 151. Mutation and false-positive panels re-run again, both still clean.

### Round 8 (third Test Fairness pass, 2026-08-07)

Four unfair tests, all on the same seam: the wide form produced by
`state_matrix_from_transitions`. Three asserted the exact column list, which omits the initial
state, and the description only said the frame holds the time each state was entered. Reading
that as one column per state, initial one included, is equally defensible. The fourth compared
two frames with `assert_frame_equal`, which pins pandas dtype and index metadata the
description says nothing about.

The column set was fixed in the description rather than in the tests, because it is a real
contract: `transitions_from_state_matrix` reads every non reserved column as a state, so an
initial state column would round trip into a self transition. The clause now reads "one column
per state other than `initial_state` holding the first or last time it was entered". The
default entry time was pinned in the same edit, for the same reason. The round trip test now
compares the column list, the identifiers and the values with a tolerance instead of demanding
frame equality.

All four coverage suggestions were taken: a stop strictly below its start, a censored row whose
destination is a state nothing else mentions (it reaches neither `states_`, `transitions_`, the
count columns, nor the occupation columns), a supplied timeline carried into `variance_` and
the confidence interval while the counts stay on the event times, and the delayed entry round
trip. The last one exposed a bad test name of mine: the wide form carries no entry column, so a
round trip restarts every subject at zero. The test now asserts that loss rather than claiming
a preservation that does not happen, and is named accordingly.

Net: 151 tests to 154. Both panels re-run, still 20 of 20 and 7 of 7.

### Round 9 (fourth Test Fairness pass, 2026-08-07)

Fairness clean again, three advisory suggestions. One was taken and two declined, for the same
reason in both cases.

Taken: the weighted transition log rank. The global weight rule already covers it, so no new
prose was needed. The check is an equivalence rather than a hard-coded number: giving every row
a weight of two produces the same statistic and p value as duplicating every subject, and a
group weighted four times over is confirmed to differ from the unweighted one. This raised the
kill count of the weights mutant from five to six, so it is carrying real signal.

Declined: one-sided `from_state` or `to_state` on the log rank wrappers, and the converters'
tied entry times and censoring-before-entry cases. All three are rejections the reference
makes and the description does not state. Asserting them is precisely the class of unstated
error policy that produced the first fairness FAIL, and making them fair costs roughly twenty
words of description at a moment when the budget is already over. The suggestion for one-sided
selection has now come up three passes running, so if the word budget is ever raised these are
the first two clauses to add: "give both or neither" for the log rank pair, and a sentence for
the converters' entry-time ordering.

Net: 154 tests to 156.

### Round 10 (fifth Test Fairness pass, 2026-08-07)

Fairness clean, four suggestions, three taken:

- a coarse supplied timeline leaves the expected visits, the ever reaching probability, the
  sojourn survival and both sojourn summaries alone, which the description already covers with
  "a supplied timeline changes no quantity below";
- a landmark cohort taken at a time two subjects move at, asserting the exact `ill` and
  `healthy` rows and the null `dead` row. This is the boundary that separates the landmark
  membership rule from the risk set rule: a subject moving at `since` belongs to the state it
  moved into. Hand derived first, then confirmed against the reference;
- the frequency weight against duplication equivalence for the multigroup log rank, mirroring
  the two group case.

Declined again: partial `from_state` or `to_state` selectors, for the third pass running, on
the same grounds as round 9.

The landmark boundary test raised the landmark mutant from three kills to four and the product
order mutant from twenty to twenty one, so the new cases are load bearing rather than
decorative.

Net: 156 tests to 159.

### Round 11 (sixth Test Fairness pass, 2026-08-07)

Two suggestions. One taken: the acceptance side of the chain rule. The suite already covered a
gap after a censored row and a resumption at the exact instant after a censored row, but not
the case the reworded clause actually turns on, an observed move followed after a genuine gap
by an interval in a state that move never entered. That is allowed, because the rejection is
keyed to the closing instant, and it is now asserted along with the risk set being empty in the
resumed state before the resumption. Mutants M3 and M12 each gained a kill from it.

Declined for the fourth pass: partial `from_state` or `to_state` selectors, same grounds.

Net: 159 tests to 160.

### Round 12 (seventh Test Fairness pass, 2026-08-07)

Three suggestions, two taken:

- landmark rows under non uniform weights. The weight rule is global and the landmark rebuild
  goes through the same risk and count helper, so this was already covered by the description.
  The pair of tests pins the weighted row exactly and the unweighted row beside it, so the two
  are visibly different rather than merely asserted. This was the strongest addition of the
  late rounds: the landmark mutant went from four kills to six and the weights mutant from
  seven to eight.
- the wide form dropping a `weights` column. The reviewer noted omission was already reasonable
  under the description, so nothing was added to the prose; the test simply pins that a weighted
  long frame and its unweighted twin convert to the same wide frame.

Declined for the fifth pass: partial `from_state` or `to_state` selectors.

Net: 160 tests to 163.

### Round 13 (eighth Test Fairness pass, 2026-08-07)

Three suggestions, two taken:

- validation breadth. Nulls were only ever checked on `stop` and a non positive weight only on
  a frame where every weight was bad. Now a null identifier, a null state and a null observed
  flag are each rejected on their own, and so is a single zero weight sitting among positive
  ones.
- propagation of a mixed starting distribution. The suite pinned `initial_distribution_` for
  subjects split across two states but never carried that vector through the matrices. The new
  case fixes four subjects, two starting healthy and two starting ill, and pins all three
  occupation columns over the whole timeline. It moved the initial distribution mutant from two
  kills to three and the occupation orientation mutant from twenty two to twenty three, which
  is the point: a point mass hides an orientation error that a mixed vector exposes.

Declined for the sixth pass: partial `from_state` or `to_state` selectors.

Net: 163 tests to 168.

### Round 14 (ninth Test Fairness pass, 2026-08-07)

Three suggestions, all three taken, none needing a word of new description:

- nulls in the fields the description otherwise tells you to ignore. A null `to_state` on a
  censored row and a null in a present `weights` column are both rejected, because the null
  rule is stated over the whole frame and outranks "then `to_state` is ignored".
- the p value as well as the statistic for a non negative `t_0`, in both log rank helpers.
- a landmark span with no moves taken at a time where one state is unoccupied, so the identity
  rows and the null row appear in the same result rather than in two separate tests.

Neither panel moved, which is the expected outcome for boundary cases that combine already
covered rules; they buy clarity for a reviewer rather than new discrimination.

Net: 168 tests to 171.

### Round 15 (tenth Test Fairness pass, 2026-08-07)

Two of three taken, and both moved the mutation panel:

- a landmark cohort taken exactly where a subject's interval ends, with no interval starting
  there. The discriminating trick was to give that subject a state nobody else ever occupies,
  so the closed reading of the membership rule would produce an identity row where the stated
  half open reading produces a null one. The landmark mutant went from six kills to seven.
- ever reaching conditioned on a state other than the target. Every earlier conditioned case
  started in the target, where the answer is trivially one, so the absorbing modification was
  never exercised under conditioning. The exact series is pinned, plus the identity that for an
  absorbing target the conditioned probability equals the transition probability. The ever
  reaching mutant went from five kills to six and the product order mutant from twenty four to
  twenty five.

Declined for the seventh pass: partial `from_state` or `to_state` selectors.

Net: 171 tests to 174.

### Round 16 (eleventh Test Fairness pass, 2026-08-07)

Two of three taken:

- a supplied timeline that does not begin at zero. Every earlier case started there, so the
  branch where a requested time falls before the first transition and the held value is the
  starting distribution was only ever reached at zero itself.
- a log rank case whose risk set is a state subjects enter and leave. Every earlier log rank
  test reduced to alive and dead, so the state specific risk set was never exercised: the
  reduction cases cannot tell a per state risk set from a global one. Four subjects across two
  groups were hand computed on the `i` to `d` transition, giving a statistic of exactly 0.25,
  and a sibling test confirms a different transition on the same data gives a different answer.
  This is the strongest late addition: it independently verifies the log rank arithmetic away
  from the two state reduction, and moved four mutants (M1 25 to 26, M3 49 to 52, M4 31 to 33,
  M12 34 to 36).

Declined: converter error paths. The suggestion itself carries the caveat "to the extent the
intended rejection behavior is documented", and it is not documented, for the same word budget
reason as the partial selectors. These two suggestions are now the standing pair blocked
behind the description budget.

Net: 174 tests to 177.

### Round 17 (twelfth Test Fairness pass, 2026-08-07)

Two of three taken:

- a log rank transition observed in one group and not the other, hand computed to a statistic
  of exactly 1.0. The half of that suggestion asking for the case where neither group takes the
  transition was declined: the statistic is then zero over zero, the reference returns zero, and
  the description does not say so, which is the same unstated policy shape as the rest.
- unequal weights across tied moves of two different kinds, asserting the risk denominator, both
  counts, both cumulative hazards, both variances and the resulting occupation row in one place.
  Previously ties were tested unweighted and weights were tested untied. It moved M9 from four
  kills to five and M14 from eight to nine.

Declined: utility validation for `visit` and inconsistent wide-form times, the third appearance
of the standing description-budget pair.

Net: 177 tests to 179.

### Round 18 (thirteenth Test Fairness pass, 2026-08-07)

All three suggestions were the same shape: an undocumented rejection or boundary policy. Only
one half of one of them was fair to take, and it was taken: a timeline of a single point is
accepted, because "strictly increasing and non negative" is satisfied vacuously by one point,
so acceptance follows from the description. The other halves and the other two suggestions
(rejecting an empty timeline, an event code missing from `event_states`, partial `from_state`
or `to_state` selectors) all assert policies the reference has and the description does not
state.

This is the point at which the loop converged. Rounds 15 to 18 produced one, two, two and one
fair tests respectively, and every declined item now belongs to a single family: a handful of
words of description would make roughly six suggested tests fair at once. The list, in the
order it should be added if the budget is raised:

- `transition_logrank_test` and its multigroup sibling take both selectors or neither
- `transitions_from_events` rejects a non zero code missing from `event_states`
- `transitions_from_state_matrix` rejects simultaneous entries, an entry before observation,
  and a censoring time at or before it
- `state_matrix_from_transitions` rejects a `visit` other than first or last
- a supplied timeline must be non empty
- a log rank pair no group ever takes gives a zero statistic

Net: 179 tests to 180.

### Round 19 (fourteenth Test Fairness pass, 2026-08-07)

One of three taken, and it is the first genuinely new fair item in several rounds: the fitter
inherits the `alpha` invariant from `BaseFitter`, which raises on anything outside `(0, 1]` at
`lifelines/fitters/__init__.py:49`. That is repo-discoverable rather than unstated, so the
rejection of zero, of a negative and of one and a half is fair, as is the acceptance of exactly
one. Nothing in the description had to change.

The other two, malformed wide conversion input and a log rank pair no group takes, are the
standing family again.

Net: 180 tests to 182.

### Rounds 20 and 21 (fifteenth and sixteenth Test Fairness passes, 2026-08-07)

Round 20 came back FAIL on two tests that pinned the order of the rows in the all transition
log rank result. The ordering rule in the description is scoped to `MultiStateFitter`, and
`StatisticalResult` only preserves whatever order its caller passes, so both encounter order
and sorted order were defensible. Fixed on the test side at no cost to the description: the
assertions now compare the sorted names and the row counts. The three uses of the private
`_test_statistic` were removed at the same time; the separation test now keys the statistics by
name through a dictionary, so it no longer depends on order at all.

Round 20 also produced the most valuable suggestion of the whole review sequence. A supplied
timeline holding a null was **silently accepted**: every comparison against a null is false, so
neither the non negative check nor the strictly increasing check fired, and the fitter happily
reported a null indexed row. That was a real defect in the reference, not a coverage gap. The
fix is a finiteness check in the timeline validation, and the test covers the null case only;
an infinity is also rejected but is not asserted, because an infinity genuinely is non negative
and genuinely does increase, so demanding its rejection would be an unstated policy.

Round 21 added the acceptance side of the chain rule: an observed move followed at its exact
stop by an interval beginning in the state that move entered. Several fixtures rely on it, but
nothing pinned it, and it doubles as a check that the entered interval is not yet at risk at
its own start.

Net: 182 tests to 184, effective LOC 468 to 470.

### Round 22 (alignment review, 2026-08-07)

The alignment check disagreed with Test Fairness about the same three assertions. Fairness had
passed the `alpha` bounds and the `__all__` membership as repo-discoverable, citing
`BaseFitter.__init__`; alignment called them implicit constraints the description never states,
and singled out the acceptance of `alpha` exactly one as the surprise, since the usual reading
of an alpha is strictly inside the unit interval.

Alignment has the stricter bar and it is the right one here: an inherited invariant is
discoverable only if the solver thinks to look for it, and nothing in the description points
there. The three assertions were removed rather than papered over with a clause, because the
word budget forbids the clause. What survives is a purely behavioural reachability test:
`lifelines.MultiStateFitter` fits and reports its state space. The `alpha` argument is still
exercised throughout by the confidence interval tests, which pin the value and the naming for
several alphas.

Net: 185 tests to 183.

### Round 23 (coverage pass, 2026-08-07)

One of three taken: the closing endpoint of a landmark span. The `since` endpoint was covered
from several angles but `t` never was, so the test takes a span whose closing time is exactly a
transition time and asserts the move is counted, alongside a span ending just short of it where
it is not. The other two, one sided log rank selectors and an invalid `visit`, are the standing
undocumented-policy pair.

Net: 183 tests to 184.

### Round 24 (coverage pass, 2026-08-07)

Nothing taken. All three suggestions were the undocumented-policy family in full: unknown state
arguments, a backwards window, malformed converter input, an invalid `visit`, unknown event
codes, an absent transition, a group-label length mismatch, and a single-group call. The
reference rejects every one of them and the description states none of them.

That is now eleven suggestions across five passes blocked on the same thing. The complete list
of clauses that would unblock them, roughly fifty words in total:

- the log rank helpers take both selectors or neither, and a pair no group takes scores zero
- querying any method with a state the fit never saw, or with `t` below `since`, is rejected
- `transitions_from_events` rejects a non zero code missing from `event_states`, and a length
  mismatch
- `transitions_from_state_matrix` rejects simultaneous entries, an entry before observation,
  and a censoring time at or before it
- `state_matrix_from_transitions` rejects a `visit` other than first or last
- a supplied timeline must be non empty

Until the description budget is settled these stay declined, and further coverage passes will
keep returning them.

**The checks contradict each other on one of these.** A coverage pass asked for `alpha` bound
tests; they were added, citing `BaseFitter.__init__` as repo-discoverable. The alignment check
then flagged exactly those tests as implicit constraints, singling out the acceptance of
`alpha` equal to one as the surprise. They were removed. A later coverage pass asked for them
again. They stay out: alignment applies the stricter bar and is right that an inherited
invariant is discoverable only if the solver thinks to look for it. Anyone re-running these
checks should expect that oscillation rather than treat it as an unaddressed finding.

## Batch 4 (2026-08-08) — the lesson, stated plainly

Zero of nine, and the cause was my own repair. Closing the two batch-3 false positives, I added
the discriminating tests and did **not** add the description clauses that make them derivable.
That converts a false positive into a hidden requirement, which is the same defect wearing the
opposite mask, and it cost a whole batch.

The rule this build should carry forward: **a false positive is never closed by a test alone.**
Every closure needs the pair, a test that discriminates and a sentence that makes the behaviour
derivable, applied in the same edit.

The batch also exposed a third ambiguity that had been quietly costing runs since batch 2. The
interval formula read "the root of the variance over the hazard", which parses either as the
root of variance-over-hazard or as the root of the variance, divided by the hazard. Six of nine
runs took the first. It now names the spread explicitly.

## Batch 3 (2026-08-08) — solvable at 20 percent, and the false-positive gate finally ran

Ten runs, **two passing**. Solvability is settled: 20 percent sits inside the cap and well above
the floor. The clarification from batch 2 did what it was meant to; the censored-close cluster
is gone from the failure lists entirely.

The remaining failures are honest difficulty. Six of eight read the interval formula as the root
of the quantity variance-over-hazard rather than the root of the variance, over the hazard, and
five pooled the rows of a multivariate call before splitting them, so an identifier reused by two
independent groups looked like one subject with overlapping intervals. The second of those is a
description gap rather than a solver error and is now fixed: a group is a self contained set of
subjects, so two groups may reuse an identifier.

**Both passes were false positives, and closing them is the whole point of the gate.** The
adjudicator found each of them passing all 191 tests while breaking a stated rule. Neither was
luck; both exploited the same blind spot in my fixtures, which always started every subject in
the initial state at time zero. Details and the closure proof are in `eval-results.md`.

The review also found a genuine defect in the reference, which no agent could have failed on
because no test covered it: `summary.n_transitions` cast weighted totals to an integer, so a
transition carrying weight 0.5 reported 0. Removed, and pinned.

Three description items came back too. The catch-all sentence is gone, replaced by attaching the
rejection to the timeline rule where it belongs; the multivariate identifier scoping is stated;
the density note is acknowledged and partly addressed by those two removals.

## Batch 2 diagnosis (2026-08-08) — one clause, six tests, one run short of solvable

Sixteen runs, none passing, but the shape changed completely: failures per run fell from the
sixteen-to-twenty-three of batch 1 to **one to eighteen**, and the best run, Nova 1, failed a
single test.

That test was `test_a_censored_row_followed_at_the_same_instant_is_allowed`, and its cause is
visible in Nova 1's own code:

```
if row.start == previous.stop:
    if not previous.observed or not _same_state(row.from_state, previous.to_state):
        raise ValueError(...)
```

The rejection rule read "an interval opening at the instant an observed move closed another, in
a state that move did not enter". That sentence carries two jobs at once: it says *when* the
rule applies, an observed move, and *what* it then demands, the entered state. Eleven of sixteen
agents collapsed the two and rejected a censored predecessor as well, for which there is no
entered state to match.

The same misreading rejects any frame with a censored row followed by a gap, which is why five
further tests fell with it in exactly the runs that failed the first: the gap and landmark
fixtures all begin with a censored interval. Six tests, one cause.

Fixed by saying the permitted case out loud: "An interval may open where a censored one closed."
Nine words, no rule changed, the reference behaves identically. It is a fairness clarification of
the kind the playbook prescribes for a deterministic universal miss, not an easing.

Projecting the batch forward with only that cluster removed gives **1 of 16, about 6 percent**,
which is inside the band and above the solvability floor. Nova 6 would sit one test away.

The next largest cluster is the confidence interval, failing in ten of sixteen on a numeric
mismatch rather than a shape or a misreading. The formula is given in full in the description,
so that one is difficulty and was deliberately left alone.

## Batch 1 diagnosis (2026-08-08) — an unfair blocker, not a hard problem

Five runs, none passing, all `FAIL_MISSED_REQUIREMENT` with sixteen to twenty three failures.
The intersection was decisive: eleven tests failed in **all five** runs and eight of them were
`probability_of_ever_reaching`, with the other three calling it.

Reading the agents' code settled it. All of them implemented the estimator **correctly**: they
copy the increments, zero the target's outgoing row so the state absorbs, and run the product
integral. Every one then returned `float(occupation[target])`, a single number. The tests want a
series over `timeline`.

That is my defect, not theirs. The description said `probability_of_ever_reaching` "is the
occupation of `state` once every move out of it is dropped" and pinned return shapes only for
quantities reported *by state* or *by transition*. This one is a time series for a single named
state, which neither clause covers, and the plain-English reading of "the probability of ever
reaching X" is a scalar. Five out of five agents took the only reading available to them.

Fixed by naming the shape: "is a series over `timeline` holding the occupation of `state` once
every move out of it is dropped". Five words, no change to the algorithm, so this is a fairness
clarification and not an easing.

A second defect surfaced alongside it: `test_multivariate_transition_logrank_matches_...`
asserted `result.degrees_of_freedom == 2`, an attribute the description never mentions. Three of
five runs died on it. The assertion was removed; the statistic and p value comparisons stay.

The residual failures after both fixes are five to eleven per run and are all genuine. The two
that survive in the best run are the confidence interval, where the agent used an untransformed
formula instead of the stated log transform, and expected visits, where the agent summed
occupations instead of the entering increments the description names. Both rules are stated
plainly, so the problem keeps its difficulty: the best run would have gone from sixteen failures
to five, not to zero.

## Not yet run

Batch 1 ran and is now stale: the description was revised in response to it. A fresh batch is
required, and it is the only way to settle two things that remain open.

**Solvability is unproven.** Zero of five passed, but eleven of each run's failures came from
one unfair requirement that is now fixed. Projecting the best run forward it would have failed
five tests rather than sixteen, which is close but not passing. The honest position is that the
pass rate is unknown until a batch runs against the revised description.

**The false-positive gate cannot be closed yet.** It inspects passing agents, and there are
none. The pre-batch work stands (twenty mutants killed, seven divergent implementations caught,
one real escape found and fixed), but the gate itself is untouched until at least one agent
passes.
