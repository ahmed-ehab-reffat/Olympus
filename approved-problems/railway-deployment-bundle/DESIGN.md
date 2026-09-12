# DESIGN - persisted and verified Railway deployment plans

Status: the trajectory gate and version-28 verifier-assembly audit were
repeated on 2026-07-29. The participant-facing contract and all 28 Linux
behavioral entities are unchanged; the grader no longer edits `Cargo.toml`.
Version 28 is at calibration 0/10. Immutable earlier results remain history;
no run carries into the revised version.

Repository: `railwayapp/cli` at
`4d49d9845a27a0947ab903b01789eb9f854414d8`.

## Public contract and repository evidence

The original immediate preview remains rejected. The reopened hypothesis is a
two-command, source-backed plan lifecycle:

1. `railway up --write-plan <file> [path]` resolves the existing deploy root
   without authentication or network access and writes deterministic JSON.
2. The plan records a version, the root/ignore controls that affect selection,
   and sorted archive entries with normalized path, type, upload-relevant size
   and mode, and a SHA-256 digest for regular-file payloads. It contains no
   source bytes or upload body.
3. `railway up --from-plan <file> [path]` performs all local parsing,
   selection, metadata, and content checks before authentication or any remote
   request.
4. Apply rejects added, removed, renamed, type-changed, size-changed,
   mode-changed, or content-changed entries. The bytes written into the
   archive, rather than a prior metadata-only scan, must match the recorded
   digest.
5. On success, the existing uploader receives the complete verified archive
   body and never reselects files. Ordinary `railway up` behavior is unchanged.

The repository already supplies the authoritative root calculation in
`commands/up.rs::get_deploy_paths`, ignore and traversal behavior in
`controllers/upload.rs::create_deploy_tarball`, SHA-256 in the locked
dependency set, camel-case JSON conventions throughout the CLI, and an uploader
that accepts a completed `Vec<u8>`. Current `up` performs authentication and
remote target resolution before packaging, so local validation-before-network
is an additional observable sequencing boundary rather than a formatting
change.

The design is consistent with Railway's public direction toward predictable
agent and CI automation: issue #820 asks for consistent JSON, idempotent
operations, and reproducible setups. It does not request a deployment plan, so
it is adjacency rather than exact prior art.

The plan is not a portable bundle. Moving it beside an equivalent source tree
may work because entry paths are relative, but applying without source bytes is
out of scope. Canonical gzip bytes, signatures, remote caching, incremental
upload, rollback, and atomic destination publication remain excluded.

## Trajectory-informed design gate

Searches performed: `problems/README.md`, `candidates/CANDIDATES.md`, all
Railway records in this folder, 3D Tiles design/run/environment records and raw
trajectory archive, Calyx checkpoint records, RustPBX SipFlow/redesign
archives, pydicom replacement, go-mp4 sample locations, and current upstream
issue/PR/source/history searches for plan, apply, artifact, bundle, manifest,
promotion, checksum, digest, root, ignore, symlink, upload, and deploy.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | 3D Tiles run 3 (`trajectory.json`, patch, run log, evaluation) | pass | Traced every output target, introduced a publisher, validated staging, then committed candidate/backup state with rollback and cleanup. The useful general lesson is validation before irreversible effects; Railway must apply it to network sequencing, not copy filesystem publication machinery. |
| Near-pass | 3D Tiles run 2 | 26/30 | Implemented the substantive transaction correctly but returned raw `Error` instead of the repository's public `PipelineError`. Public refusal behavior and error boundaries can distinguish an almost-correct implementation without prescribing private types. |
| Broad failure | unavailable | unavailable | The remaining inspected 3D Tiles record was an external `tsx` execution failure with a substantial unverified implementation, not a behavioral broad failure. |
| Legitimate shortcut | Calyx replay and transcript prototypes | rejected intended architecture | Reconstruction from original inputs plus progress/transcript satisfied the public checkpoint behavior. Railway must accept reuse of existing walker/tar helpers and may distinguish only persisted public plan behavior. |
| Thin projection | RustPBX SipFlow audit and Railway's original 81-line prototype | rejected scope | Formatting/exposing an already-complete structured result crosses no new boundary. The redesigned plan must survive time and source changes between separate invocations; otherwise it is still the rejected preview. |

No Railway solver trajectories exist. Repository evidence and the related
records above control this prototype. The private submission archive remains
unavailable, so cross-repository plan/apply similarity is a residual stop risk.

### Reviewer-triggered revision gate — 2026-07-26

The trajectory and repository searches above were repeated before revising the
prompt or grader. `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the compact Railway records, and the available
trajectory/archive locations still contain no Railway solver run, participant
patch, legitimate pass, near-pass, or broad failure. The prior 3D Tiles, Calyx,
RustPBX, pydicom, and go-mp4 evidence remains the nearest relevant history.

The new review report is direct evaluator evidence rather than a solver
trajectory. It found that the controller tests compile against
`controllers::deploy_plan`, its public data/functions, and the existing upload
helper even though that narrow integration seam was not participant-facing. It
also found avoidable exact-message assertions and questioned whether the
`deployment_plan_` name filter visibly selected both unit and integration
tests.

The resulting revision ledger is:

| Review observation | Generalized risk | Fair public invariant or assumption | Revised oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| Hidden tests require an undeclared controller module and signatures. | A behaviorally correct implementation fails to compile because it chose another internal seam. | Declare the smallest new grader-facing module, types, and functions in a short test-assumptions paragraph. | Grader compilation plus the existing behavioral fixtures. | Retain the seam because it is the reusable unit boundary under test, but disclose it completely enough to implement; do not name existing helpers, fixtures, or call sequences. |
| Several refusal probes match reference error prose. | Correct refusal with different professional wording fails. | Each malformed or changed input must be rejected; exact prose is not public. | Assert `Err`, unsuccessful exit, archive state, and request count instead of message substrings. | Remove all new exact-message checks. Distinct fixtures still isolate version, schema, selection, content, type, size, mode, option, and path failures. |
| Unit tests inherit the module's `deployment_plan_` substring but their function names do not show it. | A runner/filter interpretation could silently under-run grader coverage. | Every grader entity must be selected explicitly in `new` mode. | Prefix every controller/CLI grader test function with `deployment_plan_`, then compare selected counts with the feature-gated inventory. | This changes only harness legibility and selection robustness, not task difficulty or tested behavior. |
| Controller tests exercise data and archive behavior below the CLI. | Private architecture could be over-prescribed. | The declared controller seam returns the public plan and verified gzipped tar; CLI tests cover offline/deferred-network sequencing. | Unit-level archive decoding plus process-level request-count probes. | Keep the split: forcing all archive invariants through a failed remote deployment would be less direct and less deterministic. No helper beyond the disclosed seam is prescribed. |

No discriminator family is added by this revision. It repairs public
self-containment and oracle robustness while preserving the existing behavioral
boundaries. Because both the prompt and grader change, all old artifact hashes
and exact-version audit conclusions become historical; the revised files must
pass the full gate again before calibration.

### Follow-up prompt-minimization gate — 2026-07-26

The required local-history, compact-record, raw-trajectory, and archive searches
were repeated before this prompt-only revision. They still contain no Railway
solver trajectory or participant patch, so the repository evidence and
discriminator families above remain controlling.

The follow-up reviewer report distinguishes interface information needed for
hidden-test compilation from existing implementation details discoverable in
the repository. `controllers::deploy_plan` and its new public types/functions
remain the minimal declared test seam. In contrast,
`upload::create_deploy_tarball` is existing code that a solver can discover,
and the public offline/before-auth behavior already determines the needed
refresh scheduling without naming `command_needs_refresh`.

Both helper-specific sentences are therefore removed from the prompt. No test,
reference behavior, discriminator, or oracle changes: ordinary-upload parity,
offline planning, reconciliation-before-auth, and deferred authentication
remain observable requirements. The deletion reduces architectural
prescription and does not admit a new behavioral shortcut. It creates a new
prompt hash, so the exact-version audit and validation record must nevertheless
be repeated before calibration.

### Public-oracle revision gate — 2026-07-27

Before changing the grader, the required history search was repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the current Railway compact records, active
trajectory folders, and the archive manifests. There is still no Railway
solver trajectory or participant patch. The representative raw 3D Tiles run 3
legitimate pass and run 2 near-pass were reread from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`; the former staged and
published through a new rollback-capable abstraction, while the latter crossed
the main transaction boundary but missed the repository's `PipelineError`
contract. Run 1 remains an external verifier-bootstrap failure, not a
behavioral broad failure. Calyx replay/transcript reconstruction and the
RustPBX thin-projection record remain the relevant shortcut evidence.

The new reviewer feedback identifies two grader-only interface constraints,
not missing public behavior:

| Review observation | Generalized risk | Fair public invariant or assumption | Revised oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| `assert_eq!` compares complete `DeployPlan` values. | A correct public plan type fails to compile because it does not implement test-convenience traits absent from the contract. | Deterministic serialization and the documented public fields are sufficient. | Compare serialized bytes and individual public observations, not whole Rust values. | Remove the redundant whole-plan equality assertion instead of adding `Debug`, `PartialEq`, and `Eq` to Test assumptions. |
| CLI tests call `build_args` and `command_needs_refresh`. | The grader prescribes internal parser and refresh-classification helpers even though the requirement is process-observable. | Conflicting public invocations must be rejected; write and invalid apply must make zero requests, while valid apply resumes authenticated flow. | Spawn the compiled CLI, assert conflict exit behavior, and use an expired isolated OAuth configuration behind a counting proxy. | Delete the internal-helper test module. Strengthen the existing process test so eager refresh is observable; retain no helper names or private call-order assertion. |

No discriminator family is added or removed. CLI conflict handling and
authentication sequencing remain tested, but through the participant-facing
binary. The plan determinism check remains byte-exact. This revision changes
the grader while leaving the public prompt and reference implementation
unchanged, so it creates a new immutable version and requires test-only,
reference, platform, patch-integrity, and false-positive gates again.

### Network-continuation minimization gate — 2026-07-27

Before revising the prompt or grader again, the required search was repeated
across `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, active trajectory
folders, and archive manifests. No Railway solver trajectory or participant
patch exists. The representative raw 3D Tiles run 3 pass, run 2 near-pass, and
run 1 external verifier failure were reread from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`. Run 3 selected a
rollback-capable publisher after tracing production seams; run 2 crossed the
same transaction boundary but missed the repository-documented
`PipelineError`; run 1 remained behaviorally unclassified because the verifier
never executed. Calyx and RustPBX still show, respectively, why legitimate
reconstruction and reuse of existing structured state must remain allowed.

The new review identifies one redundant prompt sentence and one
implementation-shaped process count:

| Review observation | Generalized risk | Fair public invariant or assumption | Revised oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| The prompt says a valid plan follows the ordinary authenticated upload/deployment flow. | Repeating the command's default continuation adds prose without a distinct boundary. | `--from-plan` remains an `up` mode; verified bytes become the upload archive, while only failure ordering needs special treatment. | Existing archive and process behavior. | Delete the sentence. No valid behavior or failure family is removed. |
| Valid apply requires at least two proxy connections. | The grader encodes one OAuth-refresh-plus-GraphQL sequence even though a conforming implementation may authenticate or transport differently. | Invalid local reconciliation makes zero requests; successful reconciliation may continue and produce observable network activity. | Require at least one counted connection only after a valid local verification. | Relax `>= 2` to `>= 1`. Drop the missing-refresh-continuation mutant as artificial because connection multiplicity is not public; retain eager pre-verification refresh as a distinct ordering violation caught by the zero-request write/invalid probes. |

This revision removes one discriminator rather than weakening any public
failure boundary. Local failure must still precede all authentication and
network activity, and verified archive bytes remain independently tested. The
prompt and grader changes create a new immutable version, so validation,
artifact hashes, and the false-positive audit must restart at calibration
0/10.

### Schema-boundary coverage gate — 2026-07-27

Before changing the grader, the mandatory searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, active trajectory
folders, and archive manifests. There is still no Railway solver trajectory or
participant patch. The raw 3D Tiles run 3 legitimate pass, run 2 near-pass, and
run 1 external execution failure were reread from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`, including their
trajectories, patches, evaluations, and run records. They continue to support
public boundary validation without private architecture constraints. Calyx
replay and RustPBX structured-state reuse remain legitimate shortcut evidence;
neither supports adding representation-specific plan checks.

Repository inspection found three public schema clauses whose current probes
were indirect, plus one runner warning:

| Review observation | Plausible shortcut | Fair public invariant | Revised black-box oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| Serialized `pathAsRoot` and `noGitignore` are exercised behaviorally but their JSON names and values are not asserted. | Preserve invocation behavior in memory while omitting or hard-coding the persisted controls. | Both controls are required top-level plan fields and must record the invocation that produced the plan. | Serialize a non-default plan and inspect the two public JSON fields and values. | Add one schema assertion to the deterministic serialization fixture; it checks documented interchange bytes, not Rust representation. |
| Generated directory records are not directly checked for zero size and absent digest. | Reuse file metadata serialization for every entry kind. | Directory size is zero and directories have no SHA-256 field. | Inspect every generated directory object, then reject directory objects with nonzero size or a digest through both serialization and reading. | Add a directory-record boundary; file digest validation does not imply the inverse directory rule. |
| Invalid paths are covered for non-UTF-8 input but not unsafe UTF-8 plan strings. | Check encoding and ordering while accepting absolute or parent-traversal archive names. | Plan paths are normalized relative archive paths. | Feed otherwise valid plans containing `/absolute` and `../escape` through the public reader and require refusal. | Add one path-safety family with two representative lexical forms; do not enumerate platforms or redundant spellings. |
| The review claims `test(~deployment_plan_)` is invalid nextest syntax. | A misunderstood filter could appear to under-run the grader. | `new` mode must select every feature-gated grader entity. | `cargo nextest help filterset` identifies `~string` as the contains matcher, and `cargo nextest list -E 'test(~deployment_plan_)'` selects all 18 pre-revision host entities. The default `test(deployment_plan_)` form selects the same set. | The warning is not a real defect. Use the equivalent default contains spelling for reviewer clarity and re-enumerate host and container entities. This is a harness-only edit, not a new discriminator. |

The three schema/path probes cover distinct format, entry-kind, and archive
identity failure families. They are supported directly by the participant
facing contract and reference validation, not by a one-off mutant. The grader
change creates a new immutable version; all test-only, reference, platform,
patch-integrity, and false-positive gates must be repeated from calibration
0/10 before approval.

### Wrapper-entity and CLI-fairness gate — 2026-07-27

Before revising the grader, the mandatory searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, active trajectory
folders, and archive manifests. There is still no Railway solver trajectory or
participant patch. The raw 3D Tiles run 3 legitimate pass, run 2 near-pass, and
run 1 external verifier failure were reread from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`, including their evaluation
records and implementation patches. The pass and near-pass still support
validation-before-effects and repository-native error boundaries; the failed
run still supplies no behavioral outcome.

Two closer harness records were also inspected. The moov ACH wrapper audit
showed that a synthetic build-failure testcase cannot be classified when the
real tests exist only after the solution. The Statig audit resolved the same
failure family by skipping a synthetic runner placeholder while preserving the
process failure. For Railway, the stronger option is available: a grader-only
compatibility adapter can expose the declared API shape at the base and panic
on use, allowing every real named controller test to execute and fail before
the solution. This adapter is disabled whenever the actual declared API
compiles and imposes no implementation behavior.

Repository inspection also reconfirmed
`controllers/project.rs::resolve_service_context` explicitly requires an
environment when an explicit project is supplied. Offline plan creation needs
neither remote selector, so the test's `--project offline-probe` without
`--environment` was an unrelated and unfair exception to existing CLI
behavior.

| Review observation | Generalized risk | Fair public invariant | Revised black-box oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| Test-only compilation emits a synthetic failing `new.run` entity. | The wrapper cannot classify a name that disappears once real tests compile. | A runner-level fallback is accounting metadata, not a behavioral grader entity. | Emit `new.run` as a skipped JUnit placeholder when the real grader cannot compile, while preserving the runner's nonzero exit status. | This follows the established Statig wrapper policy and prevents a synthetic name from entering either behavioral set. A compatibility API would prescribe or mask the seam whose absence must make the base fail. |
| The offline write fixture supplies `--project` without `--environment`. | A test can accidentally require plan mode to override an existing, documented selector validation rule. | Planning without remote selectors is offline; explicit project/environment pairing retains ordinary CLI rules. | Run the write probe from an isolated source directory with neither selector; retain paired project/environment selectors for apply probes. | Remove the unrelated selector combination rather than document a new exception. |
| Invalid apply could fail at selector preflight instead of reconciliation. | Zero requests alone may accept the wrong local failure. | The fixture must first create a valid plan, then change a planned file and reject that exact invocation locally. | Supply both project and environment, require the offline write to succeed, mutate equal-size content, invoke `--from-plan` with the same pair, require failure and zero connections. | A skipped reconciliation would now reach authentication and the proxy, isolating the public ordering rule without checking error prose or private call order. |

No deployment-plan discriminator is added. This revision repairs entity
classification and removes an unfair CLI assumption. Because the grader and
harness change, the immutable artifact version, wrapper census, platform lane,
and false-positive audit must restart at calibration 0/10.

### Reference-entity and archive-order gate — 2026-07-27

Before revising either patch, the mandatory searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the current Railway records, active trajectory
locations, and archive manifests. There is still no Railway solver trajectory
or participant patch. The raw 3D Tiles run 3 legitimate pass, run 2 near-pass,
and run 1 external verifier failure were reread from
`archive/3d-tiles-atomic-output/agent-runs.tar.gz`. Runs 2 and 3 both traced the
existing output path, introduced staging and transactional publication, and
tested their chosen public seam proactively; run 2 missed the repository's
`PipelineError` boundary, while run 3 passed. Run 1 implemented substantial
behavior but remained unclassified because its verifier bootstrap failed.
These records continue to support public behavioral boundaries rather than
reference-only implementation details.

Repository inspection supplies the decisive local evidence. Ordinary upload
collects `ignore::WalkBuilder` results and appends them directly to the tar
stream. It does not sort those results or declare an archive-stream ordering
contract. The public plan is sorted, but its role as a source-backed manifest
does not imply that tar members must occur in the same sequence. Separately,
the reference patch contains nine self-tests that do not exist with the test
patch alone. Passing reference-only entities cannot enter the wrapper's p2p or
f2p sets.

| Review observation | Generalized risk | Fair public invariant | Revised black-box oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| Nine passing tests exist only after `solution.patch`. | Reference self-tests become unclassifiable wrapper entities even though the behavioral grader is complete. | Every wrapper-visible test must be common p2p, base-failing f2p, or skipped. | Remove the redundant reference-only test modules; retain the 474 upstream entities and 21 grader entities. | Do not filter or rename private reference tests. Each removed behavior already maps to a declared grader probe, so production behavior and discriminator coverage remain unchanged. |
| Several grader assertions compare decoded tar vectors in exact order. | A conforming implementation is rejected for a stream order absent from the prompt and ordinary uploader contract. | The verified archive must contain the selected normalized paths, bytes, and metadata; only plan JSON entries are uniquely sorted. | Normalize and sort decoded path lists before equality, while continuing keyed byte, hash, mode, prefix, and snapshot checks. | This removes one reference-shaped constraint without weakening selection identity or archive-consumption coverage. Tar member order is not a new semantic boundary. |

