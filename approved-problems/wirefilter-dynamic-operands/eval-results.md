# eval-results.md — wirefilter-dynamic-operands

## Local validation (pre-platform)

| Check | Result |
| ----- | ------ |
| Repo baseline green on base (`cargo test --workspace`) | PASS (120 engine + 13 ffi + 23 ctests + 2 doc) |
| Repo baseline still green with solution (`cargo test -p wirefilter-engine --lib`) | PASS 120/0 |
| New suite passes with solution | PASS 109/0 (99 plus 10 added across three coverage/quality rounds) |
| New suite fails on base (F2P) | PASS 109/109 fail |
| Vanilla workspace compiles offline-relevant targets (`cargo check --workspace --all-targets`) | PASS (engine, ffi, wasm, fuzz/*) |
| human-effective LOC (hook, Counter 2) | 494 (>= 430 target) |
| raw added / files | 758 / 7 |
| Patch encoding + modes | ASCII, LF, `test.sh` at `new file mode 100755` |
| Comments added by the patches | doc comments only, matching the repo's own `///` convention; no `//` prose, no TODO/FIXME |
| Test filename markers (`shipd` / `datacurve`) | none (`operand_expr_7972d7.rs`) |

## Docker 4-cell (olympus-base-rust, `--network none`, `--user 1000:1000`)

Built from a fresh `git archive BASE` tree, patches applied with `git apply`.

| Cell | State | Mode | Expected | Result |
| ---- | ----- | ---- | -------- | ------ |
| 1 | test.patch only | base | pass, no regressions | PASS, `tests="120" failures="0"` |
| 2 | test.patch only | new | all fail (non-empty F2P) | PASS, `tests="109" failures="109"` |
| 3 | test.patch + solution.patch | base | pass, no regressions | PASS, `tests="120" failures="0"` |
| 4 | test.patch + solution.patch | new | all pass | PASS, `tests="109" failures="0"` |

Determinism: new mode run 3x in-container, identical `tests="109" failures="0"` each time; base mode
re-run identical. Both apply orders are clean (test.patch then solution.patch, and solution.patch
then test.patch). JUnit XML carries one named node per test in every cell, so a failing base run
reports 109 individually named failures rather than an empty suite.

The Dockerfile removes `rust-toolchain.toml` before building: the repo pins `channel = "stable"`,
which is not an installed channel in the offline base image (it ships 1.95.0 as the default
toolchain), so leaving the file in place makes every cargo invocation try to download a toolchain.

Re-validated end to end after the only post-validation change (re-exporting `ContainsElement` from
the crate root so the new public enum variant names a reachable type).

## Test-scope note

`test.sh base` runs `cargo test -p wirefilter-engine --lib`, the engine's own 120 unit tests. That
is where the whole AST, parse, compile, execution and serialization surface is covered, including
every path this change touches (comparison lexing and compilation, index access, the visitor, and
the exact serde shapes of existing AST nodes). The `ffi` and `wasm` members are unchanged by the
solution and are excluded from base mode to keep the run free of the C toolchain and of
`cbindgen`; they still compile in the image.

## Solvability

Proven by construction: the reference implementation passes 109/109 while the base fails 109/109. The
new suite exercises only pre-existing public API (`Scheme::parse`, `FilterAst::compile`,
`FilterAst::uses`, `Filter::execute`, `ExecutionContext::set_field_value`), so no unstated
signature can zero a run.

## Platform batches

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
| ----- | ----- | --------- | ------- | ---- | ----- | --- | ------------ | ------------- |
| pending | | | | | | | | |
