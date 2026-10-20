# DESIGN.md - mirrorbits-mirror-sync-point

## 0. Phase 1 - repo understanding

**Architecture (one paragraph).** mirrorbits is a geographic download redirector. A daemon keeps
all state in Redis. The source scan (`scan.ScanSource`) walks the local reference repository and
rewrites one `FILE_<path>` hash per file (size, modTime, hashes) plus the `FILES` set, deleting the
hash of every path that left the tree. Mirror scans (`scan.Scan`, rsync or FTP) list a mirror and
record `MIRRORFILES_<id>` (paths), `FILEINFO_<id>_<path>` (size, modTime) and
`FILEMIRRORS_<path>` (mirror ids), then intersect with `FILES` into `HANDLEDFILES_<id>` and estimate a
timezone offset from a sample of that intersection. At request time `http.Filter` compares a
mirror's FILEINFO against the source per file (size, modTime with tz offset and protocol precision).
The monitor (`daemon`) health-checks a random `HANDLEDFILES` file over HTTP and schedules scans;
`rpc` exposes admin commands (add/edit/remove mirror) over gRPC for the CLI. A pubsub-invalidated
LRU cache (`mirrors.Cache`) fronts the Redis reads.

**Subsystems.** (1) `scan/` source scan + mirror scanners (rsync, FTP, trace file); (2) `mirrors/`
model, cache, logs; (3) `http/` redirection and selection (`Filter`); (4) `daemon/` monitor + cluster;
(5) `rpc/` + `cli/` administration; plus `database/` (Redis wrapper, pubsub, upgrades) and `config/`.

**High-entanglement zones.** `scan.Scan` (MULTI transaction spanning the scanner callback, SDIFF
removal, RENAME, SINTERSTORE, tz estimate, logs); the `Mirror` struct (Redis hash tags, JSON
mirrorlist, gRPC conversion in rpc/utils.go); `FILE_`/`FILEINFO_` hashes read by cache, Filter,
health check and tz estimate.

**Tests.** `go test ./...`, fully mocked with `redigomock` scripted connections; the `scan` package
has no tests. Template: `http/selection_test.go` (SetConfiguration + table-free explicit tests).
New tests need a real Redis (SDIFF/RENAME/MULTI/SINTERSTORE semantics), started by test.sh.

## 1. Title
Add source generations and mirror sync points to scans

## 2. Shape
- Shape: O-Pipeline-hard (new model + cascading integration, invented algorithm: a generation
  ledger with tombstones and an interval-intersection solver). SHAPES.md Pattern 12.
- Target: <= 40% ceiling, design for 15-30%.
- Dominant verdict predicted: MISSED_REQUIREMENT on integration facts (wrong generation number).

## 3. Public API surface (what the tests touch)
- `scan.ScanResult.SyncGeneration`, `.SourceGeneration`, `.FilesCurrent`, `.FilesBehind`,
  `.FilesUnknown`, `.FilesMissing`, `.FilesUnverified` (int64)
- the same seven fields on `mirrors.Mirror`, persisted in the mirror's Redis hash (tests read the hash
  with `redis.ScanStruct`, so the agent's own tag names round-trip)
- `config.Configuration.SourceHistory` (yaml `SourceHistory`, default 10)
- the "Scan completed" log text through `mirrors.ReadLogs`
- existing entry points only: `scan.ScanSource`, `scan.Scan`, daemon health check, `rpc.CLI.RemoveMirror`

## 4. Canonical form
- Generation: 0 before any tree; first scan with files = 1; +1 per scan with any add/remove/size or
  modTime change; rehash and no-op scans keep it.
- Version intervals half-open [introduced, superseded); deletion supersedes the last version.
- Window: the last `SourceHistory` generations (floored at 1); versions superseded at or before the
  window start are forgotten.
- Sync generation: max of the candidate set after intersecting every constraint, else 0.
- Counts: current / behind / unknown over remembered paths the listing contains; missing and
  unverified over paths the source still has; ignored: paths the source never had.
