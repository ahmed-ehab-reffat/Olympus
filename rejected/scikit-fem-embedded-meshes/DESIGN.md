# DESIGN.md — scikit-fem-embedded-meshes

## 1. Title

Add meshes embedded in a higher-dimensional ambient space

Repo: `kinnala/scikit-fem` (BSD-3, 657 stars, Python, last source commit 2026-09-04).
Base commit: `73e8357003d67ce267f39c74356a8f045bae99ab`.
Verb: Add -> `feature-request`.

## 2. Shape classification

- Shape: **O-Composite-extend** (SHAPES.md § Pattern 12: refactor an existing aggregation across
  packages). The capability is not a new module; it is the two `Mapping` classes, the `Mesh`
  validation/geometry helpers, the meshio ingestion path and the finders all learning that the
  point array may have more rows than the reference domain, with every basis riding the result.
- Pass rate target: <= 40% sprint cap, designed for the corpus mode of 1-3/10.
- Best agent: Orion (long-horizon, the corpus lone-passer profile).
- Dominant verdict expected: REGRESSION (base suite) and MISSED_REQUIREMENT (rigid-motion law,
  co-normals, isoparametric parity).
- Solver/our LOC ratio: ~1.3x (agents generalise per dimension-branch; the reference factors
  through one pseudo-inverse helper).

## 3. Public API surface

No new public names are introduced. Every assertion goes through existing entry points whose
BEHAVIOUR changes:

- `Mesh(doflocs, t)` for `MeshLine1`, `MeshTri1`, `MeshTri2`, `MeshQuad1`, `MeshQuad2` — a
  point array with more rows than the element's reference dimension is a valid mesh
  (`Mesh.is_valid()` returns True); fewer rows stays invalid. `Mesh.dim()` keeps returning the
  reference dimension; the ambient dimension is the row count of `mesh.p`.
- `Mesh.mapping()` -> `MappingAffine` / `MappingIsoparametric` with `F`, `invF`, `DF`, `invDF`,
  `detDF`, `G`, `detDG`, `normals` all defined for rectangular Jacobians.
- `Basis` / `CellBasis(mesh, elem)` on an embedded mesh: `dx` integrates with the manifold's
  measure; `grad` of every H1 basis function is the tangential gradient with ambient components;
  `default_parameters()['x']` has ambient rows; `['h']` is measure to the power one over the
  reference dimension (unchanged formula).
- `FacetBasis(mesh, elem, facets=...)` on an embedded mesh: integrates over the manifold's
  boundary with the boundary's own measure; `default_parameters()['n']` is the outward unit
  co-normal (tangent to the manifold, perpendicular to the boundary).
- `InteriorFacetBasis` on an embedded mesh: jumps across interior facets of the manifold.
- `Mesh.element_finder()`, `CellBasis.probes(x)`, `CellBasis.interpolator(y)` accept ambient
  coordinates (one positional array per ambient axis for the finder, an ambient-by-n array for
  probes) for points on the manifold.
- `MeshLine1.param()`, `Mesh2D.param()/params()` measured in the ambient space.
- `Mesh.translated`, `scaled`, `mirrored` act on every ambient coordinate.
- `skfem.io.meshio.from_meshio` / `Mesh.load`: coordinates a mesh actually uses are kept; the
  trailing coordinates are stripped only when they are all zero (the meshio padding case).
- `Mesh.trace(facets, mtype=...)` without `project`: the result is an embedded mesh of the facet
  type that all of the above accept.
- `MeshTri2.from_mesh(MeshTri1 in R^3)` / `MeshQuad2.from_mesh`: second-order embedded meshes.
- `ElementVector(elem, dim=k)` with `k` the ambient dimension: vector fields with ambient
  components on an embedded mesh (already accepts `dim`; the contract only states it works).
- `ElementHcurl` / `ElementHdiv` on an embedded mesh: Piola transformations through the
  rectangular Jacobian (values tangent to the mesh; `div`/`curl` scalars per measure).
  `ElementGlobal` (Morley, Argyris, ...): `NotImplementedError`.
