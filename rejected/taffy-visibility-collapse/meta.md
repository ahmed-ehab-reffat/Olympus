---
Repository: https://github.com/DioxusLabs/taffy
Issue: https://github.com/DioxusLabs/taffy/issues/124
Commit: bb351fcc056c93dbb967292acc4242a5d1c46b3c
Language: Rust
Title: Add visibility collapse for flex items
---
# Add visibility collapse for flex items

Taffy can only hide a node with `Display::None`, which removes it from layout entirely. Add a `visibility` style property, taking `Visible` (the default) or `Collapse`, that controls how a flex item participates in its container's main axis.

A flex item with `visibility: Collapse` is treated as having zero main size: it occupies no space along the main axis, so the space it would otherwise have taken becomes available to its siblings, including when those siblings grow to fill the container. Unlike `Display::None`, the collapsed item is still laid out as a child of the container rather than being removed from the flow.

`visibility: Visible` leaves layout unchanged, as does any visibility value on an item whose container is not a flex container.
