# libspatialindex-tpr-temporal-knn - eval results

Batch 1 (10x Nova, 2026-09-20): **7/10 = 70% pass - over the 40% ceiling, too-easy**. Platform
precheck passed 2026-09-20; Auto Review APPROVED; Solution Quality PASS. Hardening round 2 added the
entry-expiry wall (a description delta), so batch 2 is full price and unmeasured.

## Local validation (SLICE, 2026-09-19)

Image `factory-libspatialindex-tpr-temporal-knn` (olympus-base-cpp, Release, Ninja), cold build ~2 min.
Clean room: fresh clone at 494d966f + test.patch, run as uid 1000 with --network none.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 11 | 11 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 11 | 0 | 3 | yes |

Patch order: solution then test applies cleanly; solution unapplies cleanly.
Effective LOC (hook): 302 raw / 214 human-effective / 4 files.
Mutation battery: 8/8 mutants killed (table in feedback.md).

## Local validation (FINISH, 2026-09-20)

Same image, rebuilt from the cleanroom clone (base + test.patch + Dockerfile). Cold `docker build`
109 s, well inside the 600 s environment-start budget (L62). Every run below is uid 1000,
`--network none`, `HOME=/tmp`.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 30 | 30 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 30 | 0 | 3 | yes |

Every one of the 30 new tests fails on base, and each fails on the missing capability (the
`not implemented yet` throw, the range-query shape rejection, the `IEvolvingShape` insert guard or a
C API error code), not on a compile error: the new test target builds against the base tree because no
test calls a symbol the solution adds.

Patches apply in both orders against BASE_COMMIT and `solution.patch` reverse-applies cleanly.
JUnit: 27 and 30 `<testcase>` nodes, no duplicate `classname::name` ids, no `::` inside any name.
Effective LOC (hook): 360 raw / 259 human-effective / 5 files, padding-floor 113.

### Mutation and false-positive battery (FINISH)

16 mutants, each the natural wrong implementation of one stated rule, applied to a pristine copy of the
reference inside the container and run against BOTH modes (L33). `mutate.py` asserts its replacement
lands, so a silently no-op mutation cannot be scored as "kills nothing". Counts are new-mode failures out
of 29 (the battery ran before the 30th test, the identical-geometry cell, was added) and base-mode
failures out of 27.

| Mutant | Natural wrong implementation | new | base |
|---|---|---|---|
| M1 | default comparator left velocity blind | 14 | 0 |
| M2 | kernel evaluates endpoints and breakpoints, no quadratic vertex | 3 | 0 |
| M3 | per-dimension minima summed | 5 | 0 |
| M4 | index entries ranked with the static distance | 2 | 0 |
| M5 | self-join checks the three overlaps at independent instants | 2 | 0 |
| M6 | leaf data sent to the comparator's shape overload | 1 | 0 |
| M7 | TimeRegion dispatched before MovingRegion | 5 | 0 |
| M8 | entries extrapolated from time 0 | 3 | 0 |
| M9 | containment read at the interval start only | 2 | 0 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 8 | 2 |
| M11 | moving point query normalised with zero velocity | 4 | 0 |
| M12 | entries still required to implement `IEvolvingShape` | 1 | 0 |
| M13 | `pointLocationQuery` still wrapping its point in a static `Region` | 2 | 0 |
| M14 | horizon guard dropped from the range path | 1 | 0 |
| M15 | C API query region built through the constructor | 1 | 0 |
| M16 | reversed interval clamped instead of rejected | 2 | 0 |

16 of 16 killed, and no two mutants have the same kill set, so every stated rule has at least one test
that reacts to it alone. M10 is the baseline-preservation signal: narrowing the range queries with the
inherited static predicates also fails 2 of the repo's own 27 tests, so the shared-machinery axis is
live and visible in base mode as well (L33). These counts measure what the suite DETECTS, not what
agents get wrong (L15); the band prediction stays with the batch.

### Assertion-flip check

Five expected values were flipped at once in a copy of the suite (a distance, an id set, a pair count,
a containment set, a boundary distance), one per test, on top of the correct reference. Exactly those
five tests failed and no others, so each flipped assertion is load-bearing and nothing leaks between
cases.

