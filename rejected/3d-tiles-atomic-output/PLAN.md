# PLAN - failure-atomic 3D Tiles pipeline output

**Status: ABANDONED ON 2026-07-23 FOR ENVIRONMENT UNSUITABILITY. This document
is retained as design and audit history; it is not an active handoff. See
`SUMMARY.md` and `ERRORS.md` for the closure decision.**

## 1. Task identity

| Field | Decision |
|---|---|
| Repository | `CesiumGS/3d-tiles-tools` |
| Language | TypeScript |
| Task type | enhancement |
| Base commit | `8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff` |
| Base version | `0.5.4` |
| License | Apache-2.0 |
| Work namespace | `work/3d-tiles-atomic-output/` |
| Primary API | `PipelineExecutor.executePipeline(pipeline, overwrite)` |
| Working title | Make pipeline output failure-atomic |

The task is to make pipeline publication transactional across the three output
representations that the repository already supports: a filesystem directory,
a `.3tz` archive, and a `.3dtiles` SQLite package. A failed pipeline must not
damage or partly replace its logical destination. A successful pipeline must
publish the completed output once and preserve the existing overwrite behavior.

The scope is the pipeline API and CLI path that uses it. Do not promise atomic
behavior for every direct `TilesetOperations`, processor, source, or target API.

## 2. Upstream eligibility and audit

The proposed base commit was also the default-branch head at the final preflight:
<https://github.com/CesiumGS/3d-tiles-tools/commit/8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff>.
The repository had 529 stars, an Apache-2.0 license, and active July 2026
development. GitHub reported that Discussions are disabled, so there was no
Discussion archive to search.

### Search ledger

All issue and pull-request searches covered open and closed states; merged pull
requests are included in the closed PR results.

| Surface | Concepts searched | Result |
|---|---|---|
| Issues | `atomic`, `transactional`, `rollback` | No equivalent issue. Issue #201 uses "atomic" only in the unrelated sense of tile content as a building block. |
| Issues | `partial output`, `output cleanup`, `cleanup output` | No result. |
| Issues | `temporary` or `temp` with `pipeline` or `output` | Adjacent issue #11 concerns test artifacts. Issue #8 concerns a content-cleanup stage. Neither concerns publication rollback. |
| Issues | `overwrite`, `destination`, or `target` with `failure` or `error` | No transactional-output proposal. Issue #118 concerns detecting input/output types. |
| Pull requests | The same four concept groups | No equivalent PR. PR #57 is general cleanup; PR #167 makes source/target methods asynchronous. |
| Code and tests | `atomic`, `transaction`, `rollback`, `partial`, `temporary`, `cleanup`, `overwrite` | No transaction helper or rollback path. `PipelineExecutor` contains a live TODO that its intermediate temporary directory is not cleaned. |
| Changelog and history | The same publication and cleanup concepts | No release entry or commit implementing failure-atomic publication. |

Useful primary links:

- Repository: <https://github.com/CesiumGS/3d-tiles-tools>
- Issues: [#8](https://github.com/CesiumGS/3d-tiles-tools/issues/8),
  [#11](https://github.com/CesiumGS/3d-tiles-tools/issues/11), and
  [#118](https://github.com/CesiumGS/3d-tiles-tools/issues/118)
- Pull requests: [#57](https://github.com/CesiumGS/3d-tiles-tools/pull/57)
  and [#167](https://github.com/CesiumGS/3d-tiles-tools/pull/167)

### Maintainer and repository fit

The repository deliberately abstracts directory, ZIP-based 3TZ, and
SQLite-based 3DTILES storage behind `TilesetSource` and `TilesetTarget`. The
README describes pipelines as accepting any tileset directory or package for
input and output. Centralizing publication at the pipeline boundary follows that
architecture and does not require a new storage format or an unrelated public
abstraction. No maintainer statement rejecting transactional output was found.

### Local similarity

No existing folder in `problems/` operates on TypeScript pipelines, ZIP/SQLite
backend parity, or filesystem publication. The accepted ACH task also involved
multi-stage mutation and rollback-like behavior, but its domain, API, data
model, and oracle are unrelated. This is not a named textbook algorithm and is
not enumerated by a public upstream roadmap.

### Audit verdict

`proceed`. The feature is distinct from all located upstream work, fits the
existing architecture, and has public, deterministic cross-backend oracles.

## 3. Verified repository map

Read these files before writing `DESIGN.md`:

| Area | Files | Relevance |
|---|---|---|
| Pipeline coordination | `src/tools/pipelines/PipelineExecutor.ts` | Selects intermediate/final paths and currently leaks its temporary workspace. |
| Stage dispatch | `src/tools/pipelines/TilesetStageExecutor.ts` | Wraps stage errors and owns processor lifecycles. |
| Processor setup/close | `src/tools/tilesetProcessing/TilesetProcessor.ts`, `TilesetProcessorContexts.ts` | Opens source/target and reveals the close-on-error gap. |
| Target factory | `src/tilesets/tilesetData/TilesetTargets.ts` | Maps path suffixes to all three target implementations. |
| Directory output | `src/tilesets/tilesetData/TilesetTargetFs.ts` | Mutates files in place and preserves unrelated existing files. |
| 3TZ output | `src/tilesets/packages/TilesetTarget3tz.ts` | Deletes an existing archive in `begin()` and streams the replacement. |
| 3DTILES output | `src/tilesets/packages/TilesetTarget3dtiles.ts` | Deletes an existing database in `begin()` and commits on `end()`. |
| Public exports | `src/tools/index.ts`, `src/tilesets/index.ts` | Existing testable entry points; no new public transaction class is needed. |
| Existing oracles | `specs/SpecHelpers.ts`, `specs/tilesets/tilesetData/TilesetTargetSpec.ts`, `specs/tools/tilesetProcessing/PackageTilesetProcessorSpec.ts` | Package comparison, fixtures, and common target contract. |

Important current behavior:

- An output ending in `.json` is logically the containing directory, while the
  JSON basename remains the target tileset filename.
- Directory output with `overwrite=true` updates colliding files but retains
  unrelated existing files. With `overwrite=false`, a pre-existing directory is
  allowed until an entry collision occurs.
- `.3tz` and `.3dtiles` outputs reject any existing file when overwrite is
  false and delete it immediately when overwrite is true.
- Multi-stage pipelines use directory-shaped intermediate outputs even when the
  final output is packaged.
- `setTempBaseDirectory()` supplies a parent location for test/debug temporary
  work; it must never authorize deleting that parent itself.

## 4. Required behavior

Turn these clauses into a two-way description/test ledger before writing tests.
The eventual `meta.md` must state every tested clause naturally in no more than
500 words; aim below 480 words to leave platform-counting margin.

1. `PipelineExecutor.executePipeline()` writes the final stage to private
   staging storage and exposes it at `pipeline.output` only after every stage and
   target finalization succeeds.
2. If execution fails and the logical output already existed, that destination
   remains byte-for-byte and entry-for-entry unchanged. If it did not exist, no
   destination is left behind.
3. The guarantee applies equally to directory, `.3tz`, and `.3dtiles` outputs,
   including outputs supplied as a `.json` path.
4. Existing overwrite semantics remain intact. In particular, a successful
   directory update retains unrelated files, and an overwrite-disabled
   collision still fails without changing the destination.
5. A pipeline whose input and output name resolve to the same logical storage
   can succeed with overwrite enabled because the original remains readable
   until publication.
6. Temporary paths created by the executor are removed after success and after
   failure. When a custom temp base is configured, only the executor's unique
   child workspace may be removed.
7. Publication itself is recoverable: if replacing an existing destination
   fails after it has been moved aside, restore the original and rethrow the
   failure. Do not leave a backup or staged destination visible.
8. Preserve the original pipeline error type/cause contract. Cleanup errors may
   not hide the processing or publication error that caused rollback.

## 5. Intended design and implementation boundaries

The simplest viable architecture is a transaction owned by `PipelineExecutor`:

1. Resolve the logical destination without losing `.json` basename semantics.
2. Create a unique staging sibling whose suffix still selects the correct target
   backend. For a directory destination, seed staging with a recursive copy of
   the existing destination so current merge/overwrite behavior is reproduced.
3. Create a separate unique intermediate-stage workspace under the configured
   temp base (or the OS temp directory). Never place final staging on another
   filesystem.
4. Run the final stage against staging. Pass backend-appropriate overwrite
   values so packaged targets do not reject the private path while directory
   entry-collision semantics are still checked against the seeded copy.
5. On success, publish with destination-to-backup and staging-to-destination
   renames, then remove the backup. Restore the backup if the second rename
   fails.
6. In one `finally` path, remove only paths created by this invocation. Preserve
   the primary error when cleanup also fails.

Do not expose implementation-only staging or backup names in the public API or
description. Small private helpers in `PipelineExecutor.ts` or a focused helper
module are acceptable. Avoid spreading filesystem transaction logic through all
three target backends unless the design proof shows it is necessary.

Before implementation, prototype one failure after a target has written at
least one entry. Confirm whether the existing processor error path leaves 3TZ or
SQLite resources alive long enough to block cleanup. If so, add the smallest
internal abort/close path needed and cover it; do not weaken clause 6.

Expected production change: approximately 150-200 effective lines across two or
three source files. If the honest design is materially larger, stop after
`DESIGN.md` and report the measured reason instead of silently broadening scope.

## 6. Discriminators and shallow solutions to kill

The suite needs two independent architectural discriminators, not a collection
of unrelated edge rules.

### Discriminator A: validate/process before publication

Plausible wrong solutions delete the destination first, write directly and
delete partial output on error, or back up only packaged files. Kill them with a
late deterministic failure after at least one entry was written, against both an
existing sentinel destination and an absent destination.

### Discriminator B: logical-path and backend parity

Plausible wrong solutions handle files but not directories, stage with a suffix
that selects the wrong backend, mishandle `.json`, or replace a directory
wholesale and lose unrelated files. Cross the same behavior through directory,
`.json`, `.3tz`, and `.3dtiles` cases and read results through existing source
and package-comparison APIs.

Lifecycle cleanup and overwrite-disabled behavior should reinforce these two
discriminators; do not present them as a third independent mini-task.

## 7. Test plan

Put challenge-only specs outside upstream's `specs/**/*Spec.ts` glob, for
example under `grader_tests/`, with a randomly generated non-descriptive
filename. Base mode must run the untouched upstream suite; new mode must run the
challenge specs. Both modes must emit JUnit XML and must not fail fast.

Minimum behavioral matrix:

| Case | Destination before call | Expected result |
|---|---|---|
| Late stage failure, directory | Sentinel tree with colliding and unrelated files | Error; exact tree and bytes unchanged; no staging/backup paths. |
| Late stage failure, `.3tz` | Valid sentinel package | Error; original bytes/package entries unchanged. |
| Late stage failure, `.3dtiles` | Valid sentinel package | Error; original bytes/package entries unchanged. |
| Late failure, all three forms | Absent | Error; destination remains absent. |
| Success with overwrite | Existing directory | New entries published; unrelated sentinel retained. |
| Success with overwrite | Existing packages | Complete valid replacement readable by existing source APIs. |
| Collision with overwrite disabled | Existing directory and packages | Error; originals unchanged. |
| Same logical input/output | Existing directory and at least one package form | Success; complete output validates. |
| `.json` output | Existing containing directory | Correct JSON basename, preservation, rollback, and cleanup. |
| Custom temp base | Success and failure | Base directory retained; invocation child contains no residue. |

Use malformed-but-recognized content or a public processing stage that fails
after deterministic earlier work. Do not mock private helpers or assert exact
temporary filenames, rename counts, log text, or internal call order.

Mutation checks must include at least: direct final write, delete-on-error
without restore, file-only staging, no seeding of an existing directory,
incorrect `.json` resolution, cleanup only on success, deletion of the custom
temp base, and backup restore omitted. Every mutation should break at least two
behavioral assertions; compilation failures do not count.

## 8. Harness preflight

Verified locally at the pinned commit on macOS arm64:

- `npm install` completed. Upstream has no committed `package-lock.json`, so a
  direct `npm ci` is invalid. The Dockerfile resolves a lockfile once during its
  networked build, records the undeclared tools at exact versions, and then uses
  that generated lock with `npm ci`.
- `npm test` passed all **869 specs with 0 failures**.
- `npm run build` completed successfully.
- Node requirement is `>=18.0.0`.

The repository invokes `tsx` and `copyfiles` through `npx` without declaring
them. For offline evaluation, record pinned copies in the build-time lockfile
and invoke them with `npx --no-install` at run time. Do not let a test command
fetch from the network. Warm all native dependencies, including
`better-sqlite3`, in the image.

`test.sh` requirements:

- accept `base` and `new`, plus both `--output_path PATH` forms;
- delete a stale report before the run;
- execute all selected tests without fail-fast behavior;
- always create well-formed JUnit XML, including on setup failure;
- exit nonzero when any selected test fails;
- contain no task-authoring or platform vocabulary.

## 9. Execution sequence for the handoff agent

1. Work only from the pinned clean source and a separate solution worktree.
2. Create `DESIGN.md` first. Include the hard-rule ledger, this audit, exact
   logical-path mapping, rollback state machine, error precedence, shallow
   implementation analysis, discriminator matrix, and clause/test ledger.
3. Recheck upstream issues, PRs, Discussions availability, changelog, and head.
   Stop if equivalent work appeared after this audit.
4. Prototype the hardest late-failure cleanup case for 3TZ and 3DTILES. Record
   whether an internal abort path is required and the measured production LOC.
5. Present `DESIGN.md` for approval. Do not write tests, solution, or Dockerfile
   until the design, feasibility, and uniqueness gates pass.
6. Author `meta.md` from the approved ledger in natural maintainer prose, ASCII
   only and within 500 words.
7. Build `test.patch` and the offline Docker/test harness. Verify base mode on
   the untouched commit and new mode fails for behavioral reasons.
8. Implement the reference solution without unrelated refactors. Run upstream
   build/tests and new tests.
9. Run four pristine-clone gates: base pass, new fail without solution, new pass
   with solution, base pass with solution.
10. Run mutation testing, leak/ASCII scans, patch-application checks, and inspect
    the exact file list in each patch.
11. Create `solution.patch`, an identical `reference_solution.patch`, and a
    code-derived `solution_approach.md` that does not mention calibration.
12. Calibrate with at least ten independent agent runs. Current target is a
    30-40% solve rate with at least one legitimate solve; verify the live
    platform criteria before launching runs.

Expected durable artifacts after implementation:

`DESIGN.md`, `meta.md`, `test.patch`, `solution.patch`,
`reference_solution.patch`, `Dockerfile`, `solution_approach.md`, `SUMMARY.md`,
`LEVELS.md`, `ERRORS.md`, `verify/`, and trajectory indexes/bundles as required
by the current platform.

## 10. Stop conditions

Stop and report rather than improvising if any of these occurs:

- an equivalent issue, PR, Discussion, or archived task appears;
- cleanup cannot be made deterministic on the supported Linux runner;
- tests require private call-order assertions instead of public output behavior;
- production scope materially exceeds the current 150-200 effective-line target;
- the 500-word prompt cannot state every tested behavior naturally.
