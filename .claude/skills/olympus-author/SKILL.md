---
name: olympus-author
description: Use when authoring a new Olympus problem submission (one tier since the 2026-07 sprint merged Mars into Olympus; current floor >=200 effective LOC / >=2 files / >=40 solver-median messages, pass ceiling <=40%) — guides shape selection, difficulty design against the HARDENING.md trap arsenal, the TOO-EASY.md death-class pre-pick guard, 5-deliverable production (BASE_COMMIT.txt + meta.md + test.patch + solution.patch + Dockerfile), and pre-submit validation. Triggers when user mentions "create new problem", "author problem", "build a challenge", "Mars feature", "Olympus feature", "new submission", clones a target repo into worktrees/, or creates a folder under problems/ or diamond-problems/. Source of truth: Olympus/Instructions/HARDENING.md, TOO-EASY.md, PLAYBOOK.md, WORKFLOW.md, RULES.md, AGENTS.md, DESCRIPTION.md, TESTS.md, SOLUTION.md, DOCKER.md, CLAUDE.md RULE UPDATE 2026-07 (SPRINT).
---

# Olympus / Mars Problem Authoring

> **SPRINT UPDATE 2026-07 (supersedes 2026-06-26 bands + the Mars/Olympus split below where they conflict):** Mars has been MERGED into Olympus — author every submission as Olympus, there is no separate Mars tier anymore. New long-horizon floor: **>=2 file changes, >=40 agent messages (solver median), >=200 effective/meaningful LOC** (down from 3 files / 100 msgs / 450 LOC). Pass-rate ceiling raised to **<=40%** (up from 20%/30%; 0%=reject, >40%=too easy). Payout $150-350, scales with scope/difficulty/fairness/quality. FP Check now MANDATORY (final gate: verify every passing agent actually met every requirement, not just passed tests). See CLAUDE.md RULE UPDATE 2026-07 (SPRINT).
>
> The Mars/Olympus two-tier tables below (bands updated 2026-06-26) are HISTORICAL — per-shape LOC/file/test/word figures are observational data from specific approved problems and remain useful precedent, but the hard floor/ceiling for every NEW submission is the sprint update above, not the per-tier numbers in these tables.

Build self-contained AI-challenging coding tasks. One tier: Olympus ($150–350, scales with scope/difficulty/fairness/quality). Diamond ($500) = premium Olympus + Failure QA.

**Stance: aim for the hardest viable problem down to the solvability floor. LOC floors are real (>=200 effective); LOC ceilings are not — never cap genuine complexity to hit a number.** (Matches CLAUDE.md PRIME DIRECTIVE.)

## Mandatory First Steps (Before ANY Code)

**Read these three in full before proposing a single candidate. They are the difficulty layer and
skipping them is how too-easy and dead-class picks get authored.**

1. **`Olympus/failure-patterns.md`** — the measured trap catalogue (F-1…F-10) plus the
   cross-problem laws. This is WHAT to build. Every candidate you propose must name the F-id(s)
   it targets and honestly check that pattern's precondition.
2. **`Olympus/Instructions/HARDENING.md`** — the doctrine: the CONTRACT-STATED/FIX-HIDDEN axiom,
   the S/A/B arsenal, Rule-7 de-enumeration, the fair re-hardening method. This is HOW to build
   it fairly.
3. **`Olympus/Instructions/TOO-EASY.md`** — the death classes. A pick that matches one is dead
   before authoring, not after a wasted batch.

Then:

4. Read the rest of `Olympus/Instructions/` line by line. Start with `PLAYBOOK.md`.
5. Study closest-shape approved in `Olympus/approved-problems/`. Open in side-by-side editor as
   scaffolding. `approved-problems/README.md` is the compact index of what broke each one.
6. Identify shape FIRST — tells target pass rate, file count, LOC budget, best agent.

**The standing intent: build the HARDEST problem that is still fair, down to the solvability
floor.** Fairness is achieved by documenting every tested behaviour in meta.md, never by capping
difficulty. Concretely, that means the trap set must be:

- **Orthogonal** — traps measured on DIFFERENT axes. A trap sharing an axis with another dies
  with it when review forces a disclosure (`failure-patterns.md` lyon dossier).
- **Interdependent** — fixing one surfaces or breaks another. The cheapest source of this is a
  single trap that rides every capability at once (F-9), not two mechanisms bolted together.
- **Composite** — at least one test on the CROSS-PRODUCT cell of two stated capabilities (F-10).
  This is the measured decider between a 20% and a 40% batch, and it costs zero description
  words.

## 5-File Deliverable

```
problems/<repo>-<issue>/  (or diamond-problems/<name>/)
├── BASE_COMMIT.txt    # 40-char hash, saved immediately after clone
├── meta.md            # Plain prose, action-verb title. Recommended: Mars ≤240 / Olympus ≤200. Hard cap both: 500 words
├── test.patch         # test.sh + new test files; FAIL on base, PASS with solution
├── solution.patch     # Source-only changes diffed against $BASE_COMMIT
└── Dockerfile         # Pattern A (olympus-base-rust+chmod/symlink for Rust workspaces) or Pattern B (slim per-language: olympus-base-{python|typescript|go}) — ⚠️ cpp/jvm UNSUPPORTED 2026-05-14
```

Plus from day one:
- `feedback.md` — strategic summary, attempt history, fix tracking
- `eval-results.md` — per-agent table per run

**Forbidden in submission folder:** `*_SUMMARY.md`, `*_PLAN.md`, `*_READY.md`, repo clones, READMEs.

---

## Tier Decision (current sprint — ONE TIER)

**Mars merged into Olympus 2026-07. Author every submission as Olympus.** The table below is the CURRENT hard floor/ceiling.

| Metric | Current floor/ceiling (hard gate) |
|---|---|
| Solution +LOC | **≥200 effective/meaningful** (Counter 2 / human-effective) — down from 450 |
| Files modified | **≥2** — down from 3 (median ~17 in older approveds is historical data, not a gate) |
| Agent messages (solver median) | **≥40** — down from 100 |
| Solvability gate | ≥1 pass across 10+ Nova/Orion/Vega runs (cannot be bypassed) |
| Pass-rate ceiling | **≤40%** — up from 20%/30% (0%=reject, >40%=too easy) |
| Hint system | Removed April 2026 |
| Revision rounds | 3–5 |
| Payout | $150–350, scales with scope/difficulty/fairness/quality |

Solvability **cannot be bypassed**. 0% across runs → redesign (route a near-0 design to Diamond, which keeps the hint flow).

<details>
<summary>Historical Mars/Olympus split (pre-2026-07, kept as shape-band reference only)</summary>

| | **Mars** (historical) | **Olympus** (historical) |
|---|---|---|
| Solution +LOC | 100 floor (≥150 pref), **170–380 sweet** | ≥450 design floor (400 = platform auto-block), **600+ Good** |
| Files modified | 1–8 (mode 3) | 8–35 (median ~17) |
| Solvability gate | 10 Nova/Orion at ≤30% pass + 2 Orion | ≥1 pass across 10+ Nova/Orion/Vega runs |
| Pass-rate target | ≤30% Nova/Orion | ~10% Good, ≤20% ceiling |
| Payout | $125–175 | $250–350 |

These per-tier numbers are superseded by the sprint table above; kept only because the shape tables in the next section cite them as observational precedent.
</details>

---

## Shape Decision Tree

### Mars (6 shapes)

| Shape | Trigger | Files | LOC | Tests | Words | Pass | Best Agent |
|---|---|---|---|---|---|---|---|
| **A1** | Distributed pipeline modification | 3 dist | 167 | 68 | 107 | 10–15% | Nova→Orion (slow) |
| **A2** | Concentrated + signature change | 3 conc | 220 | 92 | 137 | 20–25% | Nova→Orion (fast) |
| **B** | Add new public API list | 3 (2 new) | 377 | 160 | 241 | ≤30% (was 50–55%; harden with a 2nd interdependent+misdirecting trap) | Orion-alone |
| **C** | Additive extension (no sig change) | 1 dense | 358 | 39 | 91 | 20–25% | Nova→Orion |
| **D-new** | New cross-crate enum variant | 15 (4 crates) | 400 | 126 | 148 | 20–25% | Orion-alone (Integration risk) |
| **D-change** | Cross-crate variant signature change | 8 multi-crate | 340 | 102 | 183 | ≤30% (was 40–45%; harden with a 2nd interdependent+misdirecting trap) | Nova→Orion + Vega (Regression risk) |

### Olympus (6 shapes; O-Trap deprecated)

| Shape | Trigger | Files | LOC | Tests | Pass | Best Agent |
|---|---|---|---|---|---|---|
| **O-Composite-extend** | Refactor existing aggregation across packages | 9+ | 600 | 162 | ≤20% (was 25–30%; harden to ≤20%) | Orion (2/2) |
| **O-Composite-add** | New feature spanning parser/compiler/VM/runtime | 12 | 366 | 73 | 15–20% | Vega (3/5) |
| **O-Pipeline-easy** | New variant + cascading, familiar coalescing algo | 5 | 433 | 104 | ≤20% (was 25%; harden to ≤20%) | Vega (3/5) |
| **O-Pipeline-hard** | New variant + cascading, invent algorithm | 4 | 413 | 103 | 15% | Vega (2/6) |
| **O-Algorithm-coverage** | New variant + missing-element-in-list trap | 4 | 379 | 68 | 10% | Orion-alone (1/1) |
| **O-Algorithm-correctness** | New variant + subtle algorithmic correctness | 6 | 532 | 62 | 8% | Mixed |
| **O-Trap (HISTORICAL)** | Universal LLM blind spot at 0% | — | — | — | 0% | NOT VIABLE — redesign |

---

## Supplementary reference: corpus-derived hardness recipe (from a sibling workspace)

This workspace was merged from three prior authoring workspaces in Aug 2026 and now has an
**approved-problems corpus of ~80 problems** on disk. One sibling workspace had already mined its
own slice of that corpus (16 approved problems) into an empirical "hardness recipe" — ranked levers
for what actually clears human review, distinct from (and narrower than) this skill's own
`HARDENING.md`-based doctrine above. Read it alongside `HARDENING.md` and the Shape Decision Tree,
**not in place of them** — `HARDENING.md` remains the primary, actively-maintained difficulty layer
for this workspace; the recipe below is corroborating evidence from a smaller sample, kept for the
patterns it independently confirms.

**Observed ranges across that 16-problem sample (design inside these, not to the bare floor):**

| Dimension | Range across 16 | Median | Design target |
| --- | --- | --- | --- |
| Pass rate | 7%-30% | **10% (1/10, single solver — usually Orion)** | **1/10.** Land here, not at the ceiling. |
| Effective LOC | 319-1485 | ~540 | **500-700** (cluster is 474-694; go higher only if the feature is genuinely that big) |
| Files | 4-21 | ~8 | 5-11 |
| Tests | 25-255 | ~69 | 50-95 |
| Language | Rust 9 · Python 3 · Go 3 | — | any accepted lang; Rust/statically-typed dominates the hard picks |

**Six hardness levers, ranked by how many of the 16 used each — a hard problem stacks 3+:**

