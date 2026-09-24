# DESIGN.md - riff-unified-conflict-regions

Repo walles/riff (Rust, MIT, 527 stars), base 62ef8a7371a7823d3ea65542751c6068f591cc6b (= origin/master).
Hunt: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-23-N.md` (spike `worktrees/_hunt/s_0923h27/riff_spike_v1.patch`).

## 0. Phase 1 - repo understanding

**Architecture (one paragraph).** riff is a streaming diff filter. `main.rs` reads stdin (or runs `diff`) and
feeds lines one at a time to `LineCollector` (`line_collector.rs`), which owns a stack-free chain of
`LinesHighlighter` trait objects (`lines_highlighter.rs`: `consume_line` returns
`AcceptedWantMore | AcceptedDone | RejectedDone` plus a list of `StringFuture`s, `consume_eof` drains). A
`--- ` line starts a `FileHighlighter` (`file_highlighter.rs`), which renders the file header (deferred one
line for hyperlinks) and spawns one `HunkLinesHighlighter` (`hunk_highlighter.rs`) per `@@` header. The hunk
highlighter counts remaining lines per column from the header, routes `-`/`+` runs to a
`PlusMinusLinesHighlighter` (`plusminus_lines_highlighter.rs`) and, for two-column combined diffs only, a
`++<<<<<<<` line to `ConflictsHighlighter` (`conflicts_highlighter.rs`). Blocks are refined by
`refiner.rs` (`diff(old, new)` tokenizes both texts with `tokenizer.rs`, runs a patience LCS from `similar`,
styles each token Unchanged / Midlighted / Highlighted, then `Formatter::format` renders rows through
`token_collector.rs`'s `render_row` using `LineStyle`s and `ansi.rs`). Output order is preserved because every
highlighter returns futures in input order and `LineCollector` prints them in order on a consumer thread
(`string_future.rs`).

**Five subsystems + boundaries.** (1) input + line routing: `main.rs`, `line_collector.rs`; (2) file/hunk
lifecycle: `file_highlighter.rs`, `hunk_header.rs`, `hunk_highlighter.rs`; (3) block highlighters:
`plusminus_lines_highlighter.rs`, `conflicts_highlighter.rs`, `rename_highlighter.rs`, `commit_line.rs`;
(4) refinement: `refiner.rs`, `tokenizer.rs`; (5) rendering: `token_collector.rs`, `ansi.rs`, `constants.rs`.

**High-entanglement zones.** (a) `HunkLinesHighlighter::consume_line[_internal]` - line counting, block routing,
nnaeof, hunk end, all in one state machine; (b) `FileHighlighter::consume_line` - header deferral, sub-highlighter
lifecycle, hunk hand-over; (c) `Formatter::format` + `refiner::diff` - every refined block goes through it, and
its NNAEOF `⏎` insertion couples tokenization to the texts' trailing newlines.

**Tests.** Unit tests are inline `#[cfg(test)] mod tests` (`hunk_highlighter.rs` calls private
`decrease_remaining_line_counts` / `remaining_line_counts`); `main.rs::test_testdata_examples` runs 43 golden
`testdata/*.diff -> *.riff-output` pairs (exact ANSI). Binary crate only (no lib target), so new tests are an
integration file in `tests/` that runs `env!("CARGO_BIN_EXE_riff")`. Template: `main.rs` golden test (process
level) + `hunk_highlighter.rs::test_happy_path` (ANSI expectations).

`#![deny(warnings)]` in `main.rs`: any warning (dead code, unused import) is a compile error.

## 0b. Phase 2 - existing PR / publicly solved (run 2026-09-23)

- Canonical org: `gh api repos/walles/riff -q .full_name` = walles/riff (not moved).
- PR search, all states: remerge, conflict, merge conflict, marker, markers, resolution, git diff HEAD, diff3,
  conflict region, unresolved, resolved -> only #55 (macports, 4 lines main.rs), #53/#28 (dependabot). Full PR
  list read (21 PRs ever): none in lane.
- Issues (all 71 read by title; #56, #57, #65 read in full with comments): #56 = raw-file conflict markers
  (implemented by walles, closed); #57 combined `diff --cc` (closed); #65 combined-diff context (fixed). No
  issue asks for one-column conflict regions; no snippet, no external implementation linked.
- Maintainer philosophy: #56 walles: "Not obvious to me how riff should highlight [a merge result against its
  parents], suggestions welcome!" then implemented per-parent max-merge (`Formatter::format`). No "prefer not",
  "by design", "won't". Our resolved rule reuses his own max-merge model.
