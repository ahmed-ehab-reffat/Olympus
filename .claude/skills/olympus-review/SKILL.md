---
name: olympus-review
description: Use when reviewing an Olympus / Diamond submission (one tier since the 2026-07 sprint merged Mars into Olympus; current floor >=200 effective LOC / >=2 files / >=40 solver-median messages, pass ceiling <=40%). Applies the 7-stage evidence-based Reviewer process (hard-block precheck, Pattern 22 GitHub audit, submission understanding, rejection eligibility, description, tests, solution, subtle bugs, Diamond branch). Reviewer scope = visible artifacts only: meta.md + test.patch + solution.patch + Dockerfile (Olympus) + failure-qa.md + test-groups.md + solution-approach.md + Env Description (Diamond). NEVER base review on author-only files (DESIGN.md, feedback.md, eval-results.md). Triggers when user mentions "review submission", "Mars review", "review this problem", "check this submission", "/review", or opens a problem folder containing meta.md + test.patch + solution.patch + Dockerfile. Source of truth: Admin-Review/docs/MARS-REVIEW-GUIDE.md and .agents/workflows/review.md. Evidence: Admin-Review/docs/REVIEWER-PATTERNS.md (26-sub mined dataset, 23 patterns ranked by hit count). CLAUDE.md RULE UPDATE 2026-07 (SPRINT).
---

# Olympus / Mars / Diamond Submission Review

> **SPRINT UPDATE 2026-07 (supersedes 2026-06-26 bands below where they conflict):** Mars merged into Olympus -- ONE TIER now, author/review everything as Olympus. New long-horizon floor: **>=2 file changes, >=40 agent messages (solver median), >=200 effective LOC** (down from 3 files / 100 msgs / 450 LOC). Pass-rate ceiling raised to **<=40%** (up from 20%/30%). FP Check now MANDATORY (final gate, after solvability). See CLAUDE.md RULE UPDATE 2026-07 (SPRINT).
>
> Bands updated 2026-06-26 (historical, superseded on conflict): Mars <=30%, Olympus <=20% (down from 30%); flakiness verification now MANDATORY. See CLAUDE.md RULE UPDATE 2026-06-26.

Final line of defense. Non-compliance = offboarding. Time budget: 40-45 min (45 min Diamond).

## Hard Rules

- **REJECTION IS FINAL** -- user cannot edit after. Prefer Request Change unless one of the 8 hard-reject reasons fires.
- Always message user before rejecting.
- Read all files line by line. Never assume intent.
- Do NOT let AI write feedback -- leadership monitors. Use format + verbatim vocabulary banks in `Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md`, but words must be yours.
- Self-check your own feedback for em-dashes + AI cadence before submitting.

## 7 Stages

| Stage | Time | Focus | Reference |
|---|---|---|---|
| **0** | 3m | Hard-Block Precheck | inline below |
| **1** | 7m | Pattern 22 GitHub Audit (6 sub-checks) | `Admin-Review/docs/GITHUB-QUERIES.md` |
| **2** | 4m | Project + Submission Understanding (visible artifacts only) | inline below |
| **3** | 2m | Rejection Eligibility (8 reasons) | `Admin-Review/docs/check_rejection.md` |
| **4** | 8m | Description Review (A1+A3+A4+A8) | `Admin-Review/docs/check_description.md` |
| **5** | 8m | Test Review (A5+A6+A13+A14) | `Admin-Review/docs/check_test.md` |
| **6** | 8m | Solution Review (A2+A9+A10+A15) | `Admin-Review/docs/check_solution.md` |
| **6.5** | 3m | Subtle Bugs (A19+A20) | `Admin-Review/docs/check_subtle_bugs.md` |
| **7** | 5m | Diamond Branch (if `diamond-problems/`) | `Admin-Review/docs/MARS-REVIEW-GUIDE.md Stage 7` |

---

## Stage 0 -- Hard-Block Precheck (3 min)

100% deterministic blockers. Any RED = HARD REJECT, do NOT proceed.

