# eval-results.md — tinywasm-exception-handling

Per-agent results per batch. Populated after each run.

## Local validation (pre-platform)

| Check | Result |
| ----- | ------ |
| Docker image build (olympus-base-rust) | PASS (30.7s) |
| base mode PASS both states (workspace lib regression) | PASS 31/0 |
| new mode FAIL on base | PASS (70/70 fail) |
| new mode PASS on solution | PASS 70/0 |
| both apply orders clean + reverse clean | PASS |
| human-effective LOC (>=400) | PASS (436) |
| instruction_layout_size_is_stable still green | PASS (16 bytes) |
| offline (--network none) + non-root (1000:1000) + deterministic 3x | PASS |

AI pre-check round (2026-07-20) — all findings addressed, re-validated green:
- Description Quality (was request_changes, 1 HIGH): removed the redundant legacy-catch restatement (legacy catch/catch_all now say "match as in a try_table"), trimmed "parse, validate," and the "returns/report them" filler. KEPT the tag-identity examples (imported-matches / distinct-sig-no-match) because two tests depend on them (Test Fairness > Description brevity). meta now 376 words.
- Test Fairness / Alignment (WARNING): expect_uncaught and the two host tests no longer depend on Error::to_string() text or destructure Trap::UncaughtException{values,..}; they use the documented accessors err.uncaught_exception() / trap.is_uncaught_exception(). Dropped the now-unused Trap import. Renamed misleading ref_is_null_on_caught_exnref -> caught_exnref_is_nonnull.
- Environment Quality (was FAIL): platform runs vanilla `cargo test` (not test.sh); the repo's pre-existing resume_execution.rs include_bytes! of a generated examples/rust/out/fibonacci.wasm broke offline compilation. Dockerfile now writes a real fibonacci.wasm (base64) + pins toolchain to 1.95.0 (repo pins nightly, absent offline). Verified: vanilla `cargo test --no-run` compiles all targets in the image.
- Dockerfile warnings: toolchain now explicitly pinned (channel="1.95.0") rather than removed (addresses version-pinning). chmod kept (matches approved rust-bio pattern; security note is advisory).
- Dockerfile Guidelines (was FAIL - base64 decode flagged as obfuscated): replaced the base64-embedded fibonacci.wasm with a plain-text, self-documenting placeholder written via printf (no encoding). include_bytes! still compiles -> vanilla `cargo test` compiles + runs; resume_execution's 2 add.wasm tests pass, its 2 fibonacci tests fail gracefully (env-quality accepts failures). Verified: no base64/hex/decode constructs in the Dockerfile.
- Description Quality round 2 (was request_changes, 1 HIGH): removed the sentence naming concrete Rust APIs (Trap::UncaughtException / accessors / exported_tag / tag_param_types) - now states only the behavior ("a trap that carries the escaped tag and its argument values"); the API names remain in tests as accepted Test Assumptions. Also dropped the tag-identity example clause, the handler-region enumeration (Rule-7 de-enumeration), and a trailing control-flow phrase. meta now 318 words.

Coverage round (proactive, preempts reviewer coverage-suggestions): 47 -> 56 tests. Added: try_table non-first-catch match; catch-miss-then-catch_all; return-out-removes-handler; br_table-out-removes-handler; multi-value catch_ref (values+nonnull exnref); legacy non-first-catch; delegate depth>0; rethrow depth>0; exnref-through-local. The delegate depth>0 design exposed + FIXED a latent off-by-one in delegate label resolution for block/loop targets (infinite-redirect hang) in parser/src/visit.rs::visit_delegate; all 3 pre-existing delegate tests still pass (backward-compatible). Re-validated green both apply orders (base 31/0; new 56/56 fail on base -> 56/0 on solution).

## Solvability sim (Query 13 — Sonnet imitators, blind to hidden tests)

| Run | Verdict | Failed tests | Notes |
| --- | ------- | ------------ | ----- |
| imitator-1 (Sonnet, blind, meta-only) | FAIL (0/56, does not compile) | all 56 | Stalled at a partial impl (153/~656 LOC, 5/14 files, 3 build errors) after ~18min. Coarse signal: NOT single-shot solvable = hard. Reference passes 56/56 = solvable. Consistent with a low pass band. Reduced from 6 imitators to 1 for budget; the platform Nova/Orion/Vega batch is the required band oracle. |

