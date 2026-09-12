# SNAP exact-artifact false-positive and mutation audit

Date: 2026-08-06.

Repository: `seladb/PcapPlusPlus` at
`8ac4366c4184f096973ef4a0ca084559935828d0`.

Status: `passed with one documented redundant same-family survivor`.

## Immutable artifact version

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `e19d13d62b65114b42fb3eebea6c386c26b09449d14880aa8c7249cbdc1943fb` |
| `test.patch` | `34fdfceeb08e307df008361d1162300bd1004628455eb33d2513b7902c805676` |
| `solution.patch` | `5849d7c4b1ebf18b2b15ee8e53d99fa1f771408551e7662ce0089550e92e94e6` |
| `Dockerfile` | `db662a08ca2218cb5de7f279b84c6a181f261c9ee425c31315a272ea59b85e19` |

The Dockerfile begins with the permitted Olympus base and resolved that base to
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`
during verification.

The focused C++ source uses the generated collision-resistant filename
`Tests/SnapLayerTest/SnapLayerTest_cceed1.cpp`. The suffix was generated with
`openssl rand -hex 3`; neither banned marker appears in the path. This rename
changed no scenario, assertion, public requirement, or reference behavior.

## Requirement-to-test map

| Participant-facing requirement | Strongest behavioral scenario |
| --- | --- |
| Complete LLC signature and five-byte recognition | `RecognitionBoundaries` |
| Public protocol identity, header position, OUI/PID decoding | `RecognitionAndFields` |
| Nonzero OUI namespace and unknown PID opacity | `NamespaceFallback` |
| Zero-OUI dispatch for every listed EtherType | `StandardDispatch` |
| Rejected inner parsers fall back without losing bytes | `InnerFallback` (invalid IPv4 and ARP, plus invalid Cisco BPDU) |
| Cisco OUI/PID routes valid classic and rapid BPDUs only | `CiscoStpDispatch` |
| Constructor, low-24-bit OUI, network order, setters, validation | `ConstructionAndSetters` |
| Standard, Cisco/STP, and unknown-next compute behavior | `ComputeFields` |

Repository-default regression coverage is tracked separately from the public
requirements:

| Repository-discoverable invariant | Strongest behavioral scenario |
| --- | --- |
| Changes in `LLCLayer` apply consistently through existing VLAN-length and SLL2 producer paths | `PredecessorPaths` |
| A fixed-header Packet++ layer follows ordinary attachment, serialization, reparse, and copy behavior | `AttachedRoundTripAndCopy` |
| Existing direct LLC/STP and Packet++ behavior remains compatible | complete 259-case `Packet++Test` lane |

The malformed-inner probes deliberately use two standard protocol families,
not every listed EtherType. Another invalid-protocol fixture would repeat the
same public discriminator rather than add a semantic boundary.

## Plausible incorrect implementations

The matrix was derived from the current `LLCLayer`, `EthLayer`, `VlanLayer`,
`Sll2Layer`, and STP factory patterns plus the trajectory ledger. Twenty-two
mutations were compiled and tested against the exact focused source. Results:

| Mutation | Result |
| --- | --- |
| Ignore LLC control byte | killed by `RecognitionBoundaries` |
| Accept truncated SNAP whenever payload is nonempty | killed by `RecognitionBoundaries` |
| Recognize SNAP only through Ethernet 802.3 | killed by `PredecessorPaths` |
| Treat four bytes as a valid SNAP header | killed by recognition and validation scenarios |
| Interpret supported PIDs without checking OUI | killed by namespace and Cisco scenarios |
| Reverse OUI byte order | killed by field, constructor, Cisco, and compute scenarios |
| Encode the high rather than low 24 OUI bits | killed by constructor and compute scenarios |
| Read PID in host byte order | killed across field, dispatch, Cisco, compute, predecessor, and round-trip scenarios |
| Omit generic payload fallback | killed by namespace, inner-fallback, and Cisco scenarios |
| Omit IPv6 dispatch | killed by `StandardDispatch` |
| Omit provider-bridge VLAN dispatch | killed by `StandardDispatch` |
| Construct malformed IPv4 directly | killed by `InnerFallback` |
| Construct malformed ARP directly | killed by `InnerFallback` |
| Construct malformed VLAN directly | survived focused and complete suites; see below |
| Ignore Cisco PID | killed by `CiscoStpDispatch` |
| Ignore Cisco OUI | killed by `CiscoStpDispatch` |
| Omit Cisco/STP route | killed by `CiscoStpDispatch` |
| Omit STP compute mapping | killed by `ComputeFields` |
| Omit parsed PPPoE-session compute mapping | killed by `ComputeFields` |
| Overwrite explicit values for an unknown next layer | killed by `ComputeFields` |
| Report a four-byte layer header | killed by field, constructor, compute, and round-trip scenarios |
| Break existing direct LLC/STP parsing | survived focused tests and was killed by the complete 259-case lane |

The malformed-VLAN survivor violates the same selected-parser fallback family
already represented by malformed IPv4 and ARP. It was run through the complete
suite and survived there as well. It is retained as a documented limitation of
the attempted mutation set: adding one fixture for each switch arm would be a
symmetry permutation, not a distinct discriminator, and would conflict with the
design gate's anti-overfitting rule. The public rule remains explicit.

No arbitrary predicates, private helper assumptions, output strings, or
prototype-only state were tested. A zero-survivor claim is not made.

## Exact lane results

- Test-only exact state: `Packet++Test` passes; the new lane emits JUnit with
  all ten named scenarios failed because the feature API is absent.
- Exact combined state: all ten focused scenarios pass and the direct
  `Packet++Test` runner passes 259/259 with zero failures and skips.
- The focused harness passes under UID/GID `1000:1000`, creates its build tree
  under `/tmp`, and emits JUnit without writing into the checkout.
- Focused ASan/UBSan probes pass for recognition, namespace fallback, Cisco
  routing, truncation, and attached construction. Packet++ compiles with its
  warnings-as-errors policy.
- Every configure/build/test replay after image creation ran with Docker
  networking disabled.

After the collision-resistant rename, both patch application orders were
replayed from the exact pin. Fresh test-only and combined images rebuilt
successfully. The combined state again passed 10/10 focused scenarios and
259/259 direct baseline cases; the test-only state passed its baseline lane and
emitted all ten expected named failures. Both combined lanes also passed as
UID/GID `1000:1000` while writing build state under `/tmp`.

The exact 22-mutant matrix was rerun after the rename. Results were unchanged:
twenty focused kills, the legacy direct-STP survivor killed by the complete
baseline, and only the documented malformed-VLAN same-family permutation
surviving. The mutation checkout was restored afterward and passed both focused
and complete suites.

A broader sanitizer invocation also exercised every focused scenario. The five
scoped sanitizer probes above passed; `ComputeFields` additionally reached an
existing unaligned 16-bit load in `Packet++/src/PacketUtils.cpp`. That library-
wide alignment behavior is outside the SNAP contract and was not converted into
a hidden discriminator.

The public description was then shortened by deleting the explicit predecessor
enumeration and generic Packet++ attachment/copy sentence. The exact artifact
hash above reflects that revision. The requirement map was repeated: no public
behavioral rule was lost, because both deleted statements describe ordinary
repository behavior rather than SNAP-specific semantics. Their existing tests
remain repository-default integration regressions, not hidden additions to the
participant-facing contract. The executable artifacts and all 22 mutation
inputs are byte-identical to the immediately preceding audited version, so the
recorded executions apply unchanged; the saved-solver search was also repeated
and still found no SNAP/PVST solver.

An external baseline run subsequently reported `cmake: not found` from the
derived evaluator image even though the exact Dockerfile installs and invokes
CMake successfully. The harness now restores `/usr/local/bin`, `/usr/bin`, and
`/bin`, resolves CMake and CTest explicitly, and emits a diagnostic JUnit record
if either tool remains unavailable. Fresh exact test-only and combined images
were rebuilt after this change. With Docker networking disabled, PATH reduced
to `/evaluation-tools`, and UID/GID `1000:1000`, the baseline passed and the
combined focused lane passed 10/10. The ordinary test-only baseline also passed,
while its new lane emitted the ten intended failures. The 22-mutant matrix was
rerun against this exact test hash with unchanged results, and the restored
reference again passed both focused and 259-case suites.

## Saved-solver and cold-solver record

Local accepted, candidate, and archive histories were searched before test
authoring. There is no saved SNAP/PVST solver patch to replay. The existing
PcapPlusPlus PCAPNG and NTP solvers implement unrelated file-copy and
variable-record APIs and do not apply to this public interface, so treating
their non-applicability as a solver result would be misleading. They remain
trajectory-informed design evidence only.

No cold solver was run.
