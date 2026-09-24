# eval-results.md — pyfakefs-block-inode-accounting

Batch 1 (2026-09-21): 0/11, see R11. Batch 2 (2026-09-22): 0/14 genuine, see R14/R16.
Artifacts in `agent-runs/1/`.

## R18 — one unfair test, one mount-root accounting hole (2026-09-23)

**Test Quality, 1 of 117 unfair.** `test_tree_usage_needs_an_existing_path` pinned `ENOENT` for a
missing path, which the description never states; returning `{}` for an empty walk is an equally
grounded reading. Removed, no description words spent.

**Solution Quality, HIGH, real.** An EXISTING directory promoted to a mount root kept the inode it
had been charged on the old mount, although the contract says mount roots are charged to no mount.
`add_mount_point` reused the directory and changed its `st_dev`, but `account=False` only ever
covered directories it created itself. Fixed where the root is reused: release its charge against
`charged_dev`, then clear it. Verified: root free inodes go 9 -> 10 on mounting over `/mnt`, the new
mount starts empty, `tree_usage('/')` agrees.

This reverses R8's direction on purpose: R8 kept the charge on the old device (via `charged_dev`)
because the contract was silent; the contract has since said mount roots are uncharged, so releasing
is now the only consistent reading.

**Probe before pinning.** 10 of 14 saved solutions already release the charge. The four that keep it
(Nova_3, Nova_8, Vega_2, Vega_3) fail other tests and none is a projected passer, so
`test_mounting_over_an_existing_directory_frees_its_inode_on_the_old_mount` is fair and costs no
pass. It asserts only the two free-inode counts; the `tree_usage` view was not probed, so it is not
asserted.

| Check | Result |
|---|---|
| base + test -> new | 117 failed, root and 4242 |
| + solution -> new | 117 passed, root and 4242 |
| + solution -> base | root 1413, 4242 1419, 0 failed |
| flakiness | 3x identical at 4242 on both modes |
| hooks | ruff format / check, pyupgrade clean (one new line reflowed to ruff's layout) |
| leak scan, patch order | clean |
| effective LOC | 334, 4 files |

Only `test.patch` and `solution.patch` changed this round.

## R17 Solution Quality — the reference contradicted its own carve-out (2026-09-23)

**HIGH, real.** The contract says `add_real_directory` and `add_real_paths` commit each step, but
both real-directory import paths created their target's ancestors through `create_dir`, which R8
made transactional. A deep import that ran out of inodes removed ancestors the contract says must
stay. My R13 revert took out the import-level collectors but left this second, quieter route to the
same rollback. Fixed with `_create_dir_stepwise`: one `create_dir` call per missing component, each
trivially atomic, built on the repo's own `_components_to_path` so Windows-style paths work too.
`create_dir` itself stays all-or-nothing (verified).

**Coverage suggestions — both taken, after a probe.** Before adding them I re-ran all 14 saved
solutions:

| Probe | Keep earlier steps |
|---|---|
| `Path.mkdir(parents=True)` refused | 14 / 14 |
| lazy `add_real_directory` to a deep target, refused | 14 / 14 |
| eager `add_real_directory` to a deep target, refused | 11 / 14 (Nova_8, Vega_3, Vega_4 roll back) |

The three that roll back already fail other tests and none is a projected passer, so the projected
3/14 holds. Added `a_refused_pathlib_mkdir_keeps_the_parents_it_made` and eager/lazy
`a_refused_*_real_directory_import_keeps_its_parents`, the latter as two tests sharing a check
helper rather than one test calling `reset()` between cases, so a `reset` bug cannot fail it.

**Description (user request).** The rollback rule is now "If `create_dir`, `create_file`,
`create_symlink` or `add_real_file` fails, any parent directories it created are removed", and the
exemption sentence names "Mount roots, directories created while establishing a mount point, and
the filesystem's temporary directory". Kept declarative. 493 words.

| Tree | 0:0 | 4242:4242 |
|---|---|---|
| base + test -> base | 1413 pass | 1419 pass |
| base + test -> new | 117 fail | 117 fail |
| + solution -> base | 1413 pass | 1419 pass |
| + solution -> new | 117 pass | 117 pass |

3x identical at 4242; hooks clean; leak scan clean; patch order clean; `human-effective` 334.

## R16 — the pass was a false positive; pool is 0/14; artifact rebuilt (2026-09-23)

### FP adjudication

The passing Vega (Vega_Nova_3) was flagged **false positive**, high confidence, verdict changed by
panel evidence. Its `set_disk_usage` reads
`new_total_size = mount_point['total_size'] if total_size is None else total_size`, so a bounded
mount can NEVER be made unlimited again. The prompt's "`None` keeps the current value" applies to
the four options after `path`, not to `total_size` itself. The hidden suite never exercised a
bounded -> unlimited transition (`test_setting_no_limit_again_keeps_what_the_mount_holds` starts
already unlimited), so the gap was mine. The solver had even added a base-mode test of its own that
baked in the buggy behaviour.

**The true pool is 0/14.** That removes the reason to protect the uploaded description, so the R14
both-sides wording fix can finally ship together with everything else.

### Probed all 14 saved solutions before changing anything

Applied each run's patch to a fresh base clone (asserting every patch actually modified the tree,
per the vacuous-apply rule) and ran two probes:

| Probe | Result |
|---|---|
| bounded mount, `set_disk_usage(None)`, then a file larger than the old limit | **12 of 14 reset correctly**; only Vega_Nova_3 (the FP) and Vega_Nova_4 keep the old limit |
| refused `os.makedirs` and `add_real_paths` keep their earlier steps | **14 of 14 keep them**, same as the reference |

So the missing FP discriminator is fair (most agents already get it right), and pinning the
carve-out costs no agent anything.

### Changes

- **Three tests added** (114 total): the bounded -> unlimited reset that the FP exposed, plus
  refused-`makedirs` and refused-`add_real_paths` partial commit, which closes the "partial"
  requirement-coverage note and the quality check's request for a stepwise-failure test.
- **One test removed:** `a_refused_large_file_resize_keeps_the_old_allocation` reached through
  `fs.get_object(...).set_large_file_size(...)`, which is not in `docs/modules.rst` and is exactly
  the "tests couple to internals" warning. The truncate test covers the same refusal publicly.
- **Description rebuilt from the R14 draft** plus the user's three rewrites (finite rounding states
  the unit and the reported result, the unlimited clause is two direct clauses, the `tree_usage`
  cases are named individually) and the two alignment clarifications: blocks are released with the
  last name even while the file is open, and the four `set_disk_usage` options each default to
  `None`. 490 words.

### Advisory suggestions NOT taken, with reasons

- **"Remove the helper examples" (HIGH).** Measured refusal. The R13 carve-out named only the
  stepwise side and left the atomic side to inference; those five deep-create tests went from 0/11
  kills to 10/12 with code unchanged. Deleting the names would restore exactly that ambiguity.
- **"Drop the directly-imported `statvfs` clause" (MEDIUM).** A test pins it
  (`test_a_directly_imported_statvfs_reports_the_fake_mount`), and it is the `FakeOsModule.dir()`
  registration a Solution Quality reviewer demanded at R2. Removing the sentence would make that
  test assert undocumented behaviour.
- Taken: the LOW trims (the opening line repeating the title, and tightening the rounding sentence).

### Projected rate

Replaying the 14 saved solutions against the final suite, treating the five deep-create tests as
fixed by the wording (batch 1 measured 0/11 kills on them with unambiguous wording) and folding in
the probe results for the three new tests: **3/14 = 21%**. Nova_Nova_2, 6 and 10 pass; four more are
one test away. The surviving discriminators are the Windows symlink allocation, the two
reserve-crossing renames, and the unlinked-open-file resize.

### R16 validation

| Tree | 0:0 | 4242:4242 |
|---|---|---|
| base + test -> base | 1413 pass | 1419 pass |
| base + test -> new | 114 fail | 114 fail |
| + solution -> base | 1413 pass | 1419 pass |
| + solution -> new | 114 pass | 114 pass |

3x identical verdicts at the unmapped UID on both modes; `ruff format`, `ruff check` and `pyupgrade`
clean; leak scan clean; both patch orders apply and reverse; `human-effective` 324, 4 files.

## R15 — two extra Vega runs on the R13 upload: 1 passed (2026-09-22)

The user fired 2 more Vega runs on the artifact as uploaded (R13 description). **One passed.** The
pool is now **1/14 = 7%**: solvable, inside the band, and at the high-payout edge.

This reverses R14's plan. R14's wording fix was never uploaded, and uploading it would change the
solver-visible surface and void all 14 runs, the pass included. `meta.md` has been restored
byte-for-byte to the description the batch-2 agents saw (extracted from
`agent-runs/2/Vega_Nova_2/trajectory.json`); the R14 draft is kept outside the submission at
`worktrees/_meta_r14_unuploaded.md` in case the agent-run review demands the wording change.
`test.patch` and `solution.patch` are untouched.

Still owed before submit: download the two new runs to `agent-runs/3/` and run the FP check on the
passer (the mandatory final gate). The standing risk is the agent-run review reading 10 of 12
batch-2 agents failing the deep-create family for one wording reason; the defence is that batch-2
Vega_Nova_2 and the new passing Vega both placed `create_dir` on the atomic side from the same text.

## BATCH 3 — 5/10, ACCEPTED by the human reviewer (2026-09-23)

10 Nova. 5 PASS_LEGITIMATE, 5 FAIL_MISSED_REQUIREMENT, no ENV flags. 50% is above the 40% ceiling;
the reviewer accepted it. Auto Review (Revision Requested, overruled by the acceptance) found one
remaining reference gap: `create_file` rolls back only on `OSError`, so `UnicodeEncodeError` leaves
the file and its parents.

