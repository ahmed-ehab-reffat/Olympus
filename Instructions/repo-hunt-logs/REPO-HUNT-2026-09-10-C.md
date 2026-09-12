# Repo hunt 2026-09-10-C — named-domain-engine axis + proven-pool second-lane mine; 0 scope-locked, 1 major competitor account mapped

Third hunt of the day. 09-10 produced DataFixerUpper (authored); 09-10-B produced jte and protobuf-es,
**both dead at Gate 8**. This session dropped the blind topic sweep (09-09-B measured three sweeps /
~190 topics -> one clean repo) for two new axes: a **named niche domain-engine list** (the shape the
approved corpus actually rewards — new capability = new domain mathematics) and a **proven-pool
second-lane mine**.

**No scope-locked candidate. The session's real product is intelligence:** three repos killed with
hard evidence, one high-volume competitor account mapped across ~16 repos, a dead-list construction
bug fixed that had been silently re-admitting killed repos, and two live leads left standing.

**Ordering change proven this session — run the gates in this order from now on:**
`mechanical -> Stage 2b-bis competitor profiling -> Gate 8 in PROBLEM vocabulary -> seam audit.`
Every kill today came from steps 2 and 3. The seam audit is the expensive step and it is the one that
must go last.

---

## Killed this session

### pybamm-team/PyBaMM — THIRD kill, now with a documented reason

Previously screened twice (`08-07-D` capability wave, `09-09` PR-blanketed). The 08-07-D note said the
shape was excellent and to revisit **if the unstructured-mesh wave landed**. It landed (#5687, #5688
MERGED), and the repo turned out to be mechanically BETTER than either earlier screen recorded:

- BSD-3-Clause, ★1657, Python, `uv` monorepo. **CI GREEN on `main`** — the 09-09 Requirement-7 doubt
  was WRONG: the failing rows are `event=pull_request` on PR branches. This is the softened-gate
  lesson in its exact form; filter by the default branch and read the event.
- **Zero AI-sweep marks in 300 commits**, despite shipping `AGENTS.md` + `CLAUDE.md` + `GEMINI.md` +
  `QWEN.md` + `.cursorrules` at the root. Those are contributor guidance, not a maintainer sweep — the
  root-level agent files are a prompt to run the probe, never a verdict on their own.
