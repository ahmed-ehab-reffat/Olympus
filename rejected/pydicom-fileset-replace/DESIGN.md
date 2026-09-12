# Design - staged replacement of a managed DICOM File-set instance

Status: rejected at the design gate on 2026-07-23. The architecture and
feasibility probes passed, but the measured implementation is materially below
the latest recorded long-horizon size criterion. No test, solution, metadata,
or container artifact is authorized.

Constraint re-evaluation on 2026-07-30: the LOC minimum changed from 250 to
200. The 72-line prototype remains below the new minimum, so the rejection is
unchanged.

Methodology correction on 2026-08-01: this remains the recorded historical
closure, but one reference prototype is no longer sufficient evidence for a
solver-size verdict. Do not use this rejection as current rating precedent. A
future user-authorized reconsideration would keep the honest task unpadded and
measure independent legitimate solver work; it would not broaden the behavior
just to increase LOC.

## 1. Decision summary and gate verdict

Add `FileSet.replace(instance, ds_or_path) -> FileInstance` as a distinct,
net-neutral staged operation. A successful call snapshots the replacement,
builds its standard directory-record branch, substitutes a new
`FileInstance` at the selected iteration position, and records the original
physical File ID for later publication. It does not compose `remove()` and
`add()`, alter `add()` duplicate handling, mutate the on-disk File-set, or
support PRIVATE branches.

The private stage gains replacement entries that pair the superseded written
instance with the staged replacement. A replacement instance has a temporary
snapshot path but is not reported as an addition. `FileInstance.path`,
`load()`, and `is_staged` recognize a non-null snapshot path; no public
replacement flag or staging representation is added.

This remains a coherent maintainer-facing design, but it is not a viable
long-horizon submission at its measured size. The disposable prototype has 72
strict effective production lines, versus the current workspace requirement of
at least 200 LOC in the median successful solution. The signed-in platform form
could not be inspected during this revision because no in-app browser was
available, so the more conservative recorded criterion governs. A repeated
replacement/cancellation interaction would naturally strengthen staging but
would not close the 128-line gap. Atomic multi-instance replacement and UID
swaps would change the task identity and reverse an explicit scope exclusion.
The candidate is therefore rejected rather than padded or broadened.

## 2. Hard-rule ledger

| Rule | Design decision | Public oracle |
|---|---|---|
| Exact ownership | The target must occur by identity in this FileSet's current yielded instance list. | Foreign and removed targets raise without changing iteration or disk. |
| Written target | Reject targets staged for addition and targets that are themselves staged replacements. A layout-only move remains eligible. | Staged additions fail; an existing non-pydicom File ID can be replaced. |
| Standard records only | Inspect the entire target record ancestry before reading the source and reject if any record type is PRIVATE. | A PRIVATE target fails even when the supplied source path is unreadable. |
| Independent snapshot | Read path sources fully; deep-copy Dataset sources; derive records and serialize the copy to a unique stage file before changing FileSet state. | Mutating/deleting the caller source after `replace()` cannot affect `load()`, `copy()`, or `write()`. |
| Existing validation | Fully materialize `_recordify()` and construct every `RecordNode` before committing. | Missing/empty required elements fail as they do for `add()`. |
| UID integrity | Derive all three referenced UIDs from the replacement and compare the new SOP Instance UID against all current and staged owners except the selected target. | Same UID succeeds; a different free UID succeeds; a collision fails unchanged. |
| Net-neutral view | Replace the selected list element rather than append/remove, and exchange the old/new branches only after all fallible preparation. | Length and iteration position are stable, but yielded record attributes and UIDs are new. |
| Deferred publication | `replace()` never touches the root file or DICOMDIR. | Root file and DICOMDIR bytes stay unchanged until write/copy. |
| Existing layout | `write(use_existing=True)` copies the snapshot over the old physical File ID, writes the new branch, and reloads. | File ID is unchanged, record keys/Uids/content are new, unrelated files survive. |
| Generated layout | Ordinary `write()` removes the superseded physical file, publishes the snapshot at the new branch-derived File ID, writes DICOMDIR, and reloads. | Old UID/reference/file is absent and all new hierarchy/reference values agree. |
| Copy isolation | `copy()` reads the replacement snapshot through the new instance while using the existing copy-safe DICOMDIR path. | Destination contains the replacement; source disk and source staging remain unchanged. |
| Reset/reporting | Replacement entries participate in FileSet and FileInstance staged state, summary counts, load reset, and `clear()` cleanup. | `is_staged` and a non-exact summary expose pending work; clear removes the snapshot and state. |

The retired `FileSetConsistencyFlag` value `FFFFH` is not used. The operation
does not scan directories, recover orphans, rebuild PRIVATE records, track
mutations made through `FileInstance.load()`, or implement multi-instance UID
swaps.

