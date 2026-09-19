# Repo hunt 2026-09-19-G — factory hunter #2 (CONSECUTIVE_MISSES=0); libspatialindex promoted to RANK 1 (TPR-centred pivot)

This is the second `olympus-factory` hunt of the day. During the run, the orchestrator marked
messageformat/messageformat as CLAIMED (the human is authoring it) and released its fallbacks, MACS
and libspatialindex. csbindgen and oxipng have `problems/` folders and are taken.

The gates are the skill as written, including the 2026-09-09-B softening already in SKILL.md. The
extra BRIEF-0919-D softenings were not applied because the miss count is 0, and the star and issue
windows were not widened. Requirement 0 (the platform picker) cannot be checked by an agent and is
marked OWED.

Order followed: proven pool (0-bis), then the cached band, then two fresh niche sweeps with brief
`worktrees/_hunt/agents/BRIEF-0919-G.md`: terminal engines (tag `term`) and linked-data / graph-query
/ rating engines (tag `ld`).

| Step | Result |
|---|---|
| 0-bis proven pool | ir-sim was the only pool repo with unaudited lanes (named in 09-19-F). All of them are dead. **Planners:** A*, JPS, RRT, RRT*, informed RRT* and PRM are textbook algorithms whose docstrings cite PythonRobotics and jps3d, so a sibling library ships the hard part. **Sensors, behaviors and maps:** all sit in the maintainer's own stream (#353 lidar perf, #360 "robustness fixes from a code review of sensors", #369 sfm groups, #337 fog map). That stream is AI-assisted: the repo has a CLAUDE.md, one Claude co-author trailer and about 20 Copilot trailers in 12 months. **Invented lane, snapshot/restore of a running env:** ABSORBED. `copy.deepcopy(env)` after 15 steps reproduced the next 30 steps exactly (max abs diff 0.0) on all 7 scenes tried (noise, 3 sfm, 3 fog). Every other pool repo already has a verdict in SATURATED-REPOS B2/B3 (B3-bis .. B3-duodecies) |
| Cached band | `unshown_0919.txt` was re-filtered against the new `deadlist_v10` (v9 + bio/fab screened slugs, 5,285 slugs); 314 rows remain. They are still app, web, ML or tooling junk. The only engine-shaped rows were lf-edge/ekuiper (a SQL stream engine run by a company team) and pinyin-pro (max-match segmentation plus the pypinyin sibling), and neither is worth a screen |
| Sweep `term` | 38 screened and about 23 killed on metadata. FALLBACK: walles/riff (below). Closest misses: pyTermTk reflow on resize, where scrollback already stores logical lines so a 60-100 line replay shortcut passes; termdash min-size splits at 150-200 eff with a shortcut under 100 lines; rustyline, where visual mode #335 and inputrc #303 are long-open magnets that reedline and linefeed already ship. 4 new signature accounts were appended to `sig_accounts.txt`. Dossier `agents/term-0919G.md` |
| Sweep `ld` | 47 screened plus 10 killed on metadata; no survivor. **Rating, voting and tournament engines:** nothing at 500 stars or more with a permissive licence and a live repo. **Licence kills:** BSL/SSPL (memgraph, FalkorDB, surrealdb, arangodb), MPL (cozo, eliasdb, indradb) and UPL (souffle). Closest misses below. Dossier `agents/ld-0919G.md`, with a reusable probe at `agents/f_ld_jena_rete_probe.java` |

**`ld` closest misses:**
- **apache/jena, RETE incremental retraction.** The F2P reproduces: FORWARD_RETE over-deletes and FORWARD under-deletes. It dies to a 20-line reset-and-rebind shortcut that HYBRID already uses.
- **GrafeoDB/grafeo.** AI-built, with 20 open PRs claiming the lanes.
- **N3.js reasoner.** An AI sweep reaches the lane, and HyLAR, a sibling library, ships DRed.

## RANK 1 — libspatialindex/libspatialindex (C++ 2.83 MB of 3.14 MB, MIT, ★798)

- **Mechanics (re-checked today):**
  - C++ is the primary language.
  - COPYING is MIT since 1.8.0; the LGPL note covers only earlier releases, and the vendored gtest is BSD-3.
  - The `Test` workflow is `success` on main (09-06, 09-09).
  - Real code commits in the window: #303 (NaN rejection, 2026-09-09), #304, #302, #292.
  - 0 open PRs.
  - Quota is 0/6; the repo is not in SATURATED § A/A0 and has no workspace collision.
  - The base the 09-19-E audit used is still HEAD: `494d966f57727060d3cc6ac39a50ca5694dad5e8`, clean clone at `worktrees/_hunt/e_storage/libspatialindex`.
  - The gtest suite (27 tests) ran 27/27 three times in `olympus-base-cpp` (09-19-E). The Docker build plus tests takes about 1 min offline.
- **Outside contributor note:** `pangwangshu` has 2 PRs outside the lane (NaN rejection, gtest link). The account has a real name, 12 followers and its own project, but it also files scattershot fixes across qdrant, vespa, milvus, ragflow and ScienceWorld. One account outside the lane is a NOTE under 2b-bis.
- **Lane (pivoted to make the Stage 6 guard hold):** time-parameterised queries on the TPR-tree, all through ONE new kernel. The kernel is the minimum distance over `[t0, t1]` between a moving query (MovingPoint or MovingRegion) and a moving MBR whose reference time differs from the query's.

  Surfaces that consume the kernel:
  - (a) `nearestNeighborQuery`: internal-node pruning, leaf ranking, the default comparator, k with ties, and `max_dist`;
  - (b) `selfJoinQuery` over an interval;
  - (c) the C API TP entry points (`Index_TPNearestNeighbors_id/obj`, sidx_api.cc:1716/1775), already wired and today throwing.

  Coupled breadth, if the LOC spike needs it: historical kNN on the MVR-tree over the root forest, with liveness and id dedup across version copies.
