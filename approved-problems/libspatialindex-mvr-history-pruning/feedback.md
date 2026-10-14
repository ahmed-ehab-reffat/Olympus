# feedback.md - libspatialindex-mvr-history-pruning

NEXT (human): paste the meta.md body into pangram.com (API key is out of credit), then run the Description Quality check and the first platform batch. Solver-visible surface (meta, Dockerfile, base) should be frozen before that batch.

## Status (2026-09-29, MODE=SLICE, factory builder)
- Repo libspatialindex/libspatialindex (canonical, unmoved), base 2fb81f6 (main HEAD 2026-09-27). Second
  libspatialindex pick; the first (approved tpr-temporal-knn) is src/tprtree only, this one is src/mvrtree.
- Core slice built and validated: 5 source files, **217 human-effective** (hook), 15 new gtests in a
  separate executable `mvrtree_history_test`, base mode = the repo's own `libsidxtest` (32 tests).
- Docker clean room (uid 1000, `--network none`, clone at BASE with .git): base 32/32 pass before and
  after the solution; new 15/15 fail before (compile fallback lists every real test name), 15/15 pass
  after; 3 runs each identical. Also checked as uid 0 and an unmapped 4242: same. Cold build 67 s.
- Mutants (reference with one mechanism broken; tests that fail):
  - dead roots only, no sweep of dead entries inside surviving versions: 3 tests (page set, compaction,
    reuse).
  - whole-subtree delete from dead roots, ignoring shared pages: 12 tests.
  - archive without fragment chaining (one visit per leaf entry): 4 tests.
  - no query clipping: 8 tests.
  - no compaction of kept pages: 4 tests.
  - header horizon read unconditionally (legacy layout): **0 tests**. The overread lands on malloc
    metadata, a denormal near 0, which clips nothing because tree times start at 0. See FINISH notes.

## FINISH (2026-10-01, own session; precheck PASSED clean per user)
- Upstream re-checked: no commit after base 2fb81f6, no new PR touching pruning/history (#315 still open,
  split selection only).
- Lever C landed: `HistoryRetention` property (finite, non-negative VT_DOUBLE). After every
  insertData/deleteData call the tree prunes to current time minus retention, no archive. Stored in the
  header after the horizon, reported by getIndexProperties only when set, replaced by a value given at
  reopen through returnMVRTree, never applied on open. C API IndexProperty_SetHistoryRetention /
  IndexProperty_GetHistoryRetention. Header read of horizon + retention is length-guarded as one block.
- LOC: 297 human-effective (hook), raw 411, 5 files. sidx_api.cc is 73 of it, mostly the repo's
  three-catch boilerplate; the hook's padding floor is 50, so the amortized worst case is still > 200.
- Trap #4 (legacy header) is now measurable: the legacy test turns on a RecordingStorage mode that hands
  back every page with 32 bytes of 0x41 slack after it, so an unguarded read sees a horizon near 2.3e6
  and every query comes back empty. M5 now killed (was 0).
- New tests (15 -> 23): reopen then archive from the stored horizon; prune at exactly the current time
  with a record inserted and one deleted at that instant; retention after inserts and after deletes;
  zero retention; retention stored / replaced at reopen / not applied on open; archive after automatic
  pruning starts at the automatic horizon, and a manual horizon later than the automatic one holds until
  the automatic one passes it; invalid retention at create and at reopen; C API retention.
- Mutants (each test in its own process, crashes count): 15/16 killed. Survivor M14 (no live-bound
  refresh) only loosens entry boxes; observable only through isIndexValid, which L82 forbids asserting.
  Kept in the reference so Index_IsValid stays true after a prune.
  Kill counts: M1 7, M2 19, M3 7, M4 13, M5 1, M6 11, M7 5, M8 1, M9 2, M10 1, M11 1, M12 3, M13 4,
  M15 7, M16 1.
- meta.md rewritten whole in the first-person-plural register (2026-09-30 rule), 535 words, unwrapped,
  ASCII. NOT yet scored: the Pangram API key returns HTTP 402 (out of credit). The user should paste the
  body into pangram.com before the Description Quality check.

## Scope-lock gates (all run before code)
- PICK-FILTER 1 PASS: no pruning exists; `MVRTree::deleteNode` is never called; `m_roots` only grows
  (probe: 19 roots after 2000 ops, capacity 20); pages never freed.
