# DESIGN.md — worldengine-orographic-precipitation

## 1. Title

Add prevailing winds and orographic precipitation to the climate pipeline

## 2. Shape classification

- Shape: O-Pipeline-hard (SHAPES.md § Pattern 11: a new stage threaded through an existing staged pipeline, where the new quantity is consumed by every later stage and by every serialiser). Closest approved precedent: rocketpy-propellant-slosh (one physical mode threaded through every phase of an integrator, Python, 375 eff, 1/10).
- Pass rate target: 25-40% (design to the ceiling with margin; only Orion is affordable, so the band must be measurable in a 10-run batch).
- Best agent: Orion (decisive multi-file), Nova if unlocked.
- Dominant verdict: MISSED_REQUIREMENT (integration walls) with REGRESSION on the existing serialisation tests.
- Solver/our LOC ratio: ~1.3x.

## Phase 1 — Repo understanding

**Architecture.** worldengine generates a world in two halves: `plates.world_gen` runs PyPlatec (C++ wheel) to get elevation and plate ids, adds noise, places oceans at the borders, and `generation.initialize_ocean_and_thresholds` derives the ocean mask, sea depth and the elevation thresholds (sea, plain, hill, mountain; `World.start_mountain_th()` is thresholds[2]). Then `generation.generate_world(w, step)` runs the climate pipeline in a fixed order: temperature -> precipitation -> (stop if the step is `precipitations`) erosion (rivers) -> watermap -> irrigation -> humidity -> permeability -> biome -> icecap. Every stage is a class with `is_applicable(world)` and `execute(world, seed)`, reads earlier `world.layers[...]` and writes a `Layer` / `LayerWithThresholds` / `LayerWithQuantiles` through a property setter with shape checks. Thresholds are land-only quantiles via `simulations.basic.find_threshold_f(data, pct, ocean)`. Sub-seeds are drawn once per stage from `RandomState(world.seed)` with a comment forbidding reshuffling. Three parallel persistence paths exist: protobuf (`World.proto` -> generated `protobuf/World_pb2.py`, `_to_protobuf_world` / `_from_protobuf_world`), HDF5 (`hdf5_serialization.py`), and `World.__eq__` over `__dict__` (used by the round-trip tests). `draw.py` renders each layer to a PNG via `image_io.PNGWriter`; `cli/main.py` wires generation, saving and map images per step.

**Subsystems and boundaries.** (1) `plates.py` + PyPlatec: elevation source. (2) `generation.py` + `simulations/*`: the climate pipeline. (3) `model/world.py` + `World.proto` + `hdf5_serialization.py`: the model and its two serialisers. (4) `draw.py` + `drawing_functions.py` + `image_io.py`: rendering. (5) `cli/main.py`: operations and steps.

**High-entanglement zones.** Adding a layer touches the model setter, `has_*`, both serialisers, the proto schema plus its generated module, `__eq__`, drawing and the CLI step wiring (the 2015 winds PR touched 20 files for exactly this). The precipitation field feeds humidity (weighted average), erosion (`river_sources` reads it as rainfall), hydrology (droplets), the biome cells and the precipitation map. The `Step` gate decides which stages run and which maps the CLI writes.

**Tests.** pytest, `tests/*_test.py`, unittest classes; fixtures in the sibling checkout `worldengine-data` (`tests/data/seed_28070.world`, blessed PNGs). `tests/simulation_test.py` (hand-built `World` with `Size`, `GenerationParameters`, arrays set through the setters) is the formatting template for the new tests; `tests/serialization_test.py` for round trips.

## Phase 2 — Existing-PR + publicly-solved check

Canonical org `Mindwerks/worldengine` (no redirect). Searches run 2026-09-15, PRs and issues, all states:
`wind`, `rain shadow`, `orographic`, `precipitation`, `moisture`, `humidity`, `elevation`, `prevailing`.

