# feedback.md — lyon-arcs-join

## Summary

Adds `LineJoin::Arcs` to lyon's stroke tessellator: a curvature-following join whose
surface follows the circular arc implied by the join point and its two neighboring
centerline points, falling back to `Bevel` when the three points are collinear or
when the join would exceed the same `miter_limit` threshold `Miter` already respects.
Wired into both the fixed-width and variable-width stroking dispatch paths (two
genuinely separate functions in `stroke.rs`), rendering an actual multi-vertex arc
fan (not a single repositioned vertex) by reusing the crate's existing recursive
`tessellate_arc` subdivision machinery. Also exposes three standalone public
functions (`compute_arcs_join`, `arcs_join_side_is_convex`, `compute_arcs_join_polyline`)
that let callers preview or hit-test the same geometry without a full tessellation
pass, each parameterized by which side of the turn to query.

## Attempt history

- **v1**: implemented as a single extrapolated vertex on the front side only
  (fixed-width dispatch). Discovered during testing that the distance-based
  fallback trigger was mathematically dead (the join point always lies exactly on
  the circumcircle by construction, so "distance from join to the arc point" is
  always exactly `half_width` regardless of curvature — the trigger could never
  fire for any `miter_limit >= 1`). Fixed by reusing the existing
  `miter_limit_is_exceeded` helper (the same one `Miter`/`MiterClip` use) instead
  of inventing a new distance metric.
- **v1 also had a second latent bug**: the fallback path reused `get_clip_intersections`
  (MiterClip's clip geometry), contradicting the description's "falls back to a
  plain Bevel corner" claim. Fixed by letting the fallback do nothing, matching how
  `Bevel` itself is handled (no explicit branch, relies on the base offset triangle).
- **v2**: solution.patch landed at ~113 meaningful LOC — under the current sprint's
  effective-LOC floor. Rather than pad, expanded genuine scope in three real
  directions, each mutation-tested:
  1. Wired the same geometry into the variable-line-width dispatch path
     (`compute_join_side_positions`), a second, architecturally separate function.
  2. Redesigned the join from a single extrapolated vertex into an actual
     multi-vertex arc fan, reusing the crate's existing `tessellate_arc` recursive
     subdivision (the same machinery `Round` uses), which is a more faithful
     "arc" join and required a new `SidePoints::arcs_peak` field plus a new
     `tessellate_arcs_join` dispatch function.
  3. Added three public predictor functions with a genuine dual-path consistency
     trap between them and the internal tessellator (verified by finding, during
     testing, that a naive "always use the positive side" implementation
     computes the CONCAVE side's geometry for left turns — a real, non-obvious
     side-convention bug now caught by `compute_arcs_join_matches_tessellated_vertex`
     and its negative-side counterpart).
  Final: 318 raw / 201 meaningful solution LOC, 33 new tests, 0 regressions.

## Fix tracking

| Issue found | Root cause | Fix |
|---|---|---|
| Distance-based fallback trigger never fired | Join point is provably always exactly `half_width` from its own arc point (algebraic identity), not curvature-dependent | Reuse `miter_limit_is_exceeded(normal, miter_limit)`, the same check `Miter` uses |
| Fallback used MiterClip geometry, not Bevel | Copy-pasted `get_clip_intersections` call from the MiterClip branch | Do nothing on fallback (matches how `Bevel` itself has no explicit branch) |
| `num_recursions == 0` sub-arc calls silently drew nothing | Splitting one full sweep into two half-sweeps, each independently re-evaluated against the tolerance-driven subdivision formula, can both round down to 0 even when the original full sweep would have gotten >= 1 | Floor each half's subdivision count at 1 so the peak vertex is always actually connected |
| `compute_arcs_join`'s "positive side" computed the concave side's geometry for a left-turning corner | `compute_normal`'s "positive side" convention does not track which side is convex; that depends on turn direction | Added `arcs_join_side_is_convex` to make this explicit and testable; generalized all 3 predictor functions with a `positive_side` parameter so either side is directly queryable |

## Mutation-proofing (traps confirmed real + orthogonal)

Ran 7 targeted mutants against the full 33-test suite; each failed a disjoint,
predictable subset:

1. Skip the `miter_limit_is_exceeded` guard entirely → fails only the two
   miter-limit-trigger tests + the composed-independence test.
2. Revert the fallback to `get_clip_intersections` (the v1 bug) → 0 test failures
   at the collinear trigger (geometrically indistinguishable from true Bevel at
   exact collinearity — documented as an inherent, not a fairness, limitation).
3. Remove the Arcs branch from the variable-width dispatch site entirely → fails
   only the 3 variable-width-specific tests that exercise real geometry.
4. Remove the Arcs branch from the fixed-width dispatch site entirely (no-op
   baseline) → fails exactly the 4 "differs from X" differentiation tests.
5. Flip the sign in the standalone predictor's normal computation → fails exactly
   the tessellator-consistency test.
6. **(added 2026-07-29, oracle-risk audit)** Use the variable-width site's unsigned
   `compute_normal(v0, v1)` instead of the already-signed local `normal` → fails
   the same 3 variable-width tests as mutant 3 (same failure signature, distinct
   root cause: a plausible "looks right" sign mistake, not a missing branch).
7. **(added 2026-07-29, oracle-risk audit)** Copy `tessellate_round_join`'s literal
   subdivision-count formula (no per-half floor) onto the two independently
   computed sub-spans either side of the curvature peak → fails 4 tests including
   `arcs_differs_from_bevel` and `same_join_within_generous_limit_uses_arc_not_bevel`.
   This is the load-bearing result: `tessellate_round_join` sits in the same file
   as an obvious template for "how to fan-tessellate a circular arc," and this
   mutant proves that literally copy-adapting it does NOT solve the problem —
   Round only ever has one span (so its formula never needs a floor), while
   Arcs splits into two data-dependent sub-spans that can independently round to
   zero even when the undivided sweep would not. See DESIGN.md's "post-authoring
   oracle-risk audit" section for the full reasoning.

## Second review round (2026-07-29): 3 reviews, 34th test added

Three review passes came back. Applied what was correct, pushed back on two
suggestions that would have orphaned real tests.

**Applied:**
- **Concave-side coverage gap (WARNING).** Added `concave_side_connects_directly_without_curvature`:
  confirms `arcs_join_side_is_convex` correctly identifies `right_angle_corner`'s
  positive side as concave, then proves the curvature point `compute_arcs_join`
  predicts for that side never appears in the real tessellated output (empirically
  verified via a throwaway probe before committing the test). This has no natural
  wrong-implementation to mutation-test against — the codebase's existing back-side
  handling is unconditional for every join type, so it functions as a completeness
  check under the same 1-codebase-inferable-requirement allowance as
  `arcs_covers_inner_corner_like_other_joins`, not a 6th independent trap.
- **`positive_side` direction ambiguous (WARNING).** Meta.md said "left or right"
  without saying which bool value maps to which. Fixed: `positive_side: true` is
  now explicitly stated to mean the left side of the direction of travel.
- **Trimmed the "since a join only draws..." rationale clause** per the
  minor_suggestions review, but kept a short factual trace of the underlying
  concave/convex fact — needed to keep the new concave test's requirement
  documented (Direction-1 FP fairness), not purely a style trim.

**Pushed back on:**
- **"Remove the fixed/variable-width sentence, it's an obvious default."** Rejected.
  My own mutation testing proved this is NOT obvious: `compute_join_side_positions`
  (variable-width) and `compute_join_side_positions_fixed_width` are genuinely
  separate functions, and removing the Arcs branch from either one silently
  compiles and only fails that one function's 3-5 tests — nothing else breaks.
  Removing the sentence would leave 5 real tests (`arcs_variable_width_*`)
  undocumented, an FP fairness violation. Kept as-is.

Regenerated test.patch (34 tests now). solution.patch unchanged — nothing in this
round touched stroke.rs or lib.rs. Re-verified full apply-order + determinism in a
clean clone: 34/34 new, 185/185 base, both patches apply cleanly against
BASE_COMMIT (3 consecutive runs).

## Platform "Verify Solution" rejection, fixed (2026-07-30)

A real platform run against test.patch WITHOUT solution.patch applied (the
no-solution baseline check) failed with: "these tests are not in the regression
set (p2p) or the new test set (f2p), and they're not skipped: cargo-test.compilation
(failed)". Root cause: the build-failure fallback in test.sh (used because the new
test file fails to compile without `LineJoin::Arcs`) emitted a single synthetic
`<testcase name="compilation" classname="cargo-test">` node instead of one failure
per actual test name. The platform's wrapper cross-checks the no-solution run's
test-name set against the f2p list mined from the with-solution run, and the
placeholder name matched none of them.

