# Exact-version environment gate

Status: `Phase A and Phase B pass; calibration 0/10`.

Repository: `dnsjava/dnsjava` at
`06a0599933114f36efe59667cd80ee0246a1a882`.

Artifact binding: `meta.md` `1f5811dd46c`, `test.patch` `6056f8559e83`,
`solution.patch` `b48dd4dba68b`, and Dockerfile `df08c4461aa6`.

- Base image: `maven:3.9.11-eclipse-temurin-17`, resolved digest
  `sha256:e4a7ace3dc0d645ed97f8d9ad0b0d3f0b14fa8d150138f27f116d7105a639b82`.
- Cold evaluator image: `olympus-dnsjava-ixfr:final-v2`, image ID
  `sha256:38935e06d2754e36fd4da593e5710fa1121c782b829b3c1d9d66155a55e638f4`.
- Runtime: networking disabled, UID/GID `10001:10001`, loopback-only hostname,
  Java 17, Python 3.12.3, cached Maven repository at
  `/opt/maven-repository`.

## Phase A - untouched repository

The final image was rebuilt with `--pull --no-cache` from the untouched frozen
checkout. Its build ran the complete repository suite, then removed `/app/target`
so an arbitrary runtime identity owns generated output. The offline runtime
proved `/app` writable and the dependency cache readable, then ran real JUnit:
**1,739 tests, 0 failures, 0 errors, 29 skips**.

The Maven base image's entrypoint is cleared because its wrapper attempts
root-home initialization for arbitrary UIDs. Python is installed only for
Surefire XML aggregation. Maven runtime resolution is forced offline.

## Phase B - exact evaluator composition

Five fresh trees were created from the frozen pin. For implementation lanes,
the implementation patch was applied and staged first; the exact `test.patch`
was then applied with three-way evaluator semantics. Every tree passed
`git diff --check`, had no unmerged path, and ran offline as UID 10001.

| Tree | Existing lane | Feature lane |
|---|---:|---:|
| pristine + tests | 121/121 pass | 17 named failures, 0 errors |
| reference + tests | 121/121 pass | 17/17 pass |
| staged-list trial A + tests | 121/121 pass | 17/17 pass |
| staged-map trial B + tests | 121/121 pass | 17/17 pass |
| direct in-place trial C + tests | 121/121 pass | 6 failures, 1 error |

The baseline, reference, and all trial trees exposed the exact same 121 base
and 17 feature testcase identities. Baseline failure attribution is therefore
behavioral: all seventeen named tests run, and no compiler, suite hook, or
harness-startup node substitutes for a feature result. The final reference plus
tests also passed Spotless and the complete combined suite: **1,756 tests, 0
failures, 0 errors, 29 skips**.

Trial patch hashes were `310ed007286d` (A), `93b7257ea1c9` (B), and
`0ad764ed1835` (C). They are verification evidence, not solver calibration.

## Quarantined environment incidents

- An early image retained root-owned `target` output and failed arbitrary-UID
  copy-up. Removing only generated `/app/target` after build fixed the image.
- The Maven image wrapper tried to initialize a root home. Clearing the image
  entrypoint fixed arbitrary-UID startup.
- During a superseded 17-test draft run, Docker's content store returned an
  input/output error for the prior image manifest. The batch stopped
  immediately and no result was counted. `docker desktop restart` restored the
  VM and overlay store; the final image was then rebuilt cold and every gate was
  restarted from zero.
- A repository helper's read-only mount could not support Maven's generated
  tree. The final evaluator instead uses fresh writable composition trees while
  retaining the required implementation-then-test patch order.

## Verdict

`Pass` for the exact artifacts in `ARTIFACTS.sha256`. Any change to the prompt,
tests, reference, Dockerfile, dependency graph, repository pin, or injection
path invalidates this verdict and requires both phases from zero.
