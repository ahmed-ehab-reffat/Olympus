# DESIGN.md — orb-ring-role-preservation

Repo: `paulmach/orb` (Go, MIT, 1123 stars) · BASE_COMMIT `a12a48ea0c2bcfdea706cc1ab274c735cbc68939` (2026-03-30)

---

## 1. Title

**Preserve polygon ring roles across GeoJSON and vector tile encoding**

---

## 2. Shape classification

- **Shape:** O-Pipeline-hard (SHAPES.md Pattern 12) — a new invariant threaded through a
  multi-stage encode pipeline where the algorithm placement must be invented, not copied.
- **Pass rate target:** 10-20% (ceiling 40%, bias to the low edge per PRIME DIRECTIVE + L10)
- **Best agent:** Orion (long-horizon); Nova expected to single-point-fix and fail
- **Dominant verdict:** MISSED_REQUIREMENT with a WRONG_LOGIC tail
- **Category:** enhancement (fixes silent corruption + adds a stated invariant)

---

## 3. Public API surface

Names tests will assert. Everything else is internal.

- `geojson.Geometry.MarshalJSON` — emits RFC 7946 ring orientation and closed rings
- `geojson.Feature.MarshalJSON` / `geojson.FeatureCollection.MarshalJSON` — same, recursively
- `mvt.Marshal` / `mvt.MarshalGzipped` — emits tile-space ring roles the decoder can recover
- `mvt.Unmarshal` — unchanged behaviour, now round-trip exact
- `orb.Ring.Orient(o orb.Orientation) orb.Ring` — NEW, returns a ring with the requested
  orientation, never mutating the receiver
- `orb.Polygon.Orient() orb.Polygon` — NEW, exterior CCW / holes CW, non-mutating
- `orb.MultiPolygon.Orient() orb.MultiPolygon` — NEW, same rule per polygon
- `geojson.CutAntimeridian(g orb.Geometry) orb.Geometry` — NEW, splits geometry crossing +/-180

---

## 4. Canonical output form

- **Ring closure:** a ring of 3+ distinct positions is closed by repeating the first position;
  rings of fewer than 3 positions are dropped from polygon output.
- **GeoJSON orientation:** exterior ring counterclockwise, every hole clockwise, measured by
  `orb.Ring.Orientation()` in the geometry's own coordinates.
- **Vector tile orientation:** ring roles must survive `Marshal` -> `Unmarshal`. A polygon with
  N holes decodes as a polygon with N holes; a multipolygon of K polygons decodes as K polygons
  in input order.
- **Degenerate rings:** zero-area rings (`Orientation() == 0`) are dropped from holes; a
  degenerate exterior drops the whole polygon.
- **Antimeridian:** a polygon crossing +/-180 becomes a multipolygon; each piece is independently
  oriented; each hole attaches to the piece containing it. Pieces ordered west to east.
- **Input immutability:** no exported call mutates the caller's geometry, including backing arrays.
- **Empty input:** empty rings/polygons produce empty output, never a panic.

---

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- Pipeline placement: "ring roles must be recoverable from the encoded tile itself"
  (states the OBSERVABLE, not where to compute it)
- Reference vs deep copy: "encoding never modifies the geometry it was given"
- Result ordering: "pieces ordered west to east"
- Falsy-on-invalid: "rings with fewer than three distinct positions are dropped"
- Compound order preservation: "a multipolygon decodes as the same polygons in the same order"

Codebase-inferable requirements: **1** (that `orb.Ring.Orientation()` is the measuring stick).

---

## 6. Description draft (meta.md) — WHAT only

> Target 190 words. No `##`, no labels, no HOW, no mention of projection, y-axis, coordinate
> space, or where normalisation belongs. The word "tile space" must NOT appear — that is the fix.

Draft (REVISED after the round-2 base-test regression — see feedback.md):

Add ring-role preservation to orb's vector tile encoder, and give callers a way to put polygon
rings into a known winding. A polygon's rings currently go out in whatever direction they were
given, so a hole can come back as solid ground.

