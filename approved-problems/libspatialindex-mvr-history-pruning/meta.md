---
Repository: https://github.com/libspatialindex/libspatialindex
Issue: N/A
Commit: 2fb81f6405af70c871ddc0be709cb325e78e9550
Language: C++
Category: feature-request
Title: Add history pruning with archiving to the MVR-tree
---

# Add history pruning with archiving to the MVR-tree

Extend the MVR-tree with a historical pruning technique.

We need `SpatialIndex::MVRTree::pruneHistory(ISpatialIndex& index, double horizon)` and `pruneHistory(ISpatialIndex& index, double horizon, IVisitor& archive)` methods. Every horizon is later than the previous one and not later than the start of the newest insertion or the end of the newest deletion. A record is never deleted at the time it was inserted, and two live records never share both ID and box.

After pruning, `intersectsWithQuery` returns no results for queries ending at the horizon or earlier and answers queries starting before the horizon as if they started there.

A node page is kept only if some root that expires beyond the horizon has a path to it through entries that all expire beyond the horizon. Other pages are purged from the storage manager, and the index statistics only count the pages that remain: `getNumberOfNodes()`, the numbers of dead index and dead leaf nodes, and the pages in each level. Other operations work as before. The horizon is kept across `flush()` and `loadMVRTree()`. Older indexes must stay openable and prunable.

With an archive, every record version that the call discards, and no other, is passed to `visitData(const IData&)` exactly once. A record version is what a single call to `insertData` stored, and it is discarded if it was deleted on or before the horizon. The data includes the record ID and contents and a `TimeRegion` with the inserted box, from the time of insertion or the previous horizon, whichever is later, to the time of deletion.
