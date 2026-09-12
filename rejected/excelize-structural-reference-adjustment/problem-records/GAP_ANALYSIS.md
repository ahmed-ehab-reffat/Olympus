# Gap analysis — Excelize structural reference adjustment

Verdict: **pass**

## Immutable version

- Repository pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`
- Focused census: reference 12/12; pristine 0/12 with 12 assertion
  failures and 0 errors.
- Base census: 583 tests, 0 failures/errors, 1 upstream skip.

## Atomic requirement-to-test map

| ID | Atomic public requirement | Strongest focused oracle | Coverage |
|---|---|---|---|
| R01 | All four exported structural operations update the three named feature families and persist through write/reopen | family tests below; `MixedStructuralSequencePersistsAfterReopen` | direct |
| R02 | Inserted rows shift comments at/after the boundary but not before it | `CommentsShiftOnRowInsertionAfterReopen` (before/at/after, three comments) | direct |
| R03 | Inserted columns shift comments at/after the boundary but not before it | `CommentsShiftOnColumnInsertionAfterReopen` | direct |
| R04 | Comment XML and the matching VML `Note` remain one identity when stores have different order | `CommentIdentityDoesNotDependOnStoreOrder` | direct |
| R05 | VML note attachment and both geometric-anchor endpoints move in rows and columns | `CommentVMLAnchorMovesInBothDirections` | direct |
| R06 | Deletion follows `x:Row`/`x:Column`, not a separately positioned box | `CommentDeletionUsesAttachmentNotBoxPosition` | direct |
| R07 | Non-comment VML controls are outside comment adjustment | `StructuralEditsDoNotTreatFormControlsAsComments` using public add/get control APIs | direct |
| R08 | Comments on deleted rows/columns disappear; later comments shift; unaffected comments survive | `CommentsAreRemovedOrShiftedOnDeletion` | direct |
| R09 | Manual row/column break IDs shift on insertion | `PageBreaksShiftOnInsertion` | direct |
| R10 | A break at a deleted boundary disappears and later breaks shift | `PageBreaksDeleteAndRecount` | direct |
| R11 | `count` and `manualBreakCount` equal the surviving manual collection | both page-break tests, strongest after two-to-one deletion | direct |
| R12 | Every protected-range area shifts/expands for row and column insertion | `ProtectedRangesExpandAndShiftOnInsertion` | direct |
| R13 | Deletion before/at/inside protected areas shifts, trims, or drops each area | `ProtectedRangesTrimDropAndShiftOnDeletion` | direct |
| R14 | A protected-range element with no surviving area disappears while a sibling remains | `ProtectedRangesTrimDropAndShiftOnDeletion` | direct |
| R15 | Other protected-range attributes remain intact | insertion and deletion tests preserve nonempty `password` | direct |
| R16 | Mixed families remain coherent across more than one structural operation and reopen | `MixedStructuralSequencePersistsAfterReopen` | direct |
| R17 | Extension protected ranges, threaded comments, macros, and unrelated legacy objects are not added to the supported surface | no positive probe; the form-control negative pins the only shared producer seam | direct negative/excluded |

`unmapped_meta_clauses = 0`

## Repository-grounded dimensions and equivalence classes

| Dimension | Separate classes | Evidence and grouping decision | Strongest coverage |
|---|---|---|---|
| Feature store | comments; page breaks; protected ranges | Three independent fields/writers and three explicit TODO labels; not grouped | R02–R16 |
| Direction | rows; columns | `adjustDirection` selects independently implemented branches | insertion/deletion tests exercise both; rows-only comment mutant fails |
| Lifecycle | insertion; deletion | deletion removes/trim states rather than only translating | separate family insertion/deletion tests |
| Relative position | before; exactly at; inside; after | before is unchanged/shift, exact can delete, inside expands/trims, after shifts | comment before/at/after; break exact/later; protected before/inside/single |
| Comment representation | comments XML; VML attachment; VML geometry | Different ZIP parts and different identifiers; none implies another | R04–R06 |
| VML producer | `Note`; non-note form control | Explicit `ObjectType` branch and public form-control API | R07 |
| Identity cardinality | one; several aligned; several independently ordered | Calamine near-pass and VML's self-identifying row/column fields make order independent | R02, R04 |
| Box placement | attachment-aligned; separately positioned | Existing repository deletion helper tempts anchor-based identity | R05, R06 |
| Break cardinality | one; multiple with a consumed member | Aggregate bugs appear only when count changes | R09, R10–R11 |
| Protected shape | singleton; rectangle; multi-area; multiple elements | Parser and filter branches differ; multi-area and element removal are direct | R12–R15 |
| Protected mutation | insertion before/inside; deletion before/start/inside | Existing `adjustCellRef` is specifically wrong at deletion start | R12–R14 |
| Publication | in-memory operation; saved/reopened archive | Writers and caches can disagree until serialization | all comment tests and mixed test reopen; other tests parse saved ZIP |
| Bounds/error state | ordinary valid coordinates | Max-row/column validation and malformed-input behavior pre-exist and are not part of the three TODOs | intentionally grouped/excluded |

Equivalent cells deliberately share a probe when they traverse the same code
and oracle. Additional form-control types all take the same non-`Note` branch,
so checkbox is representative. Other standard protection attributes are all
opaque attributes to the structural adjuster, so `password` represents
preservation rather than a Cartesian attribute matrix. Automatic page breaks
are excluded because the prompt says manual breaks. Threaded comments and
extension-list protected ranges use different unsupported stores and are
explicitly excluded.

## Gap challenges and results

| Plausible wrong implementation | Why plausible | Predecessor/current result | Full-suite result |
|---|---|---|---|
| Join comment XML entries to VML shapes by array position | Calamine 5/6 made the analogous display-order mistake | passed predecessor 9/9; final fails only `CommentIdentityDoesNotDependOnStoreOrder` | 583/583 pass |
| Use VML box top-left as comment identity | existing `deleteFormControl` uses the anchor to find an object | passed predecessor 10/10; final fails only `CommentDeletionUsesAttachmentNotBoxPosition` | 583/583 pass |
| Adjust every VML client object | easiest removal of the `ObjectType == Note` guard | passed predecessor 11/11; final fails only `StructuralEditsDoNotTreatFormControlsAsComments` | 583/583 pass |
| Update comment XML but not VML | comment API looks correct until archive inspection | final killed by five comment/VML tests | not a survivor |
| Update VML attachment but not geometry | attachment is sufficient for `GetComments` | final fails only anchor movement | not a survivor |
| Implement comments for rows only | helper exposes a tempting direction branch | final killed by column insertion, deletion, anchor, and mixed tests | not a survivor |
| Implement break insertion but ignore deletion | translation is easier than filtering | final killed by deletion and mixed tests | not a survivor |
| Filter break nodes but leave old counts | IDs look correct in a shallow inspection | final fails `PageBreaksDeleteAndRecount` | not a survivor |
| Reuse existing `adjustCellRef` for protected ranges | conspicuous local helper avoids new range logic | final killed by deletion-at-start and mixed cases | not a survivor |
| Adjust only the first `sqref` area | treating `sqref` as a scalar is common | both protected-range tests fail | not a survivor |
| Re-serialize only `name`/`sqref` and lose other attributes | raw `innerxml` invites a narrow struct | both protected-range tests fail | not a survivor |

All final mutants compile. Every actionable survivor was run through the full
pre-existing suite before its probe was admitted. The final 12-test matrix
kills all attempted incorrect mutants.

## Admitted probes

1. Independently ordered comment/VML stores: public because each store carries
   its own cell identity; passes the reference, kills the positional survivor,
   and still fails on pristine.
2. Separately positioned note box: standards-shaped eight-integer VML anchor;
   deletion remains tied to the explicit attachment; passes reference, kills
   the anchor-identity survivor, and fails on pristine.
3. Non-note form control paired with a comment that must move: public
   `AddFormControl`/`GetFormControls` oracle; reference moves the comment and
   leaves the control, pristine fails the positive comment half, and the
   all-VML mutant fails the control half.

## Rejected gaps

- Exact singleton spelling (`A1` versus `A1:A1`) and `sqref` area order are not
  public. The initial exact-string oracle was replaced by parsed coordinate-set
  comparison. A legitimate solution preserving singleton spelling passes
  12/12 focused and 583/583 base tests.
- Testing every protection attribute repeats the same opaque-preservation
  branch; `password` is representative.
- Every form-control enum repeats the same non-`Note` discriminator; checkbox
  is representative.
- Automatic breaks, extension protected ranges, threaded comments, macros,
  malformed XML, maximum coordinates, and error rollback are outside the
  announced scope or existing TODO behavior.
- An additional all-ranges-deleted container fixture would repeat the already
  tested element-filter path without repository or trajectory evidence for a
  distinct survivor.

## Final verdict

No actionable public gap survives the attempted repository- and
trajectory-grounded matrix. Exact-version verdict: **pass**. This is evidence
for the attempted dimensions and mutants, not a claim that false positives are
impossible.
