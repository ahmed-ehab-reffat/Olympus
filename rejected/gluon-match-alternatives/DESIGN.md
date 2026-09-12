# DESIGN — gluon-match-alternatives

Supersedes `problems/gluon-match-guards/DESIGN.md`. That design bundled guards, non-binding
or-patterns and exhaustiveness checking. Exhaustiveness was removed here for two measured reasons
(see § 15) and replaced with BINDING or-patterns, which is where the new lead trap lives.

## 1. Title
Add guards and binding or-patterns to match alternatives.

## 2. Shape classification
**O-Composite-add** — a new language surface spanning parser (grammar + layout), base (AST),
check (rename + typecheck + metadata + recursion), vm/core (equation-matrix translation),
completion, format and repl.

- Target band: 10-25% (ceiling 40%). Best agent: Orion / Vega (long-horizon multi-stage);
  Nova likely thrashes on the matrix.
- Predicted verdict mix: MISSED_REQUIREMENT (guard fall-through) + WRONG_LOGIC (or-branch
  binding identity) + INTEGRATION_ERROR (cross-crate exhaustive-match ripple).

## 3. Public surface (concrete syntax, no new Rust public API required)
- `| pattern if condition -> body` — guard on an alternative. Reuses the existing `if` token.
- `(p1 | p2 | ...)` — or-pattern, any number of branches, nestable, usable anywhere a pattern is.
- Branches may bind; every branch must bind the same names at the same types.
- `name @ (p1 | p2)` — `@` over an or-pattern.
- Guard type rule: unifies with `Bool`.
- New error: a variable not bound by every branch, reported by name.

