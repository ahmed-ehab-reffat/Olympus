# DESIGN - SQLSync observed mutation progress

Status: **version 27 trajectory-informed observation/routing revision is
verified in the normal lanes; calibration is 0/10 and the intentionally
deferred false-positive audit is pending**.

Repository: `orbitinghail/sqlsync`

Pinned commit: `7dc1af6b082023982fd2697f913f5b27453747f1`

Production language: Rust, with the public browser surface bridged through
Rust/Wasm and TypeScript.

Task type: feature request.

## Redesign boundary

The first 2026-08-01 screen rejected issue #31 at 4/10 because "current sync
state" combined database enumeration, timeline transfer, coordinator
application, and awaiting a mutation without defining identity, observation
boundaries, or reconnect behavior. That rejection remains recorded in
`candidates/GATCHA_CANDIDATES_2026-08-01.md`.

The retry removes waiting, server-current-state claims, and subscribed-database
enumeration. It asks for one source-backed capability: expose an **observed
per-document mutation progress snapshot** and return a stable receipt when a
local mutation is accepted.

The public values are:

- `MutationReceipt { timeline_id, lsn }`, identifying the exact local timeline
  entry appended by one successful mutation;
- `SyncState { timeline_id, local, received, applied }`, where every progress
  field is an optional inclusive LSN watermark; and
- receipt classification as local, received, or applied, with applied taking
  precedence and a receipt from another timeline or the future remaining
  unrelated.

The watermarks are deliberately conservative:

1. `local` is the greatest LSN allocated by the local timeline, even if its
   retained prefix was later dropped;
2. `received` is the greatest LSN in the latest range acknowledgement actually
   observed from the coordinator for that timeline; and
3. `applied` is the greatest coordinator-application LSN visible in the local
   SQLite copy after storage replication and rebase.

A snapshot is local knowledge. Disconnection does not make it an error and it
does not imply newer coordinator state. The feature does not promise an await
operation.

## Repository-supported semantics

- `LocalDocument::mutate` applies a mutation and appends it to the local
  timeline. `Journal::range` and `LsnRange::next` identify the allocation.
- `ReplicationProtocol` receives `ReplicationMsg::Range` after destination
  writes. Retaining that range reports acknowledgement without changing the
  wire protocol.
- `apply_timeline_range` updates `__sqlsync_timelines(id, lsn)` in the same
  SQLite transaction that applies reducer changes. Coordinator storage is
  committed only after this succeeds.
- Those SQLite storage frames replicate to the local document and
  `LocalDocument::rebase` makes the row locally visible.
- `LsnRange::Empty { nextlsn }` retains historical progress after prefix
  removal. The correct watermark is `nextlsn - 1`, not `last()`.
- The existing worker request/reply channel and `SQLSync.mutate` are the public
  browser seam. A complete implementation crosses the core, Wasm, and
  TypeScript boundaries.
- Arbitrary Rust `u64` LSNs cannot be represented losslessly by JavaScript
  `number`; the disposable implementation used decimal strings, but any
  documented lossless public representation is valid.
- The existing four-case connection-status API remains unchanged. Sync
  progress is a separate value.

## Trajectory-informed startup gate

The mandatory gate was completed before the disposable implementation or test
assertions were written.

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the original Gatcha report, and active/archive
records for sync state, replication, reconnect, acknowledgements, mutation
identity, timeline persistence, checkpoints, replay, partial progress, and
validation/commit timing. RustPBX redesign and Calyx checkpoint records were
read for reconnect-cache and reconstruction shortcuts. Statig and str0m compact
records and manifests were read. No SQLSync trajectory exists.

Representative raw Statig evidence was read directly from
`archive/statig-local-transitions/agent-runs.tar.gz` with `tar -xOf`:

| Role | Run | Outcome | Architecture and lesson |
|---|---|---|---|
| Legitimate pass | `agent-runs4/Nova_Nova_4` | 23/23 baseline, 26/26 focused, 62 platform steps, 285 strict effective production changes in six files | Carried private accepting-handler provenance through separate blocking and awaitable paths and consumed it at the transition boundary without expanding the public enum. Identity must travel with progress. |
| Near-pass | `agent-runs5/Nova_Nova_3` | Baseline passed, 25/27 focused, 60 steps, 400 effective changes in six files | Stored an absolute pre-handler depth; a hierarchy mutation changed its meaning before consumption. Correct-looking state sampled at the wrong boundary is unsafe. |
| Broad failure | `agent-runs5/Nova_Nova_1` | Baseline passed, focused crate failed to compile, 60 steps, 445 effective changes in seven files | Added an internal-only sixth public `Outcome` variant and broke downstream exhaustive matches. Private progress must not break a stable public status enum. |

The ten str0m solvers converged on one validation-before-commit file despite
many fixtures, so repetitions of one progress comparison are not independent
depth. RustPBX's reconnect/idempotency direction collapsed to a conventional
cache once existing command identity was recognized. Calyx established that
reconstruction from retained inputs and observed progress is legitimate.
Accordingly, this task permits range/row reconstruction and cannot require a
particular duplicated private tracker.

## Discriminator ledger

| Evidence / plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Store one process-global counter without timeline provenance. | Receipt and snapshot values belong to one timeline identity. | Two timelines may both issue LSN 0; progress for one must not classify the other's receipt. | Cross-document identity | Maps, owned fields, embedded IDs, or reconstruction all pass if identities remain isolated. |
| Treat upload acknowledgement as coordinator application. | Received advances on an observed range acknowledgement; applied advances only after coordinator apply/commit returns through storage replication and rebase. | Observe one receipt locally, after upload but before coordinator work, and after the storage round-trip. | Acknowledgement versus commit | Exercises existing protocol order and does not prescribe storage layout. |
| Expand `ConnectionStatus` with sync cases. | Connection compatibility remains intact and progress is separate. | Compile existing exhaustive Rust/TypeScript consumers while using the new API. | Public API compatibility | Internal carrier choices are unrestricted. |
| Use retained-entry presence as all-time progress. | An empty-following range still represents every LSN before `nextlsn`. | Fully apply and rebase a one-entry timeline; its receipt remains classifiable. | Journal GC/rebase | Follows the existing range model, independent of journal implementation. |
| Preserve a stale acknowledgement forever or reset every fact on disconnect. | State reflects the latest peer range actually observed; a fresh handshake can revise it without claiming server durability. | Disconnect with known progress, reconnect to a different peer range, and observe the refreshed snapshot. | Reconnect freshness | Cache ownership and reconstruction remain implementation choices. |
| Convert LSNs to JavaScript numbers. | Identity is exact across the Wasm/TypeScript boundary. | Round-trip a value above `2^53` through the generated public type and serializer. | Language precision | BigInt, decimal text, or another documented lossless shape is allowed. |
| Report a future LSN or another timeline as local merely because its number is small. | Classification requires identity and a locally allocated upper bound. | Compare same-number foreign receipts and future receipts with a snapshot. | Receipt validity | Tests observable provenance, not a private lookup structure. |

## Requirement-to-prototype coverage

These were design gates recorded before hidden-test authoring, not the final
test inventory.

| Requirement | Disposable observation | Result |
|---|---|---|
| Successful mutation returns exact identity | Two core mutations return the appended timeline ID/LSN | Passed |
| Local, received, and applied remain distinct | The in-process replication example asserts each stage in sequence | Passed |
| Empty-following range retains progress | Unit probe derives `nextlsn - 1` after full prefix removal | Passed |
| Foreign/future receipts are unrelated | Core classification probes both cases | Passed |
| Existing connection API remains compatible | No connection variant was added; full workspace and worker builds compile | Passed |
| Browser LSN is lossless | Generated declaration is `type Lsn = string` and receipt/state fields use it | Passed |

## Disposable architecture and measured scope

The cheapest complete prototype changed 12 source/example files: timeline
append returns its LSN; range objects expose retained-prefix-aware watermarks;
the replication protocol retains its latest destination range; local state
reads the replicated `__sqlsync_timelines` row; the Wasm worker carries
receipt/snapshot replies; and TypeScript exposes `mutate` receipts plus
`syncState`.

It measured 340 raw additions and 15 deletions. A simple strict counter found
211 nonblank/non-comment/non-brace additions across the production-file set,
but that figure includes Rust tests embedded in production files and therefore
is **not** a solver production-LOC prediction. Per `PROBLEM_DESIGN.md`, it is a
low-confidence architectural scope signal only. The prototype diff SHA-256 is
`4da4c422692d52b7ebfef933204ed58332ca3195ad0036147481173cda52f83b`.

## Verification and environment result

The official Rust base was pinned by digest
`sha256:211a2e3aeff24b410f2c982723e9314992833f4633c764217eab87552f1d1477`.
The reproducible x86_64 lane used Rust 1.91.1, Just 1.43.1, wasm-pack 0.13.1,
pnpm 9.15.9, Node, Clang, and the committed Cargo/pnpm locks.

- Pristine x86_64: `just build`, `just test`, and
  `just package-sqlsync-worker dev` passed. The same intended lane passed after
  networking was disabled; core baseline was 18/18.
- Prototype x86_64: `just build`, full `just lint`, full `just test`, worker
  packaging, and explicit offline core tests passed. The core is 23/23 and both
  replication examples pass, including the three-stage assertions.
- The final network-disabled replay exited 0 on 2026-08-01 for lint, full tests,
  worker packaging, and `cargo test --offline --locked -p sqlsync --lib`.
- Prototype image ID:
  `sha256:ebde326464493ec888650839b23a3253c5854c9b90745c478d8966f5d53106a2`
  (`amd64`). Pristine image ID:
  `sha256:2fc815b31d6844b4e86c4754b41474c900b92b702497e123abe2b7e9414d882f`.

Two repository/toolchain caveats are separate from the feature:

1. the current `pnpm-lock.yaml` requires pnpm 9 although an upstream workflow
   still pins pnpm 8; pnpm 8 fails frozen-lock installation; and
2. the official base's native ARM64 build hits a pre-existing `sqlite-vfs`
   `c_char` signedness mismatch. Upstream CI is x86_64, and the forced x86_64
   official-base lane passes.

The first overlay test invocation reused a cached pristine `sqlsync` test
binary. The overlay recipe now runs `cargo clean -p sqlsync` before validation;
the corrected runs compile and execute all 23 tests. The stale 18-test result
is not counted as prototype evidence.

## Applicability and selection

| Dimension | Score | Reason |
|---|---:|---|
| Eligibility and health | 7 | All hard gates and offline x86_64 lanes pass, but activity margin is modest and pnpm/ARM drift must be pinned. |
| Rarity | 9 | Local-first SQLite timeline observation across Rust/Wasm/TypeScript is uncommon and absent from local problem history. |
| Task applicability | 8 | Issue #31 supplies maintainer demand while source semantics now define a narrow, testable contract. |
| Behavioral depth | 8 | Identity crosses append, acknowledgement, coordinator application, storage replication, rebase, Wasm, and TypeScript. Prototype size changes depth by no more than one point. |
| Harness feasibility | 9 | The complete deterministic workspace and browser package build pass without networking or external services. |
| Prior-art/similarity safety | 5 | The public issue owns the broad desire, but exhaustive checks found no receipt/snapshot implementation. Local progress tasks create some neighborhood risk. |

Weighted rating: **8/10**.

SQLSync beats the 6/10 RMK portable-snapshot runner-up because SQLSync has a
working full-stack disposable implementation and a verified offline complete
lane. RMK still has unresolved macro/encoder extent discovery, adjacency to
merged bulk helpers, hardware/protocol harness risk, and no trial.

## Remaining gate

Construction and the false-positive audit are complete for version 5. Solver
calibration has not started and remains at 0/10. Any prompt, test, reference,
or environment change invalidates the evidence below, requires all checks
again, and starts a future calibration batch at 0/10.

## Construction freeze - 2026-08-02

Phase 0 was repeated before participant artifacts were authored. A fresh clone
resolved both default-branch `HEAD` and the proposed base to
`7dc1af6b082023982fd2697f913f5b27453747f1` (2025-11-19). GitHub reported no
later push, no open pull request, and no release. All historical pull requests
and issues were enumerated through the API. Exact/synonym searches again found
only open issue #31 and no implementation. The three live branches were
inspected; `renovate/configure` is one configuration file and `updates` is old
dependency/lint work. Discussion #53 and the Discussions search still neither
implement nor prescribe the receipt/snapshot contract. `UPSTREAM_AUDIT.md`
contains the corrected branch ledger and the full refresh result.

Immutable source/environment identifiers for construction are:

| Item | Frozen value |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| `git archive` SHA-256 | `83d778d7714cf529ec66314ab3147b71480261ef56ea808e49680ef0b0678dbd` |
| `Cargo.lock` SHA-256 | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| `pnpm-lock.yaml` SHA-256 | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |
| Official base manifest | `public.ecr.aws/d3j8x8q7/olympus-base-rust@sha256:211a2e3aeff24b410f2c982723e9314992833f4633c764217eab87552f1d1477` |
| Evaluation architecture | `linux/amd64` |
| Rust / Just / wasm-pack / pnpm | `1.91.1` / `1.43.1` / `0.13.1` / `9.15.9` |

The x86_64 choice remains necessary because the pinned official base's ARM
`sqlite-vfs` `c_char` issue is unrelated to this task. The original 4/10 broad
issue rejection remains historical evidence; it is not replaced by this
narrower design.

## Frozen participant-facing API contract

Repository naming review supports `MutationReceipt`, `MutationStatus`, and
`SyncState` in Rust, plus `SQLSync.syncState` alongside the existing camel-case
browser methods. The Rust crate root exposes the three types. A successful
`LocalDocument::mutate` returns the receipt, and
`LocalDocument::sync_state(received)` returns the conservative snapshot using
the acknowledgement observed by its caller's replication layer. `SyncState`
classifies a receipt with `status`.

The browser method `SQLSync.mutate` resolves to the generated receipt and
`SQLSync.syncState` resolves to the generated snapshot. Generated public types
must export an exact `Lsn` representation and the receipt/snapshot types. Tests
accept any documented generated representation that cannot admit JavaScript
`number`; they do not require the prototype's decimal-string conversion.

These names and signatures are public contract rather than private layout.
Acknowledgement storage, applied-row lookup, cache ownership, helper placement,
and derivation versus retention remain implementation choices. No coordinator
message, connection-status variant, await API, database enumeration, or private
persistence representation is part of the contract.

## Immutable construction version 5

The final participant artifacts were frozen on 2026-08-02 after five local
construction revisions. Versions 1-4 were never calibrated. Version 1 lacked a
browser-level acknowledgement-cache discriminator. Version 2 added that probe;
version 3 only formatted it. Version 4 added disconnect retention. The final
review found that JavaScript declarations alone did not catch a lossy
`u64 -> f64 -> string` implementation and that a browser-only failure could
leave a passing nextest XML file. Version 5 adds the high-LSN reconnect
observation and makes any failed command produce failing JUnit.

Exact identifiers are:

| Item | Version 5 value |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Source archive SHA-256 | `83d778d7714cf529ec66314ab3147b71480261ef56ea808e49680ef0b0678dbd` |
| `meta.md` SHA-256 | `16eb0f38ec337a6bbba6b721f5d8290ae60e0faca178f4375530b61b63d9f1aa` |
| `test.patch` SHA-256 | `8f824c6fb2586ee3bf971ff8c3d68fb18f20198971779385c79ea07bfd9eda61` |
| `solution.patch` SHA-256 | `997337c6f15374fdda9cb82dfb05b38043a87a14e577459b565cd3ee4dfabca1` |
| `Dockerfile` SHA-256 | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| `Cargo.lock` SHA-256 | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| `pnpm-lock.yaml` SHA-256 | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |
| Base image ID | `sha256:2c50f6c2ad01b595d38dd5489c75c2485f1d70f926ec8d6c8f27c118f9c15cdf` |
| Exact combined verification image | `sha256:40297feb07d4c9cc79dc07e6bf6988cfbf6e13587bf4ae025ae53ddad2b54992` |

Both patches apply cleanly and independently to the frozen source. The test
patch contains four files and 604 additions. The reference patch contains 12
files, 340 additions, and 15 deletions. The public description is 317 words,
ASCII-only, and contains no test or reference disclosures.

### Four-state and complete-lane results

Every container replay below used `linux/amd64`, the digest-pinned official
base, committed locks, and `--network none` after image construction.

| State / command family | Result |
|---|---|
| Pristine image construction: `just build`, `just test`, worker package | Pass; core 18/18 plus docs, examples, and package |
| Tests only, `test.sh base` | Exit 0; nextest 18/18; fixed-seed local example, network example, reducer host, docs, and worker package pass; JUnit 18 tests, 0 failures |
| Tests only, `test.sh new` | Expected exit 101 on absent receipt/state API; browser probe also rejects the old `Ack` mutation reply; fallback JUnit 1 failure |
| Solution only: full `just lint`, `just test`, worker package | Exit 0; core 23/23 plus docs and both examples |
| Solution plus tests, `test.sh base` | Exit 0; nextest 23/23 and complete base lane pass; JUnit 23 tests, 0 failures |
| Solution plus tests, `test.sh new` | Exit 0; browser acknowledgement/disconnect/high-LSN probe passes and Rust focused suite is 7/7; JUnit 7 tests, 0 failures |
| Exact combined `just lint` | Exit 0; clippy, rustfmt, and Biome pass; Biome checked 43 files |

The browser probe uses only loopback HTTP/WebSocket traffic inside the
network-disabled container. It instantiates the generated public Wasm API,
accepts a mutation, observes the coordinator acknowledgement, verifies the
snapshot while disconnected, reconnects to a newly observed peer range at
LSN `9007199254740993`, and converts the returned non-number value with
`BigInt`. It does not call an external service or inspect a private Rust field.

## False-positive audit - version 5

The audit followed `problems/statig-local-transitions/false_postive trials.md`.
No SQLSync solver rollout exists, so there was no same-task legitimate or
failing solver patch to replay. The startup-gate Statig trajectories informed
identity, observation-boundary, and compatibility mutants but were not treated
as SQLSync replays. The disposable reference and all four patch states provide
the available legitimate implementation evidence.

### Requirement mapping

| Participant-facing requirement | Strongest behavioral evidence |
|---|---|
| Successful mutation returns its exact timeline and LSN | `successful_mutations_return_timeline_bound_exact_receipts` observes two consecutive accepted mutations |
| A failed mutation neither returns a receipt nor advances local progress | `failed_mutation_does_not_advance_local_progress` |
| Snapshot watermarks are inclusive and the three stages remain distinct | `stage_order_and_retained_prefix_are_observable` drives the real in-process local/coordinator/storage/rebase sequence |
| Dropping the retained prefix does not erase local progress | The final rebase assertion in `stage_order_and_retained_prefix_are_observable`, supported by the public `LsnRange` behavior |
| Received advances only after an observed destination acknowledgement | `acknowledgement_advances_only_after_range_reply` and the browser loopback acknowledgement |
| Foreign/future receipts are unrelated and applied has precedence | `classification_is_timeline_bound_bounded_and_precedence_ordered` |
| A fresh peer observation replaces stale knowledge | `fresh_protocol_handshake_replaces_peer_observation` plus the browser reconnect to a different high range |
| The last observation remains available while disconnected | Browser loopback probe closes the acknowledged connection, waits for the public disconnected event, then reads the same receipt watermark |
| Browser LSN values are exact for every `u64` | Browser reconnect observes `9007199254740993` losslessly; generated declarations reject JavaScript `number` |
| Existing connection status and other APIs stay compatible | Generated declaration probe requires exactly the four existing statuses; exact complete base lane covers existing query, subscription, connection, replication, and package behavior |
| No new wire protocol or prescribed private layout | Existing replication examples and the complete base lane pass unchanged; tests interact through existing messages and public methods only |

### Isolated plausible mutants

Each mutant was a single behavioral change copied into a fresh ephemeral
container based on the exact combined image. Mutants were never stacked.
Copying, rather than a read-only source overlay, intentionally refreshed source
timestamps and forced Cargo to rebuild; an earlier bind-only pass reused
incremental objects and was discarded before any result was recorded. Wasm
mutants regenerated the worker package through `test.sh new`. All final mutant
runs emitted nonzero status and JUnit with one failure.

| Mutant | Repository/trajectory rationale | Version 5 result |
|---|---|---|
| `local = range.last()` | Existing empty-following range asymmetry | Killed by retained-prefix stage test; exit 100 |
| `applied = received` | Common acknowledgement/commit collapse | Killed by stage-order test; exit 100 |
| Ignore timeline identity | Process-global numeric progress shortcut | Killed by classification test; exit 100 |
| Omit the local future bound | Numeric comparison without allocation validity | Killed by classification test; exit 100 |
| Mark a sent frame as received | Transport-send versus destination-ack boundary | Killed by acknowledgement test; exit 100 |
| Declare browser `Lsn` as `number` | Direct JavaScript precision shortcut | Killed by generated API test; exit 100 |
| Add `Syncing` to `ConnectionStatus` | Trajectory-supported public-enum expansion shortcut | Killed by generated compatibility test; exit 100 |
| Never refresh the first cached range | Plausible stale-cache implementation | Killed by browser acknowledgement probe; exit 1 |
| Reset the cached range on disconnect | Plausible current-connection-only implementation | Killed by browser disconnected snapshot probe; exit 1 |
| Convert `u64` through `f64` before returning text | Plausible apparently-string but lossy bridge | Killed by high-LSN reconnect probe; exit 1 |

Three actionable survivors shaped the final tests. The never-refresh cache
passed the original seven focused tests and the complete pre-existing lane
(23/23 plus docs, examples, and package). The reset-on-disconnect cache later
passed the then-current focused suite and the same complete lane. The lossy
string bridge also passed the complete pre-existing lane. The added browser
observations pass the reference and fail those survivors without requiring
cache ownership, a field name, a query count, or a private transport seam.

Rejected mutant ideas were arbitrary nonnumeric aliases such as `boolean`,
private field-placement changes with no public effect, permutations of the
same watermark comparison, and invented wire messages. They lack repository or
trajectory support, test private architecture, or add no distinct semantic
boundary. A zero-survivor result is evidence only for these ten attempted
families; it is not a claim that every false positive is impossible.

Calibration advice was considered only after reading
`CALIBRATION_STRATEGY.md`. No local or platform solver run has been spent on
version 5. Its calibration counter is exactly 0/10.

## Revision design gate - version 6

