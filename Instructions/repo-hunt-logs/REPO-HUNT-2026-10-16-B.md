# REPO-HUNT-2026-10-16-B (hunter #69, CONSECUTIVE_MISSES=3)

Worker: olympus-hunter (unattended). Result: **CANDIDATE topfreegames/pitaya, frontend session resume and cross-frontend handover** (written sketch 303 human-effective over 10 files).

Four lanes cleared the 220 written bar:
- pitaya session resume, 303
- tork job concurrency groups, 256 (whitespace-ignored)
- olric DMap tombstones, 229
- saq job output streams, 226

Scratch: `worktrees/_hunt/s_1016h69/` (19M, nothing built, no `target/`). It holds:
- the brief `AGENT_BRIEF_h69.md` (the h69 block sits on top of the h68 brief);
- the topic sweep `topics_h69.txt`, `topic_raw_h69.tsv` (485 rows), `topic_alive_h69.tsv` (384) and `unj_h69.tsv` (368 never-judged rows);
- the screener `mech_h69.sh`, with output in `mechall_h69.out` (30 repos);
- dossiers `dossier_{tork,pitaya,gazette,olric,centrifuge,saq,huey,remotestorage.js,graft,pufferpanel,kameo}_h69.md`;
- sketches `sketch_pitaya_session-resume_h69.patch` (303), `sketch_tork_concurrency-groups_h69.patch` (339 raw hook; the `_ws_` variant, 256, ignores gofmt realignment), `sketch_olric_tombstones_h69.patch` (229), `sketch_saq_job_streams_h69.patch` (226), `sketch_pufferpanel_pathgrants_h69.patch` (170), `sketch_remotestorage_cache-eviction_h69.patch` (108) and `sketch_remotestorage_orphan-push_h69.patch` (37);
- tracker dumps per repo;
- backups `judged.bak_h69`, `sig_accounts.bak_h69` and `used_topics.bak_h69`.

Clones kept (the VIABLE or WEAK lanes only): `pitaya` (sketch applied, unstaged), `tork` (branch `h69-concurrency`, uncommitted), `olric` and `saq`. Every other clone was deleted.

Disk `/`: 11G free at the start, 8.0G at the end. Other sessions are building; this hunt built nothing.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):**
  - a LEDGER row excludes only its own lane;
  - only repo-scope verdicts block a repo;
  - the star margin is ~505;
  - the return bar is 220 written;
  - the Q3 waiver applies only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:**
  - the maintainer-roadmap magnet rule;
  - the AI-sweep, velocity and signature rules;
  - the 2026-10-13 tracker-named-lane rule.
- **Softening (misses = 3), relaxations recorded:**
  - The softened 2026-09-09-B rules were applied: one signature visit outside the lane is a note (murraywu on pitaya, docs PRs only), and capability-consuming is a lane verdict.
  - **Star window widened to 500-8,000** for the topic sweep.
  - The issue window was not used as a gate.
- **Requirement 0:** OWED (the human checks the picker).
- **Excluded lanes:**
  - Cwerg compact unions, allsorts, micasa blob reclaim, qq;
  - pint, commafeed, aptly, ray-optics module inlining, eventsourcing, mirrorbits;
  - every CLAIMED row;
  - the platform-dead lanes.
- **Defaults taken unasked:**
  - **The proven pool was not re-audited.** Every pool repo's newest lane verdict is newer than 60 days, except pulldown-cmark (07-31) and lifelines (08-20, expiring 10-19). pulldown-cmark is dead on signature bursts (4 accounts) and lifelines is competitor-visited (`SATURATED-REPOS.md § B3-bis`). No acceptance landed after #68: qq, csbindgen, micasa and mirrorbits were already covered by #60-#68. neva stays parked until 10-20.
  - **The mechanical screen was stopped after 7 repos and re-run 4-way parallel,** because it ran at ~2.5 min per repo.
  - **Lanes were audited by five parallel agents.** The hunter audited tork himself.

## Stage 0-bis: proven pool
- **Result: nothing usable.** See the defaults above.
- **Pool counts (warning only):** pitaya 0, tork 0, olric 0, saq 0. All four are new repos to us.

