# DESIGN.md — weasyprint-page-floats

## 1. Title
Add page and column floats to WeasyPrint's paged layout

## 2. Shape classification
- Shape: O-Pipeline-hard. New out-of-flow scheme (`float: top` / `float: bottom`) threaded through CSS validation/computed values, box predicates, the block container's out-of-flow dispatch, the float placement engine, the page maker (pre-placement, deferral, re-make) and the multi-column balancing loop (column reference).
- Pass target: 20-35%. Best agent: Orion. Dominant verdicts: REGRESSION (existing float/footnote/column tests), MISSED_REQUIREMENT (column reference, deferral, re-make).

## 3. Public API surface
CSS only, through the existing render API: `float: top` and `float: bottom` accepted by the validator (alongside left/right/inline-start/inline-end/footnote/none). Tests use `render_pages` and read `page.children` box geometry, as every layout test in the repo does.

## 4. Canonical output form (the contract)
- A `float: top` box is removed from flow and placed at the top of the content area of the page on which it is first encountered during layout; a `float: bottom` box at the bottom. Horizontal placement follows `float: left` rules against the page content box (line-left edge, shrink-to-fit width unless specified, margins honoured).
- In-flow content of that page is laid out around the float exactly as around a normal float (lines beside a narrower float, everything else below a top float / above a bottom float); boxes establishing formatting contexts avoid it; `clear` clears it.
- Several top floats on one page stack downward in document order; bottom floats stack upward. Bottom floats sit directly above the footnote area; footnotes laid out on the same page keep their area below the floats and both reduce the in-flow space.
- Deferral: a page float that does not fit in the page's remaining content height (content height minus page floats already placed on that page, minus the footnote area) is placed on the next page instead, and its anchor content stays where it is. A float taller than an empty page's content area is placed on its page anyway.
- Page floats are monolithic (never fragmented) and are laid out once per page: when a page float is discovered, the page is laid out again from its starting point with the float pre-placed, so the float never overlaps content laid out before its anchor.
- Column reference: `float-reference` (`inline` | `column` | `page`, initial `inline`) picks the reference. With `inline` or `column` a page float uses the current column of the nearest multi-column container when there is one and the page otherwise; with `page` it always uses the page, and the multi-column container then starts below it. A column float is placed at the top/bottom of the area the columns occupy on the page, measured independently of the balanced column height, and one that does not fit moves to the next column, then to the next page.
- Anchor convergence: a page float belongs to the page that ends up holding the element it was declared in. When placing floats pushes that element onto a later page, the float is dropped from this page, deferred forward and the page is laid out again. Each float is considered at most once per page, so the loop terminates.
- A page float declared inside a nested block formatting context (overflow other than visible, flex/grid item, table cell, another float) still anchors to the page (or column), not to the nested context.
- Position and float interplay unchanged: `position: absolute/fixed`, running elements and notes compute `float: none` as today; `float: footnote` unchanged.

## 7. File footprint (SHIPPED, measured by the LOC hook)
| Path | raw / human-effective |
|---|---|
| layout/float.py | 116 / 85 (page_float_layout, page_floats_layout, page_float_key, page_float_reference, placeholder removal, clear + avoid_collisions arms) |
| layout/page.py | 94 / 81 (per-page registry, pre-placement, deferral, anchor-convergence loop, state save/restore, blank-page and make_all_pages hooks) |
| layout/column.py | 81 / 71 (per-column registry, re-render on discovery, deferral to the next column or page, columns avoid page floats) |
| layout/block.py | 26 / 19 (out-of-flow dispatch, column pre-placement) |
| css/computed_values.py | 12 / 10 (out-of-flow ancestor walk) |
| layout/__init__.py | 7 / 7 (context fields) |
| css/validation/properties.py | 9 / 6 (float keywords + float-reference) |
| formatting_structure/boxes.py | 8 / 6 (is_page_floated, is_in_normal_flow, establishes_formatting_context) |
| layout/inline.py | 6 / 5 (placeholder in a line box) |
| css/properties.py | 2 / 2 (initial value, table wrapper) |
| build.py, stacking.py | 2 / 2 |
TOTAL 412 raw / 343 human-effective across 13 files (round 3 added flex.py 7 and grid.py 9 for page floats in flex/grid containers, and grew float.py, page.py, column.py and block.py for the bottom-float exclusion model and the column-reference bottom; build.py left base after the flex override was removed).

