# feedback.md — pyriemann-geodesic-curves

## Summary

Olympus submission adding `pyriemann.geometry.curve` (piecewise-geodesic curves through SPD/HPD
matrices) plus `CurveEmbedding` in `pyriemann.embedding`.

- Repo: https://github.com/pyRiemann/pyRiemann — BSD-3-Clause, 773 stars, Python, last commit
  2026-07-31, 62 open issues+PRs, 19k LOC.
- BASE_COMMIT: `733a46e8aca8edeb0c30fb1082e1b3718a3fc03b`
- Effective LOC (hook `human-effective`): **487** across 4 files (raw added 1104).
- New tests: **210** (190 geometry + 20 embedding), all fail on base, all pass with the solution.
- Base suite: 3590 passed / 1272 skipped, no regressions.

## Pick log (assumptions and choices, autonomous run)

- The user deferred the repo, so auto-discovery applied the standing "brand-new repo" preference:
  every repo under `Instructions/Task*/worktrees/`, `Aprroved/`, `problems/`, `rejected/` and
  `_shelved/` was excluded. pyRiemann appears in none of them.
- Screened and dropped before pyRiemann: kurbo / parry (linebender and dimforge churn daily, high
  exclusivity risk), findiff (508 stars but `compact.py` is a live workstream shipped in v0.13),
  ruptures (change-point detection is a shelved class — `rejected/augurs-offline-changepoint`),
  galois (471 stars, under the gate), hmmlearn (last commit 2024, recency gate), go-hep (253 stars),
  causal-learn and OpenFermion (suite wall-clock risk).
- Feature selection inside pyRiemann: geodesic regression was designed first and dropped, because the
  exact minimiser of the sum of squared Riemannian distances is not tractable in closed form and any
  practical algorithm (the linearised tangent-space iteration) fixes a different objective — that is a
  spec ambiguity, not a fair trap. Principal geodesic analysis was dropped because
  `examples/biosignal-ssvep/plot_classify_ssvep_pga.py` already implements it in the repo.
- The curve subsystem was chosen because its kernel (arc-length parameterisation plus nearest-point
  projection) is exactly specifiable, has closed-form oracles, and drives eight public surfaces.

## Exclusivity checks (run at pick time)

```
gh api repos/pyRiemann/pyRiemann -q .full_name          -> pyRiemann/pyRiemann (no redirect)
gh pr list    -R pyRiemann/pyRiemann --state all --search "geodesic"        -> transport / alpha work only
gh pr list    -R pyRiemann/pyRiemann --state all --search "trajectory"      -> 1 hit, an NLP demo example
gh pr list    -R pyRiemann/pyRiemann --state all --search "interpolation"   -> geodesic alpha arrays only
gh pr list    -R pyRiemann/pyRiemann --state all --search "regression"      -> SVR / KNN regressor only
gh pr list    -R pyRiemann/pyRiemann --state all --search "principal geodesic" -> PR #169, a PGA EXAMPLE
gh issue list -R pyRiemann/pyRiemann --state all --search "geodesic"        -> array-API issues only
```

No PR or issue proposes curves, arc-length parameterisation, projection onto a geodesic, curve
simplification, piecewise-geodesic fitting or the Frechet distance. The 12 open PRs all touch means,
inner products, transports, transfer learning and the array-API migration.

## Environment

- `olympus-base-python:latest` (Python 3.12.13) + `pip install pytest seaborn`, CPU-only torch from
  the PyTorch CPU index, then `pip install -e .`.
- torch is REQUIRED for a green vanilla suite: `tests/test_geometry_geodesic.py::
  test_geodesic_alpha_array_error_backend[numpy]` calls `to_backend(alpha, "torch")` unguarded, so
  without torch the repo's own suite is red (1 failed / 2557 passed). With CPU torch it is
  **3590 passed / 1272 skipped / 0 failed in 219 s** offline as uid 1000.
- `HOME` and `MPLCONFIGDIR` must be writable; `test.sh` exports both and forces `MPLBACKEND=Agg`.

## Design decisions worth recording

- Supported metrics are restricted to `euclid`, `logchol`, `logeuclid`, `riemann`. Those four give a
  strictly convex squared distance along a geodesic, so the nearest point is unique and the search
  converges. `wasserstein` and `thompson` were excluded deliberately (non-negative curvature and a
  Finsler metric respectively), and an unsupported name raises `ValueError`.
- The projection uses the closed form in the chart for the three flat metrics and a bracketed golden
  section for `riemann`. The bracket expands with a small probe step, not with the full doubling
  step: probing with the full step misses the minimiser whenever the function has already turned
  round inside the step, which silently clipped extrapolated positions in the first draft.
