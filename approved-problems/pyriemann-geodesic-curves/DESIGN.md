# DESIGN.md — pyriemann-geodesic-curves

Repo: https://github.com/pyRiemann/pyRiemann (BSD-3-Clause, 773 stars, Python, last commit 2026-07-31)
BASE_COMMIT: 733a46e8aca8edeb0c30fb1082e1b3718a3fc03b

## 1. Title

Add piecewise-geodesic curves through SPD matrices

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK Pattern 12): a new capability whose difficulty is a
  subtle numerical/geometric correctness kernel rather than breadth of API.
- Pass-rate target: <= 40% cap, designed for the corpus mode of ~1/10.
- Best agent: mixed (Orion decisive implement, Nova exploration).
- Dominant verdict expected: MISSED_REQUIREMENT / wrong logic on the projection kernel.

## 3. Public API surface

In `pyriemann.geometry.curve`:

- `curve_metrics` — `["euclid", "logchol", "logeuclid", "riemann"]`.
- `curve_lengths(C, *, metric)` -> `(n_knots-1,)` segment lengths.
- `curve_parameters(C, *, metric, parameterization)` -> `(n_knots,)` parameters in [0, 1].
- `interpolate_curve(C, s, *, metric, parameterization)` -> `(n_points, n, n)`.
- `resample_curve(C, n_knots=None, *, step=None, metric, parameterization)` -> `(n_knots, n, n)`.
- `curve_tangent(C, s, *, metric, parameterization)` -> `(n_points, n, n)` velocities.
- `project_on_geodesic(X, A, B, *, metric, clip, tol, maxiter)` -> `(n_matrices,)` positions.
- `project_on_curve(X, C, *, metric, parameterization, monotone, tol, maxiter)` -> `(s, d)`.
- `curve_length_between(C, s1, s2, *, metric, parameterization)` -> float.
- `insert_knot(C, s, *, metric, parameterization)` -> knots.
- `split_curve(C, s, *, metric, parameterization)` -> `(C1, C2)`.
- `simplify_curve(C, epsilon=None, *, n_knots=None, metric, tol, maxiter)` -> `(knots, indices)`.
- `fit_curve(X, n_segments=None, *, epsilon=None, metric, tol, maxiter)` -> `(knots, indices)`.
- `mean_curve(curves, *, metric, n_knots, parameterization)` -> knots.
- `curve_distance(C1, C2, *, metric, return_coupling)` -> float, or `(float, coupling)`.

In `pyriemann.geometry._check`: `check_knots(C)`.

In `pyriemann.embedding`: `CurveEmbedding(metric, parameterization, n_segments, epsilon, n_knots,
tol, maxiter)` with `fit(X, y=None)`, `transform(X) -> (n_matrices, 2)`, `inverse_transform(X)`,
attribute `knots_`.

## 4. Canonical output form

- Curve = ordered sequence of at least 2 SPD/HPD knots; consecutive knots joined by the geodesic of `metric`.
- Parameter of knot k = cumulated geodesic length up to k divided by total length ("arclength"), or
  `k / (n_knots - 1)` ("uniform"). First parameter 0, last 1.
- Degenerate curve (total length 0): every parameter is 0 under "arclength"; interpolation returns the
  first knot for any `s`.
- `s` outside [0, 1] is clipped.
- `s` falling exactly on a knot parameter resolves to the lowest-index segment ending at that knot.
- `project_on_geodesic` returns the position minimizing the distance to the geodesic; with `clip=True`
  the position is restricted to [0, 1], otherwise the whole geodesic line is searched.
- `project_on_curve` returns the curve parameter of the closest point over all segments, and that
  distance; ties resolve to the lowest-index segment.
- `simplify_curve` keeps first and last knots, and recursively keeps the interior knot farthest from the
  geodesic joining the current endpoints while that distance exceeds `epsilon`; ties on the farthest
  knot resolve to the lowest index; returned indices are sorted increasingly.
- `curve_distance` is the discrete Frechet distance between two knot sequences.
- Unsupported metric, fewer than 2 knots, non-square input, `n_knots < 2`, `epsilon <= 0` raise ValueError.

## 5. Blind-spot pre-empts

- Result ordering: "returned indices are sorted increasingly".
- Rule resolution: "the position minimizing the distance" (not the tangent-space approximation).
- Iteration termination: `tol` / `maxiter` named as convergence controls.
- Compound order: "knots are simplified before being resampled".
- Default ordering: "grouped by increasing value of y".
- Falsy/degenerate: zero-length curve and zero-length segment rules stated.

