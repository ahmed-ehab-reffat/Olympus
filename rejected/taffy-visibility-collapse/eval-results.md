# eval-results — taffy visibility:collapse

## Platform evals
None yet. Pending derivative check + (if it clears) Nova/Vega batch.

## Local Docker validation (olympus-base-rust, 2026-07-21)

Environment: container built from olympus-base-rust:latest, taffy @ bb351fcc, cargo 1.95.0,
cargo2junit 0.1.15. Commands via test.sh (base/new), JUnit via RUSTC_BOOTSTRAP=1 --format json | cargo2junit.

| Check | Command | Result |
|---|---|---|
| Baseline build | `cargo build` | OK |
| Full existing suite + solution | `cargo test` | 4421 + 105 + 43 + 5 pass, 0 fail (4 pre-existing ignored) |
| Patches apply (order test->solution) | `git apply` | OK |
| Patches apply (order solution->test) | `git apply` | OK |
| Patches reverse (`-R`) | `git apply -R` | clean |
| BASE mode, base commit | `./test.sh base` | exit 0 (PASS) |
| NEW mode, base commit (fail-on-base) | `./test.sh new` | exit 101, 1 testcase / 1 failure (compile-error fallback) |
| BASE mode, with solution | `./test.sh base` | exit 0, 4573 testcases, 0 failures |
| NEW mode, with solution | `./test.sh new` | exit 0, 5 testcases, 0 failures |
| Flakiness new x3 | `./test.sh new` | exit 0, 0, 0 (deterministic) |
| Flakiness base x3 | `./test.sh base` | exit 0, 0, 0 (deterministic) |
| Docker image build | `docker build` | NOT RUN (host disk filled; Dockerfile is canonical Rust pattern) |

## New tests (5, all black-box via public TaffyTree API)
- collapsed_item_has_zero_main_size
- sibling_absorbs_collapsed_space_when_growing
- visible_sibling_layout_is_unchanged
- collapsed_item_still_present_unlike_display_none
- collapse_in_non_flex_container_is_unchanged

## Notes
Probe is single-axis (zero main size); no strut/two-pass yet, so the difficulty is Mars-level
by design. This batch validates plumbing + fail-on-base + determinism only, not difficulty.
Difficulty is only assessable after the full step-10 build + a real Nova/Vega batch.
