# Repository map

| Path | Role in the problem |
|---|---|
| `Packet++/header/NtpLayer.h` | Public NTP layer, new record view/builder, and layer methods |
| `Packet++/src/NtpLayer.cpp` | Existing authentication logic and reference parsing/editing behavior |
| `Packet++/header/Layer.h` | Borrowed layer data model and resize primitives |
| `Packet++/src/Layer.cpp` | Detached and attached `extendLayer`/`shortenLayer` behavior |
| `Packet++/header/Packet.h` | Packet ownership and enclosing-field recomputation |
| `Packet++/header/UdpLayer.h` | UDP length/checksum contract exercised after attached edits |
| `Packet++/header/IPv4Layer.h` | IPv4 length/checksum contract exercised after attached edits |
| `Tests/Packet++Test/Tests/NtpTests.cpp` | Existing NTPv3/v4 parsing, creation, and authentication regressions |
| `Tests/CMakeLists.txt` | Registration point for the dedicated hidden test target |
| `Tests/NtpExtensionTest/` | Added black-box behavioral test executable and JUnit fallback |
| `test.sh` | Separate base and new grading lanes |

The production change is intentionally limited to `NtpLayer.h` and
`NtpLayer.cpp`. The hidden target links only Packet++ plus the repository's
portable endian helper. It creates wire buffers in memory and does not require
pcap fixtures, live interfaces, external processes, or network access.