1. **One interdependent core kernel that drives many surfaces (~13/16).** Difficulty is NOT breadth
   of independent functions — it is a single engine feeding every read/eval/render path, so a LOCAL
   fix to one surface REGRESSES another. Concentrate difficulty in one shared kernel; do not scatter
   it across N trivial helpers (those amortize to one pattern and read as too-easy).
2. **Exact-output correctness against an EXTERNAL oracle, fuzzed to 0 mismatches (~12/16).** Pinning
   output EXACTLY is what holds the rate low instead of ~50% — near-misses FAIL because one edge is
   wrong. Build the oracle, fuzz it to zero mismatches, then pin exact output.
3. **Misdirecting traps — the failing test points AWAY from the cause (~10/16).** The assertion that
   breaks must not name the fix.
4. **"The obvious code is wrong" sentinel / index-space edges (~8/16).** The naive one-line
   implementation must be plausibly wrong on a specific, easy-to-miss edge.
5. **De-training via a bespoke or deliberately non-standard divergence (~8/16).** Either an obscure
   low-training repo, or a deliberate non-standard surface on a known spec, so the solver cannot
   pattern-match its training priors.
6. **Long-horizon multi-subsystem span (all >=446 eff, several 686-1485).** This clears the
   message-count + LOC floors and is distinct from trap difficulty — a hard problem needs BOTH span
   and traps.

**Two corroborating notes worth keeping in mind:**

- **The "fake difficulty = compile-time signature coin-flip" anti-pattern.** A statically-typed lib
  where agents must GUESS a signature produces a whole-test-binary compile-wipe. That reads as a
  noisy low pass rate but is NOT real difficulty and reviewers reject it. Pin every new public
  signature/return-type/error-variant shape exactly in `meta.md`, then source real difficulty from
  an orthogonal behavioral surface.
- **A documented public spec has a real ceiling on how hard it can get.** When the spec is public
  and transcribable, the core is too easy and stacking on the core alone will not clear the ceiling.
  Only orthogonal, compounding integration walls the transcriber never reaches drive it down further.

This section is reference data from a smaller, sibling-workspace sample — treat any conflict with
this skill's own `HARDENING.md` arsenal, the Shape Decision Tree above, or the Difficulty Levers
section below as resolved in favor of this skill's guidance, which reflects this workspace's full
corpus and its own measured `failure-patterns.md`.

---

## Agents (costs + availability updated 2026-09-02)

**⚠️ Real per-run costs are 6-8x the old ⚡1/⚡10/⚡25 figures, and availability is rank-gated.** See `CLAUDE.md § Agents` for the authoritative table; mirrored here.

| Agent | Tier | Cost / run | Availability (Iron) | Strengths | Blind Spots |
|---|---|---|---|---|---|
| **Nova** | Olympus (10 runs) | **4 tokens** | LOCKED (temporarily) | Exploration-heavy, compact passing solutions | Thrashing on hard problems → Early Termination, type conversion bypass |
| **Orion** | Olympus, Evaluator (2 runs) | **24 tokens** | AVAILABLE | Decisive commit-and-implement, ~6.5 LOC/msg | When wrong architecture chosen, doesn't pivot |
| **Vega** | Olympus | **32 tokens** | LOCKED until **Gold** | Heavy multi-stage refactoring, 700–975 LOC | O-Composite-extend symmetric refactor, O-Algorithm-coverage |
| **Castor** | Diamond (primary); Olympus also accepts Castor | unknown | LOCKED until **Gold** | Diamond failure-QA target, 1500+ LOC capacity | Bash heredoc hangs on large file writes; type inference too restrictive |

**Batches may MIX agents** — the 10-run gate is not 10 of the same agent. **Design to a pass rate you can afford to measure:** at 24-32 tokens/run, a ~10% design is indistinguishable from 0% (reject) in an affordable batch, so when only expensive agents are unlocked, aim for ~25-35% rather than the low-pass edge. **Only the FIRST batch is full price** — later rounds that touch only `test.patch` / `solution.patch` re-grade via Re-eval at ~30% (10x Orion: 240 tokens down to ~72), so budget for one full batch plus cheap test-side iteration, and settle the description before spending any of it.

**Castor is the primary Diamond agent; Olympus also accepts Castor.** Mars uses Nova+Orion. Olympus uses Nova/Orion/Vega/Castor. Diamond requires 10+ Castor runs at **≤30% pass rate (1-3 of 10)** post-relaunch 2026-05-13. New automated **Diamond Checks** preflight pipeline (50 tokens / 30min-1hr) replaces reviewer green-light. Castor blind spots apply cross-agent to Nova/Orion/Vega — same model family. See `Olympus/Instructions/DIAMOND.md` for full pipeline + staleness rules.

---

## 8-Step Workflow

### Step 0 — Pick Repo

| Criterion | Requirement |
|---|---|
| Stars | ≥500 |
| Activity | ≥1 commit in last 12mo |
| Language | TS/JS/Python/Go/Rust |
| License | MIT, BSD, Apache, Boost, CC-BY (NOT GPL/AGPL) |
| Architecture | Multi-package, behavioral testing through public APIs |

```bash
# ALWAYS clone into worktrees/
git clone <url> worktrees/<repo>
cd worktrees/<repo>
mkdir -p ../../problems/<repo>-<issue>
git rev-parse HEAD > ../../problems/<repo>-<issue>/BASE_COMMIT.txt
```

### Step 1 — Design Phase (HARD GATE — Produce DESIGN.md, NO Code)

Goal: ship in 1 revision round (accept ≤3). Weak design = 3–5 rounds.

**Run 5 phases in order. Stop after DESIGN.md complete.**

#### Phase 1 — Repo Understanding (HARD GATE)
Demonstrate ALL 5 before any candidate:
- ✓ Architecture in ONE paragraph (2-min read)
- ✓ List 5 top-level subsystems + boundaries
- ✓ 3 high-entanglement zones (where features touch many files)
- ✓ Test framework + conventional test file location
- ✓ Cite 1 existing test file as formatting template

If any miss → STOP, read more code.

#### Phase 2 — Existing-PR + Publicly-Solved Check (NON-NEGOTIABLE; #1 reject reason)
Per candidate keyword:
```bash
gh pr list   -R <owner>/<repo> --state all --search "<keyword>"
gh issue list -R <owner>/<repo> --state all --search "<keyword>"
```
ANY PR mentions/solves feature → ABANDON candidate. Document searches run.

**Publicly-solved is a SEPARATE, equally hard reject — not just same-repo PRs.** Read the FULL BODY of every matching issue AND every comment (not just titles), and treat any of these as an immediate abandon, identical in severity to a same-repo PR:
- A maintainer/collaborator comment linking to an EXTERNAL repo/crate that implements the same capability ("there's a license-compatible implementation you can take inspiration from in X", "FWIW, Y has a good implementation of this"). Open the linked file and confirm it actually implements the core algorithm before treating it as safe — don't just note the link exists.
- A community member posting a COMPLETE working code snippet for the exact feature directly in an issue thread, even if never merged as a PR.
- A follow-up bug report showing someone already built and is using the exact capability against the repo's existing primitives (proves the composition works and is known).

`gh issue view <N> --json body,comments` and read every comment body — a title-only search misses all of this. (Real cost: a fully-built, mutation-proofed, Docker-validated Olympus submission was rejected at review for exactly this — two issue comments linking pathfinder + tiny-skia-path reference implementations that a title/PR-only search never surfaced.)

#### Phase 3 — Propose 5–7 Candidates, Pick 1 (HARDENING + TOO-EASY gates, mandatory before picking)

**Always invent original features — do not use an open issue as the binding spec** (an issue can INFORM/validate that a feature class is welcome, but design the specific scope yourself). See `RULES.md § Problem Creation Philosophy`.

Row per candidate:

| Candidate | One-line behavior | Shape | Files mod+new | Raw LOC | Meaningful (raw×0.65) | Predicted Nova | Dominant verdict | Reject? |

**Step A — TOO-EASY.md death-class guard (run on every candidate BEFORE scoring it):**
1. Is the difficulty a single guard/rule applied at many sites (uniform-wrap)? → dead, need a 2nd non-collapsing mechanism.
2. Is it a single-subsystem, fully-specified mechanical transform (inject/rewrite/reindex/validate/reject)? → dead, needs ≥2 hidden-integration walls a single subsystem doesn't have.
3. Does the hardness depend on the spec NOT stating something? → fairness will force stating it, killing the trap. Dead. (The ironcalc/petgraph/kysely law: difficulty-from-misdirection cannot survive full fair specification.)
4. Is it a port of a spec the model has memorized (java.time, stdlib, a popular library, a textbook SQL/CS-101 feature)? → saturated, dead.
5. Can the genuine-difficulty surface survive being FULLY spelled out in meta.md? If NO → dead. If YES (cross-subsystem integration timing, a genuinely-new load-bearing algorithm, an interdependent multi-stage pipeline) → proceed to Step B.

Also check: is the feature POINTWISE-DECOUPLED (independent per-item reductions with no shared state, e.g. "test N items against M independent conditions and combine with boolean logic")? Brute-forceable, ~90-100% pass, dead even if it looks algorithm-flavored. Pick GLOBALLY-COUPLED work instead (a local decision constrained by a whole-structure invariant, shared mutable state, order-dependent composition).

**Step B — HARDENING.md arsenal classification (survivors only):** name which S/A-tier class the lead trap belongs to (`HARDENING.md § 2`):
- S1 speculative-state isolation, S2 composition of documented rules, S3 baseline-preservation through a shared chokepoint, S4 machinery-riding integration, S5 dual-path consistency, S6 two-evaluators — or A-tier (cross-section refactor, orthogonal fair-wall stack, reuse-missing-arm, host-language semantics, naive-dominant-reading, second-op narrow-guard, determination-channel seams, polarity/precedence inversions, exact-fit-passing index arithmetic, numerical-stability orthogonal wall, grammar/parser-generator walls, type-equality-vs-const-eval).
- Verify CONTRACT-STATED/FIX-HIDDEN (`HARDENING.md § 1`): write the meta sentence that makes the trap fair, confirm it does NOT hand the fix. A trap that only works because the spec hides something is not a trap, it's a bug in the description.
- A candidate with no plausible S/A-tier class (only B-tier support levers, or nothing) is not worth authoring — B-tier is a lever, never the main engine.

**Two patterns come FREE with any "derive X from the existing declarations" pick — check both
before looking further: F-24** (the pass needs a total function over a namespace that has missing
keys; agents replace the repo's throw with a sentinel — 8/10 twice) and **F-25** (the pass forces a
deferred placeholder that the public API hands back to callers; agents scope its validity to their
own pass — 4/10 + 4/10). Neither costs a design decision; they are consequences of the pass you are
already asking for.

**Step B-bis — FAILURE-PATTERN TARGETING (`failure-patterns.md` § 1, mandatory):** the arsenal
class in Step B says what KIND of trap it is; this step says whether anyone has ever measured
that kind killing an agent. Name the F-id(s) the candidate targets and check the precondition
with a file:line citation, not a hunch.

- **Lead trap** — pick from F-1…F-19 by what the repo actually gives you (`failure-patterns.md`
  § 5 targeting table). Prefer patterns whose precondition you can confirm from the source tree
  today (F-2, F-3, F-5, F-9) over ones you cannot identify until after a batch (F-1).
