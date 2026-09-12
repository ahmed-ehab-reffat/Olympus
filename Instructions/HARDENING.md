# HARDENING — Fair-Difficulty Doctrine for the Steroids Era (2026-07)

Synthesized from a full forensic sweep of every in-flight + recently-decided problem (30+ eval batches, 200+ agent runs) plus TOO-EASY.md, rejected/, KNOWLEDGE.md, PROBLEM-PROFILES.md. Every claim below carries a measured kill count. This file is THE playbook for making agents trip FAIRLY now that Nova ≈ Castor and enumerated specs are transcribed first-draft-correct.

> Companion files: `PICK-FILTER.md` (pick-time gates), `TESTS.md` (test mechanics + FP check), `DESCRIPTION.md` (WHAT-not-HOW), `KNOWLEDGE.md` (calibration protocol + agent profiles), `TOO-EASY.md` (dead-class case studies). This file is the difficulty DESIGN layer that sits on top of all of them.

---

## 0. The measured steroid deltas (why the old playbook eroded)

| Capability delta | Evidence |
|---|---|
| **Documented spec = transcription.** Enumerated wall sentences are executed as a checklist. | fundsp R3: 4 enumerated walls → 9/10 implemented ALL four ("the R3 wall sentences were a CHECKLIST"). gluon: 7/10 = 70%, evaluator wrote the semantics "was stated unusually explicitly." zen wall-3 flatten: 8/10 kills → 0 the batch after one fairness sentence named it. |
| **Architecture-jumps defeat whole trap families at once.** | scryer: 9/10 independently adopted text-parse of `number_chars` output → the ENTIRE float-arithmetic trap web (misround sets, carry, tiny-float) became immune in one move. |
| **Capability walls fall when the meta hands a worked example.** | scryer R5: exact bignum decimal expansion — 8/10 implemented exact rational arithmetic once the meta's `~20e` example named the target. |
| **Thoroughness spikes clear every ISOLATED documented behavior.** | nickel-optional: same 27-test suite, 30% → 60% batch-over-batch purely from agents running 174-251 msgs and probing each behavior in isolation. |
| **Machinery reuse lands under the LOC floor.** | kcl: the passer reused the resolver's context-switching machinery, ~94 LOC, forced a scope lever just to clear the floor. |
| **Single-insight co-solves discharge multiple designed walls.** | gms smoke: opus-A's one insight ("peel view body to Filter over base cols") solved mapping AND check-option together, 30/31 hidden. |
| **Saturated features pass uniformly.** | starlark set-literals 13/13 all 46 behavioral tests; symengine smoke 3/3 zero struggle; tengo crypto primitives 95%+ correct ("crypto is NOT hard for LLMs"). |
| **Agents mirror in-repo oracles for free.** | gimli: 3 straight batches 47-100% because the reader is an oracle for the writer; go-geom batch 2: 9/10 byte-identical to reference, even protecting Point occupants the author's own reference missed. |
| **AGENT-MIX law.** | gms: all-Orion batch 80%, the same artifact 20% on Nova+Orion, 10% on all-Nova. Read difficulty ONLY off the standard Nova-heavy mix. Orion is the decisive long-horizon solver (the lone passer on stoolap/participle/zen-hit/clpq was Orion each time); fast Nova ships plausible-but-incomplete ("speed correlated with failure"). |
| **Orthogonal blind spots per agent.** | tengo: Nova dies on Go embedding `Equals()` receiver mismatch (9/10) but Castor gets it 9/10; Castor dies on self-inflicted go.mod bumps (40%) that Nova never attempts. |

**Net:** any difficulty that lives in KNOWING (semantics, spec, algorithm, primitive) is gone. Surviving difficulty lives in DOING (wiring, composition, preservation, integration) — the things that stay hard even after the contract is fully, fairly stated.

---

## 1. The Fair-Hardening Axiom: CONTRACT-STATED / FIX-HIDDEN

Fairness gates (Test Fairness, Description Quality, FP check) force every tested behavior into the description. Steroid agents transcribe descriptions. Therefore:

**A trap is viable if and only if fairly stating its CONTRACT does not reveal its FIX.**

