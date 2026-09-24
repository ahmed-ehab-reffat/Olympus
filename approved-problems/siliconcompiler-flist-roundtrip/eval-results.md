# eval-results.md - siliconcompiler-flist-roundtrip

## Batch 1 (agent-runs/1): 0 of 11

10 Nova plus 1 Vega, all evaluated by Nova. **0/11 passed.** Every run kept the baseline green (559
passed), so this was the new suite, not regressions. Every agent changed only `siliconcompiler/design.py`
(plus its own tests in `tests/test_design.py`); none touched `pathschema.py` or `filesetschema.py`.

| Run | New passed (as graded) | Real fails | Lost to the helper | Replay, fixed helper |
|---|---|---|---|---|
| Nova 1 | 48/58 | 3 | 7 | 55/58 |
| Nova 2 | 45/58 | 6 | 7 | 52/58 |
| Nova 3 | 45/58 | 7 | 6 | 51/58 |
| Nova 4 | 44/58 | 8 | 6 | 50/58 |
| Nova 5 | 45/58 | 7 | 6 | 51/58 |
| Nova 6 | 48/58 | 3 | 7 | 55/58 |
| Nova 7 | 45/58 | 6 | 7 | 52/58 |
| Nova 8 | 46/58 | 7 | 5 | 51/58 |
| Nova 9 | 46/58 | 5 | 7 | 53/58 |
| Nova 10 | 45/58 | 7 | 6 | 51/58 |
| Vega | 45/58 | 7 | 6 | 51/58 |

### Why it read 0%: three defects of mine, one wall, and the real traps underneath

**1. A test helper called an API only the reference has.** `unrooted_entries()` used
`design.get_filetypes()`, which the reference adds and the task never asks for. Every run raised
`AttributeError` in 5 to 7 tests. Replaying the agents' own patches against a base-API helper shows
those tests **passing** for nearly every run: the helper was hiding work they got right. A mechanical
audit now confirms every method the tests call exists on base.

**2. The `-G` spelling was ambiguous (4 tests, 9 to 11 of 11, identical failure).** The sentence read
"as `-G` and the name joined to the value by an equals sign", in a paragraph where every other part
("`-top` and the name", "`-y` and the path") is space separated. All 11 writers emitted
`-G ADDR=16`; the same readers then failed to parse the glued `-GDEPTH=4`. Identical failure in every
run is ambiguity, not difficulty. The sentence now spells out the glued form with an example.

**3. "a root registered earlier" had two readings.** Earlier in this read, or earlier in the design's
life. The `file://` case added under Solution Quality round 4 killed **11/11**: no agent resolved a
URI-spelled root. Cut in all three places at once (test, contract sentence, reference), per the
gate-ratchet lesson. The plain pre-existing-root case is kept, because it discriminates (5/11 pass)
and is orthogonal to the dependency trap; its sentence now names both kinds of existing root.

**The traps that remain are real.** On the revised suite, replaying every agent's actual code:

| Test | Kills | What it measures |
|---|---|---|
| `test_read_records_a_nested_edge_on_the_group_that_carries_it` | 6/11 | trap 3: edges belong to the carrying group; failing runs attached `tail` to the reader as well |
| `test_read_reuses_a_dataroot_the_design_already_had` | 6/11 | a root the design already had counts as existing |
| `test_read_group_with_no_content_is_still_a_fileset_of_its_design` | 1/11 | empty marked group is still a fileset |
| `test_roundtrip_keeps_a_dependency_whose_fileset_is_empty` | 1/11 | same, through the writer |
| `test_read_shares_one_dataroot_between_a_library_directory_and_files` | 1/11 | libdir inside a file's root |

The dependency trap and the pre-existing-root trap are independent: runs 4 and 8 fail one and pass the
other, runs 2 and 7 the reverse.

### Projection for batch 2

Replaying the 11 saved patches against the revised suite, and counting the four `-G` tests as fixed by
the description: **3/11 (27%)**, runs Nova 1, 6 and 9. Discount rule L35 applies: the replay measures
test deltas, and the `-G` fix is a description delta. It can only remove failures, and the explicit
`-GWIDTH=8` example should do that, but the live number is the evidence. Clarifying the dependency
sentence as well would read **9/11**, so that sentence was deliberately left as it is: it is true, the
precise attachment rules sit beside it, and it is the trap carrying the band.

**Batch 2 must be a full batch, not a re-eval:** the description changed.

