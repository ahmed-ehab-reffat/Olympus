# DESIGN.md - dyn4j-world-copy

Repo dyn4j/dyn4j (538 stars, BSD-3-Clause, Java, 2385 JUnit4 tests), base
bcf942adaa9bfd32a1abd043cbc9021ab158d0ad (= HEAD, release 6.0.0, 2026-07-18).
Hunt: Instructions/repo-hunt-logs/REPO-HUNT-2026-09-23-J.md (RANK 1).

## Phase 1 - repo understanding

Architecture. dyn4j is a 2D rigid-body engine. `World<T>` (world/) = `AbstractPhysicsWorld` on top of
`AbstractCollisionWorld`. A step is: step listeners, optional `detect()` when `updateRequired`,
`ConstraintGraph.solve()` (islands built by DFS over a LinkedHashMap of body nodes; each island runs
`SequentialImpulses` over its contact constraints and joints, warm-started from the impulses stored
on each `SolvableContact`), CCD (`solveTOI` over a second `DynamicAABBTree` keyed by body), then
`detect()` again: the broadphase (`DynamicAABBTree` of body-fixture `CollisionItem`s with expanded
"fat" AABBs, update tracking) emits NEW pairs only, `collisionData` (LinkedHashMap pair -> 
`WorldCollisionData`) keeps every tracked pair, the `DetectIterator` re-checks only pairs whose items
were reinserted, runs narrowphase/manifold, and `processCollisions` updates each `ContactConstraint`
(matching new manifold points to old contacts by id to carry `jn`/`jt`) and rebuilds contact edges.

Subsystems + boundaries: (1) geometry (shapes, transforms), (2) collision/broadphase (tree, Sap,
brute force, item adapter), (3) collision narrowphase/manifold (Gjk, Epa, clipping), (4) dynamics
(bodies, joints, contact constraints, SequentialImpulses, TimeStep, Settings), (5) world (pipeline,
constraint graph, islands, listeners, collision data).

High-entanglement zones: `AbstractCollisionWorld.detect` + `DetectIterator` (broadphase x collision
data x listeners); `AbstractPhysicsWorld.step/processCollisions` (graph x contact constraints x
listeners); `DynamicAABBTree.updateNode/insert` (fat AABB reinsertion decides which pairs are
re-checked and in which order new pairs are found).

Tests: JUnit 4 under src/test/java mirroring packages, `junit.framework.TestCase` asserts, one-line
javadoc per test. Template: src/test/java/org/dyn4j/world/WorldTest.java.

## Phase 2 - existing PR / publicly-solved (canonical org dyn4j/dyn4j, all states)

PR+issue searches: copy, clone, snapshot, serializ, "save state", rollback, determinis, "world copy",
Copyable, prediction, restore, "deep copy", state. Hits: #293 (issue, 2024, body-level Copyable
program, shipped in 6.0.0; the maintainer's contract is "deep copy, nothing on the copy references the
original"; the world was never in scope) and PR #292 (closed; `AbstractCollisionBody` +
`AbstractPhysicsBody` field visibility, 2 files, no world/broadphase/contact code). Discussions: #291
(clone bodies), #300 ("Prediction" - maintainer: the engine does no prediction), #205 (save/load ->
sandbox XML, bodies/joints only), #290 (pair ordering depends on which body moved). Branches: master
only. Forks: JNightRider (master, 0 ahead; old `cloning` branch deleted), OrganizationUsername
(master), victorlira (auto build branches), Ewan-Brown (javadoc). `gh search code` for a dyn4j world
copy: nothing. Box2D / jbox2d / Chipmunk have no world clone; Rapier's serde snapshot is a different
model. CLEAN. Maintainer philosophy (Gate 8): deep copy welcomed; nothing declined.

## Phase 3 - candidates (hunter lane kept)

| Candidate | Shape | Verdict |
|---|---|---|
| World.copy() bit-identical continuation (hunter lane) | O-Composite-add (world+broadphase+contact+dynamics) | PICK |
| Serialization of bodies/joints | maintainer's own slow lane (#293), derivative magnet | reject |
| Deterministic Sap (HashMap -> ordered) | ~5 LOC | reject (sub-floor) |

