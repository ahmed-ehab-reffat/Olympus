# eval-results.md — cwerg-bcopy-bzero-lowering

## Batch 2 (2026-09-12) — 10x Nova + 1x Vega — **0 / 11 PASS** (batch 1 was 0/10; 0/21 overall)

| Run | Failed / 14 | bulkshapes.parity | Everything else |
|---|---|---|---|
| Nova 10 | **3** | 3 | **none** |
| Nova 2, 3, 5, 6, 7, 9, Vega | 4 | 3 | `bulkmem.c/opt` |
| Nova 1, 8 | 5 | 3 | `bulkmem.parity` a64 + x64 |
| Nova 4 | 6 | 3 | `bulkmem.parity` a64 + x64, `bulkmem.c/opt` |

### Per-test kill counts
| Test | Killed |
|---|---|
| `bulkshapes.parity` a32 | **11 / 11** |
| `bulkshapes.parity` a64 | **11 / 11** |
| `bulkshapes.parity` x64 | **11 / 11** |
| `bulkmem.c/bulkmem_e30b83.64.opt` | 8 / 11 |
| `bulkmem.parity` a64 | 3 / 11 |
| `bulkmem.parity` x64 | 3 / 11 |
| every other case (py/cc runtime on all 3 targets, plain C) | **0 / 11** |

### The rounds 9-10 description changes WORKED
Batch 1: the runtime cases (`bulkmem.py`, `bulkmem.cc`) killed 2-5 runs each. Batch 2: **0 of 11**.
Stating the multiplicity and narrow-width semantics fixed exactly what it was meant to fix. Fairness
verdicts unanimous again: `difficulty=challenging`, `agent_blame_unfair=False`, `description_clear=True`
on all 11.

### The wall is `bulkshapes`, a parity-ONLY program I added for coverage breadth
It kills 11/11 and is the ONLY thing standing between this submission and the band. Diagnosed against
the near-miss run's own build (Nova 10 fails NOTHING else):
- **x64** diverges on the typed constants (`0x80000000:S32`, `0x100000000:S32`, ...). Removing them ->
  PARITY-OK.
- **a64 and a32** fail in the Python backend before parity is even reached:
  `parameter mismatch for bulk_shapes ... actual:[A64,S32,U16,S64] vs expected:[A64,S32,U32,S64]`
  (a32: the same with S16 vs S32). That is the widening pass widening a narrow FUNCTION PARAMETER in the
  callee signature while the caller's pusharg stays narrow -- an interaction between `FunRegWidthWidening`
  and pusharg conversion that has nothing to do with bcopy/bzero.

So all three targets die on things this problem is not about: out-of-range/high-bit typed LITERALS, which
meta.md never specifies, and narrow function PARAMETERS on a program that is never executed.

### Action: DROP the bulkshapes program (test-side only -> Re-eval eligible)
Projected on this exact solution population: Nova 10 -> **0 failures = PASS**; everyone else keeps at
least one real failure. **1 / 11 = 9%**, in band at the hard, high-payout edge.

Why this is a fairness fix and not a difficulty cave-in:
1. bulkshapes is parity-ONLY and never executed. It proves the two backends agree on text, never that the
   text is correct.
2. Its typed-constant cases enforce semantics for literals that do not fit their declared type, which
   meta.md does not specify.
3. Its killing power comes from narrow function parameters, not from the feature under test.
4. The parity REQUIREMENT keeps full coverage: `bulkmem.parity` still runs on a32, a64 and x64 over a
   program with ~60 bulk operations of every kind and direction -- and, unlike bulkshapes, that program
   is also executed against goldens.

## Batch 3 (2026-09-12) — RE-EVAL of batch 2's 11 solutions — **1 / 11 PASS (9%)**

Re-eval regraded the batch-2 solutions against the reduced 11-case suite. Outcome matched the
projection exactly.

