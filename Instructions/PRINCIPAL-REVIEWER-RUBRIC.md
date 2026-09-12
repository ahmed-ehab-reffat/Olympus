# Principal Reviewer Rubric — 10 Blockers (Source of Truth)

The principal reviewer's own consolidated blocker list. **Highest-authority source** — these are the exact things that block submissions at final human review, ranked by frequency. Every other instruction file paraphrases or expands on these; this file is the verbatim canonical reference.

Apply at every tier (Mars / Olympus / Diamond / Lite). Pre-submit, walk all 10.

---

## 1. Problem description must sound natural

**The single most common blocker.** Your description needs to read like you're talking to a developer, not writing a spec or a document.

- Concise, only mentions what's needed; don't mention discoverable details
- No AI slop
- Not prescriptive, unless implementation details are genuinely needed
- No weird titles or specific sections like "test assumptions", etc; we need a natural prompt
- **Don't use code instead of words.** Don't write `(float64)`, `(len==LatencyWindowSize)`, JSON `"adaptiveThrottling,omitempty"`, or `"Current rate: %.2f"` inline. Say "the rate is a decimal number" or "once the window is full" or "a JSON config option named adaptiveThrottling that can be omitted" or "print the current rate with two decimal places". Don't write code snippets instead of plain English (e.g. `model.update()` and `model.delete()` should... vs "Model updates and deletes should...")
- A natural prompt won't start by talking about the repo as if it were something external (e.g. "Langchain currently supports xyz, but abc is lacking...")
- A natural prompt won't be a list of requests or snappy instructions; it should have a natural flow to the requested behavior you want

→ Full ruleset: `DESCRIPTION.md § Human-Voice + ASCII Rules` + `§ Tone & Framing`.

## 2. JUnit XML must work even when things crash

The platform depends on the XML file for all per-test analysis. If builds fail or tests crash and no XML appears, that's a blocker.

- Use the framework's built-in reporter: `pytest --junitxml`, `go-junit-report`, `jest-junit`, `vitest --reporter=junit`
- **Don't roll your own XML generation with custom scripts.** They silently miss build failures and produce misleading all-pass results.
- **Test it locally by deliberately breaking the build** and checking if the XML still appears with the failure recorded.

→ Build-failure fallback details: `TESTS.md § JUnit XML Crash Resilience` + `lessons-learned § test.sh MUST produce JUnit XML`.

## 3. Every test needs meaningful assertions

A test that calls a function without checking anything is useless. **If a no-op implementation would pass the test, the test isn't doing its job.**

- Watch for weak assertions: `assert True`, `assert len(x) > 0`, loose regex that matches unrelated output
- Every assertion should verify a specific expected outcome

→ `TESTS.md § Assertion Style` + `lessons-learned § weak assertions`.

## 4. If agents keep failing on the same thing, it's a prompt issue

When all agents make the same "mistake", it usually means the behavior isn't clearly stated or inferable. If your tests enforce something that isn't explicit in the description and isn't an obvious codebase convention, agents follow a different reasonable interpretation and fail.

**Includes testing the unstated inverse of a rule.** If the description says "X happens when Y is not configured," you can't also test "X must NOT happen when Y IS configured" unless you state that too. The inverse isn't automatically implied — a solver could reasonably combine both.

For every test assertion, point to the exact sentence in the description OR an obvious codebase pattern that requires that behavior. Pay special attention to **return types, container types, and formatting details.**

→ `DESCRIPTION.md § Blind-Spot Pre-Empt Sentence Bank` + `PLAYBOOK § Pattern 8 Bucket 1`. Diagnose with `DIAMOND-PLAYBOOK § Failure-Point Analysis Procedure`.

## 5. Tests should check behavior, not implementation details

Make sure a different but correct implementation would still pass your tests. If your test asserts on specific SQL queries, mock call counts, or internal data structures, it's too coupled to one approach. **Test what the code does (data outcomes, observable behavior), not how it does it.**

→ `TESTS.md § Test Design` + `RULES` item 11.

## 6. Watch for correlated blind spots between solution and tests

If your solution and your tests both independently miss the same requirement, no test catches the gap. **The only way to find this is tracing each requirement in the description to BOTH the implementation AND at least one test.** Don't just check "do tests pass". Check "do tests cover everything the problem asks for".

**Requirement-coverage matrix (build this before submit):**

| Description requirement | Solution code (file:func) | Test that exercises it |
|---|---|---|
| <each behavioral ask> | <where implemented> | <which test> |

Any row with a blank test column = correlated blind spot. Add a test. Any row where solution AND test are both vague = the requirement isn't really enforced.

## 7. Every feature wired end-to-end, tested through the real entry point

If the description says something is a CLI flag, API endpoint, or config option, the solution must hook it up through the **real entry point** AND the tests must exercise it through that entry point.

- Don't test internal constructors or bypass the framework when the feature is user-facing
- CLI flag → test via the CLI invocation, not by calling the internal handler
- Config option → test by loading config, not by setting the struct field directly
- API endpoint → test through the route, not the controller method

→ Cross-package integration: `KNOWLEDGE § MANDATORY Cross-Package` + `SOLUTION § Modified vs New Files`.

## 8. Test exclusions need real reasons