The 2026-08-02 interface review was treated as a new immutable-version design
input before revising `test.patch`. The required startup search was repeated
across `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, active trajectory directories, and archive member
names for SQLSync, sync state, receipts, watermarks, worker bridges, and public
API compatibility. It again found no SQLSync solver trajectory. The Statig
archive manifest and the same representative legitimate pass
(`agent-runs4/Nova_Nova_4`), near-pass (`agent-runs5/Nova_Nova_3`), and broad
failure (`agent-runs5/Nova_Nova_1`) raw trajectories were re-inspected. Their
lessons remain applicable: carry identity through the actual public boundary,
sample state at the correct observation boundary, and do not require changes to
an unrelated stable public enum.

The review identified two fairness defects and one coverage gap in version 5:

- the focused Rust test called an undocumented `SyncState::new` constructor;
- the generated-declaration check required the structural spelling
  `interface`, rejecting an equivalent exported type alias; and
- browser behavior was driven through `WorkerApi`, but no consumer compiled
  calls to the participant-facing `SQLSync.mutate` and `SQLSync.syncState`
  methods with their promised result types.

The version-6 discriminator ledger therefore adds one distinct public boundary:

| Evidence / plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Implement only worker request/reply variants and omit or mistype the `SQLSync` wrapper methods. | A TypeScript consumer can call `SQLSync.mutate` and `SQLSync.syncState` and receive the exported receipt/state types. | Compile a small package consumer that assigns both calls to `Promise<MutationReceipt>` and `Promise<SyncState>` and imports the exported `Lsn`. | Participant-facing TypeScript API | Structural TypeScript checking accepts interfaces or aliases and does not prescribe serializer internals, field casing, or class implementation. |

Version 6 will remove the stylistic camel-case sentence, generic compatibility
warning, and negative non-goals from the public prompt. It will replace
`SyncState::new` with the already specified public field shape, replace textual
`interface` searches with structural TypeScript compilation, and retain the
runtime worker loopback probe because it uniquely covers acknowledgement,
disconnect, reconnect, and high-LSN serialization. These changes do not add a
private-layout, timing, declaration-form, or reference-architecture
requirement. Because the prompt and tests change, all version-5 hashes and
verification results become historical evidence; version 6 starts calibration
at 0/10 and requires the complete false-positive and four-state gates again.

## Immutable construction version 6

The review revision was frozen and verified on 2026-08-02. Version 5 is retained
above as historical construction evidence, but its hashes and results do not
count for version 6. The source pin, dependency locks, reference behavior, and
Dockerfile remain unchanged; the prompt and test patch changed.

| Item | Version 6 value |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Source archive SHA-256 | `83d778d7714cf529ec66314ab3147b71480261ef56ea808e49680ef0b0678dbd` |
| `meta.md` SHA-256 | `1b497212578ede1b1716943694b28b1cf0b74b0b3b3c28f6e4e1190d2d273a1f` |
| `test.patch` SHA-256 | `ca0a62563ec501fc20b9c12110c6d1230a67cb66f1f6d68303c78c79101396cf` |
| `solution.patch` SHA-256 | `997337c6f15374fdda9cb82dfb05b38043a87a14e577459b565cd3ee4dfabca1` |
| `Dockerfile` SHA-256 | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| `Cargo.lock` SHA-256 | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| `pnpm-lock.yaml` SHA-256 | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |
| Base image ID | `sha256:2c50f6c2ad01b595d38dd5489c75c2485f1d70f926ec8d6c8f27c118f9c15cdf` |

Both patches apply cleanly and independently. The test patch contains five
files and 663 additions. The unchanged reference patch contains 12 files, 340
additions, and 15 deletions. The revised public description is 285 words,
ASCII-only, and contains no construction disclosures.

### Version-6 four-state and complete-lane results

Every replay used `linux/amd64`, the digest-pinned base and committed locks,
with networking disabled after image construction.

| State / command family | Version 6 result |
|---|---|
| Pristine: `just test`, worker package | Pass; core 18/18 plus docs, examples, and package |
| Tests only, `test.sh base` | Exit 0; nextest 18/18 plus the complete pre-existing lane; JUnit 18 tests, 0 failures |
| Tests only, `test.sh new` | Expected exit 101 on the absent Rust API; the TypeScript consumer also reports missing exports/methods and the facade runtime rejects the old mutation reply; fallback JUnit 1 failure |
| Solution only: `just lint`, `just test`, worker package | Exit 0; core 23/23 plus docs, both examples, lint, and package |
| Solution plus tests, `test.sh base` | Exit 0; nextest 23/23 plus the complete pre-existing lane; JUnit 23 tests, 0 failures |
| Solution plus tests, `test.sh new` | Exit 0; TypeScript consumer, high-level facade runtime, loopback browser probe, and Rust focused 6/6 pass; JUnit 6 tests, 0 failures |
| Exact combined `just lint` | Exit 0; clippy, rustfmt, and Biome pass; Biome checked 44 files |

The high-level facade probe supplies an in-process worker double through the
existing public constructor. It verifies that `SQLSync.mutate` resolves to the
exact receipt object returned by the worker and that `SQLSync.syncState`
resolves to the exact state object. The separate loopback probe still drives
the generated Wasm `WorkerApi` through real loopback HTTP/WebSocket traffic for
acknowledgement timing, disconnect retention, reconnect refresh, and the exact
LSN `9007199254740993`. Neither probe inspects a private Rust field.

The type consumer imports `MutationReceipt`, `SyncState`, `Lsn`, and
`ConnectionStatus`, assigns actual facade calls to the promised `Promise`
types, and uses structural type equality. It contains no search for
`interface`, `timelineId`, or a serializer field spelling. As a legitimate-
variation check, both generated receipt/state declarations were mechanically
changed from interfaces to equivalent exported type aliases after generation;
the exact consumer still compiled successfully.

## False-positive audit - version 6

The audit was rerun only after rereading the worked Statig reference. There is
still no SQLSync solver rollout, so no representative same-task legitimate,
near-pass, or failing solver patch exists to replay. The three Statig raw
trajectories recorded in the revision gate remain supporting design evidence,
not SQLSync replays.

### Version-6 requirement mapping

| Participant-facing requirement | Strongest behavioral evidence |
|---|---|
| Successful Rust mutation returns its exact timeline and LSN | Two consecutive accepted mutations in `successful_mutations_return_timeline_bound_exact_receipts` |
| Failed mutation returns no receipt and does not advance local progress | `failed_mutation_does_not_advance_local_progress` |
| Local/received/applied are inclusive, distinct observations and retained-prefix progress survives | Real local/coordinator/storage/rebase flow in `stage_order_and_retained_prefix_are_observable` |
| Received advances only after a processed acknowledgement | `acknowledgement_advances_only_after_range_reply` plus the loopback acknowledgement |
| Foreign/future receipts are unrelated; applied outranks received and local | Public-field snapshots in `classification_is_timeline_bound_bounded_and_precedence_ordered` |
| Last observation remains while disconnected and a fresh peer observation replaces it | Loopback disconnect snapshot and high-range reconnect, supported by `fresh_protocol_handshake_replaces_peer_observation` |
| Worker exports exact `Lsn`, receipt, state, and the four connection statuses | Structural TypeScript consumer rejects numeric `Lsn`, imports both exported types, and checks the exact status union |
| `SQLSync.mutate` and `SQLSync.syncState` expose the promised result types | Type consumer assigns real calls to `Promise<MutationReceipt>` and `Promise<SyncState>` |
| Both facade methods return the worker values at runtime | Fake-worker facade probe checks returned object identity for mutation and state |
| Browser values remain exact for every Rust `u64` | Generated Wasm loopback observes `9007199254740993` and validates it with `BigInt` |

The Rust classification test now constructs the explicitly exported public
field shape; it never calls `SyncState::new`. The type consumer accepts both
interfaces and aliases. These checks directly resolve the two interface errors
without adding another participant requirement.

### Version-6 isolated mutants

All twelve mutants were applied one at a time in fresh ephemeral containers to
the exact version-6 artifact. Every production mutation was confirmed present,
every `test.sh new` invocation returned nonzero, and every emitted JUnit file
reported one failure. The six Rust tests intentionally remain green for the
browser-only and facade-only mutants.

| Mutant | Plausible incorrect mode | Version 6 result |
|---|---|---|
| `local = range.last()` | Lose progress after complete retained-prefix removal | Killed by retained-prefix stage behavior |
| `applied = received` | Collapse acknowledgement and application | Killed by stage-order behavior |
| Ignore timeline identity | Compare process-global numeric LSNs | Killed by receipt classification |
| Omit local future bound | Treat unallocated future LSN as progress | Killed by receipt classification |
| Mark sent frame received | Advance before destination acknowledgement | Killed by acknowledgement behavior |
| Browser `Lsn = number` | Admit precision loss at the language boundary | Killed by structural typing and high-LSN runtime behavior |
| Add `Syncing` connection status | Expand a stable public union | Killed by structural status-union equality |
| Never refresh first cached range | Preserve stale acknowledgement across a fresh connection | Killed by loopback reconnect observation |
| Reset cached range on disconnect | Erase the client's last observed knowledge | Killed by disconnected snapshot observation |
| Convert `u64` through `f64` before text | Return apparently lossless text after numeric aliasing | Killed by high-LSN loopback observation |
| `SQLSync.mutate -> Promise<void>` | Complete worker support but leave the old facade result | Killed by the type consumer and exact-object runtime probe |
| Omit `SQLSync.syncState` | Implement only the lower-level worker request | Killed by the type consumer and facade runtime probe |

The three earlier actionable cache/precision survivors remain the only mutants
that required new black-box observations after passing a then-current focused
suite and the complete pre-existing suite. The two facade omissions were
suggested by the external interface review; they compile in the worker package
and pass all six Rust tests, but the new public TypeScript boundary rejects
them. No version-6 mutant survives the focused suite, so no additional survivor
needed a complete-suite replay. The exact combined complete lane nevertheless
passes 23/23 plus docs, examples, reducer host, and worker packaging.

Rejected/artificial ideas remain arbitrary field aliases, private field
placement, repeated watermark permutations, invented wire messages, and
one-off adversarial casts. They either lack repository/review evidence, test a
private architecture, or add no distinct semantic boundary. The passing
interface-to-alias transformation is recorded as a legitimate variation, not a
mutant to kill. Zero survivors is evidence only for these twelve attempted
families.

`CALIBRATION_STRATEGY.md` was reread after the artifact was frozen. No local or
platform solver run has been spent on version 6. Calibration is exactly 0/10;
no version-5 result or unused slot carries forward.

## Revision design gate - version 7

The 2026-08-02 fairness and baseline review starts another immutable version.
Before revising tests, the required searches were repeated across the problem
and candidate indexes, active trajectory directories, the Statig archive
manifest, and raw representative pass, near-pass, and broad-failure
trajectories. No SQLSync solver trajectory exists. The repeated Statig evidence
again favors public values and stable boundaries over author-selected internal
carriers; it does not justify a new SQLSync method name or worker reply schema.

The review supplied new direct repository and evaluator evidence:

- the stock offline evaluator has `cargo` and Node but no `just` or `pnpm`, and
  selecting `cargo +1.91.1` triggers a forbidden network sync;
- the prompt does not require JavaScript object-reference identity;
- existing query behavior demonstrates that a facade may transform a worker
  reply before returning an equivalent public value;
- the pinned worker has an existing outer Boot/Doc/Close transport, but no
  convention requiring `MutationAccepted`, `SyncState`, `receipt`, or `state`
  as new inner variant/field names; and
- `ReplicationProtocol` has no existing `received_watermark` naming convention,
  while the public contract already passes the caller's observed
  acknowledgement into `LocalDocument::sync_state`.

Version 7 therefore removes both remaining redundant prompt sentences and
replaces three unfair oracles before changing `test.patch`:

| Reviewed shortcut or over-constraint | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Require facade reference identity. | Public methods return structurally correct generated receipt/state values. | Drive the real facade and generated worker, then compare documented value fields and exact LSNs rather than `===`. | Public JavaScript value semantics | Cloning, normalization, or another equivalent transformation passes. |
| Require exact new inner reply tags and wrapper fields. | The existing outer worker transport carries whatever mutually compatible internal schema implements the public facade. | A generic Worker double handles only existing Boot/Doc/Close routing and forwards every Doc request and worker reply opaquely. | Facade-to-worker integration | Alternative new inner tags and wrapper shapes pass when the participant's facade and worker agree. |
| Require `ReplicationProtocol::received_watermark()`. | `sync_state` classifies the acknowledgement its caller has actually observed. | Derive the watermark from the existing public `ReplicationMsg::Range` reply after handling it and pass that value explicitly. | Core acknowledgement observation | Field ownership and accessor naming remain unrestricted. |
| Assume authoring-image helper commands exist in grading. | Test-only baseline passes with the stock offline toolchain. | Use unqualified `cargo`, repository recipes expanded to Cargo commands, and run the optional browser/package lane only when its locked local tools are available. | Evaluation portability | The exact Docker lane still exercises browser behavior; lack of unrelated helper binaries cannot fail baseline. |

The generated browser test will instantiate public `SQLSync` over a generic
transport backed by the real generated `WorkerApi`. The transport may inspect
only the repository's pre-existing outer Boot/Doc/Close envelope; it never
branches on a new document request or reply variant and never reads a new
wrapper field. Public assertions will inspect receipt/state LSN values and
timeline values structurally, including the high LSN `9007199254740993`.

The Rust focused suite will remove the standalone accessor test and fresh-
protocol cache test. Its end-to-end stage flow will retain acknowledgement
ordering by updating a caller-owned observation only after handling the public
range reply. This still distinguishes local, received, and applied without
prescribing where the worker stores peer knowledge. The exact-status mutant is
retired because the corresponding prompt requirement is removed. The revised
false-positive audit must rerun the remaining semantic mutants plus new
schema/clone/accessor legitimate variations. All version-6 hashes and results
are historical; version 7 begins calibration at 0/10.

## Immutable construction version 7

The fairness and baseline revision was frozen and verified on 2026-08-02. The
source pin, locks, reference behavior, and Dockerfile remain unchanged. The
prompt and test patch changed, so no version-6 result counts for this version.

| Item | Version 7 value |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Source archive SHA-256 | `83d778d7714cf529ec66314ab3147b71480261ef56ea808e49680ef0b0678dbd` |
| `meta.md` SHA-256 | `d9499d9c9fe38c00ddac3798185510ada6265f47825eff95fdbafa4a2df329b2` |
| `test.patch` SHA-256 | `3441ae089f655b6d7f02bd0333bc8786b0804d5737c853433f6e319b5bf41bac` |
| `solution.patch` SHA-256 | `997337c6f15374fdda9cb82dfb05b38043a87a14e577459b565cd3ee4dfabca1` |
| `Dockerfile` SHA-256 | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| `Cargo.lock` SHA-256 | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| `pnpm-lock.yaml` SHA-256 | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |
| Base image ID | `sha256:2c50f6c2ad01b595d38dd5489c75c2485f1d70f926ec8d6c8f27c118f9c15cdf` |

Both patches apply cleanly and independently. The test patch contains four new
files and 590 additions. The unchanged reference patch contains 12 files, 340
additions, and 15 deletions. The revised public description is 270 words,
ASCII-only, and contains no construction disclosures.

### Version-7 four-state, portability, and complete-lane results

Every frozen-image replay used `linux/amd64`, committed locks, and networking
disabled after construction.

| State / command family | Version 7 result |
|---|---|
| Pristine: `just test`, worker package | Exit 0; core 18/18 plus docs, examples, and package |
| Tests only, `test.sh base` | Exit 0; workspace library tests 18/18 plus doc tests; JUnit 1 test, 0 failures |
| Tests only, `test.sh new` | Expected nonzero exit for the absent Rust and worker APIs; JUnit 1 failure |
| Solution only: `just lint`, `just test`, worker package | Exit 0; core 23/23 plus docs, examples, lint, and package |
| Solution plus tests, `test.sh base` | Exit 0; workspace library tests 23/23 plus doc tests; JUnit 1 test, 0 failures |
| Solution plus tests, `test.sh new` | Exit 0; structural TypeScript consumer, public facade/generated-worker loopback, and Rust focused 4/4; JUnit 1 test, 0 failures |
| Stock-tool simulation without `just` or `pnpm` | Exit 0; browser lane explicitly skipped and Rust focused 4/4 still run |

The base lane uses unqualified, locked, offline Cargo commands and excludes the
upstream example target that requires a separately built `guest.wasm`. It does
not invoke `just`, `pnpm`, nextest, or a rustup-qualified toolchain. Browser
checks run when the frozen package tools are present and skip cleanly when the
stock evaluator lacks them. This directly reproduces and resolves the reported
baseline environment while preserving full browser coverage in the frozen
image.

The public runtime probe forwards document messages opaquely between a real
`SQLSync` facade and generated `WorkerApi`. Before releasing the coordinator
range reply it observes no received progress; after releasing it, it observes
the exact receipt LSN. The same public snapshot retains that observation after
disconnect and replaces it with `9007199254740993` after a fresh connection.
Assertions compare documented structured values, never JavaScript reference
identity. The bridge double recognizes only the pinned repository's existing
outer Boot/Doc/Close routing and does not name or inspect a new document request
or reply variant or wrapper field.

## False-positive audit - version 7

The exact-version audit was performed only after rereading the worked Statig
false-positive record. The prior-history search still contains no SQLSync
solver rollout, so there is no same-task legitimate, near-pass, or failing
solver patch to replay. The representative Statig raw trajectories listed in
the version-7 design gate remain architecture evidence only.

### Version-7 requirement mapping

| Participant-facing requirement | Strongest behavioral evidence |
|---|---|
| Each successful mutation returns its exact timeline-bound allocated LSN | Two consecutive receipts in `successful_mutations_return_timeline_bound_exact_receipts` |
| A failed mutation returns no receipt and does not advance local progress | `failed_mutation_does_not_advance_local_progress` |
| Optional watermarks are inclusive and retained-prefix history remains visible | Real local/coordinator/storage/rebase flow in `stage_order_and_retained_prefix_are_observable` |
| Received advances only after this client processes an acknowledgement | Public facade snapshot before and after the held coordinator range reply, plus caller-owned observation in the Rust stage flow |
| Applied waits for coordinator application, storage return, and rebase | The Rust stage flow remains Received after remote step and becomes Applied only after return replication and rebase |
| Foreign/future receipts return `None`; Applied outranks Received and Local | `classification_is_timeline_bound_bounded_and_precedence_ordered` |
| Last knowledge survives disconnect and a fresh observation replaces stale knowledge | Public facade snapshots across loopback disconnect and high-range reconnect |
| `SQLSync.mutate` and `SQLSync.syncState` return the exported public types | Structural TypeScript consumer assigns actual calls to `Promise<MutationReceipt>` and `Promise<SyncState>` |
| Facade methods produce public structured values at runtime | Real facade/generated-worker loopback validates receipt and state LSN fields without identity checks |
| Browser LSNs preserve all Rust `u64` values and do not admit `number` | Type-level `number extends Lsn` rejection and runtime `BigInt` comparison at `9007199254740993` |

### Version-7 isolated mutants and legitimate variations

Eleven plausible incorrect implementations were applied one at a time in
fresh offline containers to the exact version-7 artifacts. Each mutation was
confirmed to alter production bytes, each `test.sh new` run returned nonzero,
and each emitted JUnit with one failure.

| Mutant | Plausible incorrect mode | Version 7 result |
|---|---|---|
| `local = range.last()` | Lose progress after complete retained-prefix removal | Killed by retained-prefix stage behavior |
| `applied = received` | Collapse acknowledgement and application | Killed by stage-order behavior |
| Ignore timeline identity | Compare process-global numeric LSNs | Killed by receipt classification |
| Omit the local future bound | Treat an unallocated future receipt as observed | Killed by receipt classification |
| Mark a sent frame received | Advance before the destination acknowledgement | Killed by the held-ack public facade observation |
| Browser `Lsn = number` | Admit precision loss at the language boundary | Killed by structural typing and high-LSN runtime behavior |
| Never refresh the first cached range | Preserve stale acknowledgement across a fresh connection | Killed by reconnect observation |
| Reset the cached range on disconnect | Erase the client's last observed knowledge | Killed by disconnected snapshot observation |
| Convert `u64` through `f64` before text | Return apparently textual but aliased values | Killed by high-LSN reconnect observation |
| `SQLSync.mutate -> Promise<void>` | Leave the old facade result despite worker support | Killed by the type consumer and runtime value validation |
| Omit `SQLSync.syncState` | Implement only a lower worker layer | Killed by the type consumer and runtime facade call |

No mutant survives the complete focused lane, so version 7 has no survivor to
promote to the pre-existing full suite. The three cache/precision families are
retained because earlier construction versions showed that each could pass the
complete pre-existing suite before its distinct public browser discriminator
was added. The exact reference plus tests nevertheless passes the complete
base lane, lint, examples, Wasm generation, and worker packaging.

Three positive variations were also run in fresh containers. Returning shallow
clones of both facade values passes. Renaming every new inner request/reply tag
and both wrapper fields while keeping facade and worker mutually consistent
passes. Renaming the reference acknowledgement accessor everywhere passes.
These checks directly demonstrate that object identity, the author-selected
worker schema, and `ReplicationProtocol::received_watermark()` are not test
contracts.

The connection-status mutant is retired rather than hidden: the prompt no
longer promises an exact status union. Rejected/artificial ideas remain private
field placement, arbitrary field aliases, repeated watermark permutations, and
one-off adversarial casts. They lack public or repository evidence or add no
new semantic boundary. Zero survivors is evidence only for the eleven attempted
incorrect families.

`CALIBRATION_STRATEGY.md` was reread after the exact artifact was frozen. No
local or platform solver run has been spent on version 7. Calibration is
exactly 0/10; no prior-version result or unused run carries forward.

## Revision design gate - version 8

The 2026-08-02 solution-pass and interface-semantics review starts a new
immutable version. Before revising `test.patch`, the required searches were
repeated across the problem and candidate indexes, active trajectory paths,
archive manifests, and repository records for SQLSync, receipts, worker
facades, generated LSNs, and watermark observations. No SQLSync solver
trajectory exists.

The representative Statig raw pass (`agent-runs4/Nova_Nova_4`), near-pass
(`agent-runs5/Nova_Nova_3`), and broad integration failure
(`agent-runs5/Nova_Nova_1`) were re-inspected from the archive. The legitimate
pass changed the public seams and both execution engines, then validated broad
feature combinations. The near-pass implemented the stated value behavior but
used one unstable internal coordinate. The broad failure exposed an extra
public enum variant for private metadata and broke downstream exhaustive
matching. The applicable lesson is to exercise SQLSync's promised public values
without silently requiring a convenience trait or one serialization carrier.
These are cross-problem design lessons, not SQLSync implementation templates.

The new evaluator evidence identifies three version-7 defects:

- the Rust stage test moves the same receipt into `status` repeatedly, so an
  otherwise natural consuming signature compiles only when `MutationReceipt`
  happens to implement `Copy`;
- the browser probe converts the public LSN with `BigInt`, although the prompt
  allows any documented exact non-`number` representation; and
- the stock solution-validation environment cannot report a skipped browser
  lane: every `new` test must execute and pass after the solution is applied.

The version-8 discriminator ledger is therefore:

| Reviewed shortcut or over-constraint | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Reuse one by-value receipt four times. | `status` classifies the same documented timeline/LSN value at successive snapshots. | Save the public timeline and LSN components and construct a fresh receipt value for every consuming call. | Rust ownership/API semantics | Solvers may implement `Copy`, `Clone`, or neither; no convenience trait is required. |
| Require every lossless LSN to be accepted by `BigInt`. | Distinct adjacent `u64` values remain observably distinct and facade values survive unchanged. | Compare public values with opaque structural equality; observe adjacent values above `2^53` and require them not to alias. | Browser representation | Decimal text, `bigint`, word pairs, or another structured exact representation can pass. |
| Skip all worker checks when package helpers are absent. | `test.sh new` always executes a meaningful public-facade check and the Rust behavior suite. | Use the full generated-worker loopback when the locked build stack exists; otherwise execute the real TypeScript facade source with Node's built-in type erasure and a schema-agnostic in-memory port. | Evaluation portability | The fallback tests method existence and returned public values without naming new inner tags or wrapper fields; JUnit never records a skip. |
| Require a separately built 18-MB reducer fixture or the broken host example. | Focused Rust behavior runs with ordinary native Cargo. | Embed a 273-byte valid reducer module implementing the repository's public reducer ABI. | Rust test bootstrap | The fixture supplies only the existing ABI and does not prescribe participant production code or require a Wasm target. |

The portable facade harness will recursively load the repository's actual
TypeScript source with Node's built-in type erasure, synthesize only unavailable
third-party/type-only imports, and drive the existing public `SQLSync`
constructor. Its in-memory port discovers mutually compatible reply tags from
the implementation rather than asserting author-selected names and supplies an
opaque, deliberately non-`BigInt`-convertible LSN value. The full frozen-image
lane will retain the generated worker loopback and structural TypeScript
consumer, but will compare public LSN values opaquely and distinguish adjacent
high values rather than choosing a representation.

Because both the tests and reference verification record change, all version-7
hashes and results are historical. Version 8 begins calibration at 0/10 and
requires the complete four-state and false-positive gates again.

## Immutable construction version 8

Version 8 was frozen and replayed on 2026-08-02 from commit
`7dc1af6b082023982fd2697f913f5b27453747f1` in the rebuilt
`linux/amd64` image
`sha256:27e672cf75a143345de1daf87612cc5b8776b18c8d79b1356cda9214cb23a680`.
The image was built from the unchanged task Dockerfile. During image
construction, its existing `just build` step generated the reducer guest before
`just test`; the reported standalone missing-`guest.wasm` failure therefore did
not occur in the frozen baseline.

The exact patch-state matrix passed with networking disabled:

| State / command family | Version 8 result |
|---|---|
| Pristine `just test` and development worker package | Exit 0 |
| Tests-only `test.sh base` | Exit 0, zero JUnit failures/errors |
| Tests-only base with package helpers removed from `PATH` | Exit 0 |
| Tests-only `test.sh new` | Rejected the absent API and emitted one JUnit failure |
| Solution-only lint, complete repository tests, examples, and worker package | Exit 0 |
| Solution plus tests, full-tools `test.sh new` | Browser loopback passed; Rust integration 4/4; zero JUnit failures/errors/skips |
| Solution plus tests, no `pnpm` or `wasm-pack` visible | Actual `SQLSync` facade probe passed; Rust integration 4/4; zero JUnit failures/errors/skips |
| Solution plus tests, `test.sh base` | Exit 0, zero JUnit failures/errors |

The full browser path calls the packaged public facade against the generated
worker. The fallback path executes the repository's real `src/sqlsync.ts`
through Node's built-in TypeScript erasure and an outer-protocol-compatible
port. It does not declare or guess the new inner request/reply names. Both paths
require structured receipt/state values. The fallback's LSN object deliberately
throws on primitive conversion, while the full path distinguishes adjacent
values `9007199254740992` and `9007199254740993` through structural comparison.

The Rust integration embeds a 273-byte reducer implementing the existing ABI.
It moves the mutation-returned receipt only once. Every later classification of
the same public timeline/LSN value constructs a fresh `MutationReceipt`, so
neither `Copy` nor `Clone` is an implicit interface requirement.

## False-positive audit - version 8

The worked Statig false-positive record was reread in full before approval.
The audit was then repeated against the exact hashes below.

### Public requirement map

| Participant-facing requirement | Strongest version-8 behavioral oracle |
|---|---|
| Successful mutation returns its exact timeline and allocated LSN; failure returns no receipt and does not advance local progress. | `successful_mutations_return_timeline_bound_exact_receipts` and `failed_mutation_does_not_advance_local_progress` |
| `local` is an inclusive allocated watermark and survives removal of an applied retained prefix. | `stage_order_and_retained_prefix_are_observable` after upload, return replication, rebase, and prefix removal |
| `received` advances only after the caller observes the coordinator range acknowledgement. | Full generated-worker loopback observes state before and after the held range acknowledgement; Rust derives the value from the existing public `ReplicationMsg::Range` |
| `applied` advances only after coordinator application returns and becomes visible after rebase. | Rust stage-order flow checks `Received` before remote step and again before return replication, then `Applied` only after rebase |
| Classification is timeline-bound, future-bounded, and ordered Applied > Received > Local. | `classification_is_timeline_bound_bounded_and_precedence_ordered` |
| Observed acknowledgement remains available while disconnected and is replaced by newly observed peer state after reconnect. | Full facade/worker loopback disconnect-retention and two reconnect observations |
| `SQLSync.mutate` and `SQLSync.syncState` exist and resolve to their exported structured values. | Structural TypeScript consumer plus full packaged facade and portable actual-source facade probes |
| Browser LSN is exact and does not admit `number`. | Generated `Lsn` compile-time exclusion of `number`, opaque facade-value preservation, and distinct adjacent high-`u64` observations |

### Plausible incorrect implementations

Eleven source-shaped mutants were applied independently after the reference and
tests. Every mutant compiled far enough to reach its relevant public oracle or
was rejected by the public TypeScript contract, and every complete focused
`new` lane failed:

| Mutant | Violated public behavior | Version-8 result |
|---|---|---|
| `local_last` | Drops progress when the retained range becomes empty | Rust retained-prefix probe fails |
| `applied_is_received` | Collapses acknowledgement and application | Rust stage-order probe fails |
| `no_timeline_identity` | Classifies a foreign receipt | Rust classification probe fails |
| `no_future_bound` | Classifies a receipt beyond local progress | Rust classification probe fails |
| `sent_is_received` | Advances on send rather than observed acknowledgement | Browser pre-ack observation fails |
| `js_number` | Makes the generated public LSN admit JavaScript `number` | TypeScript structural contract fails |
| `stale_reconnect` | Refuses fresh peer acknowledgement knowledge | Browser reconnect observation times out |
| `reset_disconnect` | Erases observed knowledge on disconnect | Browser disconnect-retention observation fails |
| `lossy_string` | Converts `u64` through `f64` before export | Adjacent high-LSN observation aliases and times out |
| `facade_void_mutate` | Keeps the facade mutation result void | TypeScript and runtime facade probes fail |
| `facade_missing_sync_state` | Omits the facade snapshot method | TypeScript and runtime facade probes fail |

There are no version-8 survivors of the complete focused lane, so no new mutant
needed promotion to the complete pre-existing suite. Earlier actionable cache,
disconnect, and lossy-conversion survivors and their complete-suite evidence
remain recorded in the version-1 through version-7 history; version 8 retains
the distinct public probes that killed those families. The complete reference
suite, lint, examples, reducer guest, Wasm build, and worker package all pass.

Four legitimate alternatives pass in fresh containers:

- shallow-cloned facade values instead of reference-identical objects;
- mutually consistent renamed inner worker request/reply tags and wrapper
  fields;
- a renamed acknowledgement accessor; and
- removal of `Copy` from the core `MutationReceipt`.

The opaque fallback value also proves that public LSNs need not be convertible
with `BigInt`. Rejected/artificial additions remain private cache placement,
arbitrary field aliases, repeated acknowledgement permutations, and exact
serialization-carrier requirements. They either lack a public requirement or
duplicate an existing discriminator. Zero survivors is evidence only for the
eleven attempted failure families.

### Immutable identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `d9499d9c9fe38c00ddac3798185510ada6265f47825eff95fdbafa4a2df329b2` |
| `test.patch` | `c28bdda598d8837ab4e7029a655c64621f75097edbcb3d5ce6ac3b36a907842e` |
| `solution.patch` | `997337c6f15374fdda9cb82dfb05b38043a87a14e577459b565cd3ee4dfabca1` |
| `Dockerfile` | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| frozen `Cargo.lock` | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| frozen `pnpm-lock.yaml` | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |

`CALIBRATION_STRATEGY.md` was reread after the version-8 artifact was frozen.
No local frontier or platform solver run has been spent on this version.
Calibration is exactly 0/10; previous-version results and unused slots do not
carry forward.

## Revision design gate - version 9

The 2026-08-02 API-shape review starts another immutable revision. Before
touching `test.patch`, `PROBLEM_DESIGN.md` was reread in full and the local
problem/candidate/archive indexes were searched again for SQLSync, sync-state
return shapes, receipt/state facade transformations, and opaque browser
representations. The search still finds no SQLSync solver trajectory or
same-task legitimate pass, near-pass, or broad failure.

The Statig archive manifest and raw trajectories were re-inspected for the
available cross-problem evidence: the legitimate pass
`agent-runs4/Nova_Nova_4` changed four production engine files plus public state
and outcome seams, used 62 recorded steps, and validated feature combinations;
the near-pass `agent-runs5/Nova_Nova_3` used 60 steps and failed only the
post-handler hierarchy-coordinate boundary; the broad failure
`agent-runs5/Nova_Nova_1` used 60 steps and exposed private routing metadata as a
new public enum variant, breaking exhaustive downstream matches. Their shared
lesson is that black-box behavior should survive ordinary alternative public
shapes and internal transformations. They provide no evidence for one SQLSync
error wrapper or one JavaScript carrier.

Repository evidence supplies the task-specific boundary. Existing Rust methods
mix direct and fallible returns, and the public prompt names
`LocalDocument::sync_state(received)` without specifying a wrapper. Existing
facade methods may transform worker replies (`query` uses `toRows`), while the
prompt promises the generated receipt/state values but does not promise
pass-through of arbitrary values that could never be generated by the chosen
implementation.

The version-9 discriminator ledger is:

| Reviewed over-constraint | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Call `.unwrap()` on every `sync_state` result. | Calling `sync_state` yields the promised snapshot, either directly or through an ordinary fallible wrapper. | Convert `SyncState`, `Option<SyncState>`, or `Result<SyncState, E>` through a test-local adapter before assertions. | Rust public return shape | Direct and fallible repository-native APIs pass; the test does not choose an error model absent from the prompt. |
| Require `SQLSync.mutate` to preserve a frozen synthetic opaque receipt and LSN unchanged. | The public method exists and resolves to a structured receipt whose LSN is not a JavaScript number. | In the portable source probe, accept transformed structured output and validate only public shape/non-number safety; retain the full generated-worker exact-high-value path. | Portable facade mutation result | String, bigint, word-pair, clone, normalization, or another generated representation may pass. |
| Require `SQLSync.syncState` to preserve a frozen synthetic state and its nested LSN objects unchanged. | The public method exists and resolves to structured state with non-number progress values when present. | Validate the returned public shape without deep equality to the synthetic reply; retain full generated-worker acknowledgement/reconnect behavior. | Portable facade snapshot result | Facade conversions analogous to existing `query` are allowed, and no arbitrary object identity or carrier becomes contractual. |

Version 9 will therefore change only the hidden test behavior and its
verification records. `meta.md`, `solution.patch`, and the Dockerfile remain
unchanged. All version-8 hashes, false-positive results, and calibration status
become historical; the revised participant artifact begins again at 0/10 and
must repeat every exact gate and the false-positive audit.

## Immutable construction version 9

Version 9 was frozen and replayed on 2026-08-02 from commit
`7dc1af6b082023982fd2697f913f5b27453747f1` in the rebuilt
`linux/amd64` image
`sha256:76797644ba8e1e28f79b806eb6a00e5dc6bcc606b447cded746f496639683e57`.
The participant prompt, reference solution, locks, and Dockerfile are
byte-identical to version 8.

The complete patch-state matrix passes with networking disabled: pristine
repository tests/package, tests-only base, stock-tool base, expected
tests-only-new rejection, solution-only lint/full tests/package, combined full
worker `new`, combined stock-tool portable `new`, and combined base. Both new
lanes report zero failures, errors, and skips; the Rust integration passes 4/4.

The Rust test-local `IntoSyncState` adapter accepts `SyncState` directly,
`Option<SyncState>`, and `Result<SyncState, E>`. No assertion invokes
`.unwrap()` on the participant method's return. A fresh-container variation
changes the reference method to return `SyncState` directly, updates its own
callers, and passes the complete new lane.

The portable facade probe no longer compares returned values to its synthetic
reply. It tries decimal text, `bigint`, and an exact word-pair as plausible
worker-side LSN carriers, then accepts any structured receipt/state result with
non-number progress values. A fresh-container variation declares generated
`Lsn` as `bigint` and normalizes worker strings in both facade methods; it
passes the full generated-worker and portable behavior. This demonstrates that
clone, conversion, and representation normalization are allowed.

## False-positive audit - version 9

The worked Statig false-positive record was reread in full before approving the
revised hidden tests. Every participant-facing requirement was remapped to its
strongest exact-version oracle:

| Public requirement | Strongest version-9 oracle |
|---|---|
| Exact successful receipts and no progress on failed mutation | Rust successful/failed mutation tests |
| Inclusive retained-prefix-aware local watermark | Rust stage-order and retained-prefix flow |
| Received only after caller-observed coordinator acknowledgement | Held-ack full facade/worker loopback and public Rust range reply |
| Applied only after coordinator work, return replication, and rebase | Rust stage-order flow |
| Timeline/future bounds and Applied > Received > Local | Rust classification test |
| Disconnect retention and fresh reconnect replacement | Full facade/worker disconnect and adjacent reconnect observations |
| `SQLSync.mutate` and `SQLSync.syncState` exported result types and runtime values | Structural TypeScript consumer, full generated-worker facade, and shape-only portable actual-source facade |
| Exact browser LSN that does not admit JavaScript `number` | Type-level `number` exclusion, runtime non-number shape checks, and distinct adjacent values above `2^53` |

The same eleven plausible incorrect implementations were independently applied
to the exact reference/test pair. All complete focused lanes failed: four Rust
watermark/classification mutants fail their specific Rust oracle; sent-before-
ack, stale-reconnect, reset-on-disconnect, and lossy-`f64` mutants fail their
corresponding full browser observation; `number`, void-mutate, and missing-
sync-state mutants fail the public TypeScript/runtime contract. No mutant
survives the focused lane, so there is no new survivor to promote to the
complete pre-existing suite. The solution-only complete suite passes, and the
historical complete-suite evidence for earlier cache/lossiness survivors
remains recorded in prior version sections.

Six legitimate variations pass in fresh containers:

- shallow-cloned facade result objects;
- mutually consistent renamed inner worker tags and wrapper fields;
- renamed acknowledgement accessor;
- a core receipt without `Copy`;
- direct `LocalDocument::sync_state -> SyncState`; and
- facade conversion of worker LSN text to generated `bigint` values.

Rejected/artificial probes remain private cache layout, an exact Rust error
wrapper, arbitrary browser object identity, exact passthrough of synthetic
values, and additional fixtures for already-covered watermark comparisons.
They are unstated or duplicate an existing failure family. Zero survivors is
evidence only for the eleven attempted mutants.

### Immutable identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `d9499d9c9fe38c00ddac3798185510ada6265f47825eff95fdbafa4a2df329b2` |
| `test.patch` | `0c71baeaf1780071b02ec8e3384548ecb56a4ad60415310de792b6d257ddea94` |
| `solution.patch` | `997337c6f15374fdda9cb82dfb05b38043a87a14e577459b565cd3ee4dfabca1` |
| `Dockerfile` | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| frozen `Cargo.lock` | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| frozen `pnpm-lock.yaml` | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |

Version 9 has no local frontier or platform solver run. Calibration begins at
exactly 0/10; no result or unused run from an earlier version carries forward.
`CALIBRATION_STRATEGY.md` was reread after the exact artifact and audit were
frozen.

## Trajectory-informed revision gate - version 10

The 2026-08-02 calibration review starts a new problem version. Before changing
`test.patch`, `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were reread in
full. Searches were repeated across `problems/README.md`, the candidate and
success indexes, this problem's compact records, and the supplied same-task raw
run bundle at `agent-runs1`. The four `Nova_Nova_1` through `Nova_Nova_4`
trajectories, solution patches, test logs, and evaluator verdicts were inspected
directly rather than relying only on the reported 4/4 aggregate.

