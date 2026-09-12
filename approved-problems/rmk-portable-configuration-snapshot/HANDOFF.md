# Handoff — RMK portable configuration snapshot

## Current state

The behavioral problem is **version 56**, accepted on 2026-08-05. Acceptance
is a user-confirmed platform outcome. The exact accepted artifacts are frozen
at the hashes below. Version 56 was reference-verified but had no fresh solver
batch, so its local calibration record remains 0/10; the exact-version false-
positive audit was intentionally skipped at the user's request. Do not describe
acceptance as a local audit approval or invent a solve-rate measurement.

Raw run evidence has moved to
`archive/rmk-portable-configuration-snapshot/agent-runs.tar.gz`; use `RUNS.md`
for the compact index and the archive manifest for recovery.

Read two sections of `DESIGN.md` before doing anything, in this order:

1. "Why the rate moved: the lever was a clue, not a difficulty" - the version-50
   diagnosis. It explains why the previous lever died and is the reason version
   51 exists.
2. "Version 51 design gate" and the sections after it - the current lever, its
   discriminator ledger, its reviews, the version-52 codec-freedom repair, and
   the version-53 testcase-identity repair, the version-54 native-derived WASM
   malformed-input repair, and the version-55 arbitrary-UID offline harness
   repair, followed by the version-56 compile/startup classification repair.

Repository: `rmk-rs/rmk`

Pinned commit: `c94426a68779e61cecc4380e21e9079e0ef0c2ae`

### Measured history

Every rate below is against the version named. A changed artifact abandons its
batch, so none of these carry forward.

| batch | version | rate |
|---|---|---|
| `agent-runs7` | 26 | 0/5, all five failures the harness |
| `agent-runs8` | 31 | 4/5 |
| `agent-runs9` | 36 | 8/10 |
| `agent-runs10` | 38 | 5/10, one failure a harness fault |
| `agent-runs11` | 40 | 5/5 |
| `agent-runs12` | 43 | 3/10 |
| `agent-runs13` | 45 | 3/10, 2/10 once a false positive was closed |
| `agent-runs14` | 49 | duplicate delivery of the `agent-runs15` batch; substantive extracted payload matches after excluding `.DS_Store`, not a second measurement |
| `agent-runs15` | 49 | 9/10 |
| - | 51 | abandoned unmeasured after an unfair decoder assertion was found |
| - | 52 | abandoned unmeasured after the wrapper reported a missing expected testcase |
| - | 53 | abandoned unmeasured after an unfair arbitrary WASM byte literal was found |
| - | 54 | abandoned unmeasured after the arbitrary-UID offline harness blocker was found |
| - | 55 | abandoned unmeasured after the wrapper reported an unclassified startup entity |
| - | 56 | not measured |

The per-version change log lives in `DESIGN.md` and `ERRORS.md`, one gate per
version, with hashes. It is not repeated here.

## Mandatory operating constraints

- Never run a cold solver unless the user explicitly asks for one.
- Do not run the false-positive audit/checks unless the user reverses the current instruction.
- Before any further problem redesign, discriminator selection, or hidden-test edit, reread workspace-root `PROBLEM_DESIGN.md` and complete/record its trajectory gate in `DESIGN.md` before changing `test.patch`.
- Before advising on calibration runs, reread workspace-root `CALIBRATION_STRATEGY.md`.
- Any artifact change creates a new immutable version and leaves calibration at 0/10.
- Preserve unrelated dirty-worktree files.
- Any completion after workspace edits must literally say `I changed` and list every changed path relative to the workspace root.

## Canonical submission-field mapping

Paste each artifact into its matching platform field. Do not swap the two patches.

| Platform field | Canonical workspace file | SHA-256 |
|---|---|---|
| Problem description | `problems/rmk-portable-configuration-snapshot/meta.md` | `bba03fcbb15d7f2194834a0e3e62e86f06db43d473c6c976faa65fb51116f63b` |
| Test patch | `problems/rmk-portable-configuration-snapshot/test.patch` | `21f7cbaea27cee217f6a940e7628b9f0447f3e5ba9381bfcf46256c5ac59cae0` |
| Solution patch | `problems/rmk-portable-configuration-snapshot/solution.patch` | `7f443935c8abecf9d695704d58f13128874679236e455c6a70ac7b7f05a2e7dd` |
| Dockerfile | `problems/rmk-portable-configuration-snapshot/Dockerfile` | `843abae0f216afdeee6bda1d0f53e02f1ed68231202df7fb96bec5bebd1d7be0` |

