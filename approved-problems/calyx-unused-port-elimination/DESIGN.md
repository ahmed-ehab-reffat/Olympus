# DESIGN — calyx-unused-port-elimination

## 0. Candidate brainstorm (STEP 5)

| # | Idea | Shape | Predicted pass | Verdict |
|---|---|---|---|---|
| 1 | **Whole-program unused port elimination** (this doc) | O-Composite-add + O-Algorithm-correctness traps | 10-20% | **CHOSEN** |
| 2 | Interprocedural combinational-cycle detection across component boundaries | O-Algorithm-correctness | ~15% | REJECT — validation/reject contract = DEAD class (TOO-EASY taxonomy row 1) |
| 3 | Re-enable + rewrite the disabled `simplify-guards` BDD pass | O-Pipeline-easy | 60%+ | REJECT — pointwise-decoupled pure function on guards, golden compresses to ~150 LOC |
| 4 | Transitive / nested `ref` cell threading (issue #2079) | O-Composite-extend | ~30% | REJECT — `dump_ports` already threads refs hierarchically; LOC-ceiling |
| 5 | `component-inliner` support for invoke-with-comb-group + multi-binding instances | O-Composite-extend | ~35% | REJECT — surgical gap fix, ~150-250 LOC, under floor |

## 1. Title

Add whole-program elimination of unused component ports

## 2. Shape classification

**O-Composite-add** (new capability spanning analysis + pass + IR + pass registration), carrying
**O-Algorithm-correctness** traps (whole-program fixpoint, effect roots, direction inversion).
Target files 6-8, solution 500-620 effective LOC, tests ~60-80, description <=200 words.
Best agent per SHAPES matrix: Vega; Orion competitive because the API surface is named.

## 3. Repo + gates

- Repo: `calyxir/calyx` @ `cb25dcb8e5074915887048e2780e2c7bedcba4e8` (HEAD 2026-07-23), 607 stars, MIT, 120 commits/12mo.
- Gate 1 behavioral gap: base keeps every port + every driver of a component whose outputs nobody reads. Verified on `tests/passes/dead-cell-removal.futil` (component `add` retains `adder`, `outpt`, `do_add` although `main` never reads `add.out`). Optimizer-pass precedent for this gate: pest-inliner, pest-charclass, pest-unused-rule-elim, lightningcss-selector-simplify all approved.
- Gate 2 saturation: no upstream reference implementation to memorize; calyx-specific IR.
- Gate 3 uniform-wrap: two OPPOSING pressures (under-delete fails new tests, over-delete breaks base golden tests). Not one mechanism.
- Gate 4 LOC ceiling: net-new analysis + pass + IR helper + second axis (unused `ref` cells). ~500-620 eff.
- Gate 5 cold: issue #1200 open + untouched since 2022-10; `dead_cell_removal` last touched 2025-04; no commits in the area.
- Gate 7 dedup: no hit for liveness / dead-code / unused-port across `problems/`, `rejected/`, approved pool.
- Gate 7b exclusivity: canonical org resolved (`calyxir/calyx`, no move). PR search over `dead code`, `liveness`, `unused port`, `dead port`, `interprocedural` (all states) returns no PR implementing whole-program port removal.
- Gate 8 defined behavior: issue #1200 authored by maintainer rachitnigam, confirmed in-thread as a whole-program analysis. Behavior is maintainer-blessed, not NeedsDesign.
- Gate 9 flakiness: calyx tests are `runt` golden-file comparisons over a deterministic CLI. To verify 3x before submit.
- Gate 10 quota: 0 of our submissions on calyx; 607 stars, niche, not a household name.

## 4. Feature specification (the contract the tests assert)

A new pass, `dead-port-elimination`, run through the normal pass pipeline. It performs a
whole-program (closed-world) analysis and then rewrites the program.

**Liveness rule (one general principle, deliberately not enumerated):** a port is live when it can
affect observable behavior. Concretely the contract states:

- The entrypoint component's signature is never changed.
- Interface ports (`@go`, `@done`, `@clk`, `@reset`) are never removed.
- An output port of a non-entrypoint component is dead when no instance of that component has that
  port read anywhere in the program.
- An input port of a non-entrypoint component is dead when nothing inside that component reads it.
- Removing a port removes every assignment that reads or writes it, at every instance, including
  `invoke` bindings.
- The analysis runs to a fixpoint: a removal that makes another port dead is itself propagated.
- A cell that is a `ref` cell or is marked `@external` is a root; its ports stay live.
- A `ref` cell in a component's signature that is never mentioned inside the component is removed
  from the signature and from every `invoke`'s ref bindings.

**Deliberately withheld (the FIX, not the CONTRACT):** that guards carry port reads; that control
(`invoke` bindings, `if`/`while` condition ports) carries reads; that `Component::signature` inverts
port direction relative to an instance; that the pass framework's whole-program hook is
`Visitor::start_context`; the fixpoint's iteration structure.

## 5. Trap matrix (HARDENING arsenal)

| # | Trap | Arsenal class | Why it misdirects | Expected kill |
|---|---|---|---|---|
| T1 | Reads live in BOTH structural assignments and the control program (invoke bindings, if/while cond ports) | S6 two-evaluators | Simple probes have no invoke-only reads; failure shows as an over-deleted port far from the control code | high |
| T2 | Effect roots: `ref` cells and `@external` cells escape observation | S3 baseline preservation | Over-deletion breaks an EXISTING golden test, pointing at an unrelated pass | high |
| T3 | Fixpoint: one removal creates the next dead port | S4 machinery-riding | A single pass passes shallow tests, fails only on chains | medium |
| T4 | Signature direction inversion: an input port is an OUTPUT of the `ThisComponent` signature cell | A4 host/framework semantics | Wrong-direction filter silently removes the wrong side | medium |
| T5 | Guard operands are reads (`Guard::Port`, `Guard::CompOp`) | A3 reuse-the-machinery missing arm | Assignment-source-only read collection over-deletes | high |
| T6 | Interface ports must survive even when unread | fairness floor, stated | — | low (stated) |

Traps are interdependent: fixing T1 (count control reads) surfaces T3 (chains now reach further);
fixing T5 (count guard reads) changes which ports T2 must protect.

## 6. Files

**New**
- `calyx/opt/src/analysis/port_liveness.rs` — whole-program read collection + fixpoint (~260-320)
- `calyx/opt/src/passes/dead_port_elimination.rs` — the rewrite (~200-260)

**Modified**
- `calyx/opt/src/analysis/mod.rs` — export
- `calyx/opt/src/passes/mod.rs` — module + re-export
- `calyx/opt/src/default_passes.rs` — pass registration
- `calyx/ir/src/component.rs` or `structure.rs` — port removal helper (~30)

## 7. Test plan

Rust integration tests under `calyx/opt/tests/` driving the public API (parse source, build
context, run the pass, assert on the printed component). Behavioral through public API, no internal
symbol imports, deterministic. Base mode runs the repo's existing `runt` golden suites plus
`cargo test`.

## 8. Open items

- Confirm the exact printed-IR assertion surface.
- Confirm base-mode test command and runt availability offline.
- Naive-agent benchmark + trap reproduction before writing final tests.