- **F-9 is the cheapest source of interdependence.** If the repo has a validating stage and an
  emitting stage in different packages, and the emitter already re-resolves something the
  validator could resolve, one trap breaks every capability at once. Measured 6/10 on neva with
  every failure surfacing as a panic in an unrelated runtime function.
- **F-18 costs one test per position and decides bands.** If the domain has two lexical spellings
  of one concept (line vs block comment, short vs long flag, quote styles), state the equivalence
  in ONE sentence and then test the non-salient form at every position where you test the salient
  one. Measured on gluon: 22 of 37 kills, and the sole failure of the closest near-miss, while the
  line-comment twins of the same positions killed 0-1 each.
- **F-20 costs zero description words and decided the band on go-workflows (8/10).** If your
  feature adds a SIBLING to an existing API (`SelectAll` beside `Select`, batch beside single,
  `try_x` beside `x`) and the sibling gets a rule the original must not have, scope the rule to the
  new API by naming only it, then guard the OLD api's behaviour in BOTH directions. The seam is live
  precisely when the old behaviour is documented in prose but has no repo test, so the agent's own
  green baseline cannot warn them. Verify that gap before counting on it.
- **F-19 is the most durable lever measured, and the cheapest to author.** If the repo's library
  entry point writes to a global output channel (a `println!` logger, a package-level writer) and
  the pick adds a command that must emit STRUCTURED output on that same channel, you get a trap
  that four batches of fairness rounds could not disclose away: 36/52 runs, never below 50%, never
  ruled unfair. Contract-state the OUTPUT ("have the command return this JSON"), never the channel
  discipline. **Assert it from a SUBPROCESS test that parses the whole of stdout** — an in-process
  call to the serializer cannot see the contamination and the trap silently evaporates.
- **F-22 is the pick for any repo with an existing fixed-point resolver.** If the repo already
  iterates to stability over two or more quantity kinds (labels, constants, sizes) and your new
  quantity can depend on them AND they on it, the mixed chains are the trap: a chain through a user
  function, a chain through a constant, a forward reference into a not-yet-placed unit. Measured 8
  of 9 failing runs on customasm-derived-bank-layout and the sole cluster behind both near-misses.
  Direct A-to-B chains discriminate nothing. **Never state an iteration-count or unbounded-length
  promise** - that exact clause was ruled a functional false positive.

- **F-10 is not optional.** If the contract has two form axes (one with multiplicity, one with
  polarity), you MUST test the off-diagonal cell. On neva it was the sole failure of both 20/21
  near-misses and the difference between a 20% and a 40% batch. It costs ~20 test lines and no
  description words.
- **A candidate with exactly one trap is not authorable.** Two traps must sit on different axes
  and at least one must be interdependent with the rest.
- **Discount a differential-harness kill count when the hardening also changed the DESCRIPTION
  (L35).** Replaying old passing patches through a hardened suite counts every agent who never
  read the new sentence; the next batch does read it. On vrp-tsplib an ordering lever killed 3 of
  5 replayed patches and **0 of 10** live agents. Trust the harness for tests-only changes; treat
  it as an upper bound whenever a meta.md sentence moved.
- **A requirement that is simple once stated buys no difficulty, however subtle the wrong version
  looks.** vrp-tsplib stated "returned in ascending node-number order" and tested it at DIMENSION
  12 with permuted input, so a lexicographic sort of the zero-based id STRINGS puts "10" before
  "2". Textbook index-space trap; all 10 agents sorted numerically. If there is only one reasonable
  primitive for the stated rule, stating the rule hands the fix.
- **Do not justify a trap on mutation evidence alone (L15).** A hand-written mutation measures
  what your tests can DETECT; only a batch measures what agents get WRONG. On neva an entire
  subsystem was added across three hardening rounds because it killed a mutation, and it killed
  zero of ten agents.

