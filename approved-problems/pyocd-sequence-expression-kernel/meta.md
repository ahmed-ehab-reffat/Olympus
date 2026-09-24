---
Repository: https://github.com/pyocd/pyOCD
Issue: N/A
Commit: d1974ffdd16369148ba678478fa85886282d09b1
Language: Python
Category: feature-request
Title: Add a single evaluation model to the debug sequence expression engine
---

# Add a single evaluation model to the debug sequence expression engine

Add one evaluation model to the debug sequence expression engine, covering its values, its evaluation order and the calls it makes into the sequence function delegate, so that writing an operand as an integer literal never changes what an expression is worth or which calls it makes.

Every value in a sequence expression is an unsigned 64 bit integer: an integer literal, a variable, an intermediate result, the value a sequence function returns, and the value an assignment is worth, which is what the variable ends up holding. Addition, subtraction, multiplication and the shifts wrap to that width, comparisons and division treat their operands as unsigned, and a shift by 64 or more places produces zero. Division and remainder by zero produce zero. A variable set to a negative value reads back as its unsigned form, and a sequence function receives the unsigned form of every value it is passed. Write8, Write16, Write32 and Write64 reduce the word they write to that many bits, and WriteAP, WriteAccessAP and WriteDP reduce it to 32 bits. DAP_SWJ_Sequence reduces the bits it sends to the count it is given. DAP_JTAG_Sequence reduces both the bits it sends and the bits it reports to that count; a probe can report them as bytes, least significant first, so the bytes 0x34 0x12 are the value 0x1234. At a count of 64 or more, the whole value is kept.

Only an integer is a value. A string, or a call to a sequence function that returns nothing or a string, cannot be an operand, an argument to a parameter that takes an integer, or a branch of a conditional expression, and that is reported before any of the code runs. A parameter that takes a string, such as the format of Message, still takes one. Calling a function that returns nothing as a statement of its own stays valid. A conditional or loop predicate is true when its last statement produces a non-zero value, and a last statement that produces no value, such as a declaration or a call to a function that returns nothing, makes it false.

The `&&` operator evaluates its right operand only when the left one is non-zero, and `||` only when the left one is zero. A conditional expression evaluates only the branch it selects. Every other operator evaluates both operands, the left one first, a call evaluates its arguments left to right, and a compound assignment reads its variable before it evaluates the right hand side. `&&` and `||` produce 1 or 0, never the value of an operand.

Treat each side of an operator as a full subexpression. Calls and assignments are observable: evaluate the required operands in the specified order, preserving which delegate functions are called and how often. Pure value-only subexpressions may still be simplified.

Re-evaluating the predicate of a conditional or a loop repeats the calls that evaluation makes.
