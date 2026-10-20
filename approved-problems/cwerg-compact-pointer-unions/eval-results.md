# cwerg-compact-pointer-unions — eval results

No platform batch yet. Local validation numbers are logged below.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|

## Local validation (2026-10-15, slice)

Clean room: fresh clone at BASE + test.patch, image `factory-cwerg-compact-pointer-unions:latest`
built from the platform Dockerfile, run as uid 1000 with `--network none`, solution applied inside the
container with `git apply` and checked to have landed (11 files, +397/-32).

| Run | Cases | Failed |
|---|---|---|
| base mode, before solution | 230 | 0 |
| new mode, before solution | 54 | 54 (py: static assert, cc: static assert, output: build did not run) |
| base mode, after solution | 230 | 0 |
| new mode, after solution | 54 | 0 |

Effective LOC hook (solution.patch): raw 394, human-effective 317, padding floor 120, 9 files.
Flakiness 3x: not run in the slice (owed at FINISH).

Trap probes against the hunter's Python sketch (bitcast encoding, register hack keyed on `is_ptr()`):
globals FE assert (`unhandled node: [bitwise_as] [@] [Id] a`) on x64 + a32; layout runtime segfault on
x64 + a32 (wrapped-pointer member); ops, convert pass. Flag-only (just setting `optimize_union_tag`)
traps at runtime on the linked-list probe and the compact probe.

## Batch 1 (2026-10-16): Orion 4/4 PASS, no Nova runs

| Run | Agent | Verdict | Files | +lines | Failed tests | Approach |
|---|---|---|---|---|---|---|
| Orion #4 (dir Orion_Orion_1) | Orion | PASS_LEGITIMATE, FP genuine (1 judge dissent: base partial-eval bug) | 18 (incl. optimize.cc/py, emit_ir) | 695 | none | unwrap-void predicate, tag = word > 0xFFFF ? ptr : word |
| Orion #3 (dir Orion_Orion_2) | Orion | PASS_LEGITIMATE, FP genuine | 15 | 660 | none | predicate without void-count, tag = word > max zero typeid |
| Orion #2 (dir Orion_Orion_3) | Orion | PASS_LEGITIMATE, FP genuine (1 dissent: union(^T,^T) dedup, ref same) | 16 (cwast.py helper) | 782 | none | tag by EQ against each zero member typeid; inlines global union initializers |
| Orion #1 (dir Orion_Orion_4) | Orion | PASS_LEGITIMATE, FP genuine | 16 | 602 | none | A-reg class, tag = word <= max zero typeid |

All four also edited sizeof_test.cw / linked_list_gen_test.cw identically to test.patch and added FE/LangTest/sum_compact_test.cw (repo naming, not a leak).

### Differential probe battery (worktrees/cwerg-cu-tools/battery*, results r*/), py+cc x x64/a64/a32
~30 cells; every cell also run on base (regular unions) for fairness.

| Cell | base | ref | O1 | O2 | O3 | O4 |
|---|---|---|---|---|---|---|
| widen side-effecting `make_missing()` into compact (let/set/arg/return) | n/a (size) | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| `set v = noisy()` / `let u = noisy()` into union(void,P) | let-init drops call (base bug) | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| **`wrap_as(noisy(), Missing)` into compact Held** | `set` form OK on regular | 6/6 | 6/6 | **0/6 FE crash (MayHaveSideEffects ExprWrap)** | 6/6 | 6/6 |
| wrapped-pointer alignment after u8 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| wrapped pointer x globals / conversions / trylet | 6/6 | all 6/6 | | | | |
| trylet regular->compact delta, compact->compact delta | 6/6 | all 6/6 | | | | |
| records by value, pointer writes, ref locals, array copy, spans, 7 params, field via ptr, call into field, reorder, eq | 6/6 (a32 7-param CG bug in base) | all equal to base | | | | |
| py/cc IR parity on the 6 test programs | | 12/12 | 12/12 | 12/12 | 12/12 | 12/12 |
| zero-size record member, untagged union with compact member, union!(void,^T) params, global-from-global union conversion, const-eval is/union_tag on globals, union_untagged | base cannot compile or run these with REGULAR unions: out of domain | | | | | |

