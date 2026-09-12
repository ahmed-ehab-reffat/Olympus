# Resolved design and harness errors

## Run-12 evaluator reset every solver's implementation files

Version 38 registered hidden tests by patching `rmk/src/ble/mod.rs`,
`rmk/src/state.rs`, and `rmk/src/usb/mod.rs`. All five run-12 solutions naturally
edited those same task-critical modules. The platform's three-way merge failed,
then reset the overlapping files to baseline and compiled a hybrid tree with
unresolved symbols. The reported 0/541 and 0/10 outcomes were therefore harness
startup failures, not product failures.

Version 39 makes the verifier additive: randomized test files are registered
only inside the wrapper's temporary source copy, and no hidden hunk touches an
existing participant-owned production file. The new global environment gate
tests exact post-solver injection before any behavioral audit or paid run. It
passes for all five run-12 patch shapes and executes two independent known-good
solutions at 538/538 plus 10/10 in a network-disabled non-root container.

## Blocked BLE send was checked only at the new USB host

The prior USB probe polled each send once while BLE was full, switched to USB,
and accepted correct USB replay without resuming the pending futures or
observing BLE afterward. Version 38 clears capacity only after cutover, awaits
each accepted future, rejects any old BLE enqueue, and advances the real BLE
writer to a host-visible marker. A captured-route duplicate mutant fails both
checks while still producing the expected USB snapshot.

## Steno CCCD update was omitted from BLE bookkeeping

The reference added the Plover characteristic but left its CCCD out of
`gatt_events_task`'s sibling update condition. Version 38 binds the steno
characteristic under its feature gate and includes its CCCD in the existing
activity/persistence path. `solution_approach.md` records the integration step.

## Verifier maintenance was delegated to solvers

Version 37 told participants to update old tests while excluding those tests
from the base lane. Version 38 removes that prose, updates the three obsolete
assertions in `test.patch`, accepts either silence or neutral cleanup, rejects
stale non-neutral traffic, and runs all 541 non-focused cases.

## Fixed-yield stale-output sampling could miss late packets

Version 36 waited for 32 cooperative yields and then drained only packets that
were immediately ready. A stale packet delayed beyond that sampling window
could escape. Version 37 observes each real USB/BLE writer until a later
required report crosses the same path, rejects every stale packet encountered,
and validates packets before snapshot-map insertion. A 64-poll delayed-stale
mutant passes version 36 plus its 538-case baseline and fails version 37.

The mutation pass also found that one capacity-three BLE phase cleared the test
channel after cutover, masking a product implementation that removed only one
stale entry. That test-side clear is removed; the isolated mutant now fails on
its retained steno packet.

## Run-11 manipulation labels were inconsistent

Nova 3 and Nova 4 both update legacy old-host release assertions to match the
public rule that direct handoff needs no release packet. Both pass all product
behavior, but only Nova 4 was labeled cheating. `meta.md` now states that those
obsolete tests should be updated, making the authorized maintenance explicit
without revealing hidden tests or prescribing implementation internals.

## Disconnected blocking producer coverage was media-only

Version 26 exercised every family through `try_send_hid_report` while
disconnected, but only media crossed the independent blocking
`send_hid_report` body. Version 27 drives held→neutral and a second held
snapshot for all five families through the blocking API, observes the real USB
writer, and accepts no private state or queue representation. Separate mutants
for missing blocking held state and missing blocking neutral replacement each
score 13/14 and fail only this test.

## BLE-bound dropped-neutral mouse state was not isolated

The prior suite covered mouse neutral replacement toward USB and other report
families toward BLE. Version 27 establishes held mouse buttons on USB, fills
the one-slot USB queue, drops a neutral mouse update, then observes the real BLE
GATT host. Any nonzero mouse notification fails; a distinct system marker
proves replay progressed, and either silence or an explicit neutral mouse
packet is accepted. The route-specific mutant scores 13/14.

## Version-27 Docker rerun could not start

The unchanged image was selected for a fresh network-disabled arbitrary-UID
run, but Docker Desktop's engine socket remained unresponsive after launch and
never reached `docker info`. No container command ran. The local/offline Cargo
matrix is complete; the prior version's container result is not claimed for
the changed test patch, and submission-ready status remains withheld pending
that environment rerun.

