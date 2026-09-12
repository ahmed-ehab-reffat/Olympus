---
Title: Add Python format specifiers to str.format and percent interpolation
Repository: https://github.com/google/starlark-go
Language: Go
Issue: N/A
Commit: 8ba36ccb83fb02b223182e27808a6d5d0636afb9
---

# Add Python format specifiers to str.format and percent interpolation

Add a Python-style format-specifier mini-language to `str.format` and `%` interpolation. In `str.format` a replacement field may now carry a format specifier after `:`, an attribute (`{0.x}`) or element (`{0[k]}`) accessor in its name, and nested replacement fields inside its specifier; a `!s` or `!r` conversion applies before the specifier formats the result.

A specifier may give, in order, an optional fill character with an alignment, a sign, the alternate form, zero padding, a width, a grouping option, a precision, and a type. The alignments `<`, `>`, `^`, and sign-aware `=` pad with the fill to the width; numbers default to right, strings to left. A leading `0` is sign-aware zero padding (fill `0`, align `=`) that places zeros between the sign and the digits unless an explicit alignment overrides it. A `+` or a space prefixes a non-negative number with a sign or a space, and `#` adds the `0b`/`0o`/`0x` base prefix. `,` groups decimal digits by three; `_` groups decimal and float digits by three and binary, octal, and hexadecimal digits by four; separators count toward a zero-padded width.

Integer types are `b`, `o`, `d`, `x`, `X`, `c` (a codepoint), and `n`; float types are `e`, `E`, `f`, `g`, `G`, `%`, and `n`; strings take `s`. Float `f` defaults to precision six and `g` to six significant digits; an empty type renders a float as `str` does, and with a precision uses the general format `g`. Integers reject a precision, while a string precision truncates to that many code points before padding. An integer may be rendered with a float type, formatting as a float. Under a non-empty specifier a `bool` formats as its integer value 1 or 0. `n` is locale-independent. A type outside a value's family, and a sign, `#`, or grouping applied to a string, are errors, as are other invalid option combinations. A field name and the nested fields of its specifier share one automatic-or-manual numbering scheme and consume positional arguments left to right.

Add the `-`, `+`, space, `#`, and `0` flags, a width, and a precision to the `%` interpolation operator's conversions: `-` left-aligns, `+` and a space control the sign, `#` selects the alternate form, and `0` zero-pads. For an integer conversion a precision sets the minimum number of digits; string conversions default to right alignment and ignore the `0` flag, as does the `c` conversion.
