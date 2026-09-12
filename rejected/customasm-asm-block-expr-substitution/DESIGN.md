# DESIGN.md — customasm-asm-block-expr-substitution

Repo: hlorenzi/customasm (Rust, Apache-2.0, 1052 stars)
BASE_COMMIT: c66cb389e7af95ad612520d4766bcb09adfea948

## 1. Title

Evaluate brace substitutions in asm blocks as expressions

## 2. Shape classification

- Shape: **O-Pipeline-hard** (SHAPES.md Pattern 12) — a new capability cascading through an
  existing multi-stage resolver where the correct staging must be invented, not copied.
- Pass rate target: <= 40% (2026-07 sprint ceiling), design intent 10-25%
- Best agent: Vega / Orion (long-horizon); Nova expected to ship the eager-evaluation version
- Dominant verdict: WRONG_LOGIC on the new tests, REGRESSION on the existing `tests/expr_asm/` suite
- Solver/our LOC ratio: ~1.3x expected

## 3. Public API surface

This is an assembler-language surface, not a Rust API. The names tests assert are the
language constructs and the diagnostic strings:

- `asm { ... }` block — existing construct, extended
- `{ <expression> }` inside an asm block — the new substitution form
- a brace holding a single parameter name bound to source tokens — existing token-splice form, preserved
- label declared inside an asm block — existing, now referencable from a brace expression
- error `expected identifier` — empty braces (existing, preserved)
- error `` expected `}` `` — trailing junk after the expression (existing, preserved)
- error ``unknown substitution argument `<name>` `` — unresolvable name (existing, preserved)
- error `` `asm` block did not converge `` — a substitution that never settles (existing, now reachable by a new path)

## 4. Canonical output form

- A brace containing exactly one identifier, where that identifier names a rule parameter that
  carries a source-token substitution, splices the ORIGINAL SOURCE TOKENS. Unchanged from base.
- Every other brace content is parsed as one expression and evaluated to a value.
- Expression scope: the enclosing rule's parameters and locals, plus every label declared in the
  same asm block (both before and after the referencing instruction).
- Label addresses inside the block are relative to the block's own layout, starting at the
  position the block occupies in the enclosing bank.
- Evaluation order within one iteration is source order; values from a later label are the
  previous iteration's values until the block stabilizes.
- Empty braces `{}` remain an error. Content that parses as an expression but leaves trailing
  tokens before `}` remains an error at the offending token.
- A value that cannot be determined this iteration is a guess, not zero and not an error.

## 5. Blind-spot pre-empts

From DESCRIPTION.md's sentence bank, two apply and are quoted in the description draft:

- Iteration termination: "the block is evaluated repeatedly until the encoding stops changing."
- Rule-resolution: "a brace holding a single parameter name that was matched from source tokens
  keeps substituting those tokens."

Codebase-inferable requirements: exactly 1 (the existing token-splice behavior is discoverable
from `tests/expr_asm/ok_subrule_morph.asm`), which is within the <= 1 budget.

## 6. Description draft (meta.md)

> Inside an `asm` block, the braces that mark a substitution currently accept only a single
> name. Widen them to accept an expression, so a rule can compute the operand it passes down
> instead of having to bind a helper variable first.
>
> A brace holding exactly one name that was matched from source tokens keeps substituting
> those tokens, so a subruledef argument still morphs into the inner rule the way it does now.
> Anything else in the braces is one expression, evaluated in the scope of the enclosing rule.
>
> Those expressions can also name labels declared in the same block, including labels that
> appear after the instruction doing the referencing, and the program counter, which reads as
> the address of the instruction the substitution belongs to. A label's address reflects where
> the block's own instructions land. Because an instruction's size can depend on a value that a
> later instruction moves, the block is evaluated repeatedly until the encoding stops changing,
> and reports that it did not converge when it cannot settle.
>
> An expression in braces is an ordinary expression, so it can itself contain an `asm` block,
> nested to the same depth limit that applies anywhere else.
>
> Empty braces stay an error, and so does anything left over between the end of the expression
> and the closing brace.

Word count: ~215. Slightly over the <= 200 recommendation, well under the 500 hard cap. The
overage buys fairness on the two closure behaviors (`$` and nesting): both are tested, so both
must be stated. Trimming them from the description while keeping their tests would be a hidden
requirement, which is the single most common revert cause.

