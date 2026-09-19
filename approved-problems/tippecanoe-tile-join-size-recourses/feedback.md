# feedback.md — tippecanoe-tile-join-size-recourses

## Strategic summary

Give `tile-join` the tile-size recourses `tippecanoe` has. Today an over-limit merged tile is
dropped from the output entirely (`tile-join.cpp:884`) while the tileset metadata keeps advertising
it. The pick adds `-M`/`--maximum-tile-bytes` and `--drop-smallest-as-needed`, and makes the
tileset's own books (strategies, tilestats, zoom ranges, bounds) describe what was produced.

Shape: O-Composite-add · S-G degradation fused with S-F accounting. Target 15-25%.

## Status

| Stage | State |
|---|---|
| Repo picked, gates cleared | DONE (`REPO-HUNT-2026-09-12.md`) |
| Gap reproduced on base in the platform image | DONE |
| Docker feasibility built + suite run offline | DONE (61s build, 75s suite, `--network none`) |
| Baseline determinism 3x | DONE (no test flips) |
| Phase 1 repo understanding | DONE |
| Phase 2 existing-PR / publicly-solved | DONE, 0 hits, bodies + comments read, both orgs |
| Spike (thinnest end-to-end) | DONE — built, ran, 161 raw / 102 human-effective |
| DESIGN.md | DONE (14 sections + Phase 5 audit) |
| Dockerfile | DONE — verified non-root incremental rebuild (31s) |
| test.sh + tests | DONE — 29 new tests, 36 base testcases, JUnit valid |
| Reference solution (COMPLETE) | DONE — 253 human-effective, 5 files |
| Patches | DONE — apply in both orders, ASCII, test.sh mode 100755 |
| Clean-room validation | DONE — see Round 1 |
| Differentiating scope (booking restructure) | DONE — see Round 2 |
| README + regenerated man page | DONE (go-md2man v2.0.7, no unrelated drift) |
| Clean-room validation, full patches | DONE — see Round 2 |
| Flakiness 3x base + 3x new | DONE — identical every run |
| Docker build + non-root offline run of the final tree | DONE — 3m00s build, new 29/29, base 36/36 |
| Platform precheck round 1 | 2 blocking FAILs + quality FAIL, all fixed in Round 3 |
| Platform precheck round 2 | 1 blocking FAIL + solution gap, fixed in Round 4 |
| Auto Review round 1 | Revision Requested (Tests 1/3, Solution 1/3, Description 3/3), fixed in Round 5 |
| Auto Review round 2 | Revision Requested (Tests 1/3; Solution 3/3, Description 3/3), fixed in Round 6 |
| Auto Review round 3 | Revision Requested (Tests 0/3 harness Blocker; Solution 3/3, Description 3/3), fixed in Round 7 |
| Auto Review round 4 | Revision Requested (Tests 1/3 harness Blocker), fixed in Round 7 |
| Auto Review round 5 | Revision Requested (Tests 1/3, Solution 2/3), fixed in Round 8 |
| Auto Review round 6 | Approved with notes (Tests 2/3: `-e` directory output untested) |
| Batch 1 | **1/10 (Nova), ACCEPTED 2026-09-16** |
| Batch | not run |

## Attempt history

### Round 0 — design (2026-09-12)

- Spike measured 102 human-effective for options + extent + ladder + strategy merge. Remaining
  clusters (pool compaction and tag remap, the booking restructure, zoom/bounds reconciliation)
  put the design at ~300-330. Re-run the hook on the first complete reference BEFORE writing tests.
- The spike exposed the lead trap empirically: dropping features without pruning the layer's
  key/value pools left the tile at 457,530 bytes only after shedding **82,493 of 90,000 features**,
  because `mvt_tile::encode()` writes the whole constant pool regardless of what survives.
- Phase 5 audit found two hidden requirements (under-limit tiles written byte-for-byte;
  `--no-tile-compression` changes the measured size) and both are now stated in the draft.

### Round 1 — core slice built and validated (2026-09-12)

Clean-room in the platform image, pristine base + patches:

| Stage | Result |
|---|---|
| base mode on base | **36/36 pass**, exit 0 |
| new mode on base | **1/15 pass**, exit 1 |
| base mode with solution | **36/36 pass** — no regressions |
| new mode with solution | **15/15 pass** |
| reverse apply order | ok |
| JUnit testcases | base 36 / new 15 |