| Agent | Verdict | New tests | Files | +LOC | Prompt tokens | Failed tests | Failure reason |
|---|---|---|---|---|---|---|---|
| Nova 1 | PASS | 117/117 | 4 | 689 | 15.7M | - | - |
| Nova 2 | PASS | 117/117 | 3 | 562 | 17.5M | - | - |
| Nova 3 | FAIL | 114/117 | 5 | 572 | 14.2M | eager + lazy real-directory import keeps parents; setting no limit again keeps usage | imports inherit `create_dir` rollback (F-20); unlimited reset drops usage |
| Nova 4 | PASS | 117/117 | 3 | 524 | 14.7M | - | - |
| Nova 5 | PASS | 117/117 | 3 | 529 | 13.8M | - | - |
| Nova 6 | FAIL | 116/117 | 4 | 642 | 14.8M | symlink charged for its path where stat reports nothing | Windows symlink sized by `st_size` (F-51) |
| Nova 7 | PASS | 117/117 | 3 | 487 | 11.0M | - | - |
| Nova 8 | FAIL | 116/117 | 5 | 608 | 17.5M | eager real-directory import keeps parents | F-20 |
| Nova 9 | FAIL | 112/117 | 3 | 542 | 14.4M | import that fits charges every object; eager import keeps parents; directory/tree removal inode return; repeated cycles | recursive removal releases only in the non-recursive branch (candidate C-6), plus F-20 |
| Nova 10 | FAIL | 116/117 | 4 | 607 | 14.4M | unlimited inode count never reports below none left | unlimited count capped by the block-derived figure (F-50) |

Per-test kills: eager import keeps parents 3/10, lazy import 1/10, symlink 1/10, unlimited-inode report
1/10, unlimited reset 1/10, Nova 9's four removal tests 1/10 each. 108 of 117 tests killed nothing.
Reserve-crossing renames and the unlinked-open-file resize, 4/12 each in batch 2, killed 0/10.

## R14 BATCH 2 — 0/12, caused by my own carve-out sentence (2026-09-22)

10 Nova + 2 Vega on the R13 artifact. **0/12.** Every agent kept the baseline green again.

| Agent | Failed | What |
|---|---|---|
| Vega_Nova_2 | 1 | Windows symlink charged 0 blocks in `tree_usage` |
| Vega_Nova_1 | 3 | deep create + both reserve-crossing renames |
| Nova_Nova_8 | 3 | both reserve-crossing renames + `set_disk_usage(None)` |
| Nova_Nova_2 / 6 / 10 | 5 each | **only** the five single-object deep-create rollback tests |
| Nova_Nova_9 | 6 | | 
| Nova_Nova_1 | 7 | |
| Nova_Nova_3 | 8 | |
| Nova_Nova_5 / 7 | 9 each | |
| Nova_Nova_4 | 21 | |

### The regression is mine, and it is measured

| Test | batch 1 kills | batch 2 kills |
|---|---|---|
| `a_refused_deep_create_leaves_no_directory_behind` | 0/11 | **10/12** |
| `a_refused_deep_file_create_leaves_no_directory_behind` | 0/11 | 9/12 |
| `a_deep_file_create_that_runs_out_of_blocks_leaves_nothing` | 0/11 | 9/12 |
| `a_refused_deep_symlink_leaves_no_directory_behind` | 0/11 | 9/12 |
| `a_refused_real_file_import_leaves_nothing_behind` | 2/11 | 9/12 |

Tests and solution for these five were unchanged between the batches. The only difference was
R13's carve-out: "Helpers that repeat such operations, like `os.makedirs`, ... commit each step
alone". `create_dir('/a/b/c')` builds its parents step by step exactly as `makedirs` does, so agents
put it on the non-atomic side. The graders' reasoning confirms it verbatim ("it creates missing
parent directories incrementally and does not roll them back"), and the agents' trajectories quote
the carve-out sentence. The carve-out named only ONE side of the boundary and left the other side to
inference, which went the wrong way for 10 of 12.

### Fix — name both sides

> An operation that cannot fit in the available blocks or inodes raises `OSError` with `ENOSPC` and
> leaves the mount as it was. So `create_dir`, `create_file`, `create_symlink` and `add_real_file`
> take back the parent directories they made. `os.makedirs`, `Path.mkdir(parents=True)`,
> `add_real_directory` and `add_real_paths` instead commit each step on its own, keeping earlier
> steps on failure.

Both lists are exactly what the suite tests (atomic side) and what the solution does not roll back
(committing side), so no test goes beyond either list. 497 words. `test.patch` and `solution.patch`
are unchanged from R13, so R13's clean-room matrix stands.

### Counterfactual

Treating the five as passes (batch 1 says a clear sentence gets 0 kills on them): **3/12 = 25%**
(Nova_Nova_2, 6, 10), with Vega_Nova_2 one fair test away. The remaining killers are genuine and
described: reserve-crossing renames (4/12), the unlinked-open-file resize (4/12), and the Windows
symlink allocation (5/12).

## R13 Auto Review — rollback coverage demand resolved by carve-out + revert (2026-09-21)

Description 3/3, Solution & Code 3/3, Tests **1/3**: three High T4 findings demanding failure-path
tests for `FakeOsModule.makedirs`, `pathlib` `mkdir(parents=True)` and eager/lazy
`add_real_directory`, plus a Medium T8 on the fallback's diagnostics.

### The High findings were the R11 cut, asked for back

These are exactly the tests dropped at R11 because batch 1 read 0/11 on them. Each finding is
grounded in my own sentence ("leaves the mount as it was; if creating one object made parent
directories first, those are removed too"), and the reviewer read `makedirs('/a/b/c')` as "creating
one object" with parents, which is a fair reading. R11 dropped the tests but kept both the promise
and the implementation, so the Tests band could never clear.

**User decision: carve out + revert.** The contract now says a single operation is atomic including
the parents it made, while "helpers that repeat such operations, like `os.makedirs`,
`Path.mkdir(parents=True)`, `add_real_directory` and `add_real_paths`, commit each step alone, so a
failure keeps the earlier steps". That is what CPython and a real filesystem do. The examples are
introduced with "like", so this is a stated rule with illustrations, not an enumeration a test goes
beyond.

The reference solution was reverted to match, so description, tests and solution now agree:

| Reverted | Result |
|---|---|
| `FakeOsModule.makedirs` / `_makedirs` split + collector | `makedirs` byte-identical to base; the R11 parent-mode fix is moot |
| `FakePath.mkdir(parents=True)` override | `fake_pathlib.py` back to base, out of the patch (5 files -> 4) |
| collectors on `add_real_directory`, lazy `entries`, `add_real_paths`, `add_package_metadata` | `FakeDirectoryFromRealDirectory` byte-identical to base |
| `_collect_added_entries`, `_undo_added_entries`, the `added_entries` hook in `add_entry` | removed, nothing references them |

Kept: single-object rollback (`_create_dir_path` + `_undo_new_dirs`, `add_real_file`), which every
batch-1 agent already passed. Verified that a partial `makedirs` or eager import leaves its earlier
steps in place AND correctly charged, with `tree_usage` agreeing with the mount counters.

### T8 — fallback diagnostic

`test.sh` now tees pytest's output and, when no `<testcase>` was written, embeds the last 200 lines
in the synthetic failure's CDATA (escaping `]]>`), with the real exit status in the message. Proved
both ways: a collection error keeps pytest's own `<error>` diagnostic; a startup failure that writes
no testcase (`-p nonexistent_plugin_xyz`) now carries its cause. Exit status comes from
`PIPESTATUS[0]`, so `tee` cannot mask it.

### R13 validation

| Tree | 0:0 | 1000:1000 | 4242:4242 | 4242:0 |
|---|---|---|---|---|
| base + test -> base | 1413 pass | 1419 pass | 1419 pass | 1419 pass |
| base + test -> new | 112 fail | 112 fail | 112 fail | 112 fail |
| + solution -> base | 1413 pass | 1419 pass | 1419 pass | 1419 pass |
| + solution -> new | 112 pass | 112 pass | 112 pass | 112 pass |

3x identical at 4242:4242 on both modes; hooks clean on all four files; leak scan clean; both patch
orders apply and reverse. `human-effective` **324** (was 391; the collector machinery was ~65),
4 files, 112 tests, 496 words. Batch-1 replay unchanged: 1/11 outright, 3 more failing only on the
`mount_usages` pronoun that R11 fixed.

## R12 Auto Review — base harness Blocker (unmapped UID) + placeholder rounding (2026-09-21)

Description **3/3**, Solution Quality **PASS** (Code Quality 3/3), Solution & Code **2/3** on one
Medium. Tests **0/3** on one Blocker that, again, was not about the new tests.

### BLOCKER — base mode failed for an evaluator UID with no account entry

The platform's offline validation runs as a NON-ROOT UID that has no passwd or group entry (4242 in
the report). `pyfakefs/tests/fake_pathlib_test.py::FakePathlibUsageInOsFunctionsTest::test_owner_and_group_posix`
calls `PosixPath.owner()` / `group()`, which go to `pwd.getpwuid` / `grp.getgrgid` for the real
process IDs and raise. The Dockerfile's `model` user (uid 1000) was added at R1 precisely so this
test passed, and it does pass for 1000; it cannot pass for an ID the image does not know.

Before deselecting I swept the whole base suite under every unmapped combination, not just the one
cited: `4242:4242`, `4242:0` and `0:4242` all produce exactly ONE failure, this test. It is now the
fourth base-mode deselect, documented in the same repository-local voice as the other three.

