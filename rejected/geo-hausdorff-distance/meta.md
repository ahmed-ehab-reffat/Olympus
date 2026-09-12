---
Repository: https://github.com/golang/geo
Issue: N/A
Commit: 857a528af6418dcb67b1d9d4fae1100dcd530fa7
Language: Go
Title: Add Hausdorff distance between shape indexes
---
# Add Hausdorff distance between shape indexes

The s2 package can find the closest edge between two `ShapeIndex` values but has no way to measure how far apart two geometries are in the worst case, which is what applications comparing a computed shape against a reference shape need.

Add `DirectedHausdorffDistance` and `HausdorffDistance`, each taking two indexes and a `HausdorffDistanceOptions`, and returning a `HausdorffDistanceResult`.

The directed Hausdorff distance from a source index to a target index is the greatest distance from any point of the source geometry to the nearest point of the target geometry. This supremum is always attained at a vertex of the source, so it equals the maximum, over every vertex of every source shape, of that vertex's distance to the target. It is not symmetric. The undirected `HausdorffDistance` is the larger of the two directed distances taken in both directions.

`HausdorffDistanceResult` exposes `Distance` as an `s1.Angle` and `TargetPoint` as the source vertex where the directed maximum is attained.

When `IncludeInteriors` is true (the default), a source vertex that lies inside a target polygon has distance zero; when false, only distance to target boundary edges counts. Distances are geodesic.

Every shape in the source index contributes its vertices, including single-point shapes and degenerate edges. If the source index has no edges the result distance is a negative `s1.Angle` and `TargetPoint` is unset; if the source has vertices but the target index has no edges the directed distance is infinite.
