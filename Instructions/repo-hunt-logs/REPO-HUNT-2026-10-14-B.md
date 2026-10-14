# REPO-HUNT-2026-10-14-B (hunter #64, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **CANDIDATE yeslogic/allsorts, instance layout variations** (written sketch 280 human-effective over 5 files).

Scratch: `worktrees/_hunt/s_1014h64/`. It holds:
- the screener `mech_h64.sh` (h63's 400-PR bot-filtered signature scan plus new-account profile) and its outputs `mech*_h64.out`, `_c_*.tsv`, `_p_*.tsv`;
- the two fresh-sweep scripts and outputs: `crates_h64.py` / `crates_slugs_h64.tsv` / `crates_join_h64.tsv` and `npm_h64.py` / `npm_slugs_h64.tsv` / `npm_join_h64.tsv`, plus the band join `join_h64.py`;
- the agent brief `AGENT_BRIEF_h64.md` (h64 block on top of the h63 brief);
- dossiers `dossier_{allsorts,typify,umbrella,peggy,ohm,ropey,hayagriva}_h64.md` and tracker dumps;
- sketches `sketch_allsorts_layout-instancing_h64.patch` (280) and `sketch_umbrella_blockfs-compact_h64.patch` (130);
- `judged_add_h64.tsv` (the rows appended to `judged.tsv`; backup `judged.bak_h64`).

Clone kept: `worktrees/_hunt/s_1014h64/allsorts` (30M, sparse: src/, tests/*.rs, tests/fonts/variable, tests/fonts/opentype/cff2; sketch applied uncommitted on HEAD `efab0fc7`). Every other clone was deleted. Nothing was built. Disk `/` stayed at 4.3G free.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):** lane-only exclusion; only repo-scope verdicts block a repo; ~505 star margin; written 220 return bar; Q3 waiver only above ~300 with an internal wall; submission count reported, never gated.
- **Not relaxed:** maintainer-roadmap magnet, AI-sweep, velocity and signature rules; the 2026-10-13 tracker-named-lane rule.
- **Softening:** misses = 0, none taken. No star or issue window widened.
- **Requirement 0:** OWED.
- **Excluded lanes:** Cwerg compact unions (HUNTED), any JFryy/qq lane, pint, commafeed, aptly, ray-optics module inlining, csbindgen const-expression, micasa, mirrorbits, every CLAIMED row.
- **Hunter #63's hint:** re-audit proven repos the week their in-flight lane is accepted. No in-flight lane resolved since #63 (tracker `REVERT-RECALIBRATION-2026-10.md`: last acceptance macs-callvar 10-13, already audited by #63). eventsourcing (shelved 10-11, user asked to consider its unused scope): default branch is still `9.5` (10.0 only as alpha tags), so #54's "re-audit once 10.0 is default" stands; the suggested scope (fork snapshots up to the cut, notification log at the cut) extends our own rejected cut core and was not pursued.

## Stage 0-bis: proven pool
94 frontmatter repos counted. Mechanical re-screen (`mech1_h64.out`) of 30 pool repos whose newest verdict was a seed row or older than the recent lane audits:

| Repo | Reading |
|---|---|
| pysmt | 122 commits (mikand), CI green, no signature; every lane under open PR diffs or mikand's stream (09-20-B / 09-29 verdicts stand) |
| tifffile | no test workflow (Req 7, repo-scope row) |
| surrealkv | 1.0 firehose, 299 commits, every storage lane live |
| openexr | most of the last 100 commits carry AI trailers |
| kapture | 24 commits, all releases (10-05-F stands) |
| icu4x | 98 open PRs, corporate team, port of ICU4C/J |
| starlark-go | 31 open PRs publish capability diffs (regexp, f-strings, `**`, profiler hooks) |
| rust-minidump, customasm, neva, grmtools, riff, kira, featurevisor, csbindgen, sfepy (25 foreign subs), gluon | covered by 10-05 / 10-14 lane audits; nothing new |
| hayro | LaurenzV 268/300 commits, SAY-5 x1 (10-05-F WEAK stands) |
| awkward, petl, pandapower, python-control, scikit-fem, h5py | signature accounts or AI trailers (69 on awkward) |
| avo, lifelines, go-astits, mtail | bot-only / near-dormant |

Expired lane verdicts (> 60 days) re-screened: encounter/objdiff (community fix stream in every arch lane, SAY-5 x2), googlefonts/fontations (**burst** metsw24-max x11, repo row), statrs (4 signature accounts + red Tests, repo row), MikePopoloski/slang (SystemVerilog spec sweep, hankhsu1996 burst of fixes), JetBrains/fernflower (monorepo mirror, PRs disabled). **Pool produced nothing.**

## Stage 0: cache tier
Reserved WEAK fallbacks from earlier logs (rain, dstask, 3DTilesRendererJS, dinit, lektor, kuva, inline-snapshot) were re-read: none had a new lever and all are under 60 days. Not re-spiked.

## Fresh sweep 1 (of 2): crates.io category lens (new lens)
- 36 crates.io categories (compilers, parser-implementations, emulators, simulation, science, mathematics, multimedia, rendering, database-implementations, text-processing, encoding, algorithms, ...), top 300 crates each by recent downloads: **4,916** GitHub slugs.
- Joined to the cached band (500-15000, pushed in 12 months, not repo-dead, not pool): **509 rows, 489 with no judged row.**
- 36 screened mechanically (`mechcr1-4_h64.out`). Kills: signature (logos, lopdf, palette, rust-decimal, swash: repo rows), corpses (madsim, salva, ascent, plastic, Clarabel 1 commit), dormant-with-PR-queue magnets (hftbacktest, barter-rs, syntect 67 PRs), firehoses or AI sweeps (fjall, lindera, mcap, takumi, parley, ggrs June AI sweep), FUTURE.md roadmap + -sys dev-deps (fundsp), red test CI (RustQuant, binrw), named specs (dicom-rs, liquid-rust).
- Lane-audited (agents): typify, allsorts, ropey, hayagriva.

## Fresh sweep 2 (of 2): npm keyword lens (new lens)
- 150 npm keywords (compiler, peg, grammar, geometry, cad, font, typesetting, solver, simulator, bpmn, crdt, ...): **27,787** slugs; 1,166 in the band; mostly apps/frameworks.
- 12 screened (`mechnp1-2_h64.out`): json-joy (root AGPL-3.0, repo row), automerge-repo (cpruijsen x2), FluidCAD and cad-viewer (firehoses, 22 AI trailers on cad-viewer), bpmn-engine/wavedrom (near-dormant), replicad (pages-only CI).
- Lane-audited (agents): thi-ng/umbrella, peggy, ohm.

## Lane audits (4 parallel agents, 8 repos, 46 lanes)

| Repo | Verdict | Best lane / killing gate |
|---|---|---|
| **yeslogic/allsorts** | **VIABLE** | A1 instance layout variations, **280 written**. A2 layout subsetting #64 + skera crib, A3 AOTS stale marker, A4 #31/#29, A5 #59, A6 #95/#96/#116 |
| oxidecomputer/typify | DEAD | maintainer moving the type model into oxidecomputer/typespace (draft PR #1088 deletes cycles/defaults/value); rest tracker-named or under PRs #1086/#987/#1041; our typify-object-applicators files |
| thi-ng/umbrella | DEAD | 8 packages; engine gaps are README roadmaps, #96/#546/#547, live branches feature/parse-packrat and csp-refactor; best cold lane block-fs compaction **130 written** |
| peggyjs/peggy | DEAD | 7 lanes tracker-named (#576, #187, #592, #577), declined (#587), maintainer self-request (#634), ohm-js incremental crib |
| ohmjs/ohm | DEAD | v18 migration guide is a maintainer roadmap and v17 in-repo ships each gap; PR #481 indentation |
| cessen/ropey | DEAD | written scope policy declines marks/metadata/graphemes/columns (#97, #19, #29, #75); in-scope kernels ship on the 2.x branch |
| typst/hayagriva | DEAD (repo) | NOTICE puts bundled CSL styles/locales under CC-BY-SA 3.0 (overturns the 07-31 licence reading) |

## RANK 1 dossier: yeslogic/allsorts, instance layout variations

**Repo facts:**
- https://github.com/yeslogic/allsorts, ★802, Apache-2.0 (LICENSE read; nothing vendored; test fonts are fixtures with their own licences). Rust 92%.
- Default branch master, HEAD `efab0fc769287f4ced68bbd723c328c9d9b89698` (2026-05-13).
- 43 commits in 12 months (mikeday 20, wezm 12, fschutt 3, six others); real code commits (Requirement 6 OK).
- CI `ci.yml` runs `cargo test` across toolchains and OSes; latest master run success; the two failures (04-01, 04-16) are only `ci (nightly, macos-latest)` with no step run (runner issue).
- 28 open issues, 1 open PR (#134, Cargo deps). No signature accounts in 400 PRs; AI marks (one jules bot commit in layout.rs, "fixes from clippy and Claude") are outside the lane: note.
- **Our submission count: 0.** SATURATED-REPOS row (2026-08-04) is lane-level ("NOT saturated, NOT blocked"; AOTS lane dead). The 10-02 "already dead: allsorts" generalised that lane death to the repo and is overturned.

**Capability:** `allsorts::variations::instance` currently rebuilds head/hhea/hmtx/maxp/name/OS2/post/cvt/glyf at the instancing tuple and copies every other table verbatim (`variations.rs:412-422`, `is_var_table` 544-547), so GSUB, GPOS, GDEF, vhea and vmtx keep their variable form while fvar/HVAR/VVAR are dropped. The lane makes the static instance shape like the variable font did: bake GSUB/GPOS FeatureVariations into the default FeatureList, fold GPOS VariationIndex device deltas into value records, drop the GDEF variation store, rebuild vmtx (VVAR or gvar phantom points 3/4) and apply MVAR to vhea.
- Outsider summary: "make allsorts' variable-font instancer also instance the OpenType layout tables and vertical metrics." Outsider-nameable (fontTools varLib.instancer does it), so Stage 2b MEDIUM; no issue or PR names it, so not a magnet kill.

**Gate 1 (from code; runtime probe OWED):** with no fvar the instance is shaped with `tuple = None`, so `gsub.rs:1378 feature_variations(None)` applies no substitution and `gpos.rs:613` adds zero delta; `Font::shape(.., Some(tuple), ..)` on the variable font applies both. In-repo fixture `tests/fonts/opentype/cff2/SourceSansVariable-Roman.abc.otf` has GDEF 1.3 with an ItemVariationStore and VariationIndex devices in a PairPos format 2. No in-repo font has FeatureVariations: tests must build one with the public FontBuilder or add a binary fixture.

**Missing machinery:** allsorts has no writer for GSUB/GPOS/GDEF, so the instancer must rewrite layout bytes itself (FeatureList rebuild with 16-bit header relocation, value-record walker over Single/Pair formats and extension lookups), plus a vmtx rebuild path.

**Written sketch:** `sketch_allsorts_layout-instancing_h64.patch`, re-measured by me: **human-effective 280** (raw 370; layout/instance.rs 207, variations.rs 64, layout.rs 7, gsub.rs 1, tag.rs 1), padding-floor 56 (repetitive byte helpers; ReadScope/WriteBuffer can replace some).

**Traps (interdependent, misdirecting):**
1. **rvrn gate (F-67/F-9):** `gsub.rs:1391` runs `apply_rvrn` only `if tuple.is_some()`. A correct FeatureList bake still loses rvrn substitutions on the instance (shaped with None); the failing glyph points at the bake, which is right.
2. **16-bit relocation (F-1/F-9):** alternate Feature tables live under the Offset32 FeatureVariations region; rebuilding the FeatureList shifts ScriptList/LookupList, and the GPOS walker must run on the relocated buffer.
3. **Lookups live only through an alternate feature (F-84 analogue):** a walker that bakes only lookups reachable from the default FeatureList misses them. Coupled to 2.
4. **Repo oracle semantics (F-8):** allsorts rounds per field, ignores placement deltas when both base placements are 0, ignores records with non-zero y_advance, ignores hinting devices and never varies anchors (`gpos.rs:547-571`, `layout.rs:1718-1731`). A fontTools-faithful baker diverges; meta must state these or the fixtures must avoid them (oracle-semantics memory).
- Second lever (written): vertical metrics (VVAR, else gvar phantom points) + vhea MVAR. Lift lever (not written): honour and bake format-3 anchor deltas (gpos.rs + baker, ~120 eff, not tracker-named; #36 is only an API-visibility request).

**Six-check / exclusivity (re-run by me, canonical slug confirmed):** searches for instance, instancing, variation, FeatureVariations, variable font, vmtx, GPOS, GDEF, rvrn, static: only #51 (closed by the 0.15 instancer), #114 (closed, outlines), #59 (vhea/vmtx SUBSETTING, adjacent), #64 (GSUB/GPOS subsetting), #116 (COLR variations). No PR, no branch in the lane (branches: alfie/sec-fix, allsorts0.15, allsorts-0.14, ci-no-default-features, mikeday/fixes, morx, wezm/*). Forks: no newer feature work in the lane. variations.rs has no commit in 12 months. No philosophy statement; the passthrough comment ("important for ensuring GPOS/GSUB etc are included") records a choice, nothing declines baking.

**Sibling crib:** skera (fontations' hb-subset port) has explicit instancing TODOs (`skera/src/lib.rs:871`, `:1234`); rustybuzz/ttf-parser are read-only. The algorithm is public in fontTools (Python) and hb-subset (C++), and the agent reported a GPL-3.0 Rust app (googlefonts/slice-web) with a feature-vars instancer; neither is built on allsorts' read-only model, and the allsorts walls (no layout writer, rvrn gate, shaper quirks) are not cribbable. Risk recorded for the precheck.

**Stage 6 death-class guard (run by me):**
- Q1 one shared kernel: YES. The instancing tuple decides which lookups are live and their values on one relocated buffer, feeding GSUB shaping, GPOS positioning and vertical metrics.
- Q2 interdependent: YES for 1<->bake (either fix alone fails) and 2<->3 (relocation before walking; substitution decides live lookups). Trap 4 is independent and is handled by the meta cap.
- Q3 standalone file: **NO** on the written 280. A new layout/instance.rs alone fails trap 1 (the shaper's rvrn gate in gsub.rs must change, or rvrn lookups must be remapped into an always-on feature) and does not deliver the vertical-metrics half, which lives inside the existing instance() table-rebuild path in variations.rs. 280 is under the ~300 waiver line, so the waiver is not used; the anchor lever would lift it above 300 and make the lane shaper + instancer. Not a printer back to a compiled format: it transforms within the same format (the hayro OC-baking shape, which was accepted).
- Q4 TOO-EASY Pre-Pick Guard: #1 no (several mechanisms: feature substitution, delta folding, relocation, metrics); #2 no (instancer + shaper + metrics, hidden integration walls 1 and 2); #3 no (traps survive being stated); #4 partial (OpenType semantics are a known spec, but the oracle is allsorts' own shaper with its quirks); #5 yes (relocation and the rvrn gate survive full specification).
- **Guard: PASS** (Q3 is the main risk; builder should take the anchor lever if the slice measures under ~300).

**Docker:** Pattern A, `olympus-base-rust`. Build with `--no-default-features --features flate2_rust` (default `flate2_zlib` pulls C zlib). Dev-deps: regex only. 2026-08-04 measured 776 tests, 84 s, deterministic 3x.

**Tests:** `cargo test --no-default-features --features flate2_rust`. A new `tests/instance_layout_<hex>.rs` calls `variations::instance`, loads the bytes with `ReadScope`/`OpenTypeFont`/`Font::new`, and compares `Font::shape(.., None, ..)` on the instance with the variable font shaped with `Some(tuple)`.

**Nova reading surface:** ~15 KLOC over 12 files (variations 1400, layout 3616, gsub 1871, gpos 994, glyph_position 619, variable_fonts 1558 + fvar/hvar/mvar ~900, subset/FontBuilder 1888, font 1580, binary/read 1153) plus OpenType byte layouts reconstructed by hand.

**Risks:** outsider-nameable capability (fontTools instancer) = derivative MEDIUM, mitigated by phrasing on allsorts' model (instance shaped with no tuple == variable font shaped at the tuple); public algorithm in fontTools/hb-subset (scope-gate crib risk, the walls are repo-specific); fixture authoring for FeatureVariations; repo last commit 2026-05-13 (active within 12 months, quiet since); runtime probe and LOC slice owed.

## Fallbacks
None returnable. Best non-returned: thi-ng/umbrella block-fs compaction (130 written, standalone, DEAD).

## Verdict rows and signature accounts
- `judged.tsv`: 53 rows appended (backup `s_1014h64/judged.bak_h64`). Repo-scope: statrs, fontations, tifffile, fernflower, swash, json-joy, logos, lopdf, palette, rust-decimal, hayagriva. The rest are lane-scope, including the allsorts RANK 1 row.
- `sig_accounts.txt`: added `spokodev` (created 2025-10, 378 repos, scattershot across ~35 JS libraries; one merged peggy codegen PR).

## What the next hunt should change
1. **Package-registry lenses work where description lenses saturated.** crates.io categories surfaced allsorts (whose lane verdict had been wrongly generalised to the repo) among 489 never-judged rows; ~450 of those rows are still unscreened. Next: screen the rest of `crates_join_h64.tsv`, and try PyPI classifiers (via a mirror listing) and Maven/Go equivalents.
2. **Re-open repos whose "dead" is a generalised lane verdict.** allsorts was recorded dead after two lane deaths; the deciding file (variations.rs) was never opened. Grep logs for "already dead" rows without a repo-level reason.
3. **Read NOTICE / THIRD-PARTY files** in licence checks (hayagriva's CC-BY-SA CSL data).
