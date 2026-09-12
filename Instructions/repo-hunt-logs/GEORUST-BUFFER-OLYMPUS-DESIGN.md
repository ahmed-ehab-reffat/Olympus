# Olympus Design Draft — georust/geo planar `Buffer`

Status: DRAFT spec (pre-authoring). Pick-time gates NOT yet run (require repo clone). See § Mandatory gates.

---

## Part 1 — Hardness ranking of the hunt candidates

Ranked by the HARDENING selector: a **globally-coupled cross-subsystem wall where the OBVIOUS implementation is WRONG** (WRONG_LOGIC-inducing), that survives full fair specification, dodges every TOO-EASY dead class, and (per the float mandate) carries a LIVE float trap web that agents cannot text-parse or brute-force pointwise.

| Rank | Repo | Why this hard | LIVE float wall | Risk that caps it |
|---|---|---|---|---|
| **1** | **georust/geo** | Naive shoelace/orientation about origin is WRONG at large coords -> sign flip cascades into winding/overlay (glaredb-DISTINCT profile). Survivor class proven: go-geom polygonize approved 30%. Broad algorithm surface -> real cross-subsystem span. | Translation-invariance / catastrophic cancellation (truck A10 class, 8/10) | HOT/COLD inversion: 1900star daily-active flagship -> robustness core is maintainer-owned. Must pick a COLD additive feature, not the hot core. |
| **2** | **iliekturtles/uom** | Float conversion factors woven into a dimensional type system; `0-2` vs unary `-2` deduce different types (numbat A12, 5/11). Deep type-level, resists memorization. | float x typesystem (A12, proven) | Macro-generated code under-counts on human-LOC; affine-units is a famous long-open request -> derivative/in-flight risk. |
| **3** | **nical/lyon** | Sweep-line fill: one mis-ordered intersection corrupts the whole tessellation. Obvious epsilon-compare is WRONG on collinear/degenerate. Cross-crate (geom/path/tessellation). Deep-but-not-frantic. | Event-ordering robustness (globally-coupled) | Output = vertex/index buffers; harder to write clean behavioral asserts. Niche. |
| **4** | **faer-rs** | Naive Gram-Schmidt / no-pivot LU is WRONG -> loses orthogonality; reconstruction tolerances catch it. Globally coupled through the factorization. | Accumulation-order + pivoting cancellation | Linear-algebra decompositions are textbook (LAPACK) -> saturated-reference-port risk on the ALGORITHM (stability less so). |
| **5** | **dimforge/salva** | SPH density->pressure->force closes the loop across particles; obvious per-particle reduction is WRONG (not pointwise). Unusual domain, low saturation. | Neighbor-summation order + feedback | Small repo, LOC-floor risk; physics fixtures harder to make deterministic (flakiness gate). |
| **6** | **linebender/kurbo** | Arc-length via Gauss-Legendre + adaptive subdivision; naive local rule passes small curves, fails high-curvature/large-coord. Green's-theorem area cancellation. | Integration + epsilon interaction | Single crate -> caps cross-subsystem breadth toward Olympus-Okay. |
| **7** | **gpython** | S6 two-evaluators: `symtable` static analyzer + bytecode `vm` share one model; closure cell/free-var resolution spans symtable->compile->vm. Diamond-capable. | (not a float pick) | CPython semantics partly memorized; not a float web. |
| **8** | **ezno / tsz** | Narrowing across control-flow joins; type inference is a proven Nova blind spot ("defaults to overly restrictive"). | (not float) | TS-spec-convergent -> derivative; heavy to set up + test. |

**Raw-hardness leader = georust/geo.** Its float wall is the strongest and it is the only candidate with both a proven survivor class (polygonize 30%) AND enough algorithm breadth for a true cross-subsystem Olympus. The one thing that can kill it is the HOT/COLD inversion, so the FEATURE must be a **cold additive capability** with the robustness wall stacked on top (truck A10 method), never the hot robustness core itself or a dead validation/distance class.

**Chosen design target: georust/geo, planar `Buffer` (offset/dilation).** Rationale in Part 2.

---

## Part 2 — Feature selection (STEP 5: 3-5 ideas, ranked)

All are geo, all globally-coupled + float-sensitive. Scored for FAIR-hardness AND survival of the doctrine's dead-class / derivative / hot-core gates.

