# REPO-HUNT 2026-09-23-F

Unattended `olympus-factory` hunt worker (hunter #19). `CONSECUTIVE_MISSES=0`, so the standard (already
softened 2026-09-09-B) rules apply and no star/issue windows are widened. Standing rules (user,
2026-09-23): a root AGENTS.md / CLAUDE.md is a ranking penalty; AI commits in the 90-day stream are
lane-scoped. Requirement 0 (platform picker) is OWED on anything handed over.
Scratch: `worktrees/_hunt/s_0923h19/`.

**Task (hint from hunt #18):** tegaki / ArchUnit are bayes_opt's fallbacks; firm up the stronger one
with a Stage 3 audit but return a DIFFERENT repo if one is found; otherwise source same-domain siblings
of approved-problems/ repos (sibling-library check first). Excluded: teavm (SLICING), bayes_opt
(HUNTED), genqlient, capnproto, openglobus, stremio-core, vermin, gauge, u-root, AeroSandbox, piscsi,
coal, cruise-control, everything adjudicated in 09-23-C/-D/-E, every LEDGER row and every problems/ repo.

## Stage 0-bis proven pool

EXHAUSTED (11th session). Pool rebuilt from frontmatter (`s_0923h19/pool.txt`, 78 repos): no repo
entered since hunt #18; the newest approvals (csbindgen, libspatialindex, siliconcompiler) and every
other 1-2-sub repo are LEDGER rows or were killed in 09-20-B/C and re-read under the AI-root ruling in
09-23-E. Nothing to reopen.

## Cached index triage (no fresh fetch)

Two offline passes over the 51,812-row cached metadata (`worktrees/_hunt/**/*.jsonl`), minus every
slug in `logged2` / `dead18` / `adjudicated` / `touched` and the hunt #18 residual `unadj2`:

- **Topic-sibling scoring** (`s_0923h19/sib.py` -> `sib_all.tsv`, 1,339 rows): IDF-weighted overlap
  of each unlogged row's GitHub topics with the 70 approved repos' topics. After an app/LLM junk
  filter the head is noise (note apps, trading bots, mail clients, LSP servers). Engine-shaped
  never-logged names it surfaced: pipelinec, openmotor, fut, cherri, rink-rs, murex, picsimlab (all
  GPL / MPL: licence kill), modm (MPL-2.0), argdown, pyret-lang (no licence file via API), malloy,
  postal-mime, mailparser, jmuxer, quickfix (NOASSERTION, read below).
- **Widened residual** (`s_0923h19/resid.py`, `resid2.py`): the same cut with an engine vocabulary,
  no upper star cap and NOASSERTION licences admitted. 150 permissive rows at 500-9000 stars, almost
  all apps, wrappers and ML paper code; the engine-shaped extras are lobster, tract, lightbend/config,
  html-to-text, graphql-jit, tensorly, prettytable, putout, vidact, _hyperscript.
  The cached index is effectively exhausted: every other in-scope row has a log entry.

## Hint rows: the two bayes_opt fallbacks

- **TNG/ArchUnit: at the reject threshold, confirmed.** Profiled both accounts hunt #18 flagged.
  `arimu1` (382 public repos, 6 followers, forks of openapi-generator, pebble, log4j2, ignite, doris,
  pulsar, restheart, jena, fastutil ...) and `DragonFSKY` (82 repos, no name/bio, forks of gradle,
  jetty, log4j2, mockito, reactor-core, spotbugs, spring-data-redis, langchain4j ...) are both the
  scattershot signature. Two distinct signature accounts on the repo = the softened Stage 2b-bis
  reject threshold, even with both outside the nested-layers lane. `arimu1` also visits google/jimfs.
  ArchUnit stays a fallback only if the next hunt's miss count lets it relax that threshold.
- **gkurt/tegaki: remains the only live fallback, still failing Guard #2 as scoped.** Clone
  `s_0923h18/agB/tegaki`: 13k LOC TS across `generator` (skeletonize, voronoi medial axis, stroke
  order, trace: almost untested, needs fonts) and `renderer` (timeline, drawGlyph, textLayout,
  svgExport, engine); 7 test files, ~1,000 test lines total, repo created 2026-03-28, root
  AGENTS.md + CLAUDE.md (penalty). The pen-travel lane still reads as one timing transform; the only
  widening with a second subsystem (SVG/CLI export honouring per-stroke delays) is a consumer fix,
  not a coupled kernel. Not promoted.

## Fresh sweep 1 of 2: the index rows no written log ever judged

Hunt #18's residual removed every slug found in a mechanical file too (GraphQL gate, probe and slice
tables). Re-cut against WRITTEN judgments only (`s_0923h19/judged.txt`: every slug in `Instructions/`,
`pipeline/`, agent dossiers, screened lists, approved/rejected folders): **1,229 engine-vocabulary
rows** at 500-8000 stars pushed since 2026-07-01 have never been named in any verdict
(`unjudged.tsv`). Joined with cached `commits12` / recent subjects / root listings and cut to active
code streams with no root AI file: **603 rows** (`unjudged_sel.tsv`), read by eye per language.
Almost all are apps, infrastructure, famous-spec implementations (TOML, YAML, glTF, ECMA-262, cron,
MQTT, protobuf, SQL), ML research code or team programs. Engine-shaped survivors of the eye pass,
probed with `probe14.sh` (`probe19_b.tsv`): mobx-keystone, adaptix, cattrs, keymap-drawer,
comfy-table, effector, vgmtrans, qpp, datashader, travels, ggsql, tanstack/charts, beanshell, iguana,
skeema, lib-font, robot. Earlier side checks: typeshare (DEAD, dormancy magnet: last code commit
2026-01-02 and a 21-PR queue of the obvious features: new target languages, serde flatten, readonly,
unions, u8 mapping), specta (AGENTS.md + 11 AI commits), interoptopus (CLAUDE.md, 5 AI), jimfs
(`arimu1` visit, Google maintenance), argdown (0 commits/90d), lobster (400 solo commits/90d, C++
with SDL), tract (162 AI-marked commits), pyret-lang (53 `claude` commits), putout (644 solo
commits/90d, plugin catalogue), vidact (179 solo/90d, React-named semantics), malloy (team, AGENTS.md).

