# Quest Olympus — Platform Onboarding Guide (verbatim, captured 2026-08-23)

This is the current in-app "Welcome to Quest Olympus" doc, pasted verbatim from the platform. It supersedes `Olympus Guides (stale 2026-08-23).md` (the prior capture, which predates C++/Java support and the frostdb example). Where this doc gives a generic instruction ("check the Submission criteria panel in the form"), that is intentional on the platform's part — those numbers change with product and are NOT meant to be hardcoded here. Treat CLAUDE.md's hardcoded LOC/pass-rate numbers as the last-known values layered on top of this; when they conflict, re-check the live in-app panel.

---

## 01 Welcome to Quest Olympus

Expect to read this doc multiple times until you get your first one or two approvals. Recommended to keep it open in a separate tab.

Submissions in Olympus are basically: creating a task similar to a GitHub issue, writing its tests, and the solution that will pass all of these new tests.

Submissions need to be challenging enough to challenge SOTA models. If you think you know what "challenging" means, you'll probably need to bump it up a notch.

## 02 How a submission works

A submission needs:

1. A repo and a commit hash — the codebase the task lives in, pinned to a single SHA.
2. A problem description — the task itself.
3. Tests — what defines success.
4. A solution — proof the task is solvable.
5. A Dockerfile — the environment everything runs in.

## 03 Pick a repo

### Requirements
- Public GitHub repository
- At least 1 commit in the last 12 months
- 500+ stars
- Production-level codebase
- Language: TypeScript, JavaScript, Python, Go, Rust, C++, or Java
- Permissive open-source license
- Optional: a GitHub issue URL describing the problem

### What makes a repo good
The requirements are the floor, not the goal. Repo depth decides the difficulty ceiling — a thin/flat repo caps difficulty no matter how good the idea is.

### Take care
- **R1** Don't use inactive or abandoned repositories.
- **R2** No existing PR solves it: open, merged, or closed. A closed/unmerged PR that already implements the idea still rules it out — not landing doesn't make it fresh. (#1 rejection reason.)
- **R3** Maintainers haven't declined it — check issues AND GitHub Discussions, not just PRs; design rulings live there. A declined feature counts as misalignment with the repo.
- **R4** Don't invent features that don't fit the project's philosophy. Read the README and get a feel for context before committing to an idea.

## 04 The problem description (the task)

- **P1** Aligns with the repo's philosophy
- **P2** Not already fixed in an open or merged PR
- **P3** Self-contained — solvable from the repo and description alone
- **P4** Clear, concise, unambiguous — no points left for guessing
- **P5** Verifiable — success is objectively testable
- **P6** Not prescriptive — don't leak the solution
- **P7** Not a duplicate — read the similarity-check results, don't treat it as a rubber-stamp gate; rewording/reshaping an existing task isn't new

### Writing it
Write it the way a maintainer writes an issue — natural prose, full sentences. Open with the ask itself ("Add X to Y", "Fix Z when..."); the first line should stand alone without the title. Skip motivation and "what the repo currently lacks" preamble.

No bulleted requirement lists, no headings, no code snippets doing the describing. Don't spell out what a developer in the repo would find on their own (internal class names, helpers, field names, file layout) — describe behavior, not implementation. Exception: if a detail is genuinely part of the contract and the task can't be pinned down without it, state it. A task nobody can implement is worse than one that names a field.

## 05 The tests

- **T1** Highlight the missing/incorrect behavior. 100% fail at base commit, 100% pass after the solution.
- **T2** Deterministic — no timing, randomness, or ordering; nothing that could change across runs or machines.
- **T3** Strong — not permissive enough to let inaccurate solutions pass.
- **T4** Extensive coverage — the requested behavior and all obvious edge cases.
- **T5** Do NOT check unspecified/undiscoverable behavior — unfair to expect agents to implement something not in the description or discoverable from the repo.
- **T6** No network required (containers run with `--network none`).
- **T7** Don't over-pin output — don't assert exact wording/formatting unless the description says so or it's obvious from the repo's existing patterns. Checking the behavior holds is enough.
- **T8** Keep failure diagnostics intact — a custom harness/reporter/JUnit adapter must not hide real failures behind hardcoded catch-all messages, mask upstream errors, or misreport what actually ran.

