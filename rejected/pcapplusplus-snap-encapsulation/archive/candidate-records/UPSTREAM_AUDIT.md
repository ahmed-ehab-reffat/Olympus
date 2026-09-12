# PcapPlusPlus SNAP/PVST upstream audit

Status: `complete; no implementation, abandoned patch, or maintainer rejection found`.

Date: 2026-08-06.

Pin: `8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`).

## Repository facts

- Public GitHub repository: `seladb/PcapPlusPlus`
- Observed stars: 3,122
- Primary/proposed language: C++
- License: Unlicense
- Archived: no
- Current contribution branch: `dev`
- Pushed through 2026-08-05 at the audit time

## Exact source and history searches

The pinned source, tests, documentation, reachable history, and fetched remote
heads were searched for:

- `SnapLayer`, SNAP, Subnetwork Access Protocol, LLC/SNAP;
- PVST, RPVST, Per-VLAN Spanning Tree;
- Cisco OUI `00:00:0c`, PID `0x010b`, and broader OUI/PID terms; and
- the relevant `LLCLayer`, `StpLayer`, `ProtocolType`, and CMake paths.

No SNAP layer, SNAP protocol registration, fixture, or implementation was
found. The current STP source retains only the PVST+, RPVST+, and Cisco Uplink
Fast TODO comments introduced with LLC/STP support. `git log -S` and `git log
-G` found the original LLC/STP work and later STP crafting support, not an
abandoned SNAP implementation.

## GitHub searches

All-state issue/PR searches used the exact feature nouns and broad
synonyms. Exact repository search pages returned zero issues for `SnapLayer`,
`IEEE 802.2 SNAP`, `LLC SNAP`, `PVST`, and `RPVST`. Preliminary GitHub API
searches also returned no PVST/RPVST issue or pull request.

The audit did find two useful rejection controls elsewhere in the repository:

- `RawPacket` capacity tracking has open issue #1910 and closed implementation
  PR #1911, so it is not a novel replacement candidate.
- custom port-based protocol resolution has issue #671 and closed
  implementation PR #1881, so it is also not a novel replacement candidate.

GRE routing has no matching implementation but is rejected locally for task
shape: it would repeat the accepted NTP problem's variable-record parsing,
traversal, and edit lifecycle.

## Completed exhaustive surfaces

- GitHub Discussions are disabled for this repository; the Discussions route
  returned 404 rather than hiding an enabled discussion corpus.
- Release notes, six remote heads, sixteen tags, documentation/API snapshots,
  and reachable history contained no SNAP/PVST implementation or incompatible
  public API.
- Review threads and commit histories for LLC/STP PR #903 and STP crafting PR
  #1022 contained no SNAP omission decision, maintainer rejection, or abandoned
  implementation.
- The fork audit inventoried 746 forks and resolved 726 default heads. Sixty-
  seven default heads outside the upstream object graph were inspected at the
  relevant paths, and 2,740 branch-head names were searched for feature terms.
  No SNAP layer or PVST implementation was found.
- The only relevant match remains the existing PVST+/RPVST+ TODO in the STP
  implementation. It does not specify an API or provide solution code.

The novelty hard stop is therefore closed for the pinned version. This audit
supports promotion but does not claim that no future upstream work can appear.
