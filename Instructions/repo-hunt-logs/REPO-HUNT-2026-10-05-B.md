# REPO-HUNT-2026-10-05-B (hunter #50, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1005h50/`:
- `gqlmc_h50.py`, `mc_h50.jsonl`: the maintainer-filed issue index for the 1,746 `fresh_eng_h48.tsv` rows. Per repo it holds the 50 newest open issues (with authorAssociation and a body excerpt), the top-6 committers of the last 100 commits, and commits since 2025-10-05.
- `score_h50.py`/`scored_h50.txt` (299 repos with >= 3 maintainer-filed issues) and `clus_h50.py`/`clus_h50.txt` (137 repos with a shared-noun cluster of >= 3 maintainer issues).
- `noneng_h50.tsv`, `dom_h50.tsv`: the 11,691 never-selected cache rows that the hunt #48 engine vocabulary dropped, and a domain-vocabulary cut of them (1,057).
- `screened_h50.txt` (9,706 slugs named anywhere in a log, dossier or screen file) and `unscr_h50.tsv`: 863 live, permissive, domain-worded cache rows that **no log has ever named**.
- `topicsweep_h50.sh`, `sweepA_h50.tsv(.raw)`: fresh sweep 1.
- `seclang_h50.py`, `seclang_h50.jsonl` (5,757 rows), `langshare_h50.py`, `sl_ls_h50.jsonl`, `sl_sup_h50.txt` (373): fresh sweep 2.
- `screen1_h50.txt`: mechanical screens of 11 repos.
- `union_h50.txt` (36,804 slugs: seen_any + deadlist_all + dead_h49 + eyed_h49 + eyed_all_h48 + slugs_h47) and `dead_h50.txt` (that union plus today's kills).

## Standing inputs
- **Direction:** hunt #49's NEXT_HUNT_HINT. Run the maintainer-filed issue-cluster axis over the ~1.7k engine-shaped rows from hunt #48. Skip the repos that #46/#47 already indexed.
  - The skip turned out to be empty. None of the 1,746 `fresh_eng_h48` rows appear in `s_1002h47/slugs_h47.txt` (8,499) or `s_1001h46/eng_slugs.txt` (417), so all 1,746 were fetched.
- **Excluded:**
  - every LEDGER repo, in every status;
  - every `problems/` folder;
  - the queue: Athou/commafeed (plus reserved cloudflare/pint, cenkalti/rain, naggie/dstask), tortoise/aerich (plus reserved sqlalchemy-continuum, aptly), gonum/plot;
  - #49's WEAK rows (scipenai/tylax, MIT-LCP/wfdb-python);
  - SATURATED-REPOS, `rejected/`, `approved-problems/`, per-repo quota;
  - the turmoil clock lane.
- **Softening:** misses = 1 (< 2), so the softened 2026-09-09-B rules were applied only as already written into the skill. **Relaxations: none.** No star or issue window was widened.
- **Requirement 0 (platform picker):** OWED (no candidate).
- **Disk:**
  - `/` read 8.2G at the start and 8.1G at the end.
  - No build, no venv, no Docker.
  - One clone was made, `worktrees/pokerkit-h50` (8.6M, no build output). It is kept for the record and can be deleted.
  - Scratch is 29M.

## Stage 0-bis: the proven pool
Nothing new. The newest folders in `approved-problems/` are grmtools, riff, ray-optics-sp and macs-circular. All four are LEDGER rows, and #49 re-checked them this morning. The two open pool lanes are unchanged:
- turmoil clock: dead by our own #22 exclusivity note;
- rust-minidump XSTATE: Stage 2d worst case.

The pool still has 87 repos at 1-2 subs, all covered by #46's kill table.

## Cached index 1: maintainer-filed issue clusters (hint): 0 viable
- **Fetch:** GraphQL, 1,746 repos, 5 per query, about 20 minutes. Results:
  - 299 repos have >= 3 open issues filed by OWNER/MEMBER/COLLABORATOR or a top-3 committer, after dropping docs/CI/release/build noise;
  - 137 of those have a cluster of >= 3 such issues on one title noun (stars 500-7,000, c12 >= 8, last commit after 2026-04).
- **What the clusters are:** mostly product backlogs. Examples:
  - per-service implementation checklists: sivchari/kumo (31 "Service implementation" rows), lupine (HIP runtime), Pluto (stdlib), TA-Lib (one issue per indicator);
  - syntax trackers: dtolnay/syn (32 "Parse X syntax", the language-surface carve-out);
  - UI epics: tacentview file dialog, threat-dragon Vue 3, jupytergis stories;
  - infra: lf-edge/eve, openziti backports, servicetalk flaky tests.
- **Kernel-shaped clusters, and why each dies:**

| Repo | Cluster | Verdict |
|---|---|---|
| apache/sedona (★2416, Java/Scala) | 5 maintainer bugs on cross-CRS raster/vector predicates (#3323 corner-only footprint reprojection, #3154 densify, #3153 WGS84 assumption, #3324 NoData band coupling) | DEAD. A Spark/Maven stack (Docker cold build), a 612-commit firehose, and the cluster is the maintainers' own open work |
| kornia/kornia-rs (★720) | PnP RANSAC / UP2P / RANSAC variants | DEAD. Named textbook estimators (sibling-library rule: OpenCV, PoseLib) |
| nickel-lang/nickel | YAML export quoting (#2481, #1979, #1968) | DEAD. Small fixes, and we already have a rejected nickel sub (exclusivity history) |
| openmls/openmls | External/grouped proposals (#1757, #1978, #2102) | DEAD. RFC 9420 spec rows (magnet) |
| membrane/api-gateway | HTTP/1 line parsing and HTTP/2 header charset quirks | DEAD. Named-spec conformance fixes, each one small |
| romeerez/orchid-orm | rake-db migration key collisions | DEAD. ORM lane (Python/TS ORM avoidance), and close to aerich in the queue |
| CarlosNZ/json-edit-react | stranded edit on a concurrent commit, move-only DnD permissions | DEAD. 71 AI co-author trailers in the last 100 commits |
| datafusion-ballista (AQE x10), rustc_codegen_cranelift (ICE x8), kani, verus, miri, sorbet | correctness clusters | DEAD. Huge toolchains or LLVM/rustc builds, and core-team firehoses |
| eclipse-langium/langium | content assist x3 | DEAD. Framework-maturity law: the completion engine is the absorbed extension point, and #1678 is the maintainer's own epic |

## Cached index 2: the never-named domain rows: 0 viable
- **The gap:** hunt #48's `fresh_h48` minus its engine selection leaves 11,691 never-selected rows that only ever met a regex. I cut them two ways:
  1. a domain vocabulary that the engine vocabulary missed (`dom_h50.tsv`, 1,057 rows);
  2. every live (pushed after 2026-07, as of the cache fetch), permissive, domain-worded row whose slug appears in **no** log, dossier or screen file (`unscr_h50.tsv`, 863 rows).
- I eyeballed all of them, minus the ML/robotics/app noise.
- **Screened (`screen1_h50.txt`, plus by hand):**

| Repo | Verdict |
|---|---|
| chenglou/freerange (★654, TS) | DEAD. No workflows at all (Requirement 7). A solo 300-commit firehose building exactly the static-relation lanes (14 open self-PRs) |
| solod-dev/solod (★1169, Go) | DEAD. A Go-subset-to-C translator: language implementation (carve-out) and a solo 300-commit firehose |
| seancfoley/IPAddress (★539, Java) | DEAD. No workflows (Requirement 7). README-only commits for six months (maintenance mode), and a mature catalogue with 0 issues |
| instancio/instancio (★1164, Java) | DEAD. A 300-commit solo firehose in a reflection framework (framework-maturity law) |
| tkrajina/gpxpy, noripyt/django-cachalot, antoine-coulon/skott, epicweb-dev/cachified, bladecoder-adventure-engine, mvdnes/rboy | DEAD or WEAK. 3-25 commits/12mo. gpxpy carries a SAY-5 signature and is a GPX catalogue. cachalot and cachified are cache-invalidation utilities with small kernels. skott is an import-graph rule list (L2). bladecoder is a libGDX app engine. rboy has 3 commits (near-corpse) |
| mapproxy/mapproxy (09-21 RANK 3 fallback, never adjudicated since) | DEAD by absorption. The lane was "level-scoped coverages in a seed task". MapProxy already expresses it by writing several `seeds:` entries over the same cache, each with its own `levels` and `coverages`. Progress is already per task. So an agent can expand a level->coverage map into N existing `SeedTask`s in `seed/config.py`, with no walker change (well under 150 eff). No commits since 2026-09-15 |
| others on the list | named specs (asn1js, FastCSV, commonmark-java, linkify-it, jsonc-parser, mistune, tomli, python-osc, h3-js, pbf), ports (vektah/gqlparser, cockatiel = Polly, markdown-it-py, kcp-go, quickfixgo = QuickFIX), catalogues (montanaflynn/stats, pycm, dirty-equals, DataFrame), heavy toolchains (tiramisu, CacheLib, pbrt-v4, iree), or apps |

## Fresh sweep 1 of 2: games, rules, assessment, narrative and calendar topics: 0 viable
- **Query:** 38 single-word topics never used before (`spaced-repetition fsrs quiz autograder autograding timetable timetabling rostering tournament swiss-system elo glicko ranking voting ranked-choice election apportionment mahjong bridge poker gedcom genealogy interactive-fiction visual-novel dialogue-system ink twine yarn-spinner recipe knitting icalendar rrule recurrence calendar crossword sudoku puzzle-solver`).
- **Result:** 73 raw rows. **68 were already in the 36.8k union**, and the 5 new ones are AI-course and skill-tree junk.
- **Conclusion:** topic discovery is now fully inside the seen union. The useful outputs were re-reads of seen rows:
  - **uoftcprg/pokerkit** (★**502**, MIT, Python, solo AussieSeaweed, CI green, 0 issues). It sat on 09-23's watch list "once it crosses 500". Cloned and checked. **WEAK/DEAD:**
    - stars sit at the floor (the same objection #49 made to tylax at 501);
    - `TODOS.rst` is a published pick list (sandbox mode, non-uniform ante pot accounting, HH-parser robustness), which the skill treats like a support matrix;
    - the one invented lane I sized, a per-seat information-set view, is absorbed: `State.get_censored_hole_cards` plus the per-player `HandHistory.to_acpc_protocol` / `to_pluribus_protocol` exports already exist;
    - `state.py` is one 6,439-line state machine whose remaining gaps are WSOP-rule rows (named external rules).
  - ical4j, khal, vdirsyncer, collective/icalendar, helios-server, todoman, Monogatari, ts-fsrs: already judged (RFC 5545 spec class, AI sweep, no CI, Cypress-only) or textbook.

## Fresh sweep 2 of 2: secondary-language-primary repos: 0 viable
- **Why this slice:** the band cache only queried the 7 supported languages plus jupyter/cython/tex/cmake/shell/html/makefile, and C separately. A repo whose GitHub primary is Kotlin, Scala, Lua, PHP, Ruby, C#, Swift, Assembly, Cuda, an HDL, Zig and so on, but where a supported language is still a top-3 language by bytes, was never fetched.
- **Fetch:** 47 primary languages, 8 permissive licences, 500-6000 stars, pushed after 2026-01-01. That gave 5,757 rows (5,689 not in the union). I then ran GraphQL language shares. **373** have a supported language in the top 3 at >= 20% of bytes and >= 15 commits in 12 months.
- **Result:** the slice is apps, CMSs, bindings, GPU kernels and Spark/JVM platforms. The engine-shaped rows:
  - natalie (a Ruby compiler; C++ only 21%), goro (PHP in Go), YueScript, p-org/P, Kusto-Query-Language (a machine-translated Java twin), apache/groovy: all language implementations or language-gate-marginal;
  - Nerdbank.GitVersioning and velopack: C#-primary, with the Rust part only a side binary;
  - pekko, nussknacker, gluten, datafusion-comet: Scala platforms, famous or firehose;
  - rav1e and purego: Assembly-primary, 7 commits / platform FFI.
- **Survivors:** none.

## Stage 6
Not run: no candidate reached a dossier. The closest rows (pokerkit, mapproxy) fail before the guard, on absorption and the star floor.

## Fallbacks (none returnable)
- uoftcprg/pokerkit: only with a lane that is neither a TODOS.rst row nor a WSOP rule, and only once its stars are clear of ~520.
- Do not return mapproxy level-scoped coverage (absorbed by multi-entry `seeds:`).

## What the next hunt should change
1. **Every discovery axis now returns rows inside the 36.8k seen union, or nothing.** That covers:
   - the band cache;
   - topic sweeps (68/73 already seen today);
   - the maintainer-issue index (#46, #47 and today together cover about 10.6k repos);
   - near-floor entrants;
   - revivals;
   - sister repos;
   - Jupyter;
   - secondary-language primaries (today).

   Another discovery sweep before about two weeks of star drift is wasted budget.
2. **At misses = 2, stop sweeping and spike.** Pick the best seen-but-WEAK row and have a builder measure human-eff on a scoped core slice before any scope-lock. The WEAK rows still open (each already has a log entry): scipenai/tylax (stars must clear ~520 first), MIT-LCP/wfdb-python (a lane outside multi-segment writing and outside the processing module), uoftcprg/pokerkit (same star caveat). None is strong, so the alternative is to re-mine the queue's reserved fallbacks once commafeed/aerich resolve.
3. **If a sweep is unavoidable, the only unread surface is above 6k stars.** These are repos in the 6,000-15,000 penalty band that have a repo-internal capability model. `band_hi.jsonl` exists, but only its engine-vocabulary cut was ever eyeballed. Expect famous-feature magnets there and apply the Stage 2b magnet test first.
4. Tooling: `s_1005h50/union_h50.txt` is the most complete seen list to date (36,804 slugs). Use it as the dead-list for any new sweep, plus `dead_h50.txt` for kills.
