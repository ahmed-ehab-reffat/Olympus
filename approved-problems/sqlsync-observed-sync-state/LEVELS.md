# Levels

## Accepted canonical version 37

Version 37 retains version 36's cross-source unsubscribe and registration-
ordering boundaries, reorganizes the dense participant description into
layered sections, and adds runtime verification that both public framework
hooks resolve to the structured receipt returned by `SQLSync.mutate`. Its
static audit and exact eight-state offline matrix pass at
`/tmp/sqlsync-gates.jy2dLy`.

The user confirmed external acceptance on 2026-08-07. No fresh version-37
solver calibration or operator-disabled false-positive/variation run is
invented after the fact: the immutable record remains 0/10 with those checks
absent. Raw evidence is archived at
`archive/sqlsync-observed-sync-state/agent-runs.tar.gz`.

## Version 36 - initial ordering and complete unsubscribe

Version 36 rejects a current initial subscription snapshot followed by a
superseded state buffered during registration. It also proves that unsubscribe
silence holds for coordinator acknowledgements and post-rebase application,
not only local mutation delivery. Its exact eight-state matrix passed at
`/tmp/sqlsync-gates.uMYxUv`; it was superseded before calibration.

## Version 35 - ordinary peer-removal silence

Version 35 proves that adding and then ordinarily removing a disposable
same-document subscription cannot notify two established peers when no state
changed. Its exact eight-state matrix passed at `/tmp/sqlsync-gates.Eh0GQ7`;
it was superseded before calibration.

## Version 27 - observation lifetime, routing, and uniform public values

Version 27 follows a 7/10 legitimate version-26 batch. It keeps the real
generated-worker integration and distinguishes connection intent from a newly
observed peer range, document-scoped subscription routing from process-global
fan-out, push delivery from idle polling, uniformly non-number LSNs from a
small-value numeric shortcut, and document identity from timeline identity for
applied progress.

The static audit and exact eight-state offline matrix pass at
`/tmp/sqlsync-gates.HoAUmc`. Version-26 run 1 fails specifically because it
clears `received` before the new peer sends a range; run 2 remains a legitimate
non-reference pass. False-positive mutants and variations were not run at
operator direction, so version 27 is **0/10**, audit-pending, non-immutable,
and not submission-ready.

## Version 26 - fresh initial state and near-ceiling LSN

Version 26 distinguishes a correct initial snapshot from two public surfaces
that merely agree: before any mutation or acknowledgement, callback and poll
must both have absent local, received, and applied watermarks. It also observes
`u64::MAX - 1` through the real range protocol and round-trips the opaque
non-number value through the public classifier.

The exact maximum is not injected because the pinned pre-task
`LsnRange::next()` computes `last + 1` and overflows before the feature can
observe that range. The static audit and exact eight-state matrix pass at
`/tmp/sqlsync-gates.yfy2AN`. False-positive mutants and variations were not run
at operator direction, so version 26 is **0/10**, audit-pending, non-immutable,
and not submission-ready.

## Version 25 - optional SyncState absence neutrality

Version 25 fixes a fairness mismatch without weakening the reconnect or public
typing contracts. Each browser `SyncState` progress field must have an exact
`Lsn` known branch, but its absent branch may be `null`, `undefined`, or both.
The real browser probe applies the same rule to polling and phase-local
subscription observations, including a fresh empty-at-zero connection that
clears retained acknowledgement knowledge.

The static audit and exact eight-state offline matrix pass at
`/tmp/sqlsync-gates.jB6WD7`, including the real generated-worker browser lane
and the mandatory missing-tool rejection. False-positive mutants and positive
variations were not run at operator direction. Version 25 is therefore
**0/10**, audit-pending, non-immutable, and not submission-ready.

## Version 24 - Docker portability and reproducibility

Version 24 changes no participant requirement, hidden behavior, or reference
implementation. Although the installed rustup supports `--target` on
`toolchain install`, the Dockerfile now uses the reviewer-compatible separate
`rustup target add ... --toolchain 1.91.1` form. Four packages already supplied
by the mandatory base are no longer reinstalled, and the sole direct apt
addition, `clang`, is version-pinned.

