# ENVIRONMENT - PcapPlusPlus PCAPNG filtered-copy audit

Audit date: 2026-07-30

## Immutable source and eligibility

The clean audit checkout is
`work/pcapplusplus-pcapng-filtered-copy-audit/source` at
`0dbbb9c75eb232135f13fdb794318c4da3270ebc`. The commit is the v26.07
release commit from 2026-07-22. A closeout `git ls-remote --symref origin
HEAD refs/heads/master` returned:

```text
ref: refs/heads/master HEAD
0dbbb9c75eb232135f13fdb794318c4da3270ebc HEAD
0dbbb9c75eb232135f13fdb794318c4da3270ebc refs/heads/master
```

The pin and current default-branch commit are therefore identical. The
official repository snapshot had 3,120 stars, 753 forks, primary language
C++, default branch `master`, `archived=false`, and no Discussions. The
latest release was
[`v26.07`](https://github.com/seladb/PcapPlusPlus/releases/tag/v26.07),
published 2026-07-23. Repository and commit:

- https://github.com/seladb/PcapPlusPlus
- https://github.com/seladb/PcapPlusPlus/commit/0dbbb9c75eb232135f13fdb794318c4da3270ebc

The repository remains comfortably above the Olympus activity and star
thresholds.

## Licenses and supported languages

| Component | License evidence | Audit result |
|---|---|---|
| PcapPlusPlus root and proposed `Pcap++` C++ files | [`LICENSE`](https://github.com/seladb/PcapPlusPlus/blob/0dbbb9c75eb232135f13fdb794318c4da3270ebc/LICENSE), Unlicense | Eligible |
| Bundled LightPcapNg | `3rdParty/LightPcapNg/LICENSE`, MIT | Eligible dependency, but C is not an allowed solution language |
| MemPlumber | `3rdParty/MemPlumber/LICENSE`, MIT | Eligible test/build dependency |
| hash-library | license header, zlib license | Eligible dependency |
| Visual Studio dirent | license header, MIT | Eligible and not used in the Linux lane |
| Audit fixture | generated entirely by `audit/fixture_probe.cpp` written for this audit | Owned; no external capture or license dependency |

The successful prototype changes only the root-Unlicense C++ module. The
smaller existing-LightPcapNg route would require material changes to vendored
C to handle section byte order correctly and is therefore not an eligible
participant solution route. No license is unresolved.

## Official image and installed tools

The exact base and derived image were:

```text
public.ecr.aws/d3j8x8q7/olympus-base-cpp@sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321
pcapplusplus-pcapng-filtered-copy-audit:local
sha256:641a8be029478e128850ae6bf5304b21d2ed3aaf68322b46e123e576a6cc6bc5
```

The disposable derived-image preparation installed only `ca-certificates`,
`iproute2`, `libpcap-dev`, `pkg-config`, `python3-pip`, and pinned
`clang-format==19.1.6`. No Dockerfile is retained. Observed tool versions:

| Tool | Version / package |
|---|---|
| CMake | 4.3.2, supplied by the official base |
| GCC / G++ | 12.2.0; Debian package `4:12.2.0-3` |
| libpcap | 1.10.3; Debian `libpcap-dev` / `libpcap0.8-dev` `1.10.3-1` |
| pkg-config | 1.8.1-1 |
| Python executable | 3.12.13; Debian Python package 3.11.2 also present |
| pip | 23.0.1 |
| clang-format | 19.1.6 |
| iproute2 | 6.1.0-3 |

Both C++ and bundled-dependency C compilation used GCC 12.2.0. Production
C++ compiled as C++14. Zstd was deliberately out of scope and LightPcapNg
configured its Zstd support off. No committed fixture, Git LFS object, or
download was needed at configure, build, or test time.

## Configure, build, and offline verification

The actual Debug configuration was:

```bash
cmake -S . \
  -B build-pcapplusplus-pcapng-filtered-copy-audit-public \
  -DCMAKE_BUILD_TYPE=Debug \
  -DPCAPPP_BUILD_TESTS=ON \
  -DPCAPPP_BUILD_EXAMPLES=OFF \
  -DPCAPPP_BUILD_TUTORIALS=OFF
cmake --build build-pcapplusplus-pcapng-filtered-copy-audit-public --parallel
```

CMake selected the system libpcap and `LIGHT_PCAPNG_ZSTD=OFF`. Configuration
and build succeeded without a network fetch. CMake's Git metadata probe
warned because the detached worktree's `.git` file names a host-absolute path
that is unavailable inside the container; this did not affect source,
configuration, or tests.

Runtime verification used a Docker `--internal` network and therefore had no
external egress. `Pcap++Test` expects a default gateway even in its `-n` lane,
so the container had `NET_ADMIN` and a non-routable local default route through
`172.31.255.1`. This satisfies only the discovery assertion and cannot reach
the Internet. A prior `--network none` run passed file and packet behavior but
failed two live-device discovery assertions; an internal network without the
synthetic route left one default-gateway failure.

The independent exact oracle was:

```bash
./audit/pcapplusplus-pcapng-filtered-copy-public-probe \
  /fixture/pcapplusplus-pcapng-filtered-copy-input.pcapng \
  audit/pcapplusplus-pcapng-filtered-copy-actual.pcapng
/tmp/fixture-probe verify \
  audit/pcapplusplus-pcapng-filtered-copy-actual.pcapng \
  /fixture/pcapplusplus-pcapng-filtered-copy-expected.pcapng
```

It passed, and actual and expected both had SHA-256
`6d3972b7df8ffdd98a3f8858cc69f3cfba7af5436887c06e21fc136e652f2558`.

The requested tag command was run from
`build-pcapplusplus-pcapng-filtered-copy-audit-public/Tests/Pcap++Test`:

```bash
./Pcap++Test -n -t pcapng
```

The harness combines those selectors with OR semantics, so this was not a
PCAPNG-only lane. It reported 113 cases: 71 passed, 0 failed, 42 skipped, in
9.128 seconds.

The complete CTest command was:

```bash
ctest --test-dir build-pcapplusplus-pcapng-filtered-copy-audit-public \
  --output-on-failure
```

It passed 2/2 tests: `Packet++Test` in 2.91 seconds and `Pcap++Test` in
9.22 seconds, total 12.14 seconds. `git diff --check` passed, and the two
production files were formatted with clang-format 19.1.6. Sanitizers were not
run because the mandatory cheapest-complete hard stop had already rejected
the candidate; this is not submission preflight.

## Network boundary

Network was used only to clone/fetch the public repositories, inspect GitHub,
pull the immutable official image, and install pinned image packages before
the test image was frozen. Fixture generation, configure, compile, the exact
oracle, focused replay, and full CTest did not require Internet access.

## Frozen problem-package verification

The retained problem `Dockerfile` now starts with the validator-permitted
`public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`. On 2026-07-30 that tag
resolved to the already audited digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
It built successfully as
`pcapplusplus-pcapng-filtered-copy-problem:latest-base` with image ID
`sha256:d49c554406aeb41f9987c93dfd23637826a4318b31bd54bf32ed8e87a8220d71`.
It installs the audited dependencies and clang-format 19.1.6 and preflights
the upstream `Pcap++Test` target.

All frozen verification runs used `--network none`. The package's base lane
invokes `Pcap++Test -n -s -x live_device`, excluding the two environment-only
live-device inventory assertions while retaining 69 offline cases. Results:

| Patch state | Result |
|---|---|
| Test only, base | 69/69 JUnit pass |
| Test only, new | Nine named JUnit failures, one for every registered `PcapNgCopy.*` entity: documented method absent |
| Solution only | `Packet++Test` 259/259; `Pcap++Test` 69 passed, zero failed, 44 skipped |
| Test plus solution, base | 69/69 JUnit pass |
| Test plus solution, new | 9/9 CTest/JUnit pass |

Test-then-solution and solution-then-test produced identical combined diffs
with SHA-256
`db3330a478c0f034ab0040c571b9d7351bd4c15eafef948107c0b33cfde65263`.
`git diff --check` passed. The exact artifact hashes and mutation audit are in
`FALSE_POSITIVE_AUDIT.md`.

The complete matrix and all 15 compile-valid mutants were rerun after the
harness compatibility re-freeze. The JUnit converter compiled and executed
under `python:3.8-alpine`, producing all six expected named failures for a
simulated build failure without using `ElementTree.indent`. Current evidence
is retained under `verification/harness-compatibility-refreeze/`.

The same patch-state matrix, solution-only regression lanes, and 15-mutant
audit were repeated after the byte-for-byte prompt-only cleanup. Results were
unchanged, and evidence for that predecessor prompt version is retained
under `verification/byte-for-byte-prompt-refreeze/`.

For the L2 multi-interface and option-framing revision, the complete matrix was
recreated in fresh worktrees at the source pin. Builds were deliberately
limited to two parallel jobs; an initial attempt to build three independent
states concurrently exhausted host memory, while every state passed when run
sequentially with the same compiler and flags. This was verification-host
contention, not a package or test failure.

All 21 isolated mutants compiled, were killed by the focused suite, and were
followed by a clean reference rebuild and 9/9 pass. The two local predecessor
patches and the Nova patch were each rebuilt with L2 and produced eight passes
plus the expected `MalformedOptions` failure. The exact converter also
compiled and emitted all nine simulated build-failure cases under the cached
`python:3.8-alpine` image without `ElementTree.indent`. Current evidence is
retained under `verification/l2-interface-option-refreeze/`.

After the prompt-only removal of “with `setFilter()`”, the four patch states,
both combined orders, solution-only regression lanes, Python 3.8 converter,
and all 21 mutants were executed again without network access. Results were
unchanged; the current immutable evidence is under
`verification/current-filter-prompt-refreeze/`.

## L3 option-termination re-freeze

Fresh worktrees at the same source pin accepted all four patch states and
passed `git diff --check`. Test-only/base passed 69/69; test-only/new emitted
all 11 named missing-method failures; combined/base passed 69/69; combined/new
passed 11/11. Both combined application orders were byte-identical at complete
diff SHA-256
`77e0c75abab1b0cc02e773f191087e1af3b8973fb3f6a9698cf4a5819b9f8c3d`.

The solution-only state passed `Packet++Test` 259/259 and `Pcap++Test` 69
passed, zero failed, 44 skipped. The converter compiled and emitted all 11
simulated named build failures under the cached `python:3.8-alpine` image.

All 28 isolated mutants compiled and were killed by the focused suite. After
restoration, the reference rebuilt and passed 11/11. Four legitimate L2
solutions replayed at 1/4: one passed and three failed only
`OptionTermination`. All execution used `--network none`; raw evidence is
under `verification/l3-option-termination-refreeze/`.

## L4 filter/opacity re-freeze

Fresh worktrees at the same source pin accepted test only, solution only, test
then solution, and solution then test. Every state passed `git diff --check`.
Test-only/base passed 69/69; test-only/new emitted all 14 named missing-method
failures; combined/base passed 69/69; and combined/new passed 14/14. Both
combined orders were byte-identical at complete diff SHA-256
`ec0506fb5c0cd5533ed6414b702f1df1dcf3509ff85b6f01d9aae77cd634b9a8`.

The solution-only state passed `Packet++Test` 259/259 and `Pcap++Test` 69
passed, zero failed, 44 skipped. The converter compiled and emitted all 14
simulated named build failures under the cached `python:3.8-alpine` image.

All 31 isolated mutants compiled and were killed by the focused suite. The
three L4 mutants fail only `DefaultAndClearedFilter`, `ReservedFieldOpacity`,
and `LocalUseOpacity`, respectively. After restoration, the reference rebuilt
and passed 14/14. Three completed L3 solutions were replayed raw and after a
one-line prompt normalization; the normalized outcomes are 13/14 on different
tests, 13/14 on a different test, and 14/14. All execution used
`--network none`; raw evidence is under
`verification/l4-filter-opacity-refreeze/`.

## L5 minor-version fairness re-freeze

Fresh worktrees at the same source pin accepted all four patch states and
passed `git diff --check`. Test-only/base passed 69/69; test-only/new emitted
all 14 named missing-method failures; combined/base passed 69/69; and
combined/new passed 14/14. Both combined orders were byte-identical at
complete diff SHA-256
`4f572abf252ecb840e5a1759646b26a9ddab692d4946fb90023ed935e94db666`.

The solution-only state passed `Packet++Test` 259/259 and `Pcap++Test` 69
passed, zero failed, 44 skipped. The converter compiled and emitted all 14
simulated named build failures under `python:3.8-alpine`.

An audit-only fixture changed a valid SHB from 1.0 to 1.1. The corrected
reference rebuilt, accepted and exact-copied it, and was then restored. All 30
active isolated mutants compiled and were killed; the unfair exact-minor
mutant is explicitly retired. The restored reference passed 14/14. All six
raw and prompt-normalized solver replays compiled and retained the L4 split.
All execution used `--network none`; evidence is under
`verification/l5-minor-version-fairness-refreeze/`.

## L6 filter/validation-order re-freeze

Fresh exact states at the same source pin accepted test only, solution only,
test then solution, and solution then test. Every state passed
`git diff --check`; both combined orders are byte-identical at complete diff
SHA-256
`a11d44fbc8e21720c7a0b26f3bdf52107b22c4b1a21dc8e1b9d5fe6fd74621ac`.

Test-only/base passed 69/69 and test-only/new emitted all 16 named
missing-method failures. Combined/base passed 69/69 and combined/new passed
16/16. The complete inventories passed `Packet++Test` 259/259 and
`Pcap++Test` 69 passed, zero failed, 44 skipped. The converter executed under
the cached `python:3.8-alpine` image and emitted all 16 simulated named build
failures.

All 33 active isolated mutants were restored from the exact reference. IDs
1-25 and 27-31 rebuilt and failed as before. The non-const mutant built the
production library and failed to compile the const-call harness; the
same-path-rejection and pre-filter option-validation mutants built and failed
only their intended CTest entities. The restored reference passed 16/16.

All ten L5 solution patches were rebuilt against the exact L6 tests. Nova 6
and 7 pass 16/16; five former passes fail only `DiscardedPacketOptions`; the
three prior failures retain independent DSB/multi-section signatures. Every
run passes `InPlaceReplacement`, whose final DSB-free fixture prevents failure
family coupling. All execution used `--network none`; raw evidence is under
`verification/l6-filter-validation-order-refreeze/`.
