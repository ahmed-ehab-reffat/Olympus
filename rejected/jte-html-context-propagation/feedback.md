# jte-html-context-propagation

Repo: https://github.com/casid/jte (Java, Apache-2.0, 1136 stars, quota 0/6, never previously submitted).
Base commit: `a271c27d21447fbfce3e91b2e59491e3855998ac` (2026-09-01).
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-10-B.md` (RANK 1).

## Pre-authoring gates, all closed before any code

- **Requirement 7 (CI runs its own tests, green):** `.github/workflows/maven.yml` = "Test all JDKs on all
  OSes", success on `main` 2026-09-01.
- **Gate 9 determinism:** `mvn -pl jte-runtime,jte,jte-kotlin -am test` three times, locally and in the
  image: **1207 tests, 0 failures, 0 errors, 0 skipped, identical every run.** No flaky baseline.
- **Gate 1 / Gate 6 behavioural F2P gap, reproduced on base** through the public API:
  - `<style>${v}</style>` renders `url('javascript:alert(1)')` verbatim (only `&<>` escaped) while the
    same value in `<script>` is JS-escaped -- the parser computes `isStyle` at `TemplateParser.java:1134`
    and it never reaches the output.
  - `<iframe src="${v}">` passes `javascript:` through while `<a href>` is correctly blanked; the scheme
    guard in `OwaspHtmlTemplateOutput.writeTagAttributeUserContent` is hardcoded to `"a"` + `"href"`.
- **Gate 7b exclusivity:** canonical org `casid/jte`, no redirect. `gh search prs` all states for
  escape / escaping / css context / url attribute / javascript escaping / contextual / style attribute /
  srcdoc: nothing implements a context model. Merged #227 produced the CURRENT `Escape` class (base state).
- **Gate 8 philosophy:** `<script>`-block template calls are philosophically CLOSED (#437, maintainer
  holds the line) -- AVOID that sub-lane. The HTML-attribute/escaping lane is welcomed (#540, no design,
  no PR). Issues INFORM only; they must never BIND the spec.
- **Stage 2b/2b-bis/2c:** competitor-clean, compiler core cold (3 small parser fixes in 12 months), no
  self-collision (no template-engine pick anywhere in the corpus).
- **Stage 3b absorption:** the missing algorithm is a per-context escaping model resolved from the
  parser's own tag/attribute state and carried across the visitor boundary into both backends. Sketch
  ~380-420 eff LOC across 6-9 files in 3 Maven modules.

## Harness — VALIDATED IN DOCKER

`Dockerfile`: `olympus-base-jvm` (JDK 17.0.19, Maven 3.9.9 already in the image), local repo warmed at
`/opt/m2` at BUILD time by running the real test target, then `clean`, then `chmod -R a+rwX /app`.
`test.sh` runs Maven with `-o` (offline).

Verified `--network none --user 4242`:

| Mode | Result |
|---|---|
| `base` | exit 0, **1207 tests, 0 failures**, 1m39s |
| `new` (before any new tests exist) | exit 1, valid JUnit, 1 synthetic failure carrying **7446 chars of the real Maven log** |

Base mode is scoped to `-pl jte-runtime,jte,jte-kotlin -am`. Rationale: those are the three modules the
solution touches plus their parents. The excluded modules are the Spring Boot starters (2/3/4), the JSP
converter, the Maven/Gradle plugins, `jte-models`, `jte-watcher` and `test/jte-hotreload-test` -- none is
touched by the capability, and the hot-reload and Spring modules are the slow, environment-sensitive ones.
This is NOT the L31 anti-pattern: no test covering modified code is excluded.

New tests use the suffix `*_992462Test` (random hex, unpredictable, no banned markers); base mode runs
`-Dtest='!*_992462Test'` and new mode `-Dtest='*_992462Test'`, both with
`-Dsurefire.failIfNoSpecifiedTests=false` (note: the `surefire.` prefix is required -- without it the
reactor fails on modules with no matching test).

## Derivative caveat carried into authoring

An outsider can name the lead thesis ("context-aware escaping"), and contextual autoescaping has canonical
implementations (Go `html/template`, Closure Templates). MEDIUM under the 2026-09-09-B softening. Plan:
author the CORE SLICE first and run the free platform precheck on it BEFORE hardening
(`feedback_precheck_at_first_slice`). If the dedupe flags it, pivot to the recorded fallback thesis
(widen `HtmlPolicy` so it sees the parser's structure -- pure F-21, names nothing external).

## Attempt history

(nothing yet -- authoring starts here)

## SHELVED 2026-09-10 — Gate 8, maintainer-declined capability class

Killed at author Phase 2, before any test or solution code was written.

Issue #387 "Allow the developer to choose the escaping strategy" (OPEN since 2024-10-01) quotes the
exact `attributeName.startsWith("on")` line this thesis targets. `kelunik`: "we don't really plan to
support context dependent escaping for JS." Owner `casid`: the `OwaspHtmlTemplateOutput` is "just one
implementation of `HtmlTemplateOutput`" and a context-aware variant is something a USER writes. Plus
#437 (template calls in `<script>` declined) and #252 (JS inlining, closed).

The hunt's Gate 8 pass read five issues in the lane and missed #387 because its title carries none of
the design's nouns. See `feedback_gate8_search_the_problem_vocabulary`.

The Dockerfile and the base-mode harness in this folder ARE validated and reusable if anyone returns
to this repo: `olympus-base-jvm`, Maven repo warmed at `/opt/m2` at build time, offline non-root base
mode 1207 tests / 0 failures, new-mode fallback carrying the real Maven log. Nothing else here is a
submission.
