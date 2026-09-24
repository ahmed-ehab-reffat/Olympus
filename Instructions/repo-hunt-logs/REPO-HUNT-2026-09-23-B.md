# REPO-HUNT 2026-09-23-B

Unattended `olympus-factory` hunt worker (hunter #14). `CONSECUTIVE_MISSES=2`, so the softened
2026-09-09-B rules apply, and the star/issue windows are widened (recorded under Relaxations).
Standing user ruling 2026-09-23 applied: a root AGENTS.md / CLAUDE.md is a RANKING PENALTY when the
90-day commit bodies carry no AI marks; an AI mark in the 90-day commit stream is still a kill.
Carry-forward scratch reused (no re-fetch): `worktrees/_hunt/s_0923h13/`. My scratch:
`worktrees/_hunt/s_0923h14/`.

**RESULT: NO-CANDIDATE.** Hunter #13's probed survivors are all dead (AeroSandbox was already
refused by the platform language gate). The cached index was reopened twice: once under the new
root-file ruling (363 rows) and once for the dormant-but-alive band that h13's ranker had
over-killed (106 rows). Two fresh niche sweeps (OSM/web-mapping, 60 niche topics) returned nothing.
Nothing reached Stage 3 with a lane that survives the Stage 6 guard. This is the 10th consecutive
empty session.

## Relaxations (CONSECUTIVE_MISSES=2)

- Softened 2026-09-09-B rules applied throughout.
- Star window widened: no 6000-star upper filter on candidate screening (5000+ remains a ranking penalty).
- Issue window: zero-issue trackers are a ranking penalty only (already so under 09-09-B).
- Root AI file = penalty, per the 2026-09-23 user ruling.

## Stage 0-bis proven pool

EXHAUSTED for the 9th consecutive session. 75 repos at <=2 subs (unchanged count). The only repos
new since hunt #12 are siliconcompiler, libspatialindex and csbindgen, all three CLAIMED in the
LEDGER, so they are taken. No re-screen.

## Carry-forward: hunter #13 probed survivors (`s_0923h13/probe13_a.tsv`, `probe13_b.tsv`)