## Environment

- Image built from the submission `Dockerfile` on `public.ecr.aws/d3j8x8q7/olympus-base-python:latest`.
- **The clean room now mirrors the platform's order exactly: the image is built from a pristine
  clone at the base commit with NO patch applied, and `test.patch` and `solution.patch` are applied
  inside the container.** Earlier rounds built the image from a tree that already had `test.patch`
  in it, which is not what the platform does and is why three rounds of green local runs did not
  predict the platform result.
- The clean room is a real `git clone`, so `.git` is in the build context as it is on the platform.
- Cold `docker build --no-cache`: **109 s / 224 s** with `.git` and `docs/` in the context (157 MB).
  It was **586 s** before the apt `graphviz` install was dropped (it only gates four `has_graphviz`
  tests, which skip themselves) and `chmod -R a+rwX /app` was folded into `COPY --chown=1000:1000`.
  That chmod layer alone measured **272 s** in isolation, because it copies the whole tree up into a
  new layer.
- Every run below: `docker run --rm --network none`, patches applied with `git apply`, hunks verified
  present afterwards.

## Platform failures found and fixed

| Symptom | Cause | Fix |
|---|---|---|
| Image build exits 1: `fatal: detected dubious ownership in repository at '/app'`, `git introspection failed` inside `pip install -e` | `COPY --chown=1000:1000` leaves the repo owned by uid 1000 while the build runs as root, so git refuses the repo and setuptools_scm's file finder dies | `git config --system --add safe.directory '*'` as the first command of the RUN |
| Verify Tests / Verify Solution FAIL, `testsuite::collection (failed)`, 1 test | that testcase is **this suite's own no-XML fallback**: pytest recorded nothing, and the fallback said only "the test runner exited before any test was recorded" | the fallback now embeds the last 60 lines of pytest's output in the `<failure>` body, so the next report names the real cause; base mode dropped from 2116 to 569 tests; `HOME`, `TMPDIR` and `--basetemp` moved into one run directory chosen from the first writable of `$TMPDIR`, `/tmp`, `/app`, and removed on exit |
| `missing test targets: /app/tests/test_design.py /app/tests/test_library.py /app/tests/schema_support`, then `fixture 'datadir' not found` | **the platform builds the image from the UNPATCHED repo and applies `test.patch` inside the container**, so the repo's `.dockerignore` (which excludes tracked `/tests/`, `/docs/`, `/examples/`, `/setup/docker/`) had already dropped them, and no edit to `.dockerignore` from `test.patch` could ever take effect | the Dockerfile runs `git checkout -- .` at build time, which restores every excluded tracked path from the `.git` that is in the context; `.dockerignore` is no longer touched by `test.patch` at all |
| `git status` showed an untracked `/app/.cache/` | pip creates `~/.cache/pip` at build time even under `--no-cache-dir`, and `HOME` is `/app` | `rm -rf /app/.cache` in the same RUN |
| `git apply solution.patch` warned `has type 100755, expected 100644` on every source file | `COPY --chmod=777` rewrites every file mode | dropped `--chmod`; `--chown` alone preserves modes |

The ownership failure and the phantom deletions are invisible without `.git` in the build context,
which is why the first four validation rounds missed them. The clean room is now a real clone.

### Harness failure modes, each forced and checked

| Condition | Result |
|---|---|
| a configured base target missing (`tests/test_library.py` moved away) | exit 1; one failing testcase, message `configured test targets are missing`, body naming the path and listing `/app` |
| pytest writes no XML (`PYTEST_ADDOPTS=--no-such-flag`) | exit 1; one failing testcase, message `pytest produced no test results (exit 4)`, body carrying pytest's own error |
| pytest runs and fails | pytest's JUnit and its nonzero exit, unchanged |

Before Auto Review round 5 the missing-target branch only logged the absent paths and then ran the
survivors, so a deleted base target plus green survivors exited 0. Both failure branches now share one
`fail_junit` helper.

### Harness comments

`test.sh` ships with its shebang as its only comment. An earlier revision documented the
`tests/schema` exclusion inline, which Auto Review scored a **Blocker**: naming which source areas
the solution does and does not touch is platform content in a solver-facing file. The reason lives
here instead. Pre-submit check over the added lines of both patches:

```
for f in test.patch solution.patch; do grep -E '^\+' "$f" | grep -v '^+++' | sed 's/^+//' \
  | grep -inE "solution|on base|base mode|grader|grading|reviewer|challenge|hidden|agent|author"; done
```

