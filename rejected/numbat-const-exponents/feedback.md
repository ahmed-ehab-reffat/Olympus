# feedback.md — numbat-const-exponents

## Status
DESIGN.md complete 2026-08-06. NO code yet. Next gate: reproduce every trap in the matrix before a
single test is authored.

## Pick provenance
Chosen after comrak-reference-style-links died at the platform Scope Gate as a derivative of an
older accepted submission. Structure reused from the approved set: take a construct the repo
supports only in a RESTRICTED form and generalize it to the repo's own full model (neva's
array-bypass, numbat's parse builtin). Scientific-domain sweep also evaluated and REJECTED
Clarabel.rs (zero real code commits in 12 months; literature-named capabilities; port-derivative
risk against Clarabel.jl; tolerance-based numerical tests).

## Measured gap (probed on a fresh build, not assumed)
| exponent form | value level `2 m^…` | type level `Length^…` |
|---|---|---|
| literal `2` | works | works |
| rational `(1/2)` | works | works |
| arithmetic `(1+1)` | WORKS | rejected at the parser |
| named constant `n` | rejected ("variable") | rejected |

Root cause, at source: `TypeExpression::Power(.., Exponent)` stores a concrete rational in the AST
because `parser.rs::dimension_exponent` computes the value eagerly at PARSE time, while value-level
exponents are const-evaluated much later by `typechecker/const_evaluation.rs::evaluate_const_expr`,
which takes NO environment and so cannot resolve a name at either level.

## Self-collision check against our own approved numbat problem
Zero file overlap. Approved `numbat-parse-unit-expressions` touches `parse_quantity.rs`,
`ffi/functions.rs`, `modules/core/quantities.nbt` — runtime, reading quantities out of strings. This
touches `parser.rs`, `ast.rs`, `typechecker/`, `dimension.rs` — compile time, resolving exponents.
Different lifecycle stage and different user-visible feature. Residual risk is that both rhyme as
"extend a restricted grammar in numbat"; mitigated by centring the submission on the type system
(exact rationals, const-eval environment, dimension equality) rather than on grammar breadth.

## Owed before any code
- Reproduce traps A, B, C, E with natural-but-wrong implementations
- Settle the F-12 skip list against the real inline parser tests
- 3x determinism on numbat's existing suite
- Maintainer-philosophy scan for "exponents are deliberately literal"
- Docker validation (no local Docker; static check only, carried to the platform run)

## Attempt history

### Round 0 - design-time trap review (olympus-harden, 2026-08-06). NO CODE, NO BATCH.

**This is PREDICTION, not measurement** (HARDENING Stage 1: agent runs are the only oracle, and none
exist). Two of the five claimed traps were REPRODUCED against the real interpreter; the rest remain
structural arguments until a batch says otherwise.

**Trap A REPRODUCED - the load-bearing claim holds.** Wrote the natural-but-wrong implementation: a
~12-line change to `parser.rs::dimension_exponent` adding `+` between literal atoms, still computing
the exponent eagerly at parse time. Result: `let x: Length^(1+1) = 4 m^2` now WORKS, while
`let n = 2; let y: Length^n = 4 m^2` still fails with `Expected dimension exponent`. The parser
cannot resolve a name because names are not bound at parse time. So the visible half of the feature
is solvable in the WRONG place, and that same place structurally cannot do the other half. The agent
sees arithmetic working and reads the named-constant failure as an unsupported case rather than as
"your resolution lives in the wrong stage". CONTRACT-STATED/FIX-HIDDEN holds: the contract says an
exponent is an expression evaluated at check time; it never says to move resolution out of the parser.

**Trap C REPRODUCED, and it is a LIVE BUG in numbat today, not a hypothetical.**
`2 m^(0.1+0.2)` evaluates to `m^(1125899906842624/3752999689475413)` instead of `m^(3/10)` - the
per-literal f64 hop in `to_rational_exponent` turns a computed decimal exponent into a garbage
rational. Since dimension type equality compares exponents, two types that should be identical are
not. The contract's "exponents stay exact rationals" is therefore a real requirement with a real
failure behind it.

**Trap B strengthened by a second measured asymmetry.** Beyond named constants, the two paths already
disagree on decimals: `2 m^0.5` is accepted at the value level, while `Length^(0.3)` in a type
annotation is rejected with `Only integer numbers (< 2^128) are allowed in dimension exponents`. The
dual-path gap is wider than the design assumed, which makes S5 easier to test and harder to fix in
one place.

