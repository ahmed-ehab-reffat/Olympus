---
Repository: https://github.com/libspatialindex/libspatialindex
Issue: N/A
Commit: 494d966f57727060d3cc6ac39a50ca5694dad5e8
Language: C++
Category: feature-request
Title: Add time-aware nearest-neighbour, self-join and range queries to the TPR-tree
---

# Add time-aware nearest-neighbour, self-join and range queries to the TPR-tree

Add nearest-neighbour and self-join queries to the TPR-tree, and let its three range queries answer over a time interval as well. Today both `nearestNeighborQuery` overloads and `selfJoinQuery` throw "not implemented yet", so the C API calls `Index_TPNearestNeighbors_id` and `Index_TPNearestNeighbors_obj` fail as well, while the range queries take a moving region and nothing else, and `pointLocationQuery` never answers.

A query shape, and a shape handed to `insertData` or `deleteData`, may be a `MovingRegion`, a `MovingPoint`, a `TimeRegion` or a `TimePoint`. Its time interval is closed, and a start equal to the end asks about that single instant. A moving shape's coordinates are its position at its start time and it moves linearly from there, while a time region or a time point stays where it is. An entry moves from the start time of the shape it was inserted with until that shape's end time, and holds the position it reached from then on; an entry inserted with a shape whose interval has no end never stops. The time-parameterised C API calls accept a start equal to the end too.

A shape of any other kind, an interval that starts after it ends, and a shape with the wrong number of dimensions are rejected with `Tools::IllegalArgumentException`, whether the shape is a query or is handed to `insertData` or `deleteData`. A query interval that starts before the tree's current time, or that ends at or after the current time plus the tree's horizon, is rejected the same way.

Two boxes meet when they overlap or when they only touch. `intersectsWithQuery` visits the entries that meet the query at a single instant of its interval, `containsWhatQuery` visits the entries the query contains at every instant of its interval, and `pointLocationQuery` visits the entries that meet the query point at a single instant of its interval.

The distance between the query and an entry is the smallest distance between the two boxes at any single instant of the interval, and it is 0 when they meet.

`nearestNeighborQuery(k, query, visitor, max_dist)` visits data entries in ascending order of that distance and stops after k, except that every entry at the same distance as the k-th is also visited. A k of 0 visits nothing. When `max_dist` is greater than 0, no entry farther than `max_dist` is visited. It returns the distance of the last visited entry, or 0 when nothing was visited. The overload that takes an `INearestNeighborComparator` runs the same search but asks the comparator for every distance it uses: the shape overload for index entries and the data overload for data entries.

`selfJoinQuery(query, visitor)` reports every pair of distinct data entries for which there is a single instant of the query interval at which the two entries and the query box all meet. Each pair is reported once, as a two-element call to the visitor's `visitData` for a vector of data entries.
