# eval-results.md — pyriemann-geodesic-curves

## Local validation matrix

Every run below uses the image built from the submission `Dockerfile` on a clean checkout of
BASE_COMMIT, offline (`--network none`) as uid 1000.

| Check | Result |
| --- | --- |
| Vanilla suite in the image | 3590 passed / 1272 skipped / 0 failed |
| Base mode on BASE_COMMIT (test.patch only) | exit 0, 4862 testcases |
| New mode on BASE_COMMIT (test.patch only) | exit 1, 210 testcases, 210 `<failure>`, 0 `<error>` |
| New mode with solution, run 1 / 2 / 3 | 210 passed / 210 passed / 210 passed |
| Base mode with solution | 3590 passed, no regressions |
| Apply order test then solution | clean, both modes green |
| Apply order solution then test | clean, both modes green |
| Reverse apply of both patches | clean, tree identical to base |
| Patch encoding | ASCII text, LF |
| test.sh mode in test.patch | `new file mode 100755` |
| Banned markers in test names | none (`shipd`, `datacurve`, `olympus`) |
| flake8 on all new and changed Python files | clean |
| Effective LOC (`effective_loc_check.py`) | human-effective **487**, raw 1104, 4 files |

Flakiness: three consecutive runs of each mode give byte-identical counts. The new tests use fixed
seeds, no clock, no network, no ordering assumptions and no unseeded randomness.

## Mutation battery (do the tests discriminate?)

Each mutation replaces one decision in `pyriemann/geometry/curve.py` with the plausible wrong one an
agent would write, then runs the 210 new tests. Baseline before every mutation: **210 passed**.

| # | Mutation | Tests killed |
| --- | --- | --- |
| M1 | tangent-space shortcut used for the `riemann` projection too | 7 |
| M2 | arc-length parameterisation replaced by the knot index | 8 |
| M4 | simplification stops after one pass instead of recursing | 6 |
| M5 | Frechet coupling forced to the diagonal | 2 |
| M6 | `fit_curve` takes the first feasible predecessor instead of the cheapest | 2 |
| M7 | `clip=False` searches [0, 1] anyway | 1 |
| M8 | knot ties resolved to the higher segment (`side="right"`) | 1 |
| M9 | per-segment projection left unclipped inside `project_on_curve` | 1 |

Every mutation is killed. M8 initially killed nothing, which meant the stated tie-break rule had no
observable consequence: `interpolate_curve` returns the same knot either way. The rule is only visible
through `curve_tangent`, where the velocity at a knot belongs to the segment on its left, so
`test_tangent_at_a_knot_uses_the_lower_segment` was added and M8 now fails.

A first battery run was killed by a timeout part-way through and left its mutant in the source; the
second run then took its backup from the mutated file, so its numbers were measured against a dirty
baseline and its "restore" put the mutant back. The table above comes from a third run that prints the
baseline first and verifies byte equality after restoring.

## Agent runs

None yet. Nova / Orion / Vega batches to be launched on the platform.

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Reason | Approach |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — | — | — | — |

## Test Fairness re-check

First run: **FAIL**, 14 of 105 unfair. Two causes, both fixed in the artifacts rather than contested.

| Cause | Count | Fix |
| --- | --- | --- |
| `indices.tolist()` / `coupling[i].tolist()` pinned a NumPy container the description never promised | 12 | assertions now use `list(...)`, accepting ndarray, list or tuple |
| `fit_curve` bounds on `n_segments` and `epsilon` were enforced and asserted but never stated | 2 | bounds added to the description's fit paragraph |

Four of the five advisory coverage suggestions were taken (they add no requirement the description did
not already state); the two tie-forcing suggestions were skipped as brittle, since mutations M6 and M8
already pin those rules.

## Tie-break battery (second advisory round)

The four tie rules the reviewer named are all stated in the description, so testing them adds no
requirement. Exact ties were built two ways: duplicated knots, so the two candidates are scored from
byte-identical inputs, and Euclidean diagonal matrices with dyadic entries, where the residual of a
point lying on a chord is exactly 0.0.

