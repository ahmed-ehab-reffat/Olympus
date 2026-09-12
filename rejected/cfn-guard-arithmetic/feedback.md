# cfn-guard-arithmetic — feedback / iteration log

Olympus. Repo: aws-cloudformation/cloudformation-guard (Rust, Apache-2.0). Base `57bbdbf`. Feature: arithmetic operators (`+ - * /`) for the Guard DSL (issue #584, maintainer-accepted, no PR, cold).

## Local validation (pre-eval)
- Build: clean.
- New tests: 19/19 PASS on solution, 0/19 on base (f2p via `./test.sh new`: 19 failures on base, 0 on solution).
- Base regression: 286 lib tests + integration = 287 JUnit cases, 0 failures, on solution.
- Flakiness: base 6x + new 3x deterministic (after fixing a cargo2junit stdout-contamination race: existing tests print the Guard eval tree to real stdout; `grep '^{'` filter before cargo2junit).
- Effective LOC (Counter-1): 278 across 6 files (exprs, parser, eval_context, eval, evaluate, path_value).

## Hardening (HARDENING.md)
- Lead S3 baseline-preservation: `*`/`/` collide with query wildcard / regex delimiter; `%` collides with variable-reference prefix. Naive grammar breaks base tests with misdirecting failures (hit during authoring: `%` as modulo consumed the next clause's `%var`, broke 19 base tests). Resolved by dropping `%` and routing arithmetic via `verify(let_value, is_binary_op)` tried before the original alternatives (lone primaries parse identically). Base mode runs `--lib` (the parser+eval preservation guard).
- S4 machinery-riding: multi-value / empty / non-numeric operand -> eval error (shares the single-scalar resolve path).
- S2 precedence composition: `* /` over `+ -`, left-assoc, parens, arithmetic tighter than comparison.

## FP check (both directions)
Every meta sentence -> >=1 discriminator test; every test -> a meta sentence. Discriminators: precedence-not-20, assoc-not-7, div-not-truncated, paren override, div-by-zero error, multi/empty/non-numeric operand error (each paired with a valid-operand PASS so it fails on base), preservation-with-arithmetic (wildcard+regex+arithmetic together).

## Attempt history
- A1 (2026-07-22): initial hardened implementation + full deliverable. Pending platform eval batch.
