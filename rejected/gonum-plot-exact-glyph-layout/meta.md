---
Repository: https://github.com/gonum/plot
Issue: N/A
Commit: d56745857d70e2e68bbcb858ff76fa6000cd8442
Language: Go
Category: feature-request
Title: Add exact glyph-aware layout to plot padding and Align
---

# Add exact glyph-aware layout to plot padding and Align

We want a plot's data area to be the widest and tallest one that keeps every glyph box inside the canvas. The padding today is worked out from only the left-most and right-most boxes of the unpadded canvas, so there is no layout that takes every box into account, and no error for a glyph that has no room at all.

Glyph boxes from plotters have to stay beside the axes and below the title. The horizontal axis's labels may reach under the vertical axis but not past the canvas edges, and the vertical axis's labels may reach down beside the horizontal axis but not past the bottom or into the title. A box with no size in one direction is ignored in that direction, as it is today. Draw, DataCanvas and DrawGlyphBoxes all use this layout.

When the axes fit but no positive data size keeps every box inside, WriterTo returns nil and an error, Save returns that error without creating or touching the file, and Draw and DataCanvas give the data all the space beside the axes in that direction. A canvas too small for the axes and title themselves keeps today's behaviour, with no error.

Align should give every data canvas exactly the same size, lined up by column and by row. Each column's margins are the largest any of its plots needs at the common width, and that width is the largest for which the columns and the tile padding fit. Rows work the same way. Reference images will change wherever the new layout pulls a glyph back inside the canvas.