Probe reads (`probe19_b.tsv`, 90 days): mobx-keystone 65 solo / 0 AI (root .claude + AGENTS + CLAUDE:
penalty); adaptix 0 on `main`, `develop` 94 commits since 2025-09 but quiet since April (zhPavel),
`binggao1230` x2 (#453 merged, #456 open, outside any core lane: note); cattrs 15 with three unknown
accounts (`winklemad`, `MaxFreedomPollard`, `uttam12331`: skipped); keymap-drawer 5 solo; comfy-table 22
solo + AGENTS.md; effector 37 (team, all Vue bindings + docs, core cold); vgmtrans 3; qpp 0; datashader
3; travels 189 solo (mutative author, firehose); ggsql team + CLAUDE.md; tanstack/charts 291 by
tannerlinsley (new project being built: capability-consuming); beanshell 206 by jimjag (modernisation
sweep); iguana 2; skeema 30 (MySQL-backed integration suite, SQL class); lib-font 8 (OpenType spec);
robot 2. Adaptix's open tracker is the maintainer's own zero-comment roadmap (#186 tagged union, #187
polymorphic loader, #291-#305 conversion items, #91 update-in-place): every item is a magnet.

Lane audits dispatched (brief `agents/BRIEF-0923-H19.md`, one repo per agent, dossiers
`agents/<tag>-0923H19.md`): effector (`eff`), keymap-drawer (`kmd`), adaptix (`adx`), mobx-keystone (`mks`).

Side verdicts while the audits run:
- **nukesor/comfy-table: DEAD.** The deep layout lane (cell spanning) has a public closed PR #194
  (colspan + rowspan, full diff) and a maintainer refusal on #195 pointing users at `tabled`
  (sibling ships it). What remains is width-constraint arms on a finished arranger.
- **vgmtrans/vgmtrans:** Zlib licence (outside the RULES.md allowlist as written), Qt GUI app, per-format
  sequence decoders = missing-arm catalogue. Skip.
- **holoviz/datashader:** numba + dask + xarray pipeline, slow JIT suite, team-owned reductions. Skip.
- **softwareQinc/qpp:** no commits in 90 days, textbook quantum-circuit lanes. Skip.

- **python-attrs/cattrs: DEAD on Stage 2b-bis.** Three scattershot accounts in the 90-day stream:
  `MaxFreedomPollard` (created 2026-03-31, 210 repos, "into evolving agentic AI"), `uttam12331` (no
  identity, 136 repos, PRs into accelerate / humanize / tortoise-orm) and `winklemad` (276 repos, PRs
  across arrow-go, gortsplib, haystack, jest, TypeScript, cpython ...). Threshold is two.
- The non-engine unjudged residual (`s_0923h19/unjudged_noeng.tsv`, 3,376 rows) was sampled: infra,
  famous crates, clients. Not screened further (see next-hunt hint).

### Lane-audit verdicts

- **caksoylar/keymap-drawer (`kmd`): DEAD, Requirement 7.** No test suite at all (no tests/, no
  pytest config); CI runs only black/pylint/mypy/deptry. Lane A (collision-aware combo placement with
  rotated-outline intersection) reproduced on base but sketched ~230 eff and fails the Stage 6 guard
  (post-pass in the draw code, independent traps). Lane B (layer-reachability `activates` field) is
  maintainer-owned #158 and #162 calls the current semantics intentional. Dossier
  `agents/kmd-0923H19.md`.
- **effector/effector (`eff`): DEAD, exclusivity + absorption.** Mechanically clean (MIT, tests green
  on master, kernel cold since 2026-03, no root AI files, no signature accounts). Invented lane
  "causal allSettled" (per-launch cause token through barriers and async continuations, ~230 eff): its
  core is already public on branches `exp-stack-meta-v2` (maintainer, per-launch meta through
  kernel.ts + createEffect, 181-line test) and `release/v24` (per-launch QueueInstance through
  onSettled); only ~90-100 eff of per-cause counting is unpublished. Five further scope lanes die on
  PR #807, maintainer philosophy (#440, #90), a hydrate() shortcut, or branches `feat-hydrate-scope`
  / `lazy-computations`. Repo-level warning: `release/v24` rewrites kernel.ts / fork.ts / createEffect
  in public, so any master-based kernel lane is pre-empted. Dossier `agents/eff-0923H19.md`.
- **reagento/adaptix (`adx`): DEAD.** Mechanically clean (Apache-2.0, 2277 tests deterministic 3x on
  py3.12, `main` CI green; `develop` has one py313-only failure). Lane 1 (one field loaded from several
  name_mapping paths, ~230-300 eff, cleared the guard) is DEAD on exclusivity through FORKS, not PRs:
  `blitzy-research/adaptix` carries five `blitzy-*` branches implementing "name_mapping aliases"
  (+256-370 in `loader_gen.py`, +146-257 in `name_layout/component.py`, the exact core footprint), and
  `LabTesing/deepswe-adaptix-name-mapping-aliases` is a benchmark fork named after the lane. Lane 2
  (defaulted fields at list positions) is absorbed: ~110-130 eff, a ~60-line shortcut passes, and
  dataclass_factory 2.16 / msgspec `array_like` define it. Dossier `agents/adx-0923H19.md`.
- **New cross-hunt finding (adx): fork-only benchmark factories are invisible to every PR/issue search
  and to PR-author profiling.** `LabTesing` holds 113 public `deepswe-<repo>-<lane>` forks
  (`agents/adx-labtesing-deepswe-forks.txt`, incl. yaegi, tengo, oxvg, pest, opa,
  `deepswe-cattrs-partial-structuring-recovery`); `blitzy-research` pushes lane branches to forks.
  Both appended to `sig_accounts.txt`. None of the 113 names bayes_opt, tegaki, ArchUnit, teavm or any
  LEDGER repo (grepped). Proposed Stage 2b-bis addition for the skill owner: `forks?sort=newest` plus
  a compare of non-upstream branches, and `gh api users/LabTesing/repos` grepped for the repo slug.
- **xaviergonz/mobx-keystone (`mks`): DEAD.** Mechanically clean (MIT, CI green, ref/snapshot/patch
  suites 422/422 x3 identical). The 2.0.0 release (2026-09-13) closed ~90 consistency edge cases
  across patches, snapshots, refs, undo and sandbox: a continuous correctness sweep over the whole
  f2p surface. Lane A (clone / generateNewIds remaps internal refs) reproduced on base but is one
  chokepoint (`fromModelSnapshot.ts:64`), ~80-120 eff, a ~50-line snapshot pre-pass passes, guard #1/#2
  FAIL. Lane B (first-class move patch op) is absorbed by the per-batch ModelPool (identity already
  kept), a cost not a value. Six more pre-screened lanes died on json-joy / MST / in-repo kernels /
  documented semantics. Dossier `agents/mks-0923H19.md`.

Fork scan of the live fallback, prompted by the adx finding: gkurt/tegaki's 7 forks pushed after
creation (sunwjy, ttymayor, L0stInFades, Bestbuybaby, ...) are personal forks, none a
`blitzy-*`/`deepswe-*` lane fork; LabTesing holds no tegaki / ArchUnit / bayes_opt / mobx fork.

## Budget spent

Proven pool (exhausted, 11th session); cached index (topic-sibling scoring over the 70 approved repos,
widened residual incl. NOASSERTION and >9000 stars: effectively exhausted); hint rows (ArchUnit
confirmed at the two-signature-account threshold; tegaki still guard #2); fresh sweep 1 (the 1,229-row
never-judged-in-writing residual -> 603 active -> eye pass -> 17 probed -> 4 full lane audits, all
DEAD; side kills typeshare, comfy-table, cattrs, specta, interoptopus, jimfs, tract, pyret, putout,
vidact, lobster, malloy). Fresh sweep 2 not run: no new source remains in the cache that the eye pass
rated above the four audited repos, and the non-engine residual sample was infrastructure.

## Result: NO-CANDIDATE

What the next hunt should change:
1. **Add a fork-branch exclusivity scan to every audit** (Stage 2b-bis/2c): `forks?sort=newest` +
   compare of non-upstream branches, and grep `users/LabTesing/repos` + `blitzy-research` forks for the
   slug. It killed adaptix after every PR/issue/author query was clean, and it must be re-run on
   bayes_opt before its core slice.
2. **The index is exhausted at the eye-pass level.** Remaining unread material: `s_0923h19/unjudged_noeng.tsv`
   (3,376 never-judged rows whose descriptions miss the engine vocabulary) and the maintainer-owned
   repos dismissed only for velocity. A new source is needed: e.g. dependents of approved repos
   (`gh api repos/O/R/dependents` is not in the API; use `network/dependents` scraping or PyPI/crates
   reverse deps of approved libraries), or org-mates of approved repo maintainers.
3. If the miss count rises: ArchUnit (nested layers, needs a second lever) is the only fallback that
   the softened rules could admit, and only if the two-account threshold is relaxed; tegaki needs a
   second coupled subsystem before it clears guard #2.
