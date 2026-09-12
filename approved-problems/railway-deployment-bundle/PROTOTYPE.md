# Cheapest-legitimate-solution prototypes

Status: the original immediate-preview prototype rejects the original seed;
the persisted/verified-plan redesign passed the disposable gates and was
subsequently packaged as a canonical problem artifact on 2026-07-26.
This file preserves prototype measurements; current hashes and authorization
live in `DESIGN.md` and `FALSE_POSITIVE_AUDIT.md`.

## Original immediate-preview prototype

### What was built

A disposable worktree at the exact pinned revision implemented the narrowest
maintainer-shaped surface:

- `DeployBundle { entries: Vec<PathBuf>, body: Vec<u8> }`;
- one `create_deploy_bundle` refactor around the existing
  `create_deploy_tarball` body;
- lexical sorting of the already-collected archive paths;
- a compatibility wrapper returning only `body` for existing MCP/new-project
  callers;
- `up --plan`, with newline output or the repository's existing JSON
  convention; and
- ordinary `up` moving the exact same `bundle.body` into
  `upload_deploy_tarball`.

The focused prototype test builds a temporary Git root with `.gitignore`,
`.railwayignore`, nested content, and `node_modules`; creates two bundles;
checks stable sorted entries; decodes the tar; and proves the reported entries
are exactly the uploaded archive entries.

The exact disposable diff is preserved in `scope-prototype.patch` with SHA-256
`d3264271630ca540b1af1f27f4f8eed69f9bff05a5d50c54959c33a8765c9a24`.
`git apply --check` passes against the untouched pinned checkout. It is a scope
probe, not a solution or authorized submission artifact.

### Measurement

| Measure | Result |
|---|---:|
| Production files touched | 2 existing files |
| Raw production additions | 90 |
| Raw production deletions | 23 |
| Strict effective production additions | 81 |
| Focused test additions | 60 raw lines in an existing module |
| New dependencies | 0 |
| New algorithms/subsystems | 0 |

The strict count includes added nonblank, non-comment Rust lines before the
`#[cfg(test)]` probe and includes structural lines. It is therefore
conservative rather than an artificially low semantic-statement count:

```bash
git diff -- src/controllers/upload.rs src/commands/up.rs |
awk '<count added nonblank, non-comment lines; stop at the added cfg(test)>'
```

The only decisions not already delegated to the pinned repository and crates
are:

1. sort the normalized archive names;
2. retain those names next to the completed body; and
3. choose a CLI/JSON presentation.

Root discovery, Git and Railway ignore semantics, hard-coded component
exclusions, traversal, link handling, metadata reads, tar headers, gzip,
progress, error propagation, and upload-body ownership are all unchanged or
delegated to existing code.

### Offline verification

All prototype commands used `rust:1.88.0-bookworm`, the read-only warmed Cargo
cache, `CARGO_NET_OFFLINE=true`, and `--network none`.

| Command | Result | Wall time |
|---|---|---:|
| `cargo check --locked` | pass | 25.27 s |
| exact focused test | 1 passed, 474 filtered | 10.50 s |
| `cargo test --locked` | 475 passed, 0 failed, 0 ignored | 0.86 s warm |
| host `cargo fmt -- --check` and `git diff --check` | pass | not material |

The official image did not include the `rustfmt` component, so formatting was
performed and checked with the host Rust 1.97 rustfmt. Compilation and every
test remained in the pinned offline image.

### Why the gate fails

The prototype is a thin projection around an existing complete collector and
archive writer. The uploaded data is already one immutable `Vec<u8>`; retaining
and serializing its entry names crosses no independent implementation
boundary. Generic `ignore`, `tar`, and `gzp` code performs essentially all
substantive work.

The implementation is also materially below the active Olympus size record:
81 strict effective lines versus the current conservative long-horizon
criterion of at least roughly 250 effective production lines. More ignore
patterns, filenames, path fixtures, or output fields would add coverage, not a
new discriminator.

A still smaller variant could decode the completed tar solely for display, but
it would not make archive ordering deterministic. The recorded implementation
already satisfies the strongest fair version of the seed—stable entry order
and one body shared with upload—and remains small.