Fixed by hardcoding the 34 real `#[test]` function names in test.sh and, in `new`
mode only, synthesizing one FAILURE `<testcase>` per name (with `classname=""`,
matching cargo2junit's actual empirically-verified output format for a Rust
integration test binary, not `classname="cargo-test"`) when the build fails.
Verified end to end in a clean clone: without solution.patch, the synthesized XML's
34 test names are byte-identical to the 34 names cargo2junit produces from a real
successful compile (`diff` clean); with solution.patch, `new` mode still passes
34/34 normally; `base` mode is untouched and still passes 185/185. Updated
`Instructions/TESTS.md`'s build-failure fallback section, which incorrectly
claimed "for the Rust crash case one node for the whole build is enough" — that
claim is now corrected with this evidence for future submissions.

## meta.md revision (2026-07-29, review feedback)

Two review passes flagged real issues, both fixed in meta.md without touching tests:

1. **Factual contradiction (ERROR).** The original wording claimed Arcs is "rather than
   a fixed-radius circle centered on the join point" — but every polyline point IS
   provably always exactly `half_width` from the join (the same radius `Round` uses;
   this is an algebraic identity of the offset-circle construction, confirmed by the
   already-passing `polyline_points_stay_at_half_width_from_the_join` test). Reworded
   to state the TRUE distinguishing property: same radius as `Round`, but the sweep
   bends through a curvature-derived intermediate point instead of interpolating at a
   constant rate. This is a wording correction, not a behavior change — the shipped
   geometry was always doing this; the description was just wrong about it.
2. **Missing public API signatures (ERROR).** Tests hardcode exact function names,
   parameter order, types, and return types. Added them inline as backtick-quoted
   signatures in prose (matching CLAUDE.md's "backticks only for new public API
   names" rule, not a code block).
3. **Conciseness (4 medium/low suggestions, verdict request_changes).** Trimmed the
   enumeration of existing join variants, the "(alongside the existing variants)"
   parenthetical, the "that Miter already respects" clause (the fairness-relevant
   part — reuse the SAME miter_limit, not a new number — survives via "the same
   miter_limit threshold"), and the redundant "both conditions independently
   trigger... neither explains the other" sentence (the "when X, or when Y" phrasing
   already states the OR-composition).

Word count 327 (was 295), still well under the 500 hard cap. Re-verified the
bidirectional FP check holds: every test still traces to a sentence, no sentence is
now untested (`both_fallback_conditions_are_independent` still traces to the
"when X, or when Y" clause even without the trimmed emphasis sentence). No code or
test changes were needed; solution.patch/test.patch are unchanged from prior
validation (33/33 tests, 185/185 baseline, Docker-confirmed).

## Known limitation, called out explicitly (not hidden)

No genuine S1/S3-style interdependent trap exists in this submission (where fixing
one requirement's natural implementation actively breaks another). Traps 1-7 above
are real, mutation-confirmed, and stacked across genuinely separate integration
sites (2 dispatch functions + 1 standalone API layer + tessellator/predictor
consistency), but they are independent misses, not interdependent ones. An
honest search was made for a natural shared-chokepoint refactor that would create
one; none was found that survives CONTRACT-STATED/FIX-HIDDEN without becoming an
artificial, unfair injection. Revised local pass-rate estimate: 20-40%, not
measured on a real platform batch.

## Platform Test Fairness review (2026-07-30): 11/34 flagged, all real, all fixed

A real platform Test Fairness run flagged 11 tests. All 11 were legitimate; none
were false positives. Fixed every one without removing any test.

**Invalid miter_limit input (4 tests: `sharp_join_beyond_limit_falls_back_to_bevel`,
`arcs_variable_width_sharp_join_beyond_limit_falls_back_to_bevel`, and the second
half of `both_fallback_conditions_are_independent`).** These set `miter_limit = 0.5`
directly on `StrokeOptions`, bypassing `with_miter_limit()`'s own assert that the
value must be `>= StrokeOptions::MINIMUM_MITER_LIMIT` (1.0) — a real gap since
direct field assignment has no such guard. A correct solver isn't obligated to
behave sensibly outside the type's own documented precondition. Fixed by switching
to a genuinely sharper corner (`sharp_corner`: `(0,0) -> (10,0) -> (3,-5)`) that
still exceeds the miter limit at the valid boundary value 1.0 — verified
empirically before committing (fixed and variable width both fall back to
identical Bevel-equivalent area at this corner+limit).

**Arbitrary area-delta thresholds (6 tests: `arcs_differs_from_bevel/round/miter`,
`same_join_within_generous_limit_uses_arc_not_bevel`,
`arcs_variable_width_differs_from_bevel`,
`arcs_variable_width_generous_limit_uses_arc_not_bevel`).** These asserted the
summed tessellated area differs from another join's area by more than an
author-chosen cutoff (0.02-0.05) — fair criticism, since the prompt requires
conceptual distinctness, not a specific quantitative area gap, and no reference
implementation exists to justify the number. Replaced with exact-point checks
grounded in the stated contract instead: assert the `compute_arcs_join`-predicted
curvature point IS present in Arcs' own tessellated output (proving Arcs actually
uses it) AND is NOT present in Bevel/Round/Miter's output (proving genuine
divergence at a specific, non-arbitrary point) — verified empirically for every
corner used, no coincidental collisions. Caught a real regression while doing
this: an earlier draft of the fix only asserted "not present in the other join,"
which is trivially true even when Arcs is broken (a no-op mutant test confirmed
this weakened 4 traps from being caught). Fixed by requiring BOTH the positive
(found in Arcs) and negative (absent from the other join) assertions together —
re-ran the full mutation suite afterward and confirmed all traps catch their
mutants again, with MORE tests failing per mutant than before (7 vs 3 for the
no-op case).

**Unstated 0.1 point-separation threshold (`positive_and_negative_side_give_different_points`).**
Reduced to 1e-3 — a floating-point-noise-distinguishing epsilon, not a claimed
minimum geometric separation.

