# feedback.md - vega-keyed-dataset-reconciliation

NEXT (human): none. DEAD at the measure-first spike (123 human-eff); fallback capa also DEAD (117). Next hunt should spike at the first shared operator before sketching.

Repo: vega/vega (canonical, no move), base b570ef375a28b6ac9c2f8ee10ceae6bb2df12517 (main HEAD 2026-09-11, no commits since).
Hunt: #39 fallback 1 (REPO-HUNT-2026-09-29-E.md, dossier worktrees/_hunt/s_0929h39/dossier_vega_h39.md).
Mode: SLICE (factory, unattended).

## Status
- 2026-09-29: folder created, BASE_COMMIT saved.
- 2026-09-29: exclusivity (canonical-org PR-DIFF, 20 open PRs by file) and six-check clean; base..main empty.
- 2026-09-29: v2.6.5 `upsert` ruling: distinct capability (single-datum trigger vs whole-array reconciliation), overlap noted.
- 2026-09-29: MEASURE-FIRST spike of the full lane (D1-D5 kept): **123 human-effective** (168 raw, 10 files).
  Works end to end in Docker and keeps every base suite green. One chokepoint (input Collect +
  ChangeSet.replace) absorbs all five surfaces, the Load holder and the add/remove cancel. Under the
  250 proceed gate and the 200 floor, no genuine coupled lever for +130. **DEAD, shelved** (TOO-EASY.md
  machinery-absorbed row + case study; rejected/).
- Conservative choices made unattended: did not pad with keyed insert (v2 upsert prior art) or
  animation (#641 magnet).
- 2026-09-29: tried the one allowed fallback (mandiant/capa process-tree scope, base 497120ff green): working full-lane spike 117 human-eff, also DEAD. Record: rejected/capa-process-tree-scope/.
