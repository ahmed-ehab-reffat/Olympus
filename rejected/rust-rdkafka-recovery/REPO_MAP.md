# Repository map - rust-rdkafka recovery boundaries

Status: complete; no candidate crosses enough Rust-owned boundaries.

Repository revision: `3f54ff1dabe7eece876b9635e22462b04478a445`

## Ownership model

rust-rdkafka is an asynchronous Rust wrapper around librdkafka. The Rust crate
owns type-safe configuration, ownership of native pointers, callback
translation, futures/oneshots, wakers, polling threads, and public Rust API
composition. librdkafka owns broker connections, request retry, metadata,
consumer groups, producer idempotence, transaction recovery, protocol queues,
and most shutdown progress.

`MockCluster` can deterministically perturb the native protocol state machine,
but it does not turn that state machine into Rust-owned production logic.

## Boundary map

| Area | Public Rust seam and Rust-owned state | Native calls and guarantees | Deterministic fault/control | Public observation | Candidate result |
|---|---|---|---|---|---|
| `AdminClient` | `AdminClient<C>` owns `Client<C>`, a dedicated `NativeQueue`, `should_stop`, a poll `JoinHandle`, and a oneshot sender per operation stored as native opaque data. Seven operation families decode events into Rust futures. | `rd_kafka_*` admin calls own request dispatch, timeouts, retries, and terminal events. The poll thread only routes returned events. | Broker down/up, transport request errors, RTT, coordinator changes, and operation timeouts; MockCluster does not fully implement the CreateTopics admin API. | Each returned future resolves once with a typed result or error; client drop should not strand it. | The drop-order defect is Rust-owned but fixed by one localized destruction reorder. Concurrent routing already uses per-operation oneshots. Undersized. |
| `FutureProducer` | `FutureProducer` shares an `Arc<ThreadedProducer>`. Each send creates a oneshot. `send` owns a 100 ms queue-full retry loop; `send_result` exposes immediate queue refusal. Delivery callbacks detach the message into an owned result. | `rd_kafka_producev`, delivery events, broker retry, ordering, batching, delivery timeout, idempotence, and network recovery are native. | Queue limits, broker down/up, RTT, request errors, leader changes, and delivery timeout. | The send result, returned owned message on failure, delivery callback, in-flight count, and queue error. | The only material Rust logic is one retry loop and oneshot routing. Queue ordering, latency, memory, and customization are already public issues/PRs; native recovery or `send_result` retry is legitimate. |
| `BaseProducer` | Owns the `Client` and main queue; translates delivery and error events. Drop calls purge then flush. | `rd_kafka_purge`, `rd_kafka_flush`, `rd_kafka_outq_len`, and transaction APIs own queue state and protocol progress. | Broker loss, queue saturation, transport errors, and native timeouts. | Delivery callbacks, flush result, in-flight count, purge failures, transaction result. | Flush/purge/drop behavior has repeated public fixes. A new wrapper policy would duplicate public work or prescribe native behavior. |
| `ThreadedProducer` | Shares `Arc<BaseProducer>`, `AtomicBool`, and `Arc<JoinHandle>` across clones. The last clone stops and joins the polling thread. | The poll thread services native main-queue events; native client destruction performs final cleanup. | Broker loss and pending deliveries at last-clone drop. | Delivery futures/callbacks finish or are purged; last drop returns. | Existing purge/drop tests and public history cover the seam. Remaining reorder changes are local lifecycle fixes. |
| `StreamConsumer` main queue | Owns `Arc<BaseConsumer>`, a `WakerSlab`, a runtime wake task, and a oneshot shutdown trigger. `MessageStream` registers one waker slot and re-polls after installing it. | Consumer polling, group liveness, fetch, reconnect, and error generation are native. | Messages, stats/log/error events, broker down/up, request errors, assignment changes, and `max.poll.interval.ms`. | `recv`/`stream` items, callbacks, assignment, committed offsets, and drop completion. | Main-queue wake races are already public and fixed. Reconnect/stuck-after-commit behavior is public and mostly native-owned. |
| Split partition queues | `PartitionQueue` owns a native queue plus an `Arc<BaseConsumer>`; `StreamPartitionQueue` adds an independent waker slab and disables its callback on drop. | `rd_kafka_queue_get_partition`, forwarding/deactivation, fetch routing, and queue lifetime are native. | Partition leader/follower changes, message arrival, assignment changes, and induced missed-edge conditions. | Partition `recv`, main-stream delivery, re-splitting, and queue drop. | Drop/forward/deactivation are public issues. Missing periodic fallback is implemented by open PR #840 with a small loop. |
| Consumer callbacks | The `ClientContext` is held in `Arc`; native opaque data points to it. Rust translates rebalance, commit, stats, log, OAuth, and error events and controls pre/default/post rebalance timing. | Group membership, rebalance selection, coordinator retry, and commit outcome are native. | Coordinator changes, commit errors, assignment changes, broker loss, and interleaved callbacks. | Callback order/data, assignment, returned poll events, and commit results. | Access, return-to-caller, and error propagation are existing issues/PRs. Operation identity is already supplied by native events/TPLs; no hidden recovery layer exists. |
| Consumer close/drop | Rust disables the nonempty callback, requests `close_queue`, and polls until `closed`. | LeaveGroup, commit-on-close, close progress, and destruction are native. | Broker down, coordinator loss, auto-commit, stored offsets, and session timeout. | Drop latency, callbacks, and committed group state. | Multiple public hang/latency issues and merged fixes own this behavior. |
| Transactions | Rust performs thin FFI calls and calls `flush` before commit. | The transaction coordinator, fencing, retryability, abortability, idempotence, and recovery state machine are librdkafka responsibilities. | Transaction/group coordinator changes, request errors, broker down/up, fencing, and topic errors. | Typed transaction errors and committed/read-committed output. | Any fresh-client, abort, retry, or native recovery satisfying public semantics is legitimate. No substantial Rust-owned task remains. |
| `MockCluster` | `MockClusterClient` distinguishes an owned `Client` from a client-borrowed handle; drop destroys only owned clusters. Wrapper methods validate strings and translate native error codes. | The embedded mock brokers and every injected protocol response are librdkafka code. | Request-error stacks, topic errors, leaders/followers, watermarks, broker down/up/RTT/rack, coordinators, and API versions. | Wrapper return values and behavior of clients connected to the mock listeners. | Strong harness, thin production ownership. Extending fixtures around native retry is not a Rust-wrapper task. |

