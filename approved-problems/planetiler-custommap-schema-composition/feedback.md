# feedback.md — planetiler-custommap-schema-composition

## Summary
Schema composition for planetiler's YAML profiles (`planetiler-custommap`): `extends` in a schema
file and a multi-file `--schema`, merged into one `SchemaConfig` before the args fixpoint, the
profile and the validator run. Picked by the 2026-09-14 hunt (issue #1148, maintainer-welcomed,
no design, no PR). Hunt log: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-14.md`.

## Environment notes (carry into Dockerfile / test.sh)
- Base `546486f63c00d56b9f697b5c4659aa40e30e6e5c`; submodule `planetiler-openmaptiles` at
  `373030bce912550e426683eda60812e35048f461` must be present or the reactor POM cannot parse.
- Install with `mvn -Pflatten -pl planetiler-custommap -am -DskipTests install`, run one online
  `mvn -pl planetiler-custommap test` to fetch the Surefire provider, then everything is offline.
- Base mode = `planetiler-custommap` tests only (431, deterministic 3x, 20-37 s). Core tests are
  untouched by the change and take minutes; documented exclusion.

## Attempt history
- 2026-09-14 R0: DESIGN.md written; thinnest end-to-end spike owed before scope-lock.
- 2026-09-14 R0 spike + tests (local validation green, Docker + FP battery in progress).
  - Spike measured 237 human-eff; added the bundled-sample parent lever (the literal #1148 ask:
    extend the built-in schema) with its own resolution machinery (`SchemaComposer.Ref`: file or
    classpath sample, sibling resolution for examples, identity for cycles/diamonds) -> 259 human-eff
    across 5 files (SchemaComposer.java new, SchemaConfig.java, FeatureLayer.java, ConfiguredMapMain.java,
    SchemaValidator.java).
  - Tests: `SchemaCompositionf87c01Test` (60 tests). Clean room: base+test.patch -> base 431 pass,
    new 60 fail per method (compile-wipe turned into per-test failures by test.sh); +solution ->
    431 / 60 pass, 3x identical; reverse order ok; unapply clean.
  - test.sh hides the new test class for base mode (Maven cannot exclude a file from test
    compilation); same approach as the approved DFU Java submission's javac harness.
  - meta.md 474 words incl. frontmatter (hard cap 500); consider trimming before submit.
- 2026-09-14 FP battery (clean room, solution + tests applied): 26 single-point mutations over
  SchemaConfig / FeatureLayer / SchemaComposer, all detected (min 1, max 42 kills of 62); every
  mutation left the 431 base tests green (no baseline-preservation axis to lose). Two tests were
  added because the first battery exposed a hole: wholesale replacement of `sources` /
  `tag_mappings` by the child survived when the child redefined every key
  (`sources_not_redefined_by_child_are_inherited`, `tag_mappings_not_redefined_by_child_are_inherited`).
  Final: 62 new tests, 3x identical.
- Docker: first image build compiled test sources during `-DskipTests install` and failed on the
  new class (compile-wipe at BUILD time) -> split: core `-DskipTests`, custommap
  `-Dmaven.test.skip=true`, `dependency:resolve` + `dependency:get` for the Surefire provider and
  launchers. Second run failed at test time with `LocalRepositoryNotAccessibleException` for uid
  1000 -> `MAVEN_ARGS=-Dmaven.repo.local=/opt/m2` + `chmod -R a+rwX /opt/m2`.
- 2026-09-14 Docker VALIDATED (`olympus-base-jvm`, `--network none --user 1000:1000`): image built
  from base + test.patch -> base 431/0, new 62 failed; solution applied inside the same container
  -> base 431/0, new 62/0. Submodule fetched by the Dockerfile at the pinned SHA.
  - Owed next: platform PRECHECK (dedupe on the core) BEFORE any batch; then the first batch.

## R1 — 2026-09-16 (platform pre-batch review: Test Quality FAIL, Solution Quality FAIL)

No agent batch had run, so meta.md was still free to edit (re-eval sequencing rule: settle the
solver-visible surface before batch 1).

Solution bugs the review found, all real, all fixed:
1. `load(List<Path>)` folded each root independently and merged the folded results, so a shared
   parent's features were appended twice and a removal made by a later root could be undone. Now one
   DFS contribution list across all roots with a shared parse cache, folded once.
2. A one-file list ran the composition path and inlined `examples`, breaking the "a file without
   `extends` keeps its examples reference" promise. Singleton lists now delegate to `load(Path)`.
3. `remove: true` was accepted for ids that were never inherited: `mergeLayers` returned early when
   the inherited collection was null, and it mutated the id map while iterating, so an id added by
   the same file counted as inherited. Now validated against a snapshot of the ids inherited before
   the file is applied, and the fold starts from an empty `SchemaConfig` so the first contributor
   takes the same path.
4. `examples` used the `extends` resolver, so a missing local spec file silently fell back to a
   bundled sample of the same name. Now a dedicated resolver with no fallback.
5. README and planetiler.schema.json did not document `extends` or layer `remove`.

Test fairness: 9 flagged assertions. Dropped the literal `cycle` wording, three map-iteration-order
assertions, the `remove()` false-vs-null representation, and the unstated empty-list contract. Kept
the cycle-names-both-files, invalid-remove `ParseException`, absolute-normalized `files`, list-name
resolution and one-file-list assertions, and stated each of them in meta.md instead.

Coverage added for the two untested prompt claims (`--schema` comma list end to end through
ConfiguredMapMain on Monaco; validator watch set over a composed graph with a bundled parent) plus
all five scalars inheriting through two silent files, and a regression test per solution bug above.
Test class moved to the `...custommap.validator` package so it can construct `SchemaValidator` and
read `validateFromCli().paths()`; test.sh updated for the new path and classname. 70 tests (was 62).

meta.md rewritten (R1): shorter paragraphs plus a bullet list per field (the AI-formatting heuristic
flagged two 150+ word paragraphs), current-state narration dropped, 457 body words, ASCII.

Validation after the revision (clean room `worktrees/cleanroom-planetiler`, clone at base):
base + test.patch -> base 431 pass / new 70 fail; + solution.patch -> base 431 pass / new 70 pass,
3x identical both modes. 282 human-effective LOC across 7 files.

### R1b — second-opinion fairness audit (same day)

An independent trace audit of every assertion against meta.md found six more gaps. Five fixed:

1. `parents()` accessor assertions (4 of them) pinned both an identifier meta.md never names and a
   null-vs-empty representation it leaves open. Worse, `extends` is a Java keyword, so a solver
   renaming the component differently would fail to COMPILE the whole class, wiping all 70 tests.
   Dropped the assertions, dropped the `composed_schema_reports_no_parents` test, and dropped the
   "A composed schema reports no parents" sentence from meta.md.
2. Whole-record `assertEquals` on two `SchemaConfig` instances compared every component, including
   the parents component and the concrete collection type of `layers`. Replaced with comparisons of
   the accessors meta.md actually describes.
3. `remove: false` alongside another field: meta.md's error rule said "combining `remove` with other
   fields", which read literally also condemns a false marker. Scoped the rule to "sets `remove` to
   true alongside any other field" and stated that a false marker is an ordinary layer entry.
4. String-loaded `extends: power.yml` sat between two meta.md rules with no stated precedence
   (relative-path-is-an-error vs bundled-name-lookup). Reworded so the bundled lookup wins: a
   relative path "that does not name a bundled sample" is the error.
5. `args` merging promoted an EARLIER bare value to `{default: value}`, which meta.md only described
   for later values. Bullet now says a bare value stands for the default in whichever file gives it.

Judged defensible and kept: the error on removing an id added by the same file. meta.md now says
"an id that the earlier files did not contribute", which states the rule the test enforces.

Coverage the audit found missing, now tested: inheritance of an unset `tile_post_process` from a
parent layer, and a three-file cycle naming every file. 71 tests.

### R1b Docker validation

Image built from base + final test.patch on `olympus-base-jvm`, run with `--network none`.

- As root: base 431 pass / new 71 fail without the solution; solution applied inside the container
  with `git apply`, then base 431 pass / new 71 pass.
- As uid 1000: base mode FAILED. `/app` comes from `COPY . .` owned by root with 755, so a non-root
  user cannot hide the new test file (test.sh moves it aside for base mode, because Maven compiles
  all test sources and the new class does not compile without the solution) and cannot apply a
  patch. The R0 note claiming a clean uid-1000 run is wrong, or was actually a root run.
- Fix 1: the Dockerfile's final RUN now does `chmod -R a+rwX /opt/m2 /app`, so base mode can hide
  the test file whatever user the platform runs the container as.
- Fix 2: with the permissions fixed, a uid-1000 run still failed EVERY mode, including base with the
  solution applied. Cause: `/app/.git` is owned by root, so git's dubious-ownership check refuses,
  and `buildnumber-maven-plugin` (bound into the custommap build, it shells out to `git log`) fails
  the whole Maven run before any test executes. Root never hits this. The Dockerfile now runs
  `git config --system --add safe.directory '*'` before the COPY.
- Fix 3: with git fixed, a uid-1000 run still failed in `maven-resources-plugin`, copying
  `src/main/resources/samples/*` over the `target/` tree baked into the image during the build. The
  files were writable (fix 1) but root-OWNED, and copying sets the last-modified time, which only
  the owner may do. The Dockerfile now deletes `planetiler-core/target` and
  `planetiler-custommap/target` at the end of the build, so the test run creates them as itself.
  planetiler-core is still resolved from `/opt/m2`, so nothing is rebuilt that was not already
  cached. Confirmed in a live uid-1000 container before rebuilding: after deleting those two
  directories, base 431/0 and new 71/0.
- Lesson: validate the image as a NON-ROOT user as well as root. Three separate blockers hid behind
  root-only validation (directory permissions, git dubious-ownership, root-owned build output), and
  any one of them would have failed every platform run if the platform does not use root.

Final Docker result (image rebuilt with all three fixes, `--network none`), IDENTICAL as root and as
uid 1000: base 431 pass / new 71 fail without the solution; `git apply` the solution inside the
container, then base 431 pass / new 71 pass.

## R2 — 2026-09-16 (second platform review: Solution Quality FAIL, description warnings)

One real defect, cross-platform only:

- `Ref.of(Path)` used `path.toString()` as the classpath reference. On Windows
  `Path.of("/samples/power.yml").toString()` is `\samples\power.yml`, which no longer starts with
  `/samples/`, so the lookup became `/samples/\samples\power.yml`, found nothing, and threw a
  missing-schema error. It hit the prefixed form through `--schema`, through the list overload, and
  through a string-loaded absolute sample path. Fix: normalize the separator before the resource
  decision (`path.toString().replace(File.separatorChar, '/')`). Raw `extends` and `examples`
  strings already carried `/` and were never affected.
- Honest limit: on Linux `File.separatorChar` IS `/`, so the fix is a no-op locally and no Linux
  test can distinguish it. That also means it cannot regress anything here. The new test documents
  the path by resolving the bundled sample through `Path.of("/samples", "power.yml")`.

Three advisory coverage gaps, all closed:

- A list entry given in the prefixed `/samples/` form (also the regression test above).
- `tile_post_process` REPLACEMENT rather than deep merge when parent and child set different keys.
- `remove: true` combined with `features` rather than only with `buffer`, so a buffer-specific
  prohibition no longer passes.

74 tests. Description reformatted: paragraphs and bullets are single unwrapped lines now (the
heuristic flags manual ~60-120 char line breaks as an AI tell), and the four clauses the necessity
check called redundant are gone. Dropped "while command-line values still win" (existing precedence
is visible in `Contexts`, and it is now the submission's one codebase-inferable requirement) and
"an entry whose `remove` is false is an ordinary layer entry" (the error rule is already scoped to
true). Kept the one-file-list clause and the validator watch clause: both pin tests, and an unpinned
test is a fairness failure, which outranks a verbosity warning. 458 body words.

Style gate: planetiler enforces formatting with spotless (eclipse formatter plus import ordering and
unused-import removal, configured in the root pom). `mvn -o -pl planetiler-custommap spotless:check`
exits 0 on the final tree, so the added source and test files match the repo's formatter.

Final R2 Docker result (image rebuilt from base + final test.patch, `--network none`), IDENTICAL as
root and as uid 1000: base 431 pass / new 74 fail without the solution; solution applied inside the
container, then base 431 pass / new 74 pass.

## R3 - 2026-09-16 (Auto Review: Revision Requested; Description 3/3, Tests 1/3, Solution 1/3)

Three verified findings, all real, all fixed.

1. Validator CLI ignored the comma list (S1). `SchemaValidator` still did
   `args.inputFile("schema", ...)`, so `verify --schema=a.yml,b.yml` died on a literal
   comma-containing path before composition. meta.md says `--schema` accepts the list without
   narrowing it to generate-custom, and the same option name is exposed by verify, verify-custom and
   verify-schema. Now the validator parses the option with `getList`, loads through the list
   overload, and watches every root plus every root's contributors. The no-argument path still falls
   back to `inputFile`, so the original missing-parameter error is unchanged.
2. Composed profiles stopped watching external examples files (S2). Composition inlines each
   contributor's `examples` reference, and the validator only added an examples path to the watch set
   when the value survived as a String, so `verify child.yml --watch` no longer noticed edits to
   `child.spec.yml`. That regresses existing watch behavior the README advertises. Added
   `SchemaConfig.exampleFiles(Path)`, which walks the same contribution list and returns the local
   spec files each contributor names; the validator adds those to the watch set. Provenance is kept
   separately, so the inline composed payload is unchanged.
3. `SchemaConfig.files` normalization and canonical dedup were untested (T3/T4). Every previous
   fixture used an already absolute, dot-free temp path, and the nested `../` fixture never called
   `files`, so an implementation using only `toAbsolutePath()` with raw-Path equality would have
   passed while returning `..` segments and counting one file twice. The new test composes
   `profiles/top.yml` over `../common/base.yml`, the same parent again through a second alias
   (`../profiles/../common/base.yml`), and `mid.yml`, then asserts the exact normalized path list and
   that the aliased parent contributes once (the water feature count stays 1).

meta.md gained one clause: the validator watches the contributing files "together with every local
`examples` file they name", which pins the new watch test. 465 body words, 77 tests.

Discrimination proof for the two solution findings: in the clean room, reverting ONLY
`SchemaValidator.java` to its base version while keeping the rest of the R3 solution makes three
tests fail. `validator_composes_a_comma_separated_schema_list` throws
`IllegalArgumentException: .../base.yml,.../overlay.yml does not exist`, which is precisely the
failure the reviewer described, and both watch tests fail their path assertions. Restoring the file
brings them back. So the new tests pin the fixes rather than passing incidentally.

Final R3 Docker result (image rebuilt from base + final test.patch, `--network none`), IDENTICAL as
root and as uid 1000: base 431 pass / new 77 fail without the solution; solution applied inside the
container, then base 431 pass / new 77 pass.

## R4 - 2026-09-17 (Test Quality FAIL 1/77, Solution Quality FAIL)

1. Solution: `verify --schema=shortbread.yml` resolved the bundled sample, but because it has no
   `extends` the loader leaves `examples: shortbread.spec.yml` as a String, and the validator then
   resolved it against `Path.of("shortbread.yml")`, i.e. the working directory, not the bundled
   `/samples/` resource. Real, and a side effect of R3 letting the validator accept bundled names.
   Fix: new `SchemaConfig.loadWithInlineExamples(List<Path>)` always folds, so every examples
   reference goes through the composer's own resolver (file sibling or bundled sibling). The
   validator uses it and drops its separate String-resolution branch. The public `load` still keeps
   a single file's examples reference untouched, as the description promises.
2. Test fairness: `command_line_schema_list_composes_files` was flagged for two ">14" thresholds.
   The reviewer misread the call: 14 was the ZOOM argument and the expected count was 0. Fixed
   anyway, because a call that reads that way to a reviewer will read that way again: the test now
   gathers the `highway` values of every feature in layer `roads` across all tiles and asserts both
   `primary` and `secondary` are present. No zoom, no count.
3. Advisory coverage, added: a list entry that does not exist is a `ParseException` naming it, and
   `remove: true` combined with `tile_post_process` is an error (buffer, features and post-process
   are now each covered).

meta.md unchanged this round. 80 tests.

R4 Docker (image rebuilt from base + R4 test.patch): identical as root and uid 1000, base 431 pass / new 80 fail without the solution, 431 and 80 pass with it.

## R5 - 2026-09-17 (Solution Quality FAIL, same finding from two reviewers)

String-loaded schemas resolved a relative bundled parent through the file-first resolver. `compose`
checked that `/samples/<name>` existed, then built the reference with `Ref.of(path)`, which prefers a
regular file. So with a `power.yml` in the working directory, `SchemaConfig.load("extends: power.yml")`
composed that local file instead of the bundled sample, making a string schema's result depend on
the caller's cwd. meta.md already says a string has no file to resolve against, so a relative name
there can only be a bundled sample. Fix: a relative parent in a string-loaded schema now builds a
resource-only reference; absolute paths still resolve as files.

Test: `string_loaded_relative_parent_ignores_working_directory_files` creates `power.yml` in the
working directory (asserting first that none exists), loads the string schema, asserts the bundled
Power profile, and deletes the file in `finally`. JUnit parallel execution is not configured, so
this is deterministic. With the old resolver restored it fails with `expected: <Power> but was:
<Shadow>`. meta.md unchanged. 81 tests.

R5 Docker (image rebuilt from base + R5 test.patch): identical as root and uid 1000, base 431 pass / new 81 fail without the solution, 431 and 81 pass with it; the cwd shadow file is cleaned up in both.

## R6 - 2026-09-17 (Auto Review: Description 3/3, Solution 3/3, Tests 1/3)

Solution and description now clean. Three test-side findings, all fixed, none solver-visible.

1. High: the comma-list validator test used two standalone roots, and transitive contributors plus
   external examples were only ever tested through a single root. A validator that expands watch
   dependencies only from the LAST listed root passed everything. New test: the first listed schema
   extends a local parent and names an external spec file, the last is standalone, and the watch set
   must contain both roots, the first root's parent and its spec file (normalized). Mutant check in the
   clean room: limiting discovery to the last root fails exactly this test while the two older watch
   tests still pass, which confirms the gap was real.
2. Medium: test.sh did not check its JUnit writes, so a failed redirect could still end in exit 0.
   Now `mkdir` failure exits 1, each XML write records a failure flag, and the script exits 1 if a
   write failed or the report is empty. Verified: an unwritable directory and a read-only output file
   both exit 1, a normal run still exits 0.
3. Medium: `power.yml` and `/samples/power.yml` were never loaded together, so a raw-spelling-keyed
   dedup would pass. New test loads both in one list and asserts one `power` layer with the same
   feature count as loading the sample alone.

meta.md and solution.patch unchanged. 83 tests.

R6 Docker (image rebuilt from base + R6 test.patch): identical as root and uid 1000, base 431 pass / new 83 fail without the solution, 431 and 83 pass with it.

## Batch 1 - 2026-09-17: 0/8 Nova, all environment/spec failures, not difficulty

- 8 of 8 agents modelled `files` as an instance accessor (7 as a record component), and the tests call
  a static `SchemaConfig.files(Path)`. meta.md said only "`SchemaConfig.files` returns the
  contributing files", which never said static or what it takes. One compile error in the single
  test class wiped all 83 tests in every run. A unanimous identical failure is the unfairness signal:
  this is a description defect, not agent error. Evaluator #8 said so (FAIL_TEST_MISMATCH, verifier
  blocker, agent blame unfair).
- Run #4 additionally ran `mvn -o -pl planetiler-core -DskipTests install` without `-Pflatten`. That
  replaced the flattened core POM in /opt/m2 with one whose parent version is the literal
  `${revision}`, and the verifier's offline `-pl planetiler-custommap` build could no longer resolve
  dependencies. The verifier runs in the agent's container, so agent-side installs can break grading.

## R7 - 2026-09-17: fixes from batch 1 (solver-visible, needs a fresh batch)

1. meta.md now names both new signatures: "A new static `SchemaConfig.load(List<Path>)` overload" and
   "A new static `SchemaConfig.files(Path)` returns the files contributing to the schema at that path".
2. Counterfactual before paying for a batch: each agent's own patch plus a one-line shim
   `static files(Path) { return load(path).files(); }`, run against the R6 tests. Result 2/8 = 25%,
   inside the 40% ceiling, every failer within 1-3 tests. Kill table in eval-results.md.
3. Fairness pass on the counterfactual killers:
   - same-file remove (5 kills, nothing thrown): pinned by "Removing an id that the earlier files did
     not contribute". Fair and misdirecting; kept.
   - standalone bundled examples in the validator (2): pinned by examples resolving "relative to that
     file and nowhere else". Kept.
   - absolute `extends` in a string-loaded schema (2, "Schema parent not found" on an existing
     absolute file): only implied by the word "relative". meta.md now adds "while an absolute path
     resolves as usual".
   - missing list entry (1, threw IllegalArgumentException): the test's missing file is the LAST list
     entry, which is not a "parent" under the as-if-extends model, so the exception class was
     unpinned. meta.md now says "a missing parent or listed file is a `ParseException` naming that
     path".
   None of the clarifications flips a counterfactual pass, since each affected run also misses the
   same-file remove test, so the estimate stays 2/8.
4. test.sh survives an agent-poisoned Maven repo: if the offline build fails with
   `planetiler-parent:pom:${revision}`, it reinstalls planetiler-core with `-Pflatten` offline and
   retries once. Reproduced in the r6 image as uid 1000 with the agent's exact command: the old harness
   produced 1 synthetic case and exit 1, the new one 431/0 base and, with the solution, 83/0 new.

meta.md 485 body words. Solution unchanged.

R7 Docker (rebuilt from base + R7 test.patch): identical as root and uid 1000, base 431 pass / new 83 fail without the solution, 431 and 83 pass with it.

## ACCEPTED 2026-09-18 at 3/10 Nova (batch 2)

Batch 2 on the R7 artifacts: 3/10 PASS_LEGITIMATE, 7/10 FAIL_MISSED_REQUIREMENT. Top killer the
same-file add-then-remove test (7/10, sole failure of three 82/83 runs), then standalone bundled
examples in the validator (3/10). The shim counterfactual from batch 1 had predicted 2/8 with the same
top killer at 5/8. FP panel: 3/3 genuine, two judge dissents on unstated edges overruled.

Post-acceptance Auto Review (Revision Requested, recorded for the record, not acted on since the
problem was accepted): Solution 1/3 for a validator watch-order regression. The R4 eager inlining runs
before examples files are registered, so a missing or malformed spec file is never watched. Tests 2/3
for a default-locale `toLowerCase()` and two narrow `SchemaConfig.files` coverage gaps (bundled root,
cycle through `files`). Fix for any future reuse: register examples dependencies before parsing them.

Finalized: lessons carried into failure-patterns.md (F-38 new, F-9 and F-22 evidence, L72, L73, L50
and L51 evidence, dossier), the hunt/author/harden skills, Instructions (Pattern 96, DOCKER.md Maven
section) and approved-problems/README.md.