The test patch contains exactly these paths:

- `.olympus-nextest.toml`
- `.olympus_wasm_c84e2a/Cargo.lock`
- `.olympus_wasm_c84e2a/Cargo.toml`
- `.olympus_wasm_c84e2a/alloc_surface_c84e2a/Cargo.toml`
- `.olympus_wasm_c84e2a/alloc_surface_c84e2a/src/lib.rs`
- `.olympus_wasm_c84e2a/src/lib.rs`
- `.olympus_wasm_c84e2a/src/snapshot_runtime_c84e2a_test.rs`
- `rynk/Cargo.toml`
- `rynk/src/driver/tests.rs`
- `test.sh`

Its `test.sh` is a new mode-100755 repository-root file supporting `base`,
`new`, and `--output_path`. It installs no packages. The patch contains no
snapshot production implementation.

The solution patch contains exactly these three production paths:

- `rynk/rynk-wasm/src/client.rs`
- `rynk/src/lib.rs`
- `rynk/src/snapshot.rs`

`rynk/src/api.rs` was in this patch until version 51, widening `split_pages` to
`pub(crate)`. The version-51 planner has to bridge matching entries, which
`split_pages` cannot express, so it measures its own runs and the file left the
patch. Do not add it back without a caller.

If a reviewer says the test patch contains those three production paths and
lacks `test.sh`, the platform received `solution.patch` in the test-patch field.
Do not rename `rynk/src/snapshot.rs`; it is a production module, not a
predictable hidden-test filename.

## Current public difficulty boundary

Version 56 is Level 6: planned restore, without a bulk requirement, with
canonical bytes across the protocol's own equality, and the fewest write
requests the target's geometry and frame allow.

- A target is compatible when no geometry dimension is smaller than the
  snapshot's. Shrinkage in any of the ten dimensions is still rejected.
- Comparisons and write addresses use the target's coordinates, so a target
  with extra rows, columns, or encoders relocates every entry. Slots the
  snapshot does not reach keep their existing values.
- Request shape is where the difficulty now lives, and it is fully stated in
  the description. Restore spends the fewest write requests it can. A bulk
  request is one contiguous run in the target's coordinates; it may carry
  entries that already match in order to bridge two that differ; it never spans
  a slot the snapshot does not reach; it never begins or ends on a matching
  entry; it must fit the frame. Without a bulk endpoint, or against a target
  without bulk transfer, only differing entries go out, one at a time. The
  optimum is unique: reachable slots split the target index space into
  independent segments, and within a segment greedy extension from the leftmost
  differing entry, then trimming to the last differing entry covered, is optimal
  by the standard exchange argument. Never reintroduce a write-side
  `max_bulk_keys` or `max_bulk_items` cap: that limit is documented for reads
  only, the crate's own `split_pages` sizes writes by payload budget, and the
  cap cost three `agent-runs7` runs seven tests each.
- Every request restore will issue must be encodable within the target's
  advertised frame, and the host must establish that before sending anything.
  `split_pages` and `send_frame` both reject an oversized request locally, so
  the shortfall needs no device to detect. This is the version-32 lever and the
  only thing separating a planning restore from the streamed architecture all
  ten saved implementations use. It covers single-entry writes too, not just
  paged ones: `send_frame` enforces the budget for every request. The test runs
  two budgets against `multi_stage_snapshot_fixture`, whose request sizes are
  keymap page 6, encoder 5, Morse page 7, combo page 9 and fork 15, so 8 stops a
  paged stage and 12 stops the single-entry fork write. A second pair of budgets
  decides bridging rather than fitting: a three-key keymap page is 10 bytes and
  a one-key page 6, so at 10 one request replaces two and at 9 the only legal
  plan is two single-key requests. Re-measure all of these before touching that
  fixture.
- Everything from Level 3 is retained: item-sparse writes, chunk-sparse macros
  on the target's grid with a short final chunk, complete validated baseline
  before mutation, preflight failure on a structurally invalid baseline, all
  eight first-request write-failure stages, second-request failure for the three
  per-entry stages, a partly written paged stage on a grown target, and retry
  that replans from a fresh baseline rather than rewriting applied entries.

