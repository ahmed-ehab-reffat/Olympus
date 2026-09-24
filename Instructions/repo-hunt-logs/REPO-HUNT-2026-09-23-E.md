# REPO-HUNT 2026-09-23-E

Unattended `olympus-factory` hunt worker (hunter #18). `CONSECUTIVE_MISSES=2`, so the softened
2026-09-09-B rules apply and the windows are widened. Relaxations recorded as they are used:

- **R1 (star window):** the 5000-star penalty band is relaxed to a 12000 soft ceiling for re-ranked
  rows (the 500-star floor is platform law and stays).
- **R2 (issue window):** zero/near-zero trackers are not penalised in ranking at all this hunt.
- **R3 (lane rule):** "ranks low" rows from hunts #16/#17 are re-adjudicated per LANE, not per repo.

Standing rules (user, 2026-09-23): a root AGENTS.md / CLAUDE.md is a ranking penalty; AI commits in
the 90-day stream are lane-scoped. Requirement 0 (platform picker) is OWED on anything handed over.
Scratch: `worktrees/_hunt/s_0923h18/`.

**Task (hint from hunt #17):** no topic sweeps. (a) Stage 3 seam audit of the ranks-low rows,
starting with coal-library/coal and cruise-control, then gobuffalo/plush, sigoden/argc,
leudz/shipyard, yamafaktory/jql; (b) same-domain siblings of approved-problems/ repos, sibling-library
check first. Excluded: teavm (SLICING), genqlient, capnproto, openglobus, stremio-core, vermin, gauge,
u-root, AeroSandbox, piscsi, and everything adjudicated in 09-23-C/-D.

## Stage 0-bis proven pool

EXHAUSTED for the 10th consecutive session. No repo entered the pool since hunt #17 (the newest
approvals, siliconcompiler / libspatialindex / csbindgen, are CLAIMED in the LEDGER). The pool repos
killed in 09-20-B/C were re-read under the 2026-09-23 AI-root ruling: none of them died on an AI root
file alone (python-control, awkward, go-workflows, numbat: competitor swarms or Requirement 7;
RocketPy: exclusivity + slosh already ours; ir-sim: maintainer shipped every lane). Verdict unchanged.

## Cached index re-adjudication (no fresh fetch)

The 28.5k-slug dead list (`s_0923h18/dead18.txt` = seen14 + dead17 + deadlist_all) marks almost every
in-scope repo >= 500 stars as SEEN, but most engine-shaped rows were dropped by screening agents with
no logged reason. Cross-referencing same-domain siblings of approved repos against the logs found 20
engine repos that are in the index with NO recorded verdict anywhere in `Instructions/`. Probed with
`probe14.sh` (`s_0923h18/probe18_a.tsv`, 90-day window):

| Repo | 90d human / ai / root | Read |
|---|---|---|
| coal-library/coal | 50 / 3 / - | hint row, see below |
| textx/textx | 20 / 1 / - | solo maintainer, meta-language, **Stage 3** |
| pysteps/pysteps | 13 / 0 / - | KNMI team, nowcasting engine, **Stage 3** |
| evalf/nutils | 14 / 0 / - | solo, FEM (sibling of scikit-fem/sfepy), **Stage 3** |
| LCAV/pyroomacoustics | 5 / 0 / - | sibling of acoular; 2 of 5 commits by `binggao1230` (recorded account, note) |
| AcademySoftwareFoundation/MaterialX | 34 / 0 / - | ASWF team, C++ shadergen |
| mfontanini/libtins | 2 / 0 / - | near dormant, 175 issues: dormancy magnet |
| MikePopoloski/slang | 97 / 1 / - | SV compiler; language-surface carve-out risk, maintainer-heavy |
| tlaplus/tlaplus | 76 / **71** / - | lemmy runs an agent over the tree: DEAD per lane unless proven otherwise |
| fjall-rs/fjall | 38 / 0 / - | solo LSM, 4.8k-class sibling redb is AI-swept |
| cberner/redb | 197 / 81 / AGENTS+CLAUDE | agent-swept, DEAD |
| lalrpop/lalrpop | 5 / 1 / - | grammar generator, low activity |
| jscad/OpenJSCAD.org, chaosprint/glicol | 0 / 0 | no commits in 90 days (activity margin) |
| cocotb, mfem, yosys, build123d | 64-613 human | team programs; capability-consuming by volume, low rank |
| pgmpy/pgmpy | 31 / 2 / AGENTS | 641 issues, swarmed tracker |
| OpenColorIO | 6 / 1 | colour-management spec rows (support-matrix penalty) |

### Verdicts on the hint rows and the index re-adjudication

- **coal-library/coal (hint row 1): SHELVED, lane dies at the absorption sketch.** Licence read: BSD-3
  (Willow Garage / OSRF / CNRS / INRIA text; the API reports NOASSERTION only because of the header).
  The invented lane named by hunt #17 is real in the source: `src/contact_patch_func_matrix.cpp:274`
  carries the maintainer's own `TODO(louis): properly handle non-convex shapes like BVH, Octrees and
  Hfields`, and `BVHShapeComputeContactPatch` / `HeightFieldShapeComputeContactPatch` /
  `BVHComputeContactPatch` just copy one point per `collide` contact. But the machinery is already
  there: `ShapeShapeContactPatch<TriangleP, Shape>` and `<TriangleP, TriangleP>` exist, and
  `src/contact_patch/polygon_convex_hull.cpp` does the merge. The BVH arm is "fetch triangle `b1`,
  call the triangle patch path, hull the coplanar ones": sketched ~120-160 eff for BVH-shape,
  hfield-shape and BVH-BVH together (missing-arm class, TOO-EASY). The lane is also live: `rjoomen`
  (Roelof Oomen, a real Tesseract contributor) merged #884 (swap direction of patches, 2026-08-18) and
  has #886 open on octree `b1/b2` handles, and `lmontaut` (who wrote the TODO) keeps topic branches.
  The one real seam (object-order polarity, the #884 bug class) is not enough to carry it. C++ with
  Boost + Eigen + assimp + octomap is also an expensive Docker. Clone removed.
- **cruise-control (hint row 2): stays SHELVED** (hunter #16/#17 verdict). Re-checked the one lane the
  hint named: the detector / self-healing subsystem is tested through EasyMock
  (`AnomalyDetectorManagerTest`), a mock-heavy suite (kill-list row), and a per-goal provenance or
  attribution lane collapses to the same `relocateReplica` / `relocateLeadership` chokepoint as the
  budget lane (uniform wrap). No new lane.
- **gobuffalo/plush, sigoden/argc, leudz/shipyard, yamafaktory/jql (hint rows 3-6): not re-opened.**
  plush's only unclaimed seam (interpreter vs VM parity) is inside the one contributor's live VM
  build (58 of 66 commits in 90 days); argc is the CLI-framework class (cliffy precedent, solo feature
  stream); shipyard's scheduler/ECS lanes have bevy as sibling prior art; jql is a query-language
  surface (carve-out) with a root CLAUDE.md. None of these reasons is a softenable gate.
- **textX/textX: DEAD on competitor profiling.** Mechanically excellent (MIT, 857 stars, pure Python,
  346 tests in ~5 s, deterministic 3x once the uv workspace members and Arpeggio 3.0.0.dev0 from git
  are installed; `worktrees/_hunt/s_0923h18/venv-textx`). The deep lane is a grammar-driven
  model-to-text serializer (inverts every construct; one walker kernel; round-trip oracle), and no
  public implementation exists. It dies on Stage 2b-bis: THREE distinct signature accounts filed
  surgical fix PRs in six weeks: `mayank-dev-15` (#440, account created 2026-06-01, 247 repos),
  `hareishakaur-spec` (#447, created 2026-03-10, 0 repos, no identity), `chuenchen309` (#445, "AI
  engineer building agent harnesses", PRs across kong, kombu, docling, markdown-it-py, msgpack,
  holidays, xsdata), plus `santhreal` (#444). The rule's threshold is two. The serializer is also a
  long-requested, maintainer-planned feature (#36 2017, #90 2018, closed), i.e. a magnet. Clone kept
  (small) only as an idea bank.
- **pySTEPS/pysteps: DEAD, capability-consuming.** A repo-wide xarray migration is landing now
  (`Xarray/example steps`, `Xarray/dont flip y` merged 2026-09-08, draft `xarray/main` #413), the
  blending lane is the KNMI team's 90-day stream, and the open queue already carries the obvious
  invented lanes (#532 motion field updated every timestep, #505 sprogloc, #523 probabilistic FSS,
  #418 nowcast plugins, #409 INCA motion).
- **evalf/nutils:** 102 stars (the cache row was stale). Below the floor.
- The other probed rows keep the reads in the table above (team programs, agent sweeps, dormancy
  magnets, spec rows, or no commits in 90 days).

## Fresh sweep 1 of 2: the never-adjudicated residual of the cached index

The cached metadata (`worktrees/_hunt/**/*.jsonl`, 51,780 rows) was cut to in-scope language,
permissive SPDX, 500-12000 stars (R1), pushed after 2026-06-15, an engine vocabulary regex on the
description and a junk regex against apps/LLM/UI/devops. Then every slug that appears in any hunt log,
`SATURATED-REPOS.md`, `TOO-EASY.md`, an agent dossier, a probe/mech table, or a GraphQL pre-gate file
(`p_0921/gate.jsonl`, `q_0921h11/gate_s11.jsonl`, the `live`/`resid`/`slice`/`tri` sets) was removed.
**1,122 rows remain** (`s_0923h18/unadj2.tsv`): repos that sat in the dead list only because an
earlier sweep had displayed them, never because anyone judged them. Split by language into three
screening agents (`agA` Python 308, `agB` TS/JS 419, `agC` Go/Rust/C++/Java 395) running Stage 1, 2c,
2b-bis, 2d-style lane naming, the sibling-library check, an eff-LOC sketch and the Stage 6 guard.

Side check while the agents ran, approved-repo siblings with no verdict anywhere: `stephenh/ts-proto`
(protobuf-to-TS codegen = the class of our approved protobuf-es-serialization: self-collision),
`timostamm/protobuf-ts`, `einsteinpy/einsteinpy`, `yapingcat/gomedia` (no commits in 90 days / since
2024), `djc/bb8` (dependabot only), `hgrecco/pint` (NOASSERTION licence, 13 AI-marked commits in 90
days, units parsing collides with numbat-parse-unit-expressions). All dead.

### agB (TS/JS, 419 rows -> 20 past triage): one borderline survivor

Kills (reason): smogon/damage-calc (lane in maintainer's open #391 + sibling vgc-multicalc ships it),
weizhenye/danmaku (736-LOC engine, karma/Chrome tests), discoveryjs/cpupro (no test CI), borewit/
music-metadata and foliojs/pdfkit (>= 2 signature accounts each), excaliburjs/excalibur (maintainer
shipping every lane, v1 churn), LittleJS / melonJS (AI sweeps 257/375 and 104/124), shifty / zrender /
geobuf / ngraph.graph (no commits), style-dictionary (218 open issues cover the kernel), galacean
effects-runtime / two.js / lo-th/phy (no test CI), automerge (Rust core), p2p-media-loader (v5 core
rewrite in an open PR), dataform (Bazel, Google team).

**Survivor: gkurt/tegaki** (3,090 stars, MIT, TS 79%, created 2026-03-28, 24 human commits / 90d by
the maintainer, 0 AI-marked; root AGENTS.md + CLAUDE.md + .claude = ranking penalty; `ci.yml` runs
`bun run test`, green on main). Lane: **pen-travel timing** - replace the fixed `glyphGap` with a
pen-lift travel time proportional to the em distance between the end of one stroke and the start of
the next (glyph to glyph, and from the word's last body stroke to each deferred dot). Shared kernel:
`TimelineEntry` offsets / `strokeDelays` / `totalDuration` in `lib/timeline.ts`, consumed by the canvas
engine, the SVG/CLI export and `render-elements`. Named traps: dot-phase anchoring (timeline.ts
~354-370), stagger interplay (`StaggerScheduler`, :164), shaped vs grapheme position sources (:399 /
:480, RTL), `finalize` trailing-gap stripping, and the SVG export ignoring `strokeDelays` today
(svgExport.ts:96, :212). Sketch 250-290 eff against the stagger-mode commit d358cbdd (~100 eff).
No issue/PR hits for the lane; one signature account (`tabbymarshlwio0-rgb`, one docs PR, outside the
lane: note). Clone kept at `s_0923h18/agB/tegaki`. Adjudicated below.

### agC (Go/Rust/C++/Java, 395 rows -> 26 past triage): one conditional survivor

Kills: askama (Jinja-named lanes, weekly parser/generator features, open PRs #536/#324), google/pprof
(3 signature accounts), go-co-op/gocron (AI audit sweep + signature PR in core + 4 copilot PRs),
bazel-gazelle (v2 rewrite across every lane), cmkr (3.5k LOC, lane exists), JoltPhysics (famous,
textbook lanes, maintainer everywhere), goplus/xgo (compiler churn + CLAUDE.md), zizmor (maintainer
ships every audit), litiengine (534 agent-style commits/90d), quartz / kraken2 / esProc (Req 7: no
test workflow), microsoft/tgrep (30/35 AI), foxglove/mcap (33/46 AI + format spec), evtx (external
spec, CI only on PR), cabin (874 commits/90d one account), kapacitor / badgerhold (no code commits),
asciigraph / bumpalo / muparser / sarulabs-di (surface too small; muparser commits from a `claude/`
branch), oak (window drivers only, GUI deps), RoaringBitmap (format spec + AGENTS.md).

**Survivor (conditional): TNG/ArchUnit** (3,840 stars, Apache-2.0, Java 99%, 76 human commits/90d by
hankem / schulzjo-tng / TheManWhoStaresAtCode, 2 AI-marked from outsiders, no root AI files, `CI`
green on main 2026-09-21). Lane: **hierarchical (nested) layers in `LayeredArchitecture`** - a layer
declares sublayers whose access rules govern only sibling traffic inside the parent, while parent
rules treat all descendants as the parent's own layer. Shared kernel `LayerDefinitions.
containsPredicateFor(...)` (Architectures.java:496-531) feeding the own-layer allowance (323-337),
`consideringOnlyDependenciesInLayers` (747-755), the contained-in-architecture check (449-459),
empty/optional layers (243-252, 305-311) and the description (209-223, which is also the frozen-rule
key); `OnionArchitecture` delegates to it too. Named traps: own-layer union vs child scoping,
descendant inclusion, optional layers across nesting, copy methods dropping state (repo history shows
this bug twice: "losing contained check after `as`", "losing optionalLayers after `as`"), description
determinism. No issue/PR/sibling hits. Sketch 230-290 eff against the whole `LayeredArchitecture`
(281 eff) and `OnionArchitecture` (146 eff): needs a second lever. Risks: closed #270 answered
"combine slices and layeredArchitecture" (partial composition route), JVM toolchains 8..25 in
buildSrc, 171 open issues. One signature-style account (`arimu1`, one GeneralCodingRules PR, outside
the lane): note. Clone kept at `s_0923h18/agC/archunit`.

### agA (Python, 308 rows -> 21 past triage): one survivor

Kills: GenSON (24/31 AI-marked), hyperbase / ursina (no test workflow), MidiTok (Tests failing on
main 10+ runs), investing-algorithm-framework (tests failing + Copilot/agent workflows), Yamale
(startup_failure since June), astropy (main CI failing 09-17..09-22; the uncertainty lane is also
maintainer-owned, #20455), apscheduler (2 signature accounts in the trigger lane), puncover
(callgraph core being built by contributors, CI only on PRs), extropic-ai/thrml (only lane ~120-170
eff, maintainer rewrite PR #56), spack / skylos / copier / angr / numba (team or solo feature streams
across every lane), tinytag / croniter (famous specs), keleshev/schema (one-file validator), metpy
(ours already, catalogue).

**Survivor: bayesian-optimization/BayesianOptimization** (details in the dossier below).

## Adjudication of the three survivors

| | bayes_opt (search-space migration) | ArchUnit (nested layers) | tegaki (pen-travel timing) |
|---|---|---|---|
| Span | TargetSpace + acquisition (ConstantLiar, GPHedge) + domain reducer + save/load: 4 modules | one class (`Architectures.java`) | one module (`timeline.ts`) + SVG consumer |
| Guard #1 (uniform wrap) | partial: a decode/re-encode helper covers point arrays only; reducer arrays, cache, constraint values and load-migration need separate per-parameter logic | no | partial: travel is one formula at every gap |
| Guard #2 (single-subsystem transform) | clears (cross-module integration) | at risk | **trips it**: a fully specified timing transform, "compute the right offsets" (reindex/derivable-maths ceiling, L83) |
| Latent base bugs on the kernel (F-39) | two, verified: `ConstantLiar._copy_target_space` zips keys with per-DIMENSION bounds (acquisition.py:1025), `_state_to_dict` writes `pbounds` as `_bounds[i]` per KEY (bayesian_optimization.py:432) | copy methods historically drop state (2 fixed bugs) | SVG export ignores `strokeDelays` (svgExport.ts:96/212) |
| Competitor accounts | none (quuger is a named student, in-lane refactor merged May) | **two signature-style accounts** (`arimu1`, `DragonFSKY`: scattered PRs across log4j2/jetty/gradle/mockito/jersey), both outside the lane = at the reject threshold | one (docs PR), note |
| Docker | pip numpy/scipy/sklearn, 167 tests, deterministic 3x, ~65 s | Gradle + JDK toolchains 8..25, heavy | bun binary to bake, young repo |

Verdict: **bayes_opt is RANK 1**; tegaki and ArchUnit are fallbacks (tegaki fails guard #2 unless the
lane is widened; ArchUnit sits at the signature-account threshold and needs a second lever).

---

### bayesian-optimization/BayesianOptimization - 8,714 stars - RANK 1

- **URL / stars:** https://github.com/bayesian-optimization/BayesianOptimization - 8,714 (penalty band
  5000+, admitted under relaxation R1; the capability is repo-internal, not a famous spec).
- **Language:** Python 99.5% (languages API: Python 253,776 B; Batchfile/Makefile/Shell trace). Pure
  Python; deps numpy / scipy / scikit-learn (wheels), lower-bounded per Python version.
- **Domain:** Bayesian optimisation engine (GP surrogate, acquisition functions, sequential domain
  reduction, typed parameter encoding, JSON state persistence).
- **Open issues:** 7 open issues+PRs total (tiny tracker, R2: no penalty).
- **License:** MIT, LICENSE read (Fernando Nogueira 2014); no vendored code.
- **Last commit:** 2026-08-21 (`Spelling error in advanced tour`, #619). 12-month code stream: `.predict`
  (#593), combined kernels (#597), `.max()` for categorical (#601), pbounds type mismatch (#607),
  state dict refactor (#609), GPHedge duplicates (#613). Low velocity, real code: Requirement 6 passes.
- **Requirement 7:** `run_tests.yml` green on master (2026-08-21, 2026-07-21).
- **Requirement 0 (platform picker):** OWED.
- **Test framework:** pytest, behavioural through the public API (`BayesianOptimization`,
  `TargetSpace`, acquisition classes), fixed `random_state` everywhere.
- **Baseline determinism:** 167 passed x3 (68 s / 61 s / 64 s), `tests/test_notebooks_run.py` excluded
  (runs notebooks). Local, Python 3.12. The per-test JUnit diff across runs is still owed at authoring.
- **Docker:** Pattern B, `olympus-base-python` + pinned numpy/scipy/scikit-learn wheels. Estimate only,
  not built.
- **Architecture:** `target_space.py` (typed params -> float encoding: `make_masks`,
  `calculate_bounds`, `params_to_array`, `_to_float` / `_to_params`, duplicate cache keyed on encoded
  tuples, constraint values), `acquisition.py` (ConstantLiar pending `dummies`, GPHedge
  `previous_candidates`, per-acquisition `get/set_acquisition_params`), `domain_reduction.py`
  (per-dimension bound history, float-only by design), `bayesian_optimization.py` (register, suggest,
  `set_bounds`, `save_state` / `load_state` via `_state_to_dict` / `_load_state_dict`).
- **Capability-lane density (Stage 2c):** the 12-month stream is small fixes by rotating contributors;
  no one is building search-space editing. Lanes the tracker names and we avoid: conditional
  parameters (#89/#168, maintainer called them out of scope), sum-to-1 constraints (#190).
- **Maintainer-welcomed lanes (Stage 2d):** none found; no removal record for the lane.
- **Self-collision:** no approved/in-flight problem on this repo or on Bayesian optimisation.
- **Exclusivity / magnet:** tracker searched (add/new/remove parameter, set_bounds, change bounds,
  categorical bounds, warm start, load_state, search space change): nothing asks for this; #486
  (bounds transformer after loading logs, closed) is adjacent, not the capability. Sibling check: no
  library remaps BO-encoded state (Optuna / Ax keep parameterisations as dicts, a different
  architecture).
- **Missing machinery (LOC carry):** today `TargetSpace.set_bounds` refuses any change of parameter
  type or total dimension (target_space.py:687-714). There is no remap of stored observations, cache,
  constraint values, pending ConstantLiar dummies, GPHedge candidates or reducer arrays, and
  `load_state` cannot load into a different space.

**Lane - carry an optimizer's state through a changed search space.** Let a running optimizer add,
remove or retype parameters and add/remove categories, then migrate everything it holds: registered
points and targets, constraint values, the duplicate-point cache, ConstantLiar's pending dummies,
GPHedge's previous candidates, and the sequential domain reducer's per-dimension state; and make
`save_state` write a faithful space description so `load_state` can migrate a saved run into a
different space. It exists only because of this repo's own encoding (one-hot categoricals with
`dim > 1`, masks, typed round-trips), which is why it needs repo nouns to describe.

**TRAP SEAMS:**
| Pattern | Present | Evidence |
|---|---|---|
| F-39 inherited helper bug | yes | `ConstantLiar._copy_target_space` (acquisition.py:1025) zips keys with per-dimension bounds; `_state_to_dict` pbounds (bayesian_optimization.py:432) indexes `_bounds` per key. Both are latent today and reached once a categorical meets ConstantLiar or save/load |
| F-9 cross-stage drop | yes | the persisted state (JSON) vs the live encoding: migration-on-load must reuse the same remap as the live path |
| F-10 cross-product | yes | change kind {add, remove, retype, category add/remove} x state holder {plain, ConstantLiar pending, GPHedge, reducer, save/load} |
| F-34-like aliasing | check | reducer keeps `original_bounds` / `bounds` history arrays sized to the old dimension (domain_reduction.py:~95-110); `_remove_expired_dummies` (acquisition.py:1039-1056) broadcast-fails on stale widths, a misdirecting error far from the cause |
| F-15 | no | |
| F-1/F-2/F-13/F-14 | no | |

**Estimated complexity:** ~300 eff (agA sketch: remap + decode/re-encode with a drop policy 80, fill
values + validation 20, constraint + cache rebuild 35, acquisition-state remap 60, reducer remap 40,
serialization + migrate-on-load 45, touch-ups 20), measured against `set_bounds` (~25 eff) and
`_load_state_dict` (~40 eff). 4 files, 1 package.

**Stage 6 death-class guard (run):** (1) one shared kernel (the TargetSpace encoding) feeds six
surfaces, and a local fix in TargetSpace leaves stale-width dummies/candidates/reducer arrays that
break later in unrelated calls: PASS. (2) traps are interdependent (column shift propagates to every
holder; drop policy must hit params, targets, constraint values and cache together; load-migration
must agree with the live path): PASS. (3) no standalone file: PASS. (4) TOO-EASY guard: #1 partial
(point arrays share one re-encode helper, the reducer / cache / serialization do not), #2 clears
(cross-module), #3 the drop/fill policy must be stated but the integration sites survive being named,
#4 not a port, #5 survives full specification. The escape to defeat in tests is "rebuild a fresh
optimizer and re-register `res`" (~40 LOC): tests must require pending ConstantLiar dummies, GPHedge
gains/candidates, reducer contraction state and random-state continuity to survive.

**Risks:** famous library (invisible pipeline competition cannot be measured); maintainers mark
non-float parameters "experimental" (target_space.py:275), so a reviewer may read part of it as bug
fixing; low commit velocity; the rebuild escape above; the drop/fill canonical form must be pinned in
meta.md. Clone kept at `worktrees/_hunt/s_0923h18/agA/bo` (HEAD af8b928), venvs deleted.

### Fallbacks

- **gkurt/tegaki - pen-travel timing** (clone `s_0923h18/agB/tegaki`). Fails guard #2 as scoped: widen
  it with a genuinely second subsystem (the SVG/CLI export and `render-elements` consumers, plus the
  layout-dependent position source) before authoring, and smoke-test for the derivable-maths ceiling.
- **TNG/ArchUnit - hierarchical layers in `LayeredArchitecture`** (clone `s_0923h18/agC/archunit`).
  Two signature-style accounts (`arimu1` #1686, `DragonFSKY` module descriptions) sit exactly at the
  softened reject threshold though both are outside the lane; composition via slices is a partial
  existing route (#270); JVM toolchains 8..25. Needs a second lever (Onion sublayers or qualified
  layer paths in violation text).

## Budget spent

Proven pool (exhausted, 10th session), hint rows (coal, cruise-control, plush/argc/shipyard/jql),
cached-index re-adjudication (20 unlogged engine siblings probed; textX, pysteps, nutils, coal checked
in source), fresh sweep 1 (the 1,122-row never-adjudicated residual, three screening agents, 67 repos
past triage, 3 survivors). Fresh sweep 2 was not needed.

## Result: CANDIDATE - bayesian-optimization/BayesianOptimization (RANK 1)
