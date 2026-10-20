ACCEPTED 2026-10-20 (Nova 0/8 + Vega 1/4, pass 326k). Archived; lessons in failure-patterns.md F-105..F-108, L138-L140.

# micasa-pro-blob-reclaim — feedback

Repo: micasa-dev/micasa (Go). Base: ca69a88f998dec25c1e285121e428a4f7621dc68 (main, 2026-10-13).
Lane (hunt #65): Pro relay blob reclaim. Devices report in-use document checksums after each sync;
`micasa pro storage --reclaim` deletes unused blobs only once every active device has reported since
its own last push, otherwise names the devices it is waiting on.

## Status
SLICE-READY (2026-10-16). Core slice built and validated; no differentiating scope yet (Step 4b stop).
- solution.patch: 11 files (relay store/memstore/pgstore/handler/blob, sync types/blob/engine/apply,
  data store_document, cmd pro.go), hook human-effective 330 (raw 482); PgStore 101 of it ungraded.
- test.patch: test.sh + cmd/micasa/pro_reclaim_f908dd_test.go, 9 tests, all fail on base, all pass
  with the solution; base suite 1377 pass / 43 skip (Pg suites) as root, uid 1000 and unmapped 4242.
- meta.md draft: 231 body words, ASCII, one-line paragraphs (not yet through the AI gate).
- Owed at FINISH: Postgres decision (PgStore graded or not), F-10 cells listed in DESIGN.md section 9,
  flakiness 3x, mutation/FP pass, meta humanizer pass if flagged, re-run SIX-CHECK at patch time.

## Decisions taken without the user (conservative defaults)
- Base = upstream HEAD ca69a88 (go 1.27.2; Dockerfile pins GOTOOLCHAIN=go1.27.2, base image ships 1.26.3).
- Clone is blobless (`--filter=blob:none`) into worktrees/micasa-blob; the hunt clone was partial and could not be cloned locally.
- PgStore: implemented in the reference (the Store interface forces it) but NOT graded in the slice; no
  Postgres in the image yet. Recorded as a FINISH decision (lever: start Postgres in test.sh with
  nss_wrapper for unmapped uids, run the new cells against PgStore too). FP exposure: an agent that stubs
  PgStore passes the MemStore suite; decide before the first batch.
- Tests drive reclaim only through the real CLI binary (subprocess, `buildTestBin`) with a per-device
  XDG_DATA_HOME secrets dir, so no new Go symbol is pinned (L72). Devices sync in-process through
  `sync.Engine` over a MemStore relay on httptest.
- CLI output fixed in meta.md: `removed N files, freed SIZE`, the usual `storage:` line, or
  `waiting for: NAME, NAME`.

## Scope-lock gates (2026-10-16)
- SIX-CHECK: canonical `micasa-dev/micasa` (no redirect). PR/issue search (all states) for blob, reclaim,
  garbage collect, orphan, prune, quota, storage usage, delete blob, unreferenced, in use, replace file,
  checksum, compaction, cleanup: only base blob machinery (#103, #791, #802, #836, #852, #867). PR bodies
  of #791/#802/#852/#867 grep clean. No philosophy hit; plans/ "post-v1 compaction" is ops/exchanges/
  invites TTL, not blobs. base == HEAD: no post-base commits. Capability check: relay Store has no delete.
- Exclusivity PR-DIFF: no PR in any state touches relay blob deletion; nothing to diff.
- Gate 5 cold: relay/blob/engine last feature commits 2026-03/05 (+ a 2026-10-13 test-speed commit).
- Gate 6/1 reproduce on base: see eval-results.md (runtime probe).
- Gate 7b: clean. Gate 8: invented behaviour, no maintainer decline.
- Overlap with our accepted micasa-field-level-sync-merge: shares engine.go (one call + Reclaim),
  apply.go (one helper in applyUpdate), pro.go (different subcommand). Capability disjoint. Precheck owed.

## Slice log (2026-10-16)
- test.sh copied from the accepted micasa lane (overlay-blanks the new file in base mode, per-test
  JUnit fallback, `::` normalisation). Added: if `$HOME` is not writable, point it at a temp dir. In the
  image uid 1000 / 4242 get `HOME=/`, and 8 base tests (document cache dir, default DB path) failed with
  `mkdir /.cache: permission denied`; root passed. With the guard all three uids pass base.
- Clean-room note: the image was built from base + the first test.patch; the HOME guard was validated by
  bind-mounting the updated test.sh over /app/test.sh (only that file changed; a rebuild re-downloads the
  toolchain + modules, ~40 min on this link). FINISH should rebuild once from the final test.patch.
- Mutants of the reference (eval-results.md): scoped report, downloaded-only report, report before push,
  strict freshness and base apply.go each fail at least one test.
- Overlap with micasa-field-level-sync-merge to show the precheck reviewer if asked: shared files are
  engine.go (report call + Reclaim), apply.go (dropReplacedFileData in applyUpdate) and pro.go
  (`storage --reclaim`); none of the accepted lane's merge machinery is touched.

## Task Prompt Quality round 1 (2026-10-16)
- FAIL `ai_generated` (major), quote = old opener "We want micasa Pro to be able to free relay storage...". Content not questioned.
- User ran the body through the humanizer. Adopted its text and repaired only the words that changed meaning (it also used U+2024/U+201A for . and , and dropped every backtick):
  - "can't delete documents" -> "can't delete files"; "Deleted documents still consume" -> "Old file versions still consume" (deleted docs are KEPT, TestProReclaimKeepsTheFileOfADeletedDocument).
  - "are informed about" -> "are included" (x2).
  - "resynchronizes" -> "synchronizes first"; "files stored for household members that did not appear on any reports from unsynchronized devices" -> "files stored for the household that do not appear in the latest report of any device".
  - "N files deleted, SIZE space reclaimed" -> literal `removed N files, freed SIZE` (regex-pinned); "same size units" -> "same size format".
  - "synchronized but unsynchronized devices ... since the relay's last report to any of these devices" -> "devices ... since the last change they pushed to it" (own-push freshness, TestProReclaimWaitsForADeviceThatPushedAfterItsReport / ...JustSyncedANewDocument).
  - "considered unsynchronized" -> "counted too"; restored backticks on the command and `waiting for: `.
  - "replaced on another device ... available on that device" -> "replaced on one device ... available on the other devices after they synchronize".
- 262 body words, ASCII. If flagged again with the opener quoted, swap only the opener for a scenario-first sentence (field-level-sync-merge precedent).

## Solution Quality round 1 (2026-10-16): FAIL 1/3 comprehensiveness, 3/3 code quality
- HIGH: a replacement upload rejected by quota was never retried (pushAll marks the op synced first). Fix: `Engine.Reclaim` now uploads every locally stored document blob the relay lacks after a sweep (new `Store.StoredBlobDocuments`, `uploadDocumentBlob` split out of `uploadPendingBlobs`), refreshes `UsedBytes` from status when it uploaded, and returns the `SyncResult` so the CLI prints the usual `warning: N blob operation(s) failed`. Checked with a throwaway 600 KiB x2 test at a 1 MiB quota: v1 freed, v2 re-uploaded, the phone gets v2. Not added to test.patch (quota retry is not a meta rule).
- MEDIUM: PgStore join race. `CompleteKeyExchange` and `RegisterDevice` now take the household row lock (`FOR UPDATE`) that `ReclaimBlobs` holds. Relay + sync Pg suites pass against postgres:17-alpine (RLS tests skip as superuser, same as CI).
- Solution: 11 files, hook human-effective 399.

## Test Quality coverage suggestions (2026-10-16, advisory), taken before the first batch
- Relay quota set in the test household (`WithBlobQuota(1<<20)`), so the storage line carries `/ 1.0 MiB (x%)`. The reclaim output is now compared to what `micasa pro storage` prints, not just `formatBytes(used)`.
- New: `TestProReclaimSyncsBeforeRemoving` (the phone has not pulled the replacement when it runs reclaim), `TestProReclaimCountsEveryRemovedFile` (2 files, freed sum, storage line), `TestProReclaimListsEveryWaitingDevice` (two names, split on commas, any order: meta gives no order).
- Skipped: "active document not downloaded". Reclaim syncs first, and that sync downloads any blob the relay holds, so an active undownloaded document whose blob could be removed can't be built through the CLI.
- Mutants: dropping the sync in Reclaim fails the sync-first test; dropping the quota from the storage line fails 2 tests.
- Clean room (host, fresh clone at BASE): test.patch alone 12/12 fail; with the solution new 12/12 three times, base 1377 pass / 43 skip. Image not rebuilt (none left locally).

## Solution Quality round 2 (2026-10-16): FAIL code quality 1/3 (comprehensiveness now 3/3)
- HIGH: `interfacebloat` max 25 (.golangci.yml says Store had 24); the two new methods made 26. Fix: the six blob methods (PutBlob, GetBlob, HasBlob, BlobUsage, ReportBlobsInUse, ReclaimBlobs) moved into an unexported `blobStore` interface embedded in `Store` (20 methods + 1 embed). Lint config untouched.
- Ran the repo's real CI gates locally (tools in worktrees/micasa-blob-tools/bin, built with go1.27.2): golangci-lint v2.14.0 `run ./...` 0 issues (also caught and fixed a wrapcheck on `ctx.Err()` in reportBlobsInUse); golines --max-len=100 + gofumpt clean (wrapped one writeError in handler.go); deadcode -test clean; nilaway (CI-pinned version) clean on relay/sync/data, cmd/micasa OOM-killed on this 7 GB box.
- test.patch unchanged. Solution 11 files, human-effective 406. Clean room again: new 12/12 x3, base 1377/0.

## Batch 1 diagnosis (2026-10-16): Orion 4/4, too easy; stated surface exhausted
- Auto Review: Revision Requested. Description 3/3; Tests 1/3 (T3/T4 High x3: MemStore-only, no orphan-blob deletion case, no active-undownloaded case); Solution 1/3 (S2 High: --reclaim flag added without regenerating docs/content/docs/reference/cli.md, which go-generate-check diffs; S1 Medium: 8 MiB single-request report).
- Solution Quality: PASS (2/3 comprehensiveness on the 8 MiB boundary, 3/3 code).
- 10 probes x 4 Orion solutions x {MemStore, PgStore}: zero divergence on stated rules (eval-results.md). The Auto Review coverage asks are fair but kill nobody. Only the unstated quota retry and the 1 MB report cap split, 4/4 each.
- Consequence: no tests-only lever exists; re-eval would stay 4/4. The next round needs a description delta and so a full batch (Nova smoke first per the gate).

## Round 3 (2026-10-16): harden after Orion 4/4 + Auto Review fixes (user chose: quota + big reports, Postgres graded)
Description delta, so this needs a fresh batch (Nova smoke first).
- meta.md: two sentences added (no other wording touched). P2: a device can have more documents than fit in one request, the relay keeps its 1 MB body limit, the report must arrive in full. P3: when nobody is waited for, reclaim also uploads every file of the device's documents the relay is missing (e.g. refused earlier for lack of space), deleted documents included, and the printed storage information includes those uploads. Body 355 words, ASCII. Needs the Task Prompt Quality gate again.
- solution.patch: report sent in parts of 8192 hashes under one report id (client), handler back on the base 1 MB maxRequestBody (8 MiB constant gone), Store.ReportBlobsInUse takes a part; MemStore/PgStore accumulate parts and replace the device's report only on the final part (PgStore: new blob_report_parts table, RLS-registered, device row locked per part). Missing-file upload now covers soft-deleted documents (StoredBlobDocuments unscoped, new Store.DocumentData). Regenerated docs/content/docs/reference/cli.md (go-generate-check, S2 High). 11 files, hook human-effective 493.
- test.patch: every reclaim test runs as memory + postgres subtests (eachRelayF908dd; postgres skips without RELAY_POSTGRES_DSN). New: orphan file removed (T3/T4 High), active document whose blob GET fails is kept (T3/T4 High, HTTP wrapper), device with 20,000 deleted never-downloaded documents (report > 1 MB), quota recovery for a replacement / a new document / a deleted document (+ storage line equals `micasa pro storage`). 18 tests, 36 subtests, ~35 s locally.
- test.sh: new mode starts a socket-only Postgres 15 in a temp dir (root via runuser postgres, unmapped uid via nss_wrapper), exports RELAY_POSTGRES_DSN, stops it after. Base mode unchanged (no Pg: the repo's Pg suites truncate shared tables and packages run in parallel).
- Dockerfile: apt-get install postgresql-15 libnss-wrapper (solvers also get a usable Postgres; all 4 batch-1 Orion runs tried and failed to provision one).
- Replay on the 4 batch-1 Orion solutions (upper bound, they never read the new sentences): each fails exactly the 4 new-axis tests (many documents + 3 quota cells) and passes the other 14 on both backends.
- Fixture note: the 20k documents are inserted soft-deleted with no data and their oplog entries marked synced. A first version with live data made reclaim upload 20k blobs (minutes on Postgres, quota noise).
- Dockerfile also regenerates docs/content/docs/reference/cli.md at build time (`go generate ./cmd/micasa/`, chmod a+rw): the repo's .dockerignore drops docs/ and *.md, so without it solution.patch could not apply in the image (first clean room: "docs/content/docs/reference/cli.md: No such file or directory"). Base generation is byte-identical to the committed file (checked on a clean BASE checkout); it is generated before the local git repo is created so it is tracked.
- Clean room in the rebuilt image (micasa-reclaim:r3), fresh container per uid, --network none, as 0:0, 1000:1000 and unmapped 4242:4242: test.patch only -> 54/54 new cases fail; + solution.patch -> 54/54 pass x3 (0 skipped, so Postgres started under every uid); base 1377 pass / 43 skip / 0 fail.
- golangci-lint v2.14 0 issues (thelper fixed by passing only hh to the per-backend bodies), golines clean, deadcode clean.
- NEXT (human): run Task Prompt Quality on the new meta (two added sentences), then the platform prechecks; batch per the gate: 1 Nova smoke first, then Orion x4, then Nova to 8.

## Task Prompt Quality round 2 (2026-10-16): FAIL ai_generated on P1 and P2-end..P4, user humanized, drift repaired

Flagged: P1 whole, and the window from the new P2 sentence (1 MB) through P4. Category ai_generated only, no content complaint. Flagged text backed up at worktrees/micasa-blob-tools/meta-r3-flagged.md.

Humanizer output kept everywhere except these drifts (word-level fixes, humanizer wording around them kept). Its U+2024 dots and U+201A commas replaced with ASCII; backticks restored on the command and literal outputs.
- P1 "documents not currently stored on any micasa product" -> "document files that no device in their home uses anymore".
- P2 "which files on the device are linked to which documents" -> "which files are used by the device's documents" (a per-document mapping and "on the device" both contradict the undownloaded-file rule).
- P2 "the relay has a 1 MB limit" -> "keeps its 1 MB limit".
- P3 "connects to the relay" -> "syncs"; "remove documents" -> "remove files"; "not mentioned in recent reports from other household devices" -> "in the latest report of any household device" (own device counts; latest report only).
- P3 "delete N files, free SIZE" -> `removed N files, freed SIZE`; "other information" -> "the usual `micasa pro storage` information" (tests assert the reclaim output contains the storage output).
- P3 "never sent a recent report" -> "have not sent a report since the last change they pushed to it"; "Unregistered devices are not excluded" -> "Devices that have never sent a report are not excluded"; "unregistered devices are present" -> "such devices are present".
- P3 "uploads documents for the device" -> "uploads to the relay any file of the device's documents that the relay is missing"; "documents previously rejected" -> "files previously rejected"; "include documents that have been deleted" -> "belong to documents that have been deleted".
- P4 "Uploading a file to a shared document on multiple devices ... after synchronizing with the device where the file was uploaded" -> "Replacing the file of a document on one device: ... after they synchronize."
Body now 374 words, ASCII. Rule checklist re-walked against all 18 tests: every rule still stated. NEXT (human): re-run Task Prompt Quality.

## Test Quality round 2 FAIL (3 of 18 unfair) + Solution Quality PASS with one medium (2026-10-16)

Unfair (negative output assertions the meta does not state):
- WaitsForADeviceThatNeverSynced, ListsEveryWaitingDevice: `NotRegexp(removed N files...)` while waiting. A `removed 0 files, freed 0 B` line is a valid reading. Now: if a removal line is printed it must say 0 (assertNothingRemovedF908dd); retention is the real check.
- DoesNotWaitForADeviceThatJustSyncedANewDocument: `NotContains("waiting")` dropped. Discrimination moved to behaviour: an orphan blob is uploaded first, and the test requires `removed 1` and the orphan gone (a waiting reclaim cannot remove it).
Coverage suggestions taken:
- Waiting tests also seed an orphan blob and assert it survives (no deletion of any kind while waiting).
- ManyDocuments: real relay blobs for every 500th of the 20,000 deleted documents (40 blobs), all must survive. Mutant "only the first part, marked final" now fails it (it passed before on the old assertions only by luck of ordering).
- CountsEveryRemovedFile: one replaced file is 600 KiB, so the freed size formats in KiB.
- RemovesAFileNoDocumentUses uses the shared uploadOrphan helper.
Solution medium: handleReportBlobsInUse now reads the body through http.MaxBytesReader + io.ReadAll (413 on MaxBytesError, same pattern as handleStripeWebhook) and json.Unmarshal, so a body over 1 MB or trailing data is rejected.
Mutant check (memory): truncated report kills ManyDocuments; `<=` freshness kills DoesNotWait and 10 others. golangci-lint 0 issues, golines clean. human-effective 501. Old patches in worktrees/micasa-blob-tools/patch-backup-r3/.

## Harness race found in clean room (2026-10-16): repo's buildTestBin 2-minute go build timeout
- r3 clean room: uid 1000 new1 failed 51/54 with "build: signal: killed" from cmd/micasa/main_test.go buildTestBin (context timeout 2m, CGO_ENABLED=0). The image only warmed the cgo build cache, so the first CLI build after the solution compiled the whole dependency graph cold, 2m14s. On a loaded machine all 3 runs failed the same way. On a slow grader this would wipe a whole run.
- Fix: test.sh runs `CGO_ENABLED=0 go build -o /dev/null ./cmd/micasa` before go test in both modes (outside the timeout; base log now appended, not overwritten); Dockerfile warms the same build (`CGO_ENABLED=0 go build -o /dev/null ./cmd/micasa`). Image micasa-reclaim:r4 built OK (backup of the old Dockerfile in patch-backup-r3/).
- The r4 clean room was stopped by Claude Code for low system memory (other sessions' containers running), after uid 0 had started. NOT yet validated: r4 clean room x3 uids.
- Follow-up: the cache warm-up was not enough. With results kept, uid 1000 new2 still failed 51/54 with "build: signal: killed" right after new1 passed fully warm: under load (load avg ~8, memory full) the repo helper's go build + link can exceed its 2-minute cap. Fix: the test file has its own one-time build (reclaimBinF908dd, same go build CGO_ENABLED=0, 20-minute cap, temp dir still removed by the repo's TestMain via testBinPath). Measured: warm helper build 2s, cold pre-build 33s.
- r4 clean room (image micasa-reclaim:r4, --network none, uids 0 / 1000 / 4242): test.patch only 54/54 fail; + solution 54/54 pass x3 for every uid, 0 skipped; base 1377 pass / 43 skip / 0 fail. golangci-lint 0 issues, golines clean.
- NEXT (human): Task Prompt Quality on the repaired meta, Test Quality + Solution Quality on the new patches, prechecks, then 1 Nova smoke, Orion x4, Nova to 8.

## Verify Solution FAIL + Test Quality suggestions + Solution Quality PASS 2 mediums (2026-10-18)
- Verify Solution: "Failed to apply solution.patch: docs/content/docs/reference/cli.md: No such file or directory". That is the round-3 symptom from before the Dockerfile regenerated cli.md (the repo's .dockerignore drops docs/ and *.md). The current Dockerfile's image (micasa-reclaim:r4) has both cli.md and .golangci.yml, and the patch applies there. Most likely cause: the platform still has an older Dockerfile. Ask the user to upload the current one. Fallback if it still fails: drop the cli.md hunk.
- Solution medium 1 (Pg revoke race): RevokeDevice now locks the household row first, the same lock ReclaimBlobs, RegisterDevice and CompleteKeyExchange take.
- Solution medium 2 (interfacebloat): the embedded blobStore did not shrink the method set. Store is flat again (26 methods) and .golangci.yml interfacebloat max goes 25 -> 26 with the comment updated, as the reviewer allowed. golangci-lint ./... 0 issues.
- Test suggestions taken: ManyDocuments records the largest request body the relay saw and requires <= 1 MB (mutant "part size 1<<20 + relay limit 8 MB" fails it); UploadsADeletedDocumentRefusedForSpace now checks the storage output too. Not taken: requiring `removed 0` while waiting (the previous Test Quality round ruled either reading valid).
- human-effective 503, 12 files incl. .golangci.yml. Old patches in worktrees/micasa-blob-tools/patch-backup-r4/.
- NEW RISK (CLAUDE.md 2026-10-18): passing Orion/Vega runs must average > 256k sequence length. This problem's batch-1 Orion runs (pass and fail) read 89k-133k, none compacted.

r5 clean room (latest patches, image micasa-reclaim:r4, --network none): uids 0:0, 1000:1000 and 4242:4242 each gave new mode without the solution 54/54 fail, with the solution 54/54 pass three times in a row, and base 1377 pass / 43 skip / 0 fail. The image predates the Dockerfile's CGO warm-up line; that line only adds a `go build -o /dev/null`.

## Batch 2 (2026-10-18): Vega x4 = 3/4, Auto Review Revision Requested
- Too easy: the gate needs exactly 1 of 4 Vega. Passing Vega runs average 359k sequence length, so the new 2026-10-18 Orion/Vega long-horizon check would pass; Vega is the agent to qualify on (Orion ran 89k-133k).
- The FP panel ruled all three passes genuine (judge-c dissents on a 1M-hash report cap and a zero-byte file were overruled).
- The failer (Vega_Orion_3) exempted devices with no push from waiting, against the stated "never sent a report are not excluded" rule. Fair.
- Auto Review T3/T4 High: the no-wait test reclaimed from the phone, whose pre-reclaim sync refreshed its report, so a household-global freshness rule passed. Fixed by reclaiming from the laptop first (removed 1), then from the phone (removed 0). A household-global mutant of the reference fails exactly this test on memory and postgres.
- Convergence: all three passers implement per-device lastPushSeq stamped at report start, skip uploads while waiting, and clear stale bytes in applyUpdate with code near-identical to the reference. No stated axis separates them, so re-eval cannot reach 1/4. Hardening needs a description change and a fresh batch.
- r6 validation: clean room as uid 0 gave 54/54 fail without the solution, 54/54 pass x3 with it, base 1377/43/0. Replaying Vega passers v1, v2, v4 on the new test.patch: 54/54 pass each, so a re-eval stays at 3/4.

## Hardening round (2026-10-18, after batch 2): incremental reports
- New meta sentence (P2, after the 1 MB sentence): once a device has reported, a later sync where only one of its documents changed must send and receive less than 64 KB in total, even on a device with 20,000 documents. Body 374 -> 426 words. Not yet through Task Prompt Quality; humanize only this sentence if flagged.
- Reference: reports now carry a base version plus added/removed hashes (Base 0 = full list). Relay MemStore/PgStore apply the change against the stored version, bump it, stamp freshness on every committed report (empty changes too), and return 409 on a stale base; the client then resends the full list. The client keeps the confirmed version and hashes on the local SyncDevice row (report_version, reported_files; go generate updated meta_generated.go). Human-effective 503 -> 635. golangci-lint 0 issues.
- New test TestProReclaimSyncAfterOneChangeStaysSmall: phone with 20,000 deleted docs + one live doc reports, replaces the live doc's file, `micasa pro sync` in a fresh process must move < 64 KB (request + response bytes counted at the test relay), then laptop reclaim removes exactly the old file.
- Replays: Vega v1/v2/v4 and the previous reference fail only the new test (both backends). Mutants of the new reference: skip sending an unchanged report -> WaitsForADeviceThatPushedAfterItsReport, KeepsTheFileOfADeletedDocument, UploadsADeletedDocumentRefusedForSpace fail; keep no state across processes -> new test fails; never send removals -> 10 tests fail. So the new rule interlocks with the freshness, deleted-file and replacement rules already in the suite.
- r7 clean room (final patches): every uid gave 57/57 fail without the solution and 57/57 pass x3 with it. Base: uid 0 and 4242 gave 1377/43/0; uid 1000 had ONE base failure (1377, 1 failed). That XML was not kept, so the test is unnamed. 22 more base runs as uid 1000 (two and three containers in parallel): 0 failures. Read as a rare flake (1 in 25 this round, 0 in every earlier round). cr-docker.sh now prints failing test names so a repeat gets named.

## Batch 3 (2026-10-19): Vega 2/2 on the hardened meta
- Both passed (57/57), FP panel genuine on both. Seq 310k and 326k, so the passing Vega average (318k) clears 256k.
- The 64 KB incremental rule did not separate them. Run rd7exngb rebuilt the reference design: versioned add/remove delta, local copy persisted, 409 then full report. Run rd7ewebf found its own design: 256 first-byte buckets with XOR digests, resending only the buckets that differ.
- Vega over batches 2+3: 5/6 (the only miss was the never-reported-device rule in batch 2). Orion on batch 1 ran 99k-113k, so it cannot be the qualifier under the 256k passer check. The problem sits below Vega's level, and the tests-only lane cannot change that: the two new passers match the reference on every stated axis.
- Auto Review T3/T4 fixed in test.patch: traffic is now counted on the connection (listener wrapper), so HEAD requests and headers count. The changed document is now created first. The reference uses 3,360 B on the wire. The 500-HEAD mutant uses 164,360 B and fails. Both batch 3 passers still pass.
- I broke the replay clones once by running `git checkout -- cmd/micasa` in them (it reverted the agents' pro.go). Caught it, stopped the container, rebuilt the clones from the saved patches. The memory-relay replay had already run on the intact clones.

## Hardening round after batch 3 (2026-10-19), tests only
- Diagnosis: Vega 5/6, every stated cell converged. apply.go's replaced-file fix is the same function in all 6 runs and the reference. The two batch 3 passers differ only in report design (digest buckets vs versioned delta).
- Probes run on all 6 saved Vega solutions (memory relay):
  - Report cut off mid-way (the phone pulled 20,000 documents the laptop pushed, so its next report needs several requests; the relay refuses the phone once it has sent 256 KB): kills **b3-1 only** ("waiting for: phone"; its relay marks a report incomplete as soon as a new one starts). Control without the cut-off: b3-1 passes. Reference and the other 5 pass.
  - Device with no documents counts as reported: 0 kills.
  - 64 KB sync after a reclaim / after another device is revoked: 0 kills on the batch 3 passers (batch 2 runs fail, they predate the rule).
- Lever kept: TestProReclaimDoesNotWaitForADeviceWhoseReportWasCutOff. Traces to "not mentioned in the latest report of any household device" and the waiting rule (the phone pushed nothing since its last full report). Deterministic, no concurrency: the cut-off is a refused request, not a pause.
- Expected effect: re-eval of batch 3 reads 1/2 (b3-2 passes, 326k). It adds ~1/6 kill rate on the observed Vega population, so a fresh 4-run pool still likely reads 2/4+. Marginal on its own.
- Base push sends every op in one request, so the laptop pushes in batches of 400 (1,000 already exceeded 1 MB).

## Second probe round after batch 3 (2026-10-19), looking for one more split
- First report cut off (the phone has never completed a report; its first multipart report is refused after 256 KB, or after the first part): reference, b3-1, b3-2, v1, v2, v4 all list the phone as waiting and recover on the next sync. Only v3 fails (exempts never-reported devices; already killed by WaitsForADeviceThatNeverSynced). 0 new kills.
- Code reads, all converged: checksum listing (unscoped, DISTINCT, non-empty) is identical in reference, b3-1, b3-2; every Pg store keeps reports in tables (no in-memory state, so a relay restart probe would split nothing); every Pg reclaim does the set work in SQL.
- The 6 saved Vega solutions are exhausted as a design sample: b3-1 is already killed, v1/v2/v4 fail the 64 KB rule, v3 fails the never-reported rule. A new test can only be measured against designs we have not seen.
- Next: 2 local Vega-like runs (Opus 5.5 xhigh subagents, task text only, clean BASE clones in /home/ahmed/vega-local/micasa-{1,2}, Go through the micasa-reclaim:r4 image with --network none) for fresh design samples. Grade them with the current test.patch, then probe them.

## Local Vega-like runs on the current meta (2026-10-19), graded with the current test.patch (60 cases, memory + postgres)
| Run | Design | Grade |
|---|---|---|
| L1 (/home/ahmed/vega-local/micasa-1) | add/remove delta with base token, local acknowledged copy, 409 -> full report with reset; relay applies each part in place and marks the report incomplete until final | FAIL only the cut-off test (memory + postgres): same failure as b3-1 |
| L2 (/home/ahmed/vega-local/micasa-2) | relay-chosen hash buckets (about 32 per bucket) with 8-byte digests, session opened before the local read, staged parts committed on final with a count check; no local state | PASS 60/60 |
- L2 reported seeing L1's test file in one early run (it probably ran the go wrapper from the other clone once), so the two runs may not be fully independent. The designs differ completely.
- Cut-off test so far: kills b3-1 and L1, passes b3-2 and L2. Current suite on the 4 post-64KB designs reads 2/4.
- Probes on b3-1, b3-2, L1, L2 and the reference: first report cut off (late and early), cut off after a push (must be waiting), empty device, 64 KB after a reclaim, 64 KB after a revoke. All pass everywhere. L2's code read (bucket bits, digest compare, staged commit, coversSeq at begin applied on commit) found no stated-rule gap.
- Side note: after the phone's reclaim with 20,000 deleted documents, b3-1, b3-2, L1 and L2 take about 180 s against 5 s for the reference (per-hash work on the missing-file list). No stated rule covers reclaim speed, so it's not a lever.

## Batch 4 (2026-10-19) and the r10 test round
Batch 4 = re-eval of batch 3 + 2 fresh Vega + 8 Nova on the r9 suite. Vega reached the gate: **1/4**, the pass is b3-2 at 326,155. Nova failed it: **3/8** (needs 0/8).

The three Nova passes share one gap. The relay keeps no version for its copy of a report:
- Nova #1 and #6 send a single-request add/remove delta and record it locally only after a 200.
- Nova #2 applies delta parts as they arrive.

So when the relay applies a report and the reply is lost, the device's local copy no longer matches the relay. The next delta is computed against the stale copy, and a hash added in the lost report stays pinned on the relay forever. The FP panel voided Nova #2 for the same reason, there through an interrupted multi-part delta. The reference and b3-2 get a 409 on the stale base and resend in full. The digest designs (b3-1, L2) compare against the relay's real state.

r10 changes (tests only, re-eval eligible):
- New TestProReclaimRemovesAFileWhoseReportReplyWasLost. The laptop attaches "warranty draft" and syncs. The phone syncs while the test relay processes every request with a body from the phone's token but drops the reply (handler runs into a recorder, then panic(http.ErrAbortHandler)); that sync only pulls and downloads, so its one body request is the report. The laptop replaces the file, both sync, and the laptop reclaims. Expected: removed 1, the draft is gone, the signed file stays.
- TestProReclaimWorksForADeviceWithManyDocuments, from Auto Review T3/T4: after the phone's report, the laptop uploads "receipt 00001" (one of the phone's 20,000 references, absent at report time). The laptop reclaims (removed 0, receipt kept), then the phone reclaims as before, and the receipt is still kept.

Host replay, memory relay:
- Lost-reply test: fails Nova #1, #2 and #6 (removed 0, draft kept). Passes the reference, b3-2, b3-1, and b2 v1, v2 and v4.
- Absent-blob check: passes all nine.
- b3-2 alone: the 20,000-document test took 169 s, against 161 s on r9.

Docker replay with Postgres (image r4):
- Nova #1, full `test.sh new`: 60/63; the only failures are the lost-reply test (memory and postgres).
- Targeted runs of the two changed tests:
  - Nova #2 and #6 fail the lost-reply test on both backends.
  - The reference and b3-2 pass both tests on both backends.
- Expected re-eval of batch 4: Nova 0/8, Vega 1/4, with the pass kept at 326,155.
- The host is about 3x slower than the platform on Postgres while another session's container loads the disk, so timings from these runs are not comparable to the platform's.

r10 clean room (new test.patch, unchanged solution.patch), uids 0, 1000, 4242: 63/63 fail without the solution, 63/63 pass x3 with it, base 1377 pass / 43 skip / 0 fail on every uid. test.patch installed. Next: re-eval batch 4 (expected Nova 0/8, Vega 1/4 at 326,155).
