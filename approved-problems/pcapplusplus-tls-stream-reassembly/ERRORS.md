# ERRORS - PcapPlusPlus TLS stream reassembly

Permanent record of review findings, false positives, invalid assumptions, and
costly dead ends. Resolved findings remain here to prevent recurrence.

## 1. Constructor order was tested before it was published

- Date: `2026-08-06`
- Source: external test-fairness review
- Severity: `high`
- Verdict: `valid`

### Evidence

Every focused scenario compiled one exact `TlsReassembly` constructor order,
but the public description originally listed the callbacks, cookie, lifecycle
callbacks, and configurations without ordering them. Several other orders were
equally reasonable, so one unstated choice could make the whole suite fail to
compile.

### Resolution

State the constructor argument order and callback shape in concise prose. The
test and reference retain the existing order; no private storage or parsing
architecture is required.

### Durable lesson

A compile-time public API discriminator is fair only when every non-discoverable
part of the signature is explicit. Method inventories alone do not specify a
new multi-callback constructor.

## 2. Oversized-handshake recovery imposed an unstated same-direction policy

- Date: `2026-08-06`
- Source: external test-fairness review
- Severity: `high`
- Verdict: `valid`

### Evidence

`MalformedAndConfiguredBounds` originally required a valid handshake on the
same connection direction after an oversized handshake. The task promised that
another connection remains unaffected, but did not require the offending
direction to recover or become permanently unusable.

### Resolution

Move the boundary-sized valid message to a separate connection. A prototyped
alternative that disables only the offending direction now passes every
focused scenario.

### Durable lesson

Test the isolation guarantee that is public. Do not turn one reference recovery
policy into a hidden requirement when reset, disable, and recovery strategies
are all defensible.

## 3. Lifecycle coverage stopped at wrapper-initiated closure

- Date: `2026-08-06`
- Source: external T3/T4 review
- Severity: `high`
- Verdict: `valid`

### Evidence

Manual `closeConnection()` and `closeAllConnections()` tests exercised the
wrapper methods but never drove the existing TCP engine's automatic FIN/RST
connection-end path. An implementation could ignore that callback while
passing the suite.

### Resolution

Add `AutomaticFinRstLifecycle`. It drives an RST and a two-sided FIN through
`reassemblePacket()`, then checks the TCP status, closure reason, connection
status, TLS-state release, and per-stream incomplete-data events. The isolated
`automatic_close_ignored` mutant fails this scenario.

### Durable lesson

Forwarding wrappers need integration probes for engine-initiated callbacks as
well as direct wrapper methods; those are different execution boundaries.

## 4. Delayed purge used wall time as a test oracle

- Date: `2026-08-06`
- Source: external T2 review and mutation audit
- Severity: `medium`
- Verdict: `valid`

### Evidence

`RawPacketAndCloseAll` polled for up to three seconds to observe the TCP
engine's one-second delayed cleanup. The engine schedules cleanup from
`time(nullptr)` and clamps a zero delay, so the assertion was inherently tied
to wall-clock progress and machine scheduling.

### Resolution

Remove the delayed polling loop. Retain a deterministic call that proves the
method, return type, and open-connection behavior. `purge_stub` consequently
survives the focused and 259-case pre-existing suites; it is recorded in
`DESIGN.md` as a rejected timing-only discriminator because the public task
does not promise a cleanup deadline.

### Durable lesson

Do not strengthen a public contract merely to kill a stub when the only
available black-box distinction is a real-time deadline inherited from another
component.

## 5. Optional constructor arguments were never omitted by tests

- Date: `2026-08-07`
- Source: external T3/T4 review
- Severity: `high`
- Verdict: `valid`

### Evidence

The shared test helper always supplied all callbacks and both configurations.
An implementation could require arguments described as optional and still pass
every runtime scenario.

### Resolution

Add `RequiredCallbackOnly`, which constructs `TlsReassembly` with only an
`OnTlsRecordReady` callback and processes a complete record. The
`required_args` mutant is rejected when the focused target compiles.

### Durable lesson

Defaulted APIs need at least one call site that actually relies on the defaults;
testing only the maximal overload does not verify optionality.

## 6. Synthetic TCP loss text leaked into TLS invalid-data events

- Date: `2026-08-07`
- Source: external solution-quality review
- Severity: `medium`
- Verdict: `valid`

