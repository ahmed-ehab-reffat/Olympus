# REPO-HUNT-2026-10-16-C (hunter #70, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **CANDIDATE weyoss/redis-smq, single active consumer with standby handover** (written sketch 239 human-effective over 14 files; core without the takeover event 215).

Two lanes cleared the 220 written bar:
- redis-smq single active consumer + standby handover, 239
- anycable cluster-wide per-identifier session cap (evict/reject), 230 (lean core ~210)

Scratch: `worktrees/_hunt/s_1016h70/` (~32M after cleanup, nothing built, no `target/`, no `node_modules`). It holds:
- the brief `AGENT_BRIEF_h70.md` (h70 block on top of the h69 brief);
- sweep 1: `topics_h70.txt` (50 topics), `topic_raw_h70.tsv` (487 rows), `unj_h70.tsv` (333 never-judged, unseen rows);
- sweep 2: `topics2_h70.txt` (39 topics), `topic2_raw_h70.tsv` (215), `unj2_h70.tsv` (166);
- the screener `mech_h70.sh`, output `mechall_h70.out` (42 repos) and `mech2_h70.out` (8 repos);
- dossiers `dossier_{redis-smq,anycable,node-resque,pgqueuer,tasktiger,pg-boss,worker,apalis,due,colyseus,evolu,yaos,hocuspocus,rulego,process-compose}_h70.md`;
- sketches `sketch_redis-smq_single-active-consumer_h70.patch` (239), `sketch_anycable_sessions_limit_h70.patch` (230), `sketch_apalis_graph-route-skip_h70.patch` (110), `sketch_tasktiger_cancel_h70.patch` (83);
- issue dumps per repo; backups `judged.bak_h70`, `sig_accounts.bak_h70`.

Clones kept (VIABLE lanes only): `s_1016h70/redis-smq` (18M, sketch not applied), `s_1016h70/anycable` (4.2M). Every other clone was deleted.

