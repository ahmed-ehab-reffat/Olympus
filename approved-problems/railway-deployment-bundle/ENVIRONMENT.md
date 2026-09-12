# Railway deployment-bundle preflight

Status: passed on 2026-07-26 for
`4d49d9845a27a0947ab903b01789eb9f854414d8`. This record establishes
eligibility and offline feasibility. The original preview was later rejected;
the final persisted-plan redesign subsequently passed its disposable scope and
attempted false-positive prototypes and repeated the complete offline lane as
recorded below.

## Eligibility and revision pin

| Check | Evidence | Result |
|---|---|---|
| Public/current repository | [`railwayapp/cli`](https://github.com/railwayapp/cli), default branch `master`; GitHub reported 576 stars and a 2026-07-25 push | pass |
| Full green revision | `4d49d9845a27a0947ab903b01789eb9f854414d8`, committed 2026-07-24 03:22:33 UTC, release 5.28.1 | pass |
| Exact-revision CI | [CI run 30064068467](https://github.com/railwayapp/cli/actions/runs/30064068467): check, lint, and Ubuntu/macOS/Windows test jobs succeeded; cargo-audit and release-asset jobs also succeeded | pass |
| License | pinned `LICENSE` is MIT, copyright Railway Corp. | pass |
| Primary language | GitHub language bytes: Rust 2,692,099; Shell 41,745; Nix 4,058; JavaScript 2,465; Dockerfile 316 | pass |
| Locked dependencies | `Cargo.lock` is tracked; neither it nor `Cargo.toml` contains a Git dependency | pass |
| Revision still resolves | `git ls-remote ... refs/heads/master` returned the full pinned SHA at final preflight | pass |

The exact checkout was clean before every baseline/probe. Its packed Git
objects occupied 4.00 MiB and the full working checkout occupied 9.7 MiB.

## Runtime and dependency inventory

The CLI is one Rust binary. The default feature set was used; the manifest has
no project-defined Cargo feature matrix. Packaging uses these locked crates:

- `ignore 0.4.23` for directory walking and Git-style ignore matching;
- `tar 0.4.46` for archive headers and filesystem reads;
- `gzp 0.11.3`, `synchronized-writer 1.1.11`, and `num_cpus 1.16.0` for
  multithreaded gzip output.

`flate2`, `zip`, and `sha2` are present for other CLI features, not the current
deployment archive. The focused seam does not call an external executable or
service. The complete test binary uses temporary files and in-process mocks;
even the test named `public_client_can_query_templates_without_auth_headers`
passed with container networking disabled.

No package was installed into the official image. The relevant Bookworm image
contents included GCC 12.2, glibc development files 2.36, pkg-config 1.8.1,
OpenSSL development files 3.0.16, Git 2.39.5, and CA certificates. The focused
test did not invoke Git. Tests and test data are inline in the repository's
tracked Rust modules; there is no separate downloaded fixture or snapshot
corpus. They are redistributable with the MIT repository.

## Official-image lane

The manifest declares `rust-version = "1.85.0"`. The first official image,
`rust:1.85.0-bookworm` at
`sha256:0ff31c9ffa641a62e48d543fb00b4960955ea375f40776f40f585b89e654cc5e`,
was therefore tried first. Dependency warming took 57.57 seconds, but the
offline locked build refused the selected `darling`, `darling_core`, and
`darling_macro` 0.23 packages because they require Rust 1.88. This is a pinned
upstream MSRV inconsistency, not a network or dependency-availability failure.

The oldest compatible official image used for the completed lane was:

| Field | Value |
|---|---|
| Image | `rust:1.88.0-bookworm` |
| Repo digest / image ID | `sha256:af306cfa71d987911a781c37b59d7d67d934f49684058f96cf72079c3626bfe0` |
| Platform | Linux arm64 |
| Image size | 513,360,656 bytes |
| Rust | `rustc 1.88.0 (6b00bc388 2025-06-23)` |
| Cargo | `cargo 1.88.0 (873a06493 2025-05-10)` |

Dependency warming was the only network-enabled Cargo step:

```bash
docker volume create olympus-railway-cargo-4d49d984
docker volume create olympus-railway-target-4d49d984
docker run --rm \
  -e CARGO_HOME=/cargo-cache \
  -v olympus-railway-cargo-4d49d984:/cargo-cache \
  -v "$PWD/work/railway-deployment-bundle/upstream:/src:ro" \
  -w /src rust:1.85.0-bookworm cargo fetch --locked
```

All completed checks used the warmed cache read-only and disabled networking:

```bash
docker run --rm --network none \
  -e CARGO_HOME=/cargo-cache -e CARGO_NET_OFFLINE=true \
  -v olympus-railway-cargo-4d49d984:/cargo-cache:ro \
  -v olympus-railway-target-4d49d984:/src/target \
  -v "$PWD/work/railway-deployment-bundle/upstream:/src:ro" \
  -w /src rust:1.88.0-bookworm cargo build --locked

docker run --rm --network none \
  -e CARGO_HOME=/cargo-cache -e CARGO_NET_OFFLINE=true \
  -v olympus-railway-cargo-4d49d984:/cargo-cache:ro \
  -v olympus-railway-target-4d49d984:/src/target \
  -v "$PWD/work/railway-deployment-bundle/upstream:/src:ro" \
  -w /src rust:1.88.0-bookworm cargo test --locked
```

| Check | Result | Wall time |
|---|---|---:|
| Offline locked development build | pass | 74.66 s |
| Complete offline test baseline | 474 passed, 0 failed, 0 ignored | 54.64 s |
| Exact local deployment-seam probe | 1 passed, 474 filtered; network disabled | 10.47 s |

The focused probe built the same archive twice from a temporary Git root,
decoded both archives, and checked nested-root, `.gitignore`,
`.railwayignore`, and unconditional `node_modules` exclusion behavior. It used
only pinned production helpers and repository dependencies.

After all builds and prototypes, the reusable Cargo cache occupied 855.6 MiB
and the shared target volume occupied 4.372 GiB. The larger figure includes
incremental artifacts from the disposable prototype; the first completed
baseline measurement was 3.785 GiB.

## Preflight verdict

Pass. The meaningful local deployment path is deterministic enough to exercise
offline, the broad test baseline is entirely offline-capable, and no
credential, Railway API, external service, mutable dependency, or foreign
fixture blocks problem work. The Rust 1.85 declaration must not be used for a
grader image without changing the lock; the exact pinned lock requires Rust
1.88.

## Persisted-plan prototype recheck

The redesigned disposable patch was tested in a fresh pair of Docker volumes.
`cargo fetch --locked` was the only network-enabled Cargo step. The final
complete run mounted that cache read-only and used:

```bash
docker run --rm --network none \
  -e CARGO_HOME=/cargo-cache -e CARGO_NET_OFFLINE=true \
  -v olympus-railway-redesign-cargo-4d49d984:/cargo-cache:ro \
  -v olympus-railway-redesign-target-4d49d984:/src/target \
  -v /private/tmp/railway-verified-plan-prototype-4d49d984:/src:ro \
  -w /src rust:1.88.0-bookworm cargo test --locked
```

Result: 477 passed, 0 failed, 0 ignored. The final warm compile took 9.17
seconds and the test process took 0.07 seconds. The three added tests cover
deterministic strict plans, plan-file self-exclusion, exact archive
path/digest consumption, equal-size content drift, selection/type/option
drift, and malformed or unsupported plans.

A host binary probe separately established that `--write-plan` succeeds
without authentication and that a same-size content mutation under
`--from-plan`, with token environment variables removed, returns the local
content-difference error and exit 1 before the existing authentication and
upload path.

## Final canonical-selector and audit recheck

The final disposable patch
`verified-plan-prototype-v3.patch` is based on the same full Railway SHA and
uses the same dependency cache and official `rust:1.88.0-bookworm` image. The
only network-enabled Cargo action remained `cargo fetch --locked`. The final
complete run mounted the source and Cargo cache read-only, set
`CARGO_NET_OFFLINE=true`, disabled Docker networking, and ran:

```bash
docker run --rm --network none \
  -e CARGO_HOME=/cargo-cache -e CARGO_NET_OFFLINE=true \
  -v olympus-railway-v2-cargo-4d49d984:/cargo-cache:ro \
  -v olympus-railway-v2-target-4d49d984:/src/target \
  -v /private/tmp/railway-verified-plan-v2-4d49d984:/src:ro \
  -w /src rust:1.88.0-bookworm cargo test --locked
```

Result: 483 passed, 0 failed, 0 ignored. The final incremental compile took
8.07 seconds and the test process took 5.73 seconds. The Linux total includes
non-UTF-8 path rejection and a 64 MiB atomic-replacement probe that observes
open descriptors through `/proc/self/fd`; the host macOS total is 481/481
because those two probes are Linux-only.

Two self-checking Node process verifiers were also run:

- `verify_no_requests.mjs` points every proxy variable at a counting TCP
  boundary, writes and rewrites the plan byte-identically, applies an invalid
  same-size edit, and observes zero connections;
- `verify_deferred_refresh.mjs` mounts an isolated expired-OAuth configuration
  into a container, applies a valid plan, and observes the deferred refresh
  followed by the normal GraphQL request.

Both passed against the pre-version-5 reference. The second observed two
connections, and an omitted deferred-refresh mutant observed one. That
prototype distinction is retained as history only; the canonical version 5
grader accepts any positive post-verification connection count. Host
format/diff checks, the changed-file Clippy review, exact patch comparison, and
reverse application check also pass.

No extra runtime, native package, live Railway service, or mutable dependency
was introduced. Docker is used only by the external sequencing verifier and
official-image lane. A Windows target was not installed locally; upstream's
green exact-revision Windows CI establishes the base environment, while final
patch validation on that lane remains a pre-submission requirement.

## Canonical grader-image validation

The final Dockerfile uses the Olympus Rust base, installs Rust 1.88.0 and
locked cargo-nextest 0.9.100 before copying the source, fetches the pinned
Railway lock, and builds all default targets. The exact Dockerfile SHA-256 is
`6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`.
The completed Linux arm64 image ID is
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.

Both final test invocations used `--network none`:

| Mode | Result | JUnit |
|---|---:|---:|
| `./test.sh base` | 474 passed, 0 failed | 474 tests, 0 failures, 0 errors |
| `./test.sh new` | 21 passed, 0 failed | 21 tests, 0 failures, 0 errors |

The grader run includes the Linux non-UTF-8 and atomic-replacement entities;
the latter completed in 6.231 seconds. The macOS canonical lane reports
474/474 base and 19/19 grader entities. The test patch alone reports 474/474
base and deliberately exits 101 in `new` at the missing deployment-plan
controller. Its fallback JUnit contains one skipped synthetic `new.run` and no
failure or error, so the wrapper does not treat runner metadata as a
behavioral regression.

The version 5 valid-apply process probe accepts any positive connection count
after local verification; it no longer assumes distinct OAuth-refresh and
GraphQL requests. Write and invalid apply still use expired isolated OAuth
state and require zero connections. Both final image runs used
`--network none` and emitted valid 483/0 and 21/0 JUnit reports.

The schema-boundary revision keeps the same build environment and adds one
cross-platform grader entity. Cargo-nextest 0.9.100 lists all 21 Linux entities
for `-E 'test(deployment_plan_)'`. The previously used
`test(~deployment_plan_)` form was also a valid contains expression, but the
equivalent default spelling avoids reviewer ambiguity.

The final wrapper/fixture revision retained the same build inputs and test
counts. Offline write now uses no remote selector; invalid apply uses paired
project and environment selectors. Exact network-disabled image results remain
483/483 base and 21/21 new, with valid JUnit. The paired invalid-apply fixture
also rejects the eager-refresh mutant after observing two proxy connections.

The version 8 reference-accounting revision retains the same image and
production behavior but removes nine reference-only self-tests. Its clean
wrapper census is historical after the agent-run merge failure described
below.

## Version 9 agent-run and environment recheck

The official Nova runs exposed a wrapper merge defect rather than a missing
dependency or incompatible toolchain. Both participant patches and the grader
edited `src/controllers/mod.rs`; fallback patch injection deleted the
participant export before compilation. Version 9 moves grader injection to
`src/consts.rs`, which neither participant patch edits. Direct application of
each participant patch followed by the revised `test.patch` succeeds in the
same Linux arm64 image.

Base mode now excludes task-owned self-test names containing `deploy_plan`,
`deployment_plan`, or `up_plan`. Cargo-nextest 0.9.100 finds no such entity in
the 474-test pinned baseline. It excludes 11 solver-authored entities in Run 1
and 13 in Run 2 while continuing to run all 474 upstream regressions.

The exact network-disabled Linux results in image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`
are:

| Tree | `base` | `new` |
|---|---:|---:|
| test patch only | 474 passed | exits 101; fallback JUnit has one skipped synthetic testcase |
| reference | 474 passed | 23 passed |
| supplied Run 1 patch | 474 passed, 11 task tests excluded | 22 passed, 1 snapshot-formation failure |
| supplied Run 2 patch | 474 passed, 13 task tests excluded | 22 passed, 1 root-identity failure |

The host macOS reference lane passes 474 base and 20 grader entities. The
additional Linux entities cover non-UTF-8 identity, coherent in-read planning
snapshots, and verified bytes after atomic pathname replacement. The new
snapshot mutation uses the already-established `/proc/self/fd` synchronization
method, proves that its same-inode mutation occurred, and completed in under
one second in the final reference run. The older 64 MiB archive-replacement
probe remains the slowest entity.

No dependency, native library, external executable, live Railway service, or
Dockerfile change was required. The exact version-9 artifact identities are
recorded in `LEVELS.md` and `FALSE_POSITIVE_AUDIT.md`.

## Version 10 environment and verifier recheck

The `agent-runs2` records contain no meaningful environment blocker. Both
patches compile in the existing image and pass version 9 completely. Missing
`rg`, broad `find` warnings, and wrapper conflict recovery were locally
recoverable and did not prevent any test.

Version 10 retains the same pinned base, lockfile, dependencies, Dockerfile,
Rust 1.88 toolchain, cargo-nextest 0.9.100, and Linux arm64 image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.
No fetch, package installation, native library, external service, or live
Railway credential was introduced.

The first network-disabled container invocation mounted `/src` read-only. Its
base run passed all 474 tests, but nextest could not publish JUnit under
`/src/target` and exited 110 before the chained grader command. The
authoritative rerun made only the result destination writable:

| Tree | `base` | `new` |
|---|---:|---:|
| test patch only | 474 passed | exits 101; one skipped fallback testcase |
| reference | 474 passed | 24 passed |
| `agent-runs2` Run 1 | 474 passed, 11 task tests excluded | 23 passed, 1 snapshot failure |
| `agent-runs2` Run 2 | 474 passed, 7 task tests excluded | 23 passed, 1 snapshot failure |
| earlier near-pass | 474 passed, 13 task tests excluded | 21 passed, 3 failures across snapshot/root families |

The macOS reference passes 474 base and 21 grader entities. Linux adds the
non-UTF-8 identity, same-size in-read modification, and atomic pathname
replacement probes for a total of 24. The final snapshot race completed in
1.210 seconds in the authoritative reference run; the atomic-replacement probe
completed in 6.319 seconds.

Both canonical patch orders and reverse checks pass. The patches reproduce the
formatted disposable source exactly; `cargo fmt --check` and applied-tree
`git diff --check` pass. A whole-repository Rust 1.97 Clippy run is not a
useful gate because it reports 35 warnings in untouched upstream files, while
the pinned 1.88 host toolchain lacks its optional Clippy component.

## Version 11 prompt-only recheck

Version 11 removes one redundant explanatory sentence from `meta.md`. The
base, tests, reference, explanation, Dockerfile, lockfile, toolchain, and image
are byte-identical to version 10. No dependency or verifier behavior changed.
Patch application, reverse application, formatting, whitespace, and the exact
prompt-to-oracle map were rechecked under prompt hash
`55df6607e9a306939ec5a6b51b7da24aa8c87bcc32d82b4f6531d9460665d577`.

## Version 12 reference and storage recheck

Version 12 changes the prompt, reference, and explanation but adds no
dependency, native tool, or image requirement. In the exact network-disabled
Linux image:

- `base`: 474 passed, 0 skipped;
- `new`: 24 passed, with JUnit `failures="0"`, `errors="0"`, and no skipped
  testcase;
- the repaired snapshot entity passed 20 consecutive repetitions.

macOS `new` passes 21/21. Patch application, reversal, formatting, and
applied-tree whitespace checks pass.

A later redundant relink filled a disposable 8.9 GiB mounted target cache and
left Docker Desktop's backend stuck. The canonical JUnit had already
completed. Removing that task-owned cache freed host storage; force-restarting
only the Docker backend restored image access. The event is verifier
infrastructure, not a failed test.

## Version 14 exact environment recheck

Version 14 adds no dependency, native tool, service, fixture, or image
requirement. It reuses Linux arm64 image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`
with source mounted read-only, a writable task-owned target volume,
`CARGO_NET_OFFLINE=true`, and Docker networking disabled.

| Mode | Result | JUnit |
|---|---:|---:|
| `./test.sh base` | 474 passed, 0 skipped | 474 tests, 0 failures, 0 errors |
| `./test.sh new` | 28 passed | 28 tests, 0 failures, 0 errors, no skipped element |

The macOS lane reports 23/23 new. The four Linux watcher tests are serialized,
so their 64–128 MiB payloads do not overlap; all finish or report a clear
untriggered condition within a 30-second observation budget. The atomic
replacement entity passed the complete run plus five consecutive focused
repetitions.

Test-only `new` still exits 101 because the solution-owned controller is
absent. Its one skipped fallback now includes the complete XML-escaped
compiler diagnostic. A forced missing-toolchain run likewise preserved the
actual cargo error, confirming that linker, compiler, or runner failures are
not reduced to an unexplained numeric code.

Both patch orders, independent application, reversal, formatting, shell
syntax, and applied-tree whitespace checks pass. The Dockerfile and image are
unchanged from version 13.

## Version 15 exact environment recheck

Version 15 changes no dependency, native tool, service, fixture, wrapper, or
image requirement. The same network-disabled Linux image produces 474/474
base and 28/28 new with zero failures, errors, or skips; macOS new produces
23/23. Test-only `new` still exits 101 and its single skipped fallback retains
the unresolved-module compiler diagnostic.

Both patch orders, independent application, reverse checks, host formatting,
shell syntax, and applied-tree whitespace checks pass. Rust 1.88 is used for
compilation and tests. Its macOS installation has no rustfmt component, so the
installed host formatter performs the separate formatting check.

## Version 16 exact environment recheck

Version 16 changes no dependency, tool, service, fixture, wrapper, image, or
resource requirement. The same network-disabled Linux image produces 474/474
base and 28/28 new with zero failures, errors, or skips; macOS new produces
23/23. Test-only `new` exits 101 with its diagnostic-preserving skipped
placeholder.

Both patch orders, independent application, reverse checks, host formatting,
shell syntax, and applied-tree whitespace checks pass. Only participant-facing
text and one CLI assertion body differ from version 15.

## Version 17 exact environment recheck

Version 17 changes only `meta.md`; every executable and environment artifact is
byte-identical to version 16. The same network-disabled Linux image produces
474/474 base and 28/28 new with zero failures, errors, or skips; macOS new
produces 23/23. Patch-order, test-only, formatting, shell, and applied-tree
checks retain their exact version-16 outcomes.

## Version 18 exact environment recheck

Version 18 changes no dependency, native tool, service, wrapper, image, or
resource requirement. The same Linux arm64 image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`
with networking disabled produces 474/474 base and 28/28 new. The new JUnit
reports 28 tests, zero failures, zero errors, and no skipped testcase. macOS
new produces 23/23.

The first container launch attempted a writable target volume nested below a
read-only source bind. Docker rejected the mount before starting the process,
so no test ran. The authoritative invocations mounted only the disposable
clean worktree writable, retained the isolated task-owned target volume, and
kept `--network none`.

Both patch orders, reverse checks, host formatting, shell syntax, and
applied-tree whitespace checks pass. Test-only macOS new exits 101 and emits a
single classified fallback whose `system-out` contains the unresolved
`controllers::deploy_plan` compiler diagnostic.

## Version 19 exact environment recheck

Version 19 changes only participant-facing text. Dependencies, source,
reference, tests, wrapper, Dockerfile, Rust 1.88 toolchain, cargo-nextest
0.9.100, and Linux arm64 image are byte-identical to version 18.

Network-disabled Linux produces 474/474 base and 28/28 new; macOS new produces
23/23. Both patch orders, reverse checks, formatting, shell syntax, and
applied-tree whitespace checks pass.

## Version 20 exact environment recheck

Version 20 changes only participant-facing text. Dependencies, source,
reference, tests, wrapper, Dockerfile, Rust 1.88 toolchain, cargo-nextest
0.9.100, and Linux arm64 image are byte-identical to version 19.

Network-disabled Linux produces 474/474 base and 28/28 new; macOS new produces
23/23. Both patch orders, reverse checks, formatting, shell syntax, and
applied-tree whitespace checks pass.

## Version 21 exact environment recheck

Version 21 changes no dependency, native tool, service, wrapper, image, or
resource requirement. The test count remains 28 on Linux and 23 on macOS
because two existing entities were strengthened rather than adding entities.

The same network-disabled Linux arm64 image produces 474/474 base and 28/28
new; macOS new produces 23/23. Test-only Linux new exits 101, and the fallback
JUnit retains the unresolved `controllers::deploy_plan` diagnostic. Both patch
orders, reverse checks, formatting, shell syntax, and applied-tree whitespace
checks pass.

## Version 22 exact environment recheck

Version 22 changes one assertion and its test name. It adds no dependency,
native tool, service, wrapper, image, fixture, or resource requirement. The
test count remains 28 on Linux and 23 on macOS.

A fresh isolated target volume under the same network-disabled Linux arm64
image produced 474/474 base and 28/28 new. macOS produced 23/23. A separate
test-only Linux target exited 101 and the fallback JUnit retained the
unresolved `controllers::deploy_plan` compiler diagnostic. Both patch orders,
reverse checks, formatting, shell syntax, and applied-tree whitespace checks
pass.

The first Linux invocation used a login shell, which reset the image's Cargo
path and ran no test; the authoritative invocation used the image's normal
non-login environment. After the reference, focused mutant, and legitimate
trajectory replay completed, an additional redundant `Nova_Nova_2` replay
encountered `Input/output error` while writing Cargo's query cache to its
task-owned Docker volume. That replay is excluded. The already-complete
reference and audit results use separate fresh volumes and remain valid.

The macOS compilation target created for the cross-platform lane occupied
approximately 2.8 GiB and was removed from its disposable worktree after the
host reached low free space. No source, submission artifact, result XML, or
user-owned persistent cache was removed.

## Version 23 exact environment recheck

Version 23 adds no production dependency, service, port, network requirement,
or Dockerfile package. On Linux, the grader compiles a small test-only shared
object with the image's existing C compiler and loads it only into child
processes created by four snapshot entities. macOS excludes that harness with
`cfg(target_os = "linux")`. Fixtures are 4 KiB; the previous 64–128 MiB race
payloads and descriptor-polling loops are gone. The 30-second deadline is a
deadlock guard, not mutation coordination.

The same arm64 image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`
produced 474/474 network-disabled Linux base and 28/28 Linux new. The new JUnit
contains 28 testcases with zero failures, errors, or skipped new testcases.
macOS produced 23/23 new. Test-only Linux exited 101, and an output-path run
wrote fallback JUnit containing the unresolved `controllers::deploy_plan`
compiler diagnostic.

Both patch orders, reverse checks, applied-tree whitespace checks, and
default-toolchain formatting pass. A `cargo +1.88.0 fmt` attempt on macOS was
inapplicable because that minimal toolchain lacks `rustfmt`; the installed
default toolchain completed the authoritative formatting check.

Docker Desktop was restarted after an earlier storage fault. At the user's
direction, unused Docker images were pruned while all containers, volumes, and
78.08 GiB of BuildKit cache were retained. The current wrapper image remained
present. The existing Dockerfile had become a macOS dataless placeholder; its
exact recorded 455-byte contents were restored, reproducing the unchanged
historical hash
`6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`.

## Version 24 exact environment recheck

Version 24 changes only a regular-file fixture inside an existing controller
test. It adds no dependency, compiler, native library, service, network access,
resource-heavy fixture, wrapper behavior, or platform condition. The test
census remains 28 on Linux and 23 on macOS.

The unchanged arm64 image produced 474/474 network-disabled Linux base and
28/28 Linux new. macOS produced 23/23 new. Both new JUnit files contain zero
failures, errors, or skipped new testcases. Test-only Linux exited 101 and its
fallback JUnit retained the unresolved `controllers::deploy_plan` diagnostic.

Both patch orders, reverse checks, applied-tree whitespace checks, and
formatting pass. The macOS build target was disposable and removed after the
lane completed; Docker BuildKit cache was not pruned.

## Version 30 exact environment recheck

Version 30 removes the Linux `LD_PRELOAD`/libc `read(2)` synchronization
harness and the four tests coupled to it. The focused suite no longer compiles
a C interposer, polls `/proc`, launches child snapshot workers, or allocates
large race fixtures. The remaining CLI integration setup uses `python3` and
`openssl`, both of which were exercised successfully in the exact test
environment.

The exact reference produced 474/474 base tests and 23/23 focused tests on
macOS. A network-disabled Linux arm64 run, using the unchanged reference image
and an exact bind of the revised grader sources, produced 24/24 focused tests.
The Linux base lane is unchanged from the preceding exact 474/474 run.

The `cargo test` fallback was exercised with nextest genuinely unavailable. It
reported all 23 focused macOS cases with zero failures, errors, or skips.
A test-only run exited 101 and produced one diagnostic JUnit failure retaining
the unresolved `controllers::deploy_plan` compiler error, rather than
misreporting the runner failure as a skipped test.

Both patch application orders, reverse checks, shell syntax, and canonical
test-patch regeneration pass. Temporary build targets that exhausted host disk
space were cleaned only with `cargo clean` inside their explicit disposable
`/tmp/railway-v30.84zGsL` worktrees. No project source, Docker cache, image,
container, or volume was removed.

## Version 31 exact environment recheck

Version 31 changes only reference Rust code and its explanation. It introduces
no dependency, native tool, service, port, fixture, test, wrapper behavior, or
resource requirement. The Unix implementation uses the standard library's
device and inode metadata; the existing non-Unix branch retains a portable
metadata fallback.

The exact macOS reference produces 474/474 baseline and 23/23 focused tests.
With nextest hidden, the Cargo fallback produces 23 JUnit cases with zero
failures, errors, or skips. Test-only mode exits 101 and records one diagnostic
failure with the unresolved controller import and zero skips. The temporary
same-size replacement/stable-link identity probe passes. Removing only the
identity check still produces 23/23, while the discard-and-rebuild mutant
produces 474/474 baseline and 22/23 focused.

Both patch orders apply and reverse cleanly, the production diff regenerated
from the tested tree exactly matches the canonical solution hash, formatting
and whitespace checks pass, and no temporary probe is included in the
artifacts. Docker Desktop did not answer its local socket, so no new local
Linux container result is claimed. The byte-identical version-30 grader had
already passed 24/24 in the network-disabled Linux image, and the external
version-31 verifier reports all 24 visible Linux cases passing before its
synthesized reference analysis.

After verification, `cargo clean` removed 25.0 GiB of rebuildable output only
from the explicit disposable
`/tmp/railway-v30.84zGsL/{order-test-first,base}` worktrees. Free host space
rose from approximately 13 GiB to 26 GiB. Docker images, BuildKit cache,
containers, volumes, project sources, and submission artifacts were not
removed.

## Version 33 exact environment recheck

Docker Desktop was restarted after its local socket stopped responding. No
image, BuildKit cache, container, volume, project source, or submission
artifact was deleted. Verification reused the existing arm64 reference image
`sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f`
and mounted fresh patch-applied source trees.

With container networking disabled, the exact reference produced 474/474
baseline and 24/24 focused nextest results. Hiding nextest exercised the cargo
fallback at 24/24. The test-only tree exited 101 and retained its unresolved
controller diagnostic in one JUnit failure with zero skips. The local TLS
upload-capture fixture completed successfully in both the reference and the
discard-and-rebuild mutant; the latter failed only its expected archived-byte
assertion after passing all 474 regressions.

The version-33 prompt clarification introduces no dependency, native tool,
service, port, resource, or platform assumption. `test.patch`, the reference,
Dockerfile, and explanation remain byte-identical to version 32.
