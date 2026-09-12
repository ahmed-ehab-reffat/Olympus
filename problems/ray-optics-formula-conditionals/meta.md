---
Repository: https://github.com/ricktu288/ray-optics
Issue: N/A
Commit: e55947ecf4cc86724085ec07b774f85e4b7dea46
Language: JavaScript
Category: feature-request
Title: Add comparisons and conditional selection to the formula engine
---
# Add comparisons and conditional selection to the formula engine

Add comparison operators and conditional selection to the formula language, carried through the parser, the closure and generated JavaScript evaluators, the WGSL generator, the symbolic derivative and the range estimator.

The parser accepts the binary operators `<`, `<=`, `>`, `>=`, `==` and `!=`. They bind looser than every arithmetic operator, so `a < b + 1` compares a with b + 1, and they do not chain: `a < b < c` is a parse error. A comparison evaluates to 1 when it holds and 0 otherwise. The ternary function `if(condition, whenTrue, whenFalse)` evaluates to whenTrue when the condition is nonzero and to whenFalse when it is zero; `and`, `or` (binary) and `not` (unary) combine truth values the same way (nonzero is true, results are 1 or 0). These four names are reserved (so not valid parameter names) and take exactly their arity. They may appear anywhere an expression may. A statement is still an assignment only at a lone top-level `=`: the `=` inside `==`, `<=`, `>=` and `!=` never starts one, so `flag = x <= 1; if(flag, 10, 20)` assigns flag and selects 10 at x = 1.

A comparison or logical function with an invalid operand is invalid, an `if` with an invalid condition is invalid, and the branch that is not selected never makes the result invalid, so `if(x != 0, 1 / x, 7)` is 7 at x = 0. The closure evaluator, the generated JavaScript and the WGSL agree; in WGSL, comparisons, the logical functions and `if` use the plain f32 lowering when the range analysis proves the node can never be invalid and the wrapped lowering otherwise.

The derivative of a comparison, `and`, `or` or `not` is 0, and the derivative of `if` is the derivative of the selected branch, except on the switching set, where it is invalid: a comparison switches where its two sides are equal, `and`, `or` and `not` switch where any comparison inside them switches, and any other condition switches where it is zero.

The range estimator reports comparison and logical results as subsets of {0, 1}. For `if`, the result is the union of the ranges of the branches the condition can still select; a branch that cannot be selected contributes neither values nor invalidity. When the condition is a comparison with a bare parameter on either side, that parameter's range is restricted inside each branch to the values that can select it, with strict comparisons excluding the bound itself and `!=` restricting nothing; the restriction composes through `not` and through the branch that `and` (when it holds) or `or` (when it fails) pins down, and it applies again to conditionals nested inside a branch. A branch whose restriction leaves a parameter no values at all cannot be selected. Labels, substitution, number extraction and DAG combination keep working unchanged for the new nodes.
