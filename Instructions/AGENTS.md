# AGENTS — Behavior, Blind Spots, Fairness

How AI agents approach challenges, where they fail, and how to design fair-but-difficult problems.

> **Read first:** `PLAYBOOK.md § Pattern 6 (How Approval Looked)` and `§ Pattern 8 (Stuck in Revision Cycles)`.

---

## Configuration (April 2026)

| Tier | Agent mix | Pass rate target | Token cost |
|---|---|---|---|
| **Mars** | 10 Nova + 2 Orion (Orion Evaluator) | **≤ 30%** (solvable; ~2+ interdependent + misdirecting traps) | Nova ⚡ 1, Orion standard |
| **Olympus** | Nova + Orion + Vega mix | ~10% | Vega ⚡ 10 |

**Hints removed for Mars + Olympus (April 2026); Diamond keeps its hint flow.** If Olympus stalls at 0%, options: (1) fix description ambiguity, (2) fix unfair test, (3) resubmit as Mars, or (4) route to Diamond + hints if near-0 (hardest-viable-tier stance — do not soften to hit a band).

**Castor is primarily a Diamond agent, but Olympus also accepts Castor runs** (e.g. csstree-specificity, gluesql-window-functions — not Diamond-exclusive). Mars uses Nova+Orion. Olympus uses Nova/Orion/Vega (+ Castor on some). Diamond requires 10+ Castor runs at **≤30% = 1-3 of 10** (post 2026-05-13 relaunch). Castor blind spots apply cross-agent to Nova/Orion/Vega — same model family. See `DIAMOND.md` for Castor-specific Diamond workflow + `KNOWLEDGE.md § Castor` for documented blind spots.

---

## Agent Environment

- Receives `meta.md` + the repo at the base commit
- Examines codebase (reads files, searches patterns)
- **Cannot see tests** — `test.patch` is applied separately for evaluation
- Limited message/turn budget
- Submits a solution patch tested against `test.patch`

---

## What Agents Are Good At

- Reading and understanding code structure
- Following established patterns in a codebase
- Implementing well-described features step-by-step
- Making changes that align with existing conventions
- Handling straightforward edge cases

## What Agents Struggle With

- Ambiguous requirements with multiple valid interpretations
- Design decisions where the "right" choice isn't obvious from the codebase
- Cross-package integration when the relationship between packages isn't clear
- Implicit requirements not stated or easily discoverable
- Long chains of reasoning across many files

---

## Confirmed Blind Spots (Cross-Agent)

These trip ALL agents — design around them:

| Blind Spot | Example | Pre-empt sentence |
|---|---|---|
| **Specific examples override general rules** | "only X triggers behavior" → agents implement only X guard | State the general constraint first, then examples |
| **Type inference defaults to overly restrictive** | `unknown` collapses to `Array<Record<...>>` | Specify type in description if ambiguous |
| **"Initializing" = "call default constructor"** | Agents call default setup including built-ins | Replace with "sets up Y without adding any built-in Z" |
| **Cross-feature ordering missed** | Primitive gate fires AFTER column validation when it should fire BEFORE | Spell out ordering: "must run before X" |
| **Reference sharing instead of deep copy** | Cloned objects share state | State "deep copy" / "no shared references" if matters |
| **AST traversal defaults to bottom-up** | 12/12 agents used `map_bottom_up` for pest-factorizer | If direction is semantic, spell out "process pairwise from left to right" |
| **Rule/Ident resolution skipped** | Agents implement predicates locally, return `false` for identifiers | "Resolve rule references through the grammar's rule map when checking …" (factorizer pre-empt) |
| **Unstated inverse not implied** | Description says "X happens when Y not configured" → agents implement X always | State both sides explicitly if both matter |
| **Default → first/common choice** | When ordering unspecified, agents pick lexicographic or insertion order | Specify the canonical form |
| **Goroutine-id maps for concurrency state in interpreters** | 16/18 Castor used `sync.Map`/`f.root`-keyed shared state in yaegi (which shares OS threads → gid-keyed broken). Only 2/18 discovered per-frame state propagation. | Concrete architectural recipe: "per-frame state field inherited from parent, reset at goStmt ancestor boundary." Abstract "frame hierarchy" hint failed (89%→90%). |
| **Sum-per-call instead of persistent set** | 7/11 Castor wrote `cr.TotalLines += lineCount` (Σ per-call distinct) instead of lifetime `|∪|`. 2-line func × 2 calls = 4 not 2. | **Concrete counter-example with literal values** ("2-line func called twice yields 2, not 4"). The word "distinct" alone is insufficient. Hint dropped failure 100%→22%. |
| **Required-arg validation runs BEFORE empty-input short-circuit** | 12/13 Nova+Orion guarded "time column exists" before handling `new DataFrame([])` (which has no inferable columns) → threw missing-column instead of returning empty. Was the SOLE failing test (47/48) and pinned data-forge-resample at 7.7%. Misdirecting (error says "missing column", cause is validation ORDER). | When a spec has BOTH "missing X throws" AND "empty input → empty result", agents implement the throw unconditionally. A great trap as-is; if you need it solvable, add: "an empty input returns an empty result before any column/timestamp validation." |
| **Canonical-type narrow-guard (special-case dominant type, forget co-equal siblings)** | 9/10 Nova gated ImageSet interval-enumeration on `is_a<Integers>(*base)` and forgot Naturals/Naturals0 are ALSO integer-indexed → `{2n:Naturals} ∩ [-4,4]` never enumerated. Load-bearing wall pinning symengine-imageset at 10% (Mars). Misdirecting ("integer-indexed" reads as "== the canonical type"); interdependent (the `base->contains` delegation the spec mandates for MEMBERSHIP must ALSO be used in the ENUMERATION path — agents split them). | Do NOT enumerate the type list in meta (gives it away). State the DELEGATION once ("ask the base set whether it contains that index"), put the sibling-type case (Naturals/Naturals0) ONLY in a hidden test. Fair fix = delegate-through-the-predicate; agents who hardcode the dominant type fail the siblings. |

---

## Per-Agent Profiles (Refined From 14 Approved Problems)

### Nova
- **Role:** Mars primary (10 runs at ⚡1 token each)
- **Strengths:** Exploration-heavy. Compact passing solutions when it works. Best on Mars Shape A1 (distributed pipeline, slow), Shape A2 (concentrated + sig change, fast). Pairs well with Orion as evaluator.
- **Best Mars shapes:** A1, A2, C, D-change (often co-solver with Vega)
- **Olympus performance:** Weak alone. 0/27 across Olympus problems where Nova-alone attempted.
- **Blind spots:** High thrashing on hard problems (1000+ messages → Early Termination); type conversion bypass; TS intersection types narrowed to `never`; `fmt.Errorf` no-op passthrough; frequent API failures on simple tasks.

### Orion
- **Role:** Both tiers; evaluator for Mars
- **Strengths:** **Decisive commit-and-implement style.** Picks an architecture and executes thoroughly without backtracking. Highest LOC-per-message efficiency (~6.5 LOC/msg on Olympus solves).
- **Best Mars shapes:** **B (smashes 2/2)**, **D-new (smashes 2/2)** — when description names the API surface or new variant explicitly, Orion converges immediately
- **Best Olympus shapes:** **O-Composite-extend (2/2 on dagster)**, **O-Algorithm-coverage (1/1 on inliner)**
- **Blind spots:** Binary decision-making — when wrong architecture is chosen, commits fully and doesn't pivot. Fails on Mars Shape A1 (distributed semantic complexity). `errors.As` half works perfectly while `reflect.TypeOf` half completely fails. Can implement one subsystem cleanly while another gets fundamentally wrong design. Doesn't self-debug.

### Vega ⚡10 tokens — Olympus only

