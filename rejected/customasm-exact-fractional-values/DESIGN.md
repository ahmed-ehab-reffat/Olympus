# DESIGN.md - customasm-exact-fractional-values

Base commit: `a45db8ff315ef29eca4fe766d5082408bb6d9903` (2026-09-07, `main`).
Repo: hlorenzi/customasm, Apache-2.0, 1060 stars, 37 PR-free issues, three runtime deps
(`getopts`, `num-bigint`, `sha2` dev-only), green `Test Build` on every recent `main` push.

## 1. Title

Add exact fractional values and precision-on-demand decomposition to the expression evaluator

Verb `Add`, 11 words, names the subsystem (`src/expr`). Category: feature-request.

## 2. Shape classification

- Shape: **O-Composite-add** (new capability spanning lexer, expression parser, value model,
  evaluator, builtin functions and the assembler's resolver/emission path). `SHAPES.md  Pattern 11`.
- Pass-rate target: **10-30%**, design to the low edge. Current ceiling is <= 50%; 0% rejects.
- Best agent: Orion for the long-horizon integration, Nova for the arithmetic. Batch should be mixed.
- Dominant predicted verdict: MISSED_REQUIREMENT on the rounding contract, REGRESSION on integer
  division.
- Solver/our LOC ratio: expect 1.2-1.5x (the value-kind addition forces edits the reference also makes).

## 3. Public API surface

The user-visible surface is four builtin functions plus a literal form. Every name below is asserted
by tests.

- **Fractional literal** - a decimal number with a point and at least one digit on each side:
  `1.5`, `0.1`, `12.0`, `1_000.25`. Evaluates to a fractional value.
- `$whole(x)` - the integer part of `x`, truncated toward zero. Returns an unsized integer.
- `$fract(x)` - `x` minus `$whole(x)`. Returns a fractional value carrying the sign of `x`.
- `$exponent(x, bits)` - the binary exponent of `x` after its significand is rounded to `bits`
  fraction bits. Returns an unsized integer.
- `$mantissa(x, bits)` - the `bits`-wide fraction of the rounded significand. Returns an integer of
  size `bits`, so it can be concatenated and emitted directly.
- Arithmetic and comparison operators accept fractional operands: `+ - *` `/` and `== != < <= > >=`,
  and unary `-`.
- Error kinds (substring-matched, 1-3 stable keywords each): `invalid value` for a malformed
  literal, `unsized` for emitting a value with no width, `expected 2 arguments` for arity,
  `division by zero`.

Legacy unprefixed spellings (`whole`, `fract`, `exponent`, `mantissa`) are registered only under the
existing `use_legacy_behavior` option, matching how every current builtin is registered.

## 4. Canonical output form

This section IS the contract. Every clause appears in meta.md.

- **Exactness.** A fractional value holds its number exactly, as a ratio of two arbitrary-precision
  integers. `0.1 + 0.2 == 0.3` is true. No decimal is approximated on the way in.
- **Normalisation.** For a non-zero `x`, `e` is the unique integer with `2^e <= |x| < 2^(e+1)`, and
  `|x| = 2^e * (1 + f)` with `0 <= f < 1`.
- **Rounding.** `f` is rounded to `bits` fraction bits, to the nearest representable value, and a
  value exactly halfway between two of them rounds to the one whose last bit is zero.
- **Carry.** If that rounding takes the significand to `2`, the reported mantissa is `0` and the
  reported exponent is one greater. `$mantissa` therefore always lies in `[0, 2^bits)`, and
  `$exponent` and `$mantissa` describe the same rounded number.
- **Sign.** Both `$exponent` and `$mantissa` describe `|x|`.
- **Zero.** `$exponent(0.0, bits)` is `0` and `$mantissa(0.0, bits)` is `0`.
- **Truncation direction.** `$whole` truncates toward zero, so `$whole(-1.5)` is `-1`, and
  `$fract(-1.5)` is `-0.5`.
- **Width.** `$mantissa` returns a value of size `bits`; `$whole` and `$exponent` return values with
  no size. A `bits` of zero returns a zero-width value.
- **Integer division is unchanged.** `/` between two integers still truncates, so `7 / 2` is `3`. A
  fractional operand on either side makes the whole operation exact, so `7.0 / 2` is `3.5`.
- **Fractional values have no inherent width**, so emitting one directly is an error.

## 5. Blind-spot pre-empts

From `DESCRIPTION.md  Blind-Spot Pre-Empt Sentence Bank`:

- *Unstated inverse* - the carry clause states what happens when rounding reaches 2, which the
  positive statement of rounding alone does not imply.
- *Default ordering / sizing* - the width clause states which results carry a size and which do not.
- *Compound order preservation* - the integer-division clause states that the existing behaviour is
  preserved, and names the condition under which it changes.
- *Falsy-on-invalid* - the zero clause gives `$exponent` and `$mantissa` a defined answer at zero
  rather than leaving it to an error path.

Codebase-inferable requirements: exactly **one** - that `$`-prefixed builtins also accept their
unprefixed spelling under the legacy option, which every existing builtin already demonstrates.

## 6. Description draft

Target ~330 words, well inside the 500 hard cap. Plain prose, no headers, no lists of instances.
Opening sentence states the ask. Full text lives in `meta.md`; the contract clauses of section 4 map
one-to-one onto its sentences, and nothing else is asserted by a test.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Effective (x0.7) | Reason |
|---|---|---|---|---|---|
| NEW | `src/util/bigfrac.rs` | - | +300 | 210 | exact rational on `BigInt`: normalise, arithmetic, binary exponent, round-to-n-bits ties-to-even with carry |
| MODIFY | `src/util/mod.rs` | 12 | +2 | 2 | module export |
| MODIFY | `src/syntax/token.rs` | 620 | +30 | 21 | fractional literal lexing |
| MODIFY | `src/syntax/excerpt.rs` | 260 | +55 | 39 | exact decimal-to-rational conversion |
| MODIFY | `src/expr/expression.rs` | 1050 | +95 | 66 | `Value` variant, constructors, metadata, type name |
| MODIFY | `src/expr/parser.rs` | 700 | +30 | 21 | literal dispatch |
| MODIFY | `src/expr/eval.rs` | 876 | +130 | 91 | binary/unary ops, promotion, comparisons, errors |
| MODIFY | `src/expr/builtin_fn.rs` | 261 | +110 | 77 | four builtins, arity and domain checks, sized results |
| MODIFY | `src/expr/inspect.rs` | ~200 | +25 | 18 | size and type queries |
| MODIFY | `src/asm/resolver/eval.rs` | ~300 | +25 | 18 | fractional values through the iterative resolver |
| **TOTAL** | **10 files (1 new)** | | **+802** | **~563** | |

Clears the floor with wide margin: hook target is `human-effective >= 275`, `raw >= 320`, `>= 3`
files. Sketch is against a measured in-repo sibling: commit `4f728a7` (member access) added one value
kind at 956 insertions across 29 files; `ae777b5` (struct literals) at 364 insertions. This design is
deliberately narrower in file count and deeper in one new module, which is what keeps the resolver
from absorbing it.

## 8. Solution outline - pure-function helpers

One helper per contract clause in section 4.

- `BigFrac::from_decimal(int_digits, fract_digits) -> BigFrac` - exact, no float intermediate.
- `BigFrac::normalize(&self) -> (sign, exponent, BigFrac /* f in [0,1) */)` - the binary
  normalisation of clause 2.
- `BigFrac::round_fraction_to_bits(&self, bits) -> (BigInt /* m */, bool /* carried */)`  -
  nearest, ties to even, reporting the carry rather than hiding it.
- `BigFrac::decompose(&self, bits) -> (exponent, mantissa)` - composes the two above and applies the
  carry adjustment. **This is the shared kernel `$exponent` and `$mantissa` both call.**
- `BigFrac::trunc_toward_zero(&self) -> BigInt` and `BigFrac::fract_part(&self) -> BigFrac`.
- `BigFrac::checked_add/sub/mul/div` - exact, with a division-by-zero error.
- `promote_operands(lhs, rhs) -> Option<(BigFrac, BigFrac)>` - returns `None` when both sides are
  integers, which is what preserves integer division.

No fixpoint loop is added; the repo's existing resolver fixpoint is reused and must keep converging
when a fractional constant participates.

## 9. Test file outline

New fixture directories under `tests/`, matching the repo's own harness (one generated `#[test]`
per `.asm` file, every fixture also run under a second optimisation variant for free).

