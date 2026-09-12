# Prototype record

The cheapest complete prototype is preserved in `prototype.patch`.

- Production files: 1 (`oci/layer/unpack.go`).
- Raw production additions/deletions: 54/0.
- Strict nonblank, non-comment production additions: 48.
- Formatted production diff SHA-256:
  `1083c6f67e25cd14ff73e661b09daa04344e264a0f30a862cd2d4ae02abb2d20`.

The prototype defers hardlinks whose target has not been supplied by the
current layer, cancels stale pending destinations when later entries replace
their path or hierarchy, resolves chains to a fixed point, and reports an error
when no progress is possible. It also avoids linking to a pre-existing lower
inode when the same target path is replaced later in the layer.

An in-memory Go prototype suite exercised six independent outcomes:

1. a reversed two-hop forward chain;
2. a forward hardlink to a symlink inode;
3. exact destination supersession;
4. an existing lower target replaced later in the layer;
5. a later non-directory parent superseding a pending child; and
6. an unresolved cycle.

The focused prototype lane passed all six as UID/GID 10001 with networking
disabled. The complete ordinary `go test ./...` package lane then passed under
the same offline arbitrary-UID conditions. `git diff --check` passed.

This is scope evidence, not a submission reference. The direct repository
recipe can also be expressed as pending state inside `TarExtractor`, a finalizer
called by `UnpackLayer`, or a dependency map rather than the prototype's retry
slice. Those alternatives move the same small state machine across the same
`oci/layer` seam; they do not create independent production boundaries.
