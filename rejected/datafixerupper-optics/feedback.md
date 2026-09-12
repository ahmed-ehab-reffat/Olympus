# datafixerupper-optics (folder name provisional until Phase 3 scope-lock)

Repo: https://github.com/Mojang/DataFixerUpper — MIT, Java 17, 1311 stars.
Base commit: `5fc0978694e996cfe68a742b67a0d506c17de3f0` (2026-05-05) — the SAME base as both prior
picks, so the environment is already platform-proven.
Clean worktree: `worktrees/dfu-optics` (the `worktrees/DataFixerUpper` clone carries the in-flight
`derived-recursion` solution and must NOT be disturbed).
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-10-C.md`.

## Why this repo, after ~20 candidates died on 2026-09-10

Every other candidate died to one of: competitor swarm, maintainer-declined capability class,
reference-toolchain prior art, or a large open PR. DFU is the one profile that survives all four:
a LIVE repo with a genuinely DEAD subsystem. It has already produced one accepted and one authored
submission from two different lanes.

## Verification — ALL GATES PASSED (2026-09-10)

| Gate | Result |
|---|---|
| Stars / licence / language | 1311, **MIT** (single, nothing vendored), Java 17 |
| Activity (Req 3) | last commit 2026-05-05 |
| Pure-language (Req 5) | deps all Maven Central: gson, guava, fastutil, jsr305, slf4j, junit |
| Live upstream (Req 6) | issues + PRs on GitHub with community authors (CI is Azure DevOps, `.ado/build.yml` runs `gradle build test`) |
| **Req 7 CI green** | verified LOCALLY instead of trusting `gh run list`: 484 main classes compile clean with `javac --release 17`, suite **52/52 OK** |
| **Gate 9 determinism** | **52/52, three runs, identical**, `--network none --user 4242` in `olympus-base-jvm` |
| Docker | built and run here; reuses the platform-validated Dockerfile from `approved-problems/datafixerupper-ordered-alternatives` |
| Quota | **2 of 6 used** |
| Stage 2b-bis competitor | **CLEAN** — every PR author is a Minecraft-ecosystem dev with a coherent footprint; zero recorded signature accounts, zero AI-sweep marks in 12 months |
| Stage 2c lane density | `optics` **0 commits/24mo** (last 2024-03-19), `functions` **0** (2024-03-07), `kinds` **0** (2020-05-11) vs `serialization` **12**. The maintainers' entire stream is the codec DSL |
| Self-collision | approved pick = `serialization/Codec.java` + `codecs/OrderedAlternatives*`; authored pick = `datafixers/schemas/Schema.java` + `types/templates/TaggedChoice`. **`optics/` and `functions/` are untouched by both** |
| **Gate 8 philosophy** | **CLEAN** — zero refusal language across the whole 27-issue tracker (all states). No roadmap, no declines. The tracker is entirely about codecs and schemas, so the optics lane carries no magnet either |

## ⚠️ HARD CONSTRAINT carried into Phase 3 — exclusivity

`functions/PointFreeRule.java` is **EXCLUSIVITY-DEAD**. Open PR
[#109](https://github.com/Mojang/DataFixerUpper/pull/109) "Various tests, tweaks and optimisations" is
**+58/-33 on `PointFreeRule.java`**, +34/-31 on `RecursiveTypeFamily.java`, and publishes **647 lines of
new optimizer tests** (`RuleOptimisationTest.java` +427, `PointFreeRuleTests.java` +220). Any pick whose
core machinery is the point-free rewrite optimizer fails the file-overlay test.

**CLEAR** (no open PR touches them): the whole `optics/` package (`Lens`, `Prism`, `Affine`, `Grate`,
`Adapter`, `Getter`, `ListTraversal`, `Optic`, `Optics`, `Procompose`, `profunctors/`, `Forget*`,
`ReForget*`, `Proj1/2`, `Inj1/2`, `InjTagged`, `PStore`), plus `TypedOptic.java` and `OpticFinder.java`.
`DSL.java`, `Type.java` and `TypedOptic.java` are touched only by #25 (a Guava-removal cleanup, +/-2..6
lines each) and #100 (annotation swap, +1/-1) — cosmetic plumbing, not core machinery.

Full open-PR file overlay is in the hunt log. Re-run it at submit.

## Owed in Phase 3 (olympus-author)

- Choose the capability from the source tree, NOT the tracker. Then run absorption with a named
  algorithm and an eff-LOC sketch against the nearest existing sibling optic.
- Re-run the Gate 8 search in the maintainer's PROBLEM vocabulary for the chosen capability, not the
  design's nouns (this is what killed jte on 2026-09-10 after a full harness build).
- `test.sh` + JUnit XML: JUnit **4** only in the image (`junit-4.11.jar`), so the runner is
  `org.junit.runner.JUnitCore` plus a reporter, exactly as the approved pick's 390-line `test.sh` does.
  Reuse it.

## Attempt history

(authoring starts here)