### Evidence

For a gap, `TcpReassembly` supplies the later captured payload prefixed with
generated text such as `[4 bytes missing]` and separately exposes the numeric
missing-byte count. The reference cleared partial TLS state and emitted
`TcpDataMissing`, but then parsed the entire callback buffer. Consumers also
received `InvalidTlsData` for bytes that never appeared on the network.

### Resolution

When the missing-byte count is nonzero, the reference removes only the exact
repository-generated marker before buffering the later payload. The public
description now states that only captured bytes may produce `InvalidTlsData`,
and `MissingDataRecovery` requires the gap to produce only its structured loss
event. The previous reference behavior is retained as the
`gap_marker_unstripped` mutant and fails that scenario.

### Durable lesson

Adapters must distinguish upstream diagnostic framing from captured protocol
bytes. Structured metadata and synthetic display text must not both enter the
downstream parser.

## 7. Review findings were kept only in DESIGN.md

- Date: `2026-08-07`
- Source: operator review
- Severity: `medium`
- Verdict: `valid`

### Evidence

The trajectory gates, mutation results, and revision explanations were detailed
in `DESIGN.md`, but the problem had no `ERRORS.md` even though Olympus defines
it as the normal durable record for review findings and resolved mistakes.

### Resolution

Create this ledger and preserve the existing evidence in `DESIGN.md`. No public
description, test, reference solution, or Docker artifact changes as part of
this documentation repair.

### Durable lesson

`DESIGN.md` explains why a problem is shaped as it is; `ERRORS.md` separately
preserves what went wrong and how it was corrected. One should not silently
substitute for the other.

## 8. Direction isolation covered records but not nested handshakes

- Date: `2026-08-07`
- Source: external T3/T4 review
- Severity: `high`
- Verdict: `valid`

### Evidence

`DirectionAndConnectionIsolation` interleaved incomplete TLS records in both
directions, but every handshake-framing assertion used only one direction. An
implementation with per-side record buffers and one per-connection handshake
buffer could pass.

### Resolution

Extend the same scenario with two distinct handshake messages, each split
across TLS records and interleaved in opposite directions. Require the exact
message bytes and side for both callbacks. An isolated shared-handshake-buffer
mutant fails this oracle.

### Durable lesson

When a feature layers one state machine over another, isolation at the outer
framing layer does not prove isolation of nested partial state.

## 9. A non-null cookie did not reach every callback surface

- Date: `2026-08-07`
- Source: external T3/T4 review
- Severity: `high`
- Verdict: `valid`

### Evidence

The only non-null-cookie scenario emitted a record and lifecycle callbacks but
never emitted a handshake or reassembly event. The helper contained cookie
assertions for those callbacks, yet they were unreachable in that fixture.

### Resolution

Make `RawPacketAndCloseAll` emit a complete handshake and leave partial TLS
state for an incomplete-close event before close-all. The existing callback
assertions then validate the same cookie on both surfaces, with explicit
handshake and event-result assertions. Separate handshake-cookie and
event-cookie mutants fail.

### Durable lesson

Installing an assertion in a callback is not coverage unless the scenario
provably invokes that callback under the value being tested.

## 10. Cleanup forwarding was checked only before expiry

- Date: `2026-08-07`
- Source: external T3/T4 review and false-positive audit
- Severity: `high`
- Verdict: `valid`

### Evidence

The only cleanup assertion called `purgeClosedConnections(1)` while every flow
was open. An implementation returning zero unconditionally passed. A suggested
default-argument-only call would have closed the compile-time hole but still
would not distinguish that stub.

### Resolution

Add one focused cleanup scenario with three closed flows. The focused
executable controls the C `time()` seam used by the existing `TcpReassembly`,
advances it past the configured expiry, and requires one bounded removal then
two removals through the default argument, checking counts,
connection-information size, and unmanaged state. The former `purge_stub`
survivor now fails. The scenario has no sleep or polling, completes in 0.00
seconds, and passed 100 consecutive exact replays.

This supersedes the earlier decision in finding 4 to leave cleanup behavior
untested. The clock control is confined to the focused executable and to the
repository engine that the public forwarding contract requires; it does not
expose a TLS implementation helper or storage representation.

### Durable lesson

