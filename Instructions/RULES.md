# RULES — What Gets Accepted

21-item review checklist, shape-aware quality ranks, rejection criteria, bypass format, track record. Apply tier AND shape thresholds.

> **Read first:** `PICK-FILTER.md` — the 8 pre-pick gates (run BEFORE selecting any pick). Then `PLAYBOOK.md` — patterns from 13 approved problems (5 Mars + 7 Olympus + 1 cross-tier), with 10-shape taxonomy.

---

## Tier Matrix

| | **Mars** (default) | **Olympus** |
|---|---|---|
| Intent | Ship medium-difficulty features fast | Hard, cross-subsystem features |
| Payout | $125–$175 | $250–$350 |
| Review | ~12h | 1–2 weeks |
| Solvability gate | 10 Nova/Orion at **≤30% pass** (solvable) | ≥1 pass across 10+ Nova/Orion/Vega runs |
| Solution +LOC | 100 floor (≥150 pref), **170–380 sweet spot** | **450 effective LOC FLOOR (HARD — auto-review triggers)**, 600+ sweet spot |
| Files modified | 1–8 (mode 3) | 8–35 (median ~17) |
| Test files | 1 typical | 1–4 |
| Pass band | **≤ 30%** (was 25-55%; solvable, 0%=reject) | ~10% (1-3/12) |
| Trap structure | **~2+ INTERDEPENDENT + MISDIRECTING** (Nova≈Castor; single-point trap single-shot-fixed) | 3+ interdependent + misdirecting, compounding |
| Revision rounds | 1–3 (playbook-aligned) | 3–5 |
| Hint system | Removed April 2026 | Removed April 2026 |

Pick at submit time. Reviewers can downgrade Olympus→Mars if scope is Mars-level (you receive Mars payout). You can switch Olympus→Mars in a revision.

### Substance + Evidence gates (Olympus/Diamond — beyond LOC + pass-rate)

- **Message-count floor (>100 solver-MEDIAN).** The platform considers the MEDIAN — across SOLVED (PASSED) runs ONLY — of message count, LOC, AND files (failed runs EXCLUDED). A problem whose solver-median message count is <100 is a concentrated needle-trap = under-scoped, even if solvability + pass-rate + LOC all pass. Fragile-median example: solvers at 94 and 109 → median 101.5 (barely cleared). Fix an under-100 by adding ANOTHER genuinely-independent subsystem/axis, NEVER by padding repetitive breadth. (Does NOT apply to Mars — short single-subsystem features are expected.)
- **Eval-freshness fingerprint.** An eval batch is valid evidence (for the ≥1-pass solvability floor, the ~10% pass ceiling, the >100-message floor) ONLY if it ran on the CURRENT deliverable bytes. Platform eval output carries no timestamp/commit, so freshness is a content-EQUALITY question: record `Fingerprint: sol=<sha> test=<sha> meta=<sha> docker=<sha> base=<sha>` (git blob SHA of the 5 deliverables, = `git hash-object`) under each batch header in eval-results.md; a batch whose fingerprint no longer matches the current deliverables is STALE and its numbers are NOT evidence (re-eval). `.claude/hooks/freshness_check.py` (Stop hook) flags staleness; `.claude/hooks/effective_loc_check.py` predicts the human LOC re-count + flags breadth-padding. A gate evidenced ONLY by stale batches is UNMET → request-change pending re-eval; never accept on stale numbers.

### Category at submit time

The platform classifier validates `category` against the description; mismatch = FAIL.

| Category | Pick when… | Example |
|---|---|---|
| **enhancement** | Modifying existing function/pass/subsystem. Title starts with "Rewrite…", "Extend the existing…" | pest-factorizer-fixpoint |
| **feature-request** | Net-new functionality (new public type, API method, config key). Title starts with "Add…", "Introduce…" | pest-extended-skip |

Pick the honest category — fighting the classifier with reworded openings is fragile.

---

## Problem Creation Philosophy

### Always Create Original Features

**Never use open issues.** Always analyze the repo deeply and invent features yourself. Original features give full scope control — you decide the complexity, file count, and requirements from scratch.

Open issues are risky: they limit scope, may have solutions in comments/PRs that agents find, and constrain what you can build. Deep analysis of the repo architecture always produces better candidates than browsing the issue tracker.

Choose repos with **many layers** and design features around **deeply entangled zones** that naturally span 10+ files (Olympus) or 1–8 files (Mars).

### The Complexity Test (Before Writing Any Code)

1. **Can an agent solve this by mainly creating new files?** → **REJECT.** Agents easily create standalone modules. The feature must require **modifying existing code deeply**.
2. **Does it require modifying 5+ existing files with complex logic?** → Good sign. Not just adding imports — actual logic changes in existing functions.
3. **Will a first attempt naturally break existing tests?** → Good sign. Features that cause regressions if done carelessly force agents to understand the codebase integration.
4. **Does the feature require understanding existing code deeply to implement?** → Required. If an agent can implement it without reading existing code, it's too easy.
5. **Is the LOC already at tier floor?** (Mars 170+, Olympus/Diamond **400 effective HARD FLOOR — auto-review triggers below**) → If not, expand scope NOW — don't accept a small solution. **Auto-reviewer effective = raw added − blank − comment-only (braces KEPT, comments NOT counted).** Verified: cel-go `575 − 48 − 160 = 367`. Sub-floor = guaranteed Auto Review fail = wasted Castor tokens. Comments are dead weight — real code clears the floor.

### Revision Rounds Are Normal

Top contributors go through 1-5 revision rounds before approval. This is normal — not a sign of failure. Each revision costs 50 tickets, so:
- Fix ALL reviewer issues in one pass per round
- Don't over-fix — only change what was requested
- Read reviewer feedback carefully — they often give specific file:line fixes
- Mars Solid (playbook-aligned): 1–3 rounds
- Olympus: 3–5 rounds

---

## Issue Selection Guide