```bash
cd <submission-folder>

# A4 em-dash hard-reject (9/9 hit, only cliffy-aliases outlier in 51 approveds)
rg '[\xE2][\x80][\x90-\xAB]' meta.md   # must be empty

# meta.md ASCII check
file meta.md   # must say "ASCII text" (NOT "UTF-8 Unicode text")

# A13 banned-marker hard-reject (precheck rejects)
grep -rEl "shipd|datacurve" tests/ test.sh   # must be empty

# test.sh executable bit (mode 100755 in patch)
grep "new file mode" test.patch | head -3   # must show 100755 for test.sh

# Patch encoding (Windows UTF-16LE trap)
file *.patch   # must say "ASCII text", NOT "Little-endian UTF-16"

# Smart quotes / ellipsis check
rg '[\xE2][\x80][\x98-\xA6]' meta.md feedback.md 2>/dev/null   # must be empty
```

Running these up-front saves 20+ min on the inevitable revert when caught at Stage 5+.

---

## Stage 1 -- Pattern 22 GitHub Audit (7 min)

CLAUDE.md "CRITICAL RULE" with 4 documented expensive misses (incl. dasel-multi-file Diamond rejected at Stage 0 after Castor 7x + Diamond Checks + Failure QA all GREEN).

Full 6-check protocol. See `Admin-Review/docs/GITHUB-QUERIES.md` for full bash recipes + 3 worked examples.

```bash
# 1. Literal name search
gh pr list   -R OWNER/REPO --state all --search "<exact-func-name>"
gh issue list -R OWNER/REPO --state all --search "<exact-func-name>"

# 2. Namespace expansion
gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"

# 3. Maintainer philosophy scan
gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("prefer not to") or contains("by design") or contains("namespace") or contains("pollute") or contains("won'\''t add") or contains("rejected"))'

# 4. Closed-with-implemented (catches post-base shipping)
gh issue list -R OWNER/REPO --state closed --search "<feature-keyword>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("implemented") or contains("supported in V") or contains("This is in v"))'

# 5. Base->main commit overlap (in clone)
git log --oneline <BASE_COMMIT>..HEAD -- <relevant-source-files>

# 6. Existing-capability functional check
cd /tmp/<repo>-main && <build-cmd> && <CLI-test>
# If 80%+ of feature scope works on main HEAD -> REJECT (already implemented)
```

Any hit checks 1-6 -> RED (abandon) or YELLOW (redesign required) -> HARD REJECT or REQUEST CHANGE per severity.

---

## Stage 2 -- Project + Submission Understanding (4 min)

**Reviewer scope -- visible artifacts only:**

| Tier | Visible artifacts |
|---|---|
| Mars / Olympus | `meta.md`, `test.patch`, `solution.patch`, `Dockerfile` |
| Diamond | + `failure-qa.md`, `test-groups.md`, `solution-approach.md`, Env Description (Shipd UI text >=300 chars) |

**Author-only (NOT reviewer-visible):** `DESIGN.md`, `feedback.md`, `eval-results.md`. These are internal authoring artifacts -- never base any review decision on them.

Internal cross-checks across visible artifacts:

| Cross-check | Look for |
|---|---|
| Tests <-> Description | Every test in `test.patch` traces to a sentence in `meta.md` (A6) |
| Description <-> Tests | Every described behavior in `meta.md` has >=1 test in `test.patch` |
| Solution <-> Tests | `solution.patch` makes new tests pass + base tests still pass (verify Stage 5) |
| Public API <-> Tests | Every exported symbol named in `meta.md` is asserted by a test (A1) |
| Trap matrix <-> Tests (Diamond) | If `solution-approach.md` names a trap, a test in `test.patch` catches it |
| Test Summary <-> Description (Diamond) | `test-groups.md` quotes meta.md requirements per group |

Reviewer-side authoring-reference (for own pattern matching, not the submission): `Olympus/Instructions/SHAPES.md` shape table, `Olympus/Instructions/PROBLEM-PROFILES.md` closest precedent. These help YOU spot whether the submission's file count + LOC + trap design matches a known shape; they are NOT requirements for the submission itself.

Output:
```
- Project purpose:
- Project philosophy:
- Requested change:
- Expected behavior:
- Fully implemented? Yes/No
- In scope? Yes/No
- Aligned with repo philosophy? Yes/No
- Trivial (one-liner)? Yes/No
- Tier visible: Mars / Olympus / Diamond
- Internal cross-check discrepancies (if any):
```

Base conclusions only on provided files.

---

## Stage 3 -- Rejection Eligibility (2 min)

**Canonical 8 hard-reject reasons** (reconciled across all docs). See `Admin-Review/docs/check_rejection.md` for full protocol + Pattern 22/23/32 + precedent cases.

