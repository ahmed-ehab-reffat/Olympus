# feedback.md - afero-overlay-deletions

Repo: https://github.com/spf13/afero (Go, Apache-2.0, 6.7k stars, default branch `master`,
last real source commit 2026-06-09).
Base: `768f1fb0e5535b77d90e44c531aacd652aabd96a`
Tier: Olympus. Shape: O-Composite-extend (the whole `CopyOnWriteFs` method set plus the shared
`UnionFile` directory merge are rewritten under the existing composite tests).

## Attempt history

### R1 - pick gates (2026-07-28)

The user asked for a fresh repo never used locally and a new hard feature, and deferred the repo
choice, so discovery ran autonomously. Candidates screened and dropped before this one:
mochi-mqtt and ergo (goroutine-driven, flakiness gate), pubgrub (MPL-2.0), resolvo (221 stars),
vega-lite (5.4k, household name for its niche), OpenTimelineIO (C++ core), atopile and skidl
(EDA-as-code is a genuinely fresh domain but both need external component or symbol libraries at
test time, so Environment Quality is hostile), mwparserfromhell (every attractive feature is
MediaWiki-spec transcription, the KNOWING-class death), Cwerg (dual Python and C++ implementations,
parity tests), lezer (moved to Codeberg, so the exclusivity search is structurally blind),
kagome and kin-openapi-style inverses (recallable), olebedev/when (last commit 2025-03, recency
gate), avo and mun (already in `SATURATED-REPOS.md` section C).

afero cleared every gate:

- **Vanilla suite in the real base image first**, offline (`--network none`) and non-root:
  5 packages ok, exit 0, ~4s. Run twice, identical. `gcsfs` and `sftpfs` carry their own `go.mod`
  so `go test ./...` in the root module never reaches them and never needs the network. The root
  module has exactly one dependency, `golang.org/x/text`. This is the cheapest lethal gate and it
  was run before any design work.
- **Behavioural F2P gap, and a bigger one than expected.** A probe on base showed four separate
  wrong answers: `Remove` of a base-only file errors, `RemoveAll` of a base-only directory returns
  `nil` and leaves the directory in place, `Rename` of a base-only file returns `EPERM`, and
  `Remove` of a file present in BOTH layers returns `nil` while the base copy silently resurfaces
  in `Stat` and in listings. The last one is a genuine silent bug in current afero.
- **Cold.** `copyOnWriteFs.go` and `unionFile.go` have no commits touching deletion behaviour; the
  recent repo activity is dependabot bumps, an SMB backend and a readonly Mkdir fix.
- **Exclusivity.** `gh pr list -R spf13/afero --state all` and the issue list were searched for
  `copyonwrite|cow|union|delete|remove|whiteout|overlay|layer`. The only hits are PR #587
  (MemMapFs Remove on non-empty directories), PR #619 (an unused parameter in `copyFile`) and
  issue #565 "Union mount", a user question closed with a community answer and no maintainer
  position. Nothing implements or proposes overlay deletions. Every hit was opened, not triaged by
  title, per the redb #1113 lesson.
- **Dedup.** No afero problem and no union / overlay / copy-on-write filesystem problem exists in
  `Aprroved/`, `problems/`, `rejected/`, `Hagora/` or the Olympus dirs (grep by repo name and by
  feature class). `go-diskfs` is filesystem images, `fjall` and `redb` are storage engines.
- **Saturation.** 6.7k stars is above the presumed-saturated line, which is the one soft gate this
  pick does not clear cleanly. The judgement call, logged here deliberately: the platform's
  over-used set is the author-obvious hosts for a whole category (clean VMs, SQL tools, policy
  languages), and a filesystem-abstraction plumbing library is not that. The evidence for it is
  the pick itself: a silent wrong-answer bug in `CopyOnWriteFs.Remove` has sat there untouched,
  which is not what a heavily mined repo looks like. Verify the platform sub-count on the
  "Learn more" page before submitting; if it is over the cap, the same feature re-homes onto a
  smaller VFS library without redesign.
- **Flakiness.** Everything this touches is in-memory. The new tests take no clock reading, no
  randomness, no ordering assumption, and no network. The one real ordering hazard was in the repo
  already: `defaultUnionMergeDirsFn` returns map iteration order, so afero's merged listings are
  non-deterministic today. The feature makes listings sorted, which removes that hazard rather
  than working around it.

### R2 - design

`DESIGN.md` holds the contract (section 5) and the trap matrix (section 11). The difficulty is
deliberately not the idea, which fairness forces into the prompt anyway. It is where the visibility
decision lives and how many code paths have to agree with it: one predicate (`hidden`) drives every
method, the directory merge, the emptiness test behind `ENOTEMPTY`, `Rename`'s copy-up and
`Flatten`, so a local fix in one place regresses another. The traps that matter:

1. `Remove` of a path present in both layers has to hide it, not just drop the layer copy. The
   naive code returns `nil` and the failure only surfaces at a later `Stat`.
2. A directory that is removed and made again has to keep its base contents hidden for good. A
   per-path removal record cannot express this; something has to mark the rebuilt directory
   opaque. The failing assertion is about a child reappearing, not about the directory.
3. The bookkeeping must never surface. The old `Open` returns the raw layer handle when the base
   has no such directory, so a listing that has nothing to do with deletion leaks marker files.
4. `OpenFile` with `O_CREATE` on a removed base file must not copy the base bytes up. `isBaseFile`
   is still true for that path, so the natural code path resurrects the content.
5. `Remove` on a directory has to weigh the merged view, not the layer, when deciding emptiness.
6. Removals live in the layer, so a fresh overlay over the same layer starts out with them.
7. The old mode has to come through the rewrite byte-identical in behaviour; 176 existing test
   nodes are the check.

### R3 - implementation

`overlayDeletions.go` is new: marker naming, the `hidden` predicate with its ancestor walk, record
write and clear, directory sealing, the merged view, `mkdirAllInLayer` (which revives and seals
along a path), `Deleted`, `Restore` and `Flatten`. `overlayDir.go` is new: the directory handle
that answers `Readdir` from the merged view while keeping `UnionFile`'s chunking and EOF contract,
plus the recursive copy-up behind `Rename`. `copyOnWriteFs.go` gains the mode flag, the new
constructor, and a visibility guard on every method. `unionFile.go`'s default merge is now sorted.

One fix was forced during the first test run, in the reference rather than the tests:
`mergedInfos` checked the seal on the directory itself but not on its ancestors, so rebuilding
`/tree/a/b` after removing `/tree/a` let `/tree/a/b/leaf.txt` reappear. The merge now asks the
same `hidden` predicate every other path asks, which is the point of having one kernel.

Scope was raised once. The first complete implementation measured 425 human-effective, under the
450 design target, so `Restore` and `Flatten` were added. Both are genuine overlay capabilities
with their own logic and their own tests, not padding; `Flatten` in particular exercises the merged
view end to end and works on a plain overlay too.

### R4 - validation

- Vanilla suite green in the base image before any work started, twice, offline and non-root.
- Base mode 176 nodes / 0 failures with `test.patch` alone AND with both patches: no regressions.
- New mode 235 nodes / 235 failures with `test.patch` alone. The test package lives in its own
  directory so a base-mode build is unaffected by it; `test.sh` detects that the new package does
  not compile and synthesises one failing node per test function, named exactly as the real ones.
- New mode 235 nodes / 0 failures with both patches.
- Both apply orders clean against a pristine base checkout, and both patches unapply cleanly.
- Three runs of each mode in the container: identical counts and identical node sets.
- `go build ./...` and `go vet ./...` clean.
- LOC: 942 raw / 595 human-effective across 4 files (2 modified, 2 new).
- No `shipd` or `datacurve` anywhere; `test.sh` is mode 100755 in the patch; both patches are
  ASCII with LF endings; `meta.md` is 472 words and pure ASCII.

### R5 - hardening round (asked for: harder, still fair)

Three levers, chosen at the composition layer rather than by adding tests. HARDENING is explicit
that test-count padding RAISES the pass rate, so nothing here is breadth; each lever is a new
interaction between rules that were already stated.

1. **Directory metadata preservation (S3, the new lead misdirection).** Recording a removal has to
   put a directory in the layer to hold the bookkeeping, and the obvious `layer.MkdirAll(dir, 0777)`
   silently changes the permissions and modification time the overlay reports for the parent. The
   contract is now stated ("a directory the overlay puts in the layer for its own sake keeps the
   permissions and modification time the base gives it, while one the caller makes gets the
   permissions the caller asked for") and it does not reveal the fix: the discovery is that
   recording a removal creates directories at all. It also pairs with the opposite requirement -
   fixing it globally breaks the "made again" case, where the caller's mode must win. 5 kills.
2. **Removals nest (S2 composition, no new behaviour invented).** Removing a directory no longer
   wipes the layer subtree; the removals recorded under it survive, so restoring the directory
   brings back everything except what was removed on its own. This turns two previously vacuous
   rules into real discriminators: `Deleted`'s pruning clause could not fire before (a nested
   record could not exist), and the merged listing now has to re-check layer entries, because a
   directory the layer keeps only for bookkeeping must not show up. 3 + 3 + 1 kills.
3. **Machinery riding (S4, one Rule-7 sentence).** "Everything afero already does with a filesystem
   keeps working over the overlay" - tested through `afero.Walk`, `afero.ReadDir`, `afero.Glob` and
   the `io/fs` adapter `afero.NewIOFS`, whose `ReadDir` takes a different code path (it type-asserts
   `fs.ReadDirFile` first). One general sentence, instances left for the solver to derive.

**Trap-proof (the part that matters).** Every trap was mutation-proven: the natural-but-wrong
implementation was written into a scratch copy of the reference and the suite re-run. Counts are in
`DESIGN.md` section 11. This also caught two of my own traps that were fiction:

- Handing back the raw layer handle for a directory that exists only in the layer: **0 kills**. Such
  a directory can never hold bookkeeping, because a removal is only recorded where the base has the
  path. The meta over-claimed ("that ordering holds for every directory the overlay opens"), so the
  claim was narrowed to what is actually asserted.
- Stripping bookkeeping names from the layer listing: **0 kills**, fully covered by the per-entry
  visibility check. Kept only as the cheap path that avoids a Stat per entry.

Without the mutation pass both would have shipped as believed-hard tests that no agent can fail,
which is exactly the dilution HARDENING warns about.

Net after R5: 823 raw / 527 human-effective / 4 files, 103 tests, 11 traps with measured kill
counts from 1 to 12, meta 504 words.

### R6 - AI pre-checks (test quality + description quality)

Both checks came back with changes requested. All findings taken, none contested.

**Test quality (2 warnings).**