### Flakiness gate

Each of the four configurations was run 3 times in the container and compared by (test count, failure
count, set of failing test ids): all three runs identical in every configuration.

| Configuration | Runs | Tests | Failed | Verdict |
|---|---|---|---|---|
| base tree, base mode | 3 | 27 | 0 | identical |
| base tree, new mode | 3 | 30 | 30 | identical |
| solution tree, base mode | 3 | 27 | 0 | identical |
| solution tree, new mode | 3 | 30 | 0 | identical |

Nothing in the suite reads the clock, the network, the filesystem timestamps or an unseeded generator:
the two random scenes are built by a fixed-seed LCG inside the test file, and every fixture asserts a
separation margin so no result depends on rounding.


## Local validation (R2 - solution-quality FAIL closed, 2026-09-20)

Reference fixed for the two high issues from the pre-batch solution-quality review (non-positive
`max_dist` must mean unbounded; moving-shape constructors must accept a degenerate interval so that
query, `insertData` / `deleteData` and the time-parameterised C calls all take a single instant), plus
10 new tests for the requirements the test-fairness report listed as untested or not discriminating.
`meta.md`, `Dockerfile` and `BASE_COMMIT.txt` are unchanged.

Image rebuilt cold from `worktrees/libspatialindex-cleanroom` (base + test.patch + Dockerfile),
`docker build` 119 s. Every run below is uid 1000, `--network none`, `HOME=/tmp`.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 40 | 40 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 40 | 0 | 3 | yes |

All 40 new tests still fail on base and none fails on a compile error: the new test target builds
against the base tree because no test calls a symbol the solution adds. The two new C API object tests
use `ASSERT_EQ` on the RTError and `ASSERT_TRUE(items != nullptr)` so a base-mode failure reports as a
failed assertion rather than a null dereference.

Patches apply against BASE_COMMIT in both orders and `solution.patch` reverse-applies cleanly.
JUnit: 27 and 40 `<testcase>` nodes, all ids unique, no `::` inside any name.
Effective LOC (hook): 349 raw / 250 human-effective / 5 files, padding-floor 112. `src/capi/sidx_api.cc`
dropped out of the patch entirely - the C API needed no change once the constructors accepted an instant.

### Mutation and false-positive battery (R2)

20 mutants, each the natural wrong implementation of one stated rule, applied to a pristine copy of the
reference inside the container and run against BOTH modes. `mutate.py` asserts its replacement lands.
Counts are failures out of 40 (new) and out of 27 (base).

| Mutant | Natural wrong implementation | new | base |
|---|---|---|---|
| M1 | default comparator left velocity blind | 19 | 0 |
| M2 | kernel evaluates endpoints and breakpoints, no quadratic vertex | 3 | 0 |
| M3 | per-dimension minima summed | 5 | 0 |
| M4 | index entries ranked with the static distance | 3 | 0 |
| M5 | self-join checks the three overlaps at independent instants | 3 | 0 |
| M6 | leaf data sent to the comparator's shape overload | 2 | 0 |
| M7 | TimeRegion dispatched before MovingRegion | 5 | 0 |
| M8 | entries extrapolated from time 0 | 7 | 0 |
| M9 | containment read at the interval start only | 2 | 0 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 10 | 2 |
| M11 | moving point query normalised with zero velocity | 5 | 0 |
| M12 | entries still required to implement `IEvolvingShape` | 1 | 0 |
| M13 | `pointLocationQuery` still wrapping its point in a static `Region` | 2 | 0 |
| M14 | horizon guard dropped from the range path | 1 | 0 |
| M15 | moving shape constructors still refuse a degenerate interval | 11 | 0 |
| M16 | reversed interval clamped instead of rejected | 2 | 0 |
| M17 | `max_dist` tested for truthiness instead of `> 0` | 1 | 0 |
| M18 | nearest results buffered and emitted farthest first | 1 | 0 |
| M19 | self-join reports each pair in both orders | 7 | 0 |
| M20 | boxes must overlap over a positive time span, touching ignored | 12 | 0 |

