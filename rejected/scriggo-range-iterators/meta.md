---
Repository: https://github.com/open2b/scriggo
Issue: N/A
Commit: 2f437fb8222e48af03cf4087794b05a23316b07a
Language: Go
Title: Support range over integers
---
# Support range over integers

Scriggo's `for range` rejects ranging over an integer value with a "cannot range over" error. Go accepts this form and Scriggo should support it too, in both programs and templates.

Ranging over an integer `n` iterates the values 0, 1, up to n-1 in order. With no range variable the body runs `n` times; with a single range variable it binds each successive value in turn. A second range variable is not allowed. A non-positive `n` runs the body zero times, in which case a template `for` runs its `else` branch. Any integer-kinded value is accepted, an untyped constant is treated as an `int`, and the range variable has the same type as the value ranged over. The value is evaluated once, before iteration begins.

`break` and `continue` behave as they do for the existing range forms. When the range assigns to an existing variable rather than declaring a new one, that variable retains its last iterated value after the loop.