A polygon encoded with `Marshal` and read back with `Unmarshal` should return a polygon with
the same holes, and a multipolygon should return the same polygons in the same order. The roles
have to live in the tile itself, not in orb's reader: a conforming vector tile reader that has
never seen this library should recover the same exterior rings and the same holes. Rings with
fewer than three distinct positions are dropped, and a polygon whose exterior encloses no area
is dropped entirely.

Existing GeoJSON and BSON output is unchanged.

Add `Orient` on `orb.Ring`, `orb.Polygon` and `orb.MultiPolygon`, returning a copy wound so an
exterior ring runs counterclockwise and every hole runs clockwise, closing any ring that is
open. Add `geojson.CutAntimeridian`, which splits geometry crossing the antimeridian so no ring
spans the seam. A split polygon becomes a multipolygon whose pieces are ordered west to east,
each piece independently oriented, with every hole attached to the piece that contains it.

None of these ever modify the geometry they are given.

**Why this wording.** It never mentions projection, coordinate space, the y-axis, or where
normalisation belongs. "Existing GeoJSON and BSON output is unchanged" is the fair statement of
trap 2 — it states the constraint without revealing that the natural shared-helper placement
violates it. "Recovered by a conforming reader that has never seen this library" is the fair
statement of trap 1 and justifies the raw-winding test, without saying to orient after
projecting.

**Rule-7 audit:** no enumeration of failure sites, no mention of projection or coordinate
spaces, no warning that the two encoders differ. The contrast is discoverable, never stated.

---

## 7. File footprint (MEASURED, not estimated)

Core orientation logic was written as real Go against the real API and measured with the
Counter-2 stripper: **raw 163 / counter1 147 / human-effective 103** (Go keeps only 63% of raw).

| Action | Path | Raw | Effective | Reason |
|---|---|---|---|---|
| NEW | `orient.go` | 95 | 60 | `Orient` on Ring/Polygon/MultiPolygon, non-mutating |
| MODIFY | `geojson/geometry.go` | 55 | 35 | RFC 7946 normalisation in MarshalJSON, recursive |
| MODIFY | `geojson/feature.go` + `feature_collection.go` | 30 | 19 | recursion through Feature layers |
| NEW | `geojson/antimeridian.go` | 175 | 110 | seam split, hole reassignment, west-east ordering |
| MODIFY | `encoding/mvt/marshal.go` | 50 | 32 | establish recoverable ring roles at encode |
| MODIFY | `encoding/mvt/geometry.go` | 45 | 28 | ring emit path + degenerate drop |
| **TOTAL** | **6 files (2 new, 4 modified)** | **450** | **~284** | |

Floor check: **284 effective >= 200** with 84 of buffer. **6 files >= 2.** Clears both.

---

## 8. Solution outline — pure-function helpers

- `orientRing(r orb.Ring, want orb.Orientation) orb.Ring` <- requirement: orientation
- `closeRing(r orb.Ring) orb.Ring` <- requirement: closure
- `dropDegenerate(p orb.Polygon) orb.Polygon` <- requirement: degenerate rings
- `orientPolygon(p orb.Polygon) orb.Polygon` <- requirement: exterior/hole rule
- `rolesForTile(p orb.Polygon) orb.Polygon` <- requirement: tile round-trip
- `splitAtSeam(r orb.Ring) []orb.Ring` <- requirement: antimeridian
- `assignHoles(pieces []orb.Polygon, holes []orb.Ring) orb.MultiPolygon` <- requirement: holes
- `sortWestToEast(mp orb.MultiPolygon) orb.MultiPolygon` <- requirement: ordering

Every helper copies before writing. `orb.Ring.Reverse()` is in-place and `append` can write
through to the caller's backing array — both are forbidden by the immutability requirement.

---

## 9. Test file outline

Path: `ring_roles_<hex>_test.go` at repo root + `encoding/mvt/tile_roles_<hex>_test.go`
(random hex suffix per the banned-marker rule; no `shipd`/`datacurve`).

- Block 1: imports
- Block 2: builder helpers (ccwSquare, cwSquare, holedPolygon, seamCrossingPolygon, ...)
- Block 3: assertion helpers (assertOrientation, assertRoundTripShape, assertUnmutated)
- Block 4: buckets
  - geojson orientation (exterior/hole/nested/collection)
  - closure + degenerate drops
  - **tile round-trip structure** (the lead trap)
  - immutability (caller geometry byte-identical after encode, incl. backing array)
  - antimeridian split + hole reassignment + ordering
  - **cross-product cell**: holed polygon straddling the seam, round-tripped through MVT
  - degenerate/empty: empty ring, 1-point ring, 2-point ring, zero-area hole