- `tests/frac_literal/` - lexing and exactness: `ok.asm`, `ok_separators.asm`,
  `err_trailing_point.asm`, `err_leading_point.asm`, `err_two_points.asm`.
- `tests/frac_arith/` - arithmetic and promotion: exact `0.1 + 0.2 == 0.3`, mixed integer and
  fractional, unary minus, comparisons, `err_div_zero.asm`, and
  **`ok_integer_division_preserved.asm`** asserting `7 / 2 == 3`.
- `tests/frac_decompose/` - the contract: `ok_basic.asm`, `ok_ties_to_even.asm`,
  **`ok_rounding_carry.asm`**, `ok_zero.asm`, `ok_negative.asm`, `ok_wide_mantissa.asm` (a
  precision no double can represent), `ok_bits_zero.asm`, `err_arity.asm`.
- `tests/frac_emit/` - width and emission: `$mantissa` emitted directly at its size,
  `err_emit_fractional.asm`, `err_emit_unsized_exponent.asm`.
- `tests/frac_ruledef/` - the cross-product cells: a `#ruledef` whose instruction field is built from
  `$exponent`/`$mantissa`, a `#const` fractional feeding an address-dependent expression across
  resolver iterations, and a user-written IEEE-754 single-precision encoder in assembly whose output
  is asserted byte-exact.

