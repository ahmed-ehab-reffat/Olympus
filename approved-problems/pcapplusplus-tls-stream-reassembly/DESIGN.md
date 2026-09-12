# DESIGN - PcapPlusPlus TLS stream reassembly

Status: `accepted and archived 2026-08-08; final local revision was 0/10`.

Repository: `seladb/PcapPlusPlus` at
`8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`, 2026-08-04).

Primary language: C++. Task type: feature request.

## Trajectory-informed design gate

Before hidden-test authoring, the search covered all local PcapPlusPlus
candidate, problem, archive, and success records plus raw representative
PCAPNG and NTP solver trajectories. No earlier TLS/SSL stream-reassembly task
or solver exists.

| Evidence | Outcome | Constraint on this design |
|---|---|---|
| PCAPNG legitimate pass (`agent-runs4/Nova_Nova_1`) | 69/69 baseline, 14/14 focused; 540 production lines | Test observable stream state and output, not one helper or buffer architecture. |
| NTP near-pass (`Nova_Nova_5`) | Baseline pass, 18/19 focused; terminal minimum applied before authentication | Exercise boundaries where the same prefix is incomplete, complete, or interrupted by reported loss. |
| PCAPNG broad failure (`agent-runs4/Nova_Nova_10`) | 69/69 baseline, 9/14 focused; section state leaked | Interleave connections and directions so TLS state cannot leak. |
| SNAP external scope rejection | Correct reference had only 193 strict additions in one parser/crafting subsystem | Require the genuine interaction of TCP ordering/loss/lifecycle, TLS records, and nested handshake framing. Do not add unrelated scope. |

The accepted PCAPNG and NTP tasks exclude another raw copy transformer,
variable-record editor, ownership-view API, or layer resize exercise.

Full candidate evidence is retained in
[`candidates/pcapplusplus-tls-stream-reassembly/DESIGN.md`](../../candidates/pcapplusplus-tls-stream-reassembly/DESIGN.md).

### Fairness-review revision gate

The 2026-08-06 description/test review was checked against the same trajectory
and repository evidence above before revising the hidden suite. It found two
contract mismatches rather than new discriminator families:

- The test compiled against one exact callback/constructor order while the
  public description named the arguments without ordering them. The public API
  must state the callback aliases and constructor signature exactly; the test
  should not infer an unpublished signature.
- The configured handshake-bound fixture recovered on the same direction after
  rejection, while the public contract promised only that another connection
  remains unaffected. The valid boundary message will therefore move to a
  separate flow. Same-direction recovery is not required or tested.

The review also identified two redundant public sentences about generic
`TcpReassembly` behavior and out-of-scope decryption/application parsing. They
add no discriminator and will be removed. These changes preserve all existing
ledger families, add no private implementation constraint, invalidate the prior
artifact hashes, and restart exact verification and the false-positive audit.

### Lifecycle and timing review gate

The next 2026-08-06 review was checked against the same recorded trajectory
set and the public `TcpReassembly` lifecycle API before changing tests. It found
one missing integration branch and one avoidable harness dependency:

- Manual close and close-all exercise wrapper methods but not the existing
  automatic FIN/RST path that invokes the same connection-end callback from
  `reassemblePacket`. A focused scenario will drive both RST closure and the
  two-sided FIN closure through packet input, then observe end reasons,
  incomplete-state events, and closed status.
- Positive delayed purge required a wall-clock polling loop. The public task
  needs the forwarding method and return type, but does not justify making the
  focused suite wait for `time(nullptr)`. The test will retain a deterministic
  open-connection call/signature check and remove the delayed cleanup oracle.

The exact inline callback/constructor prose will also be shortened to argument
order and callback shape while retaining enough information to make the
compile-time API unambiguous. These are public integration and portability
changes, not new private implementation requirements; they invalidate the prior
artifact hashes and restart exact verification and mutation review.

### Optional-callback and loss-semantics review gate

Before this 2026-08-06 test/reference revision, the startup search was repeated
across `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, both accepted PcapPlusPlus archives, the active
candidate/problem records, and all trajectory locations. There is still no TLS
stream-reassembly solver trajectory. Representative raw evidence was therefore
rechecked from the archived PCAPNG legitimate pass (`agent-runs4/Nova_Nova_1`),
PCAPNG broad failure (`agent-runs4/Nova_Nova_10`), and NTP near-pass
(`Nova_Nova_5`); their architectural and boundary lessons remain those in the
main trajectory table and do not prescribe either fix.

Repository inspection exposed two independent public seams:

| Repository evidence | Plausible shortcut | Public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| `TcpReassembly`'s neighboring constructor makes lifecycle callbacks and configuration optional; the TLS declaration also defaults every argument after the record callback | Implement the published full constructor but omit defaults or another record-only construction path | A record callback alone is sufficient to construct and use `TlsReassembly` | Construct with one callback, feed a record, and inspect its callback | Compile-and-run API compatibility; no private layout or helper is constrained |
| `TcpReassembly.cpp` prepends `[N bytes missing]` to the later network payload while separately exposing `getMissingByteCount()` | Feed the synthetic diagnostic bytes into TLS resynchronization | A reported TCP gap produces the loss event and parses only later captured bytes; generated marker text is not invalid network TLS | Trigger one gap, require the exact loss event and recovered record, and require no invalid-data event for the marker | Event semantics are participant-facing and the marker format is repository evidence, not a required implementation technique |

The callback probe adds a distinct public-interface discriminator. The loss
probe strengthens the existing `MissingDataRecovery` family instead of adding
another fixture. The reference change will strip only the exact repository
marker associated with a nonzero missing-byte count, preserving arbitrary
captured prefixes in every other callback. These changes invalidate the prior
artifact hashes and restart exact verification, mutation review, and the saved
solver search at calibration 0/10.

### Nested-direction and callback-cookie review gate

Before the 2026-08-07 hidden-test revision, the required search was repeated
across the active problem/candidate records, PcapPlusPlus success history, both
accepted repository archives, and the representative raw PCAPNG legitimate
pass, PCAPNG broad failure, and NTP near-pass. There is still no TLS solver
trajectory. The PCAPNG broad failure remains relevant because its state leaked
across namespaces; the candidate design and repository independently require
both record and nested handshake state to be isolated by connection direction.

The existing focused suite and callback helper revealed two distinct holes:

| Repository evidence | Plausible shortcut | Public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| TLS record framing and handshake framing use separate buffers, while `TcpReassembly` assigns a stable side per direction | Isolate record buffers by side but keep one handshake accumulator per connection | All framing state, including incomplete handshake messages, is independent for both directions | Interleave two handshake messages split across records in opposite directions; compare exact bytes and callback sides | Exercises the public nested state machine through callbacks without constraining containers or helper layout |
| The constructor accepts one cookie shared by record, handshake, event, and TCP lifecycle callbacks; the helper checks it only when a surface fires | Forward the cookie to records/lifecycle but use null or another pointer for handshake or event callbacks | Every callback receives the original user cookie | Under one non-null cookie, emit a handshake and an incomplete-close event and require both callbacks | Callback identity is observable API behavior; no parser implementation detail is exposed |

Both probes strengthen existing scenarios rather than multiply fixtures:
`DirectionAndConnectionIsolation` gains nested handshake interleaving, and
`RawPacketAndCloseAll` activates its already-installed handshake and event
callbacks under a non-null cookie. These public seams are independent of the
prior record-isolation and record/lifecycle-cookie probes. The changes
invalidate the current test hash and restart exact verification, mutation
review, and the saved-solver search at calibration 0/10.

### Cleanup and cross-state survivor review gate

Before the 2026-08-07 cleanup/state revision, the startup search was repeated
over `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the active PcapPlusPlus records, both accepted
PcapPlusPlus archives, and their raw trajectories. The representative evidence
remains the PCAPNG legitimate pass (`agent-runs4/Nova_Nova_1`), PCAPNG broad
failure (`agent-runs4/Nova_Nova_10`), and NTP near-pass (`Nova_Nova_5`). No TLS
solver trajectory exists. The raw runs again show that narrow happy-path tests
miss section/state interactions and explicit numeric boundaries, while valid
solutions use different internal organizations.

