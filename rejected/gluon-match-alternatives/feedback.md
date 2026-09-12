# feedback.md — gluon-match-alternatives

Tier: OLYMPUS | Shape: O-Composite-add | Repo: gluon-lang/gluon (MIT, 3.4k stars)
Base: `418c6b7de22b244746bfd0570f9fcfd6d738e542`

## What shipped

Two coupled additions to gluon's match expression:

1. **Guards** — `| pattern if condition -> body`, `Bool`-typed, evaluated after the pattern
   matches, falling through to the following alternatives when false.
2. **Binding or-patterns** — `(p1 | p2 | ...)` anywhere a pattern is expected, nestable, with
   branches that bind variables. Every branch must bind the same names at the same types; the body
   and guard see the values bound by whichever branch matched.

Span: parser (grammar + layout) -> base (ast) -> check (rename + typecheck + metadata +
recursion) -> vm/core (equation-matrix translation) -> completion + format + repl. 16 files.

## Relationship to the ancestor problem

This supersedes `problems/gluon-match-guards`, which bundled guards, NON-binding or-patterns and
exhaustiveness checking at 228 effective LOC and was never batched. Two changes:

- **Exhaustiveness checking removed.** It is gluon issue #9 — open since 2015, zero comments, no
  PR, famous feature — which is `TOO-EASY.md`'s "Open-but-unimplemented feature request" derivative
  death class verbatim. It also rejects previously-valid programs, and rejecting valid programs is
  what manufactured the PASS_CHEATED losses on gluon-format-comments (L31). Dropping it left the
  submission purely additive: all 426 base tests pass unchanged.
- **Or-patterns gained bindings.** The ancestor made a binding branch a type error, which is a
  cheap escape hatch. Allowing bindings is where the new lead trap lives.

## Traps

- **T1 (lead) — or-branch binding identity.** `check/src/rename.rs` mints a module-unique symbol
  per binder. Recursing into each or-branch (the natural implementation, and what the ancestor
  did) gives `n` a different symbol in each branch. Compiles, typechecks, then panics three stages
  later at `vm/src/compiler.rs:607` with `Undefined variable ... Please report an issue at
  github.com/gluon-lang/gluon/issues` — an ICE worded as a gluon bug, in a different crate from
  the fix. Reproduced before the tests were written by disabling the reuse path.
- **T2 — guard fall-through through the equation matrix.** The naive lowering
  (`if guard then body else <match failure>`) sends a failed guard to a run-time failure instead
  of the next alternative. Interdependent with T1: both ride `PatternTranslator`, and the
  or-expansion duplicates rows that a guard must fall through for each duplicate.