| # | Tie rule mutated | Tests killed |
| --- | --- | --- |
| T1 | `simplify_curve` keeps the highest tied knot instead of the lowest | 1 |
| T2 | `fit_curve` takes the largest tied index instead of the smallest | 1 |
| T3a | monotone `project_on_curve` picks the highest tied final segment | 1 |
| T4 | Frechet backtrack prefers the first-curve step over the diagonal | 1 |
| T3b | monotone backtrack picks the highest tied intermediate segment | 0 |

T3b is unobservable, like the earlier M8 finding: once the final segment ties to the lowest index, the
intermediate backtrack is forced, so no returned parameter can distinguish the two readings. It is left
untested rather than pinned with a contrived fixture. The reviewer's fifth suggestion, the
diagonal-then-first-curve preference in the strict case where the diagonal is *not* minimal, is not
reachable either: the Frechet recurrence takes a max over the bottleneck, so a diagonal predecessor is
never strictly worse than its two neighbours.

## Test Fairness, second re-check

Second run: **FAIL**, 3 of 112. All three were unstated API or side conventions, so the description was
extended rather than the tests dropped.

| Flag | Fix |
| --- | --- |
| scalar `s` in `interpolate_curve` asserted to keep a batch axis | description now says it always returns a batch of one matrix per parameter |
| a single 2-D matrix in `project_on_geodesic` asserted to return shape (1,) | description now says the result is always a one-dimensional array |
| the tangent at an interior knot asserted to be the incoming one | description now says the velocity at a knot is that of the segment ending there |

The tangent test was kept deliberately: it is the only discriminator that makes the stated
lowest-numbered-segment rule observable, so dropping it would turn that rule back into
over-specification. Three further advisory suggestions were taken (monotone projection against an
exhaustive constrained optimum, `fit_curve` epsilon-mode cost minimality among fewest-segment
solutions, uniform parameterisation forwarded through length/insert/split/resample/mean). Two were
skipped with reasons: the Frechet secondary backtracking preference is unreachable because the
recurrence takes a max over the bottleneck, so a diagonal predecessor is never strictly worse than its
neighbours; and asserting that `tol` and `maxiter` are "used" would pin the search algorithm rather
than the contract.

## Test Fairness, third round

Second run: **FAIL**, 3 of 112 unfair. All three were unstated conventions rather than wrong
expectations, so the description was tightened instead of dropping the tests.

| Flag | Fix |
| --- | --- |
| scalar `s` in `interpolate_curve` was required to keep a batch axis | description now says it "always returns a batch of one matrix per parameter" |
| a single 2-D matrix in `project_on_geodesic` was required to return shape `(1,)` | description now says the result "is always a one-dimensional array holding one position per matrix" |
| the tangent at an interior knot was required to come from the incoming segment | description now says "at a knot it is the velocity of the segment ending there" |

The tangent test was kept rather than relaxed: it is the only discriminator that makes the stated
lowest-numbered-segment rule observable, so deleting it would turn that rule back into
over-specification (mutation M8 would drop to zero kills).

Three of the five new advisory suggestions were taken, each on behaviour the description already
states: an exhaustive reference proving `monotone=True` reaches the constrained optimum, an
exhaustive check that the epsilon form of `fit_curve` minimises cost among fewest-segment solutions,
and uniform-parameterisation propagation through `curve_length_between`, `insert_knot`,
`split_curve`, `resample_curve` and `mean_curve`. Two were skipped with reasons: the Frechet
secondary preference is unreachable because the bottleneck recurrence never makes a diagonal
predecessor strictly worse than its neighbours, and asserting that `tol`/`maxiter` are "used" would
pin the optimizer's internals rather than its contract.

Note on the harness, not the artifact: one validation run reported a base-mode failure that was a
scratch-directory collision with another session running a similarly named script against the same
`/tmp` path. Re-run in a PID-unique directory, base mode is green.

## Fourth advisory round

