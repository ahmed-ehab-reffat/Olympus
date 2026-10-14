# REPO-HUNT-2026-10-05-G (hunter #55, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1005h55/`:
- `AGENT_BRIEF_h55.md`: the h54 brief plus hunt #55 additions (the rejected-pool reading rule, no builds, honest chokepoint pricing with a stated leanest passer).
- `screen_pool_h55.txt`: mechanical screen of 10 rejected-pool repos.
- `commits_<owner>_<repo>_h55.txt`: 12-month commit samples.
- Dossiers: `dossier_dinit_h55.md`, `dossier_str0m_h55.md`, `dossier_capa_h55.md`, `dossier_alembic_h55.md`, `dossier_go-astisub_h55.md`.
- Raw evidence from the auditors: `issues_str0m_h55.txt`, `prs_str0m_h55.json`, `pr_authors_str0m_h55.txt`, `capa_*_h55.txt`.
- No clones kept. Nothing was built, no venv, no Docker.

## Standing inputs
- **Human direction (2026-10-05, standing):** second, different-subsystem lanes on repos we already worked, not broad discovery. Still enforced: quota, a subsystem disjoint from every earlier problem on the repo, fresh exclusivity / PR-DIFF / signature / activity / post-base checks, and the TOO-EASY dead classes (including history-rewrite / ledger-squash). Licence, language, activity, Requirement 7, exclusivity and quota were not relaxed.
- **Previous hint (hunter #54):** audit the rejected/ repos that screened clean, after first checking why our earlier pick there died. If it died to an older accepted task (derivative overlap, "done before") or a repo-level reason, the repo stays dead. If it died for a lane-level reason, a disjoint lane may be fine.
- **Excluded:** every ledger repo (teavm HUNTED, aptly SLICING, commafeed, gonum/plot and all CLAIMED/DEAD rows), every repo with a problems/ folder, the reserved fallbacks (pyOCD lane K, ray-optics), and SATURATED-REPOS sections A/C/D/E.
- **Softening:** misses = 1, so the 2026-09-09-B rules apply as written. No star or issue window was widened. Relaxations taken: none.
- **Requirement 0 (platform picker):** not checkable here. OWED for any future pick.
- **Disk:** `/` had 7.8G free throughout, under the 8G build gate, and a builder was running. No builds. Every Gate 1 below is argued from code.

## Stage 0-bis: classifying the rejected pool by why our pick died
I read every rejected/ folder in hunter #54's clean screen, plus the other rejected repos it did not list.

| Repo | Our pick, how it died | Repo status |
|---|---|---|
| m4b/goblin | chained-fixups: Scope Gate "narrower derivative of older accepted candidate" | DEAD (another author holds an accepted task) |
| dnsjava/dnsjava | atomic-ixfr: "already implemented before" | DEAD |
| salsa-rs/salsa | persisted-accumulators: "implemented before" | DEAD |
| image-rs/image-png | adam7-encoding: "already done" | DEAD |
| qax-os/excelize | structural-reference-adjustment: "done before" | DEAD |
| georust/geo | polygonize: similarity to archived submissions | DEAD |
| paulmach/orb | ring-role: derivative against 5 older subs | DEAD |
| Kozea/WeasyPrint | page-floats: overlap 61.4% + 40.6% against two foreign subs; also in the 5000+ star penalty band | DEAD |
| obi1kenobi/trustfall | SATURATED: exclusivity-dead at repo level | DEAD |
| gfx-rs/rspirv | Scope Gate publicly solved (SPIRV-Tools); TOO-EASY sibling-ecosystem class covers the whole format; default-branch CI failed 2026-08-14 | DEAD |
| restsend/rustpbx | two picks dead at prior-art/task-identity; 300 commits/12mo, 3 open issues | DEAD |
| opencontainers/umoci | forward-hardlinks: convergence scope (54 eff). Lane-level, BUT the scheduled `ci` workflow on main concludes `failure` 2026-09-09/10/11, and there has been no code commit since 2026-01-10 | DEAD (Requirement 7) |
| icedland/iced | pointer-data-dedup: under floor. Lane-level, BUT 12 months show only dependabot merges and two dep-bump commits | DEAD (Requirement 6, corpse) |
| PMEAL/OpenPNM | robin-bc: too easy. SATURATED B-ledger: imbibition dead (v2.8.2 prior art), residual-NWP dead (commented-out implementation), transport has 4 open PRs, `models/` is pattern-followable | DEAD (all lanes priced earlier) |
| tdewolff/canvas | fill-rule: under floor. SATURATED: red baseline (Requirement 7) | DEAD |
| DioxusLabs/taffy | three picks short; 50 open PRs | DEAD |
| vivisect/vivisect | noret: unsolvable under review. 09-23-J verdict WEAK (maintainer WIP PRs hold PDB/DWARF/CLR/codeflow/pointers/C structs) | not re-audited |
| **davmac314/dinit** | depends-any: machinery-absorbed, under floor (lane-level) | **audited** |
| **algesten/str0m** | remote-renegotiation: too easy 10/10 (lane-level) | **audited** |
| **mandiant/capa** | process-tree scope: absorbed, under floor (lane-level) | **audited** (5000+ star penalty) |
| **sqlalchemy/alembic** | acyclic-stitching: released upstream (lane-level) | **audited** |
| **asticode/go-astisub** | merge-collisions: too easy 4/4 (lane-level) | **audited** |

## Lane audits: 5 repos by 4 parallel subagents (brief `AGENT_BRIEF_h55.md`)
| Repo (dead lane) | Verdict | Best lane, and what killed it |
|---|---|---|
| davmac314/dinit (dependency kinds) | **WEAK** | Named service commands (`service-command = name signal SIG / command ...`, control command, dinitctl, dinit-check). See note 1 |
| algesten/str0m (SDP negotiation) | DEAD | Per-stream TWCC delivery ledger. See note 2 |
| mandiant/capa (dynamic scopes) | DEAD | Minimal match evidence. See note 3 |
| sqlalchemy/alembic (revision graph) | DEAD | Offline SQLite batch via schema shadow. See note 4 |
| asticode/go-astisub (merge) | DEAD | TTML timing tree. See note 5 |

**Notes:**
1. **dinit.** HEAD `40da57f246a6391f2f97b0b90c60a35df226419e`.
   - The service-command syntax is davmac314's own, from Discussion #178: "would be reasonable ... I don't at this stage plan to implement this myself". Exclusivity is clean (all 249 PRs). There are no signature accounts; mobin-2008 is the co-maintainer.
   - Reference sketch ~270 eff, leanest ~135-180. `start_stop_process` (proc-service.cc:914-1007) and `process_signal` (PR #176) are complete in-repo oracles for launch and dispatch.
   - Invented coupled levers would bring the leanest to ~200, but push meta to ~250-300 words: (a) runtime-only variables that load-time substitution must leave intact (F-9), and (b) a FIFO action queue cancelled on stop.
   - Magnet YELLOW-RED: "reload" is famous, D178 is public, and q66 asked for reload-signal on #176.
   - The maintainer declared a feature freeze until 1.0 (NEWS:98). The adjacent process-watch code is hot (`origin/development` 401663b, 2026-10-03).
   - Other lanes, all dead: start-concurrency limit (console-queue oracle, ~100, sits next to the dead kernel), all-input modified detection (#403 deliberate choice), scrolling log #315, read-only control #431 (q66's design), multi-producer logger (~120-150), multiple env-file #540 (public NixNG patch), stdout/stderr split #247, deferred reload (#426 declined), timers #115 (published design).
2. **str0m.** HEAD `393a3d238aa466ba9edc52fba823f86563642c20`.
   - Requirement 7 passes once the run list is filtered by `headBranch=main` (`--branch main` returned stale April rows).
   - Zero signature accounts among 41 PR authors. Claude/Copilot trailers appear on #1064, #1062 and others, none in the priced lanes.
   - Best lane: TWCC feedback attributed to each MidRid, with acked / lost / recovered-by-RTX counts in `MediaEgressStats`. The traps are real: late reversal at twcc.rs:1226-1236 and Resend-kind vs is_padding at send.rs:897-909.
   - It sizes at ~140, leanest ~100. Everything routes through `Session::poll_packet` and `apply_report`. libwebrtc's `TransportFeedbackDemuxer` is a crib for the attribution, and algesten is actively working TWCC/BWE probing (Sep 2026).
   - Other lanes: frame-aware send-queue eviction (~125, the app's job per #1001/#1005), mixed clock rates (RFC 7160 port, ~125), lip-sync (declined in #731), RTX counters (an "add N fields" lane named by W3C stats). Hot or claimed: SCTP (draft #1053/#1054), buffer_rx, NACK, poll scheduling, event log #947, audio codecs, BWE probing.
3. **capa.** HEAD `f3765cdf`.
   - CI on master is `failure` on every 2026-09-08 push. Hunt #39 traced it to licensed Binary Ninja jobs, so it would need base 497120ff or a human ruling. Maintainers have been nearly idle since June.
   - Minimal match evidence: ~145-160, leanest ~90-100. The -vv MODE_SUCCESS tree already prunes the evidence, and delete-and-rematch with `ruleset.match` as a black box dissolves every trap.
   - Freeze dropping library functions is a real gap (freeze/__init__.py:313-345; loads_static 579-611), but it is a ~30-45 eff restore fix.
   - Wildcard bytes carries williballenthin's design (#233). Union of extractors carries mr-tz's plan (#938).
   - 17% of the 12-month non-bot PRs are small outsider fixes (GSoC season), none of them in the lane.
4. **alembic.** HEAD `1bc21b86`.
   - zzzeek triages every issue. Since 2026-08-10 every PR needs an "open for pull requests" label, and he drafts features himself through gerrit (comment on #326).
   - FK-dependency op ordering is his live workstream (#326, gerrit 7003). Rename ops are wontfix (#348). Reversible ops are his own design (#275), and the replay half is wontfix (#492).
   - Offline SQLite batch shadow: batch is the hottest lane of Aug-Sep 2026 (#1834 and same-day sweeps; open PRs #1792/#1839/#1862). `ApplyBatchImpl` absorbs it at ~90-120.
   - Dependent views/triggers: #1207 is resolved by docs, and alembic_utils covers views. Comparator gaps are famous magnets.
5. **go-astisub.** HEAD `7671e72e`.
   - The TTML timing tree (dur / par / seq / nested-div / span splitting) is a real discarded-state wall (ttml.go:178-188, 405-447), but it sizes at ~190 with a leanest of ~140.
   - It is also on the maintainer's bulleted list in #78 ("welcoming PRs"), and PR #131 made it the obvious next step.
   - A conform/reflow pass is a standalone post-pass that follows famous guidelines (Netflix/BBC).
   - The README roadmap is a support-matrix magnet (`.smi`).

## Stage 6 death-class guard
Not run on a RANK 1, because there is none.
- The dinit WEAK row was run through Q1-Q4 by its auditor. Q1 is partial: one helper-process lifecycle kernel. Q3 passes: it is not solvable as a standalone file. Q2 is partial: T1 (shared exec-status watcher) and T2 (stop vs action exit order) interact.
- It fails Gate 7 (leanest under ~180), so it is not returned.

## Budget record
- **Proven pool:** done. The rejected-pool classification above covers every rejected repo; five were lane-audited.
- **Cached star-band index:** not re-triaged. Hunts #50-#52 read every row (1,746 engine rows, 9,171 + 13,459 never-named rows, the 6k-15k band) and reported 0 survivors. The human's standing direction (2026-10-05) replaces broad discovery with second lanes, so re-reading it at misses = 1 has no expected yield.
- **Fresh niche sweeps:** none, for the same reason. Two remained in budget.

## What the next hunt should change
1. **The claimed pool is now exhausted for second lanes.** Every repo we ever approved, claimed or rejected now carries a recorded lane verdict:
   - approved: hunts #35/#37/#53/#54;
   - in flight: #54;
   - rejected: #54 and this hunt.
   - The standing direction no longer yields candidates. The orchestrator should tell the human so, and ask whether broad discovery may resume. The documented default if nobody answers is to resume it at misses >= 2.
2. **At misses >= 2, apply the softened rules and spend both niche sweeps on topic search.**
   - Use single-word maintainer topics, with the dead-list filter from `deadlist_v12.txt` plus every slug in today's logs (B-G).
   - Target domains where a capability means new domain mathematics or a repo-internal hidden wall (discarded persisted state, a loader convention, a stage boundary), and where the maintainer is building elsewhere.
   - Python/Go/TS with a real domain model beat framework repos; avoid SQL/ORM, WebRTC/RFC stacks and service managers.
3. **WEAK options the human may choose to spike first (measure-first, not picks):**
   - dinit named service commands with levers (a) and (b): the target is >= 230 human-eff in a 45-minute spike, re-checking the 1.0 feature freeze and D178 first.
   - NASA-AMMOS/3DTilesRendererJS in-place refresh (#54).
4. **Leads for nobody:** the capa freeze library-function gap (~40 eff) and the str0m TWCC ledger (~140) are real gaps but are under the floor. Do not re-price them.