- **T3 — cross-crate exhaustive-match ripple.** A new `Pattern` variant plus a new `Alternative`
  field stops base/check/vm/completion/format/repl compiling. `repl/src/repl.rs` is reached only
  by `cargo build --workspace`, so missing it is a Docker build failure rather than a test
  failure. (This was a latent bug in the ancestor's patch, found here.)
- **T4 — guard x or-binding cross-product (F-10).** Both axes are stated; their composition is
  not. The discriminating cells drive the SECOND or third branch, then fail the guard, then fall
  through to a later alternative that rebinds the same name.
- **T5 — self-test-shadow (P3).** The natural smoke test matches the FIRST branch. Every binding
  test drives a later one, and `or_binding_variables_swapped_between_branches` forces per-branch
  positional binding.

## Status: COMPLETE, LOCALLY VALIDATED

| Check | Result |
|---|---|
| new mode with solution | 91 / 91 pass, 3 identical runs |
| new mode on base | 80 / 91 fail (the 11 passers are error-expecting and regression tests) |
| base mode on base | 426 pass, 0 fail, 24 suites |
| base mode with solution | 426 pass, 0 fail, 3 identical runs |
| flakiness 3x (base + new) | identical every run |
| patches apply + reverse, both orders | clean |
| encoding | ASCII, LF; test.sh mode 100755 |
| test filename | random hex, no banned markers |
| human-effective LOC | 277 (floor 200), 16 files (floor 2) |
| Counter 1 (platform auto-block) | 375 |
| comment convention | 6 added comment lines, all matching gluon's own doc-comment and
inline style in the same files |

## Known hazards, stated rather than hidden

- **`gluon_parser` is excluded from base mode.** `parser/tests/support/mod.rs:344` constructs
  `ast::Alternative { pattern, expr }` as a struct literal, so the new `guard` field makes that
  package's test targets fail to compile. Including it would push the solver to edit a repo test
  file, which is scored as cheating (L31). The package's library code is still built by the
  Dockerfile. This is the only excluded package, and the exclusion reason is mechanical.
- **Docker is not verifiable on this workstation.** The Dockerfile was aligned against all six
  approved Rust references rather than the generic Pattern A, after checking what the accepted
  gluon submission actually needed. Three things Pattern A omits and 5 of 6 approveds carry are now
  present: `cargo install cargo2junit --version 0.1.15 --locked` (4 of 6 pin that version), `--locked`
  on both fetch and build (5 of 6), and `chmod -R a+rwX /opt/cargo /opt/rustup /app` (5 of 6 carry a
  chmod; gluon-format-comments uses all three paths). `olympus-base-rust` keeps its toolchain in
  `/opt/cargo` and `/opt/rustup`, so no `CARGO_HOME` / `RUSTUP_HOME` env vars are set: setting them
  is what failed gluon-format-comments' first platform image build.

  Build stays `--workspace` WITHOUT `--tests`. The accepted gluon submission recorded that
  `format/tests/std.rs` does not compile on this commit (`#[tokio::main]` against a tokio dev
  dependency carrying only the `macros` feature), so `--tests` would fail the image build for a
  reason unrelated to this change. `cargo build --workspace` was verified against the exact tree
  the image builds (base + test.patch, no solution) and against base + both patches.

- **cargo2junit is kept, unlike the accepted gluon submission.** That one scoped base mode to a
  single test target and used the bash-regex reporter. This base mode spans 24 test binaries across
  three packages, and CLAUDE.md records that the bash-regex reporter miscounts across multiple test
  binaries. cargo2junit was verified locally on the real output: 24 suites, 426 testcases, correct
  per-test failure attribution.

- **`format/tests/std.rs` compiles here only through workspace feature unification.** base mode runs
  `cargo test --offline -p gluon_check -p gluon_vm -p gluon_format` as ONE invocation, and the union
  of those packages' features supplies tokio's multi-thread runtime. Splitting that invocation per
  package would break it. Verified green across 8 separate runs.

- **All three cargo invocations use `--offline`**, so the `--network none` run cannot attempt a
  fetch. Verified locally.

## Attempt history

- **v1 (`gluon-match-guards`, retired):** guards + non-binding or-patterns + exhaustiveness, 228
  effective LOC, 58 tests, never batched.
- **v2 (this):** exhaustiveness dropped for derivative-magnet and cheat-trap reasons, binding
  or-patterns added, base mode widened from 2 test targets (21 tests) to 24 suites (426 tests),
  `repl` compile break fixed, recursive or-expansion fixed, `@`-over-or-pattern fixed.
- **v2 review round:** five tests pinned the reference's own error phrasing; rewritten to assert
  the error names the offending variable, which is what the description actually promises. Closing
  that opened a coverage hole in the extra-binding fixture (it was failing on arity rather than on
  the rule), rebuilt and re-verified against the mutation.
- **v2 hardening round 1:** 12 tests added for the F-18 flat-vs-nested or-pattern parity axis and
  the empty F-10 composition cells. Zero new description words. Found and fixed a reference crash
  on `w @ (A n | (B n | D n))`. Mutation kills moved 26 -> 38 (lead trap), 24 -> 30 (fall-through)
  and 1 -> 8 (nested expansion).

## Pre-submit self-review (olympus-review, visible artifacts only)

Run with `olympus-review` against the visible artifacts only (`meta.md`, `test.patch`,
`solution.patch`, `Dockerfile`). `DESIGN.md`, `feedback.md` and `eval-results.md` were excluded,
as a real reviewer would not see them.

## Stage 0 — hard-block precheck: PASS

| Check | Result |
|---|---|
| em-dashes / smart quotes / ellipsis in meta.md | none |
| meta.md encoding | ASCII |
| `shipd` / `datacurve` in test paths | none |
| `test.sh` mode in test.patch | `100755` |
| patch encoding | ASCII, LF |
| `##` headers in the meta body | none (the single `#` is the H1 title) |
| body word count | 359, under the 500 hard cap |

## Stage 1 — Pattern 22 GitHub audit: PASS

Canonical slug resolved first: `gh api repos/gluon-lang/gluon -q .full_name` returns
`gluon-lang/gluon`, so the repo has not moved.

1. Literal + class searches over PRs, all states: `guard`, `guards`, `pattern guard`, `or-pattern`,
   `or pattern`, `match arm`. No PR implements or mentions either capability. The only hits are
   dependency bumps and unrelated merged features (`Implement as-patterns` #342, `Allow pattern
   matching on literals` #417, both long merged and both in the base tree).
2. Namespace searches over issues, all states. Nothing on guards. Nothing on or-patterns.
3. Maintainer philosophy: the opposite of a rejection. In issue #527 the maintainer writes "I think
   a better solution for this would be to just reject any programs that do not have exhaustive
   patterns (just like Rust does)". No comment anywhere declines guards or or-patterns.
4. Closed-with-implemented scan: no closure says either feature shipped.
5. Base to `origin/master`: 8 commits, none touching `parser/src/grammar.lalrpop`,
   `base/src/ast.rs`, `check/`, or `vm/src/core/`.
6. Open-PR file lists: 7 open PRs, all in `std/`, `src/`, `book/`, `doc/`, `codegen/vm_type.rs`,
   `base/src/types/mod.rs`. Zero overlap with the solution footprint.

## Stage 2 — understanding

- **Project purpose:** gluon, a small statically typed embeddable functional language in Rust.
- **Requested change:** add guards to match alternatives and allow or-patterns whose branches bind.
- **Fully implemented?** Yes, across parser, check, vm/core, completion, format and repl.
- **In scope?** Yes. Purely additive: no existing program changes meaning, and all 426 base tests
  pass unchanged.
- **Aligned with repo philosophy?** Yes. gluon already ships as-patterns and literal patterns; the
  maintainer has asked for stricter pattern handling, not less.
- **Trivial?** No. 16 files, 277 effective LOC, seven subsystems.
- **Tier visible:** Olympus.

## Stage 3 — rejection eligibility: none of the 8 fire

Rust, MIT, 3.4k stars, commit on 2026-08-06, no existing PR, no maintainer rejection, not
already implemented, well above the tier floor, original.

## Stage 4 — description: 6/7

- Body opens with the ask (`Add guards and or-patterns to match alternatives, so ...`), current
  behavior in the second sentence.
- Backticks only on new syntax and on `Bool`, which the tests assert against.
- Every tested behavior traces to a sentence: the guard's type, its evaluation order, its scope,
  fall-through, top-to-bottom order, shared patterns with different guards, unconditional
  alternatives, the run-time failure edge, or-pattern syntax and nesting, branch binding
  agreement by name and by type, that the error names the variable, that the body sees the
  matched branch's bindings whatever its position, and `@` over an or-pattern.
- One codebase-inferable requirement left implicit: that a guard and a body share the
  alternative's pattern scope. Within the cap.
- Marked down one point for length. 359 words is comfortably under the 500 cap but above the 200
  recommendation. It carries two capabilities and their composition, and trimming further would
  drop a sentence a test asserts, so the length is kept deliberately.

## Stage 5 — tests: 6/7

- 91 tests. 85 fail on base, all for the right reason (the syntax does not parse). The 6 that pass
  on base are error-expecting or regression tests and are not discriminators.
- Assertions: 79 exact-value `test_expr!` cases, 12 `assert!` cases on rejected programs. Zero
  `is_ok()`, zero `length > 0`, zero `toBeDefined`.
- **One issue found and fixed during this review.** Five tests asserted the error text contained
  the literal phrase `not bound by every alternative`. The description promises "a type error that
  names the variable", not that wording, so the phrase was an unfair pin on the reference's own
  message. Rewritten to use distinctive identifiers (`only_in_first`, `only_in_third`,
  `extra_binding`) and assert the message names the offending variable. That is exactly what the
  description states.
- Rebuilding one fixture was required after the fix: `(A n | B n extra_binding)` was being rejected
  on arity rather than on the binding rule, so removing the extra-name check left it passing.
  Changed to `(A n 0 | B n extra_binding)`, where both branches are well-typed and only the
  binding rule can reject. Confirmed it now kills that mutation.
- `test.sh`: mode 100755, LF, position-independent `--output_path`, base and new are distinct
  sets, the second base command runs even if the first fails, non-zero exit propagates, JUnit XML
  is per-test, no network, no package install, build-failure fallback present.
- Flakiness: base and new both run 3x with identical results.
- **Known cosmetic issue, accepted:** base mode emits 4 duplicate `<testcase>` names across the 24
  suites (`foldable_bug` and three `type_alias_with_explicit_*_kind` appear in two `gluon_check`
  test binaries). They are distinguished by suite id, all 4 pass in both modes, and base mode is
  pass-to-pass only, so no attribution ambiguity is possible. Removing them would mean dropping a
  `gluon_check` test target, which is the crate the lead trap lives in. Not worth the coverage.

## Stage 6 — solution: 6/7

- 16 files, raw +402, Counter 1 = 375, human-effective (Counter 2) = 277. Clears the 200 floor
  with a 38% buffer.
- Base mode green before and after, 3x. No regressions.
- No dead code: `pattern_bound_names` feeds the typecheck consistency pass, `distribute_as` is
  called from the grammar, the completion and format changes are both reachable from their crates'
  public entry points.
- No debug statements, no commented-out alternatives, no AI markers.
- Comment convention matches: 6 added comment lines, all doc comments on new enum variants and
  public functions in files that already doc-comment (`base/src/ast.rs`,
  `check/src/typecheck/error.rs`) plus one inline note in `parser/src/layout.rs`, which carries 71
  inline comments of its own.
- No scope creep. `repl/src/repl.rs` is a one-line exhaustive-match arm forced by the new
  `Pattern` variant, not a feature.
- The guard typecheck block is written as the same shape as gluon's own `IfElse` predicate
  handling at `check/src/typecheck.rs:720-723`, so it reads as the repo's own code.
- Would I merge this as a maintainer? Yes. It is the feature the issue tracker has wanted, it
  breaks nothing, and it matches the surrounding style.

## Stage 6.5 — subtle bugs

Two real bugs surfaced during hardening and review, both fixed:

1. `w @ (A n | (B n | D n))` panicked with `ICE: Or-pattern survived pattern expansion` because
   `@` was distributed over the outer or-pattern only. `distribute_as` is now recursive.
2. `cargo build --workspace`, which the Dockerfile runs, failed on `repl/src/repl.rs`. The
   ancestor problem carried this break and would have failed its image build.

## Verdict

**ACCEPT.** Quality 6/7 on description, tests and solution.

Two items remain owed and are recorded rather than hidden: the Docker image build (no Docker on
this workstation) and the platform batch, which is the only real difficulty oracle. The 15-25%
prediction is a prediction.

## Open

- Platform batch not run (local validation only). Predicted 15-25%.
- FP check owed at the end of the batch.
