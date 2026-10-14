# DESIGN.md - eventsourcing-system-consistent-cut

Repo: pyeventsourcing/eventsourcing (canonical, BSD-3-Clause, 1687 stars), branch 9.5,
BASE 575d42c10a821828639b90178ed56703abe9c9f1. Hunt #42 lane C* (dossier
`worktrees/_hunt/s_0930h42/dossier_eventsourcing_h42.md`).

## Phase 1 - Repo understanding

**Architecture (one paragraph).** `eventsourcing` is an event-sourcing library. Aggregates
(`domain.py`) trigger domain events; an `Application` (`application.py`) turns them into
`StoredEvent`s through a `Mapper` and records them through a recorder chosen by an
`InfrastructureFactory` (`persistence.py` ABCs; `popo.py` in-memory, `sqlite.py`, `postgres.py`
backends). An application recorder numbers every stored event with a notification id (POPO: list
position, SQLite: rowid, Postgres: bigserial) and a `LocalNotificationLog` pages those notifications.
Event-processing applications (`EventSourcedProjection` in `projection.py`, `Follower` /
`ProcessApplication` in `system.py`) pull a leader's notifications, run a `policy`, and record their
new events atomically with a `Tracking(leader, notification_id)` through a `ProcessRecorder`, whose
tracking keeps only the highest id per leader. A `System` is a graph of pipes (followers, leaders,
loops allowed) and a `Runner` (single-threaded, new single-threaded, multi-threaded, new
multi-threaded) constructs the applications and wires following and prompting.

**Five subsystems + boundaries.**
1. Domain model (`domain.py`): aggregates, events, snapshots. No persistence knowledge.
2. Application layer (`application.py`): save/record/notify, `Repository` (reconstruction at a
   version, snapshots, cache), notification log.
3. Persistence ABCs + mapper (`persistence.py`): recorders, `Tracking`, `Notification`, factories.
4. Backends (`popo.py`, `sqlite.py`, `postgres.py`): concrete tables and atomic inserts.
5. System layer (`system.py`, `projection.py`): followers, process applications, `System` graph,
   runners.

**Three high-entanglement zones.**
- The atomic write path `Application._record` -> `EventStore.put` -> `ProcessRecorder.insert_events`
  (`_update_table` POPO popo.py:236-244, `_insert_events` SQLite sqlite.py:668-678, Postgres
  `insert_events`/`_insert_events` postgres.py:628-693, 1108-1117): events + tracking in one
  transaction, three implementations.
- The follower pull loop `Follower.pull_and_process` -> `EventSourcedProjection.process_event`
  (projection.py:205-229), which ALWAYS calls `_record`, so a no-op policy still reaches
  `insert_events([], tracking=t)`.
- The `System` graph (system.py:241-300) with `follows`/`leads`, loops allowed
  (`System([[Commands, Results, Commands]])`, tests/system_tests/test_runner.py:257), used by every
  runner's constructor and `start()`.

**Test framework.** `unittest.TestCase` classes run with pytest; system tests live in
`tests/system_tests/`. Template: `tests/system_tests/test_system.py` (module-level app classes,
`TestCase` methods, direct `follow` + `pull_and_process` driving).

## Phase 2 - Existing-PR / publicly-solved check (run 2026-09-30)

- `CANON=$(gh api repos/pyeventsourcing/eventsourcing -q .full_name)` -> pyeventsourcing/eventsourcing.
- `gh pr list --state all --search` for: consistent cut, cut, fork, snapshot of system, point in
  time, as of, processing step, ledger, rewind, replay, branch system, copy application, clone,
  tracking history, causal, restore. Hits: #145 (2018, v7 `application/process.py` causal
  dependencies: wait-for-dependency before processing, files no longer exist, different capability),
  #247 (runner follower-order validation, tests only), #93 (2017 restored notification logs), dependabot
  bumps. No diff implements a step ledger, a cut solver or a fork.
- Issues read (bodies + comments): #311 (truncation, open, 0 comments, not this lane), #293
  (bitemporal as-of: maintainer says bypass the repository and use `app.events`), #281 (add an app to
  an existing system: pull from start), #140 (projection rebuild: maintainer prefers upstream logs and
  atomic downstream tracking, which the ledger follows). No "won't add" / "by design" against cuts or
  forks, no closed-implemented.
- Post-base: `git log 575d42c1..origin/9.5` empty; `origin/10.0` (alpha rewrite) has no
  cut/fork/select_steps/ProcessingStep (`git grep`).
- Fork-branch scan: Zahgon/eventsourcing `commit0_all` = 1 commit replacing function bodies with
  `pass` across 18 files (commit0 benchmark stub), no cut/fork/step code (`gh api compare`, grep of
  added lines). Out of lane.
- `gh search code` for cut/fork over tracking ids in Python: 0 hits (hunt). Repo is not a port.

Verdict: exclusivity and SIX-CHECK clean.

## Phase 3 - Candidates

