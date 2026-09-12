# DESIGN - PcapPlusPlus SNAP encapsulation

Status: `promotion attempt closed after external long-horizon scope rejection`.

Repository: `seladb/PcapPlusPlus` at
`8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`, 2026-08-04).

Primary and proposed production language: C++.

Task type: feature request.

## Public contract and repository evidence

The candidate is first-class IEEE 802.2 SNAP encapsulation in Packet++. The
current `EthDot3Layer`, `VlanLayer`, and `Sll2Layer` can already produce an
`LLCLayer`, but `LLCLayer::parseNextLayer()` recognizes only the direct STP
SAP pair `0x42/0x42`. A valid SNAP LLC header (`0xaa`, `0xaa`, control `0x03`)
therefore becomes a generic payload even though the following five bytes carry
an organization identifier and protocol identifier.

A repository-native feature would add a fixed-size SNAP layer, expose its OUI
and protocol identifier, and dispatch the standard zero OUI through the
existing EtherType-backed packet layers. The strongest extension of the seam
is Cisco OUI `00:00:0c`, protocol identifier `0x010b`: it would pass the BPDU
payload to the existing STP factory and close the source TODO for PVST+/RPVST+
recognition without creating a second STP field model.

The retained behavior is intentionally not a generic dissector registry, an
NTP-style variable-record API, a raw-file copier, or a complete proprietary
Cisco STP implementation. Unknown OUIs and protocol identifiers should remain
payload. The final public contract and exact artifacts are recorded in the
promoted problem folder.

Repository evidence supporting the seam:

- `LLCLayer` already owns the previous-layer classification point and has a
  fixed three-byte header, creation API, payload fallback, and direct STP path.
- `EthLayer`, `VlanLayer`, and `GreLayer` provide established EtherType dispatch
  and `computeCalculateFields()` patterns.
- `StpLayer::parseStpLayer()` already distinguishes configuration, topology
  change, rapid, and multiple-spanning-tree BPDUs. Its source explicitly lists
  PVST+ and RPVST+ as unsupported follow-ups.
- `ProtocolType.h` and `Packet++/CMakeLists.txt` provide the ordinary new-layer
  registration seams.
- Existing LLC, Ethernet 802.3, VLAN, SLL2, STP, IPv4/IPv6, ARP, MPLS, and
  PPPoE tests give deterministic neighboring regression oracles.

## Trajectory-informed design gate

Searches covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, every local problem/archive/candidate record for
PcapPlusPlus, LLC, SNAP, PVST, RPVST, spanning tree, VLAN, GRE routing, and
source-route entries, plus both accepted PcapPlusPlus problem records and raw
archives. No earlier Olympus SNAP/PVST problem or solver run was found.

The accepted PCAPNG and NTP tasks are exclusion evidence as well as solver
evidence. This candidate must not derive its difficulty from raw-format copy,
publication, variable-length extension lists, borrowed-record ownership, or
ordinary layer-resize editing.

Representative raw PCAPNG trajectories were read from
`archive/pcapplusplus-pcapng-filtered-copy/agent-runs.tar.gz`. The accepted NTP
ZIP was also inventoried and its representative pass and near-pass trajectories
and patches were reviewed. NTP has no broad failure in its five-run batch, so
the PCAPNG broad failure remains the nearest available example.

| Evidence role | Problem / raw member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PCAPNG `agent-runs4/Nova_Nova_1` | 69/69 baseline and 14/14 focused | Added a dedicated section-aware scanner in a new source file, preserved section-local state, filtered only packet blocks, and staged destination replacement. Its production patch added 540 lines across build registration, public header, and implementation. This supports testing observable layer routing, not prescribing one helper layout. |
| Near-pass | NTP `Nova_Nova_5` | Baseline passed; 18/19 focused behavior with the short-field-plus-auth boundary wrong | Built a substantial common tail parser and public view/builder API but imposed the final-field minimum before considering authentication. Its production patch added 612 and removed 27 lines in the NTP header/source. The generalized lesson is to test branch boundaries where the same prefix has different meaning, not to reproduce NTP's record API. |
| Broad failure | PCAPNG `agent-runs4/Nova_Nova_10` | 69/69 baseline and 9/14 focused | Used a dedicated scanner but leaked section state and rejected valid Decryption Secrets options. Its production patch added 542 lines across build registration, header, and a new source. For SNAP, each encapsulation must derive dispatch only from its own OUI/PID and must preserve payload fallback instead of carrying classification assumptions across layers. |

The four passing NTP solutions changed the same public layer but used different
ownership and parsing structures. That history is positive evidence for API
freedom, but it also makes GRE source-route records the wrong third task: GRE
routing would again center on a variable-length record list, terminator,
borrowed traversal, and packet resize behavior.

## Discriminator ledger

