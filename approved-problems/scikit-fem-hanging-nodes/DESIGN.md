# DESIGN.md — scikit-fem-hanging-nodes

## 1. Title

Add locally refined quadrilateral meshes with hanging nodes

Repo: `kinnala/scikit-fem` (BSD-3, 642 stars, Python, last source commit 2026-06-05).
Base commit: `51cec1ff5ac6c00dd7a438ae3d01845f8d013899`.

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK § Pattern 12) — a new capability whose
  correctness rests on subtle algorithmic invariants (level balancing, exterior-boundary
  identification, coarse-side attribution) rather than on breadth of independent cases.
- Pass rate target: <= 40% sprint cap; **designed for the corpus mode of 1/10**.
- Best agent: Orion (long-horizon; the corpus lone-passer profile).
- Dominant verdict expected: MISSED_REQUIREMENT / REGRESSION.

## 3. Public API surface

Every name below is asserted by the tests and named in `meta.md`.

- `Mesh.hanging_nodes() -> ndarray` — sorted indices of vertices that split a facet of another
  element into two.
- `Mesh.hanging_elements() -> ndarray` — the elements on the coarse side.
- `Mesh.is_one_irregular() -> bool` — whether every facet is split at most once.
- `Mesh.hanging_f2t() -> ndarray` — `f2t` with the coarse element named as the second neighbour
  of each half, so `InteriorFacetBasis` can evaluate a jump there.
- `Mesh.conforming()` — refine until no hanging vertices are left.
- `MeshQuad1.coarsened(indices)` — merge complete sibling groups back together.
- `skfem.utils.constrain(basis, A, b, x, D)` — eliminate the constrained DOFs with `D`.
- `skfem.utils.coarsen_theta(est, theta, max)` — the marking counterpart of `adaptive_theta`.
- `skfem.models.poisson.residual_estimator(basis, x, f)` — elementwise error indicators.
- `Mesh.split_facets() -> ndarray` — sorted indices of facets that a hanging vertex splits.
- `Mesh.hanging_facets() -> ndarray` — sorted indices of the halves of split facets.
- `Mesh.boundary_facets() -> ndarray` — behaviour change: returns only exterior facets; split
  facets and their halves are interior. `boundary_nodes`, `facets_satisfying(...,
  boundaries_only=True)`, `Basis.get_dofs()` and `FacetBasis` inherit the corrected set.
- `MeshQuad1.refined(indices: ndarray)` — adaptive refinement; splits each marked quadrilateral
  into four and additionally splits whatever else is needed to keep the mesh one-irregular.
- `AbstractBasis.hanging_dofs() -> ndarray` — sorted indices of the constrained degrees of
  freedom.
- `AbstractBasis.hanging_prolongation() -> scipy.sparse.csr_matrix` — the `N`-by-`N` matrix `P`
  with `x = P @ x` for every function in the continuous space.

## 4. Canonical output form

- `hanging_nodes`, `hanging_facets`, `split_facets`, `hanging_dofs`, `boundary_facets`: sorted
  ascending, `int32`, duplicate-free.
- `hanging_prolongation`: `csr_matrix`, shape `(N, N)`, dtype float64. Row `i` of an
  unconstrained dof is the `i`-th unit row. Row `s` of a constrained dof carries the
  interpolation weights and `P[s, s] == 0`. No column indexed by a constrained dof is nonzero,
  which holds automatically because a master is never itself constrained on a one-irregular
  mesh.
- Empty input: a conforming mesh yields empty index arrays and `P == identity`.
- `refined(np.array([], dtype=np.int32))` returns a mesh equal to the input.
- Named boundaries and subdomains survive both refinement and coarsening; a named facet that is
  split contributes both halves.
- Negative/duplicate element indices in `refined` are treated like `numpy` fancy indexing.

## 5. Blind-spot pre-empts (from DESCRIPTION.md sentence bank)

- Iteration termination: "refining continues until no further element needs splitting".
- Result ordering: "returned index arrays are sorted ascending".
- Adjacent vs all positions: "the two halves of a split facet, and the facet they split, are
  all interior".
- Rule resolution: "whose columns at constrained degrees-of-freedom are zero".
- Parallel API: the interpolation rule is stated once for all degrees of freedom rather than
  per element family, so vector-valued and higher-order elements follow the same rule.

Exactly one codebase-inferable requirement: reuse of an existing hanging vertex when the coarse
element that carries it is later refined (visible from the mesh data structure, not stated).

## 6. Description draft

