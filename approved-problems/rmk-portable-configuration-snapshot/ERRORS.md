# Errors and review resolutions

There are no known environment failures in the version-56 draft. Its exact offline arbitrary-UID regression and focused lanes pass in the retained arm64 and amd64 environments. Expected test-patch-only `new` compilation is a skipped placeholder, while genuine no-JUnit startup failure is an error. The exact version-56 false-positive audit and full patch-state matrix were not completed because the user asked to skip them, so no earlier audit may be attributed to version 56.

Version 1 used the wrong Cargo working directory during the Docker build and was invalidated before calibration. Version 2 corrected that build path and passed its checks, but a later review found that the description omitted exact public record fields while tests assumed them, several tests matched private `SnapshotError` details, unsupported bulk transfer lacked a direct probe, prose was manually wrapped, and predictable harness filenames could collide with participant files.

Version 3 resolves those findings by specifying the public record and restore-progress interface, loosening rejection assertions to accept any `SnapshotError`, constructing geometry without a `From` requirement, adding the unsupported-bulk no-write test, narrowing the WASM promise to its byte-oriented public methods, using ordinary Markdown paragraph wrapping, and randomizing the lock-seed and WASM test paths. Dimension overflow was removed as an impossible public state for the bounded geometry types rather than tested through an artificial widened model.

A later review invalidated version 3 because the Dockerfile used an unaccepted base reference, export order was tested but not stated, the exact value of `SNAPSHOT_VERSION` and the public `SnapshotRead` surface were not independently checked, and the WASM methods were only compiled. Version 4 uses the accepted Rust base, states the export order, checks the constant and type across the crate boundary, and runs both byte methods through a JavaScript link under Node. The complete version-4 verification and 18-mutant audit passed.

Environment review then invalidated version 4. Its hard-coded `1.95.0-aarch64-unknown-linux-gnu` selector attempted to run arm64 Cargo under the amd64 image and failed at the `cargo-nextest` install with a missing arm64 loader. Its apt command also installed unpinned packages, and the opening description repeated information already defined by the public fields and ordered operations.

Version 5 selected `RUSTUP_TOOLCHAIN=1.95.0`, allowing rustup to use the native x86_64 or aarch64 toolchain supplied by each base image. It pinned `libdbus-1-dev=1.14.10-1~deb12u1`, removed the redundant `pkg-config` install because version 1.8.1-1 is already in both base variants, and removed the duplicate description sentence. Its checks passed only in author-time contexts that already contained the randomized lock seed.

A fresh-clone review invalidated version 5 because the Dockerfile tried to copy `rynk/.olympus_7f3c91/Cargo.lock` before `test.patch` was injected. Version 6 removes the lockfile from `test.patch` and the runner. The networked Docker build now generates `rynk/Cargo.lock`, pre-resolves the later test dependencies, fetches and builds native and WASM targets offline, and restores the original manifest. Exact fresh-checkout builds and post-build offline patch injection pass on amd64 and arm64, and the 18-mutant audit was repeated from zero.

A wrapper and fairness review invalidated version 6. The test-only compile fallback appeared as a failed `new.compile-or-run` entity that could not belong to either the pass-to-pass or fail-to-pass census. Four no-write tests also forced `GetDeviceInfo` before errors that could legitimately be found from the snapshot or cached capabilities, and the standalone offline RMK build lacked the cached `display-interface` dependency.

Version 7 emits one skipped compile placeholder when no per-test JUnit exists, while keeping the test-only process status nonzero. The four preflight tests use a recording transport that accepts zero post-handshake reads or exactly the optional identity read and rejects every mutation. A legitimate local-first prototype and the identity-first reference both pass. The Docker build now fetches and builds the standalone RMK manifest as well. Fresh amd64 and arm64 builds, every patch state, the full native/WASM suites, and all 18 mutants were rerun from zero.

A paging-fairness and cache review invalidated version 7. Its nontrivial extent test required the exact overlapping keymap reads and packed keymap write produced by private `read_all_*` and `write_all_*` helpers. It also rejected a full-sized final macro request even though the firmware documents truncation past the advertised macro region. Separately, the offline `rmk-macro` build lacked its `macrotest` dependency.

Version 8 replaces exact page vectors with a stateful peer that validates exported values, final restored state, encoder and macro address coverage, and normalized resource order. A sequential keymap pager with one-key write pages and a padded final macro chunk both pass. An incomplete keymap restore and encoder-major restore still fail. The Docker build now fetches, builds, and records the `rmk-macro` graph as well. Fresh amd64 and arm64 builds, all patch states, both fairness prototypes, and all 18 revised mutants were rerun from zero.

A false-positive review invalidated version 8 because the first stateful peer flattened keymap coordinates before checking their individual bounds. On a two-layer, one-row, one-column keyboard, invalid `(layer=0,row=1,col=0)` aliased valid `(1,0,0)`. Version 9 added component-wise checks, but its first wrong-coordinate mutant still survived because the device returned the complete two-key map from the initial valid request, so the invalid continuation was never sent.

Version 10 advertises a one-key page in the same stateful fixture. This forces any complete export to address the second layer while still allowing any valid sequential or concurrent paging strategy and any gap-free write packing. The wrong-coordinate mutant now fails on the out-of-range row, while the sequential non-overlapping pager and padded final macro writer still pass. Both architecture patch matrices and all 19 exact-version mutants were rerun from zero.

A later fairness report invalidated version 10 because the extent test asserted the exact order of individual encoder writes. The prompt orders the exported encoder vector and restore resource families, but the public endpoint and firmware impose no order among independent encoder slots. The same report's failed `_with_exact_requests` identity came from a superseded version-3 wrapper result rather than the current package.

Version 11 removes encoder-write transcript recording and judges restore through bounded addresses, the Encoders resource phase, and final device state. A correct encoder-ID-major implementation passes. The old wrong-order mutant was artificial because it did not remap the layer-major snapshot index; it was replaced with an incomplete-encoder mutant that still fails. Fresh combined XML contains only the current `snapshot_uses_advertised_encoder_and_macro_extents` identity. Both architecture patch matrices, all three fairness variants, and all 19 exact-version mutants were rerun from zero.

The same review noted two minor reference-quality issues: the WASM client duplicated its driver-pump election for snapshot errors, and capability-fetch failures were labeled as device-identity reads. Version 12 extracts a generic internal pump helper with protocol and snapshot error adapters and adds the diagnostic `SnapshotRead::Capabilities` variant. The public behavior and hidden tests are unchanged. Both architecture patch matrices, all three fairness variants, and all 19 exact-version mutants were nevertheless rerun from zero because `solution.patch` changed.

A later verifier run invalidated version 12's harness before exercising any saved implementation. The hidden patch added a `wasm-bindgen-test` development dependency to `rynk-wasm/Cargo.toml` after image build, but the wrapper ran locked/offline Cargo metadata before the test runner could update `rynk/Cargo.lock`. All four reported zero-pass runs were therefore synthetic bootstrap failures. The same review found that collection-length validation sampled only a short keymap, the USB mismatch changed both identifiers together, and the public field lists read like an API dump.

Version 13 moves the runtime WASM probe into a randomized standalone crate with its own committed lock, leaves the workspace manifests pristine, and ends the Docker build with a matching Rynk lock. It checks short and long lengths for all six geometry-sized collections, isolates vendor-only and product-only mismatch sessions, and groups the description's field contracts compactly. Fresh arm64 and amd64 images pass the exact locked/offline metadata bootstrap.

Historical replay then invalidated version 13's tests. `Nova_Nova_3` used public single-item getters rather than whole-resource read helpers and exposed its WASM restore as `&[u8]`; the tests had assumed bulk reads and called the Rust method with `Vec<u8>`. Version 14 makes native stateful peers accept bounded single-item or bulk key/combo/Morse operations and calls restore through the actual JavaScript ABI with `Uint8Array`. All four saved implementations then pass.

A final legitimate single-item restore prototype found one remaining static `SetKeymapBulk` response in the fork-failure progress test. Version 15 replaces that script with a stateful peer that rejects the first fork write, checks the public completed ledger, and detects every later write phase while accepting either command family in earlier resources. The full cross-architecture patch matrix, four historical replays, three legitimate variants, and all 28 mutants were rerun from zero. No cold solver was run.