### Rejected ways to inflate the task

- checksums, signatures, caching, incremental upload, and remote deduplication;
- canonical archive timestamps or byte-identical compression;
- snapshotting files between planning and upload;
- rejecting or containing links contrary to current behavior;
- temporary-file publication, rollback, or cleanup overlapping 3D Tiles; and
- tests that demand a private `Plan` type or forbid reuse of
  `create_deploy_tarball`.

Each would invent a new task identity or private architecture merely to add
scope.

### Verdict

Reject. The public idea is coherent and absent upstream, but the cheapest
legitimate solution is demonstrably a small wrapper. Do not create
`DESIGN.md`, `meta.md`, hidden tests, reference patches, grader images, or
calibration runs for this seed.

## Persisted and verified plan redesign

### What was built

A second disposable worktree at the same exact pinned revision implemented a
materially different lifecycle:

- `railway up --write-plan <file>` completes locally before authentication and
  writes versioned, strict, deterministic JSON;
- the plan records the selection controls and sorted normalized directory/file
  entries, including size, platform mode, and SHA-256 for every file;
- the selected plan file is excluded symmetrically, so the natural
  `--write-plan plan.json` happy path works when the plan lives inside the
  source root;
- `railway up --from-plan <file>` parses the persisted artifact, reselects with
  current Railway ignore/root semantics, and rejects selection, type, size,
  mode, or equal-size content changes before authentication;
- successful apply reads each file once, verifies that exact snapshot against
  the plan, and writes those same bytes into the tar body; and
- the existing uploader receives that completed body. Ordinary `railway up`
  retains the original archive helper and control flow.

This is source-backed verification, not a portable bundle. The plan contains
no source bytes. Canonical gzip output, signatures, caching, incremental
upload, rollback, and remote changes remain absent.

The first persisted diff remains preserved in
`verified-plan-prototype.patch`. The canonical-selector and platform
intermediate is `verified-plan-prototype-v2.patch`, SHA-256
`332e1a96e373dd193b88eb3ff4bc7584ba0b52d3d5dea73542b0951ce66e7de8`.
The last implementation prototype is `verified-plan-prototype-v3.patch`,
SHA-256
`27c7a903e1a8302c3c4efdeb725f991a4ced7bbd79d44a2e87f6f5859bc51e33`.
The historical version-8 audited reference removes only that prototype's
private self-tests and was preserved as `solution.patch`, SHA-256
`3b1b56bdafa4b977627b41e97358b9cda0ea963c67bcaa2ee72b48d13c532bcc`.
It was byte-identical to the final disposable production `git diff --binary`
and reversed cleanly against the exact pinned checkout. Version 9 subsequently
adds the trajectory-informed coherent-snapshot guard; current artifact
identities live in `DESIGN.md` and `FALSE_POSITIVE_AUDIT.md`.

### Measurement

| Measure | Result |
|---|---:|
| Production files touched | 5: 1 new controller, 4 existing integration/selector files |
| Raw production additions | 667 |
| Raw production deletions | 81 |
| Strict effective production additions | 615 |
| Focused test additions | 437 raw lines |
| New dependencies | 0 |
| Complete reference patch | 667 additions, 81 deletions |

The same conservative counter used for the first prototype counts added
nonblank, non-comment Rust lines and includes braces and error plumbing.
Reference-only self-tests were removed from the final patch; additions in the
existing production files are counted separately.

The raw count is not the verdict by itself. Unlike the 81-line prototype, the
redesign crosses independent public boundaries:

1. persisted format/version validation;
2. deterministic source selection and plan-file exclusion;
3. later-invocation selection and metadata reconciliation;
4. same-size content integrity;
5. verified snapshots becoming the exact archive bytes; and
6. local failure ordering before authentication or network effects.

The final prototype extracts the existing walk/ignore/link behavior into one
canonical selector consumed by ordinary and plan upload. It preserves the
ordinary progress indices and error flow while keeping plan-specific sorting,
metadata, digest, and output-file exclusion outside that shared seam. The
615-line count therefore no longer receives credit for a duplicated walker.

### Focused evidence

