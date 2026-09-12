# DESIGN.md — lifelines-multi-state-models

## 1. Title

Add multi state models to the non-parametric fitters.

Verb-led, names the subsystem (`lifelines/fitters`, the non-parametric family that today
holds Kaplan-Meier, Nelson-Aalen and Aalen-Johansen).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`SHAPES.md` Pattern 12). One estimator kernel whose
  correctness is subtle, feeding several reporting surfaces; a near-miss implementation
  produces plausible but wrong numbers rather than a crash.
- Pass rate target: <= 40% cap, designed for the corpus mode of about 1 in 10.
- Best agent: mixed. The engine is short but the conventions are many.
- Dominant verdict expected: MISSED_REQUIREMENT, with WRONG_LOGIC on the product integral.

## 3. Public API surface

`lifelines.MultiStateFitter(alpha=0.05, label=None)`

- `fit(transitions, initial_state=None, timeline=None, label=None) -> MultiStateFitter`
- `states_` — every state seen, ascending
- `transitions_` — ordered pairs an observed move took, ascending
- `absorbing_states_` — states no interval ever begins in, ascending
- `timeline` — zero then the transition times, or the caller's own
- `initial_distribution_` — Series over states, the weight share at time zero
- `state_occupation_` — DataFrame, timeline by state
- `cumulative_hazard_` — DataFrame, timeline by transition
- `variance_` — DataFrame, same shape
- `confidence_interval_cumulative_hazard_` — DataFrame, two columns per transition
- `at_risk_` — DataFrame, transition times by state
- `transition_counts_` — DataFrame, transition times by transition
- `summary` — DataFrame with `n_transitions` and `cumulative_hazard`
- `transition_matrix(t, since=0.0, markov=True) -> DataFrame`
- `state_occupation_at(t) -> Series`
- `predict(times) -> DataFrame`
- `expected_length_of_stay(t, from_state=None, since=0.0) -> Series`
- `expected_number_of_visits(t, from_state=None) -> Series`
- `probability_of_ever_reaching(state, from_state=None) -> Series`
- `sojourn_survival(state) -> Series`
- `median_sojourn_time(state) -> float`
- `mean_sojourn_time(state, t) -> float`

`lifelines.utils`

- `transitions_from_events(durations, event_observed, initial_state, event_states=None, entry=None) -> DataFrame`
- `transitions_from_state_matrix(df, id_col, censoring_col, initial_state, entry_col=None) -> DataFrame`
- `state_matrix_from_transitions(df, initial_state, censoring_col="censoring_time", visit="first") -> DataFrame`

`lifelines.statistics`

- `transition_logrank_test(transitions_A, transitions_B, from_state=None, to_state=None, t_0=-1) -> StatisticalResult`
- `multivariate_transition_logrank_test(transitions, groups, from_state=None, to_state=None, t_0=-1) -> StatisticalResult`

## 4. Canonical output form

- States, transitions and absorbing states are all sorted ascending.
- Transition columns are named `"<from>-><to>"`; interval columns append `_lower_<1-alpha>`
  and `_upper_<1-alpha>`, lower before upper, transitions in order.
- `timeline` is zero followed by the distinct stops of observed rows, ascending. Censoring
  times never enter it.
- `at_risk_` and `transition_counts_` are indexed by the transition times alone.
- A row of the interval is zero wherever the hazard is zero.
- A landmark row for a state nobody occupied is null; over a span with no move it is the
  identity row.
- `median_sojourn_time` is infinity when the estimate never reaches a half.
- Reported frames evaluate their step function at the requested timeline; the integrals and
  the summary do not depend on it.

## 5. Blind-spot pre-empts

| Blind spot | Sentence in the description |
| --- | --- |
| Boundary of a half open interval | "A row covers the span after `start` up to and including `stop`, which is also when it puts its subject in the risk set of `from_state`." |
| Iteration order and side of a matrix product | "taken in increasing time order with each new factor applied on the right" |
| Which end of a step a piecewise integral uses | "integrates the occupation, which holds from each transition time to the next" |
| Sort order | "each ascending", "subjects and states ascending" |
| Result ordering of a reporting frame | "`at_risk_` and `transition_counts_` are indexed by the transition times alone" |
| Falsy on an undefined case | "A row nobody occupied is null" |
| A convenience surface leaking the wrong quantity | "`probability_of_ever_reaching` is the occupation of `state` once every move out of it is dropped" |
| Two readings of one word | "`absorbing_states_` those no interval ever begins in" |

Codebase-inferable requirements: **one** — that the interval formula and its column naming
follow the shape `NelsonAalenFitter` already uses. The description states the formula and the
naming anyway, so an agent that never opens that file still has enough.

## 6. Description draft

See `meta.md`. Dense prose, no headers, no lists, ASCII only.

## 7. File footprint

| Action | Path | Raw delta | Human effective |
| --- | --- | --- | --- |
| NEW | lifelines/fitters/multi_state_fitter.py | 423 | 213 |
| NEW | lifelines/utils/multi_state.py | 373 | 198 |
| MODIFY | lifelines/statistics.py | 143 | 48 |
| MODIFY | lifelines/utils/__init__.py | 8 | 7 |
| MODIFY | lifelines/__init__.py | 2 | 2 |

TOTAL: 949 raw / **468 human effective** across 5 files. Clears the 450 design floor and the
400 platform auto-block with margin.

