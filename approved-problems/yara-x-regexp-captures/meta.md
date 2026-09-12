---
Repository: https://github.com/VirusTotal/yara-x
Language: Rust
Issue: regexp-capture-groups
Commit: be2a32547d833cb7a0f6545d421c66854f4aad70
Title: Add capture groups to regexp patterns and expose them in conditions
---

# Add capture groups to regexp patterns and expose them in conditions

A condition can ask where a pattern matched and how long the match was, but not where some part inside the match was. Make a parenthesized group in a regexp pattern a capturing group, and report the piece of the match that the group covered.

A group is written `(...)`, while `(?:...)` stays non-capturing. Groups are numbered from one, in the order in which their opening parenthesis appears, so a group nested inside another one gets the higher number, and a non-capturing group takes no number. A group may also be named, as `(?P<name>...)` or `(?<name>...)`, and a named group is numbered like any other. A name cannot be empty, cannot contain a space and cannot begin with a digit, and the same name cannot be given to two groups of one pattern.

Two new accessors report a group. `@a[i][g]` is the offset where the group number `g` matched within the `i`-th match of `$a`, and `!a[i][g]` is its length. Both are written after the match index and never on their own. The group number zero is the whole match, for every kind of pattern and not only for regexps, so `@a[i][0]` is always `@a[i]` and `!a[i][0]` is always `!a[i]`. A group can also be addressed by its name, as `@a[i]["name"]`. The group is therefore either a number or a quoted name. A group written as a negative number, one written as neither a number nor a name, and a name the pattern does not define are all errors at compile time, while a number that only turns out to be negative while scanning leaves the accessor undefined, like any other number outside the range of groups.

Above zero, both accessors are undefined when the number is larger than the number of groups in the pattern, when the pattern is not a regexp, and when the group took no part in that particular match. An alternation resolves leftmost first, the same order that decides how much a quantifier consumes, so for `/z(a)|z(b)/` over `zb` the first group is undefined while the second one is not. A group inside a repetition reports the iteration that matched last. A group that matched the empty string has a length of zero and the offset at which it matched.

Offsets are absolute offsets into the scanned data and lengths are counts of bytes in it, the same coordinates that `@a` and `!a` use. For a `wide` pattern that includes the interleaved zero bytes, so a group covering two characters has a length of four. Every regexp pattern that has at least one capturing group reports its groups, whatever the shape of the pattern and wherever in the pattern the group sits.