| Candidate | Behaviour | Shape | Files | Raw | Meaningful | Pred. | Verdict |
|---|---|---|---|---|---|---|---|
| C* consistent cut + fork (chosen) | step ledger in every ProcessRecorder, greatest consistent cut over the System graph, reads and id-preserving fork at the cut | O-Pipeline-hard | 5 mod | 331 | 269 hook | 20-35% | PICK |
| retroactive stream correction | rewrite stored events and re-drive | - | - | - | - | - | DEAD: append-only premise (docs/topics/application.rst:909) |
| truncation behind snapshot | purge history | - | - | - | - | - | DEAD: #311 magnet |
| point-in-time read of one app | read at notification id | - | 2 | ~60 | <150 | - | ABSORBED alone (searchabletimestamps example) |
| cut without fork | positions + reads only | - | 4 | ~200 | ~170 | - | under floor, fork is the F-59 wall |

**Step A (TOO-EASY guard).** (1) not a single rule at many sites: a write-path ledger in three
backends plus a graph solver plus a replaying materialiser. (2) spans persistence backends,
application reconstruction and the system runner, with two hidden walls (max-only tracking, empty
inserts for no-op steps). (3) every rule can be stated; difficulty is integration. (4) "consistent
cut" is a textbook NAME only; the definition here is the repo's own tracking model (steps, no-op
steps, loops). (5) survives full spelling. Not pointwise: the cut is a global fixed point.
Not provenance-bookkeeping (TOO-EASY 2026-09-08): the ledger is consumed by an algorithm (the greatest
fixed point) and by a materialiser, not reported. Machinery-absorbed check: measured, not sketched
(below).

**Step B arsenal.** Lead S4 machinery-riding (a no-op step must be an ordinary history member for
every surface) + F-47 discarded state (tracking keeps only the max). A-tier: A7 determination-channel
(no-op steps, untracked saves, tracked steps all move a prefix), F-22 fixed point over loops.
CONTRACT-STATED/FIX-HIDDEN: the meta states "processing a notification is a step even when it records
nothing"; it does not say that the backends' atomic insert drops empty inserts, nor that tracking
keeps only a max.

**Measured LOC (spike, hook `effective_loc_check.py`).** Core (ledger POPO/SQLite/Postgres, solver,
get, fork): 284 raw / **232 human-effective**. Full lane with the two coupled levers (snapshots copied
into the fork up to the cut; notification log as of the cut): 331 raw / **269 human-effective**, 5
files. Postgres parity is 67 of it (untestable here). Patches:
`worktrees/eventsourcing-h42-scratch/{core_spike,full_spike}.patch`.

## Phase 4 - DESIGN

### 1. Title
Add consistent cuts and forks to event processing systems

### 2. Shape
- Shape: O-Pipeline-hard (SHAPES.md Pattern 11-13: new capability + cascading, invent the algorithm).
- Pass target: 20-35% (Orion-heavy batches are affordable, so not the 10% edge).
- Dominant verdict: MISSED_REQUIREMENT (no-op steps, fixed point) and INTEGRATION_ERROR (SQLite
  persistence, fork ids).

### 3. Public API surface (tests assert exactly these)
- `Runner.cut(bounds=None)` - instance method on every runner; `bounds` maps application names to
  notification ids. Unknown name or negative id -> `ValueError`.
- cut `.positions` - dict: every application name in the system -> its notification id at the cut
  (0 when none).
- cut `.processed` - dict: every follower name -> dict: each leader it follows -> highest processed
  notification id of that leader in the kept history (0 when none).
- cut `.get(cls, aggregate_id)` - aggregate of application class `cls` as at the cut;
  `AggregateNotFoundError` if absent at the cut.
- cut `.fork(env)` - new started runner of the same class, constructed with `env`, holding exactly the
  cut state; `ValueError` if any application there already has events.
- FINISH levers: `.notification_log(cls)` (log as at the cut), snapshots in the fork.

### 4. Canonical output form
- positions/processed are plain dicts of ints; 0 for "nothing"; keys: every system node / every
  follower and each of its leaders.
- fork: original notification ids, original tracking, original step history (cuts of the fork agree).

### 5. Blind-spot pre-empts
- iteration-termination / fixed point: "the greatest cut satisfying these rules".
- parallel-API: "every runner".
- falsy-on-invalid: "0 when it has none".

### 6. Description draft
See meta.md (draft). ~390 words.

### 7. File footprint (measured)
| Action | Path | Raw | Hook eff | Reason |
|---|---|---|---|---|
| MODIFY | eventsourcing/persistence.py | 14 | 6 | `ProcessingStep`, abstract `ProcessRecorder.select_steps` |
| MODIFY | eventsourcing/popo.py | 11 | 9 | in-memory step ledger in the atomic update |
| MODIFY | eventsourcing/sqlite.py | 47 | 40 | steps table, row per recording incl. empty tracked insert, select |
| MODIFY | eventsourcing/postgres.py | 76 | 67 | steps table, insert after ids fetched in the same transaction, select |
| MODIFY | eventsourcing/system.py | 183 | 147 | `Runner.cut`, `SystemCut` solver, get, fork, snapshots, `CutNotificationLog` |
TOTAL 331 raw / 269 human-effective / 5 files (full lane); slice = core 284 / 232.