## Fresh sweep 1 (of 2): GitHub TOPIC sweep on two-process topics (new lens)
- **Rationale:** #68's hint. Single-process apps die at one chokepoint (110-190 written). Our returnable app lanes crossed two cooperating stateful processes: micasa client+relay, commafeed, mirrorbits scanner+source, aptly.
- **Topics (50, none in `used_topics.txt` before today):** local-first, replication, raft, gossip, sync-engine, offline-first, job-queue, task-queue, distributed-scheduler, message-queue, pubsub, mqtt-broker, rsync, backup, dht, libp2p, multiplayer, netcode, rollback-netcode, game-server, lockstep, consensus, paxos, leader-election, change-data-capture, cdc, event-sourcing, workflow-engine, durable-execution, actor-model, actors, state-synchronization, delta-sync, wal, peer-to-peer, federation, activitypub, xmpp, distributed-systems, service-discovery, distributed-lock, key-value-store, message-broker, background-jobs, cron, scheduler, synchronization, file-sync, deduplication, incremental-backup. All are now appended to `used_topics.txt`.
- **Funnel:**
  - 485 rows at 500-8,000★, permissive licence, in-scope language, pushed within 12 months;
  - 384 after the repo-dead list;
  - 368 with no judged row at all.
- **Triage by eye:** famous infrastructure, AI-agent repos, k8s operators, spec-port protocol libraries (XMPP, MQTT, libp2p, DHT, ActivityPub) and education repos were dropped. The 30 two-process engines left were screened mechanically.

| Repo | Screen reading |
|---|---|
| runabol/tork (Go 820) | runabol 54 of 62 commits, no signature accounts; CI green on HEAD (runtime/shell 10-min timeout flake). **Audited** |
| topfreegames/pitaya (Go 2836) | 16 commits, 29 open PRs, CI green. **Audited** |
| olric-data/olric (Go 3499) | buraksezer 29 commits. **Audited** |
| centrifugal/centrifuge (Go 1488) | FZambia 124 of 138 commits. **Audited** |
| gazette/core (Go 798) | team, CI green. **Audited** |
| coleifer/huey (Py 6049) | coleifer 230 commits, uttam12331 x1. **Audited** |
| tobymao/saq (Py 891) | tobymao 31 commits. **Audited** |
| remotestorage/remotestorage.js (JS/TS 2427) | CI green. **Audited** |
| orbitinghail/graft (Rust 1560) | carlsverre 275 commits. **Audited** |
| pufferpanel/pufferpanel (Go 1753) | LordRalex 75 commits. **Audited** |
| tqwewe/kameo (Rust 1399) | tqwewe 78 commits. **Audited** |
| zerodha/dungbeetle, akrylysov/pogreb, anthdm/hollywood, bitleak/lmstfy, get-eventually/eventually-rs, lemunozm/message-io | corpses or dormant (0-7 commits in 12 months, often dependabot) |
| gocronx-team/gocron | gocronx 286-commit solo firehose. Not audited |
| bakwc/PySyncObj | Raft (textbook, sibling cribs). Not audited |
| insitro/redun | 54 AI trailers plus a Claude PR-review workflow. Not audited |
| evennia/evennia | Sanjays2402 x3 (signature account), Griatch firehose. Not audited |
| zrepl/zrepl | 217 issues, ZFS needed. Not audited |
| colyseus/colyseus | endel 287-commit firehose, 7.3k★. Not audited |
| deepstreamIO/deepstream.io | earlier Requirement 7 death. Not audited |
| dmotz/trystero | no test workflow. Not audited |
| eljojo/rememory | Shamir, crypto nameable. Not audited |
| janbjorge/pgqueuer, rulego/rulego | solo firehoses. Not audited |
| leonchen83/redis-replicator | RDB format lanes. Not audited |
| rtic-rs/rtic | embedded, red Build. Not audited |

## Lane audits (5 agents plus the hunter)