The next environment review found that standalone RMK and `rmk-macro` fetch/build commands did not use `--locked`, the temporary dependency-warming step used `cargo add`, and the exact offline `_simulator` test could not invoke `cargo expand`. Version 16 explicitly generates each missing lock, adds `--locked` to every later fetch/build, replaces `cargo add` with a temporary exact manifest append, and installs `cargo-expand` 1.0.124 with a locked install. Fresh arm64 and amd64 images pass the exact reported proc-macro command, every patch state, all saved implementations, all legitimate variants, and the complete 28-mutant audit. No cold solver was run.

A new four-trajectory review then showed that version 16 was too easy: three of four fresh implementations passed. Two successful patches validated combo trigger counts but ignored the public optional combo layer, while the tests sampled only one of ten structural geometry mismatches and exercised unknown versions chiefly through byte decoding. Version 17 makes the combo-layer boundary explicit, checks unknown in-memory records through validation and both restore entry points, and perturbs all ten structural fields independently. Exact replay reduces the fresh set to one complete pass; all three legitimate transport variants still pass, all 40 mutants are caught, and both architecture matrices remain clean. No cold solver was run.

All four `agent-runs3` implementations then passed version 17. Version 18 adds a
two-by-two row/column discriminator, the zero-space/zero-chunk positive case,
strict partial-final macro writes, two-slot combo/fork/Morse state, and an
actual restore to a compatible unit with different transport limits. The
reference passes the revised native and WASM lane on both architectures, and
all four saved implementations still pass because they already implement these
public behaviors correctly. The expanded false-positive run was stopped at the
user's request; this is a recorded verification gap, not a test or environment
failure. No cold solver was run.

All four `agent-runs4` implementations also passed version 18. A reviewer found
that write-failure reporting was injected only at Forks even though the public
contract exposes eight independent stage exits. Version 19 makes rejection
stage-based rather than command-based, so single-item and bulk implementations
remain valid, and runs the same black-box prefix/stop oracle at all eight
stages. The reference passes on arm64 and amd64, and all four saved solutions
still pass because their stage handling is correct. The user asked to skip the
new false-positive audit, so this remains a verification gap rather than an
approved revision. No cold solver was run.

All four `agent-runs5` implementations then passed version 19. Review found
that incompatible identity and geometry were still exercised directly only
through restore, and first-request failures did not prove that a partially
applied stage remained incomplete. Version 20 independently calls direct
preflight for each identity and geometry mismatch, and rejects the second
encoder, fork, and macro request. The reference passes 18/18 native tests plus
runtime WASM on both architectures; all four saved solutions remain green
because their behavior is correct. The false-positive audit was skipped at the
user's request, and no cold solver was run.

Those same four trajectories also showed that version 20 remained too easy:
every implementation followed the same unconditional full-restore pipeline.
Version 21 introduces a complete pre-mutation target baseline and stage-level
sparse restore. New tests require an identical restore to send no setters, a
mixed target to write only dirty resource families, a late baseline read
failure to remain no-write preflight, and completed progress to exclude equal
skipped stages. The reference passes 22/22 focused native tests and runtime
WASM on both architectures, plus 83/83 pre-existing workspace tests on arm64.
The user again requested that the false-positive audit be skipped. No cold
solver was run.

Version 22 resolves the description-length warning by reducing the public text
from 518 whitespace-counted words to 421. The edit preserves every public
requirement, and the test and solution artifacts remain byte-identical to
version 21. The prompt hash changed, so the skipped audit and 0/10 calibration
status restart on version 22. No cold solver was run.

Version 23 resolves three fairness findings. Combined command assertions now
separate the required export prefix, unordered complete restore baseline, and
ordered write-stage suffix. Encoder coordinates and macro offsets are checked
for complete coverage rather than an exact reference trace. The WASM peer
accepts either reuse or reread of preflight identity instead of requiring 11
requests. The two reported redundant description sentences were removed. The
reference remains green on both architectures; no cold solver was run.

All four `agent-runs6` implementations passed version 23 and shared one
architecture: compare whole baseline vectors and rewrite complete dirty
resources. Version 24 requires logical dirty-entry writes for keymaps,
encoders, combos, forks, and Morse definitions, plus dirty advertised macro
chunks. Its stateful peer records touched logical positions through either
single or bulk endpoints, so this does not force private page packing. It also
adds the reported successful malformed-baseline case, expands second-request
failure coverage to every multi-request stage, and verifies that retry does
not rewrite an entry already applied before failure. The reference passes
25/25 native tests and runtime WASM on both architectures, plus 83/83
regressions on arm64. The user asked to skip false-positive checks, historical
replays, and calibration; no cold solver was run.

A platform review of version 24 returned two fairness defects, one coverage
gap, and a difficulty overrun. The fairness defects were hidden-test bugs, not
contract problems: `snapshot_restore_of_identical_target_reads_complete_baseline_without_writes`
and `snapshot_restore_malformed_baseline_resource_sends_no_mutation` searched
the raw command log for `GetKeymapBulk`, `GetComboBulk`, and `GetMorseBulk`, so
an implementation that assembled the same complete baseline from per-entry
reads was failed for an endpoint choice the contract never constrained. Both
now map commands through `snapshot_phase` first, which is what the export and
write-order assertions had always done.

The coverage gap was that both graded lanes enable `std`, so an API gated on
`std` would satisfy an `alloc`-only requirement unnoticed. A plain
`--no-default-features --features alloc` build does not close it, because a
missing module still compiles. An example or integration test does not close it
either: rynk's dev-dependencies include crates that depend on rynk with default
features, and feature unification switches `std` back on, which was confirmed
by gating the module on `std` and watching an example target still build. The
lane therefore builds a dependency-free member crate outside the rynk workspace
that names every required public item. Gating both `mod snapshot;` and its
`pub use` on `std` makes that crate fail to resolve seven imports, and the
runner emits a failing JUnit case for it.

The difficulty overrun was 3 legitimate passes in 4 unhinted runs against a 50%
cap. Because the fourth failure was the false negative above, repairing it can
only raise the rate, so version 26 moves to Level 4. Compatibility now accepts
any target no smaller in every geometry dimension, which breaks the flat-index
correspondence every observed architecture relies on: keys and encoders are
addressed by coordinate, so a target with an extra column or encoder gives the
same coordinate a different index, and a run of dirty keys that is contiguous
in the snapshot is not contiguous on the target. Consecutive differing entries
must also travel in as few requests as the advertised page allows. Request
shape is recorded as `(first entry, entries)` for single setters and bulk pages
alike, so grouping is judged without prescribing an endpoint.

No raw version-24 trajectories reached the workspace, so the design gate cites
the reviewer's report as a secondary source and records the absence. The user
again asked to skip false-positive checks, historical replays, and calibration;
no cold solver was run. The reference passes 26/26 native tests, 1/1 runtime
WASM, and the `alloc`-only surface build on both architectures, plus 83/83
regressions on arm64.

A platform review of version 26 returned one classification defect and eight
unfair expectations, all in the tests rather than the contract.

The `alloc`-only surface check ran as a shell step that wrote its own
single-testcase JUnit and exited when the build failed. In the wrapper run
without `solution.patch` that emitted a hard failure for
`snapshot_surface_builds_with_alloc_without_std` while every other new test was
absent, because the test crate cannot compile without the snapshot API and the
runner falls back to a skipped compile placeholder. A test that exists only in
the failing run is neither pass-to-pass nor fail-to-pass. It is now an ordinary
test inside the graded set that shells out to the same build, so both runs treat
it like its peers.

The surface crate also annotated every call site with its exact `Result` type,
pinning an error-typing design the description never states. Visible client
methods return `RynkHostError`, so assigning `SnapshotError` to
`export_configuration` and `preflight_restore` was one reasonable choice among
several. Results are now discarded and the error types named separately, so the
crate asserts reachability without `std` and nothing more.

Seven rejecting-preflight tests drove a scripted link that answered the identity
read and then hung, so any additional read-only request timed out. The contract
guarantees only that a rejected preflight does not mutate; it never defines
preflight's read scope or ordering, nor whether the public `preflight_restore`
may read resources at all. All seven now run against the stateful peer, which
answers every read, and assert only that no recorded command maps to a write
stage. A mutant whose preflight exports the whole device before judging, and
whose restore reads the baseline before validating anything, fails version 26
and passes version 27; a mutant that sends one setter before validating still
fails eight tests, so the no-mutation oracle is intact. The four version-26
discriminator mutants were rerun and still fail exactly their recorded tests.

Two supporting changes came out of the rewrite. The peer answers a macro read
with `RynkError::Invalid` when the device advertises a zero chunk, because a
zero-length chunk cannot advance an offset and would stall a reader that got
that far rather than fail it. The six duplicated `StatefulSnapshotState`
literals collapse onto one `blank_target_state` constructor, which also supplies
the compatibility sweep with a self-consistent device at any advertised shape.