| Suggestion | Outcome |
| --- | --- |
| two-dimensional `s` should raise | **real gap, fixed in the solution.** `_locate` silently flattened a 2-D parameter array, so the description's blanket "constraints are enforced with ValueError" was untrue there. Added a rank check; `test_two_dimensional_parameters_raise` covers `interpolate_curve` and `curve_tangent`. Mutation N1 (flatten instead of raise) kills it. |
| Frechet secondary preference | **my earlier "unreachable" claim was wrong.** A brute-force search over small integer-distance curves found the case immediately: for `C1 = [4, 1, 2]` and `C2 = [2, 4, 2]` along one diagonal entry, the last cell has diagonal 3.0 against tied axial predecessors 2.0 and 2.0. `test_frechet_backtracking_prefers_the_first_curve_step` pins the whole coupling; mutation N2 (prefer the second-curve step) kills it. |
| zero length under `riemann` | **not testable, description tightened instead.** `distance_riemann(A, A)` is about 1e-8 rather than 0, so identical knots never satisfy the premise under that metric; asserting the resulting parameters would pin floating-point noise. The description now says "whose total length is exactly zero". |
| `CurveEmbedding` parameterization pipeline | taken: `test_parameterization_reaches_resampling_and_inversion` checks the option through optional resampling and `inverse_transform`, not just `transform`. |

Mutation summary after this round: N1 and N2 each kill exactly one test, and the baseline is 150 passed
with a verified byte-identical restore.

## Fifth advisory round (verdict already PASS)

All four suggestions are on behaviour the description states, so none adds a requirement. All four taken.

| Suggestion | Test added | Discriminated by |
| --- | --- | --- |
| `tol` / `maxiter` are accepted and forwarded | `test_search_controls_are_forwarded` — tightening both leaves every metric's answer unchanged, through `project_on_geodesic`, `project_on_curve`, `simplify_curve` and `fit_curve` | not mutation-checked: asserting the controls *change* the answer would be unfair, since the three flat metrics use a closed form and legitimately ignore them |
| monotone parameters may decrease inside a shared segment | `test_monotone_parameters_may_decrease_inside_a_segment` — two points on segment 0 at positions .8 and .2 keep their own closest points | P1 (force non-decreasing parameters with `np.maximum.accumulate`) kills 1 |
| labelled means then simplify then resample | `test_labels_then_simplification_then_resampling` — four label groups, epsilon and n_knots together | P2 (resample before simplify) kills 2 |
| validation breadth | the two "every routine" tests now really cover every routine: 11 routines for the metric guard, 8 for the parameterization guard | already covered by the guards themselves |

The `tol`/`maxiter` test is deliberately weak. The description says the two bound the search, not that
any particular metric iterates; pinning a visible effect would contradict the closed-form path for
euclid, logchol and logeuclid, which is exactly the over-specification the earlier rounds removed.

## Test Fairness, fourth round

**FAIL, 4 of 125 — and all four were introduced by my own previous round.** Chasing the
`tol`/`maxiter` and validation-breadth advisories, I pinned interfaces the description never assigns:

| Flag | Fix |
| --- | --- |
| `tol` / `maxiter` required on `project_on_curve`, `simplify_curve`, `fit_curve` (3 flags) | the test now exercises them only on `project_on_geodesic`, the single routine the description names, and covers both `clip` modes there |
| `curve_tangent` required to reject a 2-D parameter array | narrowed to `interpolate_curve`, the only routine the description restricts to a scalar or 1-D `s` |

The implementation keeps the extra keywords and the shared rank check; they are simply no longer
demanded of a solver. The `_locate` rank check stays covered through `interpolate_curve`, so mutation
N1 still bites.

Advisories this round: negative-criterion rejection and `CurveEmbedding` validation were added; the
Riemannian zero-length case is still not testable, since `distance_riemann(A, A)` is about 1e-8 and the
description scopes the rule to a total length of exactly zero. The embedding validation test asserts
`fit(...).transform(...)` rather than `fit(...)` alone, because fixing the moment of validation would
repeat the same over-specification: an unused metric legitimately goes unchecked until it is used.

## Sixth advisory round (verdict PASS)

Each suggestion was checked against the rule the previous round taught: act only when the description
states the behaviour **for the routine the suggestion names**. All four passed that check and were taken.

