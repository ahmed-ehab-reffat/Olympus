# REPO-HUNT-2026-09-24-C (hunt #32, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0924h32/`.
(Session was cut once mid-sweep by an orchestrator restart; sweep and filter were resumed from their
jsonl checkpoints. No workshop sub-agents were running at the cut.)

## Standing inputs
- Hint from hunt #31 (09-24-B): size each mechanism separately, spike a lane before killing it on LOC.
  In the pipeline, do not return: macs3-project/MACS (SLICING), softdevteam/grmtools (HUNTED).
  asdf lane 1 and 3DTilesRendererJS are recorded WEAK fallbacks; urbansim DEAD.
- Excluded: every LEDGER repo (20 table rows plus every slug in the log, 237 slugs,
  `s_0924h32/ledger_slugs_h32.txt`), every `problems/` folder (bayesopt, hayro, macs, pict, piscsi,
  ray-optics, riff, teavm).
- Requirement 0 (platform picker): cannot be checked here -> OWED on any candidate.
- Softening: misses=0, so the 2026-09-09-B rules apply as written; no star/issue window widened.
  Relaxations taken: none.

## Stage 0-bis — proven pool
Pool rebuilt from frontmatter (82 repos: 64 at 1 sub, 16 at 2, 2 at 3). No approval since hunt #31
outside the LEDGER (pyocd, pyfakefs, csbindgen, siliconcompiler, libspatialindex are LEDGER rows =
taken). Every other pool repo carries a lane verdict in 09-19-H .. 09-24-B (J group P, P Stage 0-bis,
the per-repo lines re-read here: goblin derivative, golang/geo port, trustfall exclusivity, pysmt
PR-blanketed, orb derivative, taplo/rust-url PR-blanketed + famous spec, iwe consuming, toydb
teaching repo, barcode named symbologies, go-workflows AI sweep, lifelines dormant+rivals,
python-control/numbat/awkward swarms, ir-sim consuming, tippecanoe/planetiler lanes <=180).
Nothing to spike. Not re-derived.

## Cached index
Seen union (74,595 slugs, `s_0924h31/seen_union.txt`) plus deadlist_all/v12 is exhausted per the
K/O/B logs (~95% of any in-scope 500-6000 bin). Not re-triaged; used only as the exclusion set for
the fresh sweep below.

## Fresh sweep 1 — the language-classification blind spot (new axis)
Every band / topic / delta sweep so far filtered on GitHub's PRIMARY language (the seven supported
ones, plus jupyter/cython/tex/cmake/shell/html/makefile in band_misc and C in c_langs). A language
processor whose TEST CORPUS is in the language it processes gets classified by the corpus (a Rust
Lua tool reads "Lua", a Python HDL tool reads "Verilog", a C++ shader compiler reads "GLSL"), so the
exact anchor shape of this skill was invisible to all of them. The platform gate only needs a
supported language primary or top-3 with a real share.
Script `s_0924h32/sweep_seclang_h32.py` (+ `sweep_seclang2_h32.py` resume): ~160 non-supported
primary languages, 500-8000 stars, pushed after 2025-09-24, licence filtered client-side.
Six qualifiers are not GitHub languages and silently return EVERY repo (rego, dot, metapost,
spinalhdl, chisel, veryl: total_count 57,547); the resumed script skips a language whose unsplit
count exceeds 15,000. Tooling note for the next hunter: always sanity-check total_count per new
`language:` qualifier.
Result: 24,651 rows (with the rego junk), **1,102 unseen + allowlisted + non-junk rows in a
fixture-heavy primary language** (`filter_seclang_h32.py`, languages API per repo ->
`langs_h32.jsonl`). Kept where a supported language is top-3 at >= 20%: ~150 rows, and by eye the
blind spot is SMALL and mostly not the shape we wanted:
- Kotlin/Scala/Groovy/Elm/R/Perl/Haskell/Nix/Solidity/PLpgSQL primaries with Java/JS/Python as the
  second language are apps, Android libraries, Spark/big-data platforms, wrappers and Gradle plugins.
  The implementation is in the unsupported language, so there is nothing to author in.
