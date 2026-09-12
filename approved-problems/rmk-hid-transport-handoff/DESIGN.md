# RMK lossless HID transport handoff — design record

Status: **accepted and archived 2026-08-12; user-confirmed**

Repository: `rmk-rs/rmk` at `65df15775026bad1189139613ee3d338139bec3d`.

## Public contract and repository evidence

`rmk/src/state.rs` owns the active USB/BLE selection and already clears the old
route after committing a transport change. `rmk/src/channel.rs` is the shared
router for keyboard, mouse, media, system, and optional steno reports. Its
current cleanup emits only a neutral keyboard report, and its send functions
discard state produced without an active route. `rmk/src/hid.rs` identifies
mouse buttons as absolute and X/Y/wheel/pan as relative HID fields. Version
5's pure test scaffold observes the pre-existing USB/BLE report channels and
does not alter either production writer.

The required behavior is host-visible reconciliation: neutralize every family
the old host may hold, replay only still-held absolute state to the new host,
never replay relative mouse impulses, remember state while disconnected, avoid
offline ghost presses, and prevent a blocked send from leaking across cutover.
Order between independent families and silence versus neutral output for an
already released offline control are not part of the contract.

Because the pinned documentation describes steno as USB-only, version 15 also
states the intended scope extension directly: when steno and BLE are enabled
together, the composite HID-over-GATT service must advertise a Plover input
report and deliver the eight-byte chord to the BLE host.

## Trajectory-informed design gate

Workspace-root `PROBLEM_DESIGN.md` was read before the original feasibility
spike and again before this user-authorized escalation. Searches covered
`problems/README.md`, `candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, the
accepted RMK snapshot records and archive, HID routing, transport switching,
split disconnection, and KLE conversion. The complete current upstream census
at the pin contained 52 issues and 16 pull requests and no owner for this
behavior. Closed issue #616 concerns split peripheral message loss, not active
host transport handoff.

| Evidence role | Problem / run / archive member | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `archive/rmk-portable-configuration-snapshot/agent-runs.tar.gz`, `agent-runs15/Nova_Nova_1` | 38/38 focused and 83/83 baseline | Host-side Rynk snapshot module, codec validation, differential staged restore, alloc/WASM checks; no overlap with firmware HID routing |
| Near-pass | same archive, `agent-runs15/Nova_Nova_7` | 36/38 | Same snapshot architecture, missed zero-space/zero-chunk macro boundary; demonstrates why fixture accretion is not a new lever |
| Broad failure | same archive, `agent-runs12/Nova_Nova_8` | 32/35 | Same host configuration seams, missed protocol equality canonicalization and a macro boundary |

No solver trajectories exist for HID handoff. Repository evidence and two
independent complete local prototypes therefore supply the implementation-mode
evidence. A priority reconciliation-lane design measured 125 strict-effective
production additions; an existing-channel design measured 151. Both passed the
complete non-steno and steno lanes plus relevant feature checks. The user
explicitly accepted the known below-200 scope risk; the contract is not padded.

### Version 5 review-correction gate

This gate was completed before revising `test.patch`. The workspace design
protocol and the worked false-positive audit were re-read. Searches were
repeated across `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the current candidate/problem records, and the
archived RMK snapshot trajectories. There are still no raw solver trajectories
for this HID-handoff behavior; the representative pass, near-pass, and broad
failure remain the disjoint snapshot runs listed above, so they provide process
evidence but no HID implementation constraint.

External review correctly identified that version 4's test scaffold changed
the production USB and BLE writer paths and added a non-test channel API. Those
changes are solution code even though their purpose was observation. Version 5
therefore removes all three production seams from `test.patch`; hidden code is
limited to test configuration, test modules, and the wrapper. The focused
oracles consume the pre-existing `USB_REPORT_CHANNEL` and
`BLE_REPORT_CHANNEL`, which are the repository-defined inputs drained by the
transport writers at this pin.

That correction has a known tradeoff: the separate priority-lane prototype no
longer satisfies this particular pure-test oracle unless it also preserves the
repository's existing writer-input contract. Version 5 does not claim that the
test patch observes arbitrary replacement writer architectures. This is
recorded as a residual fairness risk rather than hidden behind production
scaffolding. The behavioral discriminators themselves remain unchanged, and
the public prompt continues to require outcomes without naming a cache, lock,
dirty-bit representation, report ordering, or exact counts.

The prompt review also found that enumerating every report family was an
unnecessary implementation hint. Version 5 replaces that list with the general
rule to release every stateful enabled family. The families remain
repository-discoverable through `Report` and the existing transport writers.

### Version 6 feature-request wording gate

This gate was completed before editing `meta.md`. `PROBLEM_DESIGN.md`, the
version-5 design record, requirement-to-oracle map, mutation results, and the
same-task trajectory search were re-read. The repository pin, lack of HID
solver trajectories, representative disjoint RMK snapshot runs, discriminator
ledger, hidden tests, reference behavior, and residual risks are unchanged.

Version 6 is deliberately non-semantic: the title and opening sentence begin
with “Add” so the task is unmistakably framed as a feature request. No public
requirement is added, removed, weakened, or made more implementation-specific.
Because `meta.md` is hashed, the exact false-positive audit and runtime matrix
must nevertheless be repeated and recorded under new immutable hashes.

### Version 7 review-correction gate

This gate was completed before revising `test.patch`. `PROBLEM_DESIGN.md`, the
worked statig false-positive audit, the version-6 design record, the archived
RMK snapshot trajectories, and the current repository channel/build surfaces
were re-read. There are still no same-task solver trajectories. The new
evidence is the external wrapper review of the immutable version-6 artifacts:

- the standalone no-ghost test already passed the unpatched repository, so it
  was not a fail-to-pass discriminator even though its requirement is public;
- the reference raised the generated channel capacity instead of operating at
  the configured one-entry capacity, so it did not demonstrate the public
  small-queue invariant;
- the image generated an ignored lockfile during its build and cached only the
  RMK manifest, leaving supported sibling manifests unresolved offline.

The no-ghost assertion remains useful but will be folded into the offline
positive-replay test. That combined test necessarily fails on the base because
the required held-state replay is absent, while still rejecting ghost controls
after an offline release. This removes the sole pre-solution pass without
weakening the participant-facing contract or adding a duplicate fixture.

The small-queue discriminator remains valid and distinct, but the reference
architecture changes: reconciliation will keep a bounded pending sequence and
feed the existing configured report channel as capacity becomes available.
The requested report-channel capacity therefore remains exactly one; no build
script override may enlarge it. This is an outcome-level implementation mode
supported by the repository's existing receive/try-receive seams and does not
change the test oracle.

Harness reproducibility is treated separately from product behavior. The exact
manifest lockfiles needed by the supported offline commands will be committed
in `test.patch`; Docker will fetch them with `--locked` and will not generate
lockfiles. The image preflight will cover `rmk`, `rmk-types`, and `rynk`, so a
network-disabled arbitrary-UID run validates the repository commands named by
the review rather than only the focused crate.

Version 7 invalidates every version-6 hash and verification claim. After the
changes, the full requirement map, mutation set, baseline/focused lanes,
no-std/feature checks, sibling-manifest offline commands, arbitrary-UID image
matrix, and immutable hashes must all be regenerated from the exact artifacts.

### Version 8 pre-patch image correction

This gate was completed after a platform build proved that Docker constructs
the image from the untouched repository before applying `test.patch`.
`PROBLEM_DESIGN.md`, the version-7 discriminator ledger, exact mutation record,
and prior RMK trajectory search were re-read. There are still no same-task
solver trajectories, and no behavioral discriminator, prompt clause, test, or
reference line changes in version 8.

The failed `cargo fetch --manifest-path rmk/Cargo.toml --locked` was an
environment-sequencing defect: the committed package locks correctly live in
`test.patch`, but cannot exist during the earlier untouched-repository image
build. The corrected Dockerfile therefore warms shared dependencies from
upstream example manifests that already have committed locks and downloads any
remaining registry packages with `cargo info` at the exact versions pinned by
the three test-patch locks. It neither creates a lockfile nor runs tests during
the build. After patch application, every runtime command continues to use the
committed locks with `--locked --offline`.

The clean-pin image build, arbitrary non-root/network-disabled baseline and
focused matrix, `rmk-types` tests, and `rynk` workspace build were repeated.
The nine behavioral mutants were also re-applied individually: their results
remain 6/7 for each of the five narrow shortcuts, then 2/7, 1/7, 3/7, and 3/7
for the four broad shortcuts. No focused survivor remains. Version 8 therefore
changes only the Docker hash while preserving the exact public and behavioral
artifacts.

### Version 9 lock-path collision correction

`PROBLEM_DESIGN.md`, the current discriminator ledger, prior RMK trajectory
search, and exact false-positive record were re-read before revising
`test.patch`. There are still no same-task solver trajectories and no new
behavioral evidence. External packaging review identified a different concern:
adding `rmk/Cargo.lock` at the package's predictable path can collide with a
participant-generated lock even though the filename itself is mandated by
Cargo.

Version 9 moves that committed lock beneath the randomized parent
`.rmk-a01fa986/`. Because stable Cargo requires the lock beside the selected
package manifest, the wrapper copies the patched source tree into its existing
writable temporary runtime directory and installs the randomized lock only as
that disposable copy's `rmk/Cargo.lock`. It never creates or overwrites the
participant's predictable source path. The `rmk-types` and `rynk` locks remain
at their package paths because they were not flagged and are used only by the
separate supported-root checks.

This is harness-path isolation, not a new discriminator. The prompt,
production reference, test assertions, and seven-test behavioral partition are
unchanged. Exact patch application, offline arbitrary-UID baseline/focused
runs, sibling-root checks, startup-error JUnit, and the nine-mutant audit were
all repeated successfully before version 9 was frozen.

### Version 10 pristine-build and Harbor correction gate

This gate was recorded before changing any submission artifact.
`PROBLEM_DESIGN.md`, the complete same-task design history, the v9
requirement-to-oracle map, exact mutant results, and the prior archived RMK
snapshot trajectory evidence were re-read. Searches of `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and the current problem
records still find no HID-handoff solver trajectory; the legitimate pass,
near-pass, and broad failure categories therefore remain unavailable for this
task. The new evidence is external infrastructure feedback from a pristine
clone build and a Harbor reference run.

The Docker image must derive its runtime lock and Cargo cache entirely from the
untouched checked-out repository because `test.patch` is injected only after
the image build. It must also perform a real Rust build during image creation,
not merely fetch packages. The root has no Cargo manifest, the RMK package's
default test feature combination is invalid, and BLE requires the pinned
`trouble-host` git revision; therefore the build must select an actual package
manifest and the same explicit compatible feature lane used by the focused
suite. Network is available only at image-build time.

Version 10 derives a lock from the pristine `rmk/Cargo.toml` inside the image,
compiles the focused test binaries there while network is available, and
stores the resulting lock outside the participant source tree for the offline
wrapper's disposable copy. A locked fetch then caches every optional and
target-specific package that nextest metadata can inspect. Rynk receives the
same build/fetch treatment. This removes every Docker dependency on a later
patch and populates registry, git, and compiler caches through real builds.
The two Debian package revisions are explicitly pinned.

The seven Harbor failures were traced to two formatting-only solution hunks
whose context existed only after `test.patch`. They were removed without
changing production output. Both patch orders now apply cleanly and produce
byte-identical implementation files. The solution-first Harbor-equivalent
reference passes 7/7, while the test-only image still fails 7/7. No public
behavior or hidden assertion changed. The full false-positive audit and
immutable runtime matrix were repeated successfully.

### Version 11 prompt-default removal gate

This gate was recorded before editing `meta.md`. `PROBLEM_DESIGN.md`, the full
same-task design history, the v10 discriminator ledger, requirement map, and
exact mutation results were re-read. Searches of `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, trajectory directories,
and the RMK archive still find no HID-handoff solver trajectory. The archived
snapshot pass, near-pass, and broad failure remain disjoint process evidence;
no new task-specific implementation mode or shortcut was found.

External prompt review correctly identified “Keep the implementation bounded
and compatible with RMK's existing `no_std` feature combinations” as a default
repository-compatibility expectation rather than a distinct feature behavior.
Version 11 removes that sentence. The bounded one-entry-queue requirement
remains explicit and testable. The existing feature and Clippy lanes remain
regression/build verification, not a participant-facing discriminator.

No hidden assertion, reference behavior, harness path, or discriminator is
changed. Because `meta.md` is an immutable participant artifact, its hash, the
requirement map, all nine mutation trials, the baseline/focused matrix, feature
checks, and offline arbitrary-UID evidence were nevertheless repeated before
version 11 was frozen. The base passes 541/541 baseline and fails 7/7 focused;
the reference passes 541/541 baseline and 7/7 focused. All nine mutants remain
rejected, and the USB-only, BLE-only+steno, dual+steno, and warning-denying
Clippy checks pass.

### Version 12 package-level offline cache gate