The standalone-clone image builds completely and the static audit, exact
eight-state offline matrix at `/tmp/sqlsync-gates.2MhIfk`, and separate combined
plain locked offline Cargo build/test pass. False-positive mutants and
variations were not run at operator direction. Version 24 is therefore
**0/10**, audit-pending, non-immutable, and not submission-ready.

## Version 23 - declaration, inclusive-browser, and full-u64 boundaries

Version 23 follows an 8/10 legitimate version-22 batch. It closes three public
coverage gaps without choosing a private bridge design or a browser LSN
carrier: worker receipt/state/status declarations must be concrete rather than
`any`; the browser classifier must apply inclusive watermarks to an older real
receipt after a newer receipt advances progress; and two adjacent opaque
acknowledgements above the signed-64 boundary must remain distinct, non-number
values that the public classifier accepts as input.

The reference passes the static and formatting checks, exact eight-state
offline matrix at `/tmp/sqlsync-gates.cSs2GN`, plain locked offline Cargo
build/test, and a replay of legitimate version-22 run 1. The two tests-only new
states still reject, the browser lane cannot skip when its tools are absent,
and the real generated-worker probe covers both new runtime boundaries.
False-positive mutants and variations were not run at operator direction.
Version 23 is therefore **0/10**, audit-pending, non-immutable, and not
submission-ready.

## Version 22 - end-to-end browser mutation classification

Version 22 exposes the existing timeline-bound, local-bounded stage classifier
through the worker package and `SQLSync.mutationStatus`. The public browser
values are `"local"`, `"received"`, `"applied"`, or `undefined`. The real
generated-worker lane classifies one receipt before acknowledgement, after
acknowledgement, and after coordinator application returns through storage and
rebase. It also rejects a foreign-timeline receipt and a same-timeline receipt
whose opaque LSN came from acknowledgement state above local progress.

The static audit, exact eight-state offline matrix at
`/tmp/sqlsync-gates.zzyC3Y`, and plain locked offline Cargo build/test pass.
Representative version-20 solutions 1, 3, and 9 fail specifically at the new
public export and facade method; these are historical replays, not calibration.
False-positive checks were not run at operator direction, so version 22 remains
**0/10**, audit-pending, and not submission-ready.

## Version 21 - snapshot, reconnect, fan-out, and notification boundaries

Version 21 compares initial subscription callback contents with current public
snapshots before mutation and for a late populated subscriber, covers the
exact inclusive `Received` boundary, replaces retained acknowledgement with a
fresh empty-at-zero range, keeps a second subscriber active after the first is
cancelled, and prevents acknowledgement-only progress from re-emitting an
unchanged connection status.

All verification gates pass, but all ten legitimate version-20 working-pool
patches also pass unchanged. Version 21 was therefore abandoned as too easy;
its replays do not count as calibration and its false-positive audit remains
operator-disabled.

## Version 20 - failure rollback and complete subscription stages

Version 20 closes three distinct public-behavior gaps in the real worker lane.
The coordinator-backed document now has an active sync-state subscription when
application returns through storage/rebase, and only a callback emitted after
that transition can satisfy the applied-stage oracle. A reducer-rejected
facade mutation must reject, preserve polled local progress, and publish no
advanced local watermark through the subscription. The ownership-neutral Rust
consumer also requires `status` to return `None` for a same-timeline receipt
when the snapshot has no local bound, even if downstream watermarks are
present.

Formatting, static checks, all eight offline patch states, plain Cargo, and all
four trajectory replays pass with the expected 2-pass/2-runtime-serde-failure
split. False-positive checks were not run at operator direction, so version 20
remains **0/10**, audit-pending, and not submission-ready.

## Version 19 - Rust trait and ownership neutrality

Version 19 removes three compile-time conveniences from the hidden contract.
Receipt identity is asserted through its public fields rather than whole-value
equality; status results use variant patterns rather than equality/debug
formatting; and a standalone public consumer accepts either an owned receipt
or a shared reference. The public prompt expressly permits both argument forms.

The exact borrowed-reference variation passes after removing `Debug` and
`PartialEq` from both public types. Formatting, static checks, all eight offline
patch states, plain Cargo, and four trajectory replays preserve the expected
2-pass/2-runtime-serde-failure split. False-positive checks were not run at
operator direction, so version 19 remains **0/10**, audit-pending, and not
submission-ready.

