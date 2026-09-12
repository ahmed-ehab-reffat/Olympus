# Upstream audit - str0m remote negotiation

Audit date: 2026-07-23.

Pinned repository state:

- repository: `algesten/str0m`;
- commit: `98d3b401e4fada626122b9846a5b4f9dd1d5d741`;
- default branch: `main`;
- license: MIT OR Apache-2.0;
- Rust edition 2024 and MSRV 1.85.0.

The audit searched all 182 issues, 826 pull requests, nine Discussions, main
history, and 101 branch names. Related SDP retry, transaction API, safety, and
offer-test branches were compared with main. No issue, proposal, branch, or
commit implements failure-atomic rejection of remote offers or rollback of
partially applied SDP state.

Local Olympus history was searched through `problems/README.md`,
`candidates/CANDIDATES.md`, problem records, and archived manifests. No str0m
submission or equivalent SDP task was found. The closest trajectory evidence
concerns cross-domain transactional state and is recorded, with its limits, in
`DESIGN.md`.

Refresh this audit before submission if upstream `main` moves, a new SDP issue
or pull request appears, or solver calibration is delayed.
