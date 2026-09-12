# RustPBX SipFlow archive manifest

Archived on 2026-07-25 after rejection at the upstream
prior-art/task-identity gate.

## Why the seed failed

The pinned revision already contains a mature `SipFlow` subsystem for SIP/RTP
capture, storage, query, diagnostics, media statistics, console presentation,
and offline analysis. The feature dates to 2025-10-30 and received substantial
production work before candidate selection.

The proposed deterministic cross-leg diagnostic would therefore be a projection
or formatter over an existing structured event store. Adding transfer or
re-INVITE labels would extend the existing feature rather than establish the
hypothesized new cross-subsystem task. Forbidding reuse of SipFlow state would
be an artificial private-architecture requirement.

## Preserved records

- `UPSTREAM_AUDIT.md`: pinned-revision source and history evidence.
- `PLAN.md`: original gated handoff with its terminal rejection record.

No environment build, prototype patch, `DESIGN.md`, prompt, hidden tests,
reference solution, verifier, or calibration run was created because the
prior-art stop gate was decisive.

## Reuse rule

RustPBX remains eligible for a materially different task. Do not revive the
SipFlow seed through new formatting, deterministic sorting, transfer labels,
media labels, or restrictions on using the existing capture/query subsystem.
