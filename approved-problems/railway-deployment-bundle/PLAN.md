# PLAN - deterministic Railway deployment bundles

Status: explicitly reopened by the user on 2026-07-26 and redesigned from
supplied trajectories on 2026-07-27. Version 31 preserves version 30's
implementation-independent grader while conservatively hardening the reference
against post-read pathname replacement. The original 81-line immediate preview
remains rejected. Version 13 retains its official observed 2/10 calibration
result; later calibration and adjudication results are historical, and version
31 is the current immutable bundle at 0/10.

## 1. Task identity

| Field | Current handoff |
|---|---|
| Repository | `railwayapp/cli` |
| Language | Rust |
| Task type | feature request |
| Pinned commit | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| Candidate facts | 576 stars; active 2026-07-24; MIT |
| Dependency state | committed `Cargo.lock` |
| Existing harness | approximately 474 tests across 59 modules; cross-platform CI |
| Work namespace | `work/railway-deployment-bundle/` |
| Working title | Persisted and verified Railway deployment plans |
| Current rating | provisional 8/10 after scope and false-positive prototypes; original preview remains rejected |

The seed is to make Railway deployment input planning explicit, deterministic,
and inspectable before upload while preserving the CLI's existing project-root,
service-root, ignore, archive, symlink, and deployment semantics.

The likely public operation would produce a deployment plan or bundle that can
be inspected and then consumed by the existing upload path without selecting a
different set of files. The exact command, Rust API, manifest schema, and
archive format are hypotheses for repository investigation—not an approved
contract.

The reopened prototype may add a source-backed JSON plan/apply lifecycle. Its
content digests are justified only as freshness evidence between separate
commands; the plan must not embed source bytes or become a standalone
deployment archive. This is a materially different hypothesis from printing
the entries of an already-completed tarball.

Do not broaden the task into remote deployment orchestration, authentication,
Railway API changes, build execution, container-image creation, a general
backup tool, content-addressed storage, incremental remote synchronization, or
a new standalone archive format.

## 2. Mandatory stop gates

Run these gates in order. Record exact revisions, dates, commands, logs, links,
and results. If a gate fails, update `candidates/CANDIDATES.md` and this plan
with the rejection. Do not weaken the gate or silently change task identity.

### 2.1 Current eligibility and revision pin

Reverify from primary sources:

- public repository, default branch, and full candidate SHA;
- at least 500 stars and a default-branch commit in the last twelve months;
- MIT or another allowed permissive license at the pinned revision;
- Rust as the primary and expected production-change language;
- committed dependency lock and absence of mutable Git dependencies;
- current CI status at the exact pinned revision;
- every runtime, native library, external executable, and service used by the
  focused and baseline tests; and
- whether fixtures and snapshots are repository-owned and redistributable.

Freeze one green full commit. Do not use the abbreviated candidate SHA in any
problem artifact.

### 2.2 Minimal official-image offline preflight

From a pristine checkout:

1. Use an appropriate official Rust image.
2. Warm only dependencies declared by the pinned repository and lock.
3. Disable networking.
4. Build the CLI with `--locked`.
5. Run the complete deterministic unit/integration subset relevant to project
   roots, ignore rules, archive construction, and deployment upload planning.
6. Run the broadest practical offline baseline.
7. Record image digest, Rust version, system packages, test counts, ignored
   tests, wall time, disk use, and feature flags.

Focused tests must not call Railway's live API, require credentials, depend on
GitHub/network state, or use nondeterministic wall-clock behavior. Reject if
the meaningful local deployment path cannot be exercised offline.

### 2.3 Exact upstream and task-identity audit

Create `UPSTREAM_AUDIT.md`. Before proposing any API, search the exact nouns,
commands, types, modules, tests, and history for:

- bundle, deployment bundle, deploy bundle, package, archive;
- upload, deploy input, file plan, file list, manifest;
- inspect, preview, dry run, explain, deterministic;
- ignore, `.gitignore`, `.railwayignore`, root, service root;
- symlink, hard link, traversal, canonicalize, workspace;
- tar, gzip, zip, compression, checksum, digest;
- include, exclude, hidden file, executable mode;
- issue #181 and every linked issue, pull request, commit, or discussion; and
- the concrete helper/type names discovered in `REPO_MAP.md`.

Search all open, closed, and merged issues and pull requests; Discussions;
releases/changelog; every fetched branch and tag; full Git history; source,
tests, fixtures, and docs; and referenced forks.

Stop if an existing command already previews the upload set, an existing
archive builder already exposes a complete reusable manifest, or public work
specifies the same central operation. Do not rescue overlap by changing output
format or adding incremental metadata.

### 2.4 Local and submission-archive similarity

Search `problems/`, `archive/`, and `candidates/` for:

- deployment packaging and upload planning;
- filesystem publication and archive construction;
- deterministic manifests and canonical ordering;
- ignore/root semantics;
- atomic output and rollback; and
- symlink/path-containment behavior.

Read at minimum:

- `archive/3d-tiles-atomic-output/` and its manifest;
- the 3D Tiles design, summary, environment postmortem, and decisive solver
  records;
- the Calyx and RustPBX shortcut-rejection archives;
- any local problem involving archives, filesystem trees, or deterministic
  serialization; and
- representative raw trajectories required by `PROBLEM_DESIGN.md` if their
  failure mechanism is relevant.

The Railway task must remain distinct from 3D Tiles. “Build an output elsewhere
and publish it atomically” is already used. A Railway task whose central
discriminator is destination rollback, temporary-path cleanup, or atomic
archive publication must be rejected rather than renamed.

If the platform exposes a private submission archive, search it before
problem design. Treat absence of access as residual risk, not a completed gate.

## 3. Cheapest-legitimate-solution prototype

This is the decisive gate. Create `PROTOTYPE.md` and first build the smallest
correct implementation using existing helpers.

Test whether the complete proposed behavior can be satisfied by:

1. locate the existing deployment root;
2. reuse current ignore matching;
3. walk the selected files;
4. sort normalized relative paths;
5. write a simple manifest or archive; and
6. pass that archive into the existing upload seam.

Measure strict effective production lines, files touched, and decisions not
already delegated to current helpers.

Reject the seed if:

- the implementation is a thin wrapper around an existing file collector or
  archive writer;
- the honest production change is materially below the active scope target;
- difficulty comes from enumerating more ignore/path cases rather than
  crossing independent implementation boundaries;
- a generic filesystem/archive library does nearly all solver work;
- the plan is generated but the real uploader independently reselects files;
  or
- tests would have to require a private pipeline or forbid reuse of existing
  helpers to force scope.

Do not add checksums, signatures, caching, remote deduplication, incremental
upload, rollback, or a custom format merely to increase line count.

## 4. Repository map to produce

Create `REPO_MAP.md` before fixing the contract. Locate and explain:

