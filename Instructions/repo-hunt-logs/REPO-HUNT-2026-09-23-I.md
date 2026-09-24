# REPO-HUNT 2026-09-23-I (hunter #22, CONSECUTIVE_MISSES=1)

Unattended olympus-factory hunt. Softening at misses=1: NOT applied beyond the rules that are already
permanently softened in SKILL.md (2026-09-09-B). The whole point of this hunt is to apply those
softened rules RETROACTIVELY to pre-2026-09-10 kills.

Method (from hunt #21's hint): no GitHub band sweeps. Re-open repos whose ONLY recorded kill reason in
a hunt log dated before 2026-09-10 is a rule the 2026-09-09-B softening changed:
- velocity / commit count (now: lane verdict only, SKILL.md Stage 2c "Softened 2026-09-09-B");
- `action_required` / `cancelled` CI (now: only `failure` on the default branch kills, Req 7);
- one competitor-signature visit outside the lane (now: NOTE; reject = 2+ accounts, in-lane PR, or burst);
- zero-issue tracker (now: ranking penalty);
- outsider-nameable alone (now: MEDIUM mitigation, reject only with long-open uncommented issue or port);
- AI root file (user ruling 2026-09-23: ranking penalty) and AI trailers (lane-scoped, 2b softened).
Each re-opened repo: re-verify licence (incl. vendored), activity, language share, quota,
SATURATED-REPOS; then lane audit + Stage 6 guard + fork-branch exclusivity scan.

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Excluded up front (orchestrator): microsoft/pict, bayesian-optimization/BayesianOptimization,
konsoletyper/teavm, UDST/urbansim, gkurt/tegaki, TNG/ArchUnit, Khan/genqlient, capnproto/capnproto,
everything adjudicated in the 09-23-C..H logs, every LEDGER repo, every problems/ folder repo.

Scratch: `worktrees/_hunt/s_0923h22/`.

## Stage 0-bis — proven pool

Pool rebuilt (repos at 1-2 subs). Declared exhausted by hunts #12-#21 EXCEPT one member nobody
re-mined: **reinterpretcat/vrp** (approved `vrp-tsplib-edge-weight-types`, 3/10). Its only kill
anywhere is `SATURATED-REPOS.md:870` / 09-06 log: "every workflow run is `action_required`". That
is exactly the softened Requirement 7 (only a `failure` on the DEFAULT branch kills). It is both a
pool repo and a softened-rule re-open, so it goes first.

## Re-open list (pre-09-10 kills on softened rules only)

Grep of the 28 pre-09-10 logs for velocity / firehose / Gate-5 / capability-wave / action_required /
competitor / zero-issue / nameable kills, minus every repo re-examined in a log dated >= 09-10
(logos, cadence, Clarabel, egglog, please, simpeg, kapture, tifffile, iwe, gonum, geogram, calamine,
scikit-fem, rye, toydb, verible, Alloy, pybamm, Peroxide, moon, heimdall-rs, manifold) and minus the
orchestrator exclusions. Survivors of that filter, with the ONLY recorded kill reason:

| Repo | Log | Recorded kill | Softened rule that now applies |
|---|---|---|---|
| reinterpretcat/vrp | 09-06 | action_required CI only | Req 7 default-branch conclusion |
| optimatika/ojAlgo | 09-09 | 0 issues + 0 PRs, solo firehose | zero-issue penalty + velocity |
| jenetics/jenetics | 09-09 | "live core", solo firehose | velocity (lane verdict) |
| TimefoldAI/timefold-solver | 09-09 | commercial, 100 commits/180d | velocity (lane verdict) |
| ERGO-Code/HiGHS | 09-09 | commercial, capability-consuming | lane verdict |
| LaurenzV/hayro | 07-31 | 118 commits/90d + 11 PRs | velocity |
| uber-go/nilaway | 08-04-C | Gate 5 capability-consuming | lane verdict |
| elodin-sys/elodin | 08-02-C | 261 commits/12mo firehose | velocity |
| 0xMiden/miden-vm | 07-27 | firehose in processor+air | lane verdict |
| se2p/pynguin | 08-07-C | LLM-integration capability wave | lane verdict |
| dynaconf/dynaconf | 08-07-C | lane density on the F-13 seam | lane verdict (other lanes) |
| cuthbertLab/music21 | 08-07-C | broad capability wave | lane verdict |
| hcoles/pitest, uiua-lang/uiua, cycfi/q, sqlancer/sqlancer | 09-09-B | "capability-consuming firehose" by count | velocity (SKILL itself now cites pitest/uiua as count-only) |
| skjolber/3d-bin-container-packing | 09-09 | copilot AI-sweep + capability stream | AI lane-scoped |
| deadsy/sdfx | 09-09 | one-account burst + CLAUDE.md | AI root file = penalty; burst still a reject unless the account is a genuine contributor |
| holo-routing/holo, gorules/zen, yorkie-team/yorkie, flanglet/kanzi-go, noir-lang/noir | 08-05..09-09 | capability wave / sweep / firehose | lane verdict |


## reinterpretcat/vrp (proven pool + softened Req 7) — lane audit

**Mechanical (re-verified 2026-09-23):** ★508 (thin margin over 500), Apache-2.0 (LICENSE, no
vendored code; languages Rust 2.96 MB, Shell/Python/Dockerfile trivial), pushed 2026-09-21, 134
commits/12mo, all real code. **Req 7 now PASSES:** default branch `master` `Build` = success
2026-09-21 (the `failure` rows are dependabot PR branches, and the 09-06 kill was on
`action_required` rows, the exact softened case). Quota: 1 sub (`vrp-tsplib-edge-weight-types`,
approved). SATURATED-REPOS:870 row is the Req-7 kill only (to be corrected by the human; hunter does
not edit that file). No AI markers in the 90-day stream (solo maintainer `reinterpretcat`, no
trailers). No AGENTS.md/CLAUDE.md.

**Streams (Stage 2c).** Solo maintainer, ~130 commits/12mo, ALL in the metaheuristic lane: rosomaxa,
GSOM, dynamic heuristic, Thompson sampling, decompose search, SISR, LKH (added then removed),
VNS, path relinking, swap-star, guided ejection. That lane is capability-consuming (dead). Nothing
in 12 months touches `vrp-pragmatic/src/format/solution/initial_reader.rs` or
`vrp-core/src/solver/processing/vicinity_clustering.rs` beyond clippy. Open/closed outside PRs with
published diffs: #190 tags constraint, #181 shift balancing, #189 tag LIFO, #179 strict departures,
#163 overtime cost, #89 minimize-area — none touches the lane files (file lists read). Maintainer
merges no outside PRs (PR queue small, 4 open): mild dormancy-magnet note for those feature lanes only.
No signature account among PR authors (rtpg, kristinl, henningms, Sagmedjo, uptickmetachu, akitaylor).

**Removal records (Stage 2d first check):** CHANGELOG removed `dispatch`, the old `area` constraint,
`depot`, `hre` format, NSGA-II, push-tour-departure LS. None is the lane.

**Lane (invented from two explicit reader refusals + a measured stage-boundary bug):** make initial
solutions work across the vicinity-clustering boundary.
- F2P A (reproduced on base, HEAD 2026-09-21): a solution the solver itself wrote for a clustered
  problem cannot be fed back: `Error: cannot read initial solution 'commute property in initial
  solution is not supported'` (`initial_reader.rs:110`). Sibling refusal at `:115`: "transit
  property in initial solution is not yet supported" (breaks the writer moved into a transit stop,
  `break_writer.rs`).