- Base..main: base == origin/master (62ef8a7, 2026-08-15), no commits after.
- Branches: 79 upstream; every conflict branch (`johan/conflict-*`, `git-diff-conflict`, `diff3-base-minus`,
  `git-rebase-unmerged`) is raw-file or combined `++` form; the only unmerged one (`git-rebase-unmerged`, 1 commit)
  adds a combined-diff test file. `git log --all -S remerge` empty. Fork branches (hunt): none in lane.
- Siblings: delta `src/handlers/merge_conflict.rs` parses only `++<<<<<<<`; difftastic `conflicts.rs` parses raw
  files with markers; git-split-diffs, icdiff, ydiff, diff-so-fancy, diffr: shallow-cloned and grepped, no
  conflict-marker or remerge handling (ydiff's `=======` hits are svn log fixtures). Code search for
  `"remerge CONFLICT"` returns only git forks (the emitter). lazygit `mergeconflicts` = raw-file TUI resolver.
- Functional check 6: base renders `-<<<<<<<` / `+<<<<<<<` as ordinary removed/added lines; the second side of
  a conflict is never compared with anything (probes in `worktrees/_hunt/s_0923h26/riff_probe/`).

Verdict: exclusive, SIX-CHECK clean. Residual risk = rivals in the platform pipeline (Step 4b precheck).

## 0c. PICK-FILTER gates

1 BEHAVIORAL-F2P-GAP: PASS - base shows side 2 of a remerge region as plain removed lines, never compared with
the resolution; unresolved side 2 is plain green, never compared with side 1.
5 COLD: PASS - conflict lane last touched 2024-10-19 (1355279), raw/combined forms only; 12-month stream is the
hyperlink programme. Capability (one-column regions) never built.
6 REPRODUCE-ON-BASE: PASS (above).
7 DEDUP: 0 riff folders anywhere; no conflict-marker/remerge meta.md in problems/ rejected/ approved-problems/.
7b EXCLUSIVITY: PASS (0b).
8 DEFINED-BEHAVIOR: PASS - behaviour is defined by riff's own two models (raw `ConflictsHighlighter`:
side-vs-side and diff3 base rules; `Formatter::format`: a merge result max-merged against each parent) and by
git's marker grammar (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`, conflict-marker-size).
9 NO-FLAKY: 62 tests x3 identical (1.5 s each).
10 QUOTA: 0 of ours; niche 527-star repo.

## 0d. Stage 6 guard #2 - why this is more than a single-pipeline uniform wrap

The pre-pick risk was "one pipeline, one transform". It does not hold, for three reasons that survive full
specification:

1. **There is no single local rule.** A region line's meaning depends on three things at once: its diff prefix,
   the zone it sits in, and the region's polarity. A context line inside a resolved side belongs to that side AND
   to the resolution (two roles), a removed line belongs to one side, an added line to the resolution, and in an
   unresolved region the same removed line belongs to nothing. Each role set feeds a different text, the texts
   feed four different comparison kernels (resolved 2-way, resolved diff3, unresolved 2-way, unresolved diff3),
   and the per-line output must then be reassembled from several token streams in input order. A local fix to
   the role table changes every kernel's input at once.
2. **The region's lifetime is not the hunk's.** A region can open in one hunk and close in a later one. The
   hunk highlighter that saw the opening marker ends (its line counts run out) while the region is still open,
   so the open region must be handed to `FileHighlighter`, adopted by the next `HunkLinesHighlighter`, and the
   next hunk header must be emitted INSIDE the region's deferred output, or it prints above lines of the
   previous hunk. That is a second component and a second state machine (hunk line counting, `RejectedDone`
   hand-over, EOF and next-file flush). An agent who fixes the carry but not the flush drops or duplicates
   lines at EOF or at the next `diff --git`.
3. **The failure path is a baseline-preservation wall through the same chokepoint.** A candidate region that
   turns out incomplete or out of order must render byte-for-byte as base, including a hunk header it
   swallowed, a run that started before the opening marker, and `\ No newline at end of file` lines (which
   base feeds into `PlusMinusLinesHighlighter` so the `⏎` lands on the right line). This is the opposite
   pressure to (1) and (2): the region machinery must absorb lines early, and the fallback must un-absorb them
   exactly. The spike got this wrong for NNAEOF (it printed the nnaeof line verbatim instead of replaying it),
   which is the kind of mistake the tests are built to catch.

## 1. Title

Add conflict region highlighting to one-column unified diffs

## 2. Shape

- Shape: O-Composite-add (new capability spanning the hunk router, file lifecycle, block highlighter and
  refinement kernels). Mars analogue D-new.
- Pass target: 20-35%.
- Best agent: Orion (long-horizon, commits to an architecture).
- Dominant verdict predicted: MISSED_REQUIREMENT (role attribution) + REGRESSION (fallback / ordering).

