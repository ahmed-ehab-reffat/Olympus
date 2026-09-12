# SUMMARY - transactional 3D Tiles pipeline publication

**Status: ARCHIVED; ABANDONED ON 2026-07-23. The feature and focused suite are locally
verified, but the pinned upstream revision cannot provide a reliable,
reproducible offline image under the current platform workflow. Do not submit
or resume this candidate without a committed upstream lockfile and a successful
pristine image preflight.**

## Environment rehabilitation update - 2026-08-06

The earlier environment defect now has a locally proven upstream-style fix.
Disposable commit `1e919dbe48181d63b082007f6b448bfa41746ed4` on top of current
upstream head `4ca692eb16a9c7db21ec99e2aacc32645ce92f28` stops ignoring the
npm lock, declares `tsx` and `copyfiles`, and commits the ordinary lock generated
by the required Olympus image. A simple lock-consuming Dockerfile built
successfully, and the resulting container passed 870 upstream specs, the full
TypeScript build including both post-build copy steps, ESLint, and Prettier with
runtime networking disabled.

This changes the diagnosis from "no demonstrated reliable image" to "small
technical fix proven, upstream provenance still missing." The candidate remains
abandoned under the current selection rule because the corrected lock and
manifest do not yet exist at an upstream-accessible revision. No challenge
prompt, test, runner, or reference solution was revised during rehabilitation.
`ENVIRONMENT.md` records the exact commit, image, hashes, and verification
matrix. The complete branch, mail patch, and preflight Dockerfile are archived
under `archive/3d-tiles-atomic-output/` for periodic upstream rechecks.

## Closure decision

The repository has no committed npm lockfile and its scripts invoke undeclared
`tsx` and `copyfiles` tools. The platform builds from the pristine upstream
checkout before injecting task patches, so the normal task-side lock cannot be
copied into the image. Attempts to bridge that gap caused repeated
reproducibility, manifest-mutation, Docker syntax, encoded-payload, and
build-output failures.

The final remote attempt timed out after 40 minutes at `fetching git
attributes`, before loading or executing the Dockerfile. That last failure is a
separate build-context/platform problem, but it confirms that this repository
is not a dependable evaluation target. The candidate is closed rather than
spending more runs on infrastructure.

Future TypeScript and JavaScript candidates must commit a recognized lockfile,
declare every offline build/test tool, and pass a minimal pristine Docker build
before a problem folder is developed.

## Target and artifacts

- Repository: `https://github.com/CesiumGS/3d-tiles-tools`
- Production language: TypeScript
- Task type: enhancement
- Base commit: `8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff`
- Production change: `src/tools/pipelines/PipelineExecutor.ts`
- Focused suite: 39 specs outside the upstream Jasmine glob
- Environment: required Olympus TypeScript base plus a task-side full npm
  dependency lock

| Artifact | Purpose |
|---|---|
| `meta.md` | Enhancement contract and observable guarantees |
| `test.patch` | Focused specs, JUnit wrapper, and base compatibility setup |
| `solution.patch` | Execution staging, candidate preparation, commit, rollback, and cleanup |
| `Dockerfile` | Offline-capable Node/TypeScript development environment |
| `package-lock.json` | Canonical, plain, integrity-checked npm dependency graph |
| `ENVIRONMENT.md` | Runtime and lock provenance, rationale, hashes, and update procedure |
| `solution_approach.md` | Code-derived reference design |
| `ERRORS.md` | Trajectory and environment diagnosis |
| `RUNS.md` | Compact ten-run calibration index and terminal lesson |
| `verify/docker-environment.mjs` | Audits the Docker payload against the pinned source |
| `verify/sync-docker-lock.mjs` | Synchronizes bounded plain Docker lock parts |

## Verification matrix

| State | Mode | Result |
|---|---|---|
| Test patch only | `base` | 869 tests, 0 failures |
| Test patch only | `new` | 39 tests, 39 failures |
| Test and solution patches | `new` | 39 tests, 0 failures |
| Test and solution patches | `base` | 869 tests, 0 failures |

The reference production file also passes the complete TypeScript build,
ESLint, and Prettier. The full locked dependency graph supports the build and all
869 upstream specs through the task runner. Docker's static build check reports
no warnings.

## Discriminator distribution

The suite covers four output forms and distributes failure boundaries across:

- processing after earlier writes;
- filesystem, `.3tz`, and `.3dtiles` target finalization;
- overwrite refusal and recursive entry-type collisions;
- same-storage directory, JSON-alias, and package execution;
- configured and default temp cleanup on success and failure;
- absent, nested, invalid, and output-contained temp bases;
- missing destination parents for every output form; and
- destination setup after a successful target finalizer.

Successful JSON is compared semantically while all other entries and all
failure-preservation snapshots remain byte-exact.

## Environment correction

The blocked trajectory was an environment failure, not a solution failure:
`npx --no-install tsx` could not find a local executable and runtime networking
is intentionally unavailable. The image now installs a fixed local `tsx`.

The separate 101-test baseline cascade came from Linux base-runtime cleanup
behavior for absent trailing-slash paths. The base runner retains a narrow
compatibility guard for those upstream scratch paths.

`ENVIRONMENT.md` documents the canonical lock and the need for its plain Docker
mirror instead of silently diverging from the checkout. The accompanying audit
verifies the pinned commit and source manifest, the exact two added tools, the
lock hash, all registry integrity fields, the 711-package graph, and the absence
of encoded payload commands or direct remote-file fetches.

The post-change static build check and dependency audit pass. A requested full
local rebuild was attempted from a detached clean checkout, but Docker Desktop
stalls on the first offline `RUN` instruction and also hangs on independent
container starts and base-image pulls. The final platform build then timed out
before the Dockerfile ran. `ERRORS.md` records both boundaries.

## Final artifact hashes

- `meta.md`: `6d71f8d0b7fa88fe28e3568fea62e6f4c947099724effd72e584e5c3f4a4c87c`
- `test.patch`: `e482e67f2bbc965c4b080ab2efc3da3f1971af8a452184fa53f2a04a6d1876e9`
- `solution.patch`: `fbaae9fc80c827d16003d45e9c7e53ad0739099b5b019a1f165456142887a1a4`
- `Dockerfile`: `d02b7e297011d88388ad54a2bbe2b552d8e68ea4c8f14526ceb0f60bb1f7f886`
- `package-lock.json`: `4074d13c92a36903bda81ba611d747dae460686966786eac3ff287b545685711`

Raw trajectories and the retired probe suite are archived under
`archive/3d-tiles-atomic-output/`.
