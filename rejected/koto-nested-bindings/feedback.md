# feedback.md — koto-nested-bindings

## Summary

Olympus submission against [koto-lang/koto](https://github.com/koto-lang/koto) at
`c579dcd02f015e0855d9495d10c7a4479fb82b0c` (Rust, MIT, 882 stars, HEAD 2026-08-06).
Invented feature: nested tuple patterns and rest captures at every binding site (assignment,
`let`, `for`, `catch`) with iteration semantics, plus middle-position rests in `match` and
function arguments. DESIGN.md holds the design; this file tracks rounds.

Pick provenance: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-09-B.md § PASS 3`.

## Attempt history

| Round | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-10 | DESIGN.md written | — |
| 1 | 2026-09-10 | Implemented: `IterUnpackRest` op (op/instruction/reader/vm), parser binding arms + expression-list rest hook + tuple-target validation, compiler kernel `compile_unpack_targets` used by assignment / let / for / catch, multiple-rest error | 51 new tests pass; workspace regression: `compile_failures::match_ellipsis_out_of_position` |
| 2 | 2026-09-10 | Dropped the match/function-arg middle-rest lever (it superseded an existing repo test, L31); middle rest stays in bindings where the kernel gives it for free; meta reworded | 378 human-effective / 470 counter-1 / 6 files; compile_failures 14/14 |

## Validation ledger (2026-09-10)

- Effective LOC: hook `human-effective` 378 (counter-1 470, raw 515), 6 files across parser / bytecode / runtime. The hook's padding-floor (19) is an artifact of the match-arm-heavy compiler code, not repetition of a registry.
- New tests: 51 in `crates/runtime/tests/nested_bindings_<hex>.rs` (mod `nested_bindings`, so base mode's `--skip nested_bindings` excludes them by name); fail-on-base and 3x flakiness recorded below when the background jobs finish.
- Comment convention: koto doc-comments ops (`///`) and uses short `// e.g.` comments in the compiler; the added comment lines follow that style.
- Round 3 (2026-09-10): every baseline test tied to a feature assertion (51/51 fail on base, 51/51 pass with solution; `check_fails` now panics on a compile error so runtime-failure tests cannot pass vacuously on base). Workspace suite green with the solution (`compile_failures` 14/14 after dropping the match/args lever). Mutation sweep: 13/15 well-formed mutations killed; the 2 survivors were redundant code (temp-tuple path bypass, top-level `for` export walk) and were REMOVED, not tested around. Final: 358 human-effective, 6 files.
- Docker (definitive): Pattern A image (`cargo install cargo2junit && cargo fetch && cargo build --workspace`) built from a clean checkout of BASE + test.patch, and again + solution.patch. Runs as the image user with `--network none` (uid-1000 runs fail on the root-owned `target/.cargo-lock`, the known local artifact DOCKER.md line 155 documents; the platform remaps users). test-patch-only image: base 1099 testcases / 0 failures, new 51 / 51 failures. Full image: new 51/51 pass x3, base 1099 pass x3, identical. base mode is `cargo test --workspace --lib --test '*'` because the `koto` crate declares its criterion bench with `test = true`, which `--workspace` and `--tests` both run and which rejects libtest arguments (exit 2, JUnit truncated at 32 cases) - documented reason for the target selection. Patches apply and unapply in both orders.

## OUTCOME: REJECTED 2026-09-10 — DERIVATIVE OVERLAP (no batch ever run)

Platform overlap check, verdict `Drop` / `Blocker`:

> Older Koto candidate already supplies the central nested/rest binding machinery for assignment,
> let, and for; 258 of 489 authored submission lines correspond (52.8%). The submission's iterator
> policy and catch/export extensions do not replace that recycled core. No independent upstream or
> repository-scope blocker was found. An older accepted task already carries the primary
> implementation challenge.

- Killed at PRECHECK, before any rollout batch. Zero agent tokens spent; the cost was the authoring
  arc (3 rounds, mutation sweep, Docker validation, flakiness gate).
- Not contestable: the correspondence is measured on authored LINES against an ACCEPTED task, and
  the judge pre-rates bolt-ons as incremental.
- Root causes and reusable laws: `Instructions/TOO-EASY.md § koto-nested-bindings`.
  Lane ledger: `Instructions/SATURATED-REPOS.md § B2-KOTO` (repo now DO-NOT-PICK).
- Folder quarantined in `rejected/` for reference only. Do not resubmit any slice of it.