| Run | Failed / 11 | Remaining failures |
|---|---|---|
| **Nova 10** | **0** | **PASS** |
| Nova 2, 3, 5, 6, 7, 9, Vega | 1 | `bulkmem.c/...64.opt` |
| Nova 1, 8 | 2 | `bulkmem.parity` a64 + x64 |
| Nova 4 | 3 | `bulkmem.parity` a64 + x64, `bulkmem.c/...64.opt` |

FP Check: judge-a TP, judge-c FP, **adjudicated GENUINE PASS (high confidence)** — judge-c's only probe
was the most-negative S64 immediate on a64, a pre-existing py/cc divergence the clean baseline and the
reference fail identically.

### Per-test kill counts (11 cases)
| Test | Killed |
|---|---|
| `bulkmem.c/bulkmem_e30b83.64.opt` | 8 / 11 |
| `bulkmem.parity` a64 | 3 / 11 |
| `bulkmem.parity` x64 | 3 / 11 |
| every other case | 0 / 11 |

### Suite expanded 11 -> 13 this round (Auto Review T4 High)
Added `bulkmem.c/<name>.optcc` (C++ `optimize_tool.exe` -> C backend -> execute -> golden) and
`bulkmem.opt/<name>.parity` (py-optimizer text vs cc-optimizer text).

Measured, not assumed:
- **Nova 10 rebuilt from its own patch passes 13/13** -> pass rate unchanged at **1/11 = 9%**.
- Mutant "C++ shared `FunRegWidthWidening` unaware of BCOPY/BZERO": new case 1 segfaults, new case 2
  differs by 88 lines. It ALSO fails 4 pre-existing cases, so the reviewer's premise that it passed
  everything was wrong.
- Reference 13/13 three times; base 121/121; 13/13 fail on clean BASE.

## Batch 4 (2026-09-13) — FRESH 10x Nova (meta.md changed) — **1 / 10 PASS (10%)**

| Run | Failed / 13 | Verdict | Failures |
|---|---|---|---|
| **Nova 2** | **0** | PASS_LEGITIMATE | -- |
| Nova 7 | 2 | INTEGRATION | `bulkmem.parity` a64 + x64 (C++ codegen segfaults in normal mode) |
| Nova 9 | 2 | INTEGRATION | `bulkmem.parity` a64 + x64 (same) |
| Nova 1 | 2 | MISSED_REQ | `bulkmem.c` opt + optcc (segfault) |
| Nova 8 | 4 | MISSED_REQ | parity a64 + x64, c opt + optcc |
| Nova 3 | 5 | MISSED_REQ | parity a32/a64/x64, c opt + optcc |
| Nova 5 | 8 | MISSED_REQ | py a32/a64/x64 + parity x3 + c opt/optcc (`list.remove` -> `Ins.__eq__` assert) |
| Nova 4 | 10 | MISSED_REQ | CFG invariant (unconditional + extra succ edge) |
| Nova 6 | 10 | MISSED_REQ | positive bcopy loop never steps src |
| Nova 10 | 10 | MISSED_REQ | lowered before widening, no narrowing barrier |

### Per-test kill counts (10 runs)
| Test | Killed |
|---|---|
| `bulkmem.c/...64.opt` | 7 |
| `bulkmem.c/...64.optcc` | 7 |
| `bulkmem.parity` a64 | 7 |
| `bulkmem.parity` x64 | 7 |
| `bulkmem.py` a32 / a64 / x64 | 4 / 4 / 4 |
| `bulkmem.parity` a32 | 3 |
| `bulkmem.cc` a32 / a64 / x64 | 2 / 2 / 1 |
| `bulkmem.c/...64` (plain) | 0 |

`.optcc` kills exactly the same 7 runs as `.opt` -- it added no independent kills this batch, but also no
false ones. The new optimizer-parity case killed nobody. Every failure is agent-attributed; fairness
verdicts unanimous (`agent_blame_unfair=False` on all 9 failures).

