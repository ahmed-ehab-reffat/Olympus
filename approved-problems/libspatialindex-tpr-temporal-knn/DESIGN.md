# DESIGN.md - libspatialindex-tpr-temporal-knn

## 1. Title

Add time-aware nearest-neighbour and self-join queries to the TPR-tree

## 2. Shape classification

- Shape: O-Algorithm-correctness on the repo's own moving-object model (SHAPES.md section Pattern 11): one new
  interval kernel (smallest distance between two linearly moving boxes, each extrapolated from its own
  reference time, over a closed time interval) that feeds best-first index pruning, leaf ranking, the
  default comparator, ties/max_dist and the C API; plus a second kernel (a single common instant at which
  three moving boxes overlap) that drives a pairwise node traversal for the self-join.
- Pass rate target: 20-35%. Best agent: Orion. Dominant verdict: MISSED_REQUIREMENT (kernel edge,
  composition cell), with a silent WRONG-RESULT on deep trees when index entries are pruned with a
  static distance.
- Solver/our LOC ratio: ~1.2x (best-first loop is copyable from RTree, the kernels are not).

## Phase 1 - Repo understanding

**Architecture.** libspatialindex is a C++ spatial-index library with three trees behind one
`ISpatialIndex` interface (`include/spatialindex/SpatialIndex.h`): the R*-tree (`src/rtree`), the MVR-tree
(`src/mvrtree`, historical, entries carry a lifetime) and the TPR-tree (`src/tprtree`, moving objects). Shapes
live in `src/spatialindex`: `Region`/`Point`, `TimeRegion`/`TimePoint` (static geometry plus an interval) and
`MovingRegion`/`MovingPoint` (geometry at a reference time `m_startTime`, velocities, `getExtrapolatedLow/High`).
A TPR entry is stored as a `MovingRegion` whose `m_startTime` is its insertion time and whose end is
`numeric_limits<double>::max()`; a TPR node MBR is a `MovingRegion` re-anchored to the tree's `m_currentTime`
whenever it is adjusted (`Node.cc:332`, `Index.cc:303`), with velocity bounds so it contains its children for
every later time. `insertData` refuses times older than `m_currentTime` (`TPRTree.cc:260`); range queries accept
only a `MovingRegion` whose interval lies inside `[m_currentTime, m_currentTime + m_horizon)` (`TPRTree.cc:1193`).
Storage is paged through `IStorageManager`; visitors receive `IData`/`INode`; a C API (`src/capi`) wraps every
tree, including `Index_TPNearestNeighbors_obj/_id` (`sidx_api.cc:1475`, `:1716`) that construct a `MovingRegion`
and call `nearestNeighborQuery`.

**Subsystems.** (1) shape library `src/spatialindex` (Moving*/Time* kernels); (2) TPR tree `src/tprtree` (insert,
delete, adjust, range query); (3) R-tree `src/rtree` (the kNN/self-join template: `RTree.cc:589`, `:1492`);
(4) MVR tree `src/mvrtree` (root forest, version copies, dedup by id in `rangeQuery`); (5) C API `src/capi`.

**High-entanglement zones.** The TPR node MBR re-anchoring (every node carries its own reference time);
`MovingRegion`'s inherited static `Region` API (`getMinimumDistance`, `intersectsRegion`,
`getIntersectingRegion` compile on a `MovingRegion` and silently ignore velocity and time); the
`INearestNeighborComparator` contract (issue #276: 2.1 routed RTree leaf data through the shape overload,
maintainer "we want to support this interface ... dereference your own data").

**Tests.** gtest under `test/gtest` (27 tests in `libsidxtest`, Codex-ported, `NativeTestSupport.h` helpers,
in-memory storage, exhaustive oracles). Template: `test/gtest/TPRTree.cpp` (TPR insert/delete/query vs an
exhaustive oracle). Legacy `test/tprtree/*` generators are not run (disabled after #247 flakiness under Debug
asserts). New tests: `test/gtest/TPRTreeTemporal_48145d.cpp`, own executable `tprtree_temporal_test` so base
mode (libsidxtest) stays compilable and untouched.