Calling a forwarding API in a state where every implementation returns the
same value proves only availability. When inherited behavior is clock-gated,
prefer deterministic control of the repository-owned clock seam over a
wall-clock deadline; a compile-only call is not behavioral coverage.

## 11. Exact values were tested without their cross-state transitions

- Date: `2026-08-07`
- Source: external mutation suggestions
- Severity: `high`
- Verdict: `valid with consolidation`

### Evidence

The suite covered endpoint TLS versions, configuration member values, isolated
handshake carry, per-direction loss, and close counts. Plausible implementations
could still reject intermediate versions, cap the default at 16 KiB, erase a
handshake on a non-handshake record or an opposite-side gap, split one side's
close state into two events, misreport event sides or discard totals, or forward
the connection-end callback before incomplete events.

### Resolution

Strengthen the existing record, handshake, loss, lifecycle, and
resynchronization scenarios instead of adding eight shallow fixtures. Add one
17 KiB record, both intermediate versions, an intervening application record,
an opposite-side handshake spanning a gap, exact event sides, combined
same-side close state, callback order, and a three-byte invalid prefix whose
event totals are summed. Nine isolated mutants for these boundaries all fail;
the independently valid oversized-handshake policy still passes the complete
focused suite.

### Durable lesson

Accessor and endpoint checks do not cover transitions between independent
state machines. Consolidate related assertions into fixtures that already own
the relevant state, while keeping each added oracle tied to a distinct public
failure mode.

## 12. The hidden helper imposed copy construction

- Date: `2026-08-07`
- Source: saved solver `agent-runs1/Nova_Nova_3`
- Severity: `high`
- Verdict: `valid verifier defect`

### Evidence

The shared helper returned `TlsReassembly` by value. The repository builds as
C++14, where this return still requires an accessible copy or move constructor.
Run 3 deliberately deleted copy operations for its stateful wrapper, so every
focused scenario failed to compile even though copyability was never part of
the participant contract. Its own tests and the baseline passed.

### Resolution

Make the helper return `std::unique_ptr<TlsReassembly>` and exercise the object
only through the published API. On replay, run 3 now compiles and enters all 14
scenarios. It then fails only the independently valid exact-limit probe.

### Durable lesson

Test scaffolding must not create ownership or value-semantics requirements for
a stateful callback engine unless those semantics are public. This was not an
environment blocker; it was an undocumented compile-time verifier assumption.

## 13. An inclusive record limit had a split-prefix false positive

- Date: `2026-08-07`
- Source: saved solvers `Nova_Nova_1` and `Nova_Nova_3`
- Severity: `high`
- Verdict: `valid`

### Evidence

Run 1 passed all 14 focused scenarios, but its four-byte header-prefix check
compared the minimum payload represented by the length high byte with the
configured maximum using `<`. At the default 18 KiB limit, that rejects a
candidate whose completed length can equal the allowed maximum. After the
copyability repair, run 3 exposed the same behavior.

### Resolution

Extend `SegmentedRecords` with an exactly 18 KiB record split after the fourth
header byte. The reference and three legitimate saved solvers pass; runs 1 and
3 now fail this single public inclusive-boundary oracle. All five still pass
the complete pre-existing suite.

### Durable lesson

Testing a maximum with a complete header does not test prefix plausibility.
When a parser retains incomplete candidates, exercise the boundary at the
earliest prefix that constrains the eventual length.

## 14. Status forwarding covered only two enum branches

- Date: `2026-08-07`
- Source: external T3/T4 review
- Severity: `high`
- Verdict: `valid`

### Evidence

The wrapper promised the corresponding `TcpReassembly` return values, but the
suite asserted only out-of-order buffering and FIN/RST. A wrapper could process
data correctly while returning one constant for ordinary, ACK,
retransmission, closed-flow, non-IP, or non-TCP packets.

### Resolution

Strengthen `OutOfOrderAndRetransmission` with exact statuses for those parsed
packet branches and for non-IP/non-TCP raw packets. `RawPacketAndCloseAll` also
checks ordinary raw-packet handling. Separate constant-status mutants for the
parsed and raw overloads both fail.

### Durable lesson

A forwarding wrapper's callbacks do not prove its return contract. Exercise
the normal, ignored, closed, and wrong-protocol branches without manufacturing
unreachable internal error states.

## 15. The first mutation rerun reused a stale object