## 3. Upstream and local audit

The audit was refreshed on 2026-07-23. `git ls-remote origin
refs/heads/main` still returns the pinned commit
`dd9f032d15ac5265e1903d1102d19ceb51182506`. The local `source` worktree is
detached, clean, and at that commit. The disposable `probe` worktree is also
detached at that commit but is intentionally modified by the prototype
described in section 12.

GitHub issue and pull-request searches included all states and the terms
`FileSet replace`, `FileSet replacement`, `update existing`, `DICOMDIR
repair`, and `DICOMDIR reconcile`. The exact issue query returned only #1597,
an old malformed-DICOMDIR report. The exact PR query returned #1189, #1217,
#1921, and #2300; none adds replacement. The broader result set was reviewed
for FileSet/DICOMDIR entries, including #2209, #2142, #1958, #1922, #1707,
and #1596. These concern folder import, record validation, documentation,
temporary filenames, invalid DICOMDIR input, or offset failures.

Discussion searches for `FileSet replace`, `FileSet update existing`,
`DICOMDIR repair/reconcile`, and `ReferencedFileID replace` found no matching
proposal. The previously identified #1662 modification question and #1759
roadmap remain adjacent but do not specify managed-instance replacement.
Current generated API documentation lists `add`, `add_custom`, `remove`,
`write`, and `copy`, but no `replace`. Local history, tests, tutorials, API
reference, and `doc/release_notes/v3.1.0.rst` also contain no replacement
operation.

Uniqueness verdict: proceed. No equivalent issue, PR, Discussion, changelog
entry, API, or default-branch change appeared during the refresh. This verdict
only clears upstream eligibility; it does not override the overall size-based
rejection in section 11.

Primary references:

- https://github.com/pydicom/pydicom/pull/1189
- https://github.com/pydicom/pydicom/issues/2209
- https://github.com/pydicom/pydicom/discussions/1662
- https://github.com/pydicom/pydicom/discussions/1759
- https://dicom.nema.org/medical/dicom/current/output/chtml/part03/sect_f.3.2.2.html

## 4. Existing architecture and extension seams

`FileSet._instances` is the public flat ordering and `_tree` is the branch
used to write DICOMDIR. `FileInstance` obtains all public record attributes
dynamically from its leaf and ancestors. The current stage contains additions,
removals, layout movement, identification changes, and a temporary directory.

`add()` creates standard records using `_recordify()`, puts a new instance in
the tree/list, marks it as an addition, and serializes it to the stage.
Duplicate SOP Instance UIDs return the current instance. `remove()` either
cancels an addition or removes an existing instance from the yielded list and
records it for later deletion. These semantics prove that public remove/add
composition cannot replace a same-UID instance.

`copy()` already publishes `instance.path` for every yielded instance and
writes a copy-safe DICOMDIR while restoring temporary record/tree edits.
Making a replacement instance resolve `path` to its snapshot lets this path
work without consuming replacement state. `write()` needs explicit handling:
existing-layout publication must overwrite the remembered original File ID,
whereas generated-layout publication must treat the snapshot as the source
and remove the superseded file.

## 5. Private state and invariants

The stage receives a private replacement mapping. Each entry retains:

- the original, already-written `FileInstance`, whose leaf retains its
  original `ReferencedFileID` and UID metadata; and
- the new `FileInstance`, whose leaf and ancestors contain replacement-derived
  records and whose private stage path names the serialized snapshot.

The replacement leaf initially receives a deep copy of the old
`ReferencedFileID`. This is the physical publication destination for
`use_existing=True` and makes the pre-publication object resolve its generated
`FileID` independently of its original location. The old and new objects are
sufficient to recover both source and destination; no second UID index is
needed.

Invariants after a successful `replace()` are:

1. The new object occupies exactly the old object's index in `_instances`.
2. The new branch is present in `_tree`; the old branch is absent.
3. Exactly one replacement entry connects old and new.
4. The new snapshot exists and is the data returned by `new.load()`.
5. Neither object is in the addition/removal stages.
6. Current/staged final SOP Instance UIDs are unique.
7. The root file and DICOMDIR are byte-for-byte untouched.

## 6. State machine and validation precedence

```text
written current target
        |
        | replace(source)
        v
validate target -> isolate source -> derive/validate records -> check UID
        |                                                   |
        | any failure                                       | collision
        +------------------------> unchanged <---------------+
        |
        v
serialize unique snapshot
        | failure: unlink attempted snapshot only
        v
exchange list/tree and record replacement
        |
        +--> clear/load: discard snapshot and all replacement state
        |
        +--> copy: publish snapshot to destination; source stays staged
        |
        +--> write(use_existing=True): overwrite old File ID; reload
        |
        +--> write(): delete old physical file, publish generated File ID; reload
```

Checks occur in this order:

1. Identity membership in this FileSet's currently yielded instances.
2. Written eligibility: not an addition and not an uncommitted replacement.
3. PRIVATE anywhere in the existing target branch.
4. Read the path source or deep-copy the Dataset source.
5. Materialize `_recordify()` output and construct all nodes/keys.
6. Check the replacement SOP Instance UID against current instances and staged
   removals, excluding only the selected target.
7. Serialize to a unique stage path.
8. Set the old physical File ID on the new leaf and commit the in-memory
   exchange.

This precedence makes ownership/private failures independent of source I/O,
preserves existing `_recordify()` error behavior, and ensures collision
refusal creates no temporary file.

## 7. Rollback proof

Before step 7, work is confined to local datasets, records, nodes, and a new
instance not attached to the FileSet. Reading, deep copy, required-element
validation, reference UID lookup, node key validation, and collision checks
therefore cannot alter iteration, tree state, stage state, or disk.

Serialization targets a new UUID-named file in the existing temporary
directory. Its exception handler unlinks only that path, including a partial
file. No stage entry points at it yet. Existing staged files and the live root
are never candidates for cleanup.

After serialization, all externally fallible work is complete. The commit is
a bounded sequence of deterministic in-memory operations: remember the list
index and old File ID, detach the validated old leaf, attach the fully
validated new leaf, replace one list slot, and insert one mapping entry. Node
constructors have already forced every key access that `RecordNode.add()`
requires. No live filesystem operation occurs in this commit section.

Consequently every specified read, validation, private-scope, ownership,
collision, and serialization failure returns the FileSet to its exact entry
state. Publication failure is not promised to be transactional by the
existing `write()` API and is outside this method-level rollback guarantee.

## 8. Publication algorithms

### Existing layout

Replacement is net-neutral, so it is not included in the existing
`use_existing=True` addition rejection. Apply ordinary removals first. For
each replacement, copy its snapshot to the root joined with the old leaf's
validated `ReferencedFileID`; then write DICOMDIR from the already exchanged
tree and reload with orphan checking. The new leaf keeps that same File ID.

### Generated pydicom layout

Before collision/move planning, unlink each superseded old physical file; its
replacement is already safe in staging. Exclude replacement old paths from
the set of live move sources so collision protection never overwrites a
replacement's snapshot state. In the main publication loop, additions and
replacements copy from their stage paths; unchanged instances move from their
old paths. Set every leaf's `ReferencedFileID` to its generated `FileID`, write
DICOMDIR, and reload.

### Copy

The tree and yielded list already represent final replacement metadata.
`copy()` uses the replacement instance's snapshot-aware `path`, assigns
generated File IDs only for the duration of copy-safe DICOMDIR writing, and
restores them. It never removes a replacement entry or snapshot, so the
source remains staged and its root remains unchanged.

## 9. Discriminator and mutation matrix

| Incorrect implementation | Decisive observations | Minimum killed assertions |
|---|---|---|
| Public remove then add | Same-UID replacement and stable length/new identity | New content; returned instance identity |
| Mutate old leaf in place | Old target object remains yielded and hierarchy may be stale | New instance identity; changed Patient/Study/Series keys |
| Retain caller Dataset/path | Delete/mutate source after replace | Published data; replacement `load()` data |
| Reject same UID | Same-UID existing-layout case | Call succeeds; one resulting UID |
| Check collision after exchange | Before/after public snapshot plus anchored temp inventory | Iteration/tree metadata; anchored stage inventory |
| Leave reference UIDs stale | Changed SOP Class/Instance/transfer syntax | Three leaf reference fields; loaded file metadata |
| Treat replacement as addition | Existing-layout write | No rejection; original File ID retained |
| Do not delete old generated file | Changed hierarchy/UID ordinary write | Old path absent; only one managed file |
| Consume source stage in copy | Copy followed by source inspection/write | Source `is_staged`; source disk bytes |
| Leak on clear | Capture replacement stage path then clear | Path absent; `is_staged` reset |

## 10. Two-way clause/test ledger

| Clause | Planned behavior tests |
|---|---|
| 1. Public method/source types | Dataset, string path, and PathLike source cases; returned `FileInstance`. |
| 2. Exact written ownership | Foreign, removed, staged-add, staged-replacement refusals; moved written target success. |
| 3. Standard derivation/private refusal | Invalid standard data rollback; PRIVATE ancestry refusal before bad-source I/O. |
| 4. Snapshot | Dataset mutation, source deletion, and source-equals-old-path cases before copy/write. |
| 5. Net-neutral public view | Stable length/order, new object identity/attributes, staged state, unchanged root bytes. |
| 6. New records/references | Changed patient/study/series/record type and all three reference UIDs in DICOMDIR. |
| 7. Same/change/collision UID | Same UID in existing layout; free changed UID in both writes/copy; collision rollback. |
| 8. Failure atomicity | State oracle around read, validation, serialization, private, ownership, and collision failures. |
| 9. Existing-layout publication | Same and changed UID retain old File ID; unrelated sentinel and instance files unchanged. |
| 10. Generated publication | Changed hierarchy derives new File ID; old UID/reference/file absent. |
| 11. Copy | Destination replacement plus source stage/root byte preservation and later source usability. |
| 12. Clear/reporting | FileSet/FileInstance staged state and summary presence; clear deletes snapshot and resets state. |

