---
Repository: https://github.com/Kozea/WeasyPrint
Issue: https://github.com/Kozea/WeasyPrint/issues/259
Commit: d21889a799c760399b9e2cd06c8bc7ad5aec7144
Language: Python
Category: feature-request
Title: Add page floats to the layout engine
---
# Add page floats to the layout engine

Add the page float values `top` and `bottom` to the float property, so a box can be pinned to the top or the bottom of the page that holds it.

A box with `float: top` or `float: bottom` is laid out at the left edge of the page area, shrinking to fit when its width is auto, with its margins honoured, and it is never split. Content is then laid out around it exactly as around a `float: left` box of the same size, and `clear: left` clears it, but it doesn't push later ordinary floats down to its own top edge. Several top floats stack downwards in document order, several bottom floats stack upwards, and bottom floats stay above the footnote area of their page.

The float goes to the edge of its page even when its element comes after other content on that page: the content before it is laid out again around the float, rather than the float moving to a later page. `is_page_floated()` on a box reports whether it is a page float, and a placed float sits as a direct child of the page's root box rather than of the element it was written in.

A float that does not fit in the space the page has left moves on to the next page, and later floats are still placed on the current page when they fit there. A float taller than the whole page area is placed anyway, starting at its top edge, rather than moved forward forever. A page float belongs to the page that ends up holding the element it was written in, so it follows that element when float placement pushes it onto a later page. That element may sit inside a paragraph, a table cell, a multi-column container or a block with its own formatting context, and a multi-column container never overlaps a page float: its columns start below the top floats and end above the bottom floats.

Inside another float, a footnote, an absolutely positioned or fixed box or a running element, `top` and `bottom` compute to `left` instead, since such a box is laid out in its own area rather than on the page. Flex and grid items ignore `top` and `bottom`, as they ignore the other float values.
