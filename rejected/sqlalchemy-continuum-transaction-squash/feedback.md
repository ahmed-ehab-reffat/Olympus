# sqlalchemy-continuum-transaction-squash: feedback

Status: DEAD at the measure-first spike (2026-10-05). Machinery-absorbed, under the LOC floor. Shelved to rejected/ (TOO-EASY.md case study 2026-10-05).
Factory MODE=SLICE, FALLBACKS[0] after the hunted aerich lane died the same way
(rejected/aerich-migration-squash, 157 human-eff full scope).

Repo sqlalchemy-continuum/sqlalchemy-continuum, base main a84e8286 (1.8.0). Lane: hunt #41 L1.

## Attempt history

- 2026-10-05: folder created, base pinned. Draft Dockerfile (`factory-sqlalchemy-continuum-transaction-squash`,
  SQLAlchemy 2.1.1 per uv.lock for py>=3.11): base suite 856 passed / 15 skipped with the
  multithreaded validity module deselected, uid 1000, `--network none` (matches the hunt).
- Full-scope spike written first: **146 human-effective / 182 raw / 7 files** (squash kernel over
  every version table, op algebra, validity restitch, `_mod` recompute, three plugin hooks, vacuum
  rebuilt). Probe 16/16 over all 8 setting variants; `tests/test_vacuum.py` green. Hunt sketch 310,
  repriced 180-230; measured 0.47x of the sketch. Absorption table in DESIGN.md.
- Decision (unattended, conservative): both lanes of this run are dead, so the run ends in Death per
  the factory rule. No further fallback taken (the factory allows one).

OWED: nothing for this folder (shelved).
