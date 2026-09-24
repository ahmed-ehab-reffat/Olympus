# DESIGN.md - teavm-method-summaries

Repo: konsoletyper/teavm (Java 17 language level, Gradle 9.7.1, Apache-2.0, 3115 stars).
Base: fd78e03fca45fc76d5454f2940a3b200b221959f (master HEAD, 2026-09-15). Hunt log: REPO-HUNT-2026-09-23-C.

## Phase 1 - Repo understanding

**Architecture (one paragraph).** TeaVM is an AOT compiler from JVM bytecode to JS / Wasm GC / C. The
`parsing` frontend turns class files into TeaVM's SSA IR (`org.teavm.model`: `Program`, `BasicBlock`,
`Instruction` subclasses, `Variable`). `dependency` runs a points-to style reachability analysis over the
whole program (`DependencyAnalyzer`, `DependencyInfo`). `vm/TeaVM.build` then, in the eager pipeline used
by the ADVANCED and FULL optimization levels, links the reachable classes into a fresh
`MutableClassHolderSource` (`link`, `Linker` prunes unused methods), devirtualizes, runs
`ClassInitializerAnalysis` + inserts/eliminates `initClass` instructions, inlines, and then optimizes
every method ALONE (`optimizeMethod` -> `optimizeMethodCacheMiss` loops the `MethodOptimization` list to a
fixed point on a copy of the program, then stores it in the `ProgramCache` with the classes the optimized
program names as dependencies). Backends (`backend/javascript`, `backend/wasm`, `backend/c`) decompile to
an AST (`org.teavm.ast`) and emit.

**Five subsystems + boundaries.**
1. `parsing` - bytecode to IR (plus `dependency/DependencyClassSource` which applies `ClassInitInsertion`).
2. `dependency` - reachability / points-to (`DependencyInfo`, `MethodDependencyInfo`, `Linker`).
3. `model/analysis` - IR analyses: `NullnessInformation(Builder)`, `AliasAnalysis`, `ClassInference`,
   `ClassInitializerAnalysis`, `EscapeAnalysis`.
4. `model/optimization` - per-method passes behind `MethodOptimization` / `MethodOptimizationContext`
   (`RepeatedFieldReadElimination`, `RedundantNullCheckElimination`, `ConstantConditionElimination`,
   `LoopInvariantMotion`, `GlobalValueNumbering`, `Inlining`, `Devirtualization`, ...).
5. `vm` + `cache` - the pipeline driver (`TeaVM`) and the per-method program cache
   (`ProgramCache`, `ProgramDependencyExtractor`, `CacheStatus`).

**Three high-entanglement zones.**
1. `TeaVM.eagerPipeline` / `optimizeMethod` / `MethodOptimizationContextImpl` - every pass, the cache.
2. `NullnessInformation.build(program, descriptor)` - called by `RedundantNullCheckElimination`,
   `ConstantConditionElimination`, `LoopInvariantMotion` (+ the unused `LoopInversionImpl`) and the test.
3. Class initialization - `ClassInitInsertion` (explicit `initClass` before cross-class static access),
   `ClassInitializerInsertionTransformer` (`initClass` at entry of static methods / constructors),
   `ClassInitializerAnalysis`, `ClassInitElimination`, backend clinit rendering.

**Test framework.** JUnit 4 in `core/src/test/java`, run by `:core:test` (213 tests, 0 failures,
identical 3x per hunt log). Programs are written in TeaVM's listing language and parsed by
`ListingParser`. Formatting template: `core/src/test/java/org/teavm/model/optimization/test/
RepeatedFieldReadEliminationTest.java` (builds a `MutableClassHolderSource` of `ClassHolder`s and an
anonymous `MethodOptimizationContext`, compares `ListingBuilder` output).

## Phase 2 - Existing-PR / publicly-solved check (all run 2026-09-23, canonical org konsoletyper/teavm)