Rule-7 audit on this draft: it states four general principles (braces hold an expression; one
name that came from tokens keeps splicing tokens; block labels and pc are in scope; iterate to
stability). It does NOT enumerate which cases are hard, does not name a pipeline position, and
carries no worked example. No sentence spotlights a pitfall.

## 7. File footprint

**Measured, not estimated.** The repo's real meaningful-LOC ratio was computed over the three
files this change touches most (`eval_asm.rs` 0.63, `instruction.rs` 0.67, `matcher/mod.rs` 0.57),
giving **0.60-0.62** — customasm's Allman brace style with blank-line separation strips hard under
Counter 2. All figures below use 0.60.

The core of the change (expression parse, classification, token-splice preservation, deferred
binding, guess propagation) was then written as real code in the repo's style and measured:
**296 raw / 179 meaningful**. Everything else is scaled off that measured ratio.

| Piece | Path | Raw | Meaningful | Entailed by |
|---|---|---|---|---|
| Expression parse + classification in the brace position | eval_asm.rs | 110 | 66 | "braces hold one expression" |
| Token-splice preservation path | eval_asm.rs | 45 | 27 | subruledef morphing must survive |
| Deferred per-iteration evaluation | eval_asm.rs | 95 | 57 | "labels in the same block are visible" |
| Guess/resolution propagation + position tracking | eval_asm.rs, instruction.rs | 70 | 42 | "evaluated until the encoding stops changing" |
| `$`/pc context threading into the deferred eval | eval_asm.rs, resolver/eval.rs | 40 | 24 | `$` is an ordinary symbol in an expression |
| Nested `asm { }` inside a brace expression | eval_asm.rs | 60 | 36 | `Expr::Asm` is a variant of the parsed type |
| Error span mapping back into original source | eval_asm.rs, diagn | 45 | 27 | the error fixtures |
| Call-site integration, struct threading, exports | eval_asm.rs, mod.rs, expr/eval.rs | 65 | 39 | — |

TOTAL: **~530 raw / ~318 meaningful** across 5 modified files.

**Leanest plausible agent solution: ~229 meaningful** (0.72x the reference, assuming inlined
helpers and minimal error plumbing). That clears the 200 floor with the buffer requested, and it
is the number that matters because Counter 2 is measured on the PASSING AGENT's diff.

**Why the two added pieces are closure, not scope creep.** Both were tested against the question
"does excluding this cost more code than including it?":

- `$` / pc in a brace expression: `$` is resolved by the ordinary symbol resolver
  (`resolver/eval.rs:348`). Once braces hold expressions, `{$ + 2}` parses and evaluates by
  default. Excluding it would require an explicit walk-and-reject pass.
- Nested `asm { }`: `Expr::Asm(Span, AstTopLevel)` is a variant of `expr::Expr`
  (`expression.rs:29`) — the exact type the brace now parses. It is admitted by construction.
  Rejecting it would need a deliberate special case. Including it costs the recursion-depth and
  position accounting; excluding it costs a guard plus a diagnostic plus fixtures.

**Considered and DROPPED as genuine creep: per-iteration match-set revalidation.** I checked
whether a changing deferred value can change which rule matches, which would force re-running
`match_instr` each iteration. It cannot: the substituted text is a synthetic variable name that is
stable across iterations, so the match set is fixed, and constraint re-evaluation already happens
per iteration inside `resolve_instruction_inner` (eval_asm.rs:416). Not implemented, not tested,
not counted.

**Lever explicitly REJECTED: local/hierarchical labels inside asm blocks.** PR #120 (CLOSED)
implements exactly that capability. Its diff targets `src/asm/state.rs`, a file that no longer
exists after the decls/defs/resolver restructure, so there is no file-set overlap with this
design — but it is the central capability of a published diff, and the exclusivity rule is
existence-based, not overlap-based. Out of scope.

**API dependencies verified against base:** `expr::parse(report, walker)` exists
(`expr/parser.rs:4`) and `syntax::Walker` is `#[derive(Clone)]` (`syntax/walker.rs:4`), so the
classification can either backtrack by clone or parse-then-inspect the resulting `Expr`. There is
no cursor-restore API, which is why the parse-then-inspect form is the likely natural choice —
and that is precisely where trap 2's classification decision sits.

## 8. Solution outline — pure-function helpers

