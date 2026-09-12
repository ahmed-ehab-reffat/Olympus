# eval-results - avo-register-spilling

No platform agent runs yet. This records the local validation the first batch will be measured
against.

## Local validation matrix (2026-07-27)

Each state built from `git archive 16419356370fdbe6f006c6d4521bdb2c660f9411` plus the
deliverable Dockerfile, image built on `olympus-base-go:latest`, containers run with
`--network none --user 1000:1000`.

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | 13176 tests, 0 failures, 0 skipped, exit 0 | 81 tests, 81 failures, exit 1 |
| BASE + test.patch + solution.patch | 13176 tests, 0 failures, 0 skipped, exit 0 | 81 tests, 0 failures, exit 0 |

Patch application: `test.patch` then `solution.patch`, and `solution.patch` then `test.patch`,
both clean.

## Flakiness

Three consecutive runs of each mode against the solution image:

| Run | base | new |
| --- | ---- | --- |
| 1 | 62 suites, 0 failures, 0 skipped | 81 / 0 failures |
| 2 | 62 suites, 0 failures, 0 skipped | 81 / 0 failures |
| 3 | 62 suites, 0 failures, 0 skipped | 81 / 0 failures |

The suite has no timing, randomness, ordering or network dependence. It shells out to the Go
toolchain twice per scenario, both offline.

## Host feature coverage

Measured in the base image: AVX2 present, AVX-512 absent. The YMM scenarios therefore execute and
compare against their non-spilling references; the ZMM and opmask scenarios are generated,
assembled and frame-checked but not executed. Every scenario that needs an extension is gated, so
this changes coverage depth, never determinism. `TestWideSpillSlotsPreserved` closes part of that
gap without executing anything: it checks slot store and reload symmetry in the generated assembly
for the ZMM, Opmask, YMM and Vector scenarios.

## Excluded from base mode

Verified by count: `go list ./...` yields 67 packages, base mode keeps 62, exactly 5 are excluded
(the new package plus the four below).

`examples/md5x16` and `tests/alloc/zeroing` skip themselves without AVX-512;
`internal/github` and `tests/thirdparty` skip themselves without network access. The wrapper
counts a skipped test as not passing, so base mode leaves those four packages out. None of them
exercises register allocation on a host that cannot run them.

## F2P detail (base run)

All 81 tests fail. Twelve fail because allocation still gives up under pressure
("failed to allocate registers"); the rest additionally cannot generate their scenario because
`Reserve` or `Pin` do not exist yet.

## Effective LOC

`effective_loc_check.py solution.patch`: raw added 614, human-effective 337, 6 files.

| File | raw | human-eff |
| ---- | --- | --------- |
| pass/spill.go | 290 | 172 |
| pass/reg.go | 107 | 55 |
| pass/alloc.go | 62 | 34 |
| ir/ir.go | 54 | 25 |
| build/context.go | 16 | 6 |
| build/global.go | 6 | 2 |

## Test inventory

77 tests: 59 assert values computed by executing the generated assembly (general purpose
spilling at four widths, high and low byte forms, 32 bit zero extension, loops, branches,
memory base and index operands, two spilled operands in one instruction, copy chains, 128 bit
vectors, vectors across a loop, reservation, reservation with an explicit use, pinning, pinned
vectors, pinning onto a reserved register, reservation across the forms of one register,
pinning a value referenced at three widths, pinning two values with disjoint live ranges to one
register, two functions built in one context so that reservations and pins cannot leak between
them, reserving nothing, reserving a narrow form of a register, and one function that spills
both general purpose and vector values at once), 13 assert frames and the physical registers named
in the generated code, 3 assert that the wide vector and opmask scenarios spill into a frame
wide enough for the kind that spilled, including pinned YMM, ZMM and opmask scenarios. Wide
scenarios are executed where the host advertises the extension (checked through
`golang.org/x/sys/cpu`, never skipped); the AVX-512 ones compare against a reference function
that computes the same thing without spilling rather than against a constant. 1 test asserts that a pinned value never reaches the stack while the rest
of its function does spill.

