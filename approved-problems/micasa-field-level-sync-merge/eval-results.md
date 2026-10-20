# micasa-field-level-sync-merge — eval results

Batch 1 (2026-10-13, round-9 artifacts, 36 new tests): Orion 0/4. No Nova runs yet.

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Orion #4 (rd70z03f) | Orion | FAIL 35/36 new, base 1338/1339 | - | 17 | +1304 raw | NewerRestoreCountsThePendingEditItDiscards; base guard OlderDeleteAndRestoreCountAsConflictsAgainstANewerEdit | delete+restore vs newer edit counted 1 not 2 | data/sync_merge.go replay of row history |
| 1 | Orion #3 (rd793kmx) | Orion | FAIL 32/36 | - | 18 | - | NewerEditBringsBackAPermanentlyDeletedIncident, NewerDeleteCountsThePendingEdit, NewerRestoreCounts..., CLI PendingEditANewerDeleteDiscarded | no hard-delete rebuild; local edits displaced by delete/restore not counted | field merge without displaced-local accounting |
| 1 | Orion #2 (rd7f7tem) | Orion | FAIL 26/36 | - | 18 | - | 10 incl. SameFieldKeepsTheLaterEdit..., EachLostFieldCounts..., QuoteAmounts, Appliance, Overlapping KeepTheLater, displaced-edit cells | local losses of concurrent field edits never counted | merge without local-loss attribution |
| 1 | Orion #1 (rd77q0rm) | Orion | FAIL 35/36 | - | 16 | +1385 raw | NewerRestoreCountsThePendingEditItDiscards | replay barrier drops the older rejected delete (1 conflict, not 2); converges | op-sorted replay merge in sync/merge.go with base payloads |

Round-10 replay of the 4 saved patches against the round-10 suite (38 new): #1 (dir Orion_Orion_4) fails only the restore cell; #4 (dir Orion_Orion_1) fails the restore cell + OlderDeleteAndRestoreOfAMergedRowCountAsConflicts; #3 5 fails; #2 11 fails. Re-eval would read 0/4; user chose to keep the restore cell and run a fresh batch.

Batch 2 (2026-10-14, round-10 artifacts, 38 new tests): Orion 0/4 as graded, two TEST_BROKEN on our fixtures. No Nova runs yet.

| Batch | Agent | Evaluator | Verdict | Msgs | Seq len | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|---|---|
| 2 | Orion #1 (rd70rwex, dir Orion_Orion_4) | Orion | TEST_BROKEN 0/38 | 81 | 198K | 15 | 1929 sandbox | all (compile) | its own internal/sync/merge_test.go declared `mergeDevice`, colliding with our helper; harness fallback also overwrote 5 passing CLI tests | full field merge with displaced-local accounting |
| 2 | Orion #4 (rd73cey8, dir Orion_Orion_1) | Orion | TEST_BROKEN 13/38 | 79 | 159K | 16 | 1506 sandbox | 25 | our edit helper rewrote oplog created_at to 2099 after the write; agent's persisted sync_row_states kept time.Now() stamps, so ordering inverted | persisted last-synced snapshots + per-field versions (data/sync_merge.go) |
| 2 | Orion #3 (rd769wpr, dir Orion_Orion_2) | Orion | MISSED_REQUIREMENT 28/38 | - | - | - | - | SameFieldKeepsTheLaterEdit..., TimestampLikeText, EachLostField, Appliance, QuoteAmounts, OverlappingSyncsKeepTheLater, NewerDelete/NewerRestore/EditingDevice counts, CLI PendingEdit | local field losses never counted in sync results; displaced edits rendered as one '*' entry | merge counting only incoming op ids |
| 2 | Orion #2 (rd705kqq, dir Orion_Orion_3) | Orion | MISSED_REQUIREMENT 27/38 | - | - | - | - | same 10 + NewerEditBringsBackAPermanentlyDeletedIncident | local losses not counted; no hard-delete rebuild | rejectLocalField persisted but not returned |

Round-11 replay (fixtures fixed: real clock, hash-suffixed helpers, per-test fallback) of the 4 saved batch-2 patches: Orion_Orion_4 38/0 (3 identical runs); Orion_Orion_1 fails 4 (NewerDeleteCountsThePendingEdit, NewerRestoreCounts..., NewerDeleteCountsTheEditItDiscardsOnTheEditingDevice, CLI PendingEditANewerDeleteDiscarded; the displaced-edit gap its evaluator named as a real defect); Orion_Orion_2 10, Orion_Orion_3 11 (unchanged). Expected re-eval: Orion 1/4.

Accepted batch (agent-runs/3, 2026-10-15): re-eval of batch 2's Orion runs on the round-11 test.patch + 8 fresh Nova. **Nova 0/8, Orion 1/4**, FP panel genuine (one dissenting judge on concurrent backdated service logs, reference shares it, ruled unstated). ACCEPTED by human reviewer.

| Run | Verdict | New failed | Seq len | Files / +LOC | Main causes |
|---|---|---|---|---|---|
| Nova #1..#8 | MISSED_REQUIREMENT x8 | 18-21 / 38 | 525k-663k (avg 547k) | 7-10 / 1312-1674 | F-88 merge only while unpushed (8/8), F-89 snapshot stamps (8/8), F-90 one-sided accounting (8/8), F-91 empty tombstones / hard delete (8/8), F-39 losers re-pushed (5/8) |
| Orion #1 | PASS_LEGITIMATE | 0 | 198k | 15 / 1929 | own oplog replay merge with displaced-local accounting |
| Orion #4 | MISSED_REQUIREMENT | 4 | 159k | 16 / 1506 | F-90 on whole-row winners only |
| Orion #3 | MISSED_REQUIREMENT | 10 | 141k | 17 / 1462 | F-90 (local losses never in sync result) |
| Orion #2 | MISSED_REQUIREMENT | 11 | 118k | 17 / 1408 | F-90 + F-91 hard-delete rebuild |

Per-test kills (12 runs): 4 accounting cells 11, 6 same-field/count cells 10, hard-delete rebuild 9, 5 history/overlap/restore cells 8 (all Nova), 4 delete/third-device cells 6, house profile 2, 2 CLI 1. Killed nothing: 15 of 38.

## Local validation (SLICE, 2026-09-30)
| Run | uid | base (no sol) | new (no sol) | base (sol) | new (sol) |
|---|---|---|---|---|---|
| 1 | 1000 | 1377 tc / 0 fail | 16 / 16 fail | 1377 / 0 | 16 / 0 |
| 1 | 0 | 1377 / 0 | 16 / 16 | 1377 / 0 | 16 / 0 |
| 1 (pre-fix suite) | 4242 | 1377 / 0 | 16 / 14 | 1377 / 0 | 16 / 0 |
| 2 | 1000 | 1377 / 0 | 16 / 16 | 1377 / 0 | 16 / 0 |
| 3 | 1000 | 1377 / 0 | 16 / 16 | 1377 / 0 | 16 / 0 |

LOC hook on solution.patch: human-effective 487, raw 720, 8 files. Cold image build 412 s.
