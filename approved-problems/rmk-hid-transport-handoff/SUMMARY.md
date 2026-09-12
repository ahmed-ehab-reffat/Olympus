# RMK HID transport handoff

Status: **accepted and archived 2026-08-12**.

The accepted task adds lossless absolute HID state across USB, BLE, no-host,
and BLE-profile transitions, including bounded replay, stale and blocked route
retirement, relative-mouse suppression, and Plover-compatible BLE steno with
per-profile subscription isolation and restoration.

The user confirmed platform approval. Canonical artifacts and compact records
remain in this directory. All 18 raw solver batches are preserved as verified
ZIPs under `archive/rmk-hid-transport-handoff/`; duplicate extracted copies and
project-specific temporary/Docker state were removed.

Version 45 corrected the final hidden-test mismatch by observing persistence at
RMK's profile storage boundary instead of requiring the private
`UPDATED_CCCD_TABLE` signal to retain its old payload type. The focused test
passed the reference and the formerly rejected run-18 Nova 9 implementation.
The operator explicitly skipped the complete exact-version pipeline after this
narrow fix, so acceptance is user-confirmed rather than inferred from stale
verification records.
