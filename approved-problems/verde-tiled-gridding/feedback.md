# feedback — verde-tiled-gridding

## Summary

Olympus submission on [fatiando/verde](https://github.com/fatiando/verde) at
`19e67c6b570384d2380c7d78cd08a85983b34d0c` (BSD-3-Clause, 665 stars, source commits through
2026-03, pure Python). Invented feature: tiled gridding with a tapered blending kernel
(`verde/tiling.py` plus tile geometry in `verde/coordinates.py`), 321 human-effective LOC over
3 files, 121 F2P tests.

## Pick trail (repos screened and why they died)

Autonomous discovery, user preference is a brand-new repo never used locally. Screened and
rejected before verde:

- **devbisme/skidl** (MIT, 1.6k) — the repo's OWN suite is broken at HEAD: 16 failures because the
  bundled KiCad 10 symbol libraries lack parts the tests use (`Q_PNP_CBE`). `test_schematic.py`
  also runs over 10 minutes. Environment gate reject.
- **donmccurdy/glTF-Transform** (MIT, 1.9k) — ava runs `.ts` tests through Node type stripping, so
  the suite needs Node 22+; the base image ships Node 20 and the monorepo would also need an
  ava-to-JUnit shim. Too much environment risk for the value.
- **movingpandas** (BSD-3, 1.4k) — the kinematics/closest-approach space I wanted is exclusivity
  dead: PR #457 publishes a complete 442-line `movingpandas/cpa.py`, and PR #320 publishes
  constant-acceleration interpolation. The maintainer also merged Frechet/DTW/LCSS distances in
  2026, so trajectory measures are a live workstream.
- **bebop/poly** (MIT, 735) — last SOURCE commit 2024-10; the 2026 commits are README and CI only.
  Recency gate reject, same shape as the avo/mun trap.
- **matt-kempster/m2c** (619) — GPL-3.0. **zxcalc/pyzx** — GitHub primary language is OpenQASM, so
  the language gate fails. **formulaic** (462) and **fluids** (449) — under the 500-star floor.
  **patsy** — recent commits are all pre-commit/dependabot. **pysheds, obspy, MultiQC, djLint,
  cobrapy, mathics** — GPL/LGPL. **zarr-python** — hypothesis property tests in the vanilla suite
  make the flakiness gate risky.

## Exclusivity (verde)

`gh pr list --state all` for tile, tiled, window, blend, mosaic, merge, overlap: no PR touches
tiling or blending. All branches enumerated and diffed (`2.0-dev`, `rm-vector`, `derivatives`,
`dims-on-projection`) — `derivatives` adds a Derivative metagridder, none add tiling. Open PRs
#440 and #541 implement NaN filling in grids, so gap filling is deliberately out of scope here.
Issue #451 ("Merge overlapping grids") is an open, unassigned request with no PR, which is what
`merge_grids` answers.

## Environment

- Vanilla suite: **182 passed, 4 skipped** offline (`--network none`, `--user 1000:1000`) in the
  built image, ~4 minutes. Verified on the VANILLA tree (Environment Quality) and again with both
  patches applied.
- `scikit-learn` is pinned below 1.9 in the Dockerfile: verde issue #558 reports that undamped
  `Spline` silently returns wrong predictions with scikit-learn >= 1.9, which fails 5 of the repo's
  own tests at HEAD.
- The sample datasets are fetched with `pooch`. The Dockerfile copies the bundled files in `data/`
  into the exact registry path (`$VERDE_DATA_DIR/v<version>`) at build time so nothing downloads at
  test time. This is the failure that a first Docker round exposed: `test.sh` had pointed
  `VERDE_DATA_DIR` at `data/` itself, and pooch appends a version directory, so 6 dataset tests
  went to the network.
- Determinism: base 3x identical (182/4), new 3x identical (86).

## Difficulty design

One kernel (tile geometry plus the linear taper) drives four surfaces: `tile_regions`,
`taper_weights`, `TiledGridder.fit/predict`, and `merge_grids`. The interdependent traps are

1. the taper margin is the WHOLE band shared with the neighbour, which is twice the amount each
   tile was extended by;
2. only edges shared with a neighbour taper, so a tile touching the region boundary keeps full
   weight there;
3. the two direction factors MULTIPLY, which is what makes the weights of four tiles meeting at a
   corner sum to one;
4. the split rule counts points in the tile BEFORE it is extended while the drop rule counts them
   after, so one counter gives the wrong tile set;
5. dropped tiles break the partition of unity, so predictions must renormalise.

Fixing 1 without 2 moves the error to the region border, and fixing both with `min` instead of a
product still fails at four-tile corners.

## Mutation battery

18 mutations of the reference, all killed after two rounds of test hardening
(`/tmp/mutate_verde.py`). The first round left 5 survivors, each of which exposed a real hole:

- `split-threshold-off-by-one` — no test had a tile sitting exactly at `max_data`.
- `no-normalisation` — every blend test had weights summing to exactly one, so dividing by the sum
  was invisible. Added a case with a dropped tile where the weights sum to 0.7.
- `nearest-ties-to-later` — the tie test used two mirror-image tiles of a symmetric field, whose
  linear fits agree exactly at the tie point. Rebuilt with 3 tiles so the two candidates differ.
- `merge-margin-full-size` — doubling every margin cancels in the normalised average unless one
  weight is clipped at one, so the test now probes a point where the west grid is clipped.
- `merge-ignores-nan` — the NaN cell sat on a grid edge where the weight was zero anyway.

## Deviations and open items

- **Effective LOC is 321, not the 430 the skill's hook targets.** The sprint floor is 250
  human-effective and this clears it by 29%. verde is a compact library (~6.7k lines total, heavy
  NumPy-style docstrings that the reviewer strips), so a 430-effective feature would be a fifth of
  the library's entire logic. Scope was raised twice for this reason (multi-component data, an
  explicit `region`, the `nearest` blend mode, `adjust="region"`, and `merge_grids`), each a real
  behaviour with its own tests, never padding. Cutting either `merge_grids` or the blend modes to
  shorten the description would drop the count to ~250.
