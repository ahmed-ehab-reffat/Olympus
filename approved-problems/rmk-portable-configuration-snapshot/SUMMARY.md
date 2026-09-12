# RMK portable configuration snapshot

Status: **accepted and archived 2026-08-05; canonical version 56 Level 6**

Repository: `rmk-rs/rmk`

Pinned commit: `c94426a68779e61cecc4380e21e9079e0ef0c2ae`

The problem adds deterministic, versioned export and restore for every
host-visible mutable Rynk configuration family, with portable same-model
compatibility, ordered non-atomic restore progress, and native/WASM byte parity.

Versions 18 through 20 closed the reported boundary gaps: non-square keymap
ordering, empty and partial macro extents, multi-slot resources, independent
identity and geometry mismatches, all eight first-request failure stages, and
later-request failures within encoder, fork, and macro stages. All four latest
saved solvers passed that contract, showing that further rejection fixtures
would improve coverage without materially increasing task difficulty.

Version 21 changed the restore architecture. After compatibility preflight,
the client must read a complete current baseline before any mutation. Equal
resource stages send no setter. Dirty stages alone are written in the existing
order, and write-failure progress contains only dirty stages that completed in
full. A failure while reading the late baseline remains a no-write preflight
error. The rule is stage-granular: it does not require private helpers,
item-level minimality, rollback, or exact bulk page scheduling.

Version 22 shortens the participant description to 421 whitespace-counted
words without changing any contract, hidden test, or reference behavior.

Version 23 removes transcript coupling discovered in review. Native tests still
enforce exact export order, complete pre-mutation baseline coverage, advertised
extents, final state, and dirty write-stage order, but baseline reads may occur
in any order. The WASM peer dynamically accepts identity reuse or reread and
rejects unrecognized or mutating requests. The description is now 407 words
after removing two redundant guarantees.

All four `agent-runs6` implementations passed version 23. Each retained the
complete baseline but compared indexed resources as whole vectors, rewriting
every entry in a dirty stage and every macro chunk if any byte differed.
Version 24 selects the next repository-supported architectural boundary:
indexed resources are restored entry-sparsely, macros are restored
chunk-sparsely, and a retry refreshes the baseline so already applied entries
are not rewritten. The participant description remains compact at 442 words.

The revised stateful tests distinguish these independent shortcuts:

- unconditional writes fail an identical-target no-op probe;
- whole-stage rewrites fail a logical mixed-entry probe across keymaps,
  encoders, combos, forks, and Morse definitions;
- whole-macro rewrites fail when only the first and last advertised chunks are
  dirty around an equal middle chunk;
- mutation before complete baseline acquisition fails a late-read probe; and
- accepting a successfully read invalid baseline fails before any setter;
- counting skipped resources as completed fails sparse progress reporting; and
- retrying an entire partially applied stage fails the per-entry write ledger.

Versions 26 and 27 add two more:

- comparing or addressing entries at the snapshot's own flat indices fails a
  target grown by one in every geometry dimension, which also fails any write
  that disturbs a slot the snapshot does not reach; and
- one request per differing entry fails the exact request-shape ledger, which
  records single setters and bulk pages alike as `(first entry, entries)`.

Version 26 answers a platform review of version 24. Two hidden assertions named
bulk read commands and so rejected a legitimate baseline assembled from
per-entry reads; both now fold single-entry and bulk reads to one phase per
resource, matching what the ordering assertions already did. The new lane also
builds a dependency-free surface crate with `alloc` on and `std` off, because
both graded lanes previously enabled `std` and rynk's own dev-dependencies
re-enable it through feature unification.

That repair makes the reported 3-of-4 pass rate a floor, so version 26 raises
the level. A target is now compatible when no geometry dimension is smaller
than the snapshot's, which forces every comparison and write address into the
target's coordinates and leaves uncovered slots untouched; and consecutive
differing entries must travel in as few requests as the target's advertised
page size allows. Request shape is judged as `(first entry, entries)`, so the
endpoint family stays free.

