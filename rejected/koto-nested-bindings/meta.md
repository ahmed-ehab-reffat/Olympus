---
Repository: https://github.com/koto-lang/koto
Issue: N/A
Commit: c579dcd02f015e0855d9495d10c7a4479fb82b0c
Language: Rust
Category: feature-request
Title: Add nested and rest patterns to every binding site in Koto
---

# Add nested and rest patterns to every binding site in Koto

Add nested tuple patterns and rest captures to every place Koto binds a value: plain assignment, `let`, `for` arguments and `catch` arguments. Today only function arguments and `match` arms accept shapes like `(a, (b, c), rest...)`; an assignment such as `(a, b), c = x` or `a, rest... = x` is a syntax error, and so is `for (a, b), c in x`.

A binding pattern is an identifier, an ignored name, a map pattern, or a parenthesised tuple of patterns, where any identifier or map pattern may carry a type hint wherever hints are accepted today (`let`, `for` and `catch`) and a tuple may contain one rest written `name...` or `...`. A single parenthesised tuple as the whole target means the same as the unparenthesised list. Unpacking works by iteration at every level: a tuple pattern takes the values of its value one at a time, a missing value binds null and extra values are ignored. A rest captures into a tuple the values its siblings do not take: at the end, everything that remains; at the start or in the middle, everything except what the siblings after it need, those siblings then taking the last values in order and binding null when too few remain. A rest works on any iterable value, including a generator or an iterator whose length is unknown, and never requires the value to be indexable. A second rest in the same tuple is a compile error, as is a rest outside a binding pattern. Type hints on nested identifiers are checked as the identifier is bound. An exported assignment, and a top-level `for` when top-level identifiers are exported, exports every identifier bound anywhere in its targets. A `catch` with a tuple pattern must be the last catch block, like an untyped one.

Function arguments and `match` arms are unchanged, including their rule that a rest may only open or close a tuple pattern; every existing flat form, packed call argument and `koto_format` output keeps its behaviour.
