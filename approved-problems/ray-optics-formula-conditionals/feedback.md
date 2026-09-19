# ray-optics-formula-conditionals — feedback / iteration log

## Summary

- Repo: ricktu288/ray-optics (JavaScript geometric-optics simulator, Apache-2.0, ★1774, solo maintainer, jest suites over the core; PR authors are translation bots and scene contributors, no competitor signatures).
- Base: e55947ecf4cc86724085ec07b774f85e4b7dea46 (2026-08-28, master HEAD at pick time).
- Feature: comparison operators, `if`, `and`, `or`, `not` in the formula language, carried through parser (incl. the statement splitter), closure evaluator, JS generator, WGSL generator (raw + wrapped lowering, guard profile, runtime), symbolic derivative (switching-set invalidity via nested guards) and the interval range estimator (truth sets, branch pruning, parameter narrowing composed through and/or/not and nested ifs).
- Hunt log: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-11.md` (second pick of the session). Design: `DESIGN.md`.

## Deliverables (round 1, 2026-09-11)

| File | State |
|---|---|
| BASE_COMMIT.txt | e55947ec... |
| meta.md | round 1 ~487 body words; round 2 488 after the trim and the unreachable-branch sentence, ASCII, frontmatter, feature-request |
| test.patch | test.sh (100755) + test/formula/conditionals-078515.test.js (round 1: 76 named jest tests, ~230 assertions, incl. a seeded random derivative check and a seeded random range-soundness check) |
| solution.patch | 7 files under src/core/formula |
| Dockerfile | olympus-base-typescript, `npm ci --ignore-scripts` (canvas is an optional native dep that only the scene tests need) |

## Harness

- base mode: `jest test/formula test/primitive test/propertyUtils test/sceneObjs` (the new file ignored). `test/scenes` is excluded: it needs the native `canvas` module (cairo), `sharp`, and the webpack `dist-node` bundle, none of which the platform image builds; it is unrelated to the formula subsystem.
- new mode: the single jest wrapper. JUnit via the image's global `jest-junit` (or a local one when present), with a synthetic failure XML if no testcase is produced.

## Local validation (round 1)

- Existing formula + propertyUtils suites: 229/229 pass with the solution.
- New suite: 76/76 with the solution; on base 75/76 fail (`FormulaParseError: Unexpected token "<"` / unknown function; the one passing on base is `assignment_inside_parentheses_rejects`, whose error is the same on both).
- LOC hook: human-effective 289 across 7 files (range-estimator 128, wgsl 61, parser 35, derivative 24, evaluator 19, js-gen 16, syntax 6).
- Clean-room Docker (fresh clone at base + test.patch, image built from the submission Dockerfile, `--network none --user 1000:1000`, 3 runs each):

| | base mode | new mode |
|---|---|---|
| without solution.patch | 1301/1301 pass, 3x identical | 75 of 76 fail, 3x identical |
| with solution.patch (git apply in container) | 1301/1301 pass, 3x identical | 76/76 pass, 3x identical |

- Both patches apply and revert cleanly in both orders on a clean checkout.
- Mutation sweep: 25 single-site mutations (chain check, statement splitter, NaN handling in both evaluators, `if` truthiness, WGSL `.value` on a raw select, comparison opcode map, `w_select` invalid condition, comparison/if/logic derivative guards, if-range union vs selectability, unselected-branch invalidity, no narrowing, closed vs strict bounds, missing negation, missing flip, `!=` narrowing, and/or branch composition, `<` strictness, `or` falsity, right-operand invalidity, `if` reserved). Every mutation kills at least one new test and regresses zero existing formula tests; three survived the first pass (`w_select` invalid-condition body, closed strict bounds, right-operand invalidity) and got tests, then were re-run and killed.
- Assertion-flip sweep (node shim, 227 assertion lines perturbed one at a time): every perturbation fails at least one test, apart from the NaN branch of the random range oracle, which no sampled expression reaches.

## Round 2 (2026-09-11) - platform precheck responses

Precheck came back with two FAILs plus two warnings before any batch was run. All four are addressed; the solver-visible surface (meta.md) changed in this round, so the first batch is still full price.

| Check | Verdict | Response |
|---|---|---|
| Verify Solution | FAIL - `assignment_inside_parentheses_rejects` passed on base | Deleted. `(x = 1)` rejects identically with and without the solution, so it discriminated nothing; the statement-splitter contract is still covered by the four assignment tests that do fail on base. New suite is 75 tests, all 75 fail on base. |
| Test Quality | FAIL - 10 of 76 unfair | All ten rewritten (below). |
| Solution Quality | FAIL - 2 high issues | Both fixed in the reference, each with a regression test. |
| Description | WARNING - unnecessary information | Dropped the `src/core/formula` path and the "Today `x < 1` is a parse error" sentence. Kept the consumer list, the three-evaluator agreement sentence and the transformation-stability sentence: tests assert all three, so cutting them would create exactly the unstated-requirement gap the Test Quality check punishes. |
| Title | FAIL - title/content mismatch | The platform Title field still held the shelved dropflow title. meta.md's own H1 and frontmatter Title were always correct; the field has to be reset in the submission UI. |

### The ten unfair tests

The finding was the same in every case: the assertions pinned a private ABI this task invented (`w_compare` / `w_select` / `w_logic` names, comparison opcode integers, argument wrapping, `vN` numbering, exact emitted source), none of which meta.md states or the base repo establishes. Replaced with observables that already exist at base:

- `createDagWgslSpecialization(...).guardProfile[node]` is base code (`createGuardProfile`) and already returns `"raw"` / `"wrapped"` per node from `maybeInvalid`. Asserting it tests exactly the stated contract (plain f32 when the range analysis proves the node can never be invalid, wrapped otherwise) and needs no invented name. Three tests: comparison, conditional, logic lowering.
- `assertWgslTypesAgree` reads the `var vN: f32|W =` declarations the base generator already emits and fails when an f32 statement consumes a W operand without `.value`, or takes `.value` of an f32. That is the type error the reviewer found, caught structurally instead of by template.
- `assertWgslCallsAreDeclared` fails when generated code calls a function that neither the generated code nor `WGSL_RUNTIME_CODE` declares. Name-agnostic: it only requires that whatever helpers a solution invents are actually emitted.
- `generated_javascript_uses_the_new_runtime_helpers` lost the `compare(` / `conditional(` regexes and became `generated_javascript_compiles_conditionals`, keeping the part the reviewer called fair (`evaluationMode === "compiled"`, i.e. the JS generator handles the new nodes instead of silently falling back to the closure path) over four expressions.
- Parser diagnostics were called "fair but brittle", so the error-message substrings (`"chained"`, `"exactly 3 arguments"`, `"trailing comma"`, ...) are gone; `rejects()` now asserts only `FormulaParseError`. Each of those tests gained a positive parse assertion so it still fails on base.
- Dropped the node-id ordering assertion in `if_partials_for_two_parameters` (a base invariant of `appendPartialDerivatives`, not part of this feature).

Accepted coverage gap: whether a solution's comparison opcode map agrees with its own runtime helper is not observable without executing WGSL, which the image cannot do. Two round-1 mutations (opcode permutation, `w_select` invalid-condition body) are no longer killed. That is the price of removing the private-ABI pins, and it is the trade the precheck asked for.

### Solution fixes

1. Raw comparison and raw `and`/`or`/`not` interpolated `v${id}` directly, so a raw node consuming a guaranteed-valid wrapped operand emitted `select(0.0, 1.0, (v4 < v5))` against a `W` struct. `generateRawBinary` and `generateRawCall` now take `states` and route the new arms through the existing `asF32`, like the raw `if` lowering already did. Existing arithmetic arms are untouched. Reproduced on `fallback(1 / x, 7) < 8`.
2. `estimateBranch` called `estimateSubtree` even when narrowing left a parameter with no values, so `if(and(x > 0, x < 0), 1 / 0, 7)` came back maybe-invalid. It now returns null for an empty narrowed domain and `estimateConditional` drops unreachable branches entirely. meta.md gained one sentence for it ("A branch whose restriction leaves a parameter no values at all cannot be selected"), since the tests now enforce it.

### Coverage added (precheck advisories)

- `conditionals_in_power_and_unary_positions` - the new forms as a power exponent, under unary minus, and as a power base.
- `every_comparison_switches_where_its_sides_are_equal` - on-boundary derivative for all six operators, plus a scaled left side.
- Direct `or` / `not` derivative outputs added to `logical_condition_derivatives`.
- `contradictory_condition_leaves_its_branch_unselectable` - contradictory conjunction and a nested-if variant.
- WGSL battery of 19 expressions covering fallback operands, unselectable branches, nested conditionals.

### Round 2 validation

- New suite 75/75 with the solution; 75/75 fail on base (`git stash` of `src/core/formula` only).
- Existing formula + propertyUtils suites 229/229 with the solution.
- Targeted mutations, each killing only what it should: raw operands back to bare `v` -> 2 WGSL tests; renamed runtime helper -> the declaration test; infeasible-branch guard removed -> the contradictory-condition test; comparisons forced always-maybe-invalid -> 12 range tests.
- LOC hook: human-effective 302 across 7 files (was 289).
- Flakiness, 3 runs each, identical every time: base mode 1301/1301 pass with 1301 JUnit testcases; new mode 75/75 pass with 75 JUnit testcases.
- Both patches apply and revert cleanly on a fresh checkout at the base commit, in both orders.
- Clean-room container (fresh clone at base + test.patch, image built from the submission Dockerfile, `--network none --user 1000:1000`): without solution.patch new mode 75/75 FAIL and base mode 1301/1301 pass; with solution.patch applied in the container new mode 75/75 pass and base mode 1301/1301 pass. The `has type 100755, expected 100644` warnings from `git apply` are an artifact of the host mount (the exFAT/NTFS partition reports every file executable), not of the patches: solution.patch carries no mode lines at all, and test.patch carries only the intended `new file mode 100755` for test.sh.

## Round 3 (2026-09-11) - second precheck pass

Test Quality PASSED this round (the round-2 rewrite held) and Verify Solution passed. Solution Quality found two new defects, both real, plus one genuine alignment gap.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS | No change. The remaining "implementation-coupled" note is advisory and names the things that replaced the unfair pins (AST kind/op, guardProfile, evaluationMode); weakening them further would leave the lowering rule untested. |
| Solution Quality | FAIL - 2 high | Both fixed (below), each with a regression test. Code Quality moved 2/3 -> 3/3. |
| Alignment | WARNING - precedence understated | Real gap: meta.md said comparisons bind looser than `+` and `-` while tests assert looser than `*` and `^` and tighter than unary minus. meta.md now says they bind looser than every arithmetic operator, with `-x <= 1` as the second example. |
| Description | WARNING - unnecessary information | Dropped the "matching abs, min and max" analogy. Kept the three-evaluator agreement and transformation-stability sentences for the second time: the Test Quality check's own requirement map lists both as prompt-stated requirements with tests attached, so removing them converts passing tests into unfair ones. |
| Dockerfile | WARNING x2 | No change, both conditions already hold: `package-lock.json` is committed at the base commit, and `--ignore-scripts` is deliberate - `canvas` and `sharp` are optionalDependencies whose native builds only the excluded `test/scenes` suite needs, while jest is itself an optionalDependency and so survives the base image's production install. The clean-room run confirms the image is fully offline-capable. |

### Solution fixes

3. `switchingGuard` treated an `if` node used as a logical operand as an opaque numeric condition, so `not(if(x < 0, 0, 1))` reported a finite derivative at x = 0 where the nested comparison switches. It now recurses into the conditional's own condition and keeps the generic zero guard on the node, which is the composition the description states ("`and`, `or` and `not` switch where any comparison inside them switches" plus "any other condition switches where it is zero").
4. `narrowParameters` restricted a parameter using operand ranges taken from the un-narrowed node-range array, so in `if(and(y > 0, x > y), sqrt(x), 7)` the restriction on x used y's original [-1, 1] and left x negative. Comparison operands are now re-estimated under the narrowing built so far, and the and/or case iterates to a fixpoint (capped at 4 passes) so the result no longer depends on conjunct order. Both orders now come back valid and lower raw.

Preempting a third round on the same function: the fix above only reached a comparison nested in a conditional, but the description says `and`, `or` and `not` switch where ANY comparison inside them switches, which literally includes one under arithmetic (`not(x + (x < 1))` at x = 1). The fall-through case now also guards every comparison found in the condition's subtree alongside the generic zero guard. The specific cases (comparison, and/or, not, if) still come first, so a plain comparison condition is unaffected and `if(x < 1, x * x, 2 * x)` still differentiates to 2 at x = 3.

### Coverage added (round-3 advisories)

- `comparison_binds_looser_than_subtraction` - the direct `a < b - 1` case the checker asked for, plus a left-side variant.
- `conditionals_in_power_and_unary_positions` extended with a denominator, an ordinary unary-function argument, a logical form under `sqrt`, and an assignment reference.
- `nested_conditional_condition_joins_the_switching_set` and `conjunction_narrowing_composes_through_a_dependent_comparison` - the two regressions, the second asserting both `maybeInvalid` and the WGSL raw/wrapped specialization as the grader requested.
- `comparison_under_arithmetic_joins_the_switching_set` - the preemptive case above.

Suite is 79 tests. The one advisory still outstanding is executing or validating the generated WGSL, which the offline image cannot do.

### Round 4 validation

- New suite 81/81 with the solution; 81/81 fail on base; existing suites 310/310 (the functionName guard regressed nothing).
- Mutations: comparison case stops at its own difference -> the nested-comparison test; identical operands treated independently -> the self-comparison test.
- Flakiness, 3 runs each, identical: base 1301/1301 with 1301 JUnit testcases, new 81/81 with 81.
- LOC hook: human-effective 344 across 7 files.
- Clean-room container: without solution.patch new 81/81 FAIL and base 1301/1301 pass; with it applied in the container new 81/81 pass and base 1301/1301 pass.

### Round 3 validation

- All formula suites 87/87 with the solution (8 existing + 79 new); new suite 79/79 fail on base.
- Mutations: nested-if guard removed -> the nested-conditional test; nested-comparison collector removed -> the arithmetic test; single narrowing pass -> the dependent-comparison test. Estimating comparison operands from the un-narrowed map survives, and is a no-op rather than a gap: the and/or fixpoint already hands the narrowed map down as `parameters`, so the two spellings differ only inside a single both-sides-parameter comparison, where `<` narrows the left's upper bound and the right's restriction reads the left's lower bound.
- Flakiness, 3 runs each, identical: base 1301/1301 with 1301 JUnit testcases, new 79/79 with 79.
- Clean-room container: without solution.patch new 79/79 FAIL and base 1301/1301 pass; with it applied in the container new 79/79 pass and base 1301/1301 pass.
- LOC hook: human-effective 329 across 7 files.

## Round 4 (2026-09-12) - third precheck pass

Test Quality and Verify Solution passed again; the per-test quality notes rated all 79 fair (the remaining tags are "internal coupling" advisories on DAG-shape and guard-profile assertions, which are the base-visible observables that replaced the round-1 pins). Solution Quality failed on three more cases.

| Check | Verdict | Response |
|---|---|---|
| Solution Quality | FAIL - 1 high + 2 medium | All three fixed (below). |
| Alignment | WARNING - WGSL rule understated | Real gap: meta.md stated the raw/wrapped rule for "comparisons and `if`" while `wgsl_logic_lowering_follows_the_range_analysis` also asserts it for `and`/`or`/`not`. meta.md now names the logical functions in that sentence. |
| Description | WARNING - unnecessary information | Declining the same two clauses a third time for the same reason (both appear in the checker's own requirement map with tests attached). Traded the `-x <= 1` example away instead, which the precedence rule already covers, to keep the body under the cap. |

### Solution fixes

5. `switchingGuard` handled a comparison by guarding only its own difference, so a comparison nested inside another comparison's operand was lost: `not(2 * (x < 3) < 1)` was finite at x = 3. `guardNestedComparisons` now descends into every operand before guarding the node itself, and the comparison case delegates to it, so an outer comparison keeps its own guard and gains its descendants'.
6. `x < x` was estimated from two independent copies of x's interval, so `if(x < x, 1 / 0, 7)` reported maybe-invalid. The parser already deduplicates identical subexpressions (`x < x` parses to one node with `args: [0, 0]`, and so does `sin(x) != sin(x)`), so a comparison whose operands are the same node id now resolves to the constant truth value and `estimateConditional` drops the branch that can never be selected.
7. The generated-evaluator `functionName` option could collide with an emitted runtime helper: `generateDagJsEvaluator(dag, { functionName: "compare" })` emitted two `compare` functions and the formula then called the evaluator recursively. Both generators now reject a `functionName` that matches a helper declared in their runtime source, derived from the source itself rather than a hand-kept list, so it cannot drift as helpers are added. This also closes the pre-existing cases at base (`fallback`, `guardNonzero`, `finiteOrNaN`, `w_add`, ...), which collided the same way before this task.

No test covers fix 7 on purpose: meta.md states nothing about reserving helper names, and testing a validation the description never mentions is the unfair-requirement pattern. The reference is correct; agents are not graded on it.

### Coverage added

- `nested_comparison_inside_a_comparison_joins_the_switching_set` - the grader's `not(2 * (x < 3) < 1)` case plus a conditional whose condition is a comparison over a comparison.
- `self_comparison_branch_is_unselectable` - `x < x`, `x >= x`, and a shared non-parameter subexpression (`sin(x) != sin(x)`), asserting both the estimated range and the evaluated values.
- Exact-arity negatives the checker asked for: `if()`, `and(1, 2, 3)`, `or(1, 2, 3)`, `not()`.

Suite is 81 tests.

### The traversal had to be scoped, and the property test paid for it

The first cut of fix 5 descended into every argument of every node, including the branches of an `if` nested inside a condition. That contradicts the description's own "the branch that is not selected never makes the result invalid": a comparison sitting in an unselected branch was invalidating the derivative. The scan now descends into a nested `if`'s condition only. `not(if(x < 0, 0, 1))` is unaffected because an `if` that IS the operand is handled by `switchingGuard`'s own conditional case.

Even scoped, the fix legitimately invalidates more points, and that surfaced in `random_conditional_derivatives_match_finite_differences`, which requires at least 30 of its sampled points to stay differentiable: only 23 of 60 did. Checked before changing anything: across 60, 90 and 120 samples there were ZERO symbolic-vs-numerical mismatches, so nothing was wrong, the sampler was just landing on switching sets more often. Raised the sample count to 120 (46 usable checks) and left the floor at 30, rather than lowering the floor, which would have made the property test easier to satisfy vacuously.

## Round 5 (2026-09-12) - fourth precheck pass

One high finding, and it was mine to own: the round-2 unreachable-branch guard pruned an empty narrowed domain only when the parameter was also valid.

| Check | Verdict | Response |
|---|---|---|
| Solution Quality | FAIL - 1 high | Fixed: `hasEmptyParameter` now prunes on `intervals.length === 0` alone. Code Quality stayed 3/3. |
| Test Quality | PASS | All 81 rated fair. |
| Description / alignment | WARNING | Same two clauses declined a fourth time, same reason. The example trims are advisory and the examples are the concrete form of rules the tests assert, so they stay. |

### Solution fix

8. `hasEmptyParameter` carried `&& !info.maybeInvalid`, added defensively in round 2. That was the wrong condition: an invalid input cannot make a comparison true, it makes the comparison invalid, so an empty finite interval set means unselectable whatever `maybeInvalid` says. With `x: { intervals: [[-1, 1]], maybeInvalid: true }`, `if(and(x > 0, x < 0), 100, 7)` was keeping 100 alive. It now estimates as "7; may be invalid" - the branch is gone, and the invalidity that survives comes from `condition.maybeInvalid`, which is where it belongs. A selectable branch is unaffected: the same input on `if(x > 0, 1 / x, 7)` still yields the full maybe-invalid range.

Covered by `an_invalid_parameter_does_not_revive_an_impossible_branch`, which asserts the maybe-invalid input, the valid input, and the self-comparison form. meta.md already stated the rule ("A branch whose restriction leaves a parameter no values at all cannot be selected"), so no description change was needed.

### Round 5 validation

- New suite 82/82 with the solution; 82/82 fail on base; existing suites 311/311.
- Mutation: restoring `&& !info.maybeInvalid` kills `an_invalid_parameter_does_not_revive_an_impossible_branch` and nothing else.
- Flakiness, 3 runs each, identical: base 1301/1301 with 1301 JUnit testcases, new 82/82 with 82.
- Clean-room container: without solution.patch new 82/82 FAIL and base 1301/1301 pass; with it applied new 82/82 pass and base 1301/1301 pass.
- LOC hook: human-effective 344 across 7 files.

## Round 6 (2026-09-12) - fifth precheck pass

Test Quality PASSED with all 82 rated fair and 20 of 21 prompt requirements pinned (the uncovered one is the WGSL numeric agreement that needs a shader runtime). One Solution Quality finding, and it is the exact mirror of the round-4 over-invalidation.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS - 0 unfair of 82 | No change. |
| Solution Quality | FAIL - 1 high | Fixed (below). Code Quality stayed 3/3. |
| Description | WARNING | Same clauses declined a fifth time. The checker now also wants the `a < b < c` and `if(x != 0, 1 / x, 7)` examples cut; both are the concrete form of rules whose tests the Test Quality check maps to those exact sentences, so they stay. |

### Solution fix

9. Round 4 scanned both branches of a nested `if` and over-invalidated; the scoped fix scanned only the condition and therefore lost the SELECTED branch: `not(if(1, 1 + (x < 0), 1))` came back 0 at x = 0 even though `x < 0` sits inside the `not` and switches there. Neither static choice is right, because which branch contributes depends on the condition at evaluation time. `guardSelectedBranch` now builds an `if` node over the two branches' guard chains, so the guard that applies is the one the condition actually selects. `not(if(1, 1 + (x < 0), 1))` is invalid at x = 0 and finite either side; `not(if(x > 5, 1 + (y < 0), 1))` differentiated in x at y = 0 stays finite because the branch holding `y < 0` is not selected.

Both directions are pinned by `selected_branch_comparison_joins_the_switching_set`, and both mutations die: skipping branches entirely (the round-4 scoped behaviour) and scanning both unconditionally (the round-4 original).

### Round 6 validation

- New suite 83/83 with the solution; 83/83 fail on base; existing suites 312/312.
- Mutations: skipping branches entirely and scanning both unconditionally each kill `selected_branch_comparison_joins_the_switching_set` and nothing else.
- Flakiness, 3 runs each, identical: base 1301/1301 with 1301 JUnit testcases, new 83/83 with 83.
- Clean-room container: without solution.patch new 83/83 FAIL and base 1301/1301 pass; with it applied new 83/83 pass and base 1301/1301 pass.
- LOC hook: human-effective 355 across 7 files.

## Round 7 (2026-09-12) - sixth precheck pass

Test Quality PASSED again (all 83 rated fair, 19 of 23 prompt requirements pinned, the 4 "partial"
marks are coverage breadth not fairness). One Solution Quality finding, and it is real and mine.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS - 0 unfair of 83 | No change. 3 of the 4 coverage suggestions taken (below); the 4th needs a WGSL runtime the offline image does not have. |
| Solution Quality | FAIL - 1 high | Fixed (below), with two regression tests. |
| Description | WARNING x5 | 3 example trims accepted, the 2 HIGH clause removals declined for the sixth time (reason below, now with the checker's own requirement map as evidence). |

### Solution fix

10. `maybeInvalid: true` is not the same as "has no finite value", and two new paths conflated them.
`estimateLogic` derived truth from each argument's intervals and then merely OR-ed `maybeInvalid`, so
an argument with NO finite interval still let the other argument decide the outcome:
`or(1, sqrt(-1))` came back `1` and `and(0, sqrt(-1))` came back `0`, both of which are invalid at
every input because a logical function with an invalid operand is invalid. The round-4
`leftId === rightId` shortcut had the same hole: `identicalComparison` advertised a constant truth
value without checking that the shared operand has any finite value, so `sqrt(-1) == sqrt(-1)` was
`1`. Both then propagated: `estimateConditional` saw a condition that could select a branch and
pulled `[10, 10]` into the root range of `if(or(1, sqrt(-1)), 10, 20)`.

Both sites now return `invalidOnly()` when an operand has no finite intervals. `estimateComparison`
already did the right thing for free (its nested interval loop produces no outcomes, so
`outcomes.size === 0` already returned `invalidOnly()`), which is why the general comparison path
was never affected and only the identity shortcut and the logical path were wrong.

Scope check, because the fix must not over-prune: an operand that has finite values AND
`maybeInvalid` must keep its truth value. `or(1, sqrt(x))` over x in [-1, 4] still estimates
`1; may be invalid`, `sqrt(x) == sqrt(x)` still estimates `1; may be invalid`, and `x == x` over a
valid x still estimates `1`. All three verified unchanged before and after.

The reviewer named `==`; the same shortcut was also wrong for `<`, `<=`, `>`, `>=` and `!=`, so
`sqrt(-1) < sqrt(-1)` was `0`. The fix is at the shortcut, so all six are covered, and the tests
assert three of them.

No meta.md change: "A comparison or logical function with an invalid operand is invalid" and "an
`if` with an invalid condition is invalid" already state exactly this, which is what the grader
quoted back as the violated requirement.

### Coverage added

- `an_invalid_only_operand_leaves_a_logical_function_no_truth_value` - the grader's `or(1, sqrt(-1))`
  and `and(0, sqrt(-1))`, plus `not` and an operand-order variant, each asserting the range AND that
  all three evaluators agree it is NaN, plus the must-not-over-prune `or(1, sqrt(x))` case.
- `an_invalid_only_condition_selects_no_branch` - the same four as `if` conditions.
- `an_identical_comparison_over_an_invalid_operand_is_invalid` - `==`, `<`, `>=` over an invalid
  shared operand, plus the `sqrt(x) == sqrt(x)` case that must stay `1; may be invalid`.
- `comparison_binds_looser_than_division` - coverage suggestion 1, structural + evaluated, both
  orientations.
- Chaining negatives extended to start with `>`, `>=`, `<=` and `!=` incl. mixed second operators -
  coverage suggestion 2.
- Invalidity extended to `<=`, `>`, `==`, `!=` and to `and` / `not` - coverage suggestion 3.

Suite is 87 tests.

### The two description clauses, declined a sixth time

Both HIGH suggestions ask to delete a sentence that the Test Quality check, in the SAME report,
lists as a prompt-stated requirement with tests mapped to it:

- "The closure evaluator, the generated JavaScript and the WGSL agree" is requirement 13, mapped to
  5 tests. It is not an assumed default: the failure it prevents is a solution that implements the
  closure path and lets the JS generator silently fall back to interpretation, which is exactly what
  `generated_javascript_compiles_conditionals` catches, and the `both()` helper re-checks on every
  value assertion in the suite.
- "Labels, substitution, number extraction and DAG combination keep working unchanged for the new
  nodes" is requirement 23, mapped to 4 tests, 3 of which have no other anchor in the description.
  It is not generic no-regression guidance: `substitution.js`, `parameter-extraction.js` and
  `dag-combination.js` are separate modules that each have to learn the new node kinds.

Deleting either converts passing fair tests into unstated-requirement tests, which is the exact
failure mode the Test Quality check exists to catch. Declining is the lower-risk side of a
WARNING-vs-FAIL trade.

The three MEDIUM example trims were taken (`a < b + 1`, `if(x != 0, 1 / x, 7)`,
`flag = x <= 1; if(flag, 10, 20)`). Each removed only an illustration whose general rule sentence
stays stated verbatim, so no requirement lost its anchor, and it cuts two concrete hints for
predicted traps 1 and 2. meta.md is now 442 body words (was 486), restoring headroom.

### Round 7 validation

- New suite 87/87 with the solution; 87/87 fail on base; base-mode scope 1301/1301 pass (unchanged).
- Mutations, each killing only what it should: dropping the `estimateLogic` guard kills
  `an_invalid_only_operand_leaves_a_logical_function_no_truth_value` +
  `an_invalid_only_condition_selects_no_branch`; dropping the `identicalComparison` guard kills
  `an_identical_comparison_over_an_invalid_operand_is_invalid` + the same shared conditional test.
  Zero collateral in either direction.
- Flakiness, 3 runs each in the clean-room container, identical every run.
- Clean-room container (fresh clone at base + test.patch, image built from the submission
  Dockerfile, `--network none --user 1000:1000`): without solution.patch new 87/87 FAIL and base
  1301/1301 pass; with it applied new 87/87 pass and base 1301/1301 pass.
- Both patches apply and revert cleanly on a fresh checkout at base, in both orders, tree clean after.
- LOC hook: human-effective 357 across 7 files (was 355).
- Submit gates re-run: canonical org unchanged (ricktu288/ray-optics), master HEAD still == base
  commit (zero post-base activity), no PR in the feature class (all hits are dependabot bumps), no
  issue in the class, repo quota 1/6, test.sh mode 100755, patches ASCII, no banned markers, zero
  comments added by either patch.

### Process note

The first patch regeneration this round emitted the PREVIOUS test file: the new tests were written
to the working tree but never re-staged, and test.patch is generated from `git diff --cached`. The
clean-room container caught it (87 expected, 83 testcases reported). `git add` of the test file is
now part of the regeneration step. Nothing downstream was affected because the clean-room run sits
before any submit.

## Round 8 (2026-09-12) - seventh precheck pass

Test Quality PASSED again (87 of 87 fair, 21 of 22 requirements pinned). One Solution Quality
finding, real, and the last unguarded corner of the switching-set traversal.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS - 0 unfair of 87 | No change. The one coverage suggestion left is executing real WGSL, which the offline image cannot do. |
| Solution Quality | FAIL - 1 high | Fixed (below), two regression tests. |
| Problem-and-tests quality | WARNING | WGSL codegen coupling, advisory. Test Quality rates the same assertions fair and repo-discoverable in the same report; these forms replaced the round-1 unfair private-ABI pins and weakening them again would leave the lowering rule untested. No change. |
| Description | WARNING x3 | The two HIGH clause removals declined a seventh time (same requirement-map evidence). The new MEDIUM decline is argued below. |

### Solution fix

11. `guardNestedComparisons` knew two special cases, nested `if` and nested comparison, and treated
everything else as a plain parent to descend through. A nested `and` / `or` / `not` therefore never
reached `switchingGuard`, which is the only function that knows a logical operand is itself a
condition and switches where it crosses zero. The grader's case: `if(and(x, 1) < 0.5, 5, x)`
differentiated in x. At x = 0, `and(x, 1)` is 0, the condition holds and the branch is the constant
5; just off zero `and(x, 1)` is 1, the condition fails and the branch is x. The selected branch
changes, so x = 0 is a switching point, but the old code only guarded `and(x, 1) - 0.5`, which is a
constant -0.5, and returned 0.

`guardNestedComparisons` now delegates a nested logical call to `switchingGuard`, which already
handles and / or / not correctly. No recursion hazard: `switchingGuard`'s logical arms recurse into
OPERANDS via `switchingGuard`, never back into `guardNestedComparisons` on the same node.

The grader named `and` under a comparison. The same hole covered `or`, `not`, and any arithmetic
parent, so `if(and(x, 1) + 2 > 2.5, x, 5)` was finite at x = 0 too. Fixing at the delegation point
covers all of them, and the test asserts four shapes.

Selection-awareness from round 6 is preserved: `guardSelectedBranch` still routes each branch
through `guardNestedComparisons` under an `if`, so a logical call in an UNSELECTED branch stays
finite. `if(y > 5, and(x, 1) < 0.5, 1)` differentiated in x is invalid at y = 9 and finite at y = 1,
and that pair is pinned by its own test.

### A pre-existing conservatism, deliberately left alone

While verifying, `if(or(x, 0) < 0.5, 5, x)` turned invalid at x = 0.5, where it had been 1. Checked
before assuming a regression: `switchingGuard` guards each logical OPERAND as a condition, and a
literal 0 operand is at its zero crossing everywhere, so `or(x, 0)` reads as always-switching. That
behaviour is PRE-EXISTING, not new - `if(or(x, 0), 5, x)` (the direct form, which never touches
`guardNestedComparisons`) produces exactly the same NaN with the round-8 change reverted, verified
side by side. It has survived seven precheck rounds unflagged.

Left as is on purpose. Narrowing the guard to non-constant operands would be an unrequested
behaviour change to code the grader did not flag, on the surface that has already caused two
over/under-scoping reversals (rounds 4 and 6), and the direction of the imprecision is the safe one
(invalid where a value was possible, never a wrong number). The new tests are chosen so that none of
them pins a point that depends on this conservatism: the `or` case is tested at a genuine switching
point and at a point where both operands are nonzero.

### Coverage added

- `nested_logical_call_joins_the_switching_set` - the grader's `and` case at the switch and either
  side of it, the `not` and `or` forms, and the arithmetic-parent form.
- `a_nested_logical_call_switches_only_in_the_selected_branch` - the selected/unselected pair.

Suite is 89 tests.

### The description declines

The two HIGH suggestions are the same clauses as rounds 2-7, and the same report still lists both as
prompt-stated requirements with tests mapped (requirement 12 "evaluators agree", 4 tests;
requirement 22 "labels, substitution, number extraction, DAG combination", 4 tests). Unchanged
reasoning, seventh decline.

The new MEDIUM asks to cut "They may appear anywhere an expression may." Declined: its stated
rationale is "the examples already demonstrate their use in all positions", but those examples were
REMOVED last round at this same checker's request, so the rationale no longer holds against the
current text. The requirement map also lists it as covered by three tests
(`conditionals_in_power_and_unary_positions`, `comparison_inside_a_function_argument`,
`parenthesised_comparisons_can_be_compared`), which would lose their anchor.

### Round 8 validation

- New suite 89/89 with the solution; 89/89 fail on base; base-mode scope 1301/1301 pass.
- Mutations, all four clean: removing the delegation kills both new tests; keeping only `and`/`or`
  kills the nested-logical test; keeping only `not` kills both; scanning both branches
  unconditionally still kills only `selected_branch_comparison_joins_the_switching_set`.
- Property-test margin: `random_conditional_derivatives_match_finite_differences` now has 40 usable
  checks against its floor of 30, down from 46 in round 4. The extra invalidation costs ~6 usable
  samples per fix of this kind. If a future round adds more, raise the sample count (120) again
  rather than lowering the floor.
- Flakiness, 3 runs each in the clean-room container, identical every run.
- Clean-room container: without solution.patch new 89/89 FAIL and base 1301/1301 pass; with it
  applied new 89/89 pass and base 1301/1301 pass.
- LOC hook: human-effective 359 across 7 files (was 357).

### Process note

A first pass at the mutation sweep reported a bogus result: the sed targeting the new delegation
matched an EARLIER identical-looking dispatch (`derivative.js` line 218, the derivative-of-logical
arm) and killed 5 tests, which read as the new clause being load-bearing everywhere. Re-ran pinned
to the line number. Mutation edits on this file must be line-anchored - three sites share the
`and || or || not` shape.

## Round 9 (2026-09-12) - eighth precheck pass, first Test Quality FAIL since round 2

Both unfair findings are correct. They get OPPOSITE fixes, because one pins behaviour the task
really does require and the other pins an optimisation the description deliberately does not promise.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | FAIL - 2 of 91 assertions unfair | One fixed by stating the rule, one fixed by deleting the assertion (below). |
| Problem-and-tests quality | WARNING | Implementation coupling in the WGSL/DAG assertions, advisory, third time. Unchanged: the same report rates every one of them fair and repo-discoverable, and they are what replaced the round-1 private-ABI pins. |
| Description | WARNING x4 | All four declined (below). |

### Unfair 1 - `if((x < 3) >= 1, x, 2 * x)` must be NaN at x = 3: FIXED BY STATING THE RULE

The grader is right. At x = 3 the outer comparison's sides are 0 and 1, not equal, and meta.md only
granted nested propagation to `and` / `or` / `not`. Nothing said a comparison switches where a
comparison inside its OPERANDS switches, so a prompt-literal implementation returns 2 and the
asserted NaN was not singled out.

This is not a test to delete: the behaviour was demanded by Solution Quality in round 4 (fix 5,
`not(2 * (x < 3) < 1)` finite at x = 3), it is in the reference, and it is a genuine trap. The gap
was in the description, so the description is what changed. The switching-set clause is now:

  a comparison switches where its two sides are equal, `and`, `or` and `not` switch wherever an
  operand switches, any other condition switches where it is zero, and every condition also switches
  wherever a comparison or logical call nested inside it switches, counting a nested `if` only
  through the branch it selects.

Four separate things were folded in deliberately: the operand wording now covers the round-8 case
(`and(x, 1)` switching where its operand crosses zero) which the old "any comparison inside them"
wording never did; the new clause covers propagation through a comparison's operands and through
ordinary arithmetic/functions; and the trailing qualifier preserves the round-6 selection-aware
behaviour instead of blanket-claiming both branches of a nested `if`.

This was the LAST cheap moment to do it. No batch has run, so the solver-visible surface is still
free to edit; after batch 1 this same fix would cost a full-price batch (RULE UPDATE 2026-09-03).

Verified the new wording does not OVER-claim, which would make the reference wrong rather than the
test unfair. Probed ten nesting shapes at their nested switching point - comparison-of-comparison,
comparison under `+`, under `*`, under `sqrt`, under `abs`, under `min`, inside `and`, inside `not`,
a logical call under a comparison, and a comparison compared with itself. All ten return NaN in the
reference, and the off-switch points of each still return the selected branch's derivative.

### Unfair 2 - `if(sin(x) != sin(x), 1 / 0, 7)` must be valid: FIXED BY DELETING THE ASSERTION

Also right, and the opposite call. meta.md scopes its narrowing rule to "a comparison with a bare
parameter on either side"; `sin(x)` is not bare. A conservative estimator that ranges the two
operands independently, keeps both truth values and includes the invalid branch satisfies every
stated rule, so the assertion pinned an unstated same-DAG-node correlation.

Deleted rather than described. Stating it would mean writing a sentence about identical
subexpressions resolving to one node, which leaks the parser's deduplication into the spec and
describes the implementation rather than the behaviour. The bare-parameter half of the test
(`x < x`, `x >= x`, and the three evaluated values) is rated fair and stays - that is where the trap
actually lives. The reference keeps the extra precision; it is sound, just no longer required.

Note the round-7 test `an_identical_comparison_over_an_invalid_operand_is_invalid` uses non-bare
operands too (`sqrt(-1) == sqrt(-1)`) and was rated FAIR, correctly: it asserts invalidity, which
follows from "a comparison with an invalid operand is invalid" whether or not the estimator folds
identical nodes. It still kills the round-7 mutation, so nothing was lost there.

### Coverage added

- `a_comparison_nested_under_a_function_joins_the_switching_set` - propagation through `sqrt` and
  `abs`, at the switch and either side of it, anchoring the new clause with a shape none of the
  existing tests used.

Suite is 90 tests.

### The four description declines

Same two clauses as rounds 2-8 (now HIGH + MEDIUM, they swapped severities), plus "They may appear
anywhere an expression may" for the second time, plus a new LOW on "and take exactly their arity".

All four are listed in this same report's requirement map with tests attached: 4 tests, 4 tests,
4 tests, and 5 arity tests respectively. The arity one is the closest call, since `if(condition,
whenTrue, whenFalse)` and "(binary)" / "(unary)" do imply the counts, but "take exactly" is what
makes a wrong count a parse ERROR rather than ignored extra arguments, and five tests assert
rejection. Five words, five tests, kept.

### Round 9 validation

- New suite 90/90 with the solution; 90/90 fail on base; base-mode scope 1301/1301 pass.
- Mutation: removing the operand descent in `guardNestedComparisons` kills 6 switching-set tests
  including the new one, and nothing else.
- Flakiness, 3 runs each in the clean-room container, identical every run.
- Clean-room container: without solution.patch new 90/90 FAIL and base 1301/1301 pass; with it
  applied new 90/90 pass and base 1301/1301 pass.
- LOC hook: human-effective 359 (solution.patch untouched this round - both fixes were description
  and test side).
- meta.md 464 body words (was 442), ASCII, still under the 500 cap.

## Round 10 (2026-09-12) - ninth precheck pass

Test Quality PASSED with all 90 fair and 24 of 26 requirements pinned - the round-9 fairness repairs
held. One Solution Quality finding, a genuine numerical bug in my own guard.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS - 0 unfair of 90 | Both coverage suggestions taken where possible (below). |
| Solution Quality | FAIL - 1 high | Fixed (below), with a regression test. Code Quality stayed 3/3. |
| Description | no findings this round | The round-9 wording (incl. the generalized switching clause) drew no complaint. |

### Solution fix

12. The comparison guard tested equality by SUBTRACTING the operands:
`guardNonzero(left - right, guarded)`. A difference is not an equality test under this engine's
finite-number semantics. For `x < -x` at x = 1e308 the operands are finite and unequal, so the point
is nowhere near the switching set, but `x - (-x)` is 2e308, the evaluator normalizes the overflow to
NaN, and `guardNonzero` then reported the derivative invalid. Reproduced in BOTH the closure and the
generated-JS evaluators, and in four shapes: bare `x < -x`, the same inside an `if` condition,
against a large negative literal, and with the parameter on the right (`if(x > 1e308, 1, x)` at
x = -1e308).

The guard now builds a `!=` comparison node over the two operands and guards on its 1/0 result, as
the grader suggested. The three cases it has to separate all still come out right, because `!=`
already has the semantics the guard wants: unequal gives 1 (finite, guard passes), equal gives 0
(guard invalidates, which is the switching set), and an invalid operand gives NaN (guard
invalidates, which is the invalid-operand rule). Verified the invalid-operand direction explicitly -
`x < sqrt(-1)`, `sqrt(-1) < x`, and both inside conditionals still differentiate to NaN.

This is the feature differentiating itself: the guard for the new comparison nodes is now built out
of a new comparison node. No extra machinery, and one line shorter than the subtraction.

Scope checked before editing: `grep` for `subtractExpr` shows my patch introduced exactly ONE, this
guard. The other uses (`derivativeOfMinMax`'s `left - right`, the asin/acos/acosh/atanh arms) are all
pre-existing base code at line 305 of the base file, so the same overflow shape in min/max is the
repo's own behaviour and out of scope for this task. Not touched.

### Coverage added

- `far_apart_operands_are_not_a_switching_point` - the grader's `x < -x` at 1e308, the genuine switch
  at x = 0 for contrast, the `if`-condition form, the parameter-on-the-right form, the large-literal
  form, and an invalid-operand case so the fix cannot be "make the guard never fire".
- `logical_functions_with_no_arguments_reject` - coverage suggestion 1: `and()` and `or()` were the
  one arity hole (a parser accepting only the zero-argument forms would have passed the old tests).
- Coverage suggestion 2 (execute/validate real WGSL) remains impossible offline; declined for the
  fifth time.

Suite is 92 tests.

### Round 10 validation

- New suite 92/92 with the solution; 92/92 fail on base; base-mode scope 1301/1301 pass.
- Mutations: restoring the subtraction guard kills ONLY `far_apart_operands_are_not_a_switching_point`;
  inverting the guard to `==` kills 16 tests. The first is the tight one - the new test is the sole
  discriminator for this fix, exactly as intended.
- Flakiness, 3 runs each in the clean-room container, identical every run.
- Clean-room container: without solution.patch new 92/92 FAIL and base 1301/1301 pass; with it
  applied new 92/92 pass and base 1301/1301 pass.
- LOC hook: human-effective 359 (unchanged - the fix swapped one call for another).
- meta.md untouched this round: 464 body words. The solver-visible surface has now been stable for
  two rounds.

## Round 11 (2026-09-13) - tenth precheck pass

Test Quality PASSED with all 92 fair. One Solution Quality finding, real: the last unguarded path in
the switching-set traversal.

| Check | Verdict | Response |
|---|---|---|
| Test Quality | PASS - 0 unfair of 92 | No change. The transformation-coverage suggestion is noted below; WGSL execution remains impossible offline. |
| Solution Quality | FAIL - 1 high | Fixed (below), two regression tests. |
| Problem-and-tests quality | WARNING | WGSL/DAG coupling, advisory, fourth time. Unchanged for the same reason as rounds 8-10. |
| Description | WARNING x4 | All four declined (below). |

### Solution fix

13. A nested `if` was traversed by `guardNestedComparisons` with its SELECTOR handed back to
`guardNestedComparisons`, which only recognises comparisons and logical calls. A plain numeric
selector therefore produced no guard at all. The grader's case, `if(if(x, -1, 1) < 0, 5, 7)`, is a
real jump: the value is 5 at x = -0.001, 7 at x = 0 and 5 again at x = 0.001, yet the derivative came
back 0. The outer guard `if(x, -1, 1) != 0` holds at zero (the inner `if` is 1 there), so nothing
invalidated it.

The selector now goes through `switchingGuard`, which already knows every condition shape: a
comparison guards where its sides are equal, a logical call guards through its operands, and
anything else guards where it is zero. Branch traversal still goes through `guardSelectedBranch`, so
a nested `if` inside a condition only contributes the branch it selects. Deliberately NOT added: a
zero guard on the nested `if` node itself. Inside a comparison operand the `if` is a number, not a
condition, so its own value being zero is not a switch; `switchingGuard`'s own `if` arm adds that
guard only when the `if` IS the condition, which is correct there.

Reproduced across shapes before fixing, which also confirmed the diagnosis was exactly the selector:
the direct form `if(if(x, -1, 1), 5, 7)` and a comparison selector `if(if(x > 2, -1, 1) < 0, 5, 7)`
were already invalid at their switch; only the plain selector under a comparison (or under
arithmetic, `2 * if(x, -1, 1) < 0`) was wrong.

### Coverage added

- `a_nested_conditional_selector_joins_the_switching_set` - the grader's case at the switch and on
  both sides, the arithmetic-parent form, the comparison-selector form, and the two evaluated values
  that show the jump (7 at zero, 5 just off it), so the NaN is visibly justified.
- `a_nested_conditional_selector_switches_only_in_the_selected_branch` - `if(y > 5, if(x, -1, 1) < 0, 1)`
  invalid at y = 9 and finite at y = 1.

Suite is 94 tests.

Not taken: the advisory to parameterize substitution / number extraction / DAG combination over every
new node kind. Those three modules copy nodes generically by kind and never inspect `name`, so a
solution that "handles only comparisons and `if`" there would have to add code to special-case the
logical calls out; the one-off integration tests already exercise all three node shapes flowing
through them. Low value against more suite surface for the fairness checker to re-audit.

### The four description declines

Three are the same clauses as earlier rounds, each still mapped to tests in this report (4, 4, 3).
The new MEDIUM asks to drop the component list from the opening sentence. Declined: that list is the
cross-subsystem scope signal for a 7-file task, the first body sentence is where the feature request
has to be stated, and with no batch data yet, removing the one sentence that tells a solver the WGSL
generator, the derivative and the range estimator are all in scope is an untested change pointed at
the solvability floor (0% = reject). It is the most defensible of the four to trade later if the
word budget ever forces a cut.

### Round 11 validation

- New suite 94/94 with the solution; 94/94 fail on base; base-mode scope 1301/1301 pass.
- Mutations, line-anchored: restoring `guardNestedComparisons` on the selector kills exactly the two
  new tests; dropping branch-selective traversal still kills only
  `selected_branch_comparison_joins_the_switching_set`.
- Property-test margin unchanged at 40 usable checks against the floor of 30 (the sampler does not
  generate nested numeric selectors).
- LOC hook: human-effective 359 (one call swapped for another).
- meta.md untouched: 464 body words. Solver-visible surface now stable for three rounds.
- Clean-room container (`--network none --user 1000:1000`), 3 runs each, identical: without
  solution.patch new 94/94 FAIL and base 1301/1301 pass; with it applied new 94/94 pass and base
  1301/1301 pass. The with-solution matrix was OOM-killed on this 7GB host during run 3 when both
  modes ran back to back in one invocation; run 3 was re-run with each mode in its own container and
  came back identical. Host memory pressure, not the harness - but a reminder that jest's default
  worker count is uncapped in test.sh.

## Batch 1 (2026-09-13) - 10 Nova + 1 Vega: 0/11 PASS

First platform batch. Unsolvable-reject territory. Full per-run table in eval-results.md; all 11
agent runs saved under agent-runs/1/.

Every evaluator verdict was FAIL_MISSED_REQUIREMENT with description_clear=true,
tests_deterministic=true and "challenging but fair". The data says otherwise for one cluster.

### Wall 1 - description under-specification (11/11, same reason)

10 tests failed in ALL 11 runs, every one a derivative switching-set test. The failing lines are the
NaN assertions on a BARE comparison or logical call at its switching point: line 442
`partial("x < 1", x = 1)`, line 484 `partial("and(x > 0, x < 2)", x = 2)`, line 553
`partial("x < -x", x = 0)`. All 11 agents wrote `if (isComparisonOperator(node.op)) return
builder.number(0, "0")` and the same for and/or/not, and all 11 ALSO built a switching-guard pass
for `if`. So they understood switching sets; they applied them only to `if`.

meta.md says "The derivative of a comparison, `and`, `or` or `not` is 0, and the derivative of `if`
is the derivative of the selected branch, except on the switching set, where it is invalid". The
"except" clause attaches grammatically to `if` only. A competent engineer reading the description
writes exactly what the agents wrote. That is the unanimous-same-reason unfairness signal, and the
evaluator's "fair" verdict does not override it. (The round-12 precheck independently asked to split
this very sentence because it is hard to parse.) Lines 538 and 571 belong to the same cluster even
though they are `if`-wrapped: their NaN comes from the SELECTED BRANCH being a bare comparison, not
from the `if`'s own switch. Only 476-482 and 513 exercise genuine `if` switching, and those passed.

### Wall 2 - order-independent conjunction narrowing (10/11)

`conjunction_narrowing_composes_through_a_dependent_comparison` (line 811, `maybeInvalid === false`)
asserts both conjunct orders. meta.md says the restriction "composes through ... the branch that
`and` (when it holds) ... pins down"; nothing says the result must not depend on conjunct order. Only
Nova_Nova_7 passed it.

### Beneath the walls - trap stacking (the binding constraint)

Local re-grade harness: fresh clone at base, each agent's source patch applied, candidate test
suites run. Validated first: REFERENCE passes all variants, and every V0 count reproduces the
platform's count exactly.

| Variant | Change | Pass | Failure counts |
|---|---|---|---|
| V0 | current suite | 0/11 | 12-17 |
| V1 | drop the 19 bare-switch-point NaN assertions | 0/11 | 2-8 |
| V2 | V1 + conjunction test natural order only | 0/11 | 1-8 |
| V3 | V1 + conjunction test removed | 0/11 | 1-7 |

Removing both walls halves the failures and still passes nobody. What remains is the stack of
edge-case tests added in response to precheck Solution Quality findings, each killing 30-60% on its
own: identical-comparison-over-invalid 7/11, invalid-only condition 6, far-apart overflow 6,
invalid-only logical operand 5, invalid parameter reviving a branch 5, self-comparison 5, WGSL raw
reading wrapped operands 5, WGSL types 4, disjunction true branch 3. Every one of those is a corner
case the precheck grader found in MY reference; the agents make the same mistakes. Roughly eight
independent ~50% traps multiply to ~0.

Closest runs: Vega_Nova 1 residual (the round-11 nested selector test), Nova_Nova_1 2 (both round-7
invalid-only tests).

Lesson worth carrying forward: every precheck Solution Quality finding was real, and fixing it in
the reference was right, but reflexively adding a regression TEST for each one turned eleven rounds
of reference hardening into eleven stacked traps. A reference fix does not have to become a graded
requirement.

### Recovery attempt A - tests only (user-chosen), built and measured, then blocked by the FP check

Decision taken with the user: resolve both walls in tests only, keep meta.md frozen for re-eval, and
drop 5 late-round edge-case tests (r11 nested selector, r7 sqrt(-1)==sqrt(-1), r7 invalid-only if
condition, r7 or(1, sqrt(-1)), r10 1e308 overflow). Suite built: drop the 19 bare-switch-point NaN
assertions, keep the conjunction test in natural order only, drop the 5 tests, rename 6 tests whose
remaining assertions no longer match their switching-set names. 89 tests. meta.md, solution.patch,
Dockerfile and BASE_COMMIT.txt verified byte-identical by sha256.

Harness on the built suite: BASE 89/89 fail, REFERENCE 89/89 pass, agents 3/11 = 27%
(Nova_Nova_1, Nova_Nova_7, Vega_Nova), exactly the pre-computed prediction.

Blocked before submit: the mandatory FP Check would flag every one of those passers.
- All three still return literal 0 for a bare comparison's derivative at its switch. In batch 1 ALL
  11 platform evaluators read meta.md as REQUIRING that switch to be invalid and marked literal 0 as a
  missed stated requirement. The FP check uses the same reading, so each passer is a false pass.
- Each passer also violates a rule meta.md still states that a dropped test used to pin: Nova_Nova_1
  on the invalid-only range cases, Nova_Nova_7 on those plus the 1e308 comparison, Vega_Nova on the
  nested selector.

Conclusion: tests and description disagree about bare derivatives, and the platform's own reading of
the description sides with the old tests. No tests-only change can align them, so a solver-visible
edit - and a full-price batch - is unavoidable. The re-eval saving that motivated attempt A does not
exist. The built suite is staged in the worktree and test.patch, pending the route decision.

Process lesson: when choosing a tests-only relaxation, check the FP-check reading of the description
against the batch evaluators' reading FIRST. The evaluator verdicts are the best available evidence
of how the FP panel will read the same prompt.

### Recovery route B - "0 everywhere" (user delegated the call; executed)

After attempt A was blocked by the FP check, the user delegated both open questions. Calls made:

1. Bare comparison / `and` / `or` / `not` derivatives are 0 EVERYWHERE, including where the value
   jumps; only `if` is invalid on the switching set of its condition. This is what 11 of 11 agents
   wrote naturally, so the harness number is a grounded estimate for a fresh batch; it removes the
   headline FP exposure outright (the requirement the passers missed no longer exists); and it is the
   standard autodiff convention for comparisons.
2. Keep the 5 edge-case drops and leave their sentences as they are. Re-adding the tests returns the
   population to 0/11. Every sentence those tests pinned ("invalid operand is invalid", "invalid
   condition is invalid", the switching clause) is still pinned by other tests that the passers pass;
   only pathological corners go unchecked. Smaller residual FP risk than any alternative that stays
   solvable.

Changes (solver-visible, so this needs a full-price batch - re-eval is not available):

- meta.md: the derivative rule now reads "Comparisons, `and`, `or` and `not` have derivative 0
  everywhere, including where their value jumps. The derivative of `if` is the derivative of the
  selected branch, except on the switching set of its condition, where it is invalid." followed by the
  switching-set rules as separate sentences. The range-narrowing rule is split into sentences by scope
  (bare-parameter restriction; strict bounds and `!=`; logical composition; nested conditionals),
  wording otherwise preserved. Both splits were the round-12 precheck's own presentation suggestions.
  467 body words, ASCII.
- solution.patch: the two bare arms in derivative.js (lines 207 and 219) return literal 0 instead of
  `switchingGuard(..., 0)`. Verified by diffing the saved round-11 file: exactly those two lines.
  `switchingGuard` still has 7 call sites, all on the `if` path. LOC 359.
- test.patch (89 tests): the attempt-A suite, plus explicit at-jump zero assertions (`x < 1` at 1,
  `x == y` at 3,3, `and` / `or` / `not` at their jumps, all six operators at equality, and
  `2 * x op 2` at 1) so tests and description agree exactly on bare derivatives; two tests renamed to
  match (`comparison_derivative_is_zero_even_where_it_jumps`,
  `every_comparison_derivative_is_zero_including_at_equality`).
- Dockerfile and BASE_COMMIT.txt unchanged (sha256 verified).

Declined again from the round-12 description check: the two HIGH clause removals and the "take exactly
their arity" trim, for the reasons recorded in rounds 2-11 (each still has tests mapped to it).

### Route B validation

- Worktree: full formula suite 97/97 with the reference; new suite 89/89 fail on base.
- Mutation: re-wrapping the bare arms in `switchingGuard` (line-anchored) fails exactly the three
  tests carrying at-jump assertions and nothing else.
- Harness over the 11 batch-1 solutions: BASE 89/89 fail, REFERENCE 89/89 pass, 3/11 = 27% pass
  (Nova_Nova_1, Nova_Nova_7, Vega_Nova). No agent fails any at-jump assertion. Remaining failures
  per non-passing run: 2, 2, 2, 4, 4, 4, 5, 6 - spread across self-comparison, invalid-param revive,
  WGSL typing, disjunction true branch and conjunction, no unanimous wall left.
- Clean-room container (fresh clone at base, submission Dockerfile, `--network none --user 1000:1000`),
  3 runs each, identical: without solution.patch base 1301/1301 pass and new 89/89 FAIL; with it
  applied base 1301/1301 pass and new 89/89 pass.
- Host note: two clean-room attempts died from host memory, not from the harness. The first overlapped
  another session's `tj-olympus` container (swap 100%, 102MB free), so I stopped my own run; the second
  was killed by the system while queued behind `tj-final`. The completed matrix pinned each container
  to 2 CPUs (`--cpuset-cpus=0-1`), which makes jest run one worker; host memory stayed above 2.6GB.
  The pin is a local-run flag only: test.sh is unchanged, and batch 1 ran base mode 1301/1301 in all
  11 platform runs with jest's default workers.
- Caveat on the 27%: it is measured on batch-1 solutions graded against the new suite. The description
  change removes a misreading rather than adding a requirement, so fresh agents should behave much like
  batch 1 did, but only the fresh batch confirms it.

## Batch 2 (2026-09-13) - 10 Nova: 1/10 PASS, and that pass was a false positive

No unanimous wall any more (worst test 6/10). Per-run table in eval-results.md; runs in agent-runs/2/.
Three platform findings, all confirmed locally:

1. **FP check: the only passer (Nova_Nova_2) was a false positive.** Its derivative returns NaN for
   `if(if(x < 0, 0, 1) < 1, x, 2 * x)` at x = -1, where the true derivative is 1 (reference: 1). It
   routes the nested `if`'s selected branch VALUE through its condition-switch logic, where "any other
   condition switches where it is zero" fires on the constant 0.
2. **Auto Review: Tests 1/3.** No test checks the values the generated WGSL computes; a raw `select`
   with swapped operands would pass every WGSL assertion.
3. **Solvability.** Testing the FP behaviour kills the lone passer.

### Why the spec itself had to shrink

Broad FP probe battery over all 10 batch-2 solutions (behaviours meta.md states but tests did not pin):

| Probe | Agents that violate it |
|---|---|
| order-independent `and` narrowing (`and(x > y, y > 0)`) | 10/10 (all compose left to right) |
| nested-`if` value branch over-guard (D1) | 8/10 |
| invalid-only operand kept a truth value (`if(or(1, sqrt(-1)), 10, 20)`, `or(1, sqrt(-1))`) | 7/10 |
| `sqrt(-1) == sqrt(-1)` identity range | 4/10 |
| `1e308` `if`-derivative | 4/10 |
| `and`/`or` short-circuit, `!=` / right-side / `or`-false-branch / nested narrowing | 0/10 |

No batch-2 agent was clean on every stated behaviour, so under that description a clean pass was
essentially unreachable, and testing each behaviour instead would have stacked the pass rate back to 0.

The D1 over-guard traces directly to the switching clause. All 10 agents implemented nested-`if`
handling because the clause asked for it (Nova_Nova_7 paraphrases it in a comment); the 8 over-guarders
read "counting a nested `if` only through the branch it selects" as "treat the selected branch as a
condition", while Nova_Nova_4 and Nova_Nova_7 scanned the branch only for comparisons inside it. Same
sentence, two readings - a description defect, not a trap.

### Redesign (user chose "simplify nesting")

- **Switching set is the condition's top-level form only.** meta.md: "Only the condition's top-level
  form counts: a comparison switches where its two sides are equal, `and`, `or` and `not` switch
  wherever an operand, read as a condition, switches, and any other condition switches where it is
  zero. Nothing nested below that form adds a switch." Reference: `switchingGuard` keeps its three
  top-level arms; `guardNestedComparisons` and `guardSelectedBranch` are deleted.
- **Left-to-right `and` / `or` narrowing,** in the plainer prose the precheck asked for: "`not` passes
  restrictions on with the truth flipped. `and` passes them into the branch where it holds and `or`
  into the branch where it fails, applying its operands left to right, so each operand is estimated
  under the restrictions of the ones before it." Reference: the 4-pass fixpoint is replaced by one
  left-to-right pass; `NARROWING_PASSES` and `narrowingsEqual` are deleted.
- **Scoped range precision for invalid operands:** "When an operand can be invalid, the result only
  has to be marked as possibly invalid, and it may keep the truth values the other operands allow."
  The two always-invalid-operand interval assertions are relaxed to `maybeInvalid` only. The reference
  stays more precise, which that sentence permits.
- **Opener component list removed** (flagged HIGH by the description check twice). Every layer is
  still named in the body, and both batches show agents always touch all of them. meta.md 491 words.
- **Tests (92):** the three nested-propagation tests flipped to finite values and renamed
  (`a_nested_logical_call_adds_no_switch`, `a_comparison_nested_under_a_function_adds_no_switch`,
  `a_comparison_inside_a_comparison_adds_no_switch`); new `a_nested_conditional_value_adds_no_switch`
  (D1); `far_apart_operands_are_not_a_switching_point` restored with `if`-wrapped cases; the two branch
  tests now also assert the selected side; and new `generated_wgsl_agrees_with_the_closure_evaluator`.
- **WGSL behaviour test.** No WGSL tool is available offline, and agents invent their own helper
  names (`w_if`, `w_and`, `w_compare_lt`), so the test translates the ENTIRE emitted program
  (`WGSL_RUNTIME_CODE` plus the generated function) to JavaScript generically and compares value and
  invalid flag with the closure evaluator over 23 expressions: raw and wrapped comparisons for all six
  operators at and off equality, all three logical calls, both `if` branches, invalid conditions and
  unselected invalid branches. Fair: it executes all 21 agent solutions from both batches with 0
  crashes and 0 mismatches. Discriminating: swapped raw `select`, swapped `w_select` branches, `<` to
  `<=`, `>` to `>=` and `or` to `and` in the runtime are each caught.

### Redesign validation

- Reference 92/92; base 92/92 fail; formula suites green. One of my own assertions was wrong and was
  removed: `if((x < 3) >= 1, x, 2 * x)` at x = 1 has identically equal sides for every x < 3, so NaN
  is the stated result there.
- Mutations: the full pre-redesign nested `derivative.js` fails the three flipped nested tests; a
  value-branch guard fails D1; a swapped raw `select` fails the WGSL test.
- Property test: 82 usable derivative checks (was 40) against its floor of 30 - fewer guards, more
  finite points.
- LOC 319 human-effective (was 359; the nested machinery and fixpoint are gone). test.sh 100755, 0
  added comments, Dockerfile and BASE_COMMIT unchanged.
- Harness over the 21 old solutions: 0/21, as expected for a description change - the top killers are
  the flipped nested tests (21, 20, 19/21) and D1 (14/21), which every old solution failed because the
  old description required nested propagation. With those four set aside, 3/21 are clean (batch 2's
  Nova_Nova_2, batch 1's Nova_Nova_1 and Vega_Nova), consistent with a ~10-20% fresh-batch estimate.
  Remaining spread: WGSL raw/wrapped 9-11/21, self-comparison and invalid-param revive 10/21,
  far-apart 10/21, disjunction 6/21.

### Clean-room for the redesign: DONE (after the Docker store was repaired)

Result (fresh clone at base, submission Dockerfile, `--network none --user 1000:1000`, each container
pinned to 2 CPUs), 3 runs each, identical: without solution.patch base 1301/1301 pass and new 92/92
FAIL; with it applied base 1301/1301 pass and new 92/92 pass. The batch-3 candidate is fully validated.

The run had to wait behind other sessions' concurrent Docker builds (cwerg-dev, weasyprint-pf-nt4) and
sfepy containers, one of them `sleep infinity`. The script's first guard waited for zero other
containers and could have blocked forever, so it was stopped (own PIDs only, verified by arguments) and
restarted with a memory-only guard (>= 3000MB available). That is safe because the CPU pin keeps jest
at one worker.

History of the pending state, kept for the record:

- The first attempt reported "done" with empty results. Both `docker build` calls had failed, their
  output was sent to /dev/null, and every `docker run` then tried to pull a non-existent image. The
  script checked nothing between build and run. Fixed in `worktrees/cleanroom-r13.sh`: it stops on a
  failed build and inspects each image before running containers.
- The real cause is the local Docker image store: containerd's content blobs are gone
  (`/var/lib/docker` fell from 5.6G to 897M), so `olympus-base-typescript:latest` cannot be inspected,
  listed or built from, and `docker pull` fails with "failed to lease content" because it tries to
  reuse the broken record. Not a submission problem. Cause unknown; the earlier `docker system prune -f`
  runs in this session may have raced another session's builds, which is unconfirmed.
- Repair needs removing the broken record or resetting the store, which is machine-wide state the
  other workstream shares, so the user is doing it. Once Docker works:
  `bash /home/ahmed/Olympus/worktrees/cleanroom-r13.sh`
- Mitigation meanwhile: Dockerfile and test.sh are byte-identical to the ones batches 1 and 2 ran on
  the platform (baseline 1301/1301 in all 21 runs), and the new suite passes 92/92 locally with the
  reference. What remains unverified is only that the new test file runs inside the image.
- Going forward: no `docker system prune` from this session while another session may be building.

### Test Quality advisory on the batch-3 candidate: two coverage gaps closed (test-only)

The check marked two prompt-stated requirements "partial" and suggested a discriminator for each.
Both were taken, since batch 3 has not run and test-only changes are free now.

- **`or` in an arithmetic position.** "They may appear anywhere an expression may" was covered for
  comparisons, `if`, `and` and `not`, but not `or`. `conditionals_in_power_and_unary_positions` now
  also asserts `2 + or(x, y)` (2 at (0,0), 3 at (0,3)) and `or(x, y) * 5 - 1` (4 at (-2,0)). All 21
  old solutions already get these right, so it pins the rule at no difficulty cost.
- **Dependent left-to-right `or` narrowing.** New
  `disjunction_narrowing_composes_through_a_dependent_comparison`:
  `if(or(y <= 0, x <= y), 7, sqrt(x))` with x, y in [-1, 1] must be never-invalid and cover 7 and 1.
  The false branch proves `x > 0` only when `y > 0` from the first operand is applied before
  estimating the second. Probe over the 21 old solutions: all 10 batch-2 solutions pass; in batch 1,
  Nova_Nova_2, Nova_Nova_4 and Nova_Nova_6 report maybe-invalid - exactly the three that failed the
  `and` counterpart - so it overlaps rather than adding a trap. One more, batch-1 Nova_Nova_1, drops
  the selectable false branch entirely (`[7, 7]` only), a real over-pruning bug the `covers 1`
  assertion now catches instead of leaving it for the FP panel.

Validation: reference 101/101 on the formula suites; new suite 93/93 fail on base; a mutation that
estimates the second `and`/`or` operand without the first operand's restriction fails both dependent
narrowing tests (plus six related narrowing tests); restored 93/93. Patches regenerated: 93 tests,
test.sh 100755, 0 added comments, LOC 319. meta.md, Dockerfile and BASE_COMMIT untouched this round.

Clean-room rerun on the 93-test patches (fresh clone at base, submission Dockerfile, `--network none
--user 1000:1000`, 2-CPU pin), 3 runs each, identical: without solution.patch base 1301/1301 pass and
new 93/93 FAIL; with it applied base 1301/1301 pass and new 93/93 pass. Batch-3 candidate validated.

## Auto Review on the batch-3 candidate (2026-09-14): Revision Requested - 2 High + 2 Medium, all fixed

Description 3/3; Tests 1/3; Solution 1/3. All four findings reproduced before any change.

| Finding | Verified | Fix |
|---|---|---|
| T3/T4 High: WGSL never validated as WGSL (the JS translation accepts `!==` or an f32 `select` condition) | yes | real naga validator added (below) |
| S1 High: WGSL rounds literals to f32, closure/JS compare binary64, so branches diverge | yes, wider than reported | comparisons and truth tests in the f32 domain (below) |
| T4 Medium: no comparison parsed without spaces | yes (reference already fine) | `comparisons_parse_without_spaces` |
| T4 Medium: no bare-parameter operand of a top-level `and`/`or`/`not` tested for switching | yes (reference already fine) | `bare_logical_operands_switch_where_they_are_zero` |

### S1 - CPU and GPU could take different branches

`if(1 < 1.00000001, 10, 20)` returned 10 in the closure, generated JS and wrapped evaluator, but WGSL
emits both literals as `1.0` and returns 20. The same class also hit truth tests (`if(1e-50, 10, 20)`:
10 on CPU, `0.0` in WGSL) and parameter inputs (`x == 1` at x = 1.00000001: 0 on CPU, 1 in WGSL,
where inputs are packed as f32).

Fix: the closure evaluator and the JS generator now compare `Math.fround` values and use
`Math.fround(v) !== 0` for `if` / `and` / `or` / `not` truth. The range estimator already worked in
f32. meta.md gained "Comparisons and truth tests use values rounded to 32-bit floats, as WGSL does."
(the assignment sentence was tightened to stay under the cap: 499 words). New
`comparisons_and_truth_tests_use_32_bit_values` checks the literal, truth, `and`/`or`/`not` and
parameter cases on all three CPU evaluators and against the executed WGSL.

Out of scope, noted: huge values (e.g. 1e308) are finite on the CPU but overflow f32 in WGSL, a
pre-existing domain difference in the base repo's arithmetic; `guardNonzero` truth is base code.

### T3/T4 - a real WGSL validator

No WGSL tool ships with the repo. npm candidates tried: `wasm-naga` 0.3.2 is a 2021 naga that
rejects even a tiny modern snippet; `wgsl_reflect` will not load in Node (mis-declared package);
`naga-wasi-cli` 0.1.0 (modern naga under Node's WASI, 2.2MB bundled wasm) works: raw and wrapped
reference shaders validate, `!==` is a parse error (exit 1) and an f32 `select` condition fails
validation (exit 255).

- Dockerfile: `npm install --no-save --ignore-scripts naga-wasi-cli@0.1.0` after `npm ci`. No
  network needed when tests run; base image Node is v24.15.0 (WASI needs >= 20).
- New `generated_wgsl_is_valid_wgsl`: runtime plus each generated function, one shader per
  expression, validated by naga. One module per shader on purpose, since solutions may inline helpers
  and concatenating would fake redefinition errors. naga is run with its cwd set to a temp directory
  and a relative filename: an absolute temp path fails under WASI ("No such file or directory (os
  error 44)").
- Fairness: all 27 test shaders validate for the reference and 18 of the 21 old solutions. The other
  three (batch 2 Nova_Nova_5 and Nova_Nova_7, batch 1 Nova_Nova_9) name a helper parameter
  `operator`, a WGSL reserved word, so every WGSL implementation rejects them - a genuine
  production-breaking bug, not naga strictness.
- Test design: the f32 boundary cases were first added to the general WGSL agreement test, which
  made every old solution fail two tests for one miss (the pre-restructure harness showed 21/21 on
  both). They now live only in the f32 test; the agreement test keeps 24 plain-semantics cases in
  `WGSL_BEHAVIOUR_CASES`. (The first attempt at that name collided with the round-2 `WGSL_CASES`
  battery and stopped the file loading; renamed.) The translator's inputs are now packed with
  `Math.fround`, as WebGPU does.

### Validation

- Reference 105/105 on the formula suites; base-mode suites 1301/1301; new suite 97/97 fail on base.
- Mutations, each caught by exactly one test: WGSL `!=` emitted as `!==` fails only
  `generated_wgsl_is_valid_wgsl` (the JS-translation agreement test still passes - precisely the gap
  the reviewer found); an f32 `select` condition fails `generated_wgsl_is_valid_wgsl`; generated JS
  comparisons without `fround` fail the f32 test.
- Patches regenerated: 97 tests, test.sh 100755, 0 added comments, no banned markers, LOC 319.
- Local-only note: `npm install --no-save` of the validator pruned a locally installed `jest-junit`,
  so `./test.sh` on this host falls back to its synthetic JUnit failure. The base image has
  `jest-junit` globally at `/usr/lib/node_modules/jest-junit`; the clean-room is the authority.
- Difficulty: the f32 rule is new and stated; every old solution fails it (they predate it), so the
  harness cannot predict it. It is the most likely new miss in batch 3.
- Harness, final 97-test suite over the 21 old solutions (informative only - description-driven
  tests cannot be predicted from solutions written for older descriptions):
  - `generated_wgsl_agrees_with_the_closure_evaluator` 0/21 (the double counting is gone),
    `generated_wgsl_is_valid_wgsl` 3/21 (the reserved `operator` parameter),
    `comparisons_parse_without_spaces` 0/21, `bare_logical_operands_switch_where_they_are_zero` 1/21,
    `disjunction_narrowing_composes_through_a_dependent_comparison` 4/21.
  - Description-driven: `comparisons_and_truth_tests_use_32_bit_values` 21/21 and the top-level
    switching tests 21, 20, 19/21, D1 14/21.
  - Spread traps unchanged: WGSL raw/wrapped 9-11/21, self-comparison and invalid-param revive 10/21,
    far-apart 10/21, disjunction true branch 6/21.
  - Clean apart from the description-driven tests: 2/21 (batch 2 Nova_Nova_2, batch 1 Vega_Nova),
    down from 3 because batch 1 Nova_Nova_1's over-pruning is now caught.
- Clean-room with the new Dockerfile (naga-wasi-cli installed; fresh clone at base; `--network none
  --user 1000:1000`; 2-CPU pin), 3 runs each, identical: without solution.patch base 1301/1301 pass
  and new 97/97 FAIL; with it applied base 1301/1301 pass and new 97/97 pass. This confirms the
  validator runs offline as a non-root user and that JUnit output works in the image. The memory
  guard held containers back 29 times while other work used the host. Batch-3 candidate validated.

## Solution Quality on the revision (2026-09-14): f32 intermediate rounding - resolved by scoping agreement

Verdict FAIL, one high finding, and it is real: rounding only the final comparison operands cannot
match WGSL, which rounds at every f32 node. `if(x + 1 - x > 0.5, 1, 0)` at x = 16777216 returns 1 in
the JavaScript paths (doubles: the cancellation is exact) and 0 in WGSL (`16777216.0 + 1.0` rounds
back to `16777216.0`).

Options weighed:
- Emulate f32 at every arithmetic node in the closure and generated JS: changes the base repo's numeric
  semantics for every existing formula - an unrelated behaviour change.
- Emulate f32 only inside condition subtrees: shared DAG nodes would need a parallel f32 evaluation
  path in both JavaScript evaluators - a large new requirement agents would have to reproduce.
- Scope the promise to what the base design can deliver: the JavaScript evaluators work in doubles and
  WGSL in 32-bit floats, so they can only be expected to agree while values stay exactly representable
  in f32. Chosen.

This also covers the earlier Auto Review S1 case (`1.00000001` is not f32-representable either). That
review's own "strongest disproof" was that WGSL is f32 by design; it failed only because the
description promised agreement unconditionally.

Changes:
- meta.md: "The closure evaluator, the generated JavaScript and the WGSL agree while every value
  involved is exactly representable as a 32-bit float;" and the sentence about rounding comparisons and
  truth tests to 32-bit floats is removed. 497 body words.
- Reference: the `Math.fround` rounding added last round is reverted in `dag-evaluator.js` and
  `dag-js-generator.js` (exactly the 18 calls added per file; neither file now differs from base in
  that respect).
- Tests: `comparisons_and_truth_tests_use_32_bit_values` removed. It was also the requirement every old
  solution missed (21/21), so removing it helps solvability. The naga validity test, the WGSL agreement
  test (24 representable cases), space-free parsing and bare logical switching stay.
- Coverage suggestion taken: right-side `==` / `!=` narrowing - `if(4 == x, sqrt(x), 0)` added to
  `equality_narrows_to_the_other_side` (never invalid, values {0, 2}, exactly like `x == 4`) and
  `if(0 != x, 1 / x, 7)` to `inequality_does_not_narrow` (maybe invalid). Declined: the table-driven
  expression-position test (the check itself calls it not discriminating) and the five description
  trims (each sentence is anchored by tests; the agreement clause now also carries the f32 scope).

Validation: reference 104/104 on the formula suites; base-mode suites 1301/1301; new suite 96/96 fail
on base; a mutation that stops narrowing right-side parameters fails `equality_narrows_to_the_other_side`
(the new flipped case), `narrowing_a_right_side_parameter` and `strict_bounds_exclude_the_bound_itself`;
restored 96/96. Patches regenerated: 96 tests, 0 `fround` in added solution lines, 0 added comments, no
banned markers, LOC 319. Dockerfile unchanged from the naga revision.

Clean-room on the 96-test patches (fresh clone at base, submission Dockerfile with naga-wasi-cli,
`--network none --user 1000:1000`, 2-CPU pin), 3 runs each, identical: without solution.patch base
1301/1301 pass and new 96/96 FAIL; with it applied base 1301/1301 pass and new 96/96 pass. Batch-3
candidate validated.

Lesson: when two reviews pull on the same seam (literal rounding, then intermediate rounding), look
for the boundary the base design already has before stacking another emulation layer. Stating that
boundary precisely ended the cycle and removed a requirement instead of adding one.

## Solution Quality (2026-09-14): later `and`/`or` operand infeasible under earlier restrictions - fixed

Verdict FAIL, one high finding (Code Quality 2/3). The gap is real, though the grader's exact example
was already handled.

- Grader's case `if(and(x > 0, x < sqrt(0 - x)), 100, 7)` with x in [-1, 1]: the reference already
  reported {7}, maybe invalid - narrowing x by `x < sqrt(0 - x)` empties the parameter and the existing
  empty-restriction rule drops the branch.
- The mechanism the grader described does leak, though: when a later operand cannot take the required
  truth value under the earlier restrictions, nothing checked it. Before the fix, 100 leaked for
  `and(x > 0, x < sqrt(0 - x - 1))` (the comparison's other side is always invalid, so
  `restrictByComparison` returns "no restriction"), for a plain numeric operand
  `and(x > 0, sqrt(0 - x - 1) + 1)`, and for the `or` false-branch counterparts. Sampling confirms
  only 7 or NaN ever occur.

Fix (`range-estimator.js`): `and`/`or` narrowing now estimates each operand under the restrictions of
the operands before it (`canYieldTruth`); if it cannot take the required truth value (true for `and`,
false for `or`) - including when it is always invalid - `narrowParameters` returns an `UNSELECTABLE`
marker that `not` passes through and `estimateBranch` turns into a dropped branch. No meta.md change:
the grader quoted the sentences that already state this.

Precision boundary, deliberately not tested: `and(x > 0, sqrt(0 - x) + 1)` still reports 100. Not a
logic gap - the estimator rounds interval bounds outward for soundness, so under x > 0 the bound of
`0 - x` touches 0 and `sqrt` looks valid there. The description promises no precision at that level,
so the regression test uses shapes whose infeasibility survives the rounding (`- 1` keeps the operand
well away from the domain edge).

New `a_later_operand_that_cannot_hold_leaves_the_branch_unselectable`: the grader's case plus the four
rounding-robust shapes; each asserts 100 not covered, 7 covered, maybe invalid.

Validation: reference 105/105 on the formula suites; base-mode 1301/1301; new suite 97/97 fail on
base; both the whole pre-fix estimator and removing only the second-operand check fail exactly the new
test; random range soundness still 3000/3000, so no reachable branch is pruned; restored 97/97.
Patches regenerated: 97 tests, 0 added comments, no banned markers, LOC 329 (was 319). meta.md and
Dockerfile untouched this round.

Harness, 97-test suite over the 21 old solutions: `a_later_operand_that_cannot_hold_leaves_the_branch_unselectable`
fails 14/21. Unlike the f32 rule this is NOT a new description requirement - the left-to-right and
unselectable-branch sentences already existed when those solutions were written - so it predicts fresh
agents. Clean apart from the top-level switching tests drops from 2/21 to 0/21 (it catches both
remaining candidates, batch 2 Nova_Nova_2 and batch 1 Vega_Nova). Same tested-trap vs untested-FP
dilemma as the earlier redesigns.

Decision (user): scope the pruning promise in meta.md and drop the test, the same move that closed the
f32 seam.
- meta.md: "A branch whose restriction leaves a parameter no values at all cannot be selected" became
  "A branch counts as unselectable when the condition's estimated range cannot select it or its
  restriction leaves a parameter no values; other unreachable branches may still be included." That
  names exactly the two mechanisms most agents implement and permits both less and more precise
  estimators. It also covers the outward-rounding shape (`sqrt(0 - x) + 1`) that no correct estimator
  can prove impossible.
- Word budget: removed "Nothing nested below that form adds a switch" (it restates "Only the condition's
  top-level form counts", flagged LOW) and shortened the left-to-right clause to "applying its operands
  left to right, each under the restrictions of the ones before it". 499 body words.
- Reference keeps `canYieldTruth` as sound extra precision the description now allows; the test is
  removed. Remaining pruning tests stay anchored: `x < x` and the contradictory / invalid-param cases by
  the emptied restriction, `unselectable_branch_contributes_nothing` by the condition's own range.
- Validation: reference 104/104 on the formula suites (random range soundness 3000/3000); new suite
  96/96 fail on base; patches regenerated (96 tests, 0 added comments, no banned markers, LOC 329).
  The clean-room of the intermediate 97-test candidate was green (base 1301/1301; new 97/97 fail
  without, pass with), confirming the unchanged solution and Dockerfile in the container.
- Effect on the old-solution harness: back to 2/21 clean apart from the top-level switching tests.
- Clean-room on the final 96-test patches (fresh clone at base, submission Dockerfile with
  naga-wasi-cli, `--network none --user 1000:1000`, 2-CPU pin), 3 runs each, identical: without
  solution.patch base 1301/1301 pass and new 96/96 FAIL; with it applied base 1301/1301 pass and new
  96/96 pass. Batch-3 candidate validated.

Lesson reinforced: when a grader's finding is a precision gap in an estimator, the fix belongs in the
reference, but whether it becomes a graded requirement is a separate call. Measure the miss rate on
existing solutions first; a 14/21 miss on a stated-but-subtle precision rule is a description-scoping
problem, not a trap.


Declined: real WGSL execution (still impossible offline; naga validates and the translator executes)
and the five description trims (each sentence anchors tests; "Nothing nested below that form adds a
switch" is what stops the nested-guard false positive).

## Test Quality (2026-09-14): 1 of 96 unfair - WGSL agreement case outside the f32-exact domain - fixed

The finding is correct. After agreement was scoped to "every value involved is exactly representable as
a 32-bit float", `generated_wgsl_agrees_with_the_closure_evaluator` still evaluated
`if(sqrt(x) >= 1, 1 / (x - 1), 7)` at x = 4, whose result 1/3 is not f32-representable; real f32 WGSL
gives about 0.3333333433, outside the test's 1e-9 tolerance. It is the only test that executes WGSL, so
fixing its case list closes the finding.

Fix (test only):
- That case now uses range [-1, 9] and points [-1, 0.25, 1, 9]: `sqrt(9) = 3` and `1 / 8 = 0.125` are
  exact, and the four behaviours stay covered - invalid condition (-1), unselected branch (0.25),
  selected invalid branch (1, i.e. 1/0), selected valid branch (9). The range still includes 1, so the
  lowering stays wrapped.
- The 1e-9 tolerance is replaced by exact equality, since every case is now inside the promised domain.

Audit instead of trusting a manual read: every case and point of `WGSL_BEHAVIOUR_CASES` was run through
the translator twice - once in doubles and once with `Math.fround` applied to every f32 variable, as
real WGSL would - and compared with the closure: 74 points, 0 disagreements. Reference 96/96.

Not changed (advisory): the regex WGSL-to-JavaScript translator coupling (naga now does the real WGSL
validation; within the exact domain the translation is semantically faithful, as the audit shows), and
the "undeclared `naga-wasi-cli` dependency" note (the Dockerfile installs it and every clean-room run
has exercised it).

Validation: reference 104/104 on the formula suites; new suite 96/96 fail on base; patches regenerated
(96 tests, no 1e-9 tolerance left, 0 added comments, no banned markers, LOC 329). solution.patch,
meta.md and Dockerfile unchanged this round.

Clean-room on the corrected test patch (fresh clone at base, submission Dockerfile with naga-wasi-cli,
`--network none --user 1000:1000`, 2-CPU pin), 3 runs each, identical: without solution.patch base
1301/1301 pass and new 96/96 FAIL; with it applied base 1301/1301 pass and new 96/96 pass. Batch-3
candidate validated.

## Task Quality + Verify Solution (2026-09-14): the naga validator test - replaced with a self-contained check

Two FAILs with one cause:
- Task Quality criterion 4 (fairness): `generated_wgsl_is_valid_wgsl` resolves and runs `naga-wasi-cli`,
  which neither `package.json` nor `package-lock.json` declares, so a contributor with a normal checkout
  cannot run it.
- Verify Solution: that same test FAILED on the platform with the solution applied, although every local
  clean-room run with the same Dockerfile passed it. The platform's environment evidently differs from
  the local clean-room (different build path, skipped install, or a reused image); no platform log was
  available to say which. Either way, an external tool is the fragile part.

Why not just declare the dependency: the image runs `npm ci` before test.patch is applied, so a
dependency added through test.patch would not be installed, and a CLI subprocess has already failed once
under the platform's conditions.

Fix: a dependency-free WGSL check - exactly the fallback the Auto Review named as acceptable ("at minimum
add direct syntax/type checks ... reject JavaScript-only ===/!== and assert that raw if/logical select
conditions are bool expressions").
- New `generated_wgsl_uses_wgsl_operators_and_boolean_select_conditions` (replaces
  `generated_wgsl_is_valid_wgsl`): over the runtime plus every generated function in
  `WGSL_BEHAVIOUR_CASES`, it rejects JavaScript-only syntax (`===`, `!==`, `=>`, `?`, `**`) and requires
  every `select(...)` to take a bool condition - a comparison, `&&`/`||`/`!` of bools, `true`/`false`, a
  bool variable, parameter or struct field, or a call to a function declared `-> bool`. It relies on no
  helper names, so solutions that invent their own helpers are judged fairly.
- Test file: the naga helper, its temp-file handling and the `node:child_process`, `node:fs`,
  `node:module`, `node:os` and `node:path` imports are gone.
- Dockerfile reverted to the committed original (byte-identical); nothing needs naga any more.
- Trade-off, accepted: this does not catch everything a real compiler would (for example the reserved
  `operator` keyword three old solutions used), but it covers both failure modes the reviewer named and
  runs anywhere.

Fairness, checked before trusting it: across 43 shaders (the 24 behaviour cases plus the round-2
19-expression battery), the reference and all 21 old agent solutions pass with 0 rejections; the
reference with JavaScript `!==` injected is rejected (2 shaders), and with an f32 `select` condition
injected is rejected (5 shaders).

Process slip, fixed: the first Dockerfile revert used a relative path while the shell sat in the
ray-optics worktree, so it wrote a stray untracked `Dockerfile` there and left the problem's Dockerfile
unchanged. The stray file was deleted and the revert redone with an absolute path.

Validation: reference 104/104 on the formula suites; new suite 96/96 fail on base; injecting JavaScript
`!==` into the WGSL generator, or an f32 `select` condition, each fails only
`generated_wgsl_uses_wgsl_operators_and_boolean_select_conditions`; restored 96/96. Patches regenerated
(96 tests, 0 naga / child_process references, 0 added comments, no banned markers, LOC 329); meta.md
499 words; Dockerfile byte-identical to the committed original.

Platform re-run of the PREVIOUS (naga) version, run by the user without the replacement: Task Quality
PASS (its undeclared-dependency objection did not recur that time), Verify Solution FAIL again on
`generated_wgsl_is_valid_wgsl`. The naga test fails deterministically on the platform even though it
passes in every local clean-room, so the version with the naga validator cannot pass Verify Solution
and the self-contained replacement is required, not optional.

Clean-room of the replacement with the ORIGINAL Dockerfile (no naga install; fresh clone at base,
`--network none --user 1000:1000`, 2-CPU pin), 3 runs each, identical: without solution.patch base
1301/1301 pass and new 96/96 FAIL; with it applied base 1301/1301 pass and new 96/96 pass. The base
image alone runs the whole suite, including the self-contained WGSL check. Ready to upload.

### Carry-forward lessons

- The FP check does not care whether a behaviour is tested, only whether the description states it.
  A dense spec whose every clause is either tested (traps stack) or untested (FP exposure) cannot
  produce a clean pass; the fix is to state less, not to test differently.
- Probe the batch's own solutions against every stated-but-untested sentence before redesigning; the
  miss-rate table picks the clauses to delete.
- A code comment that paraphrases the prompt is direct evidence of which sentence drove a design.

## Batch 3 (2026-09-14) - 9 Nova + 1 Vega: 1/10 PASS (Vega), ACCEPTED

Human reviewer accepted the problem after this batch. Per-run table in eval-results.md.

- Four seams carried the band, each an exception to a rule the agents otherwise implemented: identical
  operands in the range estimator (7/10, F-26), `or` narrowing its true branch (6/10, F-27), a raw
  comparison over a wrapped operand in WGSL (6/10, F-10, the sole failure of the 94/96 near-miss) and
  subtraction-based equality in the derivative (3/10, F-23 family).
- 17 of the 40 kill events came from tests written for Solution Quality findings against the
  reference (rounds 4, 5, 10), 2 from a Test Quality advisory, 5 from the round-2 fairness rewrite and
  16 from designed tests.
- Killed nothing: WGSL agreement, the in-process WGSL check, no-space parsing, bare logical switching,
  the remaining nested "adds no switch" tests, and every parser reject test.
- Finalized: mined into failure-patterns.md (F-26, F-27, L52-L56, dossier), the skills, the
  Instructions files and approved-problems/README.md.

## Predicted traps (to compare against the batch)

1. Statement splitter treats `<=`, `>=`, `==`, `!=` as assignments (F-6/F-3).
2. Range of `if` unions both branches' invalidity / values regardless of selectability (F-9; also drives the WGSL raw-vs-wrapped guard profile).
3. Derivative switching set: guardNonzero on the comparison value instead of the sides' difference, or on only one operand of and/or (F-8 via the repo's abs/min convention).
4. Raw WGSL select with a wrapped (unselectable) branch operand needs `.value` (F-10 cell, codebase-inferable).
5. Narrowing: missing negation for the false branch, missing flip for a right-side parameter, closed instead of strict bounds, `!=` narrowing, and/or composition on the wrong branch.

## Attempt history

| # | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-11 | Authored end to end | validated locally + in a clean-room container |
| 1 | 2026-09-11 | Submit-time gate re-run: human-effective 289, exclusivity PR-DIFF clean (canonical org unchanged, only dependabot PRs in the class), no issue in the class, master HEAD still == base commit (zero post-base activity), repo quota 0/6, test.sh 100755, no banned markers, meta.md ASCII 495 body words | handed off for batch 1 |
| 2 | 2026-09-11 | Platform precheck round: fixed both Solution Quality bugs, rewrote the 10 unfair WGSL/JS tests onto base-visible observables, de-brittled parser diagnostics, deleted the base-passing test, trimmed meta.md and added the unreachable-branch sentence | 75 tests, 75/75 fail on base, LOC 302; awaiting batch 1 |
| 3 | 2026-09-11 | Second precheck: fixed the nested-if switching guard and the stale-range narrowing (now a fixpoint), clarified precedence in meta.md, added 3 tests | 78 tests; awaiting batch 1 |
| 4 | 2026-09-12 | Third precheck: nested-comparison traversal, self-comparison branch pruning, functionName/runtime-helper collision guard, WGSL rule now names the logical functions, 2 tests + arity negatives | 81 tests; awaiting batch 1 |
| 5 | 2026-09-12 | Fourth precheck: empty narrowed domain now prunes regardless of maybeInvalid, + 1 test | 82 tests; awaiting batch 1 |
| 6 | 2026-09-12 | Fifth precheck: switching-set traversal is now selection-aware through a nested if (runtime-selected guard chain), + 1 test | 83 tests; awaiting batch 1 |
| 7 | 2026-09-12 | Sixth precheck: invalid-only operands no longer yield a truth value in estimateLogic or the identical-comparison shortcut, 3 coverage suggestions taken, 3 meta examples trimmed, 2 clause removals declined | 87 tests, LOC 357; awaiting batch 1 |
| 8 | 2026-09-12 | Seventh precheck: nested and/or/not now delegate to switchingGuard so a logical call under a comparison or arithmetic keeps its zero-crossing switch, + 2 tests, 3 description declines | 89 tests, LOC 359; awaiting batch 1 |
| 9 | 2026-09-12 | Eighth precheck, first Test Quality FAIL since r2: generalized the switching-set rule in meta.md to cover nesting (keeps the trap, fair), deleted the non-bare identity assertion (unstated optimisation), + 1 test | 90 tests, meta 464 words; awaiting batch 1 |
| 10 | 2026-09-12 | Ninth precheck: comparison guard tested equality by subtracting, which overflowed to NaN on far-apart finite operands; now guards on a `!=` node, + 2 tests (incl. and()/or() arity hole) | 92 tests, LOC 359; awaiting batch 1 |
| 11 | 2026-09-13 | Tenth precheck: a plain numeric selector of a nested `if` produced no switching guard; selector now routed through switchingGuard, + 2 tests, 4 description declines | 94 tests, LOC 359; awaiting batch 1 |
| 12 | 2026-09-13 | Batch 1 = 0/11 (bare-derivative description misread 11/11 + trap stacking). Route B: bare comparison/logical derivatives 0 everywhere (meta + reference), 5 edge tests dropped, bare-switch NaN assertions replaced by at-jump zeros, conjunction natural order only, round-12 sentence splits applied | 89 tests, harness-predicted 3/11 = 27%; awaiting batch 2 (full price) |
| 13 | 2026-09-13 | Batch 2 = 1/10, the pass FP-flagged (nested-if value over-guard); Auto Review Tests 1/3 (no WGSL behaviour test). Redesign: top-level-only switching, left-to-right and/or, scoped invalid-operand precision, opener list dropped, D1 + far-apart + WGSL behaviour tests | 92 tests, LOC 319, meta 491 words; awaiting batch 3 (full price) |
| 14 | 2026-09-14 | Auto Review revision (2 High + 2 Medium): f32-domain comparisons/truth tests (meta + reference), real naga WGSL validation via naga-wasi-cli in the Dockerfile, no-space parsing and bare logical switching tests | 97 tests, LOC 319, meta 499 words; awaiting batch 3 (full price) |
| 15 | 2026-09-14 | Solution Quality: f32 intermediate rounding still diverged. Scoped evaluator agreement to f32-representable values in meta, reverted the fround rounding and its test, added right-side ==/!= narrowing assertions | 96 tests, LOC 319, meta 497 words; awaiting batch 3 (full price) |
| 16 | 2026-09-14 | Solution Quality: later and/or operand infeasible under earlier restrictions leaked its branch; added per-operand feasibility (UNSELECTABLE) in narrowParameters, + 1 test | 97 tests, LOC 329, meta 497 words; awaiting batch 3 (full price) |
| 17 | 2026-09-14 | Feasibility test failed 14/21 old solutions (0/21 clean). Scoped unselectable-branch rule in meta (two mechanisms, others may remain), dropped the test, kept canYieldTruth as allowed precision, trimmed redundant nested-switch sentence | 96 tests, LOC 329, meta 499 words; awaiting batch 3 (full price) |
| 18 | 2026-09-14 | Test Quality: WGSL agreement test used a non-f32-representable point (1/3). Moved that case to exact points (x = 9), exact equality instead of 1e-9; 74-point f32 audit clean | 96 tests; awaiting batch 3 (full price) |
| 19 | 2026-09-14 | Task Quality (undeclared naga-wasi-cli) + Verify Solution (naga test failed on platform): replaced naga with a self-contained WGSL operator/select-condition check (0/21 false rejections, both mutations caught), Dockerfile reverted | 96 tests; awaiting batch 3 (full price) |
| 20 | 2026-09-14 | Batch 3 on the round-19 artifact | **1/10 (Vega_Nova), ACCEPTED by the human reviewer**; finalized and archived to approved-problems/ |
