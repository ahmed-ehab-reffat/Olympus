# Summary - rust-rdkafka recovery investigation

Status: **rejected at the task-approval gate on 2026-07-27**.

Repository: `fede1024/rust-rdkafka`

Production language: Rust

Task type: bug fix

Pinned revision: `3f54ff1dabe7eece876b9635e22462b04478a445`

## Outcome

The repository is technically suitable for focused offline Rust work, but this
recovery/async-cleanup investigation does not yield an Olympus problem.

The complete public audit found:

- 820 issue/pull-request entries;
- 24 Discussions;
- 56 branches;
- 46 tag refs;
- no GitHub releases; and
- an unchanged pinned default branch.

Consumer reconnect, silent stalls, shutdown, wakeups, split queues, producer
flush/purge, future-producer queueing/memory, callback propagation, and
transaction recovery all have explicit public issues, pull requests,
Discussions, or mature source history. The protocol recovery state machines are
otherwise librdkafka responsibilities.

The one novel Rust-owned defect was real but too small: an AdminClient with a
pending admin operation stopped its polling thread before native destruction,
stranding the returned future. Destroying the native client first made the
future resolve with `BrokerDestroy`, but the complete prototype changed only
`src/admin.rs` with 18 insertions and 17 deletions.

## Candidate decisions

| Seed | Decision |
|---|---|
| AdminClient pending future on drop | Novel and reproducible, but rejected at one file and 18+/17- production lines |
| Split partition fallback wakeup | Open upstream PR #840 and a small local wake loop |
| StreamConsumer reconnect/stuck after commit | Public issues #597/#661/#848; native connection ownership |
| Consumer close while disconnected | Public issues #453/#509/#611, fixes #508/#517, Discussion #677 |
| Producer flush/purge/drop | Public issue #676 and fixes #520/#748/#777 |
| FutureProducer queue retry/memory | Public issues #468/#695/#746 and PR #792; `send_result` is a legitimate caller seam |
| Callback/error recovery | Public issue/PR lineage #627/#636/#644/#669/#775 |
| Transaction recovery | Public and native-owned |
| MockCluster lifecycle | Existing ownership model; no missing multi-boundary behavior reproduced |

## Verification

- audit checkout clean at the pinned commit;
- librdkafka submodule pinned at
  `e1db7eaa517f0a6438bc846a9c49ede73b9ea211`;
- `cargo test --locked --lib`: 18/18 passed on the host;
- prior network-disabled `rust:1.85-bookworm` lane: 18/18 passed; and
- no external Kafka/Testcontainers dependency introduced.

## Final verdict

No task is approved. No `meta.md`, `test.patch`, `solution.patch`,
`solution_approach.md`, Dockerfile, grader, false-positive suite, or calibration
batch was created.

The mandatory exact-version false-positive gate was not triggered: there is no
approved prompt, test suite, reference behavior, or immutable submission
version to audit. The investigation stopped before hidden-test authoring.

Do not revive this investigation by:

- adding more MockCluster fixtures around a native retry state machine;
- renaming an existing public reconnect/shutdown/wakeup issue;
- combining unrelated admin methods with the small drop-order fix;
- forbidding fresh-client retry, replay from offsets, or native recovery; or
- imposing timing, transcript, representation, or history restrictions.

rust-rdkafka may be reconsidered for a materially different subsystem after a
fresh complete audit. This recovery/async-cleanup task identity is closed.