No discriminator is added. Exact tar sequence is removed as artificial, while
path-set equality and per-path payload/metadata observations retain the
selection and verified-byte boundaries. Because `test.patch` and
`solution.patch` change, version 7 is superseded at 0/10 and every exact
validation and false-positive gate must be repeated.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Original Railway prototype retained sorted names beside a completed body. | Print an immediate preview and call it a plan. | A saved plan must govern a later, separate invocation. | Create a plan, change the source, then apply in a fresh process; the command refuses before upload. | Persistence / temporal separation | Any storage and implementation strategy passes if the documented JSON and later behavior agree. |
| RustPBX projections reused an existing structured subsystem without new semantics. | Rebuild a fresh plan during apply and ignore the saved one. | Added, removed, renamed, and metadata-changed entries must be compared with the saved plan. | Mutate each independent aspect after planning and observe refusal. | Selection reconciliation | Tests assert only public plan/apply results, not a private `Plan` pipeline. |
| Metadata-only checks are a common shallow freshness approximation. | Compare path, size, or mtime but not bytes. | Same-size content changes invalidate a plan. | Replace a file with different equal-length bytes and apply. | Content integrity | SHA-256 is already a project dependency; any correct digest/read strategy passes. |
| Validation followed by the old helper would independently reopen and rescan paths. | Validate once, then package through an unrelated selection/read pass. | The payload bytes admitted to the archive must match the saved digest and selected set. | Capture the upload body with a local HTTP seam and compare decoded entries/digests to the plan. | Archive consumption | Does not require helper names, call order, or a particular in-memory representation. |
| 3D Tiles near-pass crossed the main boundary but violated the public error contract. | Begin auth/remote resolution before discovering a local plan error. | Plan parsing and local reconciliation failures cause no network request. | Point the CLI at a counting local endpoint, apply an invalid plan, and assert zero requests. | Validation / external-effects ordering | A mock boundary observes only public I/O; multiple internal architectures pass. |
| Calyx showed that private representation constraints reject legitimate reconstruction. | Tests demand a particular manifest or collector implementation. | Only the documented strict JSON schema and behavior are public. | Round-trip/unknown-version/unknown-field cases plus behavior checks. | Format compatibility | Solvers may freely reuse the walker, tar builder, or alternate internal types. |

These public discriminator families now control the canonical hidden suite.
Filename variations within one family do not count as independent scope.

## Clause-to-test coverage

| Public requirement | Canonical observable probe | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Offline deterministic plan | Build twice from an unchanged ignored tree and compare serialized JSON | operation absent | identical sorted JSON | Existing root and ignore behavior plus CLI JSON convention |
| Strict source-backed format | Deserialize versioned JSON and reject unknown fields/version | operation absent | stable refusal | Public persisted artifact requires compatibility boundary |
| Selection freshness | Add/remove/type-change after plan | operation absent | refuse | Saved plan otherwise has no effect |
| Content freshness | Equal-size byte replacement | operation absent | refuse | Digest is necessary rather than decorative |
| Exact archive consumption | Decode the returned tar and compare paths/content digests to plan | operation absent | exact match | Existing uploader consumes the returned body without rescanning |
| Ordinary compatibility | Complete existing suite | 474 pass | all pass | Pinned upstream regression contract |

The final audit extended this matrix only where an actual survivor justified a
new boundary. The hidden suite now covers repeat plan writes, alternate Git-ignore mode,
workspace-prefixed versus path-as-root archives, followed out-of-root links,
broken links, regular-file and directory modes, non-UTF-8 identity on Linux,
deferred OAuth refresh after valid verification, and atomic replacement
between verification and archive consumption. The evidence and mutation
isolation are recorded in `FALSE_POSITIVE_AUDIT.md`.

## Environment and harness preflight

- Pristine build and existing tests: 474/474 passed with
  `cargo test --locked`.
- Offline dependency/tool availability: passed in
  `rust:1.88.0-bookworm`; the pinned lock does not build with the manifest's
  declared Rust 1.85 because `darling` 0.23 requires 1.88.
- Official-base Docker build before patch injection: passed with networking
  disabled after warming only the pinned lock.
- Determinism/shared-state hazards: plan tests use isolated temporary trees.
  Apply must consume source bytes into the returned archive before any network
  action. Wall-clock metadata and byte-identical gzip output are not public
  invariants.

## Historical version-8 artifact and design verdict

Version 8 passed the cheapest-legitimate-solution gate and its exact-version
false-positive gate. It measured 615 strict effective
production additions across five files with no new dependency. The increase
from v1 is the honest cost of extracting one selector shared with ordinary
upload and repairing authentication sequencing, not extra manifest fields or
fixtures. Persisted format, later selection reconciliation, equal-size content
verification, exact snapshot-to-archive handoff, and
validation-before-network are independent implementation boundaries.

The historical version-8 artifacts were:

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `cd51d0d25782d0eb17c50bf57c7d4bc8d45250240bb43fadab587ba0157f21d2` |
| `solution.patch` | `3b1b56bdafa4b977627b41e97358b9cda0ea963c67bcaa2ee72b48d13c532bcc` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

The test patch leaves the default build untouched and gates 19 macOS / 21
Linux grader entities behind `deployment-plan-tests`. On the pinned base,
`base` passes 474/474 and `new` exits 101 because the controller is absent; its
fallback JUnit contains one skipped synthetic `new.run` and no failure or
error. With the reference applied, macOS reports 474/474 base and 19/19 grader
tests. The final network-disabled Linux image reports 474/474 base and 21/21
grader tests, with valid JUnit XML for both modes.

The reviewer-triggered revision declares the narrow controller API required by
the grader, shortens source-selection prose to the ordinary-upload parity
rule, removes the redundant ordinary-mode sentence, and removes every
error-message substring assertion from the grader. Prefixing every grader
function with `deployment_plan_` makes nextest and cargo fallback selection
explicit. The exact reference and ten-mutant audit were rerun after those
changes.

The follow-up prompt-only revision removes the existing upload-helper and
refresh-helper disclosures. The new controller seam remains declared because
otherwise a conforming implementation cannot compile against the grader; the
ordinary-upload parity and pre-authentication requirements state the relevant
behavior without prescribing those existing internals. Test, reference,
explanation, and Docker bytes are unchanged. Host, network-disabled Linux,
patch-integrity, and all ten mutation trials were replayed against the new
prompt hash.

An earlier audit added one process-level valid-apply probe after the
missing-deferred-refresh mutant passed the complete 481-test suite. That probe
initially required an expired OAuth refresh and the ordinary remote request as
two connections after local reconciliation. Version 5 deliberately supersedes
that call-count assumption.

The 2026-07-27 public-oracle revision removes complete-plan equality and the
internal CLI-helper grader module. Controller assertions now require no
`Debug`, `PartialEq`, `Eq`, `Clone`, `Copy`, or direct `Serialize` bound on the
declared plan types beyond what the documented functions and public fields
provide. A trait-stripped compatible reference passed all 18 host grader
entities. Conflict and refresh scheduling are now checked only by spawning the
binary; isolated expired OAuth state makes premature refresh observable. The
exact-version audit killed 11 plausible mutants, including eager refresh and
missing public flag conflicts, and the unchanged reference passed the new
network-disabled 483/20 Linux lane in image
`sha256:ae2ccb14959acfdf06c771dc5409d4d1af92f89d38817e31eba4acd9b35f6669`.

The final network-continuation revision removes the redundant valid-success
sentence and requires only one or more post-verification connections. It
neither requires nor distinguishes OAuth refresh and GraphQL calls. The old
missing-refresh mutant is now classified as artificial; a valid-apply local
no-op replaces it in the 11-mutant audit. Eager pre-verification refresh
remains a public ordering failure caught by the zero-request probes. The Linux
atomic-replacement test separately proves that verified bytes, rather than a
later pathname read, become the archive payload.

The preceding schema-boundary revision directly inspects non-default
`pathAsRoot` and `noGitignore` values in serialized JSON, verifies that every
generated directory has size zero and no digest, and rejects malformed
directory metadata plus representative absolute and parent-traversal paths.
These are public persisted-format and archive-identity rules rather than Rust
representation constraints. The equivalent nextest filter spelling
`test(deployment_plan_)` selects all 21 Linux entities under the pinned
cargo-nextest 0.9.100. The exact 14-mutant audit has no actionable survivor,
and the network-disabled Linux lane passes 483/483 base and 21/21 grader tests
in image
`sha256:52d93cb5a3f83f719acad3a7b3e17e10c7882faf10443e5d157125f0d319b802`.

The wrapper-entity and CLI-fairness revision supersedes that version at 0/10.
When test-only `new` cannot compile the solution-owned controller seam, the
fallback JUnit now marks its synthetic runner testcase skipped while returning
the original failing status. The offline write process no longer supplies an
unpaired project selector. The invalid-apply process supplies both project and
environment, so a missing reconciliation would proceed into authentication
and the counting proxy rather than fail at unrelated selector validation. The
same 19 macOS and 21 Linux behavioral entities pass with the reference.
Network-disabled Linux reports 483/483 base and 21/21 new in image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.
All 14 exact-version mutants were replayed; the eager-refresh mutant made two
requests in the revised invalid-apply probe and was rejected.

The reference-entity and archive-order revision supersedes version 7 at 0/10.
Nine self-tests were removed from `solution.patch`; they duplicated grader
coverage and appeared only after the reference was applied, so the wrapper
could not classify them. This changed no production behavior. Four decoded
tar-path comparisons now normalize and sort both sides before equality. Plan
entries remain byte-deterministic and sorted, but tar-stream order is no
longer treated as public because ordinary upload exposes no such guarantee.

For the exact version-8 artifacts, the test-only and reference base lanes both
enumerate the same 474 entities on macOS and Linux. Reference `new` passes 19
entities on macOS and 21 on Linux; test-only `new` exits 101 with one skipped
synthetic `new.run`. The resulting wrapper census is 474 p2p, 21 f2p, one
skipped synthetic placeholder, and no unclassified entity. All 14 mutants
were replayed. M2 passed the full 474-test pre-existing suite before failing
the Linux atomic-snapshot probe. The unchanged Dockerfile still uses image
`sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63`.

At that point Railway remained provisionally 8/10 on candidate quality and
version 8 remained uncalibrated. The agent-run evidence below superseded that
bundle before any valid solver run was spent.

## Agent-run environment and trajectory redesign gate — 2026-07-27