- The true "fixture corpus classified as primary" rows are few and all dead on shape or build:
  KhronosGroup/SPIRV-Cross (GLSL 57 / C++ 31; every lane is a spec-named SPIR-V/GLSL/MSL feature,
  test harness needs glslang + spirv-tools binaries), google/clspv, intel/llvm, llvm-mos, DeNA/DeClang,
  openxla/stablehlo, google/heir (full LLVM/MLIR builds, L62), cdisselkoen/llvm-ir (llvm-sys),
  xgo-dev/llgo (LLVM + cgo), vortexgpgpu/vortex (RTL simulator), BLAKE3 (famous crypto spec),
  kamadorueda/alejandra (Unlicense, not on the allowlist), terminusdb (Rust 8.6%, third),
  struppigel/PortEx (Scala/Java PE parser, spec-named format), walmartlabs/lacinia (Clojure).
Survivors: none. Lesson: GitHub's language classification is NOT hiding a population of language
processors in the supported languages; the 74.6k seen union already had them (a Rust 700-800 probe
without a licence qualifier: 99/100 seen, including the NULL-licence rows).

## Cached index re-reads (lanes noted once and never audited)
- tdewolff/minify (Go ★4141, noted in 09-20-D as "other lanes unvetted"): DEAD. Three signature
  accounts in 90 days (`binggao1230`/`gaoflow` #1006, `jackwalkerlabs` #1032/#1033 created
  2026-07-10 with a scattershot footprint, `hdimer` #1008), a prior foreign sub (minify-css-source-maps,
  scope-gate publicly-solved), the unit-conversion lane is a commented-out draft in mainline, and
  the maintainer posted "Limit GenAI scraping efforts".
