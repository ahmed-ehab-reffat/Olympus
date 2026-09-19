# DESIGN.md — cwerg-memory-passed-parameters

Base: robertmuth/Cwerg @ 3bc94f7c1c26834f98c614aef51b5aa7370615d9 (2026-06-18), the same base as the
accepted `cwerg-bcopy-bzero-lowering`, so its Dockerfile (413 s cold), baseline (BE py 94, FE py 102,
BE cc through Elf, identical 3x) and base-mode exclusions (ApiDemo/BindingsC need ARM cross compilers,
FE C++ needs GCC 13) carry over unchanged. Clone: `worktrees/Cwerg`. Hunt dossier:
`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-18.md`. Probe programs + Python prototype:
`worktrees/_cwerg_mpp/`. Dev image: `cwerg-dev:base` (the approved Dockerfile at base).

Requirement 0 (platform picker): CONFIRMED selectable by the user 2026-09-18 (eligible, Apache-2.0).

**R1 amendments (core slice as built — these override the sections below where they differ):**
- Title: "Add memory passing for overflowing parameters to Cwerg backends". Issue link #3 in frontmatter.
- The "a signature that fits keeps exactly today's code" sentence was DROPPED (untested, L53); T4 is
  not in the slice. meta.md states no per-class float threshold for x64, because py (7) and cc (8)
  disagree today and either reconciliation passes the tests.
- Two pre-existing twin divergences reached by the feature's own inputs are fixed in the reference
  (L60): x64 cc float parameter count 8 -> 7 (the eighth, xmm8, miscompiles: mutation M3), and the
  a32 cc immediate matcher reading float constants as integers (T5, reproduced on base).
- Six further pre-existing base defects are kept OUT of the fixtures (list in feedback.md).
- Tests: 4 programs x their targets x {py, cc, parity} = 18 new cases (C-backend/optimizer cases
  dropped: they pass on base). Traps T1, T2, T5 and the M3 twin wall verified by mutation.

## 0. Phase 1 — repo understanding (gate)

**Architecture.** Identical to the approved pick's § 0 (Python spec + C++ port under byte-identical
output; textual IR from `IR/opcode_tab.py`; target-independent passes in `BE/Base`; three backends
`BE/CodeGen{A32,A64,X64}` each with `regs` (calling convention + register pools), `legalize`
(`PhaseLegalization` sequencing), `isel_tab`, `codegen`; golden programs under `BE/TestData` run under
`qemu-*`; `codegen_parity` diffs py vs cc `-mode normal` text). What matters for this lane:

- **Calling convention** lives in each backend's `regs.{py,cc}`: `_GetCpuRegsForSignature` hands out
  parameter registers in declaration order per class (GPR / FLT; a32 pairs S regs for R64 and wastes
  an odd slot) and ASSERTS when a class runs out. a32: 6 GPR, 16 S / 8 D. a64: 16 GPR, 24 FLT.
  x64: 9 GPR in (rdi rsi rdx rcx r8 r9 r10 r11 rax), 9 GPR out (different order, rax first), 7 FLT.
- **Three consumers of that classification:** `lowering.FunPushargConversion` (caller side, reverse
  pass, `pusharg x` -> `mov argreg = x`), `lowering.FunPopargConversion` (callee side, forward pass,
  `poparg x` -> `mov x = argreg`, and results after a call), and `fun.cpu_live_in/out` (set in each
  `PhaseLegalization`, read by `liveness.py` to keep a pinned argument register alive up to the call).
- **Ordering:** argument conversion is the FIRST step of `PhaseLegalization` (a32: after the narrow
  width widening), before stack-access legalization, immediate rewriting, `FunCfgExit`, the CFG sanity
  check, then global/local register allocation and stack finalization. So a lowering that emits
  `st.stk`/`lea.stk`/`ld` is legalized by the existing later passes.
- **C++ twin:** `lowering.cc` rewrites instructions IN PLACE (`InsInit`) while iterating the block;
  `FunSetInOutCpuRegs` copies into fixed `cpu_live_in[MAX_PARAMETERS]` arrays. The IR allows up to
  `MAX_PARAMETERS = 64` parameters and results (`serialize.py:153`).