This gate supersedes the statement above that no Railway solver trajectories
exist. The operator supplied two raw Nova runs under `agent-runs/`. Before
revising any grader artifact, the mandatory searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, this problem's compact records, the active and
archived related-problem records named earlier, both Railway trajectories,
both solution patches, both run logs, both JUnit pairs, and both evaluation
records. `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were reread in full.

### Verifier failure classification

Neither official post-agent result is behavioral evidence. In both runs the
wrapper first failed a three-way merge of `test.patch`, then its fallback
reset every test-patch-owned path to the pinned base before applying the test
patch. Both participant patches correctly added `pub mod deploy_plan;` to
`src/controllers/mod.rs`; the test patch also edited that file only to declare
its private grader module. The fallback retained the grader declaration while
deleting the participant's public module export. Compilation then failed on
`controllers::deploy_plan`, no real test ran, and the reported 474 baseline
plus 21 new failures were synthetic “missing from XML” records. This is a
deterministic test-injection overlap, not an agent mistake.

The two patches were therefore replayed diagnostically in disposable
containers from the exact wrapper image with an additive merge that preserved
both declarations. This replay is not calibration and cannot carry into a
revised problem version:

| Run | Official result | Corrected diagnostic replay | Behavioral classification |
|---|---|---|---|
| `Nova_Nova_1` | verifier compile failure before tests | 21/21 grader entities pass | legitimate solve of version 8 |
| `Nova_Nova_2` | verifier compile failure before tests | 14/21 pass | near-pass; the seven failures reduce primarily to one generalized root-directory omission |

The harness repair is to inject the feature-gated grader from an unrelated
existing crate file and import `crate::controllers::{deploy_plan, upload}`
there. The test patch must no longer modify `src/controllers/mod.rs`, because
that is the natural participant-owned export point disclosed by the prompt.
The repaired patches must be replayed through both ordinary application and
the wrapper's fallback shape before any revised run is spent.

Both trajectories also add reasonable task-specific self-tests. The wrapper
previously rejected equivalent reference-only tests because entities that
exist only after a solution patch belong to neither the pre-existing
regression set nor the grader fail-to-pass set. Direct nextest enumeration of
Run 1 finds ten `controllers::deploy_plan::tests::*` entities and one
`up_plan_modes_parse_and_conflict` entity; Run 2 has the same two task-owned
name families. None of the pinned 474 upstream tests contains `deploy_plan`,
`deployment_plan`, or `up_plan`. Base mode must therefore exclude those three
task-owned substrings in both nextest and cargo fallbacks. This changes no
participant behavior and preserves all 474 regressions while allowing a solver
to add relevant self-tests without generating unclassifiable verifier
entities.

### Representative raw trajectory evidence

Both trajectories were read as action sequences rather than relying only on
their final patches. Each solver traced `commands/up.rs`, the ordinary upload
walker/tar path, top-level token refresh, telemetry, and auto-update behavior
before implementing. Both independently chose a strict JSON plan, a
pre-authentication CLI branch, descriptor-backed file buffers, parser-level
flag conflicts, plan-file self-exclusion, and dead-proxy process checks.

Run 1 extracted one shared collector used by ordinary upload, planning, and
verified apply. Its source records held metadata and file bytes, and its tar
builder consumed those records directly. It proactively added broken-link,
Unix-socket, non-UTF-8, and telemetry tests and repaired a telemetry request it
noticed after its first implementation. That architecture legitimately passes
all existing version-8 oracles.

Run 2 built an independent plan scanner and explicit archive builder. It also
buffered verified file bytes and deferred the command's remote work, but it
discarded the walk entry whose relative path was empty. Consequently it
omitted the selected root directory (`"."` in path-as-root mode or the service
prefix otherwise). Four parity assertions and three schema fixtures then
failed for that same defect; two schema tests panicked while indexing assumed
generated entries instead of reporting an isolated semantic failure. This is
one useful near-pass boundary, not seven varied discriminators.

Both implementations take file metadata before `read_to_end` and can accept a
file that changes while plan bytes are being captured. Run 1 derives the plan
size from whatever bytes the read returned, while retaining mode metadata from
before the read; run 2 compares the returned length with the initially opened
length but has no general before/after stability check. A plan can therefore
record a digest and metadata that never described one stable source snapshot.
This is a repository-supported extension of the existing descriptor/snapshot
boundary, not a new archive format or private implementation demand.

### Revised discriminator ledger

| Evidence | Generalized shortcut or defect | Fair participant-facing invariant | Revised oracle | Independent boundary and decision |
|---|---|---|---|---|
| Both official runs lost `pub mod deploy_plan` during fallback merge. | A grader-owned edit overlaps the only natural participant export point. | A correct patch must be testable without a merge strategy deleting participant code. | Apply each supplied participant patch, then apply the revised test patch and enumerate the real entities. | Harness integrity, not a discriminator. Move grader injection away from `controllers/mod.rs`; do not blame or score either run for the old result. |
| Both participant patches add task-specific self-tests that version 8 base mode executes. | Correct solver-owned tests appear only post-agent and become unclassifiable wrapper entities. | The regression census is the exact pinned upstream suite; participant self-tests must not create a scoring failure. | Base mode excludes task-owned `deploy_plan`, `deployment_plan`, and `up_plan` names; nextest proves zero pinned tests and all supplied self-tests match that exclusion. | Harness integrity, not a discriminator. Preserve all 474 upstream entities and do not enumerate private test names individually. |
| Run 2 omitted the empty relative walk entry. | Treat the selected source root as traversal scaffolding instead of an uploaded directory entry. | Planning and verified archive selection equal ordinary upload, including the selected root entry. | One dedicated root/prefix assertion with explicit expected paths; all unrelated malformed-record fixtures construct their own records and never index an assumed generated layout. | Source identity. Retain one strong probe and remove accidental multiplicity/panics. |
| Run 1 passed all existing probes after tracing each documented clause. | Metadata and content can be sampled at different instants during plan creation. | Each regular-file plan record must describe one coherent descriptor-backed snapshot; if relevant file metadata changes while its content is being read, planning refuses instead of publishing an internally inconsistent record. | On Linux, observe the opened descriptor for a large file, change the same inode during the read, and require `create_deploy_plan` to fail. The watcher must prove the mutation occurred. | Snapshot formation. Add: it is temporally distinct from later apply reconciliation and later verified archive consumption. |
| Current process test covers only a validly parsed plan whose content changed. | Defer authentication for content comparison but still refresh before reading or validating the plan document. | Every parse and reconciliation failure completes before authentication or network access. | Invoke public `--from-plan` with malformed JSON, expired isolated OAuth state, and a counting proxy; require failure and zero connections. | Format/effect ordering composition. Add one process probe; do not enumerate malformed JSON variants. |
| The current strict-schema tests assume the generated plan has particular indices and a directory. | A single selection defect cascades into panics and appears to cover multiple families. | Serializer and reader reject malformed public records independently of filesystem selection. | Build malformed JSON or mutate entries found by kind with an explicit assertion that the fixture exists; never use numeric indices dependent on root inclusion. | Oracle quality. Refactor only; no new requirement. |
| More ignore filenames, traversal spellings, exact tar order, exact error prose, or proxy call counts could increase the raw failure count. | Inflate difficulty by repeating a known family or pinning one implementation. | Difficulty must come from independent public state transitions and observable effects. | Existing representative fixtures remain controlling. | Reject. These additions would not improve discriminator diversity. |

The revised semantic families are persisted-format validity, ordinary-source
identity, temporal reconciliation, content integrity, coherent plan-snapshot
formation, exact verified-snapshot archive consumption, and local
validation-before-external-effects. Root inclusion is counted once.
Malformed-plan sequencing composes two public boundaries but contributes a
distinct process-level shortcut oracle. No requirement is added for exact tar
member order, canonical gzip bytes, atomic plan publication, mtime fields,
helper names, or a specific collector architecture.

This gate authorizes revision of `meta.md`, `test.patch`, and the reference
implementation. Those edits create canonical version 9 at calibration 0/10.
Before version 9 can be approved for any run, the exact reference lanes,
test-patch merge/fallback replays, wrapper census, platform probe, and
false-positive audit must all be repeated and recorded with new immutable
artifact identities.

## Canonical version-9 validation and verdict

All checks authorized by the trajectory gate were repeated for the exact
version-9 artifacts:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `bc682a86ed12764b43e6251586a62e4dd8366ad126c1828448aadb9f776c50c1` |
| `test.patch` | `26a8751b9ddf9abccf1975e0cde75db436807914d87482308ade93b2de56b741` |
| `solution.patch` | `be61c9cad6bb3c1c478ed1141d84e1418e63c7b65783b3fb78e4007137cc5c59` |
| `solution_approach.md` | `70ee500b728e09d24aae9655da168f324dc37b0d0cf813bb8042141ba9a30302` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently, together in either order, and reverse-check
cleanly. Test-only Linux runs 474/474 upstream regressions; its expected
missing-solution `new` failure produces one skipped synthetic testcase and no
unclassified entity. The reference passes 474/474 base plus 20/20 macOS and
23/23 Linux grader entities. The authoritative Linux wrapper census is 474
p2p, 23 f2p, one skipped synthetic placeholder, and zero unclassified
entities.

The supplied patches now apply without touching the grader injection point.
Under the revised exact harness, Run 1 passes 474/474 base and 22/23 new,
failing only coherent plan-snapshot formation. Run 2 passes 474/474 base and
22/23 new, failing only selected-root identity. Their 11 and 13 task-owned
self-tests respectively are excluded from baseline accounting without
excluding any pinned upstream test. These are intentionally two independent
near-pass boundaries instead of an environment failure or a seven-test cascade
from one defect.

The exact version-9 false-positive audit exercised 14 plausible modes,
including both supplied architectures, and found no actionable survivor. The
redesign measures 628 strict effective production additions across five files
with no new dependency. Railway remains provisionally 8/10 on candidate
quality and is approved to begin a fresh immutable calibration batch, but it
is not submission-ready: version-9 calibration is exactly 0/10. No official
version-8 result or diagnostic replay carries forward. A patched Windows run
and private submission-similarity access remain review risks.

## Agent-runs2 trajectory redesign gate — 2026-07-27

Version 9 is superseded after two legitimate complete solves. Before changing
the prompt, grader, or reference, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread in full. Searches were repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the compact Railway records, related persisted and
atomic-output problem records, the earlier `agent-runs/` evidence, and every
file in both new `agent-runs2/` directories. Both raw trajectory step streams,
participant patches, workspace diffs, run logs, baseline/new JUnit, and
evaluations were inspected.

### Run classification

| Run | Environment classification | Behavioral result | Trajectory role |
|---|---|---:|---|
| `agent-runs2/Nova_Nova_1` | no meaningful blocker; missing `rg`, one broad `find` warning, and wrapper merge recovery were non-blocking | 474/474 base and 23/23 new | legitimate pass |
| `agent-runs2/Nova_Nova_2` | no meaningful blocker; the same minor tooling limitations were recovered locally | 474/474 base and 23/23 new | legitimate pass |
| Earlier `agent-runs/Nova_Nova_2` corrected replay | official result invalid because of the old module-export merge defect | 22/23 under version 9, isolated selected-root miss | representative near-pass |
| Broad behavioral failure | unavailable after excluding the old synthetic compile failures | — | recorded as unavailable rather than substituting environment noise |

The 2/2 legitimate frontier solve signal triggers the mandatory local harden
rule. These results belong only to immutable version 9. Once any artifact is
revised, they remain trajectory evidence but version 10 restarts at 0/10.

### Representative solver architecture

Both solvers first traced `commands/up.rs`, authentication/refresh dispatch,
the ordinary tar builder, configuration-root discovery, telemetry, update
checks, and advisory paths. Both then created a strict serde-backed controller,
branched plan modes before authentication, buffered file bytes from the
verified descriptor, built tar entries from those buffers, and added
solver-owned tests. Both independently noticed that token-refresh suppression
alone was insufficient and disabled updater, telemetry, and advisory effects
for plan invocations. Their implementations are substantive and structurally
independent:

- Run 1 uses `flate2`, retains filesystem metadata beside verified payloads,
  drops payloads after each planning digest, and resolves a local source root
  through a custom helper.
- Run 2 uses the existing parallel gzip stack, stores only plan entries plus
  payload buffers, retains all payloads during plan creation, and delegates
  offline root discovery to `get_closest_linked_project_directory`.

Neither implementation shares the reference selector extraction, but that is
legitimate because their observed source-selection behavior satisfies all
version-9 oracles. No test may require the reference collector architecture.

The recurring substantive shortcut is in-read stability: both compare only
descriptor type, byte length, and Unix permission bits before and after
`read_to_end`. An in-place same-length rewrite changes modification metadata
without changing those three values, so each implementation can publish a
digest over bytes read while the file was changing. This is the same public
coherent-snapshot boundary as version 9, but the old probe changed length and
therefore exercised only its easiest branch.

Run 1 also makes source-root resolution independent of the parsed explicit
project selector. If invoked below a linked parent with `--project`, it still
plans the linked parent, while ordinary `up` uses the current directory when
an explicit project is supplied. Run 2 and the reference take the latter path.
This is a CLI source-identity boundary, not another ignore fixture.

Finally, the current process harness sets `CI`, `DO_NOT_TRACK`,
`RAILWAY_NO_AUTO_UPDATE`, and `RAILWAY_NO_TELEMETRY` on every invocation.
That isolates OAuth ordering but weakens the public unconditional no-request
claim by disabling the auxiliary request sources before the implementation is
tested. Both new solvers proactively handle those sources; the version-9
reference does not. The next grader must test offline success and local
failure with normal auxiliary-network defaults, while retaining opt-outs only
for the valid-apply continuation oracle so a background request cannot satisfy
that test.

### Version-10 discriminator ledger

| Evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary and anti-overfitting decision |
|---|---|---|---|---|
| Both complete solves compare only type, size, and mode around file reads. | Treat unchanged length and permissions as proof that a descriptor was stable. | A regular-file record describes one coherent descriptor-backed read; if modification metadata changes during that read, planning refuses even when length and mode are unchanged. | On Linux, observe the opened descriptor for a large file, overwrite bytes in place without changing length or mode, prove the write and metadata change occurred, and require planning to fail. | Snapshot formation. Replace the truncation probe rather than add a second race fixture. |
| Run 1's custom root helper ignores explicit `--project` in a linked child invocation; Run 2 mirrors ordinary resolution. | Reuse linked-root discovery without accounting for the selector that disables the link-derived source base. | Offline planning resolves the local source root exactly as ordinary `up`; an explicit project makes the current directory the local base and does not require an environment merely to write and exit. | Create an isolated linked parent, invoke write-plan from a child once normally and once with `--project`, and inspect the two public manifests. | CLI source identity. One process entity covers linked-parent and explicit-project branches; do not expose helper names. |
| Version-9 process helpers disable every auxiliary request source; both new solvers nevertheless suppress them. | Pass zero-request tests by relying on the fixture's opt-out environment rather than owning the command's full effect boundary. | Write and every invalid apply are request-free under normal defaults, including auxiliary background activity. | Run successful write, malformed apply, and changed-source apply behind a counting proxy without CI, tracking, telemetry, or updater opt-outs; require zero connections. Keep opt-outs for valid apply. | Effect isolation. Strengthen existing entities instead of adding multiple network-count variants. |
| Both solutions write the final plan pathname directly; the repository contains atomic config writers. | Truncate the previous plan during publication. | No public atomic-publication or rollback guarantee exists, and atomic destination work would repeat the separate 3D Tiles problem. | None. | Reject. Do not add crash, disk-full, temporary-name, or rollback requirements merely because both solvers share this implementation. |
| Both solutions accept directory `sha256: null`, drive-like path spellings on Unix, and other untested strict-schema variants. | Interpret one wording edge permissively. | Existing representative unknown-field, path, digest, ordering, and directory-shape checks already define the schema boundary. | Existing oracles remain. | Reject additional spelling/null fixtures unless a distinct semantic boundary emerges. |
| Both solutions duplicate the walker while the reference extracts it. | Choose an independent implementation instead of the reference seam. | Behavioral equality with ordinary source selection, not shared code. | Existing selector, ignore, link, root, and payload comparisons plus the new CLI root-resolution entity. | Accept independent walkers. Never require a private collector or second-scan implementation shape. |

The resulting suite remains varied across persisted-format validity, CLI source
identity, ordinary selector behavior, in-read snapshot coherence, later
reconciliation, verified archive consumption, and external-effect ordering.
The changes deliberately strengthen three independent boundaries rather than
adding filenames, error strings, tar order, proxy counts, or another manifest
field. This gate authorizes version-10 artifact work. Before version 10 can be
calibrated, the reference, both supplied passing patches, the earlier
near-pass, wrapper accounting, platform lanes, and an exact-version
false-positive audit must all be replayed and recorded.

## Canonical version-10 validation and verdict

All gates authorized above were repeated for the exact version-10 artifacts:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `96ff6ae0eb5c125f0b643a94f67e901e4d25c27488d8b314b5421bb082c93e9b` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c` |
| `solution_approach.md` | `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently and together in either order, reverse-check
cleanly, reproduce the formatted prototype, and pass applied-tree whitespace
checks. The reference passes 474/474 base plus 21/21 macOS and 24/24 Linux
grader entities. Test-only Linux runs 474/474 base and exits 101 in `new`; its
fallback JUnit contains one skipped synthetic testcase and no unclassified
behavior.

The first Linux execution mounted source read-only. Its 474 base entities
passed, but nextest then exited 110 trying to write JUnit under `/src/target`,
so the chained grader never ran. The authoritative rerun made only the result
destination writable and passed 24/24 with networking disabled. This is
recorded as a verifier-mount issue, not a product or participant failure.

An initial stability prototype compared ctime and mtime. Atomic replacement
of a pathname can change ctime on the unlinked but still-open old inode even
though its bytes remain coherent. That overbroad check failed the existing
verified-descriptor oracle and was removed before canonicalization. The final
probe proves an in-place write changed mtime while size and mode remained
equal; the reference rejects it and still archives the old open-descriptor
bytes after atomic pathname replacement.

Exact network-disabled replays produce:

- `agent-runs2/Nova_Nova_1`: 474/474 base and 23/24 new, failing only
  same-size in-read snapshot modification;
- `agent-runs2/Nova_Nova_2`: 474/474 base and 23/24 new, failing only the
  same coherent-snapshot branch;
- earlier `agent-runs/Nova_Nova_2`: 474/474 base and 21/24 new, with the
  additional two failures both caused by its already-known selected-root
  omission.

The two new implementations pass the linked-parent/explicit-project and
unconditional-offline process probes; those tests remain valuable independent
families for future solutions even though the observed solvers handled them.
The exact audit executes isolated digest, reopen, no-op, permissive-schema,
ignore-option, and updater-only mutants plus the three participant
architectures. Each is rejected by a public boundary, and no actionable
survivor remains. The reference is 624 strict effective production additions
across six files with no new dependency.

Version 10 was approved to begin calibration, not to submit, but no run was
spent. It was superseded by the prompt-only version-11 cleanup below. The two
version-9 solves and every diagnostic replay remain design evidence only and
cannot be counted or carried forward.

## Canonical version-11 prompt-only review

Reviewer feedback identified one explanatory sentence in `meta.md` that
restated the preceding requirement to use ordinary upload source selection and
local source-root resolution. `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread before the edit. The version-10
trajectory gate and discriminator ledger were rechecked against the shorter
text: the public ordinary-upload parity requirement remains explicit, so the
linked-parent/explicit-project black-box oracle still tests that public
behavior without exposing a private helper or prescribing an implementation.
No hidden test, reference behavior, dependency, or environment artifact
changed.

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `55df6607e9a306939ec5a6b51b7da24aa8c87bcc32d82b4f6531d9460665d577` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c` |
| `solution_approach.md` | `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

The exact false-positive audit was repeated for this prompt hash. Every
participant-facing requirement retains a behavioral oracle, the previously
executed mutants and participant architectures remain applicable because the
executable artifacts are byte-identical, and the removed sentence did not
authorize any distinct discriminator. Version 11 was the then-current
immutable bundle at calibration 0/10 and was not submission-ready.

## Version-12 verifier-stability gate

Before revising `test.patch`, the mandatory design and calibration protocols,
the version-10 trajectory gate, and the exact version-11 audit were reread.
The verifier then reported that the reference intermittently failed
`deployment_plan_creation_rejects_a_file_changed_during_snapshot`. Five exact
replays in the pinned network-disabled Linux image passed, confirming that the
failure is scheduling-dependent rather than a deterministic reference defect.

The current watcher treats observing the descriptor in `/proc/self/fd` as
proof that bytes are already being read. That is too weak: it may overwrite
the file between `open` and the reference's initial descriptor metadata read.
In that schedule the implementation legitimately observes one stable
post-write snapshot, so the test's final error assertion can fail even though
the file was open during the write.

| Evidence | Generalized oracle defect | Public invariant | Revised black-box synchronization | Anti-overfitting decision |
|---|---|---|---|---|
| Reference failure in one verifier environment but five passes in the exact local Linux image. | Descriptor existence is mistaken for proof that the implementation has already captured its initial metadata. | Planning rejects a metadata-changing in-place write after the descriptor opens and before the descriptor-backed snapshot is complete. | Preserve the public `/proc/self/fd` open observation, but make the reference compare metadata captured immediately before `open`, immediately after it, and after bytes are read and digested. A write triggered by the observed open must differ from at least one adjacent observation. | Keep the same file, mutation, metadata assertions, participant API, and failure family. Do not add sleeps, expose a hook, or prescribe the rest of the snapshot architecture. |

Polling `/proc/self/fdinfo` for a positive partial offset was prototyped and
rejected before canonicalization: on the exact image the read could advance to
EOF between observer polls, causing the watcher to miss the mutation entirely.
The open-to-completion interval is deterministic for the reference and is the
smallest public clarification that closes the observed early-write schedule.

This is a reliability correction to an existing discriminator, not a new
failure family. It authorizes the interval wording and adjacent-metadata
reference correction described above; the hidden scenario itself remains
unchanged. Because the prompt and reference change, the resulting version 12
must receive new artifact hashes, reference validation with no
failures/errors/skips in `./test.sh new`, participant replay, and a repeated
exact false-positive audit before calibration can begin.

The exact audit also prototyped a second branch that delayed the write by
10 ms, intended to isolate a pre-open-only metadata implementation. The
executable mutant that removed every final descriptor check failed both the
existing immediate branch and the delayed prototype. The extra branch
therefore contributed no distinct discriminator and was removed before
canonicalization under the anti-duplication rule. Version 12 keeps the
original single hidden entity unchanged. Its reliability correction belongs
in the public interval wording and reference: capture metadata immediately
before opening, retain the initial descriptor metadata, compute the digest,
then take the final descriptor metadata before completing the snapshot.

## Canonical version-12 validation and verdict

Version 12 has these exact identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `210c0849e50feb2ddb9ece2c63f80a38c026f5a9376c4c45fc2df9d92ec7f7be` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `be78e955fb5ccaf40357b6921c4253f32b00ec2d6b74d1cda6a3f8ec38fd2340` |
| `solution_approach.md` | `05ef56f662047b1c1f5f200540cd44d274bc17f14a7d804e46125591c96cf8e9` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The hidden test is byte-identical to version 11. The reference now captures
pathname metadata before opening and takes its final descriptor metadata only
after digesting the verified bytes. It measures 630 strict effective
production additions across six files with no new dependency.

Validation results:

- the snapshot test passed 20 consecutive exact-image repetitions;
- network-disabled Linux `./test.sh new` produced JUnit with 24 testcases,
  zero failures, zero errors, and no skipped elements;
- network-disabled Linux `./test.sh base` produced 474/474 with zero skipped;
- macOS `new` produced 21/21;
- both patches apply independently and together, reverse-check, format, and
  pass applied-tree whitespace validation.

The subsequent cache-backed stress relink exhausted a disposable 8.9 GiB
target directory and left Docker Desktop's backend stuck. The canonical
24/24 JUnit had already been published. Removing only that task-owned cache
and restarting the backend restored the image; this is an environment event,
not a reference failure.

The exact false-positive audit is not closed. The version-11 reference—initial
and final descriptor metadata both taken before digesting—passed five local
Linux repetitions but failed the external verifier's same hidden entity. Under
the clarified version-12 interval it is a plausible incorrect implementation
whose classification depends on scheduling. A pre-open-only mutant was
rejected by the existing immediate entity, and the delayed prototype added no
distinct discrimination, so it was removed. Version 12 satisfies the
zero-failure/error/skip reference gate but is not approved for calibration or
submission until the timing-dependent survivor is addressed by a fair,
implementation-neutral oracle or the discriminator is withdrawn.

## Canonical version-13 prompt-only gate

Before changing the prompt, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. Local history was searched in
`problems/README.md`, `candidates/CANDIDATES.md`, this problem's compact
records, and both supplied trajectory batches. The representative legitimate
pass was `agent-runs2/Nova_Nova_1`: it traced the upload and eager-refresh
flows, built strict serde-backed validation, retained descriptor-read bytes
for archiving, and proactively exercised deterministic rewrite and dead-proxy
offline behavior. The representative near-pass was
`agent-runs/Nova_Nova_2`, whose repaired replay missed the coherent-snapshot
and selected-root families while implementing strict parsing and
serialization. No representative broad behavioral failure exists; the two
earlier nominal failures were verifier merge defects and are recorded as
environment evidence rather than solver mistakes.

The requested deletion removes only the final sentence saying that reading and
serialization enforce the schema, version, ordering, metadata, and digest
rules. Each behavior remains stated earlier in the public schema paragraph:
the plan is strict and versioned; entries are uniquely sorted; directory and
file metadata rules are explicit; and unknown fields, unsupported versions,
invalid paths, malformed records, duplicates, and unsorted entries must be
rejected. The public API signatures remain stated in Test assumptions.

| Observed evidence | Generalized shortcut | Retained public invariant | Existing black-box oracle | Decision |
|---|---|---|---|---|
| Both legitimate version-9 solvers implemented strict parsing and serialization from the schema paragraph, independent of the repeated final sentence. | Treat Test assumptions as the only source of behavioral requirements. | Strict, versioned, uniquely ordered plan records with the stated metadata and digest constraints. | Existing parser, serialization, directory-record, digest, ordering, and unsafe-path entities. | No discriminator or test change; deleting the repetition does not weaken the contract. |
| The repaired near-pass failures were snapshot and root-resolution misses, not schema ambiguity. | Fix one temporal or root boundary while leaving strict plan handling intact. | Snapshot coherence and ordinary local-root parity remain separate public families. | Existing snapshot and public CLI root probes. | No new schema fixture; it would duplicate existing discrimination. |
| The old reference remains timing-sensitive under one schedule. | Take both descriptor metadata observations before digest completion. | A descriptor-backed record must remain coherent through snapshot completion. | Existing same-size in-place mutation entity, currently recorded as schedule-sensitive. | The prompt cleanup neither resolves nor worsens this open survivor; calibration remains blocked. |

Version 13 changes only `meta.md`. Its identities are:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `a820a076e28b7a9129a40d47a670ebb68a5ce4a12699eccaf007d3fc0989aa22` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `be78e955fb5ccaf40357b6921c4253f32b00ec2d6b74d1cda6a3f8ec38fd2340` |
| `solution_approach.md` | `05ef56f662047b1c1f5f200540cd44d274bc17f14a7d804e46125591c96cf8e9` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

The v12 executable validation remains directly applicable because the tests,
reference, explanation, base, and image are byte-identical. The exact
false-positive mapping was repeated for the shorter prompt and retains the
same timing-dependent survivor. Version 13 therefore starts at 0/10 and is not
approved for calibration or submission.

## Agent-runs3 calibration gate and requested revision

Before revising hidden tests, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. Repository and problem history was
searched in `problems/README.md`, `candidates/CANDIDATES.md`, the compact
Railway records, and all ten raw `agent-runs3` bundles.

The immutable version-13 calibration result is 2/10: `Nova_Nova_1` and
`Orion_Nova` are legitimate passes; all ten runs preserve the 474-test
baseline. Seven near-passes fail only the open-to-first-metadata snapshot
boundary. `Nova_Nova_5` fails only the two pre-network apply probes, and
`Nova_Nova_4` is the widest behavioral failure available at 21/24, combining
those two pre-network misses with the snapshot miss. No broader behavioral
failure exists in this batch.

Representative raw trajectory review:

- `Nova_Nova_1` is a legitimate pass. It modifies the upload collector,
  command, main startup classification, telemetry, and a dedicated controller;
  retains descriptor-read bytes for archive construction; samples metadata
  before opening and after digest completion; and proactively runs focused,
  full-suite, deterministic-rewrite, and dead-proxy checks.
