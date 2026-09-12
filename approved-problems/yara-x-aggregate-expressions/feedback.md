# feedback.md — yara-x-aggregate-expressions

## Summary

- Repo: `VirusTotal/yara-x` (Rust, BSD-3-Clause, 1229 stars, last commit 2026-07-27).
- BASE_COMMIT: `aae0a1ea73e8bad84d9237cff2073351f2d2a88d`.
- Feature: aggregate expressions over iterables in rule conditions —
  `for count|sum|min|max|avg <var> in <iterable> : ( <body> )`, and over pattern sets.
- Shape: O-Composite-extend. Threads tokenizing decisions, parsing, CST, AST, IR construction,
  static typing, WebAssembly emission and the runtime.
- Size: 762 human-effective LOC (hook), 1168 raw added, 12 files across 3 crates.
- Tests: 81 (none naming an internal AST type), across `lib/tests/aggregate_685dcf.rs` (68), `cli/tests/deps_agg_685dcf.rs` (5)
  and `parser/tests/dfs_agg_685dcf.rs` (8).

## Status

Built and locally validated. First platform batch came back 0 of 6; the description was
corrected in response (see the batch section below). NOT yet re-run.

Done:
- All 10 pick gates (see DESIGN.md § 2). Exclusivity, dedup, coldness, license, flakiness, quota.
- F2P confirmed on base: `for count i in (0..4) : ( i > 1 ) > 1` is `error[E001]: syntax error`.
- Reference implementation complete; `cargo test --workspace` is green (21 result groups, 0 failures).
- `./test.sh new` = 81 tests / 0 failures. `./test.sh base` = 364 tests / 0 failures.
- 4-cell run on a fresh BASE checkout: base+new = 81 of 81 fail; everything else green.
- AI pre-checks rounds 1-27 cleared. Coverage advisories addressed throughout; 1 reverted on a
  scored check (round 7), 1 accepted only in part because pinning it would be unfair (round 12),
  1 declined twice on a scored-check precedent (rounds 24 and 27).
- Platform Verify Solution FAIL on `before_f2p_unexpectedly_passing` fixed; all 78 tests are now
  fail-to-pass (see eval-results.md).
- test.sh fallback name list verified programmatically against the test functions: 81/81, no gaps.
- meta.md 264 words, ASCII, LF, no headers, no em dashes.
- solution.patch and test.patch generated against BASE_COMMIT, ASCII + LF,
  `new file mode 100755` present for test.sh.

Still open:
- Docker build of the image has not been run; the Dockerfile mirrors the two sibling Rust
  problems in this folder but is unverified.
- The 4-cell offline validation (base/new x base/solution) has not been run inside the image.
- The FP check and a platform batch are pending.

## Traps actually reproduced while building the reference

These are not predictions, each one bit during implementation and is recorded so the difficulty
claim is grounded:

1. **Global keywords break `math.min`.** The tokenizer is a `logos` derive where every keyword is
   a global `#[token("...")]`. Reserving `min`, `max` or `count` steals them from the field-access
   path, and `math.min`, `math.max` and `math.count` all exist and are covered by the repo's own
   tests. The reference recognizes the names positionally instead (`at_for_agg`, two tokens of
   lookahead after `for`), so nothing is reserved.
2. **`boolean_term` swallows the aggregate.** `for_expr` sits in the boolean-term alternation, so
   the first working parse consumed `for sum i in (..) : ( i )` and left `== 10` behind, producing
   a syntax error for every aggregate used in a comparison. The fix is to route an aggregate to
   the comparison alternative and to add it to `term`, since it produces a number, not a boolean.
   Cost: one full debugging round, every test failing with the same misleading `E001`.
3. **Adding an enum variant changed every IR hash.** `Expr`'s `Hash` uses `discriminant`, so
   inserting `ForAgg` before `Lookup` shifted the discriminants and broke the `5.ir` goldenfile
   with no connection to the feature. The variant is now last, with a comment saying why.
