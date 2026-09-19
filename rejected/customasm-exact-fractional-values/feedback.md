# feedback.md - customasm-exact-fractional-values

## Status

**CORE SLICE COMPLETE AND VALIDATED. Blocked on the platform core-slice precheck before any
differentiating scope is written.** All five deliverables exist and pass clean-room and Docker
validation. Do not write the arithmetic operators, emission rules, resolver integration or
cross-product cells until the precheck verdict is clean.

## Validation record (core slice)

| Check | Result |
|---|---|
| Effective LOC (hook, human-effective) | **404** against a 275 target, 10 files, 1 new module |
| Base suite, solution applied | 708 pass, 0 fail |
| New suite, solution applied | 36 pass, 0 fail |
| New suite on base | 35 of 36 fail as per-test failures, not a build wipe |
| The one base-passing new test | `integer_division_still_truncates`, the deliberate baseline guard. No existing fixture covers integer division, so it is load-bearing, and it is P2P by design |
| Patch order, test then solution | validated in a fresh clone at BASE |
| Patch order, solution then test | validated in a second fresh clone |
| Reverse-apply | both patches unapply cleanly |
| Flakiness gate | 3 runs each of base and new, identical every time |
| Docker, unsolved image | builds in 19s with test.patch and no solution, so `cargo build --tests` is safe here; base 708/0, new 36 cases/35 failures |
| Docker, solved image | base 708/0, new 36/0, non-root uid 1000, `--network none` |
| Mutation pass, 5 branches | ties-to-even 1 kill, carry 2, mantissa width 6, truncation direction 1, rounding itself 5. No dead branches |
| Comments added | zero in both patches, matching the repo's convention |
| Encoding | every file ASCII, test.sh mode 100755 in the patch |

## Oracle note

Expected values were computed by an independent Python implementation, not derived from the Rust
code, and three of them were cross-checked against real IEEE-754 bit patterns: 0.1 and pi at single
precision and 0.3 at double precision. The kernel matched all three, and caught one error in my own
hand-computed expectation.

## Strategic summary

Add exact fractional values to customasm's expression evaluator, plus four builtins that decompose
one into a whole part, a fractional part, a binary exponent and a mantissa rounded to a requested
number of bits. The assembler supplies exact arithmetic and a stated rounding contract; the user
writes whatever encoding they want (IEEE-754 single, bfloat16, a fixed-point Q format) in their own
`#ruledef`. That division of labour is the maintainer's own stated preference.

## Why this pick

- **Exclusivity clean.** Seven feature-class PR searches in all states returned zero rows.
- **Maintainer philosophy positive and recent.** Issue #233, hlorenzi 2025-12-01, endorses exactly
  this direction and proposes passing the precision into the decomposition. Issue #92 shows him
  reluctant about the alternative (a built-in float library), which this design avoids.
- **Competitor-free repo.** No account in `sig_accounts.txt` has touched customasm; the two open PRs
  are from 2021.
- **Absorption test passed.** `Value` has no fractional arm, `grep` for f32/f64/float across `src`
  returns nothing but unrelated substring noise, `BigInt` is integer-only, and the number lexer has
  no fraction path. The missing content is exact rational arithmetic plus a normalisation and
  rounding routine, which is a real algorithm, not a call-through.
- **Size.** ~563 effective lines over 10 files against a 275 target, sketched against two measured
  in-repo siblings (`4f728a7`, `ae777b5`).

## Known risks, carried forward

1. **Derivative risk is the live one.** The lane is maintainer-invited, cold and PR-free in a repo we
   already hold three submissions in, which is a named derivative shape. Mitigation is the mandatory
   core-slice precheck before any differentiating scope is written. This is a hard gate, not advice.
2. **Outsider-nameability MEDIUM.** "Float support in an assembler" is nameable. meta.md must be
   phrased on the repo model: exact values, the decomposition contract, the sized-value model,
   `$`-prefixed builtins.
3. **Baseline preservation is the lead trap and also the biggest reference risk.** Integer division
   must keep truncating. Our own reference has to be checked against the full base suite every round.
4. **Legacy option.** Every builtin is registered twice, once `$`-prefixed and once bare under
   `use_legacy_behavior`. Missing that is the one codebase-inferable requirement and is deliberate.

## Attempt history

| Round | What changed | Result |
|---|---|---|
| 0 | DESIGN.md written after a six-repo screen; two earlier candidates (ott-jax/ott, pymatting) died at the absorption gate | design complete, precheck owed |

## Round: Verify Solution FAIL fix + coverage + normalization wording (2026-09-17)