This gate was recorded before revising `Dockerfile`. `PROBLEM_DESIGN.md`, the
same-task design history, the v11 discriminator ledger, and the exact mutation
record were re-read. Searches of `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, available trajectory
records, and the archived RMK snapshot evidence still find no HID-handoff
solver trajectory or new behavioral shortcut. The new evidence is an external
offline image check, not solver behavior: `/app` correctly has no top-level
Cargo workspace and Rynk succeeds, but an RMK package-level resolution selected
`bytemuck` 1.25.2 after the pristine locked build had cached an older release.

An exact warm of only the reported archive exposed the same mismatch at the
next newer package, `either` 1.17.0. Version 12 therefore performs a complete
package-level RMK fetch without the harness lock while image-build networking
is available, then removes the temporary source-tree lock. This cache-only
resolution is distinct from the authoritative lock retained under `/opt`; the
wrapper remains deterministic under that official lock. The correction does
not add a workspace, retain a participant-tree lockfile, depend on `test.patch`
during image construction, or change the prompt, hidden tests, reference
implementation, and runtime lock contract. A pristine build and
network-disabled package-level RMK fetch/build/test compilation now pass,
including as UID/GID `12345:23456` with the newer graph. The arbitrary-UID
baseline/focused matrix, feature checks, and all nine mutation trials were also
repeated successfully before version 12 was frozen.

### Version 13 non-root Cargo cache visibility gate

This gate was recorded before revising `Dockerfile`. `PROBLEM_DESIGN.md`, the
full same-task design history, v12 requirement map, and nine-mutant record were
re-read. Searches of the repository/candidate indexes, current problem records,
and archived RMK snapshot evidence still find no HID-handoff solver trajectory
or behavioral discriminator change. The repeated external report is strictly
environmental: the evaluation runtime still cannot read or locate the fetched
`bytemuck` 1.25.2 archive, although local v12 images created under a permissive
umask can.

Version 13 makes the cache contract explicit instead of inheriting incidental
base-image or build-host state. Docker declares `/opt/cargo` as `CARGO_HOME`,
fetches `bytemuck` 1.25.2 by exact version in addition to the complete RMK
resolution, and normalizes read/execute permissions for the registry archive
cache and index as well as extracted sources and git checkouts. A direct probe
then exposed a second defect: the randomized local fallback lock had been
resolved later than Docker's authoritative lock, so it could require versions
outside that locked cache (`zerocopy` 0.8.55 was the next example). Version 13
regenerates the randomized fallback from the exact pristine image lock, making
the official and fallback dependency graphs identical while retaining the
collision-safe randomized path.

No workspace, participant-path lock, prompt, hidden assertion, or reference
behavior changes. The pristine image and both derived images built
successfully. As UID/GID `12345:23456` with networking disabled, an exact
`cargo info bytemuck@1.25.2 --offline` probe passed, as did locked RMK fetch,
focused-feature build, and focused-feature test compilation using the aligned
fallback lock. The official and fallback RMK locks are byte-identical at
`9b154a7d93f86c5fccb79ff7265042ffe7ea823add597ac19653c06457a181f1`.
The 541-test baseline, seven-test focused matrix, four feature/Clippy lanes,
both patch orders, and all nine mutation trials were repeated before version
13 was frozen.

### Version 14 writer-boundary and public-API correction gate

This gate was recorded before revising `test.patch`. Workspace-root
`PROBLEM_DESIGN.md`, the complete same-task design history, the exact v13
requirement map and mutation record, `problems/README.md`, the candidate
indexes, the candidate prototype records, and the archived RMK snapshot
trajectory manifest were re-read. Searches of active and archived trajectory
directories still find no solver trajectory for HID transport handoff. The
accepted snapshot pass, near-pass, and broad failure remain disjoint process
evidence only. The new evidence is external review plus two concrete source
boundaries at the frozen repository pin.

First, `rmk/src/ble/ble_server.rs` explicitly returns `Ok(0)` for
`Report::StenoReport` because the BLE HID service has no stenography
characteristic. Version 13's focused tests stop at `BLE_REPORT_CHANNEL`, before
that writer, so they can accept a replay that the BLE host never receives. The
public rule covers every enabled report family; a steno-enabled BLE target must
therefore advertise a matching report and emit a host-facing notification.
The revised strongest oracle will cross the writer boundary using a mock
notification sink and verify both the Plover report-map identity and emitted
chord payload. Queue observation remains appropriate for concurrency/state
tests, but no longer serves as proof of BLE steno delivery.

Second, base `rmk/src/channel.rs` declares `USB_REPORT_CHANNEL` and
`BLE_REPORT_CHANNEL` as public statics exposing the complete
`embassy_sync::channel::Channel` method surface. Version 13's custom wrapper
omitted stable methods such as `sender` and `receiver`. This is a real
downstream API regression independently supported by the public declarations.
Version 14 retains the bounded wrapper but implements `Deref` and `AsRef` to
the original concrete channel, preserving downstream method calls and coercion
to `&Channel` without exposing the private reconciliation backlog. A
compile-time regression probe exercises representative existing methods
without prescribing that private layout.

The review also identified harness-only cleanup. `rmk-types/Cargo.lock` and
`rynk/Cargo.lock` are not used by either wrapper mode and were removed from
`test.patch`; Docker remains responsible for image dependencies. `test.sh`
stopped assigning a fallback toolchain version and inherits the execution
environment. New handoff tests contain no millisecond scheduling delays:
blocked-send ordering uses deterministic future polling/readiness, while
absence checks use immediate queue state or the repository's virtual-time test
support only where an existing baseline contract requires it.

These changes revised the reference architecture, hidden test source, test
patch, and harness contract, invalidating every v13 hash and verification
claim. The base/reference matrix, public-API compile probe, BLE writer probe,
both patch orders, feature/Clippy lanes, repeated-run flake check, exact
false-positive mutation audit, clean-image offline execution, and artifact
hashes were regenerated before version 14 was frozen.

### Version 15 BLE-steno fairness correction gate

This gate was recorded before revising `test.patch`. Workspace-root
`PROBLEM_DESIGN.md`, the complete same-task design record, the version-14
requirement map and mutation audit, `problems/README.md`, the candidate indexes,
and the archived RMK snapshot trajectory manifest were re-read. Searches of the
available local problem and trajectory history still find no solver trajectory
for HID transport handoff. The snapshot pass, near-pass, and broad failure
listed above remain disjoint process evidence only. The actionable new evidence
is an external fairness review checked against the pinned repository.

The review is correct on both points. Version 14's BLE-steno test patched
test-only fields into private `BleHidServer`, instantiated that private layout,
and required a test-specific notification seam. A legitimate implementation
that adds the real characteristic to the structure naturally can therefore
fail to compile against the hidden scaffold. That is an implementation-shape
oracle, not a black-box host-output oracle, and it must be removed. The
replacement probe will leave the production structure untouched, establish a
real `trouble-host` GATT connection through a scripted controller, subscribe as
a BLE host, send a steno report through RMK's ordinary BLE path, and inspect
the emitted ATT notification. It may use existing runtime entry points at the
pinned repository boundary, but it will neither name candidate-added fields nor
construct a candidate-private layout.

The pinned public documentation supplies a second necessary correction:
`docs/docs/main/docs/features/steno.md` says steno is USB-only because the BLE
HID service has no stenography characteristic, and `rmk/Cargo.toml` describes
the current steno endpoint as USB. “Every enabled report family” does not by
itself fairly announce that the task extends this documented limitation.
Version 15 will therefore state explicitly in `meta.md` that enabling steno
with BLE requires advertising a Plover-compatible HID-over-GATT input report
and delivering its eight-byte chord state to the BLE host. This preserves the
intended behavior while making the scope discoverable without hidden-test
knowledge.

Both the public contract and its strongest probe change, so every version-14
hash, verification result, and mutation conclusion is invalidated. After the
new black-box probe is working, the exact requirement map, plausible mutation
set, base/reference baseline and focused lanes, relevant feature builds,
patch-order checks, offline arbitrary-UID execution, and immutable hashes must
be regenerated before version 15 can be declared ready.

Those gates were then completed on the exact version-15 artifacts. The new
test drives RMK through an in-memory `bt_hci` controller and real
`trouble-host` runners, establishes and subscribes a GATT client, identifies
the Plover characteristic by its report-reference descriptor, and observes the
outgoing ATT notification. It never patches, constructs, or names
`BleHidServer`. The base fails all eight focused tests, the reference passes all
eight, both pass 541/541 baseline tests, and all thirteen isolated plausible
mutations are rejected.

### Version 16 directional-completeness and cutover-atomicity gate

This gate was recorded before revising `test.patch`. Workspace-root
`PROBLEM_DESIGN.md`, the complete same-task design history, the version-15
requirement map and mutation audit, `problems/README.md`, both candidate
indexes, and the archived RMK snapshot trajectory manifest were re-read.
Searches of active, estimated, current-problem, and archived trajectory records
still find no solver run for HID transport handoff. The representative RMK
snapshot pass (`agent-runs15/Nova_Nova_1`), near-pass
(`agent-runs15/Nova_Nova_7`), and broad failure
(`agent-runs12/Nova_Nova_8`) were inspected again; they use Rynk-side snapshot
modules and remain disjoint process evidence rather than an HID implementation
constraint. The new evidence is the external review plus the exact
version-15 router source.

The directional finding exposes a real public-contract gap. The prompt says
both directions and every enabled family, but the BLE→USB oracle exercises only
media. Version 16 will broaden that existing test to the same unordered
keyboard, mouse-button, media, system, and steno release/replay contract as the
USB→BLE test, including zero relative mouse fields. This is a meaningful route
asymmetry boundary, not an extra fixture: an implementation may dispatch or
clean up families differently by transport while passing the one-family reverse
probe.

The atomicity finding is also supported by the current reference. Report state
is remembered under `HID_REPORT_STATE`, route selection is read separately from
`CONNECTION_STATUS`, channel enqueue happens later, and reconciliation runs
after the connection-state lock is released. A producer can therefore select
the previous route and enqueue after its stale traffic was cleared, or enqueue
on the new route while reconciliation subsequently replaces that queue. The
planned oracle will race an ordinary producer against repeated committed
cutovers and check only host-visible invariants: the prior host never ends with
pressed state, and the new host receives the producer's latest absolute state.
It will not inspect locks or require the reference architecture. The reference
will coordinate route selection, logical-state recording, enqueue, and
reconciliation through one cutover serialization boundary; blocked sends will
release that boundary while awaiting capacity and retry against the then-current
route.

These changes invalidate every version-15 hash, runtime result, mutation
conclusion, and readiness statement. Before version 16 can be frozen, the race
probe must first demonstrate deterministic rejection of the unsynchronized
version-15 reference and stability of the synchronized reference. Then the
complete requirement map, plausible mutation set, baseline/focused lanes,
feature and Clippy checks, repeated-run probe, patch-order checks, offline
arbitrary-UID matrix, startup-error JUnit, and artifact hashes must be rerun on
the exact artifacts.

Those gates were completed. The corrected race oracle rejected the exact
unsynchronized version-15 reference in 10/10 trials and then passed the
synchronized version-16 reference in 20/20 isolated trials. Ten complete
focused-suite repeats also passed 9/9. The broadened reverse-direction test
passes every enabled family on the reference, while an isolated plausible
BLE→USB legacy-family-only mutation scores 8/9. The exact test-only tree fails
9/9 focused and passes 541/541 baseline; the reference passes 9/9 focused and
541/541 baseline locally and in the network-disabled arbitrary-UID image. All
fifteen exact mutations are rejected.

### Version 17 trajectory-informed easing and coverage gate

This gate was recorded before revising `test.patch`. Workspace-root
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the complete same-task design
history, the version-16 requirement map and fifteen-mutant audit, the current
candidate records, and all ten raw trajectories under `agent-runs/` were read.
Searches of `problems`, `candidates`, and `archive` found no additional
same-task solver history beyond these ten runs. Because version 17 changes the
prompt and tests, the version-16 batch is abandoned as calibration evidence and
the revised immutable version starts at 0/10. The stored patches remain valid
trajectory and replay evidence only; the user has explicitly ruled out new
cold solves for this revision.

The batch produced no legitimate pass. Runs 4 and 9 are verifier/environment
blockers: both preserve the 541-test baseline, but the focused crate cannot
compile because the BLE probe imports a private parent-module
`BLE_REPORT_CHANNEL` alias that their otherwise valid writer refactor removes.
Runs 6 and 10 are the closest behavioral attempts at 1/9 focused, with only the
real BLE-steno host notification passing; both also regress two existing
non-steno report-map tests. Run 8 is the representative broad failure: it
preserves all 541 baseline tests but fails 9/9 focused because reconciliation
travels through writer-private pending state rather than the ordinary report
queues, and its state update remains outside the cutover lock. The remaining
runs split between the same private-import compile failure and 0/9 behavioral
results, often with the same unconditional BLE descriptor regression.

Raw trajectory inspection shows a consistent architecture rather than random
non-attempts. Every solver tracked absolute state and introduced a bounded
sideband release/replay path consumed by modified USB and BLE writers. Several
used a route generation or mutex, and all extended the BLE server with an
eight-byte steno characteristic. Their self-tests exercised their private
receiver paths and therefore missed both the private-alias compilation
dependency and the verifier's ordinary-channel observation boundary. This
supports two easing decisions: the BLE test will import the repository's public
channel at its defining path instead of relying on a private `ble`-module alias,
and the public prompt will state the otherwise entailed single-transport
disconnect/reconnect, family-independent dropped-state, and Plover descriptor
shape requirements directly. It will not name a cache, queue wrapper, lock,
generation, receiver function, server structure, characteristic field, or
service location.

The external review also demonstrated four plausible shortcuts not isolated by
version 16. They are admitted only where the behavior is public and the probe
adds a distinct semantic boundary:

| New evidence | Plausible incorrect implementation | Public invariant | Planned discriminator | Why distinct and fair |
|---|---|---|---|---|
| The full-queue probe covers mouse only | Remember dropped mouse state but forget another nonblocking family | Every absolute family records current state even when live nonblocking delivery is dropped | Fill the one-entry route queue, drop a steno chord, switch, and require that chord on the new route | Crosses report-family-specific producer handling; `steno` uses the repository's nonblocking producer path |
| Dual-transport tests can hide feature guards | Compile reconciliation only when BLE is present | USB-only builds reconcile USB to/from no active host | Disconnect and reconnect a held keyboard in a USB-only feature lane | Exercises a compile-time ownership boundary, not a symmetric extra fixture |
| No focused behavior runs with USB compiled out | Compile no-host reconciliation only through USB-owned code | BLE-only builds reconcile BLE to/from no active host | Disconnect and reconnect a held keyboard in a BLE-only `_no_usb` lane | Separately proves the alternate supported transport owns the lifecycle logic |
| The map oracle accepted only vendor page/report ID/count | Advertise a 64-bit vendor report with the wrong usage | BLE steno is genuinely Plover-compatible | Require Plover usage `0x4c56`, report ID `0x50`, logical collection, and 64-bit report count before host notification | Checks observable HID protocol bytes already defined by RMK's USB Plover descriptor, not private BLE layout |

The title remains an “Add” feature request. The steno paragraph will remove the
implementation-location clause about RMK's existing composite GATT service.
Instead it states the observable Plover usage, eight-byte shape, matching input
report reference, and payload order. The no-host and dropped-state clauses will
explicitly cover USB-only, BLE-only, and each enabled absolute family. These are
clarifications supported by demonstrated shortcuts; they do not broaden the
behavior requested by version 16.

Version 17 completed those gates. The test-only tree fails 12/12 focused tests
and passes 541/541 baseline tests; the reference passes 12/12 focused and
541/541 baseline tests locally and as a network-disabled arbitrary UID. The
three focused feature lanes produce distinct JUnit suites and an injected
startup failure produces three explicit errors. Nineteen exact mutations were
restarted from zero and every intended incorrect implementation was rejected.
Ten complete reference repeats pass 12/12.

All ten stored solver patches were replayed against version 17 without a cold
solve. Runs 4 and 9 now compile, eliminating the private-import verifier
blocker. Run 4 improves to 7/12; runs 3, 6, 9, and 10 score 1/12; the remaining
five score 0/12. None solves the revised problem. These are warm trajectory
replays only, so the immutable version remains at 0/10 calibration as the user
requested.

## Discriminator ledger

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Existing cleanup sends only keyboard all-up | Generalize only the oldest family | Every stateful family the old host may hold is neutralized | Deliver all five enabled families, switch, and inspect old-host output as an unordered set | Previous-host cleanup | Uses existing report variants and permits any storage/routing design |
| A cleanup-only implementation starts the new host empty | Release old state without continuity | Still-held absolute state reaches the new active host | Inspect new-host output after USB→BLE and BLE→USB handoffs | New-host replay | Requires outcomes, not a cache or queue layout |
| Event replay copies a complete mouse report | Treat relative impulses as durable state | Buttons replay; X/Y/wheel/pan do not | Handoff a report with held buttons and nonzero relative axes | Absolute/relative semantic boundary | HID descriptors mark the fields and all valid designs can normalize them |
| Current router drops disconnected reports | Track only routed traffic | Latest absolute state survives a no-host interval | Produce every family offline, connect, and inspect output | Disconnected state | Does not require event history or replay of released controls |
| Naive offline event replay creates ghost presses | Preserve events instead of current state | Press then release offline remains released | After the positive offline replay phase, disconnect, release every control offline, reconnect, and reject any pressed output | State versus history | Shares the required positive-replay discriminator while preserving silence and neutral-snapshot modes |
| A sender blocked on the old queue resumes after cutover | Select the route once before waiting | No blocked traffic appears on the previous host after transition | Fill old queue, block a mouse send, switch, then inspect both routes | Concurrency / commit timing | Reuses the repository's deterministic mock-time pattern and has no sleeps or private hook |
| Route selection, state recording, enqueue, and reconciliation use separate critical sections | Treat individually atomic steps as an atomic cutover | A producer racing a committed handoff cannot append pressed state to the cleared old route or have its latest absolute state erased from the new route | Race ordinary production against repeated cutovers; after each committed transition inspect both host queues for old-route neutrality and new-route latest state | Producer/cutover atomicity | Observes only existing routing and report outputs; permits a lock, generation/retry protocol, transactional queue, or another serialization design |
| A nonblocking producer drops both delivery and logical state when the queue is full | Conflate live delivery with current absolute state | Dropped live traffic still updates state for the next host | Fill the old queue, try-send a mouse report, switch, and inspect both routes | Nonblocking producer / state timing | `try_send_hid_report` is the repository's explicit drop-on-full path used by steno |
| Full-queue logic remembers mouse but not steno | Implement dropped-state tracking per legacy family | Every enabled absolute family records current state independently | Fill a one-entry route queue, drop a steno chord, switch, and require that chord on the new route | Optional-family producer path | Steno uses the same public nonblocking producer but a distinct feature-gated variant |
| Direct handoff works but disconnect clears the cache | Reconcile only when old and new routes coexist | A disconnect releases the old host and a later connection replays held state | Disable USB, inspect release, then connect BLE and inspect replay | Two-step lifecycle | Exercises the same public state across a real no-host interval without prescribing storage |
| Cleanup uses current state instead of what the old host may hold | Forget delivery history once a neutral report is queued | A neutral still reaches the old host when its queued copy is discarded | Consume a press, queue its release, switch, and inspect old-host output | Observed versus queued state | Distinguishes host-observed state from queue contents using existing channel semantics |
| One ordinary queue slot cannot fit all enabled families | Assume default capacity is always sufficient | Reconciliation works when configured capacity is below family count | Run the suite with a one-entry requested queue and steno, observing the existing route channels | Bounded resource/feature boundary | Configuration and enabled report variants are repository-discoverable |
| BLE routing accepts steno but the writer drops it | Stop the oracle at the transport queue | BLE+steno advertises and delivers a Plover input report to the BLE host | Connect a real in-memory GATT client, subscribe to notifications, identify the Plover report-reference handle, and inspect the emitted ATT payload | Writer / host-delivery boundary | Observes the public HID-over-GATT protocol without constructing or patching private server layout |
| A generic vendor report happens to use the right length and ID | Treat any 64-bit vendor input as Plover | BLE steno exposes the repository's existing Plover usage and logical collection | Inspect the host-visible report map for usage page, Plover usage `0x4c56`, report ID `0x50`, logical collection, and 64-bit count | HID descriptor semantics | These bytes are already defined by RMK's USB Plover descriptor and are now stated publicly |
| Reconciliation is compiled only in dual-transport builds | Put no-host lifecycle work behind the other transport's feature guard | Each supported single-transport build reconciles to and from no active host | Hold keyboard state, disconnect, require release, reconnect, and require replay in separate USB-only and BLE-only lanes | Feature ownership | Crosses two distinct compile-time configurations and does not prescribe shared-code placement |
| A narrow wrapper replaces public `Channel` statics | Preserve internal callers but break downstream channel methods | Existing public channel calls remain source-compatible | Compile representative `sender` and `receiver` calls against both public statics | Public API regression | Exercises pre-existing public declarations without demanding the reference wrapper type |

## Clause-to-test coverage

| Public requirement | Strongest observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Release and replay every enabled family | `hid_handoff_releases_and_replays_every_enabled_family` | old host receives keyboard only; new host empty | unordered five-family release/replay passes | existing `Report` variants and writer channels |
| Preserve offline absolute state and avoid ghosts after offline release | `hid_handoff_connect_replays_absolute_state_created_offline` | positive held-state phase fails because the destination is empty | all current families replay; a later all-family offline release produces no pressed output | the combined test fails on the required base delta while accepting silence or neutral cleanup |
| Both directions for every enabled family | broadened `hid_handoff_ble_to_usb_releases_and_replays_current_state` | only keyboard cleanup and no replay | unordered keyboard, mouse, media, system, and steno release/replay passes with zero relative mouse fields | explicit prompt clause and transport-specific route asymmetry |
| Producer/cutover atomicity | `hid_handoff_racing_producer_cannot_leak_or_lose_current_state` | unsynchronized selection/enqueue leaks pressed state to the cleared old route | every completed cutover leaves the old route neutral and the latest absolute producer state on the new route | core lossless-cutover contract and separate mutex/source boundaries |
| Blocked send and relative mouse semantics | `hid_handoff_blocked_report_moves_only_as_current_absolute_state` | old cleanup completes but the new state is absent | old route has no press; new route has buttons with zero deltas | drains the old route concurrently and extends an existing deterministic blocked-send unit test |
| Drop-on-full nonblocking state | `hid_handoff_dropped_nonblocking_report_still_updates_current_state` | new route remains empty | buttons replay with zero deltas | explicit `try_send_hid_report` repository path and public prompt clause |
| Drop-on-full applies independently to steno | `hid_handoff_dropped_nonblocking_steno_report_still_updates_current_state` | dropped chord is forgotten | exact eight-byte held chord replays on the new route | explicit per-family prompt clause and feature-gated repository producer |
| Disconnect interval | `hid_handoff_disconnect_gap_releases_then_replays_held_state` | old route gets keyboard only; new route empty | media releases before gap and replays after it | public disconnect-without-replacement clause |
| Queued neutral is not host-observed | `hid_handoff_releases_state_when_a_neutral_report_was_only_queued` | only keyboard release survives clear | mouse neutral is re-enqueued | existing stale-queue cleanup semantics |
| USB-only no-host transitions reconcile | `hid_handoff_usb_only_disconnect_releases_and_replays_keyboard` | disconnect emits only legacy cleanup and reconnect has no replay | held keyboard releases and replays in the USB-only lane | explicit v17 clause and supported feature combination |
| BLE-only no-host transitions reconcile | `hid_handoff_ble_only_disconnect_releases_and_replays_keyboard` | disconnect/reconnect loses held state | held keyboard releases and replays with USB compiled out | explicit v17 clause and supported `_no_usb` feature combination |
| BLE+steno advertises and delivers a Plover input report | `hid_handoff_ble_host_receives_steno_replay` | BLE report map lacks Plover and no host notification is possible | a subscribed GATT client verifies the Plover usage, logical collection, 64-bit count, report ID `0x50`, and exact chord notification | explicit public v17 protocol clause plus observable HID-over-GATT bytes |
| Preserve the public report-channel API | compile expressions in `hid_handoff_releases_and_replays_every_enabled_family` | original `Channel` methods compile | compatibility wrapper preserves `sender` and `receiver` | public statics in the pinned repository |

## Environment and harness preflight

- The exact test-only and reference trees both pass 541/541 baseline tests.
- Test-only focused behavior fails 12/12 as required; the canonical reference
  passes 12/12 with generated `REPORT_CHANNEL_SIZE` equal to one.
- The harness sets Cargo offline, builds into a unique temporary target/store,
  and synthesizes a JUnit error for any startup failure before nextest output.
- The network-disabled matrix passes as UID/GID `12345:23456`. Injecting a
  missing toolchain exits nonzero and creates one `harness-startup` error for
  each of the dual+steno, USB-only, and BLE-only lanes.
- The official RMK runtime lock is derived during the pristine image build and
  stored at `/opt/rmk-handoff/rmk.Cargo.lock`; the randomized lock in
  `test.patch` is a byte-identical local fallback. Both hash to
  `9b154a7d93f86c5fccb79ff7265042ffe7ea823add597ac19653c06457a181f1`.
  Either is installed at Cargo's mandated name solely inside the wrapper's
  disposable source copy, so the participant tree's `rmk/Cargo.lock` remains
  absent before and after a run.
  Docker also warms the supported sibling Cargo roots. Under the same arbitrary
  UID and disabled network, the previously frozen `rmk-types` and default-member
  `rynk` probes pass; their unused lockfiles are no longer shipped in
  `test.patch`. Docker supplies the DBus headers and `pkg-config` required by
  the Linux BLE member.
- Nextest process isolation is mandatory because RMK's embassy mock clock is
  process-global. No test depends on inter-test state or report-family order.

## Observation-boundary history

Version 2 read the ordinary USB/BLE queues directly. Version 3 added a
transport-aware receive function and routed both real writers through it so a
priority reconciliation lane was observable. External review later correctly
classified those non-test changes as solution code inside `test.patch`.

The first receive-seam blocked-send test also waited for the producer before
draining the writer. Version 4 corrected that scheduling artifact by draining
concurrently and retaining every report observed during cutover.

Version 5 keeps the concurrent drain but removes the receiver function and both
writer rewrites. Its pure hidden tests use the repository's existing transport
channels. The existing-channel reference passes 8/8 and 541/541; the earlier
priority lane scores 1/8 because its private reconciliation reports bypass
those channels. This is recorded as a residual false-negative risk, and version
5 makes no architecture-neutrality claim for replacement writer paths.

## Exact-version false-positive audit

`FALSE_POSITIVE_AUDIT.md` maps every public clause to its strongest oracle and
records nineteen exact version-17 mutations. The four new isolated mutants
forget only full-queue steno state, compile reconciliation only with BLE,
compile it only with USB, and advertise the wrong Plover usage; each scores
11/12 and fails only its intended discriminator. The prior narrow and broad
shortcuts remain rejected, while the narrow public-channel wrapper is rejected
at compile time. No intended incorrect mutation passes the complete focused
suite.

One exploratory narrower synchronization edit passed 12/12: it moved only the
reconciliation call outside the status lock while retaining producer
state/selection/enqueue serialization. That does not instantiate the public
race violation and may be a legitimate design. It was nevertheless run through
the full baseline and failed 29 existing tests (512/541), so it is not an
actionable survivor. No artificial probe was added for it.

The audit rejects exact order/count, private cache internals, silence-only
offline cleanup, fixed scheduling, and unrelated feature padding as artificial
probes. The older priority-lane source was not retained as a version-7 replay
artifact; its sole version-6 pass was the now-folded no-ghost test, so the
direct-channel false-negative risk remains explicit. This is a zero-survivor
false-positive result for the attempted set, not a claim that false positives
or false negatives are impossible.

Immutable hashes are recorded in `ARTIFACTS.sha256`. The exact arbitrary-UID,
network-disabled results and image digests are recorded in `VERIFICATION.md`.

## Design verdict

The version-17 reference, test-only hidden suite, aligned-lock offline harness,
and exact false-positive audit are locally verified. The canonical solution is
unchanged at 266 strict-effective production additions. The BLE test now uses
the public defining channel path and crosses the real protocol boundary through
a subscribed GATT client; it does not require a private server layout or a
particular GATT service placement. Direct-channel observation remains an
explicit residual false-negative risk for replacement writer-private designs.
Stored-patch replay is recorded as design evidence, but no cold solver
calibration has been run and this record makes no empirical acceptance-rate
claim for version 17.

### Version 18 trajectory-informed correctness and verifier-merge gate

This gate was recorded before revising `test.patch`. Workspace-root
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were read in full. Searches of
`problems/README.md`, both candidate indexes, the accepted RMK snapshot archive,
the complete same-task design history, `agent-runs/`, and `agent-runs2/` found
five new same-task Nova trajectories in `agent-runs2` and no other HID-handoff
batch. Every raw trajectory, retained patch, evaluator result, JUnit document,
and wrapper log in that directory was inspected. The accepted snapshot task is
still disjoint except for its offline/JUnit lessons.

There is no legitimate pass in the new five-run batch. Run 4 is the closest
architectural attempt and a genuine verifier blocker; run 5 is the nearest
executed feature result; run 1 is the representative broad behavioral failure.
Runs 2 and 3 independently demonstrate descriptor-API integration mistakes.
Strict-effective production LOC was not reported by the platform, so this
record does not invent it; retained raw patch additions are shown instead.

| Category | Raw trajectory and outcome | Solver architecture and proactive checks | Design consequence |
|---|---|---|---|
| Legitimate pass | Unavailable: 0/5 solved | No substitute trajectory is used | Version 18 cannot claim empirical solvability from this batch; the reference remains the local proof |
| Verifier-blocked near attempt | `Nova_Nova_4`: ten files, 744 raw additions; its own 436-test USB-only suite and focused BLE/Plover checks passed | Added a separate `hid_state.rs`, route generation, a dedicated family-sized handoff channel, writer receive integration, BLE Plover delivery, and USB-only/BLE-only tests | The grading merge failed on overlapping hidden additions in `state.rs`; the fallback reset all six test-patch files to base while retaining the solver's `channel.rs`, producing the impossible hybrid call to removed `clear_and_release_report_channel`. Hidden behavior tests must move out of the implementation file tail |
| Executed near attempt | `Nova_Nova_5`: seven files, 482 raw additions; 541/541 baseline and both single-transport keyboard tests passed | Built a bounded `ReportChannel` with a handoff queue, retained per-family state, host-may-hold bits, BLE Plover output, and multiple feature checks | It removed the original public `send`, `sender`, and `receiver` surface and the dual lane failed to compile. The existing public-API compile probe remains necessary |
| Broad failure | `Nova_Nova_1`: seven files, 728 raw additions; 541/541 baseline and 0/12 focused | Tracked every family and used writer-side generation/signals plus direct writer reconciliation; checked USB, BLE, steno, `_no_usb`, and local channel tests | Its transition path only left keyboard release in the ordinary route queues, so all queue-boundary behavior failed; it also filtered a directly queued BLE steno report as stale. Preserve host-output BLE coverage and document the direct-channel observation tradeoff |
| Integration failures | `Nova_Nova_2` and `Nova_Nova_3`: 777 and 586 raw additions; neither dual+steno lane ran | Both chose sideband/writer reconciliation and composed a BLE Plover descriptor, but used nonexistent `::DESC` associated items instead of the repository's `SerializedDescriptor::desc()` API; both omitted the exact verifier feature build from their final checks | Keep the exact dual+steno compile lane and protocol oracle; no new private descriptor implementation requirement is added |

The wrapper blocker is not evidence that run 4 would have solved the behavioral
suite. It is evidence that the verifier did not evaluate it at all. The
platform log says the three-way merge failed, reset the six test-patch files to
base, and then compiled baseline `state.rs` against the solver's changed
`channel.rs`; every reported testcase was synthetic/missing. Version 18 will
place state behavior in a randomly named test-only source module and attach it
through one small crate-root declaration. The BLE GATT probe may retain a small
additive test-module seam where private runtime access is necessary. This
reduces implementation-file overlap without widening public production APIs or
requiring the reference architecture.

Independent adversarial probes against the exact version-17 reference found a
combined plausible shortcut that passes 541/541 baseline and all 12 focused
tests: it records only blocking offline production, treats only non-neutral
nonblocking reports as worth remembering, and retains rich family lifecycle
logic only in dual-transport builds. The following version-18 discriminators
are therefore admitted:

| New evidence | Generalized shortcut | Fair public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Offline replay currently uses only `send_hid_report` | Return from the nonblocking producer when no route exists | Producer mode does not change current absolute state | Produce a mouse report through the repository's nonblocking API while disconnected, connect, and require buttons with zero relative fields | Crosses producer mode plus no-host lifecycle; no cache representation is named |
| Full-queue probes use held values only | Ignore a neutral value as “not worth replaying” | Neutral is the latest absolute state and clears a prior hold | Deliver a held mouse state, fill the queue, drop its neutral update, switch, and reject resurrection | Crosses held→neutral semantics under backpressure, unlike the existing queued-neutral host-observation test |
| Single-transport lanes cover keyboard only | Put rich family lifecycle logic behind dual-transport cfg | Every enabled family reconciles in each supported build | In USB-only+steno and BLE-only+steno lanes, hold mouse/media/system/steno, disconnect, require family-neutral old output, reconnect, and require exact held replay with zero mouse impulses | Two compile-time ownership boundaries; optional steno is repository/public-prompt supported |
| Old-route assertions search only for one neutral per family | Append releases without deleting stale non-neutral traffic | Every post-cutover old-route stateful report is neutral | Classify every report collected from the old route and reject any held absolute value | Directly tests the public stale-queue clause without requiring family order or exact counts |
| Full-queue retention covers mouse and steno only | Implement `try_send` state updates per special family | Every absolute report family updates independently | Fill the route queue separately, drop keyboard/media/system values, switch, and require each current value | Family-specific producer dispatch is independently plausible from the enum match; one table-driven test avoids fixture multiplication |

The existing 2,000-round `thread::yield_now` race is not a reliable mandatory
discriminator: it widens an interleaving but does not force it. A deterministic
black-box pause point does not exist in the pinned nonblocking producer API, and
adding a production hook in `test.patch` would be both solution code and an
implementation-shape requirement. Version 18 will retain the deterministic
full-queue blocked-send cutover oracle as the mandatory concurrency boundary
and either remove the stress test or keep it only if it cannot determine suite
success. No private synchronization hook or scheduler-dependent failure will be
introduced.

The exact false-positive pass confirmed the consequence of that boundary. An
independently applied mutation moved reconciliation outside the status critical
section and split only the nonblocking producer's route selection from its
state/enqueue work. It passed 16/16 focused and 541/541 baseline tests. Forcing
its latent race would require the removed scheduling stress or a hook into one
particular router/cache design. The public contract is therefore narrowed
explicitly to the deterministically observable blocked-send cutover; other
producer calls racing a transport setter are outside version 18. This survivor
is legitimate under the narrowed contract, not silently accepted as a false
positive. The canonical reference remains more strongly serialized.

Because `meta.md` and `test.patch` will change, all version-17 hashes, mutation
results, runtime matrices, and the five-run calibration batch are invalidated.
Version 18 starts at 0/10. Before it can freeze: both patch orders must apply
without the run-4 hybrid failure; test-only must fail every focused testcase;
the reference must pass the full three-lane focused suite and 541-test baseline;
the arbitrary-UID offline/JUnit startup matrix must pass; the exact
false-positive audit must restart from zero with the combined survivor and each
new discriminator isolated; and representative stored solver patches must be
replayed as trajectory evidence rather than counted as calibration.

### Version 18 freeze record

All prerequisites above were completed against one immutable source patch.
The seven-file `test.patch` places 1,012 lines of state behavior in randomized
test-only module `rmk/src/handoff_verifier_7c91e4.rs`; `state.rs` receives only
a four-line `#[cfg(test)]` module declaration. It contains no production
implementation. The scheduling-dependent 2,000-yield stress test is absent.

The final focused surface has 16 tests: 12 dual USB/BLE+steno, two
USB-only+steno, and two BLE-only+steno. Test-only scores 0/16; the reference
scores 16/16. Both trees pass the complete 541-test baseline. All three
warning-denying Clippy feature lanes pass, and startup failure produces three
explicit JUnit errors rather than an empty green document.

Both canonical patch orders apply cleanly and produce byte-identical
implementation files. The exact final run-4 patch also merges with all seven
hidden files retained and executes real behavior, scoring 1/16. The four other
stored patches were replayed as trajectory evidence; no stored patch solves
the revision, and no cold solver run was used.

The exact false-positive audit isolated five actionable shortcut families.
Their scores are 15/16, 15/16, 15/16, 14/16, and 13/16. The combined
version-17 survivor falls from 12/12 to 12/16. A producer/setter race mutation
survives 16/16 and 541/541 but is legitimate under the explicit frozen scope:
only the deterministic already-blocked send is required to reconcile across a
concurrent cutover. No private hook or probabilistic scheduler oracle was
admitted.