**Five subsystems.** `IR/` · `BE/Base` (lowering, liveness, reg_alloc, sanity, serialize) ·
`BE/CodeGen*` (regs, legalize, isel, codegen) · `BE/Cpu*` + `BE/Elf` · `BE/StdLib` + `BE/TestData`.

**Three entanglement zones.** (a) signature classification <-> push/pop conversion <-> live sets <->
register allocation (pinned registers, spilling); (b) Python <-> C++ under parity; (c) per-target
width: a32/a64 widen narrow kinds, a32 does it per function interleaved with conversion, x64 never.

**Test framework + template.** Make-driven golden programs (`BE/CodeGen*/Makefile_{py,cc}` `TESTS`),
run under qemu and diffed against `.golden`; plus `codegen_parity`. Template programs:
`BE/TestData/multiple_results.asm` (multi-value signatures, `print_*_ln`) and `indirect.64.asm`
(`lea.fun` + `jsr`). Harness template: the approved pick's `test.sh` (make targets wrapped as JUnit
testcases).

## 1. Title
Pass overflowing parameters in memory in the Cwerg backends

(8 words. Alternative if results make the core: "Support signatures larger than the register file in Cwerg".)

## 2. Shape classification
- Shape: **O-Pipeline-hard, twin implementation** (SHAPES.md § Pattern 12; same class as the accepted
  bcopy pick): a calling-convention extension through the shared lowering, three backends and the
  mandatory C++ mirror, observable only through programs run under qemu and py/cc text parity.
- Pass-rate target: 15-35% (affordable middle; Nova is locked, Orion 24 tokens/run).
- Best agent: Orion / Vega. Nova tends to ship Python only.
- Dominant verdict: WRONG OUTPUT / segfault at run time on one target (T1, T2), INTEGRATION (C++ twin).

## 3. Public surface (the IR; no host API)
- `.fun f NORMAL [outs] = [ins]` with any number of inputs up to the IR limit (64), in any mix of
  integer, address, code-pointer and floating point kinds, on every backend.
- `pusharg` / `bsr` / `jsr fp sig` / `poparg` call sequences and `poparg` / `pusharg` / `ret` in the
  callee, unchanged syntax.
- **Scope-up (after the core-slice precheck):** the same for results (`[outs]` beyond the result registers).
- Observable: stdout of programs under qemu from BOTH codegens on all three targets; `-mode normal`
  text identical between py and cc.

## 4. Canonical form
- Values arrive exactly as pushed, per kind: narrow kinds keep their low bits and sign as the IR
  defines; floats bit-exact.
- Signatures whose parameters all fit in registers compile exactly as today (no change in the text a
  codegen emits for them). This is the baseline-preservation rule and it is testable through parity
  of the repo's own programs.
- The in-memory convention itself is NOT specified (block pointer vs direct stack slots): both codegens
  must merely agree with each other and with themselves. Tests are behavioural + parity only.
- Recursion, calls in loops, several call sites with different overflow sizes, indirect calls: all
  work.

## 5. Blind-spot pre-empts
- Parallel implementation: "The Python and the C++ code generators must emit identical assembly text"
  (repo rule; approved precedent).
- Multiplicity / placement: "wherever such calls appear and however many times" (L26: this clause was
  load-bearing on bcopy).
- Baseline preservation: "a signature that fits keeps the code it gets today".
- Codebase-inferable (exactly one): the rewrite sequencing inside `PhaseLegalization`.

## 6. Description draft (meta.md body, ~180 words, frontmatter omitted)

Allow functions in the Cwerg backends for a32, a64 and x64 to take more parameters than the target has
argument registers. Today each backend's calling convention assigns integer and floating point
parameters to registers and stops with an assertion as soon as a class runs out: seven integer
parameters already fail on a32, and ten integer or eight floating point parameters fail on x64.

Any function may take up to the IR's limit of parameters, in any mix of integer, address, code and
floating point kinds, and be called directly or through a function pointer. Parameters that fit keep
the registers they get today, and a signature that fits entirely keeps exactly the code it gets today;
the remaining parameters are passed through memory. Every parameter arrives in the callee with the
value the caller pushed. This holds wherever such calls appear and however many times, including
recursion and calls inside loops.

