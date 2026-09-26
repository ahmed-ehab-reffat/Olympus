# DESIGN.md - grmtools-contextual-lexeme-readings

Repo softdevteam/grmtools @ 8ce095a386c84392bf6d7bf98bf813d06c87b708 (master HEAD on 2026-09-26).
Source: hunt RANK 1 of `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-24-B.md` (W3 spike, 362 human-eff).

## 0. Phase 1 - repo understanding

**Architecture.** grmtools is an LR parser generator in five crates. `cfgrammar` reads Yacc/Lex
grammar text into a `GrammarAST` (parser.rs, ast.rs: directive parsing, validation, unused-symbol
warnings) and freezes it into an indexed `YaccGrammar` (grammar.rs, derive-serialised with wincode
for compile-time parsers). `lrtable` builds the LR(1) state graph and merges states with Pager's
weak-compatibility method, then packs the action/goto tables. `lrpar` runs the tables: `Parser::lr`
is the main loop, `lr_upto` and `lr_cactus` are the two error-free sub-parsers that CPCT+ recovery
(cpctplus.rs) uses to explore (`lr_cactus`, over a cactus stack), rank (`lr_upto` in `rank_cnds`)
and replay (`apply_repairs`) repair sequences. `lrlex` is the regex lexer; lrpar pre-reads every
lexeme before parsing starts (`Parser.lexemes`), so nothing outside the parser can change a lexeme
once parsing has begun. `nimbleparse` is the CLI.

**Five subsystems and boundaries.** (1) cfgrammar yacc reader/validator -> `GrammarAST`;
(2) cfgrammar `YaccGrammar` (indexed, serialised) -> consumed by lrtable, lrpar, codegen;
(3) lrtable state graph + Pager merging + `StateTable`; (4) lrpar runtime loops (`lr`, `lr_upto`,
`lr_cactus`); (5) lrpar CPCT+ recovery (Dijkstra search over `PathFNode`s, `collect_repairs`,
`rank_cnds`, `simplify_repairs`, `apply_repairs`). Plus lrpar codegen/ctbuilder (compile-time path)
and lrlex.

**High-entanglement zones.** (a) The three parse loops in parser.rs: every lookahead decision is
duplicated in `lr`, `lr_upto` and `lr_cactus`, and CPCT+ reaches the grammar only through the latter
two. (b) CPCT+ node identity: `PathFNode` hash/eq on (pstack, laidx) plus the Delete/Shift merge
rules; any new position dimension must enter the identity or nodes merge wrongly. (c) The repair
pipeline `collect_repairs` -> `repair_to_parse_repair` -> `rank_cnds` -> `apply_repairs`, where
positions are whole-lexeme indices in four places.

**Test framework.** cargo test. Unit tests live in `#[cfg(test)] mod test` inside the source files
(parser.rs `do_parse`, cpctplus.rs `check_all_repairs`), compile-time parsers in `lrpar/cttests`.
New integration tests go in their own cargo test target; template: the approved
grmtools-parameterized-rules `lrlex/tests/params_parse_d799b2.rs` (lrlex lexer + `lrtable::from_yacc`
+ `RTParserBuilder`), which needs `lrtable` as an lrlex dev-dependency. Formatting template for
recovery assertions: `lrpar/src/lib/cpctplus.rs` `test::corchuelo_example` (order-insensitive set of
repair sequences).

## 1. Title

Add context-dependent token readings to lrpar parsers

## 2. Shape classification

- Shape: O-Pipeline-hard (a new lookahead-reading kernel threaded through every parse loop and the
  CPCT+ repair pipeline, plus a new sub-lexeme position model inside recovery).
- Pass-rate target: <= 40% ceiling, designed toward 10-30%.
- Best agent: Orion / Vega (long horizon; the kernel must reach three loops and five recovery sites).
- Dominant verdict predicted: MISSED_REQUIREMENT (recovery sites) and INTEGRATION_ERROR
  (PathFNode identity, mid-lexeme resume).

## 3. Public API surface

