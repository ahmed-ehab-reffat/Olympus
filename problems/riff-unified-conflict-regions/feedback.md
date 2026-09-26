# riff-unified-conflict-regions - feedback

Repo: walles/riff (Rust, MIT, 527 stars at 2026-09-23 - 27 over the floor, re-check at submit). Base 62ef8a7371a7823d3ea65542751c6068f591cc6b (= origin/master, unchanged since 2026-08-15).
Lane (hunt 09-23-N): conflict regions inside one-column unified diffs (remerge-diff resolved form, `git diff HEAD` unresolved form, diff3, cross-hunk, NNAEOF, base-identical fallback).
Mode: SLICE done (Step 4b). Reference started from the hunt spike `worktrees/_hunt/s_0923h27/riff_spike_v1.patch` and was reworked (below).

## Status (2026-09-23, end of SLICE)

- Core slice built and validated. Folder: BASE_COMMIT.txt, DESIGN.md, meta.md (draft, 432 words), test.patch (test.sh + tests/conflict_regions_119021.rs, 9 tests), solution.patch (6 files, 445 human-eff), Dockerfile, feedback.md, eval-results.md.
- Docker clean room (image built from a real clone at base, `.git` included, `--network none`), as uid 0, 1000 and unmapped 4242: base 62/62 pass before and after the solution; new 9/9 fail before, 9/9 pass after; 0 `::` in JUnit, 0 duplicate IDs. Cold `docker build --no-cache` 153 s.
- Flakiness: base + new 3x in the container, identical fingerprints.
- Traps reproduced by mutation (HARDENING 3a.4): M1 context line counted for its side only -> fails only `resolved_kept_line_counts_for_its_side_and_the_resolution`, on side 2's row (misdirecting, as designed); M2 region ends at the closing marker -> 5 tests; M3 open region flushed at hunk end -> `region_continues_across_hunks`.
- Build-failure fallback checked: a syntax error in src gives 9 named failing cases in new mode and one `compilation` case in base mode.
- Worktree: worktrees/riff holds the reference uncommitted (target/ deleted at end of run); clean room at worktrees/riff-cleanroom; probe tooling, fixtures and a base binary at worktrees/_riff_val (tools/show.py renders inverse spans as [..]; tools/fixhdr.py recomputes hunk counts; tools/lit.py prints base output as Rust literals).

## Scope-lock record

- PICK-FILTER 1/5/6/7/7b/8/9/10, SIX-CHECK, canonical-org PR-DIFF (walles/riff, not moved; 21 PRs ever, none in lane), all 79 upstream branches (every conflict branch is raw-file or combined `++` form; the only unmerged one adds a combined-diff test file), issues #56/#57/#65 read in full. Sibling code search finished locally after the API rate limit: delta handles only `++<<<<<<<`, difftastic only raw files; git-split-diffs, icdiff, ydiff, diff-so-fancy, diffr have no conflict or remerge handling. Details in DESIGN.md 0b/0c.
- Guard #2 (single-pipeline transform): argued in DESIGN.md 0d (role table x zone x polarity, a region lifetime that outlives the hunk highlighter, and an exact-replay fallback through the same chokepoint).

## Decisions (unattended run, conservative choices)

- Tests assert visible text (every line, in order) + reverse-video spans only, through an SGR-parsing helper; no colour pins. The two "exactly as today" cells compare full appearance (colour, weight, inverse per character) against output captured from the base binary. Keeps riff's exact-ANSI golden culture out of the new tests (hunt risk).
- Every "looks like today" check shares its input and test with a valid region, so each new-mode test fails on base.
- Dropped the spike's `remerge CONFLICT` bold header line: unrelated to the lane, would need its own sentence and a style pin.
- Test crate carries `#![allow(clippy::needless_return)]` (machine directive) to keep the repo's explicit-return style warning-free; panic messages use positional args because the crate is edition 2018.
- Comments: none added (repo comments some source, but the default is none and nothing here needs one).

## Reference changes vs the hunt spike