## Version 18 - optional applied-property representation

Version 18 removes two JavaScript key-membership assertions that required an
unavailable optional `SyncState.applied` value to exist as a runtime property.
Before application, ordinary property access still must not equal the receipt;
after coordinator application, storage return, and rebase, it must equal the
receipt. The generated TypeScript consumer continues to read `applied` as
`Lsn | undefined`.

Formatting, the static audit, all eight offline patch states, plain Cargo, and
the four trajectory replays pass with the expected 2-pass/2-runtime-serde-
failure split. False-positive checks were not run at operator direction, so
version 18 remains **0/10**, audit-pending, and not submission-ready.

## Version 17 - representation-neutral wire fixture

Version 17 removes decimal high-LSN literals and conversion from the private
browser replication fixture. High wire values are encoded directly as two
unsigned 32-bit words, while every public receipt/state LSN remains opaque and
is compared only to another value emitted by the implementation. Correct
string, bigint, word-pair, normalized, or other lossless non-`number` carriers
remain admissible.

The exact eight-state matrix, format/static checks, plain Cargo, and four
trajectory replays pass with the expected 2-pass/2-runtime-serde-failure split.
False-positive mutant and variation checks are disabled by default at operator
direction. Version 17 therefore remains **0/10**, audit-pending, and not
submission-ready.

## Version 16 - real applied-state return and fresh subscription events

Version 16 closes two trajectory-confirmed browser gaps. A native test
coordinator now participates through the existing replication protocol: the
real generated worker observes a receipt as received, remains unapplied before
coordinator work, then receives coordinator storage and must expose the same
receipt watermark as applied after rebase. The public TypeScript consumer also
reads `SyncState.applied`.

Lower fresh-connection replacement and empty-following acknowledgement checks
now accept matching subscription snapshots only from callback slices created
after each transition starts. Old matching snapshots cannot satisfy them.

The exact offline eight-state matrix passes. Replays of the four version-15
solver patches retain two legitimate passes and two failures at the recurring
runtime high-`u64` serialization boundary. Because the operator explicitly
deferred the mandatory false-positive audit, version 16 remains **0/10** and is
not submission-ready.

## Version 15 - deterministic Cargo doctest environment

Version 15 changes no participant behavior. The injected manifest disables the
empty host doctest harness for the Wasm-only `sqlsync-wasm` bridge, preventing a
missing cached `libsqlsync.rlib` from failing before any doctest can run. All
real workspace unit/integration tests and the remaining crate doctests still
run.

The rebuilt clean image also performs a final targeted host `sqlsync` build and
asserts that exact rlib exists, so plain clean-repository `cargo test` passes
before test injection as well.

The eight-state offline matrix and a separate plain
`cargo build && cargo test` replay pass. The false-positive mutation and
positive-variation suites were intentionally deferred by operator direction.
The later four-run unhinted batch produced two legitimate passes and two
runtime high-`u64` near-passes, so version 15 closed at **2/4** and was
superseded by version 16.

## Version 14 - explicit public layouts, ordering, and neutral frame fixture

Version 14 explicitly documents the public Rust receipt/snapshot struct fields,
the named `SyncStateSubscription` worker export, and delivery of the initial
snapshot before `subscribeSyncState` resolves. The browser fixture now encodes
high protocol LSNs from decimal text into 32-bit words and contains no BigInt
dependency; public LSN values remain opaque, and a public-`bigint` variation
passes.

The required Docker base now performs a literal locked Cargo workspace build,
checks the committed pnpm lock, and installs/builds all browser dependencies
before offline execution. The exact eight-state matrix, 19 mutants, eight
legitimate variations, and four representative old-solver replays pass. Fresh
version-14 calibration is exactly **0/10**.

## Version 13 - named subscription export

Version 13 named the public `SyncStateSubscription` export and removed
redundant opening layout prose. It was an unverified editorial intermediate
superseded by version 14; it has no calibration runs.

## Version 12 - mandatory real worker path and live observation

