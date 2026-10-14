# DESIGN.md - aerich-migration-squash (SHELVED at the measure-first spike)

Repo tortoise/aerich (Apache-2.0, 1083 stars), base dev `6333068e09a3f14b45699487846714de525c735e`.
Lane from hunt #48 RANK 1 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-10-03-B.md`).

## 1. Title (as it would have shipped)
Add migration squashing to the aerich command set

## Phase 1 - repo understanding
- Architecture: `aerich/__init__.py` `Command` drives every user command (init-db, migrate, upgrade,
  downgrade, heads, history, inspectdb, fix-migrations). `aerich/migrate.py` `Migrate` is the planner:
  it diffs `get_models_describe(app)` against a baseline (the last `aerich` row online, the last file's
  `MODELS_STATE` offline) and writes `<N>_<timestamp>_<name>.py` files from `MIGRATE_TEMPLATE`. The
  `aerich` table (`aerich/models.py`, ordering `-id`) is the ledger: one row per applied file, holding the
  models state after that file. `aerich/ddl/*` emits dialect DDL; `aerich/inspectdb/*` reverse-engineers
  models; `aerich/cli.py` wraps `Command` in asyncclick.
- Subsystems: CLI, Command executor, Migrate planner, DDL emitters, inspectdb.
- Entanglement zones: the ledger order (`-id`) feeding baseline + numbering + downgrade `pk__gte`;
  the per-file executor loop duplicated in `upgrade` and `_do_init`; the planner's two baseline origins.
- Tests: pytest + anyio, `tests/test_*.py`; template `tests/test_command.py` and the
  `tests/assets/command_programmatically/_tests.py` in-process Command flow.

## Phase 2 - exclusivity / SIX-CHECK (2026-10-05)
- Canonical org `tortoise/aerich` (no move). PR + issue searches in all states for squash, combine,
  collapse, baseline, consolidate, "merge migrations", "reset migrations", replaces, compact,
  "single migration", "migration history", plus body/comment search (`gh search issues`) for squash,
  squashmigrations, "too many migrations", "merge migration files": no squash-class hit.
- dev HEAD still 6333068e; only open PR #561 (executor transaction split, outside the lane).
- Sibling tortoise-orm (fresh shallow clone, HEAD 1f896c0, 2026-10-03): no squash command;
  `replaces` is written by `writer.py` and read by nothing.
- Verdict: exclusivity CLEAN. The lane did not die here.

## Phase 3 - the lane and why it died

Contract: `Command.squash(A, B)` / `aerich squash --from A --to B` folds files A..B into one file and
compacts the `aerich` rows; afterwards every command except `history` behaves as if the range had
never been squashed, on databases holding none, some or all members (upgrade, downgrade -1 and -v N
with N a member, heads, migrate online and offline, init-db replay, per-app).

### Measured full-scope spike: 157 human-effective (hook), 175 raw, 3 files

`solution.patch` in this folder is that spike. It passes an end-to-end probe in the image
(`worktrees/aerich-squash-tools/probe_spike_end_to_end.py`): mid-range squash of 1..2 with 3 applied,
next `migrate` emits exactly one `ADD "d"` (the hunt's W1 reproduction no longer fires), `downgrade -1`,
`downgrade -v 2` splitting the compact row back into member rows, `heads` and partial `upgrade`
reporting member names.

| Hunt wall / surface | Hunt price | Measured | Absorbed by |
|---|---|---|---|
| W1 ledger order (`-id`) feeds the planner | compaction 30 | 4 lines | update the last member row in place (`row.version = new; save()`), no pk work at all |
| W2 two holders of "applied" + resolver | resolver 35, upgrade partial 30 | ~20 | one `rows -> member names` expansion (`_applied_entries`); the existing per-file loop then runs unchanged over a member-level plan |
| W4 offline vs online baseline origin | (lever) | 0 | name the file with B's number and carry B's MODELS_STATE; both origins read it for free |
| init-db replay | 20 | 0 | `_do_init` imports the squashed module and runs its top-level `upgrade`, recording a compact row the resolver already understands |
| nested squash flatten | 25 | 0 | reading a squashed member returns its steps |
| downgrade -1 / -v N | 40 | ~30 | expand rows from the first touched row, then the base loop |
| `--delete` partial rewrite | (lever) | ~8 | rewrite the file with the kept steps, renamed to the last kept number |
| W5 mixed RUN_IN_TRANSACTION | (wall) | dead | SQLite `executescript` commits before running, so transaction mode is unobservable here (probed with VACUUM both ways) |

Every genuine extra left (alias names for absorbed squash files, per-step transaction flags,
old-format members read from the ledger, validation messages) adds ~20-30, so the honest ceiling is
~180-190 against a 200 floor and a 250-300 design target.

## Alternative aerich lane checked (one allowed)
SQLite table rebuild for the four `NotSupportError` ALTERs (`aerich/ddl/sqlite/__init__.py:16-26`):
dead before scoping. Issue #510 carries the maintainer's "no plan to support column alter for it.
However, PRs are welcome!" (maintainer-invited PR-free lane = collision magnet) and Alembic batch mode
and Django's `_remake_table` implement the same rebuild publicly (sibling-ecosystem death class).
