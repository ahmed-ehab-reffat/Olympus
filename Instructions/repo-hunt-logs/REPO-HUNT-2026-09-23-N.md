# REPO-HUNT 2026-09-23-N (hunter #27, CONSECUTIVE_MISSES=1)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=1 (< 2): no extra softening beyond the permanent
2026-09-09-B rules; no star/issue window widening. Standing rulings: AI root file = ranking penalty;
AI commits/trailers = lane-scoped (SKILL 2b softened). Mandatory fork-branch exclusivity scan and
vendored-licence read on every lane audit; L62 cold-build timing for any C++ engine.
LOC honesty: return only if honest total >= 250 human-eff AND difficulty-carrying core >= 150.

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Plan (hunt #26 hint): (a) SPIKE walles/riff (conflict regions in one-column unified diffs) by
prototyping the core in a scratch clone and measuring with `.claude/hooks/effective_loc_check.py`;
(b) only if the spike fails, an invented-lane workshop on NEW domain engines (max 3 concurrent
agents), seen-set `worktrees/_hunt/s_0923h24/allseen_k2.txt`.

Excluded: all LEDGER repos, repos judged in 09-23-C..M (riff allowed for the spike), luna.

Scratch: `worktrees/_hunt/s_0923h27/`.

## Stage 0-bis / cached index
Not re-derived: hunt #23 (J) re-judged the whole pool (0 viable of 9); hunt #24 (K) exhausted the
cached index (78,844-slug union, two fresh sweeps, 0 survivors); hunt #26 (M) exhausted every cached
fallback. Nothing approved since except LEDGER repos. Proceeding straight to the riff spike.

## (a) SPIKE: walles/riff, conflict regions in one-column unified diffs

Scratch clone `worktrees/_hunt/s_0923h27/riff-spike/` (copy of `f_term/riff` at 62ef8a7371a7 =
origin/master, unchanged since 08-15). Patch `s_0923h27/riff_spike_v1.patch`. target/ deleted after.

**What the spike implements (a complete working prototype, not a sketch):**
- `src/unified_conflicts_highlighter.rs` (new, 542 raw): marker parse (length >= 7, same-length
  pairing, `=======` bare), zone state machine Before/Side1/Base/Side2/After with transition
  validation, region continues to the end of the -/+ block holding the closing marker, role
  assignment per line (resolved: `-` side lines -> that side, `+` -> resolution, context -> side AND
  resolution; unresolved: `+`/context by zone -> side, `-` -> plain old), attribution (resolved:
  diff(side_k, resolution) + max-merge on the resolution, base vs resolution; unresolved: two-way
  side1 vs side2, diff3 via base with max-merge, empty-side Context rule copied from the raw-file
  highlighter), per-role row cursors reassembling token rows in input order, marker line style,
  NNAEOF flag, fallback that replays invalid/incomplete sets through PlusMinusLinesHighlighter
  exactly as base renders them.
- Wiring: `hunk_highlighter.rs` (+60: region intercept before the PlusMinus path, block-line
  tracking, hunk-end handling, `adopt_region` that files the next hunk header INTO the region so
  output order is preserved), `file_highlighter.rs` (+16: carry an open region across the hunk
  boundary, flush it at a non-hunk line and at EOF), `lines_highlighter.rs` (trait hook
  `take_open_region`), `refiner.rs` (Formatter line-style accessors), `line_collector.rs`
  (`remerge CONFLICT ` header style), `main.rs` (mod).

**Behaviour checked on the hunt-26 probes:** remerge.txt (resolution line interleaved with kept
context: side1 vs resolution shows nothing missing, resolution highlights `compute2` vs side 2 and
`, c` vs side 1), remerge2.txt (trailing `+v = 23` after `->>>>>>>` joins the region; second hunk
region with the kept context `w = 3` as side1+resolution), remerge3.txt (diff3 base against the
resolution), plusside.txt (unresolved: `ours` context lines refined as side 1 against side 2), and a
synthetic CROSS-HUNK region (`xhunk.diff`: `-<<<<<<<` in hunk 1, `-=======`/`->>>>>>>` + `+tail = 1`
in hunk 2) renders in order with the second hunk header inside the region. Existing suite: 62 passed
x3 (incl. `test_testdata_examples`, 43 goldens), identical; zero warnings.

**Measured LOC (`.claude/hooks/effective_loc_check.py`):** raw 633, **human-effective 440**, 7 files
(new module 377, hunk_highlighter 43, file_highlighter 11, rest 9). padding-floor 56 (the hook
amortizes the repeated `Response {..}` returns and enum rows; ~30 lines are imports/derives/Response
boilerplate). Honest subtraction: minus ~30 boilerplate = ~410 for a complete implementation; the
fallback replay is ~45 of it. **Difficulty-carrying core** (zone machine + roles + attribution +
row reassembly + cross-hunk carry + ordering) ~250-300. **Leanest plausible passer** ~260-320
(integers for enums, terser fallback). Both numbers clear 250 / 150. Hunt #26's paper sketch (~245
/ ~200) UNDER-estimated by ~40%: it sized decision points but not the enum/role/cursor plumbing a
streaming highlighter needs.

