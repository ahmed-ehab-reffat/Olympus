# SQLSync observed mutation progress - disposable prototype

Date: 2026-08-01

Upstream pin: `7dc1af6b082023982fd2697f913f5b27453747f1`

Purpose: validate that the redesigned feature has a complete repository-native
implementation path and a deterministic offline oracle. This disposable patch
is evidence, not the canonical reference solution.

## Cheapest complete architecture tried

1. Return the appended timeline LSN from the existing mutation path and pair it
   with the local timeline ID.
2. Derive a retained-prefix-aware watermark from `LsnRange::next()`.
3. Retain the latest destination `Range` processed by the existing replication
   protocol and expose its watermark as `received`.
4. Read the local replicated `__sqlsync_timelines` row for the timeline's
   observed `applied` value.
5. Combine these values in a `SyncState` and classify timeline-bound receipts.
6. Carry the receipt and snapshot through existing Wasm request/reply messages.
7. Return the receipt from TypeScript `mutate` and add a TypeScript `syncState`
   request. Represent LSNs as decimal strings.

No new wire message, coordinator RPC, waiting primitive, persistence format, or
connection-status variant was needed.

## Changed prototype seams

| Seam | Disposable change |
|---|---|
| `lib/sqlsync/src/timeline.rs` | Mutation append returns the allocated LSN; applied LSN is read from the existing table. |
| `lib/sqlsync/src/lsn.rs` | Watermark preserves progress for empty-following ranges. |
| `lib/sqlsync/src/replication.rs` | Sender records the latest destination acknowledgement. |
| `lib/sqlsync/src/local.rs` | Mutation returns a receipt; snapshot combines local/received/applied observations. |
| `lib/sqlsync/src/sync.rs` | Receipt, snapshot, and classification types. |
| Wasm `api.rs`, `doc_task.rs`, `net.rs` | Public request/replies and retained observation cross the worker. |
| TypeScript `sqlsync.ts`, `index.ts` | Receipt-returning mutation, snapshot request, and exported types. |
| `end-to-end-local.rs` | Stage-order assertions using the real coordinator loop. |

## Behavioral probes

- `LsnRange::Empty { nextlsn: 11 }` reports watermark 10.
- A sender remains unreceived after frame emission and advances only after it
  processes the destination's range acknowledgement.
- A receipt from another timeline and a future receipt remain unrelated.
- Applied classification wins when an older received observation lags it.
- The local replication example observes one receipt as local, then received
  after upload, then applied only after coordinator step, storage return, and
  rebase.
- The generated declaration contains `type Lsn = string` and uses it for every
  receipt/snapshot LSN.

## Diff measurements

```text
12 files changed, 340 insertions(+), 15 deletions(-)
```

The full disposable diff SHA-256 is:

```text
4da4c422692d52b7ebfef933204ed58332ca3195ad0036147481173cda52f83b
```

A simple effective-additions counter over the production-file set returned
211, but Rust tests embedded in those files are included. This is intentionally
not reported as strict solver production LOC. The reference architecture and
its physical size have low forecasting weight until independent legitimate
solver trajectories exist.

`git diff --check` passed.

## Official-base environment

Base manifest digest:

```text
public.ecr.aws/d3j8x8q7/olympus-base-rust@sha256:211a2e3aeff24b410f2c982723e9314992833f4633c764217eab87552f1d1477
```

Pinned additions:

- Rust 1.91.1 plus `clippy`, `rustfmt`, and `wasm32-unknown-unknown`;
- Just 1.43.1;
- wasm-pack 0.13.1;
- pnpm 9.15.9;
- Node, Clang, and `pkg-config`.

Both committed dependency locks were used. Dependencies and tools were warmed
before the network-disabled verification.

## Results

| Revision | Command family | Result |
|---|---|---|
| Pristine | `just build`; `just test`; `just package-sqlsync-worker dev` | Pass; core 18/18, workspace/doc/examples and worker package pass |
| Pristine, network disabled | Same intended lane plus locked offline core test | Pass |
| Prototype | `just build`; `just lint`; `just test`; worker package | Pass; core 23/23 and both end-to-end examples pass |
| Prototype, network disabled | Lint, full tests, worker package, explicit locked offline core test | Pass; final replay exit 0 on 2026-08-01 |

Image identifiers:

```text
pristine amd64  sha256:2fc815b31d6844b4e86c4754b41474c900b92b702497e123abe2b7e9414d882f
prototype amd64 sha256:ebde326464493ec888650839b23a3253c5854c9b90745c478d8966f5d53106a2
```

## Reproducibility findings

The repository's current pnpm lock was regenerated for pnpm 9, while one
upstream workflow still sets pnpm 8. The old version fails frozen-lock install;
the prototype does not regenerate or replace the lock and instead pins pnpm
9.15.9.

On an ARM64 host, the official image's native compile reaches a pre-existing
`sqlite-vfs` signed-`i8` versus ARM `c_char`/`u8` error. A forced x86_64 build,
matching upstream GitHub-hosted CI, passes. Keep the evaluation platform
explicit rather than hiding this portability issue.

The first prototype overlay reused a cached pristine `sqlsync` test executable
and displayed 18 tests. Adding `cargo clean -p sqlsync` before overlay
validation forced recompilation. Every cited prototype result comes from the
corrected 23-test run.

## Verdict

**Pass and escalated.** The three progress meanings are observably distinct,
the public bridge is feasible and lossless, no private architecture is needed,
and the complete offline lane passes. The resulting version 37 was accepted on
2026-08-07; use `SUMMARY.md` and `DESIGN.md` for the canonical closure record.
The retired planning file is preserved in
`archive/sqlsync-observed-sync-state/retired-authoring.tar.gz`.
