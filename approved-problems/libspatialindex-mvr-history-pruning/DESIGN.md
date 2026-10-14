# DESIGN.md - libspatialindex-mvr-history-pruning

Repo: libspatialindex/libspatialindex (canonical, 800 stars, MIT per our approved TPR pick), C++.
Base: 2fb81f6405af70c871ddc0be709cb325e78e9550 (main HEAD, 2026-09-27).
Second libspatialindex problem. The first (approved-problems/libspatialindex-tpr-temporal-knn) lives in
`src/tprtree/*` (TPR-tree kernels, kNN, self-join); this one lives in `src/mvrtree/*` and never touches
a TPR file or a geometry kernel.

## Phase 1 - Repo understanding

Architecture. libspatialindex is a C++ library of three disk-capable spatial indexes (R*-tree, MVR-tree,
TPR-tree) behind one `ISpatialIndex` interface. Every index keeps its nodes as byte pages in a pluggable
`IStorageManager` (memory, disk, a random-eviction buffer in front of either); a node is read by id,
deserialised into a pooled `Node`, mutated and written back. Shapes (`Region`, `TimeRegion`,
`MovingRegion`, ...) live in `src/spatialindex`, generic tools (`PropertySet`, `PointerPool`,
`Interval`) in `src/tools`, and a C API (`src/capi`, consumed by Python `rtree`) wraps everything in
handles plus a buffer.

Subsystems and boundaries:
1. `src/storagemanager` - page stores; `deleteByteArray` returns a page to a free list (`MemoryStorageManager`
   LIFO stack, `DiskStorageManager` ordered set persisted in the .idx file); `NewPage` writes reuse it.
2. `src/mvrtree` - the multiversion R-tree: `MVRTree` (roots list, header, stats, queries), `Node`
   (version copy, split, weak version underflow), `Index`/`Leaf` (chooseSubtree, findLeaf, adjustTree).
3. `src/tprtree`, `src/rtree` - sibling indexes (untouched).
4. `src/spatialindex` - shapes and their interval predicates (`TimeRegion::intersectsInterval`).
5. `src/capi` - handles, error stack, `Index_*MVR*` calls.

High-entanglement zones:
- `Node::insertData` version copy (Node.cc 380-620): copies LIVE entries of a full node into a new node,
  sets the old node's end time, and for a root appends a new `RootEntry` and a `m_treeHeight` slot. The
  old node keeps every child pointer, so live children are SHARED by the old and the new version, and the
  old page is not rewritten for a non-root node: its own end time stays at +max. Dead-ness of a non-root
  node lives ONLY in its parent's entry.
- `Node::deleteData` weak version underflow (Node.cc 760-1030): kills a node and re-inserts its live
  children (whole subtrees) under other parents - a second source of shared pages.
- `MVRTree::storeHeader/loadHeader` (MVRTree.cc 851-1055): roots, stats (`m_u32Nodes`, per-root heights,
  per-level page counts, dead counters), current time; a fixed layout with no version field.

Test framework: GoogleTest 1.14 vendored in `test/gtest`, one executable `libsidxtest`
(`test/gtest/CMakeLists.txt`), helpers in `test/gtest/NativeTestSupport.h`. Template:
`test/gtest/MVRTree.cpp` (insert/delete/query against an exhaustive version history).

## Phase 2 - Existing-PR / publicly-solved / SIX-CHECK (run 2026-09-29)

CANON = `gh api repos/libspatialindex/libspatialindex -q .full_name` = libspatialindex/libspatialindex.
- PR + issue search, all states: prune, pruning, purge, vacuum, garbage, history, horizon, deleteNode,
  "old versions", "MVRTree delete", mvrtree, reclaim, "free pages", compact, expire, retention,
  multiversion, multi-version, pruneHistory, PruneMVRHistory, "prune history", "MVRTree memory",
  "MVRTree size", "old roots", "time horizon", version, temporal, "delete old", grow. No hit implements
  pruning, page reclamation or version GC.
- Every mvrtree PR diff read by file set: #315 (OPEN, NaN-safe split selection: Node.cc rtreeSplit /
  rstarSplit / pickSeeds + tests), #311 (CLOSED, pooled-node leak + Time shape leaks), #282 (warnings),
  #208 (MovingPoint/Region fixes), #41/#49 (C API MVR, locking). None touches root trimming, page
  deletion, the header layout or query clipping. EXCLUSIVITY: CLEAN.
- hobu's 2026-09-25..27 leak sweep (#307-#314): C API error stack, obj-query return codes, STR merge,
  TPR moving-shape leaks, one bulk-load record leak; branch `mvrtree-leak-fixes` = PointerPoolNode delete
  + TimeRegion/TimePoint coordinate ownership. Memory hygiene, not history. Capability overlap: none.
