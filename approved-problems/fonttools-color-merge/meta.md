---
Repository: https://github.com/fonttools/fonttools
Issue: N/A
Commit: 386243ed95d6a42114f7695f21de3ef45524108a
Language: Python
Title: Merge the color tables when combining fonts
---
# Merge the color tables when combining fonts

Merging fonts silently drops every color table, so a color font comes out of the merger with no color at all. Merge `COLR`, `CPAL`, `SVG `, `CBDT`/`CBLC` and `sbix`.

The merged `CPAL` holds every font's color records, each font's block starting after the records of the fonts before it. The merged palette count is the largest of the inputs and a font with fewer palettes repeats its last one; the version is the largest of the inputs; a palette's type comes from the first font that has that palette. Palette and entry labels survive only from the first font, whose `name` records are the ones the merger keeps, and the rest become absent.

Every palette index a `COLR` table reaches, in its layer records, its solid paints and its gradient color stops alike, moves into that font's block. The value 0xFFFF selects the text foreground color rather than a palette entry, and is left alone. Base glyph records are ordered by glyph ID, layers keep their font's order, and every index into the merged layer list is re-based. Every font's clip boxes are kept. The merged version is the largest of the inputs. A `COLR` carrying variation data raises `NotImplementedError`, and one without a `CPAL` raises `ValueError`.

The merged palettes are then canonicalized: entries no color glyph references are dropped, entries holding the same color in every palette collapse onto the first of them, and a run of layers that repeats is stored once and shared.

An `SVG ` document's glyph IDs move by the number of glyphs the earlier fonts contribute -- its `startGlyphID` and `endGlyphID`, and the glyph names its `id` and `href` attributes carry, all rewritten together. Documents are ordered by start glyph ID.

`CBLC` strikes of equal size and depth merge, widening their line metrics to cover both fonts. `CBDT` records no size of its own, so its bitmap dictionaries follow the same strike order. `sbix` strikes merge by ppem; disagreeing resolutions raise `ValueError`.
