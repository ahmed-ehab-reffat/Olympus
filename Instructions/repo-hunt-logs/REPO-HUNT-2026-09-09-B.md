# Repo hunt 2026-09-09-B — three topic-search sweeps (~190 topics), 35 repos screened, 0 authorable

Second hunt of the day (the morning one scope-locked Cwerg; the user asked for MORE candidates beyond
the in-flight set). Method: Stage 0-bis pool check (every 1-2-sub pool repo was already re-mined on
09-01-C / 09-04 / 09-06 / 09-09, so no pool candidate was re-screened), then the topic-search axis
with the dead-list filter (157 slugs) over THREE sweeps: geometry/science/storage (75 topics, 194 rows),
language-processing (63 topics, 220 rows), data-format/science (55 topics, 123 rows). 35 repos
mechanically screened, 2 cloned and seam-audited (koto, pmp-library), 1 built (koto, 3x).

**Headline: no RANK 1.** The one repo that survived every mechanical gate AND the competitor profile
(pmp-library) died on a rule this workspace had never had to apply to a C++ repo: **vendored
`external/` licences.** The other survivor (koto) is a finished language whose only gap is a missing
arm of an existing dispatch.

| Repo | ★ | Mechanical | Verdict |
|---|---|---|---|
| pmp-library/pmp-library | 1505 | ALL PASS, CI green daily, competitor-CLEAN | ⛔ **LICENCE: vendors Eigen (MPL-2.0 + LGPL files) and GLFW (zlib) under `external/`** — RULES.md: one non-allowed vendored licence = whole-repo reject. Also kernel-hook lanes maintainer-declined |
| koto-lang/koto | 882 | ALL PASS, 3x deterministic (69 suites) | SHELVED — finished language; the only gap (nested/ellipsis patterns in assignment/`let`/`for`) is a missing arm: function args and `match` already carry the nested machinery |

---

## pmp-library/pmp-library (C++, halfedge mesh processing) ★1505 — DEAD on vendored licence

- MIT (own `LICENSE.txt`, "plain MIT" since 2026-01-02), pushed 2026-08-28, 28 commits/180d by the two
  maintainers (`dsieger` 24, `mbotsch` 4), `build` workflow green every day, 13 open issues, 4 open PRs.
- **Stage 2b-bis CLEAN**: every PR author is a real geometry user (`Giacogiak` also on geometry-central,
  `elshorbagyx` on gccrs/cglm, `nemectad` physics). No scatter account, no recorded signature.
- **Lane density**: 12mo stream is viewer/docs/CMake + the maintainer's live `MeshAnalysis` +
  `polygonal` + "TFEM Laplace" work. Algorithm lanes COLD: remeshing 0, subdivision 0, hole_filling 0,
  smoothing 0, geodesics 0, curvature 0, decimation 1, parameterization 1 (bug fix).
