# False-positive audit — version 44

Repository pin: `65df15775026bad1189139613ee3d338139bec3d`.
The exact environment, gap, and fairness gates passed before approval.

## Requirement map

| Participant-facing behavior | Strongest discriminator |
|---|---|
| stale output and a blocked send cannot enter a retired route activation | real-writer packet observation after direct cutover, USB/BLE leave-return, and profile switch |
| the latest current state reaches the next host | exact all-family snapshots after direct, readiness, disconnected, full-queue, and profile transitions |
| both producer APIs retain state offline | nonblocking and awaited all-family phases with both next-host destinations |
| neutral and later values replace older state | dropped-neutral, offline held→neutral, awaited replacement, and changed-steno probes |
| every enabled family works with undersized queues | steno/no-steno capacity-one plus old-USB and old-BLE capacity-three lanes |
| relative mouse impulses are not replayed | exact zero x/y/wheel/pan checks at each replay boundary |
| BLE steno is genuinely Plover-compatible | parsed descriptor collection, report reference `0x50`, and exact eight-byte notification |
| BLE profiles are independent route activations | non-neutral queued packet and blocked send from profile zero are absent at profile one while current mouse state is present |
| Plover subscriptions are saved and isolated per profile | ATT subscribe on profile zero, no Plover output on profile one, opaque-table reconnect and exact Plover output on profile zero |
| existing supported behavior remains intact | exact 538-test baseline inventory |

## Plausible incorrect implementations

The retained mutation ledger covers captured-route leakage, preference-only
reconciliation, missing `None`→BLE replay, lost disconnected state in either
producer, family-specific neutral/update loss, incorrect Plover descriptor or
report reference, clear-one queue disposal, late stale output, transport-only
activation identity, awaited-state destination asymmetry, and steno/no-steno
feature mistakes. Their strongest probes are unchanged and no version-44 edit
weakened them.

Version 44 adds these repository- and trajectory-supported shortcuts:

1. Treat BLE as one transport-wide activation and clear the retained snapshot
   during the transient `None` state created by profile switching.
2. Retire only blocked traffic but leave an already queued non-neutral packet
   available to the next profile.
3. Add a live Plover characteristic but omit its CCCD from RMK's existing
   update/persistence bookkeeping.
4. Store one global Plover subscription, enabling profile one after profile zero
   subscribed or failing to restore profile zero after reconnect.

The integrated profile probe independently observes the state/queue branch and
the subscription/persistence branch without inspecting their implementation.

## Exact mutation and trajectory evidence

Run-17 Nova 9 is an actual transport-wide solver architecture. Against the
exact version-44 verifier it passes the prior 13 focused tests and fails only
`hid_handoff_ble_profiles_isolate_plover_subscriptions_and_blocked_sends`, where
profile one never receives the latest held mouse state. Its archived complete
baseline is 538/538; the final verifier compiles with the patch and all other
focused lanes remain green.

An isolated reference mutant removed only the steno CCCD handle from the
existing GATT update condition. On the final exact test hash:

- complete pre-existing suite: 538/538 passed, 5 skipped;
- prior focused behavior: 13/13 passed;
- profile/Plover lifecycle test: failed because the subscription never entered
  profile persistence;
- total focused result: 13/14.

The pristine exact verifier has 14 testcases; all 14 fail behaviorally and none
error. The unchanged reference passes 538/538 plus 14/14. No plausible mutant
survives its strongest attempted discriminator. Candidates requiring fixed
packet order, private state, extra profile counts, arbitrary producer/setter
races, or another family/profile permutation without an independent branch
were rejected as artificial or redundant.

Verdict: **pass**. Immutable `test.patch` is
`4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`.
Calibration is 0/10; no cold solver was run.
