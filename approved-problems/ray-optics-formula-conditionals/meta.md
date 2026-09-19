---
Repository: https://github.com/ricktu288/ray-optics
Issue: N/A
Commit: e55947ecf4cc86724085ec07b774f85e4b7dea46
Language: JavaScript
Category: feature-request
Title: Add comparisons and conditional selection to the formula engine
---
# Add comparisons and conditional selection to the formula engine

Add comparison operators and conditional selection to the formula language.

The parser accepts the binary operators `<`, `<=`, `>`, `>=`, `==` and `!=`. They bind looser than every arithmetic operator, and they do not chain: `a < b < c` is a parse error. A comparison evaluates to 1 when it holds and 0 otherwise. The ternary function `if(condition, whenTrue, whenFalse)` evaluates to whenTrue when the condition is nonzero and to whenFalse when it is zero; `and`, `or` (binary) and `not` (unary) combine truth values the same way (nonzero is true, results are 1 or 0). These four names are reserved (so not valid parameter names) and take exactly their arity. They may appear anywhere an expression may. Only a lone top-level `=` starts an assignment; the `=` inside `==`, `<=`, `>=` and `!=` never does.

A comparison or logical function with an invalid operand is invalid, an `if` with an invalid condition is invalid, and the branch that is not selected never makes the result invalid. The closure evaluator, the generated JavaScript and the WGSL agree while every value involved is exactly representable as a 32-bit float; in WGSL, comparisons, the logical functions and `if` use the plain f32 lowering when the range analysis proves the node can never be invalid and the wrapped lowering otherwise.

Comparisons, `and`, `or` and `not` have derivative 0 everywhere, including where their value jumps. The derivative of `if` is the derivative of the selected branch, except on the switching set of its condition, where it is invalid. Only the condition's top-level form counts: a comparison switches where its two sides are equal, `and`, `or` and `not` switch wherever an operand, read as a condition, switches, and any other condition switches where it is zero.

The range estimator reports comparison and logical results as subsets of {0, 1}. When an operand can be invalid, the result only has to be marked as possibly invalid, and it may keep the truth values the other operands allow. For `if`, the result is the union of the ranges of the branches the condition can still select; a branch that cannot be selected contributes neither values nor invalidity. When the condition is a comparison with a bare parameter on either side, that parameter's range is restricted inside each branch to the values that can select it. Strict comparisons exclude the bound itself, and `!=` restricts nothing. `not` passes restrictions on with the truth flipped. `and` passes them into the branch where it holds and `or` into the branch where it fails, applying its operands left to right, each under the restrictions of the ones before it. Restrictions apply again to conditionals nested inside a branch. A branch counts as unselectable when the condition's estimated range cannot select it or its restriction leaves a parameter no values; other unreachable branches may still be included. Labels, substitution, number extraction and DAG combination keep working unchanged for the new nodes.