- F2P B (reproduced on base, silent): an UNclustered initial solution for a clustered problem is
  accepted and the final solution comes back completely unclustered (12 single stops, commuting 0,
  parking 0) while the same problem solved without `-i` clusters 10 of 12 jobs into 3 parked stops.
  Root cause is a stage boundary: `rosomaxa/src/evolution/simulator.rs:63` runs `pre_process`
  (VicinityClustering swaps the Jobs registry for cluster jobs) and only THEN feeds
  `config.initial.individuals` (built by the reader against the ORIGINAL registry) to `on_initial`.
  The maintainer named this exact mechanism in #141 ("job1 and job2 are merged into one job in
  preprocessing step and this new job is used in internal job registry, not old ones") for the
  relations case, and fixed THAT case by exclusion; the initial-solution case was never addressed.
  (Relations+clustering is NOT the lane: the maintainer chose exclusion there, Gate 8.)
- Missing machinery (the algorithm the repo does not contain): the inverse of
  `VicinityClustering::post_process` (unpacked member activities with parking/commute back to one
  cluster activity with the member order `post_process` folds over) plus a translation of an
  individual across the pre-processing registry swap (member activities -> the cluster job the
  pre-builder made; split members -> policy), plus reader inversion of the writer's clustered and
  transit schedule arithmetic (`solution_writer.rs:163-271`: parking, forward commute on arrival,
  backward commute on departure only under `return` or on the last member under `continue`).
