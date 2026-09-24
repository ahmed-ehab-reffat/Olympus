# REPO-HUNT 2026-09-23-K (hunter #24, CONSECUTIVE_MISSES=0)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=0: no extra softening beyond the permanent
2026-09-09-B rules. Standing rulings: AI root file = ranking penalty; AI commits/trailers =
lane-scoped (SKILL 2b softened). Mandatory fork-branch exclusivity scan on every lane audit.

Method (hunt #23 hint): re-check kill rows whose recorded reason was a TRANSIENT state (Req-7 red
CI, "finished"/dormant label, a competitor PR that was open, an open maintainer refactor), verify
with live API state / live test runs, then the unchanged hard rules (licence incl. vendored, >=500
stars, activity, language share, quota), lane audit, Stage 6 guard, fork scan.
SATURATED-REPOS.md is NOT edited; stale rows listed at the end.

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Excluded up front: every LEDGER repo (vrp, pict, BayesianOptimization, teavm, piscsi, pyOCD,
siliconcompiler, pyfakefs, libspatialindex, csbindgen, oxipng, messageformat, stremio-core,
openglobus, dyn4j), turmoil, hayro, urbansim, tegaki, ArchUnit, genqlient, capnproto, and every repo
adjudicated in the 09-23-C..J logs.

Scratch: `worktrees/_hunt/s_0923h24/`.

## Step 1 — transient-kill inventory (live API state, 2026-09-23)

Sources: every SATURATED-REPOS.md / hunt-log row whose kill reason was Requirement 7 (red or absent
CI), "dormant"/"near-corpse"/"finished", a REVISIT condition, or a maintainer workstream/rewrite.
91 Req-7 slugs re-checked live (`s_0923h24/req7_check.sh` -> `req7_out.txt`: default-branch test
workflow conclusions + last commit), 19 dormant rows re-checked for commits since 2026-06-25.

**Transient state that CHANGED (re-open candidates):**

| Repo | Recorded kill | Live now | Verdict |
|---|---|---|---|
| SciTools/cartopy | "DEAD (red CI)" (09-19-E) | main 2026-09-17 `Tests`: 22/23 matrix jobs green, the one red job is windows-3.11 `test_natural_earth_custom` (network-feature image compare, `fiona fread` error); PR runs 09-22/23 fully green | RE-OPEN, lane audit below |
| taskiq-python/taskiq | Req 7b, 3 red `Testing taskiq` on master (09-21-B) | latest master runs green (09-17 17:07) | RE-OPENED then DEAD, see below |
| pubkey/event-reduce | CI failing (09-09-B; J "not re-opened") | CI green 2026-09-16 | RE-OPENED then WEAK, see below |
| tdewolff/canvas | Req 7 red (08-29, 09-01), "REVISIT if master goes green" | still red 2026-09-13, but only `renderers/pdf TestPDFText/without_subset` (output-size assertion 505146 != 521000+-1000); core package green | RE-OPENED then DEAD, see below |

