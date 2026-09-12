# False-positive audit — RMK portable configuration snapshot

Status: **historical version-17 audit complete; version-24 audit skipped at the user's request on 2026-08-03**.

Versions 18 through 24 changed the public contract, description, and hidden fixtures,
expanded failure reporting, introduced complete-baseline sparse restore, and
then added item-sparse writes and retry semantics.
The results below therefore do not approve the current artifacts. The
version-24 reference passes the 25-test native lane and runtime WASM lane on
both architectures, plus the 83-test regression lane on arm64. The user asked
to skip the exact-version mutation audit. Version 24 must remain marked
audit-pending until that gate is rerun from the beginning.

Pin: `c94426a68779e61cecc4380e21e9079e0ef0c2ae`

The networked Docker build starts from the exact pinned checkout and generates locks for the otherwise unlocked Rynk, RMK, and `rmk-macro` manifests. Every later fetch and build is locked. The image warms every native and WASM dependency, installs `cargo-expand` 1.0.124, restores the pristine participant-facing `rynk-wasm` manifest, and regenerates a matching Rynk lock. `test.patch` does not mutate a workspace manifest: its runtime WASM probe is a randomized standalone crate with its own committed lock. Every post-build check used `--locked --offline`. No cold solver or calibration run was started.

## Immutable artifact identities

| Artifact | SHA-256 |
|---|---|
| `Dockerfile` | `9c7d6a81f0e0018931f044d7e68b416774f1e21c98bd31d2ea54e3e0437e3338` |
| `meta.md` | `fed074f7107e498cea41d721add2bd3e244ae9eb41d9fe9dc584ab3c837acaba` |
| `test.patch` | `205032cb52b2ea0c0a50af63d22098bdb9d1828c38d17f8a056ce53c3d660735` |
| `solution.patch` | `66a7d2b80b5a6d2b47ae11709745b0b96d2ca2f3d9c0bc0d84b5c77aa1f5b9c7` |
| Standalone WASM test `Cargo.lock` | `68a7b9e034e9c321c93d9964b6e601aae7b0864713825e2b5ce8faf3e38df350` |
| Docker-generated `rynk/Cargo.lock` | `4079ee4f12dc050a959f6f57d9a3ec06928753df50c73602097699443355e777` |
| Docker-generated `rmk/Cargo.lock` | `64ae242b25f19fd8b29298c9ab267e1c3a074608b54836fe139da7c357b292a2` |
| Docker-generated `rmk-macro/Cargo.lock` | `2e2146412ba0fcc0dd4d8eb518c384354cbffd6833b04572dbc364ad8afd365e` |

The fresh-checkout images are `olympus-rmk-snapshot:review-v17-arm64-pristine` (`sha256:79e7204492d32cb7a75e093f14d9394095a96dd673804160df543031317a22ae`) and `olympus-rmk-snapshot:review-v17-amd64-pristine` (`sha256:5ba0f2f239e20daaaccd4d2789174c29b38ac787bd9ae9432fba218ee39cc971`). Their pristine and combined `rynk-wasm/Cargo.toml` hashes are both `90cca65c6ae27c5f543aa09206bb95dfb311c05ce5052ae29b3c5e3969f5ad9d`.