The website proposal was treated as survivor evidence, not copied wholesale.
Its default-only purge call would still pass an always-zero stub, and eight new
one-assertion scenarios would add fixture count without eight independent
failure families. The revised plan strengthens existing scenarios where the
state already exists and adds one cleanup scenario for the otherwise
unreachable forwarding branch.

| Repository/public evidence | Plausible shortcut | Public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| `TcpReassembly::purgeClosedConnections` returns a removal count and erases expired closed flow information | expose a same-signature method that always returns zero | TLS cleanup preserves the underlying bounded/default purge behavior | close three flows, advance the test-controlled C clock used by the existing TCP engine, then check bounded count/state followed by default count/state | observes only published wrapper state and deterministically controls the repository engine's clock seam; no TLS helper or storage layout is selected |
| Every TLS callback carries a `side`, and loss/close operate on one direction at a time | always report event side zero or clear both directions on one gap | event direction is accurate and a gap clears only its affected direction | check loss side, both close sides, and completion of an opposite-direction partial handshake across the gap | exercises public callback metadata and isolation without selecting a container or helper |
| Exact accepted record-version range and 18 KiB default are public constants | accept only range endpoints or silently reuse a 16 KiB TLS convention | accept `0x0301`/`0x0302` and a default-sized payload above 16 KiB | add intermediate-version records and a 17 KiB default record to existing framing scenarios | direct boundary values; no parser architecture is constrained |
| Handshake carry is fed only by handshake records and survives until a later handshake record | clear handshake carry on any non-handshake record | intervening alert/application records neither erase nor contaminate partial handshakes | place an application record between two handshake fragments and compare the completed message | distinct nested-state transition observable through normal callbacks |
| Close reports one combined incomplete count per affected direction before forwarding end | emit one event per buffer, omit side, or invoke end first | combine record/handshake bytes for one side and deliver incomplete events before end | close with both buffers populated, inspect one exact event, side, count, and callback order | callback order and aggregation are explicitly public; no storage representation is required |
| Invalid-data events expose discarded captured-byte counts | report a constant one even when discarding a batch | event counts account for every captured byte discarded | resynchronize after a multi-byte prefix and sum all invalid-event counts | allows either batched or per-byte event emission while pinning only the public total |

These probes are public, distinct, and grounded in the wrapper contract. They
invalidate the participant description and test hashes and therefore restart
the exact matrix, false-positive audit, saved-solver search, and any future
calibration at 0/10. No cold solver is planned.

### Saved-solver calibration revision gate

Before revising the description or hidden tests on 2026-08-07, the startup
search was repeated over the active problem and candidate records, the accepted
PcapPlusPlus archives, and the newly available raw runs in `agent-runs1`.
Unlike the earlier gates, this search found five directly relevant TLS solver
trajectories. Their evaluation records, patches, test logs, and representative
raw implementation sections were inspected before selecting new probes.

| Raw run | Observed outcome | Architecture and effort | Design consequence |
|---|---|---|---|
| `Nova_Nova_1` | baseline and 14/14 focused passed, but source review found a real exact-limit split-header bug | public header, implementation, and build registration; about 703 production additions; prefix plausibility used `high-byte minimum < maximum` | add one inclusive maximum-boundary record split after the fourth header byte; this is a saved-solver false positive grounded in the public limit |
| `Nova_Nova_2` | legitimate pass | the same three production surfaces; about 727 additions; per-flow, per-direction record and handshake state | preserve architecture-neutral callback and state-machine oracles |
| `Nova_Nova_3` | focused target failed to compile | the same production surfaces; about 755 additions; explicitly deleted copy operations | remove the verifier helper's undocumented C++14 return-by-value/copyability assumption |
| `Nova_Nova_4` | legitimate pass | the same three production surfaces; about 760 additions; an independent array-of-direction-states design | replay after revision to ensure the strengthened suite accepts a distinct legitimate organization |
| `Nova_Nova_5` | legitimate pass | the same three production surfaces; about 721 additions | replay after revision as another legitimate saved solver |

This batch therefore yielded three clean legitimate passes, one legitimate
implementation blocked by the verifier, and one behaviorally wrong
implementation that the focused suite accepted. A broad behavioral failure was
not present in this five-run set; the copy-construction failure is recorded as
a fairness defect and is not treated as substitute evidence for a parser
discriminator. The median production change was roughly 727 additions across
the public header, implementation, and build registration, confirming that the
task still exercises the intended multi-state-machine scope.

The revision ledger is:

| Repository/trajectory evidence | Plausible shortcut or verifier fault | Public invariant | Revised oracle | Decision |
|---|---|---|---|---|
| A four-byte TLS header prefix fixes the payload high byte but not the low byte; run 1 used a strict prefix comparison | discard an incomplete candidate whose eventual payload may equal the configured maximum | the configured record maximum is inclusive even when the header is split | feed an exactly 18 KiB record in two TCP callbacks split after header byte four and require its exact callback | add; distinct inclusive-boundary survivor |
| `TlsReassembly` owns callback state and wraps a noncopyable-style engine; the public API does not promise copy construction | return the wrapper by value from a C++14 hidden helper | no copy or move capability is required | allocate the helper result with `std::unique_ptr` and exercise only the published API | fairness repair; no participant requirement added |
| Both packet overloads promise the corresponding `TcpReassembly` status, whose public enum has ordinary, no-data, retransmission, closed-flow, non-IP, and non-TCP branches | return one convenient status while still forwarding payload callbacks | each wrapper call retains the underlying observable status | assert the common statuses with ordinary TCP, ACK, retransmission, post-close, Ethernet-only, and UDP packets | add; one forwarding family, not six new fixtures |
| The public description repeated every signature in long paragraphs | preserve correctness but obscure the task in API-reference prose | new names, types, defaults, callback order, and behavioral contracts remain discoverable | compress into a short public-surface list plus state-machine paragraphs | prose-only revision |

These changes are public, black-box, and do not select a buffer layout or
private helper. Editing either `meta.md` or `test.patch` abandons the five-run
calibration version; the revised immutable version restarts at 0/10. Saved
solvers will be replayed as verification evidence, but their previous outcomes
cannot be counted toward the new batch. No cold solver will be run.

### Adversarial boundary and teardown revision gate

Before the next 2026-08-07 revision, the startup search was repeated over the
active problem/candidate records, `agent-runs1`, the five saved solution
patches, and the prior mutation/error ledgers. The same three saved legitimate
architectures, two exact-limit failures, and one verifier-mismatch run remain
the directly relevant trajectory set; there is still no broad behavioral
failure beyond the previously recorded PCAPNG state-leak analogue. Raw patch
inspection confirms that successful solvers use different direction-state and
boundary-scanning organizations, while all add the same public header,
implementation, and build seam at a median of roughly 727 production
additions.

An external adversarial report proposed six gaps and a replacement verifier.
Those proposals were evaluated against the public contract and the earlier
legitimate-alternative replay rather than accepted as a block:

| Evidence | Plausible shortcut | Public invariant | Planned oracle | Decision and anti-overfitting rationale |
|---|---|---|---|---|
| The record type is an inclusive numeric range, while the current malformed fixture checks only type 19 | accept type 24 through an upper-bound typo and let it block or emit before a valid record | only types 20 through 23 are plausible, and scanning continues after a refutable candidate | place type 24 immediately before a valid type-23 record and compare the exact output and discarded total | add to the existing malformed scenario; upper-bound rejection is distinct from the lower-bound fixture and was demonstrated by a plausible mutant |
| Nearby TCP configuration uses zero as a sentinel, but the TLS limits are direct maxima | treat either zero TLS limit as “unlimited” | nonempty record payloads exceed a zero record maximum; only zero-payload handshakes fit a zero handshake maximum | exercise both zero configurations and inspect record/handshake callbacks | add to the existing bounds family; this is a semantic sentinel boundary, not an arbitrary numeric permutation |
| Record framing completes before nested handshake decoding | suppress a complete record when its inner handshake is over limit | TLS-record emission is independent of whether the nested handshake is emitted | require the over-limit containing record while rejecting its handshake | add to the existing bounds scenario without requiring recovery policy |
| The public close contract says TLS state is released, while cleanup currently checks only TCP bookkeeping | retain record/handshake buffers after close and reuse them if the same tuple is recreated after purge | a recreated flow starts with no TLS framing state from the prior connection | close with both buffers partial, purge, recreate the tuple, and require a clean valid record with no stale event/handshake | add to `PurgeClosedConnections`; black-box lifecycle behavior, independent of map or erase strategy |
| New callback-data and query types do not exist in the base repository | return copies or drop required const qualification while matching runtime values | the explicitly published return categories and const query surface are part of the public C++ API | place focused `static_assert`s in an existing compilation scenario | add only for non-inferable reference/const categories; do not create a large API-only scenario |
| The prompt says an over-limit handshake is rejected without affecting another connection; a prior legitimate implementation disables only the offending direction | require a later handshake on that same direction | same-direction recovery was never promised and would reject a preserved legitimate mode | proposed later-message recovery assertion | reject as unfair reference policy; keep the separate-connection isolation oracle |

The description review is internally inconsistent: it asks to delete the new
API names, defaults, callback order, and return categories while the proposed
tests statically require those exact choices. Because `TlsReassembly` does not
exist in the base repository, hidden tests are not a participant-facing source
of interface information. The revision will remove the templated “public
surface consists of” presentation and compress the prose, but retain the
load-bearing names, defaults, ordering, and ambiguous return categories needed
to make compile-time checks fair.

These prompt/test changes invalidate the current hashes and reset calibration
to 0/10. The exact package matrix, saved-solver replay, legitimate-alternative
replay, requirement map, and repository-grounded mutation audit must all be
repeated. No cold solver will be run.

### Loss, timestamp, and invalid-event revision gate

Before the 2026-08-07 revision below, the search was repeated over the active
problem and candidate records, all five `agent-runs1` evaluation summaries,
their raw solution patches, representative raw trajectories, and the current
49-mutant ledger. Runs 2, 4, and 5 remain independent legitimate solutions;
runs 1 and 3 retain the known split-header inclusive-limit defect; no new broad
behavioral failure is available. All five patches use the published two-limit
configuration shape, propagate `TcpStreamData::getTimeStampPrecise()`, and
contain separate record and handshake state. The legitimate patches also show
explicit low/high version checks, handshake-state clearing on loss, and
invalid-data event paths at both record scanning and handshake decoding. This
supports public black-box probes without prescribing their containers or
helpers.

The new external audit demonstrated seven plausible survivors. They were
evaluated as failure families rather than copied as six new top-level test
fixtures:

| Repository/trajectory evidence | Plausible shortcut | Public invariant | Revised oracle | Decision and anti-overfitting rationale |
|---|---|---|---|---|
| TLS configuration is new at the pinned commit, while every saved patch chooses the same two public `size_t` members and two-argument constructor | use narrower integer members while preserving all currently tested values | `maxRecordPayloadSize` and `maxHandshakeMessageSize` are public `size_t` limits with the stated constructor/defaults | compile the existing minimal-construction scenario with exact member-type checks | add; public ABI information will be named explicitly in the description |
| Record plausibility is an inclusive version range; current malformed input checks only `0x0304` | check only the upper bound and accept `0x02ff` | versions below `0x0300` are refutable and cannot block later valid data | place `0x02ff` before `0x0300` on one flow and compare recovery/discard totals | add inside `MalformedAndConfiguredBounds`; direct opposite boundary, demonstrated mutant, no numeric permutation matrix |
| `TcpStreamData` exposes the completing packet's precise timestamp and every saved implementation forwards it | stamp callbacks with wall time or any nonzero default | a record reports the precise timestamp of the TCP callback that completed it | emit a single-packet record with an injected nanosecond timestamp and compare exactly | add inside `SegmentedRecords`; one metadata provenance boundary |
| Record and handshake buffers are independent; the current loss fixture never continues the affected handshake after loss | clear only record bytes while retaining the affected handshake accumulator | no handshake may join captured bytes across a reported TCP gap | send an affected-direction continuation that would complete only if pre-gap handshake bytes survived | add inside `MissingDataRecovery`; distinct nested-state transition |
| A gap is upstream transport information even when the TLS discarded count is zero | condition the loss callback on partial TLS state | every reported gap emits `TcpDataMissing`, including zero discarded TLS bytes | create a second flow with a clean record followed by a gap and require missing count plus zero discarded count | add inside `MissingDataRecovery`; event gating rather than another payload fixture |
| Literal zero limits make every nonempty record header implausible, and scanning must account for captured bytes it discards | treat zero as a silent parser-disable switch | refutable captured bytes produce `InvalidTlsData` | require positive invalid-data accounting in the existing zero-record subcase | add; record-scanner invalid-reporting boundary |
| Over-limit handshake bytes are deliberately cleared by every saved legitimate implementation | clear the inner buffer silently while still emitting the outer record | rejected inner bytes produce `InvalidTlsData` without suppressing the outer record | snapshot events around the existing oversized handshake and sum its exact discarded bytes | add; nested-decoder reporting boundary, separate from record scanning |

The prose correction will remove the redundant packet-overload/purge detail
after “Mirror `TcpReassembly`”, but it will name the configuration members,
two-argument constructor, and event getters because none exists in the base
repository and hidden tests are not interface documentation. The timestamp and
invalid-event provenance will also be made explicit. These changes abandon the
previous immutable hashes and reset calibration to 0/10. The exact matrix,
saved-solver replay, legitimate alternative, requirement map, and mutation
audit must all be repeated. No cold solver will be run.

### Over-limit record accounting revision gate