- Spans 3 crates: vrp-pragmatic (reader), vrp-core (processing), rosomaxa (the hook order /
  initial-individual path) + vrp-cli wiring.
- Repro setup note: the shipped example `berlin.vicinity-continue.*` has matrix profile
  `normal_car` vs problem profile `car`, so it does not cluster as-is; with the profile renamed and
  thresholds 300/600 it clusters. `--check` without `-m` panics at `checker/mod.rs:422` (unwrap on
  missing matrices) — pre-existing, outside the lane, keep tests on explicit matrices.

**Exclusivity / fork-branch scan (vrp).** 99 forks; the 19 pushed after creation had their branches
listed and 19 fork branches compared against `reinterpretcat:master` for the lane files
(`initial_reader`, `vicinity`, `clustering`, `processing/mod`, `simulator`). Only two hits, both
off-lane: `henningms/vrp:master` touches `vicinity_clustering.rs` (+1/-1, a `Jobs::new` argument
refactor) and `initial_reader.rs` (+1/-1, `core_tour.end()` -> `actor.detail.end`); `uptick/vrp:master`
deletes the clustering docs and adds `break_id`/`id: None` fields in two test files. Branch names
carry no clustering/initial-solution family (uptick: early tours, strict departures, required break,
depot objective; WasteHero: `claude/plan-multi-route-containers-*`, an AI branch in a different lane
= note; DayemSolutions: even distribution, offset break reschedule). vrp absent from
`agents/adx-labtesing-deepswe-forks.txt` and `sig_accounts.txt`; no LabTesing/blitzy fork.
Issue/PR search ("initial solution", "init solution", commute, clustering, vicinity, cluster): no
request for the lane; #141 (closed) is the relations case, fixed by exclusion; #126/#7/#72 are
reload/time-window init bugs, fixed. CLEAN.

**Derivative (2b):** outsider summary "let the solver warm-start from a solution it wrote for a
clustered problem" needs repo nouns (vicinity clustering, commute, parking, transit stop) -> LOW-MEDIUM.
Risk carried: the two refusal strings are public, greppable "not supported" markers, a mild
support-matrix-style magnet. Self-collision: our approved vrp sub is TSPLIB parsing + CLI export
(vrp-scientific + vrp-cli); this lane is vrp-pragmatic solution round-trip + vrp-core processing +
rosomaxa hook order. Different subsystem class.

**Sibling/port check:** not a textbook algorithm; VROOM/jsprit/OR-tools have no vicinity-cluster
model to crib. The capability is the repo's own stage boundary. CHANGELOG: clustering added as
"experimental" (line 431); no release ever supported commute in the init reader.

**Absorption sketch (rule 5, against the chokepoint):** decision points the lane changes:
(1) reader: rebuild a clustered member activity (arrival/departure from stop + activity interval,
minus parking on the first member, forward commute into arrival, backward commute only under
`return` or last-member `continue`, activities whose `time` the writer stripped on single-activity
stops) ~70 eff; (2) reader: transit stop -> break activity at the right tour position with its
schedule ~40 eff; (3) processing: map an individual's member activities onto the cluster job the
pre-builder made (same route, consecutive, cluster order), and a stated policy for members served
apart (cluster unassigned + members removed, so the registry stays consistent) ~110 eff; (4)
rosomaxa/vrp-core: route initial individuals through the context processing after the registry swap
~30 eff; (5) cli ~10. Total ~260 human-eff across 4 crates -> PROCEEDS (>250), with the transit
lever as the coupled second capability. Cheap shortcut that the contract must forbid: exclude
initial-solution jobs from clustering (~30 LOC) -> the contract states clusters form exactly as
without `-i`.

