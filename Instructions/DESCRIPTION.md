# DESCRIPTION — How to Write meta.md

A description says **what** is broken or missing and **what** correct behavior should be. Never **how**.

> **Read first:** `PLAYBOOK.md` § Patterns 1, 11–13 — title format, body structure, blind-spot pre-empts, shape-aware writing patterns from 13 approved problems.

---

## ⚠️ REQUIRED — the YAML frontmatter block (write it FIRST, every meta.md)

**Every meta.md opens with a YAML frontmatter block, before the `#` title.** It carries the
submission metadata so it never has to be hunted for across `BASE_COMMIT.txt`, the worktree and
the repo page at submit time. This is the convention in the approved set
(`approved-problems/calyx-unused-port-elimination`, `neva-array-bypass-generalization`,
`pulldown-cmark-gfm-autolinks`; only the oldest, `lyon-arcs-join`, predates it).

```markdown
---
Repository: https://github.com/<owner>/<repo>
Issue: <full issue URL, or N/A when the feature is invented>
Commit: <40-char BASE_COMMIT hash>
Language: <Rust | Go | Python | TypeScript>
Category: <feature-request | enhancement>
Title: <same text as the H1 below>
---
# <same title again>

<body starts here>
```

Rules for the block:

- **`Commit` must equal `BASE_COMMIT.txt` byte for byte.** Copy it, never retype it. A mismatch
  sends reviewers to the wrong tree and invalidates every line reference in the review.
- **`Issue: N/A`** when the feature is invented rather than taken from a tracker (the common
  case — `RULES.md` says invent features, do not bind to an open issue). Put the full URL when
  an issue genuinely informed the scope.
- **`Category`** must match the honest category and the title's verb: Add/Implement/Support =
  `feature-request`; Fix/Handle/Rewrite/Extend-existing = `enhancement`. A mismatch is an
  automatic FAIL.
- **`Title`** duplicates the H1 deliberately — the platform surfaces them in different places.
  Keep the two in sync when either changes.
- The frontmatter is **metadata, not prose**: it is excluded from the body word budget, and the
  no-`##`-headers / plain-prose rules apply only to the body below it.

---

## The One Rule

A description is a **behavioral ask**: it says **what** is broken or missing and **what** the correct behavior should be. It never says **how** to implement it internally — that's the solver's job.

### WHAT-not-HOW: disclose the contract, withhold the algorithm

WHAT and HOW split along one line: the **output contract** is WHAT (always disclose it), the **algorithm** is HOW (always withhold it).

> **⭐ The meta-side hardening rules (Rule-7 de-enumeration, giveaway audit, fairness floor, novel-semantics rule floor) are consolidated in `HARDENING.md § 3b` with measured evidence** (enumerated walls = checklist → fundsp 90%; worked example handed the approach → scryer 80%; de-enumeration → symengine 100%→10%).

**Leanness is a DIFFICULTY lever, not only a fairness rule.** A description that carries only the required contract + the fairness minimum WIDENS the strong-vs-weak agent gap: strong agents still decode it and pass, weak agents hallucinate the unstated parts and fail, so the pass-rate band emerges. An over-prescriptive description does the opposite three ways at once — it LEAKS the approach (rubric P6), it COMPRESSES the gap so weak agents coast through on the spelled-out detail (too easy, blows the ≤30%/≤20% cap), and it draws conciseness flags. So the tightest FAIR description is also the HARDEST one. Cut every sentence that isn't a tested contract detail or a fairness necessity; state the principle + the canonical form and trust the agent to discover the rest.

- **Disclose the full output contract the hidden tests assert.** Exported names, signatures, schema keys, sort order, rounding mode, error/exception types, boundary inclusivity (`>` vs `>=`), NaN/empty/zero handling — pin every one a test depends on. A contract the tests assert but the description omits is a hidden requirement and reverts the problem.
- **Withhold the algorithm, the helper decomposition, and which files to touch.** The solver discovers traversal order, internal data structures, where the wiring lives, and how the feature factors into helpers. Naming any of these is solution-leaking.
- **Strip line-by-line narration.** "Notice: `X` passes through because the code does `Y`" hands over the implementation — a HOW leak even when phrased as an observation. State the observable result (`X` is returned unchanged), not the internal reason.
- **One anchor per non-obvious behavior, not a walkthrough.** Give exactly ONE input → output pair for each behavior a reader can't infer (traceability), then stop. A multi-step trace re-derives the algorithm and leaks HOW.
- **The spec must admit exactly ONE reading.** Pin every detail a test depends on so the discriminator is "the agent did not implement rollback" or "its solution OOMs on the large input", never "the agent missed an ambiguous sentence". Ambiguity = unfair difficulty; under-implementing a fully-pinned contract = fair difficulty.
- **Plausible distractor** is fair ONLY when an authoritative agent-visible source disconfirms it (a stale README/CHANGELOG the real code contradicts). See `olympus-common-mistakes.md`.

---

## Core Writing Principles

