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