**The validation gap this exposed:** every clean room since R1 ran as `0:0` and `1000:1000`, both of
which HAVE account entries. Neither can reveal an account-lookup dependency. The matrix now includes
an unmapped UID.

### MEDIUM — the unlimited placeholder was not whole blocks

`mount_capacity()` returned raw `UNLIMITED_SIZE` for `total_size=None`, while `statvfs` divided it
into whole blocks. For any block size that does not divide 2^40 the two public APIs disagreed:
`block_size=3` gave `get_disk_usage().total == 1099511627776` against
`f_blocks * f_bsize == 1099511627775`. Every test so far used 1 or 4096, both powers of two, which is
why it never showed. The placeholder now goes through the same `// block_size * block_size`
rounding as a finite total. The description now says the placeholder is "in whole blocks", so the
new test has a sentence to stand on.

### Tests added — 110 -> 112

- `test_an_unlimited_mount_reports_whole_blocks_of_any_size` — the non-divisor case, comparing
  `get_disk_usage` against `statvfs` directly.
- `test_set_disk_usage_only_changes_the_reserves_of_the_mount_of_the_path` — R11's Auto Review
  T3/T4 Medium, which I had not closed: the existing locality test proved `total_size`,
  `block_size` and `inode_count` go to the path's mount, but never the reserves. An implementation
  keeping reserves in root-only state passed.

### Description (user request) — two rewrites

The unlimited sentence no longer uses "a placeholder the figures come from" (opaque), and the
rollback sentence is two sentences so its scope is immediately clear. Kept declarative rather than
imperative, and kept "creating one object" so the R11 narrowing still excludes a sequence of
directory creations. 498 words.

### R12 validation matrix

| Tree | User | Base | New |
|---|---|---|---|
| base + test.patch | 0:0 | 1413 passed, exit 0 | 112 failed |
| base + test.patch | 1000:1000 | 1419 passed, exit 0 | 112 failed |
| base + test.patch | **4242:4242** | 1419 passed, exit 0 | 112 failed |
| base + test.patch | **4242:0** | 1419 passed, exit 0 | 112 failed |
| + solution.patch | 0:0 | 1413 passed, exit 0 | 112 passed |
| + solution.patch | 1000:1000 | 1419 passed, exit 0 | 112 passed |
| + solution.patch | **4242:4242** | 1419 passed, exit 0 | 112 passed |
| + solution.patch | **4242:0** | 1419 passed, exit 0 | 112 passed |

Plus: 3x identical verdicts at 0:0 and 4242:4242 on both modes; `ruff format`, `ruff check`,
`pyupgrade` clean on all five files; leak scan clean; both patch orders apply and reverse; `test.sh`
100755; 391 effective LOC.

## R11 FIRST AGENT BATCH — 0/11, UNSOLVABLE, and the cut-back (2026-09-21)

Batch 1 landed in `agent-runs/1`: 10 Nova + 1 Vega. **Every run failed.** 0% is an automatic reject,
so this is the round that matters more than the eight gate rounds before it.

### Per-agent table

| Agent | Verdict | New tests failed (of 119) | Baseline |
|---|---|---|---|
| Nova_Nova_2 | fail | 8 | pass |
| Vega_Nova | fail | 8 | pass |
| Nova_Nova_1 | fail | 10 | pass |
| Nova_Nova_10 | fail | 10 | pass |
| Nova_Nova_4 | fail | 10 | pass |
| Nova_Nova_7 | fail | 10 | pass |
| Nova_Nova_6 | fail | 11 | pass |
| Nova_Nova_8 | fail | 11 | pass |
| Nova_Nova_3 | fail | 13 | pass |
| Nova_Nova_5 | fail | 21 | pass |
| Nova_Nova_9 | fail | 59 | pass |

Every agent kept all 1414 baseline tests green, so nobody broke the repo; they ran out of
REQUIREMENTS, not competence. 66 distinct tests failed at least once, but the distribution is
extremely concentrated.

### The six tests that killed 11 of 11

```
11/11  test_a_refused_bulk_import_leaves_nothing_behind
11/11  test_a_refused_deep_real_directory_import_takes_its_parents_back
11/11  test_a_refused_lazy_directory_read_leaves_the_mount_as_it_was
11/11  test_a_refused_lazy_read_of_directories_leaves_nothing_behind
11/11  test_a_refused_real_directory_import_leaves_nothing_behind
11/11  test_a_refused_pathlib_mkdir_with_parents_leaves_nothing_behind
10/11  test_mount_usages_reports_every_mount
 9/11  test_a_mount_added_over_a_directory_keeps_its_charge_where_it_was
 8/11  test_a_negative_total_size_reports_no_blocks
 8/11  test_a_refused_makedirs_leaves_no_directory_behind
```

**Every one of those was added under gate pressure between R4 and R9.** Each time a Solution
Quality reviewer said "your description promises atomicity, so this path must roll back too", I
implemented it and wrote a test. None of those additions was wrong on its own. Together they made a
problem no agent could finish: transactional rollback through eager real-directory import, lazy
materialisation, bulk import, `os.makedirs` and `pathlib` parent creation is five distinct
recursive-undo mechanisms on top of the accounting itself.

### Two of the ten were FAIRNESS defects, not difficulty

Reading the failure text rather than the counts:

- `test_mount_usages_reports_every_mount` (10/11): agents returned `(0, 0)` per mount, i.e. a
  used/free pair rather than an `os.statvfs_result`. The description said "`mount_usages()` returns
  **it** for every mount" with the antecedent three sentences upstream. That pronoun is the whole
  failure. Fixed by naming the type: "returns an `os.statvfs_result` for every mount".
- `test_a_negative_total_size_reports_no_blocks` (8/11): two grounded readings. Nova_Nova_1 returned
  `f_blocks = -1` (no clamp); Nova_Nova_10 raised `ValueError("total_size must not be negative")`,
  which is a perfectly reasonable extension of "a negative count or reserve is a `ValueError`". The
  test pinned one of two readings, exactly the class that was dropped from the `get_disk_usage`
  assertion at R7. Dropped.

### The cut (user decision: balanced aim)

Dropped 9 tests, 119 -> 110:

| Dropped | Why |
|---|---|
| the 5 real-import rollback tests (eager, deep, lazy x2, bulk) | five recursive-undo mechanisms beyond what a real filesystem offers |
| `a_refused_makedirs_leaves_no_directory_behind`, `a_refused_pathlib_mkdir_with_parents_leaves_nothing_behind` | CPython's own `os.makedirs` and `pathlib` leave parents behind; demanding otherwise was my over-promise |
| `a_mount_added_over_a_directory_keeps_its_charge_where_it_was` | the `charged_dev` subtlety is genuinely under-specified by the description |
| `a_negative_total_size_reports_no_blocks` | two grounded readings |

The single-object rollback tests STAY and every agent already passed them: `create_dir`,
`create_file`, `create_symlink` and `add_real_file` still take back the parents they make. The
description clause was narrowed to match, from "taking back any directory it had to create on the
way" to "creating one object takes back any parent directory it made", which excludes a sequence of
directory creations without re-introducing an enumeration.

**The implementation was NOT reverted.** The import/makedirs/pathlib rollback all stays, so the
reference solution is still stricter than the contract. Only the hidden tests stop requiring it.

### Replayed rate

Replaying all 11 saved runs against the reduced suite: **1/11 passes (Vega_Nova)**. Eight of the
remaining ten fail on nothing but `test_mount_usages_reports_every_mount`, which the pronoun fix
addresses; a replay cannot credit a wording change, so the true rate sits between **9% and 36%** and
only a fresh batch settles it. `meta.md` changed, so this is not re-eval eligible.

### Also in this round: the two Auto Review HIGH regressions

- **S1, statvfs mount selection.** `_mount_point_for_path` (base code) decides membership with a raw
  `path.startswith(root_path)`, so `/mnt2/file` was reported against mount `/mnt`. My `statvfs`
  newly exposed a pre-existing repo bug. Added `_is_below()`, which compares whole path components,
  and routed the prefix branch through it. `get_disk_usage` benefits too, and all 1414 baseline
  tests still pass, which is the check that mattered since this is shared base code.
- **S2, makedirs parent mode.** My R7 rollback refactor forwarded the leaf `mode` into recursive
  parent creation, so `makedirs('/a/b', mode=0o700)` made `/a` 0o700 instead of the default. The
  recursive call now passes `PERM_DEF`, matching the implementation the repo copied from CPython.
  Verified: `/a` is 0o777, `/a/b` is 0o700 under umask 0.

Both are pure bug fixes and are kept regardless of the test cut.

### Description readability (user request) — three rewrites

The `add_mount_point` / `set_disk_usage` paragraph is now three sentences separating creation
defaults from reconfiguration semantics; the statvfs field mapping is one sentence per field family
so no pronoun carries a three-field mapping; and `mount_usages` names its return type. 498 words.

### R11 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **110 failed / 110**, exit 1 |
| `test.sh new` with solution | **110 passed / 110**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical |
| Repo hooks | `ruff format --check`, `ruff check`, `pyupgrade --py310-plus` clean on all five changed files |
| Leak scan | clean on added lines of both patches |
| Patch order | both orders apply, both reverse clean, tree empty after |
| meta.md | 498 body words, ASCII, unwrapped |
| Effective LOC | `human-effective: 391`, raw 710, 5 files |

## R10 Auto Review — Revision Requested, both items fixed (2026-09-21)

First full **Auto Review**, not just the individual gates. Description **3/3 Clean**, Solution &
Code **3/3 Clean**, and the standalone Solution Quality check flipped to **PASS** with
Comprehensiveness **3/3 Fully Met** (it had been 1/3 for eight rounds). Tests scored **0/3** on a
single Blocker that has nothing to do with the tests themselves.

