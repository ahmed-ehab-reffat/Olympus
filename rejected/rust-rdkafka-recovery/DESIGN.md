# DESIGN - rust-rdkafka recovery task audit

Status: `rejected at task-approval gate; no task or tests approved`.

Repository: `fede1024/rust-rdkafka` at
`3f54ff1dabe7eece876b9635e22462b04478a445`.

## Public contract and repository evidence

There is no approved public contract yet. This folder is a gated search for one
repository-native recovery or asynchronous-cleanup behavior that:

- is owned by rust-rdkafka rather than delegated to librdkafka;
- can be driven deterministically with the in-process `MockCluster`;
- crosses enough Rust-side lifecycle, callback, future, queue, or context
  boundaries to meet the long-horizon scope standard;
- is absent from public issues, pull requests, Discussions, branches, releases,
  source history, and the local Olympus archive; and
- has a black-box oracle that permits multiple correct internal architectures.

The pinned crate is an MIT-licensed Rust 2021 wrapper with a committed
`Cargo.lock` and Rust 1.74 minimum. At the refreshed 2026-07-27 audit it had
1,988 stars, 820 issue/PR feed entries, 24 Discussions, 56 remote branch refs,
46 tag refs, and no GitHub releases. The default branch still resolved to the
pinned commit. The repository had later pushes on other refs, which were
confirmed to be non-default release/dependency work. The earlier provisional
67-tag count was incorrect; the exact REST and local ref count is 46.

`MockCluster` can inject request errors, topic errors, leader/follower changes,
broker down/up state, round-trip latency, coordinator changes, and API-version
constraints. This proves a deterministic fault harness, not task ownership:
ordinary broker retry, reconnection, transaction recovery, and coordinator
behavior remain librdkafka responsibilities unless the Rust wrapper introduces
an independently observable defect.

The focused locked library lane passed 18/18 on the host on 2026-07-27,
including `mocking::tests::test_mockcluster`. The same lane had already passed
in `rust:1.85-bookworm` with container networking disabled during the
2026-07-26 candidate re-audit. External Kafka and Testcontainers suites remain
out of scope for problem design.

### Eliminated AdminClient shutdown seed

A disposable probe found a real Rust-owned lifecycle defect:

1. create a one-broker `MockCluster`;
2. take the broker down;
3. start an `AdminClient::create_topics` request with a 30-second timeout;
4. drop the `AdminClient`; and
5. wait two seconds for the returned future.

On the pinned base the future remained pending. The polling thread is stopped
before the native client is destroyed, so it cannot receive the terminal
`BrokerDestroy` event. A complete prototype changed `AdminClient.client` to an
`Option<Client<C>>`, destroyed the client before stopping the poll thread, and
made all seven native admin-call sites use `inner()`. The same probe then
resolved immediately with `KafkaError::AdminOp(BrokerDestroy)`.

That fix changed only one production file with 18 insertions and 17 deletions.
It is useful repository evidence but materially below the active scope target.
Do not pad it with more admin methods, error aliases, timeout variants, or
fixtures, and do not turn it into a task.

### Terminal candidate search

`UPSTREAM_AUDIT.md` records the complete 820-entry issue/PR enumeration, all 24
Discussions, every branch name, tags, release endpoint, relevant open PR
patches, source history, and local archive searches. `REPO_MAP.md` traces the
Rust/native ownership boundary, and `PROTOTYPE.md` records every seed and the
cheapest legitimate implementation.

| Seed family | Decisive evidence | Result |
|---|---|---|
| StreamConsumer reconnect or silence | Public issues #322, #597, #661, and #848 plus PR #810; connection recovery is native | Prior art and wrong ownership |
| Main/split queue wakeup | Public issue #665, merged PR #666, and open PR #840; the split fix is a small periodic fallback | Prior art and undersized |
| Consumer shutdown | Public issues #453, #509, and #611, fixes #508/#517, and Discussion #677 | Prior art and mostly native |
| Producer purge/flush/drop | Public issue #676 and fixes #520/#748/#777 | Prior art |
| FutureProducer retry, latency, or memory | Public issues #468/#695/#746, Discussion #764, PR #792, and the existing `send_result` retry seam | Prior art and localized |
| Callback/error recovery | Public issue #627 and PRs #636/#644/#669/#775 | Prior art |
| Transaction recovery | Mature public API/history; transaction coordinator and recovery are librdkafka state | Wrong ownership |
| MockCluster lifecycle | Existing owned/borrowed lifetime model; no missing multi-boundary behavior reproduced | No candidate |

No seed other than the AdminClient drop defect survived far enough to justify a
new disposable worktree. Prototyping the others would merely reproduce public
patches or native recovery.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the 2026-07-26 rejected-pool re-audit, recovery,
retry, shutdown, callback, future, poll-thread, and fault-injection terms across
local problems, and the Calyx, Str0m, Statig, and Railway compact records.

Raw evidence inspected:

- Str0m `agent-runs/Nova_Nova_10`: `trajectory.json`,
  `solution-patch.patch`, and `eval-result.json`;
- Statig `agent-runs4/Nova_Nova_4`: the same three artifacts; and
- Statig `agent-runs4/Nova_Nova_3`: the same three artifacts.