The description is now maintainer prose at 467 words rather than a field-by-field
specification, keeping the names the hidden tests construct.

Version 27 answers a review of version 26. Seven rejecting-preflight tests
drove a scripted link that answered only the identity read and then hung, so
any further read-only request timed out even though the contract forbids only
mutation. They now run against the stateful peer, which answers every read, and
assert only that no setter was sent. The `alloc`-only surface check moved from a
shell step into the graded nextest set, because as a shell step it appeared
solely as a failure in the run without `solution.patch` and so belonged to
neither the regression nor the new-test set; and the surface crate no longer
pins exact result and error types, which the description never states.

Version 28 answers the first real trajectory batch. All five `agent-runs7` runs
failed version 27, and all five failures were the harness rather than the
implementations. Runs 1 to 3 lost seven tests each to a write-side page cap
that the repository contradicts: `max_bulk_keys` is documented for reads only,
and the crate's own `split_pages` sizes writes by payload budget. Run 4 lost
those plus five more by returning standalone `RestoreError` variants for
pre-mutation rejections. Run 5 never compiled, because it declared
`Preflight { source }` while the tests destructured `Preflight(_)`.

The cap and the request-shape ledger are gone, the tests match
`Preflight { .. }` so either variant shape compiles, every multi-request stage
now has a dirty-equal-dirty gap so a second request exists whatever an
implementation packs into one, and the description states that `RestoreError`
has exactly two cases with `Preflight` covering every pre-write rejection. The
description is also split into shorter thematic paragraphs, longest 57 words.

Replaying the five implementations against the repaired tests gives 4/5, up
from 0/5, and the fifth fails only on the error mapping now documented. Version
28 is therefore expected to land near 100%, far above the 50% cap, and needs a
new fair lever before a calibration batch is worth spending. Geometry
adaptation is not that lever: every run that compiled handled it correctly.

Version 29 answers a package review of the reference and the runner. The WASM
round trip ran as a shell step after nextest, so its result reached only the
exit status and the merged JUnit reported it as an expected-but-missing
testcase; it is now a graded test and the report holds all 28 cases. The
reference also reuses the crate's own `split_pages` instead of a second pager,
stops rejecting non-bulk devices during export, and no longer re-reads
capabilities and identity it already holds. The participant contract is
unchanged and the replayed rate is still 4/5.

Version 30 answers two further findings. The nested WASM round trip assumed its
host provided the wasm32 target, the wasm-bindgen runner and Node; it now probes
for all three and stands down with a message when any is missing, while still
running and still gating in the provisioned image. The description no longer
claims `RestoreError` has exactly two cases, which the tests never checked; what
they check, and what it still says, is that every rejection before the first
write arrives as `Preflight`.

Version 31 removes the postcard mandate. The contract needs deterministic
bytes, full consumption and version rejection, not a named format, so the
description now says the encoding is the implementer's choice. One test did
depend on the codec, hand-encoding its unknown-version input because `to_bytes`
validates; it now checks that `validate` rejects the version and `to_bytes`
refuses to emit it, and no test assumes an encoding any more.

A second finding, that nine tests require `Preflight` to be a struct variant,
rests on a mistaken premise: `Variant { .. }` is Rust's struct-pattern form and
the language applies it to tuple variants too, so one arm accepts both shapes.
The behaviour is unchanged; the nine sites now route through one documented
helper and a graded test declares both shapes locally and proves the pattern
accepts each.

Version 32 hardens the task using `agent-runs8`, the first batch that both
compiles and passes, at 4/5 against version 31. All five implementations share
one architecture: export a baseline, diff it, then write stage by stage and
discover problems along the way. The review handed over the seam by filing the
same defect against the reference: `split_pages` and `send_frame` both reject an
oversized request locally, without a device, so a streamed restore writes earlier
stages and only then trips over a later one it could have ruled out first.

