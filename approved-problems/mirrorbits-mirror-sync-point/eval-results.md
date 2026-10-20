# eval-results.md - mirrorbits-mirror-sync-point

No platform batch yet.

## Local validation (SLICE, 2026-09-30)

| Check | Result |
|---|---|
| Hook human-effective (solution.patch) | 299 (raw 420, 9 files, 6 packages) |
| Base tree + test.patch, base mode | 132 testcases, 0 failures (uid 1000, 0, 4242) |
| Base tree + test.patch, new mode | 6 testcases, 6 failures (compile error, real test ids) |
| + solution.patch, base mode | 132 testcases, 0 failures (uid 1000, 0, 4242) |
| + solution.patch, new mode | 6 testcases, 0 failures (uid 1000, 0, 4242) |
| Flakiness, both patches | base 3x identical, new 3x identical |
| Gate 9, clean base tree `go test ./...` 3x | identical; TestVersion needs the Makefile ldflags (test.sh passes them) |
| Docker cold build | ~2 min |

| Test | Cell |
|---|---|
| TestSyncPointMirrorIdenticalToSourceIsAtLatestGeneration | 3 generations, mirror current |
| TestSyncPointMirrorHoldingOlderVersionsIsBehind | behind + missing, stored Mirror fields |
| TestSyncPointRehashAndNoopScansDoNotAdvance | forced rehash + no-op scan keep the clock |
| TestSyncPointUnreadableSubtreeIsUnverifiedNotMissing | exit 23 + `[sender] opendir`, sub-second source mtimes, index kept |
| TestSyncPointDeletedFileStillOnMirrorCapsGeneration | tombstoned version held caps below deletion |
| TestSyncPointScanLogReportsGeneration | log suffix through ReadLogs JSON round trip |

## Local validation (FINISH round 1, 2026-10-04)

| Check | Result |
|---|---|
| Hook human-effective | 291 (7 files: config, daemon, mirrors x2, rpc, scan x3) |
| test.patch only, base / new | 132/0 ; 15/15 failing (uid 1000, 0, 4242) |
| + solution.patch, base / new | 132/0 ; 15/0 (uid 1000, 0, 4242) |
| Flakiness 3x each mode | identical |
| No-.git build | OK |

New tests: ConflictingEvidenceHasNoSyncGeneration, TimezoneOffsetFoundBySameScan, HistoryWindowForgetsOldVersions, MissingDeletedFileIsNotMissing, PlainOpendirFormIsUnreadable, UnknownFilesAndForeignPathsAreNotEvidence, ScanLogOmitsGenerationWithoutSourceTree (scan); HealthCheckRequestsOnlyCurrentFiles (daemon); RemoveMirrorClearsScanState (rpc).

## Local validation (round 2, 2026-10-04)
After the Solution Quality fixes: 17 tests, human-effective 289. uid 1000/0/4242: base 132/0 both ways, new 17/17 fail -> 17/0 pass. Flakiness 3x identical in each mode.

## Local validation (round 3, 2026-10-04)
19 tests, human-effective 290. uid 1000/0/4242: base 132/0 both ways, new 19/19 fail -> 19/0 pass. Flakiness 3x identical.

## Local validation (round 4, 2026-10-04)
22 tests, human-effective 290. uid 1000/0/4242: base 132/0 both ways, new 22/22 fail -> 22/0 pass. Flakiness 5x identical in each mode.

## Batch 1 (10 Nova, re-eval 1, 2026-10-05): 1/10 legitimate pass (10%)

