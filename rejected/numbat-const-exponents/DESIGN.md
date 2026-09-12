# DESIGN.md — numbat-const-exponents

Base commit: `88b2e81a35d06942101d74e9b368081f02555f4f` (sharkdp/numbat, repo HEAD, 2026-03-13)

## 1. Title

**Evaluate dimension exponents as compile-time constants**

## 2. Shape classification

- **Shape:** O-Composite-extend (cross-section refactor of shared machinery), with an
  O-Algorithm-correctness core (exact rational exponents govern dimension type equality).
- **Pass band target:** <=40% ceiling, designing for 10-25%.
- **Best agent:** long-horizon Orion expected to be the lone passer (SPEED-CORRELATES-WITH-FAILURE).
- **Dominant verdict predicted:** MISSED_REQUIREMENT (parser-only fix clears the easy half), then
  REGRESSION (the refactor touches 13 `TypeExpression::Power` sites).
- **Span:** `parser.rs` (type grammar) + `ast.rs` (the `Power` variant) + `typechecker/` (const-eval
  with an environment) + `dimension.rs` (consumers). Genuinely cross-stage: resolution MOVES from
  parse time to check time.

## 3. Public API surface

No new public Rust API. The capability is observable entirely through numbat source that the
interpreter accepts or rejects, plus these existing diagnostics, which must keep their meaning:

- `ExpectedDimensionExponent` — the exponent is not a constant expression
- `NumberInDimensionExponentOutOfRange` — integer literal outside i128
- `DivisionByZeroInDimensionExponent` — zero denominator
- `NonRationalExponent` — the constant does not denote an exact rational
- `UnsupportedConstEvalExpression` — the expression is not const-evaluable

## 4. Canonical form (INVENTED — no issue, no PR, no maintainer request)

1. A dimension exponent is any expression that evaluates to an exact rational **at check time**.
2. The permitted forms are the ones const-evaluation already accepts at the value level: integer
   literals, unary minus, parentheses, `+`, `-`, `*`, `/`, and `^` between them.
3. A **name** bound to a constant may be used as, or inside, an exponent. It resolves to the value
   that name has where the annotation is written.
4. The same forms are accepted wherever a dimension exponent may appear: `dimension` declarations,
   `unit` definitions, `let` annotations and function signatures, and equally in a value expression
   such as `2 m^n`.
5. Exponents stay **exact rationals** throughout. A constant that is not an exact rational is
   rejected rather than rounded.
6. A name that is not a compile-time constant, or is used before it is bound, is rejected.
7. The unicode superscript form (`Length²`) keeps its current literal-only meaning.
8. Existing accepted programs keep their exact current behaviour, including every existing
   diagnostic for a malformed exponent.

## 5. Blind-spot pre-empts

- Pipeline placement: rule 1's "at check time" is the ONE sentence that makes trap A fair without
  naming where the resolution has to move.
- Falsy-on-invalid: rules 5 and 6.
- Compound/dual-path: rule 4's "and equally in a value expression".
- Iteration/ordering: rule 6's "used before it is bound".

## 6. Description draft

See `meta.md`. Plain prose, target 300-400 words (hard cap 500). Rule-7 discipline: state the
PRINCIPLE (an exponent is a constant expression evaluated at check time) and never enumerate the
instance list of operators, surfaces or interaction cases.

## 7. File footprint (sketched against real source)

| Action | Path | Current | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | `numbat/src/ast.rs` | 349+ | +35 | ~22 | `TypeExpression::Power` carries an expression, not an `Exponent` |
| MODIFY | `numbat/src/parser.rs` | ~2000 | +110 | ~75 | `dimension_exponent` stops computing a value and builds an expression; error paths move |
| MODIFY | `numbat/src/typechecker/const_evaluation.rs` | 118 | +95 | ~70 | environment parameter, name resolution, exact-rational guard |
| MODIFY | `numbat/src/typechecker/mod.rs` | ~1400 | +90 | ~60 | thread the constant environment; evaluate type-level exponents at check time |
| MODIFY | `numbat/src/dimension.rs` | — | +45 | ~30 | consumers of `Power` take the evaluated exponent |
| MODIFY | `numbat/src/typed_ast.rs` | — | +25 | ~16 | typed form of the exponent |
TOTAL: ~+400 raw / **~273 meaningful** across 6 modified files.

Clears the >=200 floor with buffer; >=2 files satisfied. **The machinery is genuinely missing**, which
is the LOC-carry check: `evaluate_const_expr(expr)` takes NO environment, and
`TypeExpression::Power` stores a concrete `Exponent`, so neither named constants nor deferred
evaluation is expressible today. This is new machinery, not a call-through.

## 8. Solution outline — helpers

- `const_env_from_scope(...)` — the constant environment the exponent evaluator consults.
- `evaluate_const_expr(expr, env)` — existing function, gains the environment (rule 3).
- `exact_rational(value) -> Option<Exponent>` — replaces the f64 round-trip (rule 5).
- `type_exponent(expr, env) -> Result<Exponent>` — check-time entry point for type-level exponents.
- Parser: `dimension_exponent` returns an expression; the three parse-time exponent errors become
  check-time errors raised from the evaluator.

## 9. Test file outline

Path: `numbat/tests/const_exponents_<hex>.rs`, alongside the existing `numbat/tests/interpreter.rs`
(the conventional integration location). Harness mirrors `interpreter.rs`.