The final controller and command probes establish:

- repeated plans over an unchanged Git tree serialize identically;
- repeated fresh-process writes exclude the previous plan and remain
  byte-identical;
- `.gitignore`, `--no-gitignore`, `.railwayignore`, `.git`, and
  `node_modules` behavior is retained;
- a plan saved inside the source tree is excluded and can drive apply;
- archive entry order and every archived file digest agree exactly with the
  plan;
- equal-length byte replacement, added selection, type change, and option
  mismatch are rejected; and
- unknown JSON fields, unsupported versions, unsorted entries, and non-UTF-8
  Linux archive paths are rejected;
- workspace-prefixed and path-as-root modes match existing archive behavior;
- out-of-root file/directory links are followed while broken links fail as
  ordinary upload does;
- Unix file and directory modes are preserved and reconciled; and
- an atomic same-size pathname replacement cannot change the bytes admitted
  after verification.

An end-to-end binary probe ran:

```text
railway up --project offline-probe --write-plan plan.json --json
{"entries":2,"plan":"plan.json"}
```

After replacing `app.txt` with different bytes of the same length, with both
token environment variables removed:

```text
railway up --project offline-probe --from-plan plan.json --json
{"code":"ERROR","error":"Deployment input changed since planning: content differs for app.txt","hint":null}
exit_status=1
```

The failure occurs in the new local branch before the existing auth/client
construction and upload path.

### Verification

| Check | Result |
|---|---:|
| Host `cargo check --locked` | pass |
| Host focused probes | 7 passed; 2 additional probes are Linux-only |
| Host complete suite | 474 passed, 0 failed, 0 ignored |
| Offline official-image complete suite | 474 passed, 0 failed, 0 ignored |
| `cargo fmt -- --check` | pass |
| `git diff --check` | pass |
| Host Clippy changed-file review | no warnings in changed files |
| Offline write/rewrite and invalid apply counting probe | pass, 0 requests |
| Deferred expired-OAuth counting probe | pass, 2 requests after local verification |
| Preserved patch reproduction | exact diff match; reverse check pass |

The final official run used `rust:1.88.0-bookworm`, the warmed locked Cargo
cache read-only, `CARGO_NET_OFFLINE=true`, and Docker networking disabled. A
strict host `clippy -D warnings` remains unavailable as a whole-repository
signal because Rust 1.97 reports 35 warnings in untouched upstream files; the
ordinary Clippy pass emitted none in `up.rs`, `deploy_plan.rs`, or
`controllers/mod.rs`.

### Canonical follow-up

The prompt, feature-gated hidden suite, reference patch, explanation, and
grader image were later created and passed the repeated exact-version
false-positive audit. See `DESIGN.md` for artifact hashes and
`FALSE_POSITIVE_AUDIT.md` for the identical 474 test-only/reference base sets
and 19/21 grader counts.

Remaining work is solver calibration from exactly 0/10, a patched Windows run,
and private submission-archive similarity review when access exists. Any
artifact edit invalidates the recorded audit and restarts calibration.

### Redesign verdict

Pass the cheapest-legitimate-solution and canonical false-positive gates. The
redesign answers the original LOC objection with an honest
615-line conservative result after selector deduplication, but its stronger
case is semantic: a saved artifact governs a later deploy, verified snapshots
become the uploaded archive, and local failures precede every external effect.
The candidate is provisionally 8/10 and stronger than the nearly approved
Statig task on measured scope. The canonical bundle is ready for fresh
calibration but remains uncalibrated; private-similarity access and patched
Windows validation are still outstanding. Continue only on this persisted-plan
identity; the immediate preview remains rejected.

### Version-9 trajectory follow-up

The supplied agent runs did not change the cheapest-legitimate-solution
conclusion, but they exposed a verifier merge defect and two useful
architecture-level boundaries. The canonical reference now measures 628
strict effective production additions: 13 additional lines reject a file whose
type, size, or Unix mode changes while planning reads its opened descriptor.
The revised grader also isolates selected-root identity, adds malformed-plan
before-network coverage, and avoids counting solver-authored task tests as
regressions.