## 3. Public surface (behavioural; no new Rust API is tested)

- The `riff` binary, fed a unified diff on stdin with `--color=on`.
- Conflict markers: opening `<<<<<<<`, base `|||||||`, separator `=======`, closing `>>>>>>>` (length N >= 7,
  optional ` label` except the separator, which is bare).
- Region polarities: resolved (markers on removed lines), unresolved (markers on added lines).
- Output contract: text of every line unchanged and in input order; refined parts in reverse video; marker
  lines in reverse video after the prefix; a failed candidate rendered exactly as base.

## 4. Canonical rules

- A region starts at the block (run of removed then added lines) holding an opening marker and ends with the
  block holding its closing marker. Lines between hunks that the diff does not show are simply absent.
- Markers are only lines with the opening marker's diff prefix and exactly its length; any other line (other
  prefix, other length, context line) is content.
- Order: open, optional base, separator, close. Anything else, or a candidate still open when the file's diff
  ends, renders exactly as today.
- Resolved roles: removed and context lines between markers -> that side (or base); added and context lines in
  the region -> resolution. Context lines render plain.
- Unresolved roles: added and context lines between markers -> that side (or base); removed lines -> none.
- Resolved comparison: each side and the base vs the resolution (whole texts, riff's refiner); resolution part
  highlighted when highlighted against at least one side.
- Unresolved comparison: no base lines -> side 1 vs side 2; base lines -> each side vs base, base highlighted
  where removed by either side, only the other side's removals when one side is empty (the raw
  `ConflictsHighlighter` rule).
- Lines with no role (removed lines of an unresolved region, lines before the opening marker or after the
  closing marker that are not resolution) render like an unpaired removed/added line (no refinement).