### Pick These (High Value)
- **Original feature ideas** — invented features that naturally span many subsystems
- **Deeply entangled zones** — areas where changing one thing requires touching 10+ files (Olympus) or 1-8 files (Mars)
- **Cross-subsystem features** — features that span compiler/runtime/API, parser/optimizer/generator/VM, model/query/API/middleware/routing/docs
- **Features that require modifying 5+ existing files with complex logic** (not just imports) — Olympus
- **10+ interacting requirements** with precision wording — Olympus
- **5–13 requirements** for Mars (clear API surface, integration hook)
- **Deep codebase integration** — features requiring hooks into multiple code paths
- Lifecycle/Hook bugs (100% approval), Web API implementations (100% approval)

### Avoid These
- **Standalone new modules** — if the agent can solve it by creating new files without deeply modifying existing code, it's too easy
- **Open issues** — limits scope, risks existing PRs, AI finds solutions in comments. Always invent original features instead.
- Solutions under tier floor → too easy
- Solutions touching only 3-4 files when Olympus is targeted → missed complexity opportunity (Okay rank at best)
- Well-known patterns (WeakRef, null checks)
- Validation/type coercion changes → might be intentional
- Simple helper functions
- Integration/environment-specific issues
- **Only 5-7 requirements for Olympus** — these hit 30% pass rate (too easy for agents)
- Pattern-followable: 3+ identical structural examples already in codebase → agents copy-paste, no test hardening fixes it

### Repository Requirements
- Public repository on GitHub
- At least 500 GitHub stars (platform floor). Our own HUNT ceiling is **10000** (relaxed from 5000 on 2026-08-04); 5000-10000 is a penalty band, not a free window — see `PICK-FILTER.md § Gate 10`
- At least 1 commit in the last 12 months
- Language: **TypeScript, JavaScript, Python, Go, Rust, Java/JVM, or C/C++**. (Java/JVM + C/C++ re-enabled — the 2026-05-14 disable was reverted; verified toolchains in `DOCKER.md`.) **⛔ Plain C is NOT eligible (platform picker 2026-09-19):** the supported language must be the repo's PRIMARY language or a MAJOR top-3 share by bytes (`gh api repos/O/R/languages`); tyfkda/xcc (C primary, TypeScript 4.9%) was refused. "C/C++" here means C++-primary repos that also contain C.
- Production-level codebase
- Permissive open-source license (see allowed list below). **If the repo carries MULTIPLE licenses, EVERY one must be in the allowed set — a single non-allowed license (even vendored/subdir) = whole-repo reject.** Verify all before investing. **READ the actual LICENSE file and match against the explicit allowlist — "OSI-approved" is NOT the test:** CC-BY (1.0-4.0) is ALLOWED though not OSI-approved, while **NCSA is a HARD disqualifier though it IS OSI-approved**, and any **conditional / rider BSD** (BSD text plus extra conditions) is a HARD disqualifier (community burns: linearmodels NCSA, pykalman conditional-BSD rider — both perfect picks killed on license).
- No existing PR that already solves the problem
- Immutable commit hash (not branch name or tag)
- Optional: GitHub issue URL that describes the problem

**Per-repo submission caps (admin 2026 — platform warns at submit):**
- **≤ 6 submissions per repo (total).**
- **≤ 3 submissions per repo in a single week.**
- **Global ≤ 50 submissions per repo across the whole quest** (all authors combined).

Count existing subs for a repo across ALL dirs (`Olympus-Approved/Feature-Requests/<repo>/`, `problems/`, `diamond-problems/`, `rejected/`) at pick time. Repos already at/over the 6-cap (do NOT add): dasel (9), cliffy (7), yaegi (7). Platform-flagged over-used (all authors, DEAD): opa (60). Full blocklist: `SATURATED-REPOS.md`. See `PICK-FILTER.md § Gate 10 REPO-QUOTA`.
- NOT plagiarized from another submission (plagiarism = hard reject)

### Allowed Licenses
- MIT
- BSD (all variants: BSD-1-Clause through BSD-5-Clause, BSD-FatFs, BSD-Mixed, BSD-Protection, BSD-Source-Code)
- Boost / BSL-1.0
- BLAS
- GNU-All-permissive-Copying-License
- Apache (Apache-2.0, Apache-2.0-Modified, Apache-with-LLVM-Exception, Apache-with-Runtime-Exception)
- Creative Commons (CC-BY-1.0 through CC-BY-4.0)

NOT allowed: GPL, AGPL — rejected.

---

## 21-Item Review Checklist

Reviewers score each submission against these. Must score 5+/7 on the quality scale to be accepted.

### Problem (Items 1–7)

| # | Criterion | YES | NO |
|---|---|---|---|
| 1 | Requirements complete and self-contained | Everything needed is present | Important context missing |
| 2 | No ambiguities, fully deterministic | Precise and testable | Vague or open to interpretation |
| 3 | Concise and not prescriptive | Describes what, not how | Prescribes implementation steps |
| 4 | Matches real-world repo scope | Realistic issue | "Rewrite entire auth system" |
| 5 | Aligns with repo design philosophy | Fits existing patterns | Adds business logic to hooks framework |
| 6 | No irrelevant context | Focused on what matters | Long narrative background |
| 7 | Clear writing and formatting | Plain sentences | Formulaic AI headers |

### Tests (Items 8–15)

| # | Criterion | YES | NO |
|---|---|---|---|
| 8 | Tests highlight missing/incorrect behavior | Fail on base, pass after fix | Already pass without changes |
| 9 | Tests are deterministic | Stable across runs | Depend on timing/randomness |
| 10 | Assertions verify correct output | Check precise outcomes | Only weak conditions |
| 11 | Tests validate behavior, not internals | Assert via public APIs | Inspect private state |
| 12 | Tests follow repo structure | Match naming/folder conventions | Random folders or different framework |
| 13 | Tests cover behavior and edge cases | Success + failure paths | Only happy path |
| 14 | Test suite is non-redundant | Each test adds distinct value | Bloated or repetitive |
| 15 | Tests don't check unspecified behavior | Map to problem spec | Extra expectations not in spec |

### Solution & Code (Items 16–21)

| # | Criterion | YES | NO |
|---|---|---|---|
| 16 | Solution meets all requirements | Every specified behavior implemented | Missing features |
| 17 | No regressions, code follows patterns | Clean, idiomatic, consistent | Introduces bugs or violates patterns |
| 18 | No unexplained defensive code | Only what spec requires | Speculative guards |
| 19 | No irrelevant changes | Diff only includes task changes | Unrelated edits |
| 20 | API contracts remain stable | Public APIs unchanged unless required | Breaking changes |
| 21 | No AI slop | Clean, purposeful code | Verbose, over-commented, auto-generated |