The one new test that passes on base is `oversized_tile_is_skipped_without_the_option` — the
deliberate baseline-preservation cell flagged in the Phase 5 audit, not a feature test.

**Base regression found and fixed, and kept as trap 6.** The first complete core slice recorded
`tile_size_desired` for every tile it wrote, which injected a `strategies` key into the metadata of
every join and broke the repo's own `tests/raw-tiles/raw-tiles-z67-join.json` at byte 1424. Narrowed
to record only when a reduction actually happened, and to report the PRE-reduction size (matching
`tile.cpp:2892`). Recorded in DESIGN.md as a predicted trap rather than silently fixed (L50).

**The lead trap is measured, not assumed.** Reducing the same 1,001,495-byte tile:
- without pool compaction (the naive implementation): 82,493 of 90,000 features shed
- with compaction: **56,301 shed, 33,699 survive** at 423,278 bytes

A naive implementation keeps ~4.5x fewer features and reports a wildly different
`dropped_as_needed`, because `mvt_tile::encode()` writes a layer's entire key/value pool regardless
of what survives.

### Round 2 - differentiating scope: the booking restructure (2026-09-12)

The core slice was 151 human-effective, under the 200 floor, and carried only the degradation half
of the design (S-G). Round 2 added the accounting half (S-F), which is traps #2 and #3.

**What changed.** `append_tile` booked tilestats, per-layer zoom range and tileset bounds per feature
WHILE merging, i.e. before the tile was known to survive. All of it now goes through a staging record
keyed by `mvt_feature::seq`, and `book_tile` commits only the records whose features reached the
written tile. The skip path books nothing. Implementation rationale, and why recomputing from the
final tile was rejected, is in `DESIGN.md § The booking restructure`.

**The repo's own comment turned out to assert the intent the code violated.** `tile-join.cpp:1905`
reads "don't trust the source metadata maxzooms; claim the zooms that were actually written" - but
the layermap zooms it reads were booked during merge, so a skipped tile still contributed its zoom.
That makes the requirement discoverable (fair) while the defect is real.

**Four independent discriminators, measured base vs solution** on one fixture (90000 points, `-Z0
-z1`, so the z0 tile is 1,222,547 bytes and skipped while four z1 tiles are written):

| metric | base | with solution |
|---|---|---|
| `minzoom` | 0 | 1 |
| tilestats `count` | 180000 | 90000 |
| layer zoom range | (0, 1) | (1, 1) |
| `bounds` minlat | -40.044438 | -40.010787 |

**Tie-break bug found in our own reference and fixed (L50).** `rank_features` numbered features in
(layer, feature) order and used that as the tie-break key. Layer index is first-appearance order, so
that is NOT merge order: a later-merged input feeding an earlier layer sorts ahead of an
earlier-merged input that opened a later layer. The key now comes from `mvt_feature::seq`, the same
staged identity the accounting uses - so the drop order and the books are coupled through one value.

**Validation, pristine base + generated patches, platform image, `--network none`:**

| Stage | Result |
|---|---|
| both patches apply to pristine base, and in reverse order | ok |
| base mode on base | **36/36 pass** |
| new mode on base | **2/29 pass** |
| base mode with solution | **36/36 pass** |
| new mode with solution | **29/29 pass** |
| build warnings under `-Wall -Wextra -Wshadow -Wunreachable-code` | none |

The 2 new tests that pass on base are both deliberate preservation cells:
`oversized_tile_is_skipped_without_the_option` and `no_tile_size_limit_books_the_oversized_tile`
(under `-pk` nothing is skipped, so the books are identical before and after). 2 of 29 is well under
the design's predicted 5 of 39.

**Base stayed 36/36 through the restructure**, which was the main risk: the repo has golden files over
tile-join's tilestats (`joined.json` and the four `joined-tile-stats-*` variants). Staging preserves
the exact `serial_val` objects, the `add_to_tilestats` call order and the layer-creation order, so
nothing drifted.

**LOC: 151 -> 253 human-effective** (389 raw, 5 files). Above the 200 floor with a 26% buffer and
inside the 250-300 design band, under the hook's 275 stretch target. Candidates for more were all
scope invention or fairness risks; they are enumerated and declined in
`DESIGN.md § Why the reference stops here`.

