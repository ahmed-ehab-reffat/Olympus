# DESIGN.md - pyocd-sequence-expression-kernel

Repo: pyocd/pyOCD (Apache-2.0, 1462 stars, Python 99.7%)
Base: d1974ffdd16369148ba678478fa85886282d09b1
Hunt log: Instructions/repo-hunt-logs/REPO-HUNT-2026-09-20-C.md

## 1. Title

Add a single evaluation model to the debug sequence expression engine

Verb: Add. Names the subsystem (debug sequence expression engine). 9 words.

## 2. Shape classification

- Shape: O-Pipeline-hard / Mars A2 hybrid. Two existing evaluation stages of one
  operator table must be reconciled, plus a new analysis (effects) that gates one of them.
  Closest SHAPES.md entry: O-Pipeline-hard (new machinery + cascading through existing stages,
  no obvious single approach).
- Pass rate target: 20-35% (sprint ceiling 40%).
- Best agent: Orion (long-horizon; the fix spans a class the agent did not open).
- Dominant verdict: MISSED_REQUIREMENT, surfacing as a missing probe transaction.
- Category: feature-request (title verb Add; the evaluation model is net-new machinery).

## 3. Public API surface

No new public name is required by the tests. Everything is asserted through names that
already exist on base:

- `Block(code)` / `Block.execute(context)` - run a statement list.
- `WhileControl(predicate)` / `IfControl(predicate)` - run a predicate loop.
- `DebugSequence.execute(context)` - run the whole node tree.
- `Scope.get(name)` - read the resulting value.
- `_ConstantFolder()` - constructed with NO arguments, `.transform(tree)`; already imported by
  `test/unit/test_debug_sequences.py` on base.
- The delegate object returned by `get_sequence_functions()` - the tests supply one that records
  every call, which is the observable for the effect stream.

Deliberate choice (L72 inverted): the tests import nothing new, so a solution that names its
helpers differently still compiles. There is no signature coin-flip in this problem.

Internal (not named in meta.md): a new module holding the 64-bit value domain and the per-operator
model (evaluator, short-circuit decider, literal simplifications), an effect-analysis helper over
the AST, an expression-kind analysis in the semantic checker, and a transfer-width helper on the
common sequence functions.

## 4. Canonical output form

- Value domain: every value an expression produces is an unsigned 64-bit integer; arithmetic,
  shifts and bitwise operators wrap modulo 2**64; comparisons and `/` `%` are unsigned.
- Shift count >= 64: result is 0.
- `/` and `%` by zero: result is 0 (existing behaviour, preserved).
- `&&` and `||` produce exactly 1 or 0, never an operand's value (already the documented run-time
  contract at `test/unit/test_debug_values.py also carries the per-operator model consumed by BOTH the folder and the interpreter:
  - `BinaryOperator(evaluate, decider, identities, constants)` - one row per operator
  - `short_circuit_result(op, value)` - the result one operand settles on its own, or None
  - `simplify_with_literal(op, index, literal)` - keep the other operand, or a constant, or None
  - `is_true(value)` - the one truth test used by the logical operators and the predicates

sequences.py:433-437`).
- Effect order: left operand first, then the right one if it is evaluated at all.
- Scope stores the wrapped value.
- A call's arguments and its result are values of the domain; a call that returns nothing is worth
  zero as a statement and is not a value anywhere else.
- A compound assignment reads its variable before evaluating the right hand side; an assignment is
  worth the value the variable ends up holding.
- A transfer carries as many bits as its width names, and a width of 64 or more carries the whole
  value.
- Only an integer is a value: a string or a call that returns nothing, used where a value is
  required, is a semantic error raised before any of that code runs.

## 5. Blind-spot pre-empts

- Iteration termination / repeated evaluation: "Re-evaluating a `while` predicate repeats the
  effects of that evaluation."  (bank: iteration-termination)
