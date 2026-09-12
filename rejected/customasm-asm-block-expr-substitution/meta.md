# Evaluate brace substitutions in asm blocks as expressions

Inside an `asm` block, the braces that mark a substitution accept only a single name. Widen them
to hold an expression, so a rule can compute the operand it passes down instead of having to bind
a helper variable first.

A brace holding exactly one name that was matched from source tokens keeps substituting those
tokens, so a subruledef argument still morphs into the inner rule the way it does now. Anything
else in the braces is one ordinary expression.

The expression is evaluated where it stands. It sees the same names an instruction written in
that position would see, and it resolves them against the layout the block itself produces.
Because an instruction's size can depend on a value that a later instruction moves, the block is
evaluated repeatedly until the encoding stops changing, and reports that it did not converge when
it cannot settle.

Empty braces stay an error, and so does anything left over between the end of the expression and
the closing brace.