### Round 3 - platform precheck feedback (2026-09-13)

Precheck returned two blocking FAILs (Verify Tests, Verify Solution: both on one base test), a
Solution Quality FAIL with three high findings, and two description/test warnings. All addressed.

**Blocker: `make_allow_existing_test` failed on the platform's clean baseline, never locally.**
Root cause is a pre-existing tippecanoe defect, not our patch. The `--allow-existing` path's golden
output only matches when tippecanoe runs with 8 or fewer threads; thread counts are rounded to a power
of two and taken from `TIPPECANOE_MAX_THREADS` before `sysconf`. Measured on the image:
threads 1/2/4/8 pass, 16/32/64 fail at the `cmp` (the `UNIQUE constraint failed: metadata.name`
messages appear at every count, so they are not the discriminator). This workstation has 8 CPUs; the
platform host evidently has more. Not reproducible by repetition (8/8), `taskset`, tmpfs, or low
`ulimit -n` down to 256. Fix: `test.sh` exports `TIPPECANOE_MAX_THREADS=8` in both modes, with a
two-line reason, which is the parallel-determinism pin `TESTS.md` names as the preferred fix over
excluding the test.

**Solution Quality - all three high findings were real defects in our reference:**

| Finding | Fix | Test that now pins it |
|---|---|---|
| `keep` floors to 0 when the tile is over 1.33x the limit with 2 features, emptying a tile whose last feature would fit | clamp `keep` to at least 1 | `a_tile_is_reduced_to_its_last_feature_when_that_feature_fits` (2131-byte pair vs 1082-byte budget) |
| features shed from a tile that is still skipped never reached `strategies` | record `dropped` / `desired` before the skip decision | `features_shed_from_a_tile_that_is_still_skipped_are_reported` (20 shed, 0 tiles) |
| base `handle_strategies` SUMS inherited `tile_size_desired`, so inherited + new gave a size no tile had | take the maximum | `shed_counts_are_added_to_inherited_strategies`, `tile_size_desired_is_the_larger_of_the_inherited_and_the_new_size` |
| (low) `-M` used bare `atoll` | reuse the linked `is_integer`, reject non-integers and negatives with `EXIT_ARGS` | untested on purpose: the error text is not in the contract |

The second finding had been logged in Round 2's open questions as a deliberately untested
ambiguity. The reviewer read "Whatever tile-join sheds" literally, which is the better reading, so the
sentence now says it outright ("including from a tile that ends up skipped anyway").

**Coverage the reviewer asked for, added:** line extent ordering (straight lines of w+h 34 vs zigzags of
w+h 22 but longer length and larger area, so area- or length-based ranking gets it backwards: 0 zigzags
survive, 138 straights do), exact largest `tile_size_desired` across four z1 tiles (328770, not the
1.31M sum), and a no-op run preserving non-empty inherited `strategies` exactly. Not added: a
byte-identity test for untouched tiles, because the sentence it would rest on was removed at the
reviewer's request.

**Warnings:** tile-join tests now spell the limit switch `--no-tile-size-limit`, as the description
does, instead of `-pk`. `meta.md` lost the five filler clauses the reviewer listed and gained the two
semantics above; body 362 -> 317 words.

**Totals:** 29 -> 36 new tests. LOC 253 -> 261 human-effective (401 raw, 5 files).

**Validation of the Round 3 patches** (pristine base, `TIPPECANOE_MAX_THREADS=64` forced from outside
to mimic the platform host): base-on-base 36/36 x3 identical; new-on-base 2/36; base+solution 36/36 x3
identical; new+solution 36/36 x3 identical; JUnit parses (36/36); Dockerfile builds; in-image
non-root offline run new 36/36, base 36/36.

### Round 4 - platform precheck 2 (2026-09-13)

Round 3 cleared the base-suite blocker and the three quality defects. Precheck 2 returned one new
blocking FAIL, one solution gap, and advisory warnings.

