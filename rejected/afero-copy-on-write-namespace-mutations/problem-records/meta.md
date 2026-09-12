Title: Complete copy-on-write namespace mutations

Make `CopyOnWriteFs` support `Remove`, `RemoveAll`, and `Rename` over its merged logical view for regular files and directories, including entries that exist only in the base, while leaving the base filesystem unchanged.

After a successful `Remove`, the name must be absent from stat, open, and parent-directory iteration even when a lower entry still exists. Removing a missing name must remain a not-exist error, and removing a non-empty logical directory must fail without changing its contents. `RemoveAll` must hide the complete logical subtree, return nil for an absent path, and allow the path to be recreated. A directory recreated after recursive removal starts empty: old base children must not reappear, while new children written through the composed filesystem remain usable.

`Rename` must move the complete logical source, whether it is base-only, layer-only, or a merged directory. The source becomes absent and the destination exposes the source's contents, modes, and directory structure. When replacing an existing logical destination of the same kind, no stale base-only or layer-only destination entry may remain visible. Deletion and opaque-directory state inside a renamed tree must move with it, and repeated renames must continue to behave as ordinary namespace moves.

Equivalent cleaned path spellings must address the same logical state. If a required layer operation reports an error before a namespace mutation commits, the observable source and destination views must remain as they were before the call. Internal bookkeeping must never appear through the composed filesystem's directory or lookup APIs.

The new state only needs to live for the lifetime of the constructed `CopyOnWriteFs`; rebuilding a wrapper from the same two filesystems need not recover earlier removals or renames. Concurrent namespace mutation and new cross-layer symlink behavior are outside this change; retain existing optional-interface behavior without requiring base-backed symlink relocation.