### Base-mode scope and why `tests/schema` is excluded

`tests/schema` is 1547 of the original 2116 and covers `siliconcompiler/schema` (BaseSchema,
Parameter, EditableSchema), which the solution does not touch. The three files it does touch are
guarded by `tests/test_design.py` (114), `tests/test_library.py` (37) and `tests/schema_support`
(414), which is where `pathschema` and `filesetschema` are tested. Base mode is those three plus
the 4 preservation tests, 569 collected. The reason is also recorded in `test.sh` itself.

After the fixes, `git status` inside the image reports only the harness files: `.dockerignore`
modified, and `Dockerfile`, `test.sh` and the two new test files untracked. Applying
`solution.patch` modifies exactly the three source files.

## Lane-death gate (SATURATED-REPOS.md "tool-harness" row)

| Check | Result |
|---|---|
| `pip install -e ".[test,server]"` at build time | PASS |
| Scoped base suite, `--network none` | **570 passed, 0 failed, 11 skipped** |
| Any EDA binary reached | NO - `eda` / `docker` / `nightly` / `slurm` markers excluded, and the image installs no tool at all |

Gate verdict: **CLEARED for this lane.** The flist reader and writer and everything guarding them is
pure schema and serialisation code.

## 4-state matrix (Docker with `.git` present, `--user 0:0`, which is what the platform grades as)

| State | Mode | tests | failures | errors | skipped | Expected |
|---|---|---|---|---|---|---|
| base + test.patch | base | 570 | 0 | 0 | 11 | all pass - OK |
| base + test.patch | new | 57 | 57 | 0 | 0 | all fail - OK |
| base + test.patch + solution.patch | base | 570 | 0 | 0 | 11 | no regression - OK |
| base + test.patch + solution.patch | new | 57 | 0 | 0 | 0 | all pass - OK |

Run in the platform's order: image built from the unpatched base repo, both patches applied inside
the container.

Identical counts under `--user 1000:1000`, so nothing in this lane is permission-sensitive. The
image is writable as root and as uid 1000 (both verified by editing a source file inside it).

Re-running against base source with the `hierarchy` keyword accepted but ignored still gives 57/57
failures, so no test passes merely because the signature exists.

## Flakiness (mandatory gate)

Five runs of each mode in the container, solution applied, sorted `classname|name|status` lists
hashed:

| Mode | runs | tests | verdict |
|---|---|---|---|
| base | 5 | 570 | identical every run, md5 `b697e7c8dd0a8fd8b08626a5f3481691` |
| new | 5 | 57 | identical every run, md5 `10f38edab17b1e35cdd0c047053568a2` |

No duplicate JUnit ids in either mode, and no id containing `::` after `test.sh` normalises them.
`test.sh` passes `-p no:randomly` and does not use xdist, so the repo's `-n logical` CI ordering
risk does not apply.

## Auto Review round 1 (Revision Requested) and what changed

Description scored 3/3 and was called clean. Tests and Solution each scored 1/3 on three High
findings, all of them fair and all now fixed and covered by mutations that reproduce exactly the
wrong implementation the reviewer described.

| Finding | Wrong implementation it allowed | Fix | Mutation kills |
|---|---|---|---|
| S1: hierarchy output suppressed a repeated resolved path inside a group, so one source registered under two file types lost an entry on the round trip | reuse the flat writer's `write()` deduplication inside hierarchy groups | `write()` suppresses only when `hierarchy` is false; the per-group `written_cmd.clear()` is gone because hierarchy never consults the set | 6 |
| T3: the cycle test could not tell a currently-open set from an ever-seen one | one global `seen` set for the whole read, which also suppresses a legitimate second inclusion of a closed list | a test that includes one child list under two different groups in sequence | 1 |
| T4: multi-root assertions never inspected each value's `dataroot` metadata | register the right roots but store multi-root values as bare absolute paths | the helper now resolves each entry's `field="dataroot"` and checks that root really contains it | 4 |

The trap the first finding touched survives in a cleaner form: dropping suppression *everywhere* to
fix hierarchy still reds three base-mode tests, two of them the repo's own.

## FP prevention

### Per-branch mutation, run against BOTH modes

Each mutation restored from a pristine copy, with the edit asserted to have applied.

