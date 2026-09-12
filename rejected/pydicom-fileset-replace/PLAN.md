# PLAN - staged replacement of a managed DICOM File-set instance

Status: upstream audit and task preflight passed on 2026-07-23. This is a
self-contained implementation handoff. The design gate remains mandatory.

## 1. Task identity

| Field | Decision |
|---|---|
| Repository | `pydicom/pydicom` |
| Language | Python |
| Task type | feature request |
| Base commit | `dd9f032d15ac5265e1903d1102d19ceb51182506` |
| Base version | `3.1.0.dev0` |
| License | MIT project license |
| Work namespace | `work/pydicom-fileset-replace/` |
| Public API | `FileSet.replace(instance, ds_or_path) -> FileInstance` |
| Working title | Replace a managed File-set instance without remove/add gaps |

Add a first-class staged replacement operation for an instance already managed
by a `FileSet`. It must snapshot the replacement dataset, regenerate the
standard directory-record branch and SOP reference metadata, and cooperate with
both `write()` modes and `copy()` without modifying the live File-set before
publication.

This replaces one explicitly selected managed instance. It does not scan an
arbitrary folder, discover unreferenced files, or act as a general DICOM
validator.

## 2. Upstream eligibility and audit

The proposed base commit was also the default-branch head at final preflight:
<https://github.com/pydicom/pydicom/commit/dd9f032d15ac5265e1903d1102d19ceb51182506>.
The repository had 2,191 stars, current July 2026 development, and an MIT
project license; its license file separately identifies permissively licensed
generated dictionary portions.

### Search ledger

Issues and pull requests were searched in all available states, including
merged PRs. GitHub Discussions were searched separately because this repository
has them enabled.

| Surface | Concepts searched | Result |
|---|---|---|
| Issues | `FileSet` with `audit`, `validate`, `integrity`, or `verify` | No equivalent replacement task. Closed issue #2209 asks how to create a DICOMDIR from arbitrary files. |
| Issues | `DICOMDIR` with `repair`, `reconcile`, `consistency`, `missing file`, `broken reference`, or `mismatch` | No managed-instance replacement proposal. Located historical malformed-DICOMDIR and offset bugs only. |
| Issues | `FileSet replace instance`, `FileSet update existing`, `FileSet modify managed` | No matching feature. Results were the foundational FileSet issue or unrelated parsing reports. |
| Pull requests | The same integrity and replacement concepts | No replacement implementation. PR #1189 added the current FileSet/add/remove/copy/write model. PR #1707 handles an invalid DICOMDIR dataset. |
| Discussions | `FileSet`, `replace`, `update existing`, `modify instance`, `DICOMDIR repair`, `integrity`, `ReferencedFileID` | No matching design. Discussion #2208 became issue #2209. Discussion #1662 asks how to mutate attributes for anonymization but proposes no staged replacement contract. |
| Roadmap discussion | FileSet and DICOMDIR sections of #1759 | Maintainers say `FileSet` should continue to represent a standard DICOM File-set and note that it already organizes added instances. This task stays inside that boundary. |
| Code, tests, changelog, git history | `FileSet`, `DICOMDIR`, `replace`, `repair`, `reconcile`, `integrity`, reference UIDs | `add()` intentionally returns the existing instance for a duplicate SOP Instance UID; no replacement stage or API exists. |

Useful primary links:

- Repository: <https://github.com/pydicom/pydicom>
- Project license: <https://github.com/pydicom/pydicom/blob/main/LICENSE>
- Foundational FileSet PR: <https://github.com/pydicom/pydicom/pull/1189>
- Adjacent folder-import request:
  [discussion #2208](https://github.com/pydicom/pydicom/discussions/2208) and
  [issue #2209](https://github.com/pydicom/pydicom/issues/2209)
- Modification question: <https://github.com/pydicom/pydicom/discussions/1662>
- Maintainer roadmap discussion: <https://github.com/pydicom/pydicom/discussions/1759>
- DICOM directory-reference requirements:
  <https://dicom.nema.org/medical/dicom/current/output/chtml/part03/sect_f.3.2.2.html>

### Maintainer and standards fit

The DICOM standard requires each referenced file to be within the File-set and
the directory record to carry the SOP Class, SOP Instance, and Transfer Syntax
UIDs of that file. `FileSet.add()` already derives standard record branches and
reference fields from a dataset, while `remove()`, `write()`, and `copy()` own a
staging model. A replacement operation composes these established behaviors
without expanding pydicom into application-specific series processing.

The current DICOM standard reserves `FileSetConsistencyFlag` value `0000H` and
states that the former `FFFFH` inconsistent-state signal is retired. Do not use
that retired mechanism for this task.

### Local similarity

No existing `problems/` task concerns Python object replacement, DICOMDIR tree
maintenance, or staged filesystem publication. The task is domain-specific and
does not resemble the accepted ACH correction API beyond the generic fact that
both stage mutations. No public checklist enumerates this missing method.

### Audit verdict

`proceed`. The exact replacement feature is absent from upstream history,
maintainer comments support keeping FileSet behavior within the DICOM model,
and the arbitrary-folder request is explicitly excluded.

## 3. Verified repository map

Read these locations completely before producing `DESIGN.md`:

| Area | Location | Relevance |
|---|---|---|
| FileSet state | `src/pydicom/fileset.py:975` onward | `_tree`, `_instances`, and the `+`, `-`, `~`, `^` staging state. |
| Managed instance view | `FileInstance` near line 735 | Public path, UIDs, dynamic directory-record lookup, and staging flags. |
| Add paths | `FileSet.add()` and `add_custom()` | Duplicate-UID no-op, standard/private record creation, and staged snapshot behavior. |
| Reset/copy | `FileSet.clear()` and `copy()` | Every new replacement state must reset and must be applied to copies without consuming the original stage. |
| Record derivation | `FileSet._recordify()` | Existing authoritative standard directory-record builders and required-element validation. |
| Removal | `FileSet.remove()` | Explains why a naive public remove-then-add cannot replace an instance with the same UID. |
| Publication | `FileSet.write()` | Existing-layout versus pydicom-layout paths, collision staging, physical moves/copies, DICOMDIR rewrite, and reload. |
| Existing tests | `tests/test_fileset.py` | FileSet fixtures, standard/private branches, copy/write helpers, orphans, bad paths, and staging assertions. |
| User docs | `doc/tutorials/filesets.rst`, `doc/reference/fileset.rst` | Required public API documentation location and terminology. |

Key architectural facts:

- `add()` returns the existing `FileInstance` when its SOP Instance UID already
  exists, even if the supplied dataset has different content.
- Removing an instance and then adding the same UID cancels the removal and
  restores the old instance. That shortcut is not a replacement.
- `write(use_existing=True)` currently permits removals but rejects additions;
  replacement is net-neutral and must become a distinct supported staged case.
- Ordinary `write()` may reorganize files into pydicom's generated File IDs.
  `use_existing=True` must preserve the replaced instance's current File ID.
- `copy()` must apply staged changes to the destination while leaving the
  original FileSet and root unchanged and still staged.

## 4. Required public behavior

Convert these clauses into a two-way prompt/test ledger. The final `meta.md`
must be natural maintainer prose, ASCII only, and no more than 500 words; target
below 480 words.

1. Add `FileSet.replace(instance, ds_or_path) -> FileInstance`, accepting the
   same `Dataset`, string path, and path-like replacement sources as `add()`.
2. `instance` must be a currently yielded, already-written managed instance of
   that exact FileSet. Reject a foreign instance, a removed instance, or an
   instance still staged for addition. An existing instance merely staged for
   movement remains eligible.
3. The replacement uses the same default standard directory-record derivation
   and required-element validation as `add()`. Replacing a branch containing a
   `PRIVATE` directory record is out of scope and must be refused before state
   changes; do not guess how to rebuild private records.
4. Snapshot the replacement into FileSet staging before changing public FileSet
   state. Later modification, deletion, or reuse of the supplied path or dataset
   must not change what `write()` or `copy()` publishes.
5. On success, return the replacement `FileInstance`. The FileSet still has the
   same length, yields the new instance in place of the old one, reports staged
   changes, and leaves the on-disk root and DICOMDIR unchanged until publication.
6. The new branch and leaf reference fields come from the replacement dataset,
   including record type and Patient/Study/Series keys plus Referenced SOP Class,
   SOP Instance, and Transfer Syntax UIDs.
7. Reusing the old SOP Instance UID is valid. Changing it is also valid unless
   another managed or staged instance already owns the new UID. Refuse a
   collision before any staging or observable state changes.
8. Any read, validation, serialization, private-branch, ownership, or collision
   failure leaves the FileSet exactly as it was, including iteration, staging
   flags, temporary staged files, and the old instance's usability.
9. `write(use_existing=True)` applies a replacement at the original Referenced
   File ID, updates the DICOMDIR branch and UID references, removes no unrelated
   files, and reloads as an unstaged FileSet containing only the replacement.
10. Ordinary `write()` may publish the replacement under the File ID derived
    from its new standard record branch, using the existing pydicom layout
    rules. The superseded file and old DICOMDIR reference must be gone.
11. `copy()` publishes the replacement into the copied FileSet while the source
    FileSet remains staged and its original on-disk root remains unchanged.
12. `clear()`, `is_staged`, and the non-exact human-readable staged-change
    summary must account for replacement state. Do not require a particular
    private dictionary key or exact summary sentence in tests.

Out of scope:

- arbitrary folder discovery or importing unreferenced files;
- replacing newly added, already removed, orphan-only, or private-record
  instances;
- in-place mutation tracking for datasets returned by `FileInstance.load()`;
- multi-instance atomic replacement or UID swaps;
- pixel-data decoding or semantic validation beyond existing FileSet/add rules;
- new validation of unrelated files in the File-set root.

## 5. Intended design boundaries

Use the existing FileSet staging transaction, but introduce replacement as a
first-class net-neutral change rather than disguising it as an addition. The
exact private representation is an implementation choice and must not appear in
`meta.md` or behavior-only tests.

A sound implementation sequence is:

1. Verify ownership and eligible staging state without mutation.
2. Load or accept the replacement dataset, fully materialize `_recordify()`
   output, validate the non-private scope and all reference UIDs, and check UID
   collisions against every managed/staged instance except the one replaced.
3. Serialize the replacement to a new temporary staged path. If that fails,
   delete only the attempted snapshot and leave the FileSet untouched.
4. Build the new standard branch and `FileInstance`, then atomically exchange
   the in-memory branch/instance and record one replacement entry containing the
   original physical File ID and staged snapshot.
5. Extend `clear()`, `is_staged`, summary reporting, `copy()`, and both `write()`
   paths. Existing-layout publication overwrites the original physical file;
   ordinary publication follows the new generated branch.
6. Reload after successful write through the existing code so offsets, paths,
   stage state, and public instances are canonical.

Do not change `add()` duplicate semantics. Do not expose the staging data
structure, temporary path, or a new public replacement flag unless a separately
justified API design requires it.

Expected production scope is approximately 150-200 effective lines, primarily
in `src/pydicom/fileset.py` plus public documentation. If the clean solution is
materially larger, stop at the design review with measured evidence.

## 6. Discriminators and shallow implementations

The suite must center on two independent architectural discriminators.

### Discriminator A: a real staged replacement transaction

Kill implementations that call `remove()` then `add()`, mutate the old leaf in
place, retain a reference to the caller's dataset/path, or partially change the
tree before validation finishes. The decisive cases are same-UID replacement,
source equal to the old file path, source deletion after `replace()`, and a late
serialization/record-validation refusal with a before/after state snapshot.

### Discriminator B: publication-mode and identity parity

Kill implementations that only work for ordinary `write()`, count replacement
as a forbidden addition under `use_existing=True`, update content but not the
record hierarchy, leave an old UID/path behind, or mutate the source during
`copy()`. Cross same-UID and changed-UID replacements through existing-layout
write, generated-layout write, and copy, with an independent UID-collision case.

Private-branch refusal and reset/summary behavior support these discriminators;
they are not a third checklist task.

## 7. Behavioral test plan

Place challenge tests outside upstream's configured `tests/` collection, under
`grader_tests/` with a random non-descriptive filename. Base mode runs upstream
tests only; new mode explicitly runs the challenge file. Use only public
behavior for assertions. It is acceptable to inspect the DICOMDIR with
`dcmread()` because that is the repository's public format oracle.

Minimum matrix:

| Case | Assertions |
|---|---|
| Same UID, `use_existing=True` | Original File ID preserved; file bytes/data and directory keys updated; one instance; unstaged after reload. |
| Changed UID, ordinary `write()` | New standard hierarchy and generated File ID; all three reference UIDs match; old UID/file absent. |
| Changed UID, `use_existing=True` | Original physical File ID retained while branch/reference metadata changes; unrelated files untouched. |
| Staged replacement then `copy()` | Copy contains replacement; source disk remains original; source FileSet remains staged and usable. |
| Replacement source is original path | Snapshot survives deletion or mutation of that path before publication. |
| UID collision | Raises; exact iteration, paths, UIDs, staging state, DICOMDIR, and staged-temp inventory unchanged. |
| Invalid standard dataset | Existing `_recordify()` error behavior; no partial tree/stage mutation. |
| Foreign, removed, or staged-add instance | Refused with no state change. |
| Private-record branch | Refused before reading/writing live File-set data. |
| `clear()` after replacement | Temporary snapshot gone and all replacement state reset. |

Compare datasets without requiring pixel decoder plugins. Assert exact UIDs,
record hierarchy, Referenced File ID behavior, and file existence, but not exact
exception text, private stage keys, UUID filenames, internal call order, or
temporary-directory implementation.

Mutation testing must include at least: public remove/add composition, in-place
leaf edits, no snapshot copy, same-UID rejection, collision check after mutation,
reference UIDs left stale, use-existing rejection, old file not removed under
ordinary write, copy consuming source staging, and clear leaking the snapshot.
Every compiling mutation should break at least two assertions.

## 8. Harness preflight

Verified locally at the pinned commit with CPython 3.14.2:

- `uv sync --group dev` completed using the declared dependency group.
- `uv run pytest tests/test_fileset.py -q` passed **153 tests**.
- `uv run pytest -q` passed **2,642 tests**, skipped **1,722** optional/plugin
  cases, and emitted 22 expected warnings in 111.30 seconds.
- The project declares Python `>=3.10` and classifiers through Python 3.14.

Use an official supported Python image. During the image build, install the
project plus pinned test dependencies needed by the chosen base slice, including
`pytest`, `pyfakefs`, and `pydicom-data`. Do not install GPL optional pixel
plugins or depend on network downloads at test time. Verify both modes with
network disabled after warming dependencies.

`test.sh` must:

- support `base` and `new`, plus both `--output_path PATH` forms;
- remove a stale report before running;
- use pytest without `-x` or other fail-fast settings;
- always write well-formed JUnit XML, including setup/collection failures;
- return pytest's nonzero status on failures;
- contain no problem-authoring or platform vocabulary.

The full suite is acceptable at roughly two minutes, but a documented base
slice may use all of `tests/test_fileset.py` plus directly affected writer tests
if container limits require it. Do not silently reduce base coverage.

## 9. Execution sequence for the handoff agent

1. Use the pinned clean source and a separate solution worktree.
2. Create `DESIGN.md` first with the hard-rule ledger, full audit, replacement
   state machine, ownership/collision precedence, rollback proof, publication
   paths, discriminator matrix, and two-way clause/test ledger.
3. Refresh all issue, PR, Discussion, changelog, and default-head searches. Stop
   if equivalent work appeared after 2026-07-23.
4. Prototype the same-UID replacement through `write(use_existing=True)` and
   `copy()`. Measure the production diff and prove a caller-source snapshot can
   be deleted before publication.
5. Present `DESIGN.md` for approval. Do not create tests, solution, or
   Dockerfile before uniqueness, feasibility, and design gates pass.
6. Write `meta.md` from the approved ledger in natural maintainer prose, ASCII
   only, under 500 words.
7. Build `test.patch`, `test.sh`, and Dockerfile. Prove base passes and new fails
   for the intended missing behavior without the solution.
8. Implement the smallest reference solution, public docs, and any required
   release-note fragment following current upstream convention. Avoid unrelated
   refactors.
9. Run four gates from pristine clones with networking disabled: base pass; new
   fail without solution; new pass with solution; base pass with solution.
10. Run mutation tests, formatting/lint/type checks used by upstream, ASCII and
    leak scans, patch-application checks, and an explicit patch file-list audit.
11. Create `solution.patch`, identical `reference_solution.patch`, and a
    code-derived `solution_approach.md` without calibration language.
12. Calibrate with at least ten independent runs. Current target is 30-40%
    legitimate solves with at least one solve; refresh live platform criteria
    first.

Expected durable artifacts after implementation:

`DESIGN.md`, `meta.md`, `test.patch`, `solution.patch`,
`reference_solution.patch`, `Dockerfile`, `solution_approach.md`, `SUMMARY.md`,
`LEVELS.md`, `ERRORS.md`, `verify/`, and current trajectory indexes/bundles.

## 10. Stop conditions

Stop and report rather than broadening the task if:

- an equivalent upstream or archived replacement task appears;
- correct behavior requires general folder scanning, orphan recovery, or private
  record reconstruction;
- tests have to inspect private staging dictionaries rather than public state
  and on-disk DICOM behavior;
- replacement cannot be made rollback-safe before live state changes;
- the honest solution materially exceeds the 150-200 effective-line target;
- all tested clauses cannot fit naturally inside the 500-word description.
