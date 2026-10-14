# DESIGN.md - gonum-plot-exact-glyph-layout

Base: gonum/plot master `d56745857d70e2e68bbcb858ff76fa6000cd8442` (2026-04-22, = upstream HEAD on 2026-10-03).

## Phase 1 - Repo understanding

**Architecture (one paragraph).** Package `plot` owns the plot model (`Plot`, `Axis`, `Legend`) and the
layout: `Draw` removes a title band, sizes a vertical-axis band (`verticalAxis.size`) and a
horizontal-axis band (`horizontalAxis.size`), then pads the remaining area so plotter glyphs are not
clipped (`padX`/`padY` in plot.go), draws the axes on canvases that share the data area's extent, and
hands the data canvas to every `Plotter`. Plotters (package `plotter`) declare the ink they draw outside
their data point through `GlyphBoxer`: a `GlyphBox` is a location in normalised data coordinates plus a
rectangle offset in points. `Align` (align.go) tiles several plots so their data canvases line up. All
drawing goes through `vg/draw.Canvas` (a `vg.Canvas` plus a rectangle; `Crop`, `Tiles`) onto backends
(`vg/vgimg`, `vgsvg`, `vgpdf`, `vgeps`, `vgtex`, `vg/recorder`), and text is measured and drawn by a
`text.Handler` (`text.Plain`, `text.Latex`) over `font`.

**Subsystems and boundaries.**
1. `plot` layout: plot.go (Draw, DataCanvas, DrawGlyphBoxes, padX/padY, WriterTo, Save), axis.go
   (size/draw/GlyphBoxes per orientation), align.go, legend.go.
2. `plotter`: 12 GlyphBoxer implementations (scatter, labels, barchart, boxplot, line, errbars, ...).
3. `vg/draw`: Canvas, Crop, Tiles, text style alias.
4. `text` + `font`: Style.Rectangle (rotation-aware bounds), handlers, extents.
5. Backends + `cmpimg` (golden comparison: PNG pixel-exact, SVG/TeX byte-exact).

**High-entanglement zones.**
1. The padding solve: `padX`/`padY` feed Draw (axes AND data), DataCanvas, DrawGlyphBoxes and Align.
2. The axis trio: `size` (band thickness), `draw` (where text lands) and `GlyphBoxes` (what the solve
   sees) must agree per orientation, per label position, per rotation.
3. The writer path: WriterTo/Save are the only error-returning entry points, Draw/DataCanvas are not.

**Tests.** Go `testing`; root package tests in package `plot_test` (plot_test.go, align_test.go,
legend_test.go) and package `plot` (axis_test.go, labelling_test.go); goldens under testdata via
`cmpimg.CheckPlot`. Template: plot_test.go `TestIssue514` (recorder canvas + public API) and
axis_test.go (internal). The recorder test needs `go test -trimpath` outside a GOPATH layout.

## Phase 2 - Existing-PR / publicly-solved check (2026-10-03, canonical slug gonum/plot)

- PR searches, all states: padX, padY, glyph box, GlyphBox, padding, align, Align, clipped, clip,
  rotated label, label rotation, layout, DataCanvas, overflow, legend glyph, margin, tick label cut,
  cut off, Save error. Hits are merged history (#337 rotated tick-label padding, #439/#455 Align tile
  padding, #650/#708 descent, #762 Line GlyphBoxer, #780) plus ONE open PR:
- **#806 (OPEN, 2026-10-02, mikamikasuki, "Prepared with AI assistance")**: `axis.go` +2/-2 (centered
  axis-label glyph box at normalised 0.5 instead of `Norm(midpoint)`), axis_test.go +102. DIFF read in
  full. It does not touch the padding solve, overflow, Align, rotation or the PosRight/PosTop boxes.
  The account is a mass AI bug-fix sweep (about 50 PRs to unrelated repos on 2026-10-02/03). Softened
  rule 3: an AI-sweep mark counts only when it closes the gap class in the lane; this one fixes one
  box location. NOTE, not a kill. Keep the centered-label location out of the core.
- Issues read in full with comments: #773, #733, #722, #723, #724, #725, #294, #200, #569, #14, #89, #151,
  PR #190. #773 carries a MAINTAINER sketch (sbinet) of error plumbing: a private `draw` returning an
  error, padX/padY returning errors, WriterTo returning the error. It is plumbing, not the exact solve,
  and both maintainers favour an error there; kortschak: "Is there reason to not just make the sizes
  correct in the first place?". PR #190 (sticky `Err` on Plot) was declined in 2015: do not add an
  error field. Branch `origin/errors` (2017, unmerged) makes `Plotter.Plot` return errors; it does not
  touch layout and confirms Draw's signature should stay.
