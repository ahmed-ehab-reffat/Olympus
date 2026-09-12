# OFFICIAL-RUBRIC — Shipd Olympus guide (SOURCE OF TRUTH for feedback codes)

Verbatim from the platform guide: <https://shipd.ai/quests/olympus/docs/problem> (captured 2026-07). Reviewers now cite these codes in feedback (e.g. "P6", "T3"). Every submission must satisfy EVERY point. When feedback names a code, look it up here for the exact requirement. This is the platform's own bar; where our internal instruction files add nuance, THIS file defines what the code means.

> Reference these codes while authoring AND while self-reviewing (the guide's "Be your own reviewer first" step). A submission is measured against all R/P/T/S points below plus the Dockerfile + solvability + LOC rules.

---

## R — Pick a repo ("Take care")

- **R1** — Don't use inactive or abandoned repositories.
- **R2** — **No existing PR solves it** — open, merged, or closed. A closed or unmerged PR that already implements your idea still rules it out; not landing doesn't make it fresh. (The #1 rejection reason.)
- **R3** — **The maintainers haven't declined it** — check the issues and GitHub Discussions, not just PRs; that's where design rulings live. A declined feature = misalignment with the repo.
- **R4** — Don't invent nonsensical features that don't fit the project's philosophy — read the readme and get a feel for the context before committing to an idea.

Repo requirements: public GitHub repo; ≥1 commit in the last 12 months; 500+ stars; production-level codebase; language TypeScript / JavaScript / Python / Go / Rust / C++ / Java; permissive license (see list — **if MULTIPLE licenses, ALL must be allowed; one non-allowed = whole-repo reject**); optional GitHub issue URL. Allowed families: MIT, BSD (the listed variants), Boost (BSL-1.0), BLAS, GNU-All-permissive, Apache-2.0 (+ variants), CC-BY. NOT GPL/AGPL/LGPL. **"OSI-approved" is NOT the test:** CC-BY is allowed though non-OSI; NCSA is a hard reject though OSI-approved; conditional/rider BSD (extra conditions bolted on) is a hard reject. Read the actual LICENSE file, match the explicit list.

---

## P — Problem description (the task)

- **P1** — Aligns with the repo's philosophy.
- **P2** — Not already fixed in an open or merged PR. (Duplicate of R2 — stated again because it is the top reject.)
- **P3** — **Self-contained** — solvable from the repo and description alone.
- **P4** — **Clear, concise, and unambiguous** — describes what to build or fix; leaves no points for guessing.
- **P5** — **Verifiable** — success is objectively testable.
- **P6** — **Not prescriptive** — don't leak the solution; we want to challenge the agents.
- **P7** — **Not a duplicate** — a similarity check runs against existing submissions. Not a gate: open the results, read the close matches, confirm you're not rebuilding an existing problem. Rewording the same task or reshaping the same behavior doesn't make it new.

Writing style: write it the way a maintainer writes an issue — natural prose, full sentences. Open with the ask ("Add X to Y", "Fix Z when …"); the first line stands on its own without the title. Skip motivation and the "what the repo currently lacks" preamble. No bulleted requirement lists, no headings, no code snippets doing the describing. Describe the BEHAVIOR, not the implementation (no internal class/helper/field names or file layout) — but use judgment: if a detail is genuinely part of the contract and the task can't be pinned down without it, state it. A task nobody can implement is worse than one that names a field.

---

## T — Tests (hidden from the agent)

- **T1** — Highlight the missing or incorrect behavior. **100% FAIL at the base commit and 100% PASS after the solution.**
- **T2** — **Deterministic** — no timing, randomness, or ordering; nothing that changes across runs or machines.
- **T3** — **Strong tests.** Not permissive enough to let inaccurate agent solutions pass.
- **T4** — **Extensive coverage.** Cover the requested behavior AND all the obvious edge cases.
- **T5** — **DO NOT check unspecified or undiscoverable behavior** — unfair to expect agents to implement something not in the description or discoverable from the repo.
- **T6** — No network connection (container runs `--network none`).
- **T7** — **Don't over-pin the output** — don't assert exact output (error text, messages, wording, formatting) unless the description says so or it's obvious from the repo's existing patterns. Checking the behavior holds is enough; over-pinning is unfair to an agent that gets the behavior right but words it differently.

### test.sh harness
- Root-level `test.sh`, included in the test patch, two modes:
  - `./test.sh --output_path results.xml base` — runs the repo's EXISTING tests in the change's blast radius (a genuine regression check, not a token smoke test). MUST PASS. Writes JUnit XML.
  - `./test.sh --output_path results.xml new` — runs your new/modified tests. MUST FAIL without the solution patch.
- May exclude existing tests that are flaky, need network, or fail for pre-existing issues. **Do NOT exclude valid tests because your solution breaks them.**
- **No fail-fast flags** — every test result is needed, not just the first failure.
- JUnit XML per framework: pytest `--junitxml`; vitest `--reporter=junit --outputFile`; jest `jest-junit` (preinstalled); go `go test -v … | go-junit-report -set-exit-code` (the `-v` is required); mocha `mocha-junit-reporter` (preinstalled); deno `--junit-path`.
- Generate the test patch with `git diff > test.patch`; verify via `git stash && git apply test.patch && git stash pop`.
- **No quest leaks:** no dirs/files named "challenge"/"quest"/"olympus"; no `test.sh` comments referencing the challenge; no "Shipd/Olympus/mars" anywhere. Treat the patches like a real PR.

---

## S — Solution (the golden solution)

- **S1** — Meets ALL requirements. (If it misses a requirement yet still passes your tests, the tests are too weak.)
- **S2** — **No regressions** and **follow existing code patterns.** Don't break existing working code (the repo's existing tests still run).
- **S3** — **No irrelevant changes** — anything unrelated to the task stays as it is.
- **S4** — **No AI slop** (weird comments, unexplained defensive code, new coding patterns).

