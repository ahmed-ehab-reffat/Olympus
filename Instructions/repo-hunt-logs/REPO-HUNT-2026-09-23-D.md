# REPO-HUNT 2026-09-23-D

Unattended `olympus-factory` hunt worker (hunter #16). `CONSECUTIVE_MISSES=0`, so the softening
threshold (n >= 2) was NOT reached: standard 2026-09-09-B gates, no star/issue window widened.
Standing rules (user, 2026-09-23): a root AGENTS.md / CLAUDE.md is a ranking penalty; AI commits in
the 90-day stream are lane-scoped (SKILL.md 2b, Softened 2026-09-09-B). Scratch:
`worktrees/_hunt/s_0923h16/`.

**Task (orchestrator hint from hunt #15):** probe the engine-shaped rows of
`s_0923h14/eng_pool.txt` that hunt #14 never probed, with `probe14.sh`, then `ailanes15.sh` on any
row with ai>0. Pre-filter with `seen14.txt`. No new star/size/year sweeps. Excluded: teavm
(SLICING), genqlient + capnproto (reserved TeaVM fallbacks), openglobus, stremio-core, vermin,
gauge, u-root, AeroSandbox; piscsi HANDOFF.


## Stage 0-bis proven pool

Rebuilt the pool count (75 repos at <=2 subs). No repo is new since hunt #15: the only recent
additions (siliconcompiler, libspatialindex, csbindgen, pyfakefs, pyocd, piscsi) are all in the
LEDGER. EXHAUSTED, not re-screened.

## Cached index: `s_0923h14/eng_pool.txt`

170 rows; after removing everything already probed by hunts #14/#15 or named in a 09-20..09-23 log,
**140 rows were unprobed** (`s_0923h16/unprobed.txt`). Hand-triaged by domain first (no network):
about 100 are apps, websites, LLM/ML infra, GPU/CUDA, or plain C (Provenance), and were dropped on
sight. 38 engine-shaped rows were probed with `probe14.sh` (`probe16.tsv`) and mechanical metadata
(`mech16.tsv`).

Every one of the 38 carries a root AI file (AGENTS.md / CLAUDE.md / .claude / skills), which is a
ranking penalty only under the 2026-09-23 ruling. Verdicts:

| Repo | Probe | Verdict |
|---|---|---|
| graphistry/pygraphistry | ai=1031/1573 | DEAD: the GFQL engine lane is the agent sweep |
| opsmill/infrahub | ai=531 | DEAD: repo-wide agent sweep; Neo4j-backed tests (Docker) |
| bruin-data/bruin | ai=200 | DEAD: repo-wide sweep, 571 MB repo |
| growthbook/growthbook | ai=167 | DEAD: NOASSERTION (enterprise-licensed dirs) |
| Devolutions/IronRDP | ai=143 | DEAD: protocol spec rows + sweep |
| halide/Halide | ai=120 | DEAD: sweep + LLVM build cost |
| hiloteam/Hilo3d | ai=73 | DEAD: sweep, WebGL |
| astronomer/astronomer-cosmos | ai=52 | ranks low: sweep + dbt selector syntax is a named external model |
| tombi-toml/tombi | ai=12 | ranks low: TOML + JSON Schema are named specs, solo dev with .claude |
| Apicurio/apicurio-registry | ai=16 | ranks low: Quarkus monolith, Docker cost |
| moonrepo/proto, nornir, taurus, strawberry-django | ai=8-24 | ranks low: frameworks/wrappers, no engine |
| koxudaxi/datamodel-code-generator | 358 maintainer commits/90d, root plans/skills | capability-consuming maintainer |
| paradigmxyz/solar | 433 human/90d team | capability-consuming; Solidity language-surface carve-out |
| koordinator-sh/koordinator | 51 human/90d | every scheduler lane (deviceshare, NUMA, reservation, gang, elastic quota, descheduler) touched in 90 days, LFX-mentee PR flow, flaky-test fixes. Ranks low |
| duckdb/ducklake, ispc/ispc, zeek, LLGL, MethaneKit, facebook/igl | - | DEAD on Docker cost (DuckDB / LLVM builds, GPU) |
| antgroup/vsag | ai=0 | ranks low: textbook ANN (hnswlib/faiss siblings) |
| LalitMaganti/syntaqlite | ai=0, solo, .claude | ranks low: SQL (avoid list) |
| rust-glancer/rust-glancer | ai=0 solo | ranks low: a Rust LSP, host-semantics creep (L80) |
| Myriad-Dreamin/tinymist | ai=1 | ranks low: Typst LSP, huge typst crate graph |
| audiojs/web-audio-api | ai=0, 106 solo commits | ranks low: W3C spec rows (support-matrix penalty) |
| APIDevTools/json-schema-ref-parser, mongodb/js-bson | - | ranks low: named specs, near-empty trackers |
| mittagessen/kraken | ai=0 | ranks low: torch-heavy OCR, lanes are ML |
| CircuitVerse/CircuitVerse | - | DEAD on Docker: Rails + Postgres/Redis |
| HoudiniGraphql/houdini, lightninglabs/taproot-assets, carapace-bin, spring-integration, MyST-Parser | - | ranks low: GraphQL / protocol spec / completion catalogue / mature framework / markdown |
| **cruise-control-for-kafka/cruise-control** | 17 commits/90d, ai=0 (one `Copilot` AGENTS.md commit) | **Taken to Stage 3 below** |

## cruise-control-for-kafka/cruise-control - Stage 1-3 (measured)

- **Mechanical:** 3045 stars; Java 5.2 MB of 5.3 MB (Python client 82 KB); LICENSE Apache-2.0 plus
  `licenses/linkedin-BSD-2-clause` for original LinkedIn code (NOTICE read). Only non-permissive text
  in the tree is inside the vendored swagger-ui source map: DOMPurify, dual Apache-2.0 / MPL-2.0
  (Apache option available). No stray jars. Canonical org confirmed (`linkedin/cruise-control`
  redirects here).
- **Requirement 7:** `ci.yaml` runs `./gradlew build` (unit tests) and a separate `integrationTest`
  job; last 10 `main` runs: 8 success, 1 action_required, 1 failure (09-10), latest 09-22 success.
- **Requirement 6 / activity:** 17 commits in 90 days, mostly dependency/CVE bumps, plus real code
  (`Fix Vert.x webserver implementation to respect setting`, `Ensure Executor tests use up-to-date
  cluster metadata`). 12-month heat: analyzer 0, model 1, executor 3, monitor 3, detector 2,
  cruise-control-core 0. The whole optimization engine is cold.
- **AI marks:** one `Copilot`-authored commit adding AGENTS.md (PR-template guidance for agents).
  NOTE, not a lane.
- **PR queue (44 open, enumerated):** throttling lane is crowded (#2385, #2367, #2339, #2305, #2304,
  #2214, #2148, #2145, #2370 = executor/ReplicationThrottleHelper), planner/strategy interest
  (#2223, issues #2382, #2359), goals (#2267 new topic-leader goal, #1864 BrokerSetAware colouring,
  #2288/#1721 intra-broker self-healing), Prometheus sampler (#2397, #2347, #2127). The queue fills
  faster than it merges (dormancy-magnet signal for those lanes).
- **PR authors:** `Pybsama` is a signature account (created 2026-06-17, 65 repos, 0 followers, forks of
  azcopy/NVSentinel/photon/flatbuffers/elasticgraph...), ONE PR here in the Prometheus sampler lane:
  a NOTE under the softened rule. acgtun / il-kyun / sameer-sde are identified contributors.
- **Tracker magnets in the analyzer:** weighted distribution goals (#2334), partial/scheduled
  rebalance (#2236), broker-set-aware distribution goals (#2027), BrokerReplacementGoal (#1894),
  consistent proposals (#1962), topic leader distribution (#1437 + PR #2267). All excluded as lanes.
- **Build + determinism (measured, JDK 21, Gradle 8.5 wrapper):** analyzer scoped suite (Deterministic,
  Excluded*, FixOfflineReplica, GoalOptimizer, ReplicationFactorChange, RackAware, IntraBroker,
  goals.*, kafkaassigner.*) = **512 tests, 0 failures, 3 runs, 201-236 s each**. Outcome sets are
  identical, but the parameterised test NAMES embed object identity hashes
  (`PreferredLeaderElectionGoal@147aceec-0`), so raw names differ run to run: test.sh must strip
  `@[0-9a-f]+` from JUnit names (and 3 names then collide). The random-cluster classes are slow
  (an unscoped `analyzer.*` run passed 621 tests and was still going past 25 minutes when the session
  restarted); base mode must be scoped. Build output removed; clone kept (32 MB).

### Lane considered: a data-movement budget for the goal optimizer (REJECTED at Stage 6)

No budget machinery exists (`grep -rniE "budget|maxDataToMove"` hits only the OptimizerResult
report fields), and no issue or PR in any state asks for it (`#1715` caps execution RATE, a different
thing). Seams found: net charging against `Replica.originalBroker()` (a replica moved home costs
nothing, an immigrant moved again costs nothing extra), swaps as a pair, the report's per-partition
`(int)` truncation of the LEADER's disk utilisation in `AnalyzerUtils.getDiff`, the
`initReplicaDistributionForProposalGeneration` origin on the replication-factor path, the
KafkaAssigner goals that call `relocateReplica` directly, and the proposal-cache bypass predicate
`KafkaCruiseControl.ignoreProposalCache`.

Stage 6 guard fails: (1) 27 of 30 action sites go through the four `AbstractGoal.maybe*` helpers, so
the gate is one guard at a chokepoint (Pre-Pick Guard #1, uniform wrap); (2) every accounting trap
above collapses to ONE insight, "evaluate the budget on the would-be proposal diff", after which net
moves, swaps, rounding and the RF origin all fall out (the jsondiff single-insight law); (3) the
remaining traps (KafkaAssigner path, cache predicate) are independent silent paths. Sketched ~250-340
eff but ~120 of it is REST parameter plumbing. Not handed over.

Other cruise-control lanes looked at and dropped: execution staging under transient disk capacity
(no fair canonical form; feasibility of a safe order is not decidable by a stated greedy rule),
aggregator window re-bucketing (absorbed: the sample store replays raw samples into the new window
grid), new goals / movement strategies (missing-arm class and tracker magnets), co-partitioned leader
co-location goal (per-action acceptance rejects every intermediate step of a group move, so it needs
group actions across every goal: too large to scope here, recorded as an idea).

---

# Continuation by hunter #17 (same day, `CONSECUTIVE_MISSES=1`)

Hunter #16 was cut twice by session exits without a result block. Hunter #17 continues THIS log
(append only). `CONSECUTIVE_MISSES=1`, so the softening threshold (n >= 2) is still NOT reached:
standard 2026-09-09-B gates, no star/issue window widened. Requirement 0 (platform picker) is OWED on
anything handed over. Scratch for this continuation: `worktrees/_hunt/s_0923h17/`.

## cruise-control-for-kafka/cruise-control - final verdict: SHELVED (no lane survives), idea bank only

The determinism run hunter #16 left behind (`s_0923h16/cc_det_summary.txt`) finished cleanly: 512
tests, 0 failures, 3 of 3 runs, 201-236 s each. That clears Gate 9 for the scoped analyzer suite (with
the `@<hash>` name normalisation already noted). It does not rescue the repo:

- The one invented lane (optimizer data-movement budget) failed the Stage 6 guard above (chokepoint
  wrap + single-insight collapse). A second invented lane is not allowed under Stage 2c once the
  tracker lanes are gone, and every tracker-adjacent lane here is a magnet (#2334, #2236, #2027,
  #1894, #1962, #1437 + PR #2267) or the crowded throttling queue.
- The remaining idea (co-partitioned leader co-location) needs group actions threaded through every
  goal's per-action acceptance. That is a multi-week refactor of `AbstractGoal`, not a scoped pick.
- Cost profile is also poor for an author: 200-240 s per scoped base run, JUnit names need
  normalisation, Gradle warm-cache Docker work.

Verdict: not handed over. Clone kept (32 MB, no build output) in case a later hunt finds a lane that
is not a goal/strategy/throttle row.

## Rest of `eng_pool.txt`

Re-read the 102 unprobed rows hunter #16 dropped by domain (`unprobed.txt` minus `probe_list16.txt`).
The hand triage stands: apps, LLM/ML/GPU infra, drivers, UI kits, plus the few engine-shaped rows
that fail on other grounds (gem5 and timeplus/proton on build cost, apache/drill and apache/ozone on
size and SQL, qcad on GPL, markdown-it-py and sqruff on the Python/SQL avoid list, vdaas/vald
distributed, PySR is Julia-backed). **`eng_pool.txt` is exhausted.**

## Hunter #16's unlogged sweep caches (`s_0923h16/sweepA/`, `sweepB/`) - triaged, no new fetch

Hunter #16 had also run topic/keyword sweeps whose results never reached the log (cached as
`sweepA/f3.tsv`, `sweepB/live*.tsv`, and an unfiltered `sweepB/raw4.tsv`). Triaged here with the
probe scripts (`s_0923h17/mech17.tsv`, `probe17.tsv`):

| Repo | Probe | Verdict |
|---|---|---|
| google-deepmind/torax (cloned by #16) | team of 5 shipping across every lane (transport, pedestal, solver, edge model) in 90 days | capability-consuming, DEAD |
| spacetelescope/jwst (cloned by #16) | JIRA-driven team program; CRDS reference files need network | DEAD (activity + Docker) |
| flexible-collision-library/fcl | the live home is its fork coal-library/coal | corpse upstream, skip |
| coal-library/coal | 644 stars, BSD-3 (Willow Garage text), 50 human/90d but all packaging/bindings plus one contact-patch fix; algorithm lanes cold | ranks low: collision algorithms are textbook with many sibling libraries (fcl, bullet, libccd, mujoco), so the sibling-library check kills most lanes; Eigen/Boost/jrl-cmakemodules build |
| Akkudoktor-EOS/EOS | 1670 stars, Apache-2.0, 72 human/90d, just merged "deliver complete GENETIC optimization to main" + energy-planner upgrade | capability-consuming team wave; provider lanes are a catalogue. DEAD |
| apache/casbin-pycasbin, casbin-rs | 11 / 5 commits by hsluoyz | ports of Go casbin: port law makes the parent's feature list prior art. DEAD |
| onury/accesscontrol | 2330 stars, MIT, v3 rewrite 2026-06 "turns RBAC into a full policy engine" (ABAC, deny-overrides, gates, schedules), 100% coverage + Stryker mutation gate | capability-consuming maintainer, every policy lane just shipped. DEAD |
| gobuffalo/plush | 66/90d, 58 by one contributor (Mido-sys) building a compiled VM, budgets, caches | repo-wide single-contributor sweep. Ranks low |
| yamafaktory/jql | root CLAUDE.md, solo, lazy tape evaluator just landed | ranks low: query-language surface (carve-out) + penalty |
| joaquinbejar/OrderBook-rs | 119/90d, ai=18 | capability-consuming with an agent in the stream. DEAD |
| sigoden/argc | 18 commits in 12 months, last 06-29, all sigoden features | ranks low: CLI framework class (cliffy precedent), solo feature stream |
| leudz/shipyard | 23 leudz perf commits/90d (iteration rework) | ranks low: ECS scheduler lanes have bevy as sibling prior art |
| mlpack/ensmallen | 5/90d | catalogue of optimizers (missing-arm class), Armadillo dep. Skip |
| hyperjumptech/grule-rule-engine | 2 commits in 12 months (last code 2025-11-06) | activity margin ~6 weeks; Drools-named features (agenda groups, no-loop) are magnets. Skip |
| ifandelse/machina.js | root AGENTS.md + CLAUDE.md, ai=6/23 | SCXML/statechart named model + sweep. Skip |
| behave/behave, feedparser, c2rust, others in raw4 | - | cucumber port / named formats / LLVM build. Skip |

## Fresh niche sweep 1 of 2: domain-engine topics (`s_0923h17/sweep1_domain.sh`)

~75 single-word topics (geodesy, tides, hydraulics, FEM, kinematics, motion planning, Kalman,
DSP, music notation, font/text shaping, colour science, spatial index, mesh generation, CSG/CAD,
accounting/ledger, finance/backtesting/matching engine, orbital mechanics, astronomy,
photogrammetry, point cloud, cartography). 750 raw rows; after the 28.5k-slug dead list, the licence
allowlist and the language filter, **31 live rows** (`sweep1_live.tsv`). The domain-engine topic space
is almost fully mined: most rows are apps, ML research code or GPL/AGPL. Probed the three
engine-shaped survivors:

| Repo | Probe | Verdict |
|---|---|---|
| gbeced/basana | 867 stars, Apache-2.0, solo, root AGENTS.md + CLAUDE.md, commits say "Bug fixed. Claude's fault." | the backtesting exchange lane (fill price, fees, stop orders) is the maintainer's own 90-day stream, and order-type picks (OCO, bracket) are exchange-named magnets. DEAD for this hunt |
| apache/incubator-baremaps | archived | DEAD (Req 6) |
| iTowns/itowns | 1272 stars, CeCILL-B/MIT dual, 301 issues, WebGL/Three.js | ranks low: rendering-bound tests need a GL context |

## Fresh niche sweep 2 of 2: solver/simulation/operations topics (`s_0923h17/sweep2_niche.sh`)

60 topics (discrete-event simulation, queueing, network/traffic simulation, power flow, digital
logic/HDL/chisel, CFD, thermodynamics, kinetics, SBML, population genetics, crystallography,
computer algebra, interval arithmetic, autodiff, ODE, sparse matrix, graph partitioning, auction,
voting, rating/elo, rrule/icalendar/cron, payroll, fixed income, inventory/supply chain/warehouse,
manufacturing, rostering, GA/metaheuristics/annealing/tabu/local search). 282 raw rows; the 12
topics that came back empty were re-run and are genuinely empty at >=500 stars (checked:
`discrete-event-simulation` tops out at salabim, 405 stars). **11 live rows** (`sweep2_live.tsv`),
none engine-shaped and eligible: symbolica (proprietary licence), in-toto (Python reference of a
named spec with an in-toto-golang sibling = port/sibling prior art), JAXFLUIDS (custom licence, JAX
CFD), crbnos/carbon (ERP app), openclarity (security platform), and five apps/agent-skill repos.

## Result: NO-CANDIDATE (hunter #17)

Budget spent as the contract says: proven pool (exhausted per hunter #16, nothing new since),
cached index (`eng_pool.txt` exhausted, hunter #16's unlogged sweepA/sweepB caches triaged), and two
fresh niche topic sweeps (135 topics, 1032 raw rows, 42 live, 0 surviving Stage 2c). cruise-control
closed as SHELVED. Nothing failed only a softenable gate: every death was capability-consuming
streams, port/sibling prior art, licence, archive status, or Docker/GL cost.

**What the next hunt should change (misses will be 2, so the 2026-09-09-B softening applies):**
1. Stop topic sweeps at >=500 stars. With a 28.5k-slug dead list, two sweeps of 135 fresh topics gave
   42 live rows and zero engines. The topic index is mined out.
2. Re-adjudicate the "ranks low" rows under the softened rules and the lane rule, not the repo rule.
   Best three: **coal-library/coal** (BSD, algorithm dirs cold; needs an INVENTED lane on coal's own
   model, such as contact-patch/`ContactPatch` semantics or its BVH-model update API, that fcl/bullet
   do not ship), **cruise-control** (the co-partitioned leader co-location idea sized properly, or a
   detector/self-healing lane), **gobuffalo/plush** (one contributor is building a VM; its
   interpreter-vs-VM parity is a twin-implementation seam, F-30..F-32 style).
3. Or source by dependency graph instead of topic: repos that approved-problem repos depend on or
   that depend on them (same-domain siblings of scikit-fem, sfepy, pvlib, ezdxf, pcapplusplus), with
   the sibling-library check run first.
