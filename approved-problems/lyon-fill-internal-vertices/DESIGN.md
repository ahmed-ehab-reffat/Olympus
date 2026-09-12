# DESIGN.md — lyon-fill-internal-vertices

Base commit `8071ec066c610b006e58086fea30cd96d4cef153` (nical/lyon, dual MIT/Apache-2.0, 2593 stars).
All measurements in this file were taken locally on a CLEAN checkout of that commit.

## 1. Title

**Add interior vertex elimination to the fill tessellator**

Verb `Add`, 7 words, names the subsystem (`FillTessellator`). Category `feature-request` (net-new
public option + net-new output contract), which matches the verb.

## 2. Shape classification

- **Shape:** O-Algorithm-correctness (`SHAPES.md § Pattern 13`) — a new opt-in output mode whose
  difficulty is a subtle whole-mesh correctness property, not breadth of API.
- **Pass rate target:** 10-25%. Current sprint band is `<=40%` ceiling, `0%` = reject. Biasing to
  the hard edge per PRIME DIRECTIVE, but the contract is fully stated so it should stay solvable.
- **Best agent:** Vega / Castor (multi-stage restructuring), Orion second.
- **Dominant verdict predicted:** WRONG_LOGIC (the classifier and the re-triangulator are both
  places to be silently wrong), with a REGRESSION tail from the shared-chokepoint wall.
- **Span:** `fill.rs` + `event_queue.rs` + `lib.rs` + one new module. Single crate, multi-file.

## 3. Public API surface

Exactly the names the tests assert:

- `FillOptions::eliminate_interior_vertices` — public `bool` field, defaults to `false`.
- `FillOptions::with_interior_vertex_elimination(bool) -> FillOptions` — const builder method,
  same style as the existing `with_intersections` / `with_fill_rule` / `with_sweep_orientation`.

That is the whole new surface. **Deliberately no standalone public helper function.** Exposing
something like `eliminate_interior_vertices(positions, indices)` would hand the agent the
architecture (buffer the mesh, post-process it) and defuse trap T4 below. The contract is stated
purely in terms of what `FillTessellator::tessellate_*` emits, so any correct architecture passes.

## 4. Canonical output form

The contract is on the mesh the tessellator hands to the `FillGeometryBuilder`. With the option
enabled:

- **Which vertices survive:** exactly those on the boundary of the filled region. A vertex is
  interior when the filled region covers a full neighbourhood around it; every other vertex is
  boundary and is kept.
- **Holes and reflex corners are boundary, not interior.** A corner of a hole (a subpath wound
  opposite to its container) and a self-intersection point that is a reflex corner of the outline
  both stay, even though they sit inside the shape's bounding area.
- **Covered region:** unchanged. Same area, same point-in-mesh answers everywhere.
- **Mesh boundary:** unchanged. The set of boundary edges is identical before and after.
- **Triangle orientation:** every emitted triangle keeps the same handedness the tessellator
  already produces for that sweep orientation.
- **Vertex buffer:** contains only surviving vertices; no unreferenced vertices are emitted.
  Relative order of surviving vertices is the sweep order, unchanged.
- **Default (`false`):** output byte-identical to today, for every fill rule and orientation.
- **Interaction with `fill_rule`:** the option is honored for both rules; `EvenOdd` output
  typically has no interior vertices, so it is usually unchanged.

## 5. Blind-spot pre-empts (from `DESCRIPTION.md` sentence bank)

| Blind spot | Sentence going into meta.md |
|---|---|
| Adjacent-vs-all / partial application | "the covered region, its boundary, and the answer to whether any given point is filled all stay exactly the same" |
| Unstated inverse | "corners of holes and reflex corners of the outline are on the boundary and are kept" |
| Iteration termination | "repeat until no interior vertices remain" |
| Result ordering | "surviving vertices keep the relative order the tessellator already emits them in" |
| Default preservation | "with the option left off the output is unchanged" |
| Orientation | "triangles keep the winding the tessellator already produces" |

Codebase-inferable requirements: **1** (that the triangle winding differs between the Vertical and
Horizontal sweeps is discoverable from the source/output, and the meta states the preservation rule
without stating which handedness applies where). Within the `<=1` limit.

## 6. Description draft (meta.md body, ~230 words — under the 500 hard cap)

Opening sentence states the ask, current behavior second, per `DESCRIPTION.md`. Plain prose, no
headers, no formulaic labels, backticks only on the two new API names. Full text written at Step 5.