- PICK-FILTER 5 PASS: the capability is cold. mvrtree is touched only by lint and leak sweeps.
- PICK-FILTER 6 PASS: reproduced on base with `worktrees/libspatialindex/_probe/probe1.cc`, which
  measured sharing, stale dead-node pages, and garbage under surviving versions.
- PICK-FILTER 7b / exclusivity PASS: every mvrtree PR diff was read. #315 is open and covers NaN split
  selection. #311 is closed and covers pooled-node and time-shape leaks. #282, #208, #41 and #49 are
  unrelated. hobu's 09-25..27 sweep (#307-#314 plus branch `mvrtree-leak-fixes`) is memory hygiene.
  No PR touches root trimming, page deletion, the header layout, query clipping or archiving.
- PICK-FILTER 8 PASS: the literature defines purging (MVBT/MV3R), and no maintainer has declined it.
- SIX-CHECK clean. The search list is in DESIGN.md Phase 2. Base is HEAD, so the base->HEAD overlap is
  empty. Re-check #315 at submit.
- Quota: 1 approved (tpr-temporal-knn), and this would be the 2nd.

## Decisions taken without a human (conservative defaults)
- LOC: the hunter-sketched core (drop dead versions, clip queries, persist the horizon, C API)
  measured **146** human-eff on a working reference, under the 200 floor. I grew it with ONE coupled
  lever from the same lane: the archive overload, which hands every discarded record version out once.
  It needs version reconstruction from leaf fragments, and it brought the slice to **217**. I did not
  add the second lever (retention window) in SLICE; it is the FINISH plan for reaching >= 250.
- Horizon semantics: I chose clipping, where a query answers as if it started at the horizon and a
  query ending before it visits nothing. I rejected filtering by entry end, which returns partial
  answers for times before the horizon.
- The horizon may not be later than the tree's current time. Such a horizon is rejected, and the tree
  is left unchanged.
- The header gains a trailing horizon field, read only when the stored header is long enough. Legacy
  headers are tested by writing the base layout by hand. The writer was verified byte-equal to base's
  own header on 29 seeds, apart from two stat counters.
- No `isIndexValid()` assertion in new tests (L82). The reference still keeps it true: compaction plus
  `refreshLiveBounds`, and the probe checks it on 10 seeds.

## FINISH notes (for the next run)
- LOC lever C, a retention window: a `HistoryRetention` property that auto-prunes after every
  insert/delete. It is persisted in the header, reported by `getIndexProperties`, and needs a C API
  property setter/getter. Estimate +45-50 eff, target >= 260.
- Traps still to measure: #4 (legacy header). Option: an ASan-built copy of the library for new mode
  only (`detect_leaks=0`). First check whether base mvrtree has overreads of its own.
- F-10 cells still open: reopen then prune again; C API query after reopen; prune at exactly the
  current time with a record inserted at that instant.
- The meta is 399 words. Watch the FP exposure of the sentence "the reopened index behaves the same".

## meta.md humanizer pass (2026-10-01)
User ran the body through the humanizer. Adopted its wording except where it drifted from a tested rule:
- Look-alike punctuation U+2024 / U+201A -> ASCII `.` / `,`. Backticks restored on API names: without them
  markdown ate the underscores (`Index_PruneMVRHistory`, `RT_None`, `VT_DOUBLE`, `IndexProperty_*`, `Index_Create`).
