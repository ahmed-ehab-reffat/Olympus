---
Repository: https://github.com/yeslogic/allsorts
Issue: N/A
Commit: efab0fc769287f4ced68bbd723c328c9d9b89698
Language: Rust
Category: feature-request
Title: Add layout and vertical metric instancing to font variations
---
# Add layout and vertical metric instancing to font variations

We want `variations::instance` to instance the layout tables and the vertical metrics of a variable font as well. Right now it rebuilds the outlines, the horizontal metrics and a few header tables at the requested location, but GSUB, GPOS, GDEF, vhea and vmtx are copied over as they are, so the static font that comes out doesn't shape like the variable font did at that location.

The font that `instance` returns should shape the same way the variable font does there. If we shape some text with the instance through `Font::shape` without a variation tuple, we should get the same glyphs, and the same kerning and placement on each glyph, as when we shape that text with the variable font and pass the tuple that `instance` returns. This has to hold for every script and language system in the font, for the feature variations in both GSUB and GPOS, and for the variation deltas on GPOS positioning values.

Once the location has been applied there's no variation data left for the layout tables to carry, so the instance's GSUB and GPOS shouldn't have a FeatureVariations table anymore and its GDEF shouldn't have an item variation store.

We'll treat the vertical metrics the way the horizontal ones are treated today. When the font has a VVAR table, a glyph's advance height is its vmtx advance plus the VVAR delta, rounded, and its top side bearing takes the VVAR delta as well when VVAR maps one; otherwise the top side bearing is the distance from the glyph's top phantom point down to the top of its new bounding box. A TrueType font without VVAR takes both values from the glyph's vertical phantom points after the gvar deltas have been applied. A CFF2 font without VVAR keeps its vertical metrics as they are. The vhea table takes the MVAR deltas for its vertical ascender, descender, line gap and caret values, and its maximum advance height becomes the largest advance height in the new vmtx.
