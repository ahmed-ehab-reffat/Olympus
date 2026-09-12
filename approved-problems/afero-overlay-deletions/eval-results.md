# eval-results - afero-overlay-deletions

No platform batch has been run yet. Local validation only.

## Local validation

| Check | Command | Result |
|---|---|---|
| Vanilla suite, base image, offline | `go test ./...` in `olympus-base-go`, `--network none`, `--user 1000:1000` | 5 packages ok, exit 0, twice identical |
| Base suite, base commit + test.patch | `./test.sh --output_path X base` | 176 nodes, 0 failures |
| New suite, base commit + test.patch | `./test.sh --output_path X new` | 235 nodes, 235 failures (F2P) |
| Base suite, both patches | `./test.sh --output_path X base` | 176 nodes, 0 failures (no regressions) |
| New suite, both patches | `./test.sh --output_path X new` | 235 nodes, 0 failures |
| Patch apply, test then solution | `git apply` on a pristine base checkout | clean |
| Patch apply, solution then test | `git apply` on a pristine base checkout | clean |
| Patch unapply | `git apply -R` both, in reverse order | clean, `git status` empty |
| Flakiness | 3 runs of each mode in the container | identical counts and identical node sets |
| Docker | built from a clean base context, run `--network none --user 1000:1000` | green |
| LOC | `effective_loc_check.py solution.patch` | 942 raw / 595 human-effective / 4 files |
| Banned markers | `grep -rniE "shipd\|datacurve" test.patch` | none |
| Encoding | `file solution.patch test.patch` | ASCII text |
| test.sh mode | `grep "new file mode" test.patch` | 100755 |
| Description | word count, ASCII scan | 472 words, pure ASCII |
| AI test-quality check | platform pre-check | R6 2 warnings fixed; R7 all four points OK, concrete-type note fixed |
| AI description-quality check | platform pre-check | R6 3 high addressed; R7 1 high (Restore contradiction) fixed |
| Test Fairness | platform check | R8 FAIL 4/104 repaired (2 via the reference); R9 FAIL 4/113 repaired (via the description); R10 clean; R11 FAIL 4/127 repaired (both gaps via the description); R12 clean; R13 clean; R14 FAIL 4/147 repaired (one root rule stated); R15 clean; R16 clean; R17 FAIL 4 groups repaired (root rule made an equivalence); R18 clean; R19 clean; R20 clean; R21 FAIL 1/180 repaired (partial-write co-assertion dropped); R22 clean; R23 FAIL 3/195 repaired (Flatten conflict policy stated); R25 desc check: 2 HIGH fixed, 2 MEDIUM declined; R26 Solution Quality FAIL repaired (visibility hole + rooted paths); R27 FAIL 5/117 repaired (failure-atomicity assertions stripped); R28 desc check: HIGH cut (pre-existing merge/precedence), sorting kept with base-repo evidence; R29 FAIL 2/27 repaired (Rename made consistent with the rebuild rule); R30 desc check: both HIGH complied, ops list + ENOTEMPTY tail cut; R31 quality warning: Op pinning dropped from prompt + suite; R32 FAIL 3/37 repaired (rename-parent branch deleted, 2 co-assertions dropped); R33 FAIL 1/59 repaired (bookkeeping-traversal test removed); R34 clean; R35 Solution Quality FAIL repaired (skippable tests removed, hidePath made record-first); R36 two / 4 tests, no prompt or reference change; R37 restored the 7 symlink tests deleted in R35 (harness expects prior-revision test names); R38 desc check: no HIGH, constructor line folded into the opening, 4 declined; R39 two / 4 tests (Restore error shape declined); R40 5/5 Nova failed one unstated rule (file branch), stated in one sentence; R41 desc HIGH complied (exception moved, not dropped) + 3 advisories / 5 tests |
| Coverage advisories | platform check | R8 four areas / 9 tests; R9 three / 8 tests; R10 three / 7 tests; R11 three / 5 tests; R12 three / 5 tests; R13 three / 10 tests; R14 two / 1 test + 2 strengthened; R15 two / 5 tests; R16 two / 6 tests; R17 two / 4 tests + a Flatten fix; R18 two / 4 tests + a Flatten metadata fix; R19 two / 6 tests (atomicity declined); R20 three / 8 tests; R22 three / 12 tests + a readlink fix; R23 one / 2 strengthened; R25 three / 10 tests (symlink declined); R31 three / 5 tests (symlink declined again); R33 three / 9 tests + 2 reference bug fixes; R34 two / 4 tests (partial-state doc declined) |