The exact reference passes 474/474 upstream tests plus 20/20 macOS and 23/23
Linux grader entities. Repaired replays leave each supplied architecture at
22/23 on Linux, but on different public requirements. See `DESIGN.md` and
`FALSE_POSITIVE_AUDIT.md` for the version-9 hashes and exact 14-mode audit.

### Version-10 agent-runs2 follow-up

The second trajectory batch changes the calibration conclusion, not the
underlying scope verdict. Both independent version-9 implementations solve all
23 old Linux entities while retaining different archive and source-walker
architectures. Version 9 was therefore too easy at the frontier and is
superseded.

The version-10 reference was 624 strict effective production additions across
six files. It adds stable descriptor modification-time comparison and complete
top-level suppression of plan-mode update/advisory/telemetry effects. The
grader replaces the easy length-changing race with a same-size in-place write,
tests linked-parent versus explicit-project root resolution through the
binary, and removes auxiliary network opt-outs from offline and invalid
processes.

The reference passes 474/474 base plus 21/21 macOS and 24/24 Linux grader
entities. Both new solvers pass 23/24, failing only the strengthened
same-size snapshot branch. The earlier near-pass passes 21/24 across that
branch and the selected-root family. This is the intended calibration shape:
substantive implementations remain close, but distinct public temporal,
identity, schema, selection, and effects boundaries prevent a single shallow
strategy from dominating.

Version 11 was superseded at 0/10 after an external reference race failure.
Version 12 adds before-open metadata and moves the final descriptor check
after digest completion. The reference passes 20 consecutive race
repetitions and exact 24/24 Linux new JUnit with no failures, errors, or skips.
The false-positive audit nevertheless retains the old reference as a
schedule-dependent survivor, so calibration remains unapproved at 0/10.

### Version-14 review prototypes

The `agent-runs3` version-13 batch produced an official observed 2/10. Before
revising the artifact, the reference and both reported passes were exercised
with public CLI probes for a persisted-option mismatch and a directly selected
Unix socket; all three handled those new boundaries. Separate Linux mtime,
size, and mode races also passed the three implementations in focused
prototype runs.

The final complete replay was more informative: both reported passes include
descriptor `ctime` in their stability signature and fail the existing atomic
replacement oracle when the watcher lands during the opened snapshot. Each
passes 27/28 version-14 entities. This exposes a timing false positive in the
old calibration without inventing a new semantic requirement.

Version 14 serializes all four payload-heavy watchers, gives each a 30-second
observation deadline, preserves mtime and mode in the size race, and preserves
mtime and size in the mode race. Isolated reference mutants that omitted final
size or final mode checks compiled and failed their respective probes. The
atomic reference passed five consecutive exact-image repetitions.

Additional prototypes established that:

- removing Unix mode-presence validation fails strict plan reading;
- silently skipping the selected socket fails public offline write;
- `agent-runs3/Nova_Nova_5` makes two premature requests on the new public
  option-mismatch apply; and
- forced runner failure emits a skipped fallback testcase whose `system-out`
  contains the XML-escaped cargo diagnostic.

The final reference passes 474/474 base, 23/23 macOS new, and 28/28
network-disabled Linux new. These are validation and mutation trials, not
version-14 solver runs; calibration remains exactly 0/10.

### Version-15 strict-reader prototypes

Two focused mutations validate the review-driven coverage without changing the
problem's difficulty mechanism. Removing version validation lets an
unsupported on-disk version through `read_deploy_plan` and fails the new reader
assertion. Removing only entry-level unknown-field denial lets an extra member
through and fails the nested-record assertion.

The historical version-13 reported pass `Nova_Nova_1` and snapshot near-pass
`Nova_Nova_2` both pass the strengthened parser entity. The final reference
again passes 474/474 network-disabled Linux base, 28/28 network-disabled Linux
new, and 23/23 macOS new. These are exact validation and false-positive trials,
not version-15 solver runs; calibration remains 0/10.

### Version-16 root and conflict prototypes

A focused mutant drops `"."` only when `pathAsRoot` is true. The existing
prefix/path-as-root entity fails with `["app.txt"]` instead of
`[".", "app.txt"]`, confirming that the new public sentence describes an
existing oracle.