- **Verify Solution FAIL:** `integer_division_still_truncates` passed on base (`#d8 7 / 2`). Every new test must fail without the solution, so it now reads the quotients through `$mantissa`: `#d16 $mantissa(7 / 2, 8) @ $mantissa(-7 / 2, 8)` -> `8080`. Truncation gives 3 twice (0x80). Exact division would give 3.5 (0xC0), and floor division would give -4 for the negative case (0x00). This also covers the advisory "signed truncation" gap.
- **Coverage tests added (all stated in the prompt):** `.5` rejected (no digit before the point); `$mantissa($fract(5.75), 8)` = `80` (pins 0.75, not just the exponent bin); integer arguments to `$whole` / `$fract`; arity checks `$mantissa(1.5, 8, 2)`, `$whole()`, `$fract(1.5, 2)`.
- **meta.md:** normalization sentence swapped for the direct inequality form. Rounding and carry text left as is. meta.md is solver-visible, so this round needs a full batch, not a re-eval.
- **Not addressed:** the sign of `$fract` can't be observed. The solution has no arithmetic or comparison on fractional values, and `$mantissa` / `$exponent` ignore sign. Either drop that phrase from meta or accept it as untested.
- **Validation:** clean clone at BASE with test.patch only: 42/42 new tests fail, none by build wipe. With solution added, run 3 times: new 42/0 and base 708/0 on every run.

## Round: Auto Review revision (T8, T3/T4, S1, S2) (2026-09-17)

- **T8 JUnit diagnostics:** test.sh now collects each `---- <test> stdout ----` block from cargo and writes it into that testcase's `<failure>` as CDATA. Checked by breaking one assertion on purpose: the XML carried the panic location and the left/right values, and it parses as valid XML.
- **T3/T4 sign of `$fract`:** added `fract_of_a_negative_value_keeps_its_sign` (`$fract(-5.75) == -0.75` and `!= 0.75`). `==` on fractional values was not stated anywhere, so meta.md gains one sentence: two fractional values compare with `==` / `!=` and are equal exactly when they are the same number. Added `equal_fractional_values_compare_equal_however_they_are_written` (`0.50 == 0.5`, `1.25 != 1.2`) to cover that sentence.
- **S1:** `$exponent` / `$mantissa` now also take their metadata from the precision argument. I could not make the old code give a wrong result: forward-label precisions (`end`, `end - x`) already resolved correctly. So there is no regression test, because it would not fail against the previous reference.
- **S2:** a precision at or above `BIGINT_MAX_BITS` is rejected with the repo's "value is outside the supported range" error before any shift. `BIGINT_MAX_BITS` is now re-exported from `util`. There is no test, because this limit is not in meta.md and a test would be a hidden requirement.
- **Validation:** clean clone at BASE with test.patch only: 44/44 new tests fail, none by build wipe. With solution added, run 3 times: new 44/0 and base 708/0 on every run. Both patches reverse cleanly. Human-effective LOC is 413. No comments were added.

## Round: Solution Quality FAIL, mixed integer/fractional equality (2026-09-17)

- **Finding:** `1.0 == 1` and `$fract(7) == 0` reached the "invalid argument types" error, because the Eq/Ne arms only compared values of the same variant. The description says integers are accepted anywhere fractions are, so this was a real gap.
- **Solution:** added Eq and Ne arms in `eval.rs` for Fractional-vs-Integer in both orders. The integer is converted with `BigFrac::from_integer` before comparing.
- **meta.md:** the equality sentence now says the comparison can be against another fractional value or an integer, so this is stated directly and does not have to be inferred.
- **Tests:** added `a_fractional_value_compares_equal_to_the_same_integer` (`1.0 == 1`, `2 == 2.0`, `$fract(7.5) != 0`, `$fract(7) == 0`, `0.5 == 0` is false). Coverage suggestions also added: point rejected in binary and octal literals, `$fract()`, `$exponent(1.5, 8, 2)`.
- **Validation:** clean clone at BASE with test.patch only: 49/49 new tests fail, none by build wipe. With solution added, run 3 times: new 49/0 and base 708/0 on every run. Patches reverse cleanly. Human-effective LOC is 419, no comments, meta.md is ASCII at 420 words.

## Round: Auto Review T3/T4, cross-type `!=` + meta trim (2026-09-17)

- **T3/T4:** added `a_fractional_value_and_the_same_integer_are_not_unequal` (`1.0 != 1` false, `1 != 1.0` false, `1 != 1.5` true, `2.5 != 2` true). This covers equal operands and an integer on the left, which kills both wrong implementations the reviewer named.
- **Coverage suggestions:** same-type `!=` on equal values (`0.50 != 0.5` is false) added to the equality test. `-0.1` now decomposes the same as `0.1` in the magnitude test. Multi-group underscores `1_2_3.4_5_6` added (whole part and exact fraction). Skipped: validating the type of the bit-count argument, and adjacent-underscore rejection. Neither is stated in meta, so tests for them would be hidden requirements.
- **meta.md:** removed the "Today a number is always an integer..." sentence, as the reviewer asked. Now 394 words.
- **Validation:** clean clone at BASE with test.patch only: 50/50 new tests fail, none by build wipe. With solution added, run 3 times: new 50/0 and base 708/0 on every run. Patches reverse cleanly. solution.patch unchanged this round.

## Round: hardening after batch 1 (8/8 = 100%) (2026-09-17)

