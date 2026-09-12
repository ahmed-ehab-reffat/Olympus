# Diamond Failure-QA Writer Prompt (copy-ready)

Hand the block below to whoever (or whatever agent) writes the Failure QA artifacts (`failure-qa.md` + `test-groups.md`) for a Diamond-tier Olympus problem. It is self-contained: read order, ground-truth gathering, the exact structure of both files, the rules that decide validator true-vs-MIXED, the reviewer-judgment rules, and a pre-handback checklist.

Source of the rules: `DIAMOND.md` (Failure QA Guide + rules 21-34), `DIAMOND-PLAYBOOK.md Section 5` (34 rules), `lessons-learned.md` rules 30-56, `KNOWLEDGE.md` yaegi entry. Distilled from the cliffy 6-round + dasel + yaegi-generic-constraint-fidelity (all-true across 10 runs) arcs.

Copy everything between the lines.

---

```
You are writing the Failure QA artifacts (test-groups.md + failure-qa.md) for a Diamond-tier Olympus problem. They get checked by TWO independent gates, and you must pass both in one shot:
  1. An auto-validator that greps the NAMED identifiers you cite and matches the described behavior against the code, returning true / MIXED / false per claim.
  2. A human reviewer who judges grouping fairness, per-test completeness, and tone.
All-true on the validator does NOT mean the reviewer passes -- they check different things. QA-only edits do NOT stale Castor / Diamond Checks / Auto Review, so iterate the artifacts freely until both gates are clean.

================ READ FIRST: GENERAL RULES, the EXAMPLES are NOT your content =====

This is a GENERAL procedure for ANY Diamond problem. Every concrete token in backticks below (`runErrIs`, `untyped float`, `assignableTo`, `rangeChan`, `Kind.String`, the FastAPI env example, etc.) is an ILLUSTRATION from a PAST problem to show the SHAPE of a rule. DO NOT copy these identifiers, test names, error strings, or constraint names into your QA -- they are almost certainly not in your problem. Build every artifact ENTIRELY from YOUR problem's real description, real test bodies, real run diffs, and real source symbols (gathered in Step 1). If your repo is not Go, the Go-flavored examples still teach the PRINCIPLE -- translate it.

================ STEP 0 - FOLLOW THE RULES; THE LISTED FILES OVERRIDE ON CONFLICT =

This block is a faithful WORKING ruleset and is ENOUGH to produce a correct first draft on its own. The files below are the AUTHORITATIVE fuller reference (more examples + edge cases) and they OVERRIDE this block on any conflict. If they are in your workspace, read them and comply; if they are NOT (e.g. you are in a different repo), proceed from this block -- do NOT stall or wait. Either way: follow the rules, do not improvise a different format.

Authoritative files (read if present, in this order):
  1. Instructions/DIAMOND.md
       - the "Failure QA Guide" (Zeroth Step, Three Required QA Annotations, Bad-vs-Good example, the failure-qa.md structure template)
       - "Failure QA Writing Style ... Validator-Substance Rules" (rules 21-27)
       - "Failure QA Writing Style -- Reviewer-Judgment Rules" (rules 28-34)
  2. Instructions/DIAMOND-PLAYBOOK.md Section 5 - the full 34 failure-QA writing rules + the ZEROTH RULE box + the "Validator-iteration cost reduction" subsection. This is the canonical rule list; read all 34.
  3. Instructions/lessons-learned.md - rules 30-56 (the Diamond QA cluster) + the "ASCII + Human-Voice Rules" block at the top.
  4. Instructions/KNOWLEDGE.md - the "yaegi-generic-constraint-fidelity" entry under Castor (the validator-iteration + reviewer-change-request bullets) for a worked example of what flags and why.

GOLD-STANDARD references (these ARE the format - copy their shape):
  - diamond-problems/approved/cliffy-command-aliases/failure-qa.md  (8 groups; per-failed-test entries; Correctness confidence + Issues; ZERO line numbers)
  - diamond-problems/approved/dasel-csv-options/failure-qa.md       (22 groups; runs with 16 grouped failures; ZERO line numbers)

Closest-to-current-rubric reference (all-true across all 10 runs + reviewer-format-aligned):
  - problems/yaegi/yaegi-generic-constraint-fidelity/failure-qa.md   (inlined 20-group Test Summary + coverage statement; 15 standalone failing blocks; per-test tables; Success Trajectory + Correctness confidence + Issues; zero value-anchored line numbers)
  - problems/yaegi/yaegi-generic-constraint-fidelity/test-groups.md  (run-independent companion)
  - problems/yaegi/yaegi-generic-constraint-fidelity/solution-approach.md

================ STEP 1 - GATHER GROUND TRUTH (do NOT write from memory) ========

For every run, open its Castor folder (Castors/S#N/ or equivalent): failing-test.md (the junit error line + the verbatim test body), sol-dif.md (the agent's actual diff), trajectory.md. Pull every call expression, expected value, kind assertion, sentinel name, and error string STRAIGHT FROM failing-test.md. Memory swaps literals across near-identical tests and gets you MIXED.

================ STEP 2 - WRITE test-groups.md FIRST (it feeds the Test Summary) =

test-groups.md is the detailed source-of-truth that the failure-qa.md "Test Summary" is condensed from. Write it first so groupings + spec quotes are consistent. It is uploaded to the platform alongside failure-qa.md, and it must stay RUN-INDEPENDENT.

Reference: problems/yaegi/yaegi-generic-constraint-fidelity/test-groups.md

Structure:

  # Test Groups: <problem-name>

  <N> F2P (fail-to-pass) tests across <M> behavioral groups spanning <packages>. Every test fails on base (test.patch only) and passes after solution.patch is applied.

  ## Group N: <Behavioral Title> (<count> tests, <pkg>/)

  - TestName_1
  - TestName_2
  - ...

  Description requirement (quoted from the description): "<verbatim sentence from the description, backticks preserved>"

  <1-3 lines: what this group verifies behaviorally + the inputs/edge cases it covers. State why the assertion is fair if non-obvious.>

Rules for test-groups.md:
  - Group by BEHAVIOR / requirement, not by "tests for function X". Each group maps to a described behavior, an API surface, a Kind, or an edge-case class.
  - Every group TRACES to a described requirement. Quote it VERBATIM (backticks preserved, in quotation marks) for the group that OWNS that requirement; for a sub-group that splits one requirement into facets, cross-reference the owning group's clause ("the Group 1 promotion clause", "same as Group 5 with 3 args") instead of re-quoting -- that is accepted and approved (the gold reference runs ~14/20 verbatim, ~6/20 split-cross-ref). What is NOT acceptable: a group with no traceable requirement at all (either the description is missing it -> fix the description, or the group tests something unstated -> unfair, fix it). Attribute every quote to "the description" - NEVER "quoted from meta.md" / "from the prompt" / any local filename; meta.md is only the local filename and must never appear in the artifact.
  - List EVERY F2P test by exact identifier. The sum of per-group counts must equal the total F2P count, and must equal the number of new tests the suite adds.
  - RUN-INDEPENDENT: no "6/10 runs fail this group", no "R12 cluster", no pass-rate annotations. Those are eval data and never belong in this uploaded artifact. A cross-run stat here is an instant reviewer flag.
  - Prefer substantive groups. Very sparse 2-3-test groups across the board read as in-flight/padded; consolidate cosmetic variations. Not a hard cap - a genuinely distinct 1-test behavior (e.g. "Kind.String stability") is fine.
  - Close with a COVERAGE statement, both directions: every prompt requirement maps to at least one group, AND every group traces to a quoted requirement.
  - Pure ASCII. file test-groups.md must say "ASCII text".

================ STEP 3 - failure-qa.md STRUCTURE (mirror the gold-standards) ====

## Success Solution Explanation
  High-level, a non-expert of the repo can follow it. What the feature does + the core trap. No diff narration.

## Test Summary
  The condensed inline form of test-groups.md. One line per group:
    "**Group N: title (M tests).** <what it tests>. From the description: \"<verbatim quote>\"."
  Close with the same coverage statement. Same groupings, same quotes, same counts as test-groups.md - do not let the two drift.

## Castor S#N: PASS (Y/Y new, Z/Z baseline)
### Success Trajectory Analysis
  Why correct + meets requirements + NO regressions. High-level, name the methods/fields, NO diff-step narration ("diff line 825" is banned).
  Correctness confidence: 1-5   (5 = fully correct)
  Issues: No issues noted.   (or, if a passing run hides an untestable bug: one line per issue with severity 1-5 [4+ blocking] and category {correctness/design/extensibility/readability/instruction following})

## Castor S#N: FAIL (X/Y new, Z/Z baseline)
### Failed Tests A-B/X: <cluster name>
  If the cluster's tests have DISTINCT calls/values, map each with a per-test table so every exact assertion is auditable:
    | Test | Call | Expected | Actual |
    |---|---|---|---|
    | test_name | `Call(args)` | `value` (and kind) | `verbatim junit error` |
  Then ONE shared root cause below the table.
  Unfairness check: Fair. <name the assertion helper and what it checks, e.g. "`runErrIs` asserts the error unwraps via `errors.Is` to `Sentinel`"> The description states: "<verbatim prompt quote, backticks preserved>". <why a seasoned engineer would infer it>
  Root cause: <named solution construct + the behavioral defect>. Type of error: {incorrect assumption | missed requirement | wrong architecture}.

================ STEP 4 - THE RULES THAT DECIDE TRUE vs MIXED ====================

PLATFORM NAMING (the artifact is read by a platform reviewer who never sees our workspace - APPLIES TO ALL ARTIFACT TEXT):
  - Quote requirements as "from the description". NEVER "quoted from meta.md", "from the prompt", or any local filename. "quoted from meta.md" is the #1 agent mistake here and is NOT acceptable - the platform calls the task text the description.
  - Do NOT name any local workspace file in the artifact text: meta.md, test.patch, solution.patch, Dockerfile, sol-dif.md, trajectory.md, failing-test.md, eval-results.md, the Castors/ folder. Those are how YOU gather evidence, not what the reviewer reads.
  - Use platform-facing terms instead: "the description", "the hidden test suite" or "the tests", "the agent's submission" / "the solution", "the reference solution". Name a concrete repo SOURCE path only when it is part of the agent's own diff (e.g. a test file the agent added, like `interp/constraint_test.go`) - that lives in the target repo, not our workspace.

Validator substance (ground every claim on three NAMES: the agent helper [what], the repo mechanism by function name [why], the verbatim error string [symptom]):
  - Cite NAMED identifiers (methods, types, helpers, sentinels), not generic phrases. The validator locates lines itself.
  - Quote error/spec strings VERBATIM and in full. No placeholders ("main.Y"), no truncation ("operator == ..."), no paraphrase. Keep backticks on quoted spec.
  - A bool predicate (isX / representableAs) does NOT emit errors - the CALLER constructs/returns the error when the predicate is false. State it that way.
  - Mirror the string junit actually renders (the sentinel's .Error() text); name the Go identifier separately in prose.
  - Name any in-repo test file the agent added; never claim "no test-file hunks" or "hidden suite untouched" without reading the diff headers.
  - Enumerate EVERY failing test; the listed count must equal (total - passing) for that run.

LINE NUMBERS - the #1 recurring MIXED (rules 13/31/34):
  - DO NOT attach a line number to a specific field/string VALUE (e.g. `str is "untyped float", type.go:160`). The validator greps that line, finds the value one line off, and the number now CONTRADICTS the value -> MIXED. It is non-deterministic on these. Describe the field by NAME instead (`str: "untyped float"`), no number.
  - Behavior-anchored line numbers (cited beside a named function whose behavior the validator matches, e.g. "the loose `assignableTo` (type.go:1466), which accepts an untyped float") are tolerated - but only cite a line you have READ this session. When unsure, drop it. Gold-standards carry ZERO line numbers and pass.

Reviewer judgment (not validator-flaggable, but gets change-requested):
  - Group ONLY tests that share the SAME root cause AND the SAME assertion shape. If each test has a distinct call/value/kind -> per-test table. Over-collapsing 14 distinct tests into 2 examples gets change-requested.
  - NEVER put two tests under one Expected/Actual unless they emit the same junit error class. Cascade/promotion failures are a different signature from typed-pin truncation even when adjacent in the run - split them.
  - In a FAILING block, explain only why THOSE tests fail. Do not credit a named branch with the OTHER (passing) tests' success - per-agent code differs and that cross-test claim is usually unverifiable.
  - A fairness rationale that asserts an external fact the validator cannot grep (e.g. "compiles under gc") must be framed interpretively ("a seasoned engineer would expect...") or dropped.
  - When a cluster's tests use DIFFERENT helpers, name each (e.g. "three use `runErrIs`; the fourth uses `runStructuredErr` + `errors.Is`").
  - Every entry STANDS ALONE - no "same as Castor #1", no "by the same inference as above".

  ADVANCED edge-rules (SKIP on the first draft; consult ONLY if a MIXED/FALSE verdict cites a claim you cannot otherwise explain -- each came from one specific past arc and may not apply to your problem):
  - GROUPING-BINDING (yaegi-channel-diagnostics arc): the validator binds each claim to the PLATFORM's behavioral grouping of the failing tests (the test-file group, observed as a name prefix - e.g. non-Cross vs Cross), NOT your symptom clustering. Align your failure blocks to that grouping. Never regroup a block along a symptom axis (genuine-deadlock vs false-positive) that cuts ACROSS the platform groups, even when a reviewer asks to "split" - a pure-symptom block bound to a symptom-MIXED platform group makes "each of these does X" FALSE for the other-symptom members. Keep the behavioral-group block and split the symptoms INSIDE it (prose + Expected column), with a both-manifestations root cause true for every bound test. A whole-group claim must hold for EVERY test the platform binds there.
  - PER-RUN CODE DIFFERS: a causal mechanism verified TRUE for one run can be FALSE for another with the same junit symptom. State only what THAT run's diff supports; when the causal timing is not in the diff, fall back to the verified predicate + junit observable.
  - GREP-VARIANCE: a bare backticked repo identifier the validator must grep (e.g. `rangeChan`) is TRUE in some runs, MIXED in others, for the same token. Anchor path-miss / range-miss claims on the agent's own helper + the behavior + the junit symptom, not a standalone repo function name. Cite the helper that HOLDS the switch, not a wrapper that delegates. No struct-literal tokens (`GoID: 0`) the diff does not contain.
  - FAIRNESS SCOPE: do not enumerate scenario examples belonging to OTHER tests in the run; keep the rationale generic-to-contract or name only the bound group's members.
  - STALE-VERDICT GUARD: before re-editing on a FALSE/MIXED verdict, grep the flagged strings in the current file - a verdict can score a pre-edit upload; if the text is gone, the verdict is stale on those claims.

Tone (human-voice; leadership monitors for AI):
  - Present-tense final-state framing. Do NOT mechanically open every paragraph with "In the final code, the agent..." - vary openers, several drop the prefix.
  - 2-3 short declarative sentences per unfairness/root-cause. No diff-line spam, no step references ("at step 21"), no cross-run comparisons.
  - PURE ASCII. No em dashes, no "--" in prose, no smart quotes / Unicode arrows. file failure-qa.md must say "ASCII text".
  - If you find a test is genuinely unfair/ambiguous during analysis, you MUST fix the prompt or verifier and re-run the pipeline - do not paper over it.

================ STEP 5 - VERIFY BEFORE HANDING BACK ============================

test-groups.md:
  - sum of per-group test counts == total F2P count == new-test count in test.patch
  - every group traces to a described requirement (verbatim quote for the owning group; cross-ref for split sub-groups), attributed to "the description" (NOT "meta.md")
  - a closing Coverage section maps every requirement to a group AND every group to a requirement
  - no run/pass-rate stat anywhere (NOT even "latest batch: 3 of 10 pass" in the header)
  - no local workspace filename appears in the artifact text (meta.md, test.patch, solution.patch, Castors/, etc.)
  - file test-groups.md -> "ASCII text"

failure-qa.md:
  - file failure-qa.md -> "ASCII text"
  - grep for value-anchored line numbers (a field value followed by file.go:NNN) -> none
  - per FAIL run: listed-test count == (total - passing)
  - every failing block has its own Unfairness check + Root cause + Type of error (standalone)
  - every PASS run has Success Trajectory Analysis + Correctness confidence + Issues
  - Test Summary closes with the coverage statement; its groups/quotes/counts match test-groups.md exactly
  - requirements attributed to "the description"; no "meta.md" or other local filename anywhere in the text

Aim for all-true on the first validator pass.
```

