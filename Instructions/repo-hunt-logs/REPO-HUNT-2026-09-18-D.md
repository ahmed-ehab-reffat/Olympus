# Repo hunt 2026-09-18-D — sibling-workspace proven repos: 5 audited, 0 lanes

Fourth hunt of the day, after kira (precheck Blocker: restores a removed capability) and ray-optics
(in-repo oracle shortcut) died. Stage 0-bis again, on the proven repos whose approved picks were
IMPORTED from a sibling workspace (different folder layout, no `Repository:` frontmatter), which no
hunt in this workspace had ever screened. Shared brief `worktrees/_hunt/agents/BRIEF-0918-D.md` adds two
gates: the removal-record check and the in-repo-oracle shortcut test.

## Mechanical screen (10 repos)

| Repo | Verdict |
|---|---|
| cgohlke/tifffile | DEAD Req 7: no workflow runs tests (only dependency-graph jobs) |
| spf13/afero | DEAD dormancy magnet: 0 commits/90d, 32 open PRs |
| AmrDeveloper/GQL | DEAD: 0 commits/90d, SQL-shaped (two dead picks already) |
| unicode-org/icu4x | not audited: NOASSERTION (Unicode licence, not in the allowlist), 85 open PRs |
| railwayapp/cli | reserve: company product, 100 commits/90d, 36 open PRs |
| 5 others | audited below |

## Lane audits

| Repo | Verdict | Killer |
|---|---|---|
| seladb/PcapPlusPlus (4/6 quota) | DEAD | two signature accounts (`vsaraikin` x7 incl. LightPcapNg, `carrerasdarren-cell`); core/reassembly/pcapng/live lanes under open PRs or our own picks; IP fragmentation is RFC-named with Scapy prior art, ~120-180 eff |
| microsoft/maker.js | DEAD | no real code commits in 90 days; dimensions lane has a public maintainer branch (+450 LOC, removal-record gate); booleans/offset/bezier branches too; invented laser-cut plan solved by existing `findChains` + `chain.toPoints` in a 28-line shortcut |
| rmk-rs/rmk (2/6) | DEAD | maintainer's daily `codex/daily-review-*` AI sweep over the engine; every tracker lane claimed or QMK/ZMK-named; invented layer-holder ledger: 50-70-line shortcut, 120-180 eff |
| h5py/h5py | DEAD | `_hl` wraps libhdf5 or mirrors numpy: 21- and 15-line numpy shortcuts pass 6/6 on the indexing and field-write lanes; `iter_chunks` has zarr/dask prior art and a maintainer scope objection; three signature accounts |
| AcademySoftwareFoundation/openexr | DEAD | core deep-data encoding (`pack.c:14` stub) is the inverse of the existing decoder: an 81-line mirror passes 24/48 cells, ~90 eff for a full pass; `CHANGES.md` publicly says "not yet complete"; second lever is the maintainer's `staging/cpp_core_rewrite` |

Signature accounts added to `worktrees/_hunt/sig_accounts.txt`: vsaraikin, carrerasdarren-cell,
teddytennant, lilu5458, Fuyugithub (NotAFlightRisk was already there).

## What this says about the pool

Every proven repo in `approved-problems/` now has a written verdict less than three weeks old, and
today's two gates killed four of the five audits by themselves (a public branch or an in-repo oracle
or a shortcut under the floor). The shortcut gate is the new dominant killer: in mature libraries the
capability most often exists as an inverse, a sibling, or a numpy/zarr equivalent.

Dossiers: `worktrees/_hunt/agents/{pcapplusplus,makerjs,rmk,h5py,openexr}-0918D.md`, probes beside them.
Clones kept source-only: pcapplusplus 138M, makerjs 22M, rmk 71M, h5py 18M, openexr 114M.