| # | Reason | Check |
|---|---|---|
| 1 | Existing PR on GitHub | Stage 1 Pattern 22 found one |
| 2 | Maintainer-rejected feature class | Pattern 22 check 3 found philosophy comment |
| 3 | Wrong language | Not TS/JS/Python/Go/Rust (Java/C++ UNSUPPORTED as of 2026-05-14) |
| 4 | Invalid repo | <500 stars, inactive >12mo, GPL/AGPL |
| 5 | Trivial below tier floor | One-liner; pattern-followable (Pattern 23) |
| 6 | Plagiarism / AI-generated | Not original |
| 7 | Already-implemented feature | Pattern 22 check 6 capability test passed (80%+ works) |
| 8 | Out of scope, can't reach tier floor | Genuinely too small |

Everything else -> **REQUEST CHANGE** (description issues, test issues, solution bugs, AI comments -- all fixable).

> Minor description issues are NOT valid rejection reasons.

---

## Stage 4 -- Description Review (8 min)

See `Admin-Review/docs/check_description.md` Gate 1-7 for full per-pattern detail.

Top patterns ranked by hit count:
1. **A1** -- API enumeration gaps (22/26 hit, TOP) -- every exported symbol named, including pre-existing classes tests import (CRITICAL: `CommandError` lesson from cliffy-output-format, hit TWICE -- second time 0/10 regression)
2. **A3** -- AI cadence / tech-spec tone (18/26) -- no "Sure!", "I'd be happy", "It's important to note", "In essence", "At its core", "Notably", "This approach", paired clauses, forced tricolons
3. **A4** -- em-dash zero-tolerance (Stage 0 should have caught)
4. **A8** -- pre-existing class export hints (12/26) -- AI HIGH suggestions to remove these are PROVEN REGRESSORS
5. **F1** -- subtle but fair sweet-spot (2+ clues present, agents connect them)
6. **F2** -- <=1 codebase-inferable rule cap
7. **Per-shape word budget** (Mars C ~91 / A1 ~107 / A2 ~137 / D-new ~148 / D-change ~183 / B ~241; Olympus <=200; hard cap 500 both)

Quick checklist:
```
[ ] **First sentence of the body reads as the ask** (`Add <capability> to <subsystem>.`), not as
    narration of current behavior. Reviewers are graded on the description and the title is often
    not shown beside it. Request Change if the body opens by describing the current state.
[ ] Clear problem + expected outcome
[ ] Behavioral focus (WHAT not HOW)
[ ] Deterministic (implementable from description alone)
[ ] Word count within per-shape budget (hard cap 500)
[ ] Human wording (real GitHub issue, not tech spec)
[ ] ALL tested requirements mentioned in description (A6 alignment)
[ ] No ## headers, no formulaic labels
[ ] Backticks ONLY for new public API names
[ ] No code-instead-of-prose
[ ] <=1 codebase-inferable requirement
[ ] Pre-existing classes tests import are listed in meta.md (A8)
```

**Quality rating 1-7. Pass = 5+.**

---

## Stage 5 -- Test Review (8 min)

See `Admin-Review/docs/check_test.md` Gate 1-8 for full per-pattern detail.

```bash
./test.sh new   # MUST FAIL pre-solution
./test.sh base  # MUST PASS pre + post solution
# (after git apply solution.patch)
./test.sh new   # MUST PASS post-solution
```

If new tests pass pre-solution -> REJECT (useless tests).

**MANDATORY flakiness check (reviewer gate, NEVER SKIP):** run the full suite (base + new) at least 3-5 times; pass/fail must be deterministic and identical every run. REJECT on any timing-dependent assertion, ordering-dependent test (map/set iteration order, parallel races), unseeded RNG, network/clock/filesystem-time dependence, or resource-contention race. A flaky repo baseline OR a flaky new test = reject; if the repo baseline is known-flaky, base mode must be scoped to solution-relevant tests and that must be documented.

```bash
for i in 1 2 3 4 5; do ./test.sh base; ./test.sh new; done   # results identical every iteration
```

**Classify every tested behavior into one of four buckets — this is the platform Test Fairness
panel's own vocabulary, so classifying first lets you pre-empt its verdict:**

