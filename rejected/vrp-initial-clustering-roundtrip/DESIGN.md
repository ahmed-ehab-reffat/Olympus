# DESIGN.md — vrp-initial-clustering-roundtrip

Repo reinterpretcat/vrp (Rust, Apache-2.0, 508 stars), BASE e49bee0eccb9d732d0e020d7f9bbbb378e2de2bc
(master HEAD 2026-09-21). Lane from REPO-HUNT-2026-09-23-I (RANK 1).

## Phase 1 — repo understanding

Architecture in one paragraph: `rosomaxa` is a generic metaheuristic framework (population, evolution
simulator, context/solution processing hooks). `vrp-core` holds the VRP model (jobs, fleet, tours,
activities with schedule/commute), the construction heuristics, the goal/feature pipeline and the
solver, including pre/post processing hooks such as `VicinityClustering` (pre_process swaps the job
registry for cluster jobs; post_process unpacks a cluster activity back into member activities with
commute and parking). `vrp-pragmatic` is the JSON format: problem reader, solution writer (stops,
parking, commute intervals, required breaks as transit stops), initial-solution reader, checker.
`vrp-cli` wires formats to the solver (`solve --init-solution`, `--max-generations`, `--init-size`).
`vrp-scientific` reads Solomon/LiLim/TSPLIB.

Five subsystems + boundaries: (1) rosomaxa evolution simulator (hook order: `pre_process` then
initial individuals `on_initial`, `simulator.rs:63-77`); (2) vrp-core processing hooks
(`solver/processing/*.rs`); (3) vrp-core clustering (`construction/clustering/vicinity`); (4)
vrp-pragmatic solution format (`format/solution/{solution_writer,initial_reader,activity_matcher,
break_writer}.rs`); (5) vrp-cli commands (`commands/solve.rs`).

High-entanglement zones: the cluster job (`ClusterInfo` vector) read by pre_process, post_process,
the writer (via post-processed member activities) and the checker; the initial individual path
(reader -> `InsertionContext::new_from_solution(original problem)` -> `with_init_solutions` ->
simulator after pre_process); the writer's per-activity leg fold (parking, commute, stop split).

Tests: unit tests via `#[path]` into `tests/unit`, feature tests `vrp-pragmatic/tests/features/*`
through the solve path (crate-internal helpers). Template cited:
`vrp-pragmatic/tests/features/clustering/basic_vicinity_test.rs` (solves and asserts exact stops).
New tests go in an integration target `vrp-pragmatic/tests/initial_clustering_df3f26.rs` that uses
only public API (read_init_solution, write_pragmatic, VrpConfigBuilder, Solver).

## Phase 2 — existing-PR / publicly-solved

Canonical `reinterpretcat/vrp` (not moved). PR search (all states) for "initial solution", "init
solution", commute, clustering, vicinity, cluster, transit, "warm start", parking: 0 PRs. Issues:
#141 (relations + clustering, maintainer fixed by EXCLUDING related jobs from clustering; not this
lane), #72/#126/#138 (init-solution reload/time bugs, fixed or unrelated), #194 (performance
question). No maintainer refusal of the lane. Commits base..HEAD: none (base = HEAD). Fork-branch scan
(hunter, 19 active forks): only henningms (1-line `actor.detail.end` fix in create_core_route, which is
the open-shift start bug this design also fixes) and uptick (docs). History: the init reader copied
commute for one day in Oct 2021 (a5988741 -> 60b3eecb) before the refusal; both commits first ship in
v1.12.0, so the passthrough was never released: not the "reintroduced removed capability" class.
Sibling tools: VROOM/jsprit/OR-tools have no vicinity-cluster model. CLEAN.

## Phase 3 — candidates

