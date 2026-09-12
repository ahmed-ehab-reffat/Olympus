---
Repository: https://github.com/reinterpretcat/vrp
Issue: N/A
Commit: 1b0a5e8c49dbf3e34aba5bf1a2ac57fe5af82655
Language: Rust
Category: feature-request
Title: Add TSPLIB non-Euclidean edge-weight types and CLI location export
---

# Add TSPLIB non-Euclidean edge-weight types and CLI location export

Add CEIL_2D, ATT, GEO, and EXPLICIT support to the TSPLIB CVRP reader.

CEIL_2D distance between two points is the ceiling of the Euclidean distance.

For ATT, take the square root of ((dx squared plus dy squared) divided by 10), round to the nearest integer, and add 1 when the rounded value is below the unrounded one.

For GEO, read each coordinate as degrees-and-minutes rather than decimal degrees (whole part degrees, fractional part minutes), converted to radians as pi times (degrees plus 5 times minutes divided by 3), divided by 180. Using the two points' converted latitude and longitude, take the cosine of the longitude difference, the cosine of the latitude difference, and the cosine of the latitude sum. The distance is 6378.388 times the arc cosine of half of ((1 plus the longitude-difference cosine) times the latitude-difference cosine, minus (1 minus the longitude-difference cosine) times the latitude-sum cosine), floored and then increased by 1.

EXPLICIT edge weights are supplied in an EDGE_WEIGHT_SECTION, laid out according to the instance's declared EDGE_WEIGHT_FORMAT, which every EXPLICIT instance must carry. Support exactly five layouts and reject any other EDGE_WEIGHT_FORMAT value: FULL_MATRIX lists every row in full. UPPER_ROW lists, row by row up to the second-to-last row, only the values strictly right of the diagonal; LOWER_ROW does the same left of it. UPPER_DIAG_ROW and LOWER_DIAG_ROW are those same two traversals with the diagonal entry included in each row. EXPLICIT instances also require a DISPLAY_DATA_TYPE key, accepting only NO_DISPLAY and TWOD_DISPLAY; the other edge-weight types never carry one. NO_DISPLAY means no further coordinate data follows, so a DISPLAY_DATA_SECTION under NO_DISPLAY is rejected; TWOD_DISPLAY means a DISPLAY_DATA_SECTION directly after EDGE_WEIGHT_SECTION, before DEMAND_SECTION, with one coordinate line per node, the depot included. EDGE_WEIGHT_FORMAT, DISPLAY_DATA_TYPE, and CAPACITY may appear in any order relative to each other. Those coordinates are for visualization only and never affect distances.

The depot's row and column remain part of the parsed matrix. Explicit weights are used exactly as given, with no rounding. is_rounded continues to control only the existing EUC_2D path.

vrp-scientific implements a `TsplibLocations` trait for `Problem` with `get_tsplib_locations(&self)`, returning `Option<Vec<(String, f64, f64)>>`: one (id, x, y) triple per DISPLAY_DATA_SECTION node, using the same zero-based id every job and the depot already use elsewhere in the parsed problem, or `None` when the instance has none. Each DISPLAY_DATA_SECTION line names its own node, so the lines need not appear in node order. The returned triples are always ordered by ascending node number, which past node 9 differs from alphabetical id order. vrp-cli exposes `get_tsplib_locations_serialized`, taking that same `Problem` and returning `Result<String, _>`: those triples serialized to JSON with `id`, `x`, and `y` fields in that same ascending node order, or an error when there are none. Have vrp-cli's existing `solve tsplib <problem> --get-locations` command return this JSON output.