## Requirement map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| Public version, types, fields, and native methods | Native construction/calls plus the standalone dependent crate's `SNAPSHOT_VERSION == 1` and public `SnapshotRead` import |
| Deterministic complete postcard record | `snapshot_bytes_are_deterministic_and_round_trip`, canonical Morse-map insertion-order test, and complete-input rejection |
| Unknown versions fail in every public input mode | Byte decoding and direct `validate`, followed by no-write `preflight_restore` and `restore_configuration` calls on an in-memory unknown-version record |
| Every geometry-sized collection has the exact length | `snapshot_validation_rejects_lengths_and_default_layer`, with separate short and long cases for keymap, encoders, combos, forks, Morses, and macro data |
| Default-layer and nested combo/Morse geometry limits | The same length/default test plus trigger-count, out-of-range optional combo layer, and Morse-pattern cases |
| Complete export and stated read order | Stateful full-family export/restore with distinct values and normalized DeviceInfo → DefaultLayer → Keymap → Encoders → Combos → Forks → Morses → Macros → Behavior phases |
| Capability-driven key, encoder, and macro enumeration | Two-layer/two-encoder stateful peer with one-key pages and a five-byte macro region read in three-byte chunks |
| Complete no-write preflight | Recording peers cover malformed late data, unknown in-memory versions, invalid combo layers, unsupported bulk, zero macro chunk size, and identity mismatch while rejecting every mutation |
| Every structural geometry field must match | Ten independent target sessions perturb layers, rows, columns, encoders, combo slots/key limit, macro extent, Morse slots/pattern limit, and fork slots |
| Same-model portability | Positive preflight changes manufacturer, serial, firmware, payload/page limits, and macro chunk size without changing the three compatibility keys or structural geometry |
| Each identity key is independently required | Separate product-name, vendor-ID-only, and product-ID-only target sessions |
| Ordered non-atomic restore | Stateful final-state and normalized phase checks require every family and default layer last |
| Accurate partial progress and stop-after-failure | Stateful fork rejection checks the completed ledger, failed stage/source, and absence of every later write phase |
| Native/WASM byte parity | Runtime `wasm-bindgen-test` exports through a JavaScript byte link, decodes/re-encodes natively, invokes the exported restore method with `Uint8Array`, and exhausts the peer |

## Fairness and trajectory replay

The stateful peers accept bounded single-item or bulk keymap, combo, and Morse operations and normalize them to their public resource phases. They validate addresses, values, complete final state, and family order without fixing helper paging, overlap, packing, sequence numbers, or write iteration order. Macro writes may use a short final chunk or a full advertised chunk padded beyond the persisted region. Encoder export remains layer-major/encoder-ID-major, but correct restore may visit independent encoder slots in another order.

Three deliberately different legitimate variants pass all 16 native tests and the runtime WASM test: single-item key export and restore, a padded final macro chunk, and encoder-ID-major restore with correct snapshot indexing. The identity-first reference and the prior local-first preflight prototype are also accepted.

Version 16 allowed three of the four newly supplied `agent-runs2` implementations to pass. Inspection of their compact evaluations, production patches, raw trajectories, and representative tool records found the same plausible omission in two successful implementations: both checked combo trigger count but ignored the public optional combo layer. Version 17 states and probes that boundary. Exact version-17 replay results are:

| Saved implementation | Base | Native focused | Runtime WASM | Version-17 outcome |
|---|---:|---:|---:|---|
| `agent-runs2/Nova_Nova_1` | 86/86 | 19/19 | 0/1 | Fails the existing empty-macro/zero-chunk WASM boundary |
| `agent-runs2/Nova_Nova_2` | 87/87 | 18/20 | 1/1 | Fails direct and no-write combo-layer rejection |
| `agent-runs2/Nova_Nova_3` | 86/86 | 17/19 | 1/1 | Fails direct and no-write combo-layer rejection |
| `agent-runs2/Nova_Nova_4` | 87/87 | 20/20 | 1/1 | Passes; its overlapping self-authored hidden-test file was excluded while all production changes were retained |
| `agent-runs1/Nova_Nova_1` | 86/86 | 19/19 | 1/1 | Passes |
| `agent-runs1/Nova_Nova_2` | 86/86 | 19/19 | 1/1 | Passes |
| `agent-runs1/Nova_Nova_3` | 86/86 | 19/19 | 1/1 | Passes |
| `agent-runs1/Nova_Nova_4` | 87/87 | 18/20 | 1/1 | Fails direct and no-write combo-layer rejection |

The higher totals include implementation-authored tests. The fresh four-run replay is reduced from three complete passes to one; across all eight saved patches, four pass and four fail. These are trajectory replays, not a new solver or calibration batch.

The test-only state exits nonzero because the participant API is absent, but its base lane passes 83/83 and its fallback JUnit contains one skipped `new.compile-placeholder`, not an unclassified failed entity.

## Mutation method and results

Each mutation was applied alone to the exact version-17 combined arm64 artifact. The complete 16-test native lane and runtime WASM lane ran after every mutation. All 40 were caught; no mutant survived the focused suite, so none qualified for escalation through the complete pre-existing suite. The complete 83-test suite was nevertheless run in the exact combined, test-only, and solution-only reference states on both architectures.

