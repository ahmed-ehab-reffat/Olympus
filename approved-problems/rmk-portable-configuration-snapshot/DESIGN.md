# DESIGN — RMK portable configuration snapshot

Status: **accepted and archived 2026-08-05; canonical version 56 Level 6**

Repository: `rmk-rs/rmk`

Pinned commit: `c94426a68779e61cecc4380e21e9079e0ef0c2ae`

Task type: host-protocol feature

## Trajectory-informed startup gate

The startup search covered `problems/README.md`, `candidates/CANDIDATES.md`,
all local `problems/`, `candidates/`, and `archive/` records for RMK, Rynk,
configuration snapshots, backup/restore, bulk paging, compatibility,
validation-before-effects, partial progress, replay, and transactions. No
prior RMK problem, RMK solver run, or RMK raw trajectory exists locally.

Relevant compact records inspected:

- `archive/calyx-cider-checkpoints/DESIGN.md`, where public replay behavior
  admitted multiple internal snapshot representations and rejected tests for
  private checkpoint state;
- `problems/railway-deployment-bundle/DESIGN.md`, `RUNS.md`, and `SUMMARY.md`,
  where snapshot work retained public compatibility/effect-ordering
  boundaries while private atomic-publication and syscall-shaped requirements
  were rejected; and
- the closed OpenPNM and TwelveMonkeys SGI records, which show respectively
  that a complete but sub-100-line feature is too small and that technically
  deep work still fails when an accepted external task already owns it.

Representative raw Railway trajectories were read from
`archive/railway-deployment-bundle/agent-runs.tar.gz`:

| Raw evidence | Result | Generalized design evidence |
|---|---|---|
| `agent-runs8/Nova_Nova_1/trajectory.json` and evaluation, 71 steps/65 tool calls | 26/28 | A broad snapshot implementation can still miss compatibility ordering and a canonical boundary despite extensive local validation. |
| `agent-runs8/Nova_Nova_3/trajectory.json` and evaluation, 72 steps/67 tool calls | 27/28 | Conflating validation-before-effects with permanent offline operation incorrectly suppresses legitimate post-preflight effects. |
| `agent-runs8/Nova_Nova_6/trajectory.json` and evaluation, 75 steps/70 tool calls | verifier assembly failure | Infrastructure failure is not behavioral evidence and is not counted as a broad solver failure. |

No representative broad behavioral failure was available in that inspected
batch. The evidence supports testing public preflight ordering and public
partial progress separately, accepting any internal aggregate representation,
and avoiding rollback, private firmware state, timing, or syscall requirements.

Repository evidence substituted for the absent RMK trajectories:

- `DeviceCapabilities` advertises every enumeration extent required here:
  layers, rows, columns, encoders, combo slots/key limits, Morse slots/pattern
  limits, fork slots, macro-space bytes, and macro chunk size.
- `Client` exposes matching reads and writes for the default layer, keymap,
  encoder matrix, combos, forks, Morse definitions, flat macro region, and
  global behavior configuration.
- The native client already owns safe whole-resource keymap/combo/Morse
  pagers; its public docs prohibit overlapping one of those reads with a bulk
  write. Export and restore can therefore be phase-separated without adding
  a private scheduling rule.
- `DeviceInfo` distinguishes keyboard models and serial units. Portability
  across two units of one model compares USB vendor/product and product name,
  while deliberately ignoring manufacturer label, serial number, and firmware
  version.
- Postcard and serde are existing dependencies, so a deterministic versioned
  binary record needs no new serialization stack.

## Renewed ownership and similarity audit

The exact pin was the upstream `main` head when selected. A fresh check on
2026-08-01 found upstream `main` at
`8701b684b2c77af485eabc68645265b9b21c735e`, one later BLE-only commit. The
latest issue/PR searches for snapshot, backup, restore, configuration export,
configuration import, and saved profiles found no owned snapshot task.

Open PR #1013, “Fix squeezed read pages, drain cancelled wasm writes,” is an
adjacent correctness change after the pin. It fixes concurrent pager/write
behavior and cancelled WASM sends, but does not propose configuration
snapshotting. This problem neither asks participants to reproduce that PR nor
permits the documented unsafe pager/write overlap. Local all-ref history and
tree searches found no snapshot implementation. General web similarity
searches found ordinary keyboard backup/import tools but no accepted RMK/Rynk
task or matching host-protocol contract.

## Frozen public behavior

The host crate will expose a version-1 `ConfigurationSnapshot` with explicit
model identity, structural geometry, default layer, keymap, encoder matrix,
combos, forks, Morse definitions, exact macro bytes, and behavior settings.
Equivalent values must serialize to canonical deterministic bytes; decoding
rejects malformed/trailing records and unknown versions.

Restore performs complete structural and target compatibility preflight before
its first mutation. Transport/page limits, manufacturer labels, serial numbers,
and firmware versions are intentionally not compatibility keys. After
preflight it reads and validates a complete target baseline, then applies only
different keymap, encoder, combo, fork, and Morse entries and different macro
chunks. Dirty stages retain the keymap-to-default-layer order. A runtime
failure reports the failed stage and all fully completed earlier dirty stages;
a retry refreshes the baseline and skips changes already applied. Native and
WASM callers use the same byte format and semantic operation.

## Discriminator ledger

| Plausible shortcut | Public invariant | Planned behavioral oracle | Independent boundary | Fairness rationale |
|---|---|---|---|---|
| Serialize only the three existing `read_all_*` resources | Every mutable host-visible family is captured | Give each family a distinct value, export, then restore through typed public requests | Resource enumeration | Any aggregate type and helper architecture can pass |
| Omit forks or default layer | Snapshot covers the complete current mutable surface | Require exact fork reads/writes and set the default layer only after all backing data | Newly found repository families | Both are public getter/setter pairs, not padding |
| Hard-code macro or encoder extents | Enumeration follows advertised capabilities | Exercise nontrivial layer/encoder and macro-space/chunk geometries against a stateful protocol peer, then inspect exported and restored state | Address-space discovery | Rejects fixture constants without requiring one bulk-page schedule or final macro frame shape |
| Trust vector lengths or validate while writing | Malformed/incompatible snapshots send no mutation | Put the defect in a late family and record every post-handshake request, allowing an optional identity read but rejecting every mutation | Validation/effect ordering | Local-first, identity-first, two-pass, typed, and staged implementations pass |
| Pin serial number, firmware patch, or transport limits | Snapshot is portable across units of the same compatible model | Change ignored identity/transport fields independently while preserving configuration geometry | Portability compatibility | Required comparison fields are public and explicit |
| Ignore device-specific combo/Morse limits | All record shape is validated before writes | Exceed one advertised per-entry limit inside otherwise correct lengths | Nested structural validation | Tests public capacity fields, not internal validators |
| Serialize `LinearMap` insertion order | Equivalent snapshots have canonical bytes | Build equal Morse maps in opposite insertion orders and compare bytes | Canonical persistence | Any canonical encoding can pass |
| Write families in arbitrary/concurrent order | Restore has a documented durability boundary | Observe ordered resource phases and default layer last while allowing any valid paging within a bulk family | Partial-failure semantics | No private helper page boundaries, timing, or packing choices are observed |
| Return only the underlying transport error | Failure reports deterministic progress | Reject one write and inspect completed/failed stages; then prove no later write occurred | Recovery observability | Does not demand rollback or atomicity |
| Implement native only or return unrelated bytes from WASM | Native and browser callers share one snapshot model | Run both WASM byte methods through a scripted JavaScript byte link, decode the export with the native API, restore it, and exhaust the expected replies | Binding integration | The oracle observes public bytes and requests, not private pump helpers |

## Version 3 feedback-driven redesign gate

The version-3 review resumed hidden-test design only after rereading `PROBLEM_DESIGN.md` and this recorded trajectory gate. No RMK solver trajectory exists, and no cold solver has been launched. The same repository and Railway trajectory evidence therefore remains the applicable basis; no unrelated run is being substituted.

The review found a fairness defect rather than a missing discriminator: several tests matched private `SnapshotError` variant names and `field` labels even though the public task required only rejection. Version 3 will preserve the behavioral probes while changing those assertions to accept any error, except for `RestoreError::Preflight` and `RestoreError::Write`, whose public progress/no-mutation distinction is explicitly part of the interface. The prompt will state every public snapshot field and restore-stage variant that tests construct or compare. Tests will no longer require `SnapshotGeometry: From<DeviceCapabilities>`.

One repository-grounded capability boundary was described but not directly exercised: `bulk_transfer_supported == false`. Version 3 adds a no-write preflight probe for it. The proposed dimension-overflow requirement is removed because the persisted geometry uses bounded `u8` and `u16` fields whose products cannot overflow `usize` on the supported native and WASM targets; inventing a probe would require changing the public model solely for a synthetic case. WASM remains a compile-time public surface check because exercising JavaScript error objects would require a browser/runtime harness and adds no distinct native snapshot discriminator.

The predictable ignored `rynk/Cargo.lock` artifact is replaced by a randomly named lock seed copied into Cargo's mandated location by the Dockerfile and runner. The compile-only WASM test file is also randomized. These are harness isolation changes, not participant behavior.

## Version 4 feedback-driven redesign gate

Before revising the version-4 hidden tests, the design protocol and the existing RMK gate above were reread. There are still no RMK solver trajectories, and no cold solver has been run. The repository-backed resource-order, public-interface, and browser-binding evidence remains the applicable basis.

The combined scripted test already requires export reads in the order DeviceInfo, DefaultLayer, Keymap, Encoders, Combos, Forks, Morses, Macros, then Behavior. Version 4 makes that order participant-facing so the black-box transcript is no longer an unstated reference choice. The randomized `rynk-wasm` test imports `SNAPSHOT_VERSION` and `SnapshotRead` through the public `rynk` dependency boundary, checks that the constant is exactly 1, and uses the type without assuming any variants or payloads.

The prior compile-only WASM check left a genuine integration boundary uncovered. The repository's browser transport accepts a JavaScript-owned byte link, and the accepted Rust base image includes Node. Version 4 therefore replaces the surface-only probe with a `wasm-bindgen-test` that connects through a scripted JavaScript link, exports bytes through `RynkClient`, decodes and re-encodes them through the native snapshot API, restores the same bytes, and exhausts command-specific replies. This observes the public binding and wire behavior without requiring one private Rust helper architecture or a browser device.

The Dockerfile base reference is also moved from an unaccepted digest form to the accepted `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` image. These prompt, test, dependency-lock, runner, and environment changes create immutable version 4, invalidate the version-3 audit, and keep calibration at 0/10.

## Version 5 environment-feedback redesign gate

Before changing the description, runner, or Dockerfile, `PROBLEM_DESIGN.md` and the complete RMK design record were reread. The local search covered prior problem, candidate, and archive records for architecture-qualified Rust toolchains, accepted Rust base images, apt package pinning, `libdbus-1-dev`, and `pkg-config`. There are still no RMK solver trajectories or patches to replay, and no cold solver has been run. This revision changes environment portability and removes redundant prose; it does not add or alter a behavioral discriminator.

Both published architectures of `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` were inspected directly. The amd64 image supplies the active default `1.95.0-x86_64-unknown-linux-gnu` toolchain, while the arm64 image supplies `1.95.0-aarch64-unknown-linux-gnu`. Both already include `pkg-config` 1.8.1-1, and both expose `libdbus-1-dev` version `1.14.10-1~deb12u1` from their Debian bookworm repositories. The version-4 architecture-qualified environment forced the arm64 binary under amd64 and reproduced the review's loader failure. Version 5 therefore uses the architecture-neutral rustup name `1.95.0`, removes the redundant `pkg-config` install, and pins the remaining dbus development package exactly.

The opening description sentence duplicated the authoritative `ConfigurationSnapshot` field list and ordered operation lists. Version 5 removes that enumeration without changing the public contract. Because `meta.md`, `test.patch`'s runner, and the Dockerfile change, version 4 is invalidated, the false-positive gate must be repeated for the exact version-5 artifacts, and calibration remains 0/10.

## Version 6 build-order redesign gate

Before revising the environment or harness, `PROBLEM_DESIGN.md` and the complete RMK design record were reread. Local problem, candidate, and archive records were searched for fresh-clone Docker builds, post-build test-patch injection, uncommitted Cargo locks, dependency warming, and offline runners. There are still no RMK solver trajectories or patches to replay, and no cold solver has been run. This is an environment-order correction and does not add, remove, or alter a behavioral discriminator.

The pinned checkout tracks `rynk/Cargo.toml` and `rynk/rynk-wasm/Cargo.toml` but no `rynk/Cargo.lock` and no randomized lock seed. The grading sequence builds the image from that checkout and injects `test.patch` afterward, so version 5's build-time reference to `rynk/.olympus_7f3c91/Cargo.lock` cannot exist and is invalid even though author-time combined contexts happened to include it.

Version 6 will generate `rynk/Cargo.lock` during the networked Docker build. Before the offline runtime, the build will resolve the exact `wasm-bindgen-test` version used by the hidden WASM lane into that lock and Cargo cache, while restoring the participant-facing manifest to its pristine contents. The test patch will no longer carry or copy any lock file; after injection, its dependency declaration will match the pre-resolved lock. Validation must reproduce the platform order exactly: clean pinned checkout build first, then test-only or combined patch injection into containers with networking disabled.

Because the Dockerfile, runner, and `test.patch` change, immutable version 5 and its false-positive audit are invalidated. Version 6 starts again at calibration 0/10 and must repeat the exact-version false-positive gate before it can be called locally verified.

## Version 7 wrapper and fairness redesign gate

Before revising the runner or tests, `PROBLEM_DESIGN.md` and this complete design record were reread. Local problem, candidate, archive, and raw archived records were searched for wrapper entity classification, compile-failure JUnit placeholders, pass-to-pass/fail-to-pass censuses, optional preflight reads, cached capability checks, and no-mutation oracles. The Calamine record provides a validated skipped-placeholder pattern, while the Moov ACH record explains why a synthetic compile-failure entity that disappears after the solution is unclassifiable. There are still no RMK solver trajectories or patches to replay, and no cold solver has been run.

The platform wrapper found one unclassified `new.compile-or-run` failure. It is a harness entity, not a participant behavior: the test-only tree cannot compile the deliberately absent snapshot API, while the combined tree emits the real native test identities. Version 7 reports that no-JUnit fallback as one skipped compilation placeholder while preserving the nonzero process status. This leaves the 83 stable regression identities and the real fail-to-pass snapshot identities to the wrapper.

The fairness review also found that four rejection tests required `GetDeviceInfo` to consume sequence 3 even when malformed snapshot data or cached capabilities already prove rejection. The public contract orders all preflight work before mutation but does not order the non-mutating checks among themselves. Version 7 uses the existing recording transport for those cases. It accepts either no post-handshake request or exactly the optional identity read, and still fails on every mutating request, hang, wrong error class, or successful restore. The identity-mismatch tests continue to require identity I/O because that input cannot be checked locally.

Finally, the reported root `cargo build` failure is expected repository structure because the pin has no top-level manifest. The standalone `rmk/Cargo.toml --no-default-features --offline` failure was a real cache-coverage gap: `display-interface` is outside the graph warmed by the Rynk workspace build. Version 7 fetches and builds that manifest during the networked image build, and the relevant standalone command now works offline on both architectures. It does not invent a top-level workspace. These runner, hidden-test, and environment changes invalidated version 6 and kept the public prompt and reference behavior unchanged.

## Version 8 paging-fairness and cache redesign gate

Before revising the description, tests, or Dockerfile, `PROBLEM_DESIGN.md` and this complete design record were reread. Local problem, candidate, archive, and raw-trajectory locations were searched for RMK/Rynk runs, exact protocol transcripts, bulk paging, helper scheduling, final-chunk padding, stateful protocol fakes, and implementation-detail findings. No RMK solver trajectory or patch exists to inspect or replay, and no cold solver has been run. The existing Railway trajectory evidence remains relevant only at the generalized snapshot/commit boundary; repository evidence governs this protocol-specific correction.

The review identified a genuine hidden-test fairness defect. Public `get_keymap_bulk` accepts any valid start position, while `read_all_keymap` privately derives overlapping concurrent offsets from `MAX_IN_FLIGHT`, frame size, and `PARKED_REQUEST_BYTES`. Public `set_keymap_bulk` likewise accepts ordered pages, while `write_all_keymap` privately packs items by serialized payload size. The version-7 extent test required the exact overlapping reads and one packed write chosen by those helpers. It also required the last macro write to contain only the two in-range bytes even though a three-byte advertised chunk with one padded byte has the same observable device result when the firmware truncates at `macro_space_size`.

Version 8 replaces that frame-vector oracle with a stateful protocol peer. It responds to valid keymap page starts, applies any gap-free ordered bulk write split, truncates macro writes at the advertised region, and records normalized resource phases. The test will assert exported values, layer-major encoder addresses, exact macro read coverage at offsets 0 and 3, final restored keymap/encoder/macro/behavior/default-layer state, resource-family order, and no out-of-range or oversized macro request. It will not assert the number of keymap pages, their overlap, payload packing, sequence numbers, or whether the final macro request is short or padded. This preserves the independent enumeration and restore-order discriminators while admitting alternative correct paging implementations.

The opener's early `rynk-wasm` mention is redundant with the final binding paragraph and will be removed without changing behavior. The reported root `cargo build` remains inapplicable because the repository has no top-level manifest. The separate `rmk-macro/Cargo.toml` failure was reproduced in the network-disabled version-7 image: Cargo could not resolve the dev dependency `macrotest`. Version 8 will fetch and build that manifest during the networked image build so its ordinary offline build works after image construction.

These prompt, hidden-test, and environment changes invalidate immutable version 7 and its false-positive audit. Version 8 remains at calibration 0/10 and must repeat fresh architecture builds, all patch states, legitimate paging variants, and the exact-version false-positive audit before it can again be called locally verified.

That exact-version gate is now complete. Fresh arm64 and amd64 images built
from the pin, then passed offline standalone `rmk` and `rmk-macro` builds.
Combined injection passed 83 base tests, 15 native snapshot tests, and the
runtime WASM test on both architectures. Test-only and solution-only states
behaved as required. A sequential non-overlapping keymap implementation and a
padded final macro-chunk implementation both pass the revised stateful oracle.
All 18 repository-grounded mutants were rerun; the former frame-shape mutant
was rejected as artificial and replaced by an incomplete-keymap mutant that
the final-state check catches. No mutant survived the focused gate.

## Version 9 key-address validity redesign gate

Before revising the hidden test again, `PROBLEM_DESIGN.md`, the complete design
record, and the worked false-positive reference were reread. The same local
history and raw-trajectory searches remain applicable: there is still no RMK
solver trajectory or patch, and no solver has been run. Repository protocol
evidence exposes a distinct public boundary that the first stateful peer did
not model correctly. `GetKeymapBulkRequest` names layer, row, and column as
separate bounded coordinates; flattening an invalid row happened to alias the
next layer in the peer's arithmetic.

A plausible manual pager could therefore encode flat cursor 1 as
`(layer=0,row=1,col=0)` on a two-layer, one-row, one-column device, export and
restore the expected values through the alias, and pass version 8 despite
violating the stated layer/row/column order. Version 9 adds component-wise
bounds checks before flattening keymap read or write starts. It still accepts
any valid page count, overlap, or payload split. This is a new address-space
discriminator, not a private helper schedule. A wrong-coordinate mutant must
be prototyped, and the complete exact-version audit must restart from zero.

Version 9's first wrong-coordinate prototype survived. The stateful device
advertised a two-key page for a two-key map, so export completed from the first
valid `(0, 0, 0)` request and never exercised the next layer's address. The
component bounds added to the peer were sound, but unreachable for that
geometry and paging limit. Version 9 is therefore invalidated before its final
audit was claimed.

## Version 10 keymap-page boundary redesign gate

Before changing the hidden test, `PROBLEM_DESIGN.md`, this complete design
record, the false-positive audit protocol, and the repository keymap pager and
firmware handlers were reread. The prior local history and trajectory searches
remain applicable: no RMK solver trajectory or patch exists, and no solver has
been run. The new evidence is the concrete version-9 survivor above plus the
repository contract in `rynk/src/api.rs` and
`rmk/src/host/rynk/handlers/keymap.rs`: bulk starts are separately bounded
layer/row/column coordinates, and a response page can end before the complete
keymap.

Version 10 changes only the stateful extent fixture's advertised
`max_bulk_keys` from two to one. A correct implementation must then continue at
the second key, encoded as `(layer=1, row=0, col=0)` for this two-layer,
one-row, one-column geometry. The oracle still accepts sequential or concurrent
reads, overlap where valid, and any gap-free write packing; it does not assert
sequence numbers or a private helper schedule. This makes the existing public
layer/row/column-order discriminator reachable and should reject the observed
`(0, 1, 0)` mutant. The mutant and both legitimate paging variants must be
replayed before freezing version 10, followed by the complete exact-version
false-positive audit and patch-state matrix.

That exact-version gate is now complete. The wrong-coordinate mutant fails at
the row bound, while the sequential non-overlapping keymap pager and padded
final macro writer both pass. Combined injection passed 83 base tests, 15
native snapshot tests, and one runtime WASM test on arm64 and amd64. Test-only
injection passed all 83 base tests and produced only the skipped compilation
placeholder for its expected missing API; solution-only passed 83 workspace
tests, one doctest, and the WASM target check after regenerating its lock from
the warmed cache offline. Standalone RMK and `rmk-macro` builds also passed
offline on both architectures. All 19 exact-version mutants were caught, so no
survivor qualified for complete-suite replay.

## Version 11 restore-encoder ordering redesign gate

Before revising the hidden test, `PROBLEM_DESIGN.md`, the complete local RMK
design history, the worked false-positive reference, and the Rynk encoder API
and firmware handler were reread. Searches across active problem records,
candidate history, archive manifests, raw-trajectory locations, and the RMK
audit workspace again found no RMK solver trajectory or patch to inspect. No
solver has been run. Repository and review evidence therefore remain the basis
for this fairness correction.

The public prompt requires exported encoder values to use layer-major then
encoder-ID-major order, and restore resource families to occur in the stated
order. It does not require the individual `SetEncoderAction` requests inside
the Encoders stage to use that same order. The public `set_encoder` API and the
firmware handler accept any independently bounded `(encoder_id, layer)` pair;
there is no ordering dependency between encoder slots. A correct restore may
therefore traverse encoder IDs first while mapping each layer-major snapshot
element to its proper address.

Version 10's stateful peer already checks the final encoder state and keeps all
encoder writes inside the Encoders resource phase. Its separate equality
assertion on the write transcript adds only a private iteration-order
requirement. Version 11 removes that assertion while preserving the exported
encoder vector order, final restored state, address bounds, resource-family
order, and failure-stage semantics. A legitimate encoder-ID-major restore must
be prototyped and pass. The previous M9 mutation is rejected as artificial
because it changed iteration order without correcting the snapshot index; it
will be replaced by a genuinely incomplete-encoder restore mutant that must
still fail through final state. The full patch-state matrix and exact-version
false-positive audit restart from zero.

