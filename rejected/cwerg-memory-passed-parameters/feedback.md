# feedback.md — cwerg-memory-passed-parameters

## Summary

Repo: robertmuth/Cwerg (Python spec + C++ port compiler, Apache-2.0, ★705). Base
3bc94f7c1c26834f98c614aef51b5aa7370615d9 (same as the accepted cwerg-bcopy-bzero-lowering).
Pick source: hunt 2026-09-18 (proven pool, maintainer roadmap issue #3). Tier: Olympus.
Category: feature-request.

## Status

**SHELVED 2026-09-19 — DERIVATIVE.** Scope gate re-run returned an overlap `Blocker` (older foreign
submission implementing issue #3 as a C++-only a64/x64 signature-rewrite pass; 72/163 of its lines =
44.2% correspond). Not contestable. Case study: `Instructions/TOO-EASY.md`. Everything below is history.

**R3 VALIDATED (2026-09-19). Batch 1 read 0/11; test-only R3 suite replays 1/11. Next: platform
Re-eval (only test.patch + solution.patch changed).** Requirement 0 confirmed (picker: eligible, Apache-2.0).

## Evidence gathered at design time

- F2P on base via the real CLI: a32 `IndexError` at 7 x U32; x64 `too many gpr args` at 10 x U64,
  `too many float args` at 8 x R64.
- Python prototype (`worktrees/_cwerg_mpp/prototype-py-probe.patch`) passes probe1 + probe2 on all
  three targets under qemu in `cwerg-dev:base`.
- T1 reproduced: loading overflowed parameters from the pinned incoming register segfaults on x64
  under register pressure (spill scratch = rax = 9th input register).
- T2 reproduced: reserving the pointer GPR only on integer overflow gives a silent wrong value on
  x64 for 9 U32 + 8 R64.
- Pre-existing base defects to keep OUT of fixtures (L60/L61): a32 forward-declared narrow-param
  calls; a32 local allocator at >= 8 live values in one block; x64 `conv U32 = R64` into a spilled dst.

## Core slice (R1, 2026-09-18) — built for the Step 4b scope-gate precheck

Inputs only; results keep asserting ("too many results"). 10 source files, **325 human-effective**
(hook). Reference: per-target `SplitInSignature` (py + cc) returns a null/None slot for each
overflowing parameter and, when anything overflows, reserves the next free GPR for the address of
the caller's `$param_mem` stack region; caller stores with `st.stk`, `lea.stk` right before the
call; callee copies the incoming address into a scratch register as its first instruction and
loads with `ld`. `GetCpuRegsForInSignature` (live-in) = register params + that GPR.

Two pre-existing twin divergences fixed in the reference because the feature's own inputs reach them
(L60): x64 C++ used 8 float parameter registers vs Python's 7 (C++ now follows Python), and the a32
C++ immediate matcher called `ConstValueInt64` on a float constant store (a pushed float constant
that goes to memory). Base reproduction of the latter: `st.stk buf 0 = 96.0:R64` aborts a32 cc.

Tests: 4 golden programs (`argmem_43df76.{32,64}`, `argflow_43df76.{32,64}`), goldens from the
independent model in `worktrees/_cwerg_mpp/gen_tests.py`; new mode = py run + cc run + parity per
program per target = 18 cases, all 18 fail on base with the register-exhaustion assert.

**Pre-existing base defects the fixtures deliberately stay clear of (L60/L61), all reproduced on base:**
1. a32 forward-declared callee with narrow params: `unexpected reg type: U8`.
2. a32 local allocator: >= 8 values live in one block (no local spilling) — shapes kept small on .32.
3. a32 py vs cc global allocation of R64 values live across calls (28-line parity diff on base).
4. a32 int->float conversion inside a loop: allocator failure.
5. S16 vs U16 widening order differs py vs cc (a32 and a64) — no S16 with U16 in fixtures.
6. x64 `conv` into a spilled destination / same xmm register: no isel pattern.

## Attempt history

| Round | Date | Change | Result |
|---|---|---|---|
| 0 | 2026-09-18 | DESIGN.md + probes | T1, T2 reproduced; 3 exclusions found |
| 1 | 2026-09-18 | Core slice: reference py + cc, 4 programs, test.sh, Dockerfile (approved pick's), meta.md | scope gate PASSED (0/310 overlap); Auto Review: Desc 3/3, Tests 1/3, Solution 1/3 |
| 2 | 2026-09-18 | A32 + C++ A64 two-pass legalization, C++ 64-param parser fix, argedge + argleaf programs, structural memory check, meta.md edits (user) | validated clean; ready for Auto Review re-run |

## Validation record (R1 core slice, clean clone at base + test.patch, image from the submission Dockerfile, uid 1000, --network none)

| Check | Result |
|---|---|
| new mode on base | 18/18 fail, every one on the register-exhaustion assert (py IndexError/assert, cc `too many gpr regs`) |
| new mode with solution | 18/18 pass, 3 runs identical |
| base mode with solution | 122/122 pass x3, per-case identical (same count as the accepted pick) |
| patch order | sol->test, test->sol, reverse: all clean, 19 paths, hunks verified |
| effective LOC | 325 human-effective, 10 files |
| meta.md | ASCII, 203 words, Commit byte-identical to BASE_COMMIT.txt |

## Mutation battery (design traps reproduced against the shipped tests, `worktrees/_cwerg_mpp/mutate.py`)

| Mutation | Result |
|---|---|
| M1 callee loads from the pinned incoming register (T1) | x64 SIGSEGV py + cc in both programs; a64/a32 pass (x64-only wall, as designed) |
| M2 address GPR reserved only on integer overflow (T2) | py wrong value on x64, a64, a32 (argmem exact-fit cells) + parity |
| M3 C++ x64 keeps 8 float registers | parity DIFF, and cc WRONG value in argflow (xmm8 miscompiles: the pre-existing divergence was a latent C++ bug) |
| M4 a32 C++ float-constant immediate fix reverted (T5) | a32 cc compile abort |
| M5 address register missing from callee live-in | equivalent mutant (address materialised right before the call), not a trap |

T4 (baseline-preservation sentence) was dropped from meta.md: untested, so FP exposure (L53).

## R2 (2026-09-18) — scope gate PASSED (0/310 overlap); Auto Review revision round

Scope gate: Low overlap against two same-path candidates (our own bcopy pick and another), 0/310
authored lines; no public implementation in repo, PRs, branches, forks. Auto Review: Description 3/3,
Tests 1/3, Solution 1/3. Findings and what R2 did:

| Finding | Action |
|---|---|
| A32 py + cc: forward call to a later callee with narrow overflowing params aborts (per-function widening before call conversion) | Split A32 legalization into Step1 (shift limit + widening for ALL funs) / Step2 (py + cc), as A64 py already does. Found C++ A64 ran Step1+Step2 in ONE loop (same latent bug) and split it too. New `argedge` program: main first, implicit forward refs, narrow tail, direct + function pointer |
| Memory transport not discriminated (expanded-register convention passes) | New `argleaf` program + `params.memory` cases (py/cc x 3 targets): the leaf `sumint` must contain a real load (any base, epilogue pops excluded) in the final assembly. Mutation M6 (widened A32/A64 register sets) passes all execution tests and FAILS this check on a32 + a64 |
| One-over result capacity not rejected | User removed the "Results are unchanged" sentence from meta.md (review feedback), so no test: it would pin unstated behaviour |
| 64-parameter boundary untested | `max64` in `argedge`: exactly 64 params, interleaved kinds, code pointer last, called through a function pointer. Found a pre-existing C++ parser off-by-one (`PopulateSig` accepted only 63): fixed in serialize.cc |

meta.md edits from the user (review feedback): diagnosis condensed to "Currently, calls fail once an
argument-register class is exhausted."; results sentence removed. Now 157 words.

**More pre-existing base defects found and kept out of fixtures (L60):**
7. a32 PYTHON global allocator ignores incoming float parameter registers when those params become
   globals: base program with [U32 R64 U32 x4 R32 R64 R32 R64 R32 R64 R32] and a 2-block body prints
   2624478 in py vs 3468 correct in cc. The a32 `max64` therefore carries no float kinds (float
   overflow on a32 is covered by argmem/argflow).
8. C++ parser: EXTERN declaration later defined with a non-empty result list asserts
   (serialize.cc:54, tokens indexed without the bracket). Fixtures use implicit forward references.
9. a64 local allocator fails with many UNUSED float params (24, all fitting) — leaf callees use all.
10. C++ parser accepts out-of-range constants (`257:U8`) that py rejects — not reached.

R2 solution: 14 files, 340 human-effective. Tests: 8 programs, 42 new cases (36 run/parity + 6
structural).

R2 clean-room validation (fresh clone + test.patch, image from the submission Dockerfile, uid 1000,
--network none): new-on-base 42/42 fail (register exhaustion, narrow forward call, C++ "too many
args" at 64); with solution new 42/42 x3 identical, base 122/122 x3 identical; patch order both ways
+ reverse clean (31 paths). Mutations M1-M4 and M6 all killed on the R2 suite.

## R3 (2026-09-19) — batch 1 read 0/11; test-only fixes for re-eval + Auto Review notes

Auto Review (R2 artifact): **Approved with notes** (Desc 3/3, Tests 2/3, Solution 3/3; notes: memory
check gives no diagnostic on failure; backend READMEs still list the feature as TODO). Solution
Quality: PASS. Then batch 1 (8 Nova, 1 Orion, 2 Vega): **0/11** (table in eval-results.md).

Diagnosis from the saved runs (`agent-runs/1`), replaying each agent's actual patch in the platform
image:

| Cluster | Runs | Verdict |
|---|---|---|
| A: a32 (and a64 C++) forward call to a later callee with narrow params | 10/11 | **Unfair (L60).** Base fails it with 3 params and no overflow; the meta never states definition order. Cells removed: `argedge` now defines callees before `main`. The reference keeps the fix (Auto Review R1 asked for it) |
| C: `mix20` on a32 | 8 of 9 a32 failures | **Unfair.** a32 local allocator cannot spill (base fails at 8 live values in one block); 20 simultaneously live params sit past it and the reference only fits incidentally. Replaced by `mix14` |
| E: `fwd20` on a64 | 3/11 | **Unfair**, same class (a64 allocator). Forwarding now passes the received values on unchanged with 17 params (minimum a64 overflow). At 17 the one remaining failer hits its own `gpr16` boundary bug |
| B: C++ parser rejects exactly 64 params | 9/11 | **Fair.** "up to the IR's limit", MAX_PARAMETERS = 64 in the repo. Kept |
| D: x64 xmm8 (agents copied C++'s 8 float regs into Python) | 6/11 | **Fair**, misdirecting: xmm8 is clobbered across calls, the loop's 2nd iteration prints 13460 not 8400 (same value as mutation M3). Kept |
| T5: a32 C++ float-constant store | 3/11 | Fair (designed). Kept |

Also fixed (re-eval eligible, no solver-visible change): `run_memory_check` prints the expected load
and the `sumint` body when no load is found; the three backend READMEs describe memory passing
instead of the TODO. Solution: 17 files, 349 human-effective. meta.md unchanged.

**Local replay of all 11 batch-1 solutions against the R3 suite: 1/11** (Vega #2 passes 42/42 with a
clean baseline; Vega #1 fails only D; Nova #8 fails only B). Next step: platform **Re-eval** (test.patch
+ solution.patch changed only), not a fresh batch.

FP note for the passer (Vega #2): its only batch-1 failures were the three removed cells (A on a32
py and a64 cc, C on a32). A and C both reproduce on base without the feature.

R3 clean-room validation (fresh clone + test.patch, submission Dockerfile, uid 1000, --network none):
new-on-base 42/42 fail; with solution new 42/42 x3 identical, base 122/122 x3 identical.
