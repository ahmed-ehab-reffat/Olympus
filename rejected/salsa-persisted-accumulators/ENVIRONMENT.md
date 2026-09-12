# Environment viability - Salsa persisted accumulator outputs

Status: `pass` for Phase A and Phase B on the immutable artifact version listed
below.

Immutable source: `salsa-rs/salsa` at
`81496d19d42c9d6f4bab876d1f2ac9941ec8992f`.

Submitted environment artifact at this gate: `Dockerfile` with image
`olympus-salsa-persisted-accumulators:phase-a-v5`, image ID
`sha256:19ec4b9adc62fe2632773eebe08caf721208beeaac86d71b9f31c96008d22df2`.
Its base image ID was
`sha256:211a...d1477` as recorded by the local Docker builder. The exact base
reference is `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest`.

The image generates its own `Cargo.lock` only after asserting that the
untouched source context contains none, fetches dependencies while image
networking is available, and sets `CARGO_NET_OFFLINE=true` for runtime. It pins:

- `rustc 1.85.0 (4d91de4e4 2025-02-17)`;
- `cargo 1.85.0 (d73d2caf9 2024-12-31)`; and
- `cargo-nextest 0.9.97 (68a690b80 2025-05-30)`.

Host-volume free space was checked before the exact run. The repository volume
had 62 GiB available at the first check (54 GiB after retained Docker build and
quarantined scratch outputs), enough for a fresh disk-backed Cargo target.

## Quarantined attempts

None of these attempts executed a behavioral test or count as a solution run:

1. `phase-a` built successfully but Git rejected the root-owned checkout as an
   unsafe directory for UID 10001. The image was quarantined and system-level
   trust was limited to `/app`.
2. The next build was stopped when the audit checkout was found to contain a
   task-created ignored `Cargo.lock`. That lock was removed and the Dockerfile
   was changed to reject any lock in the submitted build context before
   generating its image-local lock.
3. `phase-a-v3` started, but a Debian login shell replaced the image `PATH`, so
   UID 10001 could not execute `rustc`. No Cargo command ran. Rust proxies were
   exposed through `/usr/local/bin`.
4. The following image build stopped when `rustup` attempted a post-install
   self-update DNS lookup. Runtime was never reached. Rustup self-update was
   disabled before toolchain installation.
5. `phase-a-v5` passed formatting and both clippy lanes, then nextest tried to
   create its embedded default store at `/app/target/nextest/default` on the
   read-only source tree. No tests ran. The exact harness now supplies a
   temporary nextest config that changes only `store.dir`.
6. The first redirected-store rerun passed formatting and both clippy lanes,
   then its 6 GiB tmpfs filled during test linking. No tests ran. The Cargo
   target and nextest store were moved to a permission-checked disk-backed
   scratch mount while `/app` and the container root remained read-only.
7. The first disk-backed rerun used `nextest --all-targets`. Compilation
   completed, but Salsa's benchmark binary rejects nextest's `--list` argument.
   No tests ran. The corrected lane exactly follows Salsa CI: persistence uses
   `--tests --examples`; macros-only uses `--tests`.

Every affected batch was discarded and the successful verdict below starts
from the first identity and tool check with a fresh scratch directory.

## Phase A exact pass

The successful container was started with `--network none`, `--read-only`,
`--user 10001:10001`, a 256 MiB `/tmp` tmpfs, and a newly created mode-0777
disk-backed scratch mount at `/scratch`. The root-owned source and dependency
cache remained read-only. `CARGO_TARGET_DIR=/scratch/target` and
`CARGO_INCREMENTAL=0` were set. The temporary nextest config contained only:

```toml
[store]
dir = "/scratch/nextest-store"
```

After checking UID, exact Git revision, image-local lockfile, and tool versions,
the following commands all passed offline:

```text
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo clippy --workspace --all-targets --features persistence --locked -- -D warnings
cargo nextest run --workspace --tests --examples --features persistence --no-fail-fast --locked --target-dir /scratch/target --config-file /tmp/nextest.toml
cargo nextest run --workspace --tests --no-fail-fast --no-default-features --features macros --locked --target-dir /scratch/target --config-file /tmp/nextest.toml
cargo test --workspace --doc --features persistence --locked --target-dir /scratch/target
```

Observed discovery and results:

- persistence/default lane: 290 tests across 126 binaries, 290 passed;
- macros-only lane: 19 tests across 124 binaries, 19 passed;
- doctests: no failures (nine repository examples are intentionally ignored).

The complete Phase A lane was repeated after the final hidden-test ordering
change. It again produced 290/290 persistence/default tests, 19/19 macros-only
tests, and passing doctests, with both clippy lanes and formatting clean. Phase
A therefore passes for the untouched pin and current immutable artifact
version.

## Phase B exact pass

Phase B was run with:

```text
scripts/environment_gate.sh \
  --problem problems/salsa-persisted-accumulators \
  --repo Work/salsa-persisted-accumulators-gate
```

The source argument is a complete, non-promisor checkout whose `HEAD` is the
immutable pin and whose `git fsck` is clean. The gate rebuilt the untouched
image from the submitted Dockerfile, then reproduced evaluator composition in
fresh clones with the source injected read-only and execution offline as UID
10001:

| Composition | Existing/base lane | New lane | Verdict |
| --- | ---: | ---: | --- |
| pristine + `test.patch` | 7/7 | 0/1 | expected feature failure |
| pristine + `solution.patch` + `test.patch` | 7/7 | 1/1 | pass |

The pristine new lane reached and failed the real testcase
`persisted_accumulator_fixture_round_trips_without_execution` because the
upstream accumulator macro rejects `persist`; it was not a build, discovery,
permission, or startup failure. The reference ran the same JUnit testcase
identity and passed it. No representative solver patches exist because
calibration has not started, so that optional replay set is empty rather than
silently treated as passing.

The corrected transitive scenario executes before any direct accumulated
lookup. A predecessor Phase B result with the reverse ordering was explicitly
invalidated and is not carried forward.

## Immutable version

The exact submission-artifact hashes for both final gates are:

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `c8471d8bfe9ccb8857fbaf34e98c82ff7a4849bf6923a2a7735077c57dd65180` |
| `test.patch` | `955efec5c24d26c967040847e6d31261db2c8e64e306fdf43135c7e7c2b8a0af` |
| `solution.patch` | `3d241b5ed9c16334474ac02917757a51fc613932130ab62575a6ffe8d8af1201` |
| `Dockerfile` | `ecb18013b3ce715be5e7907ac5736af9f7cd97f5e5b7751a8311d5ab54351f24` |

Any prompt, test, reference, Dockerfile, dependency, repository-pin, harness,
or injection-path change invalidates this verdict and requires both phases to
restart before calibration or approval.
