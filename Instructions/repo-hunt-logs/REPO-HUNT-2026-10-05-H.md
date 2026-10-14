# REPO-HUNT-2026-10-05-H (hunter #56, CONSECUTIVE_MISSES=2)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch is in `worktrees/_hunt/s_1005h56/` (732K, all clones deleted):
- `AGENT_BRIEF_h56.md`: the lane-audit brief, including the mid-hunt COURSE CORRECTION (write the sketch, do not estimate it).
- `screen_approved_h56.txt`: a fresh mechanical screen of 18 approved-pool repos.
- `dossier_<repo>_h56.md` for 14 repos.
- `sketch_<repo>_<lane>_h56.patch`: 7 written, unrun reference sketches, measured with `effective_loc_check.py`.
- Tracker dumps: `prs_*`, `issues_*`, `openpr_files_tippecanoe_h56.txt`, `prauthors_*`.
- Sweeps: `topics_h56.txt`, `sweep_h56.sh`, `topic_hits{,2}_h56.tsv`, `deadlist_h56.txt`.

Nothing was built. No venv, npm, cargo, mvn or Docker was used.

## Standing inputs
- **Human direction (2026-10-05, in session):** "continue hunting and find out why you keep finding nothing. also try other lanes on the approved problems some of my friends use the same repo 12 times".
  - The pool is the approved-problems repos plus the accepted/CLAIMED ledger repos.
  - Try more than one lane per repo, and re-open earlier single-lane verdicts.
  - The submission count is a warning only: it is reported below and was never used to kill a repo.
  - The real walls are derivative overlap, exclusivity/PR-DIFF, signature accounts, Requirement 7, the 200 floor and the TOO-EASY classes.
- **Excluded (queued or in flight):**
  - the teavm cache-validity lane (other teavm lanes were audited);
  - aptly, commafeed, gonum/plot;
  - every repo with a `problems/` folder: asdf, Cwerg, csbindgen, eventsourcing, hayro, libspatialindex, MACS, micasa, mirrorbits, pyOCD.
- **Softening (misses = 2):**
  - The 2026-09-09-B rules applied as written.
  - The topic-sweep star ceiling was widened from 6000 to 8000 (relaxation recorded). No issue window was used.
  - Never relaxed: licence, language, activity, Requirement 7, exclusivity.
- **Requirement 0 (platform picker):** not checkable here. OWED.
- **Disk:** 7.1-7.6G free on `/` throughout (under the 8G build gate). No builds; Gate 1 was argued from code.

## Stage 0-bis: 14 approved-pool repos, 98 lanes, by 7 parallel auditors
- **Which repos.** Repos whose earlier kill was LANE-level (B2 ledger rows, "capability-consuming", single-lane DEAD/WEAK verdicts). All 14 have 0-1 signature accounts, a test CI that is not red, and real code commits in the last 12 months.
- **Repos skipped at the screen:**
  - statig: 3 commits in 12 months, red CI.
  - pysmt: intermittent master failures; theory lanes exclusivity-dead.
  - kira: every lane dead (B2-KIRA).
- **Pricing rule (course correction).** Every lane an auditor would rate VIABLE or WEAK was WRITTEN as leanest-correct code in the clone (unrun) and measured. Thresholds: VIABLE >= 230 written, WEAK 190-230, DEAD < 190.

