# DESIGN - avo register spilling, reservation and pinning

## 1. Title

Spill registers to the stack instead of failing allocation (mmcloughlin/avo, Go, MIT, 2986 stars, base `16419356370fdbe6f006c6d4521bdb2c660f9411`, default branch last commit 2026-07-01).

## 2. Shape

O-Pipeline-hard. A compiler back end pass gains a capability that every later pass, the printer and the Go assembler all have to keep agreeing with. Difficulty lives in DOING (rewriting a function while control flow, liveness, register forms and the frame all stay consistent), not in KNOWING.

## 3. Why this pick

- avo is absent from the whole local corpus (`problems/`, `rejected/`, `Aprroved/`, `Olympus/problems/`) and from every scouted repo list. No compiler back end / register allocation pick exists anywhere in it.
- No public PR or issue implements spilling. Open PRs touching the same area (#481 liveness, #480 MarkUndefined, #488 arm64 printer stack-slot promotion) do not implement the central capability: #488 works in the printer on slots that already exist, in the opposite direction (slot to register), for arm64 lowering only.
- Invented, not a spec: nothing external defines what avo's allocator should do under pressure, so there is no reference to port and no cross-corpus spec name to collide with.
- **The anti-ratchet property**: correctness is checked by executing the generated assembly. The prompt states one invariant ("compute exactly what it would have computed"), and every implementation strategy that satisfies it passes. Fairness rounds cannot convert this difficulty into specification text, which is what killed mapcidr-allocation.

## 4. Public API surface

- `build.Reserve(rs ...reg.Register)`, `(*build.Context).Reserve`, `(*ir.Function).Reserve(rs ...reg.Register) error`
- `build.Pin(v, p reg.Register)`, `(*build.Context).Pin`, `(*ir.Function).Pin(v, p reg.Register) error`
- `ir.PinnedRegister{Virtual, Physical reg.Register}`, `ir.Function.Reserved`, `ir.Function.Pinned`
- `(*pass.Allocator).AddRegister(r reg.Register)`, `(*pass.Allocator).Assign(v, p reg.ID) error`

Only the two build package helpers are required by the prompt and exercised by the tests; the
`Context` and `ir.Function` methods and the `pass.Allocator` additions are how the reference
wires them and are free for a solver to arrange differently. Spilling itself needs no API: it is
a behavior change in `pass.AllocateRegisters`.

## 5. Canonical observable form

Generated Go assembly, verified by assembling it and running it. Numeric results are the primary assertion; the frame directive (`$0-16` versus a non-zero frame) and the physical registers named in the body are the secondary ones. No test asserts an instruction sequence, so any spilling strategy is accepted.

## 6. Trap matrix (all reproduced on the natural-but-wrong implementation while building the reference)

| # | Class | Trap | Symptom when missed |
| - | ----- | ---- | ------------------- |
| 1 | S3 baseline preservation | `pass.CFG` appends to `Succ`/`Pred`; re-running it after inserting reloads doubles the edges, liveness explodes and allocation never converges | "failed to allocate registers" after spilling everything, no hint that the CFG is the cause (hit during development) |
| 2 | S4 machinery riding | Reloads inserted before an instruction that a label targets; `LabelTarget` must be recomputed or the jump skips the reload | wrong results only in loops and branches |
| 3 | S2 composition | A virtual general purpose register referenced at 8, 16, 32 and 64 bits: the slot access has to match the form of each reference, and the high byte form lives at offset 1 | wrong results only in the mixed width and high byte scenarios |
| 4 | A4 host semantics | Physical registers have no form at every width (R12 has no high byte); a temporary reloaded into one dies in `VerifyAllocation` | "non physical register found", pointing away from allocation |
| 5 | S4 machinery riding | Kinds other than general purpose: vector 128/256/512 and opmask registers need their own move opcodes and slot sizes; aligned moves fault on an 8 byte aligned frame | assembler rejects the code, or a fault at run time |
| 6 | S2 composition | Spilled register used as the base or index of a memory operand; two spilled operands in one instruction; a spilled register both read and written | silently wrong values, or an instruction the assembler rejects |
| 7 | S5 dual path | Reserving and pinning both change what the allocator may hand out, and a pinned virtual must not be re-allocated by the normal loop | pinned value clobbered under pressure (hit during development) |
| 8 | Termination | Temporaries introduced by spilling must never themselves be spill candidates | infinite loop or exponential frame growth |
| 9 | Baseline | A function that does not need spilling must not gain a frame | `TestNoSpillHasNoFrame` |

## 7. File footprint (reference solution)

| File | raw + | human-eff |
| ---- | ----- | --------- |
| pass/spill.go (new) | 290 | 172 |
| pass/reg.go | 107 | 55 |
| pass/alloc.go | 62 | 34 |
| ir/ir.go | 54 | 25 |
| build/context.go | 16 | 6 |
| build/global.go | 6 | 2 |
| **total** | **614** | **337** |

Above the 250 sprint floor, 6 files, well above the 2 file floor.

## 8. Solution outline

`AllocateRegisters` becomes a loop: attempt allocation; on a pressure error (a sentinel raised only when a virtual has no candidate register) pick a spill candidate for that kind, rewrite the function, recompute label targets, control flow and liveness, and retry. The rewriter gives each spilled virtual a stack slot sized to its widest reference, and replaces each referencing instruction's use with a fresh temporary, preceded by loads of every form read and followed by stores of every form written. The allocator learns the set of forms each virtual is referenced at and only offers physical registers that have all of them, which is what makes high byte spilling work. Reservation filters the physical register list per kind; pinning pre-assigns an allocation entry and is skipped by both the spill candidate search and the normal allocation loop.

## 9. Test outline

81 tests in `tests/spill5f34af/`. Three build-tag-ignored generator programs (spill, reserve, pin) each build one scenario selected by an environment variable; the test harness runs the generator with the avo under test, drops the generated assembly and stubs into a throwaway module, and runs it. Splitting the generators means a missing `Reserve` or `Pin` only fails the tests that need it. Scenarios that need AVX2 or AVX-512 are executed only where the host advertises the extension, checked through `golang.org/x/sys/cpu`; nothing is ever skipped, because the assembly and frame assertions run everywhere. The AVX-512 scenarios also generate a reference function that computes the same thing without spilling and assert the two agree, so no expected value depends on an instruction set this machine cannot run. The SSE-executed vector scenarios reserve X16-X31 so that no EVEX encoding is emitted.

## 10. Fairness

Two AI pre-checks were run and addressed (see feedback.md): the description was trimmed to the
public build API only, and the pinned "never spilled" guarantee plus the byte forms of a
reserved general purpose register are now asserted. Every assertion traces to a sentence in meta.md: the values to the "compute exactly what it would have computed" invariant, the frame checks to the "no stack frame allocated for it" sentence and to spilling into the frame, the register checks to the reservation and pinning paragraphs, and the conflict test to the last sentence about two pinned values. Nothing pins an instruction sequence, an error message, a spill count or a strategy: frame
checks only ever require room for one value of the kind that had to spill. The one codebase-inferable requirement is that each control is exposed both as a build context method and as a package-level helper, which is how every other helper in the build package is shaped.

## 11. Predicted difficulty

Solvable (the reference is 292 effective lines) but heavily trapped: nine interdependent traps, of which the CFG re-entrancy and the pinned re-allocation bugs both bit the reference implementation during development, and both surface as misdirecting failures. Expect a low pass rate; the batch is the oracle.

## 12. Validation

Docker matrix built from `git archive BASE` plus the deliverable Dockerfile, run offline as uid 1000:

| State | base mode | new mode |
| ----- | --------- | -------- |
| BASE + test.patch | 13176 tests, 0 failures, 0 skipped | 81 tests, 81 failures |
| BASE + test.patch + solution.patch | 13176 tests, 0 failures, 0 skipped | 81 tests, 0 failures |

Patches apply cleanly in both orders. Three consecutive runs of each mode give identical counts.

## 13. Risks

- Register allocation is a textbook topic; the pick relies on the integration surface (avo's IR, passes, register forms, frame) rather than the algorithm for difficulty.
- An instruction pairing a high byte register with a REX register is invalid and the Go
  assembler mis-assembles it silently. avo does not model that constraint, so the high byte
  scenarios keep the interacting operands in legacy registers rather than requiring a solver to
  handle it.
- Base mode excludes four packages that skip themselves depending on the host (AVX-512 or
  network). The platform wrapper treats a skip as a non-passing regression test, which is what
  forced this; none of the four covers register allocation.
- The harness shells out to the Go toolchain. It needs no network and no module downloads beyond what the image already has, but it is heavier than a normal unit test (about 6 seconds for the suite once the image is warm).

## 14. Status

Built and validated. No platform batch yet.