---

## Pre-Submission Checklist

### Repository state
- [ ] `BASE_COMMIT.txt` exists in problem folder
- [ ] All tests pass: `./test.sh --output_path /tmp/base.xml base` and `./test.sh --output_path /tmp/new.xml new`
- [ ] JUnit XML has `<testcase>` count > 1 in both modes

### Tests
- [ ] New tests FAIL on base for the right reason (missing feature, not import error)
- [ ] New tests PASS after solution
- [ ] Base tests still PASS (no regressions)
- [ ] `test.sh` is executable (mode 100755 — Windows: `git add --chmod=+x test.sh` BEFORE diff; verify `grep "new file mode" test.patch` shows `100755`)
- [ ] `test.sh` accepts `--output_path <path>`, position-independent arg parsing
- [ ] Build-failure fallback present (Rust)
- [ ] No comments inside test bodies (unless repo convention)
- [ ] No debug statements
- [ ] Tests run offline (`--network none`)
- [ ] Coverage complete: every described behavior, every public API, every solution branch, every edge case

### Solution
- [ ] Follows project conventions (naming, patterns, error handling)
- [ ] No debug statements, unused variables/imports, dead code, `as any`
- [ ] No AI markers (`// TODO`, `// FIXME`, `// NOTE`, category headers, numbered steps)
- [ ] No scope creep (nothing beyond what description asks)
- [ ] Extends existing infrastructure, not creating replacements
- [ ] No breaking changes to existing function signatures
- [ ] Tier-appropriate +LOC (Mars 170–380 sweet spot, **Olympus/Diamond 400 EFFECTIVE LOC HARD FLOOR — auto-review triggers below 400; submission rejects + wastes Castor tokens**)
- [ ] Tier-appropriate file count (Mars 1–8 mode 3, Olympus 8–35)
- [ ] Pure-function helpers extracted (1+ per behavior)

### Patches
- [ ] Generated against `$BASE_COMMIT` (not HEAD)
- [ ] `test.patch` includes test.sh + all new test files (no solution code)
- [ ] `solution.patch` includes only source files (no tests, no Dockerfile)
- [ ] Both apply cleanly with `git apply` in either order
- [ ] Both can be unapplied with `git apply -R`
- [ ] No untracked files missing (`git status --porcelain` clean)

### Description
- [ ] Action-verb title, 5–10 words, names specific subsystem
- [ ] Tier-appropriate word count (recommended: Mars ≤240, Olympus ≤200; hard cap both: 500)
- [ ] Plain sentences only, no `##` headers, no formulaic labels
- [ ] Backticks only on new public API names
- [ ] No `Box<...>` type wrappers — describe variants in prose
- [ ] No code-instead-of-prose
- [ ] WHAT not HOW
- [ ] Self-contained — solvable from repo + description alone
- [ ] Canonical form spelled out when tests use `assert_eq!` on structures
- [ ] Every described behavior has ≥1 test; every test traces to description; ≤1 codebase-inferable requirement

### Dockerfile
- [ ] Pattern B language-specific slim image (`olympus-base-{python|typescript|go|cpp|jvm}`) for Python/JS/Go/C++/Java; Pattern A (`olympus-base-rust` + chmod/symlink workaround) for Rust workspaces. Legacy generic `olympus-base` / `mars-base` only for re-verifying historical submissions. (May 2026 admin update — slim images speed post-checks.) Java/JVM + C/C++ ✅ supported (2026-05-14 disable reverted).
- [ ] No package manager installation (preinstalled in base)
- [ ] No test execution at build time
- [ ] Builds offline (`--network none`)
- [ ] Uses `CMD ["/bin/bash"]`
- [ ] Verified non-root (`--user 1000:1000`)

### Folder
- [ ] Exactly 5 files: BASE_COMMIT.txt, meta.md, test.patch, solution.patch, Dockerfile
- [ ] No `*_SUMMARY.md` / `*_PLAN.md` / `*_READY.md` / docs

### Solvability

- [ ] Flakiness verification (MANDATORY Core Dev check): the target repo's existing tests AND the new tests must be non-flaky — run base+new at least 3-5x and confirm deterministic, identical pass/fail every run; no timing/ordering(map-set-iteration, parallel-race)/unseeded-RNG/network/clock/filesystem-time dependence; a flaky repo baseline or flaky new test = reject.

**Mars:**
- [ ] 10 Nova/Orion runs at **≤ 30% pass rate** (solvable, 0%=reject)
- [ ] 2 Orion runs at any pass rate (Orion Evaluator)
- [ ] No "description_clear: false" flags, no env-blocker issues

**Olympus:**
- [ ] ≥1 agent passed (solvability cannot be bypassed)
- [ ] Pass rate ≤20% ceiling (0% = reject; >20% = too easy = reject, lowered from 30% on 2026-06-26)
- [ ] 10+ runs with Nova + Orion + Vega mix
- [ ] All prechecks/postchecks pass before agents run
- [ ] Bypassed non-solvability checks have written justifications

---

## Quality Ranks

### Mars Solid — 6 Shapes

After 5 approved Mars problems, every Mars feature falls into one of 6 shapes. Each has a predictable pass-rate band. **See `SHAPES.md § Pattern 11` for full details.**

| Shape | Files | Solution +LOC | Pass Rate Band | Verdict | Best Agent |
|---|---|---|---|---|---|
| **A1 — Distributed pipeline modification** | 3 dist | 167 (P1) | **10–15%** | Diverse (4) | Nova→Orion (slow) |
| **A2 — Concentrated + signature change** | 3 conc + wiring | 220 (P4) | **20–25%** | Diverse (4) | Nova→Orion (fast) |
| **B — Add new public API list** | 3 (2 new) | 377 (P2) | **50–55%** | Mono (Missed) | **Orion-alone** |
| **C — Additive extension (no sig change)** | 1 dense | 358 (P3) | **20–25%** | Mono (Missed) | Nova→Orion |
| **D-new — New cross-crate variant** | 15 (4 crates) | 400 (P_err-rec) | **20–25%** | Diverse — **Integration** | **Orion-alone** |
| **D-change — Cross-crate variant signature change** | 8 (multi-crate) | 340 (P7) | **40–45%** | Diverse — **Regression** | Nova→Orion + Vega |

