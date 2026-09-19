# feedback.md — ir-sim-scenario-events

## Summary
- Repo: hanruihua/ir-sim (Python, MIT, ★1130), base `e4a60f9` (2026-09-12). Platform picker: accepted (2026-09-18).
- Capability: a declarative `events:` YAML section checked at the end of every step (conditions: time, arrive,
  collision, distance, enter/leave, all/any/not; actions: spawn, delete, goal, pause; repeat/cooldown/delay;
  `env.event_log`), with reset()/reset(random=True)/reload() undoing and re-arming.
- Lead traps (lifecycle integration): random-reset early return (F-9 origin), restore-in-place + reset order,
  id-counter rewind on replay (F-35), shared object-list aliasing (GeometryTree indices / EnvParam.objects),
  lazy enter/leave tracking under all/any short-circuit, add_object survivors (F-20). All 11 natural-but-wrong
  mutants reproduced and killed (`worktrees/_probe/irsim_mutants.py`).

## Status
- 2026-09-18: DESIGN.md, reference, 60 tests, Dockerfile, patches. human-effective 275 (floor 200), 3 files.
  Clean room in Docker (uid 1000, --network none): base 1040 pass/45 skip; new 60/60 fail on base, 60/60 pass
  with solution; base unchanged with solution. Cold build 169 s.
- NEXT: Step 4b core-slice platform precheck (dedupe/scope) BEFORE any further scope; then FP passes
  (per-branch mutation incl. base mode, feature-stub, assertion flip), 3x flakiness, first batch.

## Attempt history