| Candidate | Behaviour | Verdict |
|---|---|---|
| A. Reader round trip + clustered initial individuals (this) | reader inverts writer's clustered stops; solver maps individuals onto the clustered registry | PICK |
| B. Reader only (accept commute) | drop the refusal | dead: ~5 LOC, F2P B stays |
| C. Exclude init-solution jobs from clustering | ~30 LOC shortcut | dead: contract forbids (clusters as without -i) |
| D. Required breaks in the reader alone | skip reserved-time breaks / transit stops | too small alone; FINISH scope of A |
| E. Relations + clustering | maintainer chose exclusion (#141) | Gate 8 dead |

Death-class guard (TOO-EASY Pre-Pick Guard): (1) not a uniform wrap: three different inversions
(reader arithmetic, registry translation, split policy); (2) not single-subsystem: pragmatic reader,
core processing, rosomaxa hook order; (3) difficulty survives full statement: the stage boundary
(F-9) is not named by stating the outcome; (4) not a saturated port; (5) survives full spec: yes.
Absorption check (name the algorithm): the inverse of `post_process` (grouping member runs back into
one cluster activity), the reader inversion of the writer's parking/commute arithmetic, and the
split-member policy. None exists in the repo (grep: no caller maps original jobs to cluster jobs).
Measured risk: the working core slice measured 113 human-eff before the reader inversion; with it
see § 7. Missing-arm test: the reader refusal is a guard, but deleting it (probe) does NOT make the
feature work (F2P B stays, write(read(x)) had 56 diffs) — not a NEW-CASE absorption.

Arsenal: lead S6/F-9 (two stages, validate/emit split: individuals built against the original
registry, clusters created later inside the solver); S2 composition (split policy x run order x stop
sharing); F-49-style inversion (writer flattens a cluster into commute-bearing member activities).

## 1. Title
Add vicinity-clustering support to pragmatic initial solutions

## 2. Shape
O-Composite-add (reader + core processing + rosomaxa hook). Best agent: Orion/Vega (long horizon).
Dominant verdict predicted: MISSED_REQUIREMENT (policy cells) + INTEGRATION (hook placement).

## 3. Public API surface (all existing; no new public name is needed by tests)
- `vrp_pragmatic::format::solution::read_init_solution(BufReader, Arc<Problem>, Arc<dyn Random>)`
- `vrp_pragmatic::format::solution::write_pragmatic(&Problem, &Solution, PragmaticOutputType, &mut writer)`
- `vrp_core::solver::VrpConfigBuilder::...with_init_solutions(Vec<InsertionContext>, Option<usize>)
  .with_max_generations(Some(0))`, `Solver::solve`
- Reference adds a defaulted `HeuristicContextProcessing::pre_process_solution` (rosomaxa); tests do
  not call it (agents may place the translation anywhere inside the solver).

## 4. Canonical output form
Output is the pragmatic solution JSON; tests compare parsed JSON values (key order irrelevant).
Stops/activities in tour order. Unassigned compared as a SET of job ids (reason codes not pinned).

## 5. Blind-spot pre-empts
- "exactly the clusters it builds when no initial solution is given" (forbids the exclusion shortcut)
- split policy stated in full, both sides (served-together vs not)
- "in any order" for member runs (order-insensitive grouping)
- "vehicles with and without a shift end" (open-shift start bug is in scope)

## 6. Description draft
See meta.md (draft for the slice). ~330 words.

## 7. File footprint (slice measured, FINISH sketched)
| Action | Path | Slice raw | FINISH add |
|---|---|---|---|
| MODIFY | rosomaxa/src/evolution/mod.rs | +5 | 0 |
| MODIFY | rosomaxa/src/evolution/simulator.rs | +2 | 0 |
| MODIFY | vrp-core/src/solver/processing/vicinity_clustering.rs | +157 | +10-20 (TW choice, split across tours) |
| MODIFY | vrp-pragmatic/src/format/solution/initial_reader.rs | +50 | +40-70 (required breaks at a stop and in transit stops; break-extended times) |
| MODIFY | vrp-pragmatic/src/format/solution/activity_matcher.rs | 0 | +10-20 (reserved-break matching reuse) |
Slice human-eff measured at scope time: see feedback.md. FINISH target 250-300 human-eff.

## 8. Solution outline
- reader `create_commute_activity`: arrival = stop arrival for the stop's first activity else previous
  departure; departure = time.end + backward commute; place.duration = interval + stop parking on the
  first activity; waiting preserved by raising place.time.start when service started late.
- reader `create_core_route`: set the end activity's time only when the actor has an end (open-shift
  fix: `Tour::end()` returns the start on an open tour).
