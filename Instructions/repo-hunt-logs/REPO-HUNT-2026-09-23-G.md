# REPO-HUNT 2026-09-23-G

Unattended `olympus-factory` hunt worker (hunter #20). `CONSECUTIVE_MISSES=1`, so the standard
(already softened 2026-09-09-B) rules apply and no star/issue windows are widened (widening starts at
n >= 2). Standing rules (user, 2026-09-23): a root AGENTS.md / CLAUDE.md is a ranking penalty; AI
commits in the 90-day stream are lane-scoped (SKILL.md 2b). NEW mandatory gate from hunt #19: a
fork-branch exclusivity scan (forks?sort=newest + non-upstream branch compare + grep of
`agents/adx-labtesing-deepswe-forks.txt` and `sig_accounts.txt`) in every lane audit. Requirement 0
(platform picker) is OWED on anything handed over.
Scratch: `worktrees/_hunt/s_0923h20/`.

**Task (hint from hunt #19):** the cached index has been read by eye; use a GENUINELY NEW SOURCE:
(a) reverse dependencies (PyPI / crates.io / npm / Go proxy / Maven) of libraries in
approved-problems/ (engines built ON an approved repo's domain), (b) org-mates and other repos of
approved-problem maintainers. `s_0923h19/unjudged_noeng.tsv` only as a last resort. Pre-filter every
slug against `s_0923h14/seen14.txt`, `s_0923h17/dead17.txt`, h18/h19 lists. Excluded: bayes_opt
(SLICING), teavm (HANDOFF), tegaki + ArchUnit (bayes_opt fallbacks), genqlient, capnproto, every
LEDGER row, every problems/ repo, everything adjudicated in 09-23-C/-D/-E/-F.

## Stage 0-bis proven pool

EXHAUSTED (12th session). Pool rebuilt from frontmatter (`s_0923h20/pool.txt`, 78 repos) is identical
to hunt #19's up to slug case; no repo entered since. Nothing to reopen.

## New source (a): reverse dependencies of approved-problem libraries

Tooling: `packages.ecosyste.ms` `dependent_packages` (free, no key; carries `repo_metadata` with stars,
licence, language, pushed_at). Measured quirk: `sort=` breaks pagination (page 2 returns 0), so the
fetch uses unsorted `per_page=1000` pages. Seeds: 98 registry packages of approved-problem repos
(`s_0923h20/seeds.txt`: 47 PyPI, 27 crates, 8 npm, 13 Go modules, 4 Maven). Script `revdeps.sh` ->
`revdeps.jsonl`. Dead filter `s_0923h20/dead20.txt` (57,765 slugs = seen14 + dead17/18 + adjudicated
+ logged2 + touched + judged19 + every slug in hunt logs, LEDGER, SATURATED-REPOS, TOO-EASY, pool).

## New source (b): org-mates and top contributors of approved-problem repos

`orgmates.sh`: every repo >= 400 stars owned by each pool repo's owner, plus the own repos of each pool
repo's top-2 human contributors -> `orgmates.tsv` (878 rows). After the dead filter, in-scope
languages, permissive licence, pushed since 2025-10-01: 24 rows, all big-org products or famous
libraries (google/*: python-fire, cadvisor, go-cloud, snappy, google-java-format, j2objc, highway,
re2j, fuzztest, ...; golang/vscode-go, vulndb; pytest-dev plugins) plus Cysharp's C# family (out of
language scope). No engine-shaped, maintainer-owned niche repo. Source (b) is DRY: the pool owners'
other repos were already read by earlier hunts (the dead filter removed ~850 of 878).

### Source (a) verdict: DRY

`revdeps.jsonl`: 21,463 dependent packages over the 98 seeds (17,776 with GitHub metadata). Only 468
distinct repos reach 500 stars; 198 are outside the dead filter (`rd_new.tsv`), and they are apps,
web frameworks, infra (consul, coder, terraform providers, kubectl plugins), ML paper code
(lucidrains/*, kyegomez/*) or dormant (2022-2024 pushes). The dependents of the DOMAIN seeds
(pandapower 7, sfepy/scikit-fem 0-3, lifelines 23, pvlib 17, laspy 14, lyon 31, kira 17) are small
research packages far under 500 stars: engines built on an approved repo's domain are, almost by
construction, too niche for the star floor. Note: hunt 2026-09-19-H already swept crates.io reverse
deps of 16 approved crates, and 09-12 / 09-14-B swept conda-forge, Homebrew, vcpkg, Debian and crates.io
categories, so registry-graph sources were largely spent before this hunt.

## New source (c): DELTA sweep, live repos the cached index never saw

Rationale: the index is a snapshot; repos that crossed 500 stars, were created, or went live after it
was cached are invisible to every triage of it. `delta.py`: GitHub search per language
(rust go python typescript javascript cpp java), `stars:500..3000 pushed:>2026-08-15`, bands split
adaptively under the 1,000-result cap -> `delta.jsonl` (~16.8k live rows expected), then minus
`dead20.txt`.

Early reads while the sweep runs:
- **mahmoud/glom: DEAD (Stage 2b-bis + dormancy magnet).** BSD-3, 2.1k stars, a real spec-interpreter
  engine and never judged in any log. But 15 surgical-fix PRs from 13 distinct outside accounts
  since 2026-06 (`Sahana2524` x3, `binggao1230` x2 incl. one merged, `Jerry-val`, `oyeong011`,
  `Pitchfork-and-Torch`, `rupayon123`, `chiliec`, `arunsoman`, `chuenchen309`, `Eric3-jp`,
  `be-student`, ...: Iter sentinels, Match negation, flatten depth, Coalesce defaults, Delete
  ignore_missing, Path slicing) while the maintainer merged 2 in 12 months and added a PR template
  demanding AI-assistance disclosure on 2026-09-08. The repo is being mined as a surgical-bug farm;
  every lane is presumptively claimed.
- **binref/refinery: DEAD.** 1,164 solo commits in 90 days, 83 AI-marked, root CLAUDE.md: the unit
  catalogue is a firehose and consuming.

### Delta sweep result

`delta.jsonl`: 16,804 live rows (7 languages, stars 500-3000, pushed after 2026-08-15). **5,685 (34%)
are in no dead/seen/judged list** (`delta_new.tsv`); 2,269 permissive or NOASSERTION
(`delta_perm.tsv`); 401 match the engine vocabulary minus AI/LLM words (`delta_eng.tsv`). The delta
is dominated by infrastructure (k8s operators, cloud SDKs, terraform providers), apps, and 2025-2026
AI-agent projects, which is why engine-targeted index fetches never pulled it. Eye pass over the
engine rows plus the non-vocabulary rows created before 2025: engine-shaped survivors are
**microsoft/pict** (C++, MIT, combinatorial test generation with a constraint language), mahmoud/glom
(dead above), visjs/vis-timeline, jeremyckahn/shifty, benmoran56/esper, typograf/typograf,
brofield/simpleini, thestk/rtmidi, Samsung/rlottie, enjoy-digital/litedram (LiteX), danielhrisca/asammdf.


### microsoft/pict (delta survivor, full lane audit): FALLBACK only, fails the absorption sketch

Mechanical: MIT (LICENSE.TXT read), C++ 89%, 1,466 stars, real code commits in 12 months (DBCS
handling, best-of-N `/b`, thread pool `/t`, PictGenerate reset), CI `main.yml` runs `make test` +
ctest and is green on main; local `make` 5 s, `make test` rc=0 in ~10 s (perl golden-baseline
harness, `test/rel-baseline.log`). Root has no AGENTS/CLAUDE file but `.github/copilot-instructions.md`
(penalty), and the maintainers run a Copilot sweep over the tracker (`app/copilot-swe-agent` PRs #150,
#132, #152 and `danfiedler-msft` `copilot/*` fork branches): all docs/CI, none in generation code
(lane-scoped note). Fork scan (all forks pushed in 2025-2026, every non-upstream branch compared):
unicode fixes (ishikawa096), docs, CI, a .NET wrapper; no kernel work. Not in the LabTesing list or
sig_accounts. PR search negative / submodel / seed / alias: docs only. No signature accounts.

Architecture: CLI model + constraint parser (`cli/mparser`, `cparser`, `ctokenizer`) -> constraint
to exclusion translation (`cli/gcdexcl.cpp`) -> api model with a sub-model hierarchy of
pseudo-parameters (`api/model.cpp` `GenerateVirtualRoot`, `mapExclusionsToPseudoParameters`,
`mapRowSeedsToPseudoParameters`), with negative testing done as TWO CLI runs (`cli/gcd.cpp`
`Generate`: a positive run with negatives removed, a negative run keeping rows with a `~` value)
and "no two negatives" as synthetic pair exclusions (`gcdmodel.cpp:542`). Negativity never reaches
the api (F-9 shape: the CLI destroys it before the hierarchy sees it).

Reproduced on base:
- #44 negative values lost across sub-models: model `{C1,C2}@2 {D1,D2,D3}@2` with negatives in
  both -> every C negative (`C1=~0`, `C2=~0`) is absent from the output, silently. Root cause read:
  in the negative run the D sub-suite can have a negative in every row, so every (C-negative row,
  D row) pseudo pair is excluded and the C negatives have no partner. With seeds the seeded C
  negatives are dropped, and a two-valued variant trips `Assertion !iexcl->empty()` (issue text).
- #40 `/o:1` emits 3 constraint-violating rows of 33 (maintainer confirmed the bug); `/o:2` has 0.

Lane sketch (softened rule 5, sized against the chokepoint): "negative testing honoured across
sub-models" = give each sub-model's pseudo-parameter fully valid partner rows in the negative run
(~50-80 eff; a shortcut exists: append the positive-run sub-suite rows) + seeds carrying negatives
mapped through both runs (~40-60) + `/s` statistics (~20) = **~110-160 human-eff**. #40 is a
different root (order-1 exclusion enforcement), so adding it is a second independent bug, not a
coupled lever (L2). Alias-aware constraints (#130) and first-class parameter exclusion (#121) are
both absorbable by desugaring (expand aliases / the documented dummy-value technique) under any
property test, and golden-row tests are unfair for a generator. Arithmetic in constraints is
maintainer-refused (#110 "No."). Verdict: engine and F2P are real, but no lane clears ~150 eff
without a padding lever. Kept as a fallback for a hunt allowed to relax the LOC sketch.

Other delta / residual survivors, probed (`probe14.sh`) and dismissed: visjs/vis-timeline (renovate-
dominated, DOM-heavy, outside-PR magnet queue), jeremyckahn/shifty (0 human commits in 90 days),
typograf (AGENTS.md, rule catalogue), simpleini / rtmidi (small / hardware backends), litedram
(HDL cores, same class as the approved amaranth picks), jupyterlab/lumino (team, browser test
rig), LeaferJS (solo, no suite worth the name), bitburner (game, AGENTS.md, 112 commits/90d by a
community: consuming). Last-resort residual `s_0923h19/unjudged_noeng.tsv` cut against the dead list
and an infra/app/AI stop-list: 258 rows (`noeng_cut2.txt`), read by eye. Engine-shaped: ag-psd (PSD
read/write; sibling psd-tools / psd.js ship the format surface: sibling-library absorption),
josdejong/jsonrepair (famous format), _hyperscript (language-surface carve-out), ethercalc (262 solo
commits/90d + AGENTS.md), shader-slang/slang (NVIDIA/Khronos team). Nothing survives.

## Fresh sweep 2: delta for pushed 2026-06-01..2026-08-15 (colder but live band)

Same `delta.py` with the pushed window moved (`delta2.py` -> `delta2.jsonl`).

### PICT re-scoped (while sweep 2 runs): negative values as an api-level capability

Second look at the public C API (`api/pictapi.h`): it has parameters, value weights, exclusions,
seeds, child models and (since PR #160) thread counts, but **no notion of negative (out-of-range)
values at all**. Negativity exists only in the CLI (`CModelValue::IsPositive`), implemented as two
whole CLI runs plus synthetic pair exclusions (`gcd.cpp` `Generate`, `gcdmodel.cpp:542`). An API
caller (api-usage sample, clidll, the PictNet .NET wrapper in the fork scan) cannot do negative
testing. Maintainer stance on the API (#107, jaccz 2023): "It is just sets of indexes. It is up to the
caller ... to translate the user input into indexes" - a per-value-index negative flag fits that
stance; strings do not. The API is still being extended (#160 added `PictCreateTaskWithThreadCount`).

Lane: give the api generator per-value negative flags (C API entry + result-row negative marker),
generate negative rows inside `Model` so that one negative per row, every negative covered with the
valid values of the other parameters, sub-models (pseudo-parameters) and seeds all hold, and make
the CLI delegate to it. The obvious template is the CLI's own two-run code, and it is WRONG in
exactly the sub-model regime (#44, reproduced) and crashes on negative seeds under sub-models:
F-39 (inherited helper bug) by construction. F-9: negativity is destroyed at the CLI/api boundary
before the hierarchy sees it. F-10 cells: negatives in one vs several sub-models x generated vs
seeded x `/o:1` vs `/o:2`.
Sketch against the chokepoints (`Model::Generate` + pseudo-parameter mapping + C API + CLI
delegation): api negative-aware generation incl. partner rows for pseudo-parameters ~110-160,
C API surface + result marker ~30-40, seeds through the hierarchy ~40-60, CLI delegation + `/s`
~30-50 = **~210-310 human-eff** across `api/model.cpp`, `api/generator.h`, `api/parameter.cpp`,
`api/pictapi.{h,cpp}`, `cli/gcd.cpp`, `cli/gcdmodel.cpp`.
Risks: (1) in-repo prior implementation (the CLI) may read as "integration around an existing
engine" at the scope gate; mitigated only because the hard part (sub-models + seeds) is exactly
where the CLI is broken; (2) tests must be property checks (a C++ api harness emitting JUnit plus
CLI property checks), never golden rows, since any correct generator emits different rows;
(3) copilot-instructions.md penalty and a docs/CI-only Copilot sweep over the tracker.

### Fresh sweep 2 result

`delta2.jsonl`: 5,295 live rows (one secondary-rate-limit retry, recovered); 1,923 outside the dead
list, 816 permissive/NOASSERTION, 142 engine-vocabulary (`d2_eng.tsv`). Engine-shaped:
DanielSWolf/rhubarb-lip-sync (C++, a staged phone -> mouth-shape animation pipeline, but **0 commits on
master in 12 months**; work moved to `feature/v2-rust` / `rewrite-attempt-*` branches: Requirement
6 corpse), gajus/liqe (Lucene syntax, famous), gajus/surgeon, Instagram/Fixit (Meta lint framework,
0 commits/90d), zkat/cacache-rs (AGENTS.md, 0/90d), libimagequant (GPL). Nothing beats PICT.

## Stage 5 dossier: microsoft/pict - RANK 1

- **URL / stars:** https://github.com/microsoft/pict - 1,466 stars
- **Language:** C++ 89% (C 3%, Perl 3% test harness). Pure: no external deps, plain `make`.
- **Domain:** combinatorial (pairwise / t-way) test-case generator: model + constraint language ->
  exclusions -> hierarchical greedy generator.
- **Open issues:** 15 total (tracker is mostly old bug reports; #44, #40, #121, #130 are the live ones).
- **License:** MIT, `LICENSE.TXT` read (the API reports NOASSERTION only because of the file name).
  No vendored third-party code.
- **Last code commits:** 2026-07-24 (#160 thread pool + best-of-N), 2026-05 (count-uniques tool),
  2026-01 (DBCS handling, PictGenerate reset). CI `main.yml` (make test + ctest, 3 OSes) green on main.
- **Tests:** `test/test.pl` perl golden-baseline harness over ~15 model directories; `make test`
  ~10 s, rc=0 with 0 failures in 3 consecutive runs (log hash differs run to run; timing lines,
  confirm at scope-lock). Generation is deterministic (same output hash 3x). New tests must be
  PROPERTY checks (C++ api harness + CLI checks emitting JUnit), never golden rows.
- **Docker:** `olympus-base-cpp`, `make` only, ~5 s build, offline. (Not built in Docker here.)
- **Architecture:** `cli/` (model parser, constraint tokenizer/parser, `gcdexcl` constraint ->
  exclusion translation, `gcd` two-run negative orchestration) over `api/` (Model hierarchy with
  pseudo-parameters, exclusion deriver, generator, C API `pictapi.h`).
- **Capability-lane density (2c):** 12-month stream = perf (thread pool, best-of-N), DBCS, docs,
  CI, a count-uniques tool. No commit in negatives / sub-models / seeding. Copilot sweep
  (`app/copilot-swe-agent`, `danfiedler-msft` `copilot/*` branches) = docs + CI + a seed-contract
  doc note: lane-scoped NOTE.
- **Maintainer-welcomed lanes (2d):** none explicit. #40 bug confirmed by jaccz ("there's indeed a bug
  somewhere"). #107 philosophy: API = index sets, caller translates strings.
- **Fork-branch exclusivity scan (new gate):** all forks pushed 2025-2026 compared; no lane work.
  Not in `adx-labtesing-deepswe-forks.txt`, no `blitzy-*` fork, no signature accounts in PRs.
- **Self-collision:** no combinatorial-testing / covering-array problem in approved-problems/,
  problems/ or rejected/.
- **Missing machinery (LOC carry):** negativity inside the api generator (the api has none), made
  correct through the pseudo-parameter hierarchy and seeds; C API surface; CLI delegation.
  Sketch ~210-310 human-eff over 6-7 files in 2 subsystems.

TRAP SEAMS:
| Pattern | Present | Evidence |
|---|---|---|
| F-39 inherited helper bug | yes | the CLI two-run negative code (`gcd.cpp` `Generate` + `gcdmodel.cpp:542`) is the natural template and loses every negative of one sub-model when another sub-model's suite has a negative in every row (#44, reproduced: C negatives absent; seeded variant drops all D negatives) |
| F-9 cross-stage drop | yes | negativity is a CLI-only concept (`CModelValue::IsPositive`), removed before the api hierarchy (`mapExclusionsToPseudoParameters`, `mapRowSeedsToPseudoParameters`) ever sees it |
| F-10 cross-product | yes | negatives in 1 vs several sub-models x generated vs seeded x `/o:1` vs `/o:2` x root-level vs sub-model parameters |
| F-15 arming | yes | "exactly one negative per row" vs "every negative covered with every valid value" |
| F-3 second-axis carve-out | partial | a parameter may sit in several sub-models (doc note 1) |
| F-1 / F-2 / F-4 / F-13 | no | |

**Stage 6 death-class guard (RANK 1, lane = api-level negative values honoured through sub-models
and seeds):**
1. Shared kernel feeding several surfaces: YES. `Model` generation + pseudo-parameter mapping feeds
   CLI output, API result rows, seeding and `/s` statistics; giving a sub-model fully valid partner
   rows (the #44 fix) changes which pseudo pairs the "no two negatives" exclusions remove and which
   seeded rows map, so a local fix to coverage regresses masking or seeding.
2. Interdependent traps: YES (F-39 template bug x F-9 boundary x masking-vs-coverage). Not a list of
   independent rules.
3. Standalone new file with minimal wiring: NO, the change lives in `api/model.cpp` generation.
4. TOO-EASY Pre-Pick Guard 1-5: (1) not one rule at many sites; (2) not a single-subsystem
   transform (api generator + C API + CLI, two hidden-integration walls: sub-model partner rows,
   seeds through the hierarchy); (3) the sub-model requirement can and must be stated; the difficulty
   is that the in-repo template is wrong there; (4) not a port; (5) survives full spelling-out.
   PASS, with the LOC sketch as the main risk.

Risks: in-repo prior implementation (CLI) could read as "integration" at the scope gate; LOC sketch
210-310 is estimated, not built (below ~200 the pick dies); copilot-instructions.md penalty; a
maintainer Copilot sweep over the tracker could fix #44 upstream (it would remove the F-39 wall, not
the api capability) - re-run the base->main check at scope-lock; golden-baseline test convention means
the new harness must be written from scratch. Requirement 0 (picker) OWED.

## Budget spent

Proven pool (exhausted, 12th session); source (a) reverse deps of 98 approved-repo packages via
ecosyste.ms (DRY); source (b) org-mates + top contributors of 78 pool repos (DRY); fresh sweep 1 =
delta of live repos the index never saw (16,804 rows, 34% unseen) -> PICT; last-resort residual
`unjudged_noeng.tsv` (258 after cuts, nothing); fresh sweep 2 = delta for the June-August pushed
window (5,295 rows, nothing better). Disk: PICT clone kept at `worktrees/pict` (7.4M, build output
removed); scratch `worktrees/_hunt/s_0923h20/`.

## Result: CANDIDATE microsoft/pict

Lane: negative (out-of-range) values as an api-level capability of the generator, honoured through
sub-models and seeds, with the CLI delegating to it. Fallbacks: none in another repo survived; the
same-repo reserve lane is #40 (`/o:1` emits constraint-violating rows, maintainer-confirmed) but it is
an independent root, usable only as a separate pick, not a coupled lever.

Next-hunt hint: the delta sweep (live repos minus every seen/judged slug) is the productive new
source: 34% of the live 500-3000-star band had never been seen. Extend it to stars 3000-6000 and to
the 2025-10..2026-06 pushed window before re-reading anything cached.