Finally, a pristine `docker build --no-cache` completed before either patch
was present. The exact test-only and reference trees then reproduced the
541/541, 0/16, and 16/16 matrix inside that image with networking disabled and
UID/GID `12345:23456`. The image manifest-list digest is
`sha256:1d24c25fd0512afb7e3054a19e4386be59ac10b41c0d67dc4751a27771fa0195`.
Exact artifact hashes are frozen in `ARTIFACTS.sha256`; calibration remains
0/10 because stored-patch replay is not a new immutable solver batch.

### Version 19 `agent-runs3` trajectory and fairness gate

This gate was completed before changing version 18's hidden tests. The
workspace `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md` were reread. The
search covered `problems/README.md`, both candidate indexes, the accepted RMK
snapshot record, all prior handoff design/audit/error records, `agent-runs/`,
`agent-runs2/`, and every raw trajectory, retained patch, evaluator result,
test log, and JUnit document under `agent-runs3/`. No additional same-task pass
exists elsewhere. The five-run batch belongs to version 18 and is abandoned at
0/5; it is trajectory evidence only and cannot count toward version 19.

There is no legitimate recorded pass. Run 2 is a verifier-blocked near-solve,
runs 1 and 3 independently chose the same writer-side architecture family,
run 4 is a broad integration failure, and run 5 is the representative
behavior-plus-integration failure.

| Category | Raw trajectory and measured outcome | Architecture and proactive checks | Version-19 consequence |
|---|---|---|---|
| Legitimate pass | Unavailable: 0/5 solved | No unrelated pass is substituted | Ease through a demonstrated implementation boundary; do not claim empirical solvability until replay/reference verification |
| Verifier-blocked near-solve | `agent-runs3/Nova_Nova_2`: seven production files, 500 raw additions; 541/541 baseline, 1/16 focused | Retained per-family absolute state, serialized routing, used fixed dedicated USB/BLE handoff queues, changed both real writers to consume `receive_hid_report`, implemented Plover GATT delivery, and checked USB-only, BLE-only, Vial, Rynk, and a 247-test BLE+steno lane | Fifteen hidden tests drained only the legacy ordinary queues and therefore bypassed the changed writers. Replace that private placement oracle with actual writer/host output |
| Independent writer-side attempts | Runs 1 and 3: eight and seven production files, 369 and 606 raw additions; each passed 541/541 and the host-level Plover test but scored 1/16 | Run 1 used per-transport reconciliation signals consumed by writers; run 3 used pending family bits and a writer receive helper. Both ran broad feature/build checks | Three independent solutions converging on writer-side reconciliation establish that dedicated output is plausible, not a one-off mutant. Queue-only observation is an actionable false negative |
| Broad integration failure | Run 4: six files, 523 raw additions; BLE verifier lanes did not compile | Added route epoch/state and BLE Plover support but used nonexistent `BleCompositeReport::DESC`; its selected checks missed the exact Rynk BLE lane | Keep the exact BLE+steno compile/host lane. This is an agent error, not an easing target |
| Behavior plus integration failure | Run 5: eight files, 798 raw additions; 541/541 baseline, 0/16 focused | Built a family-bit backlog and writer drain path, but used nonexistent descriptor constants and its size-one USB lifecycle remained incomplete | Preserve real size-one backpressure and descriptor API coverage without requiring backlog placement |

The apparent 0% success rate is therefore not clean difficulty evidence.
Three runs implemented reconciliation at the real writer boundary, while the
state verifier observed a different internal boundary. Run 2's evaluator
correctly classified this as `FAIL_TEST_MISMATCH`; the conflicting run-1/run-3
evaluations treated the public legacy channel as the host itself even though
their writers had been changed to consume sideband reconciliation. Version 19
accepts ordinary-channel backlogs, dedicated queues, signals, family masks, or
other bounded designs when the actual transport writer emits the required
reports.

The five trajectories also show that USB-only and BLE-only all-family behavior
adds distinct conditional-compilation work on top of the already coupled dual
transport, backpressure, and Plover implementation. Version 19 removes that
single-transport behavioral requirement as its explicit easing lever. Supported
feature compilation remains regression coverage, but focused semantics are
defined for the dual USB/BLE build and transitions through no active host.

#### Version 19 discriminator ledger

| Evidence | Generalized shortcut or false result | Fair public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Runs 1–3 emit reconciliation through writer-private paths | Correct host behavior is rejected because reports are absent from legacy queues | Hosts, not an internal queue, receive releases and replay | Exercise the real USB writer with a scripted endpoint and the real BLE writer with the in-memory GATT host; classify serialized host packets/notifications | Crosses the repository's existing external-effect boundary and accepts queue, signal, mask, and lazy-backlog architectures |
| Review found mouse-only dropped-neutral coverage | Cache nonzero values for keyboard/media/system/steno but ignore later dropped neutral values | A dropped neutral nonblocking update clears prior absolute state independently for every enabled family | Under a full ordinary queue, submit held then neutral keyboard/media/system/steno state, cut over, and reject every stale held value at writer output | One table-driven family-state transition, not four duplicate fixtures; distinct held-to-neutral/backpressure boundary |
| Runs 4–5 misuse descriptor APIs | Plover map compiles only in a solver's selected feature lane | Required dual BLE+steno surface compiles and exposes the declared report | Retain the real GATT report-map/reference/payload probe in the exact Rynk+BLE+steno lane | Integration boundary is public protocol behavior, not descriptor layout |
| Version 18 direct stale-queue probes | Append releases without removing stale traffic | Post-cutover old-host output contains no stale held state | Queue a held report before cutover and reject held serialized output on the old host while requiring family releases | Tests stale traffic at writer output without prescribing storage or count/order |
| Version 18 blocked-send probe | A send blocked on the old queue escapes after cutover or is forgotten | The already-blocked send is the frozen concurrent boundary | Fill the old route, poll the send pending, cut over, then drain real writer output and require latest absolute state only on the new host | Deterministic backpressure interleaving; no scheduler stress or private hook |

No hidden test will call a candidate-added receive helper or inspect a private
handoff queue. The verifier may use test-only mock transport infrastructure,
but it must run the repository's actual writer task and assert serialized host
output. Exact family order, queue choice, backlog representation, and GATT
service placement remain out of scope. The prompt, tests, reference matrix,
false-positive audit, and artifact hashes must all restart after this change;
version 19 begins at 0/10 and no unused version-18 runs carry forward.

### Version 19 freeze record

The planned redesign was implemented as seven host-observed tests. USB probes
run the actual `UsbKeyboardWriter` with test-only endpoints, and the BLE probe
runs `run_ble_keyboard` with an in-memory HCI/GATT host. The test patch no
longer changes `state.rs`; it adds randomized test source
`rmk/src/usb/handoff_host_probe_5e2a91.rs`, a four-line test module declaration
in `usb/mod.rs`, and tests inside the existing BLE test module. No test calls a
candidate-added helper or drains a private reconciliation path.

The final suite explicitly separates neutral clearing into mouse and
keyboard/media/system/steno cases so both sentinels fail on the pristine tree.
The test-only tree passes 541/541 baseline and fails 0/7 focused; the reference
passes 541/541 and 7/7. Dual, USB-only, and BLE-only warning-denying Clippy
lanes pass. Both patch orders apply and produce byte-identical implementation
files. Startup failure creates one explicit JUnit error.

The exact false-positive audit independently kills ten plausible mutants:
offline nonblocking loss; neutral filtering for mouse, keyboard, media,
system, or steno; omitted old-host release; a one-slot reconciliation backlog;
post-delivery-only blocked-send recording; and a wrong Plover report reference.
There are zero actionable survivors in that attempted set. No scheduling-only,
private-layout, or duplicate symmetry probe was admitted.

Corrected replay of `agent-runs3` gives run 1 6/7 because its pending send can
still emit held mouse state to the old USB host, runs 2 and 3 7/7, and runs 4
and 5 genuine BLE descriptor compile failures. This turns the prior apparent
0% into two demonstrated legitimate passes without weakening the public
blocked-cutover or host-protocol contracts. No cold solve was used.

The pristine-built Docker image was reused because neither Dockerfile nor its
base repository changed. With networking disabled and UID/GID `12345:23456`,
it reproduces 541/541 and 0/7 for test-only and 541/541 and 7/7 for reference.
Final artifact hashes are recorded in `ARTIFACTS.sha256`. Version 19 remains
calibration 0/10.

### Version 20 transition-composition design gate

This gate was completed before revising version 19's hidden tests. I reread
the workspace `PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, and `candidates/SUCCESSES.md` for RMK, HID,
handoff, transport, and Plover history; reread the current compact summary and
error records; and inspected raw `run.txt`, evaluator JSON, production patches,
and relevant routing/writer hunks for representative `agent-runs3` runs 1, 2,
and 4. The earlier snapshot task is same-repository prior art only and has no
handoff trajectory relevant to these transition boundaries.

Run 2 remains the representative legitimate pass under the host-observed
version-19 verifier. It tracks per-family absolute state, uses dedicated
handoff channels consumed by both real writers, and proactively exercised
USB-only, BLE-only, Vial, Rynk, and BLE+steno configurations. Run 1 is the
representative near-pass: its pending-family writer architecture passes 6/7
but permits an already-blocked mouse send to escape to the old USB host. Run 4
is the representative broad failure: it attempts a complete separate handoff
lane and Plover integration but does not compile because it assumes a
nonexistent `BleCompositeReport::DESC`. No category was filled with unrelated
evidence, and no cold run was used.

Review of the exact version-19 tests found two transition-composition holes.
The blocked-send test proves only that the old USB writer does not emit the
held mouse state, then switches back to USB to observe eventual replay. It
does not observe the immediately selected BLE host. Separately, the suite
covers state produced with no active host and direct USB/BLE changes, but not
state first observed by an active host, followed by a real no-host interval,
then activation of the other host. Both behaviors are already stated in the
public prompt and require no description expansion.

#### Version 20 discriminator ledger

| Evidence | Generalized shortcut or false result | Fair public invariant | Black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Version-19 blocked-send test observes only old USB and later USB reactivation | Record a pending send globally but defer delivery until some later route transition | A report already blocked during cutover belongs to the immediately newly active host | Poll the send pending on a full USB queue, select BLE, and require the real GATT host to receive the absolute mouse buttons with relative fields zeroed during that BLE activation | Completes the two-sided deterministic cutover contract; it observes protocol output and does not prescribe queue, signal, or pending-bit storage |
| Existing tests cover offline-origin state and direct handoff, but not active → none → different host | Preserve state only for direct replacement or only for values created while disconnected | State already held by an active host survives a no-active interval and is replayed when the other host activates | Produce and drain all family state while BLE is active, transition BLE to inactive while USB is disabled, then activate USB and require the real USB writer to emit the held snapshot | Exercises transition composition rather than another family permutation; one table-driven all-family snapshot avoids representation or ordering assumptions |

The first probe will be integrated into the existing in-memory BLE host test,
where the BLE writer and Report Reference are already observed. The old-host
half remains a USB writer test but will be named for the behavior it actually
proves. The second probe will use the existing USB mock writer and will not
inspect the new host's legacy queue. Exact report ordering and counts remain
out of scope. Because hidden tests change, version 20 restarts the runtime,
false-positive, stored-replay, and immutable-hash gates at calibration 0/10.

### Version 20 freeze record

The two planned oracles were implemented without changing `meta.md` or the
reference solution. The in-memory GATT test now polls a mouse send pending on
the full USB route, performs one USB-to-BLE selection, and requires report ID 2
to carry `[5, 0, 0, 0, 0]` at that immediately active BLE host. The future is
not awaited inside the BLE-only writer probe because no USB writer exists there
to drain the old-host release; the separately executed USB-writer phase proves
that completion does not leak the report to old USB.

The no-host probe first retains that deterministic old-host assertion, then
neutralizes its phase state through the public producer path. It delivers all
five held families while BLE is active, moves through a checked
`active_transport() == None` interval, activates USB, and classifies the real
USB endpoint snapshot. Combining the two USB phases keeps every focused
testcase fail-to-pass on pristine while preserving mutation isolation.

The exact test-only/reference matrix is 541/541 baseline for both, 0/7 focused
for pristine, and 7/7 focused for reference. Three warning-denying feature
lanes pass. Both patch orders apply and are byte-identical. Startup failure is
one explicit JUnit error. The exact focused matrix also reproduces in the
pristine-built image with networking disabled and UID/GID `12345:23456`.

Eleven independent plausible mutants compile and fail. The two new isolated
mutants both score 6/7: one records a full blocking send only after the old
queue wakes, so immediate BLE misses it; the other clears absolute state on
entry to no-host mode, so later USB replay is empty. No mutation survives.

All five `agent-runs3` patches were replayed without a cold solve. Runs 2 and 3
remain architecture-independent 7/7 passes. Run 1 remains 6/7 because its
blocked mouse state escapes onto old USB. Runs 4 and 5 retain their exact
descriptor-API compile failures. Version 20 is frozen at calibration 0/10 with
hashes in `ARTIFACTS.sha256`.

### Version 21 `agent-runs4` trajectory and asymmetry gate

This gate was completed before changing version 20's prompt or hidden tests. I
reread the workspace `PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, and `candidates/SUCCESSES.md` for RMK, HID,
transport, handoff, and Plover history; and reread this problem's compact
summary, false-positive audit, and error record. The five `trajectory.json`
files in `agent-runs4` are empty, so the raw evidence used instead was every
retained production patch, evaluator result, test log, baseline/focused JUnit
document, and representative writer/routing hunk. No unrelated task was used
to fill a missing category, and no cold solver was launched.

The batch contains two legitimate passes, two behavioral failures, and one
broad integration failure:

| Category | Raw outcome | Architecture and evidence | Version-21 consequence |
|---|---|---|---|
| Legitimate pass | `Nova_Nova_2`: 541/541 baseline and 7/7 official focused | Uses fixed dedicated per-transport handoff channels consumed by both real writers, retains independent family state, and implements BLE Plover delivery | Preserve writer/host observation; do not require reconciliation to use the public ordinary queues |
| Independent legitimate pass | `Nova_Nova_3`: 541/541 baseline and 7/7 focused | Uses per-transport handoff signals, pending family state, and writer helpers rather than the reference backlog | Confirms that queue, signal, and pending-bit designs can all satisfy the host contract |
| Near-pass | `Nova_Nova_5`: 541/541 baseline and 5/7 focused | Uses a pending-family writer path but leaves previous-route replay work alive; held keyboard and blocked mouse state reach old USB | Retain immediate per-packet stale-output rejection; final-value snapshots are insufficient |
| Incomplete behavior | `Nova_Nova_1`: 541/541 baseline and 2/7 focused | Adds writer-side handoff signals and Plover GATT support, but release/replay is wrongly conditional on current transport readiness | Keep disconnect release and offline/current-state replay as observable writer obligations |
| Broad integration failure | `Nova_Nova_4`: neither lane compiles | Attempts a sideband family-mask design but references nonexistent descriptor constants such as `BleCompositeReport::DESC` | Retain exact dual BLE+steno compile and real GATT coverage; this is not an easing target |

Review of the exact version-20 verifier and isolated adversarial probes found
six related but semantically distinct asymmetries. The BLE release loop stores
only the final payload per family, so a stale packet can be overwritten by a
later neutral packet. Direct USB-to-BLE cutover observes only a keyboard release
at old USB. No real BLE host is activated after an offline interval. The suite
also omits BLE-to-none all-family release, USB-held state carried through none
to BLE, and the already-blocked full-queue boundary in the BLE-to-USB
direction. Plausible implementations for the last three pass all seven current
focused tests and all 256 tests in the relevant complete base lane, while
host-observable prototypes pass the reference and reject them.

#### Version 21 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| BLE release packets are collapsed into a final-value map | Append stale held traffic before valid neutral releases | Stale old-route traffic is discarded, not merely followed by a release | Validate every real GATT notification as it arrives and reject any non-neutral old-host payload before recording family coverage | Checks the traffic stream rather than final state; no order, count, queue, or storage representation is prescribed |
| Direct USB-to-BLE phase stops after a neutral keyboard packet | Release only keyboard on old USB while replaying every family to BLE | Every family the old host may hold is released on direct cutover | Dirty all five families at USB, then classify actual `UsbKeyboardWriter` packets and require every observed packet neutral plus all-family coverage | Exercises the old-host half of the already-covered direction at the real endpoint |
| Offline replay is host-observed only for USB | Preserve disconnected state only when USB becomes active | A newly active host receives current absolute state regardless of transport | Produce held mouse/media/system/steno plus a pressed-then-cleared keyboard while no route is active, activate BLE, and inspect real notifications; mouse impulses must be zero and no held keyboard may appear | Crosses no-route producer semantics with the BLE writer and includes a cleared control without requiring neutral replay to be emitted |
| BLE-to-USB direct release exists, but BLE-to-none release does not | Treat a disconnected BLE peer as needing no releases | The previous host receives releases even when no replacement becomes active | While the in-memory BLE host remains observable, move logical BLE state to inactive with USB disabled and require neutral notifications for all dirty families | Distinguishes disconnect-without-replacement from direct replacement without depending on physical radio teardown |
| BLE-held-to-none-to-USB exists, but USB-held-to-none-to-BLE does not | Clear the snapshot only on USB disconnection | State held by an active host survives a no-host interval for the next transport | Deliver all five families to USB, enter verified no-host state, activate BLE, and require the exact real GATT snapshot with zero mouse impulses | Tests transition composition in the missing transport direction, not another isolated family fixture |
| The deterministic blocked-send boundary starts only on USB | Recheck route after USB backpressure but capture BLE forever | An already-waiting send cannot escape its old route and belongs to the newly active host in either direction | Fill BLE, poll a mouse send pending, cut to USB, reject held buttons in every old-BLE notification, and require `[buttons, 0, 0, 0, 0]` at the real USB endpoint | Symmetry is justified by distinct writer/backpressure code paths and a demonstrated transport-specific mutant |

The public concurrency scope will be restated in natural issue prose without
expanding it: only a send already waiting on a full queue during cutover is
required; other races between report production and connection-state updates
remain out of scope. Tests will continue to use the repository's actual USB
writer and in-memory BLE/GATT host. The suggested direct-channel probes are
useful mutation prototypes but are rejected as final oracles because runs 2 and
3 legitimately route reconciliation through writer-private queues or signals.

Because `meta.md` and `test.patch` will change, all version-20 hashes, runtime
results, mutation results, and stored replay outcomes are invalidated. Version
21 restarts at calibration 0/10. Before freeze it requires a pristine/reference
baseline and fail-to-pass matrix, all warning-denying feature lanes, both patch
orders, startup-error JUnit, arbitrary-UID offline execution, an exact
false-positive audit including all six new shortcut families, and replay of the
five stored `agent-runs4` patches. Stored replays remain trajectory evidence,
not cold calibration runs.

### Version 21 freeze record

The public concurrency sentence now reads as natural issue scope: a send
already waiting on a full queue must not escape the old route and its latest
absolute state must reach the new host; other producer/connection-state races
are not in scope. No behavior was added beyond the prior public contract.

The final seven-file test patch contains only configuration, the randomized
fallback lock, the offline/JUnit wrapper, tests in the existing BLE test
module, a randomized USB test module, and its four-line `cfg(test)` attachment.
It does not edit `channel.rs`, `state.rs`, `hid.rs`, either production writer,
or any production API. The focused lane remains a genuine one-entry ordinary
queue and now has eight fail-to-pass tests.

All planned host-observable probes were implemented. Every BLE release packet
is validated when it arrives, so a later neutral packet cannot hide stale
traffic. Direct USB-to-BLE verifies all-family neutral output at old USB. The
real GATT host observes nonblocking offline state and USB-held state after a
no-host interval, including zero mouse impulses and no ghost key. Logical
BLE-to-none emits all-family releases at the still-observable GATT host. A send
polled pending on full BLE is rejected at old BLE and replayed immediately at
the real USB writer.

The exact local and fresh-container matrices are identical: pristine and
reference each pass 541/541 baseline; pristine fails all 8 focused tests; the
reference passes all 8. Three warning-denying Clippy lanes, formatting, both
byte-identical patch orders, one explicit startup-error JUnit testcase, and ten
consecutive focused reference runs pass.

Seventeen independent compiling mutants have zero survivors. The six admitted
version-21 shortcuts score 6/8, 7/8, 7/8, 7/8, 7/8, and 6/8 for stale append,
USB-only keyboard release, omitted BLE activation replay, omitted BLE-to-none
release, USB-only state erasure on disconnect, and BLE-specific blocked-send
capture. No survivor required full-suite escalation.

All five `agent-runs4` patches were replayed. Runs 2 and 3 retain independent
writer-side passes of every official focused test. Run 1 scores 2/8, run 5
scores 5/8, and run 4 retains its genuine descriptor-constant compile error.
No cold solver was launched.

Finally, Docker was rebuilt with `--no-cache` from the pristine repository
before either patch was injected. Image
`sha256:16ede2a9a30247ca3bc24d42c3cb0c7ec806d8d8bde5dcf44070b33afa563656`
reproduces the complete 541/541, 0/8, and 8/8 matrix with networking disabled
as UID/GID `12345:23456`. Exact artifact hashes are frozen in
`ARTIFACTS.sha256`; calibration remains 0/10.

### Version 22 descriptor-structure and multi-entry stale-queue gate

This gate was completed before revising version 21's hidden tests. I reread
`PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and the compact records
under `problems/` for RMK, HID handoff, report channels, steno, and Plover;
then reread this problem's version-21 design, summary, error, and audit
records. No newer calibration trajectories exist. The five retained
`agent-runs4` `trajectory.json` files are empty, so the raw evidence remains
their production patches, evaluator results, test logs, and JUnit documents.
I re-inspected the representative legitimate passes (`Nova_Nova_2` and
`Nova_Nova_3`), behavioral near-pass (`Nova_Nova_5`), incomplete run
(`Nova_Nova_1`), and broad integration failure (`Nova_Nova_4`). No unrelated
run was substituted and no cold solver was launched.

The descriptor review confirms an oracle weakness, not a new requirement.
RMK's repository Plover descriptor is a Logical collection selected by usage
page `0xff50` and usage `0x4c56`; inside it, report ID `0x50`, one-bit report
size, count 64, and a Data/Variable/Absolute Input item jointly declare the
eight-byte chord. Version 21 merely finds some of those byte fragments
anywhere in the composite map. A malformed map can therefore scatter the
fragments across unrelated collections or omit the Input item. Runs 2 and 3
both produce a coherent generated collection despite choosing different map
composition and handoff architectures, so parsing the host-visible HID items
preserves both legitimate solutions.

The queue review likewise confirms a distinct capacity boundary. The public
task says stale queued traffic must be discarded and that ordinary queue
capacity cannot be assumed to match the family count. Version 21 runs every
focused behavior with capacity one, which proves bounded reconciliation but
cannot distinguish clearing the whole old-route queue from removing only its
first entry. The repository exposes `Channel::clear`, and both legitimate
passing runs clear the complete ordinary route independently of their private
release/replay mechanism. A second lane with capacity three can preload
multiple ordinary stale packets, cut over, and classify every packet emitted
by the real old USB writer. The original capacity-one lane remains intact so
the two resource boundaries are tested independently.

#### Version 22 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Version-21 Plover assertions search unrelated byte windows in the complete composite map | Advertise a malformed HID map containing the expected constants without one usable Plover input declaration | BLE+steno exposes a genuinely Plover-compatible 64-bit input report | Parse the host-readable report map and require usage page `0xff50`, usage `0x4c56`, Logical collection, report ID `0x50`, 64 total input bits, and a Data/Variable/Absolute Input item in the same collection | Validates HID protocol structure rather than Rust types, field layout, descriptor generator, map offsets, or service internals; generated-map designs from both legitimate passes remain accepted |
| The only behavioral lane has `report_channel_size = 1` | Remove one queued packet on cutover and mistake that for draining the old route | Every stale queued packet for the previous route is discarded at any supported configured capacity | In a separate capacity-three lane, queue three distinct non-neutral packets on active USB, switch to BLE, and reject every non-neutral packet observed from the real USB writer while still requiring the complete neutral release set | Exercises queue multiplicity rather than family-count pressure; it does not prescribe `clear`, queue replacement, sideband channels, signals, ordering, or exact packet count |

The descriptor parser will be local test code and will reject truncated HID
items as well as structurally incoherent Plover fragments. The larger-capacity
probe will use a randomly suffixed configuration filename, while preserving
the existing one-entry configuration and excluding the multi-entry testcase
from that lane. Because `test.patch` changes, version 22 invalidates all
version-21 runtime, mutation, stored-replay, and immutable-hash results and
restarts calibration at 0/10. Before freeze it requires the complete
pristine/reference matrices, warning-denying lanes, patch-order checks,
startup-error JUnit, arbitrary-UID offline execution, an exact false-positive
audit including both new shortcuts, and replay of all five stored
`agent-runs4` patches. No cold solver runs are authorized.

### Version 22 freeze record

The final verifier implements exactly the two planned discriminators. A local
HID short-item parser rejects truncated items and accepts Plover only when
usage page `0xff50`, usage `0x4c56`, a Logical collection, report ID `0x50`,
explicit report size/count totaling 64 bits, and a Data/Variable/Absolute
Input item are structurally connected. Report Reference and exact eight-byte
notification checks remain host-observed. Both stored legitimate map-generation
approaches pass the parser.

The original eight focused tests still compile with generated
`REPORT_CHANNEL_SIZE = 1`. A separately named configuration generates size
three for one additional USB writer test, which queues three distinct held
packets before cutover, validates every emitted packet as neutral, and requires
all five release families. The wrapper keeps separate JUnit documents for the
two lanes and merges them. Test-only scores 0/8 plus 0/1; the reference scores
8/8 plus 1/1. Both trees independently pass the complete 541-test baseline.

All exact quality gates pass: the eight-file test-only patch has 5,132
additions and one deletion, with no production implementation edit; formatting and three
warning-denying Clippy feature lanes pass; both patch orders are byte-identical;
missing-toolchain startup yields two explicit JUnit errors; and ten consecutive
reference iterations pass both lanes.

Nineteen independent mutants compile and have zero combined survivors. The
fragment-only descriptor mutant passes seven of eight one-entry tests and the
multi-entry test, failing only the semantic GATT oracle. The clear-one-entry
mutant passes all eight one-entry tests and fails only the capacity-three
probe. The other seventeen mutations were repeated against the exact version
and remain rejected; none needed full-suite escalation.

All five `agent-runs4` patches were replayed without a cold solve. Runs 2 and 3
remain independent 9/9 legitimate passes. Run 1 scores 3/9, run 5 scores 5/9,
and run 4 retains its descriptor-API compile error. The unchanged pristine
no-cache image was reused because the base pin and Dockerfile did not change.
After runtime-only patch injection, network-disabled containers as UID/GID
`12345:23456` reproduce both 541/541 baselines, pristine 0/9, and reference
9/9. Exact hashes are frozen in `ARTIFACTS.sha256`; calibration remains 0/10.

### Version 23 directional-neutral and BLE stale-queue gate

This gate was completed before revising version 22. I reread
`PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and the related compact
problem records for RMK, HID handoff, report-channel capacity, stale traffic,
dropped neutral state, BLE, USB, steno, and Plover. I also reread this
problem's current public requirements, design ledger, audit, verification,
level, error, summary, and handoff records. The repository seams remain the
public transport state setters, ordinary report channels, and the real USB and
BLE writers; there is no new private implementation requirement.