- `curve_tangent` is specified by the `exp_map` identity rather than by a norm, because `log_map`
  returns a whitened tangent vector while `innerproduct` whitens again, so `norm(log_map(...))` is not
  the geodesic distance in this repo.
- The zero-length rule is only reliably reachable for the flat metrics. Measured,
  `distance_riemann(A, A)` is about 3e-16 and for some seeds exactly 0.0, so an all-zero parameter
  assertion under `riemann` would be seed-dependent; the parameter test uses `euclid`, `logchol` and
  `logeuclid`. The interpolation half is metric-independent and is covered for all four.

## Iteration history

- R1 — first implementation (7 functions + the transformer): `human-effective` 237, far under the
  floor. Added `fit_curve`, `mean_curve`, `curve_length_between`, `insert_knot`, the coupling
  backtrack and the budget form of `simplify_curve`: 344.
- R2 — added the log-Cholesky chart, `curve_tangent`, step resampling and the monotone segment
  assignment: 397. Added the epsilon form of `fit_curve` and `split_curve`: **437**, clears the floor.
- R3 — first test run: 124 passed / 6 failed. Five were wrong expectations of mine (an arc-length
  share computed as 0.25 instead of 1/3, chord length confused with arc length in two resampling
  tests, a length-between value, a hand-guessed simplification result); one was a real spec problem
  (the zero-length rule is unreachable under `riemann`). Replaced the hand-guessed simplification
  expectation with an independent recursive brute-force oracle in the test file.
- R4 — style pass: flake8 clean on all new files, unused import removed.
- R5 — FP audit: dropped every `match=` pin on error messages (22 of them), since the description
  promises the error CLASS but never the wording, and closed three description gaps the tests relied
  on (`parameterization` accepted everywhere, the blanket "constraints are enforced with ValueError",
  and the two guards in `mean_curve` and `curve_distance`).
- R6 — mutation battery, 8 mutations. Seven were killed at once; the tie-break mutation killed
  nothing, so `test_tangent_at_a_knot_uses_the_lower_segment` was added to make the stated rule
  observable. Final: 136 tests, every mutation killed, 479 human-effective LOC.
- R7 — Test Fairness FAIL, 14 of 105 flagged, two real defects, both fixed.
  1. Twelve assertions compared returned index arrays with `indices.tolist() == [...]`, which silently
     requires a NumPy container. The description only promises "indices" and "index pairs", and the
     repo has no public routine returning selected indices, so a correct implementation returning a
     plain list would have failed. Every one now compares `list(indices) == [...]`, which accepts an
     ndarray, a list or a tuple. Same fix for the two `coupling` row assertions.
  2. `fit_curve` rejected `n_segments=0` and `epsilon=0`, and the tests asserted it, but the fit
     paragraph never stated either bound while the neighbouring resample and simplify paragraphs
     state theirs. Added "`n_segments` at least 1 and `epsilon` strictly positive" to the description
     rather than dropping the tests, and reclaimed the words elsewhere to stay under the cap.
  Took four of the five advisory coverage suggestions that add no new requirement: step-resampling a
  zero-length curve, uniform resampling at the original knot count, and the unsupported-metric and
  unknown-parameterisation guards reached through routines other than `curve_lengths`. Skipped the two
  tie-forcing suggestions: constructing an exact floating-point tie in the monotone assignment or in
  the Frechet backtrack would be brittle, and both rules are already pinned by mutations M6 and M8.
  Result: 140 tests, meta 994 words, flake8 clean, effective LOC unchanged at 479.
- R8 — took the second advisory round (tie-breaking coverage) after all. Every one of the four rules is
  already stated in the description, so the tests add no requirement; the only reason they had been
  skipped was brittleness, and that is solved by building the ties out of duplicated knots (identical
  inputs, so the scores are byte-identical) and Euclidean dyadic diagonal matrices (a point on a chord
  has residual exactly 0.0). Three of the four rules now have a killing discriminator; the monotone
  intermediate backtrack does not, for the same reason M8 did not, and is documented rather than
  pinned. Final: 144 tests, 479 effective LOC, meta 994 words.
