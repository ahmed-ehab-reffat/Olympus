---
name: olympus-hunt
description: Use when SOURCING new target repositories for Olympus challenges — the stage BEFORE authoring. Finds niche, unsaturated repos in Go, Rust, Python, TypeScript/JavaScript, C++, or Java (500+ stars, permissive license, active, pure-language, live upstream — issue count and commit velocity are ranking signals, NOT gates) and scores each for trap-seam potential against the measured patterns in failure-patterns.md, plus capability-lane availability, so the shortlist is ranked by whether the repo can still carry an authorable pick at all. Runs the six mechanical hard requirements, the local dedup/saturation check (SATURATED-REPOS.md + problems/ + rejected/ + approved-problems/), the capability-lane-density triage, the maintainer-welcomed-lane search, a Docker-feasibility estimate, and emits a per-candidate dossier. Triggers when the user says "find repos", "hunt repos", "new targets", "repo recon", "candidates for Olympus", "repos similar to X", or asks what to author next with no repo chosen. Hands off to olympus-author once a candidate is scope-locked. Source of truth: Instructions/PICK-FILTER.md (10 gates), Instructions/RULES.md (repo + license rules), Instructions/SATURATED-REPOS.md (blocklist), failure-patterns.md (trap-seam targeting), Instructions/TOO-EASY.md (dead classes).
---

# Olympus Repo Hunt — sourcing targets that can carry a hard problem

Upstream of `olympus-author`. The output is a **ranked shortlist of repos with a trap thesis
for each**, not a list of repos. A repo that passes every mechanical filter but has no seam is
a dead target — most wasted authoring cycles start there.

**The governing insight** (`failure-patterns.md` L1/L2): difficulty comes from repos that are
*globally coupled* — a pipeline stage that destroys information, a construct that is both
producer and consumer, an analysis that must reach a fixed point. Repos whose features are
independently implementable cap out around 67% pass no matter how many rules you write. Hunt
for the seam, not the star count.

**Two seams to prioritise, and why they beat the rest per unit of authoring effort.** A repo
that offers a **stage boundary** (F-9) and **two form axes** (F-10) can carry a full submission
on those alone — measured 20% on neva with no other lead trap. F-9 gives interdependence for
free (one root cause breaks every capability at once, which is what the calibration model asks
for and what bolting on a second mechanism usually fails to deliver), and F-10 is the only
pattern measured to separate the 20/21 near-misses from the passes. Both are structural, so you
can confirm them from the source tree during this hunt — unlike F-1, which you cannot identify
until you have read a batch's passing patches.

Time budget: 30-40 min for a 3-5 candidate shortlist. Stages 2c and 2d are the cheapest minutes in
the hunt — 2c kills a repo whose lanes are gone before you audit its seams, and 2d finds a lane the
maintainer has already blessed.

---

## Stage 0 — Set the search space (2 min)

Ask the user for `{EXAMPLE_REPOS}` if not given. Good anchors from our own history:
**bunster** (shell compiler), **dasel** (query language), **cliffy** (CLI framework),
**calyx** (HDL compiler), **pulldown-cmark** (markdown parser).

Derive the search axes from the anchors — domain, not name. All five are
*language-or-format processors with a multi-stage pipeline*. That is the shape to search for.

---

## Stage 0-bis — MINE THE PROVEN-REPO POOL FIRST (added 2026-09-01, after four cold-start picks died)

⚠️ **Do this BEFORE any GitHub sweep.** A cold hunt is the low-probability path, and the corpus says so.

**The evidence.** Across `approved-problems/` + `problems/` + `rejected/`, the ~39 repos carrying
frontmatter host multiple problems each — starlark-go 3, gluon 3, numbat 2, python-control 2, lyon 2,
ezdxf 2, yara-x 2, pcapplusplus 3, amaranth 2, customasm 2, rmk 2. **The corpus re-mines repos that
already worked.** Four consecutive cold-start picks (geometry-central, choco-solver, thermo,
handlebars-rust) died at absorption or prior art; every one of them was a repo nobody here had ever
shipped from.

**Why a proven repo is strictly better odds:**
- It has DEMONSTRATED it hosts a non-absorbed capability — which is precisely what the four cold
  picks each failed to.
- Every mechanical measurement is already paid for: licence, stars, activity, live-upstream, Docker
  pattern, flakiness baseline, test conventions, JUnit wiring.
- There is a calibrated `meta.md`, `DESIGN.md` and `feedback.md` to scaffold against, and a known
  pass rate to aim at.
- Quota is `<= 6` per repo, so a repo at 1-2 has room for 4 more.

```bash
# Build the pool: repos we have shipped from, with counts
for f in approved-problems/*/meta.md problems/*/meta.md rejected/*/meta.md; do
  grep -m1 '^Repository:' "$f" | sed 's|Repository: *||; s|https://github.com/||; s|/*$||'
done | grep -E '^[^/]+/[^/]+$' | sort | uniq -c | sort -n
```

**Then, for each candidate at 1-2 subs:** confirm it is still live, run **Stage 2b-bis PR-author
profiling**, and pick a **different SUBSYSTEM CLASS** from the one already shipped (the self-collision
rule is subsystem-level, not repo-level — see the comrak note in Stage 2b).

⚠️ **Read the COMMIT stream, not the PR queue** — the rapier lesson bites hardest here, because a
proven repo is usually a small repo with one maintainer who pushes directly. **Measured on neva
2026-09-01:** the PR queue is 2 PRs, all `emil14`, all ci/test/docs — reading maintenance-only. The
commit stream for the same window is **300 commits** and shows a whole formatter subsystem built in
August (`Add neva fmt command`, `Add nevafmt renderer`, `Add nevafmt parser foundation`), plus
`Implement stream synchronization`, union literals, an os package and a portable type descriptor.
Feature phase, invisible through the PR lens.

**Pool status measured 2026-09-01** (all under the 6-cap):

| Repo | Subs | Read |
|---|---|---|
| nevalang/neva | 1 | Go dataflow compiler+runtime, MIT, ★1079. ⚠️ **Re-measured 2026-09-09: the "cold" reading below was STALE and partly a moved-path artefact.** 12mo heat is now `parser` 89, `analyzer` 100, `desugarer` 50, `irgen` 41, `backend` 73, `runtime` 100, `std` 100; `internal/interpreter` and `internal/compiler/sourcecode` DO NOT EXIST (their 0/14 was the artefact). Competitor-CLEAN (solo `emil14`, no outside PRs) and CI green, but analyzer+desugarer+irgen are the approved pick's own span -> self-collision, typesystem is his current workstream, and he runs a documented AI-assisted papercut sweep |
| calyxir/calyx | 2 | MIT ★612 HDL compiler, 15 open PRs mostly dependabot. The 13-batch flagship; frontend/emitter/scheduling untouched |
| tokio-rs/turmoil | 1 | MIT ★1255, but `marcbowes`/`mcches` actively adding turmoil-fs, io_uring, turmoil-net, fault injection — capability-consuming |
| VirusTotal/yara-x | 2 | **CONTESTED** — `king-tero` (5 repos, 4 followers, no identity) filed SEVEN perf PRs on 2026-08-30 across parser/wasm/compiler/scanner/regex, active only on yara-x + own fork |
| quickwit-oss/tantivy | 1 | ★16021 (well past the 5000 penalty band) and maintainer `fulmicoton` is mid-build on "calculated fields in aggregation" — collides with our own approved pipeline-aggregations pick |
| nical/lyon | 3 | **2026-09-01-C RANK 1, ALL 10 GATES CLEARED (see the hunt log Stage 6).** MIT/Apache ★2596, 0 open PRs, no competitor, 38 fix-only commits/12mo. tessellation consumed by all 3 subs; `algorithms`/`path`/`geom` cold. Lead: S-C inversion of the builder's shape emitters (rounded-rect + ellipse recognition, ~400-450 eff, 3 crates) |
| acoular/acoular | 1 | **RANK 2.** BSD-3 ★650, no competitor, our first pick landed 7.7%. tbeamform/sources/trajectory cold. Lead: moving sources + trajectory beamformer in a convected medium (~250-300 eff). ⚠️ pytest-regtest auto-snapshots EVERY Generator subclass (441 files): add traits to existing classes, never a new Generator |
| sfepy/sfepy | 1 | **RANK 3.** BSD-3 ★838, no competitor, rc ships monthly in fields/LCBC/homogenization (avoid). solvers/ts_* cold (a live `NameError` at ts_controllers.py:128 proves it). Lead: accountable adaptive time stepping + restart (~325 eff, 5 files) |
| 11 other pool repos | 1-3 | **competitor-visited or dead** on 2026-09-01-C — mpmath, scikit-rf, PlasmaPy, MetPy, QuantEcon, mp4ff, moov-ach, numbat, verde, lifelines, avo, tinywasm, pyamg. See `SATURATED-REPOS.md § B3-bis` and the hunt log's account table |

---

## Stage 1 — Hard requirements (MECHANICAL — run before reading a single README)

**Six binary rejects, and nothing else.** Everything that used to be a seventh and eighth gate is
now a SIGNAL (below the table) — they were rejecting good repos, which is the expensive direction
of error. A repo that clears these six is eligible; whether it is *worth* authoring is decided by
the capability check in Stage 2c and the seam audit in Stage 3, not by more repo-level filters.

| # | Requirement | Why |
|---|---|---|
| 1 | **stars ≥ 500** (`RULES.md` floor). No ceiling — but 5000+ is a PENALTY band | <500 = platform-invalid. High stars = more training data AND faster global saturation, so score 5000+ down and verify the platform sub-count before authoring. It is not a reject; the 10000 cap was arbitrary and cost us candidates |
| 2 | **Go, Rust, Python, TypeScript/JavaScript, C++, or Java** | This hunt's scope. **Python added 2026-08-07; TypeScript/JavaScript, C++ and Java added 2026-08-11** — all four base images (`olympus-base-typescript`, `olympus-base-cpp`, `olympus-base-jvm`, plus `olympus-base-python`) are supported per `DOCKER.md`. See § Python notes and § TS/JS/C++/Java notes below — each carries a different trap mix and its own extra gates |
| 3 | **≥1 commit in last 12 months** | `RULES.md` repo requirement |
| 4 | **Permissive license** — MIT, BSD (any clause), Apache-2.0, Boost/BSL-1.0, CC-BY | GPL/AGPL = hard reject |
| 5 | **Pure-language implementation** — no CGO / no `-sys` C bindings, **in the TEST build path as well as the lib** | Docker builds offline and fast |
| 6 | **This repo is where development HAPPENS** — not an abandoned upstream of a fork, and **the last 12mo must contain real CODE commits, not only docs/README/CI** | A starred corpse reads `archived:false` with recent `pushed_at` and gorgeously cold core dirs. Killed a full mtail seam audit; see `SATURATED-REPOS.md § E`. ⚠️ Measured 2026-08-05: bunster (★2675) shows `pushed:2026-04-28` and 8 commits/12mo — **all 8 are docs/README typo fixes, zero code in a full year**, and every fork is ★0 so there is no livelier home. Read the commit SUBJECTS, never the count or `pushed_at`; a `docs:`/`chore:`-only stream is a corpse and will trip the platform's active-maintenance precheck |

### ⛔ Requirement 7 — THE REPO RUNS ITS OWN TESTS IN CI, AND THEY PASS (added 2026-09-01)

**One API call. Run it with the other mechanical gates — it is the cheapest gate in this file and it
predicts base-mode health, which every submission depends on.**

