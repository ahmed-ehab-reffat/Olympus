---
Repository: https://github.com/LaurenzV/hayro
Issue: N/A
Commit: 6dcda45859b7e9cc8488fb6cd011795ba0cca86b
Language: Rust
Category: feature-request
Title: Bake default optional content visibility into hayro-write extraction
---

# Bake default optional content visibility into hayro-write extraction

When hayro-write extracts a page, as a new page or as a Form XObject, from a PDF that has optional content (layers), the layers that are hidden by default should stay hidden in the output.

Users of the extracted PDFs, including users of PDF viewers that do not support optional content, should have the same experience as users of the original PDFs.

This applies to all content drawn on a page, including content in Form XObjects, tiling patterns, Type 3 fonts, and soft masks. Hidden sections should not be drawn but otherwise still affect later content, including graphics states and clipping paths, including glyph shapes for glyphs drawn in clipping mode, and text position. Section properties may be specified inline rather than by name; in these cases, the /OC entry in the inline dictionary points to a group or membership dictionary specifying whether the section is hidden.

You can assume that optional content sections are tagged with the /OC keyword, a Form XObject with hidden text is drawn only once by a Do operator, a Form XObject, tiling pattern, Type 3 font, or soft mask that inherits its resources from whatever uses it is used from only one place, group states in the default configuration are set only with /BaseState, /ON, or /OFF, membership dictionaries lack a /VE entry and use the AnyOn or AllOn policy, and a section that names its properties finds them in the /Properties entry of the stream it is in.