Roughly 55-70 fixtures. Decomposed per ATOM, not per sentence: every clause of section 4 has both its
positive and its negative fixture, and every builtin has an arity and a domain fixture.

5-axis coverage: every clause of section 4; all four builtins plus the literal and every operator;
every branch of `decompose` including the carry; empty/zero/single/boundary/negative/wide; and the
stated inverse (integer division unchanged) has its own fixture.

## 10. Forced trait bounds / generics

Rust. `BigFrac` must implement `Clone`, `PartialEq`, `PartialOrd`, `Debug` and `std::fmt::Display`
to slot into `Value`, which already derives those. `Value` is matched exhaustively in several
places, so a new variant forces every match arm to be handled - a compile-forced path. The silent
path is `promote_operands`, which nothing forces. That pairing is trap 5 below.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Rounding carry breaks agreement between `$exponent` and `$mantissa` | F-9 | S-tier shared kernel | normalisation | #2, #3 | the two builtins are computed independently, so a significand that rounds up to 2 yields mantissa `2^bits` or an exponent one too small | the carry clause | `ok_rounding_carry.asm` |
| 2 | Ties round half away from zero instead of to even | F-13-adjacent | A8 boundary inversion | rounding rule | #1 | half-up is the reflex and matches most languages' printing | the rounding clause | `ok_ties_to_even.asm` |
| 3 | Decimal parsed through a double | - (A9, unmeasured here) | A9 exact-fit-passing | exactness | #1 | `str::parse::<f64>()` is exact for every value an agent smoke-tests (`1.5`, `0.25`, 23-bit requests) and wrong only past 53 bits | the exactness clause | `ok_wide_mantissa.asm`, `0.1 + 0.2 == 0.3` |
| 4 | Integer division regressed to exact division | F-20 | S3 baseline preservation | operator semantics | #5 | making `/` uniformly exact is the clean refactor, and it reds existing fixtures the agent did not write | the integer-division clause | `ok_integer_division_preserved.asm` plus the whole base suite |
| 5 | Size dropped from `$mantissa`, or wrongly attached to `$exponent` | F-9 | S4 machinery-riding | value width | #4 | the size lives in `BigInt::size`, is set far from the builtin, and nothing forces it | the width clause | `frac_emit/` fixtures |
| 6 | Cross-product cells | F-10 | S2 composition | capability composition | all | composition over-fires: promotion applied twice, or a sized mantissa re-sized by the ruledef field | none needed | `frac_ruledef/` |

Every trap is CONTRACT-STATED / FIX-HIDDEN: each clause says what the observable is, none says how to
compute it. No clause enumerates the failing cases.

Scope audit: `bits` is scoped to the single decomposition call, stated. Format-noun audit: "significand",
"exponent" and "mantissa" are defined by the normalisation clause rather than assumed.
Unbounded-promise audit: no clause promises an iteration count, a precision limit or a performance
bound. Example audit: the description carries no worked example, so no example can narrow a rule.

## 11b. Capability cross-product matrix

Axis 1 = value kind (integer / fractional). Axis 2 = context (`#d` directive / ruledef instruction
field / `#const` through the resolver).

| | `#d` directive | ruledef field | `#const` through resolver |
|---|---|---|---|
| **integer** | base behaviour, guarded | base behaviour, guarded | base behaviour, guarded |
| **fractional** | error, no inherent width | **off-diagonal: field built from `$mantissa`/`$exponent`** | **off-diagonal: fractional const in an address-dependent expression** |

