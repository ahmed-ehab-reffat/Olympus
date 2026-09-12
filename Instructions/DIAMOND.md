# Diamond-Tier Tasks

Diamond-tier is a premium level for select Olympus devs. Stricter evaluation, Failure QA, automated Diamond Checks preflight, and higher payout ($500 USD per approved submission).

> **Diamond Relaunch (2026-05-13):** Diamond is back with new automated **Diamond Checks** preflight pipeline replacing reviewer green-light. Discord channels gone — all feedback through Shipd. Castor pass-rate ceiling tightened to **≤30%**. See § Diamond Relaunch Changes below.

> **Read first:** `DIAMOND-PLAYBOOK.md` — evidence-based design + iteration discipline from 6 Diamond subs (84+ Castor runs). 8 cross-architectural trap categories, design-time checklist with LOC/word/test/API bands from 2 approved subs, iteration cost model (mean 8 eval + 4-6 QA rounds), failure-QA 12-rule writing guide, pre-submit maintainer-philosophy gate (Section 9 — covers the dasel-multi-file rejection lesson).

---

## What Makes Diamond Different

| Aspect | Standard Tier | Diamond Tier (Post-Relaunch) |
|--------|---------------|--------------|
| Agent type | Vega / Orion / Nova | **Castor only** (currently throttled to 25 tokens/run — temporary) |
| Required runs | 10+ total | **10+ Castor runs** |
| Pass rate target | 1-3 / 12 | **1-3 / 10 Castor (≤30% ceiling)** |
| Preflight | Standard prechecks | **Diamond Checks pipeline** (30min-1hr, 50 tokens full run) |
| QA approval | Reviewer green-light (DEPRECATED) | **Diamond Auto Review** auto-issues "approved for QA" badge |
| Failure QA | Not required | **REQUIRED for every test failure** |
| AI in QA | N/A | **Absolutely no AI** in Failure QA |
| Feedback channel | Discord | **All feedback through Shipd** (no Discord) |
| Review queue | Standard | **PRIORITY queue — minutes to few hours turnaround** |
| Payout | Standard | **$500 USD per approved submission + bonus potential** |
| Token cap | Standard | **Increased drips + cap** while in Diamond program |

---

## Diamond Checks (Automated Preflight) — NEW 2026-05-13

Diamond Checks runs BEFORE submission goes to reviewers. Surfaces structural issues (broken solution patch, broken test setup, ambiguous spec, etc.). Solves prior problem of devs starting QA, discovering broken submission, then editing + invalidating QA work.

**Total: 50 tokens full run. Duration: 30min-1hr.** Each pipeline step can run individually:

| Step | Cost | Purpose |
|---|---|---|
| **Rollouts** | 45 tokens per rollout job (3 rollouts per job) | Agent-style trajectory rollouts checking solvability |
| **Code Validation** | 15 tokens | Patch applies, builds, runs cleanly |
| **Full Environment QA** | 20 tokens | End-to-end Dockerfile + test.sh validation |

**Hinted submissions:** run pipeline TWICE — once for unhinted, once for hinted versions.

Think of Diamond Checks as another form of agent runs but with more evaluation + checks baked in.

---

## Diamond-Tier Submission Workflow (Post-Relaunch 2026-05-13)

**Only proceed to next step after addressing everything in previous step.**

### Step 1: Create the Task

Follow standard Olympus workflow (see `WORKFLOW.md`) to create 5 deliverables:
- `BASE_COMMIT.txt`
- `meta.md`
- `test.patch` (includes test.sh)
- `solution.patch`
- `Dockerfile`

All standard rules apply — WHAT not HOW in descriptions, comments match the repo convention (default NONE — not a blanket ban), no AI slop, **≥450 EFFECTIVE LOC DESIGN FLOOR (400 = platform auto-block; auto-review triggers below)**, 3+ files, test-description alignment.

### Step 2: Enable Diamond Label

Turn on the Diamond label in the top right corner. Can convert existing draft/review tasks to Diamond.

### Step 3: Prechecks + Postchecks

Run standard prechecks + postchecks. All quality checks pass (or valid bypass justifications) before proceeding.

### Step 4: Smoke Test (1x Castor or 1x Vega)

**Run 1x Castor (or even 1x Vega) FIRST** to catch environment blockers + obvious defects before full run. Cheap insurance against burning 10x Castor tokens on a broken submission.

Fix any environment issues before proceeding.

### Step 5: 10x Castor Runs + Diamond Checks

Submit **10 Castor runs** in parallel with **Diamond Checks** preflight pipeline. Target: **≤30% pass rate** (1-3 / 10).

| Outcome | Action |
|---------|--------|
| 1-3 Castor pass (≤30%) | ✅ Proceed to Step 6 |
| 4+ Castor pass (>30%) | ⚠️ Too easy — harden tests, expand scope, tighten description per `lessons-learned.md § Tighten-First Rule` |
| 0 Castor pass | ⟶ Add hint, run 10x more Castor (hinted) + Diamond Checks again (hinted) |

### Step 5a: Fairness Analysis Before Any Iteration (admin 2026-05-29) — MANDATORY

**Applies to every Castor batch, hinted or unhinted.** Before adding hints, adding clarifications, or running more agents, analyze WHY existing agents failed. Brute-forcing pass rate without analysis wastes tokens, produces low-quality submissions, and risks revert downstream.

**A good approach:** run a small batch first (1-3 Castor), then check why they passed or failed. Be honest and realistic — are the tests truly fair based on the prompt and repo conventions a competent engineer could discover, or are they testing a hidden implementation detail or contradicting repo conventions?

**Strong unfairness signal:** all or most agents fail for the same exact reason. Could mean:

| Pattern | Diagnosis | Fix |
|---|---|---|
| All agents emit a reasonable-but-different implementation that tests reject | Tests check implementation detail, not behavior | Relax to sentinel / behavioral assertion (e.g. `errors.Is` + `Kind`) |
| All agents miss a requirement that isn't actually stated | Meta has hidden requirement | Add the requirement to meta as an explicit sentence |
| All agents miss a requirement that IS stated but ambiguously | Meta is ambiguous (multiple reasonable approaches exist; only one passes tests) | Reword to disambiguate; if a specific approach is truly needed, prompt must say so |
| All agents fail at one genuinely hard step | Real difficulty (acceptable for Diamond) | Leave it; hint flow legitimate if still 0/10 after analysis |
| All agents pick a different public API SHAPE (value vs pointer slice, string vs struct field) and an external test package fails to COMPILE, zero-scoring the whole file | Under-specified return types + external test pkg imports by exact type (PATTERNS-ADVANCED § Pattern 47) | Reword: pin the return types in meta (`returns a []T`, `*T ... or nil`, field `as a line:col string`). Spec-completion, not a hint. yaegi-unreachable-code: 4/5 -> 2/10 after the pin |

**General principle:** tests should check behavioral requirements regardless of the approach the agent takes. If a specific approach is truly needed, the prompt must be clear about that.

**Skip Step 5b (hints) until Step 5a passes.** Hints on an unfair problem don't fix the unfairness — they hide it and lead to revert later.

### Step 5b: Hints Flow (If 0% Castor Pass AND Step 5a confirms fair — admin policy 2026-05-28)

**Trigger:** unhinted 10-Castor batch lands 0/10 AND problem is fair (failures all `agent_blame_unfair: false` and `was_inferable_from_codebase` true) AND Step 5a fairness analysis cleared. If failures are unfair / verifier-broken / collision-induced / point to ambiguity, fix the artifact first; hints are not the right response.

**Flow (admin Leonard 2026-05-28):**

1. **Add hint** in the Shipd UI **hint section** (NOT in `meta.md`). The hint section is a separate Shipd field — the unhinted meta.md stays as-is. Diamond Checks runs the unhinted prompt one round and the hint-augmented prompt a second round; both must satisfy their thresholds.
2. **Test cheaply first** — run 1-2 Castor with the hint before committing 10. If the hint doesn't move pass rate at all, the hint is wrong; iterate before burning tokens.
3. **Complete 10 hinted runs total** when the 1-2 test looks promising.
4. **Pass threshold:** no fixed minimum (admin Leonard: "as long as some amount passes"). **Ceiling sanity:** if all 10 pass, the unhinted meta is probably too ambiguous or leaking too little — re-examine.

**Hint quality rules (admin Leonard 2026-05-28 — stricter than legacy rules):**

- A hint is **valid** when a human expert with access only to the description (and the repo) could have inferred it. The hint just makes the implicit explicit.
- A hint is **invalid** when it leaks implementation details — helper names the solver wouldn't know, algorithm steps, file paths to touch, test-side facts.
- **Library/version specifics are fair game** (e.g. "Use the `go/constant` package's strict folding") because they're behaviorally observable, not implementation prescriptions.
- **Each hint MUST include a "why inferrable" justification** — one or two sentences pointing to the spec text or repo evidence the hint follows from. Without justification, the hint reads as a leak and gets rejected.

**Examples that pass admin policy:**
- Re-stating implicit universals: "The `Constraint` field is populated for every `Kind`, including mismatched_types." Inferrable because description names the field and enumerates the Kinds; the hint just makes the universal explicit.
- Naming a loose helper in the repo to bypass: "Representability is Go-spec strict, not yaegi's loose `assignableTo`." Inferrable because spec says "Go-spec strict" and `assignableTo` is visible in `interp/type.go`.