- Genuinely the right SHAPE: a repo-internal computer algebra system, and a real pipeline
  `Model (symbolic) -> ParameterValues -> Geometry -> Mesh -> Discretisation -> Solver -> Solution`
  where discretisation destroys the symbolic structure (F-1) and `processed_variable*.py` re-derives
  named variables from raw solver output (F-9). Tracker carries OPEN, UNCOMMENTED core bugs in that
  lane (#5414 separator IndefiniteIntegral edge-shape, #5192 rhs/initial_conditions shape mismatch,
  #5152 variable ordering), i.e. nobody is sweeping it.

**Killed on Stage 2b-bis.** `binggao1230` — a RECORDED signature account (also on cantools and petl) —
holds **NINE open PRs**, and they are capability-shaped f2p work, one squarely in the target lane:

- *"Fix #4930: discretise `Variable.reference` / `scale` so r/x in initial concentration don't leak"*
- *"Fix #5018: exclude internal 'start time' InputParameter from termination check"*
- *"Fix #2484: include unsaved cycles in solve_time / integration_time"*
- *"Let CRate accept callables for its default duration (#4926)"*

Alongside `medha-14` 8, `Rishab87` 4, `martin1cifuentes` 3, `mleot` 3, `AIMindCrafter` 2,
`vidipsingh` 2, `swastim01` 2. All three softened reject thresholds are met simultaneously: a recorded
signature account, a burst, and a signature PR inside the intended lane.

### beartype/beartype — solo-maintainer roadmap tracker + PEP-named capability space

★3493, MIT, Python, CI green on `main` (real `tests` workflow), competitor-clean (`posita` x13 is a
long-time genuine collaborator). Right shape on paper: a runtime type-checker that GENERATES checking
wrappers from hints, i.e. its own compiler pipeline.

Dead anyway. All 104 open issues are `[Feature Request]`/`[Docos]` items written in `leycec`'s own
voice with his own emoji, and he comments on them — **the tracker IS the maintainer's public roadmap**,
and it already enumerates every extension point (#53 deep type-checking, #391 dataclass field checking,
#589 generator checking, #644 class-variable defaults, #626 forward-reference resolution). On top of
that the capability space is PEPs — externally named by construction (484/544/593/646/692/747/810/827
all appear in the tracker), which is Stage 2b row 1 plus TOO-EASY guard #4. Style is a further tax:
the codebase is famously idiosyncratic and comment-dense.

### mozman/ezdxf — contested by the account mapped below

★1435, MIT, Python, tiny tracker (21 issues / 2 PRs). PR authors include `youdie006`, `origami7`,
`eXponenta`, `haluk-pointr`, `eeshsaxena` — several thin accounts at 2-3 PRs each. `youdie006` is the
account profiled below.

### Triaged out on shape, without spending calls

`haifengl/smile`, `oracle/tribuo` (ML = named published algorithms); `zeux/meshoptimizer` (solo
world-class maintainer shipping continuously, ★8316 penalty band); `petercorke/robotics-toolbox-python`
(named Lie-group mathematics — its sibling `spatialmath-python` was killed for exactly this in
08-07-D); `pyscf/pyscf`, `Cantera/cantera` (published methods; Cantera also C++/NOASSERTION with
sundials+eigen); `locationtech/jts` (EPL/EDL, and it IS the reference implementation that GEOS and
Shapely are ported from); `skyfielders/python-skyfield` (NOVAS/SPICE/astropy prior art);
`isl-org/Open3D` ★13950 and `gonum/gonum` ★8425 (penalty band). Licence/activity/star kills:
`libigl` + `ete` (GPL-3.0), `poliastro` (archived), `meshio` (last push 2024-07), `cclib`/`unyt`/
`spglib`/`diffpy.structure` (<500 stars), `pysam` (Cython/C-extension), `pyproj` (binding to the PROJ
C library — the 08-07-D reject still stands).

---

## ⭐ NEW SIGNATURE ACCOUNT — `youdie006` (high volume, overlaps our corpus)

Surfaced twice independently today: in the opensheetmusicdisplay swarm (09-10-B) and again on ezdxf.

- created 2024-05-09, **422 public repos**, 32 followers, name "KBS", no bio.
- PR footprint across mutually unrelated niche, permissively-licensed parsing/format libraries in Go,
  C++, TS and Python: `CloudyKit/jet`, `CrowCpp/Crow`, **`Eyevinn/mp4ff`** (a repo we hold a
  submission in), `NikolaLohinski/gonja`, `andybalholm/brotli`, `console-rs/console`,
  `dolthub/go-mysql-server`, `getkin/kin-openapi`, `hjson/hjson-go`, `jsonata-js/jsonata`,
  `kaptinlin/jsonschema`, `mattn/go-runewidth`, `mity/md4c`, `nyaruka/phonenumbers`, plus
  `opensheetmusicdisplay` and `mozman/ezdxf`.
- House style confirmed on osmd: *"fix(stems): don't force a lone secondary voice stem-down"*.

**Treat every repo in that list as CONTESTED.** This is the third recorded signature after
`binggao1230` and `ChrisJr404`, and the second to overlap our own corpus.

Also recorded, weaker: **`repowazdogz-droid`** (created 2025-09-22, 1 follower; forks-then-fixes across
`cedar-policy/cedar-spec`, `cvc5/cvc5`, **`e2nIEE/pandapower`** (our corpus), `pulp-platform/common_cells`,
`PyBaMM`; personal repos are AI-evals themed — `proof-carrying-evals`, `capability-budget-eval`,
`evaltrust`). Probably an agentic-benchmark builder; functionally the same competitor class.

Cleared as GENUINE (do not re-flag): `aabills` (Alec Bills, real PyBaMM researcher, the Aug 6-7 burst
is legitimate), `philocalyst` (Miles Wirht, coherent typst/cetz/nushell/gpui footprint),
`posita` (long-time beartype collaborator), `bunlongheng` (real name, 144 repos, web-dev footprint).

---

## Live leads left standing (next session starts here)

| Repo | ★ | State | What is owed |
|---|---|---|---|
| `asticode/go-astits` | 617 | MIT, Go, MPEG-TS demuxer. Tiny tracker (5 issues / 3 PRs) = responsive maintainer, a mild positive under the softened rule. PR authors look like genuine users (`k-danil` x6, `eric` x3). Was RANK ~3 on 09-06 and never taken | profile `k-danil`; Gate 8 in problem vocabulary; check the spec-named risk (MPEG-TS is a standard, but the demuxer state machine / PES assembly / PCR handling is astits' own model); absorption sketch |
| `obi1kenobi/trustfall` | 2882 | Apache-2.0, Rust query engine over pluggable adapters. **Competitor-clean** — the `philocalyst` x9 burst is a genuine contributor | maintainer `obi1kenobi` has 14 recent PRs -> run the Stage 2c lane histogram for capability-consuming before anything else |

---

## Both leads resolved the same session — BOTH DEAD

### asticode/go-astits — reference-toolchain prior art on the only coherent lane

Requirement 7 clears (`Test` workflow, success on `master`, push events). **Competitor-CLEAN** —
every PR author is a real, established video-domain developer (`tmm1` Aman Karmani 3104 followers,
`eric` Eric Lindvall 279, `thiagopnts` 282, `k-danil` Danil Korymov, `Vadym-Kupriyanchuk`). 9 real
code commits in 12 months, all from outside contributors; the maintainer only touched devcontainers.

The five open issues form one coherent lane — **demuxer recovery policy**: #71 stream already
transmitting, #67 192-byte Bluray packets, #50 muxer payload panic, #35 corrupted PES advertising a
wrong length, #25 complex PMT with multiple tables. That looked ideal, because MPEG-TS specifies the
FORMAT but not how a library should RECOVER.

**Killed by the repo's own commit history:** `fix(packet_pool): align discontinuity detection with
FFmpeg behavior` (KHuynh, 2025-10-27). FFmpeg's `libavformat/mpegts.c` is the reference toolchain for
every one of those behaviours, and the repo's own convention is to match it — so the correct answer is
transcribable from FFmpeg. Secondary: of 212KB non-test Go, **78KB is `descriptor.go`**, a flat DVB
descriptor table that amortises to one pattern; the actual engine files are small (`demuxer.go` 6.2KB,
`packet_pool.go` 3.8KB), so the LOC floor is a live risk.

### obi1kenobi/trustfall — EXCLUSIVITY-DEAD at the repo level (and we already knew)

On every gate this skill runs, trustfall looked like the best candidate of the session:

- Apache-2.0, ★2882, Rust. **CI green on `main`** (the failing rows are the scheduled
  `Bump dependencies in Cargo.lock` job, not the suite).
- **Competitor-CLEAN**: 75 `obi1kenobi` (almost entirely weekly `cargo update`), `philocalyst` x9
  (profiled — Miles Wirht, coherent typst/cetz/nushell footprint, genuine), then single PRs from
  `xd009642` (tarpaulin author) and `musicinmybrain` (Fedora packager).
- **The maintainer is in MAINTENANCE mode, not capability-consuming** — 153 commits/12mo and the
  non-bot ones are cargo updates, clippy fixes, security hardening and the Rust 2024 migration.
- **The core is COLD and BIG**: `interpreter` 3 commits/12mo, `frontend` 1, `ir` 2, `graphql_query` 1,
  `schema.rs` **untouched since 2022-01-20** — against `execution.rs` 61KB, `frontend/mod.rs` 50KB,
  `candidates.rs` 47KB, `interpreter/mod.rs` 35KB. No LOC-floor risk.
- **Gate 8 is POSITIVE**, the exact opposite of jte. `obi1kenobi` on #303: *"the query language
  currently doesn't have a way to do this. **It's a feature I'd love to add in the future though!**"*;
  on #268: *"I don't have a concrete timeline... **I need more community input** so I know what's
  important."* No refusal language anywhere in the lane.
- **Derivative risk LOW**: the capability space is Trustfall's own directives (`@fold`, `@recurse`,
  `@tag`, `@optional`, `@transform`), and the open requests (#342 combine `@fold` and `@recurse` on one
  edge — zero comments since 2023; #341 `@tag` inside a `@fold`; #268 `@optional` on type coercion)
  cannot be named without repo-internal nouns.

**Dead anyway, and our own workspace had already recorded it.**
`rejected/trustfall-prefix-candidates/feedback.md` ends: *"Net: trustfall has no clean Olympus for
us."* Draft PR **#617 "Allow `@transform` directive to be applied to properties"** (OPEN since
2024-06-11) is **+19053/-2812 across 602 files** and rewrites `frontend/mod.rs` (+895),
`interpreter/execution.rs` (+471), `ir/mod.rs` (+236), `graphql_query/directives.rs` (+245), a NEW
`interpreter/transformation.rs` (+297) and `hints/*`. That is the core machinery ANY directive-
semantics capability must touch, so the bright-line overlay test fails for every lane with LOC mass.
The prior verdict also killed the other candidate (`prefix-narrowing`, honest reference = **64
effective LOC**, sub-floor).

**Process failure worth its own note:** trustfall reached the front of the shortlist because the pool
scan checked `SATURATED-REPOS.md` only. The verdict lived in `rejected/<repo>-<slug>/feedback.md` and
was never consulted. That is the third instance today of dead knowledge failing to reach the filter.

## Method notes worth keeping

1. **⭐ Run the gates in kill-probability order: mechanical -> competitor -> Gate 8 -> seam audit.**
   Today's three kills came from competitor profiling and Gate 8. The seam audit costs the most and
   caught nothing. jte reached a built, Docker-validated harness before Gate 8 killed it.
2. **⭐ The dead-list must match bare `owner/repo` slugs AND basenames, not just `github.com/` URLs.**
   PyBaMM had been killed twice and is named in `SATURATED-REPOS.md`, yet passed the filter and cost
   ~20 minutes of re-screening, because kill-table rows cite it as `pybamm-team/PyBaMM` with no URL
   prefix. Corrected filter immediately caught three more (trimesh, pyroomacoustics, geogram) that the
   old one would have re-admitted. Build it as
   `grep -ohE '(github\.com/)?[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' | sed 's|github.com/||'` plus a
   basename pass, and test a candidate against all three forms.
3. **A `failure` row in `gh run list` is not a Requirement-7 reject until you check `event` and
   `--branch <default>`.** PyBaMM reads as failing and is green on `main`; the failures are PR-branch
   runs. The 09-09 screen recorded it as a Requirement-7 doubt and that was wrong.
4. **Root-level `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`/`.cursorrules` is a prompt to probe, not a verdict.**
   PyBaMM ships all five and has zero agent-authored commits in 300. Run the commit-author probe.
5. **A tracker written entirely in the maintainer's own voice is a roadmap, and a roadmap is a
   capability-consuming stream.** beartype's 104 issues are all `leycec`'s own feature requests. This
   is the same kill as an active PR queue, in a form the PR-queue probe cannot see.
6. **⭐ Pool-mining must read `rejected/<repo>-*/feedback.md`, not just `SATURATED-REPOS.md`.** The
   trustfall verdict ("no clean Olympus for us", PR #617 exclusivity) was sitting in our own
   `rejected/` folder and cost a full audit because the pool scan never opened it. Grep the repo slug
   across `rejected/*/feedback.md` and `rejected/*/DESIGN.md` at pool-mine time.
7. **A repo can pass EVERY gate in this skill and still be dead.** trustfall cleared mechanical,
   Requirement 7, competitor profiling, lane density, Gate 8 (positively), derivative risk, LOC and
   coldness — and died on one draft PR touching 602 files. Run Gate 7b exclusivity with the FILE
   OVERLAY, not a keyword search, before celebrating any candidate.
8. **The named-domain-engine axis mostly returns reference implementations.** Of ~30 probed, the
   majority died because the library IS the canonical implementation of its domain (jts, pyproj,
   skyfield, Cantera) or its capabilities are published methods (pyscf, smile, tribuo, robotics-toolbox).
   The axis is still worth running, but filter for "obscure DOMAIN whose capabilities are NOT named by
   an external body of practice" before spending API calls.