**Median Mars Solid:** 3 files, 340 LOC, 92 tests, 137 description words.

**Mars file count: 1–15** (D-new can extend to 15 files with thin per-file changes — pest-error-recovery has 15 files at 4 crates and is approved).

### Mars Entry / Strong (Sub-Tiers Within Each Shape)

Within any Mars shape, problems span Entry → Solid → Strong:

| Tier | LOC | Files | Pass |
|---|---|---|---|
| Entry | 100–200 | 1–3 | 25–39% (must stay ≤30%) |
| **Solid (default)** | **170–380** | **1–8 (mode 3)** | **≤ 30%** (was 25-55%; ~2+ traps) |
| Strong | 380–600 | 6–12 | 5–20% |

Target Solid by default. Strong approaching Olympus Okay → consider resubmitting as Olympus. **All Mars now ≤ 30% (the old 25-55% upper bound is gone). A single ~50% trap is too easy — need ~2+ traps or one >60%-miss trap.** See `../CLAUDE.md § ⚠️ HARD RULE — Difficulty-Calibration Model`.

### Olympus — 4 Shapes (+ O-Trap Historical)

After 7 Olympus problems. **See `SHAPES.md § Pattern 12` for full details.**

| Shape | Files | Pass Rate | Verdict | Solver/our LOC | Best Agent |
|---|---|---|---|---|---|
| **O-Composite-extend** (refactor across packages) | 9+ | 25–30%* | Diverse (4) | ~0.98× | **Orion (2/2)** |
| **O-Composite-add** (new feature spanning subsystems) | 12 | 15–20% | Diverse (4) | ~2.13× | **Vega** |
| **O-Pipeline-easy** (familiar coalescing) | 5 | 25% | Diverse (4) | ~1.81× | **Vega** |
| **O-Pipeline-hard** (invent transformation) | 4 | 15% | Diverse (5) | ~1.78× | **Vega** |
| **O-Algorithm-coverage** (missing element trap) | 4 | 10% | 3 types | ~1.49× | **Orion-alone** |
| **O-Algorithm-correctness** (subtle algorithm) | 6 | 8% | 6 types | ~1.27× | Mixed |
| **O-Trap (HISTORICAL ONLY)** | 4 | 0% (bypass) | 2 types | n/a | None |

**O-Trap is no longer viable** post-April 2026 (hints removed; solvability bypass not allowed for Olympus). If you hit a universal LLM blind spot at 0% pass rate, resubmit as Mars or redesign.

### Tier Sub-Ranks (Olympus)

| Rank | Files Modified | Solution LOC | Requirements |
|---|---|---|---|
| **Okay** | 3–10 | 400–600 | 5–10 |
| **Good** (target minimum) | 10–20 | 600+ | 10+ interacting |
| **Excellent** (goal) | 20+ | 600+ (often 800–1500) | 15+ cross-subsystem |

> **File counts and LOC NEVER include test files.** Tests are our hidden verification — written by the problem author, not the agent. "20 files, 800 LOC" means 20 source files and 800 source LOC.

### Solver/our LOC Ratio Varies by Shape

The "agents write 2-3× our LOC" old rule is too generic. Real ratios vary 0.98×–2.13× by shape:

| Highest agent overhead | ~2.13× | O-Composite-add (goja-using) |
| Mid agent overhead | ~1.5–1.8× | O-Pipeline, D-new, A1, A2 |
| Lowest agent overhead | ~1.0× | C (validator), D-change (ext-skip), O-Composite-extend (dagster) |

When sketching a new problem, use the shape's expected ratio to estimate agent LOC.

---

## Rating Guidance

| Verdict | Quality | Difficulty |
|---|---|---|
| **ACCEPT** | 2–3 | 2–3 (3 only when problem requires genuine design decisions) |
| **REQUEST CHANGE** | 1 | 1 |
| **REJECT** | 1 | 1 |

Other ratings: 2–3 based on submission quality.

---

## Rejection Criteria

### 8 valid hard reject reasons (final on platform; message user first)

1. **Existing PR on GitHub** solving the same issue
2. **Maintainer-rejected feature** (philosophy violation)
3. **Wrong language** (must be TS/JS/Python/Go/Rust)
4. **Invalid repo** (<500★, inactive, GPL/AGPL)
5. **Trivial below tier floor** AND not genuinely difficult
6. **Plagiarism / AI-generated submission**
7. **Already-implemented feature** (claimed bug/feature already works)
8. **Out of scope, can't reach Mars Solid floor**

Everything else → REQUEST CHANGE. Always message the user before rejecting — rejections are final.

### Additional Hard Reject Reasons (categorical)

- **Made up feature** — problem doesn't reflect a real need
- **False claims** — described bug/feature already works correctly
- **AI-generated** — submission not original human work
- **Contradicts design** — violates library's explicit philosophy
- **Duplicate with different approach** — another submission for the same core issue exists, even if implementation approach differs

### Rejected categories (do NOT submit these)

- Made-up features that don't reflect a real need
- Standalone modules solvable by creating new files with minimal wiring
- Pattern-followable features (3+ identical structural examples in codebase)
- Solutions under 100 LOC for Mars (under 400 for Olympus)
- Cosmetic refactors or doc-only changes
- Bugs in dependencies, not the project itself

---

## Modified vs New Files — The Real Difficulty Lever

Creating new files is easy. Modifying existing code requires understanding what's there and how changes propagate.

**Good Mars Solid pattern:** 0–2 new core files + 1–8 modified (median: 0 new + 3 modified).
**Good Olympus pattern:** 1–3 new + 8–35 modified (imports, wiring, integration hooks).
**Bad pattern (both tiers):** 5+ new standalone files with minimal modifications.

Mars approveds:
- pest-validator-hardening: 0 new + 1 modified — single dense validator (358 LOC)
- pest-factorizer-fixpoint: 0 new + 3 modified — pure rewrite (220 LOC)
- lightningcss-selector-simplify-fixpoint: 0 new + 3 modified — fixpoint over existing pass (167 LOC)
- pest-unused-rule-elim: 2 new + 1 modified — paired modules wired into optimizer (377 LOC)
- pest-extended-skip: 0 new + 8 modified — multi-crate enum addition (340 LOC)

