# Runs

Immutable versions 9 and 11 each received four unhinted working-pool runs; both
batches were 4/4 legitimate solves. Each result exceeds the 50% difficulty cap.
Version 12 therefore added the trajectory-grounded live-observation boundary
and requires the real generated-worker browser lane in every passing
environment. Version 22 added public browser mutation classification and its
ten-run batch produced eight legitimate passes plus two runtime-precision
failures. Version 23 hardened three remaining public boundaries. Version 24 was
an environment-only Docker portability revision. Version 25 removed an
unstated JavaScript absence-sentinel constraint. Version 26 checked a truly
empty fresh snapshot and a reachable near-ceiling LSN; its ten-run batch
produced seven legitimate passes, one broad failure, and two runtime-Wasm
precision failures. Versions 27 through 29 hardened the public boundaries
exposed by later trajectory review. Version 30 closes the local-mutation
unsubscribe path and replaces callback settling sleeps with causal barriers.
Version 31 adds the independent browser inclusive-Received boundary. Version 32
adds registration isolation and mutation rollback boundaries but leaves 4/5
historical solutions passing. Version 33 adds re-entrant callback-dispatch
isolation; its completed batch produced three legitimate passes and seven
genuine behavioral failures. Version 34 repairs prompt precision and JUnit
diagnostics without changing the behavioral suite. Version 35 directly checks
ordinary peer-removal silence. Version 36 closes initial-delivery ordering and
cross-source unsubscribe gaps. Version 37 reorganizes the prompt and adds
runtime receipt-forwarding checks for both framework hooks. The user confirmed
external acceptance of version 37 on 2026-08-07.

All historical `agent-runsN` paths mentioned below now refer to members of
`archive/sqlsync-observed-sync-state/agent-runs.tar.gz`; no raw trajectory
directory remains active.

| Version | Working-pool/platform completed | Solves | Status |
|---|---:|---:|---|
| 5 | 0/10 | 0 | Historical construction |
| 6 | 0/10 | 0 | Historical construction |
| 7 | 0/10 | 0 | Historical construction |
| 8 | 0/10 | 0 | Historical construction |
| 9 | 4/10 | 4 | Abandoned as too easy |
| 10 | 0/10 | 0 | Superseded by editorial version 11 |
| 11 | 4/10 | 4 | Abandoned as too easy |
| 12 | 0/10 | 0 | Superseded after exact verification |
| 13 | 0/10 | 0 | Unverified editorial intermediate |
| 14 | 0/10 | 0 | Superseded after exact verification |
| 15 | 4/10 | 2 | Abandoned after trajectory-informed browser hardening |
| 16 | 0/10 | 0 | Superseded by representation-neutral fixture version 17 |
| 17 | 0/10 | 0 | Superseded by optional-property fairness version 18 |
| 18 | 0/10 | 0 | Superseded by Rust API-shape fairness version 19 |
| 19 | 0/10 | 0 | Superseded by browser rollback/subscription version 20 |
| 20 | 0/10 | 0 | Superseded after version-21 trajectory hardening |
| 21 | 0/10 | 0 | Abandoned after all 10 version-20 solver patches still passed |
| 22 | 10/10 | 8 | Abandoned as too easy after two runtime-precision failures |
| 23 | 0/10 | 0 | Superseded by environment-only version 24 |
| 24 | 0/10 | 0 | Superseded by optional-absence fairness version 25 |
| 25 | 0/10 | 0 | Superseded by fresh-snapshot and near-ceiling version 26 |
| 26 | 10/10 | 7 | Abandoned as too easy after one broad and two runtime-precision failures |
| 27 | 0/10 | 0 | Superseded after version-28 transition hardening |
| 28 | 0/10 | 0 | Superseded by inclusive-Local version 29 |
| 29 | 0/10 | 0 | Superseded by unsubscribe/determinism version 30 |
| 30 | 0/10 | 0 | Superseded by browser inclusive-Received version 31 |
| 31 | 5/10 | 5 | Abandoned as too easy after the run-9 batch |
| 32 | 0/10 | 0 | Superseded by callback-dispatch version 33 after 4/5 historical survival |
| 33 | 10/10 | 3 | Abandoned after artifact-review reporting and wording findings |
| 34 | 0/10 | 0 | Superseded by teardown-silence version 35 before calibration |
| 35 | 0/10 | 0 | Superseded by subscription-order version 36 before calibration |
| 36 | 0/10 | 0 | Superseded by description/hook-runtime version 37 before calibration |
| 37 | 0/10 | 0 | Accepted externally 2026-08-07; eight-state matrix passed; operator-disabled audits remain recorded as absent |

