# Solution approach

Return the LSN allocated by the existing timeline append and pair it with the
timeline ID as a mutation receipt. Derive the local watermark from the range's
next allocation so an empty range after prefix removal still preserves
historical progress.

Retain the latest destination range processed by replication and expose its
inclusive watermark as the coordinator-received observation, including
`nextlsn - 1` for an empty-following range. Preserve that observation while
disconnected and replace it when a fresh connection reports a newer or lower
range. Read applied progress from the existing
`__sqlsync_timelines` row after coordinator storage has replicated back and
rebased locally.

Combine those observations in a timeline-bound snapshot. Classification first
rejects foreign or future receipts, then checks applied, received, and local in
precedence order.

Carry the receipt and snapshot through the existing Wasm worker request/reply
channel. Return the receipt from `SQLSync.mutate`, add `SQLSync.syncState`, and
export generated types. Accept a public receipt in a worker classification
request, convert its lossless LSN carrier back to Rust, and return the core
classifier result through `SQLSync.mutationStatus`. Propagate the receipt return
through the React and Solid mutation hooks. Convert Rust `u64` LSNs directly to
decimal strings so the browser boundary never passes through JavaScript's lossy
numeric type.

Add a per-document sync-state subscription alongside the existing query-event
path. Register interested worker ports, return the current snapshot when the
subscription is established, and emit updated snapshots from local-timeline
and coordinator-observation signals. The TypeScript facade fans those events
out to document listeners and unregisters the worker port after the final
listener unsubscribes.