Raw evidence exists in all five retained `agent-runs4` trajectories, solution
patches, logs, and evaluator results. I re-inspected the independent legitimate
passes (`Nova_Nova_2` and `Nova_Nova_3`), the near-pass (`Nova_Nova_5`), the
incomplete behavioral attempt (`Nova_Nova_1`), and the broad integration
failure (`Nova_Nova_4`). Runs 2 and 3 both use writer-consumed sideband state
but differ between dedicated per-transport queues and pending family signals;
both clear USB and BLE ordinary queues and retain neutral updates as absolute
state. Run 5 independently implements route-specific replay slots but misses
part of the public surface. Run 1 makes route handling conditional in ways
that expose directional asymmetry. Run 4 attempted a family-mask design and
failed at the repository descriptor API. The successful trajectories therefore
support host-visible tests in both directions without prescribing queue,
signal, mask, or backlog internals. No cold solver was launched.

The reported dropped-neutral gap is a distinct transport-output boundary. The
current verifier proves that a neutral update dropped from a full BLE route
replaces prior held keyboard, media, system, and steno state before USB replay;
it does not prove the same state replacement before BLE replay. Because the
public contract requires both directions and implementations have separate
writer paths, an otherwise complete implementation can apply neutral snapshots
only to USB-bound replay. A new host-level BLE phase may fill the active USB
ordinary queue, drop neutral updates, switch to BLE, and reject every prior held
value in real GATT notifications. It need not require a neutral notification:
absence of the stale held value is the portable observable contract.

The capacity-three gap is independent from that state-replacement direction.
Version 22 proves complete disposal of three queued packets only when USB is the
old route. The BLE writer and notification path are separate, and the public
stale-traffic rule applies to either previous route. A second capacity-three
host probe may enqueue three distinct non-neutral packets on active BLE before
the BLE writer consumes them, cut over to USB, then run the real BLE writer and
reject every stale non-neutral notification while requiring the expected
neutral releases. This tests queue multiplicity on the BLE boundary without
mandating how disposal or release delivery is represented.

The harness comment about an “official image” is not operational guidance and
will be removed. The fallback behavior itself remains unchanged and continues
to install the image-provided pristine lock when available or use the committed
randomized lock otherwise.

#### Version 23 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Full-queue neutral replacement is observed only on BLE-to-USB replay | Record dropped neutral values only for USB-bound replay, leaving previously held state cached for the BLE writer | A dropped neutral report is the latest absolute state for both handoff directions and every family | Fill the active USB ordinary queue, submit neutral keyboard/media/system/steno updates nonblocking, activate BLE, and reject each prior held value in real BLE host notifications | Crosses state replacement with the other real writer; it does not require emission order, a particular neutral packet, or candidate-private storage |
| The only multi-entry stale probe has USB as the old route | Drain the complete USB queue but remove only one stale BLE packet | Every stale packet for either previous route is discarded at supported queue capacities | Under the existing capacity-three configuration, queue three distinct held BLE packets, cut over to USB, and reject every non-neutral packet observed from the old BLE host while requiring release output | Exercises the separate BLE writer/GATT boundary and queue multiplicity; it does not prescribe `clear`, queue ownership, signals, masks, or exact release order |
| `test.sh` explains the authoring image instead of only the operation | Carry evaluator-specific framing into the participant harness | Harness comments should document behavior needed to run it | Remove the framing sentence and retain only the fallback operation | Hygiene-only; no behavioral discriminator or environment assumption changes |

Because the tests and harness change, version 23 invalidates the version-22
runtime, mutation, replay, and immutable-hash results and keeps calibration at
0/10. Before freeze, the exact revision requires the pristine/reference base
and focused matrices, formatter and warning-denying feature lanes, both patch
orders, startup-error JUnit behavior, repeated reference execution, offline
arbitrary-UID execution, an exact false-positive audit with both directional
shortcuts, and replay of the retained solver patches. No cold solve is planned.

### Version 23 freeze record

The final verifier implements exactly the two planned behavioral probes and
the harness comment cleanup. The existing BLE GATT exercise is factored behind
two test entrypoints. With generated capacity one it retains the original eight
focused tests. With generated capacity three it joins the USB multi-entry probe
and queues three distinct stale packets on BLE without an intervening await,
then validates every real notification and the late-output drain. The same GATT
exercise now establishes held keyboard, media, system, and steno state on USB,
fills the active USB queue, submits neutral replacements nonblocking, activates
BLE, and rejects each old held value while using a held mouse replay as a
positive completion marker. It does not require neutral replay packets or a
candidate-private state representation.

The exact test-only patch is an eight-file Git diff with 5,279 additions and one
deletion. It applies cleanly to the pristine pin and contains no production
implementation edit. Test-only and reference trees each pass the complete
541-test baseline. The test-only focused lanes fail 0/8 and 0/2; the reference
passes 8/8 and 2/2. Formatting and warning-denying dual, USB-only, and BLE-only
Clippy lanes pass. Test-first and solution-first application produce the same
staged diff SHA-256
`c4abf1b8d9264bf11869a804080433a649d183d966318dbafd44fc16e123be43`.
An intentionally missing toolchain yields two explicit JUnit startup errors,
and ten consecutive reference iterations pass both focused lanes.

Twenty-one independent compiling mutants have zero combined survivors. The
new ignore-neutral-only-on-USB mutant scores 7/8 plus 1/2 and fails the BLE
directional phase. The new clear-one-only-on-BLE mutant passes 8/8 and the old
USB capacity-three test, then fails the BLE capacity-three test for 1/2. The
other nineteen mutations were replayed against this exact test revision and
remain rejected. Since no mutant survived both lanes, none required escalation
to the full pre-existing suite; both exact baseline trees independently pass it.

All five stored `agent-runs4` patches were replayed. Runs 2 and 3 remain
independent legitimate 10/10 passes despite their different writer-side
architectures. Run 1 scores 3/10, run 5 scores 6/10, and run 4 retains its
genuine descriptor-API compile error. No cold solve was launched.

The Dockerfile and pristine repository pin are unchanged, so the exact no-cache
image
`sha256:16ede2a9a30247ca3bc24d42c3cb0c7ec806d8d8bde5dcf44070b33afa563656`
was reused. The current patches were injected only at runtime into writable
copies. With networking disabled as UID/GID `12345:23456`, independent
containers reproduce both 541/541 baselines, pristine 0/10, and reference
10/10. Artifact hashes are frozen in `ARTIFACTS.sha256`; calibration remains
0/10.

### Version 24 non-steno feature gate

This gate was completed before revising version 23. I reread
`PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and the related compact
records for RMK, HID handoff, feature gating, optional steno, ordinary report
families, and report-channel capacity. I reread the current public prompt,
design ledger, error record, verification, audit, summary, and handoff. The
public contract applies to every enabled report family and says steno applies
when enabled; therefore the ordinary build without `steno` is directly in
scope rather than an inferred compatibility permutation.

I also re-inspected all five retained `agent-runs4` trajectories, final
messages, solution patches, logs, and evaluator results. The independent
legitimate passes (`Nova_Nova_2` and `Nova_Nova_3`) put their core absolute
state and writer reconciliation outside `cfg(feature = "steno")`, gating only
the fifth family and Plover surface. The near-pass (`Nova_Nova_5`) likewise has
explicit steno and non-steno descriptor/writer branches. The incomplete run
(`Nova_Nova_1`) reports USB-only verification and implements separate family
counts, while broad failure `Nova_Nova_4` attempts an unconditional family-mask
core but fails at descriptor integration. Their effective production diffs
remain seven files +632/-63, six +516/-43, seven +594/-36, seven +634/-71,
and seven +856/-40 respectively. This evidence supports testing the ordinary
feature surface without requiring any one queue, mask, signal, or state layout.
No cold solver was launched.

The current hidden behavior modules are both compiled only with `steno`:
the in-memory GATT host is nested beneath `cfg(feature = "steno")`, and the
USB writer probe is attached beneath the same feature. A solution can therefore
place all reconciliation behind the optional feature and pass every current
behavior test. Warning-denying non-steno compilation would not detect that
behavioral omission.

The fair discriminator is a separately named no-steno test module attached
only for dual USB/BLE builds without `steno`. Using the real USB writer and an
ordinary queue of one, it can first observe four-family neutral release when
USB becomes the old route, then make BLE active, record four-family held state
while its live queue is full, switch back to USB, and observe exact replay with
mouse impulses zeroed. This covers both transport directions at the USB host
boundary and every family enabled in that build. It does not inspect private
reconciliation storage or require BLE Plover behavior when steno is absent.

#### Version 24 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Every current behavior module requires `steno` | Put the entire handoff implementation behind `cfg(feature = "steno")`; ordinary keyboard/mouse/media/system builds compile but retain baseline routing | Handoff applies to every enabled family, and steno is conditional rather than required | In a no-steno dual-transport lane at capacity one, observe real USB output for all four releases on USB-to-BLE and all four exact replays on BLE-to-USB, including zero mouse impulses | Crosses an untested conditional-compilation surface and real writer boundary; it does not duplicate a fixture, require the fifth family, or prescribe internal storage |

Because `test.patch` and the wrapper change, version 24 invalidates version 23's
runtime, replay, audit, and immutable-hash results and remains at calibration
0/10. Before freeze it requires the complete pristine/reference matrix, exact
feature and formatting checks, both patch orders, startup-error JUnit, repeated
reference execution, offline arbitrary-UID reproduction, replay of retained
solver patches, and the mandatory exact false-positive audit. No cold solve is
planned.

#### Version 24 partial verification record

The planned no-steno probe and third wrapper lane are implemented in exact
`test.patch` SHA-256
`58c8b9437b4543043920f83f50f0d7aad1a7569a625e09bf1a1afbe92625f3cf`.
The patch is a nine-file, test-only diff with 5,647 additions and two context-
preserving blank-line deletions. It adds
`handoff_no_steno_probe_c84d17.rs`, attaches it only when `_ble` is enabled and
`steno` is disabled, and runs it in a capacity-one dual-transport lane.

The exact local wrapper matrix passes 541/541 baseline on both test-only and
reference trees. Test-only fails all 11 focused tests; the reference passes all
11, partitioned as 8/8 steno capacity one, 2/2 steno capacity three, and 1/1 no
steno capacity one. Formatting and warning-denying no-steno Clippy pass. Both
patch orders apply cleanly and yield staged diff SHA-256
`d8d358db911de67bb5872ed8bd01f9f9e0e4681cd30002d1b284276ebaa6d1cb`.

At the user's explicit direction, no version-24 false-positive audit was run.
The revision is therefore recorded as an unapproved draft rather than frozen
or submission-ready. Stored-solver replay, repeated execution, startup-error
JUnit, and offline arbitrary-UID checks were also not rerun. No cold solver was
launched.

### Version 25 host-probe watchdog fairness gate

This gate was completed before changing version 24's verifier. I reread
`PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and related compact
records for RMK, HID handoff, timeout, watchdog, liveness, mock host, and
scheduling evidence; and reread the current prompt, design, error, audit,
verification, summary, and handoff records. The public task specifies state and
delivery semantics but no latency. Repository search finds no one-second HID
handoff convention, while the existing USB writer has a 500 ms endpoint retry
path. The reported one-second cutoff is therefore a verifier liveness choice,
not a participant-facing invariant.

I also re-inspected the retained `agent-runs4` evidence. The legitimate passes
(`Nova_Nova_2` and `Nova_Nova_3`) use different writer-side backlog/signal
architectures; the near-pass (`Nova_Nova_5`) has separate steno/non-steno
writer branches; broad failure `Nova_Nova_4` fails descriptor compilation; and
run 1 reaches the host tests but misses release/replay behavior. Their strict
effective production sizes remain six files +516/-43, seven +594/-36, seven
+856/-40, seven +634/-71, and seven +632/-63 respectively. None establishes or
relies on a one-second public completion promise. The one-second expressions
visible in stored workspace diffs are copies of the injected verifier, not
solver-selected product behavior.

The fair repair is not to remove deadlock protection. Each in-memory host
exercise still needs a harness liveness guard so a broken writer cannot stall
the evaluation indefinitely. Version 25 will replace each exact one-second
cutoff—including BLE connection acceptance, BLE observation, and both USB
writer exercises—with a named, generous 30-second test-harness watchdog. A
comment will state that it is not a firmware latency assertion. No public
prompt, behavioral assertion, queue boundary, output oracle, or reference
implementation changes.

#### Version 25 discriminator ledger

| Evidence | Unfair rejection mode | Public invariant retained | Planned oracle | Anti-overfit rationale |
|---|---|---|---|---|
| The verifier chooses one second; the prompt and repository define no such latency, and USB may spend 500 ms in one retry | A semantically correct but slower implementation or loaded CI worker times out before observable output | Required release, replay, stale disposal, and BLE Plover output must eventually be observed | Keep every host-visible assertion but apply only a named 30-second harness deadlock watchdog to the enclosing mock exercise | Separates evaluator liveness from product timing; accepts all architectures and schedules that complete within an operationally generous test bound |

Because `test.patch` changes, version 25 invalidates version 24's exact runtime,
patch-order, hash, and partial-verification record and remains at calibration
0/10. The exact revision requires the pristine/reference matrix, feature and
formatting checks, patch-order check, startup JUnit, repeated reference runs,
offline arbitrary-UID reproduction, stored-solver replay, and false-positive
audit. No cold solver is planned.

### Version 25 freeze record

The verifier implements only the planned fairness repair. Its three host probe
modules define the same named 30-second `HOST_PROBE_WATCHDOG` and immediately
describe it as test-harness deadlock protection rather than a firmware latency
requirement. BLE connection acceptance, the enclosing BLE observation future,
and both USB writer exercises use that constant. No `from_secs(1)` remains in
the test patch. The prompt, reference solution, queue boundaries, feature
lanes, and every host-visible assertion are unchanged.

The exact test patch SHA-256 is
`f0be551e47e566721303b7afe3a20c334faf33d91f3273235281401273ba9a74`.
It is a nine-file, test-only Git diff with 5,656 additions and two
context-preserving deletions. Test-only and reference trees each pass the
complete 541-test baseline. Test-only fails all eleven focused tests with
assertions and no wrapper errors; the reference passes 8/8 at steno capacity
one, 2/2 at steno capacity three, and 1/1 at no-steno capacity one.

Formatting and warning-denying dual-steno, USB-only-steno, BLE-only-steno, and
dual-no-steno Clippy lanes pass. Both patch orders apply cleanly and produce
staged diff SHA-256
`edea7a346622ac9687bb028a6a06354cb993426261408b491b2250419128a0ef`
and Git tree `48f4a76912c7a84ea41561cccb9813683477e8b1`. An intentionally missing
toolchain produces three explicit lane-specific JUnit startup errors. Ten
consecutive exact reference iterations each pass the complete 11-test matrix.

The exact false-positive audit applies 22 plausible incorrect implementations
independently across all three lanes and has zero combined survivors. The new
non-steno omission mutant passes 8/8 and 2/2 with steno but fails 0/1 without
steno, isolating the new conditional-compilation boundary. The other 21
mutants retain their distinct rejections. Since no mutant survives the focused
matrix, none needs full-baseline escalation; both exact trees independently
establish the 541/541 baseline.

All five retained `agent-runs4` patches were replayed without cold solves. Two
independent writer-side architectures pass 11/11. Run 1 scores 3/11, run 5
scores 6/11, and run 4 retains its descriptor-API compile error. The unchanged
pristine no-cache image
`sha256:16ede2a9a30247ca3bc24d42c3cb0c7ec806d8d8bde5dcf44070b33afa563656`
was reused because neither the Dockerfile nor repository pin changed. After
runtime-only patch injection, networking-disabled containers as UID/GID
`12345:23456` reproduce both 541/541 baselines, pristine 0/11, and reference
11/11. Artifact hashes are frozen in `ARTIFACTS.sha256`; calibration remains
0/10.

### Version 26 offline family-replacement gap gate

This gate was completed before revising version 25's hidden tests. I reread
workspace `PROBLEM_DESIGN.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and compact records for
RMK, HID handoff, disconnected production, neutral replacement, current
absolute state, report-family independence, and steno chords. I reread this
problem's prompt, current verifier, reference state machine, summary, errors,
levels, verification record, and exact false-positive audit.

Raw same-task evidence exists in all five retained `agent-runs4` trajectories,
solution patches, logs, and evaluator records. I re-inspected legitimate passes
`Nova_Nova_2` and `Nova_Nova_3`, near-pass `Nova_Nova_5`, broad descriptor
failure `Nova_Nova_4`, and incomplete behavior run 1. Runs 2 and 3 remain the
critical architecture check: one stores complete per-transport handoff reports
in dedicated queues consumed before ordinary writer traffic; the other signals
writers to serialize a current state snapshot directly. Run 5 uses
route-specific slots. All three record reports before route availability, but
none makes the legacy ordinary queue the authoritative reconciliation surface.
Their raw final messages also explicitly claim disconnected, neutral, and steno
handling. Therefore any new oracle must observe real host output, not require a
replay to appear in `USB_REPORT_CHANNEL` as the supplied draft probes do.

The current host test proves only keyboard held-to-neutral replacement while
both events occur with no active host. Mouse, media, system, and steno are left
held in that phase. Later full-queue neutral tests cover those families while a
transport is active, which is a different route branch. The public prompt says
“A control pressed and released while disconnected” and independently applies
current-state tracking to every absolute family. A cache may therefore handle
offline keyboard correctly yet treat neutral updates for other disconnected
families as no-route no-ops. The reported media-only survivor is plausible
because `Report` dispatch stores every family separately and because active,
full-queue, and disconnected paths are distinct in both the repository and
solver patches.

The current suite also tests one held steno chord and held-to-neutral steno, but
never two different nonzero chords before replay. The public rule requires the
latest absolute state, not merely whether a family is active. A first-nonzero
steno latch can pass the existing held and neutral checks while replaying an
older chord. The supplied demonstrated survivor and the feature-gated steno
match arm provide evidence for this separate value-replacement mode.

The admitted repair keeps the current public prompt and reference solution.
One real-USB-writer probe will produce held and then neutral values for every
family while no route exists, activate USB, and reject any non-neutral ghost
packet while using a new live keyboard packet as a positive progress marker.
It accepts silence and neutral cleanup for released controls. A second
real-writer probe will produce two distinct offline steno chords and require
the exact second chord at the host. Neither test reads the ordinary channel as
the result oracle or names a cache, queue, signal, mask, order, or private state
representation.

#### Version 26 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Offline held-to-neutral host coverage is keyboard-only; a demonstrated media-neutral survivor passes all version-25 lanes | Record held values while disconnected but discard neutral no-route updates for selected non-keyboard families | A control pressed and released while disconnected is not held when a host activates, independently for every absolute family | Produce held then neutral keyboard, mouse-button, media, system, and steno state with no route; activate USB; reject every non-neutral offline value at the real endpoint while requiring a distinct live marker | Crosses the no-route branch with family-specific replacement in one table-driven lifecycle, rather than four duplicate fixtures; silence and neutral output both pass |
| Existing steno checks cover one nonzero value and nonzero→zero only; a demonstrated first-chord latch passes version 25 | Treat steno as a boolean/latch and ignore later nonzero chord values until neutral | The newly active host receives the latest absolute value, including an exact changed steno chord | Produce chord A then chord B offline, activate USB, and require chord B from the real steno endpoint | Tests value replacement rather than another direction or fixture; preserves dedicated-queue and writer-signal implementations and uses repository-defined Plover bytes |

Because `test.patch` changes, version 26 invalidates every version-25 runtime,
audit, replay, stability, patch-order, and immutable-hash result. The finalized
revision requires a fresh gap analysis, fairness analysis, false-positive
audit, pristine/reference matrix, stored-solver replay, feature/formatting
checks, patch-order and startup checks, repeated execution, and offline
arbitrary-UID reproduction. No cold solver is planned; calibration remains
0/10.

### Version 26 freeze record

The admitted tests use ordinary producers and the real USB writer. The
all-family offline test records held then neutral state before any host has
been active, accepts only neutral family output or a distinct live keyboard
progress marker, and then proves positive all-family offline-held replay. The
steno test records chord A then chord B and requires exact B at the steno USB
endpoint. Direct-channel and standalone silence-passing drafts were rejected.

The exact test patch SHA-256 is
`1dc550cfc84ff87c01cb17a1210090d35431dafa37bbdd3838a59de8da72af7c`.
Test-only and reference trees each pass 541/541 baseline. Test-only fails all
13 focused tests with assertions and no wrapper errors; the reference passes
10/10 at steno capacity one, 2/2 at steno capacity three, and 1/1 at no-steno
capacity one.

Formatting and warning-denying dual-steno, dual-no-steno, USB-only-steno, and
BLE-only-steno Clippy checks pass. Both patch orders apply cleanly. The combined
staged diff SHA-256 is
`d565abb432afcfb7c4f89abca69f87124d818ac5b8ecb6af00163d245abcaf23`
and the Git tree is `5b22f0bf7fe623c58b57c062c134ae6ca78c89f3`.
Missing Cargo produces three explicit lane-specific JUnit errors. Ten repeated
frozen reference matrices pass 13/13, and the unchanged image passes the
focused matrix network-disabled under a non-root UID.

The exact gap and fairness analyses both conclude `pass`. Twenty-four
independent plausible mutants have zero combined survivors. The new offline
neutral shortcut scores 11/13; the first-chord steno latch scores 12/13 and is
isolated to the new test. Stored runs 2 and 3 remain legitimate passes with
different writer-side architectures, while runs 1, 4, and 5 retain genuine
behavioral or compile failures. No cold solve was launched; calibration remains
0/10.

### Focused BLE writer-reconnect correction gate

This correction is limited to the demonstrated false positive in
`agent-runs5/Nova_Nova_3`. I reread `PROBLEM_DESIGN.md`, the current BLE host
probe, the reference queue replacement path, and that run's raw solution patch.
The existing probe keeps one `run_ble_keyboard` future alive across every BLE
state transition. Real connection teardown instead drops that writer before
`set_ble_state(Inactive)` runs. The retained patch clears the old BLE queue and
then enqueues a neutral compatibility marker during that transition, but its
`None -> BLE` transition schedules an out-of-band replay without clearing the
ordinary BLE queue. A fresh writer therefore emits the correct held replay and
then the orphaned neutral marker, clearing the new host.

| Trajectory/repository evidence | Plausible false result | Public invariant | Focused discriminator |
|---|---|---|---|
| `run_ble_keyboard` is per connection; the outer BLE loop marks the connection inactive after it returns. The retained passing patch leaves the old-route neutral marker in the ordinary queue while reconnect Replay is out of band. | A single persistent verifier writer drains the marker, while a real fresh writer replays held state and then clears it. | A transition through no active connection preserves the latest absolute state for the next host, and stale traffic from the previous output must not overwrite it. | End the first real BLE writer while BLE is active, mark BLE inactive with no fallback route, reconnect, start a fresh real writer, observe held Replay, then require a live marker without any intervening stale neutral keyboard report. |

This is a writer-instance lifecycle boundary, not another queue-capacity or
state-permutation probe. Per the operator's explicit request, only the focused
reference and retained false-positive replay will be run; this draft is not an
immutable-version approval and no broader gap, mutation, or cold-solver audit
is claimed.

### Focused no-steno BLE-host coverage gate

The reported feature-matrix gap is real and narrow. The current no-steno lane
uses the real USB writer, while the real BLE GATT host probe is compiled only
with `steno`. Repository routing and the retained solver patches independently
feature-gate steno branches, so a solution can implement correct BLE handoff
only in its steno build and still pass the present no-steno test. The public
handoff contract applies to every enabled family regardless of whether steno
is compiled.

| Evidence | Plausible false result | Public invariant | Focused discriminator |
|---|---|---|---|
| The only no-steno host probe observes USB; the BLE host-output module is gated by `feature = "steno"`. | Put BLE release/replay logic behind the steno branch while leaving ordinary keyboard, mouse-button, media, and system BLE builds unchanged. | USB/BLE handoff applies independently to every enabled stateful family and must not depend on steno. | In the no-steno lane, use the real BLE writer and mock GATT host to observe exact keyboard, mouse-button, media, and system Replay, then observe neutral release for all four families. |

The public description will also be condensed without changing this contract.
Per the operator's request, verification remains limited to the focused
pristine/reference behavior and formatting; no cold-solver or broad mutation
batch is planned.

### Version 27 producer-mode and BLE mouse-neutral gap gate

This gate was completed before revising the current hidden patch. I reread the
workspace `PROBLEM_DESIGN.md`, `GAP_ANALYSIS.md`, and `FAIRNESS_ANALYSIS.md`;
searched `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, and compact problem records for RMK, HID handoff,
disconnected production, blocking and nonblocking producers, dropped neutral
mouse state, USB-to-BLE replay, and writer lifecycle; and reread the current
problem design and public contract. The current `test.patch` also contains two
focused corrections made after the version-26 freeze record, so version 27
will verify and hash those actual bytes rather than carrying forward the stale
version-26 artifact claim.

