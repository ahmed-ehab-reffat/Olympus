# SQLSync observed mutation progress

Status: **accepted and archived 2026-08-07; canonical version 37**

Repository: `orbitinghail/sqlsync`

Pinned commit: `7dc1af6b082023982fd2697f913f5b27453747f1`

Production language: Rust, with Rust/Wasm and TypeScript public-API bridge
changes.

Task type: feature request.

## Acceptance and archive

The user confirmed external acceptance of version 37 on 2026-08-07. Its static
audit and all eight offline patch-state gates had passed at
`/tmp/sqlsync-gates.jy2dLy`. The pre-acceptance record remains explicit that a
fresh version-37 solver batch and the operator-disabled false-positive and
variation suites were not run; acceptance is recorded as an external outcome,
not inferred from those missing checks.

All eleven raw trajectory batches are preserved in
`archive/sqlsync-observed-sync-state/agent-runs.tar.gz`; the canonical package,
compact run/design records, prototype, upstream audit, and verification scripts
remain active. Transient planning/handoff files are preserved in the cold
archive rather than left in the active problem directory.

## Outcome

The task returns a timeline-bound receipt for each accepted mutation and
exposes conservative per-document local, coordinator-received, and locally
observed coordinator-applied watermarks. Version 22 exposes the same
timeline-bound, local-bounded classifier through `SQLSync.mutationStatus`.
Version 14 additionally exposes live
per-document observation: callers receive the current snapshot, later local
mutation, coordinator acknowledgement, and post-rebase applied changes, and
can unsubscribe.

The feature crosses local timeline allocation, destination-range
acknowledgements, coordinator application metadata, storage replication and
rebase, Wasm requests/events, generated declarations, the TypeScript facade,
and React/Solid hook returns.

## Version-35 evidence

- The prompt already says ordinary peer removal is not a state change, but the
  previous browser flow removed its last ordinary listener only after no active
  peer remained.
- The real generated-worker lane now removes a disposable same-document
  listener while two established listeners remain active. A public `syncState`
  request/reply barrier completes without either peer receiving a snapshot.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.Eh0GQ7`. The prompt, reference solution, solution patch,
  and Docker environment are unchanged.
- False-positive, variation, and solver-replay suites were not run at operator
  direction, so version 35 remains audit-pending, 0/10, and not submission-ready.

## Version-34 evidence

- Version 33's fresh calibration completed at 3/10 legitimate solves, with all
  ten baselines passing and seven genuine behavioral failures. Version 34 does
  not inherit those run counts and starts at 0/10.
- The LSN contract now requires a lossless non-JavaScript-number representation
  without imposing an unverified documentation deliverable.
- `test.sh --output_path` preserves the full selected-lane output in XML-safe
  JUnit `system-out` while continuing to stream it to the terminal. Successful
  base/new reports and expected missing-API/missing-tool failures are all
  content-checked.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.W5zuEv`. No SQLSync test, reference behavior, solution
  patch, or Docker environment changed.
- False-positive and variation suites were not run at operator direction, so
  version 34 remains audit-pending and not submission-ready.

## Version-33 evidence

- A sync-state listener may unsubscribe itself from inside its callback without
  suppressing the in-flight state for another active listener. A later local
  mutation reaches only the surviving listener.
- The reference facade dispatches over a stable subscriber view. The oracle
  uses real coordinator and local changes and does not prescribe worker tags,
  subscription IDs, or listener storage.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.F8PYQU`.
- Historical run-9 solutions 1-2 pass, solutions 3-4 fail the re-entrant
  delivery boundary, and solution 5 fails registration isolation. This 2/5 is
  construction replay evidence. Its later working-pool batch completed with
  three legitimate solves out of ten.
- Version 33 was abandoned after artifact review identified prompt wording and
  JUnit diagnostic quality issues; its 3/10 result remains historical evidence.

## Version-32 evidence

- Same-document listener registration and removal cannot notify a peer when
  document state did not change. Reducer rejection emits no state callback and
  consumes no LSN allocation, and the browser classifier covers an older Local
  receipt.
- All eight normal gates passed, but historical replay left run-9 solutions 1-4
  passing and rejected only solution 5. Version 32 was abandoned as under-
  discriminating.

## Version-31 evidence

- The real browser classifier now receives an earlier receipt after a later
  local mutation, while Received is ahead and Applied is absent, and must
  return `"received"`. Equality-only facade comparisons can no longer pass.
- Exact `u64::MAX` is not injected: the pinned protocol evaluates the
  exclusive successor of every non-empty received range and overflows before
  the feature can observe a maximum endpoint. The opaque `u64::MAX - 1` probe
  remains the strongest reachable real-protocol boundary.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.f9aYVR`. Legitimate run-8 solutions 1 and 4 pass the full
  focused lane.