The conflict assertion was rewritten to accept any unsuccessful status while
requiring each supplied long option to appear in the diagnostic. The reference,
historical reported pass, and representative near-pass all satisfy it. Exact
reference results remain 474/474 Linux base, 28/28 Linux new, and 23/23 macOS
new. These are validation trials, not version-16 solver runs.

### Version-17 prompt-minimization prototype

Deleting the repeated reader/serializer sentence changes no executable
artifact. Focused mutants that accept unsupported versions, accept unknown
entry fields, or serialize an invalid constructed plan all compile and fail the
unchanged strict parser entity. The reference remains 474/474 Linux base,
28/28 Linux new, and 23/23 macOS new. These are exact audit trials, not
version-17 solver runs.

### Version-18 fairness prototypes

The reference was changed temporarily so public `DeployPlan` no longer
implemented `Serialize`; `serialize_deploy_plan` used a private borrowed wire
DTO instead. The code compiled and the strict parser entity passed, confirming
that the revised fixture uses only the declared serializer seam.

Three isolated incorrect variants were then compiled. Removing version
validation failed the unsupported-version read assertion. Admitting absolute
paths failed the `/absolute` branch, and admitting parent components failed the
`../escape` branch. The conflict entity was inspected after revision and reads
only unsuccessful status and proxy count, so a generic diagnostic is accepted.

The restored controller is byte-identical to the other clean patch order.
Exact results are 474/474 network-disabled Linux base, 28/28
network-disabled Linux new, and 23/23 macOS new. These are validation and
compatibility trials, not version-18 solver runs.

### Version-19 verified-byte minimization prototype

The two internal recipe clauses were removed while retaining the archived-byte
outcome. A focused mutant verified buffered contents and then reopened the
pathname for tar input. It passed the complete 474-test network-disabled Linux
baseline and failed the atomic-replacement entity because the replacement
bytes entered the archive.

The restored controller is byte-identical to the clean other-order
application. The reference passes 28/28 Linux new and 23/23 macOS new. These
are exact audit trials, not version-19 solver runs.

### Version-20 snapshot-clause minimization prototype

The abstract coherent-snapshot sentence was removed while its following
concrete open/type/stability rule remained unchanged. Three isolated
prototypes removed modification, size/byte-count, or Unix-mode comparisons
from the reference snapshot reader. Each compiled and was accepted by ordinary
code paths, but its matching synchronized Linux race failed because planning
accepted the corresponding in-flight change.

The restored controller is byte-identical to the clean solution-first
application. The final reference passes 474/474 network-disabled Linux base,
28/28 network-disabled Linux new, and 23/23 macOS new. These are exact audit
trials, not version-20 solver runs; calibration remains 0/10.

### Version-21 reader and root-parity prototypes

Four isolated variants validate the reviewer corrections. Removing validation
only from `read_deploy_plan` admits a raw reversed plan and fails the existing
strict-record entity. Using the current directory for every apply fails the
linked-child case. Ignoring project-token or environment-variable targeting
independently selects the linked ancestor and fails the matching apply branch.

The restored reference is byte-identical across both patch orders. It passes
474/474 network-disabled Linux base, 28/28 network-disabled Linux new, and
23/23 macOS new. These are exact audit trials, not version-21 solver runs;
calibration starts at 0/10.

### Version-22 atomic-outcome prototype

The atomic watcher remains synchronized on `/proc/self/fd`, performs the
equal-size pathname replacement, and proves that the event occurred. The
oracle now branches on the public result: `Err` is accepted; `Ok` is decoded
and must contain only the original payload bytes.

Two independent implementations validate the boundary. The historical
legitimate `Nova_Nova_1` replay detects changed descriptor metadata and safely
rejects, passing 28/28. A focused mutant verifies buffered bytes but delegates
tar input back to the selected pathname; it succeeds with replacement bytes
and fails only the revised atomic entity after passing the other 27.

The unchanged reference passes 474/474 network-disabled Linux base, 28/28
Linux new, and 23/23 macOS new. These are exact audit trials, not version-22
solver runs; calibration starts at 0/10.
