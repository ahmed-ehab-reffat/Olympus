---
Repository: https://github.com/gluon-lang/gluon
Issue: N/A
Commit: 418c6b7de22b244746bfd0570f9fcfd6d738e542
Language: Rust
Category: feature-request
Title: Add comment preservation to the source formatter
---
# Add comment preservation to the source formatter

Add comment preservation to the formatter, so that running it over a file keeps every comment the author wrote, attached to the code they attached it to.

A comment that begins on the same line as the code before it belongs to that code and stays on its line, one space after it. Both comment forms behave this way. A line comment runs to the end of the line it sits on, so a construct holding one is written out in its multiple line form rather than being collapsed onto one line. A comment that begins a line of its own belongs to whatever follows it, indented to the same column as the item it precedes, including when what follows is the first item of a construct. A comment sitting after the last item of a record, with only the closing brace left, belongs inside that construct and keeps the indentation the items have. An own line comment after the final alternative of a match belongs to whatever follows the match. A record whose only content is a comment keeps it inside as well, indented one level in from the line the record opens on.

These rules hold the same way for a record literal, the alternatives of a match, and successive let bindings, including where one of those is nested inside another. Within those constructs every comment appears in the output exactly once, and a blank line the author left between two comments is kept, with a run of several blank lines becoming one.

Documentation comments, the ones written with three slashes, belong to the binding or field they are attached to. Each one appears in the output once, carried by that binding or field, and never a second time as a comment in its own right.
