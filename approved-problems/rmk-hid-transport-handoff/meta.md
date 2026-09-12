Title: Add lossless USB/BLE HID transport handoff

Add lossless HID state handling across USB/BLE changes and reports produced while no connection is active. On a direct handoff, discard stale traffic from the old route and replay the latest absolute state to the new host; no release packet to the old host is required. A disconnect without a replacement may clear held state, but later offline updates must be retained for the next host. Support both handoff directions and every enabled report family even when the ordinary report queue is smaller than the replay set.

Both `send_hid_report` and `try_send_hid_report` must retain the latest absolute state when there is no active route; the nonblocking producer must also retain it when the live queue is full. A `send_hid_report` call already blocked on a full active queue must not leak onto that old route after handoff. Treat each transport activation as a distinct route: leaving and returning to the same transport must not revive a send blocked during its earlier activation. A neutral update clears held state. Preserve keyboard, mouse buttons, media, system control, and optional steno; replay relative mouse movement and scrolling as zero.

Other producer/status races are out of scope.

Treat each BLE profile as a separate host activation. Switching profiles must
retire the previous profile's queued and blocked traffic, then replay the latest
held absolute state when the selected profile connects. Returning to an earlier
profile must not revive a send that was blocked during its previous connection.

With BLE and `steno`, add a Plover-compatible input report with report ID `0x50`. Define it in the HID report map as one coherent logical input collection on usage page `0xFF50` with usage `0x4C56`. Within that collection, report ID `0x50` must have a Data, Variable, Absolute Input item whose `report_size * report_count` is 64 bits. Notifications must use the `0x50` input-report reference and carry exactly the eight chord bytes in order.

Plover notification subscriptions are per profile. Enabling report `0x50` for a
profile must be restored when that profile reconnects, without enabling it for
another profile.

Validate offline from the repository root with `KEYBOARD_TOML_PATH="$PWD/examples/use_config/nrf52840_ble/keyboard.toml" cargo test --manifest-path rmk/Cargo.toml --offline --no-run --no-default-features --features=rynk,_ble,split,async_matrix,storage,steno`.

Also run that command with temporary `[rmk]` configurations setting `report_channel_size` to 1 and 3, passed by absolute `KEYBOARD_TOML_PATH`.
