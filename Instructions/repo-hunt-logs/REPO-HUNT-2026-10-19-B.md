# Repo hunt 2026-10-19-B (hunter #73, CONSECUTIVE_MISSES=1)

**Result: CANDIDATE.** RANK 1 is `line/centraldogma`, lane **repository rename** (written 357 human-effective over 19 production files, 7 subsystems). Three more lanes cleared the 220 written bar and are fallbacks: go-workflows workflow reset (469), kellnr version retention (303) and slumber pinned exchanges (236).

All files for this hunt are in `worktrees/_hunt/s_1019h73/`:
- the brief `AGENT_BRIEF_h73.md` (the h73 block sits on top of the h72 brief);
- the screener `mech_h73.sh` and its outputs `mech0/1/2_h73.out`;
- the sweep script `sweep1_h73.sh` with `sweep1_raw_h73.tsv` and `sweep1_uniq_h73.tsv`;
- the residual filter `unshown_unjudged_h73.tsv`;
- eight dossiers `dossier_{aptly,commafeed,go-workflows,athens,slumber,kellnr,centraldogma,terrakube}_h73.md`;
- the sketches:
  - `sketch_centraldogma_repo-rename_h73.patch` (357)
  - `sketch_go-workflows_reset_h73.patch` (469)
  - `sketch_kellnr_retention_h73.patch` (303)
  - `sketch_slumber_pinned-exchanges_h73.patch` (236)
  - `sketch_athens_metadata-first-stash_h73.patch` (235)
  - `sketch_aptly_mirror-retention_h73.patch` (83, kept as evidence of death)
- tracker dumps per repo;
- backups `judged.bak_h73` and `sig_accounts.bak_h73`.

Clones kept (the VIABLE and WEAK lanes only): `centraldogma` (sketch applied, uncommitted), `go-workflows`, `kellnr`, `slumber` and `athens`. Every other clone was deleted. No builds were run. Disk `/` had 7.7G free at the start and 6.0G at the end, because other sessions are building.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):**
  - a LEDGER row excludes only its own lane and file set;
  - only repo-scope verdicts block a repo;
  - the star margin is ~505;
  - the return bar is 220 written;
  - the Q3 waiver applies only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule, and the AI-sweep, velocity, signature and tracker-named rules.
