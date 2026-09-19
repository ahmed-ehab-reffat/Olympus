# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ PRIME DIRECTIVE — Olympus/Diamond-First Authoring Stance

The goal is to ship the HARDEST viable problems at the Olympus and Diamond tiers. Mars is a fallback for picks that cannot reach cross-tier depth, NOT the aspirational default. Read every rule below through this lens — wherever a rule reads as "keep it small / stay mid-band / prefer the easy pick", the PRIME DIRECTIVE overrides it.

- **Author for the hardest tier the pick can carry.** Scope up before scoping down. Downgrade to Mars only after a genuine cross-subsystem design fails the solvability gate, never as a first move.
- **The only hard LOWER constraint is solvability:** at least one agent must pass (Mars/Olympus 0% = reject; Diamond near-0 routes to the hint flow, not reject). Above that floor, bias toward maximum difficulty. Pass-rate "bands" are upper bounds (too-easy rejects) plus a description of where approved problems landed — not a window you must stay inside by softening a hard design.
- **LOC floors are real; LOC ceilings are not.** >=450 effective (Olympus/Diamond) and >=100 (Mars) are hard floors. The "sweet spot" upper numbers (e.g. Mars 170-380) are observations, not caps — never stop adding genuine complexity just to hit a number.
- **Maximal complexity is the product, not a risk.** A design that scores high on every complexity dimension (no codebase precedent, 5+ packages touched, no obvious single approach) is the TARGET for Diamond. Fairness comes from documenting every tested behavior in meta.md (≤1 codebase-inferable requirement), never from capping difficulty.
- **"Prefer bug fixes" applies ONLY when triviality risk is high** (Pattern 23). For hard cross-subsystem work, additive/feature picks touch more files and force more design decisions — exactly what Olympus/Diamond need.
- **Where hard problems actually die (REAL walls, not your instructions):** the solvability gate, the maintainer-owned SIX-CHECK (active + visible + hard often means maintainer-owned), the derivative/similarity check (blocks reusing a proven-hard shape), the 400-LOC auto-block, and the >=500-star + active-maintenance precheck. Spend selection effort dodging THESE, not on self-throttling difficulty.

---

## ⚠️ RULE UPDATE 2026-06-26 — Tighter pass-rate ceilings + MANDATORY flakiness check (admin)

These numbers OVERRIDE every older band figure anywhere in this repo (this file, `Instructions/*`, `.claude/skills/*`, `Admin-Review/docs/*`). Where an older table says Olympus 30% or Mars 40%, the figures below win.

- **Mars: `<= 30%` pass MAXIMUM** (Nova/Orion). 0% = reject (unsolvable); `> 30%` = reject (too easy). (Was an interim 40%; now firmly 30%.)
- **Olympus: `<= 20%` pass MAXIMUM** (Nova/Orion/Vega/Castor). DOWN FROM 30%. 0% = reject; `> 20%` = reject (too easy). `~10%` (1-3/12) stays the Good target; design to land at-or-under 20%. Any shape band that historically read 25-30% (O-Composite-extend, O-Pipeline-easy) MUST now be hardened to `<= 20%`.
- **Diamond: unchanged** (Castor `<= 30%` ceiling) until admin updates it; the flakiness check below still applies.
- **Flakiness verification is now a MANDATORY Core Dev check (gate, not advisory).** Before submit, confirm the target repo's EXISTING tests AND your NEW tests are NOT flaky: run the full suite (base + new) at least 3-5 times and confirm identical, deterministic pass/fail every run. Reject/avoid timing-dependent assertions, ordering-dependent tests (map/set iteration, parallel races), unseeded RNG, network/clock/filesystem-time dependence, and resource-contention races. A flaky repo baseline OR a flaky new test = reject. If the repo has a known-flaky baseline, scope base mode to the solution-relevant tests (see `Instructions/TESTS.md`) and document why. This gate sits alongside the LOC floor and the SIX-CHECK in every pre-submit checklist. Full detail: `## ⚠️ HARD RULE — Flakiness is a MANDATORY Check` below.
- **Per-repo submission caps (platform warns at submit):** `≤ 6` submissions per repo total, `≤ 3` per repo in a single week, and a global `≤ 50` per repo across the whole quest (all authors combined). COUNT existing subs per repo (across `Olympus-Approved/Feature-Requests/<repo>/`, `problems/`, `diamond-problems/`, `rejected/`) at PICK time — do not burn authoring effort on a repo you can't submit against. Already at/over the 6-cap: dasel (9), cliffy (7), yaegi (7). Detail: `Instructions/PICK-FILTER.md § Gate 10 REPO-QUOTA` + `RULES.md § Repository Requirements`.
- **Feedback now cites rubric codes (P1, T3, S4, R2, …).** Every code maps to a point in the platform guide, mirrored verbatim in `Instructions/OFFICIAL-RUBRIC.md`. Reference every R/P/T/S point while authoring and self-reviewing; when a reviewer cites a code, look it up there.

---

## ⚠️ RULE UPDATE 2026-07 (SPRINT) — Mars merged into Olympus · pass ≤40% · new long-horizon floor · FP Check mandatory

Latest admin update. These OVERRIDE the 2026-06-26 caps and EVERY older tier / band / LOC / long-horizon figure anywhere in this repo where they conflict.

- **ONE TIER: Olympus.** Mars has been MERGED into Olympus — there is no Mars tier anymore. Author every submission as Olympus. Mars-specific shapes / bands / LOC scattered in older docs are historical DATA only, not a live tier. (This update does not mention Diamond; treat Diamond as unchanged until admin says otherwise.)
- **Pass-rate MAXIMUM = 40%** (up from the 20% / 30% caps). Approvable = solvable (≥1 agent passes) through ≤40%. **0% = reject (unsolvable); >40% = reject (too easy).** Per the PRIME DIRECTIVE, still bias toward the HARD / low-pass edge — difficulty now also drives PAYOUT, not just approval.
- **Long-horizon MINIMUM metrics (the new floor): ≥2 file changes · ≥40 agent messages (solver median) · ≥200 effective LOC.** Down from 3 files / 100 msgs / 450 LOC (previously lowered to 250, now further reduced to 200 per fresh admin update). The 200 is the effective / meaningful (Counter 2) floor — gate on the hook's `human-effective` ≥ 200. Higher still helps (payout scales with scope), but 200 / 2 / 40 is the hard floor.
- **Payout $150–$350 (Olympus).** Final payout scales with task SCOPE, DIFFICULTY, FAIRNESS, and overall QUALITY. Bigger + harder + fair + clean = more money — the PRIME DIRECTIVE's push for depth now serves PAYOUT, not only approval.
- **★ FP CHECK — now MANDATORY (new FINAL gate).** After ALL agent runs, run the False-Positive check. It inspects EVERY passing agent and confirms each REALLY solved the task (met all requirements), not merely passed the tests. An FP flag = an agent passed WITHOUT meeting a requirement = **the tests OR the description are wrong** (the datapoint is the ENVIRONMENT — prompt + tests; agent runs only validate it, so one false pass invalidates the whole submission, not just that run). Fix by ALIGNING tests ↔ description (strengthen the missing discriminator, or fix the ambiguous sentence that allowed the divergent pass), then re-run. Catch it early with the Test Fairness "light bulb" pre-check (matches prompt↔tests BEFORE agent runs). The check is mechanical/deterministic — aligned tests+prompt = pass. Run it at the very end; clean FP required to submit. Detail: `Instructions/TESTS.md § FP Check`.

---

## ⚠️ RULE UPDATE 2026-09-16 — pass-rate ceiling LOWERED back to <= 40%

Platform lowered the Olympus pass-rate MAXIMUM from 50% back to **40%**. This OVERRIDES the
2026-08-31 block it replaces (which had raised it to 50%) and every older 20% / 30% / 50% cap
anywhere in this repo. The 2026-07 SPRINT figure (<= 40%) is live again.

- **Approvable = solvable through <= 40% pass.** 0% = reject (unsolvable) is unchanged; > 40% =
  reject (too easy).
- **This is a CEILING, not a target.** Per the PRIME DIRECTIVE, still design to the HARD / low-pass
  edge: payout scales with difficulty, so a 40% submission is approvable but paid at the bottom of
  the band, and it has ZERO margin against batch-to-batch variance (measured on
  vrp-tsplib-edge-weight-types: the same artifact ran 22% in batch 9 and 50% in batch 11).
- **A batch that read "in band" under the 50% cap may now be a too-easy reject.** Anything measured
  at 41-50% while the 50% ceiling was live (2026-08-31 to 2026-09-16) is NOT approvable as-is —
  harden it (`olympus-harden`) and re-measure. Historical pass rates recorded in
  `approved-problems/`, `Instructions/`, and `failure-patterns.md` are facts about past runs, not
  current targets.
- Everything else in the 2026-07 SPRINT block (>= 2 files, >= 40 agent messages, >= 200 effective
  LOC, $150-350 payout, mandatory FP Check) is unchanged.

---

## ⚠️ RULE UPDATE 2026-09-09-B — hunt gates SOFTENED (user decision; `olympus-hunt` SKILL.md edited)

Six hunt rules were being applied harder than their evidence and rejected the repo that carried the
best lane of the month (scikit-fem). Now, in `.claude/skills/olympus-hunt/SKILL.md`, marked
"Softened 2026-09-09-B": (1) Requirement 7 rejects only on a `failure` conclusion on the DEFAULT
branch, never on `action_required`/`cancelled`; (2) one competitor-signature visit outside the lane
is a note, reject needs two accounts or an in-lane PR or a burst; (3) an AI-sweep mark counts only
when the agent closes the gap class in the intended lane; (4) capability-consuming is a LANE verdict,
commit count never kills a repo; (5) a missing-arm/absorption verdict needs a sketched eff-LOC number
(<150 dies, 150-250 needs a coupled lever, >250 proceeds); (6) an outsider-nameable pick is a
mitigation (phrase meta.md on the repo model + F-10 table + submit-time PR-DIFF), a reject only with
a long-open uncommented issue for exactly it or a faithful-port shape; plus zero-issue trackers are a
ranking penalty and one invented lane is allowed after two tracker lanes die. Hard platform rules
(licence incl. vendored, activity, exclusivity, quota) are unchanged.

---

## ⚠️ RULE UPDATE 2026-09-03 — RE-EVAL: re-grade the last batch for ~30% instead of re-running it

Platform added **Re-eval**. When a rollout batch goes stale because you edited `test.patch` and/or
`solution.patch`, the agents' SOLVING work is still valid (same prompt, same repo), so a green
**Re-eval** button appears next to Run Rollouts (and inside the Run Rollouts dialog). It re-runs
ONLY grading + evaluation over the last batch of agent solutions: fresh verdicts at **~30% of the
normal batch token price**, and much faster because nothing is solved.

**Eligibility is decided by the SOLVER-VISIBLE surface, and the platform enforces it for you:**

| You edited | Button appears? | Cost of a fresh verdict |
|---|---|---|
| `test.patch` (tests, `test.sh`, discriminators) | YES | ~30% of a batch |
| `solution.patch` (reference only; agents never see it) | YES | ~30% of a batch |
| `meta.md` / title / Dockerfile / repo+commit (the ENVIRONMENT) | NO | full batch, no discount |

- **A failed re-eval auto-refunds** and the button comes back. Retry whenever.
- **Runs that already picked up a fresh verdict are not re-charged** — re-eval bills only what still needs grading.
- **⚠️ Firing a fresh batch — even ONE single run — DISMISSES the offer.** Pick the path before you
  click anything. Never fire a smoke run while a re-eval is pending.

### What this changes about how we work

