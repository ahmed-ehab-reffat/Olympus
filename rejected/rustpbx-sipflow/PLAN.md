# PLAN - deterministic cross-leg SipFlow diagnostics

Status: **rejected at the upstream prior-art/task-identity gate on
2026-07-25**. The exact candidate revision already contains a mature SipFlow
SIP/RTP capture, storage, query, diagnostic, and console subsystem. See
`UPSTREAM_AUDIT.md`. Do not create `meta.md`, `DESIGN.md`, `test.patch`, a
reference solution, or calibration artifacts, and do not rescope this seed to
rescue its former 8/10 rating.

## 1. Task identity

| Field | Current handoff |
|---|---|
| Repository | `restsend/rustpbx` |
| Language | Rust |
| Task type | enhancement |
| Candidate commit | `ac15e936ee0c8f7bd1eaedc83609d05096ccaf58` |
| Candidate facts | 731 stars; active 2026-07-24; MIT |
| Work namespace | `work/rustpbx-sipflow/` |
| Working title | Deterministic cross-leg SipFlow diagnostics |
| Candidate rating | rejected (formerly 8/10, conditional) |

The seed is a repository-native diagnostic that reconstructs one logical B2BUA
call as a deterministic timeline across multiple SIP legs, transfers,
re-INVITEs, and correlated RTP streams. It should help an operator understand
how signaling events and media-flow changes relate without manually joining
per-transaction or per-session logs.

This is a hypothesis to audit, not a final contract. The agent must discover
RustPBX's actual identifiers, event ownership, observability surfaces, and
existing diagnostic conventions before choosing an API or output schema.

Do not broaden the task into packet capture, a general tracing framework,
distributed telemetry storage, live dashboards, call recording, media routing,
DTMF implementation, SIP compliance expansion, or network-service integration.

## Rejection record

Inspection of the exact pinned revision found `src/sipflow/`,
`src/bin/sipflow.rs`, `src/bin/sipflow-diag.rs`,
`src/callrecord/sipflow.rs`, `src/console/handlers/sipflow.rs`,
`docs/config/08-sipflow.md`, a console screenshot and templates, and extensive
SipFlow tests. The existing subsystem records SIP and RTP by call and media
leg, retains timestamped flow data, calculates RTP/SSRC statistics, derives
media information from SDP, supports local and remote storage, exposes flow
and media query endpoints, and supplies an offline diagnostic CLI.

The history dates the first SipFlow feature to 2025-10-30 and the high
performance subsystem to 2026-01-20, well before candidate selection. A new
“deterministic cross-leg SipFlow diagnostic” would be an extension or
presentation of this existing structured event store, exactly the shortcut
which this plan requires rejection upon finding. The dependency and container
gates were not run after this decisive discovery because they cannot restore
task freshness. No problem-design or test artifacts were created.

## 2. Mandatory stop gates

Run these gates in order. Record exact revisions, commands, dates, logs, and
results. If a gate fails, update `candidates/CANDIDATES.md` and this plan with
the rejection; do not weaken the gate or silently change task identity.

### 2.1 Current eligibility and revision pin

Reverify from primary sources:

- public repository, default branch, and full candidate SHA;
- at least 500 stars and a default-branch commit in the last twelve months;
- allowed permissive license at the pinned revision;
- Rust as the primary language and expected production-change language;
- all workspace members relevant to SIP signaling, B2BUA sessions, and media;
- every native library, compiler, runtime, external executable, and service
  required by focused and baseline tests; and
- upstream CI status at the exact pinned revision.

The candidate screen found no committed `Cargo.lock`. Confirm that this is still
true and determine whether the repository is intentionally a library-style
workspace or simply omits reproducibility metadata.

### 2.2 Lock and dependency reproducibility

The missing committed lock is a material risk. Before problem design:

1. Resolve dependencies from a pristine pinned checkout.
2. Record the generated lock hash and the registry/Git sources selected.
3. Repeat resolution independently and require the same result.
4. Confirm no dependency is fetched from an unpinned branch or mutable path.
5. Warm declared dependencies without modifying source manifests.
6. Disable networking and rebuild from the warmed cache.
7. Decide whether the platform artifact may carry a generated lock without
   misrepresenting upstream reproducibility or violating repository policy.

If two clean resolutions differ, a Git dependency is not pinned, or the
submission cannot reproduce the exact graph offline, reject the candidate.
Do not conceal the missing-lock risk by generating a lock inside the Dockerfile.

### 2.3 Minimal official-image offline preflight

Use the smallest appropriate official Rust image and a pristine checkout.
Identify the focused lane before adding system packages.

The lane must:

- compile the crates owning SIP parsing/transactions, B2BUA call state, and the
  local media/session harness;
- run a representative set of existing unit and integration tests;
- cover more than pure parsing—at least one multi-leg or media-related flow;
- run with container networking disabled after dependency warming;
- avoid external SIP servers, live RTP endpoints, Docker-in-Docker, and timing
  dependencies;
- record native packages, build time, disk use, test counts, and ignored tests;
  and
- demonstrate that required fixtures are repository-owned and redistributable.

