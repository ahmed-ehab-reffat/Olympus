# weasyprint-page-floats — evaluation results

No batch has been run yet. Fill one row per agent run.

## Batch 1 (2026-09-14): 10 Nova, 0 of 9 graded runs passed

Baseline 3326/3326 passed in every graded run. Nova 7 produced no artifacts and was not graded. Files
touched and added lines count production code only (agents also edited repo tests). Failure classes
come from the JUnit messages: "extra" is `too many values to unpack` (mostly the document spilling onto
extra pages), "missing" is `not enough values to unpack`.

| Agent | Evaluator | Verdict | Messages | Files touched | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| Nova_Nova_1 | Nova | FAIL_WRONG_LOGIC | 173 tool calls | 10 | +349 | 77/131 | extra pages/boxes 24, missing 30, geometry 8, other 15 | The agent lays out page and column floats immediately inside the current formatting pass and uses a captured static-position check; for a top float en |
| Nova_Nova_2 | Nova | FAIL_MISSED_REQUIREMENT | 174 tool calls | 12 | +408 | 77/131 | extra pages/boxes 40, missing 9, geometry 10, other 18 | The agent implemented the property and much of the placement plumbing, but top floats commonly get deferred even when the page has room, causing simpl |
| Nova_Nova_3 | Nova | FAIL_MISSED_REQUIREMENT | 154 tool calls | 12 | +421 | 77/131 | extra pages/boxes 42, missing 8, geometry 10, other 17 | The implementation runs and preserves the baseline, but it places floats while laying out their source and only uses local overflow flags |
| Nova_Nova_4 | Nova | FAIL_MISSED_REQUIREMENT | 203 tool calls | 10 | +367 | 70/131 | extra pages/boxes 24, missing 29, geometry 5, other 12 | The patch adds the CSS values and some local placement logic, but it lays page and column floats while processing their source box and then prepends o |
| Nova_Nova_5 | Nova | FAIL_MISSED_REQUIREMENT | 156 tool calls | 10 | +285 | 86/131 | extra pages/boxes 32, missing 28, geometry 11, other 15 | The CSS additions and basic placement logic are present, but page floats are laid out eagerly in their source context and only partially extracted aft |
| Nova_Nova_6 | Nova | FAIL_MISSED_REQUIREMENT | 183 tool calls | 10 | +402 | 82/131 | extra pages/boxes 33, missing 24, geometry 13, other 12 | The implementation adds parsing and some basic placement, but it lays page floats out immediately in the writing context and only reparents them after |
| Nova_Nova_7 | Nova | no result (run produced no artifacts) | - | - | - | - | - | - |
| Nova_Nova_8 | Nova | FAIL_MISSED_REQUIREMENT | 183 tool calls | 9 | +299 | 84/131 | extra pages/boxes 12, missing 20, geometry 22, other 30 | The implementation adds the CSS values and substantial float scaffolding, but page and column floats are placed during source traversal and their sour |
| Nova_Nova_9 | Nova | FAIL_MISSED_REQUIREMENT | 162 tool calls | 12 | +364 | 75/131 | extra pages/boxes 34, missing 9, geometry 10, other 22 | The code runs and preserves all baseline behavior, but it does not implement several explicit page-float requirements |
| Nova_Nova_10 | Nova | FAIL_MISSED_REQUIREMENT | 168 tool calls | 13 | +374 | 76/131 | extra pages/boxes 37, missing 8, geometry 11, other 20 | The implementation adds the properties and basic placement machinery, but does not correctly implement page/column float fragmentation and anchor trac |

Per-test kill counts: 45 tests fail in all 9 graded runs, including the most basic ones
(`test_page_float_top_is_placed_at_the_top_of_its_page`, `test_float_reference_keywords_are_accepted[*]`,
`test_page_float_margins_are_honoured`). In 8 of 9 runs those fail at `page, = render(...)` because
`<p>one</p><p>two</p><div>F</div><p>three</p>` renders to more than one page; in Nova 8 the float stays
at its anchor position (y=20) instead of the page top.

## Local pre-batch measurements

| Measurement | Value |
|---|---|
| New tests | 131 (91 functions, 40 parameterized cases), including one pixel test |
| New tests failing on base | 131 of 131 (local and in the v10 container) |
| Local full suite (solution applied) | 3455 passed, 0 failures (9 deselected incl. the 3 property-parametrized float-reference cases) |
| Solution human-effective LOC | 501 |
| Solution files | 13 |
| Mutations killed | 21 (round 0) + 5 (round 3) + 3 (round 4) + 1 (round 5) + 1 (round 6) + 3 (round 7) + 1 (round 8) + 1 (round 9) + 1 (round 10) + 1 (round 11) + 2 (round 12, coverage) + 1 (round 13) + 2 (round 14) + 3 (round 15) + 3 (round 16, coverage) |
| Flakiness | 3 identical runs, randomized order |
| Lint | ruff clean on source and the new test file |

## Narrowed scope (round 17), pre-batch measurements

Batch 1 above ran against the full scope and is stale for the narrowed submission.

| Measurement | Value |
|---|---|
| New tests | 75 (54 functions), including one pixel test |
| New tests failing on base | 75 of 75 (v10 container, round 18) |
| Container with solution | new 75/75 pass; base 3341 pass, 0 failures; base test IDs identical with and without solution (3341) |
| Local base targets (solution applied) | 3325 passed, 1 local-only env failure (fails on clean base too) |
| Solution human-effective LOC | 301 |
| Solution files | 12 |
| Mutations killed | 10 of 14 (survivors: in_page_float break and page-name guards, grid re-entrancy, and the removed document-order sort) |
| Flakiness | 3 identical runs |
| Lint | ruff clean |
