NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

# grmtools-contextual-lexeme-readings - feedback

## Status (2026-09-26, SLICE-READY)

- Repo softdevteam/grmtools @ 8ce095a386c84392bf6d7bf98bf813d06c87b708 (master HEAD). Hunt RANK 1 of
  `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-24-B.md`; the W3 spike patch was re-applied as the
  reference core.
- Feature: `%fallback` / `%split` declarations; the parser reads a lexeme as lexed, as its fallback
  token, or as its pieces, decided from the configuration where it becomes the lookahead (before any
  reduction it triggers); CPCT+ recovery uses the same readings in search, ranking and replay, and
  repairs an unreadable split lexeme piece by piece.
- Slice: solution 362 human-effective (479 raw) over 5 files in 2 crates; 15 new tests; Dockerfile
  and test.sh validated in a Docker clean room. Not yet built: the section 11b cells and the other
  FINISH scope in DESIGN.md.
- Owed before FINISH: Requirement 0 (platform picker) and the core-slice precheck (Step 4b).

## Scope-lock gates

All run before new code; full record in DESIGN.md "Scope-lock gates". Summary: canonical org
unchanged; no PR in any state implements lexeme reinterpretation (15 feature-class searches, all
branches of the canonical repo and of the 8 most recently pushed forks listed); base rejects both
directives; lane capability cold (recent parser.rs/cpctplus.rs commits are CR Shift 3, codegen and
clippy); open PR #667 is unrelated (`%grmtools` user entries). Gate 8 YELLOW-mitigated: #612 (open)
has ltratt "punted on" lexer/parser interaction with "none of them ideal" workarounds; #301 (closed by
its reporter, 2022) has ltratt's grammar-level `'>' '>'` workaround. Neither declines the feature.

## Known risks (carried to the precheck)

- Collision: the lane answers open issue #612, and `%fallback` is lemon's name (outsider-nameable).
  A sibling workspace once screened grmtools as "beacon-saturated" citing #612 (noted in
  approved-problems/grmtools-parameterized-rules/feedback.md). Only the precheck can see rivals.
- T1 (decide before reductions) softens once its sentence is written; T2/T3 carry the band.
- CPCT+ equal-rank order is HashSet-dependent: tests compare repair SETS, and assert trees only where
  the first-ranked repair is unique by length.

## Decisions made unattended (conservative choice recorded)

1. Directive names kept as `%fallback` / `%split` (spike names). The hunt suggested considering a
   repo-specific name. Declined: the dedupe compares the implemented core, so a rename is the
   "rename the API surface" anti-pattern and would not change collision odds, while lemon's name is
   what makes lemon's current-state rule (the T1 wrong variant, measured) the retrieved prior (F-8).
   Revisit only if the precheck flags the name.
2. Tests assert grammar errors by span text and `SpansKind` only, never by error-kind name or message.
   The reference's three error kinds stay unnamed in meta.md, so there is no compile-wipe exposure (L72).
3. New tests live in `lrlex/tests/readings_0638b7.rs` with `lrtable` as an lrlex dev-dependency, the
   layout accepted on grmtools-parameterized-rules.
4. Base mode runs per package (`cfgrammar`, `lrtable`, `lrpar`, `lrlex` lib+bin, `lrpar-tests`,
   `nimbleparse`) so JUnit classnames carry the package: the single workspace run produced a duplicate
   id (`ctbuilder.test.test_invalid_identifier_in_derived_mod_name` exists in lrlex AND lrpar).
5. Base mode runs `cargo clean -p lrpar-tests` first. Measured in the clean room: with the image built
   at base, applying the solution left the cttests' generated parsers stale (lrpar's
   `VERGEN_BUILD_TIMESTAMP` cache key does not change when lrpar's sources change), and three cttests
   (`ast_modified`, `ast_unmodified`, `test_storaget`) panicked in `_reconstitute` with
   `Io(ReadSizeLimit(1))`, because the cached wincode blob predates the new `YaccGrammar` fields. With the
   clean, base mode reads 296/296 with and without the solution. Agents who add fields to
   `YaccGrammar` will see the same three failures in their own sandbox until they rebuild cttests;
   the grader does not (L63 family). No comment in test.sh explains it (Auto Review leak rule).
6. Doc comments on new functions and fields are kept (concise, repo style): grmtools doc-comments its
   functions and fields, and the accepted grmtools-parameterized-rules shipped 19 such lines.

## Attempt history

- 2026-09-26 SLICE: spike applied, 15 tests written, 3 trap mutants reproduced (eval-results.md),
  Dockerfile + test.sh validated as uid 1000 / 0 / 4242 with `--network none`, 3x flakiness identical.
- 2026-09-26 Solution Quality precheck FAIL (Comprehensiveness 1/3): fixed bare declared tokens,
  whole-lexeme delete at piece 0, zero-piece split at EOL; 12 tests added for those and all 8 coverage
  suggestions (27 total), mutant-checked, Docker clean room re-validated. Only test.patch and
  solution.patch changed, so meta.md / Dockerfile / base are untouched (re-eval eligible after a batch).
- 2026-09-26 Solution Quality precheck round 2 FAIL: last split piece took the lexeme remainder. Fixed
  (name-length pieces; wrong-length lexeme is not read as pieces and is repaired whole), meta.md got the
  matching two sentences, 6 tests added (33 total) incl. the 3 coverage suggestions. Clean room re-run.
