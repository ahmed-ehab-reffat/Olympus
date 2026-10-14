---
Repository: https://github.com/robertmuth/Cwerg
Issue: N/A
Commit: 3bc94f7c1c26834f98c614aef51b5aa7370615d9
Language: Python
Category: feature-request
Title: Add symbolic address constants to the Cwerg front end
---

# Add symbolic address constants to the Cwerg front end

I would like to add support for constant addresses of global objects and of their subobjects, including modifiable subobjects.

It should allow references to fields and array elements in constant expressions (e.g., `@g.f`, `@g[i]`, where `i` is any constant expression), addresses of values that can be retrieved by dereferencing these references, and start addresses (`front`) of vectors and constant spans; it should allow adding a constant offset to each of these addresses with `ptr_inc`. It should allow immutable global variables whose values are addresses; these addresses can initialize global pointers and spans and record and array literal fields and elements. A global variable with an explicitly declared type can be initialized to the address of itself or another global variable whose value is the address of the first one. Possible applications include linked-record loops.

A span created by `make_span` or from a vector or vector field of a global shares storage with the global. A span stored in a global is a constant span.

Two global pointers are equal if and only if they point to the same global and the same location in that global. Values computed with `^`, or by indexing a constant span of an immutable global, can be used in `static_assert` and to initialize other globals, including complete records and vectors and spans. You can write `global copy = p^`.

You can assume that all vec literals are complete and that there are no vecs with spans or complete copies of records containing spans. Programs using these addresses should compile and run correctly, with identical output, using the Python and C++ front ends for x64, a64, and a32 targets.
