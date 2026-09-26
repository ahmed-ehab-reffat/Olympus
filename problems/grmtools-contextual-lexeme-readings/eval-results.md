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
