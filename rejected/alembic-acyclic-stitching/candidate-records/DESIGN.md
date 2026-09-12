# DESIGN - Alembic acyclic revision stitching

Status: `rejected-exact-prior-implementation`.

Repository: `sqlalchemy/alembic` at
`c116cbc0f39d9df2b4ce5f1871043a622ca8774f` (default branch `main`,
2026-08-14).

Primary and proposed production language: Python.

Task type: enhancement.

This record completes the mandatory trajectory-informed startup gate. It does
not approve a problem folder, public description, hidden test, `test.patch`,
reference solution, Dockerfile, solver run, calibration, or submission-ready
claim.

## Provisional direction and repository evidence

The seed name `alembic-acyclic-stitching` was interpreted as an enhancement to
stitch existing, potentially non-head revisions into a new merge point while
retaining Alembic's directed-acyclic revision-graph guarantees. The natural
public surfaces were the `alembic merge` command, `alembic.command.merge()`,
`ScriptDirectory.generate_revision()`, and `RevisionMap` validation.

The exact behavior is already present at the pinned head:

- Alembic's README and branch documentation define revision history as a
  directed acyclic graph with branches, multiple bases, and merge points.
- Closed issue
  [#167](https://github.com/sqlalchemy/alembic/issues/167) and commit
  `5c747a068b53` introduced multiple heads, branch resolution, merge points,
  and independent bases in 2014.
- Discussion
  [#1707](https://github.com/sqlalchemy/alembic/discussions/1707) asks for
  merging non-head revisions. The maintainer posted the complete two-hunk
  `splice` implementation and then approved tracking it.
- Closed issue
  [#1712](https://github.com/sqlalchemy/alembic/issues/1712), closed PRs
  [#1757](https://github.com/sqlalchemy/alembic/pull/1757) and
  [#1794](https://github.com/sqlalchemy/alembic/pull/1794), and main-branch
  commit `637159a95a3d` implement that exact non-head stitching operation.
  `command.merge(..., splice=True)` now passes the selected revisions and the
  splice flag to `generate_revision()`.
- `tests/test_command.py::MergeTest::test_merge_cmd_splice` proves the public
  behavior: a non-head merge is rejected without `splice`, succeeds with it,
  and writes both selected revisions into the new revision's
  `down_revision` tuple.
- The behavior shipped in Alembic 1.18.5 and is documented in the current
  changelog.
- Closed issue
  [#757](https://github.com/sqlalchemy/alembic/issues/757), PR
  [#758](https://github.com/sqlalchemy/alembic/pull/758), and commit
  `3e178bd6d728` added eager self-loop, revision-cycle, dependency-self-loop,
  and dependency-cycle detection in 2020.
- `RevisionMap._detect_cycles()` remains in production and
  `tests/test_revision.py` covers solitary, base, head, branch-point, and
  merge-point loops plus ordinary and dependency cycles above and below
  otherwise valid graph regions.

This is not a neighboring implementation that merely reduces the task. It is
the command, API flag, graph model, validation path, release note, and focused
test that the seed would ask participants to add.

## Trajectory-informed startup gate

Before any hidden-test work, `PROBLEM_DESIGN.md`, `ENVIRONMENT_GATE.md`, and
`candidates/SEARCH_INSTRUCTIONS.md` were read. Searches covered
`candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`, `problems/README.md`,
`problems/`, and `archive/` for Alembic, migration revisions, directed acyclic
graphs, cycles, branches, merge points, stitching, and graph traversal. No
Alembic problem, candidate dossier, solver patch, or raw Alembic trajectory
exists locally; the pre-existing candidate directory was empty.

The closest compact graph-composition record was
`archive/node-opcua-nodeset-merge/`, but its five platform records contain only
run IDs and URLs, not solver trajectories or patches, and remain quarantined
no-starts. `problems/geo-line-merge/DESIGN.md` was also reviewed because it uses
the word "stitches"; it is a geometric segment-connectivity algorithm, not
revision-graph lifecycle work.

The accepted Statig record was the closest source of usable raw evidence about
hierarchy identity and traversal. `problems/statig-local-transitions/DESIGN.md`,
`LEVELS.md`, `ERRORS.md`, and `RUNS.md` were read, followed by the named raw
`trajectory.json`, solution diff, evaluator result, and test result for three
runs extracted outside the workspace from
`archive/statig-local-transitions/agent-runs.tar.gz`:

| Evidence role | Problem / raw member | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | Statig `agent-runs/Nova_Nova_1` | 23/23 baseline and 18/18 focused | Carried accepting-handler position internally across separate blocking and awaitable paths while keeping the public outcome representation stable. |
| Near-pass regression | Statig `agent-runs/Nova_Nova_2` | baseline pass, 17/18 focused | Flattened blocking dispatch recursion and changed established hook unwind order, showing that a graph traversal rewrite can preserve destinations while regressing lifecycle order. |
| Late near-pass | Statig `agent-runs8/Nova_Nova_1` | baseline pass, 23/25 focused | Identified a boundary by its full ancestor-chain fingerprint; a parent mutation made the same logical occurrence appear external, showing that node identity and surrounding topology are distinct concerns. |

Those trajectories would justify checking traversal lifecycle, occurrence
identity, and producer-mode parity in a genuinely novel graph task. They do
not authorize repackaging Alembic's released implementation or copying
Statig's private architecture into tests.

## Trajectory-informed discriminator ledger

These rows record the reasoning that was considered before the upstream stop.
They are not approved hidden tests.

| Observed repository or solver behavior | Generalized shortcut | Fair public invariant that would be needed | Existing black-box oracle | Boundary / failure family | Gate result |
|---|---|---|---|---|---|
| Statig's pass kept public outcome and internal position separate. | Add a CLI spelling without carrying the mode through the Python API and revision generator. | CLI and `command.merge()` both create the same merge point from non-head revisions. | `test_merge_cmd_splice` plus the `command.merge()` signature and generated `down_revision`. | Command/API/generator plumbing | Already implemented and tested by #1794. |
| Statig's traversal rewrite changed hook order. | Produce the desired new node while breaking ordinary head-only rejection or branch traversal. | The default merge path still rejects non-head revisions, while explicit splice succeeds. | The two halves of `test_merge_cmd_splice` and the existing revision suite. | Opt-in compatibility | Already implemented and tested. |
| Statig's late near-pass confused logical identity with its ancestor path. | Detect only cycles that erase every head/base, missing a cycle embedded beside valid graph regions. | Loops and cycles are rejected whether isolated or embedded at a base, head, branch point, merge point, or dependency edge. | `GraphWithLoopTest` and `GraphWithCycleTest`. | Graph identity and reachability | Already implemented across independently shaped fixtures. |
| Alembic distinguishes versioned parents from `depends_on` edges. | Validate only `down_revision` and permit dependency cycles. | Both version and dependency graphs remain acyclic, with distinct error classes. | `CycleDetected`, `DependencyCycleDetected`, `LoopDetected`, and dependency-loop tests. | Edge-family parity | Already implemented and released from #757/#758. |
| The non-head merge writes a fresh revision pointing to existing nodes. | Add more malformed tuples or permutations as if they were a new capability. | A new public behavior must be distinct from existing splice and cycle validation. | Current command, revision-map, and traversal suites. | False-positive padding risk | No distinct unowned requirement was found. |

## Clause-to-test disposition

No participant-facing clause or hidden test is authorized.

| Provisional clause | Existing production behavior | Existing test or documentation | Disposition |
|---|---|---|---|
| Merge selected non-head revisions into a new branch/merge point | `command.merge(..., splice=True)` forwards to `generate_revision(..., splice=True)` | `test_merge_cmd_splice`, 1.18.5 changelog, #1707/#1712/#1794 | Exact prior implementation |
| Preserve ordinary head-only behavior unless explicitly enabled | `generate_revision()` checks `is_head` when `splice` is false | failure half of `test_merge_cmd_splice` | Exact prior implementation |
| Keep the revision graph acyclic | `RevisionMap._detect_cycles()` validates version and dependency topology | `GraphWithLoopTest` and `GraphWithCycleTest`, #757/#758 | Exact prior implementation |
| Support branches and merge points as repository-native concepts | revision DAG, multiple heads/bases, merge command | branch docs, #167, extensive revision/traversal tests | Mature existing subsystem |

Adding permutations, longer cycles, more branch shapes, or a renamed helper
would only create fixtures around existing behavior. It would not yield a new
maintainer-facing enhancement.

## Environment and harness record

- A clean exact clone was inspected outside the Olympus workspace at the pin;
  it remained clean.
- GitHub's API reported 4,320 stars, Python, MIT, default branch `main`, and a
  latest push on 2026-08-14.
- The repository has a substantial pytest suite across command, script
  production, revision, traversal, offline environment, SQLite, and backend
  integration surfaces.
- No repository `AGENTS.md` was found.
- No Phase A image build, dependency warmup, arbitrary-UID offline run,
  prototype, mutation, gap, fairness, or solver run was performed. The exact
  prior-implementation gate is terminal and precedes that investment.

## Design verdict

Reject at 4/10 with dimensions **9 / 5 / 1 / 2 / 9 / 1** for eligibility and
health, rarity, task applicability, behavioral depth, harness feasibility, and
prior-art/similarity safety. The repository itself is healthy and test-rich,
but this seed has no remaining task gap. Reconsider Alembic only through a
materially different subsystem and a fresh exact-name, synonym, history,
issue, pull-request, and Discussion audit.