Older Olympus approveds:
- bumpp: 0 new + 3 modified — pure modification
- goja: 2 new + 10 modified — heavy modification across compiler/parser/VM
- FoalTS: 17–18 modified, 768–922 LOC — passing agents

---

## Difficulty Calibration

### Mars (target ≤ 30% pass rate, solvable)

| Nova/Orion Pass | Mars Rank | How to Achieve |
|---|---|---|
| 25–39% | Entry/Solid | ~2+ interdependent + misdirecting traps, 3–8 files, one subsystem |
| 10–25% | Solid/Strong | 2-3 interdependent + misdirecting traps, 6–12 files |
| 5–10% | Strong | 3 stacked interdependent + misdirecting traps, 8–12 requirements |

**The knob is trap count/strength, NOT requirement count alone** (1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%). **Nova ≈ Castor now — traps must be INTERDEPENDENT (one fix regresses another) + MISDIRECTING (failing test hides the fix), even for Mars/Nova. An isolated self-revealing trap gets single-shot-fixed.**
If Nova >30% → too easy. Add a 2nd interdependent trap with a misdirecting failure OR strengthen one to >60% miss. A uniform-wrap / single-point / self-revealing trap is too easy now.
If Nova 0% across 10 runs → unsolvable, reject. Clarify to pull into ≤30% band, or resubmit as Olympus if genuinely cross-subsystem-hard.

### Olympus (target ~10% pass rate; HARD CAP ≤20%)

| Pass Rate | Rank | How to Achieve |
|---|---|---|
| >20% | **TOO EASY — reject** | add interdependent+misdirecting traps until ≤20% |
| 11–20% (borderline) | Okay | 8–10 requirements, 6–10 files |
| **~10%** | **Good** | **10+ interacting requirements, 10–20 files** |
| **0–5%** | **Excellent** | **15+ requirements, 20+ files, precision wording** |

What you control (inputs):
- Number of files the feature must touch
- Number of interacting requirements
- Precision of wording in each requirement
- Cross-subsystem integration depth
- Negative constraints (what NOT to do)

What follows automatically (outputs):
- Pass rate drops as files and requirements increase
- Agent messages and LOC grow because agents explore and backtrack
- Near-miss patterns emerge (90%+ score, 1–2 edge case failures)

**Difficulty levers (in order of impact):**
1. **Precision wording** — 52% of failures are MISSED_REQUIREMENT. "subjects" vs "commits" trips agents.
2. **File count** — more files = more exploration = more messages and LOC
3. **Interacting requirements** — 10+ at Olympus Good, 15+ at Excellent
4. **Codebase-inferable requirement** — visible in code but not description (0–1 max)
5. **Near-miss tests** — agents score 19/21 = perfectly calibrated

If agents pass too easily, **expand scope** (more files, more requirements) — don't add tricky wording to a small problem.

---

## Real Revert Causes

| Cause | Quote / Symptom | Prevention |
|---|---|---|
| Hidden requirements | "Tests check things not mentioned in description" | Every test must trace to description |
| test.sh trickery | "TS configs run wrong tests" / build-tag swaps | Verify actual test count in both modes |
| Redundant tests | "21 cases is excessive" | Consolidate via parametrization |
| Exact-string assertions | "Use `.toContain()` not exact match" | Substring match for errors |
| Code duplication | "validateCharClass duplicates matchCharClass" | Extract shared helpers |
| Scope creep | "RedactEnv not in description, untested" | Only implement what's described |
| Solution breaks existing | base tests fail after applying solution | Run base after applying solution |
| AI-generated comments | "// CATEGORY 1: Basic Circular References" | No comments unless repo convention |
| Weak assertions | "Returning [] still passes" | Assert specific content, not just shape |
| Wrong package location | "Errors in shared/ should be translatableerror/" | Follow repo's organization |
| Dead code | "_ = negate variable assigned but unused" | Remove all unused code |
| Missing validation | "Zero/negative power not rejected" | Validate all inputs |
| Ambiguous bounds | "'exceeding 5 seconds' — > or >=?" | Use precise comparison operators |
| Non-deterministic tests | "Tests rely on undocumented wakeup order" | Tests must be deterministic |
| Pre-existing test passes | "2 of 22 fail at base" | Most new tests must fail pre-solution |
| Vacuously true assertion | "Trivially true; precondition doesn't trigger" | Verify the precondition actually fires |
| Duplicate tests | "deeply_nested_left_choice and four_adjacent_chars both feed a b c d and assert Range a d" | Check structurally different inputs don't collapse after earlier passes |
| Asymmetric codegen | "NegCharClass uses match_char_by with a closure instead of individual match calls" | Paired variants must use consistent patterns |
| Lossless but less readable merge | "Cyrillic ranges merged into one combined range — less readable" | Check error message readability after optimizations |
| Banned test-filename markers | `"interp/goroutine_lifecycle_shipd_test.go" contains banned marker "shipd"` — predictable to implementer agents | Use random hex suffix: `HASH=$(openssl rand -hex 3)` → `test_{name}_${HASH}.py` / `{name}.${HASH}.test.ts` / `{name}_${HASH}_test.go`. NEVER include `shipd` or `datacurve` in test filenames. Pre-submit guard: `grep -rEl "shipd\|datacurve" tests/ test.sh` must return empty. |
| Passing-agent diffs too small (Mars substance gate) | "The non-empty passed-agent diffs still have a conservative median of `91`, below this reviewer variant's required `> 100`. This is now the main blocker." — measured on PASSING agents' diffs, NOT your reference solution (dasel-compound-assign-operators R1) | Thin-wiring A2 features (wire dead tokens; delegate to existing math/Set) have a small minimal passing solution — agents correctly skip any code the tests don't force. Complete the operator/dimension FAMILY by delegating to existing machinery (added `*= /= %=` reusing existing `Multiply`/`Divide`/`Modulo`): raises required passing LOC ~+20 eff without raising difficulty (mechanical copy of the `+=` path → solvability preserved). FIRST probe l-value / code-path classes empirically — an unreachable guard-rejected branch (here every branch/spread/range target errors `must be a property path`) is dead code, can't be a lever, and is itself a latent dead-code flag. |