Reject if meaningful behavior requires a live network/service, unavailable
native dependency, non-hermetic certificate/clock setup, or an environment too
heavy for the platform.

### 2.4 Exhaustive upstream and local prior-art audit

Create `UPSTREAM_AUDIT.md`. Search all open, closed, and merged issues and pull
requests; Discussions; releases/changelogs; every fetched branch and tag; full
Git history; code/tests/examples; documentation; and referenced forks.

Search titles and bodies using combinations of:

- `SipFlow`, `call flow`, `call-flow`, `ladder`, `timeline`, `trace`;
- `B2BUA`, `dialog`, `leg`, `fork`, `bridge`, `correlate`;
- `Call-ID`, tags, branch, transaction, session, transfer;
- `REFER`, `Replaces`, attended transfer, blind transfer;
- `re-INVITE`, `UPDATE`, renegotiation, offer, answer;
- `RTP`, `RTCP`, `SSRC`, media stream, track, endpoint;
- diagnostic, inspect, explain, history, event log, audit;
- deterministic, ordering, timestamp, sequence;
- names of concrete RustPBX types and identifiers found in `REPO_MAP.md`; and
- public media-routing and DTMF issues #230 and #231.

Exclude task behavior already requested or implemented by public RTP/media
routing and DTMF work. Stop if the proposed flow is an obvious presentation
layer over an existing structured event log, an enumerated roadmap feature, or
an abandoned upstream implementation.

Search `problems/`, `archive/`, and `candidates/` for related call-flow,
renegotiation, transaction, media, correlation, and diagnostic tasks. Compare
carefully with `str0m-remote-renegotiation`: sharing SDP vocabulary is
acceptable only if RustPBX's central operation is cross-leg diagnostic
reconstruction rather than failure-atomic offer acceptance.

## 3. Mandatory shortcut and scope spike

Before assigning an implementation-difficulty score, build the cheapest
legitimate SipFlow.

Test whether the complete proposed output can be produced by:

- sorting or formatting an existing structured log;
- joining records by one existing call/session identifier;
- replaying an already retained event vector;
- wrapping a current debug serializer;
- projecting transaction state without touching B2BUA/media ownership; or
- parsing emitted text logs after the fact.

If any small implementation satisfies the black-box contract, accept it as
legitimate and score that task—not the desired cross-subsystem architecture.
Do not ban existing logs, require private types, impose arbitrary minimum
history, or test internal file touches to force scope.

Create `PROTOTYPE.md` and measure strict effective production lines. The
prototype must prove that honest behavior requires non-local reconciliation
across independently owned signaling and media state. Reject if the task is a
thin adapter, familiar sequence-diagram formatter, or under the current scope
target without padding.

## 4. Repository map to produce

Create `REPO_MAP.md` before fixing the public contract. At minimum, identify:

- workspace entry points and crate boundaries;
- SIP message parsing and serialization;
- transaction, dialog, and call/session ownership;
- inbound and outbound B2BUA leg creation;
- stable identifiers available for calls, dialogs, branches, transactions,
  endpoints, and media streams;
- transfer handling, including `REFER` and `Replaces`;
- re-INVITE/offer-answer state and how it affects media;
- RTP/RTCP session creation, SSRC/track association, and teardown;
- existing event buses, hooks, logs, tracing spans, metrics, and diagnostic
  structures;
- clock/timestamp sources and ordering guarantees;
- error, retry, retransmission, provisional-response, cancellation, and fork
  behavior;
- test builders, fake transports, local endpoints, and deterministic clocks;
- baseline test commands and feature combinations; and
- native/system dependencies used by the focused lane.

For every candidate event source, record:

- who owns and mutates it;
- when it becomes observable;
- its stable correlation keys;
- whether it is emitted before or after state commit;
- whether retransmission produces a new semantic event;
- whether it survives transfer/replacement;
- whether ordering is total, partial, or timestamp-derived; and
- whether adding observation would change runtime behavior.

## 5. Feasibility questions

Answer these from repository evidence:

1. What public or maintainer-natural API consumes or returns a SipFlow?
2. Is the flow built live, queried from retained state, or reconstructed from
   existing call/session records?
3. What defines one logical call across new dialogs created by transfer,
   replacement, or B2BUA leg creation?
4. Can unrelated calls reuse Call-IDs, tags, branches, SSRCs, or endpoint
   addresses in ways that defeat a single-key join?
5. How are retransmissions represented without duplicating semantic
   transitions or erasing useful wire-level evidence?
6. How are provisional/final responses, CANCEL/487 races, BYE, timeout, and
   failed transfer ordered?
7. How is an RTP stream linked to the signaling negotiation that created or
   changed it?
8. What does a re-INVITE do to an existing stream's identity and timeline?
9. Can deterministic ordering avoid wall-clock/timing assertions?
10. Can flow observation be added without retaining unbounded production
    history or changing call behavior?
11. Can malformed, incomplete, or partially torn-down calls yield useful
    diagnostics without panics or invented events?
12. Does a natural correct implementation meet scope and long-horizon criteria?

If the answer requires private architecture rather than public behavior, revise
or reject the seed before tests.

## 6. Candidate public behavior