The reported wrapper identity
`snapshot_uses_advertised_encoder_and_macro_extents_with_exact_requests` is
from a superseded version-3 result. The current test has been named
`snapshot_uses_advertised_encoder_and_macro_extents` since version 8, and the
participant artifact does not include an `after_solution_xml` file. Version 11
will regenerate wrapper XML from the current test-only and combined artifacts
so stale result data cannot be mistaken for the immutable package.

That exact-version gate is now complete. A correct encoder-ID-major restore,
the sequential non-overlapping keymap pager, and the padded final macro writer
all pass. Combined injection passed 83 base tests, 15 native snapshot tests,
and one runtime WASM test on arm64 and amd64. Test-only injection passed all 83
base tests and produced only the skipped compilation placeholder; solution-only
passed 83 workspace tests, one doctest, and the WASM target check from the
warmed cache offline. Standalone RMK and `rmk-macro` builds passed offline on
both architectures. The replacement incomplete-encoder M9 and all other 18
mutation trials were caught. Fresh combined XML names only
`snapshot_uses_advertised_encoder_and_macro_extents`.

## Version 12 reference-quality redesign gate

Before changing the reference artifact, `PROBLEM_DESIGN.md`, the complete RMK
design history, and the same repository and trajectory search results were
reviewed again. No RMK solver trajectory or patch exists, and no solver has
been run. This revision changes neither the public prompt nor any hidden-test
discriminator; it addresses two maintainability findings in the reference
implementation.

The WASM client currently duplicates the complete driver-lock election in
`drive` and `drive_snapshot` solely to map two future error types. Version 12
will extract that election into one generic internal helper and keep the two
call-site wrappers as error-conversion adapters. This preserves the existing
public methods, driver-error mapping, snapshot JavaScript error name, and
runtime behavior.

The native snapshot module also labels the locally fetched capabilities as
`SnapshotRead::DeviceInfo` if that operation ever fails. Version 12 adds an
internal diagnostic `Capabilities` operation and uses it for the three
capability fetches while leaving actual identity reads labeled `DeviceInfo`.
`SnapshotRead` is public as required, but its variants and payloads are not a
participant-facing construction contract and no test assumes them.

Because `solution.patch` changes, immutable version 11 and its exact audit are
invalidated even though behavior and tests are unchanged. Version 12 must rerun
the full patch-state matrix, runtime WASM lane, legitimate variants, and all 19
false-positive mutants before it can be frozen.

That exact-version gate is now complete. Combined injection passed 83 base
tests, 15 native snapshot tests, and one runtime WASM test on arm64 and amd64.
Test-only injection passed all 83 base tests and produced only the skipped
compilation placeholder; solution-only passed 83 workspace tests, one doctest,
and the WASM target check from the warmed cache offline. Standalone RMK and
`rmk-macro` builds passed offline on both architectures. All three legitimate
implementation variants passed, and all 19 exact-version mutants were caught.

## Version 13 verifier and validation-coverage redesign gate

Before changing the prompt, tests, runner, or image, `PROBLEM_DESIGN.md`, this
complete design history, `CALIBRATION_STRATEGY.md`, and the worked
`problems/statig-local-transitions/false_postive trials.md` audit were reread.
The history search was repeated across active problems, candidates, archives,
and the newly available `agent-runs1` directory for RMK/Rynk snapshots,
collection validation, identity compatibility, Cargo lock failures, and WASM
test bootstrapping.

Unlike the earlier revisions, four raw RMK runs now exist under
`problems/rmk-portable-configuration-snapshot/agent-runs1`. Their trajectories,
test logs, final evaluations, and solution patches were inspected rather than
using their synthetic zero scores as behavioral evidence:

| Raw evidence | Verifier result | Design evidence |
|---|---|---|
| `Nova_Nova_1` | Aborted in locked Cargo metadata before either suite | The substantial snapshot implementation validates every geometry-sized collection and compares VID, PID, and product name independently. |
| `Nova_Nova_2` | Same pre-test lock abort | Independently chose exact validation for all six collections and an OR compatibility predicate. |
| `Nova_Nova_3` | Same pre-test lock abort | Independently implemented the requested native/WASM feature and reported successful repository checks, but the submitted implementation was never exercised. |
| `Nova_Nova_4` | Same pre-test lock abort | Again produced a complete-looking multi-file solution with exact collection lengths and independent identity checks; the wrapper emitted synthetic failures only. |

These are infrastructure-invalid trajectories, not four broad solver failures
and not a calibration batch. They remain useful implementation evidence, but
none can be classified as a verifier pass, near miss, or behavioral failure.
Version 13 therefore remains at 0/10, and no new solver will be started without
the user's explicit request.

The common failure is reproducible from the artifact order. The Docker image
generates `rynk/Cargo.lock` while a temporary `wasm-bindgen-test` dev dependency
is present, restores the pristine manifest, and leaves that lock behind. The
hidden patch later mutates the same workspace manifest again. The platform's
node-id wrapper runs `cargo metadata --locked --offline` before the test script,
so the runner cannot repair a stale lock and no test identity is discovered.
Version 13 will leave the Rynk workspace manifests untouched. The image will
regenerate a lock matching the restored pristine manifest, and the runtime WASM
probe will move to a randomly named standalone test crate with its own committed
lock. This preserves offline execution after post-build test injection without
creating a predictable participant-file collision.

Two public validation boundaries were under-sampled even though all four
reviewed implementations happened to get them right. The existing length test
checked only an undersized keymap. Version 13 will exercise both undersized and
oversized keymaps, encoders, combos, forks, Morse definitions, and macro data.
The existing USB test changed both IDs together, allowing the plausible weaker
predicate that rejects only when both differ. Version 13 will isolate a
vendor-only mismatch and a product-only mismatch in separate sessions. These
probes directly cover explicit participant-facing requirements; they do not
assert error variants, error strings, helper choices, or preflight sub-check
order.

The public description's field contracts remain necessary, but their long
bullet-by-bullet presentation reads like generated API reference material.
Version 13 will group the same names and types compactly without adding or
removing behavior. This prompt change, the new validation cases, the relocated
WASM lane, and the corrected pristine lock invalidate immutable version 12 and
its audit. Before version 13 can be called locally verified, it must pass the
fresh-clone build and post-build injection order, both architectures, every
patch state, the runtime WASM lane, legitimate variants, representative
historical solution replays, and a new exact-artifact false-positive audit.

## Version 14 trajectory-replay fairness redesign gate

Version 13 reached the historical replay step but is invalidated before its
audit can be frozen. With the lock bootstrap repaired, `Nova_Nova_1`,
`Nova_Nova_2`, and `Nova_Nova_4` pass every regression, native snapshot, and
runtime WASM check. `Nova_Nova_3` passes 86 pre-existing and self-authored
tests, then exposes two hidden-test assumptions that are not public behavior.

First, that implementation enumerates keys, combos, and Morse definitions with
the public single-item getters rather than the existing whole-resource helper.
It still uses the advertised dimensions and required resource order, and its
restore uses the bulk writers after enforcing bulk support. The prompt requires
whole-resource bulk capability but never requires one command family for reads
or writes. Requiring `GetKeymapBulk` in the scripted peer is therefore the same
private-helper coupling rejected in the earlier paging review. Version 14 will
accept bounded single-item or bulk access for keymaps, combos, and Morse
definitions, normalize both into the same resource phase, and judge values,
coordinates, final state, and public family ordering.

Second, the replay exposes
`restore_configuration_snapshot(&self, bytes: &[u8])` while the hidden Rust
test calls the method with an owned `Vec<u8>`. Both compile to a byte-oriented
JavaScript method, and the public request does not specify an internal Rust
argument type. Version 14 will call the exported method through JavaScript with
a `Uint8Array`. That checks the actual WASM ABI and method name while admitting
any wasm-bindgen-compatible Rust signature.

These are fairness corrections, not new participant requirements. The full
stateful resource test, runtime binding probe, patch-state matrix, historical
replays, legitimate variants, and all false-positive mutants must restart on
the resulting exact artifacts. Calibration remains 0/10, and the four saved
runs remain trajectory evidence rather than a calibration batch.

## Version 15 partial-progress fairness redesign gate

Before revising the remaining scripted restore test, `PROBLEM_DESIGN.md`, the
complete design history above, the four saved trajectories, and the Rynk
single-item and bulk mutation APIs were reviewed again. The version-14 replay
accepted `Nova_Nova_3`'s single-item export and bulk restore, but a separate
legitimate variant that used bounded `SetKeyAction` writes failed only because
`restore_reports_completed_stages_and_stops_after_failure` returned a
hard-coded `SetKeymapBulk` response. The native stateful peer and runtime WASM
peer already accept either command family, and the firmware exposes both as
equivalent ways to address the same mutable resource.

The public contract requires complete resource writes, resource-family order,
whole-resource bulk capability at preflight, and accurate completed-stage
reporting. It does not require restore to call one private convenience helper.
Version 15 will therefore run the fork-failure progress probe through the same
bounded stateful peer used by the complete restore test, inject the rejection
at the first fork write, and assert the public completed ledger and absence of
all later resource phases. This admits single-item or bulk keymap, combo, and
Morse writes while preserving the distinct partial-progress discriminator.

This hidden-test change invalidates version 14 even though the prompt,
reference behavior, runner, and Dockerfile are unchanged. The exact patch-state
matrix, four historical replays, legitimate variants, and all 28
repository-grounded mutants must restart on version 15 before its false-positive
audit can be frozen. Calibration remains 0/10, and no cold solver is authorized.

That exact-version gate is complete. Combined injection passes 83 regressions,
15 native snapshot tests, and one runtime WASM test on arm64 and amd64.
Test-only injection passes all 83 regressions and emits only the skipped compile
placeholder for the expected absent API. Solution-only builds and tests the
workspace, WASM target, standalone RMK graph, and `rmk-macro` graph offline on
both architectures. All four saved implementations pass the repaired harness;
the three deliberately different legitimate variants pass; and all 28
exact-version mutants are caught. Artifact hashes and the full requirement map
are frozen in `FALSE_POSITIVE_AUDIT.md`.

## Version 16 locked-build and complete-tooling gate

Before changing the Dockerfile, `PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`,
the complete design history above, and the lock-generation precedents in the
Noodles and Gimli problem records were reread. The four saved RMK test logs
were checked again: all contain the same pre-test locked-metadata failure and
provide no contrary behavioral evidence for this environment-only revision.
The public prompt, hidden tests, reference implementation, and discriminator
ledger remain unchanged.

The pinned checkout contains no `Cargo.lock` in `rynk`, `rmk`, or `rmk-macro`.
The accepted local precedent is to generate each absent lock exactly once
during the networked image build, then require `--locked` on every later fetch,
build, metadata, check, and test command. Version 15 followed that pattern for
Rynk but allowed the standalone RMK and proc-macro fetch/build commands to
resolve implicitly. Version 16 will explicitly generate their locks and make
all four reported commands locked.

Rust 1.95 provides `cargo add` as a built-in command even though no separate
`cargo-add` executable is present in the base image, so the reported conditional
failure does not reproduce. Nevertheless, the temporary dependency-warming
step does not need a manifest-editing subcommand. Version 16 will append the two
exact development dependencies with the base shell, generate the temporary
Rynk lock, warm it, then restore the pristine manifest and regenerate its final
lock as before.

Repository inspection also confirms that `rmk-macro`'s `macrotest` development
test invokes `cargo expand`. The exact offline `_simulator` test path can compile
from the version-15 cache but cannot run without that subcommand. Version 16
will install `cargo-expand` 1.0.124 with `--locked`; that release declares Rust
1.88 and is compatible with the pinned Rust 1.95 toolchain. The exact command
`cargo test --manifest-path rmk-macro/Cargo.toml --features _simulator --locked
--offline` must pass in both final images.

Because `Dockerfile` changes, immutable version 15 and its false-positive audit
are invalidated. Version 16 must rebuild both architecture images from the exact
Dockerfile, repeat every patch state, run the newly reported proc-macro test,
replay the three legitimate implementation variants, four saved solutions, and
all 28 mutants, then freeze new artifact and lock hashes. Calibration remains
0/10, and no cold solver is authorized.

That exact-version gate is complete. Fresh arm64 and amd64 images built from
the pinned checkout, and every post-build Cargo command ran locked and offline.
The reported `_simulator` proc-macro test passes all 47 unit tests, its compile-
fail test, and all five macro-expansion fixtures on both architectures with
`cargo-expand` 1.0.124 available. Combined injection passes 83 regressions, 15
native snapshot tests, and one runtime WASM test; test-only and solution-only
states behave as required. All four saved implementations and all three
legitimate alternatives pass. All 28 mutants were rerun and caught, with no
survivor. Exact hashes and image identities are frozen in
`FALSE_POSITIVE_AUDIT.md`.

## Version 17 trajectory-informed hardening gate

Before revising the public contract, reference, or hidden tests,
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the complete local design
history, and the four new raw RMK trajectories under `agent-runs2` were read.
Their evaluations, submitted patches, test logs, and representative raw
agent/tool records were inspected. The user-supplied SQLsync `agent-runs2`
path was also resolved, but it is unrelated and was not substituted for RMK
evidence.

| Raw RMK evidence | Exact version-16 result | Hardening evidence |
|---|---|---|
| `agent-runs2/Nova_Nova_1` | Behavioral failure after 83 regressions and 15 native tests passed | The WASM restore panics on the explicitly valid empty-macro/zero-chunk case because it constructs `step_by(0)`. The existing runtime WASM probe already distinguishes this boundary. |
| `agent-runs2/Nova_Nova_2` | Legitimate full pass | It compares the complete `SnapshotGeometry` and rejects unknown versions in `validate`, but validates only combo trigger count and accepts an out-of-range `Combo.layer`. |
| `agent-runs2/Nova_Nova_3` | Legitimate full pass | It independently makes the same combo-layer omission while otherwise using full geometry equality and direct version validation. |
| `agent-runs2/Nova_Nova_4` | Legitimate full pass | It validates both combo trigger count and `Combo.layer`, compares full geometry, and rejects unknown in-memory versions. |

The 3/4 pass rate is treated as evidence that version 16 is
under-discriminating, not as a completed calibration batch. The trajectory
comparison exposes one actionable survivor family: accepting a combo whose
optional layer selector is outside the snapshot's recorded layer geometry.
`rmk-types/src/combo.rs` makes that selector a public `Option<u8>`, and the
participant-facing requirement already says combo entries must not exceed
recorded geometry. Version 17 will state the layer boundary explicitly, update
the reference validator, and add a black-box validation/preflight/restore
probe. This is a public semantic boundary and distinguishes two observed
legitimate-looking solver shortcuts; it is not a private error variant or
helper choice.

Two reviewer-reported false-positive families are also actionable even though
all four reviewed implementations happen to implement them correctly:

| Plausible survivor | Public requirement | Version-17 oracle | Why distinct |
|---|---|---|---|
| Compare only the previously sampled `max_forks` geometry field | Every one of the ten structural geometry fields must match | Independently perturb the target's layers, rows, columns, encoders, combo slots/key limit, macro extent, Morse slots/pattern limit, and fork slots; require preflight failure and no mutation for each valid snapshot | Each field is manually copied from `DeviceCapabilities`; an omitted mapping/equality term is independently plausible |
| Reject unknown versions only in byte decoding | `validate`, `preflight_restore`, and `restore_configuration` accept an in-memory public record and must reject an unknown version | Call `validate` directly, then exercise preflight and restore with the same in-memory unknown-version snapshot while accepting either local-first rejection or an optional identity read and forbidding mutation | Covers independent public invocation modes rather than another malformed-byte fixture |
| Validate trigger count but not `Combo.layer` | Combo entries may not exceed recorded geometry | Set `Combo.layer == num_layers` in an otherwise valid snapshot; require direct validation and no-write preflight/restore rejection | Observed in two passing trajectories and grounded in the public wire type |

The probes will assert only success/error class, target state, and absence of
mutating commands. They will not require particular `SnapshotError` variants,
strings, sequence numbers, preflight sub-check order, bulk helper scheduling,
or encoder write order. The existing zero-macro WASM probe remains unchanged
because it already caught the sole failed trajectory; duplicating it would add
no discriminator.

Changing the prompt, reference behavior, and hidden tests creates immutable
version 17 and invalidates the version-16 audit. Before version 17 can be
approved, it must repeat the arm64/amd64 patch-state matrix, runtime WASM lane,
all eight saved RMK solution replays across `agent-runs1` and `agent-runs2`,
the three legitimate implementation variants, and the expanded exact-version
mutation audit. Calibration remains 0/10, and no cold solver is authorized.

### Version 17 audit result

The exact-version gate is complete. Combined arm64 and amd64 runs pass 83/83
base tests, 16/16 native snapshot tests, and 1/1 runtime WASM test. Test-only
runs pass the same 83-test base and emit only the skipped compilation
placeholder. Solution-only runs pass locked/offline metadata, workspace
all-target tests, doctests, the WASM target check, standalone no-default RMK,
the `rmk-macro` build, and its `_simulator` suite on both architectures.

All three legitimate alternatives pass: independent keymap paging and
one-item writes, a padded final macro chunk, and encoder-ID-major restore with
correct layer-major snapshot indexing. All 40 isolated mutants are caught,
including combo-layer omission, decoder-only version checking, and omission of
each structural geometry comparison independently. No mutant survived the
focused suite.

The four fresh `agent-runs2` patches now produce one complete pass: one still
fails the existing empty-macro WASM boundary, and two fail the new combo-layer
boundary. Replaying `agent-runs1` gives three passes and one combo-layer
failure, for four passes and four failures across all eight saved patches. No
cold solver or calibration run was performed. Exact artifact identities and
the requirement ledger are frozen in `FALSE_POSITIVE_AUDIT.md`.

## Version 18 trajectory-informed hardening gate

Before changing the prompt or hidden tests, `PROBLEM_DESIGN.md`, the complete
RMK design history, the three reviewer findings, and every compact and raw
record under `agent-runs3` were inspected. All four runs are legitimate passes;
this batch contains no near-pass or broad behavioral failure, so those
categories are recorded as unavailable rather than replaced with unrelated
evidence.

| Raw evidence | Result and approach | Design evidence |
|---|---|---|
| `agent-runs3/Nova_Nova_1` | 83/83 base and 18/18 focused including two self-authored tests; 563 added production lines | Uses `read_all_keymap`, conditionally rejects zero macro chunks only for nonempty space, emits short final macro writes, and proactively checks native, alloc/no-alloc, WASM, formatting, and the empty-macro path. |
| `agent-runs3/Nova_Nova_2` | 87/87 base and 20/20 focused including four self-authored tests; 601 added production lines | Uses the same public bulk helpers and exact macro slicing, with native tests, WASM checks, formatting, clippy, and no-default checks. |
| `agent-runs3/Nova_Nova_3` | 87/87 base and 20/20 focused including four self-authored tests; 574 additions and one deletion across four production files | Uses the bulk helpers, exact row-major encoder indexing, guarded `max(1)` chunk iteration, and a small public Morse ordering support change; it checks Rynk, `rmk-types`, WASM, allocation-free builds, and formatting. |
| `agent-runs3/Nova_Nova_4` | 83/83 base and 19/19 focused including three self-authored tests; 601 additions and three deletions | Independently converges on bulk helper enumeration, conditional zero-chunk rejection, short final macro writes, and native/WASM/no-default/clippy checks. |

Each raw record contains six compact trajectory steps with the implementation
work represented as tool calls inside the agent turn. The selected seams are
consistent across the batch: `rynk/src/snapshot.rs`, `rynk/src/lib.rs`, and
`rynk/rynk-wasm/src/client.rs`, with one solver also making a small
`rmk-types/src/morse.rs` change. The successful-solution production median is
therefore about 588 added lines, replacing the original low-confidence
reference estimate as the current scope signal.

The 4/4 pass rate invalidates version 17 as sufficiently discriminating. The
following ledger records the version-18 changes before `test.patch` is revised:

| Evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| The extent fixture has one row and one column, so a manual column-major implementation is indistinguishable from row-major. All four passes avoid the shortcut by calling the repository helper, but the public API permits an independent implementation. | Keymap vectors are layer-major, then row-major, then column-major. | Use two layers, two rows, and two columns with distinct actions; verify exact exported flattening and the restored action at every coordinate. | Exercises a semantic ordering boundary across both export and restore without requiring the helper, page schedule, or packing. |
| The native negative test covers nonempty macro space with a zero chunk but does not name the inverse boundary. The repository default capabilities and the existing WASM fixture make zero space plus zero chunk a normal state. | A zero macro chunk is invalid only when macro space is nonempty. | With matching zero-sized macro geometry and zero chunk capability, require export, preflight, and restore success and observe no macro request. | Covers the positive side of the condition rather than another rejection fixture; it accepts local-first and identity-first implementations. |
| The prior stateful peer deliberately accepted a padded final macro frame because firmware truncates it; the new review and user direction require the portable restore contract itself to remain inside the recorded resource. | Macro restore covers exactly `macro_space_size` bytes in advertised chunks, with only the remaining bytes in the partial final request. | Record macro writes for a five-byte region and three-byte chunk, require contiguous `(0,[1,2,3])` and `(3,[4,5])`, and reject every `offset + len` overrun. | Observes the public transport extent, not a helper or private error. The prompt is updated so the former padded-frame prototype is no longer an unstated legitimate alternative. |
| The complete fixture advertises only one combo, fork, and Morse slot. A solver can special-case the first slot while still passing, even though these families use distinct bulk and single-item endpoints. | Enumeration covers every advertised slot and preserves index order for combos, forks, and Morse definitions. | Advertise two slots in each family, use distinct values, force one-item pages, and compare the exported vectors and fully restored target state. | Adds nontrivial extent to three independent resource APIs without prescribing single-item versus bulk access or page concurrency. |
| The compatibility test stops after preflight. An implementation can accept different target transport limits but still restore with a fixed or source-derived chunk/page assumption. | Compatible units may have different payload, page, and macro chunk limits, and restore uses the target's advertised limits. | Restore a source snapshot to a metadata-compatible target with different transport limits and a one-byte macro chunk; verify complete final state and exact target-sized macro writes. | Exercises actual cross-unit data flow rather than another identity permutation or an exact private packing strategy. |

No private error variants, exact keymap bulk page shapes, encoder write order,
or identity-read-before-local-check ordering will be added. Version 18 must
repeat the exact arm64/amd64
patch-state matrix, all twelve saved RMK solution replays, legitimate
alternatives that remain valid under the revised contract, and an expanded
false-positive mutation audit. Calibration remains 0/10, and no cold solver is
authorized.

## Version 19 trajectory-informed stage-failure gate

Before revising `test.patch`, `PROBLEM_DESIGN.md`, the complete local RMK design
history, the new reviewer finding, and all compact and raw records under
`agent-runs4` were inspected. The repository, candidate, success, and prior-run
records were searched again for Rynk snapshot restore, staged failure, partial
progress, and stop-after-error evidence. All four new runs are legitimate
passes. This batch again contains no near-pass or broad failure, so those
categories are recorded as unavailable.