| Repo | Verdict | Best lane / killing gate |
|---|---|---|
| **topfreegames/pitaya** | **VIABLE, RANK 1** | P1 session resume and handover, **written 303** (same-frontend half alone 184). P2 ordered dispatch is #179 (maintainer "must implement"). P3 backend presence is #382. P4 circuit breaker is maintainer roadmap #100. P5 disconnect-cancel is absorbed (~90-120) |
| runabol/tork | VIABLE, fallback 1 | Job concurrency groups, **written 256 whitespace-ignored** (339 with gofmt realignment churn). Pause/resume is declined in #264. Worker cordon is open PR #639. Task result caching was not sketched |
| olric-data/olric | VIABLE (marginal), fallback 2 | DMap tombstones, **written 229**. Caveat: master's test workflow has been red since 08-16 (TestClusterClient_smartPick, TestRoutingTable_LeftOverData, an internal/server timeout). internal/dmap passed in those runs, so base mode must scope. Fencing is absorbed (~120). Replica heal (#55), key events (#273), rolling handoff (#276) and hot keys (#194) are tracker-named or on maintainer branches |
| tobymao/saq | WEAK-to-VIABLE, fallback 3 | Job output streams, **written 226** (about 10 of it is the cursor lever). The reading surface is only ~3 KLOC, a sequence-length risk. Redis and postgres are both needed. depends_on (#96) is declined; per-function limits (#183) are declined |
| coleifer/huey | DEAD (repo) | Signature burst: zhechen-cs #919-#921 on 10-13, plus Kuang-xianxin, uttam12331 and tonyzedginidze |
| orbitinghail/graft | DEAD (repo) | Requirement 5: zstd-sys is load-bearing in the core crate, and ring is pulled in. The logical-misha in-lane burst (#322-#324) and a maintainer roadmap tracker add to it |
| remotestorage/remotestorage.js | DEAD | Conflict resolution has a removal record (0.9.0). Cache eviction written at 108. Orphan push recovery written at 37. #1170, #873 and #858 are tracker-named |
| centrifugal/centrifuge | DEAD | FZambia is running an agent-assisted recovery/history sweep (5 PRs in 60 days). #518 (maintainer), #335 and #20 are tracker-named. Keyed compaction is absorbed by MapBroker |
| gazette/core | DEAD | Tests exec an etcd binary. Every lane is absorbed (recorder truncate ~40-70, standby promotion, txn abort, fork #429) or a maintainer roadmap issue (#232, #237, #236, #265) |
| pufferpanel/pufferpanel | DEAD | Transfer #983, offline queue #1489, backups #1466/#1414, template upgrade #1179 and suspension #308 are tracker-named. Per-path grants written at 170 (independent guards, fails Q2). Incremental backups are blocked by an unassigned `backupServer` at HEAD (servers/server.go:38). Revisit once upstream fixes it |
| tqwewe/kameo | DEAD | The maintainer is rewriting remote (#373, #376, #380). Supervision is lane-dense. Message-queue acks are an AMQP port. Discussion #336 is a maintainer roadmap |

## RANK 1 dossier: topfreegames/pitaya, session resume and cross-frontend handover

**Repo facts**
- **Repo:** MIT (LICENSE read; xk6-pitaya also MIT), Go, ★2836.
- **HEAD:** f3d0af570f76e2608aee35900dcea20015b36978 (2026-10-07). Module `github.com/topfreegames/pitaya/v3`, library under `pkg/`.
- **Activity:** real code commits in the last 12 months: zlib writer reuse 10-05, NATS nil-msg guard and channel metrics 06-09, IsReady 01-16, lame duck mode 2025-11.
- **Requirement 7:** "Tests" (unit plus NATS/gRPC e2e) green on main 10-07 and 10-01. One failure on 06-09 was followed by a same-day success (a flake).
- **Signature accounts:** none in the lane. murraywu (#486/#489, docs) is a note and is now in `sig_accounts.txt`.
- **Submissions (ours):** 0.

**Exclusivity and tracker**
- All 29 open PR file lists were enumerated. #372 and #350 touch `session.Close` (sync.Once idempotence): same file, different capability.
- PR #465 "Implement Lame duck reconnection" (closed) was read as a 37-commit diff. It is a v2 backport bundle (NATS reconnect, drain, etcd), with no client session resume.
- The branches `session_fixes`, `session_fixes_2` and `fix/session-by-uid-leak` are 2023-2025 bug fixes. `lame_duck_reconnection` is NATS-side.
- Independent tracker searches by the hunter (reconnect, resume, reconnection, session recovery, restore session, session persistence, handover, offline) return no request for client session resume.
- **Sibling cribs:** nano has a 5-line `Session.Restore` setter. cherry, leaf and origin only redial. libpitaya redials with a fresh handshake. The Go socket.io port has protocol-level connection state recovery but none of pitaya's walls.

**Outsider summary (dedupe sentence):** "Adds reconnect-with-session-resume to the Pitaya game-server framework: a client that reconnects within a configured window, to the same or another frontend, presents a resume token and gets its bound session (uid, data) back, plus the pushes and responses sent while it was offline."
- Outsider-nameable: MEDIUM (Socket.IO connection state recovery, Colyseus allowReconnection).
- Mitigation: phrase meta.md on pitaya's own model (agent teardown paths, binding storage, unique session, NATS user subscriptions, `sys` remotes). No issue asks for it.

**Sketch:** `sketch_pitaya_session-resume_h69.patch`
- 10 files, raw 430, **human-effective 303**, padding-floor 96 (the bulk is lock/unlock bookkeeping in `session.go`, 190 eff).
- Leanest passer ~260. The same-frontend half alone is 184 and would be dead. The cross-frontend handover is what carries the lane: a `sys.handoversession` remote, `RemoteService.ResumeFromFrontend`, and pool `Handover`/`Continue`.
- Session and agent mocks must be regenerated (generated files, not counted).

**Traps (base file:line)**
1. **Three teardown paths share one decision (F-41, F-20).** The read loop (`service/handler.go:208`), the heartbeat timeout (`agent/agent.go:467-472`) and a write error (`agent.go:529-532`) all reach `agent.Close`. So do Kick (`session/session.go:489-494`), duplicate Bind (`:462`) and CloseAll (`:288`).
2. **Close side effects must wait for finalize, then run exactly once (F-19, F-14).** These are the NATS user subscription drain (`session.go:523`) and the binding-storage delete in a close callback (`modules/binding_storage.go:94-97`).
3. **Handover must skip A's close callbacks but still drain A's subscription (F-19, F-88).** `binding_storage.go:75` deletes by uid, so it would delete B's binding. `modules/unique_session.go:55,64` is involved too. The obvious trap-2 fix breaks this one.
4. **Held pushes and in-flight responses must be portable and ordered after HandshakeAck (F-47).** See `handler.go:298,381` and `remote.go:127`.
5. **Identity bookkeeping (F-58, F-59).** Every connection counts a fresh session (`agent.go:220`), and that must not leak or CloseAll never ends. The handshake response is a global computed once (`agent.go:196`, `once.Do`), so it cannot carry a per-session token.

**Gate 1 (argued from code; runtime probe OWED):** `HandshakeClientData` has no resume field and the handshake response has no token. A reconnecting client gets a new session with no uid or data:
- pushes during the gap fail with `ErrPushingToUsers` (`push.go:47-66`) or `ErrSessionNotFound` (`remote.go:206-219`);
- a response that finishes during the gap is lost;
- `OnSessionClose` fires immediately.

**Stage 6 guard (run by the hunter on the agent's evidence)**
- **Q1, shared kernel:** YES. The pool's detach/hold/finalize/handover state machine is fed by three teardowns, local and NATS pushes, in-flight responses, local, remote and unique-session Kick, duplicate Bind, CloseAll/drain, the binding-storage callback and the cross-frontend RPC.
- **Q2, interdependent traps:** YES. Where trap 1's decision lives decides whether kicks detach. Trap 2's finalize is wrong for trap 3's handover. Trap 4 rides trap 1's session. Trap 5 couples to CloseAll.
- **Q3, standalone file:** NO, so no waiver is needed. The lane edits 10 files across 7 packages.
- **Q4, TOO-EASY Pre-Pick Guard:** it is not membership/validation, not a mechanical transform, not misdirection-only, not a uniform wrap and not a spec port, and its walls survive being stated in full. **PASS.**
- **Watch item:** a solver who puts `Release` inside `agent.Close` finds a chokepoint fast. Smoke the same-frontend half first, and keep the cross-frontend cells as the separator.

**Tests and Docker**
- `go test ./pkg/...` (testify plus gomock). A new `pkg/session_resume_<hash>_test.go` can drive everything through public APIs:
  - same-frontend: `NewBuilder` with a TCP acceptor on `:0`, plus `pkg/client` in standalone mode;
  - cross-frontend: two frontend Apps on the embedded etcd (`helpers.GetTestEtcd`) and embedded gnatsd (`helpers.GetTestNatsServer`), following the app_test.go:295-330 pattern.
- No cgo and no external service: olympus-base-go plus `go mod download`.
- **OWED:** confirm two Apps coexist in one process. The shared globals are the timer, the `once` handshake response and prometheus registration.
- **OWED:** run the suite 3x for flakiness. There is history: #328, #82, the 06-09 CI flake.

**Reading surface:** ~10 KLOC Go (session 1.1k, agent 0.95k, service 1.25k, cluster NATS/etcd 2.5k, modules 0.58k, client 1.0k, config 0.87k, app/builder ~1.5k).

## Fallbacks
1. **runabol/tork, job concurrency groups** (`dossier_tork_h69.md`)
   - Capability: `concurrency {key, limit}` on jobs and scheduled jobs, a new QUEUED state, FIFO by `queued_at`, release on every terminal exit, and a queued RESTART that resumes at its position.
   - Written 256 (whitespace-ignored) over 12 files; the admission/release kernel is 100.
   - Traps: F-14 exits including completion-time output failure; F-9 restart resume point; F-10 restart x queue order; cancel of a QUEUED job; holder states SCHEDULED+RUNNING; F-9 scheduled-instance copy site.
   - Tracker clean: all 68 issue bodies and 418 comments grepped.
   - Docker: needs a PostgreSQL server in the image, started as the postgres user when graded as root. The runtime/shell timeout must be excluded from base mode.
   - Outsider-nameable: MEDIUM (GitHub Actions concurrency).
   - Second lever, named: a cancel-in-progress supersede policy.
2. **olric-data/olric, DMap tombstones** (`dossier_olric_h69.md`)
   - Written 229 over 18 files.
   - Seven traps across the balancer, read repair, the PUTENTRY partition kind, eviction and the delete early return.
   - Outsider-nameable (Dynamo/Cassandra).
   - Caveat: the red master test workflow sits next to the routing table.
3. **tobymao/saq, job output streams** (`dossier_saq_h69.md`)
   - Written 226 over 7 files.
   - Seven traps around a per-attempt stream header.
   - Small reading surface; needs redis plus postgres in Docker.

## Side findings
- **New signature accounts added to `sig_accounts.txt`:**
  - logical-misha (graft burst #322-#324, 10 seconds apart, push/sync lane; also systemd, util-linux, neon, etcd, ray, runc, nginx);
  - murraywu (26 "comprehensive guide" docs PRs across niche repos in April 2026);
  - zhechen-cs (huey burst on 10-13; apscheduler, celery, rq, faststream, aio-pika, nats, quix-streams);
  - tonyzedginidze (task-queue forks);
  - Kuang-xianxin (profiled 09-23-K, now listed).
- **pufferpanel** has a richer two-process lane (incremental backups with a protocol field and two in-repo walls: basename archive entries and `skipRoot` on extract). It is blocked only by the broken `backupServer` at HEAD. Re-audit it when upstream assigns it again.
- **Process note:** the olric agent ran `go vet ./internal/dmap` once, against the brief. Its result was not used.

## Submission counts (warning only)
pitaya 0, tork 0, olric 0, saq 0, and 0 on every other audited repo.

## Verdict rows
`judged.tsv`: 21 rows appended (backup `s_1016h69/judged.bak_h69`).
- **Repo-scope (2):**
  - huey: signature burst;
  - graft: Requirement 5.
- **Lane-scope:**
  - pitaya: candidate, plus 4 dead lanes;
  - tork: fallback, plus 3 dead lanes;
  - olric: fallback, plus 5 dead lanes;
  - saq: fallback, plus 5 dead lanes;
  - the dead lanes of remotestorage.js, centrifuge, gazette, pufferpanel and kameo;
  - six screen-only corpses.

## What the next hunt should change
1. **The two-process topic lens works.** It returned 4 lanes at 226-303 from 11 audits, where #66-#68 returned none. Its 368 never-judged rows are only partly spent: about 20 screened-but-unaudited engines are listed above (redun, PySyncObj, evennia, colyseus, rulego, pgqueuer, zrepl, ...). Audit those next, or run the same lens on more two-process topics (e.g. `sync`, `crdt-sync`, `queue`, `worker`, `matchmaking`, `realtime`).
2. **Keep the cross-process half when sizing.** On pitaya the same-process half wrote 184 and only the cross-frontend handover carried the lane past 220. On tork the admission/release kernel only clears the bar because it spans several handlers plus the datastore.
3. **Re-check neva after 2026-10-20,** and re-audit any proven repo the day its in-flight lane is accepted.