Step A guard: not a single guard at N sites (the pieces of state fail in different scenarios); not a
single-subsystem transform (4 packages, private state in each); hardness survives full specification
(the contract is one sentence of bit-identity; the fix is discovering which engine state decides
future steps, which the sentence does not reveal); not a memorised port. Step B: lead S4
(machinery-riding: the copy must survive every history the engine supports) + F-1 (convergent
architecture: rebuilding through `addBody`). CONTRACT-STATED/FIX-HIDDEN verified per trap below.

## 1. Title
Add deep copies of physics worlds that continue the simulation exactly

## 2. Shape
O-Composite-add. Best agent Orion (long-horizon). Dominant verdict MISSED_REQUIREMENT
(scenario-shaped divergence). Solver/our LOC ratio ~1.0.

## 3. Public API surface
- `World<T>.copy()` returning `World<T>`; `World` implements `Copyable<World<T>>`.
- `protected World(World<T>)`, `protected AbstractPhysicsWorld(AbstractPhysicsWorld<T,V>)`,
  `protected AbstractCollisionWorld(AbstractCollisionWorld<T,E,V>)` copy constructors.
- `protected V AbstractCollisionWorld.copyCollisionData(V, CollisionPair)` (non-abstract hook).
- `WorldCollisionData(WorldCollisionData<T>, CollisionPair)`, `ContactConstraint.copy(CollisionPair)`,
  `TimeStep.copy()`, `DynamicAABBTree.copy(Map)`, `AbstractBroadphaseDetector.copy(Map)`,
  `CollisionItemBroadphaseDetectorAdapter.copy(Map)`.
- Tests call ONLY `World.copy()` plus base API.
- `CopyException` when a body/joint copy returns another class; `UnsupportedOperationException` for a
  broadphase detector or joint type that cannot be copied (untested, unstated).

## 4. Canonical output form
Body i of the copy is the copy of body i of the original; joint j likewise; collision data iterate in
the original's order with the same body in the first/second role. Bit identity = equality of
`Double.doubleToLongBits` of translation, cos/sin, linear and angular velocity, plus at-rest flag,
after every step. Listeners empty, user data null.

