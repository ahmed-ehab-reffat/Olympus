# PLAN - rust-rdkafka MockCluster recovery investigation

Status: closed and rejected at the task-approval gate on 2026-07-27. No problem
contract or hidden tests are approved.

Repository: `fede1024/rust-rdkafka`

Pinned commit: `3f54ff1dabe7eece876b9635e22462b04478a445`

Audit checkout: `work/rust-rdkafka-audit/source`

Terminal rating for this task neighborhood: 6/10

## Terminal result

The gated trial is complete:

- all mandatory startup and trajectory-informed design evidence was read;
- all 820 issue/PR entries, 24 Discussions, 56 branches, 46 tags, and the empty
  GitHub release list were enumerated;
- current `master` was confirmed to remain exactly pinned;
- Rust-owned admin, producer, consumer, callback, transaction, and MockCluster
  boundaries were mapped;
- the only non-public Rust-owned defect remained the one-file 18+/17-
  AdminClient destruction-order fix;
- every neighboring seed was public, native-owned, or a localized
  retry/wakeup/order change; and
- `cargo test --locked --lib` passed 18/18 on the final clean checkout.

The required records are `UPSTREAM_AUDIT.md`, `REPO_MAP.md`, `PROTOTYPE.md`,
`ENVIRONMENT.md`, `DESIGN.md`, and `SUMMARY.md`. Phase 6 is permanently
inapplicable to this task identity. A materially different rust-rdkafka task
would require a new plan and complete audit.

## Objective

Find and prove one non-public rust-rdkafka recovery or asynchronous-cleanup task
that is:

- implemented materially in the Rust wrapper rather than librdkafka;
- deterministic under the in-process `MockCluster`;
- substantial under the cheapest legitimate implementation;
- behaviorally distinct from existing Olympus problems and public upstream
  work; and
- testable through public outputs, futures, callbacks, or client state without
  prescribing private architecture.

The correct outcome may be rejection. Do not manufacture a task merely because
the repository and harness are eligible.

## Mandatory startup

Before changing source:

1. Read root `AGENTS.md`, `PROBLEM_DESIGN.md`, and
   `CALIBRATION_STRATEGY.md`.
2. Read this folder's `DESIGN.md` completely.
3. Read the rust-rdkafka entries in `candidates/CANDIDATES.md` and
   `candidates/REJECTED_REAUDIT_2026-07-26.md`.
4. Read:
   - `archive/calyx-cider-checkpoints/MANIFEST.md`;
   - `archive/calyx-cider-checkpoints/DESIGN.md`;
   - `archive/str0m-remote-renegotiation/MANIFEST.md`;
   - `problems/str0m-remote-renegotiation/RUNS.md`;
   - `problems/statig-local-transitions/RUNS.md`; and
   - the relevant recovery/snapshot rows in
     `problems/railway-deployment-bundle/DESIGN.md`.
5. Confirm the audit checkout is clean and exactly pinned:

   ```bash
   git -C work/rust-rdkafka-audit/source status --short
   git -C work/rust-rdkafka-audit/source rev-parse HEAD
   ```

Do not create or edit `meta.md`, `test.patch`, `solution.patch`, or grader
artifacts during task discovery.

## Known facts and exclusions

The locked host library lane passes 18/18, including `MockCluster`. A previous
network-disabled `rust:1.85-bookworm` run passed the same lane. External
Kafka/Testcontainers integration tests are unavailable to the challenge and
must not become a hidden dependency.

The following obvious seams are already public, recently implemented, or
unsafe as novel task identities:

- consumer stuck after commit: issue #848;
- split-partition fallback wakeup: open PR #840;
- resilient connection retry: open PR #810;
- `FutureProducer::send` memory growth: issue #746;
- producer flush behavior: issue #676 and completed PRs #748/#777;
- `StreamConsumer` wakeup: issue #665;
- broker reconnect behavior: issues #661 and #597;
- consumer-drop hangs: issues #611/#509 and completed PRs #508/#517;
- partition-queue drop behavior: issue #535;
- transaction examples and async methods: issues #98/#358; and
- additional admin operations: open PR #785.

Do not repackage any of these by renaming the API or adding MockCluster
fixtures. Search bodies, comments, linked librdkafka work, and current open
branches before deciding that a neighboring behavior is distinct.

The AdminClient-drop seed is also closed. The base future remained pending
after client drop, but destroying the native client before stopping the polling
thread fixed it in one production file with 18 insertions and 17 deletions.
Preserve this honest scope result; do not broaden it.

## Phase 1 - complete upstream and local novelty audit

Create `UPSTREAM_AUDIT.md` and record exact URLs, states, dates, and conclusions.

1. Re-enumerate every issue and pull request across open and closed states. The
   2026-07-27 REST feed contained 820 entries.
2. Inspect every Discussion because Discussions are enabled.
3. Inspect all remote branch names and compare any recovery, retry, async,
   transaction, consumer, producer, admin, mock, shutdown, queue, or lifecycle
   branches with the pinned default branch.
4. Inspect tags, release records, changelog, README, source history, tests, and
   examples.
5. Compare the pinned revision with current default `master` and every relevant
   open PR; a later push on a non-default ref is not evidence that `master`
   changed.
6. Search the Olympus candidate registry, problem index, success list, rejection
   re-audit, compact problem records, and archive manifests by both operation
   name and invariant.