**Stage 6 death-class guard (RANK-1 check):**
1. Shared kernel feeding several surfaces: YES. The member-order `ClusterInfo` vector + cluster job
   is read by `pre_process` (registry), `post_process` (unpack fold), the writer (stops/parking), and
   now the reader and the individual translation. A reader-only fix (accept commute, emit ordinary
   activities) regresses into F2P B (original jobs in a clustered registry, silently unclustered
   result); a translation-only fix never sees commute-bearing input.
2. Interdependent: YES. The reader's reconstructed schedule must be the exact inverse of
   `post_process`'s fold (arrival + forward commute, `max(cluster_time.start)`, backward only under
   return/last-continue), or the translated cluster activity's schedule and the `--check`
   assignment check (`checker/assignment.rs` commute arithmetic) disagree; the split-member policy
   changes the unassigned list the writer expands (`post_process` unassigned flat_map). F-10 cells:
   visiting {return, continue} x serving {original, multiplier, fixed} x parking {0, >0} x "two
   clusters at the same location" (writer's own NOTE).
3. Standalone file: NO (reader in vrp-pragmatic, processing in vrp-core, hook order in rosomaxa).
4. TOO-EASY guard #1 (uniform wrap): no, three different inversions. #2 (single-subsystem fully
   specified transform, no hidden wall): no, the hook ORDER in `simulator.rs:63` is an F-9 hidden
   wall the prompt cannot name without giving the fix.
Verdict: PASSES the guard.

## Group A re-open screen (subagent, 10 repos) — all DEAD

