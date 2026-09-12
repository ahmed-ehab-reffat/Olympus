# Creating Challenges
Everything you need to create high-quality challenges for the Project Olympus quest. This guide combines creation and evaluation criteria so that contributors and reviewers are aligned from the start.

# Overview
A challenge on Project Olympus is a self-contained coding task built around a real open-source repository. You select a repository and immutable commit, write a precise problem description, add deterministic tests that expose missing behavior, implement a full reference solution, and package everything in a reproducible Docker environment.

These challenges must be hard. They should push the limits of top-tier AI models and advanced agents. State-of-the-art systems should rarely pass them without significant reasoning and iteration.

# The creation process follows six steps:

1
Choose a Repository
Find a public GitHub repository with an active codebase and pick a specific commit.

2
Write a Clear, Precise Problem
Describe the task clearly enough that a developer can implement the solution without seeing the tests.

3
Write Deterministic Tests
Author tests that fail on the original commit and pass only with the correct solution.

4
Implement a High-Quality Reference Solution
Write a complete reference solution that passes all tests without regressions.

5
Create a Reproducible Dockerfile
Define a self-contained environment that works without network access.

6
Review & Submit
Run prechecks, verify everything, and submit for review.

# Choose a Repository

## Hard Requirements
- Public GitHub repository
- Immutable commit hash (not a branch name or tag)
- At least 1 commit in the last 12 months
- 500+ stars
- Production-level codebase
- Language: TypeScript, JavaScript, Python, Go, or Rust
- Permissive open-source license (see allowed list below)
- Optional: GitHub issue URL that describes the problem

## Allowed Licenses
- MIT
- BSD
- BSD-1-Clause
- BSD-2-Clause
- BSD-2-Clause-Flex
- BSD-2-Clause-FreeBSD
- BSD-2-Clause-Modification
- BSD-2-Clause-Patent
- BSD-2-Clause-Views
- BSD-3-Clause
- BSD-3-Clause-Attribution
- BSD-3-Clause-EricHeitz
- BSD-3-Clause-HealthLevelSeven
- BSD-3-Clause-LBNL
- BSD-3-Clause-Modification
- BSD-3-Clause-OpenMPI
- BSD-3-Clause-plus-CMU-Attribution
- BSD-3-Clause-plus-Paul-Mackerras-Attribution
- BSD-3-Clause-plus-Tommi-Komulainen-Attribution
- BSD-4-Clause
- BSD-4-Clause-Argonne
- BSD-4-Clause-Atmel
- BSD-4-Clause-Giffin
- BSD-4-Clause-PC-SC-Lite
- BSD-4-Clause-Plus-Modification-Notice
- BSD-4-Clause-UC
- BSD-4-Clause-Visigoth
- BSD-4-Clause-Vocal
- BSD-4-Clause-Wasabi
- BSD-4.3TAHOE
- BSD-5-Clause
- BSD-FatFs
- BSD-Mixed-2-Clause-And-3-Clause
- BSD-Protection
- BSD-Source-Code
- Boost
- BSL-1.0
- Other
- BLAS
- GNU-All-permissive-Copying-License
- Apache
- Apache-2.0
- Apache-2.0-Modified
- Apache-with-LLVM-Exception
- Apache-with-Runtime-Exception
- Creative Commons
- CC-BY-1.0
- CC-BY-2.0
- CC-BY-2.5
- CC-BY-3.0
- CC-BY-4.0

## Do not
- Use inactive or abandoned repositories
- Use repos where a PR already solves the exact problem you plan to create
- Invent nonsensical or unmergeable features that don't fit the project

# Write a Clear Description
The problem should read like a real GitHub issue or engineering ticket.

Difficulty is non-negotiable. State-of-the-art AI agents should struggle with your challenge and rarely pass.

## Core Requirements
- Self-contained — solvable from the repo and description alone
- Not already fixed in an open or merged PR
- Clear — describes what to build or fix
- Verifiable — success is objectively testable

