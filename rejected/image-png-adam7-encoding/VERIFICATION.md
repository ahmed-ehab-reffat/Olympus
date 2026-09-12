# Verification - image-png static Adam7 encoding

Verdict: **local exact-version checks pass; external prior-work rejection is
terminal and calibration is closed at 0/10**.

Repository pin:
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

Artifact hashes are recorded in `ENVIRONMENT.md` and
`FALSE_POSITIVE_AUDIT.md`.

## Exact evaluator matrix

| Tree | `test.sh base` | `test.sh new` |
|---|---:|---:|
| pristine + tests | pass: five real upstream groups | fail: 17/17 JUnit cases |
| reference + tests | pass | pass: 17/17 |
| direct-row replay + tests | pass | pass: 17/17 |

The final automated environment gate passed with networking disabled, arbitrary
UID/GID 10001, read-only source injection, real JUnit output, and matching
baseline/reference feature identities. The underlying base suite is 105 passed
and 1 ignored.

## Static and style checks

- `test.patch` and `solution.patch` apply cleanly to the exact pin and in the
  required composition order.
- Hidden paths are additive and do not overlap `src/adam7.rs` or
  `src/encoder.rs`.
- `git diff --check` passes for the test, reference, and direct-row trees.
- `cargo fmt --all -- --check` passes for both legitimate implementations and
  the additive Rust test.
- Stable all-target Clippy is not a differential gate because the pristine
  repository reports existing warnings under Rust 1.93.1.

## Behavioral audits

- Gap analysis: pass on the exact version.
- Fairness analysis: pass on the exact version.
- False-positive audit: pass; all 16 current mutations are caught.
- Architecture replay: pass for materialized pass buffers and direct row
  extraction.
- Upstream ownership audit: no exact implementing issue, PR, branch, release,
  discussion, or linked fork found as of 2026-08-15.

No platform solver calibration started. Local verification establishes only
historical reproducibility; it does not override the external finding that the
problem had already been done.