### ⚠️ "No environment blockers" check: 1/10 flagged -- and it is the PASSING run
Every run's VERIFIER is healthy (base 121/0 on all ten, all 13 new cases executed). The flag comes from the
AGENTS: 10 of 10 trajectories run the literal root `make tests` that meta.md names, and it stops in
`BE/ApiDemo/Makefile_cc` with `Cannot find A32 c++ compiler` (no `arm-linux-gnueabihf-g++` in the image).
Six runs record `blocker_detected=True`; only **Nova 2** also has `agent_blame_unfair=True`, which is what
the gating count reports. Its evaluator's own remedy: "install that prerequisite or document the skipped
ApiDemo C++ suite".

### Harness change since batch 4 (read before comparing batch 5)
New mode is now **19 cases** (was 13): the 64-bit program adds typed-constant, `255:U8`/`-128:S8`, S16-wrap and
conditional-successor cases; the 32-bit program adds the same plus an S32 wrap; the new native-only
`bulkwrap_e30b83.64n` program adds 6 cases (S32/S64 wraps, py/cc/parity on a64 + x64, no C backend). Base mode is
**122** (ApiDemo removed after it failed platform Verify; BindingsC added). Batch-4's per-test kill counts are over
the old 13 cases. Nova 2 (batch 4's only pass) passes all 19.

### Harness change for batch 5 (round 24)
New mode is **23 cases**: `bulkwrap_e30b83.64n` now also runs through the C backend (plain / opt / optcc) and optimizer
parity. **Nova 2 (batch 4's only pass) fails those 3 C cases** in the gcc 12.2 image -- its batch-4 pass did not meet
the stated S32/S64 wrap requirement on the C backend. There is no measured passer for the current test set; batch 5
is the first real solvability signal. meta.md now names C-backend arithmetic in the wrap requirement.

### Harness change for batch 5 (round 25)
Still 23 new-mode cases, but `.64n` now carries 8 all-constant overflowing adds (S32/U32/S64/U64) that the optimizers
fold, and the 32-bit program carries 4 (S32/U32). A tool-build failure no longer aborts the run and no longer leaves
stale tool binaries for later cases. The reviewer's wrong impl (BASE `eval.cc`) is killed by 5 of the 23 cases.

### Going into batch 5 (2026-09-14)
23 new-mode cases, 122 base. No measured passer for this suite: passing needs C-backend arithmetic without signed
overflow (round 24) and C++ evaluator width truncation (round 25). The mul/div widening fix (round 26) is solution-side
only and not yet tested; its chain test is deferred to a post-batch Re-eval by user decision.

### Batch 5 suite (2026-09-15): STRICT
Batch 5 runs on the extended fixtures: SUB/MUL/SHL wraps (constant + runtime), same-register bzero, U16/S16 widening
chain, float-DIV parity. Still 23 new-mode cases, 122 base. Mutant kills: ADD-only 3, cursor=input register 8,
widening fix removed 6, float floor 6. Compare batch-5 kill counts against these case files, not batch 4's.

### Environment change before batch 5 (2026-09-15)
Dockerfile now builds in 413 s cold (was 704 s, over the platform's 600 s environment-build timeout that caused
`EnvironmentStartTimeoutError` on Verify Solution). Same `/app` tree byte-for-byte. Batch 5 runs on this Dockerfile
plus the strict test.patch.

## Batch 5 (2026-09-15) — FULL batch, 8x Nova + 1x Vega, STRICT suite — **0 / 9 PASS**
Environment fix worked: every run built and executed, base 122/122 in all nine, no environment blockers, no run marked
unfair. Every verdict `FAIL_MISSED_REQUIREMENT`.

| Run | Failed / 23 | Case groups failed (golden-line mapping + failure text) |
|---|---|---|
| Nova 1 | 9 | `cntpop` chain, float-div parity, **constant-fold add** (C++ evaluator leaves `add fw1:S32 MAX MAX` as 4294967294: x64 isel crash `could not find matching pattern for mov fw1@rdx 4294967294`, optcc segfault, optimizer parity `bzero 4294967294` vs `-2`) |
| Nova 2 | 10 | chains (div/rem/cntpop/sdiv), float, runtime sub/mul/shl, `.32` crash |
| Nova 3 | 17 | positive bcopy loop never advances src (plus the chain/float/fold groups) |
| Nova 4, 6, 7, 8, Vega | 10-12 | chains, float, runtime sub/mul/shl (identical profile) |
| Nova 5 | 12 | same + `.64` C opt/optcc crash |

### Per-test kills (9 runs)
All 8 `bulkwrap_e30b83.64n` paths 9/9; `bulkmem_e30b83.32.a32` py + cc 8/9; `.64n` cc x64 3/9; `.64` C opt/optcc 3/9;
anything else on `.64` 1/9.
### Per case group (runs failing)
`cntpop` chain 9/9 · float-div parity 9/9 · runtime sub/mul/shl 8/9 · U16 div, U16 rem, S16 div chains 8/9 each ·
older corpus and constant folds 1/9 by line mapping, but the constant-fold group also causes Nova 1's crashes.

### Batch 5 replay (Docker, all nine solutions): S strict 0/9 (matches platform 9/9) · suite A 3/9 (Nova 2, Nova 4, Vega) · suite B 3/9

### Batch 5 Re-eval target (2026-09-15): suite A uploaded. Predicted 3/9 (Nova 2, Nova 4, Vega) from the Docker replay.

## Batch 6 (2026-09-16) — FRESH 9x Nova + 1x Vega, suite A — **3 / 10 PASS, ACCEPTED**
Base 122/122 in all ten runs.

| Run | New passed | Verdict | Files | +LOC | Prompt tok | Failures / approach |
|---|---|---|---|---|---|---|
| Nova 1 | 19/23 | INTEGRATION | 15 | 920 | 34.2M | parity a64/x64 on `.64` and `.64n`: C++ `-mode normal` SIGSEGV (F-32) |
| Nova 2 | 18/23 | MISSED_REQ | 25 | 1214 | 36.9M | `.64n` parity a64/x64, cc x64, optcc, opt parity: eval.py/eval.cc untouched, `4294967294` vs `-2` (F-31) |
| **Nova 3** | **23/23** | **PASS_LEGITIMATE** | 27 | 1166 | 32.6M | -- |
| Nova 4 | 11/23 | MISSED_REQ | 15 | 784 | 26.2M | positive `bcopy` never advances src, both twins |
| **Nova 5** | **23/23** | **PASS_LEGITIMATE** | 27 | 1103 | 42.2M | -- |
| Nova 6 | 21/23 | MISSED_REQ | 16 | 848 | 32.8M | `.64` C opt + optcc segfault: no BCOPY/BZERO in width widening (F-30) |
| Nova 7 | 18/23 | MISSED_REQ | 13 | 788 | 36.1M | same 5 as Nova 2 (F-31) |
| Nova 8 | 21/23 | INTEGRATION | 12 | 849 | 33.1M | `.64` parity a64/x64 SIGSEGV (F-32) |
| Nova 9 | 21/23 | MISSED_REQ | 31 | 891 | 36.4M | `.64` C opt + optcc segfault (F-30) |
| **Vega** | **23/23** | **PASS_LEGITIMATE** | 18 | 851 | 23.0M | -- |

Per-test kills: `.64n` parity a64 3, parity x64 3, cc x64 3; `.64` C opt 3, optcc 3; `.64` parity a64 2,
x64 2; `.64n` optcc 2, opt parity 2; nine native py/cc cases 1 each (Nova 4). Killed nothing: `.64` and
`.64n` plain C, `.64n` opt, `.64` optimizer parity, `.32` a32 parity.

