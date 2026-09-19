---
Repository: https://github.com/hlorenzi/customasm
Issue: N/A
Commit: a45db8ff315ef29eca4fe766d5082408bb6d9903
Language: Rust
Category: feature-request
Title: Add exact fractional values and precision-on-demand decomposition
---

# Add exact fractional values and precision-on-demand decomposition

Add fractional numbers to the expression evaluator, so a source file can describe a value between two integers and take it apart into whatever bit layout its target needs.

A number literal may carry a decimal point with at least one digit on either side of it, and underscores may separate digits on both sides. A literal written in a base other than ten may not carry a point. Such a literal is a fractional value, and it is held exactly: nothing about it is rounded or approximated when it is read.

Four built-in functions act on one. `$whole` gives the integer part, truncated toward zero, and `$fract` gives what is left, carrying the sign of the original. `$exponent` and `$mantissa` each take a value and a number of bits, and describe the value once its significand has been rounded to that many bits.

They describe it like this. For a non-zero value, choose `e` such that `2^e <= |value| < 2^(e + 1)`, and write `|value| = 2^e * (1 + remainder)` with `0 <= remainder < 1`. That remainder is rounded to the requested number of bits, to the nearest value representable in them, and a remainder sitting exactly between two of them rounds to the one whose last bit is zero. `$mantissa` reports the rounded remainder and `$exponent` reports `e`. Should the rounding carry the significand up to two, the reported mantissa is zero and the reported exponent is one greater, so the two always describe the same rounded number and the mantissa always fits the requested bits. Both describe the magnitude, ignoring the sign. At zero both report zero.

`$mantissa` produces a value of exactly the requested width, so it can be emitted or concatenated as it stands; `$whole` and `$exponent` produce values with no width of their own. A fractional value has no width either, so emitting one directly is an error. A fractional value can be compared with `==` and `!=` against another fractional value or an integer, and the two are equal exactly when they are the same number. Anywhere a fractional value is accepted, an integer is too.

Addition, subtraction, multiplication and division take fractional values as well, including with an integer on one side, and every result is exact, so a quotient with no finite decimal form loses nothing along the way. Such a result is itself a fractional value with no width. Division between two integers keeps truncating as it does now, and dividing by zero stays an error. Every other operator goes on working with integers alone and turns a fractional operand away.