Concurrency inside a stage is deliberately unconstrained. A write failure is
judged by two things only: the rejected request was reached, and no later stage
ran. Never assert an exact count of same-stage requests: `write_all` builds
`MAX_IN_FLIGHT` lanes and joins them, so a second disjoint page may legitimately
be in flight when the first rejection arrives.

Request order inside a stage is deliberately unconstrained. Writes in a stage
address disjoint entries and `write_all` dispatches pages concurrently, so every
per-stage comparison goes through `touched`, which sorts first. Never assert a
raw sequence there; stage order is separate and stays exact.

The serde bound covers `ConfigurationSnapshot` only, because that is all the
task requires. Do not extend it to `SnapshotGeometry`.

The WASM test calls both snapshot methods through `Reflect` and a JS `Function`,
never the Rust methods directly. wasm-bindgen surfaces a Rust `Vec<u8>` and a
`js_sys::Uint8Array` as the same JavaScript typed array, so calling into Rust
would pin a representation the task never states; that cost `agent-runs10` a run.
Keep both halves going through JS.

Test scaffolding must not impose traits the task does not name. The suite
requires only `Serialize`, `Deserialize` and `PartialEq` on
`ConfigurationSnapshot`, and nothing on `SnapshotGeometry`. That is checked,
not assumed: stripping `Debug` from the reference's derive leaves the suite
compiling, and it is worth re-running after adding any assertion that formats
a whole record. To keep it that way: build a second
fixture from `snapshot_fixture` rather than cloning, and borrow
`&snapshot.geometry` rather than moving it. Stripping `Clone` and `Copy` from
the reference must leave errors only in `rynk/src/snapshot.rs`, never in
`rynk/src/driver/tests.rs`; that is the check to re-run after touching setup.

A stated rule gets satisfied, and a hidden clue gets found once the description
is clear enough. Difficulty that survives review has to be in the work, not in
what the description leaves out. Test every new lever against that.

Do not feed `from_bytes` bytes emitted by a serializer the implementation did
not choose. Rejection-only is still codec-coupled: a permitted decoder may
consume those foreign bytes as an alternate encoding of a valid snapshot. The
version-54 suite keeps only implementation-native round-trip and trailing-input
checks plus codec-independent `validate` and `to_bytes` rejection checks. There
is no documented envelope from which to construct codec-neutral invalid bytes.
The later version-56 coverage review reached the same conclusion after also
rejecting a conditional native-byte mutation sweep: it would not guarantee a
semantic-invalid decode for every legal codec and would be selected around the
postcard reference mutant. This is an accepted observability gap, not an open
request to restore the foreign-byte assertions.
Keep the historical function name
`snapshot_decoder_rejects_trailing_bytes_and_unknown_versions`: the official
wrapper registers that testcase identity, even though the unfair decoder cases
inside it are gone. The WASM runtime test follows the same rule: it appends a
byte to that implementation's exported snapshot and never assigns invalidity to
an arbitrary literal.

Whole-snapshot comparisons stay whole, and use `assert!(a == b, "message")`,
never `assert_eq!`. Comparing field by field would let a field added to the
record but forgotten in an assertion stop being checked. `Eq` is deliberately
not required, and the description asks for `PartialEq` alone.
Two reviews pull opposite ways here: one called the unstated `Debug` and
`PartialEq` requirement an unfair compile-time condition, the other called
stating both checklist filler. `assert_eq!` needs `Debug` only to format a
failure, so comparing with `==` keeps the whole-record check, which is what stops
a newly added field escaping notice, while the description need only ask for
`PartialEq`. Do not convert them back, and do not drop `PartialEq` from the
description.

Items the task only requires to exist are named by import under
`#[allow(unused_imports)]`, never as a type expression. `Option<SnapshotRead>`
looks shape-free but demands the item be nongeneric and lifetime-free, which the
task never says. An import still fails when the item is missing, which is the
whole job. `RestoreStage::Keymap` and friends stay as value expressions, because
the task lists those eight variants by name.

