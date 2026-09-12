# eval-results — laspy-dataset-assembly

Repo: [laspy/laspy](https://github.com/laspy/laspy) @ `b4e14088d24e7e23f72fd9d33d61f63a9668cb74`
Image: `olympus-base-python` + `COPY . .` + pinned numpy 2.5.2, pytest 9.0.3, lazrs 0.8.2,
hatchling 1.32.0 + editables 0.5 (removed after use), then `pip install --no-build-isolation --no-deps -e .`;
container start measured at 0.8-1.4 s

## Local validation (2026-08-11)

| check | result |
|---|---|
| vanilla suite, no patches | 854 passed / 24 skipped / 0 failed (~14 s) |
| test.patch only, `new` mode | 205 failed / 0 errors (every new test is F2P) |
| test.patch only, `base` mode | 854 passed / 24 skipped |
| both patches, `new` mode | 205 passed, x5 identical |
| both patches, `base` mode | 854 passed / 24 skipped, x5 identical |
| apply order test then solution | green |
| apply order solution then test | green |
| network | `--network none` throughout |
| image built from the repo build context | vanilla suite 854 passed / 24 skipped |
| mutation battery | 35 / 35 killed |
| solution size | 738 raw / 474 human-effective LOC, 7 files |
| meta | 498 words, ASCII, no paragraph over 150 words |

## Agent runs

### Batch 1 (2026-08-11) - 0 / 6 PASS, UNSOLVABLE, artifacts in `Task50/agent-runs(12)/`

| agent | verdict | baseline | failed | failed tests | root cause |
|---|---|---|---|---|---|
| Nova_1 | fail | pass | 8 | buffer family (4), split bounds, explicit version, crop degenerate | reused the base cell's upper bound for every final cell |
| Nova_2 | fail | pass | 2 | upper buffer edge, crop degenerate | half-open buffer top, crop validated after quantization |
| Nova_3 | fail | pass | 19 | crop/thin/split family, version, buffer | `record.copy()` returns a PackedPointRecord, losing the scale-aware x/y/z |
| Nova_4 | fail | pass | 8 | version, evlr legacy, buffer, crop x2, thin empty | mixed |
| Nova_5 | fail | pass | 4 | version, extra dim definitions x2, buffer | writes scaled zeros into every extra dimension |
| Vega | fail | pass | 2 | upper buffer edge, thin empty | half-open buffer top; empty index hits laspy's name-list branch |

Shared failures, which is the prompt-bug signal:

| failing test | runs |
|---|---|
| `..._buffer_..._upper_margin_edge` (plus Nova_1's whole buffer family) | 6 / 6 |
| `test_merge_incompatible_version_raises` | 4 / 6 |
| `test_crop_bounds_inside_one_stored_unit_keep_nothing` | 4 / 6 |
| `test_thin_empty_dataset` | 3 / 6 |

### Replay of the same six patches against the corrected suite

| agent | batch 1 | after the fixes (192 tests, FP closed) |
|---|---|---|
| Nova_1 | 8 failed | 11 failed |
| Nova_2 | 2 failed | 2 failed - the crop sub-resolution FP defect |
| Nova_3 | 19 failed | 19 failed |
| Nova_4 | 8 failed | 7 failed |
| Nova_5 | 4 failed | 3 failed |
| Vega | 2 failed | passed 196 / 196 before the hardening round; now fails only the 7 newly added tests |

**Solvable: 1 / 6 = 17%**, measured by replay, with the FP panel's two defects now caught by tests
and proved by two extra mutations (31 / 31).

## Expected failure surfaces

Ranked by how likely a solver is to miss them:

1. Cell and voxel membership computed on the scaled floats (`floor(0.3 / 0.1)` is 2, the stored
   integers say 3).
2. World sizes converted to stored steps by truncation (`0.29 / 0.01` is 28.999999999999996).
3. Buffer points counted toward `min_points`, or written before the core points, or left unflagged.
4. Quadrant subdivision continuing past an odd stored size, or triggering at exactly `max_points`.
5. Merge offsets taken from the input headers rather than from the smallest coordinate present.
6. Extra dimension union missing the zero fill, or the type clash not raising.
7. `thin` returning points in voxel order rather than input order, or breaking height ties by the
   last index.
