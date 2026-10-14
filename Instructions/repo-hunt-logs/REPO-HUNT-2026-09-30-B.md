# REPO-HUNT-2026-09-30-B (hunt #43, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch lives in `worktrees/_hunt/s_0930h43/`:
- **Exclusion lists:** `eyed_prev_h43.txt` holds hunt #40-#42's eye-passed selection rows (3,797 slugs). It is used together with `s_0930h42/dead_h42.txt`.
- **Cached-index selection:** `sel_h43.py` produces `sel_h43.tsv` (231 rows) on a new vocabulary.
- **Screens:** `screen_h43.sh` (hunt #42's screener, unchanged) wrote `screen1_h43.txt`.
- **Fork scan:** `forkscan_h43.sh` (a copy of `forkscan_h42.sh`). Its output is `forkscan_aptly_h43.txt` plus the per-agent files.
- **Lane audits:** `AGENT_BRIEF_h43.md` briefed the subagents. The results are in `dossier_{aptly,devpi,hashcards,hamilton}_h43.md`, with raw evidence under `ap_*`, `dv_*`, `hc_*` and `hm_*`.

## Standing inputs
- **Direction:** continue the two-kernel stateful-repo profile (a write-path ledger plus a solver, planner or replayer) that produced micasa, eventsourcing and mirrorbits.
- **Hint from hunt #42:**
  - Add the fork-branch scan to Stage 2b-bis.
  - Do not re-mine migration tools (aerich, piccolo, reshape).
  - Price each lane by the first shared operator downstream of its call sites.
  - Return only a lane whose repriced estimate is >= 260, with named coupled surfaces.
- **Excluded:**
  - Every LEDGER repo and every `problems/` folder.
  - The orchestrator's list: eventsourcing, mirrorbits, micasa, aerich, ipyflow, piccolo, pueue, reshape, parsync, eventhorizon, dstask, commafeed, sqlalchemy-continuum, CrowdAnki, vega, capa, healthchecks, db-scheduler, timewarrior, Cwerg, MACS, pyOCD, pyfakefs, csbindgen, libspatialindex.
  - The axes of REPO-HUNT-2026-09-28, 09-29 through -G, and 09-30.
- **Requirement 0 (platform picker):** OWED. It could not be checked here.
- **Softening:** misses=0, so the 2026-09-09-B rules apply as written. No star or issue window was widened. **Relaxations taken: none.**
- **Licence allowlist:** applied strictly.
- **Fork scan:** run on every audited repo (the new Stage 2b-bis step).
- **Disk:** `/` had 7.3G free at start and 7.2G at the end.
  - Nothing was built, installed or run in Docker, so Gate 9 is OWED everywhere.
  - Clones were blobless.
  - The dead clones (devpi-h43, hashcards-h43, hamilton-h43) were deleted.
  - `worktrees/aptly-h43` (56M, no build output) is kept.

## Stage 0-bis: the proven pool
- Unchanged since hunts #35-#42. The only recent approvals (pict, macs-circular) are LEDGER rows.
- Result: nothing new.

## Cached index: 500-6000 band, NEW vocabulary (not used by #40-#42)
- **Source:** band.jsonl, band_misc.jsonl and band_noassert.jsonl, pushed after 2026-01-01.
- **Filters:** permissive licence (plus NOASSERTION/empty, for a manual licence read), dead-list and hunt #40-#42 eye-passed rows removed.
- **Vocabulary:**
  - trading: backtest, order book, matching engine;
  - simulation: netcode, lockstep, deterministic simulation, discrete-event, checkpoint, save state;
  - spreadsheet and recalc;
  - consensus and Paxos;
  - ratings: tournament, pairing, Elo;
  - spaced repetition and flashcards;
  - business records: inventory, BOM, billing, metering, payroll;
  - package/artifact repository managers, mirrors and registries;
  - data history: provenance, lineage, reproducibility, memoisation, snapshot, versioned, history, audit trail, bitemporal, point-in-time;
  - scheduling and people: timetable, roster, genealogy;
  - quota and rate limiting.
- **Result:** 231 rows, mostly noise: "operating system" matched "rating system", plus mirrors of other VCS hosts, ML checkpoints, UI registries and SDKs.
- **Rows that fit the profile:**
  - aptly-dev/aptly (sent to audit);
  - chronoxor/CppTrader;
  - eudoxia0/hashcards (sent to audit);
  - aiidateam/aiida-core;
  - python-cachier, joblib (single-kernel caches);
  - sigstore/rekor, MarquezProject/marquez (company, external services).

## Fresh sweep 1: knowledge brainstorm on repository managers, provenance and SRS (1 of 2)
Every name was checked against the dead-list and the eye-passed list first. Screen results are in `screen1_h43.txt`.

| Repo | Screen verdict |
|---|---|
| mozilla/cargo-vet | DEAD. Req 7: "Rust CI" fails 8 of 8 on main; 0 commits in 90 days |
| devpi/devpi | sent to audit |
| theupdateframework/python-tuf | DEAD. A TUF-spec client (faithful-port class) plus ChrisJr404 (signature account) |
| pyinfra-dev/pyinfra | DEAD. ★6018, Sanjays2402 (signature account), 0xTaoZ with 19 PRs |
| chronoxor/CppTrader | DEAD. 8 commits in 12 months, in-memory only (no stored ledger), CLAUDE.md-assisted, gil submodules |
| beetbox/beets | DEAD. ★15.7k, CAOShurong (signature account, 10 PRs) |
| kopia/kopia | DEAD. ★14k firehose |
| aiidateam/aiida-core | DEAD. 100 commits in 90 days, 100 open PRs, team firehose |
| datalad/datalad | DEAD. Req 7: `Test` fails on the default branch `maint` (09-25..09-30), plus a gitmate bot and a copilot-swe-agent PR |
| apache/hamilton | sent to audit |
| **Dead-list hits, already judged** | tinybase, xodus, OpenRefine, Chronicle-Queue, ledger, graphhopper, traccar, nitrite, OTP, icechunk, diskcache, snakemake, redun, vdirsyncer, ironcalc, hftbacktest, barter-rs, ggrs, gtsam, bt, bleve, bluge, quix-streams, salsa, loro, automerge, yjs |

## Fresh sweep 2: data-versioning and storage-engine brainstorm (2 of 2)
- earth-mover/icechunk and quiltdata/quilt: company firehoses (100 commits in 90 days; paraseba and QuiltSimon).
- lancedb/lance, delta-io/delta-rs and apache/iceberg-python: dropped without a screen.
  - They are spec-named (Delta and Iceberg protocols; a faithful port of the Java reference).
  - They are company firehoses.
  - lance and delta-rs are also multi-GB cargo builds.
- Event-sourcing siblings of the queued eventsourcing pick:
  - Under 500 stars: hallgren/eventsourcing, modernice/goes, cqrs-es, castore, occurrent, disintegrate.
  - Licence null or MPL: hallgren and emmett.
  - get-eventually/eventually-rs (★600) was not pursued: it has the same capability class as the queued eventsourcing lane, a self-collision risk.

## Lane audits (the hunter did aptly; three parallel subagents did the rest)

| Repo | Stars | Verdict | Best lane, and what killed it |
|---|---|---|---|
| aptly-dev/aptly | 2886 | WEAK | **A. Snapshot recipe ledger plus refresh cascade.** Snapshot keeps only SourceKind/SourceIDs plus free text (`deb/snapshot.go:19-47`); pull args and config-derived architectures are discarded (`cmd/snapshot_pull.go:67-80`); CLI and API duplicate the creation paths. The replay half is absorbed by `PackageList.Filter` and `PackageRefList.Merge`. Repriced ~200.<br>**B. Publish history plus rollback with retention-aware pool and db GC.** It has three holders and two origins, but the write chokepoint is `PublishedRepoCollection.Update` and rollback reuses `Publish()`. Repriced ~220-240. The publish lane is warm: by-hash PRs #1621/#1626/#1633, S3 PRs #1614/#1616, and the Daedaluz fork's `claude/*` publish branches. #902 is an open "snapshot update" request |
| devpi/devpi | 1228 | WEAK | **Index-scoped partial metadata replica.** The first shared operator is `KeyFS.import_changes`; repriced ~205-240. What decides it: the maintainer's public fork branch `fschulze/devpi:server7` (+12986/-7358 in server, updated 2026-08-21..09-17) rewrites keyfs (SQLAlchemy), model/inheritance.py and replica.py. Snapshot/copy is dead to PR #900 plus the maintainer's `enh-add-snapshot-feature` branch. An inheritance-aware change tag already exists in server7 (a014ce10). Point-in-time reads are absorbed (`keyfs.py:620`, `857-911`). Revisit after 7.0 lands |
| eudoxia0/hashcards | 1168 | DEAD | **Retroactive history amendment plus FSRS replay.** ~185, a thin fold over `update_performance`. Card lineage across edits was declined twice (#87, #168). Card stages is the only lane over 260, and it sits in the maintainer's IDEAS.md roadmap, which outsiders implement (#196, #198) |
| apache/hamilton | 2601 | DEAD | **Run-history retention/GC for caching.** ~230. Real wall: cache hits never write run history (`adapter.py:1338-1356`, F-47). Killed by the published roadmap bullet "cache eviction" (`docs/concepts/caching.rst:681`), textbook mark-and-sweep (DVC gc, joblib `reduce_size`), and `breken-ai` (an AI auto-fix account) with a 6-PR burst on 09-25/26 outside the lane |

**Repricing (orchestrator rule).**
- None of the four clears 260.
- Every best lane collapsed onto one pre-existing operator. The planner/replayer half kept reusing machinery the repo already owns: aptly's Filter/Merge/Publish, devpi's import_changes and sro, hashcards' update_performance, hamilton's store deletes.
- The same 0.7-0.9x pattern hunt #42 measured on migration tools.

**No RANK 1**, so the Stage 6 death-class guard was not run. Stage 6 notes from the audits:
- devpi lane A passes Q1-Q3 but has a Guard 3 risk (shrink, redaction and mirror-base rules all need spelling out).
- hamilton L1 partly fails Q4 (textbook mark-and-sweep).

## Fallbacks (both under the 260 bar)
1. **aptly-dev/aptly, publish history plus rollback** (~220-240): three GC holders (history, pool cleanup, db cleanup) and two origins. Needs a coupled lever to reach 260. Clone: `worktrees/aptly-h43`.
2. **devpi/devpi, index-scoped partial replica** (~205-240): only after server7/7.0 lands on main.

## Fork-scan results (new Stage 2b-bis step, `forkscan_h43.sh`)
- **aptly:** Daedaluz `claude/edit-publication-architectures-*` and `claude/update-publish-api-release-*` (a user's own AI-assisted publish work: a NOTE, but it is in lane B's area). NeatNerdPrime is a mirrored branch.
- **devpi:** no dataset families.
- **hashcards:** longregen `claude/*` for its own WASM website fork, outside every lane.
- **hamilton:** `codex/prefect-ui-walkthrough` and `task_submission_hook`. Both diffs were read; neither touches caching.
- **No `codex/<date>-project-N` or `commit0_all` families this hunt.**

## What the next hunt should change
1. **The two-kernel profile is producing a consistent pricing failure, not a discovery failure.** Seven audited repos across #42 and #43 each had a real write-path wall (F-47 discarded state), but the solver half reused existing machinery. The operator that decides the price was, repo by repo:

   | Repo | Operator that decided the price |
   |---|---|
   | aerich | the resolver |
   | piccolo | table rebuild |
   | aptly | Filter/Merge/Publish |
   | devpi | import_changes |
   | hashcards | the FSRS step |
   | hamilton | store deletes |

   Only eventsourcing, whose cut solver needed a greatest fixed point over a NEW ledger, cleared.
2. **Next hunt: invert the order.**
   - First find a repo whose domain needs a solver the repo lacks entirely (fixed point, cut, assignment, schedule).
   - Then check that the solver needs state the write path discards.
   - Screening for "has a ledger" first selects for repos whose planner already exists.
3. **Discovery is saturated.** The cached index needed a noise-heavy vocabulary to surface 3 profile rows; the knowledge brainstorms hit the dead-list on ~60% of names. Consider re-adjudicating the WEAK rows of #40-#43 against a coupled lever instead: aptly B, devpi A after 7.0, aerich squash, ipyflow.
4. **Stage 2c addition:** a maintainer FORK branch can be the real development line (devpi `fschulze/devpi:server7`, 179 commits ahead). List the maintainer's own fork branches next to the fork scan, and treat a large ahead-count rewrite of the lane's files as capability-consuming.
5. **Signature account list:** consider adding `breken-ai` (AI auto-fix account, created 2026-08, 344 repos, 0 followers, bursts on large repos) and `r3wretrhy` (79 repos, scattershot fixes) to `worktrees/_hunt/sig_accounts.txt`. This hunt did not edit that file.