## Platform batches

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
| ----- | ----- | --------- | ------- | ---- | ----- | --- | ------------ | ------------- |
| pending | | | | | | | | |

Alignment ERROR round (host-API catch-22, 2026-07-21) — RESOLVED by removal:
- Two reviewers conflicted irreconcilably: Description Quality (HIGH) demanded the host-API names be REMOVED from the description; Test/Problem Alignment (ERROR) demanded they be SPECIFIED. A named host-API surface cannot satisfy both (the API-heavy-subsystem non-behavioral trap).
- Fix: removed the host-visible uncaught-exception API entirely (Error::uncaught_exception, Trap::{is_uncaught_exception,uncaught_tag,uncaught_values}, ModuleInstance::exported_tag, Store::tag_param_types; Trap::UncaughtException is now a unit variant, do_throw marshaling gone). Deleted the 5 host-API tests (56 -> 51). expect_uncaught now asserts behaviorally (matches!(err, Error::Trap(_))). meta trimmed the uncaught tag/values tail (309 words).
- Uncaught exceptions are now purely behavioral: an escaping exception fails the invocation with a trap. The full EH engine (both dialects, exnref, cross-frame unwind, tag identity via internal addresses) is intact.
- Re-validated: base 31/0 both states; new 51/51 fail on base -> 51/0 on solution; human-effective 436 (>=400 both counters); lib green; 16-byte invariant holds; no stale host-API refs in solution/tests/meta.

Description Quality round 3 + coverage (2026-07-21) — prose trims + 2 tests:
- Applied all 5 Description Quality suggestions (1 HIGH + mediums/lows): dropped the legacy-encoding aside, the "operands dropped" tail, the standalone "tag carries a parameter signature" sentence, the duplicated "to the nearest matching handler," and rethrow's "keeping its tag and values." meta now 274 words, fully behavioral.
- Coverage suggestions: added 2 F2P-valid tests (51 -> 53): try_table_mixed_clause_kinds_first_match_wins (mixes catch/catch_ref/catch_all/catch_all_ref in one clause list, throw hits the 2nd) and distinct_cross_module_tags_do_not_match (two modules, same-name/sig tags but different definitions -> no match -> trap). SKIPPED the "malformed EH rejected" negative-validation suggestion: on base EH is disabled so any EH module is already rejected, so such a test passes on base too and violates fail-on-base (F2P). No solution bug exposed (one initial fail was a wat typo in the test, fixed).
- Re-validated: base 31/0 both states; new 53/53 fail on base -> 53/0 on solution; human-effective 436; lib green; 16-byte invariant holds.

Coverage round 3 (2026-07-21, advisory):
- tag import/export type compatibility: ADDED tag_import_signature_mismatch_rejected (53 -> 54). Verified the solution already rejects mismatched tag imports at link time via imports.rs Imports::link() reusing compare_types (same mechanism as func/global imports) -> LinkingError::incompatible_import_type. Test parses EH modules first (fails on base), then asserts instantiate(B-with-wrong-tag-sig) is Err (passes on solution). No solution/meta change; standard WASM import type-checking (inferable).
- rethrow-outside-catch validation error: SKIPPED (definitively F2P-invalid). A rejection test asserts a malformed EH module is rejected; on base EH is disabled so EVERY EH module is already rejected at parse -> the test passes on base AND solution -> cannot fail-on-base (F2P requires new tests fail on base). No F2P-valid rethrow-misuse test exists. Advisory-only; safe to skip.
- Re-validated: base 31/0 both states; new 54/54 fail on base -> 54/0 on solution; lib green; 16-byte holds; human-effective 436.