## Offline press/release coverage was keyboard-only

Version 25 proved keyboard press→release while no host was active, but it left
mouse buttons, media, system control, and steno held in that lifecycle. An
implementation could therefore discard offline neutral updates for selected
families and reconnect with a ghost control. Version 26 drives all five
families through held→neutral before any host activation and observes the real
USB writer. A live keyboard marker proves progress, and a second positive
all-family offline-held phase ensures pristine cannot pass by silence. The
oracle accepts silence or explicit neutral cleanup for released families and
rejects every other non-neutral family packet.

## Steno never changed from one held chord to another

Prior tests covered one nonzero chord and nonzero→zero, allowing a first-chord
latch to pass. Version 26 produces distinct chords A and B while offline and
requires exact B at the host-facing USB steno endpoint. The isolated latch
mutant scores 12/13 and fails only this test.

## Absence draft passed pristine by doing nothing

The first all-family no-ghost draft accepted an empty output stream, so the
pristine implementation passed. It was not admitted. The final combined test
requires a live current keyboard packet and then exact positive replay of every
held family. Pristine now fails all 13 focused tests.

## Hidden behavior compiled only when steno was enabled

Version 23 attached both host-observable handoff modules beneath
`cfg(feature = "steno")`. An implementation could therefore leave ordinary
keyboard, mouse, media, and system-control builds on the old routing behavior
while passing every focused test. Version 24 adds a separately randomized
no-steno module and a third wrapper lane. The probe drives the real USB HID
writer at queue capacity one, observes all four neutral releases for a
USB-to-BLE cutover, then observes exact four-family BLE-to-USB replay with
mouse impulses zeroed. It passes the reference and fails the pristine tree.

Version 24 was deliberately left unapproved because its exact false-positive
audit was skipped. Version 25 reruns that audit: a steno-only reconciliation
mutant passes all ten steno tests and fails the no-steno probe, and none of the
22 exact mutants survives the full focused matrix.

## Test patch contained solution code

Version 4 added a receive seam in `rmk/src/channel.rs` and changed both
production writers. Version 5 removed those edits. The current `test.patch`
contains only test code, configuration, one randomized fallback lock, and the
wrapper.

## Public prompt over-enumerated implementation details

Version 4 listed every HID family explicitly. Version 5 replaced the list with
the general rule to cover every enabled stateful family; the variants are
repository-discoverable. Version 6 also begins the title and opening sentence
with “Add” so the feature-request framing is explicit.

## Public prompt stated a default compatibility expectation

The version-10 prompt separately required bounded compatibility with existing
`no_std` feature combinations. Version 11 removes that sentence because not
breaking supported repository configurations is a default expectation, not a
distinct HID-handoff behavior. The explicit one-entry queue requirement and
the feature regression checks remain.

## Standalone new test passed before the solution

The no-ghost test accepted silence, which the base implementation already
produced. Version 7 folds that phase into the required positive offline replay
test. The base fails the positive phase, while the reference must still prove
that a later offline release does not create a ghost. Test-only is now 0/7.

## Small-queue reference inflated the configured capacity

The version-6 build script raised the ordinary report channel to the number of
enabled families, so it did not demonstrate the stated one-entry boundary.
Version 7 removes that override. Each route retains a bounded reconciliation
backlog and lazily refills the actual live channel after receives; generated
`REPORT_CHANNEL_SIZE` was inspected as exactly one in the focused build.

## Lockfile was generated during Docker build

Version 6 ran `cargo generate-lockfile` in Docker and committed no lockfile.
Version 7 commits `rmk/Cargo.lock`, `rmk-types/Cargo.lock`, and
`rynk/Cargo.lock` in `test.patch`. Version 8 additionally accounts for Docker
building before that patch exists: it warms from upstream-committed example
locks and exact pinned package versions without creating a lockfile.

## RMK lock used a predictable participant path

