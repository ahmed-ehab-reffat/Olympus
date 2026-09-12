# DESIGN.md — dropflow-min-max-sizing

## 1. Title
Add min and max sizing constraints to dropflow's block layout

## 2. Shape classification
- Shape: O-Composite-add (feature spanning parser -> style -> block layout -> float/inline-block shrink-to-fit -> replaced sizing -> margin collapsing), single kernel (clamp helpers + the re-resolved inline box model) feeding five surfaces.
- SHAPES.md § Pattern 11: new capability threaded through an existing multi-stage pipeline where the emitting stages already own the quantities the new stage constrains.
- Pass rate target: 20-35% (Orion-only batches at 24 tokens/run must show a pass within 3-4 runs).
- Best agent: Orion.
- Dominant verdict: MISSED_REQUIREMENT (a surface left unclamped) / REGRESSION (margin collapsing moved).
- Solver/our LOC ratio: ~1.3x.

## 3. Public API surface
Tests reach everything through the existing public API: `parse(html)`, `flow.layout`, `flow.reflow`, `element.query(sel).boxes[0].getContentArea() / getBorderArea()` ({x, y, width, height}), plus the hyperscript `style({...})` object.
New public names:
- CSS declarations `min-width`, `max-width`, `min-height`, `max-height` in style attributes and stylesheets. Values: length (px, em, cm...), percentage, and `none` for the max properties (`auto` is not a valid value; unparseable values are dropped like any other bad declaration).
- Hyperscript style keys `minWidth`, `maxWidth`, `minHeight`, `maxHeight` on the object passed to `style()`. Same value forms (number = px, `{value, unit: 'em'}`, `{value, unit: '%'}`, `'none'`).
- Initial values: min = 0, max = none. Not inherited.

## 4. Canonical output form (the contract, all stated in meta.md)
- Clamp order: the used content size is `max(min, min(max, tentative))`; when min exceeds max, min wins.
- `box-sizing` applies to min/max exactly as to width/height (border-box minimums and maximums include padding and border).
- Percent min/max-width resolve against the containing block's width. Percent min/max-height resolve against the containing block's height only when that height is definite (specified, or the initial containing block); otherwise min behaves as 0 and max as none.
- Block-level boxes: the clamp is applied to the tentative width the ordinary rules produce, and the horizontal margins are then re-resolved against the clamped width as if it had been specified (so `max-width` plus `margin: 0 auto` centers, and the over-constrained rule fills the remaining space on the end side).
- Auto heights (from children or line boxes) are clamped; a specified height is clamped too.
- Floats and inline-blocks: shrink-to-fit widths are clamped, and the intrinsic contribution every box makes to an ancestor's shrink-to-fit width is clamped by that box's own min/max-width (percentages ignored in contributions).
- Replaced boxes (images): a specified dimension is clamped; a dimension derived from the other through the intrinsic ratio is derived from the clamped value and then clamped itself; when both are auto and the image has a ratio, the CSS 2 §10.4 constraint table decides.
- Margin collapsing: a box whose resolved min-height is greater than zero does not collapse its top and bottom margins through, and its bottom margin does not collapse with its last child's bottom margin.

## 5. Blind-spot pre-empts
- "the horizontal margins are re-resolved against the clamped width as if that width had been specified" (compound-order).
- "these constraints also apply to intrinsic (shrink-to-fit) contributions" (pipeline-placement).
- "a box whose min-height resolves to more than zero no longer collapses through" (stated inverse of the existing collapse rule).
- Codebase-inferable (the 1 allowed): where the auto height of a block container of inlines is set.

## 6. Description draft
See meta.md (written after the reference is measured).

## 7. File footprint
| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | src/style.ts | 1152 | +140 | ~110 | declared/computed/used fields, initial values, logical maps x3, 4 getters with percent + box-sizing, clamp helpers, definite-height check |
| MODIFY | src/layout-flow.ts | 1903 | +170 | ~140 | re-resolved block inline box model, clamped auto/specified heights at 3 sites, shrink-to-fit clamp, contribution clamp, replaced constraint table, collapse exemptions |
| MODIFY | src/parse-css.pegjs | ~1000 | +20 | ~16 | four declarations |
| MODIFY | src/parse-css.js | generated | +~120 | 0 (generated) | peggy regeneration |
TOTAL ~330 raw / ~265 meaningful across 3 hand-written files. Measure with the hook BEFORE tests (framework-maturity law).