| Mutation | new-mode kills | base-mode kills |
|---|---|---|
| hierarchy output reuses the flat writer's deduplication (trap 1) | 6 | 0 |
| a global ever-seen include set instead of a currently-open one | 1 | 0 |
| multi-root values stored without their data root | 4 | 0 |
| file type passed down only on the `-F` branch | 1 | 0 |
| an include that opens groups loses its insertion point | 1 | 0 |
| an own-design group forced into the argument fileset | 1 | 0 |
| fallback references deduplicated by design name | 1 | 0 |
| a dependency edge recorded only on the traversal's first visit | 2 | 0 |
| include and library directories resolved against the child list's own directory | 1 | 0 |
| drop duplicate suppression entirely (the cheap fix for trap 1) | 0 | **3** (`test_write_fileset_duplicate`, `test_write_fileset_alias`, `test_write_default_output_unchanged`) |
| containment by string prefix (trap 5) | 1 | 0 |
| data roots per group instead of per design (trap 6) | 0 | 0 | (see note) |
| `-f` resolves like `-F` (trap 7) | 1 | 0 |
| no cycle guard | 1 | 0 |
| ignore the filetype marker (trap 8) | 2 | 0 |
| library directory kept out of the data-root set (trap 9) | 1 | 0 |
| writer drops the top module | 3 | 0 |
| writer drops undefines | 2 | 0 |
| reader drops depfileset edges | 1 | 0 |
| edges recorded on the reading design (trap 3) | 2 | 0 |
| unreferenced group not attached | 8 | 0 |
| skip a marked group that carries no content | 2 | 0 |
| do not materialise a group's fileset | 2 | 0 |
| sub-list drops the enclosing file type | 2 | 0 |
| a group marker clears the active file type | 1 | 0 |
| allocator ignores roots the design already had | 2 | 0 |
| edge map built without alias resolution | 2 | 0 |

The second row is the interdependence proof: the cheap fix for trap 1 reds three base-mode tests,
two of them the repo's own, which the agent's green baseline will not warn them about until they run
it.

Two mutations survive, both for structural reasons rather than test gaps.

**Per-group versus per-design data-root allocation** stopped discriminating once the allocator was
seeded from the roots the design already carries, because a fresh per-group allocator then re-reads
the roots the previous group registered and behaves identically. The sharing behaviour is still
true and still asserted; the two implementations are simply no longer distinguishable. The
per-design cache is kept because it states the intent and avoids rescanning the roots per group.

**Unsorted parameters** The schema's `getkeys` already returns names
sorted, so `sorted()` is a no-op. It is kept because it makes the documented order independent of
schema internals, and recorded here as a test that discriminates nothing. A second survivor from an
earlier round, innermost-vs-first data root, was provably unreachable (a root is only registered
when no existing root contains it, so of two nested roots the inner is always registered first and a
first-match scan already returns it); that branch was deleted as dead code and the claim was removed
from `meta.md`.

### Feature-stub and base-source runs

- Solution reverted to base source: **57 of 57 new tests fail**.
- Base source with `hierarchy` accepted and ignored: **57 of 57 still fail**.

So no new test is vacuous with respect to the feature, and none passes on its signature alone.

## Other local checks

| Check | Result |
|---|---|
| `flake8 7.3.0` on all changed source and test files, repo config | clean |
| Added comment lines in `solution.patch` (beyond the repo's own `###` separators) | none |
| Added comment lines in `test.patch` | none |
| `shipd` / `datacurve` in test names | none |
| `test.sh` mode in `test.patch` | `new file mode 100755` |
| Patches apply in both orders, unapply cleanly in both orders, tree byte-identical to base afterwards | OK |
| `file *.patch` | ASCII text |
| `file meta.md` | ASCII text, unwrapped paragraphs |
| `effective_loc_check.py solution.patch` | **human-effective 324**, 3 files |
| base mode at `--memory=512m`, `--memory=1g`, `--memory=2g` | 569 passed each time, so the platform's no-XML failure is not an OOM |
| `git status` inside the built image | only the harness files: `.dockerignore` modified, `Dockerfile`, `test.sh` and the two test files untracked |
| run directory left behind by `test.sh` | none (removed by an EXIT trap) |

## Owed

- Platform batch. Nothing else: picker eligible, precheck clean, six-check and canonical-org PR-DIFF
  re-run at FINISH.
- Re-run the six-check once more immediately before submit; the repo moves fast (PRs past 5412).