- CLI deploy command entry points and argument parsing;
- project/environment/service root resolution;
- configuration discovery and workspace behavior;
- `.gitignore`, `.railwayignore`, and other exclusion handling;
- filesystem walking and path normalization;
- symlink and path-containment policy;
- current archive/stream construction;
- upload request construction and remote API boundary;
- progress, size, and file-count reporting;
- error handling and cleanup;
- existing dry-run, debug, JSON, or machine-readable output conventions;
- test fixtures for nested roots, ignore files, permissions, and links;
- platform-specific filesystem handling;
- current test commands and offline feature composition; and
- every dependency involved in walking, matching, archiving, compression, and
  hashing.

For each stage, record:

- input and output ownership;
- whether ordering is deterministic;
- when filesystem metadata/content is read;
- whether file selection is repeated by later stages;
- how errors and unsupported file types are represented;
- whether paths are lexical or canonical;
- which state is observable through public CLI behavior; and
- whether one immutable plan can genuinely drive upload.

## 5. Feasibility questions

Answer these from pinned repository evidence:

1. What is the maintainer-natural public surface: command flag, subcommand,
   Rust type, or machine-readable output?
2. Does the existing uploader stream a tree directly, build an archive, or
   delegate packaging elsewhere?
3. Is there already one canonical file-selection function?
4. Can preview and upload share one immutable plan without changing current
   behavior?
5. What is the semantic root when project, service, workspace, and explicit
   root settings interact?
6. Which ignore files apply, in what order, and relative to which root?
7. Are ignored parents allowed to contain explicitly re-included children?
8. What is current symlink behavior, including links outside the root, broken
   links, loops, and platform differences?
9. Are modes, empty directories, or non-UTF-8 names part of the current upload
   contract?
10. How are concurrent file changes between planning and upload handled today?
11. Can output be deterministic without inventing archive-byte reproducibility
    where the repository only promises a stable file set?
12. Can a natural correct implementation meet scope and long-horizon criteria?

Unspecified repository behavior must be investigated, not filled with generic
archive conventions.

## 6. Candidate public behavior

Only promote requirements supported by the pinned repository. A coherent task
might provide:

- one explicit deployment plan representing the exact upload file set;
- stable normalized relative ordering;
- repository-consistent ignore and root behavior;
- inspectable per-entry path, type, and upload-relevant size or metadata;
- an upload path that consumes the plan rather than independently rescanning;
- deterministic repeated planning for an unchanged tree;
- clear rejection or representation of unsupported/out-of-root links; and
- existing deploy behavior preserved when the new inspection surface is not
  used.

Do not require byte-identical compressed archives unless the project already
promises canonical archive bytes. Do not assert private walker order, helper
names, temporary paths, compression library, hash function, or internal data
layout.

## 7. Trajectory-informed design gate

Before creating or revising `test.patch`:

1. Read `PROBLEM_DESIGN.md` completely.
2. Search the local problem index, candidate registry, and archives by
   repository, subsystem, behavior, shortcut, and invariant.
