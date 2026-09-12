---
Repository: https://github.com/felt/tippecanoe
Issue: N/A
Commit: 4f2621186acfec33b63ddf636f665623c0fef2dd
Language: C++
Category: feature-request
Title: Add tile size recourses to the tile-join merger
---

# Add tile size recourses to the tile-join merger

Add tile size recourses to `tile-join`.

Because `tile-join` copies geometries into the new tileset without processing them, a merged tile that comes out larger than the size limit is left out of the tileset altogether. Give it the two recourses `tippecanoe` has for the same situation.

`-M` or `--maximum-tile-bytes` sets the limit, in bytes, on the compressed tile, or on the tile itself when `--no-tile-compression` is given, and is 500000 by default. `--drop-smallest-as-needed` makes a tile that is larger than the limit shed features until it fits instead of being skipped. A tile that is not over the limit is written exactly as it is written today.

Features are shed in increasing order of extent: a polygon's extent is the area of its bounding box in tile coordinates, a line's is the width plus the height of its bounding box, and a point's is zero. Features of equal extent are shed in reverse of the order they were merged in. Dropping is across the whole tile, not per layer. A tile that still does not fit once one feature is left is skipped, as it is now, and `--no-tile-size-limit` still turns the limit off entirely.

A tile that was reduced has to be as clean as one that was copied. A layer carries no attribute key and no attribute value that none of its remaining features uses, every remaining feature keeps the attributes it had, and a layer with no remaining features is not written.

Whatever `tile-join` sheds is added to the per-zoom `dropped_as_needed` count in the `strategies` metadata, on top of the counts it inherits from its inputs, and the largest size a tile at that zoom wanted to be before it was reduced is reported there as `tile_size_desired`. A run that sheds nothing leaves `strategies` exactly as it inherited it.