| Observed solver/repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| PCAPNG near/broad failures overvalidated or leaked structural state | Treat any `0xaa/0xaa` LLC payload as SNAP or reuse one classification outside its layer | SNAP requires the complete LLC signature and five-byte SNAP header; other LLC payloads retain current fallback | Parse control variants, truncated headers, and neighboring LLC frames and compare the produced layer chain | Recognition / fallback | Tests wire-visible classification and permits any construction helper |
| Existing protocol layers dispatch standard EtherTypes from fixed headers | Decode PID without conditioning on OUI | Only the standard OUI interprets PID as EtherType; an unknown vendor using the same numeric PID stays opaque | Compare zero-OUI IPv4/ARP frames with nonzero-OUI frames carrying the same PID | Namespace / dispatch | OUI scoping is public SNAP semantics, not a private map choice |
| NTP near-pass collapsed two legal endings into one minimum rule | Implement only the common zero-OUI path and treat every vendor path identically | If Cisco PVST is retained, its OUI/PID path reaches the existing STP parser while unrelated Cisco PIDs remain payload | Parse classic and rapid BPDU bodies behind the Cisco identifier and a neighboring unknown identifier | Vendor dispatch / sibling protocol integration | Uses existing STP behavior and exact public identifier, without requiring Cisco-internal state |
| Packet++ protocol layers support parse and craft paths | Add read-only classification with no stable round trip | Constructed SNAP headers encode OUI/PID in network order and reparse to the same layer chain | Build detached and packet-attached standard/vendor frames, serialize, and independently decode five header bytes | Crafting / round trip | Wire bytes and reparsed layers are architecture-neutral |
| LLCLayer is reachable through Ethernet 802.3, VLAN length payloads, and SLL2 | Wire SNAP only under one predecessor | Every existing predecessor that delegates to `LLCLayer` gains the same SNAP behavior | Feed the same LLC/SNAP bytes through direct, 802.3, VLAN, and SLL2 entry points where supported | Cross-layer integration | Exercises existing public composition rather than fixture permutations |
| Existing direct STP uses SAP `0x42/0x42` | Replace direct STP recognition while adding SNAP | Legacy direct STP parsing and ordinary unknown LLC payloads remain unchanged | Replay current LLC/STP fixtures and compare layer types and bytes before/after the feature | Compatibility | Protects an established sibling route, not an implementation detail |

## Clause-to-test coverage

The promoted `test.patch` implements these black-box oracles and the complete
pre-existing Packet++ regression lane.

| Public requirement | Strongest observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Recognize complete SNAP LLC frames | Standard OUI/PID packet produces LLC, SNAP, and inner layer | Payload after LLC | First-class SNAP layer | IEEE framing plus current LLC dispatch seam |
| Keep unknown namespaces opaque | Unknown OUI/PID exposes SNAP then payload with exact bytes | One payload containing SNAP header and body | Fixed header plus unchanged payload | Existing fallback convention |
| Dispatch standard PID values | Representative IPv4, IPv6, ARP, VLAN, MPLS, and justified PPPoE identifiers reach existing parsers | Payload | Existing typed layer | Existing EtherType dispatch tables |
| Recognize PVST/RPVST if retained | Cisco OUI/PID plus valid BPDU reaches the existing STP subtype | Payload | Existing STP subtype after SNAP | Source TODO and existing STP factory |
| Reject truncated/near-signature inputs safely | Truncated and wrong-control payloads do not create SNAP or read past input | Payload | Same fallback | `LLCLayer::isDataValid()` and payload convention |
| Support repository-style creation | Constructor/getters/setters emit exact five-byte header and packet round trip | No API | Stable bytes and reparsed chain | New-layer contribution guide and sibling layers |
| Preserve current LLC/STP behavior | Existing 259 Packet++ cases remain green | 259/259 | 259/259 | Clean offline baseline |

## Environment and harness preflight

- The exact `dev` pin was cloned into
  `Work/pcapplusplus-third-problem-audit/source`; the checkout is clean.
- The accepted NTP Docker recipe was reused unchanged as an environment proof.
  It starts from `public.ecr.aws/d3j8x8q7/olympus-base:latest`, installs CMake,
  `libpcap-dev`, and `pkg-config`, and vendors Google Benchmark for offline
  configuration.
- Docker image `sha256:17f35824fc17d4f6706ad6c1e9a269e8854264d318e0b836a413d4ef6921f9e5`
  configured and built `Packet++Test` successfully at the exact pin.
- With Docker networking disabled, CTest passed its aggregate `Packet++Test`
  target and the direct runner passed 259/259 cases with zero failures or
  skips. The earlier missing-CMake/missing-libpcap blocker is therefore closed
  for this pin and recipe.
- Focused fixtures can be generated as byte arrays. No live device, clock,
  service, secret, or nondeterministic input is needed.
- The temporary Docker tag is audit evidence only and is removed after this
  record is verified; the reproducible recipe remains the accepted Dockerfile.

## Applicability score

| Dimension | Score | Reason |
|---|---:|---|
| Eligibility and health (15%) | 10 | Active, 3,122-star, unarchived C++ repository with Unlicense and a green offline suite |
| Rarity (20%) | 6 | SNAP is established networking, but Cisco PVST integration is an uncommon Packet++ seam |
| Task applicability (25%) | 7 | Concrete missing layer and public layer-chain/round-trip oracles; exact first-version scope is unresolved |
| Behavioral depth (15%) | 6 | Namespace-aware dispatch, several predecessor paths, vendor integration, and crafting may span enough production seams, but a thin adapter is plausible |
| Harness feasibility (15%) | 10 | Deterministic byte fixtures and 259 fast offline regressions |
| Prior-art and similarity safety (10%) | 3 | Exact upstream searches are clean, but this would be the third task in one packet library and a visible PVST TODO raises prescription risk |

The pre-prototype weighted result was 7.15, rounded to **7/10 preliminary**.
The subsequent complete prototype and exhaustive audit cleared both hard stops.

## Design verdict

The candidate cleared the trajectory, environment, novelty, prototype, and
behavioral gates and was promoted for a trial. The external evaluator rejected
its long-horizon scope: the complete 193-strict-addition implementation remains
localized to one parser/crafting subsystem. The later PATH blocker was fixed
and reverified, but it does not cure the scope result. Preserve the exact package
in `problems/pcapplusplus-snap-encapsulation/`; do not broaden it with unrelated
docs, examples, or capture features. Calibration remains 0/10.
