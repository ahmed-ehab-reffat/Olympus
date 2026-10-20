# REPO-HUNT-2026-10-15-C (hunter #67, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE.** I wrote and compiled two hunt-time spikes on the strongest unspent lanes, cenkalti/rain at **184** and GothenburgBitFactory/timewarrior at **179**. Both are under the 210 written bar, and timewarrior also fails Stage 6 Q3. About 40 repos were screened mechanically. No lane reached the return bar.

Scratch: `worktrees/_hunt/s_1015h67/`. It holds:
- the screener `mech_h67.sh` (h66's copy) and its outputs: `mechjava_h67.out` (15 Java rows), `mechband_h67.out` (12 band rows), plus the `_c_*.tsv` and `_p_*.tsv` dumps;
- the fresh-band fetch `newband_h67.py`, `newband_h67.jsonl` (3,082 rows, 500-600★, pushed since 2025-10-15), and `newonly_h67.tsv` (43 rows not in any cache);
- `known_h67.txt` (89.5k cached slugs), `allmentions_h67.txt` (the lower-cased mention corpus of every hunt log, SATURATED-REPOS, the LEDGER and the dossiers);
- the cuts `java_unmentioned_h67.tsv` (1,897 rows), `java_cut_h67.tsv` (200) and `band500_cut_h67.tsv` (650);
- the sketches `sketch_rain_queue_h67.patch` (184) and `sketch_timewarrior_targeted-undo_h67.patch` (179), plus `build_tw_h67.sh`;
- `judged_add_h67.tsv`, the 24 rows appended to `judged.tsv` (backup `judged.bak_h67`), and `sig_accounts.bak_h67`.

The timewarrior clone was deleted after measurement; it was built only inside a throwaway `olympus-base-cpp` container. The borrowed rain clone (`s_1002h47/logic/rain`) is back on clean master `7d5cd61`. Disk `/` is at 11G free, unchanged.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):**
  - LEDGER rows exclude only their own lane;
  - only repo-scope verdicts block a repo;
  - ~505 star margin;
  - return bar is 220 written (210-220 only with a real, named second lever);
  - the Q3 waiver applies only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet, AI-sweep, velocity and signature rules, and the 2026-10-13 tracker-named-lane rule.
- **Softening:** misses = 1, so the softened 2026-09-09-B rules were not triggered (they need n >= 2). No star or issue window was widened.
- **Requirement 0:** OWED (nothing returned).
- **Excluded lanes:**
  - Cwerg compact unions (HANDOFF);
  - allsorts (SLICING);
  - micasa blob reclaim (HUNTED);
  - qq typed binary schema (human session; its other lanes died at h60);
  - pint, commafeed, aptly, ray-optics module inlining, eventsourcing, every CLAIMED row;
  - the platform-dead lanes.
- **Default decision taken unasked.** The orchestrator's 09-30 "do-not-return" list named db-scheduler, timewarrior and dstask only because they were reserved behind micasa (then HUNTED). micasa is now accepted, so I treated those reservations as lapsed (the rule from REPO-HUNT-2026-10-06) and re-judged all three.

## Stage 0-bis: proven pool
- **Pool:** 95 repos with frontmatter plus about 45 older approved repos without it. For every repo I checked the newest `judged.tsv` row and the newest hunt-log mention.
- **No lane verdict has passed its 60-day expiry.** The oldest are pulldown-cmark (07-31) and neva (08-01). pulldown-cmark is repo-dead: four signature accounts, per the 10-05 table.
- **neva:** silent since 2026-08-23. The emil14 codex sweep has paused for about 7.5 weeks, short of the 8 weeks the 09-29-D audit asked for. Lanes must avoid analyzer/desugarer/irgen/typesystem; what remains is runtime/std small arms and printer backends. **Re-check after 2026-10-20.**
- **No acceptances since hunter #66.** REVERT-RECALIBRATION shows only micasa, csbindgen and mirrorbits today, all covered by #65 and #66.
- **qq** sits in `approved-problems/`, but its feedback.md shows a live human session (Description Quality rounds). Its codec file set stays excluded, and its other lanes died at h60. Spent.
- **The pool produced nothing.**

