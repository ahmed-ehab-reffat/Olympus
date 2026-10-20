# DESIGN.md - qq-typed-binary-schema

Repo: JFryy/qq (canonical, no move; 740 stars; MIT; Go 1.25). Base 321eba7b1db4f42f7bd351e020f8e0fae6b0c354
(main HEAD 2026-10-12). Hunt: REPO-HUNT-2026-10-06-B RANK 1, dossier
`worktrees/_hunt/s_1006h60/dossier_qq_h60.md`.

## Phase 1 - repo understanding

- **Architecture (one paragraph).** qq is a jq-style CLI over many formats. `cli/qq.go` reads a file or
  stdin, picks input and output codecs from flags or the file extension, decodes the input into a
  generic Go value (`map[string]any`, `[]any`, `int`, `float64`, `string`, `bool`, `nil`) through
  `codec.Unmarshal`, runs a gojq query over it, and encodes every query result with `codec.Marshal`;
  binary outputs (parquet, msgpack, cbor, avro) are written raw to stdout. `codec/codec.go` is a
  registry (`Codecs` map of Unmarshal/Marshal function pairs per `EncodingType`); every format lives
  in its own package under `codec/`; `codec/util` holds shared normalisation (`ParseValue`,
  `NormalizeNumbers` from #72, which turns sized ints into the `int`/`float64` gojq accepts);
  `codec/stream.go` is the `--stream` path; `internal/tui` is the interactive mode.
- **Five subsystems.** (1) cli: flags, input reading, query execution, slurp/stream modes.
  (2) codec registry + Marshal/Unmarshal wrappers + `IsBinaryFormat`. (3) per-format codecs
  (json/yaml/toml/hcl/xml/csv/... and the two binary record codecs avro (hamba/avro v2.31 OCF) and
  parquet (apache arrow/go v16 pqarrow)). (4) codec/util shared value helpers. (5) internal/tui.
- **Entanglement zones.** (a) number representation: JSON decode keeps ints as `int` (#72), gojq needs
  `int`/`float64`/`*big.Int`, binary decoders return sized types (`int64`), and two codecs normalise
  through a JSON round trip (avro both directions, parquet read). (b) `cli.executeQuery` marshals each
  query result separately, so a binary output gets one file per emitted value. (c) per-codec JSON round
  trips (avro.go:43-55 and :34-38, parquet.go:163) that silently change types.
- **Test framework.** Go `testing`, in-package `*_test.go` beside the code (`codec/parquet/parquet_test.go`,
  `codec/codec_test.go`, `cli/*_test.go`); plus `tests/test.sh`, a shell conversion matrix that needs
  `jq` and `bin/qq` (not in the base image; not part of base mode, see section 9).
- **Template test file.** `codec/codec_test.go` (`TestAvroRoundTrip`, `TestCBORRoundTrip`:
  `Marshal(original, AVRO)` then `Unmarshal(encoded, AVRO, &decoded)` and compare).

## Phase 2 - existing-PR / publicly-solved check (run 2026-10-13 on current main)

```
gh api repos/JFryy/qq -q .full_name                      # JFryy/qq, no move
gh pr list/issue list -R JFryy/qq --state all --search X for X in:
  parquet avro schema "schema inference" infer nested typed int64 arrow "record type" nullable union
  "data loss" precision
```
Hits: PR #72 (merged; parquet column ORDER sort + util/numbers.go; diff read: parquet.go +3/-1 only),
PR #38 (codecs added), PR #52/#53 (closed, key order; parquet.go +2/-2 ordering only), PR #55/#56
(open; codec.go/util/order.go/utils.go, key order and no-auto-convert, no avro/parquet hunks),
issue #71 (closed, parquet output order), issue #70 (closed by #72, JSON-family int precision; avro not
in its file list), **issue #67 (OPEN, maintainer roadmap)**. No PR touches typed schemas, nested
avro/parquet values, or the readers. Every open PR's file list was pulled; none touches codec/avro or
codec/parquet beyond the ordering lines above.

**Issue #67 overlap (tracker-named check, asked for by the orchestrator).** #67 has ONE bullet in this
lane: "avro converts through float64 internally (codec/avro/avro.go Unmarshal and Marshal), so integers
above 2^53 lose precision." It does not name schema inference, all-record columns, nested types,
nullability, mixed kinds or anything in parquet. Our lane's core (cross-record schema merge kernel, typed
nested parquet, avro union handling) is not tracker-named; one sub-part (avro int precision, ~15-25 eff
of ~350) is. Verdict: PARTIAL tracker overlap, MEDIUM risk. A rival working #67 as a "codec data loss"
task would overlap our avro Marshal/Unmarshal JSON-round-trip removal only. The platform precheck on
this slice is the instrument that decides it (Step 4b). Recorded as risk R1 below.

