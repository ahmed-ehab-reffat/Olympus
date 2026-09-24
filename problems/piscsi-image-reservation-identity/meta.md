---
Repository: https://github.com/PiSCSI/piscsi
Issue: N/A
Commit: 4f800bae944bbcbc185b47b7ac28ccaf7c94906c
Language: C++
Category: feature-request
Title: Add identity-aware, shareable image reservations to the PiSCSI daemon
---

# Add identity-aware, shareable image reservations to the PiSCSI daemon

Add file identity and read-only sharing to image reservations in the piscsi daemon: an image is recognised by the file its name resolves to, not by the name's text, and a hold stays with that file even if it is renamed and its name reused; read-only devices may share an image.

An image name is an absolute path or a name relative to the default image folder (attach and insert try the daemon's working directory first, as today), and may contain `.` or `..` segments or go through a symbolic link. Names that resolve to the same file, and hard links to one file, all refer to the same image.

A device that is read-only once its image is opened (a CD-ROM, or a disk whose image file is not writable) is a reader; write protection does not count. Readers may share an image, but any other device needs it alone: attaching or inserting is refused when a non-reader holds the image, or when a non-reader asks for an image anyone holds. While an image is held, the delete, rename/move, copy, protect and unprotect commands refuse it as their source. Refusal errors name holders as `1:0, 3:0`: all of them for image commands, only those the new device conflicts with for attach or insert. Detaching a holder or ejecting its medium releases only that device's hold. Once nobody holds it, the image is free under every name; deleting a symbolic link to it removes only the link.

The create, delete, rename/move, copy, protect and unprotect commands accept both name forms for every file name. `.` and `..` are resolved as the filesystem does (after a folder link, `..` is the link target's parent), and the folder depth limit then applies to the resulting location inside the default image folder, so `sub/../disk.hds` counts as `disk.hds`. They refuse any name outside that folder, including one whose folders lead outside through a symbolic link; an image that itself links to a file elsewhere stays usable. Creating works for a user without a passwd entry too, keeping that user's group.

`StorageDevice::GetHoldersForReservedFile` accepts any absolute name of an image and returns its holders (`ImageFileHolder` values with `ids`, an `id_set` of ID and LUN, and `read_only`) ordered by ID and LUN, empty when the image is free. `StorageDevice::GetIdsForReservedFile` returns the first holder's ID and LUN, or `{-1, -1}`. `StorageDevice::GetReservedFiles` maps each file name a device opened (as given, or joined to the default image folder when found there, nothing resolved) to the holders that opened it under that name.

Each reported image file lists these holders, in order, in a new `holders` field of `PbImageFileHolder` messages (`id`, `unit`, `read_only`). scsictl adds `in use by 1:0, 2:0` to a held image's line and `shared with 2:0`, naming the other holders, to a sharing device's line.

A multi-device attach command also checks its devices against each other and attaches none of them if one would be refused or two share an ID and LUN.
