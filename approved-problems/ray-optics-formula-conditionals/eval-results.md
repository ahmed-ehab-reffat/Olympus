# ray-optics-formula-conditionals — eval results

Msgs = tool calls in the trajectory (the platform trajectory stores the solve as one step with N tool calls; no separate message count is exported). Files/LOC = the agent's solution-patch (includes any tests the agent added). Failed tests are the new suite (94 tests); baseline passed 1301/1301 in every run.

## Batch 1 (2026-09-13) - 10 Nova + 1 Vega, evaluator Nova - 0/11 PASS

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| 1 | Nova_Nova_1 (Nova) | FAIL_MISSED_REQUIREMENT | 70 | 11 | 604 | 13/94: 10 bare-switch + conj + identical_invalid + invalid_only_condition | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_2 (Nova) | FAIL_MISSED_REQUIREMENT | 63 | 11 | 711 | 17/94: 10 bare-switch + conj + self_comparison, identical_invalid, invalid_param_revive, disjunction_true_branch, wgsl_types, wgsl_raw_wrapped | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_3 (Nova) | FAIL_MISSED_REQUIREMENT | 59 | 11 | 530 | 15/94: 10 bare-switch + conj + nested_logical_call, nested_selector, wgsl_types, wgsl_raw_wrapped | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_4 (Nova) | FAIL_MISSED_REQUIREMENT | 68 | 11 | 654 | 16/94: 10 bare-switch + conj + disjunction_true_branch, invalid_only_operand, invalid_only_condition, wgsl_types, wgsl_raw_wrapped | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_5 (Nova) | FAIL_MISSED_REQUIREMENT | 51 | 7 | 488 | 16/94: 10 bare-switch + conj + self_comparison, identical_invalid, invalid_param_revive, wgsl_types, wgsl_raw_wrapped | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_6 (Nova) | FAIL_MISSED_REQUIREMENT | 91 | 11 | 649 | 16/94: 10 bare-switch + conj + comparison_in_fn_arg, self_comparison, identical_invalid, invalid_param_revive, narrowing_both_params | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_7 (Nova) | FAIL_MISSED_REQUIREMENT | 54 | 7 | 523 | 13/94: 10 bare-switch + identical_invalid, invalid_only_operand, invalid_only_condition (only run to pass conj) | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_8 (Nova) | FAIL_MISSED_REQUIREMENT | 101 | 11 | 518 | 16/94: 10 bare-switch + conj + self_comparison, identical_invalid, invalid_param_revive, invalid_only_operand, invalid_only_condition | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_9 (Nova) | FAIL_MISSED_REQUIREMENT | 95 | 11 | 709 | 15/94: 10 bare-switch + conj + disjunction_true_branch, invalid_only_operand, invalid_only_condition, wgsl_raw_wrapped | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Nova_Nova_10 (Nova) | FAIL_MISSED_REQUIREMENT | 88 | 11 | 600 | 16/94: 10 bare-switch + conj + self_comparison, identical_invalid, invalid_param_revive, invalid_only_operand, invalid_only_condition | Returned literal 0 for bare comparison/and/or/not derivatives (meta: 'is 0'); range invalid-only/identity traps | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |
| 1 | Vega_Nova (Vega) | FAIL_MISSED_REQUIREMENT | 45 | 11 | 630 | 12/94: 10 bare-switch + conj + nested_selector (closest run) | Returned literal 0 for bare comparison/and/or/not derivatives; dependent conjunction narrowing; nested selector | isComparisonOperator -> number(0); built a separate guardConditionSwitches pass for `if` only |

### Batch 1 aggregate

- Pass rate 0/11 = unsolvable-reject territory. Every evaluator marked description_clear=true, tests_deterministic=true, 'challenging but fair'.
- 10 tests failed in ALL 11 runs, every one a derivative switching-set test that asserts NaN for a BARE comparison / logical call at its switching point (e.g. `x < 1` at x = 1, line 442; `and(x > 0, x < 2)` at x = 2, line 484; `x < -x` at x = 0, line 553).
- All 11 agents wrote `if (isComparisonOperator(node.op)) return builder.number(0, "0")` and the same for and/or/not, while all 11 built switching guards for `if`. meta.md says 'The derivative of a comparison, `and`, `or` or `not` is 0'; the 'except on the switching set' clause attaches only to `if`. Same-reason unanimous failure = description under-specification, not difficulty.
- Second near-unanimous wall: conjunction_narrowing_composes_through_a_dependent_comparison 10/11 (line 811, maybeInvalid must be false in both conjunct orders; order independence is not stated).
- Spread traps (healthy distribution): identical_invalid 7, invalid_only_condition 6, self_comparison / invalid_param_revive / invalid_only_operand / wgsl_raw_wrapped 5, wgsl_types 4, disjunction_true_branch 3, nested_selector 2, nested_logical_call / fn_arg / narrowing_both 1.
- Long-horizon: tool calls 45-101 (median 68) clears the >=40 floor in every run.

