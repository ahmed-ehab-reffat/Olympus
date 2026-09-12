# DESIGN — sparse-region-analysis

## 1. Title

Add connected region analysis for sparse arrays

## 2. Target

- Repo: [pydata/sparse](https://github.com/pydata/sparse) (canonical slug confirmed, no redirect)
- Stars 666, SPDX `BSD-3-Clause`, primary language Python, latest commit 2026-08-03
- BASE_COMMIT `99b89dfcf9bc7d34ec81e2add5556d74229607c1` (= `main` HEAD at pick time)
- Tier: Olympus

## 3. Shape classification

O-Composite-add: a new `sparse.regions` namespace beside the existing array API surface,
built on two new private modules. Thirteen public entry points over one shared neighbourhood
model, so a mistake in the shared model shows up in most of them while the per-routine rules
(numbering order, window choice, tie breaking, dtype) stay independent of each other.

## 4. Why this pick clears the gates

| Gate | Evidence |
| --- | --- |
| behavioral f2p gap | No connectivity machinery of any kind exists. `sparse.__all__` covers array API arithmetic, reductions, indexing and sorting; nothing groups neighbouring cells. `sparse.regions` raises `AttributeError` on base. |
| saturation | N-d sparse arrays are a niche PyData corner, not the author-obvious host of a tooling category. The routines are named after the domain, not ported from one reference: the numbering rule, the wrapped-window rule, the tie rules and the perimeter rule are ours. |
| uniform wrap | Four separate mechanisms: the neighbour model (connectivity plus per-axis wrap), the canonical numbering, the wrapped-window geometry, and the step-by-step semantics of `iterations`. Fixing the neighbour model does not fix any of the other three. |
| LOC ceiling | Genuinely missing core, not a fix to nearly correct code. 437 human-effective across 5 files (hook measurement below). |
| cold not live | `git log` shows no commit touching connectivity, labelling or morphology. The four non-default branches (`getitem-func`, `pagerank-example`, `aws-gpu`, `ci-test-finch-tensor`) touch indexing, docs, CI and the Finch backend. |
| reproduce on base | `import sparse; sparse.regions` raises `AttributeError` on base; all 101 new tests fail there. |
| dedup | Nothing under `Aprroved/`, `problems/`, `rejected/` or any `TaskN/problems/` touches sparse arrays, connectivity or morphology. Closest neighbours are `awkward-sliding-windows` (ragged windowing, no connectivity) and `scikit-fem-hanging-nodes` (mesh constraints, no arrays). |
| exclusivity | PR and issue search over all states for `label`, `ndimage`, `morphology`, `connected components`, `dilation`, `erosion`, `neighborhood`: zero hits on the feature class. The only `connected_components` hit is a scipy interop test that calls `scipy.sparse.csgraph` on a 2-D adjacency matrix, a different operation. All branches enumerated. |
| defined behavior | Region labelling and morphology are textbook operations with no maintainer position against them, and the repo already ships the fill-value discipline (`check_zero_fill_value`) the new rules lean on. |
| no flaky repo | Vanilla suite, offline, in the image: 6090 passed, 0 failed, every run. One pre-existing xfail family (`test_reductions_float16`) draws unseeded random data and flips between xfail and xpass; `test.sh` deselects it in base mode with the reason recorded, after which three runs are byte identical. No RNG, clock or network anywhere near the new code. |
| repo quota | 0 prior submissions on this repo. 1 of 6. |

## 5. Public API surface

All of it lives in `sparse.regions`, exported as a subpackage of `sparse.numba_backend`
and re-exported by `sparse/__init__.py` beside the private module list. It deliberately
stays out of `sparse.__all__`, which `tests/test_namespace.py` pins to the array API set.

- `label(x, *, connectivity=1, wrap=False, equal_values=False) -> (COO, int)`
- `dilate(x, *, connectivity=1, wrap=False, iterations=1) -> COO`
- `erode(x, *, connectivity=1, wrap=False, iterations=1) -> COO`
- `border_distance(x, *, connectivity=1, wrap=False) -> COO`
- `grow_labels(labels, *, connectivity=1, wrap=False, iterations=1) -> (COO, int)`
- `filter_regions(labels, *, min_count=1) -> (COO, int)`
- `region_counts(labels) -> ndarray`
- `region_sums(x, labels) -> ndarray`
- `region_maxima(x, labels) -> (ndarray, ndarray)`
- `region_bounds(labels, *, wrap=False) -> ndarray`
- `region_centroids(labels, *, wrap=False) -> ndarray`
- `region_perimeters(labels, *, connectivity=1, wrap=False) -> ndarray`
- `region_adjacency(labels, *, connectivity=1, wrap=False) -> ndarray`

## 6. Canonical output form

- A **labelling** is a sparse array of the input shape, integer dtype, fill value 0, holding
  the region number of every cell. Numbers run 1..count, assigned in the order of the first
  cell of each region taken in row major order.
- **Boolean results** (`dilate`, `erode`) are sparse arrays with fill value False.
- **Per-region results** are 1-D arrays of length `count`, in region number order.
- **`region_bounds`** is `(count, ndim, 2)`: first index and window length per axis.
- **`region_maxima`** is a pair: values of length `count`, positions of shape `(count, ndim)`.
- **`region_adjacency`** is `(n_pairs, 2)`, smaller number first, lexicographically sorted,
  shape `(0, 2)` when empty.

Every output is exact. The only floating point is `region_centroids`, and its test values are
exactly representable.

## 7. File footprint

| File | Status | raw | human-effective |
| --- | --- | --- | --- |
| `sparse/numba_backend/regions/_analysis.py` | new | 683 | 256 |
| `sparse/numba_backend/regions/_neighbors.py` | new | 476 | 137 |
| `sparse/numba_backend/regions/__init__.py` | new | 31 | 26 |
| `sparse/numba_backend/__init__.py` | modified | 1 | 1 |
| `sparse/__init__.py` | modified | 1 | 1 |
| **total** | | **1241** | **437** |

Counter 1 (platform auto-block, braces kept) is well clear; Counter 2 is the 437 above,
measured with `.claude/hooks/effective_loc_check.py`.

## 8. Solution outline

`_neighbors.py` holds the shared model: argument validation, the step set for a connectivity,
row major linear indices, one stepping routine that either wraps or drops an axis, membership
lookup by binary search over sorted linear indices, neighbour pair discovery, union-find, and
the numbering pass that turns components into region numbers by first cell.

`_analysis.py` holds the thirteen public routines. Everything works on coordinate columns:
`label` builds pairs and unions them, `dilate` unions shifted coordinate sets one step at a
time, `erode` and `border_distance` peel by membership tests, `grow_labels` runs a level by
level multi source expansion that takes the smallest region number on a tie, `region_bounds`
finds the widest circular gap per region and axis and reports its complement, and the
remaining routines are grouped reductions over the labelling.

## 9. Trap matrix (predicted)

| # | Trap | Why it is missed | Which routines regress |
| --- | --- | --- | --- |
| 1 | A stored value of zero is not a cell | `x.coords` is the obvious cell list, and the repo lets a COO carry explicit zeros | `label`, `region_sums`, every count |
| 2 | `iterations` repeats a one step neighbourhood | scaling the step vectors by `iterations` looks equivalent and gives a square instead of a diamond | `dilate`, `erode`, `grow_labels` |
| 3 | Positions off a non-wrapping axis are not cells | erosion feels like a neighbour count, so the array edge is easy to treat as neutral | `erode`, `border_distance`, `region_perimeters` |
| 4 | The wrapped window is the complement of the widest gap | min and max are the obvious bounds and are wrong the moment a region crosses the seam | `region_bounds`, `region_centroids` |
| 5 | Ties: smallest first index, smallest region number, first position in row major order | three separate tie rules, each invisible until a symmetric input appears | `region_bounds`, `grow_labels`, `region_maxima` |
| 6 | Numbering follows position, not component discovery | union by size plus numbering by root is the textbook shape and reorders nested regions | `label`, `filter_regions` |
| 7 | Nothing may densify | the whole suite is small enough to tempt a `todense()` fallback | two scale tests fail immediately |

Traps 2, 3 and 5 share the step machinery, so a local fix to one surfaces the next; trap 4
interacts with trap 5 through the tie rule; trap 6 is independent and only shows on nested
regions.

## 10. Test outline

263 tests in `sparse/numba_backend/tests/test_regions_1d0920.py`, no parametrisation, one
behaviour per test: labelling by rank and connectivity, numbering order, stored zeros, other
array classes, every validation error, wrap per axis and across the seam, `equal_values`,
the per-region reductions and their dtypes, window geometry with and without wrap, centroids,
perimeters, adjacency, morphology including the diamond versus square distinction, the
`border_distance` and `erode` agreement, growth tie breaking, filtering and renumbering, and
two scale tests on a `(9000, 9000, 9000)` array that no dense implementation can serve.

Negative tests assert the exception class only, never the message text, because no message
wording is stated in the description or fixed by a repo convention. The two that do match on
`zero fill value` are matching the repo's own shared validator in
`sparse/numba_backend/_utils.py`. Every negative test first exercises a valid call of the same
argument, so it cannot be satisfied by a blanket raise and it fails on base for the right
reason.

## 11. Validation performed

- Differential fuzz against an independent dense brute force oracle: 9 shapes from 1-D to 3-D,
  every connectivity, every per-axis wrap combination, 12 random densities each, all 13
  routines. 0 mismatches.
- Mutation battery of 24 probes: 23 killed outright; the one survivor is behaviour
  preserving refactors of union-find, and their combination (union by larger root plus
  numbering by root) is killed by two tests.
- False positive check: a second implementation written from meta.md alone, dense and
  structurally unrelated, passes 259 of 259 non-scale tests. The two scale tests are exactly the
  discriminator the description calls out.
- F2P: all 263 tests fail on base with `AttributeError: module 'sparse' has no attribute
  'regions'`; all pass with the solution. Both patch application orders verified.
- Repo suite with the solution applied: 6090 passed, unchanged from the vanilla baseline.

## 12. Tier and category

Olympus. Cross-module capability add with a shared invariant, 433 human-effective LOC,
5 files, 263 F2P tests.

## 13. Predicted pass rate

10 to 30 percent. The neighbour model and the plain labelling are within reach of a careful
solver; landing the wrapped window, the three tie rules, the iteration semantics and the
scale requirement together is the hard part.

## 14. Quality gate checklist

- [x] meta.md 495 words, ASCII, no em dash, every paragraph under 150 words
- [x] every tested behaviour stated in meta.md, every stated behaviour tested
- [x] test file name carries a random suffix and no banned marker
- [x] `test.sh` mode 100755 in the patch, `--output_path` JUnit XML for both modes
- [x] solution.patch touches source only
- [x] repo comment convention followed (numpy style docstrings, no inline comments)
- [x] ruff check and ruff format clean
- [x] offline, deterministic, no RNG in the new code
