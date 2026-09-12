# Fairness analysis — Excelize structural reference adjustment

Verdict: **pass**

## Immutable version

- Repository pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`

## Predicate-to-provenance audit

| Rejection predicate | Tests/lane | Provenance | Freedom preserved |
|---|---|---|---|
| Comments before an insertion remain and comments at/after it move for rows | `CommentsShiftOnRowInsertionAfterReopen` | explicit prompt; exported `AddComment`, `InsertRows`, `GetComments`; TODO `adjustComments` | no helper, cache, XML whitespace, or comment ordering required |
| Same rule for columns | `CommentsShiftOnColumnInsertionAfterReopen` | explicit prompt and exported `InsertCols` | independent implementation allowed |
| Comment/VML association follows each store's own cell identity rather than parallel order | `CommentIdentityDoesNotDependOnStoreOrder` | explicit identity requirement; comment `ref`; VML `x:Row`/`x:Column`; Calamine trajectory evidence | either store may be parsed first; no join strategy required |
| VML attachment and both anchor endpoints move in two directions | `CommentVMLAnchorMovesInBothDirections` | prompt explicitly names VML attachment and anchor; repository documents the eight-field anchor layout | offsets, shape IDs, XML formatting, and recomputation strategy are unasserted |
| Deletion uses attachment row/column when the display box is elsewhere | `CommentDeletionUsesAttachmentNotBoxPosition` | prompt says remove the comment whose attached row/column is deleted; VML stores attachment separately from geometry | any valid box placement and parser architecture accepted |
| Structural comment work does not move non-comment VML controls | `StructuralEditsDoNotTreatFormControlsAsComments` | prompt explicitly excludes non-comment legacy controls; exported add/get form-control APIs; `ObjectType` repository branch | no private VML inspection for the control oracle |
| Deleted comments disappear and later comments shift in both directions | `CommentsAreRemovedOrShiftedOnDeletion` | explicit prompt; exported remove operations and reopened `GetComments` | operation order is public input; internal deletion method unrestricted |
| Inserted row/column break IDs are the stated zero-based values | `PageBreaksShiftOnInsertion` | explicit prompt; Excelize `InsertPageBreak`; Microsoft row-break example stores B25 as ID 24 | break order is sorted before comparison; no raw whitespace required |
| Deleted-boundary break is removed, later break shifts, counts equal surviving manual nodes | `PageBreaksDeleteAndRecount` | explicit prompt; OOXML `count`, `manualBreakCount`, `man`; repository types | internal slice/filter/count strategy unrestricted |
| Protected ranges expand/shift on row/column insertion and retain opaque attributes | `ProtectedRangesExpandAndShiftOnInsertion` | explicit prompt; classic OOXML `protectedRange sqref`; Microsoft says layout-changing apps can adjust `sqref` | areas are parsed and sorted; `A1` and `A1:A1` are equivalent |
| Protected areas trim/drop/shift on deletion, empty element disappears, attribute survives | `ProtectedRangesTrimDropAndShiftOnDeletion` | explicit prompt; standards-shaped classic worksheet XML | no serialization spelling/order or private struct required |
| Three families remain coherent across a mixed sequence and reopen | `MixedStructuralSequencePersistsAfterReopen` | explicit persistence requirement and exported write/open APIs | no transactional rollback or call order beyond the requested operations |
| Base tree builds and the complete existing suite passes | `test.sh base` | ordinary Go module behavior and upstream CI discovery path | no race flag imposed in the memory-limited evaluator |
| Focused tree compiles with build tag and completes within 5 minutes | `test.sh new` | additive verifier isolation; generous deadlock/startup protection | no product latency assertion; reference completes in about 0.03 s |
| Runtime is offline, arbitrary UID, and read-only at evaluator mount | Docker/Phase B | platform contract, not product behavior | wrapper stages into UID-owned `/tmp`; no writable home or source assumed |
| Reporter emits real JUnit and preserves process failure | both modes | evaluator contract | no exact diagnostic text is asserted |

## Negative-data and archive construction

Every workbook begins with Excelize's exported constructors and writer. The two
archive mutations change only standards-shaped, self-describing data:

- swapping two complete `<comment>` elements leaves each `ref`, text, and
  author relationship intact; neither OOXML nor the prompt assigns semantic
  identity by list position;
- changing one VML `<x:Anchor>` to another valid eight-integer rectangle moves
  only the display box and leaves `x:Row`/`x:Column` attachment intact.

Classic protected ranges are inserted as the documented worksheet
`<protectedRanges><protectedRange name=... sqref=.../></protectedRanges>` form
into a workbook produced by Excelize, then consumed through public
`OpenReader`. Password fixtures use valid four-hex-digit values. No malformed,
arbitrary, implementation-defined bytes are used.

## Implementation freedoms preserved

- Tests are `package excelize_test` and invoke exported workbook operations.
  They do not reference private helpers, fields, module layout, or a
  candidate-added API.
- ZIP inspection is an output-format oracle for existing supported XLSX/VML
  features. Assertions use semantic refs, attachment cells, numeric anchor
  endpoints, and aggregate counts, not exact bytes or XML order.
- Protected `sqref` areas are converted to coordinate tuples and sorted.
  Singleton and range spelling are equivalent.
- Comment text is keyed by cell after reopen, so returned list order is not
  prescribed.
- Break IDs are sorted before comparison.
- Only `Note` versus non-`Note` is distinguished. The test does not prescribe a
  parser, relationship resolver, caching scheme, or writer batching strategy.
- No error string, panic, timing threshold, maximum-coordinate edge, malformed
  XML policy, or rollback architecture is tested.
- The prompt expressly excludes extension protected ranges, threaded comments,
  macros, and unrelated legacy controls from positive adjustment.

## Legitimate architecture replay

The golden solution passes all 12 focused tests and all 583 base tests. A
materially different but legitimate serialization variant was also replayed:
it preserves a singleton protected area as `A1` instead of normalizing it to
`A1:A1`. It passes 12/12 focused tests and 583/583 base tests (one upstream
skip), proving the semantic oracle no longer prescribes the reference's
encoding. No external solver patches exist yet.

The positional comment/VML, anchor-identity, and all-VML implementations are
not legitimate alternatives: each contradicts an explicit public identity or
scope predicate, despite passing its predecessor suite and the entire base
suite.

## Lifecycle, determinism, and absence review

All operations are synchronous exported calls; there are no sleeps, threads,
queues, eventual-output drains, or silence-based oracles. Every absence check
is paired with positive progress in the same synchronous workbook:

- detached-box deletion first invokes `RemoveRow`, then verifies both the
  public comment list and note collection;
- the non-comment-control test requires the comment to move from E5 to F7 while
  the control remains at G7, so pristine cannot pass by doing nothing;
- protected-range deletion retains and checks a sibling range while requiring
  a fully consumed element to disappear.

The 5-minute focused and 60-minute base limits are harness watchdogs. They are
orders of magnitude above observed focused and base runtimes and are not
interpreted as product latency.

## Environment and harness fairness

The approved base image resolves all dependencies at build time. `test.sh`
copies the read-only evaluator checkout to `/tmp` because upstream tests write
generated XLSX fixtures into `test/`; both baseline and reference use the same
path. Phase B passed offline as UID 10001 for all four lanes, produced real
JUnit, and confirmed identical focused testcase identities. The deliberate
race-instrumented >4-GB ZIP64 OOM was quarantined; race is not part of the
submitted wrapper. See `ENVIRONMENT.md`.

## Corrected and rejected fairness complaints

- **Corrected:** initial protected-range assertions required exact `A1:A1`
  normalization and area order. They now parse/sort coordinate areas; the
  preserve-single legitimate replay passes.
- **Corrected:** the first non-comment control probe passed pristine because
  neither observed object needed to move. It now pairs an E5→F7 comment with a
  G7 control; pristine and the targeted mutant fail for different public
  reasons, while reference passes.
- **Rejected:** protected ranges lack a first-class Excelize constructor. The
  repository explicitly retains classic protected-range XML, the structural
  helper names its TODO, Microsoft documents the format and adjustment
  behavior, and the test enters through public `OpenReader` and exported edit
  APIs.
- **Rejected:** reordered comment elements or a detached box are artificial.
  Both are valid self-identifying representations; the repository already
  stores logical attachment separately from ordering and geometry, and both
  shortcuts were independently demonstrated as full-suite false positives.
- **Rejected:** checking saved break and protected XML is private-layout
  testing. These are standardized XLSX output parts for supported public
  features; the tests ignore internal Go layout and formatting.
- **Rejected:** setting `GITHUB_ACTIONS=true` hides product behavior. It invokes
  an upstream-authored resource skip only for a separate temporary-file ZIP64
  case and is identical across participants; the in-memory ZIP64 case and all
  582 other discovered entities still run in base mode.

## Final verdict

Every logically distinct rejection predicate is grounded in the public prompt,
exported repository behavior, standardized saved format, ordinary Go
semantics, or the evaluator contract. No unresolved uncertainty remains.
Exact-version verdict: **pass**.
