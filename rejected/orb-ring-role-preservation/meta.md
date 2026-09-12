---
Repository: https://github.com/paulmach/orb
Issue: N/A
Commit: a12a48ea0c2bcfdea706cc1ab274c735cbc68939
Language: Go
Category: enhancement
Title: Preserve polygon ring roles through vector tile encoding
---
# Preserve polygon ring roles through vector tile encoding

Add ring-role preservation to orb's vector tile encoder, and give callers a way to put polygon rings into a known winding. A polygon's rings currently go out in whatever direction they arrived in, so a hole can come back as solid ground.

A polygon encoded with `Marshal` and read back with `Unmarshal` should return a polygon with the same holes, and a multipolygon should return the same polygons in the same order. The roles have to live in the tile itself rather than in orb's reader: a conforming vector tile reader that has never seen this library should recover the same exterior rings and the same holes. Rings with fewer than three distinct positions are dropped, and a polygon whose exterior encloses no area is dropped entirely.

Existing GeoJSON and BSON output is unchanged.

Add `Orient` on `orb.Ring`, `orb.Polygon` and `orb.MultiPolygon`. On a ring it takes the wanted orientation; on a polygon and a multipolygon it winds each exterior ring counterclockwise and every hole clockwise, keeping the polygons of a multipolygon in the order they came in. All three return a copy, closing any ring that is open by repeating its first position, and leaving a ring that encloses no area as it is. `orb.Polygon` and `orb.MultiPolygon` also get `OrientWith`, taking the orientation their exterior rings should end up in, and `orb.Ring` gets `Close`, returning a closed copy of itself.

Add `geojson.CutAntimeridian`, which splits geometry that crosses the antimeridian so no ring or line spans the seam. A split polygon becomes a multipolygon whose pieces are ordered west to east, each piece independently oriented, with every hole attached to the piece that contains it. A split line becomes a multi line string, and the two sides meet at the same latitude on the seam. Geometry that does not cross is returned as it is.

None of these ever modify the geometry they are given.
