# DESIGN.md — verde-tiled-gridding

## 1. Title

Add tiled gridding with tapered blending to the interpolators

## 2. Shape classification

- Shape: **O-Composite-add** (new capability spanning coordinates -> tiling kernel -> gridder base class -> public API), with an O-Algorithm-correctness core (the taper/partition-of-unity kernel).
- Pass rate target: <= 40% (sprint cap), designed for the 10-20% band.
- Best agent: Mixed (Orion/Vega).
- Dominant verdict expected: MISSED_REQUIREMENT (taper band width, internal-edge rule, split-then-drop ordering).

## 3. Public API surface

- `verde.tile_regions(region, shape=None, spacing=None, overlap=0.0, adjust="spacing")` -> list of `[W, E, S, N]` tiles.
- `verde.taper_weights(coordinates, tile, margin, region=None)` -> array of weights in [0, 1].
- `verde.merge_grids(grids)` -> merged `xarray.DataArray`.
- `verde.TiledGridder(estimator, shape=None, spacing=None, overlap=0.25, min_data=10, max_data=None, max_depth=3, region=None, blend="taper")`
  - `fit(coordinates, data, weights=None)` -> self
  - `predict(coordinates)` -> array
  - `tile_report()` -> `pandas.DataFrame`
  - attributes `region_`, `tiles_`, `estimators_`
- Inherited from `BaseGridder`: `grid`, `scatter`, `profile`, `score`.

## 4. Canonical output form

- Tile order: sorted by south edge, then by west edge (both ascending). `tile_regions` emits the same order.
- Tile bounds: base tiles divide the region into equal parts; a tile is extended by `overlap` times its base size on every side that borders another tile, never on a side lying on the region boundary.
- `spacing` -> number of tiles = ceil(extent / spacing), at least one; tiles stay equal sized so the effective tile size is <= spacing.
- Taper: per axis, factor = min over tapered edges of clip(distance / margin, 0, 1); the point weight is the product of the two axis factors; zero outside the tile; margin <= 0 means no taper.
- Blending: weighted average over fitted tiles that contain the point. No fitted tile -> NaN.
- `tile_report()` columns, in order: `west, east, south, north, n_data, fitted`.
- Errors: both/neither of shape and spacing; overlap outside [0, 1); every tile dropped.

## 5. Blind-spot pre-empts

- Iteration termination: "splitting stops when the tile holds at most max_data points or has been split max_depth times".
- Result ordering: tile order stated explicitly (south, then west).
- Adjacent-vs-all: taper applies only to edges shared with another tile.
- Falsy-on-invalid: uncovered prediction points are NaN, not zero.
- Default values stated for every optional parameter.

## 6. Description draft

See `meta.md`. Prose, no headers, states: tile geometry, splitting, overlap, taper band, blending, drop rule, report, errors, defaults.

## 7. File footprint

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| NEW | verde/tiling.py | 569 raw / 257 eff | taper kernel, TiledGridder, merge_grids |
| MODIFY | verde/coordinates.py | 213 raw / 62 eff | tile geometry (`tile_regions`, `grow_tile`, `shared_edges`) |
| MODIFY | verde/__init__.py | 2 raw / 2 eff | exports |

Shipped: 784 raw / **321 human-effective** across 3 files. The sprint floor is 250; verde is a
compact library with heavy docstrings, so 430 was not reachable without padding (see feedback.md).
`grow_tile` and `shared_edges` stay unexported and undescribed.

## 8. Solution outline (pure helpers)

- `_tile_bounds(region, shape)` — equal division of a region.
- `_split_tiles(coordinates, tiles, max_data, max_depth)` — recursive quadrant refinement.
- `_grow_tile(tile, region, overlap, size)` — overlap growth on internal sides only.
- `_axis_factor(coordinate, low, high, margin, taper_low, taper_high)` — the taper kernel.
- `taper_weights` — public wrapper over the axis factors.
- `TiledGridder.fit/predict/tile_report`.

## 9. Test outline

`verde/tests/test_tiling_<hash>.py`: builder helpers (synthetic linear/quadratic fields), assertion helpers, then buckets:
geometry (shape/spacing/overlap/ordering/errors), splitting (max_data/max_depth/counting rule),
taper (partition of unity, edges, margin<=0, outside), gridder (exact recovery of a linear field,
hand-computed blend, min_data drop, NaN coverage, weights passthrough, estimator cloning),
report (columns/order/values), integration (`grid`, `score`, `Chain` as the wrapped estimator).

## 10. Forced signatures

Statically-loose Python, so the contract is method-vs-function shape: `tile_report()` is a method
returning a DataFrame; `tiles_` is a list of lists; `estimators_` holds `None` for dropped tiles.
All pinned in meta.md.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt | Test |
| --- | --- | --- | --- | --- |
| 1 | Taper margin is the full overlap band (2 x overlap x base size), not the growth margin | The growth used to build the tile is the obvious scale | "across the whole width of the band it shares with its neighbour" | partition-of-unity + hand blend |
| 2 | Only edges shared with a neighbour taper | Symmetric code tapers all four | explicit sentence | corner/edge prediction of a linear field |
| 3 | Axis factors multiply (not min) | min is the natural guess for a 2D taper | explicit sentence | four-tile corner sums to one |
| 4 | Split counts base-tile points, drop counts grown-tile points | One counter feels natural | explicit sentences | split/drop interaction test |
| 5 | Dropped tiles force renormalisation; uncovered -> NaN | Assumes weights always sum to one | explicit sentence | sparse-corner test |

Traps 1-3 are interdependent: fixing the margin without the internal-edge rule moves the error to
the region border, and fixing both with `min` still fails at four-tile corners.

## 12. Tier + category

Olympus, feature-request.

## 13. Predicted pass rate

10-25%. Levers stacked: one kernel (taper/geometry) driving fit, predict, report and the public
functions; exact oracle (partition of unity + exact recovery of a linear field); three interdependent
misdirecting traps; bespoke (no published implementation of tiled blending in this domain).

## 14. Quality gate

- [x] Repo understanding (5/5): sklearn-style gridders, BaseGridder does grid/scatter/profile/score,
      coordinates.py owns region helpers, tests live in verde/tests, numpy-style docstrings with doctests.
- [x] Exclusivity: no PR/branch/issue implements tiling or blending (searched tile/tiled/window/blend/
      mosaic/merge/overlap across all states; enumerated all branches, diffed 2.0-dev, derivatives,
      rm-vector, dims-on-projection). Open PRs #440/#541 cover NaN filling only — deliberately out of scope.
- [x] Environment: vanilla suite 182 passed / 4 skipped offline (sklearn pinned < 1.9 for issue #558).
- [x] LOC: 321 human-effective, above the 250 sprint floor; the 430 target is unreachable on a library this compact without padding (documented in feedback.md).
- [x] Not pattern-followable: no meta-estimator of this kind exists in the repo.

## Why this is not a duplicate

Closest approved siblings: `sparse-region-analysis` (Task45, region labelling over sparse arrays) and
`petl-incremental-refresh` (incremental table refresh). Both are pure data-structure transforms; this
is a spatial partition + partition-of-unity blending kernel wrapping an estimator. No verde submission
exists in any local directory. Predicted iteration cycles: 2.
