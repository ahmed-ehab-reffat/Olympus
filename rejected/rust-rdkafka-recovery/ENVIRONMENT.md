# Environment record - rust-rdkafka recovery investigation

Status: verified on 2026-07-27.

## Repository state

- Checkout: `work/rust-rdkafka-audit/source`
- HEAD: `3f54ff1dabe7eece876b9635e22462b04478a445`
- Commit date: `2026-06-14 16:10:07 +0200`
- Commit subject: `test: converting test suite to TestContainers (#798)`
- Worktree: clean
- librdkafka submodule:
  `e1db7eaa517f0a6438bc846a9c49ede73b9ea211`
- Current upstream `master`: identical to the pinned revision

## Host

- OS: Darwin 24.6.0, arm64
- Rust: `rustc 1.97.1 (8bab26f4f 2026-07-14)`
- Cargo: `cargo 1.97.1 (c980f4866 2026-06-30)`
- Host triple: `aarch64-apple-darwin`
- Docker CLI: `/usr/local/bin/docker`
- CMake: unavailable on the host

The missing host CMake executable means `--features cmake-build` is not a valid
host lane. It does not affect the already-built default locked library lane.

## Focused offline lane

Command:

```text
cargo test --locked --lib
```

Result:

```text
running 18 tests
18 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
finished in 3.29s
```

The test process used the in-process librdkafka MockCluster and no external
Kafka broker.

## Prior official-image evidence

The repository re-audit on 2026-07-26 ran the same 18-test locked library lane
in `rust:1.85-bookworm` after warming dependencies, with container networking
disabled. It passed 18/18, including `mocking::tests::test_mockcluster`.

That result remains applicable because the audit checkout and command are
unchanged. No new submission artifact or source patch was created in this
investigation.

## Integration-suite boundary

The checkout contains 21 integration-related test files. Most use
Testcontainers or an external Kafka service and therefore cannot serve as an
offline challenge lane. They were inspected for repository evidence but were
not made a hidden dependency.

## Environment verdict

The harness is healthy for deterministic focused probes. The investigation was
rejected for novelty, ownership, and honest scope, not for an environment
failure.