| Suggestion | Test |
| --- | --- |
| defaults | `test_defaults_are_riemann_and_arclength` — omitting `metric` and `parameterization` matches the explicit values across lengths, parameters, interpolation, both projections and `curve_distance` |
| zero-length under `riemann` | `test_interpolate_repeated_knots_returns_that_knot`, parameterized over all four metrics |
| knot validation in higher-level routines | `test_malformed_knots_raise_in_higher_level_routines` — 2-D, non-square and single-knot inputs through `project_on_curve`, `mean_curve` and `simplify_curve` |
| HPD metric breadth | `test_hpd_curve_supports_every_metric` — lengths, interpolation and self-projection on complex knots under all four metrics; no real-only operation had crept into the curve layer |

**Correction to an earlier note in this file.** I twice recorded `distance_riemann(A, A)` as "about
1e-8" and used that to argue the zero-length rule was untestable under `riemann`. Measured, it is about
3e-16, and for some seeds exactly 0.0. The conclusion for the *parameters* half stands but for a
sharper reason: the value is seed-dependent, so an all-zero assertion under `riemann` would be
flaky rather than merely wrong. The *interpolation* half needs no such premise, since every knot of a
repeated-knot curve equals the first one, and is now covered under `riemann` too.

## Seventh advisory round (verdict PASS)

| Suggestion | Outcome |
| --- | --- |
| malformed knots across the full API | taken: `test_malformed_knots_raise_in_every_routine` parameterizes 2-D, non-square and single-knot inputs over all 13 public curve routines |
| epsilon tie-breaking | **half taken.** `simplify_curve(epsilon=...)` gets an exact tie from duplicated knots; mutation T1 now kills 2 tests instead of 1. `fit_curve(epsilon=...)` is not included: its tie is broken by the same `np.argmin(candidates)` line the fixed-segment DP uses, with only a feasibility mask added, and mutation T2 already pins that line. Constructing two distinct minimal-segment cuts of bit-identical cost needs a shape where the minimal cut is not unique, and every symmetric candidate tried had a unique minimum |
| search-control behaviour | **not taken, with a concrete reason.** The reference answers `euclid`, `logchol` and `logeuclid` in closed form and ignores `tol`/`maxiter` entirely; only `riemann` iterates. Any assertion that a tiny `maxiter` degrades the answer would therefore fail against three quarters of the reference's own metric paths, and would also punish a solver whose `riemann` search converges in a fixed number of steps. The description says the two bound the search, not that any metric must iterate |
| HPD beyond core evaluation | taken: `test_hpd_curve_supports_the_whole_api` drives complex knots through `curve_tangent`, `simplify_curve`, `fit_curve`, `curve_distance` and `mean_curve`, and `test_embedding_handles_hpd_matrices` covers `CurveEmbedding` fit / transform / inverse_transform |

## Eighth advisory round — two of my earlier declines were wrong

Three of the four suggestions repeated declines I had made on reasoning alone. Tested, two of them
collapsed. Both are now covered.

| Suggestion | Outcome |
| --- | --- |
| non-divisible step resampling | taken: `test_resample_by_indivisible_step`, `step = total / 3.5`, checks the four full-step samples, the appended endpoint, and that the final gap is shorter than a step. Mutation S1 (drop the appended endpoint) kills it |
| epsilon-mode `fit_curve` tie | **decline was wrong.** I had claimed no fixture exists, having only tried shapes by hand. An exhaustive search over integer-valued curves of length 4 to 6 found ties immediately: `[1, 2, 2, 1]` at epsilon 0.5 has minimal count 2 and two zero-cost cuts, `(0,1,3)` and `(0,2,3)`. `test_fit_curve_by_epsilon_ties_take_the_smallest_indices` pins the stated rule; mutation T2 now kills 2 tests |
| zero-length `riemann` parameters | **decline was too broad.** `distance_riemann(A, A)` is about 3e-16 for a general diagonal matrix but *exactly* 0.0 when A is a scalar multiple of the identity, and for a power-of-two multiple the whitening reduces to the identity exactly in floating point, so this is structural rather than lucky. `test_parameters_of_zero_length_riemann_curve_are_all_zero` uses `4 * I` and asserts both the parameters and the interpolation at `atol=0` |
| search-control behaviour | declined a third time, unchanged reason: the reference answers `euclid`, `logchol` and `logeuclid` in closed form, so no assertion that a small `maxiter` degrades the result can hold across the metrics, and the description promises the controls bound the search rather than that any metric iterates |

