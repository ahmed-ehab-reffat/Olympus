# Add deletion support to the copy-on-write overlay filesystem

Give `CopyOnWriteFs` a new mode, reached through `NewCopyOnWriteFsWithDeletions(base Fs, layer Fs) *CopyOnWriteFs`, that records removals in the layer, so what lives only in the base can be taken away.

`Deleted() ([]string, error)` reports the paths with a removal recorded, slash separated, rooted at the overlay, sorted, and never an entry under another it reports. `Restore(name string) error` drops the removal recorded at a path, so the base entry and everything under it not recorded on its own shows again; a path with no record reports `os.ErrNotExist`. Restoring a path under a removed directory drops its record and leaves it out of sight. `Flatten(dst Fs) error` writes the view the overlay shows into another filesystem, permissions and modification times included, replacing whatever it writes over and leaving the rest. On an overlay from the old constructor, `Deleted` reports nothing and `Restore` reports `os.ErrNotExist`.

In the new mode `Remove` and `RemoveAll` succeed on anything the overlay shows. Whatever the layer holds for it is dropped and, where the base still shows it, the removal written there, so a fresh overlay over the same base and layer starts the same way. Every operation on a hidden path reports `os.ErrNotExist` in an `*os.PathError` naming the path, except `RemoveAll`, which succeeds. Removing a directory hides everything under it, including base entries nobody has looked at; a path is hidden whenever any directory above it is. `Remove` on a directory that still shows an entry fails with `syscall.ENOTEMPTY`. `RemoveAll` on the root is removing each thing it shows.

A directory the overlay makes for its own sake takes the base permissions and modification time; what the caller makes takes the permissions asked for. Removing a directory does not undo the removals recorded under it.

Making a hidden path again drops its removal record, and nothing of the base comes back with it: a file made there starts empty and holds only what the layer writes, and a directory made there is empty and keeps the base contents under it hidden. A path the layer shows as a file hides whatever the base keeps under it. This works under a removed directory too, rebuilding that directory on the way.

`Rename` moves what the overlay shows at the source to the new name, permissions and modification time with it, copying into the layer whatever lives only in the base, file or tree, and records the source removed where the base still shows it. Renaming onto a path the overlay already shows replaces it. A symlink copied into the layer or written out is what it points at, not a link; moving one already in the layer keeps it a link.

An overlay in either mode reads a directory sorted by name, minus anything it hides, and never the bookkeeping it keeps.
