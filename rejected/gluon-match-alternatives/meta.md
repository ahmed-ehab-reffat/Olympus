---
Repository: https://github.com/gluon-lang/gluon
Issue: N/A
Commit: 418c6b7de22b244746bfd0570f9fcfd6d738e542
Language: Rust
Category: feature-request
Title: Add guards and binding or-patterns to match alternatives
---
# Add guards and binding or-patterns to match alternatives

Add guards and or-patterns to match alternatives, so an alternative can carry a boolean condition and one alternative can accept several shapes of value. Today an alternative can only test the shape of the scrutinee, there is no way to attach a condition to it, and there is no way to share one body between several patterns.

An alternative may carry a guard, written `| pattern if condition -> body`. The guard is an expression of type `Bool` evaluated only after `pattern` matches the scrutinee. It may read variables bound by that pattern, including bindings from nested patterns and from `@` patterns, as well as variables already in scope around the match. When the guard is `True` the body is taken. When it is `False`, matching continues at the following alternatives exactly as if `pattern` had not matched, so a later alternative whose pattern also matches the scrutinee is still tried. Alternatives are attempted from top to bottom, and several alternatives may share one pattern with different guards. An alternative written without `if` is unconditional. If every alternative whose pattern matches has a guard that fails, and nothing else matches, the match fails at run time as before.

A pattern may be an or-pattern, written as `(p1 | p2)` in parentheses with any number of branches. It matches when any branch matches, branches are tried left to right, and it may appear anywhere a pattern is expected, including nested inside another pattern and inside another or-pattern.

The branches of an or-pattern may bind variables. Every branch must bind exactly the same set of variable names, and each name must have the same type in every branch. A branch binding a name the other branches do not, or binding one at a type the others do not, is a type error that names the variable. Those names are in scope in the alternative's guard and in its body, and they hold the values bound by whichever branch actually matched, whatever position that branch occupies. An `@` pattern may name an or-pattern, and the name then refers to the whole matched value.