- `Flatten` is described as carrying modification times and nothing asserted it. Added
  `TestOverlayFlattenKeepsModificationTimes`, pinned against an explicit `time.Unix` stamp on the
  base so it stays deterministic, and mutation-proved it (dropping the `Chtimes` in the copy breaks
  exactly that test). This was a real bidirectional-alignment hole: a described behaviour with no
  discriminator.
- Two tests reached into the layer and the base to assert where bytes had landed, which pins an
  implementation choice the description never makes. Both were rewritten to observable behaviour:
  the failed-`chmod` test now asserts the path stays hidden and the parent listing is unchanged,
  and the copy-on-write test now writes through the overlay and asserts the overlay shows the new
  content while the base still shows the old. The "written into the layer" requirement keeps its
  discriminator in `TestOverlayRemovalsSurviveAFreshOverlay`, which is observable.
  `TestOverlayRemovalDoesNotTouchTheBase` still reads the base directly and was left alone: the
  base is a caller-owned input, so "the base is never written" is behaviour, not an internal.

**Description quality (3 high, 2 medium).** Removed the restatement of current behaviour ("nothing
that lives only in the base can be taken away ..."), the "leave the existing mode exactly as it is"
filler, the "Add three methods" meta-orientation, and the broad "everything afero already does keeps
working" guarantee. The last one had been a deliberate Rule-7 machinery sentence, but the tests it
was meant to license (`Walk`, `ReadDir`, `Glob`, `NewIOFS`) assert consequences of the stated `Open`
and `Stat` rules rather than extra requirements, so they stay fair without it.

The one suggestion I did not take literally was "remove: that ordering holds in both modes". Sorted
listings are a CHANGE to the old mode, not a restatement, and `TestOverlayPlainModeListingIsSorted`
needs the contract. Instead of a reiterating sentence the rule is now written mode-neutrally: "An
overlay in either mode reads a directory as ...". That satisfies the redundancy point and keeps the
test anchored.

Old-mode regression tests lost their explicit sentence and were kept: they assert existing,
unchanged behaviour, which the description-quality check itself called an obvious default.

Net after R6: meta 460 words, 104 tests, 823 raw / 527 human-effective, all four cells re-validated.

### R7 - AI pre-checks, second pass

Test quality came back all-OK on the four graded points, with one note; description quality still
requested changes on one HIGH.

**The HIGH was a real defect of mine.** When `Restore` was added in R3 I put it in the hidden-path
list, so the description said both "`Restore` drops the removal recorded at a path" and "a hidden
path is gone from ... and `Restore`, which report `os.ErrNotExist`". A hidden path is exactly where
`Restore` must SUCCEED. Both halves were half-true, which is why it read as a contradiction: a path
hidden by its own record restores fine, a path hidden only because an ancestor is removed has no
record of its own and errors. The `Restore` sentence already says that correctly, so `Restore` came
out of the list. No test changed; the implementation was always right.

**Taken as suggested:** dropped "contents and" from `Flatten` (writing contents is implied by
"writes the view"), and dropped the rhetorical lead-in before the permission and mod-time rules.

**Restructured rather than deleted:** "and from directory listings" was flagged as redundant with
the listings paragraph. It was not redundant - that paragraph described merging, ordering and
bookkeeping but never said hidden entries are excluded, so deleting the clause would have stranded
`TestOverlayListingOmitsRemovedEntries`,
`TestOverlayRemovedDirectoryDisappearsFromParentListing` and
`TestOverlayDirectoryKeptOnlyForBookkeepingIsNotListed`. The exclusion moved into the listings
paragraph instead ("minus anything the overlay hides"), which removes the repetition and keeps
every test anchored.

**Declined, with reason:** "delete: an overlay in the old mode hides nothing and restores nothing"
(MEDIUM, non-blocking). This is not a backward-compatibility default. `Deleted` and `Restore` are
NEW methods, and what they do on an overlay built by the OLD constructor is new behaviour that
nothing else in the description implies. Deleting it would strand
`TestOverlayPlainModeReportsNoDeletions` and `TestOverlayRestoreInPlainModeIsNotExist` as hidden
requirements, which is the Test Fairness failure in the opposite direction.

**Test note taken:** three plain-mode tests type-asserted the concrete `*afero.CopyOnWriteFs` to
reach the new methods. They now assert a local interface carrying just `Deleted`, `Restore` and
`Flatten`, so nothing depends on what `NewCopyOnWriteFs` returns concretely.

Net after R7: meta 444 words, 104 tests, 823 raw / 527 human-effective, all four cells re-validated,
3x deterministic.

### R8 - Test Fairness FAIL (4 of 104) + coverage advisories

**Verdict was FAIL and all four calls were right.** Two needed the implementation changed, not the
tests.

1. `TestOverlayRenameIntoARemovedDirectory` required `Rename` to rebuild a hidden destination
   parent. Nothing in the prompt said that, and standard rename semantics say the opposite: the
   destination parent has to exist. My implementation was silently reviving it, which is the
   non-standard choice. Fixed in the REFERENCE: `Rename` now checks the destination parent through
   the overlay first and reports `os.ErrNotExist` when it is hidden or missing, before any copy-up
   happens, so a refused rename leaves nothing behind. The test now asserts the standard outcome
   plus source-untouched. No new prompt sentence needed - the checker itself named standard rename
   semantics as the fair baseline.
2. Three `Restore` error tests pinned `*os.PathError` with `Op: "restore"`. The prompt promises only
   `os.ErrNotExist`, and there is no `restore` convention anywhere in afero to infer the wrapper
   from. Relaxed to a sentinel-only `ovlRequireNotExist` helper. `ovlRequireGone` (wrapper + exact
   Op) stays for the operations the prompt DOES pin that way, and the checker rated all of those
   fair.

**All four coverage advisories added (9 tests), each mutation-checked:**

- Hidden descendants across every operation, not just `Stat`: two tests walking `Open`, `OpenFile`,
  `Lstat`, `Chmod`, `Chown`, `Chtimes`, `Rename`, `Remove` on a child and on a deep leaf.
- `Flatten` metadata breadth. This one found a real gap: the contract says modification times are
  carried, and directories were not getting theirs. Fixed in the reference (the directory stamp is
  written after its children land, so nothing bumps it afterwards) and covered for directories,
  layer-created files and modified base files.
- `Deleted` path formatting: removal by a non-clean path and by a relative path both report the
  cleaned, overlay-rooted form; nested paths come back in sorted order.
- `Flatten` failure propagation against a destination that refuses writes. Worth keeping even
  though it scores 0 against narrow mutations: it is the only test that fails when every
  destination error is swallowed.

**A near-miss worth recording.** The first re-validation came back 1 of 113 failing WITH the
solution applied, and the reference was fine - the PATCH was stale. New files are diffed from the
git index, so every edit made after the last `git add` is silently dropped from `solution.patch`.
`patch_gen` now re-stages the new files itself before diffing. Nothing but the full four-cell matrix
against a pristine checkout would have caught this; running the suite in the working tree passes
happily while the shipped patch is wrong.

Net after R8: 113 tests, 831 raw / 532 human-effective, meta unchanged at 444 words.

### R9 - Test Fairness FAIL (4 of 113), all one root cause + 3 more advisories

All four unfair tests traced to the same two spec gaps, and both were mine. The tests were right
about the behaviour; the prompt did not pin it.

1. **`Deleted` pruning (three tests).** The prompt said "no entry for a path only out of sight
   because a directory above it is". That phrasing is about WHY a path is hidden, so a child with
   its OWN recorded removal is not covered by it - and my implementation prunes it anyway. The
   checker was right that two designs were open. Restated as a structural property of the output
   instead: "reports where the overlay hides something ... and never an entry that sits under
   another entry it reports". That pins the minimal-reporting policy without saying how records are
   stored, and it keeps the pruning trap (3 kills) load-bearing.
2. **`Restore` of a directory made again (one test).** "Hidden for good" fixes the OUTCOME (base
   children stay hidden) but not whether `Restore` errors or is a silent no-op. Now stated: "a path
   with no removal recorded, a directory made again among them, reports `os.ErrNotExist`".

No implementation change was needed for either; both were description repairs. Meta 444 -> 464
words, still under cap.

**All three coverage advisories added (8 tests), each mutation-checked:**

- **Restore persistence:** a successful `Restore` survives a fresh overlay over the same base and
  layer, including the case where one of two removals is restored and the other must remain.
- **Restore below a hidden ancestor:** the checker asked me to SPECIFY this, not just test it. Added
  the sentence "Restoring a path that is still under a removed directory drops its record and leaves
  it out of sight", plus tests for both halves: the record goes (so `Deleted` reports only the
  ancestor) and the path stays invisible until the ancestor is restored too, after which the child
  is back.
- **Mixed-tree Rename:** a source directory combining a base-only child, a layer override, a
  layer-only addition, a nested base subtree and an independently removed child. Three tests pin the
  complete destination view, the removed child staying gone, and the source being hidden with the
  base untouched. These are the strongest rename tests in the suite: mutating
  `materializeSubtree` to walk the base instead of the merged view, or to skip stripping
  bookkeeping, breaks them and nothing else.

Net after R9: 120 tests, 831 raw / 532 human-effective, meta 464 words.

### R10 - coverage advisories only (Test Fairness clean)

No unfair tests this round; three advisories, all added (7 tests), each mutation-checked. Two needed
the prompt tightened first.

- **`*os.PathError.Path`.** The helper checked type, Op and the sentinel but never that `Path` names
  the requested path. The prompt only promised "naming the operation", so asserting `Path` would
  have been the same over-specification that failed in R8. Prompt now says "naming the operation and
  the path"; the shared helper checks `Path` (which strengthens ~30 existing tests at once) and two
  dedicated tests pin it for a directly removed path and for an ancestor-hidden descendant. Mutating
  the error to name the parent instead breaks 14 tests.
- **`Deleted` after a directory is made again.** This exposed a wording problem: "reports where the
  overlay hides something" is ambiguous once a sealed directory hides its base contents while the
  directory itself is visible. Re-based the rule on records, which the prompt already uses as
  vocabulary ("the removal written into the layer", "drops the removal recorded at a path"):
  "reports the paths with a removal recorded against them". A directory made again has no removal
  recorded (the `Restore` sentence already says so), so it drops out consistently. Also pinned when
  a removal is recorded at all - "where the base still shows it" - so the layer-only case is
  determined rather than inferred. Mutating `Deleted` to also report sealed directories breaks 2.
- **Rename destination conflicts.** Added "Renaming onto a path the overlay already shows replaces
  it" plus three tests: onto a base-only target, onto a target present in both layers (with a
  follow-up removal proving the base does not resurface underneath), and a layer-only source onto a
  visible base target. Mutating `Rename` to refuse an existing destination breaks 4.

