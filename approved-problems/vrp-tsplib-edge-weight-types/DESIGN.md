# DESIGN.md — vrp-tsplib-edge-weight-types

Repo: `reinterpretcat/vrp` (Rust, 7-crate VRP metaheuristic solver workspace).
Base commit: `1b0a5e8c49dbf3e34aba5bf1a2ac57fe5af82655` (2026-08-20).
Crate: `vrp-scientific` (academic benchmark format readers: Solomon, TSPLIB, Lilim).

## 1. Title

Add TSPLIB non-Euclidean edge-weight-type support to the CVRP scientific reader

(verb: Add — net-new capability, feature-request category)

## 2. Shape classification

- Shape: closest to Olympus **O-Composite-add** (new capability spanning parsing + a
  shared transport-construction layer within one crate), sized and file-count-wise closer
  to the historical Mars **D-change** band (extends an existing cross-cutting dispatch point
  — `EDGE_WEIGHT_TYPE` — with new variants, each wired through parsing + transport
  construction). Single crate (`vrp-scientific`), 3 files, no cross-crate span — this is a
  smaller Olympus pick, not a Vega-scale rewrite, and that is a deliberate choice: see
  "Why this is not a duplicate" below for why bigger was not available in the cold lanes.
- Definition (SHAPES.md § Pattern 11, D-change): "Cross-crate variant signature change" —
  adapted here to "cross-cutting variant addition within one crate": `EDGE_WEIGHT_TYPE` is
  parsed once and consumed by both job construction (location assignment) and transport
  construction (distance lookup), so adding variants touches the parse site, the job-building
  site, and the transport-construction site together.
- Pass rate target: ≤40% (current sprint ceiling), designing toward the low-to-mid band
  (~15-25%) given one S4/F-9-style lead trap plus two orthogonal support traps.
- Best agent: Nova→Orion (parsing-heavy, moderate integration depth: matches the A1/D-change
  profile more than a Vega-scale multi-file refactor).
- Dominant verdict: MISSED_REQUIREMENT (silently wrong distances) rather than
  INTEGRATION_ERROR (compile failure) — the lead trap produces a solution that solves and
  reports a cost, just the wrong one, which is the harder-to-notice failure mode.
- Solver/our LOC ratio: unmeasured (no prior TSPLIB-format pick in this workspace to compare
  against); expect roughly A2-D-change range (~1.3-1.7x) given the parsing-heavy, dispatch-lite
  nature of the work.

## 3. Public API surface

Deliberately minimal. The only externally-visible behavior change is what `read_tsplib`
accepts and what `Problem` it produces — no new public types are added to avoid the
unstated-public-API-signature compile-wipe hazard (`failure-patterns.md` C-5).

- `TsplibProblem::read_tsplib(self, is_rounded: bool) -> Result<Problem, GenericError>` —
  **signature unchanged**. Previously errored (`"expecting 'EUC_2D' as EDGE_WEIGHT_TYPE, got
  '<X>'"`) for any `EDGE_WEIGHT_TYPE` other than `EUC_2D`. Now succeeds for `EUC_2D` (existing,
  unchanged), `CEIL_2D`, `ATT`, `GEO`, and `EXPLICIT`, and still errors with the same message
  shape for anything else (e.g. `EDGE_WEIGHT_TYPE: MAN_2D`, unsupported).
- For `EDGE_WEIGHT_TYPE: EXPLICIT`, a new required key `EDGE_WEIGHT_FORMAT` must be one of
  `FULL_MATRIX`, `UPPER_ROW`, `LOWER_ROW`, `UPPER_DIAG_ROW`, `LOWER_DIAG_ROW`; any other value
  errors with a message in the same style as the existing `EDGE_WEIGHT_TYPE` check.
- No new public types, traits, or enums are exported from the crate. All new machinery
  (`EdgeWeightType`, the per-type distance formula dispatch, the explicit-matrix reconstruction,
  the GEO coordinate parser) is `pub(crate)` or private to `vrp-scientific`. Tests interact only
  through `read_tsplib` and the standard, already-public `Problem` / solved `Solution` accessors
  (`transport`, `jobs`, and — after solving — route composition and cost) that the existing
  Solomon/Lilim tests already use.

## 4. Canonical output form

