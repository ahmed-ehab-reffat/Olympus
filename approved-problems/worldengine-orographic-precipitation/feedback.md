# feedback.md — worldengine-orographic-precipitation

## Summary

Repo: Mindwerks/worldengine (Python, MIT, ★1070). Base b2adbb674afb381232097f126e548a8c133e4633 (2026-08-27).
Pick source: hunt 2026-09-14-B (README promises rain shadows; precipitation never reads elevation or wind).
Tier: Olympus. Category: feature-request.

## Attempt history

| Round | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-15 | DESIGN.md written, no code | — |
| 1 | 2026-09-15 | Reference + 57 tests + Dockerfile built. First LOC read 199 human-eff incl. 32 generated pb2 (under floor); added three coupled levers from the design's own model (winds step, mountains halve strength, temperature-scaled ocean uptake) and the `rainfall` layer (model, both serialisers, grey map, CLI map, info). Final hook: 242 human-eff (~210 excluding the generated protobuf module), 11 files. | Local: 106 passed x3 (49 base + 57 new), deterministic. Clean room (fresh clone at base): both patch orders OK; new-on-base 57/57 fail for feature-missing reasons (guarded imports). Docker: both images build; offline `--user 1000:1000` runs: base 49/49, new 57 fail w/o solution, 57 pass with. Mutation battery: 22 mutants, 21 killed (m02b is equivalent). Feature-stub: 31/57 fail; the 26 survivors are persistence/drawing/step/self-consistency tests by design. |

## Fix tracking

- Reference bug caught by the tests: `WindSimulation.execute` overwrote a supplied wind (contract says keep it). Fixed.
- Fixture bug: a symmetric ridge cannot tell "climb from previous" from "climb from next" (mutation m01 survived). Replaced with a plateau fixture, both directions.
- Base repo bug, not ours: `worldengine --step precipitations` crashes in `draw_precipitation` (it draws humidity, per its own FIXME). CLI tests use the `winds` and `full` steps.
- After erosion the elevation changes, so `transport_moisture(world)` on a finished world differs from the stored `rainfall`; the CLI test asserts the stored layer and the map, not a recomputation.

- 2026-09-15 platform build FAILED rebuild-safety: `git clone --depth 1` of `worldengine-data` followed the moving `master` branch. Fixed by fetching the exact SHA (asserted with `test rev-parse`), `.git` removed, and pinning all pip packages to the versions the build resolved (numpy 2.5.3, protobuf 7.36.1, grpcio/grpcio-tools 1.84.0, h5py 3.16.0, pytest 9.0.3, ...). Rebuilt from a clean base clone; offline `--user 1000:1000`: base 49/49, new 57 fail without solution, 57/57 pass x3 with solution, base 49/49 with solution. Dockerfile is solver-visible, so the next batch is full price.

- 2026-09-15 platform checks (Test Quality FAIL 2/61, Task Quality FAIL fairness, Solution Quality FAIL). Fixed:
  - meta: dropped the README/issue-history sentence, body opens on the task sentence. Looped rows now defined as the steady state of a parcel circling the row (one more lap brings it back unchanged), not "a parcel that already crossed the row" (the reference ran exactly one zero-start warm-up lap, unstated). Uniform temperature: every cell counts as warmest, in the uptake and in `base_field`. Dropped the input-layer list. 488 words.
  - reference: `transport_moisture` solves each row's lap as an affine map in closed form (`_steady_moisture`); `normalized_warmth` guards the zero temperature span (was NaN) and is reused by `base_field`.
  - protobuf: `World_pb2.py` regenerated with official protoc 33.1 (gencode 6.33.1, same as base, was 7.35.1) and ruff 0.8.4 check+format clean. Dockerfile runtime pins now protobuf 6.33.6 + grpcio-tools 1.81.1 (bundled protoc 33.5, so an agent regen is importable).
  - docs: `manual/cli.rst` step list and --bw text, README example output list wind + rainfall maps.
  - tests (62): height-3 test no longer pins direction on the zero-strength band boundaries (equator only). Half-strength now 8/79, 7/79. New: weak-wind steady state east + west, uniform temperature for transport and for `base_field` (finite, spans 0..1), calm wind reproduces pre-change precipitation (values computed on base b2adbb67) and leaves an all-zero `rainfall` layer. CLI info checks use regex, not exact spacing. atol 1e-9 so iterate-to-convergence solvers pass. Constant `O` renamed `OCEAN` (ruff E741); whole test file ruff clean.
  - mutants: zero-start two-lap and ten fixed laps each fail 4 steady-state tests; uniform-as-coldest fails 2.
  - clean room (pin4 image, offline, uid 1000): base 49/49 x3, new 62/62 fail without solution, 62/62 pass x3 with it, identical fingerprint. LOC hook 251 human-eff, 13 files.
  - not done (advisory): legacy HDF5 fixture test, no pre-feature .hdf5 exists in worldengine-data; the no-wind HDF5 round-trip covers the loader path.
  - meta + Dockerfile changed, so the next batch is full price (no re-eval).

