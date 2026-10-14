# aerich-migration-squash: feedback

Status: DEAD at the measure-first spike (2026-10-05). Machinery-absorbed, under the LOC floor. Shelved to rejected/ (TOO-EASY.md case study 2026-10-05).
Factory MODE=SLICE. Repo tortoise/aerich, base dev 6333068e (pinned before open PR #561).
Lane from hunt #48 (Instructions/repo-hunt-logs/REPO-HUNT-2026-10-03-B.md RANK 1).

## Attempt history

- 2026-10-05: folder created, base pinned, draft Dockerfile built (`factory-aerich-migration-squash`):
  base suite 70 passed / 10 skipped as uid 1000 `--network none`, matching the hunt. Needs aiomysql,
  pymysql and asyncpg installed because conftest imports the MySQL schema generator.
- Exclusivity + SIX-CHECK on the canonical org: clean (see DESIGN.md Phase 2). tortoise-orm still has
  no squash command at 1f896c0.
- Full-scope spike written FIRST, as the orchestrator and hunt asked: **157 human-effective / 175 raw /
  3 files** for squash + compaction + resolver + partial upgrade + downgrade -1 / -v member with row
  re-expansion + `--delete` rewrite + heads + CLI. Probed end to end in the image: correct.
  Hunt price was ~240-250 (0.63x, inside the 0.5-0.8x band TOO-EASY.md predicts for 150-265 sketches).
  The walls collapse: W1 is an in-place update of the last member row, W4 is free once the file
  carries B's number and state, init-db replay and nested flatten are free, W5 is unobservable on
  SQLite. Absorption table in DESIGN.md.
- One other aerich lane checked (SQLite table rebuild): dead on #510's invitation + Alembic/Django
  sibling implementations.
- Decision (conservative, unattended): shelve as machinery-absorbed and move to FALLBACKS[0]
  (sqlalchemy-continuum). Artifacts kept: DESIGN.md, the spike as solution.patch, Dockerfile.

OWED: nothing for this folder (shelved).