```bash
R=owner/repo
ls .github/workflows/            # is there a workflow that RUNS TESTS (not just lint/codespell)?
gh run list -R $R --limit 8 --json conclusion,name,createdAt -q '.[]|"\(.createdAt[0:10]) \(.conclusion)  \(.name)"'
grep -iE "numpy|scipy|pandas|networkx" setup.py pyproject.toml   # are deps PINNED?
```

**Reject when:** there is no test-running workflow, or the test workflow FAILS ON THE DEFAULT BRANCH,
or the runtime deps are entirely unpinned. All three mean the baseline is a moving target you cannot
rely on, and **base mode must PASS** for every submission.

⚠️ **Softened 2026-09-09-B (user decision): read the CONCLUSION of runs on the default branch, not the
latest rows.** `action_required` means a fork PR is waiting for a maintainer to approve the workflow
run, not a failing suite; `cancelled` is superseded pushes. Filter with
`gh run list -R $R --branch <default> --limit 8` and reject only on `failure` there. Today's run
killed argmin and nearly koto on `action_required` rows, which is a reject the platform would never
have made. When in doubt, build and run the suite yourself (it is owed at Stage 3 anyway).

**Measured 2026-09-01 — this killed a candidate that had cleared every other gate in this skill.**
`py-why/causal-learn` passed mechanical, dedup, PR-author profiling, Phase 2 on issue bodies,
absorption (verified locally), the port check, the sibling-ecosystem check (verified by cloning
TETRAD), self-collision and the S-F shape test. Then:
- its **only** workflow is `codespell.yml` — a spellchecker. **No workflow runs the test suite.**
- deps are unpinned (`'numpy'`, `'scipy'`, `'scikit-learn'`, `'pandas'`, `'networkx'` — no bounds)
- the suite has **5 deterministic failures** (identical across 3 runs) — `TestFCI::test_continuous_dataset`,
  `TestFCI::test_bnlearn_discrete_datasets`, and three in `TestBackgroundKnowledge` — sitting in the
  EXACT lane the capability targeted, so they could not be legitimately excluded from base mode
  (excluding the tests that cover the code you modify is the L31 anti-pattern and a certain reviewer
  finding)
- `TestPC` alone exceeds **600s**, making the mandatory 3-5x flakiness runs and the platform harness
  impractical

**A green baseline is not a formality — it is a precondition.** A repo with no test CI has never
promised one, and unpinned deps mean it can rot again between authoring and the platform run.
⚠️ Do not mistake a passing CI badge for a test run: check the workflow NAMES.

**SIGNALS, not gates** — record them in the dossier, let them rank candidates, never reject on them alone:

- **Open-issue count.** The old "100-1000 open issues" gate is RETIRED as a reject. It was relaxed
  in nearly every hunt, and the repo that finally produced an authorable pick — **comrak, with 9
  open issues** — would have been rejected outright by it. A lean tracker means a maintainer who
  closes things, not a narrow surface. Read it the other way now: >1000 open issues is a mild
  negative (sprawl), and a tracker under ~30 is a mild positive (responsive maintainer, and your
  Gate-8 philosophy check is cheap to run). The authorable surface lives in the CODE, not the
  tracker. **Softened 2026-09-09-B (user decision):** zero open issues / zero PRs / "no core requests
  in the tracker" is a RANKING PENALTY, never a reject on its own — some maintainers simply close
  things. A shallow clone plus one sketched lane overrules it.
- **⚠️ Published support matrix = HEAVY ranking penalty (added 2026-09-11).** If the repo's README or
  docs carry a conformance / support TABLE of the standard it implements — a CSS property grid, a
  supported-opcode list, a spec checklist, any ✅ Works / 🚧 Planned matrix — then that table is a
  public, pre-ranked, pre-filtered pick list, and its incomplete rows are exactly what every rival
  author picks. Treat each "Planned" row as presumptively CLAIMED. This is NOT the
  maintainer-wants-it mitigation it resembles: dropflow's README marked min/max sizing "Planned"
  directly above a `position: absolute` row a public PR was already implementing, the audit logged
  that as a mitigation, and the pick died at precheck on 70.3% overlap with an older same-repo
  submission. A repo whose deep lanes are all rows of such a table should rank BELOW an equivalent
  repo without one. See `TOO-EASY.md § Repo publishes a support matrix`.
- **Commit velocity and file churn.** NOT a reject in either direction — see the corrected Gate 5
  below. Only capability collision kills.
- **Already in the workspace.** Not automatically dead. A repo you cloned and shelved for a
  capability reason still has its other subsystems available, and its licence/build/determinism
  measurements are already paid for. Check `SATURATED-REPOS.md` and the ≤6 quota (Stage 2), then
  reuse the audit.

### 🐍 PYTHON NOTES (added 2026-08-07) — same bands, different trap mix, two extra gates