- No code snippet anywhere solves the padding as a constraint problem; `gh search code "func padX(p
  *Plot"` (hunter) found only stale copies of the closed form. Base..origin/master: 0 commits.

## Phase 3 - Candidates

| Candidate | One-line behavior | Verdict |
|---|---|---|
| **A. Exact glyph-aware layout** | widest data area keeping every glyph box in its region, defined overflow, exact Align | **PICK** |
| B. Align exact only (#733) | the most nameable single piece | rejected: magnet, thin (~70 eff) |
| C. Overflow error only (#773) | maintainer sketch exists | rejected: sketch = publicly designed, ~30 eff |
| D. Legend GlyphBoxer (#724) | legend placement is relative to the unpadded region; making it a box moves every legend golden | rejected: contradicts goldens |
| E. Area-dependent glyph boxes (#14) | new GlyphBox form with normalised extents | rejected: open design sketch in the issue, API change |

**Step A (TOO-EASY guard) on A.** (1) not a uniform wrap: the solve, the region rules, the writer path
and Align are different mechanisms. (2) not a single-subsystem mechanical transform: it is a constraint
solve plus its inverse inside a multi-surface layout. (3) the contract can be stated in full (regions,
widest, overflow, Align equality) and stays hard to derive. (4) not a port. (5) survives full spelling-out.
Pointwise-decoupled? No: every box constrains a shared (offset, width) pair and Align couples all plots
of a column. Recogniser/post-pass? No. Missing arm? No: there is no existing solver to add a case to.
**Risk classes recorded:** machinery-absorbed under-floor (the solver compresses; see section 7),
maintainer-filed open bugs as a magnet (#733 most nameable), single-package concentration.

**Step B (arsenal).** S3 baseline preservation through the shared padding chokepoint (every golden
goes through it); S5 dual path (Draw draws axes on canvases computed separately from DataCanvas;
Align consumes DataCanvas); S2 composition (region rule x box source x direction); A8 precedence
(overflow must be decided before Save touches the file); A9 exact-fit index (the two-extreme pair is
correct on every fixture with one box per side).

**Gate results (PICK-FILTER).** Gate 1/6 reproduced on base through the public API (scratch test,
deleted): (a) boxes X=0/MinX=-50 and X=0.3/MinX=-160 on 400pt: data canvas Min.X 55, second box left
edge -1.5 (clipped); (b) one box X=0.5 width 600 on 400pt: data canvas `{-Inf 5} {+Inf 300}`, WriterTo
error nil; (c) 2x2 Align with one plot carrying a box at X=0.1 MinX=-60: data widths 199.92 / 197.57,
left edges 66.26 vs 68.61 in one column. Gate 5: capability cold (layout features last 2021; #806 is a
one-box sweep fix). Gate 7b: PASS with the #806 note. Gate 8: defined (maintainer-filed bugs, both
maintainers endorse an error for #773; #190 constrains the channel). Gate 9: `go test -trimpath ./...`
3x identical (timing noise only), 132 top-level tests. Gate 10: no gonum/plot subs of ours.

## Phase 4 - Design

### 1. Title
Add exact glyph-aware layout to plot padding and Align

### 2. Shape
O-Composite-extend (refactor a shared aggregation consumed by several surfaces) with an
O-Algorithm-correctness core. Dominant expected verdict: MISSED_REQUIREMENT on region/overflow cells,
REGRESSION on goldens for over-broad region rules.

### 3. Public API surface (revised after the slice measured the repo's own tests)
No new exported names. Behaviour changes on existing API only:
- `(*Plot).Draw`, `(*Plot).DataCanvas`, `(*Plot).DrawGlyphBoxes` - one exact layout; never panic.
- `(*Plot).WriterTo` - returns `nil` and an error when the axes fit but no positive data size keeps
  every glyph box inside.
- `(*Plot).Save` - same error, decided before the file is created or truncated.
- `plot.Align` - equal, column/row-aligned data canvases.
Why no sentinel and no panic: `plotter.TestPolygon_clip` asserts Draw does not panic on a 1cm canvas and
`gob.TestPersistency` saves a 4x4pt plot expecting no error. A panic from Draw or an error for every
too-small canvas breaks both, so the overflow error is limited to the #773 case (axes fit, glyphs do
not) and a canvas smaller than its axes keeps today's no-error behaviour. Dropping the exported error
keeps the new tests compiling on base (no build-tag split, no compile-wipe hazard, L72/L99).

### 4. Canonical layout (the contract)
Per direction, the data area is the WIDEST (tallest) one for which every glyph box lies in its region:
- plotter boxes (`Plot.GlyphBoxes`, existing filters): beside the axes, i.e. right of the vertical-axis
  band and above the horizontal-axis band, below the title band;
- horizontal-axis tick-label and label boxes: anywhere across the canvas width (they may reach under
  the vertical axis), not past either canvas edge;
- vertical-axis boxes: anywhere in the canvas height below the title (they may reach down beside the
  horizontal axis);
- the data area itself lies beside the axes.
A box is ignored in a direction where its size is not positive; axis boxes outside the axis range
(not drawn) are ignored. The widest width is unique and fixes the offset.
Overflow (axes fit, no positive size fits): WriterTo/Save error; Draw/DataCanvas use the whole space
beside the axes in that direction (unpadded). Canvas smaller than axes+title: no padding, no error.
Align: one common data width W and height H; per column, each side's margin is the largest any plot of
the column needs AT W (rows likewise at H); W is the largest value for which the columns, their margins
and the tile padding fit the canvas width. Tolerance in tests: 1e-6 pt (L59).

### 5. Blind-spot pre-empts
- Region rule stated for each box source (pipeline-placement class).
- "widest" (rule resolution), "decided before anything is drawn or written" (compound order) for Save.
- Align margins "at that common width" (the iteration seam), stated as WHAT.

### 6. Description draft (slice; <= 200 words, human register, finalized in FINISH)
See meta.md.

### 7. File footprint (sketch; measured numbers in feedback.md)
| Action | Path | Raw | Meaningful | Reason |
|---|---|---|---|---|
| NEW | layout.go | ~110 | ~75 | bounds, box collection per source and region, the widest-fit solver |
| MODIFY | plot.go | ~70 | ~45 | private draw with error, Draw/DataCanvas/DrawGlyphBoxes on one layout, WriterTo, Save order, error var; padX..bottomMost deleted |
| MODIFY | align.go | ~90 | ~60 | exact common-size solve and per-tile crops |
| MODIFY (FINISH) | axis.go | ~60 | ~40 | rotated label extents in size/draw/GlyphBoxes for both axes, PosRight/PosTop boxes |
| MODIFY (FINISH) | plot.go | ~20 | ~14 | rotated title placement + its box |
MEASURED slice (layout.go + plot.go + align.go): **167 hook human-effective**, 262 raw (106/30/31).
FINISH must add ~85 of genuine surface (axis-label placement over the documented Position range
[-1,+1] with rotation for both axes, title placement/box, legend containment). Sketch for full lane
~235-260. **LOC risk is real** (TOO-EASY: every hunt sketch in the
150-265 band measured 0.5-0.8x). The solver compresses (pairwise or Newton-from-the-right, ~25 lines).
FINISH must add genuine surface, not padding; if the full lane measures < 200 hook human-effective,
the pick dies as machinery-absorbed.

### 8. Solution outline (helpers)
- `bound{off, slope}`: a lower bound `off - slope*w` on the room on one side of the data area.
- `sides.box(at, min, max, insetBefore, insetAfter)`: the two bounds of one glyph box.
- `sides.room(w)`: the largest bound per side at size w.
- `fit(length, cols []sides) (w, ok)`: largest w with sum(room before + w + room after) <= length;
  Newton from the right on a convex piecewise-linear function; overflow when no w > 0 fits.
- `(*Plot).layout() (x, y sides)`: collects bands, plotter boxes, axis boxes with their regions.
- `(*Plot).dataRect(c) (vg.Rectangle, error)`.
- `(*Plot).draw(c) error`; `Draw` panics on error; `WriterTo`/`Save` return it, Save before creating.
- Align: per-column/row `sides` merged, `fit` with cols/rows, then per-plot crops so each plot's own
  solve lands on the common rectangle.

### 9. Test outline (new file `layout_ee66e8_test.go`, package plot_test, recorder canvases)
SLICE as built: 11 F2P `TestExactLayout*` (fail on base, pass with reference) + 5 base-mode guards
`TestLayoutGuard*` (pass on both; they pin ordinary layouts numerically so an agent who regenerates the
repo goldens cannot hide a regression).

Buckets: widest solve vs an analytic optimum (binding pair NOT the unpadded extremes, three boxes);
region rules per source (horizontal-axis label reaching under a hidden vertical axis; vertical-axis
label down beside the horizontal axis; plotter box not allowed under the axis band); filters per
direction (box with zero X size still pads Y); overflow on Draw/DataCanvas (panic + errors.Is),
WriterTo (nil + error), Save (error, no file created, existing file untouched); Align equality and
column/row alignment with margins that depend on width; Align with a title on one plot; a plain plot's
data canvas unchanged from base (P2P guard).

### 10. Forced shapes
Go: `errors.Is(err, plot.ErrGlyphOverflow)`; panics carry an `error` value (recover() then type-assert).

### 11. Trap matrix (predicted, F-ids; every row a guess until a batch)
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| 1 | Keep the two-extreme pair (re-picked after padding) instead of a global solve | F-39 / A9 | A9 | which box binds | 3 (Align consumes the same solve) | three-box fixture whose binding pair changes |
| 2 | One region for every box ("all inside the data area") moves every plot with a tick at the axis end | F-12 (golden) / F-10 | S3 | which region | 1 | existing goldens + hidden-axis corner cells |
| 3 | Align by iterating DataCanvas or by margins measured once | F-22 / F-9 | S5 | Align vs single plot | 1 | width-dependent margins, 3 columns, title on one plot |
| 4 | Save creates/truncates the file before the layout fails | F-15 attempt-vs-effect / F-61 | A8 | writer order | - | pre-existing file untouched |
| 5 | Box ignored in one direction still constrains the other / is dropped in both | F-10 | S2 | per-direction filter | 2 | zero-width box that pads vertically |
| 6 (FINISH) | Rotated label: size, draw and GlyphBoxes disagree | F-9 (three consumers) | S6 | rotation | 1,2 | recording handler: drawn label bounds inside canvas |
| 7 (FINISH) | PosRight/PosTop label box located in data units | F-39 latent bug | A3 | label position | 6 | right/top label on a wide axis range |

### 11b. Cross-product matrix (F-10)
| | plotter box | h-axis box | v-axis box |
|---|---|---|---|
| horizontal | data region (beside band) | full width | (band) |
| vertical | data region (above band, below title) | (band) | full height below title |
Off-diagonal cells: h-axis box reaching left under a hidden v-axis (must stay in canvas, not padded
into the data region); v-axis box reaching down; plotter box with zero X size padding Y only. FINISH
adds rotation x position x axis.

### 12. Tier / category
Olympus, feature-request ("Add ...").

### 13. Predicted pass rate
25-40%. The kernel is fully stated and will be transcribed (L58); the band has to come from the region
rules, the writer order, Align's width-dependent margins and (FINISH) the axis trio under rotation.

### 14. Quality gates
Phase 1 5/5; Phase 2 searches above; no `##` in meta; API names listed; LOC measured after the slice;
traps on different axes (row 1 solve, row 2 regions, row 3 Align, row 4 writer order); F-10 cells listed.

## Phase 5 - Self-audit
- Hidden requirements: region rules, overflow channel, Save behaviour and Align semantics are all in
  meta.md. Tolerances everywhere (no exact float equality on solved values).
- Goldens (MEASURED, see feedback.md "Golden handling"): TestAlign's golden is unchanged by the exact
  Align (margins there do not depend on width). Six repo tests pin output in which base clipped a glyph
  and change by design: palette TestReverse, plotter TestColorBar_horizontal / TestColorBar_vertical
  (left tick label "0.5" cut at the canvas edge), TestFilledLine, TestTimeSeries and vgtex TestTexCanvas
  (rotated Y label pushed past the title band, 1.1pt in the TeX case). They leave base mode. Pixel
  goldens also pin last-bit rounding of the old closed form (rotation: 126.62304687500001 vs exact
  126.623046875 flips 2 pixels): four alternative correct solvers flipped TestRotation, TestLatex or
  TestBarChart, so 37 `CheckPlot` calls in 22 test files move to the repo's own `CheckPlotApprox(...,
  0.1)` convention (vg_test already uses 0.1); after that all four variants pass every base-mode test.
- Tests that pass on base: the P2P guard (plain plot data canvas) is base-passing by design and lives in
  base mode, not new mode.
- Not a duplicate: no plotting/layout pick in approved-problems/, problems/ or rejected/.
- Predicted iteration cycles: 3.
