# Environment gate - image-png static Adam7 encoding

Status: `exact-version Phase A and Phase B pass`.

Date: 2026-08-15.

Repository pin: `721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

This record proves pristine environment viability and exact evaluator
composition for the frozen L1 artifacts.

## Immutable artifact version

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `bf10cb00065ca0328f911b62b3f138d9e01e58921406efc642977c9b334dd46f` |
| `test.patch` | `cb5912a5dc5c09c8cd328854b80f1adbec007defa46aafd01418a4356707f689` |
| `solution.patch` | `af00d4c4e798ba3ba07a5244bc787120ff1b0a292bcbc94e73c060d97692582f` |
| `Dockerfile` | `52358a813ace9b8e812cab2831613cbd9fc601265ab205f04b9dcff529e57289` |
| mandatory direct-row replay | `b948f02d7dc07f12e2a466dded73420fceb6c7fe6b842dfe2708e12a38eaa4c1` |

Repository pin:
`721fd56651038c51bb3a6c2eabe9ab11b086db6e`.

## Phase 0 - Dockerfile contract

- First line:
  `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`.
- Only workdir: `WORKDIR /app`.
- Final command: `CMD ["/bin/bash"]`.
- Dockerfile SHA-256:
  `52358a813ace9b8e812cab2831613cbd9fc601265ab205f04b9dcff529e57289`.
- The image performs dependency resolution and compilation during build, not
  tests.

## Phase A - pristine image

- Docker client/server: 29.2.1 / 29.2.1; storage driver `overlayfs`.
- Initial free host space: 65,046,172 KiB, above the 12 GiB gate.
- Approved base digest:
  `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
- Clean no-cache image ID:
  `sha256:e5a49f2465d89161d390ac9e2cd31a68f96c6ee3428d62e576b27c08cb09d650`.
- Toolchain: Rust/Cargo 1.93.1, rustfmt 1.8.0-stable, Clippy 0.1.93.
- Runtime: network disabled, UID/GID 10001, original source files root-owned
  and non-writable, root-owned Cargo/Rustup caches readable.

The upstream library does not commit `Cargo.lock`. The image resolves a lock
and fetches all crates during its network-enabled build. The final arbitrary-UID
lane deliberately omitted that generated lock from its scratch worktree, then
resolved the same dependency graph from the cached index and crates with Cargo
offline. No runtime network access occurred.

The committed text-metadata doctest writes `target/text_chunk.png` relative to
the package root. Running Cargo directly against the root-owned image checkout
therefore fails only that doctest with `PermissionDenied`. The passing lane
keeps `/app` root-owned and copies repository bytes, excluding `.git`, `target`,
and the build-generated lock, into a UID-owned disposable worktree under
`/tmp`; it creates that worktree's `target/` output directory and uses a
separate writable Cargo target directory. This is required harness working data,
not a source mutation or test deselection.

Exact passing command shape:

```sh
docker run --rm --network none --user 10001:10001 \
  olympus-image-png-adam7-phase-a sh -c '
    mkdir /tmp/image-png-source
    tar --exclude=.git --exclude=target --exclude=Cargo.lock \
      -C /app -cf - . | tar -C /tmp/image-png-source -xf -
    mkdir /tmp/image-png-source/target
    cd /tmp/image-png-source
    CARGO_TARGET_DIR=/tmp/image-png-target cargo test --offline
  '
```

Observed result:

- library: 89 passed, 1 ignored;
- integration: 1 + 4 + 3 passed;
- doctests: 8 passed;
- total: **105 passed, 1 ignored**, exit 0.

## Quarantined attempts

1. A draft Dockerfile used `--locked`, but the repository intentionally has no
   committed lockfile. Static inspection stopped the attempt before build.
2. The first clean build used `--all-features`; that activates the documented
   nightly-only `unstable` feature on stable Rust and stopped during compilation.
   No tests ran.
3. The first arbitrary-UID pin check invoked ordinary Git in a root-owned tree
   and hit Git's dubious-ownership guard. The passing diagnostic uses a
   per-command `safe.directory` only for hash verification.
4. A login-shell probe reset the configured toolchain `PATH`; evaluator-style
   non-login execution sees the image environment correctly.
5. Direct and initially staged test runs passed every unit/integration test but
   could not write the doctest output path. The final scratch worktree includes
   a writable `target/` directory and passes the complete suite.

None of these stopped attempts supplies behavioral or difficulty evidence.

## Exact-version Phase A rerun

The final `scripts/environment_gate.sh` run rebuilt the image with `--pull` and
`--no-cache` from a fresh clone of the untouched pin. Host free-space and Docker
preflights passed. The final build resolved the same 102-crate graph, used the
same approved base digest, and exported image manifest list
`sha256:920546d81cd48768e56cdad2a4d7fb67738842a743977be9fafce74826e4dfe4`.

The baseline base lane ran the five genuine upstream groups offline as UID/GID
10001 from a read-only `/workspace` mount. Its underlying results remain 89
library tests passed with one ignored, eight integration tests passed, and
eight doctests passed: **105 passed, 1 ignored**. No runtime dependency
resolution, permission, missing-tool, startup, or JUnit error occurred.

## Phase B - exact evaluator composition

The final gate applies implementation patches before verifier injection and
runs every lane with `--network none`, UID/GID 10001, read-only source, and a
separate writable results mount.

| Composed tree | Base mode | New mode | JUnit |
|---|---:|---:|---|
| pristine + `test.patch` | pass | behavioral fail; independent host census confirms 17/17 testcases fail | real, 5 base identities / 17 feature identities |
| pristine + `solution.patch` + `test.patch` | pass | 17/17 pass | real; feature identities match baseline |
| pristine + mandatory direct-row replay + `test.patch` | pass | 17/17 pass | real |

`test.patch` owns only `test.sh`, `tests/adam7_encoding_support.rs`, and
`tests/run_junit.py`; it does not overlap either implementation's production
files. Three-way application left no unmerged paths. The mandatory replay is
bound by `ENVIRONMENT_REPLAYS.sha256`, so future gate runs cannot silently omit
the materially different one-file architecture. No near or broad solver patch
exists for this new task; the post-gate mutation audit nevertheless compiled
and executed verifier code after 16 representative production changes without
an injection/startup failure.

Phase A: **pass**.  
Phase B: **pass**.

Any change to `meta.md`, `test.patch`, `solution.patch`, the Dockerfile,
harness, repository pin, dependency graph, replay manifest, or injection path
invalidates this verdict and requires a fresh exact gate before downstream
approval or solver work.
