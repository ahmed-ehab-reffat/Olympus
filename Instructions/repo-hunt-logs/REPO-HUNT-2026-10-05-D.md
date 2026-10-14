# REPO-HUNT-2026-10-05-D (hunter #52, CONSECUTIVE_MISSES=3)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1005h52/` (5.0M):
- `judged_h52.txt` (5,920 slugs): every owner/repo named in a hunt log, SATURATED-REPOS, TOO-EASY, the LEDGER, any meta.md, any `screen*` file or any `agents/` dossier. This is the list of rows somebody actually adjudicated, as opposed to `screened_h51.txt` (rows that were only read in a list).
- `unjudged_rows_h52.json` (13,459): live cache rows (band + band_hi + band_misc + band_noassert, 500-4000 stars, supported primary language, pushed after 2026-06-15 at fetch time) whose slug AND short repo name appear in no log, dossier or screen file.
- `vocab_keep_h52.txt` (1,967, broad engine vocabulary) and `vocab2_h52.txt` (1,017, strict domain-engine vocabulary minus app/AI/infra noise): the two cuts of that residual.
- `brain_h52.txt`, `brain2_h52.txt`, `brain3_h52.txt` (≈340 slugs) and `b*_meta.jsonl`: knowledge brainstorms (domain engines, Python science/tooling engines, TS/JS and database engines), with GraphQL metadata for the unjudged ones.
- `orgs_h52.txt`, `orgsweep_raw_h52.tsv` (180 rows): fresh sweep 1.
- `topics_raw_h52.tsv` (132 rows): fresh sweep 2.
- `used_topics_h52.txt`: topic words recovered from earlier sweep scripts and logs (partial).

## Standing inputs
- **Direction:** hunt #51's NEXT_HUNT_HINT. It said not to run broad sweeps, to re-check tylax and pokerkit (spike only above ~520 stars), and to use the widening a miss count of 3 allows (re-open lanes killed only by softened-rule criteria, or invent lanes on gate-clean repos already judged). Licence, language, activity, Requirement 7, exclusivity and quota stay fixed.
- **Excluded:**
  - every LEDGER repo in every status (the table plus every slug named in its notes);
  - every `problems/` folder (13 today);
  - the queue: tortoise/aerich (with sqlalchemy-continuum and aptly reserved), Athou/commafeed (with cloudflare/pint, cenkalti/rain and naggie/dstask reserved), gonum/plot;
  - SATURATED-REPOS, `rejected/`, `approved-problems/`, per-repo quota.
- **Softening (misses = 3).** The 2026-09-09-B softened rules apply. Relaxations taken, as the skill requires:
  1. **"Already looked at" was narrowed from "eyeballed in a list" to "named in a verdict".** The 13,459 live cache rows that no log, dossier or screen file ever names (by slug or short name) were re-read as candidates instead of being treated as seen.
  2. **WEAK fallbacks were re-opened under the softened LOC rule** (150-250 eff needs a coupled lever, above 250 proceeds): planetiler direction-aware merging and ipyflow's restart ledger. Both died again, on criteria that were never softened (below).
  3. **Star window:** the 500 floor was kept. tylax and pokerkit were re-checked, not spiked.
  - Not relaxed: licence, language, activity, live upstream, Requirement 7, exclusivity, signature-account threshold, quota.
- **Requirement 0 (platform picker):** OWED, but there is no candidate.
- **Disk:** `/` read 8.1G free at the start and at the end. No clone, build, venv or Docker. Scratch is 5.0M.

