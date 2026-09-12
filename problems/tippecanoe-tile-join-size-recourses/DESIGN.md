# DESIGN.md — tippecanoe-tile-join-size-recourses

Repo: felt/tippecanoe · base `4f2621186acfec33b63ddf636f665623c0fef2dd` · C++17 · BSD-2 · ★1600 · quota 0/6
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-12.md`

---

## 1. Title

**Add tile size recourses to the tile-join merger**

Verb `Add` -> category `feature-request`. Names the subsystem (`tile-join`). 7 words.

---

## 2. Shape classification

- **Shape:** O-Composite-add (`SHAPES.md § Pattern 12`) — a new capability spanning the merge worker,
  the vector-tile encoder's constant pools, and the tileset-metadata writer.
- **Capability shape:** S-G (finite resource / graceful degradation) fused with S-F (analysis and
  accounting layer) — `CAPABILITY-SHAPES.md`. The reduction is the vehicle; keeping the tileset's own
  books honest is the interdependent half.
- **Pass rate target:** 15-25% (sprint ceiling <=40%, 0% = reject).
- **Best agent:** Orion (decisive, will commit to an architecture); Nova likely thrashes on the
  pool-compaction/remap step.
- **Dominant verdict:** MISSED_REQUIREMENT (the accounting surfaces), then REGRESSION (tag remap
  garbles attributes).
- **Solver/our LOC ratio:** expect ~1.0-1.3x (C++, concentrated).

---

## 3. Public API surface

The public surface is the `tile-join` command line and the tileset it writes. Every name below is
asserted by tests and is named in meta.md.

- `-M <bytes>` / `--maximum-tile-bytes=<bytes>` — maximum size in bytes of a compressed tile.
  Default 500000, matching the current hard-coded limit and `tippecanoe`'s own option.
- `--drop-smallest-as-needed` — when a tile exceeds the maximum, shed features until it fits
  instead of skipping the tile.
- `-pk` / `--no-tile-size-limit` — unchanged; still disables the limit outright.
- Output tileset `metadata` row `strategies` — a JSON array indexed by zoom; the keys this feature
  writes are `dropped_as_needed` (count) and `tile_size_desired` (bytes).
- Output tileset `metadata` row `json` -> `tilestats` — per-layer `count`, `geometry`, and attribute
  value lists; per-layer `minzoom` / `maxzoom`.
- Output tileset `metadata` rows `minzoom`, `maxzoom`, `bounds`.

No new C++ public API is named in meta.md. The compaction helper added to `mvt_layer` is internal;
tests reach it only through the tiles `tile-join` writes.

---

## 4. Canonical output form

| Rule | Value |
|---|---|
| Drop order | increasing extent |
| Extent, polygon | area of the feature's bounding box in tile coordinates |
| Extent, line | width + height of the feature's bounding box in tile coordinates |
| Extent, point | zero |
| Tie-break | reverse of merge order (the later-merged feature is dropped first) |
| Scope of ranking | the whole tile, across every layer, not per layer |
| Terminal case | a tile that still does not fit with one feature left is skipped, as today |
| `-pk` | disables the limit entirely; no reduction, no skip |
| At-limit case | a tile whose size equals the maximum is NOT reduced (strictly greater triggers) |
| Under-limit tile | written exactly as today, byte for byte |
| Measured quantity | the compressed tile, or the tile itself under `--no-tile-compression` |
| Empty layer | a layer with no remaining features is not written |
| Empty tile | a tile with no remaining layers is not written |
| Attribute pools | a layer carries no key and no value unused by its remaining features |
| Attribute preservation | a surviving feature keeps exactly the attributes it had |
| `strategies` | tile-join's own drops are ADDED to the per-zoom counts inherited from inputs |
| `strategies`, no reduction | a join that reduces nothing leaves `strategies` exactly as inherited — no new key, no new entry |
| `tile_size_desired` | the largest size a tile WANTED to be at that zoom before being reduced (matching `tile.cpp:2892`, which records it only inside the too-big branch) |
| tilestats / zoom range / bounds | count only features that reached the output, including when a tile was SKIPPED |

---

## 5. Blind-spot pre-empts (`DESCRIPTION.md` sentence bank)

| Blind spot | Sentence in §6 |
|---|---|
| Result ordering / tie-break ambiguity | "features of equal extent are shed in reverse of the order they were merged in" |
| Adjacent vs all-positions (per-layer vs whole tile) | "Dropping is across the whole tile, not per layer" |
| Iteration termination | "A tile that still does not fit once only one feature is left is skipped as before" |
| Falsy/boundary on the threshold | "larger than the limit" (strictly greater, not >=) |
| Unstated inverse | "whether they were dropped to make a tile fit or lost because the tile was skipped" |

Codebase-inferable requirements: **1** (that the default limit is 500000 — it is the current
hard-coded constant; stated anyway).

---

## 6. Description draft (meta.md body)

> Add tile size recourses to `tile-join`.
>
> `tile-join` copies geometries into the new tileset without processing them, so a merged tile that
> comes out larger than the size limit is left out of the tileset altogether. Give it the two
> recourses `tippecanoe` has for the same situation.
>
> `-M` or `--maximum-tile-bytes` sets the limit, in bytes, on the compressed tile, or on the tile
> itself when `--no-tile-compression` is given, and is 500000 by default. A tile that is not over
> the limit is written exactly as it is written today. `--drop-smallest-as-needed` makes a tile that is larger than the limit shed features
> until it fits instead of being skipped. Features are shed in increasing order of extent: a
> polygon's extent is the area of its bounding box in tile coordinates, a line's is the width plus
> the height of its bounding box, and a point's is zero. Features of equal extent are shed in
> reverse of the order they were merged in. Dropping is across the whole tile, not per layer. A tile
> that still does not fit once one feature is left is skipped, as it is now, and
> `--no-tile-size-limit` still turns the limit off entirely.
>
> A tile that was reduced has to be as clean as one that was copied. A layer carries no attribute
> key and no attribute value that none of its remaining features uses, every remaining feature keeps
> the attributes it had, a layer with no remaining features is not written, and a tile with no
> remaining layers is not written.
>
> The tileset metadata has to describe the tileset that was produced rather than the ones that were
> read. Whatever `tile-join` drops is added to the per-zoom `dropped_as_needed` count in
> `strategies`, on top of the counts it inherits from its inputs, and the largest size a tile at that
> zoom wanted to be before it was reduced is reported there as `tile_size_desired`. A run that
> reduces nothing leaves `strategies` exactly as it inherited it. The layer statistics, the layer and tileset zoom
> ranges, and the tileset bounds count only the features that reached the output, whether they were
> dropped to make a tile fit or lost because the tile was skipped.

~300 words. Under the 500 hard cap. No `##` headers, no formulaic labels, no code-prose, backticks
only on the option names and the metadata keys.

