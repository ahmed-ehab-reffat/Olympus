---
Repository: https://github.com/pysmt/pysmt
Language: Python
Issue: Translate bit-vector formulae into Boolean formulae
Commit: 9342f1829ab7c1f846e00dca57e20603a38550e0
Title: Translate bit-vector formulae into Boolean formulae
---

# Translate bit-vector formulae into Boolean formulae

pySMT builds, type checks and simplifies bit-vector formulae, but it cannot hand one to a purely Boolean back end. Add that translation as a new `pysmt.bitblast` module holding a `BitBlaster` class, together with a `bit_blast(formula, environment=None)` function in `pysmt.rewritings`.

`BitBlaster(environment=None).convert(formula)` takes a Boolean formula and returns a Boolean formula equivalent to it, not merely equisatisfiable. Every bit-vector symbol stands for one fresh Boolean symbol per bit, so the result holds nothing beyond the bits of the symbols that occur and the Boolean symbols that already occurred. Nor is it simplified afterwards: a bit the encoding uses stays even where the truth of the formula does not depend on it, though folding an operator whose arguments are constant can leave a bit out.

`bit_symbols(symbol)` returns those bits, least significant first, in an indexable sequence, creating them the first time it is asked. It answers for symbols alone: a symbol of a type that carries no bits raises `ConvertExpressionError`, and so does anything that is not a symbol, including bit-vector terms. Bits never change for a given blaster, so two formulae it converted may be conjoined, while two blasters give the same symbol disjoint bits. They are fresh: whatever they are called, they never coincide with an existing symbol.

`cnf(formula)` converts the formula and hands back the result as clauses for a SAT back end: a list of clauses, each a list of literals, where a literal is a Boolean symbol or its negation and nothing else. The clauses are satisfiable exactly when the formula is, which is weaker than what `convert` gives, because `cnf` may introduce helper symbols of its own; those are fresh in the same way the bits are, and a later call makes its own rather than reusing them.

No reading is lost or invented along the way: fix the bits and the other symbols of the formula to values that make it hold and the helpers can always still satisfy every clause, fix them to values that do not and no choice of helpers can. A formula that converts to the constant true needs no clauses at all, and one that converts to the constant false gives a single empty clause. The bits are the ones `bit_symbols` already gives, so a satisfying assignment reads back through `reconstruct` and `model`, and neither of those reports a helper.

`reconstruct(assignment)` turns a mapping from Boolean symbols to values into a dictionary from every symbol the blaster has given bits to so far to that symbol's constant value, reading the bits least significant first, counting a bit the assignment does not mention as false, and accepting either pySMT Boolean constants or Python booleans as values. `model(assignment)` returns that same information as an `EagerModel`. The bits it read are not in it, the symbols they stand for are there instead; every other symbol of the assignment stays as it was given, so the model can evaluate the formula that was converted.

Boolean connectives, Boolean constants and symbols, and equalities and if-then-elses over any supported type are supported, and so are the library's bit-vector operators: arithmetic, bitwise, comparison, shift, rotation, extension, concatenation, extraction, repetition and the one-bit comparison.

So are arrays indexed by a bit-vector whose elements are bit-vectors or arrays of the same kind. Such an array stands for one group of bits per index value, a group being the bits of a bit-vector element or the groups of a nested one, and `bit_symbols` returns them in that shape, ordered by index at every level.

A selection picks out the addressed group, a store rewrites that group alone, an array written as a constant stands for the groups its default and assigned indices give, and two arrays are equal when all their elements are. `reconstruct` gives an array symbol the array whose default is the zero of its element type, itself an array of zeros when nested, and which assigns every index holding something else.

A quantifier binding Boolean or bit-vector symbols becomes the instances of its body over their values, so a bound symbol is gone before any bit is made and never gets bits of its own; binding anything else, an array included, is an error.

Everything else raises `ConvertExpressionError`: a term of any other type, an application of an uninterpreted function whatever type it returns, and a `convert` whose argument is not Boolean.

Each operator keeps the bit-level meaning the library already gives it: unsigned division by zero gives all ones and unsigned remainder by zero the dividend; signed division truncates towards zero and signed remainder takes the sign of the dividend, the zero divisor included; a left or logical right shift by at least the width gives zero while an arithmetic one repeats the sign bit; a rotation by the width leaves the vector unchanged; and `BVComp` yields a vector one bit wide.