Raw same-task evidence exists in `agent-runs4` and `agent-runs5`. I inspected
the independent legitimate passes `agent-runs5/Nova_Nova_1`,
`Nova_Nova_3`, and `Nova_Nova_6`; the no-host near-pass `Nova_Nova_2`; the
BLE-release near-pass `Nova_Nova_10`; and the broad descriptor failures in
runs 4, 5, and 8. The three legitimate implementations use different
writer-side pending mechanisms, but all record an absolute report before the
early no-active-route return in both `send_hid_report` and
`try_send_hid_report`. Runs 1 and 6 keep the state in the channel router; run 3
records it through the HID module. This makes producer mode a real public API
boundary without favoring one cache, queue, signal, or module layout.

The current offline host probes comprehensively exercise every family through
`try_send_hid_report`, while the blocking `send_hid_report` path is exercised
offline only for media. The two functions have independent bodies in the
pinned repository and in every reviewed solution. An implementation may
therefore record all nonblocking offline reports but special-case or omit
non-media blocking reports before its no-route return. The fair discriminator
is one real-USB-writer scenario that submits held and then neutral keyboard,
mouse, media, system, and steno reports through `send_hid_report` while
disconnected, proves that no stale held state ghosts after USB activates, then
submits a second held all-family snapshot through the same API while
disconnected and requires its exact replay. It keeps relative mouse fields
zero and does not require those calls to enqueue ordinary traffic while
disconnected.

The BLE directional-neutral gap is separate. Existing full-queue mouse-neutral
coverage replays toward USB. The real BLE host phase fills USB and checks
dropped neutral keyboard, media, system, and steno updates, but uses a held
mouse as its progress marker. Since the writers and per-route replay state are
independent, a solution can ignore only a neutral mouse update dropped on USB
when BLE will become active. The fair oracle establishes held mouse buttons at
the active USB host, fills its ordinary queue, submits a neutral mouse update
nonblocking, and switches to BLE. It rejects any stale nonzero mouse
notification while a distinct held system report proves BLE replay progressed;
silence and an explicit neutral mouse notification are both accepted.

#### Version 27 discriminator ledger

| Evidence | Generalized shortcut or false result | Public invariant | Planned black-box oracle | Distinct boundary / anti-overfit rationale |
|---|---|---|---|---|
| Offline all-family tests use the nonblocking producer; only media currently crosses the blocking producer | Record offline reports in `try_send_hid_report`, but let `send_hid_report` return on no route before recording selected families or neutral replacements | Reports produced while disconnected define the latest absolute state regardless of which existing producer API emitted them | Submit held→neutral for all five families through `send_hid_report`, prove no ghost after activation, then submit and require a second exact held snapshot with zero mouse impulses | Crosses a separate public producer body and every report arm while checking both replacement polarities; it does not require queuing while offline, completion timing beyond the harness watchdog, or private state placement |
| Dropped-neutral mouse is host-observed only when USB is the destination; the USB-to-BLE GATT phase excludes mouse from its neutral set | Preserve stale mouse buttons only on BLE-bound replay after a full USB queue | A dropped neutral nonblocking update is the current absolute mouse-button state in both handoff directions | Deliver held mouse state on USB, fill USB, drop the neutral update, activate BLE, reject nonzero mouse notifications, and require an independent system replay marker | Crosses the BLE writer/GATT boundary and mouse match arm; accepts neutral output or silence and does not prescribe report order or representation |

Because `test.patch` changes, every prior hash, runtime, gap, fairness,
false-positive, replay, stability, and patch-order result is invalid for version
27. The exact revision requires fresh pristine/reference matrices, an exact
gap and fairness analysis, the mandatory false-positive audit, all retained
mutation and solver-patch replays, formatting and feature checks, both patch
orders, startup-error JUnit, repeated execution, and offline arbitrary-UID
reproduction. No cold solver will be launched; calibration restarts and remains
at 0/10.

### Version 27 exact freeze

Version 27 is bound to repository pin
`65df15775026bad1189139613ee3d338139bec3d`, prompt SHA-256
`481414885f4127a20baaaea611124dd5cee5a0233152ac32ec52327ee2ec3ab9`,
test SHA-256
`de4f9fe964140fc54ec0eaee9c1c87413feb5835b6758ff42071e761da929e71`,
reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and Dockerfile SHA-256
`88dbbf3d4269d123263a61fc8a245d5d180698088236e619b2f22fa327e191ac`.
Both patch orders produce staged diff SHA-256
`36429e6a273933ff3b195a99691b5df134b68ca053487ff729051506788a90ea`
and Git tree `31739b78cdc41a6dff09aa2e4d9c423b6331b513`.

The exact test-only tree passes 541/541 baseline and fails all 14 focused
tests. The exact reference passes 541/541 baseline and all 14 focused tests,
split 10/10 at capacity one with steno, 2/2 at capacity three with steno, and
2/2 at capacity one without steno. Ten consecutive reference matrices pass.
Formatting and four warning-denying Clippy feature lanes pass, both patch
orders commute, and an absent Cargo executable yields three explicit JUnit
errors.

The exact false-positive audit independently applies 27 plausible incorrect
implementations across all three lanes and has zero combined survivors. The
three version-27 mutants each score 13/14: omit blocking offline non-media
state, ignore only BLE-bound dropped neutral mouse state, or ignore blocking
neutral updates while disconnected. Fifteen retained solver patches were
replayed; none passes the exact focused matrix, so none is escalated as a
focused survivor. No cold solver was run.

The exact gap and fairness analyses both pass. Full Cartesian duplication of
producer API, destination, family, and capacity cells was rejected where the
repository and reviewed architectures share one state-recording branch; the
admitted cases cross independent producer bodies or real USB/BLE writer
boundaries. The unchanged Docker image could not be re-entered because the
local Docker Desktop engine remained unresponsive after launch; version 27
therefore records the fresh arbitrary-UID container rerun as an environment
blocker and does not reuse version 26's runtime result as exact-version
evidence. Calibration remains 0/10.

### Version 28 trajectory-informed easing gate

This gate was completed before changing the version-27 submission artifacts. I
reread `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, and the current problem's compact records for RMK,
HID handoff, Cargo locking, feature matrices, release ownership, reconnect,
blocking producers, and calibration history. Same-task raw evidence exists in
`agent-runs5` and `agent-runs6`, so no unrelated trajectory was substituted.

The representative legitimate passes are `agent-runs5/Nova_Nova_1` and
`Nova_Nova_6`. They passed 541 baseline and all 13 then-current focused tests
using distinct writer-side designs over six and seven production files,
respectively; their strict effective production sizes are 704 and 594 lines.
The current near-pass `agent-runs6/Nova_Nova_2` passes baseline and 11/14
focused tests with a seven-file, 518-line implementation, but its writers emit
old neutral or stale replay state before the current snapshot. The broad
failure `agent-runs6/Nova_Nova_1` is still a substantial six-file, 484-line
implementation; it validated against an unlocked `usbd-hid` 0.10.1 graph and
then failed the authoritative 0.10.0 evaluator graph at `BleCompositeReport::DESC`.
`Vega_Nova` independently compiled all lanes with a 689-line implementation
but retained an old release ahead of replay and scored 8/14. Platform final
messages generally claimed successful local feature validation, confirming
that solve-time commands did not reproduce the evaluator's exact dependency
and feature surface.

Across `agent-runs6`, four implementations reached all 14 tests, one reached
only the two no-steno tests, and four could not compile the focused steno lane.
The compile failures converge on a Docker mismatch: the image stores the
authoritative lock under `/opt` but removes `rmk/Cargo.lock` from the solver's
tree. Solvers therefore created writable temporary Cargo homes, resolved
`usbd-hid` 0.10.1, and exercised feature sets different from the evaluator's
locked `rynk,_ble,split,async_matrix,storage,steno` lane. This is accidental
solve friction, not desired implementation difficulty.

The behavioral failures also converge, but remain a fair core challenge. A
release is cleanup for the retiring writer/connection; preserving that cleanup
in a shared route queue lets a fresh connection replay current held state and
then consume an orphaned neutral report. Separately, `send_hid_report` and
`try_send_hid_report` have independent bodies, and several solutions recorded
offline state in only the locally exercised producer path. The current prompt
states the outcomes but does not name these repository-visible seams.

Version 28 is a measured easing revision, not a discriminator reduction. It
will keep `test.patch` and `solution.patch` byte-for-byte unchanged. The Docker
image will leave the authoritative `rmk/Cargo.lock` at the normal package path,
and the public description will provide one exact locked/offline validation
command with an absolute keyboard-config path (Cargo runs package build scripts
from the crate directory). The description will also state, without prescribing storage or
signaling architecture, that both existing producer APIs update absolute state
before route/enqueue decisions and that retiring-route release work must not be
consumed by a fresh writer after a no-host interval.

#### Version 28 easing ledger

| Trajectory evidence | Generalized failure | Public invariant retained | Easing action | Why difficulty remains |
|---|---|---|---|---|
| Four of nine current runs compile against a different `usbd-hid` API than the evaluator; another misses the exact `rynk` steno surface | Local success on an unlocked, non-authoritative dependency/feature graph | Participant validation and grading must compile the same source against the same supported graph | Keep `rmk/Cargo.lock` in `/app/rmk` and publish the exact locked/offline steno build command | Removes environment guessing only; it supplies no handoff implementation |
| Every compiled current failure mishandles release versus replay, including the 11/14 near-pass and Vega's independent 8/14 design | Treat a neutral release as global queued state that can outlive its retiring writer/connection | Release old-host state, discard stale traffic, and begin a fresh connection from the latest absolute replay | Clarify release ownership and reconnect ordering at the behavioral level | Solvers must still design atomic cutover, stale disposal, per-family state, and real writer delivery |
| The new blocking-producer discriminator is a common failure; reviewed code and solutions have distinct blocking/nonblocking bodies | Record disconnected/full-queue state in only one producer API | Both public producer paths contribute to the same latest absolute state before routing can discard delivery | Name `send_hid_report` and `try_send_hid_report` as equal state inputs | Still requires implementation in two async/nonblocking paths and preservation of blocked-send cutover semantics |

The nine version-27 results and the operator's tenth run remain bound to version
27. Any version-28 calibration begins at 0/10 after its exact checks. Based on
the earlier 3/10 version-26 pass evidence, the retained stronger 14-test suite,
and the removal of four compile-only losses, the intended solve-rate band is
roughly 20–35%, not an all-pass easing. This is a forecast; only a fresh
ten-run batch can establish the accepted percentage.

### Version 28 local verification and review record

Version 28 is bound locally to prompt SHA-256
`8edf6e7e8c6fdce63c21c2f2feaecf0a3d4c9af6cd0bcda1171a4b4c7a89437c`,
test SHA-256
`de4f9fe964140fc54ec0eaee9c1c87413feb5835b6758ff42071e761da929e71`,
reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and Dockerfile SHA-256
`1144dffae8447e34209b9abbb07091f6ab66d277441103e2ed4b598c6e6dc0c9`.
The executable patches retain version 27's combined staged-diff SHA-256
`36429e6a273933ff3b195a99691b5df134b68ca053487ff729051506788a90ea`
and Git tree `31739b78cdc41a6dff09aa2e4d9c423b6331b513`.

The literal solver-facing command was executed from a clean repository root
with the evaluator lock and succeeds locked/offline on
`rynk,_ble,split,async_matrix,storage,steno`, compiling `usbd-hid` 0.10.0. A
first draft used a relative `KEYBOARD_TOML_PATH` and correctly failed because
Cargo runs the package build script from its crate directory; the published
command now uses `$PWD` and passes.

The fresh test-only matrix fails all 14 focused cases. The fresh reference
passes 541/541 baseline and 10/10 capacity-one steno, 2/2 capacity-three steno,
and 2/2 capacity-one no-steno. Both patch orders apply and execute because the
first reference tree used test-then-solution and the second verification tree
used solution-then-test. `git diff --check` passes.

The exact-version gap and fairness reviews pass without adding a probe: the new
text names dimensions already tested by byte-identical verifier code and does
not prescribe private state representation. The refreshed false-positive audit
replays two independent candidate controls. `agent-runs5/Nova_Nova_1`, a
legitimate 13-test pass on the earlier version, now scores 12/14 and fails the
blocking producer plus fresh BLE writer boundaries. `agent-runs6/Nova_Nova_2`
scores 11/14 and additionally fails multi-stale BLE cutover. The retained
27-mutant table remains exact byte-identity evidence because neither test nor
reference bytes changed; no focused survivor exists.

Docker Desktop's engine did not return `docker info`, so the changed Dockerfile
could not receive a fresh image or arbitrary-UID offline run. The version-27
image is invalidated and is not reused. Version 28 is locally behaviorally
verified but is not declared submission-ready or eligible for calibration
until that environment gate is completed. Calibration is 0/10.

### Focused `rmk-macro` offline environment correction

The reported failure is an image-cache omission, not another behavioral design
gap. The repository's own `rmk-macro` test target declares `macrotest` and
`trybuild` only as dev-dependencies and exercises them under `_simulator`.
Version 28 warms `rmk` and `rynk`, but never resolves the standalone
`rmk-macro` test graph, so `CARGO_NET_OFFLINE=true cargo nextest run --features
_simulator` cannot start in `/app/rmk-macro` when `macrotest` is absent from the
registry cache.

The focused repair is to compile that exact test target with `--no-run` while
the Docker build still has network access, retain its generated package lock,
and run `cargo fetch --locked` for target-only members of that graph. The first
focused reproduction proved why both steps are needed: compilation cached
`macrotest` and `trybuild`, allowing 48/49 tests to run, but macrotest's nested
metadata call still needed the target-only `wasi` archive. After fetching it,
the expansion test reached its repository-defined `cargo expand` subprocess;
the image did not install that command. The accepted same-repository
`rmk-portable-configuration-snapshot` environment already pins
`cargo-expand` 1.0.124 for this exact test, so this Dockerfile will install the
same Rust-1.95-compatible version with `--locked`. No prompt, hidden test,
reference behavior, or solver-facing requirement changes. Per the
operator's request, validation is limited to the exact
standalone offline runner and artifact consistency; no new behavioral probes,
gap search, mutation batch, or cold solver is warranted for this cache-only
change.

The isolated reproduction then performed the Dockerfile sequence in a fresh
Cargo home: compile `rmk-macro` tests with `_simulator`, fetch the locked graph,
and install `cargo-expand` 1.0.124. With `CARGO_NET_OFFLINE=true`, the reported
`cargo nextest run --features _simulator` command starts and passes all 49 tests,
including the five macro-expansion fixtures and compile-fail target. No other
test matrix was rerun for this environment-only correction.

### Solver-visible evaluator-surface clarification

The fairness report correctly identifies that a promise of an authoritative
lock is insufficient if a solver cannot tell where or when it appears. The
current Dockerfile already leaves the generated evaluator lock at
`/app/rmk/Cargo.lock`; unlike version 27, it does not remove that file. The
public description will name that exact pre-solve path and tell solvers not to
regenerate it. This is a documentation correction, not another lock or test
mechanism.

The same report identifies queue capacity as a central but under-advertised
validation dimension. Repository configuration publicly defines
`[rmk] report_channel_size`, and the focused suite uses the independently
meaningful capacities one and three: one proves reconciliation cannot require
one ordinary slot per family, while three proves complete stale-queue disposal.
The prompt will disclose both values and the existing `KEYBOARD_TOML_PATH`
mechanism without revealing hidden filenames, fixtures, test order, or private
assertions. No behavioral test or reference change is planned.

Both documented queue configurations were compiled with the exact
locked/offline steno feature command: capacity one completes in the clean
reference tree, followed by capacity three. This validation compiles the
advertised public surface only and does not rerun the behavioral suite.

### Version 29 trajectory-informed discriminator gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, then searched the current
problem history and inspected the compact and raw records in `agent-runs7`.
The five version-28 attempts all produced substantive six-file implementations:
`Nova_Nova_2` is the representative near-pass at 12/14 focused tests and 463
strict effective production lines, while `Nova_Nova_1` and `Vega_Nova` are
representative broad failures at 8/14 with 436 and 792 lines. Earlier
legitimate passes in `agent-runs5` remain architecture controls, but no
version-28 run passed. Every run-7 solver did execute the published full-example
and small-channel compile commands successfully; the remaining failures are
behavioral, not another offline dependency mismatch.

The review exposed two distinct omissions. First, the public validation command
names `examples/use_config/nrf52840_ble/keyboard.toml`, but the hidden runner
compiled only generated capacity-one and capacity-three configurations. The
revision will add a compile-only preflight for that exact repository example
before the focused lanes. It is an environment/configuration-surface check, not
a new behavioral testcase, and therefore will produce a harness error only if
the promised surface cannot compile. Second, the existing full-queue cutover
test proves the blocking `send_hid_report` branch only for mouse. The repository
dispatches each `Report` variant independently, and the public contract names
keyboard, mouse, media, system control, and steno, so a plausible variant-specific
implementation can preserve only mouse in the blocked branch. One existing host
test will be strengthened to poll one blocked send per enabled family during the
same cutover and require one exact replay snapshot. This keeps the focused test
count unchanged and adds one semantic boundary rather than five fixtures.

#### Version 29 discriminator ledger

| Evidence | Plausible incorrect behavior | Public invariant | Oracle/probe | Decision |
|---|---|---|---|---|
| All run-7 agents followed the exact example-config command, while `test.sh` exercised only minimal generated configs | A change passes hidden minimal configs but breaks the documented real configuration | The published locked/offline validation command is part of the reproducible participant surface | Compile the exact example config locked/offline before focused lanes; report startup error on failure | Add as one harness preflight, with no passing testcase |
| The current pending-send host probe constructs only `MouseReport`; report variants have independent state-dispatch arms | The full-queue blocking path records/reroutes mouse but loses another enabled absolute family | A send already blocked at cutover must preserve every enabled report family's latest absolute state | Fill the old route once, poll blocked sends for all five families, cut over, and observe one exact USB replay snapshot | Strengthen the existing test; do not multiply cases |
| Existing focused lanes already cover try-send, offline state, reconnect, both transports, capacities one/three, and no-steno | Cartesian duplicates can inflate the suite without a new semantic discriminator | Tests should target independent modes, not every permutation | Retain all other tests unchanged | Reject additional permutations |

The description will also replace evaluator-image wording with ordinary
repository validation guidance. This changes no product requirement. Because
the prompt and verifier bytes change, version 29 is a new immutable version:
calibration resets to 0/10 and the exact false-positive audit and artifact
hashes must be refreshed after verification.

### Version 29 verification and false-positive record

Version 29 is bound to prompt SHA-256
`15c22eae573f9dd8b31fd47f9c534c3c6c7f8dae5926285a8220638f8967a79c`,
test SHA-256
`b0461340f3ecf1e28221c3ef64156d812c8f717c0e5486be122cb6c7e61f30d8`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`1144dffae8447e34209b9abbb07091f6ab66d277441103e2ed4b598c6e6dc0c9`.
Both patch orders apply cleanly and produce combined staged-diff SHA-256
`1153b7655af660290ce90b5e68b6d8ea6d4a423fb5341ee73b0b9c108bca9e25`
and Git tree `559138e262038f6ccfc7c73af471406682881172`.

The test-only wrapper executes the exact full-example preflight successfully
and then fails every one of the 14 focused behavioral tests. The reference
executes the same preflight, passes all 14 focused tests, and passes 541/541
selected pre-existing tests with two skips. The focused count is unchanged:
10 capacity-one steno, 2 capacity-three steno, and 2 capacity-one no-steno.

The exact false-positive audit maps the public requirements to their strongest
host observations in `FALSE_POSITIVE_AUDIT.md`. A new plausible mutant records
full-queue blocking updates only for mouse while handling disconnected and
ordinary sends normally. It passes the entire previous 14-test suite, including
both other lanes, but fails the strengthened all-family blocked-send probe. All
previous mutation discriminators remain present: thirteen test bodies are
unchanged and the fourteenth is a strict semantic strengthening. No current
focused survivor exists, so no mutant qualifies for full-baseline escalation.

For architecture controls, the earlier legitimate
`agent-runs5/Nova_Nova_1` solution and the current `agent-runs7/Nova_Nova_2`
near-pass both pass the strengthened test. The near-pass remains 12/14 and
continues to fail its two independent lifecycle requirements. This confirms the
new test rejects the variant-specific shortcut rather than either solver
architecture. Pristine remains 0/14. No cold solver was launched, and any
version-29 calibration starts at 0/10.

After verification, the public description was compressed from 287 to 220
words and all evaluator-image wording was removed. The exact false-positive map
was repeated against the final prompt hash: every behavioral and validation
invariant above remains explicit, with no added predicate or changed oracle.

### Version 30 trajectory-informed easing gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, searched the complete local
history for this problem, and inspected both compact evaluations and
representative raw patches from `agent-runs8`. Version 29 has seven substantive
attempts: five Nova runs and two much larger Vega runs. They all compile and run
the focused suite, so there is no common environment blocker. The Nova attempts
pass 6--8 of 14 focused tests after adding 369--628 raw production lines; the
Vega attempts pass 7--8 after adding roughly 560 and 818 lines and consuming
about 6.2M and 6.5M total tokens. The two baseline bookkeeping failures in the
Vega reports concern renamed test node IDs and do not explain the shared focused
failures.

The failure matrix shows one dominant architectural bottleneck rather than
fourteen independent mistakes. Five lifecycle tests fail in every Nova run and
also fail in both Vega runs: BLE all-family lifecycle, USB capacity-three stale
cutover, USB blocked/no-host lifecycle, USB disconnect release, and USB
no-steno lifecycle. Six state-update tests pass in every Nova run. Representative
architectures include synchronized writer state, router-owned release slots,
writer-start snapshots, one-shot release signals, and generation-aware writer
sessions; all converge on correct state replacement while failing durable
all-family release ownership across disappearing writer instances. Earlier
passes in `agent-runs5` remain legitimate controls, but they do not outweigh the
current 0/7 result on the immutable version-29 artifacts.

The repository already has a conventional all-up keyboard report, whereas the
version-29 problem expanded that mechanism into an all-family release protocol
owned by a retiring writer even after its connection disappeared. That is the
main accidental difficulty. Version 30 will preserve the portable state cache,
small-queue cutover, stale-traffic disposal, all-family replay, mouse impulse
normalization, and BLE Plover support, while narrowing old-host neutralization
to the conventional all-up keyboard report on a direct USB/BLE handoff. A
transition to no active host need only preserve state for later replay; it need
not write to a host that is already gone. The prompt will describe observable
outcomes and remove the instruction that state recording occur before route or
enqueue decisions. It will also stop requiring `send_hid_report` calls made
with no active route to behave as offline state updates; the nonblocking
producer remains explicitly responsible for current-state updates while offline
or full, and an already blocked active-route send remains cutover-safe.

#### Version 30 easing ledger

| Trajectory evidence | Version-29 burden | Version-30 public boundary | Verifier action |
|---|---|---|---|
| All 7 runs fail writer-lifecycle release tests despite 369--818 added lines and several distinct synchronization designs | Every stateful family must be released through the retiring writer, including disconnect without replacement | Direct handoff discards stale traffic and emits the repository-conventional all-up keyboard report; disconnect-to-none preserves state without requiring output to a vanished host | Relax all-family old-route release assertions and remove disconnect-only release oracles |
| Evaluator P6 flags the explicit “record before route/enqueue decisions” clause | The prompt prescribes internal sequencing rather than a behavioral result | Nonblocking updates must be retained while offline/full; accepted blocked sends must not escape to the old route | Rewrite as outcome-only language |
| The blocking-offline test fails 6/7 runs and is not necessary to distinguish the two producer contracts | `send_hid_report` is treated as an offline state setter even without an active receiver | Offline retention is required from `try_send_hid_report`; blocking-send coverage starts from a full active route | Remove the blocking-offline behavioral test |
| State replacement, dropped-neutral, latest-steno, and full-queue retention pass broadly | Those are attainable, independent requirements | Keep them unchanged | Retain their black-box probes |
| BLE Plover and feature-lane surfaces are independent of release ownership | Removing them would erase the feature request's host-visible value | Keep exact descriptor/reference/eight-byte notification and steno/no-steno builds | Retain those probes, changing only their old-route release expectation |

This is a substantive public-contract reduction, not an implementation hint.
Prompt and verifier bytes will change, invalidating every version-29 audit and
calibration result. Version-30 calibration therefore restarts at 0/10 after
verification, exact false-positive, gap, and fairness analyses are recorded.

The first pristine replay found that the relaxed capacity-three USB probe now
passed without any solution: RMK already clears that queue and emits the
keyboard all-up required by version 30. It therefore no longer discriminated
new behavior and was removed. Capacity-three disposal remains tested on the BLE
old-route path, where pristine fails and the feature implementation is needed.
This reduces the focused suite to eleven tests and avoids preserving a
false-positive testcase merely for directional symmetry.

Replay of all seven version-29 solutions against that first eased draft still
produced 0/7 complete passes. Every solution failed the combined USB no-host
probe, the integrated BLE no-host phase, and the USB-destination no-steno probe.
The first two failures were specifically pre-disconnect held-state carryover;
the third showed that even a keyboard-only old-host release still retained the
same retiring-writer ownership bottleneck. Six ordinary state-update probes
continued to pass every replay, while the seven solutions scored only 6--8 of
11 overall.

The final version-30 boundary therefore removes old-host release delivery
entirely and distinguishes offline updates from pre-disconnect held state. A
direct handoff must discard stale old-route traffic and replay current state on
the new host, but need not write a release to the old host. Disconnect may clear
the held snapshot; subsequent `try_send_hid_report` updates made with no active
route must still become the next host's state. The verifier will remove the two
pre-disconnect carryover phases and observe the old route only to reject stale
non-neutral packets. This keeps the feature centered on portable state routing
without requiring cross-lifetime delivery through a writer that is going away.

A second replay stopped after the first two runs because both had only one
remaining semantic failure: the integrated BLE test repeated the already
covered offline all-family cache case with BLE as the destination. The cache is
transport-independent, while BLE destination replay is independently exercised
by direct handoff and Plover notification checks. That phase was removed as a
symmetry duplicate; offline press/release, neutral replacement, and changed
steno state remain covered at the USB destination. The capacity-one and
capacity-three BLE tests now focus on their distinct BLE host and stale-queue
boundaries instead of rerunning the entire scenario script.

The first replay after that removal exposed one harness-order artifact rather
than another product gap: activation of BLE legitimately emitted a state replay
immediately before the test's later live-notification sequence, so the test saw
report `0x50` where it assumed report `1` would be next. Version 30 does not
specify inter-family scheduling. The host probe now lets activation replay
settle and clears those already-observed packets before checking the subsequent
live reports, preserving payload/reference validation without imposing an
ordering oracle across separate phases.

One replay packet could still be pending inside an alternative writer even
after the controller queue was drained; its next wake produced report `4`
before the newly submitted keyboard report. The live-notification check was
therefore made fully order-independent: after each submission it waits for that
report ID with the exact expected payload, ignoring unrelated replay packets.
The enclosing watchdog still detects missing delivery. This is the host-visible
eventual-delivery contract and does not weaken the Plover reference or
eight-byte payload assertions.

The final pristine run then found one focused test passing without the
solution: after old-host releases were removed from the contract,
`hid_handoff_usb_writer_blocks_old_host_escape_at_cutover` only observed
behavior RMK already provides. It was removed rather than counted as new. The
opposite writer-destination blocked-send probe still fails pristine, and the
integrated BLE host probe independently covers USB-to-BLE blocked state replay,
so the public cutover boundary remains discriminated. The final focused count
is ten.

### Version 31 participant-visible lockfile fairness gate

Before revising the harness, I reread `PROBLEM_DESIGN.md` and
`CALIBRATION_STRATEGY.md`; searched `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, and this problem's
compact history for RMK, HID handoff, offline Cargo resolution, lockfiles, and
feature-lane failures; and inspected the raw `agent-runs8` trajectories and
logs. The seven same-task runs remain the relevant evidence set. Their
behavioral result is summarized by the version-30 gate above. For this packaging
revision, the representative near attempts and both Vega attempts repeatedly
ran the public `--locked --offline` command from `/app`, demonstrating that the
ordinary package lock is a useful participant debugging surface. The broad
failures also compiled against that graph; none required or inspected the
randomized `.rmk-a01fa986/Cargo.lock` carried only by `test.patch`.

