# qq-typed-binary-schema - eval results

No agent batch yet.

## Local validation
| date | where | mode | user | testcases | failures |
|---|---|---|---|---|---|
| 2026-10-13 | clean room, base + test.patch | base | 1000 | 280 | 0 |
| 2026-10-13 | clean room, base + test.patch | new | 1000 | 11 | 11 (all F2P) |
| 2026-10-13 | clean room, + solution.patch | base | 1000 / 0 / 4242 | 280 | 0 |
| 2026-10-13 | clean room, + solution.patch | new | 1000 / 0 / 4242 | 11 | 0 |

Hook: 354 human-effective, 441 raw, 3 files. Flakiness 3x: not run (FINISH).

## Batch 1 (2026-10-15): Nova 2/2 PASS -> too easy (gate needs Nova 0/8)
Meta = the round-4 humanized text (Task Prompt Quality passed). test.patch = the round-3 version (no all-null "w").

| run | agent | verdict | new tests | baseline | steps | seq length | files | eff LOC | approach |
|---|---|---|---|---|---|---|---|---|---|
| Nova_Nova_1 | Nova | PASS_LEGITIMATE | 11/11 | 289/289 | 170 | 210,034 | 6 (avro, parquet, util/schema.go + 3 own test files) | 1134 | util/schema.go inference engine, OCF record/union schemas + unwrapping, recursive arrow builders/readers |
| Nova_Nova_2 | Nova | PASS_LEGITIMATE | 11/11 | 298/298 | 180 | 235,903 | 6 (same set) | 1161 | same architecture |

Nova average sequence length 222,969 < 256k: also misses the sequence gate.

Differential probe (worktrees/qq-tools, olympus-base-go container, root):
- 46 stated cells x 2 formats (list null elements, list of records with missing keys, nullable records in lists in nullable records, int/float merges in nested fields / list elements / across rows, 2.0 in lists, mixed in lists and nested fields, same key at two depths, sibling records sharing inner names, list of lists, nullable inner lists, empty + non-empty lists, all-empty / all-null values, nested nullable + missing keys, one-key nullable records incl. keys named like avro types, record vs list mix, big ints in mixed JSON text, min/max int64, deep big ints, deep jq queries, unicode, extreme floats, late field after 9 rows): ref 92/92, Nova2 92/92, Nova1 90/92 (fails nullable list + list of nullable lists in avro: leaves the {"array": [...]} union wrapper).
- Cross-codec (yaml, toml, hcl, cbor, msgpack decoded rows into both writers): every decoder already normalizes to int/float64; 10/10 for all three.
- Reserved-name keys inside the cap (string/record/long/null as record keys, a key reused at depth): 10/10 for all three.
- Keys outside the cap ("first-name", "1x", "a b"/"a_b"/"a-b", "k.v", "", "cafe" with accent): avro fails for ref AND both Nova, parquet passes for all.
Diagnosis: stated surface exhausted (L83). No tests-only lever separates Nova2 from the reference. Only the Nova1 nullable-list cell is new discrimination.

## Harden round 1 validation (2026-10-15, any-key rule)
| where | mode | user | testcases | failures |
|---|---|---|---|---|
| clean room, base + test.patch | new | 1000 | 16 | 16 |
| clean room, base + test.patch | base | 1000 | 280 | 0 |
| clean room, + solution.patch | new | 1000 | 16 | 0 |
| clean room, + solution.patch | base | 1000 | 280 | 0 |
| staged clone, + solution | new x3 | root | 16 | 0, 0, 0 |
Replay of batch 1 on this suite: Nova1 5 fails, Nova2 4 fails (the 4 any-key tests). Description changed, so batch 1 is void for gating.
