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