**Blocker: two new tests passed without `solution.patch`.** The platform requires every new test to
fail, error or skip on base. `oversized_tile_is_skipped_without_the_option` and
`no_tile_size_limit_books_the_oversized_tile` were pure preservation cells (flagged as such in Round
2/3 and wrongly treated as acceptable). Each now also asserts something only the feature satisfies:
the skip test checks the skipped tile leaves no layer in tilestats (base books it during merge), and
the unlimited test runs with `--drop-smallest-as-needed` too and checks nothing was shed
(`strategies` absent). **Lesson: "a handful of preservation cells that pass on base" is not allowed on
this platform at all - every F2P node must fail on base.**

**Solution gap: `--exclude-all-tile-geometries` erased the ranking key.** That branch sets
`type = -1` and copies no geometry, and ranking read the output feature, so every extent was 0 and
shedding fell back to pure merge order. Fix: the scaled geometry is computed once, its extent is
stored in `staged_feature::extent` before the exclusion branch, the layer-rescale loop keeps staged
extents in step (recomputed from live geometry, or scaled by the extent ratio when there is none),
and `rank_features` reads the staged extent by `seq`. The description now states the rule. Test-first:
`extent_still_orders_shedding_when_geometries_are_excluded` FAILED on the Round 3 binary (both `big`
and `small` survived) before the fix was written.

**Coverage suggestions taken** (both are real wrong-formula traps, each with in-test fixture guards
that assert the two metrics really disagree on the decoded tile):
- `polygons_are_shed_by_the_area_of_their_bounding_box` - thin 0.5x20 degree rectangles vs 5x5
  squares, so area and width+height rank them in opposite orders. The graduated squares could not
  tell those formulas apart.
- `lines_are_not_ranked_by_their_longest_side` - straight 9-degree lines vs 5.3x5 degree bent lines,
  so width+height disagrees with the longest side (and with endpoint distance).
Not taken: points vs tiny positive extents (z0 drops lines that short, so the fixture would be fragile).

**Description warnings:** added the two alignment clauses (`strategies` is the JSON array with one object
per zoom; absent when nothing was inherited or shed). Declined all four "only necessary information"
trims, because each would unstate something a test pins: the booking sentence (13 tests), the
one-feature skip clause (`features_shed_from_a_tile_that_is_still_skipped_are_reported`), the 500000
default (the default-limit tests), and the opening line (the required feature-request first sentence).
Body 317 -> 354 words.

**Validation of the Round 4 patches** (pristine base, threads=64 forced from outside): base-on-base
36/36 x3 identical; **new-on-base 0/39**; base+solution 36/36 x3 identical; new+solution 39/39 x3
identical; JUnit parses; Dockerfile builds; in-image non-root offline new 39/39, base 36/36. LOC 261 ->
277 human-effective (425 raw), now above the hook's 275 target. Tests 36 -> 39.

### Round 5 - Auto Review: Revision Requested (2026-09-15)

Description 3/3 (clean). Tests 1/3 and Solution 1/3, each on one verified High finding. No agent
runs yet. `meta.md` untouched this round, so the solver-visible surface did not change.

**S1 High (solution): false ties after a non-divisible rescale under `--exclude-all-tile-geometries`.**
Round 4 staged a summary extent and, for features with no output geometry, multiplied it by a float
extent ratio. Base rescales coordinates with integer division, so the reviewer's case (extent 3 -> 4,
lines (0,0)-(1,0) and (2,0)-(3,0)) has merged widths 1 and 2 but staged widths 4/3 and 4/3, and the
reverse-merge-order tie-break sheds the larger one. Fix: stage the integer bbox (`feature_box`) instead
of a number and rescale its four corners with the repo's exact expression `v * to / from`. Truncating
division is monotone, so the rescaled corners are exactly the bbox of the rescaled geometry; this
also deletes the separate live-geometry branch. Test-first:
`excluded_geometries_are_ranked_on_their_rescaled_coordinates` kept {1, 3} on the Round 4 binary
and passes after the fix. The fixture is a hand-encoded MVT (new `mvt.encode_tile` helper) because
tippecanoe only emits power-of-two extents, which can never truncate.

**T4 High (tests): no same-name layers with different extents.** Added
`a_coarser_layer_is_ranked_after_its_coordinates_are_rescaled`: a `-d10` (extent 1024) tileset of
10-degree lines joined with a default-detail (4096) tileset of 5-degree lines. Guards assert the source
extents are 1024/4096, that the coarse lines are SMALLER in source units, and LARGER after merging, so
ranking in source coordinates sheds the wrong set.