- Compound order preservation: "The left operand is evaluated first."  (bank: compound-order)
- Falsy-on-invalid: "`&&` and `||` produce 1 or 0."  (bank: falsy-on-invalid)
- Pipeline placement is deliberately NOT stated (that is the F-9 trap; the contract is stated on
  the observable stream, never on which stage must change).

Codebase-inferable requirements: 1 (that division by zero keeps yielding 0 - visible in the op
table and in no test).

## 6. Description draft

See meta.md. Framed on `Block`, `Control`, `Scope` and the sequence-function delegate, and on the
invariant that whether an operand is a literal must not change the call stream. NEVER framed as
"fix the arithmetic semantics" (rejected/cfn-guard-arithmetic died DERIVATIVE on that phrasing).

## 7. File footprint

SHIPPED (round 2, after the platform solution review):

| Action | Path | Raw added | human-eff | Reason |
|---|---|---|---|---|
| NEW    | pyocd/debug/sequences/values.py    | 147 | 71 | value domain + the per-operator model (evaluator, short-circuit decider, literal simplifications) |
| MODIFY | pyocd/debug/sequences/sequences.py | 222 | 150 | effect analysis, table-driven folding, short-circuit interpreter, lazy ternary, call boundary, compound assignment order, expression-kind checking, the value-producing context for a control predicate |
| MODIFY | pyocd/debug/sequences/functions.py |  32 | 17 | transfer-width coercion at the delegate boundary |
| MODIFY | pyocd/debug/sequences/scope.py     |   5 |  2 | store values in the domain |

Measured: 406 raw / **240 human-effective** across 4 files (hook padding-floor 166; the 18-row
operator table is the breadth it is flagging, and it replaces the base `_BINARY_OPS`/`_UNARY_OPS`).

The Step-4b slice was 182 raw / 107 eff across 3 files. What closed the gap, against the six-lever
FINISH table this section used to carry:

| Lever | Status |
|---|---|
| 1 transfer-width coercion at the `functions.py` delegate boundary | SHIPPED, with a domain clamp so a bit count from the domain cannot build a 2**64-bit mask |
| 2 `SemanticChecker` diagnostics over the expression domain | SHIPPED as the "only an integer is a value" rule: a string or a call that returns nothing, anywhere a value is required, reported before any of the code runs |
| 3 remaining fold identities (`x - x`, `x ^ x`, ...) | DROPPED. They need subtree equality and are unobservable at run time, so any test for them would pin the AST rather than behaviour |
| 4 compound assignment and declaration through the whole model | SHIPPED (this was also review finding 2) |
| 5 argument evaluation order for several arguments | SHIPPED (no new code needed; covered by the call-boundary rewrite and two tests), and meta.md now states it after the alignment gate asked |
| 6 the `Control` timeout interaction | DROPPED on flakiness grounds: it is the one lever here that would put a clock in an assertion |

## 8. Solution outline

values.py:
  - `to_word(value) -> int`               - mask to 64 bits
  - `evaluate_binary(op, left, right)`    - one entry point for every binary operator
  - `evaluate_unary(op, value)`           - one entry point for every unary operator
  - per-op helpers for `/ % << >>` (unsigned division, zero divisor, out-of-range shift count)

sequences.py:
  - `_expression_has_effects(node) -> bool` - true when the subtree contains a function call or an
    assignment; recursive over LarkTree children
  - `_ConstantFolder.binary_expr` - per-operator identity table gated on which operand the identity
    DISCARDS and whether that operand has effects; `&&` / `||` handled by short-circuit polarity
  - `_InterpreterVisitor.binary_expr` - left operand first, right operand visited only when the
    combinator needs it
  - `_InterpreterVisitor.ternary_expr` - predicate first, selected branch only
  - `_InterpreterVisitor.fncall` - arguments left to right, each value and the returned value
    reduced to the domain
  - `_InterpreterVisitor.assign_expr` - read the target first for a compound operator
  - `SemanticChecker._SemanticsVisitor._expression_kind` - VALUE / STRING / NOTHING / UNKNOWN,
    recursive through conditionals and assignments, a call's kind taken from its declared result
  - `SemanticChecker._SemanticsVisitor._require_value` - the operand, argument and initialiser check
  - `SemanticChecker._SemanticsVisitor._check_argument` - one argument against the parameter that
    receives it, called for each fixed parameter AND for every argument a varargs parameter takes