All four version-11 working-pool runs solved the task, and every official new
lane selected the synthetic portable facade probe. Version 12 removes that
fallback: the frozen amd64 image always builds the reducer and generated Wasm
worker, then runs the real facade/coordinator loopback.

The public contract now adds per-document `SQLSync.subscribeSyncState`
observation. It delivers the current snapshot, pushes later local-mutation and
coordinator-acknowledgement changes, and stops after unsubscribe. This crosses
the Rust/Wasm event path and TypeScript listener lifecycle rather than adding
another polling fixture. The LSN wording is provenance-neutral: any exported
lossless non-`number` representation remains valid. Fresh version-12
calibration is exactly **0/10**.

## Version 11 - concise participant description

Version 11 deletes a redundant opening sentence whose two claims are already
specified by the concrete Rust and worker API directives. Requirements,
`test.patch`, `solution.patch`, Dockerfile, and all behavioral discriminators
are unchanged. The exact eight-state matrix, fifteen isolated mutants, seven
legitimate variations, and representative solver replays pass under the new
prompt hash. Fresh version-11 calibration is exactly **0/10**.

## Version 10 - trajectory-hardened protocol and wrapper boundaries

Version 9 solved 4/4 in the unhinted working pool, so it was abandoned as too
easy. Version 10 adds four distinct public discriminators: lower fresh-
connection replacement of a larger stale watermark, empty-following
acknowledgement history, runtime receipt/state timeline agreement, and receipt
returns through the React and Solid hooks.

The exact eight-state matrix, fifteen isolated mutants, and seven legitimate
variations pass. All four old version-9 patches fail unchanged in the full
version-10 lane, while run 1 passes after only its newly stated empty-range
derivation is repaired. Fresh version-10 calibration is exactly **0/10**.

## Version 9 - return-shape and facade-transformation neutral

Version 9 removes the remaining cross-cutting API-shape assumptions. The Rust
suite adapts direct, optional, and fallible snapshot results instead of calling
`.unwrap()` on the participant method. The portable facade tries several
plausible exact worker carriers and validates only the returned public shape
and non-number safety; it does not require worker reply passthrough.

The exact patch-state matrix, full and stock-tool new lanes, eleven-mutant
false-positive audit, and all six legitimate variations pass. Direct Rust state
return and facade string-to-`bigint` normalization are explicit positive
variations. It later solved 4/4 unhinted working-pool runs and was abandoned as
too easy; those runs are historical and do not count for version 10.

## Version 8 - historical ownership-neutral and no-skip validation

Version 8 preserves the complete observed-progress contract while removing two
unpublished interface assumptions. Rust tests no longer require
`MutationReceipt: Copy`; browser tests no longer require public LSN values to be
accepted by `BigInt`. The full worker lane distinguishes adjacent high `u64`
values structurally, and the portable lane supplies an opaque value that cannot
be converted to a primitive.

Every `test.sh new` environment now executes a facade test: the generated
worker loopback is used with the frozen package tools, and the repository's
actual TypeScript facade source is used with stock Node otherwise. Both exact
paths pass with zero failures, errors, or skips. All eleven mutants are killed,
and four legitimate variations pass. No local frontier pre-filter or platform
solver run has been performed, so calibration is exactly **0/10**.

## Version 7 - historical complete observed progress

The single participant level covers exact timeline-bound mutation receipts,
inclusive local/received/applied observations, retained-prefix progress,
acknowledgement versus application ordering, receipt validity and precedence,
disconnect retention, reconnect refresh, lossless browser LSNs, and the
participant-facing `SQLSync` methods.

Construction version 7 passed the exact four-state matrix, portable stock-tool
baseline, full offline lanes, lint, worker packaging, and the eleven-mutant
false-positive audit. Cloned facade values, renamed inner worker schema, and a
renamed acknowledgement accessor all pass as legitimate variations. No local
frontier pre-filter or platform solver run has been performed. Calibration is
therefore exactly **0/10**; no result from construction versions 1-5 carries
into this version, and version 6 is historical only.

The reference changes 14 production/example files with 344 additions and 17
deletions. That is architecture evidence only. Long-horizon acceptance must be
decided from successful independent solver patches and platform-reported agent
messages, not reference size.