Version-9 run IDs are `rd79fay03276m4gaq9e83qg4258bqn53`,
`rd7fqbh5fp7dqcrd0y3q3mz6y98bpeh0`,
`rd7b9pxw989edd5j75sam09pyh8bq3zx`, and
`rd7cta2aj6r3srbht4kccyqkqs8bp4g5`. Their raw bundles are preserved in
`agent-runs1/Nova_Nova_1` through `Nova_Nova_4`.

Unchanged replay against versions 10 and 11 fails all four old-prompt patches at
different full-lane boundaries. Run 1 passes after only the newly specified
empty-range observation is corrected, establishing a non-reference passing
architecture. These diagnostic replays do not count as calibration runs for
later versions.

Version-11 bundles are preserved in `agent-runs2/Nova_Nova_1` through
`Nova_Nova_4`. Their official graders all selected `PORTABLE_FACADE_PROBE`
because solver images lacked pnpm, wasm-pack, and the Wasm target. Replaying the
same four patches in the frozen full-tool image also passes the old real worker
probe, confirming that v11 was genuinely too easy rather than merely
under-tested. Unchanged v11 patches do not expose the version-12 subscription
API and are representative failing replays, not version-12 calibration runs.

Version 13 named the public `SyncStateSubscription` export but was superseded
before verification. Version 14 additionally documents the public Rust struct
layouts and pre-resolution initial callback, removes BigInt from the private
protocol fixture, and rebuilds the Docker environment with explicit locked
Cargo and pnpm steps. Its eight-state matrix, 19-mutant audit, eight positive
variations, and four old-solver replays pass; these are construction evidence,
not solver runs. Version-14 calibration remains exactly 0/10.

Version 15 disables only the zero-case `sqlsync-wasm` host doctest harness to
remove a cache-dependent missing-rlib failure. Its complete eight-state gate
matrix and a separate plain `cargo build && cargo test` replay pass. At the
operator's direction, the false-positive mutants and positive variations were
not rerun. Its four supplied unhinted Nova runs produced two legitimate passes
and two near-passes that failed only because their declared `bigint` LSN type
still serialized runtime Rust `u64` values as JavaScript numbers. Run IDs are
`rd722372r6jzn8ntbrs7a8cebh8bsy42`,
`rd71vkvej51gknrqtnq9je0d698bs5bg`,
`rd75n29cbayz2h0s2gmes51c6n8bsbgm`, and
`rd76aed695qqn1p3tyeqn5tjgh8brdyz`; the raw bundles are in `agent-runs3`.

Version 16 fixes two browser-suite gaps found from those trajectories. It
drives coordinator application and storage replication back through the real
generated worker before asserting `SyncState.applied`, and it restricts the
lower-reconnect and empty-following subscription searches to callbacks emitted
after each transition begins. The exact eight-state matrix passes. Replaying
the four version-15 patches preserves the 2-pass/2-runtime-precision-failure
split, but those replays are construction evidence rather than version-16
calibration. Per operator direction, version 16's false-positive audit remains
pending, so it is not submission-ready and starts at exactly 0/10.