3. Read relevant `SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and
   `RUNS.md`.
4. Inspect a representative legitimate pass, near-pass, and broad failure when
   raw evidence exists; record unavailable categories honestly.
5. Record solver files/seams, data flow, validation/commit timing, shortcuts,
   missed invariants, and proactive checks.
6. Test deterministic replay/history reconstruction if any resumability or
   persisted plan behavior is proposed.
7. Create `DESIGN.md` from `templates/problem/DESIGN.md`.
8. Record the evidence table and discriminator ledger before hidden-test work.

Analogical filesystem trajectories may suggest questions, but Railway's pinned
repository and public contract control fairness.

## 8. Candidate discriminator families

Validate—do not assume—distinct public boundaries such as:

- project/service/root resolution;
- layered ignore and re-inclusion semantics;
- lexical/canonical path containment and symlinks;
- deterministic normalized plan ordering;
- one plan shared by inspection and upload;
- metadata/content changes after planning;
- platform-independent behavior; and
- compatibility with the current deploy command.

Multiple filenames, ignore patterns, nested directories, or link targets are
coverage breadth unless they cross a genuinely different semantic boundary.
Every final discriminator must trace to a public requirement, black-box oracle,
distinct failure family, and trajectory or repository evidence.

## 9. Mandatory false-positive audit

Before calibration, follow the false-positive gate in `AGENTS.md` and the
worked method in
`problems/statig-local-transitions/false_postive trials.md`.

Plausible candidate survivors include:

- generate a correct preview but rescan differently during upload;
- sort display output while archive entry order remains unstable;
- apply ignore patterns relative to the process directory rather than the
  resolved deploy root;
- use one ignore file while silently skipping layered repository behavior;
- follow an out-of-root symlink;
- reject every symlink regardless of existing deploy semantics;
- normalize separators for display but not for archive entries;
- include changing files with plan metadata from one version and bytes from
  another; and
- preserve selected paths but lose upload-relevant executable/type metadata.

Only repository-supported survivors justify probes. Run meaningful survivors
through the complete existing suite, replay representative solver patches when
available, and record rejected artificial mutants as well as actionable ones.

Any prompt, test, reference-behavior, or submission-artifact change creates a
new immutable version. Repeat required checks and restart calibration at 0/10.

## 10. Verification and calibration

Build a reproducible verifier that checks:

- exact pinned base and patch applicability;
- focused base failures and reference passes;
- complete offline baseline passes before and after the reference;
- committed-lock and feature composition;
- repeated deterministic planning on unchanged trees;
- relevant cross-platform path behavior without OS-specific assertions;
- formatting and linting;
- mutation and false-positive gates;
- artifact hashes and absence of leaked fixtures/solution details; and
- no Railway credentials, live API, network, or timing dependency.

Before recommending solver runs, read `CALIBRATION_STRATEGY.md`. Run one Nova
and one Orion local preflight against the exact immutable version and save
their trajectories under `estimate_trajectories/`. If both solve cleanly,
harden before upload. Platform calibration begins at 0/10 and never mixes
problem versions.

## 11. Handoff outcome

The next agent must leave one of two evidence-backed outcomes.

### Proceed

- current eligibility and exact green revision recorded;
- official-image offline lane passes;
- exhaustive upstream/local/archive audits pass;
- exact task nouns and concrete seams are absent from prior art;
- cheapest legitimate prototype does not collapse into a small wrapper;
- honest scope clears the platform target;
- repository map supports a maintainer-natural black-box oracle;
- `DESIGN.md` records the trajectory-informed gate; and
- multiple legitimate internal implementations can satisfy the contract.

### Reject

- record the decisive failed gate in this plan and
  `candidates/CANDIDATES.md`;
- preserve audit links, environment logs, repository map, shortcut prototype,
  and measured scope;
- do not author hidden tests or add unrelated features to save the rating; and
- update `problems/README.md` if this folder becomes a durable rejection record.

Do not commit active work. Olympus commits only at verified cleanup or archival
checkpoints.

## 12. Terminal outcome recorded 2026-07-26

Verdict: **Reject**.

The exact pinned revision is
`4d49d9845a27a0947ab903b01789eb9f854414d8`. Its complete 474-test suite and a
focused deployment-seam probe passed offline in the official Rust 1.88
Bookworm image. The exhaustive upstream audit found no existing public upload
plan or manifest operation, and the local audit kept the task distinct from 3D
Tiles atomic publication.

The decisive gate is section 3. `create_deploy_tarball` already owns root
semantics, both ignore layers, manual exclusions, traversal, link behavior,
tar construction, gzip, and the complete in-memory request body.
`upload_deploy_tarball` consumes that body without rescanning. The disposable
prototype only retained sorted entry names next to the existing body and added
a small output branch:

- 2 existing production files;
- 90 raw production additions and 23 deletions;
- 81 strict effective production additions;
- no dependency, new algorithm, or independent subsystem; and
- 475/475 prototype tests passing offline, including the one added probe.

Requiring checksums, snapshots, canonical compressed bytes, link containment,
rollback, or a private plan pipeline would change the task identity or pad it.

Durable evidence:

- `ENVIRONMENT.md` — eligibility, image, commands, timings, counts, and
  dependencies;
- `UPSTREAM_AUDIT.md` — full upstream prior-art and history audit;
- `SIMILARITY_AUDIT.md` — local/archive comparison and representative
  trajectory evidence;
- `REPO_MAP.md` — exact roots, ignore, link, archive, upload, and error flow;
- `PROTOTYPE.md` — measured shortcut and rejection rationale; and
- `scope-prototype.patch` — exact disposable implementation and focused test.

The candidate and problem indexes have been updated. A materially different
Railway subsystem may be reconsidered only through a fresh audit and early
scope spike; do not revive this seed with additional manifest fields or path
fixtures.

## 13. Persisted-plan redesign outcome recorded 2026-07-26

Verdict: **Proceed past the disposable scope and false-positive gates only**.

The user explicitly reopened the candidate in light of Statig's later review
trajectory. The redesign does not add fields to the rejected preview. It
separates planning and deployment across invocations:

- offline `up --write-plan <file>` writes strict, versioned JSON;
- later `up --from-plan <file>` reconciles selection, type, size, mode, and
  SHA-256 against current source;
- the exact verified file snapshots become the archive body consumed by the
  existing uploader; and
- local plan failures occur before the existing auth/client/network path.

The first persisted implementation is preserved as
`verified-plan-prototype.patch`. The canonical-selector/followed-link
intermediate is `verified-plan-prototype-v2.patch`. The final audited
implementation is `verified-plan-prototype-v3.patch`, SHA-256
`27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`.
It measures:

- 5 production files touched;
- 668 raw production additions and 81 deletions;
- 615 strict effective production additions;
- 437 raw focused-test additions;
- no new dependency; and
- 481/481 host tests and 483/483 tests in the final network-disabled
  official-image run.

This clears the original LOC/thin-wrapper objection because the work crosses
persistence, reconciliation, content-integrity, archive-consumption, and
external-effect-ordering boundaries. The final prototype extracts one
canonical selector shared by ordinary and plan upload, preserves Railway's
followed-link behavior and Unix file/directory modes, defers OAuth refresh
until local verification succeeds, and passes two process-level counting
oracles.

`FALSE_POSITIVE_AUDIT.md` records ten mutation families. Six meaningful
survivors passed the then-current focused and complete upstream suites before
being isolated by public probes for deferred refresh, non-UTF-8 identity,
directory modes, `--no-gitignore`, archive-prefix/root behavior, and repeat
plan writes. A Linux atomic-replacement probe independently rejects the
central verify-then-reopen shortcut.

Required next gates before submission:

1. recheck private submission-archive similarity when that source is
   available;
2. turn the prototype contract into a reviewed public prompt and only then
   design hidden tests from the approved discriminator families;
3. run the mandatory false-positive audit again for that exact prompt/test
   artifact;
4. validate the final artifact in upstream's Windows CI lane; and
5. read `CALIBRATION_STRATEGY.md` before recommending or spending any solver
   runs.

Do not calibrate this disposable prototype or carry its results into a later
artifact version.

## 14. Canonical submission-bundle outcome recorded 2026-07-26

Verdict: **Artifact-complete and ready for fresh calibration at 0/10**.

The public contract was frozen in `meta.md`. `test.patch` adds a feature-gated
grader with a root `test.sh`, JUnit-producing nextest configuration, 19 named
macOS entities, and 21 Linux entities. `solution.patch` is byte-identical to
the final v3 production/reference prototype. `solution_approach.md` explains
the shared selector, strict plan schema, verified snapshot transaction, and
deferred authentication path. The Dockerfile pins Rust 1.88.0 and
cargo-nextest 0.9.100.

Exact identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bfaab788d1af0a9cc2fce6bdba49ec147abec722c9e34135f1888acb2cd988a5` |
| `test.patch` | `3187049b49d4f16faa199f33039d74a61e5e09bec2a2a91d82368eb4ba8ef402` |
| `solution.patch` | `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Validation results:

- test patch on base: `base` 474/474; `new` fails at the absent plan
  controller and emits failing fallback JUnit;
- combined patches on macOS: `base` 481/481; `new` 19/19;
- final network-disabled Linux image: `base` 483/483; `new` 21/21;
- valid JUnit reports contain the same entity totals;
- both patches apply independently and together, reverse-check cleanly, and
  pass formatting/whitespace checks; and
- the exact false-positive audit kills ten plausible mutation families,
  including the pre-probe full-suite survivor that omitted deferred refresh
  after valid local verification.

The artifact version has no solver evidence. Per `CALIBRATION_STRATEGY.md`,
the next batch starts at 0/10 and targets ten runs on this exact hash set.
Any prompt, test, reference, explanation, or Docker change invalidates the
audit and restarts calibration. A patched Windows run and private
submission-archive similarity search remain review risks; upstream's exact
base revision has green Windows CI.

## 15. Reviewer-interface revision recorded 2026-07-26

Before calibration, reviewer feedback identified that the controller seam
compiled by hidden tests was not declared in the prompt. Version 1 was
superseded at 0/10. Version 2 adds only the minimal test assumptions, replaces
long source-selection enumeration with ordinary-upload parity, and removes the
redundant ordinary-mode sentence.

The grader no longer asserts reference error strings. Every grader test
function now starts with `deployment_plan_`; nextest and cargo fallback both
select exactly 19 tests on macOS, with the two intended Linux-only tests
bringing the container total to 21. Test-only, reference host, offline Linux,
patch integrity, and the ten-mutant false-positive audit all passed again on
the version 2 hashes above. The Linux image identity is
`sha256:429ccf6d3717c855c3a5a34230fa6201a2ff0cc8addd4f2502843feeb3ba5b34`.

## 16. Prompt-minimization revision recorded 2026-07-26

Version 2 was superseded before calibration at 0/10. The prompt no longer
names the existing upload helper or the internal refresh-classification
helper. The new `controllers::deploy_plan` seam remains declared because it is
required for grader compilation; ordinary-upload parity and reconciliation
before authentication state the relevant behavior.

Only `meta.md` changed, producing version 3 with prompt SHA-256
`7806b2c24d587c0aec67867f2ede46fc8b7b923021d0adc9b9a3ce7f08476a2d`.
The tests, reference, explanation, Dockerfile, and Linux image retain the
version 2 identities above. Test-only behavior, the 481/19 macOS reference
runs, the network-disabled 483/21 Linux runs, patch integrity, and all ten
false-positive mutants were replayed successfully for the exact version 3
prompt. Calibration remains 0/10.

## 17. Public-oracle revision recorded 2026-07-27

Version 3 was superseded before calibration at 0/10. The public prompt and
reference implementation are unchanged. The grader no longer compares
complete `DeployPlan` values, so it does not impose undocumented
`Debug`/`PartialEq`/`Eq` bounds. The unit module that called `build_args` and
`command_needs_refresh` was deleted. Public spawned-process tests now check
all three flag-conflict combinations and make eager OAuth refresh observable
through an expired isolated config and counting proxy.

Version 4 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `7806b2c24d587c0aec67867f2ede46fc8b7b923021d0adc9b9a3ce7f08476a2d` |
| `test.patch` | `768e83a993e586a1001c6539ed347c3f3ffc9bd5b07c47129d92f2dce6898f38` |
| `solution.patch` | `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passed: test-only base 474/474 with expected missing-solution
failure in `new`; reference macOS 481/481 base and 18/18 focused; and
network-disabled Linux 483/483 base and 20/20 focused with valid JUnit in image
`sha256:689a9e8cb0c333a7cebbc4af5f1df61e6d62fe7f441553f6cf68af2550425884`.
Both patches apply independently and together in either order, pass format and
whitespace checks, and reverse-check cleanly. A trait-stripped compatibility
replay passed 18/18, and all 11 exact-version mutants failed their strongest
public probes. Calibration remains 0/10.

