# Solution approach

Introduce an allocation-gated `snapshot` module in `rynk`. Model compatibility
with a transport-independent `SnapshotGeometry`, and keep the persisted record
typed with the protocol's existing actions and configuration structures. Gate
the module and its re-exports on `alloc`, never on `std`.

Validate the record before encoding and after decoding. Because
`heapless::LinearMap` serializes in insertion order even though Morse action
maps compare by content, clone the snapshot and sort each Morse map by pattern
before postcard encoding. Decode with `postcard::take_from_bytes` so trailing
data is rejected.

Export by using the existing whole-resource pagers for keymaps, combos, and
Morse definitions, explicit capability-bounded loops for encoders and forks,
and advertised-size chunks for macros. Restore first checks target identity and
transfer support, then accepts the target when no geometry dimension is smaller
than the snapshot's, then exports and validates a complete current baseline
before mutation.

The baseline belongs to the target, so it is shaped by the target's geometry,
not the snapshot's. Enumerate the snapshot in its own coordinates but resolve
every comparison and every write address through the target's strides: a key at
`(layer, row, col)` sits at `(layer * target_rows + row) * target_cols + col`,
and an encoder at `(layer, id)` sits at `layer * target_encoders + id`. Slots
the snapshot does not reach are never read into a comparison and never written.

Collect the differing entries of a stage as `(target index, value)` pairs, then
fold them into pages: extend the current page while the next index is adjacent
and the page is below the target's advertised size, and start a new page
otherwise. A gap can come from an equal entry or from the target's spare
columns, so a run that looks contiguous in the snapshot may legitimately split.
Keymaps, combos, and Morse definitions send those pages through their bulk
endpoints; encoders and forks have no bulk endpoint and write one entry at a
time. Compare macro data on the target's chunk grid but only out to the
snapshot's macro space, so the final write is short when the spare bytes do not
divide evenly.

Record a stage as completed only after all of its writes succeed, and keep the
default layer last. Because every invocation refreshes the baseline, retrying
after a partial stage failure naturally skips entries and chunks that the first
attempt already applied.

The WASM wrapper races the native snapshot future against the same shared
driver lock as existing methods, then converts snapshot errors into JavaScript
`Error` values. This keeps native and browser callers on one serialization and
restore implementation.
