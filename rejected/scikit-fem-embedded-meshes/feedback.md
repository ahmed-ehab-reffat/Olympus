# feedback.md — scikit-fem-embedded-meshes

## Summary

Olympus submission against [kinnala/scikit-fem](https://github.com/kinnala/scikit-fem) at
`73e8357003d67ce267f39c74356a8f045bae99ab` (Python, BSD-3, 657 stars, HEAD 2026-09-04).
Invented feature: meshes embedded in a higher-dimensional ambient space (curves in R2/R3,
surfaces in R3, first and second order) through rectangular-Jacobian mappings, with the whole
basis/element/io stack riding the result. DESIGN.md holds the design; this file tracks rounds.

Pick provenance: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-09-B.md § PASS 2` (Gate 1
reproduced on base: MeshTri in R3 crashes in `MappingAffine._init_invA`; MeshLine in R2 silently
assembles a wrong mass matrix).

## Attempt history

| Round | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-09 | DESIGN.md written | — |
| 1 | 2026-09-10 | Implemented mapping-only slice (rectangular Jacobians, pseudo-inverse, Gram measure, finders, meshio strip rule, validity) | 135 human-effective: under floor. Machinery absorption law confirmed again: two shared helpers ate the sketch |
| 2 | 2026-09-10 | Added orientation propagation (simplex + quad, Moebius ValueError), induced normals in CellBasis, trace default type + boundary tags, tangential smoothing, Piola on surfaces | 242 human-effective / 270 counter-1 / 11 files; 79 new tests fail on base, pass with solution; base suite 544 pass |
| 3 | 2026-09-10 | Quad orientation/oriented, tangential smoothing, trace boundary tags; finders pick the closest inside candidate (folded-surface fixture) | 81 new tests, all fail on base, all pass with solution; base suite 544 pass; 23/23 mutations killed (per-branch, new mode) |
| 4 | 2026-09-10 | Pre-submit sweep: meta.md body was 507 words (over the 500 cap); dropped the explanatory clause about a surface losing its third coordinate | Body 496 words, still ASCII, 13 non-empty lines. Patches re-verified against the worktree (solution byte-identical; test identical with mode 100755). Hook human-effective 241 / 11 files. Ready for batch 1 |

| 5 | 2026-09-10 | Uploaded to the platform for precheck (no batch fired) | **SHELVED - DERIVATIVE.** LLM dedupe `derivative` sim 0.79 / conf 0.90 against an OLDER embedded-mesh submission by another author (authored 2026-09-06 04:34 UTC, three days before our hunt scope-locked the lane). All nine core surfaces shared (rectangular A/B, Gram measure, pinv gradients, CellBasis `n`, is_valid, trace coordinates, finders, strip rule). Our orientation / tangential smoothing / trace tags / ElementGlobal guard rated "incremental to the shared core". Folder moved to `rejected/`; entry in `Instructions/TOO-EASY.md`; lane closed in `SATURATED-REPOS.md § B2-SKFEM` |

## Validation ledger (2026-09-10)

- Effective LOC: hook `human-effective` 236-242 (final run below), padding-floor ~200, counter-1 ~264, 11 files, 4 packages.
- New tests: 81 in one file (`tests/test_embedded_<hex>.py`), 81/81 fail on base for feature reasons (lazy fixtures, no collection error), 81/81 pass with the solution.
- Base suite: 544 passed / 1 skipped with the solution applied (`tests/test_mamba.py` excluded in base mode: optional `mamba` module, same exclusion as the approved pick).
- Mutation sweep (23 single-branch mutations across mapping, mesh, finders, orientation, smoothing, trace, normals, global-element guard): 23/23 killed. Base-mode mutations for the S3 axis (meshio strip, `dim()`) are covered by `test_meshio_cycle` and the planar tests in the base suite.
- Docker (definitive, final patches, clean checkout of BASE): image with test.patch only: base PASS 544/1 skipped, new FAIL 81/81 (feature reasons, per-test); image with both patches: new 81/81 PASS x3, base 544 PASS x3, identical every run, `--network none`, uid 1000. JUnit XML has 81 / 545 testcases. Patches apply and unapply in both orders.
- Patches apply and unapply cleanly in both orders; test.sh mode 100755; ASCII; no banned markers; zero added comment lines in either patch.