functions.py:
  - `_to_transfer_width(value, width)` - reduce to the transfer width, clamped at the domain
  - the fixed width writes, the DP/AP writes, the abort write and the two bit-sequence functions

scope.py:
  - `Scope.set` stores `to_word(value)`

No fixpoint loop. No cycle trace (the AST is finite and acyclic).

## 9. Test file outline

Path: `test/unit/test_sequence_eval_6f893c.py` (new file, hex suffix per the naming rule). 30 tests.

Block 1 - imports (all exist on base).
Block 2 - builders: a recording sequence-function delegate (`read32`, `write32`, `dap_delay`),
          a delegate/session/context fixture triple mirroring the repo's own fixtures, and
          `run_block(context, code)` / `run_sequence(context, nodes)` helpers returning
          (scope, call log).
Block 3 - assertion helpers: `assert_calls(log, expected)`, `value_of(scope, name)`.
Block 4 - tests by bucket:
  - effect preservation through folding (literal on either side, both combinators, `* 0`, `& 0`,
    `|| 1`, `% 1`, a discarded assignment)
  - short-circuit at run time (`&&` false-left, `||` true-left, both true/false twins)
  - lazy ternary
  - the corrected fold identities as run-time values (`x || 0`, `0 || x`, `0 - x`)
  - 64-bit domain (`0 - 1`, `-1`, `y -= 1`, `1 << 64`, wrap on `*`)
  - the while-predicate path (call count per iteration)
  - base-preservation twins (`_ConstantFolder()` no-arg; `x && 0` with a pure operand still folds
    to 0 in the AST, mirroring the repo's own TestConstantFolder style)

Existing-file amendment (test.patch also edits `test/unit/test_debug_sequences.py`): delete
exactly three parametrize rows that encode the old wrong identities -
  `test_fold_left_0`  row `("||", "x")`   (`x || 0` is not `x`; it is `x != 0`)
  `test_fold_right_0` row `("-",  "x")`   (`0 - x` is not `x`; it is the 64-bit negation)
  `test_fold_right_0` row `("||", "x")`   (`0 || x` is not `x`)
All three contradict the repo's own run-time contract at `test_debug_sequences.py:433-437`
("they must produce a 1 or 0 and not the value of either operand"). The corrected cases move into
the new file as run-time value tests. Every other row in those two tables, and the whole of
`test_fold_left_1`, stays in base mode and must keep passing - excluding them would be the L31
anti-pattern.

5-axis coverage: every stated atom, every surface the tests can reach, every folder branch,
edge cases (zero operand, one operand, shift >= width, empty call log), and the stated inverse
(the fold that MUST still happen when the operand is pure).

## 10. Forced signatures

Python; no generics. The only forced shape is the recording delegate, which the tests define
themselves and which mirrors `SequenceFunctionsDelegateForTesting` already in the repo. Sequence
function parameters must carry `int` / `str` annotations or `SemanticChecker` rejects the call -
the test delegate follows the repo's own pattern, so no new constraint reaches the solver.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | The same semantics is resolved twice: the folder runs inside `Interpreter.__init__` and deletes operands before the interpreter ever runs | F-9 | S6 | stage placement | #2, #4 | Short-circuiting obviously belongs in the interpreter; the folder is named as an optimization and is a different class | "Whether an operand is a literal must not change which functions a sequence calls, how many times, or in what order." | `folded_conjunction_with_a_literal_zero_still_calls_the_left_operand` |
| 2 | Which literal position short-circuits is mirrored between `&&` and `\|\|`, so a purity guard written for one is wrong for the other | F-27 | A8 | polarity | #1 | Agents derive `\|\|` from `&&` by symmetry and keep the literal value 0 in the guard instead of flipping to nonzero | "`&&` evaluates its right operand only when the left is nonzero, and `\|\|` only when the left is zero." | `disjunction_with_a_literal_one_on_the_right_still_calls_the_left_operand` |
| 3 | Cross-product of {literal on the left, literal on the right} x {`&&`, `\|\|`} x {block, while predicate} | F-10 | S2 | composition | #2 | Each axis passes alone; the off-diagonal cell needs the combination | none needed - covered by composition of #1 and #2 | `while_predicate_short_circuits_on_the_final_evaluation` |
| 4 | The repo's own `TestConstantFolder` constructs `_ConstantFolder()` with no arguments and pins 30 identities; threading a scope or context into the folder reds base mode | F-12 | S3 | baseline preservation | #1 | The natural way to ask "does this operand have effects" is to hand the folder more context | "Existing debug sequences keep evaluating exactly as they do today." | base mode |
| 5 | One 64-bit unsigned domain (support only, never the lead) | F-30-ish | B | value width | #1 (the `0 - x` identity is only removable once negation is defined) | unary `-` masks today and binary `-` does not | "Every value a sequence expression produces is an unsigned 64-bit integer." | `zero_minus_variable_is_the_sixty_four_bit_negation` |

| 6 | A call result is the one value in the system that reaches a comparison, a shift count and an argument without ever passing through a scope store | F-30 | B | boundary completeness | #5 | Normalising the store looks like it covers the variable, and the call result is the case that escapes it. The first version of this solution deleted the point as dead code and the platform review caught it | "The value a sequence function returns is a value of this domain." | `a_function_result_below_zero_is_reduced_to_the_domain` |
| 7 | A compound assignment is a binary operator whose left operand is not in the tree, so the natural `visit_children` order reads it last | F-19 | A | evaluation order | #6 | Every other operator reads its operands out of the visited children; the target is the one operand that has to be fetched explicitly, and fetching it after the visit is one line shorter | "A compound assignment reads its variable before it evaluates the right hand side." | `a_compound_assignment_reads_the_variable_before_the_right_hand_side` |
| 8 | The width model creates a gap it must then close: a 64-bit value handed to a 32-bit transfer, and a bit count that is itself a domain value | F-30 | B | cross-file consequence | #5 | The mask is obvious; the clamp is not, and a count of `0 - 1` builds a 2**64-bit mask | "A transfer carries only as many bits as its width names ... a width of 64 or more carries the whole value." | `a_bit_count_beyond_the_domain_carries_the_whole_value` |
| 9 | A string reaches an operator only through a conditional, a parenthesis or an assignment, because the grammar keeps `STRLIT` out of the operator rules | F-14 | A | declared vs derived | #6 | A direct `1 + "a"` does not parse, so the shallow check looks complete; the recursive one is what the conditional needs | "Only an integer is a value." | `a_string_operand_is_rejected_before_anything_runs` |

Every row names a different axis. Rows 1, 2 and 4 are mutually interdependent: a local fix to the
interpreter leaves row 1 live; a local fix to the folder leaves row 1 live from the other side; a
folder fix that takes more context breaks row 4.

## 11b. Capability cross-product matrix (F-10)

Axis 1 - which operand is the integer literal. Axis 2 - combinator polarity.

|                    | `&&`                                            | `\|\|`                                            |
|---|---|---|
| **literal on the LEFT**  | `0 && Read32(a)` - read must NOT happen (diagonal) | `1 \|\| Read32(a)` - read must NOT happen (diagonal) |
| **literal on the RIGHT** | `Read32(a) && 0` - read MUST happen (off-diagonal) | `Read32(a) \|\| 1` - read MUST happen (off-diagonal) |

Axis 3 - the consumer. Each of the four cells above is also run through a `while` predicate, where
`Control.execute` reuses ONE `Interpreter` across iterations while `Block.execute` builds a fresh
one per execution.

Predicted failure mode on the off-diagonals: UNDER-firing (the call disappears), because both the
fold and the short-circuit paths want to drop the same operand for different reasons.

Scope audit: the effect rule is scoped to the WHOLE expression, including nested sub-expressions
and both sides of an assignment. Stated as such.

Example audit (L21): meta.md contains no worked example of an expression. The rules are stated in
general form only.

Format-noun audit (L24): the nouns meta.md names are "operand", "expression", "statement",
"sequence function". "Operand" is given an explicit extent ("an operand is the whole
sub-expression on that side, not just a variable or a literal").

Tolerance-fixture audit (L25): the while-predicate test asserts the call count for the FINAL
evaluation (the one that ends the loop) as well as the count for the iterations, so a solution
that short-circuits only inside the body still fails.

Float audit (L59): no floats anywhere; the domain is integers.

Stage-placement audit (L57): meta.md never says a new stage runs "between" existing ones.

## 12. Tier + category

- Tier: Olympus (one tier).
- Category: feature-request.

## 13. Predicted pass rate

**MEASURED: 2 of 11 = 18%** after the round-5 cut (replay over the batch-1 solution population).
Batch 1 measured 0 of 11 before it. The prediction below was 15-30% and the pre-cut artifact
landed under it, which is the whole lesson of section 19.

Original estimate, kept for the record: 15-30%. The stated rules are individually transcribable (a competent solver knows what
short-circuiting is), so the band comes from the number of boundaries that all have to be closed
at once: the folder and the interpreter must agree, the call boundary and the compound assignment
each escape the obvious normalisation point, the kind analysis has to be recursive to reach the
only form the grammar allows, and the width clamp only matters for a count that is itself a domain
value. Round 2 added four of those nine traps, so the round-1 estimate of 25-35% comes down. If a
batch reads above 40%, the cheap lever is the remaining off-diagonal cells of 11b, which cost zero
description words and are re-eval eligible.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement zones, pytest + test/unit,
      `test/unit/test_debug_sequences.py` as the formatting template)
- [x] Existing-PR check: canonical org `pyocd/pyOCD` resolved; the only two open PRs listing
      `sequences.py` (#1604, #1687) carry ONLY the already-merged `assign_stmt` -> `assign_expr`
      rename through a stale base - diffs read, not bodies. Feature-class PR searches for
      "constant fold", "short circuit", "purity", "64-bit", "side effect": no hits in the lane.
- [x] Issue class search: no maintainer position for or against; no closed-as-implemented hit.
- [x] base..origin/develop on `sequences.py` + `scope.py`: EMPTY diff. The kernel is frozen.
- [x] Closest approved opened as scaffolding: approved-problems/ray-optics-formula-conditionals
      (dual-combinator polarity, F-26/F-27) and neva-array-bypass-generalization (F-9).
- [x] Title verb-led, names the subsystem
- [x] Public API surface: no new required name
- [x] Canonical form spelled out
- [x] <=1 codebase-inferable requirement
- [x] Description: plain prose, no headers
- [x] File footprint against real files
- [x] >=2 files
- [x] Helpers 1+ per behaviour
- [x] Test outline 4-block, scenario names
- [x] Traps on different axes, at least one interdependent
- [x] 11b matrix filled, every off-diagonal has a test
- [x] Gate 9 flakiness: base suite 1100 passed / 41 skipped in 2.35 s, no sleeps, no RNG, no
      network; 3x determinism recorded in eval-results.md
- [x] Gate 10 quota: 0 of 6
- [x] In-process validation only (L56): nothing shells out

## Why this is not a duplicate

Closest in our dirs: `rejected/cfn-guard-arithmetic` ("add arithmetic operators to a rules
language", shelved DERIVATIVE) and `approved-problems/ray-optics-formula-conditionals` (a dual
combinator added to a range-analysis pass). The differentiator is that pyOCD's operators already
EXIST and already evaluate: the capability is an effect model plus the reconciliation of two
existing consumers of one operator table, observable as a probe transaction stream. Nothing is
being added to the language.

Predicted iteration cycles: 2.


## 15. Slice validation record (Step 4b)

Clean room: fresh clone at BASE in `worktrees/pyocd-cleanroom`, Docker image
`factory-pyocd-sequence-expression-kernel`, run as `--user 1000:1000 --network none`.

| Configuration | base | new |
|---|---|---|
| test.patch only | 1138 tests, 0 failures, 3x identical | 30 tests, 30 failures, 3x identical |
| test.patch + solution.patch | 1138 tests, 0 failures, 3x identical | 30 tests, 0 failures, 3x identical |

Both patches apply and unapply cleanly in either order, leaving `git status --porcelain` empty.
Cold `docker build` 101 s. Suite runtime under 4 s; no sleeps, no RNG, no network, no clock
assertion. The two `while` fixtures are bounded twice over (the test target stops reporting a
non-zero word after eight reads, and each loop carries a 5 s control timeout) so a wrong solution
fails rather than hanging the runner.

Mutation self-check: 15 single-point mutations of `solution.patch`, each applied to a pristine copy
and verified to have landed, each run against BOTH modes. **15 of 15 killed.** Two earlier rounds
found three survivors and each one was a real finding, not a missing test:

- `Scope.set` masking was unreachable because every operator already masked its result. Fixed by
  narrowing the design to ONE normalisation point per boundary (operator result, integer literal,
  scope store) and adding a direct `Scope` fixture.
- The `>= 64` shift guard was unreachable because masking already zeroed the result. Fixed by
  testing a shift whose COUNT is a wrapped value, which is a `MemoryError` without the guard.
- Masking a sequence function's return value was genuinely dead code once the scope store masked.
  Deleted from the reference rather than tested with a contrived delegate.

An implementation-detail test that pinned the folded AST shape was also deleted: the repo's own
`TestConstantFolder` already pins the folds that must still happen, and every effect claim is
observable at run time through the call log.


## 16. Round 2 record (after the platform solution review)

The review FAILED the slice on two high comprehensiveness findings, both of which were real bugs
rather than test gaps: a call result was never reduced to the domain (the slice had deleted that
point as dead code), and a compound assignment read its target after evaluating the right hand
side. Both are fixed and pinned. The review's ten coverage suggestions are all covered, and the six
of them that do not discriminate on their own were either given an assertion only the new model
satisfies or moved into base mode, so all 84 new cases still fail on base.

Also landed: FINISH levers 1, 2 and 4 (transfer width, the "only an integer is a value" rule,
compound assignment through the model), one operator model consumed by both the folder and the
interpreter, and one reduction point per boundary after two mutation survivors showed three points
were normalising the same value.

Numbers: 392 raw / 236 human-effective across 4 files; 64 test functions / 84 cases; 23 of 23
mutations killed; base 1143 pass in every configuration, 3x identical, uid 1000 and root.
Per-requirement trace, the validation table and the mutation table are in eval-results.md.


## 17. Round 3 record (second platform precheck)

Solution Quality FAILED again on one real finding: a control predicate bypassed the value-kind
check, so `IfControl("DAP_Delay(1)")` ran the void call and was coerced to zero. Verified locally
before changing anything; the reviewer's other example (`IfControl('"text"')`) was already rejected
by the repo's own pre-existing `expr_stmt` string check, so only the void-call and
conditional-branch halves were live.

The fix is the one piece of context the checker lacked: whether the tree it is given is RUN for
what its statements do or EVALUATED for the value it produces. `Control` says the latter, and the
checker then requires the tree's last statement to be an expression statement producing a value.
Both branches of a conditional are required to be values where they are written, which is the
robust form the reviewer suggested and which let `_expression_kind` drop its conditional recursion
(two paths deciding one thing is what produced the surviving mutants in round 2).

Three other gates also moved the artifact:

- The test-quality gate FAILED `TestSequenceConstantFolding` for reaching into `Parser`,
  `_ConstantFolder` and `LarkTree` to assert AST shape. Deleted; the claims are asserted
  behaviourally elsewhere and the folds that must still happen are pinned by the repo's own
  `TestConstantFolder` in base mode.
- The sanity gate warned that base mode ran newly added tests. The five rows round 2 added to
  `test_debug_sequences.py` are removed; that file now only loses three rows.
- The alignment gate wanted call-argument order stated. Added.

Numbers: 415 raw / 251 human-effective across 4 files; 69 test functions / 90 cases; 27 of 27
mutations killed (M25 needed a new test - a predicate whose last statement only declares a
variable); base 1138 pass in every configuration, 3x identical, uid 1000 and root.


## 18. Round 4 record (third platform precheck)

Solution Quality FAILED on one real finding: variadic integer arguments bypassed the value check.
The repo's argument walk breaks out of the signature loop at the `VAR_POSITIONAL` parameter, and
round 2 had added `_require_value` INSIDE that loop, so the rule covered every fixed parameter and
nothing past the break. `Message(0, "%d", DAP_Delay(1))` ran the void call and coerced it to zero.

The fix extracts the per-argument check into `_check_argument` and calls it from both the fixed
walk and the variadic tail, so the rule lives in one place rather than one path. This is the same
shape as the round-3 finding (a rule applied at every site but one) and the same shape as the
round-1 finding (a boundary that looked covered by a neighbour). An unannotated varargs parameter
stays unchecked, which is what keeps the repo's own `valid_fn_varg(123, x, q + 1, "hi there", 99)`
green in base mode.

Both advisory coverage suggestions were taken: the conditional-branch tests now put the invalid
branch in the position that is NOT selected, which is what separates a static check from a lazy
run-time one, and the bit-sequence tests now cover counts 0, 1, 4 and 16 instead of only 8 and
counts at or beyond the domain.

Numbers: 435 raw / 259 human-effective across 4 files; 75 test functions / 96 cases; 28 of 28
mutations killed (M28 is the variadic hole); base 1138 pass in every configuration, 3x identical,
uid 1000 and root; both patches reverse cleanly.


## 19. Batch 1 and the round-5 cut

Batch 1 (10 Nova + 1 Vega): **0 of 11**. Every run passed the baseline and was graded
FAIL_MISSED_REQUIREMENT with no environment blocker and `description_clear: true`, so the artifact
was fair - it just asked for more independent rules than an agent completes.

The arithmetic the difficulty model predicts, in the actual data: nine or ten independent rules,
each of which most agents get right, multiply out to nobody getting all of them. Three tests for
ONE rule ("a value is required for the predicate of a conditional or a loop") killed 8 of 11, and
both near-misses failed nothing else.

**What was cut:** that rule only - `require_result_value` and the `produces_value` flag through
`Control` -> `Interpreter` -> `SemanticChecker`. The conditional-BRANCH checks stayed, because no
agent failed them and they are the form the round-3 reviewer recommended. The hole the round-3
reviewer found is now closed by DECLARING it: meta.md says a call that returns nothing is valid as
a statement "including when that statement is the whole of a conditional or loop predicate", and
the generic "where a value is required" promise is narrowed to the three positions that are
actually checked.

**What it measured:** 2 of 11 = 18%, by replaying every saved agent solution against the trimmed
suite (`worktrees/_pyocd-tools/replay.py`, agent test edits excluded exactly as the grader does).
That is a paired re-measurement, so it is what a re-eval would say; meta.md changed, so the real
batch is full price.

**The lesson for the next design.** Every axis added after the core slice (rounds 2-4: the value
kinds, the control predicate, the variadic tail, the transfer widths) was added to answer a
reviewer finding or to clear the LOC floor. Each one was individually fair and individually
cheap. Together they took the problem from authorable to unsolvable, and the LOC floor is what
pushed them in: at 107 effective the core slice needed roughly +130, and axes are the only way to
buy that. Next time, buy LOC with DEPTH on one axis (more machinery behind one rule) rather than
with BREADTH (more rules), because pass rate multiplies over rules and does not care how much code
sits behind each one.
