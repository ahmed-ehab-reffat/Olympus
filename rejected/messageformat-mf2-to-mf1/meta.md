---
Repository: https://github.com/messageformat/messageformat
Issue: N/A
Commit: 0ffba11d49b1aa4579497ccec7fb9ec3c082e709
Language: TypeScript
Category: feature-request
Title: Add MessageFormat 2 to ICU MessageFormat 1 conversion
---

# Add MessageFormat 2 to ICU MessageFormat 1 conversion

Add a function `messageToMF1(locale, msg)` to `@messageformat/icu-messageformat-1` that takes a locale string and a MessageFormat 2 data model message and returns ICU MessageFormat 1 source for that locale. The package only converts in the other direction today.

Compiling the result with `mf1ToMessage(locale, source)` must give a formatter that formats exactly like `new MessageFormat(locale, msg, { functions: MF1Functions })`, with `bidiIsolation: 'none'` on both, whenever each variable holds a non-negative integer or a string, as its functions expect. That includes select messages whose variants do not cover every combination of keys. The source must also be valid for the locale: each `plural` and `selectordinal` statement has an `other` case and uses only the plural categories the locale has for that kind of statement.

Selectors can be `:string`, `:number` or `:integer` with no option other than `select`, or `:mf1:plural` with an `offset`. A placeholder can be a literal or a variable, either bare or with `:string`, `:number` or `:integer` and no options, or any expression with an `mf1:argType` attribute, which is written back with its `mf1:argStyle` attribute. Declarations are followed to the expression they bind. Anything else throws an error, including markup, a `:string` key `other`, and any key or variable name that MF1 cannot write.

Two existing bugs break this round trip and must be fixed as well. `mf1ToMessage` must select like MF1 when statements nested under a statement for a different argument list different cases in different branches, where each nested statement chooses among its own cases only. And `MessageFormat` never finishes formatting some messages with three or more selectors; it must select the variant that the MessageFormat 2 specification selects.