## Local validation after the batch-1 round (2026-10-16)
Clean room as root (platform grades as root), image from the platform Dockerfile, --network none, test.patch applied to a reset BASE checkout, solution applied with git apply and checked to land (11 files, +426/-33).

| Run | Cases | Failed |
|---|---|---|
| base mode, before solution | 230 | 0 |
| new mode, before solution | 63 | 63 |
| base mode, after solution | 230 | 0 |
| new mode, after solution (x3) | 63 | 0, 0, 0 |

Replay of the new effects program on the batch-1 Orion patches: O1/O3/O4 pass, O2 FE crash. Projected re-eval Orion 3/4.

## Batch 2 (2026-10-17): re-eval of batch 1 (Orion 3/4) + Vega x2 (2/2), no Nova

| Run | Agent | Verdict | Files | +lines | Failed tests | Approach |
|---|---|---|---|---|---|---|
| Orion #4 (dir Orion_Orion_1) | Orion | PASS_LEGITIMATE, FP genuine | 18 | 695 | none | same patch as batch 1 |
| Orion #3 (dir Orion_Orion_2) | Orion | FAIL_MISSED_REQUIREMENT | 15 | 660 | effects_755373 x6 (+3 py/cc output) = 54/63 | FE crash on wrap_as(touch(), Gone): MayHaveSideEffects ExprWrap (projected) |
| Orion #2 (dir Orion_Orion_3) | Orion | PASS_LEGITIMATE, FP genuine | 16 | 782 | none | same patch as batch 1 |
| Orion #1 (dir Orion_Orion_4) | Orion | PASS_LEGITIMATE, FP genuine | 16 | 602 | none | same patch as batch 1 |
| Vega #2 (dir Vega_Orion_1) | Vega | PASS_LEGITIMATE, FP genuine | 20 (optimize.{cc,h,py}) | 1255 | none | wrapped-uint word, tag = word <= max void typeid, special-cased (== (uniontag u) typeid) |
| Vega #1 (dir Vega_Orion_2) | Vega | PASS_LEGITIMATE, FP genuine | 19 incl. BE/CodeGenX64/legalize.{cc,py} | 1388 | none | uint word, tag = word < 1<<16; fixed x64 BITCAST-immediate legalize in the backend |

Auto Review: Approved 3/3/3; difficulty note only (Orion 3/4, Vega 2/2, Nova 0 runs).

### Batch-2 probe battery (worktrees/cwerg-cu-tools/battery9..13, results r11..r15), backend tools rebuilt per impl
o1..o4 = Orion #1..#4, v1 = Vega #1 (dir Vega_Orion_2), v2 = Vega #2 (dir Vega_Orion_1).

| Cell | base | ref | o1 | o2 | o3 | o4 | v1 | v2 |
|---|---|---|---|---|---|---|---|---|
| batch-1 battery (p04 wide conversions, p09 ==, q04 trylet wrapped) | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | **4/6 x64 CG crash** |
| expr-block / select zero-size values with side effects into compact | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| is()/union_tag on call results, && / || short-circuit, while cond | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| narrow_as of call results (read + write through) | 6/6 | all 6/6 | | | | | | |
| tag compares vs non-member / runtime typeid / wrapped member | 6/6 | all 6/6 | | | | | | |
| compact args from side-effecting calls | 6/6 | all 6/6 | | | | | | |
| **`let! h Held = MISSING` then `h == wrap_as(@!c1, Handle)` (small program)** | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | **4/6 x64 CG crash** |
| same cell appended to ops_755373 | 6/6 nosize | all 6/6 incl. v2 (trigger is context-fragile) | | | | | | |