Calyx has no solver trajectories. Its archive manifest, prototype, and
trajectory-informed redesign record were read instead. No rust-rdkafka solver
trajectory or prior Olympus task exists.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | Str0m `agent-runs/Nova_Nova_10` | All 31 baseline and six challenge tests passed | The solver found the complete validation-before-mutation seam early, changed only `src/change/sdp.rs`, added ordinary regressions, and ran focused then full tests. Its minimal complete production change was 97 lines, illustrating how a broad-looking recovery matrix can collapse into one local preflight. |
| Near-pass | Statig `agent-runs4/Nova_Nova_3` | 24/26 challenge and 23/23 baseline tests passed | The solver coordinated blocking and awaitable engines and preserved the public API, but represented an accepting hierarchy position by enum discriminant. Repeated variants on unrelated branches exposed the identity shortcut. |
| Broad failure | Direct rust-rdkafka evidence | Unavailable | No rust-rdkafka solver trajectory exists, and no unrelated broad failure is substituted for one. Repository evidence and disposable prototypes control the initial task search. |

Calyx supplies a separate legitimate-shortcut warning: deterministic replay,
and later transcript-backed replay, satisfied its public checkpoint behavior.
A rust-rdkafka recovery task must likewise accept reconstruction, retry, or
librdkafka-managed recovery whenever those approaches satisfy the public
contract.

## Discriminator ledger

This is the terminal research ledger, not approval to author hidden tests.

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| All ten Str0m solvers converged on one-file preflight. | Turn a fault matrix into one local validation or retry loop. | A viable task must require distinct Rust-owned lifecycle boundaries, not more fixtures around one branch. | Cheapest-correct prototype and strict production diff measurement. | Scope and architecture | Rejects an undersized task before hidden tests instead of rejecting legitimate solutions. |
| Calyx replay and transcript replay satisfied the observable contract. | Reconstruct state from inputs, progress, or observed events rather than preserving private live state. | Any reconstruction that preserves public Kafka/Rust behavior is legitimate unless the repository exposes a contrary invariant. | Compare uninterrupted and recovered public results and callback effects; do not inspect representation or history size. | Recovery architecture | Allows direct state, replay, retry, and delegated native recovery when behavior matches. |
| Statig's near-pass used a type discriminant for a positional boundary. | Collapse distinct callback/request occurrences that share one enum or error kind. | If a selected task depends on request or callback provenance, the exact public operation must complete once with the correct result after faults. | Interleave independent operations with repeated error kinds and observe only their returned futures/callbacks. | Async identity and routing | Tests operation identity without prescribing maps, IDs, channels, or opaque layout. |
| The AdminClient drop defect was fixed by native-client/poll-thread destruction order. | Expand one lifecycle reorder into an artificial recovery framework. | Honest scope is measured on the cheapest complete implementation. | Reproduce the failure, implement the minimum fix, and count production changes. | Shutdown ordering | Prevents padding a real but small bug into a long-horizon task. |
| `MockCluster` exposes broad fault injection while librdkafka owns protocol recovery. | Reimplement native retry or classify native internal behavior as Rust logic. | The task must have a Rust-wrapper observable that the pinned native client does not already guarantee. | Compare direct native-wrapper behavior with the proposed Rust API or lifecycle behavior under the same injected fault. | Ownership boundary | Keeps the challenge repository-native and accepts correct delegation. |
| Open PR #840 repairs split-queue wakeup with one fallback loop. | Treat main and partition queues as separate task boundaries merely because they have separate fixtures. | A discriminator must represent a distinct public failure family and novel work. | Compare the cheapest production changes and upstream identity before writing tests. | Wakeup architecture | Rejects fixture multiplication and direct duplication of public work. |
| Reconnect, close, flush, queue memory, and callback propagation all have named public records. | Rename a known upstream issue and drive it through MockCluster. | A viable task must be absent from public issue/PR/Discussion history. | Complete feed enumeration followed by relevant body, patch, branch, and source-history inspection. | Novelty | MockCluster determinism cannot make a public behavior novel. |

## Clause-to-test coverage

No public requirements or tests are approved. The investigation failed the
novelty, ownership, cheapest-solution, and scope gates before clause-to-test
design. Do not create `meta.md`, `test.patch`, `solution.patch`, or a grader
from this task identity.

## Environment and harness preflight

- Clean audit checkout:
  `work/rust-rdkafka-audit/source`.
- Pinned `HEAD`:
  `3f54ff1dabe7eece876b9635e22462b04478a445`.
- Host command: `cargo test --locked --lib`.
- Host result on 2026-07-27: 18 passed, including the in-process MockCluster.
- Prior official-image result: the same 18/18 passed in
  `rust:1.85-bookworm` with container networking disabled.
- Host dynamic-link probe works. The host does not have `cmake`, so
  `--features cmake-build` is not a valid host preflight; use the already-proven
  Linux container lane for static build claims.
- The 21-file integration suite mostly requires Kafka/Testcontainers and cannot
  be used as the offline challenge harness.
- Generated `target/` output and the initialized librdkafka submodule are
  reproducible and are not design evidence.

## Design verdict

Rejected at the task-approval gate. No task, public prompt, hidden tests,
reference patch, grader, false-positive suite, or calibration is approved.

The in-process harness is strong, but the recovery/async-cleanup neighborhood
is saturated by public work or delegated to librdkafka. The first novel
Rust-owned defect is honestly too small, and the complete follow-up search
found no second candidate crossing several Rust-owned boundaries. This is the
useful no-go outcome required by `PLAN.md`.

Do not revive it by multiplying MockCluster fixtures, combining unrelated admin
operations, banning fresh-client retry/replay/native recovery, or inventing
timing and representation restrictions. rust-rdkafka may be reconsidered only
for a materially different subsystem and a fresh audit.
