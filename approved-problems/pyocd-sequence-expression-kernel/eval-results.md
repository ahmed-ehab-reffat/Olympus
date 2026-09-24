# eval-results.md - pyocd-sequence-expression-kernel

**ACCEPTED 2026-09-24 at 5/10 (batch 2).** Batch 1 came back 0 of 11; it was diagnosed, cut, and
re-measured against the saved agent solutions at 2 of 11 before batch 2 ran. Details below.

## Per-agent table

Batch 1 (10 Nova + 1 Vega, all evaluated by Nova). Every run passed the 1097-test baseline and
failed the new suite, every verdict FAIL_MISSED_REQUIREMENT, every environment assessment
`blocker_detected: false` / `agent_blame_unfair: false`, every problem assessment
`description_clear: true` / `tests_deterministic: true` / `difficulty: challenging`. So the artifact
was not unfair or broken; it simply asked for more independent rules than an agent completes.

| Batch | Agent | Verdict | base | new | # failed | Failed tests (axis) |
|---|---|---|---|---|---|---|
| 1 | Vega #1 | FAIL_MISSED_REQUIREMENT | pass | fail | 2 | JTAG width only |
| 1 | Nova #8 | FAIL_MISSED_REQUIREMENT | pass | fail | 3 | control predicate only |
| 1 | Nova #5 | FAIL_MISSED_REQUIREMENT | pass | fail | 3 | control predicate only |
| 1 | Nova #7 | FAIL_MISSED_REQUIREMENT | pass | fail | 4 | call boundary + scope |
| 1 | Nova #4 | FAIL_MISSED_REQUIREMENT | pass | fail | 5 | predicate + variadic + scope |
| 1 | Nova #9 | FAIL_MISSED_REQUIREMENT | pass | fail | 6 | call boundary + scope + logical + negation |
| 1 | Nova #10 | FAIL_MISSED_REQUIREMENT | pass | fail | 7 | predicate + call boundary + scope |
| 1 | Nova #1 | FAIL_MISSED_REQUIREMENT | pass | fail | 7 | predicate + call boundary + scope |
| 1 | Nova #6 | FAIL_MISSED_REQUIREMENT | pass | fail | 8 | predicate + variadic + call boundary |
| 1 | Nova #3 | FAIL_MISSED_REQUIREMENT | pass | fail | 8 | predicate + call boundary + JTAG |
| 1 | Nova #2 | FAIL_MISSED_REQUIREMENT | pass | fail | 9 | predicate + variadic + call boundary + scope |

**0 of 11 = unsolvable.** Kill counts per test, over the failing runs:

| Kills | Test | Axis |
|---|---|---|
| 8 | `test_a_conditional_predicate_that_produces_no_value_is_rejected` | control predicate |
| 8 | `test_a_loop_predicate_that_produces_no_value_is_rejected` | control predicate |
| 8 | `test_a_predicate_that_only_declares_a_variable_is_rejected` | control predicate |
| 7 | `test_call_arguments_are_evaluated_left_to_right` | call boundary |
| 7 | `test_a_function_argument_is_a_value_of_the_domain` | call boundary |
| 7 | `test_a_call_that_returns_nothing_is_still_valid_as_a_statement` | call boundary (its argument assertion) |
| 6 | `test_scope_stores_variables_in_the_value_domain` | value domain |
| 3 | `test_a_string_is_rejected_as_a_variadic_integer_argument` | variadic |
| 2 | `test_logical_operators_with_a_literal_operand_produce_one_or_zero` | logical result |
| 2 | JTAG width (2 tests) | transfer |
| 1 | `test_zero_minus_a_variable_is_the_negation` | value domain |
| 1 | `test_a_call_that_returns_nothing_is_rejected_as_a_variadic_argument` | variadic |

No test killed zero runs except the string/void OPERAND rules, which all 11 agents implemented.

## Batch 2 (ACCEPTED, 2026-09-24): 5 of 10

10 Nova, all evaluated by Nova. Every run passed the 1097-test baseline. Auto Review: Approved,
Description 3/3, Tests 3/3, Solution 3/3, one Low (the bounded while-loop test keeps a 5 s timeout).

| Run | Verdict | New tests failed | Cause | Source files | Non-blank +LOC | Prompt tokens |
|---|---|---|---|---|---|---|
| Nova #10 | PASS_LEGITIMATE | 0/150 | - | 4 | 232 | 8.09M |
| Nova #9 | PASS_LEGITIMATE | 0/150 | - | 3 | 296 | 8.57M |
| Nova #6 | PASS_LEGITIMATE | 0/150 | - | 3 | 269 | 7.40M |
| Nova #4 | PASS_LEGITIMATE | 0/150 | - | 3 | 267 | 5.16M |
| Nova #3 | PASS_LEGITIMATE | 0/150 | - | 4 | 285 | 6.11M |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 3/150 | JTAG `tms` masked to 1 bit (accidental, L92) - sole cause | 4 | 275 | 7.45M |
| Nova #7 | FAIL_MISSED_REQUIREMENT | 4/150 | width narrowed before the delegate (F-52) - sole cause | 3 | 282 | 6.55M |
| Nova #2 | FAIL_MISSED_REQUIREMENT | 4/150 | width narrowed before the delegate (F-52) - sole cause | 4 | 393 | 4.85M |
| Nova #1 | FAIL_MISSED_REQUIREMENT | 5/150 | stale folder identities (F-31) + `tms` | 3 | 335 | 6.05M |
| Nova #8 | FAIL_MISSED_REQUIREMENT | 5/150 | stale folder identities (F-31) + `tms` | 4 | 263 | 8.09M |