1. Marker grammar: only lines with the opening marker's prefix AND exactly its length are markers; everything else is content (the spike marked the set invalid, so a 9-char region holding 7-char content lines fell back).
2. An out-of-order set still ends at the block holding the next closing marker (the spike kept absorbing to the end of the file and swallowed a later valid region).
3. Base replay feeds `\ No newline at end of file` lines into the block highlighter (the spike printed them verbatim, so a carried incomplete region with NNAEOF was not base-identical). Now byte-identical, checked on two cross-hunk NNAEOF fixtures.
4. A finished `+` run is drained before a `-` opening marker (the spike absorbed `-a +b` into the region).
5. Empty (prefix-less) context lines are kept verbatim.

## FINISH plan (Step 4b onward; build only after the precheck verdict)

Cells to add (DESIGN.md 9, 11, 11b): resolved x cross-hunk with a kept line in the later hunk; unresolved x cross-hunk; unresolved removed line inside a side; run before the opening marker (same run vs drained `+` run); two regions in one hunk; 9-char markers with 7-char content lines and a `+=======` resolution line inside a resolved region (F-18); label forms; empty side in both polarities; unresolved diff3 empty-side rule; NNAEOF inside a resolved region; incomplete region before the next file (valid region in the next file); carried out-of-order region across hunks with NNAEOF (appearance vs base).
Open decisions for FINISH:
- Empty sides: riff's own convention compares an empty text as one empty line (no `⏎`). Either state it in meta.md or keep empty sides out of the fixtures that pin spans.
- NNAEOF: riff's refiner inserts a highlighted `⏎` and suppresses word highlights on a replaced last token (`-size = 10⏎` / `+size = 30`, nothing highlighted). Only test it with a sentence that says comparisons treat a missing final newline the way riff does for ordinary blocks, or test only that the `\` line stays in place.
- meta.md is 432 words; trim toward ~300 once the cell list is final (freeze before the first batch).
- Re-run the SIX-CHECK + exclusivity right before final patch generation; re-check stars.

## Attempt history

- 2026-09-23 SLICE: see Status.

- 2026-09-25 Auto Review round 1: Revision requested (Description 3/3, Tests 1/3, Solution 1/3; no agent runs yet).
  - S1 (x3, context prefix inverse in unresolved Side1/Base/Side2): fixed. Context lines inside an unresolved region now render with a plain prefix and plain unchanged text; only the highlighted spans keep the role's reverse video. Resolved context was already raw.
  - meta.md: one sentence added to the unresolved paragraph ("Context lines here keep a plain prefix and plain text apart from their highlighted parts."), 447 words. Free change, no batch has run yet.
  - T3/T4 gaps: 8 new tests (9 -> 17), each checked by a mutation of the reference that it kills:
    - marker_count_must_match_the_opening_marker (7/7/8 set at file end looks like today; unlabeled 8-char set in the next file is refined) + shorter_marker_lines_inside_a_longer_region_are_content -> kill length-blind marker matching
    - marker_with_another_prefix_is_content (`-=======` inside a `+` region) -> kills prefix-blind matching
    - unresolved_base_shows_only_what_the_{second,first}_side_removed_when_the_{first,second}_is_empty -> kill the unconditional base union (whole base reversed)
    - lines_outside_every_side_are_not_compared (`-flag = old`/`+flag = new` before a `+` opener, `+extra` after the closer) -> kills flushing the plus/minus block at the opener
    - unresolved_region_continues_across_hunks -> kills carrying only resolved regions between hunks
    - unresolved_context_lines_stay_plain_in_every_section + plain-prefix asserts added to unresolved_first_side_is_refined_against_the_second -> kill the inverse context prefix (new helper checks the prefix cell, which `marked` skips)
  - Human-effective LOC 452 (was 445). fmt + clippy (default targets, new test crate) clean; the 3 clippy errors under --all-targets pre-exist at base.