## 18. Network-continuation minimization recorded 2026-07-27

Version 4 was superseded before calibration at 0/10. The prompt drops the
redundant sentence stating the ordinary success continuation. The valid-apply
process test now requires at least one connection after local verification,
instead of encoding refresh plus remote flow as two distinct requests. The
reference, explanation, and Dockerfile are unchanged.

Version 5 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `11590b3289d6462bd401c24a69e61fc2fa74d7b0abad5fa64dc41e069d42e553` |
| `solution.patch` | `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passed: test-only base 474/474 with expected missing-solution
failure in `new`; reference macOS 481/481 base and 18/18 focused; and
network-disabled Linux 483/483 base and 20/20 focused with valid JUnit in image
`sha256:ae2ccb14959acfdf06c771dc5409d4d1af92f89d38817e31eba4acd9b35f6669`.
Both patch orders, reverse checks, format checks, and cargo-fallback selection
passed. The exact 11-mutant audit replaces the artificial missing-refresh
count mutant with a valid-apply no-op and has no actionable survivor.
Calibration remains 0/10.

## 19. Schema-boundary revision recorded 2026-07-27

Version 5 was superseded before calibration at 0/10. The prompt, reference,
explanation, and Dockerfile are unchanged. The grader now directly checks
that serialized non-default `pathAsRoot` and `noGitignore` values are present,
that generated directories have size zero and no digest, that readers and
serializers reject directory-only metadata violations, and that absolute and
parent-traversal plan paths are refused.

The reported nextest syntax defect was not reproducible: cargo-nextest
documents `~string` as the contains matcher, and both the old expression and
the default `test(deployment_plan_)` expression selected the same pre-revision
host set. The harness now uses the latter spelling for review clarity. The
final cargo-nextest 0.9.100 image enumerates all 21 Linux grader entities.

Version 6 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `6fbcdc32575730de5abeb88ebb4164f501f75dcec6a96daa7ebf52349c2be098` |
| `solution.patch` | `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passed: test-only base 474/474 with expected missing-solution
failure in `new`; reference macOS 481/481 base and 19/19 focused; and
network-disabled Linux 483/483 base and 21/21 focused with valid JUnit in image
`sha256:52d93cb5a3f83f719acad3a7b3e17e10c7882faf10443e5d157125f0d319b802`.
Both patch orders, reverse checks, format checks, and cargo-fallback selection
passed. The exact 14-mutant audit has no actionable survivor; its three new
mutants cover hard-coded top-level controls, omitted directory validation, and
unsafe plan paths. Calibration remains 0/10.

## 20. Wrapper-entity and CLI-fairness revision recorded 2026-07-27

Version 6 was superseded before calibration at 0/10. The prompt, reference,
explanation, Dockerfile, and 19 macOS / 21 Linux behavioral entities are
unchanged. Three grader-fixture corrections create version 7:

- if the solution-owned controller API is absent and per-test JUnit cannot be
  produced, the synthetic fallback `new.run` is skipped rather than reported
  as an unclassifiable failure; the process still returns its original exit
  status 101;
- the offline write process supplies neither project nor environment; and
- the invalid-apply process supplies both project and environment, so a
  skipped reconciliation would reach authentication and the counting proxy
  instead of failing the existing selector-pair validation.

