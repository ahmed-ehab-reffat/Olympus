# Verification

Build the frozen amd64 image from a pristine checkout at commit
`7dc1af6b082023982fd2697f913f5b27453747f1`:

```sh
docker build --platform linux/amd64 \
  -t olympus-sqlsync-observed-base:v24 \
  -f problems/sqlsync-observed-sync-state/Dockerfile \
  /path/to/pristine/sqlsync
```

Version 37 reuses the version-24 rebuilt image with Node, pnpm, wasm-pack, and
the Wasm Rust target needed by the real generated-worker browser probe. The
inherited base already supplies ca-certificates, curl, Node, and pkg-config;
the Dockerfile pins its only direct apt addition (`clang`), installs the Rust target with an
explicit toolchain-qualified `rustup target add`, builds the locked Rust
workspace, verifies the committed pnpm lock before installation, then
materializes and checks the host `sqlsync` rlib after worker packaging. A
passing focused lane never uses a synthetic facade fallback.

The injected test manifest disables only the empty `sqlsync-wasm` host doctest
harness; that Wasm bridge contains no doctest examples. Plain workspace
`cargo test` continues to run all real unit/integration tests and the remaining
crate doctests without depending on an optionally stale un-hashed rlib.

Run the exact patch-state gates with networking disabled:

```sh
problems/sqlsync-observed-sync-state/verify/gates.sh
```

False-positive mutant and variation runs are disabled by default for this
problem at the operator's direction. Neither `verify/gates.sh` nor the static
artifact audit invokes them. The commands below are retained only for an
explicit future opt-in; version 37 must not be treated as submission-ready
while they remain disabled. Version 37 adds no mutation or variation command.

When `test.sh` receives `--output_path`, it streams the selected lane to the
terminal and captures the same combined command output in the testcase's
`system-out`. XML-invalid control bytes are removed and XML metacharacters are
escaped. The gate matrix checks useful diagnostics in successful base/new
reports, the expected tests-only rejection, and the missing-browser-tools
rejection; the JUnit artifact no longer reduces a failure to only an exit code.

The ordinary combined lane now holds a reconnected socket open before its
first peer range and requires retained acknowledgement knowledge, routes two
real document subscriptions independently, observes no idle host-to-worker
requests over an interval longer than the callback budget. For a coordinator
acknowledgement injected outside the facade, worker-to-host delivery must be
the first bridge activity; an event-triggered follow-up request remains valid.
The same lane rejects JavaScript numbers for small receipt and state LSNs. It
applies and rebases one receipt before allocating the next, proving that an
empty retained prefix continues at the correct LSN and that one snapshot can
report a newer local/received watermark with an older applied watermark. The
browser classifier also rejects a same-timeline receipt while local progress is
absent. Existing carrier-neutral upper-half and `u64::MAX - 1` checks remain.
The Rust status consumer additionally requires receipt 4 to classify as Local
when local is 5, received is 3, and applied is 1, covering the inclusive
Local-only interval without selecting an owned or borrowed receipt signature.
After one of two sync-state listeners unsubscribes, the real browser lane now
performs a successful local mutation and uses the remaining listener's receipt
observation as the causal barrier before checking that the removed listener did
not run. Document isolation and unanswered-reconnect history likewise use
positive delivery barriers; no negative callback assertion uses a 25 ms sleep.
After the surviving listener observes the post-unsubscribe local mutation, the
facade must classify the earlier receipt as Received while Applied is absent.
This is an opaque, unmasked inclusive comparison. Exact `u64::MAX` is not a
valid real-protocol fixture because the pinned range code cannot represent its
exclusive successor; the existing `u64::MAX - 1` endpoint is retained.
The real facade also allocates a later local receipt before acknowledgement and
must classify the earlier receipt as Local, independently exercising the
inclusive Local branch. A reducer-rejected mutation must cross a queued
snapshot barrier without emitting a callback, and the Rust integration proves
that the next successful receipt is the immediate successor of the previous
accepted receipt. Adding a same-document listener delivers exactly one current
snapshot to that listener without notifying an existing listener; removing one
listener likewise cannot notify its peer in the absence of a state change.
For a later real acknowledgement, the first listener removes itself from
inside its callback. The peer must still receive that same snapshot, and a
causally later local mutation must reach only the peer. This exercises stable
in-flight fan-out without selecting a worker subscription representation.
Separately, a disposable third listener is removed while two established
listeners remain active. A public `syncState` request/reply barrier must pass
without either peer receiving a snapshot, proving that ordinary teardown is
not itself a state change without relying on a settling delay or private worker
message.
The listener removed from inside an acknowledgement callback remains silent
through two later real coordinator acknowledgements and the maximum-endpoint
probe, using an active peer's delivery as the causal barrier. In the separate
application flow, a peer removed before coordinator application likewise
remains silent after the active listener and public snapshot observe the
applied transition. This covers local, received, and applied notification
sources without a timing-based negative assertion.
After the final listener leaves, the test scheduler holds the next outer
document work item while two real mutations advance the document. Releasing
the in-flight zero-to-one registration must yield one current initial snapshot,
not a current snapshot followed by buffered superseded progress, and the next
acknowledgement must still be pushed. The probe does not inspect the inner
worker request or reply schema. The Rust integration also replicates an applied
row for one timeline into the same document database with a different active
timeline and requires applied progress to remain absent.
The built React and Solid packages are also executed with deterministic
adapters for their external context/callback primitives. Each public mutation
hook must call the supplied SQLSync facade once with the original document,
document type, and mutation, then resolve to a structured value equal to that
facade call's distinct receipt. The oracle does not require JavaScript object
identity and complements the existing compile-time hook signature checks.
Exact `u64::MAX` is not injected because pinned pre-task range code cannot
represent its successor.

Explicit opt-in command for all nineteen isolated false-positive mutants:

```sh
problems/sqlsync-observed-sync-state/verify/mutations.sh
```

Explicit opt-in command for the eight accepted implementation variations (cloned public values, renamed
inner worker schema, renamed acknowledgement accessor, a core receipt without
`Copy`, a direct Rust sync-state return, facade LSN normalization, and an
inferred framework-hook receipt return, plus renamed private subscription
messages):

```sh
problems/sqlsync-observed-sync-state/verify/mutations.sh --variations
```

Run static metadata, hash, patch-application, and leak checks against the
pristine checkout:

```sh
SQLSYNC_BASE_SOURCE=/path/to/pristine/sqlsync \
  problems/sqlsync-observed-sync-state/verify/audit.sh
```

Override the default image with `SQLSYNC_VERIFY_IMAGE`. Gate, mutation, and
variation logs are written beneath a reported temporary directory. The runner
also accepts one or more case names as trailing arguments.
