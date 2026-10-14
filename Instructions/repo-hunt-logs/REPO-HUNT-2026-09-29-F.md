# REPO-HUNT-2026-09-29-F (hunt #40, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Scratch lives in `worktrees/_hunt/s_0929h40/`:
- `dead_h40.txt`: 10,899 slugs named in any hunt log, the ledger, SATURATED-REPOS, TOO-EASY, a meta.md, or an agent dossier. It is used as the exclusion filter.
- `sel_h40.py` -> `sel_h40.tsv` (3,065 rows) and `sel2_h40.tsv` (928 rows): the selection from the cached band.
- `screen_h40.sh`, `screen1_h40.txt`, `screen2_h40.txt`: the mechanical screens. The script is hunt #39's screener plus a top-3 language line.
- `AGENT_BRIEF_h40.md` and `dossier_<repo>_h40.md`: seven lane audits, with their raw evidence (`ds_*`, `mc40_*`, `ms_*`, `pd_*`, `tw_*`, `pr704_h40.diff`).

## Standing inputs
- **Direction (orchestrator):** hunt #39's NEXT_HUNT_HINT. Re-screen the judged-but-never-audited rows of the cached 500-6000-star index for self-hosted tools and services with a stateful domain model (schedulers, monitors, trackers, ledgers, sync engines, workflow state machines), and apply the Docker-feasibility estimate early.
- **Excluded:**
  - Every LEDGER repo.
  - Every repo with a `problems/` folder.
  - healthchecks, Cwerg, MACS, pyOCD, pyfakefs, csbindgen and libspatialindex.
  - The reserved fallbacks vega/vega and mandiant/capa.
  - The axes spent in 09-28 and 09-29 through -E.
- **Requirement 0 (platform picker):** cannot be checked here. OWED.
- **Softening:** misses=0, so the 2026-09-09-B rules apply as written. No star or issue window was widened. Relaxations taken: none.
- **Licence allowlist applied strictly (RULES.md):** MIT, BSD, Apache-2.0, BSL-1.0, CC-BY. This dropped chrisbenincasa/tunarr (Zlib) at triage, and it puts a CC0 file in timewarrior on the risk list (below).
- **Disk:** 9.0G free at start, 7.8G at the end. The drop is not from this hunt; our clones total about 80M and no new files appeared in the Go/Maven caches.
  - Builds ran only in the timewarrior and commafeed containers, which were removed, plus a scratchpad dstask binary and micasa `go test`.
  - The reader, db-scheduler and multi-scrobbler audits skipped their installs under the 8G rule.

## Stage 0-bis: the proven pool
- The pool was rebuilt from frontmatter and is unchanged since hunt #39 (same day). The only recent approvals are pict and macs-circular, both LEDGER rows.
- Result: nothing new this cycle, as #39 recorded.

## Cached index: 500-6000 band, stateful self-hosted vocabulary
1. **Selection:** from `band.jsonl`, `band_misc.jsonl` and `band_noassert.jsonl`, take rows that are in scope, 500-6000 stars, pushed after 2025-09-29, on the permissive list, and not in the dead-list. That gives 3,065 rows on the broad state vocabulary.
2. **Narrowing:** a strong-vocabulary cut (self-host, scheduler, cron, workflow, state machine, uptime, ledger, accounting, budget, inventory, booking, calendar, backup, kanban, todo, habit, time tracking, sync, replication, retention...) plus a junk filter (AI/LLM, crypto, bots, templates, UI kits, k8s operators...). That left 928 rows.
3. **Eye pass:** all 928 rows, by language.
4. **Dropped already by earlier logs:** khal (09-15), octodns (09-20-C) and pyeventsourcing (09-23-P).
5. **Mechanical screen of 37 repos (`screen1/2_h40.txt`), and what killed each:**
   - **Dormant, or code-cold for 12 months:**
     - shynet: 2 commits in 12 months.
     - slo-generator: 1.
     - hassio-google-drive-backup: 0.
     - kala: 0.
     - django-scheduler: 0 in 90 days, 43 in 12 months.
     - todoman: 0 in 90 days; it also carries a `SAY-5` signature and the ISC licence.
     - syncall: 8 commits, failing CI.
   - **Red CI on the default branch:** alisaifee/limits (Compatibility `failure`), Syncplay, Koito (Test `failure`), sleek (Execute tests `failure`), django-helpdesk (latest run `failure`).
   - **Crowded or signature accounts:**
     - babybuddy: 34 open PRs, 30 outside authors, `NotAFlightRisk`, and copilot.
     - tasknotes: 371 issues, `SAY-5`.
     - kener: 22 outside authors, `cosark`.
     - spliit: 54 open PRs.
     - peekaping: `cosark`, and it is Uptime-Kuma-shaped, which is too near the in-flight healthchecks class.
   - **Other:**
     - Spoolman has no test workflow among its runs.
     - versatile_thermostat is a Home Assistant integration: a heavy test dependency and a two-maintainer firehose.
     - tududi and yarr are firehoses: 100 commits in 90 days each.
     - remark42: 91 issues and `paskal`'s stream.
     - ofelia: 153 issues, renovate-only stream.
     - zrepl: its core needs a ZFS pool.
     - tunarr: Zlib licence.