- `Nova_Nova_2` is the representative near-pass. It builds the same public
  lifecycle and strict format, but samples its first stability metadata only
  after opening. The immediately triggered same-inode rewrite can therefore
  complete before that sample; every other new entity passes.
- `Nova_Nova_4` is the representative widest failure. It implements a
  substantive verified archive and local apply preflight, but suppresses
  telemetry only for write mode while other top-level auxiliary work can still
  run for malformed or mismatched apply. It also uses the post-open-only
  metadata pattern.

The requested revision is constrained to reviewer-supported public boundaries
and harness diagnostics. It must not manufacture new difficulty after the
in-band 2/10 result.

| Review evidence | Plausible shortcut or defect | Fair public invariant | Planned black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| “Any option” is broader than the two controls persisted by the schema. | Compare an arbitrary collection of unrelated CLI flags. | Apply must match the persisted `pathAsRoot` and `noGitignore` values. | Retain the existing mismatch behavior and add a public CLI pre-network mismatch path. | Narrow the prompt; do not invent more persisted options. |
| Exact module/type/function names prescribe one architecture. | Add compatibility symbols solely for hidden compilation. | Planning, strict plan I/O, reconciliation, and verified archive construction must be reusable without authentication or network effects. | Prefer public CLI behavior for new probes and describe reuse behaviorally. | Remove names and the “Test assumptions” heading. Existing controller-heavy coverage requires separate fairness review; do not add more name-coupled probes. |
| Both Linux watcher loops can wait forever when no descriptor is observed. | A scheduler miss appears as a hung grader rather than a classified test. | A test must either trigger its public event or fail promptly with a useful diagnostic. | Bound watcher observation and report the untriggered condition. | Harness reliability only; no sleep threshold becomes participant behavior. |
| Unsupported selected filesystem objects are public but untested. | Treat every non-directory walk entry as a regular file or silently skip it. | Directly selected sockets/FIFOs/devices are unsupported and fail clearly. | Exercise one portable Unix socket input through offline write mode. | One object class is enough; FIFO/socket/device permutations are the same semantic family. |
| Option mismatch is tested only below the CLI. | Reconcile invocation controls after eager auth or auxiliary requests. | `pathAsRoot`/`noGitignore` mismatch must fail before every request. | Write a plan, alter a persisted option, then apply through the public CLI under the counting proxy. | Distinct command-sequencing boundary; no error-string pinning. |
| The current synchronized mutation preserves size and mode. | Check only modification time. | Descriptor-backed snapshot coherence includes observable size and mode stability as well as modification metadata. | Prototype synchronized size and mode mutations and replay both legitimate passes before inclusion. | Do not add a pathname type-replacement race: atomic pathname replacement is explicitly allowed to preserve the already-open verified snapshot, and an opened regular inode cannot change its file type. |
| Fallback JUnit collapses all runner failures into an unexplained skip. | Lose compile/link/assertion diagnostics when per-test JUnit is absent. | The wrapper must preserve the failed command’s diagnostic output. | Capture combined runner output and XML-escape it into fallback system output. | Reporting-only change; it must not reclassify filtered baseline tests as new skips. |
| Unix plans may omit mode during strict parsing in the reference. | Defer malformed-plan rejection until later reconciliation. | Every Unix plan entry records permission bits and malformed plans fail at read/serialization time. | Add the missing `validate_plan` presence check and replay strict-plan coverage. | Reference conformance fix, not a new hidden representation rule. |

## Canonical version-14 revision and exact audit

The planned reviewer revisions were prototyped before canonicalization against
the reference and both official version-13 passing patches. Public CLI option
mismatch and unsupported-socket probes passed all three implementations.
Synchronized mtime, size, and mode races passed the reference and both
participant implementations in isolation. Size and mode branches preserve the
other two observable attributes, so each kills an independently isolated
post-open metadata omission rather than relying on modification time as a
proxy. The four 64–128 MiB Linux races share a static mutex, bounding their
concurrent payload allocation, and every watcher has a 30-second observation
deadline with an explicit failure diagnostic.

The subsequent complete replay exposed a pre-existing version-13 false
positive. Both nominal passing implementations include descriptor `ctime` in
their before/after stability signature. Atomic pathname replacement updates
the unlinked old inode's `ctime` without invalidating its already-open bytes,
so both implementations reject a valid verified snapshot when the watcher
lands in the intended window. They each pass 27/28 version-14 entities and
fail only the existing atomic-replacement invariant. The official immutable
version-13 outcome remains 2/10, but it is historical observed calibration,
not proof that those patches satisfy the clarified public contract and not a
result that can carry into version 14.

The prompt now names only the two persisted invocation controls,
`pathAsRoot` and `noGitignore`; describes the reusable local operations
behaviorally; and no longer publishes a test heading, module path, concrete
types, or function signatures. Snapshot wording requires a regular file when
opened and size, Unix mode, and modification metadata stability through
completion. It deliberately does not demand a filesystem type change after
open, which is impossible for an inode and would conflict with the allowed
atomic pathname-replacement case.

The reference strict validator now rejects every Unix entry whose `mode` is
absent during read or serialization. The wrapper retains its skipped
test-only placeholder so the absent solution module cannot create an
unclassified entity, but captures combined runner output and XML-escapes it
into `system-out`. A forced missing-toolchain run preserved the actual cargo
diagnostic. With the reference applied, nextest emits real per-test JUnit, so
the authoritative `new` result contains no skip.

Exact mutation trials killed these new or strengthened shortcuts:

| Trial | Result |
|---|---|
| Remove strict Unix mode-presence validation | Compiles; strict reader entity fails. |
| Silently skip a directly selected Unix socket | Compiles; public offline write entity fails. |
| Ignore final descriptor mode | Compiles; mode-only synchronized race fails. |
| Ignore final descriptor size and byte count | Compiles; size-only, mtime-preserving race fails. |
| Replay `agent-runs3/Nova_Nova_5` option reconciliation after remote setup | Compiles; public CLI probe observes two requests and fails its zero-request assertion. |

The atomic reference entity passed five consecutive exact-image repetitions
after the complete run. No artificial type-race, private hook, syscall order,
tar order, exact error text, extra ignore spelling, or proxy call count was
added. The exact false-positive audit and requirement map are recorded in
`FALSE_POSITIVE_AUDIT.md`.

Version 14 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `83a9c0968716b32e2a4c2560746efbc17d82684f79b127dfd328e965fd56ed80` |
| `test.patch` | `d1c6efb4aa1077913ecfb72ba69e6efc19ce9fc02017f609bf72786e710e5fc0` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently and together in either order, reverse-check,
format, and pass applied-tree whitespace validation. The reference is 731
production additions and 96 deletions, or 635 strict effective additions
across six files with no new dependency. Exact network-disabled Linux results
are 474/474 base and 28/28 new; the new JUnit has zero failures, errors, or
skips. The macOS new lane is 23/23. Test-only `new` exits 101 and reports one
skipped synthetic placeholder containing the full compiler diagnostic.

Version 14 clears the exact internal gates and starts calibration at 0/10. Any
further prompt, test, reference, explanation, environment, or wrapper change
creates version 15 and requires all gates and a fresh calibration batch.

## Version-15 interface and strict-reader design gate

Before changing the prompt or grader, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The search covered
`problems/README.md`, `candidates/CANDIDATES.md`, this problem's current
`SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and
`FALSE_POSITIVE_AUDIT.md`, plus the raw version-13 trajectories for the
legitimate reported pass `agent-runs3/Nova_Nova_1`, the one-boundary near-pass
`agent-runs3/Nova_Nova_2`, and the broadest failure
`agent-runs3/Nova_Nova_4`.

All three representative solvers chose the same repository-supported seam: a
dedicated deployment-plan controller feeding the existing upload and command
flows. They implemented the strict serde model and version checks from the
public schema, while their meaningful divergence remained descriptor timing
and pre-network command sequencing. The latest review does not reveal a new
solver shortcut or justify another difficulty lever. It identifies two
unasserted spellings of already-public strict-reader behavior and a compile
interface that the grader already requires.

| Review or trajectory evidence | Plausible shortcut or defect | Fair public invariant | Planned oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Grader code imports a concrete controller API while version 14 describes only abstract reuse. Every representative solver independently used that seam, but alternative correct code can fail to compile against the grader. | Satisfy the command behavior without exporting the symbols that hidden tests compile against. | The declared test seam must be available with the parameter and result shapes the grader uses. | Add a minimal assumptions paragraph naming only the required module, types, functions, and the existing upload callback seam. | This repairs interface fairness rather than prescribing algorithms, storage, error text, or call order. Remove the broader architectural sentence. |
| Unsupported versions are rejected by validation coverage but not explicitly through `read_deploy_plan`. | Validate constructed/serialized values while allowing an unsupported on-disk version through the reader. | The on-disk format is versioned and unsupported versions are rejected. | Extend the existing strict parser entity with one unsupported-version file passed to the reader. | Coverage breadth inside the strict-schema family; it is not counted as a new discriminator. |
| Unknown top-level fields are covered, but an unknown entry field is not explicit. | Apply strictness only to the outer object while allowing entry extensions. | “Reject unknown fields” applies to both top-level and entry records. | Extend the same parser entity with one otherwise valid entry containing an extra field. | One representative nested field is sufficient; do not enumerate field names or nesting permutations. |
| The raw runs differ on snapshot timing and external-effect suppression, not schema mechanics. | Inflate the suite with more malformed JSON examples after a successful 2/10 historical batch. | Distinct discriminators must represent distinct public boundaries. | Retain all existing schema and lifecycle probes unchanged. | Reject more version values, extra-field locations, error substrings, and exact serde implementation checks as repetitive or private. |

This gate authorizes only the minimal interface clarification and two
strict-reader branches above. Editing either participant-facing text or the
grader creates immutable version 15, invalidates version 14's exact audit, and
restarts calibration at 0/10. The false-positive audit must be repeated on the
final version-15 hashes before it can be approved for calibration.

## Canonical version-15 revision and exact audit

The final prompt removes the abstract reusable-operations sentence and replaces
it with only the controller symbols and signatures required to compile the
grader. It does not require a particular scanner, snapshot representation,
serde implementation, authentication architecture, or error message. The
existing upload function is named only as the pre-existing comparison seam the
grader calls.

The existing strict-parser entity now also writes an unsupported-version plan
through `read_deploy_plan` and an otherwise valid entry containing one unknown
field. These are two paths through the already-public “unsupported versions”
and “unknown fields” requirements. They do not add test entities, fixtures in a
new failure family, or a new discriminator.

Two isolated mutants demonstrate the added coverage:

| Trial | Exact result |
|---|---|
| Remove the version check from strict plan validation | Compiles; the combined parser entity fails specifically at the unsupported-version reader assertion. |
| Remove `deny_unknown_fields` from entry deserialization only | Compiles; the same entity fails specifically at the nested unknown-field reader assertion. |

The version-13 reported pass `Nova_Nova_1` and representative near-pass
`Nova_Nova_2` both pass the strengthened parser entity. This is consistent with
their trajectories: both implemented strict nested records and version
validation, while their meaningful distinction was snapshot timing. The
revision therefore repairs false-negative coverage without converting those
schema spellings into a new difficulty lever.

Version 15 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2d90da444a11e28174359472310ab6ef1e9e040049753480bbe4f6779da18536` |
| `test.patch` | `9de6aaafeab48b579193eec31b3dc811c4327bc0898d92ea5ff4318eba3b1a57` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently and together in either order, reverse-check,
format with the installed host formatter, and pass applied-tree whitespace
validation. The pinned 1.88 macOS toolchain lacks the rustfmt component, so
compilation and test execution use 1.88 while formatting uses the installed
host component. Exact network-disabled Linux results are 474/474 base and
28/28 new; both JUnit files have zero failures, errors, or skips. macOS new is
23/23. Test-only `new` exits at the absent solution-owned module and records one
skipped synthetic placeholder containing the compiler diagnostic.

The exact version-15 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. No actionable mutant survives. Version 15 is
internally validated and starts a fresh calibration batch at 0/10; version
13's official 2/10 result remains trajectory evidence only.

## Version-16 root-entry and CLI-fairness design gate

Before revising the prompt or grader, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The search covered
`problems/README.md`, `candidates/CANDIDATES.md`, this problem's current
`SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and
`FALSE_POSITIVE_AUDIT.md`. The raw version-13 trajectories for reported pass
`agent-runs3/Nova_Nova_1`, snapshot near-pass
`agent-runs3/Nova_Nova_2`, and broadest failure
`agent-runs3/Nova_Nova_4` were reread for archive-root mapping and CLI
conflict handling.

All three representative solvers reused Railway's walker and archive-prefix
mapping and implemented conflicts through their CLI parser. Their meaningful
failures remained snapshot timing and pre-network sequencing, not root-entry
representation or process exit-code choice. The review therefore identifies
one missing public schema sentence and two implementation details that should
be removed from the prompt/test, not new hardening opportunities.

| Review or trajectory evidence | Plausible shortcut or defect | Fair public invariant | Planned oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The grader expects the selected root itself in the manifest and maps an archive-root directory to `"."`, but the prompt only implies directory selection parity. | Omit the selected root directory while including all descendants. | Every selected directory, including the selected root, has a plan entry; an entry at archive root uses normalized path `"."`. | Retain the existing prefix/path-as-root plan-path comparison and make its representation explicit publicly. | Prompt clarification only. Do not add more root aliases, separator spellings, or order assertions. |
| Version 15 names the pre-existing upload helper even though it is discoverable and adds no new feature seam. | Treat an existing implementation helper as participant API. | Planning still uses ordinary upload source selection. | Existing selection-parity behavior remains controlling. | Delete the helper sentence; keep only the four genuinely new controller functions required for grader compilation. |
| The conflict test requires Clap's conventional exit code 2. | Reject conflicts correctly with a different non-zero status. | Each conflicting invocation fails locally, identifies the conflicting options, and makes no request. | Require unsuccessful status, diagnostic mention of the supplied option names, and zero proxy connections. | Remove exact status-code pinning and avoid exact error prose. No exit-code mutant is a semantic discriminator. |

No discriminator family is added. Root inclusion was already asserted by the
existing archive-prefix entity; the new sentence makes that oracle fair.
Relaxing the exit code broadens accepted implementations, while checking only
the option names keeps the diagnostic meaningful without requiring Clap or a
specific phrase. Changing prompt and grader bytes creates immutable version 16,
invalidates version 15's exact audit, and restarts calibration at 0/10.

## Canonical version-16 revision and exact audit

The final prompt states that the selected root is a directory entry and uses
normalized path `"."` when it maps to archive root, including
`--path-as-root`. It removes the pre-existing upload helper and signature from
Test assumptions. The four new controller functions required for grader
compilation remain declared.

The public conflict test no longer checks exit code 2. Each invocation need
only fail, mention the conflicting option names supplied by the user, and make
zero requests. This admits non-Clap implementations and alternative non-zero
statuses without accepting a silent or unrelated failure.

Focused false-positive trials produced:

| Trial | Exact result |
|---|---|
| Omit the `"."` entry only in path-as-root plans | Compiles; the existing prefix/path-as-root entity reports `["app.txt"]` instead of `[".", "app.txt"]`. |
| Remove unsupported-version reader validation | Compiles; the strict parser entity fails at the reader assertion. |
| Accept unknown entry fields | Compiles; the strict parser entity fails at the nested-field assertion. |
| Replay `agent-runs3/Nova_Nova_5` late option reconciliation | Compiles; the unchanged public mismatch probe observes two requests and fails. |

The historical reported pass `Nova_Nova_1` and representative near-pass
`Nova_Nova_2` both pass the relaxed conflict diagnostic. Their earlier
complete replays already pass the selected-root entity. The new prompt sentence
therefore exposes an existing requirement rather than adding a discriminator,
and the conflict edit strictly broadens accepted behavior.

Version 16 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `c63130a29db775e2d34ff6349cfa1c6bebde708273eea732235c05c033b02046` |
| `test.patch` | `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently and together in either order, reverse-check,
format, and pass applied-tree whitespace validation. Exact network-disabled
Linux results are 474/474 base and 28/28 new with zero failures, errors, or
skips. macOS new is 23/23. Test-only `new` exits 101 and records one skipped
synthetic placeholder containing the unresolved-module compiler diagnostic.

The exact version-16 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. No actionable mutant survives. Version 16 is
internally validated and starts calibration at 0/10; version 13's official
2/10 result remains historical evidence only.

## Version-17 prompt-minimization design gate

Before editing the prompt, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The search covered
`problems/README.md`, `candidates/CANDIDATES.md`, the current compact Railway
records, and the raw reported-pass, near-pass, and broad-failure trajectories
`agent-runs3/Nova_Nova_1`, `Nova_Nova_2`, and `Nova_Nova_4`.

All three representative solvers implemented strict plan reading and
deterministic validated serialization from the schema paragraph before or
independently of the final function-specific sentence. Their meaningful
divergence remained descriptor timing and pre-network sequencing. The review
therefore identifies duplicated prose, not a missing behavior or solver
shortcut.

| Review or trajectory evidence | Plausible shortcut or defect | Fair public invariant | Planned oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The final Test assumptions sentence repeats strict on-disk validation and deterministic serialization already required by the schema paragraph. | Treat repeated prose as a second requirement or infer hidden behavior from it. | Plans remain strict, deterministic, versioned JSON and malformed records remain rejected. | Keep every strict reader and deterministic serializer entity unchanged. | Delete only the repetition. Do not alter signatures, tests, reference behavior, or error expectations. |
| Representative pass, near-pass, and broad-failure implementations all derived strict I/O from the schema itself. | Removing the repetition could accidentally admit permissive parsing. | The earlier schema paragraph remains authoritative. | Reuse the exact version-16 strict-reader mutants and full suite. | No discriminator changes; this is prompt compression only. |

No participant-facing behavior, interface signature, test oracle, or reference
byte changes. The prompt hash alone creates immutable version 17, so the exact
false-positive audit must still be repeated and calibration restarts at 0/10.

## Canonical version-17 revision and exact audit

The final prompt deletes only the repeated statement that
`read_deploy_plan` validates strict input and `serialize_deploy_plan` validates
before deterministic output. Strict, deterministic, versioned JSON and all
malformed-record rejection requirements remain explicit in the schema
paragraph; the four grader-facing function signatures remain declared.

The exact audit repeated three shortcuts tied to the deleted prose:

| Trial | Exact result |
|---|---|
| Remove unsupported-version validation | Compiles; the strict parser entity fails at the reader assertion. |
| Accept unknown fields within entry records | Compiles; the strict parser entity fails at the nested-field assertion. |
| Serialize without validating the plan | Compiles; the strict parser entity fails when unsupported constructed data serializes successfully. |

These failures show that the earlier schema paragraph plus unchanged behavioral
tests still exclude permissive read or serialization behavior. Representative
trajectories independently derived those rules from the schema, so the deletion
does not change the discriminator profile.

