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

Because `tile-join` copies geometries into the new tileset without processing them, a merged tile that comes out larger than the size limit is left out of the tileset altogether.

`-M` or `--maximum-tile-bytes` sets the limit, in bytes, on the compressed tile, or on the tile itself when `--no-tile-compression` is given, and is 500000 by default. `--drop-smallest-as-needed` makes a tile that is larger than the limit shed features until it fits instead of being skipped.

Features are shed in increasing order of extent: a polygon's extent is the area of its bounding box in tile coordinates, a line's is the width plus the height of its bounding box, and a point's is zero. Extent is measured on the geometry as merged, even when `--exclude-all-tile-geometries` leaves geometries out of the output. Features of equal extent are shed in reverse of the order they were merged in. Dropping is across the whole tile, not per layer. A tile that still does not fit once one feature is left is skipped, and `--no-tile-size-limit` still turns the limit off entirely.

In a reduced tile, a layer carries no attribute key and no attribute value that none of its remaining features uses, every remaining feature keeps the attributes it had, and a layer with no remaining features is not written.

Whatever `tile-join` sheds, including from a tile that ends up skipped anyway, is added to the `dropped_as_needed` count for that zoom in the `strategies` metadata, the JSON array holding one object per zoom level, on top of the counts it inherits from its inputs. The `tile_size_desired` reported there is the largest size any tile at that zoom wanted to be before shedding, including a tile that could not be reduced at all, counting the sizes inherited from the inputs. A run that sheds nothing leaves `strategies` exactly as it inherited it, and leaves it out entirely if it inherited none. The layer statistics, the layer and tileset zoom ranges, and the tileset bounds are computed from only the features that reached the output, whether the ones left out were shed to make a tile fit or lost because the tile was skipped.