## Phase 2 - Existing-PR + publicly-solved check (run 2026-09-19)

Canonical org: `gh api repos/libspatialindex/libspatialindex -q .full_name` = `libspatialindex/libspatialindex`
(no move). PR searches, all states: `nearest`, `TPRTree`, `TPR`, `selfJoin`, `self join`, `not implemented`,
`moving`, `kNN`, `MVRTree`, `temporal`, `time parameterized`, `nearestNeighbor`. Hits and diffs read:
#279 (OPEN, RTree.cc/.h only, unique_ptr), #277 (OPEN, RTree.cc 1-line revert of 6fe9ff76), #266/#265/#255
(RTree kNN perf), #38 (2014, C API TP wrappers only), #208 (MovingPoint/MovingRegion fixes, no kNN), #248 (test
script). None touches TPR kNN/join. Issues: #276 (comparator data overload, RTree), #247 (TPR test flakiness,
maintainer: "That index type needs more attention and proper testing"), #99/#83/#175 unrelated. No decline, no
design. `git log --all -S` on the throws: present since the 2007 import (`e2dbbb6`), never implemented, never
removed; ChangeLog/NEWS silent. One branch only. GitHub code search: ~30 vendored `TPRTree.cc` copies, all with
the throw; no `getMinimumDistanceInTime`; repo search "TPR-tree" finds only a 0-star toy (UbertoGC/TPR-Tree,
56 lines, no kNN) and a ctypes wrapper. Boost.Geometry has no TPR tree. Local dedup (`problems/`, `rejected/`,
`approved-problems/`, `diamond-problems/`): no spatial-index or moving-object kNN pick.

## Phase 3 - Candidates

| Candidate | One-line behavior | Shape | Files | Raw | Meaningful | Predicted | Verdict | Reject? |
|---|---|---|---|---|---|---|---|---|
| A. TPR interval kNN + self-join (this pick) | nearest over an interval with a new moving-box kernel + common-instant self-join | O-Algorithm-correctness | 4 | ~300 | 214 measured | 25-40% | MISSED_REQ | keep |
| B. MVR historical kNN + join | kNN over the root forest, liveness + version-copy dedup | missing-arm-ish | 2 | ~150 | ~100 | 50%+ | MISSED_REQ | reserve only (breadth) |
| C. TPR range queries for every time shape and instants | point location on TPR throws at base (`Region` is not moving) | bug fix | 2 | ~60 | ~40 | 70%+ | reject alone, keep as FINISH depth |
| D. TPR internalNodesQuery | throws at base; trivial traversal | missing arm | 1 | ~25 | ~15 | 90% | reject |
| E. Continuous kNN (answer as a function of time) | textbook Tao/Papadias CNN | textbook | 3 | ~400 | ~300 | ? | reject: famous algorithm, derivative magnet |

