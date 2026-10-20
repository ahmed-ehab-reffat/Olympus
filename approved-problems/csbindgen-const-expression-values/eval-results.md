# eval-results.md - csbindgen-const-expression-values

## Batch 9 (2026-10-15, ACCEPTED; meta cfd8ad15, test.patch 30b55b8a, solution.patch 0f5504c3): Orion 1/4 (re-eval of batch 8) + Nova 0/8 (fresh)

| Run | Verdict | Failed new tests | +LOC / files | Seq length | Note |
|---|---|---|---|---|---|
| Orion #3 (rd78w7) | PASS_LEGITIMATE (FP genuine, high) | - | 1413 / 6 | 80k | the passer |
| Orion #4 (rd7783) | FAIL | paths_go_through_use_imports | 1480 / 5 | 86k | F-95 only (17/18) |
| Orion #2 (rd709s) | FAIL | paths_go_through_use_imports | 1262 / 7 | 74k | F-95 only (17/18) |
| Orion #1 (rd74w4) | FAIL | unsuffixed_literals, chars | 1530 / 6 | 86k | `3f64`, U+2028 |
| Nova #1, #6, #7 | FAIL (abort) | 18/18 (stack overflow) | 1750-2141 / 4-5 | 505k-509k | F-92 forward variant ref |
| Nova #4, #3, #2, #1(b), #3(b) | FAIL | 5-7 of 18 | 1871-2436 / 3-5 | 499k-513k | F-94 floats 5/5, F-93 5/5, F-92 4/5, unsuffixed 5/5, chars 4/5, scope 3/5 |

Nova sequence length avg **506k** (every run compacted once). Killed nothing: 11 of 18.

## Batch 8 (2026-10-14, meta cfd8ad15, test.patch fc6a5678, solution.patch 0f5504c3): Orion 3/4 raw, 2 FP-voided (scope collision); no Nova runs

