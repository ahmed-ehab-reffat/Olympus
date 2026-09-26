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

When the source document has an optional content configuration, both extraction modes (a new page and a Form XObject) should draw exactly what the source page shows under its default configuration, even in a viewer that knows nothing about optional content. The default configuration is the `/D` dictionary of the catalog's `/OCProperties` with its `BaseState`, `ON` and `OFF` entries, and membership dictionaries decide with their `P` policy. Content is hidden when it sits, at any nesting depth, inside a marked-content section whose properties are an optional content group or membership dictionary that is off, whatever tag the section carries, or when it is an XObject whose own `/OC` entry is off. A section's properties either come by name or are written inline. A name is looked up only in the `/Properties` resources of the content stream the section appears in, not in the resources of the stream that draws it, and a Type3 glyph procedure uses its font's resources. An inline property list uses its `/OC` entry. Either way a membership dictionary counts whether it is written out directly or referenced, while a group is always a reference. The same rules apply inside every content stream the page runs, however deeply nested: Form XObjects, tiling pattern cells, Type3 glyph procedures and soft-mask groups.

Hidden content paints nothing, but everything else it does still takes effect for the content that follows it: graphics state changes, the clipping path (including the glyph outlines that text shown in a clipping render mode adds to it) and the text position. Content that is shown draws exactly as it did before. Inside a Form XObject, though, hidden text and the text after it use the render mode the form itself set, or fill if it set none, never the mode of whoever draws the form.