- Chevrotain/chevrotain (TS ★2804, "parked" in an older log): DEAD. Solo `bd82` perf stream (dense-DFA
  lookahead PR #2199 open), root AGENTS.md + AI-authored commits (penalty), syntactic content assist
  REMOVED in #2161 (cannot be restored), LL(*) lives in the sibling `chevrotain-allstar`, macros #1004
  = our approved parameterized-rules class, EBNF export #294 = long-open magnet and a GAST post-pass.
- janino-compiler/janino: 0 commits in 12 months (Req 3). erikrose/parsimonious: 1 version bump in
  12 months (Req 6 corpse). HubSpot/jinjava, PebbleTemplates/pebble, alibaba/QLExpress: template /
  expression language surfaces (famous-language-feature carve-out); QLExpress also ★5634 mid v4 rewrite.

## Fresh sweep 2 — lane-first: maintainer-welcome phrases in 2026 issues (new axis)
Every sweep so far was repo-first. This one searched ISSUES (`sweep_welcome_h32.sh` +
`sweep_welcome2_h32.sh`): `is:issue is:open created:>2026-01-01` x 10 welcome phrases ("would welcome
a PR", "PRs welcome", "happy to accept a PR", "feel free to open a PR", ...) x go/rust/python/cpp/
java/typescript, joined to the cached metadata map (`meta_map_h32.json`, 79.7k repos) for the
500-8000 band. 3,855 issue rows; after band + dead-list + an engine-vocabulary screen on the repo
description, 111 repos. By eye: MCP servers, agent harnesses, k8s operators, observability,
RL/ML training code, SDKs. The only engine-shaped rows are famous specs or heavy builds:
apache/sedona-db (DataFusion workspace, Apache-project velocity), toml-rs/toml, pydantic/jiter,
miyuchina/mistletoe (CommonMark), seaql/sea-query (SQL), osrg/gobgp (BGP RFCs), meilisearch/heed
(LMDB C binding). Survivors: none. Lesson: "PR welcome" phrasing in 2026 is dominated by AI-tooling
repos; the phrase-level lane finder does not reach engines. Do not repeat this axis.

## Workshop (1 spike sub-agent, finished before return) — greatscottgadgets/luna Lane A
Why this lane: it was the last never-spiked paper-WEAK lane in a gate-clean repo (09-23-M dossier
`s_0923h26/agents/luna.md`: ~240 / ~150 on paper, 255/170 with a function-side halt writer), and the
standing lesson said stateful multi-stage lanes ran 40-65% low on paper. Re-verified here: Python
100%, BSD-3 (Temkin / GSG), `simulations` workflow green on `main` every week through 2026-09-21,
9 real code commits in 12 months (USB3 PHY), open PRs unchanged (#305/#304/#301), no lane issue/PR
since 09-01, only gregdavill's fork pushed since 09-20 (already diffed clean).
**Spike result: DEAD.** Working prototype (descriptor-driven chapter-9 state: validated
SET_CONFIGURATION, SET/GET_INTERFACE, ENDPOINT_HALT set/clear, GET_STATUS x3, scoped data-toggle
resets, halted IN/OUT/PING STALL with the buffered IN packet kept, OUT boundary drop, function-side
halt writer), 28/28 F2P probes (base fails most of them), full suite 93/93, no regressions.
**Measured 217 human-eff** (raw 298, padding-floor 160, 10 files), **core ~120-130**. Per mechanism:
descriptor walk 29 (paper 22), state table 55 (35), request FSM 61 (100), plumbing 25 (24), IN
halt/reset ~14 + OUT ~18 (37), status/iso gating 13 (18), halt writer ~6 (20). The paper sketch ran
HIGH this time (240 -> 217), because the FSM arms were over-counted.
Guard: Q1 yes (one handler-side table feeds GET_STATUS, validation, endpoint gating). Q2 mostly
independent cases, and the predicted T1 wall (inverted PID storage) is NOT reachable: the control
request's own SETUP token moves the IN manager to WAIT_TO_SEND before the reset fires, so driving
the existing `reset_sequence` is right everywhere. The one new misdirecting trap is
`handle_register_write_request(stall_condition=...)` never returning the FSM to IDLE after a stall.
Q4 #4 partial fail (chapter 9 is a known spec, facedancer implements it) and **#5 fails: the
spiker's first draft passed every probe (~35 min of gateware, zero implementation bugs).** Only lever
past 250 is DEVICE_REMOTE_WAKEUP (+40-60, unmeasured) or USB3 parity (+60, sibling copy, not core).
Patch + probes: `s_0924h32/luna_spike/` (clone restored to 82a8f73, venv deleted).
Lesson for the ledger of paper sketches: 5 spikes now, in both directions (riff +80%, MACS +64%,
grmtools +51% with the unsized piece model; asdf -10%, luna -10%, cartopy -50%). The under-count
held only where the paper left a whole MECHANISM unsized; where every mechanism was listed, paper was
within 10% or high. Spike when a mechanism is missing from the table, not by default.

## Result: NO-CANDIDATE
Tried: proven pool (nothing new, every repo carries a 09-19..09-24 lane verdict); cached index
(exhausted; re-read minify, chevrotain, janino, parsimonious, jinjava, pebble, QLExpress: all dead);
fresh sweep 1 (language-classification blind spot, ~160 non-supported primary languages, 1,102
unseen rows language-profiled, 0 survivors); fresh sweep 2 (lane-first maintainer-welcome issue
search, 3,855 issues -> 111 band repos, 0 engine-shaped survivors); one spike (luna Lane A, 217
measured, guard #5 fails).
Fallbacks carried forward (both WEAK, unchanged from 09-24-B): asdf-format/asdf (lazy_tree
pass-through write, measured 176 / core ~140, enmime Rewrite class overlap);
NASA-AMMOS/3DTilesRendererJS (3D Tiles 1.1 multiple contents, spike 133 / honest ~215/115,
spec-named, #608 plan). Dead this hunt: luna Lane A, minify, chevrotain, the two sweep axes.
Next hunt should change: stop sweeping GitHub. Every discovery axis now reads exhausted (star band,
topics, created-year, size, dependents, org siblings, delta-by-push, secondary-language, NULL
licence, issue-first). Two options remain: (a) a COMPOSITE pick in one gate-clean repo whose single
lanes each measured 140-215 (asdf lane 1 + #1795 conversion-free info/search share the lazy tree and
the block manager; 3DTiles multiple-contents + implicit availability), spiked as ONE coupled design
and guarded on whether the two halves share a kernel; or (b) ask the human for new anchor repos or
platform-side repo lists, since the in-scope public universe has been read to ~99%.
Disk: / 12G free. No build output left; clone `j_0920/luna` restored clean; scratch 18M.
