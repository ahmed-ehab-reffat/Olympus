# eval-results — openglobus-entitycollections-tree-maintenance

No platform batch yet (Step 4b core slice).

## Local clean-room runs (Docker, uid 1000, --network none, image `factory-openglobus-entitycollections-tree-maintenance`)

| run | tree | mode | tests | failures | exit |
|---|---|---|---|---|---|
| b_base_1..3 | base + test.patch | base | 227 | 0 | 0 |
| b_new_1..3 | base + test.patch | new | 28 | 28 | 1 |
| s_base_1..3 | + solution.patch | base | 227 | 0 | 0 |
| s_new_1..3 | + solution.patch | new | 28 | 0 | 0 |

All four groups byte-identical across their three runs (md5 over the extracted `name=` and
`<failure message=` sets).

## Trap-proof (mutants of the finished reference against the 28 new tests)

| mutant | kills |
|---|---|
| M1 `_nodePtr` not assigned on leaf residency | 24 |
| M2 split does not recurse | 3 |
| M3 redistribution uses the parent's mercator extent | 2 (`north_tree_splits_past_capacity`, `equi_east_splits_past_capacity`) |
| M4 split node keeps its entity collection | 8 |
| M5 collapsed node keeps its children | 5 |
| M6 same-position guard removed | 1 (un-mutated reference hangs) |
| M7 removal decrements only the leaf | 8 |

## Per-agent table (empty until the first batch)

| batch | agent | verdict | msgs | files | LOC | failed tests | approach note |
|---|---|---|---|---|---|---|---|
