# Implementation and environment findings

## Terminal: candidate abandoned after remote build-context timeout

The final platform image build exceeded its 40-minute limit. Its complete tail
stopped at:

```text
#2 [depot] launching amd64 machine
#3 [depot] connecting to amd64 machine
#4 [internal] fetching git attributes
```

No Dockerfile definition, base layer, `COPY`, or npm command had started. This
failure therefore cannot be repaired by another lockfile encoding or Docker
installation strategy. It is a build-context/platform boundary distinct from
the dependency problems below.

The repository was explicitly abandoned on 2026-07-23. Its upstream revision
has no committed npm lockfile and omits tools required by its own scripts.
Because evaluation builds the pristine repository before task patches are
injected, a task-side lock cannot solve that cleanly. Further Dockerfile
workarounds would repeat the failures already recorded here.

Selection rule adopted from this failure: a TypeScript or JavaScript repository
must contain a committed recognized lockfile, declare every offline build/test
tool, and pass a minimal pristine Docker build before task design begins. A
dependency-free repository may be considered only when that state is verified.

## Resolved: oversized Docker instruction broke the build-log reader

The pinned lock was previously mirrored in one Docker `RUN` heredoc. BuildKit
can render an entire instruction as one progress-output record, making that
record hundreds of kilobytes long. The platform's asynchronous subprocess
reader has a 64 KiB line limit, so it raised `Separator is not found, and chunk
exceed the limit` while capturing the build. This happened before the image or
agent could start; retrying the same image could not correct it.

The synchronized mirror is now split at lockfile line boundaries into separate
plain-text Docker instructions. The largest generated instruction is below
13 KiB, while concatenating their payloads still reproduces the canonical
`package-lock.json` byte-for-byte. The environment audit verifies order,
redirection, size, and exact reconstruction so later lock updates cannot
reintroduce the failure.

## Resolved: blocked trajectory had no local `tsx`

The blocked run completed its implementation, but the verifier invoked
`npx --no-install tsx`. Its image had `node_modules` without
`node_modules/.bin/tsx`, so npm attempted to resolve `tsx@4.23.1` and then
canceled because runtime network access is disabled. The failure occurred before
any grader spec ran.

The Dockerfile now installs exact `tsx@4.20.3` and `copyfiles@2.4.1` entries from
the canonical lock. `npm test`, the JUnit wrapper, and both TypeScript
post-build copy steps therefore use local binaries and require no runtime
download.

## Resolved: base-runtime cleanup behavior caused the 101 baseline failures

All 101 upstream failures were cleanup failures at six absent scratch paths.
On the Linux base runtime, forced recursive removal of a missing path
ending in `/` surfaced `ENOTDIR` instead of honoring `force`. No feature test had
run yet.

The test runner normalizes this narrow upstream cleanup operation in base mode.
The image now uses the required TypeScript base toolchain directly instead of
downloading a second Node runtime. The unpatched upstream suite passes 869/869
through the required task entry point.

## Resolved: incomplete and transient dependency setup

The source commit has no lockfile and its scripts refer to undeclared `tsx` and
`copyfiles` executables. Earlier Dockerfile revisions either generated a
transient lock while mutating `package.json`, embedded an invalid `COPY`
heredoc, or installed only enough packages for a subset of commands.

The task now contains a normal `package-lock.json` with the full repository
dependency graph. Because the platform's pristine build context cannot access
task-side companion files, the Dockerfile carries a synchronized plain JSON
mirror. There is no encoded or compressed payload and no replacement
`package.json`. `npm ci` runs only during image build and clears its cache.
Build, tests, lint, formatting, coverage, and documentation tools are all
present in the offline agent environment.

The image intentionally does not pretend that this graph came from the
lockfile-less upstream checkout. `ENVIRONMENT.md` records the exact two-package
delta, source and lock hashes, and the commands that synchronize and audit the
plain mirror. This keeps the offline image reproducible without hiding
dependency divergence in an encoded Docker payload.

## Resolved: discriminator concentration

The earlier suite concentrated on late content-processing failures. Several
successful agents could satisfy it while mishandling entry type changes,
single-stage temp setup, or temp storage nested inside output.

The focused suite now has 39 independently named specs. New cases cover:

- filesystem and `.3dtiles` target-finalizer failures;
- both file/directory collision directions;
- an absent custom temp base on success and failure;
- a custom temp base inside an existing output;
- invalid temp setup for a single-stage pipeline; and
- destination setup failure after target finalization.

All 39 fail against the clean implementation and pass with the reference patch.

## Resolved: over-specific success comparisons

Successful JSON output is compared structurally, matching the repository's own
comparison helper. Non-JSON entries remain byte-compared. Every legacy success
or refusal behavior is paired with a transactional failure or an additional
state guarantee so no focused spec passes on the clean implementation.

## Local Docker daemon limitation

Dockerfile syntax checks complete, and the exact locked graph was installed
outside Docker. The image definition has a valid required base, standard
bounded heredocs, no direct remote-file fetches, a reproducible npm lock, and a
source-aware dependency audit.

A full rebuild from a detached clean checkout was attempted after removing the
external Node download. BuildKit resolved the cached required base at
`sha256:a2ac69f318e782a6b20fd29ceefe27ef31cd4d6fddbcab18eac57aa8ba0c5c90`
and then stalled on the first offline `RUN` instruction. After replacing the
encoded lock with the canonical plain lock, a second clean-context build passed
`WORKDIR` and `COPY` and again stalled when BuildKit attempted the first `RUN`,
before the shell produced output. Independent `docker run` and `docker pull`
commands against the same base also hang before a container starts, while
unrelated existing containers remain running. This isolates the remaining local
rebuild blocker to Docker Desktop; the static build check, plain-lock
`npm ci --dry-run`, and source-aware environment audit all pass.
