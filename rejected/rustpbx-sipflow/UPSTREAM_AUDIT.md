# RustPBX SipFlow upstream audit

Date: 2026-07-25
Outcome: rejected before problem design

## Revision and source

- Repository: `https://github.com/restsend/rustpbx`
- Default branch observed: `main`
- Candidate revision:
  `ac15e936ee0c8f7bd1eaedc83609d05096ccaf58`
- Candidate commit author date: `2026-07-23T16:48:33+08:00`
- Candidate commit committer date: `2026-07-24T10:47:20+08:00`
- Candidate license: MIT (`LICENSE` and `license = "MIT"` in `Cargo.toml`)
- Package: Rust 2024 edition, `rustpbx` 0.4.12
- Committed `Cargo.lock`: absent

The public GitHub repository showed 731 stars during this audit. The revision
was resolved and inspected in a detached local checkout. These commands were
used:

```text
git rev-parse ac15e936ee0c^{commit}
git show -s --format='%H%n%P%n%aI%n%cI%n%s' ac15e936ee0c
git checkout --detach ac15e936ee0c
git ls-tree -r --name-only HEAD
git log --follow -- docs/config/08-sipflow.md
git log --all -- src/sipflow src/callrecord/sipflow.rs \
  src/console/handlers/sipflow.rs
git ls-files Cargo.lock
```

## Decisive prior art

The proposed task is not fresh at the pinned revision. RustPBX already contains
a production SipFlow subsystem that captures, stores, queries, diagnoses, and
renders SIP signaling together with correlated RTP data.

Representative pinned-revision evidence:

| Surface | Existing behavior |
|---|---|
| `docs/config/08-sipflow.md` | Describes SipFlow as the SIP/RTP capture and recording subsystem, with signaling replay, WAV export, media statistics, storage formats, and data-flow diagrams. |
| `src/sipflow/mod.rs` | Defines public `SipFlowItem`, message/media types, media stats, and flow/media query operations. |
| `src/callrecord/sipflow.rs` | Observes SIP messages, extracts Call-ID and routing data, timestamps records, and batches them into a backend. |
| `src/sipflow/backend/mod.rs` | Provides a backend abstraction for recording and querying flow/media data. |
| `src/sipflow/backend/local.rs` and `flowdb_backend.rs` | Persist and query call-correlated SIP/RTP records; flow queries sort items by timestamp. |
| `src/sipflow/protocol.rs` | Encodes SIP/RTP packets with timestamp, optional call ID, optional leg, endpoints, and payload. |
| `src/sipflow/rtp_stats.rs` and `wav_utils.rs` | Correlate media legs/SSRCs and signaling-derived payload types for diagnostics and audio export. |
| `src/console/handlers/sipflow.rs` | Exposes `/sipflow/flow/{call_id}` and `/sipflow/media/{call_id}` query endpoints. |
| `src/bin/sipflow.rs` and `src/bin/sipflow-diag.rs` | Supply a dedicated server and an offline diagnostic CLI. |
| `src/sipflow/tests.rs` and backend tests | Cover flow isolation, query order/ranges, media legs, RTP statistics, recovery, and storage behavior. |
| `docs/screenshots/call-detail-sipflow.png` and console templates | Demonstrate an existing participant-facing SIP Flow presentation. |

The simplest legitimate implementation of the proposed diagnostic would
therefore query or project the already retained SipFlow records and format the
result. That is precisely the thin-adapter shortcut which `PLAN.md` requires
the audit to reject. Adding transfer/re-INVITE labels would extend an existing
diagnostic rather than create the hypothesized new cross-subsystem seam, and
forbidding reuse of SipFlow storage or requiring new private state would be an
artificial architecture constraint.

## History

SipFlow predates candidate selection by months:

- `3a23f53f8c4e3fcde27641117a0c3cce140abccc`
  (`2025-10-30`): “feat: add sip flow&bill template& record to ogg file”.
- `403dcd3da4f549416c363b029535d19c8b8444f6`
  (`2026-01-20`): “feat: high performance sipflow”.
- `955c2097255c80c90a99d1aed8d4f2d2b48a2eeb`
  (`2026-04-17`): dedicated SipFlow documentation.
- `ea8dc8bbfd7059c25b696eaf463c297b4cbe1ced`
  (`2026-06-13`): FlowDB backend for SIP and RTP flow management.
- `b669583d49914ebf42b79d5499b7b2646274798b`
  (`2026-07-23`): dedicated SQLite flush thread and SipFlow tuning.

This is established upstream behavior, not a feature added after the candidate
revision was chosen.

## Gate disposition

The candidate is rejected at the prior-art/task-identity stop gate. Dependency
resolution, offline image preflight, repository mapping, prototype production
patch, trajectory-informed `DESIGN.md`, hidden tests, false-positive audit, and
calibration were intentionally not started: none can make a duplicate seed
fresh, and the plan forbids rescoping or padding it to rescue the rating.

No `meta.md`, `DESIGN.md`, `test.patch`, reference solution, or calibration
artifact was created.