Per-test kills: the three JTAG tests 3 each; `test_logical_operators_with_a_literal_operand_produce_one_or_zero`
and `test_zero_minus_a_variable_is_the_negation` 2 each; the four delegate-input tests
(`test_call_arguments_are_evaluated_left_to_right`, `test_a_function_argument_is_a_value_of_the_domain`,
`test_a_call_made_as_a_statement_receives_values_of_the_domain`, `test_the_last_statement_decides_a_predicate`)
2 each. **141 of 150 killed nothing**, including every static-validation test, both literal matrices,
the AP/DP widths and the JTAG byte-response test (0/11 on replay while undocumented).

The replay had projected 2/11 for this suite (byte test excluded); the batch read 5/10. The gap is
L35: meta.md changed between batch 1 and batch 2.

## Platform solution review, round 1 (on the 107-eff core slice)

Verdict FAIL. Solution Comprehensiveness 1/3, Code Quality 3/3. Two high findings, both real:

1. **A function result was not reduced to the domain.** `fncall` turned `None` into `0` and returned
   everything else untouched, so a delegate returning `-1` compared as Python `-1`. The slice had
   DELETED that normalisation as dead code (slice decision 5) on the argument that `Scope.set`
   already normalised. The reviewer is right and the slice was wrong: a call result reaches a
   comparison, a shift count and an argument without ever passing through a scope store.
2. **Compound assignment evaluated its left value after its right operand.** `visit_children` ran
   the whole tree first, so `x += (x = 2)` read `x` as `2` and stored `4` instead of `3`.

The review also listed 10 coverage suggestions (untested / single-point / not-discriminating
requirements) and one category warning (picker suggested `bugfix`).

## What changed in round 2

| Change | Why | Tests |
|---|---|---|
| A call's result and its arguments are values of the domain | review finding 1 | `test_a_function_result_below_zero_...`, `..._wider_than_the_domain_...`, `..._before_it_is_a_shift_count`, `test_a_function_argument_is_a_value_of_the_domain` |
| Compound assignment reads the variable before the right hand side | review finding 2 | `TestSequenceCompoundAssignment` (4) |
| One operator model (`BinaryOperator` descriptors) drives folder + interpreter | the two consumers each hand-coded the same polarity and identity knowledge | whole suite; `M21`-`M23` |
| Only an integer is a value: a string or a call that returns nothing is rejected before the code runs | the domain had no answer for a non-value operand; `1 + "a"` crashed with `TypeError` after the read had happened | `TestSequenceExpressionOperands` (7) |
| A transfer carries as many bits as its width names (`functions.py`) | the width model creates the gap: a 64-bit value handed to a 32-bit write | `TestSequenceTransferWidth` (6) |
| Every reduction point made load-bearing (operand reduction removed from `evaluate_binary`, the redundant scope re-read removed from `assign_expr`) | two mutants survived because three points normalised the same value | `M14`, `M17`, `M20` now kill |
| Coverage for shift-result wrap, unsigned division and remainder, zero divisors, all six comparisons, counts 65/200, left-to-right order per operator, mixed nested effects, repeated `IfControl` | the 10 coverage suggestions | see the trace below |
| `meta.md` reframed away from "today it is inconsistent" | category picker suggested `bugfix`; the user's standing preference is `feature-request` | n/a |

Tests went 30 -> 84 cases (64 functions). Solution went 107 -> 236 human-effective across 4 files.

## Requirement to test trace (FP light-bulb pre-check)

Every sentence of meta.md, and the test that fails without it. Every row is a new-mode test unless
marked base.