## 8. Solution outline
- `Style.getMinInlineSize(cb)` / `getMaxInlineSize(cb)` -> number | 'none' (content-box terms, box-sizing adjusted, percent resolved).
- `Style.getMinBlockSize(cb)` / `getMaxBlockSize(cb)` -> same, percent only against a definite containing block height.
- `Style.clampInlineSize(cb, size)` / `clampBlockSize(cb, size)` -> `max(min, min(max, size))`.
- `Style.clampIntrinsicInlineSize(size)` -> same with percentages ignored.
- `Style.hasMinBlockSize(cb)` -> resolved min-height > 0 (margin collapsing exemption).
- `resolveBlockInlineMargins(box, cb, inlineSize)` extracted from `doInlineBoxModelForBlockBox`; the caller computes the tentative content width, clamps, and if it changed re-runs the resolution with the clamped width as specified.
- `FormattingBox.getDefiniteInnerInlineSize` / `getDefiniteInnerBlockSize` clamp specified sizes.
- `ReplacedBox.getConstrainedSize()` implementing the constraint table; both accessors read from it.
- `layoutContribution` clamps the computed contribution; `layoutFloatBox` clamps the shrink-to-fit content width; `positionBlockContainers`, `finalize`, `doTextLayout` clamp auto heights; `canCollapseThrough` and `boxEnd` consult `hasMinBlockSize`.

## 9. Test file outline
Path: test/sizing-constraints-<hex>.spec.js, plus `test/ci-<hex>.js` entry mirroring ci.js (environment + memory + the new spec) for `new` mode.
Block 1 imports (chai, dropflow, parse, register font). Block 2 helpers: `reflow(html, w, h)`, `box(sel)`, `content(sel)`, `border(sel)`. Block 3 assertions: none beyond chai. Block 4 buckets:
- parsing/api: html declarations, hyperscript keys, `none`, percent, em, box-sizing, initial values, not inherited.
- block width: max clamps, min clamps, min beats max, auto-margin centering after clamp, over-constrained end margin, rtl over-constrained, percent cb.
- block height: specified clamped, auto-from-children clamped, auto-from-lines clamped, BFC root clamped, percent against definite/indefinite cb, sibling positions after a clamp.
- margin collapsing: min-height blocks collapse-through, min-height blocks last-child bottom collapse, zero min-height still collapses, percent min-height against auto parent still collapses.
- floats/inline-blocks: shrink-to-fit clamped both ways, float wider than cb via min-width, child max-width limits parent's shrink-to-fit, percent ignored in contributions, min-height on float.
- replaced: img with max-width keeps ratio, min-height only, both constraints ratio rows (the two rows where sequential clamping differs), specified width + max-height, inline img.
- cross-product: border-box + max-width + auto margins, max-height on float containing text, inline-block with min-width inside float with max-width.

## 10. Forced bounds
TS repo, tests in JS: none. Hyperscript style keys must be typed on `DeclaredStyleProperties`.

## 11. Predicted trap matrix
| # | Trap | F-id | Class | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | clamp applied after margin resolution | F-9 | S3 chokepoint | inline box model | 3 (same kernel used by floats) | natural place is setInlineOuterSize; margins already computed | "margins are re-resolved against the clamped width" | max_width_with_auto_margins_centers |
| 2 | min-height and margin collapsing | F-3 | S2 composition | block formatting | 4 (height clamp sites) | collapse code looks only at height | stated inverse sentence | min_height_stops_collapse_through |
| 3 | contributions not clamped | F-17 | S4 machinery-riding | intrinsic sizing | 1 | agents clamp used sizes only | "intrinsic contributions" sentence | child_max_width_limits_float_width |
| 4 | replaced table rows | F-8 | A naive-dominant-reading | ratio sizing | 3 (image contributions) | sequential clamp differs on 2 rows | §10.4 reference | img_min_both_keeps_ratio |
| 5 | percent min/max-height vs indefinite cb | F-10 cell | S2 | value form | 2 | resolve against 0 -> collapses everything | stated rule | pct_max_height_in_auto_parent_is_none |

## 11b. Cross-product matrix
Axis A: {block, float/inline-block, replaced}; Axis B: {width, height} x {min, max}; Axis C: value {px, %, em, none}; box-sizing {content, border}. Off-diagonal cells listed in § 9 (float max-height with text, inline-block min-width inside a float with max-width, border-box max-width + auto margins, percent min-height in auto parent, inline img max-width).

## 12. Tier + category
Olympus; feature-request (Add).

## 13. Predicted pass rate
25-35%. Every surface is stated, so the difficulty is coverage: five sites in two files, one of which (margin collapsing) is far from the sizing code, and one of which (contributions) is invisible unless a float's width is asserted.

## 14. Checklist
See feedback.md round log. Phase 2 searches run: `gh search issues/prs --repo chearon/dropflow "max-width"`, `"min-height"` (only #3 taffy and #34 abs-pos), branch compare of all four side branches (no sizing work), commit stream grep `min|max` (0 relevant).

Why not a duplicate: the two taffy probes were flexbox alignment/visibility features in a Rust engine; quint/makerjs/avr8js are unrelated TS repos. Predicted iteration cycles: 2.