Sibling crib (from the hunt, not re-run): yq, dasel, gojq, miller have no avro/parquet writer;
arrow-go `arreflect` infers from static Go types only and is not in qq's module graph; bodkin (19 stars)
infers arrow schemas from maps, no avro, no read-back. Not a crib kill.

Dedup vs our pool: `ls new-problems problems rejected approved-problems | grep -iE 'qq|avro|parquet|schema'`
and a grep of every meta.md for parquet/avro: only planetiler-custommap-schema-composition and
ytt-library-schema-compatibility match the word "schema"; neither is this feature class. qq is not in
SATURATED-REPOS.md. Our count on the repo: 0.

## Phase 3 - candidate pick

The hunt's lane table already killed every other qq lane (key order: PR #55 diff; auto-detect: PR #61
signature account; no-auto-convert: PR #56; new codecs and empty/null fidelity: maintainer roadmap
#67/#68; YAML keys: <200 + open bug #73 with PR #74; --stream fidelity and jq parity: absorption <200;
HCL attribute lists: #67 bullet). Only typed-binary-schema survives.

TOO-EASY guard on the survivor:
1. Uniform-wrap? No. Inference/merge kernel, two writers with different type systems, two readers, a
   library union convention on the avro side, and the query engine's type domain on the read side.
2. Single-subsystem mechanical transform? Codec subsystem, but the walls are hidden integrations the
   transform does not state: hamba's map-union wrapper (encode and decode), arrow nested builders, the
   gojq number domain the readers feed. Those are discoveries, not spec lines.
3. Hardness depends on the spec not stating something? No. Every rule is stated; the fixes live in
   library internals and in the read path's type domain (CONTRACT-STATED / FIX-HIDDEN).
4. Port of a memorised spec? Schema inference is a known idea (Spark, pandas), and the merge rulebook
   itself will be transcribed (L58). The band must come from the integration cells, not the rules.
5. Survives full spelling-out? Yes for the integration walls.
Pointwise-decoupled? No: one merged shape drives schema, conformance, union wrapping and read-back;
nullability decided by the merge decides whether the avro wrapper applies.
Missing-arm / machinery-absorbed? No primitive in the repo infers schemas; the hunt's written sketch
measured 350 human-effective (hook), the kernel alone ~157.
Tracker-named / famous-feature magnets: see Phase 2 (partial, MEDIUM).

Arsenal class of the lead trap: S4 machinery-riding (the avro union machinery of the library the codec
already uses) plus F-2 bidirectional seam; second lead: A4 host-semantics (gojq number domain) as an
F-9 cross-stage drop. Candidate table:

| Candidate | Behaviour | Shape | Files | Raw | Meaningful | Nova | Verdict |
|---|---|---|---|---|---|---|---|
| typed-binary-schema | all-record typed nested schema, exact readers | O-Composite-extend | 3 mod + 1 new | ~430 | ~350 (hook, sketch) | 0/8 hoped | PICK |
| + one file per query (FINISH lever) | several query results into one avro/parquet file | cli wiring | +1 | ~40 | ~25 | - | second lever, FINISH only |
| (dead lanes above) | | | | | | | killed by hunt |

## 1. Title
Add typed nested schemas to the avro and parquet codecs

## 2. Shape classification
- Shape: O-Composite-extend (refactor an existing aggregation across packages: the two binary record
  codecs onto one shared inference kernel). Closest Mars precedent: A2 (concentrated + behaviour change).
- Pass target (2026-10-09 gate): Nova 0/8, Orion 1/4.
- Best agent: Orion-alone.
- Dominant verdict: MISSED_REQUIREMENT on cross-product cells, plus REGRESSION on the gojq number domain.

## 3. Public API surface
No new symbols. Tests call only base API, so no compile-wipe risk (C-5):
- `codec.Marshal(v, codec.AVRO)` / `codec.Marshal(v, codec.PARQUET)` - new typed behaviour.
- `codec.Unmarshal(b, codec.AVRO, &v)` / `codec.Unmarshal(b, codec.PARQUET, &v)` with `v any` - exact values.
- CLI `-o avro|parquet`, `-i avro|parquet` (FINISH: several query results into one file).
Tests inspect the written files with hamba/avro `ocf` (writer schema) and arrow `pqarrow` (arrow
schema), both already in go.mod.

## 4. Canonical output form
- Records: an array of objects (one record each) or a single object (one record); empty array, non-object
  element or any other value = error.
- Columns: union of keys over all records, ordered by name (as today).
- Kinds: bool -> boolean; integer (a number qq reads as an integer; 2.0 in JSON is a float) -> 64-bit int
  (avro long, parquet int64); float -> double; string -> string; object -> nested record (struct) with the
  same rules over every object in that position; array -> list with the same rules over every element of
  every array in that position.