Reads are deliberately unconstrained. Per-entry and bulk reads are folded to one
phase per resource before any assertion, and every rejecting-preflight test runs
against the stateful peer, which answers every read, asserting only that no
setter was sent. An implementation may therefore do any amount of read-only work,
in any order, before deciding to reject. Tests do not require private helpers, rollback,
transactions, post-write verification, or a baseline read order. They do require
the write plan of version 51's lever, which is a separate matter from reads: the
fewest write requests, run boundaries at reachable slots, differing entries at
both ends, and every request inside the frame. Encoders and
forks have no bulk endpoint and carry no grouping requirement.

Retry coverage has to include the default layer, not just the stages that send
several requests. In those the first attempt fails before behaviour is reached, so
behaviour is only ever written on the retry; a failure at the default layer is
the only case where the whole configuration has already landed and only the last
write is missing, which is where an implementation reusing the previous diff
resends everything.

The peer records `key_requests`, `combo_requests` and `morse_requests` as
`(first index, entry count)` for every write on a paged resource. That ledger is
what the version-51 lever is checked through, and every comparison of it goes
through `touched`. Asserting a raw sequence is unfair here: the repository
documents `write_all_keymap` as concurrent paged writes, so which request lands
first is the implementation's choice. A reference mutated to send the same
minimal plan back to front must pass the whole suite; re-run that check after
touching any request assertion.

Answer a description-density finding by deleting words, never clauses. Twice a
condensing pass has removed a rule: version 31 lost the unsupported-version
sentence, and version 51 lost "skipped stages are absent", which a later review
correctly reported as an unfair test because the suite still required it. A
clause that looks redundant beside its neighbour usually covers an adjacent
case. Before cutting one, find the assertion that depends on it and mutate the
behaviour away; if a test uniquely fails, the clause is load-bearing.

The equality clause deliberately says the Morse map is "one such case, and not
the only one". Keep that warning: naming the other case would hand over the
canonicalization lever, and dropping the warning entirely would make it
undiscoverable.

A no-mutation assertion means nothing against a board that already matches the
snapshot, because nothing would be written either way. Build those boards with
`dirty_restore_state`. The late-read test made that mistake and looked sound for
several versions.

Every peer state is built through `blank_target_state`; adding a field to
`StatefulSnapshotState` should mean editing one place, not five.

Frame-fit is scoped to the writes a restore actually needs, so it must be
measured after the diff, never over the whole record. A board that already holds
an entry too large to write in one frame still restores successfully, writing
nothing. `snapshot_restore_skips_entries_too_large_to_write_when_they_already_match`
pairs the frame that stops a fork write with an identical board; it exists
because an implementation that sized before diffing passed everything else.

The WASM test restores a record that differs from the board and asserts a write
carrying the changed action was sent. It separately appends one byte to the
board's implementation-native export and requires rejection under the public
whole-input rule. Never replace that construction with arbitrary "junk" bytes:
the encoding is participant-chosen. The changed-record case is still needed
because restoring a board's own unmodified snapshot asks for no writes, so an
earlier form passed a wrapper that ignored its argument.

The two out-of-process checks each get their own `CARGO_TARGET_DIR` below the
system temporary directory, keyed by package and process, and share a nextest
test group capped at one thread. Never put those targets beside the injected
manifest under `/app`: evaluation uses an arbitrary unprivileged UID. Without
the separate targets and serialization, the checks contend on the
standalone workspace's package-cache and artifact-directory locks; that cost one
`agent-runs12` build 3m36s and fills the log with "Blocking waiting" lines that
look exactly like a harness fault when reading a failure. Keep them separated.

Both out-of-process checks are ordinary tests in the graded set, sharing
`run_standalone_cargo`: `snapshot_surface_builds_with_alloc_without_std` builds
the `alloc`-only surface crate, and `snapshot_wasm_client_round_trips_under_node`
runs the WASM round trip under Node. Neither may go back into `test.sh` as a
shell step. A shell step reports only through the exit status, so its result
never reaches the merged JUnit: that left the alloc check unclassifiable before
version 27 and the WASM case reported as an expected-but-missing testcase before
version 29. The surface crate discards results rather than annotating them, so
it must never be tightened to pin return or error types.