Content to cover, one test per sentence:
1. Add the opt-in option and name it.
2. Current behavior: `NonZero` emits vertices and triangles inside the filled region where
   subpaths overlap, instead of only the outer boundary.
3. What survives: boundary vertices only; interior vertices and the triangles fanning off them go.
4. Holes and reflex corners are boundary.
5. Region, boundary edge set, and point-in-mesh answers are preserved exactly.
6. Triangle winding preserved.
7. No unreferenced vertices; surviving order preserved.
8. Repeat to a fixpoint.
9. Default off, output unchanged.

## 7. File footprint (sketched against real source, LOC from the skeleton probe)

| Action | Path | Current LOC | Raw delta | Meaningful (~0.65) | Reason |
|---|---|---|---|---|---|
| NEW | `crates/tessellation/src/interior.rs` | — | +330 | ~215 | recorder + filtering builders, boundary/interiority analysis, patch loop extraction, ear clipping, index remap |
| MODIFY | `crates/tessellation/src/fill.rs` | 3029 | +65 | ~42 | two-pass wiring in `tessellate_impl`, event-queue snapshot/restore |
| MODIFY | `crates/tessellation/src/lib.rs` | 689 | +25 | ~16 | `FillOptions` field, const builder, module declaration |
| MODIFY | `crates/tessellation/src/event_queue.rs` | 1019 | +8 | ~5 | `#[derive(Clone)]` on `Event` + `EventQueue` (Event is currently NOT Clone — verified) |

**TOTAL: ~428 raw / ~278 meaningful across 3 modified + 1 new = 4 files.**

Current sprint floor: `>=200` meaningful, `>=2` files, `>=40` solver-median messages. Clears with a
~78 LOC buffer. The 330 raw for `interior.rs` is calibrated against a **working 110-line prototype**
that already does classification + patch extraction + ear clipping + orientation handling; the
production version adds the two builder adapters, the remap, and error paths.

**If the count lands short after implementation**, the planned orthogonal lever is eliminating
*collinear boundary* vertices too (open-fan removal, a genuinely different classification and
removal path). Held back from v1 because exact-collinearity on flattened curves is a flakiness
risk that has to be measured before it is promised.

## 8. Solution outline — helpers, one per described behavior

New module `interior.rs`:

- `struct MeshRecorder` implementing `FillGeometryBuilder` — pass 1 sink; records vertex positions
  in emission order and every triangle. `add_fill_vertex` returns sequential ids.
- `struct FilteringBuilder<'a>` implementing `FillGeometryBuilder` — pass 2 adapter; forwards
  `add_fill_vertex` to the real builder only for surviving vertices, records old->new id mapping,
  discards the sweep's own triangles, and emits the precomputed simplified triangles on
  `end_geometry`.
- `fn boundary_vertices(tris) -> BitSet` — a directed edge `(a,b)` with no matching `(b,a)` is a
  boundary edge; its endpoints are boundary vertices. ← requirement 3, 4
- `fn patch_loops(patch) -> Vec<Vec<VertexId>>` — extracts the closed boundary loop(s) of the
  triangle patch around one vertex. ← requirement 3
- `fn ear_clip(loop, positions) -> Vec<[VertexId;3]>` — triangulates a possibly non-convex loop,
  **preserving the loop's own handedness** (compute signed area, normalize, clip, flip back).
  ← requirement 6
- `fn simplify(positions, tris) -> Vec<[VertexId;3]>` — the fixpoint driver. ← requirement 8

```rust
loop {
    let boundary = boundary_vertices(&tris);
    let Some(v) = used_vertices(&tris).find(|v| !boundary.contains(v)) else { break };
    let patch: Vec<_> = tris.iter().filter(|t| t.contains(&v)).cloned().collect();
    let loops = patch_loops(&patch);
    if loops.len() != 1 { break; }
    tris.retain(|t| !t.contains(&v));
    tris.extend(ear_clip(&loops[0], positions));
}
```

- `fn remap(tris, survivors) -> Vec<[VertexId;3]>` — compacts to the new id space. ← requirement 7

In `fill.rs::tessellate_impl`, when the option is on: snapshot `self.events`, run the sweep into a
`MeshRecorder`, compute the plan, restore the snapshot, `self.reset()`, run the sweep again into a
`FilteringBuilder`. When off, the existing single-pass path is untouched.

## 9. Test file outline

Path: `crates/tessellation/tests/interior_vertices_<hex6>.rs` (random hex suffix, no `shipd` /
`datacurve` markers). Template: `approved-problems/lyon-arcs-join/test.patch`, same repo.