The fairness report identified a genuine environment asymmetry. Although the
Dockerfile leaves `rmk/Cargo.lock` in `/app/rmk`, the hidden wrapper ignores that
participant-visible file, prefers `/opt/rmk-handoff/rmk.Cargo.lock`, and falls
back to a second copy introduced only by `test.patch`. Thus the submitted tests
can be read as requiring a hidden dependency graph even though the intended
image exposes an equivalent graph to the solver. The behavioral feature/config
lanes are fair; the hidden lock substitution is not needed to test them.

| Evidence | Plausible false result | Public invariant | Harness correction | Anti-overfit rationale |
|---|---|---|---|---|
| The prompt requires a locked/offline command, but the wrapper substitutes an `/opt` or hidden-patch lock after copying the source | A participant validates against the visible package lock while grading silently compiles a different hidden graph | Participant and evaluator must use the same inspectable dependency graph | Remove `.rmk-a01fa986/Cargo.lock` from `test.patch`; require and retain the ordinary `rmk/Cargo.lock` already present in the copied participant source | This changes only dependency provenance, not HID behavior or a candidate implementation shape |
| The Dockerfile already builds the exact dual+steno graph and leaves its generated lock at `/app/rmk/Cargo.lock` | A hidden fallback masks a broken or missing participant setup | A missing visible lock is a harness startup error, not an invitation to inject hidden state | Make `test.sh` fail clearly if the copied source lacks readable `rmk/Cargo.lock`; do not copy any alternate lock into place | Ensures the documented command is exactly the graded command and remains reproducible offline |

No hidden behavioral discriminator changes in version 31. The prompt will say
that the image provides the visible package lock, the Dockerfile will make its
readability explicit, and all focused lanes will continue to use `--locked
--offline` against that file. Because `meta.md`, `test.patch`, and `Dockerfile`
change, the immutable artifact version changes, all exact review gates must be
rerun, and official calibration restarts at 0/10. No cold solver is requested
or run.

#### Version 31 exact closure

The lockfile diff and fallback code were removed from `test.patch`. The wrapper
now retains `rmk/Cargo.lock` from the copied participant source; the Dockerfile
leaves that file world-readable and no longer stores an evaluator-only RMK
copy. The prompt explicitly says that participant and evaluator use the same
visible file.

With visible lock SHA-256
`1e5cc2ae6aba17ce1d7f4fd9be40166f0756a3cd24098bdc0ba6e3c0a7298b1e`,
the exact test-only/reference runs score 0/10 and 10/10 focused, respectively,
and both pass 541/541 baseline tests with two skips. Both patch orders produce
combined diff `c79cbe95046c8da4dfa834e9ef0dcca19250342aeff627fac6977276bb1335be`
and Git tree `99d53c6de62fccf7b6c4d12ab869cfbe4318703b`. An intentionally absent visible
lock exits 101 and produces four JUnit startup errors.

The exact mutation audit kills offline-state omission, one-entry-only stale
draining, and a wrong Plover report reference. Exact stored-solution replays
preserve one legitimate 10/10 plus 541/541 implementation and one independent
9/10 no-steno BLE failure. Gap and fairness analyses pass. Docker Desktop did
not answer the fresh engine probe, so image/arbitrary-UID verification remains
unclaimed and the problem is not declared submission-ready. No cold solver was
run.

### Version 32 trajectory-informed coverage gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched the local RMK
problem/candidate history for route-readiness transitions, offline replay
destinations, and lockfile setup; and inspected the compact results plus raw
patches for all five `agent-runs9` attempts. Three attempts pass all ten focused
tests but alter legacy state tests, one fails nine focused tests after replacing
the public channel surface, and one fails five focused tests because neutral
replay occupies the live queue. The representative focused pass
`Nova_Nova_2` routes all setters through a common active-transport comparison;
the representative broad failure `Nova_Nova_3` also observes active-route
changes centrally but mishandles queue ownership. These are useful architecture
controls, not private shapes for the verifier.

The review found two independent observable boundaries absent from version 31.
All direct replacement phases currently call `set_preferred_connection`, so a
plausible change can reconcile preference changes while leaving the existing
`set_usb_state` and `set_ble_state` readiness paths with stale routing. Also,
offline state is replayed only to USB, even though USB and BLE have separate
host writers and activation paths. The public contract says USB/BLE changes and
the next active host, so both omissions are participant-facing behavior rather
than symmetry for its own sake.

#### Version 32 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect behavior | Public invariant | Strongest black-box oracle | Decision |
|---|---|---|---|---|
| `ConnectionStatus` chooses the active route from preference plus USB/BLE readiness, but every direct verifier phase flips preference | Reconciliation is invoked only by `set_preferred_connection`; unplugging the preferred ready route or losing BLE readiness leaves the other available host stale | Any actual active-output change must use the same discard/replay behavior | With both routes available, make USB loss select BLE and BLE loss select USB; observe exact replay at the newly active real host in each direction | Add one status-triggered phase to each existing host integration, without adding test names |
| USB and BLE writers have distinct output code; version 31 retains offline state only with USB as the next host | Offline state is cached but BLE connection activation does not drain/replay it | Offline updates belong to whichever host becomes active next | Produce all enabled absolute families with no route, activate BLE first, and observe exact BLE reports with mouse impulses zeroed | Add one phase to the existing BLE host integration |
| Three run-9 solutions already pass preference-driven handoffs and the suite already covers capacities one/three, steno/no-steno, neutral replacement, and blocked sends | More permutations would duplicate established failure modes | Each probe should isolate a new implementation mode | Keep test count and all other scenarios unchanged | Reject additional Cartesian cases |

The setup paragraph will also be rewritten as ordinary repository guidance,
without image/evaluator framing. Prompt and verifier bytes change, so version
32 is a new immutable artifact version: calibration resets to 0/10, and exact
false-positive, gap, fairness, reference, pristine, and stored-solution checks
must be repeated before any readiness claim. No cold solver is requested.

#### Version 32 exact closure

Version 32 is bound to prompt SHA-256
`d18b34d8c1c18cb4063138abfc6d2cbca81d304947466ce42b390ce3850a778d`,
test SHA-256
`e6e894c169d5e343c39ac9a39c44fbbd0c85da574081fc2964a17896683c5b1f`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders apply cleanly and produce combined diff
`e0a3c251d3951dfeb5fdc2f06b8fbaa71e8272dc8f9a09880afaaa83dab4fa48`
and Git tree `078ce1fd170653c90280c26ed4a2c59abe8bd08c`.

The existing integrated BLE probe now starts with all five families produced
while no route is active and observes exact replay when BLE becomes the first
ready host. Its direct USB-to-BLE phase changes only `UsbState`, and the real
USB writer's reverse phase changes only `BleState`; preference-driven phases
remain elsewhere in the same suite. Neutral packets left from a prior phase
are accepted, but every non-neutral packet seen while awaiting the current
snapshot must equal that snapshot. The focused test count remains seven
capacity-one steno, one capacity-three steno, and two capacity-one no-steno.

Exact test-only/reference runs are 0/10 and 10/10 focused; both are 541/541
baseline. Ten consecutive reference repetitions pass all three lanes. Dual
steno and dual no-steno warning-denying Clippy checks pass. Five isolated
mutants are killed: preference-only direct reconciliation, omitted None-to-BLE
activation, omitted offline state capture, one-entry stale draining, and the
wrong Plover report reference. Stored replay results are: run-9 Nova 2/4/5 and
run-8 Nova 1 pass 10/10; run-9 Nova 3 remains a behavioral 5/10; run-9 Nova 1
still has verifier-facing compile/API failures. Isolated complete baselines for
run-9 Nova 2 and run-8 Nova 1 are both 541/541.

A missing visible lock exits 101 and records four JUnit startup errors. The
Docker client is present, but a bounded ten-second server probe times out with
no server version, so fresh image/non-root verification remains unclaimed.
Exact false-positive, gap, and fairness records pass. No cold solver was run,
and version-32 calibration is 0/10. After the final setup sentence was phrased
as ordinary repository guidance, the requirement map and fairness audit were
rechecked against the final prompt hash above; no behavior or oracle changed.

### Version 33 trajectory-informed neutral-state gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched the current RMK
problem history for BLE dropped-neutral coverage; and reinspected representative
raw run-9 implementations and evaluations. The passing implementations keep
keyboard, media, system, mouse, and steno state independently, while the broad
failure demonstrates that neutral replay behavior can differ by family and
route. The existing verifier helper rejects only the particular earlier held
values used by its fixture. A family-specific defect that replaces neutral with
a different nonzero value therefore remains both plausible and observably
wrong, without depending on any private implementation shape.

#### Version 33 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect behavior | Public invariant | Strongest black-box oracle | Decision |
|---|---|---|---|---|
| The BLE dropped-neutral phase observes independent HID report IDs, but `assert_not_stale_ble_state` compares each family with only one prior fixture value | A cache clears the exact previous value yet substitutes or retains another nonzero keyboard, media, system, or steno value | A neutral absolute update clears held state for that family | During the existing post-neutral BLE observation window, require every emitted payload for report IDs 1, 3, 4, and `0x50` to consist entirely of zero bytes; continue allowing the report to be absent | Strengthen the existing helper and its two call sites; add no test or ordering requirement |
| The same phase intentionally sends a held mouse marker to delimit completion | Applying the zero predicate to mouse would reject the intended current state | The oracle must distinguish the control marker from the families just neutralized | Exclude report ID 2 from this helper; its exact current value is asserted separately | Preserve the existing mouse assertion |
| Existing tests already exercise both BLE observation points around the marker and drain | A new fixture or packet-count requirement would duplicate coverage or prescribe scheduling | Absence is a valid neutral representation and replay order is unspecified | Validate only packets that are actually emitted, at both existing observation points | Reject new count, ordering, and timing assertions |

The public description and reference behavior are unchanged. Changing the
verifier creates immutable version 33, resets calibration to 0/10, and requires
fresh exact reference, pristine, mutation, stored-solution, gap, fairness,
stability, and harness checks. No cold solver run is requested.

#### Version 33 exact closure

Version 33 is bound to unchanged prompt SHA-256
`d18b34d8c1c18cb4063138abfc6d2cbca81d304947466ce42b390ce3850a778d`,
test SHA-256
`a4e12b5486ec1e325d8eb537b088b7225c9a0b24f629ae451cf5bfd041f923d4`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders apply cleanly and produce combined diff
`fa8c7bca757ecf2108387fcdeb804c5ff645b9fcc2b75640a117bc51ff8c9050`
and Git tree `1e59c1a47856e71398cb48ab87892523306fd57e`.

The helper now validates every emitted keyboard, media, system, and steno BLE
payload after the neutral updates as all-zero while accepting absence and any
ordering. Exact reference/test-only results are 10/10 and 0/10 focused, with
both baselines 541/541. Ten repetitions pass all lanes; dual steno/no-steno
warning-denying Clippy checks pass. The five earlier mutants remain killed. A
new BLE-only `0x00eb` media substitution passes all ten version-32 focused tests
and the 541-test baseline, then fails version 33, proving the reported semantic
gap is closed. Run-8 Nova 1 and run-9 Nova 2/4/5 pass 10/10; run-9 Nova 3 remains
5/10 overall and Nova 1 retains compile/API failures.

Missing-lock startup exits 101 with four JUnit errors. The Docker client is
present but its server again fails a bounded ten-second probe, so fresh image
and arbitrary-UID execution remain unclaimed. Exact false-positive, gap, and
fairness records pass. No cold solver was run, and calibration is 0/10.

### Version 34 trajectory-informed prompt-interface gate

This gate was completed before revising `meta.md`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched the RMK problem and
candidate histories for the feature-request classification and Plover HID
interface; and reinspected the raw run-9 legitimate, near-pass, and broad-fail
patches. The task is already indexed locally as a feature request and its title
already begins with “Add,” but the first sentence begins with “Route.” The raw
solutions consistently use report ID `0x50`, usage page `0xFF50`, usage
`0x4C56`, a logical collection, and a 64-bit input declaration. Those values are
also exact verifier assumptions, while version 33 exposes only a generic
“Plover-compatible” requirement.

#### Version 34 discriminator ledger

| Trajectory/repository evidence | Fairness/classification risk | Public invariant or assumption | Revision | Anti-overfitting decision |
|---|---|---|---|---|
| Local candidate history classifies the task as a feature request, but only the title starts with “Add” | An automated classifier can treat the task as an enhancement despite its intended add-capability framing | The requested work adds transport-handoff and BLE steno capabilities | Begin the first body sentence with “Add” while retaining the existing `Title: Add ...` | Change framing only; add no behavior or test |
| The coherent-descriptor parser requires a specific report ID, usage page, usage, collection type, input flags, and bit width | A solver can implement a different otherwise plausible Plover encoding and encounter hidden interface requirements | Exact HID/GATT interoperability assumptions must be participant-visible | State report ID `0x50`; one coherent logical input collection; usage page `0xFF50`; usage `0x4C56`; a Data/Variable/Absolute Input item; and `report_size * report_count == 64` | Publish exactly the existing black-box assumptions, not byte order, source layout, macro syntax, or descriptor serialization |
| Successful and failing run-9 patches use different state/channel architectures but converge on the same Plover interface | Publishing the interface does not reveal the handoff implementation | Host-observable HID structure is an interface contract | Keep all handoff, queue, scheduling, and state language unchanged | Preserve all legitimate implementation architectures and the existing test suite |

No hidden test or reference behavior changes. The prompt edit creates immutable
version 34, resets calibration to 0/10, and requires exact false-positive, gap,
fairness, reference, pristine, patch-order, and harness checks. No cold solver
run is requested.

#### Version 34 exact closure

Version 34 is bound to prompt SHA-256
`be2542cc4d58309ed4792139df0a7de34b6092c46525f8911bfba4c3eef5a1de`,
unchanged test SHA-256
`a4e12b5486ec1e325d8eb537b088b7225c9a0b24f629ae451cf5bfd041f923d4`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders again produce combined diff
`fa8c7bca757ecf2108387fcdeb804c5ff645b9fcc2b75640a117bc51ff8c9050`
and Git tree `1e59c1a47856e71398cb48ab87892523306fd57e`.

The reference is 10/10 focused and 541/541 baseline; pristine is 0/10 and
541/541. All six exact mutants are killed. Representative legitimate run-8
Nova 1 and run-9 Nova 2 remain 10/10, while failing run-9 Nova 3 remains 5/10
overall. Ten repetitions of all three lanes pass; dual steno/no-steno
warning-denying Clippy, formatting, shell syntax, patch-order, and missing-lock
startup checks pass. Gap analysis confirms every parsed Plover property is now
public, and fairness confirms the parser still permits arbitrary descriptor
serialization and internal architecture.

The Docker client remains available but the server again returns no version in
a bounded probe, so fresh image and arbitrary-UID execution remain unclaimed.
No cold solver was run, and version-34 calibration is 0/10.

### Version 35 trajectory-informed lock-independence gate

This gate was completed before revising `meta.md` or `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched the RMK problem,
candidate, error, and raw run-9 histories for Cargo lock and offline behavior;
and reviewed the previous lock strategies. Earlier versions committed package
locks in the hidden patch, randomized a lock's parent path, substituted an
`/opt` copy, or relied on a Docker-created ordinary lock. Version 34 instead
promises that `rmk/Cargo.lock` is in the repository and makes every hidden lane
require it with `--locked`, but the pinned participant repository does not
contain that file. The behavioral trajectories are useful for the HID
discriminators; none makes a hidden lock prerequisite necessary.

#### Version 35 discriminator ledger

| Repository/trajectory evidence | Fairness failure | Public invariant | Revision | Anti-overfitting decision |
|---|---|---|---|---|
| The pinned repository has no tracked `rmk/Cargo.lock`, while the prompt says it does and `test.sh` exits through Cargo's `--locked` failure | A correct HID implementation can be untestable because of grader-only dependency state | Validation prerequisites must exist in the participant-visible repository or not be required | Remove the lockfile claim, readability check, and every harness/public `--locked`; retain `--offline` | Do not add or inject any lockfile, randomized path, fallback copy, or candidate-visible implementation aid |
| Cargo can resolve and create a package lock from its cached index in offline mode; Docker may still prewarm/cache dependencies | An unlocked online build would be machine-dependent | Runtime validation must remain network-independent | Exercise the exact reference and pristine matrices from checkouts with `rmk/Cargo.lock` absent and `CARGO_NET_OFFLINE=true` | Preserve offline isolation while removing only the nonexistent-file prerequisite |
| The wrapper already synthesizes JUnit errors when Cargo exits before producing results | Removing the explicit lock check could hide a genuine resolver startup failure | Harness startup failures remain authoritative failures | Keep `capture_junit` unchanged for preflight and all focused lanes | No product behavior, test count, or HID oracle changes |

The Dockerfile may continue placing a convenience lock in the built development
environment, but neither the task nor wrapper depends on it. Version 35 changes
the prompt and test harness only, resets calibration to 0/10, and requires exact
lock-absent reference/pristine, false-positive, gap, fairness, mutation,
stored-solution, patch-order, stability, and startup checks. No cold solver run
is requested.

#### Version 35 exact closure

Version 35 is bound to prompt SHA-256
`9a1617040c2d842a92c738932fa887076bc8b465183e2042fe018e8c9cfb6355`,
test SHA-256
`0e486bf448ef0d3f7a83b31ddcda9d7d5e57aa1be4d7d3e0ccea0e8cd61ead8f`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders apply without a package lock and produce combined diff
`9586a7e2bf185bd91485b2a52e72d38546dee87f672cb0b134e2e13eb4378214`
and Git tree `12da1aed6833d383ee989d1706aca88a97fb09f5`.

Fresh pinned reference and pristine source trees were confirmed to lack
`rmk/Cargo.lock`. With the normal prepared Cargo cache, `--offline` resolution
inside each disposable wrapper copy completes: reference is 10/10 focused and
541/541 baseline, while pristine is 0/10 and 541/541. An intentionally empty
Cargo home instead produces four explicit JUnit startup errors. No hidden or
randomized lock is added by the tests.

All six exact mutants remain killed without `--locked`. Representative
legitimate run-8 Nova 1 and run-9 Nova 2 remain 10/10, while failing run-9 Nova
3 remains 5/10 overall. Ten repetitions of all three focused lanes pass; dual
steno/no-steno warning-denying Clippy, formatting, shell syntax, and patch-order
checks pass. Exact false-positive, gap, and fairness records pass.

The Docker server again yields no server version in a bounded probe, so fresh
image and arbitrary-UID execution remain unclaimed. No cold solver was run, and
version-35 calibration is 0/10.

### Version 36 trajectory-informed regression-contract gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched this problem's local
history for the version-30 release-boundary decision; inspected the pinned
repository's three legacy release assertions; and reviewed every raw run-10
patch, evaluator report, and representative trajectory. The representative
broad failure is run-10 Nova 1 (0/10 focused plus API/descriptor failures), the
near pass is Nova 2 (the no-steno lane passes but the steno lanes fail because
its channel wrapper drops `sender()`/`receiver()`), and the two behaviorally
complete attempts are Nova 3 and Nova 5 (10/10 focused each). All five attempts
independently revise the same legacy release assertions after following the
public statement that no old-host release packet is required.

The run-10 wrapper classified Nova 3 and Nova 5 as cheating because two renamed
legacy test IDs were missing. That classification is not a sound product
discriminator. The public contract deliberately removed old-host release
delivery in version 30, but the base lane still selects three older tests that
require exactly that removed behavior:

- `flipping_away_from_active_clears_stale_reports_and_queues_all_up`;
- `blocked_send_drops_report_after_transport_change`; and
- `usb_preference_flip_releases_previous_ble_transport`.

The third keeps its old name in the successful patches while its assertion is
updated, so the wrapper's expected-ID comparison detects only two of the three
contract conflicts. Preserving those tests rewards participant test edits and
rejects implementation-only solutions that obey the prompt. They are therefore
obsolete regression cases for this problem version, not safeguards against a
legitimate shortcut.

#### Version 36 discriminator ledger

| Trajectory/repository evidence | Failure mode | Public invariant | Revision | Anti-overfitting decision |
|---|---|---|---|---|
| All five run-10 patches remove the same all-up assumptions; Nova 3 and Nova 5 otherwise pass all ten host-visible tests | Contract-compliant solutions are labeled as test manipulation | A direct handoff discards stale old-route traffic and need not send an old-host release | Exclude the three obsolete release-specific legacy cases from the base lane | Match stable semantic test-name prefixes, not any solver-specific replacement name or implementation file |
| The current base lane selects every non-`hid_handoff_` test, including assertions intentionally superseded by version 30 | The regression oracle contradicts the participant-facing task | Remaining pre-existing behavior must continue to pass | Keep all other 538 baseline cases authoritative | Do not weaken focused USB/BLE writer, stale-queue, blocked-send, state-family, capacity, or Plover assertions |
| Nova 1, Nova 2, and Nova 4 fail independent API, descriptor, or writer-integration boundaries | Broadly excluding state tests could turn incomplete attempts into passes | Existing public channel compatibility and host-visible behavior remain required | Exclude only the three named legacy semantics and replay all five run-10 patches | Preserve missing-test detection for every other baseline node and all ten focused nodes |

This verifier-only reconciliation creates immutable version 36, resets
calibration to 0/10, and requires exact reference, pristine, all-six-mutant,
run-10 replay, false-positive, gap, fairness, patch-order, stability, Clippy,
and startup checks. Stored run-10 replays are trajectory evidence rather than a
new calibration batch. No cold solver run is requested.

#### Version 36 exact closure

Version 36 is bound to unchanged prompt SHA-256
`9a1617040c2d842a92c738932fa887076bc8b465183e2042fe018e8c9cfb6355`,
test SHA-256
`9e99b88366cd21f3ac94242985ee1c206c27d491ca835085ae0a920e3aedcd20`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders produce combined diff
`6603f0590e7ec5f186d7fdceb901c31ea6db536deb597a9588dcf099c357ac75`
and Git tree `447d6f6cf62a62a0b20930d2131193202480ab4e`.

The reference passes 538/538 authoritative baseline and 10/10 focused;
pristine passes 538/538 baseline and fails 0/10 focused. Ten consecutive
repetitions pass the seven-test capacity-one steno, one-test capacity-three
steno, and two-test no-steno lanes. Warning-denying steno/no-steno Clippy,
formatting, shell syntax, patch checks, and both patch orders pass. An empty
offline Cargo home exits 101 and records four lane-specific JUnit errors.

All six exact mutants are killed by distinct public probes. Run-10 Nova 3 and
Nova 5 pass the revised baseline plus all focused tests. Nova 1 retains a base
descriptor panic and focused writer failures; Nova 2 and Nova 4 retain their
steno-lane channel API compile failures. The successful solutions are therefore
legitimate under the public no-release contract, while incomplete solutions do
not benefit from the regression exclusion. Exact false-positive, gap, and
fairness records pass. Docker remains the only unclaimed environment replay.
No cold solver was run, and calibration is 0/10.

### Version 37 trajectory-informed stale-observation and evaluator-contract gate

This gate was completed before revising `meta.md` or `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched the full local RMK
problem history for stale-output timing, old-host release expectations, and
test-edit classifications; and inspected every run-11 evaluation and patch.
Representative raw trajectories were reviewed for Nova 2 (legitimate complete),
Nova 5 (near-complete no-steno descriptor regression), Nova 1 (broader handoff
failure), and Nova 4 (behaviorally complete but classified as cheating).

