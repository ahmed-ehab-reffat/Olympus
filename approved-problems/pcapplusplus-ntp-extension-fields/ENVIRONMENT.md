# Environment

- Repository: `seladb/PcapPlusPlus`
- Pin: `8ac4366c4184f096973ef4a0ca084559935828d0`
- Base image declaration: `public.ecr.aws/d3j8x8q7/olympus-base:latest`
- Base image resolved during the 2026-08-05 verification:
  `public.ecr.aws/d3j8x8q7/olympus-base@sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`
- Build system: CMake, Debug configuration
- C++ compiler in the allowed base image: GCC 12.2.0
- Added build dependency: CMake 3.25.1, installed by the Dockerfile
- Runtime support already in the base image: Python 3 converts a pre-build
  failure into JUnit
- Network policy: the image build uses the Debian package repositories to
  install CMake; patch injection and test execution then run without network
  access

The image configures with `PCAPPP_BUILD_PCAPPP=OFF`, because this problem is
confined to Packet++ and does not require libpcap-backed devices. It warms the
pre-existing `Packet++Test` target in the same build directory used by the
runner. After `test.patch` is injected, CMake reconfigures that directory and
discovers the separate `NtpExtensionTest` target.

The runner accepts `./test.sh --output_path FILE base` and
`./test.sh --output_path FILE new`. The base lane builds and runs the existing
`Packet++Test` regression executable. The new lane builds the dedicated target
and exposes fourteen independent CTest/JUnit identities. On a pristine source
tree the missing public API causes the new target to fail compilation; the
converter emits all fourteen expected failures rather than losing the graded
test census.

The Dockerfile carried into version 3 starts with the platform-permitted
literal base line.
It built as local image
`sha256:5b274844ecd2b43b4deb7fddf1b60360ac35d90d46f1d613fd5f28eb29e0a343`.
Patch injection into that image passes the ordinary test-only and combined
matrices. Version 3 has not received a new false-positive audit.
