# eval-results.md - libspatialindex-mvr-history-pruning

No platform batch yet.

## Local validation (2026-09-29, SLICE)

| Check | Result |
|---|---|
| Image build (`docker build --no-cache`, Dockerfile in folder) | OK, 67 s |
| Clean room uid 1000, `--network none`, clone at BASE with .git | test.patch + solution.patch apply cleanly |
| base mode before solution | 32 tests, 0 failed |
| new mode before solution | 15 testcases, 15 failed (compile fallback, real test names) |
| base mode with solution, 3 runs | 32/32 pass, identical |
| new mode with solution, 3 runs | 15/15 pass, identical |
| uid 0 and uid 4242 | base 32/32, new 15/15 |
| effective LOC hook (solution.patch) | raw 305, human-effective 217, 5 files |

Mutant kill counts (new tests failing):

| Mutant | Kills |
|---|---|
| M1 prune dead roots only | 3 |
| M2 delete dead-root subtrees ignoring shared pages | 12 |
| M3 archive per fragment | 4 |
| M4 no query clipping | 8 |
| M5 legacy header read unconditionally | 0 (UB overread reads allocator metadata, near 0) |
| M6 no compaction | 4 |

## Local validation (2026-10-01, FINISH)

| Check | Result |
|---|---|
| Image build (`docker build --no-cache`, fresh clone at BASE) | OK, 4m13s (slice measured 67 s; under the 600 s cap) |
| base mode before solution, uid 1000 | 32 tests, 0 failed |
| new mode before solution, uid 1000 / 0 / 4242 | 23 testcases, 23 failed (compile fallback, real test names) |
| base mode with solution, 3 runs, uid 1000 | 32/32, identical |
| new mode with solution, 3 runs, uid 1000 | 23/23, identical |
| uid 0 and uid 4242 with solution | base 32/32, new 23/23 |
| solution-then-test apply order, then reverse both | both pass; reverse leaves only the copied Dockerfile untracked |
| effective LOC hook | raw 411, human-effective 297, padding floor 50, 5 files |
| feature stub (pruneHistory returns before doing anything) | 21/23 fail; survivors are the two validation-only tests |

Mutants (one process per test, crashes count as kills):

| Mutant | Kills |
|---|---|
| M1 prune dead roots only | 7 |
| M2 delete whole subtrees ignoring sharing | 19 |
| M3 archive per fragment (no chaining) | 7 |
| M4 no query clipping | 13 |
| M5 legacy header read unconditionally | 1 (was 0; storage slack test) |
| M6 no compaction | 11 |
| M7 retention not applied after deleteData | 5 |
| M8 retention not read back from the header | 1 |
| M9 reopen value ignored | 2 |
| M10 retention applied when the index opens | 1 |
| M11 HistoryRetention always reported | 1 |
| M12 archive start not clipped to the previous horizon | 3 |
| M13 horizon not read back | 4 |
| M14 no live-bound refresh | 0 (boxes only looser; needs isIndexValid, L82) |
| M15 archive only from pruned pages | 7 |
| M16 infinite retention accepted | 1 |

## Local validation (2026-10-01, round 2 after Solution Quality FAIL)
25 new tests: 25/25 fail before the solution (uid 1000/0/4242), 25/25 pass after, 3 runs identical;
base 32/32 both ways. Human-effective 300. Mutants: as above plus M17 merge-after-deletion 1 kill
(ArchiveKeepsAReinsertionAtTheDeletionInstantSeparate); M11 now 2, M16 2, feature stub 22/25.

## Batch 1 (2026-10-01): 10x Nova, 0/10 PASS
Description clear: true in all 10 evaluations; every failure category "coding" (missed requirement).