Version 17 removes the last appearance of a string-carrier implication from
the private high-LSN fixture. Raw replication values are assembled from fixed
32-bit words; returned public LSNs are never decoded or compared to those
words. The eight-state matrix and plain Cargo pass. Replaying all four supplied
patches preserves runs 2/3 as passes and runs 1/4 as runtime-serde failures.
Those replays remain construction evidence, not version-17 calibration, which
starts at 0/10. False-positive mutant/variation runs are operator-disabled by
default, so version 17 remains audit-pending and not submission-ready.

Version 18 removes only the two runtime `in`-operator assertions on optional
`SyncState.applied`. Missing and explicit-`undefined` representations are now
equivalent before application; post-rebase equality still requires the actual
receipt LSN, and the generated TypeScript consumer still reads the public
field. The exact eight-state matrix, plain Cargo, and all four trajectory
replays preserve the version-17 outcomes. These are construction checks, not
calibration; version 18 starts at 0/10. False-positive checks were not run at
operator direction, so it remains audit-pending and not submission-ready.

Version 19 removes hidden `Debug`/`PartialEq` requirements from receipts and
statuses and permits `SyncState::status` to accept either an owned receipt or a
shared reference. Classification now runs through a compile-selected nested
public consumer, while dynamic replication tests continue to assert snapshot
fields directly. A borrowed-reference variation with both convenience traits
removed passes. The eight-state matrix, plain Cargo, and four trajectory
replays retain the version-18 outcomes. These are construction checks, not
calibration; version 19 starts at 0/10. False-positive checks were not run at
operator direction, so it remains audit-pending and not submission-ready.

Version 20 requires a fresh applied-stage subscription callback after
coordinator storage returns and rebase completes. It also drives one malformed
mutation through the real reducer/worker/facade path, requiring rejection and
unchanged local progress in polling and subscription observations, and covers
the classifier's absent-local bound. The eight-state matrix, formatting/static
checks, plain Cargo, and all four trajectory replays preserve runs 2/3 as passes
and runs 1/4 as the same runtime high-`u64` serde failures. These are
construction checks, not calibration; version 20 starts at 0/10. False-positive
checks were not run at operator direction, so it remains audit-pending and not
submission-ready.

Version 21 validates initial callback contents for empty and populated
snapshots, the exact inclusive `Received` boundary, fresh empty-at-zero range
replacement, two-subscriber unsubscribe isolation, and absence of duplicate
connection-status notifications for acknowledgement-only progress. Its exact
eight-state matrix and plain Cargo checks pass. All ten legitimate
`agent-runs4` patches also pass unchanged, so version 21 was abandoned as
insufficiently discriminating. Those replays are construction evidence, not
version-21 calibration.

Version 22 adds the documented worker `MutationStatus` export and public
`SQLSync.mutationStatus` classifier. The real generated-worker lane exercises
Local, Received, and Applied transitions plus foreign-timeline and above-local
rejection using opaque returned LSN values. Its static audit, eight-state
matrix, and plain locked offline Cargo build/test pass. Representative prior
solutions 1, 3, and 9 fail only because the newly documented export and method
are absent.

The supplied version-22 batch is preserved in `agent-runs6`. Runs 1, 2, 3, 4,
6, 7, 8, and 10 are legitimate passes; runs 5 and 9 fail because their public
declarations say `bigint` while runtime Rust `u64` serialization still emits a
JavaScript number. `agent-runs5` is a byte-identical mirror and is not counted
as another batch. Version 22 therefore closes at **8/10** and is abandoned as
too easy.

Version 23 rejects `any`-shaped worker declarations, checks inclusive browser
classification with an older real receipt after a newer watermark is visible,
and carries two adjacent opaque acknowledgements in the upper half of the
Rust `u64` domain through the public classifier input. The reference and a
representative legitimate version-22 solution pass. The exact eight-state
matrix and plain locked offline Cargo build/test also pass. This is
construction evidence, not calibration; version 23 starts at **0/10**. At
operator direction the mandatory false-positive audit was not run, so the
revision remains audit-pending, non-immutable, and not submission-ready.