| Raw evidence | Result and approach | Design evidence |
|---|---|---|
| `agent-runs4/Nova_Nova_1` | 83/83 judged base and 17/17 judged new; 556 net production lines across the snapshot module, exports, and WASM client | Implements one `stage!` helper, with explicit aggregation for encoder, fork, and macro loops; runs native, alloc/no-alloc, WASM, clippy, formatting, and diff checks. |
| `agent-runs4/Nova_Nova_2` | 83/83 judged base and 17/17 judged new; 628 net production lines in the same three files | Handles every write branch explicitly and pushes a stage only after its complete resource succeeds; runs native, loopback, no-allocation, clippy, and WASM checks. |
| `agent-runs4/Nova_Nova_3` | 83/83 judged base and 17/17 judged new; 641 net production lines in the same three files | Routes all eight branches through a shared `write_stage` helper after collecting loop failures; runs native, all-feature, no-default-feature, and WASM checks. |
| `agent-runs4/Nova_Nova_4` | 83/83 judged base and 17/17 judged new; 604 net production lines in the same three files | Implements explicit early returns with the exact completed prefix at every write boundary; runs workspace, alloc/no-alloc, WASM, clippy, and formatting checks. |

The raw records each contain six top-level steps with repository searches,
edits, compile corrections, and verification commands preserved as tool calls
inside the agent turn. All four converge on `rynk/src/snapshot.rs`,
`rynk/src/lib.rs`, and `rynk/rynk-wasm/src/client.rs`; the observed median is
about 616 net production lines. Their shared helpers are legitimate and must
remain accepted. The useful discriminator is not helper shape, but the
independent externally observable failure boundary at each resource stage.

| Evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| The current failure test rejects only `SetFork`. Seven independent write branches can return the wrong `stage`, include an incomplete stage in `completed`, omit an earlier completed stage, or continue into a later resource while the focused suite still passes. The protocol exposes different commands for each family, and every solver implements these branches separately even when sharing an error helper. | On the first write failure, `RestoreError::Write` reports the failed `RestoreStage`, reports exactly every earlier fully completed stage in order, and sends no later mutation. | For each of the eight public stages, make the stateful peer reject the first write in that logical stage, accepting either single-item or bulk commands. Require the exact public completed prefix and failed stage, then require the rejected request to be the last mutating request. | Exercises eight independent public control-flow exits without prescribing helper architecture, page shape, error strings, or the command form used for keymap, combo, and Morse resources. One table-driven test avoids presenting repeated fixtures as distinct semantic families. |

Version 19 will change only the logical-stage failure oracle and its records.
It will not pin which single-item or bulk endpoint an implementation uses, the
number or packing of pages, the order of writes within a stage, or private
error variants beyond the public `RestoreError::Write` fields. The user asked
to defer the false-positive audit again, so version 19 may be reference-tested
but cannot be approved, submission-ready, or used for calibration. No cold
solver is authorized.

## Version 20 trajectory-informed compatibility and partial-stage gate

Before changing `test.patch`, `PROBLEM_DESIGN.md`, the complete RMK design
record, the two new reviewer findings, and every compact and raw record under
`agent-runs5` were inspected. Searches across the problem index, candidate and
success records, prior RMK runs, and repository protocol code covered direct
preflight entry points, identity and geometry compatibility, multi-request
resource writes, partial progress, and stop-after-error behavior. All four new
runs are legitimate passes; no near-pass or broad failure exists in this batch.

| Raw evidence | Result and approach | Design evidence |
|---|---|---|
| `agent-runs5/Nova_Nova_1` | 83/83 judged base and 17/17 judged new; 565 net production lines in three files | Direct preflight validates the record, cached capabilities, target identity, and geometry; restore routes every write through a shared error helper and aggregates loop failures before completing a stage. |
| `agent-runs5/Nova_Nova_2` | 83/83 judged base and 17/17 judged new; 602 net production lines in three files | Direct preflight independently compares VID, PID, product name, and geometry; a shared stage macro adds completion only after the entire future succeeds. |
| `agent-runs5/Nova_Nova_3` | 83/83 judged base and 17/17 judged new; 491 net production lines in three files | Direct preflight owns all compatibility checks and restore calls it; encoder, fork, macro, and bulk helpers return one stage result before completion is recorded. |
| `agent-runs5/Nova_Nova_4` | 83/83 judged base and 17/17 judged new; 620 net production lines across the three snapshot files and a loopback test | Direct preflight performs all compatibility checks; stage completion follows successful whole-resource futures, with proactive live protocol export/restore coverage. |

All raw records contain six top-level steps with repository inspection,
implementation, compile corrections, and verification retained in tool calls.
Three runs change only `rynk/src/snapshot.rs`, `rynk/src/lib.rs`, and the WASM
client; one also adds loopback assertions. The observed median is about 584 net
production lines. These implementations are correct evidence, not targets to
reject.

| Evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| Direct `preflight_restore` currently has compatible-success and malformed-record coverage, while identity and geometry incompatibility are exercised through `restore_configuration`. A solver can put compatibility checks only in restore and leave the public direct preflight method incomplete. | `preflight_restore` itself validates support, reads target identity when needed, rejects incompatible VID, PID, product name, or any structural geometry field, and sends no mutation. | Exercise direct preflight and restore independently for each isolated identity mismatch and all ten isolated target-geometry mismatches, using a recording peer that permits local-first geometry rejection or the identity read but rejects every mutation. | Separates two public entry points without requiring a shared helper, a particular check order, or a private error variant. |
| Version 19 rejects the first request in each failed stage. An implementation can record a stage as completed after its first successful inner write and then misreport a failure on a later encoder, fork, or macro request. | A stage enters `completed` only after every request belonging to that resource succeeds; a later request failure still reports that stage as failed and sends no later-stage mutation. | Configure at least two encoder writes, two fork writes, and two macro chunks; reject the second logical request in each selected stage, require the exact earlier-stage prefix without the partially applied stage, and require the rejected stage to remain the final mutation. | Tests a different commit boundary from first-request failure while avoiding bulk page packing assumptions: encoder and fork use indexed endpoints, and macro chunking is explicit in the public contract. |

Version 20 will not require a private helper structure, exact bulk page count,
error strings, or identity-before-geometry ordering. The user again asked to
skip the false-positive audit, so the revision may be reference-tested and
replayed against saved patches but remains unapproved and unusable for
calibration. No cold solver is authorized.

## Version 21 trajectory-informed sparse-restore redesign gate

Before changing the public description, reference, or hidden tests,
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the complete local RMK design
history, and all compact and raw records under `agent-runs5` were inspected.
Searches also covered the Rynk single-resource, indexed-resource, bulk, and
macro APIs. All four latest runs are legitimate passes, with 83/83 judged
regressions and 17/17 judged new tests in each record. They contain no near-pass
or broad-failure trajectory. Their production patches range from 491 to 620
net lines and all implement the same public data flow: validate compatibility,
then unconditionally write every resource family in fixed stage order.

Version 20 closes the known behavioral omissions in that contract, but it does
not create an independent architectural discriminator: every latest solver
passes it. The calibration target is not universal failure. The next level
therefore changes one public invariant that inverts restore data flow while
remaining implementable through existing read and write APIs: restore must
read the complete target configuration before mutation and skip stage resources
that already equal the desired snapshot.

| Evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| Every latest solver writes all eight stages after compatibility preflight, even when the target already equals the snapshot. | After compatibility preflight, restore obtains a complete target baseline before mutation. Equal stage resources send no setter. | Restore an identical snapshot, require every configuration family to be readable, and require zero mutating requests. | Observes protocol effects only. It accepts any baseline representation, comparison helper, or read implementation. |
| The current fixed write pipeline has no branch for a mixture of clean and dirty resources. | Dirty stages alone are written in the published stage order; the final target configuration exactly equals the snapshot. | Start with alternating equal and unequal stage resources, then require writes only for the unequal stage families and verify final state. | Requires stage-level minimality, not item-level diffing, page packing, or a private helper structure. |
| A solver may read lazily and start keymap mutation before discovering that a later target resource cannot be read. | Failure to obtain or validate any part of the complete baseline is `RestoreError::Preflight` and sends no mutation. | Reject the final baseline resource read and require a preflight error with no mutating request. | Tests the public no-write boundary without prescribing the order of checks inside compatibility preflight or exact paging. |
| Existing progress accounting assumes every earlier stage was attempted and may count skipped resources as completed. | `completed` contains only dirty stages whose writes completed fully; equal skipped stages are absent. | Alternate clean and dirty stages, fail a later dirty stage, and require the exact completed dirty prefix with no later mutation. | Separates public write progress from comparison internals and accepts single-item or bulk endpoints. |

The redesign is deliberately stage-granular. It does not require per-key,
per-slot, or per-byte minimal writes; it does not require rollback, a firmware
transaction, a particular number of reads, or reuse of `export_configuration`.
Standalone `preflight_restore` retains its compatibility contract. The full
baseline is a restore-only pre-mutation requirement because it is needed to
decide which stage resources are dirty.

The user explicitly requested that the mandatory exact-version false-positive
audit be skipped. Version 21 may therefore be implemented and reference-tested,
but it remains audit-pending, cannot be approved or used for calibration, and
stays at 0/10. Saved solutions may be replayed as trajectory evidence; no cold
solver is authorized.

## Version 22 description-only gate

Before editing the participant description, `PROBLEM_DESIGN.md` and the
version-21 trajectory ledger were reread. The latest evidence still supports
all four sparse-restore discriminators, and the reviewer reported only a
514-word verbosity threshold. Version 22 therefore makes an editorial-only
compression: it removes repeated connective wording and combines adjacent
sentences without changing a field, method, ordering rule, validation boundary,
compatibility rule, sparse-restore invariant, error contract, or WASM behavior.
`test.patch` and `solution.patch` remain byte-identical to version 21.

The user's instruction to skip the exact-version false-positive audit remains
in force. This prompt-only revision creates a new immutable version, leaves
calibration at 0/10, and remains audit-pending. No cold solver is authorized.

## Version 23 transcript-fairness gate

Before revising `test.patch`, `PROBLEM_DESIGN.md`, the version-21 trajectory
ledger, the stateful native peer, the standalone WASM peer, and the reviewer
findings were inspected. No new solver batch exists, so the latest legitimate
passes remain the representative trajectory evidence; near-pass and broad
failure categories remain unavailable. Repository APIs permit a sparse restore
to reuse the identity obtained during compatibility preflight and to gather
independent baseline resources in any order before mutation.

The version-22 tests accidentally made the reference's use of
`export_configuration` as its baseline helper observable. That helper rereads
identity and imposes export order on baseline reads, neither of which belongs
to the public sparse-restore contract.

| Overconstraint | Fair public invariant | Revised black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| The combined native phase vector requires restore baseline reads in export order and collapses two identity reads into one phase. | Export retains its stated order; restore must acquire every stage baseline before its first mutation; dirty writes retain stage order. | Isolate and check the export prefix, require every baseline resource before the first setter, and check only the normalized write-stage suffix. | Accepts identity reuse, an extra identity read, arbitrary independent baseline scheduling, and either single-item or bulk reads. |
| Encoder and macro traces require the reference export order twice. | Exported values and advertised extents must be complete; restore must read the same extents before writing. | Require each encoder coordinate and macro offset exactly twice as a multiset, while final state and write extents remain exact. | Detects missing, duplicate, or out-of-range reads without prescribing baseline iteration order. |
| The WASM script requires exactly 11 requests, including a redundant second identity read. | Both byte APIs must run, an identical restore must acquire a complete baseline, and it must send no setter. | Dynamically answer valid restore reads at varying sequence numbers, accept 10 or 11 total requests, and reject every unrecognized request. | Accepts reuse or reread of compatible identity while still rejecting missing baseline work or mutation. |

Version 23 also removes two redundant public sentences without changing
behavior. The test and prompt changes create a new immutable version and reset
calibration to 0/10. The user again requested that the false-positive audit be
skipped, so this version remains audit-pending. No cold solver is authorized.

## Version 24 trajectory-informed item-sparse redesign gate

Before changing the public contract or `test.patch`, `PROBLEM_DESIGN.md`,
`CALIBRATION_STRATEGY.md`, all compact results and solution patches under
`agent-runs6`, and every raw `agent-runs6` trajectory were inspected. All four
runs are legitimate passes with 83/83 judged regressions and 22/22 judged new
tests. No near-pass or broad failure exists in this batch. The four raw records
each contain one complete agent turn with 20 to 34 retained tool calls covering
repository inspection, implementation, compile corrections, native/WASM
checks, formatting, and final diff review.

| Raw evidence | Production result | Restore architecture |
|---|---|---|
| `agent-runs6/Nova_Nova_1` | 743 net lines, three production files | Builds and validates a full baseline, compares whole vectors, then uses whole keymap/combo/Morse writers and rewrites every encoder, fork, and macro chunk in a dirty stage. |
| `agent-runs6/Nova_Nova_2` | 589 net lines, three production files | Reuses preflight identity in a validated export helper, then gates complete resource writers on vector inequality. |
| `agent-runs6/Nova_Nova_3` | 654 net lines across three production files plus a legitimate loopback test | Reads and validates a baseline snapshot, then rewrites complete dirty resources through explicit stage branches. |
| `agent-runs6/Nova_Nova_4` | 588 net lines, three production files | Rereads and validates a complete snapshot, then invokes whole-resource helpers for every dirty vector. |

The median successful patch is about 622 net lines. Together with the broader
history reported by the user, this 4/4 batch confirms that stage-level sparsity
is another universally solved architecture, not the intended calibration
ceiling. All four solutions expose the same next fair implementation boundary:
they know every baseline item but discard that information by rewriting the
whole resource as soon as one item differs.

| Evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| Every run compares whole vectors and rewrites every entry in a dirty keymap, encoder, combo, fork, or Morse stage. The protocol exposes stable per-entry setters for each family. | Within those dirty stages, write only entries whose baseline value differs, using the public enumeration order. | Seed multiple equal and unequal entries in every family, record logical positions touched through either single or bulk endpoints, and require exactly the unequal entries in canonical order. | Accepts single setters or bulk groups of consecutive dirty entries and judges logical touched entries rather than helper or page shape. |
| Every run rewrites all macro chunks when any byte differs, although baseline bytes and advertised chunk boundaries identify dirty chunks independently. | Compare macros by advertised chunks and write only dirty chunks, with exact snapshot bytes and a short final chunk. | Use three chunks with only the first and last dirty; require no middle-chunk write and exact boundary payloads. | Uses the public chunk model without requiring byte-run diffing or a private representation. |
| The new reviewer finding notes that transport rejection is tested but a successfully read malformed baseline is not. Some baseline assemblers can return a structurally invalid collection without a transport error. | The assembled target baseline must pass complete `ConfigurationSnapshot` validation before mutation. | Return a complete but invalid combo record successfully, require `RestoreError::Preflight`, and reject every setter. | Exercises validation of observed public data and accepts bulk or single reads. |
| A later write can leave earlier entries in the failed stage applied. Whole-stage retry rewrites them despite a fresh baseline. | A retry reacquires the baseline and must not rewrite entries or macro chunks already matching the snapshot. | For each multi-request stage, fail the second dirty write, retry successfully, and require every logical entry or chunk to complete exactly once while later stages resume normally. | Derives resumability from the public fresh-baseline and minimal-write rules without adding rollback, checkpoints, or private progress state. |

Version 24 selects Level 3: item-sparse writes for independently addressable
resources, chunk-sparse macros, validated observed baselines, and naturally
resumable retries. It does not require maximal bulk packing, a particular
single/bulk endpoint, item-level error variants, rollback, transactions,
post-write verification, or exact request counts. The existing stage order and
stage-level `completed` semantics remain unchanged.

The user explicitly requested that the exact-version false-positive audit be
skipped. Version 24 may be implemented and reference-tested but remains
audit-pending, cannot be approved or calibrated, and starts at 0/10. No cold
solver is authorized.

## Problem-construction gates

## Version 25 artifact-boundary repair gate

Before touching either patch artifact, `PROBLEM_DESIGN.md`, the version-24
trajectory ledger, the platform submission instructions, and the canonical
workspace patches were inspected. No new solver trajectory or behavioral
finding exists. The review describes exactly the three-file contents of the
canonical `solution.patch` as though they were submitted in the test-patch
field: `rynk/src/snapshot.rs`, `rynk/src/lib.rs`, and
`rynk/rynk-wasm/src/client.rs`. Conversely, the canonical `test.patch` contains
eight harness/test files, including a mode-100755 repository-root `test.sh`,
and contains none of those production files.

This is an artifact-boundary and handoff correction, not a behavioral redesign.
Version 25 will regenerate the two patches from separate clean source trees,
check their file allowlists, verify application with `git apply` in a pristine
checkout, and record an explicit submission-field manifest. The participant
contract and all version-24 discriminators stay byte-for-byte unchanged. The
request to remove public types, fields, validation, ordering, sparse-write, and
error semantics is rejected: participants do not see the reference solution,
and prior fairness reviews required those tested interfaces to be stated. The
request to randomize `rynk/src/snapshot.rs` is likewise inapplicable because it
is a production module in `solution.patch`, not a hidden test path.

The user again directed that the exact-version false-positive audit be skipped.
No mutation audit, historical solver replay, calibration, or cold solver is
authorized in this repair. Version 25 remains audit-pending at 0/10.

The version-24 reference changes about 650 production lines across the native
snapshot module, exports, and WASM wrapper. The focused lane has 25 native
tests plus one runtime Node WASM test. It retains validation, ordering,
compatibility, exact extents, all first-request failure stages, all six
multi-request partial failures, complete baseline acquisition, identical-target
no-op, and dirty-stage progress. Version 24 adds logical item sparsity,
chunk-sparse macros, successful malformed-baseline rejection, and retry after
a partially applied stage.

The completed version-17 false-positive gate is recorded in
`FALSE_POSITIVE_AUDIT.md`, but version 24 supersedes it. Versions 21 through 23
selected and refined stage-sparse restore; version 24 advances to Level 3 based
on four unanimous `agent-runs6` trajectories. `LEVELS.md` retains both earlier
architectures as explicit fallback levels.

Exact version-24 artifact identifiers:

- `meta.md`: `9e02b4062a5e52dd8194a43753fd33f8b6ddc8081ebbcdec9c77d91f25f62402`
- `test.patch`: `eaca245446f046f56da2b66d9413ecea79e4658dc873d61042898681dfb2f132`
- `solution.patch`: `95f4086a5623ddd3dab4dde459c982a6c7ff31b9b30585224034b5488bbbbc60`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338`

Reference verification is 25/25 focused native tests and 1/1 runtime WASM test
on both arm64 and amd64, plus 83/83 pre-existing Rynk workspace tests on arm64.
The four latest saved implementations are known from raw trajectories and
patch inspection to rewrite whole dirty resources. They were not replayed or
counted as calibration runs in this user-directed no-false-positive round.

Before the package can be called submission-ready:

1. complete the exact version-24 false-positive audit and full patch-state
   matrix that the user asked to skip;
2. run calibration only if the user explicitly asks for it, bound solely to a
   fully audited immutable version 24; and
3. restart at 0/10 after any prompt, test, reference, runner, or environment
   change.

The false-positive audit was intentionally skipped, and no cold solver was
run. Version 24 is therefore a hardened, reference-verified draft rather than
an approved or submission-ready package.

Any prompt, hidden-test, reference, runner, or environment change creates a new
immutable version, invalidates the false-positive audit, and resets any later
calibration count to 0/10.

## Version 26 fairness, alloc-surface, and Level 4 redesign gate

Before changing `test.patch`, workspace-root `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md` were reread, along with this problem's `LEVELS.md`,
`ERRORS.md`, `SUMMARY.md`, and the version-24 discriminator ledger above.

Evidence search for the version-24 platform batch: `agent-runs1` through
`agent-runs6` are on disk, but no `agent-runs7` bundle, `actual_trajectories`
entry, or archive member for the version-24 runs exists in the workspace. The
only version-24 evidence is the reviewer's report, which is recorded here as a
secondary source rather than raw trajectory data. Per `PROBLEM_DESIGN.md`, that
unavailability is recorded rather than substituted with an unrelated run.

Reported version-24 outcome: 3 legitimate passes in 4 unhinted working runs
(75%), against a 50% cap. The fourth run was a hidden-test false negative, not
a defect: it assembled the restore baseline from per-entry reads while two
assertions demanded the `GetKeymapBulk`/`GetComboBulk`/`GetMorseBulk` wire
commands by name. Repairing that assertion makes the fourth run a pass, so the
measured 75% is a floor and Level 3 is spent. No cold solver was run and no
false-positive audit was performed; both remain user-restricted.

| Reported evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| Two assertions named bulk read commands, so a complete per-entry baseline was rejected. The written contract never constrained read shape. | The baseline must be complete before mutation; how it is read is free. | Fold single-entry and bulk reads to one phase per resource before asserting coverage, exactly as the ordering assertions already did. | Removes a false negative without weakening the no-mutation or validation guarantees. |
| Both graded lanes enable `std`, so an API gated on `std` satisfies an `alloc`-only requirement. rynk's own dev-dependencies re-enable `std` through feature unification, so an example or integration test cannot detect this either. | The whole snapshot surface resolves with `alloc` on and `std` off. | A dependency-free member crate outside the rynk workspace names every required item and is built `--no-default-features --features alloc --locked --offline`. | Compile-only and endpoint-agnostic; it asserts existence, not implementation. Verified to fail when the module and its re-exports are gated on `std`. |
| Every architecture observed through version 23, and the reported version-24 passes, compare a snapshot vector against a target vector at identical flat indices. That correspondence is an assumption of the data structure, not of the protocol: keys and encoders are addressed by coordinate, and the stride is the device's. | A target is compatible when no geometry dimension is smaller. Entries are compared and addressed in the target's coordinates, and anything the snapshot does not reach is left untouched. | Restore a two-layer, two-row, two-column, two-encoder snapshot onto a target grown by one in every dimension; require exact touched coordinates, and require the spare key, encoder, combo, fork, Morse, and macro slots to hold their pre-restore sentinels. | Uses the device's advertised geometry and the protocol's existing coordinate addressing. It adds no private representation, and shrinkage is still rejected in all ten dimensions. |
| Version 24 explicitly accepted one request per dirty entry, so no implementation had to reason about how dirty entries batch. Whole-resource paging is already documented repository behavior for `write_all_*`. | Consecutive differing entries travel in as few requests as the target's advertised page size allows. | Record every write as `(first entry, entries)` for both endpoint families and assert exact request lists: a run that outgrows a page, a run that exactly fills one, and runs split by an equal entry. Under geometry growth, a run contiguous in snapshot order is not contiguous on the target. | Judges request shape, not endpoint choice, so single setters and bulk pages are equally acceptable. Encoders and forks have no bulk endpoint and carry no grouping requirement. The payload budget is deliberately left non-binding so the expected split is unambiguous. |

Version 26 selects Level 4. It does not require rollback, transactions,
post-write verification, payload-budget packing, a baseline read order, or
maximal packing beyond the advertised page size. Stage order, stage-level
`completed` semantics, export ordering, extents, and every version-18 through
version-24 rejection case are unchanged.

Three reference mutants confirm the two new levers discriminate independently,
and that neither is redundant with the version-24 checks:

| Mutant | Failing tests |
|---|---|
| One request per differing entry (legal under version 24) | `snapshot_restore_writes_only_dirty_entries_in_grouped_requests`, `snapshot_restore_addresses_a_larger_target_in_its_own_coordinates` |
| Flat-index keymap comparison against the target vector (the architecture every observed run used) | `snapshot_restore_addresses_a_larger_target_in_its_own_coordinates` |
| Exact geometry equality (the version-24 compatibility rule) | `snapshot_restore_requires_a_target_that_can_hold_every_entry`, `snapshot_restore_addresses_a_larger_target_in_its_own_coordinates` |

The other 20 focused tests pass under all three mutants, so the additions do
not double-count existing coverage. This is a discriminator check on the
reference, not the skipped false-positive audit.

The description was rewritten as prose in response to the spec-sheet finding.
Field and variant names are retained because the hidden tests construct those
types by name, and dropping them would create the same class of false negative
the fairness repair removes. It is 467 whitespace-counted words.

Exact version-26 artifact identifiers:

- `meta.md`: `d91ca510febe77f6c9513590c143d130dea46acabd2ffe27e82396c824b42cc7`
- `test.patch`: `5f37b06a1f9ded56712f040b5ad9fb5bdbc1fc8c72eaf324d2e133e07bc7ba0d`
- `solution.patch`: `cbc6610074ffec8e14c8aee20e44635b9cc03f6ee0d3743cbbe434f4c3434227`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338`