---

## Bypass Messages (Non-Solvability Checks)

Solvability cannot be bypassed (Olympus needs ≥1 agent pass; hints removed April 2026). Other failing checks (description_clear, test quality) CAN be bypassed with a written justification reviewers will see.

### Bypass message format — single dense paragraph with 6 elements

1. **What check failed** — name the specific check
2. **Why you believe it's wrong** — concrete reasoning
3. **Evidence with numbers** — agent scores, test counts, verdicts
4. **Dominant failure pattern** — what agents actually did wrong (all agent-fault)
5. **Alignment claim** — every requirement is documented and tested
6. **Conclusion** — why the check result is misleading

### Canonical Bypass Example (pest-normalizer, Mar 15 2026)

This is the reference template — every element is present:

> "All 12 runs produce agent-fault verdicts (MISSED_REQUIREMENT or WRONG_LOGIC) with no fairness flags. The best agent scored 56/57, failing only on sub-expression NormalizedChoice conversion within mixed choices — a behavior explicitly stated in the description ('Any choice chain or sub-expression'). Three agents scored 54+/57. The dominant failure pattern is agents placing normalization after the unroller (where RepOnce is already expanded), despite the description explicitly stating to normalize 'grammar rule expressions (Expr) before they are converted to optimized expressions.' All requirements are explicitly documented, all test expectations align with stated rules, and the reference solution demonstrates full solvability. The problem is legitimately challenging — requiring correct pipeline placement, context-sensitive empty-string handling, and two-phase architecture — but all information needed is available in the description and codebase."

### 6-Element Mapping in the Canonical Example

| # | Element | Where in the example |
|---|---|---|
| 1 | What check failed | "All 12 runs produce agent-fault verdicts" (implies solvability) |
| 2 | Why it's wrong | "with no fairness flags" |
| 3 | Evidence | "Best agent 56/57, three agents 54+/57" |
| 4 | Dominant failure | "Placing normalization after the unroller, despite description stating to normalize before optimization" |
| 5 | Alignment claim | "All requirements explicitly documented, all test expectations align, reference solution demonstrates solvability" |
| 6 | Conclusion | "Problem is legitimately challenging but all info available" |

### Bypass Eligibility — All 6 Conditions Required

A bypass is approvable ONLY when ALL of these hold:
1. ✅ All failures are agent-fault (Missed Requirement, Wrong Logic, Execution Error, Early Termination)
2. ✅ Zero infrastructure verdicts (no Integration Error, no Regression on the bypassed check, no Syntax Error)
3. ✅ Near-miss evidence: ≥1 agent at 90%+ test score
4. ✅ Multiple distinct failure modes (not all agents fail identically)
5. ✅ Reference solution demonstrably works
6. ✅ Specific failure pattern is named and traced to description text

### Smaller Bypass Example (description_clear flag only)

> "The description_clear check flagged 2/12 evals as unclear, but all 12 agents attempted the correct feature (normalizer pass). The 2 flagged evals scored 41/57 and 47/57 tests respectively — both understood the task but had WRONG_LOGIC in fixpoint convergence. The remaining 10 evals all have description_clear: true. Every requirement in the description maps to at least one test, and every test traces back to a described behavior. The 2 false flags are agent implementation failures, not description ambiguity."

### Rules

- One paragraph, no bullets or headers
- Specific numbers (scores, counts, percentages)
- Name verdict types explicitly (MISSED_REQUIREMENT, WRONG_LOGIC, EXECUTION_ERROR, EARLY_TERMINATION)
- Make the "all agent-fault, not test/description-fault" argument explicitly
- **Never bypass Olympus solvability** — that path is closed (post-April 2026)
- For Mars: solvability needs ≥1 Nova/Orion solve in 10 runs at **≤ 30% pass** (0%=reject); otherwise resubmit as a different shape

### Post-April 2026 — What's No Longer Bypassable

| Check | Bypass eligible? |
|---|---|
| description_clear (one outlier eval) | ✅ Yes |
| test_quality MEDIUM/LOW warnings | ✅ Yes |
| problem_precision_and_alignment | ✅ Sometimes (with strong evidence) |
| **Olympus solvability (0/N pass)** | ❌ **No (hints removed)** |
| Mars Nova pass rate <10% | ❌ No — fix the problem |
| Env blocker (real Docker issues) | ❌ No — fix the Dockerfile |

### Historical: pest-normalizer 0% Bypass (Pre-April 2026)

pest-normalizer was approved at 0% pass rate (12 evals, 0 PASS) using a solvability bypass. Evidence used:
- Best agent scored 47/57 tests (82%) — clear near-miss
- All 12 failures were agent-fault: MISSED_REQUIREMENT (8) and WRONG_LOGIC (4)
- 0 FAIL_TEST_MISMATCH, description_clear: true on all 12 evals

**This approach is NO LONGER valid** as of April 2026 — solvability now requires at least 1 agent pass and cannot be bypassed.

---

## Track Record

### Mars Approveds (April 2026, primary reference)

| Problem | Repo/Lang | +LOC | Files | Tests | Desc Words | Key Lesson |
|---|---|---|---|---|---|---|
| pest-validator-hardening | pest/Rust | 358 | 1 | 39 | 91 | Single-file dense diagnostics, substring-match error tests |
| lightningcss-selector-simplify-fixpoint | lightningcss/Rust | 167 | 3 | 68 | 107 | Fixpoint over CSS, "adjacent positions only" rule |
| pest-factorizer-fixpoint | pest/Rust | 220 | 3 | 92 | 137 | Fixpoint rewrite, helper extraction, rule-map resolution pre-empt |
| pest-extended-skip | pest/Rust | 340 | 8 | 102 | 183 | Multi-crate enum addition, sort-order spec, parallel API |
| pest-unused-rule-elim | pest/Rust | 377 | 3 (2 new) | 160 | 241 | 13 public functions, parallel optimized API |

**Median Mars Solid:** 340 LOC, 3 files, 92 tests, 137 description words. See `PLAYBOOK.md` for forensic synthesis.

### Olympus Approveds — With Full Agent-Run Data (8 problems)