- core `pre_process_solution`: member->cluster map from the clustered registry; served clusters =
  exactly one consecutive run per cluster containing all members; replace runs by one cluster
  activity (schedule first arrival..last departure, cluster place, first TW reachable); drop members of
  unserved clusters; unassigned = members mapped to clusters + every job neither routed nor listed.
- rosomaxa simulator: apply every context hook's `pre_process_solution` to each user individual after
  `pre_process`, before `on_initial`.

## 9. Test outline (`vrp-pragmatic/tests/initial_clustering_df3f26.rs`)
Block 1 imports; block 2 fixture loaders (problem + shared matrix from
`examples/data/pragmatic/clustering/initial.*.json`), `read`, `write`, `solve_without_generations`;
block 3 `stop_jobs` / `unassigned_ids` extractors; block 4 tests:
- read-back law: closed clustered, open clustered, (FINISH) return policy, required break at stop,
  transit stop, two clusters at one location, plain open shift
- zero-generation solve law: own clustered output (closed, open) written back unchanged
- policy: plain output -> consecutive clusters formed, interrupted cluster unassigned; reordered run
  still forms the cluster; a member left unassigned -> whole cluster unassigned; (FINISH) members split
  across two tours; cluster plus plain job sharing a location; multi-TW cluster.

## 10. Forced bounds
None new. `read_init_solution` signature unchanged; `with_init_solutions` unchanged.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Translation outside the solver (reader/CLI) or before `pre_process` | F-9 | S6 | stage placement | #2 (reader output feeds it) | reader has the original problem only; clusters are created later with new job identities | "an initial solution passed to the solver (with `with_init_solutions` ... which is what the CLI does)" | zero-generation tests via the library |
| 2 | Reader keeps base arithmetic for members (arrival=service start, job duration, no parking, no backward) | F-49 inversion | S2 | per-activity arithmetic | #1 (solve law masks it after restore; only the read-back law sees it) | solve path recomputes schedules, so agents validating by solving never see it | "writing the read solution straight back ... reproduces the original output" | read-back tests |
| 3 | Open-shift start overwritten by last stop | F-10 (open x clustered) | A9 | shift shape | #2 | agents test on one fixture shape | "vehicles with and without a shift end" | open read-back + open solve law |
| 4 | Split policy: first-run wins / partial clusters kept / order-sensitive runs | F-10 | S2 | policy | #1 | local grouping by stop or by order | stated rule both sides | policy tests |
| 5 | Clusters recomputed or skipped for -i jobs | shortcut | — | contract | #1 | cheapest path | "exactly the ones it builds when no initial solution is given" | plain-output solve test |

## 11b. Cross-product
visiting {continue, return} x serving {fixed, original/multiplier} x parking {0, >0} x shift {open,
closed}: slice covers continue/fixed/parking>0 x {open, closed}; FINISH adds return/original/0.
policy {together, interrupted, reordered, member unassigned, split tours} x stop {own stop, shared
location}.

## 12. Tier/category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
25-40% before FINISH hardening; lead risk is that the zero-generation law is transcribable once the
agent finds the hook. FINISH adds the read-back cells (required breaks, return policy) to push down.

## 14. Checklist
Phase 1 5/5; Phase 2 clean; closest approved (vrp-tsplib) opened as scaffolding (test.sh/Dockerfile);
no new API names; canonical form stated; F-ids named; different axes; F-10 matrix above; stated-noun
list: initial solution, stop, parking, commute, cluster, tour, shift end, unassigned, generations.

Why not a duplicate: our approved vrp sub is TSPLIB parsing + CLI export (vrp-scientific + vrp-cli);
this is pragmatic solution round trip + core clustering processing + rosomaxa hook. Different
subsystems and feature class.

Predicted iteration cycles: 2.