- 2026-09-15 Test Quality re-check FAIL 3/65: the `wind_at` assertions (execute, protobuf and HDF5 round-trips) pinned an exact 2-tuple the prompt never stated. Fixed in meta only: `wind_at` "returns a cell's direction and strength as a tuple". Tests and solution unchanged (4 assertions, reference returns `(int, float)`), so the last clean-room validation stands. Meta 498 words, ASCII. Advisory left open again: no genuine pre-feature HDF5 fixture exists.

- 2026-09-15 Auto Review revision requested (P4 2/3, T 2/3, S 1/3). Fixed:
  - S1 (High): `base_field` divided by a zero noise spread on a 1x1 world (NaN). New `unit_scaled` in `simulations/basic.py` (ones when every value is equal) now does the temperature scaling, the noise scaling and the final -1..1 rescale, replacing `normalized_warmth` and the two unguarded divisions. A 1x1 land or ocean world gives finite base_field, precipitation and rainfall.
  - T3/T4: `draw_wind_on_file(..., True)` writes grey pixels (128 for half strength, 51 for 0.2), and a CLI `--step winds --bw` test checks the saved wind map is grey from the stored strengths. `--bw` cannot go through a precipitation step: base `draw_precipitation` black-and-white indexes `world.precipitation["data"]` on a plain array and crashes (base bug, left alone).
  - New test: one-cell world stays finite and in range (base_field 0..1, precipitation -1..1).
  - P4: split the dense sentences (warmth defined on its own, ocean and land shares and climb split, precipitation paragraph and drawing sentence split). Longest sentence now 40 words, body 491, ASCII.
  - clean room (pin5, offline, uid 1000): base 49/49, new 65/65 fail without solution, 65/65 pass x3 with it, base 49/49 x3, identical fingerprint, protoc regen imports. LOC hook 251 human-eff, 14 files. Ruff check + format clean on every changed .py.
  - meta changed, so still a full-price batch.

- 2026-09-15 Test Quality FAIL 1/65 (two check runs, one unfair test each). Fixed:
  - `test_supplied_westward_seam_survives_the_full_pipeline`: dropped the rank-3 and coefficient assertions (fixture non-degeneracy, not a contract). Seam checks now read the stored `rainfall` instead of recomputing moisture on the eroded terrain. Kept the exact affine fit of windy precipitation on [calm precipitation, rain, 1], which the equal-weight-then-rescale rule guarantees.
  - `test_full_pipeline_precipitation_reaches_humidity`: dropped the post-erosion inequality. That left a check base already satisfies (the test passed without the solution), so it now also requires the finished world to carry a non-empty `rainfall` layer.
  - meta: base_field sentence now "Expose the warmth-curved noise as `PrecipitationSimulation.base_field(seed, world)`, returning values between zero and one." 484 words, longest sentence 40, ASCII.
  - solution unchanged. Clean room (pin6, offline, uid 1000): base 49/49, new 65/65 fail without solution, 65/65 pass x3 with it, base 49/49 x3, identical fingerprint.
  - meta changed, still a full-price batch.

- 2026-09-15 batch 1 (10x Nova) + Auto Review revision (Tests 1/3). Grader 1/10 (Nova_Nova_10); regression-free passes 0/10. Detail in eval-results.md.
  - Every run deleted `Step.plates`'s precipitation/erosion/biome flags. Base `generate_world` returns early only when `include_precipitations` is off, so base plates runs the whole pipeline like full; the meta's "winds step between plates and precipitations" read as "plates stops after plates". Nova_Nova_5 and Nova_Nova_10 carry the identical step.py hunk and both hit 65/65; the grader failed 5 as FAIL_REGRESSION and passed 10.
  - Fix: meta now says "A new winds step stops after the wind layer. The plates, precipitations and full steps keep every stage they run today and also produce winds, and a world that already carries winds keeps them." (490 words). New test `test_plates_step_keeps_every_later_stage_and_adds_wind` runs the plates step end to end: wind + rainfall + watermap/humidity/biome, and precipitation, humidity, biome equal to the full step.
  - Float (T5): `wind_at` strength, equator strength, seam ocean rain and two ocean `rainfall_at` checks now use a 1e-9 tolerance; direction still exact. Five runs tripped the band-centre check (0.9999999999999993) but never as their only failure.
  - Kept as fair (reviewer rated stated): single `wind` layer (4 runs), array properties not methods (2), precipitation alone creates wind (2), supplied wind kept (1), winds step stops before temperature (1).
  - Replay of all 10 batch-1 patches against the new tests (pin7, offline): 0/10 pass; the plates test kills all 10; no float failures remain. Nova_Nova_5 and Nova_Nova_10 fail only the plates test (65/66). If the new sentence stops the flag deletion this batch reads ~2/10. That is a description delta, so treat it as a guess (L35), not a measurement.
  - Clean room (pin7, offline, uid 1000): base 49/49, new 66/66 fail without solution, 66/66 pass x3 with it (same fingerprint), base 49/49 x3. Solution unchanged, 251 human-eff.
  - Next: meta changed, so re-eval is not offered; the next measurement is a fresh full batch.

