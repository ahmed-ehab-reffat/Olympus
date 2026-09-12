# DESIGN.md — numbat-parse-unit-expressions

Base repo: sharkdp/numbat @ `88b2e81a35d06942101d74e9b368081f02555f4f` (2026-03-13, == origin/master tip)

## 1. Title

**Extend the parse builtin to accept unit expressions**

## 2. Shape classification

- Shape: **O-Composite-add** (SHAPES.md § Pattern 12) — one capability generalised across a
  restricted parser, a validator, a type evaluator, a value evaluator and the FFI boundary.
- Pass rate target: <=40% ceiling (sprint), design target 10-25%.
- Best agent: mixed; expect Orion to be the load-bearing solver (AGENT-MIX law).
- Dominant verdict: MISSED_REQUIREMENT.
- Long-horizon: >=200 effective LOC, >=2 files, >=40 solver-median messages.

## 3. Public API surface

No new user-facing names. The change is the accepted input language of an existing builtin plus
the errors it raises.

- `parse<T: Dim>(input: String) -> T` — existing builtin (`numbat/modules/core/functions.nbt`);
  its accepted string grammar widens.
- `QuantityLiteralError::ParseError` — input is not parseable numbat source.
- `QuantityLiteralError::InvalidPattern` — parseable, but not a quantity literal.
- `QuantityLiteralError::NameResolutionError` — an identifier in the string is not a known unit.
- The runtime dimension mismatch surfaces as the existing `Type mismatch: expected X, got Y`
  user error from the FFI wrapper.

## 4. Canonical output form

- A quantity literal is: an optional leading minus, one number, and an optional unit expression.
- A unit expression is built from unit names, `*`, `/`, `^`, and parentheses. `kg m` (juxtaposition)
  means the same as `kg * m`.
- Exponents are integers or rationals; negative and parenthesised rational exponents are allowed
  (`s^-1`, `m^(1/2)`). Exponents are exact rationals, not floats.
- A prefix binds to the unit name it is written on, and the exponent applies to the prefixed unit:
  `1 km^2` is `1e6 m^2`, not `1e3 m^2`.
- The number may be followed directly by a division (`5 /s` is five reciprocal seconds).
- The parsed dimension must equal the annotated dimension. Unit identity is not required:
  `km/h` and `m/s` both satisfy `Velocity`.
- A quantity literal carries exactly one number and it comes first. A second number anywhere,
  including inside a denominator, is rejected. `unit_from` mirrors this: it takes exactly the unit
  expressions a quantity literal may carry and rejects any input carrying a number.
- Zero keeps the repo's existing exemption (a zero satisfies any annotation). See § 11 trap 2.
- Rejected with `InvalidPattern`: arithmetic between quantities (`1 km + 500 m`), a second numeric
  factor (`2 * 3 m`), function calls (`sin(1)`), comparisons, and plain variables.
- Errors are reported as the existing user-error string; tests substring-match 1-3 stable keywords.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

- Compound-order preservation -> "the exponent applies to the prefixed unit" (pre-empts the
  prefix-before-power reading).
- Compound-order preservation -> "A quantity literal carries exactly one number and it comes
  first" (pre-empts both the second-number reading and `unit_from`'s mirror).
- Rule-reference resolution -> "temperature units written with the degree sign are accepted in the
  same forms the language accepts elsewhere" (pre-empts the transformer-reshape trap WITHOUT
  naming the rewrite).
- Codebase-inferable count: **1** (that unit identifiers are resolved by the same prefix machinery
  the rest of the language uses).

## 6. Description draft (meta.md, 290 words as shipped)

Body opens with the ask (`Add support for whole unit expressions to the parse builtin ...`) plus one
sentence of motive (which quantity shapes are out of reach today), states the current
single-unit restriction second, then: the unit-expression grammar; juxtaposition equals
multiplication; exponents are exact rationals and may be negative or parenthesised; a prefix binds
to the name it is written on and the exponent applies to the prefixed unit; a number may be
followed directly by a division; the dimension must match the annotation while the unit need not;
a literal carries exactly one number and it comes first; degree-sign temperatures are accepted in
the same forms as elsewhere in the language; the rejected shapes stay rejected; and `unit_from`
reads a unit expression with no number and is the inverse of `unit_name`. No `##` headers, no
labels, ASCII only.

## 7. File footprint

AS BUILT (measured, not sketched):

| Action | Path | Reason |
|---|---|---|
| MODIFY | `numbat/src/parse_quantity.rs` | shared single-expression parse, recursive validator with the number-position parameter, dimension walk, value walk, exponent extraction, temperature expansion, `parse_unit_literal` |
| MODIFY | `numbat/src/ffi/functions.rs` | `unit_from` builtin + registration |
| MODIFY | `numbat/modules/core/quantities.nbt` | `unit_from` declaration, description and examples |