- Date: `2026-08-07`
- Source: local false-positive audit
- Severity: `high`
- Verdict: `invalid run; discarded`

### Evidence

`docker cp` preserved host source timestamps. The first mutant rebuilt, but
subsequent restored or mutated files were not newer than its object, so CMake
reused that first object and misleadingly reported the same failure for every
case.

### Resolution

Discard the entire pass. Restore the reference, prove 14/14, then touch and
rebuild the affected source or header for every isolated mutant. The valid rerun
killed all 39 actionable mutants: 37 behaviorally and two at focused-target
compilation. The reference was restored and passed 14/14 afterward.

### Durable lesson

Mutation isolation includes build freshness. Identical failure signatures
across unrelated mutants are a reason to inspect object timestamps before
claiming a strong result.

## 16. The participant description read like an API reference

- Date: `2026-08-07`
- Source: external P4 description-quality review
- Severity: `medium`
- Verdict: `valid`

### Evidence

The public statement was 496 words of dense inline signatures. The information
was accurate, but callback and getter inventories obscured the record,
handshake, loss, and lifecycle behavior.

### Resolution

Rewrite it as compact maintainer prose followed by the state-machine contracts.
The final result is 410 words and retains new type names, method names,
configuration defaults, callback order, status forwarding, and every tested
behavior.

### Durable lesson

New API names and non-discoverable constructor ordering are load-bearing;
repeating full declarations in prose is not. Group the interface for scanning
and spend prose on behavior and boundaries.

## 17. Review requested deleting non-discoverable API requirements

- Date: `2026-08-07`
- Source: external P4/API-slop review
- Severity: `high`
- Verdict: `rejected in part`

### Evidence

The review asked to remove all callback-data names and types, constructor
ordering, and forwarding surface on the ground that tests or the codebase make
them discoverable. `TlsReassembly` and its callback-data classes do not exist
at the pinned commit, and hidden tests are not participant documentation. The
same review later proposed static checks for those exact return categories.

### Resolution

Remove the templated “public surface consists of” block and compress the API
into natural prose, but keep new names, defaults, constructor ordering, and the
non-inferable const-reference contract. Add only five targeted compile-time
checks for those published reference/const categories, not the proposed
exhaustive signature catalog.

### Durable lesson

Description quality cannot be improved by making a new C++ interface
guesswork. Delete declaration-shaped repetition, not the information required
to satisfy compile-time expectations fairly.

## 18. Record upper bounds and zero-limit semantics were asymmetric

- Date: `2026-08-07`
- Source: external adversarial audit
- Severity: `high`
- Verdict: `valid`

### Evidence

The malformed fixture rejected type 19 but not type 24, and positive size
limits did not determine whether zero meant a literal maximum or a sentinel.
Nearby TCP configuration does use zero sentinels, making both shortcuts
plausible. The suite also rejected an over-limit handshake without proving
that its already-complete outer TLS record was still emitted.

### Resolution

Strengthen `MalformedAndConfiguredBounds` with type 24 followed by a valid
record, literal zero record/handshake maxima, and independent record emission
for an over-limit inner handshake. The four corresponding isolated mutants all
fail this scenario while the reference and legitimate saved solvers pass.

### Durable lesson

Test both sides of a published inclusive range and define zero explicitly when
neighboring configuration APIs give it sentinel meaning. Nested decoding must
not silently change the outer framing callback contract.

## 19. Closed TLS state was not tested against tuple reuse

- Date: `2026-08-07`
- Source: external T4 lifecycle review
- Severity: `high`
- Verdict: `valid`

### Evidence

Close tests checked incomplete-data events and TCP bookkeeping, but never
recreated the same tuple after the underlying closed-flow entry was purged. A
wrapper could retain both TLS buffers and reuse them on the next incarnation.

### Resolution

Populate partial record and handshake state, close and purge the flow, recreate
the tuple, then require exactly one fresh record and no stale handshake or
event. A retained-state mutant fails `PurgeClosedConnections`; the clean
reference and the alternative oversized-handshake policy pass.

### Durable lesson

Lifecycle teardown is observable at identity reuse, not merely through an end
callback. Recreate the identity through the normal public engine path without
asserting a private erase operation.

## 20. New configuration and event names were still implicit

- Date: `2026-08-07`
- Source: external interface-information review
- Severity: `high`
- Verdict: `valid`

### Evidence

