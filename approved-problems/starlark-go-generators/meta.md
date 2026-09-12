---
Repository: https://github.com/google/starlark-go
Language: Go
Issue: N/A
Commit: 5395d018f003e2a08bfbca6dcb2562acee700f62
Title: Add generator functions to the Starlark interpreter
---

# Add generator functions to the Starlark interpreter

Extend the dialect with generator functions, enabled per file by a new `Generators` field on `syntax.FileOptions`. Without it, both the statement and the expression form below are rejected before execution.

A `yield` statement suspends the enclosing function and produces a value; with no operand it produces `None`. A function whose own body contains a `yield` is a generator function. A `yield` outside any function is a static error, and so is a `return` that carries a value inside a generator function, though a bare `return` ends one. A `yield from` statement produces every element of an iterable in turn.

Calling a generator function runs no part of its body. It returns a value whose `type()` is `generator`, which prints as `<generator NAME>`, is always true, and is not hashable. Iterating it runs the body up to the next `yield`. A generator is consumed as it is iterated and never restarts: a loop that stops early leaves the body suspended, and a later iteration continues from there. Each call of a generator function is an independent activation, so two of them advance separately. Iterating a generator that is already running is an error, as is advancing one that has been frozen.

`(EXPR for x in seq if cond)` is a generator expression, and the value it makes is a generator like any other, printed in the same form under a name of the implementation's choosing. It produces the elements the matching list comprehension would, but the body runs only as the generator is advanced, and names from the enclosing function are visible to it. The sequence of its first clause is evaluated where the expression appears rather than on the first advance.

`next(g)` advances a generator by one element and fails once it is exhausted, while `next(g, default)` returns the default instead. `g.close()` abandons a generator, which then produces nothing further and runs no more of its body; closing one that has already finished does nothing. Closing a generator also closes the one it is delegating to, while closing a delegate leaves the generator that was delegating to it alive: its `yield from` finds nothing left and the rest of the body still runs.

A suspended generator holds whatever it is iterating, so a list or dict being walked inside the body stays locked against mutation until the body ends, by returning or by failing, or the generator is closed. An error raised while a body runs reaches whatever is consuming the generator and ends that generator, which afterwards behaves like one whose body has finished.