### The test.sh harness
`test.sh` at the repo root, included in the test patch, two modes:
- `./test.sh --output_path results.xml base` — runs the repo's existing tests as a regression check. Must pass. Writes JUnit XML.
- `./test.sh --output_path results.xml new` — runs the new/modified tests. Must fail without the solution patch applied.

Flaky/network-requiring/pre-existing-failure tests may be excluded. Do NOT exclude valid tests just because your solution breaks them. `base` must run the real tests for the touched area, not a token smoke test. No fail-fast flags — need every test result.

```bash
git diff > test.patch
git stash
git apply test.patch
git stash pop
```

**Common mistake: leaking the quest.** Treat these files like a real PR — no directories/files named "challenge", "quest", "olympus"; no test.sh comments referencing the challenge; no "Shipd / Olympus / mars" anywhere in the patches.

## 06 The solution

- **S1** Meets all requirements (if it's missing one and still passes your tests, you're in a bad position)
- **S2** No regressions, follows existing code patterns
- **S3** No irrelevant changes
- **S4** No AI-generated artifacts (weird comments, unexplained defensive code, new coding patterns)

## 07 The Dockerfile

- `FROM` one of the base images below.
- Install all dependencies at build time (`--network none` at runtime).
- `WORKDIR` must be `/app`.
- No test commands in a `RUN` step.
- End with `CMD ["/bin/bash"]`.
- Must work without test.patch/solution.patch applied — those are applied after the build.

### Base images
- Python: `public.ecr.aws/d3j8x8q7/olympus-base-python:latest`
- TypeScript/JavaScript: `public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest`
- Go: `public.ecr.aws/d3j8x8q7/olympus-base-go:latest`
- Rust: `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest`
- Java (JVM): `public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest`
- C++: `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-<language>:latest
WORKDIR /app
COPY . .
# Install everything needed here — the runtime container is offline.
CMD ["/bin/bash"]
```

## 08 Agent rollouts

A rollout = one agent given the description, the repo at the pinned commit, and the Docker environment; it writes a solution, then gets graded against the tests. A minimum number of finished rollouts is required before submission — check the "Submission criteria" panel on the submission form for the exact count (it changes with product). Runs only count once finished.

- **Quick check** — single cheap run, use while iterating.
- **Full batch** — several runs at once, use once confident.

Usually finishes in ~15 min; big repo/hard task can push to 90 min.

