# REPO-HUNT-2026-09-29-B (hunt #36, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0929h36/`.

## Standing inputs
- The human asked for this hunt knowing discovery is thin, with no language preference. The goal was
  new ground: repos that crossed 500 stars or became active after the cached index was built,
  dependency graphs of approved-problem repos, and unswept ecosystems.
- Do not repeat the 17 discovery axes of hunt #34 (REPO-HUNT-2026-09-28) or hunt #35's 9-repo pool
  re-mine (REPO-HUNT-2026-09-29).
- Excluded:
  - robertmuth/Cwerg (SLICING);
  - rust-minidump/rust-minidump and tokio-rs/turmoil (reserved fallbacks);
  - every LEDGER row (22 repos in any status);
  - every `problems/` folder (asdf, grmtools, hayro, ray-optics, riff).
- google/mangle's Requirement 7 waiver was not granted, so it stays dead.
- Requirement 0 (platform picker) cannot be checked here. It is OWED.
- Softening: misses=0, so the 2026-09-09-B rules apply as written. No star or issue window was
  widened. Relaxations taken: none.
- Disk: 11G free at start and at the end. There were no clones and no builds; everything ran
  through the API.

## Stage 0-bis: proven pool
Nothing changed since hunt #35 ran it earlier today. That hunt screened 49 pool repos and ran lane
audits on 9. The two approvals since then (pict-engine-negative-values and macs-circular-chromosomes,
both 09-29) are LEDGER rows, so they are taken. No pool repo was re-audited.

## Cached index
- `band.jsonl` (09-15) and `band_hi.jsonl` (09-16) have not changed.
- Hunt #34 already read the whole unjudged engine residual by eye: 574 rows in
  `s_0928h34/screen2.tsv`, with 0 survivors.
- No re-triage was worth running. Sweep 1 below measures how complete the cache is.

For the anti-joins I built a seen-set (`seen_h36.txt`, 280,285 slugs). It is the union of:
- every jsonl, txt and tsv under `worktrees/_hunt/`;
- every slug named in `Instructions/`, `pipeline/` and the root `.md` files.

A judged-set (`judged_h36.txt`, 41,777 slugs) takes only the logs, dossiers and agent reports.

## Fresh sweep 1: star-crossers and revivals since the index (new axis, the human's first suggestion)
Two queries, both `archived:false fork:false`, across the 7 in-scope languages. Each was split by
creation-date windows to stay under the 1,000-row search cap.

| Slice | Query | Rows | Not in the seen-set | After licence + junk filter |
|---|---|---|---|---|
| 1a crossers | `stars:500..700 pushed:>2025-09-29` | 8,439 | 149 (1.8%) | 38 (`cross_new_h36.tsv`) |
| 1b revived | `stars:701..6000 pushed:>2026-09-14` | 11,674 | 122 (1.0%) | 33 (`revived_new_h36.tsv`) |

**What this proves.** The cache plus the later delta sweeps holds 98-99% of every live in-scope repo
at 500-6000 stars. A repo that crosses 500 stars or wakes up after the index was built adds about 1%
new ground, and this hunt measured that 1% as junk. The unseen rows were:
- **LLM apps and models:** Jev and System-One clones, Qwen fine-tunes.
- **Opus-generated demo sites:** tidewater, sakura-crossing.
- **Apps and UI widgets.**
- **ROS and GPU projects:** XTDrone, cuda-rust, pyrowave.
- **Dormant 2012-2017 libraries that pushed once.**

Rows worth a mechanical look:

| Repo | Verdict |
|---|---|
| hydra-ecosystem/omegaconf (Python, BSD-3, ★2435; moved from omry/omegaconf on 09-23) | DEAD. The maintainer revived it with a firehose across every core lane: resolvers ("single pass"), typed interpolations, escaped keys and literals, union / Literal / Any support, merge roots, flag caches. That is 100 commits in 12 months, 30+ since July, heading to 2.4.0rc1 on 09-28. Two more marks: an AI backlog tool ("Backlog Atlas" workflow), and signature account `Sanjays2402` (already on the list) in the resolver lane (#1356). The interpolation grammar is ANTLR, which needs Java at build time |
| cidrblock/drawthe.net (TS, MIT, ★1181) | DEAD. A 24-commit revival burst on 09-25/26 (feat renderer / schema / connections, plus an MCP server for "agent-driven authoring"). 0 issues. It is a diagram renderer app, not an engine |
| Operational-Transformation/ot.js (JS, MIT, ★2138) | DEAD on Requirement 6: 0 commits in 12 months. OT is also a textbook algorithm |
| J-F-Liu/pom (Rust, MIT, ★527) | DEAD: 2 commits in 12 months and a 368 KB combinator library (LOC floor) |
| photopea/UTIF.js, TehShrike/deepmerge, joe-re/sql-language-server | Famous format port (TIFF), a stdlib-equivalent utility, and SQL |

Survivors: none.

## Fresh sweep 2: forward dependencies of approved-problem repos (new axis; only REVERSE deps were swept before, 09-19-H and 09-23-G)
Tooling: `fwddeps_h36.py` / `fwddeps2_h36.py`, output in `fwddeps_h36.jsonl`. It uses
packages.ecosyste.ms: `packages/lookup?repository_url=` to find each seed's registry package, then
the latest version's dependency list, then each dependency's `repo_metadata`.
- Seeds: 108 approved and in-flight repos (`approved_repos.txt`). 88 resolved to a registry package;
  ray-optics and Cwerg are not packaged, and some older Go/Java seeds have no registry entry.
- The dependencies covered pypi 821, cargo 395, go 238, npm 78 and maven 61 edges, for 927 distinct
  packages.
- After requiring ≥500 stars, not archived, in-scope language, permissive licence and a push in the
  last 12 months, 429 repos remain (`fwd_all_h36.tsv`).

Result: the forward-dependency graph of an approved engine is **infrastructure plus famous
libraries**:
- serde/syn/regex/itertools and the dtolnay family;
- pytest plugins, sphinx themes, attrs/pyyaml/lxml;
- Go logging, CLI and colour helpers;
- jackson/slf4j/hppc/roaringbitmap.

These are all ★2k-7k or famous-spec implementations. The few engine-shaped dependencies all carry an
earlier written verdict:

| Repo | Verdict |
|---|---|
| MikePopoloski/slang | 238 non-chore commits in 12 months sweeping the SystemVerilog spec (09-23-E) |
| maplibre/maplibre-tile-spec | "the core codec lane is the sweep" (09-23-C) |
| jscad/OpenJSCAD.org | 0 commits on the default branch |
| cocotb | Docker needs an HDL simulator |
| linebender/kurbo | 34 open PRs |
| pyvisa | too thin |
| chaimleib/intervaltree | a single data structure |
| brendanzab/codespan | dormant |

Two dependencies had no earlier verdict:
- **jannikmi/timezonefinder** (Python, MIT, ★538): DEAD. It has 100 commits in 12 months, and the
  maintainer is running a coded backlog programme through the query core ("API-1: return every zone
  that contains a point", "PERF-7", "PREC-1: containment precedence in every cell", "TOOL-7: shortcut
  tie precedence"). That is capability-consuming in the only engine lane.
- **bear/parsedatetime** (★711): 0 commits in 12 months, and it is in the datetime class.

Survivors: none. Lesson: an approved repo depends on libraries more famous than itself. The domain
cores (scikit-fem's meshio, sfepy's sympy, MetPy's pint/xarray, pyocd's lark/pyelftools) are either
famous or single-purpose. Do not repeat this axis.

## Axes used this hunt (add to the exhausted list)
1. The star-crosser band (500-700 stars, pushed within 12 months), anti-joined against every cached slug.
2. The post-index revival band (701-6000 stars, pushed after 2026-09-14), anti-joined the same way.
3. Forward dependencies (registry dependency lists) of 88 approved and in-flight repos.

All three were dry. With hunt #34's 17 axes, 20 discovery axes are now exhausted.

## Result: NO-CANDIDATE
There was no RANK 1, so the Stage 6 guard did not run.

What I tried:
- Proven pool: unchanged since #35.
- Cached index: judged out by #34.
- Sweep 1 (star-crossers plus post-index revivals, 20,113 rows, 98-99% already seen):
  omegaconf, drawthe.net and ot.js are dead, and the rest is junk.
- Sweep 2 (forward dependencies of 88 approved repos, 927 packages, 429 in-scope): infrastructure
  and famous libraries; timezonefinder and parsedatetime are dead.

Fallbacks are unchanged. Nothing new qualifies, and the reserved pair (rust-minidump, turmoil) belongs
to Cwerg.

What the next hunt should change:
- **Stop spending hunts on discovery.** The measured coverage of the live 500-6000 band is 98-99%, and
  new entrants are mostly LLM apps. A new metadata axis will not change that.
- The remaining moves need a human decision or a different oracle:
  - (a) Human-supplied anchor repos or platform-side lists, with the hunt running lane triage only.
  - (b) A supervised override of one soft gate on a named strong engine. mangle's waiver was
    refused, so this needs a different repo.
  - (c) **Time-decayed re-audit.** Repos killed 08-01..09-10 on a CAPABILITY-CONSUMING or
    firehose LANE verdict may have gone quiet since then. Re-run only Stage 2c (a 90-day commit
    histogram per lane) over the SATURATED-REPOS B3 "capability-consuming" rows: egglog, nilaway,
    moon, mvdan/sh, openfga, and the 09-09-B firehose group.
    - Hunt 09-23-I re-opened these on softened RULES, but not on elapsed TIME.
    - A lane that was hot in August and has been cold since September is new ground that no
      metadata sweep can see.
