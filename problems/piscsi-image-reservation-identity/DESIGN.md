# DESIGN.md — piscsi-image-reservation-identity

## Phase 1 — Repo understanding

**Architecture (one paragraph).** PiSCSI turns a Raspberry Pi into SCSI/SASI targets. `cpp/piscsi/`
is the daemon side: `PiscsiService` receives protobuf `PbCommand`s, `PiscsiExecutor` validates and
applies device commands (ATTACH / DETACH / INSERT / EJECT / PROTECT ..., with a dry run over every
device of a command before the real run), `PiscsiImage` implements image-file commands (create,
delete, rename, copy, protect) relative to a default image folder, and `PiscsiResponse` renders
device and image state back into protobuf. `cpp/devices/` holds the emulated devices; every device
with a medium derives from `StorageDevice`, which owns a process-wide static ledger
`reserved_files : unordered_map<string, id_set>` recording which ID:LUN uses which image file.
`cpp/controllers/` maps IDs to controllers; `cpp/scsictl/` is the CLI client; `go/` is the new web UI.

**Subsystems:** (1) command execution `piscsi/piscsi_executor.*`; (2) image-file operations
`piscsi/piscsi_image.*`; (3) device model + ledger `devices/storage_device.*`, `disk.cpp`
(eject), `scsi_streamer.cpp`; (4) response rendering `piscsi/piscsi_response.*`;
(5) controller management `controllers/`.

**Entanglement zones:** the reservation ledger (executor reserve / device release / image-op lookup,
three different spellings of an image name); the dry-run-then-run protocol in
`PiscsiExecutor::ProcessCmd` (snapshots and restores the ledger around a dry run that never
reserves); removable media (INSERT re-reserves, EJECT releases).

**Tests:** GoogleTest + GMock, one binary `cpp/bin/piscsi_test` built by
`make -C cpp DEBUG=1 bin/piscsi_test`, 318 tests. Format template: `cpp/test/piscsi_executor_test.cpp`
(drives `PiscsiExecutor::ProcessCmd` with real `PbCommand`s and temp image files from
`test_shared.h`), plus `cpp/test/piscsi_image_test.cpp`.

## Phase 2 — Exclusivity / publicly-solved (run 2026-09-21, canonical org `PiSCSI/piscsi`)

- PR search, all states, 12 feature-class queries (`reserved file`, `reserve`, `in use`, `canonical`,
  `normalize path`, `absolute path`, `image path`, `symlink`, `ReserveFile`,
  `GetIdsForReservedFile`, `read-only shared`, `same image`): no PR implements identity-aware or
  multi-holder reservations. Diffs pulled for the plausible hits: #1173 (2 lines, default-folder
  location limit), #1546 (meson + test hardening; its lane-file hunks move ATTACH before the device
  lookup, canonicalise the DEFAULT FOLDER, and change spdlog level rendering; nothing on the
  ledger), #1773 (open, X68000 host filesystem; touches none of the lane files).
- Issue search, all states, 7 queries: nothing requests reservation identity or image sharing.
- Maintainer-philosophy scan: no decline, no "by design" on reservations.
- Base = `develop` HEAD (4f800ba, 2026-09-06), so base..HEAD overlap is empty. Last lane-file
  commits (4e9d0de default-folder canonicalisation, e273581 network, e578938 SASI) do not touch
  the ledger's capability.
- No sibling-library implementation: the ledger is PiSCSI's own model.

## Phase 3 — Candidate and gates

Gate 1 (reproduced on base via `PiscsiExecutor::ProcessCmd` and `PiscsiImage::DeleteImage`, scratch
test `worktrees/_piscsi_scratch/zz_repro_test.cpp`):
- R1: disk attached as `/tmp/zz/disk.hds`; `DELETE_IMAGE file=./disk.hds` passes the in-use guard
  and REMOVES the attached image, then its empty-folder cleanup throws an uncaught
  `filesystem_error` on `/tmp/zz/.`.
- R2: a second writable ATTACH of the same file spelled `/tmp/zz/./disk.hds` succeeds, so two
  writable devices share one image.
- R3: one ATTACH command with two devices naming the same image returns failure with the FIRST
  device left attached (the dry run snapshots and restores the ledger but never reserves).

Gate 5 cold: no capability work on the ledger in PRs, issues or 90-day commits. Gate 6 PASS
(above). Gate 7b PASS (above). Gate 8: behaviour is defined by the repo's own guard semantics
(`ERROR_IMAGE_IN_USE`, "The list of image files in use and the IDs and LUNs using these files").
Gate 9: 316/318 deterministic 3x as uid 1000 offline; the two environment-bound tests are
`PiscsiResponseTest.GetNetworkInterfacesInfo` (needs a non-loopback interface; red under
`--network none`) and `StorageDeviceTest.ValidateFile` (red as root because `access(W_OK)` always
succeeds for root, and the platform grades as root). Both are scoped out of base mode.
Gate 10: 0 of 6 quota; no dedupe hit in problems/, rejected/, approved-problems/.
Language gate: C++ 57% of bytes (Go 33%), lane is all C++.

TOO-EASY guard: (1) not a uniform wrap: identity resolution alone is one helper, but the feature
also needs multi-holder sharing with per-holder release and whole-command accounting in the dry
run, three separate mechanisms; (2) cross-subsystem: executor + image ops + device ledger + eject;
(3) contract survives full statement: stating "every spelling names one image" does not reveal
that the ledger must keep raw keys (base test) or that the dry run never reserves; (4) not a port;
(5) yes.

