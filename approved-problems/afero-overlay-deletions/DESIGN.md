# DESIGN.md - afero-overlay-deletions

Repo: https://github.com/spf13/afero (Go, Apache-2.0, 6.7k stars, default branch `master`).
Base: `768f1fb0e5535b77d90e44c531aacd652aabd96a` (2026-06-09).

## 1. Title

Add deletion support to the copy-on-write overlay filesystem

## 2. Shape classification

- Shape: **O-Composite-extend** (PLAYBOOK Pattern 12). The change is not a bolted-on module: it
  rewrites the whole `CopyOnWriteFs` method set plus the shared `UnionFile` directory merge, and
  every existing composite test has to survive it.
- Pass-rate target: <=40% cap, designed for the corpus mode of ~1/10. Bias to the hard edge.
- Best agent: Orion (long-horizon, commit-and-implement).
- Dominant verdict expected: MISSED_REQUIREMENT, with a REGRESSION tail on the base suite.

## 3. Public API surface

Exactly the names the tests assert.

- `NewCopyOnWriteFsWithDeletions(base Fs, layer Fs) *CopyOnWriteFs` - overlay in the new mode.
- `NewCopyOnWriteFs(base Fs, layer Fs) Fs` - unchanged signature, unchanged behaviour.
- `(*CopyOnWriteFs).Deleted() ([]string, error)` - the paths the overlay currently hides, sorted,
  slash separated, rooted at the overlay, with no entry implied by a hidden ancestor.
- `(*CopyOnWriteFs).Restore(name string) error` - drops the removal recorded at a path so the base
  entry and everything under it not recorded separately shows again; a path with no removal
  recorded reports `os.ErrNotExist`.
- `(*CopyOnWriteFs).Flatten(dst Fs) error` - writes the view the overlay shows into another Fs,
  contents and modification times included.
- Every `Fs` method on `*CopyOnWriteFs`: `Create`, `Mkdir`, `MkdirAll`, `Open`, `OpenFile`,
  `Remove`, `RemoveAll`, `Rename`, `Stat`, `Name`, `Chmod`, `Chown`, `Chtimes`.
- `(*CopyOnWriteFs).LstatIfPossible(name string) (os.FileInfo, bool, error)`.
- Error values the tests match on: `os.ErrNotExist` inside `*os.PathError`, `syscall.ENOTEMPTY`
  inside `*os.PathError`, and (old mode only) `syscall.EPERM`.

No new exported type. `CopyOnWriteFs` keeps unexported fields so the existing tests that build
`&CopyOnWriteFs{base: x, layer: y}` still compile and still get the old mode.

## 4. Canonical output form

- Directory listings: merged layer + base, sorted by name (byte order), the layer entry standing
  in for a base entry of the same name. Applies to `Readdir`, `Readdirnames`, both modes, and to
  directories that exist in only one of the two layers.
- Listings never contain the bookkeeping the layer keeps for removals.
- `Deleted()`: sorted, slash separated, rooted at the overlay, descendants of a hidden path pruned,
  empty (non-nil error nil) when nothing is hidden or when the overlay is in the old mode.
- Hidden path errors: `*os.PathError{Op: <op>, Path: name, Err: os.ErrNotExist}`.
- `Remove` on a non-empty directory: `*os.PathError{Op: "remove", Path: name, Err: syscall.ENOTEMPTY}`.
- Re-created file: empty, layer-owned. Re-created directory: empty, base contents hidden for good.
- Directories the overlay puts in the layer for its own sake carry the base directory's permissions
  and modification time; a directory the caller makes carries the caller's permissions.
- Removing a directory leaves the removals recorded under it in place.

## 5. Blind-spot pre-empts

- Result list ordering -> "sorted by name" stated for listings and for `Deleted()`.
- Adjacent vs all-positions -> "a path is hidden whenever any directory above it is hidden".
- Dedup / collision -> "an entry in the layer stands in for one of the same name in the base".
- Unstated inverse -> "a removed path can be made again, and nothing of the base comes back".
- Falsy-on-invalid -> hidden paths report `os.ErrNotExist` inside `*os.PathError`.
- Codebase-inferable requirements: 1 (that the old mode keeps returning `syscall.EPERM`, which the
  existing source states in its own comments).

## 6. Description draft

See `meta.md`. Plain prose, 5 paragraphs, no headers, ASCII only, every signature pinned.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Reason |
|---|---|---|---|---|
| MODIFY | `copyOnWriteFs.go` | 332 | +186 | every method gains visibility handling; new constructor; `Deleted`; `Remove`/`RemoveAll`/`Rename` rewritten |
| NEW | `overlayDeletions.go` | - | +471 | the record store: marker naming, hide/unhide, ancestor walk, merged visible view, pruning, `Deleted`, `Restore`, `Flatten` |
| NEW | `overlayDir.go` | - | +162 | filtering directory `File` wrapper + recursive copy-up used by `Rename` |
| MODIFY | `unionFile.go` | 337 | +4 | deterministic sorted merge |