- Philosophy scan: no "by design"/"won't add"/declined text on MVR storage growth. Issue #263 is RTree
  kNN perf notes. No closed-with-implemented hit.
- Base->HEAD overlap: base IS HEAD. Open #315 may land in mvrtree/Node.cc later (split selection
  only); re-check at submit.
- Existing capability: `MVRTree::deleteNode` is defined and never called (grep); `m_roots` only grows
  (probe: 19 roots after 2000 ops, all kept); `getNumberOfNodes()` == live pages, never decreases.

Local dedup: `rejected/`, `problems/`, `approved-problems/` grepped for prune/purge/vacuum/gc/history/
retention/version/mvr/compact/reclaim: only agate-validity-interval-history (table interval methods,
different class). Quota: libspatialindex 1 approved, this is the 2nd.

PICK-FILTER gates: 1 PASS (no pruning at all; storage grows forever; F2P through the new API),
5 PASS (capability cold; mvrtree touched only by lint/leak sweeps), 6 PASS (reproduced on base with
`_probe/probe1.cc`), 7b PASS (above), 8 PASS (MVBT/MV3R literature purges old versions; no maintainer
decline), 9 base suite deterministic (see eval-results), 10 quota 1/6.

## Phase 3 - Candidates

| Candidate | Behaviour | Files | Meaningful | Verdict |
|---|---|---|---|---|
| A. pruneHistory core (drop dead roots/pages, clip queries, persist horizon, C API) | page GC + query clipping | 5 | 146 (measured) | under floor alone |
| B. A + archive visitor (hand every discarded record version out once) | + version reconstruction from fragments | 5 | 217 (measured) | PICK (slice) |
| C. B + retention window property (auto-prune on insert/delete, persisted, C API property) | + policy wired into mutation paths | 7 | ~265 est | FINISH lever |
| D. MVR internalNodesQuery | unrelated missing arm | 1 | ~25 | dead (missing arm) |
| E. MVR nearest neighbour | derivative of our own approved TPR kNN | 2 | ~80 | dead (self-derivative) |

TOO-EASY guard on B: (1) not a uniform wrap: page GC (reachability over a DAG with shared pages),
query clipping, per-record lifetime reconstruction and header versioning are separate mechanisms;
(2) not a single-subsystem transform: storage manager + mvrtree + C API + persisted header;
(3) hardness does not rely on the spec hiding anything: every rule is stated; the walls are code-side
(stale end times, shared children, fragments); (4) not a memorised port: no public MVR-tree GC to copy;
(5) survives full specification: yes. Pointwise-decoupled? No - a page's fate depends on every path to it.

Machinery-absorbed check: the repo owns `deleteNode`, `deleteEntry` and free-list reuse; those are
2-line calls. The LOC lives in NEW content: live-set marking, sweep over all versions, compaction,
live-bound refresh, fragment reconstruction, header versioning. Measured 217 human-eff on the working
reference, so not absorbed.

## 1. Title
Add history pruning with archiving to the MVR-tree

## 2. Shape
O-Pipeline-hard-like / Mars D-new-like: new capability threaded through storage, tree, header and C API,
with an invented algorithm (version-fragment reconstruction). Target <= 40% (design to ~20-30%).
Dominant verdict predicted: MISSED_REQUIREMENT (archive once / page set) + REGRESSION (queries after
reuse). Best agent: Orion.

## 3. Public API surface
- `SpatialIndex::MVRTree::pruneHistory(ISpatialIndex& index, double horizon)` (spatialindex/MVRTree.h)
- `SpatialIndex::MVRTree::pruneHistory(ISpatialIndex& index, double horizon, IVisitor& archive)`
- `RTError Index_PruneMVRHistory(IndexH index, double horizon)` (capi/sidx_api.h)
- Errors: `Tools::IllegalArgumentException` (not an MVR-tree / non-finite horizon / horizon later than
  current time); C API `RT_Failure` + pushed error.
- Existing API whose behaviour changes after a prune: `intersectsWithQuery`, `containsWhatQuery`,
  `pointLocationQuery`, `Index_MVRIntersects_*`, `getStatistics()->getNumberOfNodes()`, `loadMVRTree`.

## 4. Canonical output form
- Query window after pruning: `[max(qs, horizon), qe]`; `qe < horizon` visits nothing. The repo's own
  time predicate (`start < qe && end > qs`) is otherwise unchanged.
- Kept page set: exactly the pages reachable from a root with end > horizon through entries with
  end > horizon. Everything else deleted.