**Examples that fail admin policy:**
- "Add `dispatchConstraintFailure(interp, err)` at cfg.go:1024 and cfg.go:1189." Names exact call sites and helper — implementation leak.
- "Use `go/constant.MakeFromLiteral` to fold the untyped constant before constraint check." Names exact library function — implementation prescription.

**QA after hinted batch (admin Leonard 2026-05-28 — REDUCED):**

- **Unhinted runs:** full failure-QA per run + success-QA on passing runs (standard pre-policy behavior).
- **Hinted runs:** success-QA ONLY. No failure-QA required on hinted-run failures. Saves several hours of QA writing.
- **Final QA artifact set:** 10 unhinted (mixed failure + success QA) + 10 hinted (success QA only).

**Staleness on hinted Diamond Checks:** any edit to the hint text stales only the hinted half of the pipeline. Unhinted Castor runs + unhinted failure-QA remain valid. See `DIAMOND-PLAYBOOK.md § hinted-staleness` if applicable.

### Hint Authoring Discipline — Top-Down Pruning (saves Castor tokens)

Avoid iteration ping-pong (add hint → too much info / pass rate spike → strip → too little / pass rate drop → re-add). Use **top-down pruning** to land the hint in ONE 10x Castor batch:

**Step 1: Read 3-4 top failing runs.**
- Find the EXACT failure point in each trajectory
- Note which test failed + the wrong code the agent shipped
- Identify cascading failures: agents who failed early hid downstream traps

**Step 2: Analyze why other agents couldn't reach this stage.**
- Some failures cascade: agent A fails at step 2, never sees step 5 trap that catches agent B
- Hints often unlock agents PAST initial blocker, exposing 1-2 downstream traps that were invisible before
- Map the failure tree: which traps are upstream gates, which are downstream consequences