Arsenal: S3 baseline preservation through the shared ledger (raw-key base test); A7 determination
channels (attach, insert, delete, rename, copy, protect all consult the ledger); F-39 inherited
dead save/restore reached only by the new regime.

## 1. Title
Add identity-aware image reservations to the PiSCSI executor

## 2. Shape
O-Composite-extend (refactor an existing aggregation, the ledger, across executor / image ops /
devices). Dominant predicted verdict: MISSED_REQUIREMENT on composition cells.

## 3. Public API surface
- `StorageDevice::GetIdsForReservedFile(const string&) -> id_set` — now answers for any spelling of
  a held image; with several holders returns the lowest ID:LUN.
- `StorageDevice::GetHoldersForReservedFile(const string&) -> vector<id_set>` (new, FINISH scope)
  — every holder, ascending.
- `StorageDevice::GetReservedFiles()` / `SetReservedFiles()` keep keying entries by the name the
  device was given (base test pins `contains("filename")`).
- Commands: ATTACH, INSERT, DETACH, EJECT, DELETE_IMAGE, RENAME_IMAGE, COPY_IMAGE, PROTECT_IMAGE.

## 4. Canonical output form
- Identity: the file a name resolves to (absolute or default-folder-relative, `.`/`..`, symlinks).
- Holder order: ascending ID, then LUN.
- A device's reported image name is unchanged (the name it was given).

## 5. Blind-spot pre-empts
Parallel-API: "`GetIdsForReservedFile` answers for any spelling". Result ordering: "lowest ID:LUN".

## 6. Description draft
See `meta.md` (slice draft; FINISH extends it with sharing).

## 7. File footprint (full scope, sketched against real files)
| Action | Path | Raw delta | Meaningful |
|---|---|---|---|
| MODIFY | cpp/devices/storage_device.h/.cpp | +90 | ~60 |
| MODIFY | cpp/piscsi/piscsi_executor.h/.cpp | +80 | ~55 |
| MODIFY | cpp/piscsi/piscsi_image.h/.cpp | +55 | ~40 |
| MODIFY | cpp/devices/disk.cpp, scsi_streamer.cpp | +10 | ~8 |
| MODIFY | cpp/piscsi/piscsi_response.cpp (holders in device info / image info) | +40 | ~30 |
| MODIFY | cpp/shared/* localizer message for holder list | +20 | ~15 |
TOTAL ~300 raw / ~210-250 meaningful across 6-8 files. LOC floor risk is REAL (identity alone
compresses): the FINISH scope must carry sharing + per-holder release + response rendering.

## 8. Solution outline (helpers)
- `ResolveImageIdentity(path)` — `weakly_canonical(absolute(p))`, no throw.
- `StorageDevice::FindReservation(identity)` — scan the raw-keyed ledger comparing identities.
- `StorageDevice::ReserveFile()` — add this ID:LUN as a holder; `UnreserveFile()` removes only it.
- `PiscsiExecutor::ProcessCmd` — dry run reserves into the ledger for every device, then restores
  the snapshot, so intra-command conflicts reject the whole command.
- `PiscsiImage::*` — look up by identity of `GetFullName(name)`.

## 9. Test outline
New file `cpp/test/image_reservation_<hex>_test.cpp`, fixture with `UnreserveAll()` in
SetUp/TearDown and a per-test temp image folder. Buckets: spelling parity (abs / relative /
`./` / `..` / symlink) x guard (attach, insert, delete, rename, copy, protect); one-command
conflicts; old raw-key API still works; (FINISH) sharing and per-holder release cells.

## 10. Forced shapes
New static `GetHoldersForReservedFile(const string&)` returns `vector<id_set>`; must be named with
its full shape in meta.md (L72).

## 11. Trap matrix
| # | Trap | F-id | Class | Axis | Interdep. | Test |
|---|---|---|---|---|---|---|
| 1 | Canonicalising the ledger KEY breaks the base test that pins the given spelling; identity must be resolved at lookup | F-12/F-20 | S3 | preservation | #2 (lookup is where identity lives) | base `GetSetReservedFiles` + new raw-spelling lookup |
| 2 | Dry run snapshots/restores the ledger but never reserves; per-device checks pass single-device tests | F-39 | S2 | command atomicity | #1, #3 | one ATTACH with two devices on one image |
| 3 | Release erases the whole entry, so one of two read-only holders detaching frees the image | F-15 | A7 | multiplicity | #1 (same entry, different spellings) | share, detach one, delete refused |
| 4 | Spelling parity per guard (symlink is the non-salient form) | F-18 | A | form | all | parity cells |

## 11b. Cross-product matrix (FINISH)
spelling {abs, relative, dot, symlink} x guard {attach, insert, delete, rename, copy, protect};
holders {one, two read-only} x release {detach, eject}; command {one device, two devices}.

## 12. Tier/category
Olympus, feature-request.

## 13. Predicted pass rate
25-35% at full scope (Orion/Nova mix).

## 14. Quality gates
Repo understanding 5/5; exclusivity clean; flakiness 3x; comments: repo source carries short
`//` comments and test bodies carry a few, so added code uses NONE (default).

Why not a duplicate: nearest corpus items are `pyfakefs-block-inode-accounting` (in flight,
quota/allocation accounting) and `afero-overlay-deletions` (whiteout provenance). This pick is
reservation IDENTITY and holder multiplicity across a command protocol; no subsystem overlap.
Predicted iteration cycles: 3.