5-axis coverage: every described behaviour, every new API name, every solution branch,
edge cases (empty/single/boundary/degenerate/nested), stated inverse (multipolygon ordering).

---

## 10. Forced signatures

`Orient` must return a value rather than mutate, which forces a copy and collides with the
existing in-place `Ring.Reverse()`. Go slice aliasing via `append` is the live hazard: a helper
that closes a ring with `append(r, r[0])` writes into the caller's array whenever `cap > len`.
This is not stated in the meta — it is a repo/host-language discovery (F-4 precondition).

---

## 11. Predicted trap matrix

> **CORRECTION after hardening review.** The first draft listed the "two encoders need
> opposite reversals" trap as a separate axis from the placement trap. That was an
> over-claim: both reduce to WHERE the shared helper is called relative to the projection,
> i.e. the SAME axis. Traps sharing an axis die together the moment review forces a
> disclosure (lyon precedent). They are merged below as trap 1, and a genuinely different
> fourth axis (hole reassignment) is promoted to carry its own weight. Honest count: FOUR
> distinct axes, not five.

| # | Trap | F-id | Arsenal | Axis measured | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Ring roles must be established where the encoder emits, not where RFC 7946 lives. The projection inverts orientation, so one shared `Orient` helper called before projecting gets GeoJSON right and the tile wrong; called after, the reverse. There is no single call site that satisfies both. | **F-9** | S4 | WHERE normalisation survives to | **#2, #3** | The obvious home for "RFC 7946 orientation" is the geojson package; nothing points at the encoder | "a conforming reader that has never seen orb recovers the same ring roles" | `tile_roundtrip_polygon_with_hole_stays_a_polygon` + `raw_tile_ring_winding_is_conformant` |
| 2 | `Ring.Reverse()` is in-place and `append(r, r[0])` writes through to the caller's backing array whenever cap > len. The natural fix for #1 mutates the input. | **F-4** | A4 | host-language ownership | **#1** — the fix for #1 introduces this; the fix for this changes where #1 can run | Correct algorithm, silent caller corruption, no error | "Encoding never modifies the geometry it was given" | `marshal_does_not_mutate_caller_geometry` |
| 3 | Cross-product: a holed polygon straddling the antimeridian. Split pieces must each re-establish roles in the right space AND survive the round-trip. | **F-10** | S2 | multiplicity x seam | #1 | Both axes implemented in isolation; the cell is never constructed | composition of two stated contracts, zero new words | `seam_crossing_polygon_with_hole_round_trips` |
| 4 | Hole reassignment: when a polygon with holes splits at the seam, each hole belongs to exactly ONE piece. Naive implementations attach all holes to the first piece or duplicate them into both. | **F-3** | A3 | containment (second axis of a one-sentence rule) | #3 | The split rule reads as one requirement; the hole half is the unstated second axis | "every hole attached to the piece that contains it" | `seam_split_assigns_each_hole_to_its_own_piece` |
| 5 | Degenerate/empty rings: `Orientation()` indexes `r[0]` and panics on empty. | **F-6** | A8 | validation order | — | Degenerate input turns a wrong answer into a crash | "rings with fewer than three distinct positions are dropped" | `empty_ring_does_not_panic` |

### Architecture-jump escapes (HARDENING 3a.6) — two found, both closed

**Escape A — patch the decoder instead of the encoder.** An agent can make `Unmarshal` recover
roles by geometric containment rather than orientation. Every round-trip test then passes with
the encoder still emitting non-conformant tiles, which is precisely the bug. A round-trip test
through orb's own decoder CANNOT distinguish this.
*Closed by:* `raw_tile_ring_winding_is_conformant` — decodes the raw MVT geometry command
stream and asserts the emitted rings' tile-space orientation directly, without going through
`mvt.Unmarshal`'s role assignment. This is the machinery-forcing test.
*Fairness:* justified by the contract sentence about a conforming foreign reader, so it asserts
a stated observable (interoperability), not an implementation detail.

