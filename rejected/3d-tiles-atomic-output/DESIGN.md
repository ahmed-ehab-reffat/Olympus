# Design - failure-atomic pipeline publication

**Archived design record. It was approved on re-review and later implemented,
but the candidate was abandoned on 2026-07-23 because the platform environment
could not be made reliable. See `SUMMARY.md` for the terminal state.**

## Decision summary

`PipelineExecutor` will own one private publication transaction per non-empty
pipeline. Intermediate stages remain directory-backed, but run in a unique child
workspace under the configured temporary base. The final stage writes to a
second workspace under the nearest pre-existing directory ancestor of the
logical destination. This preserves support for missing destination parents
while keeping staging on the destination filesystem. Only a finalized final
target is renamed into place. An existing destination is first renamed into the
workspace as a backup, and restoration is attempted if publication fails.

This keeps the feature at the pipeline/CLI boundary. Raw targets, processors,
and `TilesetOperations` retain their current non-transactional contract.

## Review resolution

| Feedback | Revision |
|---|---|
| Missing destination parents | Publish staging now lives under the nearest pre-existing directory ancestor. Parent creation is deferred until finalization, tracked per directory, retained on success, and reversed with empty-directory removal on failure. T9 covers nested success and late-failure residue. |
| Implementation-coupled publication/cleanup faults | The proposed filesystem monkeypatch cases were removed. T10 is now a black-box non-directory-ancestor failure. No hidden test assumes rename APIs or a private commit sequence. |

## Trajectory-informed reopening gate - 2026-08-06

This gate records the evidence reviewed before the user-authorized environment
rehabilitation. The problem remains abandoned while the environment is being
tested. No prompt, test, solution, or runner revision is authorized by this
record, and `test.patch` remained at
`e482e67f2bbc965c4b080ab2efc3da3f1971af8a452184fa53f2a04a6d1876e9`
through the review.

### Searches and source evidence

The reopening search covered `PROBLEM_DESIGN.md`, `problems/README.md`,
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, this problem's
`SUMMARY.md`, `DESIGN.md`, `LEVELS.md`, `ERRORS.md`, and `RUNS.md`, plus
`archive/3d-tiles-atomic-output/MANIFEST.md`. The raw archive was listed with
`tar -tzf`, and the trajectories, evaluator records, run records, test logs,
and solution patches for runs 1, 2, and 3 were inspected directly with
`tar -xOf` and `jq`. Production patch statistics for the other legitimate
passes, runs 5, 6, and 9, were also read from the raw archive.

The current upstream checkout was frozen at
`4ca692eb16a9c7db21ec99e2aacc32645ce92f28`, dated 2026-07-24. It still has no
recognized JavaScript lockfile, and `package.json` still invokes undeclared
`tsx` and `copyfiles`. Comparing the original problem base
`8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff` with this head found no changes to
the pipeline executor, processor contexts, target factories, or package target
implementations; the relevant upstream delta is confined to unrelated Cesium
primitive-outline data and coverage.

### Representative raw solver evidence

| Class | Raw record | Approach, validation, and decisive evidence |
|---|---|---|
| Legitimate pass | `agent-runs/Nova_Nova_3` | Traced `PipelineExecutor`, processor finalization, filesystem targets, and both package targets before changing code. Added a private publisher beside the executor, built the final result away from the destination, seeded directory candidates to retain unrelated entries, replaced packages whole, and used backup/restoration plus owned-parent cleanup. Proactively exercised directory, custom-JSON, package, same-storage, finalizer-failure, collision, and missing-parent behavior. The evaluator reported 30/30 focused and 869/869 baseline passes. The retained patch changes two production files with 394 insertions and 33 deletions; strict effective production LOC was not reported. |
| Near-pass | `agent-runs/Nova_Nova_2` | Independently chose the same stage-then-publish architecture and added a private publisher. It found and corrected a custom-JSON basename problem through a real CLI integration and isolated unrelated Node 24 cleanup failures with a temporary compatibility shim. It passed 26/30 focused cases and all 869 baseline cases, but overwrite-disabled directory and package collisions escaped as plain `Error` rather than the repository's documented `PipelineError`. The production patch has 420 insertions and 33 deletions; strict effective production LOC was not reported. |
| Broad behavioral failure | Unavailable | No retained run is a representative broad behavioral failure. Run 1 implemented the substantive transaction, compiled it, ran focused checks and real-target probes, but the platform verifier executed zero behavioral tests because `npx --no-install tsx` could not find a local executable. Its separate Node 24 cleanup noise and incomplete lint installation are environment evidence, not a substitute behavioral failure. |