| Run | New | Failed tests | Cause |
|---|---|---|---|
| Nova #10 (dir 1) | 14/25 | 11 incl. Zero, queries, reuse, legacy, retention | `queryStart >= upperBound` returns nothing: every zero-duration query empty |
| Nova #9 (dir 2) | 24/25 | ZeroRetentionKeepsOnlyThePresent | `upperBound <= horizon` returns nothing |
| Nova #8 (dir 3) | 24/25 | Zero | `<=` |
| Nova #7 (dir 4) | 23/25 | SecondArchiveStartsAtThePreviousHorizon, Zero | archive merges versions across a second prune; `<=` |
| Nova #6 (dir 5) | 5/25 | 20 | ordinary deleteData returns false after its Node changes |
| Nova #5 (dir 6) | 23/25 | ArchiveKeepsAReinsertionAtTheDeletionInstantSeparate, Zero | archive merges delete+reinsert at one instant; `<=` |
| Nova #4 (dir 7) | 24/25 | Zero | `<=` |
| Nova #3 (dir 8) | 24/25 | Zero | `<=` |
| Nova #2 (dir 9) | 23/25 | ArchiveKeepsAReinsertion..., Zero | merge at one instant; `<=` |
| Nova #1 (dir 10) | 24/25 | Zero | `<=` |

ZeroRetentionKeepsOnlyThePresent killed 10/10 (sole failure of 5 runs). Its horizon is the current time, so its
random queries end exactly at the horizon; 9/10 wrote `if (upperBound <= horizon) return;` where the reference
has `<`. Meta only said "a query ... ending before the horizon will return no results".

## Replay of batch-1 solutions against the round-3 suite (local, worktrees/_mvr_cr/replay)
Reproduced the platform verdicts exactly first. Round-3 suite (33 tests): reference 33/33.
- QueryEndingExactlyAtTheHorizonSeesWhatIsAliveThen: 10/10 kills (the `<=` boundary, now its own test at a
  half-step horizon).
- ArchiveSeparatesIdenticalRecordsInsertedAgainLater: 6/10 (1, 3, 4, 5, 6, 9). Same id + same box + same bytes
  inserted again later; runs 3/7-style archives reach back to the first version's stale copies.
- No kills on 2/7/8/10 from: other variant type, reopened containment/point clipping, empty payload, more
  negatives, deletion exactly at the first horizon, old index opened with a retention.
- If the boundary is neutralised by the meta clause: runs 2, 7, 8, 10 pass = 4/10 on this population.

## Replay of batch-1 solutions on the round-4 suite (35 tests)
| Run dir | Fails |
|---|---|
| 1 | 13 (zero-duration queries empty, identical records, seeded) |
| 2 | Seeded, ArchiveLeavesRecordsInsertedAfterTheHorizon (live records archived as [start > end)) |
| 3 | ArchiveSeparatesIdenticalRecordsInsertedAgainLater |
| 4 | SecondArchive, identical records, seeded |
| 5 | ~30 (broken deletes) |
| 6 | reinsertion at the deletion instant, identical records |
| 7 | none |
| 8 | Seeded (deleteNode InvalidPageException on the second prune) |
| 9 | reinsertion at the deletion instant, identical records |
| 10 | none |
2/10 would pass. The boundary rule (`<=`) now matches what these runs wrote, so it kills none of them.

## Batch 2 (2026-10-03): 10 Nova + 1 Orion + 1 Vega, 0/12 PASS (round-8 meta, 37 tests)
All evaluations description_clear true, category coding.

| Run | New | Failed |
|---|---|---|
| Nova #10 | 36/37 | IndexWrittenBeforePruningExistedStillOpensAndPrunes (old-index archive starts from page copies, [35,56] vs [1,56]) |
| Vega #1 | 34/37 | the 3 same-instant cells |
| Nova #6 | 35/37 | VersionCopyAtThatInstant, IdenticalRecordsInsertedAgainLater |
| Nova #9 | 33/37 | 3 same-instant cells + identical records |
| Nova #3 | 33/37 | same |
| Nova #1 | 30/37 | pages + archive (7) |
| Nova #2 | 27/37 | degenerate queries after the horizon empty (10) |
| Orion #1 | 25/37 | retained versions unreachable, zero-duration not archived (12) |
| Nova #5 | 23/37 | archived payload corrupted (14) |
| Nova #7 | 22/37 | pages + archive (15) |
| Nova #8 | 20/37 | version tracking (17) |
| Nova #4 | 18/37 | queries + archive + counts (19) |