| ID | Plausible incorrect implementation | Strongest rejection |
|---|---|---|
| M1 | Serialize Morse maps in insertion order | Canonical equivalent-map bytes |
| M2 | Compare product name but ignore both USB IDs | Isolated USB mismatch sessions |
| M3 | Also compare manufacturer label | Portable same-model positive preflight |
| M4 | Skip snapshot validation during target preflight | Malformed late data and in-memory validation failures reach the mutation boundary |
| M5a | Accept zero macro chunk size for nonempty space | Zero-chunk no-write preflight |
| M5b | Accept no whole-resource bulk support | Unsupported-bulk no-write preflight |
| M6 | Skip structural geometry comparison | Geometry no-write preflight |
| M7 | Set default layer before backing resources | Full restore order and WASM restore |
| M8 | Omit fork writes but report Forks complete | Full final state and progress failure |
| M9 | Restore only the first encoder layer | Stateful extent final state |
| M10 | Restore only the first keymap item | Stateful extent final state |
| M11 | Mark Forks complete before its write succeeds | Completed-stage ledger |
| M12 | Omit version validation | Decoder and in-memory validation rejection |
| M13 | Omit Morse per-entry pattern validation | Nested item-limit test |
| M14 | Rename the WASM export | Dependent WASM compilation |
| M15 | Publish version 2 | Exact constant and runtime WASM |
| M16 | Keep `SnapshotRead` private | Dependent-crate public import |
| M17 | Return empty bytes from WASM export | Runtime native decode/parity check |
| M18 | Flatten the second layer into an out-of-range row | Component-wise stateful address bounds |
| M19a–M19f | Omit exact length validation for one of the six collections | Matching short and long collection cases |
| M20a | Accept undersized collections | Short case in every collection family |
| M20b | Accept oversized collections | Long case in every collection family |
| M21 | Reject USB identity only when both VID and PID differ | Vendor-only and product-only sessions |
| M22 | Validate combo trigger count but ignore `Combo.layer` | Direct validation and no-write preflight/restore |
| M23 | Reject unknown versions only while decoding bytes | Direct validation and no-write in-memory restore modes |
| M24a–M24j | Ignore one of the ten structural geometry fields | The matching isolated target-geometry session |

The attempted set totals 40: the version-16 set had 28 independent mutations, M22 and M23 add two invocation/boundary survivors, and M24a–M24j isolate all ten structural fields.

## Rejected probes

Exact helper page scheduling, exact bulk packing, exact final macro frame length, and individual encoder-write order are private transport choices; valid alternatives were prototyped and accepted. Requiring identity I/O before locally detectable preflight failures is also rejected. Dimension-overflow testing remains artificial because the public `u8`/`u16` geometry products cannot overflow `usize` on supported native or WASM targets. Extra identity permutations, a failure fixture at every restore stage, private error labels, rollback, timing, and firmware-internal state would duplicate an existing discriminator or require behavior outside the public task.

## Exact-version verification

- Combined injection passes 83/83 base tests, 16/16 native snapshot tests, and 1/1 runtime WASM test on arm64 and amd64.
- Test-only injection passes 83/83 base tests on both architectures, exits nonzero for the absent API, and emits only the skipped compile placeholder.
- Solution-only injection passes locked/offline metadata, the complete workspace/all-target test command, workspace doctests, WASM target check, standalone no-default-features RMK build, `rmk-macro` build, and `rmk-macro` `_simulator` test on both architectures. The proc-macro command passes 47 unit tests, one compile-fail test, and five expansion fixtures.
- Eight saved solutions were replayed: four pass and four fail. The newly supplied four-run set falls from three complete passes to one after the public combo-layer boundary is enforced.
- All three legitimate implementation variants pass; all 40 exact-version mutants fail a public behavioral, cross-crate compilation, or runtime WASM discriminator.
- `cargo fmt --check`, patch whitespace/application checks, pristine-manifest equality, and architecture lock equality pass.

This closes the mandatory false-positive gate for immutable version 17. It is evidence for the attempted repository- and trajectory-grounded mutation set, not proof that false positives are impossible. Calibration remains 0/10.