No new Rust API is asserted by the tests. Everything is observable through grammar text and the
existing public API (`YaccGrammar::new`, `Spanned::spans/spanskind`, `ASTWithValidityInfo::warnings`,
`RTParserBuilder::parse_map`, `ParseError::lexeme/repairs`). New grammar surface:
- `%fallback T A B ...` - each of A, B may be read as T.
- `%split S P1 P2 ...` - S may be read as P1 P2 ... (>= 2 pieces spelling S's name).
The reference adds `YaccGrammar::token_fallback` / `token_split` and three error kinds
(`DuplicateReinterpretation`, `InvalidFallback(String)`, `InvalidSplit(String)`), none of which the
tests name, so no compile-wipe exposure (L72/C-5).

## 4. Canonical output form

- Parse trees: a fallback-read lexeme is a terminal with the fallback token id and its original span;
  a split lexeme is one terminal per piece, each with its piece token and sub-span (piece i covers
  `len(name_i)` characters in order).
- Repairs: a piece repair is `Delete`/`Shift` of the piece lexeme (piece token, sub-span); whole-lexeme
  repairs keep the lexed token. Tests compare repair sequences as an order-insensitive SET (CPCT+
  equal-rank order is HashSet-dependent), and only assert trees where the first-ranked repair is
  unique by length.
- Grammar errors: asserted by (span texts, SpansKind) only - never by message text or kind name.
- Warnings: the set of unused-token span texts.

## 5. Blind-spot pre-empts

- pipeline-placement: "reads every lexeme the same way while it searches for, ranks and applies
  repairs" (the three recovery phases are named, the three loops are not).
- rule-resolution: "decides ... from its configuration at the moment the lexeme becomes the
  lookahead, before any reduction the lexeme would trigger".
- falsy-on-invalid: "A lexeme no reading fits keeps its own token and is a syntax error at that
  lexeme."

## 6. Description draft

See `meta.md` (about 400 words). Every clause maps to a test in section 9 / feedback.md.

## 7. File footprint (measured on the reference, hook `effective_loc_check.py`)

| Action | Path | Raw | Human-eff | Reason |
|---|---|---|---|---|
| MODIFY | cfgrammar/src/lib/yacc/parser.rs | +75 | 61 | directive parsing, error kinds, duplicate tracking |
| MODIFY | cfgrammar/src/lib/yacc/ast.rs | +51 | 35 | validation, unused-token accounting |
| MODIFY | cfgrammar/src/lib/yacc/grammar.rs | +29 | 15 | indexed fallback/split tables + accessors |
| MODIFY | lrpar/src/lib/parser.rs | +179 | 128 | `reading` kernel, `can_shift_all`, piece helpers, three loop hooks, main-loop piece state |
| MODIFY | lrpar/src/lib/cpctplus.rs | +145 | 123 | piece dimension in PathFNode, piecewise delete/shift, repair conversion, apply/rank |

TOTAL 479 raw / **362 human-effective** across 5 files in 2 crates (floor 200, >= 2 files).
Honest net about 325 (30-35 cpctplus lines are signature/tuple plumbing). Atomic-only (no piece
recovery) measured 190 in the hunt spike, which is why piece-level recovery is in scope.

## 8. Solution outline (helpers, one per behaviour)

- `YaccParser` `%fallback` / `%split` arms + `add_reinterpreted_token` <- declaration syntax, one
  declaration per token (duplication error with both spans).
- `GrammarAST::complete_and_validate` fallback/split checks <- target/piece must be a token, target
  not itself declared, >= 2 pieces spelling the name.
- `unused_symbols` reachability extension <- "counts as used exactly when its target or every piece is used".
- `YaccGrammar::token_fallback` / `token_split` <- indexed lookup for the runtime.
- `Parser::can_shift_all(pstack, tidxs)` <- "can shift from that configuration" (simulate reductions
  on a copy of the stack, no actions).
- `Parser::reading(laidx, pstack)` -> `AsLexed | Replaced(lexemes) | Unreadable` <- the reading rule
  (lexed, else fallback, else all pieces).
- `split_pieces` / `next_piece` / `lexeme_at` / `piece_lexeme` <- piece spans and sub-lexeme positions.
- Hooks in `lr`, `lr_upto`, `lr_cactus` <- "reads every lexeme the same way while it searches for,
  ranks and applies repairs".
- CPCT+: `PathFNode.piece` in hash/eq, `piecewise`, `DeletePiece`/`ShiftPiece`,
  `repair_to_parse_repair`, `apply_repairs`, `rank_cnds` finishing the lexeme <- piece recovery rules.

## 9. Test file outline

`lrlex/tests/readings_0638b7.rs` (+ `lrtable` dev-dependency in lrlex/Cargo.toml).
- Block 2 builders: `grammar`, `grammar_errors`, `run(lex, grm, input, RecoveryKind)`, `parses`.
- Block 3 renderers: tree `Rule(tok=text ...)`, repairs `insert T` / `delete text@pos` / `shift text@pos`
  as a BTreeSet.
- Buckets (SLICE, 15 tests): declarations accepted; fallback read / not read / not re-read after a
  later failure; merged-state decision (T1); split read / kept as lexed; no-recovery error lexeme;
  recovery consistency (T2); piece recovery (T3/T4); validation spans (unknown target, duplicate,
  bad spelling); unused-token accounting.
- FINISH adds the section 11b cells, more validation cells, action/lexeme cells and base-mode guards.

## 10. Forced bounds

None new. Tests use `parse_map` with closures over existing public types.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| T1 | Reading decided from the current state's action (lemon rule) instead of the configuration; Pager-merged states reduce spuriously first | F-8 (lemon `%fallback` name) + F-1 (merging destroys per-context lookahead) | S6 (analyser vs table) / A8 | decision point (when) | T2 (same kernel feeds recovery) | lemon semantics is the retrieved prior; canonical-looking test grammars never merge | "before any reduction the lexeme would trigger" | `the_reading_is_decided_before_the_lexeme_triggers_a_reduction` (M1 measured: error ON the fallback token) |
| T2 | Reading applied only in `lr`; CPCT+ explores/ranks/replays through `lr_cactus`/`lr_upto` with raw lexemes | F-9 (stage drop), F-20 (lr_upto shared by rank and apply) | S5 dual-path | site coverage (where) | T1, T3 | the main loop is where the feature "obviously" lives; the failure shows as bloated repair sets | "reads every lexeme the same way while it searches for, ranks and applies repairs" | `recovery_reads_a_later_split_lexeme_as_its_pieces` (M2 measured: 6 bloated sequences) |
| T3 | Piece position 0 ambiguous between whole lexeme and first piece; mid-lexeme resume after recovery | new (candidate), A9 exact-fit index | S4 | position model | T2, T4 | agents keep whole-lexeme `laidx` everywhere | "recovery repairs it one piece at a time ... carries on from the next piece" | `recovery_repairs_a_split_lexeme_one_piece_at_a_time` (M3 measured: `insert >, delete >>@3`) |
| T4 | Piecewise mode entered for readable split lexemes too, so PathFNodes with the same position stop merging (duplicate candidates) | new (candidate) | S2 | mode gate | T3 | "split lexemes are repaired by pieces" read as always | "When the lexeme at an error is a split token that no reading fits" | FINISH cell: readable split after an error (repair set unchanged vs atomic) |

## 11b. Capability cross-product matrix (F-10)

Axes: reading kind {fallback, split} x phase {main loop, recovery search/rank/apply} x table
{canonical-equivalent state, Pager-merged state} x lexeme mode {atomic, piecewise}.

| | main loop | recovery (search/rank/apply) |
|---|---|---|
| fallback, plain state | `a_keyword_is_read_...` (slice) | FINISH: a keyword read as id inside the repair lookahead |
| fallback, merged state | `the_reading_is_decided_before...` (slice) | FINISH: merged-state fallback after an earlier error |
| split, plain state | `a_split_lexeme_closes_...` (slice) | `recovery_reads_a_later_split_...` (slice) |
| split, merged state | FINISH: generics grammar with a merged `>` state | FINISH |
| split, piecewise | n/a (main loop never enters piece mode itself) | `recovery_repairs_..._one_piece_at_a_time` (slice); FINISH: insert inside a lexeme, error after resuming mid-lexeme, piece cost via `term_costs` |

Scope audit: "can shift" is scoped to the configuration where the lexeme became the lookahead (not
the post-reduction state). Format-noun audit: "lexeme", "piece", "declared token", "target" each
defined in meta.md. Tolerance fixtures: n/a.

## 12. Tier + category

Olympus, category feature-request (title verb Add).

## 13. Predicted pass rate

20-35%. Reasoning: T1 softens once its sentence is written (hunt note), T2 and T3/T4 survive full
spelling-out because the fix sites are the recovery machinery the agent has to discover. Risk of
over-shooting to 0% from the piece-model burden; FINISH keeps piece cells to the stated rules.

## 14. Quality-gate checklist (SLICE state)

- [x] Repo understanding 5/5 (section 0)
- [x] Existing PR / publicly-solved check: see "Scope-lock gates" below
- [x] Closest approved problem opened: approved-problems/grmtools-parameterized-rules
- [x] Title verb-led, names the subsystem
- [x] Public API: no new Rust names asserted
- [x] Canonical output form spelled out (section 4)
- [x] 0 codebase-inferable requirements (piece spans and repair naming stated)
- [x] Description <= 500 words, no headers
- [x] Footprint measured on real code: 362 human-eff, 5 files
- [x] Traps name F-ids, sit on different axes, interdependent (shared kernel)
- [x] Every trap reproduced with a mutant (M1-M3, eval-results.md)
- [ ] 11b off-diagonal cells (FINISH)
- [x] Float audit n/a; frequency words none; no unbounded promise (no iteration bound stated)
- [x] Enumeration audit: the three recovery phases are a complete list of the phases CPCT+ has

## Scope-lock gates (run 2026-09-26, before any new code)

- **Canonical org:** `gh api repos/softdevteam/grmtools -q .full_name` = softdevteam/grmtools (not moved).
- **Gate 1 behavioural F2P gap:** on base both directives are `UnknownDeclaration`; no grammar-level
  way exists to read a lexeme as another token (the hunt measured 7/7 probes failing on base; the 15
  slice tests all fail on base, see eval-results.md).
- **Gate 5 cold capability:** parser.rs/cpctplus.rs were touched in the last 12 months (ltratt's CR
  Shift 3 fix 2026-08-17, codegen/serialisation, clippy), but nothing touches lexeme reinterpretation.
  Open PR #667 is `%grmtools` section user entries (ast.rs +262, parser.rs header-type change only).
- **Gate 6 reproduce on base:** base rejects `%fallback` / `%split` with `Unknown declaration`.
- **Gate 7 dedup:** grep of problems/, rejected/, approved-problems/ for grmtools: only our approved
  grmtools-parameterized-rules (cfgrammar macro expansion; zero overlap with lrpar loops / CPCT+).
- **Gate 7b exclusivity PR-DIFF:** PR search in all states for fallback, split, split token, lexeme,
  `>>`, keyword identifier, context sensitive, ambiguity, push back, reinterpret, token alias,
  contextual keyword, soft keyword, generics, lexer parser: no PR implements lexeme reinterpretation
  (hits are the grmtools-section, codegen, start-states and error-reporting PRs). All branches of the
  canonical repo and of the 8 most recently pushed forks listed (ratmice, rbartlensky, hseg, avityuk,
  meithecatte, tamuratak, andypeng2015, ltratt): no fallback/split branch. `git log --all -S fallback`
  on cfgrammar/lrpar: no hit in the lane. GitHub code search `token_fallback` (Rust): unrelated repos.
- **Gate 8 defined behaviour / philosophy:** #612 (open, 2025-11): ltratt "I punted on it", lists
  workarounds "none of them ideal", and asks whether table compression affects lexer/parser
  interaction; rbartlensky notes lexemes are pre-read so no lexer-side hack works. #301 (closed
  2022, by its reporter): ltratt suggests the grammar-level `'>' '>'` workaround and calls its
  `> >` spacing leak "generally considered acceptable". Neither is a decline; the feature defines
  its own semantics (configuration-level decision, which answers the compression question) with
  lemon's `%fallback` as a sibling template. YELLOW-mitigated, recorded in feedback.md.