- PR #217 "Winds: initial winds implementation" (2015-12, OPEN, on top of #214): adds `simulations/wind.py` (101 lines, a latitude gradient of directions with noise), `set_wind_direction`, proto/hdf5 fields, a wind map. It computes a DIRECTION field only; no strength, no transport, no interaction with precipitation. One reviewer comment, never merged.
- Issue #13 "Generate winds" (2014, OPEN): maintainer resources, "direction and intensity per point". Issue #10 closed pointing at #13.
- Issue #77 (2015, CLOSED): psi29a: "I've always wanted to try to create 'real' rain shadows and work backwards from the backsides of mountains, but that requires that we also do real wind simulations". No design, no PR, no external implementation linked anywhere.
- `rain shadow`, `orographic`, `moisture`: no PR at all; only README wording PRs.
- README claims twice that precipitation considers rain shadows; `simulations/precipitation.py` never reads elevation; `erosion.py:129` mentions "wind and rainfall data" with no wind in the codebase.

Verdict: the central capability (moisture transport with orographic deposition feeding the precipitation field) is not implemented, requested or sketched anywhere. The wind-direction sub-piece overlaps #217 in footprint; the design keeps the wind field a two-component input of the moisture stage, deterministic from latitude (no noise, unlike #217), and states the whole model on worldengine nouns. Re-run PR-DIFF at submit.

## Phase 3 — Candidates

