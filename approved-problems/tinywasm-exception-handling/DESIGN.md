# DESIGN.md — tinywasm-exception-handling

## 1. Title

Implement WebAssembly exception handling in the tinywasm runtime

## 2. Shape classification

- Shape: **O-Composite-add** (new feature spanning parser -> instruction set -> compiler -> runtime executor -> store), leaning O-Algorithm-correctness on the unwinding core.
- Definition (PLAYBOOK Pattern 12): a net-new capability that must be threaded through several subsystems, where the hard locus is a subtle cross-subsystem correctness invariant (stack/frame unwinding), not a single local rule.
- Pass-rate target: 5-20% (hard Olympus). Bias to the low end; solvable by a strong long-horizon agent (Orion/Vega) reading the spec + the flat-control architecture.
- Best agent: Orion / Vega (heavy multi-file refactor + long horizon).
- Dominant verdict: MISSED_REQUIREMENT (partial impls miss cross-frame unwind, handler cleanup on branch-out, or exnref identity) + REGRESSION (a naive executor edit breaks existing control flow).

## 3. Public API surface (the WASM-level surface tests exercise via `wat`)

tinywasm has no Rust API for this; the "surface" is the WebAssembly instruction/module constructs the runtime must now accept and execute. Tests assemble modules with the `wat` crate and assert results/traps.

- `(tag $t (param ...))` — define an exception tag (a tag section entry); tag has a function-type-like parameter signature, no results.
- `(import "m" "t" (tag (param ...)))` — imported tag; identity is shared with the exporting instance.
- `(export "t" (tag $t))` — exported tag.
- `throw $t` — pop the tag's params off the stack, allocate an exception with those values, transfer control to the nearest matching handler; if none, the invocation fails with an uncaught-exception trap.
- `try_table (type $bt)? (catch $t $l) (catch_ref $t $l) (catch_all $l) (catch_all_ref $l) ... <body> end` — run `<body>` with the listed handlers installed; on normal completion the handlers are removed.
  - `catch $t $l`: if a thrown exception's tag equals `$t`, push its param values and branch to label `$l`.
  - `catch_ref $t $l`: push its param values, then push an `exnref` to the exception, branch to `$l`.
  - `catch_all $l`: match any tag, push nothing, branch to `$l`.
  - `catch_all_ref $l`: match any tag, push an `exnref`, branch to `$l`.
- `throw_ref` — pop an `exnref`; if null, trap; otherwise re-throw the referenced exception (its original tag and values are preserved).
- `exnref` — a new reference value type (nullable), produced by `catch_ref`/`catch_all_ref`, consumed by `throw_ref`; `ref.null exn` yields a null exnref.

## 4. Canonical output form

