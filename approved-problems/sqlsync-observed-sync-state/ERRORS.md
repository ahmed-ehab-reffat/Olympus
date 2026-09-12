# Errors and review resolutions

Construction version 1 passed the initial four-state matrix, but its seven
Rust tests did not observe the worker's outer acknowledgement cache. A
never-refresh cache passed the focused and complete pre-existing suites. A
loopback Node/Wasm browser probe was added to observe the public mutation and
snapshot replies after a real range acknowledgement.

Version 2 contained that probe. Combined lint then found repository-formatting
differences in the new `.mjs` file. Version 3 applied only the formatter's
output and repeated the gates and mutation set.

Version 3 still allowed a client to erase the last acknowledgement on
disconnect. That mutant passed both focused and complete pre-existing suites.
Version 4 extended the public browser probe through a real disconnect and
verified that the snapshot remained available.

A final review found two version-4 gaps. A `u64 -> f64 -> string` bridge passed
declaration checks and all low-value behavior, and a browser-only failure could
leave a passing nextest XML file. Version 5 reconnects to a peer range at LSN
`9007199254740993`, checks it through `BigInt`, and emits fallback failing JUnit
whenever any command fails. The reference, exact matrix, lint, complete base
lanes, and all ten mutants were rerun from zero for version 5.

An early mutation attempt mounted source files whose timestamps predated Cargo
incremental objects. Cargo displayed compilation but reused stale code. Those
results were discarded. Recorded mutation runs copy each isolated file into a
fresh ephemeral container, forcing the expected rebuild.

There are no known baseline or environment failures in version 5 on the frozen
`linux/amd64` lane. The upstream pnpm-8 workflow drift and native ARM
`sqlite-vfs` signedness error are pre-existing and are handled by the pinned
pnpm 9.15.9 and amd64 evaluation environment.

An interface review then found that version 5 required an undocumented
`SyncState::new` constructor and the exact TypeScript spelling `interface`, yet
did not compile or run the participant-facing `SQLSync.mutate` and
`SQLSync.syncState` methods. Version 6 removes the constructor and declaration-
form assumptions, trims non-functional prompt prose, compiles a structural
TypeScript consumer, and runs both high-level facade methods against a fake
worker before the existing loopback probe. Equivalent type-alias declarations
pass. The complete gates, exact combined lint, and twelve isolated mutants were
rerun from zero; there are no known version-6 baseline or environment failures.

A subsequent fairness review found three remaining over-constraints in version
6: JavaScript reference identity through the facade, exact new inner worker
reply tags/wrapper fields, and an exact `ReplicationProtocol` accessor name.
The reported stock baseline also lacked `just` and `pnpm`, and rustup-qualified
Cargo attempted a forbidden toolchain download.

Version 7 replaces the two browser probes with one real public facade and
generated-worker loopback. Its worker double forwards document traffic
opaquely, its assertions use structural values, and its Rust flow derives the
acknowledgement from the existing public range reply. Clone, schema-rename, and
accessor-rename variations all pass. The runner now uses plain locked offline
Cargo for the complete base library/doc lane, avoids the unrelated upstream
example that requires a separately built `guest.wasm`, and skips the browser
lane only when its locked build tools are unavailable. The exact matrix, lint,
eleven isolated mutants, and static audit were rerun; there are no known
version-7 baseline or fairness failures.

The next solution review found two remaining interface assumptions in version
7. The Rust integration reused one moved receipt four times, which made a
natural by-value `status` signature compile only when the receipt was `Copy`.
The browser path required `BigInt(public_lsn)`, even though the prompt permits
other exact documented carriers. It also reported a skipped browser lane when
package helpers were missing, while the evaluator requires every new test to
run after the solution is applied.

Version 8 constructs a fresh receipt from the saved public timeline/LSN for
each later classification. Removing `Copy` from the reference receipt passes
the exact integration suite. Public browser values are now compared with deep
structural equality; adjacent values above `2^53` must remain distinct, but no
primitive type or conversion API is prescribed. A stock-tools fallback loads
and executes the real `SQLSync` TypeScript source with a schema-agnostic port
and a deliberately non-convertible opaque LSN. The JUnit document contains no
skip element in either branch.