## 5. Blind-spot pre-empts
Result ordering ("in the same order"), parallel-API (step / update / updatev all covered by "the
same calls"), falsy (user data not copied, matching body/joint `copy()`).

## 6. Description draft
See meta.md (draft). One ask sentence, one current-state sentence, then independence, sharing
policy, the bit-identity rule stated over "whatever the original went through before it was copied"
(Rule 7: no list of histories), same collision data / listener events, CopyException, TOI caveat.

## 7. File footprint (slice measured; honest eff = code lines minus javadoc/braces/imports)
| Action | Path | eff |
|---|---|---|
| MODIFY | world/AbstractPhysicsWorld.java (copy ctor, joint remap, graph/contacts/ccd remap) | ~75 |
| MODIFY | world/AbstractCollisionWorld.java (copy ctor, broadphase dispatch, hook) | ~40 |
| NEW | world/WorldCopy.java (body copies + item/pair remap kernel) | ~30 |
| MODIFY | world/ConstraintGraph.java (structural copy) | ~18 |
| MODIFY | world/World.java, WorldCollisionData.java | ~25 |
| MODIFY | collision/broadphase/DynamicAABBTree.java (structural tree copy) | ~35 |
| MODIFY | collision/broadphase/AbstractBroadphaseDetector.java, CollisionItemBroadphaseDetectorAdapter.java | ~8 |
| MODIFY | dynamics/contact/ContactConstraint.java, SolvableContact.java | ~35 |
| MODIFY | dynamics/TimeStep.java | ~8 |
Slice: 12 files, 561 raw, **225 honest human-effective** (the hook reports 461 because it does not
strip Java `*` javadoc lines: 208 of the 561 added lines are javadoc). FINISH adds BruteForce and Sap
copies (~40-50 eff) -> ~265-280. Floor 200 cleared by the slice alone.

## 8. Solution outline
WorldCopy (copies bodies with `Unsafe.copy` in list order, maps body -> copy and body-fixture item ->
new `BasicCollisionItem`, builds copied pairs, null for stale pairs) -> AbstractCollisionWorld copy
ctor (bodies re-owned with a fresh modification handler, bounds copy, broadphase structural copy,
collisionData copied in order through the hook, stale pairs of removed bodies dropped - the
original's own iterator skips them) -> AbstractPhysicsWorld copy ctor (settings/timeStep/gravity
copies, default filter rebound to the copy, CCD tree structural copy keyed by body, joints via
`copy(b1,b2)` / `copy(b)` with a class check, graph structural copy, contactCollisions and
ccdCollisionData remapped, time + updateRequired copied) -> World.copy(). DynamicAABBTree.copy
clones nodes recursively (aabb, height, parent/left/right) and rebuilds leaves/updated in the
original's insertion order.

## 9. Test outline (slice: 10 tests in src/test/java/org/dyn4j/world/WorldCopy0cbf19Test.java)
Helpers: box/ball/ground builders, `stackWithChain()`, `rain()`, `assertSameState` (bit equality per
body with step + body index in the message), `stepBothAndCompare`. Tests: settled stack; moving
scene; unstepped world; after removals; right after a removal; varying step sizes; accumulated update
time; caller-changed contact constraints; independence (+ a twin copy proves mutating one copy leaves
the original on its course); listeners not copied. FINISH adds the cells in 11b.

## 10. Forced bounds
`World.copy()` returns `World<T>` (stated). No new signatures in tests (L72 compile-wipe guard).

## 11. Trap matrix (reproduced by mutants on the reference, `worktrees/dyn4j-probe/mut/`)
| # | Trap | F-id | Class | Axis | Interdep. | Killed by (step of first divergence) |
|---|---|---|---|---|---|---|
| 1 | Broadphase rebuilt through `addBody` (fresh fat AABBs, new topology, all items "updated") | F-1 | S4 | broadphase history | #4 (same updated/tree state) | removal history (59), moving scene copied at 45 (20); NOT the settled stack |
| 2 | Contacts re-detected / impulses not carried | F-9-ish | S4 | contact warm start | #1, #3 | step 1 in 10 of 15 scenes (self-revealing, the floor) |
| 3 | Caller-changed constraint state (enabled, tangent speed) reset by a rebuilt constraint | F-10 | S2 | contact user state | #2 | step 1, only that scene |
| 4 | Pending broadphase updates not carried (copy taken between an add and the next step) | F-10 | A9 | copy timing | #1 | overlap-add scene (FINISH measure) |
| 5 | Previous step size lost (fresh `TimeStep`) | F-10 | S4 | time | #6 | varying step sizes (1) only |
| 6 | Accumulated `update` time lost | F-10 | S4 | time | #5 | accumulator scene (1) only |
| 7 | Pre-solve list / flags not carried: listener added to the copy, collision data queries | F-10 | S2 | observation | #2 | FINISH measure |
| 8 | Abstract hook / interface method breaks the base suite's `TestWorld` / `BP` subclasses | F-12 | S3 | base compile | all | base mode only |
Axes differ per row; #1/#4 and #2/#3 share state so a fix to one path exposes the other.

## 11b. Cross-product (FINISH)
history {settled, moving, removed, just-added, unstepped} x time {fixed, varying, update-accumulated}
x observation {state, collision data, listener events}; off-diagonals: removal x varying dt,
just-added x listener, moving x caller-changed constraint, copy-of-copy x removal.

## 12. Tier/category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. Warm start is found by every self-test; the band sits on #1 (only history-rich scenes), the
time cells and the observation cells, none of which a copy-then-step smoke test on a fresh scene
exercises (P3 self-test shadow).

## 14. Quality gate
Phase 1 5/5; Phase 2 clean (above); title verb-led; API listed; canonical form stated; 0
codebase-inferable requirements; LOC measured on a real slice (225 honest); traps reproduced by
mutation; determinism measured (below).

## Determinism + scope notes (risk 4)
Fresh-vs-fresh, 20 seeded scenes x 300 steps: without bullets tree/Sap/brute force 0/20 diverged;
with three bullets 3/20, 4/20, 4/20 - `solveTOI` groups TOI events in a `HashMap` keyed by body
(identity-hash order, AbstractPhysicsWorld.java ~1411). So the promise needs a caveat for steps where
several bodies need a TOI correction, and tests use at most one fast body. Sap additionally keeps
`nodes` in a `HashMap` (Sap.java:100, iterated in `update()`), so a copy cannot reproduce the
original's iteration order; FINISH decides Sap as "copyable, same pair set" and never asserts Sap
bit identity. Brute force is LinkedHashMap-based and deterministic.

## Why not a duplicate
No approved/in-flight/rejected physics-engine copy in approved-problems/, problems/, rejected/.
Nearest: rmk-portable-configuration-snapshot (config snapshot, different domain). Rival submissions
are invisible: precheck owed (Step 4b).

Predicted iteration cycles: 2.
