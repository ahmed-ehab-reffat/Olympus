# Mars Design Phase — Agent Prompt

You produce a complete `DESIGN.md` for a Mars submission. NO code, NO tests, NO Dockerfile.
A perfect Design ships in 1 revision round; a weak Design takes 3-5. Your goal: 1.

═══════════════════════════════════════════════════════════════
INPUTS (fill these before sending)
═══════════════════════════════════════════════════════════════
REPO_URL:           {github URL}
BASE_COMMIT:        {40-char hash, already saved to BASE_COMMIT.txt}
REPO_PATH:          {local clone path}
FEATURE_CONSTRAINT: {optional: "any reasonable" OR specific area like "analyzer rules"}
SHAPE_PIN:          {optional: A1 / A2 / B / C / D-new / D-change OR "auto"}
TIER_TARGET:        {Mars Solid (default) OR Mars Strong}

═══════════════════════════════════════════════════════════════
READ FIRST (in this order, do not skip)
═══════════════════════════════════════════════════════════════
1. @Instructions/Guides/PLAYBOOK.md       — entire file (THE authoritative reference)
2. @Instructions/Guides/RULES.md          — §§ Quality Ranks, Difficulty Calibration, Real Revert Causes, Features Already Used
3. @Instructions/Guides/AGENTS.md         — §§ Confirmed Blind Spots, Per-Agent Profiles, Difficulty Calibration, Diagnosing Failures
4. @Instructions/Guides/WORKFLOW.md       — §§ Identify Your Shape, Step 1 (Design)
5. @Instructions/Problem/DESCRIPTION.md   — entire file
6. @Instructions/Problem/TESTS.md         — §§ Required Test File Structure, Test Coverage, Test-First Helpers
7. @Instructions/Problem/SOLUTION.md      — §§ Complexity Requirements, Helper Extraction, LOC Estimation Discipline
8. After picking a shape: open all 5 deliverables in the closest match under
   @Mars Approved V2/Feature Requests/<closest-shape>/  ← side-by-side scaffolding

═══════════════════════════════════════════════════════════════
PHASE 1 — Repo understanding (HARD GATE)
═══════════════════════════════════════════════════════════════
Before generating any candidate, demonstrate you can:
  ✓ Explain the repo architecture in ONE paragraph (2 minutes of reading)
  ✓ List 5 top-level subsystems and the boundaries between them
  ✓ Identify 3 high-entanglement zones (where features naturally touch many files)
  ✓ Name the test framework + conventional test file location
  ✓ Cite 1 existing test file as your formatting template
If you cannot do all 5, STOP and read more code. Do not proceed on shaky ground.