---

## 7. File footprint (sketched against real source, calibrated by a built spike)

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | `tile-join.cpp` | 1678 | +235 | ~150 | options + globals; the reduce-to-fit ladder in `join_worker`; move the tilestats/bounds/zoom booking out of `append_tile` and onto the FINAL tile; per-worker strategy accumulation; `dispatch_tasks` + `decode` wiring |
| MODIFY | `mvt.cpp` | 902 | +60 | ~45 | pool compaction: mark used key/value indices, rebuild `keys`/`values`, remap every surviving feature's `tags`, reset the dedup caches |
| MODIFY | `mvt.hpp` | 258 | +3 | ~2 | declaration |
| MODIFY | `README.md` | 1064 | +14 | 0 | document both options and the accounting rule (repo convention: every option is in README) |
| MODIFY | `man/tippecanoe.1` | — | +20 | 0 | regenerated by `make docs` (go-md2man v2.0.7) — the repo's CI fails if it drifts from README |
| **TOTAL** | | | **+332 raw** | **~197 + the booking restructure** | 3 code files, 5 files total |

**Measured calibration, not a guess.** A thinnest-end-to-end spike (options + extent + ladder +
strategy merge, no compaction, no booking restructure) was built and run in the platform image:
`161 raw / 102 human-effective` by `.claude/hooks/effective_loc_check.py`. The remaining three
clusters — pool compaction and tag remap, the booking restructure, the zoom/bounds reconciliation —
are each larger than any single piece already in the spike, so the design lands at **~300-330
human-effective**, comfortably over the 200 floor and at the hook's 275 design target.