- `MeshSimplex.orientation()` on an embedded mesh: +1/-1 relative to the first element through
  neighbour chains; `oriented()` flips the -1 elements; `ValueError` when no consistent
  orientation exists (Moebius strip). Square meshes keep the determinant-sign semantics.
- `CellBasis.default_parameters()['n']` on a curve in the plane or a surface in space: unit
  normal induced by vertex order (tangent turned clockwise / cross product of the two edges from
  the first vertex). Absent for curves in space and for square meshes.
- `Mesh.trace(facets)` with no `mtype`: returns `MeshLine1` / `MeshTri1` / `MeshQuad1` by facet
  type (was the bare `Mesh`).

- `Mesh.smoothed()` on an embedded mesh: each free vertex moves only within the tangent space
  of the mesh at that vertex (span of the dominant directions of the neighbouring elements'
  tangent projectors); commutes with rigid motions; a flat patch stays flat. Line meshes get
  `smoothed` for the first time (base indexes `facets[1]` and crashes).
- `Mesh.trace(facets)`: named boundaries meeting the traced facets become named subdomains.

Added after the first two LOC measurements (135, then 190 human-effective): the orientation
propagation, the induced normals, tangential smoothing, the trace default and trace tags are
genuine behaviour named in meta.md, each riding the same rectangular-Jacobian kernel
(`pinv`/`DF`).

## 4. Canonical output form

- Measure: `sum(basis.dx)` equals the length of a curve mesh / the area of a surface mesh
  (exact for polylines and flat facets; to quadrature accuracy for curved second-order meshes).
- Gradient: for `u` the restriction of an affine function `a . x + c` of the ambient coordinates
  to a flat element, `grad(u)` at every quadrature point equals `a` minus its component along the
  element's normal space (the orthogonal projection of `a` onto the element's tangent space).
  Shape of `grad` is (ambient, nelems, nqp) for scalar elements.
- Inverse mapping: for a global point lying on element `t`, `invF(x, tind=t)` returns its
  reference coordinates (least-squares preimage); `F(invF(x)) == x` to 1e-10 on the manifold.
- Co-normal: unit length, orthogonal to the boundary facet's tangent(s), lying in the element's
  tangent space, pointing away from the element interior. For a curve mesh the boundary facets
  are its endpoints and the co-normal is the outward unit tangent.
- Rigid-motion law: applying any rotation, reflection or translation of the ambient space to
  the point array leaves every assembled matrix and vector, `basis.dx`, `h`, and the norms of
  `grad` unchanged to 1e-12 relative; `x` and `n` transform with the motion.
- Flat-embedding law: a mesh whose points all lie in a coordinate subspace assembles to the
  same matrices as the lower-dimensional mesh with the zero coordinates removed.
- Dual-path law: for facets `F` of a 3-D mesh `m`, `FacetBasis(m, e, facets=F)` and
  `CellBasis(m.trace(F, mtype=<facet mesh type>)[0], e_facet)` assemble the same scalar
  functionals and the same measure.
- meshio stripping: trailing coordinate rows are dropped only when every entry is zero; a
  planar mesh at `z = 0` stays 2-D (baseline), a planar mesh at `z = 1` or a tilted plane keeps
  three rows.
- Empty / degenerate: an element whose Jacobian has dependent columns (zero measure) raises the
  existing "Zero Jacobian determinant" (isoparametric) / produces `inf` in `invDF` (affine) —
  unchanged from the square case; not tested.
- Fewer rows than the reference dimension: `is_valid()` False, `is_valid(raise_=True)` raises
  `ValueError` (unchanged message).

## 5. Blind-spot pre-empts

- Rule resolution / parallel API: "Both the affine mapping used by simplex meshes and the
  isoparametric mapping used by quadrilateral and second-order meshes support this."
- Pipeline placement: "`Mesh.dim()` keeps meaning the reference dimension; the ambient dimension
  is the number of rows in the point array."
- Unstated inverse: "the trailing coordinates are stripped only when they are all zero."
- Adjacent-vs-all: "every geometric quantity a mesh or basis reports is measured in the ambient
  space" (covers `param`, finders, `x`, `h`, `n`).