- Merge: int + float -> double (ints written as doubles); any other mix -> string column holding each
  value's JSON text, strings included (`"x"` stored as `"\"x\""`).
- Nullability: null or missing in some record (or some element, for lists) -> nullable; present and
  non-null everywhere -> not nullable; all-null column -> nullable string. Null stays null in every kind
  of column (never the text "null").
- Read side: ints as Go `int` (gojq domain) exact over the int64 range, doubles as `float64`, records as
  `map[string]any`, lists as `[]any`, at every depth; missing keys read back as null.
- Domain caps: nested objects always have at least one key; keys are always valid avro names.

## 5. Blind-spot pre-empts
- pipeline-placement: "These values have to behave in jq expressions just like the same values read from
  JSON." (the one codebase-inferable requirement: #72 NormalizeNumbers documents the gojq domain).
- falsy-on-invalid: the error cases are listed once.
- result-ordering: not needed (records keep input order; columns by name are invisible after read-back).

## 6. Description draft
See meta.md (slice draft). First-person plural register (CLAUDE.md 2026-09-30), one line per paragraph
(memory: hard wrap is an AI tell), ASCII only. ~300 words.

## 7. File footprint (sketched in real code by the hunt, rebuilt here)
| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| NEW | codec/util/shape.go | - | ~210 | ~157 | shape kernel: records, shapeOf, merge, conform |
| MODIFY | codec/avro/avro.go | 138 | ~+150/-90 | ~100 | schema emission, union wrapping, schema-driven unwrap, exact read |
| MODIFY | codec/parquet/parquet.go | 168 | ~+120/-70 | ~93 | arrow type mapping, recursive builders, recursive exact read |
| MODIFY (FINISH) | cli/qq.go | 445 | ~+40 | ~25 | collect query results into one binary record file |
TOTAL slice ~350 meaningful over 3 files (hook on the hunt sketch); FINISH target >= 380.

## 8. Solution outline
- `util.Records(v)` <- record set rule.
- `util.InferShape(records)` / `shapeOf` / `mergeShapes` <- kinds, merge, nullability.
- `util.Conform(v, shape)` <- value conversion (int64, int->float64, JSON text for mixed, nulls kept).
- avro `avroType(shape, names, nullable)` <- schema emission with unique record names.
- avro `wrapUnions(value, shape, inUnion)` <- hamba map-union convention for record/array branches.
- avro `unwrap(value, schema)` + `util.NormalizeNumbers` <- schema-driven unwrap, gojq domain.
- parquet `arrowType(shape)` / `appendValue(builder, shape, v)` <- typed nested columns.
- parquet `arrowValue(column, i)` + NormalizeNumbers <- exact recursive read.
- readers assign `*any` targets directly; other targets keep the JSON fallback (existing typed-target tests).

## 9. Test file outline
- New file `codec/binary_schema_<hex>_test.go`, package `codec`, helpers suffixed with the hex (memory:
  go-test-helper-name-collision).
- Superseded cases in `codec/parquet/parquet_test.go` (string asserts in TestBasicParquetMarshalUnmarshal,
  TestNilValueHandling, TestLargeDataSet; the single-object error half of TestInvalidInputTypes) are
  removed there and re-asserted, typed, in the new file (skill: move superseded cases into the new file,
  leave the original in base mode).
- test.sh base: `go test ./...` with the new file removed through `-overlay` (no `-skip`, memory:
  gate false ERROR). new: `go test -run '^TestBinarySchema' ./codec/`. `tests/test.sh` is not run (needs
  jq + bin/qq; the conversion matrix skips most avro/parquet pairs anyway).
- Buckets: avro typed round trip; parquet typed round trip; all-record columns + missing; nullability
  (schema and values); merge int+float, mixed JSON text, null in mixed; nested records and lists at depth;
  big ints at every path; gojq query over decoded values; record-set errors; moved parquet cases.
- SLICE (Step 4b) ships only the core subset (about 10 tests); the cross-product cells are FINISH.

