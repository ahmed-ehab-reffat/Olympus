---
Repository: https://github.com/DioxusLabs/taffy
Issue: N/A
Commit: bb351fcc056c93dbb967292acc4242a5d1c46b3c
Language: Rust
Title: Add last-baseline alignment for flex items
---
# Add last-baseline alignment for flex items

Taffy supports `align-items: baseline`, which aligns flex items on their first baseline, but offers no way to align them on their last baseline. Add a `LastBaseline` alignment keyword, exposed as `AlignItems::LAST_BASELINE` and parsed from `last baseline`, and implement it for flex containers.

Under last-baseline alignment each participating item is shifted along the cross axis so that its last baseline coincides with the group's furthest last baseline, mirroring how baseline alignment aligns first baselines. An item's last baseline is derived from its last flex line, and a flex container reports its own last baseline from its last line, so the value propagates correctly through nested containers. For a single-line item, such as a leaf, the last baseline equals the first baseline and the two modes agree; for an item that wraps onto several lines they differ, so first-baseline and last-baseline alignment place it at different cross positions.

As with baseline alignment, a line with fewer than two participating items is left unchanged.
