# Repo hunt 2026-09-19-C — four more new niches (graph layout, dep resolution, formula/report, text/sync); 0 RANK, 2 weak fallbacks

Third sweep of the day, same method as 09-19-B (`worktrees/_hunt/agents/BRIEF-0919-C.md`): one subagent
per niche, band cache + topic search + named projects, minus `deadlist_v6`, `screen.sh`, up to 3 lane
audits. 306 slugs screened in total; all now in `worktrees/_hunt/deadlist_v7.txt` (4,767 slugs).
Per-repo reject reasons: `worktrees/_hunt/agents/{graphlayout,depres,formula,textalgo}-0919C.md`.

| Niche | Screened | Result | Closest misses (killer) |
|---|---|---|---|
| graph layout / diagramming | 43 (+~60 metadata) | FALLBACK (weak) | awslabs/diagram-as-code grid direction (~220 eff, lean ~160, no new algorithm); stacktower (maintainer Cursor sweep rewrote layout); maxGraph (mxGraph port = prior art) |
| dependency resolution / build | 98 | none | fabric-loader (solver lane live + quilt-loader sibling ships every extension); pf4j (multi-version selection refused #189); tach (1 per-edge decision point, import-linter prior art) |
| formula / report / data mapping | 87 | FALLBACK (weak) | pdfmake footnotes (below); jxls (plugin arms, maintainer live in the class); django-slick-reporting (rollups Won't-fix #85) |
| text algorithms / sync | 78 | none | nbdime diff composition (SPIKED: 135 human-eff, one idea passes 6000/6000 property cases); pagefind (company roadmap, phrase-match removal record #1038); orbitdb (counter/feed stores removed at v0.29 = removal record) |

Why these niches are dry: layout, resolver and diff cores are textbook algorithms that sibling
libraries already ship (ELK/dagre/d3-dag, SAT/PubGrub, Myers/BM25), so the sibling-library law kills
the dense lanes; the maintained remainder is single-maintainer or company velocity that ships its own
features (vale, difftastic, typos, loro, evolu, json-joy), or AI-swept.

## FALLBACK 1 — bpampuch/pdfmake (JS, MIT, ★12.3k) — footnotes in the layout engine
- Lane: inline `footnote:` gets a numbered mark; body at the bottom of the page where the referencing
  line lands; line moves if line + footnotes do not fit; reservation carried through unbreakable
  blocks, columns, snaking columns, table cells; oversized body continues on the next page.
- Missing algorithm: page-bottom reservation during pagination, shared by the page and carried or
  rolled back through trial layouts and the `pageBreakBefore` retry loop. `git log -S footnote` over
  1619 commits: nothing, no removal record.
- F2P: footnote silently dropped. Base 482 pass / 56 pending, 3x identical with `--timeout 20000`,
  exclude `tests/browser`.
- Size: 6 decision points, 190-305 eff (central ~240); columns/tables route through one line-fit check,
  so a lean passer without continuation is 130-190. Continuation must be in scope.
- ⚠️ Derivative MAGNET (orchestrator check): #2133 "Insert Footnotes" open since 2020-11, maintainer
  comment only "not supported now, marked as feature request", no PR in any state. Nameable feature +
  long-open issue for exactly it = Stage 2b REJECT row. Also ★12.3k penalty band, maintainer is
  clearing old numbered feature requests in the same files, open PR #2922 touches page geometry,
  pagedjs (MIT JS) ships footnotes. Author only if nothing better appears, and phrase on pdfmake's
  own nouns. Clone kept: `worktrees/pdfmake`.

## FALLBACK 2 — awslabs/diagram-as-code (Go, Apache-2.0, ★1579) — 2-D `grid` group direction
- F2P: `Direction: grid` renders as a column; A->D link drawn through B and C. Base 106/106 x3.
- ~220 eff honest, ~160 lean, 5-6 decision points, no new algorithm; heuristic link auto-positioning
  costs many description words. Below the ~230 bar. Clone kept: `worktrees/gl-dac` (base `4ec965c`).

## Tooling changes
- `sig_accounts.txt` += `r3wretrhy` (surgical PRs across ~20 build tools: ninja, meson, nox, tox,
  spack, SCons, xmake, pixi, pdm, poetry, hatch, go-task, mise, yarn berry ...), `amannsan`,
  `dualfroz` (2026-created, no bio, 0 followers, dozens of small fixes across niche repos).
  WATCH, not added: `ychampion`, `yangfan-yf-yf`, `nightcityblade`, `dylanpulver`.
- `deadlist_v7.txt` built.

## Where discovery goes next
Eight niches in two sweeps today returned 0 RANK. Remaining unswept ideas: accounting/ledger engines
(permissive ones only), i18n/message-format runtimes, GIS routing/network analysis, bio file-format
engines beyond JOSS, test tooling (property testing, mutation, snapshot). Expect the same dryness;
the proven-pool second lane (featurevisor style) is still the best-odds path.