- 2026-09-15 Test Quality FAIL 2/67: two checks required `PrecipitationSimulation.execute` itself to create a missing wind; the prompt only says the generation steps produce winds, and base sequences prerequisites in `generate_world`. Fixed in tests only (meta untouched, still 490 words):
  - removed `test_precipitation_run_alone_creates_the_prevailing_wind`; the precipitations-step wind check through `generate_world` stays.
  - `test_one_cell_world_stays_finite` now supplies an eastward wind before `execute`. No remaining test calls `execute` without a wind.
  - added `test_supplied_wind_survives_the_precipitations_and_plates_steps` (the reviewer's coverage suggestion): a distinctive supplied wind is unchanged after `generate_world` with each step, and precipitation exists.
  - the reference still creates wind inside precipitation; harmless, no longer tested.
  - clean room (pin8, offline, uid 1000): base 49/49, new 66/66 fail without solution, 66/66 pass x3 with it (same fingerprint), base 49/49 x3.
  - replay of batch-1 patches: 0/10. The new test fails all 10 at its `has_precipitations` assertion on the plates step (checked on Nova_Nova_10, line 495), the same deleted-plates-flags cause as the plates test, not a wind-preservation miss. Nova_Nova_5 and Nova_Nova_10 still fail only on that cause (64/66). Dropping the direct-execute test removes one failure from Nova_Nova_4 and Nova_Nova_6; neither flips (both fail other stated checks).
  - legacy HDF5 fixture suggestion still not done: no pre-feature .hdf5 exists in worldengine-data.

- 2026-09-16 **ACCEPTED** on batch 2 (10x Nova): 2/10 legitimate (Nova #1, Nova #2), Auto Review Description 3/3, Tests 3/3, Solution 3/3. FP panel: Nova #1 clean; Nova #2 genuine pass with one judge dissent (min-max normalised `base_field`, then `(base + rain) / 2`) overruled because the prompt does not pin `base_field`'s exact form and the combination test uses the implementation's own `base_field`. Batch 2 kills: F-28 sibling wind layers 7/10 (sole failure of four 63/66 runs), F-16 accessor methods 2/10, F-29 supplied wind overwritten 2/10; 52 of 66 tests killed nothing, no run touched `Step.plates`. Finalized: catalogue F-28, F-29, L57-L59, Pattern 90; archived to approved-problems/.

## Notes for the platform run

- Solver-visible surface to freeze before the first batch: meta.md (490-word body), Dockerfile, base commit b2adbb67.
- Dockerfile needs network at build (pip + the `worldengine-data` fixture fetch into `/worldengine-data`, resolved by the repo's own tests as `../worldengine-data`). Build-time fetches are pinned: the fixture repo is fetched by SHA `802b01d6a5fe13f033331aa6aea9169cc23d99c7` (upstream HEAD, same checkout the local tests ran against) and every pip install carries an exact version. `grpcio-tools` is installed so `python -m grpc_tools.protoc` can regenerate `World_pb2.py` (the repo's `updating_protobuf_format.sh` wants a system `protoc`).
- LOC is thin: the human count excluding the generated `World_pb2.py` is about 210. Do not pad; if a reviewer re-counts under 200, the honest in-model lever left is a CLI `wind` operation for existing world files.
- Predicted band 30-45%. Levers if too easy (tests-only, re-eval eligible): a second-circuit residue row (first circuit leaves a non-zero parcel), a cold-sea seam cell, a per-cell strength row with mixed halving.
- Step 4b core-slice precheck is owed before any further scope; the wind-direction sub-piece overlaps the 2015 draft PR #217 in file footprint (not in capability).