═══════════════════════════════════════════════════════════════
PHASE 2 — Existing-PR check (NON-NEGOTIABLE; #1 reject reason)
═══════════════════════════════════════════════════════════════
For every candidate keyword, run:
  gh pr list   -R <owner>/<repo> --state all --search "<keyword>"
  gh issue list -R <owner>/<repo> --state all --search "<keyword>"

If ANY PR mentions or solves the feature → ABANDON that candidate immediately.
This check is mandatory and not optional. Document the searches you ran.

═══════════════════════════════════════════════════════════════
PHASE 3 — Propose 5–7 candidates, pick 1
═══════════════════════════════════════════════════════════════
For each candidate, fill this row:

| Candidate | One-line behavior | Shape | Files modified+new | Raw LOC | Meaningful (raw×0.65) | Predicted Nova | Dominant verdict | Reject? |

Reject any candidate matching ANY of these:
  ✗ 3+ identical structural examples already exist in repo (pattern-followable)
  ✗ Solvable by creating a standalone new file with minimal wiring
  ✗ Single-file one-liner under 100 LOC (no agent will fail it)
  ✗ Cosmetic refactor or doc-only change
  ✗ Bug in a dependency, not the project
  ✗ Already on @Instructions/Guides/RULES.md § Features already used (don't duplicate)
  ✗ Predicted Wrong Logic ≥25% (Olympus territory — universal LLM blind spot)
  ✗ Existing PR solves it (Phase 2)
  ✗ Open issue already covers it as a binding spec (use issues as inspiration only)
  ✗ Outside the TIER_TARGET LOC band

The 1 surviving candidate must:
  ✓ Match a shape from PLAYBOOK §§ 11-12
  ✓ Predicted Nova pass rate matches the shape's documented band
  ✓ Touch a real subsystem with an integration hook
  ✓ Have 5-13 stated requirements achievable in the LOC band

═══════════════════════════════════════════════════════════════
PHASE 4 — Produce DESIGN.md (the deliverable)
═══════════════════════════════════════════════════════════════
Write exactly these 14 sections to `DESIGN.md`. No extras, no missing sections.

# DESIGN.md — {repo}-{slug}

## 1. Title (verb-led, 5–10 words, names specific subsystem)
Verb from: Fix / Add / Implement / Extend / Iterate / Rewrite / Handle.
Anti-titles: "Bug fix for #1380", "Fix the parser", "How to handle XYZ".

## 2. Shape classification
- Shape:                A1 / A2 / B / C / D-new / D-change
- Definition (cite PLAYBOOK § Pattern 11):
- Pass rate target:     {from shape table — A1=10-15%, A2=20-25%, B=50-55%, C=20-25%, D-new=20-25%, D-change=40-45%}
- Best agent:           {Nova→Orion / Orion-alone / Mixed}
- Dominant verdict:     {MISSED_REQUIREMENT / REGRESSION / INTEGRATION_ERROR}
- Solver/our LOC ratio: {A1≈2.07× A2≈1.71× B≈1.28× C≈1.02× D-new≈1.44× D-change≈1.07×}

## 3. Public API surface (5–15 names)
Exactly the names tests will assert. One short line of semantics each.
- `name_1(args) -> ReturnType`  — what it does
- `name_2(args) -> ReturnType`  — what it does
- `enum_variant_1` / `enum_variant_2` — what they represent
- `error_kind_1` — when raised
"Same as X" is forbidden — list every actual name.

## 4. Canonical output form (REQUIRED if tests use assert_eq! on structures)
- Sort order:           {lexicographic / by-X-then-Y / preserves-input-order}
- Associativity:        {right / left / flat}
- Dedup strategy:       {first-occurrence / last-occurrence / none}
- Empty input:          {returns X / errors with msg containing Y}
- Unicode handling:     {as bytes / by codepoint / collation-aware}
- Negative/zero:        {clamp / error containing "Z"}
Each rule = one sentence (validator-hardening style).

## 5. Blind-spot pre-empts (match against the 10-entry sentence bank)
Walk DESCRIPTION § Blind-Spot Pre-Empt Sentence Bank. For each match, quote the
canonical sentence verbatim. Limit total to 0-1 codebase-inferable requirements
(more = hidden-requirements rejection).

Categories to check:
  rule-resolution / sort-order / adjacent-vs-all / dedup / iteration-termination /
  result-ordering / parallel-API / falsy-on-invalid / compound-order / pipeline-placement

## 6. Description draft (meta.md, plain prose)
Word budget for shape:
  A1 ≈107 / A2 ≈137 / B ≈241 / C ≈91 / D-new ≈148 / D-change ≈183. HARD CAP 240.
Body shape:
  A1 → 1 paragraph + dash bullets
  A2 → 1 paragraph with inline numbered rules (1)(2)(3)
  B  → 3 paragraphs (WHAT / behavior / edge cases)
  C  → short dense, ~10 words/rule
  D-new / D-change → 3 paragraphs (variant shape / normalization / supplementary API)

Forbidden in the draft:
  ## headers · formulaic labels (Problem Description:, Acceptance Criteria:) · numbered lists ·
  Box<...> wrappers · code-instead-of-prose · vague language (properly/correctly/as-expected) ·
  test-framework references · external framing ("Pest is a parser library that...")

## 7. File footprint (sketched against real source files)
| Action | Path                          | Current LOC | Raw delta | Meaningful (×0.65) | Reason |
|--------|-------------------------------|-------------|-----------|--------------------|--------|
| MODIFY | path/existing.go              |    XXX      |    +YY    |       YY×0.65      | …      |
| NEW    | path/new_module.go            |    —        |    +YY    |       YY×0.65      | …      |
TOTAL: {raw}/{meaningful} across {N modified + M new} files.

Tier band check (must be ✓):
  Mars Entry  → 100-200 raw,  1-3 files
  Mars Solid  → 170-380 raw,  1-8 files (mode 3)
  Mars Strong → 380-600 raw,  6-12 files
  D-new exception → up to 15 files (4 crates) at 400 raw

LOC discipline:
  • Estimate by sketching the 2-3 hardest files in real code, NOT by file-walk maxima
  • Calibration: pest-error-recovery design walked 705 LOC; reality was 398 meaningful
  • Healthy Mars Solid ratio: 200-300 raw / 130-200 meaningful

## 8. Solution outline — pure-function helpers (1+ per behavior)
Every helper maps 1:1 to a description sentence. Write the signature + 2-line description.

helpers:
  - helper_1(...) -> ...   ← description requirement #1
  - helper_2(...) -> ...   ← description requirement #2
  - helper_3(...) -> ...   ← description requirement #3
  ...

If shape is A2 / A1 / B with iterative semantics, include the fixpoint loop verbatim:
  loop {
      let next = current.clone().map_top_down(|e| transform(e, ...));
      if next == current { break; }
      current = next;
  }

If recursion through references possible, include cycle-trace pattern:
  fn check(expr, ..., trace: &mut Vec<String>) -> bool {
      // push ident before recurse, pop after
  }

## 9. Test file outline
Path: <crate>/tests/<feature>_tests.<ext>  (one new file at conventional location)

Block 1 — Imports (only what tests need)
Block 2 — Builder helpers (10-30 one-liners): {list types}
Block 3 — Assertion helpers (1-3, substring-match for errors): {list signatures}
Block 4 — Tests grouped by requirement bucket:
  Bucket "behavior X":     N tests including edge cases
  Bucket "behavior Y":     N tests
  Bucket "edge cases":     empty / zero / single / boundary / unicode / recursion / null
  Bucket "stated inverse": (if applicable)

Test count anchor for shape (observational, not target):
  C 39 / A1 68 / A2 92 / D-change 102 / D-new 126 / B 160

5-axis coverage check (ALL must be ✓):
  ✓ Every described behavior in meta.md (≥1 test per sentence/bullet)
  ✓ Every public API surface (function, method, error variant, config option)
  ✓ Every solution branch (every if, match arm, early return, recursive case)
  ✓ Standard edge cases (empty / zero / single / boundary / unicode / recursion / null)
  ✓ Stated inverse (if "X happens when Y" matters and isn't symmetric)

## 10. Forced trait bounds / generics / kwargs (test-first discovery)
Sketch test helper signatures BEFORE the spec. Walk the closures/generics/kwargs
they invoke. Document any FORCED bounds the helpers force on the API under test.

Examples to check:
  Rust   — FnOnce vs FnMut vs Fn (the recover() trap from pest-error-recovery)
  TS     — generic narrowing / conditional types
  Python — __init__ kwargs / dataclass fields / default values

Document each forced bound. If a bound is forced but not obvious, list it as a
PREDICTED TRAP in §11 and add a description sentence in §6 to surface it.

## 11. Predicted trap matrix (2-3 named traps, all with mitigations)
| # | Trap                          | Why agents hit it          | Pre-empt sentence (in §6) | Test that catches it |
|---|-------------------------------|----------------------------|---------------------------|----------------------|
| 1 | …                             | …                          | …                         | …                    |
| 2 | …                             | …                          | …                         | …                    |

Wrong Logic % constraint: <25%. If you predict ≥25%, the problem is Olympus —
either downgrade the trap or upgrade the tier.

## 12. Tier + category decision
- Tier:     Mars Solid / Mars Strong / Olympus
- Sub-rank: Entry / Solid / Strong / Olympus-Okay/Good/Excellent
- Category at submit time:
    enhancement     — modifying existing function/pass/subsystem (titles "Rewrite…", "Extend the existing…")
    feature-request — net-new (new public type/API/config) (titles "Add…", "Introduce…")
- Pick the honest category. Mismatch = automatic FAIL.

## 13. Predicted Nova pass rate
- Predicted: N% – M%
- Trap structure: list the traps + their approx miss-probabilities (1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%). The knob is trap count/strength, NOT LOC. **Each trap must be INTERDEPENDENT (fixing one regresses/surfaces another via shared state/ordering/chokepoint) + MISDIRECTING (the failing assertion points away from the real fix). Nova ≈ Castor now — an isolated, self-revealing trap gets single-shot-fixed even on Mars.**
- Reasoning: cite the shape band + the difficulty levers used:
    precision wording / file count / interacting traps / cross-subsystem integration /
    near-miss tests / codebase-inferable hint (0-1 max)
- Sanity check: **Mars target ≤ 30% (solvable). ~2+ INTERDEPENDENT + MISDIRECTING traps — a single ~50% / isolated / self-revealing trap is too easy (Nova≈Castor single-shot-fixes it).** If 0%: unsolvable, reject or rework. If >30%: too easy, add a 2nd interdependent trap with a misdirecting failure or strengthen one to >60% miss (target a Nova blind spot, AGENTS § Confirmed Blind Spots). If genuinely cross-subsystem-hard at ~10%: consider Olympus.

## 14. Quality-gate checklist (ALL ✓ required to exit Design)
- [ ] Repo understanding: 5/5 in Phase 1
- [ ] Existing PR check: 0 hits in Phase 2 (paste search commands)
- [ ] Closest approved Mars problem opened side-by-side as scaffolding
- [ ] Title: verb-led, 5-10 words, names specific subsystem
- [ ] Shape declared with PLAYBOOK § Pattern 11 citation
- [ ] Public API surface lists every name tests will assert (no "same as X")
- [ ] Canonical output form spelled out (sort, associativity, dedup, empty, unicode, negative)
- [ ] 0-1 codebase-inferable requirements (more = hidden-requirements reject)
- [ ] Description draft: word count in shape band, hard cap ≤240
- [ ] Description draft: no ## headers, no formulaic labels, no Box<>, no code-prose
- [ ] File footprint sketched against REAL source files, not file-walked
- [ ] Raw LOC and meaningful LOC both within tier band
- [ ] Solution outline: 1+ pure-function helper per description sentence
- [ ] Fixpoint loop / cycle-trace pattern included if applicable
- [ ] Test file outline: 4-block layout, scenario-encoded test names
- [ ] 5-axis test coverage planned
- [ ] Forced trait bounds / kwargs documented
- [ ] 2-3 named traps each with pre-empt sentence + catching test
- [ ] Predicted Wrong Logic <25% (else upgrade tier)
- [ ] Predicted Nova pass rate matches shape band
- [ ] Tier and category match the description
- [ ] Feature is NOT pattern-followable (no 3+ identical structural examples)
- [ ] Feature is NOT in RULES § Features already used (don't duplicate)

═══════════════════════════════════════════════════════════════
PHASE 5 — Failure-mode self-audit (must complete before declaring done)
═══════════════════════════════════════════════════════════════
Walk PLAYBOOK § Pattern 8 (5 revision buckets) and ANSWER each:

  Bucket 1 — Hidden requirements? Any test in §9 not covered by a description sentence in §6? → fix §6.
  Bucket 2 — Tech-spec tone? §6 has any ## heading or formulaic label? → rewrite as plain prose.
  Bucket 3 — Tests pass on base? §9 includes any test that doesn't use the new API? → remove or redesign.
  Bucket 4 — Tests over-constrain? §9 asserts internal-only behavior agents can't infer? → loosen or hint in §6.
  Bucket 5 — Solution under 200 LOC, problem too easy? §7 raw <170? → expand scope (parallel API,
             additional edge case dimension), don't pad with dead code.

Walk RULES § Real Revert Causes and confirm none apply:
  hidden requirements / test.sh trickery / redundant tests / exact-string assertions /
  code duplication / scope creep / regression-on-base / AI-generated comments /
  weak assertions / wrong package / dead code / missing validation / ambiguous bounds /
  flaky tests / pre-existing test passes / vacuously true assertions

Walk AGENTS § Confirmed Blind Spots and confirm any that apply have a §5 pre-empt:
  specific examples override general / type inference too restrictive /
  initializing = default constructor / cross-feature ordering / reference vs deep copy /
  AST traversal default bottom-up / rule resolution skipped / unstated inverse / default ordering

═══════════════════════════════════════════════════════════════
OUTPUT
═══════════════════════════════════════════════════════════════
Write `DESIGN.md` in the workspace root with all 14 sections.
Append a short "Why this is not a duplicate" note citing the closest 1-2 approved
Mars problems and what differentiates this one.
Append "Predicted iteration cycles: N" — target 1, accept ≤3.

Do NOT write code, tests, or Dockerfile. Stop after DESIGN.md is complete.
The Design Document is the SOLE deliverable of this phase.