## Problem Checklist
1
Requirements Complete and Self-Contained
YES
Everything needed to solve the problem is present in the description
NO
Important context is missing or assumed
2
No Ambiguities, Fully Deterministic
YES
Precise and testable — one correct interpretation
NO
Vague or open to interpretation
3
Concise and Not Prescriptive
YES
Describes what, not how
NO
Prescribes specific algorithms or implementation steps
4
Matches Real-World Repo Scope
YES
Realistic issue that fits the project
NO
"Rewrite the entire auth system"
5
Aligns With Repo Design Philosophy
YES
Fits existing patterns and conventions
NO
"Adds business logic to a hooks-only framework"
6
No Irrelevant Context
YES
Focused on what matters
NO
Long narrative background or unrelated details
7
Clear Writing and Formatting
YES
Structured sections like Goal, Expected Behavior, Constraints
NO
Large unstructured paragraph

## Example
Good description
Add a `--dry-run` flag to the `deploy` command that validates
the configuration and prints what would be deployed without
making any changes. The flag should work with all existing
deploy targets and respect the `--verbose` flag for additional
output.
Avoid descriptions that give away the solution. "Add a check for X if Y occurs .." tells the solver exactly where to look and how to fix it. Instead, describe the behavior, not the implementation. Unless the behavior is not obvious, in which case you can describe the implementation.

# Write Deterministic Tests
Tests are the backbone of the challenge. They define correctness and must be rock-solid.

## Test Patch Requirements
- Valid unified git patch
- Only test changes — no implementation code
- Does not conflict with the solution patch
- No internet required at runtime
- Includes a `test.sh` script that accepts `--output_path <path>` and produces JUnit XML output
    - `./test.sh --output_path results.xml base` — Runs existing tests as a regression check. Must pass. Writes JUnit XML to the output path.
    - `./test.sh --output_path results.xml new` — Runs new or modified tests. Must fail without the solution patch applied.

**CRITICAL:** The platform invokes test.sh as `./test.sh --output_path <path> base` — `--output_path` comes BEFORE the mode argument. Use position-independent arg parsing, never assume `$1` is the mode.

## JUnit XML Setup by Framework

**pytest** — built-in:
```bash
pytest tests/ -v --junitxml="$OUTPUT_PATH"
```

**vitest** — built-in reporter:
```bash
vitest run tests/ --reporter=junit --outputFile="$OUTPUT_PATH"
```

**jest** — needs `jest-junit` (install in Dockerfile: `npm install --save-dev jest-junit`):
```bash
JEST_JUNIT_OUTPUT_DIR="$(dirname "$OUTPUT_PATH")" \
JEST_JUNIT_OUTPUT_NAME="$(basename "$OUTPUT_PATH")" \
  npx jest tests/ --reporters=jest-junit
```

**go test** — needs `go-junit-report` (install in Dockerfile: `go install github.com/jstemmer/go-junit-report/v2@latest`):
```bash
go test -v -count=1 ./pkg/... -timeout 10m 2>&1 \
  | go-junit-report -set-exit-code > "$OUTPUT_PATH"
```
The `-v` flag is required — go-junit-report parses verbose output.

**mocha** — needs `mocha-junit-reporter` (install in Dockerfile: `npm install --save-dev mocha-junit-reporter`):
```bash
mocha tests/ --timeout 10000 \
  --reporter mocha-junit-reporter \
  --reporter-options mochaFile="$OUTPUT_PATH"
```

**deno** — built-in:
```bash
deno test tests/ --junit-path="$OUTPUT_PATH"
```

## Determinism requirements
- No timing-based assertions, no race conditions, no randomness, no network access during test execution.

## Test Quality Checklist
8
New Tests Highlight Missing or Incorrect Behavior
YES
Fail on base commit, pass after correct solution is applied
NO
Already pass without any changes
9
Tests Are Deterministic
YES
Stable across multiple runs
NO
Depend on timing, randomness, or ordering
10
Assertions Verify the Correct Output
YES
Check precise expected outcomes
NO
Only weak conditions like length > 0
11
Tests Validate Behavior, Not Internals
YES
Assert via public APIs and observable output
NO
Inspect private helpers or internal state
12
Tests Follow Repo Structure
YES
Match naming, folder, and framework conventions
NO
Add random folders or use a different test framework
13
Tests Cover Required Behavior and Edge Cases
YES
Success and failure paths tested
NO
Only happy path
14
Test Suite Is Concise
YES
Focused and non-redundant
NO
Bloated or repetitive tests
15
Tests Do Not Check Unspecified Behavior
YES
Map directly to the problem spec
NO
Extra expectations not described in the problem