Codebase-inferable requirements: 1 (the repo's `distance`/`geodesic` metric names).

## 6. Description draft

See `meta.md`.

## 7. File footprint (measured)

| Action | Path | Raw added | human-effective |
| --- | --- | --- | --- |
| NEW | pyriemann/geometry/curve.py | 887 | 390 |
| MODIFY | pyriemann/embedding.py | 150 | 57 |
| MODIFY | pyriemann/geometry/_check.py | 30 | 11 |
| MODIFY | doc/api.rst | 25 | 21 |

TOTAL: 1092 raw / **479 human-effective** across 4 files, clearing the 430 gate.

## 8. Solution outline

- `check_curve_metric` / `check_knots` — validation.
- `curve_lengths` — per-segment geodesic distance.
- `curve_parameters` — cumulated normalized parameterization, both modes, degenerate case.
- `_locate` — segment index + local position for a parameter (tie-break, zero-length segment).
- `interpolate_curve`, `resample_curve` — evaluation on the curve.
- `_geodesic_at`, `_squared_distance_at` — vectorized evaluation of the geodesic and of the distance.
- `_project_closed_form` — exact projection for the flat metrics (euclid, logeuclid).
- `_bracket` — outward doubling of the search interval when `clip=False`.
- `_golden_section` — vectorized minimization of a strictly convex 1-D function.
- `project_on_geodesic`, `project_on_curve` — nearest point on a geodesic / on the curve.
- `simplify_curve` — Douglas-Peucker recursion driven by the projection kernel.
- `curve_distance` — discrete Frechet dynamic program.
- `CurveEmbedding` — sklearn transformer wiring knots, simplification, resampling, projection.

## 9. Test file outline

Path: `tests/test_geometry_curve_<hash>.py` + `tests/test_embedding_curve_<hash>.py`

Blocks: imports, builder helpers (diagonal SPD builders, exact log-domain oracles), assertion helpers,
granular tests grouped by requirement bucket:
lengths / parameterization / interpolation / resampling / projection on a geodesic /
projection on a curve / simplification / Frechet distance / CurveEmbedding / errors / HPD.

Oracles: closed form in the log domain for `logeuclid`; commuting (diagonal) matrices make `riemann`
coincide with that closed form; congruence invariance and first-order optimality for `riemann` in
general position.

## 10. Forced signatures

Keyword-only options after `*`, matching the repo convention (`metric`, `squared`, `sample_weight`).
`project_on_curve` returns a tuple of two arrays. `simplify_curve` returns a tuple (matrices, indices).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt | Test |
| --- | --- | --- | --- | --- |
| 1 | Projection under `riemann` computed with the tangent-space formula | The Euclidean formula is the obvious one and is exact for the flat metrics | "the position that minimizes the distance" | `project_riemann_noncommuting_is_optimal` |
| 2 | Parameterization by knot index instead of cumulated length | Index parameterization is simpler and passes on evenly spaced knots | "cumulated geodesic length divided by the total length" | `interpolate_uneven_segments_uses_arclength` |
| 3 | Simplification measuring distance to the neighbouring knots instead of the current chord | Douglas-Peucker is often written against the wrong endpoints | "geodesic joining the two endpoints of the part being simplified" | `simplify_keeps_second_pass_knot` |
| 4 | Discrete Frechet computed greedily | Greedy matching looks right on monotone curves | "discrete Frechet distance" | `curve_distance_needs_nonmonotone_coupling` |
| 5 | Unclipped projection not searching outside [0, 1] | Extrapolation requires expanding the bracket | "the whole geodesic is searched" | `project_geodesic_clip_false_extrapolates` |

## 12. Tier + category

Tier Olympus, sub-rank Good, category feature-request.

## 13. Predicted pass rate

10-25%. Levers stacked: one interdependent kernel (parameterization + projection) driving eight surfaces,
external oracle (closed form in the log domain, fuzzed against the iterative solver), three
interdependent+misdirecting traps, one "obvious code is wrong" edge (trap 1), every signature pinned.

## 14. Quality gate

All checked; see feedback.md for the running log.

## Why this is not a duplicate

Closest approved siblings: `metpy-parcel-trajectories` (trajectory integration in a meteorology library,
different repo, different mathematics: ODE integration versus manifold geometry) and
`scikit-bio-feature-hierarchy` (hierarchical structure, different repo and subsystem). No pyRiemann
submission exists locally in `Aprroved/`, `problems/` or `rejected/`. The repo has no PR or issue about
curves, paths, trajectories, interpolation or projection (searches logged in feedback.md).

Predicted iteration cycles: 2
