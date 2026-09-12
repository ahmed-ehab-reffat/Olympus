---
Repository: https://github.com/obi1kenobi/trustfall
Issue: N/A
Commit: 0867b17bb16bbd892dac22fe3481503f4ab7b1f0
Language: Rust
Title: Narrow query candidate values from string-prefix filters
---
# Narrow query candidate values from string-prefix filters

The optimization API lets an adapter ask what values a property may take, so it can skip
work for values that cannot satisfy the query. Today `has_prefix` filters contribute nothing:
a property filtered with `has_prefix` reports an unrestricted candidate, even though the prefix
tightly bounds the value.

Make `has_prefix` produce a candidate range for the filtered property, on both the statically
required candidate and the dynamically resolved candidate (when the prefix comes from a tag).
The candidate is the range of non-null strings that begin with the prefix: the start is the
prefix itself, included; the end is exclusive at the shortest string that is strictly greater
than every string beginning with the prefix, measured by the same ordering `FieldValue` uses for
strings; and null is never in the range. An empty prefix yields the full range of non-null
strings. A prefix that has no such greater string yields an included start with no end bound.

The prefix candidate must combine with any other value-constraining filters on the same property,
so `has_prefix "ab"` together with an equality to `"abc"` narrows to the single value `"abc"`,
and together with an equality to `"xy"` narrows to no possible value. Only `has_prefix` gains this
behavior: `not_has_prefix`, `has_suffix`, `has_substring`, `contains`, `regex`, and their
negations still contribute no candidate range.