The reviewer's alternative, specifying exact preflight scope and method
signatures in the prompt, was declined: it would enlarge the description to
protect one arbitrary implementation choice, whereas relaxing the tests protects
every correct one. The description is unchanged.

`agent-runs7` brought the first raw trajectories since version 23: five Nova
runs against version 27, all failing, and every one of the five failures was
caused by the harness rather than by the implementation.

Runs 1, 2 and 3 each lost the same seven tests to a single panic, `keymap write
page exceeds the advertised page size`. All three had detected dirty runs
correctly and then handed each run to the repository's own `split_pages`, which
is what `write_all_keymap`, `write_all_combos` and `write_all_morses` use and
which sizes pages by `max_payload_size`. Checking the protocol settles it:
`get_keymap_bulk` documents "a page holds up to `max_bulk_keys` actions", while
`set_keymap_bulk`, `set_combo_bulk` and `set_morse_bulk` document no entry cap
at all, and `split_pages` says in its own comment that sizing by encoded size
"fits several times more per frame than the advertised count". The version-26
write cap was therefore invented, and `snapshot_caps()` advertising
`max_bulk_keys = 1` meant any two-entry dirty run tripped it. The cap and the
request-shape ledger are both gone; item sparsity survives because the peer
still records every logical entry a page touches.

Run 4 lost those seven plus five more by returning standalone `RestoreError`
variants such as `ProductMismatch` for pre-mutation rejections. Version 24 said
`RestoreError` "distinguishes `Preflight(SnapshotError)` from `Write`"; the
version-26 prose rewrite lost that framing and never said `Preflight` was the
only pre-write case. The description says so again.

Run 5 never compiled. It declared `Preflight { source }` while the tests
destructured `Preflight(_)`, giving three `E0164` errors that stopped the whole
suite, so none of the 27 tests ran. The description prescribes field names for
`Write` and deliberately not for `Preflight`, so the tests now match
`Preflight { .. }`, which accepts both shapes.

Dropping the page cap exposed a second, subtler false negative. The
partial-failure and retry families reject the second request of a stage, but
with packing unconstrained a stage can legitimately need only one request, so
the injected failure never fired and the restore simply succeeded. Every
multi-request stage now has three slots with the middle one already matching:
two dirty entries separated by an equal entry cannot share a request, so a
second request exists for any correct implementation.

Replaying all five patches against the repaired tests gives 4/5, up from 0/5,
with run 4 failing only on the error mapping the description now states. The
task is consequently expected to sit near 100%, far above the cap, and needs a
new lever before it is worth a calibration batch. That is a genuine cost of the
repair and is recorded rather than hidden: the page cap was the only thing
standing between four of these five implementations and a pass, and it was not
a legitimate requirement.

A package review of version 28 scored Comprehensiveness 1/3 and Code Quality
2/3, both against the reference solution and the runner rather than the
participant contract.

The comprehensiveness score turned on a single signal: the merged JUnit
reported an expected new testcase as missing. The cause was structural. The new
lane ran nextest and then, as a second shell command, the WASM round trip. Only
nextest writes JUnit, so the WASM result existed nowhere but the runner's exit
status and the report carried 27 cases where 28 were expected. This is exactly
the defect version 27 fixed for the `alloc` surface check, left in place on the
other lane. The WASM run is now `snapshot_wasm_client_round_trips_under_node`, a
graded test that shells out to `cargo test --target wasm32-unknown-unknown`
with the wasm-bindgen runner, and the lane is a single nextest invocation
producing a single report of 28. Breaking `restore_configuration_snapshot`
makes precisely that case fail and the runner exit non-zero, so it is a gate
rather than a formality.

The code-quality findings were all fair and all accepted. The reference carried
its own `group_dirty_runs`, grouping by adjacency and advertised item count,
beside the payload-aware `split_pages` that `write_all_keymap` and its siblings
already use. `split_pages` is now `pub(crate)`, the snapshot module only detects
runs of adjacent dirty addresses, and each run is handed to that pager. The
advertised item count has left the reference entirely, which is also what the
three `agent-runs7` implementations did and which follows the version-28 finding
that the count is documented for reads only. `export_configuration` also
rejected devices without bulk transfer even though the prompt puts that
requirement on restore; the check split into `validate_macro_chunk`, which
guards the export read loop because a zero chunk cannot advance an offset, and
`validate_transfer_capabilities`, which keeps the bulk requirement and is
reached only from the restore-side `validate_target`. Finally `restore_configuration`
re-read capabilities and identity it already held, so the export body moved into
`export_with(caps, info)` and restore passes what it read for its compatibility
check.

Replaying the five `agent-runs7` implementations against version 29 gives 4/5,
unchanged from version 28, confirming that none of this touched difficulty.

Two further findings, one a warning about the runner and one a high-severity
note about the description.

The nested WASM round trip shells out to `cargo test --target
wasm32-unknown-unknown` with the wasm-bindgen runner under Node, offline, on a
pinned toolchain, and nothing in the test proved any of that existed. The image
does provision it all, verified directly rather than assumed: `node v24.15.0` at
`/usr/bin/node`, `wasm-bindgen-test-runner` in `/opt/cargo/bin`, and a
`wasm32-unknown-unknown` libdir under the 1.95.0 toolchain. Even so, a test that
assumes its host's tooling fails a solution for something the solution did not
do, so `missing_wasm_tooling` now probes the target and both binaries and stands
down with a message when any is absent. It inspects availability only and never
the round trip's outcome, so it cannot hide a real failure. Four conditions were
checked: the image as shipped runs the round trip in 28 seconds with no skip
message; with the WASM wrapper broken the case fails and the runner exits 100;
with the runner and Node removed from `PATH` the suite passes in 2 seconds
having stood down; and on a host without the runner it reports
"wasm-bindgen-test-runner is not on PATH".

The description claimed "`RestoreError` has exactly two cases", which no test
checks. What the tests check is that a rejection before the first write arrives
as `Preflight`, which is precisely what `agent-runs7`'s run 4 got wrong by
returning a standalone `ProductMismatch`. The exclusivity sentence is removed
and the mapping requirement kept, so an implementation may carry any number of
extra variants provided pre-write rejections use `Preflight`. Both clauses are
now spelled with their full paths, `RestoreError::Preflight` and
`RestoreError::Write { completed, stage, source }`.

Replaying the five `agent-runs7` implementations against version 30 gives 4/5,
unchanged since version 28.

Two more findings, one sound and one resting on a false premise.

The description mandated postcard. The contract only needs deterministic bytes,
full consumption and version rejection, so the mandate is gone and the encoding
is now the implementer's choice. Removing it alone would have been unfair,
because `snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` built its
unknown-version input with `postcard::to_allocvec`: `to_bytes` validates, so a
solution's own encoder cannot emit an unknown version. The check now asserts
that `validate` rejects the version and that `to_bytes` refuses to emit it,
reaching the same guarantee without naming a format. No test assumes anything
about the snapshot encoding now; the remaining `postcard` calls in the suite
decode wire frames, which is the pinned protocol.

The second finding, that nine tests force `Preflight` to be a struct variant by
matching `Preflight { .. }`, is incorrect. `Enum::Variant { .. }` is Rust's
struct-pattern form and the language applies it to tuple variants too, whose
fields are the positional names `0`, `1`, and so on, so a single arm accepts
`Preflight(SnapshotError)` and `Preflight { source }` alike. The history makes
this concrete rather than theoretical: these sites read `Preflight(_)` until
version 27, that form genuinely does reject a struct variant, and it is exactly
what stopped `agent-runs7`'s run 5 from compiling. Run 5 declares
`Preflight { source }` and now passes 66/66 on replay.

The behaviour is therefore unchanged, but the confusion has now arrived twice
from opposite directions, so the code carries the answer instead of a document.
All nine sites route through `rejected_before_writing`, whose doc comment
explains the pattern, and the graded test
`snapshot_preflight_pattern_matches_either_variant_shape` declares a tuple-shaped
and a struct-shaped enum locally and asserts the shared pattern accepts each.
Were the claim ever false, that test fails rather than a solution.

Replaying the five `agent-runs7` implementations against version 31 gives 4/5,
unchanged since version 28.

`agent-runs8` is the first batch that both compiles and passes: 4/5 against
version 31, the single failure a `step_by(0)` panic on the zero-macro edge. At
80% against a 50% cap the task needed hardening, and for the first time there
were five complete legitimate implementations to choose a lever from rather
than a guess.

