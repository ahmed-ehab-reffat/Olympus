# DESIGN — laspy dataset assembly

## 1. Title
Add dataset assembly operations to laspy (merge, partition, thin, summarize).

## 2. Host repo
[laspy/laspy](https://github.com/laspy/laspy) @ `b4e14088d24e7e23f72fd9d33d61f63a9668cb74`
505 stars, BSD (2-clause), pure Python + numpy, 17.5k LOC, 17 source commits in the trailing
12 months (latest 2026-05-30). Vanilla suite measured inside `olympus-base-python`:
**854 passed / 24 skipped in 12.9 s** offline. No prior submission of ours touches LiDAR or
point clouds.

Gates: stars OK, BSD OK, Python primary OK, active OK, deterministic suite OK, quota OK (0 subs).
Exclusivity swept (`tile`, `merge`, `thin`, `voxel`, `decimate`, `index`, `quadtree`, `grid`,
`downsample`, `split file`) across PRs + issues, all states, plus all 15 branches: nothing
implements dataset assembly. Issue #95 ("Spatial Indexing") asks for a COPC-style *query* index,
which this feature does not provide.

Known risk, recorded honestly: issue #203 ("Converting las to tif") was closed by the maintainer
with "out of scope for this library ... use PDAL". That decline is about writing raster products.
This feature stays inside the file/dataset domain the CLI already occupies (`convert`, `compress`,
`info`), so it is not the declined class, but it is adjacent.

## 3. Shape
O-Composite-add: one shared kernel (integer-space grid + subset rebuild) feeding six public
entry points, with the merge path adding genuinely new machinery (scaling resolution, extra
dimension union, VLR reconciliation).

## 4. Public API

```
laspy.merge_datasets(datasets, *, scales=None, offsets=None, point_format_id=None,
                     file_version=None) -> LasData
laspy.partition(data, *, cell_size, origin=(0.0, 0.0), buffer=0.0, min_points=1,
                max_points=None) -> list[Partition]
laspy.crop(data, bounds) -> LasData
laspy.thin(data, spacing, *, keep="first") -> LasData
laspy.split_by(data, dimension) -> dict[value, LasData]
laspy.summarize(data) -> DatasetSummary
```

`Partition`: `key` (level, col, row), `bounds` (min_x, min_y, max_x, max_y), `core_count`, `data`.
`DatasetSummary`: `point_count`, `bounds`, `counts_by_classification`, `counts_by_return`,
`gps_time_span`, `extra_dimensions`, `density`, `as_dict()`.

## 5. Canonical semantics (the contract)

Everything that decides membership works on the **stored int32 coordinates**, never on the
scaled floats. World values are converted with laspy's own rule
`X = np.round((x - offset) / scale)` (nearest integer, halfway to even).

- **merge_datasets** — target point format = the largest id among the inputs unless given; target
  version = the largest among the inputs, raised if the format requires it. Target scales default
  to the element-wise minimum of the input scales; target offsets default to the element-wise
  minimum world coordinate actually present. Every point is requantized to that scaling; a value
  outside the int32 range raises `LaspyException`. Extra dimensions are unioned in first-appearance
  order, a repeated name with a different type raises, absent values are zero. VLRs: the first
  dataset's, then any later (user id, record id) not already present; the ExtraBytes VLR is always
  regenerated. Mixed GPS time types raise. Points keep input order.
- **partition** — cell size and origin are converted to integer steps `S = round(cell_size / scale)`
  (per axis) and `O = round((origin - offset) / scale)`; the cell of a point is
  `floor((X - O) / S)` by integer division, so the lower edge belongs to the cell. `buffer` becomes
  an integer margin `B`; points outside a cell but within `B` of it are appended after the core
  points with `synthetic` set to True. `min_points` filters on the **core** count. With `max_points`,
  a cell over budget halves into quadrants for as long as both integer steps stay even, and the key
  grows a subdivision level. Result sorted by (level, col, row).
- **crop** — half-open `lo <= X < hi` in integer space, 4 or 6 bound values.
- **thin** — voxel index `X // S` per axis with `S = round(spacing / scale)`; `keep` selects
  `"first"`, `"last"`, `"lowest"` (smallest Z) or `"highest"` (largest Z), ties by earliest index.
  Output keeps original relative order.
- **split_by** — groups by a dimension value, keys ascending, order preserved within a group.
- **summarize** — counts by classification and return number, GPS span, extra dimension names,
  density = points / bounding-box area (None when the area is zero).

Every returned dataset carries a header whose point count, bounds and
`number_of_points_by_return` are recomputed from the points it actually holds.

## 6. Traps (interdependent, misdirecting)

1. **Integer vs float membership.** `floor(x / cell_size)` on the scaled floats misassigns points
   whose stored integer divides evenly (0.3 / 0.1 = 2.9999999999999996, the stored 30 // 10 is 3).
   Surfaces as a point in the wrong tile, not as an arithmetic error. The same float slip hits the
   step conversion itself (0.29 / 0.01 = 28.999999999999996).
2. **Requantization rounding.** Merging different scales needs `np.round` half-to-even; `int()`
   truncation diverges for negatives only, so small fixtures pass and signed ones fail.
3. **Buffer interaction.** Buffer points must not count toward `min_points`, must be flagged, and
   must not disturb `number_of_points_by_return` correctness — the same header rebuild that trap 1
   feeds.
4. **Extra dimension union.** A dataset missing a dimension contributes zeros, and one name with
   two types must raise. (Filtering the source ExtraBytes VLR turned out to be unobservable: laspy
   strips it on every `header.vlrs` assignment, so that helper was deleted as dead code.)
5. **Offset default.** Offsets default to the minimum coordinate actually present, which changes
   the integer values and therefore every later grid decision.
6. **Budget subdivision.** Splitting at exactly `max_points`, or past an odd stored size, changes
   the whole key set of the result.
7. **Tie-breaking in thin.** "lowest" with equal Z must fall back to the earliest index, and the
   surviving points keep input order rather than voxel order.

## 7. File footprint (target)

| file | role |
|---|---|
| `laspy/assembly/__init__.py` | exports |
| `laspy/assembly/grid.py` | integer-space conversion, cell math, bounds |
| `laspy/assembly/merge.py` | scaling resolution, format/version, extra dims, VLRs |
| `laspy/assembly/partition.py` | partition, crop, Partition |
| `laspy/assembly/reduce.py` | thin, split_by |
| `laspy/assembly/summary.py` | summarize, DatasetSummary |
| `laspy/__init__.py` | top-level exports |

Measured: 735 raw / 472 human-effective LOC over 7 files.

## 8. Tests

New file `tests/test_assembly_<hex>.py`, four blocks: builders (in-memory LasData factories),
assertions helpers, per-entry-point tests, cross-operation invariants (partition then merge
round-trips, crop of the full extent is identity, thin is idempotent, summarize agrees with the
header).

## 9. Tier
Olympus. Pass band target <= 40%.