## Batch 2 - prepared, not yet run (full-price fresh batch required: meta.md changed)

Harness prediction, grading the 11 batch-1 solutions against the batch-2 suite (89 tests):
3/11 = 27% pass (Nova_Nova_1, Nova_Nova_7, Vega_Nova). BASE 89/89 fail, REFERENCE 89/89 pass.

| Batch-1 run | Predicted on batch-2 suite | Remaining failures |
|---|---|---|
| Nova_Nova_1 | PASS | - |
| Nova_Nova_7 | PASS | - |
| Vega_Nova | PASS | - |
| Nova_Nova_8 | fail (2) | invalid_param_revive, self_comparison |
| Nova_Nova_9 | fail (2) | disjunction_true_branch, wgsl_raw_wrapped |
| Nova_Nova_10 | fail (2) | invalid_param_revive, self_comparison |
| Nova_Nova_3 | fail (4) | nested_comparison_in_comparison, nested_logical_call, wgsl_raw_wrapped, wgsl_types |
| Nova_Nova_4 | fail (4) | conjunction, disjunction_true_branch, wgsl_raw_wrapped, wgsl_types |
| Nova_Nova_5 | fail (4) | invalid_param_revive, self_comparison, wgsl_raw_wrapped, wgsl_types |
| Nova_Nova_6 | fail (5) | invalid_param_revive, fn_arg, conjunction, narrowing_both, self_comparison |
| Nova_Nova_2 | fail (6) | invalid_param_revive, conjunction, disjunction_true_branch, self_comparison, wgsl_raw_wrapped, wgsl_types |

This is a prediction for steering, not a result. Near a small-sample band edge only the fresh batch
counts (vrp-tsplib ran 22% then 50% on one artifact).

## Batch 2 (2026-09-13) - 10 Nova, evaluator Nova - 1/10 on tests, 0/10 clean (FP)

| Batch | Agent | Verdict | Msgs | Failed tests |
|---|---|---|---|---|
| 2 | Nova_Nova_1 (Nova) | FAIL_MISSED_REQUIREMENT | 73 | 3/89: self_comparison, invalid_param_revive, wgsl_raw_wrapped |
| 2 | Nova_Nova_2 (Nova) | PASS (FP-flagged) | 59 | 0/89 - PASS_LEGITIMATE on tests, FP-flagged (nested-if value over-guard; also order-dependent and-narrowing) |
| 2 | Nova_Nova_3 (Nova) | FAIL_MISSED_REQUIREMENT | 68 | 1/89: nested_logical_call |
| 2 | Nova_Nova_4 (Nova) | FAIL_MISSED_REQUIREMENT | 62 | 5/89: self_comparison, invalid_param_revive, disjunction_true_branch, wgsl_types, wgsl_raw_wrapped |
| 2 | Nova_Nova_5 (Nova) | FAIL_MISSED_REQUIREMENT | 60 | 3/89: disjunction_true_branch, wgsl_types, wgsl_raw_wrapped |
| 2 | Nova_Nova_6 (Nova) | FAIL_MISSED_REQUIREMENT | 88 | 2/89: wgsl_types, wgsl_raw_wrapped |
| 2 | Nova_Nova_7 (Nova) | FAIL_MISSED_REQUIREMENT | 65 | 4/89: nested_comparison_in_comparison, nested_logical_call, wgsl_types, wgsl_raw_wrapped |
| 2 | Nova_Nova_8 (Nova) | FAIL_MISSED_REQUIREMENT | 62 | 2/89: self_comparison, invalid_param_revive |
| 2 | Nova_Nova_9 (Nova) | FAIL_MISSED_REQUIREMENT | 55 | 6/89: contradictory_condition, self_comparison, invalid_param_revive, disjunction_true_branch, wgsl_types, wgsl_raw_wrapped |
| 2 | Nova_Nova_10 (Nova) | FAIL_MISSED_REQUIREMENT | 57 | 3/89: self_comparison, invalid_param_revive, random_ranges_sound |

- No unanimous wall; worst test 6/10 (wgsl_raw_wrapped). Tool calls 55-88, all above the 40 floor.
- FP battery (stated but untested): order-independent `and` narrowing 10/10 miss, nested-`if` value
  over-guard 8/10, invalid-only operand truth values 7/10, identity range 4/10, `1e308` derivative 4/10.
- Auto Review Tests 1/3: no behavioural WGSL check.

## Batch 3 - prepared, not yet run (full price: meta.md changed)

Redesigned suite, now 97 tests after the Auto Review revision (f32 rule, naga validation, no-space parsing, bare logical switching); earlier 93 tests (92 plus a dependent `or` narrowing test added from the Test Quality advisory; overlaps the `and` counterpart on the old solutions). Harness on the 21 old solutions is 0/21 but not predictive: the top
killers are the tests for the NEW top-level-only switching rule, which every old solution fails
because the old description demanded nested propagation. Setting those aside, 3/21 are clean.
Estimate for a fresh batch: roughly 10-20%, reasoned rather than measured.