- 2026-09-25 Auto Review round 2 (Solution Quality FAIL, comprehensiveness 1/3; code quality 3/3): a second complete marker set in the same +/- block was never recognised (Zone::After only looked for the block end).
  - Semantics chosen and written into meta.md: an opening marker with the region's prefix in the closing block starts the region's next marker set (own marker length). Lines between sets are the cleanly merged text, so they belong to every side (and the base in diff3) and are shown as part of the first side. Sets must agree on having a base marker; any bad or unfinished set makes the whole region look like today. Sides stay whole texts, so every existing comparison rule applies unchanged.
  - Tried a "union of the rows" rule for between lines; riff's refiner gives identical rows for them on every probe, so the rule was unobservable. Replaced by the exact "shown as part of the first side" wording and removed the merge code.
  - meta.md 490 words incl. title (trimmed elsewhere to fit the multi-set sentences).
  - 8 new tests (17 -> 25): two unresolved sets (second with 9-char markers), two resolved sets sharing the resolution (between line changed in the resolution), two diff3 sets sharing the base, mixed base/no-base sets look like today, unfinished second set makes the whole region look like today, plus the advisory grammar cells (6-char set, `<<<<<<<label`, `|||||||| base` and `======= x` inside a 7-char set, base-after-separator and repeated separator). Resolved-base-context cell dropped: the aligner gives the same base highlights with or without the context line.
  - Mutations (all killed): review bug (later opener ignored) -> 5 tests; between lines no role; base consistency unchecked; next set keeps first length; 6-char markers; label without space; separator with label; plus all round-1 mutations still killed.
  - human-effective 495.
- 2026-09-25 Auto Review round 3 (Solution Quality FAIL, comprehensiveness): resolved diff3 dropped the resolution half of base-vs-resolution, so a resolution that matches both sides but not the base was never highlighted.
  - Fix: merge that token stream into the resolution. meta.md now says the resolution shows every part highlighted "in at least one of these comparisons" (was "against at least one side", which excluded the base) and "A base with no lines is not compared" (pins the existing empty-base behaviour instead of reversing the whole resolution). Trimmed `git diff HEAD` from P1 and shortened the base-agreement sentence; 488 words incl. title.
  - 4 new tests (25 -> 29): resolved_resolution_is_refined_against_the_base_too (equal sides, differing base, unlabeled `|||||||`), resolved_empty_base_is_not_compared, resolved_context_in_the_base_and_second_side_stays_plain, unfinished_resolved_region_looks_like_today (removed-marker EOF fallback). lines_outside_every_side_are_not_compared now also pins the ordinary red/green look of the three unassigned lines.
  - Advisory "resolved context membership in base/side2" is not observable: resolved context is printed raw and is always in the resolution, so a first-side-only mutation changes nothing. Only the plain look is asserted.
  - Mutations killed: review bug (resolution-vs-base dropped), empty base compared, base label required, unassigned lines unstyled; rounds 1-2 all still killed. human-effective 497. Clean room 62/62 + 29 fail-before/29 pass-after at uid 0/1000/4242; flaky x3 identical.
- 2026-09-25 Auto Review APPROVED (Description 3/3, Tests 2/3, Solution 3/3). Batch 1 (10 Nova + 1 Vega): 0/11. See eval-results.md for the per-run table.
  - Unfair cluster fixed tests-only: out-of-order set end was unstated (9/11 kills). Valid region moved to a separate file in both out-of-order tests.
  - Added marker-prefix assertions (Auto Review advisory): a mutation that reverses the whole marker line fails 2 tests; Nova_2 unaffected.
  - FP hole closed: removed_opening_marker_after_added_lines_starts_a_new_block (Nova_2's only gap). This takes the replay to 0/11 with four runs one fair test away, so a re-eval would read 0%. Decision pending: fresh batch vs cut a trap.
  - Suites kept: worktrees/_riff_val/suites/new/conflict_regions_119021.rs (30, current test.patch) and ...without_pto.rs (29, replays 1/11 but leaves Nova_2's pass a false positive).
- 2026-09-26 Batch 2 = re-eval (0/11, as replayed) + 1 new Nova pass that the FP panel flagged (empty-side panics; ordinary empty-line+NNAEOF crash). Added 3 empty-side tests (33 total). Did NOT test the ordinary NNAEOF input: base riff crashes or drops lines on that input family. Replay 0/12 with four one-failure near-misses, so a re-eval is pointless; next step is a fresh batch.