All four are legitimate same-task passes against immutable version 9. Their
solution-patch SHA-256 values are, in run order,
`d46c7cfa8d9f398e69339b999a8ddf2bf0fbf13208cbe873a217194855e37aca`,
`da0c8677a0eb5fc48664aed41e5646330fa8df8e8ed1d3f49264af9739efc2b6`,
`2adb0b616331133c4391e559d27c7677f68e938a61d46f34d28e4df51fe68004`,
and `503c9b91ea7fa164339801508ee4619342a028d93b41809190a03f788baaf881`.
They change 11/14/13/9 production or example files with 282/309/270/274 raw
additions and 15/25/25/25 deletions. The trajectory export serializes one agent
turn containing 60/50/44/48 tool calls; it does not expose the platform's agent-
message metric, so those counts are not substituted for the long-horizon gate.
No same-task near-pass or broad failure exists in the bundle; the absence is
recorded rather than manufacturing a failing role. Prior raw Statig pass,
near-pass, and broad-failure evidence remains the representative cross-problem
fallback for identity-at-boundary and public-API compatibility lessons.

The run patches use several legitimate architectures: decimal text and
`bigint` browser LSNs; direct worker cache ownership and protocol-owned
observation; cached and queried applied state; and different internal worker
reply names. The new design therefore continues to accept those alternatives.
The raw code nevertheless exposes two genuine shortcut families. Runs 1, 3,
and 4 observe a coordinator `Range` using only `range.last()`, which erases an
inclusive acknowledgement when the peer reports a fully removed prefix as
`LsnRange::Empty { nextlsn > 0 }`; run 2 correctly derives
`range.last().or_else(|| range.next().checked_sub(1))`. Runs 1-3 update the
existing React and Solid mutation hook result types to `MutationReceipt`, while
run 4 updates only the lower worker facade and leaves both public wrapper types
as `Promise<void>`.

Version 9 also has two independently reported black-box gaps. Its reconnect
peer moves only forward, so monotonic-maximum retention of stale knowledge can
pass even though a new connection must replace it. Its real worker receipt
probe checks only a structured non-number LSN, so a missing, fabricated, or
receipt/state-inconsistent runtime timeline identifier can pass.

### Version-10 discriminator ledger

| Evidence / plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Merge fresh acknowledgement knowledge with a monotonic maximum. | The first observed range on a fresh connection replaces stale knowledge even when it is lower. | Save public value A, advance to B, disconnect retaining B, reconnect to a peer reporting A, and require the new state to equal saved A. | Connection-generation ownership | Tests replacement, not cache placement or one serialization carrier. |
| Export a receipt with no or fabricated runtime timeline identity. | A receipt and the corresponding snapshot identify the same local timeline. | Read either documented browser spelling of the runtime timeline field and compare the receipt and state values structurally. | Cross-value runtime provenance | Allows generated casing and structured IDs; requires only the promised identity relationship. |
| Treat `LsnRange::Empty` as no acknowledgement. | An empty-following peer range with `nextlsn > 0` observes the inclusive watermark `nextlsn - 1`. | After saving the public representation of B, process an empty-following range at B+1 and require `received` to equal saved B. | Protocol retained-prefix history | Directly follows the public inclusive-watermark rule and the repository's range model; run 2's different architecture passes. |
| Update `SQLSync.mutate` but make public React/Solid mutation hooks discard its result as `Promise<void>`. | Existing React and Solid mutation hooks resolve to the generated `MutationReceipt`. | Build both packages, then compile a public consumer that structurally checks each exported hook result. | Downstream public API propagation | The prompt states this concrete wrapper result; no demo, source spelling, or private worker schema is required. |

These discriminators are intentionally varied across network generation state,
retained-prefix protocol semantics, runtime provenance, and downstream static
typing. They do not add another watermark fixture unless it crosses a new
boundary. In particular, the lower reconnect uses a previously observed public
value to remain representation-neutral, and the empty-range probe reuses a
previously observed value rather than converting the public LSN.

The four version-9 passes are historical calibration evidence only. Their 4/4
result gives the documented 97% posterior probability that the solve rate is
above 50%, so `CALIBRATION_STRATEGY.md` requires hardening. Any version-10
participant-artifact change abandons version 9 and resets calibration to 0/10.
The design target is varied public boundaries rather than one shared failure
predicate. Exact post-authoring replay is recorded below. Hidden tests do not
require run 2's accessor, cache field, worker tags, reply wrappers, or browser
carrier.

## Immutable construction version 10

Version 10 was frozen on 2026-08-02 from commit
`7dc1af6b082023982fd2697f913f5b27453747f1`. The unchanged Dockerfile was
rebuilt as `olympus-sqlsync-observed-base:v10`; its amd64 image ID is
`sha256:7b0308bffc9c12ab209de80ec84ad052bcc4da8fd6befb1427906bcf2daaab1f`.

The public prompt now states two previously implicit cross-layer obligations:
an empty-following acknowledgement at `nextlsn > 0` has inclusive watermark
`nextlsn - 1`, and the existing React and Solid mutation hooks resolve to the
generated receipt. The reference adds only the two framework hook type
updates. The Dockerfile remains byte-identical because it already builds the
reducer guest before the repository tests and includes the locked full browser
toolchain.

The full generated-worker loopback now:

1. compares the runtime timeline identifier in a mutation receipt with the
   corresponding `SyncState` identifier, accepting generated camel or snake
   spelling;
2. saves public high-LSN values A and B without converting their carrier;
3. disconnects while retaining B, then reconnects to a peer reporting lower A
   and requires A to replace B; and
4. processes `LsnRange::Empty { nextlsn: B + 1 }` and requires the observed
   inclusive watermark to return to saved B.

Both framework packages are compiled with `tsc --noEmit` after the worker
declarations are generated. A separate public consumer derives the return type
of each exported `useMutate` hook and requires `Promise<MutationReceipt>`.
Package self-compilation alone was insufficient because an implementation can
consistently declare `Promise<void>` and discard the facade result. Rollup was
also insufficient because its TypeScript plugin emits stale-hook errors as
warnings. The stock-tool branch continues to execute the repository's actual
facade source and emits no skip.

### Exact patch-state matrix

The final matrix ran with networking disabled and all eight gates exited zero.
Logs are in `/tmp/sqlsync-gates.ujcg64` in the construction environment.

| State | Version-10 result |
|---|---|
| Pristine full repository tests and worker package | Pass |
| Tests-only baseline, full tools | Pass, zero JUnit failures/errors |
| Tests-only baseline, stock tools without `just`/`pnpm` | Pass, zero JUnit failures/errors |
| Tests-only focused `new` | Correctly rejected the absent API and emitted one JUnit failure |
| Solution-only lint, complete tests, examples, Wasm, and worker package | Pass |
| Solution plus tests, full generated-worker `new` | Pass; framework compilers, browser loopback, and Rust integration 4/4 |
| Solution plus tests, stock-tool portable `new` | Pass with zero failures/errors/skips |
| Solution plus tests, baseline | Pass |

Static artifact, application, word-count, leak, interface-neutrality, and
script-syntax checks also pass against the pristine frozen checkout.
The final gate logs are `/tmp/sqlsync-gates.ujcg64`; the complete negative and
positive matrices are `/tmp/sqlsync-mutations.qvye12` and
`/tmp/sqlsync-mutations.7tKkSi`. After isolating the hook consumer, the cleaned
receipt-discard replay is `/tmp/sqlsync-mutations.nv4Yfo`.

## False-positive audit - version 10

The worked Statig false-positive record was reread in full after the exact
participant artifacts were frozen. The following map links every public
requirement to its strongest behavioral oracle.

| Participant-facing requirement | Strongest version-10 oracle |
|---|---|
| Successful mutations return their exact timeline/LSN and failed mutations return no receipt or progress | Rust successful/failed mutation integrations |
| `local` is inclusive and survives complete retained-prefix removal | Rust real stage-order/rebase flow |
| `received` advances only after an observed acknowledgement | Held-ack generated-worker loopback and Rust caller-owned range flow |
| An empty-following acknowledgement preserves `nextlsn - 1` | Real worker/protocol empty-range frame compared with previously saved public B |
| `applied` waits for coordinator application, storage return, and rebase | Rust stage flow before and after return replication/rebase |
| Classification is timeline-bound, future-bounded, and Applied > Received > Local | Rust classification integration |
| Disconnect retains knowledge and a lower fresh peer observation replaces a larger stale one | Two disconnects plus B-to-A fresh reconnect in the real worker loopback |
| Receipt and snapshot runtime values identify the same timeline | Structural comparison of their generated runtime identifiers |
| `SQLSync.mutate` and `SQLSync.syncState` expose structured generated values | Type consumer, portable actual-source facade, and real facade/worker loopback |
| Browser LSNs exclude `number` and preserve high adjacent `u64` values | Type-level exclusion plus structurally distinct A/B observations above `2^53` |
| React and Solid mutation hooks resolve to `MutationReceipt` | Public type consumer over both packages' exported `useMutate` return types |

Fifteen source-shaped incorrect implementations were applied independently to
the exact reference/test pair. Every mutation changed production bytes; every
complete focused lane returned nonzero and emitted one failing JUnit result.

| Mutant | Plausible violated behavior | Version-10 result |
|---|---|---|
| `local_last` | Empty retained local range erases allocated history | Killed by Rust retained-prefix stage test |
| `applied_is_received` | Acknowledgement is treated as coordinator application | Killed by Rust stage ordering |
| `no_timeline_identity` | Numeric LSN alone classifies foreign receipts | Killed by Rust classification |
| `no_future_bound` | Unallocated future receipt is classified | Killed by Rust classification |
| `sent_is_received` | Sending a frame advances received | Killed by held-ack browser state |
| `js_number` | Generated LSN admits JavaScript `number` | Killed by TypeScript contract |
| `stale_reconnect` | First cached range is never refreshed | Killed by reconnect browser state |
| `monotonic_max_reconnect` | Lower fresh peer knowledge cannot replace stale B | Killed only at the new lower reconnect boundary |
| `reset_disconnect` | Disconnect erases last observation | Killed by disconnected state |
| `empty_ack_last_only` | Empty-following peer range becomes no acknowledgement | Killed only at the new empty-range boundary |
| `lossy_string` | Rust `u64` crosses `f64` before text | Killed by adjacent high-LSN browser values |
| `receipt_wrong_timeline` | Receipt exports a fabricated runtime timeline | Killed only by receipt/state runtime provenance |
| `facade_void_mutate` | Public facade discards its receipt | Killed by public type/runtime facade checks |
| `facade_missing_sync_state` | Public facade omits snapshot access | Killed by public type/runtime facade checks |
| `hook_void_mutate` | Framework hooks consistently discard the facade receipt as `Promise<void>` | Killed by the public exported-hook type consumer |

No attempted mutant survives the complete focused lane, so version 10 has no
survivor to promote to the complete pre-existing suite. Earlier cache,
disconnect, and lossiness survivors that passed the complete pre-existing suite
remain documented in the version-1 through version-7 audit; their distinct
oracles remain present. The reference itself passes the complete pre-existing
suite, examples, lint, reducer build, Wasm generation, and worker package.

Seven legitimate alternatives pass the complete focused lane: shallow-cloned
facade values; mutually renamed internal worker tags/wrappers; a renamed
acknowledgement accessor; a non-`Copy` receipt; direct `SyncState` return;
facade normalization from text to `bigint`; and framework hooks whose receipt
return is inferred through `ReturnType<SQLSync["mutate"]>` rather than spelling
`Promise<MutationReceipt>`. These positive trials demonstrate that the new
tests do not require reference identity, internal schema names, one Rust error
wrapper, one accessor, one browser carrier, or one hook declaration spelling.

Rejected additions remain private cache placement, exact browser field casing,
demo-component propagation, arbitrary acknowledgement permutations, and
additional fixtures for already-covered comparisons. They either lack a
participant-facing contract or do not add a distinct semantic boundary. Zero
survivors is evidence only for the fifteen attempted families.

### Solver-patch replay and calibration consequence

All four supplied version-9 working-pool patches were replayed unchanged in the
full frozen-tool lane after the four behavioral discriminators were added. All
retain their legitimate version-9 verdict, but none satisfies the revised
prompt: run 1 reaches and fails only the empty-following acknowledgement; runs
2 and 3 first fail the existing high-LSN observation because they clamp a peer
watermark to the low local watermark; run 4 reports stale React/Solid
`Promise<void>` types and also fails the empty-following acknowledgement. The
final hook consumer only strengthens run 4's existing failure. As an exact-
artifact replay after that consumer was frozen, unchanged run 1 still fails at
the empty-range boundary. All four continue to pass the four Rust integration
tests. These old-prompt replays are diagnostic and are not version-10
calibration runs.

To check that the empty-range probe does not select the reference architecture,
run 1 was replayed with only its observation expression changed from
`range.last()` to `range.last().or_else(|| range.next().checked_sub(1))`. That
non-reference solution passes the complete final-hash version-10 focused lane;
its log is `/tmp/sqlsync-v10-replay-run1-repaired-final.log`. Together with the
seven positive variations and the reference pass, this establishes solvability
while preserving multiple implementation modes.

The prior immutable version's 4/4 working-pool solve rate is historical and
triggered the documented hardening rule. Because prompt, tests, and reference
changed, version-10 calibration is exactly **0/10**. No prior solve or unused
slot carries forward; fresh unhinted runs must start a new ten-run batch.

### Immutable version-10 identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `95cdb7ed51e8bb5445cae82a87d1696dc2a6c3ade8fe40a31c78eb7c0d6f8471` |
| `test.patch` | `c695091833324c02bba3bf5f7d7a36621b0816ecbf6ddd2bea3b2db2dd2dbb85` |
| `solution.patch` | `bdd7f60af51ccb1d31897db5dfa23bb90088d7bb18b966e82bbc5eb0704762c2` |
| `Dockerfile` | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |
| frozen `Cargo.lock` | `63f0804dcca844caf0de898e929789596b69ead37bdc093bcc5c8ac3bd692be7` |
| frozen `pnpm-lock.yaml` | `2d978bf39debf9171c4686b849dbb46d7da5e6fc1339b00e5d11eaa7bfc7ea06` |
| amd64 v10 image | `sha256:7b0308bffc9c12ab209de80ec84ad052bcc4da8fd6befb1427906bcf2daaab1f` |

`CALIBRATION_STRATEGY.md` was reread before interpreting the 4/4 evidence.
Version 10 is verified and false-positive audited, but it is not submission-
ready until a fresh immutable 10-run calibration completes within the accepted
1-5 solve band and supplies the platform agent-message metric.

## Trajectory-informed editorial revision gate - version 11

Before editing the public description on 2026-08-02,
`PROBLEM_DESIGN.md` and `instructions/03-problem-description.md` were reread.
The repository, problem, candidate, and success indexes were searched again for
SQLSync, observed progress, mutation receipts, and sync state. The current
`SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and `RUNS.md` records were
reviewed together with the four raw same-task run bundles in `agent-runs1`.
Those four runs remain legitimate version-9 passes; no same-task near-pass or
broad failure exists to inspect.

The requested deletion removes only a redundant opening summary. Every public
behavior it names remains stated concretely: `LocalDocument::mutate` returns the
exported receipt, `LocalDocument::sync_state` exposes the snapshot, the receipt
and snapshot carry timeline identifiers, and the later worker directives state
their generated public return types. No requirement, discriminator, test, or
reference behavior changes.

| Editorial evidence | Preserved public invariant | Oracle | Boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The opening sentence restates the concrete API directives immediately following it. | Successful mutations return timeline-bound receipts and callers can observe per-document sync state. | Existing Rust, generated-worker, facade, and framework tests remain byte-identical. | Public description clarity | Deleting duplicated prose neither adds an unstated contract nor selects an implementation. |

The discriminator ledger from version 10 therefore remains complete and is not
expanded. `test.patch` and `solution.patch` must remain byte-identical for this
editorial version; calibration still restarts at 0/10 because `meta.md` is a
participant artifact.

## Immutable construction and false-positive audit - version 11

Version 11 was frozen on 2026-08-02 from the same pinned commit. The requested
opening sentence was deleted, reducing the participant description from 319 to
304 words. The remaining concrete directives still state every mapped behavior.
`test.patch`, `solution.patch`, and Dockerfile are byte-identical to version 10.
The unchanged amd64 image was tagged `olympus-sqlsync-observed-base:v11`; its ID
remains `sha256:7b0308bffc9c12ab209de80ec84ad052bcc4da8fd6befb1427906bcf2daaab1f`.

The full eight-state gate matrix was rerun with networking disabled and passed;
logs are in `/tmp/sqlsync-gates.t3fYvV`. The exact static audit passed against a
pristine checkout. The version-10 requirement-to-oracle map remains exhaustive
because no requirement or oracle changed. All fifteen isolated incorrect
implementations were rerun and killed (`/tmp/sqlsync-mutations.SqE2El`), while
all seven legitimate alternatives passed (`/tmp/sqlsync-mutations.bYTabo`). No
new survivor or artificial discriminator was introduced.

Representative solver replay was repeated against the exact version-11
artifacts. Unchanged run 1 fails only the empty-following acknowledgement
(`/tmp/sqlsync-v11-replay-run1-unchanged.log`); the same non-reference patch
with only its public empty-range derivation repaired passes the complete lane
(`/tmp/sqlsync-v11-replay-run1-repaired.log`). This supplies both failing and
legitimate replay evidence without selecting the reference architecture.

| Artifact | Version-11 SHA-256 |
|---|---|
| `meta.md` | `0d526509bcdda9850f21289fa43d61d59c4447a8e76b6292226ca9d72f56faf9` |
| `test.patch` | `c695091833324c02bba3bf5f7d7a36621b0816ecbf6ddd2bea3b2db2dd2dbb85` |
| `solution.patch` | `bdd7f60af51ccb1d31897db5dfa23bb90088d7bb18b966e82bbc5eb0704762c2` |
| `Dockerfile` | `5c0ca332d855fd0db4a5e4ffffc3045f0ad80458ce9fa7ded5a22bddd51af3e5` |

`CALIBRATION_STRATEGY.md` was reread before interpreting the editorial change.
Version 11 has no solver calibration result and starts at exactly **0/10**. It
is verified and false-positive audited, but not submission-ready until a fresh
immutable ten-run calibration lands in the 1-5 solve band and supplies the
platform agent-message metric.

## Trajectory-informed redesign gate - version 12

The 2026-08-02 redesign begins a new immutable version. Before changing
`test.patch`, `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, and the current
problem-description/test instructions were reread. Searches covered the
problem, candidate, and success indexes plus the compact SQLSync records. All
four raw bundles in `agent-runs2` were inspected directly: evaluator verdicts,
test logs, solution and workspace patches, trajectories, and final metrics.

All four are legitimate version-11 passes. Their solution-patch hashes, in run
order, are
`3aa130d30e8221d08d06568344b5e3b05ed150fb0e938feb107d73241c4f11b0`,
`743ff68cbaeac26677287bbaabca4a5a08f1f8fe3baad7fb8bab1d9c4adf88f0`,
`3df8c9eb064aa58a57fd1e43f9b5651fabd299915900eb8bcae8c8fe41290d2c`,
and `7e73e76f17b4e7ba9bc8690adb4969996eee620d2ec02f0ee050564cbcb0fd86`.
They change 11/11/12/11 production files with 287/322/358/302 raw additions
and 22/22/21/16 deletions. The exported trajectory schema contains six outer
conversation records and token totals but no platform agent-message count or
raw tool-call stream, so neither is inferred. No same-task near-pass or broad
failure exists in this batch.

Every grading log selected `PORTABLE_FACADE_PROBE`: the solve images lacked
`pnpm`, `wasm-pack`, and the Wasm Rust target, and target installation failed
through the network tunnel. Thus the recorded grader never exercised the real
worker/coordinator path. Each solution was subsequently replayed in the frozen
full-tool image against the generated Wasm browser loopback; all four also pass
that existing probe. The 4/4 result again gives the documented 97% posterior
probability that the solve rate exceeds 50%, so version 11 is abandoned rather
than extended.

The implementations converge on a pull-only snapshot: each exposes
`SQLSync.syncState`, but applications must poll to learn local or received
transitions. The upstream issue and repository's existing query and connection
listener machinery support a distinct push boundary: a per-document sync-state
subscription suitable for UI observation. This is an inverted data flow across
local mutation signals, coordinator acknowledgement processing, Wasm events,
and the public facade. It is not another watermark fixture.

The exact phrase "generated `Lsn` type" is also unnecessary provenance. The
public contract needs only an exported lossless non-`number` LSN type; its
source or generation mechanism is not behavioral.

### Version-12 discriminator ledger

| Evidence / plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| All four passes implement only snapshot polling despite the repository's event/subscription architecture and upstream UI-state demand. | A caller can subscribe per document, receive the current snapshot, observe subsequent local-mutation and coordinator-acknowledgement changes without polling, and stop delivery by unsubscribing. | Public `SQLSync` subscription over the real generated worker; drive mutation and coordinator observations and compare emitted structured states. | Push observation across Rust/Wasm/TypeScript | Uses the existing event channel and public values but does not prescribe inner event tags, cache placement, or listener storage. |
| Every official grading log silently chose a synthetic facade double. | Worker-side acknowledgement retention and generation replacement must be exercised by the focused lane in every passing environment. | Remove the passing portable fallback; the offline image must build and run the generated Wasm loopback. | Test-environment integrity | This changes no participant behavior and prevents a partial worker implementation from passing on facade shape alone. |
| Review feedback identifies generated-type provenance as unnecessary. | The worker exports an LSN type that excludes JavaScript `number` and preserves all Rust `u64` values. | Structural type and high-value runtime checks only. | Public representation | String, bigint, word pair, generated alias, or handwritten alias remain valid. |

Potential lower acknowledgements later on the same WebSocket were rejected as
a discriminator. The ordered replication protocol treats such a range as an
invalid sequence, so manufacturing it would test an adversarial state the
repository cannot legitimately produce. Exact internal event names, delivery
counts for duplicate equal snapshots, hook additions, and an await-until-
applied API are likewise rejected: they are either private, redundant, or a
different feature.

This gate is complete before any version-12 test edit. The live subscription is
public and repository-supported, its oracle is end-to-end, and it adds a new
implementation boundary. Version-12 calibration starts at 0/10 after all patch
states and the false-positive audit are rerun.

The subscription contract is intentionally limited to local-mutation and
coordinator-acknowledgement changes. Applied-after-rebase remains part of the
snapshot contract, but is not separately promised as a pushed event because
the focused browser coordinator exercises the acknowledgement half of the
bidirectional protocol. This avoids claiming an untested notification edge.

## Version-12 exact false-positive audit

The worked Statig false-positive record was reread before approving the new
suite. The audit uses the exact version-12 participant artifacts and the frozen
`linux/amd64` image. Its method is requirement mapping, isolated plausible
mutations, full-suite execution for meaningful survivors, public black-box
probe repair, positive implementation variations, and representative solver
replay.

### Requirement-to-oracle map

| Participant-facing requirement | Strongest behavioral oracle |
|---|---|
| Successful mutation returns the exact timeline-bound allocated LSN; failure returns no receipt and does not advance local progress | Rust `successful_mutations_return_timeline_bound_exact_receipts` and `failed_mutation_does_not_advance_local_progress` |
| `local`, `received`, and `applied` are inclusive conservative watermarks with retained-prefix history | Rust `stage_order_and_retained_prefix_are_observable`; browser empty-following acknowledgement |
| Receipt classification is timeline-bound, future-bounded, and ordered Applied > Received > Local | Rust `classification_is_timeline_bound_bounded_and_precedence_ordered` |
| Sending is not receiving; application follows coordinator return and rebase | Held-ack browser loopback plus Rust caller-owned replication/application flow |
| Observed acknowledgement survives disconnect and a fresh lower peer range replaces stale higher knowledge | Real browser disconnect and lower-reconnect sequence |
| Empty peer ranges retain `nextlsn - 1` knowledge | Rust retained-prefix case and real browser empty-following range |
| `SQLSync.mutate` and `SQLSync.syncState` expose structured exported values tied to one runtime timeline | Structural TypeScript consumer and real facade/generated-worker loopback |
| Browser LSNs preserve every `u64` and exclude JavaScript `number` | Structural declaration check and adjacent `9007199254740992`/`9007199254740993` browser observations |
| React and Solid mutation hooks return the receipt | Strict package builds plus public hook consumer |
| `subscribeSyncState` exposes its public type and returns an unsubscribe function | Structural TypeScript consumer |
| A sync-state subscription receives current state, a post-mutation local change, and a post-acknowledgement received change | Real facade/generated-worker loopback after waiting for a stable connected state |
| Unsubscribe stops later delivery | Real worker receives a later acknowledgement while callback count remains unchanged |