## Stage 0: cache tier, lapsed reserves first (the REPO-HUNT-2026-10-06 rule)
I read every `## Fallbacks` section from 10-02 to 10-15-B. The reserves still live:

| Repo | Reserve state | Today |
|---|---|---|
| **cenkalti/rain** (Go, MIT, 1147★) | reserved behind pint, which is now CLAIMED, so lapsed | **Spiked, 184 written. DEAD (below)** |
| naggie/dstask (Go, MIT, 1210★) | behind pint, lapsed | Not returned. L1 (per-task three-way field merge against the git merge-base) is the same capability class as our **accepted** micasa-field-level-sync-merge (per-field merge against the last-synced base), so derivative-loss risk to an older accepted task. #47 and #59 declined it for the same collision. The last commit was 2026-05-11. |
| kagkarlsson/db-scheduler (Java, Apache, 1654★) | h40 VIABLE, held behind micasa, lapsed | DEAD. L1 (per-task cluster concurrency limit) is tracker-named: #207 with a maintainer sketch, #693, #702, Discussions #737 and #766. Rival-held under the 2026-10-13 law. L2, L3 and pause/state were already dead (#275, README intent, maintainer PR #791). |
| **GothenburgBitFactory/timewarrior** (C++, MIT, 1668★) | h40 VIABLE "thin", held behind micasa, lapsed | **Spiked, 179 written. DEAD (below)** |
| pcodec, inline-snapshot, kas, dovi_tool, protobuf-es validator, hayro revision history, lebab, purgecss, tylax, pokerkit, wfdb, lektor, kuva | WEAK / do-not-return | Unchanged. None has a new lever; all are under 60 days |