⭐ The pattern across this round and the Frechet one: every claim of mine that something was
"not constructible" and was tested turned out to be constructible. Only the search-control decline has
survived scrutiny, and it survives because it rests on a measured property of the reference (three
metrics use a closed form), not on an intuition about what fixtures exist.

## Ninth advisory round — two real defects in the solution

All three suggestions were probed before deciding, and two of them exposed genuine bugs rather than
missing coverage.

| Suggestion | Outcome |
| --- | --- |
| degenerate geodesic, `A == B` | **defect.** The three flat metrics returned 0 through the closed form's zero-denominator guard, but `riemann` ran a golden section on a constant function and returned whatever the bracket collapsed to, measured as `[1.0, 0.9118]`. Every position is a minimizer, so nothing was mathematically wrong, but the answer was inconsistent across metrics and unspecified. `project_on_geodesic` now returns 0 for a degenerate geodesic, the description says so, and mutation D1 (drop the shortcut) fails 2 tests |
| step resampling under `uniform` | **defect.** `step` was converted to a fraction of arc length and then interpreted as a *uniform* parameter, so consecutive knots were not `step` apart: measured positions `[0, 2.37, 5.22, 8.56, 12.38]` against a step of 3.096. The description promised length spacing unconditionally, so the code was wrong, not the prose. Step mode now places knots by arc length whatever the parameterization, the description says so explicitly, and mutation D2 (honour the requested parameterization) fails 1 test |
| `mean_curve` size mismatch | coverage only: the behaviour was already right, raising `ValueError` when the resampled curves cannot be stacked. Test added, and the description's same-size sentence now reads "combined or compared" so it covers averaging as well as `curve_distance` |

⭐ Worth recording: the advisories have now surfaced two implementation defects, not just missing
tests. Probing each suggestion against the running code before deciding whether to take it is what
found them; reasoning about whether the case "should" work would have missed both.

## Test Fairness, fifth round

**FAIL, 1 of 139.** The defaults test asserted that `project_on_curve` behaves like `monotone=False`
when the argument is omitted, and the description only ever described what happens *with*
`monotone=True`. Stated rather than dropped: that default is load-bearing for the other projection
tests, several of which use unordered probes whose expected answers would change under a monotone
default. The description now says "`monotone` is False by default", paid for by shortening five
phrases elsewhere.

Advisories: took the two the description already covers for the routine named — count-resampling a
zero-length curve (which follows from "such a curve returns its first knot everywhere") and the
`step = 0` boundary (from "`step` strictly positive"). Declined two, for the reason round four taught:

- **single unbatched `X` for `project_on_curve`.** The "one matrix or a set" clause sits in the
  `project_on_geodesic` paragraph only. The implementation accepts it, but asserting it would pin an
  interface the description does not extend to this routine.
- **channel-size mismatch through `project_on_curve` and the estimator.** The same-size sentence is
  about curves being combined or compared, not about probes projected onto a curve. The underlying
  `distance` call raises anyway, so the behaviour is sane; it is simply not a stated contract here.

## Tenth advisory round

Two of the three were repeats I had declined on the grounds that the description did not extend the
contract to the routine named. That was the right test to apply, but the right response was to extend
the description, not to keep declining, since both behaviours are real and already implemented.

| Suggestion | Outcome |
| --- | --- |
| single unbatched `X` for `project_on_curve` | taken. The description now says "`X` is again one matrix or a set" in the projection paragraph, and `test_project_on_curve_accepts_single_matrix` asserts both returned arrays have shape (1,) |
| cross-size probes | taken. The same-size sentence was widened from "Curves are only combined or compared" to "Matrices and curves are only combined or compared", which covers probes measured against a curve. `test_projection_of_differently_sized_matrices_raises` covers both projections; measured, both already raised `ValueError` from the broadcast |
| search-control semantics | declined a fourth time, but the test was renamed from `..._are_forwarded` to `..._are_accepted`, since the reviewer is right that equality proves acceptance, not forwarding. The assertion the suggestion asks for cannot be made fairly: `euclid`, `logchol` and `logeuclid` answer in closed form and correctly ignore both controls, and a `riemann` implementation delegating to a library minimiser would also ignore `maxiter` while remaining correct. Making it testable would require the description to prescribe the search algorithm, which is a HOW the specification deliberately avoids |

