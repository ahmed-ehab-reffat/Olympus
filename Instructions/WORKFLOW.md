# WORKFLOW — End-to-End Process

How to create a Shipd challenge from repo selection to submission. Both Mars and Olympus follow this process; only the scope targets differ.

> **Read first:** `PICK-FILTER.md` — run the 8 pre-pick gates BEFORE scope-locking any repo+feature (a candidate failing any gate is dead; behavioral-f2p-gap is the decisive first gate). Then `PLAYBOOK.md` — evidence-based patterns from 13 approved problems (5 Mars + 7 Olympus + 1 cross-tier).

---

## What You're Building

A self-contained coding task built around a real open-source repository. You select a repository at an immutable commit, write a precise description, add deterministic failing tests, implement a reference solution, and package everything in a reproducible Docker environment. The agent then has to solve it.

### 5 deliverables

```
problems/{reponame}-{issue}/
├── BASE_COMMIT.txt   # 40-char commit hash, saved at clone time
├── meta.md           # Problem description (plain prose)
├── test.patch        # test.sh + new test files
├── solution.patch    # Source-only changes (no tests, no Dockerfile)
└── Dockerfile        # Environment setup
```

Plus from day one:
- `feedback.md` — strategic summary, attempt history, fix tracking
- `eval-results.md` — per-agent table per run

After approval, archive in `Mars Approved V2/` or `Olympus Approved/` with post-approval reports (`Agents Runs.md`, `Checks Run.md`, optional `Bypass Massage.md`).

---

## Tier Decision (Pick First)

| | **Mars** (default) | **Olympus** |
|---|---|---|
| Payout | $125–$175 | $250–$350 |
| Review time | ~12h | 1–2 weeks |
| Solution +LOC | 100+ floor, **170–380 sweet spot** | 400+ floor, 600+ sweet spot |
| Files modified | 1–8 (mode 3) | 8–35 (median ~17) |
| Agent eval | 10 Nova/Orion, **≤ 30% pass** (solvable) | 10+ runs Nova/Orion/Vega, ≥1 pass at ~10% |
| Starter tiers | Mars only | Unlocks after promotion |

**Pick Mars when:** feature fits one subsystem with a clean integration hook; sketched solution lands 170–380 LOC; you want to ship and iterate fast.

**Pick Olympus when:** feature genuinely spans 4+ subsystems; sketched solution is 600+ LOC across 10+ files; you can defend ≥1 Nova/Orion/Vega pass.

You can downgrade Olympus→Mars at submit time or in a revision. Don't hold a problem hostage to Olympus if Mars ships it faster.

### Category at submit time

Every submission picks a category. The platform classifier validates it against your description; mismatch = FAIL.

| Category | Pick when… |
|---|---|
| **enhancement** | Modifying an existing function/pass/subsystem to add behavior. Title starts with "Rewrite…", "Extend the existing…", "Change how X does Y". |
| **feature-request** | Introducing net-new functionality (new public type, new API method, new config key, new subcommand). Title starts with "Add…", "Introduce…", "Expose a new…". |

Pick the honest category — fighting the classifier with reworded openings is fragile.

---

## Identify Your Shape (Required Before Step 0)

After 13 approved problems, every approved feature falls into one of 10 shapes (6 Mars + 4 Olympus). **Identify your shape before picking the repo** — it tells you target pass rate, best agent, file count, and LOC budget. **See `SHAPES.md § Patterns 11-13` for full details.**

### Shape Decision Tree

```
Mars or Olympus?
├── Mars Solid (default)
│   ├── Touches existing pipeline across 3+ similar-weight files? → A1 (10-15% pass, Nova→Orion slow)
│   ├── 1 main file with bulk + thin wiring + signature change? → A2 (20-25% pass, Nova→Orion fast)
│   ├── Adds new module(s) with explicit list of public functions? → B (50-55% pass, Orion-alone)
│   ├── Single file additive extension (no signature change)? → C (20-25% pass, Nova→Orion)
│   ├── Adds NEW cross-crate enum variant? → D-new (20-25% pass, Orion-alone, Integration risk)
│   └── CHANGES existing cross-crate variant signature? → D-change (40-45% pass, Regression risk)
│
└── Olympus
    ├── Refactor existing aggregation across packages? → O-Composite-extend (25-30%, Orion)
    ├── Add new feature spanning parser/compiler/VM/runtime? → O-Composite-add (15-20%, Vega)
    ├── New optimizer variant + cascading effects (familiar algo)? → O-Pipeline-easy (25%, Vega)
    ├── New optimizer variant + cascading (invent algo)? → O-Pipeline-hard (15%, Vega)
    ├── New variant + missing-element-in-list trap? → O-Algorithm-coverage (10%, Orion-alone)
    ├── New variant + subtle algorithmic correctness? → O-Algorithm-correctness (8%, Mixed)
    └── Universal LLM blind spot at 0%? → O-Trap (NO LONGER VIABLE — redesign or downgrade to Mars)
```

### Shape-Aware Targets

Once you've identified your shape, your design targets are:

> ⚠️ "Pass rate target" below = historical observed rate per shape. **Caps now: Mars ≤30%, Olympus ≤20% (admin 2026).** Any shape historically above its cap (Mars B 50-55%, D-change 40-45%; Olympus O-Composite-extend 25-30%) needs extra interdependent+misdirecting traps to land under the cap. The cap is the approval target, not the historical band.

