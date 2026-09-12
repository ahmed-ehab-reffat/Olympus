# Prototype record - rust-rdkafka recovery investigation

Status: complete; terminal no-go.

Pinned revision: `3f54ff1dabe7eece876b9635e22462b04478a445`

## Candidate matrix

| Seed | Base behavior / oracle | Cheapest complete architecture | Production scope or collision | Verdict |
|---|---|---|---|---|
| Pending AdminClient future during client drop | With a one-broker MockCluster down, a 30-second `create_topics` request remained pending for at least two seconds after dropping the `AdminClient`. A correct implementation resolves the public future with a terminal error. | Store `Client<C>` in an `Option`, destroy it before stopping the admin poll thread, and route the seven native admin calls through `inner()`. Native destruction emits `BrokerDestroy`, which the still-running thread delivers. | One production file; 18 insertions and 17 deletions. The focused locked suite remained 18/18. | Real and novel, but materially undersized. Closed. |
| Split partition stream loses a wakeup | A parked split queue can miss an edge-triggered wake and never be polled again. | Add the same periodic fallback used by the main stream, holding a weak waker reference until the split queue drops. | Open upstream PR #840; only one small `stream_consumer.rs` change plus a regression test. | Public prior art and undersized. |
| Producer queue remains full / flush leaves work | Queue-full and flush behavior can remain wrong after the event-API migration. | Continue polling native delivery events until `rd_kafka_flush` reports completion; purge on final drop. | Public issue #676 and merged PRs #748/#777; repeated source-history fixes. | Public prior art. |
| FutureProducer queue-full recovery | Concurrent `send` calls can reorder while separately retrying queue admission; reports also exist for latency and memory growth. | Use the existing `send_result` seam for caller-owned ordered retry, or adjust the local 100 ms loop. After enqueue, native delivery owns recovery. | Public issues #468/#695/#746 and PR #792. The Rust change is localized. | Public and too local. |
| Consumer reconnect / stuck after commit | Broker loss can lead to a silent consumer or require restart. | Let librdkafka reconnect, retry with a fresh client, or resume from committed/caller-owned offsets. | Public issues #322/#597/#661/#848 and PR #810; protocol state is native. | Public and not Rust-owned. |
| Consumer close while disconnected | Drop can wait on LeaveGroup/commit/session timeout or hang. | Native close plus Rust polling/destruction ordering. | Public issues #453/#509/#611, Discussion #677, and merged PRs #508/#517. | Public and mostly native-owned. |
| Callback/error recovery | Errors or rebalance events may not reach the caller at the desired Rust seam. | Translate native events to the existing context and poll result. | Public issue #627 and PRs #636/#644/#669/#775. | Public API evolution, not hidden recovery. |
| Transaction coordinator failure | Commit/abort/fencing/retry must retain exactly-once semantics. | Use librdkafka's transaction error classification and retry/abort protocol; recreation is legitimate where the native contract permits it. | Public transaction issue/PR/Discussion history; Rust methods are thin FFI wrappers. | Native ownership and prior art. |
| MockCluster lifetime/fault control | Owned and borrowed mock handles must not be double-destroyed or outlive their client. | The existing `MockClusterClient::{Owned,Borrowed}` enum and Rust lifetime already encode the distinction. | One wrapper/drop boundary with no reproduced missing behavior. | No candidate. |

## AdminClient disposable prototype

The AdminClient seed was the only non-public Rust-owned defect found.

Reproduction:

1. create a one-broker `MockCluster`;
2. configure an `AdminClient` with its bootstrap servers;
3. take the broker down;
4. submit `create_topics` with a 30-second operation timeout;
5. drop the `AdminClient`; and
6. wait up to two seconds for the returned future.

Pinned behavior: the future remained pending because `AdminClient::drop`
stopped and joined its poll thread while the native `Client` was still alive.
The native client was destroyed only afterward, when no Rust thread remained
to consume its terminal event.

Prototype behavior: destroying the native client before signalling the poll
thread caused the pending operation to resolve immediately with
`KafkaError::AdminOp(BrokerDestroy)`. All seven admin request sites continued
to use the same public API and result decoding.

Strict production diff:

- files: 1 (`src/admin.rs`);
- additions: 18;
- deletions: 17; and
- dependency changes: 0.

The prototype was disposable and was removed from the clean audit checkout.
Its result is preserved here and in `DESIGN.md`; it must not be broadened with
more admin methods, timeouts, or error aliases.

## Why no additional disposable worktree was created

Every other seed failed before Phase 4:

- the exact behavior was already public;
- the missing behavior belonged to librdkafka;
- the cheapest complete implementation was visibly a local retry/wakeup/order
  change; or
- a fresh client, replay from offsets, or caller retry already satisfied the
  prospective black-box contract.

Creating production prototypes after those stop conditions would not provide
honest scope evidence. It would only reimplement public patches or native
recovery.

## Verification

The final audit checkout is clean at the pinned revision.

Host command:

```text
cargo test --locked --lib
```

Result on 2026-07-27:

```text
18 passed; 0 failed; 0 ignored
```

The run includes `mocking::tests::test_mockcluster`,
`producer::future_producer::tests::test_future_producer_clone`, and the
future-producer send test. No external Kafka or Testcontainers service was
used.

## Prototype verdict

Reject the investigation. The only novel base failure has a 35-line
insert/delete implementation footprint in one production file. All neighboring
seeds are public or native-owned. No public prompt, hidden tests, reference
patch, or grader is warranted.
