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

`bzero` takes an address and a length and writes that many zero bytes. `bcopy` takes a destination address, a source address and a length and copies that many bytes. A length of zero or more works upward from the given addresses, and a zero length writes nothing. A negative length works downward: the byte just below the given addresses is handled first, then the one below that, until the magnitude of the length is exhausted. The sign is read from the value, whether it is a constant or held in a register of any integer kind the target supports, and a length in an unsigned register is never negative. The length is read at the register's own width, so a value that has wrapped at that width is used as it stands, and that stays true when the program is optimized first. The result is exactly what reading and writing one byte at a time in that order produces, so overlapping source and destination ranges end up as that order dictates. Both instructions work wherever they appear in a function and however many times.

The Python and the C++ backends must emit identical assembly text. The repository's own tests are run with `make tests` from the repo root.
