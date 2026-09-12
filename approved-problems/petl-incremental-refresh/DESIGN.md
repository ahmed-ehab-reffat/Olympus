# DESIGN.md — petl-incremental-refresh

Repo: `petl-developers/petl` (MIT, 1313 stars, last commit 2026-08-05)
Base: `aa03e269637d6b5abf21d71180cb37f687a2c7cb`

## 1. Title

Add incremental refresh to petl table pipelines

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`PLAYBOOK § Pattern 12`) — a new subsystem whose whole
  difficulty is a subtle correctness contract (delta propagation that must agree row for row and
  order for order with from-scratch evaluation), not breadth of API.
- Pass target: <= 40% (sprint cap); design aims at the corpus mode, 1/10.
- Best agent: mixed; Orion-style commit-and-implement is the likely single passer.
- Dominant verdict predicted: MISSED_REQUIREMENT (incrementality rules) and REGRESSION
  (petl's own AST meta-test on shadowed attribute names).

## 3. Public API surface

- `petl.feed(header, rows=())` -> `Feed`, an append-only source table.
  - `Feed.append(row)`, `Feed.extend(rows)` — add rows.
  - `Feed.rows_from(index)` — the data rows from position `index` onwards.
  - `Feed.rows_read` — how many data rows the feed has handed out, counting both iteration
    and `rows_from`.
- `petl.incremental(table)` and `Table.incremental()` -> `IncrementalPipeline`, itself a table.
  - `IncrementalPipeline.refresh()` -> `Refresh`.
  - `IncrementalPipeline.plan()` -> the plan text.
- `Refresh.added` — rows the output gained, in output order.
- `Refresh.removed` — rows the output lost, in the previous output's order.
- `Refresh.emitted` — mapping node id -> rows that node gained plus rows it lost.
- `Refresh.to_dict()` — `added`, `removed`, `emitted` as a plain mapping.
- `petl.IncrementalError` — raised for a table class the layer does not support.

## 4. Canonical output form

- Output rows are tuples; the pipeline yields the header first, exactly like any petl table.
- The refreshed output equals `list(expression)` re-evaluated from scratch — row for row, in the
  same order. Every per-node semantic (cat's field unification, sort's comparator, distinct's
  first-occurrence-in-sorted-order, join's key blocks, aggregate's sorted keys) therefore comes
  from petl itself and is never restated.
- `added` / `removed` are multiset differences (duplicates counted), in output order.
- `emitted` counts a node's own output delta: additions plus removals, per node, per refresh.
- Node ids are `kind#n`, numbered from 1 in the order nodes are first reached by a post-order
  left-to-right walk. A table object reached twice is one node.
- `plan()` returns one line per node in that order: `"<id>: <child ids, comma separated>"`,
  and `"<id>: -"` when a node has no children.

## 5. Blind-spot pre-empts

- Result ordering: "row for row and in the same order" (pre-empts append-at-the-end).
- Dedup/multiset: "as multisets, duplicates counted" (pre-empts set semantics).
- Iteration termination / staleness: "rows appended to a feed become visible only after
  `refresh()`" (pre-empts recompute-on-iterate).
- Parallel/shared structure: "a table object reached twice is one node, visited once, and its
  rows are read once" (pre-empts double counting in a diamond).
- Falsy/edge: "a refresh that finds no new rows returns empty `added` and `removed`".

Codebase-inferable requirements: 1 (the view classes each supported petl function returns).

## 6. Description draft

See `meta.md`. Body shape: five short prose paragraphs — what the layer is, the feed, the
refresh contract, the incrementality rules, the plan/ids. No headers, no lists.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
| --- | --- | --- | --- | --- | --- |
| NEW | petl/incremental/__init__.py | — | +20 | 12 | exports |
| NEW | petl/incremental/feed.py | — | +70 | 55 | append-only source + read accounting |
| NEW | petl/incremental/plan.py | — | +150 | 120 | view introspection, node ids, plan text |
| NEW | petl/incremental/operators.py | — | +420 | 340 | ten delta operators + shared state |
| NEW | petl/incremental/pipeline.py | — | +170 | 135 | build, refresh loop, Refresh record |
| MODIFY | petl/errors.py | 26 | +8 | 6 | IncrementalError |
| MODIFY | petl/__init__.py | 15 | +3 | 3 | re-export |

TOTAL: ~840 raw / ~670 meaningful across 2 modified + 5 new files. Clears the 450 design floor
with margin; gate on `effective_loc_check.py`.

## 8. Solution outline

Helpers, one per stated behaviour:

- `build_plan(table)` -> `(nodes, root)` — post-order walk, identity map, id assignment.
- `node_kind(view)` -> str — class-to-kind registry; unknown class raises `IncrementalError`.
- `Operator.build(children_output)` -> initial output list.
- `Operator.apply(child_deltas)` -> `Delta(added, removed)` — the kernel; every operator only
  touches the part of its state the incoming delta reaches.
- `multiset_delta(old, new)` -> `(added, removed)` — bag difference in output order, used by
  the operators that recompute a bounded region (cat, sort, head, join block, aggregate group).
- `RowSelectOperator` / `AddFieldOperator` — apply the user callable to new rows only.
- `AggregateOperator` — group state keyed by the aggregation key; only touched keys re-run the
  aggregation functions.
- `JoinOperator` — per-key blocks on both sides; a key whose block changes is regenerated;
  left-outer placeholder rows are retracted when the key first matches.
- `HeadOperator` — window of the first n rows of its child; a child insertion inside the window
  pushes the tail row out (a removal).
- `SortOperator` — ordered output maintained with `bisect` over petl's own comparator.
- `DistinctOperator` — key counts; a repeat key emits nothing.

No fixpoint loop: the plan is a DAG and the refresh is a single topological sweep, each node
visited once.

## 9. Test file outline

Path: `petl/test/test_incremental_<hash>.py` (petl keeps tests inside the package).

Block 1 — imports.
Block 2 — builders: `_feed()`, `_pipeline()`, `_recompute(expression)`.
Block 3 — assertion helpers: `_eq_recompute(pipeline, expression)`, `_expect_error(fn, name)`.
Block 4 — buckets:
- plan and node ids (ids, order, shared node, plan text, unsupported class) — 10
- build and staleness (materialized output, iteration before refresh, empty refresh) — 6
- row-wise operators (cut, addfield, select; callable-call accounting) — 10
- order-preserving operators (cat of two feeds, sort, head window with removals) — 12
- set-shaped operators (distinct with and without key, duplicate rows) — 8
- join (inner, left outer, retraction of the placeholder row, both sides growing) — 10
- aggregate (touched groups only, new group inserted mid-output, multi aggregation) — 9
- deltas and reporting (added/removed multisets, emitted per node, to_dict) — 8
- differential fuzz (seeded, compares against from-scratch evaluation) — 3

Coverage axes: every described behaviour, every public name, every operator branch, empty
input, single row, duplicate rows, no-op refresh, shared node, unsupported class.

## 10. Forced signatures

- `feed(header, rows=())` returns a `Table` subclass, so no instance attribute may be named
  after a `Table` API method (petl's own `test_no_shadowed_api_names` scans the source).
  `stats`, `header`, `cache`, `data`, `index`, `list`, `set` are all API names; the reference
  uses `_header`, `_rows`, `rows_read`.
- `refresh()` returns an object, not a tuple, so the fields are named in the description.
- `emitted` is a plain dict keyed by node id string.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Test |
| --- | --- | --- | --- | --- |
| 1 | Bag vs set deltas | duplicates are rare in the obvious example | "as multisets, duplicates counted" | `duplicate_rows_*` |
| 2 | Order of insertion (cat first source grows, sort, aggregate new key) | naive engines append deltas | "row for row and in the same order" | `cat_first_source_*`, `sort_insert_*` |
| 3 | Removals (head window, left-outer placeholder retracted) | delta engines propagate additions only | "`removed`, the rows the output lost" | `head_window_*`, `leftjoin_placeholder_*` |
| 4 | Callables re-applied | recompute-from-cache is the easy implementation | "never applied twice to the same row or group" | `select_calls_*`, `aggregate_calls_*` |
| 5 | Diamond double counting | a feed reached twice is read twice | "a table object reached twice is one node" | `shared_feed_*` |
| 6 | Attribute shadowing | `self.header` / `self.stats` look natural | none (repo convention, base test) | petl `test_no_shadowed_api_names` |

Traps 1, 2 and 3 all funnel through the same delta kernel, so a local fix to one regresses
another; trap 4 forbids the shortcut that would defuse 1-3.

## 12. Tier + category

- Tier: Olympus. Category: feature-request (net-new public API).

## 13. Predicted pass rate

10-25%. Levers stacked: one interdependent kernel driving ten surfaces; a from-scratch
differential oracle fuzzed to zero mismatches; three interdependent, misdirecting traps; an
"obvious code is wrong" edge (bag vs set, append vs insert); a repo that has no incremental
layer and no public sibling that adds one.

## 14. Quality gate

- [x] Repo understanding 5/5 (below)
- [x] Existing PR / issue check: `gh search issues --repo petl-developers/petl` for incremental,
      delta, change data capture, materialize, refresh, streaming — no hit touches this feature
- [x] Approved corpus opened side by side: `sqlfluff-fix-transaction` (report-record family over
      a linter loop) and `pvlib-loss-attribution` (accounting layer over an existing pipeline)
- [x] Corpus hardness recipe: kernel + oracle + 3 interdependent misdirecting traps + pinned API
- [x] Title verb-led, names the subsystem
- [x] Canonical form spelled out (order, multiset, ids, plan text)
- [x] <= 1 codebase-inferable requirement
- [x] File footprint sketched against real files; LOC over floor
- [x] Helpers 1:1 with described behaviour
- [x] Test outline 4-block, scenario names
- [x] Traps each have a pre-empt and a catching test
- [x] Not pattern-followable: petl has no delta machinery anywhere

### Phase 1 — repo understanding

petl is a lazy table library: every transform returns a `Table` subclass that stores its source
and re-derives rows on each iteration. Five subsystems: `petl/util` (base `Table`, iteration
helpers, statistics), `petl/transform` (the view classes), `petl/io` (readers and writers),
`petl/comparison` (`Comparable`, the total order used by sorts), `petl/config`. High-entanglement
zones: `petl/util/base.py` (every view inherits from it and every public function is attached
to it), `petl/transform/sorts.py` (sorting underpins join, distinct and aggregate), and the
fluent binding at the bottom of each transform module. Tests live inside the package
(`petl/test/transform/test_selects.py` is the formatting template) and run under pytest.

### Phase 2 — searches run

```
gh pr list -R petl-developers/petl --state all --search "incremental|delta|refresh|materialize"
gh issue list -R petl-developers/petl --state all --search "incremental|delta|streaming"
gh api repos/petl-developers/petl/branches
```
No PR, branch or issue proposes an incremental or delta layer.

### Why this is not a duplicate

Closest siblings: `ironcalc-incremental-recalc` (a stub, never built) recomputes a spreadsheet
dependency graph after a cell edit — a dirty-marking problem over a graph of scalar cells;
`rejected/differential-dataflow-topk-total` adds one operator to an engine that already does
delta propagation. This problem builds the delta machinery itself over a bag-of-rows model where
output ORDER is part of the contract, which neither sibling has: cell recalc has no row order and
differential dataflow has no order at all.

Predicted iteration cycles: 2