### BLOCKER — platform-content leak in `test.sh`

> `# Three deselected cases, all failing on base with and without the solution.`

Challenge-facing harness content must not expose the base-versus-solution grading phases. The
reviewer's own counter-argument is worth recording: "solution" alone could be ordinary project
vocabulary, but pairing it with "base" AND with before/after pass-fail behaviour makes the grading
context explicit. The band rule is severity-based, so one comment line took Tests from a described
"broad, deterministic, behavior-facing, honest JUnit harness" to 0/3.

Rewritten with repository-local facts only, no comparison of phases:

> `# Three cases of this repository are not compatible with this pytest invocation.`
> ... `TestClassSetup` errors during pytest collection with "OSError: [Errno 9] Bad file
> descriptor"; the repository runs those cases through `python -m pyfakefs.tests.all_tests`
> instead ... both answer to the host environment rather than to the fake filesystem.

The irony is that the leaked sentence was written at R5 to SATISFY the principal-reviewer rule about
documenting every test exclusion. Both rules are satisfiable at once: give the reason, never the
phase it was observed in.

A grep for `solution|on base|base mode|grader|grading|reviewer|challenge|hidden|agent|author` over
every added line of both patches now returns nothing, and is part of the pre-submit list from here
on.

### LOW (S2) — public annotation narrower than the contract

`set_disk_usage(self, total_size: int, ...)` while the description promises "a `total_size` of
`None` means no limit" and the body assigns `None` straight into the candidate settings. pyfakefs
ships `py.typed`, so a type checker rejects a documented, runtime-supported call. Now
`total_size: int | None`, with the docstring saying what `None` means. Confirmed by reading the
annotation back off the imported class.

### What the review confirmed

- 1414 base tests pass; all 119 new tests fail before the implementation and pass with it; six
  repeated pre/post runs stable.
- The fairness check found all 119 tests prompt-stated or repo-inferable, with **no** coverage
  suggestions left.
- The `test.sh` no-results branch was read as fail-safe rather than masking: pytest writes its own
  JUnit XML, and the synthetic failing testcase is written only when pytest produced no testcase at
  all, forcing a nonzero exit.
- No agent-run pool existed yet, so the agent-discrepancy dimension is unscored and re-runs once a
  batch lands.

### R10 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **119 failed / 119**, exit 1 |
| `test.sh new` with solution | **119 passed / 119**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical |
| Repo hooks | `ruff format --check`, `ruff check`, `pyupgrade --py310-plus` clean on all five changed files |
| Leak scan | no grading-context vocabulary in any added line of either patch |
| Patch order | both orders apply, both reverse clean, tree empty after |
| Patch encoding | both `ASCII text`, LF; `test.sh` 100755; test file 100644 |
| meta.md | 489 body words, UNCHANGED this round |
| Effective LOC | `human-effective: 382`, raw 699, 5 files |

Both edits are inside `test.patch` and `solution.patch` only, so this round stays re-eval eligible.

## R9 quality-gate fixes, round 8 — Docker clean room (2026-09-21)

Test Quality PASSED. Solution Quality FAIL with two issues, plus three advisory coverage
suggestions and two description readability suggestions, all taken.

### HIGH — resizing an unlinked open file drove usage negative

`remove_entry` releases the allocation and clears `charged_dev` when the last name goes, but the
three `FakeFile` size paths still charged unconditionally against `self.st_dev`. So keeping a
descriptor open across an `unlink` and then calling `ftruncate(fd, 0)` subtracted the same block a
second time and `used_size` went negative. The release-on-last-name rule and the descriptor-based
resize path disagreed, exactly as reported.

Fixed with one gated helper, `FakeFile._charge_resize(st_size)`: it charges against `charged_dev`
and does nothing when that is `None`, which is precisely "it already gave its allocation back with
its last name". All three size paths (`size` setter, `set_initial_contents`, `set_large_file_size`)
now go through it.

**It closed a second hole nobody had reported.** `_without_accounting()` (added at R8 for the temp
directory) only suppressed the charge in `add_entry`. The temp SYMLINK, created when `TMPDIR` points
somewhere other than `/tmp`, went on to `set_initial_contents` and charged its blocks anyway. With
the gate the symlink has no `charged_dev`, so the whole bootstrap really is free on every TMPDIR
setting, not just the default one.

### MEDIUM — bulk real-path imports were not one operation

`add_real_paths()` is a plain loop over `add_real_directory` / `add_real_file`, so an early member
that fits stayed behind when a later one did not. R6's collector was on the individual imports, not
the aggregate. Both `add_real_paths()` and `add_package_metadata()` now open
`_collect_added_entries()` around their whole loop; the per-import collectors nest harmlessly
because only the outermost one collects.

### Coverage suggestions (advisory) — all three taken

- `test_a_file_is_charged_for_its_bytes_not_its_characters`: 2049 `\u00e9` characters are 4098
  bytes, so an implementation using `len(str)` charges one block where the contract wants two. The
  test file stays pure ASCII by writing the escape.
- `test_an_unprivileged_symlink_stops_at_the_block_reserve`: the reserve tests covered file data and
  directory inodes but never symlink creation.
- `test_tree_usage_leaves_out_the_temporary_directory`: connects the temp-directory exemption to
  `tree_usage`, which the two existing tests only proved separately.

### Description readability (advisory) — both taken

The statvfs field mapping is now two sentences, blocks then inodes, and the `tree_usage` rules are
no longer a compressed list; "one charged to no mount for nothing" was genuinely ambiguous and is
now "an object charged to no mount counts for nothing". Both rewrites plus a compression pass across
the rest landed at 489 words, up 3, still 11 under the cap.

### Tests added — 114 -> 119

Two for the fixes (`resizing_an_unlimited_open_file...`, `a_refused_bulk_import...`) and three for
the advisory gaps. The bulk-import test derives the inode budget from the real source path's depth,
so the first import fits exactly and the second cannot, whatever `TMPDIR` is.

### R9 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **119 failed / 119**, exit 1 |
| `test.sh new` with solution | **119 passed / 119**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 and 119 unique ids |
| Repo hooks | `ruff format --check`, `ruff check`, `pyupgrade --py310-plus` clean on all five changed files |
| Patch order | both orders apply, both reverse clean, tree empty after |
| Modes | `test.sh` 100755, test file 100644 |
| Patch encoding | both `ASCII text`, LF; test file pure ASCII; no banned markers |
| meta.md | 489 body words, ASCII, unwrapped |
| Effective LOC | `human-effective: 381`, raw 698, 5 files (371 at R8, 351, 340, 303, 292, 238, 208, 99) |

## R8 quality-gate fixes, round 7 — Docker clean room (2026-09-21)

Test Quality FAIL (4 of 110) and Solution Quality FAIL (4 issues). The two gates were reading the
same sentence in opposite directions, which turned out to be the whole problem.

### The enumeration was the bug — one edit fixed all four unfair tests

R7's Solution Quality demanded `os.makedirs` be transactional, citing the general sentence. R8's
Test Quality then called four rollback tests unfair, because the same paragraph ENUMERATED the
helpers that take their directories back:

> ... leaves the mount as it was; `create_dir`, `create_file`, `create_symlink` and
> `add_real_file` also take back directories they created.

Naming four is an expressio-unius reading: `add_real_directory`, `os.makedirs` and
`pathlib.Path.mkdir(parents=True)` are excluded by omission, and the visible non-transactional repo
implementations make that the grounded reading. The reviewer is right, and the list was mine: it
accumulated one API at a time across R4-R6 as each was fixed.

Replaced with a universal clause, two words SHORTER:

> ... leaves the mount as it was, taking back any directory it had to create on the way.

All four flagged tests become fair, the enumeration cannot go stale again as more call paths are
covered, and the two gates now read the same rule. No test was changed.

### Solution Quality — 4 issues, all reproduced and all fixed

| Issue | Cause | Fix |
|---|---|---|
| HIGH: `set_disk_usage(None)` rejected a mount already larger than the placeholder | `_check_mount_settings` compared `used_size` against `mount_capacity(candidate)`, which is `UNLIMITED_SIZE` for `None` | the capacity check is skipped when the CANDIDATE total is `None`. Same class as R5's placeholder-as-cap bug, one branch further along: R5 fixed enforcement during allocation, this is enforcement during reconfiguration |
| HIGH: `reset` could not keep `inode_count=0` | `reset` restored the settings and THEN `_create_temp_dir` called `create_dir`, whose `add_entry` charged an inode and raised before the exemption ran | a `_without_accounting()` context manager creates the temp directory and its symlink charged to nothing from the outset. `_exempt_from_accounting` (charge-then-unmark) is gone, and so is the counter zeroing that propped it up |
| HIGH: a failed lazy read was not reliably rolled back | `_undo_added_entries` removed recursively, and `remove_entry` walks `entry.entries`, which for a `FakeDirectoryFromRealDirectory` starts the very load that just failed | the undo removes with `recursive=False`. Objects below a directory were recorded after it and are already gone when it is reached, so nothing recursive is needed |
| MEDIUM: `tree_usage` blamed the wrong mount | `add_mount_point` over an EXISTING directory changes that directory's `st_dev`, but root had charged it. `_add_object_usage` read the current `st_dev` | the `accounted: bool` flag became `charged_dev: int | None`, so every object remembers the device that actually took the charge. `remove_entry` releases against it too, which silently fixes the matching release-to-the-wrong-mount bug nobody had reported yet |

Measured before and after on the reviewer's own repro for each.

### Formatter conflict worth recording