TOTAL (measured): 942 raw / 595 human-effective across 2 modified + 2 new files.

## 8. Solution outline - pure-function helpers

- `deletionMarkerPath(name) string` <- bookkeeping is invisible
- `directorySealPath(dir) string` <- a re-created directory keeps base contents hidden
- `(*CopyOnWriteFs).hidden(name) (bool, error)` <- "hidden whenever any directory above it is hidden"
- `(*CopyOnWriteFs).recordRemoval(name) error` <- removal written into the layer
- `(*CopyOnWriteFs).clearRemoval(name) error` <- "a removed path can be made again"
- `(*CopyOnWriteFs).sealDirectory(dir) error` <- "base contents underneath stay hidden for good"
- `(*CopyOnWriteFs).mergedInfos(dir) ([]os.FileInfo, error)` <- merged sorted view, used by listings and by `Remove`'s ENOTEMPTY
- `(*CopyOnWriteFs).mkdirAllInLayer(name, perm) error` <- revive and seal every removed directory along a path
- `(*CopyOnWriteFs).Deleted() ([]string, error)` <- sorted and pruned report of hidden paths
- `(*CopyOnWriteFs).Restore(name) error` <- cancel a recorded removal
- `(*CopyOnWriteFs).flattenPath(dst, name) error` <- write the visible view into another Fs
- `(*CopyOnWriteFs).ensureLayerDir(name) error` <- overlay-owned directories shadow the base ones
- `(*CopyOnWriteFs).mirrorBaseDir(dir) error` <- "keeps the permissions and modification time the base gives it"
- `(*CopyOnWriteFs).pruneLayer(name) error` <- "removing a directory does not undo the removals recorded under it"
- `(*CopyOnWriteFs).materializeSubtree(name) error` <- `Rename` of a base file or directory tree
- `defaultUnionMergeDirsFn` (modified) <- canonical listing order for every `UnionFile`
- `overlayDir` + `(*CopyOnWriteFs).asDirectory(name, lfile, bfile)` <- listings never show bookkeeping

No fixpoint loop; the ancestor walk is a bounded upward loop from the path to the root.

## 9. Test file outline

Path: `overlaydel<hash>/overlay_deletions_<hash>_test.go`, external package importing
`github.com/spf13/afero`, so a base-mode build failure cannot take the root package with it.

- Block 1 - imports
- Block 2 - builder helpers: `newOvlBase`, `newOvlOverlay`, `writeOvlFile`, `readOvlFile`
- Block 3 - assertion helpers: `requireOvlNotExist`, `requireOvlNames`, `requireOvlDeleted`
- Block 4 - buckets:
  - remove a base-only file / directory / nested tree
  - remove a path present in both layers
  - hiding across `Stat`, `Lstat`, `Open`, `OpenFile`, `Chmod`, `Chown`, `Chtimes`, `Rename`
  - ancestor hiding, deep descendants never enumerated
  - re-creation: file empty, directory empty and sealed for good
  - `ENOTEMPTY` vs `RemoveAll`
  - persistence across a fresh overlay over the same layer
  - listings: merge, sort, layer-wins, no bookkeeping, single-layer directories
  - `Deleted()`: sorted, pruned, empty in old mode
  - `Rename` from the base, file and directory tree
  - old-mode regression: `EPERM` still returned, `Deleted()` empty

Delivered: 235 test functions.

## 10. Forced signatures

Go compile coupling is the fake-difficulty risk. Pinned in `meta.md`:
`NewCopyOnWriteFsWithDeletions(base Fs, layer Fs) *CopyOnWriteFs`, `Deleted() ([]string, error)`,
`Restore(name string) error` and `Flatten(dst Fs) error`. Nothing else new is exported, so nothing
else can be guessed wrong.

## 11. Trap matrix (MEASURED, not predicted)

Every trap below was mutation-proven: the natural-but-wrong implementation was written into a
scratch copy of the reference and the suite re-run. The count is how many of the 235 tests that
mutation breaks. A trap with a count of 0 is a dead test, not a trap.

