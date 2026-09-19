# eval-results.md - customasm-exact-fractional-values

No batch run yet. DESIGN.md complete; deliverables not yet authored.

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|
| - | - | - | - | - | - | - | - | - | - |

## Capture protocol reminder

At every batch, while the platform run view is open: record failed test NAMES and a one-line
architecture note per run, and save every passing agent's diff to `agent-runs/<batch>-<run>.patch`
plus the one or two most instructive failures. The differential harness, trap-proof and
leanest-passer measurements are impossible later without them.

## Batch 1 — 8x Nova (2026-09-17, 50-test artifact)

| Run | Verdict | Requests | Added LOC | Files | Base tests broken mid-run | Approach |
|---|---|---|---|---|---|---|
| Nova #1 (Nova_Nova_8) | PASS | 60 | 594 | 13 | none | exact normalized rational |
| Nova #2 (Nova_Nova_7) | PASS | 56 | 697 | 14 | none | exact Rational storage |
| Nova #3 (Nova_Nova_6) | PASS | 67 | 779 | 13 | `expr_member_builtin_size_*`, `test_literals` | rational + mixed numeric eval |
| Nova #4 (Nova_Nova_5) | PASS | 62 | 748 | 14 | none | rational storage + width |
| Nova #5 (Nova_Nova_4) | PASS | 54 | 752 | 11 | `expr_member_builtin_size_*`, `test_literals` | rational + tie-to-even |
| Nova #6 (Nova_Nova_3) | PASS | 63 | 720 | 12 | none | exact rational |
| Nova #7 (Nova_Nova_2) | PASS | 50 | 631 | 13 | `expr_member_builtin_size_*`, `test_literals` | arbitrary-precision rational |
| Nova #8 (Nova_Nova_1) | PASS | 64 | 593 | 12 | none | reduced exact rational |

**Pass rate 8/8 = 100%. Ceiling is 40%, so this is a too-easy reject as it stands.**

- Every eval called the solution legitimate; no cheating, no verifier tampering, no false positives. The FP check is clean, which confirms the tests and description agree. The problem is not broken, it is easy.
- Long-horizon metrics all clear: median 61 requests (floor 40), 11-14 files (floor 2), 593-779 added lines.
- Every eval rated the description clear and the difficulty "challenging". Agents treated it as a spec to implement, which it is: normalization, ties-to-even, carry, sign, zero and widths are all stated, and everything lands in NEW code (a new value variant plus a new rational module).
- The only friction anywhere in the batch was base-suite damage: 3 of 8 runs broke `test_literals` and `expr_member_builtin_size_ok_simple` / `_err_indefinite` while touching the lexer and the size machinery. All three repaired it. That is the one seam in this design that pushes back, and it is a collision with EXISTING behavior, not with the new spec.
- Diagnosis: no interdependent or misdirecting trap. Fixing one thing never breaks another, and each failure points straight at its own cause. Per the calibration model this is a one-trap uniform-wrap shape, which reads ~50% or above; it measured 100%.

### Post-batch-1 hardening (2026-09-17)

| Check | Result |
|---|---|
| Lever | exact arithmetic on fractional/mixed operands through the existing binary-op path; integer division still truncates; other operators reject fractions |
| Trap-proof M1 (promotion above integer arms) | 125 kills, 103 of them existing base tests |
| Trap-proof M2 (no zero check) | 1 kill |
| Trap-proof M3 (`%` promoted too) | 1 kill |
| Trap-proof M4 (f64 arithmetic) | 2 kills |
| New suite on base | 61 of 61 fail, no build wipe |
| Solved, 3 runs | new 61/0, base 708/0, identical |
| Reverse-apply | both patches unapply cleanly |
| human-effective LOC | 368 |
| meta.md | 462 words, ASCII, under the 500 cap |
| Next step | fresh batch (meta.md changed, so no Re-eval) |

## Batch 2 — 8x Nova (2026-09-18, 61-test artifact, arithmetic lever)

