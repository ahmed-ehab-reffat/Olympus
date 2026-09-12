# Calibration levels - failure-atomic remote offers

The full L3 package calibrated at 10 legitimate solves in 10 runs and was
archived on 2026-07-27. L1 and L2 were design stages only.

## L1 - core media transaction

Require a rejected reordered offer not to retain an earlier media direction
change, while preserving the pending-offer invalidation exception.

This is the minimum coherent task. It exercises the central validate-before-
commit boundary but can be solved with a media-specific preflight.

## L2 - cross-subsystem atomicity

Add ICE restart rollback and missing-fingerprint liveness/retry behavior.

This prevents a solution that validates only m-line ordering immediately before
media application. It requires finding the earlier ICE and lifecycle mutations.

## L3 - full current package

Add established SNAP rejection across earlier ICE/media changes, candidate
retention, remote extension-map rollback, fingerprint retry isolation, event
compatibility, valid retries, and the complete neighboring SDP regression suite.

This is the packaged level. It spans ICE credentials and candidates, lifecycle,
fingerprint/DTLS recovery, SCTP/SNAP, session/media mappings, events, and public
pending-offer ordering without prescribing an internal transaction
representation.

## Calibration levers

The 10/10 L3 result closes offer-side hardening. Do not add more fixtures for
reordered MIDs, candidate forms, fingerprints, extension attributes, events, or
SNAP: all ten legitimate solvers implemented complete preflight, so these
variations do not create a distinct implementation boundary.

If no solver can pass, ease by dropping the event guard first, then the combined
SNAP case, but only in a new immutable version whose checks and calibration
restart at 0/10. Do not remove the ICE restart, liveness/retry, or pending-offer
exception; those define the task's cross-subsystem and compatibility content.

This easing guidance is retained only as historical design context. The problem
is archived, and no further version is planned.