The Python and the C++ code generators must emit identical assembly text. The repository's own tests
are run with `make tests` from the repo root; in this environment it stops at BE/ApiDemo, which needs
ARM cross compilers, and the C++ frontend build after that needs GCC 13.

(Rule-7 audit: no instance list of what overflows; the three numbers in paragraph 1 are the
reproduction, not the scope. Giveaway audit: no mention of spilling, block pointers, live sets,
reserved registers, float/int interplay.)

## 7. File footprint (sketched against the real tree; Python measured on the prototype)
| Action | Path | Raw delta | Meaningful est. | Reason |
|---|---|---|---|---|
| MODIFY | BE/Base/lowering.py | +70 | 55 | signature split helpers, tail offsets, `$argblock` stk, push -> `st.stk`, pop -> `ld`, rest pointer capture |
| MODIFY | BE/Base/lowering.cc + .h | +110 | 80 | mirror; new instruction lists instead of in-place `InsInit`, `StkNew`/`FunStkAdd`, interface change |
| MODIFY | BE/CodeGen{A32,A64,X64}/regs.py | +3x18 | 45 | per-target classifier returns memory slots + the rest register |
| MODIFY | BE/CodeGen{A32,A64,X64}/regs.cc + .h | +3x25 | 60 | mirror, incl. a32 D-pair logic |
| MODIFY | BE/CodeGen*/legalize.{py,cc} | +2x3x3 | 10 | interface wiring (`cpu_live_in` incl. rest register) |
| SCOPE-UP | results direction in lowering.{py,cc} + regs x6 | +100 | 75 | caller-provided result block, hidden pointer consumes an input register |
TOTAL: core ~250 human-effective across ~14 files; with results ~325. Calibration: the accepted bcopy
pick measured 690 over 19 files incl. a generated table; the hand-written part was ~375.
Floor check: >= 200 effective, >= 2 files — met by the core alone, with ~50 of buffer. If the reference
lands under 230, the results direction is the scope lever (genuine capability, not padding).

## 8. Solution outline (1+ helper per behaviour)
- `_SplitSignature(kinds) -> (slots, rest_reg)` per target: first try all-register; if anything
  overflows, redo with one GPR reserved and return that GPR as the rest register  <- "remaining
  parameters are passed through memory" + T2.
- `_TailOffsets(kinds, slots) -> (offsets, size)`: natural alignment per kind, declaration order.
- Caller (`_InsPushargConversionReverse`): at a call, extend the pending list with (reg|None, offset);
  memory slots become `st.stk $argblock off src`; the call becomes `lea.stk rest = $argblock 0; bsr/jsr`
  (list in REVERSE order for `FunGenericRewriteReverse`); `$argblock` sized to the largest tail in the
  function  <- "wherever and however many times".
- Callee (`FunPopargConversion`): memory slots become `ld dst = base off`, where `base` is a fresh
  virtual register copied from the incoming rest register as the function's first instruction (never
  load from the pinned register directly)  <- "every parameter arrives with the value pushed" + T1.
- `GetCpuRegsForInSignature` returns register params + rest register, so `cpu_live_in` protects it.
- C++: same, building replacement instruction vectors per block (`BblReplaceInss`) since the C++
  conversions mutate in place today.
No fixpoint, no recursion.

## 9. Test outline
Golden programs under `BE/TestData` (hex-suffixed names, e.g. `argspill_<hex>.64.asm` / `.32.asm`),
each compiled by py and cc for every target and run under qemu, plus py/cc `-mode normal` parity per
target. Goldens produced by an independent Python model (as the probes do), never by the reference.

Program A (`argspill`): 12 x U32 (a32 overflow); 26 x U32 (overflow everywhere, callee pressure);
mixed U32/R64 x 20; exact-fit GPR + FLT overflow per target (x64 9+8, a32 6+9 R64, a64 16+25);
narrow kinds U8/U16/S8 in the tail (callee defined before caller); A64/C64 pointers in the tail; the
same callee from two call sites with different overflow sizes; calls inside a counted loop; recursion
with changing tail values; indirect call through `lea.fun` + `jsr`; a function forwarding its own
overflowed parameters to another (x64/a64 program only, see § exclusions).
Program B (multiplicity): dozens of overflowing calls across branches/loops/helpers through the text
path (F-32 analog for the C++ twin).
Harness cases: per (impl x target) run vs golden = 6 per program; parity = 3 per program; base mode =
every existing make target (reuse the approved harness).
Atoms -> tests: each overflow class (GPR / FLT / both) per target; exact-fit boundary per target;
kinds; direct vs indirect; multiplicity; recursion/loop; baseline preservation (base mode + parity of
existing programs).