## Writing the Test Patch
Generating a test patch
### Make your test changes, then generate the patch:
```bash
git diff > test.patch
```

### Verify the patch applies cleanly:
```bash
git stash
git apply test.patch
git stash pop
Verify it applies cleanly
git checkout <commit-hash>
git apply test.patch
./test.sh base  # should pass
./test.sh new   # should fail
```

> Quality check: Run your tests multiple times to confirm they're deterministic. A test that passes 9 out of 10 times is not deterministic and will be caught during review.

# Write a Solution
The reference solution is mandatory and strictly evaluated.

## Hard Requirements
- Valid unified git patch
- Does not conflict with the test patch
- No new dependencies that require internet at runtime
- Only implementation changes — not Dockerfile modifications
- With both solution and test patch applied: ./test.sh base passes (no regressions) and ./test.sh new passes

## Scope Requirement
Challenges must be system-level and multi-file. Successful agent runs must modify at least 3 files, take at least 100 agent steps, and add at least 400 lines of code (median across successful runs). Single-file fixes, trivial CRUD additions, and narrow changes do not qualify.

## Solution Quality Checklist
16
Solution Meets All Requirements
YES
Every behavior specified in the problem is correctly implemented
NO
Missing features or incomplete implementation
17
No Regressions, Code Follows Patterns
YES
Clean, idiomatic, consistent with the existing codebase
NO
Introduces bugs or violates existing patterns
18
No Unexplained Defensive Code
YES
Only implements what the spec requires
NO
Speculative guards or unnecessary error handling
19
No Irrelevant Changes
YES
Diff only includes task-related changes
NO
Unrelated edits, refactors, or formatting changes
20
API Contracts Remain Stable
YES
Public APIs unchanged unless required by the spec
NO
Breaking changes without justification
21
No AI Slop
YES
Clean, purposeful code written with intent
NO
Verbose, over-commented, or obviously auto-generated boilerplate

# Create a Dockerfile
## Hard Requirements
- Base image: public.ecr.aws/d3j8x8q7/olympus-base:latest
- Install all dependencies during the build phase
- Works with --network none at runtime
- Repository cloned at exact commit hash
- /bin/bash entrypoint
- Works without test.patch or solution.patch applied
- No malicious or suspicious code

```Python
Example Dockerfile (Python)
FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

WORKDIR /app

COPY . .

# Install dependencies (no network at runtime)
RUN pip install -r requirements.txt

CMD ["/bin/bash"]
```

> The container runs with --network none during evaluation. Any dependency not baked into the image will not be available. Always build and run tests locally with network disabled.

# Review & Submit

## Full Self-Review Before Submission
- Clone the repo and checkout the exact commit
- Apply test.patch
- Build the Docker image
- Run the container with --network none
- Run ./test.sh base (must pass) and ./test.sh new (must fail) — partial failure in new mode is acceptable if the passing tests are backwards compatibility tests
- Apply solution.patch
- Rebuild and rerun both test modes (both must pass)
- Inspect diffs in the IDE source control view
- Confirm successful agent runs modify 3+ files and take 100+ agent steps (median)
- Confirm no existing PR already solves the issue

>Acceptance Criteria
Reviewers evaluate every submission against 21 checklist items across three categories: Problem (1–7), Tests (8–15), and Solution & Code (16–21)
Your submission must score 5 or above out of 7 on the quality scale to be accepted
Your quality score directly determines your payout amount — higher quality means higher reward

## Token System
- New contributors start with an initial token balance
- Finalized approvals earn bonus tokens (reward varies by tier)
- Tokens replenish hourly based on your contributor tier — determined by your approval rate and number of finalized approvals
- Running checks consumes tokens — be deliberate with your edits and fix issues before rerunning
- Running checks on every small tweak will drain your balance quickly

