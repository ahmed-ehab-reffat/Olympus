---
Repository: https://github.com/tokio-rs/turmoil
Language: Rust
Issue: none (original feature request)
Commit: 684acc1a8eea3a9cf2c6959dc47b69dba981cac1
Title: Give the simulated network a finite capacity
---
# Give the simulated network a finite capacity

Nothing in the simulator has a rate: a message reaches the far end the moment it is sent. Add rates, queues and reporting, so a message holds each hop as long as its bytes take.

A message is as big as what it carries plus a fixed overhead: a datagram's bytes, a segment's payload, nothing for segments that only open, close or reset, costing the overhead alone. Add `Builder::message_overhead` and `Sim::set_message_overhead` to set it, zero by default.

Each link direction carries bytes at its own rate, as does each side of a host's interface: the sending side shared by every link out, the receiving side by every link in. `Builder::bandwidth`, `Sim::set_bandwidth`, `Sim::set_link_bandwidth` and `Sim::set_link_bandwidth_oneway` set link rates; only `Sim::set_host_send_bandwidth` and `Sim::set_host_receive_bandwidth` set interface ones. Rates and byte counts are `u64`, rates per second; a setter naming hosts takes them by name or by a `Regex` selector, under the crate's `regex` feature, then the value, and naming a link that is not there is an error. Zero, the default everywhere, is unlimited: an unlimited hop takes no time, is never waited on and records nothing, so it never holds a later message back.

A message starts once its sender's sending side and its link direction are free, each holding it as its own rate needs. It reaches the far end when the slower of those two finishes, plus the link's latency, where the destination's receiving side takes it in at its rate. It arrives when taken in: every hop takes messages on, and each direction delivers, in send order. A message lands on the first tick at or after it arrives.

The directions are otherwise independent; `Sim::set_link_duplex` with `Duplex::Half` shares one wire, so only one carries at a time; `Duplex::Full` is the default.

Each direction queues what it took on and has not delivered. `Builder::queue_capacity`, `Sim::set_queue_capacity` and `Sim::set_link_queue_capacity` bound both directions, zero again unbounded. A datagram that does not fit is dropped; a connection's segment waits instead, going on once enough of what is ahead has arrived, or once all of it has if it is bigger than the queue.

Partitioning throws away what a direction carried and frees it, so the next message neither waits for it nor lands behind it; interfaces keep the time they committed. A message sent while its link is held goes on the wire, in order and with no further latency, on release.

`Sim::queued_bytes` gives what a direction has yet to deliver. `Sim::link_stats` returns a `LinkStats` of `sent`, `delivered`, `bytes_sent`, `bytes_delivered`, `dropped` and `busy`, a `Duration`. `Sim::host_stats` returns a `HostStats` of `sent`, `received`, `bytes_sent`, `bytes_received`, `dropped`, and `send_busy` and `receive_busy` as `Duration`s; a host's `dropped` counts what a full queue turned away from its sends. Each hop books the time a message will hold it, and its sender the bytes, as it is taken on, so what is discarded later still shows; `received` and `bytes_received` count what arrived. Settings apply to what is sent after them.
