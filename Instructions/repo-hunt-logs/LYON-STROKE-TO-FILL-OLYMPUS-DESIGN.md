# Olympus Design — lyon `StrokeToFill` (stroke-to-fill outline conversion)

Status: DRAFT spec, pick-time gates PASSED (2026-07-24). Remaining before batch: clone + BASE_COMMIT, build-measure golden LOC, SMOKE-BATCH.

## Pick-time gate results (all GREEN)

| Gate | Result |
|---|---|
| License | dual MIT OR Apache-2.0 (LICENSE-MIT + LICENSE-APACHE) - allowed |
| Stars / recency / active | 2590 stars, last commit 2026-05-03, not archived |
| Open issues | 18 (below the 100-1000 band; feature availability confirmed via #564) |
| Language / Docker | Rust workspace -> Pattern olympus-base-rust + cargo2junit |
| Already-implemented | NO - no `outline`/`stroke_to_fill`/`to_fill` in source |
| Exclusivity PR-diff | NO PR (all states) implements stroke-to-fill / outline |
| Maintainer philosophy | WELCOMED - nical on #564: "If you would like to contribute an implementation I'd be happy to take it" |
| Dead-class check | Passes: globally-coupled new transformation; NOT validation/distance/pattern-followable/uniform-wrap |
| Derivative risk | Low: algorithm not spec-fixed (multiple valid approaches; even pathfinder "glitches" per nical) -> divergence-safe. tiny-skia-path has an impl but that is a SEPARATE crate, not lyon; dedupe compares within-pipeline submissions, not external crates |

Meta uses `Issue: N/A` (NOT a link to #564) so the solver never sees the comment pointing at tiny-skia-path / pathfinder. Feature is presented as an original invention.

---

## STEP 1 - Olympus shape

**O-Pipeline-hard** (invent the outline transformation: offset both sides of each subpath, join, cap, then RESOLVE self-overlaps into a valid fill) **+ O-Composite-add breadth** (new module reusing the stroke vocabulary across `lyon_geom` offset/arc, `lyon_path` building, `lyon_tessellation` StrokeOptions/LineJoin/LineCap).
- Best agent: **Vega** (O-Pipeline-hard 2/6; O-Composite-add 3/5). Nova+Orion+Vega mix.
- Target: **10-15%**, WRONG_LOGIC >=25% (subtle-algorithm signal).

## STEP 2 - Shape targets

| Metric | Band | This design |
|---|---|---|
| Files | 4-6 | 5-7 (2 new + reuse/wiring) |
| Solution eff-LOC | ~413 | **>=460** (floor 450) |
| Tests | ~103 | 90-120 |
| Pass rate | ~15% | 10-15% |

## STEP 4 - Complexity test

- Modifies 5+ files with complex logic? YES - new `stroke_to_fill` module + algorithms re-export + reuse geom offset/arc + path builder + stroke-option enums.
- Cross-subsystem entanglement? YES - offset -> join geometry -> cap geometry -> overlap dissolve -> winding normalization all interact; wrong join produces a self-intersection the dissolve must remove.
- Pattern-followable? NO - lyon has a stroke TESSELLATOR (emits triangles) but no path-OUTLINE converter; different output type, no template to copy.
- First attempt naturally breaks tests? YES - naive per-segment offset self-intersects at concave/sharp turns and passes only straight/convex fixtures; closed-loop annulus and miter blow-up are missed.

---

## STEP 6 - Full spec

### Public API (disclose - fairness floor)

- `StrokeToFill` trait (or free fn) converting a stroked path into a filled outline `Path`:
  `fn stroke_to_fill(&self, options: &StrokeOptions) -> Path` implemented for `Path` / path slices.
- REUSE existing lyon types (do NOT invent new option enums - fairness + no-scope-creep): `StrokeOptions { line_width, line_join, line_cap, start_cap, end_cap, miter_limit, tolerance }`, `LineJoin { Miter, MiterClip, Round, Bevel }`, `LineCap { Butt, Square, Round }`.
- Output contract: a `Path` whose contours bound exactly the stroked region, fillable with the non-zero rule; outer contours counter-clockwise, inner (hole) contours clockwise.

### meta.md draft (~190 words, ASCII, dash-prose, WHAT-not-HOW)

```
---
Repository: https://github.com/nical/lyon
Issue: N/A
Commit: <BASE_COMMIT>
Language: Rust
Title: Convert strokes to filled outlines
---
# Convert strokes to filled outlines

lyon can tessellate a stroke into triangles but cannot express that stroke as a fillable path, so there is no way to obtain the outline a stroke would paint. Add a `StrokeToFill` conversion that takes a path and a `StrokeOptions` and returns a `Path` bounding exactly the region the stroke covers, using the existing `line_width`, `line_join`, `line_cap`, `miter_limit`, and `tolerance` settings.

Each subpath is offset by half the line width on both sides. Convex turns are joined per the `LineJoin` setting, and round joins approximate each turn within `tolerance`. A miter that would extend past `miter_limit` times the half width falls back to a bevel. Open subpaths are closed with the selected start and end `LineCap`; a closed subpath produces two contours, an outer and an inner, with opposite orientation and no caps.

Where the two offsets of a concave or tight turn cross, the crossing must be removed so the result never self-intersects. A subpath whose length is zero contributes a cap shape for round or square caps and nothing for butt caps. Outer contours are oriented counter-clockwise and inner contours clockwise. The outline is translation invariant, including near coordinate magnitude 1e6.
```

Checks: ~190 words (<=200 OK), no `##`, ASCII (`file meta.md` -> "ASCII text"), backticks only on API surface (`StrokeToFill`, `StrokeOptions`, `Path`, `LineJoin`, `LineCap`, settings names).

### Trap web (HARDENING arsenal) - 3 S/A traps, interdependent + misdirecting

1. **S2 composition (self-overlap dissolve):** offsetting each side + joining is individually obvious; where the inner offset of a concave/tight turn crosses itself the crossing must be dissolved. Naive impl passes straight/convex, self-intersects on concave. Misdirects as wrong-area / rendering artifact, not "you skipped overlap resolution." This is precisely where real implementations glitch (nical's #564 note).
2. **A10 numerical stability (miter blow-up + translation invariance):** at a sharp angle the miter apex tends to infinity; `miter_limit` must clamp to bevel, and the join-point cross-product cancels at magnitude 1e6. Both contracts documented (fair); the robust computation is the discovery. Orthogonal to trap 1 (truck class, 8/10, moved 50->20% as an orthogonal wall).
3. **A8 polarity (closed-loop annulus + caps):** open subpaths get caps at both ends; a CLOSED subpath gets NO caps and produces an outer + inner contour with OPPOSITE winding (an annulus). Agents cap uniformly and emit one contour for closed loops. Interdependent with winding: the inner contour must be clockwise or the non-zero fill inverts. Plus the zero-length-subpath cap/empty edge case ("zero or more contours" trap).

**S3 baseline preservation:** reuse `StrokeOptions`/`LineJoin`/`LineCap` and geom offset/arc primitives without regressing the stroke tessellator suite; base mode runs the tessellation tests.

**Architecture-jump guard:** an agent might reuse the fill tessellator to render, sidestepping outline generation. Add a fixture asserting the OUTPUT PATH's contour count + winding + area (not just that it tessellates), so only a real outline passes.

### Blind-spot pre-empts (DESCRIPTION.md bank)

- Orientation canonical form stated ("outer counter-clockwise, inner clockwise") - default-order pre-empt.
- "zero or more contours" via closed-annulus + zero-length rules - `>=1` reflex pre-empt.
- `tolerance` governs round-join/arc density - non-deterministic tessellation pre-empt (tests assert area within tolerance + contour counts).

### Files (MODIFY vs CREATE)

CREATE:
- `crates/algorithms/src/stroke_to_fill/mod.rs` - `StrokeToFill` trait + per-subpath dispatch (open vs closed), winding normalization
- `crates/algorithms/src/stroke_to_fill/offset.rs` - side offsets, `LineJoin` geometry (miter/miter-clip/round/bevel + miter_limit), `LineCap` geometry, overlap dissolve

MODIFY:
- `crates/algorithms/src/lib.rs` - module + re-export
- reuse `crates/geom` (`LineSegment` offset, `Arc` flattening within `tolerance`) - integration
- reuse `crates/path` (`Path`, `PathBuilder`, `PathEvent` iteration) - build the output outline
- reuse `crates/tessellation` `StrokeOptions`/`LineJoin`/`LineCap` (re-export path) - shared vocabulary

### LOC estimate (sketch hardest files)

- `offset.rs` (joins x4 + caps x3 + miter_limit + overlap dissolve): ~200 eff
- `mod.rs` (open/closed dispatch, subpath walk, winding normalize, zero-length): ~140 eff
- reuse glue + trait + re-exports + arc/offset helpers: ~120 eff
- **~460 eff LOC** (clears 450; gate on `.claude/hooks/effective_loc_check.py` -> `human-effective >= 450`). Depth (joins/caps/dissolve/annulus), not breadth.

### Test strategy (behavioral, public API only, deterministic)

Helpers: path builders (open polyline, closed square, concave L / star, tight arc, zero-length dot) + assertion helpers (`assert_area_within(tol)`, `assert_contour_count`, `assert_no_self_intersection`, `assert_winding`).
- Straight open segment -> rectangle outline (area = length * width within tol).
- Join family: sharp corner miter (apex distance), miter over limit -> bevel, MiterClip, round join (contour vertex density ~ tolerance), bevel.
- Cap family: butt / square / round on open ends (distinct areas + endpoint geometry).
- **Closed-annulus wall:** stroked closed square -> TWO contours (outer CCW + inner CW), inner hole area correct; NO caps.
- **Concave-dissolve wall:** L-shape / star stroked wide enough that inner offsets cross -> single valid non-self-intersecting outline (naive per-segment fails).
- **Miter blow-up + translation wall:** near-degenerate spike clamps to bevel; outline(p).translate(v) == outline(p.translate(v)) at v ~ 1e6 (area + contour set order-insensitive).
- Zero-length subpath: round/square cap -> cap shape; butt -> empty.
- Winding: every outer contour CCW, every inner CW.
- Baseline (S3): base mode runs existing stroke-tessellation + geom suites.
- Order-insensitive comparison for independent contours; tolerance-based float asserts (no exact f64 `==`); no RNG/time/order dependence; run new+base 3-5x identical (flakiness gate).

### Dockerfile

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch && cargo build --workspace
CMD ["/bin/bash"]
```
test.sh: `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit`, build-fail fallback synthesizing a compilation `<testcase>`; base mode `-p lyon_tessellation -p lyon_geom` (existing suites) with `--skip` on the new test module; new mode `-p lyon_algorithms --test <hex>`. Test filename random hex suffix, no `shipd`/`datacurve`.

---

## Remaining steps before a paid batch

1. `git clone https://github.com/nical/lyon worktrees/lyon`; `git rev-parse HEAD > BASE_COMMIT.txt`; confirm workspace builds under the Docker image.
2. Sketch the reference `offset.rs` + `mod.rs` in real code; run `effective_loc_check.py` -> confirm `human-effective >= 450`. If short, the honest depth lever is MiterClip + zero-length + annulus (already in scope), not breadth padding.
3. SMOKE-BATCH: 3-5 cold opus/sonnet solvers in isolated worktrees on meta+repo. If any single-shots the concave-dissolve + annulus + miter walls, harden (composition-first) before spending the platform batch.
4. Build meta.md/test.patch/solution.patch/Dockerfile; run FP check (both directions) + flakiness (3-5x) + ASCII + LOC gates; then Nova+Orion+Vega batch, target 10-15%.
