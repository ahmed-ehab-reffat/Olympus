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