## riff re-audit (2026-09-23, live)
- Stage 1: ★527 (margin 27, risk), MIT (LICENSE read; no vendored code: the only other
  licence/copyright hits are testdata diff CONTENT), Rust 97%, pushed 2026-08-15, 4 open issues,
  0 open PRs, 10 forks. Pure Rust, no -sys in [dependencies] or [dev-dependencies] (similar, regex,
  threadpool, clap, url, once_cell; dev: pretty_assertions, tempfile, base64). Cargo.lock pinned.
- Req 7: linux-ci.yml runs `./ci.sh` (clippy, `cargo test --workspace`, fmt check); last 8 master
  runs all `success` (Linux + Windows, 2026-08-15 and 2026-01-31).
- Req 0: OWED.
- Dedup/quota: 0 riff folders in approved-problems/, problems/, rejected/; not in SATURATED-REPOS
  or LEDGER.
- Exclusivity: PR+issue search (remerge, conflict, merge conflict, marker, resolution, git diff
  HEAD, diff3): only #56 (raw-file conflicts, closed 2024-01 by the implementation), #65 (--cc
  context, fixed), #63 (crash). No PR in lane, ever. `git log --all -S remerge` empty.
  **Fork-branch scan:** 10 forks, 78 upstream branches; non-upstream branches = just1602:patch-1
  (ahead 0), wezm:loongarch (packaging), 0x5c:dispatch (1 commit 2023, main.rs match dispatch),
  xeago:interactive (ahead 0). None in lane. `adx-labtesing-deepswe-forks.txt`: 0 riff lines.
  `sig_accounts.txt` (57): no fork owner or PR author listed.
- Siblings: delta `src/handlers/merge_conflict.rs` (fetched, 1352 lines) parses ONLY the combined
  `++<<<<<<<` / `++|||||||` / `++=======` / `++>>>>>>>` forms (riff already has those). Code search
  `"remerge CONFLICT"` (rust/go/python): only git reimplementations that EMIT it (gitbutlerapp/grit,
  HeddleCo/sley) and unrelated CI tools; no highlighter. diff-so-fancy / diffr: no conflict code.
  (Code-search limit hit for git-split-diffs/difftastic/icdiff/ydiff; the hunt-26 dossier's issue
  search there returned 0.)
- Stage 2c: 12-month stream is the hyperlink programme only (Oct 2025, Aug 2026). The conflict lane
  had a maintainer branch family in 2024 (`johan/conflict-markers`, `-context`, `-context-ii`,
  `-marker-styling`, `git-diff-conflict`, `diff3-base-minus`; last commit 1355279 2024-10-19), all
  raw-file or combined-diff forms, cold 23 months. RISK NOTE: the maintainer treats conflicts as
  his area; the one-column forms were never touched. 3 Aug-2026 commits say "Committed by Claude
  (Sonnet 5)" in the hyperlink lane (lane-scoped NOTE). No root AGENTS.md/CLAUDE.md.
- Stage 2d: no CHANGELOG; README has no "no longer/removed" record for conflicts; README TODO lists
  `git show --stat` and three-file `diff3` (not our lane; the latter is a public pick-list row for
  rivals, avoid it). Maintainer philosophy: #56 walles asked "Not obvious to me how riff should
  highlight [a merge result against two parents], suggestions welcome!" and later implemented
  combined-diff refinement with a per-parent max-merge; the resolved-region rule reuses exactly that
  model, so it extends his own semantics rather than contradicting them. #61 (side-by-side) and #70
  (word-diff) declined: our lane keeps the -/+ line format and line count (README TODO invariant).
