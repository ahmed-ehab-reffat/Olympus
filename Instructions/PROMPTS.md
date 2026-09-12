# PROMPTS — Reusable Prompts & GitHub CLI

Mars is the default tier. Queries 1–5 cover Mars and shared workflows; Query 6 is Olympus-only; Query 7 is Diamond-tier; Queries 8–9 are Lite-tier; Query 10 is tier-agnostic ideation; **Query 11 builds end-to-end from a picked candidate in an `analysis-folders/<repo>-analysis/`** (most efficient path when analysis already done); **Query 12 is the pre-Castor Diamond audit**.

> **UNIVERSAL — ALL QUERIES, ALL TIERS:** Apply `DESCRIPTION.md § Human-Voice + ASCII Rules` to every meta.md / failure-qa.md / solution-approach.md / test-groups.md / env description / Shipd-UI text. Platform AI-slop detector fires across Mars / Olympus / Diamond / Lite. NO em dashes (U+2014), NO `--` in prose, NO Unicode arrows / smart quotes / ellipsis, NO AI cadence (Sure! / I'd be happy / It's important to note / In essence / At its core / Notably / This approach / not only X but also Y). Pre-submit guard: `rg '[\xE2][\x80][\x90-\xAB]' meta.md feedback.md` → empty; `file meta.md` → "ASCII text".

> **UNIVERSAL — DIFFICULTY-CALIBRATION (admin 2026-07 sprint):** ONE TIER = Olympus (Mars merged in). **Pass-rate cap = ≤40%** (0% = reject, >40% = too easy); still bias to the HARD/low-pass edge because difficulty drives PAYOUT ($150-350), not just approval. Long-horizon floor: **≥250 eff LOC · ≥2 files · ≥40 solver-median msgs.** FP Check mandatory at the very end. The knob is trap COUNT/STRENGTH → pass-rate (1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%), NOT LOC. **Traps must be INTERDEPENDENT (one fix regresses/surfaces another) + MISDIRECTING (failing test hides the fix); an isolated self-revealing trap gets single-shot-fixed.** Uniform-wrap / single-point trap too easy. Supersedes older ≤30%/≤20% figures. See `../CLAUDE.md § RULE UPDATE 2026-07`.

> **UNIVERSAL — OLYMPUS + DIAMOND HARD RULE:** GATE ON **COUNTER 2 (`human-effective`) ≥ 450** — the reviewer's meaningful count (strips blanks, comments, no-ops, generated files, TEST files, package/imports + closing `)`/`}`, braces/punctuation-only lines, boilerplate). This is the BINDING number; design + verify against it, NOT the looser auto-block. Primary pre-submit verify:
> ```bash
> python .claude/hooks/effective_loc_check.py solution.patch   # PRIMARY: read `human-effective:` line, target >= 450
> ```
> Counter 1 (the platform auto-block, ≥400) = `raw − blank − comment` with braces + imports KEPT (cel-go `575−48−160=367`) is a LOOSER by-product; it clears automatically once Counter 2 ≥ 450, so never design to it (it overstates ~15-30% in Rust/Go). Confirm-only: `f=solution.patch; raw=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|wc -l); blank=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*$'); comment=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*(///|//|/\*|\*)'); echo $((raw-blank-comment))` should be ≥ 400. Comments + braces + imports are DEAD WEIGHT for Counter 2 — only real implementing logic clears the floor. If under → expand scope with real logic (helpers, public API, cross-package integration), never pad (Real Revert Cause).

---

## Quick Reference

| Situation | Query |
|---|---|
| Generate a new Mars feature challenge | Query 1 |
| Solve an existing Mars/Olympus issue | Query 2 |
| Find new candidate repos | Query 3 |
| Analyze a repo for potential problems | Query 4 |
| Handle reviewer feedback | Query 5 |
| Generate an Olympus feature challenge | Query 6 |
| Diamond-tier task (create/eval/qa/review) | Query 7 |
| Lite-tier issue resolution (≥100 LOC) | Query 8 |
| Lite-tier repo analysis | Query 9 |
| Generate tier-agnostic feature request (no issue) | Query 10 |
| Build submission from picked analysis-folder candidate | Query 11 |
| Assess Diamond submission readiness (pre-Castor) | Query 12 |

---

## Query 1: Generate Mars Feature (default)

For new feature challenges fitting one subsystem.

**Design considerations** (apply to every candidate):
- Feature must be natural for the project (something users would want)
- Must not duplicate existing functionality
- Should exercise core project APIs/patterns
- Think about what would challenge an AI agent
- Consider features that require design decisions
- Tests should work with any correct implementation (no hardcoded method names)

**Parameters:**
- `REPO_URL` — repository to create feature for
- `SHAPE` (optional) — pin a specific Mars shape (A1 / A2 / B / C / D-new / D-change). If omitted, the prompt picks the best fit.

**Prompt:**
```
Generate a Mars-tier feature request challenge for {REPO_URL}.

STEP 1: Identify the Mars shape FIRST. Each shape has different targets.

Mars shape selector (see SHAPES.md § Pattern 11):
- A1 — Distributed pipeline modification (3 files of similar weight). Pass 10–15%. Best agent: Nova→Orion (slow).
- A2 — Concentrated + signature change (1 main + thin wiring). Pass 20–25%. Best agent: Nova→Orion (fast).
- B — Add new public API list (new module + thin wiring). Pass 50–55%. Best agent: Orion-alone.
- C — Additive extension (1 file dense, no signature change). Pass 20–25%. Best agent: Nova→Orion.
- D-new — New cross-crate enum variant. Pass 20–25%. Best agent: Orion-alone. Verdict: Integration Error.
- D-change — Cross-crate variant signature change. Pass 40–45%. Best agent: Nova→Orion + Vega. Verdict: Regression.

Pick the shape that fits naturally. Don't force.

STEP 2: Apply shape-specific targets (see WORKFLOW.md § Identify Your Shape):
| Shape | Files | LOC | Tests | Desc words |
| A1 | 3 dist | 167 | 68 | 107 |
| A2 | 3 conc + wiring | 220 | 92 | 137 |
| B | 3 (2 new) | 377 | 160 | 241 |
| C | 1 dense | 358 | 39 | 91 |
| D-new | 15 (4 crates) | 400 | 126 | 148 |
| D-change | 8 multi-crate | 340 | 102 | 183 |

STEP 3: Read first:
- @Instructions/PLAYBOOK.md (12-shape taxonomy, evidence from 13 approveds)
- @Instructions/DESCRIPTION.md, TESTS.md, SOLUTION.md, DOCKER.md
- @Olympus-Approved/Feature-Requests/<closest-shape> (use as scaffolding)

STEP 4: Propose 3–5 Mars feature ideas. For each, identify shape and estimate file/LOC fit.

STEP 5: For the best one, provide:
- meta.md (per shape's word count, plain prose, action-verb title, backticks for API surface, blind-spot pre-empts from DESCRIPTION.md)
- Test strategy: ONE new test file with builder helpers + assertion helpers + scenario-encoded names. Cover every behavior, API, branch, and standard edge cases. Substring-match for errors.
- Solution sketch: pure-function helpers extracted, fixpoint loops if shape A2/D
- Files to modify and create
- Estimated LOC against shape band

Calibration (shape-specific):
- Target Nova pass rate per shape (10-55% depending on shape)
- 1–2 precision words that trip Nova ("subjects" not "commits")
- 1 edge case Nova wouldn't think to test itself
- For Shape A1: aim for diverse failure modes (Missed/Regression/Integration)
- For Shape D-new: include exhaustive-match risk; multi-target test.sh
- For Shape D-change: existing variant's old shape must be everywhere updated

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/DOCKER.md for Dockerfile standards
- @Instructions/WORKFLOW.md for end-to-end process
- @Instructions/RULES.md for review checklist and tier matrix
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus-Approved/Feature-Requests/<closest-shape> for approved Mars examples
- @Olympus-Approved/ for approved Olympus examples
```

---

## Query 2: Solve an Existing Issue

For solving an existing GitHub issue at either tier.

**Parameters:**
- `REPO_URL`, `ISSUE_NUM`, `BASE_COMMIT`, `WORKSPACE`

**Test design rules** (applied to all generated tests):
- Behavior-focused, not implementation-specific
- Generalized — don't hardcode error messages or method names
- Tests should work with any correct implementation
- Hard tests should be interdependent behavioral edge cases for better complexity

**Prompt:**
```
Build a Mars or Olympus challenge around issue #{ISSUE_NUM} in {REPO_URL}.

Read first:
- @Instructions/PLAYBOOK.md
- @Instructions/WORKFLOW.md (end-to-end process)
- @Instructions/*.md (per-deliverable rules)

Steps:
1. Clone {REPO_URL} and checkout {BASE_COMMIT}; save BASE_COMMIT.txt immediately
2. Read the issue thoroughly including ALL comments
3. Pick the closest approved problem in @Olympus-Approved/Feature-Requests/<closest-shape> as scaffolding
4. Sketch the solution outline FIRST (helpers, fixpoint loops, public API surface)
5. Write meta.md (action-verb title, plain prose, tier word cap)
6. Write tests covering every described behavior, every public API, every solution branch, and standard edge cases
7. Implement solution with pure-function helpers
8. Generate test.patch and solution.patch against {BASE_COMMIT}
9. Build Dockerfile (Pattern A for Rust workspaces, Pattern B for Python/JS/Go)
10. Verify locally: docker run --user 1000:1000 --network none

Hard requirements:
- All new tests FAIL on base, PASS with solution; base tests still PASS
- test.sh accepts --output_path, base/new modes, JUnit XML with build-failure fallback
- No debug statements, no AI-style comments, no drive-by refactors
- Match repo conventions exactly

Workspace: {WORKSPACE}
Tier: pick at submit time. Mars Solid default; switch to Olympus only if sketched solution is 600+ LOC across 10+ files.

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/DOCKER.md for Dockerfile standards
- @Instructions/WORKFLOW.md for end-to-end process
- @Instructions/RULES.md for review checklist and tier matrix
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus-Approved/Feature-Requests/ for approved Mars examples
- @Olympus-Approved/ for approved Olympus examples
```

---

## Query 3: Find Candidate Repositories

For discovering new repos suitable for either tier.

**Parameters:**
- `EXAMPLE_REPOS` — known good repos to find similar ones
- `EXAMPLE_PROBLEMS` (optional) — approved problems for complexity reference
- `SEARCH_CRITERIA` (optional) — language, features, and quality requirements

**Prompt:**
```
Find open-source repositories similar to {EXAMPLE_REPOS} for Shipd challenges.

Hard requirements:
- ≥500 GitHub stars
- TypeScript, JavaScript, Python, Go, Rust, Java/JVM, or C/C++ (Java/C++ re-enabled — 2026-05-14 disable reverted)
- Active (≥1 commit in last 12 months)
- Permissive license (MIT, BSD, Apache, Boost, CC-BY — NOT GPL/AGPL)
- Pure language implementation (no C bindings preferred — easier to clone, test, Docker-build)
- Repo should not already exist in the workspace
- 100-1000 open issues (sweet spot — under 100 = too narrow, over 1000 = unmaintained sprawl)

Quality criteria:
- Multi-package or multi-module architecture (clear boundaries)
- Behavioral testing through public APIs (not heavy mocking)
- Rich domain logic — parsers, interpreters, optimizers, CLI tools, frameworks
- Solid core but missing features — established patterns + space to extend
- Niche over popular — less agent training data = genuine knowledge gaps
- Test patches should not depend on new API methods — test behavior without needing to know implementation details
- Complex enough for tier targets (Mars ≥100 LOC floor, ≥150 pref, 170-380 observed sweet spot; **Olympus + Diamond ≥450 EFFECTIVE LOC design floor (400 = platform auto-block)** across 3+ files)

For each candidate, list:
- Repository URL and stars
- Primary language
- Domain (parser, framework, CLI, etc.)
- Number of open issues without PRs
- Test framework and organization style
- Docker complexity estimate (Pattern A vs Pattern B, system deps needed)
- Best feature types for Mars (single-subsystem) or Olympus (cross-subsystem)
- Estimated complexity range
- Why it matches the search criteria

Reference good Mars repos: pest, lightningcss (both deep parser/optimizer libraries).
Reference good Olympus repos: bunster, dasel, cliffy (niche, multi-package).

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/RULES.md for repository requirements and license rules
- @Instructions/REPOSITORIES.md for repo metadata and known candidates
- @Olympus-Approved/Feature-Requests/ for approved Mars examples
- @Olympus-Approved/ for approved Olympus examples
```