### 8. Solution outline
- ledger write: POPO `_update_table` appends `ProcessingStep(tracking, ids)` when tracking or events;
  SQLite `_insert_events` inserts a steps row in the same transaction; Postgres `_insert_step` after
  ids are fetched, inside the pipeline transaction.
- `SystemCut.__init__`: read histories (process recorders: steps; plain recorders: one step per
  notification), cap each by its bound (longest prefix whose events stay within it), then
  `while changed:` shrink every follower to the longest prefix whose tracked steps stay within each
  leader's current position (monotone, greatest fixed point).
- `get`: scan notifications up to the position for the aggregate's last version, then
  `repository.get(id, version=v)`.
- `fork`: `type(runner)(system, env)`, refuse non-empty targets, replay each kept step through
  `recorder.insert_events(events, tracking=...)` in order (ids, tracking and ledger preserved), copy
  snapshots up to each aggregate's cut version (FINISH), `start()`.

### 9. Test file outline
`tests/system_tests/test_system_cut_<hex>.py`, unittest `TestCase`s. Module-level fixtures: `Counter`,
`Tally`, `Note` aggregates; `Left`/`Right` leaders; `Merge` fan-in process app; `Relay` downstream;
`Spawner` (uuid4 per processed event); `Ping`/`Pong` loop. Tests drive `follow` + `pull_and_process`
explicitly on unstarted runners wherever two leaders feed one follower (SingleThreadedRunner iterates a
`set` of prompted names, hash-seed dependent); started runners only in single-leader chains.
Buckets: positions (fan-in interleave, no-op first step, follower bound + trailing no-op, bound past
head), fixed point (chain declared downstream-first, loop with fan-in), reads (get at cut, absent,
created after cut), fork (ids, tracking, continuation, random-id follower, fork cut agreement,
non-empty target), SQLite (reopen, fork into SQLite files), validation.

### 10. Forced bounds
`bounds` is a mapping by application NAME (`cls.name`); `get` takes the application CLASS; `fork`
takes an env mapping. All stated in meta.

### 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | history from tracking maxima / event rows only | F-47 | L58 escape (discarded state) | storage | 2, 4 | tracking keeps one max per leader; events carry no step | "Processing one notification ... is one step" | fan-in interleave {A:3,B:1} -> F 2 |
| 2 | no-op steps dropped (ledger keyed on events) | F-9 / F-13 | S4 | step granularity | 1, 3, 4 | empty `insert_events` writes nothing on every backend | "even when the policy records no new events" | {A:0} -> F 0; follower bound keeps trailing no-op; fork cut agreement |
| 3 | single pass / least fixed point | F-22 | A7 | graph solving | 2 | order of `system.followers` is edge order, loops have none | "the greatest cut satisfying these rules" | chain declared downstream-first; loop with fan-in |
| 4 | fork renumbers or re-drives | F-59 | S3 | identity | 1, 2 | `Application.save` triggers snapshots/notify; re-running policies makes new uuid4 ids | "under their original notification ids", "each follower tracking its processed positions" | Spawner fork ids equal; fork continuation from processed (not leader) position |
| 5 | ledger kept in memory | F-47 persistence | S3 | persistence | 1 | POPO-first implementation | "A runner over existing SQLite databases computes the same cuts" | SQLite reopen |

### 11b. Cross-product (F-10)
| | POPO | SQLite (reopen) |
|---|---|---|
| event step | fan-in interleave | fan-in interleave after reopen |
| no-op step | {A:0}, follower bound | {A:0} after reopen, fork into SQLite then cut |
Extra cells: bound on follower x trailing no-op; processed < leader position x fork continuation;
untracked save (loop member's direct save) x loop fixed point.

### 12. Tier + category
Olympus, feature-request ("Add").

### 13. Predicted pass rate
20-35%: the solver is transcribable once stated; walls 1, 2 and 5 are integration discoveries; 4 has
an architecture-jump risk (copy the whole database) which the SQLite target + ledger agreement test
blocks.

### 14. Quality gates
- [x] Phase 1 5/5; [x] Phase 2 clean; [x] LOC measured on a working spike (269 full / 232 core)
- [x] traps on different axes, 1-2-4 interdependent; [x] F-10 matrix
- [x] determinism: explicit driving, no timing
- [ ] meta FP audit (FINISH), mutation battery (FINISH)

## Phase 5 - self-audit
- Hidden requirements: none intended; every tested behaviour has a meta sentence.
- Tests pass on base: every test calls `Runner.cut` (absent on base) -> AttributeError, fails per test.
- Over-constraint: no step API is named or tested; storage layout is free.
- Under floor: slice 232 (core), full 269; FINISH target >= 270.

Why not a duplicate: no workspace problem on eventsourcing; closest approved shapes are
customasm-derived-bank-layout (F-22 fixed point over an assembler) and piscsi-image-reservation-identity
(F-59 identity ledger) - different domains and different cores.

Predicted iteration cycles: 2.