| meta.md requirement | Test |
|---|---|
| every value is an unsigned 64 bit integer (literal) | `test_a_literal_wider_than_the_domain_is_reduced` |
| ... (variable), a negative value reads back unsigned | `test_scope_stores_variables_in_the_value_domain`, `test_compound_subtraction_below_zero_wraps` |
| ... (intermediate) | `test_intermediate_results_are_reduced_before_the_next_operator` |
| ... (function result) | `test_a_function_result_below_zero_is_reduced_to_the_domain`, `..._wider_than_the_domain_is_reduced` |
| ... (assignment value) | `test_an_assignment_expression_is_worth_the_stored_value`, `test_a_compound_assignment_is_worth_the_stored_value` |
| addition wraps | `test_addition_wraps_at_the_width` |
| subtraction wraps | `test_literal_subtraction_below_zero_wraps`, `test_zero_minus_a_variable_is_the_negation`, `test_compound_subtraction_below_zero_wraps` |
| multiplication wraps | `test_multiplication_wraps_at_the_width`, `test_a_compound_assignment_wraps_into_the_domain` |
| shifts wrap | `test_a_shift_result_wider_than_the_domain_wraps` |
| comparisons are unsigned | `test_every_comparison_of_a_wrapped_value_is_unsigned` (6 cases: `<` `<=` `>` `>=` `==` `!=`) |
| division is unsigned | `test_division_of_a_wrapped_value_is_unsigned`, `test_remainder_of_a_wrapped_value_is_unsigned` |
| a shift by 64 or more produces zero | `test_shift_count_at_the_width_produces_zero`, `test_shift_counts_beyond_the_width_produce_zero` (65, 200), `test_shift_by_a_wrapped_count_produces_zero`, `test_a_function_result_is_reduced_before_it_is_a_shift_count` |
| division and remainder by zero produce zero | `test_division_and_remainder_by_zero_produce_zero` (literal, computed, and effectful dividend) |
| a call evaluates its arguments left to right (3+ positions) | `test_every_argument_of_a_call_is_evaluated_left_to_right` |
| a sequence function receives the unsigned form of every value it is passed | `test_a_function_argument_is_a_value_of_the_domain`, `test_a_variadic_argument_is_a_value_of_the_domain`, `test_a_call_made_as_a_statement_receives_values_of_the_domain` |
| WriteAP, WriteAccessAP and WriteDP reduce the word they write to 32 bits | `test_an_ap_register_write_is_reduced_to_32_bits`, `test_an_access_port_memory_write_is_reduced_to_32_bits`, `test_a_dp_register_write_is_reduced_to_32_bits` |
| a written word is reduced to the transfer width | `test_a_written_word_is_reduced_to_the_width_of_the_transfer` |
| the bits a function sends or reports for a bit count are reduced to it | `test_a_sequence_of_bits_is_reduced_to_the_count_it_carries`, `test_a_jtag_sequence_reduces_what_it_sends_and_what_it_returns`, `test_every_bit_count_reduces_to_the_bits_it_carries` (0, 1, 16), `test_a_jtag_sequence_reduces_at_other_counts` (4, 16) |
| a width of 64 or more carries the whole value | `test_a_transfer_as_wide_as_the_domain_carries_the_whole_value`, `test_a_bit_count_beyond_the_domain_carries_the_whole_value` |
| only an integer is a value (string) | `test_a_string_operand_is_rejected_before_anything_runs`, `..._as_the_operand_of_a_unary_operator`, `..._as_the_value_of_a_variable` |
| a call that returns nothing cannot be a stored or assigned value | `test_a_call_that_returns_nothing_is_rejected_as_a_stored_value`, `test_a_call_that_returns_nothing_is_rejected_as_an_assigned_value` |
| a call returning a string is rejected as an operand, integer argument or conditional branch | `test_a_call_that_returns_a_string_is_rejected_as_an_operand`, `test_a_call_that_returns_a_string_is_rejected_by_a_parameter_that_takes_an_integer`, `test_a_call_that_returns_a_string_is_rejected_as_a_conditional_branch` |
| a string cannot reach a parameter that takes an integer | `test_a_string_is_rejected_by_a_parameter_that_takes_an_integer` |
| a probe can report JTAG bits as bytes, least significant first | `test_a_jtag_sequence_reads_bits_a_probe_reports_as_bytes` |
| an identity literal keeps its operand, its calls and the unsigned value | `test_an_identity_literal_keeps_its_operand_and_calls` (12 forms) |
| a non-identity literal gives the same value and calls as a variable, for every operator | `test_every_operator_gives_a_literal_the_value_of_a_variable` (25 rows) |
| an integer literal never changes what an expression is worth or which calls it makes | `test_a_literal_operand_behaves_like_a_variable_holding_it` (6 simplifications) |
| a string or a call that returns nothing cannot be an operand or an argument | `test_a_call_that_returns_nothing_is_rejected_as_an_operand`, `..._as_an_argument`, `..._as_a_variadic_argument`, `..._as_a_conditional_branch` |
| only an integer is a value (string as an argument) | `test_a_string_is_rejected_as_a_variadic_integer_argument` |
| reported before any of the code runs | the two tests above assert an empty call log |
| the last statement decides a multi-statement predicate | `test_the_last_statement_decides_a_predicate` |
| a predicate whose last statement produces no value (declaration, void call) is false | `test_a_predicate_that_produces_no_value_is_false` |
| such a call is still valid as a statement | `test_a_call_made_as_a_statement_receives_values_of_the_domain`, `test_a_call_that_produces_a_value_is_a_valid_predicate`, `test_a_call_result_flows_into_the_surrounding_expression` |
| `&&` evaluates its right operand only when the left is non-zero | `test_conjunction_evaluates_the_right_operand_only_when_the_left_is_true`, `test_a_deciding_literal_on_the_left_skips_the_right_operand` |
| `\|\|` only when the left is zero | `test_disjunction_evaluates_the_right_operand_only_when_the_left_is_false` |
| a conditional evaluates only the branch it selects | `test_ternary_evaluates_only_the_selected_branch` |
| every other operator evaluates both operands, left first | `test_both_operands_are_called_left_to_right` (16 operators), `test_call_arguments_are_evaluated_left_to_right` |
| a compound assignment reads its variable first | `test_a_compound_assignment_reads_the_variable_before_the_right_hand_side` |
| `&&` and `\|\|` produce 1 or 0 | `test_logical_operators_with_a_literal_operand_produce_one_or_zero` |
| treat each side of an operator as a full subexpression | `test_call_nested_inside_a_discarded_operand_still_runs`, `test_conjunction_nested_in_a_disjunction_keeps_both_calls` |
| a call evaluates its arguments left to right | `test_call_arguments_are_evaluated_left_to_right` |
| a string or a call that returns nothing cannot be a branch of a conditional expression | `test_a_call_that_returns_nothing_is_rejected_as_a_conditional_branch`, `test_an_unselected_conditional_branch_is_rejected_too` (the branch that is NOT selected, so a run-time-only check fails), and through a control predicate: `test_a_predicate_branch_that_produces_no_value_is_rejected`, `test_a_predicate_branch_that_is_a_string_is_rejected` |
| calls and assignments are effects, exact identity/count/order | `TestSequenceExpressionEffects` (8 + 16 parametrized), `test_effects_on_both_sides_of_a_discarded_operand_all_run_in_order`, `test_discarded_assignment_still_updates_the_variable`, `test_multiply_by_a_literal_zero_calls_the_operand` |
| pure value-only subexpressions may still be simplified | base mode: the repo's own `TestConstantFolder` (30 rows), which reds if a solution stops folding pure operands |
| re-evaluating a predicate repeats its calls | `test_while_predicate_short_circuits_on_the_final_evaluation`, `test_running_a_conditional_twice_repeats_its_predicate_calls` |