## Batch 1 (2026-07-28, 3x Nova/Nova) - 0/3, INVALID as a difficulty reading

| Run | Solver | Verdict | Msgs | LOC | Files | Failed tests | Approach note |
| --- | ------ | ------- | ---- | --- | ----- | ------------ | ------------- |
| 1 | Nova | FAIL_MISSED_REQUIREMENT | 104 | 931 | 7 | 53 of 65 (52 compile, 1 unaligned frame) | full spiller; `Reserve(...reg.Physical)`, `Pin(reg.Virtual, reg.Physical)` |
| 2 | Nova | FAIL_INTEGRATION_ERROR | 83 | 776 | 9 | 53 of 65 (same shape) | same narrow signatures |
| 3 | Nova | Test Mismatch (env blocker: verifier) | 83 | 790 | 8 | - | same narrow signatures |

Baseline was green in every run (6588 tests). No run was flagged agentBlameUnfair, and both
graders rated the task "challenging" with a clear description and deterministic tests.

**Why this batch does not measure difficulty.** All three agents declared the two new controls
with narrow static types, `Reserve(rs ...reg.Physical)` and `Pin(v reg.Virtual, p reg.Physical)`.
The hidden generators passed `[]reg.Register` slices and, in three scenarios, a register in the
"wrong" position on purpose. Against a narrow signature none of that compiles, so 52 of 65 tests
died at `go build` before exercising any behavior. That is the compile-wipe hazard in
FAILING-PATTERNS C-5: an unstated API shape collapses the pass rate for a reason unrelated to the
task. 12 of 65 passing therefore says nothing about how much of the allocator work they got right.

The one genuine defect visible through the wipe: run 1 emitted an unaligned 22-byte frame from
byte-width spill slots, which the assembler rejects. That is a real trap and it stays.

**Fix applied (R25), tests only.** The suite is now signature-agnostic:

- No variadic slice splats. `Reserve(upperVectors...)` became a helper that names the sixteen
  registers explicitly, and the one `[]reg.Register` reservation set was inlined. Individual
  `reg.Physical` values satisfy both `...reg.Physical` and `...reg.Register`.
- Dropped the three scenarios that could only be written against a wide signature
  (`ReserveVirtual`, `PinToVirtual`, `PinFromPhysical`). With a narrow signature those misuses are
  impossible by construction, which is a better outcome than a test that dictates the signature.
  The remaining validation scenarios pass physical registers (pseudo, restricted, wrong kind), so
  they compile either way.

Verified by narrowing the reference implementation's own signatures to exactly what the agents
wrote and re-running: all three generators compile and 65 of 65 tests pass. Both API shapes are
now accepted, so the next batch measures the allocator work rather than a naming coin flip.

## Batch 2 (2026-07-28, 10 agents) - 2 of 10 pass

Auto Review reports the batch as "hard but solvable": 2 of 10 completed the task, and the other
eight reached real allocator behaviour and failed on substantive edge cases rather than
infrastructure. Failure clusters, as reported:

| Failure | Runs | Character |
| ------- | ---- | --------- |
| narrow and high byte spill slots sized literally, leaving a frame the assembler rejects (`asm: unaligned stack size 9`) | 6 | subtle but fair |
| spill temporaries allowed into a physical register named by a live pin (`pinned register R14 spilled in Pinned`) | 4 | partly my defect, see R29: the pinned value died before the pressure region, so the check could fail a correct implementation. Scenarios now hold the pin to the last instruction |
| width handling and spill strategy broken across several pressure cases: mixed-width panics, AVX-512-only moves in ordinary vector scenarios, `SIGILL`, and a 9m21s non-terminating SlotLayout | 1 | genuinely hard |
| zero-width pseudo register accepted by Reserve (64 of 65 otherwise) | 1 | subtle but fair |