- **meta.md is 497 words** against the recommended 200 and the hard cap of 500. The API is
  explicit (4 public names, 9 constructor parameters, 6 report columns), and every clause is
  tested; trimming further would delete a tested behaviour. Precedent: approved 236-word and
  309-word descriptions.
- `grow_tile` and `shared_edges` exist in `verde/coordinates.py` but are deliberately NOT exported
  and NOT described, so no test touches them: undocumented public API is a hidden requirement.

## Round 6 — alignment check (platform, FAILED once)

The "problem and tests are aligned" check flagged one ERROR and two warnings, all on the same
theme: the tests knew more about the interface than the description did.

- ERROR: 15 error tests asserted a SUBSTRING of the `ValueError` message ("not both", "adjust",
  "overlap", "spacing", "shape", "Invalid region", "blend", "min_data", "at least one", "lattice",
  "dimensions"). Nothing in the description names those words, so the messages were a hidden
  requirement. Fixed on the TEST side: `expect_error` now only asserts that `ValueError` is raised,
  which is the behaviour the description does state. Relaxing beats adding 60 words of message
  spec, and the tests still fail on base (an `AttributeError` is not caught by the `raises` block).
- WARNING: `tile_regions(spacing=...)` and `taper_weights(margin=...)` accept a scalar or a
  (north, east) pair and the tests use pairs. Stated in the description.
- WARNING: `adjust` has no effect when `shape` is given. Stated in the description.

Re-verified afterwards: 86 tests pass with the solution, 86 fail on base with per-test nodes and no
collection error, the container run is green offline, and the 18-mutation battery still has zero
survivors. meta.md is 493 words.

## Round 7 — Test Fairness (platform, FAILED once: 3 of 89)

Two genuine spec gaps, both fixed in the DESCRIPTION rather than by weakening assertions:

- `test_tile_regions_large_overlap_error` pinned `overlap=1` as invalid while the prompt said
  "outside zero to one", which reads as closed. The range is genuinely half open (an overlap of one
  makes a tile swallow its neighbour), so the prompt now says "an overlap below zero or of one or
  more". Added a test at 1.5 as well, per the coverage suggestion.
- Two assertions required `n_data` to be the POST-extension count while the prompt introduces both
  a pre-extension count (splitting) and a post-extension count (min_data) and assigned neither to
  the report. The column is now defined in the prompt: `"n_data"` (the points its extended bounds
  hold).

