---
Repository: https://github.com/nical/lyon
Issue: https://github.com/nical/lyon/issues/871
Commit: 8071ec066c610b006e58086fea30cd96d4cef153
Language: Rust
Category: feature-request
Title: Add interior vertex elimination to the fill tessellator
---
# Add interior vertex elimination to the fill tessellator

Add an opt-in mode to the fill tessellator that emits only the vertices sitting on the boundary of
the filled region. Today, whenever subpaths overlap, under either fill rule, the tessellator also
emits vertices that fall strictly inside the filled region, along with the extra triangles that fan
off them, so a shape drawn as two overlapping subpaths produces a busier mesh than the same shape
drawn as a single outline. Where two subpaths merely meet along a shared edge, nothing lands inside
the region, but the mesh still carries boundary vertices sitting in the middle of a straight run.
Add a public `eliminate_interior_vertices` field on `FillOptions`, plus a
`with_interior_vertex_elimination` builder method that sets it. Both fill rules honor the setting.

A vertex is interior, and is dropped, when the filled region covers a full neighborhood around it.
A vertex that only looks enclosed is not interior: corners of holes, where a subpath is wound
against the one containing it, and reflex corners of the outline, such as the inner points of a
self-overlapping star, all lie on the boundary and are kept.

Also drop any surviving boundary vertex that sits in the middle of a straight run, meaning it has a
single boundary edge arriving and a single one leaving, and it lies exactly on the segment between
those two neighbors. Keep going until no removable vertex is left.

Any given point is inside the mesh afterwards exactly when it was inside before. Triangles keep the
same winding the tessellator already produces for that sweep orientation. Every vertex handed to the
geometry builder is used by at least one triangle, and the vertices that survive are handed over in
the same relative order as before.

The option is off by default.