⚠️ Re-run the hook after the first complete reference and BEFORE writing tests
(`REPO-HUNT-2026-09-10-D` framework-maturity law).

---

## 8. Solution outline — helpers (1+ per described behaviour)

```
feature_extent(mvt_feature const &)                 -> double    <- "increasing order of extent"
rank_features(mvt_tile const &)                     -> vector    <- "across the whole tile, not per layer" + tie-break
drop_ranked(mvt_tile &, size_t keep)                -> size_t    <- "shed features until it fits"
mvt_layer::compact_attributes()                     -> void      <- "no attribute key and no attribute value that none of its remaining features uses"
drop_empty_layers(mvt_tile &)                       -> bool      <- "a layer with no remaining features is not written"
encode_and_compress(mvt_tile &)                     -> string    <- the measured quantity ("the compressed tile")
reduce_to_fit(mvt_tile &, size_t max, size_t *dropped) -> string <- the ladder + terminal case
book_tile(mvt_tile const &, layermap, bounds, z)    -> void      <- "count only the features that reached the output"
note_strategy(vector<strategy> &, z, dropped, size) -> void      <- "added to the per-zoom dropped_as_needed count"
```

Convergent loop (the ladder), explicit:

```
std::string compressed = encode_and_compress(tile);
while (compressed.size() > max_tile_size) {
        size_t keep = <largest prefix of the ranking that can still shrink the tile>;
        if (!drop_ranked(tile, keep)) break;      // cannot shed any further -> terminal case
        compact_attributes_of_every_layer(tile);
        compressed = encode_and_compress(tile);
}
```

**Booking restructure (the load-bearing change).** `append_tile` currently interleaves, per feature:
`outlayer.tag(...)`, `add_to_tilestats(...)`, `points++/lines++/polygons++`, per-layer
`minzoom`/`maxzoom`, and the tileset lat/lon bounds — all while merging, i.e. before the tile is
known to survive. The reference moves every one of those onto `book_tile`, called on the FINAL tile
in `join_worker` after reduction and only when the tile is actually written.

---

## 9. Test file outline

Driver: `tests/tile_join_limit_<hex>/run_tests.py` (Python 3 stdlib only — the platform image has no
pytest), invoked by `test.sh`. Behavioural through the CLI: build fixtures with `./tippecanoe`, run
`./tile-join`, read the output tileset with `sqlite3` + `./tippecanoe-decode`.

Block 1 — imports and paths
Block 2 — builder helpers: `geojson_points(n, ...)`, `geojson_polygons(...)`, `mixed_layers(...)`,
  `build_tileset(args)`, `join(args)`
Block 3 — assertion helpers: `tiles(path)`, `metadata(path)`, `decoded_features(path)`,
  `layer_pools(path)` (decoded keys/values per layer), `assert_no_unused_pool_entries(path)`
Block 4 — buckets:

| Bucket | Tests | Notes |
|---|---|---|
| limit option | 5 | default 500000; `-M` raises; `-M` lowers; long form; at-limit tile untouched (**N-1 fixture, L25**) |
| reduction | 7 | over-limit tile survives; fits under the limit; order is by extent; points before lines before polygons of larger bbox; tie-break; whole-tile not per-layer; determinism across two runs |
| cleanliness | 6 | no unused key; no unused value; surviving features keep their exact attributes; empty layer removed; empty tile not written; a merely-copied tile is byte-unchanged |
| accounting | 8 | `dropped_as_needed` written; ADDED to inherited input counts; `tile_size_desired`; tilestats count; tilestats attribute values; per-layer zoom range; tileset zoom range; bounds |
| skip path | 4 | no option -> still skipped, but tilestats/zoom/bounds do not count the skipped tile; `-pk` keeps the oversized tile and books it |
| cross-product (§11b) | 4 | see matrix |
| edge | 5 | empty tileset; single feature; budget of 1; budget larger than every tile; `--no-tile-compression` changes the measured size |

~39 tests. 5-axis coverage: every described atom, every option, every branch of the ladder, standard
edges, and the stated inverse (skipped tiles must not be counted).