20 of 20 killed and all 20 kill sets are distinct, so every stated rule has at least one test that
reacts to it alone. M17 and M18 are killed by exactly one test each - the two new tests written for the
two requirements the fairness report called untested - and M12, M14 are the other single-test mutants.
M10 remains the baseline-preservation signal: it is the only mutant that also reds the repo's own suite.

Three tests are killed by no mutant: `EntriesTiedWithTheKthDistanceAreAllReported`,
`NothingVisitedReturnsZero` and `QueriesOutsideTheHorizonAreRejected`. All three fail on base, so they
still discriminate against a missing implementation; no mutant in the battery targets their axis.

### Flakiness gate (R2)

Each of the four configurations was run 3 times in the container and compared by (test count, failure
count, set of failing test ids): all three runs identical in every configuration. The new tests add no
clock, network, filesystem-time or unseeded-RNG dependence - the two C API tests use an in-memory
storage manager and the counting comparator counts calls, not time.


## Batch 1 - 10x Nova (2026-09-20)

| Run | Verdict | Failed | Failing tests |
|---|---|---|---|
| Nova 1 | fail | 5 | CApiReturnsTheNearestMovingObjects, CApiReturnsTheNearestMovingObjectsAsItems, NearestOnADeepTreeWithInsertionTimesAndMaximumDistance, NearestUsesTheClosestApproachInsideTheInterval, StationaryEntriesCanBeInsertedAndDeleted |
| Nova 2 | fail | 2 | ContainmentHoldsAtEveryInstant, RangeQueriesMatchExhaustiveSearchOnADeepTree |
| Nova 3 | pass | 0 | |
| Nova 4 | pass | 0 | |
| Nova 5 | fail | 4 | IntersectionQueriesAcceptEveryTimeShape, PointLocationUsesTimePoints, RangeQueriesMatchExhaustiveSearchOnADeepTree, SelfJoinMatchesExhaustiveSearchOnADeepTree |
| Nova 6 | pass | 0 | |
| Nova 7 | pass | 0 | |
| Nova 8 | pass | 0 | |
| Nova 9 | pass | 0 | |
| Nova 10 | pass | 0 | |

Three distinct root causes, each in one run: breakpoint minima missing from the distance kernel,
containment quantified over a subinterval instead of the whole interval, and the common-instant
window reset per dimension instead of intersected across them. All ten runs passed the 27 baseline
tests. Every evaluator rated the task "challenging", the description clear and the tests
deterministic; none flagged cheating or environment trouble.

## Hardening round 1 (2026-09-20) - two measurements, no fair lever

### Replay harness

Pristine clone at BASE_COMMIT + each run's `src/`/`include/` patch + the candidate `test.patch`,
built and run in the clean-room image as uid 1000 with `--network none`. It reproduces batch 1
exactly (Nova 3 clean, Nova 1 the same five failures), so for a tests-only delta it predicts a
re-eval rather than approximating one.

### Measurement A - 16 candidate tests, 0 new kills

| Suite | Nova 1 | Nova 2 | Nova 3 | Nova 4 | Nova 5 | Nova 6 | Nova 7 | Nova 8 | Nova 9 | Nova 10 | Pass rate |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 40 tests (shipped) | 5 | 2 | 0 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 7/10 |
| 56 tests (hardened) | 5 | 6 | 0 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 7/10 |

The 16 added tests cover both Auto Review follow-ups, all six advisory coverage suggestions, and a
previously empty axis (every fixture in the suite used a rigid box, `vlo == vhi`; the new ones use
boxes whose low and high corners move at different velocities, through intersection, containment,
nearest, self-join and a 70-entry deep tree). They killed nobody who was not already failing.

### Measurement B - 57-probe differential harness, 0 divergences among passers

A standalone probe program prints one canonical line per contract cell and was run against all ten
saved solutions and the reference: nearest `k`/`max_dist` boundaries, distance values on growing
boxes and breakpoint geometry, entry motion past its insertion shape's end, range and
point-location grids, self-join across all four query shapes plus instant/touching/identical/single
/empty cases, the full validation matrix, mutation acceptance, and the temporal C API.

| Probes | Cells diverging from the reference | Among the 7 passers |
|---|---|---|
| 57 | 2 (`pl_plain` - Nova 5 only; `v_nn_horizon_edge` - Nova 1 only) | **0** |