Coverage suggestions all taken: negative spacing, a zero east axis in the shape, overlap above one,
`TiledGridder.fit` with both and with neither of shape and spacing, `max_depth=0`, and a split whose
points sit on child boundaries. That last one asserts only the split count and full coverage, not
the per-tile counts, so it does not pin the boundary-membership rule the prompt leaves to
`verde.inside`.

Re-verified: 93 tests, all passing with the solution and all 93 failing on base with per-test nodes
and no collection error; container run green offline in both modes; 18-mutation battery still has
zero survivors. meta.md is 497 words.

## Round 8 — Test Fairness coverage suggestions (advisory, all taken)

All four suggestions cover behaviour the prompt already states, so they add coverage without adding
a requirement:

- region-boundary suppression on the north, east and south edges plus a tile matching the whole
  region (the earlier exact test only exercised the west boundary);
- multi-component fitting with a DISTINCT weight array per component, each with its own outlier, so
  a solution that forwards only the first weights array fails;
- `tile_regions` with a (north, east) spacing pair under `adjust="region"`, which checks the growth
  is computed per direction;
- `merge_grids` success path with non-default dimension names, checking the first grid's names and
  coordinates survive (the earlier custom-dimension test only covered rejection).

99 tests now: all pass with the solution, all 99 fail on base with per-test nodes, container run
green offline, 3 identical repeats, mutation battery still at zero survivors.

## Round 9 — second coverage round (advisory, all taken)

- `region_` is now asserted directly against the data bounding region, on scattered points and on a
  rectangular grid, instead of only implicitly.
- Two adaptive-splitting tests: the exact extended bounds of the four children (which fails any
  solution that extends before it splits, since the overlap is a fraction of the CHILD size), and a
  hand-computed blend between two neighbouring children over their own band.
- `merge_grids` now rejects a grid whose own coordinates have no single spacing, not just two grids
  whose spacings differ.

104 tests: all pass with the solution, all 104 fail on base with per-test nodes, 3 identical
container repeats, mutation battery still clean.

## Round 10 — Test Fairness (1 of 104, fixed without touching the prompt)

`test_tiled_gridder_nearest_tie_goes_to_the_earlier_tile` was the only flag: the prompt says
"the containing tile whose centre is closest" without saying whether the centre is that of the
extended tile or of the original equal tile, and my tie point (3.1875, from a 3-tile layout) was a
tie only under the extended reading.

Rather than spend words pinning one reading, the test now uses a layout where BOTH readings give the
same answer: 4 tiles over `[0, 8]`, where the two middle tiles have centres 3.0 and 5.0 whether
measured before or after extension, so `easting=4` is a tie either way. The field carries a cubic
term so the two candidate fits differ there (73.479 versus 71.604) — the earlier tile must win.
Mirror-image tiles of a purely quadratic field would have made the two fits agree at the tie point
and the assertion vacuous, which is the same trap the mutation battery caught in round 4.

Re-verified: 104 tests pass with the solution, all 104 fail on base with per-test nodes, base mode
182/4 in the container offline, 3 identical repeats, mutation battery clean.

## Round 11 — coverage suggestions (one taken, one declined)

- **Merge axis ordering: TAKEN, and it was a real bug.** A grid with descending coordinates (the
  normal layout for latitude in raster data) crashed inside `merge_grids` with an opaque numpy
  message, "zero-size array to reduction operation minimum": the union lattice was built as
  `start + spacing * arange(size)` with a negative spacing, so `size` came out negative. Descending
  axes are now rejected with a clear error, the prompt says coordinates must rise by the same
  spacing, and two tests cover a descending easting and a descending northing.
- **Validation of `min_data` / `max_data` / negative `max_depth`: DECLINED.** The reviewer's own
  note is that the prompt does not specify those error semantics, so adding the tests without a
  prompt clause would recreate exactly the hidden-requirement class that failed rounds 6 and 10.
  meta.md sits at 498 of the 500-word cap, and buying ~12 words for guard clauses would cost a
  clause that carries real difficulty. The reference still refuses `max_data < 1` and
  `max_depth < 0`, it is simply not part of the contract.

106 tests, 787 raw / 323 human-effective LOC. All pass with the solution, all 106 fail on base with
per-test nodes, base mode 182/4 offline in the container, 3 identical repeats, mutation battery
clean.