Disk `/`: 8.0G free at the start, 7.9G at the end. This hunt built nothing.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):** a LEDGER row excludes only its own lane; only repo-scope verdicts block a repo; star margin ~505; return bar 220 written; Q3 waiver only above ~300 with an internal wall; submission count reported, never gated.
- **Not relaxed:** maintainer-roadmap magnet rule; AI-sweep, velocity and signature rules; the 2026-10-13 tracker-named-lane rule.
- **Softening:** none (misses = 0). Two distinct signature accounts on a repo, a signature PR in the lane, or a burst (>= 3 in a week) killed the repo; one visit outside the lane was a note. The star window for the topic sweeps was 500-8,000 (same as #69; not a relaxation of the floor).
- **Requirement 0:** OWED (the human checks the picker).
- **Excluded lanes:** pitaya session resume (HUNTED by #69, and the session-resume class on every game-server framework), tork concurrency groups, olric tombstones, saq job streams (the #69 fallbacks), Cwerg compact unions, allsorts, micasa blob reclaim, qq, pint, commafeed, aptly, ray-optics module inlining, eventsourcing, mirrorbits, every CLAIMED row, the platform-dead lanes.
- **Defaults taken unasked:**
  - **Proven pool not re-audited.** #69 ran the same check this morning: every pool repo's newest lane verdict is under 60 days old except pulldown-cmark (signature-dead) and lifelines (expires 10-19). No acceptance landed since.
  - **#69's fallbacks (tork 256, olric 229, saq 226) were not returned.** redis-smq is a fresh repo with a lane at 239 whose walls come from its own Lua staging lists; tork stays recorded on the pitaya row as before.
  - **The go-feature-flag audit was cut off** by an API session limit before it reported. No verdict was written for it, so it stays unjudged and gets screened again.
  - **Lane audits ran as ten parallel agents** (one to three repos each); the hunter re-measured both viable sketches with the hook and re-ran the redis-smq tracker search himself.

## Stage 0-bis: proven pool
Nothing usable (see defaults). Pool counts (warning only): redis-smq 0, anycable 0, and 0 on every audited repo.

## Cached index: #69's never-judged two-process rows
#69's `unj_h69.tsv` (368 rows) had ~20 screened-but-unaudited engines and a long tail it dropped by eye. Re-triaged by eye for two-process engines with a repo-owned protocol (job queues, game-server frameworks, local-first sync, raft/replication, workflow, MQTT, actors): 34 rows went to the mechanical screen with 8 rows from sweep 1.

## Fresh sweep 1 (of 2): more two-process topics
- Topics (50, none used before): queue, worker, sync, websocket, realtime, collaborative-editing, p2p, webhooks, outbox, saga, stream-processing, rpc, json-rpc, tunnel, distributed-cache, oplog, changefeed, mmo, mmorpg, mud, matchmaking, presence, chat, irc, matrix, nostr, smtp, imap, caldav, carddav, webdav, sftp, bittorrent, torrent, swim, membership, anti-entropy, vector-clock, hlc, rate-limiter, circuit-breaker, idempotency, exactly-once, sse, server-sent-events, event-bus, cqrs, orchestration, lease, remote-desktop.
- Funnel: 487 rows at 500-8,000★, permissive, in-scope language, pushed in 12 months; 333 never judged and not shown by #69. By eye, 8 went to the screen (hocuspocus, yaos, pg-boss, arq, tasktiger, anycable, ergo, process-compose); the rest were famous infra, protocol/spec libraries (websocket, SMTP/IMAP, nostr, MQTT), AI-agent repos, GitHub Actions, or single-process tools.

## Fresh sweep 2 (of 2): CI / build / fleet two-process topics
- Topics (39): ci, continuous-integration, ci-runner, runner, remote-execution, remote-cache, distributed-build, build-cache, binary-cache, build-farm, artifact-repository, package-registry, git-server, gitops, fleet-management, device-management, iot-platform, telemetry, log-shipping, log-collector, metrics-collector, remote-control, remote-access, provisioning, configuration-management, deployment-tool, release-management, canary, feature-flags, experimentation, secrets-management, certificate-management, acme, dns-server, dhcp, tftp, pxe, netboot.
- Funnel: 215 rows, 166 never judged. 8 screened (go-feature-flag, komari, buildkite/agent, centraldogma, ovh/cds, abstruse, pipecd, buildfarm). Only go-feature-flag went to audit (cut off, see defaults). komari has only build/release workflows; cds has no workflows; abstruse is a corpse; centraldogma CI is red on main; buildkite/agent tests run off GitHub and its API side is closed; pipecd is a team + student-PR firehose; buildfarm is Bazel-built.

## Mechanical screen (50 repos), dropped before audit

| Repo | Screen reading |
|---|---|
| procrastinate-org/procrastinate | **repo-dead:** two signature accounts (Sanjays2402 #1605, tonyzedginidze #1641) |
| evennia/evennia | **repo-dead:** Sanjays2402 burst x3 on 2026-07-25 |
| wakatime/wakaq, cherry-game/cherry | **repo-dead:** Requirement 7, no test workflow |
| jcubic/sysend | corpse, no workflow |
| lonng/nano, xiaonanln/goworld, davyxu/cellnet | corpses (0-1 commits/12mo) |
| python-arq/arq, node-pinus/pinus, openmessaging/dledger, bergercookie/syncall, webtorrent/bittorrent-tracker, DrmagicE/gmqtt | dormant with filling PR queues or renovate-only |
| resonatehq/resonate, hookdeck/outpost | repo-wide AI authoring (190 commits by `claude`; 131 AI trailers + claude.yml) |
| fastly/pushpin | C++ 45% with ZeroMQ (Requirement 5 risk) |
| ergochat/ergo, moscajs/aedes | IRCv3 / MQTT spec lanes, signature visits |
| insitro/redun, RSamaium/RPG-JS, maxnowack/signaldb | heavy AI trailers (54 / 79 / 70) |
| bakwc/PySyncObj, tidwall/uhaha | Raft textbook |
| Dancode-188/synckit, jodal/pykka, bytewax/bytewax | multi-language / single-process / PyO3 build; deprioritised |

## Lane audits (10 agents)

| Repo | Verdict | Best lane / killing gate |
|---|---|---|
| **weyoss/redis-smq** | **VIABLE, RANK 1** | Single active consumer + standby handover, **written 239**. Message groups #106, publish dedup #92, size limit #74 are tracker-named; lease extension and request-reply absorbed |
| anycable/anycable | VIABLE (thin), fallback 1 | Cluster-wide per-identifier session cap, **written 230** (lean ~210). Presence and slow drain are documented Pro features; PR #329 (Codex) has a Redis presence broker; PR #306 Postgres signalling; presence/Pusher webhooks "planned" in docs |
| actionhero/node-resque | DEAD | Dead-worker recovery absorbed (forceCleanWorker/retryStuckJobs); #275, #334, #130, #277 tracker-named; resque-compat port shape |
| janbjorge/pgqueuer | DEAD | ADR-0004 rejects fencing; stall budget pointed by PR #642 + reliability.md (~130 paper); per-entrypoint rate limit and lease are v1.0 removal records |
| closeio/tasktiger | DEAD | Cross-worker cancel written **83** (the `_move` Lua + heartbeat kill absorb it); chains #161 + open PR #370, priority #96 |
| timgit/pg-boss | DEAD | #152 / #247 / #238 philosophy; #306 sticky routing and #551 pause tracker-named; leases, cancel, stop handback absorbed |
| graphile/worker | DEAD | #222: worker tracking is Worker Pro (philosophy); #279, #112, #118, #458, #546 tracker-named |
| apalis-dev/apalis | DEAD | GraphFlow route/skip written **110**; leases #504/#448, cancel #123, partition keys #718 tracker-named |
| dobyte/due | DEAD | Maintainer's `.harness/notes/architecture.md` (AI-assisted) names every two-process gap as roadmap or business-owned; #79, #3, #47, #32, #59 tracker-named; a migration state machine is published (§14.3) |
| colyseus/colyseus | **DEAD (repo)** | fatihcvs burst x6 (#969-#974, 2026-09-20) + Nacl-HCl #987; lanes also dead (#341 philosophy, #785/#155/#508/#876 tracker-named, lobby ghost listings <200). The matchmaker is a module singleton, so two servers cannot share one test process |
| evoluhq/evolu | DEAD | Every client+relay lane is an EEP / #506 backlog / open issue, or a removal record (WriteKey rotation, owner reset); maintainer `claude/*` branch sweep on the sync code |
| kavinsood/yaos | DEAD | main is legacy; the client-remake branch and merged PR #82 server rewrite carry a numbered DECISIONS.md plan covering revocation, quotas and epochs; #3 sharding RFC |
| ueberdosis/hocuspocus | **DEAD (repo)** | whoalin1 burst x7 in 4 days (#1174-#1187) + breken-ai, wanjinhao1, helenanova |
| rulego/rulego | DEAD | Stateless by design (#1, #37 declined clustering); join ordering rewritten 10-08..10-14; #22, #119 implemented |
| F1bonacc1/process-compose | **DEAD (repo)** | Three signature accounts (vulragrag-star in the readiness lane #546, bensynapse #559, jihtsan #569) |

## RANK 1 dossier: weyoss/redis-smq, single active consumer with standby handover

**Repo facts**
- **Repo:** MIT (LICENSE read; no vendored third-party source), TypeScript 80% / Vue 15% / Lua 3%, ★670 (> 505 margin). Monorepo (pnpm/lerna): core `packages/redis-smq` (~39 KLOC TS + Lua), `packages/redis-smq-common` (~11 KLOC: lock, heartbeat, worker cluster, embedded valkey server).
- **HEAD (default branch `next`):** 9620d66411ba4a241ab83d0a5953d4de07844408 (2026-10-12).
- **Activity:** 300 commits/12mo, weyoss 298 (solo). 90-day consumer/scripts subjects (handler-config fix, hash-layout refactor, public API contracts) are outside the lane. AI trailers 0.
- **Requirement 7:** `ci`, `code quality`, `release` green on `next`.
- **Signature accounts:** none from the list. katsugtgz (scattershot, 224 repos) has one closed dep-bump PR #143 in web-ui, outside the lane: a note, now added to `sig_accounts.txt`.
- **Open PRs:** 0. Non-bot PRs ever: 9, none in any lane. Branches: master, next.
- **Submissions (ours):** 0.

**Exclusivity and tracker**
- 102 issues, 19 discussions dumped and grepped by body. Hunter re-ran `gh search issues` for "single active", "exclusive consumer", "only one consumer", "one consumer at a time", "standby", "failover", "ordered", "order guarantee", "sequential": no hit asks for the capability (hits are #100 lock error, #75, #110 reliable pub/sub, #6, #57 redis failover, #79 article).
- CHANGELOG and docs grep for single-active/exclusive/standby: no removal record; the only "exclusive" hits are queue operational states and WorkerCluster locks.
- **Sibling crib:** BullMQ / Bull / bee-queue have no single-active consumer; BullMQ global concurrency caps parallelism with no ownership, handover or ordering across retries (adjacent, not a crib).

**Outsider summary (dedupe sentence):** "Let a redis-smq queue (or one consumer group of a pub/sub queue) deliver to only one consumer at a time while the other subscribed consumers wait as standbys, keeping delivery in order across retries and across handover from a crashed or departing active consumer."
- Outsider-nameable: MEDIUM (RabbitMQ single active consumer). No long-open issue asks for it and it is not a port (RabbitMQ's lives inside its Erlang broker). Mitigation: phrase meta.md on redis-smq's own model (requeued list, delayed set, reaper, consumer groups, processing lists).
- Adjacent derivative risk: a rival "message groups" task (#106) would touch the same dequeue files. Different capability (queue-level ownership and handover, no group key on messages).

**Sketch:** `s_1016h70/sketch_redis-smq_single-active-consumer_h70.patch`
- 14 files, raw 278, **human-effective 239** (re-measured by the hunter), padding-floor 93 (wrapped TS call lines; the depth is the Lua gate, 78 eff).
- Core 215; the second lever, written in, is a distributed `consumer.activeConsumerChanged` (consumerId, previousConsumerId|null, queue) event fired once per takeover.
- Pieces: `SINGLE_ACTIVE_CONSUMER` queue property + `IQueueProperties` field + parser case (base parser PanicErrors on unknown properties, `_get-queue-properties.ts:87`); `QueueManager.setSingleActiveConsumer` (refuses while consumers are subscribed); an `active` key per consumer-group path; `dequeue-single-active.lua` (claim / STANDBY / BLOCKED / pop for FIFO, LIFO, priority); a DequeueMessage branch on the non-blocking path polling on the existing 1 s timer (`message-handler.ts:181`); release in `unsubscribe-consumer.lua` (graceful shutdown and the reaper both go through it); delete-queue cleanup.
- Unchecked: no tsc / luac run (no-build rule). Chokepoint watch: the reference concentrates in one Lua gate; the builder's spike must still clear 200.

**Traps (base file:line)**
1. **T1 staged retry (F-88-like staging window, F-9).** A failed message goes to the queue-wide requeued list (`unacknowledge-message.lua:160`) or the delayed zset when retryDelay > 0 (`queue.ts:44-45`), and a background worker on the lock holder moves it back later (`requeue-immediate.lua:162`). An election-only design delivers N+1 while N is staged; the failing test shows "wrong order", not the staging list.
2. **T2 handover before recovery (F-15, F-79).** ReapConsumersWorker unacks the dead consumer's messages (`reap-consumers.worker.ts:85`) and only then unsubscribes it (`:108`). A standby that claims on heartbeat expiry alone pops N+1 before N is recovered; the gate must also wait for the dead holder's processing list.
3. **T3 queue-wide staging keys (F-11, F-28).** Requeued/delayed keys and property counters are per queue, not per consumer group; a "block while anything is staged" fix makes pub/sub group A wait on group B's retries, so staged ids must be filtered by consumerGroupId.
4. **T4 second dequeue path + batched acks (F-67, F-41).** A standby already parked in BRPOPLPUSH on its exclusive connection (`dequeue-message.ts:145`) steals the next message; batched acks leave ids in the consumer's processing list until flush, so "own processing list empty" is part of the gate.
- Interlock: recovering the dead holder's messages yourself (T2) routes N into the requeued list (T1); a queue-wide emptiness check (T1) breaks consumer groups (T3); the reaper and graceful release share `unsubscribe-consumer.lua`.

**Gate 1 (argued from code; runtime probe OWED):** every subscribed consumer pops independently (`dequeue-message.ts:134-160`, brpoplpush / rpoplpush / zpoplpush), so two consumers on one FIFO queue both receive messages and N+1 can run while N is in flight; there is no property or setter to restrict it. Observable through handled-body order, which consumer receives, and the takeover event; the new API fails to compile on base.

**Stage 6 guard (run by the hunter)**
- **Q1, shared kernel:** YES. One gate serves point-to-point and every pub/sub group, FIFO/LIFO/priority, blocking and multiplexed handlers, immediate and delayed retry, crash recovery; one release is shared by cancel, shutdown and reaper.
- **Q2, interdependent traps:** YES (interlock above).
- **Q3, standalone file:** NO. The lane needs the dequeue path, the unsubscribe Lua, the panicking property parser, QueueManager, the key schema and the event contract. No waiver needed.
- **Q4, TOO-EASY Pre-Pick Guard:** (1) four distinct structures, not one guard at many sites; (2) cross-subsystem and cross-process; (3) the walls survive being stated (the meta states the ordering promise; the staging lists and reaper order stay hidden in code); (4) not a port; (5) yes. **PASS.**

**Tests and Docker**
- vitest (forks pool) over `dist/esm` after `pnpm build` (tsc), via `scripts/test_workspace_esm.sh`. A new `tests/integration/consuming/*.test.ts` drives two consumers in one process through public APIs; `tests/helpers/scenarios/crash-consumer.ts` already forks and SIGKILLs a consumer for the crash half.
- Service: per-worker embedded valkey-server from redis-smq-common, a prebuilt binary downloaded from github.com/weyoss/valkey releases at setup (`redis-binary.ts`). Pre-populate the cache in the Dockerfile so tests run offline (or point the config at an apt redis-server).
- **OWED:** flakiness 3-5x (heartbeat/reaper timing); prefer graceful-handover cells plus wait-for-condition on the crash cells.
- **Reading surface:** ~10 KLOC over ~40 files (consumer/ ~4.5k, common/scripts Lua ~2.5k, queue-manager ~1.2k, event-bus contracts, common lock/heartbeat/worker-cluster ~2k).

## Fallbacks
1. **anycable/anycable, cluster-wide per-identifier session cap** (`dossier_anycable_h70.md`, clone `s_1016h70/anycable`, HEAD ccdf58cfe49648c384ec905a097d84453e93d760)
   - MIT (vendorlib/go-mruby also MIT; mruby only under the `mrb` tag, so test.sh runs `go test` with no tags). ★2389, palkan 121 of 155 commits; Test green; no signature accounts; open PR #306 only.
   - `max_sessions_per_identifier` + `sessions_limit_policy` (evict | reject); broker `TrackSession`/`UntrackSession` for memory, legacy and NATS (own KV bucket, no TTL, compare-and-set); hooks at authenticate, restore and disconnect; eviction on the remote disconnect command with new `sid`/`reason` fields; sid-targeted hub disconnect.
   - **Written 230** (raw 407, 8 files); lean core ~210 (CLI/TOML/metrics ~20). Second lever (reject policy) written in.
   - Traps: TryRestoreSession bypasses Authenticated (`node/node.go:417-478`); evicted sessions come back from the sessions cache via `?sid=` (`broker/memory.go:441-475`, `broker/nats.go:387-430`); `hub.disconnectSessions` closes only one session per identifier (`hub/hub.go:312-336`); the natural KV bucket has TTL = sessions_ttl (`broker/nats.go:223`); eviction must send reconnect=false.
   - Tests: two Nodes in one go test process over the existing embedded NATS helper (`node/broker_integration_test.go:665`); no external service.
   - Risks: thin margin; Pre-Pick Guard 3 risk (meta must state restored sessions count, evicted sessions cannot restore, no reconnect); outsider-adjacent (Centrifuge `UserConnectionLimit`, per-node, reject-only).
2. #69's fallbacks stay as recorded on the pitaya row: tork concurrency groups 256, olric tombstones 229, saq job streams 226.

## Side findings
- **Signature accounts added to `sig_accounts.txt`** (backup `s_1016h70/sig_accounts.bak_h70`): Nacl-HCl, fatihcvs (6-PR burst on colyseus), carfeii, whoalin1 (7-PR burst on hocuspocus, 145 PRs since Aug), vulragrag-star, bensynapse (also on JFryy/qq and pgqueuer), jihtsan, wanjinhao1, helenanova, theluckystrike, katsugtgz.
- **Since August 2026 a wave of scattershot accounts is sweeping two-process TS/Go infrastructure** (hocuspocus, process-compose, colyseus, pgqueuer). Expect more repo-level signature deaths in this lens.
- **Job-queue lanes:** on mature queues (pgqueuer, tasktiger, pg-boss, node-resque) the stale-recovery state machine already has every lever; crash-recovery lanes wrote 83 or priced ~100-130. Two repos put worker tracking behind a paid tier (graphile Worker Pro) or reject it in an ADR (pgqueuer ADR-0004). The surviving queue lane (redis-smq) adds a new ownership structure rather than recovery.
- **Maintainer roadmap documents** killed whole repos: due's `.harness/notes/architecture.md`, yaos's `DECISIONS.md`, evolu's EEP issues and #506 backlog, anycable's "Pro"/"planned" docs. Read a repo's design/roadmap docs before inventing lanes.
- **Process note:** GitHub's search API hit its secondary limit several times with ten auditors in parallel; agents fell back to local dumps (`gh issue list` / GraphQL). The go-feature-flag auditor died on an API session limit.

## Submission counts (warning only)
redis-smq 0, anycable 0, and 0 on every other screened or audited repo.

## Verdict rows
`judged.tsv`: 42 rows appended (backup `s_1016h70/judged.bak_h70`).
- **Repo-scope (8):** procrastinate (two signature accounts), evennia (burst), wakaq and cherry (Requirement 7), sysend (corpse, no workflow), colyseus (burst), hocuspocus (burst), process-compose (three signature accounts).
- **Lane-scope:** redis-smq (candidate), anycable (fallback), the dead lanes of node-resque, pgqueuer, tasktiger, pg-boss, graphile/worker, apalis, due, evolu, yaos, rulego, and 20 screen-only notes.
- `used_topics.txt`: 89 topics added.

## What the next hunt should change
1. **The two-process lens is now mostly spent on job queues, game servers and local-first sync.** 15 audits returned two lanes; the rest died on signature waves, roadmap docs and absorbed recovery machinery. Next lens to try: two-process systems in a niche DOMAIN rather than generic infra (instrument control / lab automation servers, debug probes and gdbserver/DAP bridges like pyOCD, emulators with remote protocols, EDA/simulation co-simulation, robotics bridges), where the protocol is repo-owned and the rival wave has not arrived.
2. **Re-run the go-feature-flag audit** (relay proxy + in-repo providers; screen clean except ChrisJr404 x1); it was cut off before a verdict.
3. **Re-check neva after 2026-10-20** (from #69), and re-audit any proven repo the day its in-flight lane is accepted.
