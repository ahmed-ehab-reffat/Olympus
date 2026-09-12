---
Repository: https://github.com/gluon-lang/gluon
Issue: https://github.com/gluon-lang/gluon/issues/9
Commit: 418c6b7de22b244746bfd0570f9fcfd6d738e542
Language: Rust
Title: Add guards, or-patterns, and exhaustiveness checking to match
---
# Add guards, or-patterns, and exhaustiveness checking to match

A gluon match alternative can only test the shape of a value. There is no way to attach a boolean condition to an alternative, no way to share one body between several patterns, and a match that omits a constructor fails at run time instead of being rejected while type checking. Extend pattern matching with three related capabilities.

A match alternative may carry a guard, written `| pattern if condition -> body`. The guard is an expression of type `Bool` evaluated only after `pattern` matches the scrutinee. It may read variables bound by that pattern, including bindings from nested patterns and from `@` patterns, as well as variables already in scope around the match. When the guard is `True` the body is taken. When it is `False`, matching continues at the following alternatives exactly as if `pattern` had not matched, so a later alternative whose pattern also matches the scrutinee is still tried. Alternatives are attempted from top to bottom, and several alternatives may share one pattern with different guards. An alternative written without `if` is unconditional. If every alternative whose pattern matches has a guard that fails, and nothing else matches, the match fails at run time as before.

A pattern may be an or-pattern, written as `(p1 | p2)` in parentheses, matching when any branch matches, and it may appear nested inside another pattern. The branches of an or-pattern may not bind variables; a branch that does is a type error.

A match on a variant type is checked for completeness. If some constructor of the matched type is handled by no unguarded alternative, and no alternative matches every remaining value, the match is rejected as non-exhaustive and the missing constructors are reported. A guarded alternative does not count toward completeness, since its guard may fail. An alternative that can never be reached, because an earlier unguarded alternative already matches every value it could match, is rejected as unreachable.
