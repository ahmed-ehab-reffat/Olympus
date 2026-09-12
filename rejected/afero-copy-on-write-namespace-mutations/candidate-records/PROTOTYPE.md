# Prototype record - Afero copy-on-write namespace mutations

Date: 2026-08-15.

Repository pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Status: `two independent complete prototypes pass; scope gate passes`.

## Shared behavioral probe

Both implementations were tested through the same additive 325-line prototype
suite. It covers base-only and overlapping removal, non-empty-directory
rejection, opaque subtree recreation, mixed-tree rename and replacement,
upper-shadow relocation, first- and second-rename failure rollback, cleaned
path aliases, deletion state carried through rename, repeated base-backed
renames, mode preservation, and both memory and OS-backed filesystems.

The probe deliberately excludes base-backed symlink relocation. Afero's
optional symlink interfaces are not generically composable across independent
`BasePathFs` roots: `ReadlinkIfPossible` exposes a translated host target while
`SymlinkIfPossible` translates that value again. Prescribing knowledge of
private wrapper roots would be unfair. Existing layer-owned symlink behavior is
not changed, but the task makes no new cross-layer symlink guarantee.

## Architecture A - eager logical-tree materialization

Patch: `prototype-eager.patch`.

SHA-256: `bee57ea2286d9a958ac49012310d1cb5f0a3b38e3a2991c37c7b1819d1c83b24`.

The implementation adds synchronized exact-hidden and opaque-directory state.
Rename recursively copies the complete logical source to an upper staging
path, backs up upper source and destination entries, publishes the staged tree,
commits namespace state, and removes backups.

Measured production diff:

- `copyOnWriteFs.go`: 214 additions, 43 deletions;
- `cow_namespace_state.go`: 242 additions;
- two production files, 456 raw additions and 43 deletions; and
- **433 strict nonblank, non-comment production additions**.

Offline UID/GID 20002 results: every focused scenario, `go build ./...`, and
the complete 187-case JUnit lane pass with one skip and no failure or error.

## Architecture B - lazy base-path redirection journal

Patch: `prototype-redirect.patch`.

SHA-256: `5b5b34dd077c3830a44af55f5adc20b71bec84d7ceaf6e3209a7385727f7b29b`.

This implementation keeps synchronized exact-hidden, opaque, and logical
destination-to-base-source redirect state. A base-only rename records a
redirect instead of copying bytes; a mixed-directory rename moves only the
upper branch and redirects unresolved lower reads to the old base tree.
Deletion/opacity rules move with renamed subtrees, and upper replacement is
backed up before commit.

Measured production diff:

- `copyOnWriteFs.go`: 270 additions, 111 deletions;
- `cow_namespace_redirect.go`: 257 additions;
- two production files, 527 raw additions and 111 deletions; and
- **503 strict nonblank, non-comment production additions**.

Offline UID/GID 20002 results match Architecture A.

## Scope conclusion

The two solutions make opposite choices about data movement, base lookup,
rename state, and commit timing, yet satisfy the same black-box contract. Both
exceed the 200-line strict effective production criterion without persistence,
concurrency, a hidden marker encoding, symlink policy, or unrelated features.

The convergence gate passes. The candidate may be promoted for submission
authoring, subject to exact-version environment, gap, fairness, and
false-positive gates after artifacts exist.