The description now requires the host to establish before sending anything that
every request it will issue fits the target's advertised frame, and the
reference plans all keymap, combo and Morse pages up front. The test gives a
target whose frame carries reads, keymap and encoder writes but never a combo
write, so a planning restore reports `Preflight` untouched while a streaming one
writes two stages first.

Two coverage findings are also fixed: the surface crate now asserts
`Serialize + DeserializeOwned` rather than inferring serde from a working
`to_bytes`, and `to_bytes` must refuse every validation failure, not only an
unknown version.

Replaying both saved batches gives 1/10, down from 4/5 on `agent-runs8` alone,
and every failure is the new check. That is a floor rather than a forecast: all
ten implementations predate the rule being stated.

Version 33 answers eight fairness findings. Five concerned request order inside
a stage: the suite compared write logs as sequences, but only stage order is
stated and the crate's own `write_all` dispatches pages concurrently, so every
per-stage comparison now sorts first. One dropped a serde bound on
`SnapshotGeometry` that the task never required. Two rested on an
unsupported-version rule that version 31 had accidentally deleted along with the
postcard sentence; the rule is back in the description. The description is 496
words, and the replayed rate is unchanged.

Version 34 relaxes the last ordering coupling. A write failure had to have sent
exactly one request from the failed stage, but only "no later stage" is stated,
and `write_all` keeps several pages in flight, so it now asserts that the
rejected request was reached and that nothing from a later stage ran. The
optional batching sentence is gone from the description, which is 481 words. The
replayed rate is unchanged.

Version 35 removes the last two compile-time shape constraints. Naming
`SnapshotRead` as `Option<SnapshotRead>` demanded it be nongeneric and
lifetime-free, which the task never says, so it and the other exist-only items
are named by import instead. And the surface crate borrowed the snapshot in both
restore calls while the task said nothing about ownership; the retry test cannot
avoid borrowing, so the description now states it. 497 words, replayed rate
unchanged.

Version 36 closes two gaps a package review found in the reference. Export read
the keymap, combos and Morse definitions through the crate's pagers, which are
gated on bulk transfer, although the task makes bulk a restore precondition
only; it now reads per entry when the device does not advertise it. And only the
paged writes were measured against the target's frame, so a frame too small for
a fork write would have surfaced mid-restore after earlier stages had applied;
every single-entry write is now measured too, and the planning test runs a
second budget that stops the fork write specifically. The description is
unchanged.

Version 37 restores the non-bulk export test that version 36 withheld, after a
review flagged its absence as a HIGH false-positive risk, and states the
asymmetry in the description so it is discoverable. `agent-runs9`, eleven runs
against version 36 with one aborted, measured 8/10; the export test takes that
to 6/10. Both of version 36's failures were genuine, one of them an
implementation that declares `Box` without importing it under `alloc` without
`std`. Two further candidate levers were tried against the same ten
implementations and neither discriminated, so they are kept only as regression
coverage. At 6/10 the task is still above the 50% cap.

Version 38 names `Debug` and `PartialEq` in the description. Six tests compare
whole `ConfigurationSnapshot` values with `assert_eq!`, which requires both, and
the description had named only the serde traits. Amending it is preferable to
rewriting those tests field by field, which would be more verbose and would let
a field added to the record but forgotten in an assertion go unchecked. Both
patches are unchanged from version 37.

Version 39 repairs a WASM boundary fault. The hidden test called
`export_configuration_snapshot` as a Rust method and used its result as a
`Vec<u8>`, so a wrapper returning `js_sys::Uint8Array` failed to compile even
though wasm-bindgen surfaces both as the same JavaScript typed array. Export now
goes through `Reflect` and a JS `Function`, as restore already did. That fault
cost `agent-runs10` one run: its 5/10 becomes 6/10, matching `agent-runs9`.

Version 40 hardens after two batches measured 60%. Restore no longer requires
whole-resource bulk transfer: neither direction does, and where a device lacks
it both read and write one entry at a time, which the protocol supports
directly. Per-dimension geometry growth coverage is added so no stride hides
behind another.

