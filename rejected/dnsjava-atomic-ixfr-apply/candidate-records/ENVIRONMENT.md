# Historical candidate environment gate - dnsjava atomic IXFR application

Verdict: **Phase A pass** at
`06a0599933114f36efe59667cd80ee0246a1a882`.

- Image: `maven:3.9.11-eclipse-temurin-17`, immutable ID
  `sha256:e4a7ace3dc0d645ed97f8d9ad0b0d3f0b14fa8d150138f27f116d7105a639b82`
- Work/dependency volume: `olympus_dnsjava_work_0811`
- Exact runtime: `--network none --user 12345:12345`
- Maven entrypoint: invoked directly to avoid the image wrapper's root-home
  initialization
- Maven repository: `/work/.m2/repository`, explicitly selected for both warm
  and offline runs
- Loopback setup: hostname `dnsjava-test` mapped to `127.0.0.1`; this permits
  tests that bind to the local hostname without enabling a network
- Command: `mvn -B -o -Dmaven.repo.local=/work/.m2/repository test`
- Result: **1,739 tests run, 0 failures, 0 errors, 29 skips**.

Three preceding runs were quarantined and not counted: a cache mounted only as
`MAVEN_CONFIG` left the actual local repository under the container user's
home; the corrected cache then exposed the image entrypoint's root-home write;
and a networkless default Docker hostname was not locally resolvable, causing
four loopback tests to fail before behavioral assertions. The final command
bypassed the wrapper, used the explicit cache, and supplied a loopback-only
hostname. It rebuilt from a clean `target` directory and passed offline as the
arbitrary UID.

At this candidate-stage checkpoint no prompt, test patch, reference patch, or
evaluator existed, so Phase B was not applicable. The promoted problem package
contains the superseding exact-version Phase A and Phase B record.

## Revalidation - 2026-08-11

The default pin, image ID, dependency/work volume, offline network mode,
arbitrary UID, Maven repository, and loopback-only hostname were rechecked
before disposable implementation trials. After removing only the generated
`/work/target` directory, the exact recorded command passed again with **1,739
tests, 0 failures, 0 errors, and 29 skips**. A second warm invocation reproduced
the same totals and `BUILD SUCCESS`.

One preliminary command added Maven's `clean` lifecycle. It failed before test
discovery because `maven-clean-plugin:3.5.0` was not cached. That run is
quarantined as an operator-command deviation: `clean` was not part of the
qualified offline command, and the exact lane subsequently passed from an
explicitly removed target tree.

## Disposable trial executions - 2026-08-11

Independent temporary clones were bind-mounted at `/work` while the qualified
dependency volume was mounted read/write at `/cache`; Maven was explicitly
pointed at `/cache/.m2/repository`. The image ID, `--network none`, UID/GID
12345, and loopback-only hostname remained unchanged.

- Staged-list implementation: 5/5 focused tests and the complete 1,744-test
  trial tree passed, with 29 skips.
- Staged-map implementation: 3/3 focused tests and the complete 1,742-test
  trial tree passed, with 29 skips.
- Per-record in-place mutant: its atomicity test reached JUnit and failed in
  four Surefire attempts on the intended partial-publication assertion. This
  is discriminator evidence, not an environment or solver failure.

The differing totals include disposable tests; each trial ran the same 1,739
pre-existing tests. No trial patch was promoted into the candidate workspace.
Because no evaluator composition or submission artifacts existed at this
checkpoint, these runs do not constitute Phase B or solver calibration. See
`problems/dnsjava-atomic-ixfr-apply/ENVIRONMENT.md` for the promoted exact gate.