- `parse_substitution_body(walker, report) -> SubstitutionBody` — decides token-splice vs
  expression by looking ahead for `identifier` immediately followed by `}`; otherwise calls
  `expr::parse`. Maps to description requirement 2.
- `classify_substitution(name, eval_ctx) -> SubstKind` — token-splice only when the name carries
  a token substitution; value otherwise. Requirement 2.
- `bind_deferred_substitutions(instr, labels, eval_ctx, ctx) -> ResolutionState` — per iteration,
  evaluates each held expression with labels in scope and binds the synthetic local.
  Requirements 3 and 4.
- `merge_substitution_resolution(value, resolution)` — folds a guess value into the block's
  `ResolutionState` so both loops re-run. Requirement 4.

The existing fixpoint in `eval_asm::resolve_iteratively` is reused; the new work is that
substitution values are recomputed inside `resolve_once` rather than once before the loop:

```rust
loop {
    let result = resolve_once(..., labels, instrs, ...)?;
    if result.resolution.is_stable_or_resolved() { break; }
}
```

## 9. Test file outline

Path: `tests/expr_asm_<hex>/` — golden `.asm` fixtures matching the repo's existing convention
(inline `; = 0xNNNN` expectations and `; error: ...` annotations), plus `test.sh`.

Block 1 — token-splice preservation (regression surface for trap 2): subruledef morph through a
bare brace, morph through a nested rule, morph where the argument excerpt already contains a
synthetic substitution variable.

Block 2 — expression evaluation: arithmetic, shifts, masks, parenthesized, member access,
builtin function call, nested rule parameter arithmetic.

Block 3 — labels in expressions (trap 1): backward reference, forward reference, expression whose
value changes the referencing instruction's own size, two labels straddling a variable-size
instruction.

Block 4 — convergence and guesses (trap 3): a block that settles on iteration 3, a block that
cannot settle and must report non-convergence, a guess that must not be observed as zero.

Block 5 — program counter in expressions: `{$}` in a single-instruction block, `{$ + 2}` where
the offset lands on the next instruction, `$` in a block whose preceding instruction has
value-dependent size, `$` combined with a block label.

Block 6 — nested asm blocks in expressions: a brace expression containing an `asm` block, that
inner block referencing its own label, an inner block referencing an outer block's label, and
the recursion-depth limit reached through braces rather than through rule bodies.

Block 7 — errors and edges: empty braces, trailing junk, unknown name, non-integer value,
recursion depth, unicode identifier, zero-size block.

Estimated 60-90 fixtures. Count is coverage-driven, not a target — TEST-COUNT-RAISES-PASS-RATE
(HARDENING law) means breadth is not a difficulty lever here.

5-axis coverage: every description sentence has fixtures in blocks 1-4; every new error path is
in block 5; every branch of `classify_substitution` and `bind_deferred_substitutions` is covered;
edge cases are block 5; the stated inverse (token-splice vs value) is block 1 against block 2.

## 10. Forced trait bounds / generics

Rust-specific forced signatures discovered by sketching the helpers first:

- `AsmSubstitution` must own its `expr::Expr` (not borrow the excerpt) because the excerpt string
  is rebuilt per iteration. This forces an owned-expression field and drops a lifetime parameter
  that the current struct does not carry.
- `bind_deferred_substitutions` needs `&mut expr::EvalContext` while `resolve_once` already holds
  `&instrs[cur_instr]`; the existing code works around this with `std::mem::replace` on
  `instr.matches` (eval_asm.rs:409). The same pattern is forced for substitutions. This is an
  A4 host-language-semantics pressure point and the repo demonstrates the correct pattern, so it
  is fair.

## 11. Predicted trap matrix