The user directed again that the exact-version false-positive audit be skipped.
Version 26 is reference-verified but audit-pending at 0/10, and no cold solver
is authorized.

## Version 27 preflight-fairness and test-classification gate

Before changing `test.patch`, workspace-root `PROBLEM_DESIGN.md` and this
problem's version-26 ledger were reread. A platform review of version 26
returned one wrapper-classification defect and eight unfair expectations. No
new solver trajectory exists; no cold solver was run and no false-positive
audit was performed, both still user-restricted.

**Classification.** Version 26 ran the `alloc`-only surface build as a shell
step that, on failure, wrote its own single-testcase JUnit and exited. In the
wrapper run without `solution.patch` that produced a hard failure for
`snapshot_surface_builds_with_alloc_without_std`, while every other new test
was absent because the test crate does not compile without the solution. A test
present only in the failing run is neither pass-to-pass nor fail-to-pass. The
check is now an ordinary `#[test]` inside the graded nextest set that shells out
to the build, so both runs treat it exactly like its 26 peers: absent behind the
skipped compile placeholder before the solution, passing after it.

**Signature pinning.** The surface crate annotated each call site with its exact
`Result` type, which pinned an error-typing design the description never states
and the repository never shows; visible client methods return `RynkHostError`,
so `SnapshotError` on `export_configuration` was one plausible choice among
several. Results are now discarded rather than annotated, and the error types
are named through standalone `Option<T>` bindings. The crate asserts that the
items exist and are reachable without `std`, and nothing about return types,
error assignment, or derives.

| Reported evidence and generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|
| Seven preflight tests drove a scripted link that answered only `GetDeviceInfo` and then hung, so any additional read-only request timed out. The contract guarantees that a rejected preflight does not mutate; it never defines preflight's read scope, ordering, or whether the public `preflight_restore` may read resources at all. | A rejected preflight sends no setter. Reads are unconstrained in number and order. | Drive both entry points against the stateful peer, which answers every read, and assert that no recorded command maps to a write stage. | Judges the stated guarantee directly instead of inferring it from a transcript that also forbids permitted reads. |

Verified in both directions. A mutant whose `preflight_restore` exports the
whole device before judging, and whose `restore_configuration` reads the
baseline before validating anything, now passes all 60 tests; under version 26
it failed. A mutant that sends one `SetDefaultLayer` before validating still
fails eight tests, so the no-mutation oracle is undiminished. The four
version-26 discriminator mutants were rerun and still fail exactly the tests
recorded above.

Two supporting changes. The peer now answers a macro read with `RynkError::Invalid`
when the device advertises a zero chunk, because a zero-length chunk cannot
advance an offset and would otherwise stall a reader rather than fail it. The
six duplicated `StatefulSnapshotState` literals collapse onto one
`blank_target_state` constructor, which also gives the compatibility sweep a
self-consistent device at any advertised shape.

The participant description is unchanged; the reviewer's alternative of
specifying exact preflight scope and method signatures was declined because it
would enlarge the prompt to protect one arbitrary implementation choice, while
relaxing the tests protects every correct one.

Exact version-27 artifact identifiers:

- `meta.md`: `d91ca510febe77f6c9513590c143d130dea46acabd2ffe27e82396c824b42cc7` (unchanged)
- `test.patch`: `381c539e923e4e72dd1052e881c9168ab87b1d7e3120471db20155969d2ea5cd`
- `solution.patch`: `cbc6610074ffec8e14c8aee20e44635b9cc03f6ee0d3743cbbe434f4c3434227` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Version 27 remains Level 4 and audit-pending at 0/10.

## Version 28 trajectory-informed easing gate

The first raw trajectories since version 23 arrived as `agent-runs7`: five Nova
runs against version 27. All five failed, 0/5. Workspace-root `PROBLEM_DESIGN.md`
and `CALIBRATION_STRATEGY.md` were reread, and every run's `eval-result.json`,
`junit-new.xml`, `test-log.txt`, `solution-patch.patch`, and raw trajectory were
inspected before changing anything.

| Run | Baseline | New tests | Cause |
|---|---|---|---|
| `Nova_Nova_1` | 83/83 | 20/27 | All 7 failures are the same panic: `keymap write page exceeds the advertised page size`. |
| `Nova_Nova_2` | 83/83 | 20/27 | Same 7, same panic. |
| `Nova_Nova_3` | 83/83 | 20/27 | Same 7, same panic. |
| `Nova_Nova_4` | 83/83 | 15/27 | The same 7, plus 5 from returning standalone `RestoreError` variants instead of `Preflight`. |
| `Nova_Nova_5` | 83/83 | none ran | Three `E0164` errors: the tests destructure `RestoreError::Preflight(_)`, the implementation declared `Preflight { source }`. Compilation stopped, so no new test executed. |

This is not a difficulty signal. It is one unfair assertion plus one
undocumented shape, and the 0/5 says nothing about the intended boundary.

**The advertised-page cap contradicts the repository.** All of runs 1, 2, and 3
independently reached the same design: detect dirty runs correctly, then hand
each run to the repository's own `split_pages`, sized by `max_payload_size`.
That helper is what `write_all_keymap`, `write_all_combos`, and
`write_all_morses` use, and its own comment says sizing by real encoded size
"fits several times more per frame than the advertised count, which must assume
worst-case items". So the peer's `<= max_bulk_keys` ceiling rejects the
repository's documented idiom. The evaluator scored the requirement as stated,
and it was, but a rule that punishes reuse of the crate's own pager is a
fairness defect regardless of whether the prompt names it. `snapshot_caps()`
advertises `max_bulk_keys = 1`, so any two-entry dirty run tripped it, which is
why one assertion consumed seven tests in three separate runs.

**Geometry adaptation is not what stopped anyone.** Every run that compiled
passed `snapshot_restore_addresses_a_larger_target_in_its_own_coordinates`,
including its exact touched-coordinate and untouched-sentinel assertions. Four
of four handled the target-stride remapping correctly. Version 26 chose that
lever expecting it to break the flat-index architecture; the trajectories say it
does not break Nova.

| Trajectory evidence | Decision | Rationale |
|---|---|---|
| Runs 1-3 group dirty runs correctly and fail only on page size; the repository's own pager exceeds the advertised count by design. | Drop the grouping requirement. A request may cover several consecutive differing entries and must never carry one that already matches, which is the version-24 rule. | Removes the contradiction with `split_pages` instead of restating it. Item sparsity survives because the peer still records every logical entry a page touches. |
| Run 4 returned `ProductMismatch` and similar standalone variants for pre-mutation rejections. The description named `Preflight` but never said it was the only pre-write failure case. | State that `RestoreError` has exactly two cases and that everything rejected before the first write is `Preflight`. | Closes a description gap rather than a capability gap. Version 24 had this explicitly and version 26's prose rewrite lost it. |
| Run 5 declared `Preflight { source }`; the tests required tuple syntax. | Match `RestoreError::Preflight { .. }`, which accepts tuple and struct variants alike. | The prompt prescribes `Write`'s field names and deliberately does not prescribe `Preflight`'s shape, so the tests must not either. |

Version 28 therefore keeps geometry-adaptive item-sparse restore and drops the
grouping lever, which is the fallback `LEVELS.md` pre-registered for exactly
this outcome. The expected consequence is stated plainly: with the cap gone and
the error mapping spelled out, runs 1 through 3 lose their only failure cause
and run 4 loses two, so the pass rate should move sharply up from 0/5 and may
land above the 50% cap. Level 3 measured 3/4 and the geometry addition did not
stop any of the four runs that compiled, so a further lever will probably be
needed. It is not chosen here: the next one must come from trajectories of a
version that is not blocked by an unfair assertion, and `agent-runs7` cannot
supply that.

No cold solver was run and no false-positive audit was performed; both remain
user-restricted.

### Version 28 replay measurement

Each `agent-runs7` production patch was replayed against the repaired tests in a
clean pinned checkout, with the solver's own `rynk/src/driver/tests.rs` excluded
so only the hidden tests judge it.

| Run | Against version 27 | Against version 28 |
|---|---|---|
| `Nova_Nova_1` | 20/27 | pass |
| `Nova_Nova_2` | 20/27 | pass |
| `Nova_Nova_3` | 20/27 | pass |
| `Nova_Nova_4` | 15/27 | fail: 5 pre-mutation rejections still returned as standalone variants |
| `Nova_Nova_5` | did not compile | pass |

The measured effect of the repair is 0/5 to 4/5. Run 4's remaining five
failures are the error-mapping gap, and version 28's description now states
that `RestoreError` has exactly two cases and that every pre-write rejection is
`Preflight`, so a fresh run of that implementation would very likely pass too.

The honest projection is therefore near 100%, far above the 50% cap. That is
recorded here rather than papered over: three of the four repairs were
mandatory fairness fixes, and the fourth, the advertised-page cap, was the only
thing separating any of these five implementations from a pass.

Replay measures fairness, not difficulty. It can prove that an existing
requirement wrongly rejects a correct implementation, which is exactly what it
just did five times over. It cannot estimate the pass rate of a requirement
that did not exist when those implementations were written, because every one of
them would fail a new rule by construction. So the next lever cannot be chosen
by replaying `agent-runs7`; it needs a fresh batch, or a deliberate design
decision accepted as a guess.

One correction to the version-26 ledger, now that real trajectories exist:
geometry adaptation was chosen expecting it to break the flat-index
architecture. It does not. Every run that compiled passed
`snapshot_restore_addresses_a_larger_target_in_its_own_coordinates`, including
its exact touched-coordinate and untouched-sentinel assertions. It survives in
version 28 as correct, fair behavior, not as a difficulty lever.

Exact version-28 artifact identifiers:

- `meta.md`: `d4c9570db2d43af95b06c9246bef3ce753455c9b5a203e019f421b7fee2051cf`
- `test.patch`: `74fdc4e1b0fd91d48e80ef5769866d4244c0ae97903305f72f499cf9045ea2e1`
- `solution.patch`: `cbc6610074ffec8e14c8aee20e44635b9cc03f6ee0d3743cbbe434f4c3434227` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Surviving discriminator mutants, rerun on the repaired tests: a flat-index
keymap comparison fails the growth test; exact geometry equality fails the
growth and compatibility tests; writing an entry that already matches fails five
tests. The grouping mutant is retired with the rule it tested.

## Version 29 reference-quality and JUnit-completeness gate

A review of the version-28 package scored Comprehensiveness 1/3 and Code
Quality 2/3. Both findings are about the reference solution and the runner, not
the participant contract, so `meta.md` is unchanged and no discriminator moved.

**The missing testcase.** The runner executed the WASM round trip as a second
shell command after nextest, so its result reached only the exit status. The
JUnit that the platform merges therefore listed 27 native cases and never the
WASM one, which is the expected-but-missing testcase the review reports. This is
the same defect version 27 fixed for the `alloc` surface check, left behind on
the other lane. The WASM run is now `snapshot_wasm_client_round_trips_under_node`,
an ordinary test in the graded set that shells out to
`cargo test --target wasm32-unknown-unknown` with the wasm-bindgen runner, so
the lane is one nextest invocation producing one JUnit with 28 cases and nothing
outside it. Both nested-Cargo tests share a `run_standalone_cargo` helper.

Verified as a real gate, not a formality: making `restore_configuration_snapshot`
return an error makes exactly that testcase fail and the runner exit non-zero.

**Reference quality.** Three findings, all accepted:

| Finding | Change |
|---|---|
| `group_dirty_runs` groups by adjacency and advertised item count instead of reusing the payload-aware paging already in `api.rs`. | `split_pages` becomes `pub(crate)`. The snapshot module now only detects runs of adjacent dirty addresses, in `dirty_runs`, and hands each run to `split_pages` with the same fixed-byte counts `write_all_keymap`, `write_all_combos`, and `write_all_morses` use. The advertised item count is gone from the reference entirely, which is also what `agent-runs7` did. |
| `export_configuration` rejects devices without bulk transfer, stricter than the prompt's restore-side requirement. | The capability check splits. `validate_macro_chunk` guards the export read loop, since a zero chunk cannot advance an offset. `validate_transfer_capabilities` keeps the bulk requirement and is called only from `validate_target`, which is restore-side. |
| `restore_configuration` re-reads capabilities and identity that it already holds. | `export_with(caps, info)` carries the export body. `export_configuration` reads the two values and calls it; restore passes the ones it already read for the compatibility check. |

The solution patch now touches four production paths: `rynk/src/api.rs` joins
`rynk/src/snapshot.rs`, `rynk/src/lib.rs`, and `rynk/rynk-wasm/src/client.rs`.
The one-line `pub(crate)` on `split_pages` is the whole of the `api.rs` change.

Replaying the five `agent-runs7` implementations against version 29 gives the
same 4/5 as version 28, so none of this moved the difficulty. The task is still
measured as far too easy and still needs a new lever before a calibration batch
is worth spending.

Exact version-29 artifact identifiers:

- `meta.md`: `d4c9570db2d43af95b06c9246bef3ce753455c9b5a203e019f421b7fee2051cf` (unchanged)
- `test.patch`: `d462185f5005df2ae3ec81fb3bc74718604395402d874ed7da79fed363963378`
- `solution.patch`: `f1a7100a58f3c2b52a0bb12698166cc40f1d9d1e831da1a1888fab462b130ad6`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 28/28 focused native tests on arm64 and amd64, the
WASM round trip now among them, plus 83/83 pre-existing on arm64 with the test
patch alone. The false-positive audit remains skipped and no cold solver was
run.

## Version 30 tooling-robustness and API-exclusivity gate

Two review findings, one on the runner and one on the description. Neither
touches a discriminator, and the replayed pass rate is unchanged at 4/5.

**Nested WASM tooling (WARNING).** The graded WASM round trip shells out to
`cargo test --target wasm32-unknown-unknown` with the wasm-bindgen runner under
Node, offline, on a pinned toolchain, and nothing in the test proved those
existed. The image does provision all of them, verified directly: `node
v24.15.0` at `/usr/bin/node`, `wasm-bindgen-test-runner` at `/opt/cargo/bin`,
and a `wasm32-unknown-unknown` libdir under the 1.95.0 toolchain. But a test
that assumes its host's tooling fails a solution for something the solution did
not do, so the reviewer's first option is taken as well as the second.

`missing_wasm_tooling` now probes three things before the round trip: that
`rustc --print target-libdir --target wasm32-unknown-unknown` succeeds, and that
`wasm-bindgen-test-runner` and `node` resolve on `PATH`. When anything is
absent the test prints what is missing and stands down; when everything is
present it runs for real.

All three behaviours were checked rather than assumed:

| Condition | Result |
|---|---|
| Image as shipped | The round trip executes, 28/28, no skip message, 28 seconds. |
| Image, `restore_configuration_snapshot` broken | `snapshot_wasm_client_round_trips_under_node` fails and the runner exits 100. |
| Runner and Node removed from `PATH` | 28/28 in 2 seconds, the round trip stood down. |
| Host without the runner | "skipping the WASM round trip: wasm-bindgen-test-runner is not on PATH". |

The guard cannot mask a real failure, because it only inspects tooling
availability and never the round trip's outcome.

**Enum exclusivity (HIGH).** The description said "`RestoreError` has exactly
two cases", which the tests never check. What they check is that a rejection
before the first write arrives as `Preflight`, which is what `agent-runs7`'s
run 4 got wrong by returning a standalone `ProductMismatch`. The sentence is
gone; the load-bearing mapping stays as "`RestoreError::Preflight` covers every
rejection before the first write, whatever its cause". An implementation may now
carry any number of additional variants so long as pre-write rejections use
`Preflight`. `Write`'s clause is spelled `RestoreError::Write { .. }` for
symmetry. The description is 488 words.

Exact version-30 artifact identifiers:

- `meta.md`: `8c4027f945b41de4c185be541cfec1d0200426ccd59824df6493519314a2243b`
- `test.patch`: `bdd1fc02feaedb64c53cba3fbb10206903d43fa212c40c00098ad934740da096`
- `solution.patch`: `f1a7100a58f3c2b52a0bb12698166cc40f1d9d1e831da1a1888fab462b130ad6` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 28/28 on arm64 and amd64 plus 83/83 pre-existing on
arm64 with the test patch alone. Replaying the five `agent-runs7`
implementations gives 4/5, unchanged since version 28, so the task is still
measured as far too easy and still needs a new lever.

## Version 31 codec-freedom and pattern-clarity gate

Two findings. One is a real over-specification and is fixed. The other rests on
a mistaken premise about Rust patterns, and is addressed by making the code
prove the point rather than by changing the behaviour.

**The codec mandate (HIGH).** The description said "Encode with postcard". The
reviewer is right that the contract only needs deterministic bytes, full
consumption, and version rejection. It is now "the encoding is yours to choose",
with the three properties stated directly: encoding refuses a snapshot that does
not validate, decoding consumes the entire input and rejects anything that fails
validation, and decoding returns what was encoded.

That alone would have been unfair, because one test did depend on the codec:
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` built its
unknown-version input with `postcard::to_allocvec`, since `to_bytes` validates
and so cannot emit one. The check is now codec-free. It asserts that an unknown
version fails `validate` and that `to_bytes` refuses it, which is the same
guarantee reached without naming a format. No test now assumes anything about
the snapshot encoding; the only remaining `postcard` uses in the suite decode
wire frames, which is the pinned protocol and not the snapshot.

**The `Preflight { .. }` claim (FAIL, nine tests).** The premise is incorrect.
`Enum::Variant { .. }` is Rust's struct-pattern form and the language applies it
to tuple variants as well, whose fields carry the positional names `0`, `1`, and
so on. One arm therefore matches `Preflight(SnapshotError)` and
`Preflight { source }` alike, and a tuple-variant solution compiles and passes.
This is not incidental: version 27 changed these sites from `Preflight(_)` to
`Preflight { .. }` precisely because the earlier form did reject a struct
variant, which is what stopped `agent-runs7`'s run 5 from compiling. Replaying
that run, which declares `Preflight { source }`, passes; a locally written tuple
variant passes too.

Rather than argue the point in a document nobody reads at review time, the code
now carries it. All nine sites route through one helper, `rejected_before_writing`,
whose doc comment explains the pattern, and a graded test,
`snapshot_preflight_pattern_matches_either_variant_shape`, declares both shapes
locally and asserts the shared pattern accepts each. If the claim were ever
false, that test fails rather than a solution.

Neither change touches a discriminator. Replaying the five `agent-runs7`
implementations gives 4/5, unchanged since version 28.

Exact version-31 artifact identifiers:

- `meta.md`: `773bf60fb0bae15053db0ca69378d3479d6a133dd9c86decc2418b62ec1c400b`
- `test.patch`: `49bd3e24cae7a3950ede019abcd7675033b8b80e996d7d3e28d6ad9874537fc1`
- `solution.patch`: `f1a7100a58f3c2b52a0bb12698166cc40f1d9d1e831da1a1888fab462b130ad6` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 29/29 on arm64 and amd64. The description is 502
words. The reference still uses postcard, which is now its own choice rather
than a requirement, so `SnapshotError::Codec(postcard::Error)` is a reference
detail no test inspects.

## Version 32 trajectory-informed hardening gate

`agent-runs8` is the first batch that both compiles everywhere and passes: five
Nova runs against version 31, 4/5, with the only failure a `step_by(0)` panic on
the zero-macro edge. The platform reports 80% against a 50% cap. Every run's
evaluation, JUnit, patch and trajectory was read before changing anything, and
this time there are five complete, legitimate implementations to compare.

All five share one architecture: export a baseline, diff it, then write stage by
stage, discovering problems as they go. That is the assumption to break, and the
review handed over the exact seam by filing S1 against the reference itself.

**The lever: a write the host can rule out before sending it.** `split_pages`
returns `RynkHostError::Encode` when an item cannot fit the target's frame, and
`send_frame` rejects an oversized request locally before it reaches the link, as
the repository's own `oversized_request_rejected_locally` shows. Both verdicts
need no device. A streamed restore therefore writes earlier stages, then trips
over a later one it could have ruled out at the start, leaving the device
changed. My own reference did exactly this, which is what S1 reported.

This was not previously stated, so the description now says it: every request
restore needs must be encodable within the target's advertised frame, and the
host has to find that out before sending anything. The reference plans all
keymap, combo and Morse pages up front and reports a shortfall as
`SnapshotError::UnencodableWrite` inside `Preflight`.

The oracle is exact and needs no new fixture machinery. Measured request sizes
for `multi_stage_snapshot_fixture` are keymap page 6, encoder write 5, combo
page 9, and every read 3. A target advertising `max_payload_size = 8` therefore
admits reads, the keymap and the encoders, but can never carry a combo write. A
planning restore returns `Preflight` untouched; a streaming one writes two
stages first and fails both `rejected_before_writing` and `assert_no_mutation`.

**Measured effect.** Both saved batches were replayed against the hardened
suite, each solver's own tests excluded so only the hidden ones judge it.

| Batch | Against its own version | Against version 32 |
|---|---|---|
| `agent-runs7` | 0/5 (v27, all harness faults) | 0/5 |
| `agent-runs8` | 4/5 (v31) | 1/5 |

Every failure is `snapshot_restore_plans_every_write_before_touching_the_device`,
plus the pre-existing faults of two runs: `agent-runs7`'s run 4 still mismaps
pre-write rejections, and `agent-runs8`'s run 4 still panics on the zero-macro
edge. Nothing else regressed, which is the point of replaying: the serde bound
and the widened `to_bytes` coverage pass for all ten.

`agent-runs8`'s run 2 passes everything, so the requirement is reachable without
being told, which protects the Solvable gate.

1/10 is a floor, not a forecast. All ten implementations predate the sentence
that now states the requirement, so a solver that reads it will do better; the
true rate lies between 10% and the 80% the batch measured. That is the honest
range, and it is why the next batch is worth spending.

**Two coverage findings, both accepted.** The surface crate exercised methods
without demanding serde, so a hand-rolled encoder satisfied it; it now asserts
`Serialize + DeserializeOwned` for `ConfigurationSnapshot` and
`SnapshotGeometry` through a bound that names no format, verified to fail when
the derives are removed. And `to_bytes` was only shown to refuse an unknown
version; it is now required to refuse a short keymap, an out-of-range default
layer, an out-of-range combo layer and an oversized Morse map as well.

The zero-macro edge coverage the review asked to keep is untouched.

Exact version-32 artifact identifiers:

- `meta.md`: `5eec8fc4f29a637b1fde6e2813f59c4679357af5f37b541183cb236072977f54`
- `test.patch`: `bb0ca41ef7f4ac93d5a109997b97bcf9c7676c259a6d1763bfa72989d0437d85`
- `solution.patch`: `08f46b3bbea3d34e7c043c9b2c367d5eeb499a6b0c6780e172de62e083e3536a`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 30/30 on arm64 and amd64, plus 83/83 pre-existing on
arm64 with the test patch alone. The description is 513 words. The
false-positive audit remains skipped and no cold solver was run.

## Version 33 within-stage-order and unstated-predicate gate

Eight findings across three classes, all accepted. None touches the version-32
lever, and re-replaying both batches after the changes gives the same 1/10, so
the relaxations removed coupling without blunting anything.

**Within-stage request order (five tests).** The suite compared `key_writes`,
`encoder_writes`, `combo_writes`, `fork_writes`, `morse_writes` and
`macro_writes` as ordered sequences, which pins ascending order inside a stage.
Only stage order is stated, and the repository argues the other way: `write_all`
splits a resource into pages and dispatches up to `MAX_IN_FLIGHT` of them
concurrently, so a serial ascending order is a scheduling choice, not observable
behaviour. Writes inside a stage address disjoint entries, so order carries no
meaning. All twenty comparisons now route through `touched`, which sorts before
comparing. The entries, coordinates, chunk bytes and exactly-once retry
guarantees are all unchanged; only sequence is no longer required.

**`SnapshotGeometry` serde bound.** The prompt requires serde of
`ConfigurationSnapshot`, and a manual implementation need not make the geometry
independently serializable. The bound is dropped; `ConfigurationSnapshot`'s
remains, and is still verified to fail when its derives are removed.

**Unstated unsupported-version rule.** This one is a regression I introduced.
Version 31 removed the postcard sentence, which had carried "reject unknown
versions", and the replacement never restated it, so two tests rested on a
predicate the description no longer contained. Validation now explicitly rejects
any version other than `SNAPSHOT_VERSION`, which restores the contract those
tests were always written against rather than relaxing them.

The description is 496 words, back under the 500-word target.

Exact version-33 artifact identifiers:

- `meta.md`: `c932c85d24de71075634c27677cf7c13deca3d6c0e86ce88c894dfff5c9356a2`
- `test.patch`: `e699691a208238cc6db3c31239ea2ed6542cea870622304c8301f0cdf2cd1003`
- `solution.patch`: `08f46b3bbea3d34e7c043c9b2c367d5eeb499a6b0c6780e172de62e083e3536a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 30/30 on arm64 and amd64, plus 83/83 pre-existing on
arm64. Replaying both saved batches still gives `agent-runs7` 0/5 and
`agent-runs8` 1/5, every failure the planning check. A mutant that classifies a
locally unencodable page as `Write` still fails that check alone.

