# DESIGN.md - sqlalchemy-continuum-transaction-squash (SHELVED at the measure-first spike)

Repo sqlalchemy-continuum/sqlalchemy-continuum (BSD-3-Clause, 644 stars), base main
`a84e82866450d4eb82ba356d922b42051af31724` (1.8.0). FALLBACKS[0] of factory run 2026-10-05, taken after
the hunted aerich lane died (problems -> rejected/aerich-migration-squash). Lane: hunt #41 L1
(`worktrees/_hunt/s_0929h41/dossier_sqlalchemy-continuum_h41.md`).

## Phase 1 - repo understanding
- Architecture: `make_versioned()` registers mapper/session listeners on the global
  `versioning_manager`; at configure time `builder.py` builds one `<table>_version` per versioned table
  (`table_builder.py`: reflected columns + tx, end_tx under the validity strategy, operation_type),
  the Transaction model and version classes; at flush `unit_of_work.py` writes one version row per
  (class, identity, transaction) and closes the previous row's end_tx. Read side: `fetcher.py`
  (previous/next/index/version_at), `relationship_builder.py`, `version.py` changeset, `reverter.py`.
  Plugins (`plugins/`) own the TransactionChanges, TransactionMeta and Activity tables plus `_mod`
  columns (PropertyModTracker).
- Tests: plain pytest classes in `tests/`, shared machinery in `tests/__init__.py`, fanned over 8
  strategy x column-name variants by `create_test_cases`.
- Base suite in the image (`--deselect tests/test_validity_strategy_multithreaded.py`): 856 passed,
  15 skipped, 72 s, uid 1000, `--network none`.

## Phase 2 - exclusivity
- main HEAD still a84e828 on 2026-10-05; open PRs unchanged since the hunt (#404/#398/#395 dependabot,
  #397 SQLModel, #393 join_txn_mode), none on a lane file. Hunt #41 grepped all 158 PRs and 245 issues;
  no squash/compact/purge PR. Not re-litigated further because the lane died on size.

## Measured full-scope spike: 146 human-effective (hook), 182 raw, 7 files

`solution.patch` here is the spike: `squash_transactions(session, first_id, last_id)` in a new
`squash.py` (generic fold over every version table, joined-inheritance child tables and association
version tables included, with the op algebra INSERT+DELETE = vanish / DELETE+INSERT = UPDATE,
validity restitch of the pre-range row, `_mod` recompute against the pre-range row), an
`after_squash_transactions` plugin hook implemented by TransactionChanges (dedupe, drop vanished
entities), TransactionMeta (later key wins) and Activity (re-point the three tx columns), and `vacuum`
rebuilt to compare each version with the PREVIOUS one and restitch end_tx (the T1 bug the hunt
reproduced). A probe (`worktrees/aerich-squash-tools/continuum/test_spike_probe.py`) passes 16/16 over
all 8 setting variants (mid-range squash with previous/next/changeset/mod flags/tx table, and
INSERT+DELETE vanish next to a surviving UPDATE); the repo's own `tests/test_vacuum.py` still passes.

| Hunt decision point | Sketch eff | Measured | Why it collapsed |
|---|---|---|---|
| range validation | 20 | ~5 | one ordered id query |
| per-entity table enumeration (joined inheritance, STI, custom column names) | 30 | ~8 | `sa.inspect(version_cls).tables` + `manager.option`; every version table has the same tx/end_tx/op columns, so Core treats parent and child tables alike |
| op-type fold | 55 | ~6 | three branches over (pre-range row exists, last op is DELETE) |
| validity chain | 35 | ~6 | one UPDATE of the pre-range row; the collapsed row inherits its successor from the last in-range row |
| `_mod` recompute | 25 | ~6 | inside the same row loop |
| association version tables | 40 | 0 | same per-table routine; their PK is the association key + tx |
| transaction table + hook | 15 | ~5 | |
| TransactionChanges / Meta / Activity | 50 | ~35 | three small hooks |
| vacuum rebuilt on the kernel | 25 | ~18 | |
| identity-map expiry + export | 15 | 2 | `session.expire_all()` |

The hunt had already warned (REPO-HUNT-2026-09-29-G, item 2): "history maintenance (continuum)
collapse[s] to one generic per-field or per-table operator. To reach 250+ realised, a lane needs two
structurally different kernels." The spike confirms it at 0.47x of the sketch.