Cargo mandates the filename `Cargo.lock`, so version 9 randomizes its parent
as `.rmk-a01fa986/`. The wrapper copies the source into its writable temporary
runtime directory and installs the lock at `rmk/Cargo.lock` only in that
disposable copy. It never creates or overwrites that predictable path in the
participant tree.

## Docker depended on post-build patch artifacts and did no Rust build

Version 10 derives its runtime locks exclusively from the pristine checkout,
performs explicit RMK and Rynk builds while networking is available, and then
uses those locks for complete locked fetches. The official offline wrapper uses
the image-derived RMK lock; it does not require any lock added later by
`test.patch`. Debian DBus and pkg-config revisions are explicitly pinned.

## Package-level RMK resolution missed newer cached archives

The authoritative image lock selected an older `bytemuck`, while an unlocked
package-level RMK invocation could resolve 1.25.2 and then fail offline. Warming
only that crate exposed the same issue at the next newer transitive version.
Version 12 therefore fetches the complete package-level RMK graph during image
construction and removes its temporary lock afterward. The deterministic
harness still uses the separate lock under `/opt`, and no synthetic top-level
workspace or participant-tree lock remains in the image.

## Non-root cache visibility and fallback lock drift

The package-level warm was still vulnerable to image-builder ownership and
umask details, and the randomized fallback lock had been resolved separately
from Docker's authoritative lock. An evaluation UID could therefore fail to
locate or read an otherwise downloaded archive, while the fallback could select
a different version such as `zerocopy` 0.8.55 that the authoritative fetch
never cached. Version 13 declares `/opt/cargo` as `CARGO_HOME`, explicitly
caches the reported `bytemuck` 1.25.2 archive, normalizes the registry and git
cache for arbitrary-UID reads, and regenerates the fallback from the exact
pristine image lock. The two locks are byte-identical and the locked offline
RMK probe passes with networking disabled as UID/GID `12345:23456`.

## Harbor reference patch was order-dependent

Two formatting-only hunks in `solution.patch` targeted test helpers introduced
by `test.patch`, so applying the solution first failed and left Harbor running
the unpatched behavior. Version 10 removes those non-production hunks. Both
patch orders now apply cleanly, produce byte-identical implementation files,
and the solution-first reference passes 7/7.

## Sibling Cargo roots were incomplete offline

Caching only `rmk` left `serde-wasm-bindgen` and `nusb` unavailable to sibling
package commands. Docker now builds and caches Rynk and installs
`libdbus-1-dev` plus `pkg-config` for its Linux BLE member. Version 14 removes
the `rmk-types` and `rynk` lockfiles from `test.patch` because neither wrapper
mode references them; their presence was test-patch noise rather than part of
the offline contract.

## Harness startup could look green

The wrapper uses unique writable target/store paths and synthesizes a JUnit
`harness-startup` error whenever Cargo exits before nextest produces XML. An
intentionally missing toolchain verifies that path.

## Harness pinned a runtime toolchain and new tests used short waits

Version 14 removes `RUSTUP_TOOLCHAIN` assignment from `test.sh`; the wrapper
inherits the toolchain installed by its execution environment. New handoff
tests no longer use 1–2 ms timer delays. The blocked-send case deterministically
polls the future once to pending, and absence checks inspect immediate queue
state. Ten consecutive focused runs pass 8/8.

## BLE steno coverage stopped before the writer

The earlier suite accepted a steno replay once it entered
`BLE_REPORT_CHANNEL`, but the production BLE writer explicitly dropped it.
Version 14 adds a test-only notification sink around the real writer and checks
both the Plover report map and emitted chord bytes. The reference adds report
ID `0x50` to HID-over-GATT and sends the eight-byte steno payload.

## BLE steno probe depended on private server layout and unstated scope

Version 14's notification sink added test-only fields and a constructor to
private `BleHidServer`, so a legitimate implementation with a different server
layout could fail to compile. The pinned documentation also described steno as
USB-only, making “every enabled family” insufficient notice of a new BLE
characteristic. Version 15 explicitly requires Plover-compatible BLE input in
`meta.md` and removes every test-patch edit to `ble_server.rs`. Its replacement
runs a real in-memory HCI/GATT client against RMK's ordinary BLE runtime,
discovers and subscribes the Plover report, and validates the host-visible ATT
handle and eight-byte payload. The exact mutation audit separately rejects an
absent report map, a silent writer drop, and delivery on the wrong
characteristic.

