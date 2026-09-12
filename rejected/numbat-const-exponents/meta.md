---
Repository: https://github.com/sharkdp/numbat
Issue: N/A
Commit: 88b2e81a35d06942101d74e9b368081f02555f4f
Language: Rust
Category: feature-request
Title: Evaluate dimension exponents as compile-time constants
---
# Evaluate dimension exponents as compile-time constants

Allow a dimension exponent to be any expression that can be worked out at check time, rather than
only a literal. Today an exponent has to be written as a number, a negated number, or a ratio in
parentheses, so a type like `Length^(1+1)` is refused before checking even begins, and a name never
works at all.

An exponent may now be built from integers, a name bound to a constant, unary minus, parentheses,
and addition, subtraction, multiplication and division between them. Arithmetic that is not written
inside parentheses still ends the exponent, so a quotient of two dimensions keeps reading the way it
does today. The same forms are accepted wherever an exponent may appear, which includes dimension
declarations, unit definitions, variable annotations and function signatures, and equally in an
ordinary expression such as `2 m^n`.

A name resolves to the value it is bound to at the point the annotation is written, so a later
rebinding of that name does not reach back and change an earlier type. Names that are not bound to a
compile-time constant are refused, as are names used before they are bound, and a dimensionful
quantity is not a constant for this purpose.

Exponents remain exact rationals. Two types are the same dimension when their exponents work out to
the same rational, so an exponent written as `1+1`, as a name bound to two, or as the literal two all
denote the one dimension and values may pass between them.

Every program that is accepted today keeps its current meaning, and an exponent that is written
entirely from literals keeps reporting the same problems it reports today, at the same point, with
the same message: a division by zero inside an exponent, and an exponent too large to represent, are
both still refused. When a name is involved the same two problems are still refused, since they
cannot be seen until the name is known.
