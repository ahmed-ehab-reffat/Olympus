---
Title: Add locally refined quadrilateral meshes with hanging nodes
Repository: https://github.com/kinnala/scikit-fem
Language: Python
Issue: local-refinement-hanging-nodes
Commit: 51cec1ff5ac6c00dd7a438ae3d01845f8d013899
---

# Add locally refined quadrilateral meshes with hanging nodes

`MeshQuad1.refined` takes element indices, repeats collapsing and a negative counting from the end, and splits each marked quadrilateral into four, reusing a vertex already in the middle of one of its facets rather than adding a second there. Unmarked elements are left alone, so a vertex can land in the middle of a neighbour's facet, where it is called hanging. Refinement also splits whatever else is needed so no facet is split twice: an element on the fine side of a hanging vertex is split only with the one on the coarse side, continuing until nothing further needs splitting. Named boundaries and subdomains survive, a split named facet contributing both halves.

Every mesh, not only the quadrilateral one, gains the same five queries, each a method like `boundary_facets()`. Index arrays are sorted ascending. `hanging_nodes()`, `split_facets()` and `hanging_facets()` return the hanging vertices, the facets they split and the halves those are split into, `hanging_elements()` the elements on the coarse side, and `is_one_irregular()` whether every facet is split at most once. A split facet and its two halves are interior, so `boundary_facets()` and all that rests on it, including a `FacetBasis` given no facets, cover the exterior only. `hanging_f2t()` is `f2t` with the coarse element as the second neighbour of each half, letting `InteriorFacetBasis` evaluate a jump there. `conforming()` splits coarse elements until no hanging vertex is left.

`coarsened` takes indices the same way and merges each group of four elements subdividing a larger quadrilateral back into it, provided all four are marked, none is already merged and no facet on its outer boundary is itself split by a hanging vertex, which being one half of a coarser facet is not; groups are taken in decreasing order of their shared vertex. Unused vertices are dropped and tags survive.

A degree-of-freedom on a hanging facet not belonging to the element on the coarse side is constrained, its value being what that element's own basis functions give at its location, component by component and, for a composite element, field by field. `Basis.hanging_dofs()` returns those sorted and `Basis.hanging_prolongation()` an N by N sparse matrix whose free rows are unit rows, whose constrained rows carry those weights, and whose constrained columns are zero. `skfem.constrain(basis, A, b, x, D)` eliminates the constrained degrees-of-freedom along with `D`, which may name them again since the sets are combined, returning a system for `solve` whose result has the constrained values filled in; `b` may also be a mass matrix. `Basis.project` obeys the constraints, and `skfem.coarsen_theta` mirrors `adaptive_theta`, returning elements whose indicator is at or below a fraction of the largest.

`skfem.models.poisson.residual_estimator(basis, x, f)` gives one indicator per element: the squared load times the squared mesh parameter the forms supply as `h`, plus half the squared jump of the normal derivative across each of its facets times that facet's own `h`, the halves of a split facet contributing to the coarse element too. Adaptive refinement of a second-order quadrilateral mesh raises `NotImplementedError`.
