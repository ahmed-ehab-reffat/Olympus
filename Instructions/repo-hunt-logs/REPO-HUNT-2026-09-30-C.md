# REPO-HUNT-2026-09-30-C (hunt #44, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch lives in `worktrees/_hunt/s_0930h44/`:
- **Exclusion list:** `dead_h44.txt` (14,982 slugs) = `s_0930h42/dead_h42.txt` + `s_0930h43/eyed_prev_h43.txt` + hunt #43's `sel_h43.tsv` rows (`eyed43_h44.txt`) + every owner/repo in `pipeline/LEDGER.md` + the orchestrator's do-not-return list + every `Repository:` in approved-problems/, problems/, rejected/.
- **Cached-index selection:** `sel_h44.py` -> `sel_h44.tsv` (688 rows), narrowed to `sel_strong_h44.txt` (355 rows) on the solver-domain nouns.
- **Screens:** `screen_h44.sh` (hunt #42's screener, unchanged) wrote `screen1_h44.txt` (sweep 1, 17 repos), `screen2_h44.txt` (sweep 2, 3 repos), `screen3_h44.txt` (6 more sweep-1 names).
- **Topic sweep:** `topics_h44.sh` -> `topic_raw_h44.tsv` (122 rows) -> `topic_h44.tsv` (44 after the dead-list).
- **Fork scan:** `forkscan_h44.sh` (copy of `forkscan_h42.sh`) -> `forkscan_bazelremote_h44.txt`.

## Standing inputs
- **Direction (hunt #43's NEXT_HUNT_HINT, inverted screen):** first find a repo whose DOMAIN clearly needs a solver it lacks entirely (fixed point, consistent cut, assignment/matching, scheduling, constraint propagation, reachability/GC over history); only then check that the solver needs state the write path discards. List maintainer fork branches in Stage 2c and run the fork-branch scan. Price every lane by the first shared operator downstream of its call sites; return only a lane repriced >= 260 with named coupled surfaces.
- **Done first:** added `breken-ai` and `r3wretrhy` to `worktrees/_hunt/sig_accounts.txt` (now 70 lines).
- **Excluded:** every LEDGER repo, every `problems/` folder, the orchestrator's list (eventsourcing, mirrorbits, micasa, aptly, devpi, hashcards, hamilton, aerich, ipyflow, piccolo, pueue, reshape, parsync, eventhorizon, dstask, commafeed, sqlalchemy-continuum, CrowdAnki, vega, capa, healthchecks, db-scheduler, timewarrior, Cwerg, MACS, pyOCD, pyfakefs, csbindgen, libspatialindex), and the axes of REPO-HUNT-2026-09-28, 09-29 through -G, 09-30 and 09-30-B. Every sweep row was checked against `dead_h44.txt`, and the topic list was checked against every topic in `used_topics.txt` and hunt #42's topic files (5 of my first 52 topics were already used and were dropped).
- **Requirement 0 (platform picker):** OWED. It could not be checked here.
- **Softening:** misses=1, so the 2026-09-09-B rules applied as written. No star or issue window was widened. **Relaxations taken: none.**
- **Licence allowlist:** applied strictly (it killed monetr FSL-1.1-MIT, oTree MIT+citation rider, zola EUPL-1.2, dotter Unlicense).
- **Disk:** `/` had 7.2G free at the start and 7.2G at the end. Nothing was built, installed or run in Docker. Two blobless depth-1 clones were made: `worktrees/me3-h44` (deleted) and `worktrees/bazel-remote-h44` (2.3M, kept for the weak fallback).

## Stage 0-bis: the proven pool
- No change since hunts #35-#43. The only recent approvals (pict, macs-circular) are LEDGER rows, and the pool's second-subsystem lanes were adjudicated in 09-29 / 09-29-C.
- Result: nothing new.

## Cached index: 500-6000 band, SOLVER-LACKING-DOMAIN vocabulary (new)
- **Source:** band.jsonl, band_misc.jsonl, band_noassert.jsonl; in-scope language, permissive licence (plus NOASSERTION/empty for a manual read), pushed after 2026-01-01, dead-list removed.
- **Vocabulary (domains whose natural problem is a solver):** static site generators / incremental builds / build tools and task runners; Gantt / critical path / project scheduling; todo and task managers; budgets, expense splitting, reconciliation; seating, assignment, allocation, matchmaking, placement, nesting, bin packing, cutting; graph layout and flowcharts; pathfinding, transit/GTFS, itineraries, dispatch, fleets; leagues and brackets; playlists and subtitles; media/asset/photo libraries, orphans, garbage collection, reference counting; wikis, backlinks, outliners; bibliographies and citations; home automation and rule engines; ACL/RBAC/authorization, firewalls, IPAM, CMDB; dotfiles, provisioning, release management, monorepos, package and dependency managers, lockfiles; feature flags, experiments, surveys, form builders with conditional logic; localization; puzzles; game engines, ECS, save games, mod managers, load order.
- **Result:** 688 rows, 355 on the strong nouns. Mostly noise ("experimental", "replacement", "localization" in the SLAM sense, i18n libraries, UI transitions).
- **Rows that fit the inverted profile, and what killed each:**

| Repo | Stars | Domain solver it lacks | Verdict |
|---|---|---|---|
| cobalt-org/cobalt.rs | 1538 | incremental rebuild over a render-time dependency ledger | DEAD. Req 6: every non-bot commit in 12 months is chore/ci/docs/clippy (incl. `docs(ai)` policy commits), zero code. #81 "Incremental build with Serve command" is OPEN since the early tracker (magnet). Req 7 passes (only Coverage fails; Test on 3 OSes succeeds) |
| lumeland/lume | 2283 | incremental rebuild | DEAD. Absorbed: `core/site.ts` / `core/watcher.ts` already carry incremental `update()` |
| jbake-org/jbake | 1161 | dependency-aware re-render | DEAD. 0 commits in 90 days, 9 in 12 months; content DB already re-renders only changed docs; the SSG class is cost-not-value (below) |
| jspsych/jsPsych | 1224 | resume / reconstruct timeline state from saved data (replayer + cut) | DEAD. Exclusivity: open PR #3713 "feat: resume on page reload + first-class jsPsych.state (9.0)" is exactly the lane; also 2 `app/copilot-swe-agent` PRs |
| spiral-project/ihatemoney | 1392 | settlement / matching | DEAD. Absorbed: settle computation already exists; licence is a BSD-style custom text (would need a full read) |
| oTree-org/oTree | 532 | cross-round group matching (perfect stranger) | DEAD. Licence: MIT plus a mandatory citation clause (rider); no code commit since 2023-03 |
| monetr/monetr | 685 | recurring-expense funding planner | DEAD. FSL-1.1-MIT (not permissive) |
| buchgr/bazel-remote | 776 | reachability-aware GC (AC -> Tree -> CAS) | WEAK, see lane audit |
| acl-org/acl-anthology, mozilla/pontoon, openwisp-controller, AppDaemon, NIPAP | - | - | Not pursued: data repo / team firehose / Postgres-ip4r / scheduler and app dependency ordering already present |

## Fresh sweep 1 (of 2): knowledge brainstorm on solver-lacking domains
Every name checked against `dead_h44.txt` first. Already-judged names (not re-screened): r2modman, git-machete, git-town, pydoit, redo, cargo-make, go-task, khal, todoman, otterwiki, please, comtrya, packwiz, pypiserver, aerleon, capirca, attic, turborepo-remote-cache, pretalx, node-gtfs, spoolman, mage, invoke, scons, pytest-testmon, atopile, skidl.

| Repo | Screen verdict |
|---|---|
| mkdocs/mkdocs | DEAD. 2 commits in 12 months, CI failing on master; ★22k |
| getzola/zola | DEAD. EUPL-1.2; SAY-5 and youdie006 (signature accounts) |
| anishathalye/dotbot | DEAD for the GC lane. ★8011 (penalty band). #392 "Clean directive does not clean everything" (OPEN, 0 comments) asks for exactly stale-link GC on profile change; #152 "uninstall" closed with a published config-walking script in the wiki |
| SuperCuber/dotter | DEAD. Unlicense; 4 commits in 12 months |
| gitext-rs/git-stack | DEAD. renovate plus 6 epage PRs, restack solver already present |
| ezyang/ghstack | not pursued: commit-to-PR matching by trailer already exists |
| ejoffe/spr | DEAD. 0 commits in 90 days; SAY-5 (signature account) |
| jakejs/jake | DEAD. 0 commits in 90 days, no CI runs |
| silverbulletmd/silverbullet | DEAD. ★6180, 100 commits in 90 days, 33 PR authors (firehose) |
| indico/indico | DEAD. 879 open issues, CERN team firehose, PostgreSQL-bound tests |
| tach-org/tach | DEAD. impacted-test reachability (`tach test`) already exists |
| XLSForm/pyxform, BlinkTagInc/gtfs-to-html, jerry-git/pytest-split | DEAD. Under 500 stars |
| docassemble | not screened (slug moved to jhpyle/docassemble; solo firehose, on-demand dependency resolution already present) |

## Fresh sweep 2 (of 2): GitHub topic search, solver-lacking domains
- **Topics (all new):** dotfiles-manager, mod-manager, modpack, gantt, project-management, budgeting, personal-finance, inventory-management, bom, home-automation, ipam, firewall, conference, event-management, survey, form-builder, bibliography, citation, reference-manager, library-management, school-management, course-scheduling, logistics, warehouse, wms, supply-chain, mrp, erp, manufacturing, cam, nesting, embroidery, knitting, sewing, brewing, print-farm, 3d-printing, static-site-generator, incremental, selective-undo, versioning, capital-gains, portfolio-tracker, accounting, invoicing, expense-tracker.
- **Result:** 122 rows, 44 after the dead-list, almost all Home Assistant cards, form UI kits and supply-chain security scanners. Screened:
  - GreaterWMS/GreaterWMS (★4400): DEAD. 3 commits in 12 months; CI Pipeline failing on master.
  - GladysAssistant/Gladys (★3213): DEAD. "Claude autofix" / "Trigger Cursor" / "Scheduled Claude" workflows (maintainer AI sweep) plus 100 commits in 90 days.
  - garyttierney/me3 (★630): DEAD. Load order is already a solver (`mod-protocol/src/dependency.rs` `sort_dependencies`, used by `cli/src/db/profile.rs:125-126`); the host is a Windows DLL injector.
  - Not screened: lektor (build-state dependency DB already present), nautobot (company firehose), DHTMLX/gantt (GPL-licensed code), SurveyJS (firehose).

## Lane audit: buchgr/bazel-remote (the only survivor)
- **Mechanical:** Apache-2.0, Go, ★776, CI green on master (govulncheck, golangci-lint, tests), 34 commits in 12 months (mostynb, dependency upgrades plus small fixes such as 05-06 "If a cache entry can't be found on disk, remove the cache entry"). 24 open PRs, none in the GC lane. No signature accounts.
- **Domain solver it lacks:** reachability-aware eviction. `cache/disk/lru.go` evicts AC and CAS entries by one size-bounded LRU with no references; `GetValidatedActionResult` (`cache/disk/disk.go:816-915`) walks AC -> Tree -> file digests only at READ time and reports a miss when a blob is gone.
- **State the write path discards:** the LRU index (`lruItem`) keeps size only; the AC -> CAS edges are recoverable only by re-parsing every AC blob (and every Tree) on load (`load.go`).
- **Coupled surfaces:** HTTP and gRPC AC PUT, AC overwrite (release old edges, charge new), Tree two-level references, inline `Contents` (not references), startup rebuild in `load.go`, proxy backends (AC local, CAS remote), zstd CAS sizes, Stats/metrics.
- **Repricing by the first shared operator:** both PUT paths reach `diskCache.Put` -> commit -> `lru.Add`, so wiring collapses to one site; the digest walk is already written in `GetValidatedActionResult`; the new work is a refcount index, eviction skip/cascade in `SizedLRU`, and the load-time rebuild. **~210-240.** A lease/TTL variant (keep an AC hit's closure for T, as Bazel's Build-without-the-Bytes needs; #870) reprices at ~150-200.
- **Magnet / prior art:** #65 "Only garbage collect action cache entries" (OPEN since 2019-01, 5 comments) asks for exactly reference-counted CAS GC, and the original maintainer (buchgr) wrote the plan there ("adding a reference count to each CAS entry").
- **Fork scan:** no dataset or agent branch families. Maintainer fork `mostynb/bazel-remote` branches: compressed_blobs prototypes, fetch_api, zstd_lowmem, s3 timestamps and similar; nothing in the GC lane.
- **Verdict: WEAK.** Under the 260 bar, and the lane is a long-open issue carrying a maintainer plan.

## Repricing (orchestrator rule)
- Nothing clears 260. No RANK 1, so the Stage 6 death-class guard was not run.

## Fallbacks (both under the 260 bar)
1. **buchgr/bazel-remote, reference-aware GC (AC -> Tree -> CAS) with a load-time rebuild** (~210-240). Needs a coupled lever to reach 260, and #65 must be treated as prior art. Clone: `worktrees/bazel-remote-h44`.
2. None other. Every other profile row died on licence, activity, absorption or exclusivity.

## What the next hunt should change
1. **The inverted screen finds a different failure, not a candidate.** In the 500-6000 band, the undead solver-lacking domains split into two dead classes:
   - **Cost-not-value solvers.** Incremental builds (cobalt, lume, jbake, mkdocs) and cache retention (bazel-remote leases) have a naive correct answer: rebuild everything, or report a miss. The solver buys speed, which no fair test separates (Stage 3b "VALUE or COST"). Future screens should require that the solver's OUTPUT (a plan, an assignment, a kept/removed set, a resumed state) is observable before a repo is screened.
   - **Magnets.** The obvious solver gap in a small repo is usually an old open issue: cobalt #81, bazel-remote #65, dotbot #392, jsPsych #3573 (with PR #3713 already implementing it).
2. **Licence riders are common in this class:** oTree (citation clause), monetr (FSL), ihatemoney (custom BSD text). Read the licence before any lane work.
3. **Discovery in the 500-6000 band is exhausted along this axis too.** 44 of 44 topic rows and ~60% of brainstorm names were dead-listed or noise. At misses >= 2, consider:
   - the 6000-15000 penalty band (verify platform sub-count first); or
   - VALUE-solver domains inside the proven pool's untouched subsystems (acoular tbeamform/trajectory, scikit-fem, calyx frontend, lyon algorithms) rather than new repos.
4. **The signature list now includes breken-ai and r3wretrhy** (added this hunt).