See `meta.md`. Plain prose, no headers, states: the refinement rule, one-irregularity, the
exterior-boundary correction, the interpolation rule for constrained dofs, the shape and the
resolved-ness of `P`, and the ordering of every returned array.

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| MODIFY | `skfem/mesh/mesh.py` | +150 | hanging/split facet detection, corrected `boundary_facets` |
| MODIFY | `skfem/mesh/mesh_quad_1.py` | +150 | `_adaptive` with one-irregular balancing |
| MODIFY | `skfem/mesh/mesh_quad_2.py` | +5 | second-order quad meshes reject adaptive refinement |
| MODIFY | `skfem/assembly/basis/abstract_basis.py` | +190 | `hanging_dofs`, `hanging_prolongation` |
| MODIFY | `skfem/mesh/mesh_2d.py` | +10 | 2-d hook |

Actual: **411 human-effective / 639 raw across 11 files**; Counter 1 (the platform auto-block
measure) is 494. Also touched: `skfem/utils.py`, `skfem/models/poisson.py`,
`skfem/models/__init__.py`, `skfem/assembly/basis/cell_basis.py`,
`skfem/assembly/basis/facet_basis.py`, `skfem/assembly/basis/interior_facet_basis.py`,
`skfem/__init__.py`. The 430 design target was not reached; see `feedback.md` for why and for
what was considered instead.

## 8. Solution outline — helpers

- `Mesh._init_hanging()` — one pass building `_hanging` (child facets), `_split` (parent
  facets), `_hanging_parent` (child facet -> parent facet), `_hanging_vertex` (parent facet ->
  hanging vertex). Cached like `_facets`.
- `Mesh.hanging_nodes/hanging_facets/split_facets` — thin accessors.
- `Mesh.boundary_facets` — single-neighbour facets minus hanging minus split.
- `MeshQuad1._adaptive(ix)`:
  - `_adaptive_balance(marked)` — fixpoint loop: an element whose facet is a half of a split
    facet can only be refined together with the element on the coarse side.
  - `_adaptive_split_nodes(marked)` — assign a vertex to every facet being split, reusing an
    existing hanging vertex where one is already present.
  - assembly of the four child quadrilaterals per marked element.
- `AbstractBasis._hanging_rows()` — for each hanging vertex: the constrained dofs, their
  physical locations, and the coarse element that constrains them.
- `AbstractBasis._hanging_weights(...)` — evaluates the coarse element basis at the constrained
  dof locations and contracts with the constrained dof's own direction, which selects the right
  component for vector-valued elements.
- `MeshQuad1._coarsen_groups()` / `coarsened()` — geometric sibling detection, the merge rules
  and vertex compaction.
- `skfem.utils.constrain()` — the constrained condensed system, including the eigenvalue path.
- `residual_estimator()` — interior residual plus facet jumps, with the coarse-side attribution.

Chained constraints (a master that is itself constrained) turn out to be unreachable in this
mesh model, so no fixpoint resolution is needed; see `feedback.md`.

## 9. Test file outline

Path: `tests/test_local_refinement_681511.py`, four blocks (imports / mesh builders / assertion helpers /
tests). Buckets:

1. adaptive refinement: element and vertex counts, idempotence of an empty marking, repeated
   refinement and vertex reuse, cascade balancing including a case needing two rounds, the
   one-irregularity invariant, named tags preserved.
2. topology queries: `hanging_nodes`, `hanging_facets`, `split_facets` on hand-built
   configurations; conforming meshes return empty arrays; `MeshTri1` unaffected.
3. exterior boundary: `boundary_facets`/`boundary_nodes` on adaptive meshes; perimeter of the
   unit square integrated with `FacetBasis` equals 4 exactly; `facets_satisfying`.
4. constraints: shapes, sorting, `P[s, s] == 0`, zero columns, exact weights for `ElementQuad1`
   (1/2, 1/2) and `ElementQuad2` (3/8, -1/8, 3/4 and 1 on the coarse facet dof), vector and
   composite elements, `ElementQuad0` unconstrained.
5. patch test / solve: a bilinear function is reproduced exactly on a locally refined mesh with
   `ElementQuad1`, a biquadratic one with `ElementQuad2`; the interpolated field is continuous
   across a hanging edge; Poisson on a fully marked mesh matches uniform refinement.
6. edge cases: empty marking, single element, marking every element, second-order quad mesh
   raises, conforming mesh gives identity prolongation.

## 10. Forced signatures