**Concave-side polyline length contradicting the prompt
(`polyline_negative_side_starts_and_ends_on_the_opposite_offset_edges`).** The
reviewer read "only the convex side carries curvature-following geometry; the
concave side always connects directly" as constraining what the STANDALONE
predictor functions return, contradicting this test's `len() >= 3` assertion on a
concave side. That reading is reasonable given the original wording, but it
described the TESSELLATOR's real behavior, not the predictor functions' contract
(the predictor functions always compute curvature geometry for whichever side is
asked, independent of convexity — this is intentional, confirmed by
`concave_side_connects_directly_without_curvature` proving the tessellator itself
ignores that computed point on the concave side). Fixed by rewording meta.md to
make this explicit, keeping the test unchanged (it was correct all along, just
under-documented).

All fixes verified: 34/34 tests pass deterministically (3 runs), 185/185 baseline
unaffected, full mutation re-proof (3 key mutants re-run: no-op, miter-limit-guard
skip, variable-width-branch removal — all still caught, no-op catch actually
strengthened from 3 to 7 tests). Regenerated test.patch; solution.patch unchanged.
Re-verified clean-clone apply-order: both patches apply cleanly against
BASE_COMMIT, 34/34 new + 185/185 base.

## Platform Test Fairness PASS + coverage suggestions added (2026-07-30)

Re-run of Test Fairness: 0/34 unfair, PASS. The reviewer offered 4 coverage
suggestions (not fairness failures); added all 4 as new tests, each verified
numerically before writing, none requiring a meta.md change (all trace to
already-stated behavior or pre-existing, generic repo mechanisms — verified
against the bidirectional FP check before adding):

1. **Independent numeric oracle** (`arcs_join_matches_independent_circumcircle_oracle`).
   Every prior "differs from X" test derived its expected point by calling
   `compute_arcs_join` itself, so the helper and the tessellator could agree on a
   shared wrong formula and still pass. Added a test that hand-derives the
   expected point using the standard circumcenter formula, written independently
   in the test file (not calling any crate helper), for an asymmetric corner
   distinct from every other test's geometry. Verified by hand (Python) that the
   derived point matches the library's actual output to f32 precision before
   committing the Rust assertion.
2. **Genuinely varying line width** (`arcs_variable_width_with_differing_widths_*`,
   3 tests). Every prior variable-width test used the same attribute value at all
   three points, so a solver could accidentally use ANY of prev/join/next's width
   without being caught. Verified empirically that the join uses its OWN local
   attribute (not prev's, next's, or an average), then added a test confirming
   `compute_arcs_join` computed with the join's own local half-width matches the
   real output, plus two tests confirming both fallback rules still hold with
   genuinely differing widths at each point.
3. **Tolerance handling** (`polyline_finer_tolerance_refines_without_moving_endpoints_or_peak`).
   Verified a coarse tolerance (1.0) gives 3 points and a fine one (0.001) gives
   20, with identical start/end/peak. Added a test asserting monotonic
   subdivision growth and endpoint/peak stability across tolerances.
4. **Miter-limit boundary** (`miter_limit_boundary_matches_exceeds_semantics`).
   Hand-derived the exact threshold value for a corner where it's `>=` the
   documented `MINIMUM_MITER_LIMIT` (so all three probe values are valid inputs),
   then confirmed empirically that exactly-at-threshold does NOT count as
   exceeded (matching the repository's own strict `>` semantics, which "exceed"
   already implies in plain English). Added a below/at/above three-way test.

**Caught a mutation-testing regression while verifying suggestion 1's value**: a
sign-flip mutant that a "self-consistent but wrong" implementation might produce
was tested against the new oracle — it failed the oracle AND several
already-existing consistency tests, confirming the new test adds real,
corroborated value rather than being redundant.

test.sh's hardcoded fail-to-pass test name list (used in the build-failure
fallback for the no-solution platform precheck) was updated from 34 to 40 names
and re-verified byte-identical against a real successful compile in a clean
clone. All 40 tests pass deterministically (3 runs), 185/185 baseline unaffected,
both patches re-verified clean against BASE_COMMIT (40/40 new + 185/185 base in a
fresh clone, both apply orders).

## Platform Test Fairness re-run 2 (2026-07-30): 1/40 unfair, fixed by removal

Re-run flagged exactly one test: `arcs_join_matches_independent_circumcircle_oracle`
(the suggestion-1 addition from the prior round). Verdict: it pins the EXACT
circumcircle/radial construction as the expected value, but meta.md only states
the direction is "determined by the curvature implied by" the three points —
vague enough that a different, equally reasonable interpretation (e.g. a
finite-difference tangent/curvature estimate) would legitimately fail this test.
This is a real CONTRACT-STATED/FIX-HIDDEN violation: the test effectively adds a
HOW requirement (the specific circumcircle formula) the description never states.

Two ways to fix this existed: state the exact formula in meta.md (resolves
fairness but hands away the core geometric derivation, gutting the pick's actual
difficulty), or remove the test. Removed it — the coverage goal it served
(catching a "self-consistent but wrong" implementation where the predictor and
tessellator agree on a shared bug) is still reasonably served by the existing
`arcs_differs_from_bevel/round/miter` and `compute_arcs_join_matches_tessellated_vertex`
family, which already mutation-test as catching several classes of wrong
implementation (see mutation-proofing sections above) without requiring an
independently-pinned numeric oracle.

Declined to add 2 of the same round's other coverage suggestions for the same
reason: "degenerate standalone inputs" (`prev == join` / `join == next`) would
require picking a specific behavior — panic vs. graceful `None` — that meta.md
never specifies either way; testing it would risk repeating the exact same
fairness mistake. Kept the suite at 39 tests rather than force an answer to an
underspecified question.

Suite is now 39 tests, 39/39 deterministic (3 runs), 185/185 baseline unaffected.
test.sh's fail-to-pass name list updated to 39 and re-verified byte-identical to
a real compile in a clean clone; both patches re-verified clean against
BASE_COMMIT (39/39 new + 185/185 base, fresh clone, both apply orders).

## Final trap inventory + FP check status (2026-07-30)

Five traps ship, all mutation-confirmed real and CONTRACT-STATED/FIX-HIDDEN fair
(see earlier sections for full evidence and exact mutants):

1. Dual fallback composition (collinear OR miter-limit-exceeded) — reuse of
   `miter_limit_is_exceeded`, not a self-invented distance metric. Built wrong
   twice by me before landing on the correct mechanism.
2. Two genuinely separate dispatch sites (fixed-width vs. variable-width
   stroking) — an agent can silently wire only one.
3. Fan-wiring/no-op integration — the geometry must actually reach the rendered
   output, not just compile.
4. Dual-path sign consistency — both between the standalone predictor and the
   tessellator, AND independently between the fixed-width and variable-width
   dispatch sites' own sign conventions (two distinct mutants, same failure
   family, confirmed via build-and-measure).
