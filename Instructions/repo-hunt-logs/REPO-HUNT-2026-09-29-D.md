# REPO-HUNT-2026-09-29-D (hunt #38, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/decay_0929d/`. It holds:
- `lanehist.sh`: monthly commit counts per path since 2026-05-01, from the API. It is never run on
  a shallow clone.
- `streams.sh`: repo metadata, CI on the default branch, monthly commit counts since 07-01, and the
  open PR queue with authors.
- `probe_embed/`: the nilaway Gate-1 probe module.

Clones kept (small, no build output): `worktrees/nilaway` (5M) and `worktrees/osm2world` (48M, full
history).

## Standing inputs
- **Direction (orchestrator):** run a time-decayed Stage 2c re-audit of repos killed 2026-08-01..09-10
  on LANE-level verdicts (capability-consuming, firehose, maintainer shipping).
  - Method: build per-lane commit histograms, and re-open a lane only if the burst or workstream has
    moved on.
  - Hard-reason kills stay dead: licence, activity, quota, public-diff exclusivity, picker, language
    gate. I treated failing CI (Requirement 7), 2+ signature accounts or a burst, and a flaky
    baseline as hard too.
- **Excluded by the orchestrator:** Cwerg, MACS, pyOCD, pyfakefs (in flight); csbindgen and
  libspatialindex (reserved fallbacks). Also excluded: every LEDGER row and every `problems/` folder.
  rust-minidump and turmoil stay reserved as Cwerg's fallbacks.
- **Not repeated:** the discovery sweeps of hunts #34/#36 and the accepted-pool re-mines of #35/#37.
  No fresh GitHub sweep was run, so this hunt used neither the proven pool nor the cached band index.
- **Requirement 0 (platform picker):** not checkable. OWED on anything revived.
- **Softening:** misses=0. The 2026-09-09-B rules apply as written. No star or issue window was
  widened. Relaxations taken: none.

## Stage 2c: the kill list re-measured on elapsed time

A subagent extracted every lane-level kill from the 26 logs dated 08-01..09-10 (28 rows, minus the
hard-reason kills). I then measured the current 90-day streams of 30 repos.

**Decayed** means the workstream named in the kill has stopped. **Still hot** means it has not.

