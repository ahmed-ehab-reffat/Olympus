# REPO-HUNT-2026-09-24-B (hunt #31, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0924h31/` (plus the three #30 spike
dirs under `s_0924h30/`, finished here).

## Standing inputs
- Hint from the orchestrator: hunter #30 (log `REPO-HUNT-2026-09-24.md`) was stopped mid-spike with no
  result. Finish its open spikes (asdf lane 1 lazy_tree pass-through, cartopy Z through
  project_geometry). urbansim coverage is DEAD structurally (spike 104 human-eff, memoize-and-gather
  ~20 lines), not re-audited. MACS is SLICING; 3DTilesRendererJS and asdf are its fallbacks.
  Paper eff-LOC sketches under-counted 40-65% twice, so spike before killing a lane on LOC.
- Excluded: every LEDGER row (19 repos incl. MACS SLICING), every `problems/` folder (bayesopt,
  hayro, pict, piscsi, ray-optics, riff, teavm).
- Requirement 0 (platform picker): cannot be checked here -> OWED on any candidate.
- Softening: misses=0, so the 2026-09-09-B rules apply as written and no star/issue window is widened.
  Relaxations taken: none.
- At most 3 workshop sub-agents, all finished before return.

## Stage 0-bis — proven pool
No new approvals outside the LEDGER since hunt #29 (pyocd, pyfakefs, csbindgen, siliconcompiler,
libspatialindex are all LEDGER rows = taken). Pool re-judged at subsystem level in hunts #23-#29
(J log table, P log Stage 0-bis). One pool repo carries a lane that was only ever sketched on paper:
**softdevteam/grmtools** (approved: grmtools-parameterized-rules, 1/6) `%fallback` + `%split` lexeme
reinterpretation, 09-23-L: guard Q1/Q2/Q3 all clean with a measured misdirecting trap on real Pager
tables, killed only on a ~240 paper sketch. Under the under-count lesson it gets a spike (below).

## Hunter #30 leftovers (found in `s_0924h30/`)
- `asdf_passthrough/` + prototype in `s_0923h28/asdf`: 173 human-eff (raw 205, 3 files), core
  kernel working (probe 1: base converter calls 5/5 and tag re-emitted at 1.1.0; prototype 0/0 and
  1.0.0 kept); probe 2 (aliases + masked arrays + views) fails on base AND prototype. Unfinished.
- `cartopy_z/` + `zlane/`: 78 human-eff (crs.py 58, trace.pyx 20) plus a post-pass experiment
  (`zlane_postpass.py`, naive planar vs geodesic nearest-segment Z recovery). Unfinished.
- `grmtools/` (s_0924h30): an UNLOGGED third spike, a streaming lexer for lrlex
  (`LRStreamingLexer`, push/finish, lazy-DFA dead-state release rule). Measured here: **283
  human-eff** (streaming.rs 214 new file, lexer.rs 65 refactor), padding-floor 43.
  **Verdict DEAD (guard Q3 + magnet), not re-spiked:** the capability is one new standalone module
  over the existing rule DFAs with a small refactor to share `state_matches`/`apply_target_state`
  (Q3 = yes: a new file with minimal wiring); the release rule ("pending while any rule's DFA is
  not dead") is one decision, so traps do not interlock (Q2); and `LexKind` has exactly one
  variant, `LRNonStreamingLexerKind`, with the book saying "Currently lrlex only supports a
  single" kind, an empty slot every author sees (derivative magnet). Maintainer PR #199 (2020)
  deliberately removed the "users can deal with streaming data" text and documented that grmtools
  does not support streaming lexers; lrpar's parser consumes a finished `NonStreamingLexer` anyway,
  so the released lexemes have no in-repo consumer.

## Workshop (3 spike sub-agents, SPIKE-RULES.md)
Launched in parallel: W1 asdf lane 1 completion, W2 cartopy Z completion (must resolve the Q2/Q4 +
post-pass guard failure, not only size), W3 grmtools `%fallback` + `%split` spike.

### W2 SciTools/cartopy — Z through project_geometry — DEAD (guard Q3, and far under the bar)
The #30 prototype was already complete for the lane's core (all 6 F2P probes pass: Point Z, cut
vertex Z at the antimeridian, geodesic-parameter Z over 16 inserted vertices, interpolated Z on
`_attach_lines_to_boundary` vertices, NaN on inverted-ring boundary vertices, 2D stays 2D; suite
869 passed / 8 skipped / 2 xfailed, no regressions). **Measured 78 human-eff** (crs.py 58,
trace.pyx 20; padding-floor 55), core ~45; unwritten remainder (mixed-dim multis,
GeometryCollection, Z on GEOS-inserted vertices) ~+30-50, so the complete lane is ~110-130. The paper
sketch (~150-200) was HIGH this time, not low.
**Post-pass kill:** a ~90-line `zlane_postpass_full.py` (project `force_2d(geom)` with the unmodified
2D code, inverse-map output vertices, locate on the source segment geodesically with a forward
cursor, interpolate Z; boundary vertices by ring path length or NaN) matches the reference on 60/60
random lines (3.6e-13) and 53/55 polygons (the two residues are round-off and a GEOS self-intersection
vertex where the reference itself is NaN). Output Z is a pure function of output XY plus the source,
so no fair Z rule defeats a post-pass. Guard: Q2 independent and self-revealing (shapely raises on
mixed 2D/3D), Q3 yes, Q4 #1 uniform wrap. Exclusivity was clean (PR #2647/#2658 diffs carry no Z
handling; 9 forks, none in the lane). Artifacts: `s_0924h30/zlane/` (final patch, postpass scripts,
fork list). Do not retry with another Z rule.

