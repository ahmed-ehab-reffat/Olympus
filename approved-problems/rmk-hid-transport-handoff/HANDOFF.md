# Handoff — RMK HID transport handoff

Status: **accepted and archived 2026-08-12**.

Canonical submission files remain here:

- `meta.md`
- `test.patch`
- `solution.patch`
- `solution_approach.md`
- `Dockerfile`
- `ARTIFACTS.sha256`

Raw solver batches 1–18 and their checksums are under
`archive/rmk-hid-transport-handoff/`. Project-specific temporary worktrees,
targets, Docker image, volumes, and duplicate extracted run directories were
removed after the archived ZIPs were verified.

The final v45 verifier correction is documented in `DESIGN.md`: it removed a
private CCCD-signal type assumption and passed focused reference and run-18
Nova 9 reproductions. The full exact-version pipeline was intentionally skipped
at operator direction. Do not present the earlier verification records as v45
evidence; platform acceptance was explicitly confirmed by the user.