- **Lanes examined and why each is dead or weak**:
  - kernel property propagation / UV-aware algorithms (#141 / #159, 15 comments): `dsieger` twice —
    "not a responsibility of the mesh data structure", "not sure adding hooks ... is the right path";
    the UV work exists as a PUBLIC fork branch `mokafolio:moka/uv_algos` (subdivision + triangulate).
    Remeshing UV: maintainer "not really sure this is feasible or reasonable". Philosophy + prior art.
  - size-field remeshing: open PR #232 (+61/-4 `remeshing.cpp`) + issue #92. Published diff.
  - duplicate-vertex merging (#139/#218): maintainer shipped `Report duplicate vertices` 2026-05-14 —
    his current MeshAnalysis lane.
  - **remeshing fold-over (#158)** — the one real lead: maintainer REPRODUCED it 2023-05 ("might be the
    tangential smoothing"), still open, `remeshing.cpp` untouched for 12 months. Confirmed from source:
    `tangential_smoothing()` (line 920) moves feature vertices along the tangent `t` (972-988) and
    `project_to_reference()` (591) re-projects via the KD-tree with **no face-inversion / normal-consistency
    check anywhere** (`grep -niE 'flip|fold'` hits only `flip_edges`). Scope-up would be "fold-over-safe
    relocation for every vertex move (smoothing, projection, collapse) + feature-curve confinement",
    repo-model-bound, ~200-300 eff. Never sized further because of the licence.
  - hole filling (#27 O(n³) `compute_weight`, #181 exception contract): perf / API, Liepa-named.
- **⛔ Licence, read from the tree**: `external/eigen-5.0.1/` carries `COPYING.MPL2` + `COPYING.MINPACK`
  + `COPYING.BSD` + `COPYING.APACHE` (Eigen is MPL-2.0 and ships LGPL-licensed files that
  `EIGEN_MPL2_ONLY` merely disables), `external/glfw-3.5.1/` is zlib. Neither MPL nor zlib is in the
  RULES.md allowlist (MIT / BSD variants / BSL / BLAS / GNU-all-permissive / Apache / CC-BY), and the
  rule is explicit: "a single non-allowed license (even vendored/subdir) = whole-repo reject". Not
  contestable on our side; only the platform could waive it, and the precedent (linearmodels NCSA,
  pykalman rider-BSD) says it will not.
- Docker note for the record: `olympus-base-cpp` has cmake 4.3.2 / g++ 12.2 / ninja; a container
  build (`-DPMP_BUILD_TESTS=ON -DPMP_BUILD_VIEWERS=OFF -DPMP_BUILD_EXAMPLES=OFF`) was started to
  measure determinism: it BUILT offline (Eigen/googletest vendored, no network) and `ctest` passed 139/139 identically 3x — a perfectly feasible harness, recorded only so nobody re-measures it; irrelevant once the licence killed it.

## koto-lang/koto (Rust, scripting language) ★882 — SHELVED (finished language)

- MIT, pushed 2026-08-06, 143 commits/12mo all by `irh` (solo, direct push), CI green, 5 open issues,
  1 open PR (#555 crypto lib, out of lane). Quota 0/6 here (the sibling-workspace
  `koto-generic-type-hints` reject is in the ledger). Competitor-clean (`bluurryy` 4 PRs = io/args
  contributor with a coherent footprint).
- Real pipeline: `lexer` 1.7k -> `parser` 8.3k (AST, computes accessed non-locals) -> `bytecode` 8.5k
  (register allocator with frames/captures/deferred ops) -> `runtime` 23.9k (VM + core lib) ->
  `format` 3.8k -> `serde`/`derive`. 3x `cargo test --workspace`: 69 suites, 0 failures, identical.
  target dir 3.0G, deleted.
- **Why shelved**: the language is COMPLETE at the surface a scripting-language pick would use. Nested +
  ellipsis + map patterns already work in function args (`|((a, b), (c, d, {e, f}))|`) and in `match`;
  type hints in `let`/`for`/args/return/`match`/`catch`; generators with `yield` type hints; `export`
  of arbitrary key/value iterables; `break` with value; `try`/`catch`(typed)/`finally`; optional
  chaining; packed call args. The one gap found — nested/ellipsis patterns in plain assignment,
  `let`, and `for` (`parse_binding` is flat while `parse_nested_function_args` and
  `parse_match_pattern` are recursive; the compiler already has `CheckSizeEqual`/`TempIndex`
  unpacking for args) — is a **missing arm of a dispatch**, absorbed by construction
  (`TOO-EASY.md § MISSING-ARM`). Generic type hints are maintainer-declined (#298: "too intrusive for
  what's supposed to be a lightweight feature"); bitwise ops (#37) and `+=` on tuples (#394) declined;
  async is "planned" (a whole subsystem). Nothing between "one arm" and "a subsystem".

## Killed at the mechanical screen (35 repos), grouped by gate

| Gate | Repos (★) | Evidence |
|---|---|---|
| **2b-bis competitor signature** | alecthomas/participle 3882, CloudyKit/jet 1403, LCAV/pyroomacoustics 1936, twpayne/go-geom 973 | **NEW SIGNATURE `SAY-5`**: `fix: avoid panic in Unquote on tokens shorter than two characters` (participle #458) AND `fix(eval): return error for out-of-range slice expression instead of panicking` (jet #232) — one-bug panic fixes across unrelated Go parsers. **NEW: `Pastalikek65`** 14 PRs on participle in one window; `MaxFreedomPollard` also on participle. `ChrisJr404` + `youdie006` on jet; `binggao1230` x2 on pyroomacoustics, x1 on go-geom. participle is also at quota (2 subs + `problems/participle-longest-match` + shelved precedence) |
| **maintainer AI-sweep** | tlaplus/tlaplus 3040, pubkey/event-reduce 755, maroba/findiff 509, fjall-rs/fjall 2313, potassco/clingo 830 | `app/copilot-swe-agent` PRs on tlaplus (+`lemmy` 78/92 commits in the parser lane) and clingo; `Copilot` 16 commits on event-reduce (+ CI failing); a `claude` commit author on findiff; "with Claude" commit subjects on fjall |
| **capability-consuming firehose** | mattwparas/steel 2572, uiua-lang/uiua 2162, cycfi/q 1424, hcoles/pitest 1863, Jon-Becker/heimdall-rs 1608, sqlancer/sqlancer 1753 | steel: JIT, cross-module inlining, serialization, reader macros, kernel expansion all in 6 months, 18 open PRs over `compiler/` + `steel_vm/`; uiua 100/180d; q 99/100 by owner with 0 issues + 0 PRs (kapture class); pitest 81/90; heimdall 30/30 + AI eval harness; sqlancer 100/180d and `ci` failing |
| **Requirement 7 (CI) / corpse** | atopile 3870, Algebrite 1000, lotusdb 2256, adsb_deku 727, VROOM 1855, argmin 1274, laika 723, nchopin/particles 503, BoomFilters 1646, Orca 5087, foonathan/lexy 1255, biwascheme 781 | 0 commits/180d on the default branch (atopile, Algebrite, argmin, laika, particles, BoomFilters, Orca, lexy, adsb_deku) and/or the test workflow failing (atopile, Algebrite, lotusdb 1 commit, adsb_deku, VROOM 3 commits, argmin `action_required` only); biwascheme is dependabot-only AND in the derivative ledger |
| **no test suite / finished library** | mlivesu/cinolib 1110, dyn4j/dyn4j 538, cpmech/gosl 1877, jhasse/poly2tri 518, AngusJohnson/Clipper2 2474, VTIL-Core 1585 | cinolib has `examples/` and NO `tests/` (CI "build" only compiles examples); dyn4j 0 issues / 0 PRs (Gate 8 unprobeable, release-only commits); gosl 0 issues; poly2tri 2 commits; Clipper2 4 trivial commits + last C++ CI failing; VTIL needs capstone/keystone |
| **spec / named-algorithm class (not screened further)** | opentype.js, ttf-parser, fontdue, mido, ical4j, gimli, ELFIO, LIEF, csstree, tera/askama/inja/liquidjs, Clarabel.rs (port of Clarabel.jl), rust-peg/peggy/pigeon, regexp2, cbor/avro/parquet/dicom families, raft family (raft-rs, openraft, ratis, NuRaft, sofa-jraft), pomsky + mq (already in TOO-EASY) | the pick would be named by the spec; derivative magnet by construction |

## Method notes worth keeping

1. **⭐ CHECK `external/` / `third_party/` LICENCES AT STAGE 1 FOR EVERY C++ REPO.** RULES.md already
   says vendored subdirs count, but this workspace had only ever applied it to rider-BSD and NCSA. Any
   C++ repo that vendors Eigen (MPL-2.0 + LGPL files) or GLFW (zlib) is dead on sight, and Eigen is
   vendored by most geometry/robotics/FEM C++ repos. One `ls external/*/ | grep -i copying` before the
   seam audit — it would have saved the pmp-library seam audit and the container build.
2. **Topic search still works, but three sweeps over ~190 topics produced ONE mechanically-clean repo.**
   The rows are dominated by (a) spec-named libraries (fonts, codecs, consensus, calendars), (b) apps
   and frameworks, (c) research code with no tests. The authorable middle — a domain engine with its own
   model, tests in CI, a maintainer who answers issues, no swarm — is now rare enough that a sweep's
   expected yield is well under one per session.
3. **Two new competitor signatures** (`SAY-5`, `Pastalikek65`) — record in the account table. `SAY-5`'s
   two PRs are the exact house style: panic-to-error one-liners on tokenizer/evaluator edge cases.
4. **A "finished" language reads clean on every gate and still has nothing to author.** koto is the
   fourth clean-but-absorbed pick this month (after geometry-central, choco-solver, OTIO). The
   discriminator is not the tracker size but whether the parser/compiler already carry recursive
   machinery for the construct you would extend: if `match` and function args already do it, an
   assignment form is an arm.
5. **Self-matching wait loops**: `until ! pgrep -f 'sweep.sh'` never exits because the waiting shell's
   own command line contains the pattern; `pkill -f` on the same pattern killed the caller. Poll a
   marker file instead. Cost ~10 minutes this session.

---

## PASS 2 (same session) — lane-level re-mine of the live pool repos with quota: scikit-fem, acoular, sfepy, calyx

The user asked for more candidates after the sweeps came back empty. Instead of a fourth sweep this
pass took the doctrine's own advice (Stage 0-bis: re-mine repos that already worked) and audited
LANES, not repos, in the four pool repos still alive with quota.

**Headline: scikit-fem carries a real RANK 1 lane — meshes embedded in a higher-dimensional ambient
space (curves in R^2/R^3, surfaces in R^3).** Gate 1 reproduced on base twice over, no PR in the
repo's history touches it, the maintainer has said "I think it should be possible" and never built
it, the whole mapping layer is 0 commits/12mo, and the machinery is genuinely missing (every Jacobian
in the repo is square). Owed before authoring: Gate 8 clause-level design, the F-10 cell table, and
a LOC sketch against the mapping files.

| Repo | Quota | Lane audited | Verdict |
|---|---|---|---|
| kinnala/scikit-fem | 1/6 | **embedded / manifold meshes** (ambient dim > reference dim) | **RANK 1 — authorable**, dossier below |
| kinnala/scikit-fem | — | wedge facet assembly (#743) | DEAD — missing arm; maintainer published the two-`FacetBasis` design in 2021, `RefWedge.facets` already fakes tri facets with a repeated index |
| acoular/acoular | 1/6 | time-domain beamformer interpolation (#119) + reference position (#136) | WEAK RANK 2 — both maintainer-filed roadmap items, cold since 2020, but #119's own answer is "derive other TimeBeamformer classes" (pattern-followable) and #136 is a delay-formula change; tbeamform is also our approved pick's file set |
| sfepy/sfepy | 1/6 | any | SKIP this round — `rc` 136 of 169 commits in 6 months across field/term/mesh/dg; our own `sfepy-adaptive-stepping` is in flight at 0/5 and owns the one cold lane (solvers/ts_*) |
| calyxir/calyx | 2/6 | any | SKIP — `SATURATED-REPOS.md § B2-CALYX` structural warning (0-for-4 against a triaged tracker) |

### kinnala/scikit-fem — ★657 — RANK 1 — embedded-manifold meshes

- **URL / stars:** https://github.com/kinnala/scikit-fem — ★657, canonical org unchanged
- **Language:** Python, pure (numpy/scipy; meshio optional). Image reusable from
  `approved-problems/scikit-fem-hanging-nodes/Dockerfile` (rebuilt today against HEAD
  `73e8357003d67ce267f39c74356a8f045bae99ab`, 2026-09-04; `--network none` run works)
- **Domain:** finite element assembly library (meshes, reference domains, mappings, bases, forms)
- **Open issues without PRs:** 5 (total open 6); 4 open PRs, all maintainer or docs/meshio
- **License:** BSD-3-Clause, read from the file (already cleared for the approved pick)
- **Last commit:** 2026-09-04; 26 commits/12mo, maintainer `kinnala` responsive within a day on
  every issue read; CI `tests` green 2026-09-04
- **Stage 2b-bis:** one `binggao1230` visit (`enforce` empty-row fix, #1212, 2026-05) — recorded
  signature, one visit, far from this lane. Every other PR author is a named FEM user
- **Test framework:** pytest, behavioural through the public API (`Mesh`/`Basis`/`asm`), no mocks
- **Baseline determinism:** full suite 3x in the rebuilt image: **544 passed / 1 skipped / 2 failed,
  identical every run.** The two failures are `tests/test_mamba.py::TestEx52` and `::test_ex_53`,
  both `ModuleNotFoundError` (the `tests-mamba` CI job installs extras the pip image does not) —
  exclude `tests/test_mamba.py` from base mode with that reason, exactly as the approved pick did
- **Docker:** Pattern B `olympus-base-python`, pip installs numpy/scipy/meshio/matplotlib/pyamg/jax/
  shapely/pytest at build; the approved pick's Dockerfile works verbatim on HEAD
- **Architecture:** `refdom` -> `mesh` -> `mapping` (affine / isoparametric) -> `assembly/basis`
  (Cell / Facet / InteriorFacet) -> `element` (`DiscreteField` gradients) -> forms. The mapping layer
  is the shared kernel every basis, interpolator, `element_finder`, and normal computation reads
- **Capability-lane density:** `skfem/mapping` **0 commits/12mo**, `refdom.py` 0, `mesh_2d.py` 0,
  `discrete_field.py` 0, `io/meshio.py` 0, `mesh.py` 2, `assembly/basis` 3. Maintainer's live lanes are
  elsewhere: EdgeBasis + edge affine mapping (open PR #1172, +175), `ElementConstant` (#999),
  deprecated-code removal (#1220), batched interpolation (#1218 merged), sparsity-pattern caching
  (#1197, in discussion). None touch ambient dimension
- **Maintainer-welcomed lane (Stage 2d):** issue #1076 (`kinnala`, 2023-12): "It is currently not
  possible to integrate over 1D objects embedded within 3D space. If you give me governing equations
  ... I can look into how much work it would require." Issue #1121 (2024-04): "There is no proper
  support. I have no plans for studying shells myself." Discussion #1039 (2023-07): "I have not solved
  problems where the surface is given by a triangle mesh embedded in R^3 but I think it should be
  possible." No design published anywhere; no branch; no PR in the full PR history for surface /
  manifold / embedded / codim / shell (searched all states). Not declined, not claimed, not sketched
- **Self-collision:** our approved `scikit-fem-hanging-nodes` is quad local refinement + hanging-node
  DOF constraints (touches `mesh.py`, `cell_basis.py`, `facet_basis.py`, `interior_facet_basis.py`,
  `mesh_quad_*`). Different capability class; the overlap is plumbing files only. Corpus grep for
  `manifold|surface mesh|embedded|codim|Laplace-Beltrami` across all meta.md: empty. Related demand
  exists in sfepy (#981, open, `rc`: "would be nice to make it work", pointing at Laplace-Beltrami)
  which confirms the lane is real and confirms nobody in the pipeline has shipped it there either
- **Missing machinery (absorption test PASSED — name the algorithm):** rectangular-Jacobian mapping.
  `MappingAffine` builds `A` as `dim x dim` with `dim = mesh.p.shape[0]` and inverts it by closed
  form per dimension (`_init_invA`, lines 81-131, "Not implemented for the given dimension"); its
  boundary map `B` is `dim x (dim-1)` only for boundaries of full-dimensional cells.
  `MappingIsoparametric.invF` is a Newton loop on a square `J`; `detDG` is the codim-1 surface measure
  for FACETS only. Nothing computes `(J^T J)^{-1} J^T` (tangential gradient), `sqrt(det J^T J)` (the
  manifold measure), a least-squares inverse map, or co-normals of a manifold's boundary. The two
  notions of dimension are conflated at 27 sites (`mesh.dim()` = reference dim from `refdom`;
  `p.shape[0]` = ambient dim; `MappingAffine.dim` reads the AMBIENT one and `MappingIsoparametric.dim`
  reads the REFERENCE one — the F-9 seam, already inconsistent inside the repo)
- **Gate 1 REPRODUCED on base (in the rebuilt image):**
  - `MeshTri` with 3-row `p` (4 points in R^3, 2 triangles): mesh constructs (`dim()` = 2, `p.shape`
    = (3, 4)); `Basis(m, ElementTriP1())` warns "Unable to calculate global DOF locations" and
    `RuntimeWarning: overflow encountered in multiply` inside `_init_invA`; assembling
    `dot(grad(u), grad(v))` raises `ValueError: operands could not be broadcast together ...
    (3,3,2,3)->(3,2,3,3) (2,3)->(3,2)`; `FacetBasis` raises `IndexError: index 2 is out of bounds
    for axis 0 with size 2`
  - `MeshLine` with 2-row `p` (3 points along a diagonal): everything "works" and the P1 mass matrix
    sums to **0.08** where the curve length is **2.828** — a silent wrong answer, no exception
  - `Mesh.is_valid()` line 623 already CHECKS `doflocs.shape[0] != refdom.dim()` and reports
    "Mesh.doflocs, the point array, has incorrect shape" — the repo names the exact condition as
    invalid today, so the capability is "make this valid" (a defined behavioural flip, not a guess)

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | yes | every gradient/measure/inverse path assumes square `J`; the obvious fix (branch on `p.shape[0]`) leaves `invF`, facet maps and normals square |
| F-2 bidirectional seam | partial | `Mesh.dim()` is read by bases and WRITTEN into mapping `dim` fields — reference vs ambient flows both ways |
| F-9 cross-stage resolution drop | **yes** | `MappingAffine.dim = p.shape[0]` (ambient) vs `MappingIsoparametric.dim = mesh.dim()` (reference); `FacetBasis` line 137 uses `mesh.dim() - 1` for the facet measure exponent |
| F-10 capability cross-product | **yes** | mapping kind (affine / isoparametric) x codimension (curve in R^2, curve in R^3, surface in R^3) x basis (Cell / Facet / InteriorFacet) x field (scalar / `ElementVector` with ambient components); ~20 test lines per cell, zero description words |
| F-14 declared-vs-derived terminal state | yes | `is_valid` line 623 is the existing "cannot continue" exit that must flip from reject to accept without loosening the other shape checks |
| F-17 proxy-metric drift | yes | agents will check mass-matrix totals, not tangential-gradient stiffness; the curve-in-R^2 probe already passes a naive length proxy wrongly |
| F-12 / F-16 | no | Python |

**Best Olympus feature theses (spanning mesh / mapping / assembly / element):**
1. **Embedded meshes as first-class:** a `Mesh` whose point array has more rows than its reference
   dimension is valid; affine and isoparametric mappings expose tangential gradients via the
   pseudo-inverse, the measure via the metric determinant, and a least-squares `invF`; `CellBasis`
   integrates over the manifold, `FacetBasis` over its boundary (co-normals), `ElementVector` fields
   carry ambient components, `element_finder` and `interpolator` work in ambient coordinates, and
   `from_meshio` stops dropping the third coordinate of a triangle mesh.
2. Coupled sub-lever if LOC is short: `MeshTri2` / `MeshQuad2` (isoparametric) in R^3 so curved
   surfaces are second-order accurate — same kernel, second mapping class, different Newton.

**Estimated complexity:** ~250-350 effective across 7-9 files (`mapping_affine.py`,
`mapping_isoparametric.py`, `mapping.py`, `mesh.py`, `mesh_2d.py`/`mesh_line_1.py`, `cell_basis.py`,
`facet_basis.py`, `discrete_field.py`, `io/meshio.py`), 4 packages.

**Why it matches:** a domain engine (not a framework) where the new capability is new mathematics
the repo does not own, wired through the one kernel that every surface reads; a silent-wrong-answer
Gate 1 on base; a cold lane with an explicit maintainer invitation and no design; a repo whose
harness, licence, Docker and determinism are already paid for.

**Risks, stated:** (1) derivative MEDIUM — "surface FEM" is nameable by an outsider (FEniCS, deal.II
and sfepy #981 all name it); mitigate by phrasing meta.md on the repo's own model (ambient rows of
`p` vs `refdom.dim()`) and by the F-10 table, and re-run the PR-DIFF check at submit; (2) normals
orientation is a design choice the maintainer has said he will not derive from node ordering
(D#1103) — keep the contract to orientation-free quantities (tangential gradient, measure, boundary
co-normal) or state the orientation rule explicitly; (3) `ElementGlobal` / `ElementHcurl` branch on
`mesh.dim()` and must be either supported or explicitly out of scope in meta.md; (4) `binggao1230`
has visited the repo once.

**Phase-3 death-class guard:** one shared kernel (`Mapping`) feeding several surfaces — yes; traps
interdependent (fixing the affine path regresses nothing until the isoparametric / facet / vector
paths are held to the same dimension split) — yes; standalone-file solvable — no (both mapping
classes and `Mesh` must change); `TOO-EASY.md` guards 1-5 — not a uniform wrap, not a
single-subsystem transform, hardness survives full statement (the maths is the difficulty, and it
is fully specifiable), not a known-library port.

---

## PASS 3 (same session) — koto re-audited under the softened absorption rule (sketched LOC, not opinion)

The morning verdict ("missing arm, absorbed") was an inspection. The softened rule requires a number.

**Gate 1 REPRODUCED on base (koto CLI, HEAD c579dcd):**

| Form | Result on base |
|---|---|
| `(a, b), c = [[1, 2], 3]` | `Error: expected target for assignment` (1:9) |
| `a, rest... = [1, 2, 3]` | `Error: unexpected token` (1:8) |
| `for (a, b), c in ...` | `Error: expected arguments in for loop` |
| `let (a: Number, b), c = ...` | `Error: expected target for assignment` |
| `{x}, y = [{x: 1}, 2]` (map pattern, flat) | works — `(1, 2)` |
| control `f = \|((a, b), c)\| ...` and `match` `((a, b), c)` | work — nested patterns exist in args and match |

**Where the machinery lives and what is missing (sketch against the sibling arm):**

| Piece | Sibling that exists | Delta needed | eff LOC |
|---|---|---|---|
| parser: nested `()` + `id...` in `parse_binding` (assignment / `let` / `for` / `catch` all go through `BindingContext`) | `parse_nested_function_arg` RoundOpen + Ellipsis arms (~30 lines) | recursive tuple pattern + packed id arms; assignment LHS is parsed as an EXPRESSION first (`parse_assign_expression` collects `previous_lhs`), so tuple targets must be re-validated as patterns | 35-45 |
| compiler: `compile_multi_assign` Tuple arm | `compile_unpack_nested_args_of_tuple` (index-based, `TempIndex`/`SliceTo`/`SliceFrom`, size-checked) | the assignment path is ITERATOR-based (`MakeIterator` + `IterUnpack`, null-fill on short input) — nesting must recurse with iterator semantics on the `IterUnpack` path and index semantics on the `TempTuple` path, and the two must agree | 50-65 |
| runtime: rest capture from an iterator of unknown length (`a, rest... = iter`), first-position rest (`first..., y, z`) needs buffering | `SliceFrom`/`SliceTo` on indexable containers only | 1-2 new ops across `op.rs` / `instruction.rs` / `instruction_reader.rs` / `vm.rs` | 40-55 |
| compiler: `compile_for` args (line ~4500: `Id` / `Ignored` / `MapPattern` arms only) | same three arms | Tuple + PackedId arms mirroring multi-assign | 20-30 |
| formatter (`koto_format`, `format.rs:511` `MultiAssign`, `:752` `PackedId`) | renders flat targets | render tuple targets / rest in binding positions or the formatter corpus regresses | 20-30 |
| **core total** | | 6 files, 4 crates | **~165-225** |

**Coupled second lever (same kernel, required by the 150-250 band):** allow the packed/rest
capture in the MIDDLE position for bindings, function args AND `match` (`(first, mid..., last)`),
which today errors with `InvalidPositionForArgWithEllipses` in all three; the index-from-end logic
in `compile_unpack_nested_args_of_tuple` and the iterator path must both be extended, and the
`match` size checks (`CheckSizeMin`) must change. ~45-60 eff. **Total ~210-285 eff across ~7 files /
4 crates.** Proceeds under the softened rule, at the low edge.

**F-10 cross-product available for free in tests:** RHS form {temp tuple, indexable, iterator of
unknown length} x pattern form {nested tuple, map-in-tuple, rest-first, rest-last, rest-middle,
typed nested, ignored nested} x binding site {assignment, `let`, `for`, `catch`}. The interdependent
seam is the two unpack semantics (index-checked vs iterator null-fill) that every cell touches.

**Gate 8 / prior art:** no issue or PR mentions nested or rest destructuring in bindings (searched
all states). Map destructuring (#475) was designed in the tracker by the maintainer and an outside
contributor (`bluurryy`, Oct 2025) and merged with the maintainer coaching "through the various
layers" — the lane is contributor-friendly, not maintainer-held. Derivative: "nested destructuring"
is nameable (JS/Python) — MEDIUM, mitigate by phrasing on koto's own model (`BindingContext`,
temp-tuple vs iterator RHS, null-fill contract) and by the middle-rest lever, which no mainstream
language has in that exact form.

**Verdict: koto-nested-bindings is AUTHORABLE (RANK 2 behind scikit-fem).** — **REVERSED 2026-09-10: authored, then killed by the platform overlap check (`Blocker`, 258/489 lines = 52.8% against an ACCEPTED foreign Koto task). koto is now DO-NOT-PICK. The Gate 8 line below rated the derivative risk MEDIUM and cleared it on two mitigations: phrasing on koto's own model (not a mitigation — the dedupe compares implemented surfaces) and the middle-rest lever (deleted in authoring round 2 under L31, with no re-assessment). See `TOO-EASY.md § koto-nested-bindings` and `SATURATED-REPOS.md § B2-KOTO`.** Owed at scope-lock:
the exact null-fill vs error contract per nesting level (state it, it is the F-9 seam), the
`Node::Tuple`-as-pattern validation rules (what is rejected: expressions, duplicate ids), and the
formatter round-trip. Clone kept at `worktrees/koto`, target deleted.

---

## PASS 4 (2026-09-10) — steel re-audit under the softened gates (mattwparas/steel, ★2572)

Reopened because the 09-09-B kill was a commit-count verdict, which the softened Gate 5 no longer
allows. Lane-level audit of the 12-month stream (208 commits) plus a shallow clone at `1bc0cc4`.

| Lane | 12mo heat | Finding | Verdict |
|---|---|---|---|
| JIT / inlining / serialization / macros / modules | 9 / 10 / 3 / 9 / 15 + open PRs #677 #643 #630 #553 #552 #232 | the maintainer's programme | DEAD (capability-consuming, correctly) |
| numeric tower (`primitives/numbers.rs`) | 0-1 | `exact`/`inexact`, rationals, big integers, complex (62 mentions), `exact-integer-sqrt`, numerator/denominator all present | FINISHED |
| `dynamic-wind` x `call/cc` | 1 | `parameters.scm:184-300`: winders TLS list, `call/cc` wrapper rewinds via `common-tail` (Dybvig), `parameterize` is built on it, exceptions run the after-thunk | FINISHED (implemented in Scheme) |
| contracts (`contracts.scm` 560 LOC, `contracts.rs` 91 LOC of commented-out Rust) | 0 | flat + function contracts, `->/c`, `define/contract`, `contract/out`; no dependent (`->i`), no `listof`/`or/c` combinators, no blame parties | cold but every gap is a Racket-named combinator: spec-port MAGNET |
| `match.scm` (37 clauses) | 2 | Racket-`match` subset | same magnet class |
| **reader + ports** (`scheme/modules/reader.scm`, `steel_vm/primitives.rs:2017-2110`, `values/port.rs`) | reader 0, ports 7 (aliases, `parameterize`, open options) | ONE global `*reader*` (buffer + offset) shared by every port; `read` drains the WHOLE port into it (`read-port-to-string`) so `read-line`/`read-char` after `read` see EOF, and `read` on a second port continues the first port's buffer; the maintainer's own TODOs sit on it ("This reparses everything", "This needs to get fixed"); issue #693 (2026-09-04, OPEN) reports exactly the cross-port symptom | the ONLY invented-capability lane: per-port reader state + datum-exact consumption + pushback so `read`, `read-char`, `peek-char`, `read-line` compose on any port kind (string / file / stdin) — S1 state isolation + F-10 (port kind x primitive). ~150-250 eff across `port.rs`, `ports.rs`, `primitives.rs`, `reader.scm`. RISKS: the open bug is a magnet AND the maintainer's listed debt (he fixes ports monthly: #644, #649, #652), so it may ship any week |

**Verdict: steel stays a LANE-LEDGER repo, weak backup.** Nothing here beats the two authored picks.
The reader/port lane is authorable only after reading the #693 thread (maintainer comment / claim /
published fix) and re-checking the commit stream on the day of scope-lock — both blocked this session
because the `gh` token expired mid-audit (`gh auth login -h github.com` owed).

**PASS 4 addendum (after `gh` re-auth, 2026-09-10):** issue #693 is by `DRMacIver` (Hypothesis
author, real identity, no comments, no maintainer reply, no PR), so it is a genuine fuzz report and
not a rival-author probe. But the port lane is CONTRIBUTOR-OWNED: `m4rch3n1ng` landed nine port PRs
(#489, #491, #492, #495, #501, #505, #644, #649 plus the `(print)` work) between 2025-08 and
2026-03 and is still active in the repo. That is the Stage 2c "≥4 merged PRs in one narrow lane"
condition, so the reader/port state-isolation lane is DEAD on lane density, not merely risky.
`ports.rs` has no commits in the last 90 days, which reads cold only because its owner is between
rounds. **steel: no authorable lane remains. Dead for this quarter.**

**PASS 2 outcome (2026-09-10): scikit-fem-embedded-meshes SHELVED at platform precheck — dedupe
`derivative` 0.79 / conf 0.90 against another author's embedded-mesh submission dated 2026-09-06,
three days before this hunt scope-locked the lane.** Every signal that ranked it first (cold
`skfem/mapping`, no PR, the maintainer's "should be possible" replies on #1076 / #1121 / D#1039, a
crash reproducible on base) was equally visible to that author. The dossier's MEDIUM magnet rating
was wrong: for a proven pool repo an invited, PR-free lane is HIGH by default. Case study in
`TOO-EASY.md § scikit-fem-embedded-meshes`; ledger `SATURATED-REPOS.md § B2-SKFEM` (now AVOID).
