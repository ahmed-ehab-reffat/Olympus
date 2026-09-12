# Upstream audit

- Audited repository: `seladb/PcapPlusPlus`
- Exact pin: `8ac4366c4184f096973ef4a0ca084559935828d0`
- Audited branch state: `dev` as observed on 2026-08-04
- Relevant files: `Packet++/header/NtpLayer.h`, `Packet++/src/NtpLayer.cpp`, `Tests/Packet++Test/Tests/NtpTests.cpp`, and Packet/Layer resize machinery

The pinned implementation documents NTPv4 extension fields but explicitly
does not support them. `getKeyID()` and `getDigest()` assume authentication
begins immediately after the fixed header, while the generic `Layer` resize
operations already provide both detached and attached storage updates. Existing
NTPv3 and NTPv4 regression cases establish the compatibility baseline.

A current GitHub fork audit enumerated 746 forks and all 2,011 non-default
branch heads. Of the default branches, 398 predate `NtpLayer`; every one of the
348 branches containing it retains the unsupported-authentication diagnostic
and has no matching extension API. Among non-default heads, 596 contain the
NTP implementation; all retain the same unsupported state and none contains
the selected API. Direct raw-file inspection was used rather than relying on
search-engine indexing. Exact-code searches on Sourcegraph and the public web
also found no competing implementation.

The repository has no generated NTP parser or alternate extension-field model
to preserve. The proposed surface follows existing Packet++ record-view and
builder conventions, while the behavior is stated at the wire boundary so an
independent implementation need not use the reference parser structure.