---

## Dockerfile

- `FROM` a base image below (match the repo language).
- Install ALL dependencies at build time (`--network none` at runtime).
- `WORKDIR /app` (tests run from there; other paths break imports / editable installs / relative paths).
- **No test commands in any `RUN` step** — the build sets up, it doesn't test.
- End with `CMD ["/bin/bash"]`.
- Must build WITHOUT `test.patch` or `solution.patch` applied (they are applied after the build).

Base images (`public.ecr.aws/d3j8x8q7/olympus-base-<lang>:latest`) — **all six SUPPORTED per the guide, incl. jvm + cpp:**

| Language | `<lang>` |
|---|---|
| Python | `python` |
| TypeScript / JavaScript | `typescript` |
| Go | `go` |
| Rust | `rust` |
| Java (JVM) | `jvm` |
| C++ | `cpp` |

---

## Submitting + solvability + LOC

- Fields: problem description (text), test patch (unified git diff with `test.sh` + new tests), solution patch (unified git diff), Dockerfile (pasted).
- **Solvability:** at least ONE agent must solve the challenge before you can submit. If none ever pass → tests too strict, description missing something, or task unfair — iterate first.
- **Be your own reviewer first:** walk your agent runs like a reviewer. Are the failures FAIR (genuinely hard, not ambiguous/hidden/undocumented)? Are you still clearing the LOC bar?
- **LOC — only EFFECTIVE solution lines count** (the ones that implement the task). Blank lines, comments, generated files, and test code do NOT count. Reordering unrelated code / padding does NOT count. If agents solve it in noticeably fewer lines than your solution, your real count is lower than it looks. (See `SOLUTION.md` + `CLAUDE.md` for the two-counter detail: platform auto-block keeps braces; the human reviewer's meaningful-LOC strips braces/imports/no-ops/boilerplate too.)
- **Submission criteria panel** in the create form shows the EXACT bar for the assignment (LOC / files / difficulty / etc.) — it changes with the product; read it there.

## Local review (do exactly what reviewers do, before spending tokens)
1. Clone + checkout the exact commit. 2. Apply `test.patch`. 3. Build the Docker image. 4. Run with `--network none`. 5. `./test.sh base` (must pass) + `./test.sh new` (must fail). 6. Apply `solution.patch`. 7. Rebuild + rerun both modes (both must pass). 8. Confirm no existing PR solves it. 9. Confirm every point in this rubric is met.

## Tokens
New contributors start with a balance; finalized approvals earn bonus tokens; tokens replenish hourly by contributor tier (approval rate + finalized approvals). Running checks consumes tokens — fix everything you can spot before rerunning. Editing any content after checks completed marks results STALE; stale checks must be rerun before submit (costs tokens again). Fix all issues in one pass.

## Canonical approved example
Go / polarsignals/frostdb — "Add distinct + holistic aggregations" (count/sum/avg distinct + variance/stddev/median/geo-harmonic mean/group_concat), commit `9e5cfe0171adff531d30a9df3e111686996f4a9f`. Solution touches 10 files across `query/logicalplan`, `query/physicalplan`, `sqlparse`; new tests are `TestHA_*` in a `challenge/` package; base mode runs real query-engine tests by name, excluding a deliberate OOM test + a flaky randomness test with a documented reason; `GOMAXPROCS=4` pins engine parallelism for determinism.

---

## Feedback-code quick map (when a reviewer cites a code)

| Prefix | Area | Most-cited |
|---|---|---|
| R1-R4 | repo choice | R2 (existing PR), R3 (maintainer declined) |
| P1-P7 | description | P6 (prescriptive/leaks solution), P4 (ambiguous), P3 (not self-contained), P7 (duplicate) |
| T1-T7 | tests | T3 (too weak/permissive), T5 (undiscoverable req = unfair), T7 (over-pinned output), T1 (fail-on-base/pass-after) |
| S1-S4 | solution | S4 (AI slop), S2 (regression), S3 (irrelevant changes) |

Cross-ref: `DESCRIPTION.md` (P-codes deep dive), `TESTS.md` (T-codes + JUnit), `SOLUTION.md` (S-codes + LOC), `DOCKER.md` (base images), `RULES.md` (repo requirements + caps). `PRINCIPAL-REVIEWER-RUBRIC.md` is the human-reviewer's extra 10 blockers ON TOP of these platform codes.
