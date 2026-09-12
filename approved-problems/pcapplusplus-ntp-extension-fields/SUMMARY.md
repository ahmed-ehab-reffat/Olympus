# Summary

Status: **accepted and archived 2026-08-06**.

- Repository: `seladb/PcapPlusPlus`
- Pin: `8ac4366c4184f096973ef4a0ca084559935828d0`
- Production language: C++
- Task type: enhancement
- Estimated level: 8/10

The accepted problem adds opaque NTPv4 extension-field parsing, construction, traversal,
and editing to PcapPlusPlus while preserving supported authentication, NTPv3,
and classifier behavior. The selected design is based on the exact upstream
pin and a direct audit of all visible GitHub fork heads; no existing public
implementation was found.

The final hidden suite contains nineteen behavioral scenarios. The test-only
baseline passes, the test-only focused lane reports nineteen named failures with
no harness errors, and the combined baseline and 19/19 focused lane pass. The
Docker image also passed all 259 pre-existing Packet++ cases when invoked from
the formerly blocked source-directory working path, including `OUILookup`.

The version-1 false-positive audit compiled 33 plausible mutants. Thirty-two
behaviorally distinct mutants failed the new lane; the one survivor changed
only private Crypto-NAK partition state and was equivalent through every
frozen public operation. Version 1 is now historical because its Dockerfile
used a specialized base image that the current submission validator does not
permit.

Version 2 changed only the Dockerfile. It starts with
`FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`, installs CMake, builds at the
exact upstream pin, preserves the expected test-only result, and passes the
combined base and 14-case new lanes.

Later trajectory-informed revisions added explicit owned-copy independence,
parsed-packet editing, an upper non-v4 gate, exact preservation of unaffected
opaque records, and a fairness correction that removed an undocumented public
default-constructor dependency from the ownership test. The allowed Docker base
provides CMake and libpcap, bounds build parallelism, and exposes the OUI fixture
for the documented manual workflow.

Acceptance is a user-confirmed platform outcome. The operator-directed absence
of a new exact-version false-positive audit and cold-solver run remains part of
the historical record rather than being inferred away. Canonical artifacts stay
frozen here; raw solver evidence and cleanup recovery live under
`archive/pcapplusplus-ntp-extension-fields/`.