Tests drive everything through `vm.run_expr::<T>("<top>", src)` — the real front door — so no
internal type is pinned (Principal-Reviewer Rubric #7).

## 4. Canonical / observable contract
1. Guard evaluated only after its pattern matches; type `Bool`; non-`Bool` is a type error.
2. Guard sees the pattern's bindings (nested, `@`, or-branch) and the surrounding scope.
3. Guard `True` -> body. Guard `False` -> **matching continues at the following alternatives as if
   the pattern had not matched** (fall-through), including a later alternative whose pattern also
   matches.
4. Alternatives tried top to bottom; several may share a pattern with different guards.
5. All matching guards fail and nothing else matches -> the existing run-time match failure.
6. Or-pattern matches when any branch matches; branches tried left to right; nestable at any depth.
7. Or-branches bind the SAME set of names at the SAME types; a mismatch is a type error naming the
   variable.
8. The body and the guard see the values bound by **whichever branch matched, whatever position
   that branch occupies**.
9. `@` over an or-pattern names the whole matched value.

## 5. Trap set

### T1 (LEAD, S-tier / F-9 cross-stage resolution drop) — or-branch binding identity
`check/src/rename.rs` renames every binder to a module-unique symbol. The natural implementation
of `Pattern::Or` in `new_pattern` recurses into each branch, which mints a DIFFERENT symbol for
`n` in each branch. Everything still compiles, typecheck still succeeds, and the failure surfaces
three stages later as

```
thread panicked at vm/src/compiler.rs:607:32:
Undefined variable `...:n@4_12` in probe. Please report an issue at https://github.com/gluon-lang/gluon/issues
```

an internal-compiler-error in a different crate, worded as a bug in gluon rather than in the
agent's patch. **Reproduced** by disabling the reuse path: every binding or-pattern test dies with
that panic and no other test moves.

CONTRACT-STATED / FIX-HIDDEN check: the meta states the contract ("they hold the values bound by
whichever branch actually matched, whatever position that branch occupies"). It does not name
rename.rs, the symbol table, or the reuse rule. Passing that sentence is a discovery about how
gluon resolves identifiers, not a transcription.

### T2 (S2 composition, interdependent with T1) — guard fall-through through the matrix
`PatternTranslator` (vm/src/core/mod.rs) compiles alternatives as a Barrett-Wadler equation matrix
and treats a matched row as committing. The naive guard lowering is `match p; if g then body else
<match failure>`, which sends a failed guard to a run-time failure instead of the next alternative.
Misdirecting: the failing test reads as a wrong value or an unmatched-pattern error, never as
"guards need to stay live in the decision procedure". Interdependent with T1 because both ride the
same translation path: the or-expansion duplicates rows, and a guard-wrapped row must fall through
for EVERY duplicate.

### T3 (A-tier integration ripple) — cross-crate exhaustive matches
`Alternative` gains a field and `Pattern` gains a variant, so base/check/vm/completion/format/repl
all stop compiling until every consumer is updated. `repl/src/repl.rs` in particular is only
reached by `cargo build --workspace`, not by the test targets — a missed site is a Docker build
failure, not a test failure.

### T4 (F-10 cross-product cells) — or-binding x guard
Both axes are stated separately; nothing states their composition. Cells:

| | unguarded | guarded, true | guarded, false |
|---|---|---|---|
| **branch 1 matches** | `or_binding_first_branch` | `or_binding_guard_true_on_second_branch` (mirror) | `or_binding_guard_false_on_second_branch_falls_through` |
| **branch 2 matches** | `or_binding_second_branch` | `or_binding_guard_true_on_second_branch` | `or_binding_guard_false_falls_to_a_later_or_alternative` |
| **nested under a constructor** | `or_binding_nested_in_constructor_second_branch` | `nested_or_binding_under_guard_second_branch` | `or_binding_guard_false_then_unguarded_nested_alternative` |
| **under `@`** | `as_over_or_binding_second_branch` | `as_over_or_binding_with_guard_second_branch` | `as_over_or_binding_guard_false_falls_through` |
| **inside a tuple** | `or_binding_inside_tuple_second_branch` | — | `or_binding_in_tuple_guard_false_falls_through` |
| **inside a record** | `or_binding_inside_record_second_branch` | `or_binding_in_record_guard_true_second_branch` | — |
| **nested or-pattern** | `nested_or_binding_under_a_constructor` and 3 more | `nested_or_binding_guard_true_innermost_branch` | `nested_or_binding_guard_false_falls_through` |

The off-diagonal cells (a guard reading an or-bound variable, then failing, then falling through
to a LATER or-pattern alternative that rebinds the same name) are the composition discriminators.

### T4b (F-18 form parity) — flat vs nested or-patterns
The contract states one rule for or-patterns and one clause saying they nest, so the flat form
`(A n | B n | D n)` and the nested form `(A n | (B n | D n))` are two spellings of one concept.
The flat form is salient; the nested one is what an implementation misses. Every position tested
for the flat form is also tested for the nested one. Measured: making the or-expansion
non-recursive kills 1 test without these cells and 8 with them.

### T5 (P3 self-test-shadow) — position of the matching branch
An agent's natural smoke test is `match A 5 with | (A n | B n) -> n`, i.e. the FIRST branch. Every
binding test in the suite drives the SECOND or THIRD branch. `or_binding_variables_swapped_between_branches`
(`(A a b | B b a)`) additionally forces per-branch positional binding rather than positional reuse.

## 6. Blind-spot pre-empts in meta.md
- "matching continues at the following alternatives exactly as if `pattern` had not matched" (T2).
- "several alternatives may share one pattern with different guards" (matrix-commit assumption).
- "they hold the values bound by whichever branch actually matched, whatever position that branch
  occupies" (T1 contract, fix withheld).
- "including nested inside another pattern and inside another or-pattern" (recursive expansion).
- "the match fails at run time as before" (pins the all-guards-fail edge to existing behavior).

## 7. File footprint (measured, not estimated)

| File | Role | +lines |
|---|---|---|
| parser/src/grammar.lalrpop | optional `if <guard>`; `Or` production; `@` delegates to `distribute_as` | 18 |
| parser/src/lib.rs | `distribute_as` recursively pushes `@` inside nested or-patterns | 28 |
| parser/src/layout.rs | `->` closes the guard's `If` layout context | 8 |
| base/src/ast.rs | `Alternative.guard`, `Pattern::Or`, walkers, `Typed`, `pattern_bound_names` | 60 |
| check/src/rename.rs | **or-branch symbol unification (T1 fix site)** | 33 |
| check/src/typecheck.rs | guard unifies with `Bool`; or-branch name/type consistency | 71 |
| check/src/typecheck/error.rs | `OrPatternBindingMismatch` | 7 |
| check/src/metadata.rs, recursion_check.rs | thread guard + Or | 5 |
| vm/src/core/mod.rs | `translate_guarded` fall-through + recursive or-expansion (T2) | 121 |
| completion/src/lib.rs | descend into guards and or-branches | 18 |
| format/src/pretty_print.rs | print guards, or-patterns, refold `@` over `Or` | 31 |
| vm/src/derive/{eq,show,serialize}.rs, repl/src/repl.rs | exhaustive-match ripple (T3) | 8 |

**16 files. raw +402, Counter 1 = 375, human-effective (Counter 2) = 277.**
Floor is 200 effective / 2 files; this clears with a 33% buffer.

## 8. Solution outline
- AST: `guard: Option<&'ast mut SpannedExpr>` on `Alternative`; `Pattern::Or(&'ast mut [SpannedPattern])`.
- Parser: `"|" <pat> <("if" <Guard>)?> "->" <expr>`. A dedicated `GuardExpr` production keeps the
  guard out of `InfixExpr`'s `if/then/else` territory; `layout.rs` pops the `If` context on `->`.
  `id @ (p1 | p2)` is distributed to `(id @ p1 | id @ p2)` at parse time so every later stage sees
  a plain `Or`, and the formatter refolds it so source round-trips.
- rename: `or_bindings` map + `or_depth`/`or_reuse` flags; branch 0 mints symbols, later branches
  reuse by original name. Nested or-patterns share one frame, so an inner or inside branch 1 also
  reuses branch 0's symbols.
- typecheck: guard unified with `Bool` in the arm's scope. `Pattern::Or` typechecks each branch,
  collects `(symbol, type)` via `ast::pattern_bound_names`, and `check_or_branch_bindings`
  compares against branch 0 in both directions (missing and extra) and unifies shared names.
- vm/core: `translate_guarded` compiles alternatives right to left, each as a single-equation
  `translate` whose default is the accumulated fallback, so a false guard falls into the next
  alternative's compiled matcher. `expand_or_patterns` flattens or-patterns in the head column
  recursively before grouping.

## 9. Test file
`tests/match_alternatives_75d59b.rs`, 91 tests, driven through `run_expr`.
Blocks: guards (35) / non-binding or-patterns (7) / binding or-patterns (16) / guard x or-binding
cross-product (9) / type and run-time errors (12).
Base mode: `gluon_check`, `gluon_vm`, `gluon_format` (all targets) plus
`gluon --test pattern_match --test row_polymorphism --test inline --test error --test fail`
= 426 tests, 24 suites.

**Excluded from base mode: `gluon_parser`.** Its shared helper `parser/tests/support/mod.rs:344`
builds `ast::Alternative { pattern, expr }` as a struct literal, so the new field makes that
package's test targets not compile. Including it would force the solver to edit a repo test file,
which is scored as cheating (L31, measured on gluon-format-comments). The package's library code
is still built by the Dockerfile's `cargo build --workspace`.

## 10. Forced decisions pinned in meta
Guard type is `Bool`; fall-through not failure; top-to-bottom order; all-guards-fail equals the
existing run-time failure; or-branches bind the same names at the same types; the body sees the
matched branch's bindings regardless of position. One codebase-inferable requirement is left
implicit: that guard and body share the alternative's pattern scope.

## 11. Tier + category
Olympus. `feature-request` (new language surface, title starts "Add").

## 12. Predicted pass rate
15-25%. T2 alone historically sits near 50%; T1 is a separate axis with a misdirecting ICE
symptom, and T4's composition cells are the band decider per F-10.

## 13. Docker
Pattern A verbatim: `olympus-base-rust` + `cargo install cargo2junit && cargo fetch && cargo build
--workspace`. No `ENV`, no `chmod`, no `--tests`. NOT verified locally (no Docker on this
workstation); `cargo build --workspace` was verified against the tree the image builds
(base + test.patch, no solution) and against base + both patches.

## 14. Why this is not a duplicate
- `approved-problems/gluon-format-comments` is the source formatter's comment-attachment model
  (format crate + shared pretty-print layer). Disjoint subsystem, disjoint trap family (F-18 token
  parity). The one overlapping file is `format/src/pretty_print.rs`, where this problem adds 31
  lines of new-syntax printing.
- `problems/gluon-match-guards` is this problem's ancestor and is retired by it, not shipped
  alongside.
- Exclusivity: no gluon PR in any state touches guards, or-patterns, or the pattern matrix
  (searched on the canonical slug `gluon-lang/gluon` for `guard`, `guards`, `pattern guard`,
  `or-pattern`, `or pattern`, `exhaustive`, `exhaustiveness`, `match arm`). No open PR touches
  grammar.lalrpop, base/src/ast.rs, check/, or vm/src/core/. 8 commits since base, none in the
  touched files.

## 15. Why exhaustiveness checking was dropped from the ancestor design
1. **Derivative magnet.** `TOO-EASY.md`'s "Open-but-unimplemented feature request" death class is
   gluon issue #9 exactly: open since 2015, zero comments, no PR, and a famous feature. Every
   author who looks at gluon finds it, so the prior art lives in the submission pipeline where
   GitHub queries cannot see it.
2. **Manufactured cheat trap (L31).** Rejecting non-exhaustive matches invalidates previously
   valid gluon programs, including snippets inside the repo's own tests. gluon-format-comments
   lost three runs across two batches to PASS_CHEATED for editing repo tests under exactly this
   pressure. Guards and or-patterns are purely additive: no existing program changes meaning, and
   all 426 base tests pass unchanged.

## 16. Quality gates
- [x] human-effective LOC 277 >= 200, 16 files >= 2
- [x] base mode 426 tests green on base and with the solution, 3 identical runs
- [x] new mode 91/91 with the solution; 80/91 fail on base (the passers are error-expecting and
      regression tests, not discriminators)
- [x] patches apply and reverse in both orders; ASCII; test.sh mode 100755
- [x] test filename random hex, no `shipd` / `datacurve`
- [x] lead trap reproduced with a misdirecting symptom before the tests were written
- [ ] Docker build (owed to the platform run; no local Docker)
- [ ] platform batch (pass rate, solvability, FP check)
