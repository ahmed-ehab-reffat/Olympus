Title: Expose observed progress for local mutations

## Rust API

Export `MutationReceipt`, `MutationStatus`, and `SyncState` from the Rust crate. `LocalDocument::mutate` must return the receipt. Add `LocalDocument::sync_state(received: Option<Lsn>)`, where `received` is the latest coordinator acknowledgement observed by the caller's replication layer. Add `SyncState::status` to classify a receipt; the classifier may accept the receipt by value or shared reference.

`MutationReceipt` is constructible with public `timeline_id` and `lsn` fields. `SyncState` is constructible with public `timeline_id`, `local`, `received`, and `applied` fields, and those fields are directly readable.

## Progress semantics

The three progress fields are optional inclusive LSN watermarks for the snapshot's timeline:

- `local` is the greatest LSN allocated locally, including an applied prefix that is no longer retained.
- `received` advances only after this client processes a coordinator range acknowledgement, not merely when it sends a frame.
- `applied` advances only when coordinator application has returned through storage replication and become visible after rebase.

A successful mutation's receipt identifies its exact allocated LSN. A failed mutation returns no receipt, consumes no allocation, produces no sync-state change, and does not advance `local`.

An acknowledged range can be empty after its retained prefix is removed. When `nextlsn > 0`, it still represents the inclusive received watermark `nextlsn - 1`; it is not missing acknowledgement knowledge.

## Receipt classification

Classification is timeline-bound and bounded by `local`: a foreign-timeline or future receipt returns `None`. Otherwise `Applied` takes precedence over `Received`, which takes precedence over `Local`.

A snapshot contains only knowledge already observed by this client and remains available while disconnected. A fresh connection's newly observed peer range replaces stale acknowledgement knowledge.

## Worker and browser API

`SQLSync.mutate` must resolve to the exported `MutationReceipt`. Add `SQLSync.syncState(docId, docType)` resolving to `SyncState`, and `SQLSync.mutationStatus(docId, docType, receipt)` resolving to `"local"`, `"received"`, `"applied"`, or `undefined` with the Rust classifier's binding, bounds, and precedence.

Export `MutationStatus`, `MutationReceipt`, `SyncState`, and `Lsn` from the worker package. Browser values must preserve every Rust `u64` without admitting JavaScript `number`; any lossless representation is acceptable.

## Sync-state subscriptions

Export a worker-package type named `SyncStateSubscription` accepting `{ handleState(state) { ... } }`. Add `SQLSync.subscribeSyncState(docId, docType, subscription)` accepting that type and resolving to an unsubscribe function.

The handler receives the current snapshot before the method resolves, then later locally observed changes without polling. Local mutations and coordinator acknowledgements must both be observable. Each registration is scoped to its supplied `docId` and receives its own initial snapshot. Registering or removing another subscription is not a state change and must not notify existing registrations.

If a subscription unsubscribes itself from inside `handleState`, it receives no later changes, but another active subscription must still receive the state currently being delivered. After any unsubscribe, that registration receives no further states.

## Framework hooks

The existing React and Solid mutation hooks must resolve to the `MutationReceipt` returned by their underlying `SQLSync.mutate` call.
