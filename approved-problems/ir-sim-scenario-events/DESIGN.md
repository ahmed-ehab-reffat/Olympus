# DESIGN.md — ir-sim-scenario-events

Repo: hanruihua/ir-sim (Python, MIT, ★1130) · base `e4a60f94bb719f60a615d98025db4ed7b882f6cf` (2026-09-12)
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-18-B.md` Part 2. Platform picker: accepted (user, 2026-09-18).

## Phase 1 — Repo understanding

**Architecture.** `irsim.make(yaml)` builds an `EnvBase`. `EnvConfig` parses the YAML into fixed
top-level blocks (`world`, `gui`, `robot`, `obstacle`, `custom`; any other key raises `KeyError`)
and `_build_scene` turns them into a `World` (clock, status, map) plus one flat object list built by
`ObjectFactory` (robots first, then obstacles, then map objects, sorted by id; ids come from a
per-env `itertools.count` in `EnvParam.id_iter`). `EnvBase.step()` advances objects (behaviors or
actions), sensors, the world clock, then `_status_step` (one batched STRtree collision query,
arrival, env status). The object list is shared by reference: `EnvParam.objects` is the same list
object as `EnvBase._objects`, and the STRtree (`EnvParam.GeometryTree`) is indexed by position into
it for lidar, `possible_collision_objects` and collisions. Three lifecycle paths exist: `reset()`
(per-object `reset()` over the CURRENT list, no rebuild), `reset(random=True)` (early return into
`_rebuild_from_cached_parse`), and `reload()` (calls `reset()`, then re-reads YAML and rebuilds).

**Five subsystems + boundaries.**
1. Config (`irsim/env/env_config.py`): YAML -> parse dict -> scene build.
2. Environment lifecycle (`irsim/env/env_base.py`): step order, pause/debug/external modes, reset/reload, object add/delete, lookups, status.
3. World (`irsim/world/world.py`): clock (`count`, `time = round(count*step_time, 2)`), status, map.
4. Objects (`irsim/world/object_base.py`, `object_factory.py`, `object_group.py`): ids, names, goals, arrival/collision flags, per-object reset.
5. Sensors / behaviors (`irsim/world/sensors/lidar2d.py`, `irsim/lib/behavior/*`): read neighbours through `EnvParam.objects` + `GeometryTree`.

**High-entanglement zones.** (a) `EnvBase.step` + `_status_step` (every per-tick concern). (b) The
lifecycle trio `reset` / `_rebuild_from_cached_parse` / `reload` (three paths, no shared code for
object bookkeeping). (c) Object-list identity: `_objects` / `EnvParam.objects` / `GeometryTree`
indices / `_object_groups` positional alignment in `_assign_group_action`.

**Tests.** pytest, `tests/test_*.py`, class-grouped, one-line docstrings on every test, fixtures in
`tests/conftest.py` (`env_factory`), inline YAML via `tmp_path` (template: `tests/test_env.py`
`test_make_step_mode_overrides_yaml`). Baseline: 995 passed / 45 skipped, identical 3x, ~140-160 s
(`pytest -o addopts=""`; pyproject addopts needs `pytest-cov`).

## 1. Title

Add declarative scenario events to the simulation step loop

## 2. Shape classification

- Shape: O-Composite-add (new capability spanning config parse, env step loop, object lifecycle, id bookkeeping). Closest Mars analogue B (new public surface) with D-change-style lifecycle cascading.
- Pass-rate target: 15-30% (ceiling 40%).
- Best agent: Orion (long-horizon), Nova ships plausible-but-incomplete lifecycle handling.
- Dominant verdict: REGRESSION + MISSED_REQUIREMENT (lifecycle paths), not INTEGRATION_ERROR.
- Solver/our LOC ratio: ~1.3x (new module + wiring).

## 3. Public API surface

- YAML top-level `events:` — a list of event mappings.
- Event keys: `when` (condition, required), `do` (action or list of actions, required), `name` (default `event_<index>`), `repeat` (default false), `cooldown` (steps, default 1), `delay` (steps, default 0).
- Conditions (one key each): `time`, `arrive`, `collision`, `enter`, `leave`, `distance`, `all`, `any`, `not`.
- Actions (one key each): `spawn` (`{robot: {...}}` or `{obstacle: {...}}`), `delete`, `goal`, `pause`.
- `env.event_log` — list of `(time, event name)` pairs, one per run of an event's actions, in run order.
- Invalid event config (unknown condition/action key, missing `when`/`do`) -> `ValueError` at env creation.

## 4. Canonical output form

- `event_log` order: chronological; within one evaluation, due delayed actions first (in the order they were scheduled), then events in listed order.
- Log time: `env.time` at the evaluation (already rounded to 2 decimals by the world).
- Spawned names: unnamed template -> the default `<role>_<id>`; template with `name` -> `<name>_1`, `<name>_2`, ... in the order that event spawns them.
- Spawned objects are appended to `env.objects` after the existing ones, in spawn order.
- Restored objects take back their original place in `env.objects`.
- Regions: `[xmin, ymin, xmax, ymax]`, bounds inclusive. Distance: centre to centre, strict `<`.
- Missing object in a condition -> the condition is false; `delete`/`goal` on a missing object -> no effect.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- Iteration/order: "events are checked in the order they are listed, each one seeing what the ones before it did".
- Compound order / pipeline placement: "checked at the end of every step that advances the simulation, after collisions and arrivals are updated".
- Stated inverse: "objects added with `add_object` stay, as they do today".
- Parallel API: the three lifecycle paths named explicitly (`reset()`, `reset(random=True)`, `reload()`).
Codebase-inferable requirements: 1 (the spawn template takes the same keys as a YAML robot/obstacle entry).

## 6. Description draft

See `meta.md` (drafted with this design; ~430 words, under the 500 cap). Plain prose, no headers.

## 7. File footprint (sketched against real files)

| Action | Path | Current | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| NEW | `irsim/env/env_events.py` | — | ~300 | ~200 | parse/validate, conditions incl. enter/leave tracking, firing/cooldown/delay, actions, naming, log |
| MODIFY | `irsim/env/env_base.py` | 1776 | ~110 | ~75 | step hook, reset undo (remove spawned, restore deleted in place, rewind id counter, re-arm), random/reload re-arm, `event_log`, init |
| MODIFY | `irsim/env/env_config.py` | ~260 | ~6 | ~4 | accept `events` key |
| MODIFY | `irsim/world/object_base.py` or factory | — | ~0-10 | ~5 | only if naming needs a hook |
TOTAL: ~420 raw / ~280 meaningful across 3-4 files. Floor 200; buffer ok. Scope-up if short: `env.events` status view or `leave`/`distance` variants already in.

## 8. Solution outline (helpers)

- `parse_events(raw) -> list[ScenarioEvent]` ← validation sentence.
- `Condition` tree: `evaluate(env, tracker) -> bool` per kind; `tracker` holds per-object inside/outside from the previous step, updated for EVERY object once per step before evaluation (never lazily inside a condition) ← enter/leave sentence.
- `EventManager.step(env)`: run due delayed actions, then for each event in order: armed? cooldown? condition -> fire (disarm/stamp cooldown) -> run now or schedule ← firing sentences.
- `run_action(env, action, event)`: spawn via `env.object_factory.create_from_parse`-style + `add_objects` (records spawned ids), delete (records removed objects with their list index), goal, pause ← action sentences.
- `EventManager.undo(env)`: remove spawned, reinsert deleted at recorded indices IN PLACE on the same list object, `obj.reset()` restored ones, rewind `id_iter` to the value after the scene build, clear log/pending/tracker, re-arm ← reset sentence.
- `EnvBase.reset`: undo BEFORE `_reset_all` so restored objects are reset too; `_rebuild_from_cached_parse` and `reload` build a fresh manager from the (re-read) parse.

## 9. Test file outline

`tests/test_scenario_events_<hex>.py`, pytest classes, inline YAML via `tmp_path`, headless env.
Buckets: config/validation (4) · time/arrive/collision/distance conditions (6) · enter/leave edge
semantics incl. combinator short-circuit (5) · firing once/repeat/cooldown/delay (6) · actions
spawn/delete/goal/pause (7) · spawned objects as ordinary members (lidar sees them, collisions,
done(), robot_list, lookups) (5) · reset undo (spawn removed, delete restored in place + reset
state, id replay, log cleared, pending dropped, add_object kept) (7) · reset(random=True) and
reload() cells (5) · external step_mode / pause interplay (2). ~47 tests.

## 10. Forced shapes

- `event_log` pairs: tests read them through a tolerant helper (`tuple(entry)`), times with `pytest.approx` (L48/L59).
- Spawn template = YAML robot/obstacle entry, created through the repo's factory (so `number`, `distribution`, `kinematics`, `behavior` work).

## 11. Trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence (contract only) | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Re-arm wired into `reset()` only; `reset(random=True)` returns early, `reload()` must re-read events | F-9 (origin variant) | S4 | lifecycle path | #2, #3 | the natural hook is the end of `reset()`; the random path never reaches it | "`reset(random=True)` and `reload()` re-arm the events too, and `reload()` takes them from the reloaded file" | once-event refires after reset(random=True); reload with a new file |
| 2 | Deleted object restored at the end of the list and/or after `_reset_all` (keeps mid-run state) | new (restore placement) + S2 | S2 | object order / state | #4 | append is the obvious reinsertion; order of undo vs reset is invisible in single-object tests | "each object an event deleted comes back with its id, name and place in `env.objects`, at its initial state" | delete `robot_0`, move others, reset: `env.robot`, order, state |
| 3 | Id counter not rewound: replay after reset spawns `robot_7` instead of `robot_5` | F-35 (index rewind) | S3 | id sequence | #1 | removing spawned objects looks like the whole job | "running the same steps again after a reset gives the same log, names and ids" | spawn, reset, replay: names/ids equal |
| 4 | `_objects` rebound to a new list on undo; `EnvParam.objects` and STRtree indices go stale | new (shared-list alias) | S1/S3 | object-list identity | #2 | filtering into a new list is idiomatic Python | S4 sentence: "spawned and deleted objects are seen accordingly by everything the environment already does (collisions, sensors, behaviors, `done()`)" | lidar ghost after reset; collision after undo |
| 5 | Enter/leave tracked lazily inside the condition; `all`/`any` short-circuit leaves stale previous-position state | F-15-like (arming) | S2 | condition evaluation | — (orthogonal) | lazy per-condition state is the natural design | "`enter` holds only on a step at whose start the object was outside and at whose end it is inside" | `all: [arrive X, enter Y]` where Y entered long before X arrives -> no fire |
| 6 | Reset removes objects added with `add_object` (over-eager undo) | F-20 | S3 | baseline preservation | #2 | "remove everything not from the YAML" is simpler than tracking spawns | "objects added with `add_object` stay, as they do today" | add_object + reset keeps it |
| 7 | Delayed actions survive reset, or fire while paused | S2 | S2 | pending state | #1 | pending queue is new state nobody clears | "reset drops pending delayed actions" | fire with delay, reset before due: never runs |

Axes differ per row; #1-#4 share the undo chokepoint (interdependent: fixing order breaks aliasing if
done by rebuild; fixing the random path without rewinding ids still fails replay).

## 11b. Cross-product matrix

| | `reset()` | `reset(random=True)` | `reload()` |
|---|---|---|---|
| once-event re-armed | test | test (off-diag) | test (off-diag) |
| spawned object gone | test | test | test |
| deleted object back in place | test | covered by rebuild | covered by rebuild |
| log cleared | test | test (off-diag) | test |
| pending delay dropped | test | test (off-diag) | — |

| | authored target | spawned target |
|---|---|---|
| condition (`arrive`/`distance`) | test | test (off-diag: condition on a spawned object's name) |
| action `delete` | test (restore) | test (off-diag: delete spawned, reset leaves none) |
| action `goal` | test | test |

Scope audit: `cooldown`/`delay` are per event; `time` is env time. Format nouns: "region" = the
closed rectangle; "step" = one `env.step()` that advances the simulation (paused calls are not steps).

## 12. Tier + category

Olympus, feature-request (new public YAML section + `env.event_log`). Title verb "Add".

## 13. Predicted pass rate

20-35%. Lead traps #1-#4 are lifecycle integration (DOING, not KNOWING); #5 is an orthogonal
composition. Risk of too-easy if agents build the manager with an explicit "snapshot of the authored
scene" and rebuild in place; the aliasing and id-rewind cells then carry the band.

## 14. Quality gate

- [x] Phase 1 5/5 · [x] Phase 2 (hunt: PR/issue/code/fork searches clean) · [x] closest approved opened (sfepy-adaptive-stepping-accounting)
- [x] Title verb-led · [x] API surface enumerated · [x] canonical forms · [x] 1 codebase-inferable
- [x] Footprint sketched on real files, ~280 meaningful · [x] traps with F-ids, different axes, interdependent
- [x] F-10 matrix · [x] F-20 audit (no base test of add_object+reset: seam live) · [x] L59 (times via approx) · [x] L56 (no subprocess tools)
- [ ] Core-slice platform precheck (Step 4b) — owed before differentiating scope
- [ ] Every trap reproduced with a natural-but-wrong implementation

## Why this is not a duplicate

No approved/in-flight problem touches a robot simulator. Closest lifecycle-accounting precedent is
`sfepy-adaptive-stepping-accounting` (step log + termination in a solver), a different domain and
capability. The derivative magnet ("scenario triggers") has no public implementation on ir-sim's model;
Step 4b precheck is the check that can see the pipeline.

Predicted iteration cycles: 2-3.