- Matching: size equal, and (zero mirror modTime) or modTime + this scan's tz offset truncated to
  this scan's precision equals the version modTime truncated the same way.

## 5. Blind-spot pre-empts
- rule-resolution: "at the precision of the scan's protocol after applying the timezone offset
  determined by that same scan" (not the stored/cached offset).
- adjacent-vs-all: "every path the source remembers" (tombstoned paths are evidence too).
- falsy-on-invalid: "or 0 when there is none".
- both sides of the carve-out named: unreadable -> no evidence, counted unverified, index kept;
  readable absence -> evidence, counted missing (L89 / carve-outs-must-name-both-sides).

## 6. Description draft
See meta.md (draft for the slice; ~450 words).

## 7. File footprint (measured spike, hook human-effective 299)
| Action | Path | eff |
|---|---|---|
| NEW | scan/ledger.go (history load/advance/forget/queue, matcher, solver) | ~165 |
| MODIFY | scan/scan.go (ScanSource hook before DEL FILE_, Scan carry-forward, fresh-only HANDLEDFILES, sync point persist, log, result) | ~80 |
| MODIFY | scan/rsync.go (opendir parse incl. `[sender]` form, module-relative path, exit-23 precision) | ~18 |
| ~~MODIFY~~ | scan/ftp.go: dropped 2026-10-04 (untested, meta word budget) | 0 |
| MODIFY | mirrors/mirrors.go, mirrors/logs.go | ~21 |
| MODIFY | daemon/monitor.go, rpc/rpc.go, config/config.go | ~4 |
TOTAL 299 human-effective, 9 files, 6 packages.

## 8. Solution outline
- `loadSourceHistory` (GET + HGETALL, outside any MULTI)
- `advance(files)` -> changed histories, clock +1 only on a real change; `forget` prunes by window
- `queue` into the same MULTI as `DEL FILE_` (so no version is lost)
- `sameContent` (size, tz, precision), `anyCovers`, `solve` (candidate bitmap over the window)
- `ScannerUnreadable(dir)` from rsync (opendir) and FTP (List failure below the root)
- `locateSyncPoint` after EXEC and after `adjustTZOffset`, persists fields + current-file set

## 9. Test outline (slice: 6 tests in scan/syncpoint_6075cf_test.go, build tag `syncpoint`)
Helpers: temp source repo with sub-second mtimes, fake `rsync` on PATH (stdout listing, stderr,
exit status from files), real Redis flushed per test, `snapshot()` of source entries to build
listings for older generations. FINISH adds: FTP fake server cells, tz-offset first-scan cell,
history-window cells, rehash via missing-hash path, health-check and RemoveMirror keyspace tests,
F-10 cross-product (held current/behind/deleted/unknown/absent x readable/unreadable x rsync/ftp),
the `[sender]` vs plain opendir parity cells (F-18), log round trip.

## 10. Forced bounds
None generic. Tests use only int64 result fields and Redis-hash round trips; no new signature.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Absence is evidence except under unreadable dirs; exit 23 swallowed, SDIFF deletes the subtree | F-52 / F-10 | S2 | evidence classification | #4 (tz sample), #5 | carve-out needs rsync parse + SDIFF change + solver exclusion | both sides named | unreadable test, FINISH cross cells |
| 2 | Deletion discards the only record (`DEL FILE_`) | F-47 | S4 | persistence | #1 (tombstone absence constraint) | ledger must be written in ScanSource before deletion | "a deleted path keeps its last version" | deleted-on-mirror test |
| 3 | Clock discipline: ScanSource rewrites every FILE_ each scan; rehash path | F-14 | S3 | clock | #2 | bump on write/rehash makes every mirror read behind | "a scan that changes nothing, including a forced rehash, keeps the generation" | rehash/no-op test |
| 4 | Stage ordering: tz offset estimated after HANDLEDFILES; conn inside MULTI during listing; cached offset stale | F-9 / F-64 | S3 | pipeline order | #1 (carried files must not vote) | classify in ScannerAddFile or with cached Mirror.TZOffset | "timezone offset determined by that same scan" | FINISH first-scan offset cell |
| 5 | Exit 23 returns precision 0; base opendir filter misses `rsync: [sender] opendir` | candidate (F-39 inherited helper) + F-18 | A9 | protocol precision / token form | #1 | agents' own listings use whole-second mtimes (P3 shadow) | "at the precision of the scan's protocol"; both message forms stated | unreadable test (sub-second source mtimes + `[sender]`) |
| 6 | Log fields must survive the JSON round trip in ReadLogs | F-47 variant | B | persistence | - | computing output from unexported/unsaved state | exact log suffix | log test |