## Check Staleness
- Editing any submission content after checks have completed marks those results as stale
- Stale checks must be rerun before you can submit — this costs tokens again
- Fix all issues thoroughly in one pass before rerunning

## Submitting with Failing Checks
- When you click Submit, you can bypass failing checks by providing a written reason
- Only bypass if you genuinely believe the failure is unfair or incorrect
- Solvability cannot be bypassed — at least one agent must solve your challenge before you can submit
- Legitimate failures will be caught during review and sent back for revision
- Bypassed submissions are visible to reviewers — make sure your reasoning is sound

# Tips for Success

## Acceptable submissions
- Meet all hard requirements, demonstrate high quality across Problem, Tests, and Solution, and present a realistic, challenging, and clean challenge.

## Rejectable submissions
- An existing PR already solves the problem
- Made-up or nonsensical feature that doesn't fit the project
- Fundamentally flawed or unfixable without a full rewrite

## Common pitfalls
- Misaligned
Your challenge must make sense within the repo. Challenges that feel bolted on or disconnected from the project's purpose get rejected — this is more common than you'd think.

- Copy-paste
Don't create challenges that share the same structure with only superficial differences — e.g. "add a play button" then "add a pause button." Each challenge must require genuinely distinct reasoning.

- Skipping self-review
Review your own work as if you were the reviewer. Check every checklist item yourself before submitting. Catching issues early saves revision cycles and lets you ship more challenges faster. 🤩

## Examples
Real examples of common issues found during review, with explanations and fixes.

### Example: Vague requirements
Most of this description is precise and testable — but the last sentence isn't:

“...When the subpattern uses selections, the handler must receive arrays of matched selections only. Nested array selections should keep their nesting. When no subpattern is provided, match any non-empty array. Update type inference so the pattern does not make array inputs exhaustively handled by itself.”
Why this fails review: The rest of the description is precise and testable, but “update type inference so the pattern does not make array inputs exhaustively handled by itself” is meaningless without deep ts-pattern internals knowledge. A solver reading the repo won't know what this means, and a reviewer can't verify correctness against a requirement they can't interpret.

### Example: Over-prescriptive specification
This spec dictates exact internal structures instead of describing behavior:

“FieldMetadataInfo has field_name, resolved_type (preserving container types), metadata_items (tuple of flattened Annotated metadata), constraints (dict[str, ConstraintInfo]), nested_fields (populated for BaseModel-typed fields including Optional[Model], empty for container-wrapped types like List[Model] and circular refs), defining_class.”
“Constraint name mapping: annotated_types Ge/Gt/Le/Lt to ge/gt/le/lt, MinLen/MaxLen to min_length/max_length, MultipleOf to multiple_of.”
Tests that reinforce the problem:

Implementational tests
assert type(field_info).__name__ == 'FieldMetadataInfo'
assert type(constraint_info).__name__ == 'ConstraintInfo'
assert isinstance(metadata_items, tuple)  # why not list?
The spec dictates exact constraint name mappings, exact class names, exact container types — this is implementation, not behavior.

Hidden requirements buried in the spec: metadata_items must be a tuple (not list), nested_fields empty for List[Model] but populated for Optional[Model], circular refs produce empty nested_fields.

Tests verify internal class names and data structures instead of observable behavior.

Reviewer feedback: “extremely prescriptive... SO many tests are implementational... hidden requirements”

### Example: Before & after fixes
Fix 1 — Ambiguous behavior → explicit behavior

Before
“Percentages default to 100 when omitted, delay values must be capped at 5 minutes, and aborts default to HTTP 503 when status is not set.”

After
“Percentages default to 100 when omitted, delay values exceeding 5 minutes must be clamped to 5 minutes, and aborts default to HTTP 503 when status is not set.”

“Capped at 5 minutes” is ambiguous — does it reject values over 5min with an error, or silently clamp them? The fix makes the intended behavior (clamping) explicit.
Fix 2 — Vague reference → explicit list

