# Add arithmetic operators to the Guard rules language

The Guard rules language lets authors bind values with `let` and compare them, but it cannot do arithmetic: an author who wants to check a ratio, a sum, or a scaled threshold has no way to express it. Add support for the binary arithmetic operators `+`, `-`, `*`, and `/` so that arithmetic expressions can appear anywhere a `let` assignment value or a comparison right-hand-side is accepted.

An arithmetic expression combines operands with the four operators. Multiplication and division bind more tightly than addition and subtraction, all four are left associative, and parentheses override the default grouping. Each operand is a numeric literal, a variable or property reference that resolves to a value, a function call, or a parenthesized sub-expression. Arithmetic binds more tightly than the comparison operators, so a right-hand-side such as `count(...) + 1` is evaluated before the comparison is applied.

Addition, subtraction, and multiplication of two integers produce an integer. Division produces an integer when the numerator divides evenly and a floating point number otherwise. If either operand is a floating point number the result is floating point. Division where the divisor is zero is an evaluation error rather than a result.

An operand that is a reference or function call is resolved the same way it would be anywhere else in a rule, and it must resolve to exactly one numeric value. An operand that resolves to no values, to more than one value, or to a non-numeric value makes the surrounding arithmetic an evaluation error.

Introducing these operators must not change how any existing rule is parsed or evaluated. In particular the `*` used as a query wildcard, the `/` used to delimit regular expressions, and the `%` used to reference variables keep their current meaning, and every existing rule continues to parse and evaluate exactly as before.