### Mutation results

Nineteen isolated plausible incorrect implementations are rejected by the
focused lane:

| Mutation family | Mutants | Result |
|---|---|---|
| Local/applied watermark collapse | `local_last`, `applied_is_received` | Killed by Rust stage/retained-prefix behavior |
| Receipt identity and bounds | `no_timeline_identity`, `no_future_bound`, `receipt_wrong_timeline` | Killed by Rust classification or browser timeline agreement |
| Acknowledgement timing and retention | `sent_is_received`, `stale_reconnect`, `monotonic_max_reconnect`, `reset_disconnect`, `empty_ack_last_only` | Killed by held-ack, disconnect, lower-fresh, or empty-following behavior |
| Browser precision | `js_number`, `lossy_string` | Killed by type exclusion or adjacent high-value observation |
| Public wrappers | `facade_void_mutate`, `facade_missing_sync_state`, `hook_void_mutate` | Killed by public consumers or facade execution |
| Live observation | `subscription_no_current`, `subscription_no_local_events`, `subscription_no_ack_events`, `subscription_no_unsubscribe` | Killed respectively by initial, stable post-mutation, same-connection acknowledgement, and post-unsubscribe browser checks |

The first `subscription_no_local_events` prototype survived the initial
focused suite: a connection-status event queued around document opening could
carry the new local watermark despite the missing timeline notification. It
also passes the complete pre-existing `just test` lane (23 core tests, docs,
both end-to-end examples, and reducer host). The repaired probe waits for the
connection to be stably connected, records the callback boundary, then accepts
only a post-mutation state. Reference behavior passes and the survivor fails;
the other three new subscription mutations remain independently killed.

### Legitimate variations and rejected probes

Eight positive variations pass the complete focused lane: cloned facade and
pushed state values; renamed private mutation/snapshot worker schema; renamed
acknowledgement accessor; non-`Copy` receipt; direct Rust snapshot return;
consistent facade conversion from worker strings to `bigint` for polled and
pushed values; inferred framework-hook receipt type; and renamed private
subscription request/event names. These demonstrate that the suite does not
pin JavaScript reference identity, a Rust wrapper, LSN carrier, private Rust
accessor, or inner worker protocol spelling.

Rejected additions are unchanged: a decreasing acknowledgement on one ordered
WebSocket is not a valid repository protocol sequence; exact inner event tags,
duplicate-equal notification counts, listener-container layout, and multiple-
listener scheduling are private or combinatorial rather than new public
boundaries. Applied-after-rebase push notification was removed from the public
subscription clause instead of being tested synthetically; applied progress
itself remains covered by the Rust snapshot contract.

All four legitimate version-11 solver patches fail unchanged on version 12 at
the public `SyncStateSubscription`/`subscribeSyncState` compile and runtime
boundary. The version-12 reference and every positive variation pass. Thus the
new discriminator separates the reviewed pull-only architecture without
copying a private reference design or imposing an impossible path.

### Immutable audit record

The final eight patch-state gates pass in
`/tmp/sqlsync-gates.FPfS6c`; the combined lane logs `BROWSER_PROBE` with 13
subscription observations, while the deliberately stripped tool lane reports
missing `pnpm` and a failing, non-skipped JUnit result. All nineteen mutants are
killed in `/tmp/sqlsync-mutations.dcIR8Q`. All eight positive variations pass
together in `/tmp/sqlsync-mutations.HKIXed`. The original meaningful survivor's
complete-suite run is `/tmp/sqlsync-v12-survivor-full.log`, and unchanged
version-11 replays are `/tmp/sqlsync-v12-replay-1.log` through `-4.log`.

Frozen identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:2ea5f63dd66f30f4b52be34a723f8328e1f83f9a96922d1078239054a80c0629` |
| `meta.md` | `6e1f6a05d6549bbcff79e91f2d060a8ac97ff8c8e454c3f5a582107a48dc8b89` |
| `test.patch` | `f31ca4a2563162a3c9eac01b20d0d387a07c9c8caa3d0d0cb5b6193949a437bc` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `ee54fbd1422858059bdeb6c28d348140b07ae262c893eede3c6a3b044fb7f66b` |
| `verify/audit.sh` | `24b5a9a520a45413940f11f5398ce473683e35a71fbec279dc27a3a65d2bb45d` |
| `verify/gates.sh` | `92e3d2b3f4e1cd4aa336cd92e0340975b196167d652055553fcbbacc0da867b5` |
| `verify/mutations.sh` | `a4e969e81c44cf8a762720c296a81fcec1ec6fcc84e803487ce3e6a76c7769eb` |
| `verify/README.md` | `bc9b57a8962ab0620328500f50d83603cff4a586bb7e40492e9e1bf76c5f1a45` |

This exact version has no actionable survivor in the attempted mutation set
and retains the documented legitimate alternatives. It is immutable at fresh
calibration 0/10; the earlier 4/4 batches and diagnostic replays do not carry
forward.

## Version-13 editorial interface gate

The 2026-08-02 interface review was handled as a description-only revision.
Before editing `meta.md`, `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the
problem/candidate indexes, the version-12 compact records, and the problem/test
instructions were reread. Raw version-11 pass trajectories 1 and 4 were
reinspected as representative architectures, and all four raw bundles were
searched for the new subscription names. As previously recorded, this history
contains four legitimate passes and no same-task near-pass or broad failure;
none implemented the later live-subscription API.

The test suite already compiles a public consumer that imports the exact name
`SyncStateSubscription`, constructs `{ handleState(state) { ... } }`, and
passes it to `subscribeSyncState`. Naming that exported public type in the
description closes a T5 interface-information gap; it does not select an inner
worker tag, event wrapper, listener layout, or reference implementation.

Conversely, spelling the Rust structs' fields and enum variants inline in the
opening sentence is unnecessary. The remaining behavioral prose still defines
receipt timeline/LSN identity, the three named progress watermarks, and Local /
Received / Applied precedence. Removing the inline layouts therefore changes
no behavior or oracle and reduces implementation-shape prescription.

### Version-13 discriminator ledger

| Review evidence | Fair public contract | Existing oracle | Decision |
|---|---|---|---|
| The public type consumer requires a named `SyncStateSubscription`, but version 12 only names the callback parameter structurally. | Export `SyncStateSubscription`; values with `handleState(state)` are accepted by `subscribeSyncState`. | Structural TypeScript consumer plus real facade/worker subscription loopback. | State the exact public export name. |
| Inline Rust layouts repeat semantics defined by the following paragraphs. | Export `MutationReceipt`, `MutationStatus`, and `SyncState` with the stated behavior. | Existing Rust receipt, watermark, and classification tests. | Remove only the opening inline field/variant spelling. |

No hidden test, reference behavior, or discriminator changes in this editorial
revision. Because `meta.md` and the Docker base line are participant artifacts,
version 13 starts at 0/10 and cannot inherit version-12 verification or
calibration evidence. The Docker rebuild and exact audit remain intentionally
pending after the operator requested only the base-image edit without running
verification.

## Version-14 interface and representation gate

The 2026-08-03 review resumes design from the unverified version-13 editorial
artifact. `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the public-description
and test instructions, current compact records, representative raw version-11
pass trajectories 1 and 4, and all four raw run bundles were reread/searched.
The history still provides four legitimate passes and no same-task near-pass or
broad failure; none covers the later subscription boundary.

Three test-facing interface assumptions are public API choices rather than
private implementation details: Rust callers construct receipts and snapshots
with public struct literals, callers directly inspect snapshot watermarks, and
the initial subscription callback is delivered before the subscription promise
resolves. The opening sentence remains concise, as requested in version 13;
these concrete source-compatibility contracts will be stated separately where
their observable behavior is described.

The browser test does not compare public LSN values to JavaScript `bigint`: it
compares receipt and state values structurally to other values returned by the
same public API. However, its private WebSocket fixture currently uses BigInt
constants and `Buffer.writeBigUInt64LE`, which can be mistaken for a public
carrier constraint. Version 14 will encode protocol `u64` values from decimal
text into two 32-bit words. Public assertions remain opaque and still require
adjacent values above `2^53` to stay distinct.

### Version-14 discriminator ledger

| Review evidence | Fair public invariant | Black-box oracle | Decision |
|---|---|---|---|
| Rust integration uses receipt literals and equality. | `MutationReceipt` is a public struct with public `timeline_id` and `lsn` fields. | Ordinary downstream Rust construction and comparison. | State the concrete public layout outside the opening summary. |
| Rust integration constructs snapshots and reads their watermarks. | `SyncState` is a public struct with public `timeline_id`, `local`, `received`, and `applied` fields. | Ordinary downstream Rust construction, field reads, and classification. | State the concrete public layout outside the opening summary. |
| Browser test checks the callback synchronously after awaiting subscription establishment. | The current snapshot is delivered before `subscribeSyncState` resolves. | Real facade/generated-worker call followed by an immediate callback-count assertion. | State the ordering guarantee explicitly. |
| Raw test frames use BigInt even though public values are compared opaquely. | Any lossless public non-`number` LSN carrier remains valid. | Generate high protocol values from decimal text/word pairs; compare only public-to-public structured values. | Remove BigInt entirely from the browser fixture. |
| Docker review cannot see a literal Cargo build and questions lockfile presence. | The offline image has compiled Rust dependencies and a committed frozen pnpm lock. | Explicit `cargo build --workspace --all-features --locked`; assert `pnpm-lock.yaml` exists before frozen install. | Make both build-cache steps literal; retain the allowed `olympus-base-rust:latest` first line. |

No new behavioral discriminator is added. The representation rewrite removes
an apparent over-constraint, while the prompt additions document contracts
already enforced by public-consumer tests. `test.patch`, `meta.md`, and the
Dockerfile must be treated as a fresh immutable version and audited from 0/10.

## Version-14 exact false-positive audit

The complete false-positive protocol was repeated for the exact version-14
artifacts after the prompt, fixture, and environment changed. The version-12
requirement map remains applicable, with these strengthened public-interface
oracles:

| Participant-facing requirement | Strongest version-14 oracle |
|---|---|
| `MutationReceipt` has public `timeline_id` and `lsn` fields usable in an ordinary struct literal | Rust integration constructs fresh receipts by public struct literal before classification |
| `SyncState` has public `timeline_id`, `local`, `received`, and `applied` fields and readable watermarks | Rust integration constructs snapshots by public struct literal and reads all three progress fields |
| `SyncStateSubscription` is a named worker export accepted by `subscribeSyncState` | Structural TypeScript consumer imports the exact type, supplies `handleState`, and passes it to the method |
| The current subscription snapshot is delivered before establishment resolves | The real facade/generated-worker probe awaits `subscribeSyncState` and immediately rejects an empty callback history without another wait or event-loop turn |
| Every Rust `u64` survives the public browser boundary without admitting JavaScript `number` | Type-level exclusion and structurally distinct adjacent public values above `2^53`; raw protocol frames are assembled from decimal text and 32-bit words, with no BigInt API or literal in the test fixture |

The other public clauses retain their exact version-12 oracles: successful and
failed mutation identity, conservative inclusive local/received/applied state,
acknowledgement versus application ordering, timeline and future bounds,
disconnect retention, lower fresh-connection replacement, empty-following
history, runtime receipt/state timeline agreement, React/Solid receipt returns,
post-mutation and post-acknowledgement subscription delivery, and unsubscribe.

All nineteen isolated source-shaped mutants are killed in
`/tmp/sqlsync-mutations.P50aZe`. In particular,
`subscription_no_current` fails the immediate post-resolution assertion, and
the retained-prefix, acknowledgement, reconnect, identity, precision, facade,
hook, and remaining subscription mutants continue to fail their distinct
public boundaries. No attempted mutant survives the focused suite. The earlier
meaningful late-connection-event survivor and its complete-suite result remain
recorded in the version-12 audit; the repaired stable-connection oracle remains
present in version 14. No new arbitrary or private mutant was added.

All eight legitimate variations pass in `/tmp/sqlsync-mutations.30pwoX`:
cloned values, mutually renamed private worker schema, a renamed
acknowledgement accessor, a non-`Copy` receipt, direct `SyncState` return,
facade conversion to public `bigint` LSN values, inferred hook receipt typing,
and renamed private subscription schema. The public-bigint variation is the
positive check that removing BigInt from the raw fixture did not outlaw BigInt
as an implementation's lossless carrier. Four legitimate version-11 solver
patches were replayed at `/tmp/sqlsync-v14-replay-1.log` through `-4.log`; each
is rejected only at the later named subscription API and not by layout or LSN
representation assumptions.

The exact eight-state matrix passes in `/tmp/sqlsync-gates.HYNaLd`: pristine,
tests-only base with full and stock tools, focused tests-only rejection,
solution-only full lint/tests/package, combined focused, deliberate missing-
browser-tools rejection, and combined base. The combined lane logs the real
`BROWSER_PROBE` with 13 subscription observations. The missing-tools lane fails
with `required browser integration tool is missing: pnpm`; it is not skipped.
A transient disposable Rosetta container mutex was discarded, and the entire
matrix was replayed cleanly before recording these results.

The Docker image begins with the required
`public.ecr.aws/d3j8x8q7/olympus-base-rust:latest`, explicitly runs
`cargo build --workspace --all-features --locked`, verifies the committed
`pnpm-lock.yaml`, and completes frozen pnpm install, repository build, and
worker packaging during construction. Its `linux/amd64` image identifier is
`sha256:417afd7222c5f8eb338a5e935d2b6de88e70f0029901046fd0531f3eaca84041`.
The unpinned apt package versions are an acknowledged soft reproducibility
warning; they were not fabricated into unavailable version pins. Locked Rust
and pnpm dependencies, explicit tool checks, the frozen base tag, and the
network-disabled runtime gates are the enforced environment controls.

Frozen version-14 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:417afd7222c5f8eb338a5e935d2b6de88e70f0029901046fd0531f3eaca84041` |
| `meta.md` | `8e30e78ae50bb4ddf2cf130873494ad45d4fbed3c1880be13c620c44d5c1a464` |
| `test.patch` | `968dcd60fb80700de5e06a45f5710f95292573cfb461094defd063b361038e06` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `3dd9204aa1419982e42ce1194258bd3b7c08547f8389ffbb55082ee63f4587a2` |
| `verify/audit.sh` | `429608b94c5cef4582c617c501a4546da9350b75c5f0d413bbea641fe039de47` |
| `verify/gates.sh` | `45454527ae61be2cd88bbedde13d9fd521ce10a9a4c1b5cef055a9ea2e7eda3a` |
| `verify/mutations.sh` | `347de0f609871affbe39bd9498be186b76aeb430d1242777d495890be9e97b6d` |
| `verify/README.md` | `14eeba7dbc1a99743fdfc48936814df07aa1151683c9a4f57bb2b8fc6550cfe7` |

Version 14 has zero survivors in the attempted mutation set, preserves the
documented alternative architectures, and begins a new immutable calibration
batch at exactly 0/10. No version-9, version-11, or earlier verification result
or unused run carries forward.

## Version-15 doctest environment gate

The 2026-08-03 environment review follows a reported plain-`cargo test` failure
in the `sqlsync-wasm` doctest harness: rustdoc was passed
`--extern sqlsync=/app/target/debug/deps/libsqlsync.rlib`, but that cached
artifact was absent. Before revising `test.patch`, `PROBLEM_DESIGN.md`, the
current problem compact records, the SQLSync run bundles, and repository-wide
doctest history were searched again. Representative version-11 pass
trajectories 1 and 4 compile `sqlsync-wasm` but contain no distinct doctest
architecture or failure; there is still no same-task near-pass or broad
failure. This is environment evidence, not a new solver shortcut.

Repository inspection shows that `sqlsync-wasm` is a `cdylib`/`rlib` Wasm
bridge and its source contains no rustdoc comments or fenced doctest examples.
The harness therefore always reports `running 0 tests`. The exact v14 image was
rechecked in pristine, solution-only, and solution-plus-test states: plain
offline `cargo build && cargo test`, as well as the split workspace `--lib` and
`--doc` commands, currently pass. The external missing-artifact report is still
actionable because a cache/materialization difference can fail an empty host
rustdoc harness before any participant behavior is exercised.

### Version-15 environment ledger

| Evidence | Fair invariant | Verification | Decision |
|---|---|---|---|
| The Wasm bridge has no doctest source, but its empty host harness can fail on a missing cached dependency rlib. | Every real upstream test and every participant-facing focused test runs offline; an empty, target-inappropriate harness must not decide the result. | Add `doctest = false` only to `sqlsync-wasm` in the injected test manifest; run plain workspace `cargo test`, the remaining workspace doctests, real browser/Wasm integration, and focused Rust tests. | Treat this as test-environment metadata, not a public behavior discriminator. |
| Docker rules prohibit running tests while constructing the image. | Build dependencies and artifacts during Docker construction; execute tests only after patch injection. | Retain explicit locked `cargo build` and verify the runtime commands in a fresh container. | Do not hide the issue with a Docker `RUN cargo test`. |

No executable test or documentation example is skipped: the disabled harness
contains zero cases, while doctests for `sqlite_vfs`, `sqlsync`,
`sqlsync_reducer`, and `testutil` remain enabled. The public prompt, reference
behavior, feature discriminators, and solution patch are unchanged.

Per the operator's explicit direction, the false-positive mutation audit is
not rerun in this round. Consequently version 15 cannot be called immutable,
false-positive-audited, calibrated, or submission-ready. Focused environment,
baseline, and solution verification will be recorded after the patch is
changed.

### Version-15 focused verification record

`test.patch` now adds only `doctest = false` to the existing `[lib]` section of
`lib/sqlsync-worker/sqlsync-wasm/Cargo.toml`; its SHA-256 is
`8caa84f7362f1f85947ab2fb52207f6658973497127fcd9980dc3bf7bde8ff52`.
The public prompt and solution patch remain byte-identical to version 14. The
Dockerfile now performs a final targeted locked host build of the `sqlsync`
library after worker packaging and asserts that
`target/debug/deps/libsqlsync.rlib` exists. It still runs no tests while
building the image.

All eight offline patch-state gates pass in `/tmp/sqlsync-gates.wiMsNz` against
the rebuilt final image:
pristine, tests-only base with full and stock tools, expected focused tests-only
rejection, solution-only lint/tests/package, combined real-browser focused
tests, deliberate missing-browser-tools rejection, and combined base. No JUnit
skip was introduced. The combined focused lane still passes four Rust
integrations and the generated Wasm/browser subscription probe.

A clean fresh-container replay asserted the materialized rlib, then ran plain
`cargo build --offline --locked` followed by `cargo test --offline --locked`
before either patch was applied. It exits zero, including the empty
`sqlsync-wasm` doctest harness. A second fresh-container replay applies both
patches and runs the same plain commands; it exits zero with all 23 core tests,
four focused integrations, all workspace unit targets, and the remaining
`sqlite_vfs`, `sqlsync`, `sqlsync_reducer`, and `testutil` doctest harnesses.
After test injection Cargo no longer launches `Doc-tests sqlsync_wasm`, so the
reported missing rlib cannot fail that zero-case harness.

The version-15 static artifact check passes with
`verify/audit.sh` SHA-256
`bca9b41abec32eb4ea2367a853b75ca90958e4ca1f1b2cbc6cf3c68776fca252`.
This is a hash/application/leak check, not the mandatory false-positive
mutation audit. As directed, the 19-mutant and eight-variation suites were not
rerun. Version 15 therefore remains at 0/10 and explicitly awaits that audit
before any submission-ready or immutable claim.

Current version-15 identifiers, pending the deferred mutation audit:

| Artifact | SHA-256 / identifier |
|---|---|
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `8e30e78ae50bb4ddf2cf130873494ad45d4fbed3c1880be13c620c44d5c1a464` |
| `test.patch` | `8caa84f7362f1f85947ab2fb52207f6658973497127fcd9980dc3bf7bde8ff52` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `bca9b41abec32eb4ea2367a853b75ca90958e4ca1f1b2cbc6cf3c68776fca252` |
| `verify/gates.sh` | `835c668b61282ab5188c5625a67722c8f3dd0290b53be2caab39b4c70b73f845` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `2c9d60ae6bc4b0e211a4c6c98f2f7ac1f0fbe9e906b75b111aeda020225e6f44` |

## Version-16 trajectory-informed browser-state gate

The 2026-08-03 hardening review starts from the new `agent-runs3` working-pool
bundle. Before revising `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, all current SQLSync compact records, repository-wide
sync-state/doctest history, and the four raw run bundles were read or searched.
Each run's evaluator record, test log, solution patch, workspace patch, and
trajectory were inspected directly.

Version 15 produced two legitimate passes and two near-passes in four unhinted
Nova runs:

| Run | ID | Verdict | Production shape and observed boundary |
|---|---|---|---|
| 1 | `rd722372r6jzn8ntbrs7a8cebh8bsy42` | Near-pass | 11 production files, 393 additions/26 deletions. Implemented core, worker, hooks, and subscription delivery, but annotated Rust `u64` as TypeScript `bigint` without changing serde runtime conversion; failed only at the first high browser LSN. |
| 2 | `rd71vkvej51gknrqtnq9je0d698bs5bg` | Legitimate pass | 11 files, 328 additions/28 deletions. Used decimal-string worker LSNs, worker-owned connection observation, and broadcast subscription events. |
| 3 | `rd75n29cbayz2h0s2gmes51c6n8bsbgm` | Legitimate pass | 12 files, 410 additions/26 deletions. Used decimal-string LSNs, protocol-owned acknowledgement state, and value-deduplicated subscription delivery. |
| 4 | `rd76aed695qqn1p3tyeqn5tjgh8brdyz` | Near-pass | 12 files, 462 additions/36 deletions. Implemented cached applied state and subscription events but made the same declaration-only `bigint` mistake as run 1; failed at runtime high-LSN serialization. |

The trajectory schema reports six outer records plus token totals, not the
platform agent-message metric; those values are not substituted. There is no
broad same-task failure in this batch. Runs 1 and 4 are representative
near-passes, runs 2 and 3 demonstrate distinct legitimate ownership and event
architectures, and all four are substantial cross-layer implementations. The
2/4 version-15 result is within the eventual difficulty band, but changing the
tests abandons that batch and resets version 16 to 0/10.

All four browser logs repeatedly expose `applied: undefined`. Their Rust paths
do implement applied lookup, and their worker code generally attempts a
post-rebase state send, but the current browser fixture never performs real
coordinator application/storage return. Consequently it cannot distinguish a
correct core from a worker export that omits `applied` or never propagates its
advance. Independently, the lower-reconnect and empty-following subscription
assertions search the entire observation history. Each target value was emitted
earlier, so polling can observe the new snapshot while no fresh callback occurs.

### Version-16 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Every run's browser log leaves `applied` undefined; the fixture drives acknowledgements but no coordinator application/storage return. | The exported worker `SyncState` includes `applied`, and polling it advances only after coordinator application is replicated back and rebased locally. | Compile a public field consumer, then run the real generated Wasm worker against a test coordinator using the repository's existing `CoordinatorDocument` and `ReplicationProtocol`; assert undefined before application and equal to the receipt only after storage return/rebase. | Coordinator apply -> storage frames -> Wasm rebase -> public worker value | Uses public state plus the repository's native coordinator/protocol. It permits cached or queried applied state, string/bigint/other exact carriers, and all reviewed event architectures. |
| Existing lower/empty subscription assertions can match stale observations. | Each later observed acknowledgement change promised through the subscription produces a callback after that change begins. | Record the callback-array boundary immediately before lower reconnect and before the empty-following frame; accept only a matching state in the later slice. | Event freshness across connection generation and retained-prefix acknowledgement | Tests temporal delivery rather than callback count, private event tags, or listener storage. Both broadcast and value-deduplicated passing architectures remain valid. |
| Runs 1 and 4 changed only declarations while runtime serde still used JS number. | Public LSNs are lossless at runtime, not merely in declarations. | Retain the existing adjacent high-u64 real-Wasm observation. | Rust/Wasm serialization | Already distinguishes a recurring trajectory shortcut without selecting string versus bigint. |

No applied subscription event is added: the public subscription contract names
local mutation and coordinator acknowledgement changes, while applied progress
is promised through `SyncState` itself. Exact private worker event names,
duplicate-equal delivery counts, one coordinator process layout, or an internal
rebase signal remain out of scope. The native coordinator is test
infrastructure and communicates only through the pre-existing replication wire
protocol.

This gate is complete before the version-16 test edit. Per explicit operator
direction, the false-positive mutation audit will not run in this round. The
revised prompt/tests/environment must therefore remain audit-pending and cannot
be called immutable or submission-ready even if all patch-state gates pass.

### Version-16 focused verification record

The revised public prompt, reference solution, and Dockerfile are byte-
identical to version 15. `test.patch` adds one native test-only coordinator
example, compiles that helper after the existing task reducer, reads the public
TypeScript `SyncState.applied` field, drives a second real generated-worker
document through acknowledgement then coordinator application/storage return/
rebase, and restricts the lower-reconnect and empty-following subscription
oracles to fresh callback slices.

The reference passed the strengthened browser/Rust lane during prototyping and
again in the complete eight-state offline matrix at
`/tmp/sqlsync-gates.00uLxG`. Pristine, tests-only base with full and stock
tools, expected tests-only focused rejection, solution-only lint/full suite/
worker package, combined focused, deliberate missing-browser-tool rejection,
and combined base all exited as expected. The combined browser log records
`applied: '0'` only after the native coordinator applies the uploaded mutation
and returns storage for rebase; it still records 13 subscription observations.
The lane contains no skip or synthetic facade fallback.

A separate fresh-container combined replay ran plain locked offline
`cargo build` followed by plain `cargo test`. It exits zero with all 23 core
tests, all four focused integrations, all workspace unit targets, and every
remaining doctest harness. The new coordinator example therefore does not
reintroduce the previously reported standalone-Cargo build failure in the
frozen environment.

All four supplied version-15 patches were replayed unchanged against the exact
version-16 test patch. Runs 2 and 3 pass, including public applied progress
after a real rebase and fresh reconnect/empty callbacks. Runs 1 and 4 fail at
the recurring first high-`u64` runtime serialization boundary. This preserves
two distinct legitimate event/acknowledgement architectures and rejects the
two declaration-only bigint shortcuts. These are diagnostic replays, not
version-16 calibration runs.

The static hash/application/leak audit passes. Per explicit operator direction,
no false-positive mutant or positive-variation suite was run for version 16;
historical version-14 results are not carried forward. Version 16 therefore
remains 0/10, audit-pending, non-immutable, and not submission-ready.

Current version-16 identifiers, pending the deferred false-positive audit:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `8e30e78ae50bb4ddf2cf130873494ad45d4fbed3c1880be13c620c44d5c1a464` |
| `test.patch` | `b72184e5f378b68e17cf794a5e5868308fadb6a7cb89813dc1ce73d40024001d` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `878c3c01d9fc54253b56f7ff310ced096d9dede6a098b48f7079b62a8dd2202e` |
| `verify/gates.sh` | `e71c1dd42a6b27d06d5e1fb8b082e6eb195237acc79bd98d4f8890dba166e91c` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `9f3bf10751519ad0701cc593346b6c752c228ee0979cf45367e25d97b4d4a2fe` |

## Version-17 representation-neutral high-LSN fixture gate

The 2026-08-03 fairness revision responds to a reviewer reading the decimal
strings used to assemble private replication frames as required public worker
values. Before changing `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current compact records, all four `agent-runs3`
patches/logs, and repository browser-number conventions were read or searched
again.

Runs 2 and 3 remain representative legitimate passes with decimal-string LSN
exports. Runs 1 and 4 remain near-passes: both declared public `bigint` but left
runtime serde serialization as `u64`, which fails before a high value reaches
the public API. There is no broad same-task failure in the batch. Importantly,
the pinned repository already exposes `bigint` as one public SQL value carrier
in `lib/sqlsync-worker/sqlsync-wasm/src/sql.rs`, while no existing browser LSN
convention selects decimal strings. A correctly implemented bigint LSN is
therefore plainly legitimate under the prompt.

The version-16 runtime assertions already compare implementation-produced
values to other implementation-produced values: receipt to state, first high
state to lower reconnect, second high state to empty-following, and adjacent
high states to each other. They do not compare a public LSN to a decimal
literal. Nevertheless, the private wire fixture names its high values as
decimal strings and converts them to words, which is visually ambiguous and
can be mistaken for a public representation requirement.