| Problem | Lang | LOC | Files | Tests | Pass Rate | Shape | Best Agent | Key Lesson |
|---|---|---|---|---|---|---|---|---|
| pest-charclass | Rust | ~433 | 5 | 104 | **25%** | O-Pipeline-easy | Vega (3/5) | Pattern coalescing / interval merging |
| pest-seq-rewriter | Rust | ~413 | 4 | 103 | **15.4%** | O-Pipeline-hard | Vega (2/6) | Sequence transformation, multi-target test.sh |
| pest-dispatch | Rust | ~532 | 6 | 62 | **8.3%** | O-Algorithm-correctness | Mixed | Fallback re-dispatch trap (Wrong Logic 25%) |
| pest-inliner | Rust | ~379 | 4 | 68 | **10%** | O-Algorithm-coverage | Orion-alone (1/1) | Multi-pass coverage trap (`count_references`) |
| pest-normalizer | Rust | ~414 | 4 | 57 | **0% (bypass)** | O-Trap (HISTORICAL) | None | Pipeline placement universal blind spot |
| goja-using-declarations | Go | ~366 | 12 | 73 | **16.7%** | O-Composite-add | Vega (3/5) | Multi-subsystem (parser/compiler/VM/runtime) |
| dagster-dep-health | Python | ~600 | 9+ | 162 | **30%** (hinted) | O-Composite-extend | Orion (2/2) | Aggregation refactor (Vega blind spot) |
| pest-error-recovery | Rust | ~400 | 15 | 126 | 21.4% | D-new (Mars per user) | Orion-alone (2/2) | FnMut closure bound, multi-target test.sh |
| yaegi-execution-tracer | Go | ~441 | 5 | 54 | **10%** (2/20 Castor at Diamond eval; tier-downgraded to Olympus) | O-Composite-add | Mixed | Frame-anchored state propagation beats goroutine-id maps in interpreters; concrete counter-example hint dropped failure 100%→22% |

### Older Olympus Approveds (no full agent-run data)

| Problem | Lang | Tests | Pass Rate | Key Lesson |
|---|---|---|---|---|
| bumpp | TS | 50 | 10% | Merge subject filtering, BREAKING CHANGE body parsing |
| canopy | Go | 14 | 30% | Version 0 validation (single test caught 4 agents) |
| h2 | Python | 26 | 10% | `_begin_new_stream` hook, flow control |
| httpx | Python | 69 | 30% | Trio compatibility (anyio over asyncio) |
| ormar | Python | 39 | 20% | `.limit(1)` bounded, `.correlate()` misuse |
| oxvg | Rust | 21 | 10% | href/xlink:href equivalence |

### Approved by repository

| Repo | Lang | Count | Pattern |
|---|---|---|---|
| Elysia | TS | 12 | Lifecycle/hook bugs, context propagation |
| pest | Rust | 6 | Optimizer passes + grammar-level error recovery |
| Happy-DOM | TS | 2 | CSSOM View API, Cookie Store API |
| bunster | Go | 2 | Shell feature compilation |
| yaegi | Go | 2 | reflect.Type identity (Mars); execution tracer (Olympus) |
| bumpp, canopy, cron-parser, dagster, goja, h2, httpx, ormar, oxvg | Various | 1 each | Various |

### Overall Statistics
| Category | Submitted | Approved | In Review | Rejected | Too Easy |
|---|---|---|---|---|---|
| Bugs | 20 | 15 | 0 | 2 | 3 |
| Features | 13 | 12 | 1 | 0 | 0 |
| TOTAL | 33 | 27 | 1 | 2 | 3 |

### Success Patterns (100% Approval Rate)
- Lifecycle/Hook bugs: 6 approved
- Context propagation: 3 approved
- Web API implementation: 2 approved
- Algorithm implementation: 1 approved

### Rejection Reasons (Historical)
| Issue | Reason | Lesson |
|---|---|---|
| Elysia #1379 | Too simple (15 lines) | Solution must be 400+ lines (Olympus) or 100+ (Mars) |
| Elysia #1532 | Intentional behavior | Read docs first |
| Happy-DOM #1878 | Well-known pattern | Avoid obvious AI patterns |
| Happy-DOM #1963 | Fix in comments | If answer is in issue, AI finds it |

### Agent failure categories (from 13 approved problems)

| Category | Frequency | Description |
|---|---|---|
| **MISSED_REQUIREMENT** | dominant in most shapes | Explicitly stated requirement not implemented |
| **WRONG_LOGIC** | dominant in O-Algorithm-correctness, O-Algorithm-coverage | Correct understanding, buggy implementation. **≥25% Wrong Logic = subtle algorithmic trap (hardest problems)** |
| **REGRESSION** | dominant in D-change | Broke baseline tests |
| **INTEGRATION_ERROR** | dominant in D-new | Compile error in cross-crate exhaustive match |
| **EXECUTION_ERROR** ⭐ NEW | rare (~4% in P9) | Runtime crash distinct from compile error or logic error |
| **EARLY_TERMINATION** ⭐ NEW | up to 17% in hardest Olympus | Agent stops without completing — context exhaustion (Nova thrashing 1000+ msgs) or premature commit (153 LOC, "I'm done") |
| UNVERIFIED_ASSUMPTION | ~4% | Assumed API existed without checking |
| KNOWLEDGE_GAP | ~2% | Lacked framework-specific knowledge |
| MISUNDERSTOOD_TASK | ~2% | Wrong scope entirely |

### Verdict patterns by shape

The dominant verdict tells you the problem's shape and risk profile:

| Dominant verdict | Shape signal |
|---|---|
| Missed Requirement | A1, A2, B, C, D-change, O-Composite-extend, O-Pipeline (most shapes) |
| **Integration Error** | **D-new** (cross-crate variant addition — exhaustive match risk) |
| **Regression** | **D-change** (existing variant signature change — old tests break) |
| **Wrong Logic ≥25%** | **O-Algorithm-correctness, O-Algorithm-coverage, O-Trap** (subtle algorithm traps) |
| Early Termination | Heaviest Olympus problems (goja-using-style multi-subsystem) |

### Hardest lessons learned