Kill counts: HandsOverARecordDeletedAtTheInstantItWasInserted 9, VersionCopyAtThatInstant 8, ReopenedIndexArchives 7,
Seeded 7, IdenticalRecords 7, legacy 6, PagesReused 6, ArchiveAfterRetention 6, InsertedAfterTheHorizon 5,
ReinsertionAtTheDeletionInstant 5, then 3-4 each for the rest. Every test killed at least 3.
Without the 3 same-instant cells: 1/12 (Vega). Without only the legacy test: 1/12 (Nova #10), but that run's
old-index archive defect is stated and named in its own eval (FP risk).

## Batch 3 pool (2026-10-03): agent-runs/3 = batch-2 runs + 9 new Nova, 2/21 "passes", both FP-flagged
- Nova_Nova_2 / Nova_Nova_4 passed 37/37; FP panel flagged both (high confidence):
  - per-entry logical version ids / insertion times kept in a NEW node format; on old-format node pages the
    fallback archives page-copy starts ([10,12] instead of [0,12]). Our legacy test only rewrote the HEADER, so
    every page was in the solution's own format. Hole in the tests.
  - dedup key (id, length, data, box, end) merges two identical zero-duration versions ending at one instant.
    Same-instant domain again.
- Fails per test (37-test suite): ReopenedIndexArchives 14, Seeded 14, PagesReused 13, VersionCopyAtThatInstant 12,
  legacy 11, zero-duration 11, ArchiveAfterRetention 11, ...

## Replay of the 21 pooled solutions on the round-9 suite (34 tests)
Vega passes. Fail only the old-format-pages legacy test: Nova_2, Nova_4 (the two FP-flagged passers), Nova_10.
Fail only identical-records: Nova_11, Nova_14, Nova_17. Rest fail page/archive cells. 1/21.

## Batch 4 (2026-10-09, new-model gate): 4 Nova, 2 PASS (too easy)
Nova #4 34/34 PASS, Nova #1 34/34 PASS, Nova #3 32/34 (reused-id archive cells), Nova #2 19/34.
Sequence length 556k-657k (avg ~620k, gate > 256k).

## Round 10 (tests only, re-eval of batch 4)
Probe suite against the saved patches: both passers fail fair cells. Nova #1-run: old-format pages with
identical-record reuse (archives later versions from the first insertion, [1,49] vs [34,49]). Nova #4-run:
concurrent records sharing an id (hands each the wrong deletion time). Old-model Vega passes all 43.
43 tests. Re-eval of batch 4 then returned all four Nova as fails.

## Batch 5 pool (2026-10-10): Nova 0/8, Orion 3/3 PASS
| Run | New | Failed |
|---|---|---|
| Nova #1 | 41/43 | concurrent same-id (2) |
| Nova #1 (dir 2) | 38/43 | old index x3, same-id x2 |
| Nova #5 | 39/43 | old index x3, same-id |
| Nova #3 | 39/43 | identical reuse, old index reuse, same-id x2 |
| Nova #2 | 39/43 | old index x3, same-id |
| Nova #1 (dir 6) | 38/43 | old index x3, same-id x2 |
| Nova #4 re-eval | 39/43 | old index x2, same-id x2 |
| Nova #1 re-eval | 41/43 | same-id x2 |
| Orion #4, #3, #1 | 43/43 | PASS_LEGITIMATE (Orion #2 not exported) |
Nova average sequence length ~610k. Orion sequence ~110k each.

## Round 12 replay (48 tests, narrowed precondition)
Orion_1 passes; Orion_2 and Orion_3 fail only ArchiveKeepsAReinsertionAtTheDeletionInstantSeparate and
...AfterAVersionCopyAtThatInstant. Nova 0/8 (each fails 2-5 fair cells). Projection: Orion 1/3, Nova 0/8.
400-case wide fuzz (variants, unequal capacities, old-format conversion, reopens, repeated archived prunes):
reference and all three Orion clean, so no in-contract lever existed without the same-instant cells.

## Batch 6 (2026-10-10, round 13 meta): Nova 0/8
7 of 8 Nova failed ArchiveKeepsAReinsertionSeparateAfterAVersionCopyAtThatInstant (4 as their only failure).
Nova #7 was graded FAIL_UNDOCUMENTED_REQUIREMENT on it (reopen=1 half only); contested.

## Batch 7 (2026-10-10): Nova 0/8, Orion 4/4 PASS, Vega 1/1 PASS
Nova #2..#8 are batch-6 runs #1..#6 and #8 regraded; Nova #1 is new (segfault on old-format header slack, 5 fails).
| Run | Verdict | Failed |
|---|---|---|
| Nova #1 | WRONG_LOGIC | 5 old-format (header padding read as a version count) |
| Nova #2,#5,#7 | MISSED/WRONG | VersionCopyAtThatInstant |
| Nova #3 | WRONG_LOGIC | 6 (old index, same-id, version copy) |
| Nova #4 | WRONG_LOGIC | 8 (identical reuse, version copy, old index) |
| Nova #6 | MISSED | version copy, old index reuse |
| Nova #8 | WRONG_LOGIC | 4 (same-id, old index) |
| Orion #1-#4, Vega | PASS_LEGITIMATE | none |
All five strong solutions also fixed the base deleteData defect (pick the live entry with the matching box).

## Round 14 probes and replay (51 tests)
- Wide probe, 1200 cases x 5 strong solutions (variants, capacities 10-40, packed same-id, reinserts, reopen,
  old format, retention): 0 in-contract divergence (one split was out of contract: identical live records).
- Same-instant bursts (1200 cases): Vega wrong in ~7% (archive in large reinsert bursts); Orion all clean once
  old-format conversion is off (with it on, a harness artifact: the converted index keeps solution-specific pages).
- Statistics probe (300 cases): dead index/leaf node counts after a prune. Oracle = stored pages not reachable from a
  live root through live entries. Ref, Orion #3, Vega exact; Orion #1/#2/#4 wrong in ~40% of cases after a prune,
  exact on never-pruned trees. Cause: they recount from each node's own end time, which the tree does not keep
  current (the parent entry is the truth).
- Replay on the 51-test suite: ref 0, Orion #3 0, Vega 0, Orion #1/#2/#4 15 each, Nova 15-20 each.
  Projection Orion 1/4, Vega 1/1, Nova 0/8. Description delta, so treat as an upper bound on kills.

## Round 15 (retention dropped, 39 tests) replay on batch 7
ref 0 | Orion #1/#2/#4: 9 each (statistics + prune-oracle tests) | Orion #3 0 | Vega 0 | Nova #1-#8: 11-14 each.

## Batch 8 (2026-10-10, round 16 meta, 32 tests): Nova 0/8, Orion 1/4 (FP-voided)
| Run | Verdict | Failed |
|---|---|---|
| Orion #4 | PASS, panel FALSE POSITIVE | none; skips child entries ending at the previous horizon, so pages ended by version splits right after a prune at the current time leak |
| Orion #1, #2, #3 | WRONG_LOGIC | 4: Seeded, EveryTreeVariant, ManyArchived, RecordsSharingInOneLeaf (kept parents keep entries to purged pages; after page reuse deletes fail and queries return extra ids) |
| Nova #4 | WRONG_LOGIC | same 4 as Orion #1-#3 |
| Nova #1-#3, #5-#8 | WRONG/MISSED | 8-15 each |
Nova max-step sequence 268k-288k per run (avg ~279k > 256k).

## Round 17 replay (35 tests: + purge-after-current-time prune, + same-id erase marker, + 3D)
ref (fixed) 0 | old ref 1 (same-id marker, S1) | b8 Orion #4 1 (new purge test only) | b8 Orion #1-#3 5 | b8 Nova 5-17 |
b7 Orion #3 0 | b7 Vega 0 | b7 Orion #1/#2/#4 10. Projection on re-eval: Nova 0/8, Orion 0/4.

## Re-eval of batch 8 on round 17 (35 tests): Nova 0/8, Orion 0/4. Batch 9 (2 fresh Orion): 2/2 PASS_LEGITIMATE
Probe (round18/probe.cpp: wide fuzz + containsWhatQuery/pointLocationQuery hashes after each prune, queries starting
at or after the horizon): 600 normal cases, both batch-9 passes identical to the reference. 400 same-instant burst
cases: 2 page-set divergences each, both in large bursts that leave base orphan pages (oracle unreliable there;
the reference itself mismatches the oracle in one). No fair lever found. Waiting on the FP check of batch 9.