No test asserts anything meta.md does not state. The one codebase-inferable requirement remains
division by zero yielding zero (visible in the base operator table), and meta.md states it anyway.

## Platform precheck, round 2 (on the 236-eff artifact)

Solution Quality FAIL again, one high finding, and it is real:

- **Control predicates bypassed the value-kind validation.** `IfControl("DAP_Delay(1)")` passed the
  checker, ran the void call and was coerced to zero. Verified locally before changing anything:
  the void-call predicate did run the call; `1 ? DAP_Delay(1) : 2` as a predicate did too. The
  reviewer's second example, `IfControl('"text"')`, was already rejected (by the repo's own
  pre-existing `expr_stmt` string check), so only the void-call and conditional-branch halves of
  the finding were live.

Four more gates, all warnings or advisory:

| Gate | Finding | Resolution |
|---|---|---|
| Problem and tests are good quality | **FAIL**: `TestSequenceConstantFolding` used `Parser`, `_ConstantFolder` and `LarkTree` to assert AST shape rather than behaviour | Class deleted. Its two claims (a call and an assignment are never folded away) are already asserted behaviourally by the effect tests, and the folds that MUST still happen stay pinned by the repo's own `TestConstantFolder` in base mode |
| Test patch sanity | WARNING: base mode ran newly added tests (`test_fold_computed_operand`) from the modified existing file | Those five rows removed. `test.patch` now only DELETES three rows from that file, so base mode contains no new test |
| Problem and tests are aligned | WARNING: call-argument evaluation order not stated | meta.md now says a call evaluates its arguments left to right |
| Description contains only necessary information | HIGH: drop the "already correct sequences keep working" sentence; MEDIUM x2 and LOW: drop three clauses as restatement | HIGH applied. The two MEDIUM clauses and the LOW clause were KEPT: "a value handed to a sequence function is a value of this domain" is the only sentence covering `test_a_function_argument_is_a_value_of_the_domain` (the transfer-width rule does not reach the recording delegate), and "which is the value the variable ends up holding" defines what an assignment is worth. Fairness outranks brevity on an advisory gate. The effect paragraph was rewritten tighter at the author's direction |

Five advisory coverage suggestions: three added (a `Write16` case, a positive oversized argument
and a bit count of exactly 64 carrying a wrapped value); two declined and why: `Read32("a")` is
already rejected on BASE by the repo's own argument-type check, so it would be a base-passing test
in the new file, and a `default_sequences.yaml` end-to-end trace is what base mode already is.

## What changed in round 3

| Change | Why | Tests |
|---|---|---|
| A control predicate is evaluated for its value: `Control` tells the `Interpreter`, which tells the `SemanticChecker`, which requires the last statement to be an expression statement producing a value | review finding | `TestSequenceControlPredicates` (6) |
| Both branches of a conditional expression must be values | review finding (the robust form) | `test_a_call_that_returns_nothing_is_rejected_as_a_conditional_branch`, `test_a_predicate_branch_that_produces_no_value_is_rejected`, `test_a_predicate_branch_that_is_a_string_is_rejected` |
| `_expression_kind` no longer recurses into a conditional | the branch check now covers it at the point the branches are written, and a second path would be a redundant normalisation of the kind the last round's survivors came from | `M7` |
| Internals-based folding tests deleted, in both files | quality gate FAIL + base-mode warning | n/a |
| `Write16`, a positive oversized argument, a bit count of exactly 64 | advisory coverage | 3 assertions added to existing tests |

Tests went 84 -> 90 cases (69 functions). Solution went 236 -> 251 human-effective.

## Platform precheck, round 3 (on the 251-eff artifact)

Solution Quality FAIL, one high finding, and it is real:

- **Variadic integer arguments bypassed the value check.** The repo's argument loop breaks out of
  the signature walk at a `VAR_POSITIONAL` parameter, so `Message(0, "%d", DAP_Delay(1))` was
  accepted: the void call ran and was coerced to zero. Round 2 had added `_require_value` inside
  that loop, which covered every FIXED parameter and nothing past the varargs break.

Two advisory coverage suggestions, both taken:

| Suggestion | Resolution |
|---|---|
| The conditional-branch cases all select the invalid branch, so a lazy run-time checker would pass | `test_an_unselected_conditional_branch_is_rejected_too` puts the void call and the string in the branch that is NOT selected |
| The bit-sequence cases only use count 8 and counts >= 64, so an implementation special-casing 8 would pass | `test_every_bit_count_reduces_to_the_bits_it_carries` (counts 1, 16 and 0) and `test_a_jtag_sequence_reduces_at_other_counts` (counts 16 and 4, sent and reported) |

## What changed in round 4