**Step C — Reject if ANY additional hit:**
- 3+ identical structural examples in repo (pattern-followable)
- Solvable by standalone new file with minimal wiring
- Single-file one-liner <100 LOC
- Cosmetic refactor / doc-only
- Bug in dependency, not project
- Already in `RULES.md § Features already used`
- Predicted Wrong Logic ≥25% (Diamond-grade territory — fine, just name it honestly, don't force a lower estimate)
- Existing PR or publicly-solved (Phase 2)
- Open issue covers as binding spec (inform from it, don't bind to it)
- Outside current sprint floor (≥200 meaningful LOC, ≥2 files)

**Survivor MUST:**
- Named S/A-tier arsenal class from Step B, CONTRACT-STATED/FIX-HIDDEN verified
- Predicted Nova pass ≤40% ceiling
- Touch real subsystem with integration hook — prefer sites where integration is via `if`/`==` checks rather than exhaustive `match` (a missed site is a SILENT wrong result, not a compile error — stronger misdirecting trap than INTEGRATION_ERROR)
- Have 5–13 stated requirements in LOC band

#### Phase 4 — Produce DESIGN.md (14 sections, no extras, no missing)

```markdown
# DESIGN.md — {repo}-{slug}

## 1. Title (verb-led, 5–10 words, names specific subsystem)
Verb from: Fix / Add / Implement / Extend / Iterate / Rewrite / Handle.
Anti-titles: "Bug fix for #1380", "Fix the parser", "How to handle XYZ".

## 2. Shape classification
- Shape:                A1 / A2 / B / C / D-new / D-change
- Definition (cite SHAPES.md § Pattern 11):
- Pass rate target:     {A1=10-15% / A2=20-25% / B=≤30% (was 50-55%; harden) / C=20-25% / D-new=20-25% / D-change=≤30% (was 40-45%; harden)}  — Mars band is ≤30% (0%=reject; >30%=too easy)
- Best agent:           {Nova→Orion / Orion-alone / Mixed}
- Dominant verdict:     {MISSED_REQUIREMENT / REGRESSION / INTEGRATION_ERROR}
- Solver/our LOC ratio: {A1≈2.07× A2≈1.71× B≈1.28× C≈1.02× D-new≈1.44× D-change≈1.07×}

## 3. Public API surface (5–15 names)
Exactly the names tests will assert. One short line of semantics each.
- `name_1(args) -> ReturnType`  — what it does
- `enum_variant_1` / `enum_variant_2` — what they represent
- `error_kind_1` — when raised
"Same as X" forbidden — list every actual name.

## 4. Canonical output form (REQUIRED if tests use assert_eq! on structures)
- Sort order:           {lexicographic / by-X-then-Y / preserves-input-order}
- Associativity:        {right / left / flat}
- Dedup strategy:       {first-occurrence / last-occurrence / none}
- Empty input:          {returns X / errors with msg containing Y}
- Unicode handling:     {as bytes / by codepoint / collation-aware}
- Negative/zero:        {clamp / error containing "Z"}
Each rule = one sentence (validator-hardening style).

## 5. Blind-spot pre-empts (match against 10-entry sentence bank in DESCRIPTION.md)
Quote canonical sentences verbatim. Limit ≤1 codebase-inferable requirement.
Categories: rule-resolution / sort-order / adjacent-vs-all / dedup /
iteration-termination / result-ordering / parallel-API / falsy-on-invalid /
compound-order / pipeline-placement.

## 6. Description draft (meta.md, plain prose)
Word budget by shape:
  A1 ≈107 / A2 ≈137 / B ≈241 / C ≈91 / D-new ≈148 / D-change ≈183. Recommended cap 240 (Mars). Hard cap both tiers: 500.
Body shape:
  A1 → 1 paragraph + dash bullets
  A2 → 1 paragraph with inline numbered rules (1)(2)(3)
  B  → 3 paragraphs (WHAT / behavior / edge cases)
  C  → short dense, ~10 words/rule
  D-new / D-change → 3 paragraphs (variant shape / normalization / supplementary API)

Forbidden: ## headers · formulaic labels · numbered lists · Box<...> wrappers ·
code-instead-of-prose · vague language · test-framework references · external framing.

## 7. File footprint (sketched against real source files)
| Action | Path                | Current LOC | Raw delta | Meaningful (×0.65) | Reason |
|--------|---------------------|-------------|-----------|--------------------|--------|
| MODIFY | path/existing.go    |    XXX      |    +YY    |    YY×0.65         | …      |
| NEW    | path/new_module.go  |    —        |    +YY    |    YY×0.65         | …      |
TOTAL: {raw}/{meaningful} across {N modified + M new} files.

Current floor check (2026-07 sprint, ONE TIER):
  >= 200 effective/meaningful LOC, >= 2 files modified, >= 40 agent messages (solver median)
  Historical shape bands (Mars Entry 100-200/1-3 files, Mars Solid 170-380/1-8, Mars Strong 380-600/6-12,
  D-new exception up to 15 files at 400 raw) are OBSERVATIONAL DATA from older approveds, not gates —
  a design clearing the current floor above should not be rejected for sitting below an old shape's average.

LOC discipline:
  - Sketch 2-3 hardest files in REAL code, NOT file-walk maxima (overshoots 50-75%)
  - Calibration: pest-error-recovery design walked 705 LOC; reality 398 meaningful
  - Design to a comfortable buffer above 200 meaningful (e.g. 300+) so revisions don't dip back under

## 8. Solution outline — pure-function helpers (1+ per behavior)
Every helper maps 1:1 to description sentence. Signature + 2-line description.

helpers:
  - helper_1(...) -> ...   ← description requirement #1
  - helper_2(...) -> ...   ← description requirement #2
  - helper_3(...) -> ...   ← description requirement #3

If shape A2/A1/B with iterative semantics, include fixpoint loop verbatim:
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

Test count anchor (observational): C 39 / A1 68 / A2 92 / D-change 102 / D-new 126 / B 160.

**Decompose per ATOM, not per sentence.** One description sentence usually carries 3-5
independently testable claims, and the negative half is the one everyone forgets. "Tracks the most
recent non-empty value" is TWO atoms: it updates when non-empty, and it does NOT update when empty.
Enumerate atoms explicitly:
  - every symmetric pair — set/reset, apply/rollback, encode/decode, enable/disable
  - every enumerated value, every error variant, every claimed default
  - the NEGATIVE of every positive claim (L25's N-1 fixture is exactly this: the under-threshold
    case is the discriminating one; the at-threshold case passes under both readings)

5-axis coverage check (ALL ✓):
  ✓ Every described ATOM in meta.md (not every sentence — see above)
  ✓ Every public API surface
  ✓ Every solution branch (every if, match arm, early return, recursive case)
  ✓ Standard edge cases (empty / zero / single / boundary / unicode / recursion / null)
  ✓ Stated inverse (if "X happens when Y" matters and isn't symmetric)

## 10. Forced trait bounds / generics / kwargs (test-first discovery)
Sketch test helper signatures BEFORE spec. Walk closures/generics/kwargs they
invoke. Document FORCED bounds. If forced but not obvious → add to §11 + §6.

Examples:
  Rust   — FnOnce vs FnMut vs Fn (recover() trap from pest-error-recovery: 4/10 died)
  TS     — generic narrowing / conditional types
  Python — __init__ kwargs / dataclass fields / default values

## 11. Predicted trap matrix (2–3 named traps, all with mitigations)
| # | Trap | F-id (failure-patterns.md) | Arsenal class (HARDENING.md § 2) | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in §6) | Test that catches it |
|---|------|----------------------------|----------------------------------|------------------|---------------------|-------------------|---------------------------|----------------------|
| 1 | …    | F-9                        | S6                                | …                | #2 (shares the chokepoint) | …        | …                         | …                    |
| 2 | …    | F-10                       | S2                                | …                | —                   | …                 | …                         | …                    |

Rules for this table:
- **Every trap names an F-id** or is a candidate new pattern (say so explicitly — it is a guess until measured).
- **"Axis it measures" must differ between rows.** Two traps on one axis die together the moment review forces a disclosure on that axis (lyon: the named-algorithm trap and its independent-oracle test were mutually exclusive).
- **At least one row must be interdependent with another** — fixing it surfaces or breaks the other. A row whose "Interdependent with" is `—` for every trap means the design is a pile of independent rules, which is L2/L3 dead.
- For each trap, confirm CONTRACT-STATED/FIX-HIDDEN before listing it: write the exact meta.md sentence, then check it does not hand the fix. If it does, the trap is dead — replace it, don't hide the sentence (Rule 7 de-enumeration: state the general principle, never the instance list).

## 11b. Capability cross-product matrix (F-10 — REQUIRED whenever the contract has ≥2 form axes)

List the axes the contract states, then the cells. This is a checklist item, not a design choice.

| | axis-2 value A | axis-2 value B |
|---|---|---|
| **axis-1 value A** | test: … | test: … ← off-diagonal |
| **axis-1 value B** | test: … ← off-diagonal | test: … |

- Typical axis pairs: multiplicity (one/many receivers, single/repeated rounds) × polarity (in/out, sender/receiver-anchored, which side is the boundary).
- **Every off-diagonal cell needs a test.** An empty off-diagonal cell is the single highest-value thing you can add, and it needs no new description words — a contract that states both axes covers their composition.
- Predict the failure mode: composition cells usually fail by OVER-firing (duplicate emission, double application), not by a missing feature, which is what makes them misdirecting.

Scope audit (add to § 11): for every metric the contract names, state whether it is scoped to a
sub-part or to the whole. If the feature is recursive and the contract does not say, that is an
F-11 seam — and a fixture with two consecutive variable sub-parts is the cheapest band lever known.

Example audit (L21): list every EXAMPLE in the meta. An example appended to a general rule is read
as the rule's scope. Keep the rule, delete the example.

Format-noun audit (L24, add to § 11): list every noun in the meta that names a UNIT OF THE FORMAT
(record, entry, block, section, group, rule). For each, state its EXTENT explicitly — does it mean
the header alone, or the header plus its amendment rows? Agents read these in the natural-language
sense, which is always the smaller, more local one. On rust-minidump "a single record ... is
discarded" cost 6 of 10 runs because agents discarded the ROW. If the extent matters, either say it
or make the noun unambiguous.

Tolerance-fixture audit (L25): for every "allow one, stop at the second" rule, confirm you have the
**N-1 fixture** asserting nothing happened, not just the N fixture. The N fixture passes under both
the correct reading and the stop-at-first reading; on rust-minidump it killed zero while the N-1
fixture killed 4.

Wrong Logic % constraint: <25%. ≥25% → Olympus territory. Downgrade trap or upgrade tier.

## 12. Tier + category decision
- Tier:     Olympus (one tier — Mars merged in 2026-07; historical Solid/Strong sub-rank kept as shape-precedent label only)
- Sub-rank: Okay / Good / Excellent (historical Entry/Solid/Strong labels from the merged Mars tier still usable as shape precedent)
- Category at submit time:
    enhancement     — modifying existing function/pass/subsystem ("Rewrite…", "Extend the existing…")
    feature-request — net-new (new public type/API/config) ("Add…", "Introduce…")
- Pick honest category. Mismatch = automatic FAIL.

## 13. Predicted Nova pass rate
- Predicted: N% – M%
- Reasoning: shape band + difficulty levers used (precision wording / file count /
  interacting requirements / cross-subsystem integration / near-miss tests /
  codebase-inferable hint 0–1 max)
- Sanity check: current sprint ceiling ≤40% (0%=reject; >40%=too easy). If predicted >40%, add an interdependent+misdirecting trap; if 0%, redesign the traps or route to Diamond.

## 14. Quality-gate checklist (ALL ✓ required to exit Design)
- [ ] Repo understanding: 5/5 in Phase 1
- [ ] Existing PR check: 0 hits in Phase 2 (paste search commands)
- [ ] Closest approved problem opened side-by-side as scaffolding
- [ ] Title: verb-led, 5-10 words, names specific subsystem
- [ ] Shape declared with SHAPES.md § Pattern 11 citation
- [ ] Public API surface lists every name tests will assert (no "same as X")
- [ ] Canonical output form spelled out (sort, associativity, dedup, empty, unicode, negative)
- [ ] 0–1 codebase-inferable requirements
- [ ] Description draft: word count ≤200 recommended, hard cap 500 (Mars-shape word bands below are historical precedent, not a gate)
- [ ] Description draft: no ## headers, no formulaic labels, no Box<>, no code-prose
- [ ] File footprint sketched against REAL source files
- [ ] Raw and meaningful LOC clear the current floor: **>=200 meaningful/effective LOC, >=2 files** (design to a buffer above 200, e.g. 300+)
- [ ] Solution outline: 1+ pure-function helper per description sentence
- [ ] Fixpoint loop / cycle-trace pattern included if applicable
- [ ] Test file outline: 4-block layout, scenario-encoded test names
- [ ] 5-axis test coverage planned
- [ ] Forced trait bounds / kwargs documented
- [ ] 2–3 named traps each with pre-empt sentence + catching test
- [ ] Every trap names an F-id from `failure-patterns.md` (or is flagged as an unmeasured guess)
- [ ] Traps sit on DIFFERENT axes, and at least one is interdependent with another
- [ ] § 11b cross-product matrix filled in, every off-diagonal cell has a test (F-10)
- [ ] **Sibling-API audit (F-20): does this feature add a variant of an existing entry point? If
      so, name the new rule's scope by naming ONLY the new API, and add a test of the OLD api in
      both directions. Confirm the base suite passes with the old behaviour broken — if it fails,
      the seam is already guarded and F-20 is unavailable.**
- [ ] **Unobservable-interface audit (F-21): does any rule quantify over the OUTCOME of an object
      the caller supplies through an interface? Grep that interface for an accessor. If there is
      none, add the "whatever `X` the caller supplies" clause and ONE fixture using a conforming
      implementation outside the repo's `Abstract*` base.**
- [ ] **Absent-key audit (F-24): does the feature add a pass over a namespace the caller fills?
      Find the resolver's missing-key throw, DELETE it and run the base suite — if the suite still
      passes, the seam is live. State the semantic distinction in one clause and test both the bare
      unregistered reference and one under a REQUIRED field.**
- [ ] **Placeholder-lifetime audit (F-25): does the feature force a deferred handle, and can the
      caller store it? Gate its resolution on whether the DATA exists, never on a phase flag (L51),
      and test a retained reference reused in a later registration plus one that closes a cycle.**
- [ ] **Reference-bug harvest (L50): list every defect a reviewer found in YOUR reference and ask
      of each whether a test would discriminate. Each one that got a test on dfu-derived-recursion
      became a measured killer (4, 4 and 3 of 10). Replay against the saved passers first (L40).**
- [ ] **Wrapper-domain audit (F-23/L47): does any clause say "a number or a callable" / "a value or
      a provider"? Find the repo container agents will reach for, read its validation, and list the
      spellings it REFUSES. Parametrise the tests by what that validator distinguishes, not by what
      looks varied to a reader — on rocketpy only 2 of 7 callable spellings killed anything.
      Confirm your own reference does NOT delegate to that container.**
- [ ] **Representation-pin sweep (L48/L49): for every assertion on a value the feature returns, ask
      whether meta.md states its TYPE or only its VALUE. Read it through a tolerant helper wherever
      only the value is stated. This is FP-panel armour — an adjudicator cited exactly such a helper
      to reject a dissenting judge's false-positive probe — and on rocketpy it was worth the entire
      band: the same ten solutions read 0/10 with the pin and 1/10 without it.**
- [ ] **Unbounded-promise audit (L44/L45): does any sentence promise a bound on iterations, passes,
      or chain LENGTH? If so, cut it to the capability ("a bank may be placed at the end of a bank
      defined later") — an unbounded performance promise is a false-positive generator, because a
      passer that is correct at every tested size fails it at some larger one.**
- [ ] **Stated-noun list (L46): write down every noun meta.md actually names. Any fixture whose
      subject is NOT on that list is a gate on unstated behaviour — fix the reference instead.**
- [ ] **Form-parity audit (F-18): if the domain has two lexical spellings of one concept, every
      position tested for the salient form is also tested for the other**
- [ ] Format-noun extents stated for every record/entry/block/section the meta names (L24)
- [ ] Every tolerance rule has its N-1 fixture asserting nothing happened (L25)
- [ ] Predicted Wrong Logic <25% (else this is genuinely Diamond-grade difficulty, not a tier upgrade — one tier now)
- [ ] Predicted Nova pass rate <=40% ceiling (current sprint)
- [ ] Category matches the description (enhancement vs feature-request)
- [ ] Feature is NOT pattern-followable
- [ ] Feature is NOT in RULES § Features already used
```

#### Phase 5 — Failure-Mode Self-Audit (before declaring done)

Walk `PLAYBOOK § Pattern 8` (5 revision buckets), answer each:
- Bucket 1 — Hidden requirements? Any test in §9 not covered by sentence in §6? → fix §6
- Bucket 2 — Tech-spec tone? §6 has `##` heading or formulaic label? → rewrite plain prose
- Bucket 3 — Tests pass on base? §9 has test not using new API? → remove or redesign
- Bucket 4 — Tests over-constrain? §9 asserts internal-only behavior agents can't infer? → loosen or hint in §6
- Bucket 5 — Solution under 200 LOC, problem too easy? §7 raw <170? → expand scope (parallel API, additional edge case dimension), don't pad

Walk `RULES § Real Revert Causes` — confirm none apply:
hidden requirements / test.sh trickery / redundant tests / exact-string assertions /
code duplication / scope creep / regression-on-base / AI-generated comments /
weak assertions / wrong package / dead code / missing validation / ambiguous bounds /
flaky tests / pre-existing test passes / vacuously true assertions

Walk `AGENTS § Confirmed Blind Spots` — confirm any that apply have a §5 pre-empt:
specific examples override general / type inference too restrictive /
initializing = default constructor / cross-feature ordering / reference vs deep copy /
AST traversal default bottom-up / rule resolution skipped / unstated inverse / default ordering

#### Output

Write `DESIGN.md` in problem folder with all 14 sections. Append:
- "Why this is not a duplicate" — cite closest 1–2 approved Mars problems + differentiator
- "Predicted iteration cycles: N" (target 1, accept ≤3)

**STOP after DESIGN.md complete. NO code, tests, or Dockerfile yet.** DESIGN.md is sole deliverable of this phase.

### Step 2 — Dockerfile

**May 2026 admin update — slim language-specific images preferred for ALL new submissions:**

| Image | Language |
|---|---|
| `public.ecr.aws/d3j8x8q7/olympus-base-python:latest` | Python |
| `public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest` | TS / JS |
| `public.ecr.aws/d3j8x8q7/olympus-base-go:latest` | Go |
| `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` | Rust (replaces mars-base for new subs) |
| ~~`public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`~~ | ⚠️ **UNSUPPORTED as of 2026-05-14** |
| ~~`public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest`~~ | ⚠️ **UNSUPPORTED as of 2026-05-14** |

⚠️ Java/JVM + C/C++ UNSUPPORTED as of 2026-05-14 — do not pick repos in these languages. Historical guide (reference only): <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit>. Legacy generic `olympus-base` / `mars-base` only for re-verifying historical submissions.

**Pattern A (Rust, `olympus-base-rust`) — CANONICAL. Copy verbatim.**

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch && cargo build --workspace
CMD ["/bin/bash"]
```

**NO `ENV` block. NO `chmod`. NO symlink loop. NO `--tests` / `--all-targets`.** Each of those is a
separately measured failure, not a style preference:

- **`ENV RUSTUP_HOME=/root/.rustup` BREAKS THE IMAGE BUILD** (measured, comrak 2026-08-05):
  `error: rustup could not choose a version of cargo to run, because one wasn't specified
  explicitly, and no default is configured`. The base image keeps its toolchain somewhere else, so
  overriding `RUSTUP_HOME` points rustup at an empty directory. Inherit the image's environment.
- **`chmod -R a+rX /root` breaks SOLVE TIME, not build time** — it leaves the fetched registry
  root-owned and defeats the platform's user remap, so the agent gets `Permission denied` on
  `/root/.cargo/registry/...` and cannot run cargo at all (nickel-enum-widening R1: 0/10).
- **No `cargo2junit` = hard revert**, hit twice (nickel-1336, piccolo). A clean batch does not save
  it. The bash-regex reporter also miscounts across multiple test binaries.
- **`--tests` / `--all-targets` fails the image build.** The image is built with `test.patch`
  applied and `solution.patch` NOT applied, so compiling the new tests is guaranteed to fail
  (measured on comrak: 4 errors with `--tests`, 0 with `--workspace`). `--all-targets` additionally
  drags in benches, which commonly need nightly (`#![feature(test)]`).

`cargo install cargo2junit` lands the binary in `/root/.cargo/bin`, which is exactly the directory
`test.sh` prepends to `PATH` — no chmod or symlink is needed to reach it.

**Verify statically when local Docker is unavailable:** run the image's RUN command's cargo half
against the tree the platform actually builds (base + `test.patch`, no solution), not against your
finished working tree. That one check catches the `--tests` class.

**Pattern B (Python/JS/Go only — ⚠️ C++/Java UNSUPPORTED 2026-05-14):**
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-{lang}:latest
WORKDIR /app
COPY . .
RUN {install_command}
CMD ["/bin/bash"]
```

Replace `{lang}` with `python` / `typescript` / `go`. ⚠️ `cpp` + `jvm` UNSUPPORTED as of 2026-05-14.

Verify offline: `docker run --rm --network none --user 1000:1000 -v /tmp/out:/out img bash -c "/app/test.sh --output_path /out/base.xml base"` then `grep -c '<testcase' /tmp/out/base.xml` > 1.

### Step 3 — Tests + test.sh

**4-block layout (Rust):** imports → builder helpers (10–30 one-liners) → assertion helpers → granular `#[test]` functions.

**Coverage axes (count-agnostic):**
1. Every described behavior in meta.md
2. Every public API surface
3. Every solution branch
4. Standard edge cases (empty/zero/single/boundary/unicode/recursion/null)
5. Stated inverse if asymmetric

**Naming:** scenario-encoded snake_case — `range_z_to_a_errors`, `dedup_two_class_is`, `fixpoint_three_way_prefix_folds_completely`.

**Assertions:**
- Strong: `assert_eq!` on tree/list/string outputs; `expect_error(input, "alternative")` substring-match for errors
- Weak (flagged): `is_ok()`, `length > 0`, `toBeDefined()`, exact full-message error match

**test.sh requirements:**
- `#!/usr/bin/env bash` + `set -uo pipefail`
- Position-independent arg parsing (case loop, not `$1` for mode)
- Accepts `--output_path <path>`
- `base` mode runs ALL existing tests; `new` mode runs ONLY new test files
- Produces JUnit XML
- **Build-failure fallback (Rust) — non-negotiable.** Without it, cargo crash → empty XML → "No test suite results were found."
- **Executable bit (mode `100755`) — non-negotiable.** Platform invokes `./test.sh` directly. The patch MUST contain `new file mode 100755` for test.sh, NOT `100644`. On Windows `chmod +x` does NOT update the git index — use `git add --chmod=+x test.sh` BEFORE generating the diff. Verify with `grep "new file mode" test.patch`.

JUnit by language:
- Python: `pytest --junitxml="$OUTPUT_PATH"`
- Go: `go test -v ... 2>&1 | go-junit-report > "$OUTPUT_PATH"` (install `go-junit-report` in Dockerfile)
- TS vitest: `vitest run --reporter=junit --outputFile="$OUTPUT_PATH"`
- TS bun: `bun test --reporter=junit 2>"$OUTPUT_PATH"`
- Rust: bash-regex `run_and_produce_junit` from `Olympus/Instructions/TESTS.md § Rust — Mars-Approved bash-regex`
- Deno: `deno test --junit-path="$OUTPUT_PATH"` + new-mode fallback if XML has 0 testcases

### Step 4 — Solution

Match repo style exactly (naming, patterns, error handling, comment convention — NOT blanket ban).

**Universal patterns:**
- Pure-function helpers extracted (1+ per behavior the description names)
- Fixpoint loops: `loop { … if !changed { break; } }` when description says "iterate"
- Cycle-trace pattern for recursive AST traversal

**Forbidden:**
- `// TODO`, `// FIXME`, `// NOTE`, `// Step N:`, `// CATEGORY N:` markers
- `println!`, `eprintln!`, `dbg!`, `console.log`, `print()`, `fmt.Println`
- Commented-out alternatives
- Speculative defensive guards
- Drive-by refactors of unrelated files
- Breaking existing function signatures (use overload / new method)
- AI slop (verbose boilerplate)

**Tier LOC (current sprint, one tier):**
- **≥200 effective/meaningful LOC** (Counter 2 / human-effective), **≥2 files** — down from 450/400 floor + 3-file floor. Design to a comfortable buffer above 200 (e.g. 300+) so revisions don't dip back under.
- Auto-reviewer Counter 1 formula = raw added − blank − comment-only (BRACES KEPT, comments NOT counted; cel-go `575−48−160=367`) is a looser by-product that clears once the human-effective Counter 2 clears 200 — never design to Counter 1.
- Comments are dead weight for the counter either way.
- Diamond: same floor, Castor-targeted, NO upper LOC ceiling.
- Historical Mars 170-380/Olympus 600+/8-35-files bands are observational precedent from specific approved problems, not gates.

### Step 4b — CORE-SLICE PRECHECK (HARD GATE — do this BEFORE any differentiating scope)

**Stop as soon as the minimal end-to-end version of the capability compiles and passes a handful of
tests. Upload that slice to the platform and read the dedupe verdict BEFORE writing the
cross-product cells, the edge cases, the integrations, or anything else added to clear the LOC
floor.**

Precheck is FREE and the dedupe matches on the **CORE**, not on the total. Every line of
differentiating scope written before this gate is spent on an artifact that may already be dead,
and none of it can save a colliding core: the standard rejection sentence is *"elaborating that
engine with integrations and edge cases does not restore exclusivity."*

**Why this is a gate and not advice — it has now failed three times in a row:**

| Pick | Cost | Verdict |
|---|---|---|
| scikit-fem-embedded-meshes (2026-09-10) | full authoring + Docker validation | dedupe `derivative` 0.79 / 0.90 conf |
| koto-nested-bindings (2026-09-10) | full authoring, no batch | overlap `Blocker`, 258/489 = 52.8% |
| dropflow-min-max-sizing (2026-09-11) | full authoring + submit-time audit round, no batch | overlap `Blocker`, 204/290 = 70.3% |

All three had a genuinely clean SIX-CHECK. **That is the point:** a rival author's submission lives
only inside the platform pipeline and is invisible to every GitHub query you can run — canonical-org
PR search, issue search, maintainer-philosophy scan, base..HEAD commit diff, side-branch compare.
None of them can see it. The platform precheck is the ONLY instrument that can.

**Run this gate unconditionally, and treat it as mandatory when ANY of these hold:**
- the capability is named by the standard/spec the repo exists to implement (a CSS property, an SQL
  clause, a language pattern form, an opcode);
- the repo publishes a support/conformance matrix and your pick is one of its incomplete rows
  (see `TOO-EASY.md § Repo publishes a support matrix` — a "Planned" row is a collision tell, NOT
  maintainer permission);
- the lane is maintainer-invited, cold, and PR-free (the signals that rank a lane first for you rank
  it first for every rival too);
- you need a second feature bolted on to clear the LOC floor.

A colliding core is not contestable on quality, difficulty, LOC, pass-rate or FP-cleanliness. Shelve
per `CLAUDE.md § HARD RULE — Too-Easy / Trivial Shelving` and record the lane in
`SATURATED-REPOS.md`.

### Step 5 — Description (meta.md)

**FIRST: the required YAML frontmatter block, before the `#` title.** Carries submission
metadata so it is never hunted for at submit time. Convention across the approved set (calyx,
neva, pulldown-cmark). Full rules: `Instructions/DESCRIPTION.md § REQUIRED — the YAML
frontmatter block`.

```markdown
---
Repository: https://github.com/<owner>/<repo>
Issue: <full issue URL, or N/A when the feature is invented>
Commit: <40-char BASE_COMMIT hash, byte-identical to BASE_COMMIT.txt>
Language: <Rust | Go | Python | TypeScript>
Category: <feature-request | enhancement>
Title: <same text as the H1 below>
---
```

`Commit` must be COPIED from `BASE_COMMIT.txt`, never retyped. `Issue: N/A` is the normal case
(features are invented, not taken from trackers). `Category` must match the title's verb —
Add/Implement/Support = feature-request, Fix/Handle/Rewrite = enhancement; a mismatch is an
automatic FAIL. The block is metadata: excluded from the word budget, and the no-headers rule
applies only to the body beneath it.

Then the body:

- Title: `# <Action verb> <subsystem>` — Fix/Add/Implement/Extend/Iterate/Rewrite, 5–10 words
- **First sentence of the body states the ask** — `Add <capability> to <subsystem>.` Reviewers grade the DESCRIPTION, not the title, and the title is often not shown beside it, so an opening that narrates current behavior reads as a bug report. Put the current state in the SECOND sentence. Verb matches the honest category (Add/Implement/Extend/Support = feature-request; Fix/Handle/Rewrite = enhancement). Do not restate the title verbatim. Full rule: `Olympus/Instructions/DESCRIPTION.md § HARD RULE — The FIRST SENTENCE of the body`
- Body: 2–6 plain-prose paragraphs, NO `##` headers, NO formulaic labels (`Problem Description:`, `Test Assumptions:`)
- Recommended cap: 200 words. **Hard cap: 500.** Historical per-shape word bands (C ~91, A1 ~107, A2 ~137, D-new ~148, D-change ~183, B ~241) are precedent, not a gate.
- Backticks ONLY for new public API names (not internal types, no `Box<...>` wrappers)
- No code-instead-of-prose ("the rate is a decimal number," not `(float64)`)
- Spell out canonical form (sort order, associativity, dedup) when tests use `assert_eq!` on structures
- Apply blind-spot pre-empt sentences (see `Olympus/Instructions/DESCRIPTION.md § Blind-Spot Pre-Empt Sentence Bank`)
- Every test traces to description; every described behavior has a test; ≤1 codebase-inferable requirement

### Step 6 — Generate Patches

```bash
BASE_COMMIT=$(cat problems/<repo>-<issue>/BASE_COMMIT.txt)

# test.patch (test.sh + new test files)
chmod +x test.sh                                    # filesystem bit
git add --chmod=+x test.sh                          # index mode 100755 (CRITICAL — see below)
git add test/<feature_test>
git diff --cached $BASE_COMMIT -- test.sh test/<feature_test> > problems/<repo>-<issue>/test.patch

# solution.patch (source files only)
git diff $BASE_COMMIT -- src/file1 src/file2 > problems/<repo>-<issue>/solution.patch

# For new untracked source files
git add src/new_module
git diff --cached $BASE_COMMIT -- src/new_module >> problems/<repo>-<issue>/solution.patch
```

**Never:** `git diff HEAD`, `git diff origin/main`, bare `git diff $BASE_COMMIT` (no file paths = everything).

**test.sh executable bit CRITICAL:** Platform invokes `./test.sh --output_path <path> base|new` directly. If test.sh ships as mode `100644`, the run dies with "Permission denied" before any test runs. On Windows `chmod +x` does NOT update the git index — `git add --chmod=+x test.sh` is required. Verify after generation:

```bash
grep "new file mode" problems/<repo>-<issue>/test.patch
# Must show: new file mode 100755 (for test.sh)
```

If it shows `100644` for test.sh, fix immediately and regenerate.

**Windows UTF-16 CRITICAL:** Patches as UTF-16LE BOM silently fail `git apply`. Use `patch_gen.py` (repo root) or generate via Python `subprocess` with `text=True, newline='\n'`. Verify: `file solution.patch` says "ASCII text".

**Validate both orders:**
```bash
git checkout $BASE_COMMIT && git clean -fd
git apply test.patch
./test.sh --output_path /tmp/base.xml base   # PASS
./test.sh --output_path /tmp/new.xml new     # FAIL
git apply solution.patch
./test.sh base                                # PASS (no regressions)
./test.sh new                                 # PASS

# Reverse
git checkout $BASE_COMMIT && git clean -fd
git apply solution.patch
git apply test.patch
./test.sh base && ./test.sh new               # both PASS
```

### Step 7 — Run Checks + Iterate

Layered checks:
1. Artifact (5 files, Dockerfile builds, base PASS, new FAIL-on-base, JUnit XML valid) — 0–1 rounds
2. Description quality AI review — 1–3 rounds (HIGH blocks; MEDIUM/LOW advisory)
3. Tests quality AI review — 1–2 rounds
4. Alignment check (every test → description requirement)
5. Nova empirical (≥10 for Mars) — pass rate must land in tier band
6. Orion coverage (≥2 for Mars)

Mars: 1–3 rounds. Olympus: 3–5 rounds. >5 on Mars = playbook patterns not followed (see `PLAYBOOK.md § Pattern 8`).

**Fix ALL SOLVER-VISIBLE issues in one pass before running a batch** — `meta.md`, title, Dockerfile, base commit. Those edits invalidate the agents' solving work, so redoing them costs a full fresh batch. Test-side and reference-side fixes do not: since 2026-09-03 a `test.patch` / `solution.patch` edit stales the batch but keeps the solving valid, and the platform offers **Re-eval** (grading + evaluation only, over the last batch's solutions, ~30% of batch price). Never fire a smoke run while a re-eval is pending, since any fresh run dismisses the offer. Re-eval is paired on one fixed solution set: steer with it, confirm the submitted number with a fresh batch. See `CLAUDE.md § RULE UPDATE 2026-09-03` and `failure-patterns.md § L36`.

---

## Mandatory Workflow Rules

### Tracking from Day One
- `feedback.md` — high-level summary, iteration tracking, fix history
- `eval-results.md` — per-agent table (agent, evaluator, verdict, msg count, files, LOC, failed tests, failure reason)

### After Every Eval Run
1. Update `feedback.md` (high-level summary in attempt history)
2. Update `eval-results.md` (full per-agent table)

### After Approval (CONFIRMED human reviewer only)
1. Add per-problem section to `Olympus/Instructions/PROBLEM-PROFILES.md` (behavioral data + iteration lessons)
2. Update `Olympus/Instructions/KNOWLEDGE.md` → Agent Behavioral Profiles only if NEW cross-agent blind spot discovered
3. Update `Olympus/Instructions/lessons-learned.md` only if NEW cross-cutting iteration lesson (description/tests/patches/reviewer/solution/language general)
4. Update `Olympus/Instructions/PATTERNS-ADVANCED.md` if new evidence-based pattern emerged (numbered Pattern 34+)

---

## Confirmed Cross-Agent Blind Spots — Pre-Empt in meta.md

| Blind Spot | Approved sentence |
|---|---|
| Rule-reference resolution | "Resolve rule references through the grammar's rule map when checking …" (factorizer) |
| Sort order ambiguity | "Order Literal values lexicographically, then CaseInsensitive values by ASCII lowercase, then CharRange values by start codepoint" (extended-skip) |
| Adjacent vs all-positions | "working on adjacent positions only so author-supplied alternative ordering is preserved" (lightningcss) |
| First/last-occurrence dedup | "deduplicated using ASCII case-insensitive comparison, keeping the first occurrence" (extended-skip) |
| Iteration termination | "iterates until no rewrites apply" / "iterate to a fixpoint" |
| Result list ordering | "Results preserve the order rules appear in `rules`" (unused-rule-elim) |
| Parallel optimized API | "Parallel `find_unused_optimized_rules` operates on `&[OptimizedRule]` with the same semantics" |
| Falsy-on-invalid | "Returns false for undefined names or empty input" |
| Compound order preservation | "Compound-selector component order is preserved exactly: `.x:is(.a)` stays `.x:is(.a)`" |
| Pipeline placement | "normalize grammar rule expressions (Expr) before they are converted to optimized expressions" |

---

## Difficulty Levers (ranked by MEASURED impact — see `failure-patterns.md`)

1. **A convergent-architecture wall (F-1)** — the largest single lever measured: +27 points on
   pulldown (67% → 40%). Cannot be identified before a batch; you have to read the passing patches.
2. **Sibling-API contamination (F-20)** — **8/10 on go-workflows, and the sole failure of BOTH
   near-misses**, so it moved the batch from 40% to 20% on its own. Agents refactor the new and old
   entry points onto a shared path and leak the new rule onto the old API. Requires an existing
   public behaviour that is documented but untested; costs zero description words and ~40 test lines.
3. **An absent-key sentinel replacing an existing hard failure (F-24)** — **8/10 in TWO
   independent batches on dfu-derived-recursion**, and the SOLE failure of four 85/87 near-misses.
   Any feature that adds an analysis pass over a caller-populated namespace creates it for free:
   agents invent `UnknownType`/`MissingRef` to keep the pass total, and a lookup that used to throw
   now succeeds. Needs a resolver whose throw the repo's own suite does not cover. Costs ONE clause
   naming the semantic difference — never "keep throwing", never the exception name. The most
   reproducible lever measured: same 8/10, four levers apart.
4. **A shared-helper side effect on the output channel (F-19)** — **36/52 runs across 4 batches
   (69%), the most DURABLE lever measured**: it survived three fairness rounds, a Verify Solution
   round and an FP panel without ever being ruled unfair, and never dropped below 50%. Needs a
   library entry point writing to a global channel plus a new command emitting structured output
   there. Its durability comes from the fix living in a dependency the agent was RIGHT to pick, so
   disclosing the contract does not disclose the fix. Assert from a subprocess test.
5. **A cross-stage resolution drop (F-9)** — 6/10 on neva, and the cheapest source of
   INTERDEPENDENCE: one root cause breaks every capability at once, so you get stacking without
   bolting on a second mechanism.
6. **A token-form parity cell (F-18)** — one rule, two lexical spellings. 22 of 37 kills on gluon
   for one test per position and no new description words.
7. **A capability cross-product cell (F-10)** — the band decider. On neva it was the sole failure
   of both 20/21 near-misses; without it the batch reads 40% instead of 20%. ~20 test lines,
   zero description words. Ship it in every problem that has two axes.
8. **A repo-idiomatic wrapper that narrows your stated input domain (F-23)** — **6/10 on
   rocketpy, reproducible across two batches AND two solver families (Nova and Orion both fell to
   it).** State a broad contract ("a number or a callable receiving X"), then rely on the repo's own
   pervasive scalar-or-callable container being STRICTER than that sentence: agents delegate
   validation to it and inherit its narrower domain, and the exception surfaces from a base-repo
   file they never touched. Zero description words, ~30 test lines. **Budget it as BINARY** — every
   failing run failed every killing cell, so the measured counterfactual for softening it was
   0/10 -> 56%, over the ceiling. It has no middle setting.
9. **Type-check shortcut for an unobservable interface (F-21)** — **5/10 on datafixerupper, the
   top killer and the SOLE failure of the closest near-miss (172/173).** When your rule quantifies
   over the outcome of an object reached through an interface with no accessor, agents downcast to
   the repo's own abstract base to read the field. State the rule over the INTERFACE with a
   four-word concessive clause ("whatever `X` the caller supplies") and put ONE fixture on a
   conforming implementation OUTSIDE that base class. Costs a ~30-line test helper and zero
   description words. Grep the interface for a getter first — if one exists, the honest
   implementation is a one-liner and the pattern is dead.
10. **Proxy-metric drift (F-17)** — **8/10 on lyon-fill-internal-vertices, the top killer and the
   sole failure of both near-misses.** Write every test helper in the CONTRACT's vocabulary, not the
   cheapest structural one. When the contract says something geometric/semantic and your helper
   computes something topological/syntactic, author and agent adopt the same wrong abstraction and
   the suite is blind to the exact gap it exists to measure. Verify the direct check reports zero
   false hits against your own reference before shipping it.
11. **Discard-unit granularity (F-13)** — **6/10 on rust-minidump, the top killer measured on that
   problem**, and 3 of the 6 were sole-failure near-misses at 48/49. Needs a two-tier format (base
   declaration + amendment rows) and a validity rule an amendment alone can break. State the rule
   with the FORMAT's noun and put the violation in an amendment row.
12. **Arming-vs-firing condition (F-15)** — 4/10 on rust-minidump. Any "allow one, stop at the
   second" rule. **The discriminating fixture is the ONE-event case** asserting nothing happened;
   the two-event case passes under both readings and killed zero (L25).
13. **Declared-vs-derived terminal state (F-14)** — 3/10 on rust-minidump. Add a stop reason that
   means "someone declared it" to a subsystem that already has several "cannot continue" exits.
   Couple the output rule to the ORDINARY state so a merged implementation breaks output too.
14. **Precision wording** — 52% of failures are MISSED_REQUIREMENT. "subjects" vs "commits",
   "unbounded" vs "non-aggregated", "map_top_down" vs "map_bottom_up".
15. **A joint fixed point across quantity kinds (F-22)** — 8 of 9 failing runs on
   customasm-derived-bank-layout, and the whole of both near-misses. Free interdependence: one root
   cause breaks every capability that routes through the other kinds. Needs an existing
   iterate-to-stability resolver in the repo.
16. **File count** — more files = more exploration = more messages and LOC. Note this moves SCOPE
   and payout, not pass rate.
17. **Interacting requirements** — 10+ at Olympus Good, 15+ at Excellent.
18. **Codebase-inferable requirement** (0–1 max — visible in code, not description).

- **Placeholder validity window narrower than the caller's (F-25)** — **4/10 + 4/10 on
  dfu-derived-recursion**, in the same batch as F-24 and free alongside it: the pass that creates
  the sentinel pressure is the pass that forces a deferred handle. Agents gate the placeholder on
  their own analysis phase, so a reference the CALLER retained across the boundary throws or binds
  to the wrong scope. Test a retained reference reused in a LATER registration and one that closes
  a cycle; take the reference AFTER its target is registered, or the test demands an unstated
  forward lookup and reads as unfair.
- **Unparameterised-setter inference gap (F-16)** — 4/10, but it is a COMPILE error that measures no
  understanding of the feature. Bonus only, never the lead trap, and only where the repo already has
  a boolean `with_*` setter making the shape inferable.

**What does NOT move the pass rate, measured:**

- **More instances of an already-covered axis.** neva's round-8 slot-identity tests killed 6 runs
  but always co-occurring with the lead trap — zero independent kills, zero outcome change.
- **A trap justified by mutation evidence alone (L15).** neva added a whole runtime subsystem over
  three rounds because it killed a hand-written mutation; it killed 0 of 10 agents. Mutations
  measure what your tests DETECT (that is FP insurance, and worth having); only a batch measures
  what agents get WRONG.
- **A baseline-preservation axis, on its own.** rust-minidump spent two rounds legitimising a
  conditional-output contract because emitting the fields unconditionally reds 11 existing tests.
  The batch produced **0 baseline failures in 10/10 runs** — every agent got it right. Keep it for
  fairness (an unstated preservation requirement IS unfair), but do not count it as difficulty.
- **LOC.** A 900-LOC uniform wrap is still a uniform wrap.

**If agents pass too easily:** do NOT reach for more rules or more wording. In order —
(a) fill an empty off-diagonal cell in the § 11b matrix (F-10), (b) look for what the convergent
architecture structurally cannot do (F-1), (c) only then expand scope.

**Take every reviewer coverage suggestion (L17/L22).** A fairness gap is by definition a behaviour
the contract states and nothing tests, which is exactly where an agent can be wrong for free. On
neva the decisive test came from a Test Fairness coverage suggestion. On customasm it came from an
FP-panel dissent and then killed 9/10. On rust-minidump the top TWO killers (6/10 and 4/10) were
both written in review response, in rounds 25 and 26 of 28 — 40 of the 49 tests killed nothing, and
the ones that mattered came from reviewers. **Budget late review rounds as difficulty work, not as
compliance overhead.**

**Wrong Logic ≥25% signals subtle algorithmic trap (O-Algorithm shapes). Hardest problems sit at 0–10% pass rate.**

---

## Pre-Submit Checklist (Composite)

### Repository state
- [ ] BASE_COMMIT.txt exists (40-char hash)
- [ ] `./test.sh --output_path /tmp/base.xml base` PASSES (after solution applied)
- [ ] `./test.sh --output_path /tmp/new.xml new` PASSES (after solution applied)
- [ ] JUnit XML has `<testcase>` count > 1 in both modes

### Tests
- [ ] New tests FAIL on base for the right reason (missing feature, not import error)
- [ ] New tests PASS after solution
- [ ] Base tests PASS always (no regressions)
- [ ] **MANDATORY flakiness gate** — full suite (base + new) run 3-5x; pass/fail deterministic + identical every run. No timing/ordering (map/set iteration, parallel races)/unseeded-RNG/network/clock/FS-time/resource-contention dependence. Flaky baseline OR flaky new test = reject (if baseline known-flaky, scope base mode to solution-relevant tests + document). See `TESTS.md § Avoiding Flaky Tests`.
- [ ] test.sh is executable (mode 100755 in patch)
- [ ] test.sh accepts `--output_path`, position-independent
- [ ] Build-failure fallback present (Rust)
- [ ] No `//` comments inside test bodies (unless repo convention)
- [ ] Tests run offline (`--network none`)
- [ ] Coverage complete: every behavior, every public API, every branch, every edge case
- [ ] **Test file names use random hex suffix** (`openssl rand -hex 3`) — NO `shipd` / `datacurve` substrings. Verify: `grep -rEl "shipd\|datacurve" tests/ test.sh` returns nothing.
- [ ] **Diamond only — solution-approach.md REQUIRED** (200-500 words, 1 dense paragraph OR 3 paragraphs max). Implementation walkthrough (HOW); meta.md is WHAT. Names every public API + error class with backticks. Walks algorithm step-by-step in prose. Calls out integration points + pipeline ordering. Names every invariant agents miss. Closing enumerates all exports + parent classes. Plain ASCII + human voice. See `DIAMOND.md § solution-approach.md Structure` + `DIAMOND-PLAYBOOK.md § Section 6.3` + reference `Olympus/approved-problems/diamond-problems/approved/cliffy-command-aliases/solution-approach.md`.
- [ ] **Diamond only — test-groups.md REQUIRED**. Groups tests by behavioral category; per group lists test function names + quoted description requirement. Feeds Test Summary in failure-qa.md. See `DIAMOND.md § test-groups.md Structure`.
- [ ] **Diamond only — failure-qa.md template ready** (filled per-run after Castor 10x). 12 writing rules (DIAMOND-PLAYBOOK § Section 5). Plain ASCII + human voice. No trajectory step refs, no cross-run comparisons, no fabricated identifiers.
- [ ] **Diamond only — Env Description ≥300 chars** drafted in `feedback.md § Env Description`. Covers 3 elements: (1) what env teaches model, (2) typical task shape, (3) successful vs failing trajectory description with SPECIFIC blind spot named (Section 1 trap-category vocabulary). Paste into Shipd UI at submit. See `DIAMOND.md § Environment Description` for approved 352-char example + cliffy-aliases 460-char style match.
- [ ] **ALL TIERS — Human-voice + ASCII across submission-bound text** (meta.md always; failure-qa.md / solution-approach.md / test-groups.md / env description for Diamond; feedback.md sections on Shipd UI). NO em dashes (U+2014), NO `--` in prose, NO Unicode arrows / smart quotes / ellipsis, NO AI cadence ("Sure!", "I'd be happy", "It's important to note", "In essence", "At its core", "Notably", "This approach"), NO trajectory step refs, NO cross-run comparisons. Verify: `rg '[\xE2][\x80][\x90-\xAB]' meta.md feedback.md` returns empty. `file meta.md` says "ASCII text". See `DESCRIPTION.md § Human-Voice + ASCII Rules`.

### FP prevention — EXECUTE, do not reason (run before every submit)

A false positive is a wrong solution that still passes your suite. The platform re-runs mutated and
broken solutions against your tests; green means your passing agents were never passing, and the
datapoint is void. **Reading your own tests and judging them covered fails every time — you wrote
them and you know what they meant.** Three mechanical passes, all of which run the suite:

- [ ] **Per-branch mutation.** Walk `solution.patch` hunk by hunk and break exactly ONE thing per
      run: flip a boolean, delete a match arm, stub a branch to a no-op, change a constant. Re-run.
      Green = that branch is untested. ⚠️ **Run each mutation against BASE mode as well as NEW mode
      (L33).** A baseline-preservation trap (S3) has an EXISTING test as its discriminator, so a
      harness scoped to your new tests is structurally blind to it — and its silence reads as proof
      the requirement is vacuous. Measured on sfepy: a clamp's cache-clear survived every one of 74
      new tests in four probed configurations and was deleted as dead code; the next base run failed
      the repo's own elastodynamics test. Restore from a pristine copy between mutations and assert the
      edit actually applied — a silently no-op string replace yields a confident, wrong "kills
      nothing". (This is the same harness as `olympus-harden` Stage 5; there it buys difficulty,
      here it buys FP safety. Run it for BOTH reasons.)
