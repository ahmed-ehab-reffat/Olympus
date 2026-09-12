# DESIGN — React to ICMP errors and learn the path MTU (smoltcp)

## 1. Title

Deliver ICMP errors to the sockets that caused them, and learn the path MTU from them.

## 2. Repo + pick gates

- Repo: `smoltcp-rs/smoltcp` (Rust, 0BSD, 4547 stars, standalone TCP/IP stack for bare metal).
- BASE_COMMIT: `f96a26b5968735d142e6999a016060bc5d3ab2b7`.
- Gate 1 behavioral-F2P: incoming ICMP errors are dropped on the floor. `process_icmpv4` ends in
  `// FIXME: do something correct here?` with a catch-all `_ => None`. A connection to a black hole
  never learns anything; a "fragmentation needed" reply is discarded and the same oversized segment
  is retransmitted forever. Observably wrong, not a performance question.
- Gate 2 saturation: this is not a port of a reference implementation. The behaviour is scattered
  across RFC 792/1122/1191/1981/4443/5927, but the work is integration into this stack's ingress
  demux, socket state machines, and egress sizing, none of which any reference hands over.
- Gate 3 uniform-wrap: no. Ingress demux, the per-destination MTU cache, the TCP state machine
  reaction, and egress segment sizing are four separate mechanisms; getting the MTU cache right does
  nothing for the quote parsing, and vice versa.
- Gate 4 LOC: estimated ~650 raw / ~450 effective across 8 files (table below).
- Gate 5 cold: no in-flight work. `src/socket/icmp.rs` 2 commits in 12 months, `src/wire/icmpv4.rs`
  1, `src/iface/route.rs` 4. The only PR ever filed about path MTU (#277) just documented that it is
  missing.
- Gate 6 reproduce-on-base: confirmed against the base commit.
- Gate 7 dedup: nothing in `problems/`, `rejected/`, `Aprroved/` or the Olympus approved dirs touches
  ICMP error handling or path MTU discovery, in this repo or any other.
- Gate 7b exclusivity: `gh pr list --state all` for icmp / mtu / "too big" / unreachable returns no
  PR implementing either half. (The adjacent open PRs are #902 VLAN, #933 receive-window resizing,
  #1111 silly-window avoidance - all different features, all avoided.)
- Gate 8 defined behaviour: open issue #1071 "ICMP errors (such as destination unreachable) should
  reset TCP socket", plus the `FIXME` in the source. Not declined, not designed away.
- Gate 9 flakiness: `cargo test` is 672 tests in 0.32s, no network, no wall clock (time is a caller
  supplied `Instant`), no threads.
- Gate 10 quota: zero prior submissions on this repo.

## 3. Shape

O-Pipeline-hard. One capability threaded through ingress parsing, a new per-destination cache,
two socket state machines, and the egress sizing path.

## 4. What the feature is

An ICMP error quotes the packet that provoked it. Today smoltcp parses that message only far enough
to hand it to an ICMP socket, then drops it. After the change:

1. The quoted IP header and the first bytes of its payload are used to find the socket that sent the
   offending packet, and the error is delivered to it.
2. TCP reacts by state: a hard error on a connection that is still being opened aborts it; a hard
   error on an open connection is recorded but does not tear the connection down; soft errors never
   abort. An error whose quoted sequence number is outside the socket's send window is ignored.
3. "Fragmentation needed" and "packet too big" record a path MTU for the destination, in a small
   cache with expiry.
4. Everything the stack sends to that destination is sized by that path MTU rather than by the
   interface MTU, including the retransmission of the segment that provoked the error.

## 5. Canonical form / contract

- Quotes carry only 8 bytes past the IP header, so ports and the TCP sequence number are all that may
  be read from them.
- Hard: destination/host/protocol/port unreachable, source route failed. Soft: time exceeded,
  parameter problem, fragmentation needed, packet too big.
- Path MTU is clamped to at most the interface MTU and at least 576 (IPv4) / 1280 (IPv6). A quoted
  next-hop MTU of zero means the floor.
- An entry lowers a destination's MTU for 10 minutes and then the destination returns to the
  interface MTU.
- The MSS advertised in a SYN stays derived from the interface MTU; the path MTU limits only what
  this stack sends.

## 6. Trap matrix (arsenal-mapped)

| # | Class | Trap | Misdirects as |
|---|---|---|---|
| T1 | A5 de-crutched helper | The natural move is `TcpRepr::parse` / `UdpRepr::parse` on the quoted payload. Both need a full header and a checksum over a payload that was truncated to 8 bytes, so they fail and the error is silently discarded. | feature simply does nothing |
| T2 | S3 baseline-preservation | `cx.ip_mtu()` is the shared chokepoint for the advertised MSS, the effective segment size, and IPv4 fragmentation. Making it return the path MTU everywhere changes the MSS this stack advertises and breaks existing MSS tests. | unrelated MSS tests failing |
| T3 | S2 composition | Sequence validation and the state table interact: an out-of-window quote must be ignored *before* the state table is consulted, or a stale error from a previous connection on the same port aborts a fresh one. | a passing simple case, a failing reuse case |
| T4 | A8 polarity/boundary | Clamping has both a ceiling and a floor and a zero-means-floor case; the natural `min` of the two loses the floor. | wrong segment sizes, no error |
| T5 | S4 machinery-riding | The learned MTU has to reach the retransmission path, not just new sends, or the oversized segment that caused the error is retransmitted unchanged. | connection stalls |
| T6 | S3 baseline-preservation | ICMP sockets must keep receiving these messages exactly as before, and the stack must keep generating its own ICMP errors. Consuming the message at the new demux point breaks the existing icmp-socket tests. | existing icmp socket tests |

## 7. File footprint (estimate)

| File | raw | note |
|---|---|---|
| `src/iface/pmtu.rs` (new) | 110 | cache, clamping, expiry |
| `src/iface/mod.rs` | 10 | exports |
| `src/iface/interface/mod.rs` | 120 | context field, per-destination MTU, egress sizing |
| `src/iface/interface/ipv4.rs` | 80 | quote parsing, demux |
| `src/iface/interface/ipv6.rs` | 80 | quote parsing, demux |
| `src/socket/tcp.rs` | 150 | state table, window validation, MSS sizing |
| `src/socket/udp.rs` | 60 | error reporting |
| `src/socket/mod.rs`, `src/wire/mod.rs` | 50 | error type, quote helper |
| total | ~660 | |

## 8. Tests

New integration test file driving an `Interface` over a mock device with a caller-supplied clock.
Coverage: hard error in each TCP state, soft errors, out-of-window quote, wrong 4-tuple, truncated
quote, UDP reporting, MTU learn/clamp/floor/zero/expiry, segment resizing on retransmit, IPv4
fragmentation to the learned MTU, advertised MSS unchanged, and ICMP sockets still receiving.

## 9. Tier

Olympus.
