# REPO-HUNT-2026-09-30-D (hunt #45, CONSECUTIVE_MISSES=2)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch lives in `worktrees/_hunt/s_0930h45/`:
- **Exclusion list:** `dead_h45.txt` (15,045 slugs). It is `s_0930h44/dead_h44.txt`, plus every slug in hunt #44's screens, plus every owner/repo in `pipeline/LEDGER.md`, plus every `Repository:` line in approved-problems/, problems/ and rejected/.
- **Cached-index selection:** `sel_h45.py` wrote two files:
  - `sel_lo_h45.tsv`: 311 rows, 500-6000 band.
  - `sel_hi_h45.tsv`: 34 rows, 6000-15000 band.
  - A broader read of the 6000-15000 band, without the dead-list, is in `hi_all_h45.tsv` (414 rows).
- **Screens:** `screen_h45.sh` (hunt #42's screener, unchanged) wrote five files:
  - `screen1_h45.txt`: formatters, 14 repos.
  - `screen2_h45.txt`: solver-domain brainstorm, 11 repos.
  - `screen3_h45.txt`: 6000-15000 band, 7 repos.
  - `screen4_h45.txt`: protomaps-leaflet.
  - `screen_pool_h45.txt`: 6 proven-pool repos.
- **Topic sweep:** `topics_h45.sh` (hunt #44's script, star cap raised to 15000) wrote `topic_raw_h45.tsv` (30 rows). After the dead-list, `topic_h45.tsv` has 16.
- **Fork scan:** `forkscan_h45.sh`, a copy of `forkscan_h42.sh`, wrote `forkscan_purgecss_h45.txt`.

## Standing inputs
- **Direction (hunt #44's NEXT_HUNT_HINT):** screen only solvers whose OUTPUT is observable in tests: a plan, an assignment, a kept/removed set, or a computed value. Two axes, in this order:
  1. observable-output solvers inside untouched subsystems of proven-pool repos;
  2. the 6000-15000 penalty band, after a saturation check.

  Also required: list maintainer fork branches in Stage 2c, run the fork-branch scan, price lanes by the first shared operator downstream of their call sites, and return only a lane repriced >= 260 with named coupled surfaces.
- **Excluded:**
  - every LEDGER repo and every `problems/` folder;
  - the orchestrator's do-not-return list (eventsourcing, mirrorbits, micasa, bazel-remote, aptly, devpi, hashcards, hamilton, aerich, ipyflow, piccolo, pueue, reshape, parsync, eventhorizon, dstask, commafeed, sqlalchemy-continuum, CrowdAnki, vega, capa, healthchecks, db-scheduler, timewarrior, Cwerg, MACS, pyOCD, pyfakefs, csbindgen, libspatialindex);
  - the axes of REPO-HUNT-2026-09-28, 09-29 through 09-29-G, and 09-30 through 09-30-C.

  Topics were checked against `s_0930h44/used_topics_all_h44.txt` and every earlier topic file. 8 of my 52 topics had already been used and were dropped: timetabling, hyphenation, bin-packing, boolean-operations, csg, voronoi, wave-function-collapse and procedural-generation.
- **Requirement 0 (platform picker):** OWED. It could not be checked here.
- **Softening:** misses=2, so the 2026-09-09-B softened rules apply.
- **Relaxations taken (recorded as the skill requires):**
  1. The star window was widened to 6000-15000, both for the cached-index selection and for the topic sweep. This is the Requirement 1 penalty band, and every row screened from it carries that penalty.
  2. The open-issue count was treated as a signal only; that is already the rule.
  3. Eyed-but-unjudged rows were re-read under the new observable-output filter. Hunt #44 had excluded every eyed row. The 500-star floor, licence, language, activity and live-upstream checks were NOT relaxed.
- **Platform saturation:** submission counts cannot be seen from here. The saturation check is SATURATED-REPOS § A/B plus our own corpus count. No 6000-15000 finalist has an A-section entry or a sub of ours.
- **Disk:** `/` had 7.2G free at the start and 7.2G at the end. Nothing was built, installed or run in Docker. There was one blobless depth-30 clone, `worktrees/purgecss-h45` (6.4M), kept for the weak fallback.
- **Signature list:** added `itosa-kazu`. The account was created 2026-01, has no name or bio, 2 followers, and 49 forks, most of them bounty and agent repos, with cssnano, postcss-sort-media-queries, tscircuit autorouting and purgecss among them. It holds a `codex/fix-rollup-plugin-module` branch that became purgecss PR #1466. That is one visit outside the lane, so it is only a note. The list now has 71 lines.

## Stage 0-bis: the proven pool (axis 1)
- **Re-screened:** the four pool repos the direction named, plus the two map-tile pool repos that had been screened but never lane-audited for a second pick (`screen_pool_h45.txt`).

| Repo | Today | Verdict |
|---|---|---|
| acoular/acoular | CI green. 37 commits in 90 days (artpelling 35 PRs; CMF #667, SBL #617, PolarGrid #646 and notch filters #636 open). `trajectory.py` is cold | DEAD for this axis. B2-ACOULAR still stands: the moving-source trajectory lane is absorbed (~35-45 eff, `UniformFlowEnvironment.apparent_r` already closes the retarded-time solve), and any propagation -> steering -> time-domain-beamformer pick self-collides with `acoular-reflecting-panels`. `BeamformerCleantTraj` already ships trajectory deconvolution. No observable-output solver remains in trajectory that is not the approved pick's own path |
| kinnala/scikit-fem | CI green, 9 commits in 90 days, `binggao1230` x1 | DEAD: B2-SKFEM "competitor-swarmed, AVOID". Three lanes (hybrid meshes, curved P2 lifecycle, wedges) are held by foreign submissions, and embedded manifolds is our own `derivative` |
| calyxir/calyx | 18 commits in 90 days, 13 open PRs; main CI red only on npm/extension jobs | DEAD: B2-CALYX structural warning (four lanes dead in one pass, and the academic repo triages its own gaps). `calyx/frontend` is a parser, and no solver there has observable output |
| nical/lyon | 0 open PRs, 18 commits in 90 days (nical) | DEAD, as ruled in 09-29: every algorithms/path/geom lane has a kurbo or tiny-skia sibling or is a recogniser; Hatcher NonZero is ~200 eff and fails Q3 |
| felt/tippecanoe | CI green, e-n-f 22 PRs, 51 open PRs; `youdie006` x1 (known) | DEAD. tile.cpp drop/coalesce is the maintainer's programme (B2-TIPPECANOE), and overzoom reassembly sits on draft PR #551 (09-18-C) |
| onthegomap/planetiler | 27 commits in 90 days, `catmraw34` x1 | WEAK, as in 09-18-C: direction-aware line merging is ~130 core |

- **Result:** nothing new. Every other pool repo keeps the kill recorded in 09-29 / 09-29-C.

## Cached index: observable-output solver vocabulary (new filter, both bands)
- **Vocabulary:** formatters and pretty-printers (line-splitting solvers); layout, text layout and typesetting; spreadsheet recalculation; register allocation; schema diff and migration planning; retention and pruning; dedup and chunking; label placement; simplification and generalisation; polygon clipping and triangulation; constraint layout; timetabling and rostering; pairing and tournaments; routing and map matching; packing; diff and merge; dependency resolution; model checking; allocators; procedural generation; font shaping; music notation.
- **Result:**
  - 500-6000: 311 rows, nearly all noise (renderers, Home Assistant integrations, "beautiful" UI kits).
  - 6000-15000: 34 rows on the strict vocabulary, and 414 on a broad one read without the dead-list.
- **Formatters (the one dense cluster) are signature-swarmed:**

| Repo | Stars | Verdict |
|---|---|---|
| andialbrecht/sqlparse | 4021 | DEAD. 9 signature accounts (binggao1230, ChrisJr404, chuenchen309, dylanpulver, lilu5458, Sanjays2402, santhreal, SAY-5, uttam12331) |
| PyCQA/isort | 6959 | DEAD. 4 signature accounts plus a copilot-swe-agent stream |
| sql-formatter-org/sql-formatter | 2897 | DEAD. binggao1230, MaxFreedomPollard, SAY-5 |
| google/yapf | 13987 | DEAD. 0 commits in 12 months; Eljees and SAY-5 |
| hukkin/mdformat | 825 | DEAD. 0 commits in 90 days; binggao1230 and SAY-5 |
| zhiburt/tabled | 2364 | DEAD. CI failing on master; ChrisJr404 |
| tconbeer/sqlfmt | 548 | DEAD. Licence reads NOASSERTION; Sanjays2402; SQL |
| hhatto/autopep8 | 4661 | DEAD. 3 commits in 90 days; Eljees |
| beautifier/js-beautify | 9001 | DEAD. jakezwang; 446 open issues (magnet tracker) |
| fables-tales/rubyfmt | 1233 | DEAD. Links CRuby (librubyfmt), so it is not pure-language |
| bazel-contrib/buildtools | 1194 | Not pursued. Bazel community firehose: 50 open PRs, 26 PR authors |
| html-to-text/node-html-to-text | 1761 | DEAD. 17 commits in 12 months; licence NOASSERTION |
| parinfer/parinfer.js | 1807 | DEAD. 1 commit in 12 months, no CI |
| ariga/atlas | 8758 | DEAD. Company product whose deep lanes are Atlas Pro (the javascript-obfuscator class) |

- **6000-15000 rows with a real observable-output solver (`screen3_h45.txt`):**

| Repo | Stars | Verdict |
|---|---|---|
| **FullHuman/purgecss** | 8050 | **WEAK, the only survivor.** Lane audit below |
| sverweij/dependency-cruiser | 7237 | DEAD. The solo maintainer ships features weekly (baseline modes, swc extractors, reports: #1079-#1102 in September), plus Copilot agent runs in CI. Capability-consuming |
| zeux/meshoptimizer | 8475 | DEAD. 100 commits in 90 days (zeux, clusterisation and LOD); carrerasdarren-cell |
| graphhopper/graphhopper | 6716 | DEAD. Company firehose (71 commits in 90 days, 51 open PRs, a `claude-on-call` author), and Matrix and route optimisation are commercial lanes |
| agronholm/apscheduler | 7643 | DEAD. 5 signature accounts |
| go-co-op/gocron | 7167 | DEAD. jakezwang, SAY-5 and a copilot-swe-agent stream |
| markmap/markmap | 13138 | DEAD. 4 commits in 12 months |
| penrose, vtracer, cvxpy, pdm, jsdiff, knip, Qiskit, OSRM | - | Not re-screened. Each has a written verdict (09-11 parked, 08-07, SATURATED AI-sweep row, eyed) or is a firehose, or is a textbook core with a sibling |

## Fresh sweep 1 (of 2): knowledge brainstorm, observable-output solver domains
- **Names checked against the dead-list first.** Already judged, so not re-screened: IronCalc (TOO-EASY `ironcalc-range-displacement`), dagre, d3-dag and ELK (sibling-library law, 09-19-C), brouter (14 AI marks), zrepl (needs a ZFS pool), jd (maintainer AI sweep), phonopy (under 500 stars), Clipper2 (no test suite), kopia (firehose), manifold (capability-consuming), diffsitter (C grammars).
- **Screened (`screen2_h45.txt`):**

| Repo | Stars | Verdict |
|---|---|---|
| vexflow/vexflow | 240 | DEAD. Under 500 stars after the org move. The engraving formatter would have been a real solver |
| paulrosen/abcjs | 2352 | DEAD. Requirement 7 (no CI runs); licence NOASSERTION; youdie006 |
| graphology/graphology | 1749 | DEAD. 10 commits in 12 months, a red CI row, and a catalogue of textbook algorithms (networkx/igraph siblings) |
| wal-g/wal-g | 4260 | DEAD. Firehose: 100+ commits in 90 days, 70 open PRs, 317 issues |
| mggg/GerryChain, mggg/VoteKit | 155, 24 | DEAD. Under 500 stars |
| google-deepmind/open_spiel | 5507 | DEAD. Team firehose, and the algorithms are textbook |
| YosysHQ/yosys | 4779 | DEAD. 100 open PRs, 561 issues |
| PyVRP/PyVRP | 703 | DEAD. The maintainers ship VRP variants themselves: pickup-and-delivery #1098 (08-12), clustering, v1.0.0a0. Capability-consuming, and our own VRP picks sit next door |
| PyPortfolio/PyPortfolioOpt | 6065 | DEAD. Test workflow failing, copilot-swe-agent, fkiraly firehose |
| erikbrinkman/d3-dag | 1519 | DEAD. Sibling-library law (ELK/dagre Sugiyama), and the maintainer is live (40 commits in 90 days) |

## Fresh sweep 2 (of 2): GitHub topic search, observable-output solver topics
- **Topics (all new):** timetable, rostering, label-placement, cartography, map-generalization, line-simplification, typesetting, line-breaking, music-engraving, sheet-music, tablature, voting, ranked-choice-voting, election, apportionment, tournament, swiss-system, rectangle-packing, texture-packer, cutting-stock, floorplanning, autorouter, pcb-routing, graph-drawing, sugiyama, treemap, spreadsheet-engine, formula-engine, constraint-layout, cassowary, diff-algorithm, tree-diff, mesh-simplification, polygon-offset, dungeon-generator, nonogram, crossword, sokoban, stable-matching, hungarian-algorithm, job-shop, critical-path, consistent-hashing, load-balancing.
- **Result:** 30 rows at >= 500 stars, 16 after the dead-list. They are treemap visualisers, an AI gateway, map editors, a resume typesetter and consistent-hashing libraries.
- **Only solver-shaped row:** protomaps/protomaps-leaflet (★854, label placement with a collision index). DEAD: 3 commits in 12 months, 0 in 90 days.
- **Law confirmed:** in these niches the 500+ star population is almost all visualisers, apps and wrappers. The solver engines sit under 500 stars (GerryChain, VoteKit, vexflow after its move) or in already-judged repos.

## Lane audit: FullHuman/purgecss (the only survivor)

### Mechanical
- MIT, TypeScript, ★8050. This is the penalty band, and no famous-spec port is involved.
- **CI:** "Build / Test" (build, lint, jest with coverage) is green on every run through 2026-08-22. The last push to main was 2026-04-12, and there are no main-branch failures.
- **Requirement 6:** real code in 12 months: v8.0.0 (2026-01-24), including "enhance keyframes handling to preserve animations referenced via CSS variables", `--preserve-paths`, and source-map fixes. Since April only dependency bumps have landed, so the maintainer is dormant.
- **Tracker:** 68 issues. 33 open PRs, of which 29 are dependabot. The 4 human PRs are #1492 (CSS variables in @media/@supports), #1467 (root-level `:where`/`:is` with other pseudos), #1466 (codex branch, rollup `module` field) and #1456 (docs).
- **Signature accounts:** none in the PR author list. `itosa-kazu` (fork scan) is new and was added.
- **Maintainer branches:** browser, examples, main, v1 (no feature branches). The fork scan found one agent branch, `itosa-kazu/purgecss codex/fix-rollup-plugin-module`, which is out of lane.

### Domain solver with an observable output
- **The output is the kept/removed CSS set:** `result.css`, `rejected` and `rejectedCss`.
- **Base gaps, read from source (no build was allowed):**
  - Every `&` selector is purged. `shouldKeepSelector` (`index.ts:900-995`) `continue`s past `nesting` nodes, so `isPresent` stays false. #1347's reporter uses the workaround "add `&` to the safelist".
  - Declarations directly inside nested @media/@supports are never collected. `evaluateRule` (`index.ts:620-626`) walks only direct `decl` children, so their `var()` targets are removed (#1347 and PR #1492, which is +14/-1 in `index.ts`).
  - Declarations inside kept `@keyframes` are never collected: `evaluateRule` returns early for rules inside keyframes (`:555-560`). A custom property used only inside a live animation is therefore purged.
  - Any word in any custom-property value marks an animation as used (`:409-414`), even when that property is itself purged.
  - `font-family: var(--f)` and the `font` shorthand never mark a `@font-face` as used (`:419-426`).
  - `addVariableUsage` only links variables already registered, so it depends on declaration order (`VariablesStructure.ts:39-56`). The "unordered usage" pass repairs only one level.
  - The instance state (`usedAnimations`, `atRules`, `variablesStructure`) is never reset between the CSS files of one `purge()` call. Removal also runs per file, before later files are walked, so cross-file liveness depends on file order.
- **Lane sketched:** nesting-aware liveness. Resolve `&` and implicit nesting against the SURVIVING parent selector list. Treat declarations as live only in kept rules, kept nested at-rules and kept keyframes. Settle custom properties, keyframes and font faces jointly to a fixed point (a variable used only inside a live keyframe; a keyframe named only by a live variable). Report nested rejections with their parent chain.
- **Coupled surfaces:** `shouldKeepSelector`, `evaluateRule` removal/emptiness, the collection for variables, keyframes and font faces, `VariablesStructure`, `rejected`/`rejectedCss`, and deep/greedy safelists and ignore comments on nested rules.
- **Repriced by the first shared operator:**
  - Every keep decision funnels through `shouldKeepSelector`, and every liveness fact through `collectDeclarationsData`.
  - Nesting alone is ~200-250 eff; the joint liveness fixed point alone is ~150-200 and would be a post-pass.
  - Together they are **~230-280, honest centre ~250**. That is under the 260 bar, and it reaches it only by bundling the two.

### Why it is not returned
1. **TOO-EASY named-spec-module law (weasyprint-page-floats):** "when the pick IS a named spec module the target engine lacks, assume another author already holds its core". "Add native CSS Nesting support to PurgeCSS" is outsider-nameable, and it is the first gap anyone handed an ★8k CSS tool finds. #1347 has been open since 2025-04 with one comment, and the only reply is a workaround.
2. **Sibling-library core:**
   - The hard part of the nesting half, resolving nested selectors, is exactly what postcss-nesting / postcss-nested ship in JS.
   - The at-rule half (unused keyframes, @counter-style and fonts) is cssnano's `postcss-discard-unused`.
   - The scope gate would read both as cribbable cores.
3. **Stage 6 Guard Q3:** without the nesting half, the liveness fixed point is a standalone post-pass over the purged AST (the RECOGNISER/POST-PASS class).
4. **Exclusivity:** open PR #1492 already publishes the at-rule-variables cell of the liveness half. It is not the central capability, but it is part of the kernel.

**Verdict: WEAK.** It is kept as the only fallback, and only if a future hunt accepts the named-spec risk with a precheck on a thin core slice first. Clone: `worktrees/purgecss-h45` (HEAD `6e6499261c928ab9b91147b9e62b377498dd9b7e`, 2026-05-24).

## Repricing (orchestrator rule)
- Nothing clears 260 with named coupled surfaces and an exclusive core. There is no RANK 1, so the Stage 6 death-class guard was run only on the purgecss lane (above, where it fails Q3 in its liveness-only form).

## Fallbacks
1. **FullHuman/purgecss**, nesting-aware kept-set liveness (~230-280): WEAK. Named-spec magnet plus sibling cores.
2. None other. bazel-remote (hunt #44's fallback) is on the do-not-return list.

## What the next hunt should change
1. **Observable-output solvers split three ways by population:**
   - **Formatters and pretty-printers** are the one dense 500-15000 cluster, and they are the most signature-swarmed class measured so far: sqlparse carries 9 accounts, isort 4, sql-formatter 3.
   - **Engines in niche solver domains** (engraving, tabulation, redistricting, timetabling, label placement) mostly sit under 500 stars.
   - **Solver engines above 500** are firehoses (PyVRP, meshoptimizer, graphhopper, wal-g, yosys, open_spiel) or textbook cores with siblings (d3-dag, graphology, jsdiff).

   The observable-output filter is right, but in GitHub-metadata discovery it selects the same population the previous 44 hunts already saw.
2. **Discovery by metadata is exhausted along this axis too.** Of the six in-scope repos this hunt found that were neither dead-listed nor recorded, only purgecss survived the screen.
3. **Suggested levers for misses >= 3:**
   - **(a) The bug stream of a dormant high-star tool.** purgecss showed the pattern: a famous repo whose maintainer went quiet leaves a cluster of acknowledged correctness gaps around one kernel (here liveness). Screen for "dormant maintainer + >= 3 open bugs about one kernel", read the SOURCE for the kernel, and keep the pick off the named spec feature.
   - **(b) Ask the human** whether a named-spec pick in a penalty-band repo (purgecss nesting) is worth one core-slice precheck. The skill's law says no. Only the platform can overrule it.
   - **(c) Accept a same-repo second lane on a CLAIMED or accepted ledger repo** whose problem is archived. The direction currently forbids this.
4. **Signature list:** now includes `itosa-kazu` (a codex-branch bounty account in CSS tooling, found by the fork scan).
