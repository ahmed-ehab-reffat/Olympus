# RMK HID transport handoff archive

Status: **accepted and archived 2026-08-12**.

The user confirmed platform approval. Canonical problem artifacts and compact
design records remain in `problems/rmk-hid-transport-handoff/`. Raw solver
batches 1 through 18 are preserved here as ZIP archives.

Before removing the duplicate extracted directories, every ZIP passed
`unzip -t` and its normalized file list matched its source directory exactly;
the only excluded files were `.DS_Store` metadata. `SHA256SUMS` identifies the
archived bundles.

The final version-45 change removed a verifier dependency on the private
`UPDATED_CCCD_TABLE` payload. The focused profile/Plover test passed both the
reference and run-18 Nova 9's profile-tagged signal representation. At explicit
operator direction, the complete exact-version pipeline was not rerun after
that narrow correction; platform acceptance is user-confirmed rather than
inferred from those stale local records.

Cleanup removed project-specific RMK handoff temporary trees, the exact
untagged RMK Docker image, and all `rmk-audit-*` volumes. No RMK-tagged
container existed. During BuildKit cache-filter discovery, an erroneous
`id!=...` filter also removed unrelated reclaimable build cache; source files,
images, containers, and volumes were unaffected, but those unrelated caches
are not recoverable and will rebuild on demand.