| Run | Verdict | New fails (22-test suite) | Replay on round-5 suite (24) |
|---|---|---|---|
| Nova #1 | MISSED_REQUIREMENT | MissingDeletedFileIsNotMissing | 21/24: MissingDeleted, NestedRsyncRoot, LoweredHistory |
| Nova #2 | MISSED_REQUIREMENT (base 23 fails in mirrors, own regression) | MissingDeleted | 20/24: DeletedFile (keeps FILE_ with current=false), MissingDeleted, Nested, Lowered |
| Nova #3 | MISSED_REQUIREMENT | EmptySourceTree, UnreadableModuleRoot | 19/24: + DeletedFile, Nested, Lowered |
| Nova #4 | MISSED_REQUIREMENT | HistoryWindow, MissingDeleted | 19/24: + DeletedFile, Nested, Lowered |
| Nova #5 | PASS_LEGITIMATE (judge dissent: literal opendir paths) | - | 23/24: Nested only |
| Nova #6 | MISSED_REQUIREMENT | HistoryWindow, MissingDeleted | 19/24: + DeletedFile (drops the FILE_ DEL), Nested, Lowered |
| Nova #7 | MISSED_REQUIREMENT (base TestRefreshNodeList flake) | DeletedFileCaps, HistoryWindow, MissingDeleted | 19/24 |
| Nova #8 | MISSED_REQUIREMENT | HistoryWindow, MissingDeleted | 20/24: + Nested, Lowered |
| Nova #9 | MISSED_REQUIREMENT | MissingDeleted | 22/24: + Nested |
| Nova #10 | FAIL_REGRESSION (all green; keeps live FILE_ for deleted paths) | - | 21/24: DeletedFile, Nested, Lowered |

Kill counts on the 22-test suite: MissingDeletedFileIsNotMissing 7, HistoryWindowForgetsOldVersions 4, Empty/UnreadableRoot 1, DeletedFileCaps 1. Replay on round 5: Nested 10/10, Lowered 7/10, DeletedFile (live metadata) 6/10 -> 0/10 replayed.

## Batch 2 (10 Nova, 2026-10-05): 0/10

| Run | Verdict | New fails (24-test suite) | Replay on round-6 suite (25) |
|---|---|---|---|
| Nova #1 | MISSED_REQUIREMENT | MissingDeleted, Nested, Lowered | 24/25: MissingDeleted |
| Nova #2 | MISSED_REQUIREMENT | UnreadableSubtree, PlainOpendir, Nested, Lowered | 22/25 |
| Nova #3 | MISSED_REQUIREMENT | MissingDeleted, EmptySource, UnreadableRoot, Nested, Lowered | 21/25 |
| Nova #4 | MISSED_REQUIREMENT | Nested, Lowered | 25/25 PASS |
| Nova #5 | MISSED_REQUIREMENT | MissingDeleted, EmptySource, UnreadableRoot, Nested, Lowered | 22/25 |
| Nova #6 | MISSED_REQUIREMENT | 9 fails | 17/25 |
| Nova #7 | WRONG_LOGIC (base 130/130 and new 24/24 failed on the platform) | all | 23/25 locally: MissingDeleted, OpendirWithoutPartial |
| Nova #8 | MISSED_REQUIREMENT | MissingDeleted, Nested, Lowered | 23/25 |
| Nova #9 | MISSED_REQUIREMENT | MissingDeleted, Nested, Lowered | 23/25 |
| Nova #10 | MISSED_REQUIREMENT | Nested, Lowered | 25/25 PASS |