- **SIX-CHECK:** (1) literal names `%fallback`, `%split`, `token_fallback`: no PR/issue in the lane;
  (2) namespace terms above: none; (3) philosophy scan: no "prefer not to / by design / won't add"
  in #612 or #301; (4) closed-with-implemented: #301 closed with a workaround, not an implementation;
  (5) base..HEAD overlap: base IS master HEAD; (6) capability check: base rejects the directives.
- **Derivative distance from our approved grmtools-parameterized-rules:** different subsystem
  (cfgrammar reader macro expansion vs lrpar runtime + CPCT+), different trap class.

## Why this is not a duplicate

Closest approved: grmtools-parameterized-rules (same repo, grammar-reader expansion, no runtime
change). Closest trap-shape siblings: mwparserfromhell-site-aware-parsing (consuming runs from a
pre-segmented stream, F-36) and pulldown-cmark (F-1). This pick's core is a configuration-dependent
lookahead kernel inside an LR runtime plus a sub-lexeme position model in CPCT+ recovery, which none
of them has. Known collision risk: the lane answers open issue #612 and lemon's `%fallback` is an
outsider-nameable name; a sibling workspace once screened grmtools as "beacon-saturated" citing #612.
Only the platform precheck can see rival submissions (Step 4b).

Predicted iteration cycles: 3.
