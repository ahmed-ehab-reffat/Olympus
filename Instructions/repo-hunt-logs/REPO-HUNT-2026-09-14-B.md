# Repo hunt 2026-09-14-B — exhaustive star-band enumeration; Mindwerks/worldengine RANK 1 (wind + orographic precipitation lane)

Third hunt of the day (planetiler was RANK 1 of 2026-09-14 and is now in `problems/`). The scratchpad
that held the 09-13/09-14 tooling was gone, so the screener was rebuilt under `worktrees/_hunt/`
(`gqlmeta.py`, `filt.py`, `triage.py`, `screen.sh`, `band.py`, `deadlist.txt`, `sig_accounts.txt`) —
it persists there for the next session.

## New index: the whole 500-6000 star band, enumerated

`gh api search/repositories` with `language:<L> license:<lic> stars:LO..HI pushed:>2025-09-14
archived:false fork:false`, star range split recursively whenever a slice exceeds the 1000-hit cap.
7 languages x 9 permissive licences = **21,257 repos** in ~35 min at 30 requests/min. This is a
SUPERSET of every package index swept before (conda-forge, vcpkg, crates.io, Homebrew, Debian,
awesome-lists, topics), so those no longer need re-running. Kept at `worktrees/_hunt/band.jsonl`
(name, stars, lang, licence, pushed, issues, description, topics) — re-triage it with a new keyword
filter instead of re-fetching.

Two bugs paid for: `language:c++` in a URL query is read as `language:c  ` (the `+` is a space) and
returns ZERO rows silently — use `language:cpp`. And the old dead-list built from `github.com/` URLs
had 337 entries; the logs mention most repos as bare `owner/repo` tokens, so the rebuilt list has
2749 and caught scryer-prolog, erg, go-astisub that the old one let through.

| Index | Slugs | Mechanically passing | Engine-shaped after keyword triage | Read |
|---|---|---|---|---|
| Star band, Go+Rust | 4829 | 4829 | 408 | famous infra; 10 screened, 0 authorable |
| Star band, Python | 5546 | 5546 | ~600 | 7 + 2 screened, worldengine survived |
| Star band, TS+JS | 7900 | 7900 | 517 | 6 + 6 screened, 0 authorable |
| Star band, Java | ~1500 | ~1500 | 101 | 2 screened, gctoolkit weak fallback |
| Star band, C++ (re-run with `cpp`) | 1472 | 1472 | ~200 | libraries with heavy build graphs; none screened |
| 172 fresh single-word topics | ~700 | 308 rows | ~40 | 5 screened, 0 authorable |
| nixpkgs `fetchFromGitHub` + spack-packages | 36427 | not fetched | — | superseded by the band (almost all < 500 stars) |

Also re-checked the pool: the 14 pool repos with no ledger mention are all in-flight, corpus-class
(pulldown-cmark/comrak, sqlfluff = SQL, textual = framework) or already tried (rspirv, GQL).

---

## RANK 1 — Mindwerks/worldengine (Python 3.10+, MIT) ★1070 — prevailing winds + orographic precipitation

- **URL / stars:** https://github.com/Mindwerks/worldengine — ★1070
- **Language:** Python; deps `numpy`, `protobuf`, `pypng`, `PyPlatec==1.4.3` (C++ plate simulator,
  **manylinux cp312 wheel exists** — `pip download` confirmed, no compiler needed), optional `h5py`
  (needed by `tests/serialization_test.py`).
- **Domain:** procedural world generator: plate tectonics -> elevation -> ocean -> a staged CLIMATE
  simulation pipeline (`generation.py:generate_world`): temperature -> precipitation -> erosion
  (rivers) -> watermap -> irrigation -> humidity -> permeability -> biome (Holdridge) -> icecap.
  Every stage reads earlier `world.layers[...]` and writes a `Layer` / `LayerWithThresholds` /
  `LayerWithQuantiles` with land-only quantile thresholds (`find_threshold_f(data, pct, ocean)`).
- **Open issues (PR-free):** 40 (total 44). **Licence:** MIT (`LICENSE.txt`), nothing vendored.
  **Quota:** 0 of 6; not in `SATURATED-REPOS.md`, no hunt log had screened it (`worldengine` absent
  from the 2749-slug dead list).
