# feedback.md — tinywasm-exception-handling

## Summary

- Repo: explodingcamera/tinywasm (Rust, dual MIT/Apache-2.0, 569 stars, active — 110 source commits/12mo, single maintainer).
- BASE_COMMIT: 1d754813f178fc92afffe43e3ab638ddfc03cb66 (2026-07-15).
- Tier: Olympus. Feature: implement the WebAssembly exception handling proposal (tags, `throw`, `try_table` with the four catch forms, `throw_ref`, `exnref`) in the from-scratch WASM VM.
- Shape: O-Composite-add with an O-Algorithm-correctness core (cross-frame stack unwinding).

## Why this repo/feature (pick log)

Auto-discovery. First three Olympus attempts failed the depth/LOC floor and were dropped:
- jhump/protoreflect: only real gap (protoprint float `%f` rendering) is Mars-scale + a live maintainer workstream (fails COLD-NOT-LIVE) + editions already merged.
- egraphs-good/egglog: proposed container-`:merge` feature already shipped; repo is a firehose (517 source commits/12mo) actively developing that surface.
- zaeleus/noodles: region-query pipeline already implemented and correct on base; remaining gaps are pattern-followable templates + open PR #396 in the seam.
Go backups also dead (participle used + published algo; pigeon left-recursion merged; orb taken/derivative; xz dormant). Second gap-first discovery round surfaced tinywasm.

tinywasm gates (Phase B):
- License dual MIT/Apache-2.0 (both permissive). Stars 569 in band. Active, not firehose.
- Gap re-verified absent at BASE_COMMIT: no EXCEPTIONS feature flag, no TagSection arm, no try_table/throw_ref/exnref in visit.rs, no unwinding machinery in executor.
- Exclusivity clean: `gh pr list --state all` for exception/gc/reference-typed shows no PR; `next` branch grepped clean.
- Env-quality: `cargo test --workspace --lib` green + deterministic across 3 offline non-root runs (31 lib tests). `resume_execution` integration test excluded from base scope (it `include_bytes!`s a generated `fibonacci.wasm` not checked in — documented generated-artifact exclusion); the wast spec-suite tests need a submodule and are also out of base scope.

## Difficulty design (HARDENING)

Difficulty lives in DOING, not KNOWING (the EH spec is public; wasmparser decodes EH; a `wat` oracle exists). The hard, uncorrelated, misdirecting traps:
- S3 baseline-preservation: handlers must be removed on a branch OUT of a try_table, not only on normal exit; a stale handler wrongly catches a later throw (failure reads as a wrong catch).
- S4 machinery-riding: `throw` unwinds across call frames AND restores the split-width (s32/s64/s128) value stack to the try-entry snapshot; partial impls corrupt state (failure reads as wrong values).
- S2 composition: `catch_ref` + `throw_ref` + outer `catch` must preserve exception tag identity.
- Codebase-inferable (<=1): the `Instruction` enum has a `size_of == 16` invariant (repo test) -> new EH instructions must use side-table indices; NOT stated in meta.
Naive first-cut (same-frame value-only catch) passes the simple tests, fails cross-frame / cleanup / exnref.

## As-built (diverges from DESIGN.md, which was pre-code)

DESIGN.md planned first-class exnref value variants + an explicit snapshot-truncate. The built solution is leaner and idiomatic to the repo: exnref rides the existing single `ValueRef` lane (tinywasm already collapses all reference types to one lane), and catch landing pads reuse the existing `DropKeep`+branch machinery so the value stack restores for free. That elegance compressed the core to 279 human-effective LOC (under the 450 floor), so scope was EXPANDED with genuine orthogonal depth (not padding):
- Legacy exception-handling dialect: `try`/`catch`/`catch_all`/`delegate`/`rethrow` (a second unwinding dialect; delegate forwards to a handler at a label depth, rethrow re-raises an enclosing catch's exception by label depth). ~234 LOC of new lowering + unwind logic.
- Structured host-visible uncaught exception: `Trap::UncaughtException { tag, values }` with value marshaling back to typed `WasmValue`s, plus `Error::uncaught_exception`, `Trap::{is_uncaught_exception,uncaught_tag,uncaught_values}`, `ModuleInstance::exported_tag`, `Store::tag_param_types`.
- try_table / legacy try block-parameter handling.
Final: 458 human-effective LOC across 14 source files (3 crates), 47 tests.

The host API is a small named/supplementary surface (5 tests pin it); documented explicitly in meta's final paragraph (sanctioned O-Composite-add supplementary-API prose) so the meta->test FP mapping is fair. The other 42 tests are purely behavioral (WASM execution values / trap presence).

## Local validation (2026-07-20) — ALL PASS

- Docker image (olympus-base-rust) builds offline (rust-toolchain.toml removed so the image default 1.95.0 is used; no nightly download).
- STATE base+test (no solution): base 31/0 PASS (no regressions), new 47/47 FAIL (F2P — test file references solution-only host API, synth fallback emits 47 named failing nodes).
- STATE base+test+solution: base 31/0 PASS, new 47/0 PASS.
- Patches apply both orders + reverse cleanly; solution.patch source-only; test.patch = test.sh (mode 100755) + test file; ASCII+LF; no shipd/datacurve markers.
- human-effective 458 (>=450); instruction_layout_size_is_stable holds (16 bytes; side-table indices); 3x deterministic; offline --network none; non-root 1000:1000.
- Comment convention: matches repo (tinywasm doc-comments public API; the one inline `//` is a `// >` section header matching the enum's existing style); test bodies comment-free.

## Attempt history

- 2026-07-20: repo locked, gates passed, DESIGN.md written. Reference impl v1 (25 tests, 279 eff LOC, correct but under floor) -> expanded (legacy dialect + host API + block-params) to 458 eff / 47 tests. meta.md aligned (394 words). Full Docker validation green both apply orders. Solvability signal (1 blind Sonnet imitator, meta-only) running. Platform Nova/Orion/Vega batch is the required difficulty oracle (not run locally).
