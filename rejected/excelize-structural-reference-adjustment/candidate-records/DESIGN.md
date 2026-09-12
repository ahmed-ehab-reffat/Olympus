# Design — Excelize structural reference adjustment

## Status and identity

- Status: **selected; promoted to problem package**
- Repository: `qax-os/excelize`
- Pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- Production language: Go
- Task type: bug fix
- Final measured rating: **8/10**
- Submission artifacts and exact-version audits are in
  `problems/excelize-structural-reference-adjustment/`.

## Mandatory trajectory-informed startup gate

Search performed on 2026-08-16 over `problems/`, `candidates/`, `archive/`, and
the local trajectory summaries for Excelize, OOXML, spreadsheet comments,
page breaks, protected ranges, structural row/column edits, and reference
adjustment. There is no prior Excelize problem or trajectory. The closest
repository-and-format analogue is the accepted Calamine defined-name task,
which coordinates spreadsheet metadata stored in independently implemented
format parsers. I read its `SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `RUNS.md`,
`ERRORS.md`, and archive manifest, then inspected three representative raw
solver trajectories and patches directly from
`archive/calamine-defined-names/agent-runs.tar.gz`:

- The legitimate 6/6 pass (run 4, `Nova_Nova_3`) changed five production
  parsers (+275/-29 production lines). It modeled one public logical entity but
  decoded ODS, XLS, XLSB, and XLSX through their native record structures. Its
  XLS path associated the adjacent source record rather than looking up by
  display spelling. It ran the focused and full suites; the archive records
  205/205 base and 6/6 focused tests.
- The 5/6 near-pass (`Nova_Nova_10`) also coordinated all five production
  files, but attached an XLS comment to the first same-spelling name without a
  comment. A duplicate scoped name therefore acquired the wrong comment even
  though the solver's authored tests and full suite passed. This is direct
  evidence that source identity across parallel representations is a useful
  discriminator.
- The 3/6 broad failure (`Nova_Nova_7`) parsed XLS comments from the wrong
  record, collapsed absent versus empty comments, and reused XLS bit masks for
  XLSB flags. It is evidence that superficially similar serialized stores must
  retain their own layout and lifecycle rules; it is not evidence for testing
  arbitrary format permutations.

Trajectory consequence: comment XML and the corresponding VML note must be
treated as one logical identity despite different encodings. Worksheet page
breaks and protected-range `sqref` values are separate behavior families only
if repository and public-format evidence establishes their own structural-edit
rules. The Calamine evidence does not justify bundling unrelated spreadsheet
metadata merely for breadth.

## Repository evidence

At exact pin `40f8be41a7aecf250fae03b7d79478a22a4e75a9`,
`adjust.go::adjustHelper` coordinates nine structural helpers and explicitly
lists `adjustComments`, `adjustPageBreaks`, and `adjustProtectedCells` as TODOs.
`git log -S` traces all three TODO labels to refactor commit `dc01264`; none has
subsequently been implemented. Comments are split between `xl/comments*.xml`
and a VML `Note` shape whose `x:ClientData` independently stores an eight-field
anchor plus zero-based row and column fields. Page breaks have public
insert/remove APIs and store zero-based IDs with aggregate counts. Protected
ranges are preserved only as worksheet `innerxml`; no first-class Excelize API
was found.

The exact pin is one commit behind the 2026-08-16 upstream head for an
unrelated row security fix; the three TODO seams are unchanged at head. Full
history, exact GitHub searches for each TODO name, and the newest 1,000 issue/PR
records exposed no active owner for these behaviors. Closed issue #1957 and
its fix concern adjacent VML/text-box macro content, not structural movement of
classic comments. Shapes, form controls, threaded comments, and macros are
therefore excluded. A blob-filtered audit clone was quarantined after missing
promisor objects made history traversal unreliable; all conclusions above were
repeated from a full clone that passes `git fsck --full`.

## Candidate public contract

All four row/column structural operations must keep classic comments, manual
page breaks, and existing protected ranges attached to the same logical cells
or surviving ranges. Shift items at/after insertions; for deletions, remove
items fully inside the deleted band and consistently trim/collapse survivors.
Update comments XML and VML note anchors as one unit and recompute break counts.
The workbook must save and reopen with equivalent semantics.

## Discriminator ledger

| Evidence | Plausible shortcut | Public invariant/oracle | Independent boundary |
|---|---|---|---|
| Calamine 5/6 near-pass joined metadata by spelling instead of source identity | Change comment ref only, or move the first VML note | `GetComments` and the matching saved VML note agree after reopen when several comments exist | dual representation and identity |
| Structural helper has separate row/column branches | Fix inserted rows only | insert/delete rows and columns obey the same logical rule | direction/lifecycle family |
| Breaks use zero-based IDs and counts | Shift ID but leave counts/stale nodes | saved `rowBreaks`/`colBreaks` IDs and counts are coherent | metadata invariant |
| Protected ranges may contain multiple refs | Treat `sqref` as one cell | multi-area and rectangular ranges shift/trim correctly | range representation |
| Deletion differs from insertion | Shift every item, including deleted cells | consumed features disappear; later features move | removal boundary |

The prior draft proposed transactional publication after helper errors. That
predicate is removed: `adjustHelper` already mutates rows and then invokes its
helpers sequentially, so repository behavior does not promise atomic rollback.
Malformed private XML and a prescribed helper/call layout are likewise not
candidate discriminators.

Anti-overfit rule: verify public APIs plus standards-shaped saved XML; do not
require helper names, call order, or one XML parsing strategy.

## Promotion outcome

The cheapest-complete prototype measured +348/-3 production lines in
`adjust.go`; the full upstream suite passed. The final problem artifact has 12
black-box focused tests. Pristine fails all 12 behaviorally, the reference
passes all 12, and both base lanes pass 583 tests with one upstream resource
skip. Exact Phase A/B, gap, fairness, and false-positive audits pass. Eleven
plausible wrong implementations are killed; positional comment/VML pairing,
anchor-as-identity, and all-VML adjustment each passed a predecessor focused
suite and all 583 base tests before its distinct probe was added.

The conspicuous TODO did not collapse into a small patch because the correct
solution must coordinate separate comment and VML stores, VML attachment and
geometry, page-break collection invariants, and multi-area protected-range
deletion semantics. Shapes, macros, threaded comments, and arbitrary OOXML
remain excluded.
