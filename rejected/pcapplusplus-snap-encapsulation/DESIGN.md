# DESIGN - PcapPlusPlus SNAP encapsulation

Status: `locally verified, but external long-horizon review rejected scope; not submission-ready`.

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
payload. The public constructor, standard EtherType set, and Cisco route are
fixed in `meta.md` and exercised through public layer and wire behavior.

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

| Observed solver/repository behavior | Generalized shortcut | Fair public/repository invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| PCAPNG near/broad failures overvalidated or leaked structural state | Treat any `0xaa/0xaa` LLC payload as SNAP or reuse one classification outside its layer | SNAP requires the complete LLC signature and five-byte SNAP header; other LLC payloads retain current fallback | Parse control variants, truncated headers, and neighboring LLC frames and compare the produced layer chain | Recognition / fallback | Tests wire-visible classification and permits any construction helper |
| Existing protocol layers dispatch standard EtherTypes from fixed headers | Decode PID without conditioning on OUI | Only the standard OUI interprets PID as EtherType; an unknown vendor using the same numeric PID stays opaque | Compare zero-OUI IPv4/ARP frames with nonzero-OUI frames carrying the same PID | Namespace / dispatch | OUI scoping is public SNAP semantics, not a private map choice |
| NTP near-pass collapsed two legal endings into one minimum rule | Implement only the common zero-OUI path and treat every vendor path identically | If Cisco PVST is retained, its OUI/PID path reaches the existing STP parser while unrelated Cisco PIDs remain payload | Parse classic and rapid BPDU bodies behind the Cisco identifier and a neighboring unknown identifier | Vendor dispatch / sibling protocol integration | Uses existing STP behavior and exact public identifier, without requiring Cisco-internal state |
| Packet++ protocol layers support parse and craft paths | Add read-only classification with no stable round trip | Constructor/getter/setter behavior emits stable network-order bytes; ordinary Packet integration remains compatible | Build and serialize standard/vendor frames and independently decode the five header bytes | Crafting / round trip | Wire bytes are public and Packet integration is a repository-wide layer invariant |
| LLCLayer is reachable through Ethernet 802.3, VLAN length payloads, and SLL2 | Wire SNAP only under one predecessor | Every existing predecessor that delegates to `LLCLayer` gains the same SNAP behavior | Feed the same LLC/SNAP bytes through direct, 802.3, VLAN, and SLL2 entry points where supported | Cross-layer integration | Exercises existing public composition rather than fixture permutations |
| Existing direct STP uses SAP `0x42/0x42` | Replace direct STP recognition while adding SNAP | Legacy direct STP parsing and ordinary unknown LLC payloads remain unchanged | Replay current LLC/STP fixtures and compare layer types and bytes before/after the feature | Compatibility | Protects an established sibling route, not an implementation detail |

## Clause-to-test coverage

The exact `test.patch` provides public black-box scenarios, repository-default
integration regressions, and the complete pre-existing Packet++ lane.

| Public/repository requirement | Strongest observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Recognize complete SNAP LLC frames | Standard OUI/PID packet produces LLC, SNAP, and inner layer | Payload after LLC | First-class SNAP layer | IEEE framing plus current LLC dispatch seam |
| Keep unknown namespaces opaque | Unknown OUI/PID exposes SNAP then payload with exact bytes | One payload containing SNAP header and body | Fixed header plus unchanged payload | Existing fallback convention |
| Dispatch standard PID values | Representative IPv4, IPv6, ARP, VLAN, MPLS, and justified PPPoE identifiers reach existing parsers | Payload | Existing typed layer | Existing EtherType dispatch tables |
| Recognize PVST/RPVST if retained | Cisco OUI/PID plus valid BPDU reaches the existing STP subtype | Payload | Existing STP subtype after SNAP | Source TODO and existing STP factory |
| Reject truncated/near-signature inputs safely | Truncated and wrong-control payloads do not create SNAP or read past input | Payload | Same fallback | `LLCLayer::isDataValid()` and payload convention |
| Support repository-style creation | Constructor/getters/setters emit the exact five-byte network header | No API | Stable encoded bytes | New-layer contribution guide and sibling layers |
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
The completed prototype and novelty audit subsequently cleared both recorded
hard stops; calibration remains 0/10.

## Design verdict