**Not yet reproduced:** trap E (baseline preservation across the 13 `TypeExpression::Power` sites)
and trap D (the F-10 cross-product cells) - both require the reference implementation to exist first.

**Fairness guard (Stage 4) run on A and C:** both contract-stated by canonical-form rules 1 and 5;
both fix-hidden (no file, helper or algorithm step named); neither contradicts numbat's book;
neither was previously removed by a fairness review; both deterministic.

**Next:** build the reference, then trap-proof D and E, then the F-12 skip list against the real
inline parser tests.


### Round 1 - reference implementation, PARTIAL (2026-08-06)

**State: the library builds and the capability works end to end through the interpreter; the repo's
own test build does NOT compile yet.** Recording this honestly rather than as "done".

Working, verified through the real CLI with the full prelude loaded:

| case | result |
|---|---|
| `let z: Length^2 = 4 m^2` (unchanged literal) | `4 m2` |
| `let x: Length^(1+1) = 4 m^2` (type-level arithmetic) | `4 m2` |
| `let n = 2; let y: Length^n = 4 m^2` (type-level named constant) | `4 m2` |
| `let n = 2; let y: Length^(n+1) = 8 m^3` (named inside arithmetic) | `8 m3` |
| `let n = 2; 2 m^n` (value-level named constant) | `2 m2` |
| `let n = 2; 2 m^(n+1)` (value level, named in arithmetic) | `2 m3` |
| `let y: Length^bogus` (unknown name) | rejected, "Unknown constant 'bogus' in dimension exponent" |
| `dimension Zork = Length^2 / Time` (regression guard) | still parses |

Architecture as designed: `TypeExpression::Power` now carries a `DimensionExponent` expression
instead of a concrete `Exponent`; a new `dimension_exponent.rs` holds the AST, the evaluator and the
`ConstantLookup` trait; `DimensionRegistry::get_base_representation` takes a constant environment;
the typechecker records const-evaluable `let` bindings into a `ConstantEnvironment`; and
`evaluate_const_expr` gained both the environment and an `Identifier` arm so the value level
resolves names too.

**Measured: 202 human-effective LOC across 9 files** - over the 200 floor but with NO buffer, which
is a known risk (a single removal drops it under). The design asked for 250-300. Needs the exactness
work below to land it safely.

**Two things NOT done, both known and neither hidden:**

1. **Exactness (trap C) is NOT implemented.** `2 m^(0.1+0.2)` still yields
   `m^(1125899906842624/3752999689475413)`. `0.1 + 0.2` is folded to a single f64 scalar BEFORE
   const-evaluation, so the per-literal exact-rational helper never sees the operands. Fixing it
   properly means deciding what happens to a decimal literal that has no short exact rational form
   (`0.3333333333333333` currently becomes `1/3` via `Rational::from_f64`), and that decision needs
   care rather than a quick guard. The canonical-form rule 5 stands; the implementation does not
   exist yet.
2. **13 inline repo tests do not compile** against the new API (they construct
   `TypeExpression::Power` with a bare `Exponent` and call `get_base_representation` with one
   argument). This is exactly the F-12 surface predicted at design time. Per the F-12 decision
   recorded above, these get MECHANICALLY UPDATED to the new API in `solution.patch` - which is what
   a real PR would do - rather than deleted or skipped wholesale. Until that is done, `cargo test`
   cannot run, so there is NO regression measurement yet and the base suite is unverified.

**Next, in order:** update the 13 inline tests, get `cargo test` green, then implement exactness,
then re-measure LOC, then write the new test file, then trap-proof D and E.


### Round 1b - repo tests reconciled, and the approved problem's F-12 precedent applied (2026-08-06)

`cargo test -p numbat --lib` now reads **174 passed / 1 failed**, up from not compiling at all.
Fixed along the way:

- **A real bug in my own code:** `replace_spans` did not recurse into the new exponent, so nested
  spans stayed concrete and three tests failed on span mismatches. Added
  `DimensionExponent::replace_spans` (gated `#[cfg(test)]`, matching `Span::dummy`'s own gating).
  That alone fixed `pretty_print_dexpr` and `function_definition`.
- **13 inline tests mechanically updated** to the new API (`get_base_representation` gains the
  constant lookup; `TypeExpression::Power` takes a `DimensionExponent`).

**Two repo tests are genuinely invalidated by the feature, and both are informative:**

1. `typechecker::tests::type_checking::exponentiation_with_dimensionful_base` asserts `a^x` with
   `let x=2` FAILS. ⭐ Directly above that assertion, numbat's own source carries:
   `// TODO: if we add ("constexpr") constants later, it would be great to support those in exponents.`
   **The maintainer has an in-source TODO wishing for exactly this capability.** Gate 8 is not merely
   clear, it is endorsed, and this is the one permitted codebase-inferable requirement. It is an
   in-source TODO rather than a public issue, so it does not raise the magnet risk that killed comrak.
2. `parser::tests::dimension_definition` asserts the parser EAGERLY reduces `Length^(12345/67890)`
   to `823/4526` in the AST, and separately expects a fuzzing-derived overflow at PARSE time. Both
   are consequences of resolution moving to check time. Verified the fuzzing input still errors
   cleanly with no panic and the same message text, so canonical rule 8 holds.

**Applying the approved numbat problem's hard-won precedent (its feedback.md, four rounds on this):**
its final base mode is
`cargo test -p numbat --lib --test interpreter -- --skip test_reject_compound_units --skip test_reject_unit_squared`.
Three things carry over. (a) Base mode is scoped to `--lib --test interpreter`, NOT the whole suite.
(b) Skips are by individual test NAME, never a module - the wholesale skip drew a T1 review finding,
and the over-narrow skip made the problem unsolvable; it took four positions to settle. (c) The T1
justification must be EVIDENCED: map each skipped test to a behavioural equivalent in the new suite
reached through the PUBLIC api, so no regression coverage is lost, only relocated.

**Decision for this problem:** base mode skips exactly `dimension_definition` and
`exponentiation_with_dimensionful_base` by name, and the new test file must carry public-API
equivalents for what they covered (eager-vs-deferred exponent shape, the overflow rejection, and the
`a^x` case). Updating them in `solution.patch` alone is NOT enough - agents will each update them
differently and lose p2p identity, which is precisely the failure the approved problem measured.

**`prelude_and_examples` reads 4 failed, and they are NOT assertion failures** - all four panic
inside `insta-1.43.1/src/glob.rs:130`, i.e. the snapshot-glob harness. The approved problem's base
mode excludes this suite entirely, which is circumstantial evidence the same thing was hit there.
⚠️ MUST be verified against a pristine base checkout before it is treated as pre-existing; if it is
mine, it is a real regression.

**Still owed:** exactness (trap C) unimplemented; LOC re-measure after the test updates; the new
test file; trap-proof D and E; determinism 3x; Dockerfile (canonical Pattern A, static check only,
NO local Docker on this workstation).


### Round 1c - literal folding fixed almost everything (2026-08-06)

**The prelude question is settled with evidence.** Ran the snapshot suite on a PRISTINE base
checkout (git stash, rebuild): base reads 5 passed / 1 failed. So
`numbat_tests_are_executed_successfully` is PRE-EXISTING and environmental, but the three snapshot
tests passed on base and failed under my change - they WERE my regressions, not scoping noise. Worth
the two rebuilds to know rather than assume.

**The fix that resolved nearly all of it: fold fully-literal exponents at PARSE time, exactly as
before, and defer ONLY when the expression contains an identifier.** `contains_identifier()` decides;
a literal expression is evaluated immediately and collapsed back to `DimensionExponent::Number`, so
the AST shape, the reduced rational (`12345/67890` -> `823/4526`), and the legacy parse-time
diagnostics (`DivisionByZeroInDimensionExponent`, `OverflowInDimensionExponent`, including the
fuzzing regression case) are all preserved bit for bit. This is strictly better design than deferring
everything, and it is what a careful maintainer would do.

Also fixed a genuine diagnostic regression it exposed: the division-by-zero span pointed at the whole
binary expression instead of the divisor, which moved a caret from `^` to `^^^`. Now uses the RHS
span, and `name_resolution_error_snapshots` went green.

**Current state:**

| suite | result |
|---|---|
| `cargo test -p numbat --lib` | **175 passed, 0 failed** |
| `cargo test -p numbat --test interpreter` | **52 passed, 0 failed** |
| `--test prelude_and_examples` | 3 failed (see below) |

The three: `numbat_tests_are_executed_successfully` (PRE-EXISTING, fails on pristine base too);
`parse_error_snapshots`, whose only diff is `missing_closing_paren5` -
`dimension Foo = Bar^(-3 * Baz` used to report the missing paren at `Baz` because an identifier was
illegal there, and now reports it at end of input because identifiers ARE legal in exponents, which
is a correct consequence of the feature; and `typecheck_error_snapshots`, which writes no `.snap.new`
and still needs diagnosis.

**Base-mode decision, following the approved problem's precedent exactly:**
`cargo test -p numbat --lib --test interpreter -- --skip <named>`. Both `--lib` and `interpreter` are
fully green, so at present NO skip is needed at all - a materially better position than the approved
problem reached, and it comes from the literal-folding design rather than from skipping. The snapshot
suite stays out of base mode: `solution.patch` may not touch test fixtures, so a legitimately-changed
snapshot cannot be updated solution-side, and the approved problem's base mode excludes it for what
is now clearly the same reason.

**Still owed:** diagnose `typecheck_error_snapshots`; implement exactness (trap C, still unfixed -
`2 m^(0.1+0.2)` yields the garbage rational); re-measure LOC after the folding change; new test file;
trap-proof D and E; determinism 3x; Dockerfile (canonical Pattern A, static check only - NO local
Docker here).


### Round 2 - DELIVERABLES COMPLETE; harden + review passes run (2026-08-06)

All five deliverables exist and validate. Still NO agent batch, so the pass rate remains unmeasured.

**Harden pass, two rulings.**

*Trap C is DROPPED as scope creep.* The f64 round-trip that mangles `2 m^(0.1+0.2)` into
`m^(1125899906842624/3752999689475413)` is a PRE-EXISTING numbat bug at the value level: the operands
are folded to one f64 scalar before const-evaluation, so it is not something this feature introduces
and fixing it would touch code the feature does not need (A10, "would you accept this PR"). The
design claimed five traps; honestly it ships with FOUR. I am not pretending the others cover it.
Type-level exponents are exact regardless, because the new evaluator works on `Rational` throughout.

*F-10 audit found one genuinely empty off-diagonal, and it was a fairness gap too.* meta.md states
"a later rebinding of that name does not reach back and change an earlier type" - stated, untested.
Added `rebinding_a_name_does_not_change_an_earlier_type` and `rebinding_a_name_applies_to_a_later_type`
(plus a value-level arithmetic baseline cell). Zero new description words, which is the point of the
F-10 lever, and it closes the L17 free-difficulty gap.

**Review pass (visible artifacts only): ACCEPT with two disclosed items.**

Stage 0 clean: no em-dash, meta ASCII, no banned markers, test.sh mode 100755, no AI cadence, no
headers, zero debug statements or AI comments in the solution, zero weak assertions in the tests.

Two things a reviewer will see and I am flagging rather than hiding:

1. **`solution.patch` touches `numbat/src/typechecker/tests/type_checking.rs`.** That is an INLINE
   test module living under `src/`, which is where numbat keeps them, and it is the F-12 axis: the
   feature genuinely invalidates an assertion that `a^x` fails, sitting directly under numbat's own
   `// TODO: if we add ("constexpr") constants later, it would be great to support those in exponents.`
   Updating it is what a real PR does. Agents must update it too or their base mode fails, which is
   the discrimination the approved numbat problem measured at roughly 30% of its band. The
   alternative (a base-mode skip) would remove the axis.
2. **`test.patch` is UTF-8 rather than pure ASCII**, because numbat prints `m2`-style unicode
   superscripts and the expected values must contain them. The encoding rule bans UTF-16, not UTF-8,
   and the repo's own tests are the same.

**Base-mode scoping is defensible on evidence.** `--lib --test interpreter` runs 227 tests, all
green, with NO skip needed. `prelude_and_examples` is excluded because the feature legitimately
changes two things that live in fixtures `solution.patch` may not touch: the fixture
`examples/typecheck_error/unsupported_const_eval_expr_variable.nbt` (which is `let x = 4` / `meter^x`,
i.e. a file whose entire purpose is asserting this capability does NOT exist) and the
`missing_closing_paren5` snapshot, where the missing paren is now reported later because identifiers
became legal in exponents. The approved numbat problem scoped base mode the same way.

**Final validation, clean room from a hard reset to BASE_COMMIT:**

| check | result |
|---|---|
| base on base (test.patch only) | 227 cases, 0 failures |
| new on base | exit 101, build-failure fallback fires |
| new + solution | 34/34, three runs identical digests |
| base + solution | 227, three runs identical |
| patches both orders / reverse | clean |
| human-effective LOC | 257 across 10 files |
| meta.md | 329 words, ASCII, no headers |

**Predicted pass rate 10-25%, UNMEASURED.** The 10-run batch is the only oracle. If it comes back
over 40%, the diagnosis order is written down: fill remaining cross-product cells first, do not touch
wording. **Docker validation is OWED** - no local Docker here; the Dockerfile is the DOCKER.md
canonical Pattern A verbatim and was checked statically against the tree the platform builds
(base + test.patch, no solution).