### Round 1 — platform prechecks (2026-09-18)
- **Scope / dedupe: PASS** ("candidates are unrelated cross-repository simulation tasks, their union covers no
  major block, no public/removed/declined implementation was found"). Funnel unlocked.
- **Problem and tests quality: WARNING** — `env.obstacle_number` assert is an unstated interface (removed);
  `number`/`distribution` in spawn templates judged unstated (kept: meta says the template takes the same keys
  as a `robot`/`obstacle` entry, and YAML entries take both).
- **Description: WARNING (optional)** — trim the "including collisions, sensors, behaviors, done() and lookups"
  enumeration and "An event fires when its condition holds." Not taken: the enumeration is the fairness anchor
  for the sensor/behavior/done tests.
- **Solution Quality: FAIL (1/3 comprehensiveness)**, three reference bugs, all fixed in the reference with
  regression tests (L50: a reference bug predicts the agent's mistake):
  1. nested condition/action payload keys not validated -> exact-key payload check (`_payload`), numeric/name
     type checks; tests: unknown key inside `distance` and inside `goal`, two-key condition.
  2. spawn/delete did not maintain `_object_groups`; group actions were assigned by concatenated position ->
     `_sync_groups` after spawn/delete/undo (unchanged groups reused), `_assign_group_action` now assigns by
     member identity (also removes a PRE-EXISTING base misalignment: a multi-member group without group behavior
     before a behavior group; tests deliberately never reach that base case, L60/L66). Tests: spawned sfm robot
     moves; deleting an earlier robot keeps an sfm robot moving; after reset both robots follow their own behaviors.
  3. later events saw stale arrive/collision after earlier actions -> tree rebuild + `_status_step()` after each
     run. Tests: arrive after a goal change in the same check; collision with a same-check spawn.
- Advisory coverage taken: exact-edge region entry (external step mode + set_state), missing-object enter/leave
  under not, two delayed runs due at one check (scheduling order), per-event spawn numbering (distinct names;
  a same-name cell is impossible because names must be unique).
- Mutants now 15, all killed (W12/W12b/W13/W14 added). human-effective 316, 72 tests.

### Round 1b — FP passes (2026-09-18, after the Solution Quality fixes)
- Per-branch mutation sweep `worktrees/_probe/irsim_branch_mutants.py` (22 branch mutants): 21 killed; B8 (log
  appended at the start vs end of a run) is equivalent (same `(time, name)`, same order), not a hole.
- Feature stub (event checks disabled): 7 tests still passed because they never asserted the event had acted
  before reset/reload (group-after-delete, group-after-reset, replay, add_object kept, spawn-then-delete,
  random-reset pending, reload numbering). Each now asserts its precondition. Remaining 12 stub survivors are the
  9 validation tests, the empty-log baseline and 2 region "no fire" discriminators (positive siblings exist).
- Design mutants `irsim_mutants.py`: 15/15 killed.
- Meta <-> test audit (L53): every sentence of meta.md maps to at least one discriminating test; no
  stated-but-untested clause found. Only unstated-but-accepted input: `pause: false` (no-op, untested).
- Final clean room (fresh clone at base + test.patch, Docker, uid 1000, --network none): new without solution
  72/72 fail; with solution new 72/72 pass x3, base 1040 pass / 45 skip x3, identical failure sets. Flakiness gate PASS.
- Patches: solution.patch sha1 8236595, test.patch sha1 0a067c1. human-effective 316, 3 files.
- NEXT: re-run Solution Quality / Test checks on the new patches; if clean, first batch (meta/Dockerfile frozen).

### Round 2 — Solution Quality re-check (2026-09-18): FAIL (1/3 comprehensiveness, 2/3 code quality)
- HIGH: spawn templates were not validated at creation (only warned by `check_unknown_kwargs` when the event
  fired) -> templates now checked against `ObjectBase._VALID_PARAMS` minus `role` (the repo's own canonical
  object-entry key set, incl. factory-consumed `number`/`distribution`); test: `shpae` key raises at creation.
  Nested shape/kinematics internals stay with the factory, as for YAML entries.
- MEDIUM: spawn overwrote a template's `group` -> `setdefault`; test: a spawned robot with `group: 0` joins the
  leader's sfm group and moves.
- Advisory taken: spawned robot's own lidar sees the scene; object spawned outside a region never "leaves"
  (coverage only, not discriminating); `done()` recomputed after deleting a robot.
- Mutants: group-overwrite killed by the join test, unchecked template keys killed by the `shpae` test.
- 77 tests. meta.md / Dockerfile / base commit unchanged (solver-visible surface frozen).
- Clean room (fresh clone, Docker, uid 1000, --network none): new w/o solution 77/77 fail, base w/o solution
  1040/45 skip; with solution new 77/77 x3 and base 1040/45 skip x3, identical. human-effective 321.
  solution.patch sha1 c016856, test.patch sha1 0032846.

### Round 3 — Test Quality FAIL (2/79 unfair) + Solution Quality PASS (2/3, 2/3) (2026-09-18)
- Test Quality: the two all/any short-circuit region tests were ruled unfair ("previous check" could be read as
  the previous evaluation of the condition, so a short-circuiting all()/any() is a grounded implementation).
  L30 repair = state the rule, not delete the test: meta now says enter/leave compare with the previous check
  "whether or not that check evaluated this condition" (L34 disclosure debit accepted; the fix, tracking every
  object's position at every check, stays hidden). The any-test's universal assertion was vacuous on an empty
  log; it now pins the exact 23 busy-window firings.
- Advisory taken: non-list `events` raises (meta now states it), arrive/collision hold as levels under repeat,
  distance across changing positions incl. exactly-at-threshold (external mode + set_state).
- Solution Quality fixes: `cooldown: 0` allowed; pause is applied once the check is over (after all status
  refreshes) so `env.status` stays "Pause" (test added); docs `yaml_config/configuration.md` gains an Events
  section and the six-key overview, `EnvBase.config` docstring lists `events` (English only; zh_CN .po left).
- meta.md 497 words incl. title. 82 tests. Mutants: 15 design + 24 branch, all killed except equivalent B8.
- Clean room (fresh clone, Docker, uid 1000, --network none): new w/o solution 82/82 fail, base 1040/45 skip;
  with solution new 82/82 x3 and base 1040/45 skip x3, identical. solution.patch sha1 b2f1ab4, test.patch 95ff64f.

### Round 4 — Solution Quality FAIL (1/3, 3/3) + Test Quality FAIL (1/82 unfair) (2026-09-19)
- Conflict between checkers resolved in the description: Solution Quality (round 2) demanded creation-time
  ValueError for unknown spawn-template keys; Test Quality ruled that test unfair because meta.md only named
  "event, condition or action". meta.md now names "an unknown key in an event, condition, action or spawned
  object's mapping", so the requirement is stated and the test stays.
- Solution Quality: explicit `events: null` was treated as omitted -> parse default is now `[]` and any
  non-list (incl. null) raises; test added. `distance` measured state origins -> now geometry centroids
  (`ObjectBase.centroid`), and enter/leave use the centre too (meta: "the object's centre is inside");
  tests with offset-centre shapes for both.
- L59 found in my own tests: circle centroids are polygon approximations (2.000000000000001), so the
  exact-edge, strict-below and moving-distance tests were passing by float luck. They now use square
  shapes with binary-exact centroids.
- Advisory taken: non-mapping `when` (scalar, list, string) raises; goal action asserts theta.
- The venv under /tmp/claude-1000 was wiped overnight; it now lives at worktrees/_probe/irsim-venv and the
  mutant harnesses point there. Mutants: 3 new (C1 distance by origin, C2 regions by origin, N1 null
  accepted) all killed; full sets re-run, only equivalent B8 survives. 88 tests. meta 494 words incl title.
- Clean room (fresh clone, Docker, uid 1000, --network none): new w/o solution 88/88 fail, base 1040/45 skip;
  with solution new 88/88 x3, base 1040/45 skip x3, identical. solution.patch sha1 0971c8a, test.patch 2e7e5df.

### Round 5 — Batch 1 (0/11) + Auto Review "Revision Requested" (2026-09-19)
- Batch 1 (10 Nova + 1 Vega, 88 tests): 0/11. Kill table in eval-results.md.
  - `test_lidar_sees_spawned_obstacle` 11/11: UNFAIR (L8) — it pinned that sensors had NOT seen a spawned object
    right after the spawning check; meta never says whether sensors refresh at spawn time and every agent
    refreshed them immediately. Fixed by asserting only after the following step.
  - `test_spawned_robot_with_group_behavior_moves` 10/11: FAIR (L18: Nova #3 cleared it; evaluator: mentioned in
    description + inferable from codebase). Agents leave a spawned entry in the default group 0 instead of making
    it its own group as every YAML entry is. Kept as the band decider (sole failure of 6 near-misses).
- Auto Review (Description 2/3, Tests 2/3, Solution 1/3):
  - S2 HIGH: plain `reset()` rewound the id counter below ids already handed out by `create_robot/obstacle`
    to objects not yet added -> duplicate ids. Fixed in the reference: `_IdAllocator` wraps the env's id
    counter, records the highest id issued outside event spawns, and the rewind never goes below it.
    The regression test killed 11/11 (every agent shares the bug, L50) and meta.md states the opposite
    ("same ids" on replay) -> hidden requirement by L66/L18. Test NOT shipped; reference fix kept. Contest
    note for the reviewer: fix in reference; a test would demand behaviour the description does not state.
  - T3/T4: added unknown key in a spawned ROBOT template (parametrized robot/obstacle) and goal restored by
    reset. Replay: neither kills any agent.
  - P4 (Medium, readability of the enter/leave clause): NOT changed now — a meta edit removes the re-eval
    option; defer to the next solver-visible change.
- Plan: re-eval (tests + solution only) -> projected 1/11 (9%) from the local replay.
- Clean room (fresh clone, Docker, uid 1000, --network none): new w/o solution 90/90 fail, base 1040/45 skip;
  with solution new 90/90 x3, base 1040/45 skip x3, identical. solution.patch sha1 d84103c, test.patch 34a5522.

### Round 6 — Solution Quality FAIL (1/3): sensors stale after an event spawn/delete (2026-09-19)
- The reviewer reads "Everything the environment does, including ... sensors ... sees spawned and deleted
  objects" as immediate: after the event check, sensor readings must already reflect the new scene. Reference
  now calls `env._objects_sensor_step()` after the tree rebuild when an event spawned or deleted something.
- The two lidar tests now assert the new scene at the very check where the event acts (this is exactly what all
  11 batch-1 agents did; the round-5 relaxation pinned nothing, this round pins the immediate reading).
  Mutant (no refresh) killed by both. Replay against agent-runs/1: unchanged 1/11 (Nova #3 90/90).

### ACCEPTED 2026-09-19 — re-eval 1/11, Auto Review Approved
- Finalized: F-41/F-42, L75/L76, Pattern 98, dossier in failure-patterns.md § 2; skills (hunt/author/harden)
  and Instructions updated. Open notes from the approval (not fixed, recorded for the next similar pick):
  a mixed-name same-event spawn-numbering cell (per-base counters pass today), and the docs interactive
  tree lacks an `events` node.