- **★ Re-eval IS the differential harness, made authoritative.** The local replay in
  `HARDENING.md § 3e` / L32 (apply saved `agent-runs/*.patch` to the candidate suite, count kills)
  was always an APPROXIMATION of exactly this measurement. Now the platform runs the real grader over
  the real solutions. Keep saving `agent-runs/*.patch` — they remain how you READ why an agent failed,
  and the only copy if the run view rotates — but stop treating a local kill count as the decision
  when a re-eval produces the real one for ~30%.
- **★ L35's caveat is now enforced by the button's existence.** L35: the harness measures a TEST delta
  and cannot measure a DESCRIPTION delta, so discount it hard when the lever also added a meta.md
  sentence (vrp-tsplib: 3 of 5 killed in the harness, **0 of 10** live). The button is offered ONLY
  when nothing solver-visible changed — precisely the case L35 says to TRUST. **A missing button is
  the platform telling you your lever was a description delta and the replay number would have been
  a lie.** Do not hunt for a workaround; pay for the fresh batch.
- **The two expensive disambiguations are now cheap:**
  - **Too easy (>40%):** tighten tests / add the discriminator, re-eval, watch the rate drop on the
    same solution population. Tests-only levers (F-10 cross-product cells, compound interleaves,
    per-requirement discriminators) are the cheap lane precisely because they need zero new meta.
  - **Reads unsolvable (0%):** relax or DROP the over-strict axis (L32, the gluon printer-axis move),
    re-eval, and see whether a near-miss run flips to a legitimate pass BEFORE committing to a redesign.
- **SEQUENCING RULE (new): freeze the solver-visible surface BEFORE the first batch.** Description,
  title, Dockerfile, base commit — settle all of it first, then iterate tests + solution against
  re-eval. Every description edit after the batch costs full price and burns the cheap lane. This
  supersedes the blunt "fix ALL issues in one pass before rerunning" in `Instructions/AGENTS.md §
  Token Rules`: solver-visible fixes still batch up, test-side fixes no longer have to.
- **It does NOT re-roll batch variance.** A re-eval is a PAIRED re-measurement over ONE fixed set of
  solutions, so it cannot show the 22%-vs-50% swing the same artifact produced across batches
  (vrp-tsplib-edge-weight-types). Near the 40% ceiling, and for the number you actually submit on, a
  fresh batch is still the evidence. **Re-eval to STEER, a fresh batch to CONFIRM.**
- **FP Check fix-direction now carries a ~3.3x cost asymmetry.** Strengthening a test is
  re-eval-eligible; fixing the ambiguous description sentence is not. Take the fix the FP flag
  actually calls for, never the cheap one, but do ALL description-side work in one round before
  paying for the batch. CONFIRMED 2026-09-18 (mwparserfromhell-site-aware-parsing): the FP panel
  produced fresh adjudications for the passes of a re-eval batch, which was then accepted.

---

## ⚠️ STALENESS CORRECTIONS 2026-08-01 (paths, tiers, LOC, skills — these OVERRIDE the older text below)

The 2026-07 sprint block above changed the tier and the floors, but the rest of this file was never swept. Where the text below conflicts with any of these, THESE win.

- **Approved submissions live in `approved-problems/<name>/` (flat).** The `Olympus-Approved/Feature-Requests/`, `Olympus Approved/` and `Mars Approved V2/Feature Requests/` paths referenced further down DO NOT EXIST in this workspace. Read `approved-problems/README.md` first — it is the compact index of what broke each approved problem and why. Dedup and repo-quota greps must target `approved-problems/`, `problems/`, `rejected/`, `diamond-problems/`.
- **ONE TIER: Olympus.** Every "Mars vs Olympus" table, tier-decision matrix and Mars-only band in this file is HISTORICAL shape data, not a live tier.
- **LOC floor is ≥200 effective (Counter 2 / `human-effective`), not 450.** The `## ⚠️ HARD RULE — Effective LOC floor` section below still says 400/450 throughout; those numbers are superseded. Counter 2 remains the binding measure and the hook remains the way to check it. Design to a buffer (≥250-300), not to 200 exactly.
- **Pass ceiling is ≤40%,** not the ≤20% / ≤30% figures in the tier tables below. 0% is still a reject. Per the PRIME DIRECTIVE, still bias to the hard/low-pass edge — difficulty drives payout.
- **`failure-patterns.md` (repo root) is a primary authoring input** and is missing from the Key Instructions Files table below. It is the measured trap catalogue (F-1…F-10) plus the cross-problem laws L1-L19, mined from real agent runs. Read it at design time alongside `HARDENING.md` (doctrine) and `TOO-EASY.md` (death classes).
- **`.claude/hooks/effective_loc_check.py` and `.claude/hooks/freshness_check.py` now DO exist in this workspace** — added during the Aug 2026 three-workspace merge (pulled in from a sibling workspace), calibrated to the current 200-floor / 250-300-design-target (not the old 400/430/500 numbers). Both are registered as non-blocking Stop hooks in `.claude/settings.json`. Use `effective_loc_check.py` as the automated pre-submit LOC check — alongside, not instead of, the inline Counter-2 stripper in `.claude/skills/olympus-harden/SKILL.md § Stage 5` (that inline version remains valid too; it implements the same reviewer-equivalent strip: blanks, comments, brace/punctuation-only lines, package/imports, trivial no-ops, and prints `raw`, `counter1` and `human-effective`).
- **Skills live in `.claude/skills/`** and now number five: `olympus-hunt` (source repos), `olympus-author` (build), `olympus-review` (review), `olympus-harden` (raise difficulty on an in-flight problem), `olympus-finalize` (post-acceptance: mine the batch, update the docs, archive, reclaim disk). The Skills table below lists only two.

---

## ⚠️ CRITICAL RULE — Comments in test.patch / solution.patch MATCH REPO CONVENTION (default: NONE)

**New code added by `test.patch` and `solution.patch` carries comments ONLY when the target repo's existing source already does, and then only concise comments in that exact style.** Default is NONE. Do not add doc comments, inline comments, or test-body comments unless you have verified the repo convention demands them.

Decision procedure (run BEFORE writing any new code):

1. Open 2-3 existing NON-test source files near where your change lands. Do they carry doc comments on funcs/types? Inline comments in bodies?
2. Open 2-3 existing TEST files. Do test bodies carry comments?
3. **If NO** (most repos, including dasel) → write zero comments. Not even Go-convention `// FuncName does X`. Existing base comments stay (they are not `+` lines); anything YOU add stays comment-free.
4. **If YES** → match it exactly: same density, same style, same brevity. Never exceed the repo's own level. Test bodies almost never carry comments even in repos that doc-comment their source — keep test bodies clean unless the repo's existing tests clearly do otherwise.

Banned in ALL repos regardless of convention: `// TODO`, `// FIXME`, `// NOTE`, `// CATEGORY N`, `// Step N`, `// arrange/act/assert`, `// setup`, comment-restating-the-symbol-name, commented-out code, any comment narrating what the next line does.

Always allowed (not prose comments): machine directives — `//go:build <tag>`, `//nolint:...`, `//go:generate`, shebang `#!/bin/bash`.

Pre-generate verification (run before every patch-gen):

```bash
# Added comment lines in solution.patch (exclude build directives)
grep -E '^\+' solution.patch | grep -E '//|/\*|^\+\s*#' | grep -v '//go:build\|//nolint\|//go:generate'
# Added comment lines in test.patch
grep -E '^\+' test.patch | grep -E '\s//|/\*' | grep -v '//go:build\|//nolint\|//go:generate'
```

If the repo convention is NONE, both must return empty. If the repo doc-comments its source, eyeball the output and confirm every hit is concise and matches the existing style. Author to the right comment level from the first draft — do not write-then-strip.

**Track record:** dasel-glob-primitives shipped Go-convention doc comments on every new public symbol in api.go (20), func_glob.go (6), fileutil.go (10), safety.go (2). dasel's own source does carry doc comments, but the reviewer does not require them and the user wanted them gone for this submission. All stripped, patches regenerated. Lesson: default to NONE; add only when the repo convention clearly demands it AND it survives the AI-slop check.

---

## ⚠️ CRITICAL RULE — Namespace + Maintainer-Philosophy + Post-Base Activity Check (NEVER SKIP)

**Before scope-locking ANY problem, AND at every scope change, AND immediately before patch generation, run all SIX checks:**

```bash
# 0. RESOLVE CANONICAL ORG FIRST (repos MOVE — an -R old-org search silently returns EMPTY).
#    Use $CANON for EVERY search below. Then run the ⚠️ HARD RULE Exclusivity PR-DIFF check
#    (canonical-org PR search by feature CLASS, all states, read the DIFF not the body).
CANON=$(gh api repos/OWNER/REPO -q '.full_name')   # follow the redirect; e.g. tweag/nickel -> nickel-lang/nickel

# 1. Literal name search
gh pr list   -R "$CANON" --state all --search "<exact-func-name>"
gh issue list -R "$CANON" --state all --search "<exact-func-name>"

# 2. Namespace expansion search (broader keyword)
gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"

# 3. Maintainer philosophy scan
gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("prefer not to") or contains("don'\''t want") or contains("by design") or contains("namespace") or contains("pollute") or contains("won'\''t add") or contains("rejected"))'

# 4. Closed-with-implemented scan (NEW — catches feature shipped post-base)
gh issue list -R OWNER/REPO --state closed --search "<feature-keyword>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("implemented") or contains("supported in V") or contains("This is in v") or contains("implemented in v"))'

# 5. Base→main commit overlap (NEW — catches maintainer-shipped fix between base and current)
cd /tmp/<repo>-main && git log --oneline <BASE_COMMIT>..HEAD -- <relevant-source-files>
git log --oneline <BASE_COMMIT>..HEAD --diff-filter=A -- <relevant-package>/

# 6. Existing-capability functional check (build current main; CLI-test feature)
cd /tmp/<repo>-main && go build -o <repo>.exe ./cmd/<repo>   # or equivalent
echo '<test input>' | ./<repo>.exe <feature invocation>
# If 80%+ of feature scope already works, REJECT — namespace expansion = immediate-reject
```

**ANY hit** in checks 4-6 is treated identically to hits in checks 1-3: candidate is YELLOW (redesign required) or RED (abandon).

**Why ALL six checks exist** (track record of misses):

1. **dasel-collection-funcs R17d** (prior cycle): shipped 41.7% Nova pass after 18 rounds and 12-run eval, REJECTED at platform review because (a) `FuncMerge` already existed → `mergeDeep` was namespace expansion, (b) issue #169 has maintainer comment "I'd prefer not to add ... pollute namespace". v1 Phase 2 found literal name absent + missed namespace + philosophy. Cost: ~$200.

2. **dasel-slice-operator** (this cycle): authored end-to-end (DESIGN.md + solution + tests + Dockerfile + patches + validation). REJECTED at submit-pre-check because (a) issue #312 closed by maintainer 2026-03-30 with text "This is implemented in v3" + maintainer-published docs documenting CURRENT (inclusive-end) semantics, (b) v1 audit ran Phase 2 at base time and missed the post-base closure. Our spec contradicted maintainer's documented semantics. Cost: ~half-day of authoring + Docker iterations.

