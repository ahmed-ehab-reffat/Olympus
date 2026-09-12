# Add connected region analysis for sparse arrays

Add a `sparse.regions` namespace for connected groups. A position is a cell when its value is not zero, so a stored zero is not one; non-zero fill is rejected. Two positions are neighbours when their indices differ by at most one along every axis and along at most `connectivity` axes, an integer from 1 to the rank.

`wrap` says whether the first and last index of an axis are neighbours, as one flag or one per axis. Values outside those raise `ValueError`, as does a negative or non-integer count. Any sparse class is acceptable. Results shaped like the input are sparse; the per-region summaries are numpy arrays. An array with no axes is rejected. Positions vastly outnumber cells, and cells reach the hundreds of thousands, so no routine may densify.

`label(x, connectivity=1, wrap=False, equal_values=False)` returns an array holding the region number of every cell and zero elsewhere, plus the count. Regions are numbered from one by first cell in row major order. With `equal_values` neighbouring cells join only when their values match. A labelling must hold integers using every number from one to the largest; anything else is rejected.

`region_counts(labels)` gives cells per region. `region_sums(x, labels)` totals their values in the dtype numpy sums `x` in. `region_maxima(x, labels)` returns the largest value of every region and a `(count, rank)` array of the first position holding it in row major order. A routine taking `x` and a labelling needs them to agree on shape and cells.

`region_bounds(labels, wrap=False)` returns a `(count, rank, 2)` array of, per region and axis, the first index and length of the shortest covering window, which on a wrapped axis may cross the end into the start; the smallest first index wins ties. `region_centroids(labels, wrap=False)` averages the positions into a `(count, rank)` array, measuring them on a wrapped axis from that window start and wrapping the mean back.

`region_perimeters(labels, ...)` counts distinct pairs of a cell and a neighbouring non-cell, counting one off a non-wrapping end too. `region_adjacency(labels, ...)` lists the pairs of distinct regions holding neighbouring cells as a `(k, 2)` array, smaller number first, sorted.

`dilate(x, ..., iterations=1)` returns a boolean array true at every position within `iterations` steps of a cell. `erode` returns one true at every cell keeping all neighbours through `iterations` rounds, a position off a non-wrapping end never being a cell. `border_distance(x, ...)` holds the integer steps from each cell to the nearest non-cell, one for a cell beside one, raising `ValueError` when full wrapping leaves none.

`grow_labels(labels, ..., iterations=1)` hands every position within `iterations` steps to the nearest region, ties to the smaller number, and returns the widened labelling, count unchanged. `merge_within(labels, distance, ...)` puts two regions in one when a cell of each lies within `distance` steps of the other, transitively, and renumbers by the same rule. `filter_regions(labels, min_count=1)` drops regions with fewer cells, numbers the rest again by the same rule, and reports the survivors.
