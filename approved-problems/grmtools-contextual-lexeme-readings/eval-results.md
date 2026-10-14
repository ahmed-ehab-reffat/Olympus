# grmtools-contextual-lexeme-readings — eval results

No platform batch yet. Local validation numbers are logged below as they are measured.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|

## Local measurements (SLICE, 2026-09-26, host cargo 1.98)
- Spike solution re-applied on 8ce095a: human-effective 362 (raw 479), 5 files in 2 crates (cfgrammar, lrpar).
- New tests `lrlex/tests/readings_0638b7.rs`: 15/15 pass with the solution, 3 host runs identical.
- Base mode (`cargo test --workspace --lib --bins`) with the solution: 296 passed / 0 failed
  (cfgrammar 149, lrpar lib 24, cttests 69, lrlex 33, lrtable 21), 21 s warm.
- Trap reproduction (mutants on the reference, each killed by exactly one test):
  - M1 lemon rule (reading decided from the current state's action only): kills
    `the_reading_is_decided_before_the_lexeme_triggers_a_reduction` (spurious error on the fallback token).
  - M2 reading only in the main loop (not in lr_upto / lr_cactus): kills
    `recovery_reads_a_later_split_lexeme_as_its_pieces` (6 bloated repair sequences deleting pieces).
  - M3 atomic split only (no piece-level recovery): kills
    `recovery_repairs_a_split_lexeme_one_piece_at_a_time` (repairs `insert >, delete >>@3`).

## Docker clean room (SLICE, 2026-09-26)
- Image `factory-grmtools-contextual-lexeme-readings` built from a pristine clone at base with no patch
  applied: cold `--no-cache` build 202 s (under the 600 s environment start).
- Order: apply test.patch, run base/new; apply solution.patch, run base/new. `--network none`.

| uid | base (no sol) | new (no sol) | base (sol) | new (sol) |
|---|---|---|---|---|
| 1000 | 296 pass / 0 fail | 15 fail / 15 | 296 / 0 | 15 pass / 0 |
| 0 | 296 / 0 | 15 fail / 15 | 296 / 0 | 15 / 0 |
| 4242 (unmapped) | 296 / 0 | 15 fail / 15 | 296 / 0 | 15 / 0 |

- JUnit: no duplicate (classname, name) pairs, no `::` in any id, in all four XMLs.
- New-mode compile-failure fallback (lrpar deliberately broken): 15 failing testcases with ids identical
  to the passing run, cargo's last 60 log lines in each failure body.
- Flakiness, uid 1000: base and new, each 3 runs without and 3 runs with the solution: identical
  per-test outcomes in all 12 runs.
- Patches: apply solution-then-test and reverse-apply cleanly; `file` reports ASCII; test.sh is
  `new file mode 100755`.

## Solution Quality precheck round (2026-09-26): FAIL -> fixed

Verdict FAIL (Comprehensiveness 1/3, Code Quality 3/3). Three defects fixed in solution.patch:
1. Bare `%fallback`/`%split` sources were not in `token_directives`, so `%fallback T A` + `S: A;`
   treated `A` as an unknown rule. Now `insert_full` + `token_directives.insert(idx)`.
2. CPCT+ `delete` still offered the whole-lexeme `Delete` at piece 0 of an unreadable split (cost 1 vs two
   piece deletes). Now returns right after `DeletePiece` whenever `piecewise(n)`.
3. `%split 'a'` then newline hit `ReachedEOL`. Now `parse_ws(j, true)` after the source, so validation
   reports the zero-piece split at the declared token.

12 new tests (27 total) cover the three defects and every coverage suggestion: bare names (grammar and
runtime), piecewise delete over whole delete, per-piece delete cost (default tie, then '>'=3 and '='=3),
unequal piece lengths (`'>>=' '>>' '='`), fallback read during CPCT+ search, zero/one-piece split,
self-target, target declared (by a later fallback, by a split), unknown piece at the piece, same-kind
duplicates (fallback/fallback, split/split), split usage (all pieces vs one unused). Grammar errors are
now asserted as `text@offset`.

Mutants (each killed by the intended test): whole-delete kept at piece 0; no token_directive; split
parse_ws(false); constant piece cost; split-token cost; no fallback in lr_cactus; no split usage; split
usage `any`; one-byte pieces; no arity check; no target-declared check; no duplicate check.
Survivor: dropping only `target == src` (self-target is still rejected by the target-declared check, so
the behavior stays pinned).

Docker clean room (fresh clone at base, `--network none`): new 27/27 fail without the solution and 27/27
pass with it as uid 1000, 0 and 4242; base 296/0 with and without the solution; new and base each 3 runs
identical. human-effective 363.

## Solution Quality precheck round 2 (2026-09-26): FAIL -> fixed

Verdict FAIL (Comprehensiveness 1/3, Code Quality 3/3). One defect: `split_pieces` gave the last piece the
lexeme remainder, so a named split (`%split AB A B`) over lexer text `xyz` read as `A@0..1 B@1..3`.
Fix: each piece takes its name's length; a lexeme whose length differs from the split token's name has
no pieces reading (reading() -> Unreadable, and CPCT+ repairs it whole because `piecewise` needs pieces).
meta.md: two sentences added (pieces only when exactly as long as the name of `S`; recovery repairs any
other lexeme whole). 500 words. Solver-visible change, so the first batch must run on this meta.

6 new tests (33 total): named pieces via actions, longer-than-name lexeme (no recovery: error at `xyz@0`
with token AB; CPCT+: `insert A, insert B, delete xyz@0`), three-piece split with unequal pieces through
actions and through recovery (`shift >>@5, delete >@7`), fallback lexeme through `parse_actions` (the
call generated parsers make) with exact spans, fallback no-fit keeps token `let`. The split no-fit test
also asserts the error token. Mutants killed: remainder-to-last, one-byte pieces, pair-only split,
fallback no-fit reported as its target.

Docker clean room (fresh base clone, `--network none`): new 33/33 fail without and pass with the
solution as uid 1000, 0 and 4242; base 296/0 with and without; 3 runs identical. human-effective 356.

## Batch 1 (2026-09-28): 0/25 (23 Nova, 1 Orion, 2 Vega; Nova #1 of one set produced no result)

All 25 graded runs failed; baseline passed in every run. Saved in `agent-runs/1/`. Local replay
(`worktrees/_grm_tools/replay.py`, saved solution patches + test.patch) reproduces the platform verdicts.

Per-test kills (33-test suite): reading-before-reduction 18; split closes two lists 16; split shiftable
as lexed 16; recovery reads later split 16; three-piece spans 13; unequal spans 13; piece cost 11;
cross-kind duplicate 10; empty split 8; one-piece split 7; the rest 1-6. No test killed nothing.

Diagnosis: one shared cause. 20 of 25 runs check only the CURRENT state's action (an immediate Shift)
when deciding a reading, so any token that first triggers a reduction is never read as its fallback or
pieces. That kills the headline `>>` example and 4-6 tests per run. Graders marked it "mentioned", but
20/25 reading "can shift it from that configuration" the same way is an ambiguity signal, not a trap.
Excluding those six reduction tests, Nova_3, Nova_22 and Orion have zero other failures.

Other kills checked by probe and all genuine bugs: Nova_11/20 pass the recovery stack top-first where
their reading check expects bottom-first (search reads the wrong state); empty split -> raw ReachedEOL;
one-piece split -> two errors or a broken span; duplicates -> parser breaks ("Unknown declaration"),
wrong span (a@20), or an extra second error.

## Auto Review (2026-09-28): Revision Requested. Description 3/3, Tests 2/3, Solution 1/3

Fixed:
- S1 (High): CPCT+ counted ShiftPiece toward PARSE_AT_LEAST; three shifted pieces "succeeded", the
  simplifier stripped them, replay restarted at (laidx, 0) and recovery looped (reference: 3357 errors on
  a four-piece split). `ends_with_parse_at_least_shifts` is back to base (whole shifts only).
- T8: build-failure fallback now embeds the whole cargo log (verified: broken lrpar -> 36 real ids, both
  root `error[E0308]` in the body).
- T4: split lexeme shorter than its name (`x` lexed as `AB`: no pieces; CPCT+ repairs it whole); CPCT+
  on a fallback lexeme no reading fits, costs let=1 id=3 ;=2 -> only `delete let@2` (kills the
  forced-target-cost mutant).
- Four-piece regression `recovery_carries_on_after_three_shifted_pieces`: asserts the tree, that every
  non-empty repair ends with `delete d@3`, and that none names `abcd`. First written as the reference's
  exact single-error shape, which killed 23/25 and also Nova_3/22/Orion, whose behaviour (an all-shift
  repair, then `delete d@3` at a second error) is spec-consistent. Relaxed version: 16 kills, all
  probed as real (11 loop with no tree, 4 reject a four-piece split, Nova_2 re-deletes consumed pieces).
  A tie case (`insert ;, insert if`) was dropped as an unintended extra requirement.

meta.md (solver-visible, so a FULL batch is needed, no re-eval): the reading paragraph now defines
"can be shifted" as shifted after the reductions the token triggers, noting a token whose table action
is a reduction may still be shiftable. 540 words.

Replay of batch-1 solutions on the new suite: 0/25 as expected (meta change not replayable); 3/25
(Nova_3, Nova_22, Orion) have no failures outside the reduction family. Docker clean room: new 36/36
fail without and pass with the solution as uid 1000/0/4242; base 296/0 with and without; 3 runs
identical. human-effective 354.

## Batch 2 (2026-09-28): 0/12 (9 Nova, 1 Orion, 2 Vega; Nova #10 produced no result)

Saved in `agent-runs/2/`. The reductions clarification worked: the reading-before-reduction test fell
from 18/25 kills to 1/12. New top killer: `recovery_carries_on_after_three_shifted_pieces` 9/12, the
ONLY failure for Nova_7 and Orion. Probed: Nova_7/Nova_9 loop (thousands of errors at abcd@0, no tree,
the S1 bug); Orion ends its first repair after two pieces (`shift a, shift b, delete c`) then needs
`insert c, delete d` at a second error; Nova_2 re-deletes pieces it already shifted. Nova_8/Nova_10 fail
the empty split with a raw ReachedEOL / empty span. All genuine, but the four-piece edge was never
stated in meta and carried most of the difficulty.

## Auto Review round 3 (2026-09-28): Revision Requested. Description 3/3, Tests 2/3, Solution 1/3

S1 (High): `split_pieces` used `String::len()` (bytes) where meta says characters; `%split 'éa' 'é' 'a'`
over input `aé` gave the first piece 0..2, inside `é`, and `span_str` panics. Fixed: walk the actual
lexeme's `char_indices` using each piece name's `chars().count()`; no pieces reading unless the lexeme
has exactly as many characters as the split token's name.

Test `split_pieces_are_counted_in_characters`: `aé` lexed as `'éa'` reads as `é@0..1 a@1..3` through
parse_map (span_str on every piece) and parse_actions; `abc` lexed as `'éa'` (same 3 bytes, 3 chars)
is not read as pieces. Kills the old byte reference and a char-walk-with-byte-total variant.

Four-piece test back to the exact result (one error at abcd@0, `shift a@0, shift b@1, shift c@2,
delete d@3`), because meta now states the rule. Kills the S1 mutant.

meta.md (full batch again), three sentences, 582 words:
- "a `%split` that names only `S` is invalid" (empty-split kills were ReachedEOL on an unstated case)
- "These lengths are counted in characters, not bytes."
- "A repair that works through a split lexeme piece by piece does not end until every one of its
  pieces has been shifted or deleted." (the four-piece edge that carried 9/12 kills)

Replay of batch-2 solutions on the new suite: Nova_7 and Orion fail only the four-piece test (now a
stated rule); the multibyte test kills only runs already failing 8+ tests. human-effective 365.

Docker clean room (round 3): new 37/37 fail without and pass with the solution as uid 1000/0/4242;
base 296/0 with and without; 3 runs identical; broken-lrpar fallback emits 37 real ids with both root
error[E0308] lines.

## Batch 3 (2026-09-29): 0/10 (9 Nova, 1 Vega; Nova #3 produced no result)

Saved in `agent-runs/3/`. Kills: piece cost 9, middle-piece 7, one-at-a-time 7, four-piece 6,
duplicates 6; the rest <= 5. Nova_1 fails ONLY the four-piece test, with a new variant: correct tree,
one error, but the repair reads `shift a@0, delete d@3` (the middle piece shifts go missing).
Across batches 2+3 the four-piece case is the sole failure of 3 runs (b2 Nova_7, b2 Orion, b3 Nova_1),
each failing it a different way (loop / early end / misreport). Three batches, 0/47.

## Solution Quality (2026-09-29): PASS (Comprehensiveness 3/3, Code Quality 2/3)

Medium: `ends_with_parse_at_least_shifts` did not count ShiftPiece while PathFNode::PartialEq did.
That asymmetry was the round-3 Auto Review S1 fix (counting ShiftPiece let three piece shifts end a
repair on a four-piece split and replay restarted at the whole lexeme).

## Cut (2026-09-29): a split has two or three pieces

meta.md: "A split has two or three pieces, so a `%split` that names only `S` or more than three pieces
is invalid"; the "repair ... does not end until every piece" sentence removed. 562 words.
With at most three pieces, three consecutive piece shifts from piece 0 mean the whole split was
readable, so a piecewise repair cannot end partway. ShiftPiece now counts in
`ends_with_parse_at_least_shifts` again (symmetric with PartialEq, answers the SQ Medium).
Test `recovery_carries_on_after_three_shifted_pieces` replaced by
`a_split_with_four_pieces_is_an_error_at_the_declared_token` (error at `abcd@28`). 37 tests.

Replay (saved solutions, new suite): batch 2 Nova_7 and Orion, batch 3 Nova_1 fail only the new
four-piece declaration test, which they could not know about: ~3/22 (14%) once the cap is implemented.
Docker clean room: new 37/37 fail without and pass with the solution as uid 1000/0/4242; base 296/0
with and without; 3 runs identical; compile-fail fallback carries both root errors. human-effective 367.

## Batch 4 (2026-09-30): 2/10 — ACCEPTED

All Nova. Passes: Nova #1 (dir Nova_Nova_10, +605 lines) and Nova #2 (dir Nova_Nova_9, +932 lines).
Near-miss Nova_2 36/37: `recovery_reads_a_later_keyword_as_its_fallback` only (recovery stack read
top-first, F-72). Nova_6 wiped (directives recognised for one YaccKind only). Per-test kills (wipeout
excluded): duplicates 5+5, target-declared 5, piece cost 5, piecewise delete 5 (most of the last two are
grammar rejections from unregistered declared names, F-71), 14/37 killed nothing incl. every
reduction-timing test. Final Auto Review asked for one more revision (reading not latched across
reductions in a reduce/reduce-conflicted table); accepted before it was addressed. Mined into
failure-patterns.md F-71/F-72, L111-L113, Pattern 112.
