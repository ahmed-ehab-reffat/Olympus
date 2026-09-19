# weasyprint-page-floats — feedback / iteration log

## Summary

- Repo: Kozea/WeasyPrint (Python HTML/CSS to PDF engine, BSD-3-Clause, 9584 stars, pushed 2026-09-10, active maintainer liZe).
- Base: d21889a799c760399b9e2cd06c8bc7ad5aec7144 (weasyprint 70.0, master HEAD at pick time).
- Feature: CSS Page Floats. `float: top` / `float: bottom` plus the `float-reference` property, threaded through CSS validation and computed values, the box predicates, the block container's out-of-flow dispatch, the float placement engine, the page maker (pre-placement, deferral, anchor convergence) and the multi-column balancing loop.
- Issue: https://github.com/Kozea/WeasyPrint/issues/259, open since 2015. Maintainer liZe on 2026-06-03: "we would be happy to help if someone wants to implement them!". No PR in any state implements page floats.

## Pick gates

| Gate | Result |
|---|---|
| Licence | BSD-3-Clause, permissive, no vendored copyleft |
| Stars / activity | 9584 stars, pushed one day before pick, CI green on default branch |
| Exclusivity | PR search by feature class over all states: nothing touches page floats. The nearest float PRs (#2828, #2838, #2853, #2856, #2728) are 20 to 160 line fixes to ordinary float pagination and do not touch the page maker |
| Repo quota | 0 of 6 prior submissions against this repo |
| Dedup | No float, page-layout or CSS-engine pick in approved-problems/, problems/ or rejected/ |
| Maintainer philosophy | Explicitly invited, no declined issue in the class |
| Flakiness | Base suite deterministic over 3 runs in the container |

## Deliverables

| File | State |
|---|---|
| BASE_COMMIT.txt | d21889a7... |
| meta.md | 420 body words, ASCII, frontmatter, feature-request |
| test.patch | test.sh (100755) + tests/layout/test_page_float_729ab9.py (42 tests) |
| solution.patch | 12 files, human-effective 312 |
| Dockerfile | olympus-base-python plus pango, harfbuzz-subset, ghostscript and DejaVu fonts |

## Harness

- base mode: `tests/layout tests/css tests/test_boxes.py tests/test_stacking.py tests/test_html.py`, with the new file ignored. Four inline tests are deselected: `test_breaking_linebox_regression_6`, `_10`, `_13` and `test_font_stretch`. All four assert line-breaking metrics of a system sans font that the base image does not carry (the repo's own CI gets them from the GitHub runner image), they fail identically with and without the solution, and none of them touches floats or pagination.
- Suites left out of base mode entirely: `tests/draw`, `tests/test_pdf.py`, `tests/test_api.py`, `tests/test_text.py`, `tests/test_fonts.py`, `tests/test_unicode.py`, `tests/test_acid2.py`, `tests/test_url.py`. They render to PDF and compare pixels or shell out to external tools, so they depend on the exact font stack rather than on layout.
- new mode: the single new test file.
- JUnit via `--junitxml`, with a synthetic failure XML carrying the last 40 lines of pytest output if no test case is produced.

## Local validation

- New suite: 42/42 pass with the solution, 42/42 fail on base (source-only stash).
- Full local suite, solution applied: 3364 passed, 1 pre-existing failure (`test_table_vertical_align`, which needs Ghostscript and passes in the container).
- LOC hook: human-effective 312 across 12 files (page 81, float 85, column 71, block 19, computed values 10, validation 6, boxes 6, context 7, inline 5, properties 2, build 1, stacking 1).
- Clean-room container (fresh clone at base plus test.patch, image built from the submission Dockerfile, `--network none --user 1000:1000`):

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 40 of 40 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 42 of 42 pass |

  The three extra base testcases with the solution are the repo's own generic property suites (`test_math_functions_percentage_and_font_unit`, `test_empty_property_value`, `test_variable_fallback`) picking up `float-reference`; all three pass.
- Flakiness: 3 runs of each mode in the container, byte-identical test/failure/error/skip counts every time.
- Both patches apply and revert cleanly on a fresh checkout at the base commit, in both orders.

## Mutation sweep

21 single-site mutations, one per meta.md clause chokepoint. Every one kills at least one new test:

validator rejects top/bottom; page float stays in flow; no shrink-to-fit; float is fragmented; content ignores the page float in `avoid_collisions`; `clear` does not clear it; top floats do not stack; bottom floats do not stack; bottom float ignores the footnote area; `float-reference` rejected; reference always page; reference always column; columns overlap a page float; column deferral skips the next column; no deferral at all; a deferral stops later floats; a tall float is never placed; a float does not follow its anchor; nested contexts are not searched; a float inside a footnote stays a page float.

Two survived the first pass and got dedicated tests: `float-is-fragmented` (the existing tall-float test used a fixed height, so nothing broke) and `footnote-float-stays-page-float` (the page-level assertion could not see inside the footnote area). After adding `test_a_page_float_taller_than_the_page_keeps_all_its_content` and `test_a_page_float_inside_a_footnote_floats_inside_the_footnote_area`, both are killed.

## Implementation notes (four real defects found by the repo suite)

1. Registering column floats by mutating a shared dict with `setdefault` created spurious keys and broke 8 existing column tests. The registry is now read-only from `block.py` and deferrals travel back as a return value.
2. The column fit test originally used the balanced column height, so balancing evicted floats that fit at full height. It now measures against the whole area the columns occupy on the page.
3. A column float deferred out of the last column was rediscovered from its anchor on the next pass and deferred again forever. A per-pass seen-set fixes the loop.
4. A float whose anchor moved to a later page once floats were placed stayed on the original page. The page maker now drops such a float, defers it forward and re-lays the page out, which terminates because each float is considered at most once per page.

## Predicted traps (to compare against the batch)

1. Place the float where its anchor was reached and translate it up, instead of laying the page out again with the float pre-placed (F-1). Content laid out before the anchor then overlaps the float.
2. Register the float on the nested formatting context's excluded shapes rather than the page root (F-3).
3. Measure "does it fit" against the full page height instead of the space left by floats already placed and by the footnote area (F-15).
4. Get the bottom region order wrong: bottom floats versus the footnote area and `context.page_bottom` (F-9).
5. Treat the column as the reference always, or the page always, instead of honouring `float-reference` (F-10 cross-product).
6. Let the registry survive a re-make, so a float is duplicated or lost across passes (F-9).
7. Stop placing floats at the first one that does not fit, instead of continuing with later floats that do.

## Attempt history

| # | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-12 | Authored end to end | 42 tests, validated locally and in a clean-room container, 21/21 mutations killed |
| 1 | 2026-09-12 | Platform precheck round 1 | 1 FAIL + 3 warnings, see below |
| 2 | 2026-09-12 | Platform precheck round 2 | alignment FAIL on undocumented interface, fixed; re-validated |
| 3 | 2026-09-12 | Platform precheck round 3 | derivative now PASSES; Solution Quality FAIL on 4 comprehensiveness gaps, all real, all fixed; 13 new tests |
| 4 | 2026-09-12 | Platform precheck round 4 | Solution Quality FAIL on 3 more gaps: 2 fixed in code, 1 resolved by stating the exclusion; 5 new tests |
| 5 | 2026-09-12 | Platform precheck round 5 | Test Quality FAIL caused by my own round-4 wording, reverted; Solution Quality FAIL on cross-container float adoption, fixed; 9 new tests |
| 6 | 2026-09-12 | Platform precheck round 6 | Test Quality PASS (61/61 fair, 34/35 covered); Solution Quality FAIL on nested-multicol reentrancy (an infinite loop), fixed; hang guard added |
| 7 | 2026-09-13 | Platform precheck round 7 | Solution Quality FAIL (Code Quality 2/3): forced break inside a float dropped content, flex/grid floats on the wrong fragment; both fixed; 3 new tests |
| 8 | 2026-09-13 | Platform precheck round 8 | Verify FAIL: test.sh required pytest-timeout the platform environment lacked, made conditional; Test Quality PASS (65/65); found and fixed an unreported oversized-bottom-float bug; 6 new tests |
| 9 | 2026-09-13 | Platform precheck round 9 | Verify FAIL: 3 property-parametrized repo cases appear only with the solution, deselected; Test Quality PASS (72/72); found and fixed an unreported nested-multicol overlap; 1 new test |
| 10 | 2026-09-13 | Platform precheck round 10 | Solution Quality FAIL (Code Quality 3/3): a named-page change inside a page float dropped content, the sibling branch of the round-7 forced-break fix; fixed and the whole break class inventoried; 1 new test (2 cases) |
| 11 | 2026-09-14 | Platform precheck round 11 | Solution Quality FAIL: "a positioned box" was broader than the code's absolute/fixed check, wording aligned; found and fixed an unreported bottom-page-float bug in multicol; 10 new test cases |
| 12 | 2026-09-14 | Test Quality coverage (advisory) | Two partial requirements, both test-only (solution already correct, re-probed): fixed ancestors and column references through nested contexts; 12 new test cases |
| 13 | 2026-09-14 | Platform precheck round 13 | Solution Quality FAIL (Code Quality 2/3): a float nested in a later flex/grid item was stacked before an earlier direct float; fixed with one document-order sort in both collection paths; 12 new test cases |
| 14 | 2026-09-14 | Platform precheck round 14 | Solution Quality FAIL: a page float inside a continued ordinary float overlapped that float's page-2 fragment; broken out-of-flow layout moved into the retry loop, which exposed a round-3 float rule 5 bug, also fixed; 3 new tests |
| 15 | 2026-09-14 | Auto Review | Description 3/3, Tests 3/3, Solution 1/3: two High fragment-ownership defects (reverse flex drops the float; grid emits it on a predecessor's first fragment); fixed with one finished-item rule, which exposed a pre-existing grid re-entrancy bug, also fixed; 4 new test cases |
| 16 | 2026-09-14 | Auto Review | Description 3/3, Solution 3/3, Tests 1/3: three coverage gaps (inline anchor, replaced float, painting); solution already correct on all three when probed; 7 new test cases, each trap-proven against its hunk |
| B1 | 2026-09-14 | Batch 1: 10 Nova | 0 of 9 graded runs passed (70-86 of 131 new tests failing each), Nova 7 produced no artifacts; unsolvable as submitted |

## Platform precheck, round 1 (2026-09-12)

### FAIL: Python installs are editable or test invocation is documented

The Dockerfile installed only the dependencies, never the project, so `import weasyprint` resolved to `/app` only while the cwd happened to be `/app`. Fixed by installing the project editably:

    pip install --no-cache-dir --no-build-isolation --no-deps -e .

with `flit_core==3.12.0` pinned ahead of it (weasyprint's build backend) and `--no-deps` so the explicit pins stay authoritative. Verified in the container from a foreign cwd:

    $ docker run --rm --network none --user 1000:1000 -w /tmp weasyprint-pf bash -c "python -c 'import weasyprint; print(weasyprint.__file__)'"
    /app/weasyprint/__init__.py

meta.md was left alone; the editable install is the fix that does not add harness detail to the description.

### WARNING: unpinned pip installs

All thirteen pip requirements now carry `==` pins, resolved from the base image and frozen: pytest 9.0.3, pydyf 0.12.1, cffi 2.0.0, pycparser 3.0, tinyhtml5 2.1.0, tinycss2 1.5.1, cssselect2 0.10.1, webencodings 0.6.1, Pyphen 0.18.1, Pillow 12.3.0, fonttools 4.65.0, brotli 1.2.0, zopfli 0.4.3, flit_core 3.12.0. The transitive woff deps (brotli, zopfli) are pinned explicitly rather than left to the `fonttools[woff]` extra.

### SOFT WARNING: unpinned apt installs

Left unpinned. The six packages are Debian runtime libraries (pango, pangoft2, harfbuzz-subset, libjpeg, ghostscript, DejaVu) and Debian drops old binary versions from the mirror on every point release, so pinning them makes the build fail sooner than it makes it reproducible. The precheck text itself calls apt pinning "often impractical".

### WARNING: description contains only necessary information

Four of the five suggestions taken, one rejected:

| Suggestion | Action |
|---|---|
| HIGH: drop "Both values are currently rejected by the validator." | taken, codebase-inferable |
| HIGH: drop "running elements and notes keep their current behaviour" | taken, no test covers running() or note() |
| MEDIUM: drop the nested-context example list | taken, "any nested formatting context" is the exact class the three tests instantiate |
| MEDIUM: drop "so lines sit beside a narrow float and `clear: left` clears it" | half taken: the illustration went, `clear: left` stayed |
| MEDIUM: drop "so a box can be pulled out of the flow and pinned to the top or the bottom of the page or column that holds it" | REJECTED in part |

The rejected half: the reviewer's claim that "the next paragraph fully specifies the normative behavior" is wrong. Paragraph 2 states the horizontal placement ("laid out at the line-left edge of its reference") and the stacking direction, but nothing in it says a `top` float sits at the top edge and a `bottom` float at the bottom edge. `test_page_float_top_is_placed_at_the_top_of_its_page` and `test_page_float_bottom_is_placed_at_the_bottom_of_its_page` assert exactly that. The out-of-flow half of the clause is genuinely restated in paragraph 2 and was cut; the pinning half stayed.

Body is now 369 words, ASCII, no em dashes, no `##` headers.

### WARNING: derivative (overall verdict, 0.85 / 0.75 against two prior submissions)

See the section below. This is the blocking issue, not the three above.

## Derivative finding (2026-09-12)

The similarity check returned `overall: derivative` against two earlier submissions that implement CSS page floats in this same repository:

| Cited | Authored | Similarity | Confidence | Verdict |
|---|---|---|---|---|
| A | 2026-08-30 | 0.852 | 0.90 | derivative |
| B | 2026-08-02 | 0.750 | 0.88 | derivative |

Neither is ours. Nothing in `approved-problems/`, `problems/` or `rejected/` touches WeasyPrint, floats or page layout.

The shared surface is the whole core of the pick, listed by the checker as purpose-matched: `css/validation/properties.py` accepting `top`/`bottom`, `float_reference` in `INITIAL_VALUES`, the page-float predicate on `Box`, out-of-flow dispatch in `layout/block.py` and `layout/inline.py`, the placement routine in `layout/float.py`, pre-placement before in-flow content in `layout/page.py`, and `stacking.py`. That is the same file list as our `solution.patch` minus `column.py`, `build.py` and `computed_values.py`.

What is ours alone, per the checker's own reading: column floats (`float-reference: column` with real placement, deferral across columns, and the columns-avoid-their-own-float rule) - submission A "explicitly accepts 'column' without placing anything" - plus the anchor-convergence rule and the computed-value degradation inside footnotes. What A and B have that we do not: `float-defer`, `float-offset`, `clear: top/bottom`.

The differentiation levers in CLAUDE.md do not reach this. The overlap is not the API name or the wording, it is the capability, and every one of our extensions is built on top of `float: top/bottom` plus `float-reference`: the column lane cannot be severed from the page lane because the validator change, the box predicate and the out-of-flow dispatch are shared. The checker already read our extensions and called them "incremental slices around the same lesson".

Root cause, and the reusable lesson: issue #259 has been open since 2015 and liZe commented on 2026-06-03 "we would be happy to help if someone wants to implement them!". A long-open issue that a maintainer has just invited work on is a magnet, exactly like the scikit-fem embedded-meshes lane. Our exclusivity gate searched GitHub PRs by feature class in every state and correctly found nothing, because the competition is not on GitHub, it is in the submission pool, which is invisible until precheck. The only defence available at pick time is to treat a freshly-invited, long-open, headline issue as contested by default and to precheck the core slice before authoring (the `feedback_precheck_at_first_slice` rule), not after.

## Platform precheck, round 2 (2026-09-12)

### FAIL: problem and tests are aligned (interface information)

Correct finding. The tests identify page floats with `is_page_floated()` and look for them among the children of the page's root box, and meta.md documented neither. An implementer could reasonably have named the predicate `is_page_float()`, or hung the placed float under the element's in-flow parent, and failed every test while meeting the described behaviour. One paragraph added after the layout paragraph:

> `is_page_floated()` on a box reports whether it is a page or column float. A placed float sits as a direct child of the page's root box, where the page already collects its out-of-flow boxes, rather than under the element it was written in.

Both facts are the ones the tests' `page_floats()` helper depends on and nothing more. Audited the rest of the test file for other undocumented interface: every other thing it touches is base API (`is_floated`, `element_tag`, `descendants`, `position_x/y`, `margin_width/height`, `content_box_x/y`, `boxes.TextBox`, the page's `footnote_area` as `page.children[1]`), all of it used the same way by the repo's own tests. `is_page_floated` and the tree position were the only two gaps.

The tree position is not an invention: base `make_page` already does `root_box.children = out_of_flow_boxes + root_box.children` for absolutely positioned boxes, and the solution extends the same line. Documenting it costs nothing and closes the fairness gap.

Behaviors section came back OK.

### WARNING: problem and tests are good quality (test coupling to internals)

Item 3 flagged `type(child).__name__ == 'TextBox'` and a no-op conditional in the `texts()` helper. Both fixed: `texts()` now uses `isinstance(child, boxes.TextBox)` with `from weasyprint.formatting_structure import boxes` (the dominant idiom in `tests/layout/`; `type(box).__name__` appears once, in `test_footnotes.py`), and the dead `if box.element_tag == 'div' or box.element_tag == 'span': pass` is gone. `element_tag` assertions are kept: the repo's own layout tests use them heavily (43 in `test_page.py`, 14 in `test_block.py`). `is_page_floated` is now documented, which is what made it look like over-specification.

Items 1, 2 and 4 came back OK.

### WARNING: description contains only necessary information (round 2 suggestions)

One of two taken.

| Suggestion | Action |
|---|---|
| MEDIUM: drop "keep their current behaviour," from the positioned-box sentence | taken, now "For boxes that are absolutely positioned or fixed, float computes to none." |
| MEDIUM: drop "with its margins honoured," | REJECTED |

Margins are not default box-model behaviour here. `test_page_float_margins_are_honoured` sets `margin: 5px` and asserts `outer_area == (0, 0, 50, 30)` and `content_box == (5, 5)`. An implementation that pins the border box to the reference edge, which is the obvious way to write it, puts the margin box at (-5, -5) and fails. The clause is the only thing in the description that says the margin box, not the border box, is what sits at the edge.

Body is now 408 words, ASCII, no em dashes, no `##` headers.

### Re-validation after the round-2 edits

test.patch regenerated (test.sh still `new file mode 100755`, ASCII, LF). Clean-room container rebuilt from the submission Dockerfile, `--network none --user 1000:1000`:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 42 of 42 fail, 3 identical runs |
| with solution.patch | 3344 testcases, 0 failures, 2 identical runs | 42 of 42 pass, 3 identical runs |

Mutation sweep not re-run: the test edits were confined to the `texts()` helper and are behaviour-identical (dead branch removed, `type().__name__` swapped for `isinstance`). No assertion changed.


## Platform precheck, round 3 (2026-09-12)

### Derivative: now PASSES (was the round-1 blocker)

The similarity check went from `derivative` to `Pass - the rest of the funnel is unlocked`. Both
cited submissions dropped to a Medium/borderline overlap verdict: 166 of 309 effective lines (53.7%)
and 156 of 309 (50.5%) correspond, but the checker now rules that the column-reference,
column-transfer and left-style exclusion engine is material independent work, and that the two
older tasks are "borderline alternatives for the same page-edge block rather than distinct
part-sources". It also re-confirmed the exclusivity finding: no working public implementation, no
rejection, no removal, maintainers explicitly welcome one.

No artifact change earned this - the same core shipped. The round-1 lesson stands anyway: a
freshly-invited long-open headline issue is contested by default and the submission pool is
invisible until precheck.

### FAIL: Solution Quality (4 high comprehensiveness issues) - ALL CONFIRMED, ALL FIXED

The reference solution really did fail four behaviours meta.md promises. Each was reproduced on the
base+solution tree before fixing, and each now has a dedicated test that kills a revert of the fix.
Crucially, none of the four needed new description text: every one of them brought the SOLUTION into
line with a sentence meta.md already had. The description was right and the solution was incomplete.

1. **Narrow bottom floats reserved a full-width band.** `page_floats_layout` appended top floats to
   `context.excluded_shapes` but not bottom floats, and instead returned a lowered flow bottom that
   `make_page` installed as `context.page_bottom`. Measured on a 200x100 page with a 40x30 bottom
   float: lines that should sit beside it at x=40 were pushed to the next page, and `clear: left`
   could not see the float at all. Contradicted "Content is then laid out around it exactly as
   around a `float: left` box of the same size, and `clear: left` clears it."
   Fix: bottom floats are exclusion shapes like top floats, and the physical page bottom is retained
   for flow. A full-width bottom float still pushes content off the page, now via the exclusion
   geometry rather than a lowered boundary.

2. **Page floats stopped being page floats as flex children.** The patch added
   `child.is_page_floated = lambda: False` next to the repo's existing `is_floated` override in
   `flex_children`, so `is_in_normal_flow()` became True and the box was laid out as an ordinary
   flex item. Grid had the same hole from the other direction: `grid_children` never suppressed
   anything, so the float was simply positioned as a grid item and never collected.
   Fix: dropped the `is_page_floated` override; flex creates an `AbsolutePlaceholder` for page
   floats in its not-a-flex-item branch and keeps them in `copy_with_children`; grid extracts them
   before the placement algorithm and re-attaches the placeholders to the laid-out box.
   Contradicted "That element may sit in any nested formatting context."

3. **Column bottom floats overlapped the footnote area.** Footnote page-bottom reduction is deferred
   while `context.in_column`, and `columns_layout` applies it only at the end, so a column float
   placed against the pre-footnote bottom stayed there. Measured: float at y=80-100 over a footnote
   area starting at y=90. Contradicted "bottom floats stay above the footnote area of their page."

4. **Column-reference floats used the page bottom instead of the column's.** `block.py` set
   `column_floats_bottom = context.page_bottom` and then expanded the column to it. With
   `article { columns: 2; height: 50px }` a 20px bottom float landed at y=80 and stretched the
   column toward the page bottom, instead of sitting at the 50px column's bottom at y=30.

Issues 3 and 4 share one fix: `columns_layout` now publishes
`context.column_floats_bottom = context.page_bottom - bottom_space - context.page_float_reservation`
and `block.py` uses it. `bottom_space` already encodes the declared height (the base computes
`empty_space = page_bottom - content_box_y - height.value`), so a fixed-height multicol gets its own
bottom while balanced columns keep the whole area they can occupy on the page - which is what the
balancing loop needs, and was the original reason for measuring against the page.

`page_float_reservation` is the new monotone footnote fixpoint in `make_page`: each pass places
bottom floats at `page_bottom - reservation`, and if the footnote area ended up taller than the
reservation, the reservation grows to the observed height and the page is laid out again. It only
ever grows and the area is bounded by the page, so it terminates; it also removed the old post-hoc
`translate` of bottom floats, which used to move a float after content had already been laid out
beside it. `context.bottom_floats_placed` makes the page-level loop notice bottom floats placed
deep inside a column, which is what carries the reservation into the column path.

### PASS: Test Quality (all 39 fair), plus 13 new tests

Test Quality passed every test as fair and flagged no timing, ordering, randomization or brittle
message issues. Coverage was 17 of 26 requirements with 9 advisory gaps. Added 13 tests and
parameterized one, taking the file from 42 to 56 cases: the four fixed behaviours above, plus the
advisory gaps worth closing (last-column deferral to the next page, a float taller than a whole
column, a second shrink-to-fit width, asymmetric margins on every side, explicit
`float-reference: inline` inside columns, footnote conversion over both `top` and `bottom`, and the
RTL edge case).

Skipped one advisory suggestion: asserting `float-reference` computes specifically to `inline`.
`inline` and `column` are behaviourally identical by design ("With `inline` or `column`, a page
float uses the current column..."), so only a computed-style assertion could separate them, which
buys coupling to CSS internals rather than behaviour.

### Trap-proof on the four fixes

Each fix reverted individually, expecting exactly its own test to die:

| Reverted fix | Result |
|---|---|
| bottom float not an exclusion shape | 2 failed - lines_beside_a_narrow_bottom_float, clear_left_clears_a_bottom_page_float |
| flex child loses its page float | 1 failed - inside_a_flex_container_anchors_to_the_page |
| grid child not extracted | 1 failed - inside_a_grid_container_anchors_to_the_page |
| column float ignores the footnote reservation | 1 failed - column_bottom_float_sits_above_the_footnote_area |
| column float uses the page bottom | 2 failed - column_bottom_float_sits_above_the_footnote_area, pinned_to_the_bottom_of_a_fixed_height_column |

### WARNING: description (round 3) and the alignment warning

Alignment warning was correct and is fixed: the tests expect column floats under the column box,
not the page root, and meta.md said only "a direct child of the page's root box". Now: "A placed
float sits as a direct child of its reference rather than of the element it was written in: a page
float under the page's root box ... and a column float under its column box."

Also changed "line-left edge" to "left edge". The RTL probe showed the float stays at x=0 while RTL
text flows from the right, which is correct given the "exactly as around a `float: left` box"
framing - `float: left` is physical-left regardless of direction. "line-left" implied otherwise and
was the only wording in the description that the implementation contradicted. A test now pins it.

Of the five description-trim suggestions, took two ("so a float declared inside columns is pinned
to the page instead", redundant with the preceding clause in the same sentence; "leaves the normal
flow and", now implied by the reworked placement paragraph). Rejected three: shrink-to-fit, margins
and `clear: left` each anchor tests that Test Quality has just certified as fair, and the check that
actually rejects submissions is the alignment one. Trading a non-blocking style warning for an
unanchored test is the wrong side of that trade. Body is 415 words, under the 500 cap.

### Code quality

The repo's own linter is clean at base, and the first version of the fixes introduced 2 `I001`
import-sort errors in `weasyprint/layout/block.py` and `page.py` plus 4 in the new test file
(`E501`, three `PT007`). All fixed; `ruff check weasyprint/ tests/layout/test_page_float_729ab9.py`
now passes.

### Re-validation after the round-3 fixes

Local, solution applied: 3384 passed, 0 failures over
`tests/layout tests/css tests/test_boxes.py tests/test_stacking.py tests/test_html.py` with the five
documented deselections. That is 3370 repo cases plus the 14 added ones, and the flex, grid, column
and footnote suites all stayed green through every fix.

New suite 3 times with pytest's random ordering on: 56 passed every run, identical.

Both patches apply and revert cleanly on a fresh checkout at the base commit, and test.sh lands
executable (`new file mode 100755`).

Clean-room container (fresh clone at base plus the current test.patch, image built from the
submission Dockerfile, `--network none --user 1000:1000`, counts read from the JUnit XML):

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 56 of 56 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 56 of 56 pass |

The three extra base testcases with the solution are the repo's own generic property suites
(`test_math_functions_percentage_and_font_unit`, `test_empty_property_value`,
`test_variable_fallback`) picking up `float-reference`; all three pass. LOC hook: human-effective
343 across 13 files (page 107, float 87, column 76, block 17, computed values 10, layout context 10,
grid 9, validation 6, boxes 6, inline 5, properties 2, stacking 1). build.py is back to base now that
the flex override is gone.

The `git apply` mode warnings in the container ("has type 100755, expected 100644") are an artifact
of the Dockerfile's `chmod -R a+rwX /app`, not of the patch; the apply succeeds and the patch itself
carries no mode changes for source files.


## Platform precheck, round 4 (2026-09-12)

Test Quality PASS again (all 52 fair, no timing/ordering/randomness/brittle-message findings).
Solution Quality FAIL with three more high comprehensiveness issues. All three reproduced. Two were
genuine bugs and are fixed in code; the third is a deliberate design limit that the description did
not state, and is now stated.

### 1. FIXED - a deferred column float was placed as a page float

`_defer_column_floats` dropped last-column deferrals into `context.deferred_page_floats`, and
`make_page` treats that whole list as page-referenced: sized against the page, inserted under the
page root. Reproduced: the third 40px float in a two-column 200x60 article came out a direct child
of the next page root.

Fix: `page_floats[page_number]` now carries a third element, the set of keys that left a last
column. `make_page` splits the inherited list on that set and seeds `context.pending_column_floats`
instead of page-placing them; `columns_layout` takes those into `column_floats[0]` of its next
fragment. The float now lands in the first column of the container's next fragment at y=0.

The reviewer's example assumed a next fragment exists. When the container has no content left, no
`columns_layout` runs on the next page and nothing consumes the float, so an explicit fallback puts
it against the page and re-runs the page pass. That terminates because a float changes category at
most once. Both paths now have a test.

### 2. FIXED - flex and grid `order` reversed document-order stacking

Both containers sort children by `style['order']` before the page-float placeholders are built, so
source-order floats A then B with `order: 1` and `order: -1` stacked B first. Since the
`is_in_normal_flow` change makes page floats non-items, `order` must not touch them.

Grid now builds placeholders from `box.children` and sorts only the remaining items. Flex keeps the
sorted list intact, because its indices feed `resume_at` and `skip_stack`, and instead records each
placeholder against its document index and emits them in that order. Measured A at y=0, B at y=20 in
both.

### 3. STATED, NOT CHANGED - page floats under a positioned ancestor

`compute_float` degrades `top`/`bottom` to `left` when any ancestor is out of flow: absolute, fixed,
running, note, footnote, or another page float. meta.md documented only the footnote arm, and
promised the float works in "any nested formatting context", which an absolutely positioned box
satisfies. The reviewer is right that those two statements contradict.

Took the second route the review offers ("explicitly document and implement an allowed exclusion")
rather than collecting through absolute layout. The reason is not cost: an out-of-flow ancestor has
no page or column reference to anchor to, which is the same reason the footnote arm exists, so the
honest description is one rule instead of two special cases. Collecting through the positioned path
would also mean extracting page floats from a subtree that has not been laid out when
`_collect_page_floats` runs, since absolutes are laid out after the page pass.

meta.md now reads "Inside an out-of-flow box, a footnote, a positioned box, a running element or
another page float, `top` and `bottom` compute to `left`", and the nested-context promise is scoped
to "any nested formatting context in the normal flow". A test pins the positioned case: computed
float is `left`, the box is not a page float, and it stays inside the positioned box.

### Tests: 56 -> 61

Added the next-fragment deferral, the page fallback (the existing last-column test was tightened
onto it, since its container ends on the page), flex document order, grid document order, the
positioned-ancestor exclusion, and explicit `float-reference: column` inside columns (the round-4
untested coverage gap). Two advisory "not discriminating" gaps closed by strengthening existing
assertions: the positioned box's computed float is now asserted `none` rather than merely
not-page-floated, and the footnote conversion is asserted to be `left` rather than merely
not-page-floated.

Trap-proof on the three new fixes, each reverted alone:

| Reverted fix | Result |
|---|---|
| deferred column float goes to the page | 1 failed - leaving_the_last_column_goes_to_the_next_fragment |
| flex page floats follow CSS order | 1 failed - page_floats_in_a_flex_container_stack_in_document_order |
| grid page floats follow CSS order | 1 failed - page_floats_in_a_grid_container_stack_in_document_order |

### Description suggestions (round 4)

Took two of three: dropped "where the page already collects its out-of-flow boxes" (a codebase
aside that anchors no test) and the illustrative half of the anchor-convergence sentence (the rule
in the first clause still anchors the three tests). Rejected the `clear: left` cut for the third
time: `test_clear_left_clears_a_top_page_float` and `test_clear_left_clears_a_bottom_page_float`
trace to that clause and Test Quality cites it as their anchor.

### Re-validation after the round-4 fixes

Local, solution applied: 3389 passed, 0 failures (3384 repo+earlier cases plus the 5 net new ones).
New suite 3 times with random ordering: 61 passed, identical every run. Both patches apply and
revert cleanly at the base commit; test.sh still `new file mode 100755`. ruff clean on the source
and the test file.

Clean-room container, image rebuilt from the submission Dockerfile, `--network none --user
1000:1000`, counts read from the JUnit XML:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 61 of 61 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 61 of 61 pass |

LOC hook: human-effective 373 across 13 files, raw added 444.


## Platform precheck, round 5 (2026-09-12)

Two FAILs. One of them I caused in round 4.

### Test Quality FAIL - self-inflicted by the round-4 wording

`test_a_page_float_inside_a_normal_float_anchors_to_the_page` was called unfair, and the reviewer is
right. Round 4 generalized the footnote rule to "Inside an out-of-flow box, a footnote, a positioned
box, a running element or another page float ... compute to `left`". An ordinary `float: left` IS
out of normal flow, both in standard terminology and in this repo's `is_in_normal_flow()`, so that
sentence promised a page float inside an ordinary float degrades to `left`. The test (green since
round 0) asserts the opposite, and so does the code: the ancestor walk checks
`parent_style['float'] in ('footnote', 'top', 'bottom')`, never `left`/`right`.

So the umbrella phrase "out-of-flow box" was simply wrong about the implementation. Fixed by
deleting it and keeping the exact enumeration the code implements: "Inside a footnote, a positioned
box, a running element or another page float". The nested-context sentence lost its universal too
("in the normal flow" was also wrong, for the same reason an ordinary float is not in normal flow)
and now enumerates what actually carries the float through: an ordinary float, a table cell, a flex
or grid container, or a block with its own formatting context.

Lesson, and the reason this cost a round: when a description sentence is widened to cover a review
finding, widen it to the code's actual predicate, not to a category term that sounds equivalent.
"Out-of-flow" and "the four ancestor kinds the walk tests" are not the same set, and the gap was
exactly one already-passing test.

### Solution Quality FAIL - a deferred column float could be adopted by an unrelated container

Correct and reproduced. `pending_column_floats` was a flat list, so the first multi-column container
laid out on the next page consumed it whoever it belonged to. Measured with container A carrying
`break-after: page` and an unrelated container B starting the next page: A's float 3 was placed
inside B's first column.

Fix: every deferred entry now carries its originating container. `columns_layout` publishes
`context.column_container_key = (box.element, box.element_tag)` (saved and restored, so nested
multicol works), `_defer_column_floats` records `column_deferred_keys[float_key] = container_key`,
that dict rides in the per-page `page_floats` tuple, and `make_page` rebuilds
`pending_column_floats` as `(container_key, box)` pairs. `columns_layout` takes only the entries
matching its own key and leaves the rest pending, so a float whose container does not continue falls
through to the page fallback. Verified: B's columns are now empty and A's floats land on the page
root, while the same-container continuation case still puts the float in the next fragment's first
column.

One measurement worth recording: a partial mutation (consume every pending float but leave the list
intact) does NOT change the output, because the page fallback loop re-runs and re-routes them. Only
the faithful pre-fix mutation (consume all AND clear) reproduces the bug, and that one is killed by
`test_a_column_float_is_not_adopted_by_another_multicolumn_container`. The fallback loop is
self-healing against the weaker error, which is why the first mutation attempt looked like a test
gap and was not one.

### Tests: 61 -> 70

Every requirement the round-5 report listed as untested or single-point now has one:
the cross-container adoption regression, `top`/`bottom` inside a running element, `top`/`bottom`
inside another page float, the computed initial value of `float-reference` (asserted literally
`inline`, which no behavioural test can distinguish from `column`), and the absolute/fixed and
positioned-containment tests parameterized over both `top` and `bottom`.

### Description suggestions (round 5)

Both declined this round, and they are marked "take or leave". Dropping "and `clear: left` clears
it" would unanchor two tests; dropping the page-root/column-box mapping would unanchor the
structural assertions in three more, and that exact mapping was what the round-2 alignment FAIL
demanded be spelled out. Trading a style note for an alignment or fairness regression is the wrong
direction, and rounds 2 and 5 both cost a cycle to exactly that kind of wording change.

### Re-validation after the round-5 fixes

Local, solution applied: 3398 passed, 0 failures. New suite 3 times with random ordering: 70 passed,
identical. 70 of 70 fail on base. Patches apply and revert cleanly at the base commit; test.sh still
`new file mode 100755`; ruff clean on source and tests.

Clean-room container, image rebuilt from the submission Dockerfile, `--network none --user
1000:1000`:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 70 of 70 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 70 of 70 pass |

LOC hook: human-effective 384 across 13 files, raw added 455. meta.md 443 body words, ASCII.


## Platform precheck, round 6 (2026-09-12)

**Test Quality: PASS** - all 61 test functions fair, 34 of 35 requirements covered, no brittle
messages, timing, randomness, ordering or environment findings. The round-5 wording fix held: the
ordinary-float test is now listed as covering "That element may sit inside an ordinary float".

**Solution Quality: FAIL** - one issue, counted against both Comprehensiveness and Code Quality
(the latter dropped 3/3 -> 1/3). It is a real bug I introduced in round 5, and it hangs.

### Nested multi-column containers sent an outer column float into an infinite loop

`context.column_floats` and `context.seen_column_floats` are single mutable slots on
`LayoutContext`, and `columns_layout` resets both in its balancing and final-render passes. Round 5
added save/restore for `column_floats_bottom` and `column_container_key` but not for those two, nor
for `column_index` / `deferred_column_floats`. So an inner `columns_layout`, running inside the
outer container's `block_box_layout`, wiped the outer pass's dedup set, the outer float was
rediscovered on every turn of `_column_layout`'s `while True`, and the render never terminated.

Reproduced directly: an outer `columns: 2` holding a `float: top` sibling and an inner `columns: 2`
never finished rendering (killed at 45s).

Fix: `columns_layout` now saves and restores the whole per-container tuple -
`column_floats`, `seen_column_floats`, `column_index`, `deferred_column_floats`,
`column_floats_bottom`, `column_container_key` - at entry and at both return points, which is the
save/restore route the review offers. Also dropped `_column_layout`'s local `column_floats` alias
(the review flagged it explicitly) so it reads `context.column_floats` directly and cannot hold a
stale dict across a nested call. With the fix the document renders in one page and both outer floats
sit in the outer container's first column at y=0 and y=20, with the inner container laying out
normally in the second column.

Regression test added as the review asked, with a float before AND after the nested container:
`test_a_column_float_beside_a_nested_multicolumn_container_uses_the_outer_column`. Reverting the
restore reproduces the hang and that test is the one that dies.

### Hang guard: `pytest-timeout`

This bug revealed a harness hole worth closing independently of the bug. A solver implementing the
same fixpoint loop over global state hits the same non-termination, and a HANG is strictly worse for
everyone than a failure: `test.sh`'s empty-XML fallback never runs, so the platform gets no JUnit
output at all and the whole run (24-32 tokens) is wasted on an ambiguous result rather than a clean
fail.

Added `pytest-timeout==2.4.0` to the Dockerfile and `--timeout=60` to both pytest invocations in
`test.sh`. This is not a timing-dependent assertion: the slowest single test in the suite measures
0.28s, so 60s is over 200x headroom and cannot trip on a slow grader. It only converts a
non-terminating solution into a reported failure. Done now rather than later because the Dockerfile
is solver-visible and is not re-eval eligible once a batch has run.

### Description suggestions (round 6)

Both declined again, same reasoning as round 5 and both marked "take or leave". `clear: left` anchors
two tests; the anchor-follows-its-element clause anchors three. The reviewer calls the second half
"implied by the first half and existing movement rules", but the movement rules describe a float that
does not FIT, while this clause covers a float that fits and still moves because its anchor moved -
a different mechanism, and the one `test_a_page_float_follows_its_anchor_to_the_next_page` pins.

### Re-validation after the round-6 fixes

Local, solution applied: 3398 passed, 0 failures. New suite 3 times with random ordering: 71 passed,
identical. 71 of 71 fail on base. Patches apply and revert cleanly; test.sh still
`new file mode 100755`; ruff clean on source and tests.

Clean-room container, rebuilt from the updated Dockerfile, `--network none --user 1000:1000`:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 71 of 71 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 71 of 71 pass |

LOC hook: human-effective 387 across 13 files.

## Platform precheck, round 7 (2026-09-13)

Test Quality was not re-reported (passed in round 6). Solution Quality FAIL, Comprehensiveness 1/3,
Code Quality back up to 2/3. Two issues, both reproduced, both fixed.

### 1. A forced break inside a page float dropped content

`page_float_layout` did `box, _, _, _, _, _ = block_container_layout(...)`, throwing away
`resume_at`. `bottom_space=-inf` already stops height-based fragmentation, but a
`break-before: page` inside the float still stops the container and returns a continuation.
Reproduced: a float holding `<p>one</p><p style="break-before: page">two</p>` came out as one 10px
float with only "one"; "two" was missing from the whole document. Content loss, the worst failure in
this problem so far.

Fix: forced breaks do not apply inside a page float, since it "is never split". `force_page_break`
is the single chokepoint every forced sibling break goes through, so it now returns False while
`context.in_page_float`, which `page_float_layout` sets and restores around the layout call. The
float is now 20px and holds both paragraphs.

### 2. Flex and grid page floats were anchored to the wrong fragment

Both built placeholders for every direct page-float child and appended them to every fragment,
before and regardless of where the fragment ends. The block path never had this problem because
`_out_of_flow_layout` only creates a placeholder when layout actually reaches the child.

Reproduced on a 50px page with 20px items and a trailing `float: top` child. Grid with 4 items: F
on page 1 while its source position (after item 3) is on page 2. Flex with 6 items: F stranded on a
page between the two flex fragments, pushing items 3-5 to page 3.

Fixes, each mirroring the block path's "only when reached" behaviour:

- Flex records each placeholder's index in the same `skip + position` space `resume_at` uses, and
  emits it after the line loop (once `resume_at` is final, including the overflow reset) only when
  that index is before the resume index. The rest are picked up by the next fragment's slice of
  `box.children`.
- Grid lays out by rows, so there is no child index to compare against. Each page float instead
  records the in-flow item it follows in source order, and is emitted in the fragment whose
  `this_page_children` contains that item, or in the first fragment when nothing precedes it.

After the fix: grid 4 items puts F on page 2 with item 3; flex 6 items puts items 3-5 on page 2 and
F on page 3, where it goes because it doesn't fit after them (ordinary deferral).

### Tests: 71 -> 74, and a non-discriminating first draft

Added the three regressions the review asked for. The first flex test used 4 items and did NOT kill
the flex mutation (emit every placeholder), and I nearly didn't catch it. With 4 items the page
maker's anchor convergence self-corrects: the wrongly emitted float is placed, the fragment shrinks,
the placeholder goes stale, and the float gets deferred to the right page anyway. Only at 6 items
does the wrong output survive. The test now uses 6 items and kills the mutation.

Same lesson as round 5's self-healing mutation: the page maker's convergence loops hide some
anchoring bugs. A fixture that "should" show a bug has to be checked against the mutation, not
assumed.

| Reverted fix | Result |
|---|---|
| forced breaks split a page float | 1 failed - forced_break_inside_a_page_float_keeps_all_its_content |
| flex emits every page float in every fragment | 1 failed - after_a_fragmented_flex_container_follows_its_fragment |
| grid emits every page float in every fragment | 1 failed - after_a_fragmented_grid_container_follows_its_fragment |

### Description suggestions (round 7)

Five, all declined. Four were declined in earlier rounds for the same reasons (`clear: left`, the
page-root/column-box mapping, the anchor-follows clause, "With `page` it always uses the page"),
and each anchors tests Test Quality has passed as fair. The new HIGH one wants to drop "For boxes
that are absolutely positioned or fixed, float computes to none" as standard CSS. It is standard
and it is base behaviour, which makes it this description's one codebase-inferable requirement. It
stays because `test_a_positioned_box_is_not_a_page_float` asserts it for `top` and `bottom`, and an
implementer could reasonably let a positioned page float escape to the page without that sentence.

### Re-validation after the round-7 fixes

Local, solution applied: 3401 passed, 0 failures. New suite 3 times with random ordering: 74 passed,
identical. 74 of 74 fail on base. Patches apply cleanly at the base commit; test.sh still
`new file mode 100755`; ruff clean on source and tests.

Clean-room container, rebuilt from the submission Dockerfile, `--network none --user 1000:1000`
(the base-with-solution cell was killed once by host memory pressure from other projects' containers
and re-run on its own):

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341 testcases, 0 failures | 74 of 74 fail |
| with solution.patch applied in the container | 3344 testcases, 0 failures | 74 of 74 pass |

LOC hook: human-effective 406 across 13 files.

## Platform precheck, round 8 (2026-09-13)

### Verify Tests / Verify Solution FAIL - self-inflicted harness break

Both verify steps died before running a single test:

    __main__.py: error: unrecognized arguments: --timeout=60

Round 6 added `--timeout=60` to both pytest calls in `test.sh` and `pytest-timeout==2.4.0` to the
Dockerfile. My clean-room containers were built from that updated Dockerfile, so they passed. The
platform's verify environment did not have the plugin, which means it is not building from the
Dockerfile I validated. Either the updated Dockerfile never reached the platform or it used a cached
image. Pytest rejects an unknown option outright, so a guard meant to turn a hang into a clean
failure instead turned every run into a collection error.

Fix: `test.sh` now adds `--timeout=60` only when `import pytest_timeout` succeeds. With the plugin
the hang guard applies; without it `test.sh` behaves exactly as before round 6. The Dockerfile keeps
the pin so the guard is live wherever it is actually used.

Lesson: a harness option that depends on an environment change must degrade when that change is
absent. `test.sh` and the Dockerfile are uploaded and cached separately, so validating them only as
a matched pair misses exactly this failure. Both container variants now get checked: the submission
Dockerfile, and the same Dockerfile with the `pytest-timeout` line removed.

### Test Quality: PASS (all 65 fair) - and an unreported bug it led to

17/22 covered. The four advisory gaps were all `float: bottom` variants of cases only tested with
`top`: shrink-to-fit, a float taller than its reference, deferral, and a nested context. I probed
all four against the solution rather than just writing tests, because every earlier gap turned out
to hide a bug that Solution Quality found a round later.

Three behaved correctly. One did not: a bottom float taller than its reference was pinned by its
bottom edge, so its top sat above the reference at y=-20 on a 100px page and y=-30 in a 40px
column, cut off and never rendered. An oversized top float starts at the reference top, as the
existing test already expects. The fix clamps a bottom float's position to the top of the
reference, so an oversized one starts at the top edge like a top float. A float that fits is
unaffected, since `bottom - height >= top` already holds for it.

The description said an oversized float "is placed in it anyway" but not where, so a solver could
fairly have pinned it by the bottom edge. It now reads "is placed in it anyway, starting at its top
edge, rather than moved forward forever", covering both sides.

Added 6 tests: bottom shrink-to-fit, oversized bottom page float, oversized bottom column float,
bottom page deferral, bottom column deferral, bottom float in a table cell. Reverting the clamp
kills exactly the two oversized-bottom tests; the other four pin behaviour that was already right.

### Description suggestions (round 8)

Four, all declined. The HIGH one would cut the list of nested contexts. That list replaced "any
nested formatting context" in round 5, after the universal wording contradicted the positioned-box
exception (round 4) and "in the normal flow" wrongly swept in ordinary floats (round 5). Without the
list, "that context" has no antecedent and the exception paragraph contradicts the rule again. The
page-root/column-box mapping and the anchor-follows clause stay for the reasons given in rounds 5-7.
"when there is one" is what makes "and the page otherwise" read as a fallback; cutting it saves
three words and blurs the rule.

### Re-validation after the round-8 fixes

Local, solution applied: 3407 passed, 0 failures. New suite 3 times in random order: 80 passed,
identical. 80 of 80 fail on base. Patches apply cleanly at the base commit; test.sh still
`new file mode 100755`; ruff clean on source and tests.

Clean-room containers, `--network none --user 1000:1000`, from a fresh checkout plus the current
test.patch. Both variants were run, since the platform's verify environment lacked the plugin:

| Image | base, no solution | base, solution | new, no solution | new, solution |
|---|---|---|---|---|
| submission Dockerfile (with pytest-timeout) | 3341, 0 failures | 3344, 0 failures | 80 of 80 fail | 80 of 80 pass |
| same Dockerfile without pytest-timeout | 3341, 0 failures | 3344, 0 failures | 80 of 80 fail | 80 of 80 pass |

No `unrecognized arguments` in any run's output. LOC hook: human-effective 407 across 13 files.

## Platform precheck, round 9 (2026-09-13)

### Verify FAIL - three test cases exist only with the solution applied

    tests.css.test_math.test_math_functions_percentage_and_font_unit[float-reference] (passed)
    tests.css.test_validation.test_empty_property_value[float-reference] (passed)
    tests.css.test_variables.test_variable_fallback[float-reference] (passed)

These three repository tests are parametrized over every known CSS property. `float-reference` is
a new property, so the solution creates a new case in each. The base run on the clean repo cannot
contain them, so they are neither pass-to-pass nor fail-to-pass. This was sitting in plain sight
since round 0 as the 3341 vs 3344 base-mode count, which I had written up as harmless.

Fix: `test.sh` deselects the three generated IDs in its shared deselect list. On the clean repo the
IDs do not exist and pytest ignores them; with the solution they no longer run. They are not about
page floats at all (property-registry smoke checks), and including them in the new set would add a
hidden requirement on how `float-reference` behaves inside `calc()`, empty values and `var()`
fallbacks, which the description never states. Also added `set -f` so the bracketed IDs can never
be glob-expanded by the unquoted `$DESELECT` expansion.

Verified locally by diffing JUnit test IDs from `test.sh base` with and without the solution: both
3341 cases, identical ID sets, no `float-reference` case in either. (A first attempt produced only
the fallback XML: this host has no `python`, so `test.sh` picked the system `python3` without
pytest. Re-run with the venv first on PATH. The container is unaffected.)

### Test Quality: PASS (72/72) - and another unreported bug behind its coverage hints

Probed the three advisory gaps against the solution. A bottom float leaving the last column lands at
the bottom of the next fragment's first column (correct). A float physically inside an inner
multicol nested in an outer one is owned by the inner column (correct), but its containers came out
15px tall around a 20px float, and the paragraph after them started at y=15, overlapping the float.
With `float: left` in the same document the containers are 20px and nothing overlaps.

Isolated by varying one thing at a time: only an outer multicol that balances (auto height) and has
little content triggers it. Fixed outer height, plain outer div, single level, more inner content
and `column-fill: auto` were all correct.

Cause: balancing measures `consumed_height` from the last in-flow child only, so an out-of-flow
column float never counts; an ordinary float instead breaks the column, which is what makes the
outer balancer grow. The final `min(max_height, max_column_height)` then clamps the inner container
to the outer's trial height, hiding the float from the outer balancer.

Tried two fixes in separate source copies against the six probe cases and the column/float/flex/
grid/footnote/page-float suites, with an unmodified copy as a control (422 passed):

- counting top column floats in `consumed_height`: did not fix the case and broke 3 tests.
- not clamping the container below the tallest column float: fixed it, but broke 2 tests, because a
  page-reference float inside a column is still an unplaced placeholder at that point and has no
  height. Narrowed to column-reference floats only: all probes correct, 422 passed.

Kept the narrowed second fix. Regression test
`test_a_column_float_inside_a_nested_multicolumn_container_uses_the_inner_column` pins both the
inner-column ownership (the advisory gap) and that following content starts below the float.

### Description suggestions (round 9)

Five, all declined. The second HIGH one asks to delete the standalone sentence "A page float is
never fragmented." That sentence is not in meta.md (the only "fragment" matches are "next fragment"
in the deferral rule), so there is nothing to remove. The other four repeat earlier rounds'
suggestions and are declined for the reasons given there: each anchors tests Test Quality has passed
as fair, and the nested-context list is what replaced the contradictory universal wording.

### Re-validation after the round-9 fixes

Local, solution applied: 3405 passed, 0 failures. New suite 3 times in random order: 81 passed,
identical. 81 of 81 fail on base. Patches apply cleanly at the base commit; test.sh still
`new file mode 100755`; ruff clean on source and tests.

Clean-room containers, `--network none --user 1000:1000`, fresh checkout plus the current test.patch,
JUnit XML saved from every run so the base-mode test IDs could be diffed the way the platform's
wrapper classifies them:

| Image | base, no solution | base, solution | new, no solution | new, solution |
|---|---|---|---|---|
| submission Dockerfile (with pytest-timeout) | 3341, 0 failures | 3341, 0 failures | 81 of 81 fail | 81 of 81 pass |
| same Dockerfile without pytest-timeout | 3341, 0 failures | 3341, 0 failures | 81 of 81 fail | 81 of 81 pass |

Base-mode test IDs with and without the solution: identical sets on both images (0 IDs only with
the solution, 0 only without). No `float-reference` case and no `unrecognized arguments` in any run.
LOC hook: human-effective 415 across 13 files.

## Platform precheck, round 10 (2026-09-13)

Solution Quality FAIL, Comprehensiveness 1/3, Code Quality 3/3. One issue.

### A named-page change inside a page float dropped content

Reproduced: a `float: top` or `float: bottom` holding `<p>A</p><p style="page: named">B</p>` came
out 10px tall with only "A"; "B" was gone from the document. Same mechanism as round 7: the break
stops `block_container_layout`, which returns a continuation that `page_float_layout` discards.

This is squarely my miss. Round 7 fixed the forced-break case by making `force_page_break` return
False inside a page float, but the only place that consults it is

    if page_name or force_page_break(page_break, context):

and the `page_name` half of that same condition was left live. I fixed the function the review named
instead of the condition that actually decides the stop.

Fix: `page_name` is `None` while `context.in_page_float`, so neither half of that condition can stop
a page float. Both floats now hold A and B at 20px.

### Closing the class instead of the instance

To make sure there is no third sibling, I inventoried every place layout stops between siblings:

- `block.py:753-757` - forced break or named page. The only non-overflow stop; both halves now
  suppressed inside a page float.
- `block.py:284` (a float that does not fit) and `block.py:641` (nothing fits in the remaining
  space) - overflow-driven. A page float is laid out with `bottom_space=-inf`, so they cannot fire.
- `find_earlier_page_break` - only reached from those overflow paths.
- `table.py:101-103` and `:395-396` - row-group forced breaks, through `force_page_break`, already
  suppressed.

Probed the nested forms against the fix for both sides: a named-page change inside a table cell,
inside a flex item and inside a nested div, a forced break between table rows, and
`break-before: column` inside a column float. All kept the whole float.

### Re-validation after the round-10 fix

Local, solution applied: 3407 passed, 0 failures (3405 plus the two new parametrized cases). New
suite 3 times in random order: 83 passed, identical. 83 of 83 fail on base. Reverting only the
named-page suppression fails exactly `test_a_named_page_change_inside_a_page_float_keeps_all_its_content`
`[top]` and `[bottom]`. Patches regenerated and verified to contain the fix and the test; test.sh
still `new file mode 100755`; ruff clean. LOC hook: human-effective 418 across 13 files.

Container validation is BLOCKED by host Docker, not by the submission. Both builds failed on the
base image with `failed to create snapshot: missing parent "moby/580/sha256:0da811fd..." bucket:
not found`; re-pulling the base image fails with `target snapshot ... already exists`. In the same
window `/var/lib/docker` dropped from 8.6G to 897M and the other projects' running containers
disappeared, so the store was emptied from outside this session while its metadata still points at
the removed snapshots. Repair (force-removing the base image record and re-pulling, or pruning /
restarting the daemon) touches a store shared with other projects, so it was left for the user.

This round's change does not touch `test.sh` or the Dockerfile: three lines in `block.py` and one
test. Round 9's container runs already cover the harness on both Dockerfile variants, including the
base-mode test-ID diff, so the container cells are expected to match those plus two new passing
cases. That is an expectation, not a measurement, until Docker is repaired and they are re-run.

## Platform precheck, round 11 (2026-09-14)

Solution Quality FAIL, Comprehensiveness 1/3, Code Quality 3/3. One issue, plus a bug found behind
one of the advisory coverage gaps.

### "a positioned box" was wider than the code - wording fixed, not the code

The exception sentence read "Inside a footnote, a positioned box, a running element or another page
float, `top` and `bottom` compute to `left`". In CSS a positioned box is any non-static position,
so `relative` and `sticky` are included. The code's ancestor check only looks for `absolute` and
`fixed`. Reproduced: under a `relative` or `sticky` ancestor the float stays a page float at the page
root; under `absolute` it becomes an ordinary `left` float inside the ancestor.

This is the exact lesson recorded in round 5 ("widen a description sentence to the code's actual
predicate, not to a category term that sounds equivalent"), and I repeated it in the same paragraph.

Chose the wording over the code. The sentence's own rationale, "such a box is laid out in its own
area rather than in a page or column reference", is true of absolutely positioned and fixed boxes,
which are out of flow, and false of relative and sticky boxes, which stay in the flow of the page.
The repository draws the same line: `Box.is_absolutely_positioned()` covers absolute and fixed and
`relative` is handled separately. Degrading page floats under `relative` would also stop them
working inside ordinary positioned wrappers, which most real layouts have. The sentence now reads
"an absolutely positioned or fixed box", which is the check the code makes.
`test_a_page_float_inside_a_relatively_positioned_box_stays_a_page_float` (top and bottom) pins it.

### Advisory gaps probed - three correct, one hiding a real bug

Probed all four against the solution before writing tests, as in rounds 8-10:

- auto-width column floats shrink to fit (40px for "abcd", both sides) - correct
- asymmetric margins on column floats (outer (0,0,52,34), content inset (5,3); bottom at y=66) -
  correct
- `clear: left` against a column float (below a top float; into the next column past a bottom one) -
  correct
- a multicol container with its own bottom page-referenced float - BUG

With 6 short lines and a full-width bottom page float at the end of the article, the article sat on
page 1 at 30px while the float went to page 2 alone. With 20 lines the columns filled the full page
height and never left room above the float.

Cause: `columns_layout`'s "columns don't overlap the page floats of their own reference" block
predates round 3, when only top floats were in `excluded_shapes`. Round 3 made bottom floats
exclusion shapes too, so the block started pushing the container below them, off the page, which
made the anchor stale and sent the float to the next page. It also never capped the columns above a
bottom float, and it runs after `original_bottom_space` (the height balancing may use) is captured.

Fix: only top page floats push the container down; bottom page floats cap both `bottom_space` and
`original_bottom_space` at their top edge. After the fix: 6 lines keep the float on page 1 at y=70
under a 30px article; 20 lines with the float first cap page 1's columns at 70px and continue on
page 2. Two regression tests pin both.

One case still ends with the float alone on the next page: 20 lines that fill page 1 exactly with
the float's anchor at the very end. Placing the float pushes its own anchor to page 2, and without
the float the anchor fits on page 1 again, so there is no placement that satisfies both. The plain
block path (10 lines filling a page, bottom float at the end) behaves identically, so this is the
described deferral ("moves on ... to the next page"), not something the column change introduced.

Tests added: the relative-ancestor test (2 cases), column shrink-to-fit (2), column margins (2),
`clear: left` against top and bottom column floats (2), and the two multicol bottom-float tests.

### Description suggestions (round 11)

Five, all declined for the reasons given in earlier rounds: each targets a clause that anchors tests
Test Quality has passed as fair (the page-root/column-box mapping, margins, `clear: left`, the
absolute/fixed rule), and "rather than moved forward forever" is what distinguishes placing an
oversized float from deferring it.

### Re-validation after the round-11 fixes (also closes round 10's blocked container runs)

Local, solution applied: 3417 passed, 0 failures. New suite 3 times in random order: 93 passed,
identical. 93 of 93 fail on base. Reverting only the bottom-page-float column fix fails exactly the
two new multicol tests. Patches regenerated and verified to contain the column fix, the
relative-ancestor test and both multicol tests; test.sh still `new file mode 100755`; ruff clean;
meta.md ASCII, 451 words. LOC hook: human-effective 426 across 13 files.

Docker was healthy again this round, so the container runs owed since round 10 were done here.
Clean-room containers from a fresh checkout plus the current test.patch, `--network none --user
1000:1000`, JUnit XML saved from every run:

| Image | base, no solution | base, solution | new, no solution | new, solution |
|---|---|---|---|---|
| submission Dockerfile (with pytest-timeout) | 3341, 0 failures | 3341, 0 failures | 93 of 93 fail | 93 of 93 pass |
| same Dockerfile without pytest-timeout | 3341, 0 failures | 3341, 0 failures | 93 of 93 fail | 93 of 93 pass |

Base-mode test IDs with and without the solution: identical on both images (0 only with, 0 only
without). No `float-reference` case and no `unrecognized arguments` in any run.

## Test Quality coverage, round 12 (2026-09-14)

Two requirements came back "partial" with advisory suggestions. Both are test-only: the solution
already implements them, and I re-probed each against the current code before writing tests.

- Fixed ancestors. `compute_float` checks `position in ('absolute', 'fixed')` for ancestors, but
  the suite only exercised `absolute`. Probe: under a `position: fixed` ancestor, `top` and `bottom`
  compute to `left`, are not page floats, sit inside the ancestor at (20, 40), and nothing is
  adopted by the page root, identical to the absolute case. The existing
  `test_a_page_float_inside_a_positioned_box_is_an_ordinary_float` is now parametrized over
  `absolute` and `fixed` as well as the side.

- Column references through nested contexts. The description says the float "still references the
  page or the column rather than that context", and the suite only tested the page branch. I had
  probed the column branch in round 10 (all correct) without adding tests, so this was a coverage
  debt, not unverified behaviour. Re-probed: a float inside a table cell, an ordinary float, a flex
  container, a grid container or an `overflow: hidden` block within a multicol is a direct child of
  the first column at (0, 0, 30, 20) for `top` and (0, 80, 30, 20) for `bottom`, with nothing at the
  page root, in another column, or left inside the context. New parametrized test
  `test_a_column_float_inside_a_nested_context_is_placed_in_the_column` covers all 10 cases. It does
  not assume two column boxes, because the short top-float-in-an-ordinary-float case only produces
  one.

Trap-proof for the new coverage:

| Mutation | Result |
|---|---|
| only `absolute` ancestors degrade `top`/`bottom` | 2 failed - `..._is_an_ordinary_float[top-fixed]` and `[bottom-fixed]` |
| the column path does not look inside nested formatting contexts | 6 failed - table-cell, float and bfc, both sides |

The flex and grid cases survive that second mutation: those containers emit their page-float
placeholders on their own box rather than through the block recursion the mutation narrows, so this
mutation does not discriminate their column branch. They do pin the geometry, and the flex/grid
placeholder path is separately trap-proven by the round-4 and round-7 document-order and fragment
tests.

Two harness details fixed while adding these. My first edit wrote a literal two-character `\n`
line into the test file (a quoted heredoc passed `'\\n'` through), which broke collection; removed,
three over-long parametrize lines wrapped, ruff clean. And the nested-context cases got explicit
`ids` (`table-cell`, `float`, `flex`, `grid`, `bfc`): pytest had built the IDs from the raw CSS and
HTML (quotes, angle brackets, braces, spaces), which is exactly the kind of test ID the platform's
regression/new-set matching choked on in round 9. No collected ID contains those characters now.

### Re-validation (round 12)

Local, solution applied: 3429 passed, 0 failures (3417 plus the 12 new cases). New suite 3 times in
random order: 105 passed, identical. 105 of 105 fail on base. `solution.patch` regenerated and
unchanged from round 11 (43396 characters); only `test.patch` changed. ruff clean; test.sh still
`new file mode 100755`. LOC hook: human-effective 426.

Container: new mode on the round-11 image (submission Dockerfile, with pytest-timeout) with the
updated test file mounted, `--network none --user 1000:1000`: 105 of 105 fail without the solution,
105 of 105 pass with it. Base mode and the no-pytest-timeout variant were not re-run: `test.sh`, the
Dockerfile and `solution.patch` are identical to round 11, where both images passed base mode with
identical test-ID sets, and base mode ignores the new test file.

## Platform precheck, round 13 (2026-09-14)

Solution Quality FAIL, Comprehensiveness 1/3, Code Quality 2/3. One issue, correct and reproduced.

### A nested later float was stacked before a direct earlier float in flex and grid

`<div class="flex"><div class="pf">1</div><div><div class="pf">2</div></div></div>` stacked 2
above 1 for `float: top`, and put 2 lower than 1 for `float: bottom`. Same in grid, and the probe
showed the column reference path reverses it too. "Nested then direct" and "nested in two items"
were already right, so it is specifically an earlier direct float competing with a later nested one.

Cause, and it is mine: round 4 kept direct page-float children in document order among themselves,
and rounds 4 and 7 emit their placeholders after the laid-out items (needed so fragmentation can
decide which fragment owns them). Collection walks the tree depth first, so a placeholder nested in a
later item is reached before the direct placeholder appended at the end. Both local fixes were
correct for what they covered and still left the traversal order as the de facto stacking order.

Fix, following the review's "one source-order ordering for every placeholder": `layout_document`
builds `context.element_order` from `root_box.element.iter()` (the ElementTree walk is document
order), and a single helper, `page_floats_in_document_order`, sorts collected floats by it in both
collection paths, `_collect_page_floats` for the page and `_column_layout` for columns. The sort is
stable, so floats that share an element keep their traversal order. All 14 probe shapes now come out
in document order.

Tests: the direct-then-nested and nested-then-direct shapes for flex and grid, top and bottom
(8 cases), plus the column-reference variant for flex and grid, top and bottom (4 cases). The 4
direct-then-nested page cases failed before the fix and pass after.

Trap-proof: making `page_floats_in_document_order` return the floats unsorted fails exactly the 8
direct-then-nested cases (4 page, 4 column) and nothing else.

### Re-validation (round 13)

Local, solution applied: 3441 passed, 0 failures (3429 plus the 12 new cases). Repo layout suites
(column, float, flex, grid, page, footnotes, block): 525 passed. New suite 3 times in random order:
117 passed, identical. 117 of 117 fail on base. Patches regenerated and verified to contain the sort
helper, the `element_order` index and both order tests; test.sh still `new file mode 100755`; ruff
clean. LOC hook: human-effective 439 across 13 files.

Container: the round-11 image (submission Dockerfile) with the regenerated `solution.patch` and the
updated test file mounted, `--network none --user 1000:1000`, JUnit XML saved per run:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341, 0 failures | 117 of 117 fail |
| with solution.patch | 3341, 0 failures | 117 of 117 pass |

Base-mode test IDs with and without the solution are identical (0 only with, 0 only without); no
`float-reference` case and no `unrecognized arguments`. The no-pytest-timeout image was not re-run:
`test.sh` and the Dockerfile are unchanged since round 11, where both images were verified.

## Platform precheck, round 14 (2026-09-14)

Solution Quality FAIL, Comprehensiveness 1/3, Code Quality 3/3. One issue, reproduced, and fixing
it surfaced a second bug that had been latent since round 3.

### A page float inside a continued ordinary float overlapped that float's fragment

A full-width `float: left` whose content continues onto page 2, with a full-width `float: top`
inside that continuation: the top float was placed at y=0-20 while the ordinary float's page-2
fragment stayed at y=0-50, overlapping it.

Cause: `make_page` lays out out-of-flow boxes broken on the previous page once, before the page-float
retry loop, and `saved_state` was captured after that, so every retry restored the same fragment.
The page floats found inside those fragments were collected once into `inherited_floats` and
placed, but the fragment itself was never laid out again against their exclusion shapes.

Fix: the broken out-of-flow layout moved into `_broken_out_of_flow_layout`, called inside the loop
after the page floats are placed and before the in-flow content, with the state captured before
any of it runs. Page floats found in those fragments are now collected every pass together with the
in-flow ones (in document order), so discovering one triggers a retry exactly like an in-flow anchor.
One detail mattered: the old code *assigned* the broken floats' shapes to their formatting context's
list, which now already holds the page floats' shapes, so it extends the list instead. The page's
formatting context has root `None` (`make_page` line 617), which is where both the page floats and
the broken floats live, so placing page floats first is what lets the broken float avoid them.
After the fix the continuation starts at y=20.

### Latent since round 3: a bottom page float pushed every later float off the page

The first version of that fix made the bottom-float variant worse: the continued fragment moved to
y=100, below a bottom float at y=80 and off the page. Tracing `avoid_collisions` showed the float
entering it already at y=80, and the same was true for an ordinary, non-continued full-width
`float: left` placed after a bottom page float, which was pushed to the next page. So this was not
caused by the loop change, only exposed by it.

`find_float_position` implements CSS 2.1 float rules 5 and 6 by moving a float down to the top of
the most recent exclusion shape. Round 3 made bottom page floats exclusion shapes, so a float pinned
to the page bottom became "the most recent float" and dragged every later float on the page down to
it. Top page floats sit at the page top, so they never showed it.

Fix: rules 5 and 6 now take that position from the most recent shape that is not a page float.
Those rules order floats by source position, and page floats are pinned to their reference edge
instead; collision avoidance still sees every shape, so content is still laid out around page floats
exactly as around a `float: left`. Without page floats nothing changes. After the fix: the continued
fragment sits at y=0-50 above the bottom float, and the ordinary float stays on its page at y=0.

Tests: a top float in a continued ordinary float pushes the continuation down; a bottom float in a
continued ordinary float leaves it at the top; an ordinary float after a bottom page float stays on
its page.

Trap-proof for both fixes:

| Mutation | Result |
|---|---|
| page floats count for float rules 5 and 6 again | 2 failed - bottom float in a continued ordinary float; ordinary float after a bottom page float |
| broken out-of-flow boxes laid out before the page floats (the old order) | 1 failed - top float in a continued ordinary float |

### Re-validation (round 14)

Local, solution applied: 3444 passed, 0 failures (3441 plus the 3 new tests). Repo float, page,
footnote, position, column and inline suites: 292 passed. New suite 3 times in random order: 120
passed, identical. 120 of 120 fail on base. Patches regenerated and verified to contain
`_broken_out_of_flow_layout`, the rule 5 change and the three tests; test.sh still
`new file mode 100755`; ruff clean. LOC hook: human-effective 479 across 13 files.

Container: the round-11 image (submission Dockerfile) with the regenerated `solution.patch` and
test file mounted, `--network none --user 1000:1000`, JUnit XML saved per run:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341, 0 failures | 120 of 120 fail |
| with solution.patch | 3341, 0 failures | 120 of 120 pass |

Base-mode test IDs with and without the solution are identical (0 only with, 0 only without); no
`float-reference` case and no `unrecognized arguments`. The no-pytest-timeout image was not re-run:
`test.sh` and the Dockerfile are unchanged since round 11, where both images were verified.

## Auto Review, round 15 (2026-09-14)

Description 3/3 and Tests 3/3, both clean. Solution 1/3 on two High findings, both verified,
both about which fragment of a flex or grid container owns a page float. No agent runs yet.

### S1 flex: a float after a fragmented item in a reverse flex container was dropped

`column-reverse` flex, a first item that fragments, then `float: top` F: F appeared on no page. The
forward `column` case put F on the last page next to the item's last line. Reproduced at the
reviewer's exact sizes too.

Cause: my round-7 rule emitted a placeholder when its index was before the resume index, which
assumes forward traversal. Reverse continuations keep `children[:skip + 1]`, so the float the first
pass held back was sliced out of every later pass and never reached a page root.

### S1 grid: a float after a multi-page grid item was placed on that item's first page

A grid item spanning three pages followed by F: F landed on page 1. Cause: `laid_out` came from
`this_page_children` alone, so an item counted as done as soon as its first fragment appeared,
ignoring that it still had a continuation. The same code also compared a document-order sibling
count against indexes into the list sorted by `order`, a latent mismatch.

### One ownership rule for both

A page float belongs to the fragment where the in-flow item before it in document order finishes
(laid out with no continuation), or to the first fragment when nothing precedes it. Each item
finishes in exactly one fragment, so each float is emitted exactly once, whatever the traversal
direction or index space.

- Flex builds its page-float placeholders from the unsliced `box.children` in document order, each
  paired with the flex item before it, records items finishing in the fragment, and emits floats
  whose item finished there. If the container ends with no continuation, floats after items that
  were cut short are kept, so truncation cannot lose them.
- Grid pairs each float with its preceding item object and records items laid out without
  `broken_child`.

### Pre-existing grid re-entrancy bug, exposed by the fix

With the rule in place, the grid float landed alone on a fourth, empty page. A baseline without
the float gives three fragments, so the page came from the retry. Tracing `grid_layout` and
`make_page` showed page 3's first pass finishing the item and emitting F; the retry with F placed
then saw `skip_height=0` instead of 60, treated the item as broken, withheld F, and let its anchor
go stale.

`grid_layout` keeps per-cell `advancements` on the grid box, reads them to resume a fragment and
clears and rewrites them for the next one. So laying out the same continuation twice read values the
first attempt had already overwritten. Base has identical code, and nothing saves or restores them;
the page-float retry is just the first thing that re-lays out a grid continuation on the same page.

A first attempt, restoring a snapshot whenever the skip stack repeated, broke
`test_grid_in_columns`: column balancing re-renders column 1 at a new trial height, which writes
fresh advancements, and then resumes column 2 with a skip stack equal to an earlier one, so the stale
snapshot won. The kept fix records advancements under the resume point they were written for (on
the input box, at the only exit that returns a continuation), and a continuation starts from the
latest ones recorded for its skip stack. Column balancing keeps base behaviour because column 1
rewrites that entry just before column 2 reads it; a page retry works because the only write for
page 3's resume point still comes from page 2.

Tests: the fragmenting flex item for `column` and `column-reverse`, and the multi-page grid item with
and without a following item. The `column-reverse` and both grid cases failed before the fix.

Trap-proof, each fix reverted on its own:

| Mutation | Result |
|---|---|
| flex: an item present in the fragment counts as finished | 3 failed - the fragmented flex container test and both fragmented flex item cases |
| grid: any laid-out item counts as finished | 2 failed - both fragmented grid item cases |
| grid: no advancements restore for a repeated fragment | 2 failed - both fragmented grid item cases |

### Re-validation (round 15)

Local, solution applied: 3448 passed, 0 failures (3444 plus the 4 new cases). Repo grid, flex,
page and column suites: 388 passed, including `test_grid_in_columns`. New suite 3 times in random
order: 124 passed, identical. 124 of 124 fail on base. Patches regenerated and verified to contain
the finished-item rule and `_skip_stack_key`; the only `deepcopy` lines are the page float's own
copy and a pre-existing line in `page.py`. test.sh still `new file mode 100755`; no CRLF; ruff
clean. LOC hook: human-effective 501 across 13 files.

Container: the round-11 image (submission Dockerfile) with the regenerated `solution.patch` and test
file mounted, `--network none --user 1000:1000`, JUnit XML per run. The cell script now reports a
failed `git apply` instead of silencing it (the round-14 "patch does not apply" report showed why);
none failed.

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341, 0 failures | 124 of 124 fail |
| with solution.patch | 3341, 0 failures | 124 of 124 pass |

Base-mode test IDs with and without the solution are identical (0 only with, 0 only without); no
`float-reference` case and no `unrecognized arguments`. The no-pytest-timeout image was not re-run:
`test.sh` and the Dockerfile are unchanged since round 11, where both images were verified.

## Auto Review, round 16 (2026-09-14)

Description 3/3, Solution 3/3. Tests 1/3 on three High coverage findings: realistic implementations
could omit a solution hunk and still pass every submitted test. No solution change this round.

Probed all three against the solution first, since earlier coverage gaps hid real bugs:

- Inline anchor. `<p>before <span style="float: top">F</span> after</p>`: the span becomes a
  direct page float at (0, 0, 20, 10), the paragraph keeps only "before " and "after" with no span
  box left, and its first line starts at x=20 beside the float. The bottom variant lands at
  (0, 90, 20, 10). Correct.
- Replaced float. The 4x4 `pattern.png` as `float: top` / `bottom` is a `BlockReplacedBox` at
  (0, 0, 4, 4) / (0, 96, 4, 4) on the page, and a direct child of the column at the same positions
  with a column reference. Correct.
- Painting. Nothing tested it. The layout tree alone cannot show paint order.

Tests added:

- `test_a_page_float_inside_a_paragraph_leaves_the_inline_content`, top and bottom: direct page
  float, edge placement, span gone from the paragraph, surrounding text kept, first line wrapping.
- `test_an_image_page_float_has_its_intrinsic_size` and
  `test_an_image_column_float_has_its_intrinsic_size`, top and bottom: `BlockReplacedBox`,
  intrinsic 4x4 outer area, direct parentage, edge placement.
- `test_a_page_float_is_painted_above_an_overlapping_block_background`, a repository pixel test:
  a red 2x2 top float and a later blue 4px block. The block does not establish a formatting context,
  so its background spans the full width under the float; the float must paint in the float phase
  and stay red. Expected `rrBB / rrBB / BBBB / BBBB`. No text, so it does not depend on fonts.
  Ghostscript is present locally and in the image.

Trap-proof, each hunk removed on its own:

| Removed | Result |
|---|---|
| `stacking.py`: page floats dispatched as float contexts | 1 failed - the pixel test (the float is painted as an earlier block and the blue background covers it) |
| `inline.py`: page-float branch in inline out-of-flow layout | 9 failed - both paragraph cases, plus seven nested-context cases whose markup puts the float after inline text |
| `float.py`: `BlockReplacedBox` sizing in `page_float_layout` | 4 failed - exactly the four image cases |

A failing pixel run writes PNGs into `tests/draw/results/` in the worktree. That directory is
git-ignored (`.gitignore:8`), so `gen_patches.py` staging `tests/` cannot pick them up; they were
deleted anyway, and the test.patch file list was checked to contain only `test.sh` and the test file.

### Re-validation (round 16)

Local, solution applied: 3455 passed, 0 failures (3448 plus the 7 new cases). New suite 3 times in
random order: 131 passed, identical, the pixel test included. 131 of 131 fail on base. solution.patch
is unchanged this round (human-effective 501); test.patch regenerated, contains only `test.sh` and the
test file, `new file mode 100755`, no CRLF; ruff clean.

Container: the round-11 image (submission Dockerfile, Ghostscript 10.00.0) with `solution.patch` and
the test file mounted, `--network none --user 1000:1000`, JUnit XML per run, apply failures reported:

| | base mode | new mode |
|---|---|---|
| without solution.patch | 3341, 0 failures | 131 of 131 fail |
| with solution.patch | 3341, 0 failures | 131 of 131 pass, pixel test included |

Base-mode test IDs with and without the solution are identical (0 only with, 0 only without); no
`float-reference` case, no `unrecognized arguments`, no apply failure. The no-pytest-timeout image was
not re-run: `test.sh` and the Dockerfile are unchanged since round 11, where both images were verified.

## Batch 1 (2026-09-14): 10 Nova, 0 of 9 graded passed

Result: 0% pass. Nova 7 produced no artifacts (only its run header), so 9 runs were graded. Every graded
run kept all 3326 baseline tests green and failed between 70 (Nova 4) and 86 (Nova 5) of the 131 new
tests. Effort was high everywhere: 154-203 tool calls and 20-31M prompt tokens per run. Every evaluator
marked the description clear and the failures fair (`description_clear=True`,
`agent_blame_unfair=False`); Nova 5's `blocker=environment` refers only to the agent chasing seven
unrelated local full-suite failures that the grading wrapper deselects, and the evaluator still blames
the implementation.

### The shared wall: re-laying out the page when a float is found after content

45 tests fail in all 9 runs, including the most basic ones. In 8 of 9 runs they fail at the first
line, `page, = render(...)`, because `<p>one</p><p>two</p><div>F</div><p>three</p>` renders to more
than one page. Reproduced with the best run's patch (Nova 4) on a clean base checkout: with content
before the float, page 1 holds "one" and "two" and the float is pushed to the top of page 2 with
"three"; with the float first, the single page is correct. The evaluators describe the same thing: the
agents lay out the float in its source context, find they cannot place it at the page top once content
is already there, and defer it to a later page instead of laying the current page out again with the
float placed first. Nova 8 does the other half-measure: one page, but the float stays at its anchor
position (y=20). This is exactly trap F-1 predicted at design time, and it sits under almost every
fixture because almost every fixture puts content before the float.

### Not a single-trap near miss

Failures spread across mechanisms, not one: over all runs, 278 "too many to unpack" (mostly extra
pages), 165 "not enough to unpack" (missing pages or boxes), 100 geometry mismatches, 116 other
assertions. Even the best run fails 70 tests. The later review rounds each added a real, fair
requirement (column deferral and container ownership, nested multicol, footnote reservation, flex and
grid document order and fragment ownership, continued ordinary floats, float rule 5, inline and
replaced anchors, painting), and a passing run now has to get all of them right at once on top of the
re-layout. Fixing the re-layout wall alone would not make any of these runs pass.

### Options (decision pending)

- Narrow the scope to a solvable core and re-batch. Likely candidates to drop are the column
  reference family and the fragmented-flex/grid and continued-float integrations, keeping page floats
  (top/bottom, stacking, deferral, anchor following, re-layout, footnotes, nesting). Costs: rework of
  meta.md, tests and solution, a fresh full-price batch, and a LOC check against the 200 floor.
- Keep the scope and state the re-layout behaviour more directly in meta.md. Cheapest, but the
  evidence says it would not lift any run to a pass, since the best run still fails 70 tests beyond it.
- Stop here. At 0% the submission is a reject as-is.

Re-eval does not help: it re-grades the same solutions, and no run is close enough that relaxing tests
fairly would make it pass.

## Round 17: scope narrowed after batch 1 (0/9)

Decision: narrow the scope. Kept page floats only: `top`/`bottom`, stacking, deferral, anchor following,
re-layout of earlier content, footnote reservation, nesting exceptions, inline and replaced anchors,
multi-column containers avoiding page floats, painting. Dropped `float-reference`, column floats (and all
their deferral, fragment and container-ownership machinery), page floats inside flex and grid containers
(flex and grid items now ignore `top`/`bottom` like other float values), continued ordinary floats, and
forced or named breaks inside a page float.

Solution: 13 files / 501 eff down to 12 files / 298 eff. Removed the `float-reference` property and
validator, the column float layout in column.py and block.py, the column routing in page.py, and the
flex/grid placeholder code. `compute_float` now turns `top`/`bottom` into `left` inside any float
ancestor. The document-order sort and `element_order` were removed: with column, flex and grid floats
gone, floats are already collected in document order (mutation survived, so it was dead).

Tests: 92 functions / 131 cases down to 53 / 71. Dropped 41 functions. Rewrote the ordinary-float nesting
test to "computes to left" (4 cases), removed `float-reference` from the kept column and positioned tests,
added `test_flex_and_grid_items_ignore_page_floats` (4 cases), kept rule 5 via
`test_an_ordinary_float_after_a_bottom_page_float_stays_on_its_page`. test.sh lost the three
`[float-reference]` deselects.

meta.md: rewritten, 401 body words. New title "Add page floats to the layout engine". States the re-layout
directly ("the content before it is laid out again around the float, rather than the float moving to a
later page"), the rule-5 exception, multicol non-overlap, flex/grid items ignoring the values, and the
nesting list (any float, footnote, absolute/fixed, running element).

Mutations on the new suite: killed no-relayout (46), no-stale (2), no-footnote-reserve (1), no-deferral (4),
no-bottom-clamp (1), columns-top (1), columns-bottom (1), nested-float-compute (4), flex-grid-not-ignored
(4), rule5-unfixed (1). Survivors kept as defensive code: the `in_page_float` break and page-name guards
(their forced/named break tests were dropped with the scope; without them a break inside a float loses
content) and the grid advancement re-entrancy (a fragmented grid laid out again by the page retry loop).

Local: new suite 71 passed 3x identical; base targets 3325 passed, 1 local-only failure
(`test_table_vertical_align` logs a HarfBuzz-Subset warning here and fails the same way on a clean base
checkout). Batch 1 is stale (meta.md changed): a fresh full batch is needed.

Clean-room (v10 image, final patches): new mode 71/71 pass with the solution and 71/71 fail without it;
base mode 3341 passed with and without the solution, test IDs identical, no apply failures.

## Round 18: Solution Quality FAIL (1/3 comprehensiveness)

Issue 1, "column floats are not implemented": the reviewer quotes the title "Add page and column floats to
the layout engine", which is the pre-round-17 title. meta.md now says "Add page floats to the layout engine"
and never mentions column floats, so the platform's Title field (or its copy of meta.md) is stale. Fix is
on the platform side: update the Title field and re-upload meta.md. No code change.

Issue 2, multicol inside a nested context overlaps a page float: confirmed, but not for the reviewer's
`overflow: hidden` example (that BFC is moved below the float, same as base with a `float: left` box).
Overlap matrix over wrappers (overflow hidden, flow-root, flex, grid, table cell, inline-block, ordinary
float, plain block) x top/bottom x narrow/full float x short/fragmenting content: only flex and grid
wrappers overlapped (4-12 column children each). Cause as reported: column.py read page floats from the
current BFC's `excluded_shapes`, which flex and grid items replace with their own list.

Fix: `LayoutContext.page_float_shapes`, set in the page loop right after `page_floats_layout` and cleared
after the loop; column.py reads it instead of filtering `excluded_shapes`. The footnote area layout saves and
clears it so footnote columns are not affected by page floats. Absolute and fixed multicol boxes were
probed and do not move. New test `test_columns_in_a_flex_or_grid_container_do_not_overlap_a_page_float`
(flex/grid x top/bottom, 20 lines, checks no column child overlaps the float and all lines are kept).
Fails 4/4 on the previous solution; making column.py ignore `page_float_shapes` fails it plus the two
existing column tests.

meta.md: deleted "For boxes that are absolutely positioned or fixed, float computes to none." (base already
does this). Kept `is_page_floated()` (tests call it, agents need the name) and the flex/grid sentence (base
has no `is_page_floated`, so a flex item could report True). 389 body words.

Local: new suite 75 passed; base targets same single env failure; `tests/draw` fails 169 on the clean base
checkout too (HarfBuzz-Subset warning logged), so not a regression. Solution 12 files, 301 eff.

Clean-room (v10 image, round-18 patches): new mode 75/75 pass with the solution and 75/75 fail without it;
base mode 3341 passed with and without the solution, test IDs identical, no apply failures.

## Round 19: Solution Quality FAIL (Code Quality 1/3, W293)

Claim: a whitespace-only `+ ` line after `return out_of_flow_boxes` in page.py. Not reproducible on our file:
the two lines after it in solution.patch are bare `+` (checked with `cat -A`), no added line in solution.patch
or test.patch is whitespace-only, and there are no CRs. Applying solution.patch to a clean base checkout
and running `ruff check weasyprint/` (repo config, ruff 0.16.7, W rules included) gives "All checks passed!".
No older local copy has the line either. Either the platform copy was padded on upload (pasting into
a web editor can turn empty `+` lines into `+ `) or the reviewer misread a blank context line. Action:
re-upload solution.patch as a file, check that hunk on the platform, and contest with the ruff output if it
is clean there. No code change.

## Final: REJECTED (derivative corpus overlap), shelved 2026-09-15

Platform rejected for overlap. Two older same-repo submissions from other authors implement the same page-float
engine (collection, placement, stacking, fit-deferral, repagination): 156/254 discounted subject lines (61.4%)
and 103/254 (40.6%). Upstream WeasyPrint never shipped page floats; Vivliostyle page-floats.ts (31/75 cases) and
PagedJS fragmentainers page-float.js (4/75) were noted as partial public precursors, not blockers. The overlap
is in the feature's core, so no edit can remove it. Shelved to rejected/ rather than re-run.