| Repo | Verdict under the softened rules |
|---|---|
| optimatika/ojAlgo | gates PASS (★505 MIT, CI green on develop); series lane absorbed (~110-160 eff, no second lever), optimisation lane maintainer-owned + AI plan-branches on forks (Jimmysnielsen, Jah-yee `mip`); flaky/slow suite #670/#673 |
| jenetics/jenetics | gates PASS, clean of competitors/AI; alphabet-respecting rewriting lane ~90-130 eff, trips guards #1/#2; MOEA/GE lanes are sibling-library textbook; #616 strongly-typed GP = magnet |
| TimefoldAI/timefold-solver | every core lane in a paid-team stream + 10 Copilot trailers in lane code; OptaPlanner fork = port prior art |
| ERGO-Code/HiGHS | funded team across presolve/IPM/LP reader; lanes textbook (SCIP/CBC ship them) |
| hcoles/pitest | open-core: dense capabilities (history, cross-module aggregation) live in the paid Arcmutate product (maintainer #1390) = author-controlled sibling absorption + Gate 8 |
| sqlancer/sqlancer | Requirement 7: `ci` `failure` on every `main` push since 2026-07-31 (still kills after softening) |
| skjolber/3d-bin-container-packing | maintainer's public `boxItemConstraints` branch (102 ahead) rewrites every domain lane; FEATURES.md support matrix; AGENTS.md + copilot branches (penalties) |
| cuthbertLab/music21 | 2 signature accounts (binggao1230, youdie006) = reject threshold; sibling workspace already shipped a music21 pick |
| se2p/pynguin | 262/300 commits in 90d from one dev across every lane (GitLab-mirrored MRs); GA test generation = flakiness risk |
| dynaconf/dynaconf | 6 signature accounts, 3 AI trailers — actively mined |

**Base-mode determinism (vrp, HEAD 2026-09-21, local rustc 1.98):** `cargo test -p vrp-pragmatic -p
vrp-core` 3x without seed pinning: vrp-core 780/0, vrp-pragmatic 343/0 (9 ignored), doctest 1/0,
identical all three runs. Target (4.0G) deleted after measurement. The maintainer's "Fix unstable test"
(2026-09-19) sits in the solver lane; the builder should still run the chosen base scope 3-5x in Docker.

## Group B re-open screen (subagent, 12 repos) — 1 survivor

| Repo | Verdict under the softened rules |
|---|---|
| LaurenzV/hayro | **SURVIVOR (fallback 1).** ★771 MIT/Apache (NOTICE: pdf.js/PDFBox adaptations Apache; vendored cmaps/PDFium CC0/BSD; test fonts OFL), Rust 95.8% pure, CI main green. 07-31 kill was velocity only. `hayro-write` cold (711 LOC, last change #1282 July). Lane below |
| uber-go/nilaway | lane (multi-param function contracts) EXCLUSIVITY-DEAD: closed PR #41 diff (infer.go +569 ...) kept by maintainer "as a reference"; #259 magnet; AGENTS.md/CLAUDE.md penalty |
| elodin-sys/elodin | Req 5 (gstreamer/bevy native) + Req 7 (real CI on Buildkite, GH has a manual smoke test only) |
| 0xMiden/miden-vm | every lane in a 10-dev 300/90d stream; MASM = language surface |
| uiua-lang/uiua | language-surface carve-out + owner firehose |
| cycfi/q | lanes textbook DSP (sibling libraries) or owner-occupied (pitch/onset) |
| deadsy/sdfx | Req 7: no workflows at all |
| holo-routing/holo | Req 5 (libyang C via yang5) + 26-PR burst covering every BGP lane |
| gorules/zen | Req 5 (rquickjs C) + v2 feature wave; heavily mined |
| yorkie-team/yorkie | maintainer Claude-agent programme closing CRDT correctness gaps IN the core lanes (2b in-lane) |
| flanglet/kanzi-go | same-author Java/C++ bitstream-identical ports = port prior art + hardening sweep |
| noir-lang/noir | language carve-out + 31 AI-marked SSA/frontend correctness commits in lane |

**hayro lane (fallback 1): bake the source document's default optional-content visibility into
`hayro-write` extraction** (Page and XObject modes render exactly like the original under
`/OCProperties /D`, with no document-global OC state written). F2P basis: `primitive.rs` strips `/OC`
and the writer returns chunks, so OFF-by-default layers become visible; maintainer declined
preserving `/OC` in #1279 for that reason, so baking works inside his constraint. Missing machinery: a
visibility-aware content-stream rewriter (hidden paints -> `n` keeping `W` clips, hidden text via
`Tr 3` + restore with Tr tracked across q/Q, drop hidden `Do`/`sh`/inline images, nested BDC/BMC
stack, recursion into forms / tiling PaintProcs / Type3 CharProcs / SMask groups with fresh refs that
do not collide with the `ref_map` dedup). Sketch ~300-450 eff. Free fair oracle: hayro renders both
PDFs in-process. Stage 6: shared kernel yes; interdependent yes (state ops inside hidden sections,
BT..ET illegality of the q/clip shortcut, Tr across q/Q, shared forms with visible+hidden callers);
standalone-file PARTIAL; guard #2 BORDERLINE (single crate, walls are the copier dedup and inherited
resources). Exclusivity: PR search all states + 76-fork scan clean of baking (0xbe7a `write-preserve-oc`
is the 1-line preserve; glyphst AI fork touches interpret/ocg only). Sibling: iText 5 OCGRemover (Java,
AGPL) strips sections without state preservation -> MEDIUM cribbable core. Risks: 0xbe7a said he will
fork hayro-write privately; crate labelled "internal"; corpus via sync.py (scope base mode to
write.rs + checked-in pdfs). Owed: Gate 1 repro, 3x render determinism with simd, picker.
Ranked BELOW vrp because of guard #2 borderline and the MEDIUM sibling crib.

## Dossier — reinterpretcat/vrp — ★508 — RANK 1

- **URL:** https://github.com/reinterpretcat/vrp (canonical = same; not moved)
- **Language:** Rust, pure (Docker Pattern A proven by the approved sub: `olympus-base-rust`, `cargo fetch && cargo build --workspace`)
- **Domain:** rich VRP solver: pragmatic JSON format (reader/writer/checker), core model + features, rosomaxa metaheuristic framework, CLI
- **Open issues without PRs:** ~50 (54 issues+PRs, 4 open PRs)
- **License:** Apache-2.0 (single LICENSE, no vendored code)
- **Last commit:** 2026-09-21 (maintainer)
- **Tests:** unit tests via `#[path]` into `tests/unit`, feature tests in `vrp-pragmatic/tests/features/*` through the public solve path; behavioural, not mock-heavy
- **Baseline determinism:** vrp-core 780/0 + vrp-pragmatic 343/0 identical 3x locally
- **Capability-lane density:** metaheuristic lane DEAD (whole 12-month stream); pragmatic initial-solution + clustering boundary COLD (0 non-clippy commits); outside PR diffs (tags, shift balance, LIFO, strict departures, overtime) off-lane
- **Maintainer-welcomed lanes:** none explicit; the reader's two refusal strings are the gap markers
- **Self-collision:** approved `vrp-tsplib-edge-weight-types` = vrp-scientific TSPLIB + CLI export; this lane = vrp-pragmatic round trip + vrp-core processing + rosomaxa hook order
- **Missing machinery:** inverse of `VicinityClustering::post_process` + translation of an initial individual across the pre-processing registry swap + reader inversion of the writer's parking/commute/transit arithmetic

**Trap seams:** F-9 stage boundary (`simulator.rs:63` pre_process before initial individuals); F-49
(writer flattens a cluster into commute-bearing member activities, reader cannot re-link); F-10
cells (visiting x serving x parking x same-location clusters); F-34-adjacent (post_process mutates
routes in place); F-19 known on this repo's CLI stdout (approved sub) if the lane touches `solve`
output. F-1/F-2/F-26/F-27/F-30..32 no.

**Best feature:** "Make supplied initial solutions round-trip through vicinity clustering": the
pragmatic reader accepts every stop form the writer emits (clustered stops with parking/commute,
transit stops with breaks), and the solver maps initial individuals onto the clustered job registry
so that clusters form exactly as without `-i`, with a stated policy for members an initial solution
serves apart. ~260 human-eff across vrp-pragmatic, vrp-core, rosomaxa, vrp-cli.

**Risks:** ★508 is 8 over the floor (re-check at submit); the two refusal strings are public markers
(mild magnet); clustering is labelled experimental (maintainer may rework it); the split-member policy
is invented and must be fully stated in meta.md; solver runs are randomized, so tests should hit the
reader + translation directly and any end-to-end test must pin generations/seed and assert
structure, not cost; `--check` panics without explicit matrices (checker/mod.rs:422, off-lane).

**Still owed (PICK-FILTER):** Requirement 0 picker; Gate 1/6 already reproduced (F2P A error string,
F2P B silent unclustering) but must be re-run at the pinned BASE; Gate 7b re-run at submit;
Gate 8 six-check at scope-lock (closed-issue scan found only #141, resolved by exclusion for relations).

## Budget spent

Proven pool (one un-mined member, vrp) + the re-open list (24 repos from pre-09-10 logs, killed only
by softened rules, none re-examined since 09-10) screened in three parallel tracks: vrp (me, full
lane audit, build + repro + 3x determinism), group A (10 repos, subagent), group B (12 repos,
subagent). No fresh GitHub band sweep (hint followed). One build (vrp debug + tests, peak 4.0G,
deleted). Scratch `worktrees/_hunt/s_0923h22/` (62M: vrp + hayro shallow clones kept for the
viable picks, dead clones removed; `vt/` holds the repro inputs `pc.json`/`pn.json`/`m.json`).

Method finding for the next hunt: the softened-rule re-open list is a real source (2 viable of 24),
and it also re-surfaced a PROVEN-POOL repo that every pool pass since 09-06 had skipped because its
only kill row said Req 7. Grep SATURATED-REPOS.md kill rows for the softened reasons and cross them
with the pool, not only the logs. Corrections owed to `SATURATED-REPOS.md:870` (vrp Req 7 row is now
false: master Build green) and a new pitest row (open-core Arcmutate absorption); the hunter does not
edit that file.

## Result: CANDIDATE — reinterpretcat/vrp (lane: initial solutions across the vicinity-clustering boundary)

FALLBACKS: LaurenzV/hayro (hayro-write optional-content baking); UDST/urbansim remains the
relaxed-guard fallback noted by hunt #21 (fails Stage 6, not recommended).