**Deliberately not covered: file/directory type conflicts in `Rename`.** The advisory asked for
them, but the prompt does not define them and neither does the repo - probing showed the current
behaviour is whatever `MemMapFs.Rename` does (a file silently replaces a visible directory), which
is also what the OLD mode does, so it is backend semantics rather than something this feature
introduces. Pinning it would need a conflict matrix in the prompt, and testing it unstated is
exactly what failed in R8 and R9. Left undefined on purpose.

**Infrastructure note:** the flakiness loop reported failures mid-round that were a full disk, not
tests. Re-ran after pruning on a rebuilt image from a pristine base: 3x identical, all green.

Net after R10: 127 tests, 831 raw / 532 human-effective, meta 486 words.

### R11 - Test Fairness FAIL (4 of 127) + 3 advisories

All four unfair tests were `Deleted()` exact-slice co-assertions in situations the prompt left open.
Two spec gaps, both mine, both fixed in the description; the tests were right about the behaviour.

1. **Layer-only rename sources (2 tests).** The prompt said `Rename` "records the source removed"
   without qualification, so a literal reading demands a record even when the source lives only in
   the layer and there is nothing in the base to hide. My implementation records nothing there,
   which is correct but unstated. Qualified it the same way the removal rule was qualified in R10:
   "records the source removed where the base still shows it". The two readings now agree.
2. **Making a hidden path exist again (2 tests).** File recreation clearing the record, and a rename
   onto a hidden target clearing that target's record, are the same rule, and it was only stated for
   directories, obliquely, inside the `Restore` sentence. Promoted to a general rule where "made
   again" is described: "Making a hidden path again drops the removal recorded against it". The
   directory parenthetical inside `Restore` came out as redundant once the general rule exists.

**All three advisories handled (5 tests):**

- **Flatten permissions.** Probing showed `Flatten` already carries file and directory permissions,
  but the prompt only promised modification times, so asserting them would have been the R8 mistake
  again. Prompt now says "permissions and modification times included"; three tests cover a base
  file, a layer file and nested directories. Mutations that drop either break them.
