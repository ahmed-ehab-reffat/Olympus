---
Repository: https://github.com/chearon/dropflow
Issue: N/A
Commit: 13552695d3446ac68f39952ea89dc69c4499dde2
Language: TypeScript
Category: feature-request
Title: Add min and max sizing constraints to block layout
---
# Add min and max sizing constraints to block layout

Add the `min-width`, `max-width`, `min-height` and `max-height` properties to dropflow's layout engine. Today the CSS parser drops these declarations and every box is sized purely from width, height and its content, so a block with max-width: 100px and auto side margins still fills its containing block. The properties must be accepted in style attributes and stylesheets (lengths, percentages, and `none` for the two maximums; auto is not a valid value and such a declaration is dropped) and as the `minWidth`, `maxWidth`, `minHeight` and `maxHeight` keys of a hyperscript style object. Minimums default to 0, maximums to none, and none of the four are inherited.

The used content size of a box is its tentative size clamped to the range, with the minimum winning when it exceeds the maximum. Under box-sizing: border-box a limit measures the border box, exactly as width and height do. Percentage widths resolve against the containing block's width. Percentage heights resolve against the containing block's height only when that height is specified explicitly (or the containing block is the initial one); otherwise the minimum acts as 0 and the maximum as none.

For block-level boxes the limits apply to the width the normal rules would otherwise produce, and the horizontal margins are then resolved again against the clamped width as if that width had been specified, so auto margins center a clamped box and over-constrained space goes to the end-side margin. Heights computed from children or line boxes are clamped as well, and following siblings are positioned after the clamped box while the box's own children keep their natural layout. A box whose minimum height resolves to more than zero no longer collapses its own margins through, and its bottom margin no longer collapses with its last child's bottom margin; maximum heights do not change margin collapsing.

The shrink-to-fit width of floats and inline-blocks is clamped by their own limits, and the intrinsic width contribution each box makes to an ancestor's shrink-to-fit width is clamped by that box's minimum and maximum width, where percentage limits are ignored. For images, a specified dimension is clamped, a dimension derived through the intrinsic ratio is derived from the clamped value and then clamped itself, and when both dimensions are auto the intrinsic size is constrained the way CSS 2 section 10.4 prescribes for replaced elements with an intrinsic ratio, so the ratio is preserved through the tighter of two limits on different axes.
