---
Repository: https://github.com/surrealdb/surrealkv
Language: Rust
Issue: Implement read and compaction semantics for the reserved Merge key kind
Commit: 490052928e4a12e3cf6650b70c2b2f448f63adf2
Title: Add a read-modify-write merge operator
---

# Add `merge` for read-modify-write operands

Add a `merge` method on `Transaction`, taking a key and an operand, that records a read-modify-write operand rather than a full value. Each operand is 9 bytes: a one-byte operation code (0 = add, 1 = min, 2 = max) followed by an 8-byte little-endian u64. A read of a key carrying merge operands returns, as an 8-byte little-endian u64, the operands folded onto a base value.

The base is the most recent regular put for the key, read as an 8-byte little-endian u64; a key with no prior put, or whose most recent non-merge version is a delete, folds onto 0. The fold applies the operands in commit order, oldest first: add is a saturating u64 addition, while min and max take the minimum or maximum of the running accumulator and the operand. A later regular put replaces the base and discards earlier operands, and a key never written with `merge` is returned unchanged.

The folded value is produced on every read path: point `get`, the timestamped `get_at`, range scans in both forward and reverse directions, and the version `history`. In `history` a maximal run of consecutive merge operands on a key collapses to a single entry carrying that run's fully folded value, so the intermediate accumulator after each individual operand is never surfaced, while a regular put stays its own entry. For a put of 5 followed by a merge add of 10 and then a merge min of 8, `history` reports the put value 5 and one folded merge entry 8, never the intermediate 15. Reads inside the writing transaction fold that transaction's own uncommitted operands, including in `history`. A reader only folds operands at or below its snapshot, so an older snapshot observes the value as of its own sequence and not operands committed after it. `get_at` selects the as-of value by user timestamp: the base is the regular put with the greatest timestamp at or below the query, and it folds only the operands whose timestamp is at or below the query.

Merge operands persist across memtable flush and compaction, and compaction preserves the order of differing operations. When versioning is enabled, compaction keeps the base and the per-operation operand groups as distinct versions rather than collapsing the run to a single value. Superseded merge operands are retained rather than reclaimed, so `get_at` still reconstructs any intermediate as-of value after compaction.