- No prompt, Docker, or reference-solution change was needed. False-positive
  and variation suites were not run at operator direction, so version 31
  remains 0/10 and not submission-ready.

## Version-30 evidence

- Unsubscribe is now exercised against both documented event sources. After
  the first listener leaves, a successful local mutation must reach the second
  listener without changing the removed listener's history.
- All 25 ms negative callback-settling sleeps were removed. Document routing,
  unanswered-reconnect history, and unsubscribe absence checks now run after
  causally later positive subscription deliveries.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.aLYhVY`. Legitimate run-8 solutions 1 and 4 pass the full
  focused lane with document-level and per-subscription-ID protocols.
- No prompt, Docker, or reference-solution change was needed. False-positive
  and variation suites were not run at operator direction, so version 30
  remains 0/10 and not submission-ready.

## Version-29 evidence

- The signature-adaptive Rust status consumer now covers the Local-only
  interval: with local 5, received 3, and applied 1, receipt 4 must classify as
  Local. This rejects equality-only Local branches while preserving owned and
  borrowed receipt APIs.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.wM2rXV`. Representative run-8 borrowed and
  generic-`Borrow` implementations pass the focused replay at
  `/tmp/sqlsync-v29-status-replays.AQ0e23`.
- No prompt, Docker, or reference-solution change was needed. False-positive
  and variation suites were not run at operator direction, so version 29
  remains 0/10 and not submission-ready.

## Version-27 evidence

- Version 26 closed at 7/10 legitimate solves and was abandoned as too easy.
- A reconnecting socket that has not supplied a peer range must retain the
  previously observed acknowledgement in polling and subscriptions; its later
  range still replaces that knowledge.
- Two real documents are subscribed and mutated concurrently to verify routing
  isolation. An idle interval longer than the callback wait budget emits no
  host-to-worker requests; for an externally injected acknowledgement, the
  first bridge activity must be worker-to-host delivery. This distinguishes
  push from polling without naming private tags and still allows an
  event-triggered follow-up fetch.
- Small mutation receipts and local/received/applied state values are rejected
  when represented as JavaScript numbers. Existing upper-half and near-ceiling
  checks remain carrier-neutral.