- Empty input sides compare as a single empty line (riff's existing convention).

## 5. Blind-spot pre-empts

- Pipeline placement / adjacent-vs-all: "a region can continue across hunks; a hunk header inside it stays in its
  place".
- Compound order preservation: the text of every line and the line order are unchanged.
- Falsy-on-invalid: "an incomplete or out-of-order marker set is shown exactly as riff shows it today".

## 6. Description draft

See `meta.md` (draft, ~330 words). Every rule in section 4 has one sentence; no instance lists.

## 7. File footprint (measured on the reference, hook 2026-09-23)

| Action | Path | Raw | Human-eff | Reason |
|---|---|---|---|---|
| NEW | src/unified_conflicts_highlighter.rs | 549 | 383 | marker grammar, zone machine, roles, 4 kernels, row reassembly, base replay |
| MOD | src/hunk_highlighter.rs | 61 | 43 | block tracking, region intercept, hunk-end flush, adopt |
| MOD | src/file_highlighter.rs | 16 | 11 | carry an open region across hunks, flush at next file / EOF |
| MOD | src/lines_highlighter.rs | 5 | 3 | trait hook to hand an open region upward |
| MOD | src/refiner.rs | 8 | 4 | Formatter line-style accessors |
| MOD | src/main.rs | 1 | 1 | mod |
| TOTAL | 6 files | 640 | **445** | |

Leanest plausible passer ~280-330 (integers for enums, fallback reusing a shared replay).

## 8. Solution outline

`UnifiedConflictsHighlighter` (new `LinesHighlighter`): `from_block(block_lines, marker_line)`, `marker_kind`
(prefix + length filter), `advance_zone` (transition table; close always ends), `roles_of(raw, zone)`,
`collect_text(role)`, `attribute_resolved` / `attribute_unresolved` (kernels over `refiner::diff` +
`max_merge`), `split_rows` + `RoleCursors` (per-role row cursors), `render_region_line`,
`render_as_plain_diff` (base replay through `PlusMinusLinesHighlighter`, including `\` lines and swallowed
hunk headers). Hunk router: `block_lines`, intercept before the PlusMinus path (drain a finished `+` run first),
flush complete regions at hunk end, `take_open_region` / `adopt_region`. File: `pending_region`, flush at a
non-hunk line and at EOF.

## 9. Test outline

`tests/conflict_regions_<hex>.rs`, integration, runs the binary. Helpers: `riff(input)`, an SGR parser that
turns each output line into `text` + inverse spans (bracket notation, prefix excluded) + an "unstyled" flag +
a full appearance model (fg, bg, weight, inverse per character) for base-equality checks. Every test asserts the
visible text of every output line equals the input line (order), then the bracketed spans line by line.
Fallback cells compare appearance with base output captured from the base binary, and always sit in the same
input as a valid region so the test fails on base.

Buckets (slice first, FINISH adds the rest): resolved 2-way / diff3 / kept context / trailing resolution /
empty resolution; unresolved 2-way / diff3 / empty side / removed line inside; cross-hunk (open in hunk 1,
separator and close later; second region in the later hunk); fallback (out of order, incomplete at EOF,
incomplete before next file, carried across hunks with NNAEOF); marker grammar (length 9 with 7-char content,
label forms, bare separator only, other-prefix marker text as content); run before the opening marker
(drained `+` run vs same run); NNAEOF inside a resolved region; two regions in one hunk.

## 10. Forced bounds

None in the test API (process-level). `#![deny(warnings)]` forces warning-free code.

## 11. Trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Context line has two roles in a resolved region | candidate (F-10 composition of two role rules) | S2 | role attribution | #2 (both define the resolution text) | resolution = "the + lines" is the natural reading; the miss shows on side 2's row, not on the context line | "the resolution is every added and context line of the region" beside "each side is the removed and context lines between its markers" | resolved_kept_line_counts_for_side_and_resolution |
| 2 | Region extent = whole blocks, incl. trailing + after the closing marker and the run before the opening marker | F-13 / L24 (format-noun extent) | A8 | region extent | #1, #4 | ending at `>>>>>>>` leaves an empty resolution; starting at the marker leaves the pre-marker run refined against the resolution | "starts at the block holding an opening marker and ends with the block holding its closing marker" | resolution_after_closing_marker; run_before_opening_marker |
| 3 | Cross-hunk lifetime + header order | F-9 family (state dropped between stages) | S4 | lifecycle / ordering | #4 | per-hunk highlighter ends; header printed first or region flushed at hunk end | "a region can continue across hunks, and a hunk header inside it stays in its place" | region_continues_across_hunks |
| 4 | Fallback exactly as today (replay incl. NNAEOF and swallowed header) | S3 baseline preservation | S3 | preservation | #2, #3 | re-rendering "plain" instead of replaying the real block logic; NNAEOF printed verbatim | "is shown exactly as riff shows it today" | fallback cells (appearance vs base) |
| 5 | Marker grammar: only same prefix + same length are markers | F-18 (two spellings of one concept) | A-tier lexical | lexical | #4 (a mis-parsed marker makes a valid set look invalid) | `starts_with("=======")` matches 9-char markers and 8-char content | "lines with a different prefix or number of marker characters are ordinary content" | long_markers_with_short_marker_content |
| 6 | Unresolved diff3 empty-side rule | A3 (reuse the raw highlighter's rule) | A3 | kernel choice | - | copying 2-way code; forgetting the empty-side exception | stated | unresolved_diff3_empty_side |

## 11b. Cross-product matrix (F-10)

| | one hunk | across hunks | fallback |
|---|---|---|---|
| resolved 2-way | slice | FINISH | FINISH (out of order) |
| resolved diff3 | slice | FINISH | FINISH |
| unresolved 2-way | slice | slice (FINISH adds) | FINISH (incomplete at EOF) |
| unresolved diff3 | slice | FINISH | FINISH |

Off-diagonal: resolved x cross-hunk x kept context in the later hunk (both #1 and #3); unresolved x removed line
inside a side; fallback x cross-hunk x NNAEOF.

Format-noun audit (L24): "block" = run of removed lines followed by added lines (stated); "region" extent stated;
"side" = lines between markers (stated). Example audit (L21): no examples appended to rules. Enumeration audit
(L81): marker kinds listed completely (four).

## 12. Tier + category

Olympus, feature-request ("Add ...").

## 13. Predicted pass rate

20-35%. Fully stated rules get transcribed (L1); band comes from composition (#1 x #2 x #3) and exact fallback (#4).
Risk: an agent who reuses `Formatter::format` for the resolved 2-way case and a single state machine inside the
hunk router could clear most cells; the cross-hunk and fallback cells are where that architecture breaks.

## 14. Quality gates

- [x] Phase 1 5/5 - [x] Phase 2 clean (commands above) - [x] closest approved opened (gluon-format-comments,
  pulldown-cmark-gfm-autolinks) - [x] title verb-led - [x] canonical rules - [x] <=1 codebase-inferable
  requirement (riff's refinement itself) - [x] footprint measured (445 human-eff, 6 files) - [x] traps on
  different axes, #1-#4 interdependent - [x] F-10 matrix - [x] test fairness: no colour pins, spans only, base
  appearance only for "exactly as today" - [x] flakiness: deterministic, offline, no timing.

Why not a duplicate: closest approved are gluon-format-comments (formatter preserving comments) and
pulldown-cmark-gfm-autolinks (inline parser); neither is a streaming diff renderer. No riff submission exists
in our dirs. Predicted iteration cycles: 2.
