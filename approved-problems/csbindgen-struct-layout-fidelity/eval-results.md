# eval-results.md — csbindgen-struct-layout-fidelity

## Batch 1 (2026-09-19, R9 artifact) — 0/11 (10 Nova + 1 Vega)

Every run failed `scalars::pointers_follow_aliases_to_arrays_and_functions`. Common cause: field
`d: *const OptCb` (OptCb = `Option<extern "C" fn()>`) expected `void*`, but meta only said a pointer
to "a function pointer" is `void*`, not an `Option` of one -> 10/11 wrote `delegate*<void>*`.
UNFAIR cell. Fixed in R10 by making pointers to function pointers keep their typed C# form
(`delegate*<...>*`, valid C#, matches base output for `nest_test`), so `d` is now what agents write.

| Run (folder) | Verdict | New fails | Base fails | Notes |
|---|---|---|---|---|
| Nova #10 (Nova_Nova_1) | FAIL | Prims bool, AliasPtrs, PtrAliases | - | `fixed byte*` alias pointers; `[MarshalAs]` on fixed bool |
| Nova #1 (Nova_Nova_10) | FAIL | Prims bool, AliasPtrs | sized-union guard | bool expanded to f_0..; `void/* byte[] */*` |
| Nova #9 (Nova_Nova_2) | FAIL | Prims bool, AliasPtrs | sized-union guard | only `d` + bool wrong in AliasPtrs |
| Nova #8 (Nova_Nova_3) | FAIL | PtrAliases, AliasPtrs | NonZero guard | pointer-to-array rendered as `fixed byte` |
| Nova #7 (Nova_Nova_4) | FAIL | Wides, AliasPtrs | NonZero + sized-union guards | nested arrays not flattened |
| Nova #6 (Nova_Nova_5) | FAIL | Prims bool, AliasPtrs, 2 union | - | union Size missing |
| Nova #5 (Nova_Nova_6) | FAIL | AliasPtrs | sized-union guard | extra pointer level (`byte**`) |
| Nova #4 (Nova_Nova_7) | FAIL | AliasPtrs | - | `fixed byte* a[4]` |
| Nova #3 (Nova_Nova_8) | FAIL_REGRESSION | union array, AliasPtrs | 3 guards | zero-size guards broken |
| Nova #2 (Nova_Nova_9) | FAIL | AliasPtrs | - | `fixed byte*` |
| Vega #1 (Vega_Nova) | FAIL | AliasPtrs (only `d`) | - | everything else correct -> would pass under R10 rules |

`[MarshalAs(UnmanagedType.U1)] fixed bool` checked on .NET 8: compiles but Marshal.SizeOf throws
("cannot be marshaled as an unmanaged structure"); base never puts it on fixed buffers -> fair.

Local replay of the 10 applicable patches against the R10 tests (Nova_Nova_8 patch does not apply):
all fail the 3 pointer tests because they followed the old `void*` meta (description delta, not
replayable, L35). Non-pointer failures that remain real: bool fixed buffer (4), sized-union guard (4),
NonZero guard (2), union Size (1), nested flatten (1), large-const panic (Nova #10, 1).

## Batch 2 (2026-09-20, R12 artifact) — 0/11 (10 Nova + 1 Vega)

Two tests were unfair and are REMOVED in R13:

| Test | Failed in | Why unfair |
|---|---|---|
| `scalars::aligned_enum_raises_the_layout_of_its_container` | 11/11 (9 by PANIC) | meta never says an enum can carry `align(N)`; base `collect_enum` panics on `#[repr(C, align(8))]`, so the cell demanded an undocumented parser fix |
| `arrays::expanded_array_elements_pull_in_their_struct` | 7/11 ("Kid2 not emitted") | meta says nothing about which declarations get emitted / how reduction prunes them |

Per-run new-test failures (batch 2):

| Run | New fails | Base fails |
|---|---|---|
| Nova #10 | aligned_enum, expanded_array, AliasPtrs | sized-union guard, ExprLen guard |
| Nova #1 | aligned_enum, PtrAliases | NonZero guard |
| Nova #9 | aligned_enum, expanded_array, PtrAliases | sized-union guard |
| Nova #8 | aligned_enum, expanded_array, Prims bool | - |
| Nova #7 | aligned_enum, expanded_array, PtrAliases | - |
| Nova #6 | aligned_enum, expanded_array, 2 union | - |
| Nova #5 | aligned_enum, 2 union | - |
| Nova #4 | aligned_enum, expanded_array, PtrAliases | sized-union guard |
| Nova #3 | aligned_enum, PtrAliases | - |
| Nova #2 | aligned_enum, AliasPtrs | - |
| Vega #1 | aligned_enum, expanded_array | - |

Local re-grade of all 11 batch-2 patches against the R13 suite (drop 2 unfair tests, add tuple /
packed(8) / repr(u32) / NonZeroUsize+I8 cells): **Vega PASSES 68/68 new + 27/27 base**; all 10 Nova
still fail on stated rules (PtrAliases/AliasPtrs alias-pointer lowering 5, union Size 2, bool fixed
buffer 1, guards 4). Projected batch-2 re-eval: 1/11 = 9%. The 4 new coverage cells killed nobody.

## R14 re-grade of the batch-2 patches (local, 2026-09-20)

| Suite variant | Passing runs |
|---|---|
| R13 (batch-2 artifact + 2 unfair cells dropped) | 1/11 (Vega) |
| + R14 fixes (scope-safe consts, niche-option fixed buffers) | 0/11 — the ambiguous-const guard failed 11/11 and the niche-option cell took Vega |
| + drop ambiguous-const guard and the 2 alias-pointer cells | **3/11 (Nova #7, #3, #2)** = 27% |

Why each dropped cell went:
- `unchanged::structs_using_an_ambiguous_module_const_are_emitted_as_today`: 11/11 failed. Every
  agent resolves module consts globally (all 11 pass the unique-name `ScopeThree` cell), so a
  duplicated const name silently picks one value. meta says nothing about const scope or ambiguity
  -> unfair, dropped (the solution keeps the ambiguity guard, which Solution Quality asked for).
- `scalars::aliases_to_raw_pointers_are_lowered` + `scalars::pointers_follow_aliases_to_arrays_and_
  functions`: FAIR (meta states both alias-following and pointer lowering) but the single most-missed
  axis, 7/11 between them. Dropped as the over-strict axis per the 0%-batch relaxation rule; meta
  and the solution keep the behavior, and direct raw-pointer lowering is still covered by PtrKinds.

Remaining discriminators in the R14 suite (from the same 11 patches): niche-option fixed buffer (4),
union Size (2 runs), bool fixed buffer (1), sized-union / NonZero / ExprLen guards (4 runs).

## FP adjudication of batch 2's three "passes" (2026-09-20) — all three FALSE POSITIVES

The panel flagged the exact gap my solvability trimming had created: fixtures listed in TYPES (so
they are generated) but never asserted. Cited: ScopeOne/ScopeTwo (sibling-module consts SN=1/SN=2),
LeftHolder/RightHolder (sibling-module aliases Bytes2=[u8;1]/[u8;8]), PtrAliases, DeepAlias. A
candidate with flat, non-scoped name maps emits `data[2]` for ScopeOne and `bytes[8]` for
LeftHolder and still passed. One panel also found `c_float`/`c_double` unexercised, and a candidate
emitting `fixed byte* ps[2]` (invalid C#, CS1663) for an array of pointer-to-array.

=> The 3/11 was never real. Every "pass" I preserved by leaving hard cells unasserted was an FP.

R19 response (FP-clean): meta.md now STATES the scoping rule ("A `const` or alias name resolves in
the module that uses it, so sibling modules may give the same name different values"), and every
generated fixture is asserted: the two collision pairs, PtrAliases + AliasPtrs (restored), DeepAlias
(its test had also been lost in an R14 cut), Tag8, BigKind's C# base, plus a new c_float/c_double
cell. Reference passes all four judge probes.

Re-grade of the batch-2 patches against the FP-clean suite: **0/11**.

| Cell | Fails |
|---|---|
| same_named_consts_in_sibling_modules | 11/11 |
| same_named_aliases_in_sibling_modules | 11/11 |
| c_float_and_c_double | 7/11 |
| aliases_to_raw_pointers_are_lowered | 5/11 |
| niche_option_array_is_one_fixed_buffer | 4/11 |
| everything else | <= 3 |

Those 11 solved against a meta that never mentioned module scope. Batch 3 (full price, meta changed)
is the only way to measure solvability of the stated contract.

## R23 NARROWING (Option A, 2026-09-21) — contract reduced, scoping surface deleted

meta.md: dropped "A `const` or alias name resolves in the module that uses it..." and changed
"An array length is an integer literal or a `const` name" -> "An array length is an integer literal"
(472 words). Solution reverted to ONE global alias map (base semantics): no scoped_aliases/lookup/
get_mapped_value_scoped, no RustStruct.module / ExternMethod.module, no const-length collection, no
scope parameters anywhere (`grep -c scope src/*.rs` = 0). Kept the two non-scoping fixes from that
era: niche-Option arrays flatten to a fixed buffer, and a declared struct beats a `NonZero*`
primitive spelling. human-eff 598 -> 398.

Tests 94 (69 F2P + 25 P2P + 3 lib); all Scope*/Left*/Right*/Shadow*/Dep*/ConstLen/ConstGrid fixtures
deleted; TYPES audit clean.

Re-grade of the batch-2 patches against the narrowed suite: **0/11, but no cell fails everyone** and
the distribution is healthy:

| Cell | Fails | Fair? |
|---|---|---|
| c_float_and_c_double | 7/11 | yes - repr(C) scalar sizes |
| aliases_to_raw_pointers_are_lowered | 5/11 | yes - stated alias + pointer rules |
| niche_option_array_is_one_fixed_buffer | 4/11 | yes - stated Option-niche + fixed-buffer rules |
| container_of_sized_union guard | 3/11 | yes - over-promotion guard |
| union Size cells | 2/11 | yes |
| pointers_follow_aliases | 2/11 | yes |
| paren-length guard | 1/11 | yes |

Per-run: Vega fails exactly ONE cell (niche_option_array); Nova #8/#7/#6/#3/#2 fail two. Two cells
that failed 11/11 in the first narrowed re-grade were MY artefacts and were fixed, not trimmed:
ExprLen had been rewritten to use a const name (every agent resolves those), and the
user-struct-named-NonZeroU32 fixture was another name-identity corner - deleted with the narrowing.

This population solved under the OLD contract, so 0/11 here is weak evidence; the blockers are now
all small stated rules rather than a name resolver.

## Batch 3 (2026-09-21, R25 artifact, narrowed contract) — 0/16 (15 Nova + 1 Vega)

Much tighter than batches 1-2: no cell fails everyone, and FOUR runs fail exactly one cell.

| Cell | Fails (of 16) | Verdict |
|---|---|---|
| arrays::niche_option_array_is_one_fixed_buffer | 8 | fair (two stated rules combined: Option niche payload + fixed-buffer flattening) |
| scalars::c_float_and_c_double | 7 | **UNFAIR AS WRITTEN** - meta enumerated the 8-byte C scalars and never mentioned c_float/c_double, inviting "unlisted c_* has no fixed layout". Agents emitted the right C# types but no layout. |
| scalars::pointers_follow_aliases_to_arrays_and_functions | 6 | fair |
| base: container_of_sized_union guard | 5 | fair (over-promotion) |
| base: expression / parenthesised length guards | 5 each | fair but they punish OVER-delivery (agents evaluate `4 + 4`); dropping them adds no passes, so kept |
| pointers_to_arrays, every_fixed_buffer_primitive | 3 each | fair |
| aliases_to_raw_pointers, union_array_elements | 2 each | fair |
| bitfield cells | 1 each | fair |

Near misses: Nova #2 and Nova #8 fail ONLY c_float; Nova #1 (Nova_Nova_15) and Vega fail ONLY
niche_option_array.

**Counterfactual (measured, not guessed): with the c_float rule stated, Nova #2 and Nova #8 pass ->
2/16 = 12.5%, in band.** R26 therefore adds "`c_float` takes 4 and `c_double` 8" to meta (478 words).
Those two runs are now stale (meta changed), so the number must be re-earned on fresh runs.

If a fresh batch still returns 0, the next relaxation lever is the niche-option-array cell (the 8/16
killer): dropping it on THIS batch would have produced ~5/16 = 31%, still inside the band.

## Batch 4 (2026-09-21, R26 artifact: c_float + niche-array clauses) — 1/10, ACCEPTED

| Run | Verdict | New fails | Base fails | Cause |
|---|---|---|---|---|
| Nova #8 (Nova_Nova_3) | PASS_LEGITIMATE | 0/70 | 0 | 5 files, 974 human-eff |
| Nova #9 (Nova_Nova_2) | FAIL | 1 | 0 | extra pointer level on a nested pointer alias (F-44) |
| Nova #5 (Nova_Nova_6) | FAIL | 0 | 1 | NonZero-by-name niche (L6) |
| Nova #10 (Nova_Nova_1) | FAIL | 1 | 1 | `fixed byte* p` (F-44) + sized-union over-promotion (F-46) |
| Nova #2, #3, #7 | FAIL | 2-3 | 0 | F-44 / F-45 / c_float |
| Nova #4, #6 | FAIL | 2-3 | 2 | F-44 + F-46 + over-delivery on expression lengths |
| Nova #1 (Nova_Nova_10) | FAIL | 70/70 | 29/29 | stack overflow in recursive alias formatting (wipeout) |

Measured against batch 3: niche-Option array 8/16 -> **0/10** and c_float 7/16 -> **1/10** after the two
clauses. F-44 held at 7/10. 63/70 new tests killed nobody. Prompt tokens 8.0M-16.2M per run; failing
patches 970-1372 raw +LOC.

