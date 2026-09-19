# Repo hunt 2026-09-19-E — four more niches (storage, physical science, optimisation/statistics, documents/VCS/imaging); oxipng best of sweep

Fifth hunt of the day. messageformat (09-19-D RANK 1) still owes the Requirement 0 picker check;
csbindgen is in `problems/`. Same softened gates as sweep D (`worktrees/_hunt/agents/BRIEF-0919-E.md`,
which defers to BRIEF-0919-D). ~190 slugs screened across four subagents, 12 lane audits; dead list
now `worktrees/_hunt/deadlist_v9.txt` (5,170). Per-repo reasons: `agents/{storage,physsci,optstat,docvcs}-0919E.md`.

| Niche | Screened | Result | Closest misses (killer) |
|---|---|---|---|
| storage engines | 40 | FALLBACK | libspatialindex (below); tile38 (maintainer 2.0 geofencing rewrite due, #816); moka (Caffeine port, README roadmap claims lanes); PyTables OPSI lanes parked |
| physical science | ~53 | FALLBACK (weak) | nglviewer/ngl triclinic PBC (~215 eff, lean 170-200); skyfield (frame lanes under open PRs #798/#839); iris #4872 (<100-line aux-coord shortcut); avogadrolibs (AI-assisted feature stream); ketcher/OpenMS AI sweeps; pymatgen hollowed into pymatgen-core; cartopy red CI |
| optimisation / statistics | 37 | FALLBACK (weak, near-dead) | statsmodels statespace `compose` (~250-300 ref, lean 150-200, and pymc-extras `structural/core.py:849-944` ships the block-diag assembly = same-language sibling); pymc order stats (maintainer program + GSoC idea); cvxpy (125 AI trailers); EJML fusion unobservable |
| documents / VCS / imaging | 62 | **best of sweep** | oxipng (below); git-branchless (~40-line libgit2 shortcut, jj sibling); jsPDF-AutoTable (public PRs, pdfmake ships colSpan); camelot (maintainer shipped multi-page tables May 2026) |

## OUTCOME (same day): oxipng authored to a validated core slice, then killed at the precheck
Overlap Blocker x3: an older APNG-wide reduction submission (181/407 = 44.5%) plus an older
canvas/cropping submission (199/407 = 48.9%), union ruled a set-level derivative. Risk 1 below was
the killer. `rejected/oxipng-apng-frame-optimization`, TOO-EASY.md entry + new taxonomy row.

## Best of sweep — oxipng/oxipng (Rust 100%, MIT verified, ★4.2k) — APNG reductions + frame optimisation

- Lane: run the single-image reduction chain jointly over the default image and every frame (shared
  IHDR/PLTE/tRNS, evaluator scored on total bytes), plus frame cropping to the changed canvas region
  and duplicate-frame folding with delay addition and the acTL count rewrite, composite animation
  unchanged. Today `headers.rs:346-353` disables every reduction for APNG ("APNG detected, disabling
  all reductions"); CHANGELOG:57 "reductions still not supported yet".
- Missing algorithm: cross-frame reduction admissibility (palette union + remap, tRNS key unused in
  every frame, shared depth across frames of different sizes), raw APNG compositing (dispose/blend,
  hidden default image, 16-bit), minimal changed rectangle, duplicate folding.
- Size: 7 decision points, 310-455 eff; leanest passer ~230-280. Reductions ALONE die to a 120-150
  line stack-frames-into-one-image shortcut, so the crop/dedup stage must carry the traps.
- Seams: first frame's fcTL in `aux_chunks` vs later frames in `png.frames` (png/mod.rs:96-114);
  acTL copied verbatim; `sanity_checks.rs:28` requires equal frame counts (dedup breaks it);
  evaluator scores one image (evaluate.rs:38-44); `image`-crate canvases drop 16-bit and never see the
  hidden default image (partial shortcut, misdirecting).
- F2P on base: 3-frame 4-colour APNG stays RGBA8; the same frame as a static PNG reduces to 2-bit
  indexed. `cargo test --release` 296 tests, 3x identical, 27 s build.
- Exclusivity (orchestrator re-checked): no APNG-reduction PR in any state (APNG PRs #88/#511/#626/#668
  all merged groundwork); only branch `79-APNG-Support` (2018) is parse-only; no Rust sibling ships it;
  apngopt (C++) ships stage 4.
- ⚠️ Risks, orchestrator-verified:
  1. **Derivative magnet.** Issue #551 "Feature-complete APNG optimization", open since 2023-08,
     busy and user-bumped ("how close are we?"), and andrews05 published the 4-stage plan there
     (stages 3-4 = this lane). Not the uncommented-issue hard-reject row, but it is Stage 2d's
     "welcomed, spec-named, long-lived" worst case: every author searching the tracker sees it.
  2. **Maintainer in the adjacent code.** andrews05 has refactored filtering, sorting, palette and
     transformation performance every month Apr-Jul 2026 and names reductions as the next APNG step.
     Re-run PR and commit search at submit.
  3. apngopt is a public C++ implementation of stage 4; the sibling-library rule is same-language, but
     the scope gate may still read crop/dedup as cribbable. Keep the hard part in the joint-reduction
     admissibility, which apngopt does not do the same way.
- Verdict: behind messageformat. Author only after a reference spike shows the crop/dedup +
  joint-reduction core above ~250 human-eff, and phrase meta.md on oxipng's reducer/evaluator/frame model.
  Clone kept: `worktrees/_hunt/e_docvcs/oxipng` @ `36f3ef8a` (source only).

## FALLBACK — libspatialindex/libspatialindex (C++ 93%, MIT per COPYING, ★798)

- COPYING opens with a licensing-history note (LGPL before 1.8.0); the licence is MIT and no source
  header carries GPL text (orchestrator grep). GitHub shows NOASSERTION for that reason.
- Lane: temporal kNN on MVRTree (historical, over a query interval) and TPRTree (predictive, moving
  objects), plus temporal selfJoin. Both throw "not implemented yet" since the 2007 import; the C API
  `Index_TPNearestNeighbors_*` / `Index_MVRNearestNeighbors_*` already calls into the throws.
- Missing algorithm: minimum distance over [t0,t1] between a moving query and a moving MBR (piecewise
  quadratic, minimised over sorted breakpoints); the repo has only an integral (`getCenterDistanceInTime`).
- Size: D1 kernel 60-80, TPR kNN 45-60, MVR kNN 50-65, selfJoin 60-90 = ~215-295; floor needs selfJoin.
  ~90-line copy-the-RTree-loop shortcut fails mid-interval closest-approach cells.
- Base gtest 27/27 x3. Outside contributor `pangwangshu` has a coherent vector-DB footprint (milvus,
  qdrant, vespa): genuine, not a signature account. hobu used Codex to port a test (outside lane).
- Risks: missing-arm shape with one new-maths point; TPR flaky under Debug with random data (#247), use
  fixed small inputs. Clone: `worktrees/_hunt/e_storage/libspatialindex`.

## Ranking across today's hunts
1. messageformat/messageformat (09-19-D): owes the picker check.
2. oxipng/oxipng: magnet + maintainer-adjacent risk, strongest size.
3. libspatialindex: marginal LOC.
4. nglviewer/ngl, statsmodels compose, hftbacktest, pdfmake: weak.