Block 1 — imports. Block 2 — path builder helpers (`two_squares`, `nested_squares`, `issue_outline`,
`hole_opposite_winding`, `pentagram`, `six_circles`, `three_squares`). Block 3 — assertion helpers.
Block 4 — tests by bucket.

**Assertion strategy (per the explicit ask + `failure-patterns.md` L13 — remove the NEED for a
magic constant, do not shrink one):**

- `total_area(mesh)` compared against `total_area(reference_tessellation)` — two computed
  quantities, never a literal.
- `boundary_edges(before) == boundary_edges(after)` — exact set equality on copied `f32` points.
  No epsilon, and it is the strongest single invariant: interior elimination must not move the
  boundary at all.
- `filled(p)` sampled over a deterministic lattice, asserting `filled_before(p) == filled_after(p)`
  — exact boolean equality, no tolerance.
- `interior_vertex_count(mesh) == 0` — integer, exact.
- every vertex in the buffer is referenced by some triangle — integer, exact.
- all triangles share one handedness sign — integer, exact.

Buckets:
- **eliminates**: two_squares, issue_outline, three_squares, six_circles reach zero interior
  vertices and shrink triangle count.
- **preserves**: area / boundary-edge-set / point-in-mesh identity on each of the above.
- **keeps what is boundary**: hole_opposite_winding and pentagram are unchanged.
- **default off**: every fixture byte-identical to base output.
- **cross-product** (see § 11b).
- **edge cases**: empty path, single triangle, degenerate/zero-area subpath, one subpath fully
  containing another, curve flattening at a coarse and a fine tolerance.

## 10. Forced trait bounds

`FillGeometryBuilder: GeometryBuilder`, so both adapters must implement `begin_geometry`,
`end_geometry`, `add_triangle`, `abort_geometry` **and** `add_fill_vertex`. The forced constraint
that drives the whole design: `FillVertex<'l>` borrows `&'l EventQueue` and `&'l mut [f32]`
(`fill.rs:2159`), so a `FillVertex` **cannot be stored** for later replay. Verified by reading the
struct. This is stated in the meta only as an output contract, never as an instruction.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence in meta | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| T1 | Holes and reflex corners are geometrically "inside" but are boundary. A winding-based or point-in-union interiority test deletes them. | F-2 | S2 (composition of documented rules) | classification correctness | T5 (a wrong class feeds a wrong patch) | The obvious test is "is this point inside the filled region", which is true for a hole corner's neighbourhood on one side only. | "corners of holes and reflex corners of the outline are on the boundary and are kept" | `hole_opposite_winding_unchanged`, `pentagram_unchanged` |
| T2 | **Triangle handedness differs between the Vertical and Horizontal sweeps.** A re-triangulator that normalizes to CCW silently breaks edge pairing, so the fixpoint stalls and interior vertices survive. | F-10 | A10 (orthogonal stability wall) | output orientation | T5 (same code path), T1 (symptom points at the classifier) | **Measured locally**: my own first prototype forced CCW and under-simplified Horizontal (8v/6t expected, 9v/8t produced) while Vertical was perfect. The symptom accuses the classifier; the bug is in the clipper. | "triangles keep the winding the tessellator already produces" | `*_horizontal_sweep` variants of every elimination test |
| T3 | Two-pass restructuring reroutes ALL fill tessellation. Default path must stay byte-identical across 185 existing tests, including the 20k-line earcut fixture suite. | F-12 | S3 (baseline preservation through a shared chokepoint) | regression | T4 (same chokepoint) | The natural implementation makes the new path the only path. | "with the option left off the output is unchanged" | base mode: full existing `lyon_tessellation` suite |
| T4 | `FillVertex` borrows the event queue and cannot be buffered, so vertex filtering needs a second sweep; and the sweep MUTATES the event queue (intersection splits), so pass 2 diverges unless the queue is restored. | F-9 | S4 (machinery-riding integration) | architecture | T3 | The borrow checker reveals the wall but not the fix. The divergence only shows on self-intersecting input, which is exactly the input this feature is for. | stated only as "no unreferenced vertices are emitted" (contract, not fix) | `six_circles`, `three_squares` vertex-buffer density tests |
| T5 | Interior-vertex stars are frequently non-convex; a naive fan triangulation from the first link vertex produces inverted/overlapping triangles. | F-8 | A5 (naive-dominant-reading) | re-triangulation | T1, T2 | Fan-from-first-vertex is the default mental model for filling a polygon hole. | "the covered region ... stays exactly the same" | area-identity and `filled()`-identity assertions |