**Mediums, both taken:** JUnit failure bodies now carry `traceback.format_exc()` instead of
`repr(exc)`; `layer_statistics_omit_a_dropped_features_attribute_value` also asserts tilestats
`geometry` goes from Point (point-majority input) to Polygon after the points are shed.

**Advisory, taken:** `shed_counts_are_added_to_every_inherited_input` (two inputs carrying 100 and 200).
Not taken: point extent vs a degenerate zero-extent line (a zero-length line is not a fixture worth
defending). Optional description trims declined: the `strategies` shape clause was added at an earlier
alignment reviewer's request, and the skip-path clause is pinned by the skipped-tile tests.

**Environment incident:** every Docker image on the host, including `olympus-base-cpp` and our
`tj-olympus`, disappeared between sessions (not caused by this session; no prune was run), and the
scratchpad was wiped, taking the clean-room script with it. Base image re-pulled (same digest
`ce073a88`); the clean-room script now lives at `worktrees/_tj_tools/cleanroom.sh` and follows the
vacuous-`git apply` rules (clone-root assert, patch markers, revert-to-clean in both orders).

Tests 39 -> 42. LOC 277 -> 278 human-effective.

**Validation of the Round 5 patches** (hardened clean-room, threads=64 forced): apply+revert clean in both
orders; base-on-base 36/36 x3 identical; **new-on-base 0/42**; base+solution 36/36 x3 identical;
new+solution 42/42 x3 identical; JUnit parses; Dockerfile builds; in-image non-root offline new 42/42,
base 36/36.

### Round 6 - Auto Review 2: Revision Requested, tests only (2026-09-15)

Description 3/3, **Solution 3/3 (clean, no issues)**, Tests 1/3 on two verified coverage gaps. Both gaps
are behaviors the reference already implements, so this round changed `test.patch` only; `meta.md` and
`solution.patch` are byte-identical to Round 5.

**Gap 1: `tile_size_desired` across several inherited inputs.** Every desired-size case had one inherited
input, so keeping base's `+=` passed. `strategies_inherited_from_every_input_are_combined` (was
`shed_counts_are_added_to_every_inherited_input`) now gives the two inputs desired sizes 5000000 and
6000000 as well as counts 100 and 200, and asserts max 6000000 and sum own+300.

**Gap 2: exact `dropped_as_needed` across multiple reduced tiles.** The quad z0-z1 test asserted only
desired sizes. Replaced by `strategies_total_every_reduced_tile_at_each_zoom` on a new z0-z2 pyramid
(96000 points, every one of the 21 tiles over the 60000-byte limit): per zoom, the recorded count must
equal features before minus features after, and desired size must equal the largest unreduced tile.
Fixture reasoning: `dispatch_tasks` hands tasks to workers round-robin and `test.sh` pins 8 threads, so
the quad fixture's 5 tiles landed in 5 different workers. That catches last-worker-wins but can never
catch per-tile assignment inside a worker. With 21 tasks, tasks 8 and 16 are both z2 tiles in worker 0.

**Advisory taken: exact zero point extent.** `a_multipoint_is_shed_as_a_zero_extent_feature` uses the
hand-encoder: a MultiPoint spanning 100 units merged before a 1-unit line. Correct ranking (0 < 1) sheds
the MultiPoint; a bbox-for-every-type extent (200) or a positive point constant (a tie, shed from the
end of the merge order) sheds the line instead.

**Mutation check (worktrees/_tj_tools/mutants.sh), each mutant on its own rebuilt binary:**

| Mutant | Killed by | Result |
|---|---|---|
| inherited `tile_size_desired` summed with `+=` | two-input inheritance test | FAIL |
| per-tile `dropped_as_needed` assigned, not added | pyramid test | FAIL |
| worker merge assigns, last worker wins | pyramid test | FAIL |
| point extent taken from the bbox | MultiPoint test | FAIL (kept {2, 3}) |
| correct solution | all three | PASS |

Source restored byte-for-byte and rebuilt afterwards. Tests 42 -> 43.

**Validation of the Round 6 patches** (hardened clean-room, threads=64 forced): apply+revert clean in both
orders; base-on-base 36/36 x3 identical; **new-on-base 0/43**; base+solution 36/36 x3 identical;
new+solution 43/43 x3 identical; JUnit parses; Dockerfile builds; in-image non-root offline new 43/43,
base 36/36.