## Handoff wrapper narrowed a public channel API

The version-13 `ReportChannel` exposed only the methods needed internally and
therefore broke downstream calls available on the prior public Embassy
`Channel` statics. Version 14 compile-checks representative `sender()` and
`receiver()` calls. The reference implements `Deref` and `AsRef` to the
original concrete channel while keeping its private bounded backlog.

## Blocked-send probe fixed one scheduler ordering

The old route now drains concurrently during cutover and retains every observed
report. The test rejects a pressed report on the old route without requiring a
particular family order or wall-clock sleep; removing the route recheck fails
only this test.

## Reverse-direction coverage exercised only media

Version 15's BLE→USB test proved direction selection but covered only the media
family. A transport-specific implementation could therefore omit keyboard,
mouse, system, or steno handling on that route. Version 16 mirrors the
all-family USB→BLE contract in reverse, observes unordered old-host releases
and new-host replay, and requires zero relative mouse fields. An isolated
legacy-mouse/media-only reverse mutation passes the other eight focused tests
and fails only this one.

## Cutover steps were individually atomic but not jointly serialized

Version 15 remembered report state, selected the active route, enqueued, and
reconciled channels under separate critical sections. A producer could select
the old route and append pressed state after reconciliation cleared it, or have
a new-route enqueue replaced after the route commit. Version 16 keeps route
commit and reconciliation under the connection-status boundary and requires
both blocking and nonblocking producer attempts to record state, select, and
enqueue under that same boundary. Blocking sends release it while waiting for
capacity and retry safely. A black-box barrier/atomic probe races 2,000
cutovers with production and host draining in both directions; it has no
sleeps or private-state dependency. The unsynchronized v15 reference fails
10/10 isolated runs, while the synchronized reference passes 20/20.

## Pure-test oracle has an architecture tradeoff

The direct-channel oracle passes the canonical implementation but cannot see a
replacement writer-private reconciliation lane without adding forbidden
production code to `test.patch`. This remains an explicit false-negative risk;
the suite does not turn the canonical backlog layout into a public requirement.

## BLE host test imported a private parent-module alias

Version 16's BLE test reached `BLE_REPORT_CHANNEL` through a private alias in
`rmk::ble`. Two otherwise meaningful stored implementations removed that alias
while preserving the public channel, so the focused crate failed before their
behavior could be evaluated. Version 17 imports
`crate::channel::BLE_REPORT_CHANNEL`, the public defining path. Replaying all
ten stored patches confirms that the two verifier-blocked runs now compile; the
stronger reaches 7/12 focused tests.

## Prompt prescribed service placement and left protocol boundaries implicit

The task required BLE Plover delivery but unnecessarily named RMK's existing
composite HID-over-GATT service. It also left single-transport no-host
reconciliation, per-family full-queue state, and exact Plover descriptor
semantics to interpretation. Version 17 removes the service-location clause and
states only observable requirements: Plover usage and 64-bit chord shape,
matching input-report reference, exact payload order, independent absolute
family state, and lifecycle behavior in USB-only and BLE-only builds.

Four isolated mutants demonstrate the value of the corresponding probes. Each
scores 11/12 and fails only one new test: forget dropped steno state, guard
reconciliation behind BLE, guard it behind USB, or advertise the wrong Plover
usage.

## Multiple focused feature lanes could overwrite JUnit

Adding USB-only and BLE-only behavior requires separate Cargo feature builds.
Version 17 stores each nextest document separately and merges them beneath one
`<testsuites>` root. The base and reference reports contain all 12 distinct
testcases. If Cargo cannot start, the wrapper emits one explicit
`harness-startup` error per lane instead of returning an empty report.

## Solver/test merge produced an impossible hybrid tree

