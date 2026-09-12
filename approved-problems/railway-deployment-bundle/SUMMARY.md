# Railway verified deployment plans - accepted handoff

## State

Canonical version 33 was accepted on 2026-07-29. Its submission artifacts are
frozen, and its bulky historical trajectories have been moved to
`archive/railway-deployment-bundle/`. Compact run, design, error, and
verification records remain beside the canonical package.

Repository: `railwayapp/cli`

Production language: Rust

Task type: feature request

Pinned base: `4d49d9845a27a0947ab903b01789eb9f854414d8`

Recorded pre-calibration rating: 8/10

The rejected immediate preview was 81 strict effective production additions.
The canonical verified-plan implementation is 638 strict effective production
additions across six files, with no new dependency.

## Immutable accepted version-33 identities

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd` |
| `test.patch` | `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

The exact combined source passes 474/474 Linux baseline and 24/24 Linux
focused tests. Cargo fallback also passes 24/24, while test-only mode produces
the intended classified diagnostic failure with zero skips. Patch-order,
reversal, false-positive, harness-integrity, and implementation-fairness gates
are recorded in `DESIGN.md` and `FALSE_POSITIVE_AUDIT.md`.

Historical calibration results and their exact artifact versions remain in
`LEVELS.md`; the compact raw-batch index is `RUNS.md`.

## What changed in version 33

- Clarified that the `"."` selected-root entry participates in global path
  ordering and therefore need not be the first entry.
- Kept the version-32 grader, reference, explanation, and Dockerfile
  byte-identical.
- Repeated the exact reference, fallback, test-only, patch-integrity,
  false-positive, and fairness checks before the final batch and acceptance.

## What changed in version 31

- Added a conservative Unix device/inode identity check across the pre-open
  pathname, opened descriptor, and followed pathname after reading.
- Kept `meta.md` and `test.patch` byte-identical: safe alternative snapshot
  implementations remain valid.
- Confirmed the identity-free variant still passes 23/23, while the
  discard-and-rebuild shortcut remains isolated at 22/23 after all 474
  regressions pass.
- Verified same-size replacement and stable followed-link identities with a
  temporary reference-only probe.

## What changed in version 30

- Removed the C compiler/`LD_PRELOAD` harness and four tests whose mutation
  point required the candidate to call the libc `read` symbol.
- Removed the matching mid-read size/mode/modification drift obligation from
  the public description.
- Retained the public upload-body capture that proves uploaded bytes are the
  bytes locally verified before the source mutation.
- Corrected cargo-fallback JUnit so all discovered tests are represented with
  their actual results instead of synthesizing a failure after a successful
  run.
- Verified a `pread` implementation mode, a no-mid-read-stability variant, and
  exact Nova 3 as legitimate passes; the discard-and-rebuild mutant remains an
  isolated failure.

## Historical version-27 changes

- The prompt and synchronized metadata-mutation entity now require stability
  during the file-content read, not between kernel `open` and the first
  descriptor metadata sample.
- The existing valid public apply entity captures the actual `/up` gzip body
  after a post-verification source mutation and checks the archived file bytes.
- The portability slogan was replaced with direct current-source and symlink
  behavior.
- The reference patch, compatibility API, dependencies, test names, and 28/23
  Linux/macOS census are unchanged.

## Why version 26 was revised

All twelve implementations in `agent-runs6` and `agent-runs7` began their
coherent snapshot at the first opened-descriptor metadata sample. Two were
otherwise 27/28. The former open-phase mutation was already reflected by that
sample and every byte read afterward, so it overconstrained a reasonable
implementation. Separately, the valid CLI test counted a request but did not
prove that the request used the verified body. Version 27 corrects both
boundaries without adding a testcase.

Historical versions 14-27 strengthened these independent public boundaries:

- apply with a persisted `noGitignore` mismatch fails before every request;
- a directly selected Unix socket fails locally instead of being skipped;
- strict plan reading rejects missing Unix modes immediately;
- fallback JUnit retains cargo/compiler diagnostics while preserving test-only
  census classification.

The former synchronized descriptor-race item is intentionally absent from
version 30 because its trigger prescribed libc `read(2)`.

The prompt names only the two stored controls and the four new controller
functions required by grader compilation. Strict format behavior remains
defined once in the schema paragraph. The suite still avoids atomic plan
publication, tar order, compression details, exact error strings, repeated
object kinds, proxy call counts, and exact conflict status codes. Version 16
added no new discriminator; version 17 changed no discriminator. Version 18
retains the absolute and parent-traversal safety boundaries while removing
Serde and diagnostic-presentation requirements.

## Exact validation