| Repo (our subs) | Verdict | Best lane, written or priced | Lanes tried |
|---|---|---|---|
| ricktu288/ray-optics (2 approved) | **WEAK** | Module inlining on removal + template-aware param rename: **212 written** | 7 |
| featurevisor (2 approved) | DEAD | Rule mutations on the selected variation ~150, but the SDK is pinned by the conformance spec | 7 |
| Mindwerks/worldengine (1) | DEAD | Lake basins (priority flood): **150 written** | 6 |
| acoular (1) | DEAD | CSM diagonal reconstruction: **60 written** | 8 |
| nical/lyon (2 + 1 rejected) | DEAD | Hatcher composite ~190-210, one-file (stage 6) | 7 |
| hanruihua/ir-sim (1) | DEAD | Periodic world: **90 written** | 8 |
| quint-co/quint (1) | DEAD | ITF trace replay ~300, but bugarela's OPEN PoC #1873 | 7 |
| bufbuild/protobuf-es (1) | DEAD | .proto printer ~350 / descriptor validator ~250, both standalone files (stage 6 Q3) | 9 |
| konsoletyper/teavm (1, + HUNTED cache lane) | DEAD | Strict-mode array store checks ~140-150 | 8 |
| Mojang/DataFixerUpper (2) | DEAD | Located decode errors ~150, magnet #56 | 7 |
| onthegomap/planetiler (1) | DEAD | MBTiles merge `--append`: **89 written** | 6 |
| felt/tippecanoe (1) | DEAD | Overzoom rejoin ~250, maintainer-owned magnet (mapbox #551) | 6 |
| calyxir/calyx (1 + 1 rejected) | DEAD | mem-to-reg: **151 written** | 7 |
| cloudflare/wirefilter (1) | DEAD | FilterSet shared evaluation: **140 written** (public `Compiler` trait absorbs it) | 7 |

HEADs analysed (suggested BASEs):

| Repo | HEAD |
|---|---|
| ray-optics | daf76772 |
| featurevisor | b88f3981 |
| worldengine | b2adbb67 |
| acoular | 13d3d7df |
| lyon | 4357ba65 |
| ir-sim | 30058291 |
| quint | 23a4b811 |
| protobuf-es | c3a71a86 |
| teavm | 11a50bc0 |
| DataFixerUpper | 5fc09786 |
| planetiler | c094ff05 |
| tippecanoe | 4f262118 |
| calyx | d6bcdc87 |
| wirefilter | 123ab587 |

Full lane tables with evidence are in the dossiers.

### Earlier verdicts overturned or refined
- **ray-optics lane M (h53 WEAK, "~230 ref"): DEAD on its own.** It wrote out at 146.
  - The h53 rename lever (+60-80) was confirmed: it wrote out at +66, so M+R = 212. That is WEAK, not returnable.
  - Stage 6 Q2 is only partial: the rename traps barely interlock with the inline traps.
- **worldengine (SATURATED ~1274 WEAK): now DEAD.** Lakes was the only lane outside climate, and it wrote out at 150.
  - Partly overturned: 09-20-B's "erosion lane sits in open PR #270" is wrong. #270's diff is a helper refactor with no lake logic.
- **quint (09-23-J WEAK): now DEAD.** The only rich new lane (ITF replay) is held by the lead maintainer's open PoC #1873.
- **ir-sim:** the "reactive collision mode was removed (#55)" note is stale, because #374 (2026-10-04) shipped a full contact mode.
  - The capability-consuming DEAD verdict was re-done lane by lane and still holds.
- **teavm:**
  - h37's "debugger inlined frames WEAK" is now DEAD: it is a ten-line copy of the Wasm path.
  - h37's blanket "classlib = port magnet" is LANE-level, not repo-level. The one real classlib gap (strict-mode array store checks) dies on size, not on Guard 4.
- **Confirmed unchanged:** featurevisor h35 DEAD, lyon h35 DEAD, protobuf-es 09-10-B NOT AUTHORABLE (generated-file.ts, the one unread piece, is absorbed), B2-CALYX, B2-ACOULAR, B2-TIPPECANOE, the wirefilter ledger (our dynamic-operands lane is now upstream as maintainer PR #201, merged 2026-09-23), the DFU framework-maturity verdict.
- **Signature list:**
  - Added `SahilRajputdotexe` to `worktrees/_hunt/sig_accounts.txt`. Its calyx PR #2725 (+1,217, memory banking analysis, 2026-10-01) came in the same 4-day window as 10 pycparser PRs and PRs on teavm, ironcalc, ogen and canopen.
  - Candidate for the list (issues only, not added): `scadastrangelove`, with 7 audit-style wirefilter issues (#190-196) on 2026-08-21.

### Quota (reported, never used as a kill)
- ray-optics 2, featurevisor 2, DataFixerUpper 2 (+ a datafixerupper-optics folder elsewhere), lyon 2 (+1 rejected), calyx 1 (+1 rejected).
- All others: 1.

## Kill tally: which gate killed each lane (98 lanes)
| Killing gate | Lanes | Share |
|---|---|---|
| absorption / under 200 (a shared operator or existing extension point absorbs it) | ~34 | 35% |
| magnet / obvious-next-step (famous name, long-open ask, maintainer-authored roadmap issue) | ~16 | 16% |
| lane-density (maintainer building it now) | ~14 | 14% |
| exclusivity / PR-DIFF (open or closed PR, public branch, fork) | ~13 | 13% |
| six-check / philosophy (declined, "make a plugin", conformance-pinned, numbered plan) | ~11 | 11% |
| stage 6 guard (standalone file / post-pass) | ~7 | 7% |
| derivative overlap with our own earlier problem | ~3 | 3% |
| gate 1 (no observable gap) | 1 | 1% |
| signature account in lane | 1 | 1% |
| Requirement 7 / activity / licence | 0 | 0% |

Counts are approximate where an auditor gave two gates for one lane; the first gate was counted.

## Why we keep finding nothing (diagnosis)
1. **Going in, the suspicion was over-strict hunt gates. The data says the lanes are genuinely small.**
   - The briefs had stacked three discounts on top of the 200 floor: a 0.5-0.8x shrink, a leanest-passer >= 180, and "< 350 sketch is not evidence".
   - For calibration, I measured the 128 accepted reference solutions with the hook. The median is 445, and 15 were accepted under 250 (featurevisor 164, pict 214, piscsi 221, bayesopt 242, worldengine 251). So a ~220 reference is shippable.
   - I replaced the discounts with WRITTEN sketches. The 7 written lanes measured 60, 89, 90, 140, 150, 151 and 212 human-effective. Head estimates had been 1.3-2x higher.
   - The repeated deaths are therefore real absorption, not gate strictness. Only Requirement 7, licence and activity never killed anything.
2. **Our accepted problem already took each repo's one dense capability.** What is left in a well-factored repo is:
   - a missing arm,
   - a call-through to an existing extension point (wirefilter `Compiler` trait, Cider's PassManager, calyx `Rewriter` and `from_ast`, ray-optics math.js `transform`, planetiler `VectorTile.decode` + `FieldType::merge`),
   - or a famous algorithm with a sibling crib (Barnes priority flood, mem2reg, FieldMask utils, D* Lite).

   Absorption is 35% of all kills. On every repo, the first lanes to die were the ones the maintainer is building or has already designed in an issue.
3. **Why peers can ship ~12 per repo when we cannot find a second lane.** They take exactly the lanes our gates kill as magnets / obvious-next-step / maintainer-designed issues (16% + 11% of kills here). Our three platform overlap deaths (pyfakefs advisory locks 79%, dyn4j 53%, openglobus 47%) were all against OLDER foreign tasks in those same obvious lanes.
   - By the time we arrive, the obvious lanes are taken (an overlap risk for us), and the non-obvious lanes are small (absorption).
   - The second-lane pool is a residue, and it has now been audited for every approved repo that clears the mechanical screens: hunts #35, #37, #53, #54, #55 and this one.
4. **The only lanes priced above 230 died on non-size gates.** These are the real policy levers, if the human wants one:
   - protobuf-es .proto source printer (~350) and descriptor validator (~250): both stage 6 Q3, standalone file;
   - quint state-space estimate (~250): magnet, maintainer-authored #1566;
   - protobuf-es FieldMask set ops (~250): magnet #1177 plus our own kernel;
   - quint ITF replay (~300): exclusivity, open PoC #1873, a true wall;
   - tippecanoe overzoom rejoin (~250): maintainer draft #551.

   None was relaxable under the rules I was given (stage 6 and magnet are documented death classes), so none is returned.

## Stage 0 cache and fresh sweeps
- **Cached index.** The star-band index (`seen_any.txt`, 26k slugs) was used as a second dead-list. Hunts #50-#52 had already read every engine row with 0 survivors, so it was not re-triaged row by row.
- **Sweep 1.** Topic search over 48 unused domain topics (geodesy, seismology, acoustics, spectroscopy, ephemeris, pcb, spice, plc, timetabling, phylogenetics, genomics, gtfs, gnss, point-cloud, nurbs, rule-engine, bpmn, petri-net, model-checking, ...), star ceiling 8000, dead-list filtered.
  - 180 rows, 105 not in our logs. 81 of those were already in the cache.
  - The 24 new rows are ML apps, LLM tooling, end-of-life engines (camunda 7) or GUIs. 0 engine-shaped survivors.
- **Sweep 2.** 23 engine-shaped topics never used before (physics-engine, dsp, layout-engine, query-engine, spreadsheet, formula, computer-algebra, theorem-prover, type-checker, template-engine, storage-engine, key-value, event-sourcing, stream-processing, state-machine, ...).
  - 199 rows, 124 not in our logs, 16 not in the cache.
  - Those 16 are caching wrappers, reference examples, a famous-spec reimplementation (redka = Redis on SQL), formatters wrapping prettier, and a small template language (hmpl).
  - 0 survivors.

## Stage 6 death-class guard
Not run on a RANK 1, because there is none. The single WEAK lane was checked:
- ray-optics M+R: Q1 yes (one template-rewrite kernel). Q2 partial. Q3 no (it needs Scene and ModuleObj). Guard #1 risk: it reads as "add N operations".
- At 212 written it is under the 230 VIABLE bar. It is not returned.

## What the next hunt should change
1. **Stop second-lane audits of the approved pool.**
   - Every approved repo that passes the mechanical screen now has a multi-lane verdict, and every written sketch landed at 60-212.
   - Re-open a repo only when its maintainer ships a NEW subsystem; then audit that subsystem's first gaps.
2. **Bring the human three decisions, since the rules themselves now decide the outcome:**
   - (a) Accept a ~210-220 human-eff lane with a weak second lever (ray-optics M+R, 212 written; the accepted corpus has 15 picks under 250). If yes, ray-optics M+R is ready for a measure-first spike.
   - (b) Allow a standalone-file lane above ~300 eff when its hidden wall is repo-internal (protobuf-es .proto printer: field-level decisions in `source-code-info.ts:176`, editions, extensions). It is a documented Stage 6 death class today.
   - (c) Accept maintainer-authored roadmap issues with no PR (quint #1566 state-space estimate) as lanes. They are magnets today.
3. **If broad discovery resumes, do not use topic search for it.** Two sweeps returned 0 engine survivors, and 81-87% of hits were already cached. Better yield is likely:
   - newly-crossed-500-star repos (created or crossed in the last 6 months);
   - dependents of our approved repos' domains (org siblings were done in `h_orgsib`).
4. **Signature accounts:** SahilRajputdotexe was added. Consider scadastrangelove.
