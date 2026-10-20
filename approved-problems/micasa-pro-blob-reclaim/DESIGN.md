# DESIGN.md — micasa-pro-blob-reclaim

Repo: micasa-dev/micasa (Go, Apache-2.0, 1282 stars). Base `ca69a88f998dec25c1e285121e428a4f7621dc68`
(main, 2026-10-13, go 1.27.2). Second lane on this repo; the first (micasa-field-level-sync-merge,
accepted 2026-10-15) owned the per-field merge kernel in `internal/sync/apply.go` / `engine.go` /
`internal/data/oplog*.go`. This lane's core lives in the relay and the blob phase, not in that kernel.

## Phase 1 — repo understanding

**Architecture (one paragraph).** micasa is a terminal home-management app (Bubble Tea TUI + cobra
CLI) over a local SQLite database (`internal/data`, GORM). Pro sync replicates the database between
household devices through an end-to-end encrypted relay: every local write appends a whole-row
snapshot op to `sync_oplog_entries` (oplog hooks in `internal/data/oplog.go`); `internal/sync`'s
`Engine.Sync` pulls remote envelopes, applies them with whole-row LWW (`apply.go`), pushes local ops,
then runs a blob phase: it uploads the encrypted file of every pushed document op (content-addressed by
the plaintext SHA-256, dedup through HEAD) and downloads files for documents that have a checksum but no
local data. The relay (`internal/relay`) only sees ciphertext: it stores envelopes with a per-household
seq, devices, invites/key exchanges and blobs, behind a `Store` interface with an in-memory
(`MemStore`, tests) and a Postgres (`PgStore`, production, RLS per household) implementation. The CLI
`micasa pro ...` (`cmd/micasa/pro.go`) drives init/join/sync/status/storage/devices/conflicts.

**Five subsystems.** (1) `internal/data` local store, models, oplog hooks; (2) `internal/sync` engine,
client, apply, blob client; (3) `internal/relay` HTTP handler + `Store` (MemStore/PgStore + rlsdb);
(4) `cmd/micasa` CLI (pro, entity CRUD); (5) `internal/app` TUI (forms that create/replace documents).

**High-entanglement zones.** `Engine.Sync` phase order (pull → push → blob upload → blob download);
`applyUpdate` + `stripNonColumnKeys` (every remote document update); the relay `Store` interface
(compile-time checked by both stores, `pgstore.go:31`).

**Tests.** `go test` + testify; relay through `relay.NewMemStore()` behind `httptest`
(`internal/sync/roundtrip_test.go`, `engine_test.go`); PgStore suites skip without
`RELAY_POSTGRES_DSN`. CLI subprocess tests build the binary once (`cmd/micasa/main_test.go`
`buildTestBin`). Template file: `internal/sync/roundtrip_test.go`.

## Phase 2 — existing PR / publicly solved