3. **dasel-entries-fromentries / dasel-yaml-quote-style / dasel-regex-filter** (this cycle, caught at audit-rewrite): all v1-classified GREEN; commit search base→main found maintainer shipped equivalents post-base (`ace5c25`, `80d4fe5`, #183 closed). All three would have been hard-rejects.

4. **dasel-multi-file** (Diamond tier, 2026-05-14): Phase 2 never ran at design OR submit-pre-check. 14 authoring rounds + Castor 7× + AI Reviewer PASS 0.92 + Failure QA 12/12 all GREEN. Discovered at olympus-review Stage 0: [#357 "Support multiple files"](https://github.com/TomWright/dasel/issues/357) CLOSED by TomWright 2025-12-10 (4 months pre-base) — maintainer comment lists three V3 alternatives (env vars, `readFile` function, file→variable in CLI), declines multi-file primitive. Original [#24 "Multiple file flags"](https://github.com/TomWright/dasel/issues/24) CLOSED 2020 "mostly resolved by multi-selectors". Same class twice rejected. Discontinued pre-submit. Cost: ~14 iterations + Castor 50tk × 7 + QA cycle + Diamond Auto Review. **Confirms: Auto Review + Diamond QA do NOT check maintainer philosophy.**

**Lessons:**

- **Check at submit time, not just design time.** Maintainer ships features between design and submission.
- **Namespace search must include closed issues.** Open-only search misses #312/#183/#357 patterns.
- **Read maintainer-published docs** for any pick that touches existing user-visible syntax. Spec contradiction = automatic reject.
- **Reading repo file structure is NOT sufficient.** Must run GitHub history queries.
- **Auto Review / Diamond QA passing does NOT substitute for Phase 2.** Both blind to repo politics. Search closed issues by feature CLASS (not just exact API name) and read top 3-5 closure comments for "use X / Y / Z instead" language.

See `Instructions/PATTERNS-ADVANCED.md § Pattern 22` (and § Pattern 23 triviality + § Pattern 24 post-base activity) for full procedure.

---

## ⚠️ HARD RULE — Exclusivity: CANONICAL-ORG PR-DIFF check at PICK time (a public draft PR touching your file set = SHELVE, NEVER AUTHOR)

**Olympus/Diamond require solution EXCLUSIVITY. A public PR that implements the CENTRAL capability — in ANY state (open / draft / unmerged / incomplete / closed), at ANY time — is a HARD scope-gate reject.** "Incomplete" and "unmerged" do NOT save it: the Auto Review scope gate treats the published DIFF as the disqualifier, because it hands an agent the core solver scaffold. Extensions you bolt on top (new syntax, extra operators, a coupled sub-feature) do NOT cure a non-exclusive core. This gate is BINARY and existence-based — a reject here is not contestable on quality, difficulty, LOC, pass-rate, or FP-cleanliness. Run it at PICK time (before authoring a line) AND re-run at submit.

**The exact procedure — do this BEFORE scope-lock, then again pre-submit:**

```bash
# 0. RESOLVE THE CANONICAL ORG FIRST — repos MOVE; an -R old-org search returns EMPTY and misses everything.
#    Follow the redirect the API reports, then run EVERY search against the canonical slug.
CANON=$(gh api repos/OLD_OWNER/REPO -q '.full_name')    # e.g. tweag/nickel -> nickel-lang/nickel
echo "canonical repo = $CANON"

# 1. Search PRs by FEATURE CLASS (not just the exact API name), ALL states incl. draft/closed.
gh pr list -R "$CANON" --state all --search "<feature-class keywords>" --json number,title,state,createdAt

# 2. For EVERY plausible hit, PULL THE DIFF — the PR BODY LIES BY OMISSION. Read the file set + line counts,
#    NOT the author's self-assessment. "I didn't get X working" routinely means the TESTS didn't exercise X
#    while the CODE PATH is fully present in the patch.
gh pr view <N>  -R "$CANON" --json files -q '.files[] | "\(.additions)+ \(.deletions)- \(.path)"'
gh pr diff <N>  -R "$CANON" --patch | less    # confirm what the code actually does

# 3. VERDICT: if the hit's DIFF touches the same core files you plan to touch AND implements the core
#    type/eval/algorithm machinery of your CENTRAL capability -> EXCLUSIVITY-DEAD. Shelve now, do not author.
```

**The bright-line test:** overlay the hit's changed-file list on your planned solution footprint. If it covers your core-machinery files (the ones carrying the F2P difficulty, not just plumbing), the pick is dead — regardless of what the PR body claims about completeness.

**DO NOT CONTEST a publicly-solved scope reject** unless you can show the cited PR's DIFF does not touch your core files at all. "The PR is a draft / incomplete / the author says it doesn't work" is pre-rebutted by the rule and refuted by the diff — asserting it after the diff shows overlap torches reviewer credibility.

**Track record (this exact class has now killed 5+ picks):**

- **nickel-optional-record-type** (2026-07-17): full authoring arc — 341 eff, 44 tests, 25% in band, FP CLEAN, submit-ready — REJECTED at the Auto Review scope gate. Draft PR [nickel-lang/nickel #2185](https://github.com/nickel-lang/nickel/pull/2185) "Optional field types" (OPEN, author: "I didn't figure out how to trigger subtype checking") had a published diff touching my NEAR-EXACT 26-file cascade incl. `typecheck/subtyping.rs +9/-30`, `pattern.rs`, `mod.rs`, `eval/operation.rs`. TWO failures compounded: (a) the repo had MOVED `tweag/nickel` -> `nickel-lang/nickel`, so scope-lock `gh pr list -R tweag/nickel` returned EMPTY; (b) at R3 I read the PR BODY ("didn't get subtyping working") and under-weighted it instead of pulling the diff, which shows subtyping.rs fully changed. Cost: a full authoring + 4-batch iteration cycle.
- **async-graphql-overlapping-fields, rhai-spread, rune-const-pattern, gql-row-comparison**: shelved DERIVATIVE / publicly-solved / "cannot out-add a superset" — same family (the CENTRAL capability already exists publicly or in the spec-convergent superset).

**Lessons baked into the rule above:** (1) resolve the canonical org before ANY GitHub search — a moved repo silently voids every `-R old-org` query; (2) read the DIFF, never the PR body — draft/incomplete self-assessments hide fully-present code paths; (3) a public draft PR touching your file set is DOA on exclusivity — shelve at PICK time, do not author, do not contest.

---

## ⚠️ HARD RULE — Effective LOC floor for ALL Olympus + Diamond (NEVER SKIP)

**Two numbers: platform auto-block at 400, design floor at 450.** Auto Review HARD-BLOCKS solutions under 400 effective LOC for Olympus + Diamond (verified: a Diamond got "367 effective < 400 required" rejection). **Design to ≥450** so revisions don't dip back under the 400 auto-block. Failing this wastes Castor/eval tokens + adds 2-3 revision rounds. Design for it from day one.

- **Olympus floor:** **≥450 effective LOC design floor** (400 = platform auto-block; 600+ for Good rank)
- **Diamond floor:** **≥450 effective LOC design floor** (same — Diamond is premium Olympus)
- **Mars floor:** ≥100 effective (≥150 preferred); sweet 170-380 (different rule; this hard rule is Olympus/Diamond only)

### TWO different LOC counters — design to clear BOTH

There are TWO distinct measures. The platform auto-block is the LOOSER one (braces kept); the human reviewer's "meaningful LOC" is STRICTER (braces + imports + no-ops all stripped) and is the binding floor. A green auto-gauge does NOT guarantee the human count clears.

**Counter 1 — platform auto-block (≥400, hard): `raw added − blank − comment-only`. BRACES KEPT, imports/package KEPT.** Verified: cel-go-strict-dyn auto-reviewer reported 367 = `575 raw − 48 blank − 160 comment`. The platform does NOT drop brace/paren-only lines, and does NOT count comments.

**Counter 2 — human reviewer "meaningful LOC" (the STRICTER, binding floor; reviewer Nandish 2026-07).** Measured on the PASSING AGENT's diff, not just the reference. EXCLUDES all of: blank lines; comment-only lines; **trivial no-op lines** (`pass`, `continue`, `break`, `return None`, `return nil`); **generated files**; **test files**; **package declarations** (`package foo`); **imports** (`using`, `use`, `namespace`, `from x import y`) + import-block contents + the closing `)`/`}`; **braces / punctuation-only lines** (`{`, `}`, `);`, `,`); and package/import/brace-heavy boilerplate generally. This is ~15-30% below Counter 1 in brace-heavy languages (Rust/Go). Confirmed cost: pomsky-conditionals reference was 456 braces-kept but only 373 under this strip → forced a Mars downgrade; sqlglot-window-functions raw 547, AI-waived, human re-counted under 400 → NOT resubmittable.

**Design target: ≥450 under Counter 2 (human-meaningful).** That guarantees Counter 1 clears with margin. Do NOT design to Counter 1's 400 — the reviewer strips more and rejects the gap. The `.claude/hooks/effective_loc_check.py` Stop hook predicts the Counter-2 human re-count (`human-effective`) AND flags breadth-padding (`padding-floor` << `human-effective` → add orthogonal DEPTH, not more repetitive breadth). Never lean on repetitive registry/match-family breadth to clear the floor — the human amortizes it to ~the pattern.

**Canonical pre-submit check — GATE ON COUNTER 2 (the hook's `human-effective`), NOT Counter 1:**

```bash
# PRIMARY gate (Counter 2 — the reviewer's meaningful count): design + gate on this ≥ 450
python .claude/hooks/effective_loc_check.py solution.patch   # read the `human-effective:` line, target >= 450
```

Counter 2 (`human-effective`) is the binding number for Olympus/Diamond — it strips blanks, comments, no-ops, generated files, TEST files, package/imports (+ closing `)`/`}`), braces/punctuation-only lines, and boilerplate, exactly like the human reviewer. **Gate the whole submission on `human-effective` ≥ 450.**

```bash
# SECONDARY (Counter 1 — the platform auto-block ≥400): a LOOSER by-product, only confirm it won't trip
f=solution.patch
raw=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | wc -l)
blank=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | grep -cE '^\+\s*$')
comment=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | grep -cE '^\+\s*(///|//|/\*|\*)')
echo "auto-block (Counter 1, braces kept) = $((raw - blank - comment))   (>= 400 clears automatically once Counter 2 >= 450)"
```

- Counter 1 KEEPS braces + imports, so it OVERSTATES by ~15-30% in Rust/Go — a Counter-1 ≥400 can still be a Counter-2 reject. That is exactly why you gate on Counter 2, not Counter 1.
- `raw × 0.65` is a ROUGH design-time sketch estimate ONLY — confirm with the hook (`human-effective`) before submit.

**Comments + braces + imports are dead weight for Counter 2.** Heavy doc-commenting does NOT help clear the floor — only real implementing logic does. (cel-go had 160 comment lines counting for ZERO.)

**Pre-design check (before writing any code):**

1. Sketch file footprint table per `DESIGN-TEMPLATE.md § 7` with raw + meaningful LOC columns (meaningful = raw − blank − comment, keep braces)
2. Verify `sum(meaningful)` ≥ 400 BEFORE proceeding to implementation. Target ~480 buffer so revisions don't dip back under.
3. If under 400 → expand scope NOW (add public API surface, cross-package integration, or new requirement). DO NOT submit and hope auto review tolerates it.

**Pre-submit check (after implementation):** run the canonical command above.

If `effective < 400`:

- Add 3-5 helpers per behavior the description names
- Extend public API surface (add `.Clone()` / `.String()` / `.Validate()` methods)
- Add cross-package integration (CLI flag wiring, parallel optimized variant)
- DO NOT pad with dead code or commented-out alternatives (Real Revert Cause: dead code)

**Track record:** Multiple revert cycles cost on under-LOC Olympus submissions. Auto Review hits "long-horizon" check failure → forces resubmit. Always design above floor.

---

## ⚠️ HARD RULE — Reviewer Feedback: SHORT + Human-Voice (AI wall-of-text = FAIL)

Applies to the REVIEW workflow (`olympus-review`). A reviewer promotion review FAILED outright because the feedback was AI-written wall-of-text, even though the technical verdict was sound. This is the single biggest reviewer-offboarding risk. Correctness does NOT save a verbose, AI-sounding review.

- **Feedback to the author must be terse and human.** Match the short, blunt examples in `Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md` (most are 5-12 lines). State the issue, state the fix, stop. No multi-sentence justification, no restating the spec back, no "implication"/"what this means"/"Net:"/"Decisive:" framing, no narrating your reasoning. If a bullet runs past ~2 lines, cut it. A 5-line review that nails the real issue beats a 40-line one.
- **The Reasoning AND Thoughts fields are read too and must also be human.** A grader explicitly flagged the internal Thoughts text as AI-written. Write all three fields (Feedback, Reasoning, Thoughts) in plain, blunt, first-person voice; short fragments are fine. No AI cadence, no em-dashes, no "(1)... (2)..." scaffolding, no measured-paragraph buildup.
- **Verify every "not in the description" claim before writing it.** Quote the exact description sentence and the exact test line first. A false fairness claim that cost a pass: I said `output_field` and `OuterRef` interface details were undocumented; the description said "output_field (defaults to primary key)" (which implies a column name) and `OuterRef` only ever receives a plain field name like "id". The `author__publisher__name` form was the FILTER key, not the `OuterRef` argument. Always distinguish a function ARGUMENT from a dict/filter KEY before asserting a gap.
- **Tracing each test's ASSERTIONS to a description sentence is the core job.** What actually sinks submissions is a test enforcing behavior the description never states. A real one I MISSED: three `*_json_versioned` tests asserted invalid JSON raises `ValidationError` (not `JSONDecodeError`), with nothing in the description about it. Spend the review budget finding these, not reconciling agent-run counts.
- **Do not over-invest in agent-run forensics.** Runs can carry platform bugs that do NOT change the verdict (a grader said exactly this about a batch I spent the whole review on). Note pass-rate / solvable / fairness flags in a line or two and move on. Staleness theories, message-count math, and 0/N reconciliations are NOT the review.

---

## ⚠️ HARD RULE — Difficulty-Calibration Model (ALL TIERS)

> **⭐ The full difficulty-DESIGN doctrine now lives in `Instructions/HARDENING.md`** (survival-ranked trap arsenal with measured kill counts, the CONTRACT-STATED/FIX-HIDDEN axiom, the fair re-hardening method, the steroids-era law index). This section keeps the calibration math; HARDENING.md tells you WHICH traps still work and HOW to build + re-harden them fairly.

**Pass-rate caps tightened (admin 2026, latest): Mars `≤ 30%` (down from 40%), Olympus `≤ 20%` (down from 30%).** Every tier MUST trip agents — **too-easy rejects exactly like too-hard.** But the band is an UPPER bound: per the PRIME DIRECTIVE, push toward maximum difficulty down to the solvability floor (bias to the HARD/low-pass edge), never soften a hard design to land mid-window. The only hard lower constraint is solvability (≥1 agent passes; 0% = reject Mars/Olympus, hint flow for Diamond).

### The knob is TRAP COUNT/STRENGTH → pass-rate, NOT LOC

Pass-rate ≈ product of per-trap miss-probabilities. LOC is a separate SIZE axis — it does not move pass rate.

| Traps | Approx pass rate |
|---|---|
| 1 trap | ≈50% |
| 2 independent | ≈25% |
| 3 stacked | ≈12% |

**A uniform-wrap (one local rule that solves all "walls", ≈50% pass) is TOO EASY at EVERY tier** — not just Diamond. A single ~50% trap blows past both caps. To land Mars ≤30% need ~2-3 interdependent traps; Olympus ≤20% needs 3+ stacked. A single >60%-miss trap can clear Mars but stacking is safer.

### ★ INTERDEPENDENT + MISDIRECTING TRAPS ARE NOW UNIVERSAL (Nova ≈ Castor, 2026)

**Nova has caught up to (and in places exceeds) Castor.** Smart agents single-point-fix an isolated trap ON A SINGLE ATTEMPT — so a non-misdirecting, independent trap now passes even on rate gates (Mars/Olympus), not just on the Diamond retry gate. **The trap-QUALITY floor is now the same at every tier: traps must be INTERDEPENDENT (fixing one surfaces/breaks another) AND MISDIRECTING (the failing test does not reveal the fix).** This is no longer a Diamond-only requirement.

- **Interdependent:** traps share state / ordering / a chokepoint so a local fix to trap A regresses trap B. Independent traps get cleared in one pass by a smart agent.
- **Misdirecting:** the failing assertion points away from the real cause (e.g. an off-by-one that surfaces as a Conflict error). A single-point-fixable, self-revealing trap dies to a smart single attempt.

### The 3-Tier Model

| Tier | eff LOC | Pass band | Gate | Trap structure | Span |
|---|---|---|---|---|---|
| **Mars** | ≥100 (≥150 pref; sweet 170-380) | **≤ 30%** (solvable, 0%=reject) | rate (Nova/Orion) | **~2-3 INTERDEPENDENT + MISDIRECTING traps** | single-subsystem |
| **Olympus** | ≥450 | **≤ 20%** (target ~10%, 1-2/12) | rate (Nova/Orion/Vega/Castor) | **3+ interdependent + misdirecting, compounding** | single-subsystem OK; stay solvable (0%=reject) |
| **Diamond** | ≥450 | ~0-30% (near-0 → hint) | retry (best-of-N) | **3+ interdependent + misdirecting** (retry can't single-point-fix) | **cross-subsystem REQUIRED** |

### What now differentiates the tiers (NOT trap quality — that's universal)

Trap quality (interdependent + misdirecting) is the FLOOR everywhere. Tiers differ on:
- **Trap COUNT:** Mars ~2-3, Olympus/Diamond 3+.
- **SPAN:** Mars + Olympus can be single-subsystem; **Diamond REQUIRES cross-subsystem** (a single-subsystem feature ceilings at Mars/Olympus regardless of LOC or mechanism-count — Task-Quality scope).
- **LOC floor + band:** Mars ≥100/≤30%, Olympus ≥450/≤20%, Diamond ≥450/~0-30%.

### Consequences

- **Single-point or self-revealing trap = too easy at EVERY tier now** (Nova will single-shot-fix it). Make traps interdependent + misdirecting even for Mars/Nova.
- **Mars caps at 30%, Olympus at 20%.** A single ~50% trap blows past both. Add interdependent + misdirecting traps until the rate lands under the cap.
- **LOC ≠ difficulty.** A 900-LOC uniform-wrap still fails the band. Big size with one weak/isolated trap = reject (too easy).
- **Push to the HARD edge of the band (PRIME DIRECTIVE).** The only hard lower constraint is solvability: at least one agent must pass (Mars/Olympus 0% = reject; Diamond near-0 routes to the hint flow, not reject). Above that floor, bias toward the hardest viable design. Do not soften a problem to land mid-window, and do not pad or cap LOC to hit a number (LOC floors are real, LOC ceilings are not). The cap (≤30% Mars / ≤20% Olympus) only rejects the TOO-EASY end.

---

## ⚠️ HARD RULE — Flakiness is a MANDATORY Check (admin 2026)

**Verify-flakiness is now a required gate.** A repo with flaky existing tests, or new tests that are non-deterministic, will fail review. Check BOTH:

1. **Repo flakiness (at pick time):** before scope-locking, run the repo's existing suite 2-3x. If tests pass/fail nondeterministically (timing, ordering, network, resource contention), either exclude those specific tests in `test.sh` base mode with a documented reason, OR pick a different repo if flakiness is pervasive.
2. **Your new tests (at write time):** must be 100% deterministic. NO timing (`time.sleep(0.1)`), NO randomness without a fixed seed, NO ordering assumptions, NO network (`--network none`), NO resource-dependent assertions. Run your new tests 3x locally; all 3 must give identical results.

Pre-submit flakiness check:
```bash
# Run new tests 3x — must be identical
for i in 1 2 3; do ./test.sh --output_path /tmp/run$i.xml new; done
# Run base 3x — must be identical (flag any test that flips)
for i in 1 2 3; do ./test.sh --output_path /tmp/base$i.xml base; done
```

If any test flips across runs: fix it (fixed seed, explicit wait-for-condition, `os.utime` instead of sleep) or exclude with a real reason. Flaky tests = mandatory reject now.

---

## ⚠️ HARD RULE — Derivative / Similarity Warning Response

**Platform now runs a stricter plagiarism / similarity check** comparing candidate against prior submissions across the whole pipeline (not just literal text match). **A "derivative" warning is a near-reject signal — fix before resubmitting or the submission gets blocked.**

### When you hit a "derivative" warning:

1. **Identify the cited similar submission(s)** — what feature class / API surface / trap shape overlaps?
2. **Expand on the meaningful differences** — make them explicit + prominent:
   - Different subsystem touched (parser vs optimizer vs runtime)
   - Different trap category (Section 1 mapping — convenience-method-leak vs pipeline-ordering vs concurrency-boundary)
   - Different cross-package wiring (CLI flag vs public API vs init() registration)
   - Different error-class hierarchy / different canonical output form / different ordering semantics
3. **Induce 1-2 ADDITIONAL meaningful differences** — actively add divergence:
   - Add a public API method the cited sibling doesn't have (e.g. `.Clone()` / `.Validate()` / parallel optimized variant)
   - Add a cross-package integration the sibling doesn't span (CLI integration tests, registry wiring)
   - Add a new edge case requirement (concurrency, unicode boundary, recursion termination) the sibling didn't test
   - Change trap shape — if sibling traps on storage layout, make yours trap on pipeline ordering (cross-architectural per Section 1)

### Anti-patterns (DO NOT do these to dodge the warning):

- Rename the API surface (`csv-separator` → `csv-divider`) — surface change ≠ behavioral difference, still derivative
- Reword meta.md — text-similarity isn't the only signal anymore; the check sees behavioral + structural overlap
- Bundle existing-pattern subfeatures — still derivative if the shape is the same
- Skip Phase 2 (`PATTERNS-ADVANCED § Pattern 22`) thinking similarity check substitutes — they catch different reject classes

### Pre-design check (avoid the warning entirely):

Before scope-locking, grep `Olympus-Approved/Feature-Requests/` for:
- Same feature CLASS keywords (not just API name)
- Same Section 1 trap category in solution-approach.md files
- Same shape per `SHAPES.md` (especially same Olympus shape — O-Composite-add saturated)

If 2+ approved submissions share your shape + repo-language + trap category → high derivative risk. Pick a different shape OR different trap category OR different cross-package surface BEFORE writing code.

---

## ⚠️ TRIVIALITY filter (added 2026-04-30 — second-order reject mechanism)

A pick is TRIVIAL (auto-RED) if it satisfies ANY of:

- **Pattern-followable**: 3+ existing functions in same file/folder match its shape (agent copies template, slots in code, ships in <50 messages)
- **Pure additive function ≤50 LOC** with no cross-cutting traps
- **Stdlib-equivalent**: `each`/`map`/`filter`/`sum`/`len`/`reverse`/`pick`/`omit`/`chunk`/`zip`/`partition`/`first`/`last` pattern
- **"Add N functions to namespace X"** where each function is independently solvable
- **Format wrapper around a standard library** (e.g. JSON-with-comments where target lib already supports it)

Active maintainers (e.g. dasel ships ~3 functions/week) make additive-function picks volatile: every additive pick has 1-2 week half-life before maintainer ships it OR reviewer flags as pattern-followable.

**Rule: prefer bug fixes over additive features when triviality risk is high.** If forced to ship an additive pick, ALWAYS bundle 3+ cross-feature traps (per `dasel-aggregation-functions` precedent).

See `Instructions/PATTERNS-ADVANCED.md § Pattern 23` for triviality-decision tree.

---

## ⚠️ HARD RULE — Too-Easy / Trivial Shelving (record + quarantine, NEVER re-pick)

When a sub is SHELVED or PIVOTED because it is too-easy (>30% Mars / >20% Olympus across a real batch), trivial, or pattern-followable, do BOTH of these immediately so the dead pick is never re-authored:

1. **Record it in `Instructions/TOO-EASY.md`** — append a case-study entry (repo + pick + tier attempted + batch results + ROOT CAUSE / why too-easy + the reusable law). Match the existing entry format. Add it to the Death-Class Taxonomy table if it is a new class.
2. **Move the problem folder into `rejected/`** — `git mv problems/<repo>-<slug> rejected/<repo>-<slug>` (or `diamond-problems/<name>` -> `rejected/<name>`). Keep the artifacts (do not delete) so the harness and the dedup check can see the shelved set. The folder stays intact (meta.md / test.patch / solution.patch / feedback.md) for reference only; it is NOT a submission.

`rejected/` is the quarantine dir for dead picks (too-easy, trivial, derivative, or pattern-followable). **At pick time, dedup MUST grep `rejected/` too** (alongside `problems/`, `diamond-problems/`, `Olympus-Approved/`) and reject any candidate matching a shelved feature class. `TOO-EASY.md` is the human-readable index of what lives in `rejected/` and WHY. A candidate that matches a `rejected/` entry is dead before authoring, not after another wasted batch.

---

## What This Repository Is

Olympus is a framework for creating AI-challenging coding problems based on real open-source repositories. Two active tiers: **Mars** (default, single-subsystem features, $125–175) and **Olympus** (cross-subsystem, $250–350). Diamond tier ($500) is premium Olympus with Failure QA. This repo is a **meta-project** — it produces problem submissions, not running software.

Pass-rate targets (UPDATED — see `## ⚠️ HARD RULE — Difficulty-Calibration Model` below):

- **Mars:** **≤ 30% pass** (Nova/Orion), must stay solvable (0% = reject)
- **Olympus Good:** **≤ 20% pass** (target ~10%, 1-2/12) across Nova/Orion/Vega/Castor
- **Diamond:** ~0-30% (near-0 → add hint)
- Too easy (>30% Mars, >20% Olympus, >30% Diamond) or unsolvable (0% any tier) = rejected
- **Flakiness is a mandatory check** — no flaky repo tests or non-deterministic new tests (see HARD RULE below)

## Two Workflows in This Repo

Two distinct tasks happen here. Identify which one you're doing before starting.

| Workflow                                  | Entry doc                                                                | Output location                                              |
| ----------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------ |
| **Authoring** problems                    | `Instructions/WORKFLOW.md` + `.agents/rules/olympus.md`                  | `problems/<repo>-<issue>/` or `diamond-problems/<name>/`     |
| **Reviewing** submissions (Mars Reviewer) | `Admin-Review/docs/MARS-REVIEW-GUIDE.md` + `.agents/workflows/review.md` | Reviewer feedback per `Admin-Review/docs/REVIEW-TEMPLATE.md` |

Reviewing has its own 5-stage process (GitHub check → understanding → rejection eligibility → description/test/solution review → final bug check). Per-stage rubrics live in `Admin-Review/docs/check_rejection.md`, `check_description.md`, `check_test.md`, `check_solution.md`, `check_bugs.md`. Style and tone are in `FEEDBACK-STYLE-GUIDE.md`. GitHub-search recipes are in `GITHUB-QUERIES.md`. Reviewer-side learnings live in `Admin-Review/docs/LESSONS-LEARNED.md` (separate from authoring `Instructions/lessons-learned.md`).

## Auto-loaded Agent Files

These load automatically — do not duplicate their content here:

- `.agents/rules/olympus.md` — master authoring agent prompt (always-on)
- `.agents/workflows/review.md` — `/review` workflow definition

## Skills (`.claude/skills/`)

Auto-trigger on intent match. See `/skills` for full list.

| Skill            | Triggers                                                                                                                           | Purpose                                                                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `olympus-author` | "create new problem", "Mars feature", "Olympus feature", clone into `worktrees/`, new folder under `problems/`/`diamond-problems/` | Embeds 5-phase design workflow producing DESIGN.md, then 8-step deliverable production, shape taxonomy, agent profiles, pre-submit checklist |
| `olympus-review` | "review submission", "Mars review", `/review`, opens problem folder with 4-deliverable set                                         | Embeds 6-stage Mars Reviewer process, 21-item checklist, DESIGN.md cross-check, hard-reject rules, feedback format                           |
| `olympus-hunt`   | "find repos", "hunt repos", "new targets", "repo recon", "what should I author next"                                               | Sources unsaturated Go/Rust targets, scores each for the `failure-patterns.md` trap seams, emits a ranked dossier. Upstream of olympus-author |
| `olympus-harden` | "too easy", "harden this", "raise difficulty", ">40% pass", after a batch comes back soft                                          | Diagnoses WHY a problem is easy from the agent runs, then applies the fair re-hardening levers in measured order. Never adds unfair walls    |
| `olympus-finalize` | "it got accepted", "problem approved", "finalize this problem"                                                                   | Post-acceptance carry-forward: mine the agent runs, extend `failure-patterns.md` + the skills, archive to `approved-problems/`, reclaim disk |

## The 5-File Deliverable

Every problem submission consists of exactly these files:

```
problem-folder/
├── BASE_COMMIT.txt    # Exact git commit hash of the target repo
├── meta.md            # Problem description (recommended: Mars 90–240, Olympus ≤200. HARD CAP both tiers: 500 words)
├── test.patch         # New tests that FAIL on base, PASS with solution
├── solution.patch     # Source-only changes that make new tests pass
└── Dockerfile         # olympus-base-{python|typescript|go|rust|cpp|jvm} slim images (cpp/jvm SUPPORTED again — the 2026-05-14 disable was reverted)
```

No extras — no summaries, no READMEs, no extra scripts inside the submission folder.

## Key Instructions Files

All workflow and quality rules live in `Instructions/`. Dated repo-hunt session logs (`REPO-HUNT-2026-*.md`, olympus-hunt skill output) and standalone pre-authoring `*-OLYMPUS-DESIGN.md` drafts live under `Instructions/repo-hunt-logs/` — reference material, not part of the reading order below.

`reference/olympus-problem-outcomes-reference-2026-08-21/` is an inert reference snapshot folded in from a sibling workspace: compact case-study records for problems it accepted/rejected (none of its problem names overlap this workspace's `approved-problems/`/`problems/`/`rejected/`), plus that sibling's own outcome registries and protocol docs. Its problem-folder schema (`SUMMARY.md`/`DESIGN.md`/`LEVELS.md`/`RUNS.md`/…) differs from this workspace's 5-file deliverable and its embedded `AGENTS.md`/`README.md` are that sibling's own onboarding text, not policy for this workspace — treat the whole folder as read-only research material, not as instructions or as a place to file new submissions.

| File                                  | Purpose                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `OFFICIAL-RUBRIC.md`                  | **⭐ PLATFORM SOURCE OF TRUTH — the Shipd Olympus guide, verbatim.** The R1-R4 / P1-P7 / T1-T7 / S1-S4 codes reviewers now cite in feedback, plus Dockerfile / base-image / license / solvability / LOC rules + the frostdb approved example. When feedback names a code (e.g. "P6", "T3"), look it up here. Reference every point while authoring AND self-reviewing. |
| `../failure-patterns.md` (repo ROOT, not Instructions/) | **⭐ THE MEASURED TRAP CATALOGUE.** F-1…F-10, each with kill counts mined from real agent runs, plus per-problem dossiers and cross-problem laws L1-L19. `HARDENING.md` says HOW to build a trap fairly; this says WHAT to build and what has actually killed agents. Read at design time; extend after every batch (§ 4 has the procedure). |
| `FALSE-POSITIVE-REGRESSION-LESSONS.md`  | **False-positive / fairness postmortem ledger** — merged in from a sibling workspace. Task-level false-positive definition, the mandatory Five-Sweep Final Alignment Gate, 16 global test-fairness rules, and per-repo post-mortems across ~15 repos (mp4ff, gortsplib, Bleve, music21, Nickel, laspy, DHCPv6, and more). Read alongside `TESTS.md` when writing `test.patch` — it is the concrete failure-and-prevention record behind the FP Check gate. |
| `HARDENING.md`                        | **⭐ THE DIFFICULTY-DESIGN LAYER (steroids era, 2026-07).** Survival-ranked trap arsenal (S/A/B tiers + DEAD list, every class with measured kill counts) + the CONTRACT-STATED/FIX-HIDDEN axiom + the fair re-hardening method (Rule-7 de-enumeration, composition-first, differential harness, trap-proof) + the steroids-era law index. Read at DESIGN time and at every too-easy diagnosis. |
| `PICK-FILTER.md`                      | **⭐ RUN FIRST — pre-pick gates (before authoring ANY Diamond/Olympus/Mars).** Query-10 codebase-brainstorm sourcing + 10 gates: behavioral-f2p-gap (decisive) · saturation · uniform-wrap · LOC-ceiling · cold-not-live · reproduce-on-base · dedup-all-dirs+judge-verdict · defined-behavior · no-flaky-repo · repo-quota. PASS = bug-flavored correctness gap in COLD code w/ externally-defined behavior. + scope-invent levers + the 10-run-batch-is-only-oracle meta-discipline. Each gate paid for by a dead pick. |
| `SATURATED-REPOS.md`                  | **Do-not-pick repo blocklist (check at pick time, Gate 10).** Section A = platform-flagged over-used repos (opa 60 = DEAD); Section B = our own ≥6-cap-reached (dasel/cliffy/yaegi). Record any repo the platform shows a "heavily over-used" warning for. Repo-level saturation only; dead difficulty CLASSES live in `TOO-EASY.md`. |
| `PRINCIPAL-REVIEWER-RUBRIC.md`        | **SOURCE OF TRUTH for final human review.** Principal reviewer's own 10-blocker list (natural prompt, JUnit crash-resilience, meaningful assertions, prompt-issue-on-shared-failure, behavior-not-impl, correlated blind spots, end-to-end wiring, test-exclusion reasons, difficulty rebalance, clean patches) + pre-submit 10-point walk. When a paraphrase conflicts, this file wins.                                                                                                |
| `PLAYBOOK.md`                         | **Read first.** Lean core — patterns 1-16 + approved tables + appendices (split April 2026)                                                                                                                                                                                                                                                                              |
| `SHAPES.md`                           | **Shape taxonomy.** Patterns 11-13 — 6 Mars + 6 Olympus shapes + best-agent-by-shape matrix                                                                                                                                                                                                                                                                              |
| `PATTERNS-ADVANCED.md`                | Patterns 17-33: trap-stacking ceiling, namespace expansion, triviality, post-base activity, opt-in flag, JUnit XML multi-package, etc.                                                                                                                                                                                                                                   |
| `PROBLEM-PROFILES.md`                 | Per-problem deep dives — behavioral data + iteration lessons (Section A from KNOWLEDGE, Section B from lessons-learned). Read for the closest-shape match.                                                                                                                                                                                                               |
| `KNOWLEDGE.md`                        | **Lean** — agent behavioral profiles (Castor/Vega/Nova/Orion) + cross-agent blind spots + message-count mechanics + Diamond cross-cutting.                                                                                                                                                                                                                               |
| `lessons-learned.md`                  | **Lean** — cross-cutting iteration lessons: description/tests/patches/reviewer-patterns/solution-quality/language-specific/submission-checklist/message-count/diamond-tier general.                                                                                                                                                                                      |
| `AGENTS.md`                           | Nova/Orion/Vega per-agent profiles, cross-agent blind spots, failure categories                                                                                                                                                                                                                                                                                          |
| `RULES.md`                            | 21-item review checklist, tier matrix, bypass message format, track record                                                                                                                                                                                                                                                                                               |
| `WORKFLOW.md`                         | End-to-end process: repo → design → tests → solution → Docker → submit                                                                                                                                                                                                                                                                                                   |
| `DESCRIPTION.md`                      | Shape-aware meta.md writing, blind-spot pre-empt sentence bank                                                                                                                                                                                                                                                                                                           |
| `TESTS.md`                            | 4-block test layout, JUnit XML by language, build-failure fallback                                                                                                                                                                                                                                                                                                       |
| `SOLUTION.md`                         | Helper extraction, fixpoint loops, modified-vs-new ratio, integration patterns                                                                                                                                                                                                                                                                                           |
| `DOCKER.md`                           | Pattern A (`olympus-base-rust`+chmod/symlink for Rust workspaces) vs Pattern B (slim per-language images: `olympus-base-{python                                                                                                                                                                                                                                          | typescript | go}`). **✅ Java/JVM + C/C++ SUPPORTED again (2026-05-14 disable reverted) — valid targets; verified C++/Java toolchains + footguns in DOCKER.md.** Platform guide: <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit> |
| `PROMPTS.md`                          | 14 reusable agent prompts (Mars/Olympus/Diamond/Lite/tier-agnostic) + **Query 13 LOCAL NOVA SOLVABILITY SIM** (parallel Sonnet imitators, pre-platform difficulty/pass-rate/msg-count estimate — fail-fast, NOT a platform substitute) + Query 14 clone-from-approved-pool + GitHub CLI                                                                                     |
| `DIAMOND.md`                          | Premium Diamond tier: $500/submission, Failure QA required                                                                                                                                                                                                                                                                                                               |
| `DIAMOND-PLAYBOOK.md`                 | **Evidence-based Diamond design + iteration discipline.** 8 Castor trap categories (cross-architectural ★ ranked by hit rate), design-time checklist (LOC/word/test/API bands from 2 approved), iteration cost model (mean 8 eval + 4-6 QA rounds), failure-QA 12-rule writing guide, Section 9 pre-submit maintainer-philosophy gate. Read BEFORE starting any Diamond. |
| `olympus-common-mistakes.md`          | Proven mistakes to avoid, agent failure patterns                                                                                                                                                                                                                                                                                                                         |
| `olympus-extreme-complexity-guide.md` | Anti-agent design patterns, difficulty tuning                                                                                                                                                                                                                                                                                                                            |
| `AUTO-REVIEWER.md`                    | Reverse-engineered auto-review pipeline + pre-submit hardening checklist (stable vs flaky criteria, contestation strategy)                                                                                                                                                                                                                                               |

**Reading order for new authoring task:**

0. `PICK-FILTER.md` — **RUN THE 8 PRE-PICK GATES FIRST.** A candidate that fails any gate is dead — do not author it. (behavioral-f2p-gap is the decisive first gate; build-measure + reproduce-trap are necessary-not-sufficient; the 10-run Nova/Orion/Castor BATCH is the only difficulty oracle.)
1. `PLAYBOOK.md` (foundation)
2. `SHAPES.md` (identify the shape your problem fits)
3. `PROBLEM-PROFILES.md` — open closest shape/repo match
4. `PATTERNS-ADVANCED.md` if your shape touches additive features (Pattern 22/23) or trap-stacking (Pattern 17)
5. Tier-specific: `DESCRIPTION.md`, `TESTS.md`, `SOLUTION.md`, `DOCKER.md`
6. Cross-reference: `KNOWLEDGE.md` (agent profiles) + `lessons-learned.md` (cross-cutting lessons)

## Mandatory First Steps (Before ANY Work)

1. Read every file in `Instructions/` — line by line, no skimming. Start with `PLAYBOOK.md`.
2. Study approved submissions in `Olympus-Approved/Feature-Requests/` (meta.md, test.patch, solution.patch, Dockerfile, feedback.md). Mars approved references live in `Mars Approved V2/Feature Requests/` (when present).
3. Pay special attention to problems in the same language/repo as the current task
4. **Author flow**: produce `DESIGN.md` first (14-section template in `olympus-author` skill / `WORKFLOW.md § Step 1`) BEFORE any code, test, or Dockerfile work
5. **Review flow**: follow `Admin-Review/docs/MARS-REVIEW-GUIDE.md` 6-stage process (or `olympus-review` skill)

## Core Principles

- **Fair and solvable** — every requirement in tests must be documented in the description; ≤1 codebase-inferable requirement
- **Hard but not unfair** — Mars ≤30% pass, Olympus ≤20% pass (target ~10%), Diamond ~0-30%; 0% Mars/Olympus = rejected (hints removed April 2026; Diamond keeps hints). **Traps must be INTERDEPENDENT + MISDIRECTING at EVERY tier (Nova≈Castor now — single-point traps single-shot-fixed).** Difficulty serves the BAND — see `## ⚠️ HARD RULE — Difficulty-Calibration Model`.
- **Behavioral, not prescriptive** — describe WHAT, not HOW
- **Identify the shape FIRST** — 6 Mars shapes (A1/A2/B/C/D-new/D-change) + 6 Olympus shapes (O-Composite-extend/O-Composite-add/O-Pipeline-easy/O-Pipeline-hard/O-Algorithm-coverage/O-Algorithm-correctness). Each has different pass-rate, file count, LOC, best-agent profile. See `SHAPES.md § Patterns 11–13`
- **Match repo comment convention** — not blanket ban; match existing files (e.g. pest minimal, h2 docstrings)
- **Match repo style exactly** — naming, patterns, error handling, file organization

## Mandatory Workflow Rules

### File Tracking (From Day One)

- Every problem MUST have `feedback.md` AND `eval-results.md` created from the start — do NOT wait for first results
- `feedback.md`: high-level summary, iteration tracking, fix history
- `eval-results.md`: per-agent table (agent name, evaluator, verdict, message count, files touched, LOC, **failed test NAMES**, failure reason, **one-line approach note** — the architecture the agent chose)
- **At every batch, SAVE passing-agent solution diffs** to `problems/<name>/agent-runs/<batch>-<run>.patch` (+ the 1-2 most instructive failers) while the platform run view is open — the differential harness, trap-proof, FP verification, and leanest-passer LOC all require the actual patches (`HARDENING.md § 3e`)

### After Every Evaluation Run — Update BOTH Files

1. `feedback.md` — high-level summary in attempt history
2. `eval-results.md` — full per-agent table for that run

### After Approval (CONFIRMED human reviewer only)

Move the problem folder into its tier's approved location — **Mars / Olympus (non-Diamond): `git mv problems/<...>/<name> Olympus-Approved/Feature-Requests/<name>` (flat, no repo subdir — e.g. `kcl-union-conflict-report`, sibling to `kcl-union-override-typecheck`); Diamond: `diamond-problems/approved/<name>/`.** Then update ALL of these with a concise, file-appropriate entry (append a `## <name> (APPROVED <tier> <date>)` section to each; differentiate by the file's purpose, do not duplicate verbatim):

1. `Instructions/lessons-learned.md` — key cross-cutting learnings from the problem
2. `Instructions/KNOWLEDGE.md` → Agent Behavioral Profiles — new blind spots, confirmed traps (recurrence-ranked across the runs)
3. Tier-conditional playbook (pick by the submission's tier):
   - **Diamond:** `Instructions/DIAMOND.md` (pipeline / grader-mechanics notes) AND `Instructions/DIAMOND-PLAYBOOK.md` (design + iteration discipline, confirmed bands)
   - **Mars / Olympus (non-Diamond):** `Instructions/PLAYBOOK.md` instead of the two Diamond files (do NOT touch DIAMOND.md / DIAMOND-PLAYBOOK.md)
4. `Instructions/olympus-extreme-complexity-guide.md` — confirmed anti-agent / difficulty patterns
5. `Instructions/PROBLEM-PROFILES.md` — per-problem deep dive (Outcome / Shape+Stats / decisive difficulty drivers / iteration lessons)
6. `Instructions/SHAPES.md` — a shape note if the pick introduced or confirmed a shape
7. `Instructions/PATTERNS-ADVANCED.md` — a new numbered Pattern if a reusable advanced pattern emerged
8. Auto-memory: flip the project entry + `MEMORY.md` index line to ✅ APPROVED; fold learnings into the relevant `lesson_*` topic file

Items 1-2 and 4-8 apply to EVERY tier; only item 3 (the playbook) is tier-conditional.

## Deliverables Checklist

- `BASE_COMMIT.txt` — exact commit hash (40-char), saved immediately after clone
- `meta.md` — action-verb title + plain prose. Recommended sweet spot by shape: Mars 90–240, Olympus ≤200. **Hard cap (both tiers): 500 words.** No `##` headers, no formulaic labels, no `Box<...>` wrappers
- `test.patch` — includes `test.sh` (executable, mode `100755` — `chmod +x test.sh && git add --chmod=+x test.sh` BEFORE generating diff; verify patch contains `new file mode 100755` for test.sh, NOT `100644`), coverage-driven count (Mars approveds 39–160), no comments inside test bodies
- `solution.patch` — source-only changes diffed against BASE_COMMIT. Mars sweet spot 170–380 LOC across 1–8 files (mode 3); Olympus/Diamond **≥450 effective design floor** (400 = platform auto-block) / 600+ Good across 8–35 files
- `Dockerfile` — Pattern A (`olympus-base-rust` + chmod/symlink) for Rust workspaces; Pattern B per-language slim image (`olympus-base-{python|typescript|go}:latest`) for everything else. **Slim images are May 2026 admin update — preferred for ALL new submissions.** Legacy generic `olympus-base` / `mars-base` only for re-verifying historical submissions. **✅ Java/JVM (`olympus-base-jvm`) + C/C++ (`olympus-base-cpp`) SUPPORTED again (the 2026-05-14 disable was reverted) — valid targets; verified toolchains + footguns in `DOCKER.md`.** `CMD ["/bin/bash"]`
- `feedback.md` — created from start
- `eval-results.md` — created from start

### Pre-Code Deliverable (Author Workflow)

- `DESIGN.md` — 14-section design document produced BEFORE any code (see `olympus-author` skill / `WORKFLOW.md § Step 1`). Contents: title, shape classification, public API surface, canonical output form, blind-spot pre-empts, description draft, file footprint, solution outline (helpers + fixpoint loops), test outline, forced trait bounds, predicted trap matrix, tier+category, predicted Nova pass rate, quality-gate checklist. Target: 1 revision round to ship; weak design = 3-5 rounds.

## Tier Decision

Pick at submit time:

|                  | **Mars** (default)                | **Olympus**                             |
| ---------------- | --------------------------------- | --------------------------------------- |
| Solution +LOC    | 100 floor (≥150 pref), **170–380 sweet spot** | 450 floor, 600+ sweet                   |
| Files modified   | 1–8 (mode 3)                      | 8–35 (median ~17)                       |
| Pass band        | **≤ 30%** (solvable; 0%=reject)   | **≤ 20%** (target ~10%); 0%=reject       |
| Trap structure   | **~2-3 INTERDEPENDENT + MISDIRECTING** (Nova≈Castor) | 3+ interdependent + misdirecting, compounding |
| Solvability gate | 10 Nova/Orion at ≤30% pass        | ≥1 pass across 10+ Nova/Orion/Vega runs |
| Flakiness        | **mandatory check — no flaky tests** | **mandatory check — no flaky tests**  |
| Hint system      | **Removed April 2026**            | **Removed April 2026**                  |
| Revision rounds  | 1–3 (playbook-aligned)            | 3–5                                     |

Olympus solvability **cannot be bypassed**. If 0% across runs, redesign or downgrade to Mars. Mars too-easy (>30%) and Olympus too-easy (>20%) also reject — see `## ⚠️ HARD RULE — Difficulty-Calibration Model`.

## Agents (costs + availability updated 2026-09-02)

**⚠️ Costs are per RUN and are 6-8x higher than the old ⚡1/⚡10/⚡25 figures this table used to carry. Availability is gated by account rank.** Confirmed by the account holder 2026-09-02 while iterating vivisect-noret-propagation.

| Agent      | Tier                          | Cost / run     | Availability (Iron rank)     | Strengths                                            | Where it fails                                                          |
| ---------- | ----------------------------- | -------------- | ---------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
| **Nova**   | Olympus (10 runs)             | **4 tokens**   | LOCKED (temporarily)         | Exploration-heavy, compact passing solutions         | High thrashing on hard problems → Early Termination                     |
| **Orion**  | Olympus, Evaluator (2 runs)   | **24 tokens**  | AVAILABLE                    | Decisive commit-and-implement                        | When wrong architecture chosen, doesn't pivot                           |
| **Vega**   | Olympus                       | **32 tokens**  | LOCKED until **Gold** rank   | Heavy multi-stage refactoring, 700–975 LOC solutions | O-Composite-extend symmetric refactor, O-Algorithm-coverage             |
| **Castor** | Diamond (Olympus also OK)     | unknown        | LOCKED until **Gold** rank   | Diamond-tier failure QA target, 1500+ LOC capacity   | Bash heredoc hangs on large file writes; type inference too restrictive |

**A batch may MIX agents** — the 10-run solvability gate does not require 10 of the same agent (e.g. 2 Orion + 8 Nova is a valid batch). Mix to control cost: put the expensive agent where it discriminates and fill the rest with the cheap one.

**⭐ Budget consequence — design to a pass rate you can AFFORD to measure.** At 24-32 tokens/run a 10-run batch costs 240-320 tokens, and a problem designed at the ~10% band is statistically indistinguishable from 0% (unsolvable = reject) in any batch small enough to afford. When only expensive agents are unlocked, target the middle of the band (~20-30%), which shows a pass within 3-4 runs and still keeps margin under the 40% ceiling. When cheap Nova is available, mix it in and the low-pass edge becomes measurable again. Do NOT burn a second full batch just to disambiguate 0% from 10%.

**⭐ Re-eval changes the ITERATION half of this math (2026-09-03).** The FIRST batch is still full price, but every later round that touches only `test.patch` / `solution.patch` re-grades at ~30% (a 10-Orion batch: 240 tokens down to ~72). So the expensive thing is now the SOLVER-VISIBLE surface, not the number of rounds: settle `meta.md` + Dockerfile + base commit before the first batch, then steer with re-eval. It is a paired re-measurement on a fixed solution set, so it steers but does not confirm — see `## ⚠️ RULE UPDATE 2026-09-03`.

**Castor active for Diamond submissions only.** Mars uses Nova+Orion. Olympus uses Nova/Orion/Vega. Diamond requires 10+ Castor runs targeting **≤30% pass rate (1-3 of 10)** post-relaunch 2026-05-13. See `Instructions/DIAMOND.md` (pipeline + staleness), `Instructions/DIAMOND-PLAYBOOK.md` (evidence-based design + iteration discipline from 6 subs), and `Instructions/KNOWLEDGE.md § Castor`.

## Local Toolchains - JVM/C++ SUPPORTED again (2026-05-14 disable reverted)

Java/JVM + C/C++ repos are valid targets again. Use the verified `olympus-base-jvm` / `olympus-base-cpp` toolchains + footguns documented in `Instructions/DOCKER.md` (Gradle-cache must be `a+rwX` writable, nlohmann/json FetchContent-offline pattern, `gradlew test --tests __nope__` graph-warming). Local JDK setup: `Instructions/jvm-toolchain.md`.

---

## ⚠️ ENVIRONMENT CONSTRAINTS (this workstation, updated 2026-08-25)

**DOCKER IS NOW AVAILABLE.** Docker was installed on this workstation on 2026-08-25 (confirmed
working: `docker --version`, `docker run --rm hello-world`). The previous "NO LOCAL DOCKER
SIMULATION" restriction below is stale for anything after that date — use Docker going forward to
actually validate each problem's Dockerfile (`docker build` the submission's Dockerfile, `docker run`
it, and exercise `test.sh base`/`test.sh new` INSIDE the container) rather than only reasoning about
it statically. Still watch disk usage closely (see below) — Docker image layers and build caches are
an additional, potentially large consumer on top of bare `cargo`/`go` target dirs; prune images/
containers (`docker system prune`) after each validated problem rather than leaving them.

<details>
<summary>Historical note (pre-2026-08-25): Docker was NOT available on this workstation</summary>

Docker was not available here for problems authored/reviewed before 2026-08-25 — `docker build` /
`docker run` were never attempted, and Dockerfiles for those problems were validated only statically
(base image, offline build, deps, `CMD ["/bin/bash"]`, test.sh mode 100755), with real Docker
validation recorded as owed to the platform run. If revisiting one of those older problems, prefer
actually running it in Docker now rather than trusting the old static-only reasoning.
</details>

Everything else (build, tests, flakiness 3x, patch apply/revert, LOC counting) IS validated locally
regardless, on top of the Docker run — Docker validation is additive, not a replacement for it.

**TOOLCHAIN PATHS.** `go`, `cargo`/`rustc`, and `go-junit-report` are ALL on PATH now — both
toolchains were consolidated 2026-08-26 under this project's `.toolchains/` directory and wired
into `~/.bashrc`/`~/.profile`, so a new shell needs no manual PATH export at all. The stale
`~/sdk/go1.26/bin` and `~/go/bin/go1.26` paths this note used to cite no longer exist on this
workstation. Current layout:
- Go: `GOROOT=.toolchains/go` (go1.25.0), `GOPATH=.toolchains/gopath` (also holds
  `gopath/bin/go-junit-report`), `GOCACHE=.toolchains/gocache` — all under
  `/mnt/0844D3E544D3D392/CS/Projects/Olympus/`.
- Rust: `CARGO_HOME=.toolchains/rust-toolchain/cargo` (also holds `cargo/bin/cargo2junit`),
  `RUSTUP_HOME=.toolchains/rust-toolchain/rustup`, same project root.

If a shell in this session was started before 2026-08-26 and hasn't re-sourced `~/.bashrc`, export
the four vars above plus `PATH="$GOROOT/bin:$GOPATH/bin:$CARGO_HOME/bin:$PATH"` manually before
using `go`/`cargo`/`go-junit-report`/`cargo2junit`.

**ALWAYS WATCH DISK USAGE.** This disk runs near-full and a build has already filled it mid-session
(the temp filesystem hit 0MB and tool output was lost). Rules:

- `du -sh worktrees/*` before and after any build; `df -h /home` when a build finishes.
- **`cargo`/`go` target dirs are the entire cost** — measured: gluon 5.3G, numbat 2.1G, veryl 1.8G,
  comrak 974M, against a 437M project. The CLONE is 3-32M; the TARGET is up to 100x that.
- **Delete `worktrees/<repo>/target` as soon as a measurement is done.** Keep the clone.
- Prefer scoped builds (`cargo test -p <crate>`) over `--workspace`.
- Free space BEFORE starting a long build, not after it fails.

## Repo Cloning — ALWAYS Use worktrees/

**ALWAYS clone target repos into `worktrees/<repo-name>/`** — never anywhere else in the project.

```bash
git clone <url> worktrees/cliffy
cd worktrees/cliffy
git checkout <BASE_COMMIT>
```

`worktrees/` is git-ignored so cloned repos never pollute the Olympus repo history. After cloning, save the commit hash immediately: `git rev-parse HEAD > problems/<folder>/BASE_COMMIT.txt`

## Patch Generation — ALWAYS Diff Against BASE_COMMIT

```bash
BASE_COMMIT=$(cat BASE_COMMIT.txt)
git diff $BASE_COMMIT -- <source files only> > solution.patch
chmod +x test.sh                                        # filesystem bit
git add --chmod=+x test.sh                              # index mode 100755 (CRITICAL on Windows)
git add tests/
git diff --cached $BASE_COMMIT -- test.sh tests/ > test.patch
```

**NEVER** use `git diff HEAD`, `git diff origin/main`, or `git diff` without `$BASE_COMMIT`.

### test.sh Executable Bit — CRITICAL

Platform invokes `./test.sh --output_path <path> base|new` directly — non-executable `test.sh` produces "Permission denied" and the run fails before any test runs. Verify the patch contains `new file mode 100755` for test.sh, NOT `100644`. On Windows, `chmod +x` alone does not update the git index — use `git add --chmod=+x test.sh`.

### Test File Naming — Banned Markers (CRITICAL)

Test file names MUST NOT contain `shipd` or `datacurve` — predictable markers that let implementer agents guess test filenames. Platform precheck hard-rejects any test file with these substrings (example precheck output: `"interp/goroutine_lifecycle_shipd_test.go" contains banned marker "shipd"`).

**Use a random hex suffix instead** so the filename cannot be predicted:

```bash
# Generate 6-char hex
HASH=$(openssl rand -hex 3)
# Then name the test file:
# Python:     test_{name}_${HASH}.py
# TypeScript: {name}.${HASH}.test.ts
# Go:         {name}_${HASH}_test.go
# Rust:       {name}_${HASH}.rs
# Deno:       {name}_${HASH}_test.ts
```

Apply to every new test file. Existing repo tests stay as-is. Verify before generating test.patch:

```bash
grep -rEl "shipd|datacurve" tests/ test.sh   # must return nothing
```

### Patch Encoding on Windows — CRITICAL

Windows tools write patches as UTF-16LE with BOM — `git apply` silently fails. Always generate via Python:

```python
r = subprocess.run(['git','diff','--cached', base,'--', <files>], capture_output=True, text=True, cwd=cwd)
with open(patch_path, 'w', newline='\n') as f:
    f.write(r.stdout)  # newline='\n' → LF, text=True → UTF-8
```

Verify: `file solution.patch` must say "ASCII text", NOT "Little-endian UTF-16".
Verify: `grep "new file mode" test.patch` must show `100755` for test.sh.

## JUnit XML Output (Required for ALL Problems)

`test.sh` MUST accept `--output_path <path>`. Platform invokes: `./test.sh --output_path <path> base`.

```sh
#!/bin/sh
MODE=""
OUTPUT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output_path=*) OUTPUT_PATH="${1#--output_path=}"; shift ;;
    --output_path)   OUTPUT_PATH="$2"; shift 2 ;;
    base|new)        MODE="$1"; shift ;;
    *)               shift ;;
  esac
done
MODE="${MODE:-base}"
if [ -n "$OUTPUT_PATH" ]; then mkdir -p "$(dirname "$OUTPUT_PATH")"; fi
```

Language-specific JUnit flags:

- **Deno:** `deno test --junit-path="$OUTPUT_PATH" ...`
- **Go:** `go test -v ... 2>&1 | go-junit-report > "$OUTPUT_PATH"`
- **Python:** `pytest --junitxml="$OUTPUT_PATH"`

### Deno new-mode JUnit fallback (CRITICAL)

When tests fail due to missing exports on base commit, Deno produces empty JUnit XML (0 test cases) which the platform rejects. Fix: after deno exits non-zero, check if the XML has no `<testcase>` entries and write a synthetic failure XML:

```sh
deno test --no-check --junit-path="$OUTPUT_PATH" ...
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && [ -f "$OUTPUT_PATH" ]; then
  if ! grep -q '<testcase' "$OUTPUT_PATH" 2>/dev/null; then
    cat > "$OUTPUT_PATH" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="deno test" tests="1" failures="1" errors="0" time="0">
<testsuite name="output_format_test.ts" tests="1" failures="1" errors="0">
<testcase name="output format module load" classname="output_format_test.ts">
<failure message="Module failed to load">Solution not applied.</failure>
</testcase>
</testsuite>
</testsuites>
XMLEOF
  fi
fi
exit $EXIT_CODE
```

Use `--no-check` on new mode only (skips TS type checking so Deno reaches runtime even without solution types). Do NOT use `--no-check` on base mode.

## Description (meta.md) Rules

- **REQUIRED YAML frontmatter block FIRST, before the `#` title** — `Repository`, `Issue` (full URL or `N/A`), `Commit` (40-char, copied byte-for-byte from `BASE_COMMIT.txt`), `Language`, `Category` (`feature-request` | `enhancement`, must match the title verb), `Title` (same text as the H1). Convention across the approved set (calyx / neva / pulldown-cmark; only the oldest, lyon, predates it). It is metadata: excluded from the word budget, and the no-`##`-headers rule applies only to the body below it. Full rules + template: `Instructions/DESCRIPTION.md § REQUIRED — the YAML frontmatter block`
- Title: `# <Action-verb behavioral ask>` — Fix/Add/Implement/Extend/Iterate/Rewrite, 5–10 words, names specific subsystem
- **First sentence of the BODY must read as the feature request** (`Add <capability> to <subsystem>.`), not as narration of current behavior. Reviewers are graded on the DESCRIPTION, not the title, and the title is often not shown beside it. State the current behavior in the SECOND sentence. Full rule + good/bad table: `DESCRIPTION.md § HARD RULE — The FIRST SENTENCE of the body`
- Body: 2–6 plain-prose paragraphs, NO `##` headers, NO formulaic labels (`Problem Description:`, `Test Assumptions:`)
- Word budget by shape: Mars C ~91 / Mars A1 ~107 / Mars A2 ~137 / Mars D-new ~148 / Mars D-change ~183 / Mars B ~241 (cap 240); Olympus cap 200
- Backticks **only** for new public API names (not internal types, no `Box<...>` wrappers)
- Every test traces to description; every described behavior has a test; ≤1 codebase-inferable requirement
- Spell out canonical form (sort order, associativity, dedup) when tests use `assert_eq!` on structures
- Apply blind-spot pre-empt sentences when applicable (see `DESCRIPTION.md § Blind-Spot Pre-Empt Sentence Bank`)
- **Human-voice + ASCII (ALL TIERS — platform AI-slop detector):** NO em dashes (U+2014), NO `--` in prose (code/CLI flags OK), NO Unicode arrows / smart quotes / ellipsis, NO AI cadence (Sure! / I'd be happy / It's important to note / In essence / At its core / Notably / This approach / not only X but also Y / forced tricolons). Pre-submit: `rg '[\xE2][\x80][\x90-\xAB]' meta.md` → empty; `file meta.md` → "ASCII text". Full ruleset: `DESCRIPTION.md § Human-Voice + ASCII Rules`.

## Tests Rules

- **4-block layout** (Rust): imports → builder helpers (10–30 one-liners) → assertion helpers → granular `#[test]` functions
- **Coverage-driven, count-agnostic**: every described behavior, every public API, every solution branch, every edge case (empty/zero/single/boundary/unicode/recursion/null)
- Scenario-encoded snake_case names: `range_z_to_a_errors`, `dedup_two_class_is`, `fixpoint_three_way_prefix_folds_completely`
- **Substring-match for errors** with 1–3 stable keywords (never `==` on full message)
- `assert_eq!` for tree/list/string outputs (strong); avoid weak `is_ok()` / `length > 0` / `toBeDefined()`
- Zero `//` comments inside test bodies (unless repo convention)
- test.sh with `base` (existing tests) and `new` (new tests only) modes, `--output_path` JUnit XML
- **Build-failure fallback** non-negotiable for Rust — empty XML on cargo crash = "No test suite results were found"

## Solution Rules

- Mars: 170–380 LOC sweet spot across 1–8 files (mode 3)
- Olympus/Diamond: **≥450 effective design floor** (400 = platform auto-block), 600+ Good rank across 8–35 files
- **Pure-function helpers extracted** — 1+ per behavior the description names (universal pattern across approveds)
- **Fixpoint loops** explicit: `loop { … if !changed { break; } }` when description says "iterate"
- Match repo comment convention exactly (not blanket ban — pest minimal, h2 docstrings, oxvg `///` doc comments)
- No `// TODO/FIXME/NOTE`, no `println!`/`dbg!`/`console.log`, no commented-out alternatives
- No drive-by refactors, no breaking changes to existing function signatures
- solution.patch: source files ONLY (no test files, no Dockerfile)

## Running Tests for a Problem

```bash
./test.sh base                              # Verify no regressions
./test.sh new                               # Verify new tests pass
./test.sh --output_path /tmp/test.xml base  # JUnit XML output
```

## Repository Pipeline

- `FINAL-CANDIDATES.md` — single source of truth for active targets
- `problems/` — in-flight authoring work (currently: cliffy, dasel, ferret, fq, nmap-formatter, node-minify, sqlc, tengo, yaegi)
- `diamond-problems/` — premium-tier authoring (`approved/` subfolder holds shipped diamond problems)
- `*-analysis/` (`ferret-analysis/`, `kysely-analysis/`, `sqlc-analysis/`, `tengo-analysis/`, `yaegi-analysis/`) — exploratory pre-problem investigation notes; **not** part of any deliverable
- `brainstorm.md` — analyzed candidates that may or may not become problems
- `github_repos.json` — repo metadata (877 repos) used by candidate-discovery scripts

Approved references in `Mars Approved V2/Feature Requests/` (Mars), `Olympus Approved/` (Olympus), `Olympus-Approved/Feature-Requests/` (older Olympus). Open the closest shape match in side-by-side editor and use as scaffolding.

## Repo Tooling

- `patch_gen.py` (repo root) — canonical patch generator template. Forces UTF-8 + LF (avoids the Windows UTF-16LE BOM trap). Copy and edit per problem; do not invent your own diff command.
- `scripts/` — candidate-discovery tooling: `find_hard_repos.py`, `find_top5.py`, `fetch_<repo>_issues.py`. Used to populate `FINAL-CANDIDATES.md` and `brainstorm.md`. Re-run only when sourcing new candidates.

## Problem Difficulty Target

Aim for features requiring understanding of internal architecture (compiler pipelines, type systems, VM bytecode) — not just syntax.

| Tier                 | Pass-rate band              | Verdict                                                          |
| -------------------- | --------------------------- | ---------------------------------------------------------------- |
| Mars (default)       | **≤ 30% Nova/Orion** (solvable) | Approvable                                                   |
| Olympus Good         | **≤ 20%** (target ~10%) across Nova/Orion/Vega/Castor | Approvable                          |
| Diamond              | ~0-30% Castor (near-0 → hint) | Approvable                                                     |
| Too easy             | **>30% Mars, >20% Olympus**, >30% Diamond | Reject — add interdependent+misdirecting traps (knob is trap count/strength, NOT LOC) |
| Flaky tests          | any test flips across runs  | Reject — mandatory flakiness check (fix or exclude with reason) |
| Unsolvable           | 0% Mars/Olympus             | Reject — hints removed April 2026; redesign or downgrade to Mars |

**The difficulty knob is trap COUNT/STRENGTH → pass-rate, NOT LOC.** 1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%. A uniform-wrap (one local rule, ≈50%) is too easy at EVERY tier now. See `## ⚠️ HARD RULE — Difficulty-Calibration Model`. **Wrong Logic ≥25%** signals subtle algorithmic/semantic correctness trap (O-Algorithm shapes). Hardest problems sit at 0–10% pass rate.

## Diamond Tier (Relaunched 2026-05-13)

Diamond problems (`diamond-problems/`) require additional Failure QA: written human analysis of every test failure explaining whether it was fair. **$500/submission + priority queue (minutes to few hours review turnaround) + increased token drips/cap.**

**Post-relaunch pipeline:**

1. Prechecks + Postchecks
2. **Smoke test:** 1x Castor or 1x Vega first (env blocker insurance)
3. **10x Castor + Diamond Checks** (NEW automated preflight pipeline — 50 tokens / 30min-1hr — replaces reviewer green-light)
4. If 0% pass → add hint, run 10x Castor (hinted) + Diamond Checks (hinted)
5. Holistic AI Review (sanity check)
6. Auto Review → "approved for QA" badge
7. Add QA artifacts (test-groups.md + failure-qa.md + platform UI)
8. Final QA Review (safe to iterate — QA-only changes don't stale Castor)
9. Submit → reviewer pass → finalization → accepted

**Key relaunch changes:**

- Castor pass rate ceiling: **≤30%** (was 1-5 of 10)
- Castor throttled to **25 tokens/run** (temporary)
- Reviewer green-light GONE — Diamond Auto Review gates QA
- Discord channels GONE — all feedback through Shipd
- Hinted submissions run Diamond Checks twice (unhinted + hinted)

**Fairness analysis before any iteration (admin 2026-05-29) — applies to ALL Castor runs, hinted or unhinted:** before adding hints, adding clarifications (in prompt or hint section), or running more agents, analyze WHY existing agents failed. Brute-forcing pass rate without analysis wastes tokens, produces low-quality submissions, risks revert downstream. Run small batch (1-3 Castor) first, then check why they passed or failed. Tests should check behavioral requirements regardless of approach the agent takes; if a specific approach is truly needed, prompt must say so. Strong unfairness signal: all or most agents fail for the same exact reason — could be implementation-detail tests (relax to sentinel + Kind), hidden requirement (add explicit meta sentence), ambiguous spec (reword, don't hint), or one genuinely hard step (acceptable for Diamond). Be honest: would a competent engineer reading only description + repo arrive at the implementation agents pick? If yes, tests must accept it. Hints on unfair problems hide unfairness, don't fix it.

**Hinted-runs policy (admin Leonard 2026-05-28):**

- **Trigger:** unhinted 10-Castor batch lands 0/10 AND failures are fair (no verifier breaks / unfair flags) AND pre-hint analysis cleared. Otherwise fix the artifact first.
- **Pass threshold:** no fixed minimum ("as long as some amount passes"). **Ceiling sanity:** if all 10 hinted pass, unhinted meta is under-spec'd — re-examine.
- **Hint section is separate from meta.md** in Shipd UI. Unhinted meta stays intact.
- **Test cheaply:** run 1-2 Castor with hint before committing 10.
- **Hint validity:** human expert with description+repo could infer it. Library/version specifics OK. Helper names / file paths / algorithm steps INVALID.
- **Every hint requires a "why inferrable" justification** — point to spec text or repo evidence.
- **QA load reduced for hinted runs:** success-QA ONLY. No failure-QA on hinted-run failures. Final artifact set = 10 unhinted (failure + success QA) + 10 hinted (success QA only).

**Staleness:** Diamond Checks stale on description / test patch / solution patch / dockerfile / repo+commit changes. QA artifacts only stale if Castor staled. Hint edits stale only hinted half. Air-tight submission BEFORE QA step — issues remedied later cost much more time.

See `Instructions/DIAMOND.md § Step 5b` (full hint flow + admin rules) and `DIAMOND-PLAYBOOK.md § hinted-runs QA discipline`.