Both divergences belong to runs that already fail. The seven passing solutions are behaviourally
identical to the reference across every probed cell, which is the measured form of "no fair lever
remains".

### Artifact state after the round

The 16 tests and the `k == 0` reference fix were kept - they close the Auto Review follow-ups and
cost nothing - so the artifact is consistent and fully validated at 56 tests.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 56 | 56 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 56 | 0 | 3 | yes |

Effective LOC (hook): 351 raw / 251 human-effective / 5 files.


## Hardening round 2 (2026-09-20) - entry expiry, description delta

One meta.md sentence now says an entry stops moving at the end of the interval of the shape it was
inserted with. Because the delta is solver-visible, the replay harness cannot price it and no
re-eval is offered; batch 2 is the only measurement.

### Clean-room validation (63 tests)

Image rebuilt cold from `worktrees/libspatialindex-cleanroom`; every run uid 1000, `--network none`,
`HOME=/tmp`.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 63 | 63 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 63 | 0 | 3 | yes |

The repo's own 27 tests pass unchanged on both trees: the base suite inserts through a helper that
already uses an open-ended interval, so the expiry rule is additive for existing usage. Patches
apply against BASE_COMMIT in both orders and `solution.patch` reverse-applies cleanly.

Effective LOC (hook): 476 raw / **342 human-effective** / 7 files, padding-floor 139 (was 251 / 5).
`src/tprtree/Node.cc` and `Node.h` enter the patch for the first time - the node page format now
carries each child's end of motion, which base writes nowhere and reads back as infinity.

### Mutation battery (16 mutants, both modes)

| Mutant | Natural wrong implementation | new | base |
|---|---|---|---|
| E1 | entry stored with an infinite end of motion, as base does | 6 | 0 |
| E2 | end of motion not written to or read back from the node page | 6 | 0 |
| E3 | predicates read raw extrapolated coordinates and rates | 6 | 0 |
| E4 | node velocity bounds not relaxed for children that can stop | 3 | 0 |
| E5 | containment evaluated at the interval endpoints only | 1 | 0 |
| E6 | common-instant window solved over a single piece | 1 | 0 |
| E7 | minimum distance solved over a single piece | 1 | 0 |
| M1 | default comparator left velocity blind | 24 | 0 |
| M4 | index entries ranked with the static distance | 5 | 0 |
| M6 | leaf data sent to the comparator's shape overload | 3 | 0 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 20 | 2 |
| M12 | entries still required to implement `IEvolvingShape` | 1 | 0 |
| M15 | moving shape constructors still refuse a degenerate interval | 3 | 0 |
| M17 | `max_dist` tested for truthiness instead of `> 0` | 1 | 0 |
| M19 | self-join reports each pair in both orders | 10 | 0 |
| M20 | boxes must overlap over a positive time span, touching ignored | 19 | 0 |

16 of 16 killed. E1, E2 and E3 share a kill set because they are three layers of the same axis; E4
through E7 are distinct sub-axes, so an implementation has to get every layer right rather than one.
M10 remains the only mutant that also reds the repo's own suite.

E7 killed nothing on the first run, which exposed a genuine hole: a single-piece distance solver is
only wrong when the interval midpoint lands past the stop while the true minimum lies before it.
`NearestFindsTheClosestApproachBeforeAnEntryStops` was written for exactly that geometry and is now
its sole killer.

### Fixtures re-derived for the new contract

