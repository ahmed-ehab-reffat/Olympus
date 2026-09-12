---
Repository: https://github.com/Kozea/WeasyPrint
Issue: https://github.com/Kozea/WeasyPrint/issues/259
Commit: d21889a799c760399b9e2cd06c8bc7ad5aec7144
Language: Python
Category: feature-request
Title: Add page and column floats to the layout engine
---
# Add page and column floats to the layout engine

Add the page float values `top` and `bottom` to the float property, along with a `float-reference` property, so a box can be pinned to the top or the bottom of the page or column that holds it.

A box with `float: top` or `float: bottom` leaves the normal flow and is laid out at the line-left edge of its reference, shrinking to fit when its width is auto, with its margins honoured, and it is never split. Content is then laid out around it exactly as around a `float: left` box of the same size, and `clear: left` clears it. Several top floats stack downwards in document order, several bottom floats stack upwards, and bottom floats stay above the footnote area of their page.

`is_page_floated()` on a box reports whether it is a page or column float. A placed float sits as a direct child of the page's root box, where the page already collects its out-of-flow boxes, rather than under the element it was written in.

`float-reference` accepts `inline`, `column` and `page`, and its initial value is `inline`. With `inline` or `column`, a page float uses the current column of the nearest multi-column container when there is one and the page otherwise. With `page` it always uses the page, so a float declared inside columns is pinned to the page instead, and a multi-column container never overlaps a float of its own reference.

A float that does not fit in the space its reference has left moves on: to the next column when the reference is a column, to the next page once there is no next column, and to the next page when the reference is the page. Later floats are still placed on that page when they fit there. A float taller than its whole reference is placed in it anyway rather than moved forward forever.

A page float belongs to the page that ends up holding the element it was written in, so when placing floats pushes that element onto a later page, the float follows it there instead of staying behind. That element may sit in any nested formatting context, and the float still references the page or the column rather than that context.

For boxes that are absolutely positioned or fixed, float computes to none. Inside a footnote, `top` and `bottom` compute to `left`, since a footnote is laid out in its own area rather than in a page or column reference.