- PRs, all states, by feature class: interprocedural, nullness, null check, non-null, never returns null,
  side effect(s), method summary, summaries, purity, pure method, RepeatedFieldReadElimination, field read,
  redundant null, NullnessInformation, class initializer, clinit, initclass, escape analysis, optimizer,
  optimization, program cache, invalidate, MethodSummaries, neverReturnsNull, getWrittenFields,
  ConstantConditionElimination, NoSideEffects. **No PR touches model/optimization, model/analysis or the
  capability** (hits are classlib / wasm-gc / JSO / reflection).
- Issues, same classes: no request, no decline. Nearest: #796 "Improve inliner" (maintainer, inliner
  heuristics), #809 "Add JSO-specific optimizations" (plugin-contributed passes), #1250 (maintainer "not
  interested in PRs" in general; unrelated to the capability), #1248 ScalarReplacement crash.
- Side branches: `points-to` (2026-01, new PTA prototype under `org.teavm.pta`, no summaries),
  `new-ir` (2021 WIP), `dependency-perf` (2025) - no overlap.
- Post-base: base IS master HEAD; no base..HEAD commits.
- Lane heat: `RepeatedFieldReadElimination.java` last touched 2020, `NullnessInformationBuilder.java` 2019,
  `MethodOptimizationContext.java` 2023. `ClassInitializerAnalysis` 2025-10 (recursion fix dcf99225f, which
  made every analyzed initializer dynamic - a maintainer example of how recursion handling in an effect
  analysis goes wrong).
- Sibling-ecosystem risk (recorded, MEDIUM, precheck is the judge): R8 `MethodOptimizationInfo`
  (neverReturnsNull, side effects), GWT `TypeTightener` (non-null return tightening), Soot/Tai-e side-effect
  analyses. None has TeaVM's IR, `initClass` channel, `NullnessInformation` proof, per-field RFRE cache or
  linked-class-set dispatch in liftable form. Phrase meta.md on TeaVM's model only.

## Phase 3 - Candidates (lane fixed by the hunt; variants scored)

