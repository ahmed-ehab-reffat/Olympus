---
Repository: https://github.com/servo/rust-url
Language: Rust
Issue: none (original feature request)
Commit: 25137be1fc1d35cc8ea7d43fc0a02166b023a483
Title: Add a WHATWG URLPattern matcher over the URL model
---

# Add a WHATWG URLPattern matcher over the URL model

Add a new workspace crate `urlpattern` that implements the WHATWG URLPattern specification for constructor-string parsing, compilation, and matching, over the existing URL model. A pattern is built from a constructor string or a structured `UrlPatternInit` (optional `protocol`, `username`, `password`, `hostname`, `port`, `pathname`, `search`, and `hash`) and matched against a `UrlPatternMatchInput`, which is either `Url(url::Url)` or `Init(UrlPatternInit)`. `UrlPatternInit` and `UrlPatternOptions` implement `Default`.

API:

- `UrlPatternInit::parse_constructor_string(pattern: &str, base_url: Option<url::Url>)` takes the base URL by value and errors when the string has no protocol and no base URL is supplied.
- `UrlPattern::parse(init, options)` canonicalizes each component; `options.ignore_case` makes the pathname, search, and hash match case-insensitively.
- `test` and `exec` return a `Result`; a match input that cannot be canonicalized is a non-match (`Ok(false)` / `Ok(None)`), not an error. `test(input)` reports whether the input matches. `exec(input)` returns `None` on no match, otherwise a `UrlPatternResult` whose `protocol`, `username`, `password`, `hostname`, `port`, `pathname`, `search`, and `hash` fields each hold a `UrlPatternComponentResult` with an `input` (the matched substring) and a `groups` map from each group name to an `Option<String>` capture that is `None` for an unmatched optional group.
- The `protocol()`..`hash()` accessors return the canonicalized pattern strings, and `has_regexp_groups()` reports whether any component used a regexp group. Component values omit their leading delimiter, so a `search` accessor or matched `input` drops the `?` and a `hash` drops the `#`.

Matching and syntax:

- Each component matches its whole value, with no partial matches.
- Syntax is `:name` (named group), `(regex)` (regexp group), `*` (wildcard), `{ }` (grouping), and the modifiers `?` (optional), `+` (one or more), `*` (zero or more). A bare `*` and each `(regex)` are captured under a zero-based index counting only the anonymous groups, so a preceding named group does not advance it. A `+`/`*` group captures the whole repeated span.
- A backslash escapes the next character so it is matched literally. A group may carry surrounding fixed text as prefix and suffix. In the pathname, a named group matches a single path segment and rejects an empty segment; a full wildcard matches anything.
- Ports equal to the scheme's default are canonicalized to empty for every special scheme and still match a defaulted URL; a hostname `*` matches any host, including bracketed IPv6.
- Protocol and hostname are lowercased during canonicalization while a pathname pattern keeps its original case; a hostname is further canonicalized through IDNA so an internationalized hostname matches its Punycode form. A pathname or search pattern is canonicalized the same way the URL model encodes it, so a pattern and target differing only by percent-encoding still match.
- Duplicate group names and unbalanced regexp groups are parse errors.