Both off-diagonal cells have fixtures. Predicted failure mode is over-firing: the mantissa's size is
applied once by the builtin and again by the ruledef field, or the resolver re-promotes an
already-exact value on the second iteration.

## 12. Tier and category

Olympus (one tier). Category **feature-request** - the title verb is Add and the capability is
net-new public surface. Sub-rank target Good.

## 13. Predicted pass rate

**10-30%**, designed to the low edge. Reasoning: six traps, of which four sit on different axes and
three are interdependent through one kernel; the lead trap is a baseline regression whose failing
test is an existing fixture, which misdirects away from the feature entirely. Against that, the
contract is fully stated and a thorough agent can derive all of it, which is what keeps it off zero.
If the first batch reads above 50%, the lever is the empty cell in section 11b, not more rules.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 - pipeline is lexer -> expression parser -> value model -> evaluator ->
      iterative resolver -> output formatter; five subsystems `src/syntax`, `src/expr`, `src/asm`,
      `src/util`, `src/diagn`; entanglement zones are `expr/eval.rs`, `asm/resolver/`, `util/bigint.rs`;
      tests are fixture `.asm` files with inline expectation annotations parsed by `src/test/file.rs`;
      formatting template `tests/string_encoding/ok.asm`.
- [x] Phase 2 clean - `gh pr list -R hlorenzi/customasm --state all --search "<q>"` for
      float / fractional / fixed-point / ieee / mantissa / exponent / decimal returned **zero rows in
      every state**. Canonical org confirmed, no redirect.
- [x] Maintainer philosophy POSITIVE and on record - issue #233, hlorenzi 2025-12-01: the
      user-definable-encoding direction is "a very clean and flexible solution", and he proposes
      passing the precision to the decomposition so the expansion happens on demand. This design
      follows that direction rather than the built-in float library he was reluctant about in #92.
- [x] Self-collision clear - our three approved customasm problems hold resolver/bank layout, parser
      directives and decode. This is the numeric value model, which none of them touch.
- [x] Corpus dedup clear - no submission in `approved-problems/`, `problems/` or `rejected/` adds a
      numeric literal kind or a value model to any repo.
- [x] Death-class guard - not a uniform wrap (five distinct mechanisms), not a single-subsystem
      transform (six files across three subsystems), the difficulty survives full specification (the
      contract is stated and agents still have to build exact rational arithmetic and get the carry
      right), not a memorised port (IEEE-754 is *not* implemented here; the user writes the encoding
      in assembly and the assembler supplies exact decomposition).
- [x] LOC clears floor with margin - ~563 effective against a 275 target.
- [x] Traps name F-ids, sit on different axes, three interdependent through one kernel.
- [x] Cross-product matrix filled, both off-diagonal cells have fixtures.
- [x] No unbounded promise, no worked example, no enumerated wall list.
- [ ] **CORE-SLICE PRECHECK - OWED, and it gates everything downstream.** See below.

## Why this is not a duplicate

Closest approved siblings: `customasm-derived-bank-layout` (the iterative resolver settling address
quantities) and `numbat-parse-unit-expressions` (a numeric language's parsing surface). The
differentiator is the subsystem and the content: this adds a value KIND to the expression evaluator
with exact rational arithmetic and a rounding contract, touches none of the resolver's bank or
address machinery, and its difficulty is arithmetic exactness rather than fixpoint convergence.

## Predicted iteration cycles: 2

##  MANDATORY GATE BEFORE DIFFERENTIATING SCOPE

`olympus-author` Step 4b requires a platform CORE-SLICE PRECHECK, and this pick trips two of its
named triggers: the lane is **maintainer-invited, cold and PR-free**, and the repo already carries
three submissions of ours, which is the `TOO-EASY.md` "maintainer-invited, PR-free lane" derivative
shape. GitHub queries cannot see a rival author's submission; the precheck is the only instrument
that can.

Plan: build the minimal end-to-end slice first - fractional literal, exact value, `$exponent` and
`$mantissa` with the rounding contract, and the handful of fixtures that prove it - then stop and
hand it to the platform precheck. Only on a clean verdict do the arithmetic operators, the emission
rules, the resolver integration and the cross-product cells get written. Every line written before
that verdict is at risk, and no amount of added scope repairs a colliding core.