- **Handler search order:** innermost try_table first; within one try_table, catch clauses are tested in written order; first match wins.
- **Value-stack discipline on throw:** operands pushed by the body after the try_table was entered are discarded; the value stack is restored to exactly its heights at try-entry, then the caught values (and exnref for `*_ref`) are pushed in parameter order (exnref last).
- **Cross-frame unwind:** if the nearest matching handler is in a caller, all intervening call frames are discarded before control resumes in the handler's frame.
- **Uncaught:** an exception with no matching handler anywhere on the stack surfaces as a trap; the top-level `call` returns `Err` (uncaught exception), no results.
- **Tag identity:** two tags match iff they are the same tag definition instance (an imported tag matches the exporting module's tag); equal signatures with distinct definitions do NOT match.
- **exnref identity:** `throw_ref` re-throws the exact captured exception; an outer `catch $t` matches iff `$t` is the original throwing tag.
- **Handler cleanup:** exiting a try_table by normal fallthrough OR by a branch that targets a label outside it removes its handlers; a re-entered try_table reinstalls them.
- **Null exnref:** `throw_ref` on a null exnref traps; `ref.is_null` on an exnref works as for other refs.

## 5. Blind-spot pre-empts (<=1 codebase-inferable)

- Quote (result ordering): "the caught values are pushed in the tag's parameter order, followed by the exnref for the `_ref` catch forms."
- Quote (cleanup / iteration-termination): "a branch out of a `try_table` removes its handlers, exactly as it ends the block."
- Quote (unwind scope, S4): "`throw` unwinds across called functions to the nearest enclosing matching handler, discarding the intervening call frames and their operands."
- **Codebase-inferable (the single allowed one):** the internal `Instruction` enum keeps a fixed 16-byte layout (a repo test asserts `size_of::<Instruction>() == 16`); new exception instructions must carry side-table indices rather than inline catch lists. NOT stated in meta.

## 6. Description draft (meta.md) — see meta.md; <=200 words, plain prose

Covers: accept tag definitions/imports; `throw` semantics; `try_table` with the four catch forms; `throw_ref` + `exnref`; handler search order; value-stack restoration; cross-call unwinding; uncaught -> trap; tag identity. Does NOT mention the 16-byte constraint, handler-stack representation, or file names.

## 7. File footprint (sketched against real source)

| Action | Path | Cur LOC | Raw +/- | Meaningful (x0.65) | Reason |
| ------ | ---- | ------- | ------- | ------------------ | ------ |
| MODIFY | crates/types/src/instructions.rs | 458 | +34 | 22 | Throw/ThrowRef/TryTable(PushHandler)/EndTryTable variants w/ side-table indices |
| MODIFY | crates/types/src/lib.rs | 696 | +70 | 46 | TagType, TagAddr, Handler/CatchClause side-table types, exports |
| MODIFY | crates/types/src/value.rs | 234 | +40 | 26 | ExnRef value + WasmValue::ExnRef, ValType::ExnRef |
| MODIFY | crates/types/src/reference.rs | 112 | +30 | 20 | ExnRef newtype (nullable index) |
| MODIFY | crates/parser/src/module.rs | 490 | +55 | 36 | parse Tag section; tag imports/exports |
| MODIFY | crates/parser/src/conversion.rs | 272 | +45 | 29 | TypeRef::Tag, ExternalKind::Tag, exnref valtype conversion |
| MODIFY | crates/parser/src/visit.rs | 1089 | +140 | 91 | lower try_table/throw/throw_ref; build catch side-table; resolve catch labels; enable EXCEPTIONS feature |
| MODIFY | crates/parser/src/optimize.rs | 887 | +25 | 16 | keep new control ops through jump/label resolution |
| MODIFY | crates/tinywasm/src/store/mod.rs | 612 | +90 | 58 | tag address space; exception object arena; exnref alloc; handler stack |
| MODIFY | crates/tinywasm/src/instance.rs | 636 | +60 | 39 | instantiate defined + imported tags; wire tag addrs |
| MODIFY | crates/tinywasm/src/interpreter/executor.rs | 1636 | +170 | 110 | PushHandler/EndTryTable; Throw/ThrowRef unwind: search handlers, cross-frame pop, restore split-width stack, push values/exnref, resume at catch label |
| MODIFY | crates/tinywasm/src/interpreter/stack/value_stack.rs | 276 | +35 | 23 | truncate-to-snapshot helpers for s32/s64/s128; exnref push/pop |
| MODIFY | crates/tinywasm/src/error.rs | 334 | +18 | 12 | Trap::UncaughtException; Error linking for tags |
| MODIFY | crates/tinywasm/src/imports.rs | 282 | +25 | 16 | tag import linking |

TOTAL raw ~ +837, meaningful ~ **544** across **14 modified files**. Clears the 450 Counter-2 floor with margin. Files span 3 crates (types, parser, tinywasm) — genuine cross-subsystem.

LOC discipline: the executor unwind core + store handler/exception arena + visit lowering are the load-bearing logic (~260 meaningful); the rest is real wiring (parsing, types, linking), not padding.

## 8. Solution outline — helpers (1+ per behavior)

- `parse_tag_section(...) -> Vec<TagType>` <- accept tag definitions (module.rs)
- `convert_tag_import / export` <- tag imports/exports (conversion.rs)
- `lower_try_table(blockty, catches) -> (PushHandler(idx), body, EndTryTable)` + `catch side-table` <- try_table (visit.rs), label resolution reuses existing block-label machinery
- `lower_throw(tag) / lower_throw_ref` <- throw/throw_ref (visit.rs)
- `Store::alloc_exception(tag_addr, values) -> ExnRef` <- exception allocation (store)
- `Store::push_handler(catch_idx, call_stack_len, value_stack_snapshot)` / `pop_handler` <- handler install/remove (store) — fixpoint-free; a stack
- `find_handler(&self, thrown_tag) -> Option<HandlerHit>` <- handler search order (store/executor)
- `Executor::do_throw(exn) -> Result<(), Trap>` <- unwind: pop handlers above hit, truncate call_stack to hit.frame, restore self.cf, truncate value stacks to snapshot, push values (+exnref), set instr_ptr to catch label; else Err(UncaughtException)
- `ValueStack::truncate_to(base: StackBase)` <- restore all three widths (value_stack.rs)
- `Executor::exec_end_try_table()` <- normal exit pops the current handler (S3 cleanup); a branch out must also pop — handled by lowering DropKeep/Jump through EndTryTable or by recording handler depth per label.

No fixpoint loop (EH is not iterative); the load-bearing invariant is the unwind + handler-stack discipline.

## 9. Test outline (new file `crates/tinywasm/tests/exception_handling_<hash>.rs`)

Block 1 imports: tinywasm {Store, Module, ModuleInstance, Imports, WasmValue}, wat.
Block 2 helpers: `run(wat_src, func, args) -> Result<Vec<WasmValue>>`; `expect_uncaught(...)`; `i32s(...)`.
Block 3 assertion helpers: substring-match trap message ("uncaught").
Block 4 tests grouped:
- basic throw/catch: throw caught in same function pushes tag values + branches (`throw_caught_pushes_values`, `catch_wrong_tag_falls_through`, `catch_all_catches_any`).
- value discipline: `body_operands_discarded_on_throw`, `values_before_try_preserved`.
- cross-frame: `throw_propagates_to_caller_handler`, `throw_unwinds_two_frames`, `uncaught_throw_traps`.
- exnref: `catch_ref_then_throw_ref_rethrows`, `throw_ref_preserves_tag_matched_by_outer_catch`, `throw_ref_null_traps`, `ref_is_null_on_caught_exnref`.
- handler cleanup (S3): `br_out_of_try_removes_handler`, `reentered_try_reinstalls_handler`, `nested_try_inner_first`.
- tag identity: `imported_tag_matches_exporting_module`, `distinct_tags_same_sig_do_not_match`.
- interaction (S4): `throw_from_inside_loop_caught_outside`, `throw_across_call_indirect`, `catch_with_block_result_type`.
- edge: `try_table_no_throw_falls_through`, `multiple_catch_first_match_wins`, `throw_with_multi_value_params_i32_i64`.

5-axis coverage: every described behavior; the WASM surface (tag/throw/try_table/throw_ref/exnref); every executor branch (each catch form, matched/unmatched, cross-frame, uncaught, null); edge (empty params, multi-value, nested, loop, indirect call, distinct-tag).

## 10. Forced trait bounds / value-model constraints (test-first)

- The value stack is split by width (s32/s64/s128). `exnref` is a reference; references are 32-bit-ish handles -> exnref rides the s32 stack lane as an index, or a dedicated ref lane if that is how RefFunc/RefExtern are stored (verify in reference.rs during impl). Whichever lane, `truncate_to(snapshot)` must restore the SAME lanes the body may have grown.
- `Instruction` must remain `Copy` and 16 bytes -> side-table indices (u32) for catch lists and tag params.
- wasmparser feature bitset must add `EXCEPTIONS` (parser/src/lib.rs) or validation rejects EH opcodes before lowering.

## 11. Predicted trap matrix (interdependent + misdirecting)

| # | Trap | Why agents hit it | Pre-empt sentence (in meta) | Catching test |
|---|------|-------------------|-----------------------------|---------------|
| 1 | S3 handler cleanup on branch-out: a `br` that leaves a try_table must pop its handler | agents install handlers on entry, remove only on normal `end`; a `br` out leaves a stale handler that wrongly catches a later throw | "a branch out of a try_table removes its handlers" | `br_out_of_try_removes_handler` (a later throw must NOT hit the dead handler) — fails with a wrong catch, not an obvious cleanup error |
| 2 | S4 cross-frame unwind + split-width restore: throw must discard caller frames AND restore all three value-stack widths | naive impl restores one width or only same-frame; misdirects as wrong result values | "throw unwinds across called functions ... discarding intervening frames and operands" | `throw_unwinds_two_frames`, `body_operands_discarded_on_throw` |
| 3 | exnref identity through throw_ref (S2 composition of catch_ref + throw_ref + outer catch) | rethrow that loses the original tag/values fails outer tag match | "throw_ref re-throws the referenced exception, preserving its tag and values" | `throw_ref_preserves_tag_matched_by_outer_catch` |
| 4 | 16-byte ISA layout (codebase-inferable) | inline catch list in the instruction blows `size_of == 16`, breaking a base test | (not stated) | base test `instruction_layout_size_is_stable` regresses if done naively |
| 5 | tag identity vs signature-equality | agents match by param signature; spec matches by definition identity | "two tags match only when they are the same tag definition" | `distinct_tags_same_sig_do_not_match`, `imported_tag_matches_exporting_module` |

Traps 1-3 are interdependent (all funnel through the same unwind/handler machinery; fixing same-frame throw does not fix cross-frame; fixing values does not fix exnref) and misdirecting (failures read as wrong values / wrong catch, never "clean up the handler"). Trap 4 is the one codebase-inferable anchor. Wrong-Logic is expected high (>=25%) — this is a genuine correctness engine, not an ambiguous spec.

## 12. Tier + category

- Tier: Olympus.
- Category: feature-request (net-new capability: new instructions, new value type, tag section).
- Sub-rank target: Olympus Good/Excellent (cross-subsystem, ~544 meaningful LOC, low pass band).

## 13. Predicted pass rate

- Predicted: 5-20% (Nova-heavy mix). Reasoning: the EH spec is public (KNOWING is free) but the difficulty lives in DOING — wiring unwinding through tinywasm's flat-control, split-width-stack, non-recursive executor + handler cleanup on branch-out + exnref identity + the 16-byte ISA constraint. These are uncorrelated (different agents fail on cross-frame unwind vs handler cleanup vs exnref vs the layout test). Solvable by a long-horizon Orion/Vega reading the architecture; fast Nova ships partial (same-frame only) impls that fail cross-frame/cleanup tests.
- Sanity: not 0% (spec + wasmparser decoding + wat oracle make it reachable); not >40% (no single mechanism discharges cross-frame + cleanup + exnref + layout).

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, subsystems, high-entanglement executor/visit/store, test framework = wat+cargo, template = host_import_arg_order.rs)
- [x] Existing PR/gap check: gap file-cited absent; `gh pr list --search exception/gc/reference-typed` clean incl. `next` branch
- [x] Closest approved scaffolding: wazero-fuel-metering (WASM-VM feature shape) + nutsdb test.sh harness pattern (Go, but the synth-fallback + per-test node pattern maps to Rust build-failure fallback)
- [x] Title verb-led, names subsystem
- [x] Shape declared (O-Composite-add / correctness core)
- [x] Public API surface = the exact WASM constructs tests assert
- [x] Canonical output form spelled out (search order, stack restore, unwind scope, identity, cleanup, null)
- [x] <=1 codebase-inferable (the 16-byte layout)
- [x] Description <=200 words, plain prose (see meta.md)
- [x] File footprint against real files; meaningful LOC ~544 >= 450
- [x] 1+ helper per behavior
- [x] Test outline 4-block, scenario names, 5-axis
- [x] value-model constraints documented (split-width restore, exnref lane, 16-byte)
- [x] >=3 interdependent + misdirecting traps + 1 codebase anchor
- [x] Wrong-Logic >=25% understood (correctness engine)
- [x] pass band matches shape
- [x] category = feature-request (honest: net-new)
- [x] not pattern-followable (no sibling EH; the flat-control unwind has no template in-repo)

## Why this is not a duplicate

No WASM exception-handling problem exists in the corpus. Closest siblings: `wazero-fuel-metering` (different repo, different feature — fuel accounting, not control-flow unwinding) and `wasmi` worktree (never turned into a problem). Different repo (tinywasm), different subsystem (EH control-flow), different trap family (cross-frame unwind + handler cleanup + exnref identity vs. metering counters).

Predicted iteration cycles: 3 (large surface; expect executor-unwind + handler-cleanup + exnref refinement rounds).
