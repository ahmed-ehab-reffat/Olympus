# REPO-HUNT-2026-09-29-G (hunt #41, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). The run was cut off once by a rate limit while writing this log and resumed on 2026-09-30.

Scratch lives in `worktrees/_hunt/s_0929h41/`:
- `dead_h41.txt`: 10,946 slugs, made of hunt #40's dead-list plus every slug in the LEDGER, REPO-HUNT-2026-09-29-F and the h40 dossiers.
- `sel_h41.py` -> `sel_h41.tsv` (673 rows) and `sel2_h41.tsv` (174 rows): the cached-band selection.
- `topic_h41.tsv` (83 rows): the fresh topic sweep.
- `screen_h41.sh` (hunt #40's screener, unchanged) and `screen1..3_h41.txt`: the mechanical screens.
- `AGENT_BRIEF_h41.md` and `dossier_<repo>_h41.md` x 8: the lane audits, with their raw API dumps (`ca_*`, `mb_*`, `sc_*`, `ws_*`, `ag_*`, `nb_*`, `lnk_*`, `db_*`).

## Standing inputs
- **Direction:** hunt #40's NEXT_HUNT_HINT. Same stateful self-hosted axis, 500-6000 band, but the sync / replica / offline-first / local-first / import-export / migration rows that hunt #40's strong cut dropped.
  - Skip solo-roadmap repos and 100+ commit/90-day firehoses early.
  - Add `cosark` to `sig_accounts.txt`. **Done:** it is appended as the last line.
- **Excluded:**
  - Every LEDGER repo, and every repo with a `problems/` folder.
  - micasa, vega, capa, dstask, commafeed, db-scheduler, timewarrior, healthchecks (dead), Cwerg, MACS, pyOCD, pyfakefs, csbindgen and libspatialindex.
  - The axes of 09-28 and 09-29 through -F.
- **Requirement 0 (platform picker):** cannot be checked here. OWED.
- **Softening:** misses=0, so the 2026-09-09-B rules apply as written. No star or issue window was widened. Relaxations taken: none.
- **Orchestrator LOC rule:** return a lane only if its sketch is >= 270 eff with named coupled surfaces, and price it by the first shared operator downstream of its call sites. Healthchecks, vega and capa all measured 0.5-0.8x their sketches. The repricing is in its own section below.
- **Licence allowlist applied strictly:** MIT, BSD, Apache-2.0, BSL-1.0, CC-BY.
- **Disk:** 7.8G free on `/` at start and end (under 8G).
  - Per the hard limit, nothing was built, installed or run in Docker this hunt. Every Gate 9 (base health, 3x determinism, runtime repro) is OWED.
  - Base gaps are shown by cited code paths only.
  - Clones are blobless, 1.7-2.7M each.

## Stage 0-bis: the proven pool
- The pool was rebuilt from frontmatter. It is unchanged since hunts #39/#40: the only recent approvals, pict and macs-circular, are LEDGER rows. The pool was re-mined in #35-#37.
- Result: nothing new.

## Cached index: 500-6000 band, sync / local-first vocabulary
1. **Selection:** taken from `band.jsonl`, `band_misc.jsonl` and `band_noassert.jsonl`. The broad sync/offline/local-first/crdt/import/export/migrat/backup/restore/snapshot/webdav/notes/wiki/journal vocabulary gave 673 rows, with dead-list rows and hunt #40's already eye-passed `sel2_h40.tsv` rows removed.
2. **Tightening:** dropping `async`-type noise, `eslint import` and framework/ML junk left 174 rows. Both lists were eye-passed in full, plus the migration/versioning/CRDT rows the tightening dropped.
3. **Mechanical screen of 31 repos (`screen1/2_h41.txt`), and what killed each:**
   - **Dormant, or code-cold for 12 months:**
     - soundcloud/roshi: 1 commit in 12 months.
     - resgateio/resgate: 0.
     - dudor/BookmarkHub: 2.
     - thumbsup: 0, and `SAY-5`.
     - comtrya: 0 in 90 days, 14 in 12 months, failing cargo runs.
     - lumen-notes/lumen: 0 in 90 days.
     - chibisafe: 0 in 90 days.
     - fireproof: 0 in 90 days; development has moved on.
   - **Firehose (100 commits in 90 days):** trackio (HF org), otterwiki, kovetskiy/mark (also `team-humaki`), Beaver-Notes, icloud-docker, go-drive (licence NOASSERTION too), nao1215/gup, entireio/git-sync (92).
   - **Signature accounts:**
     - django-import-export: `binggao1230` + `SAY-5` + `uttam12331`. Three distinct accounts means reject.
     - WhatsApp-Chat-Exporter: `Sanjays2402`, plus 21 outside authors.
     - osxphotos: `SAY-5`, a solo firehose and a macOS-only suite.
   - **Other:**
     - tortoise/aerich: tests run on PRs only; migration-tool derivative risk.
     - AlpinDale/parsync: rsync-over-SSH tests.
     - Dancode-188/synckit: young, TS/C#/Rust, weekly benchmark CI only.
     - tui-journal: small domain, `SAY-5` x1.
4. **Sent to lane audit:** CrowdAnki, sqlalchemy-continuum, mirrorbits, wsgidav, yarlson/lnk, databunker.

## Fresh sweep 1: GitHub topic search, sync/replication vocabulary (1 of the 2 allowed)
- **Topics searched:** local-first, crdt, offline-first, sync-engine, replication, two-way-sync, bidirectional-sync, data-sync, file-sync, incremental-backup, backup-tool, deduplication, versioning, temporal-tables, audit-log, event-sourcing, changelog, reconciliation, conflict-resolution, merge.
- **Filters:** 500-6000 stars, permissive licence, pushed after 2025-12-01, dead-list filtered. That gave 83 rows (`topic_h41.tsv`).
- **What the rows looked like:**
  - The local-first topic is now mostly LLM-agent tooling.
  - The event-sourcing rows are frameworks or samples.
  - The replication rows need Postgres, MySQL, Redis clusters or ZFS.
- **Screened (`screen3_h41.txt`):**
  - bakito/adguardhome-sync and lovelaze/nebula-sync went to audit.
  - PySyncObj: Raft, so the famous-algorithm magnet.
  - eventhorizon: 0 commits in 90 days, event-sourcing magnet.
  - eljojo/rememory: Shamir, crypto nameable, 13 open PRs.
  - AkashRajpurohit/git-sync: renovate-only.
  - docat: small.
  - colanode: no CI, cold since April.
- A second fresh sweep was not needed.

## Lane audits (parallel subagents; brief `AGENT_BRIEF_h41.md`, gates 0-9 plus the Stage 6 guard)

| Repo | Stars | Verdict | Best lane / killer |
|---|---|---|---|
| **videolabs/mirrorbits** | 591 | **VIABLE, RANK 1** | Mirror sync point from a source generation ledger, with partial-listing evidence (sketch ~320). Dossier below |
| sqlalchemy-continuum/sqlalchemy-continuum | 644 | VIABLE, low; fallback 1 | `squash_transactions(first, last)`: merge a transaction range while every read surface (previous/next/index, version_at, changeset, version relationships, TransactionChanges/Meta, Activity) agrees at every surviving tx id, and rebuild `vacuum` on the same kernel. Sketch ~310. Walls: `vacuum` compares each version with the FIRST, not the previous (utils.py:239-248), and `naturally_equivalent` never matches validity data (F-39); `update_end_tx_column` never resets to NULL (schema.py:78); INSERT+DELETE must vanish and DELETE+INSERT must become UPDATE (operation.py:68-73); PK collisions in TransactionChanges/Meta; F-10 over 8 strategy x column-name cells (tests/__init__.py:203-239). Risks: #124, where the original author (2016) called history cleanup out of scope, against co-maintainer marksteward (#310, 2022) "happy to consider ... along with ageing"; outsider-nameable purge family (#124/#145/#310); the kernel can sit in one file; AI-assisted maintainer bursts (#376) |
| Stvad/CrowdAnki | 642 | VIABLE, low; fallback 2 | Baseline-aware three-way re-import: remote-only changes applied, local-only kept, both-sides kept and reported, baseline-aware deletions, no resurrection, baseline never exported. Sketch ~305. Walls: Anki's backend NFC/tag normalisation makes the stored note differ from the imported JSON (rslib notes/mod.rs:280-287, tags/register.rs), so both snapshots are needed (F-51/F-14); the remote dict is mutated in place before any baseline (note.py:136-141, F-19); per-subdeck recursion vs tree-wide deletion scope (deck.py:172-183, F-11); exported dicts carry any baseline away (deck.py:20-33, F-47). Risks: **same capability class as the queued micasa lane** (per-field three-way merge against a baseline plus a conflict report), which is a self-collision in the pipeline; PROVENANCE death-class adjacency; the image needs PyQt6 WebEngine (~1.3-1.6 GB) because the specs import `aqt.qt`; no import test exists today |
| mar10/wsgidav | 1236 | WEAK | Trash/undelete with dead properties and locks carried is ~200. The only wall (`delete()` reused by MOVE, request_server.py:1035/1055/1125/1159) is sidestepped by intercepting DELETE into `move_recursive`. Sync-collection (#63) is an RFC magnet, and Radicale ships it. If tagged-list is #347, a magnet. Lock/prop upkeep is ~90-130, and the lock code is under security-reporter fixes. Commit 2e368a3 (2026-09-15) made inter-realm copy/move an explicit refusal |
| bakito/adguardhome-sync | 1823 | WEAK | Constraint-aware apply ordering for clients and static leases is ~245 and reduces to one claim/release scheduling insight (the #328 class). Its rules live in the AdGuard server, so the test fake is the spec (Guard Q3 fails). The replica-preserving three-way lane is DEAD on philosophy: #477 "not planned and to complex", #536. Rollback on partial failure is absorbed (~60) |
| lovelaze/nebula-sync | 1636 | DEAD | Gate 0: the last functional code change was 2025-04-24; only a lint fix and a testcontainers bump since. Sync is an opaque Teleporter ZIP copy. #184/#210/#218 are change-detection magnets |
| yarlson/lnk | 656 | DEAD | Draft PR #45 (a Rust v2 rewrite with DESIGN.md/PLAN.md) publishes the applied-state / stale-symlink design. Commit 8185b9d removed doctor orphan detection. The best lane is ~210 |
| securitybunker/databunker | 1487 | DEAD | Record versioning is held back for the Pro edition (#20, closed 2025-10-31 "implemented ... in the databunkerpro version"). Bulk import is Pro too (#27). The vendored GeoLite2 mmdb is CC BY-SA, outside the allowlist |

## Repricing by the first shared operator (orchestrator rule; the realised/sketch ratio measured 0.5-0.8)
- **mirrorbits (sketch 320).** Every output surface (Mirror fields, log line, health-check pick, RemoveMirror cleanup) consumes one sync-point result, so the surfaces collapse to ~25. The match kernel shares Filter's truncation logic (selection.go:282-290), so it is ~15.

  | Part | Eff |
  |---|---|
  | Ledger write path in ScanSource (clock + versions + tombstones) | ~50 |
  | Solver | ~50 |
  | Scan integration after EXEC and the tz estimate, plus carry-forward in the SDIFF step | ~50 |
  | rsync opendir parsing | ~15 |
  | FTP per-directory record-and-continue | ~20 |
  | **Repriced total** | **~210-230** |

  - The FTP part is a behaviour change: today `walkFtp` aborts the whole scan on one failed `List` (ftp.go:118-120, 97-99). It needs an in-process FTP fake in the tests.
  - Rsync-only, the total is ~195-210.
  - It clears the 200 floor, but not the 250 design target.
- **sqlalchemy-continuum (sketch 310).** Entity tables, joined-inheritance tables and association version tables all run through one per-table routine over `version_class_map`, and the op fold, chain restitch and mod-flag recompute are passes of that routine. Repriced ~180-200.
- **CrowdAnki (sketch 305).** The per-field/tag three-way classifier is one generic operator (~30). Repriced ~190-200.
- **Consequence:** only mirrorbits reprices at or above the floor. It keeps RANK 1 with LOC margin as its first risk. Both fallbacks reprice at or under 200 and need a coupled lever before use.

## RANK 1 dossier: videolabs/mirrorbits, mirror sync point from a source generation ledger
Full dossier: `worktrees/_hunt/s_0929h41/dossier_mirrorbits_h41.md`. Clone: `worktrees/mirrorbits-h41` (blobless, 1.7M, no build, master HEAD `9061cc3e06a00c04cd92965dae46850f2785a91b`, 2026-08-07).

### Repo facts
- **URL / stars:** https://github.com/videolabs/mirrorbits, ★591. It is a geographical download redirector.
  - `etix/mirrorbits` redirects to it, and the module path is still `github.com/etix/mirrorbits`.
  - It is not a fork.
- **Language:** Go, 86% by bytes. No CGO. Deps are redigo, redigomock, maxminddb-golang (pure Go), grpc and an old vitess module, all fetchable at image build.
- **Licence:** MIT (LICENSE.txt). No vendor tree (removed in #214) and no bundled mmdb.
- **Activity:** 29 commits in 12 months, 5 in 90 days. The latest are the v0.6.2 release (2026-07-31), #227 (a CLI matcher) and geographical-sort toggle work. `scan/scan.go` was touched twice in 12 months, both cosmetic.
- **CI:** `test` success on master for the last 8 runs (2026-05-19..08-07), on a Go matrix of 1.18 / 1.24 / stable.
- **Tests:** `go test ./...` is fully mocked (redigomock, GeoIP mocks) and offline. The `scan` package has no tests at all.
- **Quota / self-collision:** 0 subs, and no folder in approved-problems/, problems/ or rejected/. No sync-point or mirror class exists in the corpus.

### The lane
**Capability:**
1. Each source scan that changes the tree advances a generation.
2. The source keeps a bounded per-path version ledger (size, modTime, introduced/superseded generation) with a tombstone on deletion.
3. Each mirror scan matches every listed file to a version (tz offset + protocol precision). A source file the mirror lacks is evidence, except under subtrees the listing could not read.
4. The scan solves for the newest source generation consistent with the mirror (its sync generation) and reports current / behind / unknown / missing / unverified counts.

**Surfaces:** the persisted Mirror fields (mirrorlist JSON), ScanResult, the "Scan completed" log, the health check (picks only files at their current version; today it picks from stale HANDLEDFILES, #152 class) and RemoveMirror key cleanup.

**Files (5 packages):**
- `scan/scan.go`: ScanSource, walkSource, Scan, adjustTZOffset;
- `scan/rsync.go`, `scan/ftp.go`;
- a new `scan/ledger.go`;
- `mirrors/mirrors.go`, `mirrors/logs.go`;
- `daemon/monitor.go` (getRandomFile);
- `rpc/rpc.go` (RemoveMirror cleanup only; no .proto change, because #226 is rewriting the generated code);
- `config/config.go` (history depth).

### Gate 1, base gap (code path; runtime repro OWED)
I verified these citations myself:
- **The rsync partial-listing path.** `rsync` exit 23 logs the opendir lines and sets `err1 = nil`, then `return 0, err1` (rsync.go:188-205), so a partial listing reads as success at precision 0.
- **Unreadable subtrees read as deleted.** Scan then SDIFFs MIRRORFILES against the fresh listing and SREMs / DELs every missing path (scan.go:159-179).
- **Deletion discards history.** On deletion, ScanSource sends `DEL FILE_<path>` (scan.go:549), so no record of the deleted version survives.
- **Unchanged files are rewritten.** walkSource rewrites FILE_ whenever hashes are missing or a rehash is forced, even with identical size/modTime (scan.go:405-424).
- **Nothing can say which version a mirror holds.** No code records it, or how far behind the mirror is. The only lag signal is one trace-file timestamp (`trace.go:131` HSET lastModTime).

### Trap seams

| Pattern | Present | Evidence |
|---|---|---|
| F-47 discarded state | yes | `DEL FILE_<path>` (scan.go:549) is the only deletion record. The ledger must be written before it |
| F-52 / F-10 absence vs blind listing | yes | Exit 23 is swallowed (rsync.go:188-205), then the SDIFF removal (scan.go:159-171). Absence-only gives a sync point that is too low; carry-forward-only gives one that is too high |
| F-14 clock discipline | yes | The rehash rewrite (scan.go:419-424) must not advance the generation, or every mirror reads one behind. The symptom is in mirror tests; the cause is in ScanSource |
| F-9 / F-64 stage + ordering | yes | The conn is inside MULTI from scan.go:131 through ScannerAddFile, so reads return QUEUED. The tz offset is estimated after HANDLEDFILES (scan.go:193-202). The cache refreshes only via async pubsub (cache.go:92-96). FTP precision is decided per scan (ftp.go:131-150) |
| F-39 inherited helper | partial | `walkFtp` aborts the whole scan on one failed List (ftp.go:118-120) |
| F-1, F-2, F-8, F-13 | no | Not a compiler; no famous algorithm named |

**Pairwise interdependence:**
- A x D: carried-forward entries must be excluded from the tz sample.
- B x C: tombstone generations are stamped by the clock.
- A x C: an extra file matching a tombstone caps the solver, while a blind subtree does not lower it.

### Other gates
- **Exclusivity:** all 114 PRs were pulled with file lists.
  - Diffs read: #148 (open draft, MULTI batching in scan.go: plumbing only), #147, #188 (AllowOutdatedFiles, selection), #62, #100, #211, #212, #226.
  - None implements versions, generations, sync point or carry-forward.
  - elboulangero's fork branches are clean.
  - The opensourceways/openEuler fork has a different "layerfile" repo-version mechanism. That is a mild sibling note, not a PR.
- **Six-check:** I read #152, #20 (a maintainer design sketch for rescan-before-enable, outside the lane), #94, #85 (a maintainer lean against SERVING deleted files, so the lane never serves them), #68, #149, #182, #104, #113 and #1.
  - No decline and nothing closed as implemented on the lane.
- **Competitors:** 0 sig_accounts hits (cosark included). The top authors are elboulangero 48, lazka 6 and Rechi 5. `amitmishra11` (#227, CLI) is one possible scattershot account outside the lane: a note.
- **Lane density:** churn is in cli/rpc/modernisation. There are no AI-sweep marks, no roadmap and no `fix/<topic>-*` family.
- **Removal / port / sibling:**
  - No removal record. Not a port.
  - MirrorBrain, MirrorManager2 and openSUSE MirrorCache (Perl/Python) track per-file presence only.
  - Debian-style trace files give a timestamp, not a per-generation solve.
- **Magnet:** MEDIUM-LOW.
  - "Mirror freshness" is nameable by an outsider.
  - No issue asks for a generation ledger or a sync-point solve. #94 and #152 are adjacent.
  - Mitigation: phrase `meta.md` on the repo's model (source scans, generations, listings, tombstones) and re-run PR-DIFF at submit.

### Stage 6 death-class guard (run by me on RANK 1): PASS, with flagged risks
1. **One shared kernel feeding several surfaces?** Yes. The ledger and interval solver feed the Mirror fields, ScanResult/log, health check and cleanup. A local fix to one trap (e.g. carry-forward) moves another (the tz sample, the solver bound).
2. **Interdependent traps?** Yes, pairwise as above. **Misdirecting?** Yes: every failure surfaces as a wrong generation number on a mirror, and the causes sit in ScanSource (clock), rsync.go (exit 23) and the MULTI/tz ordering.
3. **Standalone new file with minimal wiring?** No.
   - The ledger must be written inside ScanSource before `DEL FILE_` discards the version.
   - Carry-forward must change the SDIFF removal in Scan.
   - Classification must run after EXEC and after adjustTZOffset.
   - A post-pass file cannot recover discarded versions.
4. **TOO-EASY Pre-Pick Guard 1-5:**
   - #1: not one rule at N sites.
   - #2: not a single-subsystem transform; it spans scan source, mirror scan, mirrors model, daemon and rpc.
   - #3: the walls survive a meta that states the generation rule and both sides of the blind-listing carve-out. The fixes live in integration facts the prompt cannot name.
   - #4: no known named design to crib.
   - #5: survives full spelling.

**Flagged risks:**
1. **LOC margin.** Repriced ~210-230 (above). If the slice measures under 230, keep the FTP record-and-continue arm and the bounded-depth pruning.
2. **Redis in the container.** The lane tests need a real `redis-server` (SDIFF/SINTERSTORE/RENAME/MULTI semantics; redigomock is scripted).
   - Plan: olympus-base-go plus `apt-get install redis-server` at image build.
   - test.sh starts `redis-server --save "" --port <n> --daemonize yes` on loopback.
   - A fake `rsync` script on PATH emits the listing, the opendir stderr lines and exit 23.
   - Tests use `config.SetConfiguration`, run FLUSHALL between tests, and read results directly from Redis or the new API, never through the pubsub-invalidated cache.
   - Owed: confirm redis-server runs as root under the platform grader.
3. **Spec length.** The generation semantics and the two-sided carve-out need careful meta wording, with 0% risk on the first batch. Cap the domain (rsync listing forms, fixed history depth).
4. **Merge conflict.** Open draft #148 reworks Scan internals. That is a conflict risk only; re-check at submit.
5. **Req 0 picker.**

**Estimated complexity:** repriced ~210-230 eff (sketch 320) across 7-8 files in 5 packages.

## Fallbacks
1. **sqlalchemy-continuum/sqlalchemy-continuum, transaction-range squash** (`dossier_sqlalchemy-continuum_h41.md`, clone `worktrees/sqlalchemy-continuum-h41`).
   - Pure Python on SQLite, so Docker is easy.
   - Reprices ~180-200: it needs a coupled lever before use.
   - The #124 out-of-scope remark (original author, 2016) must be weighed against #310 (co-maintainer, 2022).
2. **Stvad/CrowdAnki, baseline-aware three-way re-import** (`dossier_CrowdAnki_h41.md`, clone `worktrees/CrowdAnki-h41`).
   - It has the strongest hidden wall of the three (backend normalisation).
   - But it is the same capability class as queued micasa. Do not run both through the pipeline.
   - The image is heavy.

## Clones and scratch
- **Kept:** `worktrees/mirrorbits-h41` (1.7M), `worktrees/sqlalchemy-continuum-h41` (2.7M), `worktrees/CrowdAnki-h41` (2.5M). None has build output.
- **Deleted:** lnk-h41, databunker-h41, nebula-sync-h41, wsgidav-h41, adguardhome-sync-h41.

## What the next hunt should change
1. **Config-relay sync tools are a dead sub-axis** (adguardhome-sync, nebula-sync). Their rules live in the upstream server, so the test fake becomes the spec. Prefer tools that OWN their stored state: an oplog, history tables, a re-imported export, a scan index.
2. **Every lane on this axis reprices at 0.6-0.7x of its sketch under the first-shared-operator rule.** The three-way-merge family (micasa, CrowdAnki) and history maintenance (continuum) all collapse to one generic per-field or per-table operator. To reach 250+ realised, a lane needs two structurally different kernels (mirrorbits: a ledger write path plus a solver), not one kernel applied to many tables.
3. **The GitHub `local-first` topic is now LLM-agent tooling;** skip it.
4. **Untried rows from this cut:**
   - tortoise/aerich (model-state snapshot vs migration files; PR-only CI);
   - AlpinDale/parsync (resume state; SSH tests);
   - looplab/eventhorizon (in-memory stores exist; cold 90 days).
5. **Disk** stayed under 8G all hunt, which blocked every Gate 9. Free root space before the next hunt, or allow container-only probes on /var/lib/docker.