Version 24 changes no participant behavior. It replaces the already-valid
inline rustup target option with a separate toolchain-qualified `rustup target
add`, removes four redundant apt installs inherited from the mandated base, and
pins the remaining direct `clang` package. The rebuilt standalone-clone image,
static audit, exact eight-state offline matrix, and plain combined locked
offline Cargo build/test pass. This is construction evidence, not calibration;
version 24 starts at **0/10** and remains audit-pending, non-immutable, and not
submission-ready because false-positive checks were not run at operator
direction.

Version 25 removes an unstated browser representation constraint. Concrete
`SyncState` progress fields may use `null`, `undefined`, or both for absence,
while a known value remains exactly the exported lossless `Lsn`. Runtime
presence checks, fresh empty-at-zero replacement, and both subscription
callbacks use the same sentinel-neutral rule. The static audit and exact
eight-state offline matrix at `/tmp/sqlsync-gates.jB6WD7` pass. This is
construction evidence, not calibration; version 25 starts at **0/10** and
remains audit-pending, non-immutable, and not submission-ready because the
operator excluded false-positive and variation runs.

Version 26 requires the initial fresh-document callback and poll to contain no
local, received, or applied progress, closing the agreement-with-an-equally-
wrong-snapshot gap. It also sends a real range ending at `u64::MAX - 1`, the
strongest value whose successor is representable by the pinned protocol, and
round-trips its opaque public value through the browser classifier. An exact
maximum range is rejected because upstream `LsnRange::next()` overflows before
the observed-state boundary. The static audit and exact eight-state matrix at
`/tmp/sqlsync-gates.yfy2AN` pass. Its later batch closed at **7/10** legitimate
solves, so version 26 is abandoned as too easy; false-positive and variation
runs remained excluded by the operator.

Construction, reference verification, and mutation trials are not solver
calibration runs. If any participant artifact changes, the next immutable
version must repeat all gates and begin again at 0/10.

The supplied version-26 batch is preserved in `agent-runs7`. Runs 1, 2, 4, 5,
6, 7, and 8 are legitimate passes; run 3 is a broad subscription failure; and
runs 9 and 10 fail at their unsupported `u128` Wasm serialization path despite
declaring a `bigint` public carrier. Version 26 therefore closes at **7/10**
and is abandoned as too easy.

Version 27 retains the full real-worker lane and adds five distinct public
boundaries: an unanswered fresh socket must not erase the last observed
acknowledgement; two simultaneous document subscriptions are isolated; an
idle subscription cannot poll the worker; small receipt and state LSNs are
also non-`number`; and applied progress is filtered to the snapshot timeline.
The static audit and exact eight-state matrix pass at
`/tmp/sqlsync-gates.HoAUmc`. Replaying version-26 run 1 now fails at the
unanswered-reconnect boundary, while the independently implemented run 2
passes. These replays are construction evidence, not version-27 calibration.
No false-positive mutant or variation suite was run, so version 27 remains
audit-pending, non-immutable, **0/10**, and not submission-ready.

The supplied version-27 batch is preserved in `agent-runs8`. Runs 1 through 4
are legitimate passes; run 5 is a broad browser failure caused by keying
`Uint8Array` document IDs by object identity, so its initial subscription event
cannot find the facade listener. At 4/5 the batch is abandoned on the
four-run harden checkpoint and operator direction; version 28 restarts at
**0/10**.