Version 7 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `03781d163e0d9d61df133e6a077931e3831862cf815eccb0a0dbb159183f8007` |
| `solution.patch` | `27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passed: test-only base 474/474; test-only `new` exits 101 with
one skipped fallback testcase and no JUnit failure/error; reference macOS
passes 481/481 base and 19/19 focused; and network-disabled Linux passes
483/483 base and 21/21 focused in image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.
Both patch orders, format and whitespace checks, and all 14 exact-version
mutants passed their gates. The eager-refresh mutant made two requests in the
revised invalid-apply probe and was rejected. Calibration remains 0/10.

## 21. Reference-entity and archive-order revision recorded 2026-07-27

Version 7 was superseded before calibration at 0/10. The prompt, explanation,
Dockerfile, production reference behavior, and behavioral discriminator
families are unchanged. Version 8 makes two accounting/fairness corrections:

- remove nine self-tests that existed only in `solution.patch` and therefore
  could not enter either the wrapper's p2p or f2p set; and
- compare decoded tar paths after normalization and sorting, because ordinary
  upload and the public prompt do not promise a tar member sequence. Exact
  plan-entry order remains required.

Version 8 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `cd51d0d25782d0eb17c50bf57c7d4bc8d45250240bb43fadab587ba0157f21d2` |
| `solution.patch` | `3b1b56bdafa4b977627b41e97358b9cda0ea963c67bcaa2ee72b48d13c532bcc` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passed: test-only base 474/474; test-only `new` exits 101 with
one skipped fallback testcase and no JUnit failure/error; reference macOS
passes 474/474 base and 19/19 focused; and network-disabled Linux passes
474/474 base and 21/21 focused in image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.
The base entity symmetric difference is zero on both platforms. The wrapper
census is 474 p2p, 21 f2p, one skipped synthetic placeholder, and no
unclassified entity. Both patch orders, format/whitespace checks, and all 14
exact-version mutant gates passed. M2 also passed all 474 pre-existing tests
before failing the Linux atomic-snapshot discriminator. Calibration remains
0/10.

## 22. Agent-run environment repair and trajectory redesign recorded 2026-07-27

Version 8 was superseded with zero valid calibration runs. Both supplied
official Nova evaluations failed before testing: `test.patch` and each
participant edited `src/controllers/mod.rs`, and the wrapper fallback deleted
the participant's `pub mod deploy_plan` export. Corrected additive version-8
replays were 21/21 for Run 1 and 14/21 for Run 2; these are diagnostic design
evidence, not calibration.

Version 9 makes the following targeted changes:

- inject the grader from `src/consts.rs`, away from the participant-owned
  module export;
- exclude solver-authored `deploy_plan`, `deployment_plan`, and `up_plan`
  self-tests from the 474-test baseline census in both runner paths;
- retain one explicit selected-root identity oracle while removing root-based
  cascades and index-dependent schema fixtures;
- require each regular-file plan record to come from one coherent
  descriptor-backed snapshot, with a Linux same-inode mutation probe; and
- prove malformed plan parsing, as well as content reconciliation, completes
  before authentication and every request.

Version 9 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bc682a86ed12764b43e6251586a62e4dd8366ad126c1828448aadb9f776c50c1` |
| `test.patch` | `26a8751b9ddf9abccf1975e0cde75db436807914d87482308ade93b2de56b741` |
| `solution.patch` | `be61c9cad6bb3c1c478ed1141d84e1418e63c7b65783b3fb78e4007137cc5c59` |
| `solution_approach.md` | `70ee500b728e09d24aae9655da168f324dc37b0d0cf813bb8042141ba9a30302` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Exact validation passes 474/474 base plus 20/20 macOS and 23/23 Linux grader
entities. Test-only `new` retains its expected absent-controller exit and
produces one skipped synthetic testcase. The Linux wrapper census is 474 p2p,
23 f2p, one skipped placeholder, and zero unclassified entities.

The revised exact harness gives Run 1 474/474 plus 22/23, failing only coherent
snapshot formation, and Run 2 474/474 plus 22/23, failing only selected-root
identity. The two near-passes therefore expose different public boundaries.
The exact 14-mode false-positive audit has no actionable survivor. Version 9
was approved to start calibration at exactly 0/10, but was superseded after
the later `agent-runs2` batch solved it 2/2.

## 23. Agent-runs2 hardening recorded 2026-07-27

Both new Nova runs are legitimate version-9 solves: 474/474 base and 23/23
new. Their environment warnings were recoverable and did not prevent any
behavioral test. Following the mandatory 2/2 harden rule, version 10 restarts
calibration at 0/10 and adds three targeted boundaries:

- replace the length-changing planning race with a same-size, same-mode
  in-place write and require stable descriptor modification time;
- expose ordinary linked-parent versus explicit-project local-root resolution
  through a public CLI plan comparison; and
- run write, malformed apply, and changed-source apply without auxiliary
  network opt-outs.

Atomic plan publication, exact tar order, compression details, error prose,
call counts, and extra schema/path spellings remain rejected as duplicate,
artificial, or implementation-specific.

Version 10 identities:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `96ff6ae0eb5c125f0b643a94f67e901e4d25c27488d8b314b5421bb082c93e9b` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c` |
| `solution_approach.md` | `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

The exact reference passes 474/474 base plus 21/21 macOS and 24/24 Linux
grader entities. Test-only accounting has 474 p2p, one skipped fallback, and
zero unclassified entities. The two new solvers each replay at 474/474 plus
23/24, failing only the strengthened snapshot branch. The earlier near-pass is
474/474 plus 21/24 across snapshot and selected-root families.

The exact false-positive audit has no actionable survivor. Version 10 was
approved to begin fresh calibration at exactly 0/10, but was superseded before
any run by the prompt-only cleanup below.

## 24. Reviewer-driven prompt cleanup recorded 2026-07-27

One sentence spelling out linked-parent, explicit-project, and environment
consequences was removed because it repeated the preceding ordinary-upload
source-selection and local-root parity requirement. No behavioral requirement,
test, reference behavior, dependency, or environment artifact changed.

Version 11 changed only the prompt hash to
`55df6607e9a306939ec5a6b51b7da24aa8c87bcc32d82b4f6531d9460665d577`;
all other canonical hashes remain those in the version-10 table. The
trajectory ledger and exact false-positive audit were rechecked against the
shorter prompt. Version 11 was superseded at 0/10 by the reference correction
below.

## 25. Snapshot reference reliability correction

The external verifier reported the Linux same-size snapshot entity failing
with the reference applied. The old reference took its final descriptor
metadata before digesting. Version 12 clarifies that the descriptor-backed
snapshot lasts through completion, captures pathname metadata immediately
before `open`, and moves the final descriptor metadata check after digesting.

The hidden test remains byte-identical. Exact Linux reference JUnit is 24
tests, zero failures, zero errors, and zero skips; base is 474/474 and macOS
new is 21/21. The race passed 20 consecutive image repetitions. Version 12
hashes are recorded in `SUMMARY.md`.

The repeated false-positive audit found that the old reference passed five
local repetitions while failing externally. That timing-dependent survivor
prevents calibration approval. A delayed-write prototype added no distinct
discrimination and was removed. Version 12 remained 0/10 and was superseded by
the prompt-only version-13 cleanup before calibration.

## 26. Agent-runs3 result and version-14 review revision

The immutable version-13 batch produced two reported passes in ten runs while
all ten retained the 474-test baseline. The raw trajectories, patches,
evaluations, and logs were reviewed before changing any artifact. Six
near-passes missed only the planning snapshot boundary; one missed two
pre-network apply boundaries; and one combined both families.

Version 14 implements only reviewer-supported public changes:

- narrow apply-option wording to the persisted `pathAsRoot` and
  `noGitignore` controls;
- describe reusable planning behavior without a Test Assumptions heading or
  named new module, types, and signatures;
- require a regular file at open and stable size, Unix mode, and mtime through
  descriptor-backed snapshot completion;
- serialize the four memory-heavy Linux watcher tests and bound observation
  to 30 seconds;
- isolate mtime, size, and mode mutations, preserving the other observable
  attributes in each branch;