### cenkalti/rain: session admission queue, seed limits, stalled release (spiked)
- **Mechanical:**
  - ★1147, MIT, Go 100%.
  - 133 commits in 12 months: jakealti 71 (a June correctness/test sweep), cenkalti 36, including the 10-03 rewrite "send commands to the run loop as closures".
  - CI green.
  - 0 signature accounts in 41 non-bot PRs.
  - No issue or PR for queue, ratio, max active or seeding limit (only closed #205).
  - #28 is a maintainer decline of *selective download* (a different lane). #140 is a factual "not possible".
- **Missing machinery confirmed at HEAD `7d5cd61`:** no admission scheduler, no Queued status, no queue persistence, no seed limits.
- **Two real hidden walls found:**
  1. `torrent_start.go` returns early on `t.errC != nil` BEFORE its Stopping cleanup. So `start()` during the stop-announce window is a silent no-op, and that cleanup block is unreachable today (F-39).
  2. `StopAnnouncer.Run` can still post to the buffered `announcersStoppedC` after `Close()`, because its final select has two ready cases. Any fix that makes the Stopping path reachable must drain it.

  Both fire exactly when a queue re-admits a torrent it just stopped.
- **Spike** (`sketch_rain_queue_h67.patch`, `go build ./...` and `go vet` clean): new `session_queue.go` kernel plus wiring in 15 files.
  - Core: Config limits, Queued status, per-category slot accounting, persisted queue order (`queue_pos` in boltdbresumer), seed-ratio and seed-time stop, the Stopping fix and announcer drain, and StartAll/StopAll/Remove/load-on-startup through the kernel. Measured **149 human-effective**.
  - Plus the coupled stall lever (a download with no new piece for `StalledTimeout` stops holding a slot): **184 human-effective** (raw 258, padding-floor 69).
- **Why so small (the dinit chokepoint law again):**
  - completion has one site (`checkCompletion`);
  - stops have one (`handleStopped` / the stop helpers);
  - RPC, move-torrent, console and AddTorrent all route through `Torrent.Start`/`Stop` and `StartAll`/`StopAll`;
  - the status string flows through `Status.String()` to RPC and console for free.

  The only remaining addition is per-torrent seed-limit overrides, which is plumbing through Spec, the resumer, the RPC args and AddTorrentOptions. That is padding, not a lever.
- **Verdict:** DEAD at 184 written (below the 210 bar). The Transmission-style capability is also outsider-nameable (MEDIUM). Its other lanes are BEP-named, the #28 decline, or already present (`torrent_create.go`).

### GothenburgBitFactory/timewarrior: conflict-checked targeted undo (spiked)
- **Mechanical:**
  - ★1668, MIT. The CC0 `wcwidth.h` note from h40 still stands for a human ruling.
  - C++ 58%, Python 36% (E2E tests).
  - `tests` workflow green on develop for the last 6 runs.
  - 54 commits in 12 months, mostly dependabot. Only lauft pushes code.
  - #776 (08-28) is a man-page-only change to `undo`, no capability.
  - 0 signature accounts. #790 is an outside chart fix.
- **Spike** (`sketch_timewarrior_targeted-undo_h67.patch`, built clean in `olympus-base-cpp`, `ninja timew_executable`):
  - a net-effect normaliser that cancels transients by `serialize()` (which strips the T1 id noise);
  - conflict analysis covering net-added still stored, restores against the post-removal snapshot, and config still holding its value;
  - apply;
  - `Journal::transactions()` / `removeTransaction(k)`;
  - `undo <n>` / `undo @id` with synthetic-piece-to-latest mapping;
  - a CLI dispatch change.

  Measured **179 human-effective**, of which **160 is in CmdUndo.cpp**.
- **Verdict:** DEAD. It is under 210 written, and Stage 6 Q3 fails: the lane is essentially one rewritten command file plus a two-method journal API, and the Q3 waiver needs more than 300. The h40 "not standalone" reading did not survive writing it. The only named extra lever (an undo preview listing, about 40) would land in the same file.

## Fresh sweep 1 (of 2): newly crossed the 500-star floor since hunt #60
I re-ran h60's `newband_h60.py` at 500-600★, pushed since 2025-10-15, across 7 languages and 9 licences. That returned 3,082 rows; **43** were absent from every cached slug. All 43 are AI tooling, agent harnesses, apps, MCP servers or scripts (31 were created in 2026). Nothing reached a screen.

## Cache tier re-cut: the 500-600 band, never-named domain rows
From the same 3,082 rows I kept those never named in any hunt log, LEDGER, SATURATED-REPOS, dossier or judged row, that match domain-engine keywords, and that were not created in 2026. That left **650 rows**. Read by language, the Go/Rust/Python/TS/JS/C++ rows are dominated by apps, cloud SDKs, Home Assistant components and ML paper repos. Twelve engine-like rows were screened (`mechband_h67.out`):

| Repo | Reading |
|---|---|
| spesmilo/electrumx (Py, 567★) | protocol/db lanes under maintainer WIP PR diffs #341 and #101; the rest is altcoin catalogue |
| sagiegurari/duckscript (Rust, 585★) | dormant since 2025-10, 11 open PRs |
| SpriteLink/NIPAP (Py, 592★) | 24 open PRs, dormant queue |
| gpertea/stringtie (C++, 534★) | no CI runs: Requirement 7 (repo row) |
| kuatsu/react-native-boost (TS, 580★) | maintainer v2 feature burst in September (platform folding, StyleSheet evaluation, static animated, cross-file ancestors), capability-consuming; what is left are add-optimizer arms |
| ljtn/epiq (TS, 543★) | solo firehose (298 commits); sync/time-travel class near micasa |
| cargo-public-api (Rust, 581★) | nightly rustdoc-JSON Docker friction; not audited |
| paxdotdev/pax (Rust, 526★) | solo firehose; no test-workflow runs visible |
| fe3dback/go-arch-lint (Go, 595★) | youdie006 signature x1 plus 2 new accounts |
| schacon/ticgit (Rust, 531★) | 59 AI trailers |
| opendatacube/datacube-core (Py, 591★) | signature account timothyanderson096-ocdealcheck x2 (repo row) |
| jupyter-book/mystmd (TS, 526★) | 2 signature accounts (dylanpulver, sapunyangkut), 47 open PRs (repo row) |

## Fresh sweep 2 (of 2): Java-first lens (never used as a discovery lens)
- Of 2,099 Java rows in the band caches, **1,897 were never named anywhere**.
- I cut them to 505-6000★, pushed since 2025-10-15, permissive licence, domain-engine keywords, and no apps/Spring/tutorials. That left **200 rows** (`java_cut_h67.tsv`), mostly famous infrastructure or Apache projects.
- I screened 15 (`mechjava_h67.out`):
  - **Requirement 7, no test workflow (repo rows):** Wisser/Jailer, SPLWare/esProc, Adrninistrator/java-all-call-graph;
  - **dormant:** jankotek/mapdb, TexasHoldemSolverJava, Incendo/cloud, imagej2;
  - **firehoses or AI:** objectionary/eo (47 AI trailers, 100 open PRs), castorini/anserini (4 new outside accounts), beanshell/beanshell (jimjag 251 commits, plus the new signature account below);
  - **thin:** litiengine, bladecoder adventure engine, geowave (red Tests), java-language-server.
- **New signature account: `Audgui-Byte`.** Created 2026-06, 8 repos, 0 followers. Scattershot PRs across beanshell (#855, overload resolution), **petl (in our corpus)**, DotNet.Glob, fast-deep-equal, PapaParse, python-jsonschema and husk. Added to `sig_accounts.txt`.

## Submission counts (warning only)
- rain 0, timewarrior 0, dstask 0, db-scheduler 0, neva 1 (approved).
- Every other repo screened today: 0.

## Verdict rows
`judged.tsv`: 24 rows appended.
- **Repo-scope (6):** Jailer, esProc, java-all-call-graph, stringtie, datacube-core, mystmd.
- **Lane-scope:** the rest, including both spike rows (rain 184, timewarrior 179), dstask class collision, db-scheduler tracker-named, and neva re-check-after-10-20.

## Why this hunt found nothing
1. **The lapsed reserves were thin for the reason the chokepoint law predicts.** rain's dossier priced 240-300 by summing nine surfaces. Every surface routes through `Torrent.Start`/`Stop` plus one completion site and one stop site, so the written kernel is 149 (184 with the one real lever). timewarrior's "not standalone" reading broke the same way: written, it is one command file. Hunt-time spikes are the only reliable number. Neither reserve should have been carried as "VIABLE" on paper for two weeks.
2. **Fresh discovery near the floor is exhausted by fame and AI churn.** Repos crossing 500★ this fortnight are 2026-created AI tooling. The never-named 500-600 band is apps, SDKs and paper repos. The Java lens returns Apache/Spring infrastructure, and its niche engines mostly lack CI.

## What the next hunt should change (misses will be 2: the softened 2026-09-09-B rules apply)
1. **Re-check neva after 2026-10-20.** If emil14 is still silent (8+ weeks), audit runtime/std/backend lanes for an invented, non-printer capability outside analyzer/desugarer/irgen/typesystem. It is the only pool repo whose state changes within the week.
2. **Keep re-auditing proven repos the day their in-flight lane is accepted** (Cwerg compact unions, allsorts, qq, pint, commafeed, aptly, ray-optics module inlining, eventsourcing). This is still the only lens that produced returnable lanes this week.
3. **Do not re-open rain, timewarrior, dstask or db-scheduler.** Their written numbers and verdicts are recorded. Every hunt-log reserve older than 10-06 is now spent or under 210 written.
4. **Use misses = 2 for a written spike, not wider sweeps.** The WEAK rows nearest the bar are systemc wait-state (225, Q3), kas archive (214, Q3), pcodec split (215, Q3, 505★) and inline-snapshot (206). Under the softened rules, the human may want a builder measure on the best of them rather than another discovery pass.