- **Last commit:** 2026-08-27 (`psi29a`, co-author since 2015). 34 commits/12mo, 24 by the
  maintainer: Nov-2025 "Major Infra Restructure", Windows support, `from_dict` fix, release 0.20;
  Aug-2026 "drop pynoise and make use of numpy" (the only simulations/ code change), Python 3.9
  drop, gdal fix. **Requirement 6:** live — forks ★2/★1, all dead; maintainer is concurrently
  rewriting `Mindwerks/plate-tectonics` (PyPlatec's C++), not the climate pipeline.
- **Requirement 7:** `ci.yml` runs pytest; every `master` row `success` (2026-08-27).
- **Baseline determinism (measured):** venv + `pip install -e . h5py`, with the fixture repo
  `Mindwerks/worldengine-data` cloned as a sibling (tests resolve `../../worldengine-data/tests`):
  **49 passed, 3/3 identical, 13 s.** Own RNG per stage (`numpy.random.RandomState(seed)`), sub-seeds
  drawn once in `generate_world` with the comment "after 0.19.0 do not ever switch out the seeds here
  to maximize seed-compatibility".
- **Docker:** Pattern B `olympus-base-python`. `pip install worldengine[hdf5]` equivalent + the
  fixture repo cloned into the image + `grpcio-tools` (wheel confirmed) so `World.proto` can be
  regenerated with `python -m grpc_tools.protoc` (the repo's `updating_protobuf_format.sh` wants a
  system `protoc`; `World_pb2.py` IS checked in). Unbuilt in Docker yet — owed at author Step 2.
- **Lane heat (Stage 2c):** `simulations/` 2 commits/12mo, `model/` 2, `draw.py` 2,
  `hdf5_serialization.py` 1, `generation.py` 2, `cli/` 2, `World.proto` 1 — all packaging. No branch
  family, no AI-sweep marks (0 in 34 commits), no corpus invariant test (the 49 tests are thin:
  `test_world_gen_does_not_explode_badly` is literally the generation test).
- **Competitor profiling (2b-bis):** PR authors `MM1nd` (11, 2015-16), `psi29a`, `ftomassetti`
  (co-founder), `Ygryega`, `sjbrown`, `RichardScottOZ` — all old or real. Zero signature accounts.
- **Maintainer-welcomed lane (2d):** issue **#13 "Generate winds"** (2014, open): `psi29a` posted
  reference material, `ftomassetti` proposed direction+intensity per cell, then PR **#217 "Winds:
  initial winds implementation"** (2015-12, OPEN, unmerged): `simulations/wind.py` +101 (a
  latitude-band direction gradient with noise, the dungeonleague.com recipe), `set_wind_direction`
  on the model, protobuf/hdf5 fields, a wind map in `draw.py`. **Winds ALONE are therefore both a
  magnet and exclusivity-dead. Rain shadow is asked for by nobody** (searches `rain shadow`,
  `orographic`, `moisture` -> only #217/#13), while the README claims it twice: *"Worlds are
  generated using plate simulations, erosion, rain shadows, Holdridge life zones..."* and
  *"precipitations are calculated considering latitude and rain shadow effects"* —
  `precipitation.py` is simplex noise x a temperature gamma curve, wrapped at the left/right border,
  renormalised to [-1,1]; it never reads elevation. `erosion.py:129` even says "Using the wind and
  rainfall data" with no wind anywhere. This is a README-documented, unimplemented domain effect
  (`CAPABILITY-SHAPES.md` S-B), the shape that found tippecanoe and mwparserfromhell.

### The capability

Make precipitation orographic: derive a prevailing-wind field (direction + strength per cell,
latitude bands with the world's own noise so the same seed gives the same winds), transport moisture
along it from ocean sources across land with wrap-around on the x axis only (the world is a cylinder:
`precipitation.py` already blends `x < border` against the wrapped noise), deposit on windward upslope
(elevation gradient along the wind), deplete the air mass so the lee side dries, then feed the result
through the EXISTING temperature curve, renormalisation and land-only thresholds so every downstream
stage (humidity weights, river seeding in `erosion.river_sources`, watermap droplets, biome cells,
icecap) sees the new distribution through the unchanged `LayerWithThresholds` contract. The wind
becomes a first-class layer: `has_wind`, accessors, protobuf + hdf5 + dict round-trip, a wind map
image and CLI wiring, and it must exist in the `precipitations` partial step, not only in `full`.

**Machinery the repo lacks (Stage 3b):** no directional field of any kind, no advection/transport
over the grid (every existing stage is per-cell or a downhill walk), no elevation input to
precipitation, no layer that carries two components (direction + magnitude), no wind serialisation.
Nearest sibling arm: `PrecipitationSimulation._calculate` (60 lines of noise + curve). Sketch: wind
field ~70 · moisture transport with wrap/uplift/depletion/ocean source ~110 · precipitation blend +
threshold re-derivation ~25 · model layer + dict round-trip ~50 · proto fields + `(to|from)_protobuf`
~25 · hdf5 ~25 · draw ~40 · CLI + step wiring ~30 -> ~375 raw, **~280 effective**, 8-9 files across
simulations / model / protobuf / hdf5 / draw / cli / generation. Above the 200 floor with buffer.

### TRAP SEAMS

| Pattern | Present | Evidence |
|---|---|---|
| **F-9 cross-stage drop** | yes | precipitation thresholds are quantiles over LAND (`find_threshold_f(..., ocean)`); humidity, biome and the drawing all classify through them. Changing the field without re-deriving thresholds (or deriving them before the transport) shifts every biome cell |
| **F-3 second-axis carve-out** | yes | ocean cells are the moisture SOURCE for transport but EXCLUDED from thresholds; x wraps, y does not (`x < border` blend exists only horizontally) |
| **F-6 ordering** | yes | noise -> temperature gamma curve -> renormalise to [-1,1] is the existing order; where orographic modulation enters (before the curve, on the normalised field) decides whether the tropics stay wet; `Step.precipitations` runs BEFORE erosion, so wind cannot depend on rivers |
| **F-22 / seed compatibility** | yes | `sub_seeds` comment forbids reshuffling; a wind stage that draws from the global RNG or shifts a slot changes temperature/elevation for the same seed — the blessed `seed_28070.world` fixture and `worldengine-data` images are the oracle |
| **F-10 cross-product** | yes | direction (E/W/N/S bands) x slope polarity (windward vs lee) x source (ocean-adjacent vs interior) x step (`precipitations` vs `full`) |
| **F-14 declared terminal state** | yes | `is_applicable` guards (`has_precipitations() and has_irrigation()`) gate each stage; a wind layer needs its own `has_wind` and the partial step must produce it |
| **F-20 sibling API** | yes | `to_dict`/`from_dict`, protobuf and hdf5 are three parallel serialisers; #275 was a `from_dict` bug — a wind layer added to two of three breaks the round-trip test on the third |
| F-16 typed setter | partial | `precipitation.setter` demands `(data, thresholds)` tuples and shape checks; a wind setter must carry two matrices |
| F-8 named algorithm | yes | "rain shadow"/"orographic lift" is textbook, but the repo's own precipitation is a [-1,1] noise field with a temperature gamma curve and land-only quantiles — the textbook mm/yr model does not fit; misdirection for free |

**Phase-3 death-class guard:** one kernel (the transported moisture field) feeds thresholds, humidity,
rivers, biomes, drawing and three serialisers; a per-file fix (new module + call) fails the round-trip
and seed-compat tests; not a standalone file. Pre-Pick Guard: not a validation contract; not a
single-subsystem transform once thresholds, wrap, seeds and serialisers interact; hardness survives the
stated formula because the walls are integration walls (findmyway law, >= 2 hidden); not a port (no
reference implementation of "worldengine rain shadow" exists, and the winds PR is a direction map only).

**Honest difficulty read:** the physics can be stated in three sentences, so the model itself is
transcribable; the band is carried by seed compatibility, x-only wrap, land-only thresholds, the
step gate and the three-way serialisation. Predicted 30-45%, i.e. inside the 50% ceiling but not a
low-pass pick — same tier as planetiler. Author with the F-10 cell table from day one.

### Risks

1. **Exclusivity, MEDIUM:** PR #217 (open since 2015) implements a wind-DIRECTION layer with the
   same model/serialiser/draw footprint. It does not implement transport, uplift or rain shadow, which
   is the central capability, but the scope gate reads DIFFS: keep the wind field an internal input of
   the moisture stage (direction + strength together, seeded from the stage's own sub-seed), cite the
   README sentences as the requirement, and re-run PR-DIFF at submit. If a reviewer cites #217, do
   not contest.
2. **Derivative, MEDIUM:** "rain shadow" is nameable by an outsider. Mitigate by phrasing `meta.md`
   on worldengine nouns (layers, thresholds, `Step.precipitations`, seed compatibility, the three
   serialisers) and by making the F-10 cells repo-specific.
3. **Small repo (4.3k LOC):** the thin suite means every test is ours; write them through the
   public `World`/`generate_world` API with small synthetic worlds (the `test_sea_depth` pattern:
   hand-built elevation arrays), never through generated 512x512 worlds.
4. **PyPlatec** is a C++ wheel: fine for Docker (manylinux), but a plate-generation test is slow
   (~10 s at 32x16); keep new tests on hand-built `World` objects.
5. **protobuf regeneration** needs `grpcio-tools` in the image and a note in the description that
   `World_pb2.py` is generated from `World.proto`.

---

## Fallbacks (screened, weaker)

| Repo | ★ | Read |
|---|---|---|
| josephburnett/jd (Go, MIT) | 2302 | own v2 diff format (sets, multisets, set keys, LCS lists, precision) — but Feb-Mar 2026 is a maintainer AI sweep (24 commits as "Your Name", `CLAUDE.md`, "100% coverage enforcement", spec round-trip tests): the surgical-gap class is being closed continuously |
| microsoft/gctoolkit (Java, MIT) | 1300 | GC-log line parsers -> event model; 68 real issues; but docs/Javadoc/hacktoberfest churn dominates and the parser lane gets outside one-line PRs |
| wavedrom/wavedrom (JS, MIT) | 3491 | WaveJSON -> bricks -> SVG pipeline, 2061 LOC, 190 open issues **almost all uncommented feature asks** (sub-cycles, duty, thresholds, common gap lines) = a magnet field; suite is 6 `to.be.an('array')` tests; solo maintainer ships chores only |
| textX/textX (Python, MIT) | 857 | DSL meta-language; solo maintainer active on registration API + metamodel checks; `santhreal` (recorded signature) x1 outside lane; #90 model-to-text closed. Lane audit not done |
| dotabuff/manta (Go, MIT) | 689 | Dota 2 replay decoder; maintainer in a parser-perf series; fixtures are replay files |

## Screened and killed this session

| Repo | ★ | Gate | Evidence |
|---|---|---|---|
| jac3km4/redscript | 514 | corpse | 4 maintainer commits/12mo: docs, cargo update, ci fmt |
| Jon-Becker/heimdall-rs | 1614 | lane density | solo, 26 open PRs all `feat(vm)/(decompile)` — whole repo is the workstream |
| w3c/epubcheck | 1956 | spec + solo sweep | `rdeltour` shipping EPUB 3.4 rows weekly; every capability is a spec row |
| coredhcp/coredhcp | 1105 | missing-arm + RFC | plugin registry, 15 open plugin PRs |
| drewnoakes/metadata-extractor | 2831 | AI sweep + signature | 22 Copilot commits, `youdie006` PR, fuzz-fix swarm |
| donmccurdy/glTF-Transform | 1965 | lane density | maintainer's `dedup()`/hash PRs in the functions lane |
| hungpham2511/toppra | 926 | published method | TOPP-RA paper port, C++/Python hybrid |
| stoolap/stoolap | 1218 | solo + SQL | 298/300 commits by one author in our house style |
| mlivesu/cinolib · howeyc/ledger · simupy · sankeymatic · nomnoml · WebCola · OrigamiSimulator · duckscript · binary-parser | — | corpse / no CI | 1-3 code commits in 12mo or no test workflow |
| harehare/mq · mermaid-rs-renderer · annotate-snippets-rs · LaTeX.js · clarity | — | hot solo/team programme | 74-300 commits/12mo landing in the target lane |
| TUDelft-CNS-ATM/bluesky | 563 | team velocity | 80 commits, students sweeping ASAS/openap/resnav |
| rst2pdf/rst2pdf | 597 | maintenance + golden PDFs | release-only commits; reportlab golden comparisons |
| keymap-drawer · pandas_market_calendars · orgajs · json-rules-engine · receiptline · tetra3d · sprs · egui_tiles · OpenRAM · gctoolkit(weak) | — | see notes | small/solo, AI marks, PDK/tooling infeasible, or dormant |
| C++ band | 1472 | shape | reference libs (tinyxml2, pugixml, cereal, s2geometry, litehtml, blend2d), simulators with vendor toolchains (gem5, ChampSim, ramulator2), published solvers (amgcl, CaDiCaL, Stim) |

## Method notes

- **The star band is finite and now cached.** 21k repos is the entire universe the platform allows
  in these languages/licences; future hunts should re-triage `band.jsonl` with a sharper positive
  filter (mine had ~30% junk from `agent|skill|paper` rows) and refresh only the `pushed` date.
- **Yield per index this session:** engine-shaped rows after keyword triage ~1500; hand-read ~600;
  screened 43; one survived. The survivor came from the smallest reading unit — a README claim that
  the code contradicts — not from stars, issues or commit counts.
- **`screen.sh` in one call:** stars/licence/push, PR-free issue count, 12mo commit authors + last
  12 subjects, AI marks, workflow names, default-branch run conclusions, PR-author histogram,
  signature-account hits, open PR titles. ~10 API calls/repo; the search-API secondary limit
  (30/min) is shared with any background sweep, so run screens between sweeps.
