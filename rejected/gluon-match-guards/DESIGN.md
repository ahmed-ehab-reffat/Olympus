# DESIGN — gluon-match-guards

## 1. Title
Add guard clauses to match alternatives (`| pattern if condition -> body`).

## 2. Shape classification
**O-Composite-add** (new language feature spanning parser -> base/AST -> check -> vm/core translation -> vm/compiler, plus completion + format + codegen exhaustive-match ripple).
- Predicted band: 10-15% (target <=20%). Best agent: **Vega** (heavy multi-stage feature add); Orion secondary.
- Verdict mix expected: MISSED_REQUIREMENT (fall-through semantics) + INTEGRATION_ERROR (cross-crate exhaustive-match ripple) + WRONG_LOGIC (matrix grouping).

## 3. Public API / language surface
- New concrete syntax: an `Alternative` may be `"|" Pattern "if" Expr "->" BlockExpr`. Reuses the existing `if` token; no new keyword.
- No new public Rust type is *required* by the tests; tests drive behavior through `vm.run_expr::<T>("<top>", src)` and (optionally) `db.core_expr`. Fairness: the feature is user-facing syntax, so tests exercise it through the real front door (source -> run), per Principal-Reviewer Rubric #7.
- Type rule: guard expression must unify with `Bool` (`std.bool`); mismatch is a type error surfaced through the existing typecheck error channel.