Run 11 contains two unambiguous legitimate solves, Nova 2 and Nova 3, each at
538/538 baseline and 10/10 focused. Nova 4 also passes both suites and makes the
same prompt-aligned removal of obsolete old-host release assertions accepted in
Nova 3, but its evaluator calls that test manipulation. Nova 1 and Nova 5 fail
independent BLE host-output or feature-gating boundaries. The resulting
behavioral solve rate is therefore 2/5 under the recorded labels, or 3/5 if the
inconsistent Nova-4 label is normalized; neither result indicates a bottleneck.
The real verifier weakness is separate: several old-route absence checks use 32
cooperative yields and inspect only packets immediately available afterward.

#### Version 37 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect behavior or ambiguity | Public invariant | Strongest black-box oracle/revision | Decision |
|---|---|---|---|---|
| The real USB/BLE writers serialize host-visible reports, but several verifier phases stop after 32 scheduler yields | A stale report can be retained behind other work and emitted after the sampling loop | Old-route stale traffic must not reach the previous host after cutover | Observe packets until a later, required host-visible marker/snapshot has traversed the same writer; validate every packet encountered instead of draining only what happens to be ready after a yield count | Replace bounded yield-and-drain sampling with progress-delimited observation; retain the 30-second harness watchdog only for deadlock reporting, not as product latency semantics |
| Existing snapshot collectors store one payload per family and can overwrite an earlier stale packet with a later correct packet | A writer emits stale state and then correct replay for the same family | Every emitted packet before reconciliation progress matters | Reject non-neutral, non-current payloads as they arrive while collecting the complete current snapshot | Strengthen collectors without imposing report-family order or requiring neutral reports |
| Nova 3 and Nova 4 both revise the superseded release tests, but receive different manipulation labels | A contract-compliant implementation is judged by evaluator interpretation rather than behavior | Direct handoff requires stale disposal and replay; an old-host release is expressly unnecessary | State naturally that the three legacy old-host-release assertions describe superseded behavior and may be updated as part of the change | Clarify authorized regression maintenance; do not expose focused test names, private queues, or a required architecture |
| Nova 2 passes without modifying tests, while Nova 1/5 fail independent host-visible requirements | Broadly weakening the suite to avoid an evaluator label would admit incomplete implementations | Channel API compatibility, feature gating, all-family replay, blocked sends, queue capacities, and coherent Plover BLE output remain required | Keep all 538 authoritative baseline cases and all ten focused behavioral cases; change only the stale observation boundary and public legacy-contract guidance | No easing of product behavior and no cold solver run |

The stale progress marker is a test synchronization device, not a new latency,
packet-order, or internal-queue contract. The prompt clarification changes no
required behavior. These artifact changes create immutable version 37, reset
calibration to 0/10, and require exact reference, pristine, mutation, stored
solution, false-positive, gap, fairness, patch-order, stability, Clippy, and
harness checks. No cold solver run is requested.

#### Version 37 exact closure

Version 37 is bound to prompt SHA-256
`53e3b4dc35ee5d22f8f90c6a47db76eef112421860e5e5af717df4c87571567b`,
test SHA-256
`a1a93a40bf5228040f87659a26256d537ce856948509371c5754c4741e5f3809`,
unchanged reference SHA-256
`eb9142f81f1a9948d43e6ced60794cca213cc6f6bb1fe980d90126fe3f6ec82f`,
and unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.
Both patch orders produce combined diff
`4cd7a153709ccfc013fc7195e5fad031788f61d67d2478724f4fc9591974c32a`
and Git tree `d51ef38fffbff1091df0000dac16be4693359263`.

Reference passes 538/538 authoritative baseline and 10/10 focused; pristine
passes 538/538 baseline and fails all 10 focused tests. Ten consecutive runs
pass each of the three focused lanes. Formatting, shell syntax, warning-denying
steno/no-steno Clippy, patch checks, both patch orders, and the four-error
startup-JUnit fallback pass.

All six prior mutation modes remain killed. During the new audit, the
one-entry-clear mutant exposed and caused removal of a test-side BLE clear. A
new 64-poll delayed-stale mutant passes all version-36 focused lanes and its
538/538 baseline but fails the version-37 writer-progress probe. No actionable
mutant survives the final suite.

Run-11 Nova 2 and Nova 3 remain legitimate passes. Nova 4 remains behaviorally
complete, including the strengthened capacity-three test; its manipulation
label conflicts with Nova 3's accepted equivalent legacy-test maintenance and
is addressed by the public prompt clarification. Nova 1 and Nova 5 remain
independent failures. Exact false-positive, gap, and fairness records pass.
Docker remains the only unclaimed environment replay. No cold solver was run,
and calibration is 0/10.

### Version 38 trajectory-informed old-route, CCCD, and regression-ownership gate

This gate was completed before revising either patch. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, searched the complete local
RMK history for blocked sends, BLE CCCD persistence, old-route writer
observation, and legacy release assertions, and re-inspected the run-11
legitimate pass, near failure, broad failure, and manipulation-labelled pass.
Nova 2 and Nova 3 are complete independent implementations; Nova 5 is the
near-pass with a no-steno integration failure; Nova 1 is the broad BLE failure;
and Nova 4 is behaviorally complete but was labelled manipulation after editing
legacy tests that still encode the retired release protocol.

Repository inspection confirms two distinct omissions. The BLE-to-USB blocked
send probe observes only the new USB snapshot and never lets the old BLE writer
consume after cutover, so duplicate old-route delivery is invisible. Separately,
the reference adds a steno GATT characteristic but omits its CCCD handle from
the same update bookkeeping used by keyboard, mouse, media, system, and battery.
The latter is an implementation defect, not a new discriminator invented from
one solver.

#### Version 38 discriminator ledger

| Evidence | Plausible failure | Public/repository invariant | Black-box revision | Anti-overfitting decision |
|---|---|---|---|---|
| A blocked BLE send is replayed to USB, but the old writer is never run after its queue is freed | the pending send completes on both transports | the public prompt expressly forbids a blocked send from leaking onto the old route | run both real writers, cut over while pending, then free/observe BLE and require the report only in USB's absolute snapshot | check host output, not channel/cache ownership or implementation sequencing |
| Every existing HID CCCD is included in `gatt_events_task` bookkeeping except the new steno characteristic | steno subscription updates are not persisted or treated as activity | new Plover BLE input should integrate with the existing HID-over-GATT lifecycle | repair the reference condition and document the sibling integration step | do not turn the repository integration repair into an additional unstated hidden persistence requirement |
| The base lane excludes three stale legacy assertions, and Nova 4 was labelled cheating for modifying them | correct solutions are encouraged or forced to own verifier maintenance | verifier-owned obsolete expectations should be updated once, then run for every solver | revise those assertions in `test.patch`, restore them to the baseline inventory, and remove the prompt instruction to edit tests | keep solver patches implementation-focused and avoid exposing hidden test ownership in the task prose |

These changes create a new immutable version and reset calibration to 0/10.
They require exact reference/pristine matrices, isolated mutations for both new
boundaries, stored-solution replay, false-positive, gap, fairness, formatting,
Clippy, patch-order, startup-JUnit, and stability checks. No cold solver run is
requested.

#### Version 38 exact closure

Version 38 is bound to prompt SHA-256
`9a1617040c2d842a92c738932fa887076bc8b465183e2042fe018e8c9cfb6355`,
test SHA-256
`7eb2d4febeed82b574eeb4bed63528133e151983884ae24f7b9398912983b53b`,
reference SHA-256
`a795f6e646a27b3956a6b01cad9d5a65b0a1ea99b92d28e28a3bbfbb6def2bf9`,
unchanged Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`,
and solution-approach SHA-256
`feb59c185300746fa531e96a651467f454d06aeb39187811167c44c5c69a9f0d`.
Both patch orders produce combined diff
`fd301a7f2c9d9730775d5a91e6dc74baf03d6f6893d53ac8c0a53ed078fd1b8d`
and Git tree `86b653b8990ea382d6bef0b3127cc7b1d6309417`.

Reference passes 541/541 baseline and 10/10 focused; pristine passes 541/541
baseline and fails all ten focused tests. Run-11 Nova 2 merges cleanly and also
passes 541/541 plus 10/10, including the strengthened blocked-send probe. Each
of the seven retained mutants is recreated against the exact version and fails
its distinct strongest test. The new captured-old-route mutant fails both the
direct BLE-route assertion and the real BLE-host marker while preserving the
new USB snapshot.

Ten repetitions pass each focused lane. Formatting, shell syntax,
warning-denying steno/no-steno Clippy, both patch orders, diff checks, and the
four-error empty-cache JUnit fallback pass. Exact false-positive, gap, and
fairness reviews pass. The Docker daemon remains unavailable, so fresh
container execution is not claimed. No cold solver was run, and calibration is
0/10.
### Version 39 trajectory-informed evaluator-injection gate

This gate was completed before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; inspected all five run-12
evaluation reports, wrapper logs, solution patches, and representative raw
trajectories; and compared their touched production files with the version-38
test patch. There is no legitimate pass, near pass, or behavioral broad failure
to classify in this batch because the evaluator did not execute either suite
for any run. All five runs are environment/injection errors and are excluded
from calibration results.

The common failure occurs before product behavior is observed. Every run-12
solution necessarily edits `rmk/src/ble/mod.rs`, `rmk/src/state.rs`, and
`rmk/src/usb/mod.rs`; version-38 `test.patch` edits the same files to register
hidden unit tests and revise verifier-owned legacy assertions. The platform's
three-way test-patch application fails on all five independent patches, then
resets the overlapping files to baseline. That reset combines each solver's
remaining files with baseline counterparts and causes unresolved-symbol compile
errors. The resulting 0/541 and 0/10 reports are synthetic missing-test
failures, not evidence about HID handoff correctness.

Representative raw trajectories confirm that the overlap is intrinsic rather
than solver-specific. Nova 1 builds a dedicated replay path and updates the BLE
and USB writers; Nova 2 uses an active-route generation contract; Nova 3 changes
the package surface as well as the same routing modules; Nova 4 uses another
all-family state/reconciliation implementation; and Nova 5 also extends test
support. Each agent reports successful local compilation before the evaluator
destroys the coherent tree. The shared edited modules are the public task's
natural implementation boundary.

#### Version 39 discriminator and environment ledger

| Evidence | Failure mode | Required invariant | Revision/gate | Anti-overfitting decision |
|---|---|---|---|---|
| Five of five run-12 patches collide with hidden edits to the same three production modules | evaluator resets solver-owned files after a hidden-patch merge failure and grades an impossible hybrid | hidden verifier injection must not depend on merging hunks into files participants are expected to change | move hidden source additions to new randomized files and make `test.sh` register them only inside its temporary test copy | runtime registration may use stable module-file boundaries, but no participant implementation hunk or private architecture is required |
| Reference and one stored solution merged in version 38, while five new independent solutions did not | pairwise reference patch-order checks create false confidence about platform applicability | environment validation must exercise representative solver-shaped overlap, not only the author-matched reference | add an exact pre-calibration injection gate that applies the verifier after every available representative solver patch and rejects merge/reset/startup errors before audits or paid runs | a stored solver need not pass behavior; the gate only requires a coherent, executable evaluator tree |
| Wrapper logs explicitly say `3-way test.patch merge failed` before every synthetic JUnit failure | harness startup failure is miscounted as product failure | no calibration run may count unless patch injection succeeds and real baseline/new test processes start | classify patch-application, dependency, permission, toolchain, and missing-JUnit failures as environment blockers; stop the batch immediately | environment viability is separate from false-positive, gap, fairness, difficulty, and solvability analysis |
| Existing local checks covered reference/pristine matrices, two patch orders, empty Cargo cache, and JUnit fallback but not post-solver hidden-patch injection | extensive downstream checks can all pass while the actual evaluator composition path is broken | the first pipeline gate must reproduce the evaluator's real order and identity/offline constraints | introduce a mandatory global environment gate before mutation/fairness/gap work or solver calibration | later checks cannot waive or substitute for this gate |

Version 39 therefore changes verifier delivery and the global workflow, not the
public HID contract. Calibration restarts at 0/10. The five run-12 records are
retained only as trajectory and environment evidence and must never be counted
as failed solves.

#### Version 39 exact closure

Version 39 is bound to prompt SHA-256
`9a1617040c2d842a92c738932fa887076bc8b465183e2042fe018e8c9cfb6355`,
test SHA-256
`8b0d7ce3e1075c721171323357d1fda31a0459621ad72a6e3340a604efbeba96`,
reference SHA-256
`a795f6e646a27b3956a6b01cad9d5a65b0a1ea99b92d28e28a3bbfbb6def2bf9`,
Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`,
and solution-approach SHA-256
`feb59c185300746fa531e96a651467f454d06aeb39187811167c44c5c69a9f0d`.
Both patch orders produce combined diff
`5bb0ff914be417790d91fede3fb5253d6ff22d5cf3d9d055a5ec865a2f5046ab`
and Git tree `dbd224b7c61b3d9bb66594e9c5390fd34e191abe`.

The mandatory global environment gate builds the untouched checkout into
Docker manifest
`sha256:2f5fa52cc947f40ca736f91a3ec3e9fba57cf732dbb3a130e304da4f4607a679`
and executes offline as UID/GID `10001:10001`. Pristine passes 538/538 baseline
and fails all ten focused tests behaviorally; reference passes 538/538 plus
10/10. Run-12 Nova 1 and Nova 4 independently pass the same matrix. Nova 2,
Nova 3, and Nova 5 also accept verifier injection cleanly.

All eight exact behavioral mutants fail the focused suite. Both patch orders,
formatting, shell syntax, diff checks, empty-cache JUnit reporting, exact gap,
fairness, and false-positive gates pass. The hidden CCCD assertion was removed
because persistence bookkeeping is not public. No cold solver was run, and
version-39 calibration is 0/10.

### Version 40 trajectory-informed hardening proposal

This gate was recorded before any version-40 test or reference edit. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, verified the version-39
environment result, and inspected every run-13 evaluation, patch, test log, and
representative raw trajectory. All five runs reached real behavior: Nova 1,
Nova 2, and Nova 3 pass 538/538 baseline plus 10/10 focused; Nova 4 passes 8/10
and omits complete BLE steno integration; Nova 5 passes 7/10 and has broader BLE
writer failures. None is environment-blocked. The patches span six to eight
production files and 506–587 reported sandbox LOC, so implementation size is
healthy even though the observed 3/5 solve rate is above the desired margin.

The three successful implementations all retain absolute state before routing
and drain a replay path independently of ordinary queue capacity. They differ
at the blocked-send cutover boundary. Nova 1 assigns every active-route change
an epoch. Nova 2 and Nova 3 remember only the transport identity, so a send
blocked on BLE can leave BLE, return to BLE before its future resumes, and then
enqueue into the new BLE activation as though no handoff occurred. Nova 4 and
Nova 5 independently use route generations, confirming that generation-aware
solutions are natural rather than reference-specific.

Repository review also confirms the reported coverage omission: disconnected
state is exercised through `try_send_hid_report`, while every awaited
`send_hid_report` call is either made on an active route or first blocked on a
full active queue. The reference and all five run-13 patches already retain a
fresh awaited offline report, so this is a correctness gap but not a useful
difficulty lever by itself.

#### Version 40 discriminator ledger

| Evidence | Plausible incorrect behavior | Public invariant | Proposed black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Nova 2 and Nova 3 pass by comparing only `active_transport()` after backpressure; Nova 1, 4, and 5 independently version route activations | an accepted send blocked on route A survives A→B→A and emits on the later A activation | a send already blocked on a full active queue belongs to that activation and must not escape after any intervening handoff | deterministically block one mouse send, perform A→B→A without polling it, resume both the real writer and future, require current zero-relative replay, and reject the old live packet | this is the existing scoped blocked-send boundary under an ABA transition, not an arbitrary producer/setter race, timing requirement, or private generation API |
| External review found no fresh awaited send while both transports are inactive | `try_send_hid_report` is correct offline but `send_hid_report` returns before recording state | reports produced with no active connection must reach the next host | await one representative absolute report while disconnected, activate a host, and observe its real HID output | test the independent producer branch once; do not multiply the same branch across every family or destination |
| All successful patches preserve live mouse impulses but the suite emphasizes zero-relative replay | an implementation zeros relative fields before live delivery rather than only in retained state | existing live mouse behavior must remain unchanged while replay is absolute-only | retain as a false-positive audit candidate only if a plausible compiling mutant survives the existing baseline | do not add speculative breadth merely to increase test count |

The recommended hardening is therefore one route-activation ABA discriminator
plus the missing offline async-producer probe. It should not reintroduce the
earlier all-race scope, old-host release protocol, single-transport permutation
matrix, or private queue/state assertions. Any artifact implementation would
create version 40, invalidate all version-39 exact gates, and restart
calibration at 0/10.

#### Version 40 exact closure

The proposal was implemented without broadening the concurrency scope. The
public contract now says that both producer APIs retain absolute state while
offline and that a blocked live send belongs to one active-output activation.
The verifier adds exactly two black-box USB-writer probes: a fresh offline async
mouse send, and a USB→BLE→USB cycle that rejects re-entry of the earlier raw
mouse packet while accepting current zero-relative replay. The reference uses a
route generation, but no hidden assertion observes or requires that mechanism.

