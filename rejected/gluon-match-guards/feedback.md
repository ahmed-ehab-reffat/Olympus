# feedback.md - gluon-match-guards

Tier: MARS (recommended) | Shape: Mars D-new/composite (cross-subsystem language feature) | Base: 418c6b7

## What shipped
Three related match-expression features in gluon (MIT, 3.4k star embeddable typed FP language):
1. Guards `| pattern if cond -> body` - fall-through through the Barrett-Wadler equation-matrix compiler.
2. Or-patterns `(p1 | p2)` - new `Pattern::Or` variant, expanded in the core matrix; branches may not bind (type error).
3. Exhaustiveness + redundancy - variant-completeness check (guard-aware) + unreachable-after-catch-all, via the type-error channel.

Span: parser (grammar + layout) -> base (ast) -> check (rename/typecheck/recursion/metadata + new exhaustiveness) -> vm/core (matrix translate) -> completion + format. 14 source files.

## Status: COMPLETE + LOCALLY VALIDATED
- new tests: 55 pass with solution; 44/55 FAIL on base (feature absent). 3x flakiness: identical.
- base regression: pattern_match (18) + row_polymorphism (3) green with and without solution.
- exhaustiveness zero-regression on std confirmed (gluon std is written exhaustively).
- patches apply + reverse in both orders; ASCII; test.sh mode 100755; no banned markers.
- Effective LOC ~228 (Counter-2 approx) = Mars sweet spot (170-380), below Olympus 400 auto-block.

## Tier note
Difficulty is Olympus-level (3 interdependent+misdirecting traps: guard fall-through in the matrix, or-pattern binding rule + matrix expansion, guard x exhaustiveness interaction). LOC is Mars. Platform tiers by passing-agent LOC -> submit as MARS. Reaching Olympus 450 would need the full type-directed usefulness algorithm (~200 more LOC, regression-risky).

## Traps (interdependent + misdirecting)
- T1 guard fall-through: naive `if guard then body else fail` sends a failed-guard constructor to match-failure instead of the next matching alternative (incl. a later catch-all the matrix separated). Reference compiles alternatives right-to-left, each single-pattern with the previous fallback as default.
- T2 or-pattern binding + matrix expansion: Pattern::Or must expand into rows in translate; binding branches are rejected (soundness).
- T3 guard x exhaustiveness: a guarded arm does NOT count toward completeness (caught many_ctor_rows test).

## Attempt history
- v1 guards only (~110 eff) -> Mars-sized; expanded per user to guards+or-patterns+exhaustiveness.

## Open
- Platform eval (Nova/Orion) not run (local only). Pass-rate estimate: ~10-25% (hard cross-subsystem).
- meta.md 327 words (3 features; under 500 cap).
