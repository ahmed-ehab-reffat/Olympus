# PcapPlusPlus TLS stream reassembly

Status: **accepted and archived 2026-08-08**.

- Repository: `seladb/PcapPlusPlus`
- Commit: `8ac4366c4184f096973ef4a0ca084559935828d0`
- Production language: C++
- Task type: feature request
- Platform outcome: user-confirmed success

The accepted feature layers TLS record and plaintext-handshake framing over the
existing TCP reassembly engine. It coordinates arbitrary TCP segmentation,
coalesced records, nested 24-bit handshake framing, per-direction state, loss
recovery, configured limits, lifecycle forwarding, and cleanup.

The exact accepted package passes 14/14 focused tests and the 259-case Packet++
aggregate. The clean repository passes its one baseline harness test, while the
test-only package fails all 14 focused cases as intended. The final
false-positive audit kills 59/59 repository-grounded mutants, and an independent
buffer-complete oversized-message implementation also passes 14/14.

The two calibration batches are historical evidence rather than results for the
final immutable package. The final revision remained locally at 0/10 before the
platform accepted it; no cold solver was run after the final revision.

Canonical artifacts remain in this directory. Raw solver bundles, candidate
records, scratch recovery, and Docker cleanup evidence are under
[`archive/pcapplusplus-tls-stream-reassembly/`](../../archive/pcapplusplus-tls-stream-reassembly/).