- [ ] **Feature-stub run.** Apply the solution but no-op the feature itself. The suite must go almost
      entirely red. Anything still green is either a deliberate backward-compatibility check or a
      hole — name which, for each one. **This is NOT the same as the base run:** in Rust the base run
      fails to COMPILE, so every test "fails" for one reason and you learn nothing per-test. The
      stub run is the only per-test signal you get. (Measured on lyon-fill-internal-vertices: base
      mode produced 45 synthetic failures from one E0061.)
- [ ] **Assertion-flip.** For every assertion, change the EXPECTED value to something wrong and
      re-run. Still green = the assertion is decorative. Catches `is_ok()`, `len() > 0`, `contains`
      where the exact value is the contract, and vacuously-true predicates. (lyon shipped a
      vacuously-true `assert!(!... && attr != expected)` right after `assert_eq!(attr, expected)`;
      reading caught it, but only by luck — the flip test catches it mechanically.)

### Solution
- [ ] **Current sprint floor: ≥200 effective/meaningful LOC** (down from 450/400 auto-block). Pre-submit verify: `f=solution.patch; raw=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|wc -l); blank=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*$'); comment=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*(///|//|/\*|\*)'); echo $((raw-blank-comment))` (this is the looser Counter 1; gate on the human-effective Counter 2 ≥200, which strips more — imports, braces, package lines). Design to a buffer above 200 (e.g. 300+). Comments count ZERO.
- [ ] **Current sprint floor: ≥2 files modified** (down from 3; historical Mars 1-8/Olympus 8-35 bands are precedent, not a gate)
- [ ] Pure-function helpers extracted (1+ per behavior)
- [ ] Follows project conventions (naming, patterns, error handling)
- [ ] No debug statements, no AI markers, no commented-out alternatives
- [ ] No drive-by refactors, no breaking signature changes
- [ ] Comment style matches repo convention exactly