- **Softening:** none. The miss count is 1, and softening starts at 2.
- **Requirement 0 (platform picker):** OWED for every finalist. I cannot check it; the human checks it at precheck.
- **Lens (from the #72 hint and the 2026-10-18 passing-run 256k check):** wide-footprint stateful app lanes (the aptly shape), scored by production files edited (target >= 8 across >= 3 subsystems). Multi-backend parity counts as the app analogue of twin front ends. Width alone is too easy (aptly: Vega 4/4), so each lane also needs interdependent traps from the repo's own model.

## Stage 0-bis: proven pool
Agents audited aptly, commafeed and go-workflows (the app-shaped pool repos with in-flight or accepted lanes). The hunter re-verified the tork fallback himself.

| Repo (our subs) | Verdict | Detail |
|---|---|---|
| aptly-dev/aptly (1, in flight) | DEAD | Once the in-flight publish-history file set is excluded, the free surface is mirrors and tasks, and each funnels into one chokepoint. Mirror version retention **written 83**. Task cancellation is ~100-140 on paper. Reverse-dependency-safe removal is a dak/britney stage. Incremental update (#1622), missing files (#1528), keyring (#1053), export (#909/#257), purge (#291), audit log (#1058) and rolling publish (#1072) are tracker-named. The S3 pool is open PR #1607. Every repo or snapshot lane needs `api/repos.go`/`api/snapshot.go`, which are in-flight files. AdamMagued #1648 is a note. |
| Athou/commafeed (1, CLAIMED) | DEAD | 11 lanes. The tracker plus Discussions name nearly every user-visible feature: category rules #807/#1495/#1151, snooze #1047 (philosophy), per-feed retention D1029/#2041, undo D1734, smart lists D1117. The internal lanes are absorbed (websocket sync, GReader labels) or sit in the claimed refresh/status kernel. Latent bugs noted: category cycle in CategoryREST:428-435; orphaned children re-rooted on delete; fetchOne on duplicate sibling names; unregister FK order. |
| cschleiden/go-workflows (1, accepted) | **VIABLE, FALLBACK 1** | Workflow reset, **written 469**. Termination #196 is a maintainer roadmap item. Activity cancel #468, signal-with-start #291/#489, parent-close #47, signals across ContinueAsNew #493 and stats #381 are tracker-named. Retention of trees overlaps open PRs #475/#476. Delayed start is absorbed. The Copilot commits are all outside the lane. |
| runabol/tork (0, #69 fallback) | still clean, kept as FALLBACK | No commits since 10-15. The open PRs are #639 cordon, #638, and bot/docker bumps. The tracker search for "concurrency" only hits #445 each-concurrency and #3 queue concurrency. Concurrency groups stay at **written 256** (whitespace-ignored) over 12 files. |

## Cached index: unshown_big.tsv residual (the #72 hint)
- 677 rows; 661 after dropping every slug with any judged row.
- I read the Go/Java/Rust part by hand. App-shaped rows went to the screen: plakar, slumber, photofield, mark, safebucket, jjui, zrepl.
- Screened: plakar, slumber, photofield, mark, safebucket and jjui. zrepl needs ZFS, so I skipped it.

## Fresh sweep 1 (of 2): self-hosted app / registry topics
- **Topics (31, none used before):** apt, debian, mirror, registry, container-registry, oci-registry, go-proxy, helm-chart-repository, maven-repository, npm-registry, pypi, pypi-server, proxy-cache, object-storage, s3, restic, borg, snapshot, syncthing, rss, feed, podcast, bookmarks, notes, wiki, media-server, music-server, photo-management, self-hosted, package-manager, job-scheduler.
- **Funnel:** 198 raw rows, 181 after the repo-scope dead list. Mostly SDKs, AI wikis and libraries.
- **App-shaped rows screened mechanically (20, `mech1_h73.out`):**
  - athens, kellnr, cnpmcore, PowerJob, PodFetch, fusion, Flexget, stump, trow, artifact-keeper, wishlist, podsync, plus the residual six, cloudserver and supabase/storage.
- **Screen drops:**
  - plakar: its storage engine lives in the author-controlled sibling `kloset`; 26 AI trailers.
  - artifact-keeper: an AI-built shape.
  - mark: 94 AI trailers, plus a new 210-repo account.
  - photofield: Copilot commits, red CI.
  - PodFetch: 31 AI trailers.
  - fusion: "CI for agentic coding" commit.
  - podsync: claude workflows, low code activity.
  - trow: low activity.
  - Flexget: Sanjays2402 x3.
  - supabase/storage: corporate, breken-ai.
  - cloudserver and PowerJob: corporate or penalty band.
- **Audited:** athens, kellnr, slumber.

## Fresh sweep 2 (of 2): C++/Java tail of the cached band (the #72 hint)
- 315 Java/C++ rows at 505-6000 stars, permissive, pushed after 2026-04-01, with an app keyword, none judged.
- **Screened (`mech2_h73.out`):** centraldogma, terrakube, microcks, telegram-files, scoold, blazingmq, snail-job and fess.
- **Drops:**
  - microcks: six new 2025 contributor accounts, Mongo tests.
  - telegram-files: TDLib native.
  - scoold: a Para client.
  - blazingmq: heavy BDE C++ build, disk.
  - snail-job: no CI runs.
  - fess: OpenSearch tests, plus a solo fix sweep.
- **Audited:** centraldogma and terrakube.
- **Note on centraldogma CI:** the main runs read "failure", but only the jdk-25-snapshot and windows-jdk-25 legs fail (`GitHttpServiceTest > executionError`). jdk-11/17/21, lint, flaky-tests and e2e are green. That overturns the 10-16-C screen drop.

## Audit results (fresh lenses)

| Repo | Verdict | Best lane / killing gates |
|---|---|---|
| **line/centraldogma** (671, Apache-2.0) | **VIABLE, RANK 1** | Repository rename, **written 357 / 19 files**. Pull requests #1352, size limit #1307 and file history #1095 are maintainer-authored. Retention is #575 plus open PR #681. Revision tags are absorbed (each trap <= 3 lines). Repo copy is absorbed by `migrateToEncryptedRepository`. |
| cschleiden/go-workflows | VIABLE, FALLBACK 1 | see the pool table |
| kellnr/kellnr (1096, Apache-2.0 OR MIT) | VIABLE, FALLBACK 2 | Version retention policy, **written 303 / 15 files**. Killed: `-`/`_` normalization (crates.io rule), download restriction (#1374, maintainer), collections (#1283 plus a fork), storage repair (Q3), rdeps (#245), export (#1112/#680), maintenance (#1041/#1299). The yank ETag bug is real but a few lines. |
| LucasPickering/slumber (1230, MIT) | VIABLE (marginal), FALLBACK 3 | Pinned exchanges, **written 236 / 11 files**; the leanest passer is ~195-215. Killed: mock matching is his live stream; cycle detection has a removal record (shipped in #150/#287, lost in the v4 engine); cookie jar #241 is a roadmap item; prompt memory #591; prune and rename are absorbed; importers #417/#7. CONTRIBUTING bans LLM contributions. |
| gomods/athens (4808, MIT) | WEAK | Metadata-first stash, **written 235 / 21 files**, but padding-floor is 47 (lock-wrapper breadth), Artifactory and the go command already cache metadata only, and it cuts against athens's "last copy" stance. 10 lanes are tracker-named or absorbed (retention #1731/#2046/#1899, migration #1604/#2117, atomic writes #1841, list TTL #1175, negative cache #2030, delete API #1004, event hooks #1653 maintainer plus a branch). |
| terrakube-io/terrakube (970) | DEAD | The wide lanes are TFC/HCP features (rival-held reference tool) or tracker-named (#2752, #2693, #2085/#2106, #799). Storage parity is under open PRs #3724 (51 files) and #3413. The scheduler and executor are under a maintainer AI-assisted rework (14 Claude trailers). History-pruning storage cleanup is absorbed (~100-150). |

## RANK 1: line/centraldogma, repository rename
- **HEAD:** 6666e8975236bb7e4a712ae3b1d2f3292ddc7394 (2026-10-19).
- **Licence and size:** Apache-2.0, Java 83% / TS 13%, 671 stars.
- **Activity:** 162 commits in 12 months (minwoox 74, ikhoon 55, jrhee17 13). A LINE corporate team; 22 open PRs.
- **Signature accounts:** 0 in the last 150 PRs.
- **AI trailers:** 1.
- **Our submissions on the repo:** 0.
- **Outsider summary:** "Rename a Central Dogma repository in place. History and revisions stay the same. Everything filed under the old name moves to the new name: encrypted storage keys and wrapped DEKs, its metadata entry with roles and read-only status, and its mirrors, credentials and variables in the project's dogma repo. The old name becomes free again."
- **Sketch:** `s_1019h73/sketch_centraldogma_repo-rename_h73.patch`. **357 human-effective**, 472 raw, 19 production files, written but not compiled.
  - Padding-floor is 94. The new command class is boilerplate (~66). Without it and the client, the count is ~255.
- **Subsystems (7):**
  - the replicated command (new RenameRepositoryCommand, CommandType, StandaloneCommandExecutor);
  - storage (RepositoryManager, DirectoryBasedStorageManager, GitRepositoryManager, wrapper);
  - the encrypted RocksDB backend (EncryptionStorageManager plus its Default/Noop implementations, RepositoryEncryptionStorage);
  - MetadataService;
  - dogma-repo meta files (RepositoryServiceUtil);
  - the REST PATCH in RepositoryServiceV1;
  - the client (CentralDogma, ArmeriaCentralDogma, ReplicationLagTolerant, Legacy).
- **Reading surface:** ~11 KLOC.
- **Parity:** file-based JGit and encrypted RocksDB; GitRepositoryTest already runs both.
- **Traps** (verified on base by the hunter: `GitRepositoryManager.java:292/401` build the encrypted storage from `repoDir.getName()`, and the WDEK keys and rewrap path in `RepositoryEncryptionStorage.java:695/778-862` use the record's own `repoName()`):
  1. Encrypted identity is keyed by name. Metadata and DEK column families carry `project/repo`; object keys do not. A directory rename works for plain repos and loses encrypted ones on reopen. F-59, F-67.
  2. A rewrap rewrites keys under the DEK record's own `repoName`. Moving the keys but not the record resurrects the old name, and the failure surfaces later as "WDEK already exists" when the old name is reused. Misdirecting, F-59.
  3. A missing metadata entry reads as writable (StandaloneCommandExecutor.java:137-142), so a READ_ONLY repo becomes writable after rename. A stale old entry blocks re-creating the old name (MetadataService.java:413). F-78.
  4. Mirrors check `credentialName` against `localRepo` (MirrorConverter.java:67), and invalid mirrors are skipped silently since #1316. Repo-scoped credentials must move and project-level ones must not (both sides of the carve-out). F-3.
  5. Lifecycle collisions: the target may be live, removed or pending purge, and a purge deletes encrypted data by name asynchronously (GitRepositoryManager.java:487). Internal repos are excluded. F-78.
  6. The existing unremove PATCH must keep working, and other patches must still return 400. F-12.
  - One F-10 cell interlocks traps 1-4: rename, then create a repo with the old name (optionally encrypted, optionally after a rewrap).
- **Gate 1:** base rejects a PATCH `replace /name` with 400 (`checkUnremoveArgument`, HttpApiUtil.java:321-325). There is no client, command, storage or metadata path for rename. Runtime probe OWED.
- **Stage 6 death-class guard (run by the hunter):**
  - **Q1:** yes. One rename kernel (command, storage manager, backend hook) feeds REST, the client, replication replay, metadata and the meta files.
  - **Q2:** yes. Traps 1-4 interlock through the reuse cell, and each needs a different fix in a different subsystem.
  - **Q3:** no standalone file is possible (19 existing files across 7 subsystems), so the waiver is not needed.
  - **Q4 (Pre-Pick Guard 1-5):**
    - #1 is the residual risk: "move everything keyed by the name" is one insight. The sites are hidden in the encryption internals and differ in mechanism (column-family keys, the DEK record's own name, a metadata JSON entry, a mirror credential carve-out, the purge queue), so it does not collapse into one wrap.
    - #2: cross-subsystem.
    - #3: the walls survive being stated.
    - #4: not a port.
    - #5: yes.
  - **Result:** GUARD PASSED.
- **Exclusivity and tracker:**
  - I searched "rename repository", "rename repo", "repository name change" and "move repository" in issues and PRs; the only hit is PR #1254 (revert endpoint, unrelated).
  - The agent grepped 329 issue and 1043 PR bodies, the Discussions and the branches. #1286/#1289 rename a FILE in the web UI.
  - Open PRs #1333, #1350/#1342 and #1377 touch the same plumbing files (Command, RepositoryServiceV1, MetadataService, DirectoryBasedStorageManager) for other capabilities, so expect base drift.
- **Derivative risk:** "rename a repository" is outsider-nameable (GitHub, Gitea). That is a mitigation, not a kill: no tracker item asks for it, it is not a port, and the walls are internal. Phrase meta.md on Central Dogma's own model (encrypted repositories, DEK rewrap, metadata roles/read-only status, dogma-repo mirrors and credentials, purge).
- **Tests:**
  - Gradle + JUnit 5. One in-process `CentralDogmaExtension` drives the whole lane through the client or REST, with no external services.
  - Encryption via `EncryptionConfig(true,true,"kekId")` and the test key wrapper.
  - Restart via `dogma.stop()/start()`.
  - Replicas via `CentralDogmaReplicationExtension` with an embedded ZooKeeper.
- **Docker risk:** a JVM/Gradle offline build of an Armeria-sized multi-module project, and the webapp module uses Node. Expect a heavy image and a long cold build; time it against the 600 s environment start. `/` has only 6G free.

## Fallbacks (all written >= 220)
1. **cschleiden/go-workflows, workflow reset.**
   - Written 469 over 9 files. The SQL trio is near-duplicate, so a reviewer would amortize to ~300-377.
   - Kernel `backend/history/reset.go` (PlanReset at a workflow-task boundary) feeds sqlite/mysql/postgres/redis plus monoprocess and the client.
   - Traps:
     - sqlite activity ids are a global TEXT PK (schema.sql:45);
     - the redis `enqueue.lua` SADD silently drops a re-used activity id;
     - redis `last_sequence_id` is written only by complete_workflow_task.lua:85;
     - redis `msgs[len(msgs)-1]` panics on empty pending;
     - child links carry the execution id;
     - monoprocess wake-ups.
   - Parity suite: `backend/test` EndToEndBackendTest.
   - Risks:
     - Temporal ResetWorkflowExecution / DTFx Rewind make it outsider-nameable;
     - mysql/postgres need servers in test.sh, otherwise stubs are an FP hole;
     - our 1 accepted sub on the repo uses the same base 48e81194 (a different subsystem).
2. **kellnr/kellnr, version retention.**
   - Written 303 over 15 files, 6 subsystems.
   - Traps:
     - crate-file key casing plus `PutMode::Create` on re-publish;
     - two docs paths keyed differently;
     - doc-queue rows left behind;
     - unflushed DownloadCounter;
     - owner override vs global 0.
   - In-process sqlite + fs tests.
   - Risks: the Rust build is heavy (the `cargo` crate pulls libgit2/curl/openssl-sys), and it is Artifactory-nameable.
3. **runabol/tork, job concurrency groups.**
   - Written 256 (whitespace-ignored) over 12 files.
   - Needs postgres in test.sh.
   - Nameable via GitHub Actions concurrency.
4. **LucasPickering/slumber, pinned exchanges.**
   - Written 236 over 11 files, but the leanest passer is ~195-215 and pin-first ordering is a chokepoint.
5. **gomods/athens, metadata-first stash.** WEAK at 235: breadth padding plus reference-tool risk.

## Side findings
- **The multi-backend parity lens works.** It produced go-workflows (5 backends, one e2e suite) and centraldogma (JGit + encrypted RocksDB). It found nothing in aptly (publish parity is in-flight territory), kellnr (one sea-orm migration and one object_store trait, so no per-backend code) or terrakube (parity under open PRs).
- **App trackers are dense.** commafeed, aptly and athens each had 10+ lanes killed by tracker or Discussions. The lanes that survived were all invented from internal storage identity: names and keys reused after a delete or rename, executions re-created from history, and pins over a "latest" query.
- **Signature accounts:**
  - ChrisJr404 is on athens (#2153/#2154, outside the lane).
  - cosark is on commafeed, PodFetch, artifact-keeper and fess.
  - No new accounts were added to `sig_accounts.txt`.

## Submission counts (warning only)
- aptly 1, commafeed 1, go-workflows 1.
- Zero on centraldogma, kellnr, slumber, athens, tork, terrakube and every other screened repo.

## Verdict rows
`judged.tsv`: 16 rows appended (backup `s_1019h73/judged.bak_h73`), all lane-scope:
- CANDIDATE: centraldogma rename.
- Fallbacks: go-workflows reset, kellnr retention, slumber pins, athens stash.
- Dead lanes: centraldogma, go-workflows, kellnr, slumber and athens other lanes; aptly; commafeed; terrakube.
- Screen notes: plakar, artifact-keeper, mark.

## NEXT_HUNT_HINT
- **Keep the multi-backend / multi-store identity lens.** Lanes that rename, re-create or reuse a keyed entity across 2+ storage backends (encrypted vs plain, SQL vs redis) produced 3 of the 4 returnable lanes here.
- **Untouched app candidates from this hunt's screens:**
  - cnpmcore (MySQL/Postgres tests);
  - stump (Rust + TS comics server);
  - safebucket (Go + TS);
  - jjui;
  - wishlist (SvelteKit + Prisma).