The measurement that matters is negative. Three probes were written and run
against the saved implementations and caught nobody, and a merely stated rule
gets satisfied: two of ten missed export-without-bulk when unstated, none of ten
once stated. Only two things discriminate across batches, and both already
exist: the `alloc`-without-`std` surface check and geometry precision. The
recommended next step is a Dockerfile rebuild adding a bare-metal target, which
also slims the image.

Version 41 answers a saturated batch. All five `agent-runs11` runs passed
version 40 outright, so the lever had to come from the types rather than the
prose. `rmk-types` gives `KeyAction` a hand-written `PartialEq` that ignores the
morse-profile index carried by `TapHold`, while serde still serializes it, so
two snapshots that are equal by the protocol's own rule encode to different
bytes. The description has required equal snapshots to produce equal bytes since
version 1, but it illustrated that with `Morse.actions` insertion order and every
implementation canonicalized exactly that one case. The clause is now general.
All five implementations fail the new check, the first lever here to catch a
whole batch that passed everything else.

Version 42 removes two traits the hidden setup imposed without the task naming
them: `Clone` on `ConfigurationSnapshot`, from building a fixture by cloning
another, and `Copy` on `SnapshotGeometry`, from moving it out of a borrowed
snapshot at three sites rather than the two reported. Both are scaffolding, so
behaviour is unchanged and the version-41 lever still catches all five
`agent-runs11` implementations.

Version 43 answers a review that reports the task passing, with no critical
fixes, no failures and a 30% pass rate inside the 50% cap. The canonicalization
test varied the ignored `TapHold` profile index in the keymap and encoders only,
so a canonicalizer covering just those two tables would pass; it now varies the
index in a combo's actions and output and a fork's trigger and both outputs, and
the reference already handled all four. The density note is answered by
reorganization alone: three paragraphs carrying two subjects each are split at
the seam, with the text word-for-word identical and the longest paragraph down
from 56 words to 42.

Version 44 answers `agent-runs12`, ten runs at 3 passes, a 30% rate inside the
cap with every failure a real defect: six on the canonicalization lever, one on
a long final macro chunk, one a `step_by(0)` panic that failed both natively and
under WASM. The one thing worth fixing was contention: the two tests that shell
out to Cargo shared the standalone workspace's target directory, so nextest
running them together made each wait on the other's locks and cost one build
3m36s. They now use separate target directories and a nextest test group capped
at one thread; the lane logs no blocking and finishes in 33 seconds. Behaviour
is untouched.

Version 45 closes a hole in the WASM runtime test. It called
`restore_configuration_snapshot` with the board's own exported bytes and checked
only that the scripted responses were consumed and ten requests had been sent,
both already true after the export half, and restoring a board's own
configuration asks for no writes at all. A wrapper that ignored its argument
passed. The test now requires junk bytes to be rejected, and restores a record
that differs from the board while asserting a write carrying the changed action
was sent, through either endpoint. A wrapper rewritten to ignore `bytes` fails.

Version 46 closes a false positive. One `agent-runs13` implementation preflights
by walking the whole record and sizing every entry's write request against the
frame, before comparing anything to the baseline, so a board that already holds
an entry too large to write in one frame is rejected when the contract requires
that restore to succeed writing nothing. The suite tested frame-fit against a
dirty board and no-op restore against a generous frame, but never their
intersection. It now pairs the frame that stops a fork write with a board that
already matches. The other two passes are unaffected, so the batch reads 2/10.

Version 47 covers a second way the baseline read can fail. The rule makes every
pre-write rejection a preflight failure whatever the cause, but only a device
saying no was tested; the peer now also answers a named read with a payload the
client cannot decode, and the test runs both. Reviewing it exposed a weakness the
report did not mention: the test used a board that already matched the snapshot,
so its no-mutation assertion could not fail. It now uses a dirty board. The
description also loses "the rest the protocol's own types", weighed against the
element types staying reachable through the protocol's own read methods.

