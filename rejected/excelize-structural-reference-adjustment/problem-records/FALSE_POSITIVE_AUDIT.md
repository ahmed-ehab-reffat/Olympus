# False-positive audit — Excelize structural reference adjustment

Verdict: **pass** for the attempted mutation set

## Immutable version

- Repository pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`
- Final reference: 12/12 focused, 583/583 base, one upstream skip.
- Final pristine: 12/12 focused assertion failures, zero errors.

## Method

1. Mapped every participant-facing rule to its strongest black-box test (the
   complete map is in `GAP_ANALYSIS.md`).
2. Built plausible incorrect implementations from the explicit source TODOs,
   existing `deleteFormControl` anchor matching, `adjustCellRef` deletion
   behavior, raw `ProtectedRanges` storage, the Calamine positional-identity
   near-pass, and the separate VML producer branch.
3. Compiled and ran each mutant against the focused matrix.
4. Ran every meaningful focused survivor through the complete 583-test
   pre-existing suite before admitting a probe.
5. Required each admitted probe to pass reference, fail its targeted mutant,
   use only public/standards-shaped behavior, and also fail on pristine.
6. Replayed a legitimate alternate singleton serialization to distinguish
   false positives from verifier over-constraint.

## Requirement-to-strongest-test summary

| Requirement family | Strongest discriminators |
|---|---|
| comment rows/columns and persistence | row/column insertion; combined deletion; mixed reopen |
| cross-store identity | independently ordered stores; detached-box deletion |
| VML attachment versus geometry | two-direction anchor movement; detached-box deletion |
| producer boundary | moving E5→F7 comment paired with unchanged G7 form control |
| page-break translation/removal/counts | insertion and two-to-one deletion/recount |
| protected multi-area insertion/deletion | expand/shift and trim/drop tests with multiple areas/elements |
| protected attribute retention | password checks in insertion and deletion lanes |
| encoding freedom | parsed/sorted coordinate areas; legitimate singleton replay |

## Mutation results

All mutants below compile. “Predecessor survivor” means it passed the complete
focused artifact that existed immediately before its targeted probe was added.

| Mutant | Violated public behavior | Focused result | Base result / action |
|---|---|---|---|
| comments XML only | VML attachment/shape stays stale | final fails five comment/VML tests | not a survivor |
| positional comment/VML join | store order is treated as identity | predecessor 9/9 pass; final fails only `CommentIdentityDoesNotDependOnStoreOrder` | 583/583 pass; admitted identity probe |
| no VML anchor adjustment | attachment moves but geometry does not | final fails only `CommentVMLAnchorMovesInBothDirections` | not a survivor |
| row-only comments | column path omitted | final fails column insertion, deletion, anchor, and mixed lanes | not a survivor |
| VML box anchor used as comment identity | detached box prevents correct deletion | predecessor 10/10 pass; final fails only `CommentDeletionUsesAttachmentNotBoxPosition` | 583/583 pass; admitted detached-box probe |
| every VML client object adjusted | form controls are treated as comments | predecessor 11/11 pass; final fails only `StructuralEditsDoNotTreatFormControlsAsComments` | 583/583 pass; admitted paired producer probe |
| page-break deletion ignored | insertions work but consumed/later breaks stay stale | final fails deletion and mixed lanes | not a survivor |
| page-break counts left stale | nodes move/filter but aggregate remains two | final fails only `PageBreaksDeleteAndRecount` | not a survivor |
| existing `adjustCellRef` reused | deletion at range start shifts survivor start left | final fails protected deletion and mixed sequence | not a survivor |
| first protected `sqref` area only | later areas silently disappear/stay stale | both protected tests fail | not a survivor |
| protection attributes dropped | adjusted cells survive but password is lost | both protected tests fail | not a survivor |

The final exact 12-test matrix kills all eleven attempted wrong mutants. The
three predecessor survivors also passed the entire upstream suite, proving the
added discriminators close real false positives rather than base regressions.

## Admitted probes and isolation

### FP-1 — store-order identity

Mutation: use the comment-list index to decide how the VML shape at the same
index moves or disappears.

Why plausible: generated Excelize workbooks align both stores, and the closest
Calamine near-pass made the analogous first-match identity mistake.

Probe: write two ordinary comments, swap the two complete self-identifying
`<comment>` elements, reopen, insert a row, and require both comment refs and
VML attachment cells to agree.

Results: reference passes; positional mutant fails only this probe; pristine
fails because no comment moves; predecessor survivor passes all 583 base tests.

### FP-2 — box geometry mistaken for attachment

Mutation: decide whether a note is deleted or shifted from the VML anchor's
top-left coordinate, following the existing repository deletion helper,
instead of `x:Row`/`x:Column`.

Probe: move the valid eight-integer display-box anchor away from the B3
attachment, delete row 3, then require both public comments and VML notes to be
empty.

Results: reference passes; anchor-identity mutant leaves an orphan note and
fails only this probe; pristine retains the comment; survivor passes all 583
base tests.

### FP-3 — non-note producer scope

Mutation: remove the `ObjectType == Note` guard and adjust every VML object that
has row/column client data.

Probe: add an E5 comment and a G7 checkbox, insert two rows before 3 and one
column before C, then require the comment at F7 and the public form control
still at G7.

Results: reference passes both halves; pristine fails the positive E5→F7
comment half; all-VML mutant moves the control to H9 and fails the negative
half; survivor passes all 583 base tests. The first draft used an unaffected B2
comment and therefore passed pristine; it was rejected and corrected before
the final artifact.

## Legitimate survivor and fairness correction

The original protected-range assertions compared raw `sqref` strings and
therefore required the golden solution's normalization of `A1` to `A1:A1`.
That is not public behavior. The oracle was changed to parse every area into
coordinate tuples and sort them. A legitimate alternate implementation that
preserves singleton spelling as `A1` now passes all 12 focused tests and all
583 base tests. This architecture is retained as fairness replay evidence, not
classified as an incorrect survivor.

## Rejected/artificial trials

- Exact area order, singleton spelling, XML whitespace, namespace-prefix
  choice, and shape IDs are serialization choices, not semantics.
- A matrix across every standard protection attribute repeats the same opaque
  preservation branch; password is representative.
- Every non-note form-control enum repeats the same `ObjectType != Note`
  branch; checkbox is representative.
- Automatic page breaks, extension-list protected ranges, threaded comments,
  macros, malformed VML, arbitrary invalid anchors, maximum coordinates, and
  rollback after unrelated helper errors are excluded or unsupported.
- Repeating before/at/after fixtures for every feature/direction after the
  corresponding branch mutants are already killed would add symmetry, not a
  distinct discriminator.
- Leaving only an empty protected-range container after all elements are
  removed was not supported by a trajectory or independently implemented
  branch beyond the already tested element filter.

## Mutation isolation and full-suite evidence

- Each admitted false-positive mutant fails exactly its new named test.
- No admitted probe changes the known reference or prompt behavior.
- The final pristine JUnit has 12 tests, 12 failures, and 0 errors.
- The final reference JUnit has 12 tests and 0 failures/errors.
- Exact Phase B runs both baseline and reference base lanes: 583 tests, 0
  failures/errors, 1 upstream resource skip.
- Fresh exact-version replays of the positional, anchor-identity, and all-VML
  survivors each returned 583/583 base tests with one upstream skip.
- The legitimate preserve-single replay passes the final 12 focused tests and
  the same full base suite.

## Final verdict

No actionable survivor remains in the attempted repository-grounded mutation
set. Exact-version verdict: **pass**. Zero survivors is evidence for these
mutants only, not proof that false positives are impossible.