| Bucket | Meaning | Verdict |
|---|---|---|
| **Prompt-stated** | the meta says it, in words an agent can read | fair |
| **Repo-discoverable** | established by existing public repo behavior/convention (cite file:line) | fair |
| **Standard external semantics** | fixed by a spec/standard the prompt names | fair |
| **Flexible / underspecified** | the prompt leaves it open | **unfair to pin** |
| **Outside scope** | only the reference solution implements it | **unfair** |

Flag as UNFAIR any test requiring: an unstated representation or algorithm; internal helpers,
private APIs or file layout; exact error text not established by the repo; external protocol
semantics the prompt never names; or behavior only the reference implements.

**Flexible wording must stay flexible.** Words like canonical, normalized, opaque, stable,
preserve, kept, comma-separated must not be read more narrowly than the prompt defines. Measured:
lyon's `assert_unchanged` read "kept" as exact index-buffer equality and was flagged — the prompt
only promised the vertices survive in relative order, so an alternative conforming triangulation was
legal.

**Assertions on the PRE-feature (disabled/base) artifact are unfair unless the prompt describes the
current behavior.** Measured: 6 of 45 lyon tests were flagged for pinning the disabled mesh's
classification counts. The fix is to STATE the current behavior in the description, not to delete
the assertion.

Top patterns:
1. **A5** -- weak assertions (17/26): STRONG `assert_eq!` on exact / MEDIUM substring on errors / WEAK-REJECT `Contains`, `toBeDefined`, `length > 0`, `is_ok()`
2. **A6** -- test-description alignment (15/26): every test traces to description; every described behavior has >=1 test
3. **A13** -- test.sh trickery (15/26): mode 100755, LF, `--output_path` position-independent, banned markers, both modes work. Also verify: base and new modes are DISTINCT sets; no fail-fast (one failure must not suppress the rest); nonzero exit propagates; JUnit XML is per-test and well-formed; **no duplicate and no missing `<testcase>` names**, and the f2p name set emitted WITHOUT the solution must equal the set emitted WITH it (measured on lyon: a build-failure fallback emitted a single synthetic `cargo-test.compilation` that belonged to neither the p2p nor f2p set and failed Verify Solution); no package install, no network
4. **A14** -- build-failure JUnit fallback (8/26): Deno `--no-check` + synthetic XML
5. **A11** -- AI test comments (10/26): no `// CATEGORY`, `// Step N`, `// Debug`, `// SETUP`, `// TODO`
6. **A19** -- reflection-test thoroughness (5/26): Go embedding receivers, cross-file struct-tag scans

**Quality rating 1-7. Pass = 5+.**

---

## Stage 6 -- Solution Review (8 min)

See `Admin-Review/docs/check_solution.md` Gate 1-6 for full per-pattern detail.

```bash
./test.sh base  # MUST still pass after solution (no regressions)
./test.sh new   # MUST pass after solution
```

Top patterns:
1. **A2** -- dead code (20/26, SECOND-MOST-FLAGGED): audit EVERY helper, EVERY import, EVERY type field. Verbatim: "`_ = negate` -- variable assigned but never used", "Remove or use `ErrBadPattern`; it's never used"
2. **A10** -- scope creep / "Would you accept this PR?" (11/26 + 6 REJECTED): solution touches only files needed for described feature
3. **A15** -- pipeline ordering bugs (11/26): writer-side null mirror, trim-before-null, classify-before-frame
4. **A9** -- defensive copy / mutation / snapshot (11/26): `.slice()` breaks ref-sharing on outer array but not nested elements
5. **A16** -- concurrency / lock-scope (6/26): RWMutex precision, `-race` flag as universal blocker
6. **A17** -- constructor / factory defaults (8/26): `|| Infinity` vs `?? Infinity` (0 vs nullish)

**Current sprint floor (2026-07, ONE TIER -- Mars merged into Olympus):**

| Metric | Floor (hard gate) | Notes |
|---|---|---|
| Solution LOC | **>=200 effective/meaningful** (Counter 2 / human-effective) | Down from 450. Gate on the human-effective count, not raw. |
| Files modified | **>=2** | Down from 3. Median observed in older approveds (~17) is historical data, not a floor -- do not reject a submission for being below it. |
| Agent messages (solver median) | **>=40** | Down from 100. |
| Pass-rate ceiling | **<=40%** | Up from 20%/30%. 0% = reject (unsolvable); >40% = reject (too easy). |
| Diamond | Same floor + Castor-targeted (<=30% Castor: 1-3 of 10); NO upper LOC ceiling | |

