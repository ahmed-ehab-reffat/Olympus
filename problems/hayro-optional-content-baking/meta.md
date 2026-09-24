---
Repository: https://github.com/LaurenzV/hayro
Issue: N/A
Commit: 6dcda45859b7e9cc8488fb6cd011795ba0cca86b
Language: Rust
Category: feature-request
Title: Bake default optional content visibility into hayro-write extraction
---

# Bake default optional content visibility into hayro-write extraction

Add optional content (layer) support to page extraction in hayro-write. Today `extract` copies a page's content stream unchanged and strips `/OC` entries, and the extracted chunk carries no `/OCProperties`, so anything the source document hides by default shows up on the extracted page.

When the source document has an optional content configuration, both extraction modes (a new page and a Form XObject) should draw exactly what the source page shows under its default configuration, even in a viewer that knows nothing about optional content. The default configuration is the `/D` dictionary of the catalog's `/OCProperties` with its `BaseState`, `ON` and `OFF` entries, and membership dictionaries decide with their `P` policy. Content is hidden when it sits inside a marked-content section whose `/OC` properties are off, at any nesting depth, or when it is an XObject whose own `/OC` entry is off.

Hidden content paints nothing, but everything else it does still takes effect for the content that follows it: graphics state changes, the clipping path and the text position. Content that is shown draws exactly as it did before.