- **Missing algorithm:** each per-dimension gap `max(0, a_lo(t) - b_hi(t), b_lo(t) - a_hi(t))` is piecewise linear, so the squared distance is piecewise quadratic between sorted breakpoints. The kernel must minimise it with a degenerate instant branch and extrapolate from each entry's own start time. The repo has no such kernel. `MovingRegion` and `MovingPoint` inherit the static `Region`/`Point::getMinimumDistance`, and the only temporal distance, `getCenterDistanceInTime`, is an integral of the centre distance, not a minimum. The throws at TPRTree.cc:349 and :361 and MVRTree.cc:336 and :348 were re-confirmed today.
- **Size (decision points):**

  | Decision point | eff |
  |---|---|
  | D1 interval kernel | 60-80 |
  | D2 TPR best-first kNN (horizon guard as in rangeQuery TPRTree.cc:1193, a time-aware comparator replacing the velocity-blind TPRTree.h:165-176, ties, max_dist) | 45-60 |
  | D4 temporal self-join | 60-90 |
  | TPR subtotal | 165-230 |
  | D3 MVR historical kNN | 50-65 |
  | **Total** | **215-295** |

  This is below the 250 buffer without MVR. The builder's first job is a reference spike to confirm ≥250 human-eff.
- **Shortcut test:** copy the RTree kNN loop and keep the velocity-blind comparator. That is about 90 lines. It passes MVR cells and TPR cells at the reference time, and fails every cell whose closest approach is mid-interval or late. A variant that samples t0, t1 and the midpoint also fails the mid-interval cells. No in-repo oracle exists, but a brute-force scan over the stored entries is a fair TEST oracle.
- **Trap seams:**
  - F-39: the inherited velocity-blind `getMinimumDistance` in both NNComparators.
  - F-39 (second): MVR rangeQuery dedups by data id and drops the nearer re-inserted version.
  - F-20: RTree.cc:630 routes leaf data through the IShape overload, never the IData overload.
  - F-10: query {point, box} x {moving, static} x {instant, interval}, and {k, ties, max_dist}.
- **Stage 6 death-class guard: PASS (with the TPR-centred pivot).**
  1. **Shared kernel:** yes. D1 feeds node pruning, leaf ranking, the comparator, max_dist and the self-join.
  2. **Interdependence:** yes on the TPR core. A kernel that is right at leaves but uses the static MBR distance for internal pruning silently drops true neighbours, which reads as a comparator or ranking bug (misdirecting). Fixing the comparator without the interval minimum still fails the late-approach cells, and the self-join shares the same kernel. The MVR half is independent, so it is breadth only and must not carry the band.
  3. **Standalone file?** No. The kernel lives inside the tree classes' private traversal and the moving-shape types.
  4. **Pre-Pick Guard:** not a uniform wrap; spans shape types, two trees and the C API. Its missing-arm SHAPE survives only because D1 is new mathematics, per Stage 3b.
- **Exclusivity (09-19-E, base unchanged since):**
  - Issues and PRs in all states for nearest/TPRTree/MVRTree/selfJoin/"not implemented": no hit.
  - Only one branch.
  - Active forks were diffed (BU-DiSC buffers, and others): none touch kNN or join.
  - Code search over about 40 vendored `TPRTree.cc` copies: no `NNEntry` kNN. `getMinimumDistanceInTime` has 0 hits.
  - No removal record in ChangeLog/NEWS or `git log -S`.
  - Sibling check: Boost.Geometry rtree has no TPR.
- **Risks:**
  1. **Magnet.** The `not implemented yet` throws are visible to any author scanning the tree. TP-kNN (Tao and Papadias) is textbook-adjacent, which is softened rule 6. Phrase meta.md on the repo's MovingRegion model plus its ties/max_dist semantics, and re-run PR-DIFF at submit.
  2. **LOC** is marginal on TPR alone.
  3. **TPR Debug assertions** trip on random data (#247/#248), so tests must use fixed small inputs and base mode is the gtest binary.

## FALLBACKS

1. **walles/riff** (Rust, MIT, ★527, `62ef8a73`; clone `worktrees/_hunt/f_term/riff`).
   - **Lane:** edit-tolerant moved-block detection across hunks and files, with numbered pairs and in-move refinement.
   - **Size:** about 255-370 eff, but the leanest passer is about 180-220.
   - **F2P reproduced; suite 62/62 three times.**
   - **Ranked below RANK 1:**
     - The lane is a README "TODO future" item since 2020 (a public pick list).
     - git `--color-moved` is the famous named algorithm, and gitbutlerapp/grit `diff_moved.rs` (Rust) ports git's exact version, so the sibling library ships the exact half.
     - The matcher can be written as a standalone module wired into two places, so it only partly passes guard Q3.
     - Stars sit near the floor.
2. **macs3-project/MACS** (Python, BSD-3). The q-value/segmentation blacklist lane is from 09-19-F. The #613 magnet and floor-level LOC still apply.

## Tooling

- `deadlist_v11.txt` (5,403 slugs) = v10 + `term`/`ld` screened slugs. Use it for the next sweep.
- `f_term/riff` is kept and `g_irsim` is deleted. Root is at about 9.0G free.

## Next hunt

If libspatialindex dies at the picker or the LOC spike, riff is the next spike, framed on the
edit-tolerant numbering contract rather than on git's exact rule. After that, fresh niches are close
to exhausted: 28 niche sweeps since 09-18. The next hunt should try a different discovery axis,
such as dependents of proven repos (GitHub "used by" of the approved set) or org-sibling repos of
approved-repo maintainers, not more topic niches.