- **Dead by construction:** traps where the contract IS the fix ("must stay correct on a StableGraph after removals" → directs the agent straight to the panics). This is why membership/validation, mechanical transforms, and misdirection-only picks died — fairness and difficulty pull opposite ways on them (confirmed 3x: petgraph, kysely, ironcalc).
- **Alive by construction:** traps where the fix is a DISCOVERY orthogonal to the stated requirement:
  - framework/repo internals (participle: the meta fully states no-leak; the fix — snapshot the shared parent — is a framework-internals discovery),
  - a COMPOSITION of individually-documented rules (go-geom: collinear-allowed × containment-preserved),
  - baseline preservation through a shared chokepoint (zen: filter rebuild strips Nullable),
  - cross-module wiring (scryer: `pio:` meta-predicate module context).
- **FP-safe by construction:** every trap's contract is documented (description → test mapping holds), and every documented requirement has a discriminator (test → description holds). Composition traps stay fair because each COMPONENT rule is documented; what's untested-able is only the Cartesian product, and agents are graded on deriving consequences — the platform's own fairness evaluators rated all 52 zen tests fair while the compositions killed 6+.

**Corollary — the difficulty knob is COMPOSITION DEPTH and INTEGRATION SURFACE, not trap count, not test count, not LOC.** Test-count padding RAISES pass rate (findmyway 41→84 tests = 50%→80%; piccolo +9 tests = avg 0.66→0.81; scryer R6 +17 value-cases cost agents nothing and the batch got FASTER).

---

## 2. THE ARSENAL — survival-ranked trap classes (build from the top)

Ranked by measured kill-rate against the current agent cohort. Every entry: mechanism → why it misdirects → evidence → how to build. (S/A/B = oracle-proven; **P-tier = proposed, untested — validate on first use and promote/demote.**)

### S-tier (dominant killers, survive documentation + repeated batches)

**S1. Speculative-state isolation** — the framework's branch/backtrack primitive isolates SOME state (cursor, deferred lists) but not the shared destination object; a rejected alternative leaks a mutation into the winner. Misdirects as a wrong field on a correct-looking struct, no error. Evidence: participle-longest-match — 11/11, then 9/10, then 6/10 across three batches; the sole dominant biter every time. Build: find a branch primitive whose isolation is partial; force a greedy attempt that mutates the shared object before a partway failure; state the no-leak requirement fully (the fix is framework-internals discovery). Prove the idiomatic impl leaks BEFORE authoring.

**S2. Composition of documented rules (rule-interaction seam)** — each rule is stated and individually implemented; their INTERACTION is not derivable without real reasoning. Evidence: go-geom batch 3 — the only 2 fair fails were collinear-allowed × containment-preserved (strict location-equality wrongly rejects a legal collapse); zen r6 — arithmetic-as-bound-transform × {emptiness, cap, enumerability, brackets, membership} held the band while all 52 tests rated fair; nickel-optional round 4 — nested/forall-tail/open-row compositions after isolated probes died at 60%. Build: take 2-3 documented absolutes and construct the case where honoring one NAIVELY violates another; there must be exactly ONE correct composition and ≥2 tempting wrong exits, each failing a DIFFERENT existing test (go-geom R4: three wrong exits, each caught by a different suite). Zero new meta sentences needed — that is the point.

**S3. Baseline preservation through a shared chokepoint** — the natural implementation refactors or reroutes shared machinery and breaks an EXISTING behavior; the failing test is a base test, misdirecting entirely away from the feature. Evidence: zen — filter-rebuild strips Nullable (2 kills), includes()-rewrite breaks `)100..200(`; gms — over-broad `*SubqueryAlias` view-detection breaks DELETE-JOIN (3 runs, twice); scryer — the REAL FP: rerouting existing `write_csv` through the new path emptied output (planted `cd_write_rt` then killed a run with it); gimli — the shared DIE-writer generalization: 14/20 + 13/20 compile-fail. Build: route the new feature through machinery that existing behaviors also use; ensure base mode runs the integration tests that exercise the SHARED path (not just `--lib`). If the solution reroutes an existing exported API, add a public-output test of the OLD API (REWIRE-THE-EXISTING-API law).