TOTAL: raw 439 / counter1 342 / **human-effective 280** across 3 modified files. `numbat/src/unit.rs`
was NOT needed: `Product`'s existing `Mul`/`Div`/`power` already bind the prefix before the exponent,
so `1 km^2` comes out right without a new helper.

## 8. Solution outline — pure-function helpers

- `is_valid_quantity_literal(expr) -> bool` — top level: optional negate, one scalar, optional
  unit expression attached by `Mul` or `Div`. (requirement: rejected shapes)
- `is_valid_unit_expression(expr) -> bool` — recursive over `Mul`/`Div`/`Power`/identifier.
- `unit_exponent(expr) -> Result<Exponent>` — integer, negative and rational exponents, exact
  `Ratio<i128>`, never `f64`. (requirement: exponents are exact rationals)
- `unit_expression_type(expr, typechecker) -> Result<DType>` — `multiply` / `divide` / `power`
  over the typechecker's declared dimension per unit name. (requirement: dimension match)
- `unit_expression_value(expr, unit_lookup) -> Result<Unit>` — the same recursion over `Unit`
  products, `invert`, and the prefixed power helper. (requirement: prefix binds to its name)
- `validate_unit_expression(expr, number_allowed) -> Option<bool>` — one recursion carrying the
  number-position rule; `parse` requires `Some(true)`, `unit_from` requires `Some(false)`.
  (requirement: exactly one leading number / no number)
- `parse_unit_literal(...)` — the `unit_from` entry point, reusing both walks.

No fixpoint loop applies. The three recursions share one shape grammar, defined once as a helper
predicate so the validator and both evaluators cannot drift.

## 9. Test file outline

Path: `numbat/tests/unit_expressions_c41868.rs` (46 tests), styled on `numbat/tests/interpreter.rs`
(program-string in, printed result or error substring out — behavioural, no mocks).

- Block 1 imports; Block 2 builder helpers (`expect_parse`, `expect_parse_error`); Block 3
  assertion helpers (substring match on the user-error text); Block 4 tests by bucket.
- Buckets: single unit (regression) · products · quotients · integer powers · negative and
  rational powers · prefixes across every form · leading division · dimension match vs unit
  identity · degree-sign temperatures · `unit_from` and its mirrored number rule · rejected shapes ·
  edge cases (empty string, whitespace, unknown unit, user-defined units, context pollution).
- Every one of the 46 is a true f2p: the 12 that passed on base were combined with a
  new-capability assertion on the same theme (Pattern 74). Verified 46/46 fail on base.
- 5-axis coverage: every meta sentence, the builtin's surface, every branch of the three
  recursions, edge cases, and the stated inverse (accepted vs rejected shapes).

## 10. Forced trait bounds

`Exponent = Ratio<i128>`; the exponent extractor must not route through `f64` or `m^(1/3)` loses
exactness. `DType::power` and `Product::power` both take `Exponent`, so the whole path stays
rational. `unit_lookup` is `impl Fn(&str) -> Option<Unit>` — the recursion must take it by
reference to stay callable from every arm.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | **Validator and evaluators see different trees.** `parse_quantity_ast` validates the RAW AST; `transform_expression` then runs and can RESHAPE it (identifier -> `UnitIdentifier`, and `-5 °C` -> a `FunctionCall`). Extending both sides over one shape grammar still fails. | F-9 | S6 | stage boundary | #2 (the fix relocates what "carries a unit" is computed from) | Nothing names the transformer. Symptom is `Unexpected expression type` from the evaluator on an input the validator accepted — reads as an evaluator bug. Reproduced on base: `parse("-5 °C")` does exactly this today. | "degree-sign temperatures are accepted in the same forms the language accepts elsewhere" | `temperature_degree_sign_negative_parses` |
| 2 | ~~Zero keeps its exemption~~ **CONCEDED AND REMOVED AT BUILD TIME.** `numbat/tests/interpreter.rs:1191` pins `parse("0 kg")` as a `Length` returning 0, under the comment "Zero is compatible with any type". Contradicting the repo's own committed behaviour is a fairness bug, not difficulty (L19). Replaced by the mirrored number rule below. | — | S2 | number position | #1 (same `number_allowed` parameter) | `parse` rejects a unit expression with no number and `unit_from` rejects one carrying a number; both fall out of one parameter, so a naive fix to either regresses the other. | "A quantity literal carries exactly one number and it comes first" + "rejects any input carrying a number" | `a_unit_expression_without_a_number_is_rejected_by_parse_but_taken_by_unit_from` + `unit_from_rejects_a_literal_carrying_a_number` |
| 3 | **Prefix vs exponent binding.** `1 km^2` must be `1e6 m^2`. GIVEAWAY REMOVED: the meta no longer states the worked example. Applying the prefix factor once at the top, or after the power, gives `1e3`. | F-10 | S2 | numeric composition | #4 (same recursion) | Both readings look right; `Unit::with_prefix` sets the prefix on one factor and the exponent is applied later inside `to_base_unit_representation`. | "the exponent applies to the prefixed unit" | `prefixed_unit_squared_scales_by_prefix_squared` |
| 4 | **Leading division.** `5 /s` parses as `Div{Scalar, Identifier}`, not `Mul`. | — (A8) | A8 | grammar shape | #3 | The natural validator special-cases `Mul` with a scalar lhs and never revisits `Div`. | "a number may be followed directly by a division" | `leading_reciprocal_parses` |