Six existing tests inserted entries with a finite interval and therefore changed meaning. The five
C API fixtures now insert with an open end (matching the repo's own `tprInsertData` helper), and
`MovingPointEntriesCanBeInsertedAndDeleted` was rewritten so its moving point runs from t=1 to t=2
and is then asserted to still be at its stopping position at t=9.

### New tests for the expiry axis

`EntriesStopMovingAtTheEndOfTheirInsertionInterval`, `ContainmentSeesAnEntryStopInsideTheInterval`
(an entry contained at both interval endpoints but not at the stop instant, which is what defeats
the endpoint-sufficiency shortcut every batch-1 passer relies on),
`SelfJoinMeetingHappensOnlyAfterAnEntryStops` (a pair that can only meet because one entry stopped),
`NearestUsesTheDistanceAfterAnEntryStops`, `NearestFindsTheClosestApproachBeforeAnEntryStops`,
`DeepTreeWithStoppedEntriesMatchesExhaustiveSearch` (70 entries, capacity 4, staggered stop times -
the only test that sees unsound node bounds, and it sees them as a silently missing id) and
`CApiEntriesStopAtTheEndOfTheirInsertionInterval`.

The test oracles are stop-aware too: `Mover` carries a stop time, and the intersection, containment
and distance oracles split at the stop instants independently of the reference's own algebra.


## Round 3 (2026-09-20) - review findings closed, meta.md untouched

Test Quality FAIL (1 of 63 unfair) and both Solution Quality FAIL issues addressed. No solver-visible
description change, so the artifact still awaits the same full-price batch that round 2 needs.

### Changes

| Finding | Action |
|---|---|
| `ZeroNeighboursVisitsNothing` unfair (k = 0 unstated; sibling `RTree.cc:609-617` supports visiting zero-distance ties) | test dropped, reference `k == 0` guard kept. Round 1's replay measured that guard in all 7 batch-1 passers, so the test killed nobody |
| advisory: exact comparator call count couples to traversal strategy | `EXPECT_EQ(12u, dataCalls)` relaxed to `EXPECT_GE(..., 12u)`; still kills M6, which produces zero data calls |
| high: stopped entries pruned when inserted at the same current time | `boundExpiringChildren()` moved out of the two `insertEntry` branches and called on every path |
| high: unversioned page format corrupts existing indexes | `m_pageFormat` written to and read from the tree header; `Node::entryTimeFields()` drives size, store and load, so a legacy index is read and written in its own layout with unbounded entry end times |
| advisory: mutation shape matrix | `MovingRegionEntriesCanBeDeleted` added |
| advisory: reversed/wrong-dimension cases on insert/delete | declined - the prompt sentence begins "A query shape", so mutations are out of its scope and the reviewer asks for a prompt change first. Adding the test would repeat the unstated-behaviour defect that just failed Test Quality |

### Clean-room validation (65 tests)

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 65 | 65 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 65 | 0 | 3 | yes |

Effective LOC (hook): 515 raw / **369 human-effective** / 7 files, padding-floor 152.

### Mutation battery (18 mutants, both modes)

| Mutant | Natural wrong implementation | new | base |
|---|---|---|---|
| P1 | node bounds relaxed only inside the two `insertEntry` branches (the reviewer's repro) | 3 | 0 |
| P2 | header carries no format word, so the loader always assumes the legacy layout | 1 | 0 |
| E1 | entry stored with an infinite end of motion, as base does | 8 | 0 |
| E2 | end of motion not written to or read back from the node page | 8 | 0 |
| E3 | predicates read raw extrapolated coordinates and rates | 8 | 0 |
| E4 | node velocity bounds not relaxed for children that can stop | 5 | 0 |
| E5 | containment evaluated at the interval endpoints only | 1 | 0 |
| E6 | common-instant window solved over a single piece | 1 | 0 |
| E7 | minimum distance solved over a single piece | 1 | 0 |
| M1 | default comparator left velocity blind | 27 | 0 |
| M4 | index entries ranked with the static distance | 5 | 0 |
| M6 | leaf data sent to the comparator's shape overload | 3 | 0 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 23 | 2 |
| M12 | entries still required to implement `IEvolvingShape` | 1 | 0 |
| M15 | moving shape constructors still refuse a degenerate interval | 3 | 0 |
| M17 | `max_dist` tested for truthiness instead of `> 0` | 1 | 0 |
| M19 | self-join reports each pair in both orders | 10 | 0 |
| M20 | boxes must overlap over a positive time span, touching ignored | 22 | 0 |

18 of 18 killed. P1 and P2 are the two review findings turned into traps, and each is killed by the
regression written for it: `AStoppingEntryStaysFoundBesideAnIdenticalMover` (an unbounded mover and
an identical mover ending at t = 1, both inserted at t = 0) and `AReloadedTreeKeepsEachEntrysEndOfMotion`
(close the tree, reopen it through `loadTPRTree`, re-run the queries). M10 remains the only mutant
that also reds the repo's own suite.


## Round 4 (2026-09-20) - per-page format versioning

Round 3's header-level `LegacyEntries` mode made a reopened legacy tree drop the end of motion of
NEWLY inserted finite-duration entries. Replaced by a per-page flag: the node type word now carries
`PersistentEntryEndTimes`, `storeToByteArray` always writes end times, `loadFromByteArray` consumes
them only when the page says so, and `readNode` masks the flag before choosing the node kind. The
header format word and the insert special case are gone; `insertData` always stores the supplied end.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 65 | 65 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 65 | 0 | 3 | yes |

Effective LOC (hook): 495 raw / **358 human-effective** / 8 files, padding-floor 153. Zero comments
added to the solution.

### Mutation battery (18 mutants, both modes)

| Mutant | Natural wrong implementation | new | base |
|---|---|---|---|
| P1 | node bounds relaxed only inside the two `insertEntry` branches | 4 | 0 |
| P2 | loader ignores the page's layout flag | 62 | 2 |
| E1 | entry stored with an infinite end of motion, as base does | 8 | 0 |
| E2 | end of motion not read back from the node page | 8 | 0 |
| E3 | predicates read raw extrapolated coordinates and rates | 8 | 0 |
| E4 | node velocity bounds not relaxed for children that can stop | 5 | 0 |
| E5 | containment evaluated at the interval endpoints only | 1 | 0 |
| E6 | common-instant window solved over a single piece | 1 | 0 |
| E7 | minimum distance solved over a single piece | 1 | 0 |
| M1 | default comparator left velocity blind | 27 | 0 |
| M4 | index entries ranked with the static distance | 5 | 0 |
| M6 | leaf data sent to the comparator's shape overload | 3 | 0 |
| M10 | range queries narrowed with the inherited static `Region` predicates | 23 | 2 |
| M12 | entries still required to implement `IEvolvingShape` | 1 | 0 |
| M15 | moving shape constructors still refuse a degenerate interval | 3 | 0 |
| M17 | `max_dist` tested for truthiness instead of `> 0` | 1 | 0 |
| M19 | self-join reports each pair in both orders | 10 | 0 |
| M20 | boxes must overlap over a positive time span, touching ignored | 22 | 0 |

18 of 18 killed. P2 is honestly a page-integrity mutant, not a targeted discriminator: the legacy read
path can only be reached with a page written by the pre-change library, which no in-repo test can
produce, so the flag is recorded as defensive code. P1 gained a fourth killer because the reload test
now inserts after reopening. M10 and P2 are the only mutants that also red the repo's own suite.


## Batch 2 - 10x Nova (2026-09-21): 0/10, blocked by an unfair assertion

| Run | Failed | Failure kinds |
|---|---|---|
| Nova 1 | 8 | answer mismatches (containment with stops, growing boxes, deep-tree range) |
| Nova 2 | 1 | `isIndexValid` only |
| Nova 3 | 11 | answer mismatches |
| Nova 4 | 4 | answer mismatches |
| Nova 5 | 1 | `isIndexValid` only |
| Nova 6 | 13 | answer mismatches |
| Nova 7 | 1 | `isIndexValid` only |
| Nova 8 | 8 | answer mismatches |
| Nova 9 | 1 | `isIndexValid` only |
| Nova 10 | 1 | `isIndexValid` only |

49 failures total: **40 answer mismatches and 9 `isIndexValid()` assertion failures**, the latter all
inside `DeepTreeWithStoppedEntriesMatchesExhaustiveSearch`, which failed 10/10. All ten runs passed
the 27 baseline tests.

`isIndexValid()` recomputes each node bound and demands exact equality with the stored one, so once
entry expiry forces bounds to stay sound for a stopping child, any sound-but-different bookkeeping
fails it while every query answer is correct. meta.md never mentions it. All seven
`ASSERT_TRUE(isIndexValid())` calls were removed from the suite; the repo's own base tests keep
theirs and stay green, because their entries never expire.

## Round 5 (2026-09-21) - Auto Review revision + fair band measurement

### Replay of the batch-2 solutions against the revised suite

| Suite | Nova 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Pass |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 65 tests, as run | 8 | 1 | 11 | 4 | 1 | 13 | 1 | 8 | 1 | 1 | 0/10 |
| 71 tests, assertion removed | 8 | 0 | 11 | 3 | 0 | 13 | 0 | 8 | 0 | 0 | **5/10** |

Four new composition cells (`SelfJoinPairsWithTwoDifferentStopTimes`,
`AnEntryStoppingAtAnIntervalBoundary`, `NearestAcrossTwoStopInstants`, a second deep stopping scene)
killed none of the five passers.

### Clean-room validation (71 tests)

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 71 | 71 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 71 | 0 | 3 | yes |

Effective LOC (hook): 360 human-effective / 8 files. meta.md 490 words, under the 500 cap.

### Auto Review fixes

`insertData` and `deleteData` now reject a reversed interval before any conversion or state change
(`deleteData` previously assigned the unchecked upper bound to the tree's current time).
`ZeroNeighboursVisitsNothing` is restored for both overloads, now that meta.md states "A k of 0
visits nothing", and the rejection sentence explicitly covers mutation shapes.


## Round 6 (2026-09-21) - four-kind closure on mutations

`getVelocityBounds` deleted; `insertData` and `deleteData` now normalise through the same
`getShapeRegion` the queries use (renamed from `getQueryRegion`), so a shape outside the four kinds
is rejected identically on every entry point.

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 73 | 73 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 73 | 0 | 3 | yes |

Effective LOC (hook): 483 raw / **350 human-effective** / 8 files. Zero comments added.

Replay of the five batch-2 passers against all 73 tests: **5/5 still pass**. The closure gap was in
the reference only; their own normalisers already restrict mutations to the four kinds and already
validate the point-location horizon. Fair band stays **5/10 = 50%**.


## Batch 3 - 10x Nova + 2x Orion (2026-09-21): 5/12 = 42%

| Run | Verdict | Failed |
|---|---|---|
| Nova 1 | fail | 4 |
| Nova 2 | pass | 0 |
| Nova 3 | fail | 4 |
| Nova 4 | pass (FP-voided) | 0 |
| Nova 5 | fail | 31 |
| Nova 6 | fail | 0 - evaluator failed it for the unversioned node layout |
| Nova 7 | pass | 0 |
| Nova 8 | pass | 0 |
| Nova 9 | fail | 7 |
| Nova 10 | fail | 8 |
| Orion 1 | fail | 3 |
| Orion 2 | pass | 0 |

Nova 4/10, Orion 1/2. All twelve passed the 27 baseline tests. The FP panel voided Nova 4 on the
legacy-persistence probe, giving a graded 4/12 = 33%.

## Round 7 (2026-09-21) - backward compatibility stated and tested

`AnIndexFromAnEarlierReleaseStillLoads` writes a legacy leaf page by hand in the base layout,
overwrites a real tree's root page with it, reloads through `loadTPRTree` and asserts the entry keeps
moving. meta.md states the rule in one behavioural sentence (498 words total).

### Replay against the batch-3 runs with a clean suite

| Run | 73 tests | 74 tests |
|---|---|---|
| Nova 2 | 0 failures | 1 - `AnIndexFromAnEarlierReleaseStillLoads` |
| Nova 4 | 0 | 1 - same |
| Nova 6 | 0 | 1 - same |
| Nova 7 | 0 | 1 - same |
| Nova 8 | 0 | 1 - same |
| Orion 2 | 0 | 0 |

### Clean-room validation (74 tests)

| Tree | Mode | Tests | Failed | Runs | Identical |
|---|---|---|---|---|---|
| base + test.patch | base | 27 | 0 | 3 | yes |
| base + test.patch | new | 74 | 74 | 3 | yes |
| + solution.patch | base | 27 | 0 | 3 | yes |
| + solution.patch | new | 74 | 0 | 3 | yes |

Mutants re-verified at 74 tests: `P2_no_page_version_flag` (writer and loader with no flag, i.e. the
agents' implementation) kills exactly `AnIndexFromAnEarlierReleaseStillLoads`, 1 of 74;
`E1_entries_never_stop` 11, `E3_kernels_ignore_stops` 11, `E4_node_bounds_not_relaxed` 6,
`P1_relax_only_in_branches` 5.
