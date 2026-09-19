---
Repository: https://github.com/robertmuth/Cwerg
Issue: https://github.com/robertmuth/Cwerg/issues/3
Commit: 3bc94f7c1c26834f98c614aef51b5aa7370615d9
Language: C++
Category: feature-request
Title: Add memory passing for overflowing parameters to Cwerg backends
---
# Add memory passing for overflowing parameters to Cwerg backends

Add support for functions with more parameters than the target has argument registers to the Cwerg backends for a32, a64 and x64. Currently, calls fail once an argument-register class is exhausted.

A function may take up to the IR's limit of parameters, in any mix of integer, address, code and floating point kinds, and may be called directly or through a function pointer. Parameters that do not fit in registers are passed through memory. Every parameter must arrive in the callee with the value the caller pushed, wherever such calls appear and however many times, including in recursive functions, inside loops and in functions that themselves received parameters through memory.

The Python and the C++ code generators must emit identical assembly text. The repository's own tests are run with `make tests` from the repo root; in this environment it stops at BE/ApiDemo, which needs ARM cross compilers, and the C++ frontend build after that needs GCC 13.
