# REPO-HUNT 2026-09-23-H

Unattended `olympus-factory` hunt worker (hunter #21). `CONSECUTIVE_MISSES=0`, so the standard
(already softened 2026-09-09-B) rules apply; no star/issue window is widened for softening. The
3000-6000 star band swept below is inside the normal Requirement 1 range (5000+ is a ranking penalty,
not a relaxation) and was requested by hunt #20's hint. Standing rules (user, 2026-09-23): a root
AGENTS.md / CLAUDE.md is a ranking penalty; AI commits in the 90-day stream are lane-scoped (SKILL.md
2b). Mandatory in every lane audit: fork-branch exclusivity scan. Requirement 0 (platform picker) is
OWED on anything handed over.
Scratch: `worktrees/_hunt/s_0923h21/`.

**Task (hint from hunt #20):** extend the DELTA sweep (live GitHub search band minus every
seen/judged slug) to stars 3000-6000 and to the 2025-10..2026-06 pushed window before re-reading any
cache. Reverse deps and org-mates are DRY (not repeated). Excluded: microsoft/pict (SLICING),
BayesianOptimization + teavm (HANDOFF), tegaki, ArchUnit, genqlient, capnproto, glom, refinery,
rhubarb-lip-sync, every LEDGER row, every problems/ repo, everything adjudicated in 09-23-C..G.

## Stage 0-bis proven pool

EXHAUSTED (13th session). Hunt #20 rebuilt it from frontmatter (78 repos) and found nothing to
reopen; no problem has been archived since except csbindgen / libspatialindex / siliconcompiler,
which are CLAIMED ledger rows. Not re-mined.

## Fresh sweep 3: delta, stars 3001-6000, pushed after 2026-08-15

`delta3.py` (h20's `delta.py`, band moved) -> `delta3.jsonl`.

## Fresh sweep 4: delta, stars 500-3000, pushed 2025-10-01..2026-05-31

`delta4.py` -> `delta4.jsonl`. Runs after sweep 3 (sequential, search API limit).

### Sweep 3 result (stars 3001-6000, pushed after 2026-08-15)

`delta3.jsonl`: 3,010 live rows, 0 errors. Only **867 (29%)** are outside `dead21.txt` (h20's
dead20 + h20's eyeballed delta_eng/d2_eng rows + every slug in the hunt logs, LEDGER,
SATURATED-REPOS, TOO-EASY), 342 permissive/NOASSERTION, 58 engine-vocabulary (`delta3_eng.tsv`).
The unseen share is lower than in the 500-3000 band because the older star-band index reached into
this range. Eye pass over the 58 engine rows and the ~200 pre-2025 non-vocabulary rows: famous
products and frameworks (twisted, pmd, flake8/pycodestyle, highway, liquibase, logback, jetty, h2 and
rhino (MPL, licence-dead), source-map, re2j), apps, infra, AI tooling. Engine-shaped and probed:
- **sonos/tract** (Rust ONNX/NNEF inference, Apache/MIT, 3,071 stars): DEAD. 854 commits in 90 days
  (kali 521), **162 AI-marked**, root AGENTS.md + CLAUDE.md + GEMINI.md. Firehose, every lane in the
  stream (lane-scoped rule cannot save a repo whose maintainer agent-sweeps the whole tree).
- magcius/noclip.website (game-format viewer, no test suite), pmd/pmd (5,494 stars, penalty band,
  rule catalogue = "add N rules"): dismissed.

### Sweep 4 result (stars 500-3000, pushed 2025-10-01..2026-05-31)

`delta4.jsonl`: 7,022 rows (last push in the window, i.e. repos quiet since June), 0 errors. 2,980
(42%) unseen, 1,250 permissive/NOASSERTION, 257 engine-vocabulary. The unseen mass is ML paper
code (CVPR/ICCV/NeurIPS repos), Tencent/NVlabs research drops, templates, security tooling and
Chinese-language app collections. Engine-shaped survivors, mechanically checked (12-month commits):
logpy/logpy 2 (superseded by pythological/kanren), cfinke/Typo.js 2, jsonquerylang/jsonquery 5,
NationalSecurityAgency/lemongraph 0, GGBRW/BOOLR 1, mmarkdown/mmark 3, cswinter/LocustDB 0,
nemtsov/json-mask 0: all Requirement 6 corpses or near-corpses (docs/typo streams).
**csmith-project/csmith** (C++, BSD-2, 1,242 stars, 48 commits/12mo, a generator with a real
points-to/effect fixed point): DEAD on Requirement 7, the repo has no `.github/workflows` at all and
no test suite (a generator validated by external compilers). **perpetual-ml/perpetual** (Rust GBM,
Apache-2.0, 708 stars, 100 commits/12mo, CI.yml present, v3.0.0-rc.2 April 2026): the only live
engine; audited below.

### perpetual-ml/perpetual: DEAD (capability-consuming + sibling-library absorption)

12-month stream is 100 commits, all `deadsoul44`, and it is a feature firehose across every lane a
GBM has: causal ML + meta-learners, classification and regression calibration, drift support,
continual learning, ranking objectives (#70), custom objectives, multi-output, categorical handling,
serialization (Feb-Apr 2026), then silent since the v3.0.0-rc.2 tag on 2026-04-02. Every lane a
hunt can name (monotone / interaction constraints, missing-value routing, categorical splits, new
losses) is also a named feature of xgboost / lightgbm / catboost, so it dies to the sibling-library
check even where the maintainer has not reached it. No lane to hand over.

### Other late probes
- kossisoroyce/timber (687 stars, "AOT compiler for XGBoost/LightGBM/sklearn"): created 2026-02-27,
  root `llms.txt`, `skill.md` for coding agents, feature dumps like "merge TimberAccelerate: SIMD/GPU/
  HLS/embedded codegen, WCET, certification, supply-chain, deployment" in one commit, quiet since
  April. AI-built product, no stable engine to extend. DEAD.
- rbock/sqlpp11 (C++ SQL EDSL): SQL magnet and the author moved development to sqlpp23
  (author-controlled successor). DEAD.
- geoopt/geoopt (Riemannian optimisers): textbook manifolds, PyTorch test graph. Not pursued.

## Cached-fallback triage: UDST/urbansim (RANK 4 fallback of 2026-09-21, never adjudicated since)

Not in the LEDGER, not in any 09-23 log. Re-checked live: 3.3 released 2026-09-16; the maintainers'
revival sprint (smmaurer, waddell) is closing LEGACY issues: #243 transition model, #194
`hanase/max-profit-fix` + `fix/developer-pick-all-forms` in `developer/developer.py`; nothing in
`developer/sqftproforma.py` since the pandas-3 compatibility commit. One outside PR, #238 "Ponytail
audit" (ColbyBrown, closed, urbanchoice/models/utils): one visit outside the lane = NOTE. Not in
`adx-labtesing-deepswe-forks.txt` or `sig_accounts.txt`. Same-org sibling `UDST/developer`
("Redesigned UrbanSim developer/pro forma models", 3 stars, pushed 2023) was checked: its
`sqftproforma.py` also keeps `parcel_coverage` a scalar, so the sibling does not absorb the lane.

Lane re-read at source (`sqftproforma.py:309-392` `_generate_lookup`, `:533-651`
`_lookup_parking_cfg`): the pro forma precomputes one FAR-indexed table per (form, parking config)
because every per-FAR quantity is SCALE-INVARIANT in parcel size (the docstring says so: "the parcel
sizes cancel"), and only `parcel_coverage` turns stories into heights, heights into cost bands
(`_building_cost` `searchsorted(heights_for_costs)`), and feeds `max_far_from_heights` and the
height mask. Per-parcel coverage therefore means: move stories / height / cost-band / height-mask
from the precomputed table to a per-parcel 2-D computation, keep the scalar as the default, and keep
the surface-parking "stories > 5" cut BEFORE the coverage division (`:369-376` order). The 09-21
dossier's misdirection (the 1-D `parking_sqft_ratio` gather) does not survive the read:
`park_sqft / total_built_sqft` is coverage-independent, so it stays 1-D legitimately.

**Stage 6 death-class guard: FAIL.**
1. Shared kernel feeding several surfaces: partial (lookup, debug table, `developer.pick`).
2. Interdependent traps: NO. Every site is the same rewrite (replace `c.parcel_coverage` by a
   per-parcel vector and broadcast), so fixing one does not surface or break another.
3. Standalone file: no, but the whole change is one function pair in one file.
4. TOO-EASY Pre-Pick Guard #1 (one rule at many sites = uniform-wrap) and #2 (single-subsystem,
   fully-specified transform, zero hidden integration walls): both trip. The formulas are all
   present; the spec can state the lane completely and the agent threads it cleanly.
Sketch against the chokepoint (rule 5): ~120-170 human-eff, and the 150-250 band needs a coupled
second lever, which the source does not offer (multiple `parcel_sizes` should crash on base with a length
mismatch at `:326`, read from source and not run, but the sizes cancel by construction, so fixing it is a bug fix with no domain
behaviour behind it). Verdict: urbansim stays a fallback only for a hunt allowed to relax the guard,
and should not be re-audited for this lane again. Clone `worktrees/_hunt/p_0921/urbansim` updated to
HEAD 1a9a68e (no build output).

## Budget spent

Proven pool (exhausted, 13th session, not re-mined); cached-fallback triage (urbansim, the only
unclaimed and unadjudicated fallback left in the 09-19..09-23 logs: fails Stage 6); fresh sweep 3 =
delta, stars 3001-6000 pushed after 2026-08-15 (3,010 rows, 29% unseen, nothing engine-shaped and
live); fresh sweep 4 = delta, stars 500-3000 pushed 2025-10-01..2026-05-31 (7,022 rows, 42% unseen,
corpses and ML paper code; csmith dead on Requirement 7, perpetual consuming). Together with hunt
#20's two sweeps, the whole live band (stars 500-6000, last push 2025-10 onward, 7 languages) has now
been delta-swept against the seen/judged union: the unseen residue is not engine-shaped. No builds
run; disk untouched (`df -h /` 12G free at start). Scratch: `worktrees/_hunt/s_0923h21/`
(`delta3/4.jsonl`, `*_new/perm/eng.tsv`, `dead21.txt` = 58,169 slugs, `dfilt.sh <prefix>`).

## Result: NO-CANDIDATE (hunter #21)

Nothing survived: the delta sweeps are exhausted (the 3000-6000 band was mostly inside the old
index; the colder push window is corpses), and the one unadjudicated cached fallback fails the
death-class guard. Requirement 0 not applicable (no candidate).

Next-hunt hint: stop sweeping GitHub by star/push band; every live 500-6000 slice is now seen.
Re-open repos killed by rules that were SOFTENED after the kill: the 30 hunt logs dated before
2026-09-10 rejected repos on commit velocity, `action_required` CI rows, a single competitor visit,
zero-issue trackers and nameability alone (e.g. 08-01, 08-02-B, 08-04-B/C/D, 08-07-B/D, 09-06,
09-08, 09-09-B). Grep those logs for kills whose ONLY stated reason is one of the softened rules,
re-check them against today's LEDGER/dead list, and run the lane audit plus the Stage 6 guard on
each. If CONSECUTIVE_MISSES reaches 2, urbansim (per-parcel coverage) and PICT's reserve lane #40
(only if PICT dies) are the relaxed-guard fallbacks.