The outer runner is equally ownership-independent. `test.sh` creates a private
runtime root with `mktemp`, injects its absolute nextest store into a temporary
copy of `.olympus-nextest.toml`, and passes a Cargo target below that root. Do
not move either path back below `/app/rynk/target`. The image's last build step
must remain after every fetch and install and grant `a+rX` to `/opt/cargo` and
`/opt/rustup`; Cargo preserves mode 0640 on at least one cached crate source.
If nextest exits before producing its own report, new-mode exit 101 is the one
expected pre-solution case: preserve the nonzero status and emit one skipped
`new.compile-placeholder`. Every other nonzero result must emit one errored
`harness-startup`; never broaden the exit-101 exception to base mode.

`missing_wasm_tooling` lets the round trip stand down when the wasm32 target,
`wasm-bindgen-test-runner`, or `node` is absent, so a foreign host cannot fail a
solution for its own tooling. It inspects availability only, never the round
trip's outcome, so it cannot mask a real failure. The image provisions all
three; a run that skips there means the image regressed.

The description deliberately does not say `RestoreError` has exactly two cases.
Extra variants are allowed; what is required is that every rejection before the
first write arrives as `Preflight`. Do not reintroduce the exclusivity claim.

Reviews have twice challenged how `Preflight` is matched, in opposite
directions, so read this before touching it. `RestoreError::Preflight { .. }` is
Rust's struct-pattern form and the language applies it to tuple variants too,
whose fields are the positional names `0`, `1`, and so on. It therefore accepts
`Preflight(SnapshotError)` and `Preflight { source }` alike. `Preflight(_)` does
not: that form rejects a struct variant, which is what stopped `agent-runs7`'s
run 5 from compiling. Never go back to it. All nine sites route through
`rejected_before_writing`, and the graded test
`snapshot_preflight_pattern_matches_either_variant_shape` declares both shapes
locally and proves the pattern accepts each.

The description no longer names an encoding, and no test assumes one. The
reference still uses postcard by choice. Do not reintroduce a codec mandate, and
do not hand-encode snapshot bytes in a test: the unknown-version check works
through `validate` and `to_bytes` refusing to emit one.

## Verification already completed

All of the following is against version 56's exact artifacts and runs with
networking disabled as UID/GID 42424.

- Focused native reference lane: 41/41 on arm64 and 41/41 on amd64. The suite
  declares 43 snapshot tests; `test.sh`'s `-E` filter grades 41 of them.
- Pre-existing Rynk regression suite: 83/83 on arm64 and amd64, with the test
  patch alone applied.
- Both patches apply cleanly and in order to a pristine pinned checkout on both
  architectures, and produce `test.sh` at mode 755.
- Description length: 499 words, pure ASCII.
- The version-51 foreign-postcard decoder assertion and version-53 arbitrary
  WASM literal are gone. Both generated
  JUnit reports contain the wrapper's expected historical decoder testcase
  identity; the renamed version-52 identity is retired.
- A forced pre-collection failure with Cargo absent exits 127 and produces a
  fallback JUnit report with one error and no skipped testcase.
- The exact test-patch-only `new` lane reaches rustc, exits 101, and produces
  one skipped `new.compile-placeholder` with no failure or error. This keeps
  the expected pre-solution entity out of both wrapper censuses without hiding
  the nonzero process status.
- No false-positive audit, mutation check, survivor probe, solver replay, cold
  solver or calibration run was performed for version 56.
- Retained version-51 evidence, not rerun for versions 52 through 56: the run without
  `solution.patch` produced only the skipped compile placeholder, and six
  reference mutants were killed, with three tests killing one uniquely:

  | mutant | tests failed |
  |---|---|
  | never bridge a matching entry | 5 |
  | bridge but do not trim to the last differing entry | 4, uniquely `snapshot_restore_ends_every_request_on_a_differing_entry` |
  | treat every reachable slot as one run, ignoring the gaps | 3, including `snapshot_restore_retry_resumes_a_paged_stage_left_partly_written` |
  | bridge without checking the frame | 1, uniquely `snapshot_restore_bridges_a_matching_entry_only_when_the_frame_allows` |
  | send matching entries on the no-bulk path | 1, uniquely `snapshot_restores_to_a_device_without_bulk_transfer` |
  | list a no-op stage in `completed` | 1, uniquely `restore_reports_completed_dirty_stages_when_equal_stages_are_skipped` |

