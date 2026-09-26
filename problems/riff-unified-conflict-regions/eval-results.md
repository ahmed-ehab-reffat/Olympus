# riff-unified-conflict-regions - eval results

No platform batch yet (slice awaiting the precheck).

## Local validation (2026-09-23, SLICE)

| Check | Result |
|---|---|
| Cold `docker build --no-cache` | 153 s (build step 79 s, export 41 s) |
| Clean room, uid 0 / 1000 / 4242, `--network none` | identical for all three |
| test.patch only: `test.sh base` | 62 testcases, 0 failures, exit 0 |
| test.patch only: `test.sh new` | 9 testcases, 9 failures (assertion diffs, not crashes), exit 101 |
| + solution.patch: `test.sh base` | 62 / 0, exit 0 |
| + solution.patch: `test.sh new` | 9 / 0, exit 0 |
| JUnit hygiene | 0 `::`, 0 duplicate (classname, name) |
| Flakiness, base + new x3 in container | identical fingerprints |
| Build-failure fallback | new: 9 named failing cases; base: 1 `compilation` case |
| effective_loc_check.py solution.patch | raw 640, human-effective 445, 6 files |
| cargo fmt --check, cargo clippy (default targets) | clean |

## Trap reproduction (mutations of the reference, new tests)

| Mutation | Tests failing |
|---|---|
| M1 resolved context line counted for its side only | resolved_kept_line_counts_for_its_side_and_the_resolution (fails on side 2's row) |
| M2 region ends at the closing marker | 5 of 9 |
| M3 open region flushed at hunk end | region_continues_across_hunks |

## Local validation (2026-09-25, after Auto Review round 1)

| Check | Result |
|---|---|
| `docker build` (clean clone at base, `.git` included) | exit 0 (slow: host load avg 30-110 from other sessions) |
| Clean room, uid 0 / 1000 / 4242, `--network none` | identical for all three |
| test.patch only: `test.sh base` / `new` | 62/0 exit 0 / 17 testcases, 17 failures (all assertion diffs), exit 101 |
| + solution.patch: `test.sh base` / `new` | 62/0 exit 0 / 17/0 exit 0 |
| JUnit hygiene | 0 `::`, 0 duplicate IDs |
| Flakiness, base + new x3 (uid 1000) | identical fingerprints |
| effective_loc_check.py solution.patch | human-effective 452, 6 files |
| cargo fmt --check, clippy (default targets + new test crate) | clean |

## Mutation matrix for the round-1 cells (new tests killed)

| Mutation | Tests failing |
|---|---|
| unresolved context uses the role's inverse prefix (the reviewed S1 bug) | unresolved_context_lines_stay_plain_in_every_section, unresolved_first_side_is_refined_against_the_second |
| marker length not compared | marker_count_must_match_the_opening_marker, shorter_marker_lines_inside_a_longer_region_are_content |
| marker prefix not compared | marker_with_another_prefix_is_content |
| empty-side exception dropped (base union always) | unresolved_base_shows_only_what_the_second_side_removed_when_the_first_is_empty |
| plus/minus block flushed at the opening marker | lines_outside_every_side_are_not_compared |
| only resolved regions carried across hunks | unresolved_region_continues_across_hunks |

## Local validation (2026-09-25, after Auto Review round 2: sequential marker sets)

| Check | Result |
|---|---|
| Clean room, uid 0 / 1000 / 4242, `--network none` | identical for all three |
| test.patch only: `test.sh base` / `new` | 62/0 exit 0 / 25 testcases, 25 failures, exit 101 |
| + solution.patch: `test.sh base` / `new` | 62/0 exit 0 / 25/0 exit 0 |
| JUnit hygiene | 0 `::`, 0 duplicate IDs |
| Flakiness, base + new x3 (uid 1000) | identical fingerprints |
| effective_loc_check.py | human-effective 495, 6 files |
| fmt, clippy (default targets + new test crate) | clean |

| Mutation (round 2) | Tests failing |
|---|---|
| later opener after a closer ignored (the reviewed bug) | two_unresolved_sets..., two_resolved_sets..., two_diff3_sets..., sets_that_disagree_on_a_base..., unfinished_second_set... |
| between lines get no role | two_resolved_sets_in_one_block_share_the_resolution |
| base-marker agreement unchecked | sets_that_disagree_on_a_base_look_like_today |
| next set keeps the first set's marker length | two_unresolved_sets_in_one_block_are_both_refined |
| six-character markers accepted | opening_marker_needs_seven_characters_and_a_space_before_its_label |
| label without a space accepted | opening_marker_needs_seven_characters_and_a_space_before_its_label |
| separator with trailing text accepted | base_and_separator_lookalikes_are_content |
| all round-1 mutations | still killed |

## Local validation (2026-09-25, after Auto Review round 3: resolution vs base)

Clean room uid 0/1000/4242 `--network none`: base 62/0 before and after; new 29/29 fail before (assertion diffs), 29/0 after; 0 `::`, 0 dups. Flakiness x3 identical. fmt + clippy clean. human-effective 497.

| Mutation (round 3) | Tests failing |
|---|---|
| resolution-vs-base tokens dropped (the reviewed bug) | resolved_resolution_is_refined_against_the_base_too |
| empty base compared | resolved_empty_base_is_not_compared (+5 two-way resolved tests, mutation is broad) |
| base marker requires a label | resolved_resolution_is_refined_against_the_base_too |
| unassigned lines printed unstyled | lines_outside_every_side_are_not_compared |
| resolved context counted for the first side only | none (not observable; context is raw and always in the resolution) |

## Batch 1 (2026-09-25): 10 Nova + 1 Vega, suite = round-3 test.patch (29 tests) -> 0/11

Median 86 model requests (floor 40). Baseline green in all 11. Local replay of the saved patches reproduces every platform verdict exactly.

| Run | New failures (platform) | Approach / why |
|---|---|---|
| Nova #10 (dir Nova_Nova_1) | out_of_order, 2x empty-side | empty side panics in refiner::bridge_consecutive_highlighted_tokens; out-of-order set kept open |
| Nova #1 (Nova_Nova_10) | 29/29 | joins region lines without newlines (every text check fails) |
| Nova #9 (Nova_Nova_2) | base_after_separator | out-of-order set kept open, swallowed the valid third region |
| Nova #8 (Nova_Nova_3) | marker_count, out_of_order | drops an open region's lines at the file boundary |
| Nova #7 (Nova_Nova_4) | base_after_separator, out_of_order, kept_line | accepts base after separator; M1 kept-line trap |
| Nova #6 (Nova_Nova_5) | marker_count, two_unresolved, out_of_order | loses lines at file boundary; next set keeps first marker length |
| Nova #5 (Nova_Nova_6) | base_after_separator, out_of_order, two_resolved | between lines not in every side |
| Nova #4 (Nova_Nova_7) | kept_line, out_of_order | M1 kept-line trap |
| Nova #3 (Nova_Nova_8) | out_of_order, 3x two-sets, 2x empty-side | no multi-set support; empty-side panic |
| Nova #2 (Nova_Nova_9) | base_after_separator, out_of_order | accepts base after separator |
| Vega #1 (Vega_Nova) | out_of_order, 2x empty-side | empty-side panic |

UNFAIR cluster: out_of_order_markers_look_like_today_and_a_later_region_is_refined killed 9/11 and base_after_separator 4/11 for the same reason: meta.md never says where an out-of-order set ends, and most agents keep it open and swallow the next valid region (only Nova_2 matched the reference reading). Tests-only fix: the valid region after an out-of-order set now sits in a separate file, so both readings produce the same output.

Replay of saved patches:

| Suite | Passes | Near misses (1 failure) |
|---|---|---|
| batch suite (29) | 0/11 | Nova_2 |
| + out-of-order split | 1/11 (Nova_2) | Nova_6, Nova_7, Nova_9 |
| + marker-prefix asserts | 1/11 (Nova_2) | same |
| + removed opener after added lines (FP fix, 30 tests) | 0/11 | Nova_2, Nova_6, Nova_7, Nova_9 |

FP probe (47 fixtures, reference vs every agent binary): Nova_2 misses only `-a +b -<<<<<<<` (a removed opener after added lines starts a new block, stated in meta.md; 8/11 agents handle it). Untested in the 29-test suite, so its pass would have been a false positive. Now tested.
NNAEOF cell (Auto Review advisory) NOT added: riff's refinement appends a `⏎` glyph to side lines when the resolution lacks a final newline, which contradicts "every line keeps its text"; pinning it needs a meta change.

Final suite (30 tests) clean room uid 0/1000/4242: 62/0 base, 30 fail before / 30 pass after; flaky x3 identical.

## Batch 2 (2026-09-26): re-eval of batch 1 on the 30-test suite + 1 new Nova run -> 1/12, FP-flagged

Re-eval verdicts for the 11 batch-1 solutions match the local replay exactly (0/11). New run Nova_Nova_11 (85 requests) passed 30/30 but the FP panel flagged it:
1. Empty side / empty resolution in resolved regions, and an empty side in two-way unresolved regions, panic riff (refiner::bridge_consecutive_highlighted_tokens underflows on empty text). Only diff3 empty sides were tested, where the candidate skips them. REAL gap: reference handles all three.
2. An ordinary diff with an added empty line + `\ No newline at end of file` crashes the candidate. NOT tested on purpose: base riff itself mishandles this input family (crashes on `-old +<empty> \`, `-<empty> \ +<empty>`, `-old \ +<empty> \`; silently drops the last two lines on the judge's exact input). A test would have to pin base's dropped lines, contradicting "every line keeps its text". Evidence fixtures: worktrees/_riff_val/fx8/v1..v7 + fx7/plain_empty_nnaeof.

Fix (tests-only): resolved_empty_side_is_still_compared, resolved_region_without_a_resolution_keeps_every_line, unresolved_two_way_empty_side_keeps_every_line (33 tests). They assert every line kept, markers reversed after the prefix, and only spans that do not depend on comparing against empty text (riff's refiner panics on empty input, so there is no "usual" result to pin). Mutation: removing the reference's empty-text guard fails all 3 plus both diff3 empty-side tests.

Advisory cells: "between lines in the base" is already discriminated (dropping Base from between-line roles fails two_diff3_sets_in_one_block_share_the_base). "Opposite-prefix opener before the next set in the same block" cannot occur: an opposite-prefix line either ends the block or becomes resolution content.

Replay of all 12 saved solutions on the 33-test suite: 0/12. One fair failure each: Nova_2 (removed opener after added lines), Nova_6 (between lines in every side), Nova_7 (kept line), Nova_9 (base after separator). Empty-side crashers: Nova_1, 4, 8, 11, Vega.
Clean room uid 0/1000/4242: 62/0 base, 33 fail before / 33 pass after; flaky x3 identical. solution.patch unchanged.