4. **Extracting the comparison chain changed an error message.** Moving the operator token set
   into a helper and relabelling its description flipped goldenfile `errors/89.out` from
   "expecting `%`, operator, `of` or `}`" to a version that also lists "expression". Restoring the
   original description made the baseline byte-identical again.
5. **`emit_for` is boolean-shaped.** It fuses iteration with quantifier bookkeeping, returns i32
   and stops as soon as the quantifier is decided. The reference splits the iterable-specific
   scaffolding (`Loop` + `emit_loop`) from the quantifier logic so the aggregate can ride the same
   four lowerings, and runs the loop with `Quantifier::All` plus a body that always reports it can
   continue, which is what makes it visit every iteration.
6. **The variable frame is a fixed constant.** `VarStack::FOR_IN_FRAME_SIZE` is 7; the accumulator
   and the "did anything contribute" flag need two more slots, hence `FOR_AGG_FRAME_SIZE`. Getting
   this wrong collides with the loop's own `n`/`i` slots.

## Hardening round 1 (2026-07-28) - a full Nova batch solved it

A platform batch came back with every Nova run passing. Diagnosis: all six original traps are
caught by `cargo test`. Reserving the operation words breaks the math module's tests, a wrong
`ty()` or frame size fails WebAssembly validation, the enum discriminant shift breaks a goldenfile.
An agent that runs the suite and iterates to green clears every one of them without insight. More
tests would not have moved the rate either, because the reference already passed them all
(REFERENCE-UNCHANGED = DEAD TEST).

So the lever had to change what must be BUILT, not what is asserted. Probing the reference for
compositions no test covered found three live bugs in it, all one root cause: `ast2ir` allocates a
loop's frame AFTER building that loop's quantifier and iterable, and releases it on the way out, so
a sibling expression reuses the same slots. An aggregate evaluated while an outer loop's frame is
live overwrites that loop's `n`, `i` or accumulator.

Broken before this round, silently and with the whole repo suite green:

- `for (for count i in (1..3) : ( true )) j in (1..3) : ( j > 0 )` returned false
- `for sum i in (1 .. for max j in (1..3) : ( j )) : ( i )` returned 0
- `for count i in ((for min j in (2..4) : ( j )) .. 4) : ( true )` returned 0

The fix needs two separate insights. First, the aggregate must reserve its frame BEFORE its
iterable is built, so anything nested in the iterable lands on slots of its own. Second, the shared
`emit_for` must evaluate the quantifier BEFORE it initializes the loop variables, because
evaluating it may itself run a loop over the very slots being set up; the value is parked in a
scratch local until the loop is ready. The percentage form still needs `n`, so only the value moves
early, not the multiplication.