| Run | Verdict | Failed tests | Approach / note |
|---|---|---|---|
| Orion_1 (#4, rd7djxy) | PASS -> FALSE POSITIVE (medium) | - | resolver walks ancestor-module consts/imports before the current module's globs: `mod m { use super::Color::*; RED }` picks the parent's const RED |
| Orion_2 (#3, rd75kw) | PASS (genuine, high; judge dissent on c_int, out of contract) | - | general evaluator, Rust module scoping right |
| Orion_3 (#2, rd7e3b5) | PASS -> FALSE POSITIVE (medium) | - | same ancestor-first lookup (glob variant and child const both shadowed) |
| Orion_4 (#1, rd7cmz) | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position, chars_are_escaped_and_astral_chars_are_usable | `3f64` panics (unreachable), U+2028 emitted raw |

- 128-bit: 4/4 right on the new meta (batch 7: 2/8). The both-sides cap fixed it.
- FP fix (test-only, re-eval eligible): fx::imports gains `inner::Paint { RED = 1, GREEN }`, a root `const RED`, and `mod paint { use super::inner::Paint::*; PICKED = RED as u32 + 10 }` asserted in scope::paths_go_through_use_imports. Replay: batch 8 -> 1/4 (only Orion_2), batch 7 kills 2/8 (both already failing).
- Auto Review T3/T4 (BIG_USIZE emission): every agent in batch 8 emits `const nuint BIG_USIZE = 1099511627776;`, so a large-native test would make it 0/4. Large native values are capped by meta ("fits the C# type"). Added in-contract coverage instead: SMALL_USIZE (nuint) and SMALL_ISIZE (nint) selected and asserted; dropped the `BIG_USIZE == None` assertion. All 4 pass those.
- test.patch 30b55b8a, still 20 tests (18 F2P + 2 P2P). Reference 20/20; clean room x3 uids: base 5/5 pre/post, new 18/18 fail pre, 18/18 pass post.

## Batch 7 (2026-10-14, meta 1236fa65, test.patch fc6a5678, solution.patch d9ffe3e3): Orion 0/8 (two batches of 4), no Nova runs

| Run | Verdict | Failed tests | Approach / note |
|---|---|---|---|
| Orion_1 (#4) | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position | 128-bit OK; `3f64` (syn LitInt with f64 suffix) dropped |
| Orion_2 (#3) | FAIL_MISSED_REQUIREMENT | values_above_i64_max_are_emitted, values_of_128_bit_types_are_usable | integer types only to 64 bits ("unsupported integral bound" on u128::MAX) |
| Orion_3 (#2) | FAIL_MISSED_REQUIREMENT | both 128-bit tests + unsuffixed | no i128/u128 + `3f64` |
| Orion_4 (#1) | FAIL_MISSED_REQUIREMENT | both 128-bit tests | no i128/u128; unknown suffix falls back to i32 (FROM_HUGE = 0) |
| Orion_5 (#4) | FAIL_MISSED_REQUIREMENT | both 128-bit tests | no i128/u128 |
| Orion_6 (#3) | FAIL_MISSED_REQUIREMENT | both 128-bit tests + unsuffixed | no i128/u128 + `3f64` |
| Orion_7 (#2) | FAIL_MISSED_REQUIREMENT | both 128-bit tests + unsuffixed | README it added: "`i128`, `u128`, and C primitive expressions are not supported" |
| Orion_8 (#1) | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position | 128-bit OK; `3f64` dropped |

- 128-bit 6/8: induced by the cap "Declared types are ... other than `i128`, `u128`" (added for batch 6's Auto Review). It names only the excluded side, so 6/8 dropped 128-bit from expressions too. Third instance of carve-outs-must-name-both-sides. Graders called it a fair coding miss, but 6/8 failing for the same description-shaped reason is an Auto Review unfairness signal.
- `3f64` 5/8 (runs 1, 3, 6, 7, 8): fair, stated ("suffixed literals").
- Imports lever: 8/8 pass `scope::paths_go_through_use_imports` once the meta names imports.
- Probe sweep (probe6/cells5.txt, 84 cells: casts, float/int conversions, bool/char, shifts, inference through parens/unary, enums, aliases, imports): zero divergence from the reference outside the 128-bit cells (and SELF_IMPORT, which is out of contract: colliding alias names). Derivable surface exhausted.
- Re-export probe (cells6.txt, 6 forms): 7/8 agents pass all; the REFERENCE failed 4 (variant re-exported via `pub use E::*` / `pub use E::A` / renamed). Fixed in the reference (UseScopes::find_variant); also SQ's medium.
- Counterfactuals: drop 128 cells -> 3/8 (too easy); drop `3f64` -> 2/8, but keeps the misleading cap and leaves a stated-requirement hole for the FP panel. Chosen: meta names both sides (cfd8ad15), full batch.

## Batch 6 (2026-10-13, meta 54fc49a2, test.patch 4fddb682, solution.patch ff8ba835): Orion 3/4 raw, 2 passes FP-voided (alias collision); Auto Review: too easy (3/4) + no Nova runs

| Run | Verdict | Failed tests | Approach / note |
|---|---|---|---|
| Orion_1 | PASS -> FALSE POSITIVE (medium) | - | typed evaluator; declared types via flat AliasMap: `narrow::Word = u8` next to `wide::Word = u16` gives BYTE_MAX 65535 |
| Orion_2 | PASS -> FALSE POSITIVE (medium) | - | same flat-AliasMap collision (u8 `!0` emitted as u64::MAX) |
| Orion_3 | PASS (genuine, judge dissent) | - | same collision, excused: base already types narrow::Word as ushort, so "same C# type" and "Rust value" conflict there |
| Orion_4 | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position | `3f64` digit-only float suffix (syn LitInt) |

Probe sweep vs rustc (worktrees/_csb-tools/probe6): 69 value cells (casts, f32 per-op rounding, u64->f32 double rounding, bool/char comparisons, saturation, isize/usize, precedence) + 39 inference/path/alias/enum cells: every batch-5/6 passer matched rustc on all of them. The only cells that split runs were `use` imports: renamed const (`use inner::A as B`), renamed enum, single variant import (`use e::E::Y`), glob over variants (`use e::E::*`) - 8/8 batch 5+6 runs fail at least 3 of the 4 (they resolve paths by last segment). Reference passes all, plus 14 wider import forms after the 2026-10-13 resolver fix.
Replay of the 2026-10-13 test.patch fc6a5678: batch 6 0/4, batch 5 0/4 (all fail scope::paths_go_through_use_imports).

## Batch 5 (2026-10-11, meta 618f45f5, test.patch a23a3901, solution.patch f3094cf6): Orion 2/4 raw, 1 pass FP-voided -> needs a fix; no Nova runs in this batch

| Run | Verdict | Failed tests | Files / +LOC | Prompt tokens | Approach / note |
|---|---|---|---|---|---|
| Orion_1 | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position | 6 / 1203 | 1.16M | typed evaluator; panics (unreachable!) on `3f64`, which syn parses as an int literal with a float suffix |
| Orion_2 | PASS (FP panel: genuine, judge dissent) | - | 6 / 1138 | 1.05M | typed evaluator; misses renamed `use X as Y` imports of consts/variants (adjudicator: out of contract); also gives the whole cast operand the cast type (not probed by its panel) |
| Orion_3 | FAIL_MISSED_REQUIREMENT | unsuffixed_literals_take_the_type_of_their_position | 6 / 1097 | 1.08M | same `3f64` panic as Orion_1 |
| Orion_4 | PASS -> **FALSE POSITIVE** (high confidence) | - | 6 / 1054 | 1.13M | passes the cast target down as the expected type of the whole operand: `(!0 >> 4) as u8` = 15 (rustc 255); its own unit test asserts `(!0 >> 1) as u8 == 127` |

Replay of the panel's probes (`(!0 >> 4) as u8`, `(1 << 31 >> 31) as u32`, `(-8 / 3) as u8`, `(16777216.0 + 1.0 + 1.0) as f32`) as test cells: each one alone kills BOTH passers with identical wrong values (15, 1, 82, 16777216). No cell separates Orion_2 from Orion_4 (a same-name alias in two modules probe also fails both). Tests-only fix = Orion 0/4 on re-eval, so the fix is a meta sentence plus the cells and a full batch. Batch 4's 22 patches: still 0/22 on the new suite.

## Batch 4 (2026-10-11, cand3h test.patch 43066d6f): Nova 0/8 (re-eval), Orion 0/14 (4 re-eval + 10 fresh) -> UNSOLVABLE on Orion; Task Prompt Quality FAIL "Too many requirements"

Cells (fixture const behind the failing test): CAST_TYPED `3_000_000_000 as u64` (casts, wrapped to
18446744072414584320), LETTER `66 as char` (casts, const missing), SUFFIXED_FLOAT `3f64 / 2.0`
(unsuffixed_literals, const missing), CWide repr(C) 3e9 -> uint (enums_without, emitted long).
LETTER panics before CAST_TYPED, so "?" = CAST_TYPED not reached.

| Run (export dir) | Fresh/re-eval | CAST_TYPED | LETTER | SUFFIXED_FLOAT | CWide |
|---|---|---|---|---|---|
| Orion #3 (Orion_Nova_1) | fresh | X | ok | X | X |
| Orion #2 (Orion_Nova_2) | fresh | X | ok | ok | ok |
| Orion #1 (Orion_Nova_3) | fresh | X | ok | X | ok |
| Orion #3 (Orion_Nova_4) | fresh | ? | X | X | ok |
| Orion #2 (Orion_Nova_5) | fresh | X | ok | ok | X |
| Orion #1 (Orion_Nova_6) | fresh | ok | ok | X | ok |
| Orion #1 (Orion_Nova_7) | fresh | X | ok | ok | ok |
| Orion #1 (Orion_Nova_8) | fresh | ok | ok | X | ok |
| Orion #1 (Orion_Orion_1) | fresh | X | ok | ok | X |
| Orion #1 (Orion_Orion_2) | fresh | ? | X | ok | ok |
| Orion #5 (Orion_Nova_9) | re-eval of b3 | X | ok | ok | ok |
| Orion #4 (Orion_Nova_10) | re-eval of b3 | ? | X | ok | X |
| Orion #3 (Orion_Nova_11) | re-eval of b3 | X | ok | ok | ok |
| Orion #2 (Orion_Nova_12) | re-eval of b3 | ? | X | X | ok |

Re-eval matched the local replay exactly (0/4). Fresh-10 miss rates: CAST_TYPED >= 6/8 known, SUFFIXED_FLOAT
5/10, CWide 3/10, LETTER 2/10. Single-cell-only failures: CAST_TYPED 4 runs, SUFFIXED_FLOAT 2 runs.
Nova re-eval: all 8 fail 6-9 tests; strings (U+2028) 8/8 and unsuffixed_literals 8/8. Nova max-step
tokens 258k-309k (avg ~269k, just over 256k; most runs sit at the ~260k window, i.e. they compact).
Tests that killed nobody in batch 4: references_cross_input_files_in_either_order,
reference_keeps_its_declared_type, values_above_i64_max_are_emitted, discriminants_use_consts_the_filter_rejects,
discriminants_chain_through_files_aliases_and_hidden_enums, bindgen_inputs_are_evaluated_too,
variants_of_an_enum_that_is_not_emitted_are_resolved.
Task Prompt Quality: requirementCount blocking FAIL at ~20 rules / 387 words (fractionAi 0). Description
change is now forced -> full batch, no re-eval.

## Local validation (cut5, 2026-10-11): test.patch b9064c22, solution.patch 43f7607e

| Check | Result |
|---|---|
| Effective LOC (hook) | 578 human-effective, 5 files |
| Tests | 18 F2P + 2 P2P (`unchanged::`), plus 3 repo lib tests in base mode |
| Clean room uid 1000 / 0 / 4242, `--network none` | base 5/5 pre and post; new 18/18 fail pre, 18/18 pass post; signatures identical across uids |
| Cold image build | 152 s |
| Replay of 22 batch-4 patches (old-meta solutions) | 0/22, same kills as the platform |

## Batch 3 (2026-10-10, NEW-MODEL GATE): Orion 4/4 PASS (too easy; gate wants exactly 1/4)

| Run (export dir) | Verdict | Approach | Kills under cand3 tests (local soft replay) |
|---|---|---|---|
| Orion #5 (Orion_Nova_1) | PASS_LEGITIMATE | ConstEvaluator in const_eval.rs, memo + visiting set | none (passes) |
| Orion #4 (Orion_Nova_2) | PASS_LEGITIMATE | same shape; widens repr(C) to long unless the values fit int | CWide backing (uint), `66 as char` |
| Orion #3 (Orion_Nova_3) | PASS_LEGITIMATE | same shape; escapes all non-ASCII as \uXXXX | none (passes) |
| Orion #2 (Orion_Nova_4) | PASS_LEGITIMATE | same shape | `66 as char`, `3f64 / 2.0` skipped |

Differential probe (worktrees/_csb-tools/probe3, ~250 consts/enums vs reference): Orion #5 and #3 match the
reference everywhere except literals typed by an `as` target (`3_000_000_000 as u64` = 3000000000,
`1.0000000596046448 as f32` = 1.0000001), which ALL four Orion get wrong (i32 wrap / f64 parse). No fair
cell separates #5 from #3. cand3 cells: LINE_SEPARATORS + LINE_SEPARATOR (T4; 0 Orion, 8/8 Nova),
CWide (repr(C) 3e9 -> uint) + CFar (repr(C) -1, 2^33 -> long) (coverage suggestion), LETTER `66 as char`,
SUFFIXED_FLOAT `3f64 / 2.0`. Predicted re-eval: Orion 2/4, Nova 0/8. Optional cand3h adds
CAST_TYPED `3_000_000_000 as u64` -> Orion 0/4. APPLIED (user chose B): test.patch is cand3h.

## Batch 2 (2026-10-10, NEW-MODEL GATE): Nova 0/8, Orion/Vega not run yet

| Run | Verdict | Failing tests (first assertion) |
|---|---|---|
| Nova #8 | WRONG_LOGIC | casts (SATURATED 300.7 as u8 -> 127), float (1e20 as 21-digit integer) |
| Nova #7 | MISSED | float (1e20), nan (NEG_ZERO64 +0), strings (raw U+0085) |
| Nova #6 | WRONG_LOGIC | native (WIDE_UNSIGNED "@ulong"), float (1e20) |
| Nova #5 | MISSED | sibling enums, unsupported (BLOCKED emitted), casts (SATURATED 44), nan (-0), float (1e20) |
| Nova #4 | MISSED | nan (-0), float (1e20), strings (U+0085) |
| Nova #3 | WRONG_LOGIC | nan (-0), float (1e20) |
| Nova #2 | MISSED | unsupported (BLOCKED), float (1e20), strings (U+0085) |
| Nova #1 | UNDOCUMENTED + env blocker "verifier" | strings (raw U+0085) ONLY, 20/21, seq 502K |

Kills: 1e20 7/8 (designed), NEG_ZERO64 5/8, U+0085 4/8, SATURATED 2, BLOCKED 2. Sequence length only known for
Nova #1 (502K); exported eval-result.json carries none, read the rest on the platform (avg must be > 256k).

## Batch 1 (2026-10-08): 0/11 (10 Nova + 1 Orion), all evaluators: description_clear = true

| Run | Verdict | Base | New | First-failure themes |
|---|---|---|---|---|
| Nova #10 (dir Nova_Nova_1) | FAIL_REGRESSION | fail (bytes dropped) | 10/21 | chain sign-ext, c_*, alias MIN, byte strings |
| Nova #1 (Nova_Nova_10) | FAIL_MISSED | pass | 10/21 | chain, sibling enums, c_*, short-circuit, i32 default |
| Nova #9 (Nova_Nova_2) | FAIL_MISSED | fail (1.5ff) | 11/21 | doubled f suffix everywhere (F-45), chain, alias MIN |
| Nova #8 (Nova_Nova_3) | FAIL_MISSED | pass | 11/21 | chain, alias MIN, CLong, i32 default |
| Nova #7 (Nova_Nova_4) | FAIL_MISSED | fail (bytes) | 15/21 | byte strings, isize/usize repr enums |
| Nova #6 (Nova_Nova_5) | FAIL_MISSED | pass | 10/21 | chain, 1e20, CLong, short-circuit |
| Nova #5 (Nova_Nova_6) | FAIL_MISSED | pass | 18/21 | wide usize left nuint, c_* floats, isize/usize repr |
| Nova #4 (Nova_Nova_7) | FAIL_REGRESSION | fail (bytes) | 12/21 | chain, 1e20, LETTER, short-circuit |
| Nova #3 (Nova_Nova_8) | FAIL_MISSED | pass | 13/21 | unsigned MIN (u8/u32 MIN = all ones), LETTER, CLong |
| Nova #2 (Nova_Nova_9) | FAIL_MISSED | pass | 13/21 | chain (Low = 65535), !0 >> 4 in u64, CLong |
| Orion #1 (Orion_Nova) | FAIL_REGRESSION | fail (bytes) | 13/21 | 1e20, byte strings, c_* floats, short-circuit |

Per-cell kill matrix (soft-assert replay of the saved patches, worktrees/_csb-tools/cells1.txt): designed
traps Port/Y_CODE/Z_WIDE sign extension 7, alias MIN arithmetic (TINY_FLOOR) 6, 1e20 as integer 3,
doubled f suffix 1; gate-added cells: CLong/CULong 7, i32-default cast 6, SAME_BYTES 6, c_* floats 5,
repr(usize) 5, PLAIN_BYTES (P2P) 4, short-circuit 4, LETTER 2, float-suffixed int 10, U+2028 10,
Plain backing pin 10, enum alias path 8.


## Local validation (after Solution Quality round 3, 2026-10-03)

| Check | Result |
|---|---|
| Effective LOC (hook) | 553 human-effective, 5 files |
| Clean room uid 1000 / 0 / 4242 | base 5/5 pre and post; new 18/18 fail pre, 18/18 pass post; signatures identical |
| lz4 base vs reference | byte-identical |

## Local validation (after Solution Quality round 1, 2026-10-03)

| Check | Result |
|---|---|
| Effective LOC (hook) | 710 raw / 518 human-effective, 5 files |
| Tests | 18 F2P + 2 P2P (`unchanged::`), plus 3 repo lib tests in base mode |
| Clean room uid 1000 / 0 / 4242 (4 runs) | base 5/5 pre and post; new 18/18 fail pre, 18/18 pass post; signatures identical |
| Mutation pass | all non-equivalent mutants killed |

## Local validation (FINISH, 2026-10-03)

| Check | Result |
|---|---|
| Effective LOC (hook) | 681 raw / 500 human-effective, 5 files |
| Tests | 16 F2P + 2 P2P (`unchanged::`), plus 3 repo lib tests in base mode |
| Clean room uid 1000 / 0 / 4242, `--network none`, before solution | base rc 0, 5/5 pass; new rc 1, 16/16 fail |
| Same, after `git apply solution.patch` | base rc 0, 5/5 pass; new rc 0, 16/16 pass |
| Flakiness (5 runs, JUnit signature md5) | identical every run |
| New-mode compile failure | 16 failing testcases with the real ids |
| Mutation pass (26 mutants) | all non-equivalent mutants killed |
| lz4 bindings base vs reference | byte-identical |
| Cold image build | 2m36s |
| meta.md | 324 words (body + title) |

## Local validation (SLICE, 2026-09-29)

| Check | Result |
|---|---|
| Effective LOC (hook) | 665 raw / 487 human-effective, 5 files (const_eval.rs new) |
| Tests | 7 F2P + 1 P2P (`unchanged::`), plus 3 repo lib tests in base mode |
| Clean room uid 1000, `--network none`, before solution | base rc 0, 4/4 pass; new rc 1, 7/7 fail |
| Same, after `git apply solution.patch` | base rc 0, 4/4 pass; new rc 0, 7/7 pass |
| Root (0:0) and unmapped (4242:4242), before solution | base 4/4 pass; new 7/7 fail |
| Flakiness (3x pre, 3x post, JUnit signature md5) | identical every run |
| Cold image build | 2m06s |

Base failure reasons (new mode, before solution): 5 tests find the const missing (dropped at base),
`values_above_i64_max_are_emitted` panics at parser.rs:400 (`base10_parse::<i64>().unwrap()`),
`discriminants_use_consts_the_filter_rejects` sees C# renumbering (A,B,C,D = 0..3 vs 1,2,8,9),
`float_values_are_valid_csharp_literals` sees `100000000000000000000` (invalid C# double literal).