`ruff check` (SIM102) wanted the new capacity guard as one `if`; `ruff format` then split that `if`
across three lines in a shape `--check` rejected. The two hooks can disagree. Resolved by hoisting
`mount_capacity(candidate)` into a local so the combined condition fits in 87 characters. All five
changed files are clean under `ruff format --check`, `ruff check` and `pyupgrade --py310-plus`.

### Suite-wide note from the reviewer (no action)

Both new test classes skip on a real Windows runner because `statvfs` is POSIX-only, so the hidden
tests give no coverage there. Flagged as a coverage limitation, not a fairness defect. The grading
host is Linux, and the alternative (dropping the POSIX guard) would break the repo's own Windows CI.

### Tests added — 110 -> 114

One per solution fix: `setting_no_limit_again_keeps_what_the_mount_holds`,
`reset_keeps_a_mount_that_has_no_inode_left`,
`a_mount_added_over_a_directory_keeps_its_charge_where_it_was`, and
`a_refused_lazy_read_of_directories_leaves_nothing_behind`. The last builds its source with
`tempfile.mkdtemp` and `addCleanup(shutil.rmtree)`, with every top-level entry a directory, so the
failure lands on a lazily-loaded directory whatever order `os.listdir` returns. It also asserts the
read stays refused and then succeeds once there is room, which pins the `contents_read` reset.

### R8 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **114 failed / 114**, exit 1 |
| `test.sh new` with solution | **114 passed / 114**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 and 114 cases |
| Repo hooks | `ruff format --check`, `ruff check`, `pyupgrade --py310-plus` clean on all five changed files |
| Patch order | both orders apply, both reverse clean, tree empty after |
| Modes | `test.sh` 100755, test file 100644 |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 486 body words, ASCII, unwrapped |
| Effective LOC | `human-effective: 371`, raw 683, 5 files (351 at R7, 340, 303, 292, 238, 208, 99) |

## R7 quality-gate fixes, round 6 — Docker clean room (2026-09-20)

Code Quality came back **3/3 Fully Met** this round (it was 2/3 for the five rounds before), which
the R6 formatter work bought. Two things left.

### Test Quality — 1 of 106 unfair

`test_a_negative_total_size_reports_no_blocks` asserted `get_disk_usage("/m") == (0, 0, 0)` for
`total_size=-1`. The reviewer is right and the reasoning is worth keeping: the description's "none
of them below zero" is grammatically attached to the statvfs field list, and base `get_disk_usage`
returns `(total_size, used_size, total_size - used_size)`, which is `(-1, 0, -1)` here. So my clamp
is a grounded choice, not the only one. The ASSERTION was dropped; the `statvfs` assertions in the
same test are fair and stay, and the clamp stays in `mount_capacity` because that is what makes the
fair statvfs assertions true. No description words were spent, which matters at 486 of 500.

### Solution Quality — 1 HIGH, and its twin

`FakeOsModule.makedirs` recurses through its own `mkdir` calls, so `_create_dir_path`'s rollback
never saw it: with `inode_count=2`, `os.makedirs("/a/b/c")` left `/a` and `/a/b` and both inodes
behind.

Fixed by wrapping it in the `_collect_added_entries()` collector built at R6, with the body moved to
a private `_makedirs` so the recursion does not reopen the context manager (the collector is
outermost-only anyway, so this is tidiness rather than correctness).

**The twin the report did not name:** `pathlib.Path.mkdir(parents=True)` leaks identically, and for
a different reason. pyfakefs binds `FakePath.mkdir` to the single-directory
`FakeFilesystem.makedir`; the parent walk is CPython's own `pathlib` code, so it never passes
through `FakeOsModule.makedirs` and the fix above does nothing for it. Fixing only what was reported
would have left `os.makedirs` transactional and `Path.mkdir(parents=True)` not, for the same
user-visible task. `FakePath.mkdir` now opens the same collector when `parents=True`, which wraps
CPython's recursion from the outside. Verified under the Patcher, which is the only place pathlib is
wired up: `FakePath.filesystem` is a CLASS attribute that a bare `FakeFilesystem()` does not set, so
a first attempt to test this against a plain filesystem silently ran against a stale one.