Older per-shape LOC/file/test figures elsewhere in this doc (e.g. Mars-shape tables in `olympus-author`, "8-35 files" bands) are OBSERVATIONAL DATA from specific approved problems under the old two-tier regime -- useful as precedent, but the hard gate for every NEW submission is the row above. Do not reject solely for sitting below an old shape's historical average once it clears >=200 LOC / >=2 files / >=40 messages.

**Pass-rate ceiling (0% any tier = reject) -- current sprint, superseded from the table below:**

| | Pass band | Too easy (reject) |
|---|---|---|
| Olympus (one tier, non-Diamond) | **<=40%** | >40% (up from 20%/30% -- 2026-07 sprint) |
| Diamond | <=30% Castor (1-3 of 10) | >30% (unchanged) |

<details>
<summary>Historical Mars/Olympus split (pre-2026-07, superseded)</summary>

| Tier | Pass band | Too easy (reject) |
|---|---|---|
| Mars | <=30% Nova/Orion | >30% |
| Olympus | <=20% ceiling (~10% Good) | >20% (down from 30% -- 2026-06-26) |
</details>

Test manually: edge cases, modifier/flag handling, all code paths.

**Ask: "Would I merge this PR as a maintainer?"**

**Quality rating 1-7. Pass = 5+.**

---

## Stage 6.5 -- Subtle Bugs (3 min)

See `Admin-Review/docs/check_subtle_bugs.md`.

3 categories not covered elsewhere:
1. **A19** reflection patterns -- Go embedding receivers, cross-file struct-tag scans
2. **A20** agent-specific blind spots -- Castor go.mod regression denial, Vega prescriptive-hint dependence, Nova Go-embedding misses
3. **Section D** -- 5 specific failure modes reviewers caught that authors missed

Time-boxed 3 min. If clean, exit.

---

## Stage 7 -- Diamond Branch (5 min, conditional)

Run ONLY if submission path starts with `diamond-problems/`. Skip for Mars/Olympus.

Diamond-specific checks:
- [ ] `failure-qa.md` present + covers every Castor run
- [ ] Per-run audit-grade "Expected X, got Y" with literal values
- [ ] Every entry self-contained (no "same as Castor #1")
- [ ] No fabricated identifiers (grep-verify each named method/var)
- [ ] No trajectory step references ("At step N...")
- [ ] Plain ASCII only (re-verify `rg '[\xE2]' failure-qa.md`)
- [ ] Environment Description >=300 chars in Shipd UI (effective ~2026-05-21)
- [ ] `test-groups.md` + `solution-approach.md` present
- [ ] Castor pass rate <=30% (1-3 of 10)

See `Olympus/Instructions/DIAMOND.md Failure QA Guide` + `Olympus/Instructions/DIAMOND-PLAYBOOK.md Section 5` for full failure-QA writing rules.

---

## Verdict

| Condition | Action | Quality |
|---|---|---|
| All stages green | **ACCEPT** | 5-7 (Pass = 5+) |
| Stage 0/1/3 hard-reject reason | **REJECT** (final) | 1 |
| Fixable issues at Stage 4/5/6 | **REQUEST CHANGE** | 2-4 |

Composite quality = require all of description / tests / solution >=5.

---

## Feedback Format

See `Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md` for full vocabulary banks (approval / description / tests / solution / rejection -- 30+ verbatim phrases mined from approveds).

```markdown
[Repository URL]

Description:
- [Issue + specific fix, cite REVIEWER-PATTERNS A_id]

regarding tests:
- Brittle: [test name] -- [why]
- Weak Assertion: [test name] -- [Contains -> assertEquals on exact value]
- Missing Coverage: [edge cases]

solution issues:
- Bug: [description with code ref]. Fix: [specific fix]
- Dead code: [what to remove, A2]
- Scope creep: [unrequested feature]. Would you accept this PR as maintainer?

Verdict: [ACCEPT / REQUEST CHANGE / REJECT]
Quality: [1-7]
```