`agent-runs2/Nova_Nova_4` added its own tests at the end of `state.rs`, the same
location occupied by hundreds of hidden-test lines. The platform three-way
merge failed and its fallback reset all six test-patch files to the base while
retaining the solver's changed `channel.rs`. Baseline `state.rs` then called a
function the solver had removed, so the wrapper reported synthetic missing
tests rather than evaluating the solution.

Version 18 moves state behavior to randomly named test-only source
`rmk/src/handoff_verifier_7c91e4.rs` and adds only a four-line module
declaration to `state.rs`. The exact run-4 patch and final verifier now merge
cleanly. It executes all 16 tests and scores 1/16, proving the blocker is gone.

## Version-17 suite admitted a combined shortcut

The prior tests used the blocking producer for offline state, tested only held
nonblocking values, and exercised only keyboard in single-transport builds. A
combined implementation could therefore forget no-route nonblocking state,
ignore a dropped neutral value, and keep rich-family lifecycle logic behind the
dual-transport feature guard. It passed all 12 version-17 focused tests and the
541-test baseline.

Version 18 adds distinct probes for those boundaries. It also fills the old
route with a deliberate held report before each directional cutover; merely
appending neutral releases without clearing stale traffic now fails.

## Producer/cutover stress depended on OS scheduling

The version-17 2,000-round `thread::yield_now` probe could widen a race but not
force it. Barriers alone cannot pause the pinned nonblocking producer between
route selection and enqueue, while a production hook would prescribe a private
router architecture. Version 18 removes the stress test, retains the fully
deterministic blocked-send cutover test, and states that other producer calls
racing transport setters are outside the task. An exact split-critical-section
mutation passes 16/16 and 541/541 and is recorded as legitimate under that
narrowed contract rather than hidden as an untested requirement.

## Legacy-queue observation rejected legitimate writer-side solutions

The `agent-runs3` batch appeared to have a 0% success rate: fifteen of sixteen
tests failed in three implementations that had passed the baseline and BLE
Plover integration checks. Raw trajectory and patch inspection showed that
these solutions routed reconciliation through dedicated writer-side queues or
pending-family signals. The old verifier drained only `USB_REPORT_CHANNEL` and
`BLE_REPORT_CHANNEL`, bypassing the changed writers and reporting host failure
without observing either host.

Version 19 moves the assertions to the real transport boundary. Test-only USB
endpoints capture packets written by `UsbKeyboardWriter`; the in-memory BLE
host captures notifications written by `run_ble_keyboard`. Replaying the same
patches now gives two independent architectures 7/7. A third receives 6/7 for
a genuine old-host escape by an already-blocked send. The two remaining runs
retain real descriptor-API compile errors. This resolves the environment/test
blocker without requiring the reference's internal queue design.

The version-18 single-transport all-family requirement also produced distinct
conditional-compilation work beyond the core dual-transport task. Version 19
removes it as the explicit easing lever while retaining USB-only and BLE-only
compile/regression checks.

## Version-19 tests composed neither side of two required transitions

The host-observed redesign still left two holes. Its blocked-send test selected
BLE but inspected only old USB, then switched back to USB to establish eventual
replay. A solution could therefore defer the state until the old queue woke and
miss the immediately active BLE host. Its disconnect and offline tests also did
not compose active-held state, a no-host interval, and activation of the other
transport.

Version 20 makes the BLE GATT host observe the pending send's absolute mouse
state during the first BLE activation. A separate USB-writer phase carries all
five families from active BLE through `None` to USB. Isolated compiling mutants
that delay the blocked state or clear state on entry to `None` each pass six of
seven focused tests and fail the intended new boundary. The reference and two
independent stored solver architectures pass both additions.

## BLE release snapshots could hide stale packets

Version 20 inserted notifications into a map before checking the final family
values. A stale held packet followed by a neutral packet for the same family
could therefore be overwritten. Version 21 validates every USB and BLE release
packet immediately, then records only family coverage. An append-without-clear
mutation now fails at the first stale mouse/media payload.

## Remaining transition directions were asymmetric