**Diagnosis (from agent-runs/1, 8 Nova runs).** Every run passed, every eval called the solution legitimate, and the FP surface is clean. So the artifact is not broken, it is easy. The design put almost everything in new code: a new value variant plus a new rational module, with normalization, ties-to-even, carry, sign, zero and widths all stated. Nothing an agent does in one place can break something in another, and every failure points at its own cause. That is the one-trap uniform-wrap shape. The only place the repo pushed back was base-suite damage: 3 of 8 runs broke `test_literals` and `expr_member_builtin_size_*` while touching the lexer and the size machinery, then repaired it.

**Evidence for the lever.** 7 of the 8 passers never implemented arithmetic on fractional values at all. The one that did (Nova #3) wrote a single generic arm matching `Integer | Fraction` on both sides for `+ - * /`. That arm is correct only because it sits after the integer arms; move it up and integer arithmetic silently becomes fractional. So the lever targets a mistake an agent already made a version of.

**Lever: arithmetic through the existing shared operator path.** meta.md gains one paragraph: the four arithmetic operators take fractional and mixed operands, results are exact including quotients with no finite decimal form, results are unsized fractions, integer/integer division still truncates, division by zero stays an error, and every other operator still rejects a fractional operand. This is a different axis from the existing traps: it is about collision with existing behavior, not about the new spec.

**Trap-proof, 4 natural-but-wrong implementations, all killed:**

| Mutant | Kills |
|---|---|
| M1 promotion arm placed above the integer arms | 125 tests: 103 existing base tests + 22 new. This is the misdirecting one: the feature tests mostly still pass and the base suite explodes |
| M2 fractional division without the zero check | `dividing_by_zero_stays_an_error` |
| M3 promotion extended to `%` as well | `a_remainder_of_a_fractional_value_is_rejected` |
| M4 arithmetic routed through f64 | `arithmetic_on_fractional_values_is_exact`, `a_quotient_with_no_finite_decimal_form_stays_exact` |

M4 is worth noting: a first version that rounded the float to 9 decimals passed everything, because the rounding repaired the float error. Only a mutant that keeps the real f64 result is a faithful stand-in for a float implementation, and that one dies on `0.1 + 0.2 == 0.3` and on `1.0 / 3.0`.

**11 new tests** (50 -> 61): exact arithmetic and `0.1 + 0.2 == 0.3`, the three division cases, the non-terminating quotient (`(1.0 / 3.0) * 3 == 1`, `1.0 / 3.0` equals `2.0 / 6.0`, and single precision `3eaaaaab`), negative subtraction through `$whole` / `$fract`, sized integer plus fraction giving an unsized result, division by zero, and rejection of `%`, `<<`, `&` and `<` on a fractional operand, plus integer arithmetic still producing integers.

**Predicted effect.** Unknown but expected to be large: the lever adds work 7 of 8 passers never did, and its natural implementation breaks 103 existing tests. I would not expect it alone to reach the low band, so read the next batch as a measurement, not a finish.

**Note:** `integer_arithmetic_keeps_producing_integers` passed on base in the first clean-room run (it was integer-only). It now also decomposes `3 + 4`, so it requires the feature. All 61 new tests fail on base.

**Validation:** clean clone at BASE, base 708/0. With test.patch only, 61/61 new tests fail, no build wipe. With solution, 3 runs: new 61/0 and base 708/0 every time. Patches reverse cleanly. human-effective 368 (floor 200). meta.md 462 words, ASCII, no comments in either patch.

## Round: batch 2 read + differential harness (2026-09-18)

- Batch 2: **7/8 pass (87.5%)**. The arithmetic lever killed 0 of 8. Its wrong version breaks 103 base tests at once, which agents see immediately because they run the suite. A trap whose wrong version breaks the existing suite is self-revealing, not misdirecting.
- The only kill in two batches (1 of 16) is the decomposition kernel, a transcription error of a stated formula.
- Differential harness, 25 cross-stage probes x 16 saved solutions: zero divergence outside arithmetic. The repo absorbs the feature through its generic value storage, so there is no integration seam left to harden.
- Test-only additions staged in the worktree but NOT yet in test.patch: mixed-operand subtraction matrix (Auto Review T3/T4 Medium), `$exponent` on integers, `>>`, `|`, `^`, `>`, `<=`, `>=`, unary `!` rejections. 65/65 pass on the reference.
- **Recommendation: shelve.** 15 of 16 passes, two levers on two axes, and a harness showing no latent discriminator. This matches the TOO-EASY death class of a fully specified kernel absorbed by a generic architecture.

## SHELVED 2026-09-18 (too easy)

- The kernel harness (10 oracle-checked edge cases x 16 saved solutions) found no passer diverging. Together with the 25 cross-stage probes, that covers every axis this feature has.
- Result: 15 of 16 passes over two batches. Two levers on two axes both failed. Zero fair discriminators across 35 probes.
- Recorded in `Instructions/TOO-EASY.md`: a new taxonomy row ("New value kind in a generic evaluator"), a case study, and a ledger line. The customasm row in `Instructions/SATURATED-REPOS.md` is amended.
- Folder moved to `rejected/customasm-exact-fractional-values`. It is reference only, not a submission.
