# Upstream audit - Alembic acyclic revision stitching

Audit date: 2026-08-15.

Repository: [`sqlalchemy/alembic`](https://github.com/sqlalchemy/alembic).

Pin: `c116cbc0f39d9df2b4ce5f1871043a622ca8774f`, default branch `main`,
committed 2026-08-14.

## Current repository facts

GitHub's repository API reported 4,320 stars, Python, MIT license, default
branch `main`, and last push `2026-08-14T07:40:29Z`. The expected production
change would be Python. The source contains a large pytest suite and documented
command, programmatic API, revision-map, graph traversal, script-production,
offline-environment, and database-backend test surfaces.

The exact clone remained clean throughout inspection. It contains no
repository `AGENTS.md`. Environment viability was not claimed because the
terminal prior-implementation result stopped work before the mandatory Phase A
container gate.

## Saved primary-source checks

| Surface / dated query | Result | Consequence |
|---|---|---|
| Current source and docs: `stitch`, `acyclic`, `splice`, `merge`, `CycleDetected`, `DependencyCycleDetected`, branch/merge terminology | The README and branch docs call the revision structure a DAG; `command.merge()` accepts `splice`; `generate_revision()` enforces the opt-in head rule; `RevisionMap` detects version and dependency cycles. | Both the stitching and acyclicity halves exist in production. |
| All-state GitHub search: `repo:sqlalchemy/alembic stitch in:title,body` | No literal `stitch` result. | The candidate's informal label is not the repository vocabulary; exact behavioral synonyms control. |
| All-state GitHub search: `repo:sqlalchemy/alembic acyclic in:title,body` | Closed issue [#167](https://github.com/sqlalchemy/alembic/issues/167) describes branch resolution as DAG support and discusses knitting branches together. | The foundational task concept is explicit public history, not a new gap. |
| Issue [#167](https://github.com/sqlalchemy/alembic/issues/167), branches and merge points | Closed by commit `5c747a068b53` in 2014 with multiple heads, merging, named heads, and independent bases. | General revision stitching is mature production behavior. |
| Discussion [#1707](https://github.com/sqlalchemy/alembic/discussions/1707), non-head merge | Contains the exact failing command sequence and the maintainer's complete two-hunk patch adding `splice` to `merge()` and forwarding it to the revision generator. The maintainer then approved implementation. | Exact public design and implementation were published before this candidate. |
| Issue [#1712](https://github.com/sqlalchemy/alembic/issues/1712), `merge --splice` | Converts the maintainer's Discussion patch into a tracked issue. | Exact task ownership is explicit. |
| Closed PRs [#1757](https://github.com/sqlalchemy/alembic/pull/1757) and [#1794](https://github.com/sqlalchemy/alembic/pull/1794) | Both implement `merge --splice`; #1794 is the credited version carried through the project's Gerrit workflow. | There are multiple public implementations, not merely a request. |
| Main history commit `637159a95a3d`, `Add --splice support to merge command` | Adds the `splice` parameter, API documentation, forwarding call, and a 32-line command regression. The commit message fixes #1712 and closes #1794. | The exact feature is on the pinned default branch. |
| Current `docs/build/changelog.rst`, release 1.18.5 | Announces `--splice` on both the CLI merge command and `command.merge()`. | The behavior is released and user-facing. |
| Issue [#757](https://github.com/sqlalchemy/alembic/issues/757), cycles and loops | Requests consistent rejection of loops and cycles in revision dependency graphs; the maintainer explicitly approved startup-time errors. | Acyclic validation is separately owned public work. |
| PR [#758](https://github.com/sqlalchemy/alembic/pull/758) and commit `3e178bd6d728` | Adds loop/cycle exception hierarchy, detection, involved-revision reporting, and broad tests. GitHub records the PR closed rather than merged because the project imported it through Gerrit; the commit is in main history. | Exact cycle protection is implemented, regardless of GitHub merge-button metadata. |
| Current `tests/test_revision.py` | Covers self-loops and cycles at isolated, base, head, branch-point, merge-point, embedded-valid-region, and dependency-edge shapes. | More graph-shape fixtures would be redundant rather than a new discriminator. |
| Broader all-state searches: `cycle revision`, `splice merge`, `branch resolution`, `merge point`, `non-head revision` | Returned #167, #297, #656, #757/#758, #1706/#1707, #1712, #1757, and #1794. No distinct unowned acyclic-stitching operation emerged. | Synonym expansion confirms the identity match and adjacent public saturation. |
| Local Olympus search: Alembic, migration graph, DAG, cycle, branch, merge point, stitching | No Alembic problem or trajectory exists. Node-opcua graph export has no usable raw solver data; Statig supplies only analogical traversal/identity evidence. | Local novelty cannot overcome exact upstream implementation. |

## Source identity proof

The current call chain is direct:

1. `alembic.command.merge()` accepts `splice: bool = False`.
2. It calls `ScriptDirectory.generate_revision()` with `head=revisions` and
   `splice=splice`.
3. `generate_revision()` resolves every requested revision, rejects duplicate
   heads, and checks `is_head` only when splice is false.
4. The generated script records the selected revisions as its
   `down_revision` tuple.
5. When the revision map is loaded or refreshed, `_detect_cycles()` validates
   both versioned and dependency edges.

The focused command test exercises steps 1-4, and the revision-map suite
exercises step 5 across independent graph families. A differently named
`stitch` helper would be a wrapper around this released path.

## Verdict

Reject as `rejected-exact-prior-implementation`. Do not create a problem
folder, prompt, hidden test, reference patch, Dockerfile, mutation suite, or
calibration batch for this seed. Do not rescue it with longer graphs, more
cycle permutations, or a renamed API. Reconsider the repository only for a
materially different, unowned subsystem after a fresh audit.