- Stage 2b magnet test: outsider summary "highlight merge-conflict regions inside ordinary unified
  diffs (remerge-diff, git diff HEAD), refining each side against the resolution". Nameable git
  feature, but no issue asks for it, no support matrix, no TODO row, no sibling implements it;
  the attribution semantics are riff's own. MEDIUM: mitigate by phrasing meta.md on riff's model
  (regions, roles, resolution text) and the F-10 table.
- Determinism: 62 tests x3 identical (~1.5 s). Build 39 s debug (hunt 26).

## Stage 6 death-class guard (RANK 1 = riff conflict regions)
1. ONE kernel, several surfaces: YES. The region collector + role table + row reassembly feed
   resolved two-way, resolved diff3, unresolved two-way, unresolved diff3, cross-hunk and NNAEOF
   cells, and it sits in the same hunk router as ordinary -/+ refinement; the hunk-end/flush logic
   is shared with every non-region hunk (a region kept open at hunk end must be flushed at the next
   file header and at EOF, or it swallows or drops lines).
2. Interdependent traps: YES. (T1) context lines carry two roles; an agent that advances only the
   side cursor on a context line shifts every later resolution row, and the failing assertion lands
   on a DIFFERENT `+` line (misdirecting). (T2) the closing block's trailing `+` lines are the
   resolution in remerge output; ending the region at `>>>>>>>` refines both sides against an empty
   resolution. (T3) cross-hunk continuation: the region's output is deferred until close, so the next
   hunk header must be filed inside the region or it prints ABOVE lines of the previous hunk
   (ordering failure that reads as a formatting bug); this needs state carried through
   FileHighlighter, a second component. (T4) NNAEOF inside a region interacts with the refiner's
   `⏎` token insertion. T1<->T2 (both decide the resolution text), T3<->hunk flush (fixing the carry
   breaks EOF/next-file unless flushed).
3. Standalone file with minimal wiring: PARTIAL. The bulk is one new module, but it is not a
   post-pass: it must intercept the streaming hunk router ahead of the PlusMinus path and carry
   state across the hunk lifecycle (FileHighlighter), and the output order depends on the StringFuture
   deferral. Measured wiring: 60 raw in hunk_highlighter + 16 in file_highlighter.
4. Pre-pick guard: #1 no single guard at many sites; #2 RISK (one pipeline), mitigated by the
   cross-component hunk-lifecycle wall (T3) and the dual-role accounting (T1), both of which survive
   full specification; #3 no rule needs to stay unstated; #4 not a port (no tool implements it);
   #5 yes, T1/T3 survive being spelled out.
Verdict: PASSES the guard with a documented #2 risk. A smoke run (Query-13 sim) before authoring
proper is the right check for #2.

## Result: CANDIDATE walles/riff
Lane: conflict regions inside one-column unified diffs (resolved = remerge-diff markers on the `-`
side, each side refined against the resolution; unresolved = markers on the `+` side, sides refined
against each other), with cross-hunk continuation, dual-role context lines and base-identical
fallback. Spike measured 440 hook human-eff (~410 honest), core ~250-300, lean passer ~260-320.
Risks for the builder: ★527 (27 over the floor: re-check stars at submit); exact-ANSI golden
culture (assert per-line highlighted-token sets through an ANSI-parsing helper, or pin every style
in meta.md); single-pipeline guard #2 (smoke run); the maintainer owns the conflict area (dormant
since 2024-10). No fallbacks: every cached fallback was judged in 09-23-C..M and luna is excluded;
no workshop run because (a) succeeded.

## Budget spent
Pool and cached index not re-derived (J/K/M exhausted them). One prototype spike (1 cargo build,
3 test runs), live gate re-checks, one fork-branch scan, one sibling fetch (delta). No fresh niche
sweep, no workshop agents. Disk 15G free; spike target/ deleted; clone kept at
`worktrees/_hunt/s_0923h27/riff-spike` (17M) with the patch beside it.
