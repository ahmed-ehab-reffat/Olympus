---
Repository: https://github.com/robertmuth/Cwerg
Issue: https://github.com/robertmuth/Cwerg/issues/45
Commit: 3bc94f7c1c26834f98c614aef51b5aa7370615d9
Language: C++
Category: feature-request
Title: Add bcopy and bzero lowering to the Cwerg backends
---
# Add bcopy and bzero lowering to the Cwerg backends

Add support for the `bzero` and `bcopy` IR instructions to the Cwerg backends for a32, a64 and x64, and to the C backend.

`bzero` takes an address and a length and writes that many zero bytes. `bcopy` takes a destination address, a source address and a length and copies that many bytes. For a non-negative length, process bytes at increasing addresses, and a zero length performs no writes. For a negative length, begin one byte below each address and process decreasing addresses until the magnitude of the length is exhausted. Interpret the length according to its integer kind and native width, whether it is a constant or a register value of any integer kind the target supports. Unsigned lengths are never negative, and a value that has wrapped at its own width is used as it stands, which stays true when the program is optimized first. That includes lengths computed by arithmetic in the code the C backend generates. The result is exactly what reading and writing one byte at a time in that order produces, so overlapping source and destination ranges end up as that order dictates. Both instructions work wherever they appear in a function and however many times.

The Python and the C++ code generators must emit identical assembly text, and the Python and the C++ optimizers must emit identical optimized IR text. The repository's own tests are run with `make tests` from the repo root; in this environment it stops at BE/ApiDemo, which needs ARM cross compilers, and the C++ frontend build after that needs GCC 13.