The other legitimate passes were also architecture-compatible but not
identical: runs 5 and 9 used an executor plus private publisher, while run 6
kept the transaction in `PipelineExecutor.ts`. Their raw production changes,
including run 3, touched 427, 391, 367, and 403 added/deleted lines
respectively, for a median of 397 touched production lines. The corresponding
insertion median is 364.5 lines. These raw patch measures are not strict
effective LOC, which is unavailable in the retained evaluator records, but they
supersede the original 194-line reference estimate as the stronger observed
scope signal. The one-file run 6 pass must remain legitimate; tests may not
require a publisher helper or the reference file split.

### Trajectory-informed discriminator ledger

| Observed evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Anti-overfitting rationale |
|---|---|---|---|---|
| Every inspected solver first found that the final stage wrote directly to the destination; successful solvers moved the commit boundary until after finalization. | Write the final stage in place, or delete a partial destination after failure. | A pre-existing logical output is unchanged and an absent output remains absent when processing or target finalization fails. | Snapshot logical names and bytes before a deterministic late failure, then reopen package outputs through public sources and compare the post-call destination. | Observes only the public storage result. A sibling candidate, private temp tree, in-memory plan, or any other correct commit mechanism passes. |
| Run 2 preserved the output transaction correctly but returned plain `Error` on overwrite refusal. Runs 4, 7, 8, and 10 later repeated the same miss according to `RUNS.md`. | Implement the main state invariant while weakening an adjacent public failure carrier. | Pipeline publication failures preserve the executor's repository-documented `PipelineError` boundary without sacrificing destination preservation. | Trigger a normal public collision/refusal, assert the public error class, and independently compare the untouched destination. | This is a distinct API/error-surface boundary supported by production documentation, not a demand for exact prose or a private wrapper location. |
| Runs 1 and 2 found custom-JSON basename problems during real integrations before final verification. | Treat a JSON path as a standalone file or silently fall back to `tileset.json`. | A JSON output names directory-backed logical storage while preserving the requested top-level basename. | Run through the public pipeline entry point, enumerate the resulting logical directory, and parse the requested JSON name. | Tests path semantics, not the helper used to map storage and target-facing names. |
| Run 3 explicitly tightened partial-parent cleanup; successful runs exercised custom temp bases and missing destination ancestry. | Create destination parents before the result is final, clean only on success, or recursively remove caller-owned ancestry/base paths. | Invocation-owned temporary children and newly created failed-output parents are removed, while the nearest pre-existing ancestor and configured temp base survive. | Compare before/after entry and byte snapshots of the public ancestor and caller-supplied temp base across success and failure. | Ownership is independently observable and crosses a cleanup boundary; temporary basenames, call counts, and filesystem API choices remain unconstrained. |
| The successful solutions converged on one transaction but used both one-file and helper-based implementations across four storage forms. | Count every filename or storage-format permutation as a separate discriminator, or require the dominant helper architecture. | Directory merge semantics, package replacement semantics, logical JSON naming, and failure-atomic commit each remain behavioral boundaries; repeated fixtures within one boundary are coverage only. | Reopen outputs through repository readers and compare their logical contents, overwrite results, and failure snapshots. | Preserves all legitimate architectures and prevents format breadth from being mistaken for extra implementation depth. |
| Run 1 was blocked by missing environment tooling before the verifier loaded any behavioral case. | Interpret bootstrap failure as a solver failure or add behavioral tests to compensate for image uncertainty. | The pristine image must contain every declared build/test tool and run the complete harness offline before any solver is evaluated. | Build from the exact upstream context, disable runtime networking, then run local binary discovery, build, and the pre-existing test entry point. | Keeps infrastructure qualification outside the challenge discriminator set and cannot favor a private solution design. |