- Falsy-on-invalid: "elements that need a Piola transformation, and the orientation of simplex
  meshes, are not supported on embedded meshes and raise NotImplementedError."

Exactly one codebase-inferable requirement: the finder's calling convention (one positional
array per ambient axis), inferable from `CellBasis.probes` calling `element_finder(...)(*x)`.

## 6. Description draft (meta.md body, ~330 words)

Add meshes embedded in a higher-dimensional ambient space to scikit-fem, so that a line mesh
may live in the plane or in space and a triangle or quadrilateral mesh, first or second order,
may live in space. Today `Mesh.is_valid` rejects a point array with more rows than the
element's reference dimension, the affine and isoparametric mappings assume a square Jacobian,
and `from_meshio` strips every coordinate beyond the reference dimension, so a surface loaded
from a file loses its third coordinate silently.

Such a mesh is valid whenever the point array has at least as many rows as the reference
dimension; `Mesh.dim()` keeps meaning the reference dimension and the ambient dimension is the
number of rows in the point array. Both the affine mapping used by simplex meshes and the
isoparametric mapping used by quadrilateral and second-order meshes support it, including the
inverse mapping of a point lying on the mesh. A cell basis integrates with the measure of the
curve or surface itself, and the gradient of a basis function is the tangential gradient, with
one component per ambient coordinate, so a form written with `grad` assembles the
Laplace-Beltrami operator. A facet basis integrates over the boundary of the curve or surface
with that boundary's own measure, and the normal it supplies to forms is the outward unit
co-normal: tangent to the mesh and perpendicular to the boundary. Interior facet bases,
element finders, probes and interpolators, mesh parameters and the geometric helpers such as
`param`, `translated`, `scaled` and `mirrored` all work in the ambient space. Assembly on an
embedded mesh is unchanged by any rigid motion of the ambient space, and a mesh whose points
all lie in a coordinate subspace assembles exactly what the lower-dimensional mesh does.

`from_meshio` and `Mesh.load` keep the coordinates a mesh actually uses; trailing coordinates
are dropped only when they are all zero. `Mesh.trace` called with a mesh type and no projection
returns an embedded mesh of the facet type, and integrating over those facets with a facet basis
of the original mesh agrees with integrating over the trace with a cell basis. Vector-valued
elements take their component count from `ElementVector`'s `dim` argument as before. Elements
that need a Piola transformation, and the orientation of simplex meshes, are not supported on
embedded meshes and raise `NotImplementedError`.

Rule-7 audit: no instance lists of which functions were wrong; the rigid-motion and
flat-embedding sentences are LAWS (P1), not walls; no worked example; the meshio rule is stated
because it is a contract change on an existing path (fairness floor, L29/L30).

## 7. File footprint (measured on the shipped solution.patch, 2026-09-10)

