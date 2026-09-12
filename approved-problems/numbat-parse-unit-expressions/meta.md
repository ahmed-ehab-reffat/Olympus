---
Repository: https://github.com/sharkdp/numbat
Issue: N/A
Commit: 88b2e81a35d06942101d74e9b368081f02555f4f
Language: Rust
Category: feature-request
Title: Add unit expressions to the parse builtin
---
# Add unit expressions to the parse builtin

Add support for whole unit expressions to the `parse` builtin, so a quantity read from a string may carry a product, a quotient or a power.

A unit expression is built from unit names, multiplication, division, parentheses and powers. Writing two unit names next to each other multiplies them, but the language reads a parenthesised group written directly after a number as a call rather than a product, so that is not a quantity literal. An exponent is an integer or a ratio of integers and may be negative; anything else is rejected. A ratio is written in parentheses, because a bare slash after the exponent divides the quantity instead, and a minus sign may sit on either side of those parentheses. Both builtins accept the same exponent forms. A prefix belongs to the name it is written on, and a power applies to that prefixed unit. Long, short and binary prefixes all work wherever a unit name does.

A quantity literal carries exactly one number and it comes first, though the sign in front of it may be repeated. A second number anywhere, including inside a denominator, is rejected. The number may be followed directly by a division. Temperatures written with a degree sign are accepted, including after a minus sign.

For both builtins the units written need not match the annotation, only the dimension they denote. A zero keeps the exemption it has today and satisfies any annotation. Surrounding whitespace is ignored. Inputs that are not quantity literals stay rejected, including any that combine or compute quantities, and empty or blank strings.

Also add a `value_in` builtin that goes the other way: given a quantity and a target written in the same grammar and carrying no number, it returns the plain number that quantity comes to in that unit. The target may also be an offset temperature scale, written with a degree sign or with the name the language already uses for it, in which case the offset applies, so absolute zero is not zero on that scale. A target whose dimension differs from the quantity is rejected.

Add a companion `unit_from` builtin that reads a unit expression on its own and returns that unit with a value of one, for callers who want the unit without a magnitude. It accepts exactly the unit expressions a quantity literal may carry, written without the number, and rejects any input carrying one. Degree-sign temperature syntax is not a unit expression, so it is not taken on its own. A leading division is one of those forms, so a reciprocal unit may be written on its own, and divisions may be chained. It needs a concrete annotation to know which dimension to produce, and fails without one. It is the inverse of `unit_name`: whatever `unit_name` prints for a unit reads back as that same unit.