## Round 12 — Test Fairness (3 of 108, one root cause)

All three flags were the same gap: three tests assert `tile_report()["fitted"]` holds exact
booleans, while the prompt only named the column. Nothing in verde produces a comparable report, so
a solver could reasonably have written status strings or the estimator objects themselves. Fixed in
the prompt, which now says the report carries "the boolean `fitted`". Three words, and the
assertions become contract checks.

Coverage suggestions, all four taken:

- `blend="nearest"` returns NaN outside every fitted tile (the uncovered-point tests had only
  exercised the taper mode);
- multi-component prediction returns a tuple whose entries are each NaN at an uncovered point;
- a negative shape component on either axis is refused (only zero had been covered);
- a lattice point where EVERY covering grid is missing merges to NaN. The prompt's closing rule was
  "NaN when no grid covers them", which does not decide the all-missing case, so it now reads "NaN
  where no value is available" — same length, and it covers both.

110 tests, meta.md at 499 words. All pass with the solution, all 110 fail on base with per-test
nodes, 3 identical container repeats, mutation battery clean.

## Round 13 — coverage suggestions (two taken, one adapted)

- **Direct weight forwarding: TAKEN.** A `TiledRecorder` gridder (a `BaseGridder` subclass that
  appends every fit's arrays to a class attribute, so `sklearn.clone` cannot deep-copy the log away)
  now proves each tile estimator receives exactly the coordinates, data and weights of the points
  that tile holds, compared as sorted `(easting, northing, value, weight)` tuples rather than by
  container type or order. A second case asserts no weights are forwarded when the fit had none.
  This strengthened the battery: the `weights-dropped` mutation now fails 3 tests instead of 1.
- **Estimator placeholders: TAKEN.** `estimators_` is now asserted to hold None in exactly the
  skipped positions, instead of inferring it through the report and the predictions.
- **Adjusted-region integration: ADAPTED.** `TiledGridder` has no `adjust` parameter — its
  constructor is fully enumerated in the prompt and `tile_regions` is called with the default. The
  useful version of the check is the opposite one, so the new test uses a spacing that does not
  divide the region and asserts `region_` stays at the data bounds, the first tile is shrunk to
  `[0,5,0,5]`, and every point is still covered. That catches a solution that forwards
  `adjust="region"` or pads the region.

114 tests. All pass with the solution, all 114 fail on base with per-test nodes, 3 identical
container repeats, mutation battery clean.

## Round 14 — Test Fairness (1 of 119)

The recording test zipped `TiledRecorder.calls` (the temporal order of the `fit` calls) against
`tiles_` (the stored order). Only the stored order is in the contract, so a solution that fitted
tiles in reverse, or in parallel, would have failed on an ordering nobody promised.

Fixed by comparing the two collections as order-independent sets of content signatures: each call
and each tile becomes a sorted list of `(easting, northing, value, weight)` tuples, and the sorted
lists of those signatures must match. Per-call exactness is unchanged, but the temporal order is
free. Proved it by mutating the reference to fit tiles in reverse: the recorder test still passes,
while the mutation battery still fails everything it failed before.

Also took the advisory: `tile_report()["fitted"]` is now asserted to have a boolean dtype, which the
prompt states since round 12.

114 tests, all passing with the solution, all 114 failing on base with per-test nodes, 3 identical
container repeats, 18 mutations still all killed.

## Round 15 — Test Fairness (1 of 114) and coverage

`test_tiled_gridder_predictions_are_continuous` asserted `max(abs(diff)) < 0.5` across a seam. The
0.5 was mine: the prompt fixes the blending formula, not a smoothness bound. Replaced with
`test_tiled_gridder_blends_along_the_whole_band`, which walks 21 points across the band and requires
each one to equal the weighted average of the two independently fitted tiles, with weights computed
inline from the stated ramp (`clip((6.25 - x)/2.5, 0, 1)` and its mirror). No magic number, and it
is strictly stronger than the old smoothness bound.

Coverage suggestions, two taken and one declined:

- nearest mode where the geometrically closest tile was skipped: the prediction must come from the
  closest FITTED containing tile. Added, with the tile geometry and the skip both asserted so the
  scenario is provably the intended one.
- merge grids whose north and east spacings differ from each other: added, checking per-direction
  lattice validation, the union along both axes, and a blended value.
- non-`DataArray` inputs to `merge_grids`: DECLINED. The prompt does not say what happens, and the
  reference raises whatever xarray attribute access raises. Asserting `ValueError` would need both
  a guard clause and prompt words, and meta.md is at 499 of 500.

116 tests. All pass with the solution, all 116 fail on base with per-test nodes, 3 identical
container repeats, mutation battery clean.

## Round 16 — Test Fairness (1 of 116) and coverage

`test_tiled_gridder_invalid_blend` pinned a rejection the prompt never stated: the error list covered
the tile arguments but not an unknown `blend`. The prompt now reads "an unknown `adjust` or
`blend`", paid for by dropping "when None" from the region sentence (the signature already shows the
default). Still 499 words.