Version 17 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `e5bf0cacf57d9f9d486919224f43fc04684e99d82073d6a7792fe8171675ae79` |
| `test.patch` | `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Exact network-disabled Linux results are 474/474 base and 28/28 new with zero
failures, errors, or skips; macOS new is 23/23. Patch application, reversal,
formatting, shell syntax, and applied-tree whitespace remain green because all
executable artifacts are byte-identical to version 16.

The exact version-17 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. No actionable mutant survives. Version 17 is
internally validated and starts calibration at 0/10; version 13's official
2/10 result remains historical evidence only.

## Version-18 fairness-correction design gate

Before revising the prompt or grader, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The local-history search covered
`problems/README.md`, `candidates/CANDIDATES.md`, the current compact Railway
records, and the representative raw trajectories
`agent-runs3/Nova_Nova_1`, `Nova_Nova_2`, and `Nova_Nova_4`.

Those trajectories confirm that solvers reasonably choose different internal
wire representations while implementing the required serializer, consistently
derive safe archive paths from ordinary-upload mapping, and use either parser
conflicts or explicit local validation. Their meaningful divergence remains
snapshot coherence and pre-network sequencing. The new review therefore
identifies two grader overconstraints and one under-specified public safety
rule, not opportunities to add private implementation requirements.

| Review or trajectory evidence | Plausible valid implementation or shortcut | Fair public invariant | Planned oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The unsupported-version fixture calls `serde_json::to_vec` directly on `DeployPlan`, although the public seam already supplies `serialize_deploy_plan`. | A correct implementation uses a private serializable wire DTO and does not implement public `serde::Serialize` on `DeployPlan`. | Both the reader and the dedicated serializer reject unsupported versions. | Obtain valid bytes through `serialize_deploy_plan`, mutate a `serde_json::Value` for the reader fixture, and separately pass a constructed unsupported plan to the dedicated serializer. | Remove the accidental trait bound. Do not add any replacement trait or derive requirement. |
| The reader test rejects `/absolute` and `../escape`, while the prompt names only normalized and invalid paths. | A parser validates ordering and UTF-8 but lacks a clearly stated safety grammar for archive names. | Except for the root marker `"."`, archive paths are relative and contain no parent-traversal component. | Retain one absolute and one leading-parent fixture after stating that rule publicly. | Do not enumerate platform separators, aliases, redundant traversal spellings, or tar-library internals. |
| The conflict test requires the diagnostic to echo every supplied long option. | A correct implementation returns a generic local conflict error or relies on a parser whose wording names only one side. | Conflicting invocations fail before any remote request. | Require unsuccessful status and zero observed proxy connections only. | Remove all message and exact-exit-code assertions. Presentation is not a discriminator. |

No discriminator family is added. The unsupported-version and conflict edits
strictly broaden the accepted implementation space. The path edit makes an
existing safety oracle explicit and retains only two distinct semantic
boundaries: absolute naming and parent traversal. Changing prompt and grader
bytes creates immutable version 18, invalidates version 17's exact audit, and
restarts calibration at 0/10.

## Canonical version-18 revision and exact audit

The unsupported-version fixture now obtains valid plan bytes only through
`serialize_deploy_plan`, mutates a `serde_json::Value` for the reader branch,
and separately checks the dedicated serializer with a constructed unsupported
plan. A compatibility prototype removed `Serialize` from public `DeployPlan`
and used a private wire DTO; it compiled and passed the strengthened parser
entity.

The prompt now states the safety grammar exercised by the existing path
fixtures: apart from `"."`, archive paths are relative and contain no `..`
component. The conflict entity requires only unsuccessful local completion and
zero proxy connections. It no longer checks exit code or any diagnostic text.

Focused false-positive trials produced:

| Trial | Exact result |
|---|---|
| Public `DeployPlan` without `Serialize`, private serializable DTO | Compiles; the unsupported-version/unknown-field entity passes. |
| Remove unsupported-version validation | Compiles; the reader assertion fails. |
| Accept absolute archive names | Compiles; the `/absolute` reader assertion fails. |
| Accept parent traversal | Compiles; the `../escape` reader assertion fails. |
| Generic conflict diagnostic | Accepted by inspection: the entity reads only process success and proxy count. |

The restored reference controller is byte-identical to the clean
solution-first application. No actionable incorrect implementation survives
the focused suite; the byte-identical version-17 snapshot, source-selection,
metadata, archive-byte, unsupported-input, and pre-network mutants retain
their existing killing probes.

Version 18 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `dd0a8ea05ed813f74da325041962b655782a8209460ecbfd93e2fdcfd8fac838` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patch orders apply and reverse-check, formatting and shell syntax pass,
and both applied trees pass whitespace validation. Exact network-disabled
Linux results are 474/474 base and 28/28 new. The new JUnit reports 28 tests,
zero failures, zero errors, and no skipped testcase. macOS new is 23/23.
Test-only new exits 101 and its single classified fallback preserves the
unresolved-controller compiler diagnostic.

The exact version-18 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. Version 18 is internally validated and starts
calibration at 0/10; version 13's official 2/10 result remains historical
evidence only.

## Version-19 verified-byte prompt-minimization design gate

Before editing the prompt on 2026-07-28, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The history search covered
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the current Railway compact records, and the raw
reported-pass, near-pass, and broad-failure evidence in
`agent-runs3/Nova_Nova_1`, `Nova_Nova_2`, and `Nova_Nova_4`.

All three representative implementations collected descriptor-backed bytes
into snapshots and supplied those bytes directly to tar creation. Their
meaningful divergence was metadata timing and pre-network sequencing, not
interpretation of the verified-byte invariant. Earlier exact mutation records
also show that delegating archive input back to a reopened pathname survives
the complete baseline but fails the atomic-replacement payload assertion.

| Review or trajectory evidence | Plausible shortcut or valid design | Fair public invariant | Existing black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The prompt states both the observable outcome and two prohibited internal steps. | A correct implementation may use any number of scans or handles while still placing exactly the verified bytes in the archive. | The bytes whose content was verified against the plan are the bytes uploaded in the archive. | Atomic pathname replacement after the verified descriptor opens must still archive the old verified bytes. | Delete the two implementation prohibitions. Keep the outcome sentence and the byte-level oracle unchanged; do not prescribe handles, scan count, buffering, or tar construction. |
| `agent-runs3` pass, near-pass, and broad-failure patches all naturally buffer snapshot bytes. | Solvers do not need the internal recipe to discover a conforming architecture. | Archive payload identity, not internal sequencing, controls acceptance. | Verified-archive content and atomic-replacement entities inspect only decoded bytes. | No new test, fixture, message assertion, or discriminator family. |

This is a prompt-only minimization. No participant-facing outcome, grader API,
test oracle, reference behavior, dependency, or environment artifact changes.
The prompt hash alone creates immutable version 19, invalidates version 18's
exact audit, and resets calibration to 0/10.

## Canonical version-19 revision and exact audit

The final prompt retains “The verified bytes must be the bytes placed in the
upload archive” and deletes only the two implementation prohibitions about
reopening a pathname and performing a second scan. Tests continue to observe
archive bytes, source identity, and pre-network behavior without inspecting
handles, scan count, buffering, or call order.

The exact verify-then-reopen mutant passed the complete 474-test
network-disabled Linux baseline, then failed the atomic-replacement entity's
archived-byte assertion. This demonstrates that the remaining outcome
requirement and unchanged oracle exclude the real shortcut targeted by the
deleted prose.

Version 19 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `4415e1706a5712107828028c4d060883ffc28e6e5d8932de90c62ba2c9c92c44` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patch orders apply and reverse-check; formatting, shell syntax, and
applied-tree whitespace checks pass. Exact network-disabled Linux results are
474/474 base and 28/28 new, and macOS new is 23/23. The restored reference
controller is byte-identical to the clean other-order application.

The exact version-19 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. Version 19 is internally validated and starts
calibration at 0/10; version 13's official 2/10 result remains historical
evidence only.

## Version-20 snapshot-clause prompt-minimization design gate

Before editing the prompt on 2026-07-28, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The history search covered
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the current Railway compact records, and the raw
reported-pass, near-pass, and broad-failure evidence in
`agent-runs3/Nova_Nova_1`, `Nova_Nova_2`, and `Nova_Nova_4`.

The representative solvers all implemented descriptor-backed reads. The
near-pass and broad-failure evaluations identify the concrete open-to-complete
metadata window—not the abstract “coherent snapshot” phrase—as the missed
boundary. The exact suite independently mutates modification metadata, size,
and Unix mode after descriptor open.

| Review or trajectory evidence | Plausible shortcut or valid design | Fair public invariant | Existing black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| “Each regular-file record must describe one coherent descriptor-backed snapshot” is immediately followed by the concrete rejection rule. | Solvers can implement the concrete open/type/stability conditions without sharing the prompt's abstract label or reference architecture. | Planning rejects a non-regular opened input and rejects size, Unix-mode, or modification-metadata changes after open and before snapshot completion. | Separate bounded Linux races change mtime, size, and mode; the socket fixture covers unsupported opened input. | Delete only the abstract sentence. Keep the concrete sentence and every behavioral oracle unchanged. |
| `Nova_Nova_2` and `Nova_Nova_4` missed the open-to-first-metadata window despite otherwise reasonable descriptor designs. | A shallow implementation can compare only two later descriptor states or omit one metadata dimension. | Every named change kind must remain detectable across the stated interval. | Existing mtime-, size-, and mode-specific entities kill independent omissions. | No new fixture, timing rule, metadata field, error message, or private sequencing requirement. |

This is a prompt-only minimization. No participant-facing outcome, grader API,
test oracle, reference behavior, dependency, or environment artifact changes.
The prompt hash alone creates immutable version 20, invalidates version 19's
exact audit, and resets calibration to 0/10.

## Canonical version-20 revision and exact audit

The final prompt deletes only “Each regular-file record must describe one
coherent descriptor-backed snapshot.” The immediately following sentence still
requires planning to reject a selected input that is non-regular on open or
whose size, Unix mode, or modification metadata changes after open and before
snapshot completion. Tests continue to observe each named condition rather
than the deleted abstraction.

Three isolated reference mutations removed, respectively, both modification
checks, all size and byte-count checks, and both Unix-mode checks. Each compiled
and was rejected by its matching synchronized Linux race. The restored
controller is byte-identical to the clean solution-first application, so these
trials did not alter the canonical reference.

Version 20 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `fd4947f855b8aca3684960fe39f978efb5e83a00ca63853c817f2467b0d8e6c5` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patch orders apply and reverse-check; formatting, shell syntax, and
applied-tree whitespace checks pass. Exact network-disabled Linux results are
474/474 base and 28/28 new, and macOS new is 23/23.

The exact version-20 false-positive audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. Version 20 is internally validated and starts
calibration at 0/10; version 13's official 2/10 result remains historical
evidence only.

## Version-21 reviewer-correction design gate

Before revising the grader on 2026-07-28, `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread. The history search covered
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, and the representative
legitimate pass, near-pass, and broad failure in
`agent-runs3/Nova_Nova_1`, `Nova_Nova_2`, and `Nova_Nova_4`. The current
reviewer report supplies the newer 1/10 batch summary; its raw run directory
has not been added to the workspace, so the retained raw trajectories remain
the inspectable implementation evidence.

The legitimate pass implemented strict reader validation and explicitly
handled project-token/environment targeting by choosing the current directory.
The near-pass and broad failure demonstrate that otherwise substantial
solutions commonly split local planning from ordinary authenticated path
resolution. Repository source independently defines the required policy:
`Configs::get_closest_linked_project_directory` and `get_linked_project`
choose the current directory for project-token or environment-variable
targeting, while local links otherwise walk ancestors.

| Review or trajectory evidence | Plausible shortcut or valid design | Fair public invariant | Black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The current reader entity sends reversed and duplicate plans only to `serialize_deploy_plan`; a raw reader can omit the same checks. The legitimate pass validates raw unsorted input independently. | Use separate wire parsing and public serialization paths, validating only the latter. | Both public plan I/O directions reject duplicate or non-increasing entry paths. | Serialize one valid plan, reverse or duplicate its raw JSON entries, write each form to disk, and require `read_deploy_plan` to reject it. | Extend the existing strict-record entity. Add no new schema rule, error text, or representation constraint. |
| The reviewer found that the reference's offline helper always consults local links; ordinary `up` uses the current directory under project-token and env-var targeting. Earlier root tests cover only plan creation. | Share one correct write resolver but use the current working directory, linked ancestor, or a second resolver incorrectly during apply. | Planning and reconciliation use the same source-root policy as ordinary `up` for linked, explicit-project, project-token, and environment-variable targeting. | From a linked child, require an unchanged linked-root plan and a current-directory explicit plan to pass local apply verification; require changed explicit inputs to fail before requests; apply the current-directory plan under token and environment targeting and require local verification to complete before remote activity. | Extend one CLI source-identity entity across the four repository-defined modes. Observe only plan paths, local rejection, and whether verification reaches the remote boundary; do not expose or require a helper. |
| The reviewer prohibits the benchmark-sounding “Test assumptions” heading but still accepts a short compatibility note for the required public seam. | Keep the declared compile interface while presenting it as maintainer compatibility. | Participants can discover the exact grader-facing API without benchmark terminology. | Description review only; executable behavior is unchanged. | Rename the heading to “Compatibility”; do not broaden or conceal the interface. |

These are narrow false-positive corrections, not new discriminator families.
No timing fixture, error-message assertion, tar ordering rule, extra schema
field, or private call sequence is added. Editing the prompt, tests, and
reference creates immutable version 21 and resets the reported version-20
1/10 calibration result to 0/10.

## Canonical version-21 revision and exact audit

The public description now labels the declared grader seam “Compatibility”
instead of “Test assumptions.” The reader entity feeds raw reversed and
duplicate entry arrays through `read_deploy_plan`. The existing CLI root entity
now proves local apply verification for linked, explicit-project,
project-token, and environment-variable targeting, and requires changed
explicit-project input to fail before any request.

The reference offline resolver now uses a local linked ancestor only when no
explicit project, project token, or environment-variable targeting is active.
The other three modes use the current directory, matching ordinary `up`.

Version 21 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be` |
| `test.patch` | `fc7679b7296e78021877c22be6ad7276975cb96e274a1be0f2d38e8a70b17141` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patch orders apply and reverse-check; formatting, shell syntax, and
applied-tree whitespace checks pass. Exact network-disabled Linux results are
474/474 base and 28/28 new, and macOS new is 23/23. Test-only Linux new exits
101 and its fallback JUnit preserves the unresolved-controller diagnostic.

The permissive-reader, apply-always-current-directory, token-root, and
environment-root mutants each compile and fail their matching focused
assertion. The exact version-21 audit is recorded in
`FALSE_POSITIVE_AUDIT.md`. Version 21 starts calibration at 0/10; version 20's
reviewer-reported 1/10 is historical only.

## Version-22 atomic-replacement fairness gate

Before revising the hidden oracle on 2026-07-28,
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were reread. The history
search covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, and the representative
raw trajectories and patches in `agent-runs3/Nova_Nova_1`,
`Nova_Nova_2`, and `Nova_Nova_4`.

`Nova_Nova_1` is the legitimate pass: it builds descriptor-backed snapshots
and compares Unix change metadata, including `ctime`. Replaying that approach
against the later atomic-replacement entity can reject after the pathname swap
because unlinking the opened inode changes `ctime`, even though the opened
bytes remain coherent. `Nova_Nova_2` is the near-pass that misses the
open-to-first-metadata mutation interval. `Nova_Nova_4` is the broader failure
that also permits auxiliary requests before invalid apply reconciliation.
Those latter two failure families remain independently covered and are not
affected by this revision.

The new fairness report supplies direct evaluator evidence: the public
integrity guarantee controls the bytes of any archive that is produced, but it
does not require a plan apply to survive atomic pathname replacement. A
conservative identity/change detector and a descriptor-preserving archiver are
both valid implementations.

| Review or trajectory evidence | Plausible shortcut or valid design | Fair public invariant | Black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The atomic entity currently unwraps archive creation after replacing the selected pathname. A legitimate descriptor implementation may instead reject because the opened inode's change metadata or path identity changed. | Safely reject the replacement, or finish from the coherent opened snapshot. | If atomic replacement is detected during reconciliation, the operation may reject. If it succeeds, every archived regular-file byte must be the verified pre-replacement byte. | Observe the selected descriptor, atomically install equal-size replacement contents, then accept `Err`; for `Ok`, decode the archive and require the complete original payload. | Weaken only the success oracle. Keep the synchronized replacement and byte assertion so a verify-then-reopen implementation that succeeds with replacement bytes still fails. |
| The race uses `/proc/self/fd` and a large payload to make the descriptor interval observable. | A watcher may fail to win under an unusual scheduler. | The fixture is meaningful only when replacement actually occurs after descriptor observation. | Retain the bounded watcher and explicit observation assertion. | Do not silently pass an untriggered race or introduce a private test hook. No additional race permutation is added. |

This revision removes an unfair outcome constraint without deleting the
verified-byte discriminator. It changes no prompt requirement, public API,
reference implementation, schema rule, error text, or test count. Changing the
grader creates immutable version 22 and resets version 21 calibration to 0/10;
all exact validation and false-positive checks must be repeated for the new
artifact hash.

## Canonical version-22 revision and exact audit

The Linux entity is now named
`deployment_plan_atomic_replacement_is_rejected_or_uses_the_verified_snapshot`.
It still requires the watcher to observe the source descriptor and complete
the atomic replacement. It accepts a local `Err`; an `Ok` archive is decoded
and must contain the complete original payload.

Version 22 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be` |
| `test.patch` | `c6639ff612ba5144e5dd2fc800e8f96d5d043cd4717df763495f46e74760eebc` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patch orders apply and reverse-check; formatting, shell syntax, and
applied-tree whitespace checks pass. Exact network-disabled Linux results are
474/474 base and 28/28 new, and macOS new is 23/23. Test-only Linux new exits
101 and its fallback JUnit preserves the unresolved-controller diagnostic.

The verify-then-reopen mutant compiles, passes 27 focused entities, and fails
the revised atomic entity because it archives replacement bytes. The
historical legitimate `agent-runs3/Nova_Nova_1` implementation now passes all
28 focused entities by safely rejecting the replacement. The exact
version-22 audit is recorded in `FALSE_POSITIVE_AUDIT.md`. Version 22 starts
calibration at 0/10; no earlier result carries forward.

## Version-23 agent-runs4 and deterministic-race design gate

Before changing the public description or grader on 2026-07-28,
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were reread. The required
history search covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the Railway compact records, all ten
`agent-runs4` evaluations, and the raw trajectories and patches for
`Nova_Nova_1`, `Nova_Nova_2`, `Nova_Nova_3`, `Nova_Nova_7`, and
`Orion_Nova`.

The immutable version-22 batch produced three passes out of ten:
`Nova_Nova_2`, `Nova_Nova_6`, and `Nova_Nova_7`. Four near-passes
(`Nova_Nova_1`, `Nova_Nova_4`, `Nova_Nova_5`, and `Nova_Nova_8`) missed the
open-to-first-metadata interval; `Nova_Nova_3` missed that interval and
token/environment source-root parity; `Nova_Nova_9` missed explicit-project
source-root parity; and `Orion_Nova` missed the post-metadata, pre-digest
mutation interval. No run was a behavioral broad failure: the worst result was
26/28, so the broad-failure role is unavailable in this batch.

Representative raw evidence:

| Evidence role | Run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Grader-classified pass | `agent-runs4/Nova_Nova_2` | 28/28 | Captures pathname metadata, opens the file, then compares only descriptor metadata sampled before and after reading. The pre-open `initial` value is never compared with the first descriptor sample, so a mutation in that interval is accepted despite the passing result. |
| Second pass with the same survivor | `agent-runs4/Nova_Nova_7` | 28/28 | Opens first and compares two later descriptor samples. It independently confirms that the current polling race can miss the public open-to-first-snapshot boundary. |
| Near-pass | `agent-runs4/Nova_Nova_1` | 27/28 | Uses a coherent descriptor and before/after checks but has no pre-open comparison. The current mtime race happened to hit the interval and rejected this implementation. |
| Distinct near-pass | `agent-runs4/Orion_Nova` | 27/28 | Correctly compares pre-open pathname metadata with the opened descriptor, but the run exposes a later mutation interval between the last metadata validation and completed digest/snapshot work. |
| Two-family failure | `agent-runs4/Nova_Nova_3` | 26/28 | Combines the open-window omission with a source-root policy mismatch under project-token/environment targeting. The root family remains covered independently and is not revised here. |