Reverse coverage by test family:

| Test family | Clauses covered |
|---|---|
| Same UID plus `use_existing=True` | 1, 4, 5, 6, 7, 9, 12 |
| Changed UID ordinary write | 1, 5, 6, 7, 10 |
| Changed UID existing-layout write | 5, 6, 7, 9 |
| Staged replacement then copy | 4, 5, 6, 7, 11, 12 |
| Source alias/deletion/mutation | 4, 8, 9, 10, 11 |
| Collision and invalid dataset rollback | 6, 7, 8 |
| Ownership/staging/private refusals | 2, 3, 8 |
| Clear and summary | 4, 12 |

Tests use only public FileSet/FileInstance behavior and `dcmread()` of the
published format. For a deterministic staged-file rollback oracle, the setup
first adds one unrelated public instance and retains the returned
`FileInstance`. Its exposed `path` provides a stable anchor, so the helper can
inventory exactly `Path(anchor.path).parent` before and after the failing
`replace()` call. The anchor, its bytes, and the complete child entry set must
remain unchanged. This never inventories the process-wide temporary directory,
does not inspect private stage keys, and does not assert UUID names. Other
tests will not assert exact exception text, exact summary prose, or internal
call order.

## 11. Production scope, effective size, and rejection

The reference implementation should remain concentrated in
`src/pydicom/fileset.py`: one method, a private replacement stage entry,
snapshot-aware `FileInstance` access, reset/reporting changes, and small
branches in both write modes. Documentation belongs in
`doc/tutorials/filesets.rst`; the generated API reference already exposes
class methods. One enhancement bullet belongs in
`doc/release_notes/v3.1.0.rst` following current convention.

The prototype diff contains 100 raw added lines in one production file. After
excluding blank lines and comment-only lines, 85 remain; excluding the 13-line
public method docstring leaves 72 strict effective implementation lines. The
count is code-derived from the zero-context Git diff and Python AST docstring
ranges. Tests and documentation are not included.

The current signed-in submission form could not be checked because the browser
surface was unavailable. The local calibration policy, updated on 2026-08-01,
records the long-horizon criterion as at least 2 files, 20 agent messages, and 200
LOC in the median successful solution. Seventy-two reference lines provide no
credible path to that median. Adding repeated replacement or cancellation
semantics is maintainer-shaped, but an honest implementation estimate remains
well below 200. Expanding to atomic multi-instance replacement, UID swaps,
orphan recovery, or PRIVATE branch reconstruction would create a materially
different task and violate the approved scope.

Verdict: reject this candidate at the design gate. Preserve this design and
feedback as reusable repository research, but do not create `meta.md`, tests,
patches, a Dockerfile, or calibration runs unless a later live platform
criterion materially changes and a new design review explicitly reopens it.

## 12. Prototype gate evidence

A disposable implementation in `work/pydicom-fileset-replace/probe` changes
only `src/pydicom/fileset.py` and measures exactly 100 added and 6 removed raw
lines. It is intentionally not a durable solution artifact. The clean pinned
`work/pydicom-fileset-replace/source` worktree remains unmodified.

The prototype proves:

- same-UID replacement through `write(use_existing=True)` keeps the original
  physical File ID while publishing new file data and record keys;
- caller Dataset mutation after `replace()` does not affect the snapshot;
- `copy()` publishes the replacement while the source FileSet remains staged
  and its on-disk file stays unchanged;
- a path source equal to the old managed file can be deleted after staging and
  is recreated correctly by existing-layout publication;
- changed-UID replacement can change from a four-level IMAGE branch to a
  one-level PALETTE branch under ordinary `write()`, with the old nested file
  removed and all three reference UIDs updated;
- UID collision refusal preserves yielded object identity, UIDs, paths,
  staging state, DICOMDIR bytes, and all managed file bytes; and
- `clear()` deletes the replacement snapshot and resets length/staging.

The reproducible regression command is:

```text
PYTHONPATH=src .venv/bin/python -B -m pytest tests/test_fileset.py -q -p no:cacheprovider
```

It passes all 153 tests from the modified probe. The prototype therefore meets
the feasibility, rollback, publication-mode, snapshot, and copy-isolation
gates, but it fails the production-size/long-horizon gate recorded in section
11. Passing architectural probes does not override that rejection.