The reported upstream `cargo test` failure is caused by the reducer host example
including a guest Wasm file that standalone Cargo does not build first. The
task Dockerfile did not need modification: it already runs `just build` before
`just test`, which generates that guest. The test-only base lane intentionally
uses locked offline library and doctest commands, while the focused Rust new
test embeds a tiny valid reducer and requires neither the example artifact nor
the Wasm target. The rebuilt clean image, complete four-state gates, eleven
mutants, four legitimate variations, and static audit all pass for version 8.

A further fairness review found that version 8 still selected a Rust return
shape by calling `.unwrap()` on every `LocalDocument::sync_state` result. It
also made the stock-tool facade probe require deep equality with a frozen
synthetic receipt/state and its arbitrary opaque nested LSN. Neither constraint
is stated: the Rust method may return the snapshot directly, and the facade may
normalize the generated worker representation just as existing query methods
transform replies.

Version 9 introduces a test-local Rust adapter for direct, optional, and
fallible snapshots. Its portable facade tries decimal text, `bigint`, and a word
pair as plausible worker inputs, then accepts transformed structured output
whose progress values are not JavaScript numbers. It never compares the result
to the input. A direct-state-return variation and a facade string-to-`bigint`
normalization variation both pass the complete new lane. The rebuilt clean
image, full patch-state gates, eleven mutants, six variations, and static audit
all pass.

Version 9 then solved all four unhinted working-pool runs. Raw trajectory review
showed that three implementations reduced an empty peer range to `last()`, and
one left the React and Solid mutation hooks typed as `Promise<void>`. The
reported reconnect probe also moved only upward and therefore did not reject a
monotonic-max stale cache; runtime receipt checks did not compare timeline
identity with the snapshot.

Version 10 makes those four public boundaries explicit and behavioral. A lower
fresh reconnect must reproduce a previously saved public value, an
empty-following range at B+1 must reproduce saved B, receipt and state timeline
IDs must agree at runtime, and both framework packages undergo strict type
compilation. The first combined gate exposed a repository `lib` mismatch for
`Symbol.dispose`; the framework compiler commands now explicitly use
`ESNext,DOM,DOM.Iterable`, matching the generated declaration. Rollup warnings
are not treated as type-check success.

The false-positive audit then found that package self-compilation alone still
accepted hooks that consistently declared `Promise<void>` and discarded the
facade receipt. Version 10's final test patch adds a public consumer of both
exported hook types. The cleaned receipt-discard mutant now fails that consumer,
while an implementation that infers the receipt with
`ReturnType<SQLSync["mutate"]>` passes.

The unchanged Dockerfile was rebuilt as the v10 image. The final eight-state
matrix, static audit, fifteen mutants, seven variations, and a repaired
non-reference run-1 replay all pass. Unchanged old-prompt runs fail at distinct
boundaries and do not count toward the fresh version-10 0/10 batch.

A version-11 editorial review identified the opening sentence as redundant with
the concrete API directives that immediately follow it. The sentence was
deleted. No behavior, test, reference implementation, or Dockerfile changed;
the prompt hash, immutable version, verification tag, and calibration counter
were refreshed. The full gates, false-positive matrix, positive variations, and
representative solver replays were rerun under version 11.

Version 11 then solved all four unhinted working-pool runs. Every official log
selected the synthetic portable facade probe because pnpm, wasm-pack, and the
Wasm target were unavailable. All four patches also passed when replayed
against the old real browser probe in the frozen full-tool image, so the result
was legitimate but insufficiently discriminating.

Version 12 removes the portable probe and makes the generated Wasm/facade
loopback unconditional. The Dockerfile now verifies the required browser build
stack during construction and no longer runs tests while building the image.
The public task adds `SQLSync.subscribeSyncState`: current state, later local
mutation and coordinator acknowledgement observations, and unsubscribe. It also
rephrases the LSN contract around lossless non-`number` behavior without
requiring generated-type provenance.