- **EUC_2D** (existing, unchanged): `round(sqrt(dx^2 + dy^2))` if `is_rounded`, else the raw
  float. Controlled by the caller-supplied `is_rounded` flag, exactly as today.
- **CEIL_2D**: `ceil(sqrt(dx^2 + dy^2))`, always — not conditional on `is_rounded`.
- **ATT** (pseudo-Euclidean): `rij = sqrt((dx^2 + dy^2) / 10.0)`; `tij = round(rij)`; result is
  `tij + 1.0` if `tij < rij`, else `tij`. Always applied — not conditional on `is_rounded`.
- **GEO**: each coordinate pair is interpreted as degrees-and-minutes (`DDD.MM`, i.e. the
  integer part is whole degrees and the fractional part is minutes, not decimal degrees),
  converted to radians as `PI * (deg + 5.0 * min / 3.0) / 180.0`. Distance is the standard
  TSPLIB great-circle formula with earth radius `RRR = 6378.388`:
  `q1 = cos(lon1 - lon2)`, `q2 = cos(lat1 - lat2)`, `q3 = cos(lat1 + lat2)`,
  `dij = floor(RRR * acos(0.5 * ((1.0 + q1) * q2 - (1.0 - q1) * q3)) + 1.0)`. Always integer by
  construction — not conditional on `is_rounded`.
- **EXPLICIT**: the `EDGE_WEIGHT_SECTION` is a whitespace-and-newline-separated stream of
  numbers (line breaks inside the section carry no meaning), read until the expected count for
  the declared `EDGE_WEIGHT_FORMAT` is reached, then expanded into a full `DIMENSION x
  DIMENSION` row-major matrix (mirrored for symmetry where the format stores only half).
  Distance between the customer with original TSPLIB id `i` and the customer with id `j` is
  `matrix[i-1][j-1]` — i.e. **matrix indices are the customer's original file id minus one,
  independent of the order customer lines appear in the file or the order jobs are
  constructed**. The depot's row and column are present in the matrix (matrix size always
  equals `DIMENSION`) even though the depot itself is never emitted as a job. Values are used
  exactly as parsed — no rounding, regardless of `is_rounded`.
- **Empty/edge input**: `DIMENSION: 1` (depot only, no customers) continues to produce a
  `Problem` with zero jobs for every edge weight type, exactly as it already does for `EUC_2D`.
- **Unsupported type**: an `EDGE_WEIGHT_TYPE` outside the five supported values still errors,
  in the existing message style (`"expecting one of 'EUC_2D', 'CEIL_2D', 'ATT', 'GEO',
  'EXPLICIT' as EDGE_WEIGHT_TYPE, got '<value>'"`).

## 5. Blind-spot pre-empts

None of the 10 bank entries in `DESCRIPTION.md` map directly onto this problem's domain
(sort order / adjacency / dedup / fixpoint iteration are not in play here). This problem's own
blind spots are pre-empted directly in §4's canonical-form sentences instead:
- The `is_rounded`-only-controls-EUC_2D sentence pre-empts the natural assumption that the flag
  is a single global on/off switch for "should distances be integers."
- The "matrix indices are the customer's original file id minus one, independent of ... order
  jobs are constructed" sentence pre-empts the natural (and, in this file, idiomatic) choice of
  building location indices by insertion order.
- The "used exactly as given, no rounding" and "full DDD.MM precision" sentences pre-empt reuse
  of the file's existing int-rounding numeric parser at the two new call sites that need float
  precision.

Codebase-inferable requirement count: 0 — every rule above is stated explicitly in §6, none is
left for the agent to infer from reading the source only.

## 6. Description draft (meta.md body, ~215 words)

Add support for TSPLIB CVRP instances whose EDGE_WEIGHT_TYPE is not EUC_2D to the
vrp-scientific reader. `read_tsplib` currently accepts only EUC_2D and returns an error for
every other value, so instances that ship a precomputed distance matrix or use one of TSPLIB's
other standard distance formulas cannot be loaded at all.

Extend the reader to also accept CEIL_2D (Euclidean distance rounded up), ATT (the
pseudo-Euclidean formula TSPLIB defines for its ATT-class instances), GEO (great-circle
distance between two points given as degrees-and-minutes coordinates), and EXPLICIT edge
weights supplied in an EDGE_WEIGHT_SECTION using whichever of the five standard
EDGE_WEIGHT_FORMAT layouts the instance declares: FULL_MATRIX, UPPER_ROW, LOWER_ROW,
UPPER_DIAG_ROW, or LOWER_DIAG_ROW.