- add public zero-request CLI probes for persisted-option mismatch and a
  directly selected Unix socket;
- reject absent Unix modes during strict plan validation; and
- retain test-only skip classification while embedding full XML-escaped cargo
  diagnostics in fallback JUnit.

Complete replay showed both reported version-13 passes comparing descriptor
`ctime`; both now pass 27/28 and fail the existing atomic-replacement
invariant when its event is observed. The official version-13 solve rate
remains 20% as history, but no run transfers to version 14.

Exact version-14 validation is 474/474 base and 28/28 network-disabled Linux
new with zero failures, errors, or skips; macOS new is 23/23. Five isolated
mutants are rejected, and the atomic reference entity passes five consecutive
image repetitions. Immutable hashes and the exact audit are in `DESIGN.md`,
`LEVELS.md`, and `FALSE_POSITIVE_AUDIT.md`.

## 27. Version-15 interface and strict-reader revision

The latest review found that version 14 removed the concrete symbols that the
grader still imports. Version 15 deletes the abstract reusable-operations
sentence and discloses only the required controller types/functions, their
parameter/result shapes, and the existing upload comparison seam. No
algorithm, data structure, error prose, or private call order is prescribed.

The existing parser entity gains an unsupported-version reader branch and one
unknown entry-field branch. Both clauses were already public, both historical
representative implementations pass them, and both live inside the existing
strict-schema family. Isolated permissive-reader mutants fail the added
assertions.

The exact version-15 reference remains 474/474 base, 28/28
network-disabled Linux new with zero failures/errors/skips, and 23/23 macOS
new. Its prompt and grader hashes are recorded in `DESIGN.md`; all solution,
explanation, container, and production bytes remain unchanged. Calibration
restarts at 0/10.

## 28. Version-16 root-entry and conflict-oracle revision

Version 16 explicitly states that the selected root is a directory entry and
uses `"."` when mapped to archive root. It removes the pre-existing upload
helper signature from Test assumptions, since ordinary source-selection parity
already defines the behavior.

The public conflict fixture now accepts any non-zero status, requires the
diagnostic to name the supplied conflicting options, and retains the
zero-request assertion. The existing root-path fixture rejects a focused
root-omission mutant; reported pass and near-pass implementations both satisfy
the relaxed conflict check.

Exact validation remains 474/474 network-disabled Linux base, 28/28
network-disabled Linux new with zero failures/errors/skips, and 23/23 macOS
new. Solution, explanation, Docker, production, wrapper, and test-count bytes
are otherwise unchanged. Calibration restarts at 0/10.

## 29. Version-17 prompt minimization

Version 17 removes only the final sentence repeating that the reader validates
strict input and the serializer validates before deterministic output. Those
requirements remain explicit in the schema paragraph; all four grader-facing
signatures remain.

Tests, reference, explanation, Dockerfile, wrapper, and production code are
byte-identical to version 16. Repeated reader and serializer mutants still fail
the unchanged strict parser entity. Exact validation is 474/474
network-disabled Linux base, 28/28 network-disabled Linux new, and 23/23
macOS new. Calibration restarts at 0/10 because the prompt hash changed.

## 30. Version-18 fairness correction

Version 18 removes three evaluator-identified overconstraints without changing
the core difficulty profile:

- the unsupported-version fixture now creates on-disk JSON through the
  declared serializer and a `serde_json::Value`, so public `DeployPlan` need
  not implement `Serialize`;
- the prompt states that non-root archive paths are relative and contain no
  `..` component, making the existing absolute and parent-traversal probes
  explicit; and
- conflict checks require unsuccessful local completion and zero requests,
  with no diagnostic-text contract.

A private wire-DTO compatibility prototype passes. Isolated
unsupported-version, absolute-path, and parent-traversal mutants fail their
focused assertions. Exact validation is 474/474 network-disabled Linux base,
28/28 network-disabled Linux new with no failed, errored, or skipped testcase,
and 23/23 macOS new. Calibration restarts at 0/10 for the new prompt and test
hashes.

## 31. Version-19 verified-byte prompt minimization

Version 19 retains the observable requirement that verified bytes become
upload-archive bytes and removes the internal prohibitions on reopening a
pathname or performing a second scan. No test, API, reference, dependency,
wrapper, or container artifact changes.

The verify-then-reopen mutant passes all 474 baseline tests and fails the
unchanged Linux atomic-replacement archived-byte assertion. Exact reference
validation remains 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new. The prompt-only hash change
restarts calibration at 0/10.

## 32. Version-20 snapshot-clause prompt minimization

Version 20 deletes only the abstract sentence calling each regular-file record
a coherent descriptor-backed snapshot. The next sentence continues to require
rejection when an opened input is non-regular or when its size, Unix mode, or
modification metadata changes before snapshot completion.

No test, API, reference, dependency, wrapper, or container artifact changes.
Independent modification-, size-, and mode-check omissions compile and each
fail its matching synchronized Linux race. Exact reference validation remains
474/474 network-disabled Linux base, 28/28 network-disabled Linux new, and
23/23 macOS new. The prompt-only hash change restarts calibration at 0/10.

## 33. Version-21 reviewer correction

Version 21 removes the phrase “Test assumptions” from the compatibility
heading. The existing strict-record entity now writes reversed and duplicate
raw JSON to disk and requires the public reader to reject both. The existing
CLI root entity now reconciles through `--from-plan` for linked,
explicit-project, project-token, and environment-variable targeting, including
a changed explicit-project input that must fail before requests.

The reference offline resolver now follows ordinary `up`: only an unoverridden
local link supplies an ancestor root; explicit projects, project tokens, and
environment targeting use the current directory. A permissive-reader mutant,
an apply-always-current-directory mutant, and independent token/environment
root omissions fail their matching probes.

Exact validation is 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new. Both patch orders, reverse
checks, formatting, shell syntax, and applied-tree checks pass. Version 20's
reported 1/10 does not carry forward; version 21 starts at 0/10.

## 34. Version-22 atomic-replacement fairness correction

Version 22 changes one Linux assertion. Once the watcher observes the selected
descriptor and atomically replaces its pathname, plan application may reject
the change. If it succeeds, the decoded archive must still contain the
complete pre-replacement payload.

This admits conservative descriptor-identity or change-metadata checks without
allowing a successful verify-then-reopen implementation to archive replacement
bytes. The historical legitimate `Nova_Nova_1` replay now passes 28/28, while
an isolated pathname-reopen mutant passes 27/28 and fails the revised byte
assertion.

Prompt, reference, explanation, API, schema, wrapper, dependencies, image, and
test count remain unchanged. Exact validation is 474/474 network-disabled
Linux base, 28/28 Linux new, and 23/23 macOS new. Version 22 begins a fresh
calibration batch at 0/10.

## 35. Version-23 deterministic snapshot and reader correction