**T3 is DEMOTED after the harden pass.** I justified it on the grounds that the two-pass rewrite
reds existing tests. That is mutation-grade evidence, not agent-grade (`HARDENING.md` L15;
rust-minidump measured **0 baseline failures in 10/10 runs** on exactly this kind of axis). T3 stays
in the contract because an unstated preservation requirement is unfair, but it is **not counted as
difficulty** and the pass-rate prediction does not lean on it.

The honest difficulty stack is therefore **T1 (classification), T2 (orientation, measured),
T4 (architecture)** as the three real walls, with T5 as support on the same code region as T2, and
T3 as fairness only. Axes differ; T2/T4/T5 are each interdependent with another row. T2 is the only
wall I have **measured** rather than predicted, and it is flagged as such throughout.

CONTRACT-STATED / FIX-HIDDEN check: each pre-empt sentence states an observable property of the
output and none of them names the mechanism (no mention of two passes, ear clipping, link cycles,
signed area, or the event queue).

## 11b. Capability cross-product matrix (F-10) — REVISED after the harden pass

The first draft used **fill rule x sweep orientation**. That is a weak product: `EvenOdd` almost
never has interior vertices, so both `EvenOdd` cells are trivially "unchanged". Replaced with the
axes that actually interact.

**Axis 1 — overlap multiplicity** (winding depth 1 / 2 / 3+).
**Axis 2 — winding polarity** (all subpaths same-wound -> union; an opposite-wound subpath -> hole).

| | same-wound only | contains an opposite-wound subpath |
|---|---|---|
| **depth 1** | `single_square_unchanged` | `donut_unchanged` (hole corners are boundary) |
| **depth 2** | `two_squares_eliminates` | `hole_inside_overlap_d2` **<- off-diagonal, the decider** |
| **depth 3+** | `three_squares_eliminates` | `hole_straddling_seam`, `overlap3_with_hole` **<- off-diagonal** |

Each cell runs under **both** sweep orientations (orientation is a third axis carrying trap T2).

**Why the depth-2 x opposite-wound cell is the decider.** A single opposite-wound subpath placed
inside a depth-2 overlap does **not** punch a hole — winding goes 2 -> 1, still filled. Producing a
real hole there needs **two** opposite-wound copies (2 -> 0). Measured locally:

| fixture | base | simplified | area | reading |
|---|---|---|---|---|
| `hole_inside_overlap` (one CW copy) | 14v/18t | 8v/6t | 13600 = plain union, **no hole** | naive fixture, proves nothing |
| `hole_inside_overlap_d2` (two CW copies) | 14v/16t | 12v/12t | 16000 = 16400 union − 400 hole | **real hole AND 2 interior vertices removed** |
| `hole_straddling_seam` | 14v/16t | 12v/12t | 14800 = 15000 − 200 (hole half-cancelled by the seam) | partial hole |

This cell kills any implementation that classifies interiority from the *input paths* (winding
sign, point-in-union, "a clockwise subpath is a hole") rather than from the *output mesh*. It needs
**zero new description words** — the contract already states both axes.

Predicted failure mode for the off-diagonal cells is **under-firing**: the fixpoint stalls and
leaves interior vertices behind while the mesh stays valid and the area stays right. That is what
makes it misdirecting.

**Verified: the reference survives all 28 cells** (14 fixtures x 2 orientations), zero stalls, zero
area drift, and the multi-loop patch fallback never fires.

Scope audit: "interior" is scoped to the WHOLE filled region, not per subpath. Stated explicitly.
Format-noun audit (L24): "vertex", "triangle", "boundary" all mean the emitted mesh's units, not the
input path's; the meta says "emits" / "output" every time to fix the extent.
Tolerance-fixture audit (L25): the fixpoint rule's N-1 fixture is `pentagram_unchanged` — a shape
with self-intersections and zero interior vertices, asserting **nothing happens**.

## 12. Tier + category

- **Tier:** Olympus (one tier since the 2026-07 sprint).
- **Category:** `feature-request` — net-new public option and a net-new output contract. Matches
  the `Add` verb.

## 13. Predicted pass rate

- **Predicted: 10-25%.**
- Reasoning: five traps on five different axes, three interdependent. T4 is a genuine architectural
  wall (measured: `FillVertex` cannot be stored). T2 is a measured silent-stall trap. T3 puts 185
  existing tests on the shared chokepoint. Against that, the contract is fully stated and a working
  algorithm fits in ~110 lines, so it should not read 0%.