**Escape B — reverse every ring unconditionally at encode.** Trial-and-error blanket reversal
makes the headline round-trip test pass without understanding why.
*Closed by:* a test whose input polygon is ALREADY correctly wound for tile space, which
blanket reversal breaks. Orientation must be conditional on what the ring actually is.

**Not an escape:** re-deriving roles by containment at encode time is a legitimate alternative
implementation and still has to get tile-space winding right, so it does not bypass trap 1.

**Interdependence is by construction, not bolted on.** Traps 1, 2 and 3 all ride the single
orientation-normalisation chokepoint. Fixing #1 in the shared helper breaks #2; fixing #2 by
reversing in place breaks #3; fixing #3 by copying changes where #1 must run. That is the
"one fix breaks another" property, and it comes from the repo's real structure.

**Misdirection is inherited from the repo.** `unmarshal.go:371` assigns ring roles purely by
orientation, so trap #1 surfaces as a wrong geometry TYPE (`orb.MultiPolygon` instead of
`orb.Polygon`) two stages away from the cause. Nothing in the failure names the encoder.

**REPRODUCED (not a guess).** Probe on base: RFC-correct polygon with one hole, CCW exterior /
CW hole, marshalled and unmarshalled, returns `orb.MultiPolygon` with 2 polygons. Tile-space
orientations measured as -1 and +1, inverted from the geographic +1 and -1.

## 11b. Cross-product matrix

| | single polygon | polygon with hole |
|---|---|---|
| **does not cross seam** | test: `plain_polygon_round_trips` | test: `holed_polygon_round_trips` (trap 1) |
| **crosses seam** | test: `seam_polygon_splits_west_to_east` | **off-diagonal** `seam_crossing_polygon_with_hole_round_trips` (trap 4) |

---

## 12. Tier + category

Olympus. Category **enhancement**. 284 effective LOC / 6 files / expected 60+ solver messages.

---

## 13. Predicted pass rate

**10-20%.** Trap 1 alone is F-9-shaped (measured 60% on neva) and misdirects through a type
mismatch. Traps 2 and 3 are interdependent with it, so a single-point fix regresses. Trap 4 is
the F-10 near-miss decider. Risk of overshooting to 0% is mitigated because the meta states the
observable ("recoverable from the encoded tile itself"), which is the root cause named without
the fix, per HARDENING 3c-bis.

---

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5
- [x] Existing-PR check: orb has ONE open PR (geojson generic properties), no overlap
- [x] Maintainer philosophy: paulmach ASKED for this ("Error on marshal? some sort of
      validator?") and endorsed the architecture (geojson owns RFC 7946, copy-before-mutate)
- [x] Title verb-led, names subsystem
- [x] Shape declared
- [x] API surface lists every asserted name
- [x] Canonical form spelled out
- [x] <=1 codebase-inferable requirement
- [x] Description plain prose, no headers, no HOW
- [x] File footprint MEASURED (103 effective for the core, by stripper, not estimated)
- [x] 284 effective >= 200 floor with buffer; 6 files >= 2
- [x] 1+ helper per described behaviour
- [x] Test outline 4-block, scenario-encoded names, hex-suffixed files
- [x] 5 traps, each with F-id, pre-empt sentence and catching test
- [x] Traps on DIFFERENT axes; three interdependent through one chokepoint
- [x] Cross-product matrix filled, off-diagonal has a test
- [x] Lead trap REPRODUCED on base by probe before authoring
- [x] Predicted pass <= 40% ceiling
- [x] Not pattern-followable (no sibling implementation to copy)

**Why this is not a duplicate.** Closest approved sibling is `lyon-arcs-join` (geometry, F-8).
This shares the domain but not the mechanism: lyon's difficulty was retrieval-override on a
single comprehension sentence; this is a cross-stage placement wall with three interdependent
traps and no famous algorithm to retrieve. The antimeridian rule is the only externally-named
component and it is a supporting axis, not the core.

**Predicted iteration cycles:** 2.

**Open risk:** "GeoJSON ring orientation" is partially nameable externally. The MVT half and the
immutability contract need orb-internal nouns, which pulls dedup risk down but not to zero.