This evidence changes the interpretation of the race review: the existing
`/proc/self/fd` polling is not merely expensive or theoretically flaky. It
produced false negatives for two plausible, incorrect implementations in the
same batch. The public requirement already names the interval after descriptor
open and before snapshot completion, so deterministic coordination repairs the
oracle rather than adding a new rule.

The version-23 discriminator ledger is:

| Review or trajectory evidence | Plausible shortcut or valid design | Fair public invariant | Revised black-box oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| “Must fail clearly” is subjective. | Return any ordinary error without a particular message. | Broken links, unsupported selected inputs, and non-UTF-8 archive paths are rejected. | Existing `Err` and unsuccessful-process assertions. | Replace “must fail clearly” with “must return an error.” Add no message or error-type assertion. |
| The raw reader has disk cases for schema fields, version, ordering, and duplicates, but malformed file digests and unknown kinds are exercised only through serialization or deserialization incidentally. | Validate an in-memory serializer strictly while accepting incomplete or malformed persisted file records. | `read_deploy_plan` rejects malformed records, including a missing or invalid regular-file digest and an unknown entry kind. | Mutate one valid serialized JSON value, write each malformed form to disk, and require the public reader to return `Err`. | Extend the existing strict-record entity; add no new test count, spelling-specific error, or private DTO requirement. |
| `Nova_Nova_2` and `Nova_Nova_7` passed despite architectures that omit the pre-open comparison; four other runs failed the same family depending on scheduling. | Compare only descriptor samples captured after `open` returns. | A named size, Unix-mode, or modification-metadata change after the descriptor is opened and before the snapshot completes is rejected. | Run the public API in a child process with a Linux preload shim that blocks the target `open` after the kernel returns the descriptor but before Rust receives it. Mutate while blocked, release, and inspect the public result. | Replace polling and 64–128 MiB fixtures with a deterministic black-box barrier. The shim changes no production source, exposes no participant hook, and prescribes no implementation beyond the already-public timing boundary. |
| Atomic replacement may validly reject or preserve the old opened bytes. | Conservative identity validation and descriptor-preserving success are both conforming. | If apply succeeds, archived bytes are the verified bytes; safe rejection remains allowed. | Use the same deterministic open barrier, then accept `Err` or require complete old bytes on `Ok`. | Preserve version 22's fair outcome while removing its scheduler dependency. |

The mtime, size, mode, and atomic-replacement entities remain distinct public
boundaries, but share one test-harness barrier. No extra race permutation,
private implementation symbol, error text, tar order, or source-root rule is
added. Editing the prompt and grader creates immutable version 23 and resets
the historical version-22 calibration result of 3/10 to 0/10. Exact reference,
participant replay, mutation, wrapper, platform, and false-positive checks are
required before version 23 can be approved.

## Canonical version-23 revision and exact audit

Version 23 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `6ae1bc174f136556136d3d041a3307fbe6b2a092f9e087f60c77c1a490b663e7` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The prompt now replaces subjective “fail clearly” wording with the observable
requirement to return an error. The existing strict-record entity writes raw
JSON with missing and invalid-length file digests and an unknown entry kind,
then requires `read_deploy_plan` to reject each record. The four Linux snapshot
entities use a test-only `LD_PRELOAD` interposer to stop the exact target
descriptor synchronously after kernel `open` or the first successful `read`;
the 30-second deadline detects only harness deadlock and does not select the
mutation interval.

Exact validation results:

- combined network-disabled Linux `base`: 474/474;
- combined network-disabled Linux `new`: 28/28, with zero failures, errors, or
  skipped new testcases in JUnit;
- combined macOS `new`: 23/23;
- test-only network-disabled Linux `new`: exit 101, with fallback JUnit
  preserving the unresolved `controllers::deploy_plan` compiler diagnostic;
- both patch orders, both reverse checks, applied-tree whitespace checks, and
  default-toolchain `cargo fmt --check`: pass.

The exact mutation and trajectory evidence is:

| Mode | Result | Interpretation |
|---|---|---|
| Remove the reference's pathname-before-open comparisons. | Compiles; the deterministic open-phase modification assertion fails. | Kills the direct pre-open-stability omission without depending on payload size or scheduling. |
| Replay `agent-runs4/Nova_Nova_2`. | Compiles; the deterministic open-phase assertion fails with result marker `O` instead of expected `E`. | Converts a version-22 nominal pass into the correct failure; `Nova_Nova_7` has the same independently reviewed architecture. |
| Remove reader-side `validate_plan`. | Compiles; the raw malformed-record reader entity fails. | Confirms that strict serialization alone cannot satisfy persisted plan reading. |
| Reopen the selected pathname for tar construction after verification. | Compiles; the deterministic atomic-replacement entity observes replacement bytes and fails. | Preserves the verified-byte discriminator while still accepting safe rejection. |

No solver patch in `agent-runs4` is a legitimate pass: all three nominal
passes omit the public open-to-first-snapshot comparison. The earlier
conservative `agent-runs3/Nova_Nova_1` replay remains recorded as 28/28 for
version 22, but its local patch became an unrecoverable macOS dataless
placeholder before the version-23 replay attempt and is not claimed as a
version-23 result. The exact reference supplies the legitimate implementation
side; the exact Nova2 replay supplies the failing participant side.

The requirement-to-oracle map, rejected artificial mutations, and retained
historical families are recorded in `FALSE_POSITIVE_AUDIT.md`. There is no
actionable survivor in the attempted mutation set. Version 23 clears the
internal false-positive and reference gates and begins a new calibration batch
at 0/10; the version-22 3/10 result does not carry forward.

## Version-24 root-marker ordering design gate

Before revising the grader, the mandatory design and calibration procedures
were consulted from their already-recorded version-23 gate; their root files
are currently unreadable macOS dataless placeholders. The history search
covered `problems/README.md`, `candidates/CANDIDATES.md`, this problem's compact
records, all available `agent-runs4` evaluations, and the raw solution patches
for `Nova_Nova_1`, `Nova_Nova_2`, `Nova_Nova_3`, `Nova_Nova_4`, and
`Orion_Nova`.

The new adjudicator report provides a reproduced black-box counterexample:
with `pathAsRoot=true` and a selected top-level file named `-hello.txt`,
ordinary upload and the reference accept the source, while the passing
candidate rejects planning because `validate_deploy_plan` treats
`entries[0]` as the root marker. The report's candidate error text matches the
available `agent-runs4/Nova_Nova_2` validator verbatim. Nova3, Nova4, Nova1,
and Orion contain related first-entry root assumptions, so this is a plausible
solver family rather than an adversarial mutant.

The requirements are not in conflict. Entries are globally sorted by
normalized UTF-8 archive path, and the archive-root directory is represented
by `"."`. ASCII `"-"` sorts before `"."`, so a conforming sorted plan may
place `"-hello.txt"` before its `"."` root marker. Ordinary upload imposes no
leading-punctuation restriction.

The version-24 discriminator ledger is:

| Adjudicator or trajectory evidence | Plausible shortcut | Fair public invariant | Revised black-box oracle | Decision and anti-overfit rationale |
|---|---|---|---|---|
| A 28/28 candidate rejects `-hello.txt` because it requires `entries[0]` to be a directory root marker. | Infer that the selected-root record is always the first globally sorted entry. | Planning uses ordinary upload selection, includes `"."` at archive root, and globally sorts all normalized paths; root lookup cannot depend on position. | Add one `-hello.txt` child to the existing prefix/path-as-root fixture. Require ordinary upload, planning, and verified archiving to succeed with the same normalized path set, and require the plan order `["-hello.txt", ".", "app.txt"]`. | This is one new semantic boundary—root-marker position independence. Do not add space/`!`/`#`/`+` permutations, exact errors, or a private validator probe. |
| The reference already locates behavior by path/selection rather than requiring the first entry to be the root marker. | Reject punctuation-leading paths as invalid to preserve root-first order. | Such paths are valid ordinary upload inputs and valid relative plan paths. | The same public fixture passes the reference and ordinary uploader. | No prompt or reference change; the existing contract is sufficient. |

This correction strengthens one existing test entity and keeps the Linux/macOS
test census at 28/23. It changes no public description, API, reference,
dependency, wrapper, or Docker image. Editing `test.patch` creates immutable
version 24, invalidates the version-23 artifact and supplied result, and
requires exact reference, candidate replay, mutation, patch-integrity,
platform, and false-positive gates again before calibration.

## Canonical version-24 revision and exact audit

Version 24 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `c678cf73834c743b3882ac7fd7c46d370f523bb550e1de6b7da3d3167b6f4e42` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The existing
`deployment_plan_service_prefix_and_path_as_root_modes_are_preserved` entity
now selects both `app.txt` and `-hello.txt`. In prefix mode it requires
`["services/api", "services/api/-hello.txt", "services/api/app.txt"]`. At the
archive root it requires the globally sorted plan
`["-hello.txt", ".", "app.txt"]`, and independently requires ordinary and
verified archives to contain that same normalized set. The assertions sort
decoded archive paths and therefore do not establish a tar-stream order
contract.

Exact results:

- combined network-disabled Linux `base`: 474/474;
- combined network-disabled Linux `new`: 28/28, with zero failures, errors, or
  skipped new testcases in JUnit;
- combined macOS `new`: 23/23, with zero failures, errors, or skipped
  testcases;
- test-only network-disabled Linux `new`: exit 101, with fallback JUnit
  preserving the unresolved `controllers::deploy_plan` diagnostic;
- both patch orders, both reverse checks, applied-tree whitespace checks, and
  formatting: pass.

The exact `agent-runs4/Nova_Nova_2` source was replayed against only the
strengthened entity. It compiled and failed while creating the path-as-root
plan with `deploy plan root marker must be a directory`. This is the same
validator and error reported by the adjudicator. The unchanged reference
passes the entity in Linux and macOS. No incorrect root-first implementation
survives the new focused oracle.

No prompt, reference, API, dependency, wrapper, image, test name, or test count
changed. Punctuation permutations were rejected as duplicate fixtures for the
same boundary. The full requirement map, retained v23 mutation results, and
version-24 decision are recorded in `FALSE_POSITIVE_AUDIT.md`. Version 24
clears the exact internal gates and starts calibration at 0/10; the supplied
version-23 nominal pass is historical false-positive evidence only.

## Version-25 CLI-path and embedded-parent design gate

Before revising `test.patch`, the operative design procedure was recovered
from the complete trajectory-gate section in `PLAN.md`, the prior version-23
and version-24 gate records in this file, and the mandatory rules in
`AGENTS.md`. The root `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` files
remain unreadable macOS dataless placeholders, so this limitation is recorded
rather than treating an empty read as evidence. The history search covered
`problems/README.md`, `candidates/CANDIDATES.md`, `PLAN.md`, `LEVELS.md`,
`PROTOTYPE.md`, `FALSE_POSITIVE_AUDIT.md`, the current prompt and reference,
and the raw trajectories, participant patches, JUnit, and evaluations for both
`agent-runs5` runs.

Version 24 has no legitimate solver pass or broad behavioral failure:
`Nova_Nova_1` preserves 474/474 baseline tests and passes 22/28 focused
entities, while `Nova_Nova_2` preserves 474/474 and passes 23/28. Both are
representative near-passes. The exact reference is the available legitimate
implementation evidence and passes 474/474 baseline plus 28/28 Linux and
23/23 macOS focused entities. No unavailable trajectory role is inferred.

The two near-passes both carry the positional `Args.path` through their local
deploy-path helpers and both reject `Component::ParentDir`; they therefore do
not motivate another solver-specific trap. The review instead identifies two
publicly required seams for which the current tests admit simpler incorrect
implementations:

| Evidence | Solver seam and plausible shortcut | Missed public invariant | Proactive check |
|---|---|---|---|
| Every public plan CLI fixture omits positional `PATH`; `--path-as-root` is exercised only through the reusable controller API. | Implement the controller correctly but ignore, replace, or inconsistently forward `Args.path` in the offline `--write-plan` or `--from-plan` command branches. | `railway up PATH --path-as-root` uses `PATH` as both selected source root and archive root in planning and reconciliation. A mismatched invocation fails before any request. | Strengthen the existing CLI option/reconciliation entity to write from a positional subdirectory with `--path-as-root`, inspect the `"."`-rooted plan, perform a valid apply far enough to reach the remote flow, then omit `--path-as-root` and require local zero-request rejection. |
| The unsafe-path reader loop contains only `/absolute` and leading `../escape`. Its path replacement can also disturb entry ordering, allowing an ordering error to mask permissive path validation. | Reject absolute paths and only strings beginning with `"../"`, while accepting a parent component later in an otherwise relative archive path. | Apart from the root marker, no normalized archive path may contain a `..` component at any position. | Add `nested/../escape` to the existing raw-JSON reader loop and re-sort each mutated document before reading it. This isolates component-position validation and kills a prefix-only validator rather than relying on the independent ordering check. |

The version-25 discriminator ledger is:

| Proposed discriminator | Public and observable | Plausible incorrect implementation | Distinct contribution | Decision |
|---|---|---|---|---|
| Positional `PATH` plus `--path-as-root` through public write/apply commands | The prompt binds both flags to ordinary upload source selection and requires reconciliation before remote effects. Plan JSON, process status, and request count are black-box observations. | Compatibility helpers are correct, but one CLI branch uses the current directory, drops `PATH`, or fails to forward `path_as_root`. | Crosses the public CLI-to-controller forwarding boundary, which no helper-only fixture can cover. | Add one composed public CLI entity; do not add argument-order permutations, private helper assertions, or exact diagnostics. |
| Embedded parent component in persisted plan JSON | The prompt expressly forbids any `..` component and requires the reader to reject invalid paths. | A prefix check handles the two current samples yet accepts `nested/../escape`; unsorted mutated fixtures can otherwise conceal that survivor. | Exercises component-wide validation rather than leading-prefix classification while keeping the independent sortedness invariant satisfied. | Extend the existing unsafe-path entity by one structural case and sort the raw entries after mutation; do not add `a/b/../../c`, repeated separators, or platform-specific separator variants. |

No public description, reference behavior, API, dependency, wrapper, or
Docker artifact needs to change. Editing `test.patch` will create immutable
version 25, invalidate version 24's two-run calibration batch, and restart
calibration at 0/10 after exact reference, mutation, patch-integrity,
cross-platform, and false-positive gates are repeated.

## Canonical version-25 revision and exact audit

Version 25 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `7de2674f9e78fb0a185ca3e36d538ca7ee2323ed6bd62a89325a440e23bc7c33` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The existing unsafe-path entity now writes globally sorted raw JSON for
`/absolute`, `../escape`, and `nested/../escape`, preventing the independent
ordering check from masking permissive path parsing. The existing public CLI
option entity writes and applies a plan with positional `selected` plus
`--path-as-root`, requires the plan to contain only `"."` and `app.txt`, then
omits `--path-as-root` and requires rejection before any additional request.
Test names and the 28/23 Linux/macOS census are unchanged.

Exact isolation:

| Incorrect mode | Other focused tests | Complete pre-existing suite | Strengthened entity |
|---|---:|---:|---|
| Reject only absolute and leading `../` paths, accepting embedded parent components. | 22/22 macOS focused tests outside the unsafe-path entity pass. | 474/474 pass. | The sorted `nested/../escape` reader case fails because `read_deploy_plan` returns `Ok`. |
| For offline `path_as_root`, ignore positional `Args.path` and select the current directory. | 22/22 macOS focused tests outside the CLI option entity pass. | 474/474 pass. | The public write produces `[".", "outside.txt", "selected", "selected/app.txt"]` instead of `[".", "app.txt"]`. |

The exact unchanged reference passes:

- network-disabled Linux `base`: 474/474;
- network-disabled Linux `new`: 28/28 with zero failures, errors, or skips;
- macOS `new`: 23/23;
- test-only network-disabled Linux `new`: exit 101 with the unresolved
  `controllers::deploy_plan` compiler diagnostic retained in fallback JUnit.

Both patch orders, both reverse checks, applied-tree whitespace checks, and
default-toolchain formatting pass. No incorrect mode survives the complete
focused suite, so neither requires promotion to the regression set. No prompt,
reference, explanation, API, dependency, wrapper, Dockerfile, image, test
name, or test count changed. Version 25 clears the bounded false-positive gate
and restarts calibration at 0/10; both version-24 `agent-runs5` outcomes are
historical trajectory evidence only.

## Version-26 CLI no-gitignore and harness-integrity design gate

Before revising `test.patch`, the mandatory design and false-positive
procedures were rechecked through `AGENTS.md`, the complete operative gate
preserved in `PLAN.md`, the canonical version-25 records in this file and
`FALSE_POSITIVE_AUDIT.md`, and the latest reviewer findings. The root
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, and worked Statig reference
remain unreadable macOS dataless placeholders: metadata is present, but direct
reads fail with `Operation timed out` and File Provider reports no materialized
item. This limitation is recorded explicitly instead of treating an empty read
as evidence.

The history search covered the current prompt, reference and grader, the
problem/candidate indexes already summarized in the version-25 gate, and both
raw `agent-runs5` trajectories, participant patches, evaluations, test logs,
and JUnit reports. `Nova_Nova_1` is a 22/28 near-pass and
`Nova_Nova_2` is a 23/28 near-pass; each preserves all 474 baseline tests.
Both trajectories independently implement a controller-level option check and
forward `Args::no_gitignore`, so they are legitimate evidence that the
contract is solvable, not examples of the new shortcut. The unchanged
reference remains the representative pass. No additional broad failure exists
for this exact version; earlier broad-failure families remain historical only.

The reviewer identifies one public false-positive seam and two harness defects:

| Evidence | Plausible shortcut or defect | Public/integrity boundary | Version-26 action |
|---|---|---|---|
| `deployment_plan_invocation_option_mismatches_are_rejected` checks `no_gitignore` only by calling the controller, while the public CLI option entity checks only `pathAsRoot`. | Implement strict controller validation but omit, invert, or replace `Args::no_gitignore` in the `--from-plan` command branch. | Both plan-stored invocation controls must be reconciled through the public command before any request. | Extend the existing CLI option entity with `--no-gitignore`; require unsuccessful status and no increase in counted connections. Do not add argument-order variants or error-text assertions. |
| `CountingProxy::count` sleeps 25 ms before reading an atomic updated by a separately scheduled accept loop. | A slow runner observes zero before the accept thread drains an already queued connection. | Request-ordering assertions must observe the listener deterministically. | Give the proxy thread a command channel. A snapshot command drains pending accepts and replies with the count through a bounded receive, establishing a barrier without a fixed observation sleep. |
| `write_fallback_junit` labels every nonzero no-JUnit runner result as one skipped synthetic `new.run`. | Compilation, linker, or runner failures appear harmless and lose failure accounting. A naive synthetic failure would recreate the previously observed unclassified `new.run` entity. | Nonzero runner outcomes must be failures with diagnostics, and wrapper entity identities must remain classifiable. | Emit a failure under the existing public CLI write-test identity in `new` mode and an existing baseline identity in `base` mode. Preserve escaped runner output in the failure body and `system-out`; introduce no synthetic testcase. |

The version-26 discriminator ledger is:

| Proposed change | Fairness and distinctness | Expected isolation | Decision |
|---|---|---|---|
| Public `--from-plan --no-gitignore` mismatch | This crosses a separate CLI field-to-controller boundary from `pathAsRoot`; it is explicitly named by the prompt and has an observable zero-request guarantee. | A command-only `no_gitignore=false` mutant should pass the controller mismatch entity and every other focused entity, then fail only the strengthened public CLI option entity. | Add to the existing composed entity; retain test names and census. |
| Proxy snapshot barrier | This changes observation reliability, not candidate behavior or strictness. | The reference and candidates see the same request predicate without scheduler-sensitive sleeps. | Replace the fixed-delay counter implementation; add no test. |
| Classified fallback failure | This reports harness failures honestly while pairing the fallback with a testcase present in successful JUnit. | Test-only compilation failure becomes fail-to-pass rather than skipped or unclassified; combined runs retain the ordinary passing entity. | Replace skipped synthetic output and retain captured diagnostics. |

No public description, reference behavior, compatibility API, dependency, or
Docker artifact needs to change. Editing `test.patch` creates immutable version
26, invalidates version 25's audit, and restarts calibration at 0/10 after
reference, isolated mutation, wrapper classification, patch-integrity,
cross-platform, and false-positive gates are repeated.

## Canonical version-26 revision and exact audit

Version 26 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `f22d253cee5821b686d6112f8c6a979c081349dc6676cd2ff07149d6562dfbae` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:5e5fd4b380bebeebd6f553a23ae7227f0b3e31fa3f6538b30bb4318017aafc7e` |

The existing public CLI option entity now checks both independent stored
controls. Its plan has `pathAsRoot=true` and `noGitignore=false`; omitting
`--path-as-root` fails before another request, and separately adding
`--no-gitignore` while retaining `--path-as-root` also fails before another
request. The proxy obtains each observation through a channel-coordinated
listener drain with a bounded response rather than a fixed sleep.

Fallback JUnit now records nonzero no-JUnit runner outcomes as failures under
test identities that also exist in successful runs. The test-only Linux lane
exits 101 and reports
`railwayapp::deployment_plan_cli::deployment_plan_write_is_offline_deterministic_and_self_excluding`
with the unresolved-import compiler output. This pairs as fail-to-pass and
does not recreate the historical unclassified synthetic `new.run` entity.

Exact isolation:

| Incorrect mode | Other focused tests | Complete pre-existing suite | Strengthened entity |
|---|---:|---:|---|
| In the public apply branch, pass `no_gitignore=false` regardless of `Args::no_gitignore`, while retaining strict controller validation. | 22/22 macOS focused entities outside the CLI option entity pass. | 474/474 pass. | The `--from-plan --no-gitignore` invocation reaches one request and fails the zero-additional-request assertion. |

Exact reference results:

- network-disabled Linux `base`: 474/474;
- network-disabled Linux `new`: 28/28, with zero failures, errors, or skips;
- macOS `base`: 474/474;
- macOS `new`: 23/23;
- test-only network-disabled Linux `new`: exit 101 with one classified
  fail-to-pass entity and the complete compiler diagnostic;
- both patch orders and both full reverse checks: clean;
- patch whitespace, shell syntax, and default-toolchain formatting: pass.

The exact `agent-runs5/Nova_Nova_2` patch was replayed against version 26. It
compiled and passed 19/23 macOS entities, retaining its existing root-marker
and request-ordering failures. The deterministic proxy did not add a private
requirement; it made already queued requests observable without scheduling
sleep. The unchanged reference is the legitimate pass.

The reported upstream-ahead overlap was checked against `origin/master`.
Only `4d82a23` changes `src/commands/up.rs`, adding terminal-control stripping
to three log-printing sites. Current upstream contains no `write-plan`,
`from-plan`, or deploy-plan controller feature, and its changed hunks do not
overlap the reference's planning/reconciliation integration points.

No prompt, reference, explanation, API, dependency, Dockerfile, test name, or
test count changed. Version 26 clears the bounded false-positive and reference
gates and begins a fresh calibration batch at 0/10. All earlier run results are
historical only.

## Version-27 upload-body and snapshot-calibration design gate

Before revising the prompt or grader, the mandatory trajectory, calibration,
and false-positive procedures were rechecked through `AGENTS.md`, the complete
operative policy preserved in `PLAN.md`, the canonical version-26 records in
this file and `FALSE_POSITIVE_AUDIT.md`, and the latest reviewer findings. The
root `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, and worked Statig
reference remain unreadable macOS dataless placeholders: metadata is present,
but direct reads fail with `Operation timed out`. This limitation is recorded
instead of treating an empty read as evidence.

The history search covered the current prompt, reference, grader, repository
map, problem and candidate indexes already summarized by earlier gates, all six
raw `agent-runs7` trajectories, patches, evaluations, logs, and JUnit reports,
and the six corresponding `agent-runs6` artifacts. There is no participant
pass in either batch. `agent-runs7/Nova_Nova_3` is the representative near-pass
at 27/28, and `agent-runs7/Nova_Nova_2` is the widest available failure at
24/28; neither is a behavioral broad failure. The unchanged reference remains
the legitimate implementation side.

All twelve Nova implementations in `agent-runs6` and `agent-runs7` take their
first stability sample from the opened descriptor and therefore accept the
same-size modification injected after the kernel returns `open` but before the
first descriptor metadata call. Two candidates are otherwise complete:
`agent-runs6/Nova_Nova_5` and `agent-runs7/Nova_Nova_3` each pass the other
27 entities. The deterministic barrier reached the requested interval in every
run; the failure marker is `O` (successful planning), not a timeout or an
untriggered fixture.

That evidence changes calibration, not harness reliability. A mutation made at
the open barrier is fully reflected by the first descriptor metadata sample
and by all bytes subsequently read, so treating that sample as the beginning
of the coherent snapshot is a reasonable maintainer contract. Mid-read
changes remain incoherent and security-relevant. Version 27 therefore narrows
the public mutation boundary to changes occurring while the opened file is
being read and retains the deterministic read barrier, independent size and
mode mutations, and atomic-replacement verified-byte oracle. The known
open-first implementations become conforming rather than false positives.

The reviewer also found a distinct CLI integration survivor. The current
controller entity proves that `create_deploy_tarball_from_plan` returns verified
bytes, and the public valid-apply entity proves only that reconciliation reaches
some request. A command can discard the verified archive, later call the
ordinary uploader after project resolution, and still pass every current
assertion. Although all six `agent-runs7` candidates correctly retain the
verified body, this is a repository-natural branch-seam mutation: ordinary
archive construction already occurs after remote project/service resolution in
`commands::up`.

The version-27 discriminator ledger is:

| Evidence | Plausible implementation or valid design | Public invariant | Revised black-box oracle | Decision |
|---|---|---|---|---|
| Twelve consecutive candidates reject mid-read changes but accept the deterministic open-to-first-metadata mutation; two are otherwise 27/28. | Define the coherent snapshot at the first metadata sample from the opened descriptor. | Metadata and bytes must remain stable while the opened file is read for the snapshot. | Retain only the deterministic `read` phase in the modification-metadata entity; keep independent read-phase size/mode and atomic replacement entities. | Narrow prompt and oracle together. Do not weaken synchronization, remove mid-read coverage, or carry the old 0/6 batches forward. |
| The valid CLI apply test counts a connection but never observes `/up` bytes. | Reconcile correctly, discard the returned archive, then rebuild through ordinary upload after remote project resolution. | The bytes reconciled against the plan are the bytes submitted by the public upload command. | A test-only local TLS proxy answers the real project query, changes the same-size source at that post-verification boundary, captures the subsequent `/up` gzip body, and requires the archived file to contain the pre-mutation verified bytes. | Strengthen the existing valid-apply entity. Assert file bytes, not tar stream order, request count, internal helpers, or exact diagnostics. |
| “Plans are source-backed manifests, not portable bundles” is policy framing. | State only the observable current-source and link behavior. | Apply reads the selected local sources; links follow ordinary upload behavior. | Description-only wording cleanup. | Remove the slogan while preserving the concrete requirements. |
| Upstream is six commits ahead and overlaps `commands/up.rs`. | Later upstream log-output edits may conflict mechanically. | The task must not duplicate shipped behavior. | Retain version 26's upstream audit: only terminal-control stripping overlaps the file, with no deploy-plan feature or hunk conflict. | Recheck when landing; no prompt, reference, or grader action. |

The upload-body probe is distinct from the controller archive entity: it crosses
the command-to-network boundary and changes the source only after successful
local verification. The proxy uses the repository's existing develop-mode
invalid-certificate allowance, an isolated self-signed test certificate, and
ordinary HTTP request bodies. It introduces no live service, credentials,
production hook, compression-order rule, or private call-sequence assertion.

Changing `meta.md` and `test.patch` creates immutable version 27, invalidates
version 26's six-run calibration batch, and restarts calibration at 0/10.
Before calibration, the exact reference, discard-and-rebuild mutant, wrapper
classification, full baseline, cross-platform, patch-order, reverse,
formatting, and false-positive gates must be repeated and recorded with the new
artifact hashes.

## Canonical version-27 revision and exact audit

Version 27 has these immutable identities:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715` |
| `test.patch` | `3654aef8c014b318a7c34f98ffa40c3c0157f9bacf5f8e4a1cc6e03dd1ab62ad` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:7a6c1bf366e560afad8405c3a1eb94c0bd01f023a0d606c1b63cafcc2bc09e5e` |

The modification-metadata entity now exercises only the deterministic
mid-read boundary. Independent mid-read size and mode entities remain, as do
unsupported-type and atomic-replacement checks. The public wording now states
the same read-phase boundary and removes the portability slogan.

The existing valid-apply CLI entity now runs against a local TLS endpoint that
answers the actual Railway project query, changes `app.txt` from `content\n`
to equal-length `changed\n` after local verification, captures the subsequent
`/up` request body, and requires the gzip tar to contain `content\n`. The probe
asserts archive content by path and does not constrain tar order, compression
bytes, request counts, or internal helpers.

Exact isolation and replay:

| Implementation | Complete pre-existing suite | Focused suite | Result |
|---|---:|---:|---|
| Reference | 474/474 | 28/28 Linux; 23/23 macOS | Legitimate pass. |
| Discard verified body and rebuild through ordinary upload | 474/474 | 27/28 | Only the strengthened valid-apply entity fails with archived `changed\n`. |
| Exact `agent-runs7/Nova_Nova_3` | 474/474, with 11 task self-tests filtered | 28/28 | Representative participant pass after retiring the open-phase overconstraint. |

The test-only Linux lane exits 101 and reports one classified failure with the
complete unresolved-controller diagnostic and zero skips/errors. Both patch
orders, both full reverse checks, applied-tree whitespace checks, shell syntax,
and default-toolchain formatting pass. The baked network-disabled Linux image
passes 474/474 base and 28/28 new; exact macOS passes 474/474 base and 23/23
new.

No actionable survivor remains in the attempted version-27 mutation set. The
former post-open-first-sample implementations are conforming alternatives, not
survivors. Version 27 clears the bounded false-positive gate and begins a fresh
immutable calibration batch at 0/10; no version-26 run carries forward.

## Version-28 verifier-assembly design gate

The user reopened the bundle after `agent-runs8/Nova_Nova_6` was classified as
environment-blocked. Before changing `test.patch`, the startup, calibration,
and false-positive requirements were rechecked through `AGENTS.md`, the
operative policy retained in `PLAN.md`, the version-27 audit above, and all six
`agent-runs8` evaluations, JUnit reports, test logs, solution patches, and
representative raw trajectories. The root `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` remain macOS dataless placeholders: their metadata is
visible, but direct reads fail. This limitation is recorded rather than
silently treating the files as empty.

Every `agent-runs8` post-agent log reports that the verifier's three-way
`test.patch` merge failed and that all six test-owned paths were reset to the
pinned base before the test patch was reapplied. For the first five candidates,
that destructive fallback happened not to remove a candidate manifest edit.
Nova 6 legitimately added `libc = "0.2"` to `Cargo.toml` and the corresponding
root-package dependency in `Cargo.lock` so it could open unsupported inputs
without blocking. The fallback replaced `Cargo.toml` with the grader version
that adds only `deployment-plan-tests`, while retaining the candidate's
`Cargo.lock`. `cargo metadata --locked --offline` then rejected the inconsistent
workspace before test discovery, and the wrapper synthesized 474 baseline plus
28 feature failures.

This is a verifier-assembly false negative, not a hidden behavioral
discriminator. Replaying the exact Nova 6 patch with both manifest edits
preserved reaches the focused suite and passes 25/28; its remaining failures
are ordinary root-marker and CLI source-resolution defects. The replay proves
both that the published 0/502 result is invalid and that correcting assembly
does not convert this candidate into an accidental pass.

The version-28 assembly ledger is:

| Evidence | Plausible participant change | Required invariant | Proposed isolation | Decision |
|---|---|---|---|---|
| The grader adds a Cargo feature solely to hide its tests from the baseline lane. | Add or reorder a direct dependency in `Cargo.toml` and update `Cargo.lock`. | Grader assembly must preserve legitimate participant manifest and lockfile edits. | Replace the Cargo feature with a test-only compiler cfg supplied by `test.sh`; remove `Cargo.toml` from `test.patch`. | Prototype and adopt only if base/new selection, nextest fallback, and JUnit classification remain exact. |
| The destructive fallback ran in all six trajectories but corrupted only Nova 6. | Modify any grader-owned file for a legitimate implementation reason. | A candidate must not fail before discovery because an unrelated grader hunk overwrote its changes. | Reduce the grader-owned overlap set rather than special-casing `libc` or modifying the reference. | Treat Nova 6 as the concrete supported boundary; do not add dependency restrictions to the prompt. |
| A correctly assembled Nova 6 still fails three public requirements. | Interpret the blocked run as a likely hidden pass. | Environment repair must not weaken behavioral coverage or alter grading classification. | Replay the candidate after the cfg revision and require the same 25/28 behavioral result. | Preserve all 28 entities and their assertions. |
| The opened-descriptor regular-file clause lacks a dedicated type-race probe. | Trust pre-open metadata and omit an opened-descriptor type check. | Opened selected inputs must be regular files. | All six run-8 implementations already inspect the opened descriptor; the reference does too. | Record as a low theoretical gap. Do not add a new Linux interposition race without a trajectory-supported survivor. |

Changing the grader-selection mechanism creates a new immutable test artifact
even though the prompt, reference, and behavioral entities remain unchanged.
Version 28 therefore restarts calibration at 0/10. Before it can be approved,
the reference, test-only lane, both test runners, both patch orders and reverse
checks, Nova 6 assembly replay, representative legitimate replay, existing
discard-and-rebuild mutant, platform lanes, and exact false-positive audit must
be repeated.

## Version-28 exact verifier and false-positive audit

The grader-only Cargo feature was replaced by the checked compiler cfg
`deployment_plan_tests`, supplied by `test.sh` only in `new` mode. The wrapper
appends both `--check-cfg=cfg(deployment_plan_tests)` and, for the focused lane,
`--cfg deployment_plan_tests` to any participant `RUSTFLAGS`. Neither patch
application nor fallback assembly now owns `Cargo.toml`.

The exact reference assembled from the pinned base passes 474/474 baseline and
28/28 focused tests in a network-disabled Linux container. Hiding nextest
exercises the cargo fallback and runs the same 20 controller plus 8 CLI
entities. The exact macOS lanes pass 474/474 baseline and 23/23 focused tests.
The test-only lane fails before feature execution and its fallback
JUnit records a failure with exit status 101 and preserves the compiler
diagnostics; it does not misreport the runner error as a skip. Both patch
orders apply, pass `git diff --check`, reverse cleanly, and return the worktree
to the pinned base. The clean Linux arm64 image identity is
`sha256:2cf635768bb6cecda709bae108d7f095cacae388fa1b345a39eb1111f18e834e`.

The exact blocked Nova 6 assembly now preserves its `libc` manifest edit,
passes locked/offline Cargo metadata, reaches all 28 feature tests, and reports
25/28. Its three real failures are unchanged: the punctuation-before-root
ordering boundary and two CLI source-resolution cases. Thus the repair removes
the synthetic 502 failures without granting an accidental pass.

The existing discard-and-rebuild mutant still reaches all tests and passes
27/28, failing only the public valid-apply upload-body oracle because the
archive contains post-verification bytes. The representative Nova 3 patch
preserves the baseline and reaches 27/28 on this exact version; it fails the
same later-added upload-body integration boundary rather than assembly or
discovery. The unchanged reference remains the legitimate complete
implementation for the exact artifact.

No behavioral probe was added for the opened-descriptor type observation.
Repository evidence, the reference, and all six run-8 implementations already
validate the opened descriptor as regular. There is no plausible surviving
implementation supported by the trajectories, and a second Linux replacement
race would add scheduler cost without a distinct discriminator.

## Version-29 explicit-project fairness gate

Before revising the grader, attempts to read `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` again timed out because both workspace files remain
compressed dataless placeholders. The current review, the version-28 artifacts,
the historical source-root ledger, and the pinned `commands/up.rs` validation
were inspected directly.

The reviewer identified one unfair value-pinning assertion. The public CLI
fixture required `railway up --project explicit-project --write-plan ...`
without `--environment` to succeed. The prompt requires ordinary-upload source
selection but never authorizes planning mode to relax the existing
project/environment selector validation. The pinned command explicitly rejects
`--project` without `--environment`, so the success assertion conflicts with
repository evidence. The historical version-10 ledger's statement that an
environment was unnecessary was an unsupported design choice, not a public
contract.

The version-29 discriminator decision is narrow:

| Evidence | Invalid hidden expectation | Public behavior that remains tested | Revision |
|---|---|---|---|
| Prompt does not grant a selector-validation exception; pinned ordinary `up` requires an environment with an explicit project. | Offline write must accept explicit project without environment. | Supplying an explicit project selects the current directory as the local source base; write is offline; apply uses the same base and verifies before requests. | Add `--environment explicit-environment` to the existing explicit-project write invocation. Keep the plan-path assertions, request boundary, apply checks, entity name, and test census unchanged. |

No prompt or reference change is required. The revision removes an
unauthorized success case without weakening the linked, explicit-project,
project-token, or environment-variable root discriminators. Because
`test.patch` changes, version 29 starts at calibration 0/10 and requires the
exact reference, test-only, runner, patch-integrity, candidate-assembly, and
false-positive gates again.

The exact audit confirms that conclusion. The network-disabled Linux reference
passes 474/474 baseline and 28/28 focused tests; isolated macOS passes 474/474
and 23/23. With nextest hidden, the Linux Cargo fallback passes the same 20
controller plus 8 CLI entities. Test-only mode exits 101 and writes
failure-classified JUnit with the unresolved-controller diagnostic. Both patch
orders apply and reverse cleanly. Nova 6 preserves its manifest edit, passes
the baseline, and remains 25/28 with the same three public defects. The
discard-and-rebuild mutant passes all 474 regressions and remains 27/28,
failing only the verified public upload-body oracle.

The version-29 artifact identities are:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715` |
| `test.patch` | `d48876ff5cb1c73bec776eab3fb15e7f1adccc2941fb5a71288f7b7c6b6b23d4` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f` |

## Version-30 I/O-mechanism fairness design gate

