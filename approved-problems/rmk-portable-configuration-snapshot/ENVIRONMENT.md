# Environment

- Repository: `rmk-rs/rmk`
- Pin: `c94426a68779e61cecc4380e21e9079e0ef0c2ae`
- Base image: `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest`
- Rust toolchain selector: `1.95.0` (resolves to the base image's native architecture)
- Additional target: `wasm32-unknown-unknown`
- Test runner: `cargo-nextest 0.9.128`
- WASM runner: `wasm-bindgen-test-runner 0.2.126` on Node
- Macro expansion runner: `cargo-expand 1.0.124`
- Additional native package: `libdbus-1-dev=1.14.10-1~deb12u1`
- Base-provided native package: `pkg-config=1.8.1-1`
- Build policy: the fresh pinned checkout contains no lockfile in `rynk`, `rmk`, or `rmk-macro`. During the networked image build, Cargo explicitly generates all three locks, temporarily appends `wasm-bindgen-test=0.3.76` and `serde=1.0.229` to warm the later standalone WASM lane, and uses `--locked` for every fetch and build. The Dockerfile then restores the pristine `rynk-wasm` manifest and regenerates a matching Rynk lock.
- Runtime policy: `test.patch` is injected only after the image has been built. It leaves the Rynk workspace manifests unchanged and adds a randomized standalone WASM workspace with its own committed lock. Every judged Cargo command uses `--locked --offline`; no runtime dependency resolution is required. `test.sh` creates a private temporary runtime root for nextest's store and outer Cargo target, so no judged process writes below the root-owned checkout.
- The standalone WASM workspace carries a second member, `snapshot-alloc-surface-c84e2a`, which depends only on `rynk` with `default-features = false, features = ["alloc"]`. Adding it changes the committed lock by exactly one path-package entry with no checksum, so it needs nothing beyond the dependencies the image already fetches for Rynk. It is built from inside a running test, which nests one Cargo invocation in another; the alloc and WASM builds use separate package-and-process target directories below the system temporary directory, so they neither require checkout ownership nor contend for a build lock. It also depends on `serde` so it can assert `Serialize + DeserializeOwned` for the snapshot types; that adds one line to the committed lock and no download, since `serde` is already in the graph.

Commands:

```sh
./test.sh base
./test.sh new
```

The base lane runs the pre-existing workspace tests. The new lane is a single nextest invocation, so everything it judges lands in one JUnit report.

Two graded tests shell out to the standalone workspace through a shared `run_standalone_cargo` helper. `snapshot_surface_builds_with_alloc_without_std` builds the `alloc`-only surface crate; `snapshot_wasm_client_round_trips_under_node` runs the randomized WASM test under Node through a scripted JavaScript byte link. The WASM test first probes for the wasm32 target, `wasm-bindgen-test-runner` and `node`, and stands down with a message rather than failing if the host lacks them; the image provisions all three, confirmed as `node v24.15.0`, the runner in `/opt/cargo/bin`, and a `wasm32-unknown-unknown` libdir under the 1.95.0 toolchain. Neither is a shell step in `test.sh`, deliberately: a shell step reports only through the exit status and never reaches the merged JUnit, which left the alloc check in neither the regression nor the new-test set, and later had the WASM case reported as an expected-but-missing testcase. If no native JUnit exists, new-mode exit 101 is the expected pre-solution compilation state and emits one skipped `new.compile-placeholder` while preserving the nonzero process status. Every other nonzero result emits one errored `harness-startup`; base-mode exit 101 is not skipped. The surface check must still be a separate crate, because rynk's dev-dependencies re-enable `std` through feature unification and an example or integration test would link a `std`-gated API successfully.

The dependency-complete base layers were built from an exact fresh checkout. Version 55 applies the Dockerfile's final read/search normalization to those validated layers. Version 56 leaves the Dockerfile unchanged and was exercised after exact patch injection, with networking disabled as UID/GID 42424, on both accepted manifest architectures. Rust 1.95.0 resolves to `1.95.0-x86_64-unknown-linux-gnu` on amd64 and `1.95.0-aarch64-unknown-linux-gnu` on arm64.

The repository intentionally has no top-level `Cargo.toml`, so a root `cargo build` is not a valid repository command. The relevant standalone checks are `cargo build --manifest-path rmk/Cargo.toml --no-default-features --locked --offline`, `cargo build --manifest-path rmk-macro/Cargo.toml --locked --offline`, and `cargo test --manifest-path rmk-macro/Cargo.toml --features _simulator --locked --offline`. Version 17 caches `display-interface`, `macrotest`, and both complete graphs, and installs the `cargo expand` subcommand required by the proc-macro test.

The retained dependency-complete images are `olympus-rmk-snapshot:review-v56-arm64-pristine` and `olympus-rmk-snapshot:review-v56-amd64-pristine`, image IDs `579d46793de0` and `fee93d423543`. Because the Dockerfile did not change, these are version-56 tags on the validated version-55 arbitrary-UID layers. They preserve the expensive networked setup needed for offline reference verification without rebuilding from scratch. No combined solution image is retained.

Inside those images `/app` is a git worktree whose gitdir points at a host path that does not exist in the container, so `rm -f /app/.git` and `git apply --no-index` are needed before patching, and `cargo` must be reached through `/opt/cargo/bin`.

Image size, measured on the arm64 image: about 12.2 GB total, of which `/app` holds 5.3 GB of Cargo target directories (1.7 GB of that incremental caches a fresh container cannot use), `/opt/rustup` 1.4 GB and `/opt/cargo` 1.3 GB. The registry cache is what makes the offline lanes work; the target directories only save build time. Deleting all three target directories and running the base lane cold recompiles 272 crates in 27 seconds. Discarding them in the layer that builds them would take the image to roughly 7 GB, which is worth considering if the platform reports another `EnvironmentStartTimeoutError`.