7. Search the private submission archive if access is available. If it is not,
   record that limitation; do not treat silence as a pass.

Stop a seed immediately when public work already names the behavior or when its
identity is merely generic retry, reconnection, graceful shutdown, or
transaction cleanup.

## Phase 2 - map Rust-owned fault boundaries

Create `REPO_MAP.md`. For each candidate seam, trace:

- the public Rust API;
- Rust-owned state and ownership;
- native librdkafka calls and guarantees;
- opaque pointer, callback, channel, waker, queue, and polling-thread flow;
- drop and cancellation order;
- which `MockCluster` operation can inject the fault;
- how a caller observes success, refusal, recovery, or contamination; and
- whether a fresh client, ordinary retry, replay, or librdkafka delegation
  already satisfies the behavior.

Map at least the following Rust-owned areas before choosing:

- `AdminClient` native options, opaque senders, event queue, and poll thread;
- `FutureProducer` queue retry, delivery oneshots, clones, purge, flush, and
  threaded producer shutdown;
- `StreamConsumer` main and split queues, waker slab, runtime wake task,
  assignments, commits, and drop;
- consumer context rebalance/commit callbacks; and
- `MockCluster` ownership and fault-control lifetime.

Do not equate many configurable faults with many implementation boundaries.

## Phase 3 - shortlist exact public contracts

For each surviving seed, write a short candidate contract containing:

1. the user-visible operation;
2. the exact current failure on the pinned base;
3. why rust-rdkafka, not librdkafka, owns the missing behavior;
4. the deterministic MockCluster sequence;
5. public observations before, during, and after recovery;
6. at least three distinct implementation decisions or subsystem boundaries;
7. the easiest legitimate workaround, including fresh-client retry, replay,
   transcript, or native delegation;
8. public and local similarity results; and
9. expected production files and honest scope.

A requirement may not forbid retries, fresh clients, replay, retained
observations, or native recovery merely to force a preferred implementation.

## Phase 4 - cheapest-correct disposable prototypes

Use a separate clean worktree per seed. Do not mix alternatives in the audit
checkout.

For each seed:

1. reproduce the base failure through public APIs;
2. implement the smallest complete legitimate fix;
3. run the focused locked library lane;
4. run any additional deterministic MockCluster probe without external Kafka;
5. run formatting and relevant feature checks;
6. count strict effective production additions/deletions and files separately
   from tests; and
7. test whether a simpler retry, replay, fresh-client, native-configuration, or
   call-order solution also passes.

Record results in `PROTOTYPE.md`. Reject a seed when:

- the complete change remains one localized validation/reorder/retry fix;
- its scope resembles the rejected 18/17-line AdminClient or 97–151-line
  Str0m solutions;
- more fixtures repeat one failure family;
- most behavior belongs to librdkafka;
- correctness requires external Kafka or timing-sensitive sleeps;
- a public issue, PR, Discussion, branch, or archive already owns the task; or
- difficulty depends on private representation, transcript bans, history
  limits, or arbitrary performance policy.

## Phase 5 - task approval gate

Only one seed may be promoted. Update `DESIGN.md` with:

- a repository-backed public contract;
- representative raw trajectory evidence;
- a complete discriminator ledger;
- clause-to-test coverage;
- the cheapest-solution and replay findings;
- environment commands and counts; and
- an explicit `approved for tests` verdict.

Approval requires all of the following:

- no upstream, local, or accessible private-archive collision;
- deterministic offline reproduction and recovery;
- a Rust-owned observable not already guaranteed by librdkafka;
- several independent failure families or implementation boundaries;
- multiple legitimate internal architectures;
- substantial honest production scope without padding; and
- no dependence on sleep races, external services, or evaluator internals.

If any gate fails, write `SUMMARY.md`, mark the design rejected, archive the
research, update the candidate registry, and stop.

## Phase 6 - package only after approval

After—and only after—the design verdict says `approved for tests`:

1. follow `instructions/03-problem-description.md`;
2. follow `instructions/04-tests.md`;
3. create canonical `meta.md`, `test.patch`, `solution.patch`,
   `solution_approach.md`, and `Dockerfile`;
4. build the official Rust 1.85 image and warm locked dependencies;
5. run all four patch states with container networking disabled;
6. add focused feature/runtime composition checks where relevant;
7. run the mandatory exact-version false-positive audit from `AGENTS.md`;
8. replay every actionable mutation and representative legitimate approach;
9. freeze artifact hashes; and
10. read `CALIBRATION_STRATEGY.md` again before recommending or spending solver
    runs.

Any artifact change after freezing restarts verification and calibration at
0/10.

## Required handoff

The investigating agent must leave:

- updated `DESIGN.md`;
- `UPSTREAM_AUDIT.md`;
- `REPO_MAP.md`;
- `PROTOTYPE.md`;
- `ENVIRONMENT.md`;
- `SUMMARY.md`; and
- either an explicit rejection or one exact approved task.

Report:

- every seed considered and why it survived or failed;
- exact upstream and local searches;
- base reproduction;
- cheapest correct architecture and production size;
- offline commands and results;
- unresolved similarity or environment risks; and
- every changed file.

Do not commit active research. Commit only after the user requests a cleanup or
archive checkpoint.
