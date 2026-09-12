# smoltcp: deliver ICMP errors to sockets and learn the path MTU

## What this is

`smoltcp-rs/smoltcp` at `f96a26b5968735d142e6999a016060bc5d3ab2b7`, Rust, 0BSD, 4547 stars.
Incoming ICMP errors reach `process_icmpv4` / `process_icmpv6`, get offered to ICMP sockets, and
then fall into a catch-all arm that the source itself marks `// FIXME: do something correct here?`.
Nothing else in the stack ever sees them, so there is no path MTU discovery either. Open issue
#1071 asks for the TCP half of it; the README lists PLPMTUD as missing.

## Why this pick

- Behavioural F2P, not a performance question: a segment too large for the path is retransmitted at
  the same size forever, and a connection into a black hole never finds out.
- The core is cold. `trustfall`-style hot-repo risk does not apply here: `src/socket/icmp.rs` has 2
  commits in the trailing 12 months, `src/wire/icmpv4.rs` 1, `src/iface/route.rs` 4. The only PR
  ever filed about path MTU (#277) just documented that it was missing.
- Exclusivity is clean. `gh pr list --state all` for icmp / mtu / "too big" / unreachable turns up
  nothing that implements either half. The nearby open PRs are #902 VLAN, #933 receive window
  resizing and #1111 silly-window avoidance, all deliberately avoided.
- Deterministic to test end to end: time is a caller-supplied `Instant`, the device is a trait, no
  network, no threads. 672 existing tests run in 0.32s.

## What was built

`src/iface/pmtu.rs` is new: a four-entry per-destination cache with the RFC 1191 plateau table,
clamping, and probing back up. `InterfaceInner` gained `ip_mtu_to(dst)` and a `process_icmp_error`
that parses the quoted header, checks it was ours, records a path MTU when the message carries one,
and hands the error to the tcp, udp and raw socket that sent the quoted packet. The ICMPv4 and
ICMPv6 ingress paths route their error variants into it. `tcp::Socket` gained the state table plus
sequence-window validation, and both its effective-MSS sites now size from the destination's path
MTU while the SYN's advertised MSS keeps coming from the interface MTU. The egress path sizes IPv4
fragmentation and the IPv6 too-big check from the same place.

One fix was forced along the way and is worth calling out, because it is the wall a natural
implementation hits first. `Icmpv4Repr::parse` built the quoted packet with `Ipv4Packet::new_checked`,
whose `check_len` requires the buffer to hold the quoted packet's whole `total_len`. Real routers
quote the header plus eight bytes, so every real ICMPv4 error failed to parse and was dropped before
any of this ran. ICMPv6 already did the right thing (`create_packet_from_payload` uses
`new_unchecked` and checks only the header), so the two were inconsistent. `parse_quoted_packet`
brings v4 in line.

## Validation

- 672 library tests green before and after; 81 new tests green. Doc tests are excluded from the regression set, see the FAIL section below.
- F2P: with only `test.patch` applied at the base commit, all 81 fail (the API does not exist, so the
  test binary does not compile and `test.sh` synthesises one failing node per `#[test]`). Base mode
  at the same commit is 672 green.
- Both patches apply cleanly to a pristine checkout, in that order.
- Flakiness: 3 runs of each mode, identical counts every time; JUnit output is sorted so the bytes
  are identical too.
- LOC: 675 raw / 495 under the platform's Counter 1 / 383 human-effective across 10 files.
- No `shipd` or `datacurve` in any test path. `test.sh` is mode 100755 in the patch.
- Docker: image builds from a clean base checkout, and inside it, offline (`--network none`)
  and as UID 1000, both patches apply and `test.sh` reports 30/30 new green, 679 base green,
  and 30/30 failing when only the test patch is applied. 3 runs of each mode inside the
  container, byte-identical output.

## Dockerfile, round 2

The first image failed the platform build. Two things, only the first of which was mine:

- `cargo build --all-targets` drags in `benches/bench.rs`, which opens with `#![feature(test)]`
  and only compiles on nightly. `cargo build --workspace --tests` builds the lib and every test
  target and skips benches, and is also the invocation the rubric asks for.
- The checker warned that Cargo.lock should be committed for a pinned build. It is not, and cannot
  be: smoltcp gitignores it (`.gitignore:2`). Adding `--locked` on that basis made the build fail
  harder ("cannot create the lock file /app/Cargo.lock"). The lock is resolved once during the image
  build and frozen into the image, which is what actually pins the agent's offline build.

The third warning, `chmod -R a+rwX`, is kept on purpose: the agent runs non-root with no network and
has to write the cargo cache, the generated lock file and `target/`. This matches the approved Rust
submissions.

## Coverage check response

The AI quality check came back WARNING on test coverage, naming five declared API elements no test
touched. All five are now covered rather than argued about:

- `IcmpError::is_hard()` was never called: `errors_are_split_into_hard_and_soft` asserts it over all
  nine variants.
- `SrcRouteFailed` and `Prohibited` were unreachable in the suite: `a_failed_source_route_aborts_a_connection_attempt`
  and `a_prohibited_route_aborts_a_connection_attempt` (the latter over all three prohibited codes,
  9, 10 and 13) cover them.
- `PacketTooBig { mtu }` was only observed through `Interface::pmtu`, never as a value handed to a
  socket: `a_socket_is_told_its_packet_was_too_big` asserts both at once.
- `ParamProblem` had no path at all, since ICMPv4 has no such message in this stack:
  `a_parameter_problem_reaches_the_socket_that_sent_the_packet` drives it over ICMPv6.

The too-big test deliberately reports 900, a value that survives both the ceiling and the floor, so
it does not silently pin whether the socket is handed the reported MTU or the recorded one. The
description does not say which, so no test should decide it.

25 tests became 30. Solution unchanged.

## Behaviour-focus check response

A second quality check came back WARNING on one over-specific assertion:
`segments_shrink_to_the_learned_path_mtu` pinned the pre-error segment to exactly 1500 bytes, which
would reject a compliant implementation that chose to send smaller segments. Relaxed to
`first_len <= IFACE_MTU`, plus `first_len > 900` so the test keeps its point: if the first segment
already fitted the path MTU the error is about, shrinking it afterwards would prove nothing. A bare
`<=` would have let the test pass vacuously.

The two other exact assertions were reviewed and kept deliberately:

- `max_seg_size == Some(1460)` (1500 minus the IP and TCP headers) IS the discriminator for "the MSS
  advertised in a SYN still comes from the interface MTU". Relaxing it to `<=` would let an
  implementation that wrongly advertises the path MTU, 860, pass.
- `total_payload == 1208` (1200 bytes of data plus the UDP header) is fixed by the input, not by any
  implementation choice; it asserts fragmentation lost no bytes.

Solution unchanged.

## Verify Solution FAIL: line-numbered doc tests (the real bug)

The wrapper run came back FAIL with one node:

    smoltcp.src/socket/tcp.rs - socket.tcp.Socket<'a>.connect (line 978) - compile (failed)

Baseline was 679 green and the 30 new tests were 30 green, so nothing was actually broken. Rustdoc
names a doc test after the line its example starts on. The solution inserts code into
src/socket/tcp.rs above line 978, so the `connect` example moves and the node is renamed. A
regression check keyed on names reads the old name as missing, i.e. failed.

This is not cosmetic: EVERY correct solution to this task edits src/socket/tcp.rs, so the doc test
is renamed no matter what an agent writes. Left in, the regression set would have failed every
submission including a perfect one.

Fix: base mode runs `cargo test --lib` only, and the reason is written into test.sh next to the
command. The regression set is 672 unit tests, whose names are module paths and are stable under
insertion. Same class as the mq-charsplit rstest renumbering trap: a baseline is only usable if its
node identities cannot move when the source under it changes.

## Coverage suggestions, round 2

Six advisory suggestions, all now covered:

- Error-latch replacement: `the_last_error_reported_is_the_one_handed_over` reports two different
  errors before reading, asserts the second wins and the read clears it.
- Outstanding TCP range boundary: `only_a_sequence_still_outstanding_is_acted_on` walks both edges
  of the window, one past the upper edge, and a sequence the peer has since acknowledged.
- PMTU origin validation: `no_path_mtu_is_learned_from_a_packet_we_did_not_send` and
  `no_path_mtu_is_learned_from_a_quote_too_short_to_read` assert the cache stays empty, not just
  that no socket heard about it.
- Multiple entries and flush: `flushing_forgets_the_path_mtu_of_every_destination` learns two
  destinations before flushing.
- IPv6 socket notification: `an_ipv6_socket_is_told_its_packet_was_too_big` reports 1300, which sits
  between the IPv6 floor and the interface MTU so nothing clamps it. That is deliberate: the
  description does not say whether the socket sees the reported or the recorded MTU, so the test
  must not decide it.
- Raw version filtering: `a_raw_socket_bound_to_another_ip_version_is_not_told`.

30 tests became 37. Solution unchanged.

## Description check + coverage, round 3

The description check returned request_changes on one HIGH item, and one of the advisory coverage
suggestions turned out to point at a real bug.

- HIGH, removed: "ICMP sockets keep receiving these messages as before." It is a generic
  do-not-break-things line. Removing it meant the test that asserted it was hanging off a sentence
  that no longer exists, and that test was weak anyway: on base it only failed because the file did
  not compile, not because the behaviour differed. It is now
  `an_error_reaches_both_the_icmp_socket_and_the_sender`, which asserts the icmp socket still gets
  the message AND the udp socket that sent the quoted datagram gets the error. That is new
  behaviour, covered by "report the error to it", so it stands on its own.
- MEDIUM, taken: dropped the sentence describing how the code currently handles these messages.
  The motivation stayed. 489 words to 472.

**The suggestion that found a bug.** "Test a hard error against a TCP socket in SynReceived, since
the prompt says a socket still opening rather than only an active-open SynSent socket." The prompt
was right and the code was wrong: it only aborted in `SynSent`. RFC 5927 and Linux both abort in
SynReceived too, and "still opening its connection" plainly covers it. Fixed in tcp.rs
(`matches!(self.state, State::SynSent | State::SynReceived)`) and pinned by
`a_hard_error_aborts_a_connection_being_accepted`, which drives a real passive open. This is the
first solution change since the first submission.

Also added: `the_error_type_carries_the_derives_the_api_promises` (compile-time bound on
Debug + Clone + Copy + PartialEq + Eq), `an_error_quoting_the_wrong_port_on_either_side_is_ignored`
and `a_udp_socket_ignores_an_error_quoting_another_port` (each port dimension separately), and
`icmpv6_reasons_map_onto_the_same_errors` (five ICMPv6 type/code pairs through real packet parsing).

The one suggestion not taken: IPv4 parameter-problem. smoltcp's `Icmpv4Repr` has no such variant, so
the message is not parsed at all and falls through untouched, exactly as on base. Adding the variant
would be a wire-format change well outside this feature. `ParamProblem` is reachable and tested over
ICMPv6.

37 tests became 42.

## Test Fairness FAIL: three unstated pins, round 4

3 of 45 flagged unfair. All three critiques were right, and all three were the same mistake: a test
asserting a choice my implementation happens to make that the description never states. Fixed by
removing the pin, not by growing the description, since none of the three could be stated in a
sentence that was not itself an over-enumeration.

- `a_report_during_a_probe_lowers_the_path_mtu_again` pinned that an overdue upward probe is applied
  BEFORE a simultaneous zero-MTU report is interpreted (at 1201s the probe had reached 1492, so zero
  meant 1006). Nothing says which happens first; reading the report against the stored 900 and
  landing on the floor is just as defensible. Replaced by
  `a_report_before_the_probe_interval_still_lowers_the_path_mtu`, which reports at 300s, inside the
  first holding period, where no probe is pending and the outcome follows from the stated rules
  alone.
- `only_a_sequence_still_outstanding_is_acted_on` required a quote at exactly `base + 100` after 100
  bytes to be accepted. Those bytes are `base` through `base + 99`; `base + 100` is the ACK boundary,
  and the repo's own comment at src/socket/tcp.rs:487 says as much. That was my inclusive interval
  leaking into a test. Now checks `base`, `base + 99` and `base + 500`, all unambiguous under either
  reading.
- `icmpv6_reasons_map_onto_the_same_errors` required ICMPv6 NoRoute to become `NetUnreachable` and
  AddrUnreachable to become `HostUnreachable`. Those are IPv6-only names with no stated collapse into
  this enum, and mapping both to `HostUnreachable` is equally consistent. Dropped both rows; the
  three whose names carry over directly (Prohibited, PortUnreachable, TimeExceeded) stay.

The implementation was NOT changed for any of these. Each remains free to do what it does; the tests
simply no longer grade it on an unstated choice.

## Coverage suggestions, round 4

All three advisory items added:

- `a_learned_ipv6_path_mtu_constrains_what_is_sent`: previously the IPv6 tests only inspected stored
  PMTU and socket errors, never emission. Asserts a datagram within the learned size still goes out,
  and that nothing larger than the learned size is emitted. Deliberately does not assert that the
  oversized datagram is dropped, which would pin drop-versus-fragment.
- `a_soft_error_leaves_an_open_connection_alone`: the soft-error-on-established quadrant was the one
  missing from the state matrix.
- `an_ipv6_raw_socket_is_told_about_errors_for_its_protocol`: raw had an IPv4 positive and two
  negatives, but no IPv6 positive.

42 tests became 45.

## Coverage suggestions, round 5

Five advisory items, no FAIL. Four taken as asked; two needed care, because taking them literally
would have re-created the exact unfairness round 4 removed.

- Additional ICMP reason mappings. The suggestion asks specifically for "no-route/address-unreachable
  and policy/reject-route normalization" - the same normalization the fairness check flagged as an
  unstated cross-family policy. Covered in a form that does not pin it:
  `every_icmpv6_reason_that_cannot_reach_the_destination_is_hard` drives codes 0, 2, 3, 5 and 6 and
  asserts only that each produces a hard error, which the description does state. Which named
  variant each becomes stays free. Also added `an_icmpv4_parameter_problem_disturbs_nothing`:
  smoltcp's `Icmpv4Repr` has no parameter-problem variant, so the right assertion is that the
  message changes neither socket state nor PMTU, which is also what base does.
- Raw wildcard bindings: `a_raw_socket_bound_to_no_particular_protocol_is_told`, following the
  existing `None`-matches-anything convention in src/socket/raw.rs.
- Malformed input: `an_error_whose_checksum_is_wrong_is_ignored` and
  `an_icmpv6_error_quoting_less_than_a_header_is_ignored`. Both assert no socket error AND no PMTU
  change, so a malformed message cannot poison the cache.
- IPv4 fragment correctness: `the_fragments_of_a_datagram_reassemble_to_the_original` checks the
  more-fragments flag on every fragment, that each offset is where the previous fragment ended,
  eight byte alignment, and that concatenating the payloads parses back into the original UDP
  datagram with its ports and its exact 1200 bytes.
- PMTU aging boundaries: took the half that is stated, skipped the half that is not. The exact
  600 second instant is ambiguous (the description says a report holds for ten minutes without
  saying which side of the boundary the step falls on), and the previous fairness pass explicitly
  praised the suite for avoiding it, so asserting there now would be a self-inflicted regression.
  Whether a fresh report restarts the probe clock is likewise unstated.
  `a_fresh_report_holds_at_its_new_size` samples at 300, 400 and 550 seconds, all inside ten minutes
  under either reading, so it covers the fresh-report path without deciding the schedule question.

45 tests became 52.

## Test Fairness FAIL, round 6: one ambiguity, thirteen tests

13 of 52 flagged, all the same root cause, and it is a real ambiguity in my own description. Every
PMTU test learned its value with an EMPTY `SocketSet`. The description says an error is acted on
only when its addresses and ports match a socket, and then separately says the two MTU errors record
a path MTU. It never says PMTU recording is exempt from the socket-match rule, so "no socket means
no PMTU update" is an equally defensible implementation, and thirteen tests were grading mine.

Two ways out. Spend words exempting PMTU from the socket-match rule, or stop depending on the
question. I took the second: every one of the thirteen now has a UDP socket bound to the quoted
source port, so the report matches a socket and BOTH readings agree it is acted on. The tests assert
exactly what they did before; they just no longer rest on the ambiguous case.

This is better than the wording fix for two reasons. The description keeps its remaining 28 words of
headroom, and the implementation stays free: whether PMTU is recorded before or after the socket
match is still the author's business, and nothing grades it either way.

## Coverage suggestions, round 6

- TCP non-opening states: `a_hard_error_leaves_a_closing_connection_alone` drives a real close into
  `FinWait1` and checks that a hard error there records without tearing the connection down, which
  is the "every other state" rule beyond the established case.
- Socket-match/PMTU interaction: `a_socket_bound_elsewhere_is_not_told_its_packet_was_too_big` adds
  the nonempty-but-nonmatching socket case, asserting only the socket side. It deliberately does not
  assert what happens to PMTU there, since that is the very question the description leaves open.
- PMTU expiry at exactly 600 seconds: NOT added, deliberately. The description says a report holds
  for ten minutes without saying which side of the boundary the step falls on. An earlier fairness
  pass specifically credited this suite for avoiding that instant, so asserting it now would
  manufacture a fresh unfair test to satisfy an advisory note. The 599 and 601 samples already fix
  the behaviour on both sides of it.

52 tests became 54.

## Coverage suggestions, round 7

Three advisory items, all added. 54 tests became 59.

- IPv6 negative matching: `an_icmpv6_error_quoting_a_packet_we_did_not_send_is_ignored` and
  `an_icmpv6_error_quoting_another_port_is_ignored`. The ownership and port guards had only been
  exercised over IPv4.
- Latest-error semantics across socket kinds: `a_tcp_socket_also_keeps_only_the_latest_error` and
  `a_raw_socket_also_keeps_only_the_latest_error`. Overwrite of an unread prior error had only been
  asserted on UDP.
- TCP sequence wraparound: `a_send_window_that_crosses_the_wrap_is_still_matched_correctly`.

The wraparound one took two attempts and the first was wrong in an instructive way. I first tried to
detect the straddle by comparing sequence numbers, `base + queued > base`, and searched two million
seeds without a hit. That condition can never be false: smoltcp's `SeqNumber` implements `PartialOrd`
as `self.0.wrapping_sub(other.0).partial_cmp(&0)`, so a window that crosses the numeric boundary
still compares in the right order. That IS the safety property, so it cannot be used to find the
case that tests it. The straddle has to be recognised on the raw value, `base.0 > 0 &&
(base + queued).0 < 0`, which is also exactly the shape that breaks an implementation comparing
`i32`s directly.

Our initial sequence number is random, so the test searches seeds for one that starts a connection
within a megabyte of the top of the space, then asserts that precondition before testing anything.
It cannot silently degrade into testing nothing. The search is deterministic and finds a seed
immediately; the whole test runs in 0.02s.

Mutation-proven rather than assumed: replacing the wrap-safe comparison in
`Socket::process_icmp_error` with `seq.0 < unacked.0 || seq.0 > sent_through.0` fails this test and
ONLY this test. `only_a_sequence_still_outstanding_is_acted_on` still passes under that mutation,
which is precisely why the suggestion was worth taking.

## Test Fairness FAIL, round 8: two causes, both fixed in the solution

4 of 59 flagged, and unlike round 6 the fix belonged in the code, not the fixtures.

**Cause A, three tests.** `an_open_connection_survives_a_hard_error`,
`a_soft_error_leaves_an_open_connection_alone` and `a_tcp_socket_also_keeps_only_the_latest_error`
each quoted a sequence number on an idle established connection that had sent no data. The
description says a TCP error is acted on only when the quoted sequence is one the socket still has
outstanding, and on an idle connection nothing is outstanding, so those reports should not have been
acted on at all. My window was `[local_seq_no, local_seq_no + tx_buffer.len()]`, inclusive at both
ends, which on an idle socket is a single point that still matched.

Round 4 had already flagged the inclusive upper end for the same reason, and this round's coverage
note asks for the exclusive boundary explicitly. Two passes pointing the same way is a code smell,
not a test smell, so the window moved to what the sentence actually says: sent, and not yet
acknowledged, `[local_seq_no, remote_last_seq)`. That is correct on every case the suite drives -
the SYN and the SYN|ACK each consume a sequence number so they stay inside it, a FIN does too, and
an idle connection now has an empty window. The three tests were rewritten to put 100 bytes in
flight first, and `only_a_sequence_still_outstanding_is_acted_on` gained the right-edge case:
`base + 100`, one past the last byte sent, is now rejected.

**Cause B, one test.** `an_icmpv4_parameter_problem_disturbs_nothing` required an ICMPv4 parameter
problem to be silently ignored. The check is right that this contradicts the description: it
advertises a version-neutral `ParamProblem` and asks for errors to be reported, and nothing exempts
IPv4. The old behaviour was an accident of the wire layer, whose `Icmpv4Repr` had no such variant, so
the parser returned `Err` for type 12 and the message vanished. Fixed properly: `Icmpv4Repr` gained a
`ParamProblem` variant with its pointer field, plus parse, emit, `buffer_len` and `Display`, and the
ingress path maps it like every other error. The test is now the positive case the coverage note
asked for. `ParamProblem` is reachable over both IP versions, which is what the description always
claimed.

## Coverage suggestions, round 8

- ICMPv4 parameter problem positive: covered by the fix above.
- TCP outstanding-window right edge: covered by the new `base + 100` case.
- PMTU socket-match prerequisite: this asked to assert that NO path MTU is learned without a matching
  socket. That is the same ambiguity round 6 flagged from the other side, so instead of pinning it
  from a test I spent 12 words closing it: the description now says both MTU errors record a path MTU
  "whether or not a socket matches it". `a_path_mtu_is_learned_even_with_no_socket_to_tell` then
  tests it as stated. Two consecutive rounds circling one sentence is a sign the sentence was
  missing, not that the tests were wrong.
- Generic PMTU API input: `the_path_mtu_of_a_destination_can_be_asked_for_as_an_ip_address` calls
  `Interface::pmtu` with `IpAddress` values of both families, exercising the promised `Into<IpAddress>`.

The wraparound test needed rework, since the outstanding window is now what was sent rather than what
was queued, and one poll sends about 64 KB rather than the whole megabyte. The seed search now runs
over one interface instead of rebuilding it per candidate (each `connect` draws a fresh initial
sequence number), which keeps it at about a second. Re-proven by mutation: with
`seq.0 < unacked.0 || seq.0 >= sent.0` it is still the only test that fails.

59 tests became 61. LOC rose to 675 raw / 383 human-effective, Counter 1 495, from the wire-layer work.

## Test Fairness FAIL, round 9: one test, and it was mine to lose

1 of 65 flagged. `no_path_mtu_is_learned_from_a_quote_too_short_to_read` fed a complete IPv4 header
plus four transport bytes and required the whole report to be ignored. The check is right: four
bytes carry both ports, and the path MTU is keyed on the quoted addresses, which are fully present.
An implementation that records the MTU from that quote is defensible, and nothing in the description
or the repository singles out an eight-byte minimum before PMTU learning. My implementation ignores
it only because `parse_quoted_packet` demands the eight bytes a TCP sequence needs.

Replaced with `nothing_is_learned_from_a_quote_shorter_than_an_ip_header`, which truncates to twelve
bytes. That is short of an IPv4 header, so the quote names neither a sender nor a destination and
there is nothing any implementation could act on. The malformed-input coverage survives in a form
that has only one defensible answer; the checksum test and the ICMPv6 short-header test already
cover the rest of that ground and both were rated fair.

## Coverage suggestions, round 9

- Address-bound UDP matching: `a_udp_socket_bound_to_one_address_ignores_an_error_for_another` puts
  two IPv4 addresses on one interface, binds the socket to the second, and quotes a datagram sent
  from the first. Both are local, so only the address comparison can reject it. The default build
  allows two interface addresses, so this test builds its own interface rather than using the shared
  helper.
- ICMPv6 TCP integration: the TCP close and sequence-matching tests were all IPv4.
  `an_icmpv6_hard_error_aborts_a_connection_attempt` and
  `an_icmpv6_error_quoting_a_sequence_we_never_sent_is_ignored` drive a real IPv6 connection through
  both paths.
- IPv6 oversized-send outcome: the previous assertion passed vacuously if nothing was emitted at
  all. It now sends a fitting datagram AFTER the oversized one and requires that to appear, so a
  send path that simply stopped working fails. It still does not assert whether the oversized
  datagram is dropped or errored, since the description does not say and this repository has no IPv6
  fragmentation.

61 tests became 64.

## Coverage suggestions, round 10

Three advisory items, all added. 64 tests became 65.

- PMTU timer refresh. `a_fresh_report_holds_at_its_new_size` now samples at 700 and 899 seconds and
  then at 901. The first report lands at 0 and the second at 300, so 700 is past the first report's
  ten minutes but inside the second's, and 901 is just past the second's. That is the case I declined
  in round 5 as unstated. It is not: "a report holds for ten minutes" is about a report, and each one
  brings its own ten minutes, which is why the fairness pass has rated this test prompt-stated twice
  while asking for exactly this extension. Mutation-proven: keeping the original timestamp when a
  later report updates an entry (`existing.mtu = mtu` instead of replacing the whole entry) fails
  this test and only this test.
- TCP PacketTooBig recording. `segments_shrink_to_the_learned_path_mtu` now also asserts the TCP
  socket that sent the oversized segment gets `PacketTooBig { mtu: 900 }` and that reading it clears
  it. That variant had only ever been observed on UDP sockets.
- Raw-socket source validation. `a_raw_socket_is_not_told_about_a_packet_we_did_not_send` quotes a
  packet with a foreign source but the exact version and protocol the socket is bound to, so nothing
  except the ownership check can turn it away, and asserts no PMTU is learned either.

## Test Fairness FAIL, round 11: the strengthening from round 9 was the unfair part

1 of 66 flagged, and it was the liveness assertion I ADDED in round 9 to cure a "vacuous" quality
note on the same test. Round 9 said the oversized IPv6 case passed even if nothing was emitted, so I
made it queue a fitting datagram afterwards and require that to go out. This round points out that
this assumes the oversized datagram was dropped rather than held back until the path grows again.
Nothing states which, and the repository's own UDP dequeue keeps a datagram when dispatch errors
(src/storage/packet_buffer.rs), so head-of-line blocking is a real alternative.

Removed the liveness block. The test is back to asserting only sizes, which this round rates fair,
plus the earlier assertion that a fitting datagram IS emitted, which already rules out a send path
that does nothing at all. The remaining "shallow" note is accepted rather than chased: every
strengthening available pins drop-versus-retain, and that is the author's choice to leave open. Worth
recording as a lesson - a coverage note asking for a stronger assertion is not automatically safe to
satisfy, and this one cost a round.

## Coverage suggestions, round 11

- Exact PMTU aging boundary. Raised now in rounds 5, 6 and 11, and declined twice as unstated. Rather
  than decline a fourth time I closed it in the description, the same move that ended the
  PMTU-versus-socket-match loop in round 8: a report "holds for ten minutes, and once it is exactly
  that old the next size up that list is tried". `a_learned_path_mtu_is_probed_back_upward` now
  samples 600, 1200 and 1800 alongside 599 and 601, so both sides of every boundary are pinned.
  479 words to 484.
- Raw plus transport fan-out. `one_report_reaches_both_a_raw_socket_and_the_sender` puts a matching
  raw socket and the matching UDP sender behind one report and asserts both keep it, which is what
  "a raw socket ... is told as well" says.
- IPv6 PMTU lifecycle. `an_ipv6_path_mtu_is_probed_back_upward_and_can_be_flushed` walks an IPv6
  destination from 1300 up through 1492 to the interface MTU, then re-learns and flushes. The IPv6
  tests had only covered the floor and sizing, so a family-specific timer or cache mistake could
  have hidden there.

65 tests became 67.

## Coverage suggestions, round 12

Four items, all added, each checked against the description before writing it. 67 tests became 71.

- IPv6 TCP PMTU transmission: `ipv6_segments_shrink_to_the_learned_path_mtu`. This one earned its
  place. Mutation-proven, and the mutation is instructive: replacing `cx.ip_mtu_to(...)` with
  `cx.ip_mtu()` at the dispatch-time segment-sizing site fails ONLY the new IPv6 test - the IPv4
  twin still passes, because it is caught by the other MSS site in `seq_to_transmit`. The suggestion
  found a genuinely uncovered code path rather than a duplicate.
- MSS on an IPv6 SYN: `the_advertised_mss_on_an_ipv6_syn_still_comes_from_the_interface_mtu` pins
  1440, which is 1500 less the IPv6 and TCP headers. Mutation-proven: routing the advertised MSS
  through the path MTU fails this and the IPv4 equivalent, and nothing else.
- Truncated transport quote: worth care, because this is the shape that was flagged unfair in round
  9. That one asserted no PMTU was learned from a complete IPv4 header plus four bytes, which is not
  singled out, since the addresses alone identify the destination.
  `a_tcp_socket_is_not_told_about_a_quote_with_no_sequence_number_in_it` asserts only the TCP side:
  with the sequence number cut off there is no way to establish that the quote names something the
  socket still has outstanding, and the description requires exactly that before acting, so leaving
  the socket alone is the only defensible answer. It deliberately says nothing about PMTU or about
  UDP, both of which remain identifiable from four bytes.
- Raw wildcard combinations: `each_raw_binding_dimension_is_matched_on_its_own` drives fixed-version
  with wild protocol and wild version with fixed protocol, in both the matching and the mismatching
  direction, so neither dimension can be ignored without failing.

## Coverage suggestions, round 13

Two items. The second had to be split, because half of it was not safe to assert. 71 tests became 74.

- Malformed ICMPv6 checksum: `an_icmpv6_error_whose_checksum_is_wrong_is_ignored`, the counterpart to
  the IPv4 corruption test. The ICMPv6 parser verifies the checksum before anything else, so
  rejecting the message is the only defensible outcome, and the uncorrupted form of the same frame is
  already known to be acted on by `an_ipv6_socket_is_told_its_packet_was_too_big`, which is what
  keeps this from asserting nothing.
- Unknown types and unknown codes are two different questions, and only one of them can be asserted
  the way the suggestion words it.
  - Unknown TYPE, `a_message_of_an_unknown_type_is_ignored`: an ICMPv4 type 200 and an ICMPv6 type
    200 are not error messages this stack can parse at all, so no socket error and no path MTU is
    the only answer. Fair, asserted in full.
  - Unknown CODE inside a known type: the suggestion asks that it be "ignored without changing
    socket error state". That is NOT safe. A destination unreachable with an unrecognised code is
    still a destination unreachable, and the description asks for errors to be reported; mapping it
    onto some named variant is at least as defensible as dropping it, and this implementation does
    map it. Asserting "ignored" would have pinned my own choice, which is how three earlier rounds
    lost tests. `an_unreachable_reason_that_carries_no_mtu_leaves_the_path_mtu_alone` therefore
    asserts only the half that IS stated: only fragmentation-required and packet-too-big record a
    path MTU, so an unknown unreachable code must not move it. Both readings of the socket question
    pass. The MTU field is deliberately filled in with a plausible value so an implementation that
    reads it regardless of the code fails; mutation-proven by making the catch-all arm produce
    `PacketTooBig` from that field.

## Coverage suggestions, round 14

Two of three taken. 74 tests became 77.

- Additional truncation boundaries: `a_udp_socket_is_not_told_about_a_quote_with_no_ports_in_it`
  (a whole IPv4 header but only two bytes of the datagram, so the ports cannot be read) and
  `an_ipv6_tcp_socket_is_not_told_about_a_quote_with_no_sequence_number_in_it` (the IPv6 counterpart
  of the round-12 test). Both assert only the socket side. Nothing is claimed about the path MTU in
  either, because the addresses survive both truncations and learning from them is defensible - the
  mistake round 9 caught.
- PMTU error value under clamping: the suggestion asks to "clarify and test", and clarify is the
  operative word, since the description did not say whether the socket hears the reported size or
  the recorded one. Added: "A socket is handed the MTU the message reported, even where the recorded
  one is clamped." Paid for by shortening the legacy-router aside, so the description is 494 words.
  `a_socket_hears_the_reported_size_even_where_the_recorded_one_is_clamped` then drives 68, which
  the floor lifts to 576, and 9000, which the cap lowers to 1500, asserting both numbers at once.
  Mutation-proven: handing the socket the recorded value instead fails this and only this.

Not taken: UDP remote tuple matching. It asks to clarify how "addresses and ports match a socket"
applies to the quoted DESTINATION of an unconnected UDP socket. That socket has no remote endpoint,
so there is nothing for the destination to be compared against, and both answers are defensible:
notify, since only the local side identifies the socket, or refuse, on the grounds that the
destination is part of "addresses". Asserting either pins a reading the description does not choose,
which is exactly the failure mode of rounds 4, 6, 8 and 11. The local half of the rule is already
covered from both directions by `a_udp_socket_ignores_an_error_quoting_another_port` and
`a_udp_socket_bound_to_one_address_ignores_an_error_for_another`. If this is wanted, the description
has six words of headroom left and would need to say which.

## Test Fairness FAIL, round 15: the round-14 clarification did not hold

1 of 78 flagged, and it is the test round 14 asked for. That round's note said to "clarify and test"
whether `PacketTooBig { mtu }` carries the reported size or the recorded one. I clarified, in the
description: "A socket is handed the MTU the message reported, even where the recorded one is
clamped." This round flags the same assertion anyway, on the grounds that the prompt never states it.

Rather than argue the sentence, both halves are gone. The description no longer says anything about
it, so nothing is stated-but-untested, and the test no longer pins it: renamed to
`a_report_outside_the_bounds_is_still_reported_and_recorded_at_the_bound`, it now asserts that the
socket receives SOME `PacketTooBig` and that the recorded path MTU lands on the bound, 576 for a
report of 68 and 1500 for a report of 9000. Both readings of the field pass. Description back to 478
words.

Worth stating plainly: coverage notes and the fairness gate can disagree, and when they do the gate
wins. This is the second time a note asked for an assertion the next pass rejected - the same thing
happened with the IPv6 oversize liveness check in rounds 9 and 11. The lesson is not to distrust the
notes, it is that "clarify and test" is only safe when the clarification is unmistakable, and a
single sentence in a 500 word description is evidently not always enough.

## Coverage suggestions, round 15

- Other PMTU-sized transmit paths: `a_raw_socket_send_is_also_sized_by_the_learned_path_mtu` sends a
  complete 1200 byte IPv4 packet through a raw socket to a destination whose path MTU is 900 and
  requires it to be fragmented to that. The description says everything the stack sends is sized this
  way, so this is the same rule on a path the suite had not exercised. Mutation-proven: pinning the
  egress size back to the interface MTU fails it.
- UDP remote-address matching: taken this time, having been declined in round 14. Two asks changed
  the balance, and the reasoning holds up - an unconnected UDP socket has no remote endpoint, so a
  quoted destination has nothing to be compared against, and the alternative reading needs
  per-datagram history the description never mentions.
  `a_udp_socket_is_told_whatever_the_quoted_destination_was` asserts the natural reading and says so
  in a comment.

77 tests became 79.

## Coverage suggestions, round 16

Two of three taken. 79 tests became 81.

- IPv4 options in quoted packets: `a_quote_whose_ip_header_carries_options_is_still_read_correctly`
  builds a quoted datagram whose IPv4 header is 24 bytes, with four no-operation options, so the
  ports sit at offset 24. Nothing ambiguous here: the header length is a field on the wire and
  reading past it is simply wrong. The options bytes are deliberately 1,1,1,1, so an implementation
  reading the ports at a fixed offset of twenty finds 257 and does not match the socket.
  Mutation-proven by replacing `ip_packet.header_len()` with the fixed twenty in
  `parse_quoted_packet`.
- Zero-valued IPv6 packet too big: `an_ipv6_router_that_reports_no_mtu_walks_down_to_the_ipv6_floor`.
  The description states the zero rule without limiting it to one family, and the plateau list and
  the 1280 floor are both given, so 1492 then 1280 then 1280 follows from what is written.

Not taken: IPv6 extension headers in quotes. The wording is "clarify and test whether ... supported",
and clarify-and-test is exactly what produced the round 15 failure. The description says a quote
carries the IP header plus eight bytes; when an extension header sits in between, those eight bytes
are the extension header and the ports are not in the quote at all. Whether to walk the chain is
genuinely open, and both answers are defensible, so any assertion here pins a choice. Adding a
sentence would not settle it either: round 15 showed one sentence in a 478 word description is not
reliably read as stating the rule, and this needs more than one sentence to say properly. Left alone
deliberately.

## Trap notes for the batch

Ranked by what a natural implementation is most likely to get wrong:

1. The truncated quote. `TcpRepr::parse` and `UdpRepr::parse` both want a full header and a checksum
   over a payload that is not there. The symptom is that nothing happens at all.
2. `cx.ip_mtu()` is a shared chokepoint with three TCP call sites plus fragmentation. Routing all of
   them through the path MTU changes the MSS advertised in the SYN, which existing tests pin.
3. Sequence validation has to run before the state table, or a stale error tears down a fresh
   connection between the same endpoints.
4. Clamping has a ceiling, a floor, and a zero-means-plateau case that reads from what is currently
   in effect rather than from the interface MTU.
5. The learned size has to reach retransmission, not just new sends.
6. ICMP sockets must keep receiving these messages; consuming them at the new demux point breaks the
   existing icmp-socket tests.

## Open items

- No platform batch yet. This has not been measured against Nova/Orion, so the difficulty is a
  prediction, not a result.
- Capture every passing agent's patch at the first batch, for the differential harness.
- If the rate lands over 40 percent, the meta has ~10 words of headroom before the 500 cap, so
  hardening has to be test-only: more cases where a probe step, a fresh report and the floor
  interact on the same destination.
