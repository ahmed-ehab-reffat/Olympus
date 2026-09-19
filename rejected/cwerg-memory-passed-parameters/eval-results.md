# eval-results.md — cwerg-memory-passed-parameters

## Batch 1 (2026-09-19) — 8 Nova + 1 Orion + 2 Vega, all Nova-evaluated: **0/11**

Suite R2 (42 new cases). Saved runs: `agent-runs/1/`. Clusters: A = a32 forward call to a later
narrow-param callee (pre-existing base bug), B = C++ parser rejects exactly 64 params, C = a32 local
allocator on `mix20` (pre-existing no-spill ceiling), D = x64 8th float in xmm8 (agent took C++'s 8
float regs; xmm8 clobbered in the loop), E = a64 allocator on `fwd20` (ceiling), T5 = a32 C++ float
constant store.

| Run | Folder | Base | New failed /42 | Files | +LOC | Clusters | Approach note |
|---|---|---|---|---|---|---|---|
| Nova #8 | Nova_Nova_1 | pass | 10 | 27 | 883 | A, B, C | memory block + pointer; no whole-unit widening; C++ parser untouched |
| Nova #7 | Nova_Nova_2 | pass | 23 | 17 | 642 | A, B, C, D, runtime values | incomplete x64/a64 runtime paths |
| Nova #6 | Nova_Nova_3 | pass | 9 | 41 | 1137 | A, B, D | 8 x64 float regs |
| Nova #5 | Nova_Nova_4 | pass | 12 | 27 | 1182 | A, B, D, E | exact-16-GPR boundary bug (`gpr16`) |
| Nova #4 | Nova_Nova_5 | pass | 18 | 44 | 1179 | A, B, C, D, T5 | |
| Nova #3 | Nova_Nova_6 | pass | 15 | 29 | 1539 | A, B, E, T5 | |
| Nova #2 | Nova_Nova_7 | pass | 12 | 23 | 739 | A, B, C, D | |
| Nova #1 | Nova_Nova_8 | pass | 11 | 15 | 800 | A, B, C, D | |
| Orion #1 | Orion_Nova | pass | 21 | 12 | 749 | A, B, C, D, E, T5 | x64 segfaults (spill clobber) |
| Vega #2 | Vega_Nova_1 | pass | 8 | 35 | 1049 | A, C, fwd a64 cc | fixed C++ 64-param parser and xmm8; closest run |
| Vega #1 | Vega_Nova_2 | FAIL (linkerdef.a32: its codegen change moves linker addresses) | 5 | 34 | 1322 | C, D | fixed A and B |

## Local replay of all 11 solutions against the R3 suite (steering only; the platform re-eval is authoritative)

| Run | Failed /42 on R3 | Remaining clusters |
|---|---|---|
| Vega #2 | **0 (pass)** | none |
| Vega #1 | 2 | D (xmm8), plus its own baseline linkerdef failure |
| Nova #8 | 6 | B only |
| Nova #6 | 8 | B, D |
| Nova #2 | 8 | B, D |
| Nova #1 | 10 | B, D, own a32 parity diff |
| Nova #3 | 11 | B, T5 |
| Nova #5 | 11 | B, D, own gpr16 boundary bug |
| Orion #1 | 16 | B, T5, x64/a32 segfaults |
| Nova #4 | 17 | B, D, T5, own runtime errors |
| Nova #7 | 22 | B, many runtime errors |

Projection: **1/11 (9%)**.