1. **"Too easy" is unsalvageable.** If a feature is pattern-followable (3+ identical structural examples), no test hardening fixes it. Pick a harder problem.
2. **Test count ≠ difficulty.** Cutting 118→87 tests on dasel-ndjson had zero effect on pass rate. Architectural complexity drives difficulty.
3. **test.sh is the #1 infrastructure failure.** More submissions fail on JUnit XML than any other reason. Test by deliberately breaking the build and verifying XML still appears.
4. **Correlated blind spots** between solution and tests = no test catches the gap. Trace each requirement to BOTH implementation AND ≥1 test.
5. **Inverse rule trap.** "X happens when Y is not configured" doesn't imply "X must NOT happen when Y is configured." 60% of fairness rejections.
6. **Niche repos beat popular ones.** Less training data = genuine knowledge gaps without unfairness.
7. **REGRESSION is Rust-specific.** All 8 REGRESSION verdicts came from pest problems — new enum variants not handled in all exhaustive matches across crates. Multi-target test.sh is the defense.

### Lessons From Approved Problems (Detailed)

**Multi-target test.sh catches cross-crate failures:**
pest-seq-rewriter uses 3 test targets (meta, vm integration, derive integration). This caught agents who only updated pest_meta but forgot vm/generator. For Rust problems with new enum variants, test across ALL consuming crates.

**Explicit type signatures prevent agent type confusion:**
Adding explicit types to description fixed issues where agents chose incompatible type signatures.

**"zero or more" must be literal:**
Agents consistently misread "zero or more X" as "one or more X". The zero case is a clean discriminating test.

**REGRESSION is Rust-specific:**
All 8 REGRESSION verdicts across 130 evals come from pest problems. Root cause: new enum variant not handled in all exhaustive match arms across crates. Multi-target test.sh is the defense.

**EARLY_TERMINATION is file-count-specific:**
Only goja (12 files) has EARLY_TERMINATION verdicts (2/12). More files = more exploration = agents exhaust context budget.

**Display tests are dangerous for new enum variants:**
When adding new enum variants that resemble existing ones, agents copy the existing Display format. Either match the existing pattern or don't test Display at all.

**Baseline regression traps work for free:**
Existing test suites catch careless integration. httpx's `test_exported_members` caught 2 agents who leaked imports. Include ALL existing tests in `test.sh base`.

**Duplicate tests after pipeline passes:**
When the repo has a multi-pass pipeline, structurally different inputs may collapse to the same intermediate form after earlier passes. Reviewers will flag these as duplicates.

### Features already used (don't duplicate)

| Repo | Feature | Status |
|---|---|---|
| pest | Rule inlining (pest-inliner) | Approved |
| pest | Expression normalizer (pest-normalizer) | Approved |
| pest | CharClass coalescing (pest-charclass) | Approved |
| pest | Sequence rewriting (pest-seq-rewriter) | Approved |
| pest | Choice dispatch (pest-dispatch) | Approved |
| pest | Extended skip (pest-extended-skip) | Approved (Mars) |
| pest | Grammar error recovery (pest-error-recovery) | Approved |
| pest | Validator hardening (pest-validator-hardening) | Approved (Mars) |
| pest | Choice factorizer fixpoint (pest-factorizer-fixpoint) | Approved (Mars) |
| pest | Unused-rule elimination (pest-unused-rule-elim) | Approved (Mars) |
| lightningcss | Selector simplify fixpoint | Approved (Mars) |
| goja | using/await using declarations | Approved |
| canopy | Snapshot export/import | Approved |
| httpx | Retry with backoff | Approved |
| h2 | Priority-based stream scheduler | Approved |
| ormar | Subquery/OuterRef/Exists | Approved |
| oxvg | mergeDefs structural deduplication | Approved |
| bumpp | workspaceConventional option | Approved |
| dagster | Dependency health dimension with SLA tiers | Approved (hint-bypassed, path closed) |
| yaegi | Execution tracer (call/return/line events + call graph + line coverage) | Approved Olympus 2026-05-14 (tier-downgraded from Diamond eval) |

---

## Auto-Check Pattern Summary

All approved problems show `minor_suggestions` verdict with only MEDIUM/LOW items:
- 10 problems: 100% description_clear: true on all evals
- pest-charclass: 10/12 true (2 false). pest-seq-rewriter: 11/12 true.
- **0 FAIL_TEST_MISMATCH across 130 evals** — hard requirement
- Common MEDIUM: "remove implementation detail X", "trim redundant clause Y"
- Common LOW: "drop explanatory suffix", "remove obvious recursive rule"
- **MEDIUM/LOW are advisory** — approved as-is in all cases
- HIGH items would block (none encountered in any approved problem)

### Automated Check Responses

- "Tests pass without solution" → tests don't catch the feature, need harder tests
- "Tests have comments" → remove AI-generated; keep repo-convention comments
- "Solution has comments" → remove AI-generated; keep repo-convention comments
- "meta.md too long" → cut filler, keep substance
- "Dockerfile fails to build" → check slim image (`olympus-base-{lang}`) compatibility; legacy `olympus-base` / `mars-base` only for historical re-verify
- "Solvability (0 agents pass)" → **cannot be bypassed** for Olympus

---

## Archive Structure (After Approval)

### Mars archive (6 files)

```
Mars Approved V2/Feature Requests/{repo}/{reponame}-{issue}/
├── BASE_COMMIT.txt
├── meta.md
├── test.patch
├── solution.patch
├── Dockerfile
├── Nova Runs.md            # 10 Nova + 2 Orion eval results, Orion Evaluator verdicts
└── Checks Run.md           # OPTIONAL — only if AI checks returned warnings worth archiving
```

### Olympus archive (7–8 files)

```
Olympus Approved/Feature Requests/{repo}/{reponame}-{issue}/
├── BASE_COMMIT.txt
├── meta.md
├── test.patch
├── solution.patch
├── Dockerfile
├── Agents Runs.md          # Per-run JSON eval results
├── Checks Run.md           # Verbatim platform AI check output
└── Bypass Massage.md       # OPTIONAL — only if a non-solvability check was bypassed
```

**Strip from archive:** repo clone, `Ai Review.md`, scratch notes, draft patches, build artifacts, dotfiles, `uv.lock`/`pyproject.toml`, `.git/`. See `Mars Approved V2/Feature Requests/pest/pest-validator-hardening/` for a clean Mars reference.