All five share one architecture, and the review pointed at its seam by filing
the same defect against the reference. `split_pages` returns
`RynkHostError::Encode` for an item that cannot fit the target's frame, and
`send_frame` rejects an oversized request locally before it reaches the link,
as the repository's own `oversized_request_rejected_locally` demonstrates.
Neither verdict needs a device. A restore that streams stage by stage therefore
writes the earlier stages, then trips over a later one it could have ruled out
at the start, leaving the device changed and reporting `Write`. The reference
did this too.

The rule was not stated, so stating it came first: every request restore will
issue must be encodable within the target's advertised frame, and the host has
to establish that before sending anything. The reference now plans all keymap,
combo and Morse pages before the first write and reports a shortfall as
`SnapshotError::UnencodableWrite` inside `Preflight`. The oracle needed no new
machinery, only measured sizes: for `multi_stage_snapshot_fixture` a keymap page
is 6 bytes, an encoder write 5, a combo page 9, and every read 3, so a target
advertising `max_payload_size = 8` admits reads, keymap and encoders but can
never carry a combo write.

Replaying both saved batches with each solver's own tests excluded takes
`agent-runs8` from 4/5 to 1/5 and leaves `agent-runs7` at 0/5. Every failure is
the new check, plus the pre-existing faults of two runs, so nothing else
regressed. `agent-runs8`'s run 2 passes everything without having been told the
rule, which is the existence proof the Solvable gate needs.

1/10 is a floor and not a forecast, because all ten implementations predate the
sentence that states the rule. The true rate lies between that and the 80% the
batch measured, and only a fresh probe can narrow it.

Two coverage findings were also accepted. The surface crate exercised methods
without demanding serde, so a hand-rolled encoder would have satisfied it; it now
asserts `Serialize + DeserializeOwned` through a bound that names no format, and
removing the derives makes it fail. And `to_bytes` had only been shown to refuse
an unknown version, so an encoder checking the version alone would pass; it must
now refuse a short keymap, an out-of-range default layer, an out-of-range combo
layer and an oversized Morse map as well.

Eight findings against version 32, in three classes, all accepted. None touched
the planning lever, and re-replaying both batches afterwards gave the same
1/10, so the relaxations removed coupling without blunting anything.

Five concerned request order inside a stage. The suite compared `key_writes`,
`encoder_writes`, `combo_writes`, `fork_writes`, `morse_writes` and
`macro_writes` as ordered sequences, which pins ascending order within a stage
when only stage order is stated. The repository argues the other way: `write_all`
splits a resource into pages and keeps up to `MAX_IN_FLIGHT` of them in flight,
so serial ascending order is a scheduling choice rather than observable
behaviour, and writes inside a stage address disjoint entries anyway. All twenty
comparisons now route through `touched`, which sorts before comparing. Entries,
coordinates, chunk bytes and the exactly-once retry guarantee are unchanged.

One concerned the serde bound. The task requires serde of
`ConfigurationSnapshot`, and a manual implementation need not make
`SnapshotGeometry` independently serializable, so that bound is dropped. The
`ConfigurationSnapshot` bound stays and is still verified to fail when its
derives are removed.

Two rested on an unsupported-version predicate, and that one is a regression of
mine. Version 31 removed the postcard sentence, which had carried "reject
unknown versions", and the replacement never restated it, so
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` and
`snapshot_in_memory_validation_failures_send_no_mutating_request` were resting
on a rule the description no longer contained. Validation now explicitly rejects
any version other than `SNAPSHOT_VERSION`. The fix restores the contract those
tests were always written against rather than weakening them, which is the right
direction: the behaviour is desirable and the omission was accidental.

The description is 496 words, back under the 500-word target.

Two findings against version 33, both accepted.

`assert_restore_write_failure` required the failed stage to have sent exactly
`failed_request_index` requests. Only "no later stage is attempted" is stated,
and the repository argues against the stricter reading: `write_all` builds
`MAX_IN_FLIGHT` lanes and joins them, so an implementation may legitimately have
a second disjoint page in flight when the first rejection arrives. The check now
asserts that the rejected request was reached and that every recorded write
belongs to the failed stage or an earlier one, which is the stated rule and
nothing more. It stays sharp: hoisting the default-layer write ahead of the
keymap fails it with "Keymap failure did not stop later stages:
[DefaultLayer, Keymap]".

The description's "One request may cover a run of consecutive differing entries,
as many as you like" was optional guidance rather than a requirement, once
within-stage packing and order were both unconstrained, so it is gone. 481 words.

Both batches replay unchanged at 1/10.

A Harbor oracle run also failed with `EnvironmentStartTimeoutError`. Nothing in
the artifacts explains it, and the same submission classified cleanly: 83
pass-to-pass entries matching `./test.sh base` exactly, and 30 fail-to-pass
matching the new lane exactly. The five `rynk::api.tests` entries in that list
exist at the pinned commit and are added by neither patch. The environment
therefore built and ran, and the timeout came from a separate start step.

Image size is the only factor under our control, and it is large: about 12.2 GB,
of which 5.3 GB is Cargo target directories and 1.7 GB of that is incremental
cache a fresh container cannot use. The registry cache that actually makes the
offline lanes work is 1.3 GB. Deleting all three target directories and running
the base lane cold recompiles 272 crates in 27 seconds, so the build cache buys
very little. Discarding it in the layer that creates it would take the image to
roughly 7 GB. That rewrites the Dockerfile and needs a networked rebuild with
full re-verification on both architectures, so it is recorded rather than done.

Four findings against version 34, in two classes, both accepted.

Three concerned `Option<SnapshotRead>`. The task requires an item by that name
to exist and says nothing about its shape, but a type expression additionally
demands the item be nongeneric and lifetime-free, so a generic or
lifetime-parameterised `SnapshotRead` would have failed to compile. The surface
crate's own comment claimed to be shape-free while doing exactly this. All three
sites now name the item by import under `#[allow(unused_imports)]`, which
asserts that the name is exported and reachable and nothing else;
`RestoreStage`, `SnapshotError` and `RestoreError` moved with it, although only
`SnapshotRead` was reported. The weaker form still gates: with the module and
its re-exports on `std`, the surface crate fails with unresolved imports for all
seven items, and the serde bound still fails when the derives go. The native
suite keeps `RestoreStage::Keymap` and friends, which the task states by name.

The fourth concerned argument ownership: the surface crate called both restore
methods with `&ConfigurationSnapshot` while the task said nothing about it, and
neighbouring APIs commonly take composite arguments by value. This one cannot be
relaxed away, because the retry test calls `restore_configuration` twice with
the same snapshot, so the suite depends on borrowing regardless of what the
surface crate does. The description now states that the two restore methods
borrow the snapshot, and gives the reason. Naming a signature detail the
contract genuinely rests on is the right trade against a false negative.

Both batches replay at an unchanged 1/10.

A package review scored Comprehensiveness 1/3 and Code Quality 2/3 on two
implementation gaps. Both were real, both in the reference, and the contract did
not change.

Export required bulk transfer. Version 29 had removed the bulk precheck from
`export_configuration`, but the body still read the keymap, combos and Morse
definitions through `read_all_keymap`, `read_all_combos` and `read_all_morses`,
which call `get_*_bulk` and are gated on `bulk_transfer_supported`. Removing the
precheck changed nothing except when and how a non-bulk device failed. The task
makes whole-resource bulk a restore precondition only, so export now uses the
crate's pagers when bulk is advertised and `get_key`, `get_combo` and
`get_morse` per entry when it is not.

Only the paged writes were preflighted. `plan_pages` covered keymap, combo and
Morse pages, while `set_encoder`, `set_fork`, `set_macro`, `set_behavior` and
`set_default_layer` went unmeasured, even though `send_frame` enforces
`max_payload_size` for every request. A frame too small for a fork write would
have surfaced mid-restore with earlier stages already applied, which is exactly
what the stated rule forbids. Every diff is now computed before planning, and
every single-entry request is measured with `fits_frame` against the same budget
`split_pages` uses. The planning test gained a second budget to prove it: with
`multi_stage_snapshot_fixture` sizes of keymap page 6, encoder 5, Morse page 7,
combo page 9 and fork 15, a budget of 8 stops a paged stage and 12 stops the
single-entry fork write.

