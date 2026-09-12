# Solution approach

The reference treats a copy-on-write namespace as more than the two physical
filesystems. It adds synchronized wrapper-local state for exact hidden names and
opaque directory roots. Lookup consults that state after checking the upper
layer; directory merging filters lower children through the same rules.

Removal first validates the logical object. `Remove` checks merged-directory
emptiness before changing anything. Both remove variants materialize only the
needed upper parent, remove any upper entry, then commit hidden/opaque state if
the lower object contributes to the logical view. Successful creation clears
exact hidden state along the created path but deliberately retains opacity, so
recreating a recursively removed directory does not reveal its old lower
children.

Rename uses eager materialization. It copies the complete logical source to a
unique upper staging name, preserving regular-file contents, modes, timestamps,
and directory structure. It then backs up any upper destination and source,
publishes the stage through upper-layer rename, and only afterward commits
source hiding and destination opacity. Pre-commit failures remove the stage and
restore backups. A moved directory is fully materialized and its destination
root is opaque, so neither missing lower source entries nor stale lower
destination entries can leak through.

All namespace keys use cleaned paths, and subtree-state operations use
`filepath.Rel` boundaries rather than string prefixes. The reference rejects
cross-layer symlink materialization because that behavior is outside the public
task.

Reference size: two production files, 456 raw additions and 43 deletions, with
433 strict nonblank, non-comment production additions. This is one valid
architecture; the preserved 503-line lazy redirect prototype proves that tests
do not require eager copying or this state representation.