Nine words were reclaimed by shortening four phrases to pay for the two additions; the description sits
at 999 words.

## Test Fairness, sixth round

**FAIL, 1 of 140** — and it finally killed the search-control test I had been defending for four rounds,
on a point I had not considered. The test compared the omitted-argument result with `tol=1e-13,
maxiter=400` at `atol=1e-5`. The description names no default accuracy, and the repository's own
iterative defaults span `tol=1e-3` in `regression.py` to `tol=1e-14` in `mean.py`, so a solver
defaulting to a loose tolerance would legitimately disagree by more than 1e-5.

The comparison is gone. What survives asserts only what the description states: with the controls
supplied, the result has one position per matrix, is finite, and lies in [0, 1] when clipped. That is
the whole of the contract for those two arguments, and it is now all the test claims.

Both advisories taken, each derivable for the routine named:

| Suggestion | Test |
| --- | --- |
| zero-length tangent | `test_tangent_of_a_zero_length_curve_vanishes` over all four metrics, plus an HPD case. A constant curve forces the stated `exp_map` identity to hold for every step, so the velocity must be the zero tangent; measured, it is under 1e-14 |
| malformed geodesic endpoints | `test_malformed_geodesic_endpoints_raise` covers non-square and 3-D `A` or `B`. This needed a contract: the description now says "`A` and `B` are square and the same size", paid for by shortening six phrases |

## Eleventh advisory round

All three stated for the routines they name, all three taken, each probed against the running code
first.

| Suggestion | Test |
| --- | --- |
| geodesic endpoints of different sizes | `test_geodesic_endpoints_of_different_sizes_raise`, both argument orders. The description gained "`A` and `B` are square and the same size" last round, so this is the half of that clause the previous tests missed: they covered non-square and batched endpoints but never two well-formed squares of different sizes |
| defaults across the full API | `test_defaults_reach_every_routine` compares omitted against explicit for `resample_curve`, `curve_tangent`, `curve_length_between`, `insert_knot`, `split_curve` and `mean_curve` on both defaults, and for `simplify_curve` and `fit_curve` on `metric` alone, since neither takes `parameterization`. `test_embedding_defaults_match_explicit_options` covers the estimator |
| exact epsilon boundary | `test_epsilon_boundary_is_strict_then_inclusive`. A Euclidean fixture puts the interior knot at projection 0.5 with deviation exactly 2.0: at `epsilon = 2.0` simplification drops it (the rule is "exceeds") while fitting accepts one segment (the rule is "within"), and at 1.9 both keep it. The two opposite comparisons are pinned by a single fixture |

## Twelfth advisory round

| Suggestion | Outcome |
| --- | --- |
| Frechet coupling step validity | taken. The structure test asserted each step is non-negative and advances at least one index, which permits an illegal jump like (0,0) to (2,0). It now also asserts no coordinate advances by more than one, which is what "advancing one or both indices at each step" means. Mutation C1 (make the edge branches step by two) fails it |
| search-control behaviour | the suggestion itself allows that this may not be testable without implementation coupling, and it is not: `euclid`, `logchol` and `logeuclid` answer in closed form and correctly ignore both controls. **But the fifth repetition made me look at the other side of the alignment.** The description said the two "bound the search" while no test asserts bounding, which is over-specification in the description, the mirror of the flag that removed the accuracy comparison two rounds ago. The sentence now reads "`tol` and `maxiter` are accepted search controls", which is exactly what the test asserts |

⭐ The lasting lesson from this thread: when the same advisory recurs and the test genuinely cannot be
written, check whether the *description* is the thing that is wrong. Bidirectional alignment has two
directions and I spent four rounds defending only one of them.