- A legal variant, the same minimal plan sent back to front, passes the whole
  suite. That is the evidence that no assertion pins within-stage request order.
- Replaying all ten `agent-runs15` implementations against version 50 left the
  rate unchanged at 9/10, which is why version 51 exists. They have **not** been
  replayed against versions 51 through 56; replay can only put a floor under a
  newly stated rule, never forecast a rate.

Working trees, preserved for the next iteration:

- `/private/tmp/rmk-v18-test` — the ten test-patch paths.
- `/private/tmp/rmk-v21-solution` — the three production paths (its own
  `rynk/src/driver/tests.rs` is stale; the allowlist excludes it).
- `/private/tmp/rmk-v25-work` — combined tree for fast local iteration. Local
  `cargo` builds and runs the native lane; the local pinned toolchain has no
  `wasm32` target and no cached `console_log`, so the WASM and nextest lanes
  must be verified in Docker.

The retained dependency-complete images are two, tagged once per version.
Versions through 54 use arm64 image ID `79e7204492d3` and amd64 image ID
`5ba0f2f239e2`. Version 55 adds only the final permission-normalization layer;
version 56 leaves the Dockerfile unchanged. Its current tags are
`review-v56-arm64-pristine` at `579d46793de0` and
`review-v56-amd64-pristine` at `fee93d423543`. They are crucial offline
bootstrap environments and should not be removed. Retag rather than rebuild
when a future version does not change the Dockerfile.

A Harbor oracle run once failed with `EnvironmentStartTimeoutError` on an
otherwise clean submission: that same run classified 83 pass-to-pass and 30
fail-to-pass tests, exactly matching the two lanes, so the environment did build
and run. If it recurs, the one factor under our control is image size. Measured:
the image is about 12.2 GB, 5.3 GB of it Cargo target directories and 1.7 GB of
that incremental caches a fresh container cannot use, while the registry cache
that makes the offline lanes work is only 1.3 GB. Deleting all three target
directories and running the base lane cold recompiles 272 crates in 27 seconds.
Discarding them in the same layer that builds them would take the image to
roughly 7 GB for about 27 seconds per lane. That needs a networked rebuild and
full re-verification on both architectures, so it is a deliberate step, not a
quick fix.
Inside them `/app` is a git worktree whose gitdir points at a nonexistent host
path, so `rm -f /app/.git` and `git apply --no-index` are needed before
patching, and `cargo` lives at `/opt/cargo/bin`. Temporary verification
containers should be removed after use.

## Next action

Wait for user direction. Version 56 is reference-verified but cannot begin
solver calibration or be declared submission-ready while the exact-version
false-positive audit remains explicitly disabled. Do not run that audit, any
mutants, survivor probes, solver replays, cold solvers or calibration unless the
user changes the restriction. If that happens, reread the applicable workspace
gates first; any artifact edit creates version 57 and resets calibration to
0/10.

The open problem is still difficulty, and version 56 retains version 51's
untested request-planning attempt. The latest change is a wrapper-only
compile/startup classification repair and supplies no solve-rate evidence.

If new substantive feedback arrives, first decide whether it concerns public
behavior, hidden-test fairness, or environment packaging. Update the recorded
gate before changing tests, keep the false-positive and cold-solver
restrictions, run proportionate reference verification only, and refresh every
artifact hash and version-status document after any real artifact change.

### Levers ruled out by evidence, not opinion

- **Write-side page capping** contradicts the repository: `max_bulk_keys` is
  documented for reads only, and it cost three `agent-runs7` runs seven tests
  each.
- **Geometry adaptation** does not discriminate on its own: every run that
  compiled passed the growth test including its coordinate and sentinel
  assertions. It discriminates now only in combination with request planning,
  because the target's gaps segment the index space.
- **Item sparsity and retry semantics** are passed by all ten saved
  implementations.
- **Canonicalization**, the version-41 lever, held 6/10 and 7/10 failures for
  two batches and then failed nobody. It was a hidden clue rather than
  implementation difficulty, and three reviewer-driven clarity edits made it
  findable by every run. Do not rebuild a lever whose difficulty depends on the
  description staying vague; the review process removes vagueness by design.

### The test every new lever has to pass

State every rule of it plainly in the description. If it is still hard, it is
difficulty. If it stops being hard, it was a clue and it will die the same way.