- R9 — Test Fairness FAIL again, 3 of 112, all unstated conventions: the batch axis for a scalar
  interpolation parameter, the one-dimensional result of a single-matrix projection, and which side's
  tangent applies at an interior knot. All three are genuine contract choices, so the description now
  states them rather than the tests being relaxed; the tangent test in particular had to be kept,
  since it is the only discriminator that makes the lowest-numbered-segment rule observable, and
  deleting it would send mutation M8 back to zero kills. Reclaimed the words by shortening thirteen
  phrases, so meta sits exactly at the 1000-word cap. Added the three viable coverage tests (monotone
  constrained optimum, epsilon-mode cost minimality, uniform-parameterisation propagation through
  five routines) and documented why the other two are unreachable. Two validation runs were lost to
  scratch-directory races: my own script deleted and re-cloned a fixed path that a concurrently
  running session was also using, which produced one spurious base-mode failure. Fixed by giving each
  run a PID-unique work tree; re-run isolated, base mode is green. Final: 147 tests, 479 effective
  LOC, meta 1000 words, flake8 clean, every validation cell green.
- R10 — fourth advisory round, and it caught a real defect plus a wrong claim of mine. The defect:
  `_locate` flattened a two-dimensional parameter array instead of rejecting it, so the description's
  blanket ValueError promise did not hold for `interpolate_curve` and `curve_tangent`; fixed in the
  solution, not by weakening the prose. The wrong claim: I had asserted the Frechet secondary
  backtracking preference was unreachable because the bottleneck recurrence supposedly keeps the
  diagonal predecessor no worse than its neighbours. That was reasoning I never checked. A brute-force
  search over small integer-distance curves found instances immediately, so the preference is now
  pinned by a real fixture. Lesson for next time: prove an "unreachable" claim with a search before
  writing it down. Final: 150 tests, 483 effective LOC, meta 999 words, every validation cell green.
- R11 — fifth advisory round on a PASSing verdict; took all four, since each targets a sentence the
  description already carries. Two are behavioural and mutation-proven (forcing monotone parameters to
  be non-decreasing, and swapping the simplify/resample order behind labelled group means). One is
  deliberately weak: `tol` and `maxiter` are asserted only to be accepted and to leave a converged
  answer alone, because the flat metrics use a closed form and legitimately ignore them, so demanding
  a visible effect would re-introduce the over-specification earlier rounds removed. The last simply
  makes the two "every routine" validation tests honest: 11 routines for the metric guard, 8 for the
  parameterization guard. Final: 153 tests, 483 effective LOC, meta 999 words, everything green.
- R12 — Test Fairness FAIL, 4 of 125, and every one of them was self-inflicted by R11. Satisfying the
  `tol`/`maxiter` advisory made me assert those keywords on three routines the description assigns
  them to nowhere, and the validation-breadth advisory made me require `curve_tangent` to reject a 2-D
  parameter array when only `interpolate_curve` is restricted to scalar-or-1D. Both narrowed to what
  the prompt actually says. **The lesson is about the advisories themselves: a coverage suggestion is
  safe only when the behaviour it names is already stated for the routine it names.** Widening a test
  to "every routine" is precisely how an unstated signature gets pinned. Added the two safe advisories
  (negative criteria, estimator validation) and kept the estimator test agnostic about whether the
  error surfaces at fit or at transform. Final: 155 tests, 483 effective LOC, meta 999 words, green.
- R13 — sixth advisory round on a PASSing verdict; all four suggestions named routines the description
  covers, so all four were taken. The HPD-breadth one was the interesting one: it could have exposed a
  real-only operation in the new layer (the log-Cholesky chart takes a real logarithm of the Cholesky
  diagonal), and complex knots pass under every metric. Also corrected a number I had asserted twice
  without measuring: `distance_riemann(A, A)` is about 3e-16, not 1e-8, and is exactly zero for some
  seeds, which changes the reason the zero-length parameter test skips `riemann` from "never zero" to
  "seed-dependent". Final: 165 tests, 483 effective LOC, meta 999 words, every validation cell green.
- R14 — seventh advisory round. Took the malformed-knot sweep (now 13 routines), the epsilon-mode
  simplification tie, and the HPD breadth pass through tangent, simplification, fitting, distance,
  mean and the estimator. Declined two, each with a reason rather than a shrug: the epsilon-mode
  `fit_curve` tie shares the exact line mutation T2 already pins and no symmetric fixture produced two
  minimal cuts of equal cost, and the search-control suggestion cannot be satisfied fairly because
  three of the four metrics answer in closed form and legitimately ignore `tol` and `maxiter`. Final:
  180 tests, 483 effective LOC, meta 999 words, every validation cell green.
