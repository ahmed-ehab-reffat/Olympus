# Upstream audit - rust-rdkafka recovery investigation

Status: complete on 2026-07-27; no novel recovery task survived.

Repository: [`fede1024/rust-rdkafka`](https://github.com/fede1024/rust-rdkafka)

Pinned revision: `3f54ff1dabe7eece876b9635e22462b04478a445`

## Method and exact snapshot

The audit enumerated the repository through GitHub's public REST API and
compared the resulting records with the pinned checkout and every fetched
remote ref. The issue endpoint was read in ascending order across all pages,
including each entry's title and body. Candidate-related issue, pull-request,
and Discussion pages and the relevant pull-request patches were then inspected
directly.

The 2026-07-27 snapshot contained:

| Surface | Count | Details |
|---|---:|---|
| Issue/PR feed entries | 820 | 359 issues and 461 pull requests; 157 open and 663 closed |
| Discussions | 24 | all titles and bodies enumerated; shutdown, liveness, transaction, commit, and future-producer records inspected |
| Branches | 56 | all names enumerated; recovery/async/lifecycle-related branches compared with `master` |
| Tag refs | 46 | `0.30.0` and `v0.6.0` through `v0.39.0` |
| GitHub releases | 0 | the releases endpoint returned an empty list |
| Default branch | `master` | still exactly the pinned revision |

Repository metadata reported 1,988 stars, MIT licensing, Discussions enabled,
and a repository-level `pushed_at` of 2026-07-15. That later push was not a
default-branch change: the current `master` API and local `origin/master` both
resolved to the pinned 2026-06-14 commit.

This corrects the provisional count in the initial `DESIGN.md`: the exact tag
ref count is 46, not 67.

## Recovery and lifecycle collisions

The following table records the public work that closes the obvious candidate
neighborhoods. It is representative of the exact records inspected after the
complete feed enumeration; it is not a keyword-only claim.

| Candidate neighborhood | Public records and states | Created | Audit conclusion |
|---|---|---|---|
| Consumer reconnect and silent stalls | closed [issue #322](https://github.com/fede1024/rust-rdkafka/issues/322); open [issues #597](https://github.com/fede1024/rust-rdkafka/issues/597), [#661](https://github.com/fede1024/rust-rdkafka/issues/661), and [#848](https://github.com/fede1024/rust-rdkafka/issues/848); open [PR #810](https://github.com/fede1024/rust-rdkafka/pull/810) | #322 2021-01-05; #597 2023-07-06; #661 2024-03-15; #810 2025-11-22; #848 2026-07-17 | Reconnect, retry, and post-disconnect silence are explicit public task identities. The connection state machine is principally owned by librdkafka. |
| Stream wakeup and split queues | open [issue #665](https://github.com/fede1024/rust-rdkafka/issues/665); merged [PR #666](https://github.com/fede1024/rust-rdkafka/pull/666); open [PR #840](https://github.com/fede1024/rust-rdkafka/pull/840); open [issues #535](https://github.com/fede1024/rust-rdkafka/issues/535) and [#651](https://github.com/fede1024/rust-rdkafka/issues/651); open [PR #558](https://github.com/fede1024/rust-rdkafka/pull/558) | #535 2023-01-12; #558 2023-03-14; #651 2024-01-23; #665/#666 2024-03-30; #840 2026-05-31 | Main-queue and split-queue wake loss, forwarding, deactivation, and drop behavior are all public. PR #840's production fix is only a small fallback wake loop. |
| Consumer shutdown and close | open [issues #453](https://github.com/fede1024/rust-rdkafka/issues/453), [#509](https://github.com/fede1024/rust-rdkafka/issues/509), and [#611](https://github.com/fede1024/rust-rdkafka/issues/611); merged [PRs #508](https://github.com/fede1024/rust-rdkafka/pull/508) and [#517](https://github.com/fede1024/rust-rdkafka/pull/517); closed [Discussion #677](https://github.com/fede1024/rust-rdkafka/discussions/677) | #453 2022-03-29; #508/#509 2022-10-31; #517 2022-11-23; #611 2023-09-25; #677 2024-04-30 | Consumer close latency, hangs while disconnected, and accelerated termination are saturated public seams. |
| Producer flush, purge, and drop | open [issue #676](https://github.com/fede1024/rust-rdkafka/issues/676); closed [issue #518](https://github.com/fede1024/rust-rdkafka/issues/518); merged [PRs #520](https://github.com/fede1024/rust-rdkafka/pull/520), [#748](https://github.com/fede1024/rust-rdkafka/pull/748), and [#777](https://github.com/fede1024/rust-rdkafka/pull/777) | #518 2022-11-27; #520 2022-12-04; #676 2024-04-30; #748 2024-12-05; #777 2025-06-21 | Purging queued/in-flight messages, completing callbacks on drop, and event-API flush behavior have direct issue and implementation history. |
| FutureProducer queueing and lifetime | open [issues #468](https://github.com/fede1024/rust-rdkafka/issues/468), [#695](https://github.com/fede1024/rust-rdkafka/issues/695), and [#746](https://github.com/fede1024/rust-rdkafka/issues/746); answered [Discussion #764](https://github.com/fede1024/rust-rdkafka/discussions/764); open [PR #792](https://github.com/fede1024/rust-rdkafka/pull/792) | #468 2022-05-05; #695 2024-07-05; #746 2024-11-20; #764 2025-03-31; #792 2025-09-26 | Queue-full retry ordering, latency, memory, and delivery-context customization are public. `send_result` is also a documented caller-owned retry seam. |
| Queue memory after cancellation | open [issue #604](https://github.com/fede1024/rust-rdkafka/issues/604) | 2023-08-24 | Consumer queue retention after a caller disconnects is already named publicly and is entangled with native queue behavior. |
| Callback routing and errors | open [issue #627](https://github.com/fede1024/rust-rdkafka/issues/627); merged [PRs #636](https://github.com/fede1024/rust-rdkafka/pull/636), [#644](https://github.com/fede1024/rust-rdkafka/pull/644), and [#669](https://github.com/fede1024/rust-rdkafka/pull/669); open [PR #775](https://github.com/fede1024/rust-rdkafka/pull/775) | #627 2023-11-10; #636 2023-11-28; #644 2024-01-08; #669 2024-04-10; #775 2025-06-06 | Consumer access during rebalance, return-to-caller semantics, and propagation to `ClientContext::error` are explicit public work. |
| Transactions and recovery | open [issue #98](https://github.com/fede1024/rust-rdkafka/issues/98); closed [issue #289](https://github.com/fede1024/rust-rdkafka/issues/289); merged [PRs #293](https://github.com/fede1024/rust-rdkafka/pull/293) and [#323](https://github.com/fede1024/rust-rdkafka/pull/323); open [Discussion #698](https://github.com/fede1024/rust-rdkafka/discussions/698) | #98 2018-09-19; #289 2020-08-13; #293 2020-08-20; #323 2021-01-05; #698 2024-07-11 | Transaction begin/commit/abort/retry behavior is an established public surface implemented by librdkafka's transaction state machine. |
| Admin operations | open [PR #785](https://github.com/fede1024/rust-rdkafka/pull/785) | 2025-08-11 | Additional admin operations are public and unrelated to recovery. The locally found pending-future-on-drop defect was not public, but its minimum complete fix was undersized. |
| MockCluster behavior | merged [PRs #467](https://github.com/fede1024/rust-rdkafka/pull/467) and [#583](https://github.com/fede1024/rust-rdkafka/pull/583); open [issue #629](https://github.com/fede1024/rust-rdkafka/issues/629); closed [issue #633](https://github.com/fede1024/rust-rdkafka/issues/633) | #467 2022-05-02; #583 2023-06-06; #629 2023-11-13; #633 2023-11-26 | MockCluster is a useful deterministic harness. Its presence does not transfer protocol recovery ownership from librdkafka to the Rust wrapper. |

The full enumeration also covered older destruction, callback, commit, queue,
poll, and transaction records, including issues #34, #48, #66, #94, #153,
#264, #266, #349, #398, #416, #433, #437, #490, #549, #620, #630, #638,
#701, #717, #738, and #762 and their linked changes. None exposed a separate
non-public multi-boundary recovery contract.

## Branch, tag, release, and source-history audit

All 56 branch names were enumerated. The potentially relevant non-default
branches were compared with `origin/master`:

| Branch | Last relevant state | Conclusion |
|---|---|---|
| `feature/threadless_futures` | 13 commits ahead, 659 behind; last commit 2018-07-06 | Historical alternate stream architecture, not current hidden work |
| `poll_timeout` | 6 ahead, 845 behind; last commit 2017-05-06 | Historical polling work already superseded |
| `polling_producer` | 0 ahead, 716 behind | Fully ancestral |
| `protect_refcounted_structures` | 1 ahead, 248 behind; last commit 2022-08-19 | Historical ownership experiment, not a current recovery task |
| `fix_producer_flush_and_tests` | 4 ahead, 19 behind; last relevant work 2025 | Public producer-flush lineage already represented by #748/#777 |
| `davidblewett/wrap-async` | 3 ahead, 240 behind; last commit 2022-04-11 | Stale alternate async API |
| `event_tests`, `offset_registry`, `non_copy_producer`, `to_opaque` | old and hundreds of commits behind | Historical design experiments with no current candidate identity |
| `release_0_39_0`, `release/v4.10.0` | version-only release commits | Explain later non-default pushes; do not change pinned `master` |

The 46 tags and empty GitHub release list expose no unreconciled release-only
implementation. `README.md`, `changelog.md`, examples, tests, and all-history
commit searches were inspected for recovery, retry, reconnect, shutdown,
drop, cancellation, purge, flush, wakeup, queue, callback, transaction,
coordinator, admin, and mock terms.

The source history already contains the relevant Rust-owned lifecycle changes:
consumer close/drop fixes, producer purge-on-drop, delivery-future completion
on producer drop, event-API polling, stream wake-race repairs, and repeated
flush corrections. Repeating one of those behaviors with MockCluster fixtures
would not create a novel task.

## Local and private-history audit

Local searches covered:

- `problems/README.md`;
- `candidates/CANDIDATES.md`;
- `candidates/SUCCESSES.md`;
- `candidates/REJECTED_REAUDIT_2026-07-26.md`;
- all compact problem records and archive manifests for recovery, retry,
  shutdown, callback, polling, checkpoint, replay, and resumability; and
- the Calyx, Str0m, Statig, and Railway records and representative raw
  trajectories named in `DESIGN.md`.

No earlier rust-rdkafka problem or solver trajectory exists. The private
submission archive was not available through the workspace or an attached
connector, so private cross-submission similarity remains unverified. That
limitation cannot rescue a seed that already fails public novelty, ownership,
or honest-scope gates.

## Verdict

The upstream audit is terminal for this recovery/async-cleanup investigation.
The conspicuous Rust-side lifecycle seams are public, and the non-public
AdminClient drop defect collapses to one small destruction-order change.
Protocol retry and recovery are otherwise owned by librdkafka.

No prompt, hidden test, reference solution, or grader should be authored from
this audit. The repository may be reconsidered only for a materially different
subsystem and task identity after a new complete audit.
