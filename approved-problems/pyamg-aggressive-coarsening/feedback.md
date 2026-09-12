# feedback — pyamg-aggressive-coarsening

## Status

Authored and locally validated. **Solvable: 2 of 6 (33%) measured by replaying batch 2 against the
corrected suite**, inside the 40% cap. Batch 1 was 0/4 and produced four description clarifications;
batch 2 was 0/6 solely because of two unfair tests of my own, now deleted.

## Summary

pyamg coarsens with Ruge-Stuben, which halves a grid per level, so the Galerkin operators fill in
and a hierarchy grows expensive. The submission adds the aggressive-coarsening path that classical
AMG needs to coarsen harder: a long-range strength measure between the coarse points of a splitting,
a two-stage splitting built on it, multipass interpolation (the only interpolation that can reach a
fine point with no coarse neighbour), truncation, a weighted-Jacobi improvement of the prolongator,
and a coarse-operator sparsifier that lumps what it drops so the action on a chosen vector survives.
`ruge_stuben_solver` gains `CF='aggressive'`, `interpolation='multipass'`, `aggressive_levels` and
`sparsify`.

The kernel is the pass structure. It decides which fine point is settled when, which rows it may
substitute through, and therefore both the prolongator and the pass report; the same fine-only path
rule drives the long-range matrix that decides the splitting in the first place. A local fix in one
of those places moves the others.

## Repository