**Read results before editing.** Rollouts are pinned to the content they ran on — editing any field after a rollout finishes marks it stale (doesn't count, tokens gone). Triggering more rollouts mid-batch, if it forces an edit, stales the whole batch. One batch at a time, results first, edits second.

Read the fails: failing because the task is hard = good. Failing because a sentence was ambiguous = revision needed. Passing too often = too easy, harden before spending remaining runs.

## 09 Submitting

Each piece goes in its own field: description as text, test patch as a unified git diff (test.sh + new tests), solution patch as a unified git diff, Dockerfile pasted directly.

**Solvability:** at least one agent must solve the challenge before submission is allowed. 0% solved = tests too strict, description missing something, or task unfair — iterate before submitting. Legitimate failures get caught in review and sent back.

**Be your own reviewer first** — go through agent runs the way a reviewer will:
- Are the failures fair? Should fail because the task is genuinely hard, not ambiguity/hidden requirements/tests demanding something undescribed.
- Are you still clearing the LOC bar? Only *effective* solution lines count (implementing the task) — comments, blank lines, generated files, test code excluded. If agents solve it in fewer lines than your solution, your real count is probably lower than it looks.

## 10 Review it locally first

1. Clone the repo, check out the exact commit.
2. Apply test.patch.
3. Build the Docker image.
4. Run the container with `--network none`.
5. Run `./test.sh base` (must pass) and `./test.sh new` (must fail).
6. Apply solution.patch.
7. Rebuild, rerun both modes: both must pass.
8. Confirm no existing PR already solves the issue.
9. Confirm every point in this doc is satisfied.

```bash
git checkout <commit-hash>
git apply test.patch
./test.sh --output_path /tmp/base.xml base   # should pass
./test.sh --output_path /tmp/new.xml new     # should fail
```

## 11 Token system

- New contributors start with an initial token balance.
- Finalized approvals earn bonus tokens.
- Tokens replenish hourly based on contributor tier (approval rate + finalized-approval count).
- Running checks consumes tokens — be deliberate, fix everything spottable before rerunning.
- Clear checks before agent runs — checks are cheap relative to agent runs; don't spend on agent runs while a check is failing.
- Editing submission content after checks completed marks results stale → must rerun (costs tokens again).

## 12 Submission criteria

Different submission types have different bars (LOC, files touched, agent difficulty, etc.) and the numbers change with product — **always check the "Submission criteria" panel inside the form for the exact current bar**, don't rely on a hardcoded number from a prior session.

On LOC specifically: what counts is the *effective* solution — lines an agent actually has to write to implement the task and pass tests. Blank lines, comments, and padding (reordering unrelated code, etc.) are excluded; test code doesn't count at all. Improving tests doesn't move LOC, only the solution does. Judge ideas by the solution they force, not the size of the whole diff.

## 13 A complete approved example — Go · frostdb (Approved)

frostdb answers grouped aggregation queries by splitting a table into independent partitions, aggregating each partition on its own, then combining partial results into one row per group. Aggregations must return the same answer regardless of how rows are spread across partitions or how many partitions exist.

Task: add support for distinct aggregations (`count(distinct x)`, `sum(distinct x)`, `avg(distinct x)`, plus variance/stddev, median, geometric/harmonic mean, group_concat families) — each ignoring nulls, each reached through ordinary grouped SQL, coexisting with existing aggregations unchanged.

- Repo: `https://github.com/polarsignals/frostdb`, commit `9e5cfe0171adff531d30a9df3e111686996f4a9f`
- Dockerfile: `olympus-base-go`, `go mod download`, installs `go-junit-report`, `GOFLAGS=-mod=readonly`, `CGO_ENABLED=0`, `go build ./...`, `CMD ["/bin/bash"]`
- test.sh: fixed `GOMAXPROCS=4` for determinism across partition counts; `base` mode runs real package tests minus two deliberately-excluded ones (a memory-overflow test that can't run in a fixed-memory offline container, and a flaky statistical-sampler test) — every exclusion has a documented reason inline; `new` mode runs `^TestHA_` in `./challenge/...`.
- Tests: 632-line new file, ~49 tests across 8 aggregation families, arrow-record builder + assertion helpers, `assert_eq!`-style exact checks (e.g. `TestHA_CountDistinctAcrossPartitions` — 3 distinct values split across two partitions, expects exactly 3).
- Solution: 10 files across `query/logicalplan`, `query/physicalplan`, `sqlparse` — new aggregation types desugared into existing sum/count building blocks at the logical-plan level (e.g. `AggFuncAvgDistinct` rewrites to `sum(distinct)/count(distinct)` with a type-aware cast), then wired through physical execution and the SQL parser.

## 14 Tips

1. **Plan the scope before writing patches.** It's tempting to treat this like a normal OSS contribution — find something, write tests, submit. Only works when the scope is there. Figure out if the task is too trivial *before* writing 600 lines of solution, not after.
2. **Consider cross-cutting changes.** A solution spanning several layers/subsystems tends to be harder for agents (and carries more effective LOC) than one confined to a single spot. Not a requirement, but a good lever when difficulty or LOC keeps landing short.
3. **Be smart about spending tokens.** Don't run a full batch the moment you finish writing. Clear checks first, start with a small batch for a vibe check: 100% pass = too easy, 0% on a vague/unfair point = fix before committing more runs.
4. **Read the check and agent run outputs.** A 0% pass rate isn't always "bad task" — sometimes one ambiguous sentence or one unfair test. Agent logs are the fastest way to spot it.
5. **Expect to iterate.** Refining until the obvious issues are ruled out is the path to a clean approval with no reviewer back-and-forth. Every loop closed yourself is one not paid for in revision cycles.
