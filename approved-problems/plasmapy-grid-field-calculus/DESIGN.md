# DESIGN — plasmapy-grid-field-calculus

## 1. Title

Add exact field calculus to Cartesian grids.

## 2. Shape

O-Algorithm-correctness. The difficulty is getting a family of derived quantities to agree
exactly with one continuous field, not in the breadth of the API. Every method shares a single
kernel (the multilinear interpolant of a `CartesianGrid`), and the derived quantities are tied to
each other by Stokes' theorem, the divergence theorem, conservation under deposition, and
consistency between resolutions.

## 3. Repo and base commit

`PlasmaPy/PlasmaPy`, BSD-3-Clause, 703 stars, Python, 39 MB, active (last commit 2026-08-06).
Base commit `02d1c194a5b054516167b24503abe27b4e77825d`.

Pick-filter results:

| Gate | Result |
| --- | --- |
| Language / license / stars / activity | Python, BSD-3-Clause, 703, commits through 2026-08-06 |
| Corpus dedup | no PlasmaPy problem anywhere in `Aprroved/`, `rejected/`, `problems/`, `Task*/problems/`; no plasma-physics or grid-calculus problem in the corpus |
| Exclusivity (PR + issue, all states) | no PR or issue implements grid vector calculus or grid integration; the PRs that touch `grids.py` interpolation are performance work (#1295, #2226, #2911) and bug fixes (#1173, #2475) |
| Branch enumeration | `magnetic-topology` carries `magnetic_skeleton.py` (field-line tracing and separatrices); that whole feature class was avoided |
| Cold code | `grids.py` and `nullpoint.py` have had no substantive commit since 2025; every 2026 touch is a lint, lock-file or pre-commit sweep |
| Environment | vanilla suite green offline in 72 s in `olympus-base-python`, 4845 passed / 30 skipped, once the NIST stopping-power file is warmed into the image cache |
| Flakiness | new tests 5x identical, base mode 3x identical, no RNG without a fixed seed, no timing, no network |

## 4. Public API

All on `AbstractGrid`, implemented for uniformly spaced grids and raising `NotImplementedError`
otherwise: `gradient`, `divergence`, `curl`, `line_integral`, `circulation`, `surface_flux`,
`net_flux`, `box_integral`, `box_mean`, `volume_integral`, `deposit`, `remap`.

## 5. Canonical form

- The field is the multilinear interpolant of the stored grid points, which is exactly what
  `volume_averaged_interpolator` already returns.
- A position on a boundary between cells belongs to the cell above; the outer edge belongs to the
  last cell.
- Lengths in every result are metres, whatever units the axes carry.
- The three components of a vector field must carry the same unit; convertible is not the same.
- Positions off the grid are not-a-number; parts of a path, rectangle or box off the grid
  contribute nothing.

## 6. Why the obvious implementation is wrong

The natural first move is to treat the stored arrays as the object of study: `np.gradient` for
derivatives, `sum(values) * cell_volume` for integrals, sampled quadrature along a path. Each is
wrong in a way that only shows up on a discriminating fixture:

1. `np.gradient` gives central differences at grid points. On a field that is linear in each
   variable separately those agree with the interpolant at the nodes but not inside a cell, where
   the interpolant's derivative varies.
2. The plain sum times the cell volume is the rectangle rule; the exact integral of the
   interpolant is the trapezoid rule, which halves the faces, quarters the edges and eighths the
   corners.
3. Along a straight line the interpolant is a cubic in each cell but only piecewise smooth across
   cells. Simpson's rule is exact per cell and wrong if the segment is not split at every cell
   crossing first.
4. A path, rectangle or box that reaches past the grid must be clipped, and a mean must be taken
   over the overlap only.

## 7. File footprint

| File | Raw added | Human-effective |
| --- | --- | --- |
| `src/plasmapy/plasma/_grid_calculus.py` | 424 | 226 |
| `src/plasmapy/plasma/grids.py` | 535 | 226 |
| `changelog/3600.feature.rst` | 13 | 13 |
| Total | 972 | 465 |

## 8. Solution outline

`_grid_calculus.py` holds the kernels, all in SI units on bare arrays.

- `_cell_index`, `_local_coordinates`, `_outside` locate a position and give its local
  coordinates; this is the single place the tie rule lives.
- `_corner_weights` and `_corner_weight_derivatives` give the eight multilinear weights and their
  derivatives, which `evaluate`, `gradient` and `deposit` all use.
- `_hat_values` and `_hat_integrals` express the field as a sum over nodal basis functions, so any
  integral over an axis-aligned region becomes a contraction of the nodal values against per-axis
  weight matrices. `box_integral`, `surface_flux` and `remap` are three contractions of the same
  kernel; `remap` uses the batched form over every target node at once.
- `_segment_bounds` and `_segment_breaks` clip a segment to the grid and split it at cell
  crossings; `_integrate_segment` applies Simpson's rule per piece, which is exact because the
  restriction of a multilinear field to a line is a cubic. `line_integral` and `circulation`
  differ only in the weight applied to the sampled field.
- `deposit` is the transpose of `evaluate` and reuses its weights.

`grids.py` holds validation, unit handling and the public methods.

## 9. Predicted traps

1. **The field, not the samples.** The whole contract is that results describe the interpolant.
   Naive finite differences and rectangle sums pass on constants and at nodes and fail inside a
   cell. Misdirecting: the failure looks like a tolerance problem, not a wrong object.
2. **Piecewise smoothness along a line.** A single Simpson or a fine sampled quadrature over a
   whole segment is close but not exact; splitting at cell crossings is the only route to the
   asserted tolerance. This trap is only testable on rough nodal data: on a globally multilinear
   field the interpolant is one global cubic along any line, so a non-splitting implementation is
   exact there. The rough-data path tests are what carry it.
3. **Clipping and the tie rule interact.** The clipped ends of a segment lie exactly on cell
   boundaries, so the tie rule decides which polynomial evaluates them. Getting the tie rule
   wrong shows up as a wrong integral, not as a wrong cell.
4. **Trapezoid weights on the grid.** `volume_integral` of a constant field is the grid volume
   only if the boundary nodes are down-weighted.
5. **Deposition is the transpose, not a nearest-neighbour scatter.** A nearest-neighbour deposit
   still conserves the total, so conservation alone does not catch it; the transpose identity
   does.
6. **`remap` averages, it does not sample.** Remapping onto the same axes is deliberately not the
   identity.

Traps 1 to 4 are interdependent: every one of them lives in the single shared kernel, so a local
fix to the integral changes the gradient and the flux too.

## 10. Verification

- **Independent oracles.** A globally multilinear field is reproduced exactly by the interpolant,
  so closed-form gradients, antiderivatives and line integrals are exact references. Each was
  cross-checked against `scipy.integrate.quad`, `dblquad` and `tplquad` at 1e-13 tolerance before
  any test was written.
- **Invariant checks.** Stokes' theorem on a rectangle, the divergence theorem on a box,
  conservation and the transpose identity for deposition, agreement between two grid resolutions,
  and agreement between a grid in metres and the same grid in centimetres.
- **Mutation battery.** 16 mutations, all caught, against a control run that verifies the
  unmutated suite passes with the same flags. The control exists because an earlier harness passed
  an unrecognised pytest flag and reported every mutation as caught while running no tests. A
  seventeenth mutation was removed after Test Fairness showed it enforced behaviour the prompt does
  not require: a green battery certifies discrimination, not fairness.

## 11. Tier

Olympus. 465 human-effective LOC across 3 files, 209 F2P tests, single subsystem with a shared
kernel and cross-quantity invariants.

## 12. Open risk

The repository's own `nullpoint.py` already builds a trilinear approximation and its Jacobian for
a sampled vector space. That is a fair in-repo precedent for the derivative half of this problem
and will make `gradient`, `divergence` and `curl` easier than the integrals. The difficulty is
therefore concentrated in `line_integral`, `surface_flux`, `box_integral`, `remap` and `deposit`,
none of which has any precedent in the repository. If a batch lands above the pass ceiling, the
lever is composition, not more surface: fixtures where clipping, the tie rule and cell splitting
must all be right at once.