Version 40 is bound to prompt SHA-256
`4acedab39df6f1e8ebbf9d00715659d694312607ce98f11f1d55a67a966f7492`,
test SHA-256
`72fbf64194f0471f6cc8aa07ec10dbd6b6efee0bba1362fad8080e727b5ffca8`,
reference SHA-256
`3e95163813741211b836a5d19d12cb795cd2ebc8126fc02b76e7a7b70ee38f65`,
Dockerfile SHA-256
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`,
and solution-approach SHA-256
`2eb68b763993507ee4d7ba455b96eb410e49eb0a63b578a1090c7f29aef67926`.
Both patch orders produce combined binary diff
`001c822975123cfabb84b34db8c4451f8e149340a3d2e26660cf375e58ee80f0`
and Git tree `b5dd223d28b33abc9e7c1c6e40b6da7ea5a36642`.

The global environment gate rebuilt the untouched image and passed offline as
UID/GID `10001:10001` with manifest list
`sha256:d66b211035ce56237d840b4bd93a32a12ba80c840ea66cd891b79f285a7a0eea`.
Test-only passes 538/538 baseline and fails 12/12 focused behaviorally;
reference passes 538/538 plus 12/12. The gate also confirms verifier injection
for every run-13 patch and a complete pass for Nova 1. An earlier corrupt
temporary clone stopped at startup and contributed no downstream evidence.

Ten isolated mutants cover old-route leakage, preference-only reconciliation,
omitted `None`→BLE replay, disconnected nonblocking loss, wrong Plover ID,
non-neutral BLE replay, partial queue clearing, delayed stale output,
transport-identity-only blocked sends, and disconnected async loss. Every
mutant compiled and failed its strongest focused discriminator. No survivor
required complete-baseline escalation. Gap, fairness, false-positive,
patch-order, shell, formatting, and steno/no-steno warning-denying Clippy checks
pass. The two new discriminators also pass ten consecutive cached reference
runs, for 20/20 stable test executions.

Retrospective run-13 focused replay is Nova 1 12/12, Nova 2 11/12, Nova 3
11/12, Nova 4 10/12, and Nova 5 9/12. This is trajectory evidence only: version
40 is a new immutable candidate at calibration 0/10, and no cold solver was
run.

### Version 41 trajectory-informed correction gate

This gate was recorded before changing the version-40 verifier. I reread
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the current environment/gap/
fairness/false-positive records, and every run-14 evaluation, solution patch,
test log, final agent message, and representative raw trajectory. Run 14 has
one legitimate pass, two deterministic product failures, one broad integration
failure, and one verifier failure. The production patches span four to six core
files and 463–661 effective production lines.

Nova 3 is the representative legitimate pass: it preserves the visible channel
surface, uses route generations, retains every family, and implements the BLE
Plover path. Nova 2 is the near-pass: USB and no-steno handoff behavior work,
but both steno BLE host lanes time out. Nova 4 and Nova 5 demonstrate the
optional-feature and public-channel integration boundaries. Nova 1 is not a
behavioral failure. It reasonably wraps `ConnectionStatus` and its route
generation in a new internal `ConnectionState`, updates RMK's visible
`test_support::reset_connection_status` helper, and then fails compilation only
because both hidden USB probes write `ConnectionStatus` directly into the
private `CONNECTION_STATUS` static. That concrete-type dependency is neither
public nor necessary and must be removed.

#### Version 41 discriminator ledger

| Evidence | Plausible incorrect behavior | Public invariant | Black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Nova 1 changes the private connection-state representation while preserving the test-support reset seam | a correct implementation is rejected before behavior runs | no private state layout is prescribed | reset through the repository's existing test-support function, then observe host output | this removes a verifier constraint; it adds no product requirement |
| external gap review notes that the fresh offline awaited-send probe uses mouse only | the awaited producer records mouse offline but returns early for keyboard, media, system, or steno | both producer APIs retain the latest absolute state for every enabled family | submit all five families through fresh awaited calls while disconnected, activate USB, and require the exact real-writer snapshot | one combined family-dispatch probe covers the independent API branch; do not add per-family tests or another destination permutation |
| capacity three currently drives only an old BLE route; USB stale disposal is observed only at capacity one | USB cleanup removes one entry while BLE cleanup drains completely | stale traffic is discarded for either old route, independent of ordinary queue capacity | queue three distinct non-neutral USB packets, cut over, run the real USB writer through a post-cutover marker, and reject every earlier non-neutral packet | this crosses both a transport-specific branch and the multi-entry resource boundary; accept silence or neutral cleanup and impose no release order |
| review flags benchmark prose in `test.sh` | behavior is unchanged but the harness reads like evaluator scaffolding | harness comments should describe operations, not participants | rewrite only the comment around isolated module registration | hygiene-only; no executable change or discriminator |

Version 41 will therefore expand two existing public boundaries and replace the
private reset with a stable repository test seam. It will not add family-order
assertions, old-host release requirements, timing deadlines, private route
epochs, or arbitrary race permutations. Because prompt semantics do not change,
`meta.md` and the reference behavior should remain unchanged; `test.patch`
changes create a new immutable version and restart every exact gate at 0/10.

#### Version 41 closure

The final verifier is
`98f846852b01ef88e66c440ffd9676272b0b25f192f0c9067b0e627c338ca329`.
The initial capacity-three USB draft passed pristine because queue clearing was
already legacy behavior; it was rejected before freeze. The accepted test also
requires the preserved all-family snapshot after returning to USB, so it fails
pristine behaviorally while retaining a distinct per-packet stale-output
oracle. Probe sources were then mechanically rustfmt-formatted; all exact gates
were rerun after that hash change.

The clean environment gate builds the untouched repository image, runs offline
as UID/GID `10001:10001`, and ends `environment gate: PASS`. Test-only is
538/538 baseline and 0/13 focused with thirteen failures and no errors.
Reference and run-14 Nova 3 are 538/538 plus 13/13. Exact Nova 1 replay now
compiles and passes 13/13 using its different private state representation;
Nova 2 compiles and passes 10/13, failing only observable behavior. All five
run-14 patches compose without overlapping verifier-owned paths.

Twelve isolated plausible mutants cover captured-route leakage,
preference-only reconciliation, omitted `None`→BLE replay, dropped disconnected
nonblocking state, wrong Plover ID, non-neutral BLE replay, shared clear-one,
delayed stale output, transport-identity-only ABA handling, all-family async
offline loss, mouse-only async offline retention, and USB-specific clear-one.
Every mutant compiles and fails its strongest focused discriminator. A first
delayed-output attempt that emitted nothing past the marker was classified as
an invalid mutation rather than evidence; the corrected late-packet mutant is
rejected. No survivor required 538-test baseline escalation.

Both patch orders produce combined diff
`04021094054e78dc15397d999b4553bb3fb3e09dd320d98ea0a232c1366eda56`
and tree `8c6bc14c6fedf92944c13f47ab41b07284537f3f`. Shell syntax,
rustfmt, warning-denying steno/no-steno Clippy, gap, fairness, and
false-positive checks pass. Run 14 is quarantined as version-40 calibration
because of the former verifier mismatch. Version 41 starts at 0/10; no cold
solver was run.

### Version 42 trajectory-informed hardening gate

This gate was recorded before changing the version-41 verifier. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched this problem's
compact design history for disconnected producer paths and BLE-first replay;
and inspected every run-15 evaluation, test log, implementation patch, and the
available compact trajectory record. Run 15 reached real product behavior in
all five attempts: Nova 2--5 pass 538/538 baseline plus 13/13 focused tests,
while Nova 1 passes the full baseline and 9/13 focused tests before four
deterministic writer/replay failures. No attempt is environment-blocked. The
patches span six to eight production files and 419--606 added lines, so the
four-pass result reflects a remaining behavioral omission rather than trivial
or test-shaped solutions.

The successful implementations centralize latest-state retention, but the
repository and all reviewed patches still have two independent producer entry
points and transport-specific output paths. `send_hid_report` has an awaited
queue/backpressure path that returns specially when no route exists;
`try_send_hid_report` has separate no-route/full-queue behavior. USB replay is
consumed by the USB writer, while BLE replay crosses the GATT report-reference
and notification path. Earlier version-32 evidence established BLE-first
offline replay only through the nonblocking producer. Version 41 widened the
fresh awaited-send probe to every family but still activates USB. Those two
tests do not reject an implementation whose blocking producer's disconnected
snapshot is visible only to the USB replay path.

#### Version 42 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect behavior | Public invariant | Strongest black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| The awaited and nonblocking producers have separate bodies, and USB/BLE have separate real writers; version 41 crosses awaited production only with USB activation | fresh disconnected `send_hid_report` updates populate USB replay but are absent when BLE is the first host | either producer API must retain the latest absolute state for whichever transport becomes active next | while both routes are inactive, await one update for each enabled family, activate BLE first, and require the exact host-visible GATT snapshot with mouse impulses zeroed | add one phase to the existing integrated BLE test; keep arbitrary family order and do not add per-family or producer/destination matrix tests |
| Four run-15 patches already pass every current focused test and independently implement a common retained snapshot, while Nova 1 fails route/writer ownership | another queue, timing, or private-generation assertion would target solved machinery rather than the observed gap | hardening must remain observable and implementation-neutral | retain all existing blocked-send, capacity, stale-output, no-steno, and descriptor tests unchanged | reject extra races, private state inspection, and timing deadlines |

The version-42 revision therefore adds only the missing fresh-awaited-producer
to BLE-first-host composition. It does not change `meta.md`, the reference
behavior, queue capacities, feature lanes, or test count. Because `test.patch`
changes, this is a new immutable candidate: the environment, pristine,
reference, gap, fairness, false-positive, patch-order, and stored-solution
checks must all be repeated, and calibration restarts at 0/10. No cold solver
is requested or run.

#### Version 42 exact closure

The final test patch is
`2542d97ef7760e746046cd4c9add44f728ba5ca2f64ae1848df03060a2b1e62e`.
The integrated BLE host test now parameterizes its exact snapshot expectation,
awaits one report from every enabled family while both routes are inactive,
activates BLE first, and observes the real GATT reports. The mouse replay must
retain buttons and zero x/y/wheel/pan. Neutral awaited updates then clear this
phase before the existing direct, blocked, stale, and Plover phases continue.
The prompt, reference, Dockerfile, and solution approach hashes are unchanged.

The fail-fast environment gate rebuilt the untouched exact repository and ran
offline as UID/GID `10001:10001`. Test-only passes 538/538 baseline and fails
all 13 focused tests behaviorally; reference and run-15 Nova 2 pass 538/538 plus
13/13. Nova 3--5 pass the changed BLE phase. All five run-15 patches accept
verifier injection without overlapping participant-owned files. An initial
attempt detected a corrupt old temporary clone before behavior; a new
`git fsck`-verified exact checkout completed the gate and is the only result
used.

The new isolated mutant retains fresh disconnected awaited state for USB but
omits it for BLE-first activation. It compiles, passes the version-41-equivalent
13/13 focused set and complete 538/538 baseline, then fails the exact
version-42 BLE phase. The twelve retained mutation classes were re-audited;
their strongest probes remain unchanged and no oracle was weakened. Gap,
fairness, false-positive, shell, application, patch-order, and JUnit checks
pass.

Both patch orders produce combined diff
`d7485ca96ca1b3870477a7e2f309de062e3cfbf06e3a2ad1927a9322bb0e3cfe`
and Git tree `a23473071d66e68f1af523e0860ba57977ca7a5b`. Version 42 starts
calibration at 0/10. Run 15 remains version-41 trajectory evidence; no cold
solver was run.

### Version 43 trajectory-informed correction gate

This gate was recorded before changing the version-42 verifier. I reread
`PROBLEM_DESIGN.md`, `CALIBRATION_STRATEGY.md`, the global environment, gap,
and fairness protocols; searched `problems/README.md`, both candidate indexes,
same-repository records, and this problem's compact history; and inspected all
five run-16 evaluator reports, JUnit files, test logs, implementation patches,
final messages, and available trajectory records.

All five runs reached the evaluator's real Cargo/test processes. Nova 5 is the
representative legitimate pass at 538/538 plus 13/13. Nova 3 is a broad product
failure: its no-steno descriptor regresses and BLE host replay times out. Nova
1 fails public channel compatibility and removes a baseline testcase. Nova 4
has deterministic route-filtering failures. Nova 2 is the important near-pass:
it passes 538/538 plus 10/13 and uses route-aware USB/BLE writers that consume
or discard ordinary packets only while their transport activation is current.
Its three failures are verifier timeouts caused by hidden probes directly
injecting progress markers into retired route channels and requiring those
markers to reach an inactive old host. The public contract requires the
opposite for stale old-route traffic and does not require inactive writers to
transmit. This is a verifier architecture mismatch, not an external dependency
or container failure.

The run also exposes a process failure. Version 42's environment gate replayed
the reference and previously known-good architectures, but no route-gated
writer. The fairness audit discussed host-visible progress without tracing the
progress marker's route lifecycle. Therefore the environment result correctly
proved offline/non-root execution and injection, but was insufficient as an
architecture-compatibility gate. Nova 2 must become a mandatory must-pass replay
for the corrected exact version rather than merely a compatible patch.

#### Version 43 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect or legitimate behavior | Public invariant | Black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Nova 2 filters both writers by the current route and times out only because probes send a marker directly to an inactive channel | a correct implementation stops old-host output after retirement, so an inactive-route marker is deliberately discarded | stale traffic must not reach the previous host; no inactive-writer delivery is promised | reactivate the route, submit progress through the ordinary public producer while it is active, and validate every host packet until the current state crosses the same writer | remove every inactive-route marker requirement; promote Nova 2 to a mandatory exact must-pass architecture replay |
| Review and `rmk/src/state.rs` show activation identity is transport-independent; version 42 delays a blocked future across USB→BLE→USB only | a send blocked during BLE activation N can survive BLE→USB→BLE and emit raw relative data during BLE activation N+1 | leaving and returning to the same transport must not revive a send from an earlier activation | fill BLE, poll an awaited mouse send to pending, retire BLE, update state on USB, reactivate BLE, then resume the old future and observe real GATT output until an active marker | fold the missing BLE activation boundary into the existing integrated GATT probe; do not add profile-specific duplicates because both profile/status setters feed the same visible activation transition |
| The prior USB capacity-three test uses an inactive direct channel marker to delimit stale output | route-gated USB writers can be correct yet never emit the marker | complete stale disposal must remain observable for supported capacity three | reactivate USB, submit a current active marker, require current all-family state, and reject each stale queued value before completion | preserve the multi-entry/old-USB discriminator while removing the writer-lifecycle assumption |
| The platform labels verifier mismatches under environment assessment, while the current script can omit a newly accepted architecture replay | a future gate invocation can pass by replaying only the reference and convenient historical solutions | known legitimate architectures must survive exact evaluator composition before a revision is approved | maintain a per-problem mandatory replay manifest consumed automatically by the global gate; missing/unreadable entries or any non-green replay block the gate | only explicitly adjudicated legitimate verifier-blocked architectures enter the manifest; ordinary failing solvers remain injection-only evidence |

Version 43 will change the verifier and global environment-gate machinery, so
all exact environment, gap, fairness, false-positive, patch-order, and reference
checks restart at zero. The prompt and reference behavior need no expansion:
BLE activation identity is already stated transport-generically. Run 16 belongs
to version 42 and cannot count toward version-43 calibration. No cold solver is
requested.

#### Version 43 exact closure

The frozen verifier is
`fc9e5b26a6ffc0721b268ffe2dd7db9e671f5f7dad3a7c6dd80262f7acb11350`.
The BLE integrated probe now polls a send to pending on a full BLE activation,
retires BLE, records terminal neutral state on USB, reconnects BLE, and only
then resumes the old future. It observes real GATT notifications until an
active system-control marker and rejects any non-neutral old-session packet.
The USB and BLE stale-queue progress boundaries likewise use active-route
producer traffic; no inactive writer is required to deliver a test marker.

The first no-cache environment attempt correctly stopped before behavioral
auditing when BuildKit could not commit its metadata: the host data volume had
451 MiB free and Docker Desktop exited. After removing only this audit's
temporary target, the failed build's exact cache chain, and two obsolete RMK
cold image tags, Docker restarted with sufficient space. The full untouched
checkout gate then passed offline as UID/GID `10001:10001`. Pristine is 538/538
baseline and 0/13 focused with thirteen behavioral failures and zero errors;
reference and mandatory run-16 Nova 2 are both 538/538 plus 13/13.
The global executable now performs a 12 GiB host-space preflight before cloning
or building; its forced-low-space path exits 96 with a startup-blocker message.

`ENVIRONMENT_REPLAYS.sha256` pins Nova 2 at
`80fb76a13daf6d5f895ecff837d1455d403d0452c64f6dccc1ad4537af24277f`.
The global gate consumes this manifest automatically and blocks on a missing
file, hash mismatch, injection conflict, baseline regression, focused failure,
or startup/JUnit error. This converts an adjudicated verifier mismatch into a
permanent architecture-compatibility regression test.

The new isolated mutant validates blocked USB sends by full activation but
validates blocked BLE sends by transport identity only. It compiles and passes
the complete 538-test baseline, then version 43 observes stale report ID `0x02`
with raw payload `[5, 12, 245, 10, 247]` after BLE disconnect/reconnect. The
same mutant passed the prior focused behavior before this phase. Retained
mutation classes were re-audited and no strongest oracle was weakened.

Both patch orders produce combined diff
`ce351882c09c380e73539c722e34652eb8dbb2d43809fac5212ad21bc3c27442`
and Git tree `6bdb0e12b5a7829a2467104101a30d94d13f9516`. Application,
shell, artifact, environment, gap, fairness, false-positive, and JUnit checks
pass. Version 43 starts calibration at 0/10; no cold solver was run.

### Version 44 run-17 trajectory-informed profile/session hardening gate

This gate was recorded before changing the version-43 prompt, verifier, or
reference. I reread `PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`; searched
`problems/README.md`, both candidate indexes, the accepted RMK snapshot record,
and this problem's compact history for BLE profiles, CCCD persistence, route
activation, and Plover integration; and inspected all run-17 evaluator reports,
JUnit logs, implementation patches, final messages, and available raw trajectory
records. The raw records contain the participant prompt and final response but
not intermediate tool turns, so platform-reported agent-message counts are
unavailable and are not inferred from the four stored trajectory records.

Run 17 contains ten completed evaluations, not eleven: Nova 8 submitted no
solution and has no evaluation. Nova 4--7 and 9--11 are seven legitimate passes;
Nova 1--3 are coding failures; no evaluated run is environment-blocked. Nova 10
is the representative legitimate pass at 538/538 baseline plus 13/13 focused
tests. It changes six production files and implements a route generation,
per-family retained state, independent replay queues, writer consumption, and
Plover GATT output. Nova 2 is the near-pass at 536/538 plus 12/13: its handoff
state machine works, but it makes the steno report-map extension unconditional
and breaks the no-steno descriptor size. Nova 3 is the broadest completed
behavioral failure at 538/538 plus 10/13: its BLE writer snapshots the route
before awaiting a report and discards replay created by `None` to BLE activation.
The successful patches modify six to eight production files and add a median of
roughly 380 effective production lines. They are substantive, but all seven
converge on the same transport-wide route-generation plus retained-snapshot
architecture described by the public outcomes.

The exact batch therefore solves at 7/10 and fails the <=50% difficulty gate.
At the target `p = 0.28`, observing at least seven solves in ten has probability
about 0.7%; changing whitespace and rerunning would not change the underlying
problem. Version 43 is abandoned as too easy, while its runs remain trajectory
evidence. Version 44 must restart every exact gate and calibration at 0/10.

Repository inspection identifies a distinct host-identity boundary that the
transport-wide implementations do not model explicitly. RMK already treats BLE
profiles as separate bonded peers, stores a `ClientAttTable` per `ProfileInfo`,
disconnects on profile change, and restores that peer's CCCD table on the next
connection. Five of the seven successful run-17 patches add the Plover
characteristic without including its CCCD in the existing update bookkeeping;
none adds profile-specific handoff logic beyond the generic BLE transport path.
Version 38 deliberately repaired the reference's missing steno CCCD condition
without testing it because persistence was then unstated. Version 44 supersedes
that decision only by making the peer-visible profile and subscription behavior
an explicit public requirement.

#### Version 44 discriminator ledger

| Trajectory/repository evidence | Plausible incorrect behavior | Public invariant | Black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Seven legitimate passes model USB and BLE route activations, while RMK's profile manager identifies multiple bonded BLE peers | switching BLE profiles reuses one transport-wide activation, allowing a pending old-profile send or queued packet to enter the next peer session | each BLE profile is a separate host activation; profile switches obey the same stale-disposal, blocked-send, and current-state replay rules as USB/BLE handoffs | block an awaited report in one profile, switch profiles through RMK's status seam, reconnect the next profile, and observe real GATT output: only the latest absolute snapshot may arrive | test peer-visible packets and status-driven profile changes; do not inspect route counters, queue ownership, or require an internal profile key representation |
| Five of seven passing patches omit the Plover CCCD from the sibling keyboard/mouse/media/system/battery update condition; RMK stores and restores the whole CCCD table per bonded profile | steno works only in the connection where a test manually enables notifications; its subscription is neither saved nor isolated per profile | a Plover subscription must follow RMK's existing per-profile notification-subscription lifecycle and be restored for that peer without enabling it for another profile | subscribe to report `0x50` through ATT, carry the resulting profile state across a scripted reconnect/profile change, and require exactly the subscribed peer's eight-byte host notification | require the observable subscribe/reconnect result and arbitrary valid internal persistence; do not assert signal names, raw table layout, storage encoding, handle numbers, or write ordering |
| Run-17 solutions already pass every capacity/family/direction permutation in version 43 | more queue fixtures or another transport-direction example would repeat solved machinery | hardening must cross an independently implemented peer/session and GATT-subscription boundary | retain the existing 13 tests unchanged except for composition needed by the new integrated peer test | reject timing stress, private cache assertions, exact scheduler order, and redundant family matrices |

The public description will state the new peer/session and per-profile Plover
subscription outcomes without prescribing signals, storage records, or queue
types. The reference will use RMK's existing profile and CCCD lifecycle. The
verifier will extend the real BLE host harness, use a generous deadlock watchdog
only as harness protection, and accept arbitrary replay order and implementation
structure. No cold solver is requested during construction.

#### Version 44 exact closure

The frozen artifacts are `meta.md`
`b56baea0aeaa69afd2ddab1fce1bceb52999e595989d9dde6486eee2033e8d45`,
`test.patch`
`4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`,
`solution.patch`
`3e95163813741211b836a5d19d12cb795cd2ebc8126fc02b76e7a7b70ee38f65`,
and Dockerfile
`be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`.

The new integrated test discovers report characteristics from their actual GATT
report-reference descriptors, subscribes profile zero to Plover report `0x50`
through ATT, and carries the opaque saved CCCD table through RMK's existing
profile lifecycle. It then leaves a non-neutral keyboard packet queued and an
awaited mouse send blocked in profile zero, switches to profile one, and permits
only neutral cleanup plus the current absolute mouse snapshot. Profile one must
not inherit the Plover subscription. Reconnecting profile zero with its saved
table must deliver the exact retained eight-byte chord. The oracle permits
arbitrary family order and optional neutral output, and never reads a candidate
cache, route generation, lock, handle constant, or persisted-table layout.

The clean no-cache environment gate ran from the untouched pin, then executed
all runtime phases offline as UID/GID `10001:10001`. Test-only passes 538/538
baseline tests and fails all 14 focused tests behaviorally with zero startup
errors. The reference passes 538/538 and 14/14: 10 capacity-one steno, two
capacity-three steno, and two capacity-one no-steno tests. Four representative
run-16/run-17 patches compose with the verifier without file overlap. Earlier
must-pass replays predate the expanded profile contract, so version 44 records
them as injection-only evidence rather than falsely requiring them to pass new
public behavior.

Two exact false-positive probes validate the added discriminator. The run-17
Nova 9 transport-wide implementation still passes the prior 13 focused tests
but fails only the profile test because it erases held state during the
profile-switch no-host interval. An isolated reference mutant that omits the
steno CCCD from update bookkeeping passes all 538 pre-existing tests and the
same 13 prior focused tests, but the profile test fails when the Plover
subscription never enters persistence. The mutant was rerun after the final
queued-stale assertion was frozen. No actionable survivor remains in the
trajectory- and repository-supported mutation set.

Both patch orders produce combined binary diff
`d7485ca96ca1b3870477a7e2f309de062e3cfbf06e3a2ad1927a9322bb0e3cfe`
and Git tree `edc88a698c447f78958958a293fd9f98e229d515`. Application,
shell, artifact, environment, gap, fairness, false-positive, JUnit, and
reference checks pass. Version 44 starts calibration at 0/10; run 17 remains
version-43 trajectory evidence and no cold solver was run.

### Version 45 run-18 verifier-mismatch correction gate

This gate was recorded before revising `test.patch`. I reread
`PROBLEM_DESIGN.md` and `CALIBRATION_STRATEGY.md`, the version-44 discriminator
ledger, and the run-18 evaluator reports, JUnit logs, implementation patches,
and available raw trajectory records. Run 18 has two legitimate passes (Nova 1
and Nova 3), several deterministic product failures, and one verifier mismatch
(Nova 9). Nova 1 is the representative pass: route generations, retained
per-family state, replay lanes, and Plover output pass 538/538 baseline plus
14/14 focused tests. Nova 8 is the broad failure: its no-steno descriptor
regresses and its changed CCCD signal interface also prevents the hidden steno
lane from compiling. Nova 9 is the decisive near-pass: 538/538 baseline and the
two no-steno tests pass, but the twelve steno tests never compile.

Nova 9 reasonably changes the private `UPDATED_CCCD_TABLE` payload from a raw
CCCD byte vector to `(profile, table)` and updates `ProfileManager` to consume
that representation. Associating an update with the peer that produced it is a
natural implementation of the public per-profile persistence requirement. The
hidden profile probe instead assigns `UPDATED_CCCD_TABLE.wait()` directly to
the repository's former concrete vector type. That structural assumption is
neither public nor necessary, and it blocks every steno behavior test before an
observable assertion runs.

#### Version 45 discriminator ledger

| Trajectory/repository evidence | Legitimate behavior rejected | Public invariant | Corrected black-box oracle | Anti-overfitting decision |
|---|---|---|---|---|
| Nova 9 tags CCCD updates with their originating profile and updates all production consumers consistently | a correct per-profile implementation changes the payload of a private coordination signal | subscribing profile zero to Plover must be persisted, isolated from profile one, and restored when profile zero reconnects | run the repository's `ProfileManager` concurrently with the GATT task and observe the resulting profile record at the existing storage boundary; feed that opaque record into the real reconnect path and require host-visible Plover output | remove every hidden reference to `UPDATED_CCCD_TABLE` and its payload type; do not special-case vector versus tuple or expose another candidate representation |
| The omitted-steno-CCCD reference mutant previously failed because no persistence update occurred | bypassing persistence by reading the live server table would weaken a distinct public behavior | live subscription alone is insufficient; reconnect restoration must use persisted per-profile state | accept only a `ProfileInfo` emitted by the production profile manager after the ATT subscription, then verify profile isolation and reconnect notification | retain the persistence discriminator while moving observation one layer outward; reject direct server-table capture as a false-positive regression |

The requested correction is deliberately narrow. The prompt, reference
solution, Dockerfile, other thirteen tests, and behavioral expectations remain
unchanged. At the user's direction no full environment, gap, fairness,
false-positive, mutation, or cold-solver pipeline will be run for this draft;
it must remain explicitly unverified until those exact-version gates are later
completed.

The corrected `test.patch` is
`52a27bb6b6e55282d1641e6f17e69732477f83d5f7ee3ef1143f3576dfb79921`.
Only the profile/Plover testcase was reproduced. It passes with both the
reference solution and run-18 Nova 9's profile-tagged CCCD signal. No other
test, baseline, environment, mutation, gap, fairness, or false-positive result
is claimed for version 45.

### Acceptance and archive closure

The user confirmed platform approval on 2026-08-12. The canonical submission
artifacts remain in this problem directory, while the eighteen raw calibration
batches are preserved as verified ZIPs under
`archive/rmk-hid-transport-handoff/`. Their duplicate extracted trees were
removed after archive-integrity and normalized-content checks succeeded.

The full version-45 pipeline remains intentionally unclaimed: only the focused
profile/Plover correction was reproduced before acceptance, as recorded above.
Project-specific temporary worktrees, the exact RMK handoff Docker image, and
the `rmk-audit-*` volumes were removed during archival. A cache-filter mistake
also deleted unrelated reclaimable BuildKit cache; it did not delete source
files, images, containers, or volumes, but those cache entries must rebuild on
demand.