Before
“browser.tables must provide the same find methods as browser.links. Tables must have headers (th text list, extracted from thead or first row th elements), rows (excluding header row and tfoot), and caption (text or None).”

After
“browser.tables must provide find_by_id, find_by_css, find_by_tag, and find_by_xpath methods. Tables must have headers (th text list, extracted from thead or first row th elements), rows (excluding header row and tfoot), and caption (text or None).”

“Same as X” forces the solver to reverse-engineer another API's interface. If that interface has methods you don't actually want, or is missing ones you do, the spec is silently wrong. Listing the methods explicitly removes ambiguity.

## Strong challenges share
- Real-world relevance
- Precise, behavior-focused specification
- Deterministic, aligned tests
- Large, meaningful solution implementation
- Clear boundaries and no hidden requirements
- Difficulty that challenges even advanced AI systems

> If top-tier models can pass your challenge with a high success rate, it is not challenging enough. You'll see the exact difficulty thresholds during creation.

---

# Hints

Hints are optional extra context appended to the agent's task prompt. They exist for problems that are genuinely too hard for agents to solve without guidance — not as a shortcut to improve pass rates.

## When to add a hint

Only consider adding a hint when all of the following are true:
- You have at least 20 unhinted runs with a 0% pass rate
- All other submission criteria are passing — fairness, long-horizon complexity, and model diversity
- Agents are failing due to capability limitations, not trivial mistakes, unfair tests, or broken infrastructure

## What makes a good hint

Every hint must pass the inferability litmus test: could a human expert, given only the problem description, have reasonably inferred this?

**Good hints:**
- Domain knowledge a senior engineer would know (e.g. "Rails migrations require updating seeds")
- Narrowing the search space (e.g. "The bug is in the authentication middleware")
- Clarifying ambiguous requirements from the description

**Bad hints:**
- Implementation details about a specific solution (e.g. "Add a `retryCount` field to the config struct")
- Information that could only come from reading the test patch
- Step-by-step instructions that reduce the problem to transcription

## Justification

When you add a hint, you must also provide a justification explaining why each piece of information is inferrable. Reviewers will check this — if a hint leaks implementation details, the submission will be sent back for revision.

## Hint quality check

Before running agents with hints, use the Hint Quality check in the Quality Checks panel. This AI-powered check reviews your hint against the test patch and reference solution to verify it doesn't leak implementation details.

## Running with hints

Once you've added a hint, enable the "Include hint" toggle in the Run Agents dialog. Hinted and unhinted runs are tracked separately. To pass submission criteria, you must still have at least 10 unhinted working runs showing a 0% pass rate before hinted runs count.

---

# Solving Challenges

Everything you need to craft high-quality solutions for Project Olympus challenges.

## Overview

Solving a challenge on Project Olympus means writing a minimal, focused patch that makes the failing tests pass. You'll clone the repository, understand the challenge, implement a fix, and submit your patch as a unified diff.

The solving process follows four steps:
1. **Choose a Challenge** — Browse available challenges and pick one that matches your skills
2. **Set Up Your Environment** — Clone the repo, build the Docker image, and verify the tests fail
3. **Write Your Solution Patch** — Implement a minimal fix and generate a unified diff
4. **Verify & Submit** — Test your solution in the container environment and submit for review

## Set Up Your Environment

```bash
git clone <repo-url> && cd <repo>
git checkout <commit-hash>
docker build -t olympus-problem .
docker run -it --network none olympus-problem
```

Why confirm failure first? Verifying that the tests fail before you start coding ensures you're working against the right baseline.

## Patch Requirements

- Only include changes necessary to solve the challenge
- Follow the existing code style of the repository
- Format as a unified diff patch (`git diff`)
- Ensure the patch applies cleanly to the repository at the specified commit
- Don't modify test files or the Dockerfile

## Tips for Success

- **Minimal changes:** Only modify what's necessary to pass the tests
- **Clean code:** Follow the project's conventions and style guides
- **No side effects:** Don't break existing functionality outside the scope of the challenge
- **Deterministic:** Your solution should work the same way every time it's evaluated