No new discriminator is justified by the unavailable broad-failure category.
In particular, the reopening must not introduce filesystem-call mocks, exact
temporary names, rename sequencing, arbitrary failure permutations, or a
required `PipelineOutputPublisher` class merely to manufacture another failure
family.

## Hard-rule ledger

| ID | Rule | Design consequence |
|---|---|---|
| H1 | The final target is private until every stage and target finalizer succeeds. | The last stage never receives `pipeline.output`; it receives a same-filesystem staging name. |
| H2 | A processing or target-finalization failure preserves an existing destination exactly, or leaves an absent destination absent. | No destination mutation or missing-parent creation occurs before the complete staged result exists. |
| H3 | Directory, `.json`, `.3tz`, and `.3dtiles` forms behave alike. | Logical storage and target-facing names are resolved separately, and package suffixes are preserved in staging. |
| H4 | Existing overwrite behavior is unchanged. | Existing directories seed staging and use the caller's overwrite flag; packages retain whole-file collision behavior. |
| H5 | Equal logical input/output is supported with overwrite enabled. | Input remains at its original path until the finalized staged output is ready to publish. |
| H6 | Invocation-owned temporary paths are removed after ordinary success and failure. | Both workspaces have one cleanup path; a configured base is never a cleanup target, and newly created destination parents are removed in reverse after failed publication. |
| H7 | Publication failure after backup creation triggers restoration without risking the only original copy. | If restoration succeeds, normal cleanup continues. If restoration also fails, the backup workspace is retained for operator recovery. |
| H8 | Cleanup cannot replace the causal error. | The first processing/publication error is captured and rethrown; cleanup errors are secondary. |
| H10 | Implementation artifacts remain private. | No public transaction class, staging-name option, or new export is introduced. |

Exact recovery-workspace names and filesystem call choices will not be part of
the contract.

## Upstream re-audit

The re-audit on 2026-07-23 still yields `proceed`.

- `git ls-remote origin refs/heads/main` returned
  `8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff`, exactly the pinned base.
