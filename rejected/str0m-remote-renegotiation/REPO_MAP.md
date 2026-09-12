# Repository map - str0m remote negotiation

| Area | Relevance |
|---|---|
| `src/change/sdp.rs` | `SdpApi::accept_offer`, ICE/DTLS/SCTP processing, SDP rendering, session/media synchronization |
| `src/session.rs` | Media/application ownership, event polling, stream state |
| `src/media/mod.rs` | Direction, stopped state, remote payload/extension state, event flags |
| `src/sctp/mod.rs` | SNAP local/remote initialization and established-state checks |
| `src/sdp/data.rs` | Parsed SDP consistency, ICE/fingerprint/SCTP attribute access |
| `src/lib.rs` | `Rtc` lifecycle, DTLS/SCTP initialization, public output and media APIs |
| `src/change/direct.rs` | Public ICE credential, candidate invalidation, and DTLS fingerprint oracles |
| `tests/common.rs` | Peer construction, negotiation, progress, and SNAP SDP helpers |
| `tests/sdp-negotiation.rs` | Existing offer/answer, direction, codec, and SNAP behavior |
| `tests/sdp-m-recycle.rs` | Existing stopped-slot recycling and follow-up negotiation |

The golden solution changes only `src/change/sdp.rs`. The hidden test patch adds
one integration test file plus the repository-root harness and nextest JUnit
configuration.