Nested 9/9 and Lowered-before-a-source-scan 9/9 among the runs that built. The same reason everywhere: opendir paths matched literally, and the loaded history not pruned to a lowered depth until a source scan. Replay of all 20 saved patches on the round-6 suite: batch 2 -> 2/10 (#4, #10), batch 1 -> 1/10 (#5).

## Batch 3 (new models, 2026-10-09): Nova 0/8, Orion 2/2 -> too easy for Orion

| Run | Solver | Verdict | New fails (25-test suite) | Nova seq len |
|---|---|---|---|---|
| Nova #1 | Nova (eval Nova) | MISSED_REQUIREMENT | HealthCheck, UnreadableSubtree, UnreadableModuleRoot, Lowered, DeletedPathUnderUnreadable | 539k |
| Nova #2 | Nova | MISSED_REQUIREMENT | HealthCheck, UnreadableSubtree, ScanLogOmits, UnreadableModuleRoot, DeletedPathUnderUnreadable | 635k |
| Nova #3 | Nova | WRONG_LOGIC | ScanLogOmitsGenerationWithoutSourceTree (sole) | 538k |
| Nova #4 | Nova | MISSED_REQUIREMENT | HealthCheck, UnreadableSubtree, UnreadableModuleRoot, Lowered, DeletedPathUnderUnreadable | 541k |
| Nova #1 (2nd) | Nova (eval Orion) | MISSED_REQUIREMENT | HealthCheck, UnreadableSubtree, UnreadableModuleRoot, Lowered, DeletedPathUnderUnreadable | 547k |
| Nova #2 (2nd) | Nova | MISSED_REQUIREMENT | 5 incl. Lowered | 535k |
| Nova #3 (2nd) | Nova | MISSED_REQUIREMENT | LoweredHistoryForgetsAfterNextSourceScan (sole) | 544k |
| Nova #4 (2nd) | Nova | MISSED_REQUIREMENT | HealthCheck, UnreadableSubtree, UnreadableModuleRoot, DeletedPathUnderUnreadable | 268k |
| Orion #1 | Orion | PASS_LEGITIMATE | - | - |
| Orion #3 | Orion | PASS_LEGITIMATE | - | - |

Orion #2 and #4 could not complete and were not counted (user). Gate: Nova 0/8 OK, Nova avg sequence length 518k OK (> 256k), Orion 2/2 = too easy.

Differential probes (13 scenarios: prefix-named unreadable dir, two unreadable dirs, delete-and-re-add, stale stored fields, all-unknown, SourceHistory 1, tz shift on a second scan, FTP MDTM whole seconds, FTP MLST only, FTP without timestamps) on the reference, both Orion passers and the two Nova sole-failure runs: zero divergence. No tests-only lever splits Orion (L83).

## Local validation (round 7, 2026-10-09)
28 tests, human-effective 372. Clean clone at BASE, --network none, uid 1000/0/4242: base 131/0 both ways, new 28/28 fail -> 28/0 pass. Flakiness 5x identical in each mode. Batch-3 replay on the round-7 suite: every run fails the four new re-evaluation cells (expected: they never saw the rule), nothing else changed.

## Local validation (round 8, 2026-10-10)
28 tests, human-effective 374. uid 1000/0/4242: base 131/0 both ways, new 28/28 fail -> 28/0 pass. Flakiness 5x identical in each mode (after fixing the async cluster-lock race in the test helpers).

## Local validation (round 9, 2026-10-10)
28 tests, human-effective 374. uid 1000/0/4242: base 131/0 both ways, new 28/28 fail -> 28/0 pass. Flakiness 5x identical.

## Batch 4 (2026-10-10, round-8 test.patch; round 9 landed after the batch started)
| Run | Solver | Verdict | New fails (28-test suite) | Max step tokens |
|---|---|---|---|---|
| Nova #8 (dir Nova_Nova_1) | Nova | coding | OpendirWithoutPartialTransferIsEvidence (sole) | 262k |
| Nova #7 | Nova | coding | 6: [sender] opendir pre-filter cluster (UnreadableSubtree, UnreadableModuleRoot, DeletedPathUnderUnreadable, ReevaluationKeepsUnreadable, HealthCheck) + EmptySourceTree | 274k |
| Nova #6 | Nova | coding | 6: [sender] cluster + LoweredHistory (pruning skipped on no-op scans) | 253k |
| Nova #5 | Nova | coding | 3: EmptySourceTree, OpendirWithoutPartialTransfer, UnreadableModuleRoot (evidence>0 guard) | 277k |
| Nova #4 | Nova | coding | 6: [sender] cluster + RecurringVersion | 301k |
| Nova #3 | Nova | coding | 6: [sender] cluster + EmptySourceTree | 276k |
| Nova #2 | Nova | coding | 6: [sender] cluster + OpendirWithoutPartialTransfer | 280k |
| Nova #1 | Nova | coding (baseline broken too: mirrors pkg) | 8: [sender] cluster + EmptySourceTree, LoweredHistory, RecurringVersion | 275k |
| Orion #4 | Orion | TEST_BROKEN | 26 (scan pkg compile: test.patch rsyncListing vs agent's scan_test.go) | - |
| Orion #3 | Orion | TEST_BROKEN | 26 (same collision, agent's scan/integration_test.go) | - |
| Orion #2 | Orion | PASS_LEGITIMATE | - | - |
| Orion #1 | Orion | PASS_LEGITIMATE | - | - |

Gate: Nova 0/8 OK. Nova sequence length (max single step, no compaction) averages ~275k: passes > 256k but with little margin (batch 3 read 518k). Orion 2 passes + 2 broken.

Replay of all 4 Orion patches on the round-10 test.patch (collision fixed + round-9 cells): 28/28 each, i.e. **Orion 4/4 = too easy**. Re-eval would only confirm this.

Differential probes, round 10 (40 cells: re-evaluation of unknown paths/versions that later appear, deleted-but-remembered listed, delete/re-add gap, window before add, window forgetting a deleted path (h2/h3), 5 opendir spellings, FTP re-eval precision, latest listing replaces, unreadable-root re-eval, multi-change step, exit 23 without opendir, new file in unreadable dir, no-op/rehash re-eval after lowering history, recurring version x window, FILEMIRRORS/FILEINFO/MIRRORFILES/Removed/HANDLEDFILES around unreadable dirs and unknown paths): the 4 Orion patches equal the reference on every meta-stated cell. Divergences only off-contract: `[generator] opendir` (reference accepts, not stated), `opendir "x/" failed` without "(in module)" (Orions accept, reference does not; never produced by an rsync daemon), and KnownIndexed/HANDLEDFILES counting kept unreadable paths (O1-O3 count them, reference and O4 do not; meta silent). Tests-only lane exhausted.

## Local validation (round 10, 2026-10-10)
Collision fix only (package-level test helpers suffixed with the file hash). uid 1000/0/4242: base 131/0 both ways, new 28/28 fail -> 28/0 pass. Flakiness 5x identical.

## Local validation (round 10b, 2026-10-10)
31 tests (+FTP refused subdirectory, +FTP other listing failure, +opendir relative to the module), human-effective 388. uid 1000/0/4242: base 131/0 both ways, new 31/31 fail -> 31/0 pass. Flakiness 5x identical. Batch-4 replay on this suite: Orion 29/31 each (both new positive cells), Nova 21-28/31.

## Batch 5 (2026-10-11, round-10b artifact: 31 tests, meta 396w)
| Run | Solver | Verdict | New fails (31) | Sequence length (largest window) |
|---|---|---|---|---|
| Nova #8 (dir Nova_Nova_1) | Nova | MISSED_REQ | 8: OpendirWithoutPartialTransfer + [sender] cluster (UnreadableSubtree, UnreadableModuleRoot, DeletedPathUnderUnreadable, ReevaluationKeepsUnreadable, HealthCheck) + OpendirRelativeToModule + LoweredHistory | 538k (277k) |
| Nova #7 | Nova | WRONG_LOGIC | 7: OpendirWithoutPartial + [sender] cluster + OpendirRelativeToModule | 539k (278k) |
| Nova #6 | Nova | MISSED_REQ | 2: OpendirWithoutPartial, LoweredHistory | 542k (280k) |
| Nova #5 | Nova | MISSED_REQ | 7: OpendirWithoutPartial + [sender] cluster + OpendirRelativeToModule | 533k (276k) |
| Nova #4 | Nova | MISSED_REQ | 4: OpendirWithoutPartial, UnreadableModuleRoot, EmptySourceTree, LoweredHistory | 529k (273k) |
| Nova #3 | Nova | MISSED_REQ | 8: OpendirWithoutPartial + [sender] cluster + OpendirRelativeToModule + LoweredHistory | 550k (283k) |
| Nova #2 | Nova | MISSED_REQ | 8: same as Nova #3 | 559k (287k) |
| Nova #1 | Nova | MISSED_REQ | 2: OpendirWithoutPartial, DeletedFileStillOnMirrorCapsGeneration | 546k (282k) |
| Orion #4 (dir Orion_Nova_1) | Orion | MISSED_REQ | OpendirWithoutPartialTransferIsEvidence (sole) | 107k |
| Orion #3 | Orion | MISSED_REQ | OpendirWithoutPartialTransferIsEvidence (sole) | 100k |
| Orion #2 | Orion | PASS_LEGITIMATE | - | 86k |
| Orion #1 | Orion | PASS_LEGITIMATE | - | 112k |

Gate: Nova 0/8 OK. Nova sequence length (platform `final_metrics.extra.sequence_length`, compaction windows summed) averages **542k** OK. Correction: batch 4 averaged 438k on the same metric; the 275k recorded above was the largest single window, not the gate metric. **Orion 2/4 = too easy.**

Kills by test: OpendirWithoutPartialTransfer 10 (8 Nova + 2 Orion), UnreadableModuleRoot 6, HealthCheck / UnreadableSubtree / LoweredHistory / DeletedPathUnderUnreadable / ReevaluationKeepsUnreadable / OpendirRelativeToModule 5 each (all Nova), EmptySourceTree 1, DeletedFileStillOnMirror 1. The 3 round-10b tests (FTP refused subdirectory, FTP other failure, module-relative opendir) killed no Orion; every Nova run that failed module-relative also failed the partial-transfer cell, so they added nothing to the gate.

Platform checks on this artifact: Task Prompt Quality FAIL "Too many requirements" (blocking). AI review: Problem Description 3/3, Tests 2/3 (no readable empty rsync listing, no `/private2` sibling of an unreadable `/private`), Solution & Code 1/3 (S1 High: a mirror scan's sync point computed from generation G can overwrite the source scan's G+1 re-evaluation; separate locks, unconditional write). Solution Quality PASS, with a Medium for one synchronous HMGET per file during re-evaluation.

Differential probes, round 11 (14 new cells on the reference and all 10 saved Orion patches): `/private2` sibling of an unreadable `/private`, time-only mismatch, readable empty listing, a source scan landing while a mirror scan's rsync is running (mid and final state), unreadable dir later readable without the file, mirror scanned before any source scan, both opendir forms in one scan, opendir for a directory the source lacks, second partial scan with a different directory, re-evaluation after lowering history, MIRROR_UPDATE publication. Batch 4/5 Orions equal the reference on every stated cell (batch 3 Orions predate re-evaluation). Only off-contract differences remain (HANDLEDFILES/KnownIndexed counting kept paths). No test-side lever.

## Local validation (round 11, 2026-10-11)
26 tests (cut 8 with their rules, added 3), human-effective 376. Clean clone at BASE, --network none, uid 1000/0/4242: base 131/0 both ways, new 26/26 fail -> 26/0 pass. Flakiness 5x identical in each mode. Replay of batch 5 + batch-4 Orions on this suite: Orion 19-20/26, Nova 13-18/26; the shared failures are the readlink_stat rule and the foreign-path-is-unknown change, which none of them saw. ReadableEmptyListing: 8/8 Nova fail, 0/8 Orion.

## Local validation (round 11b, 2026-10-11)
25 tests (health-check test dropped with its rule), human-effective 359. uid 1000/0/4242: base 131/0 both ways, new 25/25 fail -> 25/0 pass. Flakiness 5x identical in each mode.

## Local validation (round 11c, 2026-10-11)
23 tests (re-evaluation tests dropped with the rule), human-effective 290. uid 1000/0/4242: base 131/0 both ways, new 23/23 fail -> 23/0 pass. Flakiness 5x identical in each mode.

## Local validation (round 11d, 2026-10-11)
24 tests (assert sync + source generation only; +UnmatchedVersionIsNotCurrent), human-effective 251. uid 1000/0/4242: base 131/0 both ways, new 24/24 fail -> 24/0 pass. Flakiness 5x identical in each mode. Every stated rule has a killing mutant test.

### Local validation (round 12)
uid 1000/0/4242: base 131/0 with and without the solution; new 24/24 fail -> 24/0 pass. Flakiness 5x identical in both modes (base md5 0bbc607..., new e81f06d...). human-effective 267. Raised-history probe: r11d reference 2/3, r12 0/3.

### Local validation (round 13)
uid 1000/0/4242: base 131/0 with and without the solution; new 25/25 fail -> 25/0 pass. Flakiness 5x identical in both modes (base md5 0bbc607..., new e47a6fa...). Reviewer mutants: "From >= oldest" fails only PathCurrentSinceBeforeTheWindowIsStillEvidence; "first occurrence only" fails only RecurringVersionCoversBothPeriods.

## Batch 6 (round-13 artifact, 2026-10-13): Orion 3/4 = too easy (no Nova runs)
| Run | Agent | Verdict | Failed tests | Files / +LOC | Sequence length |
|---|---|---|---|---|---|
| Orion #1 | Orion | PASS_LEGITIMATE (FP panel: genuine, high) | - | 11 / +847 | 75k |
| Orion #2 | Orion | PASS_LEGITIMATE (FP panel: genuine, medium, one judge dissent on the walkSource change) | - | 10 / +823 | 73k |
| Orion #3 | Orion | FAIL_MISSED_REQUIREMENT | UnstattableEntriesAreUnverified, UnreadableEntriesDoNotCoverSiblingPrefixes (its readlink_stat regex needs the literal word "module" from the meta's `(in module)` placeholder) | 11 / +933 | 80k |
| Orion #4 | Orion | PASS_LEGITIMATE (FP panel: genuine, high) | - | 11 / +928 | 76k |

All four Orions made walkSource return filepath.Walk errors (ScanSource aborts on an unreadable source entry; base and reference skip it). Not testable as a calibrator: it would kill all four, and chmod does not block root graders.

Differential probes, round 14 (17 cells: raised history after pruning, raised history after an unchanged scan, mirror before any source scan, delete then identical restore, exit 23 with no unreadable lines, paths with spaces/parens in both forms, trailing slash, no leading slash, other module name, rehash with a change, lowered history without a source scan, SourceHistory 0, sub-second source times, deletion-only advance, stored fields after a source change): the 3 passers equal each other on every cell. Versus the reference: raised history after an unchanged scan (reference bug, Orions right: fixed), and lowered history without a source scan (all 4 Orions forget only at the next source scan, reference applies the new depth at once; meta silent, unanimous, the batch-2 wall, not a lever). Orion #3 differs only on readlink_stat module names. Tests-only lane still empty.

Replay on the round-14 suite (27 tests): Orion 1, 2, 4 27/27, Orion 3 25/27, so a re-eval would read 3/4 again.

### Local validation (round 14)
uid 1000/0/4242: base 131/0 with and without the solution; new 27/27 fail -> 27/0 pass. Flakiness 5x identical in both modes (base md5 0bbc607..., new e45dabe...). human-effective 285.

### Local validation (round 15)
- solution.patch only (regexp capturing group, known-file count after kept paths merge); test.patch and meta unchanged. human-effective 283.
- uid 1000/0/4242: base 131/0 with and without the solution; new 27/27 fail -> 27/0. Flakiness 5x identical (base 0bbc607..., new e45dabe...).

## Batch 7 (r15 artifact: r14 meta swap + r15 solution fix), Orion x4, no Nova
| Run | Verdict | New | Failed tests | Approach note |
|---|---|---|---|---|
| Orion #2 (Orion_Orion_1) | PASS_LEGITIMATE | 27/27 | - | ledger + window solver; diagnostic regex has no `(in ...)` suffix at all |
| Orion #1 (Orion_Orion_2) | FAIL | 25/27 | UnstattableEntriesAreUnverified, UnreadableEntriesDoNotCoverSiblingPrefixes | regex hardcodes `\(in module\)\)` |
| Orion #4 (Orion_Orion_3) | PASS_LEGITIMATE | 27/27 | - | regex `\(in [^)]*\)\)` |
| Orion #3 (Orion_Orion_4) | FAIL | 25/27 | same two | regex hardcodes `\(in module\)\)` |
- Orion 2/4 (too easy). The r14 swap rule (SourceHistory reread at every scan, forgotten for good) killed 0/4: every run passes all history tests.
- Only failure class across batches 6-7: the literal `(in module)` reading (3 of 8 runs). Auto Review r15: Description 1/3, P4 High, asks to mark `module` as a placeholder. Tests 3/3, Solution 3/3. That fix removes the only Orion failure, so the expected Orion rate after it is ~4/4.
- FP panel: both passes genuine (judge dissent on rsync paths containing a literal double quote; the reference fails that probe too, so it doesn't discriminate). Review notes: walkSource now aborts on unreadable source dirs (both passers); SourceHistory < 1 rejected instead of clamped (Orion #2).

## Batch 8 (r16 meta `(in <module>)`, r15 solution, 27 tests): Nova x8 + Vega x4
| Run | Verdict | New | Seq len | Failed tests | Approach note |
|---|---|---|---|---|---|
| Nova #8 (Nova_Orion_1) | PASS_LEGITIMATE | 27/27 | 537k (compacted) | - | full snapshot per generation (SOURCE_GEN_<g> hashes); change detection re-parses FILE_ modTime with base's Time.String layout |
| Nova #7 (Nova_Orion_2) | FAIL | 26/27 | 264k | OpendirWithoutPartialTransferIsEvidence | unreadable paths collected without checking code 23 |
| Nova #6 (Nova_Orion_3) | FAIL | 26/27 | 543k (compacted) | OpendirWithoutPartialTransferIsEvidence | same |
| Nova #5 (Nova_Orion_4) | FAIL | 26/27 | 266k | OpendirWithoutPartialTransferIsEvidence | same |
| Nova #4 (Nova_Orion_5) | FAIL | 22/27 | 238k | UnreadableModuleRootIsUnverified, 3 raised-history tests, OpendirWithoutPartialTransfer | no monotonic floor |
| Nova #3 (Nova_Orion_6) | FAIL | 25/27 | 266k | EmptySourceTreeStartsGenerationOne, UnreadableModuleRootIsUnverified | needs positive evidence, returns 0 when there is none |
| Nova #2 (Nova_Orion_7) | FAIL | 23/27 | 242k | 3 raised-history tests, OpendirWithoutPartialTransfer | no floor |
| Nova #1 (Nova_Orion_8) | FAIL_REGRESSION | 27/27 | 251k | - (evaluator: SCARD inside unexecuted MULTI deletes FILES) | all-green but breaks the FILES index |
| Vega #3 (Vega_Orion_2) | PASS_LEGITIMATE | 27/27 | 86k | - | per-path version intervals as JSON, UnixNano times, raise-only Lua floor (Script.Send = EVAL) |
| Vega #4 (Vega_Orion_1) | FAIL | 26/27 | 84k | OpendirWithoutPartialTransferIsEvidence | code-23 qualifier missed |
| Vega #2 (Vega_Orion_3) | FAIL | 24/27 | 85k | 3 raised-history tests | no floor |
| Vega #1 (Vega_Orion_4) | FAIL | 24/27 | 89k | 3 raised-history tests | no floor |
- Nova 1/8 (gate needs 0), Vega 1/4 (in gate). Nova average sequence length 326k (> 256k; min 238k).
- FP panel: both passes genuine. Vega adjudicator note: SourceHistory=0 unspecified (Vega remembers nothing, reference clamps to 1).
- Auto Review: Description 3/3, Tests 2/3 (T3/T4 Medium: SourceHistory never loaded through YAML), Solution 1/3 (S1 High: "Script.Send queues EVALSHA, NOSCRIPT on a cold Redis"). The S1 claim is false for the pinned redigo (e8fc0692): Script.Send sends EVAL with the full source (redis/script.go:83); SendHash is the EVALSHA one.

### Replay of batch 8 against the r16 test.patch (29 tests)
| Run | New | Failed |
|---|---|---|
| REF | 29/29 | - |
| Nova #8 | 28/29 | NoopScansDoNotAdvanceInAnyLocalTimezone |
| Nova #7, #6, #5 | 28/29 | OpendirWithoutPartialTransferIsEvidence |
| Nova #4 | 24/29 | unchanged set |
| Nova #3 | 26/29 | + SourceHistoryLoadsFromConfigFile (its no-evidence-returns-0 bug) |
| Nova #2 | 24/29 | + NoopScansDoNotAdvanceInAnyLocalTimezone |
| Nova #1 | 28/29 | MirrorIdenticalToSourceIsAtLatestGeneration (KnownIndexed 0) |
| Vega #3 | 29/29 | - |
| Vega #4 | 28/29 | unchanged |
| Vega #2 | 26/29 | unchanged |
| Vega #1 | 25/29 | + NoopScansDoNotAdvanceInAnyLocalTimezone |
- Predicted re-eval: Nova 0/8, Vega 1/4.

## Batch 10 / re-eval 2 (2026-10-14), r18 suite (29 tests)
| Run | Verdict | New | Seq | Failed | Note |
|---|---|---|---|---|---|
| Nova #8 (Nova_Orion_1) | FAIL | 28/29 | 537k | NoopScansDoNotAdvanceInAnyLocalTimezone | re-parses base Time.String layout |
| Nova #7 (Nova_Orion_2) | FAIL | 28/29 | 264k | OpendirWithoutPartialTransferIsEvidence | code-23 qualifier missed |
| Nova #6 (Nova_Orion_3) | FAIL | 28/29 | 543k | OpendirWithoutPartialTransferIsEvidence | same |
| Nova #5 (Nova_Orion_4) | FAIL | 28/29 | 266k | OpendirWithoutPartialTransferIsEvidence | same |
| Nova #4 (Nova_Orion_5) | FAIL | 24/29 | 238k | 3 floor tests, Opendir, UnreadableModuleRoot | no floor |
| Nova #3 (Nova_Orion_6) | FAIL | 26/29 | 266k | EmptySourceTree, UnreadableModuleRoot, SourceHistoryLoadsFromConfigFile | needs positive evidence |
| Nova #2 (Nova_Orion_7) | FAIL | 25/29 | 242k | 2 floor tests, Opendir, timezone | no floor |
| Nova #1 (Nova_Orion_8) | FAIL_REGRESSION | 28/29 | 251k | MirrorIdenticalToSource (KnownIndexed) | FILES index deleted |
| Vega #4 (Vega_Orion_1) | FAIL | 28/29 | 84k | Opendir | code-23 qualifier missed |
| Vega #3 (Vega_Orion_2) | PASS_LEGITIMATE | 29/29 | 86k | - | FP genuine |
| Vega #2 (Vega_Orion_3) | FAIL | 26/29 | 85k | 3 floor tests | no floor; no blocker this time |
| Vega #1 (Vega_Orion_4) | FAIL | 25/29 | 89k | 3 floor tests, timezone | no floor |
| fresh Vega (Vega_Orion_5) | FAIL | 26/29 | 85k | 3 floor tests | no floor |
- Nova 0/8 (avg seq 325k), Vega 1/5. Auto Review: Desc 3, Tests 1 (two T3/T4 Highs: empty final listings), Solution 3.

### Replay of batch 10 against the r19 test.patch
- Same as above except Nova #3 also fails RaisedHistoryDoesNotRestoreForgottenVersions. Predicted re-eval: Nova 0/8, Vega 1/5.