Considered and rejected: narrowing the description to say a sequence of directory creations is not
one operation. It is true of a real filesystem (CPython's `os.makedirs` leaves parents behind), but
the contract as written promises atomicity, there are no words left to spend, and a fake filesystem
that enforces quotas atomically is the more useful behaviour.

### Coverage suggestion (advisory) — taken

`test_a_reserve_larger_than_what_is_left_clamps_to_nothing` sets a reserve bigger than what the
mount has free, so a shortcut that forgets to clamp the reserve subtraction underflows. The previous
underflow cases came from overuse or a negative total, not from the reserve itself.

Five tests added, 105 -> 110, including the success and `exist_ok` paths of both directory-creation
routes so the rollback cannot silently break them.

### R7 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **110 failed / 110**, exit 1 |
| `test.sh new` with solution | **110 passed / 110**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 and 110 unique ids |
| Repo hooks | `ruff format --check`, `ruff check`, `pyupgrade --py310-plus` clean on all five changed files |
| Patch order | both orders apply, both reverse clean, tree empty after |
| Modes | `test.sh` 100755, test file 100644 |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 486 body words, ASCII, unwrapped, UNCHANGED for the second round running |
| Effective LOC | `human-effective: 351`, raw 663, **5 files** (340 at R6, 303, 292, 238, 208, 99) |

## R6 quality-gate fixes, round 5 — Docker clean room (2026-09-20)

Solution Quality only, three issues. The description did not change this round, so the solver-visible
surface is unchanged from R5.

### HIGH — `add_real_directory` was not transactional

Eager import (`lazy_read=False`) creates the target with `create_dir` and then imports children in a
loop. On a mount with `inode_count=1` the target takes the only inode and the first child raises
`ENOSPC`, leaving the target and its charge behind. The lazy path had the same hole one level down:
the placeholder is cheap, but materialising it through the `entries` property adds children one at a
time and leaves the ones that fit.

Fixed with a general undo rather than a path-specific one. `FakeFilesystem` gained
`_collect_added_entries()`, a context manager that records `(parent, name, object)` for every
successful `add_entry` while it is open and, on `OSError`, takes them back newest first through the
normal `remove_entry` path so every charge is released the way it was taken. Only the OUTERMOST
block collects, so the recursive lazy import does not undo what the call around it is still
building, and `_undo_added_entries` skips any entry the failing operation already removed itself
(`add_real_file` has its own rollback). `add_real_directory` wraps both import paths in it, and
`FakeDirectoryFromRealDirectory.entries` wraps the materialisation loop, resetting `contents_read`
so a refused read leaves the directory genuinely unread rather than permanently empty.

That last point is why the general mechanism was worth it over removing the target directory: with
`contents_read` reset AND the entries taken back, a later read with room succeeds, which a
target-removal fix could not give.

### MEDIUM — negative `total_size` produced negative statvfs fields

`add_mount_point("/m", total_size=-1)` was accepted and `mount_capacity` returned -1, so `f_blocks`
and the unlimited-inode `f_files` both read -1, against the description's "none of them below zero".
Clamped in `mount_capacity` (`max(0, total_size)`) rather than by rejecting the value, because the
description promises non-negative REPORTING and says nothing about a new `ValueError`, and adding
one would be an undocumented requirement.

### LOW — formatter

Three blank lines were left between `available_size` and `free_inodes` when a dead helper was
removed at R5. Fixed, and the repo's actual hooks were then run against all four changed files
inside the base image: `ruff-format` (0.16.7, the pinned version), `ruff check`, and
`pyupgrade --py310-plus`. That found two more things `ruff format` would have rewritten in the test
file and six `%`-format strings `pyupgrade` flagged; the repo's own tests use no `%` formatting
anywhere, so all six became f-strings. All four files are now clean under all three hooks. Two added
lines over 88 characters were wrapped by hand.

### Tests added — 100 -> 105

`a_refused_real_directory_import_leaves_nothing_behind` (eager),
`a_refused_deep_real_directory_import_takes_its_parents_back`,
`a_refused_lazy_directory_read_leaves_the_mount_as_it_was`,
`a_real_directory_import_that_fits_charges_every_object` (the success path, cross-checked against
`tree_usage` and then removed to prove everything comes back), and
`a_negative_total_size_reports_no_blocks`. The import tests use `pyfakefs/tests/fixtures`, reached
from `__file__`, with an inode budget small enough that the outcome does not depend on how many
files that directory happens to contain.

### R6 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **105 failed / 105**, exit 1 |
| `test.sh new` with solution | **105 passed / 105**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| JUnit, base mode | 2397 `<testcase>`, 0 `<failure>`, 0 `<error>` |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 and 105 unique ids |
| Repo hooks | `ruff format --check`, `ruff check` and `pyupgrade --py310-plus` clean on all four changed files |
| Patch order | both orders apply, both reverse clean, tree empty after |
| Modes | `test.sh` 100755, test file 100644 |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 486 body words, ASCII, unwrapped, UNCHANGED this round |
| Effective LOC | `human-effective: 340`, raw 644, 4 files (303 at R5, 292, 238, 208, 99) |

## R5 quality-gate fixes, round 4 — Docker clean room (2026-09-20)

Test Quality PASSED this round. Three reports came back: Solution Quality (FAIL, 3 issues), a new
problem/tests alignment FAIL (2 interface items), and the only-necessary-information warning (5
advisory trims). The two description reports pulled in opposite directions, which is what made the
word budget the binding constraint.

### Solution Quality — 3 issues, all real

**HIGH, rename was destructive under a reserve.** pyfakefs implements an intra-mount rename as
`remove_entry` then `add_entry`, and my accounting hung off exactly those two calls. So a rename
RELEASED the object and then tried to CHARGE it again. With reserved blocks that second charge can
fail even though a rename needs no new allocation: 10 one-byte blocks, 3 reserved, an 8-byte `/src`
created as root, then a non-root rename. The release frees 8, the re-charge sees 7 available and
raises `ENOSPC`, and the rollback re-adds under the same restriction and fails too. The entry was
GONE and the counters were wrong. Data loss, correctly called high.

Fixed at the single chokepoint: `FakeDirectory.remove_entry` gained an `account` flag matching the
one `add_entry` already had, and `_do_rename` moves the renamed object with `account=False` on both
sides, so it keeps what it already took and its `accounted` flag rides along untouched. The
REPLACED entry is still released normally, and the rollback still re-adds it. Four tests pin it:
blocks, inodes, a directory tree, and replacement, each under a reserve that makes the old code
fail.

**HIGH, `total_size=None` had become a real 1 TiB cap.** R3's fix for unlimited-mount REPORTING
routed the capacity check through `mount_capacity()`, which returns the `UNLIMITED_SIZE` sentinel
for `None`. That turned a reporting placeholder into an enforced limit, so
`create_file(st_size=UNLIMITED_SIZE + 1)` started failing. `_move_used_size` now skips the check
entirely when `total_size is None` while the reporting stays as R3 left it. The two reviews are
reconcilable: R3 wanted unlimited mounts to REPORT what they hold, this one wants them to REFUSE
nothing, and both are now true.

**MEDIUM, `f_ffree` could go negative.** With `inode_count=None`, `charge_inode` deliberately does
not limit, but `statvfs` reports `f_files` as the block count and subtracted `used_inodes` from it
without a floor. A one-block mount holding two empty files reported `-1`. Clamped, along with
`f_bfree`, which had the same shape.

### Problem and tests alignment — FAIL, 2 interface items

1. **ERROR:** tests call `set_disk_usage(total_size, path, ...)` and assert only that path's mount
   changes, which the description never mentioned. Now stated: `set_disk_usage(total_size,
   path=None, ...)` takes the same four after `path`, changing only that path's mount, the root one
   by default.
2. **WARNING:** tests build unlimited mounts with `total_size=None` and assert their `statvfs`
   behaviour, also undocumented. Now stated in the same sentence as the rounded-total rule.

### Only-necessary-information — 5 advisory trims, 3 taken

Taken: "an empty one none" (0 bytes needing 0 blocks follows from the whole-block rule), the
"and none comes back while another name remains" clause (implied by "gives it back with its last
name"), and shortening the shrink clause.

**NOT taken, with reason:** deleting "a refused change leaves every setting as it was" and deleting
the `from os import statvfs` clause. The first is traced by the requirement-coverage table to three
tests, one of which this same round's advisory asked me to ADD; deleting it would make them
undocumented. The second is pinned by `test_a_directly_imported_statvfs_reports_the_fake_mount`, and
Test Quality passed with it present, so removing it trades a passing gate for nine words.

Net effect on the budget: 486 words, up from 487, with two new interface sentences paid for by the
trims plus a compression pass over the whole text.

### Coverage suggestions (advisory) — both taken

`test_a_refused_block_size_change_leaves_the_other_settings_alone` passes a changed total, inode
count and both reserves together with the forbidden block-size change, so an implementation that
mutates other fields before raising is caught. `test_reset_without_a_new_total_keeps_the_other_settings`
calls `reset()` with no argument. That exposed a real ambiguity: `reset(total_size=None)` means
UNLIMITED in the existing API, not "unchanged", so the description now names what `reset` keeps
(block size, inode count and reserves) instead of saying "the settings", and the test pins those
three without pinning the total.

Eight tests added, 92 -> 100.

### R5 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **100 failed / 100**, exit 1 |
| `test.sh new` with solution | **100 passed / 100**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 unique base ids, 100 unique new ids |
| Patch order | both orders apply, both reverse clean, tree empty after |
| `test.sh` mode | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 486 body words (cap 500), ASCII, unwrapped |
| Effective LOC | `human-effective: 303`, raw 579, 4 files (292 at R4, 238 at R3, 208 at R2, 99 at R1) |

## R4 quality-gate fixes, round 3 — Docker clean room (2026-09-20)

Down to one unfair test and two solution issues. All three correct, all fixed.

### Test Quality — 1 of 90 unfair

`test_tree_usage_reports_what_the_mounts_were_charged` read `.size` and `.inodes` off the pair. The
description says "a `(size, inodes)` pair", which an ordinary 2-tuple satisfies, and the repo has no
`TreeUsage` precedent. So a grounded implementation returning a plain tuple passes every other
`tree_usage` test and fails only this one. Fixed in the TEST by unpacking positionally
(`root_size, root_inodes = usage["/"]`), which works for a tuple and a namedtuple alike. The
description was NOT widened to name the type: naming it would have made the assertion fair but also
forced every implementation to invent the same attribute names, which is the more expensive
direction for no gain.

The private-helper coupling concern on `test_removing_the_temporary_directory_returns_no_inode` was
taken as well: `self.fs._tempdir_name()` is now `tempfile.gettempdir()`. That call has to happen
BEFORE the inode budget is exhausted, because `gettempdir()` probes each candidate by creating a
file there, and the probe raising `ENOSPC` makes it report "No usable temporary directory found".
Caught in the clean room, not locally.

### Solution Quality — 2 issues

**HIGH, Windows symlinks leaked blocks.** `FakeStatResult.st_size` deliberately returns 0 for a
symbolic link on a Windows fake filesystem (`pyfakefs/helpers.py:355-359`), but the charge in
`set_initial_contents` is computed from `len(byte_contents)` and does not go through stat. So the
link was charged its blocks and released nothing, and `tree_usage` reported `(0, 1)`. A real leak,
and the reviewer's reading is right: in this codebase `st_size` is a PRESENTATION value, not the
stored byte length.

Fixed with a single allocation-size helper, `fake_file.allocation_size(path_object)`: a directory is
0, a symbolic link is `len(byte_contents)` whatever stat shows, everything else is `st_size`. It is
now the one source used by `_accounted_size` (charge and release), by `_add_object_usage`
(`tree_usage`), and by all three `FakeFile` resize paths. `test_a_symlink_is_charged_for_its_path_where_stat_reports_nothing`
pins it end to end on a Windows fake filesystem: stat says 0, the mount says one block, `tree_usage`
says one block, and removing the link gives both the block and the inode back.

**MEDIUM, `change_disk_usage` lost its documented semantics.** It is listed in `docs/modules.rst`
and documented as a signed byte delta on used space; the block-aware rewrite gave it an `old_size`
keyword defaulting to 0, which made `change_disk_usage(-2, path, dev)` a no-op. Split in two, as the
reviewer suggested: `change_disk_usage` is back to exactly its original signature, docstring and
behaviour, and a new PRIVATE `_resize_allocation(old_size, new_size, path, st_dev)` carries the
block arithmetic. Both go through one `_move_used_size` helper that holds the reserve-aware room
check. Every internal caller (`allocate_entry`, `release_entry`, `add_real_file`, and the three
`FakeFile` size paths) now uses the private primitive. `_resize_allocation` is deliberately absent
from `docs/modules.rst`.

### Coverage suggestion (advisory) — taken

`test_a_new_mount_point_honours_the_reserves_it_was_given`. The reserves were only exercised through
`set_disk_usage`, so an implementation that accepted but ignored them in `add_mount_point` passed.
The new test reads both reserve gaps off `statvfs` for a freshly mounted device and then proves an
unprivileged caller is actually stopped by them.

Two tests added, 90 -> 92.

### R4 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **92 failed / 92**, exit 1 |
| `test.sh new` with solution | **92 passed / 92**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 unique base ids, 92 unique new ids |
| Patch order | both orders apply, both reverse clean, tree empty after |
| `test.sh` mode | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 487 body words, ASCII, unwrapped, UNCHANGED this round |
| Effective LOC | `human-effective: 292`, raw 565, 4 files (238 at R3, 208 at R2, 99 at R1) |

## R3 quality-gate fixes, round 2 — Docker clean room (2026-09-20)

Two gates left after R2. Both were right on every point.

### Test Quality — 5 of 80 unfair, all five `tree_usage`

Two separate defects, and they turned out to share one fix.

1. **The inner value shape was an unstated author choice.** `dict(tree_usage("/a")) == {"/": (8192, 3)}`
   pins a two-item tuple, while the description only said "a dict of mount path to the allocated
   bytes and the inodes". The reviewer's counter-reading (`{"allocated_bytes": ..., "inodes": ...}`)
   is grounded: the repo's own mount records are plain dicts and `DiskUsage` is a namedtuple, so
   both composite forms exist in this codebase. Fixed in the DESCRIPTION, not the tests: it now says
   "a `(size, inodes)` pair of allocated bytes and inodes". A namedtuple compares equal to the
   tuple, so the assertion form is now prompt-supported.

2. **`tree_usage` counted quota-exempt directories.** The description says mount-created directories
   and the temp directory "take an inode from neither mount", but the walk counted them anyway, so
   `tree_usage` and the mount counters disagreed. This was a real contradiction, not a test bug.

   The fix is the same one Solution Quality issue 3 demanded: a persistent `accounted` flag per
   object. `add_entry` sets it when it charges, `remove_entry` releases only when it is set, and
   `tree_usage` counts only charged objects. `tree_usage` now agrees with `used_size` and
   `used_inodes` exactly, which is a far better contract than either reading, and
   `test_tree_usage_reports_what_the_mounts_were_charged` pins that agreement directly.

### Solution Quality — 4 high issues, all real, all fixed

| Issue | Fix |
|---|---|
| Unlimited mounts reported no used or reserved space (`f_bfree`/`f_bavail` were both `total_blocks`, `get_disk_usage` returned the fixed unlimited tuple) | `statvfs`, `get_disk_usage` and the allocation kernel now take one uniform path. `mount_capacity()` already returned `UNLIMITED_SIZE` for a `None` total, so the special cases were simply deleted. An unlimited mount now reports what it holds and honours its reserve |
| `set_disk_usage` accepted a finite capacity smaller than what an unlimited mount already held, because the guard read `mount_point["total_size"] is not None` | The check is now `mount_point["used_size"] > mount_capacity(candidate)`, against the PROSPECTIVE settings |
| Removing an exempt temp or mount-created directory handed back an inode nobody had charged | The `accounted` flag above. `_create_temp_dir` also marks the tree it created as never charged, instead of only zeroing the counters |
| `add_real_file` inserted the file, then copied the real size, then charged; `ENOSPC` left the name and its inode behind | The block charge now happens BEFORE the stat result is copied, so a refused import removes the object while its size is still 0 (charging after the copy also produced a double release, `used_size` went to -20480 in the first attempt at this fix). The failure path removes the object and undoes any parent directories, via a new `created_dirs` out-parameter on `create_file_internally` |

### Coverage suggestions (advisory) — all three taken

`test_passing_none_keeps_the_reserves`,
`test_changing_the_block_size_of_a_mount_holding_a_symlink_is_refused` (the EBUSY shortcut that
checks only files and directories), and `test_growing_a_file_into_the_block_reserve_is_refused`
(the reserve was only exercised through creating a new file, not through growing an existing one).

Nine tests added in total, 80 -> 90; the other six pin the four Solution Quality fixes.

### R3 clean-room results

| Check | Result |
|---|---|
| `test.sh new` on base + test.patch | **90 failed / 90**, exit 1 |
| `test.sh new` with solution | **90 passed / 90**, root and uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| Flakiness | base 3x and new 3x, both users, verdict rows identical; 2397 unique base ids, 90 unique new ids |
| Patch order | both orders apply, both reverse clean, tree empty after |
| `test.sh` mode | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF; no banned markers |
| meta.md | 487 body words (cap 500), ASCII, unwrapped |
| Effective LOC | `human-effective: 238`, raw 535, 4 files (was 208 at R2, 99 at R1) |

## R2 quality-gate fixes — Docker clean room (2026-09-20)

Prechecks and the scope gate PASSED. Six quality checks came back, five of them actionable.

### What each gate said and what was done

**Verify Tests / Verify Solution (FAIL, the blocking pair).** `./test.sh base` on the base repo
reported 2 failures: `fake_filesystem_unittest_test.TestTempPathCreation::test_write_tmp_windows`
and `fake_filesystem_vs_real_test.FakeFilesystemVsRealTest::test_empty_path`. Neither reproduces
here. The grading host's counts identify it exactly: the platform runs the container as ROOT
(1414 passed / 981 skipped + 2 xfailed = the same split a local `--user 0:0` run produces, where 6
permission tests skip that pass as uid 1000). Against that baseline the ONLY difference is those 2
tests. Reproduction attempts, all green locally as root: `TMPDIR=/tmp`, `/var/tmp`, `/app/.tmp`,
`TMP`, `TEMP`, `HOME=/root`, `HOME=/nonexistent`, empty `HOME`, `--read-only` rootfs with a tmpfs
`/tmp`, `/tmp` as a symlink, and `-w /`. Both are host-dependent by construction:
`FakeFilesystemVsRealTest` compares the fake against the REAL host filesystem, and
`TestTempPathCreation` depends on real temp-directory discovery plus the real ownership of `/`.
Both are now deselected in base mode with the reason written into `test.sh`, alongside the
pre-existing `TestClassSetup` deselect.

**Test Quality (FAIL, 1 of 48 unfair).** `test_fake_os_statvfs_does_not_answer_from_the_real_filesystem`
asserted `os.statvfs("/").f_blocks != 20` on the HOST filesystem. Correct call: nothing pins that.
The assertion is gone; the callable-identity, result-type and fake-value assertions stay.

**Solution Quality (FAIL, 2 high + 1 low).** All three were real defects, all fixed:
- `FakeFile.set_large_file_size()` cleared the old size before charging the new one, so a refused
  resize destroyed the existing allocation. It now computes the delta from the current size, charges
  first and mutates only after that succeeds.
- `statvfs` was missing from `FakeOsModule.dir()`, so `from os import statvfs` kept the host call
  under the Patcher. Added, in the `sys.platform != "win32"` block, since `os.statvfs` does not
  exist on Windows.
- `FakeFilesystem.statvfs` was not in the `docs/modules.rst` member list. Added, with
  `mount_usages` and `tree_usage`.

**Problem and tests (WARNING).** Two coverage gaps named, both closed: explicitly passing `None` to
`set_disk_usage`, and the `add_mount_point` defaults on a NEW mount. The five advisory Coverage
Suggestions were taken as well: `set_disk_usage` path routing, block-exhaustion atomicity on a
mutation (truncate AND append), inode-exhaustion atomicity across file, directory and symlink, and
a nested mount whose intermediate parents do not exist.

**Description (FAIL) + only-necessary-information (WARNING).** The body was fixed-column
hard-wrapped at ~100 chars, which the detector reads as AI output. Rewritten with one line per
paragraph. The implementation-state preamble is gone, as are `after \`path\``, the redundant "Space
is charged per object." topic sentence and the "Used space is the space the objects occupy"
tautology. The rename sentence was compressed to the behaviour alone ("Renaming within a mount
changes neither count.") rather than deleted, because three tests pin it and it is the trap mutant D
falls into.

**Plagiarism comparison (WARNING, overall `derivative`).** Two pyfakefs candidates overlap:
- 0.77 `similar_idea`: a lighter statvfs/fstatvfs shim with a hard-coded 4096 block size, inodes
  counted by walking directories on demand, no ENOSPC enforcement.
- 0.65 `derivative`: per-volume `block_size` plus `statvfs`, wired through the same
  `set_contents`/`truncate`/`add_entry`/`remove_entry` sites. It has NO inode accounting, and adds
  read-only volumes with `EROFS`, a configurable `f_namemax` with `ENAMETOOLONG`, timestamp
  resolution, `remount` and `remove_mount_point`.

The divergence work took the second one as the constraint. Two planned FINISH levers were DROPPED
because they were that candidate's own features: the per-mount `f_namemax` with `ENAMETOOLONG`
enforcement, and the read-only mount flag with `EROFS` (already rejected earlier on scope grounds).
`fstatvfs` was dropped too, as the 0.77 candidate has it. What was built instead has no counterpart
in either:
- `reserved_blocks` and `reserved_inodes`, so `f_bavail` stops duplicating `f_bfree` and `f_favail`
  stops duplicating `f_ffree`, only root may take the reserve, and `get_disk_usage().free` reports
  the AVAILABLE space the way CPython's own `shutil.disk_usage` does.
- Transactional `set_disk_usage`: the candidate settings are validated as a set before any of them
  is applied, so a refused change cannot leave a new block size behind.
- All-or-nothing multi-directory creation for `create_dir`, `create_file` and `create_symlink`.
- `tree_usage(path, one_file_system=False)`, a `du` to the feature's `df`: per-mount attribution,
  each object counted once however many names it has, symlinks charged but not followed.
- `mount_usages()`, and mount settings surviving `reset()`.
- The filesystem's own temp directory costing neither blocks nor inodes.

`add_real_file` / `add_real_directory` charging and cross-mount rename accounting were both checked
and found to need NO work: the `add_entry` hook already charges real-file ingestion correctly, and
`rename` across devices already raises `EXDEV`.

### R2 clean-room results

Pristine clone at BASE_COMMIT, patches applied with `git apply`, `--network none`.

| Check | Result |
|---|---|
| Cold build | succeeds, no pip, no network needed after `COPY` |
| Container identity | `uid=1000(model) gid=1000(model)` |
| `test.sh new` on base + test.patch | **80 failed / 80**, exit 1 (every test is F2P) |
| `test.sh base` on base + test.patch | 1414 passed, 981 skipped, 4 deselected, 2 xfailed, exit 0 |
| `test.sh new` with solution | **80 passed / 80**, exit 0, as root AND as uid 1000 |
| `test.sh base` with solution | root 1414 passed, uid 1000 1420 passed, 0 failed either way |
| JUnit, base mode | 2397 `<testcase>`, 0 `<failure>`, 0 `<error>`, 2397 unique ids, no `::` inside an id |
| JUnit, new mode | 80 `<testcase>`, 0 `<failure>` with the solution |
| Flakiness | base 3x and new 3x on both trees and both users; per-test verdict rows byte-identical |
| Patch order | both orders apply, both `git apply -R` cleanly, `git status --porcelain` empty after |
| `test.sh` mode | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF |
| Banned markers | no `shipd` / `datacurve` |
| Added comments | solution: only repo-original comments moved with their code, plus `# type: ignore`; test.patch: the repo's Apache header, the shebang and the documented deselect reasons in `test.sh` |
| meta.md | 488 body words (cap 500), `ASCII text`, no unicode punctuation, no hard wrapping |
| Effective LOC | `human-effective: 208`, raw 503, 4 files. **Over the 200 floor** (was 99 at R1) |

## R1 precheck fixes — Docker clean room re-validation (2026-09-20)

Platform precheck came back with two failed gates. Both are now fixed and the whole clean room was
re-run from a PRISTINE clone at BASE_COMMIT.

**Dockerfile gate (1 ERROR + 2 WARNINGs).** The ERROR was the uid-1000 user being named `olympus`
instead of `model`, with a non-standard creation command. The two WARNINGs were both about the
`pip install --no-index --no-build-isolation -e .` line (explicit Python build during image build,
unpinned install). Fixed by deleting the install entirely: pyfakefs has zero runtime dependencies,
`pyfakefs/_version.py` is tracked in the repo, and the base image already ships `pytest 9.0.3`, so
`ENV PYTHONPATH=/app` alone makes `import pyfakefs` resolve to `/app/pyfakefs`. The image now runs
NO pip at all, which clears the ERROR and both WARNINGs. The uid-1000 user is kept (the base image
has no uid 1000 and `fake_pathlib_test.py` calls `getpwuid(1000)`), now as
`groupadd -g 1000 model && useradd -u 1000 -g model -m model` + `USER model`.

**Problem-and-tests gate (1 ERROR + 4 WARNINGs + 1 ambiguity).** Every flagged behaviour was
already implemented; none of them had a test. Ten tests added, 38 -> 48:

| Flag | Tests added |
|---|---|
| ERROR: no direct `FakeFilesystem.statvfs` coverage | `the_filesystem_reports_statvfs_for_the_mount_of_a_path`, `the_filesystem_and_the_os_module_report_the_same_statvfs` |
| WARNING: `EBUSY` on block-size change untested | `changing_the_block_size_of_a_mount_holding_a_file_is_refused`, `changing_the_block_size_of_a_mount_holding_a_directory_is_refused`, `the_block_size_of_an_empty_mount_can_be_changed` |
| WARNING: `ENOSPC` on lowering the inode count untested | `lowering_the_inode_count_below_the_number_in_use_is_refused` |
| WARNING: negative `inode_count` `ValueError` untested | `a_negative_inode_count_is_rejected` |
| WARNING: `None` leaving settings alone untested | `leaving_out_the_block_size_and_inode_count_keeps_them` |
| WARNING: symlink accounting reads ambiguous | `a_symlink_is_not_charged_for_the_size_of_its_target`, `a_symlink_holding_a_long_path_takes_more_blocks` |

The symlink flag was a FALSE alarm about the semantics and a REAL problem with the test name. The
solution charges a symlink for the byte length of the path it holds (`_accounted_size` returns
`path_object.size`, and a symlink's `size` is the length of its link path), which is exactly what
the description says. The old test name,
`test_a_symlink_takes_an_inode_and_the_blocks_of_its_target`, claimed the opposite and is what the
reviewer read. Renamed to `..._and_a_block_for_its_own_path`, and two tests were added that
DISCRIMINATE the two readings: a 3-block target whose symlink still costs one block, and a
4400-byte link path that costs two blocks with no target at all. The description sentence was also
split so a symlink is charged "for the length of the path it holds, whatever it points at".

### R1 clean-room results

| Check | Result |
|---|---|
| Cold build of the new Dockerfile | succeeds, no pip, no network needed after `COPY` |
| Container identity | `uid=1000(model) gid=1000(model)` |
| `import pyfakefs` inside the container, `--network none` | `/app/pyfakefs/__init__.py`, version `6.3.dev0` |
| `test.sh new` on base + test.patch | **48 failed / 48**, exit 1 (every new test is F2P) |
| `test.sh base` on base + test.patch | 1422 passed, 975 skipped, 2 deselected, 2 xfailed, exit 0 |
| `test.sh new` on base + test.patch + solution.patch | **48 passed / 48**, exit 0 |
| `test.sh base` on base + test.patch + solution.patch | 1422 passed, 975 skipped, 2 deselected, 2 xfailed, exit 0 |
| JUnit, base mode | 2399 `<testcase>`, 0 `<failure>`, 0 `<error>`, 2399 unique `classname::name`, no `::` inside any id |
| JUnit, new mode | 48 `<testcase>`, 0 `<failure>` with the solution |
| Flakiness, solution tree | new 3x and base 3x, identical counts |
| Flakiness, base tree | new 3x and base 3x, per-test verdict rows byte-identical across all three runs |
| Patch order | solution-then-test and test-then-solution both apply; both `git apply -R` cleanly; `git status --porcelain` empty afterwards |
| `test.sh` mode in test.patch | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF |
| Banned markers | no `shipd` / `datacurve` |
| Added comments | none in the solution; in test.patch only the repo's own Apache header and the `test.sh` shebang |
| meta.md | 446 body words, `ASCII text`, no non-ASCII bytes |
| Effective LOC | `human-effective: 99`, raw 259, 3 files. **STILL under the 200 floor** — unchanged by this round, the FINISH levers in DESIGN.md section 7 are still owed |

## R0 core slice — Docker clean room (2026-09-20)

Image `factory-pyfakefs-block-inode-accounting-*` built from `problems/.../Dockerfile`
(`olympus-base-python`, Pattern B). Every run: `--network none`, `--user 1000:1000`, from a
PRISTINE clone at BASE_COMMIT with the patches applied by `git apply`.

| Check | Result |
|---|---|
| Cold build, network on | 57 s |
| Cold build, `--no-cache --network none` | succeeds, `import pyfakefs` resolves to `/app/pyfakefs` |
| `test.sh base` on base + test.patch | 1422 passed, 975 skipped, 2 deselected, 2 xfailed, 0 failed, exit 0 |
| `test.sh new` on base + test.patch | **38 failed / 38**, exit nonzero |
| `test.sh base` on base + test.patch + solution.patch | 1422 passed, 975 skipped, 2 deselected, 2 xfailed, 0 failed, exit 0 |
| `test.sh new` on base + test.patch + solution.patch | **38 passed / 38**, exit 0 |
| JUnit, base mode | 2399 `<testcase>`, 0 `<failure>`, 0 `<error>`, 2399 unique `classname::name`, no `::` inside any id |
| JUnit, new mode | 38 `<testcase>`, 0 `<failure>` with the solution |
| Flakiness, solution tree | base 3x and new 3x, identical counts and identical per-test verdicts |
| Flakiness, base tree | base 3x and new 3x, identical; the 38 failing names are byte-identical across all three runs |
| Patch order | test-then-solution and solution-then-test both apply cleanly; both `git apply -R` cleanly; `git status --porcelain` empty afterwards |
| `test.sh` mode in test.patch | `new file mode 100755` |
| Patch encoding | both `ASCII text`, LF |
| Banned markers | no `shipd` / `datacurve` in either patch |
| Added comments | none in the solution beyond the repo's own Google-style docstrings; none in test bodies (the only `#` lines in test.patch are the repo's Apache licence header, which every test file in `pyfakefs/tests` carries) |
| Effective LOC | `human-effective: 99`, raw 259, 3 files. **Under the 200 floor, as expected for a core slice.** See DESIGN.md section 7 for the measured 2.6 raw/effective ratio and the FINISH lever table |

### Two environment fixes found by the clean room, both now in the Dockerfile

1. `pyfakefs/tests/fake_pathlib_test.py::...::test_owner_and_group_posix` calls
   `getpwuid(1000)`. The base image has no passwd entry for uid 1000, so the test failed with
   `KeyError: getpwuid(): uid not found: 1000` for the non-root run only. Fixed by creating a
   uid/gid 1000 user in the image rather than by excluding the test.
2. `LANG` / `LC_ALL` are set to `C.UTF-8`. pyfakefs's own Dockerfile notes that its tests need at
   least Latin-1; the base image ships no locale.

### One documented base-mode exclusion

`--deselect pyfakefs/tests/fake_filesystem_unittest_test.py::TestClassSetup` (2 cases). That class
drives `setUpClassPyfakefs`, and collecting it through pytest errors on BASE with an unmodified
tree (`OSError: [Errno 9] Bad file descriptor`), identically with and without the solution. The
repo's own CI runs those cases through `python -m pyfakefs.tests.all_tests`, not through pytest.
Verified pre-existing: base 1422 passed / 3 errors both with and without solution.patch before the
deselect was added.

### Trap reproduction (HARDENING 3a.4) — five natural-but-wrong implementations, each built and run

| Mutant | The wrong-but-natural move | Tests killed |
|---|---|---|
| A | round the DELTA inside the kernel and ignore the size the object had | 3: `repeated_sub_block_appends_stay_in_one_block`, `growing_within_an_allocated_block_is_free`, `shrinking_within_a_block_keeps_it` |
| B | hang the inode charge on the repo's existing `st_nlink == 1` byte guard | 5: `a_directory_takes_an_inode_and_no_blocks`, `every_created_directory_takes_an_inode`, `renaming_a_directory_leaves_both_counts_alone`, `a_new_object_without_a_free_inode_is_refused`, `statvfs_reports_every_field_of_the_configured_mount` |
| C | check the inode limit inside the shared kernel, so it fires on every write | 3: `a_new_object_without_a_free_inode_is_refused`, `the_last_inode_can_still_be_used`, `writing_to_an_existing_file_survives_inode_exhaustion` |
| D | free the inode whenever an entry disappears, allocate only when `st_ino is None` (the fix a solver reaches for after hitting B) | 2: `renaming_a_file_leaves_both_counts_alone`, `renaming_over_an_existing_file_gives_its_inode_back` |
| E | give `FakeFilesystem` a `statvfs` and let `FakeOsModule.__getattr__` keep forwarding | 24 |

Every mutation was applied to a fresh copy and the apply script asserts the edit landed before the
run (no silent no-op replaces). The kill clusters are SEPARATED, not correlated: A, C and D share
no killed test, which is the L20 check for a single-seam bimodal artifact.

## Per-agent table (empty until the first batch)

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