Key phrases (full banks in FEEDBACK-STYLE-GUIDE.md):
- Approval: "Solid problem", "subtle but fair", "Ship it", "Genuinely hard", "lgtm"
- Description: "Clarify...", "Define...", "Specify...", "Reword as observable behavior"
- Tests: "Brittle Tests:", "Weak Assertions:", "This caused X/Y agents to fail"
- Solution: "Dead code:", "Scope creep", "Would you accept this PR?"
- Rejection: "Way too heavy for this repo", "Contradicts maintainer's explicit design decision"

**Self-check before sending:** re-read your feedback for em-dashes + AI cadence (`In essence`, `It's important to note`, `Notably`). Leadership monitors -- AI-written feedback risks offboarding.

**Share to:** Shipd review interface only. Discord channels REMOVED post-Diamond-relaunch 2026-05-13.

---

## Quick Commands

```bash
# Clone + checkout
git clone <URL> && cd <REPO> && git checkout <BASE_COMMIT>

# Apply patches (both orders)
git apply test.patch
git apply solution.patch

# Build + test OFFLINE
docker build -t olympus-review .
docker run --rm -it --network=none olympus-review

# Inside container
./test.sh base   # PASS before AND after solution
./test.sh new    # FAIL before, PASS after

# Fix CRLF (Windows trap)
sed -i 's/\r$//' test.sh
```

Image tags (post May 2026 admin update): `public.ecr.aws/d3j8x8q7/olympus-base-{python|typescript|go|rust}:latest` (Java/C++ UNSUPPORTED as of 2026-05-14).

---

## Companion Skill

`olympus-author` -- produces submissions reviewers evaluate. Author skill builds DESIGN.md / feedback.md / eval-results.md as INTERNAL artifacts to ship clean submissions; reviewer never sees these. Reviewer judges only visible artifacts (meta.md + patches + Dockerfile, + Diamond extras).

## Reference Docs

### Reviewer-side (primary -- read first)
| Doc | Purpose |
|---|---|
| `Admin-Review/docs/MARS-REVIEW-GUIDE.md` | Canonical 7-stage workflow doc |
| `Admin-Review/docs/REVIEWER-PATTERNS.md` | 23 mined reviewer-flag patterns ranked by hit count |
| `Admin-Review/docs/REJECTION-CASE-STUDIES.md` | 8 structured rejection cases with verbatim quotes |
| `Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md` | How to write feedback + verbatim vocabulary banks |
| `Admin-Review/docs/GITHUB-QUERIES.md` | Pattern 22 6-check bash recipes + 3 worked examples |
| `Admin-Review/docs/CHEAT-SHEET.md` | 1-page printable summary |
| `Admin-Review/docs/REVIEW-TEMPLATE.md` | Per-review fillable template |
| `Admin-Review/docs/check_rejection.md` | Stage 3: 8 hard-rejects + Pattern 22/23/32 |
| `Admin-Review/docs/check_description.md` | Stage 4: A1+A3+A4+A8 + per-shape word budget |
| `Admin-Review/docs/check_test.md` | Stage 5: A5+A6+A13+A14 + assertion hierarchy |
| `Admin-Review/docs/check_solution.md` | Stage 6: A2+A9+A10+A15+A16 + tier-aware LOC |
| `Admin-Review/docs/check_subtle_bugs.md` | Stage 6.5: A19+A20+Section D |
| `.agents/workflows/review.md` | Workflow definition (aligned with this skill) |

### Authoring-side (cross-check submission against author's source-of-truth)
| Doc | Use when |
|---|---|
| `Olympus/Instructions/SHAPES.md` | Verify Section 2 shape claim -- file count + LOC band match shape table |
| `Olympus/Instructions/PATTERNS-ADVANCED.md` | Reject checks: Pattern 22 (namespace), Pattern 23 (triviality), Pattern 32 (post-base) |
| `Olympus/Instructions/PROBLEM-PROFILES.md` | Per-problem precedent -- open closest shape/repo match |
| `Olympus/Instructions/DESCRIPTION.md` | Verify Section 5 blind-spot pre-empt sentences verbatim |
| `Olympus/Instructions/RULES.md` | 21-item checklist + 16-row Real Revert Causes |
| `Olympus/Instructions/AUTO-REVIEWER.md` | Distinguish stable vs flaky auto-review verdicts when contesting |
| `Olympus/Instructions/DIAMOND.md` | Diamond-tier full workflow + Failure QA Guide |
| `Olympus/Instructions/DIAMOND-PLAYBOOK.md` | Diamond evidence-based design + failure-QA 12-rule writing guide |