One test was written and then deliberately withdrawn. A non-bulk export test
passes against the fixed reference but fails all ten saved implementations,
including `agent-runs8`'s run 2, the only one that passes everything else and
therefore the sole existence proof for the Solvable gate. Replay went 1/10 to
0/10 with it and back to 1/10 without. The review's finding was against the
implementation and the implementation now honours the contract, so the gap is
closed either way; adding a second lever that no observed implementation
survives is a separate decision and not one to take without measurement. The
test is recorded in `DESIGN.md` as the first coverage to restore if a probe
batch comes back too easy.

`agent-runs9` brought eleven runs against version 36. One aborted with no
results; of the ten that completed, eight passed, so version 36 measured 80%
against a 50% cap.

Both failures were genuine, and one corrected an earlier reading of mine. The
`snapshot_surface_builds_with_alloc_without_std` failures open with "Blocking
waiting for file lock on package cache" followed by a long cold compile, which
looks like nested-Cargo contention. The real error is further down the log:
`error[E0425]: cannot find type Box in this scope`, from a
`TargetInvalid(Box<SnapshotError>)` variant declared without importing
`alloc::boxed::Box`. Those implementations do not build with `alloc` on and
`std` off, which is exactly what the check exists to catch. The lock lines are
noise. `Nova_Nova_11` separately wrote a final macro chunk a byte past the
snapshot's region.

The non-bulk export test withheld in version 36 is restored, after a review
flagged its absence as a HIGH false-positive risk. That settles the trade-off
the version-36 note recorded: a submission unable to export from a non-bulk
device would otherwise pass unnoticed. The asymmetry is now stated as well as
tested. Measured against the ten completed implementations it costs two runs,
taking 8/10 to 6/10, and both failures are real: those implementations reach for
the crate's pagers, which are gated on the capability.

Two further candidate levers were tried against the same ten and neither caught
anyone: resources the device does not have at all, and macro regions smaller
than one chunk or absent entirely. Both are kept as regression coverage, since
each guards a class that has failed a run before, but neither discriminates for
this population. Recording the negative result matters as much as the positive
one: extent edge cases are not where this population is weak.

Every check that does discriminate has the same shape. The crate's convenience
helper does not cover this configuration, so a fallback has to be written.
`alloc` without `std` caught two runs, export without bulk caught two, and
extent handling caught none. The unmined member of that family is restore
without bulk transfer, which the contract currently forbids rather than
requires. At 6/10 the task is still above the cap and needs that or an
equivalent, which is a contract change rather than another test.

Six runtime tests compare whole `ConfigurationSnapshot` values with
`assert_eq!`, which silently requires `PartialEq` and `Debug`. The description
named only serde's `Serialize` and `Deserialize`, and the pinned repository has
no `ConfigurationSnapshot` to establish anything more, so a solution could
satisfy every stated behaviour and still fail to compile the suite.

Of the two offered remedies, amending the description is the better one.
Rewriting six tests to compare field by field is markedly more verbose and
throws away what whole-value equality buys: a field added to the record but
forgotten in an assertion silently stops being checked, whereas an `assert_eq!`
on the whole snapshot cannot miss one. `Debug` and `PartialEq` are also the
conventional derives for a value type of this shape, so requiring them costs a
solver a word in a derive list. Only those two are named, not `Eq`, because
`assert_eq!` needs no more.

Both patches are byte-for-byte identical to version 37, which verified that
exact pair at 33/33 on both architectures, so the container run was not
repeated; a run is deterministic given the same image and the same two patches.
The reference was re-run locally and is green. The description is 497 words.

`agent-runs10` scored 5 of 10 against version 38, exactly the cap, but one of
the five failures was mine and the number does not survive fixing it.

`Nova_Nova_3` returned `js_sys::Uint8Array` from
`export_configuration_snapshot`. The hidden WASM test called that Rust method
directly and used the result as a `Vec<u8>`, so the test crate would not
compile. wasm-bindgen surfaces a Rust `Vec<u8>` and a `Uint8Array` as the same
JavaScript typed array, so both give a browser the identical byte-oriented API
the task asks for, and the repository supports both readings: the WASM transport
uses `Uint8Array`, the typed client methods use `Vec`. The platform classified
it `FAIL_TEST_MISMATCH`, not inferable from the description or the codebase, and
that is right.

The restore half of the test was already immune because it goes through
`Reflect` and a JS `Function`; only export called into Rust. Export now does the
same, resolving the promise and reading a `Uint8Array` before converting to
bytes. Verified three ways in the image: the `Vec<u8>` reference passes, a
wrapper edited to return `Uint8Array` passes, and a wrapper whose restore method
returns an error still fails.

Replaying `Nova_Nova_3` against the repaired suite gives 36 of 36. Version 38's
true rate was therefore 6/10, and version 39 measures 6/10 on the same batch.

The other four failures are the discriminators working as intended.
`Nova_Nova_2` and `Nova_Nova_7` do not build with `alloc` on and `std` off,
missing `ToString` and `vec!` imports. `Nova_Nova_8` uses the source encoder
stride against a larger target and writes an encoder the snapshot never
described. `Nova_Nova_9` writes an extra macro byte on a larger target.

Two batches now agree on 60% across twenty runs, against a 50% cap.

Two batches having agreed on 60%, version 40 takes the one principled lever
left and records why testing cannot reach much further.

Restore no longer requires whole-resource bulk transfer. Neither direction does:
where a device does not advertise it, both read and write one entry at a time,
which the protocol supports through `set_key`, `set_combo` and `set_morse`. The
old unsupported-bulk rejection test is replaced by one that requires a complete
sparse restore over per-entry setters with no bulk command used, and the
reference branches both its planning and its writes on the capability, with the
frame check covering per-entry requests too.

All twenty saved implementations fail that test, and that number means nothing:
they predate the rule. The informative comparison is the export precedent. Two
of ten missed export-without-bulk when the description did not state the
asymmetry; none of ten missed it once it did. A stated rule of this shape gets
satisfied, so the honest expectation for this lever is small.

Three probes were written, measured and kept only for regression value, because
each caught nobody: resources the device does not have at all; a macro region
smaller than one chunk and absent entirely; and each geometry dimension grown on
its own so no stride can hide behind another. The last was aimed at exactly the
class that failed `agent-runs10`'s `Nova_Nova_8`, an encoder written at the
source stride, and the six implementations that pass everything else handle
every variant.

The conclusion is that difficulty here does not respond to more tests. Two
things discriminate across every batch and both already exist: the
`alloc`-without-`std` surface check, two of ten in `agent-runs9` and two of ten
in `agent-runs10`, and geometry or extent precision at one or two of ten.
Neither is learned away between batches because both are slips rather than
missed requirements.

The one unpulled lever with evidence behind it is to build the surface crate for
a real bare-metal target rather than the host, strengthening the most reliable
discriminator in the record. That needs `rustup target add thumbv7em-none-eabihf`
in the Dockerfile and a rebuild, which is also the measured fix for the Harbor
`EnvironmentStartTimeoutError`: discarding the Cargo target directories in the
layer that builds them takes the image from about 12.2 GB to roughly 7 GB for
about 27 seconds per lane. One rebuild serves both.

`agent-runs11` returned 5 passes in 5 runs against version 40. Nothing
discriminated: not the `alloc`-without-`std` surface, not geometry precision,
not the per-entry restore added in version 40. The task was saturated, and
version 40's own gate had already established why more prose would not help,
since a rule that is merely stated gets satisfied by everyone.

The lever came from the types instead. `rmk-types` gives `KeyAction` a
hand-written `PartialEq` with a comment explaining the intent: the morse-profile
index in `TapHold(Action, Action, u8)` is per-key timing config, not part of the
key's identity, so equality ignores it. Serde still serializes it. Measured
directly, `TapHold(User(3), No, 0)` and `TapHold(User(3), No, 7)` compare equal
and encode to `[4, 19, 3, 0, 0]` and `[4, 19, 3, 0, 7]`.

The description has demanded equal bytes for equal snapshots since version 1,
but it illustrated the demand with `Morse.actions` insertion order, and every
implementation canonicalized precisely that one case because it was the one
named. The clause now states the rule in general and marks the Morse map as an
instance rather than the whole, so the rest is found the way the Morse case was:
by reading the types being serialized. The reference normalizes the ignored
index across keymap, encoders, combos and forks.

All five implementations fail
`snapshot_canonicalizes_actions_equality_treats_as_the_same`. It is the first
lever in this problem's history to catch an entire batch that passed everything
else, and it belongs to the class that has not been learned away between
batches, the same class as the `alloc`-without-`std` check: a slip rather than a
missed requirement.

