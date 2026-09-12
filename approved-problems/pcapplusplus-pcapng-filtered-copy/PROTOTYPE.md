# PROTOTYPE - cheapest complete PCAPNG filtered copy

## Base information-loss reproduction

`audit/high_level_copy_probe.cpp` implements the ordinary public route:

```text
PcapNgFileReaderDevice -> setFilter("tcp") -> getNextPacket(packet, comment)
                       -> PcapNgFileWriterDevice::writePacket
```

It completed successfully on the 1,396-byte two-section fixture, but emitted a
172-byte synthesized, little-endian, one-section capture containing only the
first section's accepted packet. Its SHA-256 was
`72701675f09656605414d2159bb225e8f24a82ce784dad96e712da5e658024fc`.
The probe source and Linux binary hashes were respectively
`4844ceaa726973d10f3240d4076eba7e8cc205fa93fca19a148aa63c360ce7d3`
and
`73af2042df731ab053cd1976cc21ce35a0859a0903efb1e5a83632cd12142663`.
The independent scanner could parse its framing but rejected it against the
1,064-byte expected result with
`actual output differs from independent reference bytes`. This reproduces
section/metadata loss and the current mixed-endian reader limitation.

## Attempt 1: existing whole-list/subcapture route

The 31-line `audit/light_subcapture_probe.c` calls the bundled
`light_read_from_path()`, selects packets through `light_subcapture()`, and
serializes the result. Source SHA-256:
`0587628cd2711265957345f1a4334a04b444144f0ad5a3d3f29bb031cff22b64`.
The corresponding binary SHA-256 was
`298106e21f47f3664488c63b0adc80a5bcc42d9ba7ae5311cb631a8d6138d0e3`.

On the mixed-endian fixture, current LightPcapNg logged repeated block-length
and parse mismatches and exited 139 without producing an output. Source audit
also found that `light_subcapture()`:

- models one root rather than resetting section state;
- computes section length including the SHB, while the draft excludes it; and
- raw-copies the standardized do-not-copy Custom Block because that code is
  not defined.

Fixing the parser/serializer honestly requires material changes in vendored C.
This is not a supported participant-language route. The failed attempt still
shows that the existing API wrapper itself is tiny.

## Attempt 2: smallest public C++ operation

The successful disposable patch adds:

```cpp
bool PcapNgFileReaderDevice::copyFiltered(
    const std::string& outputFileName) const;
```

The caller uses the existing `setFilter()` BPF expression. The implementation
reads the uncompressed file into a byte vector, then performs one block loop:

```text
SHB  -> detect byte order, finish/restart section length, clear local IDBs
IDB  -> append local link type/snap length, raw-copy
EPB  -> validate local ID/lengths, BPF match, raw-copy or drop
SPB  -> use local ID 0/snap length, BPF match, raw-copy or drop
ISB  -> validate local ID, raw-copy
type 0x40000BAD -> drop
other -> raw-copy
```

It rejects obsolete Packet Blocks rather than leaving an unfiltered packet in
the output. It validates all framing and relevant local references before
opening the destination. Finite section lengths are rewritten; `-1` and every
other retained byte are preserved.

Production diff:

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 170 | 0 |
| **Total** | **2 files** | **178** | **0** |

Strict diff SHA-256:
`459b089a64714ce5e90a971ebfa01992a35a45a23515e89b02902b8619c72246`.
The patched header and source hashes were
`c147d556a61579fe6b5c82a2f7110aca45d5596365945efe830f757861b93d62`
and
`2b4b3e0bc186294e266a428139fc9a06999900ce47ecab32f1ae5da2a4eac6de`.
The public probe source and Linux binary hashes were
`d7081279f4d4c7821ae7f733c855c4e4b396499af63f28cd6e4cf6f02196442a`
and
`11ce2233f090296df921500c8dc0f62ac85fbffbc11544999a59880a4bd89bc4`.
No production C, vendored, generated, test, documentation, or fixture line is
included in the count.

The prototype compiled as C++14, passed `git diff --check` and
clang-format 19.1.6, and returned an output exactly equal to the independent
expected bytes:

```text
expected SHA-256 6d3972b7df8ffdd98a3f8858cc69f3cfba7af5436887c06e21fc136e652f2558
actual   SHA-256 6d3972b7df8ffdd98a3f8858cc69f3cfba7af5436887c06e21fc136e652f2558
```

The offline full CTest suite passed 2/2 in 12.14 seconds. The tag replay
reported 113 cases, 71 passed, 0 failed, 42 skipped in 9.128 seconds; it is a
selector union, not a PCAPNG-only lane. Exact environment and commands are in
`ENVIRONMENT.md`.

## Semantic decisions versus repeated cases

The fixture looks broad, but its NRB, DSB, copyable Custom, unknown blocks,
accepted packet options, and all opaque option/padding cases share one
raw-copy decision. Retaining every IDB removes remapping entirely. The
remaining work is a familiar section-aware framing loop plus two packet
formats and one copy-policy exception.

The solution reaches two production files but is below the 200-production-line
signal at 178 additions. More importantly, two independent mandatory hard
stops fire even without relying on a numeric edge:

1. the raw default branch collapses most named block coverage into fixtures of
   one decision; and
2. retaining all IDBs removes honest remapping, leaving a conventional
   filter/copy loop.