The direct USB-to-BLE old-host phase required only a keyboard release, offline
activation was host-observed only for USB, and BLE-to-none was not observed.
The full-queue blocked-send boundary also began only on USB. Version 21 adds
all-family old-USB releases, offline-to-BLE, USB-held-to-none-to-BLE,
BLE-to-none all-family releases, and both old-BLE/new-USB halves of a send
already blocked on full BLE. Six isolated transport-specific mutants confirm
that each strengthened boundary rejects a plausible shortcut.

## Concurrency scope read like a test specification

The public sentence named “the required concurrent cutover boundary” in
templated prose. Version 21 states the same scope naturally: a send already
waiting on a full queue must not escape the old route and its latest absolute
state must reach the new host; other report-production/connection-state races
are not in scope.

## Fresh-image reproduction had not been repeated

The prior freeze reused an older local image. Version 21 performs a complete
`docker build --no-cache` from the untouched pin. The exact test-only and
reference patches are injected only afterward, and the complete baseline plus
focused matrix passes with networking disabled as UID/GID `12345:23456`.

## Plover descriptor fragments were not structurally connected

Version 21 searched the composite BLE report map for the Plover usage page,
usage, report ID, Logical collection, and 64-bit count as independent byte
windows. A malformed descriptor could scatter those items or place its Input
item outside the collection. Version 22 parses the host-readable HID short
items and requires one Logical collection selected by usage page `0xff50` and
usage `0x4c56` to contain report ID `0x50`, an explicit 64-bit shape, and a
Data/Variable/Absolute Input item. A fragment-only descriptor mutant retains
every old byte window and host notification but now fails only this semantic
oracle. Both stored legitimate descriptor-generation approaches still pass.

## One-entry configuration could not prove complete stale-queue disposal

The capacity-one lane proved reconciliation below the family count, but an
implementation that removed only the first old-route entry was observationally
equivalent to clearing that queue. Version 22 preserves the one-entry lane and
adds an independent capacity-three lane. Its host-output probe queues three
distinct stale packets before cutover, rejects every non-neutral USB packet,
and requires the complete neutral release set. The isolated clear-one mutant
passes all eight one-entry tests and fails only the new multi-entry test.

## Dropped-neutral replacement was host-observed only toward USB

Version 22 filled the active BLE queue, dropped neutral keyboard, media,
system, and steno updates, and observed replay at the newly active USB host.
That did not reject a transport-specific implementation that retained the old
held snapshot only for BLE output. Version 23 adds the reverse host boundary:
it fills active USB, records the same neutral updates nonblocking, switches to
BLE, and rejects every prior held value in real GATT notifications. A mutant
that ignores only neutral USB-side updates passes seven of eight capacity-one
tests and fails this BLE-host phase.

## Multi-entry stale disposal covered only an old USB route

The version-22 capacity-three probe queued three stale USB packets, while BLE
cutovers still used only one ordinary queued packet. Version 23 runs the real
BLE host probe in the same capacity-three lane, queues distinct media, mouse,
and steno packets without yielding before cutover, validates every notification
as neutral, and checks for late output. A BLE-specific remove-one mutant passes
all eight capacity-one tests and the old-USB capacity-three test, then fails the
new old-BLE test.

## Harness comment contained evaluator framing

The fallback-lock branch described what the “official image” supplies. Version
23 replaces that authoring context with the operational statement that the
bundled pristine-build lock is the fallback. Lock selection and runtime
behavior are unchanged.

## Hidden behavior required the optional steno feature

All version-23 host behavior modules compiled only with `steno`, so an
implementation could put its complete handoff core behind that feature and
still pass. Version 24 added a separately named no-steno module. At capacity
one it drives the real USB writer, requires all four enabled families to be
released on USB-to-BLE, then requires exact four-family replay on BLE-to-USB.
An isolated steno-only implementation passes all ten steno tests and fails this
one test.

## Host probes imposed an unstated one-second deadline

The prompt specifies observable handoff behavior but no numeric completion
latency, and the repository USB writer contains a 500 ms retry path. Version 25
replaces every exact one-second USB/BLE host timeout with a named 30-second
test-harness watchdog. The code comments explicitly distinguish deadlock
protection from a firmware latency requirement. All behavioral assertions,
queue capacities, feature lanes, and the reference implementation are
unchanged. Ten repeated reference matrices pass 11/11.