- The current issue list has no item newer than unrelated issue
  [#207](https://github.com/CesiumGS/3d-tiles-tools/issues/207), opened on
  2026-07-16. Repeated searches for atomic, transactional, rollback, partial
  output, cleanup, temporary pipeline output, overwrite failure, destination,
  and target failure found no equivalent issue.
- The open pull requests are unrelated drafts/features
  [#202](https://github.com/CesiumGS/3d-tiles-tools/pull/202),
  [#195](https://github.com/CesiumGS/3d-tiles-tools/pull/195),
  [#194](https://github.com/CesiumGS/3d-tiles-tools/pull/194), and
  [#135](https://github.com/CesiumGS/3d-tiles-tools/pull/135). The same concept
  searches over open and closed pull requests found no publication transaction.
- The repository navigation still has no Discussions surface.
- `CHANGES.md`, the history of `PipelineExecutor.ts`, and repository code
  contain no equivalent behavior. The executor still has its temporary-cleanup
  TODO at the base commit.

The prior audit's adjacent issue/PR findings remain non-equivalent: #8 and #11
concern content/test cleanup, #118 concerns type detection, #57 is general
cleanup, and #167 changes source/target methods to asynchronous methods.

## Repository evidence

| File | Observed contract relevant to this design |
|---|---|
| `src/tools/pipelines/PipelineExecutor.ts` | Selects final/intermediate paths and delegates every stage; it currently writes the last stage directly and leaks multi-stage temporary output. |
| `src/tools/pipelines/TilesetStageExecutor.ts` | Converts processing failures to `PipelineError`; successful paths await processor/target finalization. |
| `src/tools/tilesetProcessing/TilesetProcessorContexts.ts` | Resolves `.json` basenames separately from storage and closes source before target on normal completion. |
| `src/tilesets/tilesetData/TilesetTargets.ts` | Selects directory, 3TZ, or 3DTILES targets from the target-facing suffix. |
| `src/tilesets/tilesetData/TilesetTargetFs.ts` | Uses entry-level overwrite and retains unrelated files in an existing directory. |
| `src/tilesets/packages/TilesetTarget3tz.ts` | Deletes an existing package at `begin`, streams entries, and becomes complete only at `end`. |
| `src/tilesets/packages/TilesetTarget3dtiles.ts` | Deletes an existing package at `begin`, writes in a transaction, and commits/closes at `end`. |
| `specs/SpecHelpers.ts` | Supplies source-backed package comparison and recursive file-name collection oracles. |

## Late-failure lifecycle prototype

The scratch probe used one real `optimizeGlb` content stage with a tileset whose
first content was the valid `specs/data/gltf/Box.glb` and whose second content
began with the GLB magic but was malformed. Thus the first content was accepted
by the target before deterministic processing failure on the second.

| Target | Returned error | Partial path after failure | Immediate recursive/unlink cleanup | Process exit |
|---|---|---|---|---|
| `.3tz` | `PipelineError` | Present, 4 bytes observed | Succeeded; path absent afterward | Normal |
| `.3dtiles` | `PipelineError` | Present, 0 bytes observed before commit | Succeeded; path absent afterward | Normal |

The current error path leaves target objects unfinalized, but their open POSIX
file handles did not block removing private staging paths and did not keep the
Node process alive. Therefore an internal processor/target abort API is not
required for the scoped guarantee. This result must be repeated in the offline
Linux image after approval. If Linux cleanup is not deterministic, the design
gate reopens rather than silently adding lifecycle APIs.

## Exact logical-path mapping

All filesystem decisions use an absolute normalized form of `pipeline.output`.
The user-facing pipeline object is not modified.

| Output form | Logical destination | Final-stage argument | Existing-output preparation | Final-stage overwrite |
|---|---|---|---|---|
| `/p/out` (no suffix) | directory `/p/out` | `<publish-workspace>/staged` | Recursively copy `/p/out` to `staged` if it exists | Caller value |
| `/p/out/custom.json` | directory `/p/out` | `<publish-workspace>/staged/custom.json` | Recursively copy `/p/out` to `staged` if it exists | Caller value |
| `/p/out.3tz` | file `/p/out.3tz` | `<publish-workspace>/staged.3tz` | Do not seed; reject an existing logical file when overwrite is false | `true` for the private target |
| `/p/out.3dtiles` | file `/p/out.3dtiles` | `<publish-workspace>/staged.3dtiles` | Do not seed; reject an existing logical file when overwrite is false | `true` for the private target |

The executor walks upward from the logical destination's parent until it finds
the nearest existing directory. An existing non-directory component is skipped
for workspace placement but recorded as a publication blocker. The publish
workspace is created with `mkdtemp` directly in that directory. Its `staged` and
`backup` children are therefore on the filesystem that will contain the
destination even when one or more destination ancestors are absent.

Missing destination parents are not created before processing. After the final
target has been finalized, publication creates each missing directory from the
nearest existing ancestor downward, using non-recursive single-directory
operations and recording every directory actually created by this invocation.
If parent creation or publication fails before a new destination is installed,
those directories are removed in reverse order with empty-directory removal,
never recursive deletion. A pre-existing file in the parent chain causes a late
publication error after staging; the file is not modified.

On success, newly created destination parents remain because they are part of
the requested output path. On failure, the nearest pre-existing ancestor has the
same entry set it had before the call. The publish workspace is always
invocation-owned, except that it becomes a retained recovery workspace if it
contains the only preserved original after restoration failure.

The `.json` basename is carried only in the target-facing argument; publication
renames the containing staged directory. An unsupported suffix remains
unsupported because the suffix is retained in its staged target name.

For two or more stages, the intermediate workspace is a separately generated
child of `PipelineExecutor.tempBaseDirectory` or the OS temporary directory.
Only that child is removed. Intermediate output names have no suffix, preserving
the current directory-backed behavior. A zero-stage pipeline remains a no-op and
does not create either workspace.

### Filesystem ownership ledger

| Path | Created when | Success cleanup | Failure cleanup |
|---|---|---|---|
| Publish workspace under nearest existing directory ancestor | Before stage execution | Remove after commit | Remove after ordinary rollback; retain only if it holds the sole original after restoration failure |
| Final staged storage inside publish workspace | During final stage | Consumed by publication | Remove with publish workspace |
| Backup inside publish workspace | Only when replacing an existing destination | Remove after the new output is installed | Rename back to destination; never delete if restoration fails |
| Missing destination-parent directories | After final target finalization, immediately before publication | Retain as requested output ancestry | Remove in reverse if empty and no destination was installed |
| Intermediate child under configured/OS temp base | Only for multi-stage execution | Remove child | Remove child; never remove configured base |

## Publication state machine

| State | Destination ancestry | Destination | Staging | Backup | Permitted next action |
|---|---|---|---|---|---|
| Prepared | Pre-call state | Original or absent | Being built | Absent | Run all stages and finalize target |
| Staged | Pre-call state | Original or absent | Complete | Absent | Create missing parent directories, tracking ownership |
| Parent-ready | Complete path exists | Original or absent | Complete | Absent | Rename existing destination to backup, if any |
| Backed up | Complete path exists | Absent | Complete | Exact original | Rename staging to destination |
| Published | Complete path exists | Complete new output | Absent | Exact original or absent | Remove backup |
| Committed | Complete path exists | Complete new output | Absent | Absent | Clean ordinary workspaces and return |

Failure transitions are as follows.

1. A processing/finalization failure in Prepared or Staged removes staging and
   intermediate work. Neither the destination nor missing destination parents
   were touched.
2. Failure creating a destination parent removes invocation-created parents in
   reverse when empty, removes workspaces, and leaves the nearest pre-existing
   ancestor unchanged.
3. Failure moving the destination to backup leaves the destination unchanged;
   any invocation-created parents are removed when they are not part of an
   existing destination path.
4. Failure moving staging into place after backup creation immediately attempts
   to rename backup back to the destination. Successful restoration permits
   normal staging/workspace cleanup and the first publication error is rethrown.
5. Failure moving a new output into place leaves the destination absent, then
   removes staging and invocation-created empty parents.
6. If restoration itself fails, the logical destination may be absent. The
   original remains at the backup location inside the publish workspace. That
   workspace is deliberately retained and excluded from automatic cleanup so
   the only preserved copy cannot be lost. The call throws the original
   publication `PipelineError`; the restoration error and retained workspace are
   reported through diagnostics without replacing it. Recovery and later
   removal belong to the operator.

No copy-based publication or cross-device fallback is used. Directory merge
semantics happen before publication by seeding staging; publication itself is a
whole-storage rename.

## Error precedence

The executor captures errors without stringifying or rewrapping an existing
`PipelineError`.

1. An existing stage `PipelineError` is rethrown as the same error object.
2. A collision detected by pipeline preflight or a filesystem publication error
   is exposed as `PipelineError`, matching `executePipeline`'s documented error
   type.
3. Backup restoration, created-parent removal, and workspace cleanup are
   attempted while a primary error is pending, but their errors cannot replace
   it. Independent cleanup continues after any one cleanup action fails.
4. Once the new destination is installed, later backup/workspace cleanup trouble
   is diagnostic and does not turn a valid published result into a rejected
   pipeline call.
5. Restoration failure retains the publish workspace as described by the state
   machine. Intermediate work is still cleaned independently.

This preserves the existing causal message chain produced by stage executors,
prevents rollback noise from hiding it, and avoids reporting a failed pipeline
after the new destination has already been committed.

## Shallow implementations ruled out

| Incorrect approach | Decisive public observation |
|---|---|
| Write directly to the destination | A late failure changes an existing sentinel tree/package and leaves an absent destination present. |
| Delete partial output on error | An existing logical destination disappears rather than remaining byte-for-byte identical. |
| Back up package files only | Directory and `.json` sentinel snapshots change on late failure. |
| Stage files but write directories directly | Directory rollback and custom JSON basename cases fail. |
| Replace an existing directory without seeding | A successful overwrite loses the unrelated sentinel; overwrite-false entry semantics also change. |
| Treat `.json` as a file destination | The wrong storage is published and the requested top-level JSON basename is absent. |
| Give staged packages a suffixless name | The directory backend is selected and the result is not a readable package. |
| Clean only after success | Parent-directory and custom-temp-base entry censuses retain invocation residue after failure. |
| Remove the configured temp base | The caller's base and its sentinel disappear. |
| Require the immediate destination parent to exist | Nested outputs that current targets accept fail before processing. |
| Eagerly create missing destination parents | A late processing failure leaves new directories in the nearest pre-existing ancestor. |
| Recursively delete created ancestry on failure | A pre-existing blocker/sentinel inside the ancestor is damaged. |

## Discriminator matrix

| Public case | Discriminator A: process before publication | Discriminator B: logical/backend parity |
|---|---:|---:|
| Late failure with existing directory and `.json` sentinel trees | Primary | Primary |
| Late failure with existing 3TZ and 3DTILES sentinel packages | Primary | Primary |
| Late failure with all destination forms absent | Primary | Reinforcement |
| Successful seeded directory/`.json` overwrite | Reinforcement | Primary |
| Successful package replacement and source-backed validation | Reinforcement | Primary |
| Overwrite-disabled directory-entry and package-file collisions | Reinforcement | Primary |
| Equal logical input/output for directory and package | Primary | Primary |
| Success/failure under a custom temp base | Reinforcement | Reinforcement |
| Nested absent destination parents on success and failure | Primary | Reinforcement |
| Non-directory destination ancestor causing publication-preparation failure | Reinforcement | Reinforcement |

The suite will assert final public trees, file bytes, source-readable package
entries, error classes, and before/after ancestor entry sets. It will not mock a
filesystem function or assert temporary basenames, log text, rename use, or a
filesystem call count.

## Clause-to-test ledger

Test IDs below describe the intended hidden specs; no test files exist yet.

| Clause | Maintainer-facing behavior | Planned public oracle |
|---|---|---|
| C1 | Pipeline output becomes visible only after all processing and finalization succeeds. | T1, T2, and T3 use a deterministic second-content failure after the first target entry. |
| C2 | Processing or target-finalization failure preserves an existing destination exactly and leaves an absent one absent. | T1 snapshots directory names/bytes; T2 snapshots package bytes/entries; T3 checks absence. |
| C3 | The guarantee covers directories, custom `.json` paths, 3TZ, and 3DTILES. | T1-T6 parameterize all four logical forms where applicable. |
| C4 | Successful directory updates retain unrelated files, while overwrite-disabled collisions fail without mutation. | T4 checks seeded success; T6 checks directory entry and package whole-file collisions. |
| C5 | Equal logical input and output can succeed with overwrite enabled. | T7 runs a no-op/copy pipeline in place for a directory and each package backend, then reads every result. |
| C6 | Executor-owned temporary paths are removed after ordinary success and failure without removing a custom base. | T3 and T8 compare ancestor/base entry sets and retain a base sentinel. |
| C7 | Nested outputs retain current missing-parent support, and failed processing leaves the nearest pre-existing ancestor free of new parent/workspace residue. | T9 covers successful publication and deterministic late failure with multiple absent ancestors. |
| C8 | Ordinary processing and publication-preparation failures retain the pipeline error type and causal information. | T1-T3 check the late GLB `PipelineError`; T10 uses a pre-existing file in the destination ancestry and checks that it is unchanged. |

## Test-to-clause ledger

| Test | Scenario and assertions | Clauses |
|---|---|---|
| T1 | Existing directory and custom-JSON destinations; late failure; exact recursive name/byte snapshot; unrelated file retained; no parent residue. | C1, C2, C3, C4, C6 |
| T2 | Existing valid 3TZ and 3DTILES destinations; late failure; exact file bytes plus source-readable entry equality; no parent residue. | C1, C2, C3, C6 |
| T3 | Absent directory, JSON-directory, 3TZ, and 3DTILES destinations; late failure; destination absent and parent entry set unchanged. | C1, C2, C3, C6 |
| T4 | Successful overwrite of existing directory and custom-JSON directory; new entries and requested JSON basename published; unrelated sentinel retained. | C3, C4 |
| T5 | Successful overwrite of existing 3TZ and 3DTILES; complete replacement opens through `TilesetSources` and matches expected entries. | C3, C4 |
| T6 | Overwrite false with a colliding directory entry and each existing package; `PipelineError`; exact original snapshot unchanged. | C2, C3, C4 |
| T7 | Input/output resolve to the same directory, 3TZ, and 3DTILES storage with overwrite true; complete source-readable result. | C3, C5 |
| T8 | Multi-stage success and late failure with a configured temp base containing a sentinel; base and sentinel survive and its child entry set is unchanged. | C6, C8 |
| T9 | Output lies below at least two absent parent directories. Success produces a readable directory/package. A separate late processing failure leaves the logical destination absent and the nearest pre-existing ancestor's recursive name/byte snapshot unchanged. | C1, C2, C6, C7 |
| T10 | A successful copy/no-op pipeline targets a path whose required ancestor component is a regular file. `executePipeline` rejects; the blocker bytes and nearest directory ancestor snapshot remain unchanged and the error is a `PipelineError`. No assertion depends on when the implementation detects the blocker. | C6, C8 |

T9 and T10 are black-box filesystem setups. They require no knowledge of whether
a solution uses synchronous, promise-based, or callback filesystem APIs. There
is no deterministic, implementation-independent setup that forces a single
failure specifically between moving an existing destination aside and
installing staging, or that makes only cleanup fail. Therefore the hidden suite
will not monkeypatch Node filesystem functions to manufacture either combined
fault. Backup restoration and secondary-error precedence remain required design
and reference-solution review points, but are not normative hidden-test clauses.

## Mutation obligations

Each planned mutation has at least two behavioral assertions, not compilation,
that reject it.

| Mutation | Assertions that fail |
|---|---|
| Direct final write | T1 exact snapshot/unrelated bytes; T2 exact package bytes/source readability; T3 absence |
| Delete-on-error without restore | T1/T2 destination presence and exact snapshot |
| File-only staging | T1 directory rollback and T4 seeded preservation |
| No directory seed | T4 unrelated sentinel and T6 overwrite-false collision |
| Incorrect `.json` resolution | T1 rollback snapshot and T4 requested basename/preservation |
| Cleanup only on success | T3 parent entry census and T8 failure base census |
| Delete configured temp base | T8 base presence and sentinel bytes |
| Wrong staged package suffix | T2 error/original oracle and T5 package source-readability |
| Assume destination parent already exists | T9 nested success/readability and nested-failure ancestor census |
| Create missing parents before processing | T9 failed-call destination absence and nearest-ancestor census |
| Delete parent ancestry recursively | T9 nearest-ancestor snapshot and T10 blocker bytes/ancestor snapshot |

Omitted-backup-restoration and cleanup-error-precedence mutations are not used
for calibration. Killing them would require monkeypatching an implementation
filesystem call or asserting a private commit sequence, so they cannot be fair
black-box behavioral mutations. The reference implementation must still contain
the restoration/preservation branches in the state machine, and code review
will verify them without presenting their mechanics as solver-visible behavior.

## Scope and size check

A revised method-level sizing pass, excluding comments and blank lines, budgets 194
effective production lines in one existing file:

| Area | Effective lines |
|---|---:|
| Logical destination, existing-ancestor search, and staging mapping | 38 |
| Workspace creation, seeding, and package collision preflight | 34 |
| Intermediate/final stage coordination | 40 |
| Parent ownership, publication, and backup restoration | 45 |
| Error precedence and cleanup | 37 |
| Total | 194 |

No target, processor, or public export change is currently justified. The
expected implementation therefore remains inside the plan's 150-200 line
boundary. If the Linux lifecycle repeat requires an abort protocol, or the
production diff honestly exceeds 200 effective lines, implementation stops and
this design returns for approval instead of broadening scope.

## Approval gate

Approval authorizes the next plan phase: write the ASCII, sub-500-word
`meta.md`; create the external specs and offline base/new harness; verify that
base mode passes and new mode fails for behavioral reasons; and only then
implement the reference solution in the separate solution worktree.