**Transient state UNCHANGED (still dead):** verde (main `test` red since 08-04), EmuKit (main
`Tests` red 08-24; fix only on the `andrei/gpy-update` PR branch), xoolive/traffic (red), OpenMDAO
(red + NOASSERTION), scryer-prolog (red), amaranth (red), canmatrix (red, alternating), DIE-engine
(red), javaparser (red), laika / lotusdb / adsb_deku / BoomFilters (red or no test runs, <=1 commit
in 90d). Dormant rows (0 commits since 2026-06-25): kapture, ezno, mtail, lifelines, statig,
ergogen, gosl, VROOM (last 2026-03-17), argmin (last 2025-10-02), lexy (2025-10-18), particles,
atopile, adsb_deku. Near-corpses still near-corpses: avr8js (4 commits: 1 release + deps),
maker.js (dependabot only). chempy woke (21 commits/90d) but the row's absorption reason
(numeric machinery in the author's sibling packages) is structural, not transient.
Workstream rows: please #3565 CLOSED unmerged (please adjudicated in 09-23-I), tinywasm still
mid-feature-wave on `next` (v0.11.0 on 09-19, WASI p1 + c-api + GC in the last 10 days, approved
same-repo sub), Stim adjudicated in 09-23-C/E/G.

### tdewolff/canvas — DEAD (lane density via a fork, Req 7 still red)
Red master is only the PDF output-size assertion, so Req 7 alone would be scopeable. But the
08-07 "untouched surface" (renderer clipping) is now EXCLUSIVITY-DEAD: fork
`anaelorlinski/tdewolff-canvas` branches `ao`/`ao2`/`ao3` (21-22 commits ahead) carry
"feat(renderer): add capability interfaces for clip, opacity groups, and pattern fills"
(canvas.go +305, rasterizer.go +541, pdf/writer.go +357, svg.go +21, clip_test.go), plus text
feature synthesis, CFF embedding, gradient stops and a Clipper2 boolean backend; issue #391 shows
the maintainer pulling that stack upstream ("I'd like to pull in most of the commits"). Bentley-
Ottmann lane = anaelorlinski/aldernero PRs #382/#392-394 + `fix/bo-*` branches. SVG-parse lane =
Mitsutan feature PRs. No lane left that needs machinery the repo (or the fork) does not own.

### taskiq-python/taskiq — DEAD (competitor accounts + PR-blanketed lanes)
CI green now, but PR profiling: `Sanjays2402` (recorded signature) merged #652 in the receiver
lane, and `Kuang-xianxin` (created 2025-11, 0 followers, no name, PRs across Scrapling, nanobot,
hermes-agent, huey, haystack, datasets, ...) has #671 open in the scheduler lane = two signature
accounts. The open queue blankets the remaining lanes: scheduler plugins #663, worker-side batching
#634, ack progress #640, skip_result #656, receiver/inmemory hardening #643/#644, wait_result
tolerance #657. Famous-domain (Celery-nameable) features on top.

### pubkey/event-reduce — WEAK (thin repo, one burst)
CI green; Copilot commits are CI/deps only (note). But 3k LOC TS whose core is a GENERATED BDD
(`bdd.generated.ts`, produced by an hours-long truth-table fuzzing run with the author's sibling
`binary-decision-diagram` package); every capability is a new state function or action arm in two
registries (missing-arm absorption), and the 12-month stream is one release burst (2026-03-17).

### SciTools/cartopy — WEAK (re-opened on stale Req 7; no RANK-1 lane)
Mechanical (2026-09-23): ★1619, BSD-3-Clause (single LICENSE, no LGPL headers left from the pre-0.22
licence; `grep -rl "GNU|LGPL" lib` = 0), Python 98% + Cython 2%, quota 0/6, 70 human commits in
6 months (greglucas, QuLogic, rcomer, dopplershift, DavidVadnais), 0 AI marks in commits (greglucas
discloses AI help in the body of open PR #2647 = note). PR authors: no recorded signature account,
none in the LabTesing/deepswe list; DavidVadnais = real identity (satellite/radar modeller).
**Req 7 re-measured: the "red CI" kill is stale.** Local `pytest -m "not network" -n 8` in a venv
(pyproj 3.8.0, shapely 2.1.2): 867 passed / 10 skipped / 2 xfailed, identical 3x, ~60 s, hash seed
unpinned (G-PY1 clean).
Lanes checked:
- Geometry projection pipeline (trace.pyx -> stitch -> attach_lines_to_boundary ->
  rings_to_multi_polygon): measured a real F-1 gap (adjacent Geodetic polygons projected to Robinson
  / LCC / Mollweide overlap by ~0.07% of their area; shared edge intersection is a MultiPoint, not a
  line; Orthographic consistent), BUT it is #1039 (open since 2018, maintainers discussed the fix)
  and maintainer PR #2647 "Adaptive line resampling" (greglucas, OPEN, trace.pyx + crs.py) states
  "The major improvement here is projection symmetry, so that any projected path A->B is identical
  output to a path B->A". PR #2658 (greglucas, OPEN, crs.py +344/-324, trace.pyx +58) overhauls
  `_attach_lines_to_boundary`; #2651 (jackbenn) ObliqueMercator inside-out. EXCLUSIVITY-DEAD.
- Z preservation through `project_geometry` (invented; measured: LineString Z -> 2D output, Point Z
  -> 2D, the interior-ring inversion path emits Z=0 via the GEOS box difference; no issue or PR asks
  for it; PR #989 only READS Z in shapereader): ~150-200 eff (trace Point struct + interpolators +
  project/project_points with z, boundary-vertex Z rule, inversion path). Stage 6: shared kernel yes,
  but traps mostly independent and self-revealing (shapely raises on mixed 2D/3D coordinates), close
  to a uniform "thread z through every stage" wrap, and a post-pass (inverse-map output vertices to
  source parameters) is a viable shortcut. FAILS guard Q2/Q4 -> not RANK 1.
- EPSG/pyproj-derived bounds: long-open magnets #813 (2016), #1911 (2021) + closed PR #1888 diff.
- Vector transform: open PR #2718 (angular CRS linearity). Gridliner: greglucas' current workstream.
  Tiles: PR #2602. CF constructor PR #2548, Winkel tripel PR #2442, LCC extent PR #2597.
  Regrid/interpolation: named methods with sibling libraries (pyresample, xESMF).
Venv + clone kept at `s_0923h24/{venv_cartopy,cartopy}` (no build output besides the 1 .so).

### Dormancy re-check (132 slugs from corpse/dormant/recency rows, `s_0923h24/dorm_out.txt`)
Code commits since 2026-06-25 (deps/bump excluded). Rows that WOKE but whose recorded kill was a
different reason are unchanged (psd-tools AI sweep, quamina lane density, jsongrep / hucre / LibPDF /
bibtexparser hot solo programme, mq too-easy shelf, yauaa Gate 5, lopdf lane density + binggao1230,
motis team velocity, Pynite competitor, please / beartype / neva / verible / geogram / gtsam /
pyomo as recorded). The one row whose ONLY kill was dormancy and that woke:

### exo-lang/exo — DEAD (public-branch rewrite + in-lane sweep)
★743 MIT, Python 94%, recorded "corpse or near-corpse". Now 9 code commits in 90 days, CI green.
But `main` is the quiet surface of a live programme: `akeley98` holds 60+ branches IN the main repo
(Exo-GPU: `spork*`, `camspork*`, `wgmma`, `tma_*`, `endgame` pushed 2026-09-15), i.e. a public,
unmerged rewrite of scheduling/codegen; plus `codex/update-arraydomain-to-linear-decision-diagram-ldd`
and `claude/err_tests` branches. The merged stream is `sueszli`'s codegen-correctness sweep (7 PRs
on 2026-08-30: floor div/mod, constant folding, extern bounds, helper-name collisions, index
width). Scheduling primitives are a ~60-op registry (missing-arm absorption); tests are golden C
snapshots. Every lane is either on a public branch or in the sweep.

## Stage 0-bis / cached index
Proven pool: nothing new to mine (hunt #23 group P re-judged all 9 pool re-opens; J log); not
re-derived. Cached index: the band, residual, sibling, delta and misc-language sweeps (09-20..09-23-H)
are exhausted; not re-fetched. Union of every seen list rebuilt as `s_0923h24/allseen_k2.txt`
(49,766 slugs) and every slug ever written in a log/brief/screen file as `logged.txt`, so the fresh
sweeps below only surface never-fetched or never-judged rows.

**Probe while building the union: `band_misc.jsonl` (the 09-19 Jupyter/Cython/TeX/... sweep) was
INCOMPLETE.** `jax-md/jax-md` (★1463, Apache-2.0, primary language Jupyter Notebook, pushed
2026-08-18) matches its query and is in no seen list. Fresh sweep A (below) re-runs that axis.

### jax-md/jax-md — DEAD (sibling-library + public legacy branches + team wave)
Apache-2.0 only (grep for GPL/LGPL = argnums false positives), Python 2.0 MB vs Jupyter 6.1 MB
(Python #2 at ~25%, clears the xcc language-share bar; Req 0 OWED), `Build` green on main
2026-08-18. Genuine academic contributors (abhijeetgangan 41 PRs, venkatkapil24, DRosen285,
mitkotak), no signature account. But: every capability is a named MD algorithm (integrators,
thermostats/barostats, FIRE, force fields, neighbour lists) mirrored by siblings (torch-sim ports
the jax-md API to PyTorch; ASE, OpenMM); 60 public branches hold old lanes (`holonomic-constraints`,
`rigid_body_per_body_state`, `radial_distribution`, `eam`, `neighborlist_refactor`, `npt_fix*`,
`2d-langevin-rb`); open PRs #422 NPT Langevin, #410 Martini force field, #420 vivace; the 2026
stream is a team capability wave (UMA/MACE/bio-mlff ports, AMBER/OPLS-AA, CSVR NPT, PreCon FIRE).

## Fresh sweep 1 of 2: GitHub-primary languages outside the band (re-run of the incomplete band_misc)
`s_0923h24/sweepA_langs.py`: `language:{Jupyter Notebook, Cython, Cuda, TeX, HTML, Svelte, Vue,
CMake, Shell, Makefile, Starlark, Scheme, Assembly, Roff}` x 6 allowed licences x 4 star bins
(500-6000), pushed > 2025-12-01 -> **2,037 rows, of which the 49.8k-then-78.8k seen union already
held most** (fix: the seen builder had skipped the `name` key used by band_misc/band_hi jsonl;
rebuilt to 78,844 slugs). 221 non-Jupyter + ~430 Jupyter rows never seen; after dropping apps,
UIs, courses, model/paper repos: engine-shaped survivors = jax-md (DEAD, above), EvgSkv/logica,
google/jax-cfd, k2-fsa/k2, google/edward2, matplotlib-venn, KDEpy, jMetalPy, aihwkit.
- **EvgSkv/logica (★2140, Apache, Jupyter 8.0 MB / Python 1.0 MB)** — WEAK: logic language compiling
  to SQL (SQL class + language-surface carve-out), solo firehose (100 commits/12mo, "Neural
  recursion", "Top-k-proofs learning" x9, no PRs), golden-SQL tests across engines.
- google/jax-cfd — DEAD: README notice "JAX-CFD is no longer maintained" (2026-02-24).
- k2-fsa/k2 — DEAD: FSA/FST algorithms (OpenFst sibling), CUDA-primary build.
- edward2 / KDEpy / jMetalPy / matplotlib-venn — named-algorithm catalogues or tiny; aihwkit needs
  a pybind/CUDA build for a 513-star repo. None carries an invented, repo-model lane.
**Sweep 1 result: 0 survivors.**

## Fresh sweep 2 of 2: 111 single-word topics absent from every earlier topic list
`s_0923h24/sweepB_topics.py` (jax, ray-tracing, n-body, behavior-tree, statecharts, rule-engine,
symbolic-execution, abstract-interpretation, e-graphs, parser-combinator, template-engine,
rich-text, operational-transformation, physics-engine, collision-detection, inverse-kinematics,
motion-planning, kalman-filter, ode-solver, sparse-matrix, constraint-programming, timetabling,
bin-packing, suffix-array, entropy-coding, colorimetry, nurbs, csg, sdf, bvh, r-tree, geohash,
map-projection, ...), stars 500-8000, pushed > 2025-12-01 -> 1,355 rows, 653 in-language and
allowed-licence, **11 never seen or logged**: flax (★7.3k, famous NN library), pyprobml (book),
react-d3-tree (UI component), deepsvg (paper), jax-cfd (unmaintained), kglab (dormant),
geospatialdatascience / geog-312 (courses), sindresorhus/figures (symbol table),
kaggle-tpu-lab (LLM), fasouto/termaid (★527, created 2026-02, Mermaid renderer: every lane is a
Mermaid-syntax feature = spec-named support matrix; 6 Claude-co-authored commits).
**Sweep 2 result: 0 survivors.** The topic space is ~98% already fetched.

## Stage 6 guard
No RANK 1 to guard. The only lane that reached a guard run (cartopy Z preservation) failed Q2
(independent, self-revealing traps: shapely raises on mixed 2D/3D coordinates) and Q4 (close to a
uniform "thread z through every stage" wrap, with a post-pass shortcut), so it is not handed over.

## Stale rows for the human (SATURATED-REPOS.md not edited)
- 09-19-E "cartopy DEAD (red CI)" -> stale: main is 22/23 green (one windows image flake), local
  867 passed x3. Cartopy's real blockers are now lane-level (#2647/#2658 maintainer PRs, #1039,
  #813/#1911 magnets), recorded above.
- 09-21-B taskiq "Requirement 7b" -> stale (master green 09-17); real kill = Sanjays2402 +
  Kuang-xianxin (two signature accounts) and a PR-blanketed scheduler/receiver/ack surface.
- 09-09-B event-reduce "CI failing" -> stale (green 09-16); real read = thin generated-BDD repo.
- `:867` / `:109` canvas: still red, but only `renderers/pdf TestPDFText` (output size). The
  "untouched clipping surface" note is now EXCLUSIVITY-DEAD (fork anaelorlinski/tdewolff-canvas
  `ao2`/`ao3` "capability interfaces for clip, opacity groups, and pattern fills").
- `:977` exo-lang/exo "corpse" -> awake (9 commits/90d) but the live programme is 60+ `akeley98/*`
  Exo-GPU branches in the main repo plus `codex/` and `claude/` branches.
- `band_misc.jsonl` (09-19) is incomplete (jax-md missing); `s_0923h24/sweepA.jsonl` supersedes it.
- Tooling bug for the next hunter: seen-set builders must read the `name` key (band_misc/band_hi
  jsonl) as well as `fullName`/`full_name`; `s_0923h24/allseen_k2.txt` (78,844) is the fixed union.

## Budget spent
Transient re-check: 91 Req-7 slugs + 132 dormancy slugs + 8 workstream rows re-measured live;
4 re-opened (cartopy, taskiq, event-reduce, canvas) + exo + jax-md audited. Two fresh sweeps
(2,037 + 1,355 rows). One local test build (cartopy venv, 393M, deleted after the 3x run; dead clones jaxmd,
canvas, event-reduce deleted; cartopy clone kept, 31M). Disk 17G free at the end.

## Result: NO-CANDIDATE
FALLBACKS (both carried from/for the orchestrator, neither RANK-1 grade): SciTools/cartopy (Z
preservation through project_geometry, ~150-200 eff, FAILS guard Q2/Q4 as scoped; needs a coupled
lever), tokio-rs/turmoil (per-host clock offset + drift, from hunt #23, conditional on closed PR #22).
