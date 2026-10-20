# micasa-pro-blob-reclaim — eval results

No platform runs yet (slice stage, precheck owed).

## Local validation (slice, 2026-10-16)

### Gate 1 runtime probe on BASE (new tests, solution not applied)
All 9 new tests fail on base. 8 fail with `unknown flag: --reclaim`; the content test fails on the base
bug itself: `TestProReclaimReplacedFileReachesTheOtherDevice` expected "manual second edition", actual
"manual first edition" (the peer keeps the old bytes under the new checksum).

### Reference (solution applied), host go1.27.2
- new: 9/9 pass (~76 s wall, includes the one-off CLI binary build)
- base: 1377 testcases, 0 failures, 43 skipped (PgStore suites, no RELAY_POSTGRES_DSN)

### Trap reproduction (one mutant of the reference per run)
| Mutant | Tests that fail |
|---|---|
| M1 report from GORM-scoped rows (deleted docs dropped) | KeepsTheFileOfADeletedDocument, KeepsADeletedFileForADeviceThatNeverDownloadedIt |
| M2 report only downloaded files (`data IS NOT NULL`) | KeepsADeletedFileForADeviceThatNeverDownloadedIt |
| M3 report at the start of Sync (before pull/push) | RemovesAReplacedFileOnceEveryDeviceSynced, KeepsAFileAnotherDocumentStillUses, DoesNotWaitForADeviceThatJustSyncedANewDocument |
| M4 strict freshness (`report > last push`) | 6 of 9 (self-revealing) |
| base apply.go (no content fix) | ReplacedFileReachesTheOtherDevice |

### LOC (hook, solution.patch)
human-effective 330 (raw 482) over 11 files; PgStore 101 of it is not graded in the slice.

### Docker clean room (image factory-micasa-pro-blob-reclaim, --network none)
| tree | uid | base | new |
|---|---|---|---|
| base + test.patch | 1000 | 1377 pass, 43 skip | 9/9 fail |
| base + test.patch | 4242 (no passwd) | 1377 pass, 43 skip | 9/9 fail |
| base + test.patch | 0 | 1377 pass, 43 skip | 9/9 fail |
| + solution.patch | 1000 | 1377 pass, 43 skip | 9/9 pass |
| + solution.patch | 0 | 1377 pass, 43 skip | 9/9 pass |
Cold image build ~45 min here (go1.27.2 toolchain + module download on a slow link); flakiness 3x not run yet (FINISH).

## Batch 1 (2026-10-16): Orion 4/4 PASS, no Nova runs

| Run | Verdict | New tests | Baseline | FP panel | Approach note |
|---|---|---|---|---|---|
| Orion #4 (dir 1) | PASS_LEGITIMATE | 12/12 | 1334/1334 | genuine (judge-c dissent: quota retry, ruled unstated) | relay reclaim.go + sync reclaim.go; report table; raised interfacebloat in .golangci.yml |
| Orion #3 (dir 2) | PASS_LEGITIMATE | 12/12 | 1334/1334 | genuine (judge-c dissent: empty-file replacement, base bug) | reclaim_handler.go + sync storage.go |
| Orion #2 (dir 3) | PASS_LEGITIMATE | 12/12 | 1334/1334 | genuine (judge-c dissent: quota retry, ruled unstated) | reclaim.go + storage.go |
| Orion #1 (dir 4) | PASS_LEGITIMATE | 12/12 | 1334/1334 | genuine, no dissent | storage.go + client.go |

All four edited `.golangci.yml` to lift interfacebloat. All four cap the in-use report at the base 1 MB `maxRequestBody` (reference: 8 MiB).

### Differential probes (2026-10-16), worktrees/micasa-blob-tools/probes + rp/{ref,1..4}
Each probe run on reference + 4 Orion solutions, MemStore relay, then real PgStore (postgres:17, superuser).

| Probe | ref | Orion 1-4 |
|---|---|---|
| 12 shipped tests on PgStore | pass | 4/4 pass |
| orphan blob never in any report is removed (count, freed) | pass | 4/4 pass |
| active document whose blob GET fails is kept (revoke uploader) | pass | 4/4 pass |
| revoked device's old report does not keep a file | pass | 4/4 pass |
| lagging device keeps v1, v2 removed, v3 kept | pass | 4/4 pass |
| two households on one relay, same bytes: isolation + waiting list | pass | 4/4 pass |
| second reclaim removes 0, freed 0 B | pass | 4/4 pass |
| quota-rejected replacement reaches the phone after reclaim (UNSTATED) | pass | 0/4 |
| report > 1 MB (by inspection of handlers) | pass (8 MiB cap) | 0/4 |

Zero divergence on every stated axis, both backends. Only unstated axes split, and they kill all four.