## 4. Canonical / observable contract (what tests assert)
1. `| p if c -> b` parses; `c` is `Bool`-typed.
2. Guard evaluated only after `p` matches.
3. Guard sees bindings from `p` (including nested + `@`), and outer scope.
4. Guard `True` -> body taken.
5. Guard `False` -> control continues to the following alternatives (FALL-THROUGH), including a later alternative whose pattern also matches.
6. Top-to-bottom order.
7. Multiple alternatives sharing one pattern/constructor with different guards, tried in order.
8. Unconditional alternative (no `if`) unchanged.
9. All matching guards fail + no other match -> runtime match failure (same class as today's non-exhaustive match).
10. Non-`Bool` guard -> type error.
11. Guard on literal patterns, record/tuple patterns, constructor patterns, ident/wildcard patterns.
12. Guard may call functions / use operators (arbitrary Bool expression).

## 5. The interdependent + misdirecting traps (difficulty engine)
- **T1 (misdirecting, dominant): fall-through vs fail.** The naive fix compiles `| p if g -> b` as "match p; if g then b else <match-failure>". A false guard then jumps to failure instead of the next alternative. The failing test reads as "wrong result / match failed", not "guard fall-through missing". Fair: meta states the fall-through contract (WHAT); the HOW (keep the guarded row live in the decision procedure) is withheld.
- **T2 (interdependent): equation-matrix grouping.** `PatternTranslator` (vm/core/mod.rs:1559-1966) groups/specializes alternatives by constructor/record/literal. A guarded row can no longer be treated as committing: it must remain available to later columns/rows. Handling guards only in `compile_constructor` but not `compile_literal`/`compile_variable`/`compile_record` regresses the others -> fixing one surfaces another.
- **T3 (integration): cross-crate exhaustive-match ripple.** Adding a `guard` field to `ast::Alternative` forces every exhaustive consumer to compile: base (ast walk / AstClone), check (typecheck, metadata, rename), vm/core translate, completion, codegen (ast_clone/arena_clone), format. Miss one -> INTEGRATION_ERROR (Rust won't compile) — the pest D-new ripple at Olympus scale.
- Guarded catch-all subtlety: a guarded `| x if c -> ...` is NOT a guaranteed match; treating a guarded ident/wildcard as exhaustive is a T1 sub-bug (covered by contract #9).

## 6. Blind-spot pre-empts already in meta.md
- "matching continues at the following alternatives exactly as if `pattern` had not matched, so a later alternative whose pattern also matches the scrutinee is still tried" (fall-through contract; pre-empts T1 fail-instead-of-fallthrough without leaking the matrix approach).
- "several alternatives may share the same pattern with different guards" (pre-empts T2 constructor-grouping-commit assumption).
- "including bindings introduced by nested patterns and by `@` patterns" (scope).
- "the same as a match with no matching pattern today" (pins the all-guards-fail edge to existing runtime-failure behavior).

## 7. File footprint (MODIFY vs CREATE)
No new files strictly required (feature is a field on an existing node). Modified, with rough effective LOC:

| File | Role | eff LOC |
|---|---|---|
| parser/src/grammar.lalrpop | `Alternative` production gains optional `if <guard>` | 15 |
| base/src/ast.rs | `Alternative.guard: Option<SpannedExpr>`; walk_alternative / walk_pattern threading; AstClone | 45 |
| base/src/ast.rs (visitor/mut visitor) | visit guard in `Visitor`/`MutVisitor` | 20 |
| check/src/typecheck.rs | typecheck guard as Bool in match-arm scope (bindings visible) | 45 |
| check/src/metadata.rs | thread guard through metadata walk | 8 |
| check/src/rename.rs | rename/scope guard | 12 |
| vm/src/core/mod.rs | core `Alternative` guard repr + `PatternTranslator` fall-through (the hard core) | 180-260 |
| vm/src/compiler.rs | ensure guarded core Match lowers correctly (if guards represented in core) | 25 |
| completion/src/lib.rs | traverse guard | 10 |
| codegen/src/ast_clone.rs + arena_clone.rs | clone guard field | 12 |
| format/src/pretty_print.rs | pretty-print `if <guard>` | 12 |

Estimated effective (Counter 2): **~430-520**. Target >=450; if the core-translation route desugars rather than adding a core field, LOC concentrates in vm/core (still >=450). Cross-crate span: 6-7 crates -> clears Olympus long-horizon (>=2 files, >=40 msgs, >=250 eff, median >100 msgs) comfortably.

## 8. Solution outline (helpers + hard core)
- AST: `guard: Option<SpannedExpr>` on `Alternative`. Thread through every `Alternative` constructor/visitor.
- Parser: `"|" <pat> <guard:("if" <SpExpr>)?> "->" <expr>`. LR(1)-clean: after the pattern, `if` vs `->` is a 1-token decision.
- Typecheck: in the arm, after binding the pattern, if `guard.is_some()` unify its type with `Bool`; body typed as today.
- Core translation (vm/core): represent the guard, then in the equation-matrix compiler a matched-but-guarded row compiles to `if guard then body else <compile remaining rows against same scrutinee>`. Guarded rows must NOT be consumed by specialization the way unguarded rows are.
- Fixpoint/ordering: preserve source order of alternatives across specialization.

## 9. Test outline (deterministic, public-API-driven)
Harness: `tests/support/mod.rs` `test_expr!` + `vm.run_expr`, plus a few `db.core_expr` structural checks (optional). New file `tests/match_guards_<hex>.rs`.
- Behavior: guard true/false picks right body; fall-through to next matching alt; two constructor alts differing only by guard; guard on literal / record / tuple / `@` / nested patterns; guard using outer var; guard using function call; all-guards-fail -> `run_expr` returns `Err` (runtime match failure); unguarded alt still unconditional.
- Type: non-Bool guard -> typecheck error (assert compile fails / `run_expr` Err with type-error substring).
- Edge: guarded wildcard is not exhaustive; nested match with guards; guard referencing `@`-bound whole value.
- ~55-75 granular tests. base mode runs full existing suite (regression: pattern_match.rs, row_polymorphism.rs, optimize fixtures).

## 10. Forced-decision points (fairness pins already in meta)
- Bool type of guard (named).
- Fall-through-not-fail (named).
- Order top-to-bottom (named).
- All-guards-fail = existing runtime failure (named).
- 1 codebase-inferable requirement max: that guard bindings share the arm's pattern scope (inferable from how bodies already see bindings) — left implicit.

## 11. Tier + category
- Tier: **Olympus** (O-Composite-add). Category: **feature-request** (new language surface; title starts "Add...").

## 12. Predicted Nova/Vega pass rate
~10-15%. Vega best (multi-stage). Nova-alone likely 0 (thrashing on the matrix). Orion may 1-shot the plumbing but stall on T1 fall-through.

## 13. Docker
Pattern: `olympus-base-rust` + `cargo install cargo2junit && cargo fetch && cargo build --workspace` (NO chmod). test.sh: `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit`, build-fail fallback. gluon workspace builds with default features; test feature `test` needed for support helpers (`#![cfg(feature = "test")]`).

## 14. Quality-gate checklist (pre-submit)
- [ ] meta.md ASCII, <=200 words, no headers. (currently ~205 — trim pass pending)
- [ ] every test traces to a meta sentence; <=1 codebase-inferable.
- [ ] human-effective LOC >=450.
- [ ] base suite green 3-5x (flakiness); new tests deterministic.
- [ ] exclusivity re-check at submit (no new guards PR).
- [ ] cargo2junit JUnit + build-fail fallback verified by forcing a failing test.
- [ ] test filename random hex, no `shipd`/`datacurve`.