## Per-agent runs

### Batch 1 (2026-07-29) - 0/5, STALE after the R24 prompt fix

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|---|---|---|---|---|---|---|---|
| Orion | Nova | FAIL_MISSED_REQUIREMENT | 80 | 4 | 1638 | `RemoveOfTheRootSucceedsOnceItIsEmpty`, `FileMadeUnderARemovedAncestorUsesTheCallersPermissions` | 190/192 passed; root `Remove` returns EPERM when empty, `O_CREATE` refused under a deleted ancestor |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 56 | 1136 | 3711 | `ExclusiveCreateSucceedsAtAHiddenPath`, `RecreatedFileUsesTheCallersPermissions`, `RecreatedEmptyFilePersistsAcrossAFreshOverlay`, `RecreatedFileWithoutTruncateStartsEmpty`, `FileMadeUnderARemovedAncestor...` | recreation either revives base contents or refuses creation |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 61 | 2323 | 7824 | create under a removed ancestor | `deletedPath(dir)` check returns not-exist instead of materialising the parent |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 61 | 1141 | 5044 | `FileMadeUnderARemovedAncestor...`, `RecreatedDirectoryKeepsDeepBaseChildrenHidden` | recreation under a removed dir fails, or deep base entries reappear |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 49 | 2 | 1178 | hidden-ancestor recreation, hidden rename destination `Op` | `ensureLayerDir` returns not-exist for a hidden parent; `Rename` leaks `Op=mkdir` |

Shared cause in 5 of 5: creation beneath a removed ancestor. Evaluators rated the prompt clear and
the requirement stated (`description_clear: true`, `was_mentioned_in_description: true`, difficulty
"challenging"), but 0% rejects regardless - the inference was two hops and every agent stopped at
POSIX "parent gone, ENOENT". Prompt amended in R24 to state it in one hop. This batch is stale.

Capture every passing agent's diff into `afero-overlay-deletions/agent-runs/<batch>-<run>.patch`
while the platform run view is open; the differential harness, the trap proof, FP verification and
the leanest-passer LOC all need the real patches.

## Trap proof (run before the first batch)

Each row is a natural-but-wrong implementation written into a scratch copy of the reference; the
count is how many of the 235 tests it breaks. Full table in `DESIGN.md` section 11.

| Mutation | Kills |
|---|---|
| `Remove` drops the layer copy only, base copy resurfaces | 12 |
| a directory made again lets base children back | 11 |
| removals are not inherited by descendants | 7 |
| bookkeeping directories created with default permissions | 5 |
| `Deleted` without pruning | 3 |
| removing a directory wipes the records under it | 3 |
| merged listing not sorted | 3 |
| `Rename` leaves the source visible | 3 |
| `Remove` judges emptiness from the layer alone | 2 |
| `O_CREATE` on a hidden base file copies the base bytes up | 1 |
| merged listing trusts layer entries | 1 |
| records kept in a Go map instead of the layer | 78 |
| `Flatten` drops modification times | 1 |
| `Flatten` drops directory modification times | 1 |
| `Flatten` swallows every destination error | 1 |
| `Deleted` emits raw uncleaned paths | 13 |
| `Rename` revives a hidden destination parent | 1 |
| hidden check dropped from one non-Stat operation | 3 |
| `Restore` refuses while an ancestor is removed | 10 |
| `Rename` keeps bookkeeping in the moved tree | 1 |
| `Rename` copies base children instead of the visible view | 3 |
| error names the hidden ancestor instead of the requested path | 14 |
| `Rename` refuses an existing destination | 4 |
| `Deleted` also reports directories made again | 2 |
| rename copy-up drops the file mode | 2 |
| `Flatten` drops file permissions | 2 |
| `Flatten` drops directory permissions | 1 |
| materialized directory loses base metadata | 6 |
| `Flatten` skips an existing destination entry | 1 |
| `Restore` keeps the record instead of dropping it | 10 |
| root removal marks the root instead of its children | 4 |
| `Rename` refuses a cross-kind destination | 2 |
| `Flatten` mutates the overlay while writing | 15 |
| hidden rename destination returns a bare error | 1 |
| recreation ignores the caller's file permissions | 3 |
| root removal kept only in memory | 6 |
| materialized ancestors lose the base mtime | 5 |
| `ENOTEMPTY` returned bare, without a wrapper | 1 (was 3 before the R30 pullback) |
| `Flatten` leaves a wrong-kind destination entry | 1 |
| recreation leaves the record behind | 7 |
| root `RemoveAll` records the root, not each child | 6 |
| `Flatten` does not force file permissions | 1 |
| `Flatten` does not force directory permissions | 1 |
| hidden rename destination names the source | 1 |
| `Rename` does not record the source removal | 10 |
| `Flatten` disturbs the overlay on failure | 1 |
| metadata change skips copy-up (per site) | 1-2 each |
| `Flatten` swallows a deep child error | 4 |
| readlink guard removed | 2 |
| readlink returns a bare sentinel | 2 |
| `Flatten` drops conflict replacement | 1 |
| removal swallows the bookkeeping write error | 2 |
| listing stops deduping layer over base | 10 |
| layer file no longer hides what is under it | 3 |
| `Rename` refuses a hidden destination again | 2 |
| `Deleted` swallows layer read failures | 0 (not pinnable; test removed R33) |
| self-rename destroys the file | 2 |
| rebuilt directories keep 0777 | 1 |

