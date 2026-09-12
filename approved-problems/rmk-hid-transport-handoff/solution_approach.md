Track the latest absolute fields of every HID report family at the shared
report-routing boundary, including reports produced while no transport is
active. Track which non-keyboard families each host route may have observed so
a cutover can release only state that could otherwise remain held.

Wrap each existing configured-size transport channel with a bounded handoff
backlog. A transition replaces stale live traffic with the required release or
replay sequence, fills only the capacity currently available in the ordinary
channel, and lazily refills it after each receive. Live producers remain behind
that sequence. This lets a genuinely one-entry configured channel deliver all
enabled families without enlarging the generated `REPORT_CHANNEL_SIZE`.

Keep the public report-channel surface source-compatible by dereferencing the
wrapper to the original Embassy `Channel` and exposing `AsRef<Channel>`. Existing
downstream calls such as `send`, `sender`, and `receiver`, plus coercions to a
channel reference, continue to compile while the reconciliation backlog stays
private.

Serialize active-route selection, logical-state recording, live enqueue, and
handoff reconciliation through the connection-status critical section. A
transition commits the route and, before admitting another producer, snapshots
the tracked state, replaces old-route traffic with a neutral keyboard report
and any required non-keyboard releases, and replaces new-route traffic with
each currently held absolute state. This prevents a producer from appending to
the old channel after it was cleared or having a new-channel enqueue erased by
reconciliation. Reconstruct mouse reports with their button field preserved
and all relative axes zero.

Blocking sends release the cutover boundary while waiting for capacity and
retry under it. If reconciliation completed while they waited, the replay
already contains their remembered absolute state and they return instead of
leaking to the previous route. Give every active-route transition a generation
and have a blocked send retain the generation on which it first waited; a
USB-to-BLE-to-USB cycle is therefore distinguishable from an unchanged USB
activation. Both producer APIs remember state before returning for lack of an
active route. Nonblocking sends also remember state when live delivery is
dropped, allowing the next host to receive the current absolute state.

Let RMK's existing profile switch transition BLE to inactive before the newly
selected peer reconnects. That retirement and reconnection advance the same
route generation used by transport handoffs, so queued traffic and blocked
sends from the previous profile cannot cross into the new peer session while
the retained absolute snapshot is replayed normally.

For steno-enabled BLE builds, append the existing Plover descriptor to the HID
report map, add a report-reference characteristic for report ID `0x50`, and
serialize the eight chord bytes into a real GATT notification. This carries a
steno replay beyond the BLE report queue to the host instead of silently
returning `Ok(0)` at the writer. Include the steno CCCD in the existing GATT
update bookkeeping so subscription changes follow the same persistence and
activity path as the other HID input reports. The existing `ProfileInfo` CCCD
table then keeps the Plover subscription scoped to its bonded profile and
restores it when that profile reconnects.