### Round 7 - Auto Review 3: Revision Requested, harness Blocker (2026-09-15)

Description 3/3, Solution 3/3, **Tests 0/3** on one Blocker plus two Mediums. `test.patch` only again;
`meta.md` and `solution.patch` byte-identical to Round 5.

**Blocker (T8, deceptive reporting) - real, in our base-mode adapter.** `run_base` parsed the repo's
Catch2 JUnit but only looked for `<failure>`. Catch2 writes uncaught exceptions and fatal errors as
`<error>`, and once the XML parsed, the unit runner's nonzero exit was never consulted. Fix: a testcase
with any `<failure>` or `<error>` child is failed with all of their text, and a nonzero unit exit with no
failed case adds a failing `unit_suite` node. In the normal passing case the node set is unchanged.
Reproduced before fixing: with `TEST_CASE("Bit reversal")` made to throw, the Round 6 adapter reported
19 unit nodes and **no failures**; the Round 7 adapter reports `unit_Bit_reversal` failed.
**Lesson: adapting a repo's own test runner is part of the test surface. Map every failure element its
reporter emits and never let a parsed report outrank the process exit code.**

**Medium: key-pool compaction was only half-discriminated.** The pool test used `dense_points`, where
every feature carries the same keys, so leaving the key pool untouched passed. It now uses the mixed
fixture, where only the shed points carry `cat`, and guards that `cat` was in the unreduced key pool.
Mutant (keys neither moved nor cleared, `key_dedup` not reset): new test FAILS ("keeps 1 unused
attribute keys"); the Round 6 test PASSES on the same mutant, confirming the gap.

**Medium: only int and string values were checked.** `surviving_features_keep_the_type_of_every_attribute_value`
hand-encodes survivors carrying bool, double, float, sint, uint, int and string values plus 40 shed
points. It compares value AND wire type against the unreduced join of the same input (so tile-join's
own copy semantics are the baseline, not an assumption), guarding that at least 6 distinct wire types
survive that copy. `mvt.py` gained typed value encoding and records each value's wire field on decode.
Mutant (booleans rewritten as strings in `compact_attributes`): FAILS (`flag` came back `('true', 1)`).

Mutations run by `worktrees/_tj_tools/mutants7.sh`; sources restored byte-for-byte and rebuilt.
Tests 43 -> 44.

**Validation of the Round 7 patches** (hardened clean-room, threads=64 forced): apply+revert clean in both
orders; base-on-base 36/36 x3 identical; **new-on-base 0/44**; base+solution 36/36 x3 identical;
new+solution 44/44 x3 identical; JUnit parses; Dockerfile builds; in-image non-root offline new 44/44,
base 36/36.

### Round 8 - Auto Review 4: Revision Requested (2026-09-15)

Description 3/3, Tests 1/3 (two Highs, one Medium), Solution 2/3 (S1 Medium, docs Low); Solution Quality
PASS with one more Medium (stale bounds). All accepted. This round touches the solution, the docs,
one `meta.md` sentence, and the tests.

**S1 (solution): a tile too large to shed was left out of `tile_size_desired`.** Recording was gated on
the tile itself shedding, so a 1-feature oversized tile that `reduce_to_fit` could not touch never
counted, even when another tile at the same zoom shed. Redesign: workers record the largest desired size
of every tile over the limit with shedding enabled (`arg::oversized`), `note_strategy` now only counts
drops, and after the last `dispatch_tasks` (which in `decode()` is always BEFORE the readers loop merges
inherited `strategies`) a zoom takes that maximum only if this run shed something there. A run that
sheds nothing still leaves `strategies` untouched. Test-first:
`tile_size_desired_counts_a_tile_too_large_to_shed` reported 6841 (the tile that shed) on the Round 7
binary instead of the lone tile's size. `meta.md` now says "including a tile that could not be reduced
at all"; 362 body words.

**Bounds (Solution Quality Medium): staged world bounds went stale on a later layer rescale.** Bounds were
staged at merge time in the then-current extent. `book_tile` now computes them from the written tile's
geometry and final layer extent; excluded-geometry features never had bounds anyway, so the staging was
unnecessary. Test-first: `bounds_follow_features_rescaled_into_a_larger_extent` gave minlon 60 and maxlat
-51 on the Round 7 binary (the pre-rescale position) instead of 0 and 0.

**Docs (Low):** README `-M` now says compressed tile, or uncompressed with `--no-tile-compression`;
`-pk` says "Don't limit the size of tiles." Man page regenerated.

**Tests (High): global tie order across inputs and layers.** New
`ties_are_shed_in_merge_order_across_inputs_and_layers`: one input carries layers a and b, the other only
a, all equal-extent points. Finding along the way: `tileset_reader::operator<` breaks ties between
readers at the same tile by comparing the raw tile bytes (`data < r.data`), NOT by command-line order, so
the first draft's hard-coded order was wrong (the second input merged first). The test now reads the
merge order off its own guard, accepts either order, and derives the expected survivor prefix and the
budget from it. Both orders catch a per-layer sequence.

**Tests (High): strategies on an oversized skip with no shedding.** `oversized_tile_is_skipped_without_the_option`
now asserts `strategies` is absent; `an_oversized_tile_skipped_without_shedding_keeps_inherited_strategies`
seeds inherited strategies (with `-M 500000` so base fails on the flag, not on behavior);
`a_tile_that_cannot_shed_leaves_strategies_untouched` covers the shedding-enabled branch where a lone
oversized tile cannot shed, both absent and inherited.

**Tests (Medium):** `maximum_tile_bytes_long_form_sets_the_limit` reduces a 20000-point tile with
`--maximum-tile-bytes=40000` and checks features dropped and size <= 40000.

Declined (advisory): inherited strategies at nonzero zooms. `handle_strategies` (base) already walks
every index, and the reviewer did not elevate it.

Tests 44 -> 49. LOC 278 -> 294 human-effective.

**Mutation check (`worktrees/_tj_tools/mutants8.sh`)**, correct solution first: all seven round 8 tests PASS,
base 36/36, new 49/49.

| Mutant | Result |
|---|---|
| ties broken by per-layer position | new cross-input tie test FAILS; the old single-layer tie test still PASSES (gap confirmed) |
| desired size recorded for any oversized tile, shedding or not | all three skip-without-shedding tests FAIL |
| `--maximum-tile-bytes` accepted but its value ignored | long-form test FAILS on the size/feature assertion (the option parsed) |

The long-option mutant also broke `-M` parsing as a side effect (tippecanoe derives the short-option
string from the long-option table), so the `-M` smoke test failing under it is not a meaningful kill.
Source restored byte-for-byte and rebuilt.

**Validation of the Round 8 patches** (hardened clean-room, threads=64 forced): apply+revert clean in both
orders; base-on-base 36/36 x3 identical; **new-on-base 0/49**; base+solution 36/36 x3 identical;
new+solution 49/49 x3 identical; JUnit parses; Dockerfile builds; in-image non-root offline new 49/49,
base 36/36.

### Round 9 — batch 1 and acceptance (2026-09-16)

**1/10, Nova (rd79de2m), accepted.** FP panel: genuine pass at high confidence; the only divergence
from the reference was unvalidated `-M` input, ruled out of scope. Final Auto Review approved with
notes: Tests 2/3 for the untested `-e` directory-output surface, Solution 3/3, plus a pre-existing Low
where `handle_strategies` drops trailing empty zoom objects.

**Two ENV-blocked flags, both contested and upheld.** Nova #4 (rd7ccsjt, FAIL_TEST_BROKEN) and Nova #2
(rd761495, FAIL_EXECUTION_ERROR_EXTERNAL) had each `git restore`d `tile-join`, `tile-join.o` and the
other objects after their last build, so plain `make` in test.sh reused the baseline binary. The
contest quoted the trajectory call; the replacement runs are in the accepted batch.

**What decided it (evaluator attributions, since the JUnit files carry no per-test signal):** F-15
accounting cell 4/10, F-33 inherited `+=` merge 3/10, one regression, one quadratic timeout. Every trap
DESIGN.md named killed nobody. Carried into `failure-patterns.md` as F-33, the F-15 accounting
variant, L63 (tracked build outputs) and an L50 evidence line.

## Fix history

| # | Issue | Fix |
|---|---|---|
| 1 | `strategies` written for every tile broke `raw-tiles-z67-join` golden file | record only when `dropped > 0`; report pre-reduction size |
| 2 | `atoll_require` is not linked into tile-join | use `atoll`, matching tile-join's own `atoi` style |
| 3 | `an_emptied_layer_is_not_written` fixture used a budget no tile could reach | size the budget from a wide-layer-only join |
| 4 | `__pycache__` captured into test.patch | `git rm --cached`, regenerate |
| 5 | `__pycache__` reappeared, root-owned from the container | `test.sh` now runs `python3 -B` |
| 6 | `append_tile`'s `struct arg *a` went unused once bounds moved out (`-Wunused-parameter`) | parameter removed; `layermap` marked `/* layermap */`, the repo's own idiom for `db` |
| 7 | tie-break keyed on layer-major position, not merge order | key from `mvt_feature::seq` |
| 8 | two new tests asserted on a z0 polygon fixture that tippecanoe discards (6 of 600 features arrived; `-pt` only raised it to 27) | small-extent group rebuilt from points; polygons sized in degrees |
| 9 | base `allow-existing-test` fails on hosts with >8 threads (platform precheck) | `TIPPECANOE_MAX_THREADS=8` exported in `test.sh` |
| 10 | reduction could empty a tile whose last feature fits | `keep` clamped to >= 1 |
| 11 | shed counts lost when the reduced tile is still skipped | `note_strategy` before the skip decision |
| 12 | inherited `tile_size_desired` summed | maximum in `handle_strategies` |
| 13 | `-M` accepted junk | `is_integer` validation |
| 14 | tests used `-pk` while the description names `--no-tile-size-limit` | long form in tests |
| 15 | two F2P tests passed on base (preservation-only) | each given a feature-dependent assertion |
| 16 | shedding order degenerated under `--exclude-all-tile-geometries` | extent staged before geometry is stripped |
| 17 | float-scaled staged extent made false ties after a non-divisible rescale (excluded geometry) | stage the integer bbox, rescale corners with the repo's integer expression |
| 18 | no differing-layer-extent test | `-d10` vs 4096 fixture plus a hand-encoded extent 3/4 fixture |
| 19 | JUnit failure text lacked tracebacks | `traceback.format_exc()` |
| 20 | inherited `tile_size_desired` max untested across two inputs | two-input test carries distinct desired sizes |
| 21 | `dropped_as_needed` total untested across reduced tiles / workers | z0-z2 pyramid test with exact per-zoom totals |
| 22 | exact zero point extent unpinned | MultiPoint vs 1-unit line, hand-encoded |
| 23 | base adapter ignored Catch2 `<error>` and the unit exit code once XML parsed | read `<failure>` and `<error>`; nonzero exit with no failed case fails `unit_suite` |
| 24 | key-pool test fixture had no key unique to shed features | mixed fixture, `cat` only on shed points |
| 25 | attribute preservation checked only int and string | typed-value fixture: bool, double, float, sint, uint, int, string |
| 26 | oversized tile that could not shed missing from `tile_size_desired` | per-zoom oversized maxima applied at zooms that shed |
| 27 | staged bounds stale after a later layer rescale | bounds computed from written geometry at booking |
| 28 | README `-M` / `-pk` wording | corrected, man page regenerated |
| 29 | tie order untested across inputs/layers | guard-derived merge order test |
| 30 | strategies untested on oversized skips without shedding | three assertions / tests |
| 31 | long option only smoke-tested | behavior-changing limit |

## Open questions

- RESOLVED: README + man page are shipped. `go-md2man v2.0.7` installed on the host (the repo pins
  that version at `Makefile:51`); `make -B docs` produced exactly the two-hunk delta for the new
  options and no unrelated drift.
- RESOLVED: 2 of 29 new tests pass on base, both preservation cells.
- Suite runtime is 2m18s for new mode, driven by rebuilding 90000-point fixtures per test (each test
  gets a fresh WORK dir). If the platform run is time-boxed tighter than that, the quad fixture can
  drop to ~50000 points and still clear 500000 bytes at z0.
- `strategies` on a tile that is reduced and STILL too big (so skipped) is deliberately untested: the
  contract does not say whether features shed from a tile that never reached the output count toward
  `dropped_as_needed`. Leaving it untested keeps it from becoming an unstated requirement.
