# Fairness analysis — version 44

## Verdict

**Pass.** The exact environment gate passed before this review.

## Public provenance and black-box observation

- The description explicitly says that each BLE profile is a distinct host
  activation and that queued and blocked traffic from the former profile must
  be retired before current absolute state is replayed to the selected profile.
- The description explicitly requires report ID `0x50`, the coherent Plover
  HID item structure, exact eight-byte chord notifications, and per-profile
  subscription save, restore, and isolation.
- RMK already exposes profile selection, connection status, a per-profile
  `ProfileInfo` containing an opaque ATT table, and the ordinary GATT
  subscription lifecycle. The test exercises those existing seams through ATT
  reads/writes and host-visible notifications.
- Report characteristics are discovered from their actual report-reference
  descriptors. The oracle does not assume candidate handle numbers or a private
  `BleHidServer` field layout.
- The saved CCCD table is passed back opaquely. The test never asserts signal
  names, table bytes, storage encoding, queue type, locks, route counters, or
  cache representation.
- Replay order is arbitrary. Neutral cleanup packets are permitted, and absence
  is permitted when neutral state need not be emitted. Assertions reject every
  stale non-neutral packet as it arrives rather than retaining only the last
  packet per family.
- The 30-second process bound is a harness deadlock watchdog. It is not a
  one-second or firmware-latency requirement; the reference phases finish in
  milliseconds.

## Architectural and environment freedom

The test-only patch adds randomized probe/configuration files and `test.sh`; it
does not modify participant production files. The USB and BLE tests exercise
real writer/GATT boundaries while allowing state maps, generations, replay
queues, locks, or another bounded design. Both patch orders compose to the same
Git tree.

The Dockerfile builds from the untouched checkout. Runtime is network-disabled
and uses UID/GID `10001:10001`; the participant-visible harness does not depend
on a hidden source-tree lockfile. Pristine compiles and fails all 14 tests for
behavior, while the reference passes every baseline and focused lane.

A run-17 transport-wide implementation composes and passes the prior 13 focused
behaviors but fails the new public profile invariant. An independent reference
mutant omitting Plover CCCD bookkeeping passes 538/538 baseline and those same
13 tests, then fails only persistence. This supports the oracle's behavioral
specificity without requiring either implementation architecture.

Immutable `test.patch`:
`4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`.