| Candidate | One-line behavior | Shape | Files | Raw LOC | Meaningful | Predicted | Verdict | Reject? |
|---|---|---|---|---|---|---|---|---|
| A. Winds + orographic precipitation (this pick) | per-row prevailing wind layer, moisture transport with wrap, deposition on climb, blended into precipitation before thresholds, both serialisers, map, step gate | O-Pipeline-hard | 9 | ~340 | ~250 | 30-45% | MISSED_REQ + REGRESSION | keep |
| B. Wind field only + map (issue #13) | latitude bands with noise, serialised, drawn | C | 6 | ~180 | ~120 | 60%+ | too easy | REJECT: exclusivity-dead (#217), pointwise, under floor |
| C. Rain shadow inside precipitation only, no wind layer | elevation-gradient rain reduction with a fixed westerly | A2 | 2 | ~90 | ~60 | 70% | uniform-wrap | REJECT: single-subsystem transform, under floor |
| D. Ocean currents modulating temperature | per-row current layer warming/cooling coasts | O-Pipeline-easy | 8 | ~300 | ~220 | 40-50% | MISSED_REQ | plausible but the currents model is invented without any README anchor; weaker fairness story |
| E. Watershed/lake accounting on the river map (issue #210) | proper lake filling and outflow | O-Algorithm | 3 | ~250 | ~180 | 20-35% | Wrong Logic | REJECT: rivers lane has open PR #270 rewriting erosion.py (exclusivity) |
| F. Seasonal temperature (two hemispheres of the year) | two temperature layers, biome uses the mean | O-Composite | 7 | ~280 | ~200 | 45-55% | REGRESSION | REJECT: doubles the model without a coupled kernel; pointwise |

Death-class guard on A: not a guard at many sites; not a single-subsystem transform (pipeline stage + model + two serialisers + drawing + CLI, with the existing round-trip tests as the S3 discriminator); hardness does not rest on withholding anything (every rule below is stated; the walls are the wrap polarity cell, the serialiser regeneration, the step gate, the threshold naming and the blend placement); not a port (no reference implementation of this model exists; the wind PR is a direction map only); the difficulty survives full statement because it is integration.

Arsenal: lead S3 (baseline preservation through the shared chokepoint: the world's `__eq__` and both round-trip tests must keep passing with a two-component layer that needs a regenerated protobuf module), S4 (the new layer is an ordinary layer: everything the model already does with layers keeps working: setters, `has_*`, equality, both serialisers, loading old files), A8 (direction polarity through the wrap seam), A5 (naive reading of the threshold names: thresholds[2] is labelled "hill" but is the mountain start that `start_mountain_th()` returns).

## 3. Public API surface

- `WindSimulation` (`worldengine/simulations/wind.py`), with `is_applicable(world)` and `execute(world, seed)` like the other stages; `WindSimulation.prevailing(height, width)` returns the `(direction, strength)` arrays from latitude alone.
- `World.wind` setter taking `(direction, strength)`; `World.wind_direction` and `World.wind_strength` getters (arrays, height x width); `World.wind_at(pos)` returns `(direction, strength)` at `(x, y)`; `World.has_wind()`.
- direction values: `1` eastward (toward increasing column index), `-1` westward.
- `transport_moisture(world)` (`worldengine/simulations/moisture.py`) returns the rain field (height x width, values in [0, 1]) for a world with elevation, ocean and wind.
- `PrecipitationSimulation.base_field(seed, world)` returns the temperature-curved noise field before the final rescaling (values in [0, 1]).
- Precipitation layer: unchanged setter and thresholds; the stored field is `rescale(base_field + rain)`.
- `draw_wind(world, target, black_and_white=False)` and `draw_wind_on_file(world, filename, black_and_white=False)` in `draw.py`.
- CLI: the precipitations and full steps write `<output_dir>/<name>_wind.png`; `info` prints ` has wind           : True/False` beside the other flags.
- Protobuf: `windDirection` (IntegerMatrix) and `windStrength` (DoubleMatrix) optional fields; HDF5: group `wind` with datasets `direction` and `strength`.

## 4. Canonical output form

- Latitude of row y: `(y + 0.5) / height` measured from the north pole; distance from the equator `u = |lat - 0.5| * 2` (0 at the equator, 1 at the poles).
- Bands per hemisphere: `u < 1/3` tropical (westward), `1/3 <= u < 2/3` middle (eastward), `u >= 2/3` polar (westward). Direction is `-1` westward, `1` eastward.
- Strength: `1 - 6 * |u - c|` with `c` the band centre (1/6, 1/2, 5/6); zero at band edges and at the equator, one at band centres. Never negative (the formula is clamped at the band edges; with the band assignment above it is already >= 0).
- Both wind arrays are per cell (height x width), constant along a row; direction is an integer array, strength a float array.
- Moisture parcel per row: ocean cell: `m += (1 - m) * s`, rain 0. Land cell: `climb = max(0, e_here - e_prev) / (mountain_start - sea_level)` with `e_prev` the elevation of the cell the parcel came from (the previous cell in the wind direction, wrapping); `rain = m * s * min(1, 0.25 + climb)`; `m -= rain`; rain recorded at the cell being crossed.
- Wrap: the row is a loop; the moisture entering any cell is what a parcel that already crossed the whole row once would carry (implementation: start at column 0 with m = 0, two circuits, keep the second).
- `sea_level` = elevation thresholds[0][1] (`world.sea_level()`), `mountain_start` = thresholds[2][1] (`world.start_mountain_th()`).
- Precipitation: `field = base_field(seed, world) + rain`; then `2 * (field - min) / (max - min) - 1`; thresholds unchanged (`find_threshold_f` over land at 0.75 and 0.3).
- Wind map pixel: eastward `(round(255 * s), 0, 0, 255)`, westward `(0, 0, round(255 * s), 255)`; black-and-white mode paints `(g, g, g, 255)` with `g = round(255 * s)` regardless of direction.
- Empty / degenerate: a row with strength 0 yields zero rain everywhere in that row; a row with no ocean cell yields zero rain (nothing to carry); a row with no land yields zero rain.
- Loading a world file without wind fields: `has_wind()` is False, no layer created; everything else unchanged.

## 5. Blind-spot pre-empts

- Pipeline placement: "the precipitation simulation adds it to the temperature-curved noise with equal weight before the final rescaling to the range minus one to one, so the thresholds and every later stage see the combined field".
- Stated inverse / preservation: "Everything computed before precipitation for a given seed is unchanged" and "a world whose winds are calm everywhere gets the precipitation it gets today".
- Parallel APIs: "Winds round-trip through the protobuf and HDF5 formats and take part in world equality, and world files written before winds existed still load and report no winds".
- Falsy-on-missing: `has_wind()` False on old files.
- Codebase-inferable (the one allowed): the protobuf Python module is generated from `World.proto` (the repo ships `updating_protobuf_format.sh`; the Dockerfile provides `python -m grpc_tools.protoc`).

## 6. Description draft (meta.md body)

Add prevailing winds and orographic precipitation to the climate pipeline. The README promises rain shadows, but precipitation today is noise shaped by temperature and never looks at elevation or at any wind.

Give every world a wind layer holding a direction and a strength per cell, computed row by row from latitude alone. A row's latitude is the centre of the row measured from the north pole, so a row centred halfway down sits on the equator, and the distance from the equator is split into three equal bands per hemisphere. The band nearest the equator and the band nearest the pole blow westward, the middle band blows eastward, where eastward means toward increasing column index. Within a band the strength rises linearly from zero at the band's edges to one at its centre. Expose this as `WindSimulation` beside the other simulations, whose `prevailing` method returns the two arrays for a height and width, and on the world as a `wind` setter taking the direction and strength arrays, with `wind_direction`, `wind_strength`, `wind_at` and `has_wind` beside the existing layer accessors. Direction is 1 for eastward and -1 for westward.

Moisture then travels along each row in that row's direction. A parcel over an ocean cell takes up a share of the moisture it is missing equal to the row's strength and drops nothing. Over a land cell it drops a share of what it carries equal to the strength times the smaller of one and a quarter plus its climb, where the climb is the elevation gained coming from the cell it just left, zero when it did not climb, divided by the distance from the world's sea level to the elevation at which mountains start. That rain lands on the cell being crossed. Rows are loops: what leaves the last column in the wind's direction enters the first, so the moisture entering any cell is what a parcel that has already crossed the whole row once would carry. `transport_moisture` in a new moisture module returns that rain field, between zero and one, for a world with elevation, ocean and wind. The precipitation simulation exposes its temperature-curved noise as `base_field`, taking the seed and the world and returning values between zero and one, and adds the rain field to it with equal weight before the final rescaling to the range minus one to one, so the thresholds and every later stage see the combined field. A world whose winds are calm everywhere gets the precipitation it gets today.

Winds are produced whenever precipitation is, including the precipitations step, and a world that already carries winds keeps them, so callers can supply their own. Everything computed before precipitation for a given seed is unchanged. Winds round-trip through the protobuf and HDF5 formats and take part in world equality, and world files written before winds existed still load and report no winds. A wind map drawn by `draw_wind` paints each cell with the row's strength scaled to 255 and rounded, in the red channel for eastward rows and the blue channel for westward rows, or in all three channels in black and white mode; generation writes it next to the precipitation map with the wind suffix, and the info operation reports whether a world has winds.

(~470 words; hard cap 500.)

## 6b. Scope added after the first LOC measurement (round 1)

The first reference measured 199 human-effective lines including 32 in the generated protobuf module, under the 200 floor. Four in-model levers were added, all stated in meta.md and all tested exactly:

- a `winds` pipeline step between plates and precipitations (Step, generation gate, CLI STEPS, wind map written under `include_winds`);
- strength halved on land at or above the mountain start (`prevailing(world)` now needs elevation and ocean; supplied winds are untouched);
- ocean uptake scaled by the cell's temperature normalised over the whole world (couples transport to the temperature layer; `transport_moisture` needs temperature);
- the rain field kept as a `rainfall` layer with `has_rainfall`, `rainfall_at`, protobuf/HDF5 round trip, `draw_rainfall` grey map, CLI map and info line.

Final hook: 242 human-effective across 11 files (about 210 excluding the generated module).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| NEW | worldengine/simulations/wind.py | — | +55 | 40 | bands, strength, WindSimulation |
| NEW | worldengine/simulations/moisture.py | — | +60 | 45 | transport_moisture with wrap and climb |
| MODIFY | worldengine/simulations/precipitation.py | 140 | +25/-12 | 15 | base_field split, rain blend, wind guard |
| MODIFY | worldengine/model/world.py | 920 | +70 | 50 | WindLayer, wind setter/getters, wind_at, has_wind, proto in/out |
| MODIFY | worldengine/World.proto | 110 | +2 | 2 | windDirection, windStrength |
| MODIFY | worldengine/protobuf/World_pb2.py | generated | regenerated | 0 | generated, counts zero |
| MODIFY | worldengine/hdf5_serialization.py | 225 | +14 | 12 | wind group |
| MODIFY | worldengine/generation.py | 275 | +6 | 5 | WindSimulation before precipitation, seed slot 9 |
| MODIFY | worldengine/draw.py | 800 | +35 | 28 | draw_wind, draw_wind_on_file |
| MODIFY | worldengine/cli/main.py | 560 | +8 | 7 | wind map on precipitations step, info line |

TOTAL ~275 raw / ~205 meaningful across 8 modified + 2 new files. The floor is 200 effective; this sits close to it. Buffer levers already inside the stated scope if the hook reads under 200: the black-and-white wind map branch, `wind_at`, the "no ocean in row" and "calm row" short-circuits, and the old-file loading branch in both serialisers are all genuine stated behaviour, not padding. Expect the real diff nearer 320 raw / 240 effective once shape checks and the two serialisers are written in the repo's verbose style.

## 8. Solution outline

helpers:
- `prevailing(height, width) -> (direction, strength)` <- band and strength sentences
- `_band_of(u) -> (direction, centre)` <- the three-band sentence
- `WindSimulation.execute(world, seed)` <- sets `world.wind` only when `has_wind()` is False
- `transport_moisture(world) -> rain` <- the parcel sentences; loop over rows, `for step in range(2 * width)`, index `x = (x0 + d * step) % width`, previous `(x - d) % width`, record when `step >= width`
- `PrecipitationSimulation.base_field(seed, world) -> field` <- the existing `_calculate` minus its final rescale
- `PrecipitationSimulation._calculate(seed, world)` <- `base_field + transport_moisture(world)` then rescale (unchanged formula)
- `PrecipitationSimulation.execute` <- runs `WindSimulation` first when the world has no wind
- `World.wind` property/setter, `WindLayer(direction, strength)` with `__eq__` via `_equal` on both arrays
- `_to_protobuf_world` / `_from_protobuf_world` branches guarded by `has_wind()` / `p_world.windDirection.rows`
- `save_world_to_hdf5` / `load_world_to_hdf5` wind group
- `draw_wind(world, target, black_and_white)` per-pixel colour rule
- CLI: `draw_wind_on_file` under `if step.include_precipitations`; `print_world_info` line

No fixpoint loop (two circuits is the stated canonical form). No recursion.

## 9. Test file outline

Path: `tests/orographic_<hash>_test.py` (hash from `openssl rand -hex 3`), unittest classes like the repo, pytest runner.

Block 1: imports (numpy, tempfile, os, World/Size/GenerationParameters, Step, generate_world, WindSimulation, transport_moisture, PrecipitationSimulation, TemperatureSimulation, hdf5 save/load, draw_wind, PNGWriter, cli main).
Block 2: builders: `flat_world(width, height, elevation=..., ocean=...)` returning a world with elevation thresholds set (sea level 1.0, mountain start chosen so the span is a power of two), `row_world(cells)` building a one-row-per-band world from a compact spec, `calm_wind(h, w)`, `east_wind(h, w, s)`, `west_wind(h, w, s)`, `rescale(field)`.
Block 3: assertions: `assert_rows_equal(a, b)`, `assert_close(a, b)` (numpy allclose with 1e-12).
Block 4 buckets:
- Wind bands (10): height 6 gives polar/middle/tropical at strength 1 with directions -1/1/-1 mirrored south; height 3 gives calm edges (u = 2/3 and equator); height 12 edge rows at 0.5; width independence; arrays constant along rows; integer direction dtype values in {-1, 1}; strength within [0, 1]; equator row calm for odd heights; `WindSimulation.execute` populates the layer; a world with a supplied wind keeps it after execute.
- Transport exact (16): ocean then flat land decays by 0.25 per cell eastward; climb 0.5 gives fraction 0.75; descent gives 0.25; climb >= 0.75 caps at 1 (parcel fully drained); westward mirror of the eastward case; wrap seam eastward (ocean at last column, ridge at column 0); wrap seam westward (ocean at column 0, ridge at last column); climb measured from the previous cell in wind direction, not the next (asymmetric ridge); rain lands on the crossed cell (not the one ahead); strength 0.5 scales uptake and rain; calm row all zeros; all-land row zeros; all-ocean row zeros; two-circuit steady state (a row where the first circuit differs from the second); rows independent (a mixed world); values within [0, 1].
- Precipitation integration (9): `base_field` in [0, 1]; stored precipitation equals `rescale(base_field + transport_moisture)` on a hand-built world with supplied wind; calm supplied wind reproduces `rescale(base_field)`; thresholds derived from the combined field (a lee cell's category changes); precipitation executed on a world without wind creates the wind layer; `generate_world(w, "precipitations")` yields wind and precipitation and no erosion layer; `generate_world(w, "full")` keeps temperature identical to a direct `TemperatureSimulation` run (unchanged before precipitation); humidity/biome downstream: a windward cell is wetter than its lee twin after the full pipeline on a small hand-built world; supplied winds survive the full pipeline.
- Serialisation (8): protobuf round trip keeps direction and strength exactly and `w == unserialised`; HDF5 round trip same; `has_wind` False after loading `seed_28070.world`; a world without wind serialises to protobuf with no wind fields and loads without a layer; HDF5 likewise; `layers` key sets match in both directions; `wind_at` after round trip; equality fails when strength differs (inverse).
- Drawing + CLI (6): eastward row pixels red channel = round(255 s), westward blue; strength 0 rows black; black-and-white mode grey; `draw_wind_on_file` writes a readable PNG; CLI generation at the precipitations step writes `<name>_wind.png` (small world, in a temp dir); info prints the has wind line.

Cross-product cells (§ 11b) are inside the transport bucket. Anchor ~50 tests.

## 10. Forced signatures / kwargs

- `WindSimulation.execute(world, seed)`: seed accepted and unused (repo convention, several stages ignore it).
- `transport_moisture(world)`: takes the world, not arrays, so it reads thresholds through `sea_level()` and `start_mountain_th()`.
- `base_field(seed, world)`: same argument order as `_calculate(seed, world)`.
- `draw_wind(world, target, black_and_white=False)`: matches `draw_precipitation`'s signature.
- `World.wind` setter takes a 2-tuple like `precipitation` takes `(data, thresholds)`; shape mismatch raises `Exception` like the sibling setters (the message is not pinned).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Wrap seam polarity: the parcel leaving the last column eastward enters column 0; westward the mirror; the "previous cell" for the climb wraps the same way | F-10 (direction x seam) + F-3 (x wraps, y does not) | A8 | transport geometry | #2 (the two-circuit steady state only shows at the seam) | agents iterate `range(width)` once in the wind direction and treat column 0 as the parcel's dry start | "Rows are loops ... what a parcel that has already crossed the whole row once would carry" | `wrap_seam_eastward_ridge_at_column_zero`, `wrap_seam_westward_ridge_at_last_column` |
| 2 | Two-circuit steady state: the first circuit starts dry, so rain on the cells before the first ocean cell is wrong unless the loop is closed | F-6 (ordering of the traversal start vs the wrap rule) | S2 | transport state | #1 | single pass passes every row whose ocean comes first | same sentence | `steady_state_row_land_before_ocean` |
| 3 | Mountain start vs hill threshold: thresholds are labelled sea/plain/hill/mountain but the mountain start is index 2 ("hill"); `start_mountain_th()` is the accessor | A5 naive reading (candidate new pattern, unmeasured) | A5 | threshold resolution | #1 (both change the climb fraction) | agents pick thresholds[1] or hard-code 3% | "the elevation at which mountains start" | `climb_uses_mountain_start_span` (span chosen so thresholds[1] gives a different fraction) |
| 4 | Serialiser regeneration: the wind layer must survive protobuf AND HDF5 AND `__eq__`, and the protobuf module is generated | S3 baseline preservation (existing `serialization_test.py` is the discriminator) | S3 | persistence | #5 | agents store wind outside `layers` or skip protobuf because pb2 is generated | "round-trip through the protobuf and HDF5 formats and take part in world equality" | existing `test_protobuf_serialize_unserialize` + new round-trip tests |
| 5 | Step gate and supplied winds: winds must exist at the precipitations step, must not be recomputed when supplied, and precipitation run alone must create them | F-14 (declared vs derived stage state) | S4 | pipeline gating | #4 (a layer created in `execute` but not in `generate_world` misses the step) | agents wire WindSimulation only into `generate_world` full path | "Winds are produced whenever precipitation is, including the precipitations step, and a world that already carries winds keeps them" | `precipitations_step_has_wind`, `supplied_wind_survives_pipeline`, `precipitation_alone_creates_wind` |
| 6 | Blend placement and rescale: rain added after the rescale, or before the temperature curve, or thresholds computed on the noise field | F-6 | S2 | precipitation composition | #2 (exact expected values depend on both) | the existing code rescales inside `_calculate`; agents add rain in `execute` after it | "adds the rain field to it with equal weight before the final rescaling" | `precipitation_equals_rescaled_sum`, `lee_cell_changes_threshold_category` |

Axes: transport geometry, transport state, threshold resolution, persistence, pipeline gating, precipitation composition. Interdependence: #1-#2-#3 share the transport kernel; #4-#5 share the layer lifecycle; #6 depends on #2 through exact values.

Scope audit: the climb fraction is per cell; strength per row; thresholds whole-world; rescale whole-world. Example audit: no examples in the meta. Format-noun audit: "row" = one y index across all columns; "cell" = one (x, y); "layer" = a `World.layers` entry. Tolerance fixtures: none. Unbounded-promise audit: "already crossed the whole row once" promises a property, not an iteration bound.

## 11b. Capability cross-product matrix

| | ridge interior of row | ridge at the wrap seam | calm row (s = 0) |
|---|---|---|---|
| eastward | `climb_half_eastward` | `wrap_seam_eastward_ridge_at_column_zero` | `calm_row_no_rain` |
| westward | `climb_half_westward_mirror` | `wrap_seam_westward_ridge_at_last_column` | (same calm test, second row) |
| supplied wind (not computed) | `supplied_wind_drives_precipitation` | `supplied_westward_seam_through_pipeline` | `calm_supplied_wind_matches_base` |

Off-diagonal predicted failure mode: over-firing at the seam (rain recorded twice, or the dry start recorded), and the westward seam being computed with the eastward previous-cell index.

## 12. Tier + category

- Tier: Olympus. Sub-rank: Good if the batch lands 20-40%.
- Category: feature-request (net-new layer, new stage, new APIs; title verb Add).

## 13. Predicted pass rate

30-45%. The model is stated in full and transcribable (the doctrine says knowing is free); the band is carried by six integration walls on separate axes, two of them discriminated by the repo's own existing tests. If the first batch reads over 45%, the next levers are tests-only: a second-circuit row where the first circuit leaves a non-zero residue, and the westward seam through the full pipeline.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5
- [x] Phase 2: canonical org resolved, 8 keywords x PR+issue, bodies of #13/#77/#217 read; no implementation of the central capability
- [x] Closest approved opened side by side: rocketpy-propellant-slosh meta.md
- [x] Title verb-led, 10 words, names the subsystem
- [x] Shape declared
- [x] API surface lists every asserted name
- [x] Canonical form: bands, strength, parcel rules, wrap, rescale, pixel colours, degenerate rows, old files
- [x] 1 codebase-inferable requirement (generated protobuf module)
- [x] Description ~470 words, under the 500 cap, plain prose, no headers
- [x] File footprint sketched against real files; ~205-240 meaningful, above 200
- [x] Helpers 1:1 with sentences
- [x] Test outline in 4 blocks, ~50 scenario-named tests
- [x] Forced signatures documented
- [x] 6 traps, 6 axes, interdependent clusters, every trap with F-id or flagged unmeasured (#3)
- [x] § 11b filled, off-diagonal cells tested
- [x] F-20 audit: `base_field` is a new sibling of `_calculate`; old behaviour (calm winds reproduce today's precipitation) guarded both ways
- [x] F-21 audit: no caller-supplied interface
- [x] F-24 / F-25: not applicable (no namespace pass, no placeholder)
- [x] F-23 audit: no value-or-callable clause
- [x] Representation pins: direction compared by value (`== 1` / `== -1`), strength by allclose, pixels by exact ints
- [x] Qualifier attachment: each sentence has one subject
- [x] Stated-but-untested: the info line and the B/W map are tested; nothing stated is untested
- [x] Unbounded promises: none
- [x] Stated nouns: row, cell, band, strength, direction, parcel, climb, sea level, mountain start, rain field, base field, thresholds, layer, step, protobuf, HDF5, equality, wind map, info
- [x] Predicted Wrong Logic < 25%
- [x] Category matches

## Why this is not a duplicate

Closest approved: rocketpy-propellant-slosh (a new physical mode threaded through an integrator) and sfepy-adaptive-stepping-accounting (in flight, time stepping). Different repo, different domain (procedural climate), different kernel (a cyclic moisture transport feeding a threshold-classified field and two serialisers). No corpus problem touches world generation, precipitation, winds or worldengine.

Predicted iteration cycles: 2 (one precheck + fairness round, one batch).
