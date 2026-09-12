Title: Add portable full-configuration snapshots to Rynk

Add a snapshot format to the allocation-enabled `rynk` host client, so a keyboard's configuration can be saved as bytes and restored.

All of it exists whenever `alloc` is enabled, with or without `std`: `SNAPSHOT_VERSION` (value 1), `SnapshotGeometry`, `ConfigurationSnapshot`, `SnapshotRead`, `RestoreStage`, `SnapshotError` and `RestoreError`.

`SnapshotGeometry` holds ten of `DeviceCapabilities`' fields under the same names and types: `num_layers`, `num_rows`, `num_cols`, `num_encoders`, `max_combos`, `max_combo_keys`, `macro_space_size`, `max_morse`, `max_patterns_per_key`, `max_forks`.

`ConfigurationSnapshot` implements serde's `Serialize` and `Deserialize` and `PartialEq`, and carries `version`, `device_info`, `geometry`, `default_layer`, the `keymap`, `encoders`, `combos`, `forks` and `morses` tables, `macro_data` and `behavior`. `version` is a `u16` and `macro_data` a byte vector.

Give it `to_bytes`, `from_bytes` and `validate`; the encoding is yours. Encoding refuses a snapshot that fails validation; decoding consumes the whole input, rejects anything invalid, and returns what was encoded.

Equal snapshots must produce equal bytes wherever the protocol's equality calls two values the same. `Morse.actions` built in different insertion orders is one such case, and not the only one.

Validation rejects any version but `SNAPSHOT_VERSION`, wrong collection lengths, an out-of-range default layer, combos over `max_combo_keys`, combo layers outside the snapshot's layers, and Morse definitions over `max_patterns_per_key`.

Add `export_configuration`, `preflight_restore` and `restore_configuration` to the client; both restore methods borrow the snapshot.

Export reads identity, default layer, keymap, encoders, combos, forks, Morse definitions, macros, then behavior, to the advertised extents. Keymaps go layer, row, column; encoders are layer-major then encoder-ID-major. Macros are read in advertised-size chunks covering exactly `macro_space_size` bytes, short final chunk included.

Restore is portable: USB vendor ID, product ID and product name must match; manufacturer, serial number, firmware version and transport limits may differ.

The target may be larger in any geometry dimension, and is rejected only if one is smaller.

Neither direction needs whole-resource bulk transfer; without it, reads go one entry at a time. Restore does need a nonzero macro chunk when macro space exists.

Before mutating anything, restore reads and validates the target's complete configuration, then writes what differs stage by stage: `Keymap`, `Encoders`, `Combos`, `Forks`, `Morses`, `Macros`, `Behavior`, `DefaultLayer`.

Restore uses as few write requests as it can. A bulk request covers a contiguous run in the target's coordinates, so it may carry matching entries to bridge differing ones, but it never spans a slot the snapshot does not reach and never begins or ends on a matching entry. Where a resource has no bulk endpoint, or the target has none, only differing entries are sent, one at a time. Macros compare on the target's chunk grid; only differing chunks are written, exact bytes.

`RestoreError::Preflight` covers every rejection before the first write, including a request the target's frame cannot carry, and guarantees the device was untouched.

`RestoreError::Write { completed, stage, source }` reports the failed stage and every earlier stage it wrote in full; skipped stages are absent; no later stage is attempted. Since each attempt re-reads the baseline, a retry plans afresh from what the device then holds.

Add byte-oriented `export_configuration_snapshot()` and `restore_configuration_snapshot(bytes)` to `rynk-wasm`'s `RynkClient`.