## Run-10 successes were mislabeled as cheating

The version-35 base lane selected every test not named `hid_handoff_*`. Three
pre-existing state tests in that set require an all-up report to be sent to the
old host during disconnect or replacement. Version 30 deliberately removed
that protocol from the participant contract, which now says no release packet
to the old host is required.

All five run-10 solutions independently updated those stale assertions. Nova 3
and Nova 5 also passed all ten focused host-output tests, but the wrapper called
them cheating because two renamed test IDs disappeared. A third assertion was
changed without renaming, showing why test-ID presence alone did not identify
the whole conflict.

Version 36 excludes exactly those three obsolete semantics from the base
nextest expression. It does not skip `state.rs`, participant tests, or any
current handoff behavior. Reference and pristine each retain 538/538 baseline;
Nova 3 and Nova 5 pass that inventory plus 10/10 focused. Nova 1 still fails its
descriptor and writer paths, while Nova 2 and Nova 4 still fail the public
channel API compile boundary. The change removes a false negative without
creating a demonstrated false positive.

## Blocked sends were associated only with a transport name

Version 39 rejected a blocked packet after a direct USB↔BLE replacement, but it
did not retire the packet when the route returned to the same transport before
the future resumed. Two successful run-13 solutions compared only
`active_transport()`, so USB→BLE→USB made the old USB send look valid again.
Version 40 adds a deterministic real-writer probe for that activation boundary.
It requires current zero-relative replay and rejects the earlier raw live mouse
packet; it does not require an epoch field or expand the task to arbitrary
producer/setter races.

## Fresh offline async production was not isolated

Disconnected retention was extensively tested through `try_send_hid_report`,
while awaited sends were exercised only on an active or initially full route.
An implementation could therefore return early from a fresh
`send_hid_report(...).await` made with no active host. Version 40 adds one
representative offline async mouse send and observes its absolute replay through
the real USB writer. It does not duplicate the same API branch across every
family and destination.

## Run-14 probe reset depended on a private state representation

Version 40's additive USB probes directly wrote the crate-private
`CONNECTION_STATUS` static as a `Cell<ConnectionStatus>`. Nova 1 legitimately
wrapped status and route generation in a different internal type and updated
the repository's visible test reset helper, but the probes then failed to
compile before behavior ran. Version 41 calls `test_support::reset_connection_status`
instead. Exact replay of the same Nova 1 patch now compiles and passes 13/13.

## Offline awaited-send coverage was mouse-only

The fresh disconnected `send_hid_report(...).await` probe established the API
branch only for mouse. Version 41 sends held keyboard, mouse, media, system, and
steno reports through fresh awaited calls while no route is active, then
requires the exact all-family USB-writer snapshot with zero relative mouse
fields. A mouse-only retention mutant now fails this single combined probe.

## Capacity-three stale disposal had no old-USB runtime boundary

The previous capacity-three lane host-observed only an old BLE route. Version
41 queues three distinct stale USB packets after establishing held state, cuts
over to BLE, and drives the real USB writer through a post-cutover marker while
rejecting every non-neutral packet. It then returns to USB and requires the
preserved all-family snapshot. A USB-specific clear-one mutant fails; the BLE
mirror remains independently covered.

## Wrapper commentary used benchmark framing

The isolated-module registration comment referred to evaluator/solver context.
Version 41 describes only the operation performed on the disposable source
copy. No executable harness behavior changed.

## Fresh disconnected awaited state was observed only by USB

Version 41 covered every family through `send_hid_report(...).await` while no
route was active, but activated USB afterward. Earlier BLE-first offline replay
used only the separate nonblocking producer. A transport-specific retained
snapshot could therefore serve USB while omitting fresh awaited state from BLE.

Version 42 adds one phase to the existing integrated BLE host test. It awaits
held keyboard, mouse, media, system, and steno state with both routes inactive,
activates BLE first, and requires exact host-facing GATT notifications with
mouse relative fields zeroed. A targeted mutant passes the prior focused suite
and 538/538 baseline but fails this phase.