## Version 34 same-stage concurrency gate

Two findings, both accepted, and one environment question answered with
measurement rather than opinion.

**Exact same-stage request count.** `assert_restore_write_failure` required the
failed stage to have sent exactly `failed_request_index` requests. The stated
rule is only that no later stage is attempted, and the repository argues against
the stricter reading: `write_all` builds `MAX_IN_FLIGHT` lanes and joins them, so
an implementation may legitimately have a second disjoint page in flight when
the first rejection arrives. It now asserts that the rejected request was
reached, `count >= failed_request_index`, and that every recorded write belongs
to the failed stage or an earlier one. That is the stated rule stated exactly.
Verified still sharp: hoisting the default-layer write ahead of the keymap makes
it fail with "Keymap failure did not stop later stages: [DefaultLayer, Keymap]".

**Optional batching guidance.** "One request may cover a run of consecutive
differing entries, as many as you like" said nothing a requirement depended on,
now that within-stage packing and order are both unconstrained. Removed. The
description is 481 words.

Replaying both batches gives an unchanged 1/10, so neither change touched the
planning lever.

**The Harbor oracle timeout.** Nothing in the artifacts explains it, and the
same submission classified cleanly: the reported pass-to-pass list is exactly 83
entries, matching `./test.sh base`, and the fail-to-pass list is exactly the 30
tests the new lane runs. The five `rynk::api.tests` entries in that list are
pre-existing at the pinned commit, not something either patch adds. So the
environment did build and run; `EnvironmentStartTimeoutError` came from a
separate start step.

The one factor under our control is image size, and it is worth reducing on the
evidence below. The image is about 12.2 GB, of which 5.3 GB is Cargo target
directories, 1.7 GB of that incremental caches that a fresh container cannot
use. Deleting all three target directories and running the base lane cold
recompiles 272 crates in 27 seconds, because the registry cache, which is what
actually makes the offline lanes work, is only 1.3 GB and stays. Discarding the
target directories in the same layer that builds them would take the image to
roughly 7 GB for about 27 seconds per lane.

That change is not made here. It rewrites the Dockerfile, so it invalidates the
retained pristine images and needs a networked rebuild plus full re-verification
on both architectures, which is a larger step than this review asked for. The
measurements are recorded so the decision can be taken deliberately.

Exact version-34 artifact identifiers:

- `meta.md`: `d1daddb41c3cf37e7fb33ffc8147743f6e9834f14f7dc745597723ad8f2ebf75`
- `test.patch`: `b667f762480883515ba84ca42727d69f4f3ec05c5390b83249646bf0a7726031`
- `solution.patch`: `08f46b3bbea3d34e7c043c9b2c367d5eeb499a6b0c6780e172de62e083e3536a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 30/30 on arm64 and amd64, plus 83/83 pre-existing on
arm64 with the test patch alone.

## Version 35 type-arity and argument-ownership gate

Four findings across two classes, both accepted. Neither touches the planning
lever; both batches replay at an unchanged 1/10.

**`Option<SnapshotRead>` pinned type arity (three tests).** The task requires an
item named `SnapshotRead` to exist and says nothing about its shape, but a type
expression like `Option<SnapshotRead>` additionally demands it be nongeneric and
lifetime-free. The comment in the surface crate claimed to be shape-free while
doing exactly that. All three sites now name the item by import under
`#[allow(unused_imports)]`, which asserts only that the name is exported and
reachable, and in the surface crate that it is reachable with `alloc` on and
`std` off. `RestoreStage`, `SnapshotError` and `RestoreError` moved to the same
treatment in the surface crate for the same reason, although only `SnapshotRead`
was reported. The native suite still uses `RestoreStage::Keymap` and friends,
which is fair because the task lists those eight variants by name.

Verified the weaker form still gates: with the module and its re-exports gated
on `std`, the surface crate fails with unresolved imports for all seven items
plus missing methods, and the serde bound still fails when the derives go.

**Borrowed restore arguments.** The surface crate called both restore methods
with `&ConfigurationSnapshot` while the task said nothing about ownership, and
the neighbouring API commonly takes composite arguments by value. This one
cannot be relaxed in the tests: the retry test calls `restore_configuration`
twice with the same snapshot, so the suite depends on borrowing whatever the
surface crate does. The honest fix is to state it, and the description now says
the two restore methods borrow the snapshot, with the reason a caller may retry
with the same one. That is a signature detail the contract genuinely rests on,
which is the case for naming it. The description is 497 words.

Exact version-35 artifact identifiers:

- `meta.md`: `b0d44fbe92f670c4f3a52a3910b01af1f7653fce9de1c1d1328c9e64abd9e4bf`
- `test.patch`: `4a514852baa2f252a42f9509e16219b6f74bc2f8dae9a7bbddbb24bc17055642`
- `solution.patch`: `08f46b3bbea3d34e7c043c9b2c367d5eeb499a6b0c6780e172de62e083e3536a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 30/30 on arm64 and amd64, plus 83/83 pre-existing on
arm64 with the test patch alone.

## Version 36 reference-completeness gate

A package review scored Comprehensiveness 1/3 and Code Quality 2/3 on two
implementation gaps, both real, both in the reference rather than the contract.
The description is unchanged.

**Export required bulk transfer.** Version 29 removed the bulk precheck from
`export_configuration`, but the body still read the keymap, combos and Morse
definitions through `read_all_keymap`, `read_all_combos` and `read_all_morses`,
which call `get_*_bulk` and so are gated on `bulk_transfer_supported`. Removing
the precheck therefore changed nothing: a non-bulk device still failed, just
later and with a different error. The task makes whole-resource bulk a restore
precondition only. Export now branches: the crate's pagers when bulk is
advertised, and `get_key`, `get_combo` and `get_morse` per entry when it is not,
in three small helpers.

**Only paged writes were preflighted.** `plan_pages` covered keymap, combo and
Morse pages, but `set_encoder`, `set_fork`, `set_macro`, `set_behavior` and
`set_default_layer` were not measured, even though `send_frame` enforces
`max_payload_size` for every request alike. A frame too small for a fork write
would surface mid-restore after earlier stages had already been applied, which
is precisely what the stated rule forbids. Every diff is now computed before any
planning, and every single-entry request is measured with `fits_frame`, which
applies the same budget `split_pages` uses for pages.

The planning test grew a second case to prove it. Request sizes for
`multi_stage_snapshot_fixture` are keymap page 6, encoder 5, combo page 9, Morse
page 7 and fork 15, so `max_payload_size = 8` stops a paged stage while 12 lets
every paged stage through and stops the single-entry fork write, which no pager
ever measures. Both budgets must reject before the device is touched.

Verified by mutation: reverting export to the pagers fails a non-bulk export,
and deleting the single-entry checks fails the fork case with "a write the
target's frame cannot carry is a preflight failure".

**A test deliberately withdrawn.** A test that exported from a non-bulk device
was written, passed against the fixed reference, and then removed after
measurement. It fails all ten saved implementations, including
`agent-runs8`'s run 2, which is the only one that passes everything else and so
is the sole existence proof for the Solvable gate. Replay went 1/10 to 0/10 with
it and back to 1/10 without.

The review's finding was against the implementation, and the implementation now
honours the contract, so the gap is closed either way. Adding a second lever
that no observed implementation survives is a different decision from fixing a
defect, and it is not one to take blind. If a probe batch comes back too easy,
this is the first coverage to restore: the test is recorded here, the reference
already satisfies it, and it costs nothing to add back.

Exact version-36 artifact identifiers:

- `meta.md`: `b0d44fbe92f670c4f3a52a3910b01af1f7653fce9de1c1d1328c9e64abd9e4bf` (unchanged)
- `test.patch`: `c6f71fc95776af7a570f8645f99978921c846b9f9d06e6755a269b71a590fd18`
- `solution.patch`: `fa2f3ab6b14095ac3e7f3002b161dd1950de319a5e70f19e7633d2d2e9ccb9e6`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 30/30 on arm64 and amd64, plus 83/83 pre-existing on
arm64. Replay is `agent-runs7` 0/5 and `agent-runs8` 1/5, unchanged since
version 32.

## Version 37 trajectory-informed gate on `agent-runs9`

`agent-runs9` is the largest batch so far: eleven runs against version 36, one
of which (`Nova_Nova_3`) aborted with no results. Of the ten that completed,
eight passed, so version 36 measured 80% against a 50% cap. Every run's
evaluation, JUnit, log, patch and trajectory was read before changing anything.

Both failures were genuine, and one of them corrects an earlier reading. The
`snapshot_surface_builds_with_alloc_without_std` failures looked at first like
harness trouble, because the visible stderr begins "Blocking waiting for file
lock on package cache" and then a long cold compile. The real error is further
down the log: `error[E0425]: cannot find type Box in this scope` at
`rynk/src/snapshot.rs:152`, from a `TargetInvalid(Box<SnapshotError>)` variant
declared without importing `alloc::boxed::Box`. Those implementations genuinely
do not build with `alloc` on and `std` off. The lock lines are noise from the
nested Cargo invocation, not the cause. `Nova_Nova_11` additionally wrote a
two-byte final macro chunk that ran a byte past the snapshot's macro space.

**The withdrawn export test is restored.** Version 36 withheld it after
measuring that it failed all ten then-saved implementations. A later review
flagged its absence as a HIGH false-positive risk, which settles the question:
a submission that cannot export from a non-bulk device would pass unnoticed.
The asymmetry is now stated as well as tested, so it is discoverable rather than
inferred from the absence of a requirement: restore "also needs whole-resource
bulk support, which export does not".

Measured against the ten completed `agent-runs9` implementations, the export
test costs two runs, taking 8/10 to 6/10. Both failures are real: `Nova_Nova_5`
and `Nova_Nova_7` reach for the crate's pagers, which are gated on the
capability.

**Two candidate levers were tried and neither discriminated.** Both are recorded
because a negative result is worth as much as a positive one here.

| Candidate | Rationale | Caught |
|---|---|---|
| Resources the device does not have: zero encoders, combos, forks and Morse slots, then that snapshot onto a board that has them | Same class as the `step_by(0)` zero-macro crash that failed a run in `agent-runs8` | none of 10 |
| A macro chunk wider than the whole macro region, and a snapshot with no macro region onto a board that has one | Same class as `Nova_Nova_11`'s overlong final chunk | none of 10 |

Both are kept as regression coverage, since each guards a class that has bitten
before, but neither is a difficulty lever for this population.

**Where difficulty actually comes from.** Every discriminating check in this
batch is the same shape: the crate's convenience helper does not cover this
configuration, so write the fallback. `alloc` without `std` caught two;
export without bulk caught two. Extent edge cases caught nobody. That is the
family worth mining, and the obvious unmined member is restore without bulk
transfer, which the contract currently forbids rather than requires.

Version 37 therefore stands at 6/10, still above the cap. It is not hardened
enough, and the next step is a contract change rather than another test, so it
is left for a deliberate decision rather than taken here.

Exact version-37 artifact identifiers:

- `meta.md`: `d1741b1e2b937e589574a4d83a3ad482e331c8e63ca9a58d7ef7baf977cdfb89`
- `test.patch`: `a476799f1ce4a9ab56c6e3f8fe90887e9d128aaa4bc3ab18b7ad63e594347ca9`
- `solution.patch`: `fa2f3ab6b14095ac3e7f3002b161dd1950de319a5e70f19e7633d2d2e9ccb9e6` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

The WASM test module comment no longer addresses the grader. Reference
verification is 33/33 on arm64 and amd64, plus 83/83 pre-existing on arm64. The
description is 495 words.

## Version 38 value-trait gate

Six runtime tests compare whole `ConfigurationSnapshot` values with
`assert_eq!`, which silently requires `PartialEq` and `Debug`. The description
named only serde's `Serialize` and `Deserialize`, and the pinned repository has
no `ConfigurationSnapshot` to establish anything further, so a solution could
satisfy every stated behaviour and still fail to compile the suite.

The review offered two remedies. Amending the description is the better one.
Rewriting six tests to compare field by field would be markedly more verbose and
would lose what whole-value equality actually buys: a field added to the record
but forgotten in an assertion silently stops being checked, whereas
`assert_eq!` on the whole snapshot cannot miss one. `Debug` and `PartialEq` are
also the conventional derives for a value type of this kind, so requiring them
costs a solver a word in a derive list.

The description now reads "implements serde's `Serialize` and `Deserialize`,
plus `Debug` and `PartialEq`". Only those two are named, not `Eq`, because
`assert_eq!` needs no more; the reference derives `Eq` as well, which remains
its own choice. The description is 497 words.

`test.patch` and `solution.patch` are byte-for-byte identical to version 37:

- `test.patch`: `a476799f1ce4a9ab56c6e3f8fe90887e9d128aaa4bc3ab18b7ad63e594347ca9`
- `solution.patch`: `fa2f3ab6b14095ac3e7f3002b161dd1950de319a5e70f19e7633d2d2e9ccb9e6`

Version 37 verified that exact pair at 33/33 on arm64 and amd64 and 83/83
pre-existing on arm64, and a container run is deterministic given the same image
and the same two patches, so it was not repeated. The reference was re-run
locally and is green.

Exact version-38 artifact identifiers:

- `meta.md`: `c09b3c1ffa26871696b348dde0f471a34ded5c6adc1fb637bd2650b46a1eac96`
- `test.patch`: `a476799f1ce4a9ab56c6e3f8fe90887e9d128aaa4bc3ab18b7ad63e594347ca9` (unchanged)
- `solution.patch`: `fa2f3ab6b14095ac3e7f3002b161dd1950de319a5e70f19e7633d2d2e9ccb9e6` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

The difficulty position is unchanged from version 37: 6/10 measured on
`agent-runs9`, above the 50% cap, with restore without bulk transfer recorded as
the candidate next lever and awaiting a decision.

## Version 39 WASM boundary gate

`agent-runs10` returned 5 passes in 10 runs against version 38. That is exactly
the 50% cap, but one of the five failures is a harness fault of mine, and the
number does not survive fixing it.

`Nova_Nova_3` exposed `export_configuration_snapshot` as returning a
`js_sys::Uint8Array`. The hidden WASM test called the Rust method directly and
then used the result as a `Vec<u8>`, so the test crate failed to compile. The
platform classified it `FAIL_TEST_MISMATCH` under category `research`, with
`was_mentioned_in_description: false` and `was_inferable_from_codebase: false`,
and that classification is correct. wasm-bindgen surfaces a Rust `Vec<u8>` and a
`js_sys::Uint8Array` as the same JavaScript typed array, so the two choices give
browser callers an identical API, and the task asks only for byte-oriented
methods. The repository supports both readings: the WASM transport uses
`Uint8Array` while the typed client methods use `Vec` for byte collections.

The restore half of the test was already immune, because it goes through
`Reflect` and a JS `Function`. Only the export half called into Rust. Export now
goes through JS too, resolving the promise and reading the result as a
`Uint8Array` before converting to bytes, which is both representation-agnostic
and closer to what a browser actually does.

Verified three ways in the image: the `Vec<u8>` reference passes, a wrapper
edited to return `js_sys::Uint8Array` passes, and a wrapper whose restore method
returns an error still fails, so the check has not been softened into a
formality.

Replaying `Nova_Nova_3` against the repaired suite passes 36 of 36. The true
difficulty of version 38 was therefore 6/10, not 5/10, and version 39 measures
6/10 on `agent-runs10`.

The other four failures are genuine and are the discriminators working:
`Nova_Nova_2` and `Nova_Nova_7` do not compile with `alloc` on and `std` off,
missing `ToString` and `vec!` imports; `Nova_Nova_8` uses the source encoder
stride on a larger target and writes an encoder the snapshot never described;
`Nova_Nova_9` writes an extra macro byte on a larger target.

Exact version-39 artifact identifiers:

- `meta.md`: `c09b3c1ffa26871696b348dde0f471a34ded5c6adc1fb637bd2650b46a1eac96` (unchanged)
- `test.patch`: `3e6e0f13c96a1f64cdf72754c4e0e6cdc3b9ea23915f080737e624aa38763e34`
- `solution.patch`: `fa2f3ab6b14095ac3e7f3002b161dd1950de319a5e70f19e7633d2d2e9ccb9e6` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Two consecutive batches now put the task at 60%: `agent-runs9` at 6/10 after the
export test, and `agent-runs10` at 6/10 after this repair. That is a consistent
measurement across twenty runs and it is above the cap. The candidate lever
remains restore without bulk transfer.

## Version 40 hardening gate, and what hardening by testing cannot reach

Version 39 measured 6/10 on `agent-runs10` after the WASM repair, matching
`agent-runs9`. Two batches, twenty runs, the same 60% against a 50% cap. This
gate records the attempt to close that and the measurement that bounds it.

**The lever taken: restore no longer requires bulk transfer.** The contract now
reads that neither direction needs it, and where a device does not advertise it
both sides address entries one at a time. This is the symmetric completion of
the export rule and the protocol supports it directly through `set_key`,
`set_combo` and `set_morse`. `snapshot_unsupported_bulk_is_a_no_write_preflight_error`
is replaced by `snapshot_restores_to_a_device_without_bulk_transfer`, which
requires a complete sparse restore over per-entry setters with no bulk command
used. The reference branches its planning and its writes on the capability, and
the frame check covers the per-entry requests as well. A mutant that pages
unconditionally fails the new test alone.

**What the measurement says about it.** All twenty saved implementations fail
the new test, because none has that path. That number carries no information:
they predate the rule. The informative comparison is the export precedent.
`agent-runs9` ran against a description that did not state the export
asymmetry and two of ten missed it; `agent-runs10` ran against one that did,
and none of ten missed it. A stated rule of this shape gets satisfied. The
honest expectation for this lever is therefore small, not the 20/20 the replay
shows.

**Three probes that found nothing.** Each was written, run against the saved
implementations, and kept only for regression value:

| Probe | Caught |
|---|---|
| Resources the device does not have at all | none of 10 |
| Macro region smaller than a chunk, and absent entirely | none of 10 |
| Each geometry dimension grown on its own, so no stride hides behind another | none of 6 |

The last was aimed squarely at the class that failed `agent-runs10`'s
`Nova_Nova_8`, an encoder written at the source stride. The six implementations
that pass everything else handle every variant of it.

**The conclusion this gate reaches.** Difficulty here does not respond to more
tests. Two things discriminate across batches, and both already exist:

- the `alloc`-without-`std` surface, which failed two of ten in `agent-runs9`
  and two of ten in `agent-runs10`; and
- geometry and extent precision, one or two of ten in each.

Neither is learned away between batches, because both are slips rather than
missed requirements. Everything else that has been added either gets satisfied
once stated or was already handled.

The one lever with evidence behind it that has not been pulled is to make the
`no_std` check stricter by building the surface crate for a real bare-metal
target instead of the host. That is the single most reliable discriminator in
the record, and a host build only catches what feature unification does not
paper over. The image carries `aarch64-unknown-linux-gnu` and
`wasm32-unknown-unknown` only, so it needs `rustup target add thumbv7em-none-eabihf`
in the Dockerfile and a rebuild.

That rebuild is also the fix already measured for the Harbor
`EnvironmentStartTimeoutError`: discarding the Cargo target directories in the
layer that creates them takes the image from about 12.2 GB to roughly 7 GB for
about 27 seconds per lane. One rebuild would serve both, and it is the
recommended next step rather than another test.

Exact version-40 artifact identifiers:

- `meta.md`: `42f20a769fad5fbaf2bcd7662fa3261b4b3fb79229c6b15f6a420072baf1d0ea`
- `test.patch`: `448c68eb71151e76176e783be68d1671498e2a8b6c6a8dc6a9056ac3a0db46a3`
- `solution.patch`: `5e732aed31d46e6baff1877e7b953931959cef52528e863a152463cf4749fc42`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 34/34 on arm64 and 83/83 pre-existing on arm64. The
description is 499 words.

## Version 41 trajectory-informed gate on `agent-runs11`

`agent-runs11` returned 5 passes in 5 runs against version 40. Nothing caught
anyone: not the `alloc`-without-`std` surface, not geometry precision, not the
new per-entry restore. The task was saturated.

Version 40's gate concluded that difficulty does not respond to stated rules,
because a rule that is merely written down gets satisfied, and that the probes
which could be measured caught nobody. That left one place to look: something
already governed by a stated rule but easy to get wrong, discoverable only by
reading the types being serialized.

**The lever.** `rmk-types` gives `KeyAction` a hand-written `PartialEq` with a
comment explaining why: `TapHold(Action, Action, u8)` carries a morse-profile
index that equality deliberately ignores, because the profile is per-key timing
config rather than part of the key's identity. The index is still serialized.
Measured directly, `TapHold(User(3), No, 0)` and `TapHold(User(3), No, 7)`
compare equal and encode to `[4, 19, 3, 0, 0]` and `[4, 19, 3, 0, 7]`.

The description has required equal snapshots to produce equal bytes since
version 1. Until now it illustrated that with `Morse.actions` insertion order
and every implementation canonicalized exactly that one case, because it was the
case named. The clause now states the rule in general and says the Morse map is
an instance and not the whole of it, so the remaining instances are found the
same way the Morse one was: by reading the types. The reference normalizes the
ignored index across keymap, encoders, combos and forks.

**Measured effect: 5 of 5.** Every implementation in the batch that had just
scored 100% fails
`snapshot_canonicalizes_actions_equality_treats_as_the_same`. That is the first
lever in this problem's history to catch a whole batch that passed everything
else.

This one should also survive being stated, unlike the levers before it. The rule
it enforces was always stated and always tested; what it demands is noticing
that a type's equality is not structural. That is the same class as the
`alloc`-without-`std` check, which has failed two of ten in two separate batches
without being learned away, because both are slips rather than missed
requirements. The wording deliberately warns that more cases exist without
listing them, which keeps the check discoverable and so protects the Solvable
gate: a solver who greps the serialized types for a custom `PartialEq` finds it
immediately, and the fix is a handful of lines.

Exact version-41 artifact identifiers:

- `meta.md`: `6829568cb30b78d1fb0634b222ad6c6b4a300fe3c9172a9e9bb6173ae69c3a6a`
- `test.patch`: `95792ad2c18a2ce41cd33199bae3f6bd8254b714eb7b93ba8b2514815e612e61`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 35/35 on arm64, plus 83/83 pre-existing. The
description is 501 words. The bare-metal `no_std` target and the image slimming
remain the recorded next step, both served by one Dockerfile rebuild.

## Version 42 setup-trait gate

Two hidden setup lines imposed traits the task never requires. Both are in test
scaffolding, so behaviour and the new lever are untouched.

`snapshot_canonicalizes_actions_equality_treats_as_the_same` built its second
fixture with `first.clone()`, requiring `ConfigurationSnapshot: Clone`. The task
names `Serialize`, `Deserialize`, `Debug` and `PartialEq` and no more, and
because both restore methods borrow, a caller never needs to clone. The second
fixture is now built from `snapshot_fixture` independently.

`grown_target_state` and `snapshot_restore_maps_each_grown_dimension_independently`
moved `snapshot.geometry` out of a borrowed snapshot, requiring
`SnapshotGeometry: Copy`. A third site did the same:
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` passed the
geometry by value into its mutator table, whose signature was
`fn(&mut ConfigurationSnapshot, SnapshotGeometry)`. All three now borrow, and the
table takes `&SnapshotGeometry`. The review reported two; the third was found by
grepping for the same shape and is fixed with them.

