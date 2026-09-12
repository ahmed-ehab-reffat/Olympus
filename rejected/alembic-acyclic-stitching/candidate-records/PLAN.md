# PLAN - Alembic acyclic revision stitching

Status: rejected at the exact prior-implementation gate on 2026-08-15.

Repository: `sqlalchemy/alembic`.

Pinned commit: `c116cbc0f39d9df2b4ce5f1871043a622ca8774f`.

Primary and proposed production language: Python.

Task type: enhancement.

## Objective considered

Evaluate an enhancement that stitches existing, potentially non-head Alembic
revisions into a new merge point without weakening directed-acyclic revision
and dependency-graph guarantees. The intended observable surface was the CLI,
the programmatic command API, generated revision metadata, and graph
validation.

## Gate result

The task is already implemented. Branch/merge DAG support landed from issue
[#167](https://github.com/sqlalchemy/alembic/issues/167). Cycle and dependency-
cycle rejection landed from [#757](https://github.com/sqlalchemy/alembic/issues/757)
and [#758](https://github.com/sqlalchemy/alembic/pull/758). Non-head stitching
was then designed in Discussion
[#1707](https://github.com/sqlalchemy/alembic/discussions/1707), tracked by
[#1712](https://github.com/sqlalchemy/alembic/issues/1712), implemented twice
in public PRs [#1757](https://github.com/sqlalchemy/alembic/pull/1757) and
[#1794](https://github.com/sqlalchemy/alembic/pull/1794), landed on `main` as
commit `637159a95a3d`, and released in 1.18.5.

## Work completed before stopping

1. Read the mandatory problem-design, environment, and repository-search
   protocols plus the candidate, success, and problem registries.
2. Searched local compact history for Alembic, revision graphs, cycles,
   branches, merging, and stitching.
3. Read the closest graph-composition and hierarchy compact records and three
   representative raw Statig trajectories with their patches and evaluator
   results.
4. Cloned the exact Alembic pin outside the workspace and inspected graph
   documentation, command APIs, revision-map construction, cycle detection,
   tests, changelog, and full Git history.
5. Queried current GitHub repository facts and all-state issue/PR/Discussion
   vocabulary, then read the decisive issues, PRs, comments, and Discussion.
6. Stopped before Phase A, prototype, mutation, prompt, hidden tests, reference,
   or problem-package creation.

## Work not authorized

Do not create `problems/alembic-acyclic-stitching/`, `meta.md`, `test.patch`,
`solution.patch`, a Dockerfile, fixtures, mutations, solver runs, or calibration
artifacts. Do not rename the released `merge --splice` behavior to evade prior
art. Do not add longer cycle or branch fixtures as padding around the existing
cycle detector.

## Reconsideration condition

Reconsider Alembic only through a materially different subsystem and a fresh
audit of code, tests, docs, history, issues, pull requests, Discussions, and
local Olympus similarity. This exact seed is terminal.