Version 48 closes two error-propagation gaps and settles a conflict between two
reviews. The WASM test never gave the wrapper valid bytes whose native restore
fails, so one that discarded the native error and resolved passed; it now
restores a record naming another board and requires the promise to reject.
Export was never made to fail, so an implementation hiding a read failure behind
a defaulted field passed; a late rejected or undecodable read must now fail the
export. And where one review called the unstated `Debug` and `PartialEq`
requirement unfair while another called stating them filler, the requirement was
reduced rather than the sentence: whole snapshots are compared with `==`, which
needs only `PartialEq` and keeps the whole-record check.

Version 49 closes a retry-ordering gap. The retry test walked the six
multi-request stages, and in all of them the first attempt fails before behaviour
is reached, so the one case that matters most went untested: behaviour applied,
the default-layer write refused, then a second attempt. That is where the whole
configuration has already landed and an implementation reusing the previous diff
would resend it. The new test requires the second attempt to write the default
layer and nothing else. The equality clause also loses its legalistic phrasing
while keeping the warning that the Morse map is not the only case.

Version 50 closes three demonstrated audit gaps: decoding accepted records it
had not encoded because validation was only ever checked through `validate` and
`to_bytes`; the `u16` version type was not pinned independently of the constant,
so both could be narrowed together; and frame-fit was proved for paged and
per-entry writes but never for behaviour, which has neither. A fourth was found
alongside them, two whole-record `assert_eq!` comparisons missed in version 48
that still required `Debug`.

The headline is elsewhere. `agent-runs15` scored 9 of 10 against version 49, up
from 2 of 10, because the canonicalization lever now fails nobody. That is the
pattern this problem has measured repeatedly: a stated rule gets satisfied, and
only slips survive between batches. The audit gaps are correctness coverage and
do not move it; all nine passing implementations still pass.

Version 51 replaces the difficulty lever. The version-50 diagnosis showed the
canonicalization lever was never implementation difficulty but a hidden clue,
and that three rounds of reviewer-driven clarity edits had made it findable by
everyone. Rather than restore the vagueness, which would have to be re-fought at
every review, the difficulty moved into the plan itself.

Restore now spends the fewest requests it can. A bulk request covers a
contiguous run in the target's coordinates, so it may carry entries that already
match in order to bridge two that differ, but it never spans a slot the snapshot
does not reach, never begins or ends on a matching entry, and must fit the
frame. Every one of those rules is in the description. Knowing them does not
produce the plan: a solver still has to build the target-space index map,
segment it by reachable slots, extend under a per-entry variable byte budget,
and trim. Nothing depends on noticing anything.

Review of version 51 returned three order-pinning findings, all valid and all
fixed: request comparisons now sort, and the paged-retry test asserts request
count and per-key write count rather than which run the peer happened to refuse.
A reference mutated to send the same minimal plan back to front passes all 75
tests. A fourth finding, to delete the SnapshotGeometry field list, is contested:
DeviceCapabilities does not determine which of its fields are structural, and the
suite pins all ten by struct literal.

A second review found one unfair test and one redundant test, both caused by the
version-51 density trim. `completed` had to exclude no-op stages while the
description no longer said so, because the trim cut "skipped stages are absent"
as restating its neighbour when it does not. The clause is restored and the test
kept, since it is the sole discriminator for that rule. The redundant test,
which the trim had turned into a strict subset of another, is deleted.

Version 52 accepts a later codec-freedom finding. The decoder test fed
`from_bytes` raw postcard bytes that no implementation method produced and
required rejection. Even a rejection-only assertion constrains an unspecified
codec: a valid custom decoder may consume those bytes as an alternate encoding
of a valid record. Because `to_bytes` must refuse invalid records and the task
documents no mutable envelope, there is no codec-neutral way to synthesize an
implementation-native invalid record. The two foreign-postcard cases are
deleted without replacement. Whole-record round trip, trailing input based on
the implementation's own bytes, direct validation, and encoder rejection remain.
The public description, solution and Level 6 difficulty lever are unchanged.

