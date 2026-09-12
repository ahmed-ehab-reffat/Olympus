# Candidate verdict - reject Alembic acyclic revision stitching

Status: `rejected-exact-prior-implementation`.

Primary and proposed production language: **Python**.

Task type: **enhancement**.

Reject `sqlalchemy/alembic` at
`c116cbc0f39d9df2b4ce5f1871043a622ca8774f` for the proposed acyclic revision-
stitching seed.

The repository is healthy and test-rich: GitHub reported 4,320 stars, MIT,
Python, and default-branch activity on 2026-08-14. The stop is exact prior art,
not repository eligibility.

Alembic has modeled migration history as a directed acyclic graph with
branches and merge points since issue
[#167](https://github.com/sqlalchemy/alembic/issues/167). It has eagerly
rejected self-loops, revision cycles, dependency self-loops, and dependency
cycles since [#757](https://github.com/sqlalchemy/alembic/issues/757) and
[#758](https://github.com/sqlalchemy/alembic/pull/758). The remaining apparent
gap—stitching non-head revisions—was designed with an exact patch in Discussion
[#1707](https://github.com/sqlalchemy/alembic/discussions/1707), tracked by
[#1712](https://github.com/sqlalchemy/alembic/issues/1712), implemented in
public PRs [#1757](https://github.com/sqlalchemy/alembic/pull/1757) and
[#1794](https://github.com/sqlalchemy/alembic/pull/1794), landed on `main` as
`637159a95a3d`, and released in 1.18.5 as `merge --splice` and
`command.merge(..., splice=True)`.

Current source and tests prove both directions: non-head merge is rejected
without `splice`, succeeds with it and records both parents, while the revision
map rejects loops and cycles across ordinary and dependency edges. More graph
permutations or a renamed helper would duplicate released behavior.

The mandatory trajectory gate found no Alembic solver history. It reviewed the
closest compact graph records and three raw accepted/near-pass Statig
trajectories for traversal order and hierarchy-identity lessons. Those lessons
cannot make an upstream-owned task novel.

No Phase A build, prototype, public description, hidden test, `test.patch`,
solution, Dockerfile, solver run, calibration artifact, or problem folder was
created.

Registry score: **4/10**, with dimensions **9 / 5 / 1 / 2 / 9 / 1** for
eligibility and health, rarity, task applicability, behavioral depth, harness
feasibility, and prior-art/similarity safety. Reconsider Alembic only through a
materially different subsystem and a fresh ownership audit.