## Data and lifecycle flows

### Admin operation

1. Rust validates request values and creates native request objects.
2. `AdminOptions::to_native` creates a oneshot and stores its sender as opaque
   native data.
3. librdkafka performs the request and posts one result event to the dedicated
   queue.
4. the Rust polling thread extracts the opaque sender and sends the native event;
5. the typed Rust future validates the event kind and decodes public results.

Dropping only the future is safe: the eventual send fails harmlessly and frees
the sender. Dropping the client while an operation is pending exposed the
reproduced defect because the polling thread stopped before native destruction
could emit `BrokerDestroy`. Destroying the client first is the complete local
fix; it does not require a recovery subsystem.

### Future delivery

1. Rust creates a oneshot sender and passes it as the delivery opaque.
2. `send` retries only synchronous `QueueFull`; `send_result` returns it.
3. after acceptance, librdkafka owns the copied record and all delivery/retry
   state.
4. the producer polling thread translates a delivery event and consumes the
   sender.
5. last producer drop purges queued/in-flight messages, polls their delivery
   reports, stops the thread, and destroys the client.

A fresh producer, caller retry through `send_result`, or librdkafka's configured
retry is a valid architecture whenever the public result is preserved.

### Stream receive and wakeup

1. the message stream polls its native queue without blocking;
2. when empty, it installs a waker and polls again to close the install race;
3. an edge-triggered native nonempty callback wakes registered tasks;
4. the main consumer also has a periodic half-`max.poll.interval.ms` fallback;
5. split queues use separate callbacks and waker slabs.

The missing split-queue fallback is exactly open PR #840, not a novel task.
Protocol reconnect and post-error progress remain native behavior.

## Cheapest legitimate implementations

The map was explicitly checked against shortcuts allowed by
`PROBLEM_DESIGN.md`:

- native librdkafka recovery;
- ordinary caller retry or `send_result`;
- dropping and recreating a client;
- replaying produce/consume work from caller-owned offsets;
- retaining prior results or callback observations; and
- reordering Rust destruction without adding new public state.

None violates a repository-supported public invariant. Any proposed task that
forbids those approaches would be inventing architecture or performance policy.

## Map verdict

The wrapper has many observable asynchronous boundaries, but the missing
behaviors do not span them:

- the one non-public defect is a one-file admin destruction-order fix;
- the Rust wakeup defect is already public and small;
- producer and consumer shutdown neighborhoods are public; and
- the remaining recovery state machines are native.

There is therefore no exact candidate contract to promote to hidden-test
design.