`hanging_prolongation` must return a `scipy.sparse` matrix supporting `@`, `.T`, `.nnz`; the
tests use `P.T @ A @ P` and `P @ x`, so a dense array would still work but a `csr_matrix` is
what `meta.md` pins. `refined` keeps its existing signature (`Union[int, ndarray]`).

## 11. Predicted trap matrix

| # | Trap | Class | Why agents hit it | Pre-empt in meta | Catching test |
| --- | --- | --- | --- | --- | --- |
| 1 | Split facets and their halves keep only one neighbouring element, so the naive `f2t[1] == -1` test reports them as exterior boundary. Dirichlet conditions then land on interior nodes and the solution is wrong. | S3 baseline-preservation through a shared chokepoint; misdirecting (the failing test is a solve, not a topology query) | `boundary_facets` is existing, correct-looking code | "only facets on the exterior boundary" | perimeter == 4, Poisson patch test, `boundary_nodes` |
| 2 | Balancing is a fixpoint: refining one element can force a chain of coarser neighbours. Agents do a single pass. | A13 N-fold accumulation | one pass passes every two-element test | "continues until no further element needs splitting" | three-level cascade counts, one-irregularity invariant |
| 3 | The two halves of a split facet keep their own facet degrees-of-freedom, which are constrained as well; and the estimator has to attribute a half-facet jump to the coarse element, which the halves' own `t2f` never reaches. | S2 composition of documented rules | the vertex alone is the visible constrained dof, and `t2f` is the obvious distribution route | the constrained-dof definition; "the halves of a split facet contributing to the coarse element too" | second-order weight tests, `test_estimator_distributes_every_jump` |
| 4 | For `ElementQuad2` the weights are not the arithmetic mean; the halves' facet dofs take 3/8, -1/8, 3/4. | "obvious code is wrong" | linear averaging is the natural guess | interpolation stated as the coarse element's own basis at the location | exact `ElementQuad2` weights, biquadratic patch test |
| 5 | An already existing hanging vertex must be reused when the coarse element is refined later, otherwise duplicate vertices appear at the same location. | A3 reuse-the-machinery missing arm | fresh midpoints are the obvious construction | (codebase-inferable, deliberately unstated) | repeated refinement vertex counts, continuity |

## 12. Tier + category

- Tier: Olympus. Sub-rank: Excellent.
- Category: feature-request (new public methods and a new refinement capability).

## 13. Predicted pass rate

10% - 25%. Five interdependent traps; traps 1 and 3 are misdirecting and interdependent (fixing
the boundary set changes which dofs are Dirichlet, which changes whether the unresolved
prolongation is visible). Corpus levers stacked: one interdependent kernel (the hanging-node
topology feeds refinement, boundary identification and constraints), an exact oracle (analytic
patch test plus uniform-refinement equivalence), five traps including two "obvious code is
wrong" edges, a bespoke low-training repo, and a >= 450 effective LOC multi-file span.

## 14. Quality gate

- [x] Repo understanding 5/5 (mesh / element / mapping / assembly / utils; entanglement in
      `Mesh.facets` + `Dofs.element_dofs` + `condense`; pytest under `tests/`; template
      `tests/test_mesh.py`).
- [x] Existing-PR check: `gh pr list -R kinnala/scikit-fem --state all --search "hanging"` and
      five further keyword searches plus a full branch enumeration return nothing touching
      adaptive quadrilateral refinement or constrained spaces.
- [x] Closest approved problems opened: `turmoil-link-bandwidth` (invented dimension threaded
      through an engine) and `surrealkv-merge-operator` (new object folded on every read path).
- [x] Corpus hardness recipe satisfied.
- [x] Canonical output form spelled out.
- [x] <= 1 codebase-inferable requirement (vertex reuse).
- [x] File footprint sketched against real source files.
- [x] Traps each have a pre-empt sentence and a catching test.
- [x] Repo baseline green and deterministic offline (538 passed, 3/3 identical runs).

## Why this is not a duplicate

Nothing in `Aprroved/`, `problems/` or `rejected/` touches finite element assembly, mesh
refinement or constrained function spaces; the nearest neighbours are `turmoil-link-bandwidth`
(a different repo, a network simulator) and `python-control-analysis-points` (a different repo,
control systems). The repo has never been used locally.

Predicted iteration cycles: 2.

Built and validated 2026-08-06. 83 new tests, 539 base cases, thirteen mutation probes, all four
validation cells green, deterministic across three consecutive runs.