Verified rather than assumed. Stripping `Clone` from `ConfigurationSnapshot` and
`Copy`/`Clone` from `SnapshotGeometry` in the reference leaves fifteen compile
errors, and every one points into `rynk/src/snapshot.rs`, which uses both
internally by its own choice. None points into `rynk/src/driver/tests.rs`, so the
hidden suite no longer imposes either trait.

The version-41 lever is unaffected: all five `agent-runs11` implementations still
fail `snapshot_canonicalizes_actions_equality_treats_as_the_same`.

Exact version-42 artifact identifiers:

- `meta.md`: `6829568cb30b78d1fb0634b222ad6c6b4a300fe3c9172a9e9bb6173ae69c3a6a` (unchanged)
- `test.patch`: `b346f6c8c7183220b08c95c2d4ae824357b3c59f0ed2f500baec87e72c546bcb`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 35/35 on arm64, plus 83/83 pre-existing.

## Version 43 canonicalization-coverage and presentation gate

The review reports the task passing: "no critical fixes are needed", failures
none, uncertains none, and a 30% pass rate, inside the 50% cap and near the
p ~= 0.28 target. Two notes were actionable and one was advisory.

**Incomplete canonical-equality coverage.** The canonicalization test varied the
ignored `TapHold` profile index in the keymap and encoders only, so a
canonicalizer that knew about those two tables and nothing else would pass, even
though `Combo` nests key actions in `actions` and `output` and `Fork` nests them
in all three branches. The requirement is over the record, not over a table.
The test now varies the index in a combo's actions and output and in a fork's
trigger and both outputs as well. The reference already normalized all four
locations, so only the test moved. Verified by deleting the combo and fork
normalization from the reference: the test fails, so the location-specific
loophole is closed.

**Presentation density.** Answered by reorganization alone. The three longest
paragraphs each carried two subjects: the codec methods together with the
determinism rule, geometry sizing together with the capability requirements, and
the preflight guarantee together with the plan-ahead rule. Each is now split at
that seam. The text is word-for-word identical, confirmed by diffing both
versions with whitespace collapsed; only the paragraph breaks changed. The
longest paragraph falls from 56 words to 42 and the count rises from 16 to 19,
still 501 words. No requirement was condensed away, which matters here because
version 31 lost the unsupported-version rule to exactly that kind of edit.

**Difficulty, advisory.** The note observes that the 70% failure rate overstates
core difficulty because most failing agents completed the feature and missed one
narrow canonicalization or macro edge case. That is a fair description and no
change is made for it. The concentration is the intended design: versions 37
through 40 established by measurement that broad architectural requirements get
satisfied once stated, and that the only checks which survive a batch are the
ones catching slips rather than missed requirements. A pass rate carried by
subtle-but-stated invariants is what that evidence predicts, and the rate now
sits in band.

Exact version-43 artifact identifiers:

- `meta.md`: `2650b1820c2b8392c445b28956fdd9ec75fbd8df9e5a3037ad46bf9444953c7a`
- `test.patch`: `1896db3fc1e785d7369c6187b65218df1889945a808e1cdeca7bc7c6f0dbe147`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 35/35 on arm64, plus 83/83 pre-existing.

## Version 44 nested-build contention gate

`agent-runs12` ran ten runs against version 43 and returned 3 passes, a 30% rate
inside the 50% cap and close to the p ~= 0.28 target. Every failure is a real
implementation defect and none is a harness fault:

| Cause | Runs |
|---|---|
| Equal snapshots with differing ignored `TapHold` profiles encode differently | 6 |
| A larger target's final macro chunk sent as `[5, 238]` instead of the short `[5]` | 1 |
| `step_by(0)` panic on a zero-sized macro region, natively and again under WASM | 1 |
| Passed everything | 3 |

The version-41 lever accounts for six of the seven failures, which is the
calibration working as designed.

`Nova_Nova_8`'s WASM failure was checked rather than assumed, because its log
opens the same way a harness fault would: three "Blocking waiting for file lock
on package cache" lines and one on the artifact directory, then a cold compile.
The real cause is further down, a `core::iter::adapters::step_by::StepBy::new`
panic inside the WASM runtime, which is the same zero-chunk defect that failed
the native test. Genuine.

The contention is real even though it did not cause a false negative here.
`snapshot_surface_builds_with_alloc_without_std` and
`snapshot_wasm_client_round_trips_under_node` both shell out to Cargo against
the same standalone workspace, so nextest running them together made each wait
on the other's package-cache and artifact-directory locks, and that build took
3m36s. Two changes remove it. The nested builds now get their own
`CARGO_TARGET_DIR`, named per package, which costs almost nothing because they
target different architectures and share few artifacts. A nextest test group
also caps the pair at one thread, so they never run at once.

Measured in the image: the new lane logs zero "Blocking waiting" lines and
finishes in 33 seconds. Neither change touches behaviour, so difficulty is
unaffected and `meta.md` and `solution.patch` are untouched.

Exact version-44 artifact identifiers:

- `meta.md`: `2650b1820c2b8392c445b28956fdd9ec75fbd8df9e5a3037ad46bf9444953c7a` (unchanged)
- `test.patch`: `4fa8fabc38a9e0942e9bed385da50728e447d8cdee9f7b4d9233a06d1836c7e3`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 35/35 on arm64 and 83/83 pre-existing on arm64.

The image slimming remains recorded and undone. With the pass rate now in band,
adding the bare-metal `no_std` target alongside it would harden further and is
no longer wanted; the slimming alone still stands as the answer to a repeat
`EnvironmentStartTimeoutError`, and it needs a networked rebuild.

## Version 45 WASM argument gate

The finding is correct and the hole was wider than it reads. The WASM runtime
test called `restore_configuration_snapshot` with the board's own exported
bytes, awaited success, and then checked only that the scripted responses were
consumed and at least ten requests had been sent. Both of those are already
satisfied by the export half. Restoring a board's own configuration also asks
for no writes, since nothing differs. A wrapper that ignored its argument
entirely and returned `Ok(())` passed.

Two additions close it, and the second is the one that matters.

Bytes that are not a snapshot must be refused: the test now calls the method
with three junk bytes and requires the promise to reject. That alone proves the
argument is decoded rather than discarded.

Applying is proved separately, because decoding is not enough. The test decodes
the exported record, changes one key action to `KeyAction::Morse(7)`, re-encodes,
asserts the bytes differ from the exported ones, and restores that instead. The
board still holds `KeyAction::No`, so the only way to satisfy the call is to
decode these bytes and write what they say. The scripted link records every
frame it is sent, and a new `snapshotSentFrame` helper lets the test assert that
a write carrying that exact action was among them, accepting either
`SetKeyAction` or `SetKeymapBulk` since the endpoint is the implementation's
choice. Alternatives answer both.

Verified by mutation: a wrapper rewritten to ignore `bytes` and restore whatever
it had just exported fails the test, where before it would have passed.

One process note worth recording. The first attempt at this failed against the
reference, and the reason was a silent edit: the replacement that registers the
write alternatives was applied without asserting its anchor matched, and the
anchor text was wrong, so the alternatives were never added while everything
still compiled. The frames the link received were byte-identical to the ones the
test expected, which is what made it look like a reference defect rather than a
missing fixture. Every scripted edit to these files should assert its anchor.

Exact version-45 artifact identifiers:

- `meta.md`: `2650b1820c2b8392c445b28956fdd9ec75fbd8df9e5a3037ad46bf9444953c7a` (unchanged)
- `test.patch`: `ed1d1e4f384076bab2cded963f05af0da5719253f69b85ed1bb0d39593c0bb57`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 35/35 on arm64 and 83/83 pre-existing on arm64. The
contract is unchanged, so difficulty is unaffected: the task already required
these methods to be byte-oriented, and only the check caught up.

## Version 46 false-positive gate: frame-fit crossed with the diff

`agent-runs13` returned 3 passes in 10 runs against version 45, matching
`agent-runs12`'s 30%. Seven failures are the canonicalization lever. One of the
three passes was a false positive and the report is correct.

`Nova_Nova_10` preflights with `check_restore_requests`, which walks the whole
record before any comparison, `for action in &snapshot.keymap` and the same for
every other table, sizing each `Set*Request` against `max_payload_size`. A board
that already holds an entry too large to write in one frame is therefore
rejected, when the contract requires that restore to succeed writing nothing:
"an entry that already matches is never sent", "writes only what differs", and
the frame-fit rule is scoped to "a request restore needs". An entry that already
matches is not one it needs.

The suite exercised both halves and never their intersection.
`snapshot_restore_plans_every_write_before_touching_the_device` gives a target
whose frame cannot carry a fork write and requires rejection, but its board is
dirty. `snapshot_restore_of_identical_target_reads_complete_baseline_without_writes`
gives an identical board and requires no writes, but its frame is generous.
Neither combination catches an implementation that sizes before diffing.

`snapshot_restore_skips_entries_too_large_to_write_when_they_already_match`
closes it with exactly the pairing that was missing: the same
`max_payload_size = 12` that stops a fork write, against a board that already
holds the snapshot. Both `preflight_restore` and `restore_configuration` must
succeed and nothing may be written. The reference passes because it computes
every diff before it plans or measures anything.

Replaying the three passes confirms the repair is targeted rather than blunt:
`Nova_Nova_1` and `Nova_Nova_3` still pass, and `Nova_Nova_10` now fails on this
test alone. The batch becomes 2 of 10, still above the Solvable floor and inside
the 50% cap.

Exact version-46 artifact identifiers:

- `meta.md`: `2650b1820c2b8392c445b28956fdd9ec75fbd8df9e5a3037ad46bf9444953c7a` (unchanged)
- `test.patch`: `63f6347c241fe027a77adba5b10c5189f143c91087fb72941fb40ed6da243d08`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 36/36 on arm64 and 83/83 pre-existing on arm64. The
contract did not change; only the check reached the intersection it had been
missing.

The general lesson, worth carrying: two rules that each have a test can still
admit a wrong implementation at the point where they meet. Frame-fit and
diff-before-write were both covered, and the defect lived precisely between
them.

## Version 47 baseline-failure sources and description filler

Two findings, both accepted.

**A single failure source behind the late-read rule.** The rule says every
pre-write rejection is preflight whatever the cause, but the only cause tested
was a device saying no, `reject_read` producing `RynkError::Invalid`. Nothing
covered a reply the client could not decode, so that branch could regress
unnoticed. The peer gains `corrupt_read`, which answers the named command with a
well-formed frame carrying a payload of the wrong shape, and the test now runs
both sources.

Reviewing it turned up a second weakness the report did not mention. The test
built its board with `matching_restore_state`, so the board already held the
snapshot and nothing would have been written even by an implementation that
ignored the failure entirely. Its no-mutation assertion was vacuous. It now uses
`dirty_restore_state`, so every resource differs and an implementation that
pressed on past the failed read would leave a mark. Both sources are checked
against that board.

Verified by mutation: rewriting the reference to report a baseline failure as
`Write` rather than `Preflight` fails this test and the malformed-baseline test,
and nothing else.

Collapsing the four remaining inline `StatefulSnapshotState` literals onto
`blank_target_state` came with it, since adding a field to the peer otherwise
means editing five places. Every peer state now flows through one constructor.

**Description filler.** "the rest the protocol's own types" is removed. It was
the only thing pinning the table element types, so this was weighed rather than
waved through: the surrounding text names every field, and export reads those
tables through `get_key`, `get_combo` and `get_morse`, whose return types are
`KeyAction`, `Combo` and `Morse`. The element types are therefore reachable from
the protocol the task already requires an implementation to call, and no run in
thirteen batches has chosen anything else. The description is 496 words.

Exact version-47 artifact identifiers:

- `meta.md`: `83c138fd074a780127e3be599be48c409038e3bc4e9591bd0994f7f99f8d60ff`
- `test.patch`: `fb184230eb6a68f38fd609389839b36f960690147ba00d69e177130fe4a34368`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 36/36 on arm64 and 83/83 pre-existing on arm64.

## Version 48 error-propagation gates, and a conflict between two reviews

Three findings. Two are coverage gaps and are closed. The third contradicts an
earlier accepted finding, and is answered by removing the requirement rather
than the sentence.

**The WASM wrapper could swallow a native failure.** The runtime test proved the
byte argument was decoded, by rejecting junk, and applied, by requiring the write
it asks for. It never gave the wrapper valid bytes whose native restore fails, so
one that awaited the native call, discarded its error and resolved successfully
passed. The test now decodes the exported record, renames the product to a board
this device is not, re-encodes, and requires the promise to reject. Decoding
succeeds there, so only propagation can produce the rejection. A wrapper
rewritten to `let _ = ...; Ok(())` fails.

**Export was never made to fail.** Every export case had a cooperative device, so
an implementation that hid a read failure and returned a record with a defaulted
field passed. Such a record encodes and validates cleanly and would later be
restored onto a board as though the device had really reported it, which is the
harm. `snapshot_export_fails_on_a_late_bad_read` rejects and then corrupts the
behaviour read, the last one export makes, and requires an error both ways. A
reference rewritten to substitute a zeroed `BehaviorConfig` fails it, and fails
the late-baseline test with it.

**The trait list, which two reviews disagree about.** Version 38 added "plus
`Debug` and `PartialEq`" because six tests compared whole snapshots with
`assert_eq!` and silently required both, which a review then called an unfair
compile-time condition. This review calls the same words checklist filler.
Deleting them would restore the earlier defect, so the requirement was reduced
instead of the sentence. `assert_eq!` needs `Debug` only to format a failure;
`assert!(a == b, "message")` needs just `PartialEq` and keeps the whole-record
comparison, which is what guarantees a field added to the snapshot cannot quietly
escape checking. The six sites now compare that way, carrying an explanatory
message apiece, and the description asks only for `PartialEq`. Both reviews are
satisfied without trading a fairness defect for a readability one. 494 words.

Exact version-48 artifact identifiers:

- `meta.md`: `ecde4a85e46d0e545eb7496df7afcaf0b71f213e38a6ad08e85ee6237b1681b0`
- `test.patch`: `47450356ae3c559626affbc2a7a5e10bcbb01cc3c96c065f753e93d14e4b1cac`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 37/37 on arm64 and 83/83 pre-existing on arm64.

## Version 49 retry ordering and equality-clause wording

Both findings are valid.

**Retry coverage stopped short of the last stage.** The retry test walked the
six multi-request stages, and in every one of them the first attempt fails
before behaviour is reached, so behaviour is only ever written on the retry. The
one ordering that matters most was therefore never exercised: behaviour applied,
then the default-layer write refused, then a second attempt. That is the case
where the entire configuration has already landed and only the final write is
missing, so an implementation reusing the first attempt's diff instead of reading
the board again resends everything, contradicting the rule that a matching entry
is never sent.

`snapshot_restore_retry_after_a_default_layer_failure_rewrites_nothing_else`
covers it. The first attempt completes the seven earlier stages and is refused at
`DefaultLayer`; the second must write the default layer and nothing else. Every
per-entry ledger is asserted to hold each entry once across both attempts,
`SetBehaviorConfig` exactly once, and `SetDefaultLayer` exactly twice, refused
then applied.

The gap was established by inspection rather than by mutation, and the record
should say so plainly. A reference mutated to write behaviour unconditionally
fails this test, but it also fails four others, so that mutant does not show the
new case is uniquely needed. What shows it is that no test in version 48 drove a
default-layer failure followed by a retry at all: the ordering, not the
assertion, is what was missing.

**Legalistic wording.** "including but not limited to" was chosen in version 41
to warn that the Morse map is not the only case without naming the others, which
is what keeps the canonicalization lever discoverable rather than handed over.
The warning is worth keeping and the phrasing is not, so the clause now reads
that `Morse.actions` built in different insertion orders "is one such case, and
not the only one". Same meaning, no legalese. 498 words.

Exact version-49 artifact identifiers:

- `meta.md`: `443b397725ea165eb9f26c1093bb4465edfa3ca1f4e92e7c7fb62eea290c0893`
- `test.patch`: `f1ce6765e04749112f5fced3f9cebdbb724a0cb924fd69fe3463177bc6c723fd`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 38/38 on arm64 and 83/83 pre-existing on arm64.

## Version 50 audit gaps closed, and a difficulty regression

An audit demonstrated three gaps where a broken implementation passed all 38
tests. All three are real and all three are closed. A fourth was found while
closing them. Separately, `agent-runs15` returned 9 passes in 10, which is the
headline: the task is no longer inside the cap.

**Decoding did not validate.** `ConfigurationSnapshot` is publicly serde-
serializable, so a record can reach the decoder without passing through
`to_bytes`. The suite checked semantic invalidity only through `validate` and
`to_bytes`, so a `from_bytes` that decoded one record and returned it without
validating passed everything. The check now serialises an unsupported-version
record and a short-keymap record with raw postcard and requires both to be
rejected.

That probe is one-sided on purpose, and the distinction matters because a
separate judge dispute in the same review turned on it. Asserting only that
`from_bytes` **rejects** these bytes holds for any encoding: a solution that
cannot read postcard rejects them as garbage, and one that can must validate.
Asserting that such bytes decode and preserve a field, which is what the
over-flagging judge did with a hand-built TapHold profile, would pin the wire
format the task deliberately leaves open. The first is fair; the second is not.
Deleting `snapshot.validate()?` from `from_bytes` now fails this test.

**The version type was not pinned.** Every fixture initialises `version` from
`SNAPSHOT_VERSION`, so narrowing the constant, the field and the error variant
together to `u8` passed all 38 tests while changing the persisted schema the
task fixes as `u16`. A `let _: &u16 = &snapshot.version;` binding pins the field
independently of the constant; the narrowed build now fails to compile.

**Behaviour was never frame-checked.** Frame-fit was proved for a paged combo
write and a single fork write, but behaviour has neither a bulk endpoint nor a
per-entry loop, so a planner written stage by stage can reach the end without
measuring it. The new test leaves only behaviour differing, against a frame too
small to carry it, and requires a preflight rejection with nothing written.
Removing the behaviour `fits_frame` call from the reference now fails it.

**A fourth gap, found while fixing the third.** Version 48 claimed the suite
required only `PartialEq` of `ConfigurationSnapshot`, having converted six
whole-record `assert_eq!` comparisons to `==`. Two were missed, in the
round-trip test and the Morse-order test, so `Debug` was still required while
the description no longer asked for it. Both now compare with `==`.

**The difficulty regression.** `agent-runs15` scored 9 of 10 against version 49,
up from 2 of 10 on `agent-runs13`. The canonicalization lever that carried six
and seven failures in the two previous batches now fails nobody. This is the
pattern versions 37 through 40 measured and recorded: a rule that is stated gets
satisfied, and only slips survive between batches. Canonicalization survived two
batches, longer than any lever before it, and has now been absorbed too.

Replaying all ten `agent-runs15` implementations against version 50 leaves the
rate unchanged: every one of the nine that passed still passes. The three audit
gaps are correctness coverage, not difficulty, and they were never going to move
it. The task needs a new lever and this gate does not have one.

Exact version-50 artifact identifiers:

- `meta.md`: `443b397725ea165eb9f26c1093bb4465edfa3ca1f4e92e7c7fb62eea290c0893` (unchanged)
- `test.patch`: `6564bf44a88abdd4df05112435e09dc6836130f23c728e7fdfa58c20d12be0d1`
- `solution.patch`: `bd3eb3333c927047d2b153aadb8c44086a24a6c421139ae81b5ce8909f36f59a` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 39/39 on arm64 and amd64, plus 83/83 pre-existing on
arm64.

## Why the rate moved: the lever was a clue, not a difficulty

Two corrections to the record before the diagnosis.

`agent-runs14` and `agent-runs15` are the same batch. All ten solution patches
and all ten trajectories are byte-identical between them. There is one
measurement at 9/10, not two, and `agent-runs14` was never written into any
document until now.

Raw pass counts per batch, scored uniformly from
`eval-result.json:test_results.new_tests_passed`: `agent-runs7` 0/5 (v26),
`agent-runs8` 4/5 (v28), `agent-runs9` 8/10 (v36), `agent-runs10` 5/10 (v38),
`agent-runs11` 5/5 (v40), `agent-runs12` 3/10 (v43), `agent-runs13` 3/10 (v45,
2/10 after the version-46 false positive was closed), `agent-runs15` 9/10 (v49).

