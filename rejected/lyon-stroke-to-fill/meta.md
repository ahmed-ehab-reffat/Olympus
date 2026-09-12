---
Repository: https://github.com/nical/lyon
Issue: N/A
Commit: 8071ec066c610b006e58086fea30cd96d4cef153
Language: Rust
Title: Convert strokes to fillable outlines
---
# Convert strokes to fillable outlines

lyon can render a stroke but cannot express that stroke as a fillable path, so there is no way to obtain the region a stroke would paint as geometry. Add a `StrokeToFill` trait, implemented for `Path` and `PathSlice`, whose `stroke_to_fill` method takes a `StrokeOptions` and returns a `Path` that, filled with the non-zero winding rule, covers exactly that region. The same outline should also be reachable from a plain sequence of path events, for callers that do not already hold a `Path` or `PathSlice`.

A miter reaching farther than `miter_limit` times the half width becomes a bevel under `Miter` and is truncated at that length under `MiterClip`, and a `miter_limit` below one counts as one. A subpath whose points all coincide becomes a full disc or square for round or square caps and nothing for butt. A closed subpath leaves its interior empty, and a `line_width` that is not a positive finite number yields an empty path.

The returned path is a simple outline of that region: filling it with the even-odd rule covers the same region as the non-zero rule.