For EXPLICIT instances, the distance between two customers is looked up from the parsed matrix
using each customer's original TSPLIB node id, independent of the order jobs happen to be
constructed in or the order customer lines appear in the file; the depot's row and column
remain part of the parsed matrix even though the depot itself is never emitted as a job.
Explicit weights are used exactly as given, with no additional rounding. GEO coordinates keep
their full DDD.MM precision rather than being rounded to the nearest whole degree. `is_rounded`
continues to control only the existing EUC_2D path; CEIL_2D, ATT and GEO always apply their own
defined rounding regardless of it.

## 7. File footprint

| Action | Path | Current raw | Raw delta | Meaningful (~0.65x) | Reason |
|--------|------|-------------|-----------|----------------------|--------|
| MODIFY | `vrp-scientific/src/tsplib/reader.rs` | 231 | +200 | ~130 | `EdgeWeightType` parse + dispatch; EXPLICIT matrix section reader (5-format reconstruction) + file-id-indexed job/location assignment (bypassing `CoordIndex.collect()`); GEO coordinate parsing (local float storage, bypassing the existing int-rounding parser) |
| MODIFY | `vrp-scientific/src/common/routing.rs` | 109 | +95 | ~65 | `EdgeWeightType` enum + per-type formula dispatch (`compute_edge_weight`); `create_transport_typed` (EUC_2D/CEIL_2D/ATT, reuses `CoordIndex.locations`); `create_transport_from_matrix` (EXPLICIT, wraps existing `SingleDataTransportCost::new` directly); `create_geo_transport` (GEO, operates on a local `&[(Float,Float)]` slice, does **not** change `CoordIndex`'s `(i32,i32)` field — keeps Solomon/Lilim untouched) |
| MODIFY | `vrp-scientific/src/common/text_reader.rs` | 168 | +25 | ~18 | `read_n_values` — a token-stream helper that accumulates whitespace-separated numeric tokens across `read_line` calls until a target count is reached (the `EDGE_WEIGHT_SECTION` block is not one-value-per-line) |

TOTAL: raw ≈ 320 / meaningful ≈ 213, across 3 modified files (0 new files).

**⚠️ LOC risk — flagged, not resolved.** 213 meaningful clears the 200 floor with only a thin
margin (~13 above floor, well short of the recommended 300+ buffer), and `TOO-EASY.md`'s own
law is that sketches this size routinely land 1.5-3x LOWER than sketched once the actual repo
machinery is reused more than expected (`canvas-fill-rule-backends`: 213 sketched -> 44 actual;
`customasm-asm-block-expr-substitution`: 318 sketched -> 167 actual). The likely absorption
point here: `SingleDataTransportCost::new(values: Vec<Float>)` already exists and does most of
the EXPLICIT path's real work — `create_transport_from_matrix` is a thin wrapper, not new
machinery, so the EXPLICIT capability's LOC is concentrated almost entirely in
`tsplib/reader.rs` parsing, which is exactly the part most likely to compress once written.
**Mandatory next step before writing any tests:** implement the solution first, run the
`effective_loc_check.py` hook against the actual diff, and only then write test.patch. If
`human-effective` lands under ~230, the documented fallback is to add `DISPLAY_DATA_SECTION`
handling (real TSPLIB instances sometimes carry a coordinate block purely for visualization
alongside an EXPLICIT matrix; it must be parsed and skipped without being mistaken for
`NODE_COORD_SECTION`) — a genuine, spec-real requirement, not padding, good for another ~30-40
raw LOC and a mild reinforcement of Trap 1 (a second place a coordinate-shaped section must be
correctly NOT used for cost lookup).

## 8. Solution outline — pure-function helpers

- `parse_edge_weight_type(&mut self) -> Result<EdgeWeightType, GenericError>` (reader.rs) ←
  §4 "five supported values" / §6 paragraph 2
- `compute_edge_weight(edge_type: EdgeWeightType, is_rounded: bool, x1, y1, x2, y2) -> Float`
  (routing.rs, pure function, one match arm per type) ← §4 per-type formula rules
- `to_geo_radians(coord: Float) -> Float` (routing.rs, pure function: DDD.MM -> radians) ←
  §4 GEO formula, §6 "full DDD.MM precision"
- `read_edge_weight_section(&mut self, format: EdgeWeightFormat) -> Result<Vec<Float>, GenericError>`
  (reader.rs) ← §4 EXPLICIT / five `EDGE_WEIGHT_FORMAT` layouts; internally dispatches to one
  reconstruction function per format (all pure, taking the flat parsed token stream + dimension,
  returning the expanded `DIMENSION x DIMENSION` row-major matrix)
- `read_n_values(count: usize, reader, buffer) -> Result<Vec<Float>, GenericError>`
  (text_reader.rs, pure/stateful-only-on-buffer) ← §6 "EDGE_WEIGHT_SECTION ... using whichever
  ... layout"; token-stream-across-lines primitive, does not exist today
- `create_transport_typed` / `create_transport_from_matrix` / `create_geo_transport`
  (routing.rs) ← §4, one per input shape (coordinates+formula / precomputed matrix / geo
  coordinates), each a thin, pure wrapper around `SingleDataTransportCost::new`

No fixpoint loop applies (no iterate-to-convergence requirement in this feature). No
cycle-trace/recursive-AST pattern applies (flat parsing, not tree traversal).

## 9. Test file outline

Path: `vrp-scientific/tests/unit/tsplib/reader_test.rs` (existing file — TSPLIB reader tests
already live here via the `#[path = "../../tests/unit/tsplib/reader_test.rs"] mod reader_test;`
inline-test-module pattern at the top of `reader.rs`; see §10/F-12 note below).

Block 1 — Imports: `crate::tsplib::reader::*`, `vrp_core::models::*` accessors used by the
existing Solomon/Lilim reader tests (same style).

Block 2 — Builder helpers (10-20 one-liners): `tsplib_header(edge_type: &str, dimension: usize)
-> String`, `node_coord_line(id, x, y) -> String`, `demand_line(id, demand) -> String`,
`explicit_section(format: &str, values: &[i32]) -> String`, `geo_coord_line(id, deg_min_x,
deg_min_y) -> String`, `full_tsplib_instance(...)` composing a complete valid file per edge type.

Block 3 — Assertion helpers: `assert_distance(problem: &Problem, from_customer_id: usize,
to_customer_id: usize, expected: Float)` (looks up `problem.transport.distance_approx` between
the two customers' assigned locations); `assert_read_error(input: &str, expected_substring:
&str)` (substring match, not exact string).

Block 4 — Tests grouped by requirement bucket:
- **CEIL_2D / ATT / GEO formula correctness** (~8-10 tests): one or two known-good distance
  pairs per type (values computable by hand / cross-checked against the TSPLIB reference
  formula), plus a `EUC_2D` regression test confirming the existing path is untouched.
- **EXPLICIT format-variant parity** (~10-12 tests, F-18-style): the SAME small instance (4-5
  customers + depot) encoded once per `EDGE_WEIGHT_FORMAT` (`FULL_MATRIX`, `UPPER_ROW`,
  `LOWER_ROW`, `UPPER_DIAG_ROW`, `LOWER_DIAG_ROW`), asserting identical resulting distances
  across all five encodings of the same underlying matrix — every format tested, not just the
  salient/obvious one (`FULL_MATRIX`).
- **Identity/index-integrity — Trap 1, the lead trap** (~4-6 tests): an EXPLICIT instance whose
  `NODE_COORD_SECTION`-equivalent customer/demand lines are listed in NON-ascending file-id
  order (id 3 before id 1, etc.), asserting exact distances that are only correct if matrix row
  `k` always means "customer with original file id `k+1`" regardless of parse/construction
  order. A second test with depot id in the MIDDLE of the id range (not first, not last) —
  this is the §11b off-diagonal cell (see below).
- **Precision preservation — Trap 2** (~4 tests): an EXPLICIT matrix containing at least one
  non-integer value (e.g. `12.5`), asserting the parsed distance is exactly `12.5`, not `13` or
  `12`; a GEO instance whose coordinates have a non-zero minutes component (e.g. `38.24` meaning
  38°24', not 38.24 decimal degrees), asserting the computed distance matches the full-precision
  formula, not one computed from `38.0`.
- **Error handling** (~4-5 tests): unsupported `EDGE_WEIGHT_TYPE`, missing `EDGE_WEIGHT_FORMAT`
  when type is `EXPLICIT`, unsupported `EDGE_WEIGHT_FORMAT` value, wrong value count in
  `EDGE_WEIGHT_SECTION` (too few / too many) — all substring-matched against the existing
  error-message style, never exact-string.
- **Edge cases**: `DIMENSION: 1` (depot only) for at least EXPLICIT and one computed type;
  end-to-end solve-and-check-cost test for at least one EXPLICIT instance (not just raw
  distance lookups) confirming the transport cost model is actually wired into a real solve,
  matching the existing Solomon/Lilim reader tests' end-to-end style.

Estimated total: ~35-45 tests (D-change historical anchor is 102; this problem is narrower in
scope than a full D-change so a proportionally smaller suite is appropriate — final count is
coverage-driven, not anchored to that number).

5-axis coverage check:
- ✓ every described atom in §6 (5 edge weight types, 5 EDGE_WEIGHT_FORMAT layouts, the
  is_rounded-scoping rule, the file-id-indexed lookup rule, the no-rounding-on-EXPLICIT rule,
  the full-precision-GEO rule)
- ✓ every public API surface (`read_tsplib` — success and error paths)
- ✓ every solution branch (one test path per `EdgeWeightType` match arm, one per
  `EDGE_WEIGHT_FORMAT` match arm)
- ✓ standard edge cases (empty/`DIMENSION: 1`, boundary depot-position, malformed section)
- ✓ stated inverse — n/a (no explicitly asymmetric X-happens-when-Y rule beyond what's already
  covered by the is_rounded-scoping tests)

## 10. Forced trait bounds / generics / kwargs

None — this is plain parsing + free-function dispatch, no new generics, closures, or trait
bounds are forced by the design.

**F-12 audit (mandatory for Rust, done):** `tsplib/reader.rs` carries an inline `#[cfg(test)]
mod reader_test` (via the `#[path = ...]` pattern) whose tests call the reader's private helper
methods indirectly through `TsplibProblem::read_tsplib` (the public trait method), not through
any other private fn directly. No private helper this feature renames or restructures
(`read_meta`, `read_customer_data`, `read_depot_data`, `read_key_value`, `read_expected_line`,
`read_line`, `skip_lines`, `create_job`) is called directly by an existing test — existing tests
go through `read_tsplib` only. **Decision: base mode keeps every existing TSPLIB reader test
intact; none are skipped.** No F-12 axis is expected on this file; will re-verify once the
actual diff is written (methods DO get restructured — `read_meta` gains the
`EDGE_WEIGHT_FORMAT` branch, `create_job`'s location-assignment gets a conditional path — so
re-check after implementation that no existing test asserted internal call structure rather
than `read_tsplib`'s output).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in §6) | Test that catches it |
|---|------|------|----------------|-------------------|----------------------|---------------------|------------------------------|------------------------|
| 1 | File-id-indexed matrix lookup vs. this file's own HashMap-based, order-agnostic customer collection + `CoordIndex.collect()` sequential-append idiom (used everywhere else in this exact file) | F-9 (cross-stage resolution: the "natural" place to resolve node-id→location, `CoordIndex.collect()`, computes the wrong resolution for this one path) | S4 (machinery-riding integration) / A3-adjacent (reuse-the-machinery, wrong arm) | identity/index integrity | #3 (a wrong index mapping corrupts every `EDGE_WEIGHT_FORMAT` reconstruction test identically — one root cause, many failing capabilities) | The established idiom in this exact file is `self.coord_index.collect(location)` for every job's location; reusing it for EXPLICIT is the locally-consistent, natural choice, and it silently produces a scrambled (or HashMap-iteration-order-dependent) row/col mapping instead of the file-id-based one EXPLICIT requires | "distances ... looked up ... using each customer's original TSPLIB node id, independent of the order jobs happen to be constructed in or the order customer lines appear in the file" | non-ascending-file-order EXPLICIT fixture (§9 bucket "Identity/index-integrity") |
| 2 | Reusing the existing `parse_int` (rounds to nearest integer) at the two new call sites that need float precision preserved: EXPLICIT matrix values, GEO DDD.MM coordinates | none yet (candidate pattern; will promote to a workspace F-id after a 2nd confirmed kill on a future problem) | A5/A6-adjacent (naive-dominant-reading / second-op narrow-guard: the established numeric-parsing idiom is right for 3 of 5 numeric call sites in this file and wrong for these 2) | numeric precision | — (independent of #1 and #3) | `parse_int` is the only numeric parser this file has ever needed (DIMENSION, CAPACITY, coordinates, demand are all conventionally-integer TSPLIB fields); reaching for it again for the two new float-sensitive fields is the path-of-least-resistance, repo-consistent choice | "Explicit weights are used exactly as given, with no additional rounding" / "GEO coordinates keep their full DDD.MM precision rather than being rounded to the nearest whole degree" | non-integer EXPLICIT value + non-zero-minutes GEO coordinate (§9 bucket "Precision preservation") |
| 3 | `EDGE_WEIGHT_FORMAT` cross-product with depot position (F-10 off-diagonal cell) | F-10 (capability cross-product) | S2 (composition of documented rules — both axes, format and depot presence-in-matrix, are separately stated in §6) | format-layout x depot-position | #1 (shares the same underlying index-mapping machinery; a correct format decoder still fails this cell if #1's fix is wrong, and a fixture built to catch #1 with depot-in-the-middle is exactly this cell) | Every natural self-test an agent writes for "does my format decoder work" will construct depot as the first (or last) customer id, matching every other format in this same file (Solomon/Lilim both treat depot as customer 0/1) and matching the common convention in most public TSPLIB CVRP instances; a depot placed mid-range in the id space is not a shape agents self-test around (`failure-patterns.md` P3) | both axes independently stated in §6 (five `EDGE_WEIGHT_FORMAT` values; depot row/col "remain part of the parsed matrix ... even though the depot itself is never emitted as a job") — the cell needs no new sentence | depot-in-the-middle EXPLICIT fixture, non-`FULL_MATRIX` format (§9 bucket "Identity/index-integrity", second test) |

CONTRACT-STATED/FIX-HIDDEN check for Trap 1 (the lead trap, done): the §6 sentence states WHAT
("looked up ... using each customer's original TSPLIB node id, independent of the order jobs
happen to be constructed in") and never says HOW (never mentions `CoordIndex`, `collect()`,
`HashMap`, or "do not use the existing location-indexing helper"). The fix — building a
location/matrix-index array by direct `file_id - 1` mapping instead of sequential append — is a
discovery orthogonal to the stated requirement, matching HARDENING's "alive by construction"
pattern (repo-internals discovery, same shape as participle's snapshot-the-shared-parent fix).

## 11b. Capability cross-product matrix (F-10)

Axis 1 (multiplicity-shaped): `EDGE_WEIGHT_FORMAT` — `FULL_MATRIX` / `UPPER_ROW` / `LOWER_ROW`
/ `UPPER_DIAG_ROW` / `LOWER_DIAG_ROW`.
Axis 2 (polarity/boundary-shaped): depot's original TSPLIB id relative to the customer id
range — **first** (id 1, or lowest id) vs **interior/last** (anywhere else in `1..=DIMENSION`).

| | depot = first id | depot = interior/last id |
|---|---|---|
| **FULL_MATRIX** | test: basic correctness (likely self-tested) | test: off-diagonal — depot-interior, simplest format |
| **UPPER_ROW / LOWER_ROW / UPPER_DIAG_ROW / LOWER_DIAG_ROW** | test: format-decoding correctness (likely self-tested for at least one triangular form) | **test: REQUIRED off-diagonal cell** — depot-interior with a non-trivial triangular reconstruction (e.g. `LOWER_DIAG_ROW`); this is §9's "second test" in the Identity/index-integrity bucket and Trap-matrix row 3 |

Both axes are already stated in §6 (the five format names; "the depot's row and column remain
part of the parsed matrix ... even though the depot itself is never emitted as a job") so the
off-diagonal cell costs test lines only, no new description words.

Scope audit: `EDGE_WEIGHT_FORMAT` is not a recursive/nested construct (F-11 does not apply — no
sub-part-within-sub-part selection scope here).

Format-noun audit (L24): the only format-defined noun this problem introduces is
`EDGE_WEIGHT_SECTION` itself — its extent is stated precisely in §4/§6 ("a
whitespace-and-newline-separated stream of numbers ... read until the expected count for the
declared EDGE_WEIGHT_FORMAT is reached"), so there is no header-vs-row ambiguity of the
rust-minidump F-13 kind to pre-empt here.

Tolerance-fixture audit (L25): no "allow one, stop at the second" rule exists in this feature;
F-15 does not apply.

Wrong Logic % constraint: predicted well under 25% — see §13.

## 12. Tier + category decision

- Tier: Olympus (single tier, 2026-07 sprint)
- Sub-rank: Okay-to-Good (213 meaningful LOC is thin against the 300+ design target; see §7 risk
  note — sub-rank depends on the actual build-measure result, not the sketch)
- Category: **feature-request** (title verb "Add"; net-new capability — the crate could not
  previously read these instance types at all, this is not a fix to existing broken behavior)

## 13. Predicted Nova pass rate

- Predicted: 15-30%
- Reasoning: one S4/F-9-style lead trap (Trap 1) that is repo-internal (not derivable from the
  public TSPLIB spec, which only defines the matrix-format math, not this repo's own
  location-indexing convention) — expected to carry most of the difficulty, in the 40-60% kill
  range based on the closest analog in `failure-patterns.md` (F-9 measured 60% on neva, though
  that problem's stage-boundary shape is not identical to this one's single-file idiom-reuse
  shape, so treating this as a moderate-confidence estimate, not a direct transfer). Trap 3 (the
  depot-position off-diagonal cell) is interdependent with Trap 1 and is not expected to add
  much beyond it per L16 ("one test usually decides the band"), but exists for fairness/FP
  coverage per F-10's "author this in every problem with two axes" rule. Trap 2 (precision
  reuse) is a narrower, single-call-site slip, more B-tier-adjacent — expected to contribute a
  modest independent kill rate (~10-20%) without dominating.
- Two real risks pull toward the too-easy end: (a) CEIL_2D/ATT/GEO's formulas ARE spec-knowable
  (a competent solver derives them correctly from training knowledge — same domain class as
  `cfn-guard-cidr-operator`'s CIDR math), so if Trap 1 turns out weaker than expected in a real
  batch, the whole problem could read closer to 50-60%; (b) if the actual LOC/complexity comes
  in as thin as §7's risk note fears, the feature may also be simpler to reason about end-to-end
  than the sketch suggests, which could also push the rate up.
- Sanity check: predicted range sits under the 40% ceiling with room; if a real batch reads
  above 40%, the diagnosis should start with Trap 1 (was the index-mapping idiom actually
  followed by agents, or did most agents happen to build jobs in ascending file-id order
  naturally, e.g. because `HashMap` iteration order was accidentally stable for small maps in
  their runs — HARDENING 3c step 1, "read the passers"). If a real batch reads 0%, the fairness
  classification table in HARDENING 3c-bis applies; the disclosure lever (naming the root cause,
  e.g. "resolve the customer-to-matrix mapping using the file's own id numbering, not
  construction order" — closer to naming the fix) would be the documented escape hatch.

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 in Phase 1 (architecture, 5 subsystems, entanglement zones, test
      framework, template test file all identified during the olympus-hunt handoff + this
      session's code reading)
- [x] Existing PR check: 0 hits — `gh pr list -R reinterpretcat/vrp --state all --search
      "tsplib"` / `"explicit"` / `"edge weight"` / `"EDGE_WEIGHT"` / `"scientific"` all empty or
      unrelated (Python build PR only); `gh issue list` hits (#132 "custom costs matrix", #6
      "Failed with Distance Matrix") are both about `vrp-pragmatic`'s existing JSON
      custom-matrix feature, not `vrp-scientific`/TSPLIB — confirmed by reading both issues in
      full, no overlap with this pick
- [x] Closest approved problem opened side-by-side — none in this workspace touches a
      scientific/benchmark-format reader; nearest shape analogs by mechanism only (neva's F-9
      stage-boundary shape) referenced directly in §11/§13, not literally opened side-by-side
      (no closer match exists in `approved-problems/`)
- [x] Title: verb-led, 5-10 words ("Add TSPLIB non-Euclidean edge-weight-type support..." — 8
      words), names specific subsystem (CVRP scientific reader)
- [x] Shape declared with SHAPES.md citation (§2)
- [x] Public API surface lists every name tests will assert — deliberately kept to one
      unchanged public signature (§3)
- [x] Canonical output form spelled out: all 5 formulas, is_rounded scoping, matrix indexing
      rule, precision rules, empty-input behavior, unsupported-type error (§4)
- [x] 0 codebase-inferable requirements (§5)
- [x] Description draft: ~215 words, under the 500 hard cap, plain prose, no headers (§6)
- [x] Description draft: no `##` headers, no formulaic labels, no `Box<>`, no code-instead-of-prose
- [x] File footprint sketched against real source (current line counts read directly from the
      repo) (§7)
- [ ] **Raw and meaningful LOC clear the current floor with a comfortable buffer** — sketched at
      213 meaningful against a 200 floor, ONLY a thin margin, NOT the recommended 300+ buffer.
      **Explicitly left unchecked.** Flagged as the top open risk in §7 with a documented,
      concrete fallback (DISPLAY_DATA_SECTION handling) and a mandatory build-then-measure gate
      before any test is written.
- [x] Solution outline: 1+ pure-function helper per behavior named in §6 (§8)
- [x] Fixpoint loop / cycle-trace pattern — correctly absent (neither applies to this feature)
- [x] Test file outline: 4-block layout, scenario-encoded test names (§9)
- [x] 5-axis test coverage planned (§9)
- [x] Forced trait bounds / kwargs — correctly none; F-12 audited (§10)
- [x] 3 named traps, each with pre-empt sentence + catching test (§11)
- [x] Trap 1 and Trap 3 name F-ids from `failure-patterns.md` (F-9, F-10); Trap 2 is explicitly
      flagged as an UNCONFIRMED candidate pattern per the C-id convention, not claimed as a
      proven F-id
- [x] Traps sit on different axes (identity/index vs. numeric precision vs. format x depot
      cross-product); Trap 1 and Trap 3 are explicitly interdependent (§11)
- [x] § 11b cross-product matrix filled in, off-diagonal cell has a required test (F-10)
- [x] Form-parity audit (F-18): all 5 `EDGE_WEIGHT_FORMAT` layouts tested, not just the salient
      `FULL_MATRIX` one (§9 bucket "EXPLICIT format-variant parity")
- [x] Format-noun extents stated (§11b) — `EDGE_WEIGHT_SECTION`'s extent is fully specified, no
      L24-style ambiguity
- [x] No tolerance rule exists — L25 audit correctly not applicable
- [x] Predicted Wrong Logic well under 25% (§11b)
- [x] Predicted Nova pass rate 15-30%, under the 40% ceiling (§13)
- [x] Category matches description: feature-request / "Add" (§12)
- [x] Feature is NOT pattern-followable — Trap 1 is a genuine, repo-internal discovery, not a
      template the agent can copy from 3+ existing examples in the file
- [x] Feature is NOT in `RULES.md § Features already used` / `TOO-EASY.md` / `rejected/` — no
      TSPLIB, scientific-format, or vrp pick exists anywhere in this workspace's history

## Why this is not a duplicate

No prior pick in `approved-problems/`, `problems/`, or `rejected/` touches `reinterpretcat/vrp`
or any VRP/vehicle-routing metaheuristic solver at all — this is the first pick against this
repo and this domain in the workspace. The closest approved problems by MECHANISM (not domain)
are `neva-array-bypass-generalization` (F-9 cross-stage resolution drop, cited directly in §11
row 1 and §13) and `rust-minidump-stack-containment` (F-13/format-parsing style, informing the
format-noun-extent audit in §11b) — both cited as evidence sources, neither as a subsystem or
capability overlap. `reinterpretcat/vrp`'s own open-PR/issue surface (checked in full during the
olympus-hunt handoff and re-checked with TSPLIB-specific keywords in this session) shows zero
engagement with `vrp-scientific` or any scientific/benchmark-format capability — the two
superficially-adjacent issues (#132, #6) are both about `vrp-pragmatic`'s unrelated JSON
custom-matrix feature.

## Predicted iteration cycles: 2

Target 1; realistically 2 given the explicitly-flagged, unresolved LOC risk in §7 — the first
real cycle is "build the solution, measure, and confirm or widen scope (DISPLAY_DATA_SECTION
fallback) before tests are written," which is design-completion work more than review-response
iteration, but is being counted honestly as a cycle rather than assumed away.
