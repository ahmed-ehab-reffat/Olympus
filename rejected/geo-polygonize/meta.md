Add a `Polygonize` operation that builds polygons from the lines of a geometry.

Add a `Polygonize` trait with a method `polygonize` that returns a `Polygonized` struct with three public fields: `polygons: MultiPolygon<f64>`, `dangles: MultiLineString<f64>`, and `cut_edges: MultiLineString<f64>`. Implement the trait for `LineString<f64>`, `Line<f64>`, `MultiLineString<f64>`, `GeometryCollection<f64>`, and `Geometry<f64>`.

The operation collects every `Line` and `LineString` contained in the geometry — including those held in a `MultiLineString`, and those nested inside a `GeometryCollection` or `Geometry`, recursing through nested collections — and treats them as the edges of a planar arrangement. Non-linear geometries (points, polygons, and so on) contribute nothing.

From that arrangement it forms polygons. Each smallest region that the lines enclose becomes one polygon in `polygons`. A region can be enclosed by a combination of several lines rather than by a single closed line; for example, a square whose interior is crossed by one diagonal yields two triangular polygons. When the lines bounding one enclosed region lie entirely inside another region, the inner region is cut out of the outer one as a hole, and the inner region is itself also returned as its own polygon.

Not every line bounds a region. A line that hangs off an endpoint touched by no other line bounds nothing and is reported in `dangles` instead of contributing to a polygon; removing such a line may expose further lines that then also dangle. A line that connects the arrangement but still bounds no region — a bridge whose removal would split the arrangement — is reported in `cut_edges`. Every input line ends up either forming part of a polygon boundary, in `dangles`, or in `cut_edges`.

The input lines are assumed to be noded: they meet only at shared endpoints, not by crossing or overlapping in their interiors. The order of the polygons in the result, the order of lines within `dangles` and `cut_edges`, and the starting vertex and winding direction of every ring are all unspecified.