The first subscription mutation trial found a real false positive. Removing
the explicit timeline-change notification still passed because a late
connection-status event carried a post-mutation snapshot. The browser probe now
waits for a stable connected state and considers only callbacks delivered after
the mutation begins. The reference passes, the timeline-notification mutant is
killed, and cloned event values plus renamed private subscription messages
remain accepted.

A version-13 interface review found that the tests import a named
`SyncStateSubscription`, while the prompt described only a structural callback.
The public description now names that export. The same review requested less
inline opening detail, so the redundant opening layouts were removed without
changing behavior. Version 13 was superseded before verification.

The next review correctly identified three public source/order contracts that
must be stated because the tests exercise them: public Rust struct literals for
`MutationReceipt` and `SyncState`, directly readable state fields, and initial
subscription delivery before establishment resolves. Version 14 states each
contract explicitly.

The browser probe did not require public values to be BigInt—it compared values
returned by the public API—but its raw protocol fixture used BigInt constants
and `Buffer` BigUInt64 helpers. Version 14 removes those entirely and writes
high `u64` frames from decimal text via two 32-bit words. The positive facade
variation that exports public `bigint` values still passes, confirming carrier
neutrality.

The Docker warning was also resolved: the required Olympus Rust base now runs
an explicit locked all-feature Cargo workspace build and checks that the
committed pnpm lock exists before frozen installation. The exact image build
and all offline gates pass. Apt package versions remain an acknowledged soft
warning because the base/repository locks and tool checks are reproducible
controls, while inventing distribution package pins would be brittle. A
transient Rosetta mutex affected one disposable test container; it was
discarded and the full clean matrix was rerun successfully.

A later evaluator reported that plain `cargo test` could fail while starting
the `sqlsync-wasm` doctest harness because rustdoc referenced a missing
`target/debug/deps/libsqlsync.rlib`. The exact v14 image did not reproduce the
failure in pristine, solution-only, or combined states, but repository
inspection showed that the Wasm bridge contains no doctest examples and its
host harness always runs zero cases. Version 15 marks only that harness
`doctest = false` in the injected test manifest. Plain offline
`cargo build && cargo test` then passes all 23 core tests, four focused
integrations, workspace targets, and every remaining crate doctest. The full
eight-state gate matrix also passes with no JUnit skip.

The clean image is independently hardened: after worker packaging, Docker runs
a targeted locked host build of `sqlsync` and asserts the exact un-hashed rlib
exists. Clean-repository plain `cargo build && cargo test` now passes as well,
including the original empty Wasm doctest harness before `test.patch` is
injected. Docker still runs no tests during construction.

The operator explicitly deferred the false-positive audit for this round. That
direction is recorded rather than silently carrying version-14 mutation
results into the revised artifact; version 15 is therefore not yet immutable
or submission-ready.

The version-15 trajectory batch then exposed two substantive browser-test
gaps. Every browser log left `applied` undefined because the fake coordinator
only acknowledged upload; it never applied the mutation and returned storage
for a worker rebase. Also, the lower-reconnect and empty-following subscription
checks searched all prior snapshots even though their target values had
already appeared, allowing stale history to satisfy a missing fresh callback.

Version 16 adds a native coordinator helper behind the existing WebSocket
replication protocol. The browser probe first observes acknowledgement without
application, explicitly runs coordinator work, returns its storage frame, and
then requires the worker's public `applied` field to equal the receipt after
rebase. The two subscription assertions record array boundaries immediately
before their transitions and search only the resulting slices. The reference
and the two legitimate trajectory architectures pass; the two declaration-
only bigint implementations still fail at runtime high-LSN serialization.

No applied subscription event, private worker tag, exact LSN carrier, or helper
layout is required. The false-positive audit remains intentionally unrun at the
operator's request, so version 16 is verified but not submission-ready.

