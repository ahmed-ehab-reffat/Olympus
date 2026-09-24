# SHAPES — Mars + Olympus Shape Taxonomy + Agent-Shape Matrix

Forensic clustering of 13 approved problems (5 Mars + 7 Olympus + 1 cross-tier) into 10 shapes. Each shape has a documented pass-rate band, file count, dominant verdict, solver-vs-our LOC ratio, and best agent. **Pick a shape FIRST**, design within its constraints.

> **Read first:** `PLAYBOOK.md` (foundational patterns + approveds tables). This file (SHAPES.md) houses Patterns 11-13, referenced by every author-side skill.

**Section index:**
- Pattern 11 — Mars Solid Shape Taxonomy (6 shapes: A1, A2, B, C, D-new, D-change)
- Pattern 12 — Olympus Shape Taxonomy (4 shapes + O-Trap historical)
- Pattern 13 — Best Agent by Shape (decision matrix)
- Vega's specific profile (refined from 7-Olympus-problem data)

When in doubt, match against `Appendix A` in `PLAYBOOK.md` ("Which Approved Problem Matches Your Use Case?").

---

## Pattern 11 — Mars Solid Shape Taxonomy (6 Shapes)

5 approved Mars problems cluster into 6 shapes. Each has a predictable pass-rate band, verdict pattern, solver/our LOC ratio, and best agent.

> **⚠️ Pass-rate cap superseded these historical bands (admin 2026): Mars is now ≤30%.** The per-shape rates below are OBSERVED from approvals at the time. Shapes that historically landed above 30% (B at 50-55%, D-change at 40-45%) are NOW TOO EASY as built — they need extra interdependent+misdirecting traps to pull under the 30% cap. Use these rates to pick a shape's STRUCTURE, not as an approval target; the target is ≤30% regardless of shape.

### Shape A1 — Distributed Pipeline Modification

**Example:** lightningcss-selector-simplify-fixpoint
**Definition:** 3 files of similar weight, modify existing pipeline, no enum signature change.
**Pass rate:** 10–15% (lower edge of Mars sweet spot)
**Verdict diversity:** 4 types (Missed Req, Regression, Integration Error, Syntax Error)
**Solver/our LOC:** ~2.07× (agents over-implement)
**Solver/our files:** ~2.17× (agents touch more files)
**Solver time:** ~28 min (slowest Mars)
**Solver msgs:** ~488 (highest Mars)
**Best agent:** Nova→Orion (slow exploration pays off)
**When to use:** Tricky semantics buried in existing pipeline. Low pass rate, diverse failures.

### Shape A2 — Concentrated + Signature Change

**Example:** pest-factorizer-fixpoint
**Definition:** 1 main file with bulk + thin wiring elsewhere; signature change on existing function.
**Pass rate:** 20–25%
**Verdict diversity:** 4 types
**Solver/our LOC:** ~1.71×
**Solver/our files:** ~0.67× (agents consolidate)
**Solver time:** ~7 min (fast)
**Solver msgs:** ~59 (low)
**Best agent:** Nova→Orion (fast)
**When to use:** Rewrite an existing pass with cleaner architecture. Signature change creates regression risk.

### Shape B — Add New Public API List

**Example:** pest-unused-rule-elim
**Definition:** New module(s) with explicit list of public functions; existing code wires them additively.
**Pass rate:** 50–55% (highest Mars)
**Verdict diversity:** Mono (only Missed Requirement)
**Solver/our LOC:** ~1.28×
**Solver/our files:** ~0.47× (agents consolidate to 1–2 files vs our 3)
**Solver time:** ~7 min
**Solver msgs:** ~69
**Best agent:** **Orion-alone smashes (2/2)**
**When to use:** Description names the API surface explicitly. No regression risk because new module is additive.

### Shape C — Additive Extension (No Signature Change)

**Example:** pest-validator-hardening
**Definition:** Single file modified, additive extension of existing class/module.
**Pass rate:** 20–25%
**Verdict diversity:** Mono (only Missed Requirement)
**Solver/our LOC:** ~1.02× (matches our LOC almost exactly)
**Solver/our files:** ~1.0×
**Solver time:** ~11.5 min
**Solver msgs:** ~83
**Best agent:** Nova→Orion
**When to use:** Strengthen an existing validator/classifier with new diagnostic rules. Each rule is enumerable.

### Shape D-new — New Cross-Crate Enum Variant