**The 5/10 and the 9/10 do not measure the same mechanism.** Version 38's five
failures had four independent causes: the no-std surface build twice, the WASM
round trip once, larger-target coordinates twice. Difficulty was spread thin
across unrelated checks. By version 43 it had collapsed onto one test: six of
`agent-runs12`'s seven failures and *all seven* of `agent-runs13`'s were
`snapshot_canonicalizes_actions_equality_treats_as_the_same`. From version 43
onward the pass rate was one test's discovery rate plus a residual slip rate.

**That test measured discovery, not implementation.** In `agent-runs13`, exactly
three trajectories mention `TapHold` at all, and they are exactly the three runs
that passed. The seven failures mention it zero times, while still mentioning
`KeyAction` 54 to 95 times each. They read the type and did not connect it. In
`agent-runs15` every one of the ten mentions `TapHold` between 10 and 19 times,
including `Nova_Nova_7`, the sole failure, which found the lever and then died on
an unrelated `chunks(0)` panic. Discovery went from 3/10 to 10/10. Fisher's
exact test on 3/10 against 9/10 gives p = 0.0198, so this is not batch noise.

**What changed between the two batches was the description.** `meta.md` changed
at versions 47, 48 and 49, three consecutive reviewer-driven clarity edits, and
two of them route a reader toward the clue:

Version 47 removed "the rest the protocol's own types". That sentence was the
only thing naming the table element types, and the justification for cutting it
was that a solver can recover them from `get_key`, `get_combo` and `get_morse`.
That is true, and it is also the problem: recovering them means opening the
`KeyAction` definition, which is where the custom `PartialEq` that ignores the
`TapHold` profile index lives. An edit made to hand over *less* information
routed every run past the clue.

Version 49 moved the warning that Morse ordering is not the only case from
"including but not limited to", buried mid-sentence as boilerplate, to a
standalone sentence ending "and not the only one". The version-49 gate recorded
that as "Same meaning, no legalese." Same meaning, different salience, and
salience was the entire lever. That claim was wrong.

**The lesson is sharper than the one versions 37 through 40 recorded.** It is not
only that a stated rule gets satisfied. This lever was never implementation
difficulty at all; it was a hidden clue, and a hidden clue cannot survive the
review process the platform requires, because every finding pushes toward
legibility and each individual edit is correct. A lever that dies when the
description gets clearer was always going to die. A durable one has to stay hard
after the solver knows exactly what to do.

**This is testable.** Restoring version 46's description under version 50's tests
and re-running separates the two explanations. If the rate falls back toward
3/10 the description edits caused it and the lever is recoverable; if it stays
at 9/10 the population has learned the case and the lever is dead.

## Version 51 design gate: a lever that survives being stated

### Gate step 1, searches performed

`problems/README.md`, `candidates/CANDIDATES.md` and the archive were searched
for coalescing, request minimization, round-trip minimization and page-packing
concepts. The only hits are this problem's own records, so there is no archive
overlap to design around.

### Gate steps 2 through 4, evidence

Evidence is `agent-runs7` through `agent-runs15`, already read in full. A
legitimate pass, a near-pass and a broad failure all exist and are recorded
above. The governing finding is the version-50 diagnosis: from version 43 onward
the pass rate was one test's *discovery* rate, and every batch-to-batch move
came from whether solvers happened to inspect a custom `PartialEq`, not from
whether they could build anything. Difficulty must therefore move to
implementation, per `CALIBRATION_STRATEGY.md`, which says plainly to prefer a
harder-to-build invariant over more stated rules.

### The repository fact the lever rests on

`set_keymap_bulk` writes a **contiguous run** starting at `(layer, start_row,
start_col)` and walking column, then row, then layer; `set_combo_bulk` and
`set_morse_bulk` take a `start_index` and a contiguous run. `split_pages` fills
each page to the payload budget by measuring `serialized_size` per item, and its
page count varint widens as a page fills. All of this is public in `rynk/src/api.rs`.

Two consequences the current description does not exploit:

A bulk request is a contiguous interval in the **target's** flat index space,
and the target's flat index space is not the source's. With source `cols = 3`
and target `cols = 5`, source positions 2 and 3 are adjacent in the snapshot and
sit at target indices 2 and 5. Any run structure computed in source coordinates
is wrong.

The present rule, "an entry that already matches is never sent", forces maximal
splitting and so removes all planning freedom. It is also unlike what a real
host tool does, because a USB HID round trip is the expensive unit and every
such tool coalesces.

### The lever

Restore minimizes the number of device requests per stage. A bulk request may
carry entries that already match, but only to bridge differing ones. Stated in
full, in the description, with nothing withheld:

- a request is a contiguous run in the target's coordinates;
- it may span matching entries, but never a slot the snapshot does not reach;
- its first and last entries must both differ, so no request carries a matching
  entry at either end;
- it must fit the target's frame;
- with no bulk transfer, entries go one at a time and only differing ones are sent.

The optimum is well defined and unique in count. Reached slots split the target
index space into independent segments; within a segment, greedy extension from
the leftmost differing entry, then trimming to the last differing entry covered,
is optimal by the standard exchange argument. There is exactly one right request
list, so it is a generation problem, which is the direction this workspace has
already recorded as the harder one.

### Why it survives being stated

Every rule above can be written into `meta.md` verbatim and the task stays hard,
because knowing the rule does not produce the plan. The solver must build the
target-space index map, segment it by reached slots, extend under a per-entry
variable byte budget, trim, and keep the existing preflight and retry
invariants intact. Nothing depends on noticing anything. This is the property
the canonicalization lever never had.

### Discriminator ledger

| Observed shortcut | Public invariant | Black-box oracle | Failure family | Anti-overfitting rationale |
|---|---|---|---|---|
| Runs computed in source coordinates | Writes use the target's coordinates | Recorded request start positions and lengths against a wider target | Cross-geometry addressing | Two runs already failed the existing coordinate test at version 38; this is the same family under a harder plan |
| No coalescing at all, one request per differing entry | Fewest requests per stage | Exact request count for a scattered dirty set | Planning | Rejects a behavior, not a style; any optimal plan passes |
| Coalescing without trimming | First and last entry of a request must differ | First and last item of every recorded request | Planning boundary | Distinct from the above: catches the half-right implementation |
| Bridging across slots the snapshot does not reach | Unreached slots are left alone | Peer rejects any write addressing an unreached slot | Portability | Directly stated; no hidden condition |
| Coalescing when the frame cannot hold two entries | Every request fits the frame | Small `max_payload_size` with a scattered dirty set | Transport limits | Reuses the existing preflight family at a new boundary |
| Coalescing on the non-bulk path | Without bulk, one entry at a time, differing only | Per-entry request ledger on a peer with bulk disabled | Capability degradation | Existing family, new interaction |

Six discriminators across five distinct failure families, none of them a
restatement of another with different fixtures.

### Blast radius, stated plainly

This is a lever swap, not a redesign. Export, the snapshot format, validation,
portability, staging, preflight and the WASM surface are unchanged, and all of
them have passed fairness review repeatedly.

What changes: one paragraph of `meta.md`; the write planner in `solution.patch`
for the three paged stages; and the assertions in the restore tests that
currently require a matching entry never to be sent. By name, the affected tests
are `snapshot_restore_writes_only_dirty_entries_and_macro_chunks`,
`snapshot_restore_addresses_a_larger_target_in_its_own_coordinates`,
`snapshot_restore_maps_each_grown_dimension_independently`,
`snapshot_restore_skips_entries_too_large_to_write_when_they_already_match`,
`snapshot_restore_retry_skips_entries_applied_before_partial_failure` and
`snapshot_restore_of_identical_target_reads_complete_baseline_without_writes`.
The last is unaffected in substance, since an empty dirty set still writes
nothing.

The description currently stands at 498 words and the new rules cost roughly 40
net, so an equivalent trim is needed elsewhere. That trim must not touch the
equality clause or the element-type sentence, both of which the version-50
diagnosis showed to be load-bearing.

### Calibration position

This version has no measured rate. Per `CALIBRATION_STRATEGY.md` the target is
p around 0.28, the batch is 10, and the acceptance region is 1 to 5 solves. The
version-50 measurement of 9/10 does not carry over; a changed artifact starts a
new batch at 0/10.

## Version 51 built: the lever implemented and mutant-verified

The design gate above is now implemented. The description states every rule and
withholds nothing, which is the point: this lever cannot be eroded by a
clarification, because clarity was never what protected it.

**Description.** The rule "an entry that already matches is never sent" is
replaced by the request-minimization contract. Two sentences elsewhere were
trimmed to pay for it, neither of them the equality clause nor the element-type
sentence, both of which the version-50 diagnosis showed to be load-bearing. One
further sentence had to change for correctness rather than length: "a retry must
not rewrite entries that already match" contradicted a plan that may bridge, and
now reads that a retry plans afresh from what the device then holds. 529 words.

**Reference.** `dirty_runs` is gone. The planner now takes every slot the
snapshot reaches, flagged for whether the target already holds it, splits them
into maximal runs of consecutive target indices, and within each run starts at
the leftmost differing entry, extends while the frame has room, and trims back
to the last differing entry reached. The three paged stages share it; the
per-entry stages and the no-bulk path send differing entries only.

**Peer.** The stateful device gained `key_requests`, `combo_requests` and
`morse_requests`, each recording `(first index, entry count)` for every write.
Which entries a restore touches was already observable; how many requests it
spent and where each begins and ends was not, and that is what the contract now
turns on.

**Mutants.** Five, each killed, and three of the new tests kill one uniquely:

| mutant | tests failed |
|---|---|
| never bridge a matching entry | 5 |
| bridge but do not trim to the last differing entry | 4, uniquely `snapshot_restore_ends_every_request_on_a_differing_entry` |
| ignore the gaps and treat every reachable slot as one run | 3, including `snapshot_restore_retry_resumes_a_paged_stage_left_partly_written` |
| bridge without checking the frame | 1, uniquely `snapshot_restore_bridges_a_matching_entry_only_when_the_frame_allows` |
| send matching entries on the no-bulk path | 1, uniquely `snapshot_restores_to_a_device_without_bulk_transfer` |

The paired-frame test is the one worth naming. The same two differing keys with
the same matching key between them, and one byte of frame deciding the plan: at
10 bytes the three-key request fits and replaces two, at 9 it does not and the
only legal plan is two single-key requests. An implementation that always
bridges fails the tight frame; one that never bridges fails the roomy one.
Neither half is satisfiable by a rule of thumb.

**Tests reworked rather than added.** Six existing restore tests asserted that a
matching entry is never sent, which the new contract contradicts. Their
expectations moved and, where the contract made a scenario unreachable, the
scenario moved with it: `snapshot_restore_retry_skips_entries_applied_before_partial_failure`
now covers the three per-entry stages, because the paged stages carry this
fixture in a single request each and can no longer fail partway through. The
paged partial failure is covered instead on a grown target, whose spare column
and row split the keymap into three requests. That is a better test than the one
it replaces: it proves the retry replans from a fresh baseline *and* that
segmentation is stable across attempts.

**The reference lost a file.** `solution.patch` no longer touches
`rynk/src/api.rs`. Version 5 had widened `split_pages` to `pub(crate)` so the
snapshot planner could call it, but that function packs one contiguous item list
and cannot express bridging, so the new planner does its own measuring and the
import is gone. Three production files remain, still above the Long-horizon
two-file minimum.

Exact version-51 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b`
- `test.patch`: `79e18d11a70f69dab8c0472c33df9ed518cb6121d4ee726952b01e02703437e6`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

**One tightening after the fact.** The rule first read "Restore uses as few
requests as it can", which a careful reader could take to cover the baseline
reads as well. Those must be complete, and the description says so two
paragraphs earlier, but a rule that appears to contradict another rule is a
fairness defect whether or not the contradiction survives careful reading. It
now says "as few write requests as it can". 530 words, and the `meta.md` hash
above reflects it.

Reference verification is 42/42 focused tests on arm64 and amd64, plus 83/83
pre-existing on both. Both patches apply cleanly to a pristine checkout on both
architectures. Version 51 has no measured solve rate; calibration is 0/10.

## Version 51 review: three fair findings, one contested

**The order-pinning findings are correct and are fixed.** Three new assertions
compared `key_requests` as an ordered sequence. The repository documents
`write_all_keymap` as "concurrent paged writes", so the order requests reach the
device inside one stage is the implementation's choice, and the description
constrains stage order, request count, run boundaries and retry replanning but
never within-stage order. Those assertions could have rejected a correct
concurrent implementation.

Every request comparison now sorts through the existing `touched` helper, and
five sites moved rather than the three reported, because two more single-request
comparisons would have grown the same defect the moment a fixture gained a
second request.

The retry test needed more than sorting. It rejected the second request the peer
observed and then asserted the survivor was exactly `[(0, 2)]`, but under
concurrent writes *which* request is refused is itself nondeterministic. It now
asserts what the contract actually promises and nothing about scheduling: after
the refusal, fewer than three runs landed; after the retry, exactly three
requests were spent across both attempts and each key was carried exactly once.
An implementation that replays the first attempt's plan spends a fourth request
and writes a key twice, whichever order it chose.

Verified rather than asserted: a reference mutated to send the same minimal plan
back to front passes all 75 tests. The five discriminating mutants are still
killed, with identical coverage.

**The `SnapshotGeometry` field-list finding is contested.** The claim is that
the fields and types are discoverable from `DeviceCapabilities`. They are not.
`DeviceCapabilities` groups its fields as Layout, Input devices, Feature flags,
Connectivity and Protocol limits. The ten the task wants are exactly the first
two groups, and "structural half, without transport or paging limits" does not
decide the middle two: `storage_enabled`, `lighting_enabled`, `is_split`,
`num_split_peripherals`, `ble_enabled` and `num_ble_profiles` describe the board
rather than the transport, so a solver could reasonably include them.

That matters because the hidden suite builds `SnapshotGeometry` as a struct
literal naming all ten fields with no `..`. Field names, field count and field
types are compile-time requirements. Deleting the list would leave a
compile-time requirement unstated, which is the defect version 48 was corrected
for. The list stays.

The density concern behind the finding is met anyway. The sentence now reads
that `SnapshotGeometry` holds ten of `DeviceCapabilities`' fields "under the
same names and types", which drops the separate `u16` and `u8` annotations
because the mirrored types already carry them. Four other sentences lost
redundant clauses, none of them the equality clause or the element-type
sentence. The description is **499 words**, inside the 500 target.

Exact version-51 artifact identifiers, after the review fixes:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b`
- `test.patch`: `79e18d11a70f69dab8c0472c33df9ed518cb6121d4ee726952b01e02703437e6`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 42/42 focused tests on arm64 and amd64, plus 83/83
pre-existing on both, and both patches apply cleanly to a pristine checkout on
both architectures. Calibration is 0/10.

## Version 51 second review: an unfair test I caused, and a duplicate I caused

Both findings trace to the same version-51 density trim, which is the second
time on this problem that condensing the description has removed a rule rather
than filler. The first was version 31, losing the unsupported-version sentence.

**`completed` semantics.** The finding is correct: the suite required
`completed` to exclude a stage that needed no write, and version 51's
description did not say so. Two readings were defensible, exactly as reported.

The cause is that version 50's sentence *did* say so. It read "skipped stages
are absent and no later stage is attempted", and the version-51 trim cut
"skipped stages are absent and" as restating the clause beside it. It does not
restate it: "no later stage is attempted" is about stages after the failure,
while "skipped stages are absent" is about stages before it that had nothing to
do. Cutting it turned a stated rule into a hidden one.

The clause is restored verbatim, and the test stays. It is worth keeping,
because a reference mutated to push every passed stage into `completed`
regardless of dirtiness fails that test and only that test. It is the sole
discriminator for the rule, so weakening it instead would have deleted the
behaviour rather than clarified it. The description is 499 words, unchanged in
size: restoring four words was paid for by four genuine redundancies elsewhere.

**The duplicate test.** Also correct, also caused by version 51.
`restore_reports_completed_stages_after_partial_failure_and_stops` rejected the
second request of a stage, which coalescing made unreachable for the paged
stages, so version 51 changed it to the first. That made it a strict subset of
`restore_reports_completed_stages_and_stops_after_failure`, which already
iterates all eight stages at the same index, and left its name claiming a
partial failure it no longer produced. It is deleted rather than repaired: the
partial-stage case is covered where it is real, by
`snapshot_restore_retry_skips_entries_applied_before_partial_failure` for the
per-entry stages and `snapshot_restore_retry_resumes_a_paged_stage_left_partly_written`
for a paged one on a grown target. The surviving test now records that division
in a comment so the next reader does not re-add the duplicate.

The suite is 74 tests, one fewer than before, and 42 in the focused lane.

**The standing lesson, restated because it did not hold.** A description
sentence that looks redundant beside its neighbour usually is not; the neighbour
covers an adjacent case, not the same one. Density findings must be answered by
deleting words, never clauses, and every clause removed must be checked against
the assertion that depends on it.

Exact version-51 artifact identifiers, after the second review:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b`
- `test.patch`: `79e18d11a70f69dab8c0472c33df9ed518cb6121d4ee726952b01e02703437e6`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd`
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

Reference verification is 41/41 focused tests on arm64 and amd64, plus 83/83
pre-existing on both, and both patches apply cleanly to a pristine checkout on
both architectures. Calibration is 0/10.

## Version 52 design gate: foreign snapshot bytes are not a codec-neutral probe

### Gate searches and representative raw evidence

Before changing the hidden patch, the workspace-root `PROBLEM_DESIGN.md` was
reread. Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, this problem's `SUMMARY.md`, `LEVELS.md`, `ERRORS.md`
and all mentions of snapshot decoding, postcard and `from_bytes`. No other
local problem supplies an RMK snapshot codec or an independent invariant for
one. The pinned repository has postcard wire frames, but no pre-existing
`ConfigurationSnapshot`, `SnapshotRead`, snapshot envelope, magic prefix or
snapshot codec. Those protocol frames do not select the new persistence
format.

Three raw solver records were inspected again:

| trajectory | result and strict production surface | codec and architecture | relevant shortcut or proactive check |
|---|---|---|---|
| `agent-runs15/Nova_Nova_1` | legitimate pass, 38/38 new and 83/83 base; 869 added lines across `rynk/src/api.rs`, `rynk/src/snapshot.rs`, `rynk/src/lib.rs` and `rynk/rynk-wasm/src/client.rs` | postcard with `take_from_bytes`, explicit remainder rejection and post-decode `validate`; export a complete baseline, preflight, diff, then staged writes | Proactively ran workspace, alloc-only, WASM and Clippy checks; no alternate snapshot codec was explored. |
| `agent-runs15/Nova_Nova_7` | near-pass, 36/38 new and 83/83 base; 730 added lines across one combined configuration module, exports and the WASM client | the same postcard/remainder/validate codec and complete-baseline staged restore | Missed only the zero-space/zero-chunk macro boundary; it is legitimate evidence that decoder validation was implemented independently of the failing restore edge. |
| `agent-runs12/Nova_Nova_8` | broadest representative behavioral failure, 32/35 new and 83/83 base; 818 net added production lines across the snapshot module, exports and WASM client | postcard with remainder rejection and post-decode validation; complete-baseline diff and staged writes | Missed protocol-equality canonicalization and the zero-chunk restore boundary despite native, alloc-only, WASM, formatting and Clippy checks. Its decoder still validates. |

All three chose the same convenient repository dependency, and all three
validated after decoding. That recurring choice explains why the probe never
distinguished the saved implementations; it does not make postcard part of the
contract. Their production seams and commit timing remain legitimate and are
unchanged by this revision. The reported platform messages and verifier records
show no environment diversion for the relevant behavior.

### Finding

The review is correct. Version 50 reasoned that a one-sided rejection assertion
was codec-free: a non-postcard decoder would reject postcard bytes as garbage,
while a postcard decoder would decode and validate them. That argument omitted
a third valid case. A custom decoder may consume either foreign byte string as
an alternate encoding of a valid snapshot, even though its own `to_bytes` never
emits that spelling. The task requires the decoder to return what its encoder
encoded and to reject records that decode as invalid; it does not require every
foreign serialization of an invalid Rust value to decode as that value or to
be rejected.

There is no codec-neutral black-box replacement. `to_bytes` must reject an
invalid in-memory record, so it cannot create implementation-native bytes for
one. The task documents no envelope field that a test can mutate while
preserving the rest of the implementation's encoding. Requiring a new magic,
version byte position, canonical-only decoder or serde format would create a
private representation rule. The public decoder-validation requirement stays
in the description, but this part of it is not independently observable through
the available black-box API for every permitted codec.

### Discriminator ledger

| observed or proposed behavior | public invariant | black-box oracle | decision and anti-overfitting rationale |
|---|---|---|---|
| Decoder ignores bytes after its own complete record | Decoding consumes the whole input | Append a byte to `to_bytes` output and require rejection | Keep. This starts from implementation-native bytes and directly exercises the stated whole-input rule. |
| Encoder emits an invalid public record | Encoding refuses every validation failure | Mutate public fields, require `validate` and `to_bytes` to reject | Keep. It is codec-independent and covers version plus four other validation families. |
| Decoder does not validate a record it successfully decodes | Decoding rejects anything invalid | Feed raw postcard serialization of invalid public records | Remove. The bytes are not produced by the implementation, and a permitted codec can consume them as a valid alternate record. No codec-neutral malformed native encoding exists through the public API. |
| Decoder round trip loses or substitutes the encoded record | Decoding returns what was encoded | Decode the implementation's own `to_bytes` output and compare the whole snapshot | Keep. This is the direct public round-trip boundary and accepts every encoding. |

This is a fairness repair, not a new difficulty lever. `meta.md`, the reference
behavior and the Level 6 request planner remain unchanged. Only the two
foreign-postcard cases and their now-false explanation are removed from the
combined codec/validation test; the test name is narrowed to the behavior it
still proves. As any artifact change creates a new immutable version,
calibration remains 0/10 for version 52. The operator-disabled false-positive
audit remains skipped, so this gate does not declare the revision
submission-ready.

### Version 52 implementation and reference verification

The two raw-postcard cases are deleted and
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` is now
`snapshot_codec_rejects_trailing_bytes_and_invalid_encodes`. The surviving test
starts from the implementation's own bytes for its trailing-input check, and
checks five invalid public records only through `validate` and `to_bytes`.
No public requirement, production implementation or difficulty discriminator
changed.

Both patches apply cleanly and in order to a pristine pinned checkout, with no
whitespace errors and `test.sh` at mode 755. The exact test-patch-only
pre-existing suite passes 83/83 on arm64 and amd64. With the reference applied,
the focused lane passes 41/41 on arm64 and amd64, including the alloc-only and
WASM subprocess tests. A local native run also passes all 74 Rynk library tests
with `snapshot-tests` enabled. These are reference and regression checks only:
no false-positive audit, mutant, survivor probe, solver replay, cold solver or
calibration run was performed.

Exact version-52 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` (unchanged)
- `test.patch`: `fcc9c2f5bbd37bca88ff1e2089370738886ac20b9e90cb2a232a52f83198a255`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

The description remains 499 words and pure ASCII. Version 52 has no measured
solve rate and remains 0/10. Because the false-positive audit is explicitly
operator-disabled, it is reference-verified but not approved or
submission-ready.

