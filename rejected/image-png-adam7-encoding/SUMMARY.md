# SUMMARY - image-png static Adam7 encoding

**Status: TERMINAL — rejected for prior-work overlap on 2026-08-15; do not
submit or calibrate.**

## Target

| Field | Value |
|---|---|
| Repository | `image-rs/image-png` |
| Repository URL | <https://github.com/image-rs/image-png> |
| Base commit | `721fd56651038c51bb3a6c2eabe9ab11b086db6e` |
| Production language | Rust |
| License | MIT OR Apache-2.0 |
| Task type | feature request |
| Task | Encode static PNGs with Adam7 from ordinary row-major raster input across existing color/depth, filtering, compression, and producer surfaces. |
| Platform state | rejected before calibration; archived |

## Canonical artifacts

| Artifact | Current fact |
|---|---|
| `meta.md` | frozen; hash `bf10cb00` |
| `test.patch` | frozen; 17 focused JUnit cases; hash `cb5912a5` |
| `solution.patch` | frozen; two production files; 220 strict-effective additions; hash `af00d4c4` |
| `Dockerfile` | frozen; exact Phase A/B pass; hash `52358a81` |
| `solution_approach.md` | present |

## Verification

| Gate | Expected | Latest result |
|---|---|---|
| trajectory-informed design | complete before tests | pass; recorded in `DESIGN.md` |
| upstream ownership | no exact implementation or decline | pass on 2026-08-15 |
| pristine Phase A | offline build/tests as arbitrary UID | pass: 105 passed, 1 ignored |
| cheapest complete implementations | two coherent architectures | pass: 231 and 220 strict-effective additions |
| exact evaluator composition | baseline fail-to-pass; reference pass | pass; pristine 0/17, reference/direct-row 17/17 |
| gap/fairness/false-positive | exact-version pass | pass; 16/16 current mutations caught |

## Historical local result

At the pinned repository head, PR #681 documents the gap but deliberately
supplies only an error, while active APNG work is excluded. Independent
direct-row and pass-buffer implementations pass the full suite at 231 and 220
strict-effective production additions. Exact environment, gap, fairness, and
false-positive gates passed on the frozen L1 artifacts.

## Outcome

Closed. External review reported that the problem had already been done. That
prior-work verdict supersedes the local ownership screen and is terminal even
though the package remains locally reproducible. No solver run started, and
the successful-solver median and platform difficulty band remain unmeasured.