---

## Query 4: Analyze Repo for Challenges (Codebase-First Deep Dive)

For deep codebase analysis to surface invented challenge ideas. **Issues are ignored** — platform reviewers reject candidates based on existing GitHub issues anyway, so don't waste time browsing them. Pure architecture exploration.

**Parameters:**
- `REPO_URL` — repository to analyze
- `TIER` (optional) — `mars` / `olympus` / `both`. If omitted, ranks across both tiers.

**Prompt:**
```
Analyze {REPO_URL} for invented Shipd challenge ideas. **Do NOT browse issues** — work from codebase architecture only.

Step 1 — Check duplicates
Read approved problem indexes:
  @Olympus Approved/<repo>/                          (if exists)
  @Olympus-Approved/Feature-Requests/<repo>/         (if exists)
Skip features already shipped. Cite duplicate-avoidance evidence inline.

Step 2 — Pre-flight namespace + maintainer-philosophy check (PATTERNS-ADVANCED § Pattern 22)
Before ANY candidate, scan for namespace conflicts and maintainer rejections:
  gh pr list   -R <owner>/<repo> --state all --search "<namespace-prefix>"
  gh pr list   -R <owner>/<repo> --state all --search "<namespace-prefix>" --json
  gh issue list -R <owner>/<repo> --state all --search "<namespace>" --json number,title,comments
Look for "I'd prefer not to", "philosophical", "namespace", "pollute", "by design", maintainer-rejected feature classes. ABANDON any candidate where a related function already exists with same prefix/suffix OR maintainer has rejected the namespace.

Step 3 — Architecture exploration
Read in this order:
  - README + CONTRIBUTING (project philosophy, design constraints)
  - Top-level directory structure (package boundaries)
  - Main entry point + public API surface (exports, public types)
  - 2-3 representative source files in each major package (style, idioms, patterns)
  - Existing test infrastructure (framework, conventions, helpers)
  - Recent commits (last 30 days) — what's actively maintained vs stale

Output: 1-paragraph architecture summary + list of 5-7 top-level subsystems with boundaries.

Step 4 — Identify deeply entangled zones
Find areas where a single behavior change naturally touches MANY files:
  - Cross-package feature surfaces (CLI → core → runtime → tests)
  - Pipeline pass chains (parser → optimizer → codegen → VM)
  - Public API + internal state interactions (e.g., scope chains, registries)
  - Symmetric read/write paths (encoder + decoder, serializer + deserializer)
  - Existing patterns where a NEW variant must integrate everywhere

Output: 3-5 entangled zones with file count + integration hook description.

Step 5 — Generate candidates per shape
For each entangled zone, propose 1-2 candidates fitting a target shape (SHAPES.md § Patterns 11-12):

Mars shapes (target Mars Solid):
  - A1 — distributed pipeline modification (3 files, 10-15% pass)
  - A2 — concentrated + signature change (3 files, 20-25% pass)
  - B — add new public API list (3 files, 50-55% pass)
  - C — additive extension single file (1 file, 20-25% pass)
  - D-new — new cross-crate enum variant (15 files, 20-25% pass)
  - D-change — cross-crate variant signature change (8 files, 40-45% pass)

Olympus shapes (target Olympus Good):
  - O-Composite-extend — refactor aggregation across packages (9+ files, 25-30%)
  - O-Composite-add — new feature spanning parser/compiler/VM (12 files, 15-20%)
  - O-Pipeline-easy — new variant + cascading, familiar algo (5 files, 25%)
  - O-Pipeline-hard — new variant + invent transformation (4 files, 15%)
  - O-Algorithm-coverage — missing-element-in-list trap (4 files, 10%)
  - O-Algorithm-correctness — subtle algorithm trap (6 files, 8%)

For each candidate, fill row:
| Candidate | Shape | One-line behavior | Files mod+new | Sketched +LOC | Predicted Nova pass | Dominant verdict | Reject? |

Step 6 — Reject filter (apply ALL)
Reject any candidate matching:
  ✗ Pattern-followable (3+ identical structural examples already in repo) — agents copy-paste
  ✗ Solvable by standalone new file with minimal wiring
  ✗ Single-file one-liner under 100 LOC
  ✗ Cosmetic refactor / doc-only
  ✗ Bug in dependency, not project
  ✗ Already in `RULES.md § Features already used`
  ✗ Predicted Wrong Logic ≥25% if NOT explicitly designing O-Algorithm-correctness
  ✗ Outside target tier LOC band
  ✗ Step 1 found duplicate
  ✗ Step 2 found namespace conflict OR maintainer-rejected feature class

Step 7 — Rank survivors
Score per candidate:
  - Architecture novelty (1=copy existing pattern / 3=new integration / 5=no precedent)
  - Cross-package scope (1=single package / 3=2-3 packages / 5=5+ with complex wiring)
  - Feature interactions (1=independent / 3=2-3 interact / 5=5+ interacting)
  - State management (1=stateless / 3=ordered pipeline / 5=multi-phase state machine)
  - Edge cases (1=none / 3=3-5 same-object/ordering / 5=edge-case dominated)
Target average: 3-4 across dimensions per `olympus-extreme-complexity-guide.md § Complexity Scoring Rubric`.

Step 8 — Develop top 3 candidates
For each top-3 survivor, provide:
  - meta.md draft (action-verb title, plain prose; recommended cap Mars 240 / Olympus 200; hard cap both 500; no `##` headers, no formulaic labels, no `Box<...>` wrappers; backticks only on new public API names)
  - Apply blind-spot pre-empts from `DESCRIPTION.md § Blind-Spot Pre-Empt Sentence Bank` if applicable
  - Test strategy: 4-block layout (imports → builders → assertion helpers → tests), scenario-encoded names, substring-match for errors, coverage-driven count
  - Solution sketch: pure-function helpers (1+ per behavior), fixpoint loop if iterative, modified-vs-new file ratio
  - Files to MODIFY (list paths) and CREATE (list paths)
  - Estimated raw LOC + meaningful LOC against tier band
  - Predicted trap matrix (2-3 named traps with pre-empt sentence + catching test from `olympus-common-mistakes.md`)

Output (by target tier):
  - If TIER=mars: `mars-candidates.md` with top 5 ranked Mars ideas
  - If TIER=olympus: `olympus-candidates.md` with top 5 ranked Olympus ideas
  - If TIER=both or omitted: both files

Each candidate file has columns: rank, candidate name, shape, files mod+new, sketched LOC, predicted Nova pass, dominant verdict, why-it-matches, full sketch.

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for shape taxonomy (Patterns 11-12) + namespace check (Pattern 22) + trap-stacking ceiling (Pattern 17)
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/DESCRIPTION.md for problem description guidelines + blind-spot pre-empt sentence bank
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/RULES.md for review checklist, tier matrix, features-already-used table
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, institutional knowledge
- @Instructions/olympus-common-mistakes.md for 12 Commandments + Top Proven Failure Patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns + complexity scoring rubric + difficulty hierarchy
- @Olympus Approved/ and @Olympus-Approved/Feature-Requests/ for approved Olympus examples (cite specific approveds)
```

---

## Query 5: Handle Reviewer Feedback

For revising a submission based on reviewer feedback.

**Parameters:**
- `REPO_URL`, `ISSUE_NUM`, `FEEDBACK`, `BASE_COMMIT`, `WORKSPACE`

**Prompt:**
```
A submission for {REPO_URL} issue #{ISSUE_NUM} received feedback:

{FEEDBACK}

Current state:
- Base commit: {BASE_COMMIT}
- Workspace: {WORKSPACE}
- Read eval-results.md for prior agent runs
- Read feedback.md (or feedback-report.md) for feedback and iteration history

