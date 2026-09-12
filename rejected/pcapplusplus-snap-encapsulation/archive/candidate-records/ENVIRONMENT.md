# PcapPlusPlus SNAP candidate environment preflight

Date: 2026-08-06.

Pin: `8ac4366c4184f096973ef4a0ca084559935828d0` (`dev`).

## Recipe

The preflight reused the accepted NTP Dockerfile without modifying it:

`problems/pcapplusplus-ntp-extension-fields/Dockerfile`

That recipe starts from
`public.ecr.aws/d3j8x8q7/olympus-base:latest`, installs `cmake`,
`libpcap-dev`, and `pkg-config`, and vendors Google Benchmark so top-level CMake
does not need the network after image construction.

Build command:

```text
docker build -t olympus-pcapplusplus-snap-audit:baseline \
  -f problems/pcapplusplus-ntp-extension-fields/Dockerfile \
  Work/pcapplusplus-third-problem-audit/source
```

Resulting image identity:

```text
sha256:17f35824fc17d4f6706ad6c1e9a269e8854264d318e0b836a413d4ef6921f9e5
```

Configure and build completed successfully, including the `Packet++Test`
target. CMake reported the exact pinned commit and `dev` branch.

## Offline baseline

Both commands ran with Docker networking disabled:

```text
ctest --test-dir build-ntp-extension-tests --output-on-failure \
  -R '^Packet\+\+Test$'
```

Result: aggregate CTest target 1/1 passed in 3.16 seconds.

```text
cd /app/Tests/Packet++Test
/app/build-ntp-extension-tests/Tests/Packet++Test/Packet++Test
```

Result: 259/259 passed, 0 failed, 0 skipped.

This closes both earlier environment failures: the image contains CMake and
the libpcap development package. The accepted OUI fixture symlink also keeps
the direct test runner independent of the invoking directory.

## Remaining environment work

- Repeat the image build under the eventual immutable problem version.
- Add an arbitrary non-root UID and read-only-checkout/writable-build-root
  harness preflight before test authoring.
- Run focused ASan and UBSan after a prototype exists.
- Remove the disposable local Docker tag after recording this proof.