- Archive: one `visitData` per record version with end <= horizon (and > previous horizon), shape
  `TimeRegion(box, max(insertTime, previousHorizon), deleteTime)`, id and bytes as inserted. Order
  unspecified (tests sort).
- Horizon <= previous: no-op. Rejected call: no change.

## 5. Blind-spot pre-empts
- Rule resolution: "a root whose lifetime ends after the horizon leads to it through entries whose
  lifetimes all end after the horizon" (defines reachability on ENTRIES, never on a node's own page).
- Dedup: "handed to the archive ... once"; "a record version is what one `insertData` call stored".
- Iteration termination: none stated (no unbounded promise, L44).
- Compatibility: "An index written before this change still opens" (L84 persisted layout).

## 6. Description draft
See meta.md (kept in sync; ~390 words).

## 7. File footprint (measured on the reference slice)
| Action | Path | Raw | Human-eff |
|---|---|---|---|
| MODIFY | src/mvrtree/MVRTree.cc | 255 | 177 |
| MODIFY | src/mvrtree/MVRTree.h | 17 | 13 |
| MODIFY | src/capi/sidx_api.cc | 29 | 24 |
| MODIFY | include/spatialindex/MVRTree.h | 2 | 2 |
| MODIFY | include/spatialindex/capi/sidx_api.h | 2 | 1 |
TOTAL 305 raw / 217 human-eff / 5 files. FINISH lever C (retention window) adds ~45-50 across
MVRTree.cc/h, sidx_api.h/.cc and capi Utility/IndexProperty, target >= 260.

## 8. Solution outline
- `pruneHistory(horizon, archive*)`: validate; archive; `collectPrunedNodes`; delete pruned pages
  through `deleteNode` with per-level and dead-counter bookkeeping; `compactNode` every kept page;
  trim `m_roots` and `m_treeHeight` together; `refreshLiveBounds` from the current root; store the
  horizon; `storeHeader`.
- `collectPrunedNodes`: mark (stack over roots with end > T, follow entries with end > T), then sweep
  (visit every page reachable from every root through every entry; unmarked = pruned). Reads happen
  before any delete.
- `archiveEndedVersions`: bottleneck-path worklist gives every node its lifetime end = max over paths
  of the min entry end; each leaf entry becomes a fragment clipped to that end; fragments chain when
  same id + box + bytes and one starts where the previous ends; chains ending <= T are visited once,
  start clipped to the previous horizon.
- `compactNode`: drop entries with end <= T via `deleteEntry`, restoring the node's own lifetime (the
  emptied-node branch resets `m_nodeMBR` to the infinite region).
- `refreshLiveBounds`: post-order over live entries; parent entry box := child box; recompute tight MBR.
- `rangeQuery`: clip the interval into a `TimeRegion` window; return when `qe < horizon`.
- Header: append the horizon; `loadHeader` reads it only when the stored header is long enough.
- C API: `Index_PruneMVRHistory` with the file's three-catch pattern.

## 9. Test outline
New executable `mvrtree_history_test` from `test/gtest/MVRTreeHistory_<hex>.cpp`; base mode keeps
`libsidxtest` untouched. Helpers: recording storage manager (tracks live page ids), a public-API page
walker (`queryStrategy` + `INode`, format-independent), a seeded workload with an exact version history,
an archive visitor, a query oracle. Buckets:
1. page set exact after pruning at several horizons (memory store, capacity 10, deep DAG).
2. `getNumberOfNodes()` equals the pages kept; kept pages hold no entry ended <= horizon.
3. query clipping: straddling, before (nothing), at the horizon, after; intersects / contains / point.
4. operations after pruning (inserts reuse freed pages; oracle still exact); prune twice.
5. archive exactly once per record version incl. version-copy fragments, id reuse with same box,
   deletion exactly at the horizon, clipped start on the second prune.
6. validation: NaN, later than current time, RTree index, earlier horizon no-op (tree untouched).
7. persistence: disk store, flush, reopen, horizon + node count kept; legacy base-layout header opens.
8. C API: prune through `Index_PruneMVRHistory`, error on an R-tree handle.