Canonical slug `micasa-dev/micasa` (no redirect). PR + issue searches (all states): blob, reclaim,
garbage collect, orphan, prune, quota, storage usage, delete blob, unreferenced, in use, replace file,
checksum, compaction, cleanup. Hits are only the base blob machinery (#103 local BLOB storage, #791 pro
sync, #802 review fixes, #836 quota rename, #867 RLS, #852 relay edge tests). None deletes relay blobs.
PR bodies of #791/#802/#867/#852 grep clean for orphan/garbage/reclaim/delete-blob. Repo grep: no blob
deletion anywhere (only `rls_test.go` checks cross-household DELETE isolation). plans/: design review
§6 "post-v1 compaction" covers ops, exchanges and invites (TTL), not blobs; spec-vs-impl Gap 4 is oplog
compaction. Base == HEAD, so no post-base commits. Lane files last touched 2026-03/05 (+ a test-speed
commit 2026-10-13). Verdict: clean.

## Phase 3 — candidate and guards

Hunted lane (single candidate, FALLBACKS none). TOO-EASY guard: (1) not a uniform wrap: three
different mechanisms (relay freshness rule, client report contents and timing, the apply-side content
fix); (2) not single-subsystem: relay store x2 + handler, sync engine/client/apply, data, CLI; (3) the
contract can be fully stated; the hardness is in where base already drops state (GORM soft-delete scope,
data kept under a new checksum, own ops never pulled so `last_seq` lags pushes); (4) not a port;
(5) survives full statement — yes, the walls are repo internals. Not machinery-absorbed: the relay has no
deletion, no per-device report, no freshness notion (sketch measured 328 hook-effective).

Risk notes: outsider-nameable as "blob GC" (MEDIUM, mitigated by the repo-internal freshness rule);
shares engine.go/apply.go/pro.go with our accepted lane (different capability, precheck owed).

## 1. Title
Add relay storage reclaim to micasa Pro sync

## 2. Shape
O-Composite-add (new capability spanning data / sync / relay / CLI). Best agent: Orion. Dominant
verdict expected: MISSED_REQUIREMENT on cross-device cells (a rule broken only as seen from ANOTHER
device), plus INTEGRATION on the base content bug.

## 3. Public API surface (what tests touch)
- CLI `micasa pro storage --reclaim [database-path]` (new flag on the existing command).
- Existing public API only otherwise: `sync.NewEngine/Engine.Sync`, `sync.NewClient` + `Client.Push`,
  `relay.NewMemStore/NewHandler/WithSelfHosted`, `MemStore.HasBlob/BlobUsage/RegisterDevice/RevokeDevice`,
  `data.Store` document CRUD. No new Go symbol is pinned by tests (avoids L72 compile wipes).

## 4. Canonical output
- Reclaim success: one line with the number of files removed, the bytes freed and the new usage
  (usage in the existing `micasa pro storage` format).
- Waiting: names of the devices holding it up; nothing removed. Order-insensitive assertions.
- Empty reclaim (nothing unused): 0 removed, nothing freed.

## 5. Blind-spot pre-empts
deleted documents count (restore), undownloaded files count, a never-reported device holds it up,
revoked devices ignored, "since the last change it pushed" (own push, not last pull).

## 6. Description draft
See `meta.md` (draft). ~200 words, we-register, one rule per sentence.

## 7. File footprint (reference, measured on the slice)
| Action | Path | Why |
|---|---|---|
| MODIFY | internal/relay/store.go | two new Store methods |
| MODIFY | internal/relay/memstore.go | reports, per-device last push, sweep |
| MODIFY | internal/relay/pgstore.go | same over Postgres + RLS-registered table |
| MODIFY | internal/relay/handler.go | report + reclaim routes |
| MODIFY | internal/sync/types.go | request/response types |
| MODIFY | internal/sync/blob.go | client calls |
| MODIFY | internal/sync/engine.go | report after the blob phase; Reclaim |
| MODIFY | internal/sync/apply.go | clear stale content when the checksum changes |
| MODIFY | internal/data/store_document.go | every checksum incl. deleted, undownloaded |
| MODIFY | cmd/micasa/pro.go | `--reclaim` flag + output |
Hunter sketch 328 hook-effective (PgStore 109). Slice re-measure in feedback.md.

## 8. Solution outline
- relay: `ReportBlobsInUse(hh, device, hashes)` stamps the report with the household's current seq;
  `ReclaimBlobs(hh)` computes each active device's last pushed seq, lists devices without a report at or
  after it, and otherwise deletes every blob outside the union of reports; returns removed/freed/used/
  waiting.
- client: `ReportBlobsInUse`, `ReclaimBlobs`.
- engine: report at the end of `Sync` (after push and both blob phases); `Reclaim` = Sync + reclaim.
- data: `DocumentChecksums()` Unscoped, non-empty `sha256` column (not a hash of local bytes).
- apply: in `applyUpdate` for documents, when the incoming `sha256` differs from the local one, clear
  `data` so the download phase fetches the new file.
- cli: `--reclaim` → Reclaim, print removed/freed/usage or waiting names.

## 9. Test outline
New file `cmd/micasa/pro_reclaim_<hex>_test.go` (package main): a household of in-process devices
(data.Store + sync.Engine over a MemStore relay on httptest) plus each device's secrets dir; reclaim
runs the real CLI binary as a subprocess with that device's XDG_DATA_HOME. Assertions on relay state
(`MemStore.HasBlob`, `BlobUsage`), CLI stdout and device document content.
Slice cells (core): replaced file reclaimed after every device synced; replaced file reaches the other
device; never-synced device holds it up (named); revoked device ignored; device that pushed after its
report holds it up; deleted document's file kept; file shared by two documents kept.
FINISH cells (planned): revoked creator x deleted x undownloaded (C joins after the delete, A revoked,
C restores → C downloads); report placement seen from another device (A syncs a new doc, B reclaims
immediately → not waiting); replace-back X→Y→X; reclaim then re-attach same content (re-upload);
quota freed for a new upload; whole-row LWW resurrecting an old checksum (stale device edits notes);
empty reclaim; usage line equals `micasa pro storage`.

## 10. Forced bounds
Subprocess CLI needs secrets in `$XDG_DATA_HOME/micasa/secrets` (crypto.Save*), so tests never call
an unexported Go function. Device names come from relay registration.

## 11. Trap matrix
| # | Trap | F-id | Class | Axis | Interdependent with | Why agents hit it | Test |
|---|---|---|---|---|---|---|---|
| 1 | report built from GORM-scoped rows / local bytes, so deleted or undownloaded documents are not listed | F-47 / F-78 | S4 | report CONTENT | #3 (stale bytes under new checksum hide a data-hash report bug) | `PendingBlobDocuments` is the pattern to copy and it is scoped | revoked creator x deleted x undownloaded restore |
| 2 | report stamped before the push or with the client's `last_seq` (own ops are never pulled, so it lags) | F-9 / F-15 | S3 | report TIMING | #1 (same report), #4 | `dev.LastSeq` is the obvious client-side stamp | another device reclaims right after A syncs a new document |
| 3 | replaced file never reaches peers (base: data kept, checksum updated) | F-39 | S3 | apply-side CONTENT | #1 | fix lives in apply.go, far from reclaim | B reads the new content after syncing |
| 4 | freshness keyed on the wrong push notion (any household op, upload time, or `>` instead of `>=`) | F-10 cell | S2 | relay GATE | #2 | dedup skips uploads, so upload time misses reuse | device pushed after its report waits; pushed-and-reported does not |

## 11b. Cross-product
| | file still referenced elsewhere | file unreferenced |
|---|---|---|
| doc live, downloaded | kept (shared file) | removed (replaced) |
| doc deleted / undownloaded | kept (restore later) | removed only when no report lists it |
Device axis: active+fresh / active+stale / never reported / revoked.

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Prediction
Nova 0/8 needs breadth (L131): 6+ stated sub-rules each with its own cross-device test, plus the
base content bug. Orion 1/4 needs one convergent cell; candidates: trap 1's revoked-creator cell and
trap 2's own-push stamp. Real risk: the stated surface converges (TOO-EASY class "stated surface
converged", eventsourcing). FINISH lever if Orion converges: Postgres in test.sh so PgStore (RLS table
registration, twin implementation, F-31) is graded. Nova sequence length: ~15-file reading surface,
expect one compaction per run (L116).

## 14. Quality gate
- [x] Phase 1 5/5, Phase 2 clean (commands in feedback.md)
- [x] Closest approved opened: approved-problems/micasa-field-level-sync-merge
- [x] Title verb-led
- [x] No new Go API pinned by tests
- [ ] Description finalised (FINISH)
- [ ] LOC >= 250 hook (slice re-measure in feedback.md)
- [ ] F-10 cells written (FINISH)

Why not a duplicate: the accepted micasa lane resolves concurrent row edits; this one adds relay-side
storage lifecycle with a per-device freshness gate. Different capability, different core files
(relay store/handler, blob client, CLI flag). Nearest corpus pattern: libspatialindex MVR pruning
(F-78, reclaim under reuse) — different repo and domain.

Predicted iteration cycles: 3.