The mandatory trajectory, novelty, environment, prototype, hidden-test, and
false-positive gates are complete. The complete SNAP/PVST scope is approved as
a real, locally verified problem. It is materially independent from the two
accepted PcapPlusPlus tasks and requires no unpublished proprietary policy.
Solver calibration has not been run, so this record does not claim a calibrated
difficulty level or submission acceptance.

## Promotion prototype evidence — 2026-08-06

The exhaustive novelty audit found no implementation or maintainer rejection in
upstream issues, pull requests, disabled Discussions, release notes, six remote
branches, sixteen tags, PR #903/#1022 review histories, or the fork network. The
fork audit inventoried 746 forks, resolved 726 default heads, inspected the 67
default heads outside the upstream object graph at the relevant source paths,
and searched 2,740 branch-head names. No SNAP layer or PVST implementation was
found; the only matching code was the existing STP TODO.

Two isolated prototypes were implemented at the exact pin. The standards-only
prototype changes five production files with 255 insertions and one deletion
(179 strict nonblank, non-comment additions). The complete prototype changes
the same five files with 269 insertions and one deletion (193 strict additions).
The complete delta adds the Cisco OUI/PID route as an independent namespace/STP
discriminator rather than as size padding.

Both prototypes compile with warnings-as-errors for Packet++, pass the complete
259-case Packet++ regression runner offline, and the complete prototype passes
focused recognition, namespace, fallback, PVST, wire-encoding, setter, attached
crafting, ASan, and UBSan probes. The feature therefore does not collapse to a
single classifier: it has independent LLC recognition, five-byte validation,
24-bit/16-bit byte order, OUI-scoped dispatch, malformed-inner fallback,
Cisco/STP routing, creation, field mutation, compute, and layer-chain behavior.

Promotion decision: **approve the complete SNAP/PVST scope for hidden-test
authoring**. Keep every assertion on the public wire and layer API. Do not test
the prototype's private constants, switch structure, or helper layout.

## Exact-artifact hardening evidence

The immutable artifact version and requirement map are recorded in
`FALSE_POSITIVE_AUDIT.md`. Twenty-two repository-grounded mutations were
compiled and exercised. Twenty were killed by the focused suite, one legacy
direct-STP regression was killed by the complete 259-case suite, and one
malformed-VLAN mutant survived as a documented same-family permutation of the
already tested malformed IPv4/ARP fallback rule. No redundant per-switch-arm
fixture was added.

The exact combined artifact state passes all ten focused scenarios, 259/259
pre-existing Packet++ tests, non-root UID/GID `1000:1000` execution, and focused
ASan/UBSan checks with Docker networking disabled. The test-only state keeps
the base suite green and emits all ten expected named failures in JUnit. No
saved SNAP/PVST solver existed locally, and no cold solver was run.

The focused implementation source was subsequently renamed to the generated
collision-resistant path `Tests/SnapLayerTest/SnapLayerTest_cceed1.cpp`. The
exact patch-state, non-root, saved-solver-search, sanitizer, and 22-mutant gates
were repeated for the resulting artifact hash; behavioral results were
unchanged. The audit record contains the final hash and rerun details.

## External evaluation outcome

The first external run did not reach either suite because its derived execution
environment hid CMake from PATH. `test.sh` now restores the standard binary
directories and resolves CMake/CTest explicitly. A fresh evaluator-like replay
with PATH set only to `/evaluation-tools`, networking disabled, and UID/GID
`1000:1000` passes the baseline and all ten focused scenarios. The portable
harness blocker is therefore fixed in the current exact test hash.

The same evaluation rejected the task on long-horizon scope. That criticism is
substantive: the complete reference has 193 strict production additions across
five files and remains centered on one Packet++ parsing/crafting subsystem. It
is close to, but below, the workspace's current 200-effective-line scope signal,
and no saved independent SNAP/PVST solver exists to supply contrary median or
message-count evidence. No cold solver was authorized.

Adding documentation, examples, fixtures, or an unrelated capture/filter API
would manufacture breadth rather than introduce a necessary public behavior.
Those suggestions are therefore rejected under the no-padding design rule. The
package is preserved as a correct locally verified implementation study, but
its promotion is withdrawn and it should not be resubmitted as an Olympus
problem without a genuinely different, repository-required system boundary and
a fresh design gate.