Harness on the 97-test suite (old solutions, informative): WGSL agreement 0/21, naga validity 3/21,
no-space parsing 0/21, bare logical switching 1/21, dependent `or` narrowing 4/21, f32 rule 21/21
(new rule, not predictable). Clean apart from description-driven tests: 2/21.

Revision after Solution Quality (2026-09-14): the f32 rounding rule and its test are removed
(agreement is now scoped to f32-representable values), so the suite is 96 tests. The rule that every
old solution missed (21/21) no longer exists; the harness "clean apart from description-driven tests"
count (2/21) is unaffected, since the f32 test was already in that excluded set.

Revision (2026-09-14, feasibility): suite is 97 tests with
`a_later_operand_that_cannot_hold_leaves_the_branch_unselectable` added; reference LOC 329.

Scoping round (2026-09-14): the feasibility test was removed after it failed 14/21 old solutions (0/21
clean); meta.md now defines unselectable branches by two mechanisms only. Suite 96 tests, LOC 329.
Harness clean count apart from the top-level switching tests returns to 2/21.

Test Quality fix (2026-09-14): `generated_wgsl_agrees_with_the_closure_evaluator` now uses only
f32-exact points (74-point audit: doubles, f32-rounded and closure agree exactly); suite still 96 tests.

Environment fix (2026-09-14): the naga-wasi-cli validity test failed Verify Solution on the platform and
used an undeclared dependency; replaced by a self-contained WGSL operator and select-condition check
(reference and 21/21 old solutions pass it). Dockerfile back to the original. Suite still 96 tests.

## Batch 3 (2026-09-14) - 9 Nova + 1 Vega: 1/10 PASS, accepted

Same artifact as prepared above (96 tests, LOC 329, meta.md 499 words, original Dockerfile).

| Run | Verdict | New tests | Files | +LOC raw | Prompt tokens | Failed tests | Approach note |
|---|---|---|---|---|---|---|---|
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | 90/96 | 7 | 531 | 6.24M | far_apart, self_comparison, invalid_parameter, disjunction_true, wgsl_types, wgsl_raw | subtraction switching guard; no identical-comparison case; narrows `or` true; raw comparison over `vN` |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | 92/96 | 7 | 471 | 4.54M | function_argument, self_comparison, invalid_parameter, disjunction_composes | variadic args still `parseAdditive`; no identical-comparison case; no sequential `or` narrowing |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | 92/96 | 9 | 572 | 6.21M | self_comparison, invalid_parameter, wgsl_types, wgsl_raw | no identical-node case; raw binary without `asF32` |
| Nova_Nova_4 | FAIL_MISSED_REQUIREMENT | 91/96 | 7 | 529 | 5.65M | self_comparison, invalid_parameter, disjunction_true, wgsl_types, wgsl_raw | `conditionContexts` narrows `or` true via leftTrue; raw binary without `asF32` |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | 90/96 | 11 | 659 | 7.54M | self_comparison, invalid_parameter, disjunction_composes, disjunction_false, disjunction_true, random_ranges | narrowing only for two distinct bare parameters; wrong `or` truth paths |
| Nova_Nova_6 | FAIL_MISSED_REQUIREMENT | 93/96 | 7 | 598 | 5.88M | disjunction_true, wgsl_types, wgsl_raw | `or` desired-true narrows both alternatives; raw comparison without `.value` |
| Nova_Nova_7 | FAIL_MISSED_REQUIREMENT | 91/96 | 7 | 559 | 6.60M | far_apart, self_comparison, invalid_parameter, disjunction_true, wgsl_raw | subtraction guard; identical comparison; `or` true branch; raw lowering |
| Nova_Nova_8 | FAIL_MISSED_REQUIREMENT | 91/96 | 7 | 494 | 6.99M | function_argument, far_apart, self_comparison, invalid_parameter, disjunction_true | variadic `parseAdditive`; `guardNonzero(left - right)`; no identical case; `or` true narrowing |
| Nova_Nova_9 | FAIL_MISSED_REQUIREMENT | 94/96 | 7 | 516 | 7.81M | wgsl_types, wgsl_raw | near-miss: raw comparison reads wrapped `v4` as f32 despite its own `asF32` helper |
| Vega_Nova | PASS_LEGITIMATE | 96/96 | 12 | 713 | 2.89M | - | clean pass |

Per-test kills: self_comparison_branch_is_unselectable 7, an_invalid_parameter_does_not_revive_an_impossible_branch 7
(same runs), disjunction_does_not_narrow_the_true_branch 6, wgsl_raw_lowering_reads_wrapped_operands_as_values 6,
wgsl_types_agree_across_the_new_lowerings 5, far_apart_operands_are_not_a_switching_point 3,
comparison_inside_a_function_argument 2, disjunction_narrowing_composes_through_a_dependent_comparison 2,
disjunction_narrows_the_false_branch 1, random_conditional_ranges_are_sound 1. 86 of 96 killed nothing.
Prediction was "roughly 10-20%": measured 10%.