5. Oracle-resistant subdivision floor — build-measured proof that literally
   copy-adapting the sibling `tessellate_round_join`'s subdivision formula
   (Round's own oracle risk) produces a real, silent bug, because Round's
   single-span formula has no analog to the two-span floor Arcs requires.

No genuine S1/S3 "fixing one breaks the other" interdependent trap exists (see
the earlier oracle-risk audit) — traps are stacked and orthogonal across real
integration sites, not interdependent in that specific sense; an honest search
for one was made and none survived fair construction.

**FP check, both directions, re-verified after every round this session:**
Direction 1 (every meta.md sentence has >=1 discriminating test) and Direction 2
(every test traces to a meta.md sentence or the single allowed codebase-inferable
fact) both hold on the current 39-test suite. meta.md states only observable
behavior (curvature source, dual fallback, fixed/variable-width uniformity, the
3 public function contracts, explicit side semantics) — no internal function
names, formulas, or derivations are named anywhere in it.

Local pass-rate estimate remains 20-40%, unmeasured against a real platform
batch (this session had no agent-solve access, only precheck/fairness gates).

## Round 3 coverage suggestions (2026-07-30): 5 added, 1 solution change, 1 skipped

Platform surfaced 4 more coverage suggestions. Handled each on its own merits
rather than reflexively implementing all of them the same way as before:

1. **Independent curvature oracle (again).** The exact same suggestion that got
   flagged UNFAIR two rounds ago (pinning the circumcircle formula). This time,
   found a genuinely SAFE way to satisfy it: for an isoceles (equal-leg) corner,
   ANY reasonable curvature-following construction must place the peak exactly
   on the angle bisector through the join, by reflection symmetry alone — a
   fact independent of which specific curvature formula is used. Verified by
   hand (Python) that the circumcenter of an isoceles triangle lies exactly on
   the bisector (cross product 0.0 exactly), then confirmed the real library
   output matches (cross product ~3e-8, float precision) before writing the
   Rust assertion. This does NOT pin a formula — a finite-difference curvature
   estimate would also have to respect this same symmetry to be correct, so it
   stays fair while still being a genuinely independent (non-self-referential)
   check. Mutation-tested: does NOT catch a pure sign-flip (expected — sign
   only affects distance along the bisector, not direction; that mutant is
   already caught by 10 other tests), which confirms the test is exactly as
   permissive as fairness requires, no more.
2. **Tolerance accuracy.** Added a test asserting the actual chord-to-arc
   deviation (sagitta) of each polyline segment is bounded by the supplied
   tolerance, not just that finer tolerance yields more points. Verified
   numerically first (Python) that the crate's own `circle_flattening_step`
   formula guarantees this bound exactly at the boundary.
3. **Degenerate standalone inputs.** This required an actual SOLUTION change,
   not just a test: `compute_arcs_join` and `compute_arcs_join_polyline`
   previously used `debug_assert!(prev != join && join != next)`, which panics
   on coincident points instead of returning `None`/empty. Replaced with an
   early graceful return, matching the "no such arc exists" fallback family
   already described in meta.md. Reworded meta.md's collinear-fallback sentence
   from "collinear" to "collinear or not all distinct from one another" to
   keep this fair and traceable (broadening an existing sentence, not adding
   scope). Added 3 tests (coincident points at each position, a 180-degree
   reversal, and the polyline equivalents). Mutation-confirmed: reverting to
   the old `debug_assert!` causes a real panic the new test catches.
4. **Serialization round-trip.** Declined. Would require modifying test.sh's
   cargo invocation to add `--features serialization`, risking the fragile
   fail-to-pass name-alignment fix from two rounds ago, for a suggestion the
   platform itself hedged ("if... supported by the benchmark build matrix").
   Not worth the risk for a feature that's automatically covered anyway (serde
   derives apply uniformly to every enum variant, `Arcs` included, with zero
   additional code).

Suite is now 44 tests. 44/44 pass deterministically (3 runs), 185/185 baseline
unaffected. Both solution.patch (degenerate-input fix) and test.patch
regenerated; test.sh's fail-to-pass name list updated to 44 and re-verified
byte-identical to a real compile in a clean clone. Both patches re-verified
clean against BASE_COMMIT (44/44 new + 185/185 base, fresh clone, both apply
orders). FP check re-verified both directions on the final 44-test suite.

## Platform Test Fairness re-run 3 (2026-07-30): 9/44 unfair — a real, substantive finding

This one was different from the earlier rounds: not a wording nitpick, a
genuine over-specification bug in the test design. All 9 flagged tests
asserted the `compute_arcs_join`-predicted point must appear as an EXACT
tessellation vertex (`contains_vertex_near`, epsilon 1e-3), and in most cases
that it must be ABSENT as an exact vertex from another join's output.