| `Flatten` ignores directory metadata failures | 1 |
| flattened directories get 0777 | 5 |
| flattened directories lose their mtime | 4 |
| `Flatten` swallows a source read failure | 7 |
| `Flatten` treats a linked directory as a link | 1 |
| `Rename` treats a linked directory as a file | 1 |
| `Readdir` never reports `io.EOF` | 4 |
| `Readdir` ignores its cursor | 4 |
| paths not rooted at the overlay (unprovable on MemMapFs) | 0 |
| `O_EXCL` observes hidden base existence | 2 |
| marker path keyed without cleaning | 48 |
| Restore keys off the raw name (unprovable) | 0 |

The last row is the FP discriminator: an implementation that keeps state in memory rather than in
the layer fails almost the whole suite, so a passing run cannot have skipped that requirement.

Two mutations scored 0 and their traps were retired rather than shipped as dead tests: the raw
layer handle for a layer-only directory, and stripping bookkeeping names from the layer listing.

## Watch items for the first batch

- Which of the eleven traps actually bite a real agent. Mutation kills say a test discriminates
  against a WRONG implementation; they say nothing about whether agents ever write that one. The
  two to watch are trap 4 (directory permissions and modification time around a removal) and trap 6
  (removals surviving under a removed directory), because both surface far from their cause.
- Whether any agent regresses the 176 base nodes. The rewrite touches `Open`, `OpenFile`,
  `isBaseFile` and the shared `UnionFile` merge, all of which the existing composite tests cover.
- Whether the sorted-listing requirement is picked up for single-layer directories, not only for
  the merged case.
- False positives: the in-memory-records mutation breaks 78 of 235 tests, so a passing run cannot
  have skipped the "written into the layer" requirement. Still check each passing diff for the
  metadata rule, which is the one requirement a solution could satisfy by accident on a backend
  that happens to preserve modes.

## FP adjudication (2026-07-28)

Passing Nova run ruled a FALSE POSITIVE: `Deleted()` pruned against the previous kept path instead
of the last kept ancestor, so a sibling sorting between an ancestor and its descendant (`/data`,
`/data-backup.txt`, `/data/deep/inner.txt`) let the descendant through. Description already required
"never an entry under another it reports"; the suite only had adjacently-sorting removals.

Two interleaving-sibling tests added, 235 -> 237. Mutation proof: the agent's exact bug fails both
new tests and ZERO old ones. Reference needed no change.

Also fixed: `go-junit-report` is at `/opt/go/bin` and not on PATH, and the Dockerfile never
installed it, so base mode exited 141 with an empty XML. Dockerfile now installs it to
`/usr/local/bin`; base mode is 176 cases / 0 failures.