**S4. Machinery-riding integration** — correctness must survive every operation the ENGINE already supports; the instance list is derivable from one general principle but agents don't expand general→instances. Evidence: fundsp R4 — push-order stale-edge (all natural tests build producer-first; a 0..n stepper passed all 47 prior tests), crossfade-inside-loop, remove×commit×index-shift; zen — arithmetic results flowing through closures/reducers/flatten. Build: enumerate the engine's operation set yourself (edit, combine, migrate, fade, commit, remove, reorder); write ONE meta sentence ("X are ordinary members of the connection model; everything the engine already does keeps working"); test each interaction. Misdirection is free — failures read as wrong values/delays/panics, never "your stepper uses insertion order."

**S5. Dual-path consistency + closed-policy misdirection** — the obvious fix site is INERT because an optimized path (hash join, merge, index) has its own helpers; and the repo's own tempting helper implements the WRONG policy. Evidence: stoolap — coerced-equal keys in different hash buckets, 7/10 and 8/12 across batches; the repo's own `Value::compare` string-coerces and every passer reused it. Build: "make X consistent across every path" where ≥2 paths have separate helpers; CLOSE the policy (open policy = thoroughness gate stuck ~50%) to a rule the tempting in-repo helper gets wrong.

**S6. Two-evaluators / analyzer-missed** — one enum consumed by a compiler-FORCED path (exhaustive match — the compiler makes agents handle it) and a SILENT path (`==` comparison, a static analyzer) nothing points at. Evidence: zen-hit-policies dominant across 11 fails; zen-table-verification — the SOLE killer across 19 runs. Build: pick an engine with a runtime evaluator + a static analyzer/type-provider sharing one domain model; require the new dimension in both; the analyzer is the wall.

### A-tier (reliable 30-70% single-wall killers — stack 2-3)