- **Role:** Olympus only — heavy multi-stage refactoring and add-new-feature problems
- **Olympus pass rate: 31.3% (10/32 attempts)** — leading Olympus agent
- **Strengths:** Heavy deliberation across multiple subsystems. Long-horizon capable. Handles 700-975 LOC solutions while remaining correct. Best on:
  - **O-Pipeline-easy (3/5 on charclass)** — pattern coalescing / interval merging
  - **O-Pipeline-hard (2/6 on seq-rewriter)** — invent transformation algorithms
  - **O-Composite-add (3/5 on goja-using)** — add new feature spanning parser/compiler/VM/runtime
  - **O-Algorithm-correctness (1/4 on dispatch)** — partial; subtle algorithm
  - **Mars D-change** when used in mixed runs (1/1 on extended-skip)
- **Specific blind spots (NOT universal weakness):**
  - **Symmetric aggregation refactor (O-Composite-extend):** 0/2 on dagster — extending an N→N+1 dimension `all()` check trips Vega
  - **O-Algorithm-coverage (inliner):** 0/4 — Orion better here ("implement everything I see" approach includes new variant in counters; Vega's deliberation may skip)
  - **O-Trap universal LLM blind spots (normalizer):** 0/5 — placement-in-pipeline traps defeat all agents including Vega
- **Pairing:** Vega→Orion ≈ Vega-alone for most shapes. Slight edge to Vega→Orion when problem has clear architecture.
- **Cost:** ⚡10 tokens — only run on truly cross-subsystem Olympus problems. Don't run for Mars work.

### Castor ⚡25 tokens (throttled — temporary) — Diamond only

- **Role:** Diamond-tier eval target. 10+ runs required per submission. Failure QA on every test failure.
- **Pass-rate ceiling:** **≤30% (1-3 of 10)** post-relaunch 2026-05-13. >30% = too easy → redesign.
- **Strengths:** Highest absolute capability of the four agents. Implements 1500+ LOC solutions cleanly. Castor 50+/51 base regression on every cliffy-aliases failing run. Passes individual feature tests ~100%. Handles registry CRUD + error classes + file organization + base test preservation without slip.
- **Best Diamond-quality traps:** cross-architectural (same trap caught through 2+ distinct implementations) — see DIAMOND-PLAYBOOK § Section 1 for 8 categories ranked by hit rate.
- **Tier-downgrade behavior (confirmed yaegi-execution-tracer 2026-05-14):** Submissions at Castor <10% land at **Olympus tier instead of Diamond rejection**. Soft landing.
- **Cross-agent blind spots (confirmed on yaegi-execution-tracer):**
  - **Goroutine-id maps in interpreters:** 16/18 used `sync.Map`/`f.root` shared state instead of per-frame propagation. Only 2/18 independently discovered frame-anchored state.
  - **Sum-per-call aggregation:** 7/11 wrote `cr.TotalLines += lineCount` instead of lifetime `|∪|`. Counter-example with literal values needed to disambiguate.
  - **Bash heredoc death:** 25% of multi-layer Go runs lose test capability mid-session (228-328 msgs). Bash sandbox restart loop on `cat > file.go << 'GOEOF'`.
  - **go.mod version bump:** Castor dismisses self-caused regressions as "pre-existing" (40% trip rate on tengo-crypto).
  - **Same-object-as-inherited:** 6/10 cliffy-aliases `clearRegisteredAliases` test — globals on current command erased through 2 architectures (single-map + separate-maps-no-current-walk).
- **Cost:** ⚡25 tokens × 10x = 250 tokens per eval batch. Diamond Checks add 50 tokens preflight.
- **Hint cliff:** abstract hints fail consistently; **concrete counter-example values (literal char/path/numeric) succeed** (TotalLines hint dropped failure 100%→22%).
- **Hierarchy:** Castor > Vega ≈ Orion > Nova on absolute capability. Different blind spots than Nova/Orion/Vega — don't assume cross-agent learnings apply.

See `KNOWLEDGE.md § Castor` for full trap inventory + `DIAMOND-PLAYBOOK.md § Section 1` for 8 trap categories.

---

## Best Agent by Shape (Decision Matrix)

After 13 problems, agent-shape pairings:

### Mars

| Shape | Best Agent | Why |
|---|---|---|
| A1 (distributed pipeline) | Nova→Orion (slow) | Needs exploration time |
| A2 (concentrated + sig change) | Nova→Orion (fast) | Architecture clear once read |
| **B (add new public API list)** | **Orion-alone (smashes 2/2)** | Description names the API; Orion commits |
| C (additive extension) | Nova→Orion | Existing code provides scaffolding |
| **D-new (new cross-crate variant)** | **Orion-alone (smashes 2/2)** | "Implement variant + all matches" decisive |
| D-change (variant sig change) | Nova→Orion + Vega | Existing pattern + heavy refactor |

### Olympus

| Shape | Best Agent | Why |
|---|---|---|
| **O-Composite-extend** | **Orion (2/2 on dagster)** | Symmetric refactor; commit-and-implement |
| **O-Composite-add** | **Vega (3/5 on goja-using)** | Heavy multi-stage feature |
| **O-Pipeline-easy** | **Vega (3/5 on charclass)** | Familiar coalescing algorithm |
| **O-Pipeline-hard** | **Vega (2/6 on seq-rewriter)** | Invent transformation |
| **O-Algorithm-coverage** | **Orion-alone (1/1 on inliner)** | "Implement everything" includes new variant |
| **O-Algorithm-correctness** | Mixed (Vega + Nova→Orion) | Subtle algorithm, luck-of-the-draw |
| **O-Trap (HISTORICAL)** | None | Universal blind spot, no longer approvable |

---

## Failure Categories (From 13 Approved Problems)

| Category | Where it dominates | Description |
|---|---|---|
| **MISSED_REQUIREMENT** | most shapes (47-77%) | Explicitly stated requirement not implemented |
| **WRONG_LOGIC** | O-Algorithm-correctness (25%), O-Algorithm-coverage (40%), O-Trap (33%) | Correct understanding, buggy implementation. **≥25% Wrong Logic = subtle algorithmic trap.** |
| **REGRESSION** | D-change (44%), D-new (12-21%) | Broke baseline tests. Rust-specific — non-exhaustive match across crates. |
| **INTEGRATION_ERROR** | D-new (43%), Olympus heavy (15-20%) | Compile error in cross-crate exhaustive match |
| **EXECUTION_ERROR** ⭐ NEW | rare (~4% in P9 dispatch) | Runtime crash distinct from compile error or logic error |
| **EARLY_TERMINATION** ⭐ NEW | up to 17% on heaviest Olympus | Two patterns: long-horizon exhaustion (1000+ msgs Nova thrashing) OR premature commit (153 LOC, "I'm done") |
| UNVERIFIED_ASSUMPTION | ~4% | Assumed API existed without checking |
| KNOWLEDGE_GAP | ~2% | Lacked framework-specific knowledge |
| MISUNDERSTOOD_TASK | ~2% | Wrong scope entirely |

### Wrong Logic % is a Difficulty Signal

| Wrong Logic % | Difficulty |
|---|---|
| 0% | Standard Mars / mostly Missed Req |
| 5–10% | Light algorithmic subtlety |
| **≥25%** | **Subtle algorithmic / semantic correctness trap. Pass rate 0–10%. Hardest problems.** |

If you're seeing Wrong Logic ≥25% on your problem, you're at Olympus difficulty.

---

## Special Verdict Notes

- **FAIL_TEST_MISMATCH (e.g., 48/49)** — almost passed; missed 1-2 tests. Likely fairness issue (description missing detail). Aim for 0 across approved problems.
- **FAIL_AMBIGUOUS_TASK** — agent flagged unclear. 2 runs with `description_clear=false` directly cause `agentFair=FAIL`.
- **FAIL_KNOWLEDGE_GAP** — agent doesn't know the framework. Ideal for niche repos.

---

## Fairness Rule

For every test assertion, you must be able to point to:
1. The **exact sentence** in the description, OR
2. An **obvious codebase pattern** that makes it inferable

If neither exists, the test is unfair.

### What counts as "inferable"
- Standard library / language behavior
- Obvious edge cases (null, empty, boundaries)
- Repository conventions visible in existing code
- Logical consequences of stated requirements

### What does NOT count as inferable
- Specific algorithms when multiple valid approaches exist
- Ordering / formatting when unspecified and multiple are reasonable
- Error message wording unless specified
- Performance constraints unless mentioned
- **Unstated inverse:** "X happens when Y not configured" doesn't imply "X must NOT happen when Y IS configured"

### Prioritize fairness over naturalness

If a fairness warning flags missing interface details that tests expect, **state the API explicitly** even if it sounds less natural. It's OK to name method signatures, error class names, etc. when introducing new features.

---

## Diagnosing Agent Failures

| Symptom | Likely Cause | Fix |
|---|---|---|
| ALL agents fail SAME test | Unfair — description missing info | Add one sentence to meta.md |
| Agents fail on DIFFERENT tests | Genuine difficulty | Keep |
| Agents 1–2 tests away from passing | Add explicit detail (fairness) + 1–2 compensating harder tests (maintain difficulty) | Both |
| 3+ evaluators mark `was_mentioned_in_description: false` | Certain unfairness flag | Add one sentence |
| 0/10 pass | Unfair or extremely hard | Check fairness first, then difficulty |
| 8+/10 pass | Too easy | Add cross-package requirement |
| Near-miss (47/49 pass) | 1–2 hidden requirements | Identify failing tests; check description coverage |
| Agents put code in wrong location | Module placement not inferable | Add hint (not path) to description |
| Agents use wrong method names | Description doesn't specify; tests assert names | Specify in description (fairness > naturalness) |
| Stuck in loops (1000+ msgs → Early Termination) | Description too vague or open-ended | Add structure to description |

### When the description reviewer and Nova data disagree

The description-quality AI reviewer flags content it thinks is "inferable from the codebase" — cross-references to specific functions, pattern hints. Simultaneously, Nova runs tell you whether agents actually can solve without the content.

**Trust Nova empirical data over reviewer speculation.** If reviewer says drop a hint (HIGH) but Nova's best runs stall at 90/92 specifically on the tests the hint targets, the hint is load-bearing.

**Resolution protocol:**
1. Check Nova pass rate with the hint. If ≥10% and verdict is `PASS`, the hint is doing its job.
2. Check rate without the hint (prior runs or remove temporarily). If drops below 10% on the same test group, hint is load-bearing.
3. Trim the hint's *form* (drop specific function names, shorten prose) while keeping the *substantive instruction*. Example: "resolve rule references through the grammar's rule map, as `skipper::skip` does in the optimizer pipeline" → "resolve rule references through the grammar's rule map".
4. If trimming still leaves reviewer HIGH flags but Nova data holds, keep the substance and note in admin review notes. Nova verdict is the gate that matters for Mars approval.

**What the reviewer gets right:** purely inferable references ("as done in the adjacent pass") are usually safe to trim, IF the agent still has a concrete behavior to implement.

**What the reviewer gets wrong:** assumes agents will read adjacent code. In practice they often don't — especially when the existing signature (`factor(rule)` taking no map) doesn't signal that a map is needed.

---

## Difficulty Calibration

Target: **≤ 30% Nova/Orion pass rate** for Mars (solvable); ~10% for Olympus Good; ~0-30% Castor for Diamond. The knob is trap count/strength → pass-rate (1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%), NOT LOC. **Nova ≈ Castor now — traps must be INTERDEPENDENT + MISDIRECTING at EVERY tier (an isolated, self-revealing trap gets single-shot-fixed even by Nova).** Single ~50% / single-point / uniform-wrap trap = too easy everywhere. See `../CLAUDE.md § ⚠️ HARD RULE — Difficulty-Calibration Model`.

### How to increase difficulty (legitimately)

- Cross-feature interaction tests (3+ features combined)
- Writer-side behavior (agents implement reader, forget writer)
- Ordering constraints (strict validation before/after null substitution)
- Cross-cutting concerns (comment-char protection in quoting)
- State consumption patterns (value used once then behavior changes)
- Architectural decisions where multiple approaches exist

### How NOT to increase difficulty

- Trick wording or ambiguous requirements (unfair)
- Hidden requirements not in description (unfair)
- Requiring specific implementation approaches (prescriptive)
- Testing internal implementation details (brittle)
- Adding test volume (87 vs 118 tests doesn't change difficulty)

### Difficulty-fairness balance

When you clarify an ambiguity, estimate how many failing runs would now pass. If the fix pushes success rate above 5/10, add difficulty elsewhere to compensate. **Never sacrifice fairness for difficulty.**

---

## Message Count — How It Works

### Median is computed on PASSED runs only

The platform computes median message count **exclusively from runs where the agent solved the problem**. Failed runs are excluded.

- 1/10 pass with 56 messages → median = 56
- 3/12 pass with 116, 135, 169 messages → median = 135
- 403 messages for a failing bash-loop run = irrelevant to median

A problem targeting 1–3/12 passes is structurally biased toward low message counts because only the fastest agents solve.

### Why harder ≠ more messages

- Harder problems → fewer pass → only fastest pass → use fewer messages
- Stuck in 100–400 message debug loops → almost never pass
- Making a problem slightly easier brings in mediocre agents who take more messages — INCREASES median

### Design for high message counts from day one

Include at least one structural requirement forcing multi-package changes:

- **CLI flag registration** (~25–35 turns added)
- **Public API surface** consumed by another package (~20–30 turns added)
- **Second package integration** required

Add these from day one — once pass rate is calibrated, retrofitting destabilizes it.

---

## Token Rules

- Each check / agent eval costs tokens
- Fix ALL SOLVER-VISIBLE issues in one pass before running a batch — description, title, Dockerfile, base commit. Those are what cost full price to redo.
- Don't run checks on every small tweak
- Editing content after checks marks results stale → but **stale no longer means re-run** (2026-09-03). A `test.patch` / `solution.patch` edit keeps the agents' solving work valid, so the platform offers **Re-eval**: grading + evaluation only, over the last batch of solutions, at ~30% of batch price. A `meta.md` / title / environment edit invalidates the solving and there is no button — that is a full fresh batch.
- **Never fire a single smoke run while a re-eval is pending** — any fresh run dismisses the offer. Failed re-evals auto-refund; already-graded runs are not re-charged.
- Re-eval is a PAIRED re-measurement on one fixed solution set: use it to STEER (tighten a discriminator, relax an over-strict axis), a fresh batch to CONFIRM the submitted number. Full rules: `CLAUDE.md § RULE UPDATE 2026-09-03`.
- Solvability cannot be bypassed on Olympus
- Hints removed — switch to Mars if Olympus solvability stalls
- Early termination from API failures auto-refunds; other early terminations have an appeal button

---

## Tracking Files

Two files; never mix:

**`feedback.md`** — Strategic. Read before every iteration.
- Issue tracker: every reviewer complaint + fix status
- Attempt history: one row per submission
- Exact reviewer quotes
- Key learnings specific to this problem

**`eval-results.md`** — Raw eval data log. Query for failure patterns.
- Per-agent table per run: agent, evaluator, verdict, msg count, files, LOC, failed tests, failure reason
- Failure pattern summary
- Submission criteria results
- Cross-run fix tracking

`feedback.md` should be readable in 2 minutes before starting work. `eval-results.md` is the data archive.