- A Rust storage-replication flow proves that an applied row for timeline A is
  not reported by a snapshot whose active timeline is B.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.HoAUmc`. Version-26 run 1 fails specifically at premature
  acknowledgement clearing, while run 2 passes as a distinct implementation.
- False-positive and variation suites were not run at operator direction, so
  version 27 remains 0/10 and not submission-ready.

## Version-26 evidence

- The initial subscription callback and contemporaneous poll must both expose
  absent local, received, and applied progress for a fresh document. Absence
  remains neutral between `null` and `undefined`.
- The real protocol observes `u64::MAX - 1` and round-trips its opaque
  non-number public value through `SQLSync.mutationStatus`. Exact `u64::MAX` is
  not injected because pinned pre-task range code overflows while calculating
  its successor.
- The static audit and all eight offline patch states pass at
  `/tmp/sqlsync-gates.yfy2AN`. False-positive and variation suites were not run
  at operator direction. Its later batch closed at 7/10 legitimate solves, so
  version 26 was abandoned as too easy.

## Version-25 evidence

- Browser `SyncState` watermarks retain an exact exported `Lsn` when known but
  may use `null`, `undefined`, or both when absent. The public type checks remain
  anti-`any` and reject unrelated field members.
- The real worker probe uses that sentinel-neutral rule for every SyncState
  presence decision and for both subscriber callbacks after a fresh
  empty-at-zero reconnect. `mutationStatus` remains explicitly `undefined` for
  an unrelated receipt, as required by the prompt.
- The static audit and all eight offline patch-state gates pass at
  `/tmp/sqlsync-gates.jB6WD7`. False-positive and variation suites were not run
  at operator direction, so version 25 remains 0/10 and not submission-ready.

## Version-24 evidence

- The Dockerfile uses a separate toolchain-qualified rustup target command,
  inherits four packages already present in the mandated base, and pins its
  sole direct apt addition (`clang`). The complete standalone-clone image build
  succeeds.
- The exact eight-state offline matrix passes at
  `/tmp/sqlsync-gates.2MhIfk`, and a separate combined plain locked offline
  Cargo build/test passes. The v24 image identifier is
  `sha256:9a3df992a695a6c1c89cf87f619cb00c348d5d03b4a8dc581c809edb2fa0add3`.

- The version-22 working-pool batch closed at 8/10 legitimate solves. The two
  failures declared browser LSNs as `bigint` but still serialized runtime Rust
  `u64` values as JavaScript numbers. Version 23 restarts at 0/10.
- The generated TypeScript consumer rejects `any` for `MutationReceipt`,
  `SyncState`, `MutationStatus`, and their progress fields; it requires the
  documented exact status union and exported `Lsn` field types while accepting
  either established timeline-key spelling.
- The real browser flow creates two mutations and requires the older receipt to
  classify as received and then applied after the newer watermark is visible,
  establishing inclusive browser semantics independently of the Rust probe.
- Two adjacent wire acknowledgements at `0x8000000000000000` and
  `0x8000000000000001` must emerge as distinct non-number public values and
  round-trip through `SQLSync.mutationStatus`. The oracle treats both values as
  opaque and does not require string, bigint, or another carrier.

- The public worker exports `MutationStatus`; `SQLSync.mutationStatus` returns
  `"local"`, `"received"`, `"applied"`, or `undefined`. The real generated
  worker covers all three stages plus foreign-timeline and above-local
  rejection without decoding opaque public LSN values.
- Version 21 added exact initial-snapshot content, empty-zero reconnect,
  subscriber fan-out, exact Received-boundary, and connection-notification
  checks. All ten historical working-pool patches still passed, motivating the
  substantive version-22 facade classifier.

- The frozen `linux/amd64` image contains Node, pnpm 9.15.9, wasm-pack 0.13.1,
  and the Wasm Rust target. It explicitly runs locked workspace Cargo build,
  verifies `pnpm-lock.yaml`, completes frozen dependency/build steps, and
  asserts the final host `libsqlsync.rlib` used by rustdoc exists.
- All eight patch-state gates pass with networking disabled: pristine,
  tests-only base with full and stock tools, tests-only focused rejection,
  solution-only lint/full suite/package, combined focused, explicit missing-
  browser-tool rejection, and combined base.
- The combined focused lane always builds the reducer and generated Wasm worker
  and logs `BROWSER_PROBE`; there is no synthetic or skipped facade path.
- A native test coordinator now participates through the repository's existing
  replication protocol. The real worker exposes acknowledgement while applied
  remains absent, then exposes the receipt as applied only after coordinator
  work, returned storage replication, and local rebase.
- While applied progress is unavailable, the browser accepts either a missing
  property or explicit `undefined`. Ordinary field access still must not equal
  the receipt before application; post-rebase equality requires the receipt
  value, and the generated TypeScript consumer remains `Lsn | undefined`.
- The real facade/worker loopback covers held acknowledgement, disconnect
  retention, lower fresh-connection replacement, empty-following history,
  timeline agreement, adjacent exact LSNs above `2^53`, initial live state,
  post-mutation and post-acknowledgement delivery, and unsubscribe.
- The coordinator-backed applied flow now keeps an active subscription and
  requires a callback appended after application messages reach the worker;
  that callback must carry the receipt LSN as `applied` before polling is used
  as an independent confirmation.
- A malformed mutation now traverses the real reducer/worker/facade path. Its
  promise must reject, polled local progress must remain unchanged, and no
  subscription observation through the later acknowledgement barrier may
  publish advanced local progress.
- Lower-reconnect and empty-following subscription assertions search only
  callback slices emitted after each transition starts; stale earlier snapshots
  cannot satisfy either oracle.
- High replication fixtures are encoded only as wire-level 32-bit word pairs.
  The browser source contains no high decimal literal or BigInt conversion, and
  never parses or compares a public LSN against a fixture. All public values are
  treated opaquely, so string, bigint, word-pair, or another documented exact
  non-`number` carrier is admissible.
- The Rust public struct layouts and named `SyncStateSubscription` export are
  explicit. The initial callback is asserted immediately after subscription
  establishment resolves.
- Rust assertions accept direct, optional, or fallible `sync_state` returns and
  do not require receipts to be `Copy`, `Debug`, or `PartialEq`; status variants
  likewise need no comparison/debug traits. The status consumer compile-selects
  an owned or shared-reference receipt argument and executes the supported
  form. A borrowed-reference variation with both traits removed passes.
- The status consumer also rejects a same-timeline receipt when `local` is
  absent, including a constructed snapshot whose received/applied fields are
  populated.
- The browser fixture contains no BigInt literal/API and assembles raw high-u64
  frames directly from word pairs, while public assertions remain opaque.
- The injected test manifest disables the empty `sqlsync-wasm` host doctest
  harness, whose source has no doctest examples. Plain offline
  `cargo build && cargo test` now passes the 23 core tests, three focused
  integrations, all workspace unit targets, and every remaining crate doctest.
- All eight patch-state gates pass under version 24 at
  `/tmp/sqlsync-gates.2MhIfk`. The combined real-worker lane records a fresh
  applied subscription observation and a post-rebase applied watermark; the
  deliberately missing-tools lane fails rather than skips.
- Version 14 killed all 19 plausible mutants and passed eight legitimate
  implementation variations. Per operator direction, those suites were not
  rerun for version 23, so their results are historical rather than a current
  false-positive audit.
- The reference changes 14 production/example files with 476 additions and 22
  deletions. This is architecture evidence, not a solver-size forecast.
- A representative legitimate version-22 solver passes the strengthened lane.
  This is construction replay evidence, not version-23 calibration.
- `meta.md` SHA-256 is
  `ffa75c8ed84ae918f0818b4f590606497bf84178dd7142d78097225cf873fd41`;
  `test.patch` SHA-256 is
  `7de84be190e7f14d17da2ca8d60bda46bcbcb8ebe2443b9f60bab2c69a2e7082`;
  `solution.patch` SHA-256 is
  `6b485d541a17d2f3b00b4e9a771f5978d9cb6711af49836f360e661a5d238f49`.

The complete trajectory gate, requirement map, mutation ledger, rejected
mutants, solver replays, full-suite evidence, and immutable environment
identifiers are recorded in `DESIGN.md`.

## Calibration history

Versions 9 and 11 each solved 4/4 unhinted working-pool runs and were abandoned
as too easy. Every official v11 grader selected the portable facade path;
separate full-tool replay showed all four also passed its real browser probe.
Version 12 removed that fallback and added the distinct live-observation
boundary. Version 13 documented the named subscription type. Version 14 made
the concrete public Rust layouts and initial-callback ordering explicit,
removed BigInt from the private frame fixture, and rebuilt the required base
with literal locked Cargo and pnpm steps. Version 15 removes only a zero-case
Wasm host doctest harness whose cache-dependent startup could fail before tests
ran. Version 15 then produced two legitimate passes and two runtime-precision
near-passes. Version 16 adds real worker applied-state return and temporally
fresh reconnect subscription oracles. Version 17 removes the ambiguous decimal
wire fixture while preserving the same runtime discriminator. Version 18
removes runtime key-membership coupling for unavailable optional applied
progress without weakening its stage/value checks. Version 19 removes Rust
comparison/debug trait and argument-ownership coupling without weakening
receipt identity or classification. Version 20 adds reducer-failure rollback,
absent-local classification, and fresh applied subscription delivery. Version
21 adds initial-snapshot content, empty-zero reconnect, fan-out, and
connection-notification boundaries, but all ten historical working-pool
solutions still pass. Version 22 adds the public browser classifier and closes
at 8/10 legitimate solves. Version 23 adds concrete declaration checks,
inclusive older-receipt browser classification, and adjacent opaque upper-half
`u64` round-trips. Version 24 changed only Docker portability and direct apt
reproducibility. Version 25 removes the unstated `undefined`-only SyncState
absence constraint. Version 26 checked the actual fresh snapshot contents and
a reachable near-ceiling LSN while retaining the carrier-neutral contract; its
batch closed at 7/10 legitimate solves. Version 27's partial batch produced
four legitimate passes and one broad subscription-routing failure and was
abandoned at the harden checkpoint. Version 28 combines successor allocation
after prefix removal with a mixed applied/received browser snapshot, adds the
browser absent-local classifier boundary, re-establishes subscription delivery
after zero listeners, and strengthens the public type consumer. Version 29
adds the remaining older-but-not-yet-received Local classifier boundary.
Version 30 covers local-mutation unsubscribe and replaces negative callback
sleeps with causal barriers. Version 31 adds the unmasked older-Received
browser classification boundary and closes at 5/5 legitimate run-9 solves.
Version 32 adds same-document registration lifecycle isolation, an older Local
browser classification, rejected-mutation callback purity, and immediate
post-failure allocation continuity, but historical replay leaves 4/5 solutions
passing. Version 33 adds re-entrant self-unsubscribe delivery isolation and
updates the reference to dispatch over a stable subscriber view; its
working-pool batch closed at 3/10. Version 34 preserves that behavioral package
while removing an untested documentation adjective and embedding real runner
diagnostics in JUnit XML. Version 35 adds the missing direct ordinary-teardown
silence oracle. Version 36 adds registration linearization and cross-source
unsubscribe coverage. Version 37 reorganizes the participant description and
exercises React and Solid receipt propagation at runtime. The user subsequently
confirmed acceptance; the exact historical omissions remain recorded rather
than retroactively treated as completed.