| # | Natural-but-wrong implementation | Kills | Why it misdirects | Contract sentence |
|---|---|---|---|---|
| 1 | `Remove` drops the layer copy and stops, so the base copy resurfaces | **12** | `layer.Remove` returns nil; the wrongness only shows at a later `Stat` or listing | "Whatever the layer holds for it is dropped and the removal is written into the layer" |
| 2 | A directory made again lets the base children back | **11** | the failing assertion is about a child reappearing somewhere else, not about the directory | "a directory made there is empty and keeps the base contents under it hidden for good" |
| 3 | Only the path itself is checked for a removal, not the directories above it | **7** | a deep descendant nobody enumerated is still there | "a path is hidden whenever any directory above it is" |
| 4 | The layer directory that holds the bookkeeping is created with default permissions | **5** | the failing assertion is `Stat(parent).Mode()`, which has nothing to do with deletion | "a directory the overlay puts in the layer for its own sake keeps the permissions and modification time the base gives it" |
| 5 | `Deleted` dumps the record set without pruning | **3** | only shows once a nested removal and an outer one coexist | "no entry for a path only out of sight because a directory above it is" |
| 6 | Removing a directory wipes the layer subtree, records included | **3** | surfaces two operations later, at `Restore` | "Removing a directory does not undo the removals recorded under it" |
| 7 | The merged listing keeps map or append order | **3** | | "sorted by name" |
| 8 | `Rename` copies the tree but leaves the source visible | **3** | the destination is correct, so the move looks done | "records the source as removed" |
| 9 | `Remove` judges a directory empty from the layer alone | **2** | | "`Remove` on a directory that still shows an entry fails with `syscall.ENOTEMPTY`" |
| 10 | `O_CREATE` on a hidden base file falls through to copy-up | **1** | the write succeeds and the file holds the old base bytes | "a file made there starts empty and holds only what the layer writes" |
| 11 | The merged listing trusts layer entries without re-checking them | **1** | a directory the layer only keeps for bookkeeping shows up as an entry | "never the bookkeeping the layer keeps for removals" |

Traps 1-4 are interdependent: the record-clearing that fixes 2 is what makes 10 bite, `hidden` is
the single predicate behind 1, 2, 3 and 11, and the directory creation behind 4 sits inside the
code path that records the removal for 1.

Two candidate traps were mutation-proven DEAD and are recorded so they are not re-invented:
handing back the raw layer handle for a directory that exists only in the layer (0 kills - such a
directory can never hold bookkeeping, because a removal is only recorded where the base has the
path), and stripping bookkeeping names from the layer listing (0 kills - the per-entry visibility
check already covers it).

## 12. Tier + category

- Tier: Olympus. Sub-rank: Good/Excellent.
- Category: **enhancement** (rewrites an existing subsystem; the one new constructor is a mode on an
  existing type, not a new subsystem).

## 13. Predicted pass rate

- Predicted 0-15% after the hardening round. Corpus levers stacked: one interdependent kernel (the visibility decision) driving
  every method (lever 1); exact-output listings and `Deleted()` (lever 2); five misdirecting traps
  (lever 3); "the obvious code is wrong" on trap 1 and trap 4 (lever 4); an obscure corner of a
  plumbing library rather than a famous spec (lever 5); 4 files, ~595 raw (lever 6).
- Solvability: the feature is conceptually reachable (an overlay with deletions), so at least one
  strong agent should land it; the tail traps are what hold the rate down.

## 14. Quality gate

- [x] Repo understanding: architecture, subsystems, entanglement zones, test framework, template file
- [x] Existing PR / issue check: no PR or issue covers overlay deletions (searched
      `copyonwrite|cow|union|delete|remove|whiteout|overlay|layer` across all PRs and issues;
      issue #565 is a closed user question with no maintainer position)
- [x] Corpus recipe: one kernel, exact output, >=3 interdependent+misdirecting traps, obvious-code-is-wrong
      edge, every new signature pinned, not a famous portable spec
- [x] Canonical form spelled out
- [x] <=1 codebase-inferable requirement
- [x] Description: plain prose, ASCII, no headers
- [x] File footprint sketched against real source
- [x] 1+ helper per described behaviour
- [x] Test outline: 4 blocks, scenario-encoded names, 5-axis coverage
- [x] Feature is not pattern-followable, not in any approved or rejected folder

### Why this is not a duplicate

Nothing in `Aprroved/`, `problems/`, `rejected/`, `Hagora/` or the Olympus dirs touches afero or any
union / overlay / copy-on-write filesystem; `go-diskfs` (filesystem *images*) and `fjall` / `redb`
(storage engines) are different subsystems and different feature classes. The closest shape in the
approved corpus is `surrealkv-merge-operator` (a write path that must ride an existing layered read
path); this differs in subsystem, in trap category (visibility and listing merge rather than merge
folding) and in public surface.

Predicted iteration cycles: 2.