## 8. Solution outline

Pure helpers in `lifelines/utils/multi_state.py`, one per rule the description names:

- `check_transitions_frame(transitions)` — validation and normalization
- `state_space(df)` — states, transitions, absorbing states
- `transition_times(df)` — the distinct observed stops
- `risk_and_transition_counts(df, states, times)` — weighted risk sets and weighted counts
- `hazard_increments(at_risk, counts)` — the Nelson-Aalen increment matrices
- `product_integral(increments)` — the running matrix product
- `occupants_at(df, time)` — who is in which state at a landmark time
- `sojourn_durations(df, state)` — stay lengths, their censoring and their weights
- `transitions_from_events`, `transitions_from_state_matrix`, `state_matrix_from_transitions`

The fitter composes them and adds the reporting surfaces. There is no fixpoint loop; the
iterative core is the product integral, written as an explicit forward loop because the order
and the side of the multiplication are the point.

## 9. Test file outline

`lifelines/tests/test_state_transition_models_2ca149.py`, four blocks: imports, seven fixture
builders, one assertion helper, then 156 granular tests grouped by requirement.

Coverage axes, all met: every described behaviour, every public name, every branch of the
solution, the standard edges (empty frame, single subject, tied times, a state with an empty
risk set, a gap in observation, delayed entry, a revisited state, a span with no move), and
the stated inverses (the two converters, and the chaining identity of the transition matrix).

## 10. Forced signatures

Every new signature, default and return shape is pinned in the description, because the
approved corpus records that a statically guessable signature produces fake difficulty. The
Python analogue is the method-versus-property and frame-versus-series coin flip, which the
description settles for each name.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt | Catching test |
| --- | --- | --- | --- | --- |
| 1 | Product integral multiplied on the wrong side | Both sides look symmetric and agree for competing risks, where only one transient state exists. It only diverges once two transient states chain, and then the failure surfaces in the occupation, not in the matrix the agent was writing. | "each new factor applied on the right" | `test_transition_matrix_chains_across_a_split_of_the_span`, `test_state_occupation_of_the_reversible_model` (mutation M1 kills 20) |
| 2 | Risk set built from a subject's state timeline rather than from the intervals | The natural model is "where is each subject now", which silently keeps a subject at risk inside a gap and puts it at risk at the instant it arrives. | "the span after `start` up to and including `stop`", "a subject outside its rows is in no risk set at all" | `test_at_risk_ignores_a_subject_inside_a_gap_in_its_observation`, `test_a_delayed_entry_is_not_at_risk_at_its_entry_instant` (M2 and M3) |
| 3 | Integrals following the reported timeline | Once `timeline` exists, reusing the reported frame is the obvious implementation, and it is right whenever the caller does not pass one. | "a supplied timeline never changes any quantity below" | `test_a_supplied_timeline_leaves_the_integrals_alone` (M18) |
| 4 | Ever-reaching reported as the occupation | They coincide until a state is left and re-entered, which is exactly the case competing-risks intuition never sees. | "the occupation of `state` once every move out of it is dropped" | `test_probability_of_ever_reaching_is_not_the_occupation` (M7) |

These interact: trap 2 changes the increments, which changes trap 1's product, which changes
trap 3's integral. A local fix to any one of them leaves the others wrong.

## 12. Tier and category

- Tier: Olympus
- Category: feature-request (a net-new public fitter, two new statistics functions and three
  new utilities)

## 13. Predicted pass rate

10% to 25%. The estimator itself is textbook, so a strong agent will reach the right family
quickly; what holds the rate down is the number of exactly pinned conventions, each of which
is independently missable, and the four interdependent traps above. The design deliberately
does not rely on the algorithm being unknown.

## 14. Quality gate

- [x] Repo understanding: five subsystems named (`fitters`, `utils`, `statistics`,
      `plotting`, `datasets`); tests live in `lifelines/tests`; `test_statistics.py` is the
      formatting template.
- [x] Existing PR check: no PR or issue implements a multi state model (searches logged in
      `feedback.md`). Issue #674 asks for one and carries no specification.
- [x] Closest approved problems opened: `python-control-analysis-points` (dense prose over a
      large API) and `petl-incremental-refresh` (a missing compositional layer over a mature
      single-object library).
- [x] Corpus recipe: one interdependent kernel driving eight surfaces; four internal oracles
      fuzz-free and exact; four interdependent, misdirecting traps; every signature pinned;
      the repo is not the author-obvious host for a tooling category.
- [x] LOC: 457 human effective over 5 files.
- [x] Canonical output form spelled out.
- [x] <= 1 codebase-inferable requirement.
- [x] Traps each have a pre-empt sentence and a catching test.
- [x] Not pattern-followable: no existing fitter takes an interval frame or estimates a
      matrix-valued quantity.

## Why this is not a duplicate

Closest approved siblings:

- `petl-incremental-refresh` shares the shape "add the missing compositional layer over a
  mature library", but its subject is dataflow invalidation over table expressions, its
  kernel is a per-transform delta fold, and it touches no estimator.
- `python-control-analysis-points` shares the dense-prose-over-a-large-API description style
  and nothing else: its domain is loop-breaking in interconnected LTI systems.
- No approved or in-flight problem touches survival analysis, lifelines, or a counting
  process estimator. The repo has never been used here.

Predicted iteration cycles: 2.
