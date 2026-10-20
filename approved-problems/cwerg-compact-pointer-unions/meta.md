---
Repository: https://github.com/robertmuth/Cwerg
Issue: N/A
Commit: 3bc94f7c1c26834f98c614aef51b5aa7370615d9
Language: Python
Category: feature-request
Title: Add one-word compact tagged unions to the Cwerg front ends
---

# Add one-word compact tagged unions to the Cwerg front ends

I would suggest that Cwerg front ends optimize pointer-like tagged unions to occupy one word of memory. A Cwerg type `union(void, ^T)`, representing an optional pointer, occupies two words of memory, although a design note suggests optimizing optional pointers for space efficiency.

A tagged union that includes only one pointer and one or more zero-sized types, namely void and wrapped types of void, which are commonly used to represent error codes, should have the same size and alignment as a pointer type in x64, a64, and a32 environments. A wrapped type with a pointer base type should be considered the same as the pointer member of such a tagged union. Other unions are unaffected.

In addition to size considerations, the behavior of a program should not depend on whether a tagged union is compressed or not. Programs compiled and run for the x64, a64, and a32 targets produce identical results using either front end. You can assume that pointers held in unions are actually object pointers and that global union variables have explicit initializers. Return values of union types from functions are assigned to variables before being converted to other union types. Unions with 64-bit members are not used on the a32 target.