| Shape | Files | Solution +LOC | Test count | Desc words | Pass rate target | Best agent |
|---|---|---|---|---|---|---|
| Mars A1 | 3 distributed | 167 | 68 | 107 | 10-15% | Nova→Orion slow |
| Mars A2 | 3 conc + wiring | 220 | 92 | 137 | 20-25% | Nova→Orion fast |
| Mars B | 3 (2 new) | 377 | 160 | 241 | 50-55% | Orion-alone |
| Mars C | 1 dense | 358 | 39 | 91 | 20-25% | Nova→Orion |
| Mars D-new | 15 (4 crates) | 400 | 126 | 148 | 20-25% | Orion-alone |
| Mars D-change | 8 multi-crate | 340 | 102 | 183 | 40-45% | Nova→Orion + Vega |
| Oly O-Composite-extend | 9+ | 600 | 162 | 330 | 25-30% | Orion |
| Oly O-Composite-add | 12 | 366 | 73 | 200 | 15-20% | Vega |
| Oly O-Pipeline-easy | 5 | 433 | 104 | 130 | 25% | Vega |
| Oly O-Pipeline-hard | 4 | 413 | 103 | 140 | 15% | Vega |
| Oly O-Algorithm-coverage | 4 | 379 | 68 | 227 | 10% | Orion-alone |
| Oly O-Algorithm-correctness | 6 | 532 | 62 | 137 | 8% | Mixed |

If your sketched solution lands far outside the matching shape's bands, either re-classify the shape or re-scope the problem.

---

## Step 0: Pick a Repository

### Hard requirements

| Criterion | Requirement |
|---|---|
| Public on GitHub | Required |
| Language | TS, JS, Python, Go, or Rust |
| Stars | ≥ 500 |
| Activity | ≥ 1 commit in last 12 months |
| License | MIT, BSD (any), Apache, Boost, CC-BY. **NOT** GPL/AGPL |
| Production-level | Tools/libraries used by real developers |
| Commit | Immutable hash, not branch or tag |
| No existing PR | None solving the problem you're targeting |

### What makes a great repo

- **Multi-package architecture** — clear boundaries that force cross-subsystem changes
- **Behavioral testing through public APIs** — not internal mocks
- **Rich domain logic** — parsers, interpreters, optimizers, CLI tools
- **Solid core but missing features** — established patterns + space to extend
- **Niche over popular** — less agent training data = genuine knowledge gaps

The two repos producing all 5 approved Mars problems are pest (parser library) and lightningcss (CSS parser/optimizer). Both are deep optimizer/transformer libraries — that's not coincidence.

### Red flags (skip immediately)