Version 53 repairs the resulting packaging regression. Version 52 also renamed
the containing test, but the platform's official wrapper still registered its
historical testcase identity and reported that expected case missing even while
the visible suite passed. The old function name is restored without restoring
the unfair foreign-postcard assertions. Exact arm64 and amd64 JUnit reports now
contain the registered identity and pass the full focused lane.

Version 54 removes the remaining codec-coupled malformed-byte fixture. The WASM
runtime test had required the arbitrary sequence `[0xff, 0xfe, 0xfd]` to be
invalid even though the encoding is implementation-defined. It now starts from
the implementation's own exported snapshot bytes, appends one byte, and
requires the wrapper to reject trailing input. This preserves the public
whole-input decoder check without assigning meaning to a foreign encoding. The
historical testcase identity remains registered.

Version 55 repairs the offline harness for the evaluator's unprivileged UID.
Nextest's store and outer Cargo target now live in a private runtime temporary
directory, each nested Cargo target lives under the system temporary directory,
and the final image layer makes every warmed Cargo and rustup input readable
and searchable without making the checkout writable. A pre-collection runner
failure now appears as a JUnit error instead of a skipped placeholder. This is
infrastructure only; no behavioral test, prompt rule, reference path or Level 6
discriminator changed.

Version 56 restores the necessary distinction inside that fallback. The
test-patch-only `new` lane is expected to reach rustc and fail because the
snapshot API does not exist yet; exit 101 now yields one skipped
`new.compile-placeholder` while preserving the nonzero process status. Genuine
startup failures still yield an errored `harness-startup`, and existing nextest
JUnit is copied unchanged. This removes the wrapper-only entity that was
neither pass-to-pass nor fail-to-pass without hiding infrastructure failures.

A later decoder-coverage review identifies a real but non-actionable gap. The
suite does not feed `from_bytes` a semantic-invalid record in the solver's own
encoding, because `to_bytes` must refuse such a record and the task defines no
mutable envelope. Foreign postcard bytes or assumed field offsets would revoke
codec freedom. A conditional mutation sweep would not guarantee the requested
case for legal integrity-protected or structurally validating codecs and would
be selected around the reference representation. The public decoder-validation
rule remains, but no fair black-box assertion or artifact change results.

## Verification completed

- Reference solution: 41/41 focused tests pass offline as UID/GID 42424 on
  arm64 and amd64 for exact version 56, including the alloc-only and WASM
  subprocess checks; each JUnit
  contains the wrapper's expected decoder testcase identity.
- Replay of all five `agent-runs7` implementations: 4/5 pass.
- Runtime WASM snapshot test: inside that 28, and confirmed to fail when the WASM wrapper is broken.
- `alloc`-without-`std` surface build: runs inside the graded set as
  `snapshot_surface_builds_with_alloc_without_std`, and was confirmed to fail
  when the module and its re-exports are gated on `std`.
- The test-patch-only `new` lane exits 101 and yields one skipped
  `new.compile-placeholder`; a forced pre-collection failure with Cargo absent
  exits 127 and yields one `harness-startup` JUnit error.
- A mutant that reads the whole device during preflight passes; a mutant that
  writes one setter before validating fails eight tests; a flat-index keymap
  comparison, exact geometry equality, and writing an entry that already
  matches each fail their recorded tests.
- Pre-existing Rynk workspace suite: 83/83 passes offline as UID/GID 42424 on
  arm64 and amd64 with the version-56 test patch applied alone.
- Both patches apply cleanly and in order to a pristine pinned checkout, with
  `test.sh` at mode 755 and no whitespace errors.
- No cold solver or calibration run was started.

The exact version-56 false-positive audit and solver calibration were skipped
at the user's request. The completed version-17 audit cannot be carried forward
because the public contract and artifacts changed. Version 56 was nevertheless
accepted by the platform, as confirmed by the user on 2026-08-05. That outcome
does not retroactively create a local audit result or measured solve rate;
calibration remains recorded as 0/10. Raw evidence is archived under
`archive/rmk-portable-configuration-snapshot/`.