| Action | Path | Raw added | Human-effective | Reason |
|---|---|---|---|---|
| MODIFY | skfem/mapping/mapping.py | 65 | 47 | `det`/`inv` (closed forms moved here from the two mapping classes), `gram`, `measure`, `pinv` |
| MODIFY | skfem/mapping/mapping_affine.py | 16 | 16 | `A` (amb x ref), `B` (amb x ref-1), `measure`/`pinv`, `normals` from `refdom.normals` |
| MODIFY | skfem/mapping/mapping_isoparametric.py | 15 | 14 | J (amb x ref), `detDF`/`invDF`/`detDG` through the helpers, `F`/`G` over ambient rows, `invF` start of reference shape |
| MODIFY | skfem/mesh/mesh.py | ~75 | ~62 | `is_valid` (rows >= ref), generic `strip_extra_coordinates`, `mirrored`, `_induced_signs` + `_relative_orientation` (parity propagation), `_tangent_projectors` + tangential `smoothed`, `trace` default type + boundary tags |
| MODIFY | skfem/mesh/mesh_simplex.py | 10 | 8 | `orientation` dispatch; `oriented` unchanged for square meshes |
| MODIFY | skfem/mesh/mesh_quad_1.py | ~25 | ~20 | `orientation` (centre determinant / relative) and `oriented` (reverse the vertex cycle) |
| MODIFY | skfem/mesh/mesh_line_1.py | 35 | 29 | `param` via ambient norms, mapping-based `element_finder`, no strip override |
| MODIFY | skfem/mesh/mesh_tri_1.py | 9 | 8 | finder over ambient rows with a surface-distance check |
| MODIFY | skfem/mesh/mesh_2d.py | 0 (-4) | 0 | strip override removed |
| MODIFY | skfem/assembly/basis/cell_basis.py | 17 | 14 | `n` in `default_parameters` on hypersurfaces, `normals()` |
| MODIFY | skfem/element/element_global.py | 3 | 3 | raise on embedded meshes |
| MODIFY | skfem/element/element_hcurl.py, element_hdiv.py | 0 | 0 | (no change needed once `invDF` is a pseudo-inverse; the design's planned guards were dropped) |

TOTAL (final patch): 298 raw / **241 human-effective** (hook `effective_loc_check.py`; padding-floor
203) / 269 counter-1 across 11 files, 4 packages. Two earlier measurements: 135 (mapping-only slice) and
190 (+ orientation, normals, trace default) — the machinery-absorption law bit twice: the
closed-form inverse and Gram helpers made the mapping generalisation a ~50-line change.

## 8. Solution outline — helpers

- `_gram_det(J) -> ndarray` — sqrt(det(J^T J)) for J of shape (amb, ref, ...), with the existing
  1/2/3 closed forms on the ref x ref Gram matrix <- "integrates with the measure of the curve
  or surface itself"
- `_pinv(J) -> ndarray` — (J^T J)^-1 J^T of shape (ref, amb, ...) <- "the gradient is the
  tangential gradient with one component per ambient coordinate"
- `MappingAffine._init_Ab` — A (amb, ref, nt); `_init_invA` — `_detA = _gram_det(A)` (signed
  det kept when square so `orientation()` keeps its sign), `_invA = _pinv(A)`
- `MappingAffine._init_boundary_mapping` — B (amb, ref-1, nf), `_detB = _gram_det(B)` with the
  0-dimensional facet case returning ones <- "boundary with that boundary's own measure"
- `MappingAffine.normals` — `Nref = self.mesh.elem.refdom.normals`, then the existing
  `einsum('ijkl,ik->jkl', invDF, N)` yields the co-normal because `invDF` is now the
  pseudo-inverse <- "outward unit co-normal"
- `MappingIsoparametric.DF/detDF/invDF/detDG/G` — J built as `[[J(i,j)] for i in range(amb)]
  for j in range(ref)]`; `detDF` square fast path else `_gram_det`; `invDF` via `_pinv`
- `MappingIsoparametric.invF` — unchanged loop; the einsum with a (ref, amb) `invDF` is the
  Gauss-Newton step; convergence test unchanged <- "the inverse mapping of a point lying on the
  mesh"
- `Mesh.strip_extra_coordinates(p)` — generic: while `p.shape[0] > refdom.dim()` and the last
  row is all zero, drop it <- "trailing coordinates are dropped only when they are all zero"
- `Mesh.is_valid` — `doflocs.shape[0] < refdom.dim()` is the invalid condition
- `MeshLine1.element_finder` — kd-tree on element midpoints, `invF` of candidates, inside test
  `-eps <= X <= 1 + eps`, fallback to all elements, `ValueError` outside <- "finders accept
  ambient coordinates"
- `MeshLine1.param` — `max(norm(p[:, t[1]] - p[:, t[0]]))`
- `MeshSimplex.orientation` — raise when `p.shape[0] != refdom.dim()`
- Piola elements — raise when `mapping.mesh.p.shape[0] != mapping.mesh.dim()`

No fixpoint loop; the only iteration is the existing Newton in `invF`.

## 9. Test file outline

Path: `tests/test_embedded_<hex>.py` (single new file, pytest functions + parametrize, matching
`tests/test_mesh.py` / `tests/test_basis.py` style; no comments in bodies).

Block 1 — imports: numpy, pytest, `assert_allclose`, skfem meshes/elements/bases, `asm`,
`BilinearForm`, `LinearForm`, `Functional`, `dot`, `grad`, `from_meshio`/`to_meshio`, meshio.
Block 2 — builder helpers (~15 one-liners): `line_in_plane(n)`, `arc_in_plane(n)`,
`line_in_space(n)`, `tri_on_plane(z)`, `tri_tilted(theta)`, `quad_tilted`, `tri2_on_cylinder`,
`quad2_on_paraboloid`, `rotate(m, R)`, `random_rotation(seed)`, `tet_cube()`, `hex_cube()`,
`mass(basis)`, `stiff(basis)`, `boundary_len(fbasis)`.
Block 3 — assertion helpers: `assert_matrices_close(A, B, rtol)`, `assert_tangential(g, a, n)`.
Block 4 — buckets:
  - validity: rows >= ref valid (5 mesh types), rows < ref invalid, `dim()` unchanged (F-9)
  - measure: line in R2/R3, arc, tilted triangle/quad, cylinder patch (MeshTri2), paraboloid
    (MeshQuad2) — `sum(dx)` vs analytic
  - tangential gradient: affine-function restriction on tilted planes, affine + isoparametric,
    scalar + `ElementVector(dim=3)`; Laplace-Beltrami stiffness on a tilted plane equals the
    flat stiffness
  - rigid-motion law: 6 seeded rotations x {line-in-R2, tri-in-R3, quad-in-R3, tri2-in-R3} x
    {mass, stiffness, load, `h`} (P1 property sweep, fixed seeds)
  - flat-embedding law: z=0 tri in R3 vs MeshTri; y=0 line in R2 vs MeshLine
  - inverse mapping / finder / probes / interpolator: points on tilted plane and on the arc;
    `F(invF(x)) == x`; interpolate a linear function exactly; `MeshLine` finder on a curve where
    the first coordinate does NOT order the elements (the old digitize would be wrong)
  - facet basis: boundary length of a tilted patch; co-normal unit, tangent to plane,
    perpendicular to the boundary edge, outward (dot with centroid direction > 0); curve
    endpoints' co-normals are outward tangents; `InteriorFacetBasis` jump of a linear function
    is zero and of a discontinuous P0 field is the difference
  - dual-path law: tet cube boundary facets via `FacetBasis` vs `trace(mtype=MeshTri)` +
    `CellBasis`; hex cube via `MeshQuad`; a Functional of `x` and the measure agree
  - meshio: z=0 triangle mesh stays 2 rows (baseline), z=1 planar keeps 3, tilted keeps 3,
    round-trip `to_meshio`/`from_meshio` of an embedded mesh preserves points
  - geometric helpers: `param` of a diagonal line, `translated/scaled/mirrored` in R3 on a tri mesh
  - not supported: `ElementTriRT0`-style Hdiv and `ElementTriN1` on tri-in-R3 raise
    `NotImplementedError`; `MeshTri(...).oriented()` in R3 raises
  - baseline: `MeshTet`/`MeshHex`/planar `MeshTri` matrices unchanged vs pinned values

Test count anchor: ~70-90 (O-Composite-extend precedent 162 is breadth we deliberately avoid).

Per-atom decomposition of the key sentences:
  - "valid whenever rows >= reference dim" -> valid(=), valid(>), invalid(<), dim() unchanged
  - "trailing coordinates dropped only when all zero" -> all-zero dropped, nonzero-constant
    kept, tilted kept, 1-D line in 3-D file with y=z=0 -> 1 row
  - "co-normal: tangent, perpendicular, outward, unit" -> four asserts on one fixture, plus the
    curve endpoint case
  - "unchanged by rigid motion" -> rotation, reflection (mirror), translation, and the
    composite; the NEGATIVE: `x` and `n` DO move
  - "trace ... agrees" -> measure, a Functional, and the `x` parameter

5-axis coverage: every atom above; every entry point in § 3; every branch (square fast path vs
Gram, 0-dim facets, strip yes/no, finder fallback, Piola raise, orientation raise); edge cases
(single element mesh, a line mesh of one segment in R3, empty facet subset warning path
unchanged); stated inverses (nonzero coordinates kept; ambient < reference invalid).

## 10. Forced bounds / kwargs

- `Mesh(doflocs, t)` positional; `MeshTri2.from_mesh(m)`; `ElementVector(elem, dim=3)` kwarg
  `dim` (exists on base).
- `element_finder()(*coords)`: one positional array per ambient axis (codebase-inferable via
  `probes`).
- `invF(x, tind=...)` keeps its signature; `x` shape (amb, nelems, nqp).
- `from_meshio(meshio.Mesh(points, cells))` unchanged.
- No new constructor arguments anywhere (L26: nothing to trim).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Two notions of "dim" — `MappingAffine.dim` is ambient, `MappingIsoparametric.dim` is reference, `mesh.dim()` is reference; agents fix the affine class and leave the isoparametric one (or flip `mesh.dim()` and break quadrature/`h`/`refinterp`) | F-9 | S6 | which dimension each stage reads | #2, #5 | the repo already conflates them at 27 sites and both readings look reasonable | "`Mesh.dim()` keeps meaning the reference dimension; the ambient dimension is the number of rows in the point array" + "both the affine ... and the isoparametric mapping ... support it" | quad/second-order measure + gradient tests; base suite |
| 2 | Isoparametric parity — Newton `invF` with a non-square Jacobian, `detDG` for a curve boundary of a surface (1-D facet in R3 uses the 3-D cross-product formula today), `G` over ambient rows | F-10 | S5 | mapping kind x codimension | #1, #4 | affine is the obvious fix site; the isoparametric class has its own helpers (`bndJ`, `J` cache) | same as #1 (no extra words) | MeshQuad tilted measure, MeshTri2 on a cylinder, quad-in-R3 finder |
| 3 | Rigid-motion law kills coordinate-projection shortcuts (project to the best coordinate plane, drop a coordinate, use `p[:2]`) which pass every axis-aligned self-test | P1 (law), A9 exact-fit | S2 | invariance under motion | #4 | agents self-test on z=0 / axis-aligned embeddings (self-test shadow) | "unchanged by any rigid motion of the ambient space" | seeded rotation sweep |
| 4 | Co-normal vs surface normal vs facet normal — agents return the cross-product surface normal, or the 2-D in-plane normal of a projected facet, or an un-normalised co-normal; on curves they return `[-1, 1]` scaled by nothing | F-17 | S2 | boundary geometry | #2 | `normals` is one einsum today and the natural fix is a `dim` switch; the contract's vocabulary (tangent, perpendicular, outward) is not what a cross product computes | "the outward unit co-normal: tangent to the mesh and perpendicular to the boundary" | four-assert co-normal test, curve endpoint test, dual-path law |
| 5 | Baseline preservation — the meshio strip rule (z=0 planar meshes must STAY 2-D), `Mesh.dim()`, `FacetBasis.mesh_parameters` (`dim()-1`), `MeshLine1.element_finder` semantics on ordinary lines, `orientation()` on ordinary simplices | S3 | S3 | existing behaviour through the shared chokepoints | #1 | thorough agents rewrite `strip_extra_coordinates` to keep everything, or make `dim()` ambient | "trailing coordinates are dropped only when they are all zero"; the rest is unstated baseline (fair: it is the repo's own test suite) | `test_meshio_cycle` and the planar-stays-2D test; base mode |
| 7 | Orientation is by VERTEX ORDER while `Mesh.__post_init__` SORTS `t` by default (`sort_t=True`); a mesh rebuilt with `type(m)(p, t)` after `oriented()` loses the orientation, and the propagation must use the CYCLIC edge direction (`RefTri.facets` lists `[0, 2]`, traversed 2 -> 0) | F-6 / S3 | S3 | orientation bookkeeping vs the repo's sorting convention | #4, #5 | agents rebuild meshes with the constructor and compare cross-product normals against `t` after a silent re-sort; the reference author hit both in one session | "the unit normal induced by the vertex order of each element" | `test_orientation_of_an_embedded_triangle_mesh...` (rebuild check via `np.sort(t)`), Moebius `ValueError`, normals after rotation with `replace` |
| 6 | `MeshLine1` finder/param read `p[0]` only — a curve whose x-order differs from element order returns the wrong element silently | F-9 (second site) | A3 | ambient geometry in 1-D helpers | #3 | agents fix the mapping and never open `mesh_line_1.py`; all their line tests are monotone in x | "element finders, probes and interpolators ... work in the ambient space" | arc finder test with a fold in x |

Scope audit: `param` is per mesh (max over elements), `params` per element; `h` per element;
stated by the existing API. Example audit: the meta contains no example. Format-noun audit:
"point array" = `mesh.p` (all doflocs rows), "reference dimension" = `refdom.dim()`, "boundary"
= facets with one neighbour (existing `boundary_facets`). Tolerance fixtures: none.
Wrong Logic prediction: ~20% (the mapping maths is derivable; the wiring is the difficulty).

## 11b. Capability cross-product matrix (F-10)

Axes: mapping kind {affine, isoparametric} x codimension {curve in R2, curve in R3, surface in
R3} x basis {Cell, Facet, InteriorFacet} x field {scalar, vector(dim=amb)}.

| | affine | isoparametric |
|---|---|---|
| **curve in R2** | MeshLine: measure, grad, finder-with-fold, endpoint co-normal | (no isoparametric curve class) — n/a |
| **curve in R3** | MeshLine in R3: measure, rigid motion, Facet endpoints | n/a |
| **surface in R3** | MeshTri: measure, grad, co-normal, dual-path vs tet, InteriorFacet jump | MeshQuad tilted: measure, grad, co-normal, dual-path vs hex; MeshTri2 cylinder measure + invF; MeshQuad2 paraboloid measure <- off-diagonal cells |

Basis x field off-diagonals: `FacetBasis` with `ElementVector(dim=3)` on a tilted triangle patch
(co-normal dotted with a vector field); `InteriorFacetBasis` on MeshQuad in R3 (isoparametric +
interior facets, the least likely self-test). Predicted failure mode: isoparametric facet paths
using the square `detDG` branch (wrong measure, no error).

## 12. Tier + category

- Tier: Olympus. Sub-rank: Good (cross-package, law-shaped contract, S-tier lead).
- Category: **feature-request** ("Add ...").

## 13. Predicted Nova pass rate

- Predicted: 20-35%.
- Reasoning: the mathematics is derivable by any agent (pseudo-inverse, Gram determinant), so
  the isolated probes will pass; the band is held by S6 (two mapping classes + `dim()`), S3
  (meshio strip + base suite), the co-normal vocabulary (F-17) and the isoparametric x boundary
  off-diagonal (F-10). Six traps on four axes, three interdependent through `invDF`/`dim`.
- Sanity: <= 40%. Risk of overshoot to 0% is low: each wall is one sentence of contract with a
  standard mathematical answer; the difficulty is DOING it everywhere.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (Phase 1 below)
- [x] Existing PR check 0 hits (Phase 2 below)
- [x] Closest approved opened: `approved-problems/scikit-fem-hanging-nodes`
- [x] Title verb-led, names subsystem
- [x] Shape declared (O-Composite-extend)
- [x] API surface lists every asserted entry point
- [x] Canonical output form spelled out
- [x] 1 codebase-inferable requirement (finder call form)
- [x] Description ~330 words, plain prose, no headers/labels/code-prose
- [x] Footprint against real files; ~210-250 meaningful, 10-12 files
- [x] Helpers 1:1 with sentences; no fixpoint needed
- [x] Test outline 4-block; 5-axis coverage; per-atom decomposition
- [x] Forced kwargs documented
- [x] 6 traps with F-ids, distinct axes, three interdependent
- [x] § 11b filled, off-diagonals tested
- [x] F-20 sibling audit: `trace` is the sibling path (documented "may lead to a lower
      dimensional mesh", the projection workaround has NO repo test of the unprojected form) —
      guarded both ways (projected trace unchanged in base tests; unprojected trace now works)
- [x] F-21 audit: no caller-supplied interface quantified over
- [x] Unbounded-promise audit: no iteration/scale promises; Newton tolerance is the repo's own
- [x] Stated-noun list: point array, reference dimension, ambient dimension, affine mapping,
      isoparametric mapping, inverse mapping, cell basis, facet basis, interior facet basis,
      gradient, measure, co-normal, boundary, element finder, probes, interpolator, mesh
      parameter, `param`, `translated`, `scaled`, `mirrored`, rigid motion, coordinate subspace,
      `from_meshio`, `Mesh.load`, `Mesh.trace`, `ElementVector` `dim`, Piola transformation,
      orientation. Every fixture subject is on this list.
- [x] F-18 form parity: n/a (no lexical forms)
- [x] Format-noun extents stated (§ 11)
- [x] Tolerance fixtures: n/a
- [x] Wrong Logic < 25%
- [x] Predicted pass <= 40%
- [x] Category matches (feature-request / Add)
- [x] Not pattern-followable (no sibling implementation of a rectangular mapping exists)
- [x] Not in RULES § Features already used

## Phase 1 — repo understanding (recorded)

Architecture: `refdom` (reference domains with facets/normals) -> `mesh` (point array
`doflocs`, connectivity `t`, lazily built facets/edges, a cached `Mapping`) -> `mapping`
(`MappingAffine` for simplices with lazy `A/b/invA/detA/B/c/detB`; `MappingIsoparametric` for
quads/hexes/second-order using the element's own `lbasis` and a Newton `invF`) ->
`assembly/basis` (`CellBasis`, `FacetBasis`, `InteriorFacetBasis` precompute `basis`, `dx`,
`x`, `h`, `n` from the mapping) -> `element` (`gbasis` maps reference basis through
`invDF`/`DF`/`detDF`; H1 identity, Hcurl/Hdiv Piola) -> `assembly/form` (`asm` of
`BilinearForm`/`LinearForm`/`Functional` over the precomputed fields). Five subsystems: refdom,
mesh, mapping, basis, element (+ io/meshio, utils as periphery). High-entanglement zones: (1) the
mapping <-> basis <-> element triangle through `invDF`/`detDF`; (2) `Mesh.dim()` vs
`p.shape[0]` used at 27 sites; (3) `boundary_facets`/`f2t`/`t2f` feeding FacetBasis, normals and
`trace`. Test framework: pytest with `unittest.TestCase` classes and parametrized functions in
`tests/`, e.g. `tests/test_mesh.py` (34 tests) and `tests/test_basis.py` (19); formatting
template: `tests/test_basis.py::test_trace`.

## Phase 2 — searches run (all states, 2026-09-09)

`gh pr list -R kinnala/scikit-fem --state all --search "<k>"` and the issue twin for k in:
surface, manifold, embedded, codim, codimension, shell, curve, ambient, trace, pseudo, "higher
dimension", "3D space", "Laplace-Beltrami", "surface mesh", "1D elements". Hits: no PR
implements a rectangular mapping or an embedded mesh; PR #930 added `Mesh.trace` with a
`project` argument (the workaround this feature removes); issues #1074, #1076, #1121 and
discussion #1039 are the maintainer saying it is not supported and "should be possible"; no
external implementation linked anywhere. Corpus grep across every meta.md for
`manifold|surface mesh|embedded|codim|Laplace-Beltrami`: empty.

## Why this is not a duplicate

Closest approved: `scikit-fem-hanging-nodes` (same repo; mesh REFINEMENT + DOF constraints) and
`lyon-fill-internal-vertices` (geometry, Rust). This pick changes the reference-to-global
mapping layer, which neither touches; the overlap with hanging-nodes is confined to plumbing
files (`mesh.py`, `cell_basis.py`).

Predicted iteration cycles: 2.
