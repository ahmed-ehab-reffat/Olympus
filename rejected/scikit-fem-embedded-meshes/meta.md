---
Repository: https://github.com/kinnala/scikit-fem
Issue: N/A
Commit: 73e8357003d67ce267f39c74356a8f045bae99ab
Language: Python
Category: feature-request
Title: Add meshes embedded in a higher-dimensional ambient space
---

# Add meshes embedded in a higher-dimensional ambient space

Add meshes embedded in a higher-dimensional ambient space to scikit-fem: lines in the plane or in space, triangles and quadrilaterals, first or second order, in space. Today `Mesh.is_valid` rejects a point array with more rows than the reference dimension, both mappings assume a square Jacobian, and `from_meshio` strips every coordinate beyond it.

Such a mesh is valid whenever the point array has at least as many rows as the reference dimension; `Mesh.dim()` keeps meaning the reference dimension and the ambient dimension is the row count of the point array. Both the affine and the isoparametric mapping support it, including the inverse mapping of a point lying on the mesh. A cell basis integrates with the measure of the curve or surface itself, and the gradient of a basis function is the tangential gradient with one component per ambient coordinate. Elements that use a Piola transformation take values tangent to the mesh. A facet basis integrates over the boundary of the curve or surface with that boundary's own measure, and the normal it supplies to forms is the outward unit co-normal: tangent to the mesh and perpendicular to the boundary. Interior facet bases, element finders, probes, interpolators, mesh parameters and the helpers `param`, `translated`, `scaled` and `mirrored` work in the ambient space and `smoothed` moves each free vertex only within the tangent space of the mesh at that vertex, so a flat patch stays flat. Assembly on an embedded mesh is unchanged by any rigid motion of the ambient space, and a mesh whose points all lie in a coordinate subspace assembles exactly what the lower-dimensional mesh does.

Quadrilateral meshes gain `orientation` and `oriented`, taking the sign at the element centre. On an embedded mesh a Jacobian determinant has no sign, so `orientation` instead compares every element with the first through chains of neighbours: 1 when the orientation carried along the chain agrees with the element's own vertex order, -1 when reversed, and `oriented` flips the latter. A mesh with no consistent orientation raises `ValueError` from both. On a curve in the plane or a surface in space a cell basis also supplies `n`, the unit normal induced by the vertex order of each element: for a curve the tangent from the first vertex to the second turned a quarter turn clockwise, for a surface the cross product of the edges from the first vertex to the second and to the third.

`from_meshio` and `Mesh.load` keep the coordinates a mesh actually uses; trailing coordinates are dropped only when they are all zero. `Mesh.trace` without a mesh type returns a mesh of the facet type, embedded in the same space when no projection is given, every named boundary meeting the traced facets becoming a named subdomain of it, and a facet basis over those facets integrates the same as a cell basis over the trace. Elements defined through global degrees of freedom, like Morley, raise `NotImplementedError` on embedded meshes.