Coverage suggestions, three taken and one declined:

- **Adaptive mixed-depth blending.** The best of the batch. A dense west half splits into four
  quadrants while the sparse east half stays one large tile, so neighbouring tiles have DIFFERENT
  band widths (1.0 against 2.0) and the taper weights no longer sum to one. The test pins the two
  tile geometries and the hand-computed normalised blend at a point they share. Nothing else in the
  suite exercised unequal neighbours.
- **Directional taper disabling.** A margin pair with one zero component, both ways round.
- **Two-dimensional merge.** Grids offset in BOTH directions, so the north and east factors must be
  multiplied; includes a NaN inside the overlap that forces the zero-weight fallback at that corner.
- **TiledGridder parameter validation: DECLINED** for the third time. The suggestion itself is
  conditioned on "if the prompt is amended"; it is not, and there is no room to amend it.

119 tests. All pass with the solution, all 119 fail on base with per-test nodes, 3 identical
container repeats, mutation battery clean.

## Round 17 — Test Fairness (1 of 122); the blend clause cleared

The `invalid_blend` flag from round 16 is gone now that the prompt names `blend` in the error list.

New flag: `test_tiled_gridder_blends_tiles_of_different_sizes` located its two tiles by INDEX
(`tiles_[1]`, `tiles_[2]`). The prompt states the order `tile_regions` emits, but nothing states how
leaves are ordered once some parents split and others do not, so a depth-first implementation would
place the west children before the unsplit east tile and fail. Fixed on the test side, per the
reviewer's own option: the tiles are now located by bounds (`any(np.allclose(...))`), so only their
existence and the blend are pinned.

Hardened the sibling `test_tiled_gridder_children_are_extended_after_splitting` the same way — it
compared the four children as an ordered list, which only passed because a depth-first quadrant walk
happens to coincide with south-then-west for a uniform split. It now sorts both sides. Proved both
by deleting the sort from the reference so it emits tiles depth-first: both tests still pass, while
the mutation battery still kills everything.

Also took the second suggestion: `TiledGridder.fit` now has direct tests that an out-of-range
overlap (1.0 and -0.5) and an invalid shape or spacing are refused at fit time, not only through
`tile_regions`.

121 tests. All pass with the solution, all 121 fail on base with per-test nodes, 3 identical
container repeats, mutation battery clean.

## Round 18 — Test Quality + Alignment (both WARNING, no FAIL)

Three advisory items, two acted on:

- **Validation timing (Test Quality W3).** Five error tests constructed the gridder OUTSIDE the
  `pytest.raises` block, so a solution validating in `__init__` would have blown up before the
  assertion instead of satisfying it. Each now builds and fits inside one lambda, accepting either
  timing. Proved it by moving the reference's checks into `__init__`: those 9 tests still pass. The
  reference keeps validating in `fit`, which is what sklearn requires of a cloneable estimator.
- **Per-tile fit window (Alignment W1).** The prompt said tiles are extended and that weights reach
  each estimator, but never that the fit window IS the extended tile. The recorder test compares
  those arrays exactly, so the prompt now says "Each estimator sees only the points its tile holds,
  with their data weights". Paid for by deleting the opening framing sentence, which the
  description rules call for anyway ("drop the reader directly into the change"). 497 words.