If `test.sh` excludes pre-existing test files from base mode, **each exclusion needs a genuine reason** like "needs a browser that's not in the Docker image" or "needs network access".

- Don't skip base tests in areas your solution touches
- Running them can surface issues in your solution that your new tests don't catch, or reveal that your new tests aren't covering what they should
- Document each exclusion inline in test.sh with its reason

→ `TESTS.md § test.sh Structure` (base mode runs ALL existing tests).

## 9. Think about what happens to difficulty when you fix things

When you clarify an ambiguous requirement, **estimate how many previously-failing runs would now pass.** If fixing the ambiguity would push your success rate above 5/10, you need to add difficulty elsewhere to compensate.

→ `AGENTS.md § Difficulty Calibration` + `lessons-learned § Tighten-First Rule` + `DIAMOND-PLAYBOOK § Section 4 wasted-iteration patterns`.

## 10. Keep your patches clean

- `solution.patch` is ONLY solution code. `test.patch` is ONLY test code. If it's test code, it goes in the test patch — don't include tests in the solution patch.
- Only include changes required by the task. **No drive-by refactoring, no style changes in unrelated files, no dead code or unused infrastructure.**
- Review every file in your diff and remove anything not directly needed.

→ `RULES § Real Revert Causes` + `CLAUDE.md § Comments rule`.

---

## Pre-Submit Walk (do all 10)

```
[ ] 1. Read meta.md aloud — does it sound like a dev bug report, not a spec? No code-in-prose, no external framing, no section labels.
[ ] 2. Break the build locally — does JUnit XML still appear with the failure recorded? Built-in reporter, not custom script.
[ ] 3. Would a no-op impl pass any test? Any assert True / len>0 / loose regex? Strengthen.
[ ] 4. Every test assertion traces to an exact description sentence or obvious codebase convention? No unstated inverse.
[ ] 5. Would a different-but-correct implementation pass? No SQL/mock-count/internal-struct coupling.
[ ] 6. Requirement-coverage matrix built — every description requirement maps to BOTH solution code AND a test? No blank test columns.
[ ] 7. Every user-facing feature tested through its real entry point (CLI/API/config), not internal constructor?
[ ] 8. Every test.sh base-mode exclusion has a documented real reason? No skipping tests in areas the solution touches.
[ ] 9. Estimated post-fix pass rate ≤ 5/10? If a clarification pushed it higher, added compensating difficulty?
[ ] 10. solution.patch = source only, test.patch = test only. No drive-by, no dead code. Every diffed file needed.
```

---

## Addendum — Reviewer Clarifications (Elabyad, 2026-04-12)

Follow-up clarifications on points 2, 8, and 1. These OVERRIDE any conflicting paraphrase.

### On #2 (JUnit crash-resilience) — the "one run missing XML" signal

If ONE agent run gets "JUnit XML not found" but other runs have the XML correctly, **your test.sh doesn't handle crashes/failures correctly.** It's not the platform — it's your harness.

- Check the test log + that agent's solution: what did it do, why did the test phase fail to produce XML?
- **Add guards in test.sh** (capture exit codes, write a synthetic failure XML if the real one is absent) OR **try-catch blocks in the tests**, so that even on a build failure / crash / critical failure that stops tests from completing, the XML STILL gets generated.
- The XML must appear with the failure recorded, never just go missing. A missing XML = that agent's run is unscored = looks like a harness defect to the reviewer.

### On #8 (test exclusions) — NOT absolute, nuanced

Skipping base tests is allowed WITH a real reason. The rule is about WHY you skip, not whether you can.

- **Legit skip:** fixing a bug that the base tests were expecting (base tests asserted the old buggy behavior, so they now correctly fail). Modifying/skipping those is the right thing.
- **New behaviors/features:** make them opt-in instead of changing base behavior, so existing tests keep passing without modification.
- **Many cases have a better approach** that doesn't break existing functionality — reach for that first.
- **NEVER skip to hide regressions or solution issues.** If the solution has issues that are hidden and it still passes the tests, that means either the tests are not fully correct OR they're missing cases. The skip itself isn't the crime; using it to mask a broken solution is.

### On #1 (natural prompt) — fairness BEATS naturalness for interface details

When tests depend on specific public API names/signatures that are NEW, state them explicitly even if it makes the prose less natural.

- It's fine to state the explicit public API (method names, signatures) when it's something new and the tests expect those exact names.
- **If you get a FAIRNESS warning** (description missing interface details, OR tests expect something specific you're asserting) → **prioritize fairness over description naturalness. State the thing explicitly.** An unfair-but-natural prompt loses to a fair-but-slightly-less-natural one.
- **If the Description Quality check then flags that explicit detail** → work around it: phrase it to read as naturally as possible while STILL stating the interface detail. Don't drop the detail to satisfy Quality. (Leonard is aware the check over-flags this; a fix is planned. Until then, keep the detail, soften the wording.)

→ Mechanics of the Quality-vs-Alignment conflict: `DESCRIPTION.md § Navigating AI Checker Conflicts`.

---

## Why this file is the source of truth

These 10 (+ the addendum) are the principal reviewer's OWN consolidated blocker list — the final human gate before acceptance. Other instruction files expand individual points with evidence + recipes, but when a paraphrase conflicts with this file, **this file wins.** Update it only when the principal reviewer issues a new consolidated verdict or clarification.
