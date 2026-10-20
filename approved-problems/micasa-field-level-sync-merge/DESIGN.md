# DESIGN.md - micasa-field-level-sync-merge

Repo: micasa-dev/micasa (canonical, no redirect), Go, Apache-2.0 (+ vendored MIT glebarez-sqlite), 1280 stars.
Base: `0b0f92ae583bafc6242a3ed9dc756195d4162fb0` (= main HEAD on 2026-09-30, last commit 2026-08-09).

## Phase 1 - repo understanding

**Architecture.** micasa is a Go TUI (bubbletea, `internal/app`) plus cobra CLI (`cmd/micasa`) for home
projects, maintenance, appliances, vendors, documents and incidents, stored in SQLite through GORM
(`internal/data`, pure-Go glebarez driver, no CGO). The paid "pro" tier syncs devices through a relay:
every local mutation appends a FULL-ROW snapshot to `sync_oplog_entries` (insert/update carry the row as
JSON, delete/restore carry `{}`), with `applied_at` set at once and `synced_at` set after push. The engine
(`internal/sync/engine.go`) pulls ops after `last_seq`, applies them in relay-seq order
(`internal/sync/apply.go`), then pushes every unsynced op. A remote op that meets a pending local op for
the same row is resolved for the whole row by LWW (`created_at`, then device id).

**Subsystems.** (1) `internal/data` models/store/oplog hooks; (2) `internal/sync` engine/apply/client;
(3) `internal/relay` HTTP relay + MemStore/PgStore; (4) `cmd/micasa` CLI incl. `pro sync|status|conflicts`;
(5) `internal/app` TUI (sync status indicator only).

**Entanglement zones.** (a) oplog writers spread over every `store_*.go` (updateByIDWith, AfterCreate hooks,
raw delete/restore writes, document payload builder with `omitempty`); (b) `apply.go` conflict branch vs
`UnsyncedOps`/`pushAll` (the loser is marked unapplied but still pushed); (c) derived maintenance state
(`syncLastServiced` writes `last_serviced_at` with no oplog entry).

**Tests.** go test + testify. Two-device round trips run offline through `relay.NewMemStore()` behind
`httptest` (`internal/sync/roundtrip_test.go` is the formatting template; `engine_test.go` has
`setupEngineRelay`/`openTestStore`). In-package tests (`apply_test.go`) call `applyOne(db, op) error`
directly, which pins that signature (F-12 axis).

## Gates (run before any code)

- Canonical org `micasa-dev/micasa`. PR search (merge, field-level, per-field, three-way, conflict, LWW,
  concurrent, converge, diverge, last serviced, sync, supersede, lost update): only cpcloud/bot PRs; sync
  PRs #791/#802/#825 are the base LWW implementation. No lane hit.
- Issues: #479-#481 (closed, prestonvanloon event-sourcing plan, superseded by the oplog), #937 (open,
  read-only oplog CRUD CLI), #770 (local last-serviced, fixed in base). No request or decline of field merge.
- Philosophy: `plans/audit-2026-03-17-design-review.md:125` rates Update/Update LWW "Correct but
  coarse-grained (no per-field merge)"; post-v1 priorities (key rotation, unique constraints, op-loss
  detection, compaction) do not include it. Not a decline. `relay-architecture.md:114-115` states LWW and
  an append-only oplog; the design keeps both (LWW stays the tie rule, nothing is deleted).