Version 28 combines boundaries that version 27 exercised only separately. The
Rust and real browser flows now allocate a second mutation after the first
applied prefix is rebased away, require a successor receipt, and observe a
mixed snapshot with newer local/received progress and older applied progress.
The browser classifier rejects a receipt while local progress is absent, the
subscription lifecycle is re-established after the listener count reaches
zero, and the TypeScript consumer proves timeline IDs and handler structure.
The static audit and exact eight-state matrix pass at
`/tmp/sqlsync-gates.tIXLat`. All four legitimate run-8 patches pass unchanged;
run 5 retains its original missing-initial-snapshot failure. These are
construction replays, not version-28 calibration. No false-positive mutant or
variation suite was run, so version 28 remains audit-pending, non-immutable,
**0/10**, and not submission-ready.

Version 29 adds the missing Local-only classifier interval to the signature-
adaptive Rust consumer. With `local = 5`, `received = 3`, and `applied = 1`, a
same-timeline receipt at LSN 4 must classify as Local; equality-only Local
implementations can no longer pass. The static audit and exact eight-state
matrix pass at `/tmp/sqlsync-gates.wM2rXV`. Representative run-8 borrowed and
generic-`Borrow` status implementations both pass the strengthened consumer at
`/tmp/sqlsync-v29-status-replays.AQ0e23`. These are construction replays, not
version-29 calibration. No false-positive mutant or variation suite was run,
so version 29 remains audit-pending, non-immutable, **0/10**, and not
submission-ready.

Version 30 exercises unsubscribe against a successful local mutation as well
as a coordinator acknowledgement. A second active listener provides the
positive delivery barrier and must observe the new receipt while the removed
listener remains unchanged. The browser probe no longer uses 25 ms callback-
settling sleeps: document isolation is checked after both documents' own
mutation deliveries, unanswered-reconnect history after both listeners receive
the later fresh range, and acknowledgement unsubscribe after the remaining
listener receives that same change. The static audit and exact eight-state
matrix pass at `/tmp/sqlsync-gates.aLYhVY`. Legitimate run-8 solutions 1 and 4,
which use different subscription protocols, both pass the full focused lane.
These are construction replays, not version-30 calibration. No false-positive
mutant or variation suite was run, so version 30 remains audit-pending, non-
immutable, **0/10**, and not submission-ready.

Version 31 adds an older-receipt browser classification while Received is
ahead, Applied is absent, and a later local receipt proves the target receipt
is strictly older. This rejects equality-only facade classifiers independently
of the Rust classifier. Exact `u64::MAX` remains deliberately untested because
the pinned pre-feature protocol overflows while calculating the exclusive
successor of a non-empty range ending there; `u64::MAX - 1` remains the
strongest reachable real-protocol value. The static audit and exact eight-state
matrix pass at `/tmp/sqlsync-gates.f9aYVR`. Legitimate run-8 solutions 1 and 4
both pass the complete focused lane. These are construction replays, not
version-31 calibration. No false-positive mutant or variation suite was run,
so version 31 remains audit-pending, non-immutable, **0/10**, and not
submission-ready.

The supplied version-31 batch is preserved in `agent-runs9`. All five runs are
legitimate full passes, despite using materially different worker registration,
facade fan-out, classifier, and lossless-LSN designs. Version 31 therefore
closes at **5/5** and is abandoned as under-discriminating. Raw trajectory
review found one public shortcut in run 5: registering a second listener emits
its initial snapshot as a document-wide event and spuriously invokes the first
listener even though state did not change.

Version 32 rejects that shortcut by checking same-document registration and
removal isolation. It also classifies a strictly older receipt as Local through
the real browser facade, requires a reducer-rejected mutation to emit no
sync-state callback, and proves in Rust that the next successful mutation uses
the immediate successor LSN. The prompt now explicitly states those public
failure and registration semantics. The static audit and exact eight-state
matrix pass at `/tmp/sqlsync-gates.NLhyRy`. The reference and run-9 solution 1
through 4 pass the complete focused lane, while run-9 solution 5 fails at the
new peer-registration oracle. Runs 2-4 are recorded at
`/tmp/sqlsync-v32-run9-234.bZIgNJ`. These are construction replays, not version-32
calibration. No false-positive mutant or variation suite was run, so version
32 remains audit-pending, non-immutable, **0/10**, and not submission-ready.