### Patches
- [ ] Generated against `$BASE_COMMIT` (not HEAD)
- [ ] test.patch contains test.sh + new test files only (no solution code)
- [ ] solution.patch contains source files only (no tests, no Dockerfile)
- [ ] Both apply cleanly with `git apply` in either order
- [ ] Both unapply cleanly with `git apply -R`
- [ ] No untracked files missing (`git status --porcelain` clean)
- [ ] UTF-8 + LF (Windows: verify `file solution.patch` says "ASCII text")

### Description
- [ ] Action-verb title, 5–10 words, names specific subsystem
- [ ] Tier-appropriate word count (recommended: Mars ≤240, Olympus ≤200; hard cap both: 500)
- [ ] Plain prose only, no `##` headers, no formulaic labels
- [ ] Backticks only on new public API names
- [ ] No `Box<...>` wrappers, no code-instead-of-prose
- [ ] Canonical form spelled out when tests use `assert_eq!` on structures
- [ ] Every described behavior has ≥1 test; every test traces to description
- [ ] ≤1 codebase-inferable requirement
- [ ] Blind-spot pre-empt sentences applied where applicable

### Dockerfile
- [ ] Pattern A (`olympus-base-rust` + chmod/symlink workaround) for Rust workspaces
- [ ] Pattern B language-specific slim image (`olympus-base-{python|typescript|go}`) for everything else (May 2026 admin update). ⚠️ `cpp` + `jvm` UNSUPPORTED as of 2026-05-14.
- [ ] Legacy `olympus-base` / `mars-base` only for re-verifying historical submissions
- [ ] No package manager installation (preinstalled in base)
- [ ] No test execution at build time
- [ ] Builds offline (`--network none`)
- [ ] `CMD ["/bin/bash"]`
- [ ] Verified non-root (`--user 1000:1000`)