---

## 10. Forced signatures / language-level traps

- C++, so no trait-bound class. The one forced shape is `mvt_feature::tags`: a flat vector of
  index pairs into `keys`/`values`. Compaction MUST rewrite these in pairs; an off-by-one remap
  silently pairs key *i* with value *j+1* and produces decodable but wrong attributes.
- `mvt_layer::key_dedup` / `value_dedup` are 65536-slot caches holding indices into the pools.
  Compaction that rebuilds the pools without resetting them corrupts every later `tag()` call.
- `encode_index` (`projection.cpp`) is a NULL function pointer inside `tile-join` — only
  `tippecanoe`'s `main` assigns it. Any solver that reaches for tippecanoe's spatial-index ranking
  segfaults. The stated extent rule needs no index, so this is a hazard for a wrong approach only,
  never for the stated one. **Not counted as a trap** (it is a crash, not a measurement).

---

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence in §6 | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | Dropped features' attribute keys and values stay in the layer's constant pools, so the tile barely shrinks and the ladder sheds far more than it needs | **F-17** proxy-metric drift | S4 machinery-riding integration | *output cleanliness* | #2, #4 | `mvt_tile::encode()` writes the WHOLE `keys`/`values` vector; nothing in the repo prunes it, and the size the agent measures is the proxy, not the features | "A layer carries no attribute key and no attribute value that none of its remaining features uses" | `cleanliness`: `assert_no_unused_pool_entries` after reduction |
| 2 | tilestats, per-layer zoom range and tileset bounds are booked in `append_tile` while merging, before the tile is known to survive | **F-9** cross-stage resolution drop | S3 baseline-preservation through a shared chokepoint | *metadata truthfulness* | #1, #3 | the booking site is 700 lines away from the size check and reads as unrelated plumbing; a local fix in `join_worker` cannot reach it | "The layer statistics, the layer and tileset zoom ranges, and the tileset bounds count only the features that reached the output" | `accounting` (5 tests) |
| 3 | The same books are wrong on the SKIP path, which exists today and has no new option attached | **F-20** sibling-API contamination | S3 | *the untouched code path* | #2 | agents scope the accounting fix to the new `--drop-smallest-as-needed` branch they just wrote | "whether they were dropped to make a tile fit or lost because the tile was skipped" | `skip path` (4 tests) |
| 4 | Ranking per layer instead of across the whole tile | **F-3** second-axis carve-out | A-tier orthogonal fair wall | *ranking scope* | #1 | dropping inside the per-layer loop is the natural place to write it | "Dropping is across the whole tile, not per layer" | `reduction`: smallest features all in one layer |
| 5 | `>=` instead of `>`: a tile whose size exactly equals the maximum gets reduced | **F-15** arming vs firing | B-tier support | *threshold polarity* | — | "larger than the limit" reads as "at the limit" | "larger than the limit" | `limit option`: at-limit tile untouched (**N-1 fixture**) |
| 6 | Recording the tile size in `strategies` for every written tile, not only for tiles that had to be reduced — which injects a `strategies` key into the metadata of EVERY join | **F-20** sibling-API contamination | **S3** baseline-preservation through a shared chokepoint | *the untouched normal path* | #2, #3 | "report the largest tile" reads as unconditional bookkeeping, and nothing in the new feature's own tests notices | "A run that reduces nothing leaves `strategies` exactly as it inherited it" | the repo's OWN `raw-tiles-test` golden file, which carries no `strategies` key — caught in **base** mode, not new mode |

Axes are distinct: output cleanliness / metadata truthfulness / untouched code path / ranking scope /
threshold polarity. #1, #2 and #3 are mutually interdependent — compaction changes which values
exist, which changes tilestats; and the booking fix has to be shared by both the reduce and the skip
path or #3 fires.

CONTRACT-STATED / FIX-HIDDEN, checked per trap: every sentence above states the required PROPERTY of
the output. None names `keys`/`values`/`tags`, `append_tile`, `add_to_tilestats`, or where the
booking should move to.

## 11b. Capability cross-product matrix (F-10)

axis 1 = tile outcome {reduced, skipped, copied unchanged} · axis 2 = layer structure {single layer,
several layers}