Two hidden setup lines imposed traits the task never names, and a third of the
same shape was found by grepping rather than reported.

`snapshot_canonicalizes_actions_equality_treats_as_the_same` built its second
fixture with `first.clone()`, requiring `ConfigurationSnapshot: Clone`. The task
names only `Serialize`, `Deserialize`, `Debug` and `PartialEq`, and since both
restore methods borrow, no caller ever needs to clone. The fixture is now built
independently.

`grown_target_state` and `snapshot_restore_maps_each_grown_dimension_independently`
moved `snapshot.geometry` out of a borrowed snapshot, requiring
`SnapshotGeometry: Copy`. The third site was
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions`, whose mutator
table was typed `fn(&mut ConfigurationSnapshot, SnapshotGeometry)` and so took
the geometry by value. All three borrow now, and the table takes a reference.

The fix was verified rather than assumed. Stripping `Clone` from
`ConfigurationSnapshot` and `Copy` and `Clone` from `SnapshotGeometry` in the
reference produces fifteen compile errors, every one inside
`rynk/src/snapshot.rs`, which uses both internally as its own implementation
choice, and none inside `rynk/src/driver/tests.rs`. The hidden suite therefore
imposes neither trait.

Behaviour is unchanged and the version-41 lever is intact: all five
`agent-runs11` implementations still fail
`snapshot_canonicalizes_actions_equality_treats_as_the_same`.

A review reported the task passing: no critical fixes, no failures, no
uncertains, and a 30% pass rate, inside the 50% cap and near the p ~= 0.28
target. Two notes were actionable.

The canonicalization test varied the ignored `TapHold` profile index only in the
keymap and encoders, so a canonicalizer that knew about those two tables and
nothing else would pass. The requirement is over the record: `Combo` nests key
actions in `actions` and `output`, and `Fork` nests them in its trigger and both
outputs. The test now varies the index in all four places. The reference already
normalized them, so only the test moved, and deleting the combo and fork
normalization from the reference now fails the test, which is the check that the
loophole is closed.

The density note is answered by reorganization rather than condensing. The three
longest paragraphs each carried two subjects, the codec methods with the
determinism rule, geometry sizing with the capability requirements, and the
preflight guarantee with the plan-ahead rule, and each is split at that seam.
Diffing both versions with whitespace collapsed confirms the text is
word-for-word identical; only paragraph breaks changed. The longest paragraph
falls from 56 words to 42 and the count rises from 16 to 19, still 501 words.
Condensing was avoided deliberately: version 31 lost the unsupported-version
rule to exactly that kind of edit.

The third note, that a 70% failure rate overstates core difficulty because most
failing agents completed the feature and missed one narrow edge case, is
advisory and no change follows from it. That concentration is the intended
design. Versions 37 through 40 established by measurement that broad
architectural requirements are satisfied once stated, and that the only checks
surviving a batch are those catching slips rather than missed requirements, so a
rate carried by subtle stated invariants is what the evidence predicts.

`agent-runs12` ran ten times against version 43 and returned three passes, a 30%
rate inside the 50% cap and close to the p ~= 0.28 target. Every failure is a
real implementation defect: six could not encode protocol-equal snapshots
identically when the ignored `TapHold` profile index differed, one sent a larger
target's final macro chunk as `[5, 238]` where the short `[5]` was required, and
one panicked in `step_by(0)` on a zero-sized macro region, natively and again
inside the WASM runtime. The version-41 lever accounts for six of the seven.

`Nova_Nova_8`'s WASM failure was checked rather than assumed, because its log
opens exactly like a harness fault: three "Blocking waiting for file lock on
package cache" lines, one on the artifact directory, then a cold compile. The
cause is further down, a `StepBy::new` panic, the same zero-chunk defect that
failed its native test.

The contention behind those lines is real even though it caused no false
negative. `snapshot_surface_builds_with_alloc_without_std` and
`snapshot_wasm_client_round_trips_under_node` both shell out to Cargo against the
same standalone workspace, so nextest running them together made each wait on
the other's locks, and that build took 3m36s. Each nested build now gets its own
`CARGO_TARGET_DIR`, which costs little because they target different
architectures, and a nextest test group caps the pair at one thread. Measured in
the image afterwards: zero blocking lines and a 33-second lane. Behaviour is
untouched, so difficulty is unaffected and `meta.md` and `solution.patch` did not
change.

The WASM runtime test did not establish that `restore_configuration_snapshot`
decoded or applied its byte argument, and the hole was wider than the report
reads. The test passed the board's own exported bytes back, awaited success, and
then checked only that the scripted responses were consumed and that at least
ten requests had been sent. Both are already true after the export half.
Restoring a board's own configuration also asks for no writes, because nothing
differs. A wrapper that ignored `bytes` and returned `Ok(())` passed.

Decoding is now proved by requiring three junk bytes to be rejected. Applying is
proved separately, because decoding alone is not enough: the test decodes the
exported record, changes one key action to `KeyAction::Morse(7)`, re-encodes,
asserts the bytes differ, and restores that. The board still holds
`KeyAction::No`, so satisfying the call requires decoding those bytes and writing
what they say. A `snapshotSentFrame` helper lets the test assert that a write
carrying that exact action was sent, accepting `SetKeyAction` or
`SetKeymapBulk`, with alternatives answering both. A wrapper rewritten to ignore
`bytes` and restore whatever it had just exported now fails.

One process note. The first attempt failed against the reference for a reason
that was not a reference defect: the edit registering the write alternatives ran
without asserting its anchor matched, the anchor was wrong, and the alternatives
were silently never added while everything still compiled. The frames the link
received were byte-identical to what the test expected, which is exactly what
made it look like the reference was at fault. Every scripted edit to these files
should assert its anchor.

The contract did not change, so difficulty is unaffected: the task already
required these methods to be byte-oriented and only the check caught up.

`agent-runs13` returned 3 passes in 10 against version 45, matching the previous
batch, with seven failures on the canonicalization lever. One of the three passes
was a false positive, and the report is right.

`Nova_Nova_10` preflights with `check_restore_requests`, which walks the entire
record before comparing anything, iterating `for action in &snapshot.keymap` and
the equivalent for every other table and sizing each `Set*Request` against
`max_payload_size`. A board that already holds an entry too large to write in one
frame is therefore rejected, when the contract requires that restore to succeed
writing nothing: an entry that already matches is never sent, restore writes only
what differs, and the frame-fit rule is scoped to the requests a restore needs.
An entry that already matches is not one of them.

The suite covered both halves and never their intersection.
`snapshot_restore_plans_every_write_before_touching_the_device` uses a frame that
cannot carry a fork write, but against a dirty board.
`snapshot_restore_of_identical_target_reads_complete_baseline_without_writes`
uses an identical board, but a generous frame. Nothing paired them, so sizing
before diffing looked correct.

`snapshot_restore_skips_entries_too_large_to_write_when_they_already_match` is
that pairing: the same `max_payload_size = 12` that stops a fork write, against a
board that already holds the snapshot, with both `preflight_restore` and
`restore_configuration` required to succeed and no write permitted. The reference
passes because it computes every diff before it plans or measures anything.

The repair is targeted rather than blunt. Replaying the three passes leaves
`Nova_Nova_1` and `Nova_Nova_3` passing and fails `Nova_Nova_10` on this test
alone, so the batch reads 2 of 10, above the Solvable floor and inside the cap.

The lesson worth carrying is that two rules which each have a test can still
admit a wrong implementation where they meet. Frame-fit and diff-before-write
were both covered; the defect lived exactly between them.

Two findings, both accepted.

The late-baseline-read rule covers every pre-write rejection whatever the cause,
but only one cause was tested: a device saying no, through `reject_read` and
`RynkError::Invalid`. A reply the client cannot decode is a different branch and
could regress unnoticed. The peer gains `corrupt_read`, which answers a named
command with a well-formed frame whose payload is the wrong shape, and the test
now runs both sources.

Reviewing that test exposed a weakness the report did not raise. It built its
board with `matching_restore_state`, so the board already held the snapshot and
nothing would have been written even by an implementation that ignored the
failed read completely. Its no-mutation assertion could not fail. It now uses
`dirty_restore_state`, where every resource differs and pressing on would leave a
mark, and both failure sources are checked against that board. Rewriting the
reference to report a baseline failure as `Write` rather than `Preflight` fails
this test and the malformed-baseline test and nothing else.

The last four inline `StatefulSnapshotState` literals were collapsed onto
`blank_target_state` in the same pass, because adding a field to the peer
otherwise meant editing five places and the compiler found them one at a time.

The description loses "the rest the protocol's own types". That phrase was the
only thing pinning the table element types, so it was weighed rather than waved
through: the surrounding text names every field, export reads those tables
through `get_key`, `get_combo` and `get_morse`, whose return types are
`KeyAction`, `Combo` and `Morse`, and no run across thirteen batches has chosen
anything else. 496 words.

Three findings. Two were coverage gaps and are closed; the third contradicts an
earlier accepted finding and was answered by removing the requirement rather
than the sentence.

The WASM runtime test proved its byte argument was decoded, by rejecting junk,
and applied, by requiring the write it asks for, but never gave the wrapper valid
bytes whose native restore fails. A wrapper that awaited the native call,
discarded its error and resolved successfully passed. The test now decodes the
exported record, renames the product to a board this device is not, re-encodes
and requires the promise to reject; decoding succeeds there, so only propagation
can produce that rejection. A wrapper rewritten to `let _ = ...; Ok(())` fails.

Export was never made to fail. Every case had a cooperative device, so an
implementation that hid a read failure and returned a record with a defaulted
field passed, and such a record encodes and validates cleanly and would later be
restored onto a board as though the device had reported it.
`snapshot_export_fails_on_a_late_bad_read` rejects and then corrupts the
behaviour read, the last one export makes, and requires an error either way. A
reference rewritten to substitute a zeroed `BehaviorConfig` fails it, and fails
the late-baseline test alongside it.

The third finding calls "plus `Debug` and `PartialEq`" checklist filler, but
version 38 added those words because six tests compared whole snapshots with
`assert_eq!` and silently required both, which a previous review called an unfair
compile-time condition. Deleting them would restore that defect. The requirement
was reduced instead: `assert_eq!` needs `Debug` only to format a failure, so the
six sites now use `assert!(a == b, "message")`, which needs only `PartialEq` and
keeps the whole-record comparison that stops a newly added field escaping
notice. The description asks for `PartialEq` alone. Both reviews are satisfied
without trading a fairness defect for a readability one.

Both findings are valid.

Retry coverage walked the six multi-request stages, and in every one of them the
first attempt fails before behaviour is reached, so behaviour was only ever
written on the retry. The ordering that matters most was never exercised:
behaviour applied, then the default-layer write refused, then a second attempt.
That is the case where the entire configuration has already landed and only the
final write is missing, so an implementation reusing the first attempt's diff
rather than reading the board again resends everything, against the rule that a
matching entry is never sent.
`snapshot_restore_retry_after_a_default_layer_failure_rewrites_nothing_else`
covers it: the first attempt completes the seven earlier stages and is refused at
`DefaultLayer`, the second must write the default layer and nothing else, and
every per-entry ledger must hold each entry once across both attempts, with
`SetBehaviorConfig` exactly once and `SetDefaultLayer` twice.

The gap was found by inspection, not mutation, and the record says so. A
reference mutated to write behaviour unconditionally does fail the new test, but
it also fails four others, so that mutant does not demonstrate the new case is
uniquely needed. What demonstrates it is that no version-48 test drove a
default-layer failure followed by a retry at all. The ordering was missing, not
the assertion.

The equality clause loses "including but not limited to". That phrasing was
chosen in version 41 to warn that the Morse map is not the only case without
naming the others, which is what keeps the canonicalization lever discoverable
instead of handed over. The warning is worth keeping and the legalese is not, so
it now reads that the Morse map "is one such case, and not the only one".

## Version 50: three demonstrated gaps, one found alongside, and a regression

An audit showed three broken implementations passing all 38 version-49 tests.
Each is a real hole and each is closed and mutant-verified.

A `from_bytes` that decoded a record and returned it without validating passed
everything, because invalidity was only ever driven through `validate` and
`to_bytes`, and `ConfigurationSnapshot` is publicly serde-serializable, so a
record can reach the decoder without passing through either. The new probe
builds an unsupported-version record and a short-keymap record with raw postcard
and requires both rejected.

The probe asserts rejection only, and that one-sidedness is the whole reason it
is fair. Any solution rejects those bytes: one that cannot read postcard treats
them as garbage, one that can must validate. The same review contained a judge
dispute over a stronger probe that required raw bytes to decode and preserve a
field, which pins the wire format the task explicitly leaves to the solver.
Rejection probes are format-free; acceptance probes are not.

Narrowing `SNAPSHOT_VERSION`, `ConfigurationSnapshot.version` and the
unsupported-version error variant to `u8` together also passed all 38, because
every fixture initialised the field from the constant and nothing pinned it
independently. A `let _: &u16 = &snapshot.version;` binding closes it; the
narrowed build no longer compiles.

Frame-fit was proved for a paged combo write and a single fork write, but never
for behaviour, which has neither a bulk endpoint nor a per-entry loop and so sits
outside both patterns. A planner written stage by stage reached the end without
measuring it. The new test leaves only behaviour differing, against a frame too
small to carry it, and requires preflight rejection with nothing written.

Found while fixing the third: version 48 claimed the suite required only
`PartialEq`, having converted six whole-record `assert_eq!` sites to `==`. Two
were missed, so `Debug` was still required after the description stopped asking
for it. The claim was wrong when it was made. Both are converted now.

The regression is separate and larger. `agent-runs15` scored 9/10 against
version 49, up from 3/10 raw on `agent-runs13`, 2/10 once the version-46 false
positive was closed. `agent-runs14` is the same batch as `agent-runs15`, all ten
patches and trajectories byte-identical, so this is one measurement and not two. The version-41 canonicalization lever
now fails nobody. Versions 37 through 40 measured this and the version-40 gate
predicted it: a stated rule gets satisfied, and only slips survive between
batches. Canonicalization lasted two batches, longer than any lever before it.

Replaying all ten `agent-runs15` implementations against version 50 changes
nothing: every one of the nine passers still passes. These three fixes are
correctness coverage and were never a difficulty lever. Recording that
explicitly matters, because closing real gaps and moving the pass rate are
separate problems and this round only did the first.


## Version 50 diagnosis: a clue was mistaken for a difficulty

Asked why the rate went from 5/10 to 9/10, the run archive answers it directly,
and the answer is that the two numbers never measured the same thing.

Version 38's 5/10 had four independent causes across five failures: the no-std
surface build twice, the WASM round trip once, larger-target coordinates twice.
By version 43 all of it had collapsed onto a single test. Six of seven failures
in `agent-runs12` and seven of seven in `agent-runs13` were
`snapshot_canonicalizes_actions_equality_treats_as_the_same`. Once that happened
the pass rate was that one test's discovery rate plus a residual slip rate, and
nothing else.

The test measured whether a solver found a clue, not whether it could implement
anything. In `agent-runs13` exactly three trajectories mention `TapHold`, and
they are exactly the three that passed; the seven failures mention it zero times
while mentioning `KeyAction` 54 to 95 times each, so they read the type and did
not connect it. In `agent-runs15` all ten mention it 10 to 19 times. Discovery
went 3/10 to 10/10, Fisher exact p = 0.0198.

Three consecutive description edits sit between the batches, at versions 47, 48
and 49, every one of them a reviewer-driven clarity fix. Version 47 cut "the
rest the protocol's own types" on the reasoning that element types are
recoverable from `get_key`, `get_combo` and `get_morse`. They are, and
recovering them means opening the `KeyAction` definition, which is exactly where
the custom `PartialEq` lives. An edit meant to hand over less routed every run
past the clue. Version 49 then moved the "not the only one" warning out of
buried legalese into a standalone sentence-final clause, recorded at the time as
"Same meaning, no legalese". The meaning was the same and the salience was not,
and salience was the whole lever.

The error worth naming is mine and it is a category error, not a wording slip. I
treated a hidden clue as if it were difficulty. A clue cannot survive a review
process whose every finding pushes toward legibility, and each of those three
edits was individually correct. The lever was scheduled to die from the moment
it depended on the description staying vague.

## Version 51: replacing the lever instead of restoring the vagueness

The version-50 diagnosis left one decision. The three description edits that made
the canonicalization clue findable were all revertible in principle, and two of
them cleanly: the element-type sentence and the "including but not limited to"
phrasing were density findings, not fairness fixes. The third was not, because
version 48 had converted six `assert_eq!` sites to `==` alongside it, so
restating a `Debug` requirement the tests no longer enforce would have created a
description-and-test mismatch, which is a real defect rather than a style one.

Reverting the other two was rejected anyway. The honest reason for preferring
"including but not limited to" is that it is less noticeable, and difficulty by
obscurity is the failure mode reviewers are looking for. Every future density
review would attack that sentence again, because it reads as legalese to anyone
without the history, and the whole pass rate would rest on winning that argument
every round.

So the lever moved into the work. Restore now spends the fewest requests per
stage, and every rule is in the description: a request is one contiguous run in
the target's coordinates, it may carry matching entries to bridge differing
ones, it never spans a slot the snapshot does not reach, it never begins or ends
on a matching entry, and it must fit the frame. Reading that does not produce
the plan. A solver still has to build the target-space index map, segment it by
reachable slots, extend under a per-entry variable byte budget, and trim back to
the last differing entry.

Three things surfaced while building it, and each is worth recording.

A stated rule can silently contradict an older one. "A retry must not rewrite
entries that already match" was written when maximal splitting was mandatory,
and a bridging plan violates it on every retry. It now reads that a retry plans
afresh from what the device then holds, which is what the tests actually check.
Changing a contract means re-reading the sentences that were true only because
of the old one.

Coalescing removed a test scenario rather than a test. `assert_retry_skips_partial_stage_writes`
rejects the second request of a stage, and the paged stages now carry that
fixture in a single request each, so the injected failure never fired and the
first attempt succeeded. The fix was not to weaken the assertion but to move the
scenario: the per-entry stages keep it, and the paged partial failure moved to a
grown target, whose spare column and row split the keymap into three requests.
That test is stronger than the one it replaces, because it proves the retry
replans from a fresh baseline and that segmentation is stable across attempts.

A lever swap can shrink the reference. The planner no longer calls `split_pages`,
which packs one contiguous item list and cannot express bridging, so the
`pub(crate)` widening in `rynk/src/api.rs` became dead and the file left
`solution.patch` entirely. A compiler warning about the unused import is what
surfaced it, which is an argument for reading build warnings on a reference and
not only its test results.

## Version 52: one-sided rejection still pins a foreign codec

Version 50 added raw postcard encodings of two invalid public records to prove
that `from_bytes` validates after decoding. I recorded the probe as
codec-independent because it asserted only rejection: a non-postcard decoder
would reject the bytes as garbage and a postcard decoder would validate them.
That reasoning was incomplete.

A permitted custom decoder can consume either foreign byte string as an
alternate encoding of a valid snapshot even when its own `to_bytes` never emits
that spelling. The public contract constrains the implementation's round trip
and records that its decoder actually decodes as invalid; it does not assign
semantics to arbitrary bytes emitted by another serializer. One-sidedness avoids
requiring postcard acceptance, but it still requires rejection of a particular
foreign representation.

There is no fair black-box replacement through this API. The implementation's
own encoder must refuse invalid records, so it cannot produce native invalid
bytes, and the task deliberately documents no envelope field to mutate. The two
foreign-postcard cases are removed. The implementation-native trailing-input
probe, whole-record round trip, direct validation checks and five encoder
rejection cases remain. The lesson is that rejection of foreign bytes can pin a
format just as acceptance can; the relevant question is whether the contract
assigns those bytes a meaning.

No false-positive audit, mutation check, survivor probe, solver replay or cold
solver was run for this repair, per the operator restriction. Version 52 is
reference-verified on both architectures but remains unapproved and
non-submission-ready.

## Version 53: a fair body under a missing testcase identity still fails

Version 52 correctly removed the foreign-postcard assertions, but it also
renamed their containing test. The official post-solution snapshot tests passed,
yet the wrapper added a failure because the historically registered testcase
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions` was absent from
the merged JUnit. The submission therefore remained failing despite green code.