### Folder
- [ ] Exactly 5 files: BASE_COMMIT.txt, meta.md, test.patch, solution.patch, Dockerfile
- [ ] No `*_SUMMARY.md` / `*_PLAN.md` / `*_READY.md` / docs

### Solvability (current sprint, one tier)
- ≥1 agent passed (cannot be bypassed) across 10+ Nova/Orion/Vega runs
- **≤40% pass-rate ceiling** — up from 20%/30% (0%=reject, >40%=too easy). No `description_clear: false` flags.
- Long-horizon floor: ≥200 effective LOC, ≥2 files, ≥40 solver-median messages

### GitHub
- [ ] `gh pr list -R OWNER/REPO --state all --search "KEYWORD"` shows no existing PR
- [ ] No closed/rejected issue from maintainer for this feature class
- [ ] Repo ≥500★, commit in last 12mo, permissive license

---

## Common Mistakes

### Patches
- Wrong base for diff → always `$BASE_COMMIT`
- Test files in solution.patch → specify exact source paths
- Untracked source files missing → `git status --porcelain` before generating
- Forgot `BASE_COMMIT.txt` at clone time → unrecoverable

### Tests
- Tests pass on base → not testing the feature
- AI-generated comments (category headers, numbered steps)
- Flaky time-based tests → use generous delays or explicit timestamps
- Weak assertions (`assert True`, `len > 0`)
- Exact error message strings → use substring match
- Tests using solution-specific helpers (don't exist in base)

### Solution
- AI-generated comments
- Debug statements
- Unused vars/imports / dead code
- Under the current floor (≥200 effective LOC, ≥2 files) → expand scope, don't pad
- Drive-by refactors
- Breaking existing function signatures

### Description
- Implementation details → describe WHAT, not HOW
- Vague language ("properly", "correctly", "as expected")
- "Same as X" without listing names → list actual names
- Markdown headers / formulaic labels → plain prose only
- External framing ("Pest is a parser library that…") → drop reader directly into change

### Dockerfile
- Installing pre-installed package managers
- Running tests at build time → setup only
- Missing offline support → must work `--network none`

### Difficulty calibration (one tier now — no Mars downgrade path)
- Submission at 0% pass → cannot bypass, redesign the traps or route a near-0 design to Diamond (keeps the hint flow)
- Submission at >40% pass → too easy, harden (add an interdependent+misdirecting trap; the knob is trap count/strength, NOT LOC)
- Problem at low pass (near the ≤40% ceiling) with Wrong Logic ≥25% → subtle algorithmic trap (good) OR ambiguous spec (bad — clarify)
- Under the current floor (≥200 effective LOC, ≥2 files, ≥40 solver-median messages) → expand scope, don't pad

---

## Quick Commands

```bash
# Clone target into worktrees/, save BASE_COMMIT
git clone <url> worktrees/<repo> && cd worktrees/<repo>
mkdir -p ../../problems/<repo>-<issue>
git rev-parse HEAD > ../../problems/<repo>-<issue>/BASE_COMMIT.txt

# Build + run offline as non-root
docker build -t <repo>-<issue> .
docker run --rm --network none --user 1000:1000 -v /tmp/out:/out <repo>-<issue> \
  bash -c "/app/test.sh --output_path /out/base.xml base && /app/test.sh --output_path /out/new.xml new"
grep -c '<testcase' /tmp/out/*.xml   # both > 1

# Generate patches against BASE_COMMIT
BASE=$(cat ../../problems/<repo>-<issue>/BASE_COMMIT.txt)
git diff $BASE -- src/ > ../../problems/<repo>-<issue>/solution.patch
git add test.sh tests/<feature> && git diff --cached $BASE -- test.sh tests/<feature> > ../../problems/<repo>-<issue>/test.patch

# Verify folder has exactly 5 files
ls problems/<repo>-<issue>/

# Existing PR check (THE #1 revert reason)
gh pr list -R OWNER/REPO --state all --search "KEYWORD"
```

---

## Reusable Prompts

See `Olympus/Instructions/PROMPTS.md`:
- Query 1 — Generate Mars feature (fallback tier)
- Query 2 — Solve existing issue (Mars or Olympus)
- Query 3 — Find candidate repositories
- Query 4 — Analyze repo for challenges
- Query 5 — Handle reviewer feedback
- Query 6 — Generate Olympus feature
- Query 7 — Diamond-tier task (create/eval/failure-qa/review-feedback)
- Query 8 — Lite issue resolution
- Query 9 — Lite repo analysis

---

## Companion Skill

`olympus-review` — applies same shape taxonomy + 21-item checklist when reviewing submissions. If you produced `DESIGN.md`, the reviewer cross-checks deliverables against its claims (shape, API surface, canonical form, file footprint, traps, predicted Nova).

## Reference Docs

| File | Purpose |
|---|---|
| `Olympus/Instructions/HARDENING.md` | **Read at design time, every pick.** The difficulty-DESIGN layer: survival-ranked trap arsenal (S/A/B/DEAD tiers with measured kill counts), the CONTRACT-STATED/FIX-HIDDEN axiom, the fair re-hardening method, steroids-era law index. Phase 3 Step B cites this directly. |
| `Olympus/Instructions/TOO-EASY.md` | **Read at pick time, every candidate.** Death-Class Taxonomy + Pre-Pick Guard (5 questions) + the `rejected/` case-study index (petgraph, kysely, ironcalc, cel-exhaustive-eval, js-joda, symengine, and more) — every dead class was a real wasted batch. Phase 3 Step A cites this directly. Also check `rejected/` itself for repo/feature-class collisions before picking. |
| `Olympus/Instructions/PLAYBOOK.md` | **Read first.** Lean core — patterns 1-16 + approved tables + appendices |
| `Olympus/Instructions/SHAPES.md` | **Shape taxonomy.** Patterns 11-13 — 6 Mars + 6 Olympus shapes + best-agent matrix |
| `Olympus/Instructions/PATTERNS-ADVANCED.md` | Patterns 17-33: trap-stacking ceiling, namespace expansion, triviality, post-base activity, opt-in flag, JUnit XML multi-package |
| `Olympus/Instructions/PROBLEM-PROFILES.md` | Per-problem deep dives — behavioral data + iteration lessons. Open closest shape/repo match. |
| `Olympus/Instructions/KNOWLEDGE.md` | **Lean** — agent behavioral profiles + cross-agent blind spots + message-count + Diamond cross-cutting |
| `Olympus/Instructions/lessons-learned.md` | **Lean** — cross-cutting iteration lessons (description/tests/patches/reviewer/solution/language/checklist/diamond general) |
| `Olympus/Instructions/AGENTS.md` | Nova/Orion/Vega per-agent profiles, cross-agent blind spots, failure categories |
| `Olympus/Instructions/RULES.md` | 21-item review checklist, tier matrix, bypass message format, track record |
| `Olympus/Instructions/WORKFLOW.md` | End-to-end: repo → design → tests → solution → Docker → submit |
| `Olympus/Instructions/DESCRIPTION.md` | Shape-aware meta.md writing, blind-spot pre-empt sentence bank |
| `Olympus/Instructions/TESTS.md` | 4-block test layout, JUnit XML by language, build-failure fallback |
| `Olympus/Instructions/SOLUTION.md` | Helper extraction, fixpoint loops, modified-vs-new ratio, integration patterns |
| `Olympus/Instructions/DOCKER.md` | Pattern A (`olympus-base-rust`) vs Pattern B (slim per-language: `olympus-base-{python|typescript|go}`). ⚠️ Java/JVM + C/C++ UNSUPPORTED as of 2026-05-14. Historical guide (reference only): <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit> |
| `Olympus/Instructions/PROMPTS.md` | 10 reusable agent prompts (Mars/Olympus/Diamond/Lite/tier-agnostic) + GitHub CLI |
| `Olympus/Instructions/DIAMOND.md` | Premium Diamond tier ($500/submission, Failure QA required) |
| `Olympus/Instructions/DIAMOND-PLAYBOOK.md` | **Read BEFORE any Diamond.** Evidence-based design + iteration discipline from 6 Diamond subs. 8 Castor trap categories (cross-architectural ★ ranked), design bands (LOC/word/test/API), iteration cost model (mean 8 eval + 4-6 QA rounds), failure-QA 12-rule writing guide, Section 9 pre-submit maintainer-philosophy gate. |
| `Olympus/Instructions/olympus-common-mistakes.md` | Proven mistakes, agent failure patterns |
| `Olympus/Instructions/olympus-extreme-complexity-guide.md` | Anti-agent design patterns, difficulty tuning |
| `Olympus/Instructions/AUTO-REVIEWER.md` | Reverse-engineered auto-review pipeline + pre-submit hardening |

**Reading order:** TOO-EASY (pre-pick guard, every candidate) → HARDENING (arsenal, every pick) → PLAYBOOK → SHAPES → PROBLEM-PROFILES (closest shape) → PATTERNS-ADVANCED if applicable → tier-specific (DESCRIPTION/TESTS/SOLUTION/DOCKER) → cross-ref KNOWLEDGE + lessons-learned.

## ⚠️ Environment constraints (this workstation)

- **NO LOCAL DOCKER.** Do not attempt to build or run the image; do not report the Dockerfile as
  verified. Write it to the `DOCKER.md` pattern, verify statically, and record Docker validation as
  owed to the platform run. Everything else is validated locally.
- **WATCH DISK.** `cargo`/`go` target dirs dominate (measured 1-5G each vs a 3-32M clone). Run
  `df -h /home` before a long build, prefer `cargo test -p <crate>` over `--workspace`, and delete
  `worktrees/<repo>/target` as soon as a measurement is done. A build has already filled this disk
  mid-session and destroyed tool output.


### F-12 audit (REQUIRED before scope-lock, Rust repos especially)

If the file your feature forces a rewrite of carries `#[cfg(test)] mod tests` whose tests call a
private fn of that file, you have an F-12 axis whether you want it or not. Measured at ~30% kill
on numbat (3 of 10 runs passed all 88 feature tests and failed on baseline alone; removing the
axis would have read 50% = too easy).

Decide it once, in DESIGN.md, and never toggle it mid-flight:
- Base mode skips ONLY the tests the feature genuinely invalidates. Name them in DESIGN.md.
- Do NOT skip the module wholesale — it removes the axis and draws a High review finding.
- Do NOT plan to relocate the tests: a test-only patch may not touch `src/`, and deleting them in
  `solution.patch` makes your own reference fail p2p identity.

The axis is invisible in local validation (your reference always preserves its own tests), so it
must be reasoned about at design time or it will cost batches.