The tests directly name `maxRecordPayloadSize`, `maxHandshakeMessageSize`, the
two-argument configuration constructor, and four event getters. None of these
symbols exists at the pinned commit, so neither nearby code nor compiler errors
provide a fair participant-facing choice among equally natural names.

### Resolution

Name the two public `size_t` fields, their constructor/defaults, and
`getType()`, `getMissingByteCount()`, `getDiscardedByteCount()`, and
`getConnectionData()` in the description. Remove only the separately flagged
redundant packet-overload/purge phrase.

### Durable lesson

Tests are not API documentation. New compile-time names must be public even
when inherited behavior can be summarized by reference to an existing class.

## 21. Loss and invalid-data reporting had seven demonstrated gaps

- Date: `2026-08-07`
- Source: external adversarial audit
- Severity: `high`
- Verdict: `valid`

### Evidence

Plausible implementations could narrow the configuration fields, accept
versions below `0x0300`, fabricate a nonzero timestamp, retain only handshake
state across a TCP gap, suppress a gap with zero TLS discard, or silently
discard zero-limit record data and oversized handshakes. Each mode passed the
previous 14 scenarios.

### Resolution

Strengthen the existing `RequiredCallbackOnly`, `SegmentedRecords`,
`MissingDataRecovery`, and `MalformedAndConfiguredBounds` scenarios instead of
adding six near-duplicate top-level fixtures. The exact reference passes
14/14; all seven new isolated mutants fail their owner scenario. A legitimate
implementation that disables later handshake decoding only on the offending
direction still passes, so same-direction oversized-message recovery remains
deliberately unspecified.

### Durable lesson

Hardening should add state transitions and provenance checks, not scenario
count. Sum observable discarded-byte events when batching is not public, and
keep invalid inner-message reporting independent of outer-record delivery.

## 22. Two verification setup failures initially mimicked product failures

- Date: `2026-08-07`
- Source: local verification
- Severity: `medium`
- Verdict: `invalid runs; discarded`

### Evidence

Saved-solver patches initially failed to apply because files introduced by a
Docker commit were root-owned, although the patches themselves applied cleanly
when staged before dropping privileges. A direct `Packet++Test` invocation
then reported missing fixtures because it was launched from `/app` instead of
the target's configured test working directory. A later diagnostic search also
left Markdown backticks unquoted, causing a harmless attempted shell command
substitution instead of treating the pattern literally.

### Resolution

Apply each saved patch during container setup, then perform every build and
test as UID/GID 1000. Invoke the aggregate binary from
`/app/Tests/Packet++Test`; the corrected run passes 259/259. Pass shell search
patterns as literal single-quoted arguments.

### Durable lesson

Separate setup privilege from evaluator privilege, and preserve CTest working
directories when reproducing a target manually. Environment-shaped failures
must not be counted as solver or baseline failures.

## 23. Over-limit record rejection lacked exact accounting

- Date: `2026-08-07`
- Source: external coverage review
- Severity: `medium`
- Verdict: `valid`

### Evidence

The configured-limit fixture mixed a declared max+1 header with several other
malformed forms and asserted only that some invalid bytes were reported. A
specialized rejection path could remove the complete over-limit record,
recover correctly, and under-report its discarded size while all 14 v16
scenarios still passed. A concrete one-byte-under-report mutant demonstrated
that survivor.

### Resolution

On a fresh flow in `MalformedAndConfiguredBounds`, feed one complete max+1
record immediately before a valid max-sized record. Require only the valid
callback and sum all new `InvalidTlsData` counts to the exact rejected encoded
record size. The reference and legitimate alternative pass; the demonstrated
mutant fails only this scenario. The full 57-mutant replay has no survivor.

### Durable lesson

Recognition, recovery, and accounting are separate contracts. When event
batching is intentionally flexible, compare the summed count on an isolated
semantic cause rather than prescribing event granularity.

## 24. The second calibration batch hit one repeated API inference trap

- Date: `2026-08-07`
- Source: `agent-runs2` trajectories and evaluation records
- Severity: `high`
- Verdict: `valid fairness issue; batch abandoned`

### Evidence