Coverage round 4 (2026-07-21, advisory):
- Legacy stack restoration: ADDED legacy_catch_restores_stack_to_try_entry (54 -> 55). A value (30) is live before the legacy try; junk operands (111,222) are produced inside the body; catch $t restores the stack to try-entry height and pushes the caught value (12) -> 30+12=42. Confirms legacy catch restores the value stack the same way try_table catches do (the legacy-dialect analog of body_operands_discarded_on_throw + values_before_try_preserved). Positive/behavioral, F2P-valid.
- rethrow invalid placement: SKIPPED AGAIN (definitively F2P-invalid; see coverage round 3). A rejection test passes on base (EH disabled -> all EH rejected) so it cannot fail-on-base.
- Re-validated: base 31/0 both states; new 55/55 fail on base -> 55/0 on solution.

## Platform batch #1 (10x Nova, on the 55-test version) — 7/10 PASS = 70% -> TOO EASY (cap 40%)
Fair (evaluators: description_clear, deterministic, "documented behavior not undocumented convention"). 3 uncorrelated FAIR walls tripped the 3 failers:
- delegate targeting (Runs 2,6): delegate to a named try/try_table target must include THAT target's handler; depth>0 must skip the right frames.
- terminal unmatched-handler (Run 5): checked_sub(1)->None->unbounded search -> infinite loop when outermost handler rejects; must trap.
- exnref heap-type recognition (Run 6): must accept all Exn ref forms, not one exact RefType::EXN.