- Solvability evidence: I built and ran a correct prototype locally against 8 fixtures, both
  orientations. Solvable.
- Sanity: under the `<=40%` ceiling, above the `0%` reject floor.

## 14. Quality-gate checklist

- [x] Repo understanding: sweep-line fill tessellator, `event_queue` -> `fill` -> `monotone` ->
      `FillGeometryBuilder`; test convention is `crates/tessellation/tests/*.rs`; template cited
      (`approved-problems/lyon-arcs-join/test.patch`).
- [x] Existing-PR check: **zero open PRs repo-wide**; feature-class searches (`internal vertices`,
      `interior vertices`, `simplify`, `boolean`, `non zero`, `self-intersect`) return no hit that
      implements this. Commands pasted in `feedback.md`.
- [x] Maintainer philosophy: issue #871's only comment INVITES an implementation ("unless you or
      someone else feels adventurous") but calls the current behavior "sort of by design" — hence
      **opt-in, default unchanged**. The issue INFORMS; the scope and contract here are invented.
- [x] Closest approved opened side-by-side: `approved-problems/lyon-arcs-join` (same repo).
- [x] Title verb-led, 7 words, names the subsystem.
- [x] Shape declared with citation.
- [x] Public API surface lists every asserted name.
- [x] Canonical output form spelled out (§ 4).
- [x] <=1 codebase-inferable requirement (exactly 1, § 5).
- [x] Description draft under the cap, no headers, no labels, no `Box<>`.
- [x] File footprint sketched against real source with real current LOC.
- [x] ~278 meaningful LOC across 4 files — clears the `>=200` / `>=2` floor with buffer.
- [x] 1+ pure-function helper per described behavior (§ 8).
- [x] Fixpoint loop included verbatim.
- [x] Test outline 4-block, scenario-encoded names.
- [x] 5-axis coverage planned.
- [x] Forced bounds documented (§ 10) — the `FillVertex` borrow is the load-bearing one.
- [x] 5 traps, each with F-id, pre-empt sentence, catching test.
- [x] Traps on different axes; >=1 interdependent (3 are).
- [x] § 11b cross-product filled, off-diagonal cells have tests.
- [x] Predicted pass <=40% and >0%.
- [x] Category matches description.
- [x] Not pattern-followable — nothing in lyon post-processes tessellator output.
- [x] Flakiness: base suite verified deterministic 4/4 runs; all planned assertions are exact
      (integer counts, set equality, boolean identity) or ratio-free area comparisons.

### Gates already run (evidence in `feedback.md`)

| Gate | Result |
|---|---|
| Gate 1 BEHAVIORAL-F2P-GAP | **PASS** — two overlapping squares under `NonZero` emit interior vertices `(20,20)` and `(40,40)`: 10v/10t vs the 8v/6t reference octagon at identical area 2800 |
| Gate 6 REPRODUCE-ON-BASE | **PASS** — reproduced through `FillTessellator::tessellate_path` on a clean base checkout |
| Skeleton probe | **PASS** — working prototype; both orientations reach the reference exactly; six_circles 246v/416t -> 74v/72t with area preserved to 7 digits |
| Gate 9 DETERMINISM | **PASS** — `cargo test -p lyon_tessellation` (192 tests) byte-identical across 4 runs |
| Gate 7b EXCLUSIVITY | **PASS** — zero open PRs repo-wide, no merged PR in this class |
| Gate 10 REPO-QUOTA | **PASS** — 1 of 6 used (`approved-problems/lyon-arcs-join`) |

### Why this is not a duplicate

Closest approved: `approved-problems/lyon-arcs-join` (same repo). That is the **stroke** tessellator,
a per-corner local geometry construction with a closed-form answer, asserted on stroke area and
join polylines. This is the **fill** tessellator, a whole-mesh global property with no closed form,
asserted on boundary-set and region identity. Different subsystem, different trap category
(local construction vs global classification + baseline regression), no shared API surface.

`rejected/lyon-stroke-to-fill` was the stroke-to-fill dissolve — also stroke-side and shelved.
Boolean path operations (#494) were rejected at scope-lock as a derivative magnet: this pick
deliberately does **not** implement polygon boolean ops. It never computes a union of input paths;
it only removes vertices from a mesh the existing tessellator already produced, and the region it
covers is required to be bit-for-bit the same region as before.

**Predicted iteration cycles: 2.**