v2 crash: `x64 codegen.cc:163 could not find matching pattern for bitcast ... 27:U64` -- its U64 word is bitcast to A64 and BE constant propagation turns the operand into an immediate. v1 hit the same bug and fixed BE/CodeGenX64/legalize.{py,cc} (test.sh rebuilds the BE tools, so its fix counts). No cell splits the three Orion passers.

### Sequence length (2026-10-18 rule: passing Orion/Vega runs must average > 256k)
| Run | Verdict | sequence_length |
|---|---|---|
| Orion #1 / #2 / #4 | PASS | 143,400 / 154,483 / 177,691 (no compaction) |
| Orion #3 | FAIL | 195,728 |
| Vega #1 (Vega_Orion_2) | PASS | 335,697 (corrected 2026-10-18 from batch 4; was logged swapped) |
| Vega #2 (Vega_Orion_1) | PASS | 327,159 |

Orion cannot qualify (every pass < 256k). Vega is the qualifying codename. agent-runs/3 is a byte-identical copy of agent-runs/2.

### Battery 14/15 (2026-10-18): compact local holding a constant zero-size member, then a pointer-side op
Each shape is its own function so BE constant propagation sees one definition (results r16, r17).

| Cell | base (no size assert) | ref | o1 | o2 | o3 | o4 | v1 | v2 |
|---|---|---|---|---|---|---|---|---|
| s1 `h == wrap_as(@!c1, Handle)` | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s2 guarded `unwrap(narrow_as(h, Handle))^` | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s3 guarded `narrow_as(l, ^!u32)^` | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s4 widen Lookup -> Wide | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s5 widen Held -> WideHeld | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s6 trylet on constant Lookup | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s7 `l != @!c1` | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | x64 CG crash |
| s8 narrow to Errs / Wide -> Lookup | 6/6 | all 6/6 incl. v2 | | | | | | |
| s9 two definitions (ptr then set MISSING) | 6/6 | all 6/6 incl. v2 | | | | | | |
| combined file locals_755373 (s1-s7 as functions) | 6/6 | 6/6 | 6/6 | 6/6 | | 6/6 | 6/6 | **4/6 x64 CG crash** |

Root cause in v2: `(bitcast (as tag uint) compact)` keeps the word in U64 and bitcasts to A64 for pointer use; the BE folds `mov h = 27` into `bitcast:A64 = 27:U64`, which x64 legalize has no pattern for. Ref and the Orions never bitcast an immediate; v1 fixed legalize. Projected re-eval: Vega 1/2 (v1 passes, 327k).

## Batch 4 (2026-10-18): re-eval of batch 2 + Vega x2 fresh. Orion 3/4, Vega 3/4, Nova 0 runs
| Dir | Run | Agent | Verdict | seq | Patch | Notes |
|---|---|---|---|---|---|---|
| Orion_Orion_1 | Orion #4 re-eval 2 | Orion | PASS, FP genuine | 177,691 | = batch-2 Orion_Orion_1 | |
| Orion_Orion_2 | Orion #3 re-eval 2 | Orion | FAIL_MISSED_REQUIREMENT 63/72 | 154,483 | = batch-2 Orion_Orion_2 | effects: ExprWrap side-effect crash |
| Orion_Orion_3 | Orion #2 re-eval 2 | Orion | PASS, FP genuine | 195,728 | = batch-2 Orion_Orion_3 | |
| Orion_Orion_4 | Orion #1 re-eval 2 | Orion | PASS, FP genuine (1 dissent: low address 0x1000, excluded) | 143,400 | = batch-2 Orion_Orion_4 | |
| Vega_Orion_1 | Vega #2 (fresh) = v4 | Vega | PASS, FP genuine (1 dissent: union(^T,^T) dedup) | 512,247 | new | wrapped uint word, tag = word <= max zero typeid, MakeNodeCopyable temps, legalize BITCAST fix |
| Vega_Orion_2 | Vega #1 (fresh) = v3 | Vega | PASS, FP genuine | 414,562 | new | wrapped ^void word, tag = word < 1+max zero typeid, asserts copyable sources, legalize BITCAST fix |
| Vega_Orion_3 | Vega #2 re-eval 1 = v2 | Vega | FAIL_REGRESSION 69/72 | 327,159 | = batch-2 Vega_Orion_1 | x64 bitcast-immediate (locals test), as projected |
| Vega_Orion_4 | Vega #1 re-eval 1 = v1 | Vega | PASS, FP genuine | 335,697 | = batch-2 Vega_Orion_2 | |