## 10. Forced bounds
Readers must put gojq-acceptable types into `*any`: `int` not `int64` (gojq rejects sized ints, issue #70).
Typed targets (`*[]map[string]any`) used by existing tests keep the JSON fallback.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | hamba map-union wrapper: a `map[string]any` in a `["null", record]` field is read as a union wrapper; error names a USER key ("unknown union type x") | F-2 encode | S4 | avro encode of nullable nested values | #3 (nullability decides wrapping) | agents test the all-present shape (P3) | "A key that is null or missing in some record makes that column nullable" | nullable nested record / list of nullable records round trip |
| 2 | decode returns `{"Record1": {...}}` for nullable records; must unwrap by schema, never by "one-key map" heuristic | F-2 decode | S4 | avro decode | #1 | the wrapper key is the record name the agent chose | "nested records as objects ... at every depth" | required one-key nested object whose value is an object; nullable twin |
| 3 | merge decides nullability decides wrapping; required vs nullable | F-10 | S2 | schema nullability | #1, #2 | base made EVERY field nullable; agents keep that or drop it everywhere | "present and non-null in every record is not nullable" | schema checks on required + nullable fields, nested |
| 4 | readers leak `int64` (or round trip through JSON): identity output looks right, queries panic or lose precision | F-9 | A4 | reader -> query engine | #5 | `qq -i avro .` passes; only arithmetic/comparison shows it | "behave in jq expressions just like the same values read from JSON" | gojq query over decoded values; 2^53+1 at nested/list positions |
| 5 | writer JSON round trip turns ints into float64 before inference (avro.go:43-55); readers' JSON round trips | F-9 | S3 | numeric precision | #4 | the existing normalisation looks like plumbing | "integers ... no loss across the whole 64-bit range" | big ints in avro and parquet, nested |
| 6 | avro named types must be unique: naming records by key collides when a key repeats at two depths | guess (unmeasured) | A-tier host semantics | schema validity | #1 (names are the wrapper keys) | key-named records look natural | none needed (valid file is implied) | same key name at two depths with different shapes |
| 7 | mixed column: strings included as JSON text, null stays null | F-10 | A5 naive reading | mixed kind | #3 | json.Marshal(nil) = "null"; strings passed raw | "strings included" / "A null stays null" | mixed with null; mixed nested in list |
| 8 | 2.0 is a float, not an int | A9-ish | A5 | kind decision | #7 | whole-number check | "2.0 in JSON input is a float" | double column from whole floats |

All rows name an axis; rows 1-3 and 4-5 are interdependent pairs. Row 6 is a guess, flagged.

## 11b. Cross-product matrix (F-10)
Axes: container (scalar / record / list) x nullability (required / nullable) x codec (avro / parquet).
| | required | nullable |
|---|---|---|
| scalar | slice | slice |
| record | slice | slice (wrapper) |
| list | FINISH | FINISH (list nullable + list of nullable records) |
| record in list in nullable record | FINISH | FINISH |
Second pair: merge kind (int+float / mixed / plain) x position (top / nested / list element): plain top
and nested in slice; merge at nested and list-element positions in FINISH.

Format-noun audit: "record" = one top-level object (and a nested object's avro record); "column" = a
top-level key. Stated in meta. Example audit: `2.0` and `"x"` examples are rules, not scope.

## 12. Tier + category
Olympus, feature-request (title "Add ...").

## 13. Predicted per-agent result
Nova 0/8 (too many cross-product cells across two codecs plus the gojq domain; Nova ships plausible
identity-tested code). Orion 1/4 is a guess; the union wrapper and gojq domain are loud once probed,
so the FINISH cells decide it. Nova sequence length: hamba and arrow internals in the module cache are
the reading surface; expect one compaction (L116).

## 14. Quality gate
- [x] Phase 1 5/5  - [x] Phase 2 searches (listed)  - [x] closest approved: none in this domain;
  scaffolding from codec_test.go  - [x] title verb-led  - [x] shape  - [x] API (no new names)
- [x] canonical form  - [x] 1 codebase-inferable requirement (gojq domain)  - [x] footprint sketched
  in real code  - [x] >= 200 meaningful (350 sketch)  - [x] traps with F-ids, different axes,
  interdependent pairs  - [x] 11b matrix  - [x] filterwarnings audit n/a (Go)
- [x] F-20 sibling audit: msgpack/cbor untouched; existing TestAvroRoundTrip (float64 scores) stays P2P.
- [x] F-12 audit: parquet_test.go superseded cases moved, rest stays in base mode.
- [x] Float audit: no exact equality on computed floats (only stored literals).
- [ ] FINISH: reference-bug harvest, mutation/FP passes, flakiness 3x.

## Why this is not a duplicate
No approved/rejected/in-flight problem touches avro/parquet or value-driven schema inference. Nearest by
word ("schema"): planetiler-custommap-schema-composition (YAML schema layering) and
ytt-library-schema-compatibility; different feature class, different repo.

Predicted iteration cycles: 3.

## Risks
- R1: issue #67 avro-precision bullet (partial tracker overlap, MEDIUM). If the maintainer fixes it
  before submit, SIX-CHECK #5 goes yellow for that sub-part.
- R2: maintainer is in a codec data-loss sweep (#67-#72, 2026-10-01/02; #75 merged 2026-10-10). Re-check
  before submit.
- R3: behaviour change of tested parquet behaviour (string values) must be stated plainly in meta.
- R4: outsider-nameable feature (schema inference). Mitigation only.