All five baselines passed and all five solvers added 699-759 strict production
lines, but every focused target failed before behavioral execution. Each solver
independently chose raw `uint8_t`/`uint16_t` results for the three TLS type
getters, while the verifier expected existing Packet++ `SSLRecordType`,
`SSLVersion`, and `SSLHandshakeType` categories. Five identical integration
misses are strong evidence that repository inference was too costly.

### Resolution

Name only those three return types in `meta.md`; remove no runtime behavior.
After mechanically normalizing only those types in the saved patches, all five
focused targets compile and each reaches 13/14. The old 0/5 batch remains
abandoned and the revised artifact starts at 0/10.

### Durable lesson

When every independent solver makes the same reasonable API choice, adding
more hidden compile assertions does not improve calibration. Publish the narrow
non-inferable category and keep difficulty in the state machine.

## 25. Timestamp provenance and oversized-message rejection stopped at one callback

- Date: `2026-08-07`
- Source: external T4/S1 review and `agent-runs2` source comparison
- Severity: `high`
- Verdict: `valid`

### Evidence

The exact timestamp probe completed a record in one packet, so an implementation
that retained the first fragment's timestamp could pass. The reference also
discarded only currently buffered bytes from an oversized handshake, forgot the
declared remainder, and could decode later body bytes as a fabricated message.
Four second-batch solvers already tracked the declared remainder; one repeated
the reference bug.

### Resolution

Split the timestamp fixture across packets with distinct controlled timestamps
and require the completing packet's value. Track the unreceived portion of a
rejected handshake in the reference, discard/report it across later handshake
records, and resume only after the full declaration. Add header-shaped body
bytes plus a later valid message to the existing bounds scenario. Both new
isolated mutants fail their owner scenarios.

### Durable lesson

Provenance and rejection semantics must be tested across the transition where
the value can differ. A framed-message rejection is incomplete if later body
bytes can re-enter header parsing.

## 26. One solution-patch regeneration silently omitted new production files

- Date: `2026-08-07`
- Source: local packaging verification
- Severity: `high`
- Verdict: `invalid artifact; caught before freezing`

### Evidence

A plain worktree diff regenerated a 20-line `solution.patch` because the new
TLS header and source were untracked at the pinned checkout. The patch retained
only build registration and would not have contained the implementation.

### Resolution

Discard the patch immediately and regenerate additions with explicit
`/dev/null` diffs plus the tracked build diff. The frozen patch is 541 lines,
applies cleanly over the test-only tree, contains the new header/source, and
matches the reference image.

### Durable lesson

Never assume a normal diff contains untracked implementation files. Check patch
line count, numstat, named paths, clean application, and frozen source hashes.

## 27. The first v18 mutation replay contained a no-op mutant

- Date: `2026-08-07`
- Source: local false-positive audit
- Severity: `high`
- Verdict: `invalid run; discarded`

### Evidence

After the reference added another rejection-state reset, the existing
`keep_loss_state` substitution no longer matched its complete intended block.
The mutation runner therefore did not produce the promised wrong
implementation, making the first v18 aggregate invalid even though the other
mutants were killed.

### Resolution

Extend the substitution to the revised reset block, verify that the mutant
source differs, and restart the complete audit. The accepted result is the
fresh 59/59 run: 51 behavioral kills and eight compile-time kills.

### Durable lesson

Mutation labels are not evidence. Every generated mutant must be confirmed to
change the intended semantic branch after reference edits, and any no-op
invalidates that aggregate run.

## 28. Replay launchers and an alternative patch produced invalid setup results

- Date: `2026-08-07`
- Source: local saved-solver and fairness verification
- Severity: `medium`
- Verdict: `invalid runs; discarded`

### Evidence

The first replay commands named a nonexistent `model` passwd entry, then used
UID 1000 before reproducing the evaluator's ownership layer. A later reporting
loop used zsh's read-only `status` variable. Separately, the first buffered
alternative patch was syntactically malformed; the unchanged reference then
passed 14/14, which was not valid alternative evidence.

### Resolution

Recreate every saved-solver container, chown `/app` as the evaluator does, run
with numeric UID/GID 1000, and use a neutral reporting variable. Rebuild the
alternative from exact source files, verify a 62-line source/header diff and
the absence of remaining-byte state, then rerun it; the genuine alternative
passes 14/14.

### Durable lesson

Do not classify a solver or alternative until setup, source delta, execution
identity, and result collection are all verified. A green unchanged reference
is not evidence for a failed-to-apply alternative.