| Repo | Recorded kill (date) | Jul / Aug / Sep commits (default branch) | Decay verdict |
|---|---|---|---|
| uber-go/nilaway | struct-init-v2 rewrite in `assertion/` (08-04-C) | 44 / 31 / 5 | **DECAYED.** The last v2 commit was 08-08. Every lane shows 0 commits in September. Audited below. |
| nevalang/neva | whole compiler hot, typesystem workstream (09-09) | 91 / 82 / **0** | **DECAYED (paused).** Nothing since 08-23. Every commit is a maintainer `codex/*` branch. Audited below. |
| egraphs-good/egglog | `src/ast` + packed-join/container wave (08-04-B) | 46 / 46 / 13 | **Partly decayed.** Nothing merged since 09-07. But 30 open `ezrosent` PRs (e-graph comparison, packed joins, container storage) are public diffs. `oflatt-claude` plus `codex/*` branches sweep every lane. The tracker is the maintainers' research roadmap ("egglog-experimental", "avoid changing semantics"). DEAD. |
| moonrepo/moon | config / action-graph velocity (08-04-B) | 58 / 34 / 17 | Graph crates cooled (`task-graph` 0 since May). But `milesj` still ships a capability every few days (v2.6: OTel, persistent tasks, Pkl). Outsiders are also mining it: `Tyagiquamar` x3, `sghintala` x2, `rupesh-one` x2, `absolutetech108sai`. DEAD. |
| dimforge/rapier | v0.35 direct-push wave (08-04-C) | 7 / 108 / 11 | The wave landed in August. The remaining lanes are textbook physics (Box2D/Jolt sibling prior art). Star penalty band (5791). DEAD. |
| dimforge/parry | every lane (09-10-B) | 3 / 45 / 7 | September still ships capabilities: SubShapeId, deformable meshes, ray-capsule. `marknefedov` burst (3 PRs in one day). DEAD. |
| mvdan/sh | commit stream IS the gap class (08-04) | 78 / 87 / 81 | Not decayed. DEAD. |
| cerbos/cerbos | check/plan parity + PR #3312 (08-04) | 44 / 35 / 42 | #3312 merged 08-07, but `ruletable` still runs 7 commits every month. Not decayed. DEAD. |
| thought-machine/please | PR #3565 over incrementality (08-04-B) | 18 / 18 / 22 | #3565 was closed unmerged, and a closed diff is still public (unblob rule). `peterebden` is steady in core. Self-hosting Docker cost. DEAD. |
| veryl-lang/veryl | four lanes (08-05) | 340 / 530 / 401 | Hotter than before. DEAD. |
| mattwparas/steel | JIT/serialization programme (09-09-B/09-10) | 1 / 12 / 12 | Quieter. It is still a language implementation, and the port lane is contributor-owned. New outsiders on the compiler: #707 `levigross`, #677 `koalazub`. DEAD. |
| Jon-Becker/heimdall-rs | owner firehose (09-09-B) | 4 / 2 / 23 | The firehose resumed on 09-06 (nine `feat(vm)`/`feat(decompile)` PRs). DEAD. |
| uiua-lang/uiua | firehose + language carve-out | 27 / 70 / 38 | Not decayed. The carve-out stands. DEAD. |
| cycfi/q | firehose | master 0 / 0 / 1 | The work moved to `develop` (15 / 85 in Aug/Sep). Not decayed. DEAD. |
| sqlancer/sqlancer | Req 7 | 40 / 22 / 8 | `ci` still fails on `main` (09-20). DEAD (hard). |
| openfga/openfga | magnet + flaky seam package | 10 / 21 / 15 | Hard reasons unchanged: #1567 is still a magnet, and the baseline is still flaky. DEAD. |
| AcademySoftwareFoundation/OpenTimelineIO | PR blanket; "re-check after the six PRs land" | 10 / 1 / 9 | #1466, #842 and #1818 are all still OPEN. DEAD until they land. |
| maciejhirsz/logos | codegen crate warm (08-02-B) | 2 / 6 / 3 | **Decayed, but now competitor-dead.** `ChrisJr404` has a merged PR (#577, morph extras), and `maxtaran2010` has another. That is two signature accounts, the reject threshold. |
| fschutt/printpdf | pagination / layout v2 workstream (08-07) | 95 / 8 / 5 | **Decayed, but still dead.** The July wave was committed under the author name `PR Analysis` (an AI agent). Layout lives in the author-controlled sibling `azul`, which is absorption. The domain is spec-named PDF, next to hayro in the ledger. |
| rust-embedded/svd2rust | 16 PRs over `src/generate` (08-07-B) | 4 / 2 / 0 | **Cold,** but the PR blanket is still open (public diffs). The capability space is CMSIS-SVD, which is spec-named. DEAD. |
| tordanik/OSM2World | solo firehose + tag registry (09-09) | 30 / 23 / 7 | **Decaying.** Lanes checked below. |
| ovh/utask | queue size only (08-04) | 2 / 0 / 0 | Cold, but `Roshan931` filed 3 PRs on 08-21, which is a burst. No test CI on `master` since February (Req 7). DEAD. |
| TimelyDataflow/differential-dataflow | PR blanket (08-04-D) | 37 / 0 / 0 | The merged stream is cold, but the PR queue is a `frankmcsherry`/`antiguru` firehose (15 open in September). `Test build against Timely master` fails daily. DEAD. |
| elalish/manifold | maintainer shipping (09-01) | 9 / 15 / 29 | Rising. DEAD. |
| It4innovations/hyperqueue | MILP scheduler lane (08-04) | 11 / 12 / 7 | `spirali` is still in the scheduler (#1136, gap constraints). ★565. DEAD. |

**Summary: 2 of 30 truly decayed with no fresh hard kill: nilaway and neva.** The other repos
either still run their workstream, or went cold but gained a hard kill after the original verdict:
- signature accounts: logos;
- an AI-authored wave plus sibling absorption: printpdf;
- a standing PR blanket: svd2rust, OTIO, differential-dataflow;
- a burst: utask.

## uber-go/nilaway: lane audit (DECAYED, the best-quality shelved repo per 08-04-C)

**Mechanical (2026-09-29).** ★3917, Apache-2.0, 100% Go, pure. Golden-test CI is green on `main`.
Quota 0/6. No corpus collision: nil-analysis greps are empty across approved-problems, problems and
rejected.
- Penalty: `AGENTS.md` and `CLAUDE.md` sit at the root.
- Stage 2b-bis: September brought five new outside PRs.
  - `rishiraj38` (#94 len-through-local), `Michael-WhiteCapData` (#527 nested composite
    affiliation), `yamaankhan20` (#521) and `ririnto` are GSoC-style or genuine Go contributors.
    They are not the niche-lib signature. `ccuetoh` is an Uber engineer.
  - This is a NOTE, not a kill. The public tracker FP/FN list is being worked from outside, though.

**Lane histogram (API, monthly since May).** `assertiontree` 0/6/15/12/**0**. `annotation`
1/1/8/7/**0**. `inference` 1/0/5/2/**0**. `structfield`, `affiliation`, `global`, `hook`, `guard` and
`config` are all 0 in September. The struct-init-v2 burst ended 08-08 (PRs #472-#506).

**Tracker lanes, all taken or magnets.**
- Open PRs with public diffs cover: #94 len checks, #166 type conversions, #277/#387 function
  variables, #46 nested composites, #512/#514 split nil checks, #503 transitive facts and #521.
- Iterators already shipped (#288, #304).
- Multi-param contracts are exclusivity-dead (09-23-I).
- #260 user nil-check helpers is a long-open, uncommented magnet.
- #339 object sensitivity is a maintainer roadmap item, the v2 team's next step.
- #192 channels is the maintainer's own "rethink". The ok-receive is already modelled
  (`rich_check_effect.go:207-391`).

**Invented lane: promoted selectors through embedded fields.**
- *Evidence of the gap.* Both struct-init suites carry an unfixed in-tree
  `// TODO: Add support for promoted fields` (`testdata/src/structinit/local/local.go:120`,
  `structinitv2/local/local.go:122`). v2 bails explicitly on promoted methods
  (`structfieldeffects/return_contracts.go:168`, `len(selection.Index()) != 1`). No issue or PR asks
  for it: a search for embed/promoted is empty apart from the closed affiliation issues #43/#44. The
  PR-DIFF check over all 15 open PRs found no hit in the assertion tree. The only hit is #503, which
  traverses embedded fields for fact export in `inference/`.
- **Gate 1 REPRODUCED on base** (`probe_embed/`, `-experimental-struct-init[-v2]`):
  - `o.Inner.F` and `(&Outer{Inner: nil}).Inner.F` are reported.
  - The promoted forms `o.F`, `o.ValM()` (value-receiver method through a nil embedded pointer) and
    the value-embed TODO case `b.aptr.ptr` are silent false negatives.
- **Absorption sketch against the chokepoint.**
  - The trackable path for `o.F` is `[o, fld(F)]`, built at `parse_expr_producer.go:190-240`. The
    receiver consumer is built at `root_assertion_node.go:813+` on `expr.X`.
  - Both collapse to one insight: expand the selection's embedded index path into the explicit
    chain `o.Inner.F`.
  - The existing, correct explicit-form machinery then supplies everything else for free:
    - guard matching (`if o.Inner != nil { o.F }`);
    - the pointer-receiver last-hop exemption (Checks 1-4 on the canonical receiver);
    - struct-init keys.
  - The v2 collector (`structfieldeffects/collector.go:232`) walks selectors on its own, so it is a
    second site with the same insight.
  - Sketch: about 40-60 eff for the canonicaliser, plus about 15-25 per site at 3-4 sites, plus about
    20 for diagnostics = **roughly 100-150 eff.**
- **Stage 6 death-class guard: FAIL.**
  - Q1: yes, one shared kernel (path canonicalisation).
  - Q2: only weakly interdependent. The FP-on-guard cell and the v2-only cell both fall to the same
    rewrite.
  - Q3: no standalone file.
  - Q4: TOO-EASY "make X consistent with existing-correct Y = CHOKEPOINT" (go-mysql-server). The
    explicit selector path is the in-repo correct reference, and the fix is "do what it does".
  - Under 150 eff it dies on the 09-09-B sketch rule.
  - Pivot considered and rejected: interface-typed embedded fields and method values ride the same
    rewrite (the method-value case is already reported on base).
- **Verdict: SHELVED.** Record it so the lane is not re-audited. The repo is otherwise open. Any
  future lane must be structural rather than one more implicit-dereference arm. #423 (the sibling arm,
  pointer-to-array) was 36 lines.

## nevalang/neva: lane audit (PAUSED since 08-23)

**Mechanical.** ★1082, MIT, quota 1/6 (approved `neva-array-bypass-generalization`: analyzer +
desugarer + irgen + runtime/std). `fuzz` is green weekly and `test` was green 08-23.
Competitor-clean.
- Lane histogram, May..Sep:
  - `runtime` 64/25/36/5/**0**; `parser` 6/7/6/14/**0**; `analyzer` 9/3/18/6/**0**;
    `backend` 16/0/7/2/**0**; `typesystem` 0/1/2/7/**0**; `std` 4/10/17/7/**0**;
  - `desugarer` 0/0/0/2/0; `irgen` 0/0/0/5/0; `ir` 0.
- 100% of August commits are `emil14` merging `codex/*` branches. The maintainer AI-sweep is active
  in EVERY lane he touches (the 09-09-B softening scopes AI marks to the intended lane; here every
  lane is in scope).
- Lanes:
  - Typesystem remains maintainer-owned: draft PR #1182 (bind-type compiler bridge) and #1160
    (7 comments) are open.
  - DI validation #435 is analyzer self-collision. Its issue body publishes the root cause lines
    (`nodes.go` "BLINDLY ACCEPTED"), so it is a public solution sketch.
  - Sender reuse #758 has an unsettled design (Gate 8: behaviour not defined).
  - `streams.Split` #1193 is a concurrency race (flakiness risk).
  - WaitGroup #890 collides with our own `WaitAll`.
  - Default inport values #564 is a famous language feature (carve-out).
  - Buffer/BufferSize #665/#671 and struct equality #613 are small arms.
- **Verdict: no lane this cycle.** A 5-week pause is too short to call the workstream over. When it
  resumes, the codex branches reach whatever lane we pick. Re-check after about 8 weeks of silence
  (around 2026-10-20). A candidate lane then must sit outside analyzer/desugarer/irgen and outside
  the typesystem PRs.

## tordanik/OSM2World: lane check (decaying solo stream)

- ★784, MIT, Java, no vendored jars. `Java CI with Maven` is green 09-09 (failures on 08-24/26 fixed).
  98 test classes. Three ancient open PRs.
- Stream: 30/23/7. The owner is still shipping tag support, glTF and 3D Tiles.
- `map_elevation` (0 commits in 90 days) looked like the prize:
  - `SimpleEleConstraintEnforcer` leaves `requireVerticalDistance`, `requireIncline` and
    `requireSmoothness` as `// TODO Auto-generated method stub`, with the "intended algorithm" in a
    TODO.
  - **DEAD on the kira removal rule.** Commit `c44d76f2` (2019-08-04) "Remove the
    LPEleConstraintEnforcer" deleted a working LP implementation of exactly these constraints
    (history `e37543d8`, `020de008`, `deb96898`, `008e2f7a` "allow vertical distance to line segment,
    use it for bridges & tunnels", `0d11933f` "enforce waterway downhill flow"). Issue #89 "Set
    EleConstraintEnforcer to LP crash" is still open.
- Roofs: all Simple-3D-Buildings shapes exist (26 classes, including saltbox, sawtooth and
  half-hipped). #254 `apse_gabled` is a missing arm.
- `world/network` (0 commits in 12 months): junction robustness (#106, #210). The maintainer says he
  has "not yet figured out what the best workaround should be", so the behaviour is not externally
  defined (Gate 8). It is a single-subsystem geometric post-pass (guard #2).
- **Verdict: DEAD for this cycle.**

## Result

**NO-CANDIDATE.** The time-decay axis yields two repos whose workstream has actually stopped:
- nilaway: its best invented lane dies at Stage 6 (chokepoint, about 100-150 eff);
- neva: paused for only 5 weeks, and still AI-swept in every lane.

Every other lane-killed repo in the window is either still hot or has since gained a hard kill.

No fallback was promoted. The orchestrator's reserved pair stays reserved:
- csbindgen: const-expression eval;
- libspatialindex: MVR-tree pruning.

Neither was re-audited here.

## What the next hunt should change

- **The time-decay axis is now measured and mostly spent.** It re-opened 2 of 30, and neither carried
  a lane.
- **Re-run it once, about 2026-10-27, on three repos only:**
  - **neva:** does the pause last 8+ weeks?
  - **egglog:** have `ezrosent`'s 30 open PRs merged or closed? Merging releases nothing, but
    closure-plus-silence would matter.
  - **OTIO:** have #1466, #842 and #1818 landed? Landing releases the timewarp kernel.
- **nilaway is open at the repo level, but its tracker lanes are small FP/FN arms.** Only a
  STRUCTURAL capability can carry it, for example a new analysis domain that is not a missing arm.
  Do not re-audit promoted fields.
- Otherwise follow hunt #36's (a)/(b): human-supplied anchor repos, or a supervised soft-gate override
  on a named strong engine.