| Idea | Shape | Predicted pass | Verdict |
|---|---|---|---|
| **A. Planar `Buffer` (offset) for Point/Line/Polygon** | O-Pipeline-hard + O-Composite-add | **~10-15%** | **CHOSEN.** Cold (geo has no buffer), additive (new capability, not validation), globally-coupled (offset-then-resolve is whole-geometry), float-heavy, algorithm not spec-fixed -> low derivative. |
| B. `MakeValid` (OGC validity repair) | O-Algorithm-correctness | ~8% | REJECT-risk. Spec-convergent (JTS/GEOS canonical algorithm) -> DERIVATIVE class (kitesql/gql law); large + likely in-flight -> exclusivity. |
| C. Extend `is_valid` with reason-reporting + self-intersection rules | (validation) | ~40-60% | DEAD. Membership/validation contract = uniform-wrap (petgraph law). Fairness forces stating the rules -> hands the fix. |
| D. Topology-preserving simplification | O-Algorithm-coverage | n/a | ALREADY PRESENT (`SimplifyVwPreserve`). Dead. |
| E. Robust convex hull + rotating-calipers (min-area rect, width, diameter) | O-Composite-add | ~20% | Partly present (`ConvexHull`, `MinimumRotatedRect`) -> already-implemented + derivative risk. |

Buffer wins: it is the rare geo feature that is genuinely MISSING, is NOT a validation/distance dead class, is NOT a spec-fixed canonical algorithm (many valid offset approaches -> divergence-safe), and is intrinsically globally-coupled with a load-bearing float wall.

---

## STEP 1 - Olympus shape

**Primary: O-Pipeline-hard** (invent a transformation algorithm: offset every edge, then RESOLVE the overlaps/self-intersections into a valid result) **with O-Composite-add breadth** (new `Buffer` trait + config type spanning a new algorithm module, the boolean-ops union path, winding/orientation, arc densification, and geo-types).
- Best agent: **Vega** (O-Pipeline-hard 2/6 on seq-rewriter; O-Composite-add 3/5 on goja-using). Run Nova+Orion+Vega mix.
- Dominant expected verdict: **WRONG_LOGIC** (target >=25% -> subtle-algorithm signal) + MISSED_REQUIREMENT on the join/cap/erosion family + INTEGRATION_ERROR on the union path.

## STEP 2 - Shape targets

