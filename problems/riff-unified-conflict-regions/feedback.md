NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

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
