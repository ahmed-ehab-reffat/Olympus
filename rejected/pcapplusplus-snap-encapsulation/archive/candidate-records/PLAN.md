# PLAN - PcapPlusPlus SNAP encapsulation investigation

Status: `completed; promotion attempt closed after external scope rejection`.

Repository pin: `8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`).

Production language: C++.

Task type: feature request.

## Objective

Determine whether a first-class IEEE 802.2 SNAP layer, including standard-OUI
EtherType dispatch and a narrowly justified Cisco PVST/RPVST route, can become
a fair and substantial third PcapPlusPlus problem.

The investigation should end in rejection if the cheapest complete feature is
a thin fixed-header wrapper, if Cisco behavior needs private policy, if an
upstream implementation exists, or if the resulting task repeats the NTP
record/edit architecture.

## Frozen exclusions

- Do not alter either accepted PcapPlusPlus problem or its four canonical
  submission artifacts.
- Do not create `meta.md`, `test.patch`, `solution.patch`, a candidate
  Dockerfile, or a `problems/` folder during this phase.
- Do not use GRE source routing as a fallback; its variable record list,
  terminator, traversal views, and resize edits are too close to NTP.
- Do not broaden into a protocol callback registry, full Cisco STP state,
  live capture, or unrelated Ethernet length fixes to increase size.

## Phase 1 - complete source and upstream audit

1. Inspect current and historical LLC, Ethernet 802.3, VLAN, SLL2, STP, and
   protocol-registration behavior at the pin.
2. Search all issues, pull requests, Discussions, branches, tags, release
   notes, review comments, and relevant fork heads for `SnapLayer`, SNAP,
   Subnetwork Access Protocol, LLC/SNAP, PVST, RPVST, Cisco OUI, `0x010b`, and
   broader organization/protocol identifier terms.
3. Inspect the history and review of the original LLC/STP PR #903 and the later
   STP crafting/editing PR #1022.
4. Record whether maintainers intentionally excluded SNAP/PVST, requested a
   particular API, or accepted any abandoned implementation.

## Phase 2 - wire and API matrix

Build a small independent five-byte SNAP decoder and resolve:

- valid LLC signature and truncated-header boundaries;
- 24-bit OUI and 16-bit PID byte order;
- standard zero-OUI dispatch set and unknown fallback;
- Cisco OUI/PID behavior for classic and rapid BPDU bodies;
- unknown Cisco PID and same PID under another OUI;
- direct LLC, Ethernet 802.3, VLAN-length, and SLL2 entry paths;
- constructor/getter/setter and `computeCalculateFields()` behavior; and
- legacy direct STP and ordinary LLC compatibility.

Prefer an API shaped like existing fixed-header layers. Do not introduce
borrowed record views, builders, dynamic registries, or validation callbacks.

## Phase 3 - cheapest complete prototypes

Create two isolated disposable prototypes under
`Work/pcapplusplus-third-problem-audit/`:

1. a minimal standards-only SNAP layer; and
2. a complete repository-shaped SNAP plus justified PVST route.

For each, record production files, raw and strict effective LOC, layer-chain
behavior, formatting, compiler warnings, 259-test regression result, and an
ASan/UBSan focused run. Compare whether the complete version introduces
independent behavior or merely more dispatch constants.

Expected production seams are `LLCLayer`, a new fixed-header layer,
`ProtocolType.h`, `Packet++/CMakeLists.txt`, and protocol/string registration
if required. This is a forecast, not a required architecture.

## Phase 4 - decision

Promote only if:

- the exhaustive audit finds no implementation or maintainer rejection;
- the public wire contract is self-contained without proprietary inference;
- the cheapest complete implementation has several independent behavioral
  boundaries and plausible alternative architectures;
- the exact official-base offline harness stays green and writable as a
  non-root UID; and
- the task is demonstrably independent from both accepted PcapPlusPlus tasks.

If promoted, copy the known-good Docker dependency recipe rather than
reintroducing the earlier CMake/libpcap environment blocker. The then-current
workspace instructions determine which hardening checks are mandatory; no
solver calibration is authorized by this research plan.

## Outcome

All four phases completed. The exhaustive upstream and fork audit remained
clean. The standards-only prototype measured 179 strict production additions;
the complete SNAP/PVST prototype measured 193 and introduced independent Cisco
namespace/STP behavior. Both passed 259/259 pre-existing tests, and the complete
version passed focused ASan/UBSan checks.

The promoted package has ten focused black-box scenarios, a portable `/tmp`
build harness with JUnit setup-failure emission, an exact solution patch, and a
permitted Olympus Docker base. Its exact mutation/false-positive audit is in
the problem folder. No cold solver or platform calibration was run.

The external trial initially exposed a derived-image PATH blocker; the harness
was hardened and then passed with a deliberately stripped PATH as non-root. The
trial nevertheless rejected the problem's long-horizon scope. Because the
complete reference remains a localized 193-strict-addition implementation, the
candidate is closed rather than padded with unrelated repository work.