## Round 3 validation (2026-10-16)
Replay of batch-1 Orion solutions on the round-3 suite (MemStore + PgStore): all 4 fail exactly
WorksForADeviceWithManyDocuments + UploadsAReplacement/ANewDocument/ADeletedDocumentRefusedForSpace, pass the
other 14 (36 subtests). Upper bound only: these runs never read the two new meta sentences.
Orion #2 (dir 3) is slow on the 20k test (89 s memory, 126 s Pg with fsync off) inside its own code; test.sh
now starts Pg with fsync/synchronous_commit/full_page_writes off and go test -timeout 30m.

Mutants of the reference (each restored after):
| Mutant | Killed |
|---|---|
| report in one request (part size 1<<30) | ManyDocuments |
| missing-file upload skips deleted docs | ADeletedDocument |
| no missing-file upload | Replacement, ANewDocument, ADeletedDocument |
| storage line not refreshed after uploads | Replacement, ANewDocument |

## Batch 2 (2026-10-18): Vega x4, 3/4 pass (75%, too easy; gate needs exactly 1/4)
| Dir | Run | Verdict | New | Seq length | FP panel | Approach |
|---|---|---|---|---|---|---|
| Vega_Orion_1 | rd7e1df9 | PASS | 54/54 | 265,490 | genuine (judge-c: 1M-hash report cap, ruled fair guard) | report.go begin/part/done, per-device lastPushSeq vs reportSeq |
| Vega_Orion_2 | rd76dj07 | PASS | 54/54 | 323,967 | genuine (judge-c: zero-byte file skipped, ref shares it) | engine.go Reclaim uses relay Missing list, per-device lastPushSeq vs basisSeq |
| Vega_Orion_3 | rd71xqpt | FAIL | 48/54 | 258,312 | - | waitingDevices skips devices with no push entry: WaitsForADeviceThatNeverSynced + ListsEveryWaitingDevice fail (stated rule) |
| Vega_Orion_4 | rd74fb65 | PASS | 54/54 | 487,451 (compacted once) | genuine (judge-c: 1M-hash cap) | begin/chunk/commit, per-device lastPushSeq vs asOfSeq |

Passing Vega average sequence length: 358,969 (> 256k, the 2026-10-18 Orion/Vega check passes). Vega, not Orion, is the agent to qualify on.

Convergence read (rp/v1..v4): all three passers track lastPushSeq on every pushed op (any table) and compare it to the value stamped when the report began, exactly like the reference; all skip uploads while waiting; dropReplacedDocumentData in apply.go is near-verbatim the reference's. No stated axis separates them, so a tests-only re-eval cannot take 3/4 to 1/4.

Auto Review (Revision Requested): T3/T4 High, no test leaves one device's older report untouched while another device pushes. Fixed: DoesNotWaitForADeviceThatJustSyncedANewDocument now reclaims from the laptop (removed 1), then from the phone (removed 0).