**Exclusions found by probing (L60/L61 — pre-existing base bugs the fixtures must NOT reach):**
- a32 cannot call a FORWARD-DECLARED function with narrow (U8/U16/S8/S16) parameters on base
  (`AssertionError: unexpected reg type: U8`): a32 widens per function interleaved with conversion,
  so the caller sees the callee's unwidened signature. Narrow tails on a32 only with the callee
  defined first. (Measured: `fwd_narrow.asm`, base, 3-param signature, a32 fails, x64/a64 pass.)
- a32's local allocator fails at >= 8 simultaneously live values in one block on base
  (`reg_alloc.py:178 assert tmp_reg is not CPU_REG_SPILL`). The forwarding shape exceeds it; keep it
  out of the `.32` program.
- x64 has no pattern for `conv U32 = R64` into a spilled destination on base. Accumulate floats in
  R64 and convert once, where pressure is low.

## 10. Forced kinds / bounds
None host-level. IR-level: the rest pointer is `A64` on a64/x64, `A32` on a32; offsets `S32`
(existing lowering convention); `st.stk` source may be a constant (`pusharg 7:U32`).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Evidence | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Loading the overflowed parameters straight from the pinned incoming register: once register pressure spills them, x64's spiller picks rax (also the 9th input register) as scratch and destroys the pointer | candidate new pattern (pinned incoming register clobbered by spill code); nearest F-30 (fix in a pass the agent never opened) | S4 machinery-riding | callee register pressure | #2 (same split decides which register carries the pointer) | **REPRODUCED:** probe1/probe2 x64 SIGSEGV with the natural variant, PASS with capture-first; a64/a32 unaffected | "Every parameter arrives in the callee with the value the caller pushed" | 26 x U32 and 12 x U32 callee cells on x64, py and cc |
| 2 | Floating point overflow with an exactly full GPR bank: the pointer to memory needs a GPR, so an integer that fits by count must also move to memory. The natural variant reserves a GPR only when integers overflow | F-15 boundary / A9 exact-fit | A9 | class interplay | #1, #4 | **REPRODUCED:** x64 9 U32 + 8 R64, silent wrong value (75526320) with exit 0 | "Parameters that fit keep ... the remaining are passed through memory" (the contract; the interplay is unstated) | exact-fit cell per target |
| 3 | C++ twin: conversions rewrite in place while iterating; the feature needs inserted instructions (pointer setup, capture) and a new stack object, with names and order identical to Python | F-32 / F-31 analog | A1 + S6 | dual implementation | #1, #2 | unmeasured (C++ not yet written); bcopy measured 2-3/10 on the analogous wall | "identical assembly text" | parity cases + cc run cases, multiplicity program |
| 4 | Baseline preservation: a signature that fits must keep today's code; implementations that route every call through memory or reserve the pointer register always change the text of every existing program | S3 | S3 | preservation | #2 (the reservation rule) | unmeasured; the parity of existing programs is the discriminator only if py and cc disagree, so add a golden-text check of one existing program | "a signature that fits entirely keeps exactly the code it gets today" | existing-program text golden per target (to be designed; must not pin anything the feature does not reach) |
| 5 (scope-up) | Results beyond registers need a caller-provided block whose pointer consumes an INPUT register, which can push a fitting parameter into memory | F-2 bidirectional | S2 | direction | #2 | unmeasured | results sentence (to write) | cells with overflowing results and fitting inputs |

Distinct axes: pressure / class interplay / twin / preservation / direction. Interdependence: 1-2-5
share the split; 3 mirrors all of them.
CONTRACT-STATED/FIX-HIDDEN: the sentences say values arrive intact, fitting signatures keep their code,
and both codegens agree. None names spilling, pinned registers, the pointer, or class reservation.
Not traps (probed, do not count): rest register missing from `cpu_live_in` (no effect when the address
is materialised right before the call); indirect calls (the natural classifier covers `jsr`
signatures for free); two call sites with different sizes (a max-sized block is the obvious design).