Promote only requirements supported by the pinned repository. A coherent task
might expose:

- a deterministic ordered sequence of signaling and media milestones for one
  logical B2BUA call;
- explicit leg identities and relationships rather than a flat Call-ID list;
- transfer/replacement links that preserve the logical call across dialogs;
- re-INVITE milestones tied to resulting media changes;
- RTP stream correlation using repository-supported negotiation/session keys;
- stable output independent of hash-map iteration and wall-clock scheduling;
- graceful representation of missing, failed, cancelled, or torn-down legs;
  and
- no mutation of call/session/media behavior while diagnostics are collected.

Do not freeze field names, event taxonomies, timestamp units, or serialization
format until the repository map and prototype establish a maintainer-natural
surface. Prefer typed public behavior over assertions on log prose.

## 7. Trajectory-informed design gate

Before creating or revising `test.patch`:

1. Read `PROBLEM_DESIGN.md` completely.
2. Search the problem index, candidate registry, and archives by repository,
   SIP/SDP subsystem, multi-stage correlation, transaction state, and event
   ordering.
3. Inspect relevant compact records and a representative legitimate pass,
   near-pass, and broad failure when raw trajectories exist.
4. At minimum, evaluate whether Statig's handler-origin lesson, Moov's coupled
   state lesson, and str0m's rollback/event-boundary lesson genuinely transfer
   to RustPBX; record unrelated analogies as excluded.
5. Record chosen files, state/data flow, validation and commit timing,
   shortcuts, missed invariants, and proactive checks.
6. Create `DESIGN.md` from `templates/problem/DESIGN.md`.
7. Add the evidence table and discriminator ledger before hidden-test work.

If no RustPBX trajectories exist, record that search and use repository
evidence. Do not substitute analogical runs as if they proved RustPBX behavior.

## 8. Candidate discriminator families

Final discriminators must be black-box, publicly justified, and distributed
across distinct boundaries. Candidate families to validate include:

- same call across multiple B2BUA/dialog legs;
- transfer/replacement lineage;
- re-INVITE negotiation linked to media change;
- signaling/media correlation when superficial identifiers collide;
- retransmission versus semantic-event distinction;
- fork/cancel/failure ordering;
- stable ordering under equal or absent timestamps; and
- incomplete teardown or partial diagnostic state.

This list is not permission to add a fixture matrix. Each final discriminator
must trace to a public requirement, observable oracle, distinct failure family,
and trajectory or repository evidence. Symmetry variants and more SIP message
types are coverage breadth, not automatically new discriminators.

## 9. Mandatory false-positive audit

Before calibration, follow the false-positive gate in `AGENTS.md` and the
worked method in
`problems/statig-local-transitions/false_postive trials.md`.

For this task, construct plausible survivors such as:

- joining only on Call-ID;
- treating each dialog as a separate logical call;
- attaching every RTP stream to the most recent offer;
- sorting only by wall-clock timestamp;
- duplicating retransmissions as semantic milestones;
- losing the original leg after `Replaces`;
- showing signaling but silently omitting media teardown; and
- formatting existing logs without observing missing cross-leg state.

Only actionable, repository-supported survivors justify probes. Run meaningful
survivors through the complete existing suite, replay representative solver
patches when available, and record rejected artificial mutants as well as
actionable ones.

Any change to prompt, tests, reference behavior, or submission artifacts
creates a new immutable version. Repeat required checks and restart calibration
at 0/10.

## 10. Verification and calibration

Build a reproducible verifier that checks:

- exact pinned base and patch applicability;
- focused base failures and reference passes;
- complete baseline passes before and after the reference;
- offline builds/tests with the recorded dependency graph;
- relevant feature/native-dependency combinations;
- deterministic repeated output;
- formatting and linting;
- mutation/false-positive gates;
- artifact hashes and absence of leaked fixtures/solution details; and
- no live network, external SIP endpoint, or timing dependency.

Before recommending solver runs, read `CALIBRATION_STRATEGY.md`. Run one Nova
and one Orion local preflight against the exact immutable version and save
trajectories under `estimate_trajectories/`. If both solve cleanly, harden
before upload. Platform calibration starts at 0/10 and never mixes versions.

## 11. Handoff outcome

The next agent must leave one of two evidence-backed outcomes.

### Proceed

- current eligibility and exact revision recorded;
- repeatable lock/dependency graph established;
- focused official-image offline lane passes;
- exhaustive upstream, local, and archive audits pass;
- cheapest-shortcut prototype cannot collapse the task;
- honest scope clears the platform target;
- repository map supports a maintainer-natural public oracle;
- `DESIGN.md` records the trajectory-informed gate; and
- multiple legitimate internal implementations can satisfy the contract.

### Reject

- record the decisive failed gate in this plan and
  `candidates/CANDIDATES.md`;
- preserve environment logs, audit links, repository map, prototype
  measurements, and the shortcut that defeated the seed;
- do not create hidden tests or inflate/rescope the task to save its rating;
  and
- update `problems/README.md` if the folder becomes a durable rejection record.

Do not commit active work. Olympus commits only at verified cleanup or archival
checkpoints.