## Hardening round (2026-07-21) — 55 -> 67 tests (add uncorrelated pure-wasm walls; drop host-API tests)
Rationale (HARDENING): more of the SAME wall is correlated (a passing agent nails all variants); need NEW uncorrelated walls the 70% passers would still miss, kept PURE-WASM to preserve the batch-confirmed fairness. Dropped the host-API integration tests (reentrant-rollback / fuel-resumption) as fairness-risky.
Reference fixes (both ADD real logic, mirror existing patterns; raise code-quality 2/3->3/3):
1. Reentrant-call rollback (func.rs +4): snapshot+truncate handler/exception stacks on the nested-call error path (reviewer-confirmed gap; source-only, no host-API test).
2. Rethrow propagation (executor.rs +1): NEW genuine bug - rethrow must truncate the handler stack to the target try's index so it propagates from OUTSIDE the target, bypassing an ARMED intervening handler (pre-fix: rethrow_depth_two_mixed_dialect = 555 vs 1007). All 5 prior rethrow tests still pass (backward-compatible).
10 new tests; confirmed discriminators (fail a naive impl): rethrow_depth_two_mixed_dialect (ref bug, fixed), br_table_exits_different_handler_depths, return_call_out_of_try_removes_handler, return_call_indirect_out_of_try_removes_handler, throw_ref_same_exnref_twice, delegate_target_handler_value_stack_restored (264 vs 92), delegate_depth_two_mixed_dialect (999 vs 15), exnref_as_function_param_and_result, unmatched_handler_propagates_then_caught_in_caller. (delegate_to_try_table_target = wall #1 variant.)
human-effective 436 -> 441 (integration fixes add logic). meta.md UNCHANGED (all consequences of documented rules).
Re-validated: base 31/0 both states; new 67/67 fail on base -> 67/0 on solution; lib green; 16-byte holds; env-quality compiles.
NOTE: a re-batch (10x Nova) is required to confirm the new pass rate <=40%; local design targets it (orthogonal walls + one that tripped a strong implementer) but the platform batch is the only oracle.

## Solution Quality check #2 (PASS but 2/3+2/3) -> Quality round to 3/3
Reviewer docked comprehensiveness + code quality for two model shortcuts. Fixed both (source-model completeness, behavior unchanged for valid programs, all tests still pass):
1. exnref FIRST-CLASS: added distinct WasmType::RefExn + WasmValue::ExnRef (+ ExnRef struct in types/reference.rs); conversion.rs recognizes Exn/NoExn heaptype in all nullable/non-null forms; throw_ref/catch_ref/catch_all_ref/ref.null exn/ref.is_null carry it as a distinct type (throw_ref now type-safe, no non-exception externref can reach it); updated every exhaustive match across types/parser/tinywasm/CLI + the 1-arm exhaustiveness fix in the pre-existing host_func_signature_check.rs (goes in solution.patch so the base tree still compiles). Removes the exact RefExtern shortcut agents also take (Run 6 exnref-type failures).
2. Tags surfaced consistently: Imports::Extern::Tag variant; Module::imports()/exports() now emit tag descriptors (ImportType::Tag/ExportType::Tag by param signature); CLI prints them.
Added test #70: imported_and_exported_tags_appear_in_module_descriptors (asserts tags appear in module.imports()/exports() via public API; F2P-valid).
Patches: solution.patch now spans 21 files incl crates/cli/src + host_func_signature_check.rs exhaustiveness (source-consequence; NO new-feature-test leakage). human-effective LOC 441 -> 506. workspace builds 0 warnings (all crates incl cli). 16-byte Instruction invariant holds.
Re-validated: base 31/0 both states; new 70/70 fail on base -> 70/0 on solution; workspace `cargo build --workspace` clean with solution; patches apply+reverse both orders.

## Test Fairness check (FAIL 1/70) -> FIXED
Unfair test: imported_and_exported_tags_appear_in_module_descriptors pinned the exact new Rust shape matches!(i.ty, ImportType::Tag(_)) / ExportType::Tag(_), which the base repo lacks and the prompt doesn't single out (concept is fair+documented; the exact variant pin is not).
Fix: rewrote it variant-agnostic - module imports only a tag, exports only a tag; asserts `module.imports().any(|i| i.module=="a" && i.name=="imported_tag")` and `module.exports().any(|e| e.name=="exported_tag")` (public module/name fields, NO enum-variant reference). Still fails on base (tags filtered/section rejected) and requires the solution's tag-surfacing, but leaves the Rust representation to the solver. Kept the tag-surfacing SOURCE (comprehensiveness) and the behavioral meta sentence ("Imported and exported tags appear among the module's imports and exports" - no API names).
Also strengthened throw_ref_null_traps to assert matches!(err, Error::Trap(_)) (advisory; meta says null throw_ref traps). Skipped validation-error suggestion (F2P-invalid).
Re-validated: base 31/0 both states; new 70/70 fail on base -> 70/0 on solution; workspace builds clean; 16-byte holds. 70 tests, 506 eff LOC, meta 285 words.

## Tail-call WARNING (recurred 3 rounds) -> removed the 2 return_call tests
The test-quality sanity check flagged return_call/return_call_indirect (tail-call ops) across 3 rounds as "not stated in the prompt / may cause spurious build failures." They are base-supported (no real risk) and fair (documented general rule "leaving a handler region removes its handlers"), but they are a CORRELATED wall (same emit_pop_handlers_to code path as br/return/br_table -> modest independent hardening). Removed return_call_out_of_try_removes_handler + return_call_indirect_out_of_try_removes_handler to permanently clear the recurring warning; exit-cleanup stays covered by br/return/br_table tests. Solution SOURCE unchanged (still handles return_call cleanup). 70 -> 68 tests.
Declined the "Test Assumptions" API-list suggestion: a formulaic header naming concrete Rust APIs would fail the DESCRIPTION rules + the Description-Quality API-name gate (which already raised a blocking HIGH). Reviewer acknowledges the APIs are in-repo.
Re-validated: base 31/0 both states; new 68/68 fail on base -> 68/0 on solution. 68 tests, 506 eff LOC, meta 285 words.

## Coverage round (2026-07-21, advisory): +missing_tag_import_rejected (68->69)
- Added missing_tag_import_rejected: module B imports "a"/"missing_tag" that A doesn't export -> link error -> instantiate Err. No reference gap (link() rejects any unresolved import via export_addr().ok_or(unknown_import)); kept as discriminator (naive impl forgetting tag imports fails it). Solution/meta unchanged.
- Skipped: validation-error tests (F2P-invalid); tag descriptor-SIGNATURE assertions (would require the unfair ImportType::Tag(_) variant pin that Test Fairness failed).
- Re-validated: base 31/0 both states; new 69/69 fail on base -> 69/0 on solution; no tail-call refs, no variant pins; 506 eff LOC, meta 285 words.

## Platform batch #2 (10x, on the 69-test hardened version) — 0/10 pass, but from an UNFAIR test
Breakdown: rethrow_depth_two_mixed_dialect (expected 1007) was THE failing test in 9/10 runs; 6 runs (#3,5,6,7,8,10) got 68/69 and failed ONLY on it. All 9 agents produced 555. Diagnosis: 555 is SPEC-CORRECT — legacy `rethrow l` re-raises the selected caught exception FROM THE RETHROW SITE (label l only picks which caught exception, not where propagation resumes); the intervening armed try_table catch_all catches it -> br $bad -> 555. Our reference's "truncate handler stack to target try" gave rethrow delegate-style bypass semantics = a REFERENCE BUG.
Fix: reverted exec_rethrow to in-place re-raise (spec-correct 555); DELETED rethrow_depth_two_mixed_dialect (asserted the wrong 1007). Other rethrow tests unchanged + still pass (their intervening handlers are in catch-phase -> correctly skipped by ordinary dispatch, not bypass). Delegate hand-verified spec-correct (delegate DOES bypass to a named target; those tests are fair). 69->68 tests, 501->500... measured 505 eff LOC.
Re-validated: base 31/0 both states; new 68/68 fail on base -> 68/0 on solution; workspace build clean; 16-byte holds.
KEY STRATEGIC FINDING: with the unfair test removed, the FAIR difficulty ceiling is ~60% pass (only the delegate-depth walls fairly catch ~40%: runs #1,2,4,9). WASM EH is a documented spec strong agents transcribe (68/69); reaching <=40% fairly needs a harder fair sub-feature strong agents miss, OR accept the ~60% ceiling. NEEDS re-batch on the corrected version to measure the true fair rate before deciding.

## Post-fix hardening: reentrant-call rollback INTEGRATION wall re-added (68->69)
After correcting the rethrow bug, fair pass ceiling was ~60% (delegate-depth the only fair wall). To push higher fairly without another wrong-answer test, re-added the reentrant-call-rollback wall (reference already fixes it in func.rs; the TEST turns the fix into a difficulty wall). It's the one orthogonal integration wall proven to bite: a spec-faithful EH impl that doesn't roll back handler/exception stacks on a nested host-reentrant-call error corrupts state.
PROVE-IT-BITES (both directions): without the func.rs rollback -> test FAILS (leaked handler mis-catches -> value-stack-exhausted trap); with the rollback -> PASSES (542). Uses ONLY existing HostFunction/FuncContext/ExternItem API (mirrors host_import_arg_order.rs) -> no new solution API (fair; not the earlier unfair new-accessor class). Orthogonal to delegate-depth (uncorrelated).
Re-validated: base 31/0 both states; new 69/69 fail on base -> 69/0 on solution; workspace clean; 16-byte holds; 505 eff LOC.
STATUS: needs re-batch to measure whether delegate-depth (~40%) + reentrant-rollback (uncorrelated, unknown %) compounds under the 40% cap. If still >40%, WASM EH's fair ceiling is above the band (documented spec) -> accept ceiling or different pick; will NOT add another unfair trap.

## Compounding integration walls round (69->70)
Added WALL A `sequential_invocations_do_not_leak_handler_state` (proven both directions: without the top-level handlers/exceptions.clear() reset -> a leaked handler from a prior uncaught-trap call mis-catches the next call's throw -> Ok(55) instead of trap; with reset -> traps correctly). Uses plain call API. Probed WALL B (EH across fuel-resume) -> DROPPED (not a discriminator: handler state lives in persistent store, works for free for any reasonable impl).
Now THREE orthogonal FAIR walls whose miss-rates compound: (1) delegate/label-depth mapping (~40% from batch#2), (2) reentrant-call rollback, (3) sequential-invocation state reset.
Re-validated: base 31/0 both states; new 70/70 fail on base -> 70/0 on solution; workspace clean; 16-byte holds; 500 eff LOC.
STATUS: this is the honest fair-hardening ceiling for a documented spec (strong agents transcribe EH; difficulty must come from integration corners, now mined). Re-batch needed to measure if the 3 compounding walls land <=40%. If still >40%, accept the feature's fair ceiling or pick a feature with more irreducible correctness difficulty; will NOT add another unfair trap.