Before revising the hidden test on 2026-08-07, the search was repeated across
`problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the active candidate/problem design, levels and
error records, all five saved evaluation summaries and solution patches, and
representative raw trajectories for the near-pass (`Nova_Nova_1`), verifier
failure (`Nova_Nova_3`), and legitimate pass (`Nova_Nova_4`). Solvers use
several record-scanning structures, but all separate header plausibility from
invalid-byte accounting. The legitimate trajectory proactively built focused
limit tests and fixed callback-driven state lifetime; the near-pass missed an
inclusive split-header boundary; the only broad failure available is a hidden
copy-construction mismatch rather than a behavioral implementation failure.

The current mixed malformed stream proves only that some invalid bytes are
reported. A repository-grounded mutant recognized a structurally valid record
whose payload exceeded the configured maximum, discarded the entire encoded
record, recovered the following valid record, but reported one fewer discarded
byte on that specialized rejection path. It passed all 14 v16 focused
scenarios. This is a distinct accounting survivor, not another recognition or
resynchronization failure.

| Repository/trajectory evidence | Plausible shortcut | Public invariant | Revised oracle | Decision and anti-overfitting rationale |
|---|---|---|---|---|
| Record scanning may reject an otherwise valid header specifically at the configured payload bound, while existing exact accounting covers type/version and generic-prefix failures | discard the complete over-limit record but omit some of its encoded bytes from `InvalidTlsData` accounting | every captured byte discarded as invalid TLS data is accounted for, including a complete record rejected only by its payload limit | on a fresh flow, concatenate one complete max+1 record and one valid boundary-sized record; require only the latter callback and sum invalid-event counts to the exact first-record size | add inside `MalformedAndConfiguredBounds`; one complete fixture isolates the semantic cause, event batching remains unconstrained, and no parser helper or discard granularity is prescribed |

The public description already requires reporting captured bytes discarded
because of either configured limit, so no prompt expansion is needed. Revising
`test.patch` abandons the v16 hashes and keeps calibration at 0/10. The exact
package matrix, 57-mutant audit, five saved solvers, full pre-existing suite,
and legitimate alternative must be replayed. No cold solver will be run.

### Second calibration batch and split-handshake revision gate

The 2026-08-07 search covered the active problem/candidate records, all five
`agent-runs2` summaries, solution patches, test logs, and representative raw
trajectories, alongside the earlier legitimate and near-pass runs. The second
batch is 0/5, with every baseline green and every focused target blocked at the
same public-API integration point before behavioral execution. No legitimate
or behavioral near-pass exists in this batch; that category is explicitly
unavailable. Prior `agent-runs1` legitimate solutions remain the behavioral
comparison set.

All five second-batch solvers implemented the feature across 699–759 strict
production additions and passed their own focused tests, but independently
returned `uint8_t`/`uint16_t` from the three TLS type getters. Existing Packet++
classes do use `SSLRecordType`, `SSLVersion`, and `SSLHandshakeType`, so the
hidden expectation is repository-grounded, yet a 5/5 convergence on raw wire
types shows that inference is an excessive calibration trap. The narrow easing
lever is to publish those three return types; no runtime rule is removed.

The same trajectories provide independent evidence for the newly reported
handshake bug. Runs 1, 2, 3, and 5 already keep an explicit remaining-byte
counter when rejecting an oversized handshake split across later handshake
records; run 4 clears only current bytes, matching the reference shortcut.
Thus the public meaning of rejecting a declared framed message supports a
cross-record black-box probe without prescribing a buffer or counter. The
reference must be corrected before that probe can be approved. The timestamp
review is likewise a real transition gap: the prose says the completing TCP
callback supplies the timestamp, but the exact assertion uses one packet and
cannot distinguish first-fragment from completion time.

| Repository/trajectory evidence | Plausible shortcut | Public invariant | Revised oracle | Decision and anti-overfitting rationale |
|---|---|---|---|---|
| Five independent 699–759-line solutions use raw integers although neighboring SSL APIs use typed wrappers | implement wire-correct getters with `uint8_t`/`uint16_t` return types | the new API integrates with Packet++'s `SSLRecordType`, `SSLVersion`, and `SSLHandshakeType` conventions | state those three return types in the participant description; retain existing behavioral calls | ease; removes one repeated interface-guessing failure without reducing state-machine scope |
| Record timestamps are propagated from `TcpStreamData`, but the current exact probe completes in one callback | retain the first fragment's timestamp for a segmented record | a record timestamp is the timestamp of the TCP callback that completes it | split one record across two packets with distinct controlled timestamps and compare with the second | add inside `SegmentedRecords`; metadata provenance across one transition, no storage strategy required |
| Four second-batch implementations track the unreceived body of an oversized handshake, while run 4 and the reference clear only current bytes | treat later body fragments as new handshake headers after an oversized declaration | rejecting a framed oversized message consumes that complete declared message across later handshake records before parsing resumes | split an oversized message body across records, place header-shaped body bytes in the continuation, then append a valid handshake; require all record callbacks, no fabricated handshake, exact invalid accounting, and the later valid message | add inside `MalformedAndConfiguredBounds`; framed-message semantics, summed events, and no private counter requirement |

The second calibration batch is abandoned at 0/5. Changing the description,
reference, or tests creates a new immutable version at 0/10; no unused runs or
outcomes carry over. The exact package matrix, full baseline, false-positive
audit, all saved solver patches, and legitimate alternative must be replayed.
No cold solver will be run.

This revision makes complete-declared-message rejection and subsequent framing
recovery public, superseding the earlier version's allowance to disable an
offending direction permanently. Fairness is preserved by testing the result,
not a counter: a second implementation that buffers the entire oversized
message until it is present, discards it in one batch, and then resumes also
passes the focused suite.

## Repository and upstream gate

The generic `TcpReassembly` engine already supplies ordered, deduplicated TCP
chunks, missing-byte counts, two directions, and connection lifecycle. The SSL
layers are packet-local: an incomplete record is truncated to the current
packet, and handshake objects borrow one record's storage.

Exact local history and all-state GitHub searches found no `TlsReassembly`,
equivalent class, implementation PR, branch, or prescribed API. Closed issues
#533, #745, #1689, #1875, and #104 describe the missing record/SNI/certificate
behavior and explicitly show no linked development. They establish demand
without supplying a solution. Neighboring flow-collision, padding/FCS,
RawPacket capacity, port-resolution, pcapng interface-name, and parser-stop
seams are excluded because public issues or implementations already own them.

See the exact [`UPSTREAM_AUDIT.md`](../../candidates/pcapplusplus-tls-stream-reassembly/UPSTREAM_AUDIT.md).

## Public contract

The feature adds a TLS-aware wrapper around TCP reassembly. It emits complete
TLS records and, for plaintext handshake records, complete handshake messages
whose framing may cross record boundaries. It never decrypts TLS and does not
parse HTTP or DNS.

The public API exposes configuration for maximum record payload and handshake
message sizes; callback data for complete records and handshakes; structured
missing/invalid/incomplete events; callbacks for those values; and packet,
connection, and cleanup operations matching `TcpReassembly`.

Records use the five-byte TLS header, network-order 16-bit payload length,
record types 20 through 23, and legacy record versions `0x0300` through
`0x0303`. Handshakes use a one-byte type and network-order 24-bit payload
length. Callback chunk boundaries do not define protocol boundaries.

Loss clears affected partial record and handshake state. Later bytes are
searched for a plausible record boundary, so recovery is deterministic when a
complete header is present but is not promised to identify cryptographically
ambiguous bytes after capture loss. State is isolated per connection and
direction and is released on close.

## Discriminator ledger

| Evidence | Plausible shortcut | Public invariant | Strongest black-box oracle | Family |
|---|---|---|---|---|
| Packet-local SSL truncates incomplete records | Send each TCP callback directly to `SSLLayer` | Emit only complete records regardless of TCP segmentation | Split every header position and payload; compare exact callbacks | Record framing |
| Saved solvers 1 and 3 discard a four-byte header prefix when the length high byte equals the configured maximum's high byte | Treat an inclusive maximum as exclusive while a header is incomplete | A record exactly at the configured maximum remains eligible for completion | Split an 18 KiB record after header byte four and compare the exact callback | Inclusive bound |
| TCP callbacks may coalesce data | Treat one callback as one record | Emit every complete record in order | Several records in one packet and one record across packets | Segmentation invariance |
| Handshake framing is independent | Parse each handshake record separately or use 16-bit length | Reassemble 24-bit-length messages across records and emit coalesced messages separately | A message above 65535 bytes plus several small messages | Nested framing |
| TCP reports retransmission and out-of-order data | Bypass `TcpReassembly` or append arrival order | Emit each logical record once in sequence order | SYN plus reordered fragments and overlap retransmission | TCP integration |
| Both wrapper packet overloads publish `TcpReassembly::ReassemblyStatus` | Process packets correctly but return one convenient constant | Preserve ordinary, no-data, retransmission, close, closed-flow, non-IP, and non-TCP statuses | Assert parsed-packet branches plus ordinary and non-IP/non-TCP raw-packet branches | Status forwarding |
| TCP gaps carry numeric loss and legacy marker bytes | Ignore loss or join partial bytes around it | Surface loss, invalidate affected partial state, and recover later complete records | Gap inside record/handshake followed by a valid record | Loss/recovery |
| TCP manages both directions and many flows | Use one global buffer or only flow key/last side | Never combine bytes across direction or connection | Interleave partial headers/messages in two directions and flows | Isolation |
| Lengths are attacker-controlled | Allocate declared sizes or accept invalid header fields | Enforce configured bounds, reject invalid headers safely, and recover healthy streams | Invalid type/version/zero/over-limit beside valid records | Bounds/malformed input |
| Oversized handshake bodies may span several TLS records | Clear only currently buffered bytes and parse later body bytes as a new header | Consume the complete declared rejected message before handshake framing resumes | Put header-shaped body bytes in a later record, followed by a valid message | Rejected-message framing |
| TCP packet timestamps differ across a segmented record | Preserve the first fragment's timestamp | Report the timestamp of the callback that completes the record | Split one record across two controlled timestamps | Metadata provenance |
| Connections close naturally or manually | Retain partial state or emit it as complete | Report incomplete bytes and clear state on close | Partial record and handshake on separate sides, then close | Lifecycle |
| Generic TCP supports IPv4 and IPv6 | Special-case IPv4 packet layout | Preserve TLS framing for IPv6 flows | Split IPv6 record and inspect metadata | Cross-family integration |

## Prototype and environment gate

The smallest complete spike changed one public header, one implementation, and
build registration: 408 effective nonblank/non-comment production additions.
It compiled at the exact pin and passed the complete Packet++ aggregate plus
crafted record, handshake, direction, out-of-order, loss, and close probes.
This is more than twice the rejected SNAP scope and its depth comes from three
interacting state machines rather than documentation or examples.

The host lacks CMake. The permitted Olympus base plus CMake, `libpcap-dev`, and
`pkg-config` successfully builds the exact pin. With networking disabled, the
aggregate pre-existing Packet++ target passes. Builds use a temporary directory
outside the checkout and always emit JUnit on setup/build failure.

See [`PROTOTYPE.md`](../../candidates/pcapplusplus-tls-stream-reassembly/PROTOTYPE.md).

## Promotion sequence

1. Freeze only behavior required by the public API above.
2. Add black-box tests for each distinct ledger family and the complete
   Packet++ regression lane.
3. Prove test-only focused failure and reference focused/regression success in
   the offline Docker environment.
4. Run the mandatory exact-version false-positive audit and repository-grounded
   mutations before declaring the hidden suite approved.
5. Search for saved solver patches and replay any relevant result. Do not run a
   cold solver unless explicitly requested.

No calibration result can be carried across an artifact change; calibration is
currently 0/10.

## Exact-package verification

The v18 package was rebuilt from the exact participant artifacts after changing
the description, hidden source, and reference. Canonical hidden-source and
production-source hashes match their respective frozen images. `test.patch`
then `solution.patch` applies cleanly at the pinned checkout, and the solution
also applies cleanly over the frozen test-only tree with strict whitespace
checking. Both images use the checked-in Dockerfile and the exact lanes run as
UID/GID 1000.

| Package | Lane | Result | JUnit |
|---|---|---|---|
| Test-only | `./test.sh ... base` | pass | 1 test, 0 failures |
| Test-only | `./test.sh ... new` | intended fail | 14 tests, 14 failures |
| Reference | `./test.sh ... base` | pass | 1 test, 0 failures |
| Reference | `./test.sh ... new` | pass | 14 tests, 0 failures |

The aggregate baseline executable also reported 259/259 internal Packet++
tests passing. The harness builds in a fresh `mktemp` directory outside the
checkout and emits JUnit for dependency, configure, build, and test failures.
The randomized focused source name is
`Tests/TlsStreamTest/TlsStreamTest_d307d4.cpp`.

## False-positive audit

### Participant requirement map

| Public requirement | Strongest behavioral test |
|---|---|
| Exact `size_t` configuration members, two-limit constructor, defaults, the 18 KiB inclusive boundary, and an exactly-maximal record whose header is split after byte four | `RequiredCallbackOnly` (focused compilation), `SegmentedRecords` |
| Construction with only the required record callback | `RequiredCallbackOnly` |
| Record header/data/payload/type/version/connection accessors and exact completing-packet timestamp provenance, including different timestamps on two fragments | `SegmentedRecords`, `CoalescedRecords` |
| Handshake header/data/payload/type/connection accessors, including opaque unknown types | `HandshakeFraming` |
| Published const-reference connection getters and const connection-query return categories | `RequiredCallbackOnly` (focused target compilation) |
| Missing/invalid/incomplete event type, exact counts, side, and connection | `MissingDataRecovery`, `MalformedAndConfiguredBounds`, `ConnectionLifecycle`, `InitialResynchronization` |
| User-cookie forwarding to record, handshake, event, and TCP lifecycle callbacks | `RawPacketAndCloseAll`, `ConnectionLifecycle` |
| `Packet&` and `RawPacket*` entry points | all stream tests; `RawPacketAndCloseAll` explicitly reparses Ethernet raw data |
| Corresponding TCP status values from parsed and raw packet entry points | `OutOfOrderAndRetransmission`, `RawPacketAndCloseAll` |
| Connection inspection, manual close, close-all, bounded/default purge counts, cleanup state, and a clean recreated tuple | `SegmentedRecords`, `ConnectionLifecycle`, `RawPacketAndCloseAll`, `PurgeClosedConnections` |
| Types 20-23 including refutable type 24, both sides and interior of version range `0x0300`-`0x0303`, network length, nonempty payload, configured/default maximum | `SegmentedRecords`, `CoalescedRecords`, `HandshakeFraming`, `MalformedAndConfiguredBounds` |
| Literal zero record/handshake maxima and exact invalid-data accounting for rejected captured bytes, including a complete max+1 record | `MalformedAndConfiguredBounds` |
| Header recognition on nonstandard ports, split headers, invalid-prefix reporting, and later resynchronization | `CoalescedRecords`, `InitialResynchronization` |
| Arbitrary TCP segmentation and several records in one callback | `SegmentedRecords`, `CoalescedRecords` |
| IPv4/IPv6 ordering, retransmission suppression, and out-of-order delivery | `OutOfOrderAndRetransmission`, `IPv6Stream` |
| Per-direction and per-connection record and nested-handshake state | `DirectionAndConnectionIsolation` |
| Network-order 24-bit handshakes, cross-record carry across non-handshake records, coalesced messages, complete-declared-message discard across later records, resumption after rejection, message-size bound, invalid reporting, independent record emission, and cross-connection isolation | `HandshakeFraming`, `MalformedAndConfiguredBounds` |
| Numeric loss even with zero buffered state, exact affected-side discard, unaffected-side carry, no synthetic-marker invalid event, no record or handshake join across a gap, ordered recovery | `MissingDataRecovery` |
| Per-direction combined incomplete close reporting, TLS-state release, and event-before-end callback order | `ConnectionLifecycle`, `AutomaticFinRstLifecycle` |
| Automatic RST and two-sided FIN closure through packet input | `AutomaticFinRstLifecycle` |

### Mutation construction and isolation

Each mutant was a one-boundary source substitution mounted over the clean
reference image. Every container began from the same immutable image, rebuilt
only the affected production object plus the focused binary, ran offline, and
discarded its overlay afterward. The set came from the packet-local SSL
limitation, `TcpReassembly` behavior, reviewed PcapPlusPlus trajectories, and
the public state-machine boundaries above; it did not target private helper
names or require the reference buffer architecture.

| Mutant | Plausible wrong implementation | Killing scenario |
|---|---|---|
| `single_record` | stop after one record per TCP callback | `CoalescedRecords`, `HandshakeFraming` |
| `handshake_16bit` | ignore the high handshake-length byte | `HandshakeFraming` |
| `handshake_per_record` | clear handshake carry at every TLS record | `HandshakeFraming` |
| `side0` | share both directions' framing state | `DirectionAndConnectionIsolation`, `ConnectionLifecycle` |
| `global_flow` | share framing state across flow keys | `DirectionAndConnectionIsolation`, `ConnectionLifecycle` |
| `version_0303` | recognize only TLS 1.2 record headers | `CoalescedRecords` |
| `accept_zero` | accept zero-length records | `MalformedAndConfiguredBounds` |
| `ignore_record_limit` | ignore configured record bound | `MalformedAndConfiguredBounds` |
| `ignore_handshake_limit` | ignore configured handshake bound | `MalformedAndConfiguredBounds` |
| `keep_loss_state` | retain partial record/handshake bytes across a TCP gap | `MissingDataRecovery` |
| `wrong_loss_event` | classify TCP loss as generic invalid TLS | `MissingDataRecovery` |
| `wrong_loss_count` | report an off-by-one missing-byte count | `MissingDataRecovery` |
| `omit_close_event` | silently drop incomplete state at close | `ConnectionLifecycle` |
| `no_resync` | examine only offset zero for a record boundary | `MissingDataRecovery`, `MalformedAndConfiguredBounds`, `InitialResynchronization` |
| `raw_stub` | leave the `RawPacket*` overload as a stub | `RawPacketAndCloseAll` |
| `closeall_stub` | leave close-all as a stub | `RawPacketAndCloseAll` |
| `ipv4_only` | reject IPv6 packets before TCP reassembly | `IPv6Stream` |
| `cookie_null` | replace the caller's cookie with null | `RawPacketAndCloseAll` |
| `config_defaults` | use a smaller undocumented default record limit | `SegmentedRecords`, `HandshakeFraming` |
| `timestamp_default` | expose an epoch/default record timestamp | `SegmentedRecords` |
| `automatic_close_ignored` | ignore the TCP engine's automatic FIN/RST connection-end callback | `AutomaticFinRstLifecycle` |
| `required_args` | require a user cookie or other constructor arguments documented as optional | `RequiredCallbackOnly` (focused target compilation) |
| `gap_marker_unstripped` | parse `TcpReassembly`'s generated missing-data text as captured TLS bytes | `MissingDataRecovery` |
| `shared_handshake_direction` | isolate record buffers but share nested handshake state between directions | `DirectionAndConnectionIsolation` |
| `handshake_cookie_null` | forward the cookie to other surfaces but pass null to handshake callbacks | `RawPacketAndCloseAll` |
| `event_cookie_null` | forward the cookie to other surfaces but pass null to reassembly-event callbacks | `RawPacketAndCloseAll` |
| `purge_stub` | expose cleanup but always return zero and retain closed flow information | `PurgeClosedConnections` |
| `event_side0` | report every reassembly event as direction zero | `ConnectionLifecycle` |
| `gap_clears_other_direction` | erase the opposite direction's handshake carry on a TCP gap | `MissingDataRecovery` |
| `nonhandshake_clears_handshake` | erase an incomplete handshake when an application/alert record intervenes | `HandshakeFraming` |
| `default_16k_record_limit` | silently cap the published 18 KiB default at the conventional 16 KiB size | `SegmentedRecords` |
| `close_split_events` | emit separate close events for one direction's record and handshake buffers | `ConnectionLifecycle` |
| `version_endpoints_only` | accept `0x0300` and `0x0303` but reject the intermediate versions | `CoalescedRecords` |
| `purge_default_required` | omit the published default argument on cleanup | `PurgeClosedConnections` (focused target compilation) |
| `invalid_discard_one` | report one discarded invalid byte for every resynchronization batch | `InitialResynchronization` |
| `close_end_before_event` | forward the connection-end callback before incomplete TLS events | `ConnectionLifecycle` |
| `record_limit_exclusive` | treat the configured maximum as exclusive | `SegmentedRecords` |
| `constant_packet_status` | process parsed packets but always return `TcpMessageHandled` | `OutOfOrderAndRetransmission`, `AutomaticFinRstLifecycle` |
| `constant_raw_status` | process raw packets but always return `TcpMessageHandled` | `OutOfOrderAndRetransmission` |
| `accept_type24` | extend the record-type range one value past its upper bound | `MalformedAndConfiguredBounds` |
| `zero_record_unlimited` | treat a zero record maximum as an unlimited sentinel | `MalformedAndConfiguredBounds` |
| `zero_handshake_unlimited` | treat a zero handshake maximum as an unlimited sentinel | `MalformedAndConfiguredBounds` |
| `suppress_record_on_oversized` | suppress a complete record when its inner handshake is over limit | `MalformedAndConfiguredBounds` |
| `stale_connection_state` | retain TLS buffers at close and reuse them on a recreated tuple | `PurgeClosedConnections` |
| `record_connection_by_value` | return record connection metadata by value | `RequiredCallbackOnly` (focused target compilation) |
| `handshake_connection_by_value` | return handshake connection metadata by value | `RequiredCallbackOnly` (focused target compilation) |
| `event_connection_by_value` | return event connection metadata by value | `RequiredCallbackOnly` (focused target compilation) |
| `connection_info_by_value` | copy connection information instead of returning the published const reference | `RequiredCallbackOnly` (focused target compilation) |
| `isopen_bool` | collapse the three-state connection query to `bool` | `RequiredCallbackOnly` (focused target compilation) |
| `config_limits_uint32` | narrow the two public configuration fields to `uint32_t` | `RequiredCallbackOnly` (focused target compilation) |
| `accept_lower_version` | check only the upper version bound and accept `0x02ff` | `MalformedAndConfiguredBounds` |
| `timestamp_now` | stamp records with wall-clock completion time instead of the completing packet timestamp | `SegmentedRecords` |
| `gap_keeps_handshake_only` | clear partial record bytes on loss but retain the affected handshake accumulator | `MissingDataRecovery` |
| `suppress_empty_gap` | emit `TcpDataMissing` only when TLS state was discarded | `MissingDataRecovery` |
| `silent_zero_record` | treat a zero record maximum as a silent parser-disable switch | `MalformedAndConfiguredBounds` |
| `silent_oversized_handshake` | clear an oversized handshake without reporting its discarded bytes | `MalformedAndConfiguredBounds` |
| `underreport_overlimit_record` | reject and remove a complete max+1 record but under-report its discarded encoded bytes | `MalformedAndConfiguredBounds` |
| `timestamp_first_fragment` | retain the timestamp of a segmented record's first TCP fragment | `SegmentedRecords` |
| `oversized_forgets_remaining` | discard only the buffered prefix of an oversized handshake and parse later body bytes as a new message | `MalformedAndConfiguredBounds` |

All 59 actionable mutants were killed by the exact v18 14-scenario focused
suite; 51 compiled and failed behaviorally, while eight public-interface mutants were
rejected when the focused target compiled the published calls and const query
surface. The first audit
iteration exposed one genuine survivor:
`keep_loss_state` emitted a
fabricated record spanning a reported TCP gap and later also emitted the valid
record, so an existence-only recovery assertion passed. That implementation
also passed the full pre-existing suite (259/259). The added exact-sequence
probe passes the reference, kills this survivor, and directly enforces the
public no-fabrication rule. Replaying the actionable set against the revised
artifact left zero focused survivors, so there was no remaining actionable
mutant to promote to a full-suite run.

The v17 review had exposed a second genuine focused survivor:
`underreport_overlimit_record` rejected a complete record solely because its
payload was max+1, removed all of it, and recovered the following valid record,
but reported one fewer discarded byte. It passed v16, while the summed exact
accounting assertion fails only `MalformedAndConfiguredBounds`. V18 adds the
two new transition mutants above; each is killed by its intended existing
scenario. The complete 59-mutant run has no survivor requiring full-suite
escalation.

An attempted one-site version of `invalid_discard_one` survived because the
fixture legitimately discarded two bytes in one path and one in a second path;
changing only the second report did not violate the observed total. It was
rejected as an incomplete mutation, replaced by the plausible constant-one
reporting mode across both batch paths, and that actionable mutant failed
`InitialResynchronization`. An initial incremental mutation pass was also
discarded because Docker preserved source timestamps and reused the first
mutant's object. The first v18 rerun was separately discarded because the
`keep_loss_state` substitution no longer matched the revised reset block; it
was repaired and the entire set restarted. The final 59/59 result comes only
from that clean rerun, which touched and rebuilt each isolated source or header
before execution.

The v18 fairness revision prototyped a different valid rejection architecture.
Instead of tracking a remaining-byte count, it retains an oversized declared
message until all of its bytes have arrived, discards and reports the complete
message in one batch, and then resumes header parsing. Its verified source diff
contains no remaining-byte state and passes 14/14. This proves the split-body
probe observes framed-message behavior without prescribing the reference's
streaming-discard mechanism.

The later cleanup review promoted `purge_stub` from a recorded timing-only
survivor to an actionable forwarding fault. `TcpReassembly` exposes no injected
clock and clamps a zero cleanup delay, but its repository implementation uses
the process's C `time()` seam. The focused executable supplies a controlled
clock for that existing engine, advances it past the configured expiry, and
checks bounded/default purge counts plus connection state without sleeping or
polling. The scenario completes in 0.00 seconds, passed 100 consecutive exact
replays, and kills the stub. This instrumentation is fair for the published
TCP-forwarding contract: an implementation that forwards to the required
existing engine observes the same deterministic clock, without exposing or
selecting TLS storage internals.

Rejected mutation ideas included reliance on a particular container type,
private helper call order, decryption behavior, HTTP/DNS parsing, or arbitrary
TLS-port permutations. They either constrain an implementation detail, are
explicitly out of scope, or add no discriminator beyond the nonstandard-port
probe already present. Zero actionable survivors applies only to this
attempted, repository-grounded mutation set.

The final description-quality pass removed the redundant forwarding detail
while retaining new names, defaults, ordering, event getters, and non-inferable
return categories. The v18 easing names only the three Packet++ SSL return
types that all five second-batch solvers guessed differently; no runtime rule
was removed. The requirement map above was repeated against the final 458-word
description. The exact four package lanes, all 59 isolated mutants, all ten
saved solvers, and the buffered-rejection alternative were rerun against the
final prompt and test hashes; these are not inherited results from an earlier
artifact version.

## Saved-solver check

Ten saved TLS solver patches are present across `agent-runs1` and
`agent-runs2`. Each exact patch was applied over the v18 test-only image and
run as UID/GID 1000. The complete reference regression is 259/259; all saved
patch baselines were green in their original evaluation records. V18 focused
results for the first batch are:

| Saved solver | Final focused result | Interpretation |
|---|---|---|
| `agent-runs1/Nova_Nova_1` | 12/14; `SegmentedRecords`, `MalformedAndConfiguredBounds` | exact-limit split-prefix rejection; later split oversized body is misframed |
| `agent-runs1/Nova_Nova_2` | 13/14; `MalformedAndConfiguredBounds` | oversized inner rejection is not reported as invalid data |
| `agent-runs1/Nova_Nova_3` | 12/14; `SegmentedRecords`, `MalformedAndConfiguredBounds` | exact-limit split-prefix rejection plus silent inner rejection |
| `agent-runs1/Nova_Nova_4` | 12/14; `SegmentedRecords`, `MalformedAndConfiguredBounds` | first-fragment timestamp plus incomplete split-oversize accounting |
| `agent-runs1/Nova_Nova_5` | 13/14; `MalformedAndConfiguredBounds` | later split oversized body is misframed |

All five exact second-batch patches fail focused target compilation because they
return raw integers from the three getters. To test the easing rather than
relabeling those compile failures, a separate mechanical replay changed only
the three return types/conversions and added the necessary existing SSL header.
Every solution then compiled and reached 13/14: runs 1 and 4 failed only
`MalformedAndConfiguredBounds`, while runs 2, 3, and 5 failed only
`MissingDataRecovery`. These normalized runs are diagnostic verification, not
saved-solver or calibration outcomes. They demonstrate that publishing the
types removes the repeated integration trap while leaving one substantive
state-machine miss per solution.

The independently buffered oversized-message implementation passes 14/14.
Neither saved batch counts toward this immutable revision, which remains at
0/10. No cold solver was run.

## Immutable artifact identifiers

Repository pin: `8ac4366c4184f096973ef4a0ca084559935828d0`.

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `1f1bede4ecb0f6a9e88e5121e9bcb7f1148b9acc16c2e14861b89016edda262e` |
| `Dockerfile` | `db856366a98e81addef3565da1710d827a35344bf66af2109be2052a480d25e6` |
| `solution.patch` | `0486854afd97a761ae1bbd04e6f25777eb3da6593958c709b8cefe26d399d245` |
| `test.patch` | `27ed90ce46b01ec084237a7bc357b8519b381fd6417ae5e9d47d6b6d3142d347` |

Exact local verification images:

- test-only: `sha256:8048d2565c7aeb181b64b9f7c7325cb8eb017790906170ef1a153d0e50f91605`
- reference: `sha256:17462585fc686abda977120970c6d44a8e5e4168b5205ea6666a92586f53c728`

Any participant artifact change invalidates this audit and restarts both the
checks above and future calibration from 0/10.