### Version-17 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Legitimate string implementations pass; repository SQL values already use bigint; the two bigint near-passes fail because their runtime conversion is incomplete, not because bigint is invalid. | Any documented lossless non-`number` public LSN representation is accepted. | Encode private replication fixtures directly as two unsigned 32-bit words; treat every returned public LSN as opaque and compare only implementation-produced values for equality or distinction. | Test-fixture representation versus public API representation | Removes decimal and BigInt literals from the high-value fixture. String, bigint, word-pair, facade-normalized, or another exact carrier remains valid. |
| The recurring declaration-only shortcut fails while serializing the first high `u64`. | Losslessness must hold at runtime, not only in declarations. | Retain two adjacent above-`2^53` wire values and require the two public observations to remain distinct. | Rust/Wasm runtime serialization | Tests aliasing and successful export without converting, parsing, stringifying, or inspecting the carrier. |

Version 17 will therefore delete the decimal parser and all high decimal
literals from the browser fixture. Constants such as `{ high: 0x00200000,
low: 0 }` exist only at the binary replication boundary and are never compared
to a public value. The public prompt and reference implementation remain
unchanged. No representation normalizer is added because it would merely
replace the string constraint with a closed list of accepted carriers.

This gate is complete before the version-17 test edit. At explicit operator
direction, false-positive mutant and variation runs are disabled by default for
this problem and will not run in this revision. Static artifact checks, format,
the exact patch-state matrix, plain Cargo, and representative trajectory
replays remain enabled. Under the workspace policy, version 17 consequently
stays false-positive-audit-pending and cannot be called submission-ready.

### Version-17 focused verification record

`test.patch` now encodes the three high private-wire fixtures only as frozen
`{ high, low }` word pairs. Its browser source contains no decimal high-LSN
literal, BigInt literal/API, parser, public-value decoder, or comparison between
a public value and a wire fixture. The high-value public assertions remain
carrier-opaque and test only equality or distinction among values returned by
the implementation. The public prompt, reference solution, and Dockerfile are
byte-identical to version 16.

Rustfmt/Biome and the static hash/application/leak audit pass. The exact eight-
state offline matrix passes at `/tmp/sqlsync-gates.XrbRqq`: pristine, both
baseline lanes, expected focused tests-only rejection, solution-only lint/full
suite/package, combined focused, deliberate missing-browser-tool rejection,
and combined base. The real browser/coordinator lane still observes distinct
adjacent high values, lower fresh-connection replacement, empty-following
history, and post-rebase applied state.

A fresh combined container also passes plain locked offline `cargo build` and
`cargo test`, including 23 core tests, four focused integrations, all workspace
unit targets, and the remaining doctest harnesses. Replaying all four supplied
version-15 solver patches preserves the intended split: decimal-string runs 2
and 3 pass; runs 1 and 4 fail while serde tries to serialize their raw Rust
`u64` as a JavaScript number despite declaring bigint. The fixture therefore
does not select strings; it selects successful lossless runtime export.

At operator direction, false-positive mutant and positive-variation commands
are disabled by default and were not executed. The default gate/static/Cargo/
trajectory workflow does not invoke them. Version 17 is consequently 0/10,
false-positive-audit-pending, non-immutable, and not submission-ready.

Current version-17 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `8e30e78ae50bb4ddf2cf130873494ad45d4fbed3c1880be13c620c44d5c1a464` |
| `test.patch` | `540689b5ede45370e06e47764c9f95465b54ada89ce5d256b18f1d9b960c8896` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `71207c307d3ac3c20d8f2d9223f7f89f9cd53374ca2799e613fabd5627d01f1c` |
| `verify/gates.sh` | `1342bf84bcef16ca4c53ff69f399bf353d8264f700048424bdb0d747db00f8e8` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `19c66ac1940f56a33a704017fe204a7cdb538a2f3510e3130ca8aca3dbcf647d` |

## Version-18 optional-property runtime gate

The 2026-08-03 fairness revision responds to a reviewer identifying that the
browser probe uses the JavaScript `in` operator on `SyncState.applied` before
and after application. Before editing `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current compact records, the four `agent-runs3`
solution patches, and the pinned worker serialization/type conventions were
read or searched again.

All four trajectories serialize a Rust `Option` into a state object whose
`applied` key happens to exist with `undefined` while unavailable. That shared
shape is an implementation consequence, not repository evidence for a public
presence contract. There is still no broad same-task failure in the batch.
The prompt says the three progress values are optional and requires the fields
to be readable; an ordinary TypeScript API may represent that as either
`applied?: Lsn` (missing key allowed) or `applied: Lsn | undefined` (present
key). Direct property access supports both.

### Version-18 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Reviewed implementations all emit a present `applied: undefined`, but the prompt only makes the watermark optional. | Before coordinator application is visible, applied progress is unavailable; omission and explicit `undefined` are equivalent public observations. | Access `beforeApplication.applied` normally and require only that it does not equal the receipt LSN. | Optional JavaScript property representation | Accepts optional-key and explicit-undefined declarations/serialization without changing the semantic stage boundary. |
| After storage return/rebase, the applied watermark must equal the receipt. | Available applied progress carries the exact public LSN. | Poll until `appliedState.applied` structurally equals `appliedReceipt.lsn`; absence already fails this equality. | Applied-value availability | The value assertion proves runtime presence when required, so a separate `in` assertion adds only layout coupling. |
| The TypeScript consumer already reads `exportedState.applied` as `Lsn | undefined`. | The public field remains readable and correctly typed. | Retain the compile-time consumer while removing runtime key-membership assertions. | Declaration surface versus serialized object shape | Does not weaken the named field/type contract or select interface versus alias, required versus optional key syntax. |

Version 18 will remove only the two `"applied" in state` assertions. The
pre-application inequality, post-rebase equality, generated type consumer,
coordinator round trip, and all other discriminators remain unchanged. The
public prompt, reference solution, and Dockerfile remain unchanged.

This gate is complete before the version-18 test edit. False-positive mutant
and variation checks remain operator-disabled by default and will not run.
Static/format checks, all patch states, plain Cargo, and trajectory replays
remain the enabled verification path. Version 18 remains audit-pending and
cannot be called submission-ready.

### Version-18 focused verification record

`test.patch` removes only the two browser `in`-operator assertions. The
pre-application `applied` inequality, post-rebase receipt equality, generated
TypeScript `Lsn | undefined` consumer, native coordinator round trip, and all
other public discriminators are unchanged. The static audit additionally
rejects reintroduction of the runtime key-presence contract. `meta.md`, the
reference solution, and the Dockerfile are byte-identical to version 17.

Rustfmt, Biome, and the static hash/application/leak audit pass. The exact
eight-state offline matrix passes at `/tmp/sqlsync-gates.gugOvm`: pristine,
both baseline lanes, intended focused tests-only rejection, solution-only
lint/full suite/package, combined focused, deliberate missing-browser-tool
rejection, and combined base. The real browser lane records 13 subscription
observations and exposes the receipt as applied only after coordinator work,
returned storage, and rebase.

A separate fresh combined container passes plain locked offline `cargo build`
and `cargo test`, including 23 core tests, four focused integrations, every
workspace unit target, and the remaining doctest harnesses. Replaying all four
supplied version-15 patches preserves the intended split: runs 2 and 3 pass;
runs 1 and 4 fail only when serde attempts to export an above-`2^53` raw Rust
`u64` as a JavaScript number. The optional-property correction therefore does
not weaken the applied-value or precision discriminators.

At explicit operator direction, false-positive mutant and positive-variation
commands were not run. Version 18 is consequently 0/10, false-positive-audit-
pending, non-immutable, and not submission-ready.

Current version-18 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `8e30e78ae50bb4ddf2cf130873494ad45d4fbed3c1880be13c620c44d5c1a464` |
| `test.patch` | `59d7c99e0adccf406e798b771565b2bbe7c12df5788e6ea3bd58b913a23bf874` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `8354ba227a7a50afb24d6851feade23a0df44173489c532012c11c2a72e09d87` |
| `verify/gates.sh` | `0e57a3b608d63e4a9249ae513c863a5b100a51723af0d4fa5bf49abb4bdd235f` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `94f414987617df6f3f38e862798c77c8f3935adb9c18e52a62e9fa994baf1eba` |

## Version-19 Rust trait and argument-ownership gate

The 2026-08-03 fairness revision responds to a reviewer identifying three
compile-time contracts in the Rust integration: whole-receipt `assert_eq!`
requires `MutationReceipt: Debug + PartialEq`; status-result `assert_eq!`
requires `MutationStatus: Debug + PartialEq`; and direct calls with an owned
receipt reject an otherwise ordinary `status(&MutationReceipt)` API.

Before editing participant artifacts, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current compact records, the version-8 ownership
history, all four `agent-runs3` patches/logs, the reference patch, and the pinned
crate's argument/derive conventions were read or searched. Runs 2 and 3 remain
legitimate passes; runs 1 and 4 remain near-passes only at browser high-`u64`
serialization; no broad same-task failure exists. All four happened to derive
the comparison/debug traits, but that convergence follows their own unit-test
style rather than the public contract. Runs 2 through 4 accept a receipt by
value, while run 1 uses `impl Borrow<MutationReceipt>` and therefore already
demonstrates a more flexible public seam. A shared-reference-only classifier is
equally compatible with immutable snapshot classification and with repository
Rust conventions.

### Version-19 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Whole-value assertions currently compare receipts even though their two public fields are the actual contract. | Successful mutations expose the exact public timeline and LSN. | Compare `timeline_id` and `lsn` separately with boolean assertions. | Rust convenience traits versus public data | Preserves exact receipt identity without requiring `MutationReceipt: Debug`, `PartialEq`, `Eq`, `Clone`, or `Copy`. |
| Every recent solver derived status comparison/debug traits because both solver and hidden tests used `assert_eq!`. | `status` returns the correct public variant or `None`. | Use variant pattern matching and `Option::is_none` rather than equality formatting. | Enum result semantics versus convenience traits | Exercises every precedence/bounds variant without requiring `MutationStatus: Debug`, `PartialEq`, or `Eq`. |
| Three solvers and the reference take ownership; run 1 accepts any `Borrow`; immutable classification has no repository-backed ownership requirement. | A caller can classify a receipt without one prescribed ownership policy. | Run a standalone public-consumer probe: compile the owned call form first, otherwise compile the shared-reference form, then execute the one supported form against all classification boundaries. | Rust argument ownership | Accepts exact owned, exact borrowed, and generic `Borrow` APIs without source inspection or private implementation coupling. |
| The stage-order integration currently repeats `status` calls after each replication transition. | Dynamic snapshot fields and static classifier semantics must both be correct. | Keep dynamic local/received/applied field assertions in the core integration; centralize status behavior in the signature-adaptive public-consumer probe. | Replication state production versus snapshot classification | Avoids weakening either behavior while ensuring only one selected ownership form is compiled and run. |

Version 19 will reword the public status directive to expressly accept either
an owned receipt or a shared reference. The core integration will remove
whole-receipt and status-result equality assertions, retain exact field and
watermark checks, and move classification behavior to a nested standalone
consumer package selected by compile preflight. Cargo's ordinary workspace
suite will ignore that nested package; `test.sh new` will execute it with
networking disabled before the focused integration. No production/reference
behavior or browser test changes are planned.

This gate is complete before the version-19 prompt and test edits. At explicit
operator direction, false-positive mutant and positive-variation commands will
not run. Static/format checks, the eight patch states, plain Cargo, and supplied
trajectory replays remain enabled. Version 19 starts at 0/10 and cannot be
called immutable or submission-ready.

### Version-19 focused verification record

The public prompt now states that `SyncState::status` may accept an owned
receipt or shared reference. The core integration compares receipt fields
without whole-value equality and checks replication-produced progress through
direct snapshot fields. Classification moved to
`test-support/observed-sync-state-status`, a nested package ignored by ordinary
workspace Cargo. `test.sh new` seeds its offline lock resolution from the
committed workspace lock, compile-checks the owned call form and otherwise the
borrowed form, then runs only the supported form. Variant patterns and
`Option::is_none` cover applied/received/local precedence, foreign timelines,
future receipts, and applied precedence over a lagging acknowledgement without
requiring status equality or debug formatting.

The explicit positive compatibility check removes `Debug`, `PartialEq`, and
`Eq` from both new public types and changes the reference classifier to
`status(&MutationReceipt)`. The owned preflight fails as intended, the borrowed
preflight and executable pass, and the three dynamic Rust integrations pass.
This demonstrates actual acceptance of the reported alternative rather than
relying on source inspection. No reference production or browser behavior was
changed.

Rustfmt, Biome, and the static hash/application/leak audit pass. The exact
eight-state offline matrix passes at `/tmp/sqlsync-gates.IxsPgK`: pristine,
both baseline lanes, intended focused tests-only rejection, solution-only
lint/full suite/package, combined focused, deliberate missing-browser-tool
rejection, and combined base. The combined lane runs the real browser probe,
the selected status consumer, and three focused Rust integrations.

A separate fresh combined container passes plain locked offline `cargo build`
and `cargo test`, including 23 core tests, three focused integrations, every
workspace unit target, and the remaining doctest harnesses. All four supplied
version-15 patches execute the status consumer and preserve the intended split:
runs 2 and 3 pass; runs 1 and 4 fail only when serde exports an above-`2^53`
raw Rust `u64` as a JavaScript number.

At explicit operator direction, false-positive mutant commands and the broad
variation suite were not run. The one focused positive compatibility check is
fairness evidence for this reported API alternative, not a false-positive
audit. Version 19 is consequently 0/10, false-positive-audit-pending, non-
immutable, and not submission-ready.

Current version-19 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `76a4df31967b685ed47a9711b58e257d57cde7b52d3f3469c30ac67495f0ebdd` |
| `test.patch` | `261db2ce82f2d715de3ff57dc23989ac54eb0bfa1c8cb4d72ca54beff34d0156` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `0bc096aa7cde663e3d9fe475ab8ae101e20fabfa29e04b135ff8a8f651a2c993` |
| `verify/gates.sh` | `a622c42093d9634c9714c1393709db5cfd17ca0fc4f54fcb6fe7dad945b00d69` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `c190eeb4cef680ef4bd8abaffa79ea3e7c6099ad7e02526c1a14d43806404ab2` |

## Version-20 applied-subscription delivery gate

The 2026-08-03 revision addresses the reported browser coverage gap: the
coordinator-backed flow proves the applied watermark only by polling
`syncState`, so an implementation can compute the applied value correctly on
demand while never publishing that transition to an active
`SyncStateSubscription`.

Before revising the test artifact, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current compact records, the existing browser
probe, all four `agent-runs3` patches, and the reference patch were read or
searched. The public prompt already requires a subscription to receive later
locally observed changes without polling. A coordinator application becoming
visible after storage return and rebase is such a change. The reference and
all four representative solver patches already notify their sync-state
subscribers after rebase/storage change, so the added oracle preserves the
known two-pass/two-high-`u64`-failure trajectory split rather than selecting a
private implementation.

### Version-20 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The applied flow polls after coordinator application, while the prompt promises later observed changes through `SyncStateSubscription` without polling. | An active subscription publishes the transition when its document's applied watermark advances after application becomes visible. | Subscribe on the coordinator-backed document, record the observation boundary immediately before returning application messages to the worker, and require a later observation whose `applied` value structurally equals the mutation receipt LSN. | Pollable state versus pushed state-change delivery | Uses only the public facade, subscription callback, and opaque public LSN equality; it does not inspect event internals, demand a callback count, or prescribe a representation. |
| Earlier acknowledgement observations can remain in the subscription history and asynchronous callbacks can cross phase boundaries. | Evidence for application delivery must come from the application phase itself. | Search only observations appended after the pre-delivery boundary and retain the existing direct polling/timeline assertions as independent state checks. | Fresh transition evidence versus stale-history acceptance | Rejects stale-history false positives without imposing synchronous delivery or a particular callback scheduling mechanism. |

No public prompt, reference solution, or container change is needed. The test
will keep direct applied-state polling and add a fresh subscription observation
after coordinator application, then unsubscribe before teardown. At explicit
operator direction, false-positive mutant commands and the broad variation
suite will not run. Static/format checks, the eight patch-state gates, plain
Cargo checks, and supplied trajectory replays remain enabled. Version 20 starts
at 0/10 and remains false-positive-audit-pending, non-immutable, and not
submission-ready.

### Version-20 additional review intake

Two further reported omissions were checked against the public contract,
repository behavior, and the same four raw solver patches before further test
editing. The task reducer already gives the browser a real malformed-input
failure path, and the worker's ordinary error reply rejects the facade promise.
Every representative solver calls the fallible core mutation before producing
its receipt; implementations that explicitly notify do so only after that call
succeeds. Their status implementations also reject a same-timeline receipt
when `local` is absent, although only one expresses that bound with `?`.

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Core tests reject malformed mutation bytes, but the real facade path currently sends only reducer-valid bytes. | Only a successful local mutation returns a receipt or advances browser-visible local progress. | Make the existing browser serializer emit malformed bytes for one marked mutation; require the facade promise to reject and require the next `syncState.local` to equal the pre-failure value. | Core transaction rollback versus worker/facade error propagation | Uses the existing public `mutate` promise and reducer behavior; it does not prescribe an error class, text, or internal reply tag. |
| A failed request could publish a false progress event even if later polling remains correct; an immediate zero-callback assertion would overconstrain harmless scheduling or redundant unchanged snapshots. | A rejected mutation does not publish advanced local progress to a sync-state subscriber. | Record a callback boundary before failure, wait through the later known acknowledgement callback as an ordering barrier, and reject any intervening observation whose `local` differs from the accepted receipt's unchanged watermark. | Polled rollback versus pushed rollback | Allows no callback or redundant unchanged callbacks and asserts only absence of false progress, not private event counts or timing. |
| The classifier covers foreign timelines and receipts above a present local bound, but not the absence of that bound. | A snapshot with no known local mutation cannot classify even a same-timeline receipt as present. | Construct the public `SyncState` literal with `local: None` and require the signature-adaptive status call to return `None`. | Missing bound versus exceeded bound | Reuses the ownership-neutral public consumer and adds one semantic absence boundary without requiring traits or a constructor. |

These checks require no prompt, reference, or Docker change. They are folded
into version 20 before its verification run; the operator-disabled false-
positive audit remains pending.

### Version-20 focused verification record

The final browser probe subscribes to the coordinator-backed document before
mutation, records `observationsBeforeAppliedReturn` only after coordinator work
and immediately before its messages reach the worker, and accepts only a later
callback whose opaque public `applied` value equals the receipt LSN. Direct
`syncState` polling and receipt/state timeline agreement remain independent
oracles. The reference combined log records seven observations for that
subscription and unsubscribes it before teardown.

The main real-worker flow serializes one marked mutation as malformed task-
reducer input. `SQLSync.mutate` rejects without an error-shape requirement;
the subsequent public snapshot retains the prior local watermark. The test
then waits for the known acknowledgement callback and rejects any observation
appended since the failure boundary whose local value differs from that prior
watermark. This permits no event or redundant unchanged events while rejecting
false progress. The signature-adaptive Rust consumer additionally returns
`None` for a same-timeline receipt against `local: None` with populated
received/applied fields.

Rustfmt, Biome, and the static hash/application/leak audit pass. The exact
eight-state offline matrix passes at `/tmp/sqlsync-gates.lXCfUi`: pristine,
both baseline lanes, intended focused tests-only rejection, solution-only
lint/full suite/package, combined focused, deliberate missing-browser-tool
rejection, and combined base. The combined lane executes the real generated
worker and all three new assertions without a fallback or skip.

A fresh combined container passes plain locked offline `cargo build` and
`cargo test`, including 23 core tests, three focused integrations, every
workspace unit target, and the remaining doctest harnesses. All four supplied
version-15 solver patches accept reducer rejection, the absent-local
classifier, and applied subscription delivery. Runs 2 and 3 pass completely;
runs 1 and 4 fail only at their existing above-`2^53` raw-`u64` Wasm
serialization error. The expected trajectory split is therefore unchanged.

At explicit operator direction, false-positive mutant commands and the broad
variation suite were not run. Version 20 is consequently 0/10, false-positive-
audit-pending, non-immutable, and not submission-ready.

Current version-20 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `76a4df31967b685ed47a9711b58e257d57cde7b52d3f3469c30ac67495f0ebdd` |
| `test.patch` | `5adb21e82f431ab5192fc25e79b83f7d27593b0ebdb28603adcc4001b7c87a54` |
| `solution.patch` | `b16efe495608a112908474088a96e8f62464cd1f367f59851a8db6cc795190ae` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `35e6b33769247a2030592dd0baf8459d38fc35a7c904aae6ca62d79b49a23b65` |
| `verify/gates.sh` | `6edd9c02c3352532e0e37b39194ec20f8308cb6568a54355693c031582666fe8` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `a74b189c80c4f1132ac86d1a2e1f1101e686599f7e95be8adf5e5a796abe7a3a` |

## Version-21 trajectory-informed hardening gate

The 2026-08-03 hardening revision follows a complete 10-run working-pool
batch against version 20. The operator supplied
`problems/rmk-portable-configuration-snapshot/agent-runs4`, but the matching
same-task evidence is the independently present
`problems/sqlsync-observed-sync-state/agent-runs4`; the unrelated RMK
trajectories were not used as SQLSync design evidence.

Before editing participant artifacts, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the version-20 prompt/tests/reference, every
SQLSync `agent-runs4` evaluation and solution patch, and representative raw
trajectories from runs 1, 3, and 9 were read or searched. All ten evaluations
are `PASS_LEGITIMATE`, with both baseline and new suites passing. The raw
records show independent implementations across the Rust core, replication
state, coordinator task, Wasm boundary, TypeScript facade, and framework
hooks. They use both decimal-string and bigint browser LSNs, several signal
topologies, and both explicit `Option<Option<Lsn>>` observations and flatter
`Option<Lsn>` tracking. There is no near-pass or broad failing SQLSync run in
this batch to substitute for the 10 legitimate passes. Version 20's 10/10
legitimate pass rate exceeds the target lane and is abandoned; version 21
restarts calibration at 0/10.

### Version-21 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The version-20 browser probe checked only that the first callback occurred. Several solvers synthesize an initial callback through a separate path from later updates. | When `subscribeSyncState` resolves, its callback has already received the document's current snapshot. | Before mutation, compare the callback's timeline and all three optional watermarks with an immediate public `syncState` result using opaque structural equality. Repeat with a late subscriber after acknowledgement, where the snapshot is nonempty. | Callback occurrence versus callback content; empty versus populated initial snapshots | Exercises only public values and ordering expressly promised by the API. It does not require reference identity, an internal reply tag, or one callback count. |
| The classifier test used an LSN strictly below `received`; all solvers implement similar-looking precedence chains whose inclusivity can diverge at equality. | `received` is an inclusive watermark when `applied` does not mask it. | Classify a same-timeline receipt whose LSN exactly equals `received` and is above `applied`; require the `Received` variant through the ownership-adaptive public consumer. | Interior classification versus exact inclusive boundary | Adds a semantic boundary rather than another fixture, and retains support for owned, borrowed, or generic receipt arguments. |
| The prompt says a fresh connection's first observed peer range replaces retained knowledge. Some trajectory implementations preserve only an `Option<Lsn>`, while others distinguish no observation from an observed empty range. | A fresh connection that observes an empty peer range at LSN zero replaces a retained nonempty acknowledgement with no `received` watermark. | Retain a high acknowledgement, reconnect to a peer whose first range is empty at zero, then require both public polling and a post-boundary subscription observation to expose `received: undefined`. | No range observed yet versus an observed empty range; monotonic retention versus connection-scoped replacement | Uses the existing replication range protocol and public state only. It does not name a protocol accessor or persistence layout. |
| Each run implements subscriber bookkeeping differently; the existing test has only one active subscriber per document. | Subscriptions are independent: adding a second subscriber yields its current snapshot, and cancelling one does not suppress later updates to the other. | Add a late subscriber after acknowledgement, cancel the original, advance the peer watermark, require only the remaining subscriber to observe the new state, then cancel it. | Single-listener delivery versus fan-out and unsubscribe isolation | Tests the public subscription lifetime contract without inspecting handles, request tags, or internal reference counts. |
| Base coordinator code emitted the connection signal only when the status changed. The reference reused that signal for acknowledgement progress, so an acknowledgement can now publish another unchanged `connected` value. Most solver trajectories already separate progress from connection-status signaling. | A sync-progress-only acknowledgement does not create a new connection-status notification when the connection status is unchanged. | Establish `connected`, record the status-listener boundary, advance only `received`, use the sync-state callback as the processing barrier, and require no additional connection-status callback. | Progress notification versus existing connection-status notification | Preserves observable pre-task behavior and accepts any internal signal architecture; the assertion is phase-bounded and does not impose global event scheduling. |
| Historical observations allowed several reconnect checks to succeed from stale entries; version 20 fixed some, but not every new phase. | Every reconnect and fan-out assertion must be supported by an observation appended after that phase begins. | Record an array boundary immediately before each fresh connection, empty-range response, unsubscribe, and application return; search only the appended slice. | Current transition evidence versus stale-history acceptance | Tightens the oracle without demanding exact callback counts or synchronous delivery beyond the documented initial snapshot. |

The public prompt already states the initial-snapshot, inclusive-watermark,
fresh-connection replacement, per-document subscription, and unchanged
connection-control contracts, so no private bridge schema or representation
directive will be added. The browser probe will preserve representation-neutral
LSN comparisons and its real generated Wasm/worker path. The reference will
separate coordinator progress signaling from connection-status signaling; the
Rust classifier consumer will add the exact received boundary.

This design gate is complete before version-21 prompt, test, or reference
edits. At explicit operator direction, false-positive mutants and the broad
positive-variation audit will not run. Static/format checks, all patch states,
plain Cargo, the real browser lane, and replay of the ten supplied version-20
solver patches remain enabled. Version 21 is false-positive-audit-pending,
non-immutable, and cannot be called submission-ready.

### Version-21 verification and calibration result

The reference passes the static artifact audit, all eight offline patch-state
gates at `/tmp/sqlsync-gates.xmsYLk`, and a separate combined plain locked
offline `cargo build` plus `cargo test`. The real browser lane records nine
main-document subscription observations and six applied-document observations;
both empty and populated initial snapshots match public polling, the fresh
empty-at-zero range removes retained acknowledgement knowledge, the remaining
subscriber survives cancellation of the first, and acknowledgement progress
does not repeat the stable connection status. The ownership-adaptive Rust
consumer accepts the exact inclusive `Received` boundary.

All ten legitimate version-20 solver patches were then replayed independently
against version 21 in offline containers. Runs 1 through 10 all pass; their
logs are `/tmp/sqlsync-v21-replay-{1..10}.log`. This is a 10/10 historical
pass result, not a new immutable solver batch, but it proves that the added
oracles do not discriminate this working pool. Version 21 is therefore
coverage-improved but abandoned as the final difficulty candidate. Its
false-positive audit remains operator-disabled and pending.

## Version-22 browser mutation-classification gate

Version 22 adds one substantive public seam instead of adding more fixtures to
the watermark families already solved by every trajectory. Before editing the
prompt or tests, the ten version-20 solution patches were searched again at
their Rust classifier, Wasm API, worker facade, and generated-type boundaries.
Every implementation exports or computes the Rust `MutationStatus`, and every
implementation exports browser receipts and sync snapshots, but none exposes
timeline-bound receipt classification through `SQLSync`. The repository's
generated request/reply bridge already carries structured public values and
fallible document operations, so a facade classifier is a natural end-to-end
extension rather than a private implementation prescription.

### Version-22 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| All ten solvers implement the Rust classifier, but browser callers receive only data values and cannot reuse that classifier without reimplementing timeline and opaque-LSN ordering. | Export worker `MutationStatus` and add `SQLSync.mutationStatus(docId, docType, receipt)`, resolving to the furthest observed stage or `undefined` under the same timeline/local bounds as Rust. | Type-check the public method and generated export; call it on a real receipt at local, received, and applied stages in the real generated-worker flow. | Rust-only classification versus public browser classification | The prompt names the public method and result. Tests do not inspect request tags, reply wrappers, or whether classification occurs in Rust or the facade. |
| A facade could classify solely by comparing watermarks and omit the Rust classifier's timeline/local validity bounds. | Browser classification is timeline-bound and bounded by current local knowledge. | Reuse an actual high, lossless public `received` value as a same-timeline future receipt and require `undefined`; replace only the public timeline identifier and require `undefined` for a foreign receipt. | Stage precedence versus validity bounds | Constructs receipts from already returned opaque public values, so it does not decode LSNs or require bigint, string, reference identity, or a private constructor. |
| Polling and subscription barriers already prove when each stage becomes locally observable. | Browser status must change only after the corresponding public observation, with Applied > Received > Local precedence. | Assert `Local` before acknowledgement, `Received` after the post-boundary acknowledgement callback, and `Applied` after coordinator storage return, rebase, and the applied callback. | Static facade shape versus live stage transitions | Reuses deterministic public barriers and adds one classification call per semantic stage, not timing sleeps or event-count assumptions. |
| Exact internal worker reply tags were previously identified as unfair. | Only the facade signature, exported result values, and behavior are contractual. | Drive every assertion through `SQLSync.mutationStatus`; static checks reject hidden source probes for an author-selected bridge tag. | Public API versus bridge schema | Solvers may add a request, classify a public snapshot in the facade, or use another source-compatible route compatible with their documented LSN carrier. |

Version 22 will explicitly name the new facade method and worker export in the
public description. It will retain any documented lossless non-number LSN
representation and the signature-adaptive Rust classifier. The reference will
carry a receipt through the generated bridge and use the core classifier, but
the tests will not require that architecture.

This gate is complete before version-22 participant-artifact edits. Version 22
restarts at 0/10. At explicit operator direction, false-positive mutants and
positive variations will not run; the version remains audit-pending,
non-immutable, and not submission-ready.

### Version-22 focused verification record

The public description now names `SQLSync.mutationStatus`, the exported worker
`MutationStatus`, and its exact `"local"`, `"received"`, `"applied"`, or
`undefined` results. The generated TypeScript consumer requires the method and
return type. The real browser probe obtains all receipt LSNs from public
runtime values: it observes Local before acknowledgement, Received after the
fresh acknowledgement callback, and Applied only after coordinator storage
returns and rebase is visible. A copied receipt with a changed public timeline
identifier and a same-timeline receipt using the public high acknowledgement
LSN both return `undefined`. The test never names an internal request or reply
tag and never decodes the documented lossless LSN carrier.

The reference carries the receipt through one generated Wasm request and uses
the existing core classifier. This is reference architecture only; the oracle
permits facade-side or other source-compatible implementations. Its separate
coordinator-progress signal preserves the existing connection-status event
stream while continuing to drive sync-state subscriptions.

Rustfmt, Biome, clean patch application, and the static hash/leak audit pass.
All eight exact offline patch states pass at `/tmp/sqlsync-gates.zzyC3Y`:
pristine; both baseline lanes; intended tests-only rejection; solution-only
lint, suite, and packaging; combined real-browser focused tests; deliberate
missing-browser-tool rejection; and combined base. A separate combined
container passes plain locked offline `cargo build` and `cargo test`, including
23 core tests, three focused integrations, all workspace targets, and the
remaining doctest harnesses.

Representative historical solutions 1, 3, and 9 fail v22 specifically because
they do not export worker `MutationStatus` or implement
`SQLSync.mutationStatus`; their logs are `/tmp/sqlsync-v22-replay-{1,3,9}.log`.
They continue to represent legitimate version-20 solutions and are not counted
as version-22 calibration runs. Fresh version-22 calibration is exactly 0/10.

At explicit operator direction, false-positive mutant commands and positive
variations were not run. Version 22 is therefore false-positive-audit-pending,
non-immutable, and not submission-ready.

Current version-22 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `d828bd899062ff23052b6c8ebecda30a9857a0185e12c9129b61858ad71e5ade` |
| `test.patch` | `249b9a1ce273269cbd5812284d1812460ac21586d41bac52dfd1cbcdecaecae3` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `2cc0421bdbc54eda799988d162cb61c497c30f7fd1a2baab3f42acb685830a1e` |
| `verify/gates.sh` | `14d863ca53490541c5f44c489ff08f02359a9e6688093c7973ab037233fb59f8` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `f008df28b4c55faee81216e5007365ca71b123fe6b3c438ab873d77270ecd0d4` |

## Version-23 trajectory-informed public-boundary gate

The 2026-08-05 revision follows the supplied ten-run batch in
`agent-runs6`. Despite two references to an RMK path in the operator message,
the prompt, test names, API vocabulary, and locally matching batch all belong
to SQLSync. Runs 1, 2, 3, 4, 6, 7, 8, and 10 are legitimate passes; runs 5 and
9 are near-passes whose generated declarations claim `bigint` while raw Rust
`u64` values still cross `serde-wasm-bindgen` as JavaScript numbers. The batch
therefore closes at 8/10 and is abandoned. Version 23 starts at exactly 0/10.

Before any version-23 test edit, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the repository catalogs, the current compact
records and artifacts, every `agent-runs6` evaluation and solution patch, and
the raw ATIF trajectories for representative pass run 1 and near-pass runs 5
and 9 were read or searched. There is no broad failing implementation in this
batch; both failures are otherwise comprehensive implementations stopped by
the same runtime precision boundary.

Run 1 is representative of the legitimate architecture: it adds a Rust
progress module, derives local/applied state at the document boundary, records
connection-scoped acknowledgement observations, serializes browser LSNs as
decimal strings, classifies browser receipts in the TypeScript facade, and
fans state changes through a separate worker signal. It changes 12 production
files with 516 raw additions and 29 deletions. Its trajectory inspects the
Rust timeline/replication seams before editing, validates core tests during
implementation, and finishes with workspace Cargo, clippy/rustfmt, worker,
React, and Solid builds. Runs 5 and 9 follow the same cross-layer shape but
mistake a TypeScript `bigint` annotation for a runtime serializer conversion;
their 13-file and 12-file patches reach the browser probe and fail when a high
wire acknowledgement is converted. Strict effective production LOC and the
platform agent-message metric are not present in these bundles; raw diff size
and the six-step ATIF envelope are recorded only as supporting evidence and
are not substituted for those metrics.

The eight passes use several legitimate internal choices: Rust-bridge or
facade-side classification, optional or explicit-`undefined` state fields,
generated or handwritten public worker values, and multiple acknowledgement
signal/cache topologies. All observed passing classifiers already compare
watermarks inclusively, and all use concrete receipt/state/status declarations
with lossless string carriers. Consequently the checks below close real public
contract holes but are not expected to retroactively turn those legitimate
solutions into failures. The high solve rate reflects a detailed contract and
strong solver execution, not a discovered family of false positives.

### Version-23 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The TypeScript consumer compares method results against the same imported aliases and reads one property; replacing `MutationReceipt`, `SyncState`, or `MutationStatus` with `any` can satisfy those checks. Runtime probes cannot restore declaration-site type safety. | The worker package exports usable structured receipt/state types and the exact documented status union. | Reject `any` at the alias and progress-field levels; require the receipt LSN and all three state watermark fields to use exported `Lsn`; require one accepted generated timeline key and the exact three status literals. | Runtime values versus public TypeScript declarations | Structural checks accept interfaces or aliases, readonly fields, optional or explicit-`undefined` state properties, and either established timeline-key spelling. They do not select a generator or bridge schema. |
| The Rust classifier exercises receipts below a watermark, while the version-22 browser flow classifies only the receipt equal to each live watermark. The browser classifier is an independently implemented public seam in most passing trajectories. | Browser classification uses inclusive watermarks, not exact receipt/watermark equality. | Create two real mutations on one coordinator-backed timeline; after the newer receipt becomes received/applied, require the older receipt to classify at the same furthest stage. | Rust semantics versus browser parity; equality versus inclusive ordering | Uses only real public receipts and observation barriers. It does not decode LSNs or prescribe whether classification runs in Rust or TypeScript. |
| The two near-passes prove that declaration-only precision is insufficient. Existing wire fixtures distinguish adjacent values above `2^53` but stop below the signed-64 boundary, leaving truncating or signed-limited adapters unexercised. | Every Rust `u64` has a lossless browser representation and can be returned through the public classifier input. | Observe two adjacent acknowledgement watermarks in the upper half of `u64`, require non-number and structural distinction, and round-trip each opaque value through `mutationStatus` as an above-local receipt. | JavaScript safe-integer precision versus the complete Rust domain; output-only versus bidirectional bridge | The oracle never calls `BigInt`, parses text, inspects a word-pair layout, or compares with a fixture object. A documented signed-bit carrier may pass if it remains lossless and its public semantics are correct. |
| Judge-c found that a callback can splice the live subscriber array and skip a peer during one fan-out. The reference uses the same live-array iteration, and repository query subscriptions do not establish stronger re-entrant dispatch semantics. | No additional public invariant is established by the current prompt or repository. | No hidden probe is added. | Re-entrant callback mutation | Rejected as a one-off robustness property shared by the designated reference and unsupported by the participant contract; adding it silently would convert a legitimate pass into a false positive. |
| The phrase “makes no claim about newer server state” repeats the immediately preceding observed-client snapshot rule. | The description remains concise without changing behavior. | Remove only the redundant clause. | Editorial quality | No test or implementation behavior depends on the deletion. |

The proposed `BigInt(publicLsn)` equality oracle is explicitly rejected. The
prompt permits any documented lossless non-`number` carrier, and JavaScript has
no universal decoder for an arbitrary structured representation. Upper-half
coverage will instead test injectivity across adjacent values and the facade's
ability to consume its own opaque representation. This retains string,
`bigint`, word-pair, and other exact carriers.

This design gate is recorded before editing `test.patch`. At explicit operator
direction, false-positive mutants and positive variations will not run.
Static/format checks, all patch states, plain Cargo, the real browser lane, and
representative solver replays remain enabled. Version 23 remains false-positive-
audit-pending, non-immutable, and not submission-ready.

### Version-23 verification record

The public prompt changed only editorially by removing the redundant newer-
server-state clause. The focused TypeScript consumer now rejects `any` aliases
and fields, accepts either established timeline-key spelling, and checks the
exact public status union. The browser probe uses two real mutations for
inclusive older-receipt classification, then observes adjacent opaque
acknowledgements at `0x8000000000000000` and `0x8000000000000001`. It requires
the returned public values to be non-number, distinct, and reusable as
same-timeline future receipts that classify as `undefined`; it never decodes
or compares them to a carrier-specific expected value.

Formatting, `git apply --check`, and the static source constraints pass. The
exact eight-state network-disabled matrix passes at
`/tmp/sqlsync-gates.cSs2GN`, including pristine/base compatibility, focused
tests-only rejection, solution-only lint/full-suite/package, the real combined
browser lane, missing-browser-tool rejection, and combined base compatibility.
A separate combined plain locked offline `cargo build` and `cargo test` passes
23 core tests, three focused integrations, all workspace targets, and the
remaining doctests.

Replaying legitimate version-22 run 1 against the strengthened lane exits 0
and exercises the new browser and Rust checks. Replaying near-pass run 5 still
fails at its known pre-existing boundary when `serde-wasm-bindgen` attempts to
emit `9007199254740992` as a JavaScript number; the new upper-half phase is not
needed to manufacture that failure. These are representative construction
replays, not version-23 calibration runs.

At operator direction, no false-positive mutant or positive-variation command
was run. The ordinary verification is complete, but workspace policy therefore
keeps version 23 audit-pending, non-immutable, and not submission-ready. Any
participant artifact edit must restart verification and calibration at 0/10.

Current version-23 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:7612ffc4dc07006d47cf92609c7500d422d14f15dced7fb23c61933bfd9b5ce8` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `7de84be190e7f14d17da2ca8d60bda46bcbcb8ebe2443b9f60bab2c69a2e7082` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `d3ee076246793b04e03e0a4f3ad1ff7949f95d4c2c4e9c4e821bfcd5b4256ecf` |
| `verify/audit.sh` | `986de672d9fad0a5e96d246cbf82ebf2c8f86223c1a4967fe6a54d77613a7e13` |
| `verify/gates.sh` | `14d863ca53490541c5f44c489ff08f02359a9e6688093c7973ab037233fb59f8` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `500daad12ab19ab996a71cc28a1d5ad234abe8943e4c45ecf0db7cd50facedee` |