| Candidate | One-line behavior | Shape | Files | Raw | Meaningful | Pred. | Verdict |
|---|---|---|---|---|---|---|---|
| A. Summaries: never-null + write sets, both consumers, class-init channel (CHOSEN) | whole-program facts fed to nullness + RFRE | O-Pipeline-hard | 1 new + 7 mod | ~390 | ~260 | 20-35% | globally coupled |
| B. Never-null only | nullness consumers only | O-Composite-add | 1+5 | ~200 | ~130 | 50% | under floor, one trap |
| C. Write sets only + RFRE | RFRE only | O-Composite-add | 1+3 | ~220 | ~150 | 45% | under floor |
| D. Fix RFRE across `initClass` alone | bug fix | bug | 1 | ~20 | ~15 | - | trivial |
| E. Loop inversion | enable `LoopInversionImpl` | - | - | - | - | - | magnet (#25) + existing impl |

Step A (TOO-EASY guard) on A: not membership/validation; not a single-subsystem transform (vm + analysis +
optimization + cache); hardness does not depend on hiding (recursion, dispatch, unknown, class-init rules
are all stated); not a port (TeaVM model); survives full spec (integration walls: two RFRE paths,
per-site nullness wiring, the proof reused inside the fixpoint, `initClass` channel).
Pointwise-decoupled? No - a local fact depends on the whole call graph's fixed point.
Absorption check: `GraphUtils` offers SCCs, `NullnessInformation` offers the per-method proof,
`RepeatedFieldReadElimination.invalidateFieldOnAllInstances` exists; the fixpoint kernel, dispatch
resolution, unknown handling, class-init channel and the RFRE frontier path are NEW code (sketched below
against real files, not surface counts).

Step B arsenal: lead S4 (machinery-riding: facts must survive recursion, dispatch, initializers, unknown
bodies) + S5 (dual-path: RFRE straight-line path and dominance-frontier path) + S2 (composition of dispatch
x recursion x unknown).

## 1. Title
Add whole-program method summaries to the TeaVM optimizer

## 2. Shape classification
- Shape: O-Pipeline-hard (new analysis kernel + consumers across 3 packages + pipeline wiring).
- Pass-rate target: 15-35% (ceiling 40%).
- Best agent: Orion (long-horizon), Nova thorough runs.
- Dominant verdict: MISSED_REQUIREMENT (one cell of dispatch/recursion/class-init) + REGRESSION (unsound
  RFRE elimination).

## 3. Public API surface (tests assert exactly these)
- `org.teavm.model.analysis.MethodSummaries` - new class.
- `static MethodSummaries build(ListableClassReaderSource classes)` - analyze every method body in the set.
- `boolean neverReturnsNull(InvocationType type, MethodReference method)` - call fact.
- `Set<FieldReference> getWrittenFields(InvocationType type, MethodReference method)` - call fact, `null` =
  may write any field.
- `Set<FieldReference> getInitializerWrittenFields(String className)` - what `initClass className` may
  write, `null` = anything.
- `NullnessInformation.build(Program, MethodDescriptor, MethodSummaries)` - new overload; the 2-arg form is
  unchanged.
- `MethodOptimizationContext.getMethodSummaries()` - new DEFAULT method returning `null`.
- (FINISH) `Set<String> getDependencies(MethodReference method)` for the program cache - see section 15.

## 4. Canonical output form
- Written-field sets: `FieldReference` exactly as the storing instruction names it; set semantics (order
  irrelevant, tests compare as `Set`); `null` = unknown.
- `neverReturnsNull` for a method that never returns normally: true. For unknown targets: false.
- RFRE listings: ListingBuilder text, compared to the expected listing (repo convention).

## 5. Blind-spot pre-empts
- rule-resolution: "a `VIRTUAL` call can run, for the called class and every non-abstract class in the set
  that is a subtype of it, the implementation an instance of that class would run".
- iteration-termination: "facts are the most precise ones that hold for all methods at once, so recursion
  and mutual recursion lose nothing by themselves" (no iteration-count promise, L44/L45).
- parallel-API: "the two-argument form stays as it is"; "with `null` summaries every pass behaves exactly as
  today".

## 6. Description draft
See `meta.md` (kept in sync; ~430 words at slice time).

## 7. File footprint (sketched against real files)
| Action | Path | Raw | Meaningful | Reason |
|---|---|---|---|---|
| NEW | core/.../model/analysis/MethodSummaries.java | ~230 | ~165 | kernel: nodes, targets, worklist fixpoint, facts |
| MOD | core/.../model/analysis/NullnessInformation.java | +6 | 4 | overload |
| MOD | core/.../model/analysis/NullnessInformationBuilder.java | +20 | 14 | summaries field, invoke result init |
| MOD | core/.../model/optimization/MethodOptimizationContext.java | +4 | 3 | default method |
| MOD | core/.../model/optimization/RepeatedFieldReadElimination.java | +50 | 35 | call/initClass effects, both paths, all-instance marker |
| MOD | core/.../model/optimization/RedundantNullCheckElimination.java | +2 | 1 | pass summaries |
| MOD | core/.../model/optimization/ConstantConditionElimination.java | +2 | 1 | pass summaries |
| MOD | core/.../model/optimization/LoopInvariantMotion.java | +2 | 1 | pass summaries |
| MOD | core/.../vm/TeaVM.java | +14 | 10 | build after inlining, expose via context |
TOTAL (slice): ~330 raw / ~235 meaningful across 9 files, 2 packages + vm. FINISH adds the cache
dependency surface (~40 meaningful) and `@NoSideEffects` (~10), target >= 280.

## 8. Solution outline
- `targets(type, method)` <- dispatch rule (SPECIAL resolve up the chain; VIRTUAL per concrete subtype via
  `resolveImplementation`); `UNKNOWN` when a target has no program or cannot be resolved.
- `computeNeverNull(m)` <- copy program, `NullnessInformation.build(copy, desc, this)`, every exit value
  `isNotNull`.
- `computeWrites(m)` <- puts + call writes + `initClass` initializer writes; `null` absorbs.
- worklist fixpoint: never-null starts TRUE for reference-returning bodies and only falls; writes start EMPTY
  and only grow; a changed fact requeues its callers (reverse edges include `initClass` users of a clinit).
- RFRE `InstructionAnalyzer`: `invalidatedFields` set for known calls / initializers; enterBlock and
  insertInvalidationPoints both invalidate those fields on every cached instance (marker key).

## 9. Test file outline
`core/src/test/java/org/teavm/model/analysis/test/MethodSummariesb8a94bTest.java` (hex suffix). Blocks:
imports -> fixture builders (`cls`, `method`, `staticMethod`, `nativeMethod`, `field`, `listing`) ->
assertions (`fields(...)` set builder, `optimizeWith(pass, method)`) -> tests grouped: kernel facts,
recursion, dispatch, unknown, class-init, RFRE consumer, nullness consumers.

## 10. Forced shapes
`MethodOptimizationContext.getMethodSummaries()` MUST be a default method: the repo's own
`RepeatedFieldReadEliminationTest` and `ScalarReplacementTest` implement the interface anonymously and run
in base mode (F-12 guard). `getWrittenFields` returns a `Set` (tests copy into `HashSet` - representation
tolerant, L48).

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Early finalization in a recursive cycle (DFS memo keeps a member's fact before the cycle settles) and conservative cycle breaking | F-22 (candidate), F-2 | S4 | fixpoint scheduling | 3, 6 | DFS + "in progress" marker is the natural recursion guard (ClassInitializerAnalysis does it) | "facts are the most precise ones that hold for all methods at once" | mirrored mutual-recursion pairs (null / write reaching one member) |
| 2 | Dispatch target set: static target only; declarations only; missing inherited implementation through an interface | F-3 | A3 | target set | 1, 3 | the static target is right for SPECIAL; interface impl inherited from a non-implementing superclass | the VIRTUAL sentence | interface call via inherited impl; override returning null / writing |
| 3 | Unknown body treated as "nothing" (native, missing) and not propagated through callers / cycles | F-24 | A-tier | absent target | 1, 2 | sentinel "empty summary" keeps the pass total | "is unknown ... and so may everything that calls it" | native callee in a cycle; missing class |
| 4 | Class-init channel: `initClass` inside a callee, and RFRE's own `initClass` | F-9 origin | S4 | effect channel | 5 | InstructionAnalyzer only looks at puts/invokes; base RFRE ignores `initClass` (real base bug, Gate 1) | initClass sentence | nested initializer writes; RFRE across `initClass` |
| 5 | RFRE frontier path + all-instance invalidation | F-9 / S5 | S5 | consumer path | 4 | `invalidateField(-1, f)` only hits static cache; frontier path keyed per instance | "forgets only the fields that call may write" | call in one branch writing an instance field, read after the join |
| 6 | Never-null proof by NullnessInformation (sigma-refined return, phi of non-null values) vs a syntactic check | F-17 (candidate) | A5 | per-method proof | 1 | a hand-written "return of new" check is easier | "when NullnessInformation, told these summaries, proves..." | `if x == null return "d" else return x`; phi(new, never-null call) |
| 7 | Nullness consumer wiring at every `NullnessInformation.build` site | F-9 multi-site | S3 | wiring | 6 | three call sites, one natural to miss (CCE) | consumer sentence | RNCE nullCheck removal + CCE null-branch fold |
| 8 | Old API preserved (2-arg build, default context method, null summaries = base behaviour) | F-20 / F-12 | S3 | baseline | - | abstract interface method breaks the repo's anonymous contexts | "default", "stays as it is" | base mode runs the repo's RFRE / ScalarReplacement / nullness tests |

## 11b. Capability cross-product (F-10)
Axes: call kind {SPECIAL, VIRTUAL, initClass} x fact {never-null, writes} x callee state {plain, recursive
cycle, unknown}.

| | plain | recursive cycle | unknown |
|---|---|---|---|
| SPECIAL x never-null | slice | slice (mirrored) | slice |
| SPECIAL x writes | slice | slice (mirrored) | slice |
| VIRTUAL x never-null | slice | FINISH (override in a cycle) | FINISH (native override) |
| VIRTUAL x writes | slice | FINISH | FINISH |
| initClass x writes | slice | FINISH (clinit <-> helper cycle) | slice (class missing) |
| initClass x never-null | n/a (no value) | n/a | n/a |
Consumer axis: {RFRE straight-line, RFRE frontier, RNCE, CCE} x {known write set, unknown}.

Scope audit: written-field sets are per call (union over targets), never per object. Format-noun audit: "the
set" = the linked class set passed to `build`. Tolerance-fixture audit: n/a. Example audit: no examples in
meta.

## 12. Tier + category
Olympus; feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. The kernel alone is textbook (agents know fixpoints), so the band rests on the cells where the
textbook answer meets TeaVM's model: dispatch through inherited implementations, unknown propagation, the
class-init channel, the RFRE frontier path, and the proof reused inside the fixpoint. Smoke batch is the
oracle (optimization-quality capability, hot/cold inversion caveat).

## 14. Quality-gate checklist
- [x] Repo understanding 5/5
- [x] Existing PR check (section Phase 2)
- [x] Closest approved: calyx-unused-port-elimination (whole-program dataflow fixpoint), datafixerupper-
      derived-recursion (Java, SCC over a reference graph)
- [x] Title verb-led
- [x] Public API listed
- [x] Canonical form
- [x] File footprint against real files
- [x] Traps with F-ids, different axes, interdependent (1<->3<->6, 4<->5)
- [x] 11b matrix
- [ ] Stage-placement audit (L57): "after inlining" must not imply existing stages move - checked: sentence
      only adds a step.
- [x] Float audit: n/a
- [x] Sibling-API audit (F-20): 2-arg `NullnessInformation.build` and `null` summaries unchanged; base mode
      runs the repo's own nullness / RFRE / scalar tests.
- [x] Absent-key audit (F-24): unknown targets stated.
- [x] Host-semantics audit (L80): the dispatch rule is stated over the class set, not JVM semantics in full.
- [x] Enumeration audit (L81): "native, or a class or method the set does not contain" - complete for what
      tests use (native + missing).

## 15. Deferred to FINISH (differentiating scope, NOT in the slice)
- Program-cache dependencies: `getDependencies(method)` = classes whose bodies the facts used by `method`'s
  calls rest on (transitively, incl. overrides and initializers the method never names); `TeaVM.optimizeMethod`
  adds them to the stored dependencies (F-47-style discarded state).
- `@NoSideEffects` (method or its class) on a body-less method: writes nothing (repo's own annotation,
  read by `ClassInitializerAnalysis` both ways - F-3 second axis).
- F-10 cells marked FINISH above; mirrored recursion for VIRTUAL; clinit <-> helper cycles; RFRE frontier
  with unknown call in one branch; `LoopInvariantMotion` cell.
- Mutation / FP battery, Rule-7 audit of the final meta.

## Why this is not a duplicate
Closest approved: calyx-unused-port-elimination (Rust HDL compiler, a dataflow pass whose output is
pruned ports) and datafixerupper-derived-recursion (Java, SCC grouping of a reference graph). Different
repo, different product (analysis facts consumed by two existing optimizer passes), different trap
channels (dispatch, class-init, RFRE frontier). No teavm entry anywhere in approved-problems, problems,
rejected, SATURATED-REPOS or TOO-EASY.

Predicted iteration cycles: 2-3.

## Phase 5 - Failure-mode self-audit
- Bucket 1 hidden requirements: every test cell maps to a meta sentence (dispatch, unknown, initClass,
  recursion, consumers). The all-instance invalidation is a consequence of "forgets the fields".
- Bucket 2 tone: plain prose, no headers.
- Bucket 3 base-passers: every new test calls the new API (compile failure on base) - no base-passer.
- Bucket 4 over-constraint: sets compared as sets; listings are the repo's own convention.
- Bucket 5 LOC: slice ~235 meaningful; FINISH scope adds real surface (cache dependencies), not padding.