- **A1. Cross-section refactor of shared write machinery** (gimli: generalize a widely-called helper off a concrete newtype; 14/20 compile-fail; wrong refactor regresses 492 base tests). The difficulty is invasive threading, not new logic.
- **A2. Orthogonal fair-wall stacks in a genuinely multi-behavior subsystem** (piccolo GC: resurrection-refeed 5/7 + arg-consume 3/7 + once-each 1/7 + reverse-order 1/7 + kv-vs-ephemeron 1/7 → 30%). Only works when the subsystem truly has ≥5 independent behaviors; one test per axis, never deeper tests on one axis.
- **A3. Reuse-the-machinery missing-arm** (kcl: existing recursive helper handles Dict/Schema but structurally lacks a List arm; ~9/11 kills, 8.3%). The natural reuse covers common cases and silently can't reach one form.
- **A4. Host-language semantics traps** (tengo: Go embedding `Equals()` receiver mismatch kills Nova 9/10; `transform.Expr` 3-value arity kills 4/10 in gms). Fair when the repo's own source demonstrates the correct pattern.
- **A5. Naive-dominant-reading + de-crutched helper** (parry: bilinear-interpolation prior vs actual triangle mesh; private helper forces re-derivation; type-contract drift usize→u32 3/10). Test on geometry that DISTINGUISHES the readings.
- **A6. Second-op narrow-guard** (symengine: delegation mandated for op A; agents hardcode the canonical type in op B; 9/10). Weaponize via a sibling type in the second op — never name the type list.
- **A7. Determination-channel seams** (clpq: a delayed obligation must fire off EVERY determination channel — unification, collapse, implicit equality, merge; agents wire one; 7/10 + 6/10). Knob = seam count through one chokepoint.
- **A8. Polarity/precedence/boundary inversions** — negated 3VL set/range (gms-null 12/13: NOT-IN = union where IN = intersection); precedence-boundary chains (erg 3/7: run closed by lower-precedence operator must chain FIRST); validation-order/empty-input precedence (data-forge 12/13: empty must short-circuit before required-arg validation). One sentence states the rule; the natural code order is still wrong.
- **A9. Exact-fit-passing index arithmetic** (nickel-array-rest: head-relative suffix indexing passes when middle is empty, fails otherwise). The agent's own smoke tests use the exact-fit shape — pick walls agents self-test AROUND.
- **A10. Numerical-stability orthogonal wall** (truck: accumulate-about-origin cancellation at 1e5; 8/10; moved 50%→20% because it was ORTHOGONAL to the existing wall). Frame as documented translation-invariance.
- **A11. Grammar/LR(1) compile walls** (nickel-array-rest 8/20 on LALRPOP ParseError conversion; gluon mixed-KIND chains panicking the author's own reference until probed). Parser-generator machinery resists transcription.
- **A12. Type-equality gate vs const-eval** (numbat 5/11: `0-2` doesn't deduce exact Scalar; unary `-2` does). Pair the passing form with the failing form.

### B-tier (support levers — never the main engine)

- Time/debug-burn on genuinely deep arithmetic (scryer run 10 died at 3600s) — real but uncontrollable.
- Capability walls (exact bignum expansion) — viable ONLY without a worked example in the meta; scryer proved the example hands the approach (80%).
- Codebase-inferable conventions (≤1 per problem) as the derivable anchor.

### P-tier — PROPOSED techniques (⚠️ NOT YET ORACLE-TESTED — no batch evidence; try on the next suitable pick, record the result in that problem's feedback.md, then promote to S/A or demote to DEAD)

**P1. ALGEBRAIC-LAW CONTRACTS** — document LAWS instead of behaviors: idempotence, commutativity, associativity, inverse round-trips, conservation ("undo(do(x)) == x for every operation"; "merge is associative"; "everything registered is unregistered on every exit path"). Why it should work: a law is ONE sentence (Rule-7 compatible, fairness-complete, FP-safe — the law maps to tests cleanly) but its instance space is COMBINATORIAL, so it cannot be transcribed as a checklist; and it converts pointwise-decoupled operations (DEAD class) into globally-coupled ones BY CONTRACT — manufacturing the #1 surviving difficulty on demand. Tests = deterministic property sweeps (fixed seeds) at composition points: dozens of discriminators from one documented sentence. ⚠ Caveat: pick laws with a REPO-specific twist (a pure textbook law like merge-associativity is a trainable prior); the strongest form is a law that holds EXCEPT where a documented rule interacts (stacks with S2). Supporting indirect evidence: piccolo per-registration conservation (P37) and clpq determination-channel obligations are law-shaped and both held bands.

**P2. OVER-EAGERNESS / QUIESCENCE TRAPS** — weaponize the steroid cohort's strongest bias (thorough, defensive, do-everything code) with contracts that require doing LESS: short-circuit FIRST, lazy evaluation, preserve-don't-rebuild, first-error-wins, must-NOT-revalidate-untouched-siblings. Assert via BEHAVIOR (which error surfaces, what is preserved byte-identical, the repo's own event/count instrumentation) — never timing. Indirect evidence is already top-shelf: data-forge validation-order 12/13 (agents validated eagerly before the documented empty-input short-circuit) and zen filter-rebuild (thorough rebuild stripped Nullable) are both over-eagerness kills that happened by accident — P2 makes them deliberate. ⚠ Caveat: word the contract as observable precedence/preservation (WHAT), not as "don't recompute" (HOW) — a lazily-worded quiescence rule reads over-prescriptive.

**P3. SELF-TEST-SHADOW GENERATOR** (method step, not a trap class — see § 3a step 4b): agents write their own smoke tests in the SHAPE their implementation already handles (participle: one nested-pointer shape; nickel-array-rest: exact-fit; fundsp: producer-first; zen: day-aligned dates — 4x observed). For EVERY requirement, predict the agent's natural probe input, then place the discriminator OFF that shape. Produces false confidence → ship → caught.

### DEAD — do not build (full case studies in TOO-EASY.md)

Membership/validation contracts · single-subsystem mechanical transforms · misdirection-only picks · uniform-wraps · saturated-reference ports (incl. whole CAS-kernel repos) · correlated-seam funnels (one chokepoint clears all variants) · textbook-standard features (derivative, "you cannot out-add a superset", 5x confirmed) · single-insight reindex transforms · shallow string builtins · pointwise-decoupled measurements (100% x 2 even after interdependent-test padding) · thread-existing-capability (LOC ceiling) · "make X consistent with existing-CORRECT sibling Y" (Y is the answer key) · float-arithmetic trap webs (text-parse architecture is immune) · near-tie value gambles (2.675-class: route-dependent, undocumented — DON'T-TEST) · clock/time-burn as a lever (R6: batch got FASTER).

---

## 3. THE METHOD — designing and re-hardening, fairly

### 3a. At design time

1. **Pick globally-coupled** (PICK-FILTER Gates + golden-LOC section). The feature's correctness must be an invariant SPANNING operations/paths/subsystems — mutation-under-invariant, staged pipelines, engine semantics. Pointwise features cap at 40-60% forever (scryer's separable directives ceiling, 3x confirmed).
2. **Enumerate the engine's operation set + the subsystem's orthogonal axes yourself** (the fundsp/piccolo prep). This list is YOUR trap inventory — it never goes in the meta.
3. **Bake 3+ arsenal traps, led by an S-tier.** For each, verify CONTRACT-STATED/FIX-HIDDEN: write the meta sentence that makes it fair, then check the sentence does not hand the fix. If it does, the trap is dead — replace it, don't hide the sentence.
4. **Prove each trap bites BEFORE authoring tests:** write the natural-but-wrong implementation (the one a strong agent would produce from the meta) and confirm it fails the discriminator with a MISDIRECTING symptom. participle build-measured the leak; go-geom probe-verified every fixture exact + tie-free. A trap you didn't reproduce is a guess.
   - **4b. (PROPOSED — P3 self-test-shadow):** for every requirement, also predict the agent's NATURAL smoke-test input shape (exact-fit, aligned, producer-first, single-shape) and place the discriminator OFF that shape. Tag first uses in feedback.md to build the evidence base.
5. **Naive-agent benchmark + skeleton probe** (KNOWLEDGE § Difficulty Calibration Protocol): ~70-85% naive pass = calibrated; >85% = add discriminators; <40% = tests misaligned with the natural architecture.
6. **Anticipate the ARCHITECTURE-JUMP:** ask "what alternative architecture defeats my whole trap family at once?" (text-parse defeated scryer's float web; parallel mini-engines almost defeated fundsp until crossfade forced the real machinery). Add one test that only the REAL machinery passes (crossfade-inside-loop, fade ratio asserted exactly).
7. **Plant the FP-closure tests up front:** per-requirement discriminators both directions (TESTS.md § FP Check); if the solution reroutes an existing API, test the OLD API's public output.

### 3b. Meta discipline (the erosion firewall)

- **Rule 7 / DE-ENUMERATION:** never enumerate walls, instances, or edge families. State ONE general principle per behavior family ("feedback edges are ordinary members of the connection model; everything a network already does keeps working") and let agents derive instances. Measured: symengine 100%→10%; fundsp enumerations produced 100% then 90%. Agents do NOT expand general→instances reliably — the blind spot works FOR you.
- **GIVEAWAY AUDIT:** strip any sentence that spotlights WHICH requirements are hard ("Two spots are easy to get wrong:" spiked scryer to 60%). Strip worked examples that hand a capability-wall approach (the `~20e` example → 80%).
- **The fairness floor is the CONTRACT:** exact option shapes (`key(true)` not bare `key` — 3x fairness fail), canonical forms, error TYPES (kinds a NATURAL solution produces — see 3d), boundary inclusivity, textual consequences (dangling point, sign-on-zero). At the floor, every clause has a fairness-precedent reason to exist; anything beyond it is a gift.
- **For NOVEL semantics the de-prescription floor is the RULE ITSELF** (gluon: dropping leftmost-commit drew 9 unfair flags; the rule went back, its consequences stayed unstated). De-enumerate INSTANCES, never the defining rule.

### 3c. When a batch reads TOO EASY (>40%)

Diagnose before touching anything:

1. **Read the passers, not the rate.** Differential harness (go-geom): run every passing agent's patch against your CANDIDATE new tests on a fixture battery — mines which kill-tests actually discriminate, catches your own reference's bugs (twice: go-geom Point-witness; gluon 3 reference-killer probes). TRAP-PROOF method (fundsp): re-run a prior passing solution against the hardened suite — old passer must now fail (8/47).
2. **Classify the erosion:** (a) a fairness sentence handed the recipe → Rule 7 the meta (remove instance lists, keep the rule); (b) agents cleared isolated probes → COMPOSITION-first re-harden (S2), test-only, zero new meta sentences, solution byte-identical (nickel-optional round 4, go-geom R4 — the proven shape); (c) an architecture-jump neutralized the family → add the machinery-forcing test (S4) or accept the ceiling; (d) the domain is separable/recallable → trap-stacking is FUTILE (Pattern 17); add a genuinely independent coupled sub-feature with its own integration path, or shelve (scryer R7 pivot).
3. **REFERENCE-UNCHANGED = DEAD TEST:** a new test your unmodified reference already passes will not move the rate (scryer R5 replay: 9/10 passers scored 0 fails on all 49 interaction traps; R6's exact-depth cluster "killed nobody"). Every hardening test must fail the STRONGEST PASSING AGENT's actual patch — that's what the differential harness verifies.
4. **One lever per round** (band is ~one run wide); the 10-run Nova-heavy batch is the only oracle. Never conclude from an all-Orion batch (gms 80% artifact).

### 3c-bis. When a batch reads 0% / NEAR-0 (the inverse of 3c — restore a fair edge WITHOUT making it easy)

0% is a REJECT, not a badge. But the fix is almost never "make the feature simpler" — it is a targeted diagnosis of WHY every agent died, then the minimum intervention that lets ONE strong agent through while the wall stays standing. Run this before touching anything.

1. **Read the failure SIGNATURE, not just the count.** Grade every failed run's actual patch and look at the failing VALUES. If all agents fail the same test with the SAME wrong value (pyomo-dae-mesh-refinement: every Opus run produced `0.375` vs the correct `0.34375`, a refresh sequenced one step too early), you have ONE well-defined missed sub-step — the profile of a fair-but-hard wall, not an unsolvable one. Divergent failure values = agents are flailing = suspect an unfair or ambiguous spec instead.
2. **Classify with the fairness table** (`DIAMOND.md § Step 5b`, applies to ALL tiers, not just Diamond):
   - *All agents emit a reasonable-but-different impl the tests reject* → tests check an IMPLEMENTATION DETAIL. Relax to a sentinel / behavioral assert (`errors.Is` + Kind; a value equality; exception TYPE not message). This was 2 of the fairness bugs on pyomo-dae (error-message substring pins, and a `ValueError`-vs-`DAE_Error` kind that the repo itself uses both ways).
   - *All agents miss a requirement that isn't actually stated* → HIDDEN REQUIREMENT. Add ONE explicit meta sentence, or fix the test so it stops smuggling an out-of-scope demand. ⭐ The sharpest version: a test that can only pass by fixing PRE-EXISTING base behavior the feature never touched (pyomo-dae: the Integral reference was orphaned by the ORDINARY first discretization, so passing silently required repairing the non-refine path — a strong solver implemented the described feature perfectly and still failed). The fix is to the TEST (construct the fixture so it exercises the described property), not the meta.
   - *All agents fail at ONE genuinely hard step* → real difficulty, LEGITIMATE to keep. This is the only branch where you ease via disclosure rather than repair.
3. **The disclosure lever: name the ROOT CAUSE, never the FIX** (lark-counterexamples, KNOWLEDGE:45 — the canonical precedent). A fair 0/N resting on one hard step moves to ~3-6/10 when the meta names the root cause only ("repeated in-process calls must behave independently"; "the refreshed value must reflect the rebuilt mesh, not the coarse one"), and jumps to a ~8/10 too-easy ceiling if you name both the fix and its consequences. Reword to state WHERE the difficulty lives (the ordering / the interaction / which components observe it), keeping the mechanism and the fix hidden — this is CONTRACT-STATED/FIX-HIDDEN (§1) applied as an easing move. Prefer a meta REWORD (make the contract concrete: name the components and the observable) over a hint; hints are a Diamond-only escape and hints on an UNFAIR problem hide the unfairness instead of fixing it (admin 2026-05-29).
4. **Add a discriminator that STEERS the probe, not one that hands the answer.** The self-test-shadow (P3) is usually why 0% happens: every agent tested the shape its own impl handled and never probed the failing one. A fair easing test makes the missed shape the OBVIOUS thing to check (a test whose name/structure implies "evaluate the integral through a constraint after refining") without encoding the fix. Verify it still fails the strongest failing patch and passes a correct reference.
5. **Re-batch and confirm you moved OFF the 0% edge but not past 40%.** One lever per round; the fresh-agent batch is the only oracle. A single historical pass does NOT prove reproducible solvability — 1-pass-then-0/3 means you are sitting ON the edge (reject-risk direction), and the disclosure lever (step 3) is the correct response, not shipping on the lone pass.

**Anti-levers (do NOT do these to clear 0%):** delete the hard requirement (collapses the wall); replace the deep test with a shallow one (too-easy); add a worked example that hands the approach (`~20e` spiked scryer to 80%); enumerate the fix steps in meta (Rule-7 violation, checklist-transcribed). Easing means restoring FAIRNESS or DISCOVERABILITY, never removing the difficulty.

### 3d. Fairness boundaries while hardening (each cost a round somewhere)

- **Error-kind natural-solution law** (gms, 14 rounds): a rejection test's pinned kind must be one a NATURAL correct solution produces AND the repo already asserts for a mapped situation. Untestable-fairly rejections (CHECK OPTION class): remove the feature claim from the meta rather than ship a brittle pin.
- **No error-message substring pins** (data-forge: the checker accepted then rejected the same tokens across rounds — no substring is stably fair). Behavioral value-asserts + bare throw.
- **MUST-break witnesses on fully-determined shapes** (go-geom: line-level witnesses, never anchoring-free rings).
- **Order among independent items = order-insensitive asserts**; order within one derived set is fine.
- **New/second-side schemes with no in-repo consumer must be stated** (parry 2D numbering); grep for an existing consumer first.
- **No undiscoverable host APIs; no traps contradicting the repo's own semantics** (piccolo register_finalizer; mq graphemes).
- **Never pad LOC with public API** (participle `Greedy()` = Blocking scope-creep fail). Scope levers must be genuine behavior (kcl `|=` was named in the description).
- **Baseline maintenance is fair when the meta warns** "validate against the full suite" (nickel golden flips).
- **FP-fix targets DOCUMENTED requirements only** (scryer b_f1_rnd cratered to 0% on undocumented ~f preservation — reverted).
- **Env-blocker inflation:** `/opt/cargo` perms suppress raw pass counts without changing fairness verdicts — expect a bump on a clean re-batch; don't over-harden against inflated difficulty.

---

### 3e. Data requirements — capture at batch time or lose the method

The methods split by what they need. Design-time methods (arsenal selection, CONTRACT-STATED/FIX-HIDDEN, trap reproduction, Rule-7 audit, naive benchmark, skeleton probe, P1/P2/P3) need NO agent data. Diagnosis methods need what you CAPTURED:

| Needs only a rich eval-results.md | Needs the ACTUAL agent patches |
|---|---|
| Strongest-agent diagnostic; erosion classification (recipe vs thoroughness vs ceiling); pass-rate math; fairness-flag triage | Differential harness; trap-proof; architecture-jump detection; FP watch-item verification; leanest-passer effective-LOC |

**Capture protocol (run at EVERY batch, while the platform run view is open):**
1. eval-results.md per-run row MUST include: verdict, **failed test NAMES**, msgs/LOC/files, and a one-line **approach note** (what architecture the agent chose — this is what detects an architecture-jump without the diff).
2. **Save every PASSING agent's solution diff** to `problems/<name>/agent-runs/<batch>-<run>.patch` (and the 1-2 most instructive failers). Without these, the differential harness, trap-proof, FP verification, and leanest-passer LOC are impossible later — the platform view is the only source and it isn't guaranteed to stay accessible.
3. If patches were NOT captured for a past batch, the fallback diagnosis is eval-results-only (strongest-agent + erosion class) — weaker but workable; never re-harden blind without at least that.

**Re-eval (platform, 2026-09-03) is now the authoritative version of the differential harness.** When the only thing you changed since the last batch is `test.patch` and/or `solution.patch`, a green Re-eval button re-runs the REAL grader over that batch's real solutions for ~30% of batch price. Prefer it over a local kill count whenever it is offered: the local replay was always an approximation of exactly this measurement. Keep capturing `agent-runs/*.patch` anyway — they remain how you READ why an agent failed, and the only copy if the run view rotates. Two consequences for this section's methods: the differential harness is now a STEERING tool you run locally between re-evals, not the decision; and the button's ABSENCE is diagnostic — it means your lever touched the description or the environment, which is precisely the case where the local kill count lies (see the law index below).

## 4. Steroids-era laws (one-line index)

| Law | Source |
|---|---|
| GATE-EROSION: stated-rule traps die when documented; composition traps survive gates + batches | zen |
| CHECKLIST-META / Rule 7: enumerated walls = to-do list; de-enumerate to ONE general principle | fundsp x2, symengine |
| RULE-INTERACTION-SEAM: documented rules get implemented; compositions of them do not | go-geom x2 |
| CONTRACT-STATED/FIX-HIDDEN: a trap survives iff stating its contract doesn't reveal its fix | participle vs petgraph |
| REFERENCE-UNCHANGED = DEAD TEST: hardening tests must fail the strongest passer's actual patch | scryer R5/R6 |
| ARCHITECTURE-JUMP: one alternative architecture can immunize a whole trap family | scryer text-parse |
| WORKED-EXAMPLE-HANDS-THE-APPROACH: capability walls die when the meta shows the target | scryer P81 → 80% |
| AGENT-MIX: all-Orion ≈ +60pts vs all-Nova on the same artifact; only the standard mix is the oracle | gms 80/20/10 |
| TEST-COUNT RAISES PASS RATE: breadth/count padding dilutes with passes | findmyway, piccolo, scryer |
| POINTWISE-DECOUPLED = DEAD: independent reductions brute-force; pick globally-coupled | go-geom-distance 100% x2 |
| TRAP-PROOF: re-run an old passing solution against the hardened suite before batching | fundsp 8/47 |
| DIFFERENTIAL-HARNESS: batch patches vs candidate tests mine real kill-tests + catch reference bugs | go-geom, gluon |
| RE-EVAL-IS-THE-HARNESS: a tests-only round re-grades the last batch for ~30%; no button = your lever was a description delta and the local replay would have lied | platform 2026-09-03 (L36) |
| SPEED-CORRELATES-WITH-FAILURE: the lone passer is repeatedly slow, long-horizon Orion | stoolap, participle, zen-hit, clpq |
| PICK-THE-SHAPE-AGENTS-SELF-TEST-AROUND: agents write their own edge tests in the shape their impl handles | participle, nickel-array-rest |

---

## 5. Pre-submit hardening checklist (runs alongside the FP + flakiness gates)

- [ ] Lead trap is S-tier; ≥3 arsenal traps total; each verified CONTRACT-STATED/FIX-HIDDEN
- [ ] Every trap REPRODUCED: the natural-but-wrong impl written and confirmed failing with a misdirecting symptom
- [ ] Architecture-jump considered; one machinery-forcing test present
- [ ] Meta passed the Rule-7 audit: no wall enumerations, no pitfall spotlights, no capability worked-examples; general principles only; novel-semantics RULES stated
- [ ] Fairness floor intact: option shapes, canonical forms, natural error kinds, no substring pins, order-insensitive independents
- [ ] Baseline-preservation trap present AND base mode runs the shared-path integration tests
- [ ] FP mapped both directions (every requirement → discriminator; every test → sentence); old-API public-output test if anything is rerouted
- [ ] Naive-agent benchmark in 70-85%; skeleton probe run at pick time
- [ ] If re-hardening: differential harness / trap-proof run; one lever; composition-first; zero new meta sentences when meta is at the fairness floor