**Step A (TOO-EASY guard) on A.** 1 uniform wrap: no, two kernels plus four independent contract seams
(query-form dispatch, comparator overload, reference time, horizon). 2 single-subsystem transform: no, shape
library + tree traversal + comparator contract + C API. 3 hardness from the spec hiding something: no, every
rule below is stated; the traps are the wrong-but-natural implementations of stated rules. 4 memorised port: the
closest external concept is Tao/Papadias TP-kNN; the repo's semantics (entries extrapolated from their own
insertion time, node MBRs from their own adjust time, the RTree tie/max_dist rules, the comparator overloads)
are repo-specific. 5 survives full specification: yes, measured below (M2/M3/M4 fail with the rule stated).
Pointwise-decoupled check: the kNN is best-first over a whole tree (pruning couples every entry to its
ancestors' bounds), the join is pairwise over node pairs. Machinery-absorbed check: the repo has NO
interval-minimum distance (only the integral of centre distance, `getCenterDistanceInTime`) and no
common-instant test (`intersectsRegionInTime` checks two shapes, asserts on degenerate intervals); the ~210
measured lines are new mathematics plus traversal.

**Step B (arsenal).** Lead: S2 composition (every dimension close at the SAME instant; three boxes overlapping
at the SAME instant) + S4 machinery riding (index entries carry their own reference times) + A4 host-language
(dynamic_cast order: `MovingRegion` is-a `TimeRegion`). F-39 inherited-helper: `MovingRegion` inherits a static
`getMinimumDistance`/`getIntersectingRegion`; the default `NNComparator` is velocity blind. F-20 flavour: the
sibling RTree loop feeds leaf shapes to the comparator's shape overload.

## 3. Public API surface

- `TPRTree::nearestNeighborQuery(uint32_t k, const IShape& q, IVisitor& v, double max_dist = 0.0)` - k nearest
  over q's interval with the default time-aware comparator; returns the distance of the last reported entry.
- `TPRTree::nearestNeighborQuery(uint32_t k, const IShape& q, IVisitor& v, INearestNeighborComparator& c, double max_dist = 0.0)`
  - same search, every distance asked of `c` (shape overload for index entries, data overload for data).
- `TPRTree::selfJoinQuery(const IShape& q, IVisitor& v)` - every unordered pair of distinct entries that overlap
  each other and q at one instant of q's interval, reported once through `visitData(std::vector<const IData*>&)`.
- C API `Index_TPNearestNeighbors_id/_obj` - unchanged signatures, now answer.
- Reference also adds `MovingRegion::getMinimumDistanceInTime(const IInterval&, const MovingRegion&)` and
  `MovingRegion::intersectsRegionAtSameInstant(const IInterval&, const MovingRegion&, const MovingRegion&)`;
  tests never call them (base compiles, and agents keep freedom of placement).
- Errors: `Tools::IllegalArgumentException` for wrong dimension, a shape without a time interval, an interval
  whose start is after its end, and an interval outside the horizon.

## 4. Canonical output form

- Query shapes: `MovingRegion`, `MovingPoint`, `TimeRegion`, `TimePoint`. A static time shape does not move; a
  moving shape's coordinates are its position at its interval start. Start == end is one instant.
- Distance: smallest Euclidean box-to-box distance (0 when overlapping, touching counts) at any single instant
  of the closed interval; entries move from their insertion time.
- kNN order: ascending distance; entries tied with the k-th distance are all reported; max_dist 0 = no limit,
  otherwise entries farther than max_dist are not reported; return value = distance of the last reported entry,
  0 when nothing is reported. Order among ties is unspecified (tests compare sorted id sets).
- Join: each unordered pair once, the two data entries in either order; tests normalise pairs and also count.

## 5. Blind-spot pre-empts

- Pipeline placement / reference time: "an entry moves from the time it was inserted".
- Adjacent-vs-all: "at a single instant" (both in distance and join), never "at some time".
- Rule resolution: "every distance the search uses" names both entry kinds and both overloads.

## 6. Description draft

See `meta.md` (draft 1, ~390 words, YAML frontmatter first).

## 7. File footprint (measured on the reference spike)

Slice (2026-09-19, 4 files, 302 raw / 214 human-eff) and FINISH (2026-09-20, 5 files, 360 raw / 259
human-eff, padding-floor 113). Measured by the hook on the generated solution.patch:

| Action | Path | Raw | Human-eff | Reason |
|---|---|---|---|---|
| MODIFY | include/spatialindex/MovingRegion.h | +4 | 3 | kernel declarations |
| MODIFY | src/spatialindex/MovingRegion.cc | +143 | 99 | interval distance (breakpoints + per-piece quadratic vertex), common-instant half-line intersection, containment at every instant |
| MODIFY | src/tprtree/TPRTree.cc | +194 | 141 | query normalisation, entry velocity bounds, horizon guard, best-first kNN, time-aware comparator, pairwise self-join, range-query rewiring, pointLocationQuery |
| MODIFY | src/tprtree/TPRTree.h | +7 | 6 | comparator/helper declarations |
| MODIFY | src/capi/sidx_api.cc | +12 | 10 | time-parameterised query construction that accepts an instant |
| TOTAL | 5 files | 360 | **259** (hook) | |

Floor check at FINISH: 259 human-effective, 5 files, clears the 200 floor and the 250 target. The plan
below was executed as (a); (b) was NOT taken (see the FINISH round note at the end of this file):
(a) TPR range queries (`intersectsWithQuery`, `containsWhatQuery`, `pointLocationQuery`) accept the same four
time shapes and instants through the same normalisation and the common-instant kernel. `pointLocationQuery`
on a TPR tree throws at base (it wraps the point in a static `Region`), so this is a real F2P, ~40 eff, and it
adds an S3 baseline-preservation seam (the two existing TPR range tests must keep passing).
(b) Reserve (only if (a) leaves the hook under 250): MVR-tree historical kNN + self-join over the root forest
(liveness against the query interval, dedup of version copies by identifier, nearest version wins), ~100 eff.
It must not carry the band. Projected 255-350 human-eff.

## 8. Solution outline

- `getQueryRegion(IShape, MovingRegion&)` - dispatch Moving* before Time*; zero velocity for static shapes.
- `validateQueryInterval` - horizon guard identical to range queries.
- `MovingRegion::getMinimumDistanceInTime` - per-dimension gap `max(0, b.lo - a.hi, a.lo - b.hi)` is piecewise
  affine; breakpoints where either affine piece crosses 0 or the two cross; on each piece the squared distance is
  a quadratic, evaluate endpoints and the vertex. Instant = one evaluation.
- `MovingRegion::intersectsRegionAtSameInstant` - every overlap condition is an affine inequality in t, so the
  feasible set is an interval: intersect half-lines, non-empty iff lo <= hi.
- `NNComparator` (default) - time-aware via the two helpers; data overload goes through `getShape`.
- `nearestNeighborQuery` - RTree best-first loop; leaf data through `nnc.getMinimumDistance(query, IData)`.
- `selfJoinQuery(id1, id2, q, v)` - node pairs in lockstep, `c2` starts at `c1` when the node is paired with
  itself, skip the diagonal at leaves, prune any pair (and any single child against q) without a common instant.

## 9. Test outline (slice 11 tests; FINISH 30 tests)

`test/gtest/TPRTreeTemporal_48145d.cpp`: builders (`Mover`, `pointMover`, `boxMover`, `Scene`, shape
factories), oracle (`oracleDistance` = ternary search on the convex distance, independent of the reference
kernel), tests: closest approach mid-interval; every dimension at the same instant (k=1 and k=2, return value);
entries move from their insertion time; moving query box; deep tree (capacity 4, 60 movers, k=1/4/7) vs the
oracle; ties at the k-th; max_dist; custom comparator data overload; self-join common instant; horizon/untimed
rejections; C API.

FINISH added 19 more, all failing on base: static query box measured from its edges; kNN at a single instant
of a moving query (point and box); a second deep tree (70 movers) crossing insertion times with a max_dist
cut between two oracle ranks; an entry exactly at max_dist; nothing-visited returns zero; reversed interval
and wrong dimension rejections on three entry points; stationary entries inserted and deleted as a
`TimeRegion` and a `TimePoint`; deep-tree self-join against an exhaustive triple oracle (60 movers); self-join
at a single instant; self-join ignoring overlap outside the interval; identical-geometry pair; intersection
queries for all four shapes; range queries at a single instant; touching at either end of the interval;
containment at every instant (including a follower box that keeps an entry inside for the whole interval but
not the instant case); point location through time points and moving points; a third deep tree (80 movers)
comparing intersects, contains and point location against exhaustive oracles; range-query rejections; C API
single instant for intersects, count and nearest.

Both exhaustive oracles are independent of the reference: the distance oracle is a ternary search on the
convex distance function, and the overlap oracle solves the affine half-line system in the test file. Each
oracle asserts a separation margin (>1e-6) on every fixture entry, so no cell rests on float noise (L75).

## 10. Forced bounds

`INearestNeighborComparator` has two pure virtual overloads; a test comparator implements both. `IVisitor`
pair callback takes `std::vector<const IData*>&`. No new signature is forced on agents.

## 11. Predicted trap matrix (reproduced on the reference, clean room, 2026-09-19)

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Natural wrong impl (mutant) | Killed by |
|---|---|---|---|---|---|---|---|
| 1 | Default comparator stays velocity blind | F-39 | S4 | distance model | 2,3,4 (all ride the comparator) | M1 | 7 tests |
| 2 | Closest approach needs the quadratic vertex when both gaps are open | new | A-tier naive reading | kernel | 3 | M2 (endpoints + breakpoints only) | same-instant, deep tree |
| 3 | Per-dimension minima summed (a lower bound, not the distance) | new | S2 | kernel | 2, 4 (valid for pruning, wrong for ranking) | M3 | same-instant, deep tree |
| 4 | Index entries pruned with the static distance while leaves use the time-aware one | F-39 | S4 | traversal | 1 | M4 | deep tree only (silent wrong ids) |
| 5 | Entries/query extrapolated from a shared time instead of their own reference times | new | S4 | reference time | 1 | M8 | 3 tests |
| 6 | `TimeRegion` tested before `MovingRegion` in the dispatch | A4 | A4 | query form | 7 | M7 | moving box |
| 7 | Leaf data fed to the comparator's shape overload (RTree loop copy) | F-20 flavour | S3 | comparator | - | M6 | custom comparator |
| 8 | Join checks the three overlaps separately (different instants) | new | S2 | join | 9 | M5 | self-join window |
| 9 | Join narrows with inherited static `getIntersectingRegion` (RTree copy) | F-39 | S4 | join | 8 | (FINISH mutant) | FINISH deep join cell |

All eight reproduced mutants fail, each on its own discriminator (see feedback.md mutation table).

## 11b. Cross-product matrix (F-10) - filled at FINISH

Axis 1 = query form, axis 2 = query family. Every cell below is exercised by at least one test, and the
instant column is the off-diagonal that costs no description words.

| query form \ family | kNN over an interval | kNN at an instant | intersects | contains | point location | self-join |
|---|---|---|---|---|---|---|
| TimePoint | closest-approach, ties, max_dist | reference-time test | (point location) | - | time-point cell | instant join |
| TimeRegion | static-box edges, deep tree + max_dist | boundary/touching | every-shape, deep-tree oracle | every-instant, deep-tree oracle | - | window join, instant join |
| MovingPoint | deep tree vs oracle | moving-instant cell | every-shape | - | moving-point cell | - |
| MovingRegion | moving query box | moving-instant cell | every-shape, deep-tree oracle | follower box | - | deep-tree join |

Entry form is a third axis: entries are inserted as moving regions everywhere, and as a `TimeRegion` and
a `TimePoint` in the stationary-entries test, which then reads them back through kNN, an intersection
query and `deleteData`. The touching cell is tested for intersects, contains and kNN at once, on integer
coordinates (L75). The identical-geometry cell covers two distinct entries with the same box and velocity
(pair reported, self-pairing not reported, tie at distance 0).

Scope audit: distance is scoped to the query INTERVAL and to one instant (stated). Format-noun audit: "entry"
= a data entry (not an index entry) wherever a result is described. Tolerance audit: max_dist uses a strict
"farther than" (N-1 fixture = an entry exactly at max_dist is reported, FINISH, on binary-exact geometry).

## 12. Tier + category

Olympus; category feature-request (title "Add ...").

## 13. Predicted pass rate

25-40% before FINISH hardening. The copyable parts (best-first loop, ties, max_dist) are free; the kernel
cells, the deep-tree pruning cell, the query-form cell and the join composition carry the band. Risk: a strong
agent that derives the convex-minimum kernel and uses it everywhere passes everything in the slice, so FINISH
must add the F-10 cells above plus the join deep-tree cell.

## 14. Quality gates (slice)

- [x] Phase 1 5/5; [x] Phase 2 clean (commands above); [x] closest approved opened (kira-loop-crossfade DESIGN,
  openexr C++ harness); [x] title verb-led; [x] shape declared; [x] API listed; [x] canonical form; [x] 0
  codebase-inferable requirements beyond "moves from insertion time" (stated anyway); [x] description <500
  words; [x] footprint measured (214 eff, FINISH plan to 255+); [x] traps reproduced (8 mutants);
  [ ] F-10 off-diagonal cells (FINISH); [ ] float audit on FINISH boundary cells (L59/L75: exact values only at
  endpoints or dyadic vertices, EXPECT_NEAR 1e-9 elsewhere).

## Why this is not a duplicate

Closest approved: none in spatial indexing. Nearest shape: `metpy-parcel-trajectories` (unrelated domain).
Exclusivity risk is the magnet: the two `not implemented yet` throws are visible to any author scanning
`src/tprtree`. Only the platform precheck can see a rival; Step 4b exists for exactly that.

Predicted iteration cycles: 2-3.

---

## FINISH round (2026-09-20)

Platform precheck passed with no warnings, so nothing in the design was declined or reworked. The round
executed plan (a) from section 7 and deliberately did NOT take reserve (b), the MVR-tree historical kNN
and join.

Why (b) was declined. It is a second index type with its own semantics (root forest, entry lifetimes,
version-copy dedup), so it would be breadth rather than coupling: a solver who has written the TPR
best-first loop reuses it there with two extra rules that the repo's own `MVRTree::rangeQuery` already
demonstrates (a `visitedData` set and an `intersectsInterval` liveness test). HARDENING's law that
breadth dilutes, failure-patterns L58 (machinery beside a kernel is LOC and FP insurance, not band) and
L61 (a breadth-only program can kill every run through a pre-existing bug outside the feature) all point
the same way, and TOO-EASY's scope-lever rule adds that a bolted-on second feature doubles the collision
surface without differentiating the core. The LOC floor did not need it: the range-query work took the
hook from 214 to 259 human-effective over 5 files, above the 200 floor and the 250 target, so (b) would
have bought scope at the cost of the band and of FP exposure.

What (a) actually changed, beyond the slice. `rangeQuery` now normalises its query through the same
`getQueryRegion` the kNN uses, so `intersectsWithQuery`, `containsWhatQuery` and `pointLocationQuery`
accept a moving region, a moving point, a time region or a time point and a single instant; the
containment arm moved to a new exact kernel (`containsRegionAtEveryInstant`, endpoints only, which is
exact because each bound is affine in time); `pointLocationQuery` stopped wrapping its argument in a
static `Region` and now answers; `insertData` and `deleteData` take velocity bounds through
`getVelocityBounds`, so a stationary entry may be given as a time region or a time point; and the C API's
time-parameterised query construction accepts a degenerate interval so the C entry points can ask about
an instant.

Traps added by (a), each reproduced by a mutant (counts in feedback.md):

| # | Trap | F-id | Axis | Natural wrong implementation | Mutant |
|---|---|---|---|---|---|
| 10 | Range queries narrowed with the inherited static `Region` predicates | F-39 | range-query distance model | copy the R-tree leaf test, which ignores velocity | M10 |
| 11 | Containment read at the interval start only | F-11 local-vs-global | temporal quantifier | "contains" evaluated at one instant instead of every instant | M9 |
| 12 | Query forms that carry no velocity treated as static when they do move | F-18 form parity | query form | a moving point normalised with zero velocity | M11 |
| 13 | Entries still required to implement `IEvolvingShape` | F-24 residual-throw | entry form | keep the base guard, so a stationary entry cannot be indexed | M12 |
| 14 | `pointLocationQuery` left wrapping its point in a static region | F-24 | query family | the base body, which throws | M13 |
| 15 | Horizon and reversed-interval guards dropped from the rewired range path | F-20 sibling behaviour | rejection | validate in the kNN only | M14, M16 |
| 16 | C API still building its query region through the constructor | F-31 twin surface | C API | the constructor refuses a degenerate interval | M15 |

Section 11's traps 1 to 9 are unchanged and still reproduced (M1 to M8).

Baseline preservation (S3 / F-12). Base mode builds and runs `libsidxtest`, which covers the R-tree, the
MVR-tree, the TPR-tree and the shape library. The natural way to make the shape library time-aware is to
change `Region`'s own predicates, and that reds the base suite rather than the new tests, so the
preservation axis is live and is measured on every mutant run (every mutant above was run against base
mode as well as new mode, per L33).