- R15 — eighth advisory round, and the useful outcome was being wrong twice. The epsilon-mode
  `fit_curve` tie I had twice called unconstructible: an exhaustive search over short integer curves
  found `[1, 2, 2, 1]` at epsilon 0.5 in seconds, with two zero-cost minimal cuts. The zero-length
  `riemann` parameters I had called seed-dependent: they are exactly zero whenever the knot is a
  scalar multiple of the identity, which is structural, not luck. Both are now covered, and mutations
  T2 and S1 confirm the new tests bite. The standing rule from the Frechet round earns its keep: any
  "cannot be built" claim gets a search before it gets written down. Final: 183 tests, 483 effective
  LOC, meta 999 words, every validation cell green.
- R16 — ninth advisory round, and it found two real bugs. Projecting onto a degenerate geodesic
  (`A == B`) returned 0 for the flat metrics but garbage from the golden section for `riemann`; every
  position minimises there, so it was unspecified rather than incorrect, but the inconsistency is now
  removed and pinned. Step resampling under `parameterization="uniform"` converted the step to a
  fraction of arc length and then read it as a uniform parameter, so the knots were not a step apart
  in length, contradicting the description; step mode is now arc-length based whatever the
  parameterization. The `mean_curve` size rule was already enforced and only needed a test plus a
  one-word widening of the description ("combined or compared"). Final: 193 tests, 487 effective LOC,
  meta exactly 1000 words, every validation cell green.
- R17 — Test Fairness FAIL, 1 of 139: the omitted-argument default of `monotone` was asserted but never
  stated. Added "`monotone` is False by default" to the description rather than deleting the
  assertion, because that default silently underpins every other `project_on_curve` expectation.
  Took the two advisories the description already covers (zero-length count resampling, `step = 0`)
  and declined the two it does not extend to the named routine (single unbatched `X` for
  `project_on_curve`, channel-mismatch through projection and the estimator) - the same discipline
  that caused the round-four regression when I ignored it. Final: 198 tests, 487 effective LOC, meta
  998 words, every validation cell green.
- R18 — tenth advisory round. Two suggestions I had declined twice on the "not stated for this routine"
  rule came back, and the rule was being applied too literally: when the behaviour is real, already
  implemented and useful, the fix is to extend the description rather than to keep refusing the test.
  Both are now stated and covered (single unbatched `X` for `project_on_curve`, and the same-size rule
  widened to cover probes measured against a curve). The search-control suggestion is declined a fourth
  time and stays declined for a reason that does not weaken with repetition: three metrics answer in
  closed form and correctly ignore the controls, so the only way to make the assertion testable is to
  prescribe the search algorithm in the prompt. The test was renamed to `..._are_accepted` because the
  reviewer is right that it never proved forwarding. Final: 200 tests, 487 effective LOC, meta 999
  words, every validation cell green.
- R19 — Test Fairness FAIL, 1 of 140, and it was the search-control test I had defended four times.
  My defence had always been about whether the controls can be shown to *act*; the flag was about
  something else entirely, that the test pinned an unstated default *accuracy* by comparing the
  default call to `tol=1e-13` within 1e-5. The repository's own iterative defaults run from 1e-3 to
  1e-14, so a loose default is legitimate and the comparison was never fair. Cut it; the test now
  asserts only shape, finiteness and the clipped range. Lesson: defending a test across rounds made me
  answer the objection I expected instead of reading the one that arrived. Took both advisories
  (zero-length tangent over all metrics and HPD, malformed geodesic endpoints), the latter after
  adding "`A` and `B` are square and the same size" to the description. Final: 206 tests, 487
  effective LOC, meta 1000 words, every validation cell green.
- R20 — eleventh advisory round, all three taken and none needing a description change, because the
  contracts were already there: the same-size endpoint clause added last round, the blanket defaults
  sentence, and the deliberately opposite comparisons in the simplification and fitting rules. The
  epsilon-boundary fixture is the neat one: one Euclidean curve whose interior deviation is exactly
  2.0 pins "exceeds epsilon" for simplification and "within epsilon" for fitting in the same test.
  Final: 210 tests, 487 effective LOC, meta 1000 words, every validation cell green.
- R21 — twelfth advisory round. Tightened the Frechet coupling structure test so a two-index jump is
  rejected, proven by mutation C1. And after five rounds of declining the search-control suggestion on
  the grounds that no fair test exists, I finally checked the other direction: the description claimed
  `tol` and `maxiter` "bound the search" while nothing asserted that, which is description-side
  over-specification. Reworded to "are accepted search controls", matching what the test actually
  checks. Final: 210 tests, 487 effective LOC, meta 1000 words, every validation cell green.