## Version 53 design gate: preserve the wrapper's testcase identity

### Gate and evidence

The workspace-root `PROBLEM_DESIGN.md` was reread before touching the hidden
patch. Searches covered the problem indexes and this problem's `SUMMARY.md`,
`LEVELS.md`, `ERRORS.md`, `DESIGN.md`, saved JUnit reports and raw trajectory
records. The version-52 representative legitimate pass
(`agent-runs15/Nova_Nova_1`), near-pass (`agent-runs15/Nova_Nova_7`) and broad
failure (`agent-runs12/Nova_Nova_8`) remain the relevant raw evidence; their
files, data flow, validation timing, shortcuts, proactive checks and production
sizes are recorded immediately above and are unaffected because no behavior is
changing here.

The new authoritative post-solution report passes the visible regression and
snapshot suites but adds a wrapper failure for the missing expected testcase
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions`. Saved JUnit
reports from `agent-runs3` through `agent-runs15` consistently expose that exact
identity. The repository record also has the same failure family at version 29:
a passing WASM command outside nextest did not appear under its expected JUnit
identity, so the wrapper correctly failed the phase despite successful code.

### Decision and discriminator ledger

Version 52 changed both the unfair body and its name. Only the first change was
needed for fairness. The platform treats test identity as submission metadata,
so renaming the case created a packaging regression unrelated to participant
behavior. Restore the historical function name while keeping the version-52
body byte-for-byte: raw foreign postcard records stay absent, and the surviving
implementation-native trailing-input plus `validate`/`to_bytes` rejection
checks remain.

| observed behavior | public or packaging invariant | oracle | decision and anti-overfitting rationale |
|---|---|---|---|
| Foreign postcard bytes are rejected | Snapshot encoding is solver-chosen | None exists codec-neutrally | Remains removed; restoring a name does not restore the unfair assertion. |
| Implementation-native trailing input is rejected and invalid public records are not encoded | Whole-input decoding and encoder validation | Existing version-52 body | Keep unchanged; every permitted codec is still accepted. |
| A passing graded test is absent under the wrapper's registered identity | The official phase must report every expected testcase | Authoritative merged JUnit and wrapper status | Restore the historical test name. This changes reporting identity only and is supported by all prior JUnit history, not one solver implementation. |

There is no new participant-facing requirement, behavioral discriminator,
fixture, production change or prompt edit. Version 52 is abandoned unmeasured;
the identity-only patch is version 53 at calibration 0/10. Per the user's
standing instruction, no false-positive audit, mutation check, survivor probe,
solver replay, cold solver or calibration run will be performed.

### Version 53 implementation and reference verification

Only the Rust function name changed. The version-52 body is byte-identical and
still contains no foreign postcard input. Both patches apply cleanly and in
order to a pristine pinned checkout, with no whitespace errors and `test.sh` at
mode 755. On both arm64 and amd64, the exact test-patch-only regression lane
passes 83/83 and the combined focused lane passes 41/41, including the
alloc-only and WASM subprocesses. The generated JUnit on each architecture
contains the exact registered identity
`driver.tests.snapshot_decoder_rejects_trailing_bytes_and_unknown_versions`.
A local exact-name run also passes.

These were reference, regression and JUnit-presence checks only. No
false-positive audit, mutation check, survivor probe, solver replay, cold solver
or calibration run was performed.

Exact version-53 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` (unchanged)
- `test.patch`: `607b0e47068f45afb42580b7b0ce5770ec8778879ce64f5c5d618ad16d86c5ef`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

The description remains 499 words and pure ASCII. Version 53 has no measured
solve rate and remains 0/10. The false-positive audit remains explicitly
operator-disabled, so the version is reference-verified but not approved or
submission-ready.

## Version 54 design gate: derive the WASM rejection input from native bytes

### Gate and evidence

The workspace-root `PROBLEM_DESIGN.md` was reread before changing the hidden
patch. Searches covered the problem indexes, current compact records, the WASM
fixture, all literal malformed-byte uses and the existing whole-input decoder
oracle. The representative raw evidence remains the legitimate pass
`agent-runs15/Nova_Nova_1` (38/38 new, 83/83 base, 869 added production lines),
near-pass `agent-runs15/Nova_Nova_7` (36/38 new, 83/83 base, 730 added lines)
and broad failure `agent-runs12/Nova_Nova_8` (32/35 new, 83/83 base, 818 net
added lines). Their chosen production seams, complete-baseline restore flow,
post-decode validation timing, postcard choice, missed restore/canonicalization
boundaries and proactive native/alloc/WASM checks are recorded in the
version-52 gate. None gives the literal three-byte string a repository meaning.

The new review is correct. `snapshot_methods_export_native_bytes_and_restore_them`
passes `[0xff, 0xfe, 0xfd]` to the WASM restore wrapper and requires rejection.
The prompt leaves the encoding to the participant, the pinned repository has no
snapshot format, and a permitted custom decoder may assign those bytes to a
valid snapshot. The sequence is therefore another foreign-input collision,
independent of the raw-postcard cases removed in version 52.

### Decision and discriminator ledger

The fair native test already expresses the codec-neutral construction required
by the public whole-input rule: take bytes returned by the implementation's own
`to_bytes`, append one byte, and require `from_bytes` to reject rather than
silently accept a complete record with trailing input. Apply the same
construction at the JavaScript boundary. Clone the bytes just returned by
`export_configuration_snapshot`, append `0xaa`, and pass that typed array to
`restore_configuration_snapshot`. The exact suffix value is irrelevant; the
oracle is that it follows an already complete implementation-native record.

| observed behavior | public invariant | black-box oracle | decision and anti-overfitting rationale |
|---|---|---|---|
| A chosen three-byte literal is rejected | Encoding is solver-chosen | Call WASM restore with `[0xff, 0xfe, 0xfd]` | Remove. The repository and prompt assign the literal no meaning, so a custom valid format may consume it. |
| The WASM wrapper ignores trailing bytes after a native complete record | Decoding consumes the whole input; the WASM method restores the supplied bytes | Append one byte to that implementation's exported snapshot and require the Promise to reject | Replace the literal with this oracle. It derives from the implementation under test and mirrors the accepted native boundary without selecting a codec. |
| The wrapper ignores its argument or hides native errors | The WASM method restores the supplied bytes and propagates failure | Existing valid foreign-identity preflight rejection and valid changed-snapshot write | Keep unchanged. These independent modes already prove argument use and native error propagation. |

No prompt, production path, request-planning discriminator, testcase identity or
test count changes. Version 53 is abandoned unmeasured; this one-fixture fairness
repair is version 54 at calibration 0/10. Per the standing instruction, no
false-positive audit, mutation check, survivor probe, solver replay, cold solver
or calibration run will be performed.

### Version 54 implementation and reference verification

The standalone WASM test now clones the bytes returned by
`export_configuration_snapshot`, appends `0xaa`, and requires
`restore_configuration_snapshot` to reject that trailing input. The arbitrary
`[0xff, 0xfe, 0xfd]` sequence is gone. The suffix does not name an encoding:
its meaning comes only from following a complete snapshot emitted by the
implementation under test. The historical Rust testcase identity remains
unchanged, and no foreign postcard fixture has been restored.

Both patches apply cleanly and in order to a pristine pinned checkout, with no
whitespace errors and `test.sh` at mode 755. On both arm64 and amd64, the exact
test-patch-only regression lane passes 83/83 and the combined focused lane
passes 41/41, including the alloc-only and WASM subprocesses. The generated
JUnit on each architecture contains the exact registered identity
`driver.tests.snapshot_decoder_rejects_trailing_bytes_and_unknown_versions`.

These were reference, regression and JUnit-presence checks only. Per the
user's instruction, no false-positive audit, mutation check, survivor probe,
solver replay, cold solver or calibration run was performed.

Exact version-54 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` (unchanged)
- `test.patch`: `a87eb8807b1ebf5ff94448403cf967849995f882748344705f4ffac2da349c86`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` (unchanged)
- `Dockerfile`: `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` (unchanged)

The description remains 499 words and pure ASCII. Version 54 has no measured
solve rate and remains 0/10. Because the false-positive audit is explicitly
operator-disabled, it is reference-verified but not approved or
submission-ready.

## Version 55 design gate: arbitrary-UID offline harness execution

### Gate and evidence

The workspace-root `PROBLEM_DESIGN.md` and current `HANDOFF.md` were reread
before changing the harness. Searches covered the problem indexes, compact
records, environment history, nested-Cargo implementations, nextest/JUnit
fallbacks, offline cache permissions and prior non-root checks. The same raw
trajectory set remains representative because this repair changes no
participant behavior: `agent-runs15/Nova_Nova_1` is a legitimate 38/38 new,
83/83 base pass with 869 added production lines;
`agent-runs15/Nova_Nova_7` is a 36/38 near-pass with 730 added lines; and
`agent-runs12/Nova_Nova_8` is a broader 32/35 failure with 818 net added lines.
Their raw `trajectory.json`, evaluator record, production patch and proactive
native, alloc-only and WASM checks were reinspected. They use the public Rynk
snapshot module and WASM client seams; their successes and missed zero-macro,
canonicalization and planning boundaries remain unrelated to the evaluation
user or Cargo cache ownership.

The reported infrastructure failure reproduces against exact version-54
artifacts in the retained arm64 image with networking disabled and UID/GID
42424. `cargo nextest` cannot create
`/app/rynk/target/nextest/default`, exits 96 before collection, and `test.sh`
emits a fallback XML document with one skipped testcase and zero failures or
errors. Redirecting only nextest's store and Cargo target to a directory made by
that UID reaches compilation, then fails reading cached
`fnv-1.0.7/lib.rs`, which is root-owned mode 0640. The standalone helper also
places its two nested target directories beside the injected manifest under
root-owned `/app`, so it would hit the same ownership boundary after the outer
build. These are three independent machine-ownership assumptions, not solver
behavior.

### Decision and discriminator ledger

| observed behavior | public or harness invariant | black-box oracle | decision and anti-overfitting rationale |
|---|---|---|---|
| Nextest writes its store under root-owned `/app/rynk/target` | The official offline runner must work under the evaluation UID | Run both modes with networking disabled as an arbitrary numeric UID | Build a per-invocation directory with `mktemp`, layer the committed nextest config with a store path there, and pass a target directory there. This depends on the OS temporary-directory contract, not a named user or UID. |
| Nested Cargo writes target directories beside a root-owned injected manifest | Both graded out-of-process checks must reach their actual assertions | Run the alloc-only and WASM testcases under the same arbitrary UID | Put each nested target under `std::env::temp_dir()` with the process ID and package name. The tests remain serialized and no participant path or implementation is selected. |
| Some warmed registry sources are mode 0640 | Offline dependencies and installed tools must be readable/executable by the evaluation user | Cold-compile from the warmed cache with networking disabled as the arbitrary UID | After all image warming, grant read/search access to `/opt/cargo` and `/opt/rustup`. Do not grant repository writes or assume a group mapping. |
| Runner exit 96 becomes a skipped fallback testcase | A harness startup failure must be visible as a JUnit failure or error | Force a pre-collection runner failure and inspect XML counts and testcase body | Emit one `errors=1` harness testcase when no nextest JUnit exists and status is nonzero. This reports infrastructure truth and cannot make a participant implementation pass or fail behaviorally. |
| Spawning nested Cargo returns only a bare OS string | A reached graded test must identify which nested command could not start | Make the Cargo executable unavailable in an isolated probe | Include the program, manifest and OS error in the returned diagnostic; do not change success or failure semantics. |

This is an offline harness repair only. The prompt, reference implementation,
behavioral tests, registered testcase identities, test count and Level 6
difficulty remain unchanged. Version 54 is abandoned unmeasured; version 55
starts at calibration 0/10. Per the user's standing instruction, no
false-positive audit, mutation check, survivor probe, solver replay, cold
solver or calibration run will be performed.

### Version 55 implementation and reference verification

`test.sh` now creates a private runtime root with `mktemp`, layers the committed
nextest settings onto a configuration whose store is inside that root, and
passes a Cargo target directory there. The standalone helper likewise puts its
alloc and WASM targets under the system temporary directory, keyed by package
and process, and its spawn error names Cargo and the manifest. When nextest
exits before writing JUnit, the fallback is now a `harness-startup` testcase
with `errors="1"`, never a skipped compile placeholder. The Dockerfile's final
layer grants read/search access to the warmed Cargo and rustup trees after all
fetches and tool installations.

The exact version-54 failure was reproduced first in a network-disabled arm64
container under UID/GID 42424: nextest exited 96 on the root-owned store and
the fallback reported zero failures and errors. With a temporary store and
target but before cache normalization, compilation reached and then failed on
the mode-0640 `fnv` source. A forced missing-Cargo run against the repaired
script exits 127 and emits one JUnit error.

Fresh version-55 pristine images were derived from the already validated
dependency-complete arm64 and amd64 layers by applying the Dockerfile's exact
final permission normalization. In both images, with networking disabled and
UID/GID 42424, the test patch applies cleanly, `test.sh` is mode 755, and the
test-patch-only regression lane passes 83/83. After the reference patch applies
cleanly, the focused lane passes 41/41, including
`snapshot_surface_builds_with_alloc_without_std` and
`snapshot_wasm_client_round_trips_under_node`. Both focused JUnit reports also
contain the wrapper-registered decoder testcase identity. Patch whitespace and
shell syntax checks pass.

These were harness, reference, regression and JUnit-presence checks only. Per
the user's instruction, no false-positive audit, mutation check, survivor
probe, solver replay, cold solver or calibration run was performed.

Exact version-55 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` (unchanged)
- `test.patch`: `723f2c750b83b93542c504bc74279d1bf4ceb140a360f7ce573f0e3f6c2c1eb9`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` (unchanged)
- `Dockerfile`: `843abae0f216afdeee6bda1d0f53e02f1ed68231202df7fb96bec5bebd1d7be0`

The description remains 499 words and pure ASCII. Version 55 has no measured
solve rate and remains 0/10. Because the false-positive audit is explicitly
operator-disabled, it is reference-verified but not approved or
submission-ready.

## Version 56 design gate: distinguish expected compilation from harness startup

### Gate and evidence

The workspace-root `PROBLEM_DESIGN.md` and current `HANDOFF.md` were reread
before changing the runner. Searches covered local problem and archive records,
wrapper pass-to-pass/fail-to-pass classification, no-JUnit compilation
placeholders, nextest exit statuses and startup failures. The representative
raw trajectories remain the legitimate `agent-runs15/Nova_Nova_1` pass, the
`agent-runs15/Nova_Nova_7` near-pass and the broader
`agent-runs12/Nova_Nova_8` failure; their `trajectory.json`, evaluator result,
production seams, validation/restore timing, proactive native/alloc/WASM checks
and 869/730/818-line production sizes were reinspected. This wrapper-only
repair changes no participant behavior and selects none of their implementation
choices.

The version-7 gate is directly controlling evidence. It records that a
synthetic testcase existing only in the failing test-only state is neither
pass-to-pass nor fail-to-pass, so the expected failure to compile the absent
participant API must be a skipped placeholder while the runner remains
nonzero. Version 55 accidentally erased that distinction by turning every
nonzero no-JUnit exit into `new.harness-startup`.

The new wrapper report classifies the complete 83-test regression set and all
41 expected fail-to-pass snapshot tests, then flags only the additional
errored `new.harness-startup` entity as unclassified. Exact reproduction with
networking disabled and UID/GID 42424 confirms that the test-patch-only `new`
lane reaches rustc, reports the missing public snapshot types and client
methods, exits 101, and emits that extra error. This is not the earlier exit-96
permission failure: version 55's writable stores, temporary targets and
readable tools/cache all work before compilation begins.

### Decision and discriminator ledger

| observed behavior | wrapper invariant | black-box oracle | decision and anti-overfitting rationale |
|---|---|---|---|
| Test-patch-only `new` reaches rustc, cannot compile the deliberately absent participant API and exits 101 without nextest JUnit | A synthetic entity present only before the solution is unclassifiable; expected new-mode compilation failure remains nonzero but skipped | Run exact test patch without the solution, inspect compiler diagnostics, exit status and merged wrapper census | Emit the historical skipped `new.compile-placeholder` only for new-mode exit 101. This follows the runner phase and documented public API absence, not a solver implementation. |
| Nextest cannot initialize its store and exits 96, or Cargo cannot be launched and the shell exits 127 | Genuine harness startup failures must be represented as JUnit failures/errors | Force each startup failure before collection and inspect XML | Keep `harness-startup` with `errors=1` for every other nonzero no-JUnit exit, including 96 and 127. The version-55 machine-independent path remains intact. |
| A reached test fails after collection | Real test identity, not a synthetic fallback, must carry the failure | Break a graded behavior or nested command after nextest creates JUnit | Continue copying native nextest JUnit unchanged whenever it exists; fallback classification never replaces real testcase results. |
| Base-mode compilation fails | Regression collection is expected before and after the solution | Run test-patch-only base under the evaluation UID | Never skip base-mode exit 101; it remains a harness error because the public baseline is known to compile. |

No prompt, behavioral assertion, registered test identity, reference code,
Docker layer, test count or difficulty discriminator changes. Version 55 is
abandoned unmeasured; version 56 starts at calibration 0/10. Per the user's
standing instruction, no false-positive audit, mutation check, survivor probe,
solver replay, cold solver or calibration run will be performed.

### Version 56 implementation and reference verification

The runner now distinguishes the expected pre-solution compile phase from a
broken harness. If the `new` lane reaches rustc, nextest writes no JUnit and
the process exits 101 because the participant-facing snapshot API is absent,
the wrapper preserves that nonzero exit and writes one skipped
`new.compile-placeholder`. Every other nonzero no-JUnit exit still writes one
errored `harness-startup`; base-mode exit 101 is deliberately not special.
Whenever nextest has written JUnit, that report still wins unchanged.

The exact test-patch-only `new` lane was run with networking disabled as
UID/GID 42424. It reached rustc, reported the missing snapshot types and client
methods, exited 101, and produced exactly one skipped
`new.compile-placeholder` with no failure or error. A forced missing-Cargo
probe exited 127 and produced exactly one errored `base.harness-startup` with
no skip, confirming that genuine startup failures were not hidden.

Because the Dockerfile is byte-identical to version 55, its validated pristine
images were retagged for version 56. On both arm64 and amd64, the exact test
patch passed 83/83 regression tests offline as UID/GID 42424. After applying
the unchanged reference patch, the focused lane passed 41/41, including the
alloc-only nested Cargo build, the Node/WASM runtime test and the registered
decoder testcase. Shell syntax, patch reproduction and whitespace checks also
pass.

Exact version-56 artifact identifiers:

- `meta.md`: `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` (unchanged)
- `test.patch`: `21f7cbaea27cee217f6a940e7628b9f0447f3e5ba9381bfcf46256c5ac59cae0`
- `solution.patch`: `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` (unchanged)
- `Dockerfile`: `843abae0f216afdeee6bda1d0f53e02f1ed68231202df7fb96bec5bebd1d7be0` (unchanged)

The description remains 499 words and pure ASCII. These were wrapper,
reference, regression and JUnit-identity checks only. Per the user's standing
instruction, no false-positive audit, mutation check, survivor probe, solver
replay, cold solver or calibration run was performed. Version 56 remains
unapproved and not submission-ready, with calibration 0/10.

## Version 56 review: semantic-invalid decoder bytes have no portable oracle

### Gate and evidence

Before evaluating the proposed decoder assertion, the workspace-root
`PROBLEM_DESIGN.md`, current `HANDOFF.md`, the version-50 and version-52 decoder
records, and the current public description and codec test were reread. Searches
covered local problem, candidate and archive records for decoder validation,
foreign serialization, implementation-native malformed bytes and codec-neutral
oracles. The directly relevant local history is version 52, which removed raw
postcard encodings of invalid records after establishing that rejection can
still constrain an unspecified codec.

The representative raw solver evidence was reinspected: the legitimate
`agent-runs15/Nova_Nova_1` pass, the `agent-runs15/Nova_Nova_7` near-pass and
the broader `agent-runs12/Nova_Nova_8` failure. Their production patches all
choose postcard and call `validate` after `take_from_bytes`; their evaluator
records report respectively 38/38, 36/38 and 32/35 focused tests with all
83 baseline tests passing. None supplies evidence that the repository or task
defines a shared snapshot envelope, magic, field offset or alternate encoding.

The review correctly identifies a coverage gap: the current decoder test proves
whole-input consumption, while invalid versions and lengths are driven through
`validate` and `to_bytes`. A decoder that can deserialize an invalid record but
returns it without validation is therefore not independently rejected by a
semantic-invalid byte fixture in the current suite.

### Candidate-oracle ledger

| proposed probe | public invariant | portability analysis | decision |
|---|---|---|---|
| Serialize an invalid record with postcard and pass those bytes to `from_bytes` | Decoding rejects invalid records | The implementation did not produce those bytes and may legally assign them to a valid record | Reject; this is the version-52 codec coupling. |
| Change a known version or length byte in `to_bytes` output | Same | The task defines no byte position or envelope, and integrity-protected codecs may reject the mutation structurally | Reject; it prescribes representation. |
| Enumerate single-byte mutations of native output and require every successful decode to validate | Any returned record is valid | The conditional invariant is fair, but it does not construct a guaranteed semantic-invalid decode; a legal codec may reject every mutation or require several coordinated changes | Reject as the requested negative case. It would be an arbitrary mutation search selected mainly because it happens to kill the postcard reference mutant, not a portable semantic boundary. |
| Append a byte to native output | Decoding consumes the whole input | The implementation supplies the valid prefix and the prompt independently defines whole-input consumption | Keep the existing assertion; it tests framing, not semantic validation. |

There is no portable black-box negative case through the current API.
`to_bytes` is required to reject invalid values, so it cannot generate the
needed native bytes, and `from_bytes` is the only operation that interprets a
byte string. Adding a documented envelope would make such a test possible but
would revoke the prompt's deliberate codec freedom and is not justified by the
repository or trajectories.

Accordingly, the finding is recorded as an accepted observability gap and no
test is added. `meta.md`, `test.patch`, `solution.patch`, `Dockerfile`, version
56 and all artifact hashes remain unchanged. This is not approval of a hidden-
test revision. Per the user's standing instruction, no false-positive audit,
mutation check, survivor probe, solver replay, cold solver or calibration run
was performed.

## Acceptance and archive closure

The user confirmed platform acceptance on 2026-08-05. Canonical version 56 is
therefore frozen at the artifact hashes recorded above and in `RUNS.md`; no
prompt, hidden-test, reference, runner, or image artifact changed during
closeout. This is platform-outcome evidence, not a substitute for the exact-
version false-positive audit or a fresh calibration batch that the user had
instructed us to skip.

The 806 readable raw-run files, available source ZIPs, and estimate records were
verified against an independently generated member inventory and moved to
`archive/rmk-portable-configuration-snapshot/agent-runs.tar.gz`. Forty-three
unique temporary logs, reports, historical patches, and mutation tools were
preserved separately. Reconstructible worktrees, generated Cargo targets, and
RMK-only Docker tags were inventoried before cleanup. `RUNS.md`, the archive
manifest, and the worktree manifest are the durable navigation records.
