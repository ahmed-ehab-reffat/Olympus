ACCEPTED 2026-10-19 (human). Finalized: archived here, agent runs and clones deleted.

# cwerg-compact-pointer-unions — feedback

## Status (2026-10-15, olympus-factory MODE=SLICE)

SLICE-READY. Clean room passed (uid 1000, --network none, numbers in eval-results.md). Core slice = full reference for the capability in
both front ends (py + cc), 4 new FE programs + 2 updated repo size tests, harness reused from the
accepted cwerg-fe-address-constants. No differentiating scope added beyond what the core needs.

- Lane (hunt #63): one-word layout for `union(void, ^T)` / `union(err..., ^T)` in the Python and C++
  front ends (the disabled `optimize_union_tag` representation). Base 3bc94f7c = master HEAD.
- Reference: `type_corpus` flags on + register hack made consistent with sizing (unwraps wrapped
  pointers, tagged only); per-union replacement record `xcompact_<name> { bits: untagged(members..., uint) }`;
  zero-size members encoded as their typeid; tag/narrow/widen/compact<->regular/zero-only conversions
  in `canonicalize_union.{py,cc}`. No emitter change needed. py and cc emit byte-identical IR on all probes.
- Hook: raw 394, human-effective 317, padding floor 120 (twin mirror), 9 files.
- Tests: `FE/UnionTest/{layout,ops,convert,globals}_755373_test.cw` x (py, cc) x (x64, a64, a32) + output
  parity per target = 36 cases, plus updated `FE/LangTest/sizeof_test.cw` and
  `FE/LangTest/linked_list_gen_test.cw` (18 cases) = 54 new-mode cases (9 per program). Base mode = every existing FE
  program except those two (they pin the old layout and move to new mode).
- Fairness check done: with the size `static_assert`s stripped, all four programs pass on BASE with
  regular unions in both FEs on x64 and a32, so every runtime check is existing union behaviour.
- Trap evidence so far (on the hunter's Python sketch, which uses bitcast + `is_ptr()`): `globals`
  fails with `unhandled node: [bitwise_as] [@] [Id] a` (data emitter cell), `layout` segfaults at runtime
  (wrapped-pointer member sized one word, lowered as `{tag, union}`). Flag-only (just flipping
  `optimize_union_tag`) compiles and traps at runtime (silent overlap), reproduced on base.

## Decisions taken without the user (unattended run)

1. **Gate 1 value-vs-cost accepted, flagged.** Base output is correct, only larger. Proceeded because
   size is a language observable (`size_of`, `offset_of`, `static_assert`) and the design doc +
   two repo test comments state the target. If the precheck calls it perf-only, shelve.
2. **2024 disable commit (be870a21)** is a disabled half-feature (no lowering ever existed), not a
   removed capability. Name it in the precheck reasoning if asked.
3. **Domain caps added to meta (L60), each a base limitation of REGULAR unions measured today:**
   widening a union-valued call result asserts in base py (`_MakeValRecForWidenFromUnion` wants an Id)
   and segfaults base cc; unions with 64-bit members cannot be copied by the a32 backend
   (`ld.stk ... U64`), base too; default-initialized union globals crash base py (hunter). Pointers
   stored in unions are real object addresses (typeid encoding needs addresses >= 65536; lowest data
   address measured: a32 0x31a24, x64 0x411d8c, a64 0x411784).
4. **Existing repo tests modified in test.patch** (`sizeof_test.cw`, `linked_list_gen_test.cw`) rather
   than copied: the stale comments state the new sizes. Risk: an agent that edits the same lines could
   make test.patch conflict at grade time. Fallback if the precheck or a batch shows it: leave the
   originals untouched, exclude them from base mode, and add copies under `FE/UnionTest/`.
5. **Output parity, not IR parity**, in the slice (same as the accepted address-constants). The
   reference already emits identical py/cc IR on every probe, so IR parity (the repo's
   "assimilation" convention, `FE/Makefile_cc`) is a ready hardening lever for FINISH.
6. Kept the core test count small (4 programs); cross-product cells listed in DESIGN.md § 11b go in at FINISH.

## Risks for the precheck
- Derivative MEDIUM: the flag and two repo comments ("should be (* N 16) with union optimization")
  are visible to any author. Not a tracker issue.
- Gate 1 perf-only reading (see decision 1).

## Attempt history
- 2026-10-15 slice built and validated locally: base 230/0 before and after the solution, new 54/54
  fail on base (all on the size static_asserts) -> 0/54 with the solution.
- Owed at FINISH: flakiness 3x, root / unmapped-uid runs (platform grades as root), a clean
  `--no-cache` build timing (the first build of the image took 4m04; a later --no-cache run took 38m
  because a BuildKit session stalled on this host, not because of the Dockerfile), Docker images
  `factory-cwerg-compact-pointer-unions:*` removed at the end of the slice run.

## 2026-10-16 Task Prompt Quality FAIL (ai_generated) -> humanizer + word-level drift repair
- Raw Output: one major `ai_generated` comment quoting the opener "I would like the Cwerg front ends to store a pointer-like tagged union in a single machine word." Content judged fine.
- User ran the body through the humanizer. Adopted its text, fixed only drift (pre-humanizer meta saved at worktrees/cwerg-compact-meta-pre-humanizer.md):
  1. U+2024/U+201A look-alike punctuation -> ASCII; backticks restored on code tokens (approved cwerg sibling uses them).
  2. "A union containing tags and one pointer-type member" -> "A tagged union containing nothing but one pointer-type member" (lost "exactly").
  3. "void and similar types" -> "void and wrapped types of void" (tests use wrapped-void error types only).
  4. "A union would be laid out more tightly" -> "Such a union"; "struct member" -> "record field".
  5. "whether a union is tagged or compressed" -> "regular or compressed" (compact unions are still tagged).
  6. "comparisons of union members" -> "comparisons against member values".
  7. "assignment to addresses narrowed from tagged unions" -> "assignment through pointers narrowed from compressed unions".
  8. Conversion targets: humanizer said "zero-size member-only and untagged unions" (untagged is WRONG, tests convert to regular tagged unions) -> "in both directions ... other compressed unions, unions with only zero-size members, and regular tagged unions".
  9. "can initialize global and constant compressed unions, records, and arrays" -> "global compressed unions and constant records and arrays that contain them".
  10. "produce the same results" -> "must produce" (py/cc parity); "have initializers" -> "have explicit initializers"; "Values returned from functions in union objects should be assigned" -> "Union values returned from functions are assigned" (domain cap, not an instruction).
  11. "have a compact representation" -> "should get" (design note describes a target, not current behaviour).
- Body now 356 words, ASCII. Next: re-run Task Prompt Quality.

## 2026-10-16 round 2: humanizer-1 text flagged again (ai_generated, quote = its opener)
- Second humanizer pass adopted (round-1 meta saved at worktrees/cwerg-compact-meta-humanizer1.md). Word-level drift fixes only:
  ASCII punctuation + backticks; "includes a tagged union value with a tag ... and one or more fields" -> "lays out each tagged union value as a tag of type typeid followed by its payload";
  "such as void and other types" -> "namely void and wrapped types of void"; "has the same size" -> "should have"; "one pointer and zero-sized types" -> "one pointer and one or more zero-sized types";
  "wrapper type ... can be considered ... in those environments" -> "wrapped type ... should be considered ... of such a tagged union"; "struct members" -> "record fields";
  "size_of and offset_of functions applied to these tagged unions will be affected" -> "will reflect the smaller size" (offset_of applies to records holding them);
  "code within a program should not depend" -> "the behavior of a program"; feature list had NO verb -> "must work the same for compressed tagged unions";
  dropped "implicit" from conversions (narrowing back is explicit); "zero-length members" -> "only zero-sized members";
  initialization clause split out: "Global compressed tagged unions, and constant records and arrays that contain them, can be initialized with member values, including global addresses";
  "produce identical results when running programs" -> "must produce identical results for programs"; "have initializers" -> "explicit initializers";
  "assigned to variables and then cast" -> "before being converted" (not always converted); "64-bit fields" -> "64-bit members".
- Fallback if flagged again on the opener: replace ONLY the opener with a scenario-first sentence (micasa precedent).

## 2026-10-16 round 3: AI detector PASSED (humanizer-2 text), requirementCount FAILED (~20 rules / 387 words)
- Text that passed the AI gate saved at worktrees/cwerg-compact-meta-humanizer2-aipass.md.
- Cut by sentence deletion only (no batch yet, so no kill counts), to ~9 rules / ~200 words:
  - "Cwerg's compiled code ... tag of type typeid followed by its payload" (background).
  - "Tagged unions ... will use less space in all contexts ..." and "Output of size_of and offset_of ..." (implied by "same size and alignment as a pointer type"; offsets follow).
  - The full operation list (is, union_tag, ==/!=, narrow_as, trylet, narrowed-pointer writes, conversions) and the global-initializer sentence: implied by "behavior should not depend on whether a tagged union is compressed". Every runtime check passes on BASE with regular unions (slice fairness check), so the general rule covers all of them.
  - "The Python and C++ front ends must produce identical results" (covered by "identical results using either front end").
- Kept "Other unions are unaffected": layout test asserts Mixed / Two stay two words.
- Kept all four caps (each is a base limitation of regular unions).
- Reference and tests unchanged (no behaviour was dropped, only its enumeration).

## 2026-10-16 Solution Quality FAIL: zero-size member widening dropped side effects
- Finding (HIGH): `_MakeCompactFromMember` / `MakeCompactFromMember` replaced any zero-size source that was not a bare `ExprCall` with the typeid constant.
- Reproduced (probes in worktrees/cwerg-cu-tools/probe/, runner run.sh): `set v = noisy()` into `union(void, ^!s32)` reaches the helper as an `ExprStmt` (void calls are canonicalized before ReplaceUnions), and `wrap_as(noisy(), Missing)` as an `ExprWrap`; both lost the call (hits 1 instead of 2). The same programs with a regular union keep the call on base.
- Fix (both FEs, identical): discard the source only when it is `Id` / `ValVoid` under any number of `ExprWrap`; anything else is kept as `do <expr>` inside the ExprStmt that yields the compact value. py and cc IR byte-identical on all probes; x64/a64/a32 all pass (args, returns, let, set, globals Id).
- Not covered (base bug, regular unions too): deref of a computed pointer to a zero-size type: base py asserts in the emitter, base cc drops the call. Domain is out of the tests; left alone.
- solution.patch regenerated (same 9 files), human-effective 325.
- Clean room after fix: base 230/0 before+after, new 54/54 fail before -> 0/54 after (uid 1000, --network none). New mode re-run 2 more times in the probe container: identical.

## 2026-10-16 Batch 1: Orion 4/4 (too easy), no Nova runs; Auto Review revision + Solution Quality PASS (2 mediums)
- All four passes FP-genuine. Auto Review: Tests 1/3 (T3 side-effect widening, T4 wrapped-pointer alignment), Solution 1/3 (S1 zero-size record compacted by the size-only predicate), calibration fail (Orion 4/4, Nova 0/8 missing).
- Solution Quality PASS but mediums: (1) optimize_union_tag also changes untagged-union register class (ref shortcut not guarded by tagged); (2) low-address typeid collision (already capped by the object-pointer assumption).
- Differential battery (eval-results.md): ~30 cells, ONE fair split: `set h = wrap_as(noisy(), Missing)` into a compact union crashes O2 in both FEs (base keeps the call for the same `set` on a regular union). Everything else converged, incl. IR parity. Zero-size records, untagged unions with compact members, global-from-global conversion and const-eval are base-broken for regular unions, so out of the domain (S1 is unreachable on base: a zero-size rec member hits ZeroDivisionError in layout).
- Projection for a tests-only round (T3 incl. the wrap_as cell + T4): Orion 3/4 on re-eval. Still too easy. Decision needed: Vega pool, Nova smoke, or a scope change (description delta).

## 2026-10-16 Round after batch 1 (user chose: tests fix + Nova smoke + Vega x4)
- Reference (S1): zero-size members count as eligible only when they unwrap to void, in BOTH sizing (`_GetSizeAndAlignmentForSum` / `GetSizeAndAlignmentForSum`) and register classification (`num_other_zero` guard on the pointer shortcut), py + cc. Unreachable on base (zero-size rec members crash layout) but now matches the meta wording. The untagged-register medium was already handled: the reference's shortcut sits after the untagged branch (the finding cited base line numbers).
- New test program `FE/UnionTest/effects_755373_test.cw` (9 cases): side-effecting `Stale` call widened into a compact union by `set` and by `return`, `set m = touch()` into union(void, ^!u32), `set k = wrap_as(touch(), Gone)` into a wrapped-pointer compact union (also as a record field), and the T4 offset asserts (u8 then wrapped-pointer compact union, offset == pointer size). Argument and `let` initializer forms left out on purpose: base drops those calls for REGULAR unions too.
- Fairness: the size-stripped copy passes on base 6/6 with regular unions. Replay: ref 6/6, O1/O3/O4 6/6, O2 0/6 (FE crash `MayHaveSideEffects: unexpected ExprWrap`). Projected re-eval: Orion 3/4 (too easy), so the cheap lane alone does not clear the gate.
- Patches regenerated (pre-round copies in worktrees/cwerg-cu-tools/{test.pre-effects,solution.pre-predicate}.patch). human-effective 338. Meta unchanged.

## 2026-10-18 Batch 2 read + Vega lever (user: do not shelve)
- Batch 2 = re-eval of batch 1 (Orion 3/4) + Vega x2 (2/2), no Nova. agent-runs/3 is a byte copy of agent-runs/2.
- New 2026-10-18 rule decides the agent: Orion passes are 143k-178k (< 256k, no compaction), Vega passes 327k / 335k. Only Vega can qualify, so the Orion 3/4 no longer matters.
- Lever: Vega #2 keeps the compact word as U64 and bitcasts to A64 for pointer use; when the local holds a constant zero-size member the x64 BE folds it into `bitcast:A64 = <imm>` and has no pattern (codegen.cc:163). Vega #1 hit the same bug and fixed BE/CodeGenX64/legalize. Robust once each shape sits in its own function (7 of 9 shapes crash v2).
- New test program `FE/UnionTest/locals_755373_test.cw` (9 cases): seven functions, each a compact local initialised with MISSING/EXPIRED followed by ==/!= with a pointer, guarded narrow + deref (wrapped and bare pointer), widening into a larger regular union, trylet. Size asserts on Held/Lookup make it fail on base.
- Fairness: size-assert-stripped copy passes on base 6/6 with regular unions; covered by "behavior should not depend on whether a tagged union is compressed" + "identical results on x64, a64, a32". Ref, v1, o1, o2, o4 12/12; v2 x64 crash on both FEs.
- Clean room (root, --network none): base 230/0 before and after; new 72/72 fail before -> 0/72 after, 3 identical new runs. Meta and solution unchanged. Pre-round test.patch in worktrees/cwerg-cu-tools/test.pre-locals.patch.
- Projected re-eval: Vega 1/2 (v1 327k passes). Then Nova smoke, then Vega x2 (both must fail for 1/4).

## 2026-10-18 Solution Quality FAIL x2 on the reference (field source + low-address tags)
- Run A (high): tags decoded as `word < 1 << typeid_bits` with no stated guarantee that object pointers sit above that range.
- Run B (high): `MakeCompactFromUnion` asserted an `Id` source (copied from base `_MakeValRecForNarrow`), so `narrow_as(box.value, Lookup)` aborted; (medium) same low-address point.
- Probed (battery16): base crashes on every field-source union conversion (regular to regular too); ref crashed only on regular field -> compact; v1, v2, o1, o2, o4 all handle it (o1 also fixes the base cases).
- Fix (py + cc, identical): `MakeCompactFromUnion` makes the source copyable with `MakeNodeCopyableWithoutRiskOfSideEffects` and wraps any temps in an ExprStmt; `MakeCompactTag` checks `1 << typeid_bits <= 0x20000` (lowest Cwerg load address: 0x400000 x64/a64, 0x20000 a32; stack and heap above the image) with a two-line comment; `FE/Docs/union_types.md` gets a short "Compact Layout" section stating the encoding and the guarantee.
- Regular-to-regular field conversions left as base (not compression related).
- No new test for field sources: base crashes on them for regular unions too, and every saved passer handles them.
- solution.patch now 10 files (adds the doc), human-effective 379. Clean room (root, --network none): base 230/0 before+after, new 72/72 fail -> 0/72, 3 identical new runs. Pre-round copy: worktrees/cwerg-cu-tools/solution.pre-fieldsrc.patch.

## 2026-10-18 Batch 4 (Orion 3/4, Vega 3/4) -> array-element lever
- Batch 4 = re-eval of batch 2 + 2 fresh Vega. Both fresh Vegas passed (414k, 512k), so Vega read 3/4. Solution Quality "DefRec/DefType guard dropped" FAIL was false (guard at canonicalize_union.py:86-87); re-run passed.
- Battery 17 (all 63 old probes) and 18 (8 new): zero agent divergence. Battery 18 found a REFERENCE bug: `union(Missing, ^!Lookup)` kept the stale `^!Lookup` member in the bits union. Fixed (replacement member types in the bits union and in the pointer narrows).
- Battery 19/20 found the split: widening a compact union read from an array element (or span element) into a wider regular union. v1 and v3 assert copyable sources, v4 and the Orions make a temporary, the reference asserted too. Reference fixed: compact conversions and the base regular widen/narrow helpers now go through MakeNodeCopyableWithoutRiskOfSideEffects (base's "Support for non-ID NYI" asserts removed), so the reference converts from any source whether or not the union is compressed.
- New test FE/UnionTest/elements_755373_test.cw (array/global array/span elements, `a[i].f`, wrapped pointer, call arg, return, set, plus the nested `^!Lookup` member). Meta unchanged: it excludes only call results as conversion sources.
- test.sh: check_output no longer sends the retried run to /dev/null and prints the stored output on a nonzero rc (Auto Review T8).
- Fairness note: base's regular unions crash on these sources too (NYI), so the test is F2P for that reason as well; the language doc allows widening from any expression and the meta carves out only call results.
- solution.patch human-effective 434 (was 379). Pre-round copies: worktrees/cwerg-cu-tools/{test,solution}.pre-elements.patch.

## 2026-10-18 Batch 5 (re-eval + 8 Nova): gate numbers met, Auto Review asks for a zero-size boundary test
- Re-eval landed as projected: Vega 1/4 (v4, 512,247), Orion 3/4. Nova 0/8, average 962k. FP: all four passes genuine.
- Auto Review Revision Requested only for Tests 1/3: no assertion that `union(^u8, [0]u8)` (zero-sized but not void) keeps the ordinary layout, in either front end.
- Probed every saved passer and the failers: all keep it at two words. Added two static_asserts (plain `[0]u8` and a wrapped `[0]u8` next to a wrapped void and wrapped pointer) to layout_755373_test.cw. A mutant that drops the void check fails them in both FEs.
- Test-only change: re-eval eligible; expected to leave every verdict unchanged. Pre-round copy: worktrees/cwerg-cu-tools/test.pre-zerovec.patch.

## 2026-10-19 ACCEPTED (batch 6 = re-eval with the `[0]u8` asserts)
- Nova 0/8 (avg seq 962k), Vega 1/4 (v4, 512k), Orion 3/4. FP: Vega pass genuine (high). Auto Review Approved 3/3/3.
- The `[0]u8` asserts killed 3/8 Nova (#8, #5, #2) and no Orion/Vega run, as the probe predicted.
- Finalized: F-101..F-104, L136/L137, Pattern 123; skills updated; runs + worktrees deleted.