---

# Diamond Environment Description Writer Prompt (copy-ready)

The Environment Description is a separate Diamond deliverable: a Shipd UI field (DIAMOND badge), entered directly on the platform, NOT a submission file. It tells the platform what skill the environment teaches. It is QA-tier (does not stale Castor / Diamond Checks / Auto Review) but a too-short / mis-formatted one BLOCKS new problem runs. Mirror it locally in env-description.md (or feedback.md "Env Description") for tracking, then paste into the UI. Hand the block below to whoever writes it.

```
You are writing the Environment Description for a Diamond-tier Olympus problem. It is a Shipd UI field (DIAMOND badge), NOT a submission file. It tells the platform what skill the environment teaches the model.

AUTHORITATIVE + MANDATORY: read and follow `Instructions/DIAMOND.md` "Environment Description" section (and the channel-diagnostics Env Description learnings in DIAMOND-PLAYBOOK / Pattern 44). The rules below summarize that section; the file wins on any conflict. If you do not have it, proceed from this block -- do not stall. The examples here (the FastAPI env, any repo names) are ILLUSTRATIONS -- write from YOUR problem's repo + domain, never copy them.

================ HARD CONSTRAINTS (a miss here rejects new problem runs) ========
  - MINIMUM 300 characters. Ideal: one tight paragraph (2-4 sentences). Under 300 -> Shipd marks "0/300" red and blocks eval.
  - NO markdown heading / `#` title and no bold title line. The platform reads the first heading AS the field title, which collapses the rest into a single sentence. Plain prose only; the first sentence starts the paragraph.
  - PURE ASCII. No em dashes, no "--" in prose, no smart quotes / Unicode arrows (Diamond AI-slop detector).
  - Framed as the ENGINEERING CHALLENGE, NEUTRAL -- prefer NOT to name the exact mechanism the solver must use (mutex, frame-keying, watchdog, "promote before the check", strict representability, invented reference-solution helper names). That belongs in solution-approach.md; the env description says WHAT the environment exercises, not HOW to solve it. (Honesty / reviewer-variance: a LONGER recipe-style env that did name reference-solution helpers HAS been approved -- yaegi-generic-constraint-fidelity -- but yaegi-channel-diagnostics had to be REWORKED to neutral by its reviewer. Neutral + concise is the lower-variance, safer target; when unsure, neutral. Naming the target repo's EXISTING source files/functions is fine; naming helpers the solver is expected to WRITE leans recipe.)
  - Do NOT name local workspace files (meta.md, test.patch, solution.patch, Castors/). Platform-facing terms only: the repo, the description, the tests, the agent's submission.

================ COVER THESE THREE ELEMENTS (Shipd ops requirement) =============
  1. WHAT THE ENV TEACHES THE MODEL: the repo + domain + the concrete trap CLASS the model must master (stated as a concept, not a fix).
  2. WHAT A TYPICAL TASK LOOKS LIKE: a failing test fixed by a scoped change to the real subsystem.
  3. HOW THE TASK SETUP WORKS: what a SUCCESSFUL trajectory looks like vs a FAILING one. The strongest env descriptions make the failing trajectory "look almost right" (most tests pass) but trip on one specific blind spot. That contrast is the teaching signal.

================ TEMPLATE (fill, then delete the brackets) ======================
[Repo + domain in one clause]. [The concrete trap concept the agent must master, as a capability not a recipe]. The task: [behavior to fix] guided by [a failing test / the hidden tests]. A successful trajectory makes [target] green with [scoping discipline]. A failing one looks almost right, [most-tests-pass indicator], but trips on one thing: [the specific blind spot, named behaviorally]. Teaches [the generalized lesson].

(Use commas or colons for the asides, NOT dashes -- the artifact must be ASCII with no "--".)

================ APPROVED EXAMPLE (Shipd-provided, 352 chars, all 3 elements) ===
"A FastAPI + Postgres inventory service with a race on stock reservation. The task: fix it so concurrent reservations can't oversell, guided by a failing pytest. A successful trajectory makes that test green with a fix scoped to that endpoint. A failing one looks almost right, most tests pass, but trips on one thing: it wraps the wrong call in the transaction, or adds an over-broad lock breaking unrelated tests. Teaches scoping concurrency fixes narrowly."

Note: it states the trap as a CAPABILITY ("scoping concurrency fixes narrowly") and describes the near-miss WITHOUT naming the exact code fix. Copy that altitude.

================ REFERENCE THE APPROVED ONES (copy their altitude + length) ======
  - Copy the altitude of the NEUTRAL+CONCISE approved ones: cliffy-command-aliases (~460 chars) and yaegi-channel-diagnostics. Do NOT copy yaegi-generic-constraint-fidelity's env-description.md as an altitude model -- it is a longer, helper-naming recipe that passed but is the over-detailed end of the range, not the target.
  - Instructions/DIAMOND.md "Environment Description" section (template + enforcement + the no-`#`-title / neutral-not-recipe rules)

================ VERIFY BEFORE PASTING ==========================================
  - >= 300 characters (count it)
  - one paragraph, no `#`/heading/bold-title line
  - all three elements present (teaches / typical task / success-vs-failing trajectory)
  - reads as a challenge, names NO implementation mechanism, helper, or file
  - pure ASCII (no em dash, no "--"); no local workspace filenames
  - paste identical text into the Shipd UI field AND the local mirror
```

---

## Notes for the dispatcher (not part of the paste)

- Both QA artifacts (`failure-qa.md` + `test-groups.md`) are uploaded to the platform and read by the validator + reviewer; keep both platform-facing (no local workspace filenames in the text). The staling deliverables are meta.md (the task description), test.patch, solution.patch, Dockerfile, and the repo+commit; ANY edit to those stales Castor + Diamond Checks, so they must be air-tight before QA. The Env Description and the two QA artifacts do NOT stale Castor or Diamond Checks (none is in the staling set) - they are QA-tier and can be edited in a QA-only round, e.g. a wrong-test-count or recipe-tone fix, without restaling. (Confirmed: a reviewer "only for QA, rest is good" round edited the Env Description count + tone with no rerun.)
- If the writer is a subagent, also give it the absolute repo path and the specific problem folder so it can open the Castors/ ground truth and the reference files.
- Expected first-pass outcome if the rules are followed: 0 MIXED. The recurring MIXED classes (value-anchored line numbers, over-collapse, cross-test attribution, ungreppable external facts, mixed-helper generalization) are all pre-empted above.