Version 32's complete historical replay closes at 4/5 survivors: run-9
solutions 1-4 pass and solution 5 fails registration isolation. It is abandoned
as under-discriminating; those outcomes do not count toward version 33.

Version 33 makes callback-dispatch re-entrancy a narrow public guarantee. When
one subscription removes itself while handling a real state change, another
still-active subscription must receive that same snapshot, while only the peer
receives a causally later change. The reference now iterates a stable subscriber
view. The static audit and exact eight-state matrix pass at
`/tmp/sqlsync-gates.F8PYQU`. Historical run-9 solutions 1 and 2 pass the full
focused lane; solutions 3 and 4 time out waiting for peer delivery during the
self-unsubscribe callback; solution 5 retains its earlier registration-
isolation failure. The 2/5 split is construction replay evidence, not version-
33 calibration. No false-positive mutant or variation suite was run, so
version 33 remains audit-pending, non-immutable, **0/10**, and not submission-
ready.

The subsequent version-33 working-pool batch completed at 3/10 legitimate
solves. Runs 1, 2, and 7 passed; the other seven exposed JavaScript-number LSNs,
duplicate unchanged connection-status notifications, premature received-state
clearing before a fresh peer Range, an unsupported Wasm `u128` ABI, or
document subscriptions keyed by `Uint8Array` object identity. Every baseline
passed and all adjudications found the task clear, deterministic, challenging,
and fair. The successful production patches changed 11-13 files and added
454-508 lines. These results close version 33 and do not transfer to a revised
artifact.

Version 34 removes the unverified word "documented" from the otherwise
unchanged lossless non-number LSN contract. Its runner now captures the complete
selected lane and embeds XML-sanitized, escaped diagnostics in JUnit
`system-out`, while continuing to stream them to the terminal. The static audit
and all eight offline patch states pass at `/tmp/sqlsync-gates.W5zuEv`, including
content checks for successful Cargo/browser reports and the expected missing-
API and missing-tool reports. No behavioral test or reference code changed.
No false-positive mutant or variation suite was run, so version 34 is
audit-pending, non-immutable, **0/10**, and not submission-ready.

Version 35 closes the remaining stated subscription-lifecycle gap. With two
established same-document listeners active, the real browser lane adds and then
ordinarily removes a disposable third listener. After a public `syncState`
request/reply barrier, neither established listener may have received another
snapshot. This is distinct from add-time isolation, self-removal during an
in-flight delivery, and excluding a removed listener from later changes. The
static audit and all eight offline patch states pass at
`/tmp/sqlsync-gates.Eh0GQ7`; no prompt, reference, solution, or Docker change was
required. No false-positive mutant, variation, or solver replay was run, so
version 35 is audit-pending, non-immutable, **0/10**, and not submission-ready.

Version 36 adds a real registration-concurrency oracle that rejects a current
initial snapshot followed by a superseded buffered state. It also retains a
removed listener's observation count through later coordinator-received and
storage-applied changes. The exact eight-state matrix passes at
`/tmp/sqlsync-gates.uMYxUv`, and the panel-identified buffered facade fails the
new ordering boundary in isolation. It was superseded before calibration.

Version 37 preserves the same behavior while grouping the participant contract
by layer and adding runtime React/Solid hook probes. The exact eight-state
matrix passes at `/tmp/sqlsync-gates.jy2dLy`, including both framework receipt
returns and the real worker browser lane. No reference production change was
needed. The user confirmed acceptance on 2026-08-07. Raw batches 1-11 and the
retired planning records are preserved under
`archive/sqlsync-observed-sync-state/`; acceptance does not rewrite the
historical 0/10 calibration count or claim the operator-disabled audits ran.