| Metric | O-Pipeline-hard band | This design |
|---|---|---|
| Files | 4-6 | 6-9 (1-2 new + wiring across algorithm/types/winding) |
| Solution eff-LOC | ~413 | **>=470** (design floor 450; buffer's join/cap/erosion families are genuine, not padding) |
| Tests | ~103 | 90-120 |
| Pass rate | ~15% | target 10-15% |

## STEP 4 - Complexity test

- Modifies 5+ existing files with complex logic? YES — new `buffer/` module + `algorithm/mod.rs` re-export + winding/orient reuse + boolean-ops union integration + geo-types conversions + prelude.
- Cross-subsystem entanglement? YES — offset generation -> arc densification -> boolean union -> orientation normalization all interact; a wrong join geometry produces a self-intersection the union must dissolve.
- Pattern-followable (3+ identical examples)? NO — geo has no offset/buffer precedent; the closest (`ConvexHull`, `BooleanOps`) are consumed, not copied.
- First attempt naturally breaks tests? YES — the naive "offset each edge outward independently" produces self-intersecting garbage at concave vertices and passes only convex fixtures.

---

## STEP 6 - Full spec

### Public API surface (disclose in meta - fairness floor)

- `Buffer` trait: `fn buffer(&self, distance: f64) -> MultiPolygon<f64>` implemented for `Point`, `Line`, `LineString`, `Polygon`, `MultiPolygon`.
- A `BufferStyle` config threaded via a builder-style call (name it, e.g. `buffer_with_style(&self, BufferStyle) -> MultiPolygon`): `join` (round / miter / bevel), `end_cap` (round / flat / square), `quadrant_segments: usize` (arc segments per quarter turn), `miter_limit: f64`.
- Orientation convention on output: shells counter-clockwise, holes clockwise (geo's `Winding`/`orient` convention - one codebase-inferable requirement).

### meta.md draft (~185 words, ASCII, dash-delimited, WHAT-not-HOW)

```
---
Repository: https://github.com/georust/geo
Issue: N/A
Commit: <BASE_COMMIT>
Language: Rust
Title: Add planar buffering for geometries
---
# Add planar buffering for geometries

geo can measure and relate geometries but cannot grow or shrink them, so there is no way to compute the region within a fixed distance of a shape. Add a `Buffer` trait whose `buffer` method returns the set of all points within a signed `distance` of the source geometry as a `MultiPolygon`.

A positive distance dilates and a negative distance erodes. A point buffers to an approximated disc, an open line to a corridor with configurable end caps, and a polygon grows its shell while shrinking its holes. Convex turns are rounded by approximating each quarter turn with `quadrant_segments` straight segments; a style selects round, miter, or bevel joins, with `miter_limit` bounding sharp miters before they fall back to bevel. Open lines accept round, flat, or square end caps.

Where offset edges from a concave turn cross, the crossing must be dissolved so the result is never self-intersecting. A negative buffer drops any ring whose area collapses, and a fully eroded polygon returns an empty `MultiPolygon`. Output shells are oriented counter-clockwise and holes clockwise. Buffering commutes with translation, including near coordinate magnitude 1e6.
```

Word/format checks: ~185 words (Olympus <=200 OK), no `##` headers, dash-prose, ASCII only (run `file meta.md` -> "ASCII text"), backticks only on API surface (`Buffer`, `buffer`, `distance`, `quadrant_segments`, `miter_limit`, `MultiPolygon`).

### Trap web (mapped to HARDENING arsenal) - 3 S/A traps, interdependent + misdirecting

1. **S2 composition (concave-overlap x validity):** offsetting each edge is individually obvious; the INTERACTION at a concave vertex (offset edges cross) requires dissolving the crossing. Naive per-edge offset passes convex fixtures, self-intersects on concave. Misdirects as a "wrong area" / invalid-output failure, not "you skipped the union." Fix = route the offset pieces through geo's boolean union - a discovery, not stated.
2. **A10 numerical-stability (translation invariance):** the commute-with-translation contract is documented (fair), but the fix (compute offsets/joins relative to a local anchor, or use robust orientation) is a discovery. At 1e6 the naive cross-product join point cancels -> wrong miter -> the invariance test fails. Orthogonal to trap 1 (truck: 8/10, moved 50->20% as an orthogonal wall).
3. **A8 polarity/boundary (negative buffer erosion):** positive buffer grows, negative shrinks - agents implement the positive path and mirror the sign, missing that erosion can COLLAPSE a ring (drop it) or vanish the whole polygon (empty result). "zero or more rings survive" trap (agents code `>=1`). Interdependent with orientation: an eroded shell that inverts must not resurface as a phantom hole.

Plus a **baseline-preservation (S3)** check: the union path must reuse geo's existing `BooleanOps` without regressing its tests - base mode runs the boolean-ops suite.

Architecture-jump guard: an agent might approximate buffer as "convex hull of discs" for points/convex polygons - add a concave-polygon-with-hole fixture that only the real offset+dissolve passes.

### Blind-spot pre-empts (from DESCRIPTION.md bank)

- Orientation canonical form stated ("shells counter-clockwise and holes clockwise") - pre-empts default-order.
- "zero or more rings survive" via "drops any ring whose area collapses ... returns an empty `MultiPolygon`" - pre-empts the `>=1` reflex.
- `quadrant_segments` arc count stated - pre-empts non-deterministic arc tessellation (tests assert vertex counts / area within tolerance).

### Files (MODIFY vs CREATE)

CREATE:
- `geo/src/algorithm/buffer/mod.rs` - `Buffer` trait + dispatch
- `geo/src/algorithm/buffer/offset.rs` - edge offsetting, join geometry (round/miter/bevel), caps
- `geo/src/algorithm/buffer/style.rs` - `BufferStyle`, `miter_limit`, `quadrant_segments`

MODIFY:
- `geo/src/algorithm/mod.rs` - register + re-export
- `geo/src/lib.rs` (prelude) - export `Buffer`, `BufferStyle`
- reuse `geo/src/algorithm/bool_ops` (union of offset pieces) - integration, not rewrite
- reuse `geo/src/algorithm/winding_order.rs` / `orient` - orientation normalization
- `geo-types` conversion touchpoints if a Line/Point disc helper is added

### LOC estimate (SOLUTION.md discipline: sketch hardest files)

- `offset.rs` (join geometry + caps + arc gen): ~200 eff
- `mod.rs` (dispatch across 5 geometry types + dissolve wiring): ~140 eff
- `style.rs` + config + orientation normalization: ~90 eff
- wiring/exports/reuse glue: ~50 eff
- **Total ~480 eff LOC** (clears 450 floor; gate on `.claude/hooks/effective_loc_check.py` -> `human-effective >= 450`). Not breadth-padded: joins/caps/erosion are orthogonal DEPTH.

### Test strategy (coverage-driven, behavioral, public API only)

Blocks: builder helpers (make Point/Line/Polygon/Polygon-with-hole) + assertion helpers (`assert_area_within(tol)`, `assert_no_self_intersection` via geo `Relate`/`is_valid`, `assert_orientation`).
- Positive buffer: point->disc (area ~ pi r^2 within arc tolerance), square shell grows by correct area, linestring corridor.
- Join family: round (vertex count ~ quadrant_segments per convex turn), miter (sharp corner extends to miter point), miter_limit fallback to bevel, bevel.
- End caps: round/flat/square on open linestring (distinct areas).
- **Concave dissolve wall:** L-shaped / star polygon buffered -> output is a single valid non-self-intersecting `MultiPolygon` (naive per-edge fails).
- **Erosion wall:** negative buffer shrinks shell + GROWS holes; ring-collapse drops the ring; full collapse -> empty `MultiPolygon`; a thin bar erodes to empty (not `>=1`).
- **Translation-invariance wall:** buffer(g).translate(v) == buffer(g.translate(v)) at v ~ 1e6 (area + vertex-set order-insensitive).
- Orientation: every output shell CCW, every hole CW.
- Baseline: base mode runs existing bool_ops + winding suites (S3 regression guard).
- Order-insensitive comparisons for independent output polygons (doctrine fairness floor).

Determinism/flakiness: fixed inputs, tolerance-based float asserts (no exact `==` on f64), no RNG/time/order dependence. Run new+base 3-5x identical.

### Dockerfile (Pattern: olympus-base-rust + cargo2junit, NO chmod)

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch && cargo build --workspace
CMD ["/bin/bash"]
```
test.sh: `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit`, build-fail fallback synthesizing a compilation `<testcase>`. Test filename random hex suffix (no `shipd`/`datacurve`).

---

## Mandatory pick-time gates BEFORE authoring a line (require clone -> flag to user)

1. **Clone + BASE_COMMIT** into `worktrees/geo`; verify last SOURCE commit < 12mo, license (MIT OR Apache-2.0 - allowed), stars, sub-count on the platform "Learn more" page.
2. **Already-implemented check** (the #1 kill risk): build current main, confirm NO `buffer`/`offset` capability exists (`rg -i "buffer|offset|dilate|minkowski" geo/src/algorithm`). geo tracks buffer as a known gap, but VERIFY.
3. **Exclusivity PR-diff (HARD gate):** `CANON=$(gh api repos/georust/geo -q .full_name)`; `gh pr list -R "$CANON" --state all --search "buffer offset"`; pull the diff of any hit - a public draft touching a `buffer` module = SHELVE. geo is HOT (daily) so this is a real risk.
4. **SIX-CHECK maintainer philosophy:** closed issues/PRs for "buffer" declined-by-maintainer language.
5. **Dedup:** grep `Olympus-Approved/`, `problems/`, `diamond-problems/`, `rejected/` for buffer/offset/geo (our go-geom work is twpayne/go-geom, a DIFFERENT repo - not derivative, but confirm no georust/geo buffer sibling).
6. **SMOKE-BATCH:** 3-5 cold opus/sonnet solvers in isolated worktrees on meta+repo; if any single-shots the concave-dissolve + erosion + translation walls, harden or pivot BEFORE a paid batch.
7. **Build-measure golden LOC** with the hook; confirm `human-effective >= 450` on the sketched reference before committing to the batch.

If gate 2 or 3 fails (buffer already exists or is in a public PR), pivot to rank #2 **uom affine-units** (run the same gates) - its float x typesystem wall is the next-hardest and lives in a less-frantic repo.
