# Calyx Cider checkpoints — rejection summary

Status: **rejected at the scope/discriminator gate on 2026-07-25**.

The candidate was evaluated at
`264c618e3db8bab3d110a0c03ff44df3611e8990`. It passed current repository
eligibility, a focused offline build and test lane in the official Rust 1.90
Bookworm image, an exhaustive upstream/research audit, repository mapping, and
the required review of relevant local problem history and representative raw
solver trajectories.

The disposable scope prototype exposed a fatal shortcut. Because Cider stepping
is deterministic for the proposed inputs, a checkpoint can contain the
original program identity, original data, and completed-cycle count. Restore
can replay those cycles in a fresh interpreter and publish the reconstructed
interpreter only on success. The 190-line probe matched cycle-by-cycle
debugger-visible control and public memory/register state on two representative
programs covering nested and unequal parallel progress, invocation/reference
bindings, memory, and a pipelined primitive.

Replay satisfies the observable contract, fresh-parse portability,
deterministic encoding, compatibility rejection, and failure atomicity. Hidden
tests cannot fairly require direct serialization of Cider's private coupled
runtime state. The honest task is consequently smaller and less
architecture-dependent than intended.

The seed was rejected without creating `meta.md`, `test.patch`,
`solution.patch`, a verifier, or calibration artifacts. The false-positive and
calibration gates were not entered because the candidate stopped before test
design.

A follow-up redesign experiment considered a consumptive nondeterministic host
primitive. Its checkpoint retained the values already observed, replayed that
transcript without touching the live provider, and then continued from the
provider's unread suffix. Seven inputs caused exactly seven live reads, final
state matched uninterrupted execution, and mismatch failure was read-atomic.
Thus nondeterminism merely replaces the cycle counter with an event log; it
does not eliminate replay. `DESIGN.md` records the trajectory-informed gate and
the closed redesign.

See `PROTOTYPE.md`, `DESIGN.md`, `ENVIRONMENT.md`, `UPSTREAM_AUDIT.md`, and
`REPO_MAP.md` for the preserved evidence.