Checked this against my own meta.md word-for-word before accepting the
verdict: meta.md never claims the standalone functions' output corresponds to
literal internal tessellator vertices — it describes the join surface
"bending through" a point and the functions computing "the join geometry,"
which is a claim about the curve's shape, not a promise about how any
particular tessellation strategy discretizes it. A reasonable alternative
implementation (different subdivision scheme, coarser tolerance, a flattener
that doesn't anchor a vertex exactly at the mathematical peak) could produce a
geometrically-equivalent surface that passes near, not exactly through, that
coordinate — and would have failed these tests despite being correct. This was
a legitimate CONTRACT-STATED/FIX-HIDDEN violation on my part, not a reviewer
misread.

**Fix:** replaced exact-vertex-membership with mesh-EDGE distance (point-to-
segment distance to every triangle edge, not just vertices), asserting Arcs'
surface passes within `NEAR_SURFACE` (0.01) of the predicted point and other
joins' surfaces stay beyond `FAR_FROM_SURFACE` (0.03). This tests the same
real geometric claim (the rendered boundary genuinely reaches that direction)
without assuming any specific internal representation. Verified numerically
before writing: for the corners used, Bevel/Miter/Round's actual distance to
the predicted point is 0.11-0.29 (comfortable margin above 0.03); Arcs' own
distance is 0 (my implementation anchors it exactly, well under 0.01).

Re-ran the two most load-bearing mutation tests against the rewritten suite:
the no-op mutant still fails exactly the same 7 tests as before (trap strength
unchanged), and the sign-flip mutant now fails 9 tests (up from fewer before —
if anything, edge-distance is a MORE sensitive discriminator than exact-vertex
matching, not less). `concave_side_connects_directly_without_curvature` was
explicitly rated FAIR by this same review and left untouched — it asserts
ABSENCE of a specific excluded point, which the reviewer distinguished from
requiring a particular emitted topology.

Suite remains 44 tests (no tests added or removed this round, only the shared
assertion mechanism changed). 44/44 pass deterministically (3 runs), 185/185
baseline unaffected. solution.patch unchanged this round; test.patch
regenerated and re-verified clean against BASE_COMMIT in a fresh clone (44/44
new + 185/185 base, both apply orders, exact fail-to-pass name match).

## Round 4 coverage suggestions (2026-07-30): 2 of 3 added

Same review batch also surfaced 3 coverage suggestions:

1. **Tessellator-level tolerance** (added). All prior tolerance tests only
   exercised the standalone `compute_arcs_join_polyline` helper, not an actual
   `LineJoin::Arcs` tessellation. Added
   `arcs_tessellation_refines_with_tolerance_and_keeps_reaching_the_peak`:
   verifies the real tessellator's triangle count is non-decreasing as
   tolerance tightens (1.0 -> 0.1 -> 0.01) and that the surface still passes
   near the predicted peak at every tolerance.
2. **Left-turn variable-width orientation** (added). Every variable-width test
   so far used a right-turning corner (positive/left side convex). Added
   `arcs_variable_width_left_turn_negative_side_differs_from_bevel`, mirroring
   the existing right-turn variable-width tests but for a left turn where the
   negative/right side is convex, closing the orientation gap.
3. **Fallback surface equivalence for collinear** (declined). The suggestion
   is that the current collinear-fallback area check would pass for many
   non-Bevel implementations. This is geometrically inherent, not a test
   weakness: three EXACTLY collinear points form no real corner at all, so
   Miter, Bevel, Round, and a correctly-falling-back Arcs all necessarily
   produce IDENTICAL straight-through geometry (already proven earlier this
   session when auditing the internal fallback mechanism). There is no
   stronger, still-fair assertion available for the truly-collinear case
   specifically; the "same threshold Miter respects" and reversal-shaped
   degenerate cases are covered by other tests instead.

Suite is now 46 tests. 46/46 pass deterministically (3 runs), 185/185 baseline
unaffected. solution.patch unchanged; test.patch regenerated and re-verified
clean against BASE_COMMIT in a fresh clone (46/46 new + 185/185 base, both
apply orders, exact fail-to-pass name match).

## Platform Test Fairness re-run 4 (2026-07-30): 8/56 unfair, real finding, fixed

8 tests flagged. All 7 "Bevel/Round/Miter must be far from the peak" halves
used a separate `FAR_FROM_SURFACE = 0.03` constant that pinned an arbitrary,
unstated magnitude of separation — the prompt requires Arcs to be
*geometrically distinct*, not separated by exactly this much. The 8th
(`concave_side_connects_directly_without_curvature`) checked vertex-buffer
absence rather than rendered-surface distance, so a correct implementation
with an unused/redundant emitted vertex could have failed it even though the
surface itself was correct.

**Fix:** removed `FAR_FROM_SURFACE` entirely. Every "must not be near" check
now reuses the SAME `NEAR_SURFACE` (0.01) constant already used for "must be
near" — one well-justified precision threshold instead of two, closing the
"where did 0.03 come from" objection at the root rather than picking a
smaller arbitrary number. Converted `concave_side_connects_directly_without_curvature`
from vertex-membership to the same `mesh_boundary_distance` check used
everywhere else (checking the rendered surface, not the vertex inventory) —
exactly the fix the reviewer itself suggested.

**Explicitly re-verified by mutation, not by re-checking the arithmetic
that 0.037-0.287 > 0.01** (per direct instruction: hardening comes from
doing, not assumptions). Re-ran all 5 core mutants against the weakened
threshold:
- No-op (fixed-width branch removed): 8 tests fail (was 7 with the old
  threshold — one more test, the new tolerance-refinement test, also failed).
- Sign flip: 11 tests fail (was 9).
- Variable-width branch removed: 5 tests fail (unchanged).
- Round-template subdivision-floor bug (no per-half floor): 10 tests fail
  (was 4 — dramatically more now that the "differs from" tests also exercise
  this trap through the peak-containment path).
- Degenerate-input panic reverted: still panics and is still caught.

Every trap is at least as strong under the weaker, more defensible threshold
as it was under the old arbitrary one — none of the fairness fix accidentally
gutted real discriminating power.

Suite stays at 46 tests (no additions/removals, only the shared threshold and
one assertion mechanism changed). 46/46 pass deterministically (3 runs),
185/185 baseline unaffected. solution.patch unchanged; test.patch regenerated
and re-verified clean against BASE_COMMIT in a fresh clone (46/46 new +
185/185 base, both apply orders, exact fail-to-pass name match).

## Platform Environment Quality FAIL, fixed (2026-07-30)

`cargo build`/`cargo test` failed offline: Cargo tried to download missing
crates because the Dockerfile only ever built the single crate
`lyon_tessellation` (`cargo build -p lyon_tessellation --tests`), never
fetching or building the rest of the workspace. `Cargo.toml`'s `[workspace]
members` list includes `cli`, `examples/wgpu`, `examples/wgpu_svg`,
`bench/tess`, `bench/path`, `bench/geom` alongside the crates the solution
touches; `exclude` only affects glob auto-discovery and does NOT drop these
explicitly-listed members, and there is no `default-members` restricting a
bare/unscoped build. The platform's Environment Quality check runs generic,
unscoped `cargo build`/`cargo test` from the repo root, which needs every
member's dependencies fetched and cached at image-build time (wgpu stack,
x11rb, wayland-protocols, metal, windows-sys, orbclient, usvg, clap) since the
solve-time container runs with `--network none`.

**Fix:** Dockerfile's `RUN` line changed from the scoped build to
`cargo install cargo2junit --version 0.1.15 && cargo fetch --locked && cargo
build --workspace --tests && chmod -R a+rwX /app`. `--locked` is safe and
correct because `Cargo.lock` is genuinely committed in the base repo
(confirmed via `git show <BASE_COMMIT>:Cargo.lock`). Kept `chmod -R a+rwX
/app` (not `/root`, not `a+rX`) — the DOCKER.md-documented failure mode is
specifically `chmod -R a+rX /root` breaking cargo's own registry permissions;
this targets a different directory with a different, less restrictive flag
and was already proven safe earlier in this session with real
`--network none` runs.

Verified outside Docker in a clean clone at BASE_COMMIT with both patches
applied: `cargo fetch --locked` and `cargo build --workspace --tests` both
succeed cleanly (no errors), pulling in every workspace member's transitive
dependencies. This is the exact command the Dockerfile's `RUN` line executes.

**Docker-level re-validation was attempted but not completed locally**: a real
`docker build` was started and had to be aborted when host free disk dropped
to 327M mid-build (this box has only ~5.6G free system-wide, most of the 119G
disk consumed by things outside this repo; a full `olympus-base-rust` image
plus a `--workspace` build of wgpu/x11/wayland/metal artifacts needs more
headroom than that safely allows). Recovered by pruning the build cache back
to 5.6G free. Per user decision, relying instead on: (a) the outside-Docker
proof above that the exact new `RUN` command succeeds, and (b) the earlier
real `docker build` + `docker run --user 1000:1000 --network none` validation
done earlier this session with the old (scoped) Dockerfile, which already
confirmed the offline/non-root mechanics (permissions, PATH, cargo2junit,
test.sh JUnit output) work correctly in this exact base image. The only
untested combination is those two together in one image; that combination
could not be safely validated on this machine's disk budget.

## Platform Description Quality PASS, one wording fix applied (2026-07-30)

PASS verdict, one `over_specification` comment: the phrase "but instead of
sweeping between them at a constant rate," contrasts Arcs against `Round`'s
internal sweep parameterization, an implementation detail no test asserts
anything about. Fixed by dropping the contrast entirely: "but bends through a
curvature-following intermediate point whose direction is determined by..."
Word count 363 (was 371), still ASCII-clean, no test or solution changes
needed (the sentence being removed was never tied to any assertion).

## Platform Auto Review: Revision Requested, both findings real, fixed (2026-07-30)

Description scored 3/3 clean (no change needed). Tests 1/3, Solution 0/3, two
findings, both legitimate on inspection, both fixed:

**T3/T4 (tests): no independent asymmetric curvature oracle.** All prior
"differs from X" and consistency tests derived their expected peak by calling
`compute_arcs_join` itself (or used a symmetric corner where the peak lies on
the bisector by construction, provable without any formula). For a general
asymmetric triple, a coherent-but-wrong implementation could pick any point on
the join-centered half-width circle, satisfy the helper/tessellator
self-consistency checks, and pass. Fixed by adding
`arcs_join_matches_independent_circumcircle_oracle_for_asymmetric_corner`: an
independent circumcenter/radius computation written directly in the test file
(the standard formula, not calling any crate function), for a scalene
(0,0)/(12,0)/(17,-5) triple, asserting both `compute_arcs_join` and the
tessellated mesh boundary reach that independently-derived point. Verified by
hand (Python) before writing the Rust assertion: the independently-derived
point matches the library's actual `compute_arcs_join` output to f32
precision (12.478852, 0.87789536). Mutation-confirmed: flipping the convex/
concave sign in `arcs_join_position`'s offset direction is caught by this new
test along with 11 others.

Note: an equivalent oracle test was added and then removed earlier this
session (see "Platform Test Fairness re-run 2") after being flagged as an
unfair formula-pinning test, since the description states only "curvature
implied by" the three points, not a formula. Re-examined that reasoning here:
for three specific points, the circumcircle through them is the unique circle
passing through prev, join, and next, so "curvature implied by the three
points" has essentially one natural reading once combined with the
already-independently-tested constraint that the peak sits exactly
`half_width` from the join (an algebraic identity confirmed by another
existing test) - unlike a discrete finite-difference curvature estimate,
which generically would not pass through all three points and would already
conflict with other passing tests. This platform review round explicitly
requested the oracle back and rated the description 3/3 without raising the
earlier ambiguity concern, so treating this as the current, authoritative
verdict rather than re-litigating the earlier round.

**S1 (solution): `compute_arcs_join_polyline` doesn't unwrap angles across the
atan2 branch cut.** The standalone polyline helper computed `start_angle`,
`peak_angle`, `end_angle` as raw `angle_from_x_axis().radians` values and fed
them straight into `push_arc_subdivisions`'s linear interpolation. For a join
rotated so the sweep crosses atan2's -pi/pi boundary, the raw angle difference
can pick the long way around the circle instead of the short, curvature-
following arc. `tessellate_arcs_join` (the real tessellator path) already had
correct branch-cut-aware unwrapping using `Angle::angle_to` plus an
`angle_sign` correction (lines ~2273-2282, an existing repo idiom also used at
line 2220) - the standalone helper just never matched it. Fixed by applying
the identical unwrapping idiom to both the peak and end angles in
`compute_arcs_join_polyline`, using `positive_side` to derive the same
`angle_sign` convention the tessellator uses (`side == SIDE_NEGATIVE` maps to
`positive_side == false`).

Verified the bug and the fix both ways before committing: reverted the fix
locally and probed a right-turn corner rotated in 30-degree steps around the
origin - the buggy version emitted 12 points (long way around, chord length
up to 0.61) at rotations between roughly 120 and 179 degrees, versus a
constant 5 points (chord length ~0.44) at every other rotation and at every
rotation with the fix restored. Added
`polyline_point_count_is_rotation_invariant_across_the_branch_cut`: asserts
the polyline's point count for a corner rotated 150 degrees around the origin
matches the unrotated reference count - a rotation-invariance property that's
true for any correct implementation regardless of formula, so it doesn't pin
anything the description doesn't already imply (a rigid global rotation
can't change how finely a fixed local shape needs to be subdivided).
Mutation-confirmed: reverting the branch-cut fix fails exactly this one test
and no others (47/48 passed on that mutant).

Both fixes verified: 48/48 new tests pass deterministically (3 runs), 185/185
baseline unaffected, both patches re-verified clean against BASE_COMMIT in a
fresh clone (both apply orders, `test.patch`-alone fails to compile with 24
errors as expected). `test.sh`'s hardcoded fail-to-pass name list updated from
46 to 48 and re-verified byte-identical to a real `cargo test -- --list`
compile in a clean clone. Neither fix required a meta.md change - the oracle
test traces to the already-stated "curvature implied by the join point and
its two neighboring stroke points" sentence plus the already-tested
half-width invariant; the branch-cut test traces to the already-stated
requirement that `compute_arcs_join_polyline` returns "the full polyline...
from that side's offset point on the incoming edge through the curvature-
following point to its offset point on the outgoing edge," which a long-way-
around polyline does not satisfy.

## Platform Test Fairness + Task Quality: circumcircle oracle flagged unfair again, resolved by narrowing meta.md instead of removing the test (2026-07-30)

Two independent reviews (Test Fairness: 49/50 fair, 1 flagged; Task Quality:
7/8 criteria passed, criterion 04 failed) both converged on the exact same
single finding: `arcs_join_matches_independent_circumcircle_oracle_for_
asymmetric_corner` pins the circumcircle-through-three-points construction as
canonical, but meta.md only says the direction is "determined by the
curvature implied by" the three points, never naming a specific estimator.
The Test Fairness review's evidence was concrete and correct: this exact
codebase already computes every OTHER join's turn direction via a tangent-
bisector construction (`compute_normal` in `math_utils.rs:16-31`, summing and
normalizing the two edge tangents), so an engineer pattern-matching to that
established convention could reasonably reach for the same construction here
and produce a different, self-consistent answer for an ASYMMETRIC corner
(bisector-based and circumcircle-based directions only coincide by symmetry
for isoceles corners, which is exactly why the pre-existing
`arcs_join_peak_lies_on_the_bisector_for_a_symmetric_corner` test alone was
never enough).

This is the third time this exact tension has surfaced in this problem's
history (see "Platform Test Fairness re-run 2" above, where an identical
oracle test was added then removed for the same reason). Rather than oscillate
a fourth time, evaluated the actual tradeoff directly with the user: fully
disclosing the construction (Task Quality's own suggested fix - state the peak
lies on the circle through prev/join/next) would make the test unambiguously
fair, but would also very likely destroy the F-8 named-algorithm-override trap
that is this submission's primary source of difficulty (see
`failure-patterns.md` F-8: 9/10 Nova runs failed by building SVG2's real
osculating-circle construction instead of this problem's stated variant -
disclosing "circle through all three points" directly answers that guess).

Resolved with a middle path instead of either extreme: added one clause to
meta.md's first sentence ruling out ONLY the specific alternative the fairness
reviewer cited by name - the tangent-bisector construction - without naming
circumcircle, a formula, or any coordinate construction. New wording: "...
whose direction is determined by the curvature implied by the join point and
its two neighboring stroke points on the path, not by the tangent bisector
the stroke's other joins use to orient their turn." This directly answers the
reviewer's specific, cited evidence (ruling out exactly the alternative they
pointed to with a file:line citation) without touching the actual measured
90%-kill trap at all, since SVG2's per-edge two-circle construction is a
completely different, unaddressed alternative that this clause says nothing
about. Word count 377 (was 371), still ASCII-clean.

Re-verified after the wording change: 48/48 tests pass deterministically (3
runs), 185/185 baseline unaffected, both patches re-verified clean against
BASE_COMMIT in a fresh clone (both apply orders, exact 24-error compile
failure with test.patch alone, exact fail-to-pass name match). The oracle test
was kept rather than removed, preserving the T3/T4 coverage the earlier Auto
Review round explicitly required.

## Platform Test Fairness re-run: bisector-only hint insufficient, evidence forced the full-disclosure decision (2026-07-30)

The bisector-only hint above was empirically wrong to trust as a durable fix.
A subsequent Test Fairness run flagged the exact same test again, and
critically, no longer even mentioned the bisector construction (already ruled
out) - it now cited "a quadratic interpolation or another discrete-curvature
estimator" as an equally plausible alternative instead. This is clean,
concrete evidence that "curvature implied by three points" is open-ended
enough that a fairness reviewer can always name some different competing
construction, no matter which specific one gets excluded by name. Excluding
one alternative does not close the ambiguity, it just relocates it.

Given this evidence, decided with the user to fully disclose the construction
rather than attempt a third narrowing round. Meta.md's first sentence now
reads: "...but bends through an intermediate point positioned along the
radius, from the join outward, of the circle passing through the join point
and its two neighboring stroke points on the path." This explicitly names a
single circle through all three points (the circumcircle) as the canonical
reference, which resolves the T3/T4 fairness gap unambiguously.

**Known consequence, stated plainly, not hidden:** this wording also directly
answers the F-8 named-algorithm-override trap documented in
`failure-patterns.md` (9/10 Nova runs previously failed by building SVG2's
real two-circles-per-edge osculating construction instead of this problem's
single-circle variant) - by naming "the circle passing through" all three
points, it now also rules out the SVG2 alternative, not just the bisector
alternative the fairness reviewer originally cited. The measured 90% kill rate
from that trap should not be expected to hold in a future batch against this
final wording; a re-measurement (fresh agent batch) would be needed before
citing this problem's original pass-rate estimate as still valid.

No code changes were needed - only meta.md changed, since solution.patch
already implements exactly this construction. 366 words, ASCII-clean. 48/48
tests still pass deterministically, 185/185 baseline unaffected, patches
unchanged from the prior round (meta.md is not part of either patch).

## Platform Test Fairness re-run: circumcircle oracle now PASSES; new flag on the branch-cut test, fixed (2026-07-30)

Confirms the full disclosure worked: `arcs_join_matches_independent_
circumcircle_oracle_for_asymmetric_corner` is now rated fair (explicitly
called "the strongest independent oracle in the suite"). One new flag
surfaced instead: `polyline_point_count_is_rotation_invariant_across_the_
branch_cut` was ruled unfair for pinning EXACT point-count equality across
rotation, since a different, still-correct tolerance-driven subdivision
strategy could legitimately produce a slightly different count without any
bug. The reviewer's own suggested fix was accepted: replaced the
`assert_eq!` on exact count with `assert!(poly.len() <= 2 * reference.len())`
- a generous bound that any reasonable implementation trivially clears, but
one the actual bug does not: measured the buggy (unwrap-reverted) code at
this exact fixture/rotation and got 25 points vs a fixed/reference count of 8
(>3x), comfortably outside the 2x bound, while the fixed code stays at
exactly 8 for both. Mutation-confirmed: reverting the branch-cut fix still
fails only this one test (47/48).

48/48 tests pass deterministically (3 runs), 185/185 baseline unaffected,
both patches re-verified clean against BASE_COMMIT in a fresh clone (fails to
compile with 24 errors without solution.patch, as expected).

## Difficulty projection after full disclosure (2026-07-30, not yet re-measured)

The user asked for an honest projection of how the meta.md disclosure changes
difficulty, using the original 10-run batch as evidence. Recorded here before
any new batch runs, so it can be checked against real results later.

The original batch's 90% kill rate (9/10 Nova) was driven entirely by agents
retrieving SVG2's real two-circles-per-edge construction instead of this
problem's single-circle variant - and all 9 were otherwise "substantial,
legitimate implementations" that got dispatch wiring, fallback structure, and
variable width right. Meta.md now states the winning construction almost
verbatim. Projected outcome: pass rate likely moves from ~10% to roughly
50-80%, landing above the current sprint's 40% ceiling (too easy). The
remaining traps (miter-limit reinvention, dual dispatch sites) were never
observed to independently kill an agent in the original batch - they always
co-occurred with the geometry failure - so they are not expected to hold the
line alone. The two newest tests (branch-cut, asymmetric oracle) are
mechanical to satisfy once the disclosed formula is implemented correctly.

This is a projection, not a re-measurement. A fresh agent batch is required
before treating this submission as approvable again; if it lands above 40%,
the design will need a new orthogonal trap (see `failure-patterns.md`'s F-8
addendum: an independent oracle and a named-algorithm trap on the same
behavior are close to mutually exclusive, and this is that prediction playing
out).

## New orthogonal trap added: concave-side curvature-vs-half-width overshoot (2026-07-30)

Per the projection above, added one new trap independent of the now-disclosed
circumcircle construction, found by reading `arcs_join_position` itself rather
than guessing: `let offset_radius = radius + sign * half_width; if
offset_radius <= 0.0 { return None; }`. Traced every call site
(`grep -n "arcs_join_position("`) and confirmed the tessellator's own
convex-side dispatch (`compute_join_side_positions_fixed_width`, front_side
only) always has `sign = +1`, so `offset_radius = radius + half_width` there
is always positive - this guard is UNREACHABLE from the actual rendered
tessellation. It is only reachable through the standalone `compute_arcs_join`
/ `compute_arcs_join_polyline` functions when explicitly queried for the
CONCAVE side of a corner whose curvature radius is smaller than `half_width`
(the concave offset direction is `radius - half_width`, which goes negative
and would otherwise flip the point to the wrong side of the center).

Verified this was a real, currently-untested, currently-undocumented gap: no
existing test exercises this condition (confirmed via targeted numeric probe
before writing any test - convex side at half_width=6.0 on `(0,0)/(10,0)/
(10,-2)` returns `Some`, concave side correctly returns `None`). Verified the
silent-bug risk by removing the guard: the concave side then returns
`Some((4.116516, -1.1766968))` - a geometrically bogus point mirrored past the
circle's center - instead of `None`, and the polyline explodes to 46 points
instead of empty. A plausible, easy-to-miss omission for an agent who
correctly derives the circumcircle formula but doesn't think to guard the
offset going negative for a side they weren't focused on.

Added ONE meta.md clause stating the general contract (WHAT), not the
formula (HOW): "`None` under the same fallback conditions described above or
when the requested side's curvature is too tight relative to `half_width`
for such a point to exist." This does not reveal the radius-vs-half-width
comparison or the sign convention - a solver still has to derive that
themselves from their own circumcircle computation. 384 words, ASCII-clean.

Added 2 tests: `compute_arcs_join_returns_none_when_requested_side_
curvature_is_too_tight_for_the_half_width` and `polyline_is_empty_when_
requested_side_curvature_is_too_tight_for_the_half_width`, each asserting the
convex side still returns `Some`/non-empty at the same half-width while the
concave side returns `None`/empty. Mutation-confirmed: removing the guard
fails exactly these 2 tests and no others (48/50 pass on that mutant).

Suite is now 50 tests. 50/50 pass deterministically (3 runs), 185/185
baseline unaffected, both patches re-verified clean against BASE_COMMIT in a
fresh clone (both apply orders, 24-error compile failure with test.patch
alone, exact fail-to-pass name match, `test.sh`'s NEW_TEST_NAMES updated to
50). This trap is independent of the disclosed geometry formula (it's a
distinct numeric edge case: curvature radius vs. half_width, not which
construction to use for direction) and independent of the miter-limit/
dispatch traps, so it should hold regardless of how the disclosure affects
the original F-8 pass rate. Not yet re-measured against a real agent batch.

## Platform Test Fairness re-run: branch-cut test flagged again on ITS OWN 2x bound, resolved with a constant-free rewrite (2026-07-30)

The curvature-vs-half-width trap above passed cleanly. The branch-cut test
was flagged unfair a second time, even after weakening exact-count equality
to `poly.len() <= 2 * reference.len()` in the previous round: the reviewer's
objection was that ANY numeric implementation-quality bound not grounded in
the prompt or repo is unstated, not specifically the "2x" value. Point count
itself, at any multiplier, is a subdivision-strategy detail the prompt never
promises.

Rewrote the test to remove ALL arbitrary constants except a pure
floating-point-slop epsilon. New approach: sum the UNSIGNED per-step angle
(via `acos(dot(unit vectors))`, always in `[0, pi]`, immune to the atan2
branch cut since consecutive polyline points are always closely spaced) along
the entire returned polyline, and compare it against the independently
computed direct unsigned sweep from start through peak to end (same
`acos(dot(...))` method, using only the already-established start/peak/end
landmarks - no formula, no subdivision assumption). A correct short-way
polyline's accumulated sweep must equal this direct sweep; a long-way
polyline's accumulated sweep is far larger (mechanically, not by any
tunable choice).

Verified numerically before committing: with the fix, `total_sweep` and the
direct sweep differ by ~2.6e-6 radians (pure float noise) on the same
rotated fixture used before; with the branch-cut bug reverted, they differ by
~4.93 radians (roughly 283 degrees) - six orders of magnitude apart. Used
`0.01` radians as the pass threshold, comfortably separating the two by
several orders of magnitude in both directions - this is a discretization
epsilon in the same spirit as the `1e-3`/`1e-4` epsilons already used
throughout the suite, not an implementation-quality constraint.

Replaced `polyline_point_count_is_rotation_invariant_across_the_branch_cut`
with `polyline_sweep_matches_the_direct_path_through_start_peak_and_end_
across_the_branch_cut`. Mutation-confirmed: reverting the branch-cut fix
fails exactly this one test (49/50). Suite stays at 50 tests (one replaced,
none added/removed). 50/50 pass deterministically (3 runs), 185/185 baseline
unaffected, both patches re-verified clean against BASE_COMMIT in a fresh
clone (both apply orders, clean patch application with no whitespace
warnings, `test.sh`'s NEW_TEST_NAMES updated). No meta.md change needed -
this still traces to the already-stated "full polyline... from that side's
offset point on the incoming edge through the curvature-following point to
its offset point on the outgoing edge" contract, which a long-way-around
sweep does not satisfy.

## False-positive review: infinite miter_limit gap + tolerance-refinement test weakness, both fixed (2026-07-30)

A 3-judge review panel flagged a real false-positive-enabling gap and Auto
Review separately flagged a real test-coverage gap. Both addressed without
touching meta.md.

**FP: `!miter_limit.is_finite() -> None` in a candidate's `compute_arcs_join`/
`compute_arcs_join_polyline`.** A reviewed candidate solution added a guard
rejecting non-finite `miter_limit` up front, forcing Bevel for `INFINITY`
even though `StrokeOptions::with_miter_limit` accepts it (its assert only
requires `>= MINIMUM_MITER_LIMIT`) and `miter_limit_is_exceeded`'s strict `>`
comparison against `miter_limit^2 * 4` can never trigger for an infinite
limit. First step: verified my OWN reference solution does NOT have this bug
- `compute_arcs_join`/`compute_arcs_join_polyline` have no finiteness check
anywhere (confirmed via `grep -n "is_finite" stroke.rs` and a direct probe:
`compute_arcs_join(..., f32::INFINITY, ...)` matches `compute_arcs_join(...,
1e6, ...)` exactly, and the full tessellator reaches the peak at `mesh_dist=0`
for an infinite limit). The bug was in the CANDIDATE, not my solution; the
real gap was that my hidden test suite never exercised this input, letting a
wrong candidate pass.

Added 3 tests closing this: `compute_arcs_join_and_polyline_treat_infinite_
miter_limit_as_never_exceeded` (standalone helpers), `arcs_tessellator_
treats_infinite_miter_limit_as_never_exceeded` (fixed-width), `arcs_variable_
width_treats_infinite_miter_limit_as_never_exceeded` (variable-width). Caught
a real bug in my OWN first draft of the variable-width test while writing it:
used `half_width=2.0` instead of the correct `1.0` (base width 1.0 x
attribute 2.0 x 0.5), inconsistent with the existing convention every other
variable-width test in the suite already uses for this exact fixture -
caught immediately by the test failing against my own correct solution,
fixed before proceeding. Mutation-confirmed the fix in isolation: replicated
the candidate's exact bug (added the same `!miter_limit.is_finite()` guard to
both standalone functions) and confirmed exactly one test fails
(`compute_arcs_join_and_polyline_treat_infinite_miter_limit_as_never_
exceeded`), none of the tessellator tests - proving each test targets its own
call site independently, matching how the candidate's bug was actually
structured (guard only in the standalone functions, not the tessellator's own
`arcs_join_position` call sites).

Traces to the already-stated meta.md fallback rule ("...or when the join
would exceed the same `miter_limit` threshold...") plus the repo-discoverable
fact that `with_miter_limit` accepts `INFINITY` - the same "repo-discoverable"
category already accepted for `miter_limit_boundary_matches_exceeds_
semantics`. No meta.md change needed.

**T3/T4: `arcs_tessellation_refines_with_tolerance_and_keeps_reaching_the_
peak` only required non-decreasing triangle count and peak proximity**, which
an implementation that always emits a fixed 2-segment peak-fan (completely
ignoring `StrokeOptions::tolerance`) could satisfy, since the peak is one of
that fan's own endpoints regardless of tolerance. Verified this concretely
before writing a fix: forced `num_subdivisions_1 = 0` and `num_subdivisions_2
= 0` in `tessellate_arcs_join` (simulating exactly the described bug - literal
2-segment fan, no refinement at any tolerance) and measured the mesh's
distance to an interior point of the true arc (one quarter of the way along a
fine-tolerance reference polyline, distinct from start/peak/end): 0.222,
comfortably outside `NEAR_SURFACE` (0.01). With the real, correct
implementation restored, the same interior point measured 0.00145 - roughly
150x closer, a decisive separation.

Added `arcs_tessellation_reaches_an_interior_arc_point_not_just_the_peak_at_
fine_tolerance`, kept the original (now-complementary, not contradictory)
triangle-count/peak test alongside it rather than replacing it. Mutation-
confirmed: the 0-subdivision mutant fails 15 tests total including this new
one (the mutation is more severe than the described bug alone, since it also
removes the fan-triangle at every span, not just refinement - expected
collateral from a blunt mutation instrument, not a problem). Traces to the
already-stated curvature-following-surface description plus the pre-existing
`StrokeOptions::tolerance` contract (documented as maximum approximation
distance), already relied on by the sibling `polyline_deviation_from_the_
curve_is_bounded_by_tolerance` test. No meta.md change needed.

**Bidirectional FP check re-verified explicitly for all 4 new tests** (not
assumed): Direction 2 confirmed individually above for each test against its
specific meta.md clause + repo fact. Direction 1 unaffected since no meta.md
sentences were added or removed this round - only tests were added, which can
only strengthen Direction 1, not regress it.

Suite is now 54 tests. 54/54 pass deterministically (3 runs), 185/185
baseline unaffected, both patches re-verified clean against BASE_COMMIT in a
fresh clone (both apply orders, no whitespace warnings, fails to compile with
27 errors without solution.patch as expected, `test.sh`'s NEW_TEST_NAMES
updated to 54 and byte-matched against a real compile). solution.patch is
unchanged from the prior round - no source fix was needed, since my reference
never had either bug; both fixes were pure test-coverage additions.