A solver can discover this architecture directly from the format and current
reader/writer seam. Requiring interface pruning, packet editing, compression,
atomic publication, a public block visitor, or more exhaustive option
validation would be padding or a different task. The correct result is
rejection, not scope inflation.

## Experimental promotion

The original candidate verdict treated this compact reference as terminal.
The user reopened it after direct review of Railway evidence: Railway's
81-line preview grew to a 638-line accepted reference, and representative
solver patches were roughly 850–916 additions across six files. The raw
Railway trajectories and exact rationale are now recorded in this problem's
`DESIGN.md`.

This prototype remains intentionally unpadded and is the reference candidate
for the experimental package. Actual successful PcapPlusPlus solver patches,
not this 178-line implementation, will decide the long-horizon gate.

## Residual risks

The successful prototype is evidence for task shape and the predecessor
reference patch. It does not handle Zstd, obsolete Packet Blocks, interface
pruning, or atomic output. Those are explicit exclusions, not unresolved
hidden-test ideas. Custom Options in retained blocks are preserved opaquely
rather than interpreted. The anonymous GitHub API quota was exhausted at
closeout, but the final `git ls-remote` still confirmed the default branch and
the earlier complete query snapshot is recorded in `UPSTREAM_AUDIT.md`.

## L2 reference expansion

The revised reference retains the same public method and raw-copy architecture
but validates inner framing before retaining standardized blocks:

```text
options -> read type/length, advance by padded value size within block
NRB     -> walk padded records through zero-type/zero-length terminator,
           then validate options
DSB     -> bound and pad secrets payload, then validate options
```

It also handles multiple IDBs through the existing section-local vector; the
new test makes Interface ID 1 observable rather than changing that
architecture.

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 245 | 0 |
| **Total** | **2 files** | **253** | **0** |

The strict non-comment, non-blank count is 231 additions. Exact
`solution.patch` SHA-256 is
`03e94b197fa99723086f00807e29637afa1076c721fba7c8552ecf24270d88e0`.
The complete exact-version matrix, 21-mutant audit, and three predecessor
trajectory replays pass their required outcomes as recorded in
`FALSE_POSITIVE_AUDIT.md`.

## L3 reference correction

L3 preserves the same declaration and scanner architecture. One production
line adds the missing SHB minor-version check, while the existing option
validator's block-end success path supplies the valid no-terminator behavior.
The expanded tests expose that acceptance boundary, a non-TCP filter, malformed
SPB length equations, and the remaining standardized option starts.

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 246 | 0 |
| **Total** | **2 files** | **254** | **0** |

The strict non-comment, non-blank count is 232 additions. Exact
`solution.patch` SHA-256 is
`33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`.
The 11-case matrix, 28-mutant audit, and four L2 trajectory replays are
recorded in `FALSE_POSITIVE_AUDIT.md`.

## L4 discriminator expansion

L4 does not expand production scope or pad the reference. The reference
already uses `BpfFilterWrapper::matches()`, ignores the IDB reserved field,
and raw-copies unrecognized blocks. It therefore satisfies the new
default/cleared-filter, reserved-field, and local-use fixtures without a
source change.

The public prompt adds one sentence making the valid block-end option-list
rule explicit. This converts the shared L3 failure from a hidden calibration
gate into an ordinary stated requirement. The solution remains:

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 246 | 0 |
| **Total** | **2 files** | **254** | **0** |

The strict non-comment, non-blank count remains 232 additions. Exact
`solution.patch` SHA-256 remains
`33f96aeb379e074cdddd07383acabccd45aa1d16d02ffe65996d036c9c824b4a`.
The 14-case matrix, 31-mutant audit, and raw plus prompt-normalized L3
trajectory replays are recorded in `FALSE_POSITIVE_AUDIT.md`.

## L5 minor-version fairness correction

L5 removes one production check rather than adding scope. The scanner still
requires SHB major version 1 but no longer rejects or normalizes an arbitrary
minor value. This matches bundled LightPcapNg, which stores both fields and
round-trips the minor version without an exclusivity check.

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 245 | 0 |
| **Total** | **2 files** | **253** | **0** |

The strict non-comment, non-blank count is 231 additions. Exact
`solution.patch` SHA-256 is
`3d8245aa3f0e06594d3bf290fcd3f633e97ffe73e17c4ea4555c713d9538b44a`.
The 14-case matrix, audit-only 1.1 compatibility probe, 30-active-mutant
audit, and trajectory replays are recorded in `FALSE_POSITIVE_AUDIT.md`.

## L6 retained-EPB validation order

L6 changes one production decision: an EPB's fixed fields, local interface,
captured/original lengths, and packet-data extent are validated before
filtering, but the option walker runs only when the filter retains that EPB.
This adds one effective source line relative to L5 and restores the prompt's
retained-block validation boundary.

| Language | File | Additions | Deletions |
|---|---|---:|---:|
| C++ header | `Pcap++/header/PcapFileDevice.h` | 8 | 0 |
| C++ source | `Pcap++/src/PcapFileDevice.cpp` | 246 | 0 |
| **Total** | **2 files** | **254** | **0** |

The strict non-comment, non-blank count is 232 additions. Exact
`solution.patch` SHA-256 is
`1f228c09ddab23d64d57791964c8f33008565560cc84fc56e686b4cf3ab514bf`.
The 16-case matrix, 33-active-mutant audit, and ten exact L5-to-L6 replays are
recorded in `FALSE_POSITIVE_AUDIT.md`.
