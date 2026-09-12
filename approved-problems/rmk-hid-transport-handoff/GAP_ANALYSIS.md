# Gap analysis — version 44

Verdict: **pass**. The exact environment gate passed before this audit.

## Requirement-to-test matrix

| Public boundary | Strongest observable coverage |
|---|---|
| direct USB↔BLE handoff from preference and readiness changes | real USB endpoint and BLE GATT output in both directions |
| route activation, not merely transport identity, owns blocked sends | blocked USB and BLE sends across direct cutover, disconnect/reconnect, and same-transport return |
| BLE profiles are separate host activations | profile-zero queued and blocked traffic is retired before profile one receives the current mouse state; return to profile zero cannot revive the old send |
| stale queued traffic is completely discarded | packet-by-packet host observation at capacities one and three for old USB and old BLE routes, plus a non-neutral queued packet at profile cutover |
| disconnected state from either producer reaches either next transport | nonblocking and awaited all-family updates with USB-first and BLE-first activation |
| neutral and later non-neutral values replace old state | queue-full dropped-neutral, offline press/release, awaited held→neutral→held, and changed-steno probes |
| family and feature independence | all enabled families in capacity-one steno, capacity-three steno, and capacity-one no-steno lanes |
| relative mouse impulses are live-only | exact live values and zero x/y/wheel/pan in replay snapshots, including profile handoff |
| BLE steno is coherent Plover HID | parsed logical collection, report ID/reference `0x50`, and exact eight-byte notification |
| Plover subscriptions belong to one BLE profile | real ATT subscription is persisted opaquely, absent on profile one, and restored on profile-zero reconnect |
| supported behavior does not regress | exact inventory of 538 pre-existing tests |

## New discriminator and rejected matrices

Run-17 Nova 9 supplies a representative shortcut: it handles the prior 13
requirements but clears retained state whenever a route temporarily becomes
`None`. The exact version-44 suite rejects only its new profile test because
profile one never receives the held mouse state. A separate omitted-steno-CCCD
mutant likewise passes the baseline and prior 13 tests but fails subscription
persistence. These are independent route-session and GATT-lifecycle branches
supported by solver and repository evidence.

No additional Cartesian fixtures were added for every family at every profile,
more than two profiles, capacity three combined with profile switching, or
arbitrary producer/setter races. Existing tests already prove the generic
all-family, multi-entry queue, and both-producer mechanisms; the profile probe
crosses those mechanisms with mouse, keyboard, and steno at the independent
peer/session seams. Repeating other families there would add fixtures, not a new
semantic discriminator. Fixed ordering, private generations, persisted table
layout, exact handles, and product latency remain outside the oracle.

No actionable public gap remains in the attempted trajectory- and
repository-supported failure modes.

Immutable `test.patch`:
`4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`.