6. **New signature account for the self-hosted-app niche: `cosark`.**
   - Profile: no name, 312 repos, scattershot one-off PRs.
   - Seen on kener, peekaping and commafeed, and also on Calibre-Web-Automated, docspell, trip and Rackula-like apps.
   - Worth adding to `sig_accounts.txt`, but I did not edit it, because it is shared state.
7. **Seven repos went to lane audit** (parallel subagents; brief `AGENT_BRIEF_h40.md`, gates 0-9 plus the Stage 6 guard).

## Lane audits

| Repo | Stars | Verdict | Best lane / killer |
|---|---|---|---|
| **micasa-dev/micasa** | 1280 | **VIABLE, RANK 1** | Convergent field-level merge in the sync engine (~270 eff, 3 subsystems). Dossier below |
| **naggie/dstask** | 1206 | VIABLE, fallback 1 | Task-aware sync reconciliation keyed by UUID across status directories, plus load-time duplicate repair and undo of a sync merge (~310 eff, 5-6 files). All six divergence cells were reproduced through the real binary; only done-vs-note merges cleanly on base. Walls: status lives only in the path (F-47); the no-change shortcut in `GitCommit` leaves MERGE_HEAD (F-39, `git.go:62`); collapsed transitions hit `IsValidStateTransition` (F-20); resolved tasks are not loaded by default (F-24). Risks: a rule-heavy contract; the README section "Dealing with merge conflicts" makes it nameable; Stage 6 Q3 is borderline unless load repair and undo stay in the contract |
| **Athou/commafeed** | 3627 | VIABLE, fallback 2 | Relocate a subscription to a new feed URL, carrying read/starred/tag state by guid, with a deferred ledger consumed at refresh insert (~320 eff, Java). Walls: `applyFilter`'s status row versus UNIQUE(entry, subscription) rolls back the whole insert (F-41/F-9); "unread = no row" is computed in 4 places (F-14/F-47); ownership is taken from `entry.getFeed()` (F-20); www-normalisation and already-subscribed cells (F-10). Docker was measured: 61 ITs on H2 plus MockServer, identical 3x offline (`QUARKUS_DATASOURCE_JDBC_URL` override needed). Risks: a firehose maintainer (455 commits in 12 months, none in the lane); #1859 is adjacent; the image carries 640M of m2 plus a node download |
| kagkarlsson/db-scheduler | 1654 | VIABLE, low rank | Per-task cluster-wide concurrency limit (~265). Walls: the dead threshold sits on the far side of the Scheduler/Repository boundary, and `running_count` counts dead rows (F-47); head-of-line blocking under LIMIT; a refill loop; the generic versus single-statement lock paths. Down-ranked because in #207 the maintainer SKETCHED the single-table design (Stage 2d "published plan" = prior art), it is outsider-nameable across 4 threads, open #933 churns the same SQL, the embedded Postgres refuses root (the platform grades as root), and Gate 9 was not run (disk) |
| GothenburgBitFactory/timewarrior | 1665 | VIABLE, not ranked | Conflict-checked targeted undo over the journal (~250-300). There is a real base bug: `undo` fails with exit 255 after a flatten-producing edit (`CmdUndo.cpp:78-95`). **Licence risk:** `src/wcwidth.h` is a CC0 generated table, and CC0 is not on the RULES.md allowlist ("every licence ... even vendored"). The human must rule on it before this lane can be used. Also: "selective undo" is nameable, and the sister repo's TaskChampion #427 publishes a design |
| lemon24/reader | 559 | DEAD | A solo maintainer with a published roadmap and design notes (`docs/dev.rst:19-92, 298-772`) is building update-state/backoff (#420 pseudocode, commits 09-25..28) and database sync now. The best remaining lane, entry revisions (~200), fails Guard 2 and the standalone-module test |
| FoxxMD/multi-scrobbler | 1243 | DEAD | 1805 commits in 12 months (303 in September) across every stateful lane: dedup, queue/retry, history sync, player state (#691 is the maintainer's own). There is an AI-trailer PR in the dedup files. The only quiet subsystem, notifiers, is a standalone wrapper |

## RANK 1 dossier: micasa-dev/micasa, convergent field-level sync merge
Full dossier: `worktrees/_hunt/s_0929h40/dossier_micasa_h40.md`. Clone: `worktrees/micasa-h40` (blobless, 31M, clean, HEAD `0b0f92ae583bafc6242a3ed9dc756195d4162fb0`, 2026-08-09).

### Repo facts
- **URL / stars:** https://github.com/micasa-dev/micasa, ★1280. It is a TUI plus CLI for home projects, maintenance, appliances, vendors, documents and incidents, with an optional multi-device sync over a relay.
- **Language:** Go, 99%. GORM over pure-Go SQLite (glebarez), so no CGO.
- **Licence:** Apache-2.0, plus a vendored `LICENSE-glebarez-sqlite` (MIT). Every source file carries a two-line copyright header, which the builder must match on new files.
- **Activity:** created 2026-02-06. There are 1063 commits by cpcloud (Phillip Cloud), the only human committer. Feature work ran Feb-Apr (937/243/89 commits); May-Aug has 4 non-bot commits (ci/lint/docs/chore), the last on 2026-08-09. The code is cold, and Requirement 6 passes on the Feb-Apr code commits.
- **CI:** `success` on main.
- **Development style:** the repo is agent-built: AGENTS.md, CLAUDE.md, and 108 design docs in `plans/`. cpcloud drove 3 copilot-swe-agent PRs himself, none in sync.
- **Tests:** Go tests through the public store and sync engine. Two-device round trips run offline through an in-process `relay.NewMemStore()` behind `httptest`, and the existing `roundtrip_test.go` and `apply_test.go` already work this way. `go test ./internal/data ./internal/sync` was run 2x: 466 top-level PASS, 1 SKIP (the Postgres round trip), identical results.
- **Docker:** Pattern B, olympus-base-go. `go.mod` declares `go 1.26.5`, so the image must fetch that toolchain and the modules at build time, and then runs offline. New tests must use fixed op `created_at` values (the oplog uses `time.Now()`), with no sleeps.
- **Quota / self-collision:** 0 submissions and no corpus folder. The nearest class in the corpus is `approved-problems/sqlsync-observed-sync-state`: progress watermarks in a different repo, not a merge, so there is no self-collision.

### The lane
**Capability:** when two devices edit the same row between syncs, every device converges to one row.
- A field edited on only one side survives.
- A field edited on both sides resolves by the existing LWW rule (created_at, then device id).
- Coupled field groups merge as a unit: interval XOR due date, and incident status/previous_status/date_resolved.
- The derived `last_serviced_at` is recomputed from the replicated service log, not copied from a peer snapshot.
- `micasa pro conflicts` reports per-field conflicts.

**Files:**
- `internal/sync/apply.go` (conflict branch);
- a new `internal/sync/merge.go`;
- `internal/sync/engine.go` (push path);
- `internal/data/oplog.go` (base lookup, merged-op emission, payload normalisation);
- `internal/data/store_servicelog.go`;
- `cmd/micasa/pro.go`.

### Gate 1, reproduced on base (scratch tests against the in-process relay, since removed)
- **P1:** a service logged on A leaves B's `last_serviced_at` nil, because the derived update writes no oplog entry. Then A edits Notes and B edits IntervalMonths concurrently. Both devices end with notes="orig", interval=6 and last_serviced=nil. A's edit and A's service date are both lost.
- **P2:** B edits Phone (older) and A edits Notes (newer); sync A, then B, then A. The devices end at A={orig, 555} and B={from-A, ""}, with 0 conflicts reported. I verified the cause in the source:
  - `apply.go:119-135` clears `applied_at` on B's losing ops;
  - `UnsyncedOps` (`oplog.go:270`) selects only on `synced_at IS NULL`;
  - so `pushAll` (`engine.go:138ff`) still ships the losing snapshot, and A applies it unconditionally because A has no unsynced op for the row.

### Missing machinery (~270 eff by decision point; the nearest sibling, `applyOne` LWW, is ~50)
There is no common-ancestor snapshot per row, no field diff, no merged-op emission and no superseding of stale unsynced ops.

| Decision point | Eff-LOC |
|---|---|
| Base resolution from full-row snapshots | 35 |
| Payload normalisation: `omitempty`, float/int, time offsets | 40 |
| Three-way field merge plus coupled groups | 55 |
| Convergence: append-only merged op and stale-op supersede | 45 |
| Derived recompute | 30 |
| Per-field conflict records plus the CLI report | 45 |
| Delete-vs-update / no-base fallback to row LWW | 20 |

### Trap seams

| Pattern | Present | Evidence |
|---|---|---|
| F-47 discarded state | yes | The oplog stores full-row snapshots, not diffs (`store.go:558-569`). The base must be reconstructed, and the losing op's `applied_at` is cleared yet still pushed (`oplog.go:270`) |
| F-14 declared vs derived | yes | `last_serviced_at` is derived from the service log, but it travels inside the maintenance-row snapshot and wins field-LWW when stale (P1) |
| F-24 absent key | yes | `documentOplogPayload` uses `omitempty` (`oplog.go:134-152`), so a cleared title/notes is absent from the payload and a naive diff reads "unchanged"; `applyUpdate` (`apply.go:207`) also skips absent keys. This hits document rows only |
| F-39 inherited helper bug | yes | `UnsyncedOps` ignores `applied_at`. That is harmless under row LWW only because the loser's full snapshot never mixes with other state. The merge regime reaches it |
| F-10 cross-product | yes | {document, maintenance, incident, vendor} x {one-side, both-side, clear-field, delete} x {pull-first, push-first} x {coupled group split across sides} |
| F-9 stage boundary | partial | Sync is the apply stage versus the push stage: a correct merge on B fails its assertion on device A |
| F-1, F-2, F-8, F-13 | no | Not a compiler/parser; the famous name (three-way merge) is the MEDIUM risk below |

**Pairwise interdependence:**
- T1 (stale push) and T2 (base reconstruction) share the oplog, and T1's merged op becomes T2's next base.
- T3 (absent key) feeds T2's diff and apply.
- T4's exclusion of derived fields changes what T2 counts as changed.

### Other gates
- **Exclusivity:** all 559 PRs were enumerated. They are by cpcloud, bots, or the 3 self-driven copilot PRs. The sync PRs #791, #802 and #825 are all LWW and in base. The open PRs (renovate, #980 UI, #929 retract) do not touch sync.
- **Six-check:** searches for per-field, field-level, three-way, merge, concurrent edit, lost update, diverge, LWW and last serviced found no lane hits.
  - #770 / PR #772 (local-only `LastServicedAt`) are in base.
  - The design review marks row LWW "Correct but coarse-grained (no per-field merge)" (`plans/audit-2026-03-17-design-review.md:125`). That is not a decline, but it is a visible pointer.
- **Roadmap:** the post-v1 sync priorities (`design-review.md:240`) are key rotation, unique-constraint handling, op-loss detection and compaction, all of which are dead lanes. Per-field merge is not on the list. `grep -rE "per-field|three-way|column-level|CRDT" plans/` finds only that one table row.
- **Competitors:** zero outside PR authors ever merged, and none of the 31 issue authors is in `sig_accounts.txt`.
- **Removal / port / sibling:** nothing was removed, and it is not a port. cr-sqlite does column-LWW (C/Rust, with a different clock model), which cannot be cribbed onto an oplog of GORM snapshots.
- **Magnet / derivative:** MEDIUM.
  - There is no issue, and "field-level merge for sync" is nameable by an outsider who reads `plans/`.
  - Mitigation: phrase `meta.md` on the repo model (oplog snapshots, applied/synced state, derived last-serviced, coupled schedule and incident groups, per-field conflict report) and keep the F-10 cell table. Re-run PR-DIFF at submit.

### Stage 6 death-class guard (run by me on RANK 1): PASS, with flagged risks
1. **One shared kernel feeding several surfaces?** Yes. The merge kernel feeds the pull/apply path, the push path (supersede), the derived recompute and the conflict report. A local fix to push (skip unapplied ops) starves the peer of the winning fields unless a merged op is emitted, so each fix regresses another surface.
2. **Interdependent traps?** Yes, pairwise as above. **Misdirecting?** Yes: T1 fails on the other device, and T4 shows up in next-due/status output, not in the sync assertion.
3. **Standalone new file with minimal wiring?** No. `merge.go` alone leaves the stale push (engine/oplog), the derived recompute (servicelog store) and the report (CLI).
4. **TOO-EASY Pre-Pick Guard 1-5:**
   - #1: not one rule at N sites.
   - #2: not a single-subsystem transform; it spans data, sync and CLI, and the two-device interaction is emergent.
   - #3: the walls survive a meta that states convergence, per-field survival, the tie rule, the coupled groups and the derived recompute.
   - #4: RISK. Three-way per-field merge is a known design, so the difficulty must come from T1-T4 (repo-internal) and never from the merge rule.
   - #5: survives full spelling.

**Flagged risks:**
- Guard 4 (known merge design).
- The design-review pointer (MEDIUM derivative).
- A young repo whose maintainer could resume in a burst.
- The toolchain must be fetched at image build.
- A smoke batch of cold solvers is owed before authoring proper.

**Estimated complexity:** 250-300 eff across 5-6 files in 3 subsystems.

## Fallbacks
1. **naggie/dstask, task-aware sync reconciliation** (`dossier_dstask_h40.md`, clone `worktrees/dstask-h40`, base cdfd902).
   - Strongest base reproduction: six CLI-level divergence cells, five of them broken.
   - Weakest point: a contract with many merge rules. Keep them few and let the git walls carry the difficulty.
2. **Athou/commafeed, subscription relocation with guid-keyed state carry-over** (`dossier_commafeed_h40.md`, clone `worktrees/commafeed-h40`).
   - Best-measured Docker.
   - Firehose-maintainer risk; re-check the commit stream at slice time.

## Clones and scratch
- **Kept:**
  - `worktrees/micasa-h40` (31M, RANK 1);
  - `worktrees/dstask-h40` (18M);
  - `worktrees/commafeed-h40` (12M);
  - `worktrees/db-scheduler-h40` (5.2M);
  - `worktrees/timewarrior-h40` (7.0M).

  None has build output.
- **Deleted:** `reader-h40`, `multi-scrobbler-h40`.

## What the next hunt should change
- **The stateful self-hosted axis pays.** 7 audits gave 4 VIABLE plus 1 licence-blocked, and three of the four lanes are SYNC or RECONCILIATION lanes (micasa, dstask, commafeed): a second holder of the same fact that the repo keeps coarsely.
- **Next axis:** same vocabulary, 500-6000 band, rows with "sync", "replica", "offline-first", "local-first", "import/export" or "migration" that my strong cut dropped because the description said "notes", "wiki", "bookmarks" or "photos". The candidate rows are in `sel_h40.tsv` minus `sel2_h40.tsv`.
- **Kill profiles to skip early:**
  - a solo maintainer with a published roadmap/design doc (reader);
  - a 100+ commit/90-day firehose (multi-scrobbler, tududi, yarr).
- **Add `cosark`** to `sig_accounts.txt`: the self-hosted-app scattershot account.

## Result: CANDIDATE, micasa-dev/micasa, convergent field-level sync merge