## Batch 3 (2026-10-19): Vega x2 on the hardened meta (64 KB incremental rule), 2/2 pass
| Dir | Run | Verdict | New | Seq length | FP panel | Approach |
|---|---|---|---|---|---|---|
| Vega_Orion_1 | rd7ewebf (Vega #2) | PASS | 57/57 | 310,507 | genuine (judge-c: 8,192-hash bucket cap with adversarial same-first-byte hashes, ruled out of scope) | 256 buckets by first hash byte, XOR digest per bucket; unchanged set = one small request, else resend only differing buckets |
| Vega_Orion_2 | rd7exngb (Vega #1) | PASS | 57/57 | 326,155 | genuine, no dissent | versioned add/remove delta on a persisted local copy, 409 falls back to a full report (same design as the reference) |

Passing Vega average 318,331 (> 256k). Vega cumulative across batches 2+3: 5/6. The 64 KB rule did not separate: one run rebuilt the reference design, the other found an independent digest design.

Auto Review (Revision Requested): T3/T4 High, the 64 KB check counted bodies only, so bodyless HEAD requests were free. Fixed: the test server's listener now counts every byte read and written on the connection (start lines, headers, bodies). The changed document is now the first document created, not the last (coverage suggestion).

Replay on the fixed suite (memory relay): reference 3,360 B on the wire; b3-1 (digest) 20,171 B, all 19 tests pass; b3-2 (delta) 3,318 B, all 19 pass. Docker replay with Postgres: both 57/57. Mutant of the reference with 500 HasBlob HEADs before the report: 164,360 B, fails.

r8 clean room (fixed test.patch, unchanged solution.patch), uids 0, 1000, 4242: 57/57 fail without the solution, 57/57 pass x3 with it, base 1377 pass / 43 skip / 0 fail on every uid (the uid-1000 flake from r7 did not recur).

## Hardening round after batch 3 (2026-10-19), tests only, no run yet
New test TestProReclaimDoesNotWaitForADeviceWhoseReportWasCutOff: the laptop pushes 20,000 deleted documents in batches of 400, the phone's next report needs several requests, the relay refuses the phone's requests after 256 KB (503), then the laptop reclaims. The phone pushed nothing since its last complete report, so it is not waiting: the orphan goes, the phone's files stay.

| Saved Vega run | Cut-off test |
|---|---|
| reference | pass |
| b2 v1, v2, v3, v4 | pass |
| b3-1 (bucket digest) | FAIL: relay marks the report incomplete when a new one starts, prints "waiting for: phone" (passes the same scenario without the cut-off) |
| b3-2 (versioned delta) | pass |

Probes that split nothing on batch 3: device with no documents; 64 KB after a reclaim; 64 KB after another device is revoked.

r9 clean room (new test.patch, unchanged solution.patch), uids 0, 1000, 4242: 60/60 fail without the solution, 60/60 pass x3 with it, base 1377 pass / 43 skip / 0 fail on every uid. Docker replay with Postgres: b3-1 fails only the cut-off test (memory and postgres, 57/60), b3-2 60/60. Expected re-eval of batch 3: Vega 1/2, the pass kept at 326,155.

Runtime (Docker, uid 4242, reference): `test.sh new` 382 s wall against the 30 m go test timeout. The cut-off test is 271 s of it (memory 123 s, postgres 147 s); next slowest 9.6 s. It needs about 20,000 documents so that any implementation's report exceeds the 1 MB request limit and goes multipart.

## Batch 4 (2026-10-19): re-eval of batch 3 + Vega x2 fresh + Nova x8, all on the r9 suite
| Dir | Run | Verdict | New | Seq length | Failed / approach |
|---|---|---|---|---|---|
| Vega_Orion_3 | Vega #2 re-eval (b3-1) | FAIL | 57/60 | 310,507 | cut-off test (expected) |
| Vega_Orion_4 | Vega #1 re-eval (b3-2) | PASS | 60/60 | 326,155 | versioned delta + 409 fallback |
| Vega_Orion_1 | Vega #2 fresh | FAIL | 54/60 | 365,994 | WaitsForADeviceThatNeverSynced + ListsEveryWaitingDevice |
| Vega_Orion_2 | Vega #1 fresh | FAIL | 57/60 | 431,176 | WaitsForADeviceThatPushedAfterItsReport (skips an unchanged report after a push) |
| Nova_Orion_8 | Nova #1 | PASS | 60/60 | 767,242 | staged full report (applied at last chunk), single-request add/remove delta, full fallback over 5000 |
| Nova_Orion_7 | Nova #2 | PASS (FP panel: false positive) | 60/60 | 568,856 | delta chunks applied on arrival, removed list in one body |
| Nova_Orion_6 | Nova #3 | FAIL | 58/60 | 535,852 | WaitsForADeviceThatPushedAfterItsReport (Pg: unset incoming seq) |
| Nova_Orion_5 | Nova #4 | FAIL | 58/60 | 528,383 | same, Pg |
| Nova_Orion_4 | Nova #5 | FAIL | 58/60 | 533,403 | same, Pg |
| Nova_Orion_3 | Nova #6 | PASS | 60/60 | 536,064 | same design as Nova #1 |
| Nova_Orion_2 | Nova #7 | FAIL | 57/60 | 540,360 | SyncAfterOneChangeStaysSmall (20,000-hash delta in one body, 413) |
| Nova_Orion_1 | Nova #8 | FAIL | 57/60 | 531,032 | cut-off test |

Gate: Vega **1/4** (pass at 326,155 > 256k), Nova **3/8** (needs 0/8), Nova average 567,649 (> 256k).

Auto Review (Revision Requested): Tests 1/3, T3/T4 High: the 20,000-document test only checks the 40 pre-uploaded hashes, so a relay that keeps only hashes it already stores would pass. Asked for a file absent at report time, uploaded later, kept by a reclaim from another device.

FP panel: Nova #1 genuine (dissent: zero-byte file, reference shares it), Nova #2 FALSE POSITIVE (an interrupted multi-part delta pins hashes on the relay forever; reference passes the probe), Nova #3 (= #6) genuine, Vega genuine.

Common gap in the three Nova passes: no version on the relay's copy of a report. If the relay applies a report but the reply is lost, the device keeps its old local copy, sends the next delta against it, and a hash added in the lost report stays pinned forever. The reference and b3-2 get a 409 on the stale base and resend a full report.

## Batch 5 (2026-10-20): re-eval of batch 4 on the r10 suite — ACCEPTED
Nova **0/8** (all fail TestProReclaimRemovesAFileWhoseReportReplyWasLost; sole failure of #1, #2, #6; plus Pg WaitsForADeviceThatPushedAfterItsReport #3-#5, cut-off #8, SyncAfterOneChangeStaysSmall #7), avg sequence 567,649.
Vega **1/4**: b3-2 PASS 63/63 at 326,155; b3-1 cut-off (310,507); fresh #2 never-synced + lists-waiting (365,994); fresh #1 pushed-after-report, unchanged report skipped (431,176).
Per-test kills: lost reply 8, pushed-after-report 4, cut-off 2, one-change-small 1, never-synced 1, lists-waiting 1; 15/21 tests killed nothing.
FP panel: Vega genuine (judge-c dissent on a 1<<20 hash cap, overruled). Auto Review Approved: Description 3, Tests 2 (two Medium T4: all 20,000 references, two missing blobs at once), Solution 3.