A fairness reviewer then interpreted the decimal strings used to build private
high-LSN protocol frames as required public string values. The runtime checks
were already public-to-public comparisons, but the fixture presentation was
ambiguous, and the pinned repository already uses public `bigint` SQL values
without establishing any browser LSN convention.

Version 17 deletes the decimal parser and every high decimal literal from the
browser source. Three wire-only `{ high, low }` constants encode adjacent
values above `2^53`; public LSNs are never parsed, converted, or compared to
those constants. Static checks reject reintroduction of decimal or BigInt high-
value fixtures. The full matrix and trajectory replays retain the same expected
outcomes, demonstrating that the two bigint-labelled near-passes fail because
their runtime serde path still emits JavaScript number—not because the suite
requires strings.

At operator direction, false-positive mutant and positive-variation checks are
now disabled by default for this problem. They were not run for version 17,
which remains audit-pending and not submission-ready under workspace policy.

A later fairness report correctly noted that the browser test used
`"applied" in state` before and after application. The public value is optional:
a missing property and an explicit `undefined` are equivalent while the
watermark is unavailable. Version 18 removes both membership assertions. It
retains ordinary field access and pre-application inequality, while the post-
rebase equality itself proves that the receipt LSN is present when required.
The compile-time `Lsn | undefined` consumer is unchanged. The complete offline
matrix, plain Cargo, and trajectory replays preserve their expected outcomes;
false-positive checks were not run at operator direction.

The next Rust fairness review found that whole-value `assert_eq!` calls made
`MutationReceipt` and `MutationStatus` require `Debug` and `PartialEq`, while
every direct status invocation supplied an owned receipt. None of those
conveniences is part of the behavioral contract. Version 19 compares receipt
fields with boolean assertions and matches status variants structurally. A
nested public-consumer probe compile-checks the owned call form, otherwise the
shared-reference form, then executes only the supported form; a runtime failure
never triggers fallback. A borrowed-only reference variant with both trait
derives removed passes. The complete offline matrix, plain Cargo, and trajectory
replays preserve their expected outcomes. False-positive checks were not run at
operator direction.

A subsequent browser review found that applied progress was verified only by
polling, so a worker could omit the corresponding live subscription event. The
coordinator-backed flow now subscribes before mutation, records a callback
boundary immediately before application messages reach the worker, and
requires a later callback whose `applied` value equals the receipt. Direct
polling remains an independent check.

The same review cycle found that reducer rejection stopped at the Rust core
and that `SyncState::status` lacked an absent-local case. Version 20 sends one
malformed mutation through the real facade, requires the promise to reject,
checks unchanged polled local progress, and inspects subscription observations
through a later acknowledgement callback for any false local advance. The
signature-adaptive Rust consumer constructs a same-timeline state with
`local: None` and populated downstream watermarks and requires `None`.
Formatting, static checks, all eight offline gates, plain Cargo, and the four
trajectory replays pass. False-positive checks remain intentionally unrun at
operator direction.

The next review identified that initial subscription delivery was checked only
for occurrence, the exact inclusive Received boundary was missing, and the
reference reused acknowledgement progress signaling for connection-status
events. Version 21 compares both empty and populated initial callbacks with
contemporaneous public snapshots, adds the equality boundary, and separates
progress from connection signaling. It also covers fresh empty-at-zero
replacement and two-subscriber unsubscribe isolation with phase-local callback
slices. The full reference gates pass, but all ten version-20 working-pool
solutions also pass, so version 21 was abandoned as insufficiently difficult.

Version 22 adds the documented browser `MutationStatus` export and
`SQLSync.mutationStatus` method. The real generated-worker test covers local,
received, and applied stages and rejects foreign-timeline and above-local
receipts using only opaque public values. Representative historical solvers
fail specifically because that new public seam is absent. All static,
patch-state, browser, Cargo, and doctest checks pass. False-positive checks
remain intentionally unrun at operator direction, so version 22 is verified
but not submission-ready.