| Artifact state | Mode | Result |
|---|---|---:|
| Test patch on pinned base, macOS | `new` | exits 101; one classified fallback retains the compiler diagnostic |
| Combined patches, macOS | `base` | 474 passed |
| Combined patches, macOS | `new` | 23 passed |
| Version-30 combined patches, network-disabled Linux | `base` | unchanged version-29 nextest lane: 474 passed |
| Version-30 combined patches, network-disabled Linux | `new` | 24 passed; JUnit has 0 failures, 0 errors, and no skipped testcase |
| Cargo fallback without nextest, macOS | `new` | 23 passing JUnit cases; zero failures/errors/skips |
| Version-31 reference-only identity probe | replacement / stable followed link | different identity / matching identity |
| Version-31 reference without its new identity check | `new` | 23 passed, proving the strategy is not participant-required |
| Discard verified body and rebuild ordinary archive | `base` / `new` | 474 passed / 22 of 23 passed, with only the captured-upload entity failing |
| Exact `agent-runs7/Nova_Nova_3` replay | `base` / `new` | 474 passed / 23 passed |
| Private wire DTO without public `DeployPlan: Serialize` | parser entity | passed |
| Unsupported-version, absolute-path, and parent-traversal mutants | focused entities | each failed its public assertion |
| Prefix-only parent-component validator, version 25 | other focused / base / unsafe-path | 22 passed / 474 passed / strengthened entity failed |
| Offline CLI ignores positional path with `--path-as-root`, version 25 | other focused / base / CLI option | 22 passed / 474 passed / strengthened entity failed |
| Public apply hard-codes `no_gitignore=false`, version 26 | other focused / base / CLI option | 22 passed / 474 passed / strengthened entity failed |
| Test-only network-disabled Linux, version 27 | fallback JUnit | one classified failure with unresolved-import diagnostic; zero errors/skips |
| Reference without pre-open comparisons, version-23 Linux | focused | deterministic open-phase assertion failed |
| `agent-runs4/Nova_Nova_2`, version-23 Linux | focused | deterministic open-phase assertion failed |
| Reader without reader-side validation, version-23 Linux | focused | raw malformed-record assertion failed |
| Verify-then-reopen mutant, version-23 Linux | focused | atomic payload assertion failed |
| Nova2 first-entry-root candidate, version-24 Linux | focused | path-as-root entity failed with the reported root-marker error |
| v13 pass replay `Nova_Nova_1`, version-22 Linux | historical `new` | 28 passed |
| v13 near replay `Nova_Nova_5` | option mismatch probe | failed after two premature requests |
| v13 pass replay `Nova_Nova_1`, Linux | strengthened parser entity | passed |
| v13 near replay `Nova_Nova_2`, Linux | strengthened parser entity | passed |

Both canonical patches apply independently and together in either order,
reverse-check cleanly, reproduce the formatted prototype, and pass applied
tree whitespace checks.

The first version-18 container launch could not create a nested writable target
mount beneath a read-only source bind and ran no test. The authoritative runs
used the disposable clean worktree as a writable source mount, retained the
task-owned target volume, disabled networking, and completed normally.

Atomic replacement can update `ctime` on the unlinked old inode without
changing its open-descriptor bytes. Version 27 therefore retains either a safe
rejection or a successful archive containing the original descriptor bytes.

## Discriminator profile

The grader has independent families for:

- strict persisted schema, Unix mode presence, and deterministic plan order;
- ordinary selection, archive prefixes, controls, links, and modes;
- CLI local-root identity;
- path-set/type/size/mode/content reconciliation;
- unsupported directly selected objects;
- verified bytes reaching the public `/up` request body;
- write and failure completion before all external effects;
- valid post-verification continuation and parser conflicts.

The exact v14 audit added isolated missing-mode, skipped-socket, omitted-size,
omitted-mode, and late-option-reconciliation mutants to the historical set.
Version 18 repeats unsupported-version validation, isolates absolute and
parent-traversal acceptance, and proves a private wire DTO compiles without
public `DeployPlan: Serialize`. Every actionable mutant is killed; no survivor
remains. Version 19 repeats the verify-then-reopen mutant: it passes all 474
baseline tests and fails the atomic-replacement archived-byte assertion.
Version 20 independently removes modification, size, and mode stability checks;
each matching synchronized Linux race rejects its omission.
Version 21 rejects a permissive raw reader, apply-only current-directory root
selection, and independent token/environment root-policy omissions. Version
22 replays the verify-then-reopen mutant and the conservative legitimate
trajectory on opposite sides of the corrected atomic oracle. Version 23
replaces timing luck with a deterministic open/read barrier and turns a v22
nominal pass into the expected focused failure. Version 24 rejects positional
root-marker validation while keeping global plan ordering. Version 25 covers
positional public CLI root forwarding and component-wide parent rejection.
Version 26 covers independent public `noGitignore` forwarding and makes request
and fallback-runner observations deterministic and correctly classified.
Version 27 retires the open-to-first-sample overconstraint and rejects a public
command that discards the verified body before upload.
Version 28 removes the grader's Cargo feature and selects focused tests through
a checked compiler cfg, eliminating the manifest/lockfile split that blocked
Nova 6 before discovery. Version 29 supplies the ordinarily required
environment selector to the explicit-project write fixture while retaining its
source-root and request-order assertions.
Version 30 retires the libc-read race family, verifies `pread` as an accepted
implementation mode, and keeps the command-level verified-upload oracle.
Version 31 conservatively hardens only the reference's post-read pathname
identity check; the public prompt, tests, and discriminator set are unchanged.
Version 32 repairs an intermittent CONNECT/TLS handoff race in the public
upload-capture fixture without changing its oracle.
Version 33 clarifies that the globally sorted `"."` root record need not be
first after all eight Nova/Orion trajectories repeated that positional
assumption. The grader and reference remain byte-identical to version 32.

The exact version-33 Linux reference is 474/474 baseline and 24/24 focused,
including 24/24 through the cargo fallback. Test-only mode is one diagnostic
failure with no skips. The discard-and-rebuild mutant remains isolated at
474/474 plus 23/24, and both patch orders reverse to a clean base tree.

## Remaining gates

1. `CALIBRATION_STRATEGY.md` remains unavailable as a compressed dataless
   placeholder. Materialize and reread it immediately before spending any run,
   then begin the version-33 immutable ten-run batch at 0/10.
2. Validate the patched artifact in a Windows lane; the pinned upstream base
   has green Windows CI, but the patch has not run there.
3. Recheck private submission-archive similarity when access exists.

Any prompt, test, solution, explanation, or Dockerfile change invalidates the
exact audit and resets calibration to 0/10.