## Version-24 Docker portability gate

An automated Docker review claimed that `rustup toolchain install` does not
accept `--target`. The installed rustup help disproves that claim: its install
subcommand explicitly lists `-t, --target <TARGET>`. Nevertheless, using a
separate `rustup target add ... --toolchain ...` command is semantically
equivalent and avoids a reviewer-specific false rejection, so version 24 will
adopt that spelling without changing participant behavior.

The same review flagged unpinned apt packages. Inspection of the mandated
Olympus Rust base shows that `ca-certificates`, `curl`, `nodejs`, and
`pkg-config` are already installed; only `clang` is absent. The image will stop
reinstalling the four inherited packages and pin the direct `clang` metapackage
to the version currently published for the base's Debian bookworm repository.
This is narrower and more reproducible than retaining five unpinned direct
installs. Transitive Debian dependencies remain repository-resolved in the
ordinary way.

This is an environment-only revision: `meta.md`, `test.patch`, and
`solution.patch` remain unchanged. The Docker image must rebuild successfully,
the explicit tool/target assertions must pass, and the ordinary eight-state
offline matrix plus static audit must be rerun against the new image. At
operator direction the false-positive mutant and variation suites remain
unrun, so version 24 starts at 0/10 and remains audit-pending, non-immutable,
and not submission-ready.

### Version-24 verification record

The corrected Dockerfile builds successfully from the mandatory Olympus Rust
base. Its pinned `clang=1:14.0-55.7~deb12u1` installation succeeds; rustup
installs 1.91.1 with clippy/rustfmt, then the separate toolchain-qualified
target command installs `wasm32-unknown-unknown`. All pinned Cargo/npm tools,
the locked workspace build, frozen pnpm install, Wasm examples, generated
worker package, final host `libsqlsync.rlib`, and explicit tool/target checks
complete during image construction.

An initial rebuild used a linked local worktree as Docker context. The image
itself built and its pristine gate passed, but patch states could not resolve
the worktree's host-only `.git` pointer. That was a construction-context error,
not a Dockerfile defect. The final image was rebuilt from a standalone clone at
the pinned commit with a self-contained `.git` directory. Its exact eight-state
offline matrix passes at `/tmp/sqlsync-gates.2MhIfk`: pristine, tests-only base,
tests-only base with stock tools, focused tests-only rejection, solution-only,
combined focused, missing-browser-tool rejection, and combined base all exit
with their expected status.

The static artifact audit passes against the same standalone clone. A separate
combined network-disabled `cargo build --locked --offline` followed by
`cargo test --locked --offline` passes 23 core tests, three focused integration
tests, all workspace unit targets, and every enabled doctest. No false-positive
mutant or variation command was run at operator direction, so version 24 remains
audit-pending, non-immutable, 0/10, and not submission-ready.

Current version-24 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `7de84be190e7f14d17da2ca8d60bda46bcbcb8ebe2443b9f60bab2c69a2e7082` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `be001f6aa7cccc168a62e1cbe195eb976885075f8044d71093d074c777f0b8cc` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `927e9fcc2c5fa2e1257ad5f27cbb5242dcbcce89beba9443f70a45a2186ab3ab` |

## Version-25 optional-absence fairness gate

The 2026-08-05 fairness report correctly identifies that version 24's browser
tests selected JavaScript `undefined` as the sole absent-watermark sentinel,
while the public prompt says only that `local`, `received`, and `applied` are
optional. Before revising `test.patch`, `PROBLEM_DESIGN.md`, the current compact
records, the version-23 declaration ledger, the supplied `agent-runs6` worker
declarations, and the pinned worker source were read or searched again.

Every reviewed solver uses Rust `Option` and the generated/default bridge emits
missing or `undefined` progress, so the existing legitimate pass is
representative. No supplied implementation uses `null`, and there is no broad
failure in the ten-run batch. That absence is not evidence against `null`:
the pinned worker already exports a public SQL-value union containing both
`undefined` and `null`, while no pre-task sync-watermark declaration establishes
one sentinel. A hand-written or normalized bridge using `Lsn | null` is a
plausible, source-compatible implementation of the stated optional value.

### Version-25 discriminator ledger

| Review/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The v23 anti-`any` consumer requires each progress field to equal `Lsn | undefined`; an otherwise concrete `Lsn | null` state fails only at declaration representation. | Each state field has one exact `Lsn` when known and an explicit or omitted absence when unknown; the contract does not select `null` versus `undefined`. | Keep alias/field anti-`any` checks, require the known branch to be exactly `Lsn`, require at least one of `null`/`undefined` as an absence branch, and reject other field members. | Declaration quality versus sentinel spelling | Accepts optional properties, required nullable fields, or unions containing both sentinels while still rejecting `any`, required always-present LSNs, and unrelated value types. |
| Fresh empty-at-zero reconnect currently requires `received === undefined` from polling and both subscribers. | A new connection's observed empty-at-zero range clears the retained received watermark for all public observers. | Use one `isAbsent` predicate accepting only `null` or `undefined` for the polled state and post-boundary callbacks. | Semantic clearing versus JavaScript absence carrier | Retains the reconnect/fan-out discriminator and phase-local callback slices without prescribing serializer output. |
| Several unrelated runtime guards use `!== undefined` merely to mean “watermark present.” A nullable bridge would enter those branches incorrectly. | Presence checks distinguish both supported absent sentinels from every concrete LSN. | Route all state-watermark presence/absence conditions through the same sentinel-neutral helpers; leave protocol-control variables and `mutationStatus` unchanged because those APIs explicitly use `undefined`. | Optional SyncState values versus unrelated control/result values | Prevents a partial relaxation that fixes only the reported assertion while later phases still reject `null`. |

The public prompt does not need to change: preserving representation freedom is
the correction. `mutationStatus` remains specifically `undefined` when no
classification exists, as explicitly documented. No test will accept arbitrary
falsey values; only `null` and `undefined` represent absent SyncState progress.
This gate is recorded before the version-25 `test.patch` edit. At operator
direction no false-positive mutant or variation suite will run, so version 25
starts at 0/10 and remains audit-pending, non-immutable, and not
submission-ready.

### Version-25 verification record

The TypeScript consumer now accepts exactly the documented known `Lsn` branch
plus `null`, `undefined`, or both as the absent branch for each `SyncState`
watermark. It still rejects `any`, an always-present watermark, and unrelated
union members. The real browser probe uses one sentinel-neutral `isAbsent`
predicate for every SyncState watermark presence/absence decision, including
the phase-local polling and both subscription callbacks after an empty-at-zero
fresh reconnect. The explicitly documented `mutationStatus` `undefined`
result and protocol-control variables remain unchanged.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.jB6WD7`:
pristine, tests-only base, tests-only base with stock tools, focused tests-only
rejection, solution-only, combined focused with the real generated-worker
browser probe, missing-browser-tool rejection, and combined base all have their
expected outcome. The reference therefore still exercises timeline binding,
all three progress stages, reconnect replacement, empty ranges, subscriber
fan-out, rollback, and lossless upper-half `u64` behavior after the fairness
relaxation.

At operator direction no false-positive mutant or positive-variation command
was run. Version 25 therefore remains audit-pending, non-immutable, 0/10, and
not submission-ready; none of the version-24 verification or unused solver
runs carry into a future immutable batch.

Current version-25 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `14382deac9791b2d08b1be442d28287e30162593b7f28a38f63839545f8a64aa` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `f97fa2c0902f562743e1335fc31c2e468b213ad22611695e64b953899cde5e01` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `2e371a2cdaa8aaf76f69047e7fb60965a2e01efa2badc97d02c0ec7b6228dd50` |

## Version-26 fresh-snapshot and near-ceiling design gate

The 2026-08-05 coverage report identifies two candidate browser boundaries:
the contents of the initial fresh-document subscription snapshot and exact
`u64::MAX` transport. Before revising `test.patch`, `PROBLEM_DESIGN.md`, the
current compact records, the pinned `LsnRange` and replication implementation,
and representative raw version-22 trajectories were inspected again.

Legitimate run 1 carries browser LSNs as decimal strings and initializes all
three progress values from Rust `Option`; near-pass run 5 declares `bigint` but
still lets runtime serde expose a JavaScript number. Both implement one
per-connection acknowledgement tracker and the public facade. The version-22
batch has no broad implementation failure: its only failures are the two
runtime precision near-passes, so that category is recorded as unavailable.
Run 7 additionally contains an explicit decimal upper-bound check against
`18446744073709551615`, showing that full-width parsing is participant code
rather than a purely hypothetical boundary.

Repository inspection establishes an important limit on the proposed maximum
fixture. `LsnRange::next()` returns `last + 1`, and
`ReplicationProtocol::handle` calls it for every received non-empty range. A
range ending at `u64::MAX` therefore overflows inside pre-existing protocol
code before any observed-sync-state implementation can expose the watermark.
By contrast, a range ending at `u64::MAX - 1` has the representable successor
`u64::MAX` and reaches the same public conversion path while exercising a
20-digit value with every high word bit set.

### Version-26 discriminator ledger

| Review/trajectory evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The initial callback is compared only with a contemporaneous poll, so a facade and worker that agree on fabricated zero progress pass. A new document has no allocated local entry, peer acknowledgement, or replicated application row. | The current snapshot delivered synchronously for a fresh document has absent `local`, `received`, and `applied` progress. | Before any mutation or acknowledgement, require all three callback fields to satisfy the same `null`/`undefined` absence predicate, while retaining callback-versus-poll equality and timeline checks. | Snapshot freshness versus observer agreement | Uses only public initial-state semantics and accepts both documented absence carriers; it does not prescribe worker storage or event tags. |
| Existing values at `2^63` and `2^63 + 1` reject signed and rounding conversions, but do not exercise a 20-digit/all-high-word-bits value. Run 7 manually validates decimal bounds. | Every operationally transportable Rust LSN is preserved as a non-number public value. | Observe a real acknowledgement ending at `u64::MAX - 1`, require a changed non-number opaque value, and pass it back through `mutationStatus` as an above-local receipt. | Signed-half crossing versus near-ceiling width | Reuses the real protocol and treats the public carrier as opaque. String, bigint, word-pair, byte-array, and normalized carriers can pass. |
| A proposed acknowledgement ending exactly at `u64::MAX` overflows in the pinned repository's existing `LsnRange::next()` before the feature boundary. | Hidden tests must not require repair of unrelated pre-existing range-successor semantics. | Do not inject an exact-maximum range. Record `u64::MAX - 1` as the strongest reachable real-protocol value. | Public serialization versus upstream protocol domain | Rejects an artificial failure shared by the pristine protocol and otherwise correct implementations; no private reply fixture or representation-specific synthetic maximum is introduced. |

The public prompt remains unchanged. Its losslessness rule still prohibits a
JavaScript number and does not select a carrier. The exact-maximum omission is
an acknowledged black-box reachability limit, not permission to truncate a
public value. This gate is recorded before the version-26 `test.patch` edit.
At operator direction no false-positive mutant or positive-variation suite
will run, so version 26 starts at 0/10 and remains audit-pending,
non-immutable, and not submission-ready.

### Version-26 verification record

The initial callback and contemporaneous poll are still structurally compared,
and both now must expose absent `local`, `received`, and `applied` progress for
the fresh document using the version-25 `null`/`undefined`-neutral predicate.
The real protocol flow additionally observes `u64::MAX - 1` from a non-empty
range, requires a distinct opaque non-number public value, and passes that value
back through `SQLSync.mutationStatus` as an above-local receipt.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.yfy2AN`,
including pristine and both base lanes, expected tests-only rejection,
solution-only full checks, the combined real browser/Wasm lane, mandatory
missing-browser-tool rejection, and combined base compatibility. The exact
`u64::MAX` range remains deliberately absent because it overflows the pinned
repository's pre-feature successor calculation.

At operator direction no false-positive mutant or positive-variation command
was run. Version 26 remains audit-pending, non-immutable, 0/10, and not
submission-ready.

Current version-26 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `a8d0916ea4c3ba8173082a100ae84ccdc8ffab5fc4dfc603ac181e9d82c751a1` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `720acfde2b15769fbe5eff73225f2dd5fc58b021d6b9034a998765e90a3ee9dd` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `952965259aec268d02e9b8f1d35549086b0f38bce7e704abc22167d1fc4042ab` |

## Version-27 run-7 trajectory gate

Version 26 completed a ten-run unhinted batch in `agent-runs7`: runs 1, 2, 4,
5, 6, 7, and 8 are legitimate passes; run 3 is a broad subscription failure;
and runs 9 and 10 are near-passes whose declared `bigint` carrier is routed
through unsupported `u128` serde. At 7/10, version 26 exceeds the 50% solve-rate
cap and is abandoned. Per `CALIBRATION_STRATEGY.md`, version 27 starts a new
immutable candidate at 0/10; no version-26 result or unused capacity carries
forward.

Before revising `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, current compact records, all ten version-26 patch
summaries, and representative raw trajectories were inspected. Legitimate run
1 uses a document-keyed TypeScript subscriber map, event-based delivery,
timeline-filtered applied queries, and a `bigint` public carrier, but clears its
remembered acknowledgement on `ConnectionTask::Connect`. Broad-failure run 3
implements the same cross-layer architecture but rejects its first subscription
because an optional-chaining duplicate guard treats a missing list as present.
Near-pass run 9 implements document-keyed push delivery and timeline-filtered
applied reads, but its custom `u128` serializer fails at the live Wasm ABI. The
successful implementations span string and bigint carriers, cached and queried
applied state, and several internal signal/reply schemas.

Across the passing patches, subscriptions are normally keyed by a stable
document string, acknowledgement and applied changes are emitted from worker
signals, and applied lookup includes the active timeline ID. Those convergent
correct choices must remain valid. The new discriminators therefore target
public boundaries rather than selecting one of their private implementations.

### Version-27 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Legitimate run 1 sets `received = None` when a connect attempt starts, then passes because every existing reconnect server immediately answers with a Range. | `received` is the latest acknowledgement actually observed and remains available until a newly observed peer range replaces it. | Reconnect to a socket that accepts the client but withholds its Range; polling and any new subscription callbacks must retain the disconnected watermark. Then deliver a lower range and require replacement. | Connection intent versus peer observation | Directly distinguishes the observed-knowledge boundary and accepts caches, protocol-owned ranges, or reconstruction. |
| Existing subscriptions coexist only for one document. A process-global callback list can satisfy all same-document fan-out and unsubscribe checks. | A subscription is scoped to the supplied `docId`; changes for one document never reach another document's handler. | Keep two real documents subscribed simultaneously, mutate each independently, and require only that document's post-boundary callback list to advance. | Same-document fan-out versus cross-document routing | Uses the real public facade and worker, not internal tags, synthetic events, or JavaScript reference identity. |
| The prompt requires push delivery, while current waits inspect callbacks without bounding background facade requests. A timer can repeatedly ask for snapshots and imitate every state transition. | After establishment, observed changes arrive from worker push delivery without polling. | Require no host-to-worker request across an idle interval longer than the callback budget. Then inject a coordinator acknowledgement outside the facade and require the first bridge activity to be worker-to-host delivery before awaiting the callback; poll only afterward for independent confirmation. | Value correctness versus delivery mechanism | Records only request/delivery direction, not private tags. Direct state events and event-triggered snapshot fetches pass because both deliver before any follow-up request; a polling timer requests first. |
| Runtime number rejection currently occurs only for large acknowledgement values. A hybrid bridge can expose safe LSNs as JavaScript numbers and large LSNs losslessly. | Every browser-visible LSN, including small receipts and snapshot values, is non-`number`. | Check each real small mutation receipt and the local, received, and applied snapshot fields, while continuing to compare values opaquely. | Safe-integer convenience versus uniform public representation | Does not require string, bigint, conversion, or generated provenance. |
| The applied browser flow contains one active timeline. A document-global maximum query can report another timeline's coordinator application. All reviewed passes already filter by timeline, but the shortcut is independently supported by the shared SQLite timeline table. | `applied` belongs to the snapshot's own timeline. | In the Rust integration, replicate coordinator storage containing an applied row for timeline A into the same document database whose active local timeline is B; B's applied progress remains absent. | Document identity versus timeline identity | Exercises the public snapshot and existing replication/rebase model without requiring a SQL query or cache layout. |

The proposed standalone fake-worker test is rejected. It requires exact private
`SyncStateSubscribe`, `SyncState`, and event wrapper tags, a constraint already
found unfair in earlier review. The same document-isolation and no-polling
properties are observable in the real generated-worker lane through two public
subscriptions and schema-agnostic outer request counts.

This gate is recorded before the version-27 `test.patch` edit. The prompt and
reference solution need no change: every accepted invariant is already public
and the reference architecture already satisfies it. At operator direction no
false-positive mutant or positive-variation suite will run. Version 27 begins
at 0/10, audit-pending, non-immutable, and not submission-ready.

### Version-27 verification record

The real generated-worker probe now keeps two documents subscribed during
independent mutations, rejects cross-document delivery, and observes no opaque
host-to-worker request during a 5.1-second idle interval. For a coordinator
acknowledgement injected outside the facade, the first subsequent bridge
activity must be worker-to-host delivery; direct state events and
event-triggered snapshot fetches both remain valid. It checks small receipts
and snapshot watermarks for the same non-`number` property already required of
high values. After retaining an acknowledgement through
disconnect, it accepts a new socket whose peer withholds its range and requires
both polling and any new callbacks to preserve the old observation; a later
range still replaces it. The Rust integration separately proves that applied
progress from another timeline in the same document database is not reported
for the active timeline.

The static artifact audit passes. The exact eight-state offline matrix passes
at `/tmp/sqlsync-gates.HoAUmc`: pristine, tests-only base, stock-tool base,
tests-only focused rejection, solution-only, combined real browser/Wasm,
mandatory missing-browser-tool rejection, and combined base all have their
expected outcomes. The combined lane also passes the adaptive status consumer
and four Rust integrations.

Version-26 run 1 is replayed unchanged and fails at `reconnect intent erased
acknowledgement before observing a peer range`, confirming that the reported
survivor is killed at its distinct public boundary. Version-26 run 2 passes the
strengthened lane, establishing that the probes accept a separate solver
architecture rather than only the reference. These are construction replays,
not version-27 calibration runs.

At operator direction no false-positive mutant or positive-variation command
was run. Version 27 therefore remains audit-pending, non-immutable, **0/10**,
and not submission-ready.

Current version-27 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `080c5876a42e0498d99d66507471d63a07f394dc3f01166134c94c8ca424543a` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `18cf79e21b3798bced6013985eee763823485653f02342be1af0d3b47ebeb7b7` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `b5db7ecfff10b3879420456e9fac69490de71adbdfd22c895513db821351f0f1` |

## Version-28 run-8 trajectory gate

Version 27 has five completed unhinted runs in `agent-runs8`. Runs 1 through
4 are legitimate end-to-end passes and run 5 is a broad browser-integration
failure, for a 4/5 solve rate. This is already a harden signal under the
four-run checkpoint in `CALIBRATION_STRATEGY.md`, and the operator explicitly
requested hardening. Version 27 is therefore abandoned; version 28 starts at
0/10 and no run or remaining slot carries forward.

Before revising `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current design/verification record, all five
run-8 solution patches and evaluator records, and representative raw
trajectories for legitimate run 1 and broad-failure run 5 were inspected. The
raw trajectory schema contains four wrapper steps with tool calls embedded in
the agent step, so it does not provide the platform agent-message metric.
Successful runs used four meaningfully different implementations: decimal
strings or bigint for LSNs; facade-side or worker-side classification; one
worker registration per port or one per subscription; queried or cached
applied progress; and shared or separate progress/status signals. All four use
content-stable document keys at the TypeScript event boundary and correctly
derive a watermark from an empty retained timeline range.