## 10. Forced signatures
`IVisitor&` overload (not a pointer, not `std::function`); free functions in namespace
`SpatialIndex::MVRTree`; C API returns `RTError`. All pinned in meta.md by full call shape (L72).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Test |
|---|---|---|---|---|---|---|---|
| 1 | Garbage hangs off DEAD ENTRIES inside surviving versions; pruning dead roots only keeps it (cap 16, T=end: 28 needed vs 118 kept) | F-47 (discarded state) candidate | S4 | page set, under-prune | #2 | "remove old versions" reads as "remove old roots" | page-set exact |
| 2 | Shared pages: deleting a dead root's or dead entry's whole subtree frees pages a live version still uses (up to 25 per prune on probes); the free list hands them out again, so later inserts corrupt the live tree | new (candidate F-66) | S3 | over-prune, surfaces later as wrong query answers | #1, #4 | recursive subtree delete is the idiomatic GC | ops-after-prune oracle |
| 3 | A record version is split into fragments by every leaf version copy / underflow reinsertion; the non-final fragments sit in dead leaves with a stale +max end. Per-entry archiving reports duplicates and copy-time starts; grouping by id merges a reused id | F-47 / F-13 (unit granularity) | S2 | archive identity | #1 (same traversal) | natural archive = iterate pruned leaves | archive exact, id-reuse cell |
| 4 | Header gains a field; base headers carry none | L84 | A-tier persisted layout | persistence | #2 (stats) | appending unconditionally reads past the buffer | legacy header opens |
| 5 | Queries ending before the horizon: filtering entries by end > T still returns long-lived records | F-10 cell | S2 | query window | #1 (dead entries) | filter instead of clip | before-horizon query |
| 6 | Records deleted before T while their leaf lives on are only removed by compaction; archiving only pruned pages misses them | F-15-like | S2 | archive completeness | #3 | archive keyed to deleted pages | archive exact |

## 11b. F-10 cross-product
| | memory store | disk store + reopen | C API (buffered) |
|---|---|---|---|
| explicit prune | page set, archive | reopen horizon + count | Index_PruneMVRHistory + MVR query |
| second prune | archive clipped start | reopen then prune again (FINISH) | - |
| query before / straddling / at / after horizon | intersects x contains x point | after reopen | Index_MVRIntersects_id |

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. Probe convergence risk: mark-sweep is textbook; the band rests on #1/#2 (page set exact + reuse
after prune), #3 (fragment reconstruction) and #4 (legacy header).

## 14. Quality gates
Phase 1 5/5; Phase 2 clean (commands above); closest approved opened (libspatialindex-tpr-temporal-knn:
Dockerfile, test.sh, C API test style); API names pinned; canonical forms above; 0 codebase-inferable
requirements; description plain prose; LOC measured 217 (>= 200, FINISH target >= 260 with lever C);
F-10 matrix filled; L82 respected (no `isIndexValid()` assertion in new tests); L84 legacy layout test;
L72 full call shapes in meta; L56 in-process only.

Why not a duplicate: the TPR pick added query kernels to `src/tprtree`; this adds storage GC and version
reconstruction to `src/mvrtree`. No shared file except the C API header.
Predicted iteration cycles: 3.

## FINISH addendum (2026-10-01)

Lever C (candidate C above) built. Public API added to section 3:
- `HistoryRetention` property: finite, non-negative `Tools::VT_DOUBLE`, accepted by `returnMVRTree` at
  create and at reopen (a reopen value replaces the stored one), reported by `getIndexProperties` only
  when set, stored in the header after the horizon.
- `IndexProperty_SetHistoryRetention(IndexPropertyH, double)` / `IndexProperty_GetHistoryRetention`.
- Behaviour: after every `insertData` / `deleteData` call, prune to current time minus retention with no
  archive. Opening never prunes.

File footprint now 411 raw / 297 human-eff over the same 5 files (MVRTree.cc 203, sidx_api.cc 73,
MVRTree.h 16, sidx_api.h 3, include MVRTree.h 2).

Trap matrix additions:
| # | Trap | F-id | Axis | Interdependent with | Test |
|---|---|---|---|---|---|
| 7 | Retention hooked only on insert (or only on successful paths); deletes advance the current time too | F-15-like (attempt vs effect) | mutation path coverage | #1/#2 (auto-prune runs the same GC every call, so a shared-page bug surfaces on the very next insert) | RetentionPrunesAfterEveryInsertionAndDeletion, ZeroRetention |
| 8 | Automatic horizon is the "previous horizon" for a later archive call | F-10 cell | archive start | #3 | ArchiveAfterRetentionStartsAtTheLastAutomaticHorizon |
| 9 | Retention persisted next to the horizon, replaced on reopen, not applied on open | L84 / F-10 persistence cell | persistence | #4 | RetentionIsStoredAndReplacedOnlyWhenGivenAtReopen |

Trap #4 made measurable: the legacy test turns on storage slack (32 bytes of 0x41 after every page), so an
unguarded header read picks up a horizon near 2.3e6.

F-10 cells filled: reopen then prune again (archive starts at the stored horizon), prune at exactly the
current time with an insert and a delete at that instant, retention x reopen, retention x archive,
retention x C API.