## 11b. Cross-product matrix (FINISH)
| | readable listing | unreadable directory |
|---|---|---|
| held at current version | current, constrains | (cannot be listed) |
| held at older version | behind, constrains | - |
| held deleted version | behind, caps below deletion | - |
| listed, no match | unknown | - |
| absent, source has it | missing, constrains | unverified, no constraint, index kept |
| absent, source deleted it | constrains only | nothing |
x protocol {rsync, FTP}, x offset {none, detected this scan}.

## 12. Tier / category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
15-30%. Main killers predicted: #1 (carve-out wiring across rsync.go + Scan), #5 (precision 0 /
`[sender]` form), #4 (first-scan offset), F-10 deleted-path absence.

## 14. Quality gate
- [x] Phase 1 5/5; [x] Phase 2 searches (feedback.md); [x] footprint measured on a working spike
- [x] every trap names an F-id or is flagged a candidate; axes differ; #1/#4/#5 interdependent
- [ ] FINISH: F-10 cells, FP mutation pass, Rule-7 audit of meta, flakiness 3x

## Why this is not a duplicate
No mirror / sync-point / generation class in approved-problems, problems or rejected. Closest
approved shapes: afero-overlay-deletions (tombstones in a union FS) and agate-validity-interval-history
(validity intervals) - different domain (mirror listings vs a filesystem / a table), different
solver (intersection of evidence intervals over a generation window) and different integration
(Redis scan pipeline, rsync/FTP listings, health check).

Predicted iteration cycles: 2.

## FINISH round 1 (2026-10-04)
FTP removed from scope. Tests 6 -> 15 across scan/daemon/rpc (see feedback.md). meta 390 words. Dockerfile: no build-time go test.

## Round 10b lever (2026-10-10)
Batch 4 replay showed Orion 4/4 once the test-helper collision was fixed, and 40 probe cells converged. Two description rules were added on code paths no Orion patch touched: FTP subdirectories refused with 550 become unreadable (scan/ftp.go walk), with a both-sides guard (other failures and a refused top still fail the scan); and rsync opendir paths are module-relative, so a mirror URL below the module root must strip its in-module path (scan/rsync.go rsyncModulePath). Both reuse the existing unreadable machinery: unverified counts, kept index entries, persistence for re-evaluation.

## Round 11 cut (2026-10-11)
Task Prompt Quality failed on requirement count, and batch 5 showed the round-10b rules failed nobody. The meta keeps only the rules the solver needs end to end: generations and the history window, version matching at protocol precision, current/behind/unknown/missing, the partial-transfer unreadable exception, the sync generation, source-scan re-evaluation, the result fields and health checks. FTP 550, module-relative paths, the timezone clause, the log line and RemoveMirror left the meta and the tests. The reference keeps module-relative stripping and the tz offset as correct, unstated behaviour; ftp.go and logs.go went back to base. The one new rule sits in the only family that has ever failed Orion: in a partial rsync transfer, an entry rsync couldn't stat (`readlink_stat("..." (in module)) failed`) is unreadable like an opendir failure, and so is everything under it. Listed paths the source doesn't remember now count as unknown (the "ignored" clause was folded into "matching nothing"). Sync-point writes are guarded by WATCH so a stale computation can't land last.