- **`taper_weights` shape + tile validation (Alignment W2): NOT TAKEN.** Both are already accepted
  as repo-discoverable by Test Fairness (numpy broadcasting, and `check_region` raising on W>E, which
  every region-taking verde function calls). Spending ~12 of the 3 remaining words there would have
  cost a clause that carries actual difficulty.

121 tests, unchanged in count. All pass with the solution, all 121 fail on base with per-test nodes,
3 identical container repeats, mutation battery clean.

## Round 19 — Test Fairness (2 of 121, one root cause, two words)

Both flags were the same ambiguity: does a point sitting exactly on a touching tile edge belong to
both tiles? `test_tiled_gridder_no_overlap_uses_a_single_tile` implies the west tile trains on
easting 5, and the recorder test requires that point in BOTH calls. The prompt said "the points its
tile holds" without defining "holds" at the edge, and the repository cannot settle it: the `inside`
docstring at `verde/coordinates.py:772` says boundary points count as outside while the code two
lines down uses `>=` and `<=`. A half-open ownership rule was equally defensible and would change
both fitted subsets.

Fixed with two words in the prompt: "Each estimator sees only the points its tile holds, edges
included, with their data weights." That also settles the `n_data` duplicate-count assertion, which
rests on the same rule and had only been passing as repo-discoverable.

Did NOT fix the upstream docstring typo. Correcting `inside`'s "outsize"/outside wording would be a
drive-by edit to a function this feature only calls, and the reject list names drive-by refactors
explicitly. Stating the rule in the prompt removes the dependency on that docstring entirely.

meta.md 499 words. No test or solution change, so the round-18 validation still stands: 121 tests,
all failing on base with per-test nodes, all passing in the container offline, mutation battery
clean.

## Round 20 — Test Fairness (1 of 122), word-neutral wording fix

The edge-inclusion clause from round 19 cleared both of its flags. The remaining one is the
unequal-size blend: for tiles of DIFFERENT sizes, "the band each shares with a neighbour" can be
read as the geometric intersection (width 1.5 in that setup) instead of each tile's own band (1.0
and 2.0). For equal neighbours the two readings coincide, which is why only the mixed-depth test was
ever flagged.

Fixed by naming the margin instead of the band, at exactly the same word count (13 -> 13):
"weighted by their taper weights, each tile's margin being twice its own extension." The extension
is already defined two paragraphs earlier as `overlap` times the tile's own size, so the margin is
now arithmetic rather than geometry, and the partition-of-unity case is unchanged because for equal
tiles twice the extension IS the shared band.

Verified the reference matches the stated rule on both layouts: every equal tiling has
band == 2 x overlap x own size, and the flagged pair gives east bands 1.0 and 2.0 exactly as the
test asserts.

meta.md 499 words. No test or solution change; the round-18 validation still stands.

## Round 21 — Test Quality (WARNING, both items taken)

- **Misfiled error clause.** Round 16 bolted "or `blend`" onto the error list at the end of the
  `tile_regions` paragraph, but `blend` is a `TiledGridder` parameter. Moved: the tile_regions list
  is back to its own arguments, and the blend paragraph now ends "ties going to the earlier tile;
  other values are errors."
- **`grid()` interface.** The tests call the inherited `grid`, which Test Fairness had accepted as
  repo-discoverable (BaseGridder is how every verde gridder works). Now stated outright:
  `TiledGridder` "is a `BaseGridder` that fits an independent copy of `estimator` per tile". Three
  words buy `grid`, `scatter`, `profile` and `score` for free, and confirmed the reference really is
  a subclass exposing all four.

Both cost words, so trimmed six places that carry no behaviour ("never on a region boundary",
"edges on `region`'s boundary", semicolons for conjunctions). 496 words, five paragraphs, longest
134. No test or solution change; round-18 validation stands.

## Attempt history

- R1 design: tiled gridder plus taper kernel. Landed 198 effective LOC.
- R2 scope: multi-component data, `region`, `blend="nearest"`, `adjust="region"` -> 261.
- R3 scope: `merge_grids` sharing the taper kernel -> 321 effective, 3 files.
- R4 tests: 88 written, 7 dropped with the un-exported helpers, 5 added from mutation survivors
  -> 86, all failing on base with per-test nodes and no collection error.
- R5 Docker: 3 rounds (setuptools_scm pretend version, pooch registry path, stale test.patch).