**Step 3: Draft MAXIMUM hint (over-spec'd, guaranteed pass).**
- Include every disambiguation that would make 8-10/10 pass
- Use clear behavioral language: "X happens when Y, NOT Z"
- This is your ceiling reference — you know this hint passes

**Step 4: Map hint items to meta.md description.**
- For each hint sentence, find the meta.md sentence it derives from
- If meta.md already implies it → mark as removable
- If meta.md is silent but agent could infer from repo → mark as removable
- If meta.md is silent + repo doesn't help → KEEP in hint

**Step 5: Prune ONE-BY-ONE.**
- Remove the most-obviously-derivable hint sentence first
- Test cheaply (1 Castor) — confirm hint still passes the targeted agent
- If pass rate drops → put it back, try next candidate
- Continue until hint is minimal-non-ambiguous

**Step 6: Run 10-batch.**
- With pruned hint, run 10 hinted Castor + Diamond Checks once
- Single batch hits target — no second iteration round needed

**Why this beats trial-and-error:**
- Standard trial-and-error: add hint → 10x run → too easy → strip → 10x → too hard → re-add (3 rounds × 250 tokens = 750 wasted)
- Top-down pruning: max hint sketch (free) → prune (~5x 1-Castor probes = 125 tokens) → final 10x (250 tokens) = 375 total, single calibration pass
- Saves ~50% of token budget on hinted runs

**Pruning anti-patterns:**
- Removing the trap-disambiguation sentence (the one matching Section 1 trap category) → pass rate collapses
- Removing the spec-bridge sentence (the one linking meta.md to the test's expected value) → ambiguity returns
- Removing multiple at once → can't tell which was load-bearing

### Step 6: Holistic AI Review (Sanity Check)

Run Holistic AI Review as a sanity check before Auto Review.

### Step 7: Auto Review → "Approved for QA" Badge

Run **Auto Review**. If approved → submission gets **"approved for QA" badge** → proceed to QA artifacts step.

**Reviewer green-light is GONE.** Diamond Auto Review now gates QA work.

### Step 8: Add QA Artifacts (Failure QA Step)

After "approved for QA" badge, start adding QA artifacts (test-groups.md + failure-qa.md + per-passing-run platform UI annotations).

**Critical staleness note:** at THIS step, you can iterate safely on QA artifacts using **Final QA Review** WITHOUT staling Castor runs / Diamond Checks / Auto Review. See § Staleness Rules below.

> **⛔ ABSOLUTELY NO AI IN FAILURE QA.** Must be written entirely by you, in your own words. Leadership monitors. AI-generated failure analysis = immediate rejection.

### Step 9: Submit for Reviewer Pass

When QA done, submit. Reviewer picks up, reviews each check + QA artifacts as final pass. From here similar to normal submissions.

### Step 10: Final Run-Through + Accept

When reviewer approves, team member does one last run-through to finalize. **Accepted! 🚀**

---

## Staleness Rules (CRITICAL — Plan Iteration Order)

Each step's checks become stale if edits are made — must re-run. Plan to fix everything from earlier checks BEFORE moving forward.

**Diamond Checks stale on changes to:**
- description
- test patch
- solution patch
- dockerfile
- github repo / commit hash

**Hint changes:** stale only HINTED Diamond Checks (similar to hinted Castor runs).

**QA artifacts stale only if Castor runs were staled.** Means: once at QA step, can iterate QA artifacts freely with Final QA Review — no worry of invalidating Castor + Diamond Checks + Auto Review + Holistic AI Review.

**Practical implication:** examine ALL insights from prior checks (Castor evals + Diamond Checks + Auto Review + Holistic Review) and air-tight submission BEFORE entering QA step. Issues remedied later cost much more time than issues remedied earlier.

---

## Diamond Relaunch Changes (2026-05-13) Summary

1. **Diamond Checks preflight pipeline** — new automated check before reviewers see submission. 50 tokens / 30min-1hr.
2. **Reviewer green-light DEPRECATED** — Diamond Auto Review now gates QA.
3. **Discord channels GONE** — all feedback through Shipd.
4. **Castor pass-rate ceiling tightened: ≤30%** (was 1-5 of 10 = 10-50%). Aim for difficult but fair.
5. **Castor temporarily throttled to 25 tokens/run** (was 10x normal cost) — focuses dev attention on new Diamond Checks.
6. **Hinted submissions run pipeline twice** — once unhinted, once hinted.
7. **Diamond queue PRIORITY** — review turnaround minutes to few hours.
8. **Locked into Diamond tier** while in program → increased token drips + cap above normal Shipd users.
9. **Environment Description ≥300 chars REQUIRED** (effective ~2026-05-21) — submissions with under-spec env descriptions reject new problem runs. See § Environment Description below.

---

## Environment Description (NEW — effective ~2026-05-21)

Diamond submissions require an **Environment Description** field on Shipd UI explaining what the env teaches the model. Minimum 300 characters. Ideal: one paragraph.

### Required content (per Shipd ops 2026-05-14)

Cover THREE elements:
1. **What env teaches model** — domain + concept + concrete trap class
2. **What typical task looks like** — failing test fixed by scoped change
3. **How task setup works** — what successful vs failing trajectory looks like

### Template (copy + fill per submission)

```
[Repo description + domain]. [Concrete trap concept agent must master]. The task:
[behavior to fix] guided by [test mechanism]. A successful trajectory makes [target]
green with [scoping discipline]. A failing one looks almost right — [most-of-tests pass
indicator] — but trips on one thing: [specific blind spot, e.g., wraps wrong call in
transaction, adds over-broad lock breaking unrelated tests]. Teaches [generalized
lesson, e.g., scoping concurrency fixes narrowly].
```

### Approved example (Shipd-provided, 352 chars)

> "A FastAPI + Postgres inventory service with a race on stock reservation. The task: fix it so concurrent reservations can't oversell, guided by a failing pytest. A successful trajectory makes that test green with a fix scoped to that endpoint. A failing one looks almost right — most tests pass — but trips on one thing: wraps the wrong call in the transaction, or adds an over-broad lock breaking unrelated tests. Teaches scoping concurrency fixes narrowly."

352 chars, paragraph form, covers all 3 elements.

### Example for cliffy-command-aliases (style match, 460 chars)

> "A TypeScript CLI framework on Deno with deep command/subcommand inheritance for flag handling and globals. The task: add an alias rewriting layer that intercepts argv before subcommand detection, guided by a failing Deno test suite. A successful trajectory makes those tests green with state cleanly separated between local and inherited-global registries on every command. A failing one looks almost right -- most tests pass -- but trips on one thing: clearing local aliases wipes own-command globals, or expansion callbacks fire in the wrong order between locals and inherited globals. Teaches state separation when current and inherited scopes coexist on the same object."

### Style traits

| Trait | Detail |
|---|---|
| Length | ≥300 chars (hard); target 350-500 chars |
| Format | 1 paragraph, plain prose, no markdown |
| Voice | Human, present tense, no AI cadence |
| ASCII | Plain ASCII (Shipd UI text input); em-dashes acceptable here per Emily example but `--` substitute is safer |
| Coverage | 3 elements: (1) what env teaches, (2) typical task, (3) successful vs failing trajectory pattern |
| Trap callout | Failing-trajectory sentence names the SPECIFIC blind spot (state separation / pipeline ordering / boundary detection) using Section 1 trap category vocabulary |
| Closing | One-sentence generalized lesson ("Teaches X") |

### Enforcement

- Under 300 chars → Shipd UI marks `0/300 minimum characters` red
- From ~2026-05-21: under-spec env descriptions REJECT NEW PROBLEM RUNS (eval blocked until fixed)
- Existing submissions need retroactive update (see Emily's note 2026-05-14)
- Linkable doc allowed for elaboration (still need ≥300 chars in the field itself)

### Where this lives

Shipd submission UI → "Environment Description" section (DIAMOND badge). NOT a file in submission folder — entered directly on platform.

**Authoring rule:** draft env description at design time (after DESIGN.md, before submit). Paste into `feedback.md § Env Description` for source-of-truth tracking + paste into Shipd UI at submit.

---

## Failure QA Guide

### Purpose

The goal of Failure QA is to assess submissions for **fairness**. If an agent fails a test, that failure must reflect a genuine mistake by the agent — not an ambiguous or underspecified task description. The agent should be able to infer the correct behavior from the prompt and codebase alone.

**If you find that tests are unfair or underspecified during this process, you MUST fix the prompt or verifier and re-run the pipeline.**

### ⭐ Zeroth Step — read the gold-standards + rubric BEFORE drafting (cheapest iteration-saver)

Before writing a single QA line, open and skim:
- `diamond-problems/approved/cliffy-command-aliases/failure-qa.md` (8 groups, per-failed-test entries, `Correctness confidence` + `Issues:`)
- `diamond-problems/approved/dasel-csv-options/failure-qa.md` (22 groups, runs with 16 failed tests grouped, zero line numbers)
- the official Diamond-Tier Task Guide rubric (Success Solution Explanation / Test Summary with spec quotes + coverage statement / Success Trajectory with severity+category / Unfairness check that cites the test snippet / Root cause that cites the solution snippet)

Copy their exact structure on the first draft. The auto-validator gates identifier substance; the human reviewer additionally gates grouping fairness, per-test completeness, and tone -- neither approved example was reverse-engineered, they ARE the format. Matching them up front is what avoids both the validator round AND the reviewer change-request round.

### ⭐ Pre-submit step — the backticked-token grep gate (single highest-leverage QA check)

The auto-validator greps every backticked token LITERALLY against the artifacts and marks MIXED on any zero-match. Before uploading failure-qa.md, extract every `` `...` `` token and grep each against test.patch + the run's agent diff + the repo source; fix or de-backtick any miss. This one mechanical pass collapses the typical 4-6 validator rounds to ~1 (yaegi-const-representability, APPROVED 2026-06-06, burned ~6 rounds all on one missed-token class). Proven MIXED token classes to scan for: comparison/threshold flips (`len(d) >= 3` when source is `if len(d) < 3`), substituted args (`errors.Is(err, ErrConstantTruncated)` when the helper passes `errors.Is(err, sentinel)`), ellipsis-in-backtick (`complex(...)`, `[]complex128{...}`, `cfgErrorf("...", ...)`), fabricated call-results (`constant.BitLen(256)` is 9), wrong-file-hunk line refs (`fileA line N` for code in fileB's `diff --git` hunk). Two FALSE classes in Go table suites: parent-rollup conflation (a table PARENT fails as `<failure message="Failed"/>` with no body — do not claim "each renders message X") and stale-per-run data (author each block from THAT run's actual failing-test dump; group count = total - passing). Full taxonomy: `DIAMOND-PLAYBOOK.md § Section 5 rules 59-64`, `PATTERNS-ADVANCED.md § Pattern 52`. **Approval note:** trajectory-step citations are a quality-lift the reviewer welcomes ("can get more detailed with citations like trajectory steps. Acceptable") but are NOT required and do NOT override "no step narration in the root cause"; keep final-state root causes, add a Failure-Point-Analysis pivot only as supporting evidence.

### Three Required QA Annotations

Every Diamond submission must include these three top-level sections:

1. **Success Solution Explanation** — A high-level summary of the expected solution that a non-expert of the repo can understand.

2. **Test Summary** — Group the tests into similar tests. For each test group, explain what the group tests and where in the description the requirement is mentioned. Quote parts of the task description for this summary.

3. **Success Trajectory Analysis** (per passing run) — Explain why the implementation is correct, why it meets all requirements of the description, and does not cause regressions on existing behavior. Then, if the implementation passes all tests but is not correct and it is impossible to test this deterministically, provide a detailed explanation of the failure and why it is impossible to test.

### Platform UI: "Why It Works" Tab

For each **passing** Castor run, the platform shows a "Why it works" tab with a DIAMOND badge. You must fill in:

- **Text area**: Explain why this implementation is correct, would it pass a thorough code review by a repo expert, confirm the task requirements are met, no regressions, no bugs introduced. If tests pass but the implementation has a real issue (and it is impossible to write a test to catch it), add it below with severity and category.
- **Correctness confidence**: 1-5 scale (1 = low, 5 = high). Use 5 when the solution is fully correct. Use 3-4 when there are minor issues that do not affect test outcomes. Use 1-2 when the solution has real bugs that tests cannot catch.
- **Issues**: "Tests pass but the implementation is wrong." Add each issue with severity and category. Severity 4+ is blocking. Leave empty if the implementation is fully correct.

### What to Analyze for Failing Runs

For **every test failure** on **every agent run**, provide two analyses:

#### 1. Unfairness Check

Validate that the failure was due to genuine suboptimal agent behavior instead of ambiguous requirements. Ask yourself: **"Would a seasoned engineer in this codebase have NOT made this same error?"**

You must:
- **Explicitly cite snippets from the prompt** (meta.md) that specify the requirement
- **Explain how the test case code correctly validates that requirement**
- If necessary, **cite conventions from the codebase** to explain inferred requirements/nuance that the test assumes

#### 2. Root Cause Analysis

Pinpoint **exactly where in the agent's trajectory** the error was made and classify the error type:
- Did the agent make an **incorrect assumption**?
- Did the agent **miss an inferrable edge case**?
- Did the agent implement a **wrong architecture** that couldn't support the requirement?

**Cite specific snippets of the agent's solution** to show the exact code that's wrong and why.

### Quality Standard

> **⚠️ IMPORTANT: Common failure mode to watch for.**
> 
> Requirements in the prompt that **contradict either (1) each other or (2) a strongly established codebase convention** can lead agents to follow convention over the prompt. If you notice these during analysis, you should:
> - **First try**: Fix the prompt/verifier to align with conventions
> - **If too difficult**: Use hints to prompt the behavior being tested

---

### Bad vs Good Failure QA

**❌ BAD Response (will be rejected):**

> **Unfairness check:** This is an explicit requirement from the prompt "Zod formatter schemas require defaulted and linked attributes".
> 
> **Root cause analysis:** The readLink requirement did not make it into Zod formatter optionality, whereas readDefault did.

**Why it's bad:** No prompt citation, no test code reference, no codebase convention analysis. Generic and could have been written by AI without reading the trajectory.

---

**✅ GOOD Response (what reviewers expect):**

> **Unfairness check:** The test case is fair, since it validates a requirement explicitly specified in the prompt "Zod formatter schemas require defaulted and linked attributes". While the exact setup in the tests
> ```
> +      label: string()
> +        .optional()
> +        .readLink<typeof schema>(({ pk }) => pk + '-label')
> ```
> seems a bit contradictory, i.e., requiring a seemingly "optional" field to also be required, it is evident from the repo that the `.optional()` modifier here describes optionality of the field's value in the database (in other words, optional on write), while the `readLink` modifier obviously applies to reads. ZodFormatter, and formatters in general, have the role of parsing objects during read, so this behavior of "optional during write" / "required during read" is conventional and consistent.
> 
> **Root cause analysis:** Essentially, the agent handled the `readDefault` case properly but not the `readLink` case. In `src/schema/actions/zodSchemer/formatter/utils.ts`, the agent extended `withOptional` to check `schema.props.readDefault` and, when it's a static value, return `zodSchema.default(readDefault)` (this also happens to be incorrect logic, since thunk values should also be handled the same). However, it never added a check for `schema.props.readLink`, so when only `readLink` is present, the schema gets wrapped in `z.optional()`, i.e., does not become a required field.

**Why it's good:** Cites specific test code, references repo conventions (write vs read optionality), explains the codebase context (ZodFormatter's role), pinpoints exact file and function where the error occurred, explains what the agent did vs what it should have done.

---

## Failure QA Checklist

For each submission, verify the top-level annotations exist:

- [ ] **Success Solution Explanation** — high-level summary of the expected solution a non-expert can understand
- [ ] **Test Summary** — tests grouped by category with description quotes for each group
- [ ] **Success Trajectory Analysis** — per passing Castor run: why implementation is correct, meets requirements, no regressions
- [ ] **Correctness confidence** — 1-5 scale per passing run (5 = fully correct, 4+ = no blocking issues)
- [ ] **Issues (if any)** — per passing run: if tests pass but implementation is wrong, list issues with severity (4+ is blocking) and category
- [ ] **"Passes but not correct" analysis** — if a passing implementation has a real bug that cannot be tested deterministically, explain the failure and why it cannot be tested

For each test failure on each agent run, verify:

- [ ] **Prompt citation** — exact quote from meta.md that specifies the tested behavior
- [ ] **Test code reference** — show the relevant test assertion/setup
- [ ] **Codebase convention** — if the test relies on inferred behavior, cite the convention
- [ ] **Trajectory pinpoint** — exact point in trajectory where the error was introduced
- [ ] **Error classification** — incorrect assumption, missed edge case, or wrong architecture
- [ ] **Solution snippet** — cite the agent's actual code that's wrong
- [ ] **Fairness verdict** — explicitly state whether the failure is fair or unfair
- [ ] **Action if unfair** — if unfair, describe the fix (prompt update, verifier update, or hint)

---

## File Organization for Diamond Tasks

Diamond tasks produce the standard 5 deliverables PLUS additional Diamond-specific artifacts:

```
diamond-problems/{name}/
├── BASE_COMMIT.txt          # Exact commit hash
├── meta.md                  # Problem description (WHAT)
├── test.patch               # test.sh + new tests
├── solution.patch           # Source-only changes
├── Dockerfile               # Environment setup
├── solution-approach.md     # **DIAMOND REQUIRED — HIGH-LEVEL summary (non-expert; public surface only, no internal helpers)**
├── test-groups.md           # **DIAMOND REQUIRED — Behavioral test groupings**
├── failure-qa.md            # **DIAMOND REQUIRED — Failure QA analysis (per-run)**
├── feedback.md              # Iteration tracking (local)
└── eval-results.md          # Per-agent eval data (local)
```

Plus on Shipd UI (NOT files in folder):
- **Environment Description** ≥300 chars (see § Environment Description)
- Per-passing-run "Why it works" + Correctness confidence + Issues
- Per-failing-run Unfairness check + Root cause

> **Upload note:** Only the 5 standard deliverables (`BASE_COMMIT.txt`, `meta.md`, `test.patch`, `solution.patch`, `Dockerfile`) are uploaded as patch files. `solution-approach.md`, `test-groups.md`, `failure-qa.md` content gets pasted into corresponding Shipd UI sections. `feedback.md` + `eval-results.md` are local-only tracking.

### solution-approach.md Structure (Diamond required)

**Purpose:** a HIGH-LEVEL summary of the expected solution that a non-expert of the repo can understand. It is context for reading solution.patch, NOT a line-by-line implementation walkthrough. The old "implementation walkthrough / step-by-step algorithm" framing here was WRONG and was reject-cause on scriggo-generics (reviewer 2026-06: "your solution approach explanation is still too low level design ... the requirement is a high-level summary ... explain it at a high level that a non-expert of the repo can understand ... you've got internal helper names also listed").

**What to name vs NEVER name:**
- NAME only the public / observable surface. Library feature -> public API methods + error classes (cliffy: `addAlias`, `globalAddAlias`, `RecursiveAliasError`). Language / compiler-internal feature -> the user-visible syntax + error conditions (scriggo: `Id[T any]`, `Box[int]{V: 5}`, "a bare generic name is an undefined identifier"). Stage names (parser, type checker, emitter) are fine.
- NEVER name internal private helpers, even though they are the bulk of the diff (scriggo reject set: `checkType`, `DefinedOf`, `substituteExpr`, `IndexList`, `bracketStartsTypeParameters`, `registerGenericTemplate`). NEVER cite file paths or line numbers. NEVER discuss the test substrings here (that belongs to the tests, not the solution).
- STATE the high-level strategy in plain words (scriggo: "monomorphization = make one concrete copy per set of type arguments, run each through the existing compiler stages") AND the property that separates a correct solution from a plausible-but-wrong one (scriggo: concrete real types vs a catch-all `any` that passes value tests but fails type/kind tests). That contrast is the most useful single sentence for a reviewer.

**Style traits (from the two approved shapes):**
- Length 200-500 words; 1 dense paragraph (cliffy) up to 3 short paragraphs (scriggo). Plain prose, no `##` headers, no bullets, ASCII, human voice (no AI cadence, no em-dash).
- A behavioral summary, NOT a teaching essay and NOT a diff narration. Describe what the solution does in terms of observable behavior, not how each helper is wired.
- Close with: the behavior is the requirement; the named approach is the reference; any implementation delivering the same behavior is valid.

**Calibrate against BOTH approved shapes (pick by feature type):**
- Library feature WITH a public API surface -> `diamond-problems/approved/cliffy-command-aliases/solution-approach.md` (1 dense paragraph; names public methods + error classes; that IS its observable surface, so it reads denser).
- Compiler / language feature with NO public API (the new code is all internal) -> `diamond-problems/scriggo-generics/solution-approach.md` (3 paragraphs; names only the user-visible syntax + behavior + strategy; ZERO internal helpers, paths, or line refs). Use this shape for any interpreter / compiler / type-system pick.

### test-groups.md Structure

Group all tests into behavioral categories. For each group, list the test names, explain what the group tests, and quote the relevant description requirement. This document serves dual purposes: (1) it feeds directly into the "Test Summary" section of failure-qa.md, and (2) it helps identify which test groups are acting as difficulty drivers vs which are universally passed.

```markdown
## Group N: {category name} ({count} tests)

{list of test function names}

These test: "{quoted description requirement}". {Brief explanation of what the
tests verify and why the group is fair.}
```

After each eval run, annotate which groups had failures and at what rate. This surfaces the true difficulty drivers (e.g., WriteNullValueHandling at 45.5% pass rate vs ReadSeparatorOptions at 100%).

### failure-qa.md Structure

```markdown
# Failure QA: {problem-name}

## Success Solution Explanation
[High-level summary of the expected solution that a non-expert can understand.
Must be understandable by a non-expert of the repo.]

## Test Summary
[Inline every group with a one-line description + a verbatim spec quote:
**Group N: title (M tests).** What it tests. From the description: "<quote>".
Close with a coverage statement: "every requirement in the prompt is tested by
at least one group", mapping each prompt requirement to its group(s).]

## Castor #{N}: PASS ({Y}/{Y} tests passed)

### Success Trajectory Analysis
[Explain why the implementation is correct, why it meets all requirements
of the description, and does not cause regressions on existing behavior.
High-level, name methods/fields, NO diff-step narration.]

Correctness confidence: {1-5}

Issues:
[If tests pass but implementation is wrong and impossible to test
deterministically, explain the failure, why it cannot be tested,
and assign severity (4+ is blocking) and category (correctness / design /
extensibility / readability / instruction following).
Leave as "No issues noted." if implementation is fully correct.]

---

## Castor #{N}: FAIL ({X}/{Y} tests passed)

### Failed Tests {A-B}/{X}: {cluster name}
[For a cluster whose tests have DISTINCT calls/values, map each test so every
exact assertion is auditable, THEN one shared root cause below. Only cluster
tests that share the same junit error class -- split different signatures.]

| Test | Call | Expected | Actual |
|---|---|---|---|
| {test_name} | {call expr from failing-test.md} | {expected value/kind} | {verbatim junit error} |

Unfairness check: Fair. {How the assertion helper validates it -- runOK/runErrIs/
runOKKind -- } The description states: "{verbatim prompt quote}". {Why a seasoned
engineer infers it.}

Root cause: {Named solution construct + the behavioral defect, NO agent-diff line
numbers.} Type of error: {incorrect assumption | missed requirement | wrong architecture}.
```

> When a cluster's tests share BOTH root cause AND assertion shape (e.g. dasel's 16 null-write tests), the simpler `### Failed Tests 1-3/5: TestA, TestB, TestC` heading + one Expected/Actual + one root cause is correct. Use the per-test table only when the calls/values differ (rules 28-29).

**Post-eval failure-QA rules proven on scriggo-generics (2026-06, validator + reviewer arc — internalize before drafting):**

1. **Root cause = artifact-grounded, NOT mechanism-speculation.** The validator marks a root cause FALSE/MIXED when you assert "the agent's code does not handle X" but the agent's diff actually HAS X-handling code (the bug is subtle within it). scriggo examples that failed validation: "substitution does not rewrite the composite in a `:=` left-hand context" (the source had it on the RIGHT; the agent had composite + assignment substitution) and "the for-range append leaves an unsubstituted node" (the agent had ForRange handling). Write what is OBSERVABLE instead: the verbatim error/panic, plus "the concrete equivalent (`b := Box[int]{V: 5}`) checks cleanly in passing runs, so the defect is in how this agent specializes it." Describe the symptom + that a correct specialization would not produce it; do NOT claim a specific missing line the diff contradicts.

2. **Helper-chain claims must name the function that actually does the work.** "`runGenericsOut` builds and runs each program" validated FALSE because `runGenericsOut` only loops and delegates; the real `Build`/`Run` live in a downstream helper (`genericsOut`). Name the real callee. Same class as Pattern 38 (predicate vs caller).

3. **Citation exactness.** Backtick the identifier exactly as it appears in code (`cas.Expressions`, not `Case.Expressions`); use the real format string (`cannot use generic %s without instantiation`, not a placeholder `X`); per-run claims must match THAT run's diff — agents differ (one touches the emitter, another uses a pre-check expand pass) so a phrase true for one run is false for another. Do not reuse a block verbatim across runs without re-checking each diff.

4. **Cascade runs (a panic inflates the JUnit fail count): split, do NOT collapse.** Do not write one repeated paragraph over all N failed entries. Split into: (a) one box per REAL failure (its leaf subtest + verbatim error/panic + its parent group row, since the parent failed because the child did), and (b) one box for the synthetic remainder — tests sequenced after the panic that never executed and are reported by the exact marker `new tests were missing from the JUnit XML (exit code 1)`. Put parent rows of real failures in the REAL boxes (they executed); only genuinely-post-panic entries go in the cascade box. Never say "did not execute" for a test that ran. Every box, including the cascade box, gets its own Root cause + Type of error (cascade box: "none of its own; synthetic post-panic, fixing the test-N panic lets them run").

5. **Multi-signature runs: re-verify the UI annotation testName buckets.** When a run fails two distinct signatures (e.g. pointer-parse AND bare-name), the failure-qa.md prose can be correct while the Shipd UI annotation groups have their testName lists CROSSED (the pointer test filed under the bare-name explanation and vice versa). The reviewer WILL catch this. After entering a multi-signature run, expand each UI group and confirm every testName matches its explanation 1:1 (E/K error tests under the undefined box, J/L position tests under the pointer box). One explanation box per signature.

6. **Attribute fairness quotes to "the description"** (never "meta.md" / "the prompt" / a workspace filename). ASCII only, no em-dash.

---

## Diamond-Tier Evaluation Criteria

All standard Olympus criteria apply, plus:

| Criterion | Requirement |
|-----------|-------------|
| Castor runs | ≥10 total |
| Pass rate | ≤30% = 1-3 of 10 Castor runs (near-0 → hint flow) |
| Failure QA | Completed for every test failure on every run |
| QA quality | Human-written, with citations and pinpointed analysis |
| No AI in QA | Absolutely no AI-generated text in Failure QA |
| Hints (if needed) | After an unhinted 10-Castor batch lands 0/10 and Step 5a confirms the failures are fair |

---

## Common Diamond-Tier Pitfalls

### 1. AI-Generated Failure QA
Leadership monitors Failure QA for AI usage. Generic statements like "The test checks behavior X and the agent didn't implement it" are flagged. Write in your own voice with specific, technical analysis.

### 2. Skipping Unfair Failures
If during analysis you discover a test is genuinely unfair (ambiguous prompt, contradicts convention), you **must** fix it and re-run. Do NOT paper over unfairness with a good-sounding justification.

### 3. Not Enough Castor Runs
The minimum is 10 Castor runs. Don't submit with only 8 or 9 — the reviewer will send it back.

### 4. Too Many Passes
If 6+ agents pass, the problem isn't hard enough. Harden tests or expand scope before submitting.

### 5. Shallow Root Cause Analysis
"The agent didn't implement X" is not a root cause. You must pinpoint WHERE in the trajectory the error was introduced, whether it was an assumption or oversight, and cite the agent's actual code.

### 6. Bash Shell Death in Castor Runs (Go Projects)
Castor agents using `cat > file.go << 'GOEOF'` heredoc patterns frequently enter infinite bash restart loops (50-350 wasted turns). These runs never pass but still count toward your 10-run minimum. If 2-3 of your 10 runs die to bash hangs, you may need 13+ total runs to get 10 usable ones. Budget for this when planning Castor token spend.

### 7. Near-Miss Runs (159/160) Without Root Cause Diversity
If multiple runs fail on only 1-2 tests each but with the SAME root cause, the problem may have a single difficulty chokepoint. Reviewers prefer problems with 3-4 distinct failure clusters. If all failures cluster on one test, consider whether that test is genuinely behavioral or just a gotcha.

### 8. Forgetting test-groups.md
The "Test Summary" section in failure-qa.md must group tests by behavior and cite description requirements. Writing this directly into failure-qa.md without first organizing in test-groups.md leads to inconsistent groupings and missed citation gaps. Create test-groups.md first, then copy into failure-qa.md.

### 9. Malformed JUnit XML from unescaped test names (verify with a parser, NOT grep)
A custom awk/sed JUnit synthesizer that emits a test name raw into `name="..."` breaks the file when a base subtest name contains `"` `<` `>` or `&`. yaegi's base suite has `TestIssue1623/pkg.S_=_"bar"`; the embedded quote made the platform's real XML parser reject the baseline run ("not well-formed"), failing Verify Tests AND Verify Solution. Local `grep -c '<testcase'` counted lines fine and hid it. Fix: an `xmlesc` awk function escaping `& < > "` at every PASS/FAIL/SKIP emit site. ALWAYS validate test.sh JUnit output with `xml.etree`/`xmllint`, never grep. (yaegi-unreachable-code 2026-06-03.)

### 10. Generic root cause that does not name the agent's own per-run helper
"The panic-call check matches by name" reads as interchangeable AI text. Per the DIAMOND.md GOOD example, each failing block names THAT run's actual construct read from its diff: `caseBodyTerminates`/`clauseBodyTerminates`/`switchTerminates`-with-`continue` for the fallthrough miss; free `isPanicCall` vs `isPanicCallExpr` on `unreachableAnalyzer` vs `isPanicCall` on `unreachableWalker` for the panic miss; plus the verbatim wrong literal `fn.kind == identExpr && fn.ident == bltnPanic` (present in each diff), with the fix-side constant `bltnSym` named as a repo identifier (not a literal the failing agent never wrote). Validator returned TRUE for every claim across all 10 runs in one pass. Per-run code differs — read each diff, never reuse one root cause.

---

## Diamond-Tier vs Standard Quick Reference

### Same as Standard
- All 5 deliverables (same format, same rules)
- WHAT not HOW in descriptions
- Comments match the repo convention (default NONE — not a blanket ban)
- **≥450 EFFECTIVE LOC DESIGN FLOOR (Olympus + Diamond)** — 400 = platform auto-block; auto-review triggers below. Formula = raw added − blank − comment-only (braces KEPT, comments NOT counted; cel-go `575−48−160=367`)
- test.sh with JUnit XML output
- test-description alignment
- Pre-checks and post-checks
- Bypass justifications for failing checks

### Diamond-Only
- Diamond label enabled
- Castor runs (not Vega/Orion/Nova for eval)
- Vega runs for environment validation only
- 10+ Castor runs required
- ≤30% pass ceiling = 1-3 of 10 Castor (post 2026-05-13; near-0 routes to the hint flow)
- Failure QA for every test failure
- No AI in Failure QA
- Hints flow: 10 → 20 → hint + 10 more
- $500 USD per approved submission
- Priority review
- Early access to newest project

---

## Tips for Diamond Success

1. **Validate environment with Vega first** -- don't waste expensive Castor tokens on infrastructure bugs
2. **Write Failure QA as you go** -- analyze each run immediately after results come in, don't batch all analysis at the end
3. **Be brutally honest in unfairness checks** -- if a failure IS unfair, own it and fix it. Reviewers respect honesty over spin
4. **Cite specific code** -- both from your prompt/tests and from the agent's trajectory. Vague analysis = rejection
5. **Track patterns across runs** -- if multiple agents fail the same test, check if the test is genuinely fair or if the description needs a tweak
6. **Use eval-results.md for pattern detection** -- Diamond tasks generate rich agent behavioral data. Use it
7. **Don't rush the QA** -- Failure QA is the main quality gate. Spend time on thorough, human-written analysis
8. **Target the ≤30% pass sweet spot (1-3 of 10)** -- too easy (4+) wastes runs; too hard (0) triggers the hints flow
9. **Force cross-package edits** -- single-package problems have median ~60 msgs. Cross-package requirements (CLI validation + parsing) boost median to 100-150 msgs, meeting the long-horizon threshold
10. **Design symmetric read/write traps** -- if the feature has both a read path and a write path, agents consistently implement the read side correctly but miss the write-side symmetry. This is the single most reliable difficulty pattern for data-format problems (confirmed across 30+ Castor runs on dasel-csv-options)
11. **Use reflection/introspection tests for thoroughness** -- tests that inspect struct tags, method sets, or type metadata across multiple files catch agents who update one file but miss others with the same pattern. These are fair (the description says "update commands" plural) and effective (4/11 agents miss the second file)
12. **Budget 13+ Castor runs for Go projects** -- bash heredoc death kills 2-3 runs per 10. Plan to submit 13 runs to get 10+ usable ones
13. **Track test group pass rates** -- after each eval run, compute per-group pass rates. Groups at 100% are fair baseline. Groups at 40-70% are your difficulty drivers. Groups at 0% may be unfair. This data goes into the AI reviewer checklist and helps justify fairness

---

## Lessons Learned from Reviewer Feedback

### QA auto-validator — anchor on PER-RUN observables (csstree-calc-typecheck, approved 2026-06-05; 3rd confirmation of Pattern 44/45/49)

The failure-qa.md auto-validator greps each run's OWN agent diff + junit + test_patch and returns true/mixed/false per claim. Five proven MIXED/FALSE triggers (full prose: `PATTERNS-ADVANCED § Pattern 50`). csstree took 3 validator rounds (~10 mixed/false -> 3 -> 1 -> 0) to reach all-true across 11 runs:
1. **Baseline count = the PLATFORM junit number, not the local runner.** csstree: local mocha 16725, grading `junit_baseline_xml tests="4000"` -> cite 4000.
2. **No per-agent MECHANISM claims.** "gate not routed back" / "`<number>` in the accepted set" / "rejects a wrong dimension" are false for the runs that don't do that. Write the junit Actual + the behavior shared by EVERY run in the group.
3. **Align failure blocks to the platform grouping handed to you in the response `testNames` arrays** (only 1 of 11 csstree runs diverged; re-cluster that one with a both-manifestations root cause).
4. **Quote backticked CALLS verbatim from test source** — `comparePriority(ast, 'b', 'a')` (variable), not `comparePriority(parse(...), 'b', 'a')` (inline) when the test used a variable.
5. **Soften absolutes** ("the only failing choice" -> "a node that is neither ... fails the assertion").

**Junit quirk (cite verbatim):** `assert.ok(falsy)` in csstree renders as `Attempted to read a non-own property` (the repo `lib/__tests/helpers/setup.js` prototype-pollution guard fires while Node builds the assert message), NOT `false == true`. Use that exact string as the Actual for offending-node / missing-error / instanceof misses.

### Solvable signal — the 3-rollout fluke (csstree-calc-typecheck)

The Diamond Checks preflight runs only 3 rollouts. csstree's preflight returned avg 0.66 with a lone **1.00** that looked solvable; a rigorous **10x Castor returned 0/10**. **A single high rollout in a 3-batch is noise — run >=10 before trusting "solvable" or deciding a problem is too easy.** See `PATTERNS-ADVANCED § Pattern 51` (measure-before-trapping).

### Writing Style — ALL Diamond text artifacts (elevated from failure-QA-only, 2026-05-14)

The rules below originally applied to `failure-qa.md` only. Reviewers now flag them across **all submission-bound text**: meta.md, env description, failure-qa.md, solution-approach.md, test-groups.md, feedback.md sections on Shipd UI. See `DIAMOND-PLAYBOOK.md § Section 6.4` for full guard commands + ASCII check tooling.

### Failure QA Writing Style (confirmed across 6 reviewer rounds on cliffy-command-aliases + 1 round on dasel-csv-options)

1. **No trajectory step references** -- never write "At step 21, the agent..." or "At step 30, the agent wrote...". Reviewers flag this as AI-generated. Instead, describe what the agent did generically: "The agent stored both locals and globals in one shared map."

2. **No cross-run comparisons** -- never write "Same bug as Castor #1" or "Same architectural mistake as #3." Each run's QA must be self-contained and independent. The reviewer explicitly said: "don't mention other runs, let's keep it independent."

3. **Verify every factual claim** -- wrong line numbers, wrong alias chains, wrong method call paths will get flagged. Before writing the QA, check the actual test code to confirm:
   - The exact assertion being tested
   - The exact setup (what aliases/objects are created)
   - The exact call path that triggers the failure

4. **Keep it concise** -- avoid verbose multi-paragraph analyses. Each failure should be: unfairness check (2-3 sentences with prompt citation), root cause (2-3 sentences with code reference). No code blocks unless strictly necessary.

5. **Plain ASCII, no dashes** -- no em dashes, no `--`, no Unicode arrows or special characters in QA prose. Use colons or natural sentence breaks instead. `--` in prose is an AI tell that reviewers catch.

6. **No fix suggestions** -- unless you have verified the fix would actually resolve the specific failing test path. The reviewer flagged "incomplete fix suggestion" when the described fix didn't match the actual failure path.

7. **Every entry needs concrete expected-vs-actual** -- don't write "wiping all entries" or "destroying everything." Write "Expected: registry.has('b') === true. Actual: false." The reviewer called this "audit-grade expected-vs-actual."

8. **Separate spec text from inference** -- when a failure depends on a chain of reasoning (spec says X, therefore Y must hold), frame Y explicitly as an inference: "This is an inference from the API: the test expects own-command globals to be included, not just parent-inherited ones." Don't present inferences as if the spec says them outright.

9. **Describe final code state only** -- never write "after encountering test failures, the agent patched four methods" or "was overlooked." That's trajectory-sequence language. Write "In the final code, getAliasRegistry() collects globals only from parent commands." The submission evaluates the final code, not the development sequence.

10. **If you mention trajectory steps, verify them** -- the first reviewer said "if you mention agent steps from the trajectory, just make sure your claims are accurate and that the step number is correct." If you can't verify, don't mention steps at all.

11. **Don't fabricate variable names** -- never invent names like `_aliasRegistry._local` or `_getInheritedGlobalAliases()` without verifying them in the agent's actual code. Describe behavior instead: "used a single shared map", "stored separately", "registry construction code only collects from parents."

12. **Inference framing must be consistent** -- if one entry frames a point as inference ("this is an inference from the API design"), every entry about the same point must also frame it as inference. Inconsistency gets flagged.

13. **Cancellation cases: lead with observed failure** -- for cancellation/ordering tests, state the concrete observed output first ("The expansion result includes `b` in the chain"), then only describe the likely cause if you've verified that exact control flow from the final code.

14. **Each entry must stand alone** -- don't write "By the same inference as above" or "Same root cause as test 1." If a reader looks at only one entry, they must get the full picture: test setup, what was expected, what happened, and why.

15. **Use public API names, not generic phrases** -- write "clearRegisteredAliases() clears that entire map" not "the clear method removes all entries." Use the actual method, class, and variable names from the tests and task description.

### Failure QA Writing Style -- Additional Rules (confirmed on dasel-csv-options Diamond, 10 Castor runs analyzed)

16. **Group related test failures in one entry** -- when 3-5 tests fail from the same root cause (e.g., TestWriteStrictRaggedRowsError, TestWriteStrictHeaderFalseRaggedError, TestWriteStrictNullRaggedError all from the same iteration bug), write one combined entry with all test names in the heading rather than repeating the same root cause analysis 3-5 times. Example heading: "Failed Tests 1-3/5: TestWriteStrictRaggedRowsError, TestWriteStrictHeaderFalseRaggedError, TestWriteStrictNullRaggedError". **CAVEAT (yaegi reviewer change-request, see rules 28-29):** grouping is correct ONLY when the grouped tests share both the same root cause AND the same assertion shape (dasel's 16 null-write tests all assert the same "model null -> csv-null string" outcome). When each test has a DISTINCT call/value/kind, you must still map each one (per-test `| Test | Call | Expected | Actual |` table) under the shared root cause -- a single broad example is "over-collapse" and gets change-requested. And NEVER group two tests under one Expected/Actual unless they emit the same junit error class.

17. **Describe the structural mechanism, not just the symptom** -- for dead-code bugs, explain WHY the check never fires. "The writer iterates over the headers slice for every row, so the encoded values slice always has the same length as headers. The strict check compares these two identical lengths." This is more useful to reviewers than "The strict check doesn't detect extra columns."

18. **Pipeline ordering bugs need before/after framing** -- when the root cause is "X happens before Y but should happen after Y," explicitly state: (1) what the correct ordering is per the description, (2) which two operations are swapped in the agent's code, (3) what concrete value passes through incorrectly. Example: "The strict newline check runs on the pre-substitution empty string instead of the post-substitution null string 'line1\nline2'. The check should run after null substitution per the pipeline ordering in the description."

19. **Null/empty string behaviors need explicit expected-vs-actual values** -- when the root cause involves null-to-string conversion, always state the literal strings. "Expected output field: 'NA'. Actual output field: '' (empty string)." Reviewers cannot evaluate correctness without seeing the literal values.

20. **Cross-file thoroughness failures are fair if the description uses plural** -- when the description says "update commands" (plural) and the agent updates one command file but not another, the unfairness check is simple: quote the plural word and note both files. No inference framing needed because the spec explicitly uses plural.

### Failure QA Writing Style -- Validator-Substance Rules (yaegi-generic-constraint-fidelity R-current, 81-test arc, 10 Castor analyzed against the auto-validator)

**Core principle:** the auto-validator earns a `true` verdict by grepping the NAMED identifiers you cite and matching the behavior to the code -- it locates lines itself. Line numbers are optional scaffolding, not the gate. The approved cliffy failure-qa carries zero line numbers and passed both the validator and the human reviewer. Ground every claim on three NAMES: the agent helper (what), the repo mechanism by function name (why), the verbatim error string (symptom). What triggers MIXED is imprecision, not missing line numbers:

21. **A multi-line code fragment can't be one backticked literal.** The validator literal-greps the token. `` `if it.untyped { def = defaultedItype(it, nil) }` `` was MIXED because the diff splits it across three lines. Describe the behavior and name the function (`defaultedItype`), or cite the per-line pieces separately. Never paste a composed multi-line block as one backticked string.
22. **No placeholder tokens.** `` `untyped X does not implement main.Y` `` is MIXED -- cite a concrete instance that appears verbatim (`untyped float does not implement main.OrderedX`).
23. **No truncated strings.** `` `operator == ...` `` is MIXED -- quote the full string `invalid operation: operator == not defined on main.ASX`. A real `%s` format string is the exception (that IS the source literal).
24. **Claim only the mechanism the diff shows.** Saying a value "is derived from a named-interface identifier" when the diff merely passes `""` at the call site is MIXED. State the empty-string argument you can see, not an inferred derivation.
25. **Don't claim "hidden suite untouched" OR a blanket "no test-file hunks" without reading the diff headers.** "Hidden suite untouched" is unverifiable from the agent patch. "No test-file hunks" is false when the agent adds its own in-repo test file -- S#9 added `interp/constraint_test.go` and went MIXED; S#7 had none and was fine. State only the confined paths the diff shows AND name any in-repo test file the agent added.
26. **Mirror the symptom string junit renders.** junit shows `errors.Is(err, type is not comparable)` (the sentinel's `.Error()` text), not the Go identifier `ErrNotComparable`. Quote what junit prints; name the identifier separately in prose.
27. **Enumerate every failing test; count must equal (total - passing).** Ranges like "15-21/22" and "representative" lists undercount. A 22-fail run names 22 tests. Verify the per-section count after writing.

**Tone correction (supersedes any "begin every paragraph with 'In the final code'" guidance):** use present-tense final-state framing, but do NOT mechanically repeat "In the final code, the agent..." as every opener -- that repetition is itself an AI tell. The approved cliffy QA varies openers and several drop the prefix entirely. Match its shape: 2-3 short declarative sentences, named method, cause then effect, no inline citation spam.

### Failure QA Writing Style -- Reviewer-Judgment Rules (yaegi-generic-constraint-fidelity reviewer change-request round, QA-only)

These six are NOT validator-flaggable (the auto-validator checks identifier substance, not grouping fairness or per-test completeness) -- they are human-reviewer judgment. The cheap fix is the **Zeroth Rule: read both approved diamonds + the official rubric BEFORE drafting** (see Failure QA Guide below).

28. **Group only same-signature, same-shape tests; map each test when assertions differ.** Rule 16 grouping holds when the cluster shares the same assertion shape. When each test has a distinct call/value/kind (`MinX(2*1.5, 1.0)` -> `1.0` vs `DoubleX(3.5)` -> `7.0`/`Float64` vs `WideX(3.14, 2.71)` -> `2.71`), map each with a per-test `| Test | Call | Expected | Actual |` row, then write the shared root cause once below. A single broad example for 14 distinct tests is "over-collapse" and gets change-requested.
29. **Never group two tests under one Expected/Actual unless they emit the same junit error class.** The S#10 miss: four promotion-cascade tests (failing `untyped float does not implement main.X`) were lumped under a typed-pin Expected/Actual (`157/50 truncated to int64`) -- wrong expected, wrong actual, wrong root cause for all four. A cascade failure is a different signature from a typed-pin truncation even when adjacent in the run; split into separate blocks with separate root causes.
30. **Pull every call/value/kind/error from the run's ground-truth `Castors/S#N/failing-test.md`, not memory.** The reviewer caught `char_lit...` written as `MinRuneX('a','b')` when the test calls `MinRuneX('m','a')`, and a missing `reflect.Int32` assertion. Copy the call, expected value, kind assertion, and error string from the actual junit + test body. Memory swaps literals across near-identical tests.
31. **Strip agent-diff line numbers; keep only stable base-repo anchors.** `(diff line 491)` points into the agent's per-run diff, which the validator cannot grep and the reviewer reads as fabricated. Both approved diamonds carry zero line numbers. Name the construct (`the matchDefault || assignableTo disjunct`, `newConstraintError with an empty constraint argument`). Greppable base-repo anchors (`interp/type.go:1466`) are acceptable in a header sentence and reused, but lean on names.
32. **Test Summary inlines every group with a verbatim spec quote and a closing coverage statement.** Both approved diamonds inline the grouped summary in failure-qa.md (`**Group N: title (M tests).** ... From the description: "<quote>"`) and the rubric requires a closing line confirming every prompt requirement maps to at least one group. test-groups.md stays the detailed companion and must carry NO cross-run stats ("R12 cluster: 6/10 fail" -> remove). **Attribute quotes to "the description"** (platform name for the task text), NEVER "quoted from meta.md" / "from the prompt" / any local filename -- that is a recurring agent mistake and is not acceptable. No local workspace filename (meta.md, test.patch, solution.patch, Castors/, sol-dif.md) appears anywhere in the artifact; use platform-facing terms (the description, the tests, the agent's submission, the reference solution).
33. **Unfairness check names the test's assertion mechanism, not only the spec quote.** Rubric: "explain how the test case code correctly validates that requirement." After the verbatim quote, state the helper and what it checks (`runErrIs` asserts `errors.Is(..., ErrMismatchedTypes)`; `runOKKind` asserts the value AND its `reflect.Kind`). **Two MIXED traps here (yaegi re-run):** (a) when a cluster's tests use DIFFERENT helpers, name each -- do not generalize `runErrIs` across a test that uses `runStructuredErr` + manual `errors.Is`; (b) a fairness rationale asserting an external fact the validator cannot grep (e.g. "compiles under `gc`" -- `gc` is absent from test_patch) must be framed interpretively ("a seasoned engineer would expect...") or dropped.
34. **Value-anchored line numbers are MIXED bait; never cross-attribute the passing tests inside a failing block.** (yaegi re-run #2.) (a) A line number presented AS the locator for a field/string value (`` `str` is `"untyped float"`, `interp/type.go:160` ``) goes MIXED when off-by-one (it's `:161`), and the validator is non-deterministic on these (S#4's identical `:160` passed the same round S#5's failed). Delete value-anchored line numbers -- write `name: "int32"`, `str: "untyped rune"` with no number. Behavior-anchored line numbers (cited beside a named function whose behavior the validator matches, e.g. `assignableTo (interp/type.go:1466)`) are tolerated; quote a field value with a line number ONLY if you read that exact line this session. (b) In a FAILING block, explain only why THOSE tests fail -- do not credit a named branch (`def.equals(c)`) with the OTHER (passing) tests' success; per-agent code differs and that cross-test causal claim is usually unverifiable. Ground the block on its own failure mechanism (`equals` compares `id()`, which returns `str`; the rune `str` is `"untyped rune"`, so the match is false).

### Failure QA Writing Style -- Grouping-Binding Rules (41-47, yaegi-channel-diagnostics arc, approved 2026-05-31)

These are validator-flaggable. The auto-validator binds each claim to the PLATFORM's behavioral grouping of the failing tests, so blocks must align to that grouping.

41. The validator binds each claim to the PLATFORM's behavioral grouping (the test-file group, e.g. by name prefix non-Cross vs Cross), NOT to your symptom split. Align failure-qa blocks to that grouping. Never regroup blocks along a symptom axis (genuine-deadlock vs false-positive) that cuts across the platform's groups -- even when a reviewer asks to "split" them. Keep the behavioral-group block; split the symptoms INSIDE it (prose + Expected column).
42. A whole-group claim ("each of these builds a genuine deadlock") must be true for EVERY test the platform binds to that block. If the group is symptom-mixed, write a both-manifestations claim ("this group holds both manifestations: X tests do A, Y tests do B"), never a single-symptom sweep.
43. Per-run agent code differs -- a mechanism verified TRUE for one run can be FALSE for another with the same junit symptom. State only what THAT run's diff supports; fall back to verified-predicate + junit-observable when the causal timing is not in the diff.
44. A bare backticked repo identifier the validator must grep (e.g. `rangeChan`) is grep-variance-prone: TRUE in some runs, MIXED in others. Anchor path-miss / range-miss claims on the agent's own recording helper + the behavior + the junit symptom, not a standalone repo function name.
45. Cite the helper that HOLDS the logic (the switch arm), not a wrapper that delegates to it (e.g. recordChanOp delegates to recordChanOpBlocked -- name the latter for the Recvs++ arm). No struct-literal tokens (`GoID: 0`) the diff does not literally contain.
46. In a fairness check, do not enumerate scenario examples that belong to OTHER tests in the run. Keep the rationale generic to the contract, or name only members of THIS bound group.
47. Stale-verdict guard: before re-editing on a FALSE/MIXED verdict, grep the flagged strings in the CURRENT file. A verdict can score a pre-edit upload; if the flagged text is already gone, the verdict is stale on those claims (re-upload, do not re-edit).

Track record: yaegi-channel-diagnostics approved 2026-05-31 (reviewer "gtg"), hinted 1/10, QA converged in 6 validator rounds -- source of rules 41-47. Env Description rework: 2-3 sentences, no `#` title, neutral not recipe. Also: test-groups.md grouping must match a test's ACTUAL assertions, not its name/adjacency (EnableRecordsEvents reads off-state by name but asserts enabled recording -- reviewer caught the mis-group). Env Description + failure-qa.md + test-groups.md are QA-tier (do not stale Castor / Diamond Checks / Auto Review); both QA artifacts are platform-uploaded.

Track record: yaegi-generic-constraint-fidelity approved 2026-05-31 (reviewer "gtg. qa is now factually correct"), unhinted 3/10, QA converged in 4 QA-only rounds (1 reviewer change-request + 3 validator) -- source of rules 28-34. **Second yaegi Diamond to converge independently on the same QA discipline as channel-diagnostics** (validator-vs-reviewer two-gate, value-anchored line numbers banned, per-run agent code differs, platform-naming, grouping bound to behavior not name) -> these rules are 2x-confirmed and stable. Headline: **QA is graded on per-test factual correctness and has its OWN approval gate** -- this sub cleared solvability + Holistic + Auto Review days before approval; only QA factual accuracy remained. The 4 QA-only rounds were avoidable by the Zeroth Step (read cliffy + dasel + rubric, copy their shape, before drafting). Sharpest single rule (34): strip VALUE-anchored line numbers (locator for a field value -> MIXED off-by-one, validator non-deterministic on it), keep BEHAVIOR-anchored ones (beside a named function). Core difficulty engine reusable across Diamonds: go/constant strict representability vs the interpreter's loose `assignableTo`.

Track record: yaegi-unreachable-code approved 2026-06-03 (reviewer 6/7, "no concrete concern found"), unhinted 2/10 Castor (20%), QA validator returned TRUE for every claim across all 10 runs in ONE pass (no validator round). **Third yaegi Diamond**; source of the two new Castor traps (DIAMOND-PLAYBOOK § Section 1 #17 builtin-shadow name-vs-symbol 6/10, #18 language-spec-exception carve-out 4/10) and three cross-cutting lessons. (1) **Similarity is a concept axis, not a GitHub-namespace check** — the closure-introspection predecessor was Pattern-22-GREEN yet scored 0.81 vs an older same-repo capture-introspection problem; pivoting the concept axis (control-flow reachability vs data-flow capture) cleared it at 0.683 (PATTERNS-ADVANCED § Pattern 46). (2) **An external test package importing the API by exact type turns an under-specified return type into a whole-file compile-collapse** — pin the value-vs-pointer slice and string-vs-struct field shapes in meta as spec-completion (Pattern 47); 4/5 -> 2/10 after the pin. (3) **Validate JUnit XML with a parser, never grep** — an unescaped `"` in a base subtest name broke the baseline XML; `xmlesc` the awk emit sites. The one-pass validator result came from naming each run's OWN helper from its diff (Pitfall 10), proving the diff-grounding discipline transfers. Approved at 459 effective LOC, which relaxed the user's Diamond floor from 500 to 450 (still above the 400 platform auto-review floor) — genuine terminating-statement difficulty carried it.

---

## Difficulty Design Patterns for Diamond (Confirmed Across 2 Diamond Submissions, 23 Castor Runs)

### Pattern 1: Symmetric Read/Write Traps
When a feature has both a read path and a write path, design tests that verify the write-side implements the same transformations as the read-side. Agents consistently implement the read side correctly but miss the write-side symmetry. In dasel-csv-options, this was the #1 difficulty driver (5-6/12 failures per run across 30+ runs). The trap works because agents correctly handle csv-null on read (string to model null) but fail to implement the reverse mapping on write (model null to csv-null string through full quoting/escaping/trim pipeline).

### Pattern 2: Dead-Code Check Patterns
Design scenarios where the obvious correctness check is structurally impossible to trigger. In dasel-csv-options, agents iterate over headers to build values, making `len(values) == len(headers)` always true. The correct approach requires a separate query (row.MapKeys()) to get the actual key count. This pattern caught 5/11 Diamond Castor agents. Look for situations where a loop-derived variable is compared against the loop bounds.

### Pattern 3: Cross-Package Integration Requirements
Require agents to touch 2+ packages with tests in both. This is the strongest message-count lever: single-package problems average ~60 msgs, cross-package problems average ~141 msgs. In dasel-csv-options, adding 7 CLI integration tests in internal/cli/ (separate from the 153 tests in parsing/csv/) forced agents to navigate both packages, read both codebases, and wire validation between them.

### Pattern 4: Reflection/Introspection-Based Thoroughness Tests
Use language-level reflection to verify that ALL instances of a pattern were updated, not just the first one found. In dasel-csv-options, TestCLIHelpTextReferencesSeparatorNotDelimiter uses Go reflection to inspect struct tags on both QueryCmd and InteractiveCmd. This caught 4/11 agents who updated query.go but missed interactive.go. The pattern generalizes: any test that inspects type metadata, struct tags, or method sets across multiple types catches incomplete grep patterns.

### Pattern 5: Pipeline Ordering Traps
When multiple transformations must occur in a specific order (trim, then null-substitute, then validate, then quote), design tests that are sensitive to the ordering. Agents who implement transformations as separate early-return branches always get the ordering wrong. In dasel-csv-options, trim-before-null vs trim-after-null tripped 3/11 agents, and strict-before-null-substitution tripped 1/11. The correct pattern is: substitute first, then pass through the same pipeline as regular values.

### Pattern 6: Same-Object Interaction Tests (from cliffy-command-aliases)
Agents always test parent-child inheritance but never the same-command case. Design at least one test per feature that exercises the same-object edge case (e.g., global and local aliases on the SAME command, clear locals, check global survives). This caught 8/8 failing runs (100%) across 3 different architectural variants.

## cel-go-strict-dyn (APPROVED 2026-06-17) - pipeline + escalation notes

- Auto Review can FALSE-block a genuinely-required change whose every offered remedy is unsafe. Here a harness-determinism fix (proto.String() subtest rename for p2p NAME stability) was flagged "prior_feedback_ignored"; Auto Review tested the WRONG justification (JUnit-XML validity, not p2p name determinism) and offered only drop-it (reintroduces an eval-corrupting flake on EVERY run) or keep-it (its block). RESOLUTION: escalate to admin with the Verify-Solution evidence + the cleaner automated check (Holistic) that already cleared it ("only stabilizes subtest names, not behavioral"). Admin overrode -> approved. Don't thrash or silently remove.
- QA artifact set for a 0-unhinted Diamond: 10 unhinted (failure-QA per fail, success-QA for the rare pass) + the hinted PASS run(s) (success-QA only; failing hinted runs need NO failure-QA). cel-go shipped 1 success + 10 failure blocks.
- STALENESS confirmed: test.patch / solution.patch / meta / Dockerfile edits stale the FULL pipeline (unhinted + hinted Castor + Diamond Checks + Auto Review + Holistic), NOT just the hinted half. A hint-only edit stales only the hinted half. QA-only edits (failure-qa / test-groups / solution-approach / env-description) stale NOTHING - iterate freely.
- Run BOTH optional pre-submit checks fresh before submit: Verify Solution caught the reintroduced p2p flake; Test Fairness caught a brittle empty-report negative-substring assertion.

## yaegi-methodset-enforcement (APPROVED 2026-06-23) - pipeline + grader-mechanics gates

4th yaegi Diamond, ZERO-new-API spec-conformance moat. Two PLATFORM-MECHANICS gates that block PASS before any difficulty question, both learned the hard way:

- **The grader applies your test patch OVER the agent's mutated working tree (test files are NOT restored to base first).** A test patch that MODIFIES an existing repo test file (here interp_eval_test.go) collides with the agent's own edits to that file -> `git apply patch.diff` fails (`... patch does not apply`, "failed to create QA version", Diamond Checks crash). FIX: test patch ADDITIVE-ONLY (new file, random hex suffix); if the feature would flip an existing repo test, re-scope the SOLUTION to preserve that documented behavior (we kept #1149/#1150 ptr-method-on-composite-literal legal via a shared `isCompositeLit` carve-out and asserted it additively).
- **The grader runs plain `go test` and does NOT pass your custom `-tags`.** A build tag used to gate the f2p file means that file is never compiled in the grader's base/new runs, so the f2p set "passes" on base -> Env Linter BLOCKING for inverted reward ("f2p 47/43-pass"). FIX: no build tag; isolate base by prefix mismatch (curated base list excludes `^Test<Name><hex>`) + a BASE_RUN var; new run = `-run ^TestMethodSet<hex>`.
- **Hint calibration:** short directional prose (match approved hint files), NOT an enumerated checklist; hint only the dominant near-miss and pair reject+accept halves co-equally (over-stressing one reject half regressed its accept twin). Landed 2/10 hinted (~20% Hard).
- **Success-QA + Describe-Tests get a SEPARATE human pass after the auto-grader is fully green.** Auto-grader marked all 12 runs "true"; the human reviewer still caught 4 factual errors (group/describe tests by BODY not name; a PASS run can be spec-wrong on an untested corner -> note it + lower confidence + issue-type Correctness). Budget a human-review round even when the validator is clean.

## typify-object-applicators (APPROVED Diamond 2026-06-25) - QA-validator + reviewer mechanics

The failure-qa auto-validator greps the NAMED identifiers you cite and matches described behavior to code, returning true/MIXED/false per claim. Confirmed behavior:

- TRUE-reliable: interpretive fairness ("a seasoned engineer would expect..."), type-of-error classification, verbatim description quotes.
- MIXED/FALSE classes (each cost a round): ASSERTION-LOCATION (claiming a helper asserts when the assert is in the test body); PIPELINE-TIMING (panic "during to_stream" when it fires in `add_root_schema`); VERBATIM-TOKEN (a CONSTRUCTED call like `get_type_name(Name::Unknown, None).unwrap()` is ungreppable -> cite the repo-exact `get_type_name(&type_name, metadata).unwrap()` + describe args in prose); PER-RUN-CODE-DIFFERS (same junit symptom, different cause per agent); GROUPING-BINDING (platform binds a lone generation test into the map cluster -> one merged block, per-test table, both-manifestation root cause); PER-AGENT-HELPER (don't cite a helper a specific agent's diff doesn't contain - grep=0 -> MIXED).
- After validator all-true, a HUMAN reviewer still catches: a plausible-but-wrong mechanism, a solution-approach naming functions that don't exist in solution.patch, a success-block selling an over-accepting fallback as a feature, a false asymmetry, imprecise test-summary counts. Budget 3 QA rounds.
- Hinted-run QA = success-QA only; final set = 10 unhinted (failure+success QA) + the hinted pass (success QA). QA-only edits do NOT stale Castor/Diamond Checks.