The error was treating a test function name as disposable implementation text
after that name had become part of the platform's expected-testcase inventory.
This is the same class as version 29's WASM check: a passing behavior that does
not appear under the expected JUnit identity is not a passing official phase.

The old name is restored and the version-52 body is unchanged. In particular,
the function still does not feed postcard-serialized invalid snapshots to
`from_bytes`; the name is compatibility metadata, not a restored codec
assertion. Both architecture JUnit reports now contain the exact expected name
and pass 41/41 focused tests, while their test-patch-only lanes pass 83/83.
No false-positive or solver work was run.

## Version 54: arbitrary WASM junk repeated the codec-collision mistake

The version-53 native decoder test was codec-neutral, but the standalone WASM
test still called `restore_configuration_snapshot` with the literal bytes
`[0xff, 0xfe, 0xfd]` and required rejection. The prompt assigns no meaning to
that sequence. A permitted custom snapshot format could treat it as a complete
valid record, so the wrapper probe repeated version 52's foreign-input mistake
through a different API.

The replacement starts from bytes returned by the implementation's own
`export_configuration_snapshot`, appends one byte, and requires restore to
reject the trailing input. This follows directly from the public whole-input
decoding rule without selecting a snapshot codec. The valid changed-snapshot
and foreign-identity cases remain, so the runtime test still proves that the
wrapper uses its argument and propagates native failures.

