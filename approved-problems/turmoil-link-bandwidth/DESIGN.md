# DESIGN.md — turmoil-link-bandwidth

## 1. Title

Give the simulated network a finite capacity

Host: [tokio-rs/turmoil](https://github.com/tokio-rs/turmoil), MIT, 1234 stars, base commit
`684acc1a8eea3a9cf2c6959dc47b69dba981cac1` (2026-07-21).

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (`SHAPES.md` Pattern 12). A new variant of an existing pipeline
  stage (message scheduling) whose difficulty is subtle scheduling correctness, not breadth.
- Pass rate: <= 40% cap, designed for the corpus mode of about 1/10.
- Best agent: mixed (Orion/Vega).
- Predicted dominant verdict: MISSED_REQUIREMENT (interface sharing, freeing a wire on a partition).

## 3. Public API surface

- `Builder::bandwidth(&mut self, value: u64) -> &mut Self`
- `Builder::queue_capacity(&mut self, value: u64) -> &mut Self`
- `Builder::message_overhead(&mut self, value: u64) -> &mut Self`
- `Sim::set_bandwidth(&self, value: u64)`
- `Sim::set_link_bandwidth(&self, a: impl ToIpAddrs, b: impl ToIpAddrs, value: u64)`
- `Sim::set_link_bandwidth_oneway(&self, from: impl ToIpAddrs, to: impl ToIpAddrs, value: u64)`
- `Sim::set_host_send_bandwidth(&self, addrs: impl ToIpAddrs, value: u64)`
- `Sim::set_host_receive_bandwidth(&self, addrs: impl ToIpAddrs, value: u64)`
- `Sim::set_queue_capacity(&self, value: u64)`
- `Sim::set_link_queue_capacity(&self, a: impl ToIpAddrs, b: impl ToIpAddrs, value: u64)`
- `Sim::set_message_overhead(&self, value: u64)`
- `Sim::set_link_duplex(&self, a: impl ToIpAddrs, b: impl ToIpAddrs, value: Duplex)`
- `Sim::queued_bytes(&self, from: impl ToIpAddr, to: impl ToIpAddr) -> u64`
- `Sim::link_stats(&self, from: impl ToIpAddr, to: impl ToIpAddr) -> LinkStats`
- `Sim::host_stats(&self, addr: impl ToIpAddr) -> HostStats`
- `enum Duplex { Full, Half }`, default `Full`
- `struct LinkStats { sent, delivered, bytes_sent, bytes_delivered, dropped: u64, busy: Duration }`
- `struct HostStats { sent, received, bytes_sent, bytes_received, dropped: u64, send_busy,
  receive_busy: Duration }`

Nothing existing changes signature, so the feature is reachable from the current surface and no test
has to guess a type.

## 4. Canonical form

- Rates are bytes per second, capacities and sizes are bytes; zero is unlimited everywhere.
- A message's size is its payload plus the overhead; SYN, FIN and RST carry no payload.
- `start = max(now, wire.free_at, sender_lane.free_at)`, each hop held for `size / its own rate`.
- `reaches = start + max(on_wire, on_sender) + latency`; the receiving lane then takes it in.
- `arrival = max(previous arrival on that direction, taken_in + on_receiver)`.
- An unlimited hop is never waited on and books no time.
- Half duplex: `start` also waits for the other direction of the same link.
- Queue overflow drops a datagram (counted) and makes a connection's segment wait for room.
- A partition frees the wire it discards from; interfaces keep committed time.
- A held message is not on the wire; on release it goes on, in order, with no further latency.

## 5. Blind-spot pre-empts

- Accumulation: "a message waits for what was taken on ahead of it".
- Adjacent vs all: "the two directions of a link are otherwise independent".
- Result ordering: "never before the message sent ahead of it on that direction".
- Falsy-on-invalid: "zero, the default everywhere, is unlimited".
- Pipeline placement: "the sending side shared by every link out of the host".
- Unstated inverse: what a partition does to a wire and to an interface.

Codebase-inferable requirements: 1 (that a partition already discards in-flight messages).

## 6. Description

`meta.md`, 498 words, ASCII, no headers.

## 7. File footprint (as shipped)

| Action | Path | Raw | Human-effective |
| --- | --- | --- | --- |
| MODIFY | crates/turmoil/src/top.rs | 599 | 354 |
| MODIFY | crates/turmoil/src/sim.rs | 114 | 54 |
| MODIFY | crates/turmoil/src/config.rs | 44 | 17 |
| MODIFY | crates/turmoil/src/builder.rs | 25 | 10 |
| MODIFY | crates/turmoil/src/envelope.rs | 21 | 9 |
| MODIFY | crates/turmoil/src/lib.rs | 1 | 1 |

TOTAL: 804 raw / **445 human-effective** across 6 files (floor 430).

## 8. Solution outline

- `Protocol::size` / `Protocol::is_connection_oriented` — what a message puts on the wire.
- `Capacity::transmit_time(bandwidth, size)` — how long a hop is held.
- `Lane::ready` / `Lane::hold` — one side of a host's interface, and its counters.
- `Wire::transmit` — the kernel: reserve, hold, order, count.
- `Link::schedule` — the duplex rule around the kernel.
- `Link::room_for` — when a full queue has room for a segment.
- `Link::discard_all` / `discard_one_way` — free a wire when its messages are thrown away.
- `Topology::queued_bytes` / `link_stats` / `host_stats` — the reporting surface.

## 9. Test file

`crates/turmoil/tests/capacity_e557d7.rs`, one new cargo test target, 146 tests: serialization,
per-direction independence, interface sharing on both sides, in-order arrival, queue overflow and
drops, segments waiting for room, overhead, duplex, faults (partition, oneway partition, hold and
release), introspection, defaults and zero, loopback, duplex and rate selectors, asymmetric half duplex, arithmetic at u64 extremes, sub-millisecond
busy accounting, and panic parity on unknown hosts and links.

## 11. Trap matrix (all mutation-proven)

| # | Trap | Why missed | Test that catches it |
| --- | --- | --- | --- |
| 1 | `start` must wait for the wire | naive adds carry time to latency | queued_datagrams_wait_their_turn |
| 2 | per direction, not per link | `Link` holds both directions | the_two_directions_of_a_link_are_carried_separately |
| 3 | the sending interface is shared | per-link state only | every_link_out_of_a_host_shares_its_interface |
| 4 | the receiving interface is shared | contention shows on an innocent link | two_senders_share_the_receiving_host |
| 5 | a partition frees the wire | discard leaves reservations | partitioning_a_link_frees_the_wire |
| 6 | segments wait, datagrams drop | a torn stream surfaces far away | a_segment_waits_for_room_in_the_queue |
| 7 | held messages are not charged twice | fixing release double-books | released_datagrams_go_on_the_wire_one_after_another |
| 8 | unlimited hops book nothing | a freed wire stays held up | partitioning_a_link_frees_the_wire |

## 12. Tier + category

Olympus, **feature_request**. Every capability the prompt names is net-new public surface (three
`Builder` methods, ten `Sim` methods, `Duplex`, `LinkStats`, `HostStats`); nothing existing changes
behaviour until one of them is called. The platform's category check rejected `enhancement` and
suggested `feature_request` for exactly this reason. Select `feature_request` at submit. A later
round rejected the category again because the prose had drifted into present-tense documentation;
the prompt now opens by stating the capability does not exist and asks for it.

## 13. Predicted pass rate

10-30%. One interdependent kernel feeding delivery, introspection, faults and both protocols; exact
arrival instants; five misdirecting traps; an obscure host with no prior submissions.

## 14. Quality gate

- [x] Repo understanding 5/5
- [x] Existing PR/issue check: zero hits for bandwidth, throughput, rate limit, congestion, duplex
- [x] Vanilla suite green offline on the base image before authoring (208 tests)
- [x] Corpus recipe: one kernel, exact-output correctness, 5 interdependent + misdirecting traps,
      an "obvious code is wrong" edge (unlimited hops), signatures pinned in meta
- [x] human-effective 445 >= 430 across 6 files
- [x] 146 tests, all F2P, base suite unchanged
- [x] Deterministic across 5 runs
- [x] 17 mutations, all killed; 3 equivalent mutants retired

- [x] False-positive review closed: the send-order-across-links discriminator was added and the
      three known-passing agent submissions still pass 146/146