| Run | Verdict | Requests | New tests failed | Base failed | Failure cause |
|---|---|---|---|---|---|
| Nova #8 (Nova_Nova_1) | PASS | 60 | 0/61 | 0 | |
| Nova #7 (Nova_Nova_2) | PASS | 56 | 0/61 | 0 | |
| Nova #6 (Nova_Nova_3) | FAIL_WRONG_LOGIC | 59 | 5/61 | 0 | decomposition kernel: for exponent >= 0 the remainder was not divided by 2^e, so 3, 7, 255.5 and pi decompose wrong |
| Nova #5 (Nova_Nova_4) | PASS | 58 | 0/61 | 0 | |
| Nova #4 (Nova_Nova_5) | PASS | 51 | 0/61 | 0 | |
| Nova #3 (Nova_Nova_6) | PASS | 57 | 0/61 | 0 | |
| Nova #2 (Nova_Nova_7) | PASS | 69 | 0/61 | 0 | |
| Nova #1 (Nova_Nova_8) | PASS | 52 | 0/61 | 0 | |

**Pass rate 7/8 = 87.5%. Still a too-easy reject.**

Nova #6's 5 failing tests: `an_integer_argument_decomposes_like_its_fractional_value`, `integer_division_still_truncates`, `integer_arithmetic_keeps_producing_integers`, `value_just_below_a_power_of_two_keeps_its_exponent`, `single_precision_of_pi_matches_reference_encoding`. Two of those are from the new round, but they fail through the decomposition, not through arithmetic.

- **The arithmetic lever killed 0 of 8.** Every agent added the fractional arms correctly, and none broke integer division. The mistake it was built for (promotion arm ahead of the integer arms) breaks 103 existing tests at once. That is loud, not misdirecting: an agent that runs the suite sees it immediately. L-candidate: a trap whose wrong version breaks the BASE suite is self-revealing, because agents run the base suite.
- The single kill came from the batch-1 design (the normalization kernel), which is the F-26-style "formula transcribed wrong" class. It is 1 of 16 across two batches.
- Evals: all description_clear, all "challenging", no FP flags on the passes.
- Combined over both batches: 15 of 16 pass.

### Differential harness after batch 2 (2026-09-18): is there a latent discriminator?

25 fair probes of fractional values moving through the assembler's OTHER stages, run against all 16 saved solutions (both batches) on clean BASE checkouts, compared to the reference:
symbols, forward-referenced symbols, forward chains that change type across passes, `#fn` user functions, `#if` / `#else`, `#const`, `$` pc arithmetic, label differences, local labels, `#ruledef` operands (single, negative, two-argument, forward-referenced, cascaded), `#subruledef`, a fractional literal inside a rule pattern, and a width taken from a later symbol.

| Result | Count |
|---|---|
| Batch-2 solutions (8) diverging from the reference on ANY probe | **0** |
| Batch-1 solutions diverging | 3, only on the 13 probes that use arithmetic, which batch 1 did not require |
| Batch-1 solutions diverging on non-arithmetic probes | **0** |

**Verdict: no cross-stage lever exists.** customasm stores every value generically, so once the evaluator knows a fractional variant, symbols, the resolver's multi-pass guessing, user functions, conditionals and ruledef operands all carry it with no extra work. Every agent inherits that for free.

### Kernel harness (2026-09-18): last unprobed axis

10 edge cases of the decomposition, expectations from an independent Python `fractions` oracle (the reference matched all 10): 1e-30 and 1e30+0.5 magnitudes, a carry at a negative exponent (0.2499 at 2 bits), a carry from a negative value (-1.99 at 2 bits), an exact tie and a just-above-tie at 60 bits, a 200-bit mantissa of 0.1, and ties or carries produced by arithmetic (1/3 + 1/6 at 1 bit, 7/1024 at 3 bits).

| Result | Count |
|---|---|
| Passing solutions diverging on any kernel probe | **0** |
| Divergences seen | 3 batch-1 solutions on the 2 probes that need arithmetic (not required in batch 1); batch-2 Nova #6 on 1e30 (the run that already failed) |

**Final verdict: no fair discriminator on any axis. SHELVED 2026-09-18, moved to `rejected/`.**