| item | value |
|---|---|
| repo | [pyamg/pyamg](https://github.com/pyamg/pyamg) |
| base commit | `0c021343e7dce3274f0d587fd60be2bd0ae53495` (2026-03-30) |
| license | MIT (spdx `MIT`), primary language Python |
| stars | 653 |
| open issues + PRs | 40 |
| vanilla suite | 269 passed, 1 skipped, 45s, offline, uid 1000 |

## Repo-compliance and exclusivity checks

Six-check run at pick time and again before patch generation. Canonical slug resolved first
(`gh api repos/pyamg/pyamg -q .full_name` returns `pyamg/pyamg`, no redirect).

| search | result |
|---|---|
| `gh pr list --state all --search aggressive` | none |
| `gh pr list --state all --search multipass` | none |
| `gh pr list --state all --search "extended interpolation"` | #244 MERGED, distance-1 routines only |
| `gh pr list --state all --search coarsening` | #466 OPEN adds PMISR splittings to the AIR solver; #360 pairwise |
| `gh pr list --state all --search interpolation` | #465 OPEN rewrites existing classical inner loops for speed; #450 OPEN CLAIR |
| `gh pr list --state all --search galerkin / lump / sparsif` | none |
| `gh issue list --state all --search aggressive` | #433 CLOSED, structured coarsening configuration, unrelated |
| base -> HEAD source diff | base is HEAD of the default branch |

The three open PRs were diffed. #466 touches `classical/split.py` but adds PMISR/PMISR-DDC splittings
for AIR, not a long-range measure or a two-stage splitting. #465 rewrites `amg_core/ruge_stuben.h`
kernels and touches aggregation for threaded sparse BLAS; it adds no new coarsening or interpolation.
#450 lives in `aggregation/` and `relaxation/`. None publishes the core machinery here.

## Environment

Three repos were screened and dropped before pyamg, each on the vanilla-suite gate:

- **pyroomacoustics** (MIT, 1920 stars): `tests/datasets/test_download_uncompress.py` and
  `tests/directivities/test_sofa_directivities.py` fetch over the network with no skip guard.
- **PyVRP** (MIT, 676 stars): green, but mid-workstream on shipments (PRs #1121-#1157 in weeks), an
  exclusivity minefield.
- **python-skyfield** (MIT, 1757 stars): the suite runs under `assay`, not pytest. Under bare pytest
  every test errors on a missing `ts` fixture, and a conftest adapter for assay's fixture protocol
  made the run hang. Nothing in a submission fixes that.

pyamg needed one pin. With numpy 2.5 / scipy 1.18 the vanilla
`pyamg/util/tests/test_linalg.py::TestComplexLinalg::test_condest` fails deterministically (3 of 3
runs): a seeded random matrix whose `condest` estimate drifts from the exact SVD ratio on the newer
library. `numpy<2.3` with `scipy==1.14.1` is green.

The first Dockerfile then failed the platform build while passing locally. pyamg takes its version
from SCM through versioningit, and `[tool.versioningit]` in `pyproject.toml` sets no
`default-version`, so `pip install -e .` dies with `metadata-generation-failed` on a tree that has no
`.git`. A local clone has one and the platform export does not. The Dockerfile now appends a
`default-version` before installing. Reproduced with `git archive <base> | tar -x` into an empty
directory, which fails on the old Dockerfile and passes on the new one; the whole validation matrix
was then re-run on that git-free image with `patch -p1` rather than `git apply`.

Every pip package is pinned to the exact version the build resolves (numpy 2.2.6, scipy 1.14.1,
meson 1.11.2, meson-python 0.20.0, ninja 1.13.0, pybind11 3.1.0, versioningit 3.3.0, pytest 9.0.3).
Two Dockerfile-guideline warnings are answered rather than removed. `pip install -e .` stays because
pyamg ships a pybind11 extension, `pyamg/amg_core`, so `import pyamg` needs a build, and the install
has to be **editable**: the platform injects both patches into `/app` after the image is built, and a
non-editable install would freeze a copy in site-packages that never sees them. `chmod -R a+rwX /app`
stays because the container runs as uid 1000 and the meson-python editable loader rebuilds into
`/app` on import.

## Validation

| cell | result |
|---|---|
| base after `test.patch` | 269 passed, 1 skipped |
| new on base | 233 failed of 233 (JUnit: 233 testcases, 233 failures, 0 errors) |
| base after `solution.patch` | 269 passed, 1 skipped, no regressions |
| new after `solution.patch` | 233 passed |
| apply order test-then-solution | clean |
| apply order solution-then-test | clean |
| `git apply -R` both | clean |
| determinism | new 4x identical, base 3x identical, offline as uid 1000 |
| git-free tree (platform shape) | all four cells re-verified with `patch -p1`, both orders, both reverse cleanly |
| effective LOC | `human-effective` 456 across 5 files |
| meta.md | 971 words, ASCII, 9 paragraphs, longest 125 words, no em dashes |

## Mutation proof of the discriminators

Every trap was proved by breaking the reference on purpose on a throwaway copy and confirming the
intended tests fail.

| mutation | tests killed |
|---|---|
| long-range graph built as the square of the strength pattern | 5 |
| the finished row scaled per pass instead of once | 11 |
| truncation without rescaling to the old row sum | 2 |
| the Jacobi sweep applied to coarse rows too | 2 |
| sparsification drops without lumping | 3 |
| a coarse point with no long-range neighbour not kept | 1 |
| the first hop of a long-range path allowed to land on a coarse point | **0, then 2** |

The last one is the FP that the first suite missed: an implementation that lets the first hop land on
a coarse point violates the stated fine-only path rule and still passed all 122 tests, because every
fixture happened to put a fine point on the first hop. Two fixtures close it, a chain whose points are
all coarse, and a square where the coarse route and the fine route both join the same pair. Both now
fail on the mutant and nothing else does.

## FP mapping (meta.md clause -> test)

| clause | test |
|---|---|
| a strong connection is a stored nonzero off the diagonal | `test_a_connection_outside_the_strength_pattern_is_ignored` |
| the entry counts distinct fine points on a path of length at most `degree` | `test_a_shared_fine_point_joins_two_coarse_points`, `test_the_entry_counts_distinct_fine_points`, `test_degree_three_reaches_across_two_fine_points`, `test_degree_two_does_not_reach_across_two_fine_points` |
| every intermediate point is fine | `test_a_path_through_a_coarse_point_does_not_count`, `test_a_chain_of_coarse_points_has_no_long_range_entry`, `test_a_coarse_neighbour_is_not_a_stepping_stone` |
| a fine point counts once however many paths run through it | `test_two_paths_through_one_fine_point_count_once` |
| entries below `paths` are dropped | `test_one_shared_fine_point_is_dropped_when_two_are_required`, `test_two_distinct_fine_points_are_needed_for_two_paths` |
| zero diagonal, nothing in a fine row or column | `test_the_long_range_diagonal_is_empty`, `test_fine_rows_of_the_long_range_matrix_are_empty` |
| splits, builds the long-range matrix, splits again | `test_the_result_is_a_subset_of_the_first_stage`, `test_aggressive_coarsening_keeps_fewer_points_than_ruge_stuben` |
| a point fine in the first stage stays fine | `test_a_point_fine_in_the_first_stage_stays_fine` |
| a coarse point with no long-range connection stays coarse | `test_a_coarse_point_with_no_long_range_neighbour_stays_coarse` |
| ones and zeros as `intc` | `test_the_splitting_holds_only_ones_and_zeros`, `test_the_splitting_is_returned_as_intc` |
| `method` picks the splitting routine, unknown refused | `test_pmis_can_drive_both_stages`, `test_cljp_can_drive_both_stages`, `test_an_unknown_splitting_method_is_refused` |
| coarse points settled in pass zero | `test_coarse_points_are_reached_in_pass_zero` |
| each later pass settles points with an earlier-settled strong neighbour | `test_a_neighbour_of_a_coarse_point_is_reached_first`, `test_a_later_pass_substitutes_through_an_earlier_one` |
| passes repeat until one settles nothing | `test_every_fine_point_of_a_connected_grid_is_reached` |
| zero, pass number, minus one | `test_a_point_no_pass_reaches_is_marked`, `test_the_pass_numbers_are_returned_as_intc` |
| the scaling formula, applied once after the passes | `test_a_fine_point_between_two_coarse_points_splits_evenly`, `test_a_third_pass_row_is_scaled_once`, `test_every_fine_row_of_a_zero_row_sum_matrix_sums_to_one` |
| a zero diagonal or zero row sum leaves the row unscaled | covered by the stranded-row tests |
| `lump` adds the unusable entries to that diagonal | `test_lumping_changes_a_row_the_passes_could_not_finish`, `test_lumping_leaves_a_finished_row_alone` |
| `max_passes` stops early, below one refused | `test_a_pass_limit_strands_the_far_points`, `test_a_generous_pass_limit_changes_nothing`, `test_a_pass_limit_below_one_is_refused`, `test_a_pass_limit_can_strand_a_point_under_strict` |
| a coarse row holds a single one, columns by increasing index | `test_a_coarse_row_holds_a_single_one`, `test_coarse_columns_follow_increasing_row_index`, `test_the_prolongator_has_one_column_per_coarse_point` |
| an unsettled fine point has an empty row unless `strict` | `test_a_point_no_pass_reaches_has_an_empty_row`, `test_a_stranded_point_can_be_refused`, `test_a_reached_grid_is_accepted_under_strict` |
| `theta` and `norm` recompute the pattern | `test_theta_recomputes_the_strength_pattern` |
| `trunc` and `improve` apply the two routines, in that order | `test_truncation_can_be_asked_for_while_interpolating`, `test_improvement_can_be_asked_for_while_interpolating`, `test_truncation_runs_before_the_sweep` |
| truncation keeps entries above the row threshold and keeps the row sum | `test_a_small_entry_is_dropped_by_truncation`, `test_truncation_keeps_the_row_sum`, `test_a_zero_threshold_keeps_every_entry`, `test_a_row_of_equal_entries_is_untouched` |
| a row whose kept entries sum to zero is left alone | `test_a_row_whose_kept_entries_cancel_is_left_alone`, `test_an_empty_row_survives_truncation` |
| the Jacobi sweep formula and the restored coarse rows | `test_a_sweep_gives_the_expected_row`, `test_coarse_rows_survive_a_sweep`, `test_a_sweep_changes_the_fine_rows`, `test_two_sweeps_differ_from_one`, `test_no_sweeps_leave_the_prolongator_alone` |
| a `C` filters `A` and lumps the rest onto the diagonal | `test_a_filtered_sweep_differs_from_a_plain_one`, `test_a_filtered_sweep_keeps_the_coarse_rows` |
| a zero diagonal is an error once a sweep is asked for | `test_a_zero_diagonal_cannot_be_swept` |
| sparsification keeps entries above the row threshold | `test_a_weak_entry_is_dropped_and_lumped_onto_the_diagonal`, `test_a_zero_threshold_keeps_the_operator` |
| `symmetric` keeps an entry whose transpose is kept | `test_a_transpose_partner_is_kept_when_symmetry_is_asked_for`, `test_a_transpose_partner_is_dropped_without_symmetry` |
| `protect` keeps a position whatever the threshold says | `test_a_protected_entry_survives_the_threshold` |
| lumping preserves the image of `B`, ones by default | `test_the_default_vector_of_a_sparsification_is_the_constant`, `test_sparsification_reproduces_the_image_of_the_given_vector`, `test_strong_lumping_also_reproduces_the_given_vector`, `test_sparsification_keeps_every_row_sum`, `test_strong_lumping_also_keeps_every_row_sum` |
| `strong` spreads in proportion to magnitude, `none` discards | `test_strong_lumping_spreads_over_the_kept_entries`, `test_lumping_nowhere_changes_the_row_sum` |
| the diagonal is always stored | `test_the_diagonal_is_always_stored` |
| a `B` holding a zero is refused | `test_a_vector_holding_a_zero_is_refused` |
| the solver gains the four options | `test_the_solver_accepts_aggressive_coarsening`, `test_the_solver_accepts_sparsification`, `test_aggressive_levels_limits_the_first_stage`, `test_coarsening_keywords_reach_the_splitting` |
| sparsification is applied to each Galerkin operator before it joins | `test_the_coarse_operator_is_sparsified_exactly_once`, `test_sparsification_leaves_the_finest_operator_alone` |
| every new name is exported from `pyamg.classical` | `test_multipass_is_exported_from_the_package`, `test_aggressive_coarsening_is_exported_from_the_package`, `test_sparsification_is_exported_from_the_package` |
| bad arguments raise, a non-CSR matrix raises `TypeError` | the fourteen refusal tests |

## Round 3, test-fairness review

The reviewer flagged five tests that pinned behaviour the description never states. Three were
dropped rather than documented, because each asserted a heuristic outcome that the stated rules do
not guarantee: that the long-range matrix is symmetric for a symmetric strength, that aggressive
coarsening keeps strictly fewer points than RS, and that it lowers the operator complexity. The
subset property that the second stage is contained in the first is stated and is still tested, which
is the fair part of what the dropped pair asserted.

The other two, sorted indices and no stored zeros, were kept and the description now says so:
"Every matrix returned carries sorted indices and stores no zeros." Several tests read `nnz`
directly, so leaving the storage convention unstated would have been the same fairness gap in a
quieter form.

Two stated behaviours the reviewer noticed were untested got tests: `second_pass` reaching only
`RS`, and `norm` selecting the recomputed pattern. Writing the first one exposed a flakiness
problem the earlier runs had hidden: pyamg's `PMIS` and `CLJP` draw unseeded weights through
`np.random.rand` in `_preprocess`, so `aggressive_coarsening(method='PMIS')` differs run to run. The
three tests on that path now seed the global RNG first, matching what pyamg's own
`test_linalg.py` does. The default `method='RS'` path has no RNG, which is why the earlier
determinism runs came back clean.

126 tests, unchanged in count: three out, three in.

## Round 4, Test Fairness

The gate failed at 5 of 126. Every flagged test asserts something the solution really enforces, so
the fix was four clauses in the description rather than five deleted tests: `degree` is at least two
and `paths` at least one; `interpolation_passes` returns `intc`; `omega` must be positive; and
`trunc` runs before `improve`. Nothing about the tests or the solution changed.

The five advisory coverage suggestions were all taken, ten tests. Three of them pin branches of the
scaling rule that nothing had touched: a settled row is left unscaled when the diagonal is zero and
when its unscaled entries cancel, and `lump` divides by the widened diagonal rather than the plain
one. Each was hand-derived from the description first and then matched the solution exactly, so the
formula in meta.md and the formula in the code are now checked against each other on the exceptional
branches, not only the happy path. The rest close the storage claim over every returned matrix
rather than the prolongator alone, add the empty fine columns of the long-range matrix, check that a
long-range path keeps its direction, and accept a `B` holding a zero when `lump='none'`.

One suggestion did not survive as written. A directed fixture meant to exercise the "either way"
isolation rule needed the first-stage RS splitting to land a particular way, which is not something
the description promises; the test now asserts only the directional part, and the isolation rule
keeps its existing star fixture.

136 tests.

## Round 5, Test Fairness again

The gate failed again, 4 of 136, on a class I had already met once: a test that asserts an empirical
OUTCOME rather than a stated rule. Two claimed coarse-count monotonicity under `paths` and `degree`,
one pinned a residual below 1e-8 after 100 iterations, and one pinned an ordering between two
hierarchies' level-2 sizes. None of the four is guaranteed by anything in the description, and the
previous round had removed three of exactly this shape without my checking whether the rest of the
suite still carried others. It did.

The replacements assert the same intent from the stated rules instead of from observed behaviour:
`paths=99` drops every long-range entry, so by the stated isolated-point rule the result must equal
`RS(S)` exactly, both directly and through the solver; and `aggressive_levels=0` means no level
coarsens aggressively, so the whole hierarchy must match a plain `RS` run level for level. The
convergence test is gone, since the description promises integration and not a convergence rate.

One replacement did not survive contact with the data. A fixture meant to show `degree=3` changing
the splitting where `degree=2` does not needs first-stage coarse points three edges apart, and RS on
a 1D chain always leaves them two apart, so degree never bites at the coarsening level on any of the
seven fixtures I measured. `degree` keeps its exact coverage on
`aggressive_strength_of_connection`, where the parameter is actually defined, rather than getting a
contrived graph that would invite the same fairness flag back.

The five advisory suggestions were all taken: exports for the four remaining names, stored-zero
cleanliness for the sparsifier, direct validation on `jacobi_improve_interpolation` and
`interpolation_passes` rather than only through `multipass_interpolation`, and the strong-lumping
fallback when the proportional share is zero, which needs a `B` with mixed signs to reach at all.

142 tests.

## Round 6, coverage suggestions

Test Fairness passed; four advisory suggestions remained and all four were taken, seven tests.

The one worth recording is the filtered Jacobi sweep. It had only been checked as "filtered differs
from unfiltered", so the lumping rule inside the filter was unasserted. Deriving the value by hand
from the description gives `40/79` for the two surviving weights, and the reference produced
`0.5063291139240506` against a derived `0.5063291139240506`. The third weight is analytically zero
and comes out at `1.7e-18`, so the assertion carries an `atol`; that residue is float noise, not a
stored zero, and does not contradict the storage rule.

The rest: rectangular CSR input is refused on all four entry points, which was already correct on
both aggressive paths, one through its own check and one through the check inside `RS`; a positive
`aggressive_levels` limit now asserts the exact dispatch, level 0's splitting equal to
`aggressive_coarsening` of its strength matrix and level 1's equal to `RS` of the next one, rather
than a size comparison; and sparsification is verified level by level on a hierarchy of at least
three, not only at level 1.

149 tests.

## Round 7, coverage suggestions found a bug

Three advisory suggestions, all taken, twelve tests. The complex-matrix one found a real defect.

`sparsify_coarse_operator` computed the dropped mass as `float((values * B).sum())`, which on a
complex operator discards the imaginary part and emits a `ComplexWarning`. The lumping then failed
its own central invariant: the sparsified operator did not reproduce `A @ B`. Nothing caught it
because every numerical fixture in the suite was real. Both `float()` casts are gone, and `B` keeps
its own dtype instead of being coerced to real, which would have quietly truncated a complex vector
the same way. The invariant is now asserted on a complex operator under both lumping modes, and the
suite runs clean under `-W error::ComplexWarning`. meta.md gains one clause, that a complex matrix is
carried through with every magnitude an absolute value, so the behaviour is stated rather than
assumed.

The cross-argument suggestion closed two validation gaps rather than only adding tests: a `C` whose
shape differs from `A` and a `P` whose height or width does not match `A` and the splitting were
both unchecked, so a caller got a scipy dimension error from deep inside the kernel instead of the
stated `ValueError`. Both now raise it directly.

The third was pure coverage: `theta` and `norm` are stated to drive the recomputed pattern for
`interpolation_passes` as well as `multipass_interpolation`, and only the latter was tested.

161 tests, 443 effective LOC.

## Round 8, one flag and three suggestions

Test Fairness came back at 1 of 161: `test_truncation_leaves_the_original_alone` pins non-mutation,
which nothing stated. Unlike the heuristic outcomes of earlier rounds this is a real contract, so it
took a clause rather than a deletion, and the clause is general because the property holds
everywhere. I checked that before writing it: every entry point was run against a snapshot of its
input and all seven leave it untouched, `remove_diagonal` returning a fresh matrix rather than
editing in place. Two more non-mutation tests were added so the general claim is not carried by
`truncate_interpolation` alone.

The three suggestions: a zero diagonal is accepted when `degree=0`, since the description makes it an
error only once a sweep is asked for; complex stored values act only as graph edges, so the long-range
matrix comes back real and a complex matrix coarsens exactly as its sparsity pattern does; and a `B`
holding zeros is ignored under `lump='none'` on a five-point matrix with several dropped rows, where
the result must equal the default-`B` run because nothing is put back.

One expectation had to be reframed. Asserting an exact splitting for the complex matrix pinned which
of two symmetric endpoints RS happens to pick, which the description does not determine. Comparing
the complex splitting against the real matrix with the same sparsity pattern tests the property that
matters, that values are edges, without pinning the tie-break.

168 tests.

## Round 9, one dtype co-assertion

1 of 169 flagged, and only half a test: `test_complex_connections_count_as_graph_edges` asserted both
the counted value and that the long-range matrix comes back as `float`. The value is stated; the
dtype is not, and unlike non-mutation it is not a contract worth stating. The count matrix is only
ever handed to a splitting routine that reads its pattern, so the storage dtype has no user-visible
consequence. The assertion is gone and the value assertion stays.

That is the distinction this problem kept re-teaching. A flagged assertion is worth a clause in the
description when the behaviour is one a caller can depend on and a wrong implementation would hurt
them: non-mutation, a validation bound, the order two post-steps compose. It is worth deleting when
it pins something arbitrary that no caller can observe through the stated contract: a heuristic
count comparison, a convergence threshold, the dtype of an internal count.

Both suggestions taken: non-mutation is now checked on every remaining input, `A` and `C` through
interpolation, the pass report and a filtered sweep, and `S` through coarsening; and `degree` and
`paths` bounds are exercised through `aggressive_coarsening` itself rather than only through the
strength routine it forwards to.

174 tests.

## Round 10, an ambiguity rather than a gap

Test Fairness passed; four suggestions, and the fourth was the useful one. It asked whether a
splitting holding values other than zero and one should be rejected. It is not: every routine reads
a mark as coarse when it is nonzero, so a splitting of twos behaves exactly like a splitting of ones.
Nothing said so and nothing tested it, which is the shape the authoring guide warns about, two
defensible readings that no fixture separates. A candidate that raised on a splitting of twos would
have passed the whole suite. meta.md now says any nonzero mark is a coarse point, and three tests
assert the equivalence across interpolation, the pass report, the long-range matrix and a sweep.

The optional `C` of `jacobi_improve_interpolation` was checked for CSR but not for shape, so a
mismatched one surfaced as a scipy "inconsistent shapes" error rather than the stated `ValueError`.
It now raises directly, matching the check the interpolation routines already had.

The other two were coverage: negative `theta` on the sparsifier, parallel to the truncation bound
already tested; and the splitter dispatch, which had only asserted that the result was nontrivial.
Setting `paths=99` empties the long-range matrix, so by the stated isolated-point rule the two-stage
result must equal the chosen splitter run once on `S`, which pins `PMIS` and `CLJP` exactly under a
fixed seed instead of loosely.

181 tests, 445 effective LOC.

## Round 11, the scalar-type question found a crash

Three suggestions. The first asked whether non-integral `degree`, `paths`, `improve` and
`max_passes` are rejected or coerced. Probing it turned up an inconsistency that was worse than the
ambiguity: `degree=2.5` raised a clean `ValueError`, but `degree=2.0` crashed with
`TypeError: 'float' object cannot be interpreted as an integer` from inside the layer walk, because
the validation accepts a whole number written as a float and then `range()` does not. So the API
rejected a value it had just declared valid. The counts are now coerced to `int` after validation,
and the whole-number rule is stated in meta.md with tests on both sides of it, fractional refused and
whole-number floats accepted.

The second suggestion extended non-mutation from matrices to the other inputs. Neither the splitting
nor `B` was ever written to, so the clause simply widened from "a matrix it was given" to "anything
it was given", with tests driving a splitting through all four routines and a `B` through both
lumping modes.

The third was cleanliness on the filtered sweep, which had been checked only on the unfiltered path.

192 tests, 449 effective LOC.

## Round 12, three clean confirmations

Three suggestions, all already correct, so this round only added tests.

The complex Jacobi one was worth the arithmetic. It asked for an exact complex oracle rather than a
dtype check, specifically to prove the sweep does not conjugate. A stationary fixture would not have
shown it, because the multipass row for a fine point whose strong neighbours are all coarse is
exactly the row that zeroes the residual, so no sweep moves it. Feeding a hand-made injection-style
`P` instead gives a moving row, and the derived answer `[0.5-0.5j, 0.5+0.5j]` matched the reference
exactly. A conjugating implementation would return the conjugate pair, so the assertion separates the
two.

`protect` was the last input not covered by the non-mutation clause; it is copied before use. An
unrecognised `norm` reaches pyamg's own strength routine, which already raises `ValueError`, matching
the stated error convention on both entry points that accept it.

196 tests.

## Round 13, Description Quality

Four comments, all accepted, all in meta.md; no test or solution change, and the patches were
re-checked against the worktree afterwards rather than regenerated.

The over-specification one was a real error on my part. "Bad arguments raise `ValueError`, and a
matrix that is not CSR raises `TypeError`" read as a blanket rule over everything the submission
touches, and it is false for `ruge_stuben_solver`, which converts a non-CSR operator with a warning
at `classical.py:110-114`. I had written a contract the repository already contradicts. It now scopes
to the new routines and the new solver options, which is what the suite actually asserts: twelve
`TypeError` tests, none of them through the solver, and the one solver-level error test expects
`ValueError` for an unknown sparsify method.

The other three were style. The two opening sentences of motivation are gone, so the description now
starts on the first requirement, matching the house rule about not framing the repository before the
change. The strong-connection definition folded into the sentence that uses it, taking the
off-diagonal sparsity pattern of `S` as the strong-connection graph, which keeps the contract that
the path rules depend on while dropping the separate explanatory sentence.

Losing the second opening sentence also removes a hint. It told the reader that coarsening harder
needs interpolation which can reach a fine point with no coarse neighbour, which is the pairing
between aggressive coarsening and multipass that the trap matrix counts on agents missing. Nothing
tested it and the empty rows follow from the stated pass rules, so the problem is unchanged in
fairness and slightly harder.

meta.md is 846 words, 8 paragraphs, longest 129, ASCII.

## Round 14, three gates at once, and two real defects

Solution Quality passed at 2/3 and 2/3 but named two gaps, and both were real.

`aggressive_levels` was accepted without any validation, so `-3` silently built a hierarchy while
meta.md promised `ValueError` for bad values given to the new solver options. It is validated now.
And `sparsify_coarse_operator` never dropped stored zeros, so an operator carrying an explicit zero
came back with it still stored at `theta=0`, contradicting the storage rule I had written. Zero
off-diagonal values are now skipped as each row is assembled.

That fix collided with another stated rule. The diagonal is always stored, and diagonal lumping can
drive a diagonal to exactly zero, which a blanket `eliminate_zeros()` would have deleted. Rather
than choose one rule over the other silently, the sparsifier keeps the diagonal unconditionally and
meta.md states the exception. Both branches now have tests: a stored zero is not carried through,
and a cancelled diagonal is still stored.

Test Fairness came back at 3 of 196, all three the whole-number-float tests I added last round. The
grader's point is fair: "whole numbers" fixes the value but not the accepted Python type, and
neighbouring validation in `strength.py:416-423` uses `isinstance(k, int)`. By the state-or-delete
rule these are coercion policy, not behaviour a caller depends on, so they are gone. The coercion
stays in the solution, untested, because it is what stops the `degree=2.0` crash from round 11.

The alignment warning added the `theta` interval for both threshold routines, the `norm` values, and
`protect` being a CSR matrix shaped like `A`. All three are now stated.

**An F2P violation nearly shipped.** The three new solver-validation tests passed on base, because
`CF='aggressive'` raises `ValueError` there for a completely different reason: the method does not
exist yet. `pytest.raises(ValueError)` cannot tell the two apart. Each now asserts a valid
configuration builds first, which fails on base, before asserting the bad value is refused. Caught
only by reading the F2P line rather than the exit code.

202 tests, 455 effective LOC.

## Round 15, three confirmations

All three suggestions described behaviour the solution already had, so this round added tests only.

The composed one was worth writing. It puts a protected weak entry, a nonconstant `B` and lumping in
the same call, and asserts both halves at once: without protection the row lumps `-0.1 * 3 / 1` onto
its diagonal and reads `[3.7, -2, 0, 0]`, with protection nothing is dropped and it reads
`[4, -2, -0.1, 0]`, and `out @ B` equals `A @ B` either way. Protection changing the dropped set and
the image invariant surviving that change had only been checked apart.

An out-of-range `theta` on the two interpolation routines is refused by pyamg's own strength routine,
`expected theta in [0,1]`, which is the delegated behaviour meta.md points at, and fractional
`degree` and `paths` are refused through `aggressive_coarsening` as well as through the strength
routine they forward to.

F2P was checked explicitly this round rather than inferred from the exit code: 209 of 209 fail on
base.

209 tests.

## Round 16, another unpinned reading

`protect` was the ambiguity this time. meta.md said "positions stored in `protect` are kept whatever
the threshold says", which never settles whether a protected position that `A` does not store should
have an entry created there. The implementation only ever retains entries `A` already holds, so a
protected structural zero adds nothing, and that reading also keeps the clean-storage rule intact,
since the other reading would manufacture an explicit zero. The sentence now says an entry of `A` at
a protected position is kept and no entry is created where `A` has none, with a test that a protected
structural zero leaves the result identical to the unprotected one.

The complex filtered sweep was the other one worth doing. It combines complex arithmetic with the
lumping of an entry outside `C`, which had only been exercised separately. The fixture puts a `-2j`
edge outside the pattern, so the filtered diagonal becomes `4 - 2j` and `1 / (4 - 2j)` is exactly
`0.2 + 0.1j`; the derived row `[0.4 + 0.2j, 0.4 + 0.2j, 0]` matched the reference.

The diagonal of `S` is stripped before any path walk, so storing or changing it leaves the long-range
counts alone; two tests now say so.

213 tests, meta.md 892 words.

## Round 17, two more real defects

Solution Quality passed again and named two edge cases; both were bugs.

`_multipass_rows` accumulated the skipped strong-neighbour entries in
`np.zeros(n, dtype=float)`, so on a complex operator `lump=True` truncated the imaginary part of the
lumped mass and emitted a `ComplexWarning`. The row came out `1 + 1j` where the stated formula gives
`1j`: a wrong number, not just a warning. The accumulator now follows the arithmetic dtype. This is
the third instance of the same mistake in this build, after the `float()` cast in the sparsifier and
the `dtype=float` coercion of `B`; a real-typed accumulator holding data taken from the user's matrix
is the recurring shape.

`_inside` called `eliminate_zeros()` on `protect`, so a mask that stores a position explicitly as
zero did not protect it, which contradicts "a position stored in `protect`". Every stored position now
counts, and the wording needed no change because it already said stored rather than nonzero.

Both fixes carry a regression test: the complex lumped row is pinned at `1j`, and a `protect` holding
an explicit zero keeps the entry.

215 tests, 454 effective LOC.

## Round 18, batch 1 and the solvability question

Four Nova runs, 0/4, on the 213-test artifact. That count alone is not a redesign signal, since
0 of 4 at a true 10% rate happens about two thirds of the time, but the shared-cause pattern is.
Agents landed at 208, 206, 205 and 204 of 213, and ten distinct tests account for every failure.

Four causes explain every 4/4 and 3/4 miss, and all four are description gaps rather than difficulty:

- **The tuple form.** All four agents rejected `sparsify=('lump', {'theta': 0.3})` and accepted only a
  bare method name. That single gap sinks four of the five universal failures. meta.md named `lump` as
  the method but never said a method may carry a dictionary of its own arguments, even though
  `strength` and `CF` already work that way in the repo. Inferable, but 4 of 4 did not infer it, which
  is the definition of a requirement that has to be stated.
- **A zero in `B`.** "Refused unless nothing is lumped" was read by all four as "refused only when a
  row actually drops something". The reference refuses whenever a lumping mode is selected.
- **The strong-lumping share.** "In proportion to their magnitudes weighed the same way" was read by
  three as the magnitude of the `B`-weighted entry rather than the magnitude times `B`.
- **`aggressive_levels=0`.** Two agents treated zero as falsy and coarsened aggressively everywhere.

All four are now spelled out. The solution and the tests did not change, and the patches were
re-checked against the worktree rather than regenerated: this is naming behaviour that already
exists, not easing it.

What stays is the difficulty that was landing correctly. Truncation leaving a cancelling row alone
was missed by two, multipass lumping timing by one, the widened diagonal by one. Those are stated
plainly and are the near-miss calibration the shape wants.

Expected effect: the closest agent was five failures away and four of those five were the tuple form,
so batch 2 should convert at least one run. Both batches must be rerun; meta.md changed and the
artifact also moved from 213 to 215 tests after batch 1 was taken.

## Round 19, three confirmations

All three suggestions described behaviour already present, so this round added tests only.

The `aggressive_levels` one is the useful addition after batch 1, since two agents read zero as
falsy. There was a test that zero means `RS` throughout, and one that a limit of one switches to `RS`
at level 1, but nothing said that omitting the count keeps coarsening aggressively past the first
level. It now asserts level 1's splitting equals `aggressive_coarsening` of that level's strength and
is not what `RS` would give, which pins both halves of the default.

`second_pass` reaching only `RS` now covers `CLJP` as well as `PMIS`, and the strictly-positive
`omega` rule is exercised on the negative side as well as at zero.

218 tests.

## Round 20, a wording tension the suggestion exposed

The missing-diagonal suggestion found no bug but did surface a reading conflict. A row of `A` with no
stored diagonal comes back from the sparsifier with one, holding zero when nothing was lumped into
it, which is what "the diagonal is always stored" requires. But the `protect` sentence ended "and no
entry is created where `A` has none", which a reader can take globally, and globally it is false: the
diagonal is created exactly that way. The clause now reads "protection creates no entry where `A` has
none", and the diagonal sentence says it takes a zero there when `A` stored none and nothing was put
back. Two tests pin it, one where the created diagonal is zero and one where it carries a lumped
value.

The directed-isolation suggestion asked for two halves: a first-stage coarse point with no long-range
edge either way, and one with a single directed edge. The first half is now covered on an asymmetric
strength matrix, asserting the result equals the first stage rather than pinning which point `RS`
chose. The second half is not, and deliberately: forcing a first stage that leaves exactly one
directed long-range edge means pinning `RS`'s selection on a hand-built graph, which is the same
tie-break pinning that was flagged unfair in round 5. The directional semantics are covered where
they are actually defined, on `aggressive_strength_of_connection`.

221 tests, meta.md 971 words.

## Round 21, two taken and one declined

The protect-and-symmetry interaction is now pinned. My first fixture did not discriminate: the
transpose partner was above its own row's threshold, so it survived either way. Weakening that entry
to `-0.05` isolates the composition, and the three-way assertion shows it: kept with protection and
symmetry, dropped with protection alone, dropped with symmetry alone. The order matters and is now
observable, protection marking the entry kept before symmetry looks for partners. No wording change
was needed, since composing the two stated rules already gives this.

A complex `B` has its image preserved under both lumping modes, which composes the complex clause
with the lumping clause.

**Declined: pinning `theta == 1.0` on the interpolation routines.** The probe shows it is accepted,
because the strength routine the description delegates to takes `[0, 1]` closed, while
`truncate_interpolation` and the sparsifier refuse `1.0` on the `[0, 1)` this description states for
them. Those are different parameters, so the artifact is self-consistent, but the repository is
ambiguous at that exact point: the docstring the delegation points at says `[0, 1)` while the code
accepts `1.0`. A test asserting acceptance would fail any agent who implemented the documented range,
and a test asserting refusal would contradict the reference. The boundary stays unpinned; `1.5` and
`-0.5` are refused under either reading and are tested.

Also declined: asserting that a two-dimensional `B` which flattens to the right length is accepted.
It is, through `ravel`, but that leniency is not stated and pinning it would be the same mistake.
The wrong-length rejection is what the description supports and it is already covered.

223 tests.

## Round 22, both taken, and one reversal

Two gaps, both closed in the solution.

`jacobi_improve_interpolation` never checked that `A` is square. A rectangular `A` with a conforming
`P` reached `A @ P` and surfaced scipy's bare "dimension mismatch", which is a `ValueError` but not
one this code raised, and every sibling routine checks squareness up front. It does now.

The `B` shape question came back from the opposite direction to last round, and the second grader is
right. Last round I declined to pin that a two-dimensional `B` flattening to the right length is
accepted, on the grounds that the leniency was unstated. The better fix is to remove the leniency:
the description says a vector and the formula needs one scalar per point, so `ravel` was quietly
accepting shapes the contract never promised. `B` must now be one-dimensional, meta.md says one entry
per point, and both a row-shaped and a column-shaped `B` are refused. That resolves the question the
same way whichever direction it is asked from, which the previous answer did not.

226 tests, 456 effective LOC.

## Round 23, the suggestion exposed three vacuous tests

Chasing the second suggestion turned up something worse than the gap it named. Probing which `theta`
actually makes the sparsifier bite showed that on a plain Ruge-Stuben hierarchy nothing is dropped at
`0.3` or `0.5`; the coarse operators only lose entries from about `0.6`. Three solver integration
tests were pitched below that line:

- `the_coarse_operator_is_sparsified_exactly_once`, grid 15 at `0.3`
- `every_galerkin_operator_is_sparsified_once`, grid 24 at `0.3`
- `sparsification_leaves_the_finest_operator_alone`, grid 15 at `0.5`

Each compared the level against `sparsify(galerkin, theta)`, and with nothing dropped both sides were
the Galerkin operator itself. **A solver that never sparsified at all would have passed all three.**
They now run at `0.6` and each asserts the coarse operator actually lost entries, so a no-op fails
them. The aggressive-coarsening path was never affected: it drops at `0.3` already, 380 nonzeros to
240.

Both named suggestions are also in. `second_pass` reaching the second-stage split is isolated on grid
15, where `RS` gives the same first stage with and without it, so the change in the final splitting
can only come from the second call; that discriminates against forwarding to stage one alone without
restating the algorithm. The solver now also passes `lump='strong'` through the method dictionary and
the level is checked against the strong-lumped reference and against the diagonal-lumped one, so a
solver that plucked only `theta` out of the dictionary would fail.

228 tests.

## Round 29, measuring beat guessing

All three taken, including the two I had declined in earlier rounds. The declines were wrong, and the
reason they were wrong is that I reasoned about the risk instead of measuring it.

I had refused `csr_matrix` fixtures and a `theta=1.0` case on the grounds that an agent following a
reasonable convention, `isinstance(x, csr_array)` or the `[0, 1)` in the delegated docstring, would
be failed by them. That was a guess. Writing the three candidates into a scratch file and running
them against the reference and both passing agent patches showed all three pass everywhere. The
solvability cost I was protecting against does not exist.

There was also an argument for adding them that I had missed. meta.md states all three, that either
CSR container is accepted, that the interpolation `theta` range is inclusive, and that any nonzero
mark is coarse, and nothing tested any of them. Described but unasserted is its own failure, so the
choice was never "add or leave alone", it was "add a test or delete the claim".

The negative-mark case is the one with a plausible wrong implementation behind it: `splitting > 0`
reads `-1` as fine while `astype(bool)` and `!= 0` read it as coarse. Only the positive value `2` had
been exercised.

The lesson generalises past this problem: when a suggestion looks like it might cost solvability,
the cost is measurable in about a minute with a scratch file and the stored patches. Measure it.
A decline that turns out to be wrong is as expensive as a bad addition, and here it left three stated
contracts unasserted for four rounds.

Replayed after adding: both Orion runs pass 231 of 231, Nova_1 fails six. Still 2 of 6.

231 tests.

## Round 30, both taken

Both suggestions name a form the description explicitly allows and nothing exercised: `sparsify`
given as a bare method name rather than a tuple, and a zero in `B` under `lump='strong'` rather than
the default diagonal mode.

Measured first, per the previous round. Both candidates pass on the reference and on both passing
agent patches, so neither costs solvability. The shorthand test was also checked for the vacuity that
caught three integration tests in round 23: on the aggressive hierarchy the default `theta` of `0.1`
does drop entries, 380 nonzeros to 360, so the test asserts both that the level lost entries and that
it equals a defaulted `sparsify_coarse_operator` call. A solver that ignored the shorthand would fail
it.

The `strong` zero-`B` case matters because the rule is stated per mode rather than per outcome, and
until now only `diagonal` was exercised on the refusing side and `none` on the permitting side. The
middle mode was the gap.

Replayed after adding: both Orion runs pass 233 of 233. Still 2 of 6.

233 tests.

## Round 24, batch 2, and the test that broke solvability

Six runs, 0/6 on the raw count, but both Orion runs sat at 226 of 228 and failed **only** the two
`B`-shape tests added the round before. Nothing else in the suite failed for them. Batch 1's four
clarifications had worked; none of those failures came back.

Those two tests were wrong. Round 21 I declined to pin `B`'s shape leniency because it was unstated.
Round 22 a suggestion asked for the opposite and I reversed, tightened the reference to reject any
array that is not one-dimensional, and wrote tests for it. Orion's code raises
"B must hold one entry per point", which is nearly the description's own words, and then reshapes.
A row or column shaped array does hold one entry per point. Six of six agents read it that way. I had
pinned the minority reading of my own sentence, and it was the only thing keeping the problem
unsolvable.

Both tests are gone and the reference is back to `ravel`, which is what it was before round 22 and
what every agent wrote. Replaying all six patches against the corrected suite, one container each:
both Orion runs pass 226 of 226, the four Nova runs land at 221, 221, 218, 218. **2 of 6, 33%.**

The wider lesson is about the coverage rounds themselves. Every test added in response to an advisory
suggestion raises the bar, because passing means passing all of them, and this suite grew from 213 to
228 across eight such rounds. Most of those additions were worth it, several found real defects, but
the two that were not worth it were enough to take the pass rate to zero. Advisory suggestions
should be filtered on whether they close a genuine hole, not taken as a checklist.

226 tests.

## Round 25, four interface clarifications

A warning, not a failure, and description-only, so unlike a new test these can only help an agent.
Three were taken as asked and one was corrected before writing.

The grader asked me to state `[0, 1)` as the range for the `theta` that recomputes the strength
pattern. That is false. The strength routine the description delegates to accepts `1.0`, its own
message reading "expected theta in [0,1]", while `truncate_interpolation` and the sparsifier refuse
`1.0` on the `[0, 1)` this description already states for them. Two different parameters, two
different ranges. meta.md now says `[0, 1]` for the interpolation `theta`, which is what the
reference does; writing `[0, 1)` would have described behaviour the reference does not have.

The rest are true and tested: every matrix argument may be a CSR array or a CSR matrix, since the
check is on the format rather than the class and both were verified; `A` and `S` are square; a `C`
matches the shape of the `A` beside it; a `P` has a row per point and a column per coarse point; and
`aggressive_levels` joins the list of whole numbers and is never negative.

## Round 26, the 1000-word cap

meta.md was 1026 and the cap is 1000. Every sentence carries a tested contract, so the cut had to be
lexical rather than substantive: eleven rewordings, none of which removes a claim. "counts the
distinct fine points ... a fine point counting once however many such paths run through it" became
"each counting once however many such paths use it"; "the share it is divided by" became "the share
they divide by"; "whether or not that row drops anything" became "even if that row drops nothing".

992 words, longest paragraph 139, ASCII. Verified by extracting every backticked identifier from
both versions, none lost and none added, and by checking each contract phrase survives, including
the protect clause that had already been reworded once. No test, solution or patch changed.

## Round 27, one flag and the filter in use

The zero-`B` clause read "refused whenever `lump` puts anything back, even if that row drops
nothing", which contradicts itself: the first half conditions on lumping actually acting, the second
half says it does not. The reference refuses whenever a lumping mode is selected, so the clause now
names the mode instead of the action, "whenever `lump` is anything but `none`, even where nothing is
dropped". Wording only; no test or code changed.

Two of the three suggestions were declined, which is the filter from round 24 rather than reluctance.
Positive `csr_matrix` fixtures and a `theta=1.0` case would each add a test without a defect behind
it, and both touch places where an agent following a reasonable convention would now fail: an
`isinstance(x, csr_array)` check, or the `[0, 1)` written in the docstring the delegation points at
while the code accepts `1.0`. meta.md states both contracts; that is enough.

The third was taken because a wrong implementation is plausible. Building the retained set as a
pattern union of the threshold and its transpose, then materialising it, would invent entries `A`
never stored, and nothing tested that. It cannot now.

Every agent patch was replayed against the new suite before believing solvability held: both Orion
runs still pass at 227 of 227, Nova_1 and Nova_4 still fail five. Still 2 of 6.

227 tests.

## Round 28, one taken, two declined, one of them permanently

Non-mutation of `A` on the unfiltered sweep was the gap worth closing. The filtered path checks `A`
and `C` together and another test checks `P`, but the ordinary sweep never asserted that `A` survives,
and scaling a matrix by its inverse diagonal in place is a natural enough optimisation to be worth
ruling out. Two sweeps with different weights now run against a snapshot.

Declined: asserting the returned container is CSR. There is no defect behind it and the container is
already pinned indirectly, since the suite reads `has_sorted_indices`, `indices` and `indptr` and
compares dense values throughout; anything but CSR fails those already.

Declined permanently: rejecting a two-dimensional `B` whose total length matches. **That is the exact
requirement that took batch 2 to 0 of 6.** Six of six agents accepted the flattening reading, one of
them with an error message almost identical to the description's own words, and the reference now
accepts it too. A test asserting rejection would contradict the reference and re-break solvability.
This suggestion has now arrived three times from three different directions; the answer does not
change.

Replayed both passers against the new suite before finalising: 228 of 228 each. Still 2 of 6.

228 tests.

## Round 29, measuring beat guessing

All three taken, including the two I had declined in earlier rounds. The declines were wrong, and the
reason they were wrong is that I reasoned about the risk instead of measuring it.

I had refused `csr_matrix` fixtures and a `theta=1.0` case on the grounds that an agent following a
reasonable convention, `isinstance(x, csr_array)` or the `[0, 1)` in the delegated docstring, would
be failed by them. That was a guess. Writing the three candidates into a scratch file and running
them against the reference and both passing agent patches showed all three pass everywhere. The
solvability cost I was protecting against does not exist.

There was also an argument for adding them that I had missed. meta.md states all three, that either
CSR container is accepted, that the interpolation `theta` range is inclusive, and that any nonzero
mark is coarse, and nothing tested any of them. Described but unasserted is its own failure, so the
choice was never "add or leave alone", it was "add a test or delete the claim".

The negative-mark case is the one with a plausible wrong implementation behind it: `splitting > 0`
reads `-1` as fine while `astype(bool)` and `!= 0` read it as coarse. Only the positive value `2` had
been exercised.

The lesson generalises past this problem: when a suggestion looks like it might cost solvability,
the cost is measurable in about a minute with a scratch file and the stored patches. Measure it.
A decline that turns out to be wrong is as expensive as a bad addition, and here it left three stated
contracts unasserted for four rounds.

Replayed after adding: both Orion runs pass 231 of 231, Nova_1 fails six. Still 2 of 6.

231 tests.

## Round 30, both taken

Both suggestions name a form the description explicitly allows and nothing exercised: `sparsify`
given as a bare method name rather than a tuple, and a zero in `B` under `lump='strong'` rather than
the default diagonal mode.

Measured first, per the previous round. Both candidates pass on the reference and on both passing
agent patches, so neither costs solvability. The shorthand test was also checked for the vacuity that
caught three integration tests in round 23: on the aggressive hierarchy the default `theta` of `0.1`
does drop entries, 380 nonzeros to 360, so the test asserts both that the level lost entries and that
it equals a defaulted `sparsify_coarse_operator` call. A solver that ignored the shorthand would fail
it.

The `strong` zero-`B` case matters because the rule is stated per mode rather than per outcome, and
until now only `diagonal` was exercised on the refusing side and `none` on the permitting side. The
middle mode was the gap.

Replayed after adding: both Orion runs pass 233 of 233. Still 2 of 6.

233 tests.

**Round 1 (pick).** Four repos screened; three dropped on the environment gate or on velocity, as
recorded above. pyamg confirmed green after the numpy/scipy pin, and the feature confirmed absent by
a repo-wide search for `aggressive`, `multipass` and `distance.two` (only `amg_core/air.h` mentions
distance-two, for the AIR restriction).

**Round 2 (authoring).** Built the long-range measure, the two-stage splitting, the pass kernel,
truncation, the Jacobi improvement, the sparsifier and the solver wiring.

**Fixes found while building.**

- The first prolongator carried int64 index arrays after a Jacobi sweep, and the next level's
  `classical_strength_of_connection` binding takes int32, so a hierarchy with `improve` set died
  inside pybind11 rather than in our code. Index dtypes are now matched to the operator.
- The first `_filter_operator` wrote the lumped diagonal through a LIL matrix and raised a numpy
  deprecation warning on every row. Adding a diagonal matrix does the same thing quietly.
- Two tests asserted behaviour the algorithm does not have. An isolated point is fine after RS, not
  coarse, so the "no long-range neighbour" rule needed a star fixture where the centre really is
  coarse; and a uniform chain truncates to nothing at any threshold, so the truncation test needed
  unequal weights.
- The suite reached 122 tests before the mutation battery showed the fine-only path rule was
  unasserted. It is 126 now.

## Why this is not a duplicate

No pyamg problem exists in `Aprroved/`, `rejected/`, `problems/` or any `Task*/` folder. The closest
approved work by subject is `scikit-fem-hanging-nodes`, which eliminates constraints on a finite
element mesh: a different repo, a different subsystem, and a constraint-elimination kernel rather
than a coarse-grid selection and interpolation kernel. `pysmt-bit-blasting` and
`python-control-analysis-points` share nothing beyond being Python numerics.

## Assumptions logged

- Tier Olympus, category feature-request. No tier change.
- `aggressive_levels` is only consulted when `CF` names aggressive coarsening; it is ignored, not
  refused, with another method, matching how `ruge_stuben_solver` treats method-specific keywords.
- The scaling denominator uses the sum of all off-diagonal entries of the row of `A`, not only the
  strong ones, which reproduces the classical result for a matrix with zero row sums. Stated in
  meta.md so the choice is not codebase-inferable.