| | single layer | several layers |
|---|---|---|
| **reduced** | baseline cell | **off-diagonal**: smallest features concentrated in one layer — ranking must cross layers, and the emptied layer must disappear from the tile AND from tilestats |
| **skipped** | **off-diagonal**: no option given, tile skipped — bounds/zoom/tilestats must not count it | **off-diagonal**: skipped multi-layer tile must not leave any of its layers in the metadata |
| **copied** | byte-identical to today | **off-diagonal**: an untouched multi-layer tile must be byte-identical, proving the booking move did not change the normal path |

Predicted composition failure mode: OVER-firing — the emptied layer keeps its tilestats entry, or the
booking move double-counts a copied tile.

**Scope audit.** Every metric the contract names is scoped explicitly: extent is per feature, the
ranking is per tile, `dropped_as_needed` is per zoom, `tile_size_desired` is per zoom.

**Format-noun audit (L24).** Nouns naming units of the format: *tile* (the whole z/x/y unit,
compressed), *layer* (one named layer inside a tile), *feature*, *attribute key* / *attribute value*
(entries in a layer's constant pools). The one with a genuine extent ambiguity is *tile* in "larger
than the limit" — stated as "the compressed tile".

**Tolerance-fixture audit (L25).** The at-limit case is the N-1 fixture and it is in the plan.

**Unbounded-promise audit (L44/L45).** No sentence promises a bound on iterations or on how many
features survive. The terminal case is stated as a capability ("still does not fit once one feature
is left"), never as a performance guarantee.

**Stated-noun list (L46).** Every fixture's subject — tile, layer, feature, extent, bounding box,
attribute key, attribute value, `dropped_as_needed`, `tile_size_desired`, layer statistics, zoom
range, bounds, `-M`, `--maximum-tile-bytes`, `--drop-smallest-as-needed`, `--no-tile-compression`,
`--no-tile-size-limit` — appears in §6.

**Wrong Logic %:** predicted ~20-30%. Subtle-correctness territory, which is the intent.

---

## 12. Tier + category

- **Tier:** Olympus (single tier).
- **Category:** `feature-request` — the title verb is `Add` and the change introduces two new public
  options plus a new metadata contribution.

---

## 13. Predicted pass rate

- **Predicted 15-25%.**
- Reasoning: the ladder itself is crib-able from `tile.cpp`, which keeps the problem solvable (the
  solvability floor is the binding constraint, and this protects it). The rate is held down by three
  independent output properties that a working ladder does not give you: pool cleanliness (#1),
  metadata truthfulness (#2), and the same truthfulness on the pre-existing skip path (#3).
- Sanity: under the <=40% ceiling; well clear of 0% because a naive-but-careful implementation that
  reads the contract sentence by sentence can pass.

---

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 — architecture, subsystems, entanglement zones, test framework, template
- [x] Phase 2 run on the capability CLASS, issue BODIES and comments read, both orgs — 0 hits
- [x] Closest approved opened as scaffolding: `rust-minidump-stack-containment` (S-F accounting) and
      `avo-register-spilling` (S-G degradation)
- [x] Title verb-led, 7 words, names the subsystem
- [x] Shape declared with citation
- [x] Public API surface lists every asserted name
- [x] Canonical output form spelled out (§4)
- [x] 1 codebase-inferable requirement (the 500000 default), stated anyway
- [x] Description draft ~300 words, under the 500 cap, plain prose
- [x] File footprint sketched against real source and calibrated by a BUILT spike
- [x] LOC clears the floor with buffer (~300-330 human-effective vs a 200 floor)
- [x] 1+ helper per described behaviour (§8)
- [x] Convergent loop written out (§8)
- [x] Test outline 4-block, scenario-encoded names, 5-axis coverage
- [x] 5 named traps, each with F-id, pre-empt sentence and catching test
- [x] Traps on distinct axes; #1/#2/#3 interdependent
- [x] §11b cross-product filled; 4 off-diagonal cells have tests
- [x] Sibling-API audit (F-20): the skip path is the untouched sibling; guarded in both directions
- [x] Format-noun extents stated (L24)
- [x] Tolerance rule has its N-1 fixture (L25)
- [x] Unbounded-promise audit (L44/L45) — none present
- [x] Stated-noun list (L46) — every fixture subject is in §6
- [x] Representation-pin sweep (L48/L49) — assertions read VALUES (counts, byte sizes, attribute
      maps), never the JSON type of a metadata field; numbers compared numerically
- [ ] Predicted pass <=40% — predicted, to be measured
- [x] Category matches the description verb
- [x] Not pattern-followable — there is no second tool in the repo doing this, and the reduction
      machinery exists only inside `tile.cpp`'s `write_tile`, which `tile-join` does not link
- [x] Not in `RULES § Features already used`

---

## Why this is not a duplicate

Closest in our corpus: `rust-minidump-stack-containment` (an accounting layer over an engine's
discarded decisions) and `avo-register-spilling` (degrade instead of failing when a resource runs
out). This pick is the same two SHAPES in a different domain, with a different kernel — vector-tile
constant pools and tileset metadata — and no overlap in repo, language ecosystem or API surface.
`rejected/orb-ring-role-preservation` is the only other vector-tile pick and is about polygon ring
winding in a Go encoder.

Externally: no PR in `felt/tippecanoe` or `mapbox/tippecanoe`, any state, implements size-driven
reduction in tile-join. `felt#81` (open since 2023, 0 comments) asks only for the 500000 constant to
be configurable — a one-line change that this design contains as its smallest part.

---

## Phase 5 — failure-mode self-audit (run before exiting design)

`PLAYBOOK § Pattern 8`, five buckets:

1. **Hidden requirements — TWO FOUND AND FIXED.** The plan tested (a) that an under-limit tile is
   written byte-for-byte as today and (b) that `--no-tile-compression` changes which size is
   measured, and §6 stated neither. Both are now sentences in the draft. This is the S3
   baseline-preservation half of traps #2/#3: testing a preservation requirement the contract never
   states is exactly the unfairness that gets a submission reverted.
2. **Tech-spec tone** — the draft is plain prose, no headers, no labels, backticks only on option
   names and metadata keys.
3. **Tests that pass on base** — about 5 of ~39 will (the preservation and empty-input cells). They
   are deliberate regression guards, not feature tests, and each also asserts a metadata fact. The
   suite as a whole fails on base because `-M` and `--drop-smallest-as-needed` do not parse there.
   Count them at test-writing time and keep the ratio low.
4. **Tests over-constrain** — the extent formula, the tie-break and the threshold polarity are all
   stated, so asserting an exact drop order is fair. **No test asserts stderr text**: the
   "Skipping this tile" message stays an implementation detail.
5. **Solution under the floor** — no; ~300-330 human-effective against a 200 floor.

`RULES § Real Revert Causes` walked: no hidden requirements (after the fix above), no test.sh
trickery, no exact-string assertions, no scope creep, no regression on base, no dead code, no flaky
test (the drop order is a stated total order; tiles are keyed by z/x/y in a `std::map`; the strategy
merge is summation and a maximum, so thread count cannot change the result).

`AGENTS § Confirmed Blind Spots` walked: cross-feature ordering (pre-empted by the whole-tile
ranking sentence), unstated inverse (pre-empted by the skipped-tile clause), default ordering
(pre-empted by the tie-break sentence).

---

## Trap 6 was found by hitting it (L50 — harvest defects from your own reference)

The first complete core slice recorded `tile_size_desired` for every tile it wrote. That is the
natural reading of "report the largest tile", it passes every test the new feature would have, and
it **broke the repo's own `tests/raw-tiles/raw-tiles-z67-join.json`** at byte 1424: the golden file
carries no `strategies` key at all, and the change injected one into the metadata of every join.

Kept as a predicted trap rather than quietly fixed. It is the strongest kind available here:
- it is discriminated by an EXISTING repo test, so a solver's own green new-feature suite cannot warn
  them (this is exactly the L33 case for running mutations against BASE mode as well as NEW);
- the contract now states the preservation half explicitly, so it is fair;
- `tile.cpp:2892` shows the repo's own answer — `tile_size_out` is assigned only inside the too-big
  branch — so the correct semantics are discoverable, which keeps it solvable.

**Predicted iteration cycles: 2.**