Buckets: literal parity (existing forms still work) · arithmetic at type level · named constant at
type level · named constant at value level · exactness rejection · non-constant rejection ·
use-before-binding · each surface (dimension decl, unit def, let annotation, fn signature) ·
unicode superscript unchanged · dimension equality after a computed exponent.

## 10. Forced bounds

`TypeExpression::Power`'s exponent field changes type, which forces every one of the **13 match
sites across `ast.rs`, `parser.rs`, `dimension.rs`** to be updated. That is the cross-section
pressure (A1, gimli precedent) and needs no description support.

## 11. Predicted trap matrix (to be REPRODUCED before tests are written)

| # | Trap | Axis | F-id / Arsenal | Why agents hit it | Pre-empt sentence |
|---|---|---|---|---|---|
| **A** | **Resolution must move from parse time to check time.** | WHERE the exponent is resolved | F-9 / A1 | ⭐ The easy half is solvable in the WRONG place: `1+1` IS computable during parsing, so a parser-only fix passes every arithmetic test and then cannot do named constants at all, because names are unknown to the parser | rule 1 "at check time" |
| **B** | Value level and type level are separate code paths that must both gain the environment | WHICH path | S5 dual-path | `2 m^n` goes through `evaluate_const_expr`; `Length^n` goes through the parser's mini-parser. Fixing one leaves the other | rule 4 |
| **C** | Exponents must stay EXACT rationals | exactness | A12 / F-11 | `to_rational_exponent` routes through `f64`; a computed `1/3` becomes 0.333... and dimension equality silently fails | rule 5 |
| **D** | Cross-product of {arithmetic, named constant} x {type level, value level} | composition | F-10 | Off-diagonal cells over-fire or are simply never probed | rules 2+3+4 |
| **E** | Existing accepted programs and diagnostics must survive the refactor | baseline | S3 | 13 `Power` sites; a wrong refactor regresses the existing suite | rule 8 |

Interdependence: A and B share the resolution chokepoint (moving resolution to check time is what
makes B fixable at all); C rides whatever A produces; E fires on any wrong A.

## 11b. Cross-product matrix (F-10)

| | type level `Length^…` | value level `2 m^…` |
|---|---|---|
| **arithmetic `(1+1)`** | currently REJECTED, must work | currently works, must keep working |
| **named constant `n`** | currently rejected, must work ← off-diagonal | currently rejected, must work ← off-diagonal |
| **named inside arithmetic `(n+1)`** | ← off-diagonal, both mechanisms at once | ← off-diagonal |

## 12. Tier + category

- Tier: Olympus. Category: **feature-request** (title verb Evaluate/Add; net-new capability).

## 13. Predicted pass rate

10-25%. Trap A is a single insight a strong agent can reach, keeping it solvable; B, C and E are
independent discriminators a passing run must also clear.

## 14. Quality gate

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement, test layout, template file)
- [x] Phase 2 searches run: no PR implements computed or named exponents (`exponent`, `const eval`,
      `dimension exponent`, `type annotation`, all states); #614 "Allow units with rational
      exponents" is MERGED and is the EXISTING literal-rational support, not this
- [x] Self-collision: zero file overlap with approved `numbat-parse-unit-expressions`
      (`parse_quantity.rs` + `ffi/functions.rs` + `quantities.nbt` vs typechecker + parser)
- [x] LOC carry named: missing machinery is the const-eval environment and the deferred exponent
- [x] Traps on 5 different axes, A-B-C-E interdependent
- [x] F-10 matrix filled, off-diagonal cells identified
- [ ] **OWED: reproduce every trap** (write the natural-but-wrong impl, confirm misdirecting symptom)
- [ ] **OWED: F-12 decision** (below) settled before any code
- [ ] **OWED: 3x determinism on numbat's existing suite**
- [ ] **OWED: maintainer-philosophy scan** for a statement that exponents are deliberately literal
- [ ] **OWED: Docker validation** — no local Docker; static check only, carried to the platform run

## F-12 audit (mandatory, decided ONCE here)

`parser.rs` carries 2 inline `#[cfg(test)]` modules and `typechecker/mod.rs` carries 1. Moving the
three exponent diagnostics from parse time to check time INVALIDATES any inline parser test that
asserts a parse-time exponent error.

**Decision: keep the axis, scoped narrowly.** Base mode skips ONLY the individual inline parser
tests that assert a parse-time exponent error, named explicitly in `feedback.md` once enumerated
against the real file. Do NOT skip either module wholesale (removes the axis, draws a High review
finding). Do NOT relocate the tests (a test-only patch may not touch `src/`, and deleting them in
`solution.patch` breaks our own p2p identity).

## Why this is not a duplicate

Closest prior art is our own accepted `numbat-parse-unit-expressions`. That one adds RUNTIME
builtins (`parse`, `unit_from`, `value_in`) that read unit expressions out of STRINGS, and it lives
entirely in `parse_quantity.rs`, `ffi/functions.rs` and a `.nbt` module. This one changes WHEN and
WHERE a dimension exponent is resolved inside the compiler, and lives entirely in the parser, the
AST and the typechecker. Zero file overlap, different lifecycle stage, different user-visible
feature. The centre of gravity is deliberately the type system (exact rationals, a const-eval
environment, dimension equality) rather than grammar breadth, so the one-line summary reads as a
type-system capability and not a second grammar extension.

Predicted iteration cycles: 2-3.
