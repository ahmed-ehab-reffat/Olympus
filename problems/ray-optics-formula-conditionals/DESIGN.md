# DESIGN.md — ray-optics-formula-conditionals

## 1. Title
Add comparison operators and conditional selection to the formula engine

## 2. Shape classification
- Shape: O-Composite-add. One new value form (comparison / `if`) threaded through every stage of `src/core/formula`: parser (incl. the statement splitter), syntax tables, closure evaluator, JS code generator, WGSL code generator (+ its guard profile and runtime), symbolic derivative, interval range estimator (with branch narrowing).
- SHAPES.md § Pattern 11: new construct + cascading through a multi-backend pipeline; parity between backends is the kernel.
- Pass target: 20-35%. Best agent: Orion. Dominant verdict: MISSED_REQUIREMENT (a backend or the splitter left out) / REGRESSION (existing formula tests).

## 3. Public API surface
Existing entry points only: `parseFormula`, `createDagEvaluator`, `createDagClosureEvaluator`, `generateDagJsEvaluator`, `generateDagWgslFunction`, `createDagWgslSpecialization`, `appendPartialDerivatives`, `estimateDagRanges`, `isValidFormulaParameterName`, `substituteParameters`, `extractParameters`, `combineDags`.
New language surface: binary operators `<`, `<=`, `>`, `>=`, `==`, `!=` (value 1 or 0); ternary function `if(condition, whenTrue, whenFalse)`; `if` becomes a reserved name. DAG representation: comparisons are `binary` nodes with the operator as `op`; `if` is a `call` node named `if` with three args.

## 4. Canonical output form (all stated in meta.md)
- Precedence: comparisons bind looser than `+`/`-`; `a < b + 1` compares `a` with `b + 1`. Comparisons do not chain: `a < b < c` is a parse error.
- Assignment detection: a statement is an assignment only at a lone `=`; `==`, `<=`, `>=`, `!=` never start one, so `y = x <= 1` assigns.
- Truth: a comparison yields 1 when it holds and 0 otherwise. `if` selects whenTrue when the condition is nonzero and whenFalse when it is zero.
- Invalid values: a comparison with an invalid operand is invalid; an `if` with an invalid condition is invalid; the branch that is not selected never makes the result invalid.
- Derivative: a comparison's derivative is 0 except on the set where its two sides are equal, where it is invalid; the derivative of `if` is the derivative of the selected branch, invalid exactly where the condition switches (sides equal for a comparison condition, condition zero otherwise). Same convention as abs/min/max.
- Range estimation: comparison ranges are subsets of {0, 1}; the `if` range is the union of the branches the condition can select; a branch that cannot be selected contributes neither values nor invalidity; when the condition is a comparison with a bare parameter on one side, that parameter's range is restricted inside each branch to the values that make the branch selectable (strict/non-strict handled as closed intervals).
- WGSL: same value semantics through both the raw f32 lowering and the wrapped (W) lowering; the generator may use either as its range analysis allows.
- JS generator, closure evaluator and WGSL agree.

## 5. Blind-spot pre-empts
- statement splitter (compound-order): stated.
- unselected-branch invalidity (falsy-on-invalid): stated.
- narrowing (rule-resolution): stated.
- 1 codebase-inferable: WGSL W-vs-f32 lowering of a raw `if` whose unselectable branch is wrapped.

## 7. File footprint
| Path | Raw delta | Meaningful |
|---|---|---|
| formula-syntax.js | +6 | 5 |
| formula-parser.js | +45 | 38 |
| dag-evaluator.js | +25 | 20 |
| dag-js-generator.js | +25 | 20 |
| dag-wgsl-generator.js | +75 | 60 |
| derivative.js | +40 | 32 |
| range-estimator.js | +120 | 100 |
TOTAL ~335 raw / ~275 meaningful across 7 files.

## 8. Solution outline
- parser: `parseComparison()` above `parseAdditive()`; `findTopLevelAssignment` skips comparison `=`; `if` via `parseFixedFunctionArguments(name, 3)`; TERNARY_FUNCTIONS set.
- evaluator/js-gen: `compare(op, l, r)` helper semantics; `conditional(c, a, b)`.
- wgsl: `generateRawComparison`, `w_compare(a, b, op)`, `w_select(c, a, b)`, `asF32` for raw select operands, guard profile passthrough.
- derivative: `derivativeOfComparison`, `derivativeOfConditional` using `switchingGuard(node)`.
- range-estimator: `estimateComparison(op, l, r)`, `estimateConditional(node, parameters, values, dag)` with `narrowParameter(op, side, other)` and `estimateSubtree(dag, id, parameters, cache)`.

## 9. Test outline
test/formula/cases/test-conditionals-<hex>.js + a wrapper test/formula/conditionals-<hex>.test.js (jest testMatch already covers test/formula/**/*.test.js; the wrapper requires the case file like formula.test.js does). Buckets: parsing (precedence, chaining error, `if` arity, reserved name, assignment splitter for each operator, `=` inside parentheses), evaluation parity (closure vs compiled, all six ops, truthiness, invalid propagation, unselected invalid branch), derivative (comparison zero, if selected branch, switching invalidity, nested if, chain rule inside branch, numeric check), ranges (subset of {0,1}, definite conditions prune, union, invalidity rules, narrowing on each operator both sides, narrowing through nested expressions, seeded random soundness), WGSL (raw select, wrapped select, w_compare, raw if with wrapped unselectable branch, specialization equality), substitution/extraction/combination preserve new nodes.

## 11. Predicted trap matrix
| # | Trap | F-id | Axis | Interdependent with |
|---|---|---|---|---|
| 1 | statement splitter treats `<=`/`==` as assignment | F-6 ordering / F-3 second collection | parsing | 2 (tests of every backend go through parsing) |
| 2 | range of `if` unions both branches' invalidity | F-9 | ranges | 4 (WGSL guard profile derives raw/wrapped from it) |
| 3 | derivative of comparison/if via guardNonzero on the wrong quantity | F-8 (repo's own abs/min convention) | derivative | 2 (guardNonzero range rules) |
| 4 | raw WGSL select with a wrapped operand | F-10 cell | wgsl | 2 |
| 5 | narrowing not applied / applied to the wrong branch or side | S2 composition | ranges | 2 |

## 11b. Cross-product
ops {<,<=,>,>=,==,!=} x side {parameter left, parameter right} x branch {true,false} for narrowing; backend {closure, compiled, wgsl-raw, wgsl-wrapped} x construct {comparison, if}.

## 12. Tier + category
Olympus; feature-request.

## 13. Predicted pass rate
25-35%.
