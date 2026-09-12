# Add ruledef-driven disassembly of assembled output

Add a `disasm` output format that prints the instructions the assembled bytes encode. Each line
starts with the offset the instruction begins at, counted in the units the output is addressed in,
in lowercase hexadecimal padded with leading zeros to at least four digits, then a colon and a
single space.

A rule can be decoded when its output is a concatenation of fixed bit patterns and whole
parameters, and every parameter its pattern declares appears there exactly once; a rule that
computes its output some other way is not available for decoding, and that on its own is not an
error. A fixed bit pattern is a literal, and it pins down bits only when its own width is known;
arithmetic still counts as computing the output even when nothing varies. A parameter is whole
when the bits it contributes are exactly the width it was declared with, and not whole otherwise.
A rule that hands its whole encoding to another ruledef without pinning down any bits of its own
cannot be told apart from what it wraps, so it is not available either.

Where more than one rule could explain the bytes at a position, the one pinned down by the most
fixed bits applies, and a genuine tie is reported instead of guessed as `ambiguous decoding at
position N`, counting N in bits. Parameters that name another ruledef are decoded the same way
from the bits of their own field and nothing past it, to whatever depth the nesting reaches, and a
tie found down there is reported against the position of the field holding it. A nested choice
only counts if the rest of the rule still fits the bits that follow it, and if a field it sits in
is exactly as wide as the field says. The bits that pin an explanation down include those
contributed by the nested explanations it settled on, so a nested choice can decide which of two
outer rules wins.

Decoded operands print as lowercase hexadecimal with an `0x` prefix, and a parameter declared as
signed prints negative values with a leading minus. The rest of the line follows the rule's own
pattern, with each run of whitespace in it written as a single space. When the bytes left at a
position match no rule, decoding stops and reports `no rule decodes the bits at position N`.
