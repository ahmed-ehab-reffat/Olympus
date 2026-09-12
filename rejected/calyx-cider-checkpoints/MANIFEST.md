# Calyx Cider checkpoints archive manifest

Archived on 2026-07-25 after rejection at the scope/discriminator gate.

## Why the candidate failed

The proposed public behavior allowed a legitimate implementation to record the
original inputs and completed-cycle count, then reconstruct the checkpoint by
deterministic replay into a fresh interpreter. The disposable 190-line probe
matched subsequent cycle-level control and public memory/register state across
parallel control, invocation/reference bindings, memory, and a pipelined
primitive.

A follow-up consumptive-provider experiment did not rescue the discriminator:
previous nondeterministic observations can be retained as a transcript, replayed
without duplicate live reads, and followed by the unread provider suffix.
Black-box tests therefore cannot fairly require direct serialization of Cider's
coupled private runtime state. Timing, size, transcript bans, history limits, or
private-layout requirements would change the task rather than test its public
semantics.

## Preserved records

- `SUMMARY.md`: terminal decision and concise rationale.
- `PROTOTYPE.md`: replay architecture, cases, measurements, and decisive result.
- `ENVIRONMENT.md`: official-image offline build and test evidence.
- `UPSTREAM_AUDIT.md`: eligibility, novelty, history, and research audit.
- `REPO_MAP.md`: Cider runtime architecture and state boundaries.
- `PLAN.md`: original gated handoff with terminal rejection status.
- `DESIGN.md`: trajectory-informed follow-up experiment showing that a
  consumptive host provider still permits transcript replay.

No prompt, hidden tests, reference solution, verifier, calibration run, or raw
Calyx solver trajectory was created. `DESIGN.md` exists only for the follow-up
host-provider discriminator experiment; it closes that redesign without
approving a public contract or test suite.

## Retired reproducible checkout

The clean checkout at
`work/calyx-cider-checkpoints/upstream/` was pinned to
`264c618e3db8bab3d110a0c03ff44df3611e8990` and used approximately 579 MB.
The disposable prototype had already been deleted and `git status --short` was
empty before cleanup. The checkout contained no unique evidence and was not
archived; it can be reproduced from the pinned public repository revision.

## Reuse rule

Do not revive Cider checkpointing by banning replay or transcripts, requiring
private runtime representation, or adding arbitrary performance/history
limits. Calyx may be reconsidered only for a materially different task with a
repository-native public boundary and a black-box discriminator that legitimate
history reconstruction cannot satisfy.