Why this one survives where the others did not: no existing test exercises it, the symptom is a
wrong number rather than an error, and the WebAssembly still validates, so a solution can be
complete, pass the entire repo suite, and still be wrong. The contract is one sentence in the
description ("An aggregate is an expression, so one may appear in the quantifier or in the bounds
of another loop") and that sentence does not hint at frame lifetime or emission order.

Cost: 909 -> 951 raw, 591 -> 613 human-effective LOC. Zero regressions, 364 base tests still green.

## Hardening round 2 (2026-07-28) - aggregates over pattern sets

Round 1 closed the frame-lifetime hole. This round adds the one iterable family the aggregate did
not cover, because probing found no further live bug to convert: deep nesting (to 30 levels),
cross-rule and global/private rule use, and aggregates inside `for .. of` bodies were all already
correct, so there was nothing cheap left to harden into.

New surface: `for sum of them : ( # )`, and the same with a named subset or a wildcard in place of
`them`. It is the natural completion of the feature (the total, largest or smallest match count
across a pattern set) and it forces a fifth lowering that shares nothing with the other four.

What an implementation has to get right, none of which the other four lowerings exercise:

- The aggregate's iterable is no longer a value sequence. `Iterable` gains a pattern-set arm and
  the loop's `item` holds a pattern id rather than a value.
- The body's symbol table must bind `$` to that item, which is what makes `#`, `@`, `!` and `$`
  inside the body refer to the pattern of the current iteration rather than to a fixed one.
- `ctx.for_of_depth` has to be raised and lowered around the body. This is the buried half: the
  compiler uses that depth, together with a scan of the body for dynamic pattern variables, to
  decide whether the fast-scan optimization is still safe. Get it wrong and nothing fails to
  compile, no test in the repo breaks, and the scanner silently reports wrong matches only in
  fast-scan mode.
- The parser's two-token lookahead after `for` previously required an identifier, so it has to
  admit `of` as well without swallowing `sum of them`, which must still be an unknown identifier.

Cost: 951 -> 1100 raw, 613 -> 713 human-effective LOC. 322 base tests still green.

One earlier assertion had to be reversed: `operation_words_outside_the_aggregate_form` claimed
`for sum of them` was rejected, which was true before this round and is now the headline syntax.
The test keeps the forms that are still invalid (`sum of them` and `min of them` without the `for`,
and a missing `in`) and dropped the two that became valid.

## Coverage advisory round 13 (2026-07-28) - one advisory found a real bug

The "parser/AST tooling integration" advisory paid for itself. `cli/src/commands/deps.rs` walks the
AST to compute rule dependencies and registers the loop variables of `Expr::ForIn` and `Expr::With`
so they are not mistaken for rule references. Everything else falls through a `_ => {}`, so the new
`Expr::ForAgg` was silently omitted. Reproduced on the built binary:

    rule i { condition: true }
    rule t { condition: for sum i in (1..3) : ( i ) == 6 }

    $ yr deps
     t
     └─ i        <- wrong, `i` is the aggregate's loop variable, not a rule

The same rule written with `for any i in (1..3)` reports no dependency, which confirms it was this
feature's gap and not pre-existing behavior. Fixed by registering the aggregate's variables on
enter and unwinding the scope on leave, matching what `ForIn` already does. The pattern-set form
binds no named variables, so it pushes an empty scope to keep the push and pop balanced.

This is the end-to-end wiring blocker: a new AST node that binds variables has to be handled by
every tool that walks the AST, and a catch-all arm hides it. `fmt` was checked too and is safe,
it formats from the CST token stream rather than the AST.

Honest limitation: `find_dependencies` is a private function in a binary crate, so it cannot be
reached from an integration test, and adding a `#[cfg(test)]` module would put test code in
solution.patch. The fix is therefore verified by hand against the built binary and recorded here
rather than covered by an automated test.

## Hardening round 3 (2026-07-28) - the `avg` operation

Probed first for another live bug, as in round 1, and found none: a pattern referenced only inside
an aggregate body is correctly marked used, rules with aggregates serialize and deserialize
faithfully, the potentially-slow-loop and too-many-iterations warnings fire at parity with the
quantified form, and the formatter renders the new syntax correctly (it works from the CST, not the
AST). So the lever was new machinery again.

`avg` is the natural fifth operation, and it is valuable here precisely because it BREAKS two rules
a solver will have internalized from the other four:

- **The result type no longer follows the body type.** Every other operation is an integer over an
  integer body; `avg` is a float always. The reference had `is_float` doing double duty as both the
  accumulator type and the result type, and `avg` forces those apart: it accumulates in the body's
  type but reports `Type::Float`.
- **The empty identity no longer groups with `sum`.** `count` and `sum` are 0 when nothing
  contributes, but `avg` has no value, like `min` and `max`. A solver that groups it with `sum`
  because both are additive gets 0 instead of undefined.

Two traps sit under the arithmetic itself, and both are contract-stated but fix-hidden:

- **The divisor is the number of CONTRIBUTIONS, not the number of iterations.** Over `(0..3)` with
  a body that is undefined at `i = 0`, the answer is 201/3 = 67.0 and not 201/4 = 50.25. This also
  forced `contributed` to stop being a 0/1 flag and become a real counter, which every operation
  now shares.
- **The total accumulates in the body's type and wraps BEFORE the division.** Two iterations of
  `i64::MIN` average to 0.0, and two of `i64::MAX` average to -1.0. An implementation that
  accumulated in floating point to "avoid overflow" produces 4.6e18 instead, passes every other
  test in the suite, and is wrong only here.

The description states both rules in one clause, "`avg` is the total divided by the number of
iterations that contributed", plus the type exception. Neither sentence hints at where the
conversion belongs.

Cost: 1113 -> 1134 raw, 724 -> 740 human-effective LOC, 53 -> 58 tests. 322 base tests still green,
which also confirms the flag-to-counter change did not disturb `min` and `max`, whose
nothing-contributed check reads the same variable.

## Hardening round 4 (2026-07-28) - the fast-scan guard was CLAIMED but not IMPLEMENTED

Round 2 described the fast-scan interaction as "the buried half" of the pattern-set lowering. That
description was right about the requirement and WRONG about the reference: `for_agg_expr_from_ast`
raised and lowered `ctx.for_of_depth` but never replicated the block that `for_of_expr_from_ast`
runs right after building its body, which walks the body for `PatternCountVar`,
`PatternOffsetVar`, `PatternLengthVar` and anchored `PatternMatchVar` and calls
`disallow_fast_scan()` on every pattern in the set when it finds one. The claim sat in feedback.md
for two rounds without being true.

Proven with a differential run rather than assumed. Scanning `AAAABBBBAAAACCCC`, where `$a` matches
twice:

    for sum of them : ( # ) == 3     normal: matches      fast scan: DOES NOT MATCH

The fast scan stops after a pattern's first match, so `#` reads 1 instead of 2 and the sum is 2
instead of 3. With the guard restored both modes agree. Nothing errors, the WebAssembly validates,
and all 322 base tests pass either way, so this is only visible if something compares the two scan
modes.

The new test `pattern_set_aggregate_agrees_in_fast_scan_mode` compiles each rule once and scans it
with a normal scanner and a `fast_scan(true)` scanner, asserting both that it matches and that the
two modes agree.

**The first version of that test was a fiction and my own mutation check caught it.** It scanned the
file's `DATA` constant, where every pattern matches exactly once, so removing the guard did not
change the result and the test passed against the broken build. Only after switching to data where
`$a` matches twice did the mutation get killed. Recorded because it is the whole argument for
mutation-proving a trap test instead of trusting that it looks right: the assertion was reasonable,
the values were correct, and it still tested nothing.

Cost: 1134 -> 1168 raw, 740 -> 762 human-effective LOC. 322 base tests still green.

## Auto Review round 23 (2026-07-28) - Revision Requested, both findings were real

Three Auto Review passes. Description 3/3 in all three. Two blocking findings, both accepted.

**S1, raised by all three reviews: integer-body `avg` was reported as an integer.** When `avg` was
added in hardening round 3 I updated `ForAgg::ty()` to return float for the operation but missed the
parallel `Expr::type_value()` branch, which still keyed off `is_float` alone and so described an
integer-bodied average as an integer. The reviews called it a latent typing inconsistency; it is
worse than that. `with` types its declaration from the initializer's `type_value()`, so:

    with m = for avg i in (1..4) : ( i ) : ( m == 2.5 )

does not merely mis-type, it PANICS the compiler: "WASM module is not valid ... expected i64,
found f64". A crash on valid user input. Fixed by deriving the branch from `ForAgg::ty()` so the
two can no longer disagree. New test `integer_body_avg_stays_float_through_inference` covers the
`with` path, multi-declaration `with`, and an integer-body average as a tuple item in first and
last position.

**T4, raised by the third review: the CLI dependency path was untested.** Round 13 fixed
`yr deps` for the new AST node and I recorded then that it could not be covered, because
`find_dependencies` is private and `cli/src/tests/` cannot compile under `cargo test` (the repo
sets `test = false` on the binary, and `CARGO_BIN_EXE_yr` is undefined for a bin's own unit-test
target). That reasoning was right about the existing location and wrong about the conclusion: a
proper integration test in `cli/tests/` does get `CARGO_BIN_EXE_yr`. Added
`cli/tests/deps_agg_685dcf.rs` with three tests, wired into `test.sh` new mode, and the Dockerfile
now prebuilds `yara-x-cli --tests`.

Mutation-proven: removing the `ForAgg` arm from the deps walker makes
`aggregate_loop_variable_is_not_a_dependency` fail, and restoring it makes it pass.

The first version of that CLI test asserted on the tree-drawing characters in the deps output,
which pulled non-ASCII into test.patch. Rewritten to strip the drawing characters and compare the
resulting entry list, which is both ASCII-clean and a stronger assertion, since it now pins the
exact set of reported dependencies rather than the absence of one substring.

## FP review round 26 (2026-07-28) - two panels, opposite verdicts, same probe

Two false-positive reports on the same candidate and the same probe reached OPPOSITE adjudications:
one called it a false positive at medium confidence, the other a genuine pass at high confidence.
The disagreement is the finding. Both agree on the facts and differ only on whether the description
decides the case, which means the description did not.

The probe: `with sum = 2 : ( for (sum) i in (1..3) : ( i > 1 ) )`. Base yara-x accepts it, the
parenthesized `(sum)` being an ordinary variable supplying the loop quantifier. The candidate
rejected it, because its `cst2ast` rewrote ANY quantifier that reduced to an identifier named
count/sum/min/max/avg into the aggregate operation, ignoring the parentheses. The second panel's
own note says the prompt "does not decide whether a parenthesized name in the quantifier slot is
the operation", and the first panel called that same slack out as the reason its confidence was
only medium.

Fixed where the ambiguity lived. The scoping sentence now reads:

    The names of the five operations are only meaningful written directly after `for`. Anywhere
    else they are ordinary identifiers, so a parenthesized one supplies a quantifier the way any
    other expression does.

New test `parenthesized_operation_name_is_an_ordinary_quantifier` pins it for all five names, with
a non-operation variable as the control that makes the other cases a regression rather than a new
rule, and the bare form asserted alongside with a same-named variable in scope.

**On mutation-proving this one, honestly:** I could not reproduce the candidate's defect in my own
tree. My reference recognizes the aggregate from the token stream (a bare identifier immediately
after `for`), so a name-based rewrite at the `cst2ast` layer is structurally unreachable here, and
my attempted mutant changed no behavior. The discrimination evidence is therefore not a local
mutant but the adjudicator's own run: they reproduced the failure on the candidate using this exact
expression, and the test asserts that expression verbatim. That is stronger evidence than a
synthetic mutant, but it is external, so it is recorded as such rather than claimed as a local kill.

## Working tree loss and restore

Partway through this round the `worktrees/yara-x` checkout disappeared, with disk use dropping from
96 percent to 74 percent, so something reclaimed it mid-session; it was not removed by any command
here. The five deliverables were unaffected. The tree was restored by re-cloning the repo, checking
out BASE_COMMIT and applying solution.patch and test.patch, which both applied clean, and every
check in this round ran against that restored tree. Worth noting as evidence the patches are
genuinely self-contained.

## Test composition

All 81 tests fail on base. Rejection tests each open with a valid aggregate as a canary, so
assertions of the form "does not compile" do not pass vacuously on base, where compilation fails
for the wrong reason.

The three baseline-preservation tests (`rules_can_be_named_after_an_aggregate`,
`quantified_for_still_works`, `of_expressions_still_work`) each carry an aggregate assertion too.
They started as standalone pass-to-pass guards and the platform rejected that: every test in the
new suite must fail without the solution. Each keeps all of its original assertions and gained one
that depends on the feature, so they still guard the reserved-keyword and shared-emitter traps,
which are the two most likely ways a solution regresses the baseline.