| Change | Why | Tests |
|---|---|---|
| Every argument a varargs parameter receives is checked against it | review finding | `test_a_call_that_returns_nothing_is_rejected_as_a_variadic_argument`, `test_a_string_is_rejected_as_a_variadic_integer_argument`, `test_a_variadic_argument_is_a_value_of_the_domain` |
| The per-argument check extracted into `_check_argument`, used by the fixed walk and the variadic tail | one rule, one place; the bug was that the rule existed in only one of the two paths | `M9`, `M28` |
| Unselected conditional branches, bit counts 0, 1, 4 and 16 | advisory coverage | 3 new tests |

An unannotated varargs parameter (the repo's own `valid_fn_varg(a: int, *vargs)`) is still
unchecked, exactly as a fixed parameter without an annotation is; that is what keeps the repo's
own `valid_fn_varg(123, x, q + 1, "hi there", 99)` test passing in base mode.

Tests went 90 -> 96 cases (75 functions). Solution went 251 -> 259 human-effective.

## Batch 1 diagnosis and the cut (round 5)

The failures are not spread evenly: three tests for ONE rule killed 8 of 11 runs, and both
near-misses (Nova #5 and #8) failed nothing else. That rule was "a value is required for the
predicate of a conditional or a loop", added in round 3 to answer a reviewer finding. The rest of
the static-validation axis cost nothing by comparison: every agent implemented the string and
void-call rules for operands.

So the cut is exactly that rule, and nothing else:

- `require_result_value` and the `produces_value` flag through `Control` -> `Interpreter` ->
  `SemanticChecker` are gone.
- The conditional-BRANCH checks stay. No agent failed those, and they are what the round-3
  reviewer actually called the robust form.
- meta.md now closes the hole by DECLARING it rather than checking it: "Calling such a function as
  a statement of its own stays valid, including when that statement is the whole of a conditional
  or loop predicate." A predicate that produces nothing is false, which is also what the base
  engine does, so there is no unstated behaviour left for a reviewer to find.
- The "cannot be used where a value is required" promise is narrowed to the positions that are
  actually checked: "cannot be an operand, an argument, or a branch of a conditional expression".
  The generic phrasing is what let the round-3 reviewer point at predicates.

Two description clauses were also made concrete, since a full-price batch was unavoidable anyway
and the call/scope boundary was the second-biggest killer: "A variable set to a negative value
reads back as the unsigned form of it, and a sequence function receives the unsigned form of every
value it is passed." Same requirement, stated as the observable consequence. Its effect on the
pass rate cannot be measured by replay (L35: the harness measures a TEST delta, never a
DESCRIPTION delta), so it is not counted in the 18% below.

Also in this round, from the Auto Review (verdict: Approved with notes):

| Note | Resolution |
|---|---|
| T3/T4 Medium: no JTAG return assertion at a count of 64 or more | `test_a_jtag_sequence_at_the_domain_reports_the_whole_value` (counts 64 and 72). Asserted together with the SENT direction at the same count, because the reported value alone passes on base |
| S4 Low: `_format_atom` left dead after the interpreter rewrite | Removed |

## Replay: the measured effect of the cut

Every saved agent solution re-run against the trimmed suite, in a clean clone at BASE, with the
agent's own test edits excluded exactly as the grader does (`worktrees/_pyocd-tools/replay.py`):

| Run | Before | After the cut |
|---|---|---|
| Nova #8 | 3 failed | **PASS** |
| Nova #5 | 3 failed | **PASS** |
| Nova #4 | 5 failed | 2 failed (scope, variadic string) |
| Vega #1 | 2 failed | 3 failed (JTAG only; the added count-64 case) |
| Nova #7 | 4 failed | 4 failed (call boundary + scope) |
| Nova #10, #1 | 7 failed | 4 failed each (call boundary + scope) |
| Nova #6 | 8 failed | 5 failed |
| Nova #9, #2 | 6, 9 failed | 6 failed each |
| Nova #3 | 8 failed | 6 failed |

**2 of 11 = 18%**, baseline 1097 passed in all 11 replays. This is a paired re-measurement on the
same solution population, so it is what a re-eval would report; a fresh batch will vary. The
remaining margin sits on Nova #4 (2 failures) and Vega #1 (JTAG only) - if a later batch reads 0,
those are the two levers, and dropping the bit-sequence half of the transfer rule is the measured
+1 (27%). Keeping it was a deliberate call: the transfer contract stays whole and the Auto
Review's JTAG note stays answered.

## Round 6 (post-cut Solution Quality review)

Solution Quality FAILED on two findings, both real:

1. **A declaration used as a predicate ran and was silently false.** Round 5 blessed a void-call
   predicate but said nothing about a declaration, so the reviewer read "only an integer is a
   value" into it. Same "every site but one" shape as rounds 1, 3 and 4 - this time in the
   contract text rather than the code. Re-adding the REJECTION is what took batch 1 to 0/11 (Nova
   #5 and #8 both failed the declaration test), so it is closed the way round 5 closed the void
   call: one uniform rule in meta.md, "a conditional or loop predicate is true when its last
   statement produces a non-zero value, and a last statement that produces no value, such as a
   declaration or a call to a function that returns nothing, makes it false." That is what the base
   engine already does, so it costs agents nothing, and `test_a_predicate_that_produces_no_value_is_false`
   pins it (void-call if, void-call while and declaration if, made to fail on base through the
   unsigned argument each call receives).
2. **`DAP_JTAG_Sequence` could not consume a real CMSIS-DAP response.** Verified: the probe API
   documents `Optional[int]`, but `cmsis_dap_core.jtag_sequence` returns `resp[2:]`, which is
   `bytes` from the hidapi and pyusb backends and a list of ints from pywinusb. Base handed that
   byte sequence straight into the engine; the round-2 width mask made it a `TypeError` instead.
   `dap_jtag_sequence` now converts a byte or int-list response little-endian before masking.

**The test for finding 2 does NOT ship, and that is measured, not guessed.** Replaying all 11 saved
solutions with a byte-response test added: **0 of 11** - it killed every run, and both near-misses
failed on that test alone. No agent anticipates a probe returning bytes. The fix stays in the
reference solution (correct for real hardware, and what the reviewer asked for); the test would be
the difference between 0% and 18%.

Coverage suggestions: void-call predicates accepted (covered by the new predicate test); 3+ argument
order (`test_every_argument_of_a_call_is_evaluated_left_to_right`, cost 0 in the replay); a string in
a fixed int argument (declined again - the repo's own argument-type check already rejects it on
base, so it would be a base-passing test in the new file).

Replay after round 6: **2 of 11 = 18%**, unchanged, baseline 1097 green in all 11.

## Round 7 (Auto Review: Revision Requested, Tests 1/3)

Description 3/3, Solution 3/3, Tests 1/3 on seven High coverage gaps and one Medium. Every
requested test was written as a candidate and REPLAYED against the eleven saved batch-1 solutions
before any of it shipped:

| Gap | Candidate test | Runs it newly kills | Near-misses #5, #8 | Shipped? |
|---|---|---|---|---|
| void call as a whole initialiser | `test_a_call_that_returns_nothing_is_rejected_as_a_stored_value` | none | survive | yes |
| void call as a whole assigned value | `test_a_call_that_returns_nothing_is_rejected_as_an_assigned_value` | none | survive | yes |
| `WriteAP` 32-bit | `test_an_ap_register_write_is_reduced_to_32_bits` | 4, all already failing | survive | yes |
| `WriteAccessAP` 32-bit | `test_an_access_port_memory_write_is_reduced_to_32_bits` | same 4 | survive | yes |
| `WriteDP` 32-bit | `test_a_dp_register_write_is_reduced_to_32_bits` | same 4 | survive | yes |
| last statement decides a multi-statement predicate (Medium) | `test_the_last_statement_decides_a_predicate` | already-failing runs + Vega (it rejects void predicates - a real contract violation) | survive | yes |
| SWD `DAP_WriteABORT` 32-bit | `test_an_abort_write_is_reduced_to_32_bits` | **both near-misses, on this test alone** | killed | **no - cut from contract and solution** |
| JTAG TDO as list/bytes | measured round 6 | **every run** | killed | **no - contested, see below** |

**`DAP_WriteABORT`:** cut in all three places. The reference no longer masks it, and meta.md now
scopes the width rule to "a word written by one of the Write functions", which the abort command
is not (it is a `DAP_` probe command, like `DAP_Delay`). No reference hunk and no contract sentence
is left for a reviewer to find untested.

**JTAG list/bytes (recommended: contest).** This gap cannot be closed with a test without making
the problem unsolvable (0/11, measured), and it cannot be cut, because without the conversion the
round-1 function-result rule turns a real CMSIS-DAP response into a `TypeError`, which the round-6
Solution Quality reviewer already FAILED. The case against requiring it:

- The probe interface documents `jtag_sequence(...) -> Optional[int]` ("@return Either an integer
  with TDI bit values, or None"). The byte form is an undocumented quirk of one backend layer
  (`cmsis_dap_core.jtag_sequence` returns `resp[2:]`), and the description says nothing about probe
  backends. A hidden test for it would enforce a requirement a solver cannot learn from the
  description or from the documented API, which is exactly what the fairness rules forbid.
- The conversion exists only so the reference does not regress real hardware relative to base.
  It is correct, the round-6 reviewer asked for it, and Solution scored 3/3 with it.
- Measured cost of the test: the replay goes from 2/11 to 0/11, and both near-misses fail that
  test and nothing else.

Also applied two description edits the author requested: the opening now leads straight into the
rules ("...so that writing an operand as an integer literal never changes what an expression is
worth or which calls it makes"), and the transfer rule is two sentences.

Replay after round 7: **2 of 11 = 18%**, baseline 1097 green in all 11.

## Round 8 (Solution Quality: two more boundary sites)

1. **A `-> str` delegate function was classified as a value.** Fixed in `_function_result_kind`: a
   `str` return is STRING, so `Label() + 1` is rejected before the call. Test
   `test_a_call_that_returns_a_string_is_rejected_as_an_operand` - replay cost 0 (fails only
   Nova #4 and #3, both already failing).
2. **`DAP_WriteABORT` unmasked, again.** Round 7 scoped the width rule to "the Write functions",
   and the reviewer read `DAP_WriteABORT` as one of them by name. The advisory list also asked for
   read-side truncation, from the same general sentence ("Transfers keep only the number of bits
   their width names"). A general transfer principle keeps producing one more site each round,
   and the abort test is measured at 0/11. **Author decision: replace the general sentence with a
   closed list** naming exactly the functions the solution reduces - Write8/16/32/64 to that
   many bits, WriteAP/WriteAccessAP/WriteDP to 32, DAP_SWJ_Sequence (sent) and DAP_JTAG_Sequence
   (sent and reported) to their bit count, 64 or more keeping the whole value. Abort and reads are
   now plainly outside the contract, and the reference touches neither. Contract, solution and
   tests now cover the same set of functions.

Advisory coverage: the literal-substitution table was added as
`test_a_literal_operand_behaves_like_a_variable_holding_it` over the six simplifications that used
to drop an operand (`* 0`, `& 0`, `/ 0`, `% 1`, `&& 0`, `|| 1`); the four identity cases that pass
on base were left out. Replay cost 0. `Write32(0x10, "a")` declined for the fourth time (the repo's
own check rejects it on base).

Replay after round 8: **2 of 11 = 18%**.

## Round 9 (Auto Review: Description 1/3, Tests 1/3, Solution 3/3)

1. **P4 High - the string-argument sentence contradicted the repo.** "A string cannot be ... an
   argument" banned `Message`'s own `format` string. Real, and mine. Reworded so it names both
   sides (the carve-out lesson): a string, or a call returning nothing or a string, cannot be "an
   argument to a parameter that takes an integer"; "a parameter that takes a string, such as the
   format of Message, still takes one." No code or test change was needed, since the checker
   already made that distinction.
2. **T3/T4 High - JTAG byte responses, a third time.** This review explicitly weighed the round-7
   contest (the `Optional[int]` annotation) and rejected it, because the CMSIS-DAP path is
   reachable in production. The byte test killed every replayed run only because the requirement
   was UNDOCUMENTED - none of the eleven agents was ever told. So it is now STATED, literally and
   with an example (the parallel-phrasing lesson): "a probe can report them as bytes, least
   significant first, so the bytes 0x34 0x12 are the value 0x1234."
   `test_a_jtag_sequence_reads_bits_a_probe_reports_as_bytes` uses exactly the stated form
   (`bytes`), at counts 12 and 24.

Advisory coverage: a string reaching a parameter that takes an integer is now tested through a
string-returning call (`Write32(0x10, Label())`, which base accepts and runs, so the test fails on
base) together with the literal `Write32(0x10, "a")`. Replay cost 0. The "complete operator
surface" literal table was declined again: every remaining operator already keeps both operands
on base, so those cases pass on base and would be base-passing tests in the new file.

Author wording edit applied: SWJ and JTAG are now separate direct sentences. meta.md went over
the 500-word cap (517) with the new sentences and was trimmed to 493 by cutting framing words
only; no tested requirement lost a sentence.

**The replay number now needs two readings:**

| Suite | Replay over the batch-1 solutions |
|---|---|
| everything except the byte test | **2 of 11 = 18%** |
| with the byte test | 0 of 11 |

The second row is NOT a prediction. It measures agents that never saw the byte sentence, and a
replay cannot measure a description delta (L35). The requirement is now two lines of stated,
exemplified work in a function every near-miss already edits correctly. The honest risk: if a
fresh agent skips it, it fails. Fallback if batch 2 reads 0: withdraw the byte form from the
contract and solution together and take the Tests-band hit.

## Round 10 (Solution Quality: a string-returning call as a statement crashed)

Real, and I caused it in round 9: the checker allowed a `-> str` call as a standalone statement,
but the interpreter still pushed its result through `to_value` and raised `TypeError`. The
reviewer asked for a runtime fix plus tests for `Label();` and for a predicate ending in one.

**Both tests killed every replayed run** - Nova #5 and #8 failed on those two alone - because the
batch-1 agents crash on a string result exactly as my reference did. That made me check whether a
string-returning sequence function exists at all. It does not: all 23 public sequence functions
in `functions.py` return `int` and all 16 others return `None`, and the delegate's own docstring
says a function with a fixed result of 0 "should return None", which the interpreter converts to
0. The string-return path existed only for a hypothetical delegate invented in the round-8 review.

**So the path was cut in all three places** (the ratchet lesson). meta.md opens the rule with the
repo's real boundary - "Every sequence function returns an integer or nothing, and only an integer
is a value" - which answers the round-8 finding at its root rather than patching one more site.
The solution loses the `str` classification and keeps the original `None -> 0` result handling.
The four string-return tests went, and the fixed-parameter string test now fails on base through
a string-valued conditional (`Write32(0x10, 1 ? "a" : 2)`) instead of `Label()`.

Advisory coverage: the identity-literal matrix the review kept asking for is added in a form
that fails on base - `test_an_identity_literal_keeps_its_operand_and_calls`, twelve forms in both
operand positions (`x + 0`, `0 + x`, `x - 0`, `x | 0`, `0 | x`, `x ^ 0`, `0 ^ x`, `x << 0`,
`x >> 0`, `x * 1`, `1 * x`, `x / 1`), each compared with the same expression through a variable
AND against the absolute unsigned value, which base gets wrong. Replay cost 0 (only Nova #9, already
failing).

| Suite | Replay over the batch-1 solutions |
|---|---|
| everything except the byte test | **2 of 11 = 18%** |
| with the byte test | 0 of 11 (not predictive: those agents never saw the byte sentence) |

## Round 11 (Solution Quality: string-returning calls must be rejected after all)

The reviewer overrode the round-10 boundary sentence ("every sequence function returns an integer
or nothing") and asked again for a `-> str` delegate to be rejected wherever a value is required.
That makes three rounds on one question, and the demands only looked contradictory:

| Round | Demand | What it broke |
|---|---|---|
| 8 | classify `-> str` returns as STRING | round 10: `Label();` as a statement crashed at run time |
| 10 | `Label();` must not crash | I cut the string path and bounded the contract instead |
| 11 | classify `-> str` returns as STRING | (this round) |

Both demands fit together, and the replay had already shown the damage came from the TESTS for
the statement case, not the code. So the solution now does both:

- **Static:** `_function_result_kind` classifies a declared `str` return as STRING, so it is
  rejected as an operand, an integer argument and a conditional branch before anything runs.
- **Run time:** `fncall` reduces an integer result and turns anything else into no value (zero) in
  the same expression that already handles `None`. There is no separate string branch.
- **Contract:** the value rule names string-returning calls again, and the statement rule is
  scoped to "a function that returns nothing". What a string-returning call does as a bare
  statement is deliberately unstated, so no passing agent can be an FP on it and nothing tests it.

Tests: one per value-required position for a `-> str` delegate (operand, integer parameter,
conditional branch). Replay cost 0 - they fail only Nova #4 and #3, both already failing.

Advisory coverage: the full literal-versus-variable matrix is added as
`test_every_operator_gives_a_literal_the_value_of_a_variable` - all 16 operators with a non-identity
literal in both positions, expected values computed as plain unsigned arithmetic independently of
the solution. The operand is `1 - Read32(...)` rather than `0 - Read32(...)`, because base's old
fold rewrote `0 - x` to `x` and made most rows agree on base. Seven rows base still gets right for
any operand (`==`/`!=`/`&` with 3, and `3 - x`) were dropped; 25 rows remain, all failing on base.
Replay cost 0.

Replay (byte test excluded, as before): **2 of 11 = 18%**. Mutations: 25 of 25, with M29 for the
STRING classification. The run-time "anything else is no value" path has no mutant: no test runs
a string-returning call as a bare statement, which is the deliberate consequence of not stating it.

## Local validation (round 11)

Clean room: fresh clone of BASE in `worktrees/pyocd-cleanroom` (asserted at BASE with `values.py`
absent before applying anything), image built from the submission Dockerfile,
`docker run --network none`. Procedure saved as `worktrees/_pyocd-tools/cleanroom.sh`.

| Configuration | mode | user | tests | failures | runs | identical |
|---|---|---|---|---|---|---|
| test.patch only | base | 1000 | 1138 | 0 | 3 | yes |
| test.patch only | new | 1000 | 150 | 150 | 3 | yes |
| test.patch + solution.patch | base | 1000 | 1138 | 0 | 3 | yes |
| test.patch + solution.patch | new | 1000 | 150 | 0 | 3 | yes |
| test.patch + solution.patch | new | 0 (root) | 150 | 0 | 1 | yes |
| test.patch + solution.patch | new | 4242 (unmapped) | 150 | 0 | 1 | yes |

Every one of the 150 new cases fails on base and none passes there. JUnit ids 150 unique, no `::`.
Both patches apply and reverse cleanly.

## Mutation self-check (FP prevention)

25 single-point mutations, each applied to a pristine copy of the solution, each verified to have
landed, each run against BOTH modes. **25 of 25 killed.** (Four control-predicate mutants were
retired in round 5 along with the rule they targeted.) The harness lives at
`worktrees/_pyocd-tools/mutate.py` (moved out of the scratchpad after that directory was wiped
mid-session) and now prints ANCHOR MISSING loudly, because a stale anchor silently reads as a
survivor.

| # | Mutation | killed by |
|---|---|---|
| M1 | function result not reduced | 1 new |
| M2 | compound assignment reads after the right hand side | 1 new |
| M3 | the value check ignores a call that returns nothing | 2 new |
| M4 | transfer width has no domain clamp | 1 new |
| M5 | write32 does not reduce to the transfer width | 1 new |
| M6 | jtag sequence does not reduce what it reports | 1 new |
| M7 | the conditional branches are not checked | new |
| M8 | a call with no declared result is treated as a value | 2 new |
| M9 | arguments are not required to be values | 1 new |
| M28 | variadic arguments are not checked | new |
| M10 | short circuit polarity flipped | 7 new + 5 base |
| M11 | folding ignores effects | 25 new |
| M12 | logical folding ignores effects | 5 new |
| M13 | effect analysis is not recursive | 1 new |
| M14 | integer literals are not reduced | 1 new |
| M15 | the scope does not reduce what it stores | 1 new |
| M16 | the out of range shift guard is removed | 1 new |
| M17 | binary results are not reduced | 9 new |
| M18 | the conditional expression evaluates both branches | 1 new |
| M19 | the interpreter does not short circuit | 7 new |
| M20 | unary results are not reduced | 1 base |
| M21 | a settled logical operator produces the wrong constant | new + base |
| M22 | the operand index mapping is swapped | new + base |
| M23 | a literal simplification ignores which side it is on | new + base |
| M29 | a call declared to return a string counts as a value | 3 new |
| M24-M27 | (control-predicate mutants, retired with the rule in round 5) | - |

M25 survived its first run: nothing covered a predicate whose last statement declares a variable
instead of producing a value. That was a genuine test gap, closed with
`test_a_predicate_that_only_declares_a_variable_is_rejected`. Two earlier survivors were fixed at
the source rather than with a test, because both were redundant normalisation:

- The value of an assignment was read back out of the scope after being stored. The stored value
  and the computed value are always equal (`Scope.set` raises rather than ignoring a write), so the
  read was dead. Removed.
- `evaluate_binary` reduced its operands as well as its result, which made the literal conversion
  point unreachable. The invariant is now that everything producing a value reduces it at its own
  boundary (literal conversion, scope store, operator result, call result, transfer width), so
  `evaluate_binary` reduces only its result and `_evaluate` only rejects a non-value.