Auto Review: Approved (Description 3, Tests 2 for a T8 diagnostic in check_output, Solution 3); difficulty fails: Orion 3/4, Vega 3/4, Nova 0/8.
Solution Quality: one FAIL claimed the Python DefRec/DefType guard was dropped; false, the guard is at canonicalize_union.py:86-87 and a re-run passed.

### Battery 17 (all 63 earlier probe programs) and battery 18 (8 new), results r20, r21
Zero divergence between ref, v1, v3, v4 on battery 17 (250/378 each; the rows that fail fail everywhere, base included).
Battery 18 (nested pointer-to-union members, compact-to-compact narrowing, arrays + spans, global linked chain, pointer to compact, wrapped pointer to record, six zero-size members): base 48/48, v1 v3 v4 48/48, **ref failed g01** (`union(Missing, ^!Lookup)`: the bits union kept the stale `^!Lookup` member). Fixed in both FEs (replacement member types in the bits union and in the pointer narrows).

### Battery 19/20 (non-variable conversion sources), results r22, r23; battery 21 = the new elements test, r24
Each shape in its own program, compact (`p_c_*`, `p_idx_*`) and a regular-union twin (`p_r_*`).

| Cell | base | ref (fixed) | v1 | v3 | v4 | o1 | o2 | o4 |
|---|---|---|---|---|---|---|---|---|
| compact from field / deref / call arg / set, narrow from index | 0/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 | 6/6 |
| **widen compact array element** (let, set, arg, return, loop, global array, span element, `a[i].f`, wrapped pointer) | 0/6 | 6/6 (was 0/6) | **0/6** | **0/6** | 6/6 | 6/6 | 6/6 | 6/6 |
| regular-union twins (`p_r_*`) | 0/6 | 6/6 (new) | 0/6 | 0/6 | 0/6 | 6/6 | 0/6 | 0/6 |
| `==` on a field, trylet from a field | 0/6 everywhere (left as base) | | | | | | | |

v1 and v3 clone the source behind `IsNodeCopyableWithoutRiskOfSideEffects`, which rejects `(^ (incp front i))`; v4 and the Orions make a temporary.
New test FE/UnionTest/elements_755373_test.cw, full new-mode replay (81 cases): v4 0 failed, v1 9 failed, v3 9 failed (all 9 = elements). Projected re-eval: **Vega 1/4 (v4, 512,247)**, Orion 3/4.
Clean room r5 (root, --network none, BASE + test.patch, solution applied and checked to land): base 230/0 before, 230/0 after (x2); new 81/81 failed before, 0 failed after (x3).

## Batch 5 (2026-10-18): re-eval of batch 4 on the elements suite + 8 fresh Nova