Run 5 implemented most Rust and worker behavior but stored facade subscribers
in `Map<DocId, ...>`. Because `DocId` is a `Uint8Array`, the deserialized event
used a different object identity and the required initial snapshot never
reached the handler. The existing real browser test already rejects that
architecture at the earliest public subscription boundary; adding another
fixture for the same keying defect would not add discrimination. The run also
did not execute the real browser integration during its own verification,
whereas every legitimate run did substantial cross-layer inspection and
verification.

The prior batch has no near-pass: the four green patches are complete and the
only failure loses the entire subscription channel. The new ledger therefore
targets independent public transition combinations that the v27 tests state
but exercise only separately, rather than manufacturing a closer variant of
the run-5 identity bug.

### Version-28 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The Rust flow proves that `local` survives prefix removal, but stops before another mutation. The repository represents a removed prefix as `LsnRange::Empty { nextlsn }`; using only `last()` when allocating the next receipt duplicates or resets the LSN. | A successful mutation after rebase continues at the retained range's next LSN, and the snapshot can simultaneously report a newer local receipt with an older applied/received prefix. | Apply and rebase one mutation, allocate another, require a distinct successor receipt, and assert `local` is the successor while `received` and `applied` remain the older inclusive watermark. | Retained progress versus subsequent allocation | Exercises the existing journal representation and public receipt/state fields; caches, direct range queries, and either accepted `sync_state` return wrapper remain valid. |
| The browser applied flow uploads two mutations before one coordinator step, so application jumps directly to the newest receipt. A bridge that collapses all stages whenever any application appears can pass. | `local`, `received`, and `applied` are independent inclusive watermarks, and classification uses the furthest stage reached by each receipt. | Apply/rebase the first receipt before creating the second; then require the older receipt to remain `applied`, the newer receipt to be `received`, and a later application to advance the applied subscription and poll to the newer receipt. | Endpoint stage checks versus a mixed-stage snapshot | Uses only real coordinator, storage replication, public polling, and push delivery; it does not inspect SQL, caches, signals, or worker message names. |
| Rust explicitly rejects classification without `local`, but the browser classifier is only called after a local mutation. A separate facade implementation can omit the local bound. | Browser classification has the same fundamental local-existence bound as Rust. | On the fresh coordinator-backed document, reuse an opaque real LSN with that fresh timeline and require `mutationStatus` to return `undefined` before its first mutation. | Rust classifier versus browser classifier seam | The LSN comes from the real public API and remains opaque, so no string, bigint, conversion, or internal reply representation is selected. |
| The lifecycle test removes one listener while another remains; it never reaches zero and re-establishes the subscription. A worker can leave stale registration state or fail to register again. | Every successful subscription call receives the current snapshot before resolution and later pushes, including after all earlier subscriptions have unsubscribed. | Remove the final listener, subscribe again, compare its immediate snapshot with a contemporaneous poll, then require the next real acknowledgement through that new listener. | Fan-out removal versus zero-to-one re-establishment | Tests the public lifecycle and accepts per-port, per-document, or per-subscription worker bookkeeping. |
| The structural type consumer rejects `any` for state fields but does not prove the named subscription's handler consumes `SyncState`, nor that public timeline fields are `DocId` rather than an opaque placeholder. | The exported receipt/state timeline values are document IDs and `SyncStateSubscription.handleState` consumes the exported `SyncState`. | Add bidirectional assignability checks for the timeline field and an exact handler-parameter/return check while retaining representation-neutral optional-LSN checks. | Export names versus usable public structure | Rejects broad placeholder aliases without requiring `interface` syntax, mutable versus readonly fields, an LSN carrier, or one generated-type provenance. |

The same-object duplicate-subscription case is rejected because the public API
does not define whether one handler object may be registered twice. Callback
re-entrancy and exception isolation are also rejected; they are useful
robustness work but not stated progress semantics, and earlier investigation
showed the reference shares the live-array re-entrancy behavior. Lowering a
Range within one established protocol is rejected because the pinned protocol
asserts its monotonic outstanding-range invariant before this feature can
observe it. Exact `u64::MAX`, private worker tags/wrappers, JavaScript reference
identity, and one absence sentinel remain rejected for the previously recorded
reachability and fairness reasons.

No prompt change is required: successor allocation follows the exact-receipt
and retained-local clauses; mixed snapshots follow the three independent
inclusive watermarks and classifier precedence; the absent-local rule is
already explicit in the common Rust/browser classifier contract; and the
subscription method's current-before-resolution/later-push contract applies to
every call. This gate is recorded before the version-28 `test.patch` edit. At
operator direction no false-positive mutant or positive-variation suite will
run, so version 28 remains audit-pending, non-immutable, and not
submission-ready.

### Version-28 verification record

The real generated-worker lane now applies and rebases the first browser
receipt before allocating the second. It observes the first as Applied, then a
mixed snapshot whose local/received watermark is the second receipt and whose
applied watermark remains the first, and finally a fresh applied subscription
transition to the second. The matching Rust integration allocates again after
the retained timeline becomes empty-at-next and proves the successor receipt
and all three mixed watermarks. The browser classifier separately rejects an
opaque same-timeline receipt on a fresh snapshot with no local progress.

After both original listeners leave, a new listener must receive the current
near-ceiling snapshot before establishment resolves and then receive the next
real acknowledgement. The TypeScript consumer now rejects a placeholder
timeline type and a named subscription whose handler does not take exactly the
exported `SyncState`. Optional progress still accepts `null`, `undefined`, or
both; LSN values remain opaque and non-`number`; and no internal worker tag or
object identity is asserted.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.tIXLat`:
pristine, both tests-only base lanes, expected tests-only focused rejection,
solution-only, combined real browser/Wasm, mandatory missing-browser-tool
rejection, and combined base. All four legitimate run-8 patches pass the
strengthened lane. Run 5 still fails at `sync-state subscription did not
deliver its current snapshot`, confirming the original content-keying defect
remains rejected. Those are construction replays, not version-28 calibration
runs.

At operator direction no false-positive mutant or positive-variation command
was run. Version 28 therefore remains audit-pending, non-immutable, **0/10**,
and not submission-ready.

Current version-28 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `1155fe225bc2c1b566a3138ab14713f42e7271fb1c18a960ad91aafa019e520b` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `2aa1007cbafae4e5946f443cf82726bec7a592ee18f3aa13192a02e978030b6e` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `639549a326a0cf751cbb6ed82daa954f5b7df9a90602daa2d3ea30cea83ec359` |

## Version-29 inclusive-Local design gate

The new coverage report identifies one classifier boundary that version 28
does not exercise: a receipt strictly below `local` but above both `received`
and `applied`. Before revising `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the current problem history, the version-21
inclusive-Received design record, all five run-8 classifier implementations,
and representative legitimate/broad-failure run-8 trajectories were reviewed.
No near-pass exists in that batch. The raw trajectory schema still exposes
four wrapper steps rather than the platform agent-message metric.

All five run-8 implementations use the correct generalized precedence chain:
reject above-local receipts, compare Applied and Received inclusively, then
classify every remaining at-or-below-local receipt as Local. Their convergence
shows the intended behavior is natural, but it does not make the missing oracle
redundant: the current public consumer would also accept an implementation
whose Local branch requires equality because its only Local fixture is LSN 5
with `local = 5`. The repository and prompt independently define every progress
value as an inclusive watermark, so this is a public value boundary rather
than an implementation-style preference.

### Version-29 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The status consumer proves exact Local, older/equal Received, and older/equal Applied, but no receipt lies inside the Local-only interval. A plausible equality-only Local branch passes all current fixtures. | `local` is an inclusive watermark: after Applied and Received precedence are exhausted, every same-timeline receipt at or below `local` classifies as Local. | In the existing `local = 5`, `received = 3`, `applied = 1` snapshot, classify receipt 4 and require `MutationStatus::Local` through the owned/borrowed signature-adaptive consumer. | Exact newest-local receipt versus an older Local-only receipt | Adds one missing interval boundary to the existing public classifier matrix; it does not require traits, an argument ownership form, a constructor, or private state. |

A second browser fixture is rejected because the browser's real histories do
not naturally expose a Local-only interval without adding an unrelated
transport scenario; the Rust public consumer already tests the common
classifier contract. Permuting more receipt values inside the same interval is
also rejected as duplicate coverage. No prompt or reference change is needed.
This gate is recorded before the version-29 `test.patch` edit. Per operator
direction no false-positive mutant or positive-variation suite will run, so
version 29 starts at 0/10 and remains audit-pending, non-immutable, and not
submission-ready.

### Version-29 verification record

The signature-adaptive Rust consumer now evaluates receipt 4 in the existing
snapshot whose local, received, and applied watermarks are 5, 3, and 1. It
requires Local, completing the classifier's public inclusive intervals without
adding an argument-ownership, comparison-trait, constructor, or browser-carrier
constraint.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.wM2rXV`:
pristine, both tests-only base lanes, expected tests-only focused rejection,
solution-only, combined real browser/Wasm, mandatory missing-browser-tool
rejection, and combined base. Representative run-8 implementations using a
borrowed receipt and a generic `Borrow` status argument both pass the focused
consumer at `/tmp/sqlsync-v29-status-replays.AQ0e23`. These are construction
replays rather than calibration runs.

At operator direction no false-positive mutant or positive-variation command
was run. Version 29 therefore remains audit-pending, non-immutable, **0/10**,
and not submission-ready.

Current version-29 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `1e26644f729ce5673541c8ac2f3721aacb4e57c3437a56281867cbb2cdf84435` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `2274678f0f3eb2f64dad8858925d7d30638e18196894b0c2d6e1d44194f88043` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `86bc8129da607ace55a22387a81e8f6405539bd8efc780c25548054a3a037e02` |

## Version-30 unsubscribe and deterministic-barrier design gate

The two new coverage reports were evaluated before revising `test.patch`.
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the current problem history,
the version-27 routing ledger, the version-28 subscription-lifecycle ledger,
all five run-8 subscription implementations, and representative legitimate
run 1 and broad-failure run 5 trajectories were reviewed. No near-pass exists
in that batch. The raw trajectory schema still exposes four wrapper steps
rather than the platform agent-message metric.

The legitimate implementations generally maintain one facade subscription
registry, but the repository has independent local-timeline and coordinator-
network signals before they converge on public sync-state delivery. Version 29
proves that unsubscribe suppresses a later acknowledgement only. A split or
partially detached implementation can therefore continue delivering local
mutation changes while passing. That is a distinct public lifecycle boundary:
the prompt says the returned function prevents *all* later states, and it
explicitly names local mutations and coordinator acknowledgements as separate
observable change sources.

The fixed 25 ms negative waits are also unnecessary. Multi-document isolation
can be checked after both documents' own positive mutation callbacks have
arrived. Retention during an unanswered reconnect can be checked after both
subscribers receive the causally later fresh-range callback, while preserving
the entire intervening history. Unsubscribe can be checked after the remaining
subscriber receives the same acknowledgement or local-mutation change. These
barriers are public observable progress, not worker tags, queue internals, or
scheduler assumptions.

### Version-30 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Local timeline changes and coordinator Range observations enter the worker through independent signals, while version 29 exercises unsubscribe only with the latter. | Once the returned unsubscribe function is called, that subscription receives no later state from any documented change source. | Keep a second listener active, unsubscribe the first, perform a successful local mutation, wait until the active listener observes its receipt, and require the removed listener's callback history to remain unchanged. | Network-change unsubscribe versus local-change unsubscribe | Uses the real public mutation and subscription APIs and accepts any internal registry, message schema, or event coalescing strategy. |
| The current browser probe uses 25 ms sleeps before several absence assertions even though each scenario already has a causally later positive event. | Negative routing and transient-history claims should be evaluated only after the relevant delivery stream has demonstrably advanced past the tested action. | Replace sleeps with positive callback barriers: both documents' own mutation callbacks for isolation, both listeners' fresh-range callbacks for reconnect history, and the remaining listener's callback for unsubscribe. Inspect the complete post-baseline slices. | Wall-clock settling versus causal completion | Removes scheduling sensitivity without requiring callbacks to use a private queue, a particular task primitive, or a maximum latency. |

An arbitrary delayed-callback timeout is rejected because the public API does
not promise a millisecond deadline. Extra sleep duration and repeated mutations
inside the same event-source family are also rejected. The local mutation is
kept because it is the one explicitly documented source not covered after
unsubscribe. No prompt or reference change is needed. This gate is recorded
before the version-30 `test.patch` edit. Per operator direction no false-
positive mutant or positive-variation suite will run, so version 30 starts at
0/10 and remains audit-pending, non-immutable, and not submission-ready.

### Version-30 verification record

The real generated-worker lane now leaves one subscription active after the
primary listener unsubscribes, performs another successful local mutation, and
waits for the active listener to observe that exact receipt before asserting
that the removed listener's history is unchanged. The existing later
acknowledgement check uses the same positive-listener barrier. This covers both
documented change sources without adding a callback deadline.

All 25 ms negative callback-settling sleeps were removed. The two-document
isolation oracle waits for each document's own mutation delivery and then
checks callback counts and timeline identities. The unanswered-reconnect
oracle retains the complete histories until both listeners receive the later
fresh range, then rejects any intermediate watermark other than the retained
or newly observed value. The idle no-polling interval remains intentionally
time-based because elapsed idleness is the behavior under test, not a callback
settling mechanism.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.aLYhVY`:
pristine, both tests-only base lanes, expected tests-only focused rejection,
solution-only, combined real browser/Wasm, mandatory missing-browser-tool
rejection, and combined base. Legitimate run-8 solutions 1 and 4 also pass the
complete focused lane; they respectively use document-level subscription
fan-out and per-subscription identifiers. These are construction replays, not
version-30 calibration runs.

At operator direction no false-positive mutant or positive-variation command
was run. Version 30 therefore remains audit-pending, non-immutable, **0/10**,
and not submission-ready.

Current version-30 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `511eff99dcf6c419f897ad270aef3757cb69f35773932656aa9d687ca13d7ee6` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `d4294c1dc21dfae8b1a074bf5a0fe515a4ea82ea7f2c56d1544ecf5518d6f17c` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `acd32e9d4de2f44594c794d6c71ac7d4e50d9501617ba5d7901923c105e48b54` |

## Version-31 browser inclusive-Received design gate

The two new coverage reports were evaluated before revising `test.patch`.
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the current problem history,
the version-23 browser-classifier record, the version-26 near-ceiling record,
all five run-8 classifier implementations, and representative legitimate run 1
and broad-failure run 5 trajectories were reviewed. No near-pass exists in the
run-8 batch. The raw trajectory schema still exposes four wrapper steps rather
than the platform agent-message metric.

The Received report is correct. The real browser flow classifies a receipt at
the exact received watermark. Its only older-receipt assertion occurs after
that receipt has become Applied, so Applied precedence masks Received. A
facade-specific classifier using equality for Received and an inclusive Rust
classifier can therefore pass. All run-8 solutions implement inclusive
comparisons, showing the correct behavior is natural, while the independent
browser surface still needs its own value-level oracle.

The proposed exact `u64::MAX` acknowledgement remains rejected for the reason
established in version 26. In the pinned repository every received non-empty
range is passed through `LsnRange::next()`, implemented as `last + 1`; a range
ending at `u64::MAX` therefore overflows before worker observation or public
serialization. The current `u64::MAX - 1` acknowledgement is the strongest
reachable real-protocol value. Since the prompt permits any documented
lossless non-`number` browser carrier, a synthetic maximum cannot be built and
fed back representation-neutrally without selecting one solver's encoding or
adding a test-only production API.

### Version-31 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Browser Received is tested only at equality, while its older-receipt check is masked by Applied precedence. Rust coverage cannot constrain an independently implemented facade classifier. | Received is an inclusive browser watermark after timeline and local bounds, just as it is in Rust. | After a later successful local mutation while `received` is already ahead and `applied` is absent, classify the earlier same-timeline receipt and require `"received"`. | Exact Received versus older Received on the browser seam | Reuses real receipts and observed state, treats LSNs opaquely, and adds no message-schema, carrier, or ownership constraint. |
| An exact-maximum range would overflow the pristine protocol's required exclusive successor calculation before the feature boundary. | Tests should cover the strongest operationally reachable value without requiring repair of unrelated range arithmetic. | Retain the real `u64::MAX - 1` acknowledgement and opaque round-trip; do not add an exact-maximum wire fixture or representation-specific synthetic receipt. | Public serialization versus upstream protocol reachability | Preserves all documented lossless carriers and avoids a failure shared by otherwise correct implementations and the pinned protocol. |

No prompt or reference change is needed. This gate is recorded before the
version-31 `test.patch` edit. Per operator direction no false-positive mutant
or positive-variation suite will run, so version 31 starts at 0/10 and remains
audit-pending, non-immutable, and not submission-ready.

### Version-31 verification record

The real generated-worker lane now calls `SQLSync.mutationStatus` for the
original receipt after a second local mutation has advanced `local`, while the
previously observed coordinator watermark remains ahead and `applied` is
absent. The required result is Received. The receipt and both state values stay
opaque, so the oracle tests the inclusive browser comparison without choosing
an LSN carrier.

The exact-maximum proposal was not implemented. The pristine protocol's
`LsnRange::next()` performs `last + 1` while processing a received non-empty
range, making `u64::MAX` unreachable before the observed-state and browser
conversion paths. The existing real `u64::MAX - 1` acknowledgement and opaque
round-trip remain the strongest fair runtime boundary.

The static artifact audit passes against the standalone pinned clone. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.f9aYVR`:
pristine, both tests-only base lanes, expected tests-only focused rejection,
solution-only, combined real browser/Wasm, mandatory missing-browser-tool
rejection, and combined base. Legitimate run-8 solutions 1 and 4 also pass the
complete focused lane with their distinct browser/subscription architectures.
These are construction replays rather than version-31 calibration runs.

At operator direction no false-positive mutant or positive-variation command
was run. Version 31 therefore remains audit-pending, non-immutable, **0/10**,
and not submission-ready.

Current version-31 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41` |
| `test.patch` | `b3f2c45ac8edc21e586d827aa4667a8a23834d535aa0dfa3571ed8454e4aca8a` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `e51271cf64cd59709ac40e0dbbfe5d10deaff8bc9abbbe14ce479f77f1450f1e` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `6ee666b7b8243afbab8d04d59551ec815ef94812104cf60ef1d3d2ca76e409e7` |

## Version-32 run-9 hardening design gate

This gate was completed before changing `test.patch`. `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the version-31 requirement history, every run-9
`run.txt`, `eval-result.json`, solution patch, and representative raw
trajectories from runs 1 and 5 were reviewed. There is no near-pass or failing
run in this batch: all five unhinted runs passed both lanes and were adjudicated
as legitimate. The ATIF files again contain four wrapper steps, so the platform
agent-message difficulty metric is unavailable locally.

Run 9 is therefore a completed 5/5 legitimate-pass calibration batch for
version 31, not evidence that version 31 should be retained. Its five solutions
cover meaningfully different constructions: facade-only document-keyed push
fan-out, worker-side per-subscription identifiers, per-port worker registration,
reference-counted per-port registration, Rust-side and facade-side classifiers,
decimal-string LSNs, and BigInt LSNs. All nevertheless pass the same public
suite. Version 31 is abandoned as under-discriminating; any version-32 artifact
change restarts calibration at **0/10**.

The raw successful trajectories also expose a concrete subscription shortcut.
Run 5 sends the initial state for every new registration as an unaddressed
document event. Its facade fans that event out to all local listeners, so adding
a second listener invokes the first listener again even though the document's
`SyncState` did not change. Runs 1-4 and the reference deliver a new
registration's current snapshot only to that registration. This is a public
registration-isolation boundary, not a worker-schema requirement: a caller can
observe the extra callback using only two `subscribeSyncState` calls.

Two semantic boundaries remain under-asserted independently of that shortcut.
The real browser flow reaches older Received and Applied cases but never
classifies an older receipt as Local, so an equality-only Local branch in the
independent facade classifier can pass. The superficially similar Rust report
is stale and is rejected: the current status executable already classifies LSN
4 as Local under `local = 5`, `received = 3`, and `applied = 1`. Adding another
Rust fixture would duplicate that semantic boundary. In addition, the
rejected-mutation browser check compares the
watermark value but does not require the next successful receipt to be the
immediate successor or require the failed request to produce no callback at
all; a stale cache hiding a consumed allocation or emitting an unchanged
snapshot can pass the present assertions.

### Version-32 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Run-9 solution 5 uses an unaddressed initial-state event and fans it out to every existing listener. | Each registration receives its own initial snapshot; registering or removing a peer subscription is not a document state change and must not notify existing registrations. | Record the first listener's count, add a late listener, require exactly one initial callback for the late listener and no callback for the first listener. | Registration lifecycle isolation versus document-state delivery | Uses only public facade calls and callback counts; it permits per-port, per-ID, and facade-only designs and names no request or reply tag. |
| Browser integration exercises Local only at the newest exact watermark; the Rust executable already covers an older Local receipt. | Local is an inclusive browser watermark after timeline/local bounds, just like Received and Applied. | In the real worker, allocate a second receipt before acknowledgement and classify the first as Local. | Older Local versus exact Local on the independent browser classifier surface | Uses real browser receipts and treats their LSNs opaquely; no duplicate Rust fixture or carrier is selected. |
| Rejected browser mutation is checked only for an unchanged scalar watermark. | Failure creates no receipt, consumes no allocation, and produces no sync-state change. | Place a request/reply barrier after rejection, require the subscription count to remain unchanged, then require the next successful receipt/state transition to follow the accepted prefix rather than a hidden failed allocation. | Transactional allocation rollback and notification purity | The value comparison is against real adjacent receipts/state and does not inspect reducer, journal, worker messages, or persistence layout. |
| The existing multi-document and no-polling probes already impose public behavior that the prompt leaves implicit. | Subscription identity includes the supplied document and push registration is independent per document. | Retain the existing real two-document mutation oracle and idle push oracle, while stating their public contract explicitly. | Prompt/test derivability rather than a new implementation discriminator | Removes an avoidable fairness ambiguity without exposing hidden fixtures or requiring one bridge protocol. |

Exact `u64::MAX`, callback re-entrancy, duplicate registration of the same
handler object, private worker tags, and a required Rust replication accessor
remain rejected. Exact maximum still overflows the pinned protocol's exclusive
successor calculation; the other cases either lack a public contract, were
previously shown to be shared by the reference, or select an internal design.

Per operator direction, no false-positive mutant suite or positive-variation
suite will be run for this revision. The gate is trajectory-informed, but the
resulting version remains audit-pending and cannot be called immutable or
submission-ready under the workspace policy.

Run-9 evidence identifiers:

| Artifact | SHA-256 |
|---|---|
| Run 1 solution / trajectory | `0b06bdd197f1e8efd68f363bd1126904ca62d4b21105b43f95831888416dc6ac` / `76b600498f87bdc0408989aacff8652b5cb6bf8e7a30678debf2e988e537d171` |
| Run 2 solution / trajectory | `bcb2037f58b9ba86ec76a758e266fcfc72e6acc2dd77279951d93d3049492182` / `b38057f0fd6204fbf2208690bc421e3df07818e9f812e45d9f888f551449d245` |
| Run 3 solution / trajectory | `66a508e770592b735397e039a1bf685840d8dc42e8c5a11f094b4b311ce25fb5` / `d97a6086d93e7d6e7cdfa0e4d172b444f91507895795fb9c3af02a636a4ce99b` |
| Run 4 solution / trajectory | `603e6f7cd4f6e2217b8aa59bb0698e26057993a7593b32a2a859b90a2838655a` / `e03b284ec73a1de951209bef2754f1c65baaf257d8cabc784acc3a670f2a679c` |
| Run 5 solution / trajectory | `965561e20543ecb8e1d58ffdbd8ba2ccf53dedcaa58eec9bd4dbffe2973357ec` / `ebe7dbb0903c4dbe26acbdc82aa4a2b0181c343626acf562aa8bdc0f47b7442e` |

### Version-32 verification record

The reference passes the complete focused `new` lane with the real generated
worker/Wasm browser probe, strict TypeScript consumers, React/Solid builds, the
owned-or-borrowed Rust status executable, and all four focused Rust
integrations. The exact eight-state offline matrix passes at
`/tmp/sqlsync-gates.NLhyRy`: pristine, tests-only base, tests-only base with
stock tools, expected tests-only new rejection, solution-only regressions,
combined new, required rejection when browser tools are absent, and combined
base. Every recorded status is zero at the gate level; the two rejection gates
also produced the required failing JUnit payload for the inner unsupported
state.

All five run-9 solutions were replayed against version 32. Solutions 1 through
4 pass the complete focused lane unchanged. Solution 5 fails with
`registering a peer subscription notified an existing subscription`, before
any later state transition, which confirms that the oracle detects the
document-wide initial-event shortcut identified in its raw trajectory. The
reference passes the same oracle. Runs 2-4 are recorded at
`/tmp/sqlsync-v32-run9-234.bZIgNJ`; the earlier run-1 and run-5 focused logs are
`/tmp/sqlsync-v32-run9-1.XXXXXX.log` and
`/tmp/sqlsync-v32-run9-5.XXXXXX.log`. These are historical construction
replays, not fresh version-32 solver calibration runs.

The prompt and tests now agree that a failed mutation consumes no allocation
and emits no state change, and that subscription registration lifecycle is
independent within a document. The browser Local check is an opaque inclusive
comparison between real receipts; the allocation rollback check is in Rust,
where exact successor arithmetic is directly observable without selecting a
JavaScript LSN carrier. Peer registration/removal checks use synchronous
public callback counts, so they introduce no settling timeout or private worker
protocol assumption.

At operator direction, the false-positive mutant suite and accepted-variation
suite were not run. Version 32 therefore remains audit-pending,
non-immutable, **0/10**, and not submission-ready. Any further change to a
participant-facing or verification artifact starts a new version and requires
the normal gates again.

Current version-32 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `f4dd212a1116be3f4d423acfd56421ea452dbe3b42ab3be744d66e2296a6d78b` |
| `test.patch` | `d0f3e199630ee2e82e92403a880a631b9ccf9e4e2887e203287a2c7466f5cf07` |
| `solution.patch` | `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `ef124a6f12bfb5fd8d362f6c5a45baf09ebbdafd4f5ed4a7729fdd81e3d4575e` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `44b7cb6ff51e17a33ad239ac60be29e80b0597083e1ea7b67a869246ccc4a69e` |

## Version-33 callback-dispatch hardening design gate