Both architecture lanes pass 83/83 regression and 41/41 focused tests, and
both JUnit reports retain the historical decoder testcase identity. Per the
user's instruction, no false-positive, mutation, survivor, solver or
calibration work was run for version 54.

## Version 55: root-tested offline is not arbitrary-UID offline

Version 54's Docker checks ran as root. The evaluator runs network-disabled as
a different UID, where nextest could not create its store below the root-owned
checkout and exited 96 before collection. The fallback compounded that failure
by reporting a skipped testcase with zero failures and errors. Moving the outer
store alone exposed two more ownership assumptions: a warmed crate source was
mode 0640, and both nested Cargo targets were placed beside a root-owned
manifest under `/app`.

The repair uses a `mktemp` runtime root for nextest's store and outer Cargo
target, uses the system temporary directory for each nested target, and grants
read/search access to the warmed Cargo and rustup trees after image setup. It
does not make the repository writable or bind the harness to a named account,
group or numeric UID. A nested spawn error now names the executable and
manifest. A pre-collection failure without native JUnit emits one
`harness-startup` error testcase rather than a skip.

With networking disabled, UID/GID 42424 passes 83/83 base and 41/41 focused
tests in both exact arm64 and amd64 version-55 images. A forced missing-Cargo
probe exits 127 and produces `errors="1"`. No behavioral assertion or
participant-facing requirement changed, and per instruction no false-positive,
mutation, survivor, solver or calibration work was run.

## Version 56: a real harness error and expected compile failure are different entities

Version 55 correctly made no-JUnit startup failures visible, but classified
the expected test-patch-only `new` compile failure the same way. The wrapper
then saw `new.harness-startup` only before the solution: it was neither one of
the 83 pass-to-pass tests nor one of the 41 fail-to-pass tests, and it was not
skipped. The official census therefore failed even though all real tests were
classified correctly.

The runner now emits a skipped `new.compile-placeholder` only when the `new`
lane has no JUnit and exits with nextest's compile-failure status 101. It keeps
the process nonzero, so the solution is still required. Every other nonzero
no-JUnit result, and every base-mode compile failure, remains an errored
`harness-startup`. Existing nextest JUnit is always copied instead of replaced.

The exact test-patch-only lane reaches rustc as UID/GID 42424 offline, exits
101, and reports one skip with no failure or error. Removing Cargo from `PATH`
exits 127 and reports one error with no skip. Exact arm64 and amd64 runs pass
83/83 regression and 41/41 focused tests, including both nested tests and the
registered decoder identity. No prompt, behavioral test, reference code,
Dockerfile or difficulty level changed. Per instruction, no false-positive,
mutation, survivor, solver or calibration work was run.

## Version 56 review: decoder validation is stated but not fully observable

The review is correct that the current decoder testcase directly exercises
only whole-input rejection. Unknown-version and invalid-length records are
checked through `validate` and the encoder's obligation to refuse them, not by
feeding semantic-invalid native bytes to `from_bytes`.

No fair guaranteed byte fixture exists while the encoding remains solver-
chosen. The implementation's own encoder cannot emit an invalid record;
postcard bytes are foreign to other legal codecs; and changing an assumed
version or length position would document the reference representation through
the test. A conditional sweep over mutations of native bytes would not supply
the requested negative case: a legal checksum-bearing codec may reject every
mutation, while invalid states in another codec may require coordinated byte
changes. Selecting that sweep because it catches the postcard reference with
its validation call removed would be mutant-specific fuzzing rather than a
portable oracle.

The semantic decoder rule stays public, but this part of it remains an accepted
black-box observability gap. No assertion or artifact changed, version 56 and
its hashes remain current, and no false-positive or solver work was run.