| # | Trap | Arsenal class | Why agents hit it | Pre-empt sentence (in section 6) | Test that catches it |
|---|---|---|---|---|---|
| 1 | **Eager evaluation.** `perform_substitutions` runs once in `eval_asm` before the fixpoint and before any label exists (eval_asm.rs:89). The natural extension parses AND evaluates there, which structurally cannot see block labels or refresh across iterations. | F-1 convergent-architecture wall / S1 | The existing call site is the obvious place to extend; nothing signals that evaluation must move into the per-iteration pass. | "expressions can also name labels declared in the same block, including labels that appear after the instruction doing the referencing" | Block 3: forward label reference; block 4: settles on iteration 3 |
| 2 | **Token/value duality.** `{r}` for a subruledef argument must splice source tokens (`get_token_subst`, eval_asm.rs:572); `{r + 1}` must evaluate. Uniformly evaluating breaks subruledef morphing. | S3 baseline-preservation through a shared chokepoint + S6 two-evaluators | One brace syntax, two evaluation channels; the agent sees one construct and picks one channel. | "a brace holding exactly one name that was matched from source tokens keeps substituting those tokens" | Block 1, plus the 53 EXISTING `tests/expr_asm/` fixtures run in base mode |
| 3 | **Guess propagation.** A deferred value can be unknown mid-fixpoint. Treating it as an error kills forward references; treating it as zero converges the outer resolver on a stale size and emits wrong bytes. | F-2 bidirectional seam | The guess lattice (`mark_guess` / `should_propagate` / `handle_value_resolution`) is repo internals with no signal from the description. | "the block is evaluated repeatedly until the encoding stops changing, and reports that it did not converge when it cannot settle" | Block 4: guess-not-zero, non-convergence |

**Orthogonality** (explicitly required): trap 1 is about WHEN evaluation happens, trap 2 about
WHICH channel a brace uses, trap 3 about HOW unknowns propagate. Different symptoms (unknown
symbol / unrelated base-test regression / wrong bytes downstream), different tests, and no single
edit clears more than one.

**The two closure behaviors DEEPEN the existing traps rather than adding a fourth axis**, which
is the intended outcome — widening the trap count would have been the scope creep to avoid.

- `$` in a brace expression sharpens trap 1 from "evaluate later" to "evaluate later AND per
  instruction". An agent that defers correctly but binds all of a block's substitutions once per
  ITERATION rather than once per INSTRUCTION gets `$` right for the first instruction and wrong
  for every one after it. That is a discriminator trap 1 did not previously have, and it is
  invisible in any single-instruction fixture — which is exactly the shape agents self-test in
  (HARDENING P3, self-test shadow). Block 5 fixtures are therefore multi-instruction by design.
- Nested `asm` blocks sharpen trap 3: a guess must now propagate across two nesting levels and
  merge into both loops' `ResolutionState`. An implementation that marks guesses correctly at one
  level but swallows them at the boundary passes every single-level fixture.

**Interdependence:** deferring evaluation (fix 1) is what creates the unknown-value case (trap 3)
and removes the natural access to token text (trap 2). Reverting to text splicing to rescue
trap 2 re-breaks trap 1. The three cannot be sequenced independently.

**CONTRACT-STATED / FIX-HIDDEN check** (HARDENING section 1), run per trap:
- Trap 1: the contract names WHAT is visible (labels, including later ones) and that the block
  re-evaluates. It never says where evaluation lives in the pipeline. Fix hidden. PASS.
- Trap 2: the contract states the token-splice rule as a behavioral absolute. It does not name
  `get_token_subst`, nor that `set_token_subst` is skipped when the excerpt already contains a
  synthetic variable (instruction.rs:497). Fix hidden. PASS.
- Trap 3: the contract states the iteration and the failure mode. It does not describe the guess
  lattice. Fix hidden. PASS.

Predicted Wrong Logic: 30-40%. That is above the 25% line, which the current one-tier model
treats as genuine algorithmic difficulty rather than a tier signal.

## 12. Tier + category

- Tier: Olympus (single tier since the 2026-07 sprint)
- Sub-rank target: Good
- Category: **enhancement** — it widens an existing construct's accepted syntax and evaluation
  staging; it does not introduce a net-new public type or directive.

## 13. Predicted Nova pass rate

- Predicted: 10-25%
- Reasoning: three interdependent traps at roughly 0.5 / 0.6 / 0.6 miss probability, but they are
  not independent, so the naive product (~18%) is a lower bound rather than an estimate. The
  53-fixture existing suite makes trap 2 a hard regression gate that a thorough agent WILL catch
  once it runs the base suite, which pushes the rate up. Trap 1 is the load-bearing one.
- Sanity: under the 40% ceiling, above 0%. Trap 1 alone has a plausible single-insight fix
  ("evaluate later"), so 0% is unlikely.

## 14. Quality-gate checklist

- [x] Repo understanding: architecture, subsystems, entanglement zones, test framework, template
      fixture all established