The complete version-22 `agent-runs4` batch produced three nominal passes.
Review of the raw patches showed that all three sample descriptor metadata only
after `open`; two passed because the `/proc/self/fd` polling watcher did not
win the intended interval. Version 23 replaces polling and large payloads with
a test-only Linux interposer that synchronously blocks the exact selected
descriptor after kernel `open` or the first positive `read`.

The prompt replaces “must fail clearly” with “must return an error.” The
existing strict-record entity now feeds missing and invalid-length file
digests and an unknown entry kind through `read_deploy_plan`. No test count,
production hook, error-string assertion, tar-order rule, or reference behavior
is added.

Exact reference results are 474/474 network-disabled Linux base, 28/28 Linux
new with no skipped new testcase, and 23/23 macOS new. The test-only lane exits
101 with the unresolved-controller diagnostic preserved in fallback JUnit.
Both patch orders and reverse checks, whitespace checks, and formatting pass.

A pre-open-comparison omission, the exact v22 Nova2 nominal pass, a
reader-validation omission, and a verify-then-reopen mutation each fail their
matching focused oracle. No incorrect mode survives the focused suite. Version
23 is immutable at the hashes in `DESIGN.md` and
`FALSE_POSITIVE_AUDIT.md`, and calibration restarts at 0/10.

## 36. Version-24 root-marker-position correction

A supplied version-23 candidate passed all 28 tests but rejected a valid
path-as-root source containing `-hello.txt`. Its validator assumed the first
globally sorted entry was the root directory marker. Since `"-"` sorts before
`"."`, that assumption contradicts both global path ordering and ordinary
upload source parity.

Version 24 adds `-hello.txt` to the existing prefix/path-as-root entity. It
requires the root plan order `["-hello.txt", ".", "app.txt"]` and checks that
ordinary and verified archives contain the same normalized paths. Archive
paths are normalized and sorted before comparison; tar-stream sequence remains
unspecified.

The unchanged reference passes 474/474 network-disabled Linux base, 28/28
Linux new, and 23/23 macOS new. The exact Nova2 validator compiles and fails
only the strengthened entity with the reported root-marker diagnostic. Both
patch orders, reverse checks, formatting, and test-only diagnostic capture
pass. Prompt, reference, API, dependencies, wrapper, image, test name, and test
count are unchanged. Version 24 starts calibration at 0/10.

## 37. Version-25 CLI-path and embedded-parent correction

The version-24 reviewer found two public false-positive gaps. Plan CLI tests
did not combine positional `PATH` with `--path-as-root`, and raw unsafe-path
fixtures did not isolate an embedded `..` component from the independent
sortedness check.

Version 25 strengthens two existing entities. The public CLI writes and
applies a plan for positional `selected --path-as-root`, verifies the
`[".", "app.txt"]` source root, then omits `--path-as-root` and requires
zero-request rejection. The reader receives sorted raw JSON for
`nested/../escape` in addition to the existing absolute and leading-parent
cases.

Two isolated mutants each pass the other 22 macOS focused tests and all
474 baseline tests. The prefix-only path validator fails the embedded-parent
case, and the offline current-directory root mutant fails the positional CLI
entity. The exact unchanged reference passes 474/474 network-disabled Linux
base, 28/28 Linux new, and 23/23 macOS new. Test-only Linux exits 101 with the
expected unresolved controller diagnostic. Both patch orders, reverse checks,
formatting, and whitespace checks pass.

Prompt, reference, explanation, API, dependency set, wrapper, Dockerfile,
image, test names, and the 28/23 census remain unchanged. The new test hash is
`7de2674f9e78fb0a185ca3e36d538ca7ee2323ed6bd62a89325a440e23bc7c33`.
Version 25 supersedes the two-run version-24 batch and restarts calibration at
0/10.

## 38. Version-26 CLI no-gitignore and harness-integrity correction

The version-25 reviewer verified that `noGitignore` mismatch behavior was
covered only through the reusable controller, not the public `--from-plan`
command. It also found a fixed-delay request counter and fallback JUnit that
reported runner failures as skipped.

Version 26 strengthens the existing public CLI option entity with a
`--no-gitignore` mismatch and requires rejection before another request. The
counting proxy now acknowledges a snapshot after draining pending connections
through a command channel. Fallback JUnit reports nonzero runner outcomes as
failures under existing successful-run testcase identities and retains the
escaped runner diagnostic, avoiding both harmless skips and a synthetic
unclassified `new.run`.

The command-only `no_gitignore=false` mutant passes the other 22 macOS focused
entities and all 474 baseline tests, then fails only the strengthened CLI
entity. The unchanged reference passes 474/474 network-disabled Linux base,
28/28 Linux new, and 23/23 macOS new. Test-only network-disabled Linux exits
101 with one classified fail-to-pass entity and the unresolved-controller
diagnostic. Both patch orders, full reverse checks, formatting, shell syntax,
and whitespace checks pass.

Prompt, reference, explanation, API, dependency set, Dockerfile, test names,
and the 28/23 census remain unchanged. The new test hash is
`f22d253cee5821b686d6112f8c6a979c081349dc6676cd2ff07149d6562dfbae`.
Version 26 supersedes version 25 at 0/10 and starts a new immutable calibration
batch.

## 39. Version-27 snapshot calibration and public upload-body correction

The six version-26 `agent-runs7` implementations and six preceding
`agent-runs6` implementations all failed the same deterministic mutation
inserted after kernel `open` but before their first descriptor metadata
sample. Two candidates otherwise passed 27/28. Because the mutation is already
reflected by that first sample and by every subsequently read byte, version 27
defines the required stability interval as the file-content read rather than
the earlier open-to-first-sample interval. The synchronized mid-read
modification, size, and mode checks remain.

The latest reviewer also identified a separate public integration gap: the
valid `--from-plan` process test proved only that some request followed local
verification. Version 27 strengthens that existing entity with a local TLS
endpoint that answers the real project query, mutates the source afterward,
captures `/up`, and requires the uploaded gzip tar to contain the verified
pre-mutation bytes. A discard-and-rebuild mutant passes 474/474 regressions and
27/28 feature tests, failing only this strengthened entity.

The exact `agent-runs7/Nova_Nova_3` patch now passes 474/474 base and 28/28
new, demonstrating a participant implementation on the revised contract. The
unchanged reference passes 474/474 network-disabled Linux base, 28/28 Linux
new, 474/474 macOS base, and 23/23 macOS new. Test-only JUnit classification,
both patch orders and reverse checks, shell syntax, formatting, and the exact
image build pass.

The prompt, tests, and explanation hashes are recorded in `DESIGN.md` and
`FALSE_POSITIVE_AUDIT.md`. Version 27 supersedes the six-run version-26 batch,
starts at calibration 0/10, and carries no earlier run forward.

## 40. Version-28 verifier assembly isolation

