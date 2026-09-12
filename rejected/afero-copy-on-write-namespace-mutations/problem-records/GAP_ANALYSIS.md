# Gap analysis — Afero copy-on-write namespace mutations, version 3

Verdict: `pass`.

Repository: `spf13/afero` at
`768f1fb0e5535b77d90e44c531aacd652aabd96a`.

Artifact identifiers: prompt
`7c54baa9a4250d090542bc73a866b8c9f87dd869a13b8791768a5a260ff4af8a`,
test patch
`0d882efc4555640ebeba57de65c64de300690ba5c1b1047ffeaeb4a1201b4cd1`,
reference
`65939f4dc645bb3407d00b8a644e521b3a38e0b42ebbc97074fbb31debbf90a1`,
Dockerfile
`33c69a5c4ac80b747abb40dcd63c8fbbb29f96476ea1b8189fc14af7d66fc72f`,
reference combined tree `df3a8a2ae2cb3ceef4091404d7a744793663c75d`,
and redirect combined tree `5b9d2f7a6c81d46650236908661b9c8e29d30953`.

## Atomic requirement map

| Public obligation | Qualifiers and independent dimensions | Strongest test | Coverage |
|---|---|---|---|
| `Remove` hides a successful deletion from lookup and enumeration | base-only, layer-only, and overlapping regular files; base-only empty directory | `TestCopyOnWriteNamespaceRemoveAndRecreate` | direct |
| removing a missing name reports not-exist | second removal of an already hidden lower file | `TestCopyOnWriteNamespaceRemoveAndRecreate` | direct |
| removing a non-empty logical directory fails without changing it | merged directory and independently base-only directory | `TestCopyOnWriteNamespaceRemoveAndRecreate` | direct |
| namespace mutations leave the base unchanged | exact files, empty directory, recursively removed subtree, renamed source and replaced destination | remove/recreate, merged replacement, upper-shadow, and base-only rename tests | direct |
| `RemoveAll` hides the whole logical subtree and is nil on absence | mixed base/upper subtree, base-only subtree, absent name | `TestCopyOnWriteNamespaceRemoveAndRecreate` | direct |
| recreation does not resurrect lower children | `Mkdir`, `MkdirAll`, and regular-file recreation after exact or recursive removal | `TestCopyOnWriteNamespaceRemoveAndRecreate` and state lifecycle | direct |
| `Rename` moves the complete logical source | base-only regular file and directory, layer-only directory, overlapping file, merged nested directory | failure/commit, upper-shadow, merged replacement, and base-only repeated-rename tests | direct |
| same-kind destination replacement exposes only the moved source | regular file and merged directory; stale base-only and layer-only destination children | `TestCopyOnWriteNamespaceUpperShadowRename` and `TestCopyOnWriteNamespaceRenameMergedReplacement` | direct |
| rename preserves contents, modes, and directory structure | nested regular files, merged children, `0750` directory and `0600` file | merged replacement, state lifecycle, and base-only mode tests | direct |
| deletion and opacity state move with the source | deleted child, recursively removed/recreated child, two consecutive renames | `TestCopyOnWriteNamespaceRenameStateLifecycle` | direct |
| cleaned path spellings share namespace state | remove and rename aliases on independent OS-backed roots | `TestCopyOnWriteNamespaceOsBackendsAndCleanPaths` | direct |
| a reported pre-commit layer error either leaves views unchanged or the operation succeeds completely | early all-operation failure and a later second-rename failure after destination staging | `TestCopyOnWriteNamespaceFailurePreservesOrCommits` | direct |
| bookkeeping is not visible | exact and one-entry-paged directory sets plus missing-name lookup across mutation lifecycles | remove/recreate, merged replacement, state lifecycle | direct |

## Equivalence classes and weak cells

| Dimension | Grouped equivalent cells | Separate repository branches | Weak or uncovered cell | Evidence |
|---|---|---|---|---|
| backend | `MemMapFs` supplies deterministic logical-state coverage | `BasePathFs(NewOsFs())` changes path/root translation and real OS errors | none in scoped regular-file/directory behavior | the OS alias lane and both legitimate architectures pass |
| source producer | upper-only file and directory operations share the existing layer backend | base-only copy/redirect and merged recursive enumeration are independent | none | explicit layer-only, base-only, overlapping, and merged cases |
| object kind | file content checks are grouped across producer modes | directory emptiness, recursion, opacity, and mode require separate branches | none | both kinds are directly exercised |
| removal kind | exact file deletion and empty-directory deletion share exact hiding | non-empty rejection and recursive opacity are independent | none | separate `Remove` and `RemoveAll` oracles |
| rename lifecycle | one rename establishes ordinary relocation | replacement, moved deletion state, and a second rename have independent state transitions | none | separate replacement and repeated-rename tests |
| failure point | failures before staging are equivalent once no public mutation occurred | failure after destination backup requires restoration | backend partial-mutation-after-error | intentionally excluded because the public `Fs` contract does not promise an operation both mutates and reports failure |
| interfaces | `Stat`, `Open`, and directory iteration are the stated public observations | optional symlink interfaces cannot portably relocate cross-root targets | symlink relocation | explicitly outside the prompt after prototype evidence |

## Gap trials

| Plausible incorrect implementation | Focused result | Full-suite result if needed | Targeted probe result | Decision |
|---|---:|---:|---:|---|
| delegate `Remove` only to the layer | 4/7 | not escalated | overlapping/base-only removals fail | retained discriminator |
| delegate `Rename` only to the layer | 1/7 | not escalated | base-only, merged, replacement, alias, and state moves fail | retained discriminator |
| clear opacity when recreating a directory | 5/7 | not escalated | old lower children reappear after recreation and relocation | retained discriminator |
| omit destination opacity during directory replacement | 6/7 | not escalated | stale lower destination child remains visible | retained discriminator |
| omit source hiding after rename | 1/7 | not escalated | source lower entries reappear | retained discriminator |
| key state by raw caller paths | 6/7 | not escalated | cleaned-path OS lane disagrees | retained discriminator |
| discard original modes while materializing | 6/7 | not escalated | base-only repeated-rename mode check fails | retained discriminator |
| return nil from missing `Remove` | 6/7 | not escalated | second removal rejects the shortcut | retained discriminator |
| skip non-empty logical-directory validation | 6/7 | not escalated | base-only and merged non-empty removal rejects the shortcut | retained discriminator |
| omit destination restoration after the second backend rename fails | 6/7 | not escalated | later-stage snapshot loses destination entries | retained discriminator |

## Rejected gap candidates

- A mutation that leaves an exact tombstone after a same-name upper file is
  recreated passes because the upper file is still the complete observable
  view. Requiring deletion of that private state would prescribe an encoding.
- Marking a lower shadow hidden before a failed removal is observationally
  equivalent when the failed backend operation leaves the upper entry intact.
  A backend that deletes and then reports failure is not a stable `Fs` semantic
  on which to prescribe rollback.
- Additional path-spelling permutations, page sizes, or marker-like filenames
  add fixtures without a new semantic boundary.
- Durable reconstruction, concurrent mutation, cross-layer symlink relocation,
  and cross-kind rename replacement are outside the frozen public contract.

## Final coverage statement

Every atomic in-scope obligation has a direct black-box discriminator across
the repository-grounded producer modes, object kinds, lifecycle states, and
the memory/OS backend boundary. The final pristine tree fails all seven focused
tests; the reference and independent redirect architecture pass all seven plus
176 pre-existing cases. This pass is evidence for the mapped cells and the
attempted mutants, not proof that no future plausible gap exists.