- [x] Existing PR check: 44 PRs enumerated, all states; adjacent diffs (#120, #119, #127, #248,
      #249) pulled and read; no PR implements brace-expression substitution
- [x] Death-class guard run against TOO-EASY.md (see below)
- [x] Title verb-led, names the subsystem
- [x] Shape declared with citation
- [x] Public surface enumerated including diagnostics
- [x] Canonical form spelled out
- [x] <= 1 codebase-inferable requirement
- [x] Description draft ~185 words, plain prose, no headers, ASCII
- [x] File footprint sketched against real files with real current LOC
- [x] **LOC clears the floor.** Core written as real code and measured at 179 meaningful / 296
      raw; full closure ~318 meaningful; leanest plausible agent ~229. Repo ratio measured at
      0.60-0.62, not assumed. Re-verify with `.claude/hooks/effective_loc_check.py` on the real
      solution.patch before submit.
- [x] Helpers map 1:1 to description sentences
- [x] Fixpoint reuse documented
- [x] Test outline in the repo's fixture convention
- [x] Forced signatures documented
- [x] 3 traps, each with pre-empt sentence, catching test, and CONTRACT-STATED/FIX-HIDDEN pass
- [x] Predicted pass rate under the 40% ceiling and above 0%
- [x] Category honest
- [ ] Feature is NOT pattern-followable — see risk below
- [x] Not in RULES section "Features already used"

## Death-class guard (TOO-EASY.md pre-pick, all 5)

1. **Single guard at many sites (uniform-wrap)?** No. Three distinct mechanisms in three
   different stages.
2. **Single-subsystem fully-specified mechanical transform?** No. Spans substitution parsing,
   the expression evaluator, the block fixpoint, and the instruction matcher.
3. **Hardness depends on the spec NOT stating something?** No. Every trap's contract is stated
   in section 6 and the fix stays hidden in all three cases (checked individually above). This
   is the ironcalc law and it is the check this design was built to survive.
4. **Port of a spec the model knows?** No. `asm` blocks with brace substitution are a customasm
   invention with no external spec, no textbook algorithm, and no sibling implementation. This
   is why the earlier branch-relaxation thesis was dropped.
5. **Survives full specification?** Yes. The wall is where evaluation sits relative to the
   fixpoint, which is a property of this codebase's architecture, not a withheld rule.

**Oracle check (fundsp CORRECT-ARCHITECTURE-ABSORBS law).** The repo contains a PARTIAL oracle:
`resolve_once` already rebinds labels per iteration (eval_asm.rs:380-385), which demonstrates the
per-iteration pattern an agent must extend to substitutions. This is the single largest residual
risk in the design — a strong agent may read that loop and generalize it for free, collapsing
trap 1. Mitigation: trap 2 and trap 3 do not funnel through that loop, so the design does not rest
on trap 1 alone. This must be re-checked against the first batch's passing patches.

## Why this is not a duplicate

Closest prior work in our pool is `calyx-unused-port-elimination` (whole-program fixpoint over an
IR, F-2 lead) and `pulldown-cmark-gfm-autolinks` (F-1 pipeline-stage wall). This shares their
PATTERNS but not their subsystem, repo, language surface, or trap shape: calyx's fixpoint is a
liveness analysis over a static graph, this one is an evaluation-staging problem inside a nested
sub-assembler. No customasm submission exists in `problems/`, `rejected/`,
`diamond-problems/`, or `Olympus-Approved/`.

Residual derivative risk is LOW: the platform dedupe compares feature cores, and "brace
substitution inside customasm asm blocks" has no canonical cross-repo equivalent the way GROUPING
SETS or a spread operator does. This is the specific reason the branch-relaxation thesis was
dropped — that one IS a textbook feature core.

## Predicted iteration cycles: 2-3

## Blocking items before Step 2 (Dockerfile)

1. Build-measure the solution slice and confirm human-effective >= 200 with buffer; apply lever 1
   if short. This gate failed at sketch time and must clear before any test is written.
2. Reproduce all three traps by writing the natural-but-wrong implementation and confirming each
   fails with the predicted misdirecting symptom (HARDENING 3a.4). Trap 1's f2p is already
   reproduced on base: `asm { inner: ldi {inner} }` fails today while bare `ldi inner` succeeds.
3. Re-run the SIX-CHECK immediately before submit.