`agent-runs8/Nova_Nova_6` added a legitimate direct dependency to both Cargo
files. The generic post-agent merge fallback reset `Cargo.toml` to the grader
copy but retained the candidate's `Cargo.lock`, so Cargo rejected the
inconsistent workspace before discovering tests. The outer verifier reported
502 failures even though correct assembly reaches a substantive 25/28 result.

Version 28 removes the grader-only Cargo feature and the entire manifest hunk
from `test.patch`. `test.sh` now selects grader entities with the checked
compiler cfg `deployment_plan_tests`, enabled only for `new`, while appending
to rather than replacing participant `RUSTFLAGS`. Base/new separation remains
474/474 and 28/28 for the exact network-disabled Linux reference, and hiding
nextest runs the same 20 controller plus 8 CLI tests through Cargo.

The exact Nova 6 replay retains `libc`, passes metadata, and exposes its three
real failures. The discard-and-rebuild mutant still passes 27/28 and fails only
the public verified-upload-body test. Both patch orders and reverse checks
pass; the test-only fallback JUnit reports a real failure with retained
diagnostics.

No prompt, solution, explanation, dependency, behavioral test, name, or test
census changed. Nevertheless, the test artifact hash changed, so version 28
supersedes version 27 at calibration 0/10 and begins a fresh immutable batch.

## 41. Version-29 explicit-project fairness correction

The version-28 CLI fixture invoked `--project explicit-project --write-plan`
without `--environment` and required success. The prompt does not grant
planning mode an exception from the existing selector validation, and pinned
ordinary `up` rejects that combination. This made one hidden expectation
unfair despite the underlying source-root test being valid.

Version 29 adds `--environment explicit-environment` to that write invocation,
matching its existing apply invocation. All path-set, offline-request,
successful-reconciliation, and changed-input-before-request assertions remain.
The prompt, reference, explanation, Dockerfile, test names, and 28/23 census
are unchanged.

The test hash is
`d48876ff5cb1c73bec776eab3fb15e7f1adccc2941fb5a71288f7b7c6b6b23d4`.
Version 29 supersedes version 28 at calibration 0/10; no previous run carries
forward.

## 42. Version-30 I/O-mechanism fairness correction

External adjudication correctly separated four fair semantic outcomes from an
unfair trigger. The Linux snapshot harness blocked only after an intercepted
libc `read(2)` call. A conforming `pread`, `mmap`, or other descriptor-backed
implementation could never reach that barrier and would time out without its
result being evaluated.

Version 30 removes the complete C/`LD_PRELOAD` child harness, the three
mid-read metadata mutation entities, and the controller atomic-replacement
race entity. It also removes the matching size/mode/modification-drift
sentence from the public description. The public valid-apply fixture remains:
it mutates the source after completed local verification, captures the real
upload request, and requires the verified old bytes in its tar body. Thus the
central verified-byte guarantee remains strongly covered without fixing one
private I/O mechanism.

The cargo fallback audit also found that successful `cargo test` runs were
misreported as one JUnit failure. The wrapper now translates every discovered
test line into JUnit and preserves actual pass/fail/ignored counts; pre-
discovery failures still receive a diagnostic failure record.

Exact validation is 474/474 macOS baseline, 23/23 macOS focused, and 24/24
network-disabled Linux focused. Cargo fallback reports 23 passing JUnit cases
with no skips. Test-only mode reports one diagnostic failure and zero skips.
Both patch orders and reversals are clean. The discard-and-rebuild mutant is
474/474 plus 22/23, while a `pread` variant, a no-mid-read-stability variant,
and exact Nova 3 replay are accepted as intended.

The version-30 prompt and test hashes are
`5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f`
and
`5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c`.
Version 30 supersedes version 29 at calibration 0/10; no earlier solver result
carries forward.

## 43. Version-31 reference pathname-identity hardening

An external verifier passed 474 baseline tests and all 24 visible Linux
focused entities, then synthesized additional snapshot/atomic-replacement
failures from the reference's missing post-read pathname-identity comparison.
The finding applies to reference robustness, not to the fairness correction in
version 30: the removed hidden tests reached their mutation only through libc
`read(2)`, while the public contract permits other snapshot mechanisms and safe
rejection.

Version 31 changes only `solution.patch` and `solution_approach.md`. On Unix,
the reference now compares device and inode across pre-open pathname metadata,
the opened descriptor, and the followed pathname after reading. A missing or
different post-read object is rejected. The prompt and test patch remain
byte-identical, so participants are not required to implement this exact
strategy.

Exact macOS validation is 474/474 baseline and 23/23 focused. Cargo fallback is
23/23 with zero failures/errors/skips, and test-only mode is one diagnostic
failure with zero skips. Removing only the new identity check still passes
23/23, proving it is not a hidden participant requirement. The
discard-and-rebuild mutant remains 474/474 plus 22/23, failing only the
captured-upload body. A temporary reference probe distinguishes same-size
replacement while accepting a stable followed symlink. Both patch orders and
reversals are clean.

The version-31 reference and explanation hashes are
`52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14`
and
`cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc`.
Version 31 supersedes version 30 at calibration 0/10; no earlier result carries
forward.

## 44. Version-32 valid-apply proxy repair

Harbor intermittently failed the valid `--from-plan` apply despite the exact
reference passing locally. Repetition reproduced a first-request
`FETCH_ERROR`: the Python CONNECT proxy's buffered reader could consume the
beginning of the TLS handshake before handing the socket to SSL.

Version 32 changes only the fixture transport in `test.patch`. CONNECT input
is unbuffered, each tunneled response closes explicitly, and Rust waits for a
parsable ready port rather than mere file existence. The upload mutation,
captured tar assertion, prompt, and reference behavior are unchanged. Repeated
Linux stress and all eight later calibration runs reached the valid-apply
fixture without the old transport failure.

## 45. Version-33 root-order clarification

Four Nova and four Orion implementations globally sorted paths and then
assumed the first entry was the selected root. Every one failed the existing
case where a valid child sorts before `"."`; four Orion runs were otherwise
23/24. The behavior was already implied, but the uniform near-pass pattern
made it an accidental wording trap.

Version 33 adds one sentence: the root entry participates in global ordering
and need not be first. It does not name the fixture or prescribe a lookup
strategy. Tests, reference behavior, wrapper, Dockerfile, and dependencies are
unchanged.

Fresh network-disabled Linux verification is 474/474 baseline and 24/24
focused. Cargo fallback is 24/24 with zero skips; test-only mode is one
diagnostic failure with zero skips. Both patch orders reverse cleanly. The
discard-and-rebuild mutant passes 474/474 plus 23/24 and is killed only by the
captured upload-body entity.

The version-33 prompt and test hashes are
`6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd`
and
`850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851`.
Version 33 starts a fresh immutable calibration batch at 0/10.
