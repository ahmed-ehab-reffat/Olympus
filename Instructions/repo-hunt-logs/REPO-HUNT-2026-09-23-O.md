# REPO-HUNT 2026-09-23-O (hunter #28, CONSECUTIVE_MISSES=0)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=0: no softening beyond the permanent 2026-09-09-B
rules; no star/issue window widening. Standing rulings: AI root file = ranking penalty; AI
commits/trailers = lane-scoped (SKILL 2b softened). Mandatory on every lane audit: fork-branch
exclusivity scan (forks?sort=newest + non-upstream branch diffs + `agents/adx-labtesing-deepswe-forks.txt`
+ `sig_accounts.txt`), vendored-licence header read, L62 cold-build timing for any C++ engine.
LOC honesty: return only if an honest SPIKE total is >= 250 human-eff AND the difficulty-carrying
core is >= 150 (hook `.claude/hooks/effective_loc_check.py`).

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Plan (hunt #27 hint): invented-lane workshop on NEW domain engines whose pipeline discards state a
later stage needs; at most 3 workshop sub-agents at once; seen-set `s_0923h24/allseen_k2.txt`.

Excluded: all LEDGER repos (SLICING walles/riff, HANDOFF, CLAIMED, DEAD), greatscottgadgets/luna,
every repo judged in the 09-23-C..N logs, every `problems/` repo.

Scratch: `worktrees/_hunt/s_0923h28/`.

## Stage 0-bis / cached index
Proven pool: re-judged in hunt #23 (J, group P, 0 viable of 9); nothing approved since except LEDGER
repos. Not re-derived.

Cached index triage (no fetch): union of every cached jsonl (35,103 rows with metadata) minus
`s_0923h24/logged.txt` (every slug ever written in a log/brief/screen), in-language, 500-6000 stars,
pushed > 2025-11-01, allowlisted licence, not app/LLM/UI -> 2,369 rows; engine-keyword narrowing ->
391 + 2nd-tier 737. Read by eye: overwhelmingly ML papers, apps, UI kits, downloaders. Engine-shaped
never-logged residue: alchemist0823/three.quarks, geomstats/geomstats, neilfraser/js-interpreter,
meodai/heerich, azurice/ranim, chrisbuilds/terminaltexteffects, keichi/binary-parser,
mapbox/geojson-vt, projectmesa/mesa (plus dead-on-sight: planck.js = Box2D port, opentype.js /
swash = OpenType support matrix, avian/godot_voxel/terrain3d = engine-host builds, CUDA repos).

Second triage pass: "judged" = every owner/repo slug written in a hunt log, an agent dossier,
SATURATED-REPOS, TOO-EASY or LEDGER (7,322 slugs; `s_0923h28/judged.txt`), which is narrower than
`logged.txt` (logged includes raw screen lists). Cached rows in-language, 500-6000 stars, pushed
>= 2026-01-01, allowlisted licence, engine keywords, never judged -> 708 (`s_0923h28/unjudged.tsv`).
Read by eye. Dead on sight: game engines / renderers needing a GPU host, CUDA, ROS, LLVM/MLIR builds,
spec-support-matrix engines (litehtml, blitz, canvg, micromark, commonmark-java, opentype.js,
takumi), language implementations (coconut, TSTL, porffor, scriptc, perry, biwascheme, engine262),
named-algorithm catalogues (mealpy, gradient-free-optimizers, POT, probreg), apps.
Live check (stars/licence/pushed/commits in 90 days) of 18 engine-shaped survivors: dormant = 
protomaps-leaflet, kiss-icp, function-plot, tangram, coconut, pyntcloud, three.quarks,
JS-Interpreter, heerich, binary-parser (0 commits/90d). mmcloughlin/avo = dormancy with a full PR
queue (lizthegrey #486 arm64 lowering, #491/#496 infra; dominikh #480/#481; kill-list row "dormant
with a full PR queue").

## Fresh sweep 1: repos CREATED after 2025-03-01 (newly grown into the band after the index fetch)
`s_0923h28/sweep1.sh`: 7 languages x 6 star bins x 6 licences, pushed > 2026-06-01. (results below)

## Workshop (brief `s_0923h28/BRIEF-O.md` = hunt #26 brief + mechanical gates, vendored-licence read,
C++ 600 s cold build, SPIKE-not-paper LOC rule). Wave 1: NASA-AMMOS/3DTilesRendererJS,
corrscope/corrscope, TimelyDataflow/timely-dataflow.

### TimelyDataflow/timely-dataflow (agent) — DEAD
Gates pass (★3649, MIT, no vendored code, 100% Rust, master CI green). Best invented lane: a
"why is this frontier stuck" blame API naming the pointstamps holding a probe/scope-output frontier,
through nested scopes (Tracker implications sum counts and discard origins). Honest ~155-190 total /
~80-100 core: it reuses summarize_outputs, PathSummary, MutableAntichain, Tracker::node_state and
the logging events, and is a post-pass over reachability logging that Materialize already ships
(src/compute/src/logging/reachability.rs). Guard Q1 n, Q2 n, Q3 y, Q4 fails #2/#5. Other lanes:
summary-aware progress validation ~155 (validation dead class, maintainer protocol unsettled
#327/#331); nested-scope cycle witness ~150-195 (textbook cycle finding); graph IR / fusion =
maintainer drafts #761/#763/#764; suspend-dataflow = teskje fork branch; deterministic simulation =
#810; notificator operators = REMOVAL record (#818/#819). Maintainer is restructuring the progress
core. No build. Dossier `s_0923h28/agents/timely.md`.

Fresh sweep 1 result: 3,009 rows (repos created after 2025-03-01); after removing the seen union,
the judged set and AI/app/UI descriptions -> 44 rows, all apps, UI kits, LLM installers, scripts
(one procedural dungeon demo, one Rust file manager). **0 survivors.** New-growth repos are
overwhelmingly apps and AI tooling, not engines.
Fresh sweep 2 (running): 20 engine keywords `in:description` x 7 languages, 500-6000 stars, pushed
> 2026-04-01, sorted by update.

Wave 2 (launched as slots free): asdf-format/asdf (F-49/F-47 write->read round-trip lanes).

### corrscope/corrscope (agent) — DEAD (absorbed; a spike measured it)
Gates pass (★754, BSD-2, vendored scipy code BSD-3, Python 99.9%, master CI green, no livelier
fork), but velocity is low (2 real code commits in 12 months). Suite: 311 tests, ~9 s, deterministic
x3; 12 failures all come from one Python 3.12 `object.__getstate__` issue that corrupts the global
yaml object (#288/#368). A Docker image would need Python 3.10 or one documented deselect. Best
lane: config-format versioning where unversioned files keep the defaults they were written against
(#410). The wall is ruamel's children-before-parent construction order. **Spike measured 93
human-eff** (~120 with extras, core ~70). Guard Q3 y (a post-pass over the ruamel node tree), Q4
fails #2/#3. Other lanes: grid layout ~120-150 (a CSS-grid port); sub-sample trigger precision
absorbed by parabolic()/np.interp; stereo triggering ~80; external-trigger sample rate ~60 (real F2P
bug: 48000 -> 48280 at 12 kHz). Dossier `s_0923h28/agents/corrscope.md`, spike
`s_0923h28/spike-corrscope-versioning.patch`.

### NASA-AMMOS/3DTilesRendererJS (agent) — WEAK (spike 133)
Repo is strong: Apache-2.0 (no vendored code), ★2474, JS, gkjohnson commits daily, master CI 8/8
green, vitest 629/629 in ~1.7 s identical x3, headless three.js TilesRenderer works in Node. Best lane:
3D Tiles 1.1 multiple contents (`tile.contents`, implicit per-content availability that
SUBTREELoader parses and throws away, tiles mixing renderable content with an external tileset).
F2P reproduced: base parses 0 of 3 contents. **Spike measured 133 human-eff** (211 raw, 5 files),
honest ~215 / core ~115. The maintainer said in #323 it "should be able to be consolidated in
requestTileContents", and the spike agrees. Spec-named (CesiumJS Multiple3DTileContent), and
Om-singhaI's AI-assisted #608 plan covers multi-content + metadata (live risk). Other lanes:
metadata/TILE_* semantics absorbed + CesiumJS; S2 bounding volumes = S2 port; viewerRequestVolume
~30; tilesetVersion ~25; LRU bytes merged #1747 (2026-09-15); skip-LOD maintainer PR #1452. Dossier
`s_0923h28/agents/tiles3d.md`, spike `agents/tiles3d-spike.patch`.

Fresh sweep 2 result: 1,971 rows (20 engine keywords in the description x 7 languages, 500-6000
stars, pushed > 2026-04-01). After removing the judged set, non-allowlisted licences and AI/app/UI
rows, ~500 rows remain, but only 4 are NOT in the seen union, and all 4 are noise (a dungeon demo,
a recaptcha solver, a survey list, CompilerGym). The engine-shaped seen-but-never-judged rows are
cloud emulators, GPU/CUDA/ROS/LLVM stacks, metaheuristic catalogues, manifold-optimisation
toolboxes (pymanopt, geomstats: named-algorithm siblings), CARLA scenario_runner (needs a server),
coreemu (0 commits in 6 months), CesiumGS/gltf-pipeline (6 commits in 6 months; sibling
gltf-transform ships every optimisation), DraqueT/PolyGlot (★509, 1 commit in 6 months).
**0 survivors; the sweep budget (2) is spent.**

Wave 2: asdf-format/asdf (running), thorvg/thorvg (running; C++, L62 cold build first).

### thorvg/thorvg (agent) — DEAD (vendored licence)
Top-level LICENSE is MIT, but `src/loaders/lottie/tvgLottieInterpolator.cpp` carries an MPL-2.0
header and is compiled in the default Lottie loader (`src/loaders/lottie/meson.build:21`, in the tree
since 2023-07-18), and `src/loaders/png/tvgLodePng*` is LodePNG under Zlib. Both fail the allowlist
(RULES.md: one non-allowed vendored licence = whole-repo reject; same class as pmp-library). The
gif.h and jpgd pieces are public domain, also outside the allowlist. Every other gate passed (★1834,
C++ primary, 100+ engine commits in 90 days, CI 8/8 green). No build and no lane work. For the human:
SATURATED-REPOS.md candidate row "thorvg LICENCE-DEAD (vendored MPL + Zlib)". Detector: a per-file
header grep over `src/`, since the MPL file has no LICENSE beside it. Dossier
`s_0923h28/agents/thorvg.md`.

### asdf-format/asdf (agent) — WEAK (~195 / ~120 on paper, below both floors; not spiked)
Gates pass: ★567, BSD-3, vendored jsonschema MIT, 100% Python, 119 code commits/180d, main CI green
(one downstream-packages failure), pytest 2194 passed / 2 xfailed, ~45 s, identical x3 without a
hash-seed pin. Round-trip identity is already very complete on base (views, aliases, cycles,
compression/storage options, external and streamed blocks all survive write -> read). Best lane:
pass-through write of untouched lazy_tree nodes (F-47: lazy nodes keep never-accessed children in
tagged form, yet write_to/update re-convert every node; F2P reproduced, a lazy converter is called
5/5 times on base). ~195 / ~120; Q4 #3 risk (converter-indexed blocks #1508 must be stated); the
approved "untouched parts byte-identical Rewrite" problem shares the class. Other lanes: windowed
reads of compressed blocks (#2026) = maintainer's active 6.0 compressor rework + prior art; view-span
packing refused by maintainer (#1669); tag-version negotiation (#2105) maintainer-owned; aligned
blocks ~110; smart in-place update = asdf 2.15 free-space reuse (previous-major prior art);
AsdfFile.blocks API = public closed PR #1946 diff. binggao1230 (sig account) x1 outside the lane.
Dossier `s_0923h28/agents/asdf.md`.

Wave 3 not launched. Remaining unjudged engine-shaped rows fail on sight: tskit (★191), PyRTL (★305),
pyfar (★137), GPy (a GP catalogue with GPflow/GPyTorch siblings), perfanalytics/pose2sim (solo, but
the pipeline needs ONNX pose models and OpenSim via conda, so it cannot build offline), mapbox/geojson-vt
(~600-line core; v5 memory rewrite just landed; maplibre's fork exists), coreemu (needs netns/root).

## Stage 6 guard
No RANK 1, so there is nothing to guard. The two WEAK lanes were not guarded as candidates because
both miss the LOC bar. Their guard answers are in the agent dossiers.

## Result: NO-CANDIDATE
Tried: the proven pool (not re-derived; J re-judged it and nothing new has been approved); the cached
index, triaged twice (never-logged 2,369 -> 391, and never-judged 708), plus 18 live re-checks; two
fresh sweeps (repos created after 2025-03, 3,009 rows, 0 survivors; 20 engine keywords in the
description, 1,971 rows, 4 unseen, 0 survivors); and a workshop of 5 NEW domain engines in two
waves of at most 3: timely-dataflow DEAD, corrscope DEAD (spike 93), 3DTilesRendererJS WEAK
(spike 133, honest ~215/115), asdf WEAK (~195/120), thorvg DEAD (vendored MPL-2.0 + Zlib).
Weak fallbacks (NEITHER clears 250/150): NASA-AMMOS/3DTilesRendererJS (3D Tiles 1.1 multiple
contents with implicit per-content availability; spec-named, CesiumJS prior art, Om-singhaI plan
#608); asdf-format/asdf (lazy_tree pass-through write; overlaps the approved byte-identical
Rewrite class).

Lesson: the seen union (78,844) covers ~95% of any in-scope 500-6000-star bin (probe: Rust
700-760 stars, 95/100 seen). The ~700 seen-but-never-judged engine rows are almost all
GPU/ROS/CUDA/LLVM stacks, spec-matrix engines, catalogues or apps. Workshops on the remaining
live, buildable engines keep finding MATURE ABSORBING frameworks (timely, asdf, tiles3d), where the
state a stage discards is real but the lane that restores it comes in at 90-200 honest eff.

Next hunt: stop mining GitHub star bands. Either (a) re-open the proven pool at the SUBSYSTEM level
with a spike per lane (repos where we already shipped and a second subsystem class is cold), or
(b) accept a composite pick. The only >=250 route seen in three hunts is a lane with its own
streaming/ordering state (riff's spike: 440). Target that shape directly: a stage that must carry
state across chunk/hunk/tile/frame boundaries that the repo processes one at a time, in repos
already known to be gate-clean.
Disk: 15G free; no build output left; clones kept under `s_0923h28/` (timely, corrscope, tiles3d,
asdf, thorvg; 71M total).