- Post-base: base == origin/main; no commits base..HEAD.
- Fork scan: 55 forks, 214 branches compared against main; none touches `internal/sync`, `oplog*` or the
  pro conflicts command (cpcloud's show-command branch touches `store_servicelog.go` for a list method only;
  Byron's Rust port has no sync files).
- Local dedup: no sync/merge problem in approved/problems/rejected except sqlsync-observed-sync-state
  (watermarks, different repo, not a merge).
- Gate 1 (reproduced with the spike's own tests on base, see feedback.md): P1 lost edits + derived clobber,
  P2 permanent divergence with 0 conflicts.
- Gate 9: `go test ./internal/sync ./internal/data ./cmd/micasa ./internal/relay` deterministic (see
  eval-results.md).
- Quota: 0 submissions for micasa.

## 1. Title
Add field-level merging to micasa Pro sync conflicts

## 2. Shape
O-Pipeline-hard (new merge stage inside an existing pull/apply/push pipeline, invented algorithm on the
repo's own oplog model). Dominant verdict predicted: MISSED_REQUIREMENT / INTEGRATION_ERROR.

## 3. Public surface the tests touch (all pre-existing names)
- `sync.NewEngine(...).Sync(ctx) (SyncResult, error)`, `SyncResult.Conflicts`.
- `data.Store` CRUD (`UpdateVendor`, `UpdateMaintenance`, `CreateServiceLog`, `UpdateDocument`,
  `UpdateIncident`, `DeleteVendor`...), `OplogEntries`, `GormDB()` (to stamp fixed `created_at` values).
- `runProConflicts(w, dbPath)` (cmd/micasa, in-package test) output.
No new exported symbol is required by the tests.

## 4. Canonical rules
- Base = the row as this device last synced it: payload of the last insert/update this device both applied
  and exchanged with the relay. No base, or a delete/restore on either side: whole-row LWW as today.
- One-side change wins (clearing included); both-side different values: later edit OF THAT FIELD wins
  (created_at, then device id); equal values: no conflict.
- Units: maintenance {interval_months, due_date}; incident {status, previous_status, date_resolved}.
- Bookkeeping never merged: id, created_at, deleted_at, blob_ref; updated_at takes the later value.
- Merged row stored and pushed as a new update stamped with the later of the two sides' times;
  superseded/losing local ops never pushed.
- last_serviced_at: follows the service log on every device; with live entries it is the latest entry's
  date after a merge; without entries it merges as an ordinary field.
- Document payload omits empty fields; omitted = empty.
- Each discarded field edit is one conflict (SyncResult.Conflicts); `pro conflicts` lists it with field and
  discarded value next to whole-row losers.

## 5. Blind-spot pre-empts
result-ordering (later edit per field), rule-resolution (base definition), falsy-on-invalid (omitted =
empty), pipeline-placement (merged row pushed; stale ops not pushed).

## 6. Description draft
See `meta.md` (draft, SLICE stage).

## 7. File footprint (measured, hook human-effective 487 / raw 720 after slice fixes)
| Action | Path | human-eff |
|---|---|---|
| NEW | internal/sync/merge.go | 212 |
| NEW | internal/data/oplog_merge.go | 157 |
| MOD | internal/sync/apply.go | 48 |
| MOD | cmd/micasa/pro.go | 33 |
| MOD | internal/data/store_servicelog.go | 23 |
| MOD | internal/data/models.go (+meta_generated.go, generated) | 5 |
| MOD | internal/sync/engine.go | 1 |

## 8. Solution outline
- `data.MergeBase` (rowid-ordered applied+synced payload op), `data.PendingOps`, `data.SupersedePendingOps`
  (synced_at set; applied_at cleared only for whole-row losers), `data.AppendMergedOp`,
  `data.AppendRestoreOp`, `data.DecodeOplogPayload` (document omitempty zero-fill by reflection),
  `data.RecordLostFields` + `SyncOplogEntry.LostFields`, `data.FieldConflicts`,
  `data.LatestServicedAt`/`RefreshLastServiced`, `syncLastServiced` now logs the item when the date moves.
- `sync.mergeOne`: `localEditStamps` (walk pending ops from base, per-field last-edit stamp), `mergeUnits`
  (coupled groups first), `mergeRows` (three-way + LWW per unit), derived override, write, record remote op,
  supersede, append merged op, refresh derived parents for service-log merges.
- `applyOne` keeps its signature; `applyRemote` returns field conflicts; fallback adds restore-on-win.

## 9. Test outline
One new file `internal/sync/fieldmerge_<hex>_test.go` (package sync_test), two/three devices through the
in-process relay, fixed op timestamps, no sleeps. Plus one `cmd/micasa` in-package test for the conflicts
report. SLICE: core cells only; FINISH adds the F-10 matrix.

## 10. Forced bounds
`applyOne(db, op) error` must keep its signature (in-package tests call it).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| T1 | stale/superseded local ops still pushed (loser applied_at cleared but `UnsyncedOps` ignores it; filtering on applied_at breaks `TestEngineSyncSkipsBlobUploadForDocumentWithoutData`) | F-39 + F-12 | S3 | push path | T2 (merged op becomes next base) | pull-then-push convergence, delete-vs-edit cells; failure lands on the OTHER device |
| T2 | base must be the last applied+synced snapshot, not the op before the latest pending one; per-field edit time across several pending ops | F-47 | S1 | base reconstruction | T1, T3 | two pending edits then merge |
| T3 | document payload `omitempty`: absent key = cleared field (also breaks plain, non-concurrent apply and hard-delete detach) | F-24 | A9 | payload decoding | T2 | cleared document notes, both concurrent and plain |
| T4 | derived last_serviced_at travels in the item snapshot and wins; origin never logs the derived change | F-14 | S4 | derived state | T2 (excluded from diff) | service logged on A while B edits the item; failure on A |
| T5 | coupled groups split across sides | F-10 | S2 | unit granularity | - | interval vs due date; incident resolve vs reopen |

## 11b. Cross-product matrix (FINISH)
{vendor, maintenance, incident, document} x {one-side, both-side, clear} x {pull-first, push-first} x
{single pending op, several pending ops}; derived {with log entries, without}.

## 12. Tier/category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
15-35%: the merge rule itself is transcribable (Guard 4 risk); the band is carried by T1/T4 (other-device
failures), T2 (several pending ops), T3 (plain-path clear).

## 14. Quality gate
Phase 1 done; exclusivity/six-check/fork scan clean; LOC measured 479 hook; meta draft stated per rule.

Why not a duplicate: nearest corpus item is sqlsync-observed-sync-state (progress watermarks). No sync-merge
problem in approved/problems/rejected.