## Stage 0-bis: proven pool, 0 viable
- Pool repos not on the LEDGER were checked against their latest written verdicts (09-18-C through 10-05-C):
  - mwparserfromhell, scikit-fem, tippecanoe: DEAD;
  - worldengine: dormancy magnet (erosion lane in open PR #270);
  - DataFixerUpper, calyx, acoular, sfepy: B2 lane kills still stand;
  - mpmath, petl, ezdxf, cantools: two or more signature accounts;
  - customasm: quota;
  - planetiler: WEAK, and re-opened below.
- **onthegomap/planetiler re-screen** (★2194, Apache-2.0):
  - 34 msbarry commits in 12 months, the latest "fix issue 1622 (#1623)" on 10-04.
  - No signature accounts, no AI marks, CI green.
  - Open PRs: Shortbread profile, `--source_parallelism`, runtime tile extent (#1565, already dead), MLT.
  - The only open lane is #298, direction-aware line merging. Its 09-18-C dossier priced the core at ~130 eff and ~250-290 with the provenance or group-and-combine lever.
  - **Verdict: DEAD.** #298 is a maintainer-authored bulleted plan: filter; group by a subset and combine the rest; keep direction; swap `oneway` on reversal; 3-way and fuzzy merges. Each bullet is a pre-sized pick, and core plus lever is two or three bullets of that one plan. That is the oxipng #551 class ("a maintainer's numbered plan inside a popular issue is a reject"), and that rule was never softened. Guard #2 also stays borderline.
- **tylax / pokerkit:** ★501 / ★502 (unchanged). Not spiked.

## Cached index: the never-named residual, 0 viable
- **The gap #51 left:** #51 read the never-EYED rows, and nobody had re-read the eyed-but-never-NAMED rows. A list glance had dismissed them on their description alone. 13,459 rows.
- **Cut 1** (broad vocabulary, 1,967 rows): mostly matched generic nouns (map, tile, sync, index). I sampled it and dropped it for cut 2.
- **Cut 2** (strict domain-engine vocabulary minus app/AI/infra, 1,017 rows): every Python, Go and Rust row was read in full, and the TS/JS, C++ and Java rows through an engine-noun filter. Nearly all of it is apps, scrapers, Home Assistant integrations, game mods, ML papers and SDKs. Rows worth a check:

| Repo | Verdict |
|---|---|
| dstl/Stone-Soup (Py ★663, MIT) | DEAD. A burst: `sylvesterkaczmarek` filed ~29 tracker-numbered PRs in two weeks (08-18..08-31), a Claude-style sweep over the correctness gap class. The only test CI is CircleCI (GitHub has only `docs-link.yml`). A sibling-workspace pick here (`stonesoup-multiple-model-tracking`) died as publicly-solved. It is also a named-algorithm catalogue (Kalman/PDA/JPDA/PHD) with FilterPy-class siblings |
| CMU-SAFARI/ramulator / ramulator2 (C++ MIT) | DEAD. v1 has had no code in 12 months. v2 is the authors' active JEDEC-standard timing refactor (LPDDR6/HBM4, 08-30), so it is a named-spec lane, and it was already judged in 09-14-B/09-29 |
| fb55/css-select, webpack/enhanced-resolve, meriyah | DEAD. Named specs (CSS selectors, Node resolution, ECMAScript) |
| facebook/mariana-trench, JohnEarnest/ok, HDiffPatch, openscope | DEAD. Respectively: a Redex/C++ heavy build; a language implementation (carve-out); NOASSERTION; NOASSERTION plus an app |

## Knowledge brainstorm (≈340 slugs, three lists): 0 viable
- About 60% of the names were already judged. The rest were checked with GraphQL metadata.
- Rows above the floor and alive, with their verdicts:
  - **Copier** (Py ★3611, MIT): DEAD. A dormancy magnet. 50 open PRs, ~30 of them outside feature PRs with public diffs across every core lane: preserve-regions update #2762, `copier schema` #2758, opt-in questions #2849, version-range updates #2588, postrender tasks #2389, dict/nested questions #2231/#2223, and sisp's own git-merge update rewrite #2376. sisp is also sweeping `fix(updating)` himself.
  - **opensheetmusicdisplay:** already DEAD (competitor swarm, Claude sweep).
  - **cantools:** already DEAD (7 signature accounts plus a sibling-workspace sub). The slug filter missed it because the logs name it only by short name, which is why `judged_h52` checks short names too.
  - **import-linter:** DEAD (absorbed into the grimp sibling).
  - **similar / imara-diff / pymoo / ompl / pinocchio / TEASER / tinybvh / madmann91-bvh:** DEAD. Textbook algorithms with sibling libraries.
  - **asmjit, LIEF, chrono, Triton:** company firehoses or heavy builds.
  - **go-jet, goqu, sqlboiler:** SQL (avoid).
  - **WebCola, expr-eval, cannon-es, polybooljs, reactphysics3d, netlistsvg, go-ruleguard:** no code in 12 months.
  - **liquidjs, csstree, Algebrite:** named spec / language surface / CAS class.

## Fresh sweep 1 of 2: research-institute and lab orgs: 0 viable
- **Query:** 86 orgs (NREL, sandialabs, usnistgov, LLNL, ORNL, nasa, esa, cern, DLR, pnnl, idaholab, Unidata, NOAA, USGS, ecmwf, MetOffice, SciTools, dstl, alan-turing-institute, OSGeo, pangeo/xarray-contrib, PyPSA/oemof/calliope/pvlib, LANL, MIT-SPARK, ethz-asl, opensim, pybamm, cantera, openmc, FEniCS/firedrake/mfem/deal-ii/precice/su2, materials and quantum orgs, plus the big-company research orgs) with `--stars>=500`, supported language, pushed in 12 months.
- **Result:** 180 rows, almost all famous, ML, or already judged.
- The unjudged science rows and why each dies:
  - CleverCSV: a small dialect sniffer;
  - HyperNetX and fipy: licence not on the allowlist (PNNL / NIST public-domain);
  - qsim: Google quantum, textbook state-vector;
  - pyquil: client library;
  - Kimera-RPGO: GTSAM-heavy.
  - iris, xarray-spatial, PyPSA, pymatgen: already judged.

## Fresh sweep 2 of 2: 75 niche topics never used before: 0 viable
- **Topics:** `electrochemistry battery-modeling fuel-cell hvac building-energy daylighting lighting-design acoustics room-acoustics psychoacoustics tablature music-theory sheet-music engraving lilypond musicxml abc-notation dmx show-control timecode braille hyphenation knitting embroidery cnc laser-cutting pen-plotter plotter slicer inverse-kinematics motion-capture bvh cloth-simulation softbody sph lattice-boltzmann molecular-dynamics epidemiology traffic-simulation railway interlocking flight-dynamics astrodynamics orbital-mechanics astrometry photometry radio-astronomy smart-grid power-flow water-distribution stormwater groundwater cadastre plain-text-accounting beancount hledger bookkeeping invoicing amortization actuarial yield-curve fixed-income order-book matching-engine auction social-choice stable-matching rostering bin-packing cutting-stock nesting job-shop critical-path gantt`.
- **Result:** 132 rows; 24 topics returned nothing at >= 500 stars. Every engine-shaped row was already judged:
  - pyroomacoustics, acoular, ikpy, mink, dart, pink, SPlisHSPlasH, salva, maker.js, grid-apps, ezbookkeeping, CppTrader, 3d-bin-container-packing, DHTMLX gantt, fava, opensheetmusicdisplay, Hyphenopoly, textwrap, three-mesh-bvh.
- The unjudged rows are apps or out of licence:
  - alphaTab (MPL-2.0);
  - qlcplus (a Qt lighting app);
  - double-entry-generator (a per-provider importer catalogue, L2);
  - pytheory (a small catalogue);
  - tinybvh / madmann91-bvh (textbook BVH);
  - cncjs, Invio, gantt UIs (apps).

## Re-opened WEAK lane: ipyflow L1 (restart ledger): still WEAK
Re-read `s_0930h42/dossier_ipyflow_h42.md`. The lane prices at ~235 eff. Under the softened rule that number needs a coupled lever, and the only named lever (a restore plan) is already shipped in TypeScript (`graph/closure.ts`).

Two further problems, neither of them a softened criterion:
- the maintainer runs Claude Code over the same staleness planner the lane must change;
- the dossier calls the spec "heavy" (path encoding, ledger schema, restart semantics), which cannot fit the 2026-10-02 meta.md ceiling of <= 200 words (hard 400).

Not returnable.

## Stage 6
Not run. No candidate reached a dossier.

## Fallbacks
None returnable. Unchanged WEAK rows: tylax and pokerkit (star floor), ipyflow L1 (above), lektor (the maintainer says in #1235 that he has no time; near-dormant). planetiler #298 is now DEAD (maintainer bulleted plan).

## What the next hunt should change
1. **Discovery is exhausted on every axis tried so far, and this hunt added four more:**
   - the eyed-but-never-named residual;
   - a ≈340-slug knowledge brainstorm;
   - research and lab orgs;
   - 75 fresh niche topics.

   Every engine-shaped row they returned was already adjudicated. Another hunter launch at misses >= 4 will cost budget for the same answer.
2. **The only levers left need the human:**
   - (a) allow a second, different-subsystem lane on ACCEPTED or CLAIMED LEDGER repos (pict, piscsi, bayesopt, teavm, pyocd and others). This is the corpus's most reliable pattern (Stage 0-bis), and the hunt contract forbids it today;
   - (b) supply new anchor repos or domains;
   - (c) pause discovery until ~2026-10-19, then re-fetch the band for 500-star crossers and fresh pushes since the 09-15/16 cache (the 09-29 crosser sweep found 1.8% new rows, all junk, so expect little).
3. **Cheap re-checks for the next run:** tylax and pokerkit stars (spike only above ~520), and devpi once `fschulze/devpi:server7` merges.
4. **Tooling:**
   - Use `s_1005h52/judged_h52.txt` plus a short-name match against the logs (the cantools miss) as the "adjudicated" list.
   - Use `s_1005h51/screened_h51.txt` as the "eyeballed" list.
   - `orgs_h52.txt` and the topic list above are spent.
