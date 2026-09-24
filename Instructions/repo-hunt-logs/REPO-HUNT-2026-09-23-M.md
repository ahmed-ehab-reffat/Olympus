# REPO-HUNT 2026-09-23-M (hunter #26, CONSECUTIVE_MISSES=0)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=0: no extra softening beyond the permanent
2026-09-09-B rules. Standing rulings: AI root file = ranking penalty; AI commits/trailers =
lane-scoped (SKILL 2b softened). Mandatory fork-branch exclusivity scan on every lane audit.
LOC honesty: return only if honest total >= 250 human-eff AND difficulty-carrying core >= 150.

Method (hunt #25 hint): invented-lane workshop with parallel agents on DOMAIN ENGINES, weighting
stages that DISCARD state. 6+ new gate-clean repos no earlier workshop covered.

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Excluded: every LEDGER repo, tokio-rs/turmoil, SciTools/cartopy, ricktu288/ray-optics (HUNTED),
softdevteam/grmtools, featurevisor/featurevisor, LaurenzV/hayro, dyn4j/dyn4j, every problems/ folder
repo, hard-rule kills in 09-23-C..L.

Housekeeping: added `arbelonson-source` and `tabbymarshlwio0-rgb` to
`worktrees/_hunt/sig_accounts.txt` (hunt #25 finding).

Scratch: `worktrees/_hunt/s_0923h26/`.

## Stage 0-bis / cached index
Proven pool (rebuilt 2026-09-23): 66 repos at 1 sub, 13 at 2, 2 at 3 (starlark-go, gluon). Every
pool repo was re-judged in hunt #23 (J log, group P, 0 viable of 9) and nothing new has been approved
since except LEDGER repos (csbindgen, pyfakefs, siliconcompiler, libspatialindex), so not re-derived.
Cached index: exhausted per K (78,844-slug union, two fresh sweeps 0 survivors); not re-fetched.

## Workshop selection (cached fallbacks never adjudicated since, all gate-clean at their hunt)
Live mechanical re-check 2026-09-23 (`gh api repos/...`):

| Repo | Stars / licence / pushed | Why chosen | Prior note |
|---|---|---|---|
| gkjohnson/three-mesh-bvh | 3494 MIT 09-20 | 09-21 RANK 2 fallback, never adjudicated after openglobus died | group-partitioned roots vs live groups/drawRange, ~280-330 sketched |
| netenglabs/suzieq | 905 Apache 08-29 | 09-20-C RANK 2 fallback, never adjudicated | path identity + snapshot alignment, ~315 sketched; semi-dormant risk |
| PatWie/CppNumericalSolvers | 977 MIT 07-24 | 09-20-B RANK 2 fallback (reserved for siliconcompiler, now CLAIMED) | vector-valued composition through the mode lattice, ~300-330; sibling risk |
| macs3-project/MACS | 784 BSD-3 09-23 | 09-19-F fallback (reserved for libspatialindex, now approved) | seed lane was a magnet (#613); invent on the pipeline |
| walles/riff | 527 MIT 08-15 | 09-19-G/H/09-20 fallback (reserved, now free) | streaming diff pipeline |
| tyrasd/overpass-turbo | 1245 NOASSERTION 07-19 | 09-23-B killed ONE lane (wizard, Stage 6); other engines unaudited | licence must be read first |
| greatscottgadgets/luna | 1139 BSD-3 08-19 | 09-20-B RANK 3 fallback (reserved, now free) | seeds are USB-spec rows (magnet) |

Dropped from the workshop: quint-co/quint (language carve-out + approved sub, judged 3x),
mapproxy (vendored Zope Public License, not on the allowlist), reindexer (heavy C++ build),
getgauge/gauge + netromdk/vermin (lanes already dead), chicory (dormant).

Brief: `worktrees/_hunt/s_0923h26/BRIEF-M.md` (hunt #25 brief + two-number LOC honesty,
discarded-state weighting, updated sig accounts). Seven agents launched in parallel.

## Agent verdicts

### tyrasd/overpass-turbo — DEAD (licence, vendored LGPL + WTFPL)
The root LICENSE is MIT, but it adds that "included libraries may be released under different
licences" (which explains the NOASSERTION). `js/misc.ts:8` says "lzw_* taken from jsolait library
(http://jsolait.net/), LGPL". `lzw_encode` (:197) and `lzw_decode` (:225) are live at HEAD bb21a1c,
imported by the share-link code (`js/ide.ts:1478,1570`, `js/urlParameters.ts:32`). The Levenshtein
function (`js/misc.ts:11`) and `js/PopupIcon.ts:5` are WTFPL, which is also not on the allowlist.
This is a hard licence kill. **Stale row:** the 09-23-B log recorded the repo as MIT-clean and
killed it at Stage 6. Dossier `s_0923h26/agents/overpass-turbo.md`.

Replacement for overpass-turbo: Restream/reindexer (09-20-B RANK 2 fallback, ★811 Apache-2.0,
pushed 09-23; seed = composite-index prefix+range folding in QueryPreprocessor), agent launched with
a 12G disk floor for any build.

**Interruption (API session limit):** all seven remaining workshop agents (tmbvh, suzieq, cppnum,
MACS, riff, luna, reindexer) were cut before writing a dossier. Partial state left on disk: tmbvh
node_modules+build (357M), suzieq .venv+build (873M), MACS (591M), luna .venv. Resumed per the
coordinator: re-dispatch at most 3 at a time, reuse partial installs, delete them at the end.
Wave 1: tmbvh, suzieq, cppnum. Wave 2: reindexer, MACS, riff. Wave 3: luna.

### netenglabs/suzieq (agent) — DEAD
The seed lane (path identity + two-snapshot alignment) is weaker than the 09-20-C log recorded.
Path-as-of-time ALREADY works: `PathObj(end_time='2021-03-26')` returns 448 rows / 64 paths, and
the CLI and GUI pass start/end time. A diff that builds two PathObj never reaches the lru_cache
seam, and keying the returned frame avoids the prev_hop back-patch, so nothing forces a discard.
Honest ~175 total (ceiling ~220), core ~85. It is a post-pass over two public `path.get()` frames
(guard Q3 yes), and it fails Q4 #2 and #3 (the altered-vs-add/remove threshold and the ECMP tie-break
must be stated). Other lanes: weighted-ECMP share (weights dropped at path.py:607) ~115, a uniform
wrap; `view='changes'` is a REMOVAL record (2020 aaa0c913/029efad7, removed in 39b32340); OSPF
SPF-predicted vs actual RIB ~200 / core ~125, but networkx absorbs SPF and the vendor RIB conventions
trip Q4 #3; strict-uRPF asymmetry ~60; overlay/underlay split (#592) is a post-pass, ~120.
Exclusivity is clean (21 open PRs, none in engines/; forks mirror only; 0 sig accounts). Last code
commit 2026-08-05. Recommend dropping suzieq from every fallback list. Clone cleaned to 256M.
Dossier `s_0923h26/agents/suzieq.md`.

### PatWie/CppNumericalSolvers (agent) — DEAD
The seed lane (vector-valued constraint blocks via composition J^T grad f / J^T H_f J + sum
(grad f)_i H_{g_i}) was MEASURED, not sketched. An 80-human-eff standalone header
(`s_0923h26/cppnum_probe/absorb_a.h`: vector-map interface, row-view component expression, expansion
into the existing scalar constraint list, composition node with the second-order term) makes
TrustRegionNewton converge on a composed Rosenbrock and AL solve a 2-row block, with zero edits to
AL/penalty/progress. Honest full lane ~220 (210-235), core ~120. Guard Q3 fails (standalone file),
and so does Q4 (#2, plus #4: NLopt mconstraint in AUGLAG and the IPOPT/CasADi Lagrangian Hessian are
the siblings). Other lanes: resume/warm-start is absorbed (skipping InitializeSolver gives an exact
diff=0 for lbfgs/bfgs, `absorb_b.cc`), per-constraint penalty ~140 (LANCELOT), L-BFGS-B duals to KKT
~120, a Hessian-vector rung 160/100 (scipy hessp), AL infeasibility ~100, LM = MINPACK port,
variable freezing = standalone adapter. Law: the expression-template layer absorbs new maths as a
node or an expansion into the existing lists, and solver state lives in copyable members.
Exclusivity is clean (PR #174 CI-only; 15 forks compared; 0 sig accounts), and the maintainer
reworked every solver file in Apr-Jul 2026. Dossier `s_0923h26/agents/cppnum.md`.

### gkjohnson/three-mesh-bvh (agent) — DEAD
The seed (group/drawRange-surviving roots) reproduces on base: after setDrawRange the BVH still hits
tri 7, in both direct and indirect mode. But the lane is ~70-100 eff, and a naive rebuild gives the
same answers (value vs cost). The query-time version is a guard #1 uniform wrap. The `a.type`
comparator bug is real but unobservable. Best lane: spatial-split construction (#903, SAH + forced
indirect + duplicated references), with a genuine discard seam (computePrimitiveBounds reduces each
triangle to a padded box at BVH.js:134-165, and getOptimalSplit drops the object-split cost). It
reaches only ~250 total (230-290) / core ~165, and only by counting its performance half: a spatial
split changes tree quality, never a query answer, and the one answer-changing part (dedupe) is the
same one-line check at every query site. Q4 fails on #4 (SBVH paper port, named in maintainer-filed
#903), #1 and #5. Other lanes: subtree restructure (#284) ~150-175 plus the rayzee JS sibling;
selective refit ~40-60 post-pass; signed distance (fork + declined); kNN (PR #699); CCD (Babylon);
BatchedMesh optimize, LineLoop drawRange and margin are all under 100. Exclusivity is clean
(5 PRs, 99 forks, 0 sig). Base suite: 3 of 8 runs hit a 5000 ms timeout in
MeshBVH.options.test.js, so test.sh would need `--testTimeout`. Clone cleaned to 57M.
Dossier `s_0923h26/agents/tmbvh.md`.

### Restream/reindexer (agent) — WEAK
Best lane: AVG/FACET/DISTINCT aggregations in MERGE queries. This is maintainer TODO #1506. On base
it throws "Aggregation '{}' in merge query is not implemented yet" (rx_selector.cc:117-131), and
sharding refuses the same three, so there is no in-repo reference. It has been cold since release/4
(Feb 2025). It has real discard points: AVG drops hitCount (aggregator.cc:319); FACET is
sorted/offset/limit-truncated per namespace before any merge (aggregator.cc:288/295/309);
multi-field facet keys are namespace-bound PayloadValues; the main namespace finalizes before merged
ones run (nsselecter.cc:413); and each selection starts DISTINCT with an empty seen-set. Honest ~260
total / ~185 core, after reusing the facet maps, comparators, fillOrderedFacetResult, DistinctHelpers
and the Sum/Min/Max merge arms. Guard Q1 y, Q2 y, Q3 n, Q4 pass (with a #4 caution: partial
aggregation merge is a known distributed-DB idea). Exclusivity is clean (0 open PRs; the Uzer-007-1
codex/* branches are GIS only; 0 sig accounts). Req 7 passes (master b7ee7c0, all C++/GO legs
green). Why only WEAK: (1) **L62 Docker cold build.** The library is 401 ninja steps; the agent
estimated 12-15 min cold plus ~5 min for a trimmed gtest target, far past the 600 s environment
start. This needs the platform's prebuilt-image behaviour settled before any authoring. (2) Both
lanes sit at the floor (core 185, total 260; seed composite fold ~240/175 and a pure optimization
whose only F2P surface is the explain shape). (3) MERGE is an active maintainer lane (5.11/5.12
MERGE explain, hybrid MERGE), so #1506 could land. (4) An aggregation-class caution against our
tantivy pipeline-aggregations pick; the agent judges it a different class (a cross-source
partial-state merge). Also: one gtest binary including cluster/replication suites that open ports
(so the scope needs a filter), and repo suites that seed from `srand(now)`. Owed: runtime F2P probe
(`s_0923h26/rxprobe/probe.cc`), a cold Docker build time. Dossier `s_0923h26/agents/reindexer.md`.

### macs3-project/MACS (agent) — WEAK
Best lane: circular chromosomes (`--circular CHR,...`). Fragments, lambda windows and peaks wrap
across the origin instead of being clipped at fix_coordinates (PileupV2.py:78) and split by the
linear segmentation. F2P reproduced on a local build: a site straddling position 0 gives two
half-peaks (0-161 at -log10q 282.6, and 19838-20000 at 256.0), while the identical interior site gives
one peak (9831-10167 at 588.8); BED input runs a peak past the chromosome end. Honest ~190 total
(~225 with the BAMPE spanning-pair lever), core ~110-145. Guard: Q1 y (one wrap kernel feeds treat +
d/slocal/llocal, and the pileup chokepoint feeds pqtable, cutoff, narrow, broad and bedGraph); Q2
partial (the pad-the-origin shortcut double-counts bp in the pqtable, shifting q-values far from the
origin: a misdirecting cell); Q3 n; Q4 at risk on #1 (mod-L at every site) and #2. Below the floor on
both numbers. Other lanes: library-aware callpeak is exclusivity-dead (the public `feat_wacs` branch);
blacklist #613 is a magnet; duplicate provenance is in the cindykrafft fork branch
`fix/keepdup-auto-control-threshold` (Claude co-authored); lambda provenance is a post-pass;
spike-in is #356, a magnet; multimapper weighting is absorbed by Genrich/PETrackII; replicate
bdgdiff (#739) is absorbed. Signature account `cindykrafft` is on the repo (dedup lane). Repo health:
Python primary (Cython pure-python mode, so test.sh must `build_ext --inplace`, ~5 min), base
106 passed / 4 skipped 2x, CI clean. Clone cleaned. Dossier `s_0923h26/agents/macs.md`.

### walles/riff (agent) — WEAK
Best lane: detect conflict regions inside one-column unified diffs. That means resolved conflicts
from `git show --remerge-diff` (markers on the - side, each side compared against the resolution)
and unresolved ones from `git diff HEAD` (markers on the + side, side vs side). Region extent covers
the whole -/+ blocks, context lines count for both a side and the resolution, markers pair by
length, and regions continue across hunks. F2P reproduced on a base debug build (remerge output is
refined as one old text against `+v = 23` with side 2 left plain; `+<<<<<<<` input comes out all
plain green). Probes are in `s_0923h26/riff_probe/`. Honest ~245 total, core ~200, leanest passer
~180-200. Guard: Q1 y, Q2 partial-y (region extent and the double role of context lines decide the
resolution text, and side-token failures point away from membership), Q3 partial-y (one new
sub-highlighter at hunk_highlighter.rs:146 plus a FileHighlighter carry), Q4 pass-with-risk (G2 is
one subsystem). Exclusivity is clean (0 open PRs, 10 forks with no extra branches, 0 sig; delta only
parses `++<<<<<<<` combined conflicts, which riff already handles). Risks: ★527 is only 27 above the
floor; 50 commits/12mo, bursty (HEAD 2026-08-15); three Aug-2026 "Committed by Claude" commits in the
hyperlink lane (note); exact-ANSI golden tests. Other lanes: `log --graph -p` is a pre/post-pass
(~130); range-diff is absorbed (~150); `diff -c`/normal input has core 150 and is Q3-standalone;
weighted token cost (#14) is a textbook LCS that rewrites the goldens; moved blocks are a sibling
feature. Dossier `s_0923h26/agents/riff.md`.

## Adjudication (my own checks while luna runs)
Only reindexer Lane B clears both LOC numbers (honest total ~260 >= 250, core ~185 >= 150); riff is
~245/200 and MACS ~190/110-145. Verified in the clone (master b7ee7c0): the throw is at
`cpp_src/core/reindexer_impl/rx_selector.cc:129` (`// TODO #1506`, AggAvg/AggFacet/AggDistinct);
the sort-in-merge throw at :151 is asserted by fixtures/queries_api.cc:33/55/61 (Lane C, absorbed).
Side finding: `hasUnsupportedAggregations` (rx_selector.cc:~158) tests
`a.Type() != AggCount || a.Type() != AggCountCached`, which is always true, so any aggregation inside
a merged sub-query is refused. Magnet note: the literal "not implemented yet" + TODO in source is a
visible invitation to any author who reads rx_selector.cc (MEDIUM; there is no public issue, and #1506
is an internal tracker number). L62 cold build: timing `ninja -j6 reindexer` in olympus-base-cpp on an
unloaded host now (container `hunt26-rx`, `s_0923h26/rxprobe/build3.sh`).
L62 measurement (unloaded host, 8 cores / 7.7 GB RAM, olympus-base-cpp, `ninja -j6 reindexer`):
159/401 library steps in 5 min 35 s (15:04:24 -> 15:09:59 UTC), with RAM at 1.6 GB available and
the harness reaping background shells for memory pressure. I stopped the container (`docker stop
hunt26-rx`, --rm) to protect the session. A linear extrapolation gives ~14 min for the library alone
before the gtest binary, and apt (leveldb/snappy) plus cmake come on top. **The cold build is far
past the 600 s environment start (L62).** The only way out is a Dockerfile that builds a trimmed
library (and test.sh building only the incremental delta), and the reindexer lane's tests need the
one monolithic `tests` binary (~103 TUs). Verdict: reindexer stays WEAK, and it is not RANK 1 grade
under L62 unless the platform builder is ~2x faster than this host.

### greatscottgadgets/luna (agent) — WEAK
Best lane: descriptor-driven chapter-9 device state inside the USB2 gateware. That means validated
SET_CONFIGURATION, SET/GET_INTERFACE with alternate settings, SET/CLEAR_FEATURE endpoint halt,
GET_STATUS, and scoped data-toggle resets. Discard seam: the configuration tree is flattened into
ROM bytes (`request/standard.py:60-85`, `usb2/descriptor.py:202`), and the request FSM (TODOs at
standard.py:140-265) and the endpoint layer never see it. F2P reproduced with the repo's own
USBDeviceTest host model. The misdirecting cell: after a second SET_CONFIGURATION an OUT DATA0 is
ACKed and its data silently dropped (the toggle is never reset). Traps are T1 (inverted-PID storage
in USBInTransferManager, reset during a retransmit, transfer.py:117-119 vs 266-271), T2 (halt with a
buffered IN packet), T3 (OUT FIFO `transfer_active` boundary state) and T4 (per-interface reset
mask). Honest ~240 (lean passer ~170-190), core ~150; ~255/~170 with a function-side halt writer.
Guard: Q1 y, Q2 partly, Q3 n, Q4 #4 partial FAIL (USB 2.0 chapter 9 is a famous spec, and same-org
facedancer implements the rules in software; several downstream projects hand-write
SET_INTERFACE). Exclusivity is clean (3 PRs, 64 forks, 0 sig). 93 tests in ~37 s, identical 3x;
USB2 cold for 12 months; quota 0/6. Risks: Amaranth-FSM 0% solvability (needs a smoke run), and new
gating inputs must default open. Other lanes: rx-error provenance ~100 (no consumer since the
analyzer moved to cynthion); speed-aware descriptors ~150; iso MDATA ~100 (next to #295); USB3
LPM = #77/#74 magnets. Dossier `s_0923h26/agents/luna.md`.

L62 second measurement (reindexer, the cheapest configuration): Debug `-O0`, `ninja -j4 reindexer`,
unloaded, olympus-base-cpp. cmake 15:11:5x, ninja 15:12:02 -> 15:22:13 UTC = **10 min 11 s for the
library alone** (401/401, LIB_OK; RAM stayed >= 4.4 GB available). The lane's tests live in the one
monolithic `tests` gtest binary (~103 TUs), which adds several more minutes. Against the 600 s
environment start (cwerg: 704 s local failed on the platform, 413 s passed), **reindexer is
Docker-infeasible. Lane B is DEAD on L62, not WEAK.** Moving the test-binary build into test.sh does
not rescue it: the library alone is over the limit. Containers were removed (`--rm`; the stale
`rxprobe_0923` from the cut agent was removed too). No build output on `/`.

## Ranking after all 8 verdicts

| Repo | Verdict | Honest total / core | Killer |
|---|---|---|---|
| Restream/reindexer | DEAD (L62) | ~260 / ~185 | cold library build 10-14 min before the tests binary |
| walles/riff | WEAK | ~245 / ~200 | 5 short of the 250 bar; ★527 thin margin; exact-ANSI goldens |
| greatscottgadgets/luna | WEAK | ~240 / ~150 (255/170 with a halt writer) | at the line; Q4 #4 partial (chapter 9 + facedancer rules); Amaranth 0% risk |
| macs3-project/MACS | WEAK | ~190 (225) / ~110-145 | under both numbers; Q4 #1 wrap risk |
| suzieq, CppNumericalSolvers, three-mesh-bvh | DEAD | 175 / 220 / 250-perf | absorbed / standalone header measured at 80 eff / performance-only |
| tyrasd/overpass-turbo | DEAD | - | vendored LGPL (jsolait lzw) + WTFPL |

No lane clears BOTH hunt-26 honesty numbers (total >= 250 AND core >= 150) without a hard blocker.

## Stage 6 guard
No RANK 1 to guard. Guards run by the agents: reindexer B passed Q1-Q4 (it dies on Docker, not
the guard); riff Q1 y / Q2 partial / Q3 partial / Q4 pass-with-risk; luna Q4 #4 partial fail; MACS
Q4 #1/#2 risk; suzieq, cppnum and tmbvh fail Q3/Q4.

## Stale rows for the human (SATURATED-REPOS.md not edited)
- tyrasd/overpass-turbo: 09-23-B recorded MIT-clean + Stage 6. The real kill is the vendored LGPL
  `js/misc.ts:8` (lzw_encode/decode live, imported by the share-link code) plus WTFPL code.
- netenglabs/suzieq (09-20-C fallback): path-as-of-time already works (`PathObj(end_time=...)`); drop
  it from fallback lists.
- PatWie/CppNumericalSolvers (09-20-B fallback): the seed lane was measured at an 80-eff standalone
  header; expression-template layer absorbs new maths. Drop it.
- gkjohnson/three-mesh-bvh (09-21 fallback): the seed is ~70-100 eff and value-vs-cost; the base suite
  has a 5000 ms timeout flake in MeshBVH.options.test.js (3 of 8 runs).
- Restream/reindexer (09-20-B fallback): Docker-infeasible (cold library 10 min at -O0 -j4, 14 min
  Release -j6 extrapolated). Latent bug on file: `hasUnsupportedAggregations` in rx_selector.cc
  always returns true (`!= AggCount || != AggCountCached`).
- sig_accounts.txt: + arbelonson-source, + tabbymarshlwio0-rgb (done this hunt). New notes:
  `cindykrafft` fork of MACS carries a Claude-co-authored `fix/keepdup-auto-control-threshold`
  (dedup lane); consider it for the signature list.

## Budget spent
Pool and cached index triaged without a fetch (K/J already exhausted them). One workshop of 8
cached-fallback repos (7 agents + 1 replacement), cut once by an API session limit and resumed in
three waves of at most 3. Two local Docker build timings (reindexer). No fresh niche sweep: K's two
sweeps returned 0 survivors on a ~98%-fetched topic space, so a third would cost more than it could
return. Disk: 15G free at the end; agent build output deleted (node_modules, venvs, target, build).
Clones kept: s_0923h26/{reindexer,overpass-turbo}, plus the refreshed older clones.

## Result: NO-CANDIDATE
FALLBACKS (neither clears the two-number bar, orchestrator's call): walles/riff (conflict regions in
one-column unified diffs: remerge-diff resolved conflicts + `git diff HEAD` unresolved markers,
~245/200, F2P reproduced, exclusivity clean); greatscottgadgets/luna (descriptor-driven chapter-9
device state with scoped data-toggle resets in the USB2 gateware, ~240-255/150-170, F2P reproduced
incl. the silent OUT data loss after re-configuration; a smoke run is mandatory).
Next hunt: the workshop over CACHED FALLBACKS is now exhausted (every 09-19..09-21 fallback has a
verdict). Either (a) let a builder spike riff's or luna's core slice and measure human-eff before
committing (both fall 0-10 short of 250 on paper), or (b) workshop NEW domain engines whose pipeline
discards state. Pre-screen every C++ engine for L62 (time a cold library build before any lane
work), and read every vendored file header for licence (overpass-turbo slipped past two hunts).