## 8. Solution outline
- `Box.is_page_floated()` (top/bottom), `is_floated()` unchanged (so existing float code never sees page floats), `is_in_normal_flow()` excludes page floats.
- `LayoutContext.page_floats: dict[page_number -> list[(box, side)]]`, `pending_page_floats` (deferred to next page), `column_floats` (keyed by column index for the current columns layout), `register_page_float(box, side)` returning whether it is new for the page, `reset_page_floats_from(page_number)`.
- `block.py _out_of_flow_layout`: page float child → if `context.in_column` register for the current column and signal column restart; else register for the page and mark `context.page_float_discovered = True` (page re-make). The child produces no box in the flow.
- `float.py page_float_layout(context, box, containing_block, side, stack_offset)`: percentages, margins, shrink-to-fit width, content layout via block_container_layout with bottom_space -inf, position at the stack offset from the page/column top (or bottom), append to the ROOT excluded shapes of the page/column BFC.
- `page.py make_page`: after creating the root BFC and before laying out the note area / in-flow content, pre-place floats registered for this page (deferring those that do not fit, into the next page's registry), reduce `context.page_bottom` for bottom floats, then lay out; at the end, if a new page float was discovered during this pass, set `remake_state['content_changed']` so `make_all_pages` re-makes the page. `remake_page` truncates registries for pages after the one being re-made.
- `column.py`: wrap the per-column `block_box_layout` call in a `render_column` loop that pre-places column floats registered for that index (in the column BFC created by `block_container_layout` for `is_column` boxes) and re-renders when a new one is discovered; deferral moves registrations to the next column; registries reset at the start of every balancing pass.

## 9. Test outline
tests/layout/test_page_floats_<hex>.py using `render_pages` + `assert_no_logs`, geometry assertions on `page.children` (html > body children, the float being a body child at the page top). Buckets: validation (accepted keywords, computed none under absolute/running), single top float (position, width, content below, lines beside a narrow float), bottom float (position at page bottom, content above), stacking (two tops, two bottoms, top+bottom), deferral (float taller than remaining page height goes to next page; anchor stays; taller than a page stays), re-make correctness (content before the anchor is pushed down, no overlap, paragraph split across pages moves correctly), clear, nested BFC anchoring (float inside overflow:hidden div / table cell / float), footnotes interplay (bottom float above footnote area, in-flow space reduced by both), columns (float at column top, other columns unaffected, balancing height, deferral to next column, last column -> next page), multi-page documents with floats on several pages, existing float tests unchanged (base mode).

## 11. Predicted trap matrix
| # | Trap | F-id | Axis | Interdependent with |
|---|---|---|---|---|
| 1 | place the float at its encounter position and translate it up (no re-make) -> overlaps content before the anchor | F-1 | page pipeline | 2, 3 |
| 2 | register on the nested BFC's excluded shapes instead of the page root | F-3 | BFC scoping | 1 |
| 3 | deferral measured against the full page height instead of remaining height (stacked floats / footnotes) | F-15 | fits rule | 1, 4 |
| 4 | bottom floats vs footnote area ordering / page_bottom accounting | F-9 | bottom region | 3 |
| 5 | reference always page or always column, ignoring `float-reference` | F-10 cell | reference | 1 |
| 6 | registry not reset on re-make -> float duplicated or lost across passes | F-9 | state | 1 |
| 7 | stop placing floats at the first one that does not fit | F-15 | ordering | 3 |
| 8 | float stays on the page where its anchor was first seen, after the anchor moved | F-1 | convergence | 1, 3 |

## 13. Outcome
Authored 2026-09-12. 42 tests, 312 human-effective LOC across 12 files, 21 of 21 mutations killed, clean-room Docker validated in both directions, 3 identical runs per mode. No batch run yet.

## 12. Tier + category
Olympus; feature-request.