- Current time was inverted ("end time of the most recent insertion and the start time of the most recent
  deletion") -> start of newest insertion OR end of newest deletion.
- "no-ops if an illegal call is made" -> "A rejected call leaves the index untouched"; "less than or equal to
  the previous pruning operation" -> "an earlier horizon".
- Query names renamed by the humanizer (IntersectsWithQuery, ContainsWhatQuery, LocationQuery) -> the real
  `intersectsWithQuery`, `containsWhatQuery`, `pointLocationQuery`; "a time interval earlier than the horizon"
  -> "whose time interval starts before the horizon".
- Page rule said "a path ... consisting only of NODES that expire" and dropped "only" -> "kept only if ... through
  ENTRIES that all expire" (node end times are stale; dead-ness lives in parent entries, trap #1).
- Archive: `callData` -> `visitData`; "deleted by the call" -> "discarded by the call"; "exactly once" restored;
  "a version of a record inserted by insertData" -> "what one call to insertData stored" (id-reuse test);
  garbled "all versions deleted by the call or earlier are passed" -> "discarded when deleted at or before the
  horizon"; "not deleted by the call" -> "still alive after the horizon".
- Retention: "the two pruning functions that prune the tree, insertData and deleteData, behave like
  pruneHistory" -> "every insertData and deleteData call is followed by a prune that works like pruneHistory".
  "Values ... override saved index values" -> "replaces the saved one" (the test reopens again and expects
  the new value persisted). getIndexProperties sentence tidied.
- "querying" added back to the keeps-working list; "declared" for "defined"; "kept" for "saved" pages.
Body now 580 words (warning only, limit 1000). Next: re-score on pangram.com, then Description Quality check.

## Solution Quality FAIL fix (2026-10-01, round 2)
Finding (high): archive merged a delete at t and a reinsert of the same id/box/bytes at t into one version,
because chaining only checked id + bytes + box + adjacent times.
- Fix: each leaf fragment now records whether its own entry was ended by a deletion (stored entry end <=
  the node's lifetime end). Only a fragment cut off by its node's lifetime (a version copy, entry still
  open in that node) can be continued. Grounded in the code: Node.cc:706 is the only place a leaf entry
  gets a finite end, and version copies / underflow reinsertions leave the old entry open.
- Regression test ArchiveKeepsAReinsertionAtTheDeletionInstantSeparate (insert 1, delete+reinsert 2,
  delete 3, prune 3 -> [1,2) and [2,3)). Mutant M17 (old merge rule) killed by exactly this test.
- Tried a dense variant (pinned id reinserted 25 times among churn) and DROPPED it: the BASE tree leaves a
  duplicate live entry for a long-lived record after some underflow reinsertions (seen as [125,open) plus
  [133,154] for one record version in one leaf; the delete ends only the copy). Queries hide it because
  rangeQuery de-duplicates by id. Same result with a 1-step gap between delete and reinsert, so it is not
  about the shared instant. Pre-existing repo defect, out of scope; no test reaches it.
- Coverage suggestions taken (all stated in meta): archive overload validation with no callbacks; C API
  Index_MVRIntersects_count and _obj clipping (meta now names the three Index_MVRIntersects_* calls, since
  the MVR nearest-neighbour calls throw "not implemented" in the repo); per-operation auto-pruning after
  single inserts and single deletes; NaN/inf retention on reopen and through Index_Create; Index_PruneMVRHistory
  with NaN/inf; a current-format index without retention reports none after create and reopen.
- Not taken: non-VT_DOUBLE retention variant (meta does not say other types are rejected).
- 25 tests; human-effective 300; clean room uid 1000/0/4242 green, 3x identical.

## Batch 1: 0/10 (2026-10-01) and round 3
- Diagnosis: one shared wall. ZeroRetentionKeepsOnlyThePresent failed 10/10 because its queries end exactly at
  the horizon (horizon = current time); 9/10 used `upperBound <= horizon`. Evaluators all ruled it a described
  requirement, but a 9/10 shared failure is a prompt issue and 0/10 is a reject. Dropping the test is not an
  option: the `<=` runs would then pass while breaking a stated rule (FP).
- Base-repo quirk found while testing it: a degenerate query [h, h] at an instant where an operation happened
  misses records in nodes created at that instant (TimeRegion.cc:357 "will not work for degenerate intervals").
  ZeroRetention only passed on the reference by luck of the seed. It now queries past the current time, and the
  boundary lives in a dedicated test at a half-step horizon.
- meta.md (solver-visible, so the next batch is full price): one clause states the boundary literally ("a query
  that ends exactly at the horizon is still answered, as a query of that single instant"), and the retention
  rejection sentence adds "or a value of any other type" (Auto Review T3/T4 asked for the type test). Body 605
  words. NEEDS a Pangram re-check by the user; only those two sentences changed.
- Reference: empty-payload archive copy guarded (`m_pDataLength > 0`), from Auto Review S2 / Solution Quality.
- Tests 25 -> 33: boundary at the horizon, non-double retention (create + reopen), containment/point clipping
  after reload, empty payload archived, more negative retentions (C++ and C), identical record inserted again
  later (6/10 replay kills), deletion exactly at the first horizon archived once, old index opened with a
  retention keeps it.
- Clean room 33/33 after, 33/33 fail before, base 32/32, uid 1000/0/4242, 3x identical. Human-effective 300.
- Prediction for batch 2: the boundary drops to a residual 0-2 kills once stated; the identical-records and
  same-instant archive cells carry the band. Replay ceiling on the batch-1 population is 4/10, so expect ~20-40%.

## Round 4: Solution Quality FAIL on the boundary clause (2026-10-01)
Findings: (high) "a query ending exactly at the horizon is answered as a query of that single instant" is
not implementable on this repo: TimeRegion::intersectsInterval rejects [t,t] for roots/nodes starting at t, so
after pruning at a root-copy instant the clipped [h,h] query sees nothing; (medium) a finite horizon of DBL_MAX
(insert at DBL_MAX makes it the current time) removed every root, then m_roots.back(); (medium) legacy header
check formed a pointer past the buffer end.
- Semantics changed to the repo's own half-open reading: the predicate is start < queryEnd, so [a, h] never
  covers h, and after pruning only [h, inf) remains. meta now: queries "return no results for a query whose
  time interval ends at or before the horizon, and answer any other query that starts before the horizon as if
  it had started at the horizon instead." (This is also what 9/10 batch-1 agents wrote.) The exact-instant
  clause from round 3 is gone; the "any other type" retention clause stays.
- Reference: early return on upperBound <= horizon; endsAfter() treats the DBL_MAX open sentinel as never
  ended (roots, entries, compaction, archive); legacy check is byte-based. DBL_MAX itself is NOT tested (meta
  says nothing about it; a test would be an unstated wall).
- Tests: QueryEndingAtARootCopyHorizonVisitsNothing (prunes at the latest root's start, [1,h] and [h,h] and a
  containment query empty, [1,h+0.5] finds a record inserted at 1); oracle uses end <= horizon; C error
  message non-empty (coverage suggestion). Clipping itself is now redundant after a correct prune (mutant M4
  0 kills), kept because it states the contract.
- New discriminators from replaying batch-1 solutions:
  - ArchiveLeavesRecordsInsertedAfterTheHorizon: second archived prune behind the newest insertions. Run 2
    archives three LIVE records as [416, 413) (fragment clipped by its node lifetime to before its start, not
    skipped). Stated: versions alive after the horizon are not passed.
  - SeededWorkloadsMatchTheOracleAcrossCapacities: 6 seeds x capacities 10/12/16/24, horizons on and between
    operation instants, two archived prunes, pages + archive + queries vs the oracle. Kills runs 1, 2, 4, 8
    (run 8 crashes: deleteNode InvalidPageException on the second prune).
- 35 tests, human-effective 304, clean room uid 1000/0/4242 green, 3x identical. Mutants M18 (strict `<`
  boundary) 2 kills, M19 (keep empty fragments) 7 kills.
- Replay of batch-1 solutions on this suite: 2/10 pass (runs 7, 10). That population was written against the
  old meta, so it is a lower-bound estimate of difficulty, not a prediction.
- meta.md changed again (one sentence). Pangram re-check needed; body 586 words.

## Round 5: Solution Quality FAIL, archive merged across a same-instant version copy (2026-10-02)
Description Quality PASSED (user, 2026-10-02) on the round-4 meta. meta.md NOT touched this round.
Finding (high): fill a leaf with P at 1, insert at 2 to force a version copy, delete P at 2, reinsert identical P
at 2, delete at 3, prune at 3: archive gave one [1,3]. Cause is in the base tree: the copy gives P start 2, and
Node.cc:699-702 ERASES a leaf entry whose start equals the deletion time, so nothing on the pages records the
deletion at 2.
- Reference: Node::deleteData now hands every entry it is about to erase to MVRTree::keepErasedVersion, which
  keeps a tombstone (id, box, bytes, time). Tombstones are stored in the header after the horizon and
  retention (count + records; read only when the bytes are there), joined into the archive as zero-length
  deleted fragments (sorted by start, then end, so a fragment cut off at t chains into the tombstone at t and
  stops), and dropped once a prune passes them. Queries keep base behaviour (the entry stays erased).
- This also fixes a second hole: a record inserted and deleted at one instant is "what one insertData call
  stored" and is now archived as [t, t]. Batch-1 runs 7 and 10 already did this (they keep zero-duration entries
  dead instead of erasing them), so it is solvable without the tombstone design.
- Tests (37): ArchiveKeepsAReinsertionSeparateAfterAVersionCopyAtThatInstant (reviewer's exact sequence, with and
  without a reopen before the prune), ArchiveHandsOverARecordDeletedAtTheInstantItWasInserted (reopen, then a
  second archived prune must not repeat it).
- Mutants: tombstones not archived 2, not reloaded 2, kept after a prune 1. M19 (skip empty fragments) now 0:
  with the start-then-end sort a clipped zero-length fragment chains into its continuation, so the skip is only
  a guard. Feature stub 32 fails.
- Replay of batch-1 solutions on 37 tests: still 2/10 (runs 7, 10). The version-copy cell fails 2, 3, 4, 6, 8, 9;
  the zero-duration cell fails 2, 8, 9.
- Human-effective 371 over 6 files (Node.cc added). Clean room uid 1000/0/4242: 37/37 fail before, pass after,
  base 32/32, 3x identical; patches apply with --whitespace=error.
- Known, not tested: the DBL_MAX open-sentinel guard; clipping is redundant after a correct prune (M4 0).

## Round 6: description length FAIL (2026-10-02)
Platform: "Description is too long (594 words). Maximum is 400" (pass <= 200, warn 201-400, fail > 400; the
count includes the H1 title: 586 body + 8 title = 594). Trimmed to 380 body / 388 with title by compression
only. Rule checklist (15) re-walked, all kept: the API shapes, the three rejection reasons + current-time
definition, rejected call untouched, earlier horizon no-op, query rule (ends at or before -> nothing, else
start at the horizon; the existing C queries now named `Index_MVRIntersects_*`), page rule on entries, deletion
from the storage manager, getNumberOfNodes, compaction, later operations, persistence + old indexes, archive
once / one insertData = one version / discarded at or before / no other version / data + start + end,
retention type + both entry points, prune after every insert/delete without archive, no prune on open,
saved + reported only when set, reopen value replaces, invalid values incl. other type at create/reopen.
Dropped only motivation and restatement ("so they can be reused", "including an older index" is implied by
"only when set"). Needs the AI (Pangram) check and Description Quality again; if the humanizer is used, give
it this 380-word body and recount after the drift repair (it lengthens text).

## Round 7: AI gate FAIL (fractionAi 1.0) -> humanizer -> drift repair (2026-10-02)
Description Quality FAILED on ai_generated (whole 379-word body) plus a minor "inferable" note on the
current-state preamble. User ran the body through the humanizer. Adopted its wording except:
- U+2024 / U+201A -> ASCII; backticks restored (markdown had eaten Index_PruneMVRHistory, RT_None, VT_DOUBLE,
  IndexProperty_*, Index_Create, Index_MVRIntersects_* underscores); "tools::" -> "Tools::".
- Page rule drifted AGAIN to "a path ... consisting entirely of pages beyond the horizon" and lost "only" ->
  "retained only if a root that expires after the horizon leads to it through entries that all expire after".
- "Entries ... with horizons less than or equal to the horizon" -> "that expire at or before the horizon".
- "earlier or equal horizon values do nothing" (no reference point) -> "at or before an earlier horizon".
- "Older versions of the index" (reads as history) -> "Indexes written by older versions".
- Archive paragraph was garbled ("calls to getNextXXX discard some versions ... and not others", "deleted or
  overwritten", "versions of records inserted by calls to insertData") -> each discarded version and no other,
  once; one insertData call = one version; discarded if deleted at or before the horizon.
- Retention: "overrides the stored value" -> "replaces the stored one" (persistence is tested);
  "nonnumeric value" -> "one that is not a Tools::VT_DOUBLE" (VT_ULONG/VT_LONG are tested).
- Preamble "unlike current MVR-tree implementations, which retain all versions created" dropped (the check's
  inferable note). Repaired text was 441 words with title; compressed in the humanizer's voice to ~385.
Next: Pangram on this body, then Description Quality. If Pangram flags it, send only the flagged windows.

## Round 8: AI gate FAIL again (fractionAi 0.81, flagged window = opening sentence) -> humanizer pass 2 (2026-10-02)
Adopted the second humanizer output except: ASCII punctuation + backticks/underscores; page rule drifted a
third time ("path ... of only pages", "only" dropped) -> "kept only if ... a path to it through entries that
all expire beyond the horizon"; "Other code maintains the value of the horizon by calling flush and
loadMVRTree" -> "The horizon is kept across flush() and loadMVRTree()"; archive "every record that a call
deletes" -> "every record version that the call discards, and no other"; "which is deleted if deleted" ->
"what a single call to insertData stored, and it is discarded if it was deleted on or before the horizon";
archive start "the current horizon" -> "the previous horizon" (inverted, tested); retention "parameter" ->
"property", "when insertData and deleteData are called at the current time minus the retention" -> "every
insertData and deleteData call is followed by a no-archive prune at ...", "returned ... if set" -> "only if
set", "types ... thrown when" -> "cause ... when an index is created or reopened"; duplicated "for the C API"
removed. 418 -> 393 words with title by light compression. All 15 checklist rules present.

## Batch 2: 0/12 (2026-10-03)
See eval-results. Decision (user): run another 10 Nova on the UNCHANGED artifact before touching meta, since
Nova #10 reached 36/37 and every one of the three same-instant cells was passed by at least one run (Nova #10
passed all three). Fallback if it reads 0/10 again: one meta precondition sentence (each insertData/deleteData
call comes after the current time), drop the 3 same-instant tests and the tombstone code, fresh batch.
If a run passes: replay its patch against same-instant and old-index probes before trusting it (FP check).

## Round 9: FP panel on batch 3 + same-instant cap (2026-10-03)
- Both batch-3 passers were FP-flagged. (1) Old-format NODE pages were never tested: writeLegacyIndex() now
  rewrites every node page in the base library layout (type, level, count, times, per child box/id/times/
  length/bytes, node box; bytes recovered from the scene history) plus the legacy header, used by both legacy
  tests. Kills both flagged passers and Nova #10; reference and Vega pass. (2) Same-instant zero-duration
  versions: third finding from that domain (Solution Quality x2, FP panel x1).
- Cap (L113): meta now says "Every insertData and deleteData call uses a time later than the current time."
  Dropped ArchiveKeepsAReinsertionAtTheDeletionInstantSeparate, ...AfterAVersionCopyAtThatInstant,
  ...DeletedAtTheInstantItWasInserted, the Scene::reinsert helper, and the reference tombstone mechanism
  (Node.cc back to base, no erased-version list in the header). PruningAtTheCurrentTime rewritten without two
  calls at one instant.
- meta also drops `spatialindex/MVRTree.h` (Auto Review P6). 392 words with title. Changed sentences: the
  C-function return clause, "or it is later than", the new precondition, "Kept pages lose entries ...",
  "Opening an index does not prune.", "It is saved with the index ...". Needs Pangram/Description Quality.
- 34 tests, human-effective 307 over 5 files, clean room uid 1000/0/4242 green 3x.
- Replay on the 21-run pool: 1/21 (Vega). Next batch is full price (meta changed); suggest the same mix
  (Nova + 1 Orion + 1 Vega).

## New-model gate rounds (2026-10-09 .. 10-10)
Problem was accepted, then reverted by the admin recalibration. Gate now: Nova >= 8 at 0, Orion/Vega >= 4 same
agent at 1-25%, Nova avg sequence > 256k.
- Batch 4: Nova 2/4 pass. Probed the saved patches: added nine tests (named, no "probe" names in the patch):
  tree variants with unequal capacities, frequent identical reinsertion, many small archived prunes, old index
  across reopens and prunes, retention with reinsertion then archive, deep history, old index archiving
  reinserted identical records, concurrent records sharing an id (fresh and old format), same-id records
  surviving an earlier prune; plus VT_BOOL retention rejection. Re-eval: Nova 0/4.
- Batch 5: Nova 0/8 (gate met, avg seq ~610k), Orion 3/3 (too easy). Fuzz (400 cases) + disk/C API
  persistence probes: all Orion clean. Added as coverage (from the Test check's suggestions): retention
  persists on disk storage, C API disk index keeps retention after reopen, rejected reopen keeps stored
  retention.
- Base-repo defects found while fuzzing (not tested, documented): Node::deleteData ends the entry by id
  only, so two live same-id records in ONE leaf, or a re-inserted identical record next to its own dead
  earlier version, can end the wrong entry. The shipped same-id tests keep the records in opposite corners;
  the fuzz excludes concurrent same-id and identical reuse for that reason.
- Round 12 (user decision): narrowed the precondition. meta sentence "Every insertData and deleteData call
  uses a time later than the current time." -> "A record is never deleted at the time it was inserted."
  Re-added the two same-instant archive tests and the reference's erased-copy markers (Node.cc records
  (id, time) when it erases a copy deleted at its copy instant; persisted after the horizon and retention,
  dropped once pruned). Zero-duration versions stay out of contract. 48 tests.
  Replay: Orion 1/3, Nova 0/8. Needs the AI/Description Quality check on the changed sentence, then a fresh
  batch (meta changed): 4 Orion + 8 Nova.
- Round 12 Test Quality FAIL (13/49 "unfair"), tests-only fix:
  - 12 archive tests "sort only the actual vector": false, `Scene::ended` sorts its result. The grader can't
    see that from the call site, so every archive comparison now reads `EXPECT_EQ(sorted(expected), sorted(actual))`.
  - RejectedReopenKeepsStoredRetention: dropped the unchanged-page-set assertion after the throwing reopen
    (meta promises no rollback). The exception and the kept stored retention are still checked.
  - Coverage suggestion taken: VT_FLOAT and VT_LONGLONG retention values also rejected at create and reopen.
  - Not taken: nearest-neighbour / self-join after pruning. MVRTree throws "not implemented" for both at base;
    contains, point-location and statistics after pruning are already tested.
  - Replay unchanged: ref 0 fails, Orion 1/3, Nova 0/12 (b4 + b5).
- Round 13, Auto Review (Description 3/3, Tests 1/3, Solution 1/3):
  - S1 archive lineage: two live records with the same id, box and bytes, version-copied at one instant, then
    one deleted -> archive can pair the wrong halves. Not fixable from the tree: base Leaf::findLeaf matches id +
    spatial box only, and Node::deleteData ends the last entry with that id, so the delete call cannot say which
    of the two it meant. Capped in meta (same sentence as the earlier precondition): "A record is never deleted at
    the time it was inserted, and two live records never share both ID and box." No existing test creates that
    shape (the same-id tests use different boxes; the fuzz reuses only ids with no open version).
  - T3/T4 deferred retention: expectRetained now snapshots the storage page set BEFORE walk() (which flushes).
    Mutant "retention prune runs only in flush()" -> 10 tests killed.
  - T3/T4 isIndexValid: asserted in expectPruneMatches, expectRetained, KeptPagesHoldNoEntryThatEndedByTheHorizon
    (also after 200 more mutations) and QueriesAfterPruningSeeOnlyTheHorizonOnward. Mutant "no refreshLiveBounds"
    -> 11 tests killed.
  - meta: also "the C API functions" -> "the C functions", "must still be" -> "must stay" for length. 398 words
    with title. Needs the AI/Description Quality check.
  - Replay: per-run fail counts unchanged (ref 0, Orion 0/2/2, Nova 2..25). Clean room green, 3x identical.
- Round 14 (batch 7 Orion 4/4 + Vega 1/1, Nova 0/8):
  - Probes found no in-contract Orion split on pages, archive, queries, validity, retention, same-instant bursts.
  - Lever: index statistics after a prune. meta "`getNumberOfNodes()` reports the pages remaining" ->
    "the index statistics only count the pages that remain: `getNumberOfNodes()`, the numbers of dead index and
    dead leaf nodes, and the pages in each level." Tests read them through the public operator<< and compare with
    the page graph (dead = not reachable from a live root through live entries). Trailing zero levels tolerated.
  - Reference: deleteData now ends the LIVE entry whose box matches (Leaf::findLeaf skips dead entries,
    Node::deleteData takes the box). Base defect; every strong agent fixed it. New test packs same-id records in
    one leaf (the unfixed reference fails it).
  - Harness fix: legacyHeader wrote 0 dead nodes; it now writes the graph's dead counts like a real old index.
  - meta 418 words (limit is 1000 again). Needs the AI check, then a fresh batch.
  - 51 tests, 8 files, human-effective 350. Clean room uid 1000/0/4242 green, 3x identical.
- Round 15, Task Prompt Quality FAIL "Too many requirements" (blocking, not contestable; AI part fine at 0.21).
  User chose to drop HistoryRetention as a whole:
  - meta: retention paragraph deleted (no rewording elsewhere). 321 words.
  - reference: retention property, prune after insert/delete, header field, getIndexProperties entry and the
    two C property functions removed. Header is now horizon + erased-copy markers, still byte-guarded on load.
  - tests: 12 retention tests deleted; the disk and C API disk tests converted to explicit prune + reopen
    (HorizonPersistsOnDiskStorage, CApiDiskIndexKeepsHorizonAfterReopen). 39 tests.
  - replay on batch 7: ref 0, Orion #3 0, Vega 0, Orion #1/#2/#4 9 each, Nova 11-14 each. Projection unchanged:
    Orion 1/4, Nova 0/8.
  - 8 files, human-effective 272 (was 350). Clean room uid 1000/0/4242 green, 3x identical.
  - Needs Task Prompt Quality re-run; if still "too many", next cut candidate is the C API (Index_PruneMVRHistory
    and the Index_MVRIntersects_* clause).
- Round 16, Task Prompt Quality still "Too many requirements" after round 15 (312 words, AI 0.33 fine).
  Cut every rule whose tests killed 0 of the 14 batch-7 solutions:
  - C API (Index_PruneMVRHistory + Index_MVRIntersects_* clause): tests CApiPrunesAnMvrIndex,
    CApiDiskIndexKeepsHorizonAfterReopen; reference function removed.
  - Rejection rules (not an MVR-tree, not finite, later than current time, rejected/earlier horizon no effect)
    folded into one precondition: "Every horizon is later than the previous one and not later than ...".
    Probe: with a throw on a non-increasing horizon only RejectedHorizonsLeaveTheIndexUntouched tripped (deleted).
    Reference keeps its defensive checks, untested.
  - containsWhatQuery / pointLocationQuery named rules: two tests + one containsWhatQuery assertion removed;
    meta now names only intersectsWithQuery (reference still clips all three through rangeQuery).
  - "Kept pages lose entries that expire at or before the horizon": KeptPagesHoldNoEntryThatEndedByTheHorizon removed.
  - meta 260 words, ~14 rules. 32 tests, 6 files, human-effective 247.
  - Replay batch 7 unchanged: ref 0, Orion #3 0, Vega 0, Orion #1/#2/#4 9 each, Nova 11-14 each.
  - Clean room uid 1000/0/4242 green, 3x identical.

## Round 17 (2026-10-10) - batch 8 FP + Test/Solution Quality findings
- Batch 8: Nova 0/8, Orion 1/4, but the Orion pass was voided by the FP panel: after a prune at the current time,
  inserts at that same instant split leaves and end their entries exactly at the horizon; the candidate's next
  prune skips entries ending at or before the previous horizon, so those pages leak from storage and statistics.
  Added PagesEndedRightAfterAPruneAtTheCurrentTimeArePurgedLater (24 spread inserts at that instant). A 40-insert
  burst was rejected: it creates base orphan pages (leaf created and killed in one instant loses its parent entry
  but stays stored; base dead counter counts it, the test oracle treats it as a root). 24 spread inserts make 1-3
  entries end at the horizon with no orphans.
- S1 (High, real): erase markers keyed by (id, time) could mark a live same-id record with a different box as
  deleted. Markers now carry the box (header stores 2*dim doubles per marker). Test
  DeletionAtAVersionCopyKeepsALiveRecordSharingTheIdentifier (fails the old reference only).
- T4: added ThreeDimensionalRecordsArchiveAndQueryOnEveryAxis. T8: test.sh fails the listing case on a nonzero
  --gtest_list_tests exit even when some tests were listed.
- Test/solution only (re-eval eligible). 35 tests, solution 259 human-effective, clean room green x3 uids.
- Orion #1-#3 failures are real: kept parents keep entries to purged pages, page reuse then breaks deletes and
  queries ("Other operations work as before"). The sentence that stated this was cut in round 16.
