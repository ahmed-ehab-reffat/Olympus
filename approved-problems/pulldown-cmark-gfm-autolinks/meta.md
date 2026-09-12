---
Repository: https://github.com/pulldown-cmark/pulldown-cmark
Issue: https://github.com/pulldown-cmark/pulldown-cmark/issues/695
Commit: 68afb08c9014619750afd12d403a78b7a72331a7
Language: Rust
Title: Add GFM extended autolinks for bare URLs and emails
---
# Add GFM extended autolinks for bare URLs and emails

Add an opt-in extension, gated behind a new `ENABLE_BARE_URL_AUTOLINKS` option, that recognizes
bare URLs and email addresses in ordinary text and turns them into links. Add this option as the
next flag in the `Options` bitset, occupying bit `1 << 18` (the existing flags end at `1 << 17`).

A recognized autolink starts only at the beginning of the text or immediately after a space, tab,
newline, or one of the characters `*`, `_`, `~`, or `(`. Three forms are recognized: a run beginning
with `http://` or `https://`, a run beginning with `www.`, and an email address of the form
`local@domain`. A URL run extends up to the next space, except that inline code spans and link or
image syntax take precedence and end the run early: `www.example.com/`x`` links only `www.example.com/`
and leaves the code span intact, and a bare URL running into `[text](dest)` link syntax stops before
it. Emphasis does not take precedence, so characters such as `*` or `_` that would otherwise start
emphasis are ordinary parts of the run and `http://example.com/a*b*c` links as a single URL. For a
`www.` autolink the visible text stays as written but the link
destination is prefixed with `http://`; an email destination is the address itself, which the
renderer turns into a `mailto:` link.

The host of a `www.`/`http(s)://` autolink, and the domain of an email, must be a dotted domain: it
needs at least one `.`, may contain only letters, digits, `-`, `_`, and `.`, must not have an
underscore in either of its last two dot-separated segments, and must not end in `-`. A run whose
host is not a valid domain, such as `http://localhost`, is left as plain text.

Trailing characters are then removed from the end of the run: any of `?`, `!`, `.`, `,`, `:`, `*`,
`_`, and `~`, and a trailing `)` only when the run contains more `)` than `(`. Such characters remain
part of the link when they occur in the interior, and removing one trailing character may expose
another.

Autolinking never occurs inside code spans, code blocks, existing autolinks, or the text or
destination of a link or image. A recognized autolink appears in the offset iterator with a source
span covering the recognized run.