**Example:** pest-error-recovery
**Definition:** Add a NEW enum variant requiring exhaustive-match arms in 4+ crates.
**Pass rate:** 20–25%
**Verdict diversity:** 4 types — **Integration Error dominates (43%)**
**Solver/our LOC:** ~1.44×
**Solver/our files:** ~0.95×
**Solver time:** ~22 min
**Solver msgs:** ~250
**Best agent:** **Orion-alone smashes (2/2)**
**Failer file pattern:** Over-touch (16.1 files vs solvers' 14.3) — modifying things that don't need it
**When to use:** New AST/optimizer variant requiring multi-crate exhaustive-match handling.

### Shape D-change — Cross-Crate Variant Signature Change

**Example:** pest-extended-skip
**Definition:** CHANGE existing enum variant signature (e.g., `Skip(Vec<&str>)` → `Skip(Vec<SkipChoice>)`); requires updating all consumers.
**Pass rate:** 40–45% (high — existing structure provides scaffolding)
**Verdict diversity:** 4 types — **Regression dominates (44%)**
**Solver/our LOC:** ~1.07×
**Solver/our files:** ~1.01× (matches our file count)
**Solver time:** ~12 min
**Solver msgs:** ~201
**Best agent:** Nova→Orion + Vega (Vega solves 1/1 in mixed runs)
**Failer file pattern:** Under-touch (7 files vs solvers' 8.1) — missed an exhaustive match
**When to use:** Refactoring an existing enum variant's payload while preserving its semantic role.

### Mars Shape Summary Table

| Shape | Files | Pass | Verdict | Dominant verdict | Solver/our LOC | Solver/our files | Best Agent |
|---|---|---|---|---|---|---|---|
| A1 | 3 dist | 10-15% | Diverse (4) | Missed | ~2.07× | ~2.17× | Nova→Orion (slow) |
| A2 | 3 conc + sig | 20-25% | Diverse (4) | Missed | ~1.71× | ~0.67× | Nova→Orion (fast) |
| B | 3 (2 new) | 50-55% | Mono | Missed | ~1.28× | ~0.47× | **Orion-alone** |
| C | 1 dense | 20-25% | Mono | Missed | ~1.02× | ~1.0× | Nova→Orion |
| D-new | 15 (4 crates) | 20-25% | Diverse | **Integration** | ~1.44× | ~0.95× | **Orion-alone** |
| D-change | 8 (multi-crate) | 40-45% | Diverse | **Regression** | ~1.07× | ~1.01× | Nova→Orion + Vega |

---

## Pattern 12 — Olympus Shape Taxonomy (4 Shapes + O-Trap Historical)

7 Olympus problems cluster into 4 shapes (5 counting the deprecated O-Trap).

### Shape O-Composite — Multi-Subsystem Cross-Package Feature

Two sub-shapes:

**O-Composite-extend** (refactor existing aggregation across packages)
- Example: dagster-dep-health
- Pass rate: 25-30% (historical; must be hardened to <= 20% per the 2026-06-26 Olympus ceiling)
- Best agent: **Orion (2/2)**
- Files: 9+
- Solver/our LOC: ~0.98× (agents can be more concise)
- Why: Symmetric refactor with clear architecture; Orion's decisive commit pays off

**O-Composite-add** (add new language feature spanning parser/compiler/VM/runtime)

> **Confirmed 2026-09-04 by `go-workflows-channel-drain`** (Go, ACCEPTED 2/10 = 20%, 9 files,
> 351 effective LOC, 102 tests). The shape holds outside compiler stacks: here the span was
> internal concurrency core (channel + selector + cooperative scheduler) -> workflow-state ->
> public wrappers. Two shape-specific notes. (1) The band was decided not by the new capability but
> by a guard on an ADJACENT EXISTING API the feature sits beside (F-20 / Pattern 34, 8/10) — in
> O-Composite-add the new surface almost always has a sibling, so budget a test for it. (2) Nova
> cleared it twice unaided, so the "best agent: Vega" note is a preference, not a requirement.
- Examples: goja-using-declarations, **yaegi-execution-tracer** (2026-05-14)
- Pass rate: **10-20%** (goja 16.7% Vega 3/5; yaegi 10% Castor 2/20 at Diamond eval → tier-downgraded to Olympus)
- Best agent: **Vega (3/5)** for runtime/VM additions; **Mixed (frame-anchored architecture)** for interpreter tracer
- Files: 5-12 (yaegi was 5; goja was 12)
- Solver/our LOC: ~2.13× goja; ~1.0× yaegi (compact at 441 LOC)
- Why: Multi-stage feature add; heavy deliberation across subsystems. yaegi confirmed sub-shape: **interpreter-tracer variants need frame-anchored state propagation, not goroutine-id maps** (16/18 Castor used wrong approach).
- **Hint discipline:** abstract architectural hints fail (89-90% failure persists); concrete counter-example values succeed (100%→22% drop on TotalLines via "2-line func × 2 calls = 2, not 4").

### Shape O-Pipeline — New Variant + Cascading Optimizer Effects

Two sub-shapes:

**O-Pipeline-easy** (familiar coalescing/merging algorithm)
- Example: pest-charclass
- Pass rate: 25% (historical; must be hardened to <= 20% per the 2026-06-26 Olympus ceiling)
- Best agent: **Vega (3/5)**
- Files: 5
- Solver/our LOC: ~1.81×
- Algorithm: pattern matching + interval merging (familiar)

**O-Pipeline-hard** (invent transformation algorithm)

> **Confirmed 2026-09-10 — rocketpy-propellant-slosh, ACCEPTED at 1/10 on Nova+Orion.** The shape
> survives without Vega: the band came from threading ONE new quantity through every stage of an
> existing integrator (tank API, mode ordering, state vector, rail / 6 DOF / 3 DOF / parachute),
> so the per-phase coupling rules are the trap surface rather than the algorithm itself. Agents
> reliably built the whole feature (every failing run passed >= 140 of 146) and separated on two
> phase/domain details. Expect near-misses to be DENSE in this shape, and expect Auto Review to
> comment on that distribution.
- Example: pest-seq-rewriter
- Pass rate: 15%
- Best agent: **Vega (2/6)**
- Files: 4
- Solver/our LOC: ~1.78×
- Algorithm: sequence transformation with cascading effects on later passes

### Shape O-Algorithm — New Variant + Algorithmic Trap

Two sub-shapes:

**O-Algorithm-coverage** (missing-element-in-list trap)
- Example: pest-inliner
- Pass rate: 10%
- Best agent: **Orion-alone (1/1)**
- Files: 4
- Solver/our LOC: ~1.49×
- Trap: agents must remember to include the new variant in coverage points (e.g., `count_references` must include `InlinedRule`)
- Why Orion: "implement everything I see" approach happens to include the new variant

**O-Algorithm-correctness** (subtle algorithm shape trap)
- Example: pest-dispatch
- Pass rate: 8% (lowest non-bypass)
- Best agent: Mixed — Vega + Nova→Orion (1 each in 12 runs)
- Files: 6
- Solver/our LOC: ~1.27×
- Trap: subtle algorithmic correctness (e.g., fallback re-dispatch must use map_top_down, not manual recursion)
- **Wrong Logic at 25%** — agents understand the spec but botch the algorithm

### Shape O-Trap (HISTORICAL ONLY — Bypass-Era)

**Example:** pest-normalizer
**Defining trait:** Universal LLM blind spot defeats every agent. Pass rate 0%.
**Approval method:** Solvability bypass with "agent-fault" message format (no longer permitted post-April 2026).

**This shape is no longer viable.** Agents at 0% pass rate cannot be approved without hints, and hints were removed April 2026. If you hit this shape:
- Resubmit as Mars (≤ 30% Nova band may be reachable)
- Redesign to avoid the universal blind spot
- Pick a different feature

The pest-normalizer bypass message remains the **canonical 6-element bypass format reference** — see Pattern 14.

### Olympus Shape Summary Table

| Shape | Files | Pass | Verdict types | Dominant verdict | Solver/our LOC | Best Agent |
|---|---|---|---|---|---|---|
| O-Composite-extend | 9+ | 25-30%* (harden to <= 20%) | Diverse (4) | Missed | ~0.98× | **Orion** |
| O-Composite-add | 12 | 15-20% | Diverse (4) | Missed | ~2.13× | **Vega** |
| O-Pipeline-easy | 5 | 25% | Diverse (4) | Missed | ~1.81× | **Vega** |
| O-Pipeline-hard | 4 | 15% | Diverse (5) | Missed | ~1.78× | **Vega** |
| O-Algorithm-coverage | 4 | 10% | 3 types | Missed | ~1.49× | **Orion** |
| O-Algorithm-correctness | 6 | 8% | 6 types | Missed | ~1.27× | Mixed |
| O-Trap (HISTORICAL) | 4 | 0% (bypass) | 2 types | Mono-fault | n/a | None |

### Shape note — cross-subsystem language feature (O-Algorithm-correctness, cross-subsystem span)

**Example:** piccolo-to-be-closed (APPROVED Olympus 2026-06-24, 20% on 11 Castor/Orion runs, 8 files / 6 subsystems / 537 eff LOC / 67 f2p tests).

A new language feature implemented across a compiler→opcode→VM→executor→runtime-state→stdlib stack. Designed as Diamond, approved as Olympus — a single coherent feature ceilings at Olympus even when its span is wide, because the difficulty is correctness-of-semantics, not cross-subsystem coordination per se. Verdict type is mono-dominant (FAIL_MISSED_REQUIREMENT) because every failing behavior traces to an explicit spec sentence; this is the O-Algorithm-correctness signature, not O-Composite (which gives diverse verdicts). Solver LOC ran 0.7–0.8× of ours (660–968 vs 537+tests) — agents wrote MORE code and still missed the semantic edges.

**Pivot lesson:** a language feature that reads too easy at Diamond (avg-pass-fraction too high) is often a correct Olympus at the same artifact — re-tier rather than over-harden. Difficulty came from a forced-representation trap + a block-exit-discrimination trap (see `olympus-extreme-complexity-guide.md` + `PATTERNS-ADVANCED.md § Pattern 37`), not from the wide file span.

---

## Pattern 13 — Best Agent by Shape (Decision Matrix)

The agent that solves a problem depends on its shape. Match agent to shape:

### Mars

| Shape | Best Agent | Why |
|---|---|---|
| A1 (distributed) | Nova→Orion (slow) | Agents need exploration time; Nova provides it |
| A2 (concentrated + sig) | Nova→Orion (fast) | Architecture clear once read; Nova converges quickly |
| B (add public API) | **Orion-alone (smashes)** | Description names the API; Orion commits and implements |
| C (additive extension) | Nova→Orion | Existing code provides scaffolding |
| D-new (new variant) | **Orion-alone (smashes)** | "Implement Recover variant + all matches" — Orion's decisive commit |
| D-change (variant sig change) | Nova→Orion + Vega | Existing pattern + heavy refactor — both agents help |

### Olympus

| Shape | Best Agent | Why |
|---|---|---|
| O-Composite-extend | **Orion (2/2)** | Symmetric refactor; commit-and-implement |
| O-Composite-add | **Vega** | Heavy multi-stage; Vega's deliberation |
| O-Pipeline-easy | **Vega** | Familiar algorithm; Vega leads |
| O-Pipeline-hard | **Vega** | Invent algorithm; Vega leads |
| O-Algorithm-coverage | **Orion-alone** | Coverage trap; "implement everything" includes the new variant |
| O-Algorithm-correctness | Mixed | Subtle algorithm; luck-of-the-draw |
| O-Trap (HISTORICAL) | None | Universal blind spot |

### Vega's Specific Profile (Refined from 7-Olympus-problem data)

**Vega total Olympus pass rate: 31.3% (10/32 attempts)** — strongest single Olympus solver.

**Strengths:** O-Pipeline (easy + hard), O-Composite-add, O-Algorithm-correctness (partial).

**Specific blind spots:**
- O-Composite-extend with symmetric aggregation refactor (dagster: 0/2)
- O-Algorithm-coverage (inliner: 0/4 — Orion better here)
- O-Trap universal blind spots (normalizer: 0/5)

See `AGENTS.md § Vega ⚡10 tokens` for full per-shape data.

## Shape note: opt-in checker/analysis mode with provenance tracking (cel-go-strict-dyn, APPROVED Diamond 2026-06-17)

An opt-in EnvOption/flag that adds a NEW analysis pass over an existing pipeline (the CEL type checker) plus a read-only structured-report surface. Single-subsystem, yet platform-Diamond because the difficulty is integration-TIMING (record provenance during the walk vs a later promotion/substitution phase), not algorithm depth or cross-subsystem span.

Design notes:
- An opt-in flag that MIRRORS an already-shipped flag (here HomogeneousAggregateLiterals) does NOT contradict documented default behavior -> NOT a maintainer-philosophy violation. Opt-in additive modes survive the Section-9 philosophy gate (overrides the reflexive "opt-in flag = philosophy risk" read).
- LOC: the analysis core is small; reach the 450 floor with an ADDITIVE READ-ONLY aggregation/report API over the structured output, not by padding the analysis. Refactors are LOC-neutral; only new feature surface adds eff.
- Best-agent: Castor-hard AND opus-hard (the timing wall bites the frontier), unlike a plumbing-wall which is opus-mechanical and ceilings at Olympus. Run the opus-smoke - if it solves from meta, the difficulty must be a destroyed-signal timing wall, not plumbing.

## Shape note: zero-new-API spec-conformance enforcement (yaegi-methodset-enforcement, APPROVED Diamond 2026-06-23)

A Diamond shape distinct from the additive O-Composite-add cluster: instead of adding a public API, make already-illegal input FAIL through the interpreter/compiler's EXISTING error channel and repair its silent corruptions, bringing a static checker to language-spec fidelity. Properties:
- **Dedup moat:** zero new public surface differentiates it from a repo whose approved siblings are all additive-API (yaegi had 14). Pick this shape when similarity risk against an additive cluster is high.
- **Cross-subsystem by construction (Diamond-required):** the check threads through several checker stages (config/typecheck/type + a new internal helper file) whose shared state makes the traps interdependent.
- **Difficulty source:** every leak site must be found (no single named function to implement) + behavioral correctness on subtle spec corners (shallowest-wins SELECTION not just detection, accept-twin legality, error-wording selection), not API breadth.
- **Best agent:** Castor (Diamond). Confirmed traps in KNOWLEDGE.md and PROBLEM-PROFILES.md yaegi-methodset entries.
- **Authoring guard:** the new tests must be ADDITIVE (the grader applies the test patch over the agent's mutated tree) and carry no build tag (grader runs plain `go test`) — see PATTERNS-ADVANCED Pattern 55.

## Shape note: O-Algorithm-correctness / codegen round-trip (typify-object-applicators, APPROVED Diamond 2026-06-25)

A code-generator correctness shape: tests assert real serde serialize/deserialize round-trip behavior on types produced at compile time by the target's own macro (`typify::import_types!`), plus runtime generation-success (catch_unwind) for shapes that panic on base. The difficulty axis is the REPRESENTATION SPLIT (struct vs map/newtype) rather than raw algorithm depth - a single-subsystem feature that still cleared the Diamond band because the same keyword must be honored across two generated representations + a degenerate root edge. f2p trick: schema strings compile on base in the round-trip file, while panic-on-base shapes move to a runtime catch_unwind generation file (keeps the test file loadable on base). Best solved by an agent that treats both representations as the whole problem.

## Shape note: starlark-rust-set-literals (APPROVED Mars 2026-06-25)

New-syntax-feature-at-Mars variant. Spans parser -> AST (new ExprP variants) -> scope resolver -> compiler (new ExprCompiled/ComprCompiled variants) -> bytecode (new instrs + opcode enum) -> runtime -> typing -> analysis lints -> LSP. Looks like O-Composite-add but at Mars LOC (232 eff, 22 files). Key shape insight: a SATURATED syntax feature has no feature-level pass-rate lever, so its Mars difficulty comes entirely from the LONG-HORIZON THOROUGHNESS of keeping the existing baseline suite green (the syntax/opcode change breaks an obsoleted parse-fail golden + the opcode-profile golden). Pass band 8% via thoroughness, not feature depth. Best agent: thorough Orion (the one rollout that ran full suite). f2p shape: new tests use enable_sets dialect source strings -> compile on base but fail-on-base (set syntax absent) -> clean f2p; existing-golden fixups go in solution.patch (platform ignores test.patch edits to existing files).

## Shape note: single-subsystem cost-coverage extension over a static<->runtime dual-maintenance pair (cel-go-cost-coverage, APPROVED Mars 2026-06-24)

CONFIRMS (does not introduce) a single-subsystem MARS shape: an opt-in flag that brings an existing library into a cost/budget/size system, where the SAME operation is estimated STATICALLY (checker/cost.go `Max`) and measured at RUNTIME (interpreter/runtimecost.go `ActualCost`) as maintained twins. The canonical form is the SOUNDNESS INVARIANT: `static.Max >= runtime.ActualCost` must hold through a compound chain, and the obvious bounded-size fix lands static one unit under at large size (the dominant interdependent+misdirecting trap). Best terminal in cost tests = `contains("z")` ONLY (scales with size, sound upper bound, saturates; endsWith/startsWith undershoot, size() is O(1)/vacuous). Eff ceiling is small (192) -> this shape is MARS, not Olympus, unless padded with cross-subsystem surface (the inspection/report API that would do so is pure glue + signature-ambiguity unfair -> drop it, don't pad with it). f2p: tests compile on base but assert the new cost numbers -> fail-on-base; opt-in gating means base behavior is unchanged. See PROBLEM-PROFILES + Pattern 58.

## Shape note: O-Pipeline-hard whose correctness trap lives in the repo's DISTINCT/specialized execution path (glaredb-ordered-aggregates, APPROVED Olympus 2026-06-27)

CONFIRMS the O-Pipeline-hard Olympus shape and pins WHERE its difficulty must sit. A SQL-engine clause feature (aggregate-local `ORDER BY` + `FILTER`) spans parser -> AST -> resolver -> binder -> aggregate-function framework -> hash/ungrouped execution. The defining property: the OBVIOUS pipeline design (insert a global sort before the aggregate) is correct for the linear/grouped cases, and a REPO-SPECIFIC execution path (the hash-table DISTINCT scan) silently breaks the hard case (DISTINCT ordering) with misdirecting output. That single interdependent+misdirecting trap carries the band (10-17% Hard across two batches); the rest of the feature (FILTER, first/last, arg_min/arg_max) is fair coverage + LOC. Reaches Olympus (775 eff / 16 files) because it is genuinely cross-subsystem AND has a robust gating trap; a single-subsystem or trap-less version of the same feature would ceiling at Mars. Difficulty knob = WHERE the trap lives (a specialized internal path), not LOC. See Pattern 60 + PROBLEM-PROFILES.

## Shape note: O-Composite-add with a DUAL-AST compile-floor -- integration difficulty UNDER the semantics (nickel-1336, Olympus SOLVED 1/10=10% 2026-07-03)

CONFIRMS O-Composite-add and adds a difficulty lever specific to language/compiler repos with TWO AST representations (a surface/parser AST + a core AST) bridged by generated-parser code. A feature that threads one new payload through BOTH ASTs + the LALRPOP-generated grammar + ~15 match/initializer sites stacks a COMPILE/INTEGRATION wall beneath the behavioral walls: fast agents (Nova) die at the build (grammar ambiguity from placing new syntax in an overlapping production; missing struct-initializer sites; `&T`-vs-owned mismatches; unresolved imports) before reaching semantics, and only the heavy agent (Orion) carries the full build. Add a SHARED-STRUCT-REPRESENTATION-LEAK (the new state lives on a struct many EXISTING paths observe -> baseline regression that outlives the feature being 100% correct) and you get a 4-orthogonal-wall Olympus (compile / propagate / materialize-vs-template / baseline-regression) landing ~10% with NO misdirecting-trap gimmick -- each wall catches a different agent. Reaches Olympus (439 human-eff / 21 files) on genuine cross-crate breadth; the dual-AST IS the wall, not just plumbing. This pick required a 4-batch hint arc to solve (0-pass-but-fair) -- see Pattern 63 + PROBLEM-PROFILES + olympus-extreme-complexity-guide.

## Shape note: single-subsystem subtyping-arm extension, hardened by a SECOND constructor arm (nickel-enum-widening, APPROVED Mars 2026-07-04, 30%)

CONFIRMS a Mars shape: extend an existing type-RELATION (subsumption/subtyping) with a MISSING constructor arm. The reference is compact (mirror an existing arm), so a SINGLE arm caps the pass-rate high (~44% too-easy) -- passers just write the reference and no in-scope case trips them. The pass-rate LEVER is adding a SECOND, orthogonal constructor arm (here enum WIDTH + FUNCTION variance) that (a) reference-only solvers never write and (b) COMPOSES with the subsystem's existing negative goldens so over-eager solvers regress them (contravariant-domain over-generalization: 2/10 flip `mismatch_enum_match_fun_type` to pass when it still errors). Difficulty knob = NUMBER OF ORTHOGONAL RELATION ARMS x their interaction with the baseline suite, NOT LOC. Fair Mars difficulty also comes from behavior-CHANGE maintenance: a subtyping change flips an existing type-error golden (MissingRow->ExtraRow) + an executable manual doc-snippet (error->value); meta must warn "validate the full existing suite" to keep it fair. f2p shape: source strings through `Program::eval` (no new Rust symbol) fail-on-base (base rejects the widening / errors differently); force the diagnostic direction via a hidden test where base and solution reject with DIFFERENT error kinds. Ceiling is Mars (146 eff, single subsystem) -- the Olympus long-horizon gate is unmeetable for a feature this size; select Mars at submit (tier-gate law). See Pattern 64 + PROBLEM-PROFILES.

## Shape note: single-subsystem O-Algorithm-correctness with 5+ ORTHOGONAL sub-behaviors -- the un-bimodal-able exception (piccolo-finalizers-gc, APPROVED Mars 2026-07-04, 30%)

REFINES the Mars O-Algorithm-correctness shape AND the "single-subsystem = uniform-wrap-capped" rule. A GC/finalization subsystem is single-subsystem but is NOT a uniform-wrap: it has multiple GENUINELY-INDEPENDENT code paths that fail independently (ephemeron marking, finalizer-ordering bookkeeping, argument-consumption plumbing, weak-mode distinction, once-each cleanup). Such a feature is BIMODAL (~50%, "understand the mechanism or not") only while the tests over-concentrate on ONE axis; spreading fair tests across all N independent sub-behaviors drops the rate to the Mars cap because no single agent nails all N. Contrast the true uniform-wraps that DO cap (petgraph membership-validation, kysely predicate-injection = one concept at N sites -> one guard clears all). Diagnostic at pick time: count the subsystem's independent sub-behaviors; 5+ orthogonal ones => hardenable to <=30% by stacking a wall on each; <3 => genuine uniform-wrap, will stay too-easy. Difficulty knob = NUMBER OF ORTHOGONAL SUB-BEHAVIOR WALLS, not LOC and not depth-on-one-axis (though ship both shallow+deep of any fixpoint behavior). Oracle stays observable-post-GC-state-only; solution can be byte-identical across every hardening round (difficulty = test coverage). See Pattern 65 + PROBLEM-PROFILES + KNOWLEDGE (Nova GC blind spots).

## Shape note: Cross-Section Routing (gimli-type-units, APPROVED Mars 2026-07-05)

A variant of the convert/extend shape where the difficulty is structural, not logical. The feature routes a unit KIND to a DIFFERENT output section by version/flavour (v4 type unit -> new `.debug_types`; v5 -> existing `.debug_info`), which forces generalizing a shared, concretely-typed writer helper (`DebugInfo<W>` -> raw `W`) that ALL units flow through. Best agent: none reliably -- 14/20 Nova compile-fail on the generalization. LOC band: SMALL (249 eff -- surgical), so it ships MARS despite cross-subsystem difficulty (difficulty != volume; do not pad to the Olympus floor). Use this shape when a single-subsystem CONVERT feature is too easy via new-behavior walls (reader is the oracle): add a new output section that makes the shared write pipeline load-bearing. Pairs with PATTERNS-ADVANCED Pattern 66.

## Shape note: Cross-Crate Surface-Syntax (small) (nickel-array-rest, APPROVED Mars 2026-07-05, 30%)

An additive surface-syntax feature that touches BOTH crates of a dual-AST codebase (grammar -> parser AST -> core pattern compilation + diagnostics) yet is LOC-SMALL (139 eff). The lesson for the shape taxonomy: cross-crate span is NOT sufficient for Olympus -- if the AST representation is chosen well (nickel: a `rest_index: Option<usize>` boundary that keeps the suffix inside the existing `patterns` slice), the typechecker, both binding-injection passes, and the parser->core bridge (`compat.rs`) all compile UNCHANGED, and only the grammar + the one compile site carry real logic. Best agent: none reliably (30% Nova); the difficulty is the LR(1) grammar reshape + the `lalrpop_util::ParseError::from` wrapping + from-tail index arithmetic, not volume. LOC band: SMALL -> Mars. Diagnostic at pick time: for a surface-syntax feature, sketch which downstream consumers the new AST field forces to change; if a position-agnostic representation leaves typecheck/bindings untouched, expect ~a Mars-sized diff regardless of how many crates the syntax nominally spans. Contrast nickel-1336 (dict catch-all), where a new field on the SHARED `TypeF::Dict` struct DID force every match/construction site in both crates + eval propagation = 21 files = Olympus. Pairs with Pattern 67 (the rejection-case fairness trap this shape tends to invite).

## Shape note: scope-expanded Mars C -- grid-shape point-query family (parry-heightfield-point-projection, APPROVED 2026-07-05)

A convenience-wiring additive feature (fill in a point-query surface other shapes already have) is a Mars C variant, but the CLEAN core can be sub-floor when the hard helper is pre-shipped (parry `convert_triangle_feature_id` -> core 54 eff). Rescue by expanding to a coherent FAMILY (two grid shapes: HeightField + Voxels, 2D+3D) -- feature + location + containment + a new surface query -- to clear >=110 human-eff. Best agent Nova->Orion. Difficulty does NOT come from the wiring (Nova transcribes it, ~70% pass) -- it comes from deepening ONE core behavior into a naive-dominant-reading trap (Pattern 68) + de-crutching an internal helper. Pass band achieved 30% (at cap).

## Shape note: capability-add whose fair minimal solution ALIASES -> tier by passing-LOC, not difficulty (aircompressor-zstd-strategies, ACCEPTED Mars 2026-07-06)

A "implement the missing strategies of a family" capability-add (zstd fast/greedy/lazy/lazy2/btlazy2/btopt/btultra) looks like a Mars D-new / Olympus-Composite-add, but agents ALIAS the whole family to ONE parameterized implementation (10/10) because a single correct matcher satisfies every fair behavior (round-trip + ratio + monotonicity). Consequence for SHAPE + TIER: the passing agent's IRREDUCIBLE LOC is the size of ONE member, not the family -- here 289 human-eff -- so it TIERS AS MARS even at a hard 10% pass rate, regardless of how many members the description names or how big the reference is (663). Difficulty and irreducible-solution-size are INDEPENDENT axes (Pattern 69). Best agent Nova. Difficulty comes from BREADTH of orthogonal FAIR correctness walls the aliased solution must ALL satisfy (ratio, repcode/ll0, MIN_MATCH boundary, streaming-invariant), not from forcing distinct architectures (unfair + untrue). Do NOT force Olympus LOC by requiring a public-API family the aliasing passer already writes -- no-op on the passing floor.

## kcl-union-override-typecheck (APPROVED Mars 2026-07-07) -- shape note: Shape C (concentrated additive check) + cross-file misdirection + machinery-reuse LOC risk
- Shape C variant: an additive correctness check bolted onto an existing pass (the binary-operator / config-merge type checker), 2 source files, no signature change. Reference 150 Counter1 / 114 Counter2, 14 tests, 8.3% pass.
- Cross-file misdirection axis: the failing test is a silent compile_only pass; grepping the error strings lands agents in config.rs (config-literal checking, already correct), while the `|` gap is in calculation.rs binary(). Agents cluster in node.rs/config.rs, never calculation.rs.
- Shape-C LOC RISK (new): when the pass being extended already has reusable recursive machinery, Shape C collapses below the Mars 100 floor on the leanest passer (here 94 raw). Shape C on a machinery-backed pass needs a structural lever (a form the reuse can't reach, e.g. `|=` aug-assign) to hold the floor. Do not tier Shape C by your reference LOC.

## Shape note: make-consistent-across-every-path (Mars) -- open-policy is a thoroughness gate; close it for a misdirection wall (stoolap-comparison-consistency, APPROVED Mars 2026-07-07, 10%)

A "make behavior X consistent across every place the engine does X" feature (here: comparison/equality/ordering coercion) is intrinsically BREADTH: route N duplicated sites through one shared helper. On its own that is a PURE THOROUGHNESS gate (bimodal ~50%, un-lowerable by adding more sites -- see Pattern 72). It only becomes a real difficulty band when you (a) CLOSE any open policy to a rule the codebase's tempting helper gets WRONG (misdirection wall), and (b) cover the paths that DON'T route through the shared helper -- for a SQL engine that means EVERY join algorithm (hash / parallel-hash / MERGE / nested), which the planner selects by input size + sortedness (Pattern 73). The interdependent+misdirecting core is the join-hash bucketing (type-discriminated hash keeps coerced-equal values in separate buckets, so fixing the equality helper is INERT). Best agent: heavy thorough (Orion / the one Nova that changed all 4 files). Fast agents miss a join path and fail.

## Shape note: D-new = a WHOLE NEW LIBRARY MODULE is MARS-by-nature, and a from-scratch engine is a bimodal DEPTH-wall (scryer-clpq-linear, APPROVED Mars 2026-07-09, 30%)

Adding a whole new public module (`library(clpq)` — a from-scratch CLP(Q) solver) is Shape D-new. TWO tier/difficulty facts confirmed: (1) TIER — a single new library module is MARS regardless of how deep or large it is; the platform Task-Quality post-check reclassifies "single library module = too localized for Olympus." Olympus needs cross-SUBSYSTEM SPAN (multiple existing modules + downstream consumers, like zen's graph+policy+analyzer), not depth in one new module. Do NOT tier a from-scratch module by LOC — a 415-C2 clpq was still Mars. (2) DIFFICULTY — a from-scratch multi-behavior engine tested behavior-by-behavior in ISOLATION is a bimodal ~50% coin-flip (full impls pass, partial fail). Harden it into band by STACKING at composition seams (Pattern 75) — tests that force one determination to re-fire ALL consumers, so partial impls that pass each behavior alone break composed. Solution stays unchanged; the correct reference already composes. Best agent: full-completion runs (the passers were 500-850 LOC); fast partial runs die at the seams.

## Shape note — numbat-const-exponents (APPROVED Mars 2026-07-09) confirms Mars D-change/composite

- A cross-subsystem language-feature add (parser + typechecker const-eval + dimension registry + AST) that COMPRESSES to a surgical 354 eff = Mars, not Olympus (build-measure gate). Best agent Nova/Orion. Confirms: a multi-subsystem span alone does NOT lift tier — passing-LOC / build-measured size does. Difficulty came from interdependent TEST-DESIGN traps (negative-const type-gate, from_f64 exactness, parser factor-ambiguity, shadowing/rebind), not shape.

## Shape note: NEW-NODE-through-the-pipeline (D-new x O-Composite-add) is Mars-sized when the node is syntactic sugar (erg-chained-comparison, APPROVED Mars 2026-07-10, 30%)
A net-new AST/HIR node threaded through parser -> desugar -> typecheck -> codegen + transpiler LOOKS Olympus (15 files, 4 crates) but is Mars by C2 LOC because enum/node boilerplate amortizes to ~0 and there is one right architecture. Tier is set by the PASSING-agent C2 diff (343 here), not file count. The difficulty is NOT the node plumbing (agents do that) but the SEAMS the node interacts with: precedence boundary vs existing operators, paren-flag survival through desugar, shared-path (in->contains) regression, effect-system integration. Harden a syntactic-sugar-node pick by stacking seam-interaction tests, not by adding more node-variant breadth.

## Shape note: GREENFIELD static-analysis (O-Composite-add, dual-consumer) is a THOROUGHNESS-gate that ceilings HIGH until you engineer a wall (zen-table-verification, APPROVED Olympus 2026-07-10, 10%)

A net-new static-analysis feature threaded through a shared engine + two consumers (here: a cover-algebra engine in zen-expression driving both the graph `Decision::verify()` and the policy analyzer) is Shape O-Composite-add and comfortably Olympus by SPAN (cross-crate, dual-consumer, 468 C2). But SPAN/LOC does not make it HARD: because the agent builds the whole analyzer clean, every documented behavior is independent + self-revealing and thorough agents implement each one (2 batches at 90%). It never rides the trap-laden EXISTING machinery that carries difficulty in a modify-existing pick (contrast zen-hit-policies: no-Ord + Decimal + silent dual-path in the runtime). To bring a greenfield analyzer into band you must ENGINEER one machinery-riding wall (Pattern 77) -- rearchitect two of its checks to share a single domain-model chokepoint so the OBVIOUS separate-checks structure is subtly wrong. Dominant-agent profile: full-completion Nova runs (the passers wrote 800-1240 LOC); the wall is what separates the one passer from the rest, not thoroughness.

## Shape note — O-Composite planar-graph subdivision (go-geom-polygonize, APPROVED Olympus 30% 2026-07-13)

A geometric/graph subdivision task (JTS Polygonizer: node -> strip dangles -> trace faces -> assign holes) is a strong O-Composite Olympus shape. Difficulty knob = interdependent traps on a SHARED chokepoint (the half-edge `next` linkage): fixing face-merging, hole-assignment, cut-edge, and orientation all route through the same angular-linkage + ring-label state, so a local fix to one regresses another. Cross-subsystem requirement met by a cycle-safe second-package consumer (see Pattern 34a). 6 traps, 3 files/2 pkgs, 346 eff LOC, 46 tests.

## Shape note — manufactured solve->project->render pipeline lifts a structurally-single-file library to Olympus (scryer-clpq-linear, APPROVED Olympus 2026-07-16, 10%)

A NEW LIBRARY MODULE is single-file by nature (prior note: Mars-by-nature). The Olympus lift is NOT more depth/LOC in the module — it is splitting the module's OUTPUT data flow into genuine downstream consumers: solver store -> projection layer (dump/3, FM eliminate onto a target set) -> render layer (DCG text). Each layer has its own spec'd contract + tests use_module all three, so >=2 meaningful files holds by construction and the layers stay interdependent (shared residual representation). Works for any engine whose result is a structured artifact (constraint store, AST, IR): manufacture the consumer from the data flow. Cost: the render/serialization layer is a fairness magnet — pin format via worked examples, keep projection cases pivot-independent, no empty-input renders. O-Algorithm-correctness x pipeline hybrid; 3 files, 541 eff, 121 tests, 10%.

### O-Composite-add — confirmed on NOVA at 20% (rust-minidump-stack-containment, APPROVED 2026-08-06)

The shape table lists Vega as the best-fit agent for O-Composite-add at 15-20%. rust-minidump ran a
**Nova-only** batch (no Orion, no Vega) and landed **2/10 = 20%**, at the band the table predicts —
so the shape's rate is not Vega-specific. Effort was Vega-scale even on Nova: 9-26 files and
439-685 added LOC per run.

The variant that produced it: **three orthogonal axes over ONE existing control loop**, each with a
stated precedence against the others, spanning a parser crate, the loop, and two output surfaces —
without adding a subsystem to any of them. Difficulty came from the precedence interactions and from
scope ambiguity (which unit, which event, which provenance), not from API breadth. That keeps
effective LOC modest (327) while the file/crate count stays high enough for scope.

**Shape note for the next O-Composite-add:** Nova's failures were entirely semantic-scope, never
mechanical. Every token, enum-shape, boundary and multi-architecture test passed 10/10. Spend the
design budget on what a rule APPLIES TO, not on how much surface it covers.


## O-Composite-add confirmed — vrp-tsplib-edge-weight-types (APPROVED 2026-09-02, 3/10 Nova)

Second measured instance of O-Composite-add, and the first solved by **Nova rather than Vega**:
8 files, 374 effective LOC, 35 tests, 30% pass. The table above lists Vega as the best agent for
this shape on a 12-file / 366-LOC sample; this instance was Nova x10 with 3 solves and no Vega run,
so read the best-agent column as "Vega for the heavy multi-stage variant", not as a requirement.

**What this instance adds to the shape.** The "composite" half does not need to be a second
language stage — a CLI/export surface over the new capability counts, and it is where the entire
difficulty lived. The parser half (four edge-weight types, five matrix layouts, a display section)
killed nobody across 52 runs; the one cross-crate command wiring killed 36. When picking this
shape, put the trap on the SURFACE that spans crates, not on the depth of the new capability.

## O-Composite-add confirmed on a COMBINATOR DSL — datafixerupper-ordered-alternatives (APPROVED Olympus 2026-09-08, 5/10 Nova)

Third measured O-Composite-add, and the first in Java: a new composite codec added to an existing
combinator DSL (`Codec.orderedAlternatives` / `MapCodec.orderedAlternatives` + labeled twins), 5 files
and 270 effective LOC. Nova again, 10/10 of the batch, no Vega.

**The shape's own hazard, and it decided this problem.** A combinator DSL gives you two surfaces per
type -- decode and encode -- and they look symmetric in the description, so the natural design spends
its trap budget evenly. It should not. All ten runs implemented BOTH decode paths and the `Codec`
encode path correctly; every kill landed on the third surface, `MapCodec.encode`, because that is the
only one whose result is delivered through a caller-supplied mutable abstraction rather than returned
as a value. The band lived entirely in the surface that hands the answer to an object the codec does
not own.

**Shape note for the next O-Composite-add on a DSL:** find the surface where the result crosses an
ownership boundary and put the difficulty there. Value-returning surfaces of a combinator are
transcription work -- agents get them unanimously right, and tests over them (here 156 of 173) buy
fairness, not band. Expect ~50% if the boundary surface is the only trap; pair it with an orthogonal
lever to reach the low edge.

## O-Pipeline-hard — confirmed by customasm-derived-bank-layout (ACCEPTED 2026-09-09, 1/10)

New confirmation and one refinement. The strongest instance of this shape is NOT "add a new
subsystem that cascades"; it is **promote an existing quantity out of a single-pass pre-pass INTO
the repo's existing fixed-point loop**. The repo supplies the loop, the guess/stable state and the
diagnostics, so the author writes only the joining logic while every capability becomes
interdependent for free.

Band evidence: 13 files, 980 effective LOC, 68 fixtures, accepted at 1/10. Best agent Orion (1/2);
Nova 1/24. Lead pattern F-22.


## O-Pipeline-hard confirmed on a DERIVE-FROM-DECLARATIONS pick — datafixerupper-derived-recursion (APPROVED Olympus 2026-09-11, 1/10 Nova, twice)

**The sub-shape: take a property the caller currently DECLARES and require it to be derived.** Base
`Schema` made the caller pass a `recursive` boolean per registered type; the task derives recursion
from the reference graph between registered templates. This is a reliable Olympus-sized shape
because the derivation is a graph algorithm (real LOC: 389 effective over 6 files) while the
DIFFICULTY sits in three consequences you get without designing them:

| Consequence of deriving | Pattern | Measured |
|---|---|---|
| The pass must be total over a namespace with missing keys | F-24 | 8/10 in both batches |
| References cannot resolve at write time, so a placeholder escapes to callers | F-25 | 4/10 + 4/10 |
| The assembly path is rewritten and drops untested behaviour it carried | F-20 family | 3/10 |

**Band behaviour.** Two independent full batches four levers apart, both exactly 1/10 with the same
dominant cluster. A band carried by a SEMANTIC distinction reproduces; compare vrp-tsplib's
22%-vs-50% swing on a numeric/ordering band. **Pick this shape when you need a predictable band.**

**Cost warning.** Four Auto Review rounds and seven reference defects, four of them self-inflicted
by the previous round's fix. Deferred resolution has a long self-inflicted tail — see L51.


## O-Pipeline-hard confirmed on an IR NODE-FAMILY pick — ray-optics-formula-conditionals (APPROVED Olympus 2026-09-14, 1/10)

**The sub-shape: add a node family to an IR that several independent passes consume.** Here one
formula DAG feeds a parser, two evaluators, a JS generator, a WGSL generator, a symbolic derivative
and an interval range estimator. Batch 3's 40 kill events by consumer:

| Consumer | Kill events | Pattern |
|---|---|---|
| Interval range estimator | 24 | F-26 identical operands, F-27 `or` polarity, one soundness oracle |
| WGSL generator | 11 | F-10 valid node over a maybe-invalid operand |
| Symbolic derivative | 3 | F-23 family (subtraction-based equality overflows) |
| Parser | 2 | F-10 variadic-argument grammar cell |
| Evaluators, JS generator | 0 | — |

**Pick this shape only when the IR has a static-analysis consumer.** Without one the node family is
breadth: 7 files and 329 effective LOC, but the parser, evaluators and JS codegen killed 2 events
between them. **Cost warning:** the description hits the word cap fast, and a dense spec has no clean
pass under the FP check (L53).

## O-Composite-add confirmed on a SIMULATION-LAYER pick — worldengine-orographic-precipitation (APPROVED Olympus 2026-09-16, 2/10)

**The sub-shape: add a physical layer to a simulation pipeline whose world model is a keyed layer
container.** Batch 2's 46 kill events by subsystem:

| Subsystem | Kill events | Pattern |
|---|---|---|
| Serialisation round trips + equality | 25 | F-28 container key, F-16 accessor form |
| Precipitation stage / generation steps | 11 | F-16 accessor form, one missing accessor |
| Wind model API | 6 | F-29 guard, F-16 |
| CLI maps and info | 4 | F-16 |
| Moisture transport (24 tests) | 0 | — |
| Drawing | 0 | — |

**Pick it when the model has a composite value type** (here `LayerWithThresholds` /
`LayerWithQuantiles`). Without one the physics is breadth: it supplies the LOC and none of the band.

## O-Pipeline-hard confirmed on a TWIN-IMPLEMENTATION COMPILER pick — cwerg-bcopy-bzero-lowering (APPROVED Olympus 2026-09-16, 3/10)

**The sub-shape: a new IR instruction in a compiler written twice (Python spec + C++ port) under an
identical-output convention.** Batch 6's 32 kill events by pipeline:

| Pipeline | Kill events | Pattern |
|---|---|---|
| Native wrap program (py/cc/parity) + its C and optimizer paths | 16 | F-31 folders, F-32 at scale, one broken loop |
| Optimized C on the main program | 6 | F-30 width pass |
| Python/C++ assembly parity, main program | 4 | F-32 |
| Native py/cc execution | 6 | one run's source cursor |
| Plain C output | 0 | — |

**Pick it when the repo already runs every program through several pipelines** (here plain and
optimized C, three targets, text and binary). The feature is the same everywhere; the difficulty is
in the pipelines. Budget the parity promise's review cost (L60).

## O-Composite-extend confirmed on a SOLVER-FAMILY ACCOUNTING pick — sfepy-adaptive-stepping-accounting (APPROVED Olympus 2026-09-16, 2/15)

One accounting contract threaded through every existing solver path (first-order simple and adaptive,
five elastodynamics solvers) and the controllers they call. The shape held its band only after scope was
cut twice: each extra lane (restart files, a matrix cache) added a wall in base code, not in the
feature. The band lived in the stop and retry path all solvers share (F-34, F-10 hook cell, F-35), not in
per-solver breadth: 87 of 117 tests killed nobody. Budget per-solver tests as FP insurance and put the
traps where the solvers converge.

## O-Composite-extend confirmed on a TWIN-IMPLEMENTATION pick — mwparserfromhell-site-aware-parsing (APPROVED Olympus 2026-09-18, 2/19)

A parsing profile threaded through a Python tokenizer and its C-extension twin under an identical-trees
contract. The second arm did not double the difficulty: both passers forwarded C to Python when a site was
given, and the FP panel accepted it (L67). The band lived in the SHARED scanning logic and the C reader's
sentinel (F-36, F-37) and in a two-path property cell (F-10), not in reimplementing the feature twice.
Budget a twin shape as one arm plus a forwarding stub, and check the LOC floor against that passer.

## O-Composite-add on a two-path playback feature — kira-loop-crossfade (APPROVED Olympus 2026-09-18, 3/10, fair 9/10)

A feature added to both a synchronous path (static sound, pre-resampler) and an asynchronous one
(streaming, decoder thread) with a shared transport rule reads EASY when every rule is local and stated:
Nova implemented both paths in 10 of 10 runs. The asynchronous path adds test-harness risk (queue depth,
thread scheduling), not agent difficulty. Only the composition cell (live update x shortened wrap)
killed. For this shape, design the trap matrix on cross-path and live-update cells, not on per-path rules.

## O-Composite-add on a layered-config composition feature — planetiler-custommap-schema-composition (APPROVED Olympus 2026-09-18, 3/10)

Config inheritance (a file extends others, merged per field) reads EASY rule by rule: every stated merge
rule was implemented by 10 of 10 runs. Difficulty lives in two places only: provenance (what counts as
inherited when one input both adds and removes, F-38) and origin (a second consumer re-resolving a
reference that came from a bundled resource, F-9). For this shape, state the merge rules briefly, spend
the trap design on provenance and origin cells, and name every new static API's full signature.

## O-Algorithm-correctness on a stated allocation algorithm — featurevisor-minimal-rebucketing (APPROVED Olympus 2026-09-19, 2/11)

When the contract states the algorithm step by step (retain lowest-first, refill in declared order,
sort and merge), the algorithm itself is transcribed: 0 of 11 failed any kernel cell. For this shape,
state the rules plainly and find the difficulty outside the prose: a repo helper the new regime drives
into its lossy path (F-39) and host-language edges in the reported structures (F-40).


## O-Composite-add as a declarative config section in a simulator — ir-sim-scenario-events (APPROVED Olympus 2026-09-19, 1/11)

Confirms O-Composite-add outside compilers: a new top-level YAML section whose semantics run inside the
existing step loop (conditions, actions, timing, undo on reset). Profile: one new module (~300 eff)
plus lifecycle wiring (~60 eff), ~90 tests, a ~490-word description that pins every semantic. The
lifecycle wiring the prompt names is transcribed; the band sits in an integration default the loader
supplies implicitly (F-41).

## Shape note — csbindgen-struct-layout-fidelity (APPROVED 2026-09-21)

O-Algorithm-correctness confirmed for a **two-model comparison** feature: the output is chosen by
comparing a source-language model against a target-runtime model. Kills come from composing the model's
rewrite rules (F-44) and from reusing one model for the other side (F-46), not from the individual layout
rules, which 63/70 cells show agents transcribe. Pass rate 1/10 on Nova.

## Shape note — libspatialindex-tpr-temporal-knn (APPROVED 2026-09-21)

O-Algorithm-correctness with a **derivable core** confirmed as too easy on its own: three stated
interval-geometry kernels read 7/10. What made it land was an integration layer the core forced through
the repo's storage (per-entry lifetime through node pages, node bounds and reload; F-47). For a maths
pick, budget the band on state the repo discards, not on the maths. Accepted at 5/12.

## Shape note — siliconcompiler-flist-roundtrip (APPROVED 2026-09-23)

O-Composite-extend, confirmed on a serialisation round trip rather than a schema merge.

The shape's usual reading is "extend an existing aggregation across packages". This instance shows the
productive variant: extend an aggregation that is **lossy by construction** (a walk that flattens a
graph into an ordered command list) so that what the flattening destroys survives a write/read pair.
That framing gives the writer and the reader as two independent surfaces over one structure, and the
band lives in the structure, not in either surface.

Warning carried from HARDENING § 0 and confirmed here: a write/read pair is a closed loop and the
reader is an oracle for the writer, so any self-consistent encoding satisfies a pure round-trip suite.
Half this suite reads hand-written lists the writer never produced, and the exact-emitted-text writer
tests pin the other half. Pass rate 2/10.

## Shape note — pyfakefs-block-inode-accounting (APPROVED 2026-09-23)

O-Composite-add, confirmed on an accounting model: new accounting axes (whole blocks, inodes,
reserves) laid over an existing byte-only model, reported through new surfaces (`statvfs` on two
modules, `mount_usages()`, `tree_usage()`).

The productive variant: the band lives where a new axis meets a surface the old model never had to
reconcile, namely an unlimited mode that must report a finite figure (F-50), a size getter that
presents something other than what is stored (F-51), and repo helpers already routed through the
primitive the new rule changes (F-20). The stated per-operation rules were transcribed. Pass rate 5/10.

## Shape note — pyocd-sequence-expression-kernel (APPROVED 2026-09-24)

O-Pipeline-hard, confirmed on an expression engine: one semantic model (unsigned 64-bit values,
operand order, effect preservation) that several existing consumers of one operator table must agree
on: a parse-time constant folder, the interpreter, the semantic checker, control predicates and a
pluggable delegate.

The productive variant: the band lives where two consumers or two layers each hold part of one rule.
Folder vs interpreter (F-31) and delegate seam vs the operation below it (F-52) decided every near-miss.
The stated per-operator rules were transcribed. Pass rate 5/10.

## Shape note — teavm-method-summaries (APPROVED 2026-09-24)

O-Pipeline-hard with an O-Algorithm-correctness core: a new whole-program analysis whose facts are
consumed by several existing per-method passes. The consumer wiring is transcribed (every run touched
the same nine files). The band comes from the analysis's fixed-point direction (F-53) and from how the
new facts enter the old passes: the frozen off path (F-54) and the deferred join path (F-55). Pass
rate 4/10.