The user reopened the grader after an external fairness adjudication identified
four Linux snapshot entities as implementation-coupled. Before editing the
prompt or `test.patch`, the mandatory startup and false-positive gates were
repeated against the current version-29 artifacts, the operative policy
retained in `AGENTS.md`, `PLAN.md`, and the prior exact audits, the version-29
requirement map, all `agent-runs6`, `agent-runs7`, and `agent-runs8` solution
patches, representative raw trajectories and evaluations, and the current
reference implementation. The root `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, and the worked Statig false-positive record remain
macOS compressed dataless placeholders whose direct reads time out. That
environment limitation is recorded explicitly; their mandatory rules are
available through `AGENTS.md` and the already recorded operative gates rather
than being treated as empty.

All eighteen reviewed run-6 through run-8 implementations use Rust
`Read::read_to_end`, and the reference does likewise. That trajectory pattern
explains why the current interposer discriminated among observed candidates,
but it does not establish a public I/O contract. The hidden harness compiles a
C shared object, injects it with `LD_PRELOAD`, intercepts `open*`, and blocks
only after a positive call to the libc `read` symbol. A correct implementation
using `pread`, `mmap`, io_uring, or another descriptor-backed snapshot can
avoid that symbol completely. It then fails by the harness's 30-second barrier
timeout before the semantic outcome is observed.

The version-30 discriminator ledger is:

| Public requirement or evidence | Plausible implementation mode | Existing oracle | Fairness decision |
|---|---|---|---|
| Planning rejects unsupported selected objects. | Inspect metadata from the opened object using any platform API. | Selected Unix socket planning returns an error through the public CLI; broken links fail in ordinary and plan modes. | Retain. It observes the public result and does not constrain how bytes are read. |
| Persisted file content and metadata agree at an ordinary stable point in time. | `read`, `pread`, `mmap`, or another coherent local snapshot strategy. | Plan digests, sizes, modes, deterministic serialization, and later reconciliation are checked on stable fixtures. | Retain the stable-fixture oracles. |
| Applying a plan never uploads bytes different from the locally verified bytes. | Buffer verified bytes, retain an open descriptor, or safely reject detected replacement. | The public valid-apply TLS fixture mutates the pathname after local verification, captures `/up`, decodes the request tar, and requires the verified old bytes. | Retain. This is the strongest implementation-independent byte-integrity oracle. |
| Modification metadata, size, or mode changes during an in-progress snapshot must be detected. | Implement with libc `read`, `pread`, `mmap`, or another valid reader. | Three tests reach the mutation only through an undisclosed libc `read(2)` interposer. | Retire the tests and the matching participant-facing sentence. The result cannot be triggered deterministically without prescribing an I/O mechanism. |
| Atomic pathname replacement during controller snapshotting may reject or use old verified bytes. | Any coherent or conservative descriptor strategy. | One test reaches replacement only through the same libc `read(2)` interposer. | Retire this controller race entity. The command-level captured-upload oracle independently enforces the public verified-byte guarantee without a private syscall. |

Hooking additional named syscalls was rejected because it would enumerate more
private implementations rather than make the probe behavioral. A large-file
concurrent writer was rejected because it restores scheduler and timing
flakiness. FUSE, ptrace, or a production test hook were rejected because they
add privileged infrastructure or prescribe an architecture not required by
the feature. Marking the four tests ignored was also rejected because the new
lane permits no skips.

Version 30 therefore removes the complete C interposer/child-process harness
and its four Linux entities, and removes the untestable mid-read
size/mode/modification rejection sentence from `meta.md`. It does not weaken
strict plan validation, stable metadata recording, content reconciliation,
unsupported-type rejection, pre-network ordering, or the public verified
upload-body guarantee. The reference may continue to perform stronger
descriptor stability checks as a conservative implementation detail.

The exact cargo-fallback audit then exposed a separate wrapper defect retained
from version 29: when `cargo test` succeeded without producing nextest JUnit,
`write_fallback_junit` synthesized one failing testcase with exit status zero.
Version 30 corrects that reporting path by translating every standard
`test ... ok|FAILED|ignored` result into JUnit, preserving the complete focused
test census and the real failure/skip counts. Runs that fail before discovering
any test still receive one failure-classified runner record with escaped
diagnostics. This is reporting integrity only; it adds no participant
predicate.

Because both prompt and grader change, version 30 is a new immutable problem
version at calibration 0/10. Before approval it requires: clean patch
application in both orders; complete reverse checks; focused reference and
test-only lanes; full baseline regression; cargo-fallback parity; replay of a
legitimate candidate; replay of the discard-and-rebuild upload mutant; and an
exact requirement-to-oracle and alternative-I/O fairness audit with new
artifact hashes.

## Version-30 exact verification and fairness audit

The exact artifact completed the required gates. The reference passes 474/474
macOS baseline tests, 23/23 macOS focused tests, and 24/24 focused tests in the
network-disabled Linux arm64 image. The cargo-test fallback reports all 23
macOS focused cases in JUnit with zero failures, errors, or skips. Test-only
mode exits 101 and reports one failure with the unresolved-controller
diagnostic and zero skips. Both patch orders apply and reverse cleanly, the
applied trees pass whitespace checks, and the regenerated test diff has the
same hash as the canonical artifact.

The exact discard-and-rebuild mutant passes all 474 baseline tests and 22/23
macOS focused tests; only the captured public upload-body entity rejects it.
A version without mid-read modification/mode stability checks passes 474/474
and 23/23 because that implementation is now conforming. A Unix
`FileExt::read_at`/`pread` reference variant passes 23/23, demonstrating that no
hidden barrier waits for libc `read`. The exact
`agent-runs7/Nova_Nova_3` participant patch passes 474/474 baseline and 23/23
focused tests.

The final identities are:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f` |
| `test.patch` | `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux reference base image used with exact source binds | arm64 `sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f` |

No actionable survivor remains in the bounded version-30 mutation set. The
remaining external-tool assumption is the already exercised `python3` and
`openssl` pair used by the public upload-capture fixture; the C compiler,
dynamic interposition, `/proc` descriptor polling, fixed read syscall, and
large race payloads are gone. Version 30 clears the exact false-positive and
fairness gates and remains at calibration 0/10.

## Version-31 external-verifier reference-hardening gate

An external solution-verification pass reported 474/474 baseline and all 24
visible Linux focused entities passing, then synthesized four additional
snapshot/atomic-replacement failures. Its concrete code finding was narrower:
`read_file_snapshot` compares pathname metadata before `File::open` and
descriptor metadata after reading, but never proves that the pathname still
resolves to that opened object. This is not evidence that the removed
libc-`read(2)` barriers should return. The current prompt and focused tests
intentionally allow independent `read`, `pread`, `mmap`, and conservative
rejection strategies.

The trajectory and repository evidence already recorded for versions 27-30
remains controlling: reviewed candidates differ in their I/O mechanism; the
ordinary uploader is pathname based; the reference snapshots descriptor bytes;
and the public upload-capture entity is the implementation-independent oracle
for verified bytes. The new verifier feedback adds one reference-robustness
boundary but no fair participant discriminator.

The version-31 ledger is:

| Boundary | Candidate/reference mode | Decision |
|---|---|---|
| Opened bytes remain coherent if a pathname is replaced. | A participant may retain the opened object, safely reject replacement, or otherwise guarantee that uploaded bytes are the verified bytes. | Keep the participant contract and hidden suite unchanged. Do not restore syscall barriers or require pathname-identity rejection. |
| The supplied reference should satisfy conservative synthesized probes. | After reading, compare the followed pathname with the opened descriptor using stable filesystem identity where the standard library exposes it; reject a missing or different object. | Harden `solution.patch` only. This is stricter permitted behavior, not a new public requirement. |
| Stable paths, followed symlinks, and non-Unix builds. | Identity comparison must follow the same link target as `File::open`, preserve ordinary stable symlinks, and compile with an explicitly defined fallback on other targets. | Verify Unix behavior dynamically and compile-check supported conditional branches where available. |
| Fairness and false-positive risk. | A stronger reference must not turn its private strategy into a hidden oracle or alter the discriminator set. | Leave `meta.md` and `test.patch` byte-identical; repeat the exact reference, legitimate-alternative, upload mutant, patch-order, and artifact-hash audits. |

No test edit begins from this gate. Version 31 will be a reference-only
hardening revision if the identity check passes the unchanged complete suite.
Any reference or explanation change creates a new immutable version at
calibration 0/10.

## Version-31 exact verification and fairness audit

The reference now inspects the followed pathname after reading. On Unix it
requires that the pre-open pathname, opened descriptor, and post-read pathname
share device and inode identity. A missing or different object returns an
error. The fallback branch retains the existing portable metadata comparison.
The public description and test patch are byte-identical to version 30.

The exact macOS reference passes 474/474 baseline and 23/23 focused tests.
Cargo fallback with nextest hidden reports 23/23 with zero
failures/errors/skips. Test-only mode exits 101 with one diagnostic failure and
zero skips. Both patch application orders and reversals are clean, and the
production diff regenerated from the tested tree has exactly the canonical
solution-patch hash.

Two isolation probes establish the fairness boundary:

- removing only the new pathname-identity check still passes 23/23 focused
  tests, so the reference strategy is not a hidden participant requirement;
- discarding the verified body and rebuilding through ordinary upload passes
  474/474 regressions but only 22/23 focused tests, failing the captured public
  upload-body entity.

A temporary unshipped helper probe confirms that same-size atomic replacement
changes Unix identity while a stable followed symlink retains the target
identity. A stale-binary result from a reused worktree was excluded: its source
contained the plan flags while its executable rejected them. The authoritative
probes rebuilt in the exact tested worktree.

The final version-31 identities are:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f` |
| `test.patch` | `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Docker Desktop did not answer its socket for a redundant local Linux rerun, so
none is claimed. The byte-identical version-30 grader had passed 24/24 in the
network-disabled Linux image, and the supplied external verifier independently
reports all 24 visible Linux entities passing before its synthesized reference
analysis. No test was added, removed, skipped, or coupled to the new identity
strategy. Version 31 clears the bounded false-positive and fairness gates and
starts calibration at 0/10.

## Version-32 Harbor valid-apply transport gate

Harbor reported that the reference failed
`deployment_plan_valid_apply_continues_after_local_verification`. Before
editing `test.patch`, the mandatory design evidence was revisited: the
version-30 and version-31 gates and requirement map, all available run-8 test
logs, the raw Nova 1 run-8 trajectory, the current upload-capture fixture, the
exact reference implementation, and the exact current macOS and Linux test
trees. The root `PROBLEM_DESIGN.md` remains a compressed dataless file whose
direct reads time out; the operative rules in `AGENTS.md` and the previously
recorded gates were therefore used, and the failed read was not treated as an
empty policy.

The exact current test passed on macOS and in a fresh Linux container, but a
same-container Linux repetition reproduced Harbor's failure on attempt 8 after
seven passes. The command returned `FETCH_ERROR` for the first GraphQL request.
No source or reference change occurred between repetitions. Historical run-8
logs also show the entity passing, so this is a test-transport intermittent
failure rather than a solver discriminator.

The embedded Python proxy reads the plaintext `CONNECT` request through a
buffered `socket.makefile("rb")` and then hands the underlying socket to
`ssl.wrap_socket`. The buffered reader may consume bytes beyond the CONNECT
header, including the beginning of the client's TLS handshake, leaving those
bytes unavailable to the TLS layer. The proxy catches the resulting SSL or
connection exception and closes the connection, producing the observed
`FETCH_ERROR`. Its keep-alive loop also permits an idle first connection to
delay acceptance of a later upload connection.

The version-32 ledger is:

| Evidence | Public invariant | Proposed fixture repair | Discriminator decision |
|---|---|---|---|
| Exact reference intermittently fails before the capture proxy answers GraphQL. | A valid locally reconciled apply must continue and upload the already verified archive bytes. | Read CONNECT without buffering past the header, answer each tunneled HTTP request with `Connection: close`, and accept the next connection independently. | Repair transport only; keep the request mutation, captured archive assertion, command invocation, and participant-facing requirement unchanged. |
| The discard-and-rebuild mutant is killed only when the captured upload contains post-verification bytes. | Uploaded bytes must equal the verified snapshot. | Replay the mutant after the transport repair. | Retain this distinct public oracle; do not weaken it to connection counting. |
| Run-8 candidates and the exact reference use different deployment-plan implementations but all reach this fixture. | The grader must not require a private networking or snapshot implementation. | Stress the exact test repeatedly in Linux and replay a legitimate participant patch. | No new predicate, error text, request count, or internal API assertion is added. |

Because `test.patch` will change, version 32 is a new immutable problem version
at calibration 0/10. Approval requires repeated Linux stress, the complete
focused and baseline suites, cargo-fallback and test-only reporting, patch
application/reversal, the discard-and-rebuild mutant, a representative
legitimate candidate replay, and a fresh exact false-positive/fairness record.

## Version-33 root-order clarification gate

The version-32 prompt and repaired proxy were calibrated against four Nova and
four Orion trajectories in `agent-runs9`, `agent-runs10`, and `agent-runs11`.
Before revising the prompt, their evaluations, JUnit reports, test logs,
solution patches, and representative raw trajectories were inspected. The
root `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` remain compressed
dataless files whose direct reads time out; the operative startup,
false-positive, and immutable-batch rules in `AGENTS.md` and the recorded
design history therefore remain controlling.

All eight implementations preserved the complete 474-test regression suite.
Every implementation failed
`deployment_plan_service_prefix_and_path_as_root_modes_are_preserved`; six
passed 23/24 focused tests, while two Nova implementations had one or two
additional CLI sequencing/root-resolution failures. The common defect was
structural rather than environmental: after globally sorting archive paths,
each implementation treated `entries[0]` or `sources.first()` as the selected
root. The raw Orion trajectory explicitly described a shared selector and
strict validation, then its patch validated only the first sorted entry. The
Nova and Orion patches independently repeated the same positional assumption.

The existing contract states both that entries are globally sorted by
normalized UTF-8 archive path and that the archive-root marker is `"."`.
Those clauses logically permit an ordinary archive path such as
`"-hello.txt"` to precede the marker, so the existing test remains fair.
However, eight independent near-passes show that the interaction is an
overwhelming wording trap rather than a varied discriminator. Retaining it
without clarification would make the measured solve rate depend primarily on
one positional inference after candidates had already implemented the much
broader plan lifecycle.

The version-33 discriminator ledger is:

| Trajectory evidence | Public invariant | Revision | Decision |
|---|---|---|---|
| Eight implementations globally sort entries and then validate the root only at index zero. | The selected-root record is an ordinary member of the global path ordering. | Add one sentence stating that the root record participates in the same ordering and need not be first. | Clarify the existing schema interaction without naming the `-hello.txt` fixture, candidate code, test name, or a required implementation. |
| Six implementations otherwise reach 23/24; four Orion runs fail only this case. | The task should discriminate across source selection, strict I/O, reconciliation, byte integrity, and request ordering rather than one shared sentinel assumption. | Leave every test and reference behavior unchanged. | Preserve the oracle and all other discriminator families while reducing accidental ambiguity. |
| Version-32 valid-apply transport passes all eight calibration runs after the readiness repair. | The captured upload must contain verified bytes. | Keep the repaired `test.patch` byte-identical. | The Harbor transport defect is resolved and unrelated to the prompt clarification. |
| The prior apply-time broken-link/unsupported/non-UTF-8 warning produced no surviving candidate. | Distinct public failure families merit probes; redundant permutations do not. | Add no tests for those permutations. | All eight patches share selection between planning and applying; the existing suite already covers apply-time path/type change plus planning-time selection errors. |

Only `meta.md` changes functionally in version 33. `test.patch`,
`solution.patch`, `solution_approach.md`, and `Dockerfile` remain byte-identical.
The revision invalidates all version-32 calibration results and restarts the
batch at 0/10. Exact reference, regression, cargo-fallback, test-only,
patch-order, false-positive, and fairness checks must be repeated before the
new batch begins.

## Version-33 exact verification and false-positive audit

The required gates were repeated against fresh synthetic pinned-base clones.
Both patch orders applied without offsets, passed `git diff --check`, and
reversed to the same clean base tree
`1b864ae1475cd7b8dc7dabe5a337ddf615bc3e32`. The synthetic commit wraps the
upstream Railway base `4d49d9845a27a0947ab903b01789eb9f854414d8`.

The exact reference ran in the arm64 Linux image
`sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f`
with external networking disabled. The nextest lanes produced 474/474
baseline and 24/24 focused passes, with zero failures, errors, or skips. With
nextest hidden, the cargo fallback produced 24/24 JUnit passes and zero skips.
The test-only lane exited 101 and produced one classified JUnit failure,
retaining the unresolved `controllers::deploy_plan` import instead of
misreporting a skip.

The fresh discard-and-rebuild command mutant completes local plan
reconciliation but throws away the returned archive and invokes the ordinary
path-based archive builder after remote project resolution. It passes all 474
pre-existing tests and 23/24 focused tests. Only the captured public upload
body rejects it: the tar contains `changed\n` rather than the reconciled
`content\n`. This is the strongest remaining repository-natural shortcut and
confirms that the version-32 proxy repair preserved its distinct
discriminator.

The eight version-32 solver reports are valid failing-patch replays for the
byte-identical grader: all eight baseline JUnits are 474/474; every focused
JUnit fails root-position independence; four Orion runs fail only that entity.
Their patches and the reference were inspected, establishing independent
implementations of the same positional-root shortcut. No passing solver patch
exists for this exact grader, so the clean reference is the legitimate
implementation replay. Prompt prose cannot affect compiled results, and no
test or reference change was made merely to manufacture a new replay.

The complete requirement map and bounded mutation decisions are recorded in
`FALSE_POSITIVE_AUDIT.md`. In particular, no test was added for arbitrary
punctuation variants or apply-only broken-link/socket/non-UTF-8 permutations.
Those proposals contribute no trajectory-supported semantic boundary beyond
the current root-position, source-selection, and apply-time type/path-set
oracles.

The immutable version-33 identities are:

| Artifact | SHA-256 / identity |
|---|---|
| Railway base tree | `1b864ae1475cd7b8dc7dabe5a337ddf615bc3e32` |
| `meta.md` | `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd` |
| `test.patch` | `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

Version 33 clears the exact reference, harness, patch-integrity,
false-positive, and implementation-fairness gates. Calibration remains 0/10;
no version-32 run carries forward.

## Acceptance and archival closure

The user confirmed platform acceptance on 2026-07-29. Canonical version 33 is
therefore frozen at the identities above. No post-acceptance prompt, grader,
reference, explanation, or image change was made.

Cleanup preserved the complete readable trajectory corpus as
`archive/railway-deployment-bundle/agent-runs.tar.gz`. The archive contains
304 members, was listed successfully after creation, and has SHA-256
`98b72b6066cc0889e47c375524797a8fb27a6d3b29f6a5c894170faba831361c`.
Its exact member list has SHA-256
`0652deb7402bf5576252e20d94fbea92ada1a52f1f2f60165634587cb509ed34`.

Another 112 older trajectory files and six retired prototype files were
macOS iCloud placeholders whose backing objects no longer existed. Repeated
absolute-path `brctl download` requests returned Cocoa file-not-found errors.
Their paths, logical sizes, timestamps, and filesystem flags are preserved in
the archive inventories, and the unresolved placeholders themselves remain
under the archive's two `*-placeholders/` trees. No claim is made that their
missing bytes are recoverable.

The disposable pinned worktree was not retained because the accepted state is
fully reconstructible from base
`4d49d9845a27a0947ab903b01789eb9f854414d8` plus the canonical patches.
`archive/railway-deployment-bundle/WORKTREE_MANIFEST.md` records that
decision and the reconstruction commands. `RUNS.md` is the compact active
index for the archived batches.