- **Rename metadata.** This one found a real defect: the rename copy-up created the destination with
  `layer.Create`, so a base-only file arrived at the new name with mode 0666 instead of its own.
  Fixed in the reference (create with the source's permissions, then chmod and chtimes) and stated:
  `Rename` moves "permissions and modification time with it". Two tests, one for a file and one for
  a child inside a moved tree; reverting the fix breaks exactly those two.
- **Restore error structure.** Not changed, deliberately. The advisory itself says the current
  `errors.Is(os.ErrNotExist)` check is "appropriately permissive for the present prompt", and
  pinning a `*os.PathError` shape for `Restore` is precisely what was ruled unfair in R8. Left
  permissive.

Net after R11: 132 tests, 835 raw / 534 human-effective, meta 494 words.

### R12 - coverage advisories only (Test Fairness clean)

Three advisories, all added (5 tests). No reference change was needed this time - probing showed
both behaviours were already right, so the work was stating one of them and testing both.

- **Rename directory-root metadata.** Probed first: renaming a base-only directory already carries
  the directory's own permissions and modification time, because `materializeSubtree` builds it
  through `ensureLayerDir`, which mirrors the base directory, and the layer rename keeps what it
  moves. Already covered by the prompt's "permissions and modification time with it", so a test was
  all that was missing. Dropping the mirror breaks 6 tests.
- **Flatten overwrite behaviour.** Genuinely undefined by the prompt. Probed the reference: it
  writes over what it finds and never deletes. Stated that ("leaving whatever else `dst` holds in
  place") and covered both halves - a conflicting destination file is overwritten, an unrelated file
  and an unwritten sibling both survive, and the destination listing is pinned exactly. Making
  `Flatten` skip existing entries breaks the overwrite test.
- **Restore persistence under an ancestor.** Two tests: the dropped nested record stays dropped
  across a fresh overlay built on the same base and layer, and restoring the ancestor from that
  fresh overlay brings the nested path back; plus a sibling variant proving an unrelated record
  survives the whole sequence.

**Word budget.** The meta was at 494 of 500 before this round, so the new `Flatten` clause had to be
paid for. Compressed three sentences that carried no requirement ("paths that live only in the base
can be taken away and stay away" -> "what lives only in the base can be taken away for good", and
two smaller trims) to buy the eight words. 495 now - there is effectively no headroom left, so any
further rule has to displace an existing one.

Net after R12: 137 tests, 835 raw / 534 human-effective, meta 495 words, reference unchanged.

### R13 - coverage advisories only, and one real bug found

Three advisories, 10 tests added, meta unchanged at 495 words. Everything asserted here derives from
rules already stated, so no words had to be found.

- **Root removal boundary. This one found a genuine bug.** `RemoveAll("/")` reported success, wrote a
  nonsensical marker for the root itself, and hid NOTHING: every child stayed visible and the marker
  was never consulted, because the visibility walk skips the root by construction. Fixed in the
  reference: removing the root removes each of its visible children instead, which is what
  "removing a directory hides everything under it" already promises, and leaves the filesystem root
  itself in place, which it has to be. Now `Remove("/")` gives `ENOTEMPTY` while children show and
  succeeds once emptied, `RemoveAll("/")` empties the overlay, `Deleted` lists the children, and
  making a child again or restoring one behaves exactly as it does one level down. Four tests;
  reverting the fix breaks all four.
- **Rename destination type conflicts.** Probed all three: file onto a visible directory, directory
  onto a visible file, directory onto an existing directory. All three already replace, consistently
  with the stated rule "renaming onto a path the overlay already shows replaces it", so they were
  fair to pin without new wording. Three tests; making `Rename` refuse a cross-kind destination
  breaks two of them.
- **Flatten cross-type conflicts. Deliberately only half-covered.** The advisory asked whether
  `Flatten` replaces the conflict or propagates an error. Probing showed it does neither visibly on
  MemMapFs: `MkdirAll` over a file and `OpenFile` over a directory both succeed silently there,
  while `OsFs` would error. That makes the outcome backend-dependent, so pinning it would be the
  same unfairness that failed in R8. What IS stated and backend-independent is that unrelated
  destination entries survive, so both conflict directions are tested for that and the conflict
  outcome itself is left alone.

Net after R13: 147 tests, 847 raw / 542 human-effective, meta 495 words.

### R14 - Test Fairness FAIL (4 of 147): the root tests I added last round

The four root tests from R13 were flagged, correctly. Fixing the `RemoveAll("/")` bug was right, but
I picked a representation - record each top-level child, leave the root itself - and never said so.
An implementation that records `/` directly satisfies every stated rule and fails all four tests.

Rather than delete them, one sentence makes them fair: "Removing the root removes everything it
shows and leaves the root itself." That single rule determines all four outcomes - children hidden,
`Deleted` listing them, `Remove("/")` succeeding once empty, and `Restore` of a child working -
because each child is then an ordinary removal with an ordinary record.

**Paying for it.** The meta was at 495 of 500, so the twelve words had to come from somewhere.
Compressed six sentences that carried no requirement ("taken away for good" -> "taken away",
"a removal recorded against them" -> "a removal recorded", "never an entry that sits under another
entry it reports" -> "never an entry under another it reports", and three smaller ones) for fifteen
words. 496 now. The easy compressions are gone; anything further has to displace a rule.

**Both advisories addressed, one only in part:**

- **Flatten type-conflict result.** Still not pinning the conflicting path itself, for the second
  time and for the same reason: probing shows MemMapFs silently accepts `MkdirAll` over a file and
  `OpenFile` over a directory while `OsFs` errors, so any assertion about the final conflicting
  entry pins a backend, and stating a rule for it costs words I do not have. What I could
  strengthen fairly, I did: both conflict tests now also flatten into a FRESH destination
  afterwards and pin the complete result, which proves the conflict left the overlay itself
  undisturbed. That is a real discriminator - making `Flatten` mutate the overlay as it writes
  breaks 15 tests.
- **Hidden rename destination diagnostics.** Added a test pinning `*os.PathError` and `Op` of
  "rename" with the `os.ErrNotExist` sentinel. Deliberately NOT pinning `Path`: the prompt's
  wrapper rule is about a hidden path passed to an operation, and here the hidden thing is the
  destination's parent while the argument is the destination, so which path belongs in the error is
  genuinely open. Returning a bare error instead of a wrapper breaks the new test.

Net after R14: 148 tests, 847 raw / 542 human-effective, meta 496 words, reference unchanged.

### R15 - coverage advisories only (Test Fairness clean)

Two advisories, 5 tests, reference unchanged. Word count also unchanged at 496 - the one wording fix
this round was length-neutral.

- **Root-removal persistence.** Fully derivable from rules already stated ("a fresh overlay over the
  same base and layer starts out with the same paths hidden" plus the root rule added in R14), so
  no new words. Two tests: a fresh overlay over the same base and layer sees the root present with
  an empty listing, the former children hidden and the same `Deleted` report; and `Restore` of a
  top-level child works from that fresh overlay. Making the root removal prune the layer without
  recording anything breaks 6 tests.
- **Recreated-file permissions.** The caller-permission rule was written for directories only ("a
  directory the overlay puts in the layer for its own sake takes the base permissions and
  modification time; ONE the caller makes takes what was asked for"), so pinning the permission of a
  recreated FILE would have been unstated. Generalized the second clause from "one" to "what the
  caller makes takes the permissions asked for" - same length, now covers files and directories.
  Three tests: recreation at a removed path, creation under a rebuilt ancestor, and creation inside
  a sealed directory (which also re-checks that the file starts empty there). Ignoring the caller's
  permission breaks all three.

Net after R15: 153 tests, 847 raw / 542 human-effective, meta 496 words.

### R16 - coverage advisories only (Test Fairness clean)

Two advisories, 6 tests, reference unchanged, meta still 496 words.

- **Implicit-directory modification times.** Probed first across all three paths that materialize
  ancestors - an ordinary write, a rename and a removal - on a three-deep tree. Every ancestor
  already keeps the base modification time, so no fix was needed; the gap was purely in coverage,
  since existing tests pinned mtime only on the removal path and only on the immediate parent.
  Four tests now cover mtime on all three paths across three ancestor levels, plus permissions on
  every level of the write path. Dropping the mtime half of the mirror breaks 5 tests, which is the
  point: permissions and modification time were being carried by one call and only one of them was
  pinned deeply.
- **ENOTEMPTY PathError fields.** These were genuinely unfair to assert before this round: the
  "naming the operation and the path" phrase was attached only to the `os.ErrNotExist` sentence, so
  the `ENOTEMPTY` wrapper's fields were unstated. Extended that sentence to carry the same naming
  requirement, and paid the five words back by compressing four phrases that carried no requirement
  ("something that is not there" -> "something not there", "starts out with" -> "starts with",
  "the removal written into the layer" -> "the removal written there", "the bookkeeping the layer
  keeps" -> "the bookkeeping it keeps"). Two tests, one for a directory and one for the root.
  Returning a bare `syscall.ENOTEMPTY` breaks 3.

Net after R16: 159 tests, 847 raw / 542 human-effective, meta 496 words.

### R17 - Test Fairness FAIL (4 of 54 groups): root record granularity

Same area as R14, one level deeper. The R14 sentence pinned what root removal DOES to the visible
tree, but not whether it is recorded as one root-level removal or one per top-level child. A single
root record satisfies every stated rule and would make `Restore("/data")` report not-exist, so the
four assertions that pin `Deleted` as `["/data", "/top.txt"]` and restore individual children were
not determined.

Fixed by making the rule an equivalence instead of a description: "`RemoveAll` on the root is
removing each thing it shows." Nine words replacing twelve, so the budget went DOWN, and it
determines strictly more: each child is an ordinary removal, so each carries an ordinary record,
`Deleted` lists them, `Restore` works per child, and the root itself is never removed and stays
visible. Scoping it to `RemoveAll` also keeps `Remove("/")` under the `ENOTEMPTY` rule, which is
what the reference does. Meta 496 -> 494.

**Both advisories addressed - and the Flatten one is finally covered, because I fixed the cause.**

- **Flatten type conflicts.** Declined twice before on the grounds that the outcome was
  backend-dependent: MemMapFs silently tolerates `MkdirAll` over a file and `OpenFile` over a
  directory, `OsFs` errors. That was true but it was a defect, not a reason. `Flatten` now drops a
  destination entry that is there as the other kind before writing, which makes "writes the view"
  hold on every backend instead of only on permissive ones. Two tests pin the conflicting path
  itself now: a file replaced by the directory (with its children) and a directory replaced by the
  file (with its content). Removing the new guard breaks one; the earlier tests that only checked
  unrelated survivors are kept as the weaker complement.
- **Recreated-file persistence.** Two tests, mirroring the recreated-directory pair: a fresh overlay
  over the same base and layer sees only the recreated layer content with no record left, for a file
  written with content and for one made empty through `O_CREATE`. Leaving the record behind on
  recreation breaks 7 tests.

Net after R17: 163 tests, 860 raw / 549 human-effective, meta 494 words.

### R18 - coverage advisories only, and a second real bug

Two advisories, 4 tests, meta unchanged at 494 words.

- **Flatten destination metadata conflicts. This found a real bug.** `Flatten` was passing the
  view's mode to `OpenFile` with `O_CREATE` and to `MkdirAll`, and BOTH ignore the mode when the
  entry already exists. So flattening into a fresh destination carried permissions correctly - which
  is what the R11 tests checked - while flattening over an existing entry silently left the
  destination's old permissions. The modification time was fine, because that was an explicit
  `Chtimes` call. Fixed by chmodding explicitly in both branches after writing. Three tests: an
  existing file, an existing directory, and an entry that was replaced because it was the wrong
  kind. Each branch was mutated separately after the first attempt hit only the directory path.
- **Rename destination error path.** R14 left `PathError.Path` unpinned for a hidden rename
  destination, reasoning that the hidden thing is the destination's parent while the argument is the
  destination, so which path belongs in the error was open. The check reads the prompt's "naming the
  operation and the path" as settling it on the requested destination, which is what the reference
  already returns, so the assertion is now in. Naming the source instead breaks it.

**Pattern worth noting.** Two rounds in a row the advisory found a real defect in the same shape: a
metadata rule that held on the fresh-write path and silently failed on the overwrite path (rename
copy-up in R11, `Flatten` here). Both were hidden by tests that only ever exercised a clean
destination.

Net after R18: 166 tests, 866 raw / 553 human-effective, meta 494 words.

### R19 - coverage advisories only; one taken, one declined on purpose

Two advisories, 6 tests, reference and meta both unchanged (494 words).

- **Rename persistence.** Free - fully determined by rules already stated (the rename rule plus "a
  fresh overlay over the same base and layer starts with the same paths hidden"). Four tests: a
  base-only file, a base-only tree with its children, a layer-only source, and a rename onto a
  hidden target, each rebuilt over the same base and layer and checked for the moved content, the
  hidden source and the recorded set. Dropping the source removal from `Rename` breaks 10 tests.
- **Flatten partial-failure semantics. Declined, and this one stays declined.** The advisory is
  conditional ("if atomicity or partial-write behaviour is intended"), and it is not: `Flatten`
  walks and writes as it goes, stopping at the first error, which is what any recursive copy does.
  Nothing is silently wrong here, so unlike the last two rounds there is no defect to fix. Stating
  it would cost the last of a 494-of-500 word budget to pin a niche error path, and pinning
  partial-write behaviour without stating it is exactly the R8 mistake. What I did add instead is
  the part that IS determined: a failed `Flatten` leaves the overlay itself usable and correct - a
  second `Flatten` into a good destination produces the complete view - and unrelated destination
  entries survive. Making `Flatten` disturb the overlay on failure breaks the new test.

**Process note:** the first mutation attempts this round reported SETUP FAILED because the shell cwd
had drifted into the test subdirectory, so `$PWD/worktrees/afero` did not exist and Docker mounted
an empty directory in its place. Worth knowing that a bad mount reads as a passing-looking no-op
rather than an error - the mutation harness now uses absolute paths.

Net after R19: 172 tests, 866 raw / 553 human-effective, meta 494 words.

### R20 - coverage advisories only; the Flatten one is now covered

Three advisories, 8 tests, reference and meta both unchanged (494 words).

- **Successful metadata copy-up.** The suite had been testing `Chmod`/`Chown`/`Chtimes` almost
  entirely on hidden paths, so the success path went unpinned. Four tests: each of the three changes
  the overlay while leaving the base untouched and the content intact, plus one that siblings stay
  visible and no removal is recorded by a copy-up. Each of the three copy-up call sites was mutated
  separately, since removing one only broke one test - the first attempt looked like weak coverage
  until the sites were separated.
- **Rename missing source.** Probed first, and the result changed what I asserted: a source that
  never existed produces `*os.PathError` with `Op` "open", not "rename", because it propagates from
  the underlying stat rather than being wrapped like the hidden-path case. Both shapes are
  defensible and the prompt only speaks to hidden paths, so the tests pin the parts that any
  implementation reaches - `*os.PathError`, the source in `Path`, the `os.ErrNotExist` sentinel and
  no destination appearing - and deliberately leave `Op` alone.
- **Flatten mid-tree failure. Taken this time.** I declined this twice, most recently arguing it
  would cost words to state partial-output semantics. The check's sharper framing made the way
  through obvious: a destination that accepts some writes and then refuses one exercises error
  propagation THROUGH the recursion, which is already fair, without pinning what survives the
  failure. Added a small destination wrapper that fails on one nested path, and two tests: the
  failure is reported rather than swallowed, and the overlay still flattens completely into a good
  destination afterwards. Making `Flatten` continue past a failed child breaks 4 tests. The
  partial-output question itself stays unstated and unasserted, which is the same position as
  before - only now the reachable half is locked down.

Net after R20: 180 tests, 866 raw / 553 human-effective, meta 494 words.

### R21 - Test Fairness FAIL (1 of 180): my own flagged risk, shipped anyway

One test, and it was the exact assertion I described in the R20 note as the part that "stays
unstated and unasserted". It was not unasserted. `TestOverlayFlattenReportsAMidTreeDestinationFailure`
checked that the `/data` directory created before the failing write was still present, which pins
non-transactional partial-write behaviour over rollback - the very thing I said I was avoiding.

Fixed by deleting the co-assertion. The test now checks only that a mid-tree failure is reported,
and adds two assertions that are determined instead: the overlay's own view and recorded set are
unchanged by the failed flatten. The mutation that made `Flatten` continue past a failed child still
breaks 4 tests, so the propagation coverage the test was added for survives intact.

**The lesson is about the note, not the test.** Writing "this stays unasserted" in the log did not
make it true; I never re-read the assertions against that claim before shipping. A written intent to
avoid over-specification needs a check against the actual test body, otherwise it is just a
comforting sentence in the feedback file.

Net after R21: 180 tests, 866 raw / 553 human-effective, meta 494 words, reference unchanged.

### R22 - coverage advisories only; one found a leak, one declined, one unprovable

Three advisories, 12 tests, meta 494 -> 495.

- **Symlink behaviour. Mostly declined, but it exposed a real leak.** MemMapFs does not implement
  `Symlinker`, so the deletion / recreation / Rename / Flatten symlink cases the advisory asks for
  are unreachable on the backend this whole feature is defined against; they would need `OsFs` and
  real temp dirs, and the prompt defines no symlink semantics at all (does `Flatten` copy a link or
  its target? genuinely open). Pinning any of that unstated is the R8 and R21 mistake. What WAS in
  scope: `ReadlinkIfPossible` had no hidden-path guard, so a removed path could still be read
  through it while every neighbouring operation reported not-exist. Fixed, added
  `ReadlinkIfPossible` to the stated list of operations a hidden path is gone from (+1 word), and
  covered it for a directly removed path and one under a removed ancestor. Removing the guard breaks
  both. The error classes differ (`ErrNotExist` vs the backend's no-readlink error), so this
  discriminates on MemMapFs even though symlinks themselves do not exist there.
- **OpenFile flag semantics.** Six tests: `O_EXCL` succeeds at a hidden path and fails on a visible
  base file and on a path already made again, `O_APPEND` and `O_TRUNC` and `O_RDWR` each copy up and
  leave the base untouched. The `O_EXCL` point the advisory singled out - visibility, not hidden
  base existence - is the discriminating one: making `O_EXCL` consult the base breaks 2 tests.
- **Path normalization for Restore and Rename. Added, and honestly UNPROVEN.** Four tests cover dot
  segments and relative names through `Restore` and `Rename`, including persistence. But no mutation
  can kill them: MemMapFs canonicalises its own keys, so `Restore`'s `filepath.Clean` is redundant
  and removing it changes nothing (0 failures). They are regression cover against a divergent
  implementation that keys removals by raw string, not traps, and they are recorded as such rather
  than credited with a kill count. Two earlier mutation attempts this round were also no-ops for the
  same reason - stripping `O_EXCL` where the layer has no file, and un-cleaning a path that
  `filepath.Join` re-cleans downstream.

Net after R22: 192 tests, 870 raw / 555 human-effective, meta 495 words.

### R23 - Test Fairness FAIL (3 of 195): the Flatten conflict policy I added in R17

The three flagged assertions are the cross-type replacement tests I introduced in R17. The behaviour
is right - `clearConflicting` is what makes `Flatten` deterministic across backends instead of
depending on MemMapFs being permissive - but I added the policy to the reference and never put it in
the prompt. Replacing a non-empty destination directory with a file is a real choice; returning an
error is equally reasonable, and nothing told the agent which.

Fixed by rewriting the `Flatten` clause rather than extending it: "leaving whatever else `dst` holds
in place" became "replacing whatever it writes over and leaving the rest". Two words, and it now
states both halves - what it overwrites goes regardless of kind, what it does not touch stays.
Meta 495 -> 497.

**Advisory: readlink error shape.** Both readlink tests now pin `*os.PathError`, `Op` of "readlink"
and the requested path, which the prompt already requires since `ReadlinkIfPossible` joined that
list last round. Returning a bare sentinel instead of the wrapper breaks both.

**This is the third time a corner I ADDED came back as unfair** (root record granularity twice,
Flatten conflict policy once). The shape is always the same: I improve behaviour in a corner the
prompt does not reach, test the improvement, and only then discover the policy was mine rather than
the spec's. The check is doing its job, but the cheaper order is to ask "is this policy in the
prompt?" at the moment I write the code, not after the tests exist.

Net after R23: 192 tests, 870 raw / 555 human-effective, meta 497 words.

### R24 - FIRST AGENT BATCH: 0 of 5. Shared-cause failure, spec gap found

| Run | Solver | Verdict | Msgs | LOC | Died on |
|---|---|---|---|---|---|
| 1 | Orion | FAIL_MISSED_REQUIREMENT | 80 | 1638 | empty-root Remove + create under a removed ancestor (190/192 passed) |
| 2 | Nova | FAIL_MISSED_REQUIREMENT | 56 | 3711 | recreation: resurrects base contents or refuses creation |
| 3 | Nova | FAIL_MISSED_REQUIREMENT | 61 | 7824 | create under a removed ancestor |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 61 | 5044 | create under a removed ancestor + deep base children reappear |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 49 | 1178 | hidden-ancestor recreation + rename destination error Op |

**0 of 5 = reject on the solvability floor, and it is one shared cause.** Every run failed to
implement creation beneath a removed ancestor. Each agent reached the same conclusion independently:
parent is deleted, therefore `os.ErrNotExist`. That is POSIX intuition and it is the obvious reading;
mine - rebuild the ancestor as a sealed directory on the way - was reachable only by chaining two
sentences ("a path is hidden whenever any directory above it is" plus "making a hidden path again").
The evaluators actually rate this fair (`description_clear: true`, `was_mentioned_in_description:
true`, all five classified as the agent missing a stated requirement, difficulty "challenging"), but
fair-and-0% still rejects. A two-hop inference that five of five miss is a spec defect in practice.

Fixed by making it one hop: "This works under a removed directory too, rebuilding that directory on
the way." Twelve words, paid for by compressing six sentences that carried no requirement, so the
meta went 497 -> 495.

**Second finding, and this one was my test's fault.** Run 5's evaluator flagged that the two mid-tree
`Flatten` failure tests "should normalize destination paths rather than requiring the implementation
to call OpenFile with an absolute spelling; the prompt specifies resulting filesystem behavior, not
internal path spelling." Correct - `ovlFailingFs` matched `name == "/data/deep/inner.txt"` exactly,
so an implementation that walked with a different but equivalent spelling would never trigger the
failure and would fail a test it should pass. Now matches on the cleaned, slash-normalised suffix.
The mutation still breaks 4 tests, so the coverage is unchanged.

**Not done: more agent runs.** Brute-forcing pass rate before analysing why agents failed is exactly
what the rules forbid, and with a single shared cause more runs would only reproduce it. The next
batch goes out against the amended prompt.

Net after R24: 192 tests, 870 raw / 555 human-effective, meta 495 words.

### R25 - new description check (request_changes) + 3 advisories

A "description contains only necessary information" check appeared, with 2 HIGH (blocking) and 2
MEDIUM (optional) suggestions. Both HIGH are done; both MEDIUM are declined on purpose.

- **HIGH, removed outright.** "`CopyOnWriteFs` puts a writable layer over a read only base" was pure
  context describing what the type already is. Gone; the opening now starts at the requirement
  ("Give `CopyOnWriteFs` a second mode...").
- **HIGH, reworded rather than removed.** The check called "An overlay in the old mode hides nothing
  and restores nothing" a restatement of existing behaviour. It is not: `Deleted` and `Restore` are
  new methods, and two tests pin what they do on an overlay built by the OLD constructor. Deleting
  the sentence would have orphaned them. Reworded to name the new methods explicitly - "On an
  overlay from the old constructor, `Deleted` reports nothing and `Restore` reports
  `os.ErrNotExist`" - which answers the complaint (it now reads as new-API behaviour, not old-type
  description) without breaking fairness.
- **MEDIUM, declined: drop the method list.** Removing it would collide head-on with Test Fairness,
  which has twice justified the per-operation `*os.PathError` assertions BY that list - the
  `ReadlinkIfPossible` shape tests in R22 and R23 exist because the operation is named there. It
  would also raise difficulty right after a 0/5 batch forced me to lower it. Wrong direction on both
  counts.
- **MEDIUM, declined: trim "sorted by name" and the layer-stands-in phrase.** Tests assert both, and
  this same round's advisory asks for MORE tests on the layer-stands-in rule. Trimming the sentence
  while adding tests that depend on it is a guaranteed fairness failure.

Meta 495 -> 488, so the HIGH fixes also bought back seven words of headroom.

**Advisories: two taken, one declined again.**

- **Bookkeeping write failures.** Six tests using a read-only layer, which needs no knowledge of how
  bookkeeping is stored - a marker-name matcher would have pinned an implementation detail. `Remove`,
  `RemoveAll` and `Rename` all report the failure and leave the view exactly as it was, with nothing
  hidden and nothing recorded; a failed removal alongside an EARLIER successful one leaves that
  record working; and a failed `Restore` leaves its record in place with the path still hidden.
  Swallowing the bookkeeping write error breaks 2.
- **Same-name file/directory precedence.** Four tests: a layer file standing in for a base directory
  and a layer directory standing in for a base file, each checked through `Stat`, content or
  listing, plus the removal case where the layer file goes and the base directory underneath must
  not resurface. Dropping the layer-over-base dedup breaks 10.
- **Optional symlink support. Declined, same reason as R22.** It needs an `Fs` implementing
  `Linker`/`LinkReader`; MemMapFs is not one, so it means `OsFs` and real temp dirs, and the prompt
  defines no symlink semantics for rename or flatten to assert against.

Net after R25: 200 tests, 870 raw / 555 human-effective, meta 488 words.

### R26 - Solution Quality FAIL: a real correctness hole in the reference

Comprehensiveness 1/3, Code Quality 2/3. Both criticisms were correct and both are now fixed. This
one matters more than the fairness rounds: the tests all passed, so nothing in my own harness was
ever going to surface it.

**The hole.** `hidden()` decided visibility from removal markers and directory seals only. It never
considered that the LAYER might hold a file where the base holds a directory. So once a removed
directory was made again as a file - by `O_CREATE` or by renaming something onto it - the marker was
cleared, nothing sealed the old subtree, and a direct lookup of a descendant fell straight through to
the base. Reproduced before fixing: after replacing `/data/deep` with a file, `ReadFile("/data/deep/
inner.txt")` still returned "base inner". That breaks two stated rules at once - "nothing of the base
comes back with it" and "renaming onto a path the overlay already shows replaces it".

Fixed by teaching the ancestor walk that a layer file leaves no room underneath: `layerHoldsNonDirectory`
is consulted alongside the seal check, so anything below a layer non-directory is not visible.
Six new tests cover it - made again as a file, the same across a fresh overlay, renamed onto a
directory, and a layer file standing over a base directory from the start. Removing the check breaks
4 of them.

**Robustness, second criticism.** `Deleted()` walked from the root assuming rooted layer paths while
the mutating entry points accepted relative names; that only worked because MemMapFs normalises for
us. Added `overlayPath`, which roots a name before it keys any bookkeeping, so both spellings
converge explicitly. Two tests confirm a relative removal reports the rooted path and that either
spelling restores the same record. Honest caveat: the mutation that un-roots paths kills 0 tests,
because MemMapFs normalises anyway - the fix is for other backends and this suite cannot demonstrate
it, same as the R22 normalization tests.

**Self-inflicted detour worth recording.** The first version of the rooting fix stack-overflowed
every test: I inserted `overlayPath` and THEN ran a blanket `filepath.Clean(name)` -> `overlayPath(name)`
replace, which rewrote the helper's own body into a call to itself. Caught immediately by the suite,
but a reminder that a global replace has to run before the new helper lands, not after.

Net after R26: 206 tests, 901 raw / 572 human-effective, meta 488 words.

### R27 - Test Fairness FAIL (5 of 117): the failure tests the ADVISORY asked for

The five flagged tests are exactly the bookkeeping-failure tests the R25 coverage advisory requested
- "verify Remove/RemoveAll/Restore/Rename propagate failures while leaving the visible overlay and
existing records consistent". Fairness says the second half of that sentence pins transactional
rollback that the prompt never states. The two checks want opposite things, and fairness wins,
because it is the blocking one.

**Before stripping the assertions I tried to justify them, and that is what settled it: the
implementation is NOT atomic.** I built a layer that permits pruning but refuses the marker write.
`Remove` then deleted the layer's copy of the file and failed to record anything, so a path holding
"layer notes" came back reading "base notes" - the view changed after a failed removal, and the
layer's content was destroyed. The R25 tests only passed because a fully read-only layer has nothing
to prune. So stating atomicity in the prompt would have been stating something false, and pinning it
in tests was pinning a guarantee the reference does not make.

Reduced all five to the half that is both stated and true: the failure is reported. Renamed to match
what they now check (`...ReportsALayerWriteFailure`) rather than leaving names that promise an
unchanged view. Swallowing the bookkeeping write error still breaks 2, so the propagation coverage
the advisory actually wanted is intact.

**Known limitation, now documented rather than hidden:** a removal whose layer prune succeeds and
whose record write fails leaves the overlay in a mixed state. Making it atomic means staging the
prune and rolling it back, which is a real design change; it is out of scope for this submission and
deliberately neither stated nor tested.

Net after R27: 206 tests, 901 raw / 572 human-effective, meta 488 words, reference unchanged.

### R28 - description check again (request_changes): 1 HIGH done, 3 MEDIUM + 1 LOW declined

Note the escalation: the directory-listing sentence was MEDIUM in R25, I declined it, and it came
back HIGH. Declining a suggestion appears to raise its severity next round, so the ones below are
declined with evidence rather than preference.

**HIGH, complied - but only the half that is genuinely pre-existing.** I checked the base repo
before cutting. `defaultUnionMergeDirsFn` (unionFile.go:139) builds the merged listing in a Go MAP
and returns `range` order, so:

- layer precedence IS pre-existing and discoverable - the function adds a base entry only "if
  !exists". Cut, as asked.
- merging both layers IS pre-existing. Cut.
- **sorting is NOT pre-existing.** Map iteration order in Go is randomised, so the stock overlay
  returns directory entries in a different order each run. Sorting is new behaviour my solution
  introduced, and it is what makes every exact-listing assertion in the suite deterministic. Cutting
  it would have made the tests unfair AND non-deterministic, which is a mandatory-check failure, not
  a style point.

Sentence is now "An overlay in either mode reads a directory sorted by name, minus anything it
hides, and never the bookkeeping it keeps." - 41 words down to 21, keeping sorted-by-name and the
deletion-specific clauses the check said I could retain. Meta 488 -> 468, so there is real headroom
again for the first time in ten rounds.

**Declined, each because a fairness FAIL was repaired by adding exactly that sentence:**

- "`RemoveAll` on the root is removing each thing it shows" - added in R17 to fix a 4-test fairness
  FAIL on root record granularity. Removing it re-breaks them.
- "so a fresh overlay over the same base and layer starts the same way" - persistence is asserted by
  roughly fifteen tests. The check calls it implied by "records removals in the layer"; that is a
  one-hop inference, and R24 is the standing evidence that a one-hop inference agents miss costs the
  whole batch.
- "what the caller makes takes the permissions asked for" - added in R15 for exactly this reason;
  without it the recreated-file permission tests are unstated.
- (LOW) "Renaming onto a path the overlay already shows replaces it" - added in R10; the rename-onto
  tests depend on it, and R23 showed what happens when a replacement policy is unstated.

Net after R28: 206 tests, 901 raw / 572 human-effective, meta 468 words, reference unchanged.
Suite verified deterministic 3x after the change, since the cut touched the ordering rule.

### R29 - Test Fairness FAIL (2 of 27): a contradiction my own R24 fix created

The description half of this run is STALE - its HIGH still quotes the long listing sentence I
already cut in R28, and that text is no longer in meta.md. Nothing to do there.

The fairness half is real, and it is self-inflicted. R24 added "This works under a removed directory
too, rebuilding that directory on the way" to fix the 0/5 batch. But `Rename` into a destination
under a removed directory still REFUSED with not-exist, so the prompt now promised rebuilding for
creation while the reference refused it for rename. The check put it exactly right: "An equally
reasonable implementation would rebuild the hidden destination directory, as creation does."

I fixed the reference rather than adding an exception to the prompt. `Rename` now rebuilds a hidden
destination directory, sealed, the same way creation does - the destination lands, the rebuilt
directory shows none of the base contents, and the source is recorded removed. A destination parent
that NEVER existed still fails with not-exist, which is ordinary filesystem behaviour and outside the
rebuilding rule. Both directions are pinned: restoring the old refusal breaks 2 tests, dropping the
missing-parent check breaks 1.

**Why fix the code and not the prompt.** An exception would have cost words and, worse, left an API
where `OpenFile` with `O_CREATE` under a removed directory rebuilds it but `Rename` into the same
place fails. That is the kind of wart a human reviewer asks about. Removing the inconsistency
shrinks the spec surface instead of growing it, which also helps with the description check that
keeps trimming.

Both tests were rewritten to assert the new behaviour, and the second was renamed
(`...ReportsAPathError` -> `...RebuildsItSealed`) since it no longer expects an error. Added a
replacement test for the never-existed destination so that path stays covered.

Net after R29: 207 tests, 907 raw / 576 human-effective, meta 468 words.

### R30 - description check, two HIGH: the ops list and the error-shape restatements

Both blocking items complied with. This is the collision I flagged last round: the description check
wants the error contract gone, and Test Fairness has twice REQUIRED it. I resolved it by giving up
the enumeration (which was genuinely over-specified) and keeping one general contract sentence
(which about thirty assertions rest on).

- **HIGH, method enumeration.** "A hidden path is gone from `Stat`, `LstatIfPossible`, `Open`,
  `OpenFile`, `Chmod`, `Chown`, `Chtimes`, `ReadlinkIfPossible` and `Rename`, which report..." became
  "Every operation on a hidden path reports `os.ErrNotExist` in an `*os.PathError` naming the
  operation and the path." The nine-name list is gone, which was the substance of the complaint, and
  the general rule still covers every per-operation test. Verified it still bites: removing the
  readlink guard's wrapper breaks 2 tests.
- **HIGH, `ENOTEMPTY` tail.** Deleted "inside an `*os.PathError` naming the operation and the path;
  `RemoveAll` never does". The `RemoveAll` half was already covered by "Remove and RemoveAll succeed
  on anything the overlay shows". The `*os.PathError` half was added in R16 for a coverage advisory,
  so I pulled the two tests that depended on it back to the sentinel alone and renamed them to match
  (`...NamesTheOperationAndPath` -> `...IsNotEmpty`). Real, accepted coverage loss: a bare
  `syscall.ENOTEMPTY` now breaks 1 test instead of 3.

**Why I kept the PathError phrase in the general sentence.** The check argues the wrapping is a Go
default and should go too. Dropping it would strand roughly thirty Op/Path assertions across the
hidden-path suite - the readlink shape, the rename destination path, every per-operation `Op` - and
Test Fairness has flagged exactly that pattern before. Keeping one sentence is the smaller risk than
weakening thirty tests, and if it comes back HIGH the honest answer is that the two checks want
incompatible things and someone has to choose.

**MEDIUM items declined again** (persistence clause, rename-replacement, missing-path defaults), each
because a fairness round previously required them. They are now on their third escalation cycle.

Meta 468 -> 445. Net after R30: 207 tests, 907 raw / 576 human-effective.

### R31 - three checks converge on the Op strings; 2 advisories taken, 1 declined

The description half of this run is STALE again - it quotes the enumeration and the `ENOTEMPTY` tail
I already removed in R30, neither of which is in meta.md now.

**A third check appeared and it broke the deadlock.** "Problem and tests are good quality" warned
that pinning exact `os.PathError.Op` strings is "stricter than necessary for user-visible behaviour"
and suggested checking PathError plus the sentinel plus the path instead. That is the same direction
the description check keeps pushing, and unlike its blanket demand it is surgical. So: dropped
"naming the operation" from the prompt, and removed every `Op` assertion from the suite - the shared
helper plus five inline ones. What remains is the `*os.PathError` type, the path, and the sentinel,
all still stated. Three checks satisfied at once, and the readlink and rename-path assertions that
Test Fairness previously validated survive intact.

**Advisories, two taken:**

- **Deleted scan failures. Found a real defect.** The `Deleted` walk callback started with
  `if err != nil || info == nil || info.IsDir() { return nil }` - it SWALLOWED walk errors, so a
  layer that could not be read reported "no deletions" with a nil error. Silently wrong, and exactly
  the case the advisory named. Now not-exist is still ignored (an empty layer must report nothing)
  while any other failure propagates. One test with a layer that refuses to open the bookkeeping
  directory; it also checks nothing is returned alongside the error. Restoring the swallow breaks it.
- **Flatten close/metadata failures.** The failure-injection wrapper only overrode `OpenFile`, so the
  `Chmod` and `Chtimes` calls added in R18 were never exercised on the error path. Extended it with
  `Chmod`, `Chtimes` and `Open` injectors; four tests cover a file permission failure, a file time
  failure, a directory metadata failure, and that the overlay still flattens cleanly afterwards.
  Ignoring directory metadata errors breaks 1.
- **Symlink preservation. Declined, fourth time, same reason.** MemMapFs does not implement
  `Symlinker`, so there is no way to create one to rename or flatten; it needs `OsFs` and real temp
  dirs, and the prompt defines no symlink semantics for either operation to assert against.

Net after R31: 212 tests, 913 raw / 580 human-effective, meta 442 words.

### R32 - Test Fairness FAIL (3 of 37): three unstated pins, all removed

Each of the three was mine, and two of them I had added in the last two rounds while fixing other
findings. The check reasoned from the pinned repository each time, which is what made the calls
correct rather than arguable.

- **Rename into a never-existing parent.** I added this test in R29 to keep the missing-parent path
  covered after making `Rename` rebuild HIDDEN parents. The check pointed at
  `registerWithParent` (memmap.go:111-130), which creates a missing parent - so MemMapFs itself
  supports the opposite behaviour, and the prompt only ever singled out REMOVED directories.
  Rather than state a new rule, I deleted the special case from the reference entirely: `Rename` no
  longer inspects the destination parent at all and simply lets the layer do what it does. That
  removes an unstated policy and a branch, instead of adding words to defend one.
- **A pre-existing layer file hiding base descendants.** This was the fourth test on the R26
  visibility fix. The fix itself is still needed and still stated - it is what makes "nothing of the
  base comes back with it" and "replaces it" true for a directory made again as a file or renamed
  over. But THIS test used a layer file that was there from the start, which no rule covers, and the
  check is right that stock `CopyOnWriteFs` would fall through ENOTDIR to the base. Deleted the test;
  the three stated-case tests remain and still break when the fix is reverted.
- **`Deleted` returning exactly zero results on error.** Same shape as R21 and R27: the error
  assertion is fair, the co-assertion about what comes back alongside it is not. Dropped
  `len(got) != 0`.

Net after R32: 210 tests, 902 raw / 573 human-effective, meta 442 words unchanged.

**Pattern across the last four fairness rounds:** every failure has been a pin I introduced while
satisfying an earlier finding - the root granularity in R17, the Flatten conflict policy in R23, the
rename parent in R29, the atomicity co-assertions in R27. Fixing one corner keeps creating the next
one. Removing the branch, rather than defending it with prompt words, has been the cheaper move
every time it was available.

### R33 - 1 unfair test removed; 3 advisories, and two of them found real bugs

**Fairness (1 of 59).** `TestOverlayDeletedReportsALayerReadFailure`, added last round, injected its
failure on `Open` of `/data` - which assumes markers live beside the files they hide. An
implementation with a central index would never open `/data` and would pass trivially. There is no
implementation-independent place to inject this, so I deleted the test. The reference keeps the
error-propagation fix from R31 (swallowing read errors is still wrong); it is simply not pinnable,
like the rooted-path fix in R26.

**Advisories, all three addressed:**

- **Rename invalid topology. Found a data-destroying bug.** Renaming a file onto itself returned nil
  and DESTROYED it: `materializeSubtree` copied the base file into the layer, the layer rename
  no-opped, and then `recordRemoval(oldname)` hid the very path that was also the destination. The
  file came back empty and `Deleted` listed it. Now a rename whose source and destination normalise
  to the same path is a no-op that still reports not-exist for a hidden source. Four tests, covering
  the plain case, a dot-segment spelling, a layer-only file, and the hidden case; removing the guard
  breaks 2. I left the other two topologies alone - the destination-parent case is now backend-defined
  on purpose (R32) and moving a directory into its own descendant is unstated.
- **Rebuilt intermediate directory metadata. Found a second inconsistency, against my own prompt.**
  `ensureLayerDir` called `reviveDir(step, 0o777)` for a removed directory and skipped the metadata
  mirror entirely, so rebuilt intermediates came out 0777 instead of the base permissions the prompt
  promises for "a directory the overlay makes for its own sake". Added `adoptBaseDirMetadata` on the
  revive path, keeping caller-made directories on their requested mode. Two tests: three rebuilt
  levels each carry base permissions and modification time while the caller-created endpoint keeps
  0642, and the rebuilt chain lists none of the base entries. Reverting breaks 1.
- **Symlink integration. Finally testable, and taken in part.** The advisory pointed out I could use
  a filesystem that supports `Linker`/`LinkReader`, so these run on `OsFs` over `t.TempDir()` with a
  real symlink: removing it hides it from `ReadlinkIfPossible` and `Stat`, leaves its target intact,
  and stays hidden on a fresh overlay. That half is squarely stated. I still did not assert symlink
  MOVE semantics for `Rename`/`Flatten` - the prompt says nothing about whether a link or its target
  travels. Probing also showed `ReadlinkIfPossible` never falls back to the base for a base-only
  symlink; that is pre-existing afero behaviour outside this feature, so it is neither fixed nor
  tested.

Net after R33: 218 tests, 920 raw / 583 human-effective, meta 442 words. Suite verified deterministic
3x in both modes, since the symlink tests are the first to touch a real filesystem.

### R34 - coverage advisories only (Test Fairness clean); one taken, one declined

- **Rename/Flatten symlink handling.** The advisory made the condition explicit: add it only if
  "file or tree" is meant to include symlinks, otherwise clarify the prompt first. Probed both paths
  on `OsFs`: `Rename` and `Flatten` each DEREFERENCE, so a link arrives as a plain file holding the
  target's bytes. That is the right choice rather than an accident - preserving links would depend
  on the layer implementing `Linker`, which MemMapFs does not, so it would be backend-dependent in
  exactly the way that has failed here before. Clarified the prompt in thirteen words ("Copying or
  moving a symlink writes what it points at, not the link") and added four tests: rename writes the
  content and hides the link, the target is untouched, flatten writes the content, and a removed
  link is omitted from a flatten. Mutations that preserve the link instead break 1 test each.
- **Destination partial-state documentation. Declined.** The advisory suggests stating that partial
  writes to `dst` may remain after an error so implementations are not inferred to need rollback.
  That sentence would be a permission, not a requirement, and the description check has now cut six
  non-requirement sentences from this prompt; a permissive clause is exactly what it removes next.
  The advisory itself notes the Flatten failure tests "correctly avoid requiring atomicity", so the
  inference it worries about is already blocked by what the tests do NOT assert. The non-atomicity
  limitation stays documented here in feedback rather than in the prompt.

**Mutation note.** My first attempt to prove the symlink tests was a no-op: it routed through
`ReadlinkIfPossible`, which never falls back to the base for a base-only link (the pre-existing afero
gap found in R33), so the mutated branch was unreachable. Rewrote both mutations to detect the link
via `LstatIfPossible`, which does fall back, and then they fired. A mutation that cannot reach its
own branch reads exactly like strong test coverage.

Net after R34: 222 tests, 920 raw / 583 human-effective, meta 455 words. Deterministic 3x in both
modes.

### R35 - Solution Quality FAIL: 8 phantom failures + the atomicity I had shelved

Two separate problems, and the first was an environment trap of my own making.

**The 8 synthesized failures.** The report says the visible suite passed 222 tests with 0 failures,
yet the merged report carried "8 failing synthesized new-test cases in the fallback suite". Locally
the run is clean - 222 cases, 0 failures, 0 skipped - so the difference has to be environmental, and
exactly 7 tests plus their helper were the only ones in the suite that touched a REAL filesystem:
the `OsFs` symlink tests added in R33 and R34, which call `t.Skipf` when a symlink cannot be created.
On a platform sandbox that forbids symlinks they skip, and a skipped test that the wrapper expected
to pass is synthesized as a failure.

Removed all seven and the helper. The suite is back to 100% MemMapFs and cannot skip. Also removed
the R34 prompt sentence about symlinks, since no test asserts it any more and a described behaviour
without a test is its own review flag. Meta 455 -> 442. The lesson is one I should have applied when
I added them: a test that can skip is worse than no test, because a skip is indistinguishable from a
silent failure in someone else's harness.

**Atomicity - fixed in code, still unasserted in tests.** The reviewer objected that `hidePath`
pruned the layer BEFORE the removal record was durable, so a failed remove could still change what
the overlay shows. That is precisely the limitation I documented in R27 and declined to fix. It was
worth fixing after all, and the fix is small: decide from the base first, write the record (or clear
it), and prune LAST. Verified with a layer that permits pruning but refuses the marker write - a path
holding "layer notes" used to come back reading "base notes", and now keeps its content with nothing
recorded.

This satisfies both checks at once, which is why it is the right shape: Solution Quality gets the
robustness, and Test Fairness is untouched because no test asserts the post-failure state. The
behaviour is better; the contract is unchanged.

**Over-suppressed errors**, both named by the reviewer, both fixed: `readDirInfos` returned
`nil, nil` for ANY open or stat failure and now only swallows not-exist; `clearConflicting` ignored
every `Stat` error and now only ignores not-exist. Both became methods to reach `isNotExist`.

`Rename` is still multi-step and not transactional. Making it so needs staging and rollback, which
is a design change rather than a reordering, and no test asserts its post-failure state either.
Left alone deliberately and recorded here.

Net after R35: 215 tests, 942 raw / 595 human-effective, meta 442 words, zero skippable tests.

### R36 - coverage advisories only; solvability deliberately unchanged

Two advisories, 4 tests, and NO reference or prompt change. That last part is the point of this
round, so it is worth stating why rather than just reporting it.

- **Flatten layer-directory metadata.** Existing coverage pinned permissions and times on BASE
  directories and on layer FILES, but never on a layer-only directory. Two tests: a single layer
  directory with both changed, and a nested pair. The first mutation I tried (dropping the explicit
  `Chmod`) did not catch them, because `MkdirAll` still applies the mode when the destination entry
  does not exist yet - so I retargeted to `MkdirAll(0o777)` plus no `Chmod`, and to dropping the
  directory `Chtimes`. Those break 5 and 4 respectively, the new tests among them.
- **Source-side Flatten failure.** Every failure-injection test so far pointed at the DESTINATION.
  Two tests put the failing wrapper on the source side instead: the read failure is reported, and a
  healthy overlay still flattens completely afterwards. Swallowing the copy error breaks 7.

**Why this does not repeat the 0/5 batch.** The R24 failure came from a REQUIREMENT that was only
reachable by chaining two sentences, so every agent implemented the opposite. Nothing here adds a
requirement:

- meta.md is byte-identical to last round at 442 words. No new rule means no new thing to discover.
- Both behaviours are already stated - "permissions and modification times included" covers a layer
  directory exactly as it covers a base one, and a method returning `error` covers propagation.
- Both ride code paths the suite ALREADY exercised. `flattenPath` handles every directory through
  one branch, so an implementation that passes the existing base-directory tests passes the new
  layer-directory ones for free. Same for the copy error: any implementation that returns the error
  from its read call already passes.
- Neither is a trap. They cannot be failed by an implementation that is correct on the paths already
  tested - which is the test for whether new coverage costs solvability.

Net after R36: 219 tests, 942 raw / 595 human-effective, meta 442 words, reference untouched.

### R37 - Solution Quality FAIL again: I deleted the wrong thing in R35

The report names the 7 phantom cases outright - `TestOverlayFlattenOmitsARemovedSymlink`,
`TestOverlayFlattenWritesWhatASymlinkPointsAt`, `TestOverlayRemovalHidesASymlinkFromReadlink` and
the rest of the symlink set. Those are exactly the tests I DELETED in R35. The harness expects the
previous revision's test names, so removing a test does not remove its expectation - it turns it
into a permanent synthesized failure.

**My R35 diagnosis was wrong and it made things worse.** I reasoned that the symlink tests must be
skipping on the platform and deleting them would clear the 8 phantoms. But the same report said the
visible suite passed 222 tests, and 222 is the count WITH the symlink tests - so they ran and passed
there. I removed working tests on a hypothesis the evidence in front of me already contradicted, and
the phantom count went 8 -> 7 rather than 8 -> 0.

Restored all seven plus the helper, and restored the prompt sentence they assert so the description
and the suite stay in step. Meta 442 -> 455. All seven now emit `<testcase>` nodes and pass.

**De-risked the skip path properly this time,** instead of guessing: a probe confirms
`go-junit-report` emits a full `<testcase>` node for a SKIPPED test, name and all. So even in an
environment that cannot create symlinks, the nodeids appear and cannot be synthesized as missing.
The `t.Skipf` fallback is safe; it was never the problem.

**The rule, now paid for twice:** never delete or rename a test function across revisions. R27, R29,
R30, R32 and R33 all renamed or dropped tests, and every one of those is a candidate phantom. I am
not restoring those - R32 and R33 deleted tests that Test Fairness had ruled UNFAIR, and bringing
them back would trade a harness failure for a fairness failure. The symlink set is different: it was
never unfair, so restoring it costs nothing.

Net after R37: 226 tests, 942 raw / 595 human-effective, meta 455 words, reference unchanged.

### R38 - description check: nothing blocking, one taken, four declined with evidence

No HIGH items this round - 4 MEDIUM and 1 LOW, and the check states plainly that "only
high-severity issues are blocking". The `request_changes` verdict comes from its own count rule
("3+ suggestions requires request_changes"), not from severity. Worth being clear about that,
because complying with one or two would not flip the verdict either: I would have to accept three
of the five, and three of them are load-bearing.

**Taken: the constructor line.** Rather than delete "returns an overlay in the new mode" and leave
"the new mode" undefined for the rest of the prompt, I folded the constructor into the opening
sentence: "Give `CopyOnWriteFs` a new mode, reached through `NewCopyOnWriteFsWithDeletions(...)`,
that records removals in the layer". The redundant clause is gone, the constructor-to-mode linkage
survives, and the prompt lost five words. Meta 455 -> 450.

**Declined, with the specific evidence for each:**

- **"Removing something not there..."** - the closest call. Cutting it is probably survivable since
  `os.RemoveAll` on a missing path is documented Go behaviour. But Test Fairness has rated these
  tests "Prompt-stated" in at least one round, and a fairness FAIL is blocking while this suggestion
  is not. I am not trading a non-blocking suggestion for a blocking risk.
- **Persistence clause** - about fifteen tests assert it, and R24 is the standing evidence that a
  one-hop inference agents miss costs the entire batch (0/5). Solvability outranks concision.
- **"sorted by name"** - already declined in R28 with hard evidence: `defaultUnionMergeDirsFn`
  (unionFile.go:139) returns Go MAP order, so the stock overlay's listing is randomised. Sorting is
  new behaviour and it is what makes every exact-listing assertion deterministic. Cutting it would
  break the mandatory flakiness gate, not just fairness. It has stayed MEDIUM across two rounds,
  which suggests the decline is holding.
- **Rename replacement (LOW)** - six tests depend on it, and R23 was a fairness FAIL caused by
  exactly this: a replacement policy that the reference implemented and the prompt did not state.

Net after R38: 226 tests, 942 raw / 595 human-effective, meta 450 words, suite unchanged and green.

### R39 - coverage advisories only; one taken, one declined as the advisory itself suggests

- **Symlink to a directory.** Probed before writing anything, because a case that does NOT work
  naturally would be a new requirement and a solvability risk. It works: `Stat` follows the link, so
  the overlay shows a directory, `Flatten` writes a real directory holding the target's contents, and
  `Rename` produces the same. That is the existing sentence ("copying or moving a symlink writes what
  it points at") applied to a directory target, so no new prompt words and no new implementation
  burden - any implementation that stats rather than lstats gets it for free. Four tests: the link
  shows and lists as a directory, `Flatten` writes the tree under the link name while leaving the
  original tree intact, `Rename` moves the tree and hides the source, and removing the link leaves
  its target alone.

  The mutations I already had did not cover this: they patch `copyVisibleFile` and `copyBaseFileAs`,
  which only handle FILES, so a linked directory never reaches them. Wrote two new ones that make
  `flattenPath` and `materializeSubtree` treat a linked directory as a link rather than following it,
  which is the natural wrong implementation. Each breaks exactly the matching new test.

- **Restore error shape. Declined, on the advisory's own terms.** It says to state the contract
  before adding such a test, and the prompt deliberately does not: the `*os.PathError` rule covers
  operations on a HIDDEN path, and `Restore` of a path with no record is not that. Adding the
  sentence would grow a surface the description check has now trimmed seven times, and asserting the
  shape without it repeats the R21, R27 and R30 mistake. The `errors.Is(os.ErrNotExist)` check stays.

Net after R39: 230 tests, 942 raw / 595 human-effective, meta 450 words, reference and prompt both
unchanged.

### R40 - 5/5 Nova fail the same three tests: the file branch was never stated

The three failures - `DirectoryMadeAgainAsAFileKeepsItsChildrenHidden`,
`...SurvivesAFreshOverlay`, `RenameOntoADirectoryKeepsItsChildrenHidden` - are all the same rule,
and five of five agents missing it is the coordinated-failure signal, not five unlucky runs.

**The tests were right; the prompt was not.** Read the governing sentence closely:

> a file made there starts empty and holds only what the layer writes, and a directory made there is
> empty and keeps the base contents under it hidden

The descendant rule appears ONLY in the directory branch. For the file branch it says what the file
holds and stops. So an agent implements exactly that - the file starts empty - and leaves
`/data/deep/inner.txt` reachable through the base once the removal record is dropped. Every one of
them read it the same way, which is the tell that the sentence, not the agents, is at fault.

Fixed with one general sentence rather than patching the file branch: "A path the layer shows as a
file hides whatever the base keeps under it." It covers all three failures at once - made again as a
file, the same across a fresh overlay, and renamed onto - because all three end with a path that the
layer shows as a file. Meta 450 -> 465.

**Not touched: the tests or the reference.** The behaviour is correct and Solution Quality flagged
its ABSENCE in R26 - without it you can read base content straight through a path that is now a
file. Deleting the tests would trade a fairness complaint for a real bug. The mutation still breaks
exactly those three, so the coverage is unchanged; only its discoverability moved.

This is the second time the same failure mode has cost a batch: R24 was a rule reachable only by
chaining two sentences, and this is a rule stated for one branch of a two-branch sentence. Both read
as complete when writing them and neither was.

### R41 - blocking HIGH complied without breaking a rule; 3 advisories, one exposed a contradiction

**Description HIGH (escalated from MEDIUM in R38).** "Removing something not there is
`os.ErrNotExist` for `Remove`, nothing for `RemoveAll`" is gone. But deleting it outright would have
created a CONTRADICTION: "Every operation on a hidden path reports `os.ErrNotExist`" then covers
`RemoveAll` too, while `TestOverlayRemoveAllOfHiddenPathSucceeds` asserts nil. So the exception moved
rather than vanished - the hidden-path sentence now ends "except `RemoveAll`, which succeeds". Six
words replace thirteen, the HIGH is satisfied, and the four tests that leaned on the old sentence are
still covered: `Remove` of a missing path is standard Go, and the hidden-path case is stated.

**MEDIUMs declined, each with a reason that is not "I prefer it":**

- `ENOTEMPTY` is not redundant - "Remove and RemoveAll succeed on anything the overlay shows" says
  `Remove` SUCCEEDS, so the `ENOTEMPTY` sentence is the carve-out that makes a non-empty directory
  fail. Deleting it contradicts a stated rule, exactly like the HIGH would have.
- "including base entries nobody has looked at" is the lazy-discovery requirement, which
  `TestOverlayRemoveAllHidesNeverListedDescendant` exists for; "a path is hidden whenever any
  directory above it is" is the ancestor rule. Neither follows from "hides everything under it" for
  an implementation that only hides what it has enumerated.
- Rename replacement caused a fairness FAIL in R23 when it was unstated.
- (LOW) "in either mode" is what ties the listing rule to the OLD constructor, which
  `TestOverlayPlainModeListingIsSorted` asserts.

**Advisories, all three taken - and the first found the reference contradicting its own prompt.**

- **Layer-origin symlinks.** The prompt said "copying OR MOVING a symlink writes what it points at",
  but a link that already lives in the layer is not copied - `Rename` moves it, so it stays a link.
  My own sentence was false for that case. Fixed by stating both halves: a symlink copied into the
  layer or written out becomes its target, while moving one already in the layer keeps it a link.
  That is also the better behaviour - dereferencing on a same-layer move would silently destroy the
  link. Two tests, one per half.
- **Chunked `Readdir`.** Only `Readdir(-1)` and `Readdirnames(n)` were covered. Two tests walk
  `Readdir(2)` and `Readdir(1)` to `io.EOF` over a merged, filtered listing. **The first version
  could HANG:** the mutation that removes `io.EOF` sent it into an infinite loop instead of a
  failure, which on the platform is a timeout rather than a clean result. Bounded both loops so a
  wrong implementation fails fast. Both mutations now break 4 tests each.
- **Mixed root removal.** One test with base-only, layer-only, overridden and already-removed
  top-level entries: `RemoveAll("/")` empties the view, a fresh overlay reports the same records, and
  restoring one base-backed subtree brings back only that.

Net after R41: 235 tests, 942 raw / 595 human-effective, meta 472 words.

## Open risks

- **Repo saturation** is the one unverified gate (see R1). Check the platform sub-count first.
- **Recall.** Overlay filesystems with whiteouts and opaque directories exist in the Linux kernel
  and in OCI images, so an agent may arrive knowing that opaque directories are the answer to
  trap 2. The meta never names whiteouts, overlayfs or opacity, and the mechanism is left free, so
  the difficulty that remains is the integration: fifteen methods, the directory merge, the
  emptiness test and the copy-up all agreeing with one predicate while 176 existing nodes stay
  green. That is DOING, not KNOWING, which is where HARDENING says surviving difficulty lives.
- **Solvability.** Eleven interdependent traps is firmly on the hard edge and this is now the main risk, ahead of saturation. If the first batch comes back
  0%, the de-trap ladder is: name the "made again" case more concretely before touching anything
  else, and only then consider dropping the `ENOTEMPTY` rule. Do not soften the opaque-directory
  rule, which is the lead trap.

## Why this is not a duplicate

Nothing in any local directory touches afero or a union / overlay / copy-on-write filesystem. The
closest approved shape is `surrealkv-merge-operator` (a write path that must ride an existing
layered read path); this differs in repo, in subsystem, in trap category (visibility and listing
merge rather than merge folding) and in public surface.

## FP adjudication (2026-07-28) - false positive confirmed, discriminator added

The passing Nova run was adjudicated a FALSE POSITIVE. Two of three judges called it a genuine
pass; judge-c found the defect and the adjudicator re-ran the probe and upheld it.

**The bug.** `Deleted()` sorts the recorded paths and then prunes each one against
`result[len(result)-1]`, the immediately previous KEPT path, rather than against the last kept
ancestor. Lexical sort puts an ancestor before its descendants but not necessarily immediately
before them: a sibling whose next byte is below `/` (0x2F) sorts in between. With `-` (0x2D),
`/data-backup.txt` lands between `/data` and `/data/deep/inner.txt`, so the descendant is compared
against the sibling, is not contained by it, and survives. meta.md line 5 requires "never an entry
under another it reports", so the description was already explicit; the hidden suite was the gap.
`TestOverlayDeletedPrunesPathsUnderARemovedDirectory` only ever produced adjacently-sorting
removals, which cannot expose the class.

**My reference was already correct** - it checks each candidate against every already-kept path
(`for _, kept := range pruned`), which is the second fix the adjudicator suggested. So this was a
missing test, not a wrong solution.

**Added two tests**, both mutation-proved:

- `TestOverlayDeletedPrunesUnderARemovedDirectoryAcrossAnInterleavingSibling` - removes
  `/data/deep/inner.txt`, then a base sibling `/data-backup.txt`, then `RemoveAll("/data")`.
- `TestOverlayDeletedPrunesUnderANestedRemovedDirectoryAcrossAnInterleavingSibling` - the same
  shape one level down, so the case is not a root-level artifact.

**Mutation proof.** Rewriting the prune loop to compare only against the previous kept entry (the
agent's exact bug) makes both new tests fail with precisely the adjudicator's reported output,
`[/data /data-backup.txt /data/deep/inner.txt]` where `[/data /data-backup.txt]` was wanted, while
ZERO pre-existing tests fail. The suite really was blind to the whole class. Reference restored
after the proof.

**Separate defect found while verifying: base mode produced no JUnit XML.** `test.sh` calls bare
`go-junit-report`, which lives at `/opt/go/bin` in `olympus-base-go` and is NOT on PATH, and this
Dockerfile never installed it. Base mode exited 141 (SIGPIPE) and wrote an empty file. The
Dockerfile now installs it into `/usr/local/bin` the same way the cadence submission does. Base
mode now exits 0 and reports 176 cases.

Re-verified end to end in the built image: 237 of 237 new tests fail on base with zero vacuous
passes, all 237 pass with the solution, and base mode is 176 cases / 0 failures in both states.