Steps:
1. Analyze the reviewer feedback — what specific changes are requested?
2. Categorize feedback: description / test / solution / Dockerfile / patch
3. Read PLAYBOOK.md § Pattern 8 — match feedback to one of the 5 revision buckets
4. Read 21-item review checklist in RULES.md to understand reviewer evaluation criteria
5. Make MINIMUM changes to address feedback (don't over-fix)
6. Re-validate locally:
   - test.sh new FAILS on base
   - test.sh new PASSES with solution
   - test.sh base PASSES always
7. Regenerate affected patches against {BASE_COMMIT}
8. Update meta.md if description changes were requested
9. Ensure clean code: no unused imports/variables/methods, no comments (unless repo convention), follow repository coding style, no whitespace issues in patches
10. Run final sanity check (PLAYBOOK.md § Pattern 10)

Do NOT change anything not mentioned in feedback.

Provide a test report:
- On base code: test.sh base / test.sh new pass/fail counts
- On solution code: test.sh base / test.sh new pass/fail counts

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns and § Pattern 8 (5 revision buckets)
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/DOCKER.md for Dockerfile standards
- @Instructions/RULES.md for review checklist and tier matrix
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md for understanding reviewer phrasing
- @Admin-Review/docs/LESSONS-LEARNED.md for reviewer-side learnings
- @Olympus-Approved/Feature-Requests/ for approved Mars examples
- @Olympus-Approved/ for approved Olympus examples
```

---

## Query 6: Generate Olympus Feature

Use only when sketched solution naturally exceeds Mars Strong (600+ LOC across 10+ files). Otherwise use Query 1 (Mars).

**Design considerations** (apply to every Olympus candidate):
- Feature must be natural for the project (something users would want)
- Must not duplicate existing functionality
- Should exercise core project APIs/patterns
- Tests should work with any correct implementation (no hardcoded method names)
- Think about what would challenge an AI agent
- Consider features that require design decisions across 4-6 interdependent layers
- No network or external dependencies

**Parameters:**
- `REPO_URL` — repository to create feature for
- `SHAPE` (optional) — pin a specific Olympus shape. If omitted, prompt picks best fit.

**Prompt:**
```
Generate an Olympus-tier feature request challenge for {REPO_URL}.

STEP 1: Identify the Olympus shape FIRST. Each has different best-agent profile.

Olympus shape selector (see SHAPES.md § Pattern 12):
- O-Composite-extend — refactor existing aggregation across packages. Pass 25-30%. Best agent: Orion (2/2 on dagster).
- O-Composite-add — add new feature spanning parser/compiler/VM/runtime. Pass 15-20%. Best agent: Vega (3/5 on goja-using).
- O-Pipeline-easy — new variant + cascading effects, familiar coalescing algorithm. Pass 25%. Best agent: Vega (3/5 on charclass).
- O-Pipeline-hard — new variant + cascading, invent transformation algorithm. Pass 15%. Best agent: Vega (2/6 on seq-rewriter).
- O-Algorithm-coverage — new variant + missing-element-in-list trap. Pass 10%. Best agent: Orion-alone (1/1 on inliner).
- O-Algorithm-correctness — new variant + subtle algorithm correctness. Pass 8%. Best agent: Mixed.
- O-Trap (HISTORICAL ONLY) — universal LLM blind spot at 0% pass. NO LONGER VIABLE post-April 2026.

DO NOT design for O-Trap shape — solvability cannot be bypassed. If you sketch a problem and predict a universal blind spot, redesign it or downgrade to Mars.

STEP 2: Apply shape-specific targets:
| Shape | Files | Solution LOC | Tests | Best Agent |
| O-Composite-extend | 9+ | 600 | 162 | Orion |
| O-Composite-add | 12 | 366-700 | 73 | Vega |
| O-Pipeline-easy | 5 | 433 | 104 | Vega |
| O-Pipeline-hard | 4 | 413 | 103 | Vega |
| O-Algorithm-coverage | 4 | 379 | 68 | Orion-alone |
| O-Algorithm-correctness | 6 | 532 | 62 | Mixed |

STEP 3: Read first: @Instructions/PLAYBOOK.md, RULES.md, @Olympus-Approved/Feature Requests/<closest-shape>

STEP 4: Run complexity test:
- Modifies 5+ existing files with complex logic? Required for Olympus
- Cross-subsystem entanglement? Required
- Pattern-followable (3+ identical examples in repo)? REJECT
- First-attempt naturally breaks existing tests? Good

STEP 5: Propose 3-5 Olympus ideas. For each, identify shape and predict pass rate.

STEP 6: For the best one (most modified existing files, matching shape band):
- meta.md (≤200 words recommended, hard cap 500; behavior-focused, blind-spot pre-empts from DESCRIPTION.md)
- Test strategy covering every behavior, every API, every solution branch, every edge case
- Files to MODIFY (list) and CREATE (separately)
- Estimated LOC against shape band

Calibration:
- 52% of agent failures are MISSED_REQUIREMENT — precision wording is #1 lever
- 10+ interacting requirements (not 5-7)
- 1 codebase-inferable requirement (visible in code, not description)
- Best problems: agent scores 56/57 or 116/117 (near-miss)
- Trip words: "subjects" vs "commits", "unbounded" vs "non-aggregated"
- Modified-to-new file ratio matters — passing Olympus agents modify 14-18 files
- WRONG_LOGIC ≥25% signals subtle algorithmic trap (O-Algorithm shapes)
- Solvability cannot be bypassed; hints removed April 2026 for Mars + Olympus (Diamond keeps the hint flow)
- If 0% on Olympus → resubmit as Mars (≤ 30% Nova band usually reachable)

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns and § Pattern 12 (Olympus shape taxonomy)
- @Instructions/AGENTS.md for Vega/Orion/Nova profiles and cross-agent blind spots
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/DOCKER.md for Dockerfile standards
- @Instructions/RULES.md for review checklist and tier matrix
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus-Approved/ and @Olympus-Approved/ for approved Olympus examples
```

---

## Query 7: Diamond-Tier Task (Post-Relaunch 2026-05-13)

Use when creating or iterating on a Diamond-tier problem. **Diamond Relaunch 2026-05-13** introduces automated Diamond Checks preflight + ≤30% Castor pass-rate ceiling + Discord channels deprecated.

**Parameters:**
- `REPO_URL` — GitHub repository URL
- `ISSUE_NUM` — issue number (or feature description)
- `BASE_COMMIT` — commit hash to build on
- `WORKSPACE` — local workspace path
- `PHASE` — current phase: create | smoke-test | eval | diamond-checks | hint | auto-review | qa | failure-qa | review-feedback

**Prompt:**
```
You are working on a Diamond-tier Olympus task for {REPO_URL} issue #{ISSUE_NUM}.

Phase: {PHASE}
Base commit: {BASE_COMMIT}
Workspace: {WORKSPACE}

Read ALL of these before starting:
- @Instructions/DIAMOND.md for Diamond-specific requirements + post-relaunch pipeline + staleness rules
- @Instructions/lessons-learned.md § Diamond Relaunch Pipeline + § Diamond-Tier Lessons
- @Instructions/KNOWLEDGE.md § Diamond-Tier Cross-Cutting Behavior
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus-Approved/ for examples of approved submissions

Post-relaunch pipeline (only proceed after addressing prior step):
1. Prechecks + Postchecks
2. Smoke test (1x Castor or 1x Vega — env blocker insurance)
3. 10x Castor + Diamond Checks preflight (50 tokens / 30min-1hr)
4. If 0% pass → add hint → 10x Castor (hinted) + Diamond Checks (hinted)
5. Holistic AI Review (sanity check)
6. Auto Review → "approved for QA" badge
7. Add QA artifacts
8. Final QA Review for iterating QA artifacts (won't stale Castor/Diamond Checks)
9. Submit → reviewer pass → finalization

=== PHASE: create ===
1. Follow standard Query 2 workflow (clone, analyze, tests, solution, patches)
2. Design at least one "same-object interaction" test (the #1 Diamond trap)
3. Design at least one ordering/cancellation test where push-before-check matters
4. Create feedback.md and eval-results.md from day one
5. Target ≤30% Castor pass rate (1-3 of 10) — tighter post-relaunch ceiling
6. Default to tighter description proactively (Castor capability has grown)

=== PHASE: smoke-test ===
1. Run 1x Castor (or 1x Vega) BEFORE committing to 10x full run
2. Check: Docker builds, JUnit XML produced, base passes, new fails appropriately
3. Fix env blockers / obvious defects before spending 10x Castor tokens

=== PHASE: diamond-checks ===
1. Run Diamond Checks preflight pipeline (50 tokens / 30min-1hr)
   - Rollouts: 45 tokens per rollout job (3 rollouts per job)
   - Code Validation: 15 tokens
   - Full Environment QA: 20 tokens
2. Address ALL surfaced issues BEFORE proceeding to Auto Review
3. Plan: changes to description/test patch/solution patch/dockerfile/repo+commit stale Diamond Checks → re-run

=== PHASE: eval ===
1. Parse evaluation results (agent name, verdict, tests passed/failed, LOC, messages)
2. Update eval-results.md with per-agent breakdown
3. Update feedback.md with high-level summary
4. Identify which tests trapped which agents and why
5. If pass rate >30% → too easy → tighten description (Tighten-First per lessons-learned) before adding tests
6. If pass rate 0% → proceed to hint phase

=== PHASE: hint ===
**Use Top-Down Pruning method** (saves ~50% tokens vs trial-and-error). See `DIAMOND.md § Hint Authoring Discipline` + `DIAMOND-PLAYBOOK.md § Section 4`.

1. **Read 3-4 top failing Castor runs** from this submission's eval-results.md + Castors/ trajectories. Find exact failure point + cascading downstream traps in each.
2. **Analyze:** which failures are upstream gates (block agents from reaching downstream traps)? Which are downstream consequences (only visible after upstream resolved)?
3. **Draft MAXIMUM hint** in Shipd UI hint section (NOT meta.md). Over-spec'd, guaranteed 8-10/10 pass = ceiling reference.
4. **Map each hint sentence to meta.md** — find originating sentence. Mark as removable if meta implies it OR repo provides inference.
5. **Prune ONE-BY-ONE** — remove most-obviously-derivable first, probe with 1 Castor, restore if pass rate drops. Continue until minimal-non-ambiguous.
6. **Run 10x Castor hinted** + Diamond Checks (hinted half of pipeline) once final.
7. **At least some runs must succeed with hint** (no fixed minimum per admin Leonard 2026-05-28). Ceiling sanity: if all 10 pass, unhinted meta too ambiguous.

**Pruning anti-patterns to avoid:**
- Removing trap-disambiguation sentence (Section 1 trap category match) — pass rate collapses
- Removing spec-bridge sentence (links meta.md to test's expected value) — ambiguity returns
- Removing multiple at once — can't isolate which was load-bearing

**Hint validity rules (admin Leonard 2026-05-28):**
- Valid: human expert with description+repo could infer it (library/version specifics OK)
- Invalid: implementation details (helper names, algorithm steps, file paths, test-side facts)
- Each hint requires "why inferrable" justification (1-2 sentences citing spec/repo evidence)

=== PHASE: auto-review ===
1. Run Holistic AI Review (sanity check)
2. Run Auto Review (replaces reviewer green-light)
3. On "approved for QA" badge → proceed to QA artifacts

=== PHASE: failure-qa ===
Write failure-qa.md for each failed Castor run. Follow these rules strictly:
- No trajectory step references ("At step 21...")
- No cross-run comparisons ("Same bug as Castor #1")
- Every entry has concrete expected-vs-actual values
- Separate spec text from inference explicitly
- Describe final code state only, not development sequence
- Each entry must stand alone (no "same as above")
- Use public API names (getAliasRegistry(), clearRegisteredAliases())
- Don't fabricate variable names you haven't verified
- Cancellation cases: lead with observed failure, then cause
- Plain ASCII only, no em dashes, no Unicode
- Verify every factual claim against the actual test code
- No fix suggestions unless verified against the exact failing test path

=== PHASE: review-feedback ===
1. Read the reviewer feedback carefully
2. Identify every specific issue flagged
3. Fix each issue precisely without introducing new problems
4. Update failure-qa.md with corrections
5. Update DIAMOND.md lessons if the reviewer taught something new
6. Verify plain ASCII, no fabricated names, concrete values
7. Each entry self-contained, inference explicitly framed
```

---

## Query 8: Lite Issue Resolution

Use when solving an issue for the Lite tier. Lite has LOWER complexity thresholds (≥100 LOC, ≥1 file) but the SAME difficulty target — agents must still struggle. The problem must NOT be trivially solvable by pattern-following.

**Parameters:**
- `REPO_URL` — GitHub repository URL
- `ISSUE_NUM` — issue number
- `BASE_COMMIT` — commit hash to build on
- `WORKSPACE` — local workspace path

**Prompt:**
```
You are working on the Olympus project (LITE TIER). Your task is to solve GitHub issue #{ISSUE_NUM} in {REPO_URL}.

CRITICAL: Lite tier means LOWER complexity thresholds, NOT lower difficulty.
The problem must still be genuinely hard for SOTA AI agents.

Lite tier thresholds:
- Solution: ≥100 LOC (not 400+)
- Files: ≥1 file (not 3+)
- Nova median messages: ≥1 (not 100+)
- Pass rate target: ≤60% (at most 7 out of 12 agents pass)

All other rules are IDENTICAL to standard Olympus — description quality, test rules,
behavioral focus, no comments, JUnit XML, Dockerfile, patch generation. The only
difference is the complexity floor.

WHAT MAKES LITE HARD (not easy with fewer lines):
- The solution is compact but requires NON-OBVIOUS reasoning to arrive at
- Cross-cutting concerns: fixing one path breaks another unless both are understood
- Subtle behavioral interactions between features that share state or pipelines
- Edge cases where the naive/obvious implementation fails in non-trivial ways
- Implementation requires understanding internal architecture, not just public APIs

WHAT FAILS AS LITE (reject immediately):
- Collections of independent utility functions (deep-equal, clamp, pad, hex-convert)
- Stdlib wrappers (filepath.Match, strconv.FormatInt, strings.Repeat)
- Pattern-followable features where existing code provides a copy-paste template
- Any problem where each sub-task is independently solvable without understanding others
- "Add N functions to namespace X" — agents implement each one trivially

1. Clone the repository and checkout the base commit: {BASE_COMMIT}
2. Read the issue thoroughly, including ALL comments
3. Analyze the codebase to understand the affected area
4. Write comprehensive tests (8-25) that fail on the base code
   - Behavior-focused, not implementation-specific
   - Generalized — don't hardcode error messages or method names
   - Tests should work with any correct implementation
   - Hard tests should be interdependent behavioral edge cases
   - Apply anti-agent design patterns from @Instructions/olympus-extreme-complexity-guide.md
5. Implement the solution (100+ lines across 1+ files)
6. Generate test.patch and solution.patch against BASE_COMMIT
7. Create meta.md with problem description (BEHAVIOR not implementation, for word count range check @Instructions/DESCRIPTION.md)
8. Create Dockerfile using language-specific slim image: `public.ecr.aws/d3j8x8q7/olympus-base-{python|typescript|go|rust|cpp|jvm}:latest` (CMD ["/bin/bash"]).

Requirements:
- NO comments in test or solution code
- NO debug statements
- All tests must FAIL on base code and PASS with solution
- test.sh with base/new modes and --output_path JUnit XML support
- Solution should be 100+ lines of actual code changes
- No AI slop (verbose boilerplate, over-commented, auto-generated code)
- Difficulty is paramount — a compact problem that agents can't solve is better
  than a large problem that all agents pass

Workspace: {WORKSPACE}

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus-Approved/ for examples of approved submissions
```

---

## Query 9: Analyzing & Suggesting Lite Challenges (Codebase-First)

Use when analyzing a repository for Lite-tier Olympus problems. **Issues ignored** — pure codebase exploration. Lite means LOWER complexity thresholds but the SAME difficulty bar.

**Parameters:**
- `REPO_URL` — repository to analyze

**Prompt:**
```
Analyze {REPO_URL} for invented Lite-tier Olympus challenge candidates. **Do NOT browse issues** — work from codebase architecture only.

CRITICAL CONTEXT: Lite tier has lower LOC/file thresholds but the SAME difficulty target as standard Olympus. Problems must be genuinely hard for SOTA AI agents, not trivial tasks with small code changes.

Lite tier thresholds:
- Solution: ≥100 LOC, ≥1 file
- Nova median messages: ≥1
- Pass rate target: ≤60% (at most 7 out of 12 agents pass)
- Same quality rules as standard (description, tests, behavioral focus, no comments)

REJECT THESE IMMEDIATELY (proven 80-100% agent pass rate):
- Collections of independent utility functions (e.g., pad/repeat/reverse/clamp/deepEqual)
- Stdlib wrappers (filepath.Match, strconv.FormatInt, math.Copysign)
- "Add N functions to namespace X" where each function is independently solvable
- Pattern-followable features where existing code provides a copy-paste template
- Any concept with massive training data: deep equality, deep clone, set operations, hex/binary conversion, path manipulation, basic math utilities
- Guard-clause bug fixes (division-by-zero checks, negative index handling)

PRIORITIZE THESE (proven low pass rates):
- Cross-cutting concern interactions where fixing one path breaks another
- Pipeline ordering traps where the obvious execution order fails
- Same-object edge cases where two features interact on the same entity
- Convenience method vs constructor traps (calling existing setup includes wrong defaults)
- Bugs requiring understanding of compiler/VM internals, not just public API
- Formatter/serializer idempotence issues requiring multi-path fixes
- Resource lifecycle bugs across multiple exit paths (LIMIT, FILTER, error, nested)

Step 1 — Check duplicates
Read approved indexes (avoid shipping a Lite version of an existing approval):
  @Olympus Approved/<repo>/                          (if exists)
  @Olympus-Approved/Feature-Requests/<repo>/         (if exists)
Check `problems/` and `diamond-problems/` for pending submissions.

Step 2 — Pre-flight namespace + maintainer-philosophy check (PATTERNS-ADVANCED § Pattern 22)
Before any candidate, scan for namespace conflicts and maintainer rejections:
  gh pr list   -R <owner>/<repo> --state all --search "<namespace-prefix>"
  gh issue list -R <owner>/<repo> --state all --search "<namespace>" --json number,title,comments
ABANDON any candidate where related function exists with same prefix/suffix OR maintainer has rejected the namespace.

Step 3 — Read instructions
- @Instructions/lessons-learned.md
- @Instructions/KNOWLEDGE.md (agent behavioral profiles + confirmed traps)
- @Instructions/AGENTS.md (cross-agent blind spots)
- @Instructions/PLAYBOOK.md (16 patterns + shape taxonomy + Pattern 22 namespace check)
- @Instructions/olympus-common-mistakes.md (proven mistakes + 12 Commandments + Top Failure Patterns)
- @Instructions/olympus-extreme-complexity-guide.md (anti-agent design patterns)

Step 4 — Codebase architecture analysis
Read in this order:
- README + CONTRIBUTING (project philosophy, design constraints)
- Top-level directory structure (package boundaries)
- Main entry point + public API surface
- 2-3 source files in each major package (style, idioms)
- Existing test infrastructure (framework, conventions)
- Recent commits (last 30 days) — actively maintained zones

Output: 1-paragraph architecture summary + 3-5 zones where compact-but-hard features could live.

Step 5 — Identify high-density traps
Lite candidates need ONE dominant trap, not breadth. Look for:
- Subtle behavioral interactions between features sharing state or pipelines
- Edge cases where naive implementation fails non-trivially
- Bugs requiring compiler/VM/internal-architecture knowledge (not public API)
- Pipeline ordering where obvious execution order fails
- Same-object edge cases (two features interact on same entity)
- Convenience method that calls public default-init (includes wrong defaults)
- Formatter/serializer idempotence (round-trip data preservation)
- Resource lifecycle across multiple exit paths

Step 6 — Generate candidates
For each high-density trap zone, propose 1-2 Lite candidates. Per candidate, fill row:
| Candidate | Dominant trap | Anti-agent pattern (cite section) | Files mod+new | Sketched +LOC | Predicted Nova pass | Reject? |

Step 7 — Reject filter
Apply these rejects:
✗ Pattern-followable (3+ identical examples in repo)
✗ Core concept well-known to LLMs (deep equality, set operations, hex conversion)
✗ Codebase has copy-paste template
✗ Doesn't require novel architectural reasoning
✗ Network or 3rd-party dependency required
✗ Already implemented (grep verified)
✗ Step 1 found duplicate
✗ Step 2 found namespace conflict OR maintainer rejection
✗ Bug-fix candidate that's a guard clause (div-by-zero, neg-index)

Step 8 — Rank survivors
Score per candidate (DIFFICULTY FIRST, then complexity fit):
1. Agent difficulty — will SOTA agents struggle? (most important)
2. Non-pattern-followable — no copy-paste template in codebase
3. Cross-cutting — solution touches multiple interacting subsystems
4. Complexity fit — 100-400 LOC across 1-3 files
5. Testable without network/3rd-party
6. Code implementation focused (not config/docs)
7. Tests behavior-focused and generalizable

Step 9 — Develop top 3
For each top-3 survivor:
- Draft problem description (BEHAVIOR not implementation, ≤200 words recommended, hard cap 500)
- Test strategy outline (4-block layout, generalized assertions, 8-25 tests)
- Solution approach sketch (pure-function helpers, file count)
- Estimated line count and file count
- What makes this genuinely HARD despite being compact
- Which anti-agent design pattern applies (cite `olympus-extreme-complexity-guide.md` section)
- Predicted trap matrix (1-2 named traps with pre-empt sentence + catching test)

Output:
- `lite-candidates.md` — top 10 ranked Lite ideas with full sketch on top 3
```

---

## Query 10: Generate Tier-Agnostic Feature Request (No Issue)

Use when creating an invented feature request from scratch (no GitHub issue, no candidate from analysis). Tier decided AFTER the sketch lands. Complements Q1 (Mars-specific) and Q6 (Olympus-specific).

**When to pick this over Q1 / Q6:**
- You don't yet know the right tier — let the sketched LOC + file count decide
- You want quality-first ideation: 3–5 candidates, pick the best, classify tier last
- The repo is unfamiliar — broader exploration before locking shape

**Parameters:**
- `REPO_URL` — repository to create feature for

**Prompt:**
```
Generate a feature request challenge for {REPO_URL}.

Requirements:
- Feature must be natural for the project (something users would want)
- Must NOT duplicate existing functionality
- Should exercise core project APIs/patterns
- Tests must work with any correct implementation (no hardcoded method names)
- No network or external dependencies
- Behavior-focused tests, not implementation-specific
- Solution complexity sets tier (decided AFTER sketch):
    Mars Solid: 170–380 LOC across 1–8 files (mode 3)
    Mars Strong: 380–600 LOC across 6–12 files
    Olympus Good: 600+ LOC across 10–20 files
    Olympus Excellent: 800–1500+ LOC across 20+ files
- Test count is COVERAGE-DRIVEN, not target-driven (Mars approveds 39–160; Olympus 14–162)

Steps:
1. Check existing approveds for duplicates:
   - @Olympus Approved/ and @Olympus-Approved/Feature-Requests/ (Olympus approveds)
2. Run namespace + maintainer-philosophy check (PATTERNS-ADVANCED § Pattern 22):
   gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
   gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"
   gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments
   ABANDON if existing function shares prefix/suffix OR maintainer has rejected the namespace.
3. Analyze codebase architecture (multi-package boundaries, deeply entangled zones, integration hooks)
4. Read instruction files (in order):
   - @Instructions/PLAYBOOK.md (lean core: patterns 1-16 + approveds tables + appendices)
   - @Instructions/SHAPES.md (Pattern 11-13: shape taxonomy + best-agent matrix)
   - @Instructions/PATTERNS-ADVANCED.md (Pattern 17-33: trap-stacking ceiling, namespace expansion, triviality, post-base activity)
   - @Instructions/PROBLEM-PROFILES.md (per-problem behavioral data + iteration lessons — open closest shape match)
   - @Instructions/AGENTS.md (per-agent profiles + cross-agent blind spots + failure categories)
   - @Instructions/RULES.md (21-item review checklist + tier matrix + Real Revert Causes)
   - @Instructions/lessons-learned.md (retrospective patterns from approved submissions)
   - @Instructions/KNOWLEDGE.md (agent behavioral profiles, confirmed traps, institutional knowledge)
   - @Instructions/olympus-common-mistakes.md (proven mistakes + 12 Commandments + Top Proven Failure Patterns)
   - @Instructions/olympus-extreme-complexity-guide.md (anti-agent design patterns + difficulty hierarchy)
5. Identify gaps or natural extensions in the codebase. Avoid pattern-followable features (3+ identical structural examples in repo = automatic 100% pass rate)
6. Propose 3–5 feature ideas. Per idea, fill this row:
   | Candidate | One-line behavior | Shape (PLAYBOOK § 11–12) | Files modified+new | Sketched +LOC | Predicted Nova pass | Dominant verdict | Reject? |
7. For the best surviving candidate, provide:
   - meta.md draft (action-verb title, plain prose; recommended cap Mars 240 / Olympus 200; hard cap both 500; no `##` headers, no formulaic labels, no `Box<...>` wrappers; backticks only on new public API names)
     - For word budget by shape see @Instructions/DESCRIPTION.md § Word Budget by Shape
     - Apply blind-spot pre-empt sentences from @Instructions/DESCRIPTION.md § Blind-Spot Pre-Empt Sentence Bank
   - Test strategy: 4-block layout (imports → builders → assertion helpers → tests), scenario-encoded snake_case names, substring-match for errors, coverage-driven count
   - Solution sketch: pure-function helpers extracted (1+ per behavior), fixpoint loop if iterative, modified-vs-new file ratio
   - Files to modify and create (cite exact paths)
   - Estimated raw LOC + meaningful LOC against tier band
   - Predicted trap matrix (2–3 named traps, each with pre-empt sentence + catching test)
   - Predicted Wrong Logic % (≥25% signals subtle algorithmic trap → Olympus territory)

Tier classification (decided AFTER sketch, not before):
   - Sketch lands 170–380 LOC, 1–8 files, predicted Nova **≤ 30%** (~2+ traps) → Mars Solid
   - Sketch lands **400+ EFFECTIVE LOC (HARD FLOOR — auto-review triggers below)**, 8+ files, predicted Nova ~10% → Olympus
   - Sketch lands 600+ LOC, 10+ files, 10+ interacting requirements → Olympus Good

Calibration anchors:
- Think about what would challenge an AI agent (cite specific blind spots from AGENTS.md § Confirmed Blind Spots)
- Consider features that require design decisions (multiple valid approaches, only one matches tests)
- Cross-feature interaction tests > single-feature tests (PLAYBOOK § Pattern 9)
- Same-object edge cases > parent-child cases (the #1 Diamond trap per olympus-common-mistakes Commandment 10)

Reference files:
- @Instructions/ for all rules and standards
- @Instructions/PLAYBOOK.md for evidence-based patterns from approved problems
- @Instructions/AGENTS.md for cross-agent blind spots and per-agent profiles
- @Instructions/DESCRIPTION.md for problem description guidelines
- @Instructions/TESTS.md for test writing guidelines
- @Instructions/SOLUTION.md for solution guidelines
- @Instructions/DOCKER.md for Dockerfile standards
- @Instructions/WORKFLOW.md for end-to-end process
- @Instructions/RULES.md for review checklist and tier matrix
- @Instructions/lessons-learned.md for key insights from approved submissions
- @Instructions/KNOWLEDGE.md for agent behavioral profiles, confirmed traps, and institutional knowledge
- @Instructions/olympus-common-mistakes.md for proven mistakes to avoid and agent failure patterns
- @Instructions/olympus-extreme-complexity-guide.md for anti-agent design patterns and difficulty tuning
- @Olympus Approved/ and @Olympus-Approved/Feature-Requests/ for approved Olympus examples
```

---

## Query 11: Build Submission from Picked Candidate (Analysis Folder)

Use when you already have an `analysis-folders/<repo>-analysis/` folder (ASSESSMENT.md + mars-candidates.md / olympus-candidates.md / lite-candidates.md + PROMPTS.md) and have picked ONE candidate to build end-to-end. Agent skips Phases 1-3 of DESIGN-TEMPLATE (already done in analysis folder) and produces DESIGN.md → 5 deliverables → validated submission.

**When to pick this over Q1/Q2/Q6/Q7/Q8/Q10:**
- Analysis folder exists with verified ASSESSMENT.md (13-gate pass)
- Candidate already proposed + ranked + reject-filtered in `*-candidates.md`
- You just want the build phase, not re-discover the candidate

**Parameters:**
- `REPO_URL` — from `ASSESSMENT.md § Repo`
- `BASE_COMMIT` — from `ASSESSMENT.md § Base commit` (already 13-gate verified)
- `REPO_PATH` — local clone path (typically `worktrees/<repo>/`)
- `ANALYSIS_PATH` — path to `analysis-folders/<repo>-analysis/`
- `FEATURE_NAME` — candidate row identifier (e.g., `M1`, `O2`, `L3` — references row in `*-candidates.md`)
- `FEATURE_BRIEF` — 2-5 sentence description: what the feature does + which subsystem it touches + key public API names. Pulled from candidate row "One-line behavior" + your extension. The agent fills out the full 14-section DESIGN.md from this brief + the analysis context.

**Prompt:**
```
Build an Olympus submission for candidate {FEATURE_NAME} from {ANALYSIS_PATH}.

Inputs:
- REPO_URL:        {REPO_URL}
- BASE_COMMIT:     {BASE_COMMIT}  (already 13-gate verified in ASSESSMENT.md)
- REPO_PATH:       {REPO_PATH}
- ANALYSIS_PATH:   {ANALYSIS_PATH}
- FEATURE_NAME:    {FEATURE_NAME}
- FEATURE_BRIEF:   {FEATURE_BRIEF}

═══════════════════════════════════════════════════════════════
PHASE 0 — Load analysis context (DO NOT redo Phases 1-3 of DESIGN-TEMPLATE)
═══════════════════════════════════════════════════════════════
Read these files in order. They contain the work already done:

1. {ANALYSIS_PATH}/ASSESSMENT.md
   - § 13-gate verification (repo viability — already PASS)
   - § Architecture summary (5 subsystems + 3 entangled zones)
   - § Dockerfile constraints (any pinned versions, build-time gotchas)
   - § Per-module cold build timing
   - § Test framework + conventional test file location

2. {ANALYSIS_PATH}/mars-candidates.md (or olympus-candidates.md / lite-candidates.md)
   - Find the row matching {FEATURE_NAME}
   - Pull: shape, files mod+new, sketched +LOC, predicted Nova pass, dominant verdict
   - Confirm Reject? = KEEP

3. {ANALYSIS_PATH}/PROMPTS.md
   - Read the prompts that generated the analysis (audit trail)
   - Note any candidate-specific reasoning

4. Read instruction files (in order):
   - @Instructions/PLAYBOOK.md (lean core: patterns 1-16 + approveds tables + appendices)
   - @Instructions/SHAPES.md (Pattern 11-13: confirm the candidate's shape)
   - @Instructions/PATTERNS-ADVANCED.md (Pattern 17 trap-stacking + Pattern 22 namespace + Pattern 23 triviality if applicable)
   - @Instructions/PROBLEM-PROFILES.md (open closest shape/repo match for scaffolding)
   - @Instructions/DESCRIPTION.md (meta.md + blind-spot pre-empt sentence bank)
   - @Instructions/TESTS.md (4-block layout + JUnit XML + banned filename markers)
   - @Instructions/SOLUTION.md (helper extraction + fixpoint loops)
   - @Instructions/DOCKER.md (Pattern A vs Pattern B + slim language images)
   - @Instructions/WORKFLOW.md (end-to-end + per-step checklists)
   - @Instructions/RULES.md (21-item checklist + Real Revert Causes)
   - @Instructions/AGENTS.md (Confirmed Blind Spots for the picked agent)
   - @Instructions/DESIGN-TEMPLATE.md (14-section structure — you will produce DESIGN.md per this template, but skip Phases 1-3 since analysis folder did them)
   - @Instructions/lessons-learned.md (cross-cutting iteration lessons)
   - @Instructions/KNOWLEDGE.md (agent profiles + Diamond cross-cutting if Diamond)
   - @Instructions/olympus-common-mistakes.md (12 Commandments + Top Proven Failure Patterns)
   - @Instructions/olympus-extreme-complexity-guide.md (anti-agent design + complexity rubric)

5. Open scaffolding side-by-side:
   - Closest approved problem matching the candidate's shape in
     @Mars Approved V2/Feature Requests/<closest-shape>/ (Mars)
     OR @Olympus-Approved/Feature-Requests/<closest-shape>/ (Olympus)
     OR @Olympus Approved/<closest-shape>/ (older Olympus)

═══════════════════════════════════════════════════════════════
PHASE 1 — Produce DESIGN.md (14 sections per DESIGN-TEMPLATE.md § Phase 4)
═══════════════════════════════════════════════════════════════
Write `problems/<repo>-<slug>/DESIGN.md` (or `diamond-problems/<slug>/DESIGN.md` for Diamond).

Use the 14-section structure from @Instructions/DESIGN-TEMPLATE.md § Phase 4:

  1. Title (verb-led, 5-10 words, names specific subsystem)
  2. Shape classification (from candidate row + cite SHAPES.md § Pattern 11/12)
  3. Public API surface (5-15 exact names tests will assert)
  4. Canonical output form (sort/associativity/dedup/empty/unicode/negative)
  5. Blind-spot pre-empts (walk DESCRIPTION.md § Sentence Bank, ≤1 codebase-inferable)
  6. Description draft (plain prose, word count per shape, hard cap 500)
  7. File footprint (MODIFY/NEW table against REAL source files; raw + meaningful LOC)
  8. Solution outline (1+ pure-function helper per behavior; fixpoint loop if applicable)
  9. Test file outline (4-block layout, scenario-encoded names, 5-axis coverage)
  10. Forced trait bounds / generics / kwargs (test-first discovery)
  11. Predicted trap matrix (2-3 named traps, each with pre-empt sentence + catching test)
  12. Tier + category decision (Mars Solid / Mars Strong / Olympus / Diamond; enhancement vs feature-request)
  13. Predicted Nova pass rate (must match shape band per SHAPES.md)
  14. Quality-gate checklist (ALL ✓ required to exit Design)

Anchors pulled from analysis folder (paste verbatim, then expand):
  - Shape from candidate row
  - Files mod+new from candidate row
  - Sketched +LOC from candidate row
  - Predicted Nova pass from candidate row
  - Dominant verdict from candidate row
  - Architecture summary from ASSESSMENT.md
  - Test framework from ASSESSMENT.md
  - Dockerfile constraints from ASSESSMENT.md

FEATURE_BRIEF expansion: take the user-provided brief and flesh it out into §§ 3-6 (Public API, Canonical form, Pre-empts, Description draft). FEATURE_BRIEF is the seed; you produce the full design.

═══════════════════════════════════════════════════════════════
PHASE 2 — Self-audit (DESIGN-TEMPLATE.md § Phase 5)
═══════════════════════════════════════════════════════════════
Walk PLAYBOOK § Pattern 8 (5 revision buckets) and answer each:
  - Bucket 1 — Hidden requirements? Any test in §9 not covered by §6 sentence?
  - Bucket 2 — Tech-spec tone? §6 has ## headers or formulaic labels?
  - Bucket 3 — Tests pass on base? §9 includes test not using new API?
  - Bucket 4 — Tests over-constrain? §9 asserts internal-only behavior?
  - Bucket 5 — Solution under tier floor? §7 raw <170 for Mars Solid?

Walk RULES § Real Revert Causes and confirm none apply (20-row table).

Walk AGENTS § Confirmed Blind Spots and confirm any applicable ones have §5 pre-empt.

If any audit fails → fix DESIGN.md before proceeding. Do NOT advance to Phase 3 with audit gaps.

═══════════════════════════════════════════════════════════════
PHASE 3 — Implementation (only after DESIGN.md audit passes)
═══════════════════════════════════════════════════════════════
Build the 5 deliverables per @Instructions/WORKFLOW.md:

  1. BASE_COMMIT.txt           (paste {BASE_COMMIT})
  2. meta.md                   (from DESIGN.md § 6, plain prose, word count per shape, hard cap 500)
  3. test.patch                (includes test.sh)
       - 4-block layout from DESIGN.md § 9
       - scenario-encoded snake_case test names
       - test FILE names use random hex suffix: HASH=$(openssl rand -hex 3)
         → test_{name}_${HASH}.py / {name}.${HASH}.test.ts / {name}_${HASH}_test.go
         NO `shipd` or `datacurve` substrings (banned markers — precheck hard-reject)
       - test.sh: position-independent --output_path arg parsing, base/new modes, JUnit XML
       - Build-failure fallback if Rust
  4. solution.patch            (from DESIGN.md § 8; source files only, no test files, diffed against $BASE_COMMIT)
  5. Dockerfile                (Pattern A `olympus-base-rust` for Rust workspaces, Pattern B language-specific slim `olympus-base-{python|typescript|go|cpp|jvm}` for everything else.)

Patch generation (CRITICAL on Windows):
  - Use patch_gen.py (UTF-8 + LF, no BOM)
  - `chmod +x test.sh && git add --chmod=+x test.sh` BEFORE generating test.patch
  - Verify: `grep "new file mode" test.patch` shows `100755` for test.sh
  - Verify: `file solution.patch` says "ASCII text", NOT "Little-endian UTF-16"
  - Pre-submit guard: `grep -rEl "shipd|datacurve" tests/ test.sh` returns empty

Local validation cycle (Docker):
  git checkout $BASE_COMMIT && git clean -fd
  git apply test.patch && ./test.sh --output_path /tmp/base.xml base    # PASS (no regressions)
  ./test.sh --output_path /tmp/new.xml new                              # FAIL pre-solution
  git apply solution.patch
  ./test.sh --output_path /tmp/base.xml base                            # PASS (still no regressions)
  ./test.sh --output_path /tmp/new.xml new                              # PASS (solution works)

Create from day one:
  - problems/<repo>-<slug>/feedback.md (status + iteration log + reviewer quotes)
  - problems/<repo>-<slug>/eval-results.md (per-agent table per run)

═══════════════════════════════════════════════════════════════
PHASE 4 — Pre-submit sanity check
═══════════════════════════════════════════════════════════════
Walk @Instructions/PLAYBOOK.md § Pattern 10 (5-Minute Sanity Check):
  - Patches apply in BOTH orders (test then solution AND solution then test)
  - Patches unapply cleanly with `git apply -R`
  - Base tests PASS in both orders
  - New tests FAIL pre-solution + PASS post-solution
  - JUnit XML produced in both modes with <testcase> count > 1
  - Solution.patch contains ONLY source files (no test files, no Dockerfile)
  - Test.patch contains ONLY test files + test.sh (no source files)
  - test.sh mode 100755 in patch (NOT 100644)
  - Patches UTF-8 + LF (no BOM, no CRLF)
  - No banned test-filename markers (`shipd`, `datacurve`)

For Diamond submissions: also walk @Instructions/DIAMOND.md § Diamond Checks Pipeline before considering submission ready.

═══════════════════════════════════════════════════════════════
OUTPUT
═══════════════════════════════════════════════════════════════
- `problems/<repo>-<slug>/DESIGN.md`        (14 sections, audit-passed)
- `problems/<repo>-<slug>/BASE_COMMIT.txt`
- `problems/<repo>-<slug>/meta.md`
- `problems/<repo>-<slug>/test.patch`
- `problems/<repo>-<slug>/solution.patch`
- `problems/<repo>-<slug>/Dockerfile`
- `problems/<repo>-<slug>/feedback.md`        (created from day one)
- `problems/<repo>-<slug>/eval-results.md`    (created from day one)

For Diamond: substitute `diamond-problems/<slug>/` for `problems/<repo>-<slug>/`.

Report at the end:
- Local validation results (test.sh base + new in both apply orders)
- DESIGN.md § 14 quality-gate checklist status (all ✓ required)
- Predicted Nova pass rate (must match shape band)
- Predicted tier classification
- Files diff'd against $BASE_COMMIT (not HEAD)
```

---

## Query 12: Assess Diamond Submission Readiness (Pre-Castor Audit)

Use BEFORE spending Castor tokens. Audits a Diamond candidate against `DIAMOND-PLAYBOOK.md` (9 sections) + `CLAUDE.md § CRITICAL RULE` (6-check namespace/philosophy gate). Returns GREEN / YELLOW / RED verdict with specific remediation.

**Cost saved:** A YELLOW/RED catch here = avoid 250-5000 wasted Castor tokens + 1-26 wasted eval rounds.

**Parameters:**
- `SUBMISSION_PATH` — `diamond-problems/<name>/` folder
- `REPO_URL` — target repo
- `BASE_COMMIT` — 40-char hash

**Prompt:**
```
Audit Diamond submission at {SUBMISSION_PATH} for pre-Castor readiness.

Read first (full):
- @Instructions/DIAMOND-PLAYBOOK.md (all 9 sections)
- @Instructions/DIAMOND.md (pipeline + staleness)
- @CLAUDE.md § CRITICAL RULE (6-check protocol)
- @Instructions/PATTERNS-ADVANCED.md § Pattern 22 + Pattern 23 + Pattern 32
- @Instructions/KNOWLEDGE.md § Castor

Submission inputs:
- SUBMISSION_PATH: {SUBMISSION_PATH}
- REPO_URL:        {REPO_URL}
- BASE_COMMIT:     {BASE_COMMIT}

═══════════════════════════════════════════════════════════════
GATE 1 — Maintainer-Philosophy Check (§ Section 9 — HARDEST GATE)
═══════════════════════════════════════════════════════════════
Run all 6 checks from CLAUDE.md § CRITICAL RULE. Document each:

1. Literal name search:
   gh pr list   -R OWNER/REPO --state all --search "<exact-func-name>"
   gh issue list -R OWNER/REPO --state all --search "<exact-func-name>"

2. Namespace expansion search:
   gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
   gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"

3. Maintainer philosophy scan:
   gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments \
     | jq '.[] | select(.comments[]?.body | contains("prefer not to") or contains("don'\''t want") or contains("by design") or contains("namespace") or contains("pollute") or contains("won'\''t add") or contains("rejected"))'

4. Closed-with-implemented scan (catches post-base shipping):
   gh issue list -R OWNER/REPO --state closed --search "<feature-keyword>" --json number,title,comments \
     | jq '.[] | select(.comments[]?.body | contains("implemented") or contains("supported in V") or contains("This is in v"))'

5. Base→main commit overlap (catches maintainer-shipped fix post-base):
   cd /tmp/<repo>-main && git log --oneline <BASE_COMMIT>..HEAD -- <relevant-source-files>

6. Existing-capability functional check:
   build current main HEAD; CLI-test the feature.
   If 80%+ of feature scope already works → REJECT.

ALSO: search closed issues by FEATURE CLASS (not exact API name):
   gh issue list -R OWNER/REPO --state closed --search "<class-keywords>"
   Read top 5 closure comments for "use X instead", "by design", "won't add" language.

VERDICT for GATE 1: GREEN (0 hits) / YELLOW (ambiguous hint) / RED (clear maintainer rejection)

═══════════════════════════════════════════════════════════════
GATE 2 — Triviality Filter (PATTERNS-ADVANCED § Pattern 23)
═══════════════════════════════════════════════════════════════
Does pick satisfy ANY?:
- Pattern-followable (3+ existing funcs in same file/folder match shape)
- Pure additive function ≤50 LOC with no cross-cutting traps
- Stdlib-equivalent (each/map/filter/sum/len/reverse/pick/omit/chunk/zip/partition pattern)
- "Add N functions to namespace X" each independently solvable
- Format wrapper around standard library

Any YES → RED.

═══════════════════════════════════════════════════════════════
GATE 3 — Trap Quality (DIAMOND-PLAYBOOK § Section 1 + § 2)
═══════════════════════════════════════════════════════════════
Read SUBMISSION_PATH/solution-approach.md + test-groups.md + meta.md.

Count named traps fitting Section 1 categories:
- Same-object-as-inherited (★)
- Pipeline ordering / pre-mutation read (★)
- Convenience-method default-leak (★)
- Boundary detection in concurrency (★)
- Wrapper-bypass / authentication coverage (★)
- Null/empty short-circuit (★)
- Sibling-struct duplicate update (★)
- Off-by-one slice/splice (non-★ — single arch)

For each trap verify Section 2 quality bar:
- Admits 2+ natural implementations? (Walk through 2 storage layouts / pipeline orderings / padding placements.)
- Description states 2 facts whose combination forces constraint?
- Operates on a boundary (call/storage/scope/AAD)?
- Test asserts SPECIFIC structural value (count==2, errors.As true, cg[""] exists)?

VERDICT for GATE 3:
- GREEN: 3+ ★ traps, all 4 quality criteria met
- YELLOW: 2 ★ traps OR 1-2 quality criteria missing — strengthen design
- RED: <2 ★ traps OR all single-architecture — reshape required

═══════════════════════════════════════════════════════════════
GATE 4 — Scope Bands (DIAMOND-PLAYBOOK § Section 3)
═══════════════════════════════════════════════════════════════
Measure submission against approved bands. Flag any over-ceiling:

| Metric | Target | Hard rule | Submission value | Status |
|---|---|---|---|---|
| meta.md word count | Follow `DESCRIPTION.md § Word Count` shape-based targets (no Diamond floor; Tighten-First favors shorter) | ≤500 hard cap | (count via wc -w) | |
| Solution +LOC | **≥450 EFFECTIVE LOC design floor (400 = platform auto-block)**; no upper ceiling | Auto-reviewer = raw − blank − comment (braces kept). Verify with canonical command (see top-of-file banner); platform auto-blocks below 400, so design to ≥450 | (count from solution.patch) | |
| Test count | ≥50 floor; coverage-driven | — | (count from test.patch) | |
| Tests per group | ≥6 avg | — | (from test-groups.md) | |
| Public API surface | every name traceable to ≥1 test + 1 meta mention | — | (count new exported names; verify each in tests) | |
| Packages touched | 1 deep OR 2 in pipeline preferred | 3+ adds dilution risk but not banned | (count distinct top-level dirs) | |
| Test files | 1 per package | — | | |
| Pre-empt sentences in meta | ≥5 verbatim trap-disambiguation sentences | — | (count) | |
| Cross-feature test ratio | 20-25% | — | | |
| `##` headers in meta | 0 | 0 enforced | | |
| Title verb | "Add" (6/6 subs) | — | | |
| Cross-feature/matrix group | 1 dedicated group, 7-15 tests stacking 2-4 features | — | | |

VERDICT for GATE 4:
- GREEN: all targets met; word count appropriate for shape (per DESCRIPTION.md); LOC ≥450 design (≥400 auto-block clear); pass rate ≤30% (or no eval data yet but structurally sound)
- YELLOW: 1-2 metrics weak (e.g., <5 pre-empt sentences, missing cross-feature group, sparse groups <6 tests avg) but no hard violations
- RED: hard rule violation (word count >500, missing pre-empts entirely, `##` headers in meta) OR scope-creep evidence (pattern-followable funcs, trimable without losing requirements)

**Important reframings:**
- **No Diamond word-count floor.** Follow `DESCRIPTION.md § Word Count` shape-based targets. 220 words OK if every sentence ties to a test + 5+ pre-empts fit. Tighten-First Rule favors shorter (smaller inference surface = harder problem).
- **No LOC upper ceiling.** Raw LOC over 650 is NOT a reject signal. tengo-crypto ships at 925 LOC with Castor 4/10. Pass rate ≤30% validates difficulty, not LOC.
- **≥450 EFFECTIVE LOC DESIGN FLOOR (400 = platform auto-block).** Below 400 effective → Auto Review fail = guaranteed reject + wasted Castor tokens; design to ≥450 so revisions don't dip back under 400. Sub-floor = STOP and expand scope before submitting.
- See DIAMOND-PLAYBOOK § Section 3 "LOC ceiling is a myth" + Section 8 Rules #14 + #16.

═══════════════════════════════════════════════════════════════
GATE 5 — Deliverable Completeness (DIAMOND-PLAYBOOK § Section 5)
═══════════════════════════════════════════════════════════════
Verify SUBMISSION_PATH contains:
- [ ] BASE_COMMIT.txt (40-char hash matching {BASE_COMMIT})
- [ ] meta.md (440-580 words, plain prose, no `##` headers)
- [ ] test.patch (test.sh mode 100755, position-independent --output_path, JUnit XML, build-failure fallback)
- [ ] solution.patch (source-only, diffed against $BASE_COMMIT, UTF-8 + LF, no BOM)
- [ ] Dockerfile (Pattern A for Rust workspaces / Pattern B `olympus-base-<lang>` slim image)
- [ ] feedback.md (status + iteration log)
- [ ] eval-results.md (per-agent table per run; can be empty if pre-Castor)
- [ ] solution-approach.md REQUIRED — 200-500 words, 1 dense paragraph OR 3 max, plain prose no `##` headers, names every public API + error class with backticks, walks algorithm step-by-step, calls out integration points + pipeline ordering, names invariants agents miss, closing enumerates all exports + parent classes. Style match: `diamond-problems/approved/cliffy-command-aliases/solution-approach.md`. See `DIAMOND-PLAYBOOK.md § Section 6.3`.
- [ ] test-groups.md REQUIRED — groups tests by behavioral category; per group: test function names + quoted description requirement
- [ ] failure-qa.md template ready — 12 writing rules embedded (per-run analysis post-Castor)

VERIFY pre-submit guards:
- [ ] grep -rEl "shipd|datacurve" tests/ test.sh → empty
- [ ] grep "new file mode" test.patch → 100755 for test.sh (NOT 100644)
- [ ] file solution.patch → "ASCII text" (NOT "Little-endian UTF-16")
- [ ] **Em-dash + Unicode check on ALL submission text artifacts** (universal rule per `DESCRIPTION.md § Human-Voice + ASCII Rules`, all tiers; Diamond adds failure-qa.md / solution-approach.md / test-groups.md / env description):
      rg '[\xE2][\x80][\x90-\xAB]' meta.md failure-qa.md solution-approach.md test-groups.md feedback.md → empty
- [ ] Smart quotes check: rg '[\xE2][\x80][\x98-\x9D]' (same files) → empty
- [ ] `file` reports "ASCII text" for meta.md, failure-qa.md, solution-approach.md, test-groups.md
- [ ] No `--` as pseudo-em-dash in prose contexts (manual scan)
- [ ] No AI cadence markers (Sure!/Certainly!/I'd be happy/It's important to note/In essence/At its core/This approach/This solution) in submission-bound text
- [ ] No trajectory step references ("At step N..." / "After encountering...") in failure-qa.md / solution-approach.md
- [ ] No cross-run comparisons ("same as Castor #1") in failure-qa.md

VERDICT for GATE 5: GREEN (all present + guards pass) / YELLOW (1-2 missing OR 1 human-voice slip) / RED (3+ missing OR ASCII guards fail OR multiple em-dashes)

═══════════════════════════════════════════════════════════════
GATE 5b — Environment Description ≥300 chars (NEW ~2026-05-21)
═══════════════════════════════════════════════════════════════
Read SUBMISSION_PATH/feedback.md § Env Description (or wherever drafted).

Verify env description:
- [ ] Length ≥300 chars (count via `wc -c` on plain text, no markdown)
- [ ] Covers element 1: WHAT env teaches model (domain + concept + trap class)
- [ ] Covers element 2: TYPICAL TASK shape (failing test fixed by scoped change)
- [ ] Covers element 3: SETUP mechanics (successful vs failing trajectory description)
- [ ] Plain ASCII (no em dashes, no Unicode arrows)
- [ ] One paragraph (no `##` headers, no bullet lists)
- [ ] Optional doc link if elaboration needed (but field itself still ≥300 chars)

Reference approved example (DIAMOND.md § Environment Description):
"A FastAPI + Postgres inventory service with a race on stock reservation. The task: fix it so concurrent reservations can't oversell, guided by a failing pytest. A successful trajectory makes that test green with a fix scoped to that endpoint. A failing one looks almost right — most tests pass — but trips on one thing: wraps the wrong call in the transaction, or adds an over-broad lock breaking unrelated tests. Teaches scoping concurrency fixes narrowly."

VERDICT for GATE 5b:
- GREEN: ≥300 chars + all 3 elements present
- YELLOW: ≥300 chars but missing 1 element
- RED: <300 chars (Shipd UI rejects new problem runs from ~2026-05-21)

═══════════════════════════════════════════════════════════════
GATE 6 — Local Validation (DIAMOND-PLAYBOOK § Section 4 R0 smoke)
═══════════════════════════════════════════════════════════════
Run pre-Castor smoke test locally:

  git checkout $BASE_COMMIT && git clean -fd
  git apply test.patch
  ./test.sh --output_path /tmp/base.xml base    # PASS (no regressions)
  ./test.sh --output_path /tmp/new.xml new      # FAIL pre-solution
  grep '<testcase' /tmp/new.xml | wc -l         # >0 (XML has cases)
  git apply solution.patch
  ./test.sh --output_path /tmp/base.xml base    # PASS (still no regressions)
  ./test.sh --output_path /tmp/new.xml new      # PASS (solution works)
  git apply -R solution.patch && git apply -R test.patch   # reverse cleanly

Apply BOTH orders (test→solution AND solution→test) to verify patch independence.

VERDICT for GATE 6: GREEN (all 4 cells correct + both orders apply + XML has cases) / RED (any cell fails)

═══════════════════════════════════════════════════════════════
GATE 7 — Failure-QA Writing Readiness (DIAMOND-PLAYBOOK § Section 5)
═══════════════════════════════════════════════════════════════
Sample failure-qa.md template for compliance with 12 writing rules:

- [ ] Rule 1: Names actual API methods (not "the registry code")
- [ ] Rule 2: No trajectory step references ("At step 21...")
- [ ] Rule 3: No cross-run comparisons ("Same bug as Castor #1")
- [ ] Rule 4: Audit-grade Expected X / got Y placeholders
- [ ] Rule 5: Separates spec quote from inference framing
- [ ] Rule 6: No fabricated identifier patterns
- [ ] Rule 10: Plain ASCII only (no em dashes, no Unicode arrows)
- [ ] Rule 11: Concise (2-3 sentences per section)

VERIFY top-level QA artifacts ready:
- [ ] Success Solution Explanation section template
- [ ] Test Summary (grouped + spec-quoted) ready in test-groups.md

VERDICT for GATE 7: GREEN (template + 12 rules ready) / YELLOW (template missing 1-2 sections)

═══════════════════════════════════════════════════════════════
GATE 8 — Hint Readiness (ONLY if at hint phase post-0% Castor)
═══════════════════════════════════════════════════════════════
Skip this gate unless unhinted Castor 10x = 0% AND fairness analysis cleared (no `agent_blame_unfair: true` flags).

If at hint stage, verify Top-Down Pruning method applied (DIAMOND.md § Hint Authoring Discipline):
- [ ] **Failure-Point Analysis Procedure applied per failing run** (DIAMOND-PLAYBOOK § Failure-Point Analysis): test XML → meta anchor → trajectory pivot → shipped code → root cause
- [ ] 3-4 top failing Castor runs analyzed (failure point + cascading traps mapped)
- [ ] Upstream gates vs downstream consequences distinguished
- [ ] MAXIMUM hint drafted first (over-spec'd ceiling reference)
- [ ] Each hint sentence mapped to meta.md originating sentence
- [ ] Pruning done one-by-one with 1-Castor probes between removals
- [ ] Final hint minimal-non-ambiguous (no obvious derivables remaining)
- [ ] Hint validity: human expert with description+repo could infer it (no implementation details, no helper names, no algorithm steps, no file paths)
- [ ] "Why inferrable" justification present per hint (1-2 sentences citing spec/repo evidence)

VERDICT for GATE 8: GREEN (top-down pruning method applied + hint valid) / YELLOW (trial-and-error approach detected — token waste risk) / RED (hint leaks implementation details — admin rejection risk)

═══════════════════════════════════════════════════════════════
FINAL VERDICT
═══════════════════════════════════════════════════════════════
Aggregate gate verdicts:

GATE 1  (Maintainer):       GREEN / YELLOW / RED
GATE 2  (Triviality):       GREEN / YELLOW / RED
GATE 3  (Trap Quality):     GREEN / YELLOW / RED
GATE 4  (Scope Bands):      GREEN / YELLOW / RED
GATE 5  (Deliverables):     GREEN / YELLOW / RED
GATE 5b (Env Desc ≥300):    GREEN / YELLOW / RED
GATE 6  (Local Validation): GREEN / RED
GATE 7  (Failure-QA):       GREEN / YELLOW
GATE 8  (Hint Readiness):   GREEN / YELLOW / RED  (skip if not at hint phase)

OVERALL:
- ALL GREEN → SHIP: proceed with smoke test (1x Castor) then Castor 10x + Diamond Checks.
- ANY RED (Gates 1, 2, 3, 4, 5b, 6, 8) → STOP: do NOT spend Castor tokens. Remediate first.
- YELLOW only → HARDEN: address weakest gate before submission, then re-audit.

For each non-GREEN gate, output specific remediation:
- Which Section of DIAMOND-PLAYBOOK to read
- What change to make to which file
- Estimated time + token cost to remediate
- If remediation impossible → ABANDON candidate (cite reason)

End report with one-line summary: "SHIP" / "HARDEN: <gate>" / "STOP: <gate>" / "ABANDON: <reason>".

Reference files:
- @Instructions/DIAMOND-PLAYBOOK.md (full)
- @Instructions/DIAMOND.md
- @CLAUDE.md § CRITICAL RULE
- @Instructions/PATTERNS-ADVANCED.md § Pattern 22 + 23 + 32
- @Instructions/KNOWLEDGE.md § Castor
- @Instructions/PROBLEM-PROFILES.md (closest Diamond shape match for scaffolding comparison)
```

---

## Query 13: Local Nova Solvability Simulation (parallel Sonnet imitators) — pre-platform difficulty estimate

Spawn N independent Sonnet sub-agents that each IMITATE the platform solver, each solving a FINISHED problem from `meta.md` ALONE (blind to the hidden tests), grade every attempt with `test.sh`, and return an Orion-format report. Estimates pass-rate / difficulty / message-count BEFORE platform eval — a cheap pre-filter to catch an obviously-too-easy (or env-broken) problem before spending Castor/eval tokens. It MEASURES; it does NOT modify the 5 deliverables.

> ⚠️ COARSE UPPER BOUND on easiness, NOT a platform substitute. Sonnet-imitators are not exactly Nova/Castor: if they ALL solve it, it is definitely too easy (harden); if they all FAIL that does NOT prove it is hard (could be an unfair test or a Sonnet-specific stumble). **The 10-run platform batch (Nova/Orion for Mars/Olympus, Castor for Diamond) is the ONLY difficulty oracle** (PICK-FILTER meta-discipline). Use this to FAIL-FAST, never to greenlight.

**Parameters** (all optional — self-discovers from the workspace; pass a value only to override):
- `PROBLEM_DIR` — folder under `problems/{slug}/` or `diamond-problems/{slug}/` holding the 5 deliverables. Auto: the sole problem folder; pass only to disambiguate if >1 exists.
- `N` (default 6) — number of imitators. `MODEL` (default `sonnet`). `WORKSPACE` (default repo root).

**Prompt:**
```
Run a LOCAL NOVA SOLVABILITY SIMULATION for my Olympus submission: spawn {N or 6} independent Sonnet sub-agents IN PARALLEL (all launched at once, each fully independent) that each IMITATE the platform solver, each solving the problem from meta.md ALONE (blind to the hidden tests), grade every attempt with test.sh, and send back a structured Orion-format report. Aggregate into the tier gate and write results to eval-results.md + feedback.md. This is a COARSE pre-filter, NOT the platform oracle — use it to fail-fast on too-easy, never to greenlight.

SELF-DISCOVER THE TARGET (do not ask me to point at files): list problems/ + diamond-problems/ and find the submission folder yourself. If exactly ONE folder holds the 5 deliverables, that IS the target. If PROBLEM_DIR is given, use it. If >1 exists and none is pinned, STOP and ask which slug. Read REPO_URL from meta.md `Repository:` and BASE_COMMIT from BASE_COMMIT.txt (fallback meta.md `Commit:`).

THIS IS A SIMULATION, NOT AUTHORING. Estimate pass-rate / difficulty / message-count before platform eval — do NOT create or change any of the 5 deliverables. The gate is agent-agnostic and PER-TIER:
- SOLVABILITY (ABSOLUTE, never bypassable, every tier): >=1 of N must FAIRLY PASS. 0 fair passes after enough runs = redesign, never ship.
- PASS BAND: Mars too-easy at >30% solve (cap 30%); Olympus too-easy at >20% (target ~10%, cap 20%); Diamond <=30% (1-3 of 10, Castor). If the imitators solve ABOVE the band => too easy => harden. (Below-band on Sonnet imitators is INCONCLUSIVE — could be unfair test; verify on the platform.)
- MESSAGE-COUNT floor (Olympus/Diamond ONLY, NOT Mars): solver-MEDIAN messages must exceed 100 (the platform takes the MEDIAN of messages/LOC/files across PASSED runs ONLY — compute over SOLVERS, not all runs; a solver-median 80-99 is a rejection risk; with few solvers the median is fragile).
See Instructions/PICK-FILTER.md (meta-discipline) + RULES.md (Substance + Evidence gates) + KNOWLEDGE.md (Difficulty Calibration Protocol).

INPUTS (blank => auto-discover; fill only to override)
- PROBLEM_DIR: {PROBLEM_DIR or "auto: the sole problems//diamond-problems/ folder (ask only if >1)"}
- REPO_URL / BASE_COMMIT: {auto from meta.md + BASE_COMMIT.txt}
- N: {N or 6}    MODEL: {MODEL or sonnet}    WORKSPACE: {WORKSPACE or "repo root"}

STEP 0 - LOCATE + GRADER SETUP (orchestrator, once)
- Resolve the target per SELF-DISCOVER. Confirm it holds the 5 deliverables; derive REPO_URL + BASE_COMMIT.
- Read meta.md (the ONLY spec solvers may see), BASE_COMMIT.txt, Dockerfile, test.sh + test.patch (so YOU the grader know how F2P/P2P score). NEVER pass test.patch / solution.patch / any oracle to a solver.
- Build the BASE image; confirm a clean BASE clone builds and `test.sh base` passes, so any solver failure is the SOLVER's, not the env.

STEP 1 - SPAWN N SONNET IMITATORS (ALL IN PARALLEL, fully independent)
Launch all {N} sub-agents IN PARALLEL: emit every Agent/Task call in ONE assistant message (N tool_use blocks same turn), each model {MODEL or sonnet}, run_in_background: true, isolation: worktree (each gets its own clone). Do NOT spawn-and-wait (that serializes). They share no state, do not see each other, do not see hidden tests. Identical brief each:
  --- per-solver brief (imitate Nova) ---
  You are Nova: a single SOTA coding agent solving ONE task end-to-end. Imitate the Nova profile (AGENTS.md): cheap + exploration-heavy; read the repo, pick an approach, implement, self-validate with the repo's OWN build/linters/visible tests; prone to thrashing on hard problems + blind spots (silent type-conversion bypass, non-exhaustive match -> regression, fmt.Errorf no-op passthrough, tool/API stumbles). Solve HONESTLY from the spec.
  HIDDEN-TEST DISCIPLINE (hard rule): there are NO visible new tests. Do NOT search for/open/read any hidden test, solution patch, expected-value fixture, or oracle — if you stumble on one, ignore it; reading it INVALIDATES your run.
  1. Clone {REPO_URL} at {BASE_COMMIT} into your worktree. 2. Read meta.md + explore; infer required behavior from spec + existing code/tests ONLY. 3. Implement in SOURCE, match repo conventions, keep the repo's build/linters/existing suite green. 4. You may write throwaway self-checks but are graded by a hidden suite — do NOT optimize to guessed test names or hardcode outputs. 5. STOP when the spec is satisfied OR report honestly you are stuck — never fabricate success.
  Return ONLY: (a) the unified diff of your SOURCE changes (no test files), (b) `<minutes> | <files touched> | <added LOC> | <messages spent>`, (c) one paragraph: approach + where you were unsure.
  --- end brief ---

STEP 2 - GRADE EACH ATTEMPT (orchestrator; mirror the platform; PIPELINE as each returns)
For each solver's diff, in a FRESH BASE clone YOU control: apply the solver's SOURCE diff, then test.patch on top; run `./test.sh --output_path <xml> base` (must PASS — no regressions) + `./test.sh --output_path <xml> new` (PASS = solved). Use the Dockerfile env, --network none, --user 1000:1000. Record baseline_passed, new_tests_passed, both exit codes, JUnit counts, exact failing node ids. Diff-doesn't-apply/build = INTEGRATION_ERROR/REGRESSION fail (a real signal), not an env blocker.

STEP 3 - PER-AGENT FEEDBACK (Orion format, one per solver)
  Solver: Nova - Eval: Orion
  <Solved | Missed Requirement | Test Mismatch>
  <Xm Ys> | <N files> | <LOC> | <msgs>
  verdict: PASS_LEGITIMATE | FAIL_MISSED_REQUIREMENT | FAIL_TEST_MISMATCH (+ test_results, justification incl was_mentioned_in_description / was_inferable_from_codebase_excluding_tests, problem_assessment, environment_assessment incl agent_blame_unfair).
Honest-verdict rules: PASS_LEGITIMATE only if base AND new pass AND the diff is a genuine impl (no hidden-test hardcoding/stubbing/gaming). FAIL_MISSED_REQUIREMENT (FAIR — the real difficulty signal) when new tests fail on behavior meta describes or is inferable; agent_blame_unfair=false; give expected-vs-actual + name the missed req (near-miss 23/24 = good calibration). FAIL_TEST_MISMATCH (UNFAIR — ZERO signal) when a hidden test pins behavior NOT in meta and NOT inferable, or flaky/env; agent_blame_unfair=true — that is a PROBLEM BUG (relax the test or document the contract), not difficulty.

STEP 4 - AGGREGATE + GATE READ
- Pass rate = PASS_LEGITIMATE / N. Split fails FAIR vs UNFAIR; DISCOUNT unfair entirely (fix the unfairness).
- Per-tier read: >=1 PASS => solvability MET. For ~10% Olympus, 0 of 4-6 FAIR runs is EXPECTED (0.9^5=59%) — redesign ONLY at ~0 of 10 fair runs; solve-rate ABOVE the tier band => too easy (harden). If EVERY fair run misses the SAME described requirement => 0%-trap risk: de-trap by naming that surface in meta (keep the work + scattered difficulty). Check the message-count floor as the solver-MEDIAN (Olympus/Diamond only); flag a solver-median <=100 as under-scoped (add an independent subsystem, don't pad).
- Update eval-results.md: per-agent rows (agent, model, verdict, msgs, files, LOC, failed tests, fair/unfair, reason) + tally + the statistical read + a Fingerprint line (git hash-object of the 5 deliverables). Update feedback.md: summary, which hidden tests trapped which solvers + why, recommended next action (submit / harden / de-trap / redesign). Do NOT touch the 5 deliverables.

Reference: @Instructions/PICK-FILTER.md (meta-discipline + the 10-run-batch-is-only-oracle rule), AGENTS.md (Nova/Orion/Vega profiles + Orion verdict taxonomy), KNOWLEDGE.md (Difficulty Calibration + 0%-trap diagnostic), RULES.md (solvability-absolute + Substance/Evidence gates), TESTS.md (test.sh F2P/P2P contract), DOCKER.md (offline non-root run matrix), Olympus-Approved/Feature-Requests/ + diamond-problems/approved/ (calibration references).
```

## Query 14: Clone From the Approved Pool (preserve calibration, rebuild distinct)

Start from an APPROVED submission, preserve its proven difficulty calibration (shape, trap-count, LOC band, msg-count), and rebuild a STRUCTURALLY DISTINCT problem on a DIFFERENT feature/subsystem — then run a hard distinctness/dedup audit (PICK-FILTER gate 7: dedup ALL dirs by feature class + read the JUDGE verdict). Use when you want a known-good calibration template but must avoid a derivative.

**Prompt (sketch):** Pick an approved sub at `Olympus-Approved/Feature-Requests/<repo>/<slug>/` whose shape + pass-band you want to reuse. Read its DESIGN/meta/test/solution to extract the CALIBRATION (shape, # interdependent traps, eff-LOC, solver-median, the misdirection style) — NOT the feature. Then Query-10-brainstorm a DIFFERENT cross-subsystem feature (different repo OR different subsystem of the same repo) that hits the SAME calibration. Run all 8 PICK-FILTER gates on the new feature. Before authoring, run a dedup precheck by FEATURE CLASS across diamond-problems/ + problems/ + Olympus-Approved/ and confirm the JUDGE verdict is Adjacent-or-Clear (Duplicate/Derivative = pivot). The calibration is reused; the feature, subsystem, and trap surface must be genuinely distinct.

---

## GitHub CLI Commands

### Search issues + PRs

```bash
# Open issues
gh issue list -R {org}/{repo} --state open --limit 50

# By label
gh issue list -R {org}/{repo} --label "bug" --state open

# By keyword
gh issue list -R {org}/{repo} --search "keyword" --state open

# Specific issue
gh issue view {number} -R {org}/{repo}

# Existing PR check (THE #1 revert reason — always run)
gh pr list -R {org}/{repo} --state all --search "{keyword}"

# Issue's linked PRs
gh issue view {number} -R {org}/{repo} --json closedByPullRequestsReferences | jq

# PR details
gh pr view {pr_number} -R {org}/{repo}
```

### Bulk download (formatted JSON)

```bash
# All issues
gh issue list -R {org}/{repo} --state all --limit 1000 \
  --json number,title,state,labels,body,closedByPullRequestsReferences \
  | jq '.' > Issues.json

# All PRs (open + closed + merged)
gh pr list -R {org}/{repo} --state all --limit 1000 \
  --json number,title,state,body,mergedAt,mergeable \
  | jq '.' > PRs.json
```

---

## Query Chaining Patterns

| Goal | Chain |
|---|---|
| Mars-default workflow | Query 3 (find repo) → Query 1 (Mars feature) → Query 2 (build it) |
| Olympus workflow | Query 3 (find repo) → Query 6 (Olympus feature) → Query 2 (build it) |
| New repo exploration | Query 3 (find) → Query 4 (analyze) → Query 1 or Query 6 (generate) → Query 2 (build) |
| Existing issue (rare) | Query 2 (build it) → if feedback: Query 5 (revise) |
| Multi-repo backlog | Query 3 (5–10 repos) → Query 1 per repo for Mars backlog → Query 2 per (or Query 6 for Olympus) |
| Olympus stalls at 0% | Resubmit as Mars (no changes) — usually lands in ≤ 30% Nova band |
| Diamond-tier workflow | Query 7 create → submit → Query 7 eval → Query 7 failure-qa → submit → Query 7 review-feedback → iterate |
| Lite-tier exploration | Query 3 (find repo) → Query 9 (analyze for Lite) → Query 8 (solve Lite) |
| Lite-tier existing issue | Query 8 (solve Lite) → if feedback: Query 5 (revise) |
| Tier-agnostic ideation | Query 10 (generate, classify tier post-sketch) → Query 2 (build) → if feedback: Query 5 (revise) |
| Analysis-folder workflow | Query 3 (find repo) → Query 4 (analyze repo → analysis-folders/*) → pick candidate → Query 11 (build picked candidate end-to-end) → if feedback: Query 5 (revise) |
| Lite analysis-folder workflow | Query 3 (find repo) → Query 9 (analyze for Lite) → pick candidate → Query 11 (build picked candidate) → if feedback: Query 5 (revise) |
| Diamond analysis-folder workflow | Query 3 (find repo) → Query 4 (analyze) → pick Olympus candidate that fits Diamond → Query 11 (build with Diamond tier) → **Query 12 (pre-Castor audit — STOP if RED)** → Query 7 (Diamond pipeline: smoke/eval/diamond-checks/auto-review/qa) → if feedback: Query 5 (revise) |
| Diamond audit-only workflow | Query 12 (audit existing submission, get GREEN/YELLOW/RED + remediation) |