## 11b. Cross-product (F-10)
| | GPR overflow only | FLT overflow only | both |
|---|---|---|---|
| **a32** | 7+ U32 | 9 R64 with 6 U32 (exact-fit) | mixed |
| **a64** | 17+ | 25 FLT with 16 GPR (exact-fit) | 26 mixed |
| **x64** | 10+ | 8 R64 with 9 U32 (exact-fit) <- T2 | 20 mixed |
Second matrix: {direct bsr, indirect jsr} x {leaf callee, callee that itself makes an overflowing call}.
Every cell runs in py and cc.
Scope audit: "parameters" = inputs only in the core; results only after the precheck.
Tolerance / format-noun audits: n/a.

## 12. Tier + category
Olympus. Category: **feature-request** (net-new capability; today it asserts). Title verb "Pass".

## 13. Predicted pass rate
15-35%. T1 and T2 each killed the natural Python implementation in probing; the C++ twin carried
2-3/10 on the sibling pick; bcopy's walls took it to 0/10 before its fairness rounds, so the risk is
the LOW side: keep the first batch's fixtures inside what the contract states and what base supports
(§ 9 exclusions), and hold the results direction until a batch says the rate is soft.

## 14. Quality-gate checklist
- [x] Repo understanding 5/5 (§ 0, plus the approved pick's § 0)
- [x] Existing PR / publicly-solved check: see hunt log (issue #3 is the maintainer's own, no PR, no
      branch, no commit; corpus grep empty). Cross-repo textbook check: calling conventions are
      universal compiler machinery; the accepted bcopy precedent (memcpy loops) passed the scope gate
      on Cwerg-integration grounds. **Step 4b core-slice precheck is MANDATORY before any scope-up.**
- [x] Closest approved opened as scaffolding: cwerg-bcopy-bzero-lowering (same repo, harness, Docker)
- [x] Title verb-led, 8 words
- [x] Shape declared
- [x] Surface listed (IR; no host API)
- [x] Canonical form (§ 4)
- [x] Exactly one codebase-inferable requirement (sequencing inside PhaseLegalization)
- [x] Description ~180 words, no headers/labels
- [x] Footprint sketched against real files, Python part measured on the prototype
- [x] >= 200 effective with buffer (core ~250)
- [x] Helpers 1:1 with sentences
- [x] Test outline + exclusions from probing
- [x] Traps with F-ids, two REPRODUCED on base, distinct axes, interdependence marked
- [x] § 11b filled
- [x] Sibling-API (F-20): n/a. Unobservable interface (F-21): n/a. Absent key (F-24): n/a.
- [x] Twin-parity scope (L60): three pre-existing base defects found and excluded before writing tests
- [x] Cold build < 600 s (L62): inherited Dockerfile, 413 s measured on the sibling pick
- [x] In-process validation (L56): qemu + the repo's own tools only, as the accepted pick
- [x] Unbounded-promise audit: "up to the IR's limit" is bounded (64); no iteration promise
- [x] Predicted Wrong Logic < 25%; predicted pass <= 40%
- [x] Category matches (feature-request)
- [x] Not pattern-followable (no memory-passed parameter exists anywhere in the tree)
- [ ] OWED: Requirement 0 picker check (user)
- [ ] OWED: reproduce T3 once the C++ half exists; decide T4's discriminator without pinning unrelated text

## Why this is not a duplicate
Closest: our own accepted `cwerg-bcopy-bzero-lowering` (same repo, same `lowering`/`legalize` files,
different capability: bulk-memory opcode lowering vs the calling convention in `regs`). No recorded
reject for file overlap without capability overlap; the precheck will say. Derivative sentence:
"extends each Cwerg backend's poparg/pusharg calling convention so overflowing parameters travel
through memory, in Python and C++ with identical output" — needs repo nouns. Risk MEDIUM (an outsider
can say "stack-passed arguments").

## Predicted iteration cycles: 3
(Precheck on the core slice; one fairness round on the preservation sentence; one on T3's fixtures.)