The compile-wipe that invalidated batch 1 is gone: every run reached behavioural failures.

Rubric bands: Description 3/3 clean, Solution 3/3 clean, Tests 1/3 with a single high-severity
finding, fixed in R28 below.

## Batch 3 (2026-07-28, 9x Nova + 3x Orion at 77 tests) - 0 of 12

| Run | Solver | Verdict | New tests failed | Dominant cause |
| --- | ------ | ------- | ---------------- | -------------- |
| 1-9 | Nova | FAIL_MISSED_REQUIREMENT | 8, 11, 11, 14, 16, 29, 33, 34, 34 | unaligned frame in every run; several also accept unassignable reserve targets |
| 10 | Orion | FAIL_MISSED_REQUIREMENT | 6 | Reserve skips the allocatable check; unaligned frames (251, 9) |
| 11 | Orion | FAIL_MISUNDERSTOOD_TASK | 11 | rejected pinning to a reserved register, which the prompt allows; mixed-width virtuals panic |
| 12 | Orion | FAIL_MISSED_REQUIREMENT | 10 | unaligned frames (105, 131, 21, 13, 235); Reserve skips the allocatable check |

Baseline green in all twelve. Every eval rated the task challenging, description clear, tests
deterministic, no unfair flag. Orion is the better profile here: its best run failed six tests
against Nova's best of eight, and its failures collapse into two causes rather than a spread.

Two causes dominate:

1. **Unaligned stack frames, 11 of 12 runs.** Agents call `AllocLocal` with the exact byte extent
   of a value and never pad, so byte and word spills or an odd-sized existing local produce frame
   sizes the Go assembler rejects: 9, 13, 14, 21, 22, 105, 131, 203, 235, 251. One eval explains
   why it is invisible to them: "Its single runtime smoke test used only 64-bit GP spills, which
   naturally produced an aligned frame and did not expose the layout bug."
2. **Reserve does not reject unassignable targets, all three Orion runs.** Each applies its
   allocatable check to Pin and not to Reserve.

## Batch 4 (2026-07-28, 2x Orion + 4x Nova, after the R44 prompt fixes) - 0 of 6

| Run | Solver | New tests failed | Dominant cause |
| --- | ------ | ---------------- | -------------- |
| 1 | Orion | 6 | rejects pinning to a reserved register |
| 2 | Orion | 6 | same |
| 3 | Nova | 28 | pins not honoured under pressure |
| 4 | Nova | 29 | pin semantics incomplete, includes the reserved-pin rejection |
| 5 | Nova | 10 | six from the reserved-pin rejection |
| 6 | Nova | 4 | unaligned frames |

The R44 clauses moved the needle. Unaligned frames dominated 11 of 12 runs in batch 3 and appear in
2 of 6 here, and no run failed on unassignable reserve targets at all. Both restored sentences are
doing their job.

The new dominant cause is the opposite of a missing requirement: four of six runs implement a rule
the prompt explicitly rules out, rejecting a pin whose target is also reserved. Two Orion runs fail
on nothing else, 71 of 77 with all six failures reporting "cannot pin to a reserved register". Every
eval marks it mentioned in the description, one calling it "especially clear in the prompt".

Best runs are now 73 and 71 of 77, against 69 in batch 3.

## Batch 5 (4x Nova, after the R48 easing) - 3 of 4 passed

75 percent against a 40 percent ceiling, a too-easy reject. Dropping the reserve-plus-pin
requirement in R48 plus the R44 and R47 clauses removed all three causes that had been failing
runs. Re-hardened in R55 by requiring stack slots to be shared between values that are not live
together, measured at 392 bytes without reuse against 176 with.

## Per-agent results (batch 6, pending)

| Run | Solver | Verdict | Msgs | LOC | Files | Failed tests | Approach note |
| --- | ------ | ------- | ---- | --- | ----- | ------------ | ------------- |
| - | - | - | - | - | - | - | pending |