## Cached index + fresh sweep 1 (of 2): newly-in-band delta
Cached index: seen union rebuilt from every cached jsonl = 74,596 slugs (`s_0924h31/seen_union.txt`),
plus deadlist_v12/deadlist_all. Not re-triaged (09-23-K/O record it exhausted: ~95% coverage of any
500-6000 bin, the never-judged engine rows are GPU/ROS/LLVM stacks, spec matrices, catalogues, apps).
Delta sweep `s_0924h31/sweep_delta_h31.sh`: 7 languages x 4 low star slices (500-900) x 7 licences,
`pushed:>2026-08-20` (the repos that most plausibly crossed 500 since the band was built): 3627 rows,
3627 unique, **30 unseen, 20 non-junk, 0 engine-shaped** (sindresorhus micro-packages, AWS credential
tool, Tauri shell, Redis-on-Durable-Objects, test-case macro, tracing lib, ML model repos). Survivors: none.
The band is closed at the bottom edge too.

### W1 asdf-format/asdf — lazy_tree pass-through write — WEAK, near DEAD (measured 176, lane tops out ~180-210)
The prototype is now a complete, correct reference. **Measured 176 human-eff** (raw 214, padding-floor
148; `_pass_through.py` new 154, `_asdf.py` 16, `yamlutil.py` 6). Core ~140. A cross-file surface
was added and cost about 1 net line, so the lane has no headroom left. The only surface still in reach
is #1795 (info/search without conversion), which is a different lane and would make this a bundle. Paper said ~195/120,
so here the sketch was about RIGHT (the under-count law is not universal: it held for streaming/
multi-stage lanes riff and MACS, not for hook-in modules). Fixes over #30's prototype: `_serial_write`'s
`copy.copy(root)` converted every top-level child before the walker (misdirecting T1); the
converter-private-block policy (#1508) has to be decided on the raw tree at open time; forced
conversions and alias substitutions must be written back so `update()` does not leave stale `source`
indices. Full suite 2189 passed / 2 xfailed with and without it. 7 F2P probes in
`s_0924h30/asdf_passthrough/` (base: 5/5 converter calls, re-tag at 1.1.0, mask dropped; prototype
0/0, 1.0.0 kept). Pre-existing base bugs seen outside the lane: rewrite drops the mask of any
converted masked NDArrayType; `update(all_array_storage="inline")` with zero write blocks leaves
trailing bytes.
Guard: Q1 yes (make_write_block + renumber list feed write_to and update with opposite in-memory
`source` rules); Q2 yes, with coupled pairs T3-T4, T3-T5, T5-T6, T3-T7, T2-T6, and T1/T5/T7
misdirecting; Q3 mostly YES (one new module plus ~22 lines of wiring at 4 sites); Q4 #3 needs the
policy sentences (private blocks, version change, cross-file). Exclusivity clean (no lane PR, forks
clean, #2133/#1677 unrelated). Derivative: approved enmime-preserving-edits class. Dies on the
250/150 bar. Patch `s_0924h30/asdf_passthrough/asdf-lazy-passthrough-spike.patch`.

### W3 softdevteam/grmtools — `%fallback` + `%split` lexeme reinterpretation — SPIKE 362 human-eff (PASS)
Working reference (rustfmt'd, source only): **362 human-eff** (raw 479, 5 files, 3 crates):
cfgrammar ast 35 / grammar 15 / parser 61, lrpar parser.rs 128, cpctplus.rs 123. The padding-floor of 68
is an artefact, because it collapses every Rust function body. About 30-35 cpctplus lines are
signature/tuple plumbing, so the honest net is ~325. **Core ~175**: the reading kernel,
`can_shift_all`, split_pieces/next_piece, loop hooks, main-loop piece state, and the CPCT+ piecewise
delete/shift, `repair_to_parse_repair`, `apply_repairs`, `rank_cnds` finishing pieces, and Eq/merge.
**Correction to the 09-23-L paper sketch:** the ATOMIC-only design (split applies only if every piece
shifts) measures **190** because its "CPCT+ sites ~40" were fully absorbed. CPCT+ reaches the parse
loops through `lr_upto`/`lr_cactus`, so it needed zero changes. The lane clears the bar ONLY with
piece-level recovery in scope: pieces become individually shiftable or deletable when the whole
lexeme cannot be read, a piece's delete cost is its token's cost, repairs report the piece with its
sub-span, and parsing resumes mid-lexeme. So the paper sketch was wrong in both directions: the
atomic part was over-counted and the piece model was never sized.
Existing suites with the patch: cfgrammar 149, lrtable 21, lrpar lib 24, lrpar cttests 69 (with the
wincode codegen roundtrip), lrlex 33, 0 regressions. Probe output identical over 4 runs. Patches:
`s_0924h31/grm_fallback/grmtools-fallback-split-spike.patch` (full),
`...-ATOMIC-only.patch`, `...-probes.patch` + `reinterp_probe_grmfb.rs`. They apply on 8ce095a; the
clone was restored clean and the target dir deleted.
**F2P:** on base, all 7 probes fail with `Unknown declaration`. On the prototype: P1 `x id w y` on the
Pager-merged trap grammar parses via B; P2 `z id w` keeps w; P3 `a<b<c>>>>d` splits the first `>>`
and keeps the second as shift; P5 an earlier `,,` error followed by a `>>` tail gives 1 error and
the tail splits; P6 validation kinds and unused accounting work through fallback/split sources;
P7 piece-level recovery `a<b>>` gives 1 error `["D>", "S> D>"]`, where atomic gave `["I> D>>", ...]` at cost 2.
Measured wrong variants: naive lemon semantics (fallback only when the current state's action is
Error) gives `ERR err@2 ["Dw"]`, an error exactly ON the declared fallback token (misdirecting). A
main-loop-only fix gives 6 bloated repairs deleting `>>` on P5.

## Stage 6 — death-class guard on RANK 1 (softdevteam/grmtools, lexeme reinterpretation)
1. ONE shared kernel feeding several surfaces, where a local fix regresses another: **YES.**
   `Parser::reading` plus the piece helpers feed `lr` (actions), `lr_upto` (apply_repairs,
   rank_cnds), `lr_cactus` (the CPCT+ search) and piecewise CPCT+. Fixing only `lr` breaks P5 (6
   bloated repairs, measured).
2. Traps INTERDEPENDENT and MISDIRECTING: **YES.**
   - T1: decide before reductions on Pager-merged tables. The naive variant errors at the fallback token.
   - T2: recovery consistency. It shares T1's kernel, and one-site fixes diverge far from the cause.
   - T3: piece position 0 is ambiguous between "whole lexeme" and "first piece". The spike author hit it
     himself: a `D>>` repair plus a spurious EOF error.
   - T4: piecewise mode is entered only when the lexeme is Unreadable, otherwise non-merging duplicate
     nodes appear.
   - T3 and T4 exist only inside T2's path, and the main loop must resume mid-lexeme after recovery.
3. Standalone file / post-pass: **NO.** The reading depends on the parser configuration, and lrpar
   pre-reads all lexemes (rbartlensky in #612), so no lexer wrapper or post-pass can rewrite the stream.
4. TOO-EASY Pre-Pick Guard:
   - #1 not a uniform wrap: one hook at 3 loop sites, but the kernel and the piece model do not collapse.
   - #2 spans cfgrammar + lrpar/parser + cpctplus, with hidden walls (Pager merging, CPCT+ node identity).
   - #3 the delayed-error and piece-recovery rules must be STATED, while the fix stays hidden.
   - #4 partial port risk from lemon `%fallback`, but lemon's semantics ARE the T1 trap, and `%split`
     has no LR-generator port.
   - #5 T2/T3 survive full spelling-out; T1 weakens once its sentence is written (it nearly names the
     simulation).
Guard verdict: **PASS.** Moderate risks carried: the fairness load of the piece-recovery sentences,
T1 softening when stated, and CPCT+ equal-rank ordering (HashSet), which is non-deterministic. Tests must
assert error counts, spans, trees and first repairs only where the sequence lengths differ.

## Dossier — RANK 1
### softdevteam/grmtools — ★575 — RANK 1
- **URL:** https://github.com/softdevteam/grmtools (canonical; default branch `master`)
- **Language:** Rust 887 KB of 896 KB (Yacc/Lex/Shell fixtures). Pure Rust, no -sys crates in the lrpar/cfgrammar test path.
- **Domain:** LR parser generator. Grammar reader (cfgrammar), table builder with Pager merging
  (lrtable), runtime parse loops plus CPCT+ error recovery (lrpar).
- **License:** dual MIT / Apache-2.0 (COPYRIGHT, LICENSE-MIT and LICENSE-APACHE read; no GPL, LGPL or MPL
  text in the tree). GitHub reports NOASSERTION; our approved grmtools-parameterized-rules is precedent.
- **Last commit:** 2026-09-21 (#668). 180d stream: ratmice 50 / ltratt 26 (codegen module,
  grmtools-section values, multistart docs, CR Shift 3 fix). CI: buildbot `buildbot-build-script`
  success on master HEAD.
- **Open issues:** 21 (open_issues_count incl. PRs); 1 open PR (#667, ratmice, grmtools-section user
  entries, ast.rs +262 = merge churn in ast.rs, not in the lane).
- **Tests:** cargo unit + lrpar cttests (codegen roundtrip); behavioural via generic parse trees and
  repair lists. Deterministic in the spike (4 identical runs), but assert only order-stable CPCT+ output.
- **Docker:** Pattern A `olympus-base-rust` (the approved grmtools problem has a working Dockerfile to
  scaffold from). Scoped `cargo test -p cfgrammar -p lrpar`.
- **Capability-lane density:** there is no fix/ branch family and no AI marks in the lane. Other lanes
  are dead on file (09-23-L list; streaming lexer DEAD in this log).
- **Maintainer-welcomed:** #612 (open since 2025-11, "Ambiguities and how to handle them"). ltratt
  "punted on" lexer-parser interaction and suggested `>`-only tokens plus span checks. Not a refusal, so
  Gate 8 is clear; not a welcome either.
- **Self-collision:** approved grmtools-parameterized-rules is a grammar-reader macro expansion in the
  cfgrammar yacc parser. This lane's LOC lives in lrpar's runtime loops and CPCT+, and cfgrammar only gets
  directive parsing and validation. Different subsystem class.
- **Missing machinery (LOC carry):** no notion of a lexeme having more than one reading, and no
  sub-lexeme position anywhere. `next_tidx(laidx)` has no stack argument; CPCT+ nodes are keyed on
  whole-lexeme indices.
- **Trap seams:** F-1/F-9 (Pager merging destroys the per-context lookahead the rule needs),
  F-10 (form axes: fallback/split x main-loop/recovery x atomic/piecewise x merged/unmerged
  state), F-8 (lemon `%fallback` name vs the repo's configuration-level semantics), F-20 (lr_upto is
  shared by apply_repairs and rank_cnds).
- **Estimated complexity:** 362 human-eff measured (net ~325), core ~175, 5 files, 3 crates.
- **Risks:**
  - Outsider-nameable (lemon `%fallback`, the `>>` generics problem) = MEDIUM. Mitigate by leading
    with `%split` + piece recovery phrased on Pager/CPCT+, consider a repo-specific directive name, and
    re-run the PR-DIFF check at submit.
  - The pick answers open issue #612 (commented by the maintainer, so not the uncommented-magnet
    row). Record it in feedback.
  - Heavy description load for the piece-recovery rules. Stay near 0% only if every rule is stated.
  - CPCT+ equal-rank non-determinism must not enter the assertions.
  - Rebase churn from #667 in cfgrammar ast.rs.

## Result: CANDIDATE — softdevteam/grmtools
Fallbacks (both WEAK, neither clears 250/150 on its measured evidence): asdf-format/asdf (lazy_tree
pass-through write, measured 176 / ~140 complete; enmime class overlap) and NASA-AMMOS/3DTilesRendererJS
(3D Tiles 1.1 multiple contents, spike 133 / honest ~215/115, spec-named, #608 plan).
Dead this hunt: cartopy Z (78 measured, ~90-line exact post-pass), grmtools streaming lexer (Q3 +
LexKind slot magnet + #199), delta sweep (30 unseen, 0 engine-shaped).
Lesson: paper sketches are not biased in one direction. The earlier "under-count" law held for
streaming/multi-stage lanes (riff +80%, MACS +64%). Here it split: a hook-in module was estimated about
right (asdf 195 -> 176), a projection wrap was over-counted (cartopy 150-200 -> 78, and ~110-130
complete), and a parse-loop lane had its absorbed part over-counted (atomic 240 -> 190) while its
unsized second mechanism (piece-level recovery) carried it to 362. Spike, and size each MECHANISM separately.
Disk: / 12G free at the end. Build outputs are gone (grm target, cartopy build/.so), venv_cartopy (429M)
and venv_asdf (126M) are removed; clones are kept (s_0923h28/asdf with the prototype,
s_0924h30/cartopy_z with the prototype, s_0923h25/grmtools clean, s_0924h30/grmtools streaming spike).