Python is in scope. Our own approved set is 9/9 Go+Rust, but that reflects where we looked, not a
ceiling: the doctrine already rests on Python cases (`pyomo-dae-mesh-refinement` is the worked
example for recovering a 0% batch in `HARDENING.md § 3c-bis`; `lark-counterexamples` is "the
canonical precedent" for the disclosure lever in `KNOWLEDGE.md`).

**Trap catalogue transfer.** Most of it survives, including every top killer — F-1, F-2, F-3, F-5,
F-6, F-7, **F-9**, **F-10**, F-11, **F-13**, F-14, F-15, **F-17**, F-18, **F-20**, **F-21**, **F-23**, **F-24**, **F-25** are all language-agnostic.

- **LOST in Python:** **F-16** (unparameterised setter) is valuable precisely *because* it is a
  COMPILE error; in Python it degrades to a runtime `TypeError` and measures nothing. **F-12**
  (inline `#[cfg(test)] mod tests` calling a private fn) is a Rust idiom with no Python analogue.
  A1/A11 compile-wall classes weaken.
- **CHANGES CHARACTER:** **S6** is built on "one compiler-FORCED path (exhaustive match) + one
  SILENT path". In Python BOTH paths are silent. That makes silent-drop traps (F-9) *more* potent,
  but removes the discoverability anchor the compiler provided — so budget extra care on fairness,
  because the agent gets no type error steering it to the sites.
- **GAINED:** A4 host-language-semantics traps, and Python is rich in them — mutable default
  arguments, late-binding closures, the `__eq__`/`__hash__` contract, MRO / cooperative `super()`,
  descriptors, shallow-vs-deep copy, iterator exhaustion, `__slots__`. Fair when the repo's own
  source demonstrates the correct pattern.

**⚠️ LOC is NOT a reason to prefer Python, and may cut against it.** The tempting argument is that
Counter 2 strips brace/punctuation-only lines and Python has none, so Python dodges the 15-30% brace
tax Rust and Go pay. That does not survive contact: Python is also far denser per line, so the same
capability is fewer RAW lines, and its "there is a library for that" culture makes **machinery
absorption** (the `canvas-fill-rule-backends` death) MORE likely, not less. Treat the LOC floor as
at least as hard in Python and sketch the DIFF before ranking.

**⚠️ SATURATION RISK IS HIGHER.** `SATURATED-REPOS.md`'s central law is that submission count tracks
AUTHOR-OBVIOUSNESS, not stars — and sqlglot (**62 subs**, the second-most saturated repo recorded)
is Python. Python has far more household-name libraries than Rust does. So the obscure-domain rule
matters MORE here: **avoid anything SQL, datetime, HTTP, ORM, serialization-of-a-famous-format, or
generally famous.** Prefer schema/validation engines, template engines, static analyzers,
packet/binary parsers, constraint and scheduling engines, config languages, scientific DSL pipelines.

**Two extra mechanical gates for any Python finalist:**

```bash
# G-PY1. HASH-SEED DETERMINISM (direct hit on the mandatory flakiness gate).
#   `set` iteration order varies across runs under hash randomization, and it is invisible if you
#   only run the suite once. Run WITHOUT pinning the seed, three times, and diff.
for i in 1 2 3; do python -m pytest -q 2>&1 | tail -1; done          # must be identical
grep -rn "PYTHONHASHSEED" tox.ini setup.cfg pytest.ini pyproject.toml 2>/dev/null  # a pin here HIDES the risk
grep -rnE "for .* in (set\(|\{)" --include=*.py . | head            # set-iteration order dependence

# G-PY2. C-EXTENSION TEST EXTRAS (the Python twin of the Rust [dev-dependencies] lesson).
#   Pure-Python repos are EASIER to Dockerise than Rust; scientific ones are worse.
grep -rnE "numpy|scipy|lxml|pillow|pandas|pyarrow|cryptography|psycopg2" \
  pyproject.toml setup.py setup.cfg requirements*.txt 2>/dev/null | head
```

Seam probes in Stage 3 need `--include=*.py` alongside the `*.rs` / `*.go` variants. Docker is
Pattern B with `olympus-base-python`; JUnit is `pytest --junitxml="$OUTPUT_PATH"`.

### 🌐☕ TS/JS, C++, JAVA NOTES (added 2026-08-11) — same bands, three more trap mixes, extra gates each

All three are in scope, unaudited by any approved submission yet (our 9/9 approved set is still
Go+Rust, and no TS/C++/Java pick has been run through this skill before) — treat early candidates
in these languages as higher-uncertainty on pass-rate calibration until a first batch confirms it.

**Trap catalogue transfer — language-agnostic core survives everywhere:** F-1, F-2, F-3, F-5, F-6,
F-7, F-9, F-10, F-11, F-13, F-14, F-15, F-17, F-18 do not depend on host-language mechanics and
apply to all three the same way they do to Go/Rust/Python.

**TypeScript / JavaScript**
- **GAINED:** structural typing gaps (an interface satisfied by accident), `this`-binding traps,
  prototype-chain / `Object.assign` shallow-copy bugs, async ordering (`Promise.all` vs sequential
  `await`, microtask-vs-macrotask), closures-over-loop-variable (`var` vs `let`), `==` vs `===`
  coercion. F-16-style "unparameterised setter" partially SURVIVES in TS (a compile error under
  `strict`) but LOSES it entirely in plain JS (runtime-only, same degradation as Python).
- **RISK:** TS/JS has the largest std-lib-equivalent surface of any language here (lodash-shaped
  helpers, `Array.prototype` methods) — triviality filter (`CLAUDE.md`) bites hardest here. Avoid
  anything that reads as "reimplement a well-known JS utility."
- **Docker:** Pattern B, `olympus-base-typescript`. JUnit: `deno test --junit-path=...` (Deno repos)
  or the platform's documented JS/TS JUnit reporter for Node repos — confirm which runtime the
  target repo uses before assuming Deno tooling.
- **Extra gate G-TS1 (determinism):** Node/Deno `Object.keys`/`for...in` order is insertion-order
  for string keys (NOT hash-random like Python/Go), so the classic set/map-iteration flakiness risk
  is lower here — but `Promise`/timer-based tests are the dominant flakiness source instead. Grep
  for `setTimeout`, unawaited promises, and `Date.now()`/`Math.random()` without a fixed seed.

**C++**
- **GAINED:** iterator invalidation, dangling reference / use-after-move, UB from signed overflow,
  template SFINAE / overload-resolution surprises, RAII-ordering (destructor sequencing), implicit
  conversion chains, `const`-correctness gaps. These are some of the strongest host-language traps
  available in this hunt — a repo whose own source relies on a subtle ownership or lifetime
  invariant is a strong F-4-adjacent seam.
- **RISK — the dominant one:** build system and dependency complexity. CMake/Bazel/Make repos with
  vendored or system deps (Boost, fmt, protobuf, OpenSSL) are the C++ analogue of the Rust
  `[dev-dependencies]` -sys trap — check the build file BEFORE clone, not after.
  ```bash
  grep -riE "find_package|FetchContent|vcpkg|conan" CMakeLists.txt 2>/dev/null | head
  ```
  Prefer repos with header-only or vendored-and-committed dependencies (no network fetch at build
  time) per the `nlohmann/json` FetchContent-offline pattern already validated in `DOCKER.md`.
- **Docker:** Pattern B, `olympus-base-cpp`. Verified toolchain + footguns: `DOCKER.md`. No JUnit
  reporter is native to most C++ test frameworks — Catch2/GoogleTest both support
  `--reporter junit` / `--gtest_output=xml:` flags; confirm the repo's existing framework supports
  one before scope-lock.
- **Extra gate G-CPP1 (build-time dep gate, mirrors the Rust `[dev-dependencies]` check):** read
  the FULL dependency graph pulled by the TEST target, not just the library target — a test-only
  GUI/plotting/audio dep kills Docker feasibility exactly like the Rust case.

**Java / JVM**
- **GAINED:** equals/hashCode contract violations, mutable-shared-state across threads (visibility
  without `volatile`/`synchronized`), checked-exception swallowing, generic type-erasure surprises,
  `equals` vs `==` on boxed types, iterator `ConcurrentModificationException` seams (a close cousin
  of Go's F-4 range-mutation trap). Interface default-method resolution (diamond-of-defaults) is a
  Java-only seam with no clean analogue elsewhere in this hunt.
- **RISK:** Gradle/Maven build graphs are large and slow to warm; a cold-cache build can look like a
  Docker-feasibility failure when it is actually a cache-warming cost. Budget for it, do not reject
  on first-build time alone.
  ```bash
  grep -riE "^\s*(implementation|api|testImplementation)\s" build.gradle build.gradle.kts 2>/dev/null | head -20
  ```
- **Docker:** Pattern B, `olympus-base-jvm`. Local setup notes: `Instructions/jvm-toolchain.md`.
  Gradle-cache directory must be `a+rwX` writable per `DOCKER.md`; use the documented
  `gradlew test --tests __nope__` graph-warming trick to pre-populate the cache offline.
- **Extra gate G-JVM1 (test-graph warm gate):** confirm `gradlew`/`mvn` can resolve all test deps
  from a warmed local cache with network disabled — a repo pulling test deps from a private or
  non-Maven-Central repository is a hard Docker-feasibility reject.

Seam probes in Stage 3 need `--include=*.ts --include=*.tsx --include=*.js` (TS/JS),
`--include=*.cpp --include=*.hpp --include=*.h --include=*.cc` (C++), or `--include=*.java` (Java)
alongside the existing variants.

---

### ⭐ The corrected Gate 5 — velocity is not a reject criterion, capability collision is

Derived from the approved set and confirmed twice since. **neva shipped 600 commits in 12 months
with its own pick's files hot at base (33/34/15 commits) and was ACCEPTED.** Repos were being
rejected at 20-37 commits on files nobody had touched.

Overlay **capabilities**, not file lists. Is anyone — maintainer commit, merged PR, or open/draft
PR — building the capability you intend to add? A busy file whose capability space is untouched is
fine; a cold file whose capability just shipped is dead.

⚠️ **Two bugs that silently return an EMPTY sweep** (both measured 2026-08-05, both cost a
restart): (1) `gh search repos --json` takes **`license`**, NOT `licenseInfo` — older docs and
`gh api` use `licenseInfo`, and `gh search` errors out with `Unknown JSON field`, so the whole
pipeline yields nothing; (2) a repo with a **null description** aborts the entire `jq` filter, not
just that row — always guard with `(.description // "")`. Both are already fixed below; do not
"restore" the old field name.

```bash
# Discovery sweep — run per domain keyword, across all six in-scope languages.
# `gh search repos --language=` values: go, rust, python, typescript, javascript, c++, java
for LANG in go rust python typescript javascript c++ java; do
  gh search repos --language=$LANG --stars=">=500" --limit=30 \
    --json fullName,stargazersCount,description,license,pushedAt,openIssuesCount \
    "<domain keyword>" 2>/dev/null \
  | jq -r '.[] | select((.license.key // "") | IN("mit","apache-2.0","bsd-3-clause","bsd-2-clause","bsl-1.0","cc-by-4.0"))
           | select(.pushedAt > "<12 months ago, YYYY-MM-DD>")
           | "\(.stargazersCount)\t\(.fullName)\t\(.license.key)\t\(.openIssuesCount)\t\((.description // "")[0:60])"'
done | sort -rn | head -10
```

⭐ **TOPIC SEARCH is the sweep that still works (measured 2026-09-09).** Star-sorted KEYWORD search
is LLM-colonised (2026-09-06 lesson), but `gh search repos --topic=<t>` reads maintainer-curated
topics and returned ZERO LLM-infra rows across ~120 niche engineering topics in one session. Run it
with a DEAD-LIST filter built from every slug in the ledger, pool and hunt logs so nothing is
re-screened, and use single-word topics (`assembler`, `disassembler`, `voxel`, `slam`, `sdr`,
`gcode`, `pcb`, `hydrology`, `crystallography`, `petri-net`, `datalog`, `type-inference`,
`register-allocation`, `circuit-simulator`, `logic-synthesis`, `nurbs`, `marching-cubes`, ...).
The 2026-09-09 RANK 1 (Cwerg, topic `assembler`) came out of this sweep after 44 pool/keyword
repos had produced nothing.

```bash
# dead-list: every owner/repo ever mentioned in the ledger, pool or hunt logs (case-folded)
{ grep -rhoE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' Instructions/SATURATED-REPOS.md \
    Instructions/repo-hunt-logs/*.md approved-problems/*/meta.md problems/*/meta.md rejected/*/meta.md \
    | sed 's|github.com/||'; } | tr 'A-Z' 'a-z' | sort -u > /tmp/deadlist.txt
for T in <topic> ...; do
  gh search repos --topic="$T" --stars=">=500" --limit=40 \
    --json fullName,stargazersCount,language,license,pushedAt,openIssuesCount,description \
  | jq -r --arg since "$(date -d '12 months ago' +%F)" '.[]
      | select((.license.key // "") | IN("mit","apache-2.0","bsd-3-clause","bsd-2-clause","bsl-1.0","isc","0bsd"))
      | select(.pushedAt > $since) | select(.stargazersCount <= 6000)
      | select((.language // "") | IN("Go","Rust","Python","TypeScript","JavaScript","C++","Java"))
      | "\(.stargazersCount)\t\(.fullName)\t\(.language)\t\(.license.key)\t\(.openIssuesCount)\t\((.description // "")[0:70])"'
  sleep 2.5      # search API secondary limit is ~30/min
done | awk -F'\t' 'BEGIN{while((getline l < "/tmp/deadlist.txt")>0) d[l]=1} {if(!(tolower($2) in d)) print}' | sort -rn
```

Then, BEFORE cloning any hit: `gh issue list` and count issues that ask for CORE behaviour. Zero on a
cold repo = finished library, do not clone (alembic, 2026-09-09).

Domain keywords that match the anchor shape: `parser`, `interpreter`, `compiler`, `query
language`, `template engine`, `type checker`, `optimizer`, `linter`, `layout engine`,
`serialization`, `expression evaluator`, `state machine`, `diff`, `regex engine`, `shell`.

⚠️ **Use SINGLE-WORD keywords.** Measured 2026-08-05: multi-word phrases (`constraint solver`,
`font shaping`, `structural diff`, `query planner`, `date parser`) return ZERO rows for both
languages, while their single-word heads (`solver`, `diff`, `assembler`, `codec`) return full
result sets. A phrase that returns nothing is a search artifact, NOT evidence the domain is empty.

⚠️ **Rate limiting.** A tight `gh api` loop over candidates trips a SECONDARY limit that reports as
a 403 quota message while `gh api rate_limit` still shows ~5000 core remaining. It is not the real
quota and waiting for the printed reset is wasted time — just add `sleep 1-2` between repos.

```bash
# Per-finalist verification (the API is the authority, not the search index)
R=owner/repo
gh api repos/$R -q '"\(.full_name)  ★\(.stargazers_count)  \(.license.spdx_id)  pushed:\(.pushed_at)  issues:\(.open_issues_count)"'
# open_issues_count INCLUDES PRs -- get the real issue count:
gh api "search/issues?q=repo:$R+is:issue+is:open&per_page=1" -q .total_count
# PR-free issues (the number the dossier reports)
gh api "search/issues?q=repo:$R+is:issue+is:open+-linked:pr&per_page=1" -q .total_count
# CGO / C-binding check (Go)
gh api repos/$R/contents --jq '.[].name' | grep -iE '\.c$|cgo' || echo "no obvious C"

# ⚠️ RUST: READ [dev-dependencies], NOT JUST [dependencies] — this kills repos late and silently.
#    Cargo builds the ENTIRE dev-dependency graph for ANY test target, including `cargo test --lib`.
#    A pure-Rust library with an audio/GUI/plotting dev-dep is NOT Docker-feasible for us.
gh api repos/$R/contents/Cargo.toml -q '.content' | base64 -d | sed -n '/\[dev-dependencies\]/,/^\[/p'
#    Red flags (each pulls a -sys crate needing system headers at build time):
#      cpal, midir, rodio, alsa       -> alsa-sys        (libasound2-dev)
#      eframe, egui-winit, winit      -> X11 / wayland stack
#      plotters (default features)    -> yeslogic-fontconfig-sys (libfontconfig1-dev)
#      openssl, curl, git2, rusqlite  -> the classic -sys family
# LIVE-UPSTREAM check -- is this repo the place development actually happens? (see Requirement 6)
gh issue list -R $R --state all --limit 60 --json number,title \
  -q '.[] | select(.title | test("obsolete|moved|no longer maintained|fork|abandoned|deprecat"; "i")) | "#\(.number) \(.title)"'
```

**License check is READ-THE-FILE, not trust-the-label** (`RULES.md`): NCSA is OSI-approved and a
HARD disqualifier; a BSD text with extra rider conditions is a HARD disqualifier; CC-BY is allowed
though not OSI-approved. If the repo carries multiple licenses (including vendored subdirs),
**every one** must be in the allowlist.

**What may never be relaxed:** licence, language, activity, the 500-star floor, and the
live-upstream check. Everything else is a ranking input. If a sweep returns nothing, widen the
DOMAIN keywords rather than reaching for a repo that fails one of the six.

---

## Stage 2 — Local dedup and saturation (2 min, no network)

```bash
cd <workspace-root>
R=<repo-short-name>
grep -ri "$R" Instructions/SATURATED-REPOS.md          # see below: A/C/D/E = dead, B2 = lane ledger, NOT dead
ls worktrees/ problems/ rejected/ diamond-problems/ Olympus-Approved/Feature-Requests/ 2>/dev/null | grep -i "$R"
```

**Reject only on a REPO-DEAD hit (sections A, B, C, D, E).** A hit in the **B1/B2/B3 lane ledger is
NOT a reject** — those entries record a dead SUBSYSTEM or CAPABILITY LANE in a repo that is still
pickable, and several of them literally begin "NOT saturated, NOT blocked" (one, customasm, is a repo
we have an APPROVED problem in). Read the entry's untouched-surface note and pick a different lane;
the entry's licence / determinism / dev-dep measurements are a paid-for head start, not a warning.
Killing a repo for one failing feature permanently shrinks the searchable universe.

Known repo-dead at time of writing: **risor (78 subs),
sqlglot (62), opa (60), goja (57)** global-saturated; **dasel (9), cliffy (7), yaegi (7)** at our
6-cap; **scriggo** contested subsystem. Re-read the file rather than trusting this list.

Count existing submissions per candidate repo — the cap is **≤6 total, ≤3 per week, global ≤50**
(`PICK-FILTER.md` Gate 10). A repo at 5 is worth one pick, not a campaign.

---

## Stage 2b — DERIVATIVE-RISK GATE (added 2026-08-01, paid for by a dead submission)

`SATURATED-REPOS.md` and the local dirs only see OUR history and GitHub. They are BLIND to the
submission pipeline, where other authors' work lives. The dedup engine is not — and it compares
behavioural + structural overlap, so a different implementation strategy for the same capability
still reads as `duplicate`.

**The measured failure:** `rejected/lol-html-sibling-combinators` was built end to end (292 eff,
66 f2p, 8 traps reproduced, everything green) and came back **`duplicate`, 0.80 similarity, 0.91
confidence** against an older submission doing the same two capabilities at the same five files.
Two further older subs covered one of the capabilities independently. The GitHub SIX-CHECK was
clean throughout: issues #67 and #300 were OPEN with **zero comments and no PR**.

**The inversion to internalise:** a famous feature sitting unimplemented in a popular repo, with an
open uncommented issue asking for it, is a derivative **MAGNET**. The SIX-CHECK reads clean
*because* nobody upstream engaged — which is precisely the condition that makes every problem
author reach for it first. Open + uncommented + unimplemented + famous = maximum collision odds.

**Score every candidate's BEST PICK before the seam audit:**

| Signal | Risk | Action |
|---|---|---|
| The pick can be NAMED by an external standard (a CSS selector/combinator, a SQL clause, an RFC, a language syntax sugar, a textbook algorithm) | **MEDIUM** (softened 2026-09-09-B) | A risk to MITIGATE, not a reject on its own: phrase `meta.md` on the repo's own model (its types, stages, invariants), build the F-10 cell table so the tests encode repo-specific behaviour, and re-run the PR-DIFF check at submit. It becomes a REJECT only when combined with the next row (a long-open, uncommented issue asking for exactly the named thing) or with a faithful-port shape |
| The repo has open, uncommented, long-lived issues requesting a well-known feature | **HIGH** | Treat as a magnet, not a moat. Do not pick what the issue asks for |
| The pick is a faithful port of a spec the model already knows | **HIGH** | Dead anyway (`TOO-EASY.md` saturated-reference-port) |
| The capability is defined by the REPO'S OWN model (its type system, its IR, its stage boundaries, its invariants) and could not be described without naming repo-internal concepts | **LOW** | Proceed. This is the target shape |
| The pick is a correctness/behaviour gap that no external document names | **LOW** | Proceed |

### ⛔ CARVE-OUT to row 1 — LANGUAGE-SURFACE features in a language implementation (added 2026-09-10, paid for by koto-nested-bindings)

The 2026-09-09-B softening ("nameable alone is MEDIUM, mitigate by phrasing on the repo's own
model") does **not** apply when BOTH hold:

1. the target repo IS a programming-language implementation (interpreter, compiler, scripting
   runtime), and
2. the pick is a **user-visible language surface feature** — destructuring / rest patterns, pattern
   matching, guards, or-patterns, ranges, exhaustiveness, `@`-bindings, string interpolation,
   operator sugar, comprehensions.

Then it is a **REJECT at pick time**, not a risk to mitigate. This is `TOO-EASY.md`'s
`Famous-language-feature lane` row, and it has now killed two full authoring arcs:
`gluon-match-alternatives` (dedupe `duplicate` 0.92) and `koto-nested-bindings` (overlap `Blocker`,
258/489 authored lines = 52.8% against an ACCEPTED task, every upstream gate clean). The magnet is
the feature's FAME, so no tracker signal predicts it and no GitHub query sees it.

**Two mitigations that do NOT work here** (both were used to clear koto):

- *"Phrase meta.md on the repo's own model."* The dedupe compares IMPLEMENTED SURFACES, not prose.
  It cannot move a line-correspondence number. Every judge in this class emits the same sentence:
  the extras "do not replace that recycled core" / "are incremental to the shared core".
- *"We have an unusual sub-lever no mainstream language has."* A lever is only a differentiator
  while it is still in the artifact. koto's middle-rest lever was **deleted in authoring round 2**
  (it superseded an existing repo test) and the pick silently reverted to the bare famous-feature
  core with the derivative risk still recorded as MEDIUM.

**Rule for the author stage:** if authoring drops, shrinks or refactors away the differentiator the
hunt named as the derivative mitigation, the pick has reverted to its dead class. Stop and run the
platform precheck at that commit before spending another round (`TOO-EASY.md § koto-nested-bindings`,
law 2), or drop the pick.

⚠️ **Stage 2b's magnet test must be run against ISSUE BODIES, not titles** (added 2026-09-01).
`gh issue list --search` matches TITLES, and capability-level prior art hides in the body. On
geometry-central a title search returned #47 and #134 looking like ordinary bug reports; their bodies
held a six-year-old zero-comment magnet and an ASCII diagram of the exact mechanism, and a linked PR
held a partial solution. Those three killed the pick at author Phase 2, after the full seam audit,
Docker pull, 511s CMake configure and 3x determinism run had already been spent. `gh issue view <N>
--json body,comments` every plausible hit, at HUNT time.

**Stage 2c — ENUMERATE EVERY OPEN PR'S FILE LIST (do not keyword-search).** Cheap, mechanical,
and it has now caught two picks that keyword search missed:

```bash
for n in $(gh pr list -R OWNER/REPO --state open --json number -q '.[].number'); do
  echo "--- #$n: $(gh pr view $n -R OWNER/REPO --json title -q .title)"
  gh pr view $n -R OWNER/REPO --json files -q '.files[]|"    \(.additions)+ \(.deletions)- \(.path)"'
done
```

Build the set of files under open PRs, then overlay your planned footprint. But **classify the queue
by KIND before you reject anything** — the exclusivity rule is CONJUNCTIVE (same core files AND the
same central capability), and Gate 5's kill examples are all feature-shipping, not file-churn:

**Classify BOTH streams — the open-PR queue alone will lie to you.** The PR queue reflects OUTSIDE
contributions; a maintainer with commit rights lands features as direct pushes that never appear
there. Read the merged commit stream too:

```bash
# Stream 1 - outside contributions. Read TITLES, not file counts: capabilities or maintenance?
gh api "repos/OWNER/REPO/pulls?state=open&per_page=40" -q '.[].title'

# Stream 2 - THE MAINTAINER'S OWN PROGRAM (the one that hides). A `feat:` line with NO (#NNN)
# suffix is a direct push, invisible to every `gh pr list` query.
gh api "repos/OWNER/REPO/commits?since=<90d ago>T00:00:00Z&per_page=100" \
  -q '.[]|"\(.commit.author.date[0:10])  \(.commit.message|split("\n")[0])"'
```

**Measured cost of checking only stream 1 (rapier, 2026-08-04):** the open queue is 31 PRs of pure
maintenance ("fix wheel impulse scaling", "fix aliasing UB", "add getter for `contact_id`"), which
reads ALIVE. The commit stream for the same week shows the maintainer shipping `v0.35.0-beta.0` with
**intra-island parallelism, box2d-style CCD, unified SIMD/non-SIMD paths, NaN-quarantine containment,
non-Sync event handlers, a broad-phase rework** — 14 commits, **zero of them carrying a PR number**.
The repo is in a major-release feature phase and reads as maintenance-only through the PR lens.

- **Capability-consuming in EITHER stream** -> the maintainers are eating the invent-able space.
  Measured: egglog, moon, nilaway, cerbos (open PRs); **rapier (direct pushes only — the PR queue said
  maintenance and the commit stream said beta-release feature wave)**.
  ⚠️ **Softened 2026-09-09-B (user decision): this is a LANE verdict, never a repo verdict.** Name the
  lane you intend FIRST, then ask whether the stream touches THAT lane. A maintainer building a JIT
  does not occupy the module system; a formatter subsystem does not occupy the parser. Kill the
  repo only when every lane you can name is in the stream (that is what Stage 2c measures). Commit
  COUNT alone — steel 39/180d, uiua 100/180d, pitest 90/180d — is never a reject; neva shipped 600 in
  12 months and was accepted.
- **Maintenance in BOTH streams** -> file overlap WITHOUT capability overlap; the repo stays ALIVE for
  an INVENTED capability. No repo has yet cleared this bar in practice — treat a clean result as
  provisional and re-check the commit stream at submit.
- **A PR implementing YOUR central capability** -> that pick is dead regardless of queue kind. This
  is the only unconditional case (objdiff #358, nickel #2185).

Residual risk: no recorded case exists of a pure file-overlap-without-capability-overlap reject, so
this is reasoned from the rule text, not from a measured survival. Prefer picks whose core-machinery
files carry no open PR; accept overlap only in plumbing; re-run the SIX-CHECK at submit.

**Why keyword search is not enough (measured, objdiff 2026-08-02):** searching PRs for "symbol
matching", "rename" and "fuzzy" returned nothing relevant, so the pick looked clean. Enumerating
all 12 open PRs surfaced **#358 "Find similar functions"** — +181 LOC of new
`jobs/find_similar.rs` plus +43 in `diff/mod.rs`, i.e. exactly the content-based unmatched-symbol
matching capability about to be authored. The title shares not one keyword with the feature. The
same enumeration showed PR #381 touching `diff/code.rs`, `diff/data.rs` AND `diff/mod.rs` at once,
which is what proved the repo had no cold file left. Run this BEFORE the seam audit — it is two
API calls and it retires the most expensive reject class there is.

**The test to apply:** write the one-line summary the dedup engine would emit for your pick. If
that sentence is intelligible to someone who has never seen the repo ("adds CSS sibling
combinators to the selector engine"), the collision risk is high. If it cannot be written without
repo-specific nouns ("makes the analyzer's resolved form survive the boundary into IR generation"),
the risk is low.

### ⛔ Run the magnet test on the CAPABILITY, never on the SUBSYSTEM

**This is the failure that killed a fully-built, fully-validated submission (comrak, 2026-08-05).**
The magnet risk was SEEN at pick time, written down, and rated "moderate" — because the target
subsystem (the CommonMark *renderer*) was fresh next to our two existing markdown *parser* picks.
That reasoning is invalid and cost a complete authoring cycle: 214 effective LOC, 58 tests, six
reproduced traps, killed at the Scope Gate by an older accepted submission touching the same file.

**Changing subsystem changes the DIFFICULTY story. It never changes the COLLISION story.**

- A capability named by an external spec, a manual, or a well-known tool's feature list is a magnet
  **regardless of which subsystem implements it and how novel the internal machinery is**.
  "Reference-style links" is named by the CommonMark spec, so every author reading that spec
  converges on it, whichever part of the codebase they touch.
- Write the summary the way an OUTSIDER would, naming the user-visible feature. If you find yourself
  reaching for the subsystem name to make it sound novel ("a new document-level phase in the
  streaming renderer"), you are describing your IMPLEMENTATION, not your capability. The dedup engine
  compares capabilities.
- The self-collision check (approved-problems/, problems/) is a DIFFERENT question and does not
  substitute. Passing it means we have not built this; it says nothing about the other authors in
  the pipeline, whom you cannot see.

⚠️ **You are strictly worse off when the prior art is a SUPERSET.** If an existing task does your
core plus a deeper integration layer, no amount of added policy, escaping detail or edge-case
handling differentiates you — every addition still rides the duplicated machinery
(`HARDENING.md` DEAD list: "you cannot out-add a superset", 5x confirmed). Do not contest, do not
bolt on differences. The only fix is a DIFFERENT CENTRAL CAPABILITY, which means a new pick.

**Note on F-8.** The named-algorithm-override trap (`failure-patterns.md` F-8) is still good, and
it does not contradict this gate — F-8 requires implementing the repo's *deliberate divergence*
from a famous algorithm, which is an invented capability wearing a famous name. Implementing the
famous thing itself is the dead case. Keep the name as misdirection; never let it be the scope.

**Self-collision is a SUBSYSTEM problem, not a repo problem.** Our own approved and in-flight set
is the first place the dedup engine looks, and the match is at FEATURE CLASS, not repo. When a
candidate collides with our own prior art, move to a different SUBSYSTEM CLASS inside the same repo
before dropping the repo. Measured (comrak, 2026-08-05): with an accepted `pulldown-cmark-gfm-autolinks`
and an in-flight `pulldown-cmark-abbreviations` already in the set, comrak's *extension* surface was
derivative on sight — "add markdown extension X to a Rust CommonMark parser" three times. Its
*renderer* surface was not: reference-style output is comrak's own model, no spec names it, and it
touches no parser code. Same repo, different subsystem, collision gone.

---

## Stage 2b-bis — PR-AUTHOR PROFILING (added 2026-09-01 — the FIRST direct way to see pipeline competitors)

The doctrine repeatedly says the competing prior art "lives in the submission pipeline where GitHub
queries cannot see it" (lol-html `duplicate` 0.80; comrak scope gate). That is true of their
SUBMISSIONS. It is **not** true of the AUTHORS — they file reconnaissance PRs, and those are public.

```bash
R=owner/repo
# 1. Who has filed PRs here recently?
gh pr list -R $R --state all --limit 40 --json number,title,author,createdAt \
  -q '.[]|"#\(.number) [\(.createdAt[0:10])] \(.author.login)  \(.title)"'
# 2. Profile each non-maintainer author
U=<login>
gh api users/$U -q '"created:\(.created_at[0:10]) repos:\(.public_repos) followers:\(.followers) name:\(.name // "-") bio:\(.bio // "-")"'
gh api "users/$U/events/public?per_page=300" -q '[.[]|.repo.name]|unique|.[]'
```

**The signature of another problem author:** no real name and no bio, very few followers, and a
scattershot of **small, surgical, precise bug-fix PRs across mutually unrelated niche,
permissively-licensed libraries** in the target languages — i.e. the exact repo profile this skill
tells you to hunt. A genuine domain contributor looks different: a real identity and a coherent
single-domain footprint (their own projects in that field).

**Measured 2026-09-01.** Auditing CalebBell/thermo surfaced `steps-re` — account with 2 followers,
no name, no bio, and July-August 2026 PRs across **thermo, biotite, scikit-bio, sunpy, lmfit, PyDMD,
ProDy, scanpy, PyPSA, movingpandas, serpent-tools, C-Star, slmsuite, gridstatus, GSEApy**. Every one
is a niche scientific library; every PR is a tight one-bug fix (`fix: handle atol=None in
pair_align`, `Fix corrupted brute() candidates for a single varying parameter`, `fix
dihedral_backbone() returning garbage angles across chain breaks`). **`scikit-bio` is a repo we hold
an APPROVED problem in**, and three of that session's finalists (thermo, biotite, sunpy) were on the
list. Contrast `binggao1230` on the same repo: real name, 770 repos, a coherent CFD/aerodynamics
footprint of their own — a genuine contributor, not a competitor.

**How to read a hit.** It is a RISK WEIGHT, not a kill:
- **Their PRs touch YOUR intended lane** -> treat as occupied; pick a different lane or repo.
- **Their PRs touch other lanes** -> the repo is being mined, so invisible-derivative risk is
  elevated and unmeasurable. Proceed only with a capability that is far from their footprint, and
  expect the dedup engine to have seen this repo before.
- **⚠️ Softened 2026-09-09-B (user decision): ONE visit from ONE recorded account, outside your
  lane, is a dossier NOTE, not a reject.** scikit-fem carried exactly that (`binggao1230` x1, an
  `enforce` fix) and produced the best lane found in two sessions. The reject threshold is: two or
  more distinct signature accounts on the repo, OR any signature PR inside the lane you intend, OR a
  burst (>= 3 PRs from one account in a week). Below that, record the login and move on.
- **Their footprint overlaps your own approved/rejected corpus** -> confirmed same-pipeline
  competitor. Weight every candidate they have touched down hard.

⚠️ **Matcher bug to avoid when diffing their footprint against your corpus:** folder names are
`<repo>-<slug>`, so `sed 's/-.*//'` truncates `scikit-bio-feature-hierarchy` to `scikit` and silently
misses the match. Compare with a prefix test (`grep -E "^${base}(-|$)"`) against the full folder list.

---

## Stage 2c — CAPABILITY-LANE DENSITY (3 min — the triage that would have saved a full day)

Stage 2b asks "is MY capability taken". This asks the cheaper, earlier question: **is this repo
still handing out capabilities at all?** A repo can pass every mechanical gate, have gorgeous seams,
and still have no authorable pick left, because an active contributor base consumes lanes as fast as
you can find them.

**Measured (veryl, 2026-08-05): four consecutive candidates died in one gate-clean repo** — 995
stars, dual MIT/Apache, 127 issues, 414+65 tests, deterministic 3/3, a real two-backend pipeline over
one IR. Clock domains died to a dedicated `fix/cdc-*` branch series (19 commits). Inferred
declarations died to five merged PRs in one narrow lane, one of which *deliberately* chose the
rejection we wanted to reverse. Emitter/simulator parity died to the hottest area in the repo (58
commits of Cranelift/AOT work). The formatter — the coldest lane at 7 commits — died to a
corpus-wide fixed-point test that already asserts the invariant. That is a full day for zero picks,
and every one of those deaths was visible from the commit stream in three minutes.

```bash
R=owner/repo
# 1. Commit subjects for 12 months, then a keyword histogram over YOUR candidate lanes.
for pg in 1 2 3 4 5 6; do
  gh api "repos/$R/commits?since=$(date -d '12 months ago' +%Y-%m-%d)T00:00:00Z&per_page=100&page=$pg" \
    -q '.[]|.commit.message|split("\n")[0]' 2>/dev/null
done > /tmp/lane_commits.txt
wc -l < /tmp/lane_commits.txt
for k in <lane1> <lane2> <lane3>; do printf "  %-20s %s\n" "$k" "$(grep -icE "$k" /tmp/lane_commits.txt)"; done

# 2. BRANCH-NAME FAMILIES — the loudest signal. A `fix/<topic>-*` series means a maintainer is
#    systematically sweeping that exact gap class, and every hole you find in it is next week's commit.
grep -oE 'Merge pull request #[0-9]+ from [^ ]+' /tmp/lane_commits.txt \
  | sed 's|.*/||' | sed 's/-[^-]*$//' | sort | uniq -c | sort -rn | head -12

# 2b. MAINTAINER AI-SWEEP (added 2026-09-09) - a maintainer running an agent over their own tracker
#     closes the surgical-correctness gap class CONTINUOUSLY, which is exactly the f2p surface.
grep -inE "copilot|codex/|Checkpoint before|papercut|AI-assisted|swe-agent" /tmp/lane_commits.txt | head
gh pr list -R $R --state all --limit 40 --json author -q '.[].author.login' | sort | uniq -c | sort -rn | head
#     Marks seen so far: `app/copilot-swe-agent` as commit AUTHOR (go-workflows, Pynite),
#     `codex/*` branch families (techan), `Checkpoint before follow-up message` (ikpy),
#     a documented AI-assisted "papercut" programme (neva). Treat a hit like a `fix/<topic>-*` family
#     ONLY when the agent's commits/PRs are closing the correctness gap class IN THE LANE YOU INTEND.
#     Softened 2026-09-09-B (user decision): a single `claude`/`Copilot` authored commit elsewhere in
#     the repo (docs, a test tolerance, a CI file) is a NOTE, not a lane verdict. Read the subjects of
#     the agent's commits and overlay them on your lane exactly as for a human competitor.

# 3. CORPUS-WIDE INVARIANT TESTS — a repo that asserts a global property over a corpus has already
#    closed the cheapest bug class you would have hunted (idempotence, round-trip, golden output).
grep -rln "testcases\|corpus\|golden\|snapshot" --include=*.rs --include=*.go . | head
```

**Read it as:**

- **A `fix/<topic>-*` branch family in your lane** -> that lane is dead. Not the repo — pick another lane.
- **≥4 merged PRs in one narrow lane** -> dead lane, and treat any deliberate "reject/defer" decision
  inside it as maintainer philosophy you would be contradicting (Gate 8).
- **A corpus-wide invariant test covering your intended property** -> that gap class is already closed.
- **Two or more of your candidate lanes dead** -> STOP drilling the tracker and re-rank. Three dead
  tracker-sourced lanes in one repo is a property of the repo, not bad luck. One INVENTED lane (from
  the source tree's own seams, filtered against the tracker afterwards) is still allowed before you
  leave — that is how scikit-fem's embedded-mesh lane was found after the wedge lane died.
- **Cold lanes exist and carry no branch family** -> proceed to Stage 3 on those lanes specifically.

Do NOT read a high total commit count as bad. neva did 600/12mo and was accepted. What matters is
whether the commits are landing *in the lane you want*.

---

## Stage 2d — MAINTAINER-WELCOMED LANES (3 min — a finder, not a filter)

The cheapest known route to an authorable pick, and it makes picking EASIER without loosening any
bound: search the tracker for capabilities the maintainer has explicitly said yes to and nobody has
built. A hit gives you three things at once — Gate 8 cleared in advance, evidence the lane is open,
and an independent expert opinion on difficulty.

```bash
R=owner/repo
# Maintainer-welcome language on open issues, any age
gh issue list -R $R --state open --limit 60 --json number,title,comments \
  -q '.[] | select(.comments[]?.body | test("welcome.*PR|PRs? welcome|happy to (accept|review|merge)|would accept|feel free to (submit|open) a PR"; "i"))
      | "#\(.number) \(.title)"'
```

**Grade each hit:**

- **Maintainer says yes, no design published, no PR** -> BEST CASE. Author it, inventing your own
  scope and canonical form (`RULES.md`: an issue may INFORM that a class is welcome, it must never
  BIND the spec).
- **Maintainer says yes AND publishes an implementation plan** -> the plan is a public solution
  sketch. Treat as Stage 2b prior art, not as a gift.
- **Maintainer flags the edge cases as hard** -> a difficulty signal from someone who knows the
  codebase. Worth more than your own guess at pick time.
- **No maintainer comment at all on a popular request** -> the derivative magnet
  (`lesson_famous_unimplemented_feature_is_a_derivative_magnet`): it reads clean only because nobody
  engaged. Not a positive signal.

**Measured (comrak #740, 2026-08-05):** owner comment — *"I'd be happy for this feature to be
implemented and would welcome PR(s) to do so, though thinking through it, there are many complicated
edge-cases."* No PR, no published design. That query converted a shelved fallback repo into a
scope-locked pick that built cleanly at 214 effective LOC with six reproduced traps — **and then died
at the platform Scope Gate as a derivative of an older accepted submission.** Read the next
paragraph before using this stage.

### ⚠️ A welcomed lane is DOUBLE-EDGED — Gate 8 and collision risk move in OPPOSITE directions

The same evidence that clears maintainer philosophy also marks the lane as a magnet. A publicly
blessed, still-unimplemented, spec-named feature is the derivative-magnet DEFINITION: every author
who searches that tracker sees the identical invitation, and you cannot see which of them already
submitted (`lesson_famous_unimplemented_feature_is_a_derivative_magnet`).

So treat a welcome comment as clearing ONE gate only, and immediately run the capability-level magnet
test above on the lane it points at:

- **Welcomed AND the capability needs repo-specific nouns to name** -> genuinely strong. Author it.
- **Welcomed AND the capability is named by a spec / manual / famous tool feature list** -> the
  welcome does not save it. This is the comrak case. Treat as HIGH collision risk and prefer a
  different lane in the same repo.
- **Welcomed, spec-named, AND long-lived with no PR** -> worst case, not best. The lane has been
  visible and unclaimed for a long time precisely because it is the obvious thing to pick.

The lane's AGE is the tell: a fresh invitation is a lead, a two-year-old one is a queue.

---


### F-12 seam probe — inline tests coupled to a private helper (adds ~30% kill, free)

Rust repos often keep `#[cfg(test)] mod tests` inside the implementation file. When the file a
feature forces you to rewrite carries such a module AND its tests call a private fn of that file,
agents must delete them to compile, and p2p identity grading turns that into a real discriminator.

```bash
# files with an inline test module that calls a private fn of the same file
for f in $(grep -rl '#\[cfg(test)\]' --include=*.rs src/ numbat/src 2>/dev/null); do
  fns=$(grep -oP '^fn \K\w+' "$f" | tr '\n' '|' | sed 's/|$//')
  [ -n "$fns" ] && grep -qE "($fns)\(" <(sed -n '/#\[cfg(test)\]/,$p' "$f") && echo "  F-12 seam: $f"
done
```

Dossier row: `F-12 seam: yes/no` — if yes, note it; the base-mode skip decision must be made
deliberately (skip ONLY the tests the feature invalidates), never by reflex.

### F-22 seam probe — an existing iterate-to-fixed-point resolver (8 of 9 failing runs on customasm)

The strongest lead trap measured on customasm-derived-bank-layout needed nothing exotic: the repo
already resolved several quantity KINDS to stability in a loop, and the pick added one more kind
that the existing kinds could depend on and that could depend on them. Mixed dependency chains
(through a function, through a constant, through a forward reference) then separate a real joint
fixed point from a single-quantity settling pass, while direct chains discriminate nothing.

```bash
# a real fixpoint loop, plus per-value "this is still a guess" state
grep -rnE 'while .*(stable|changed|converg)|resolve_iterativ|fn resolve_once|max_iterations' \
  --include=*.rs --include=*.go --include=*.py src/ | head
grep -rnE 'is_guess|unresolved|Unresolved|\bstable\b' --include=*.rs src/ | wc -l
# how many KINDS the loop already settles (labels, constants, sizes, ...)
grep -rnE 'enum .*(ResolverNode|WorkItem|Node)\b' -A 15 --include=*.rs src/ | head -25
```

Dossier row: `F-22 seam: yes/no + kinds already settled`. Two or more existing kinds is the
precondition; one kind is not enough, because there is nothing for the new quantity to interleave
with. **If you take this seam, never write an iteration-count or unbounded-chain-length promise
into meta.md** — that clause was ruled a functional false positive on customasm.

## Stage 3 — TRAP-SEAM AUDIT (the stage that actually decides — 10 min)

This is what separates this skill from a GitHub search. Clone the finalist shallowly and look for
the structures that the measured patterns in `failure-patterns.md` need. **Score each seam
present/absent with a file:line citation.** A repo with zero seams is rejected regardless of how
well it scored above.

```bash
git clone --depth 50 https://github.com/$R worktrees/$(basename $R)
cd worktrees/$(basename $R)
tokei . 2>/dev/null || cloc .        # size + language mix
ls */ | head -20                      # multi-package? (Gate: clear module boundaries)
```

| Seam to look for | How to spot it | Unlocks |
|---|---|---|
| **A staged pipeline where an early stage destroys information** | separate lex/parse/lower/optimize/emit dirs; an IR built before the stage you'd extend | **F-1** convergent-architecture wall — the highest-value lever measured |
| **A construct that is both producer and consumer** | call bindings, aliases, bidirectional constraints, two-way edges | **F-2** bidirectional seam (~50% kill) |
| **An exemption/protection spanning two collections** | "skip if X" logic where the protected entity has 2+ member lists | **F-3** second-axis carve-out (~28% kill) |
| **Aliasing-graph IR** | Rust `Rc<RefCell<_>>`/`RRC`, Go maps mutated during range | **F-4** ownership trap (~18%, kills whole runs) |
| **A pass-through node type in an analysis** | "transparent"/combinational/identity nodes | **F-5** transitive reachability |
| **Two documented transforms with unstated order** | validate + normalise living in different functions | **F-6** ordering inversion |
| **Suppression contexts across several stages** | "not inside X" handled in 2+ places | **F-7** context-exclusion completeness |
| **A recursive matcher/decoder where one rule holds two or more variable-extent sub-parts in sequence** | grep for a recursive resolve/match fn that loops over a term/part list and calls itself; look for a preference metric (specificity, cost, priority, length) | **F-11** local-vs-global selection scope — band decider on customasm (9/10) |
| **A subsystem bordering a famous named external algorithm/spec/format, where the repo's actual behaviour deliberately diverges from the textbook version** | feature name/domain overlaps an RFC, W3C spec, crypto primitive, textbook graph/geometry algorithm, or another well-known library's method; repo's own source/tests/issues show a narrower or different variant | **F-8** named-algorithm override (~90% kill on ONE sentence, cheapest lever measured — pair with an orthogonal trap, never ship alone) |
| **A validating stage and an emitting stage in different packages, where the LATER stage already re-resolves something the earlier one could have resolved** | analyzer/checker package + lowering/codegen package; grep the emitter for name/type/default resolution that the validator also performs | **F-9** cross-stage resolution drop (~60% kill; one root cause breaks every capability at once, so trap interdependence is free) |
| **A construct with ≥2 independent form axes — one with multiplicity, one with polarity** | "this works for one or many X" + "either side may be Y"; look for fan-in/fan-out, in/out direction, sender/receiver anchoring, single/repeated rounds | **F-10** capability cross-product cell (costs ~20 test lines and ZERO description words; the measured decider between a 20% and a 40% batch) |
| **A format parsed in TWO TIERS: a base declaration plus amendment rows that override its fields** | Breakpad `STACK CFI INIT` + `STACK CFI`, patch/diff hunks, cascading config layers, CSS `@media` overrides, INI section inheritance; grep the parser for a struct holding both an `init`/`base` field AND a `Vec` of later rules | **F-13** discard-unit granularity (top killer measured: **6/10** on rust-minidump, 3 of them sole-failure near-misses). Needs a validity rule an amendment ALONE can violate |
| **Several existing "cannot continue" exits, plus room for a NEW externally-declared reason to stop** | grep the walker/interpreter/resolver for the sites returning None/nil/break on null pointer, non-advancing state, or exhausted candidates; you need 3+ of them, ideally duplicated per backend | **F-14** declared-vs-derived terminal state (~30%; agents wire the new state to every giving-up site) |
| **Any existing tolerance/threshold rule, or room to add one ("allow one, stop at the second")** | grep for retry/attempt/consecutive/max counters; also any place the repo tolerates a single anomaly before bailing | **F-15** arming-vs-firing condition (~40%; author the ONE-event fixture, not the two-event one) |

| **A shared entry point whose logger/writer targets a GLOBAL output channel, next to a CLI or command layer that must emit STRUCTURED output on the same channel** | grep the library entry point for `println!`/`fmt.Print`/`console.log`/a package-level writer reached without an injected sink; then check the CLI writes results to bare stdout when no `--out` is given | **F-19** shared-helper side effect on the output channel — most durable killer measured (36/52 runs across 4 batches, never below 50%, never ruled unfair) |
| **A public API documented in prose (README/guide/doc comment) but with NO test of its own, next to which your feature would add a sibling entry point that differs on one rule** | find the documented behaviour (`grep -rn` the guide/README for the API name), then confirm the test suite never asserts it — break the behaviour locally and check the base suite still passes | **F-20** sibling-API contamination — band decider on go-workflows (8/10, and the SOLE failure of both near-misses); costs ZERO description words |
| **A public interface whose state has NO accessor, shipped alongside an abstract base class that holds that state in a field** | grep the interface for a getter of the quantity your rule needs; if there is none, and an `Abstract*` base in the same file holds it, the seam is live. Confirm a conforming implementation can be written outside the hierarchy in ~30 lines | **F-21** type-check shortcut for an unobservable interface — top killer and sole near-miss failure on datafixerupper (5/10); costs a four-word clause |
| **A lookup that throws on a missing key, whose throw the repo's own suite never exercises, in a namespace your feature must traverse before every key is known** | grep the resolver for the throw (`Unknown`, `not found`, `orElseThrow`, `panic!`), then delete it and run the base suite — if the suite still passes, the behaviour is untested and the seam is live | **F-24** absent-key sentinel replaces an existing hard failure — 8/10 in TWO independent batches on dfu-derived-recursion, four runs failed ONLY this pair; costs one clause naming the semantic difference |
| **A public API that hands the CALLER a value the feature cannot resolve yet** (an id/handle/template returned during a registration or builder phase) | check whether the API returns the unresolved thing to user code at all; if the caller can assign it to a local or memoize the supplier that produced it, the placeholder's lifetime is a seam | **F-25** placeholder validity window narrower than the caller's — 4/10 + 4/10 on dfu-derived-recursion; zero description words |
| **A pervasive "value or provider" container the repo uses for every scalar-or-callable quantity, whose constructor validates by signature/type introspection** | grep the container for `inspect.signature`/`__code__.co_argcount`/arity or dimensionality checks; then confirm a plain Python/JS callable with a DEFAULTED or KEYWORD-ONLY parameter is refused while the repo's own docs call it "a number or a function of X" | **F-23** repo-idiomatic wrapper narrows the stated input domain — 6/10 on rocketpy, reproducible across batches AND solver families; costs zero description words, but the axis is BINARY (flips all runs or none) |
| **Two lexical spellings of one concept the language treats as equivalent** | line vs block comments, short vs long flags, quote styles, prefix vs infix call syntax; grep the lexer for a second branch on the same token class | **F-18** token-form parity gap — decided the band on gluon (7/11, 22 of 37 kills) |

```bash
# Fast seam probes
grep -rnE '"//"|"/\*"|starts_with\(.--.\)' --include=*.rs --include=*.go | head   # F-18: two lexical forms of one concept
grep -rn "RefCell\|Rc<\|RRC" --include=*.rs | wc -l        # F-4 (Rust)
grep -rn "for .* := range" --include=*.go | wc -l          # F-4 (Go, check for in-loop mutation)
grep -rln "fixpoint\|fixed_point\|until.*changed\|converge" # F-2 (existing fixed points = coupled domain)
grep -rnE "fn [a-z_]*(match|resolve|decode|select)[a-z_]*\(" --include=*.rs | wc -l   # F-11 recursive selection sites
# F-13: two-tier format? a parser struct with BOTH a base decl and a list of amendment rows
grep -rnE "struct [A-Za-z]+ \{[^}]*\b(init|base|header)\b" -A 12 --include=*.rs | grep -B4 "Vec<" | head
grep -rniE "\b(INIT|delta|amend|override|inherit|cascade)\b" --include=*.rs <parser-dir>/ | head
# F-14: count the existing "give up" exits in the walker/interpreter
grep -rnE "return (None|nil)\b|break;" --include=*.rs <subsystem>/ | wc -l
# F-15: existing tolerance counters to ride, or a natural place to add one
grep -rniE "consecutive|max_(retries|attempts|depth)|tolerat|first_failure" --include=*.rs | head
# F-20: behaviour documented in prose but untested -- break it and see if the base suite still passes
grep -rniE 'is executed if|defaults to|takes precedence|in argument order' docs/ README* 2>/dev/null | head

# F-21: an interface with no reader for its own state, beside an Abstract* base that holds it
grep -rnE "^(public )?(interface|trait) " --include=*.java --include=*.rs | head -40
grep -rnE "abstract class Abstract[A-Za-z]*" --include=*.java          # the base agents will downcast to
# then, for the candidate interface: confirm NO getter exists for the quantity your rule quantifies over
# F-19: does the LIBRARY write to a global channel, and does a CLI emit structured output there?
grep -rnE "println!|eprintln!|fmt\.Print|console\.log|log\.(Print|Info)" --include=*.rs --include=*.go --include=*.ts <lib-dir>/ | head
grep -rnE "serde_json::to_string|json\.Marshal|JSON\.stringify" --include=*.rs --include=*.go --include=*.ts <cli-dir>/ | head
# F-24: a throw on a missing key that the repo's own suite never covers
rg -n 'Unknown |not found|NoSuchElement|orElseThrow|KeyError|panic!\("' --type-add 'src:*.{java,rs,go,py,ts}' -tsrc | head -30
#   then: comment the throw out, run the base suite, and confirm it still passes

# F-25: an unresolved handle handed back to caller code during a registration/builder phase
rg -n 'public .*(id|ref|reference|handle|placeholder)\(' -tsrc | head -20
#   live if the returned value is usable outside the pass that created it

# F-23: a scalar-or-callable container whose validation is narrower than the prose contract
grep -rnE "signature\(|co_argcount|__code__|getfullargspec|arity|n_args|num_inputs" --include=*.py --include=*.js --include=*.ts | head
grep -rniE "class (Function|Supplier|Lazy|Provider|Expr|Value)\b" --include=*.py | head
# then: does `Container(lambda x, scale=0.5: ...)` raise where `Container(lambda x: ...)` does not?
grep -rnE "addr_unit|unit_size|granularity|default_.*= *8" | head              # F-9 elidable default across stages
ls */                                                       # multi-package boundary count

# F-9: does a LATER stage re-resolve what an EARLIER stage validates?
#   list the pipeline packages, then look for the same resolution verb in two of them
ls internal/ src/ 2>/dev/null                               # find analyzer|checker vs irgen|codegen|lower|emit
grep -rn "resolve\|lookup\|infer\|default" --include=*.go --include=*.rs \
  <emitting-pkg>/ | head -20                                # a hit here + the same verb in the validator = F-9 seam

# F-10: count the form axes the subsystem already has
grep -rn "\[\]\|Vec<\|multiple\|fan_out\|fan_in\|broadcast" <subsystem>/ | head   # multiplicity axis
grep -rn "\bIn\b\|\bOut\b\|direction\|inbound\|outbound\|sender\|receiver" <subsystem>/ | head  # polarity axis
```

**F-8 probe (manual, not grep-able):** read the README/module docs for any feature named after a
real external spec (RFC numbers, "SVG", "CSS", a named crypto/compression/graph algorithm, "GFM",
a textbook construction). For each hit, check whether the repo's actual implementation or its
open issues describe a narrower/different variant than the famous one. A hit here is a strong,
cheap trap candidate — the misdirection is the name itself, not a code structure you can grep for.

**Also required at this stage:**

- **Test style.** Behavioural tests through public APIs, not mock-heavy unit tests. Test patches
  must assert behaviour without needing new API methods. Reject heavy-mock repos.
- **Determinism (Gate 9, MANDATORY).** Run the suite 2-3x. Any test that flips = flaky baseline =
  reject or scope base mode to solution-relevant tests with a documented reason.
  ```bash
  for i in 1 2 3; do (cargo test 2>&1 || go test ./... 2>&1) | tail -3; done
  ```
- **Solid-core-missing-features.** Established patterns you can extend, not a half-built repo.

---

## Stage 3b — THE ABSORPTION TEST (added 2026-09-01, paid for by two back-to-back dead picks)

⚠️ **Seams are necessary and NOT sufficient. Run this before Stage 4, and reject on it.**

Stages 1-3 rank candidates on *cold + large + no open PRs + rich seams*. That combination
**selects for FINISHED subsystems**: a lane is cold precisely because it is done, and a done lane's
remaining gaps are the ones too small for the maintainer to have bothered with. Two consecutive
top-ranked candidates died this way after full seam audits — geometry-central's `MutationManager`
(every F-seam present, ~130 eff LOC available) and choco-solver's graph lane (8140 LOC, zero open
PRs, F-2/F-3/F-10 all present, ~130 eff LOC available). Full post-mortems:
`TOO-EASY.md § MISSING-ARM-OF-A-DISPATCH`.

**⛔ RUN THE PORT / REFERENCE-TOOL CHECK IN THE SAME BREATH AS THIS ONE.** Absorption asks "does the
REPO already have it". That is half the question. The other half is "does the repo's PARENT or its
domain's reference toolchain already have it" — and it is one search.

```bash
# 1. Is the repo a PORT? (repo-level, check ONCE — the answer disqualifies a whole feature list)
grep -rli "matpower\|derived from\|ported from\|port of" <repo>/ --include=*.py --include=*.rs | head
head -5 <repo>/<vendored-dir>/__init__.py     # look for a foreign copyright holder
# 2. Does the domain's canonical toolchain ship your capability as a named function?
gh api "search/code?q=repo:<REFERENCE_TOOL>+filename:<your-capability>"
# 3. ⭐ Does the repo's OWN PREVIOUS MAJOR VERSION ship it? (added 2026-09-09 - one call, decisive)
git ls-remote --tags origin | sed 's|.*refs/tags/||' | grep -v '\^{}' | sort -V | tail -20
gh api "repos/<R>/contents/<old/path/to/Capability.py>?ref=<PREVIOUS_MAJOR_TAG>" -q .size
```

⭐ **A repo's OWN earlier major version is prior art.** The port law has a same-repo form: a v2 -> v3
REWRITE inherits its own v2 feature list, and a rewrite is exactly where a capability goes missing in
a way that greps clean. Measured 2026-09-09: OpenPNM v3 has zero hits for
`imbib|snap.?off|cooperativ|hysteres|relative.?perm` across the whole tree, and
`openpnm/algorithms/MixedInvasionPercolation.py` has been sitting at tag `v2.8.2` at **36,540 bytes**
the entire time (plus `Porosimetry.py`, plus 22 `imbibition` hits in the sibling tool `porespy`).
If the tag list shows a major-version boundary, check the previous major BEFORE sketching LOC.

⭐ **The reference-tool check can PASS for a mechanical reason, and that is worth far more than an
absence.** Ask HOW the reference tool implements it, not just whether it has the name. Measured on
lyon 2026-09-01: Skia has `SkPath::isRRect`/`isOval`/`isArc`, which LOOKS like fatal prior art for a
shape recogniser - but they read flags cached at construction (`fIsRRect` in `SkPathRef`), so they
are not recognisers at all. Only `isRect` walks the verbs, and lyon had already ported exactly that
one. Confirm the shortcut is unavailable in YOUR repo too (lyon's `Path` carries no such flag:
`grep -rniE "is_rect|is_oval|shape_hint|cached_shape"` = 0), and you have converted a feared
collision into a proof that the capability must be earned geometrically.

Domain -> reference toolchain: power systems -> **MATPOWER**; SPIR-V -> SPIRV-Tools; DWARF ->
llvm-dwarfdump/gimli; WASM -> wabt/binaryen; SQL -> the engine's own docs; CP -> the Global Constraint
Catalogue; circuits -> SPICE.

**Measured 2026-09-01, and it killed a pick that had cleared everything else.** pandapower continuation
power flow passed absorption (0 files for continuation/voltage_stability/loadability), passed Phase 2
(nobody had requested it), sketched at 445-675 effective against a same-repo 557 calibration, and had
a genuine repo-specific integration wall. Then: **pandapower vendors 69 PYPOWER files carrying
MATPOWER's PSERC copyright**, and MATPOWER ships `runcpf.m` plus `cpf_predictor`, `cpf_corrector`,
`cpf_tangent`, `cpf_p`/`cpf_p_jac` (the parameterization switch that was the identified crux),
`cpf_nose_event`, and `cpf_qlim_event` (the Q-limit-during-continuation interaction that was to be the
interdependent trap). Every design element pre-implemented, on the same array format. A port inherits
its parent's ENTIRE feature list as prior art.

**The test, in one question: NAME THE ALGORITHM THE REPO DOES NOT ALREADY CONTAIN.**

An enumeration, an analysis, an inversion, a reconstruction, a solver, a new normal form. Write it
down in the dossier as a sentence. If the honest answer is *"none — it reuses what is there and plugs
it into one more slot"*, the pick is dead at the LOC floor no matter how good its seams look.

⚠️ **Softened 2026-09-09-B (user decision): a "missing arm" / absorption verdict is not final until
the diff is SKETCHED in effective LOC against the nearest existing sibling arm.** Inspection alone
killed koto today without a number. The rule is: sketch (sibling arm size x number of sites the new
arm must touch, plus any semantics the sibling does not have); **below ~150 eff it dies, 150-250 needs
a coupled second lever named in the dossier, above 250 it proceeds.** Write the number down; a
verdict without one is an opinion.

**The shape-level tell, visible at pick time.** If the capability can be phrased as *"add the missing
X arm to a thing that already handles A, B and C"*, it is absorbed by construction — the framework
around the dispatch does the work, which is exactly why the arm is small. Look for: kind-dispatch
`if/else if` chains on a type tag, plugin/policy registries, visitor interfaces, `register*Handler`
callback tables, per-node-kind or per-variable-kind switches. A throw in the missing arm
(`UnsupportedOperationException("unrocognised variable kind")`) is a genuine, citable F2P gap AND a
guarantee that filling it is small.

**What the approved corpus actually looks like** (`approved-problems/README.md`): every accepted pick
is a net-new capability whose LOC lives in NEW domain logic — calyx "whole-program dataflow pass,
cross-subsystem" (925 eff), customasm "decode assembled bytes back to instructions using the repo's
own ruledefs" (493 eff, an inversion of the assembler), acoular "image-source path enumeration with
occlusion, wired into the steering vector, four source models and the time-domain beamformer" (438
eff), neva "generalise the array-bypass so every form an ordinary connection supports works for it
too" (6 files / 4 subsystems), rust-minidump "a trust-accounting layer for the stack walker". Not one
is a missing arm.

**Corollary for repo choice.** Prefer a repo with a real DOMAIN (geometry, acoustics, geodesy, crash
dumps, assemblers, dataflow compilers) where a new capability means new domain mathematics, over a
mature, well-factored FRAMEWORK where every extension point is already abstracted. Framework maturity
is the enemy: the better the abstraction, the smaller your diff. This is the same axis as the
existing "obscure deep engine, not the famous clean VM" rule, one level down — obscure DOMAIN beats
obscure REPO.

**Sketch the diff against its nearest existing twin, in eff LOC, before Stage 4.** Every arm has a
sibling already implemented; measure the sibling. choco's would-be graph arms sized against
`SetRandomNeighbor` (40 eff), `MaxDelta`/`MinDelta` (22 each) and `SetInLit` (58) — the total was
knowable in ten minutes and would have saved a full session.

---

## Stage 4 — Feasibility (5 min)

**Effective LOC.** Current floor is **≥200 effective (Counter 2)** per the 2026-07 sprint;
**design to ≥250-450** so revisions do not dip under, and note that 400 is the platform
auto-block on the looser Counter-1 measure. Estimate the *implemented fix slice*, not the file
sizes (`PICK-FILTER.md` Gate 4) — a surgical fix to mostly-correct code is ~30-50 LOC and dies.
Target **3+ files**.

⭐ **The LOC question is "does the repo LACK the machinery", not "is the subsystem big".** The
measured failure mode is machinery reuse: if the repo already owns the pieces your capability needs,
a correct implementation is a thin call-through and lands far under the floor no matter how large
the surrounding subsystem is. Measured twice — kcl reused the resolver's context-switching machinery
for ~94 LOC, and comrak's first complete, fully-correct reference-link implementation came in at
**87 effective LOC** against a 200 floor.

At pick time, ask what the capability needs that the repo cannot already do. For comrak the answer
was concrete: the renderer is a streaming walker with no document-level phase at all, and the
existing type-name path (`Option<&'static str>`) structurally cannot express the new form — so the
work was new machinery, not a call-through. Sketch that answer BEFORE scope-lock and write it in the
dossier.

If you cannot name the missing machinery, expect to need a scope lever, and plan a GENUINE second
capability rather than padding (`olympus-author` Phase 3). Rejecting a padding-flavoured lever is as
informative as taking a real one — record both.

**Docker.**

| Pattern | When | Shape |
|---|---|---|
| **A** | Rust workspaces | `olympus-base-rust` + chmod/symlink workaround |
| **B** | Go, and everything else | `olympus-base-go:latest`, plain `COPY . .` |

Flag anything needing system deps, network at build time, code generation, or a vendored C
toolchain — each is a real cost. Always `CMD ["/bin/bash"]`, offline-buildable, non-root.

---

## Stage 5 — Emit the dossier

One block per candidate, ranked by **trap-seam score first**, mechanical fit second.

```markdown
### <owner/repo> — ★<stars> — RANK <n>

- **URL / stars:** https://github.com/<owner>/<repo> — ★<stars>
- **Language:** Go | Rust (pure? CGO/-sys deps: <none | list>)
- **Domain:** parser | interpreter | compiler | CLI | framework | <other>
- **Open issues without PRs:** <n>  (total open issues <n>)
- **License:** <SPDX> — verified by reading LICENSE (+ any vendored licenses)
- **Last commit:** <date>
- **Test framework / organisation:** <e.g. cargo integration tests in tests/, table-driven;
  behavioural through public API? yes/no; mock-heavy? yes/no>
- **Baseline determinism:** <3 runs identical? any flaky tests?>
- **Docker:** Pattern A | B — <system deps, est. build time, offline-safe?> (estimate only where
  local Docker is unavailable — say so, never report an unbuilt image as verified)
- **Architecture:** <n packages/modules> — <the boundaries that matter>
- **Capability-lane density (Stage 2c):** <lanes checked, which are dead and to what — branch family
  / merged-PR cluster / corpus invariant — and which are open>
- **Maintainer-welcomed lanes (Stage 2d):** <issue refs where the maintainer said yes with no design
  published and no PR, or "none found">
- **Self-collision:** <nearest feature class in approved-problems/ + problems/, and which SUBSYSTEM
  of this repo avoids it>
- **Missing machinery (LOC carry):** <what the capability needs that the repo cannot already do — if
  you cannot name it, expect a scope lever>

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | yes/no | `path/to/file.rs:120` — <the destructive stage> |
| F-2 bidirectional seam | yes/no | <construct> |
| F-3 second-axis carve-out | yes/no | <exemption + its two collections> |
| F-4 ownership trap | yes/no | <RefCell/range-mutation count> |
| F-5 transitive pass-through | yes/no | <node type> |
| F-8 named-algorithm override | yes/no | <famous spec/algorithm the feature name borders + how the repo's real behaviour diverges> |
| F-9 cross-stage resolution drop | yes/no | <validating pkg + emitting pkg + the thing both could resolve> |
| F-10 capability cross-product | yes/no | <the two form axes: which has multiplicity, which has polarity> |
| F-13 two-tier format (base + amendments) | yes/no | <the base decl + the amendment row type + a validity rule an amendment alone can break> |
| F-14 declared-vs-derived terminal state | yes/no | <count of existing "cannot continue" exits + the declarable stop you could add> |
| F-15 tolerance/threshold rule | yes/no | <the existing counter, or the allow-one rule you could state> |

**Best Olympus feature types (cross-subsystem):** <2-3 concrete theses, each naming the
packages it spans and the seam it exploits>

**Estimated complexity:** <effective LOC range> across <n> files, <n> packages

**Why it matches:** <2-3 sentences — niche-ness, unsaturated domain, coupling, room to extend>

**Risks:** <maintainer velocity in the target subsystem, exclusivity, LOC ceiling, flakiness>
```

---

## Stage 6 — Handoff

### ⛔ FIRST — run the Phase-3 DEATH-CLASS GUARD on your RANK 1 before handing it over (added 2026-09-01-C, paid for by a full gate sweep on a structurally dead pick)

**This skill ranks on repo CLEANLINESS. That is a different axis from DIFFICULTY STRUCTURE, and a
candidate can score top on the first and bottom on the second.** Measured: lyon shape-recognition
cleared all ten PICK-FILTER gates — zero open PRs repo-wide, the target file had two commits ever,
every prior-art search empty against live positives, maintainer philosophy positive, 158 tests
deterministic 3x, and four traps REPRODUCED on base — and was still dead, because a recogniser over
the public event stream is `failure-patterns.md § 5`'s explicit anti-target and its traps are
INDEPENDENT rather than interdependent. Full case: `TOO-EASY.md § RECOGNISER / POST-PASS`.

Ask these four before writing the dossier's verdict line:

1. **Is there ONE shared kernel feeding SEVERAL surfaces**, such that a local fix to one surface
   REGRESSES another? If the answer is "no, it is one self-contained function/module", the pick is
   dead however rich its case analysis. (Corpus: ~13 of 16 approved picks have this.)
2. **Are the traps INTERDEPENDENT or merely several?** Write them out and ask, for each pair, whether
   fixing A surfaces or breaks B. A pile of independent case-analysis details is L2/L3 dead — smart
   agents single-shot-fix each one.
3. **Could a standalone new file with minimal wiring solve it?** That is an explicit Phase-3 reject.
   Post-passes over a public event/AST/token stream almost always are.
4. **Run `TOO-EASY.md`'s Pre-Pick Guard 1-5 verbatim.** Guard #2 (single-subsystem fully-specified
   transform) is the one that catches this class.

A candidate failing any of these does not go to `olympus-author`. Pivot the FEATURE, not the wording,
and re-rank the shortlist on coupling rather than on availability.

### Then the gates

Before `olympus-author`, the chosen candidate must clear the full
**`PICK-FILTER.md` 10 gates** — this skill pre-clears 2 (saturation), 7 (dedup), 9 (flaky), 10
(quota) and partially 4 (LOC ceiling). Still owed at scope-lock:

- **Gate 1 BEHAVIORAL-F2P-GAP** — base must produce observably wrong output (decisive)
- **Gate 5 COLD-NOT-LIVE** — check commit DATES in the target subsystem, not issue state
- **Gate 6 REPRODUCE-ON-BASE** — run the repro through the real entrypoint
- **Gate 7b EXCLUSIVITY** — resolve the canonical org first (`gh api repos/O/R -q .full_name`),
  then search PRs by feature CLASS in all states and **read the DIFF, not the PR body**. A public
  draft PR touching your core file set is a hard reject; this class has killed 5+ picks
- **Gate 8 DEFINED-BEHAVIOR** + maintainer philosophy (the six-check in `CLAUDE.md`)

---

## Kill list — reject on sight

| Signal | Why |
|---|---|
| In `SATURATED-REPOS.md` **section A/B/C/D/E**, or ≥6 of our subs | Platform warns at submit; extra scrutiny. (A B1/B2/B3 lane-ledger hit is NOT a kill — pick another lane) |
| GPL / AGPL / NCSA / rider-BSD | Hard license reject |
| >5000 stars with a famous spec (JSON, semver, java.time, SVGO, Box2D) | Training-saturated; a faithful port is a dead class (`TOO-EASY.md`). High-star repos are admissible only where the CAPABILITIES are repo-internal — a high-star repo implementing a famous spec is still dead |
| CGO / `-sys` crates / vendored C | Docker cost, offline-build risk |
| Mock-heavy test suite | Cannot write behavioural test patches |
| Flaky baseline | Gate 9, mandatory reject |
| Feature set is a list of independent rules | `failure-patterns.md` L2 — caps ~67% pass no matter how many rules |
| Single-package, no pipeline | No seam; cannot reach cross-subsystem scope |
| Best pick is a NAMED external standard AND a long-open uncommented issue asks for exactly it (or it is a faithful port) | Derivative magnet — the name is the spec, so authors converge (Stage 2b). Nameable ALONE is a mitigation, not a kill (softened 2026-09-09-B) |
| Repo has an open, uncommented, long-lived issue asking for a famous feature | Every author picks it; the SIX-CHECK is blind to the pipeline (Stage 2b) |
| Active maintainer workstream in the target CAPABILITY (not merely the target files) | Corrected Gate 5. A `fix/<topic>-*` branch family or >=4 merged PRs in one narrow lane means that lane is dead — pick another lane, not another repo (Stage 2c) |
| Two or more TRACKER-SOURCED candidate lanes already dead in the same repo | Lane density, not bad luck. A further tracker-sourced candidate is a coin flip at the same odds (veryl: 4 for 4). One INVENTED lane (built from the source tree, not the tracker) is still allowed before stopping |
| Core dirs frozen for 12mo while the periphery stays busy, and you have NOT checked for a live fork | Ambiguous: either a real cold seam or a dead upstream. `gh api "repos/O/R/forks?sort=newest"` — a livelier low-star fork means the coldness is a corpse (`SATURATED-REPOS.md § E`) |

## Anti-patterns for the hunt itself

- **Do not rank by stars.** risor at 902 stars is the most over-used repo on the platform.
  Submission count is uncorrelated with stars.
- **Do not shortlist on the README.** The seam audit needs the source tree.
- **Do not skip the clone.** Every mechanical filter can pass on a repo with no coupling.
- **Do not pick from the issue tracker.** `RULES.md`: invent original features; open issues limit
  scope and may carry solutions in the comments.
- **Record relaxations.** If you widened the issue or star window, say so — it changes the
  saturation risk the next author inherits.

## ⚠️ Disk discipline (measured cost, 2026-08-04)

A hunt clones repos and builds them; the builds are what fill the disk. Clone 3-32M, target 1-5G.
`df -h /home` before any build, prefer scoped builds, and `rm -rf worktrees/<repo>/target` the moment
a measurement is recorded. Keep the clone for shelved-but-viable candidates so the audit is not
repeated. There is NO local Docker here, so Docker feasibility is always an ESTIMATE, never a test.


## Seam rows added 2026-08-07 (lyon-fill-internal-vertices)

- **F-17 proxy-metric drift** — target repos whose core emits a STRUCTURE nothing external names (vertex/node/index set). Grep `fn .*triangul|fn .*simplif|boundary|manifold`. Measured 8/10 top killer.
- **F-24 absent-key sentinel** — target repos whose resolver throws on a missing name AND whose own
  suite never exercises that throw, where your feature adds a graph/closure pass over the same
  namespace. The strongest measured single-clause lever available to a "derive X from the existing
  declarations" pick: 8/10 in two independent batches on dfu-derived-recursion.
- **F-25 placeholder lifetime** — target repos with a registration/builder phase whose public API
  hands unresolved handles back to caller code. Free companion to any F-24 pick: the same pass that
  creates the sentinel pressure creates the placeholder.
- **F-21 type-check shortcut** — target repos with a builder/visitor/sink INTERFACE plus an `Abstract*` base holding the state, and no accessor on the interface. Java and Rust trait-object APIs both qualify. Measured 5/10 top killer and sole near-miss failure on datafixerupper.
- **F-16 unparameterised setter** — repos with an options struct carrying a boolean `with_*` setter. Grep `fn with_[a-z_]*\(mut self, [a-z_]*: bool\)`. Measured 4/10 but it is a COMPILE error: bonus only.