The supplied version-22 batch then produced eight legitimate passes and two
runtime-precision failures. The review's public-type finding is valid: the old
consumer could accept `any` aliases for receipt, state, and status. Version 23
adds structural declaration checks without requiring `interface` syntax,
mutable fields, one timeline-key spelling, or a generated-type provenance.

Two behavioral gaps were also accepted. Browser status had only been checked
at equality even though it is a separately implementable public seam, so the
real coordinator flow now classifies an older receipt after a newer watermark
is received and applied. Precision checks now cross the unsigned half of the
Rust `u64` range with two adjacent opaque public values and round-trip them
through the facade. The suggested `BigInt(publicLsn)` oracle was rejected
because it would exclude documented structured lossless carriers. The
re-entrant self-unsubscribe fan-out probe was also rejected: the reference
shares that behavior and neither the prompt nor repository establishes a
re-entrant dispatch guarantee.

Version 23 passes formatting/static checks, the full eight-state offline
matrix, plain locked offline Cargo build/test, and a representative legitimate
version-22 replay. At operator direction no false-positive mutant or variation
suite was run, so this evidence does not make the revision immutable or
submission-ready.

A later Docker reviewer incorrectly claimed that rustup's toolchain installer
does not accept `--target`; the installed CLI explicitly documents that option.
Version 24 nevertheless adopts the reviewer's separate `rustup target add`
spelling because it is equivalent and avoids the false rejection. The apt
warning was valid as a reproducibility concern: four listed packages were
already inherited from the mandatory base, so they were removed from the
install command and the remaining direct `clang` package was pinned.

The first v24 image was accidentally built from a linked local worktree. Its
Docker build and pristine gate passed, but the copied `.git` file referenced a
host-only worktree path, so later patch-state gates failed before applying any
artifact. Rebuilding the identical Dockerfile from a standalone clone fixed
the context issue. The final image, all eight offline gates, static audit, and
plain combined locked offline Cargo build/test pass.

A version-24 fairness review found that the declaration consumer and fresh
empty-at-zero browser flow selected JavaScript `undefined` as the only absent
`SyncState` watermark representation. The prompt specifies optional progress
but does not select `undefined` over `null`, and the pinned worker surface
already uses both sentinels in public data types. Version 25 accepts only
`null` or `undefined` for absence while still requiring an exact exported
`Lsn` when present. The same helper now governs polling and subscription
presence checks, preventing a partial relaxation. Static checks and the exact
eight-state matrix pass; false-positive and variation suites were intentionally
not run at operator direction.

A version-25 coverage review correctly observed that comparing the initial
subscription callback only with `syncState` allowed both public surfaces to
agree on fabricated progress. Version 26 directly requires absent local,
received, and applied values for the fresh callback and poll. The proposed
exact-`u64::MAX` acknowledgement was not adopted: pinned pre-task
`LsnRange::next()` computes `last + 1`, so that fixture overflows before the
feature boundary. The real browser lane instead carries `u64::MAX - 1`, whose
successor is representable, through observation and classifier input. All
eight normal states pass; false-positive and variation suites remain unrun at
operator direction.

The version-26 `agent-runs7` batch then produced seven legitimate passes. Run
1 revealed a real surviving defect: it cleared `received` when a connect task
started, but every reconnect fixture immediately returned a range and hid the
transient regression. Version 27 first accepts a fresh socket while withholding
its range, then requires the retained acknowledgement to remain visible before
delivering the replacement range. The original run-1 patch fails this exact
boundary; run 2 passes.

The same trajectory review identified four independent public gaps. The real
facade now keeps two document subscriptions active during separate mutations,
counts only opaque outer worker requests across an idle interval to reject
polling, checks small receipt/state LSNs for JavaScript `number`, and exercises
timeline-filtered applied state after cross-timeline storage replication. A
suggested fake-worker subscription probe was rejected because its exact inner
tags and wrappers are private and had already been found unfair. All eight
normal gates pass at `/tmp/sqlsync-gates.HoAUmc`; false-positive and variation
suites were not run at operator direction.
