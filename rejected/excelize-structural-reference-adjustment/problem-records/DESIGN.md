# Design — Excelize structural reference adjustment

## Status and immutable identity

- Status: **problem package complete; exact-version audits pass; calibration 0/10**
- Repository: `qax-os/excelize`
- Exact pin: `40f8be41a7aecf250fae03b7d79478a22a4e75a9`
- Production language: Go
- Task type: bug fix
- Selection date: 2026-08-16

## Mandatory trajectory-informed startup gate

I searched `problems/`, `candidates/`, `archive/`, and local trajectory summaries
for Excelize, OOXML, spreadsheet comments, page breaks, protected ranges,
structural row/column edits, and reference adjustment. There is no prior
Excelize problem or trajectory. The closest repository-and-format analogue is
the accepted Calamine defined-name task, which coordinates logical spreadsheet
metadata across independently implemented serialized representations.

I read the Calamine problem's `SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `RUNS.md`,
`ERRORS.md`, and archive manifest, then inspected three raw solver trajectories
and their patches directly from
`archive/calamine-defined-names/agent-runs.tar.gz`:

- The legitimate 6/6 pass (run 4, `Nova_Nova_3`) changed five production
  parsers (+275/-29 production lines). It decoded each spreadsheet format
  natively and associated the adjacent XLS source record rather than looking up
  by display spelling. The archive records 205/205 base and 6/6 focused tests.
- The 5/6 near-pass (`Nova_Nova_10`) coordinated the same five production
  files, but attached an XLS comment to the first same-spelling name without a
  comment. A duplicate scoped name acquired the wrong comment even though all
  solver-authored tests and the full suite passed. This is direct evidence that
  identity across parallel stores is a distinct discriminator.
- The 3/6 broad failure (`Nova_Nova_7`) parsed XLS comments from the wrong
  record, collapsed absent versus empty comments, and reused XLS bit masks for
  XLSB flags. Similar serialized concepts still require their own layout and
  lifecycle rules; this does not justify arbitrary format permutations.

Trajectory consequence: classic comment XML and its corresponding VML `Note`
must move as one logical entity without joining by list position, spelling, or
geometric coincidence. Page breaks and protected ranges remain separate axes
only because repository and public-format evidence gives them independent
state and structural-edit rules.

## Repository and ownership evidence

At the exact pin, `adjust.go::adjustHelper` coordinates nine reference-adjust
helpers and explicitly leaves `adjustComments`, `adjustPageBreaks`, and
`adjustProtectedCells` as TODOs. `git log -S` traces the labels to refactor
commit `dc01264`; none has ever been implemented. Comments use
`xl/comments*.xml` plus a VML `Note` whose `x:ClientData` separately records an
eight-field anchor and zero-based row/column attachment. Row and column breaks
store zero-based IDs plus `count` and `manualBreakCount`. Classic protected
ranges are retained as worksheet `innerxml` and have no first-class Excelize
API.

The pin is one commit behind the 2026-08-16 upstream head for an unrelated row
security fix; all three TODO seams are unchanged at head. Full Git history,
exact GitHub searches for all three labels, and the newest 1,000 issue/PR
records exposed no active owner. Closed issue #1957 and its fix affect adjacent
VML/text-box macro content, not structural comment movement. A broken
blob-filtered audit clone was quarantined after missing promisor objects made
history traversal unreliable; every conclusion was repeated from a full clone
that passes `git fsck --full`.

Public-format grounding:

- Microsoft documents `rowBreaks` with the example that a break inserted at
  B25 is stored as zero-based `id="24"`, and defines `count` and
  `manualBreakCount` as collection invariants:
  <https://learn.microsoft.com/dotnet/api/documentformat.openxml.spreadsheet.rowbreaks>
- Microsoft documents classic `protectedRanges` and the standard
  `protectedRange sqref="A1:C5"` form:
  <https://learn.microsoft.com/dotnet/api/documentformat.openxml.spreadsheet.protectedranges>
- The Microsoft XLSX specification states that an application can adjust
  `sqref` cell references when worksheet layout changes, even in an
  unrecognized extension:
  <https://learn.microsoft.com/openspecs/office_standards/ms-xlsx/4d7cc415-6c51-4c71-8dbd-a2e28bdd9193>

Shapes, non-note form controls, macros, threaded comments, extension-list
protected ranges, and unrelated worksheet reference stores are excluded.

## Candidate contract

`InsertRows`, `RemoveRow`, `InsertCols`, and `RemoveCol` must update three
currently omitted standard worksheet feature families:

1. Classic comment attachment refs and the matching VML `Note` attachment and
   geometric anchor. A feature on a deleted row/column disappears; later
   features shift; unaffected features remain identified with the same text.
2. Manual row/column page-break IDs. A break at the deleted boundary
   disappears, later breaks shift, and both aggregate counts remain coherent.
3. Every area in classic protected-range `sqref`. Insertion before a range
   shifts it and insertion inside expands it. Deletion before shifts, deletion
   inside trims, and a consumed single-cell area disappears. A protected-range
   element disappears only when none of its areas survives. Other protection
   attributes remain intact.

The behavior must survive `WriteToBuffer`/`OpenReader`. The task does not
promise transactional rollback if a later existing helper errors; Excelize's
current pipeline already mutates sequentially.

## Discriminator ledger

| Evidence | Plausible shortcut | Public black-box oracle | Independent boundary |
|---|---|---|---|
| Calamine 5/6 joined by display identity | update comment XML only or move the first VML note | reopened `GetComments` plus note `x:Row`/`x:Column` agree for several comments | dual store and source identity |
| VML stores attachment and eight-part geometry separately | change `Row`/`Column` but not `Anchor` | saved note attachment and both anchor endpoints shift in two directions | logical versus geometric state |
| helper has row/column and insertion/deletion branches | implement inserted rows only | all four exported operations preserve the same logical rule | direction and lifecycle |
| breaks use zero-based IDs and two counts | move an ID but leave stale aggregates | saved break IDs, `count`, `manualBreakCount`, and `man` agree | collection invariant |
| `sqref` is a list of areas | call a single-cell shifter on the whole string | multi-area and rectangular ranges independently move/trim/drop | range representation |
| existing `adjustCellRef` shifts a range start left when deleting exactly at it | reuse it unchanged | deletion at the first row/column keeps the surviving range start in place | deletion boundary |
| unrelated VML shapes can share a part | adjust every VML client object | only `ObjectType="Note"` is in scope | producer mode |

Anti-overfit rule: tests use exported workbook operations and standards-shaped
ZIP parts. They do not require helper names, call order, a particular XML
parser, internal structs, unchanged serialization whitespace, malformed private
XML handling, or rollback after unrelated errors.

## Cheapest-complete convergence probe

The first reference prototype added 348 and removed 3 production lines in
`adjust.go`. It separately:

- resolves the worksheet's comments relationship, filters/renames comment
  refs, and rebuilds the comment cache;
- loads VML into a writable form, filters `Note` shapes by their own
  row/column identity, and adjusts attachment and anchor fields without
  rewriting non-note shape bodies;
- adjusts row or column break collections and recomputes both counts; and
- parses classic protected-range elements, adjusts every `sqref` area with
  insertion/deletion-specific range semantics, and preserves other attributes.

Three exploratory public/archive probes and the final twelve black-box focused
cases pass. The complete upstream suite also passes (roughly 35 seconds without
race instrumentation). The pristine pin fails all twelve focused cases as real
assertion failures with zero compile/startup errors.

A smaller alternative can reuse `adjustCellRef` and omit VML geometry, but it
is incomplete: deletion at a range's first coordinate shifts the surviving
start one cell too far, and comment XML then disagrees with the serialized VML
attachment/anchor. The correct seam therefore remains roughly 300–350
production lines despite the conspicuous TODO comment. Selection verdict:
**promote**.

## Environment prerequisite

Phase A and exact-composition Phase B are recorded in `ENVIRONMENT.md`. The
exact untouched pin passes build and 583 discovered tests offline as arbitrary
UID 10001 after staging the evaluator's read-only checkout into temporary
writable storage. A race-instrumented attempt is quarantined because the
deliberate in-memory ZIP64-over-4-GB test exceeds the approved runtime's 7.653
GiB; it is not behavioral evidence. Baseline focused JUnit contains 12 real
failures; reference focused JUnit contains the same 12 identities with zero
failures/errors. `GAP_ANALYSIS.md`, `FAIRNESS_ANALYSIS.md`, and
`FALSE_POSITIVE_AUDIT.md` all record exact-version `pass` verdicts.

Final artifact hashes:

- `meta.md`: `745f5d75524980aad1094d27e49ac0939226592b79bc0b6b425f2fbc5677587d`
- `test.patch`: `619b5d4276e0ade214fc2c3539d4b81eed8624ea7defc265906b11861700dc4f`
- `solution.patch`: `0683b4099bc6c91a2625da2d35b75dc561b8d512905d555673b1e8314b4b3b7c`
- `Dockerfile`: `bc744ed1078ad721d86ca847c003e5f490880ddf075e9b8b4132ce0e45b03da6`