| Dir | Run | Solver | Verdict | seq | Note |
|---|---|---|---|---|---|
| Nova_Orion_8 | Nova #1 | Nova | FAIL 36/81 | 784,251 | |
| Nova_Orion_7 | Nova #2 | Nova | FAIL_MISSED_REQUIREMENT 63/81 | 796,635 | nearest Nova |
| Nova_Orion_6 | Nova #3 | Nova | FAIL_MISSED_REQUIREMENT 36/81 | 808,776 | |
| Nova_Orion_5 | Nova #4 | Nova | FAIL_MISSED_REQUIREMENT 36/81 | 1,049,354 | |
| Nova_Orion_4 | Nova #5 | Nova | FAIL 36/81 | 1,362,491 | |
| Nova_Orion_3 | Nova #6 | Nova | FAIL_MISSED_REQUIREMENT 36/81 | 1,063,542 | |
| Nova_Orion_2 | Nova #7 | Nova | FAIL_MISSED_REQUIREMENT 45/81 | 780,977 | |
| Nova_Orion_1 | Nova #8 | Nova | FAIL_MISSED_REQUIREMENT 36/81 | 1,050,428 | |
| Orion_Orion_4 | Orion #1 re-eval 3 = o1 | Orion | PASS, FP genuine | 143,400 | |
| Orion_Orion_3 | Orion #2 re-eval 3 = o2 | Orion | PASS, FP genuine | 195,728 | |
| Orion_Orion_2 | Orion #3 re-eval 3 | Orion | FAIL_MISSED_REQUIREMENT 72/81 | 154,483 | effects |
| Orion_Orion_1 | Orion #4 re-eval 3 = o4 | Orion | PASS, FP genuine | 177,691 | |
| Vega_Orion_4 | Vega #1 re-eval 1 = v1 | Vega | FAIL_MISSED_REQUIREMENT 72/81 | 335,697 | elements x9, as projected |
| Vega_Orion_3 | Vega #2 re-eval 1 = v4 | Vega | **PASS, FP genuine** (1 dissent: union(^!u8,^!u8), base cannot compile it) | **512,247** | |
| Vega_Orion_2 | Vega #1 re-eval 2 = v3 | Vega | FAIL_MISSED_REQUIREMENT 72/81 | 414,562 | elements x9, as projected |
| Vega_Orion_1 | Vega #2 re-eval 2 = v2 | Vega | FAIL 78/81 | 327,159 | x64 bitcast (locals) |

Gate: **Nova 0/8, Nova avg 962,057 (> 256k); Vega 1/4, passing Vega avg 512,247 (> 256k).** Orion 3/4 (not the qualifying agent).
Auto Review: Revision Requested. Description 3, **Tests 1** (T3/T4 High x2: no test that a zero-sized NON-void member, e.g. `union(^u8, [0]u8)`, stays uncompressed, py and cc), Solution 3. Difficulty note pools Orion+Vega as 4/8; recorded as a note, not a band.

### Battery 22 (zero-length vector members), r25; mutant check battery 23
`union(^u8, [0]u8)`, `union(^!u32, wrapped [0]u8)`, `union(Missing, ^!u32, [0]u8)` size == 2 words, plus a runtime use: base, ref, v1, v3, v4, o1, o2, o4 all 6/6 on every program. Lever kills nobody.
Added to layout_755373_test.cw: `wrapped type Empty = [0]u8`, `type Gap = union(^u8, [0]u8)`, `type GapHeld = union(NotFound, Handle, Empty)`, both static_assert 2 * size_of(^u8).
Mutant (reference with the void check removed in both type corpora): layout fails in py and cc on x64/a64/a32 (cc: static assert failed at line 43, `Gap`); unmutated reference passes.
Clean room r6 (zero-vec asserts, root, --network none): base 230/0 before, 230/0 after (x2); new 81/81 failed before, 0 failed after (x3).

## Batch 6 (2026-10-19, ACCEPTED): re-eval of batch 5 with the zero-length-vector asserts
Same pool as batch 5. Nova 0/8 (passed 27-63 of 81; layout newly failed for Nova #8, #5, #2), Vega 1/4 (v4 PASS 512,247; v1/v3 elements only, v2 x64 locals only), Orion 3/4 (Orion #3 effects only). Auto Review Approved 3/3/3; FP genuine.
Per-program kills over the 14 runs with junit (+2 Nova from batch 5): elements 10, convert 8, effects 8, locals 8, ops 6, layout 3, globals 0, sizeof 0, linked_list_gen 0.