- Single-file monolith (no multi-package potential)
- All tests use heavy mocking (can't write behavioral tests)
- No test infrastructure
- All open issues are trivial (typos, docs)
- Archived or stale (>12mo)
- GPL/AGPL license
- Auto-generated or heavily templated codebase
- Most features need external services (DB, cloud APIs)

### Setup — Worktree Method (Recommended for Multiple Issues)

Worktrees let you work on multiple issues from the same repo simultaneously with fully isolated changes.

```bash
cd {workspace}

# Clone bare repo (first time only for this repo)
git clone --bare https://github.com/{org}/{repo}.git {reponame}

# Create issue folder
mkdir -p {workspace}/problems/{reponame}-{issue}

# Create worktree for this issue
git -C {reponame} worktree add ../worktrees/{reponame}-{issue} HEAD

# CRITICAL: save base commit immediately
cd worktrees/{reponame}-{issue}
git rev-parse HEAD > {workspace}/problems/{reponame}-{issue}/BASE_COMMIT.txt
echo "Base commit saved: $(cat {workspace}/problems/{reponame}-{issue}/BASE_COMMIT.txt)"
```

**Folder structure after setup:**
```
{workspace}/
├── {reponame}/                    # Bare repository clone
│   └── .git/
├── worktrees/
│   └── {reponame}-{issue}/        # Worktree for this issue (work here)
│       ├── .git
│       ├── src/
│       └── test.sh
└── problems/
    └── {reponame}-{issue}/        # Issue deliverables
        ├── BASE_COMMIT.txt
        ├── meta.md
        ├── test.patch
        ├── solution.patch
        └── Dockerfile
```

**Cleanup worktree when done:**
```bash
git -C {reponame} worktree remove ../worktrees/{reponame}-{issue}
# Or: rm -rf worktrees/{reponame}-{issue}
```

### Setup — Simple Method (Single Issue)

```bash
# Clone fresh, use the latest commit
git clone https://github.com/{org}/{repo}.git worktrees/{reponame}
cd worktrees/{reponame}
mkdir -p {workspace}/problems/{reponame}-{issue}

# Save BASE_COMMIT immediately — first thing after cloning
git rev-parse HEAD > {workspace}/problems/{reponame}-{issue}/BASE_COMMIT.txt
```

**ALWAYS clone target repos into `worktrees/<repo-name>/`** — never anywhere else in the project. `worktrees/` is git-ignored so cloned repos never pollute the Olympus repo history.

**Save BASE_COMMIT before any other action.** Forgetting this is unrecoverable.

### Install Dependencies (verify existing tests pass)

```bash
# Python
python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
# or: uv sync --frozen / poetry install / pdm install

# Node/Bun
bun install
# or: npm install / pnpm install / yarn install

# Go
go mod download

# Rust
cargo build

# Verify existing tests pass
pytest / bun test / npm test / go test ./... / cargo test
```

### Pre-Flight Checks (BEFORE starting work)

**Check for existing PRs and duplicates:**
```bash
# Search for existing PRs solving this issue
gh pr list --repo OWNER/REPO --state all --search "KEYWORD" --json number,title,state,url

# Check if issue has linked PRs
gh issue view ISSUE_NUMBER --repo OWNER/REPO --json closedByPullRequestsReferences | jq '.'

# Search for related PRs
gh pr list --repo OWNER/REPO --state all --search "fixes #ISSUE_NUMBER OR closes #ISSUE_NUMBER" --json number,title,state,url
```

If a PR already exists that solves the issue → **reject**, pick a different issue.

**Verify repo philosophy alignment:**
- Read the repo's README.md and CONTRIBUTING.md
- Check if proposed change fits project's direction
- Search closed PRs for similar features that were **rejected** by maintainers
- Changes that contradict project conventions → will be rejected

**Difficulty check:**
- Target: **4-8+ hours** for an experienced contributor
- SOTA AI agents **should struggle** with the problem
- If the issue looks like it can be solved in < 2 hours → pick a harder one
- One-liner solutions = trivial = **rejected**
- If Holistic_AI/AI_DIFF checks pass easily after submission → too easy

---

## Step 1: Design (Before Any Code)

The design phase is where you decide WHAT the challenge is and WHY it works. A weak design wastes patches, fails agent runs, and gets rejected.

### Mars Solid sketch reference (April 2026, observational)

5 approved Mars problems landed at 3 files, ~340 LOC, ~137 description words. Test counts varied 39–160 — **no test count target**. If your sketch lands far outside this, reconsider tier or scope before coding.

### Understand the codebase first

You must deeply understand the repository before picking a feature. You've studied enough when you can:

- Explain the architecture in 2 minutes
- Predict which files would change for a given feature
- Name 3+ areas where the codebase is missing features
- Describe the testing framework and organization

### What makes a good problem

**✅ Strong Mars Solid candidates:**
- Feature fits one subsystem with an integration hook (1–8 files, mode 3)
- 5–13 stated requirements, 170–380 LOC
- 2–3 genuine edge cases agents will miss (canonical form, sort order, fixpoint termination)
- Clear API surface (method/option/error names tests assert against)
- Naturally produces **≤ 30% Nova pass rate** (~2+ INTERDEPENDENT + MISDIRECTING traps; Nova≈Castor so single-point/self-revealing traps get single-shot-fixed)
- Approved shapes: validator pass with substring-match diagnostics; new optimizer module with parallel APIs; fixpoint rewrite over an existing pass

**✅ Strong Olympus candidates:**
- Touches 20–40+ files across multiple packages
- Architectural thinking, not just code addition
- Cross-package integration (CLI ↔ core ↔ tests)
- 400+ LOC, 10+ interacting requirements

**❌ Weak candidates (both tiers):**
- Single-file one-liner fixes (<100 LOC)
- Generic patterns bolt-on (caching, rate limiting, logging)
- Cosmetic refactors or docs
- Bugs in dependencies, not the project
- Features solvable by a standalone new module with minimal wiring
- Pattern-followable: 3+ identical structural examples already in the codebase → agents copy-paste, no test hardening fixes it

### Always create original features (don't use open issues)

Open issues limit scope and may already have solutions in linked PRs/comments. Architectural analysis produces better candidates than the issue tracker. Use issues as inspiration only, never as a binding spec.

**Inventing your own feature:** You don't need a GitHub issue to create a challenge. All 6 approved Olympus problems are **invented features** with no issue URL. Design a genuinely complex feature that fits the repo's philosophy. Even without an issue, still run the pre-flight checks above to verify no one has already built the feature.

### Validate complexity

| Tier | Floor | Observed range | "Ceiling" (non-binding) |
|---|---|---|---|
| Mars Entry | 100 | 100–200 | 200 |
| **Mars Solid** | ≥100 (≥150 pref) | **170–380** | 400 |
| Mars Strong | 400 | 400–600 | 600 |
| Olympus Okay | ≥450 (400 auto-block) | 400–600 | 600 |
| Olympus Good | 600 | 600–900 | 1000 |
| Olympus Excellent | 900 | 900–1500 | 1500+ |

The Floor column is binding. The "Ceiling" column records observed maxima only — it is **never a cap and never a reason to stop adding complexity** (a genuinely hard 900+ LOC Olympus is better, not worse). Sketch the 2–3 hardest files in real code before committing to an LOC estimate. File-walk estimates consistently overshoot by 50–75%. Modern languages catch missing match arms with `..` patterns; threading a parameter through 35 call sites is ~5 lines, not ~35.

**Counting functional LOC** (Olympus 400+ rule):
```bash
grep '^+[^+]' solution.patch | grep -v '^+$' | grep -v '^+[[:space:]]*$' \
  | grep -v '^+[[:space:]]*//' | grep -v '^+[[:space:]]*\*' \
  | grep -v '^+[[:space:]]*/\*' | grep -v '^+[[:space:]]*\*/' \
  | grep -vE '^\+[[:space:]]*[}\)\]]$' | grep -vE '^\+[[:space:]]*(package |import )' | wc -l
```

If complexity is too low, expand scope naturally (don't pad with dead code or boilerplate):
- Add related features in the same domain
- Require CLI flag registration
- Add a public API surface consumed by another package
- Require a second package/subsystem to integrate

### What makes a challenge genuinely hard

Difficulty comes from the problem domain, not test volume:

| Property | Why it's hard |
|---|---|
| Cross-cutting concerns | Agents implement features independently, miss interactions |
| Ordering constraints | Agents wire steps in wrong order |
| State consumption | Agents don't track values used once then changing behavior |
| Writer-side behavior | Agents build reader features then forget writer side |
| Multi-layer integration | Wiring through 4–6 interdependent layers |
| Novel state machines | No patterns to copy from existing codebase |

### Pre-empt shared LLM blind spots

If your problem hits any of these, add a one-sentence pre-empt to `meta.md`:

| Blind Spot | Approved sentence |
|---|---|
| Rule-reference resolution | "Resolve rule references through the grammar's rule map when checking …" |
| Sort order ambiguity | "Order Literal values lexicographically, then …" |
| Adjacent vs all-positions | "working on adjacent positions only so author-supplied ordering is preserved" |
| First/last-occurrence dedup | "deduplicated using ASCII case-insensitive comparison, keeping the first occurrence" |
| Iteration termination | "iterates until no rewrites apply" / "iterate to a fixpoint" |
| Result list ordering | "Results preserve the order rules appear in `rules`" |
| Parallel optimized API | "Parallel `<fn_optimized>` operates on `&[OptimizedRule]` with the same semantics" |
| Falsy-on-invalid | "Returns false for undefined names or empty input" |
| Compound order preservation | "Component order is preserved exactly: `.x:is(.a)` stays `.x:is(.a)`" |

### Reproduce the Bug (Bug-Fix Problems)

For bug fixes (not new features):
- Create minimal reproduction case
- Verify bug exists on base commit
- Document expected vs actual behavior
- Identify root cause

### Design quality gate

Before leaving design:

- [ ] LOC estimate based on a sketched solution, not file-walked maxima
- [ ] Sketched solution touches the right files and proves the approach works
- [ ] Every predicted trap has a named mechanism (NOT compiler-caught, NOT spec-stated)
- [ ] Test helper signatures sketched; forced trait bounds documented
- [ ] meta.md draft fits tier sweet spot (Mars ≤240 recommended, Olympus ≤200 recommended). Hard cap both: 500 words
- [ ] If cross-crate, all needed test files planned with LOC budgets
- [ ] No existing PR solves this
- [ ] Feature is not pattern-followable (no 3+ identical structural examples)
- [ ] Repo's design philosophy respected
- [ ] Predicted pass rate matches declared rank

**Do not start any code until the design is confirmed good.**

---

## Step 2: Dockerfile

Two valid base images:

**Slim language-specific images (May 2026 admin update — preferred for ALL new submissions):**

| Image | Language | Status |
|---|---|---|
| `public.ecr.aws/d3j8x8q7/olympus-base-python:latest` | Python | ✅ supported |
| `public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest` | TS / JS | ✅ supported |
| `public.ecr.aws/d3j8x8q7/olympus-base-go:latest` | Go | ✅ supported |
| `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` | Rust (workspaces too — replaces mars-base) | ✅ supported |
| `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest` | C / C++ | ✅ supported (2026-05-14 disable reverted) |
| `public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest` | Java / JVM | ✅ supported (2026-05-14 disable reverted) |

Legacy generic `olympus-base` / `mars-base` still work for historical re-verify but should NOT be used for new submissions. Historical Java + C++ guide (reference only): <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit?tab=t.0>

```dockerfile
# Pattern A — Rust on olympus-base-rust (default for Rust workspaces)
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

ENV RUSTUP_HOME="/root/.rustup"
ENV CARGO_HOME="/root/.cargo"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY . .

RUN chmod -R a+rX /root \
    && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && cargo fetch && cargo build --workspace

CMD ["/bin/bash"]
```

```dockerfile
# Pattern B — Python/JS/Go/Java/C++ on language-specific slim image
FROM public.ecr.aws/d3j8x8q7/olympus-base-{lang}:latest

WORKDIR /app
COPY . .
RUN {install_command}
CMD ["/bin/bash"]
```

Replace `{lang}` with `python`, `typescript`, `go`, `cpp`, or `jvm`.

**Rust JUnit = `cargo2junit` (2026-07 reviewer directive).** Add `cargo install cargo2junit` to the Dockerfile and pipe libtest json through it in test.sh — see `DOCKER.md § ⚠️ Rust JUnit = cargo2junit` + `TESTS.md § Rust — cargo2junit`. The old bash-regex `run_and_produce_junit` is superseded (reviewer-rejected placeholder + miscounts multi-binary).

If using same repo as a previous problem, copy the existing approved Dockerfile — it's already proven to work.

### Verify Docker offline

```bash
docker build -t {reponame}-{issue} .
docker run --rm --network none --user 1000:1000 -v /tmp/out:/out {reponame}-{issue} \
  bash -c "/app/test.sh --output_path /out/base.xml base"
grep -c '<testcase' /tmp/out/base.xml   # should be > 1
```

If count is 0 or 1, permissions are broken — switch to Pattern A.

Full per-language install commands and troubleshooting in `DOCKER.md`.

---

## Step 3: Tests + test.sh

Follow `TESTS.md` for all rules. Key requirements:

- **One single new test file** at conventional repo location (`<crate>/tests/<feature>_tests.rs` for Rust)
- **4-block layout**: imports → builder helpers (10–30 one-liners) → assertion helpers → granular `#[test]` functions
- **Scenario-encoded names**: `range_z_to_a_errors`, `dedup_two_class_is`, `fixpoint_three_way_prefix_folds_completely`
- **Substring-match for errors** with 1-3 stable keywords (`"alternative"`, `"invalid range"`, `"contradictory"`)
- **Exact-match (`assert_eq!`)** for tree/list/string outputs
- **Zero `//` comments** inside test bodies
- **One assertion per `#[test]`**

### Plan Test Strategy

- Core functionality: 40-50% of tests
- Edge cases: 30-40% of tests
- Integration cases: 10-20% of tests
- Error cases: 10-20% of tests
- Total: 10-35 tests typical (simple bug: 10-15, moderate feature: 20-25, complex feature: 30-50, large feature 40-70)

### Coverage (count-agnostic)

Tests must cover, with no count target:

1. Every described behavior in `meta.md` (≥1 test per sentence/bullet)
2. Every public API surface (function, method, error variant, config option)
3. Every solution branch (every `if`, `match` arm, early return, recursive case)
4. Standard edge cases (empty / zero / single / boundary / unicode / recursion / null)
5. Stated inverse if it matters and isn't symmetric

The count is whatever full coverage requires. Approved Mars range was 39–160 tests — observational only.

### test.sh structure

Must accept `--output_path <path>` and produce JUnit XML. Position-independent arg parsing.

```bash
#!/usr/bin/env bash
set -uo pipefail
MODE=""; OUTPUT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    base|new) MODE="$1"; shift ;;
    *) exit 1 ;;
  esac
done
[ -z "$MODE" ] && exit 1

# run_and_produce_junit function definition — see TESTS.md § Rust for full version

case "$MODE" in
  base) run_and_produce_junit "$OUTPUT_PATH" cargo test --workspace ... -- --skip quote ;;
  new)  run_and_produce_junit "$OUTPUT_PATH" cargo test -p pest_meta --test <new_feature_tests> ;;
esac
```

**Full Rust template** with the `run_and_produce_junit` function and build-failure fallback: see `TESTS.md § Rust — Mars-Approved bash-regex`. The build-failure fallback is non-negotiable — without it, JUnit XML is empty when cargo crashes and the platform reports "No test suite results were found."

### Validate tests

```bash
bash -n test.sh                              # verify syntax
./test.sh --output_path /tmp/base.xml base   # Must PASS
./test.sh --output_path /tmp/new.xml new     # Must FAIL (no solution yet)
grep -c '<testcase' /tmp/base.xml /tmp/new.xml   # Both > 1
```

If new tests pass on base code, they're not testing the bug.

---

## Step 4: Solution

Follow `SOLUTION.md` for all rules. Key requirements:

- Match repo style exactly (naming, patterns, comments, error handling)
- Extract pure-function helpers (1+ per behavior)
- Use fixpoint loops with `loop { … if !changed { break; } }` shape when description says "iterate"
- No comments inside function bodies (unless repo uses doc comments on public APIs)
- No `// TODO`, `// FIXME`, `// NOTE`, `println!`, `dbg!`, `eprintln!`, `console.log`
- No commented-out alternative implementations
- No defensive `if` branches without triggering tests
- No drive-by refactors of unrelated files
- No breaking changes to existing function signatures

### Complexity Checkpoint
- **Mars:** 100+ LOC floor, 170-380 sweet spot, 1-8 files
- **Olympus + Diamond:** **GATE ON COUNTER 2 (`human-effective`) ≥ 450** across 3+ files; 100+ agent steps median. Counter 2 = the reviewer's meaningful count (strips blanks, comments, no-ops, generated/TEST files, package/imports + closing `)`/`}`, braces/punctuation-only, boilerplate). Primary: `python .claude/hooks/effective_loc_check.py solution.patch` → `human-effective` ≥ 450. Counter 1 (auto-block ≥400, raw − blank − comment, braces + imports KEPT; cel-go `575−48−160=367`) is a looser by-product that clears once Counter 2 ≥ 450 — never design to it.
- If solution is under tier floor → the issue is probably too easy, consider a harder one OR expand scope (real code, not comments)
- Don't artificially inflate — genuinely complex problems produce long solutions naturally

### Validate

```bash
./test.sh --output_path /tmp/base.xml base   # Must PASS (no regressions)
./test.sh --output_path /tmp/new.xml new     # Must PASS (solution works)
```

---

## Step 5: Description (meta.md)

Follow `DESCRIPTION.md` for all rules. Key requirements:

- **Action-verb title** (Fix/Add/Implement/Extend/Iterate/Rewrite), 5–10 words, names specific subsystem
- **Plain prose**, 2–6 paragraphs. Mars Solid: 90–160 sweet, 240 recommended cap. Olympus: ≤150 sweet, 200 recommended cap. **Hard cap both tiers: 500 words.**
- **No markdown headers** (`##`), no formulaic labels (`Problem Description:`, `Test Assumptions:`)
- **Backticks** for new public API names only (not internal types)
- **No `Box<...>` type wrappers** — describe variants in prose
- **No code-instead-of-prose** — write "the rate is a decimal number," not `(float64)`
- **Spell out canonical form** when tests use `assert_eq!` on structures (sort order, associativity, dedup strategy)
- **State new public API names explicitly** when tests expect specific names (fairness > naturalness)

### Validate alignment

For every test, can you point to the exact sentence in the description? For every described behavior, is there at least one test? 0–1 codebase-inferable requirements are acceptable; more = hidden requirements.

---

## Step 6: Generate Patches

### Always diff against BASE_COMMIT

```bash
BASE_COMMIT=$(cat problems/{reponame}-{issue}/BASE_COMMIT.txt)
git diff $BASE_COMMIT -- <files> > patch.patch
```

Never use `git diff HEAD`, `git diff`, `git diff origin/main`, or `git diff $BASE_COMMIT` without file paths.

### test.patch (test.sh + new test files)

```bash
# Add untracked files first — they're invisible to git diff
git status --porcelain   # Look for ?? entries
git add test.sh test/test_feature.py
git diff --cached -- test.sh test/test_feature.py > test.patch

# Or for tracked files:
git diff $BASE_COMMIT -- test.sh test/test_feature.py > test.patch
```

### solution.patch (source files only)

```bash
git diff $BASE_COMMIT -- src/file1.py src/file2.py > solution.patch

# For new untracked source files:
git add src/new_module.go
git diff --cached -- src/new_module.go >> solution.patch
```

### Full integration test (both orders)

```bash
# Order 1: test first, then solution
git checkout $BASE_COMMIT && git clean -fd
git apply test.patch
./test.sh --output_path /tmp/base.xml base   # PASS
./test.sh --output_path /tmp/new.xml new     # FAIL
git apply solution.patch
./test.sh --output_path /tmp/base.xml base   # PASS
./test.sh --output_path /tmp/new.xml new     # PASS

# Order 2: solution first, then test (must also work)
git checkout $BASE_COMMIT && git clean -fd
git apply solution.patch
git apply test.patch
./test.sh --output_path /tmp/base.xml base   # PASS
./test.sh --output_path /tmp/new.xml new     # PASS

# Cleanup
git apply -R solution.patch && git apply -R test.patch
git checkout -
```

If any result doesn't match, do not submit.

### Patch separation rules

| Patch | Contains | Never contains |
|---|---|---|
| **test.patch** | test.sh + new/modified test files + test fixtures | Solution code, Dockerfile, docs |
| **solution.patch** | Source files only (impl code, modified config if required) | Test files, Dockerfile, docs, drive-by refactors |

### Common patch issues

| Error | Fix |
|---|---|
| "Patch does not apply" | `git apply --check`, try `--whitespace=fix`, verify on BASE_COMMIT |
| "Already exists" | `git checkout $BASE_COMMIT && git clean -fd` |
| "Patch too large" | Specify exact files, not bare `git diff $BASE_COMMIT` |
| Untracked file missing | `git status --porcelain`, `git add` it, regenerate |
| Windows CRLF | `sed -i 's/\r$//' test.sh` |
| Windows UTF-16 BOM | Generate via Python subprocess (PowerShell `>` produces UTF-16LE) |

### Verify issue folder

```bash
ls problems/{reponame}-{issue}/
# Must have exactly: BASE_COMMIT.txt, meta.md, test.patch, solution.patch, Dockerfile
```

**Forbidden files:** `*_SUMMARY.md`, `*_PLAN.md`, `*_READY.md`, `SOLUTION_COMPLETE.md`, any docs.

---

## Step 7: Run Checks + Fix Cycle

### Iteration cycle expectations

Layered checks; expect multiple revision rounds even on a well-designed problem:

1. **Artifact checks** — 5 files present, Dockerfile builds, base passes, new fails-on-base, JUnit XML valid. 0–1 rounds.
2. **Description quality AI review** — flags HOW-leaks, header usage, redundancy. 1–3 rounds. HIGH severity blocks; MEDIUM/LOW advisory.
3. **Tests quality AI review** — flags weak assertions, AST coupling, missing negative cases. 1–2 rounds.
4. **Alignment check** — traces every test to a description requirement. 0–1 rounds.
5. **Nova empirical runs** (≥10 for Mars) — the real signal. 1–3 rounds until pass rate lands in the tier band.
6. **Orion coverage** (≥2 for Mars) — confirms reachability.

**Mars Solid (playbook-aligned): 1–3 rounds. Olympus: 3–5 rounds.** If you hit 5+ on Mars, the playbook patterns aren't being followed — see `PLAYBOOK.md` § Pattern 8.

### Token rules

- Each check costs tokens. Fix ALL issues in one pass before rerunning.
- Editing content after checks marks results stale (rerun cost).
- Each revision gives 50 tickets for that specific problem. Tickets don't stack across submissions.

### Common auto-check failures

| Failure | Fix |
|---|---|
| "Tests pass without solution" | Tests don't catch the feature; tighten them |
| "Tests have comments" | Remove AI-generated; keep repo-convention only |
| "Solution has comments" | Remove AI-generated; keep repo-convention only |
| "meta.md too long" | Cut filler, keep substance; respect tier cap |
| "Dockerfile fails to build" | Verify base image and offline build |
| "Solvability (0 agents pass)" on Olympus | Cannot bypass; clarify description or resubmit as Mars |
| "Nova pass rate >30%" on Mars | Too easy; add a 2nd INTERDEPENDENT + MISDIRECTING trap or strengthen one to >60% miss (Nova≈Castor — isolated/self-revealing traps single-shot-fixed; knob is trap count/strength, not LOC) |

### When to stop iterating

All artifact checks green; description + tests reviews HIGH-clear; ≥1 Nova solve in ≥10 runs with pass rate in the tier band; ≥2 Orion coverage. Remaining MEDIUM/LOW reviewer suggestions are advisory — if addressing them regresses Nova pass rate, leave them.

### Solvability

At least one agent must solve your challenge — this cannot be bypassed (Olympus). Other failing checks can be bypassed with written justification (see `RULES.md` → Bypass Messages).

---

## Step 8: Submit + Wait for Review

After all checks pass, submit. The submit modal shows both Mars and Olympus options side-by-side; pick the tier that matches your scope.

### Submission gates

**Mars:**
- 10 Nova/Orion runs at **≤ 30% pass rate** (solvable, 0%=reject)
- 2 Orion runs (Orion Evaluator)
- ≥100 LOC, ≥1 file, ≥1 agent message
- No env-blocker, no "task unfair" flags

**Olympus:**
- ≥1 agent solves (cannot be bypassed; hints removed April 2026)
- 10+ runs with Nova + Orion + Vega mix (Castor reserved for Diamond tier)
- ≥400 LOC, 3+ files, 100+ agent messages

Other failing checks can be bypassed with a written justification. Reviewers see the bypass message — make it airtight (see `RULES.md` § Bypass Messages).

### After submission

If reviewer requests changes:
1. Make minimum changes addressing feedback
2. Re-validate locally
3. Regenerate affected patches against BASE_COMMIT
4. Rerun checks
5. Resubmit

Reverts also give 50 tickets. Sprint bonus: +$10–$25 USD per approved submission (limited time).

---

## Step 9: Post-Eval Learning (MANDATORY — every eval, every revision, every approval)

**Source of truth:** `.agents/rules/olympus-post-eval-workflow.md` (always-on rule)

After EVERY eval result / reviewer feedback / approval, update files per the 6-tier matrix:

| Trigger | Action |
|---|---|
| Eval run completed | Update `feedback.md` + `eval-results.md` (per-problem) |
| Revision round | Append "Revision Round N" to `feedback.md` with bucket + fix + re-eval |
| UNFAIR flag | Add pre-empt sentence to `DESCRIPTION § Sentence Bank` + `AGENTS § Confirmed Blind Spots` |
| 0% Olympus pass | DON'T bypass — add pre-empt OR redesign OR downgrade Mars. Document in feedback.md. |
| **Approval** | **Layer 1 (mandatory):** Append per-problem section to `PROBLEM-PROFILES.md` (behavioral data + iteration lessons). **Layer 2:** `PLAYBOOK.md` (approveds table) + `SHAPES.md` (shape data refinement) + `PATTERNS-ADVANCED.md` (if NEW pattern emerged) + `KNOWLEDGE.md` (only if NEW cross-agent blind spot) + `lessons-learned.md` (only if NEW cross-cutting rule) + `olympus-common-mistakes.md` + `olympus-extreme-complexity-guide.md` + `RULES.md` + `AGENTS.md`. See `.agents/rules/olympus-post-eval-workflow.md § Tier 4` for full guidance. |
| Reject | Append post-mortem to `PROBLEM-PROFILES.md` + Update `RULES § Track Record` + `PLAYBOOK § Appendix B` + `olympus-common-mistakes` (META-MISTAKE if novel) |
| 3+ no-move iterations | Update `PATTERNS-ADVANCED.md § Pattern 17 (Trap-Stacking Ceiling)` |

**Per-approval ratchet (the most valuable update):**

After human-confirmed approval, every approval feeds back into 7 files. Mistake catalog grows. Shape taxonomy refines. Agent profiles sharpen. Future authors avoid the same mistake. Skip = lose the ratchet → next problem repeats the same trap.

**Cite specifics:**
- "Tests over-constrained" → vague, useless
- "tests/extended_skip_tests.rs:142 asserts internal `optimize_single` order; reviewer flagged 'tests focus on behavior' WARNING; fix: replaced with `find_unused_rules` public-API assertion. Bucket 4." → actionable

**Update format per file (cite problem + failure rate + verbatim quote):**

```markdown
### N. <Pattern Name> (PROVEN — <Problem Name>, X% failure rate)
**What**: <one-line>
**Why it works**: <cognitive model>
**Example**: <problem cite + failing test name + agent count>
**Detection**: <verbatim test or reviewer quote>
**Fix**: <surgical change>
```

**Anti-patterns (don't):**
- Skip update "I'll do it next time" — context lost on next session
- Vague phrasing ("sometimes fails") — future authors can't act
- Update only `feedback.md` — lessons stay siloed
- Bulk-edit all 7 files at once — each has different update cadence

See `.agents/rules/olympus-post-eval-workflow.md` for the full 6-tier matrix with exact section anchors.

---

## Go-Specific Workflow

### Build Tags for New Tests
Use build tags to separate new tests from existing ones:

**Test file header:**
```go
//go:build featurename

package mypackage
```

**test.sh new command:**
```bash
go test -v -tags=featurename -run '^TestFeature' ./...
```

This ensures new tests are excluded from `go test ./...` (base mode) and only run when explicitly tagged (new mode).

### Go Test Patterns
```go
func TestFeatureName(t *testing.T) {
    vm := New()
    result, err := vm.RunString(`/* JavaScript code */`)
    if err != nil {
        t.Fatal(err)
    }
    if result.Export() != expected {
        t.Fatalf("expected %v, got %v", expected, result.Export())
    }
}
```

---

## Common Mistakes to Avoid

### Patches
- Wrong base for diff → always `$BASE_COMMIT`
- Test files in `solution.patch` → specify exact source paths
- Untracked source files missing → `git status --porcelain` before generating
- Forgetting `BASE_COMMIT.txt` → save first thing after clone

### Tests
- Tests pass on base → they're not testing the feature
- AI-generated comments (category headers, numbered steps) → remove
- Flaky time-based tests → use generous delays or explicit timestamps
- Weak assertions (`assert True`, `len > 0`) → assert specific content
- Exact error message strings → use substring match

### Solution
- AI-generated comments → remove
- Debug statements → remove all
- Unused variables/imports → remove
- Under tier floor LOC → expand scope, don't pad code
- Drive-by refactors → strip them

### Description
- Implementation details → describe WHAT, not HOW
- Vague language ("properly", "as expected") → use concrete terms
- "Same as X" → list actual names
- Markdown headers / formulaic labels → plain prose only

### Dockerfile
- Installing pre-installed package managers → olympus-base-{lang} images already ship them
- Running tests at build time → setup only
- Missing offline support → build must work `--network none`

---

## Tips for Success

1. Read the issue thoroughly — understand before coding
2. Save BASE_COMMIT immediately — first thing after cloning
3. **Search for existing PRs first** — reject if PR already exists
4. **Verify repo philosophy alignment** — change must fit the project
5. **Bias toward maximum difficulty down to the solvability floor** — author for the hardest viable tier; SOTA AI should struggle and rarely pass (Olympus target ~10%, ceiling ≤20%; Mars ≤30%). Never soften to land mid-band; route a near-0 design to Diamond + hints rather than dialing difficulty down. Both ends still reject: too-easy (>30% Mars / >20% Olympus) rejects just like unsolvable (0%)
6. Write tests first — verify they fail on base code
7. Keep it simple — minimal changes, focused solution
8. No comments unless repo convention — use descriptive names instead
9. Validate everything — test patches, run tests, check files
10. Follow conventions — match the existing codebase style
11. Be concise — in description, in code, in everything
12. Test on base commit — ensure tests actually catch the bug
13. Never create summary files — only the 5 deliverable files
14. **Monitor AI checks** — after submission, watch automated results. If all checks fail for the same reason, your description likely needs updating
15. **Fix Windows carriage returns** — if test.sh fails with `\r` errors, run `sed -i 's/\r$//' test.sh`
16. **Test with `--network=none`** — Docker containers should run offline: `docker run -it --network=none challenge`
17. **Be deliberate with check reruns** — running checks consumes tokens; fix all issues in one pass before rerunning

---

## Quick Reference

```bash
# 1. Clone + save BASE_COMMIT (worktree method)
git clone --bare https://github.com/{org}/{repo}.git {reponame}
git -C {reponame} worktree add ../worktrees/{reponame}-{issue} HEAD
cd worktrees/{reponame}-{issue}
git rev-parse HEAD > {workspace}/problems/{reponame}-{issue}/BASE_COMMIT.txt

# Or simple clone:
git clone https://github.com/{org}/{repo}.git worktrees/{reponame} && cd worktrees/{reponame}
mkdir -p {workspace}/problems/{reponame}-{issue}
git rev-parse HEAD > {workspace}/problems/{reponame}-{issue}/BASE_COMMIT.txt

# 2. Build Docker
docker build -t {reponame}-{issue} .
docker run --rm --network none --user 1000:1000 ...

# 3. Validate locally
./test.sh --output_path /tmp/base.xml base   # PASS
./test.sh --output_path /tmp/new.xml new     # FAIL → after solution PASS

# 4. Generate patches
BASE=$(cat ../../problems/{reponame}-{issue}/BASE_COMMIT.txt)
git diff $BASE -- test.sh test/ > .../test.patch
git diff $BASE -- src/ > .../solution.patch

# 5. Verify folder has exactly 5 files
ls problems/{reponame}-{issue}/
```

---

## Reviewing Submissions (Reviewer Audience)

Authoring is one workflow; **reviewing** is another with its own 5-stage process. See:

- `Admin-Review/docs/MARS-REVIEW-GUIDE.md` — complete reviewer guide (30-45 min budget)
- `Admin-Review/docs/REVIEW-TEMPLATE.md` — per-review checklist
- `Admin-Review/docs/FEEDBACK-STYLE-GUIDE.md` — admin feedback phrasing
- `Admin-Review/docs/check_rejection.md`, `check_description.md`, `check_test.md`, `check_solution.md`, `check_bugs.md` — per-stage rubrics
- `.agents/workflows/review.md` — `/review` workflow definition

### Review Process Order

1. **Read `solution.patch` first** — understand the intent, then read the actual modified files (not just the diff). Check that implementation matches intended behavior and doesn't introduce semantic regressions.
2. **Read `test.patch` next** — go through tests one by one. For each test verify: what behavior it asserts, whether it truly validates the intended logic, whether it could produce **false positives** or miss edge cases.
3. **Cross-check solution vs tests** — ensure every behavior introduced in solution.patch is covered by tests. Flag any logic that is untested or only implicitly verified.

### Final Verification Checklist

Before approving any submission, verify ALL of these:

| Check | Status |
|---|---|
| Searched GitHub for existing PRs? | [ ] |
| Repo philosophy matches feature? | [ ] |
| All AI checks passing? | [ ] |
| ./test.sh new FAILS pre-solution? | [ ] |
| ./test.sh new PASSES post-solution? | [ ] |
| ./test.sh base PASSES always? | [ ] |
| Tests use correct framework? | [ ] |
| No debug code or AI comments? | [ ] |
| Description not overly prescriptive? | [ ] |
| No unrelated changes in solution? | [ ] |
| test.sh doesn't have tricks? | [ ] |
| Solution actually works (tested)? | [ ] |
| Problem category correct (bugfix/enhancement)? | [ ] |
| Claimed bug/feature doesn't already exist? | [ ] |
| Solution is proper fix, not workaround? | [ ] |

### Team Lead Verification

> ⚠️ "AI reviews often miss vague specs or sneaky tests."

Before final approval, re-read your conclusions and flag:
- **Hidden assumptions** — specs that seem clear but leave gaps
- **Vague behavior** — description that could be interpreted multiple ways
- **Tests that pass accidentally** — tests that pass for wrong reasons
- Confirm review is strict and human-like

> ⛔ **Never let AI write your feedback** — all feedback must be your own words. Leadership monitors feedbacks/approvals.

### Feedback Format

When writing feedback, use this structure:

```markdown
[Repository URL]

Description:
- [Issue + specific fix needed]

Regarding tests:
- Brittle: [test name] - [why]
- Missing Coverage: [edge cases]

Solution issues:
- Bug: [description]. Fix: [fix]
- Dead code: [what to remove]

Verdict: [Accept/Request Change/Reject]
```

**Key phrases to use:** "Clarify...", "Define...", "Specify...", "This caused X/Y agents to fail", "Dead code", "Remove unused...", "Brittle Tests:", "Missing Coverage:"