Every row's contract sentence states WHAT and none hands the fix (CONTRACT-STATED / FIX-HIDDEN).
Rows 1 and 2 share a chokepoint; rows 3 and 4 sit on different axes from both.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = unit-expression form. Axis 2 = prefix presence.

| | plain unit | prefixed unit |
|---|---|---|
| **single** | `parse("3 m")` | `parse("1.5 km")` (base regression) |
| **product** | `parse("2 kg m")` | `parse("2 g mm")` <- off-diagonal |
| **quotient** | `parse("100 m/s")` | `parse("100 km/h")` <- off-diagonal |
| **power** | `parse("3 m^2")` | `parse("1 km^2")` <- **off-diagonal, the decider** |
| **quotient of powers** | `parse("5 kg/m^3")` | `parse("5 g/mm^3")` <- off-diagonal |

Predicted failure mode in the off-diagonal cells is a WRONG VALUE (prefix applied once, or before
the power), not a missing feature — which is what makes it misdirecting.

## 12. Tier + category

- Tier: Olympus (one tier).
- Category: **feature-request** — the title verb is Add, the body opens with Add, and the change
  introduces a new capability plus the new `unit_from` name. Verb and category agree.
- Measured at 188 across 1 file without the axis, so the co-equal axis was taken: `unit_from`, the
  inverse of the repo's existing `unit_name`, reading a unit expression with no number. Final
  measurement 280 across 3 files.

## 13. Predicted Nova pass rate

- Predicted 10-25%. Trap 1 is architecture-shaped and reproduced on base; traps 3 and 4 are
  cheap-to-miss composition cells; trap 2 is a baseline-preservation regression.
- Risk of overshoot toward 0% is low: every trap has a stated contract sentence and the repo's own
  `interpreter.rs` tests demonstrate the idioms.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (pipeline, subsystems, entanglement zones, test framework, template file)
- [x] Existing-PR check: #796 and #815 build the single-unit `parse`; issue #813 CLOSED as done;
      no PR or issue covers compound units; searches recorded in feedback.md
- [x] Gate 1 behavioral-f2p-gap reproduced on base (five failing forms captured)
- [x] Gate 5: `parse_quantity.rs` untouched since creation (2026-01-25); repo quiet since 2026-03-13
- [x] Gate 7 dedup: differentiated from our approved `numbat-const-exponents` below
- [x] Gate 9: baseline deterministic across 2 runs (one tzdata-dependent example test to scope)
- [x] Gate 10: numbat holds 1 of our 6 submissions
- [x] Title verb-led, names the subsystem
- [x] Canonical form spelled out (§ 4)
- [x] <=1 codebase-inferable requirement
- [x] Traps name F-ids, sit on different axes, two are interdependent
- [x] § 11b filled, every off-diagonal cell has a test
- [x] **LOC measured: human-effective 280 across 3 files** (188 across 1 file before the co-equal axis)
- [x] Tests written (46, all f2p) · solution written · patches generated · clean room both orders · flakiness 3x
- [ ] Dockerfile build + offline non-root run (stopped on request; the one outstanding step)
- [ ] FP check (runs after the first agent batch)

## Why this is not a duplicate

Closest prior art is our own **numbat-const-exponents** (APPROVED Mars 2026-07-09): named `let`
constants usable as exponents in dimension and unit DEFINITIONS, implemented in the parser,
typechecker and dimension registry, with a type-equality-gate-vs-const-eval trap. This problem
touches none of that: it is a RUNTIME string-parsing capability in `parse_quantity.rs` and the FFI
boundary, its traps are a stage-boundary tree mismatch, a mirrored number-position rule, and a
prefix-vs-exponent composition cell, and its observable is the `parse()` builtin rather than a
declaration. The overlap is the repo and the fact that units have exponents. Differentiators to
keep prominent: different subsystem, different trap family, different failure surface.

**Predicted iteration cycles: 3**
