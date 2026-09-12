# DESIGN — `LineMerge` for `georust/geo` (Rust, complex tier)

Status: **design only.** No tests, solution, or Dockerfile yet (prompt: "stop after
the corrected design"). All uniqueness / similarity / license / activity gates
below are **resolved**, not pending. Supersedes the earlier Python `laspy` draft
(kept at `../laspy-merge-las/` as a rejected alternate — wrong language, too small).

Calibration for this task (per user): **complex feature, wide file spread, ≥400
effective LOC, Rust/Go.** Two independent discriminators.

---

## 1. OLYMPUS_ROOT and workspace boundary

- **OLYMPUS_ROOT** = `/Users/andrewemad/Documents/Olympus/` (contains `instructions/`,
  `templates/`, `problems/`, `.claude/`).
- Only outside-root inspection: the public target repo `georust/geo`, cloned to the
  session scratchpad. No sibling/home-archive Olympus trees were searched.
- Recorded caveats (unchanged): `instructions/` is my faithful distillation of the
  platform doc; `templates/` holds placeholders only. Neither blocks DESIGN.md.

## 2. Hard-rule ledger (from `instructions/`) — deltas from prior draft

Same ledger as the laspy design (HR1–HR15). Language-specific bindings for this task:

| Rule ID | Exact hard rule | This task |
|---|---|---|
| HR1 | ≥500★, commit ≤12mo, permissive license, allowed language | geo: 1,895★, pushed 2026-07-12, **MIT/Apache-2.0 dual**, **Rust** ✓ |
| HR2 | No PR solves it | Only **open issue #1437** (feature request); no implementing PR ✓ (§6) |
| HR3 | Not maintainer-declined | Open feature request → welcomed, not declined ✓ |
| HR11 | `test.sh` base/new modes, JUnit XML, no fail-fast | Go/Rust: `cargo test` → JUnit via `cargo2junit` or `--format junit`; Phase 6 |
| HR14 | `FROM olympus-base-rust`, `WORKDIR /app`, deps at build, `CMD ["/bin/bash"]` | Phase 6 |

Ambiguity recorded: no LOC floor in `instructions/`; the **user's ≥400 effective
LOC** governs (§13).

## 3. Template / output map

| Artifact | Template? | Output path |
|---|---|---|
| `meta.md` | placeholder only | `problems/geo-line-merge/meta.md` |
| test patch (`test.sh`+tests) | none | `problems/geo-line-merge/test.patch` |
| solution patch | none | `problems/geo-line-merge/solution.patch` |
| Dockerfile | skeleton from `instructions/06` | `problems/geo-line-merge/Dockerfile` |

## 4. Repository shortlist (facts verified via GitHub API, Jul 2026)

| Repo | Domain | Lang | Stars | License | Last push | Saturation | Decision |
|---|---|---|---|---|---|---|---|
| **georust/geo** | Geospatial primitives & algorithms | **Rust** | 1,895 | MIT/Apache (permissive) | 2026-07-12 | Med (algorithms, not "architecture-memorized") | **SELECTED** |
| koto-lang/koto | Embeddable scripting language | Rust | 881 | MIT | 2026-07-05 | Low | Alt — very complete; only open feature is #277 async (too large/unstable) |
| expr-lang/expr | Expression language | Go | 7,948 | MIT | 2026-07-07 | **High** (agents know it cold) | Reject — saturation |
| google/cel-go | CEL expression language | Go | 3,033 | Apache-2.0 | 2026-07-16 | Med-high | Reject — spec-complete; gap-finding costly |
| keats/tera | Jinja-like templates | Rust | 4,261 | MIT | 2026-07-07 | Med | Reject — too close to bank's MiniJinja example |
| paulmach/orb | 2D GIS geometry/encodings | Go | 1,122 | MIT | 2026-03-30 | Low | Reject — explicit 2D-only limits a coherent large feature |
| construct/construct | Binary parsing | Python | 1,010 | MIT | 2025-04-22 | Low | Reject — **fails HR1 activity** + wrong language |

Why geo wins for *this* calibration: a graph algorithm over the geometry hierarchy
is genuinely complex, is tested purely through a public trait against a
deterministic oracle, threads a wide set of files (per-type impls + graph engine +
registration, mirroring geo's own `contains/`, `bool_ops/` module layout), and the
target feature has an **open, welcomed** feature request with no PR.

## 5. Architecture analysis — geo @ `771d1bf8d4cd8ad9b27b589b8a485d0aac2e5cba`

One paragraph: `geo` is a large Rust geospatial crate. Concrete geometry types live
in the `geo-types` sub-crate; `Geometry<T>` is a 10-variant enum
(`Point, Line, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon,
GeometryCollection, Rect, Triangle`). Algorithms are exposed as **traits**, each
implemented per geometry type and re-exported through the crate prelude; many
non-trivial algorithms are organized as module *directories* with one file per
geometry type plus a shared engine (e.g. `algorithm/contains/`, `algorithm/bool_ops/`,
`algorithm/relate/`).

- **≥5 subsystems:** `geo-types` (geometry model + `CoordsIter`/`LinesIter`),
  `algorithm/` (traits), the prelude (`geo/src/lib.rs`), the trait-dispatch pattern,
  the numeric-trait layer (`GeoNum`/`CoordNum`).
- **High-entanglement areas:** (a) per-type trait dispatch + `Geometry`/
  `GeometryCollection` recursion; (b) exact-coordinate endpoint equality &
  orientation/reversal of `LineString`s; (c) prelude re-export surface.
- **Test framework:** `cargo test`, `#[cfg(test)] mod test` in-file + `geo/tests/`.
  Style refs: `algorithm/line_interpolate_point.rs`, `algorithm/frechet_distance.rs`.
- **≥7 files a feature can touch:** new module `algorithm/line_merge/{mod.rs,
  graph.rs, line_string.rs, multi_line_string.rs, geometry.rs, geometry_collection.rs}`,
  plus `algorithm/mod.rs` and `geo/src/lib.rs` registration.
- **Public test surface:** the new `LineMerge` trait's `line_merge()` returning
  `MultiLineString`, compared against oracle geometries built from `geo-types`.

## 6. Prior-art searches (recorded)

- **Code + tree:** grep confirms **no** `LineMerge`/`line_merge`/`linemerge`,
  `Polygonize`, `Snap`, `MinimumBoundingCircle`, or noding module exists. `Densify`
  exists; `LineStringSegmentize` exists.
- **Issues/PRs (GitHub search):**
  - **#1437 OPEN issue** — "[Feature Request] `MultiLineString::line_merge`" — asks
    for a pure-Rust line merge (no GEOS). → target problem; proves alignment + not
    declined; usable as the optional issue URL.
  - **No PR** implements line merge (open PRs #1529 linear-referencing `Substring`,
    others unrelated).
  - `LineStringSegmentize` merged in **#1055/#1107** → the *segmentize* idea is taken
    and is **rejected** here (would duplicate).
- **Discussions/changelog/default branch:** no line-merge implementation landed.
- **`problems/` similarity audit:** only the rejected laspy alt; different repo,
  language, domain, and feature class → no duplicate.

**All uniqueness gates resolved. None pending.**

## 7. Task-candidate matrix (geo)

| # | Candidate | Missing? | Complexity / files | Discriminators | Decision |
|---|---|---|---|---|---|
| 1 | `Segmentize` (euclidean max-len) | **No** (#1055 merged) | wide/low | 2 | Reject — taken |
| 2 | `MinimumBoundingCircle` (Welzl) | Yes | high / **narrow** (coords-only) | ~1 (engine only) | Reject — narrow files, 1 discriminator |
| 3 | `Polygonize` | Yes | high / narrow | ~1 | Reject — 1 discriminator, ambiguous dangles |
| 4 | `Snap` (vertex snapping) | Yes | med / wide | 2 | Alt — good file spread but snapping semantics risk ambiguity |
| 5 | **`LineMerge`** (JTS LineMerger) | **Yes (#1437 open)** | **high / wide** | **2** | **SELECT** |
| 6 | 3D/Z coordinates | n/a | huge | — | Reject — geo is deliberately 2D (R4 misalignment) |

## 8. Selected task + shallow-implementation hypothesis

**Task:** add a `LineMerge` trait whose `line_merge()` stitches the constituent
line segments of a geometry into the fewest possible maximal `LineString`s,
returning a `MultiLineString` — the standard JTS `LineMerger` operation, requested
in #1437.

Who needs it & why: GIS users reconstruct continuous linework (road/river networks,
contours, dissolved boundaries) from unordered, arbitrarily-directed line fragments;
geo currently forces a GEOS dependency for this. Why geo is the right layer: it owns
the geometry model and the algorithm-trait surface, and maintainers explicitly want
a pure-Rust version (#1437).

**Shallow implementation an agent will attempt (and why it fails):** iterate the
segments and concatenate any pair whose `end`/`start` coordinates touch
(head-to-tail), on a flat `MultiLineString`. This fails three ways: (a) it misses
**reversed** connections (`A→B` meeting `C→B`); (b) it **over-merges at branch
nodes** where 3+ segments meet (which must instead terminate merged lines); and (c)
it ignores lines nested inside a `GeometryCollection`. A correct solution needs a
node-degree graph and recursive extraction.

## 9. Adopted discriminator matrix (prompt bank only — 2 independent)

| Discriminator (bank) | Shallow shortcut it defeats | Subsystems crossed | meta clauses | Named tests |
|---|---|---|---|---|
| **Engine-authoritative evaluation** (Excelize) | Head-to-tail-only or greedy pairwise concatenation instead of a node-degree graph | endpoint-node graph · `LineString` orientation/reversal · degree logic | M04, M05, M06, M07 | `y_junction_stays_three_lines`, `reversed_segments_merge`, `closed_ring_is_closed`, `each_segment_used_once` |
| **Pipeline re-entry** (fontTools) | Reading only a flat `MultiLineString`, not recursing into nested containers | geometry-hierarchy extraction · `Geometry`/`GeometryCollection` recursion | M02, M03 | `lines_nested_in_geometry_collection_are_merged`, `non_line_members_ignored` |

Independence: discriminator 1 is the graph correctness on a *given* flat set of
segments (triggers even with a single `MultiLineString`); discriminator 2 is
building that set from a *nested* structure (triggers even when the merge graph is a
trivial single chain). A solution can pass one and fail the other.

## 10. Draft `meta.md`

> **Add a `LineMerge` operation that stitches line segments into maximal lines.**
>
> Add a `LineMerge` trait with a method `line_merge` that returns a
> `MultiLineString`. It collects every `Line` and `LineString` contained in the
> geometry — including those nested inside a `MultiLineString`, a `GeometryCollection`,
> or a `Geometry`, recursing through nested collections — and joins them into the
> fewest possible continuous `LineString`s. Non-linear components (points, polygons)
> contribute nothing. Implement it at least for `LineString`, `Line`,
> `MultiLineString`, `GeometryCollection`, and `Geometry`, on `f64` geometries.
>
> Two segment ends belong to the same node when their coordinates are exactly equal.
> Where exactly two segment ends meet at a node, those segments are joined into one
> line, reversing a segment's vertex order when needed so the joined line is
> continuous; the shared coordinate appears once at the join. Where one, or three or
> more, segment ends meet at a node, that node terminates a merged line. A chain that
> returns to its start through only two-way nodes forms a closed `LineString`.
>
> Every input segment appears exactly once across the result, and no interior vertex
> is moved or dropped. Merging an empty set of lines yields an empty
> `MultiLineString`; a set that is already one continuous line yields that line
> unchanged in shape.
>
> The order of lines in the returned `MultiLineString`, and the start-to-end
> direction of each returned line, are unspecified.

(No private names, no algorithm prescription beyond the public node/degree rules,
no output ordering pinned — direction/order explicitly declared free, per T7.)

## 11. Meta-to-test ledger (two-way, zero unmapped)

Tests compare results as a **multiset of lines**, each normalized to a canonical
direction (the lexicographically smaller of its coordinate sequence vs. its
reverse). This asserts *which segments merged* without pinning order/direction (M-last).

| Clause | Atomic requirement | Test | Public assertion |
|---|---|---|---|
| M01 | `line_merge()` exists on the listed types, returns `MultiLineString<f64>` | `trait_available_on_listed_types` | compiles + returns `MultiLineString` |
| M02 | Recurses into `MultiLineString`/`GeometryCollection`/`Geometry` (nested) | `lines_nested_in_geometry_collection_are_merged` | nested lines across containers merge into one |
| M03 | Non-linear members contribute nothing | `non_line_members_ignored` | polygon/point in a collection ⇒ absent from result |
| M04 | Degree-2 node ⇒ join (with reversal as needed) | `reversed_segments_merge` | `A→B`,`C→B` ⇒ one line `A→B→C` (normalized) |
| M05 | Degree 1 or ≥3 node ⇒ terminates lines | `y_junction_stays_three_lines` | 3 segments at a node ⇒ 3 separate lines |
| M06 | Two-way closed chain ⇒ closed `LineString` | `closed_ring_is_closed` | result line `is_closed()` |
| M07 | Each input segment used exactly once; interior vertices preserved | `each_segment_used_once` | total coord/segment accounting matches input |
| M08 | Empty ⇒ empty; single continuous line ⇒ unchanged shape | `empty_and_identity_cases` | `0` lines; single line equal (normalized) |
| M09 | Order and per-line direction unspecified | (assertion style) | tests normalize; never assert order/direction |

`unmapped_meta_clauses = 0`, `unstated_test_requirements = 0`.

## 12. Oracle & deterministic test plan

- **Oracle:** JTS `LineMerger` semantics (the de-facto standard the issue cites).
  Expected geometries are hand-constructed in each test from `geo-types`; recorded
  in the test file, not computed by the solution.
- **Determinism:** exact-f64 endpoint equality; integer-valued coordinates in
  fixtures ⇒ no float tolerance; multiset+canonical-direction comparison removes all
  ordering/direction nondeterminism. No time/random/IO/network (HR7/HR9). The graph
  must not depend on `HashMap` iteration order for its *result* — tests enforce this
  by checking content, not order.
- **Audits:**
  1. *Clause-omission:* drop recursion ⇒ M02 fails; treat every shared endpoint as a
     join ⇒ M05 fails; head-to-tail only ⇒ M04 fails; reuse/skip segments ⇒ M07 fails.
  2. *Passing-but-wrong (≥3):* (a) head-to-tail concatenation → fails M04; (b) greedy
     pairwise merge at all shared endpoints → fails M05; (c) flat-`MultiLineString`
     only → fails M02. Each has a dedicated failing test.
  3. *Verifier:* `new` runs only `line_merge` tests; `base` runs the existing geo
     suite for the touched area (`cargo test -p geo algorithm::`), disjoint from `new`.

## 13. Footprint & solve-rate rationale

- **Effective LOC ≈ 400–520:** `line_merge/graph.rs` node-graph + degree logic +
  chain following with reversal/ring handling (~200–300); per-type impls
  `line_string.rs`/`multi_line_string.rs`/`geometry.rs`/`geometry_collection.rs` +
  extraction (~120–180); `mod.rs` trait def (~30); `algorithm/mod.rs` + `lib.rs`
  prelude registration (~6). Meets ≥400.
- **Files touched (wide, following geo's own module-dir idiom):** ~6 new files under
  `algorithm/line_merge/` + 2 edited (`algorithm/mod.rs`, `geo/src/lib.rs`).
- **Predicted 30–40% solve:** the head-to-tail shortcut is the obvious first attempt
  and passes only the trivial single-chain case; correctly handling reversed
  connections, branch-node termination, rings, *and* recursive extraction requires
  the real graph model — two independent axes of failure, neither obscure (both fully
  stated in `meta.md`). Complex enough to sink shallow attempts, fair enough that a
  correct graph-based solution passes cleanly.

## 14. Fairness & ambiguity audit

- Full meta↔test symmetry (§11). Node/degree/reversal/ring rules all explicit.
- Ordering and direction **explicitly declared unspecified** and never asserted (T7).
- Exact-equality node rule stated ⇒ no hidden tolerance contract.
- Not prescriptive: states public merge *rules and outcomes*, not the graph data
  structure or function names (P6).
- Deterministic, offline (HR7/HR9). Non-linear-input behavior stated (M03) so agents
  aren't tested on undiscoverable behavior (T5).

## 15. Final hard-rule compliance check (vs §2 ledger)

HR1 ✅ (1,895★, 2026-07-12, MIT/Apache, Rust) · HR2 ✅ (no PR; open issue only) ·
HR3 ✅ (welcomed feature) · HR4 ✅ (fits geo's algorithm-trait model) · HR5 ✅ (§14) ·
HR6 ⏳ design-proven, executes Phase 6 · HR7/HR9 ✅ (in-memory, exact-int fixtures) ·
HR8 ✅ (§12 audits) · HR10 ✅ (order/direction free) · HR11–HR14 ⏳ Phase 6 ·
HR15 ⏳ post-design agent run.

No uniqueness, similarity, license, activity, or tier gate remains pending.

---
### Base target
- Repo: `https://github.com/georust/geo`
- Commit: `771d1bf8d4cd8ad9b27b589b8a485d0aac2e5cba` (2026-07-12)
- Optional issue URL: `https://github.com/georust/geo/issues/1437`