1. **Be concise** — only mention what's necessary; don't include discoverable details
2. **Avoid AI-generated prose** — write it yourself in natural language
3. **Avoid being prescriptive** — unless implementation details are required for fairness
4. **No titles or rigid sections** for simple/moderate problems — keep it natural and flowing (don't use "Test Assumptions:", "Agent Instructions:")
5. **Don't frame the prompt as if the repo is external** — don't start with "Langchain currently supports xyz, but lacks abc..." as if introducing the repo to a stranger
6. **Don't turn it into a list of requests** — should flow naturally like a developer reporting an issue
7. **Don't list discoverable repo details** — behavioral or implementation details that an agent can find by reading the code don't belong unless needed for fairness
8. **Don't use code snippets when plain English works** — write "Model updates and deletes should..." not "`model.update()` and `model.delete()` should...", unless exact shape or name is needed

---

## Format

Plain sentences, dash-bullets, backticks for code names. **No markdown headers, no formulaic labels, no numbered lists.**

```
# [Action-Oriented Title]

[Plain sentences. Backticks for `method names`, `API names`, `parameter names`. Dash-bullets for lists. No more sentences than the problem demands.]
```

| Allowed | Not allowed |
|---|---|
| Backticks for code/API names | Markdown headers (`##`, `###`) |
| Dash-bullets (`-`) for lists | Formulaic labels (`Problem Description:`, `Test Assumptions:`) |
| Plain paragraphs | Numbered lists |

One flowing paragraph (or 2-3 short paragraphs for complex features). For complex features with multiple distinct behaviors, structured sections like **Goal**, **Expected Behavior**, **Constraints** are acceptable — but the **proven approved pattern** is dash-delimited flat paragraphs:

```
# [Action-Oriented Title]

[Motivation sentence]. [Core feature]. - [Behavior 1 with params]. - [Behavior 2]. - [Error conditions]. - [Return values/API surface].
```

All 6 approved Olympus problems use this dash-delimited flat paragraph style — even at 400+ words, none use section headers. This is the safest format.

Do NOT split into formulaic sections like "Problem Description:", "Agent Instructions:", or "Test Assumptions:" — these feel artificial. Use natural structure (Goal/Behavior/Constraints) only when complexity truly demands it.

---

## meta.md File Format

**YAML frontmatter (Style B) is the standard/preferred format** — the platform reads `Repository` + `Language` from it to set up the eval environment. Style A (title-only) is a legacy fallback; prefer Style B for all new submissions.

### Style A: Title + Description Only
```markdown
# [Action-Oriented Title]

[Description paragraph(s)]
```

### Style B: YAML Frontmatter + Description
```markdown
---
Repository: https://github.com/{org}/{repo}
Issue: https://github.com/{org}/{repo}/issues/{number}
Commit: {base_commit_hash}
Language: {TypeScript|JavaScript|Go|Python|Rust|C++|Java}
Title: [Clear Title]
---
# Problem Description

[Description paragraph(s)]
```

For feature requests without a GitHub issue, use `Issue: N/A`.

---

## Title

- Starts with verb: Fix, Add, Implement, Extend, Iterate, Rewrite, Handle
- 5–10 words
- Names the specific subsystem

| Good | Bad |
|---|---|
| Fix pickling Exceptions with kw_only attributes | Bug fix for issue #1380 |
| Add task archive functionality | Feature request |
| Iterate Selector Simplification to a Fixpoint | How to better handle XYZ |
| Implement Iterator Helpers | Update the code to handle a new case |
| Handle cancellation ICS imports | |

---

## ⚠️ HARD RULE — The FIRST SENTENCE of the body must read as the feature request

**Reviewers are graded on the DESCRIPTION, not the title.** The title is often not shown next to
the description in the review UI, so a body that opens by narrating the current state reads as a
bug report or a status note, not as a request for work. Lead with the ask.

**Default opening shape:** `Add <capability> to <subsystem>.` Swap the verb to match the honest
category: `Add` / `Implement` / `Extend` / `Support` for feature-request, `Fix` / `Handle` /
`Rewrite` for enhancement. Then, and only then, state the current behaviour as the second
sentence.

| Good (opens with the ask) | Bad (opens with narration) |
|---|---|
| "Add the sibling combinators `+` and `~` to the CSS selector matcher used by element content handlers. All four are rejected as unsupported today." | "The CSS selector matcher rejects the sibling combinators `+` and `~`. Make them work." |
| "Extend the union type checker to report every conflicting member, not just the first." | "The union type checker stops at the first conflicting member." |
| "Fix reference adjustment so formulas survive a row insert that straddles the range." | "When a row is inserted inside a range, formula references are adjusted incorrectly." |

The bad column is not wrong on content — it says the same thing. It just makes the reviewer read
a sentence before learning what is being asked for, and the first sentence is what the
description is judged on.

Do NOT restate the title verbatim as the first sentence. The title is a 5-10 word label; the
opening sentence is a full request naming the capability AND the subsystem it lands in.

---

## ⚠️ HARD RULE — Named-standard features force a lose/lose between the two graders

Two graders pull in opposite directions and a NAMED-STANDARD feature cannot satisfy both:

- The **fairness / test-alignment** grader requires every tested behaviour to trace to a sentence.
- The **conciseness** grader deletes any sentence restating semantics the solver can already
  assume, and marks it HIGH priority.

When the feature is a named external standard (CSS combinators, a SQL clause, a language syntax
sugar, an RFC), its semantics ARE assumable, so every sentence pinning them reads as noise — while
omitting them leaves your tests unanchored. Measured on `rejected/lol-html-sibling-combinators`:
a 345-word meta.md written to the fairness floor drew `request_changes` with 5 deletions, 2 HIGH,
including the sibling-semantics block and the composition paragraph, both of which existed only to
anchor tests.

**The resolution is at PICK time, not at writing time.** Prefer a capability defined by the repo's
OWN model over one defined by an external standard:

- **Named-standard feature** — say the standard governs ("follows the standard CSS meaning") and
  state ONLY the deliberate divergences and the genuinely non-obvious edges (which content-less
  elements participate, what the error is). Do not restate the standard. Accept that you cannot
  build a trap on standard semantics, because you are not allowed the words to make it fair.
- **Invented / repo-specific capability** — state everything. Nothing is assumable, so the
  conciseness grader has nothing to delete, and the fairness grader is satisfied by the same
  sentences. This is the only shape where the two graders agree.

This is a second, independent reason to prefer invented capabilities over famous ones — the first
being that a famous unimplemented feature is a derivative MAGNET (see `TOO-EASY.md`
§ lol-html-sibling-combinators).

---

## Word Budget by Shape (Evidence-Based)

| Shape | Sweet spot | Approved median | Notes |
|---|---|---|---|
| **Mars A1** (distributed pipeline) | 100–110 | 107 | One paragraph + bullets |
| **Mars A2** (concentrated + sig change) | 130–145 | 137 | One paragraph, inline rules |
| **Mars B** (add new public API list) | 220–245 | 241 | 3 paragraphs naming 13+ funcs |
| **Mars C** (additive extension) | 85–100 | 91 | Short, dense rules @ ~10 words/rule |
| **Mars D-new** (new variant) | 140–160 | 148 | Multi-paragraph w/ API signature |
| **Mars D-change** (variant sig change) | 175–200 | 183 | 3 paragraphs: types, normalization, API |
| **Olympus** (any shape) | ≤150 | varies | AI checker enforces tighter trim |
| **Mars recommended cap** | — | **240** | Sweet spot ceiling (above this still allowed if dense API surface, see B at 241) |
| **Olympus recommended cap** | — | **200** | AI checker enforces tighter trim |
| **Hard cap (both tiers)** | — | **500** | Absolute limit. Above 500 = automatic fail. |

**Approved Mars range: 91–241 words** (median 137). The 241-word case (`pest-unused-rule-elim`, Shape B) got approved because every word names an API surface. Don't pad.

### Generic Complexity Tiers (Cross-Reference)

| Complexity | Target | Absolute Max |
|---|---|---|
| Simple bug | 20-40 words | 80 |
| Moderate bug/feature | 60-100 words | 150 |
| Complex feature | 100-200 words | 300 |
| API-heavy / spec-like feature | 200-450 words | ~450 |

The sweet spot is **70-120 words** for bugs, **150-250 words** for features. Complex features with significant API surface regularly reach 200-450 words in approved Olympus problems. Every sentence must add unique testable information — don't pad, but don't cut critical behavioral specs either.

### Rules (All Shapes)

- **First sentence of the body states the ask** (`Add <capability> to <subsystem>.`) — see the
  HARD RULE above. Reviewers grade the description, not the title.
- ≤4 paragraphs of plain prose
- ≤10 backticked names (API surface only — never internal types, struct fields, enum field signatures)
- 0 algorithm pseudocode
- 0 mentions of internal field names
- 0 "must" sentences about HOW (only WHAT)

Every sentence must add unique testable information.

---

## Shape-Specific Writing Patterns

**A1 (distributed pipeline modification)** — 1 paragraph + dash bullets. Lead with the pipeline change; bullet the rules. Example: lightningcss-selector-simplify-fixpoint (107 words).

**A2 (concentrated + signature change)** — 1 paragraph with inline rewrite rules numbered (1), (2), (3). Example: pest-factorizer-fixpoint packs 6 rewrite rules into one paragraph (137 words).

**B (add new public API list)** — 3 paragraphs. Name every public function explicitly (unused-rule-elim names 13).
- Para 1: WHAT is added (new types, enum variants, methods)
- Para 2: Behavior rules / normalization / output form
- Para 3: Edge cases or supplementary API

**C (additive extension)** — Short, dense. Each rule = one phrase (~10 words/rule). validator-hardening packs 9 distinct error classes into 91 words.

**D-new (new cross-crate variant)** — Multi-paragraph with explicit API signature. State forced trait bounds (e.g., `recover(primary, sync)` with `FnMut` bound). Example: pest-error-recovery (148 words).
- Para 1: New variant + payload + integration points
- Para 2: Behavior semantics
- Para 3: Edge cases + parallel optimized form

**D-change (cross-crate variant signature change)** — 3 paragraphs. Spell out canonical form (sort order, dedup strategy, range merging). Example: pest-extended-skip (183 words).
- Para 1: New variant shape (e.g., `Vec<SkipChoice>` replacing `Vec<&str>`)
- Para 2: Normalization / merge / dedup rules with sort order
- Para 3: Display formatting + supplementary API

---

## What TO Include

### 1. What is broken/missing + why it matters
State current wrong behavior and its consequence.

```
GOOD: "The convert plugin skips reconversion when the destination exists, even if the source was modified."
GOOD: "Completed tasks accumulate in workspaces with no way to hide them while preserving their history."
GOOD: "Response validation incorrectly rejects valid responses when using nested schemas."
```

### 2. Correct behavior (WHAT not HOW)
State what should happen, focusing on observable behavior.

```
GOOD: "The plugin should reconvert when the source file has been modified since the last conversion."
GOOD: "Ensure onAfterResponse hooks receive complete derived and resolved context for all request outcomes."
BAD:  "Modify the convert() function in beets/plugins/convert.py to compare os.path.getmtime() values."
```

**Mental model (community wisdom, Shipd Discord 2026-05-29):**
> "It should read like a problem report, NOT an implementation guide. Like telling your own AI: 'I have XYZ problem that you need to fix.' Give the results you need + some repo context. Don't give the steps."

If meta.md reads like a tutorial / step-by-step / "first do X, then Y, then Z" → you wrote a solution, not a problem. Rewrite as observable behavioral asks. The AGENT figures out the steps.

**Self-check:**
- Could a human dev hand this to a teammate without further explanation as a bug report or feature request? → GOOD
- Does it tell the reader which functions to modify, which files to touch, which algorithm to use? → BAD

### 3. Interface names WHEN NEEDED ("Test Assumptions")
Method signatures, option names, error types — but only when the solver needs them to match your tests. This is what the platform calls "Test Assumptions" — non-obvious interface details that tests require.

```
GOOD: "Add an ignored_cookies option on CachedSession, analogous to ignored_parameters."
GOOD: "Archive state should be exposed via Todo.is_archived and Todo.archived_at."
GOOD: "SetBreakpoint(funcIndex uint32, pc uint64) error — idempotent, accepts any funcIndex."
GOOD: "The parsing function parse_recurrence should be importable from dooit.utils.recurrence."
```

Interface names are NOT implementation details — they specify the public API the solver must implement.

**Fairness BEATS naturalness for interface details (Elabyad 2026-04-12).** When tests depend on specific NEW public API names/signatures, state them explicitly even if the prose reads slightly less natural:
- It is FINE to state explicit public API (method names, signatures) when it's new AND tests expect those exact names.
- **If you get a FAIRNESS warning** (description missing interface details, OR tests expect something specific you assert) → **prioritize fairness over naturalness. State it explicitly.** An unfair-but-natural prompt loses to a fair-but-slightly-less-natural one.
- **If the Description Quality check then flags that explicit detail** → work around it: phrase it to read as naturally as possible while STILL stating the interface detail. Do NOT drop the detail to satisfy Quality. (The check over-flags this; a platform fix is planned. Until then: keep the detail, soften the wording.)

**"Same as X" is not enough.**
```
BAD:  "provide the same find methods as browser.links"
GOOD: "provide find_by_id, find_by_css, find_by_tag, find_by_xpath"
```

**When to include Test Assumptions:**
- Only if multiple reasonable choices exist AND tests actually require a specific one
- Only if the detail is non-obvious (names, paths, function signatures, CLI flags, error shapes/codes)

**When NOT to include (anti-patterns):**
```
DON'T: Specify if obvious from context (a function to parse toml should be called
       parse_toml if there's already parse_json)
DON'T: Specify if similar existing code does it the same way (new fastapi endpoint
       should raise ResponseValidationError when field validation fails)
DON'T: Specify when there's one clear, idiomatic choice any reasonable dev would pick
DON'T: Describe interfaces literally when words suffice
  BAD:  "solution should implement function foo(input: A, settings: B): C in ./src/lib/foo.ts"
  GOOD: "add functionality to process A and B to produce C, must be called foo and importable from libs/foo.ts"
```

### 4. Error behaviors WHEN TESTED
If your tests verify specific error conditions, the description must mention them.

```
GOOD: "throws RangeError if negative"
GOOD: "Use ArchivedTodoError when writes are attempted on archived todos."
GOOD: "At least 2 arguments required."
```

If tests check specific error TYPES (`ETIMEDOUT`, `ECONNABORTED`), name them. Generic "timeout errors" is insufficient when tests assert specific names.

### 5. Edge case behaviors WHEN NON-OBVIOUS
Only include edge cases that aren't obvious from the problem itself.

```
GOOD: "For floats, if any argument is NaN, the result is NaN."
GOOD: "Empty xmlns attribute values clear inherited namespaces."
GOOD: "Calling Todo.archive() on an already archived todo must not change Todo.archived_at."
```

### 6. Canonical output form when tests use `assert_eq!` on structures
Sort order, associativity, dedup strategy.

```
GOOD: "Emit Choice subtrees in right-associated form."  (factorizer)
GOOD: "Order Literal values lexicographically, then CaseInsensitive values by ASCII lowercase, then CharRange values by start codepoint."  (extended-skip)
```

Without canonical-form spec, a correct solution that picks a different form fails tests and looks "unfair" in agent runs.

### 7. Blind-spot pre-empts
See sentence bank below.

---

## What NOT to Include

| Category | Reason |
|---|---|
| Implementation details (algorithms, data structures, internal approach) | Solver's job |
| Discoverable repo details (behavioral or implementation patterns visible in code) | Agent will find them |
| Obvious expectations ("maintain backward compatibility", "follow code style", "all tests must pass") | Always assumed |
| Markdown headers (`##`) or formulaic labels | Plain prose only |
| Test references ("The tests verify that…", "In test mode…") | State behavior directly |
| Vague language ("properly", "correctly", "as expected") | Use concrete behavior |
| Code examples (unless API surface) | Internal detail |
| `NOTE:`, `TODO:`, test mode references | Internal tooling |
| Step-by-step agent instructions | Hand-holding |
| Background narrative ("requested by the community…") | Filler |
| Bundled requirements in one sentence | Separate distinct behaviors |
| Undefined terms ("handle empty values properly") | Specify what counts as empty |
| Missing trigger context ("parser fails with certain inputs") | Specify the trigger |
| `Box<...>` type wrappers | Describe variant in prose |
| Code-instead-of-prose (`(float64)`, `model.update()`) | Plain English |
| External framing ("Pest is a parser library…") | Drop reader directly into the change |
| Restating default behavior (if library already does X by default) | Redundant |

### Anti-Pattern: Solution Leaking
Don't describe things in a way that maps directly to the implementation.

```
BAD:  "Add a check in the convert() function that compares file modification
       timestamps before skipping conversion."
GOOD: "The plugin should reconvert when the source file has been modified since
       the last conversion."
```

Multiple correct implementations should be possible — the description should be loose enough that different approaches can satisfy it.

### Anti-Pattern: Bundled Requirements
Don't combine multiple unrelated behaviors in one paragraph without clear separation.

```
BAD:  "Fix the parser to handle nested arrays and also add support for custom
       delimiters and update the error messages to be more descriptive."
GOOD: Separate distinct behaviors into separate sentences so each is independently testable.
```

### Anti-Pattern: Missing User Context
Always state what user action triggers the issue.

```
BAD:  "The parser fails with certain inputs."
GOOD: "When parsing a TOML file containing inline tables with trailing commas,
       the parser throws a SyntaxError instead of accepting the comma."
```

### Anti-Pattern: Option/Flag Precedence Not Stated
When multiple options interact, explicitly state which takes priority.

```
BAD:  "Add a force_synced option for synced lyrics."  (What if `force` is also set?)
GOOD: "Add a force_synced option. When both force and force_synced are set,
       force takes precedence."
```

### Anti-Pattern: Overlapping General + Specific Constraints (LLM Blind Spot)
When a general rule is followed by specific examples, agents implement ONLY the specific examples and treat them as exhaustive. Documented shared LLM blind spot.

```
BAD:  "only objects or arrays trigger formatting. If the action returns
       undefined or null, no formatting occurs."
       → Agents guard only null/undefined, miss the general "only object/array" rule.
       → 14/14 agents failed on this exact pattern.

GOOD: "only a returned object or array triggers formatting and any non-object
       return value is silently ignored."
       → General rule stands alone, no specific examples to latch onto.

BAD:  "strings, numbers, and booleans are ignored just like undefined and null"
       → Too explicit — gives agents a checklist, pushes pass rate to 100%.
```

Fix: either remove specific examples entirely, or restructure so general constraint is self-contained without examples that agents treat as the complete list.

### Anti-Pattern: Inconsistent Naming
Use exact conventions from the repo. Tests using `X-Death` header but repo convention `x-death` (lowercase) → agents fail on inconsistency. Match repo casing/spelling.

### Anti-Pattern: Ambiguous Boundary Conditions
"exceeding 5 seconds" unclear — `> 5` or `>= 5`? Use precise comparison operators.

```
BAD:  "delay values must be capped at 5 minutes"  (capped = error or clamp?)
GOOD: "delay values exceeding 5 minutes must be clamped to 5 minutes"
```

### Anti-Pattern: Copy-Paste Challenges
Don't create challenges that share the same structure with only superficial differences (e.g., "add a play button" then "add a pause button"). Each challenge must require genuinely distinct reasoning.

---

## Blind-Spot Pre-Empt Sentence Bank

Add the matching sentence to `meta.md` when applicable:

| Blind Spot | Approved sentence |
|---|---|
| Rule-reference resolution | "Resolve rule references through the grammar's rule map when checking …" (factorizer) |
| Sort order ambiguity | "Order Literal values lexicographically, then CaseInsensitive values by ASCII lowercase, then CharRange values by start codepoint" (extended-skip) |
| Adjacent vs all-positions | "working on adjacent positions only so author-supplied alternative ordering is preserved" (lightningcss) |
| First/last-occurrence dedup | "deduplicated using ASCII case-insensitive comparison, keeping the first occurrence" (extended-skip) |
| Iteration termination | "iterates until no rewrites apply" (lightningcss); "iterate to a fixpoint" (factorizer) |
| Order of result list | "Results preserve the order rules appear in `rules`" (unused-rule-elim) |
| Parallel optimized API | "Parallel `find_unused_optimized_rules`, … operate on `&[OptimizedRule]` with the same semantics" (unused-rule-elim) |
| Falsy-on-invalid | "is_rule_reachable returns false for undefined names or empty rules" (unused-rule-elim) |
| Compound order preservation | "Compound-selector component order is preserved exactly: `.x:is(.a)` stays `.x:is(.a)`" (lightningcss) |
| Pipeline placement | "normalize grammar rule expressions (Expr) before they are converted to optimized expressions" (normalizer — universal blind spot) |

See `AGENTS.md § Confirmed Blind Spots` for the broader list.

---

## Alignment Rule (#1 Review Criterion)

**Every test must trace back to the description. Every described behavior must be tested.**

If you test it, mention it. If you don't mention it, don't test it.

0–1 codebase-inferable requirements (visible in code but not description) are acceptable. More than 1 = hidden requirements → reverted.

Reviewers check:
- Are there "surprise tests" — tests that verify behavior not mentioned in the description?
- Are there described behaviors that have no corresponding test?

How to align:
1. Write description first (or at least a draft)
2. For each sentence in description → plan at least 1-2 tests
3. After writing tests → re-read description, check every test has a home
4. If you find yourself writing a test for something not in description → either add it to description or don't write the test

---

## Wrong Logic Prevention

When agents hit **Wrong Logic ≥25%** of runs, the description has a subtle correctness trap. From 13 approved problems, this happens when:

| Cause | Example | Fix |
|---|---|---|
| Pipeline placement implicit | normalizer must run BEFORE optimization (33% Wrong Logic, 0% pass) | State pipeline position explicitly: "runs as the final pass" / "before X" |
| Multi-pass coverage trap | `count_references` must include new variant `InlinedRule` (40% Wrong Logic) | Name every collection / counter that the new variant must appear in |
| Algorithmic shape implicit | dispatch fallback must use `map_top_down` not manual recursion (25% Wrong Logic) | Specify traversal direction: "applied top-down" / "process pairwise from left to right" |
| Async semantics implicit | goja-using disposal order, SuppressedError wrapping (25% Wrong Logic) | State exact ordering and error-wrapping shape |

If your problem requires a subtle algorithm decision (traversal direction, multi-pass behavior, error wrapping order, pipeline placement) — name it. Don't rely on agents inferring.

---

## Engineering Hard Problems / Olympus Difficulty Levers

Target ~10% Olympus pass rate. **52% of failures are MISSED_REQUIREMENT** — precision wording is the #1 lever. From 130 agent runs across 12 approved problems: best problems have agents scoring 19/21, 84/85, or 105/107 — near-miss on 1-2 edge cases.

### Lever 1 — Dense requirement sentences

Pack multiple testable requirements into single sentences. Each parenthetical, comma-separated option, or qualifier is a potential failure point.

| Approved example | Testable requirements |
|---|---|
| ormar: "Subquery takes a queryset with optional output_field (defaults to primary key) and optional aggregation (sum, avg, min, max, count)" | 5: queryset input, optional output_field, default to PK, optional aggregation, five aggregation types |
| httpx: "retry_on_status (tuple of ints; default (503, 429))" | 3: parameter name, type constraint, default value |
| goja: "Value must be null, undefined, or an object with a [Symbol.dispose] method" | 3: null OK, undefined OK, object with specific method |
| pest-normalizer: "Double negation eliminates both layers to yield the bare inner expression (not a positive lookahead)" | 2: elimination behavior + clarification of what it is NOT |

### Lever 2 — Layered complexity (multiple subsystems)

The hardest Olympus problems require implementing across 4–6 interdependent layers. Each layer is independently tricky and agents must get ALL of them right.

| Problem | Layers | Pass Rate |
|---|---|---|
| bumpp | workspace discovery → tag matching → commit parsing → scope matching → bump determination → file writing | 10% |
| h2 | RFC parsing → dependency tree → scheduling → event firing → introspection → configuration | 10% |
| pest-inliner | eligibility → reference counting → complexity thresholds → multi-pass resolution → substitution scope → order preservation | 10%, 67/68 best |
| pest-normalizer | expression classification → normalization rules → fixpoint iteration → new variant introduction → traversal integration | 0% (47/57 best) |

### Lever 3 — Precision words that trip agents

Single words with specific semantic weight. Agents interpret the generic meaning instead of the precise one.

| Word used | What agents did instead | Failure rate |
|---|---|---|
| "**subjects**" not "commits" (bumpp) | Filtered by git parent count, not subject text | 6/9 |
| "BREAKING CHANGE in **body**" (bumpp) | Only checked `!` in commit header | 4/9 |
| "**created**" not "reprioritized" (h2) | Only hooked priority frames, not `_begin_new_stream` | 4/9 |
| "**unbounded** non-aggregated scalar" (ormar) | Rejected ALL non-aggregated subqueries | 5/8 |
| "**equivalent**" (oxvg href/xlink:href) | Compared attribute names literally | 5/9 |
| "**map_top_down**" traversal (pest-charclass) | Used map_bottom_up | 9/12 |
| "**non-Opt** copies" (pest-seq-rewriter) | Treated Opt(x) as a "mandatory copy" | 3/12 |
| "**zero or more** Opt wrappers" | Required ≥1 Opt wrapper | 3/12 |

### Lever 4 — Negative constraints (what NOT to do)

Telling agents what to exclude is as important as what to include. Agents often over-implement.

- bumpp: "no interactive prompts, regardless of confirm/interface settings. Ignore release, currentVersion, and files"
- pest-inliner: "Substitutions occur only at call sites; the bodies of inlineable rule definitions themselves are not rewritten"
- pest-normalizer: "Empty strings inside push or predicate sequences must not be removed"

### Lever 5 — Precise error conditions

Specify exactly when errors should occur and what error behavior looks like.

- ormar: "Contextless OuterRef and unbounded non-aggregated scalar comparisons raise errors"
- httpx: "ValueError if max_retries<0, backoff_factor<0, backoff_max<=0 when set. Error message must include the offending parameter name"
- bumpp: "Any malformed directive line or unmatched directive token errors and no workspace package.json is modified"

### Lever 6 — Return contracts and observable state

Specify exact return types, field names, and observable state changes.

- bumpp: "returns updatedFiles/skippedFiles as absolute paths... currentVersion as the max current version across considered packages"
- httpx: "response.extensions['retry_history'] = list of dicts per failed attempt: {'status_code': int|None, 'exception': str|None}"
- h2: "get_scheduling_metrics() returning object with total_scheduled_bytes, scheduling_rounds, fairness_index, streams_starved"

### Lever 7 — Integration hooks (the #1 agent killer)

Agents build the core feature correctly but fail to wire it into all code paths.

| Problem | Integration requirement | Agents who missed it |
|---|---|---|
| h2 | Scheduler must hook into `_begin_new_stream` | 4/9 |
| httpx | Must use `anyio.sleep()` not `asyncio.sleep()` for trio | 4/7 |
| pest-inliner | InlinedRule must be handled in iter_top_down, map_top_down, AND map_bottom_up | Common miss |
| pest-normalizer | NormalizedChoice/NormalizedSeq must integrate with Display, traversals, and downstream passes | Common miss |
| pest-seq-rewriter | FlatSeq/BoundedGroup must be handled in VM and generator (exhaustive match) | 5/12 |
| pest-charclass | CharClass/NegCharClass must be handled in VM, generator, Display, traversals | 4/12 |

### Lever 8 — Codebase-inferable requirements (0–1 max)

Requirements not stated in description but discoverable from codebase. Limit to 0-1 per problem.

- httpx: Trio compatibility via `sniffio` usage visible in codebase (not in description)
- pest: Existing optimizer passes use `map_top_down` (pattern discoverable but not stated)

More than 1 drops pass rate below target and risks fairness flags.

### Problem Quality Ranks

| Rank | Files | Our Solution LOC | Requirements | Pass Rate | Example |
|---|---|---|---|---|---|
| Okay (approvable-but-weak) | 3-10 | 400-600 | 5-10 stated | 5-20% (>20% = too easy) | httpx (3 files, 30% historical — must be hardened to ≤20%), pest-inliner (4 files, 10%) |
| Good | 10-20 | 600+ | 10+ interacting | 5-15% | goja (12 files, 25%) |
| Excellent | 20+ | 600+ | 15+ cross-system | 0-10% | FoalTS reference (20+ files) |

Agent metrics (messages, LOC) are a consequence of problem design — more files and requirements naturally force agents to write more code and use more messages. Design the right problem and the difficulty follows.

### Difficulty Calibration Anti-Patterns

| Mistake | Effect | Fix |
|---|---|---|
| Too few requirements (5-7) | >20% pass rate, too easy (5-20% is approvable-but-weak) | Target 10+ for ~10%, 15+ for Excellent |
| No codebase-inferable | Easy agents skip exploration | Add 1 (max) requirement visible in code, not description |
| Words without semantic weight | Generic interpretation | Use precise terms ("subjects" not "commits") |

---

## Decision Framework

For each sentence, ask:

1. **WHAT or HOW?**
   - WHAT: "detect dangerous protocols even when encoded" → INCLUDE
   - HOW: "decode percent entities before checking" → REMOVE

2. **Would any developer assume this?**
   - "Maintain backward compatibility" → REMOVE (obvious)
   - "Archiving cascades to descendants" → INCLUDE (not obvious)

3. **Do my tests verify this?**
   - Yes → INCLUDE
   - No → Don't mention it

4. **Does the solver need this name to pass my tests?**
   - Yes → INCLUDE the method/option/error name
   - No → Don't clutter with unnecessary names

5. **Can I say this in fewer words?**
   - Always compress.

---

## Writing Style

### Tense
- Present tense always: "The function fails..." not "will fail..."
- Active voice: "The parser skips..." not "Items are skipped..."

### Tone
- Natural language — reads like a developer reporting an issue
- NOT a technical spec, NOT an API document
- No bullet-pointed specs within the description
- No run-on sentences

### Conciseness
- Every word adds value
- No redundant phrasing
- No unnecessary backstory
- Cut any sentence that doesn't add new information
- No AI slop — avoid verbose, boilerplate-sounding language that feels auto-generated

---

## Human-Voice + ASCII Rules (ALL Tiers — Mars / Olympus / Diamond / Lite)

Platform runs an AI-slop detector on every description across every tier. Same human-voice rules apply universally. These were originally scoped to Diamond failure-QA but reviewer feedback confirms they fire across ALL submission-bound text.

### Where these rules apply

| Artifact | Tier | Why |
|---|---|---|
| `meta.md` (description) | All | AI-slop check runs at submission |
| `failure-qa.md` | Diamond | Reviewer cycle (6 rounds confirmed) |
| `solution-approach.md` | Diamond | Reviewer cross-checks |
| `test-groups.md` | Diamond | Test Summary annotation |
| Env description (Shipd UI) | Diamond ~2026-05-21 | Required field, paragraph-form |
| `feedback.md` sections quoted on Shipd UI | All | Reviewer visibility |

### The 9 Rules

1. **No em dashes** (U+2014 `—`). #1 AI tell. Use colons / commas / parens / sentence breaks. Platform hard-rejects `non_ascii_character` on em-dash in meta.md.

2. **No `--` as pseudo-em-dash in prose.** Reads as AI shorthand. Code / CLI flags / diff contexts OK (e.g., `--output_path`); prose NOT.

3. **No Unicode arrows / smart quotes / curly punctuation.** `→`, `←`, `↑`, `↓`, `«»`, `""`, `''`, `…` all flagged. Use ASCII equivalents.

4. **No AI cadence markers.** Avoid:
   - Pleasantries: "Sure!", "Certainly!", "Of course!", "I'd be happy to..."
   - Hedging: "It's important to note that...", "It's worth mentioning..."
   - Throat-clears: "In essence", "At its core", "Fundamentally", "Notably", "Specifically", "Essentially"
   - Demonstratives: "This approach...", "This solution...", "This implementation..."
   - Paired clauses: "not only X but also Y", "while X, also Y"
   - Forced tricolons: "X, Y, and Z" when only X matters

5. **Final code state, not trajectory.** Describe what code DOES, not what an agent / developer DID. "The function returns false" beats "the agent wrote a function that returns false."

6. **No fabricated identifiers.** Every named variable / method / field exists in actual code. Grep before citing.

7. **Concrete values over abstractions.** `Expected 'NA', got ''` beats "expected null representation, got empty value." Use literal characters / paths / error substrings.

8. **No trajectory step references** (in failure-qa / solution-approach). Never "At step 21...", "After encountering test failures...", "Subsequently the agent..."

9. **No cross-run comparisons** (in failure-qa). Every entry stands alone. No "same as Castor #1", "as noted above", "see entry 3."

### Pre-Submit Guard Commands (RUN ON EVERY SUBMISSION)

```bash
# Em-dash + Unicode dash check (must return empty)
rg '[\xE2][\x80][\x90-\xAB]' meta.md feedback.md $(ls failure-qa.md solution-approach.md test-groups.md 2>/dev/null)

# Smart quotes + ellipsis
rg '[\xE2][\x80][\x98-\xA6]' meta.md feedback.md $(ls failure-qa.md solution-approach.md test-groups.md 2>/dev/null)

# Pseudo-em-dash in prose contexts
rg ' -- | --$' meta.md feedback.md

# One-shot ASCII check
file meta.md   # must say "ASCII text" (NOT "UTF-8 Unicode text")
```

Better one-shot: `file <each-file>` reports "ASCII text" if clean. "UTF-8 Unicode text" means non-ASCII somewhere; investigate.

### Why elevated to all tiers

Reviewer feedback confirms AI-slop detector fires on:
- meta.md across Mars + Olympus + Diamond + Lite
- AI cadence markers caught in approveds-feedback for Mars problems
- Em-dash hard-reject (`non_ascii_character`) fires before human review at any tier

Treating human-voice as a Diamond-only concern leaves Mars / Olympus / Lite vulnerable to the same auto-rejection class. From this point: **apply to all submission-bound text regardless of tier**.

### What stays as-is

Internal instruction / playbook files (`Instructions/*.md`, `.agents/*.md`, the playbooks themselves) are working documents for the author. Em dashes acceptable in these. **The rule applies to submission-bound text only.**

See also: `lessons-learned.md § Description Format` (ASCII rule), `DIAMOND.md § Failure QA Writing Style` (Diamond-specific QA rules), `DIAMOND-PLAYBOOK.md § Section 6.4` (Diamond cross-artifact application).

---

## Review Criteria (Items 1–7 of 21)

Reviewers score on a 7-point scale. Must score 5+ to pass:

| # | Criterion | Pass | Fail |
|---|---|---|---|
| 1 | Requirements complete and self-contained | Everything needed is present | Important context missing |
| 2 | No ambiguities, fully deterministic | Precise and testable | Vague or open to interpretation |
| 3 | Concise and not prescriptive | Describes what, not how | Prescribes implementation steps |
| 4 | Matches real-world repo scope | Realistic issue | Unrealistic scope |
| 5 | Aligns with repo design philosophy | Fits existing patterns | Contradicts project conventions |
| 6 | No irrelevant context | Focused on what matters | Unnecessary background |
| 7 | Clear writing and formatting | Well-structured | Unstructured wall of text |

### 5-Second Test
Does it read like a GitHub issue or API docs? If API docs → rejected.

### Common Reviewer Feedback
- "Description is written like a technical spec tone instead of natural language"
- "What defines '[term]'? This needs to be specified"
- "Missing edge case tests for [scenario]" (test/description misalignment)
- "Remove obvious content: backward compatibility is always expected"

---

## AI Check Patterns

| Pattern | Diagnosis |
|---|---|
| All checks fail for same reason | Description likely missing critical info |
| Tricky wording causes failures | Fix the ambiguity, don't rely on tricks |
| Checks pass easily | Problem is too easy |
| Checks fail for logical reason clear from description | AI's mistake — bypass with justification |
| `minor_suggestions` verdict with MEDIUM/LOW items | Acceptable (approved as-is) |
| `request_changes` verdict with HIGH items | Must fix |

**Example from admin review:** Tests used `X-Death` header but repo convention was `x-death` (lowercase). AI agents failed due to this inconsistency. Admin required fixing the case in the description.

---

## Agent Run Requirements

- **FAIL_TEST_MISMATCH = 0** or near-zero. Any count > 0 = description ambiguous. 12/14 approved Olympus had zero.
- **`description_clear: false` ≤ 1** outlier per run set.
- **Near-miss evidence** required for low pass rates: ≥1 agent at 80%+ test score proves solvability.
- **Wrong Logic ≥25%** signals subtle algorithmic trap — see Wrong Logic Prevention above.
- **0% pass rate is a REJECT at Mars and Olympus.** (HISTORICAL: the old Mars-only 0%-with-near-miss-evidence path is DEAD post-April-2026 — do not treat it as a live approvable route. Olympus solvability also cannot be bypassed. A near-0 design belongs at Diamond, which keeps the hint flow.)

---

## Rejection Criteria

> **⚠️ Rejection is FINAL — the user cannot edit after rejection. Most issues should be "Request Change", not Reject.**

### Hard Reject (Cannot Be Fixed)
1. **PR already exists** — GitHub PR solves the issue. Always search first.
2. **Too easy/trivial** — one-liner solution, or AI checks pass easily. Target 4-8+ hours.
3. **Doesn't fit repo** — change contradicts repo philosophy (admin is lenient on this).
4. **Duplicates** — another Shipd submission for the same problem already exists.
5. **Plagiarized** — submission copied from another Shipd submission.
6. **Wrong language** — repo is not Python, TypeScript/JS, Go, or Rust.
7. **Inactive/invalid repo** — no commit in last year, invalid commit hash, or <500 stars.
8. **Non-permissive license** — GPL, AGPL (see RULES.md for allowed list).
9. **Made up feature** — problem doesn't reflect a real need; feels artificial or contrived.
10. **False claims** — described bug/feature already works correctly.
11. **Duplicate with different approach** — another submission for the same core issue exists.

### Mandatory Pre-Submit Gate

- Flakiness verification (MANDATORY Core Dev check): the target repo's existing tests AND the new tests must be non-flaky — run base+new at least 3-5x and confirm deterministic, identical pass/fail every run; no timing/ordering(map-set-iteration, parallel-race)/unseeded-RNG/network/clock/filesystem-time dependence; a flaky repo baseline or flaky new test = reject.

### Request Change (CAN Be Fixed — do NOT reject for these)
- Description too prescriptive → user can reword
- Missing information → user can add
- Ambiguous wording → user can clarify
- AI-generated tone → user can rewrite
- Wrong format → user can fix
- Test issues (wrong framework, excessive, weak assertions) → all fixable
- Solution bugs, debug code, unrelated changes → all fixable
- Hidden requirements (AI agents failing due to undocumented requirements) → user can add missing info

---

## Reference Examples

### Modern Mars (April 2026) — see `Mars Approved V2/Feature Requests/`

| Problem | Words | Shape | Style |
|---|---|---|---|
| pest-validator-hardening | 91 | C | Short, 9 distinct error classes, dense |
| lightningcss-selector-simplify-fixpoint | 107 | A1 | 1 paragraph + bullets |
| pest-factorizer-fixpoint | 137 | A2 | 1 paragraph, 6 inline rewrite rules |
| pest-extended-skip | 183 | D-change | 3 paragraphs (types, normalization, supplementary API) |
| pest-unused-rule-elim | 241 | B | 3 paragraphs covering 13 public functions |

Open the closest match in `Mars Approved V2/Feature Requests/` and use it as scaffolding.

### Compact approved Olympus (ormar — 68 words, 20% pass)

```
# Subquery Support

Complex filtering patterns like finding entities based on related data
aggregations force users to write raw SQL or execute multiple queries without
subquery support.

Add `Subquery`, `OuterRef`, and `Exists` to enable single-query
`.filter()`/`.exclude()` calls, including nested subqueries. `Subquery` takes a
queryset with optional `output_field` (defaults to primary key) and optional
`aggregation` (sum, avg, min, max, count).

Contextless `OuterRef` and unbounded non-aggregated scalar comparisons raise
errors.
```

This 68-word description (the shortest approved Olympus) packs 9 testable requirements: Subquery/OuterRef/Exists creation, single-query filter/exclude usage, nested subqueries, queryset input, optional output_field, default to PK, optional aggregation, 5 aggregation types, two distinct error conditions.

### Real Approved Descriptions (Annotated)

#### Bug: Short and Direct (28 words)
```
# Fix natural join with one-time iterators

Natural joins read inputs multiple times, breaking one-time iterators. Update
all natural join variants to consume each input exactly once across the whole
operation.
```
**Why it works:** States what's broken, states what to do. No fluff.

#### Bug: Medium with Consequence (52 words)
```
# Check source modified dates in convert plugin

The convert plugin skips reconversion when the destination file exists, even if
the source file was modified after the last conversion. This causes stale
conversions when source audio files are updated.

The plugin should reconvert when the source file has been modified since the
last conversion. This applies to all conversion modes.
```
**Why it works:** Clear problem → clear consequence → clear expected behavior → scope note.

#### Bug: Minimal (17 words)
```
# ReadableStream Error in mount()

Using mount() fails when hooks or handlers read request bodies multiple times.
Fix body stream handling to allow multiple reads.
```
**Why it works:** Shortest possible while still being clear.

#### Feature: Complex with API Surface (140 words)
```
# Add task archive functionality

Completed tasks accumulate in workspaces with no way to hide them while
preserving their history.

Add the ability to archive and unarchive todos. The Todo.all() listing should
only return non-archived items. Archiving or unarchiving a parent todo should
cascade to all its descendants. A todo's status should be "archived" while it
is archived.

Archive state should be exposed via Todo.is_archived and Todo.archived_at;
calling Todo.archive() on an already archived todo must not change
Todo.archived_at. Unarchiving should clear archived_at to None. Use
ArchivedTodoError when writes are attempted on archived todos. The
sort_siblings() method should only sort non-archived items. Provide helpers
Todo.archived(), workspace active_todos / archived_todos, and todo
active_siblings (which includes the todo itself). Archive metadata should be
ignored by Todo.comparable_fields().
```
**Why it works:** States motivation → core behavior → detailed behavioral requirements with API names. Long but every sentence adds unique testable information.

#### Feature: API-Heavy (wazero debug support, ~180 words)
```
# Add debugging support

Implement debugging support in the experimental/debug package. Add Debugger()
method to api.Module returning debug.Debugger (nil if closed). All Debugger
methods are concurrent-safe. The Debugger interface:
- SetBreakpoint(funcIndex uint32, pc uint64) error — idempotent
- RemoveBreakpoint(funcIndex uint32, pc uint64) error — errors if no breakpoints
- ClearBreakpoints()
- SetCallback(DebugCallback) — nil allowed
- Breakpoints() map[uint32][]uint64 — never nil

DebugCallback func(DebugEvent, StackFrame) DebugAction where:
- DebugEvent: PC, FunctionName, FunctionIndex, SourceOffset
- StackFrame: FunctionName, FunctionIndex, PC, Locals
- DebugAction constants: Continue, StepInto, StepOver, StepOut
```
**Why it works:** For new API implementation, specifying the interface IS the problem — the challenge is making it work internally. Method signatures aren't implementation details here, they're the spec.

---

## Before/After Examples (From Admin)

### Example 1: Vary: Cookie Support

**REJECTED — too verbose, split sections, implementation details:**
```
Problem Description:
The requests-cache library fails to cache responses correctly when servers
send Vary: Cookie headers. POST requests with identical cookies return fresh
responses on every call instead of using the cache, because cookie values are
not included in cache key generation. This causes unnecessary network requests
and defeats caching for cookie-aware APIs like Wikipedia and Google Places...

Agent Instructions:
Extend cache key generation to include cookies when Vary: Cookie is present.
Serialize cookies from the request's cookie jar, including domain and path
information to distinguish same-name cookies with different scopes...
```

**APPROVED — single paragraph, behavioral, concise:**
```
The requests-cache library fails to cache responses correctly when servers
send Vary: Cookie, because cookie values are not included in cache key
generation. When Vary: Cookie is present or cookie matching is explicitly
requested, include request cookies (cookie jar + Cookie header) in the cache
key and add an ignored_cookies option on CachedSession, analogous to
ignored_parameters, to filter those out of cache keys and cached request data.
When Vary: Cookie is absent and cookie matching isn't requested, continue
ignoring cookies.
```

### Example 2: Natural Join Iterators

**REJECTED — split sections:**
```
Problem Description:
Natural join operations fail when used with one-time iterators...

Agent Instructions:
Ensure all natural join operations read each input table exactly once...
```

**APPROVED — single paragraph:**
```
Natural joins currently read inputs multiple times, breaking one-time
iterators. Update all natural join variants, including hash-based ones, to
consume each input table exactly once across the whole operation, covering
both natural key determination and join execution.
```

### Example 3: Optional Path Segments

**REJECTED — split sections, test assumptions:**
```
Problem Description: [text]
Agent Instructions: [text]
Test Assumptions: Optional segments use ? suffix for dynamic params (:id?).
```

**APPROVED — single paragraph with all info:**
```
Add optional dynamic path segments marked with a ? suffix (e.g., :id?) so a
single route matches paths with zero or more of those segments present. When
multiple routes match, apply precedence: 1) static over dynamic, 2) fewer
optional segments, 3) exact path length, 4) insertion order. The router and
its compiled form must support optional segments, and removing a route defined
with optional segments must remove all of its variants.
```

---

## Real Review Examples (From Olympus Admin)

### Example: Vague requirements
Most of this description is precise and testable — but the last sentence isn't:

> "...When the subpattern uses selections, the handler must receive arrays of matched selections only. Nested array selections should keep their nesting. When no subpattern is provided, match any non-empty array. **Update type inference so the pattern does not make array inputs exhaustively handled by itself.**"

**Why this fails review:** The rest of the description is precise and testable, but the bolded sentence is meaningless without deep ts-pattern internals knowledge. A solver reading the repo won't know what this means, and a reviewer can't verify correctness against a requirement they can't interpret.

### Example: Over-prescriptive specification
This spec dictates exact internal structures instead of describing behavior:

> "FieldMetadataInfo has field_name, resolved_type (preserving container types), metadata_items (tuple of flattened Annotated metadata), constraints (dict[str, ConstraintInfo])..."

Tests that reinforce the problem:
```python
# BAD — implementational tests
assert type(field_info).__name__ == 'FieldMetadataInfo'
assert type(constraint_info).__name__ == 'ConstraintInfo'
assert isinstance(metadata_items, tuple)  # why not list?
```

**Problems:** The spec dictates exact constraint name mappings, exact class names, exact container types — this is implementation, not behavior. Hidden requirements buried in the spec (metadata_items must be tuple not list, nested_fields empty for List[Model] but populated for Optional[Model]). Tests verify class names instead of observable behavior.

**Reviewer feedback:** *"extremely prescriptive... SO many tests are implementational... hidden requirements"*

### Example: Before & after fixes

**Fix 1 — Ambiguous behavior → explicit behavior**

| Before | After |
|---|---|
| "delay values must be **capped** at 5 minutes" | "delay values exceeding 5 minutes must be **clamped** to 5 minutes" |

"Capped at 5 minutes" is ambiguous — does it reject values over 5min with an error, or silently clamp them?

**Fix 2 — Vague reference → explicit list**

| Before | After |
|---|---|
| "browser.tables must provide **the same find methods as browser.links**" | "browser.tables must provide **find_by_id, find_by_css, find_by_tag, and find_by_xpath** methods" |

"Same as X" forces the solver to reverse-engineer another API's interface. Listing the methods explicitly removes ambiguity.

---

## Lessons from Iteration (pest-seq-rewriter — Approved)

This problem went through 3 rounds of agent runs before reaching 8% (1/12 pass):

**Round 1 (0/12)**: Display format `{expr}{min,max}` was ambiguous — agents read `{expr}` as placeholder, not literal braces. ALL 11 agents got Display wrong.

**Round 2 (0/12)**: Added Display examples `{"x"}{2,3}`. Fixed Display but agents now failed on BG logic. "mandatory copy" was ambiguous — agents treated Opt(x) as mandatory. Also agents copied Seq's parenthesized Display for FlatSeq → failed tests.

**Round 3 (1/12 — approved)**: Removed Display specification entirely (follows approved normalizer precedent). Changed "mandatory" → "non-Opt". Result: 1 pass, 1 near-miss at 84/85. Final verdict distribution: 1 PASS, 5 MISSED_REQUIREMENT, 3 REGRESSION, 2 INTEGRATION_ERROR, 1 WRONG_LOGIC. 0 FAIL_TEST_MISMATCH, 11/12 description_clear: true.

**Key takeaways**:
1. **Don't test Display when repo patterns conflict** — if existing variant Display uses parens, agents will copy it for new variants. Either match the pattern or don't test it.
2. **Use domain-precise terms** — "non-Opt" is unambiguous in pest context; "mandatory" is overloaded.
3. **"zero or more X" is a valid trap** — agents consistently code `if count > 0` despite "zero or more" clearly including zero. This is fair difficulty, not ambiguity.
4. **Three-layer tests work** — unit (optimizer) + VM integration + derive/generator catches different failure modes across agent types.
5. **Explicit type signatures prevent FAIL_TEST_MISMATCH** — `FlatSeq(Vec<Box<OptimizedExpr>>)` leaves no ambiguity.
6. **Check warnings are acceptable** — approved with `minor_suggestions` verdict (1 MEDIUM + 1 LOW unfixed). Only HIGH items require fixing.

---

## Common Mistakes (From Rejections) — Quick Reference

1. **Split description into Problem + Agent Instructions** → merge into single paragraph
2. **Include "maintain backward compatibility"** → remove, obvious
3. **Describe internal algorithm** → describe observable behavior instead
4. **Tests verify behaviors not mentioned in description** → add the behavior or remove the test
5. **Tricky wording that makes the problem non-deterministic** → be clear, not clever
6. **Inconsistent naming** (e.g., X-Death vs x-death) → use exact conventions from the repo
7. **Too verbose** (250+ words on a simple bug) → cut ruthlessly
8. **Vague terms undefined** ("synced lyrics" without defining what makes lyrics "synced") → define key terms
9. **Hidden requirements** (multiple backends tested but not mentioned) → state explicitly
10. **Ambiguous boundary conditions** — "exceeding 5 seconds" unclear if `> 5` or `>= 5` → be precise
11. **Missing error behavior** — tests check for `ETIMEDOUT`, `ECONNABORTED` but description only says "timeout errors" → specify exact error types if tests check them
12. **Copy-paste challenges** — different challenges share structure with only superficial differences → require genuinely distinct reasoning
13. **Too few requirements** — 5-7 requirements → 30% pass rate (too easy). Target 10+ for ~10%, 15+ for Excellent rank.
14. **No codebase-inferable requirements** — at least 1 requirement visible in codebase but not description filters lazy agents who skip exploration.
15. **Words without semantic weight** — use precise terms ("subjects" not "commits", "unbounded" not "non-aggregated").
16. **Framing the repo as external** — don't start with "X currently supports Y but lacks Z..." as if introducing the project. The solver already has the repo.
17. **Turning description into a checklist** — don't make it a list of snappy instructions. It should flow naturally like a developer describing a problem or feature need.
18. **Listing discoverable repo details** — don't describe patterns, mechanisms, or behaviors that agents can find by reading the code, unless needed for fairness.
19. **Using code snippets for everything** — `model.update()` and `model.delete()` is worse than "Model updates and deletes" unless the exact method name matters for tests.