This gate was completed before changing `test.patch` or the reference solution.
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the SQLSync records surfaced by
searches of `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, and related problem histories, the complete
version-32 design record, all five run-9 solution patches, and the raw run-9
trajectories were reviewed. The trajectory files expose four wrapper steps and
no platform agent-message metric. Strict non-test/demo production diffs remain
substantive: 11-14 files and 400-548 additions across the five solutions.

Version 32 is abandoned after historical replay left solutions 1-4 passing and
rejected only solution 5, a 4/5 survival signal. There is still no run-9
near-pass: all five were legitimate version-31 solutions. For version 33,
solutions 1 and 2 are the representative robust constructions, solutions 3 and
4 are the representative live-array constructions, and solution 5 is the
already-rejected document-wide initial-event construction.

The operator-provided adjudication from the earlier subscription review
identified a real re-entrancy defect: iterating a live subscriber array while a
callback removes itself shifts the next listener and skips it. That review did
not count the defect against the then-current task because the prompt omitted
the behavior and the reference shared it; it explicitly recommended snapshotting
the subscriber array if the contract were hardened. Run-9 patches confirm that
this is a genuine architecture discriminator rather than a one-off mutant.
Solution 1 already iterates a snapshot and verifies membership, while solution
2 addresses each worker subscription independently. Solutions 3, 4, and 5
iterate a facade-owned live array that is spliced by unsubscribe.

The stronger contract is public and narrow: when a state change begins
delivery, a subscription that removes itself from inside its callback affects
only later state changes; it cannot prevent an independent subscription that
remains active from receiving the current snapshot. This says nothing about
worker tags, subscription identifiers, array storage, callback object identity,
or whether fan-out occurs in Rust or TypeScript. It does not require delivery
to a peer that another callback explicitly removes, does not constrain callback
exceptions, and does not generalize into an arbitrary re-entrancy matrix.

### Version-33 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Earlier adjudication demonstrated the live-array splice defect and recommended snapshot dispatch if made contractual. Run-9 solutions 3-5 use that live-array pattern; solutions 1-2 use distinct robust fan-out designs. | A subscription's self-unsubscribe during a state callback takes effect for future changes without suppressing delivery of the current change to an independent still-active peer. | Keep two same-document registrations active, arm the first to unsubscribe itself on a real coordinator acknowledgement, and require both to observe that acknowledgement; drive a causally later acknowledgement and require only the peer to observe it. | Re-entrant delivery isolation, distinct from registration-time isolation and ordinary post-return unsubscribe | Uses only public callbacks, the returned unsubscribe function, and opaque real state values. Snapshot iteration, per-ID worker delivery, immutable collections, deferred removal, and other implementations all satisfy it. |
| Version 32's peer-registration oracle rejects run 5 before re-entrant delivery, while solutions 3-4 survive it. | Registration lifecycle and in-flight callback lifecycle are separately observable guarantees. | Retain the version-32 exactly-one-initial-snapshot oracle, then exercise self-unsubscribe only on a later real change. | Registration event routing versus mutation of the active dispatch set | Prevents counting another callback fixture as a new discriminator and demonstrates that the version-33 check reaches a different implementation family. |

The reference must be updated to dispatch over a stable view of the current
subscriptions before this test is added. The public prompt will state the same
semantics. Duplicate callback-object registration, callbacks that unsubscribe a
different peer, callback exception isolation, private bridge schemas, and exact
`u64::MAX` remain rejected as unstated or redundant expansions.

Per operator direction, no false-positive mutant suite or accepted-variation
suite will run. Version 33 starts at **0/10** and remains audit-pending,
non-immutable, and not submission-ready until the required workspace audit is
permitted.

### Version-33 verification record

The first reference construction attempt exposed a stale new-file hunk length
in `test.patch`, causing Node to parse a truncated browser file. The hunk header
was corrected from 1142 to its actual 1152 lines before recording the version-
33 identifiers or running the complete gates. This was patch bookkeeping, not a
behavioral failure.

The corrected reference passes the complete focused lane at
`/tmp/sqlsync-v33-reference-fixed.XXXXXX.log`. Its stable-view facade dispatch
delivers the in-flight acknowledgement to both listeners; the self-removed
listener receives no later local mutation. All five historical run-9 patches
were then replayed at `/tmp/sqlsync-v33-run9-all.huo6VE`. Solutions 1 and 2
pass. Solutions 3 and 4 each fail only after timing out on
`peer delivery during self-unsubscribe callback`. Solution 5 fails earlier on
`registering a peer subscription notified an existing subscription`. This is a
2/5 historical construction split across two distinct subscription failure
families, not fresh version-33 calibration.

The exact eight-state offline matrix passes at `/tmp/sqlsync-gates.F8PYQU`:
pristine, tests-only base, tests-only base with stock tools, expected tests-only
new rejection, solution-only lint/regressions/package, combined new, required
missing-browser-tools rejection, and combined base. The static artifact audit
also passes against the standalone pinned source. No false-positive mutant or
accepted-variation suite was run at operator direction, so version 33 remains
audit-pending, non-immutable, **0/10**, and not submission-ready.

Current version-33 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `f8e83e3b0aab4b2831bd19101a6246dbc208fdd5386d6357a9770741c3743dca` |
| `test.patch` | `2f2663a497dc6b56f8e29c233fe804b1d3370261fafc307661fffa36e4002ddc` |
| `solution.patch` | `a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `68ed5c145bb1f66d5f3724494e58bee5dacabe3e0842b3c98afac5b2edc08b9e` |
| `verify/gates.sh` | `63fb232ad24fd0c381745eb6ef520c468a868fea8f4dee1a940b96650a0178bc` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `e2ce7c71a9022865efc375523a01d3f52a199963f2483e9f5100b02e9bf94030` |

## Version-34 reporting-quality design gate

This gate was completed before changing `test.patch`. `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the complete version-33 record, all ten version-33
calibration summaries and adjudications in `agent-runs10`, every submitted
solution patch, and representative raw successful and failing trajectories were
reviewed. Version 33 produced three legitimate passes (runs 1, 2, and 7) and
seven genuine behavioral failures: JavaScript-number LSNs, duplicate unchanged
connection-status notifications, premature acknowledgement clearing before a
fresh peer Range, an unsupported Wasm `u128` ABI, and subscriptions keyed by
`Uint8Array` object identity. All ten baselines passed, and no adjudication
identified an environment, determinism, derivability, or fairness defect.

The successful solutions remain substantial and independent: their production
diffs span 11-13 files and 454-508 additions, with a median of 12 files and
approximately 492 additions. Their raw trajectories contain 58-76 tool calls;
the available ATIF wrapper count is not a reliable platform agent-message
metric. The 3/10 result is in the intended calibration band, but version 33 is
abandoned because artifact review found two quality defects. Version 34 is a
new candidate version and restarts calibration at **0/10**; version-33 solver
results are historical evidence only.

The first defect is a participant-facing wording mismatch. The phrase
"documented lossless representation" imposes an unverified documentation
deliverable even though the public behavior is fully expressed by preserving
every Rust `u64` without using JavaScript `number`. Removing "documented" does
not weaken or change the executable representation contract.

The second defect is evaluator diagnostics. The runner streams useful Cargo,
TypeScript, and Node output to the terminal, but its requested JUnit artifact
records only a generic exit code. A failed evaluation therefore loses the
specific compiler or assertion message in the machine-consumed report. Version
34 will capture the complete selected lane while preserving live terminal
output, remove bytes that are invalid in XML 1.0, XML-escape the remaining
text, and include it in the JUnit testcase's `system-out`. The exit-code failure
element remains for standard consumers. This is a generic reporting repair,
not a new behavioral discriminator.

### Version-34 discriminator ledger

| Review/repository evidence | Fair invariant | Verification oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Artifact review flags "documented" as a literal, untested obligation; runtime and type tests already enforce lossless non-number LSNs. | Every browser-visible Rust `u64` is lossless and never a JavaScript `number`; no separate documentation deliverable is required. | Remove only the provenance/documentation adjective and retain all representation-agnostic runtime and type probes unchanged. | Prompt precision, not implementation discrimination | Permits bigint, string, or another lossless non-number carrier and adds no hidden representation choice. |
| `test.sh --output_path` currently emits only `runner exited N`, while the same run prints actionable Cargo/tsc/Node output. | The JUnit artifact preserves the actual selected-lane diagnostics for successes and failures. | Exercise successful base/new reports and expected tests-only/missing-tool failures; require `system-out` to contain the real command or assertion output and a correctly set failure count. | Evaluator observability, separate from SQLSync semantics | Captures the whole lane generically and does not map particular assertion strings, commands, or solver architectures to special report logic. |

No SQLSync behavior, hidden semantic probe, reference implementation, Docker
environment, or participant API changes in version 34. The existing version-33
discriminators remain unchanged. Per operator direction, no false-positive
mutant suite or accepted-variation suite will run. Consequently version 34
remains audit-pending and cannot be called submission-ready under the workspace
policy.

### Version-34 verification record

The static artifact audit passes against the standalone pinned source. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.W5zuEv`:
pristine, tests-only base, tests-only base with stock tools, expected tests-only
new rejection, solution-only lint/regressions/package, combined new, required
missing-browser-tools rejection, and combined base. Every gate-level status is
zero. The expected inner rejection reports have `failures="1"`; ordinary lanes
have `failures="0"`.

The report-content oracles confirm that successful base reports contain actual
Cargo test output, the combined new report contains the browser probe output,
the tests-only rejection contains the missing Rust API diagnostic, and the
tool-deficient rejection contains the missing-pnpm diagnostic. The stock-tools
base lane also passes, proving that report generation does not require the
browser toolchain. The runner continues to stream output while capturing it.

No behavioral assertion, participant API, reference solution, or Docker image
changed. Version-33's 3/10 completed calibration is therefore relevant design
history but cannot be counted toward version 34. At operator direction, no
false-positive mutant or accepted-variation suite was run. Version 34 remains
audit-pending, non-immutable, **0/10**, and not submission-ready.

Current version-34 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `64fb33e42127a9511bd727e27efb48ed91fbe7ffdc279dbbf3746b372cc17b0c` |
| `test.patch` | `fe12beae121f03dc016030f91d7eb5146b59dbf9f9bab795a94dfb441f480524` |
| `solution.patch` | `a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `08c84b4760bdf2de8352a21500af1a19ec496ce6c00c8c92df1a8f51dece5c56` |
| `verify/gates.sh` | `5a5171c16f25014c9000d4938f42ba9984dfd0eae653243bcf2b7b82ea5e30d9` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `ffacb641c8e4cf3cb0fd05944215c961b2ca452f862ce78b80d5371fb8484584` |

## Version-35 ordinary teardown-silence design gate

This gate was completed before changing `test.patch`. `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the problem/candidate/success indexes, the complete
SQLSync design and run histories, all version-33 `agent-runs10` adjudications
and solution patches, and representative raw trajectories were reviewed. Run 1
is the representative legitimate pass, run 4 is a near-pass with one unrelated
connection-notification regression, and run 10 is the representative broad
subscription-routing failure. Their raw trajectory and solution hashes are
recorded below. All use the public facade and worker seams but choose different
subscription registries and teardown protocols.

The review finding is valid. The participant-facing contract already says that
removing another subscription is not a state change and must not notify active
registrations. The browser probe directly checks that adding a late peer is
silent, that self-unsubscribe during an in-flight delivery does not skip a peer,
and that removed listeners receive no later local mutation. It eventually calls
the late listener's ordinary unsubscribe only after the primary listener has
already removed itself, so no active peer exists whose callback count can prove
that ordinary teardown was silent.

This is a separate public lifecycle transition, not another event-source
fixture. A plausible implementation can correctly isolate initial registration
but reuse a current-snapshot broadcast when its worker registration or reference
count is reduced. The current suite accepts that extra peer notification. The
oracle will register a disposable third listener on the same real document,
verify its own initial snapshot, record both established peers' histories,
remove only the disposable listener, and issue a public `syncState` request as a
FIFO request/reply barrier. Neither established peer may gain an observation.
The barrier avoids a settling delay and does not require a private unsubscribe
request or acknowledgement shape.

### Version-35 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| Run-10 solutions use facade-only arrays, per-document reference counts, and per-subscription worker IDs; the current test removes its last ordinary listener only after no peer remains. The prompt expressly makes peer removal silent. | Removing one ordinary registration without a document-state change cannot deliver a snapshot to another still-active registration. | With two established peers active, add a disposable same-document registration, capture peer counts after its initial snapshot, remove it, cross a public `syncState` request/reply barrier, and require both peer counts to remain unchanged. | Ordinary registration teardown versus add-time isolation, in-flight self-removal, and later-event exclusion | Uses only public subscriptions, their returned function, public polling as an ordering barrier, and callback counts. Facade-only, reference-counted, per-port, and per-ID implementations all pass when teardown is silent. |

The public prompt and reference solution already implement the required
behavior, so neither changes. Duplicate handler registration, removing a
different peer during an in-flight callback, callback exceptions, private
worker messages, and timing sleeps remain rejected. Version 34 is abandoned
before calibration; version 35 starts at **0/10**. Per operator direction, no
false-positive mutant or accepted-variation suite will run, so the revision
remains audit-pending and cannot be called submission-ready.

Trajectory evidence identifiers:

| Evidence | Solution / trajectory SHA-256 |
|---|---|
| Run 1 legitimate pass | `9eae1202c7ee557fa6988ed26b381f2c2788992b7f822015f81279f1767fd905` / `e29cf0bd2a340459637e9dca6b567e6f4106421ff159c5b30c89c0682c3b5b71` |
| Run 4 near-pass | `ae4793f56a7499ed97e9d1d0e7f4a2111dd647811ec0aa1c3e852c6d4f772bce` / `710f823a5137fb988abab1cb7faeea8efee911dc1ff06ad494767cb88a542088` |
| Run 10 broad subscription failure | `114f060374a67875e78de4842e4e1d103cab78a62473b664eaf986011a8a198f` / `17357e8ed2ece9dad5dadfc5bdab0aa03033af38b2b9f6e02e22b763356579a2` |

### Version-35 verification record

The static artifact audit passes against the standalone pinned source. The
exact eight-state offline matrix passes at `/tmp/sqlsync-gates.Eh0GQ7`:
pristine, tests-only base, tests-only base with stock tools, expected tests-only
new rejection, solution-only lint/regressions/package, combined new, required
missing-browser-tools rejection, and combined base. All eight gate-level status
files contain zero, and the combined real generated-worker/browser probe passes
the new teardown-silence assertion.

The disposable registration receives exactly one initial snapshot. After its
ordinary unsubscribe call, a public snapshot request resolves as the ordering
barrier and neither established listener's history advances. The reference
needed no change. No historical solver replay, false-positive mutant, or
accepted-variation suite was run at operator direction. Version 35 therefore
remains audit-pending, non-immutable, **0/10**, and not submission-ready.

Current version-35 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `64fb33e42127a9511bd727e27efb48ed91fbe7ffdc279dbbf3746b372cc17b0c` |
| `test.patch` | `4d2871c1b75c372703bdaccf88cbe1428ddfcbd1ed40d86b1404a54f9659491a` |
| `solution.patch` | `a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `5bcd7606ef3451602bb26d961dae2b615a5df3a56cfeb2d214047f94a81d50e4` |
| `verify/gates.sh` | `5a5171c16f25014c9000d4938f42ba9984dfd0eae653243bcf2b7b82ea5e30d9` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `849264bf7cf09bc24c56836853e11515d1a6268149400774c57b66be56af11cb` |

## Version-36 subscription-order and cross-source teardown design gate

This gate was completed before changing `test.patch`. `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, the complete version-35 record, the five supplied
`agent-runs11` evaluations, every run-11 solution patch, and representative raw
trajectories were reviewed. Run 5 is the legitimate pass. Runs 2 and 4 are
near-solutions whose independent failures are unchanged connection-status
notifications and missing pushed acknowledgement delivery; run 1 is the broad
failure with an unsupported `u128` Wasm ABI. The submitted panel report also
describes a buffered facade architecture that is not present in those five
run-11 patches. Repository history identifies the exact demonstrated
implementation as run 10/1: it registers an uninitialized facade entry, obtains
the initial state with a separate request, buffers globally broadcast states,
then replays the entire buffer after the current snapshot. Its solution and
trajectory hashes are recorded below.

Both reported gaps are valid and participant-facing. First, unsubscribe is
unconditional, while version 35 proves post-removal silence only for a local
mutation. Local timeline changes, coordinator range acknowledgements, and
storage application/rebase are independent notification sources in the real
worker. A split registry or source-specific removal can therefore pass the
local check while retaining a removed handler for received or applied changes.
Version 36 will retain the removed listener's count through real subsequent
acknowledgement transitions, and will remove a listener immediately before a
real coordinator application while a peer remains active. Public snapshot and
active-listener delivery provide completion barriers; no settling sleep is
used for the negative assertions.

Second, the initial subscription snapshot is an ordering boundary, not merely
an eventual-value requirement. A new handler must first see the current
snapshot and may then see changes observed later. Replaying an older state after
that snapshot reverses public progress and violates that contract. The oracle
will exercise a zero-to-one registration using the real generated worker while
the test Worker scheduler holds the next pre-existing outer `Doc` request.
Two real mutations advance the document while registration is in flight, after
which the held request is released. A conforming implementation delivers one
current initial snapshot; a facade that buffered older global events and
unconditionally replays them delivers an extra regressing snapshot. The probe
does not inspect the inner request tag, reply tag, wrapper field, subscription
identifier, or registry layout. Holding an outer Worker request is ordinary
concurrency scheduling already under the browser harness's control.

### Version-36 discriminator ledger

| Trajectory/repository evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The review notes that version 35 checks a removed primary only through a later local mutation. Worker implementations independently emit local, coordinator-received, and storage-applied changes. | A returned unsubscribe function prevents every later delivery to that registration, regardless of which public progress field changed. | Preserve the removed primary's count through real upper-half coordinator acknowledgements; in the applied flow remove a peer before coordinator application, wait for the active peer and public snapshot to observe applied progress, then require the removed count to remain fixed. | Coordinator and storage event sources, separate from the already-covered local source | Uses only the public unsubscribe function and real observable state transitions. It accepts unified or split registries and imposes no private teardown acknowledgement or timing rule. |
| Panel evidence reproduces callbacks `2,1` for run 10/1's `initialized/pending` facade, while the reference returns only `2`. The prompt requires the current snapshot before later observed changes. | Initial delivery cannot be followed by a superseded older snapshot that was observed during registration. | With no existing listener, hold the next outer document request, begin subscription, perform two real mutations, release registration, and require the first/only registration-time callback to equal the newest public receipt watermark. | Registration linearization and monotonic delivery order, separate from ordinary teardown and steady-state fan-out | Controls only Worker scheduling and compares public callback values. It does not require the reference's atomic worker request; repaired buffering, versioned snapshots, per-port routing, and other linearizable designs pass. |

Rejected alternatives include naming `SyncStateSubscribe`, asserting a private
reply shape, requiring JavaScript object identity, imposing a particular
monotonicity algorithm, or using a fixed delay to prove callback absence. The
ordering probe will be retained only if the current reference passes and the
specific panel-identified run-10/1 implementation fails for the stale replay.
Version 35 is abandoned before calibration; version 36 starts at **0/10**.
Per operator direction, no false-positive mutant suite or accepted-variation
suite will run, so this revision remains audit-pending and cannot be called
submission-ready.

Trajectory evidence identifiers:

| Evidence | Solution / trajectory SHA-256 |
|---|---|
| Run-11/5 legitimate pass | `e124987ad56fd78f6c042a8b50f3afba80e88cc8a4a098990bb791687dff6ae1` / `dc64ef89a83920d75657f206da56184efd656aeb94640228e58c74f52bc6a321` |
| Run-11/2 near-solution | `8949b33021bb38a0a51fab7a969ce682b6adcb5ade91dd87566fcd06fca6586d` / `259f390131a93e6f19806a6f78452d11f31d82e25e94cbd25a455a7b5c0727d5` |
| Run-11/4 near-solution | `cbc38e2804a711c446777f07c58e709fc18f4d0968099d13aa9c381362d97055` / `3fa8cf7866d2a4cdb591993e0af5afb61c060335b78a3653cd061150db82c010` |
| Run-10/1 stale-buffer survivor identified by panel | `9eae1202c7ee557fa6988ed26b381f2c2788992b7f822015f81279f1767fd905` / `e29cf0bd2a340459637e9dca6b567e6f4106421ff159c5b30c89c0682c3b5b71` |

### Version-36 verification record

The static artifact audit passes against the standalone pinned source copied
from the frozen image. The exact eight-state offline matrix passes at
`/tmp/sqlsync-gates.uMYxUv`: pristine, tests-only base, tests-only base with
stock tools, expected tests-only new rejection, solution-only
lint/regressions/package, combined new, required missing-browser-tools
rejection, and combined base. Every gate-level status file contains zero. The
combined reference browser lane delivers exactly one current initial snapshot
after the held zero-to-one registration and remains silent for removed
listeners through later received and applied transitions.

The panel-identified buffered facade was replayed from run 10/1 at
`/tmp/sqlsync-v36-buffered-replay.aUGX7n/run.log`. It reaches the new
registration oracle and fails with `initial subscription replayed a superseded
registration-time snapshot`; the same replay's four focused Rust integration
tests pass. This isolates the reported public-ordering failure rather than an
earlier unrelated defect. The reference's focused construction log is
`/tmp/sqlsync-v36-reference.fOgHBW/run.log` and contains a passing browser
probe plus four passing Rust integration tests.

No prompt or reference implementation change was needed. No fresh solver
calibration, false-positive mutant suite, or accepted-variation suite was run
at operator direction. Version 36 therefore remains audit-pending,
non-submission-ready, and **0/10**; historical runs are design evidence only.

Current version-36 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `64fb33e42127a9511bd727e27efb48ed91fbe7ffdc279dbbf3746b372cc17b0c` |
| `test.patch` | `3da90546d89644f7f0ce1eb2fbbe8c398391ca2961b99d1227b6cd968b1a2955` |
| `solution.patch` | `a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `853159542caec9bf2392504a469479bf9418b7bb275c8e08bf04910a2d96ab40` |
| `verify/gates.sh` | `5a5171c16f25014c9000d4938f42ba9984dfd0eae653243bcf2b7b82ea5e30d9` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `98b6e0d4e9d7b28942937c25cf62881fcf93a8d0a6fd278148f7bf07425bb395` |

## Version-37 description and framework-runtime design gate

This gate was completed before changing `meta.md` or `test.patch`.
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the complete version-36 record,
the SQLSync problem/candidate indexes, run histories 9-11, all available hook
hunks, and representative raw run-11 trajectories were reviewed. Run 11/5 is
the legitimate pass, run 11/2 is the near-solution with an unrelated repeated
connection-status notification, and run 11/1 is the broad failure with an
unsupported `u128` Wasm ABI. Their solution and trajectory hashes are already
recorded in the version-36 gate.

The prose review is valid. The participant contract has accumulated precise
cross-layer boundaries, but seven long paragraphs make unrelated Rust,
replication, browser, subscription, and framework obligations difficult to
locate. Version 37 will retain every behavioral requirement while grouping the
same content under short descriptive headings. This is a presentation repair,
not a new requirement or discriminator.

The hook-runtime review is also valid, with limited expected calibration
impact. The current TypeScript consumer proves only the declared return type.
A hook can `await` `SQLSync.mutate`, discard its result, and use an assertion or
overbroad annotation to preserve `Promise<MutationReceipt>`. The existing React
and Solid source closures already return the underlying call, and every
solution patch across run histories 9-11 changes only the `MutateFn` type alias;
none of the reviewed solvers exhibits the bad runtime behavior. The gap is
therefore repository-supported and plausible, but not trajectory-recurring.

The runtime oracle will load the built public React and Solid packages with
minimal deterministic adapters for their context/callback primitives, inject a
fake SQLSync whose `mutate` records its call and resolves to a distinct receipt,
invoke each public mutation hook, and compare the resolved structured value
with the underlying receipt. It also verifies one underlying call with the
supplied document, document type, and mutation. Structural equality is used:
cloning an equivalent public receipt remains accepted, avoiding the previously
rejected JavaScript reference-identity constraint. The adapter replaces only
external framework and worker modules and executes each package's actual built
hook implementation.

### Version-37 discriminator ledger

| Evidence | Fair public invariant | Black-box oracle | Distinct boundary | Anti-overfit rationale |
|---|---|---|---|---|
| The public description is dense despite its requirements being individually relevant. | Participants can locate Rust, progress, classification, worker, subscription, and hook requirements without reconstructing topic boundaries from long paragraphs. | Preserve the exact contract while reorganizing it into concise titled sections. | Description usability, not behavioral discrimination | No requirement, field, variant, representation, or hidden-test detail is added. |
| Runtime closures in the pinned React and Solid packages delegate to `SQLSync.mutate`; type tests alone cannot detect awaiting and discarding that value. Historical solutions update only the alias because the runtime forwarding path already exists. | Each framework hook resolves to the structured receipt produced by its underlying mutation call. | Execute both built hook closures with distinct fake SQLSync receipts and require one correctly-parameterized call plus a structurally equal resolved value. | Framework runtime propagation, separate from worker facade behavior and compile-time hook typing | Uses public package exports, accepts cloned equivalent values, and does not require React/Solid renderer internals, receipt identity, or a private SQLSync protocol. |

Rejected alternatives include source-text matching, requiring receipt object
identity, installing a browser DOM/test renderer, or asserting framework
implementation internals. Version 36 is abandoned before calibration; version
37 restarts at **0/10**. Per operator direction, no false-positive mutant suite
or accepted-variation suite will run, so the revision remains audit-pending and
cannot be called submission-ready.

### Version-37 verification record

The public description is now 468 words organized under Rust API, progress
semantics, receipt classification, worker/browser API, sync-state subscription,
and framework-hook headings. The static artifact audit passes against the
pinned source. The exact eight-state offline matrix passes at
`/tmp/sqlsync-gates.jy2dLy`: pristine, tests-only base, tests-only base with
stock tools, expected tests-only new rejection, solution-only
lint/regressions/package, combined new, required missing-browser-tools
rejection, and combined base. Every gate-level status is zero.

The combined report contains `HOOK_RUNTIME_PROBE` with distinct React and Solid
receipt values as well as the existing real-worker `BROWSER_PROBE`. The runtime
test uses Node's registered-loader API without an experimental-loader warning,
executes the built framework bundles, and compares structured values rather
than object identity. The focused reference construction also passes at
`/tmp/sqlsync-v37-reference.qeXhXW/run.log`; that earlier construction used the
equivalent loader directly and was superseded by the warning-free complete
matrix.

No reference production change was required because both pinned hook closures
already return the underlying mutation promise. No historical solution replay,
fresh solver calibration, false-positive mutant suite, or accepted-variation
suite was run at operator direction. Version 37 remains audit-pending,
non-submission-ready, and **0/10**.

Current version-37 identifiers:

| Artifact | SHA-256 / identifier |
|---|---|
| Source commit | `7dc1af6b082023982fd2697f913f5b27453747f1` |
| Reused amd64 image | `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3` |
| `meta.md` | `70aa414159f1f0a905168b9d29b66b194c5c01988a6fcf2cd76ed04d58c655d8` |
| `test.patch` | `4d54b57df88ef10ff276a53d965295f3aa049221c9663259a7fdda72456e930a` |
| `solution.patch` | `a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c` |
| `Dockerfile` | `fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc` |
| `verify/audit.sh` | `43e2194e0b93fbe418186cd3c4c83edc70d5c2214ee953c66dfb891815fb0362` |
| `verify/gates.sh` | `1579e81be16518095a5999435002c51261c6481b15758a986c3d22033fdf5b56` |
| `verify/mutations.sh` | `c2935fd77d061c868cf92d456635ce8ff7a7e676455cd8964435689d18dd5c1c` |
| `verify/README.md` | `94004653dc94c295e062bbd514c165976e29fe7a007b053ebdf9c174e774e1fc` |

## Acceptance and archival record

The user confirmed external acceptance of canonical version 37 on 2026-08-07.
This outcome does not alter the exact pre-acceptance evidence: the static audit
and eight-state offline matrix passed at `/tmp/sqlsync-gates.jy2dLy`, while no
fresh version-37 solver batch, false-positive mutant suite, or accepted-
variation suite was run at operator direction.

An acceptance-time repository screen found no fair bounded second SQLSync
problem. The strongest apparent candidate, table-scoped query invalidation from
issue #17, is already present at the pinned source through SQLite root-page
dependency tracking. The remaining open requests are either unresolved policy,
environment-heavy persistence, performance heuristics, or repository-scale
replication redesigns. The details are recorded in `UPSTREAM_AUDIT.md`.

All eleven trajectory batches were consolidated into
`archive/sqlsync-observed-sync-state/agent-runs.tar.gz` with SHA-256
`97dc07473750f49ebfa94ccf4d6cf5969cac57744d7b08bc90f463395fc4322f`.
Extraction and per-file hashing matched all 616 non-metadata source files.
Transient `PLAN.md` and `handoff.md` were preserved in
`retired-authoring.tar.gz` with SHA-256
`7b8030853b47de33170d9f359b447b74c9721efbaff621490f2b21a6e9e5a8a7`.
The active directory retains the canonical package, compact evidence,
prototype, upstream audit, and reproducible verification scripts.
