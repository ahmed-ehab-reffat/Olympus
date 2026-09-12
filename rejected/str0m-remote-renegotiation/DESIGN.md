# Design — failure-atomic remote SDP offers

Status: archived on 2026-07-27 after the immutable package calibrated at ten legitimate solves in ten runs. The package remains a locally verified historical record but is closed as too easy and too localized for the long-horizon standard.

Repository: [`algesten/str0m`](https://github.com/algesten/str0m) at `98d3b401e4fada626122b9846a5b4f9dd1d5d741`.

Language: Rust.

Task type: bug fix.

Retired checkout recovery:
`archive/str0m-remote-renegotiation/worktree-recovery.tar.gz`.

## Decision summary

`SdpApi::accept_offer` must be failure-atomic for invalid remote offers. If a parsed `SdpOffer` is rejected with `RtcError::RemoteSdp`, none of the remote-negotiated ICE, fingerprint, DTLS, SCTP, session, media, stream, or pending-event state may be left partially updated. The `Rtc` must remain usable, and a later valid offer must behave as if the rejected offer had never been applied.

There is one intentional exception. Calling `accept_offer` must continue to invalidate an outstanding `SdpPendingOffer`, even when the remote offer is rejected. The method documents that a new remote offer rolls back pending local changes, and the current implementation advances the change ID before validating the offer. A solution that snapshots and restores the entire `Rtc` must preserve this documented side effect.

The task is limited to `accept_offer`. It does not change `accept_answer`, SDP parsing, the public API, successful negotiation semantics, or the errors returned for independently invalid offers. The implementation may use complete prevalidation, staged state, or rollback, but tests must observe behavior only through public APIs.

## Gate ledger

| ID | Gate | Result and consequence |
|---|---|---|
| G1 | Pinned default head | GitHub `main` and the clean source checkout both resolve to `98d3b401e4fada626122b9846a5b4f9dd1d5d741`, committed 2026-07-22. |
| G2 | Repository eligibility | Active, unarchived, MIT OR Apache-2.0, Rust 2024, MSRV 1.85.0, committed `Cargo.lock`, 590 stars, and 115 forks at the refreshed audit. |
| G3 | Upstream novelty | All 182 issues, 826 pull requests, and nine Discussions were searched across open and closed states. No report or proposal requires failure-atomic rejected offers or rollback of partially applied remote SDP state. |
| G4 | History and branch novelty | Main-history commit searches found no rollback or atomic-SDP change. All 101 current branch names were inspected; the SDP retry, transaction API, safety, and offer-test branches were compared with `main` and do not implement this behavior. There are no GitHub releases. |
| G5 | Local similarity | Problem records, candidate history, archived manifests, and rollback-related designs were searched. No str0m submission or equivalent SDP task exists locally. Transactional-output and ACH-correction runs are used only as cross-domain rollback evidence below. |
| G6 | Reproduction | A rejected offer can change an earlier media direction before a later reordered m-line produces `RtcError::RemoteSdp`. The public `Rtc::media(mid).direction()` value proves the leak. |
| G7 | Feasibility | A disposable one-file probe fixes the reproduced leak, passes the 31 neighboring SDP tests plus the new regression, passes the full offline pure-Rust-crypto suite, and is clean under rustfmt and clippy. |
| G8 | Scope | The completed narrow implementation changes 202 production lines (155 insertions, 47 deletions) and adds a 471-line public integration-test file. It is larger than the 151-line probe because it preserves the original incremental `accept_answer` path instead of broadening failure atomicity to answers. This remains below the preferred long-horizon scope, but the implementation was not padded. |
| G9 | Container preflight | The official `rust:1.85.0-bookworm` image is present and Docker briefly reported server 29.2.1, but the network-disabled focused run remained stuck for more than nine minutes without starting a running container or producing build output. A subsequent container inspection also hung. This is still a host-wide Docker failure, not a repository-specific build result. A clean official-image offline run is mandatory before challenge tests are packaged. |

## Repository contract and evidence

| Area | Discoverable behavior |
|---|---|
| `src/change/sdp.rs` — `SdpApi::accept_offer` | Success means the offer has been applied and an answer can be returned. The docs explicitly list invalid incoming SDP as an error source and explicitly state that a new remote offer invalidates pending local changes. |
| `src/change/sdp.rs` — current call order | The method advances the change ID, mutates ICE credentials and candidates, stores the first fingerprint, initializes DTLS, processes remote SCTP initialization, and only then calls `apply_offer`. |
| `apply_offer` | `assert_consistency` can reject the SDP. Before later m-line validation finishes, `update_session` and `sync_medias` can mutate session-wide feedback settings, media direction, payload mappings, extension mappings, receive streams, and recycled-slot bookkeeping. |
| `sync_medias` | Existing media are updated in iteration order. A later media section can then fail because its MID moved to another index or attempted to recycle an active slot. This creates the concrete partial-application bug. |
| `add_ice_details` | A remote ICE restart can rotate local credentials and replace remote credentials before a later offer check fails. |
| fingerprint handling | A first offer with ICE details but no fingerprint currently disconnects the receiver after ICE state has already changed. Missing fingerprint is documented as invalid input, so it must return an error without poisoning the live receiver. |
| SCTP/SNAP handling | Established SNAP sessions reject changed or missing `a=sctp-init`. The current check occurs after ICE, fingerprint, and DTLS handling, so a late SCTP rejection can retain unrelated earlier mutations. |
| public state oracles | `Rtc::media`, `Media::direction`, `Media::remote_pts`, `Media::remote_extmap`, `Rtc::is_alive`, `DirectApi::local_ice_credentials`, generated SDP, `Rtc::poll_output`, and a later `accept_offer` provide black-box observations without exposing private fields. |
| existing regression suites | `tests/sdp-negotiation.rs` covers ordinary offers and answers, SNAP re-negotiation, malformed SNAP input, payload mapping, directions, and errors. `tests/sdp-m-recycle.rs` covers permitted offer recycling, forbidden answer recycling, active-slot refusal, media-type changes, and follow-up negotiation. |

## The current failure sequence

For an established session with media `A`, `B`, and `C`, a remote peer can send an offer that validly changes `A` and then swaps the positions of `B` and `C`.

```text
accept_offer
├── invalidate outstanding local PendingOffer       intentional, retained
├── apply remote ICE details                        mutation
├── initialize fingerprint / DTLS / SCTP            mutation
└── apply_offer
    ├── update session-wide settings                mutation
    ├── update A                                    mutation
    └── reject reordered B or C                     RtcError::RemoteSdp
```

The method returns an error, but `A` keeps its new direction and may have queued a `MediaChanged` event. If the offer also carried an ICE restart, ICE credentials may already have changed. Restoring only the visible media value is insufficient because a later valid negotiation can observe contaminated ICE, stream, extension, codec, event, or index state.

The required transaction boundary is therefore:

```text
invalidate pending local offer
validate every remote-offer condition that can yield RemoteSdp
commit remote-negotiated state only after validation succeeds
```

This is a semantic boundary, not an implementation requirement. A complete rollback implementation is valid if it preserves the same public behavior and does not restore the change ID.

## Normative behavior

### Rejected remote offer

When `accept_offer` returns `RtcError::RemoteSdp`:

- The receiver remains alive if it was alive before the call.
- Existing media keep their previous MID, index, kind, direction, stopped/disabled state, remote payload types, remote extension map, and stream associations.
- No new media or application line survives, and no stopped media or stream is retired.
- Local and remote ICE negotiation state, including credentials, candidates, role, and restart effects, remains as it was before the call.
- The established remote fingerprint, DTLS role/state, SCTP/SNAP negotiation state, and message-size negotiation remain unchanged.
- No `MediaAdded` or `MediaChanged` event caused solely by the rejected offer is observable later.
- A subsequent valid offer can be accepted and produces the same negotiated behavior it would have produced without the failed call.
- An outstanding `SdpPendingOffer` is still invalidated and later fails with `RtcError::ChangesOutOfOrder`.

The task does not require byte-for-byte identity of logs, internal allocation capacity, or random-number-generator position. Tests should assert protocol and public API behavior.

### Accepted remote offer

Successful offers retain current behavior:

- Remote ICE restarts are applied.
- First-offer fingerprint and DTLS setup are installed.
- Valid SNAP negotiation and re-negotiation continue to work.
- Existing media changes, valid stopped-slot recycling, new media/application lines, codec and extension negotiation, stream creation, events, and the returned answer remain correct.
- Existing error variants and meaningful single-defect messages remain compatible.

### Multiple invalidities

The task does not establish a new exact precedence among several independent defects in the same SDP. Tests may combine a late rejection with otherwise valid state changes to expose partial application, but they must not require a particular message from an offer containing unrelated competing errors.

## Recommended internal design

The lowest-risk repository-native design is validation followed by commit. `Rtc`, `Session`, DTLS, SCTP, ICE, and stream state are not designed as a single cheap cloneable transaction object, and a shallow rollback is likely to miss nested event and stream mutations.

### Offer-level validation

Add an immutable validation path that runs after change-ID invalidation and before any remote-owned state mutation. It should cover:

1. At least one m-line.
2. The existing ICE-Lite/ICE-Lite refusal.
3. `Sdp::assert_consistency`.
4. Presence of complete ICE credentials.
5. Presence of a fingerprint when the receiver does not already have one.
6. Established SCTP/SNAP re-offer consistency.
7. Complete m-line index, MID, active-slot recycling, and application-line constraints.

Do not parse the SDP again or invent stricter policy. Validation must use the same `Sdp`, `Session`, ICE, and SCTP semantics that the commit path uses.

### Media preflight

Split the fallible discovery and ordering checks from `sync_medias`:

- Walk every m-line immutably.
- Track the prospective application-line occupancy locally rather than calling `Session::set_app`.
- Match an existing media by MID and require its existing index.
- Permit an unknown MID at an occupied index only when the existing media is stopped and the incoming SDP is an offer.
- Record new lines for the later commit path.
- Do not change direction, codecs, extensions, streams, media vectors, event flags, or stopped-slot contents during preflight.

After preflight succeeds, the commit pass may update existing media, retire valid recycled slots, add new lines, and ensure transmit streams with the current semantics.

### SCTP preflight

Separate the immutable consistency check from the mutating `process_remote_sctp_init` behavior. An established SNAP association must still reject a changed or missing `a=sctp-init`; established non-SNAP SCTP must continue to ignore a newly introduced SNAP value as it does now. The commit path should cache or generate SNAP state only after the immutable check succeeds.

### Commit ordering

Once preflight succeeds, preserve the existing successful order unless a concrete invariant requires movement:

1. Apply ICE details and any valid remote restart.
2. Store the first remote fingerprint.
3. establish ICE controlling state and initialize DTLS.
4. Process accepted remote SCTP/SNAP data.
5. Apply all session and media changes.
6. Initialize SCTP if the application line is active.
7. Render and return the answer.

Do not add a public transaction type, make `Rtc` or `Session` publicly cloneable, expose validation helpers, or change `accept_offer`'s signature.

## Historical implementation-agent handoff

This handoff is retained only as design history. The package is closed, the
scratch checkouts were retired, and the steps below must not be resumed.

1. Reproduce the late m-line-order failure using public SDP generation and parsing.
2. Implement the smallest complete validation/commit separation that covers every `RtcError::RemoteSdp` path reachable from `accept_offer`.
3. Keep the change-ID invalidation before validation.
4. Add focused public integration tests under `tests/`; reuse `tests/common.rs`, `SdpOffer::from_sdp_string`, and existing negotiation helpers.
5. Do not broaden the task to `accept_answer`, refactor unrelated negotiation code, or add artificial code to satisfy a line target.
6. Run the focused, full, formatting, and clippy commands in the verification section.
7. Report production changed lines separately from tests. If the complete implementation remains near the 151-line probe, preserve the honest size and flag the packaging risk.
8. Do not commit active work. Olympus commits only at cleanup or archival checkpoints.

Stop and report rather than guessing if current upstream `main` moves away from the pinned commit, a public issue or PR begins implementing this behavior, a correct solution requires changing successful offer semantics, or the clean official-image preflight remains unavailable when packaging starts.

## Pre-calibration trajectory-informed design gate

No str0m solver trajectories existed when this original design gate was
completed. The closest stored evidence concerned multi-domain state that must
be staged before publication. These runs are analogical evidence only; the
str0m source and public API remain the authority for task fairness. The later
ten-run terminal evidence is recorded in `RUNS.md` and the archive manifest.

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`, rollback and atomicity terms across every problem folder, compact `RUNS.md` and `ERRORS.md` records, `archive/3d-tiles-atomic-output/agent-runs.tar.gz`, and `archive/moov-ach/actual_trajectories.tar.gz`.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | 3D Tiles Nova 3, `agent-runs/Nova_Nova_3` | 30/30 challenge and 869/869 baseline tests passed | Staged complete output away from the destination, finalized it, then published with backup/rollback handling. The solver identified finalizer and same-storage boundaries before committing. |
| Near-pass | 3D Tiles Nova 2, `agent-runs/Nova_Nova_2` | 26/30 challenge tests passed; baseline passed | The transaction architecture was correct, but overwrite-disabled publication leaked plain `Error` instead of the repository's `PipelineError`. Correct rollback alone did not preserve the public error surface. |
| Broad failure | moov ACH run 12, `actual_trajectories/run_nova_12` | 100/120 challenge tests passed; baseline passed | The solver tentatively mutated shared offsets and rolled back only the primary target. Later corrections saw contaminated state; provenance and validation were also captured at the wrong boundary. |

The resulting lesson is that a rejected operation must not mutate any coupled state before all failure conditions are known. It is not enough to restore the most visible field, and transactional changes must still preserve documented error and lifecycle behavior.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| The base updates an early media section before rejecting a later reordered section. | Validate and mutate in one ordered pass. | A rejected offer cannot change any existing media. | Capture directions for three media, reject a reordered offer that also changes the first direction, and compare all public media afterward. | Session/media ordering | Any staging, prevalidation, or complete rollback design passes. |
| The base applies ICE details before SDP consistency and m-line checks. | Make one subsystem atomic while leaving earlier subsystems eager. | A late offer error cannot perform an ICE restart. | Capture `DirectApi::local_ice_credentials`, send an otherwise valid restart offer with a later order defect, and require identical credentials after rejection. | ICE/session coupling | The test observes credentials, not private ICE calls or helper layout. |
| Missing first-offer fingerprint currently disconnects after ICE mutation. | Return the right error but poison the receiver. | Invalid user input returns `RemoteSdp` without killing a live receiver. | Strip fingerprint from a valid initial offer, assert the error and `is_alive`, then accept the untouched valid offer. | Lifecycle/recovery | A solution can prevalidate, rollback, or defer disconnect; no internal state representation is required. |
| Existing SNAP tests assert rejection but not rollback. | Add a new validation helper for only the reproduced m-line case. | A late SCTP/SNAP refusal cannot retain unrelated ICE or media state. | Establish SNAP, create a re-offer with an ICE restart and media change, corrupt `a=sctp-init`, and compare credentials/media before retrying valid SDP. | SCTP with earlier subsystems | Combines public, already-supported features and rejects one documented SNAP violation. |
| Moov run 12 restored the target but left coupled state contaminated. | Restore visible values while leaving queued side effects. | A rejected offer emits no media event. | Drain prior outputs, reject a direction-changing/reordered offer, then poll and assert no offer-caused `MediaChanged` or `MediaAdded`. | Event queue | Catches incomplete snapshots without requiring a particular event-storage mechanism. |
| A generic “restore everything” implementation is tempting. | Roll back the documented change-ID invalidation too. | Calling `accept_offer` still invalidates an outstanding local pending offer. | Hold a valid pending offer/answer, process an invalid remote offer, then require the old answer to fail with `ChangesOutOfOrder`. | Public lifecycle exception | Directly follows the existing `accept_offer` documentation and protects a non-obvious compatibility point. |
| Rollback changes can over-reject complex success paths. | Make validation stricter than the commit path. | Current valid recycling, SNAP, media, and ICE restart behavior remains supported. | Keep the full existing SDP suites and add one valid multi-change offer beside the negative cases. | Success compatibility | The oracle is existing public behavior, not the reference helper design. |
| 3D Tiles Nova 2 preserved output but changed the error type. | Fix state while changing public failure classification. | Single-defect invalid offers still return `RtcError::RemoteSdp` with meaningful reasons. | Match the public variant for missing fingerprint, reordered MID, and bad established SNAP data; avoid multi-defect precedence assertions. | Error surface | Preserves repository conventions without pinning helper names or all prose. |

## Clause-to-test plan

| Public requirement | Observable test | Pinned base | Completed solution | Fairness evidence |
|---|---|---|---|---|
| Earlier media changes do not survive a later m-line-order error | Three-media direction change plus reordered trailing sections | Fails | Passes | `Rtc::media` and `Media::direction` are public; current error already rejects changed order. |
| Remote extension mappings do not survive the same rejection | Remove extensions from the first media, reorder later sections, and compare `Media::remote_extmap` | Fails | Passes | The mapping is public state updated by the same media commit path, but it is independent of direction rollback. |
| Rejected ICE restart leaves credentials unchanged | ICE restart plus late reordered media, followed by the valid retry | Fails | Passes | `SdpApi::ice_restart` and `DirectApi::local_ice_credentials` expose both sides of the behavior. |
| Rejected offers do not install remote candidates | Add a unique candidate to a reordered re-offer, then call public `invalidate_candidate` | Fails | Passes | A leaked candidate is directly observable without accessing the private ICE agent. |
| Missing fingerprint does not disconnect | Strip only fingerprint, reject, check `is_alive`, then retry original | Fails | Passes | `accept_offer` docs name missing fingerprint as invalid SDP, and README classifies invalid input as an error. |
| Rejected initial offers do not pin a fingerprint | After the base-failing missing-fingerprint liveness/retry case, reject one peer for missing ICE, then accept and connect to a different valid peer | Parent test fails on liveness | Passes | A wrong retained fingerprint causes the later public DTLS handshake to fail; this guards independently plausible validation orderings without creating a wrapper-visible compatibility pass. |
| SNAP rejection is atomic across earlier state | Established SNAP, changed `a=sctp-init`, ICE restart, media change, and retry | Fails on the earlier ICE mutation | Passes | Existing tests and current error strings define SNAP re-offer consistency. |
| No event leakage | In the base-failing media rollback test, drain prior output and poll after the rejected direction/reorder offer | Parent test fails on leaked media state | Passes | `Event::MediaChanged` is a public consequence of media mutation; combining the assertion preserves incomplete-rollback coverage without a wrapper-visible compatibility pass. |
| Pending local offer remains invalidated | After the base-failing missing-fingerprint liveness/retry case, place an invalid remote offer between a local offer and its answer | Parent test fails on liveness | Passes | Explicit `accept_offer` documentation and `ChangesOutOfOrder`; aggregation preserves the compatibility check without a standalone base pass. |
| Successful complex offers still commit | Valid direction/ICE retries plus existing stopped-slot recycling and SNAP coverage | Passes | Passes | The retry assertions and existing 31 focused tests establish these conventions. |
| Rejections in scope return `RtcError::RemoteSdp` | Match the variant for independent missing-fingerprint, reordered-MID, missing-ICE, and SNAP defects | Passes | Passes | The participant prompt names `RtcError::RemoteSdp`, and existing tests expose the variant. |

All six wrapper-visible integration tests were run against both the untouched pinned base and the completed solution. Every test fails on the base for an intended atomicity defect and passes on the solution. Event leakage is asserted inside the base-failing media-state test; fingerprint retention and pending-offer invalidation are asserted inside the base-failing initial-offer liveness/retry test. This keeps the compatibility and alternative-implementation coverage while satisfying the wrapper rule that no new test may independently pass on the base.

## Exact-version false-positive audit

Status: repeated and complete on 2026-07-26 after renaming the integration target to `sdp-rejected-offer-state_83efa2`. The random suffix removes the predictable-path collision without changing the six behavioral tests or solution. The four wrapper gates, full suite, formatting, clippy, and all three rebuilt survivor replays passed under the renamed artifact. No str0m solver patches were available to replay; the trajectory search and representative analogical runs recorded above remain the available implementation evidence.

### Participant-facing requirement map

| Public requirement | Strongest behavioral coverage |
|---|---|
| A `RemoteSdp` rejection retains the prior remote-negotiated state | Direction, extension-map, ICE-restart, candidate, and established-SNAP probes |
| Pending media events do not reflect a rejected offer | Event-drain probe after a direction-changing reordered offer |
| A live receiver remains usable | Missing-fingerprint rejection followed by the unchanged valid offer |
| A later valid offer behaves as if the rejection never happened | ICE, SNAP, missing-fingerprint, and different-peer fingerprint retries |
| Glare still invalidates an outstanding pending offer | Pending answer must fail with `ChangesOutOfOrder` |
| Rejections in scope use `RtcError::RemoteSdp` | All probes match the named public variant; the 31 neighboring tests and full suite remain green |
| Parsing and `accept_answer` remain out of scope | Inputs are parsed successfully before `accept_offer`; existing answer and recycling suites remain green |

### Mutations and survivors

| ID | Plausible incorrect implementation | Complete pre-existing suite | Exact six-test matrix | Isolation result |
|---|---|---|---|---|
| FP-1 | Install `offer.ice_candidates()` before final offer validation while staging credentials correctly | Pass: 638 library tests, all integrations, 56 doctests; 2 ignored | 5/6 | Only `rejected_offer_does_not_retain_remote_candidates` fails |
| FP-2 | Pin the first offered fingerprint before validating the rest of an initial offer | Pass: 638 library tests, all integrations, 56 doctests; 2 ignored | 5/6 | Only `missing_initial_fingerprint_does_not_disconnect_receiver` fails, at the aggregated different-peer DTLS handshake |
| FP-3 | Roll back only media direction after an eager `update_media`, leaving negotiated extension state behind | Pass: 638 library tests, all integrations, 56 doctests; 2 ignored | 5/6 | Only `rejected_reordered_offer_does_not_apply_remote_extension_changes` fails |

All three survivors were rebuilt from the randomized-path package. Each compiles, scores 5/6 with only its intended challenge test failing, and passes the complete repository suite when the six challenge tests are excluded. The reference passes the exact six-test matrix, and the untouched pinned base fails all six. Aggregating the event, fingerprint, and glare compatibility assertions changes only wrapper test boundaries: each assertion still runs against the reference and against any partial implementation that reaches it.

### Rejected and already-covered trials

- Restoring the entire `Rtc`, including the change ID, is already rejected by the pending-offer glare test.
- Omitting SCTP/SNAP prevalidation is already rejected by the established-SNAP test, which combines a late SNAP error with earlier ICE and media changes.
- Over-restricting stopped-slot recycling is already covered by the six existing recycling tests; duplicating that success path in the new file would not add a new discriminator.
- Repeating the extension mutation for every payload, RID, SSRC, and stream attribute was rejected as an unbounded symmetry matrix around the same partial-`update_media` rollback family.
- Candidate transport/type permutations were rejected because the actionable defect is installation before validation, not candidate representation.
- No test was added for private DTLS/SCTP flags or internal application bookkeeping without a distinct public failure mode. The fingerprint handshake, established SNAP retry, and neighboring SDP suites provide public boundary coverage.

The resulting changes are limited to three behaviorally distinct probes supported by repository state flow and public oracles. No private helper layout or reference-solution architecture is required.

### Immutable artifact identifiers

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c59f5a12c9b3bc42deeb015263cea59fce06c53236ff8370a8feb36a1c27431c` |
| `test.patch` | `06351f1c862e1868ff3f89643e6ec1b59aebd212779e29aa8e7790eb474ffe21` |
| `solution.patch` | `f43666f50dfc101f3b3b33cebd04df2a6b9e5237844aa672c6cd5d4e8ec2d413` |
| `Dockerfile` | `69f599d152c11436e019a47bd50b08f36d7e09eee96fda5b6ca290db2c90973a` |
| `verify/gates.sh` | `916eb72520f183770db44f71f56953b7d51133be7fe98f093b0addb0e0722c50` |

This is a new immutable problem version at 0/10 calibration runs. Any further prompt, test, reference, or packaging change requires the audit and local checks to be repeated and calibration to restart at 0/10.

## Post-calibration trajectory review and redesign gate — 2026-07-27

The immutable package identified above was exercised by ten Nova runs stored
under `agent-runs/Nova_Nova_1` through `agent-runs/Nova_Nova_10`. All ten
evaluations are `PASS_LEGITIMATE`: every run passed the 31-test neighboring SDP
suite and all six challenge tests without verifier manipulation. There is
therefore no near-pass or broad-failure trajectory for this version. Those
evidence roles are unavailable rather than replaced with unrelated failures.

Every solver changed `src/change/sdp.rs`; one solver also edited two existing
integration-test files. The production approaches converged on the same
repository-native seam:

1. retain `next_change_id()` before validation so glare still invalidates a
   pending local offer;
2. preflight the offer's ICE, fingerprint, SDP consistency, SNAP/SCTP, and
   m-line layout requirements without mutating live state;
3. run the existing commit path only after preflight succeeds; and
4. stop disconnecting the receiver for a missing initial fingerprint.

The representative raw pass, `Nova_Nova_10`, identified the complete
validation-before-commit fix by trajectory step 19, then spent the remaining
work adding regression tests and running the focused and full suites. The other
nine patches use equivalent preflight helpers. Successful trajectories contain
44–76 agent steps, but the implementation remains centered in one production
file. This confirms the earlier scope warning: the task can sustain a long
investigation, but its decisive implementation architecture is localized and
predictable.

### Redesign discriminator ledger

| Observed trajectory behavior | Generalized shortcut or design lesson | Fair public invariant | Candidate black-box oracle | Boundary / failure family | Decision and anti-overfit rationale |
|---|---|---|---|---|---|
| Ten of ten solvers implemented complete offer preflight and passed legitimately. | The offer-side validation/commit seam is sufficient for the entire published contract. | Rejected offers are failure-atomic with the documented glare exception. | Existing six-test matrix and valid retries. | `accept_offer` transaction | Closed for hardening. Another offer fixture would not distinguish an incorrect architecture and must not reject these legitimate solutions. |
| All successful patches remained centered in `src/change/sdp.rs`. | Adding more state categories does not force a second implementation boundary once the offer is preflighted. | Existing public offer behavior remains correct across ICE, media, events, fingerprint, and SNAP. | Existing focused and full suites. | Scope / long-horizon depth | Closed for fixture expansion. Candidate, extension, stream, and bookkeeping permutations repeat already-covered failure families. |
| Solvers proactively checked missing fingerprint recovery, media events, and pending-offer invalidation. | Explicit edge cases were absorbed into the same preflight architecture rather than creating independent difficulty. | Liveness, event isolation, and glare compatibility remain observable. | Current liveness/retry, event-drain, and `ChangesOutOfOrder` assertions. | Lifecycle compatibility | Retain as compatibility coverage if the task is archived; do not use variants of these checks as a new level. |
| The neighboring `accept_answer` path still performs several live mutations before its final SDP/session checks. | A redesign is viable only if answer rejection has a distinct, reproducible public state leak that is not repaired automatically by offer preflight. | A rejected parsed answer should not partially commit the pending negotiation or poison later negotiation, if repository behavior supports that contract. | Capture public media/ICE/liveness state, submit a late-invalid answer, then retry through a fresh negotiation. | Answer-side pending transaction | Investigation candidate only. It requires a base reproduction, novelty review, feasible reference design, and false-positive audit before any prompt or hidden-test change. |
| `try_init_sctp` remains fallible after SDP state commit. | Expanding atomicity to every internal error could invent rollback semantics for transport or resource failures. | No broader invariant is assumed without an existing public error and deterministic recovery contract. | None established. | Post-commit transport initialization | Rejected unless a deterministic public reproduction and repository-supported recovery rule are found. Private fault injection or invented error precedence would be artificial. |

This review abandons the completed 10/10 batch for calibration purposes. At the
user's direction on 2026-07-27, the redesign investigation stopped and the
problem was archived. No current hidden test is approved for reuse merely to
lower the observed pass rate.

## Proposed maintainer-facing problem statement

Title: Fix partial state updates after rejected remote SDP offers

`SdpApi::accept_offer` can partially apply a remote offer before discovering that a later part of the SDP is invalid. For example, during re-negotiation it may update an early media direction and then reject a later m-line whose MID moved to a different index.

Fix this bug by making remote-offer rejection failure-atomic. When `accept_offer` returns `RtcError::RemoteSdp`, the `Rtc` must retain the remote-negotiated state it had before the call, and pending media events must not reflect the rejected offer. A receiver that was alive must remain usable, and accepting a later valid offer must behave as though the rejected offer had not been applied.

Preserve the existing documented behavior that calling `accept_offer` invalidates any outstanding `SdpPendingOffer`, even if the remote offer is rejected. This task covers rejection of parsed remote offers in `accept_offer`; it does not change SDP parsing or `accept_answer`.

## Verification plan

Focused base suite:

```bash
cargo test --locked --offline --test sdp-negotiation --test sdp-m-recycle
```

New behavioral suite:

```bash
cargo test --locked --offline --test sdp-rejected-offer-state_83efa2
```

Full repository-native suite using the portable backend:

```bash
cargo test --locked --offline --no-default-features --features rust-crypto
```

Quality gates:

```bash
cargo fmt --all -- --check
cargo clippy --locked --offline --no-default-features --features rust-crypto -- -D warnings
```

Packaging preflight:

- Build from `rust:1.85.0-bookworm`.
- Warm dependencies from the committed `Cargo.lock`.
- Run the focused and full commands again with container networking disabled.
- Verify the pristine base before injecting either test or solution changes.

Local results refreshed on 2026-07-25:

- Completed source: all 31 neighboring SDP tests and all six integration tests passed.
- Untouched pinned base with the same integration-test file: all six wrapper-visible new tests failed for the intended atomicity defects.
- Fresh pinned worktree with `test.patch` only: `test.sh base` passed 31 tests and `test.sh new` failed all six tests as intended; after `solution.patch`, both modes passed. The regenerated JUnit reports were well formed.
- Completed source: the full offline `rust-crypto` command passed, including 638 library tests, all integration tests, and 56 passing doctests with two ignored doctests.
- Completed source: rustfmt and clippy with warnings denied passed.
- Container result: not obtained. Docker server 29.2.1 and the cached official image were observable, but the network-disabled Rust 1.85 focused run hung for more than nine minutes before a running container or test output appeared. The client process was stopped; no repository result can be inferred.

## Design verdict

The bug, public oracle, repository fit, novelty audit, false-positive audit, and
local package gates are strong. The problem nevertheless fails as an Olympus
long-horizon task: all ten solvers passed legitimately, all used the same
one-file preflight architecture, and their production logic outside in-file
tests changed only 97–147 lines.

The terminal decision is archive, not harden. Raw trajectories are in
`archive/str0m-remote-renegotiation/agent-runs.tar.gz`; scratch checkout recovery
is in `archive/str0m-remote-renegotiation/worktree-recovery.tar.gz`. Preserve the
honest package and its calibration lesson, but do not resume or broaden it.