| Repo | Verdict | Evidence |
|---|---|---|
| peterdsharpe/AeroSandbox | DEAD (Requirement 0 on record) | Already killed on the PLATFORM LANGUAGE GATE: `SATURATED-REPOS.md` line ~1474 "aerosandbox-area-rule - language-gate/quota disqualification", and `approved-problems/acoular-reflecting-panels/feedback.md` says the picker refused it. Also: its whole 90-day stream is 256 commits on 2026-07-04/05 (204 on one day), a repo-wide surgical-fix sweep ("Fix ...", "Raise ValueError for ...", "Standardize docstrings ...") across every subsystem, with no trailers. The correctness gap class is closed repo-wide |
| amzeratul/halley | DEAD | Requirement 7: no workflow runs at all (`gh run list` empty). Stream is console-platform/GDK/PS5 studio work. C 50% / C++ 48% by bytes |
| protomaps/PMTiles | DEAD | Author-controlled sibling package: every nameable capability (extract, cluster, verify, edit, show) lives in `protomaps/go-pmtiles`; a port into the js/python arms is publicly solved. 8 commits/90d |
| pink-kinematics/pink (was stephane-caron/pink) | DEAD | Curated catalogue: 4,724 lines over ~25 Task/Limit/Barrier classes of 45-425 lines each, every lane is "add the missing arm". Sibling port `kevinzakka/mink` ships the open asks (#188 obstacle collision avoidance = mink `CollisionAvoidanceLimit`). Textbook differential IK |
| konvajs/konva | NOT PURSUED | 14.8k stars (heavy penalty band), famous canvas library, 0 open issues; ranked below everything else |
| tyrasd/overpass-turbo | DEAD at Stage 6 guard | See the dossier section below |
| KhronosGroup/KTX-Software | DEAD (licence) | `LICENSES/` carries `LicenseRef-ETCSLA` (Ericsson texture codec licence, vendored `etcdec`), `LicenseRef-Kodak`, `Zlib` |
| crownengine/crown | DEAD (licence) | LICENSE: "The Crown Tools are released under GPL-3.0-or-later"; vendors `3rdparty/openal` (OpenAL Soft, LGPL). Note: probe13's ai=4 was a false positive (the regex matched "cursor" in editor commits) |
| jlblancoc/nanoflann, rust-diplomat/diplomat, uber/causalml, capnproto/capnproto, pdal/pdal, syoyo/tinyexr, csinva/imodels | DEAD (AI marks, verified in bodies) | nanoflann: `Co-Authored-By: Claude Sonnet 5` + `Claude-Session:`; capnproto: `Co-Authored-By: Claude Fable 5.1`, `Co-authored-by: Copilot`; pdal: `copilot-swe-agent[bot]` |
| RainerKuemmerle/g2o, maptalks/maptalks.js, agronholm/typeguard | DEAD / not pursued | g2o: 6 human commits in 90d and null licence (LGPL/GPL plugins); maptalks: null licence; typeguard: opr=23 vs m90=9 (a filling queue under a slow merge rate, the ruptures magnet) plus a recorded competitor-footprint account (`jaideeppyne`) |

Probe fix: `probe12.sh`'s AI regex contains a bare `cursor`, which matches ordinary commit text
(crown's editor commits). `s_0923h14/probe14.sh` replaces it with `Co-authored-by: Cursor|cursoragent`
and adds `claude.ai/code`, `copilot-swe-agent` and `Co-authored-by: ...(codex|gemini|devin|jules|openai)`.

## tyrasd/overpass-turbo (the one carry-forward survivor I audited in depth)

Mechanics clean: 1,245 stars, TypeScript 81%, MIT (package.json; the LICENSE file is what GitHub
reads as NOASSERTION), CI `node.js.yml` green on master (the red rows are Dependabot update jobs),
pnpm lockfile, 0 AI marks in 90-day bodies, no root AI file, PR authors are genuine OSM
contributors (deevroman, m-hue, mfbehrens, amandasaurus). Shallow clone in `worktrees/overpass-turbo`.

Lanes (Stage 2c):
- **Wizard (`js/ffs.ts` + `js/ffs/ffs.pegjs` + `js/ffs/free.ts`, ~780 lines).** The only lane with a
  real compiler shape: a PEG grammar, a DNF normaliser (`normalize()`), a leaf compiler
  (`get_query_clause`, with in-place mutation of shared leaf objects), preset expansion into
  types plus conditions, and a sibling API (`ffs_repair_search`) that walks the same normalised
  tree. The open capability is boolean completeness: the grammar carries commented-out `xor` and
  `except` productions and `/*logical_not TODO? */`, `normalize()` alerts on anything but and/or,
  and several leaves have no negated Overpass filter (`likelike`, `id:`, `user:`, `uid:`, presets),
  so negation needs set difference with named sets.
  **Killed, three ways:** (1) Stage 6 guard #2 / TOO-EASY decision rule: a single-subsystem,
  fully-specified transform. The tests must pin exact Overpass QL text (there is no offline
  Overpass evaluator to use as a semantic oracle), so the canonical form has to be spelled out,
  and the traps (leaf negation table, preset negation, date-in-negated-branch) are independent
  case analysis. (2) Magnet: issue #247 (2016, open) asks for `not` over a parenthesised
  expression, and the grammar TODOs point every author at the same three operators. (3) Warm lane:
  simon04 worked #247 in July 2026 (`older:` tests, abbreviated dates, `date:`), so `not` is the
  next item on the list the maintainer is working through.
- MapCSS engine (`js/jsmapcss`, ~1,300 lines): refactored into ES6 classes in July 2026; its open
  features are MapCSS 0.2 / JOSM spec rows (link selectors, pseudo-classes), a named-spec magnet.
- Shortcuts / autorepair: small regex preprocessors, LOC ceiling.

The July 18-19 stream is 98 commits in two days with agent-style bodies but no trailer; under the
2026-09-23 ruling that is a note, not a kill.

## Cached index, reopened by the 2026-09-23 ruling (root AI file = penalty)

Re-ranked every cached gate file that recorded root listings (`s_0923h13/gate13.jsonl`,
`gate_sib.jsonl`, `gate_joss.jsonl`, `p_0921/gate.jsonl`, `q_0921h11/gate_s11.jsonl`) with the
root-marker kill turned into a flag (`s_0923h14/rank14.py`). 363 rows in 500-9000 stars
(`ai_pool.txt`), 170 engine-shaped after a keyword filter (`eng_pool.txt`). Probed 24 with
`probe14.sh` (`probe14_a.tsv`, `probe14_b.tsv`):

| Repo | Verdict |
|---|---|
| SeaOfNodes/Simple, emdgroup/baybe, MOLAorg/mola, MRPT/mrpt, vincentlaucsb/csv-parser, lichtblick-suite/lichtblick, markuplint/markuplint, maplibre/maplibre-tile-spec, konsoletyper/teavm, reactive/data-client, samchon/typia, roblox-ts/roblox-ts, cooklang/cookcli, facet-rs/facet, OpenFeign/querydsl | DEAD: AI marks in 90-day commit bodies (3 to 198 each) |
| contentful/rich-text | 9 human commits, renovate-driven |
| IceCreamYou/THREE.Terrain | Agent-built bursts ("Document agent contribution process", SKILL.md, llms.txt) plus a public `roadmap.md` (a published pick list); textbook terrain algorithms |
| Baekalfen/PyBoy | Game Boy emulation is a faithful hardware-spec port (Pan Docs), sibling emulators ship every feature; 5,203 stars |
| tdewolff/parse | Web-format parsers (ECMAScript, CSS, HTML): every lane is a spec-named language-surface feature (carve-out) |
| microsoft/DirectXMesh | Textbook mesh processing (meshoptimizer is the sibling); only 10 human commits |
| LavaMoat/LavaMoat | The policy lane (includes, overrides, compaction) is being built right now by boneskull / FrederikBolding (May-July 2026); MetaMask team, 223 issues, a recent flakiness fix |
| streamich/memfs | Faithful port of Node's `fs` semantics (Node's own `lib/internal/fs` is prior art for every lane), 128 maintainer commits in 90 days, and fs-emulation collides with our pyfakefs picks |
| NucleoidAI/Nucleoid, project-blinc/Blinc | 65 and 363 solo commits in 90 days on young projects; lanes consumed as fast as they appear |

Also re-ranked the same gate files for the **dormant-but-alive** band (1-4 commits in 90 days, open
PRs <= 5, 500-9000 stars), which the h13 ranker had killed as `dormant` although the skill's
activity requirement is only 12 months (`dormant_pool.txt`, 106 rows). Engine-shaped rows and
their kills: Khan/genqlient (a `Co-authored-by: Copilot` trailer in the 90-day stream, verified),
guillaumeblanc/ozz-animation (vendors GLFW, zlib licence), observablehq/runtime (ISC, not on the
platform's explicit list), blend2d (zlib), emicklei/proto and davidhalter/parso (language-surface
carve-out), glyph-brush (text-layout lane already burned in 2026-09-20-C), segno / mangos /
glTF-SDK / swagger-parser (faithful ports of named specs), small_gicp / TinyMPC / NGT /
GeometricKernels (textbook algorithms with sibling libraries), PyGPSClient (parsers live in the
author's sibling packages), three-pathfinding (0 human commits in 90 days).

## Fresh sweep 1: OSM / web-mapping niche

70 hand-listed repos from the ecosystem overpass-turbo lives in (`osm_niche.txt`). 33 were already
in `seen14.txt` (the union of every seen list). Of the 37 unseen, the engine-shaped ones died at once:
abrensch/brouter (already seen, 14 AI marks), mapnik / osm2pgsql / osmose / openstreetmap-website /
OsmAnd / StreetComplete (GPL or LGPL), pyosmium / togeojson / overpy (under 500 stars),
mapbox/carto (archived). **0 survivors.**

## Fresh sweep 2: 60 single-word niche topics

`topic14.sh` searched 60 topics nobody had used (petri-net, bpmn, dmn, sysml, modelica, fmi,
lattice-boltzmann, sph, molecular-dynamics, phylogenetics, genome-assembly, mass-spectrometry,
spectroscopy, seismology, astrodynamics, ephemeris, gnss, rtk, radar, sonar, antenna, photonics,
lens-design, acoustics, psychoacoustics, microtonal, typesetting, hyphenation, chess-engine, shogi,
model-checking, term-rewriting, unification, prolog, answer-set-programming, pddl, timetabling,
vehicle-routing, bin-packing, 3d-printing, cnc, laser-cutting, embroidery, gerber, kicad,
spice-simulator, electrochemistry, battery-modeling, pharmacokinetics, epidemiology,
agent-based-modeling, cellular-automata, l-system, procedural-generation, wave-function-collapse,
navmesh, pathfinding) at >=500 stars. 397 rows, 378 unique, 113 already seen. Of the 265 unseen,
only 5 had an allowed licence, a supported language and a push in the last 12 months, and none is
an engine (a vacuum-robot product, two draw.io agent kits, end-of-life Camunda 7, Kogito, which has
moved). These niches are GPL/AGPL/LGPL-dominated (Stockfish, LAMMPS, gnss-sdr, SpiffWorkflow,
plumed, mdtraj, rinohtype, vivliostyle) or written in unsupported languages (Fortran, Modelica,
Lua, Kotlin, C#). `topic14_raw.tsv`, `topic14_live.tsv`. **0 survivors.**

Also probed, from past hunts' root-marker-only kills: stillwater-sc/universal (195 AI-marked
bodies), eunomia-bpf/bpftime (1), wemake-python-styleguide (3), johnfercher/maroto (1), all dead.
eclipse-ecal/ecal is clean but is IPC middleware (UDP multicast, shared memory) with a
timing-flakiness profile and a heavy dependency stack, so it was not pursued.

---

## Requirement 0

Not applicable (no candidate).

## Disk

No builds. Shallow clones of pink and overpass-turbo were removed after the audit. `df -h /`: 15G free throughout.

---

## What the next hunt should change

1. **The AI-marker commit-stream kill is now the largest single killer.** Of the 24 repos probed
   from the reopened root-file pool, 15 died on AI trailers in 90-day commit BODIES, not on the
   root file. The 2026-09-23 ruling reopened root files, but the body kill still removes about
   60% of engine-shaped repos in this band. Softened rule 09-09-B #3 already says an AI sweep counts
   only when it closes the gap class IN THE INTENDED LANE. The one lever left that reopens a large
   pool without breaking a platform rule is for the human to decide whether a trailer outside the
   intended lane (docs, CI, a different subsystem) is a note rather than a kill. Ask at the next
   touchpoint. Until then, do not re-screen the `probe14_*.tsv` rows.
2. **Do not re-run** the star/size/year grid, the TS/JS bands, h13's 30 awesome lists, JOSS, the
   sibling ecosystems, the OSM niche, or the 60 topics above. All are mined and filtered against
   `worktrees/_hunt/s_0923h14/seen14.txt` (28,095 slugs), which is the union to pre-filter against.
3. **Fix the AI regex before reusing `r_0923h12/probe12.sh`:** its bare `cursor` false-positives
   on editor and UI commits. Use `s_0923h14/probe14.sh`.
4. **Fix h13's ranker:** `rank13.py` kills `c90<5` as `dormant`, but the skill only requires a
   commit in 12 months. `s_0923h14/dormant14.py` rebuilds that band. It held 106 rows, and none
   survived (the licence and AI kills are listed above).
5. A structural observation: siliconcompiler was killed by the root-marker gate in an earlier
   session and later APPROVED (2026-09-23), and csbindgen was called a Requirement-6 corpse by
   hunt #12 and approved anyway. Both over-killing gates have now been relaxed. The remaining
   over-killer is the whole-stream AI trailer rule (item 1).
6. Do not re-screen: AeroSandbox (language gate), halley (no CI), PMTiles (go-pmtiles sibling),
   pink (catalogue plus the mink port), KTX-Software and crown (licence), overpass-turbo (the wizard
   lane fails guard #2, #247 is a magnet, and the maintainer is warm in that lane), memfs
   (a faithful port of Node fs), LavaMoat (policy lane under active build), genqlient (Copilot
   trailer), ozz-animation (vendored GLFW, zlib).

## Scratch

`worktrees/_hunt/s_0923h14/`: `probe14.sh` (fixed AI regex), `aimarks.sh` (prints the matching
body lines), `rank14.py` (a root-marker flag instead of a kill), `dormant14.py`, `ai_pool.txt`,
`eng_pool.txt`, `dormant_pool.txt`, `probe14_{a,b,c}.tsv`, `osm_niche.txt`, `topic14.sh`,
`topic14_raw.tsv`, `topic14_live.tsv`, `seen14.txt`.
