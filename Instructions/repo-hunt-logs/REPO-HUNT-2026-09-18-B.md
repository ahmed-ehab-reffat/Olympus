# Repo hunt 2026-09-18-B — parked-lead audits + fresh-entrant sweep; no RANK 1

Second hunt of the day (Cwerg memory-passed parameters is in `problems/`). The proven pool has a
recent verdict on every repo and the cached band is swept (09-16-B), so this session took two axes
no earlier session had finished:

1. **Parked leads never lane-audited.** Four parallel subagents, one shared brief
   (`worktrees/_hunt/agents/BRIEF-0918.md`), each stopping at the first hard gate.
2. **Fresh entrants.** `worktrees/_hunt/fresh.py` fetched 490-620★ repos (7 languages x 7 permissive
   licences, pushed in 12 months) and diffed them against every cached band file. Output is
   `fresh_0918.jsonl`, 174 rows, 93 after dead-list + junk filter.

## 1. Parked-lead audits

| Repo | Gate reached | Verdict |
|---|---|---|
| synthetichealth/synthea | 1 (licence) | DEAD: vendored LGPL-3.0 jar `lib/sbscl/`, compiled in (`build.gradle:133`), imported by the engine's Physiology state (verified) |
| textX/textX | 2 (competitors) | DEAD: `santhreal` #444 + `chuenchen309` #445, one day apart (verified). Both added to `sig_accounts.txt` |
| wilsonzlin/minify-html | 1 (Req 7) | DEAD: 7 workflows, all tag-triggered build/publish, none runs tests (verified) |
| scribbletune/scribbletune | 5/6 | DEAD: clip-layering lane publicly diffed in closed PR #48 (verified); the real nested-tuplet drift gap is ~50-80 eff |
| mitex-rs/mitex | 5/6 | WEAK FALLBACK, see below |

### mitex — the one partial survivor

Lane: make the lexer-level macro engine follow the parser's grouping (definitions local to `{}`,
environments, formulas; ignored inside `\iffalse`), check new/renew/provide against the command
spec, bound expansion, and export surviving definitions as a preamble (#194). All reproduced on base,
including `\newcommand{\a}{\a}\a` hanging the engine. The engine reads ~170 tokens ahead of the
parser (`macro_engine.rs:399-404`), so calling the dormant `create_scope`/`restore`
(`macro_engine.rs:986/994`) from the parser is too late. That is a real misdirecting trap.

Why it is not RANK 1: the repo-own export half is ~105-145 eff; reaching 250 needs group scoping and
expansion limits, both public in KaTeX (`Namespace.ts`, `MacroExpander.ts:250`, `macros.ts:161`). By
the sfepy/JAX-FEM precedent a scope gate may rule the core cribbable. Build needs typst 0.10.0 on
PATH (copy at `worktrees/_hunt/bin/typst010/`). Full dossier: `worktrees/_hunt/agents/mitex-0918.md`.

## 2. Fresh-entrant sweep

The band's `stars:500..6000` snapshot (09-14) cannot contain repos that crossed 500 since. The sweep
found 174 such rows, but almost all engine-shaped ones sit at 490-499★, i.e. still under the floor:

| Repo | ★ | Read |
|---|---|---|
| heitzmann/gdstk | 499 | **WATCH.** GDSII/OASIS layout toolkit, C++ + Python, BSL-1.0, CI `Tests Runner` green, solo maintainer (11/15 commits), 50 PR-free issues, 2 open PRs (one is a Clipper2 migration), no signature accounts. One star short; not audited. Vendored-licence and lane audit still owed |
| pcodec/pcodec | 497 | under floor; maintainer `mwlon` actively reworking the codec heuristics (capability-consuming) |
| phonopy/phonopy | 496 | under floor; 300 maintainer commits/12mo (QHA programme) |
| unexpectedpanda/retool | 495 | no CI |
| gpertea/gffread | 499 | 1 commit/12mo, no CI |
| hedge-dev/XenosRecomp | 495 | 0 commits/12mo, no CI |
| wwrechard/pydlm | 492 | 4 commits/12mo, publish-only CI |

Rows at or above 500 were infra, apps, GPU renderers, or 2026-created repos (Rux, dial9,
automic-vault, ExtendDB), none engine-shaped with a test CI.

## Method notes

- **Java vendored-jar licence scan** belongs in Stage 1 alongside the C++ `external/` scan:
  `find . -name '*.jar' -not -path './gradle/*'` and `ls lib*/*/ | grep -iE 'licen|copying'`.
  synthea's top-level Apache-2.0 hid an LGPL jar the 09-15 hunt never opened.
- **The fresh-entrant axis is thin but cheap** (~3 min of search quota). Re-run `fresh.py` in a few
  weeks: the 490-499 cohort (gdstk, pcodec, gffread) crosses the floor over time.
- **Parked-lead audits:** 5 of 5 died, 4 at a gate that costs one or two API calls (licence, CI,
  signature accounts, a closed PR diff). Parked leads should get those four checks when they are
  first logged, not a later subagent audit.

## Housekeeping

- Clones removed: synthea, textX, scribbletune. `worktrees/mitex` kept (source only) for the fallback.

## Addendum — gdstk lane audit (user chose option 1)

Mechanics clean: BSL-1.0 top level and vendored `external/clipper` (BSL), qhull + zlib are system
deps (`libqhull-dev` via apt), `Tests Runner` green, 2 open PRs (#330 Clipper2 migration, #286 gzip +
OASIS filtering), no signature accounts across 100 PRs. The maintainer ran an AI pass on #327 (report
posted in the thread); not a lane sweep.

| Lane | Verdict |
|---|---|
| hierarchy instance query / partial flatten (#301, #264, #236) | DEAD: `Reference::transform` (`reference.cpp:181`) and `Repetition::transform` (`repetition.cpp:273`) already compose the transform; remaining work is a traversal (<150 eff), and #264 carries public user code (`find_leaf_reference_offsets_and_rotations`) |
| OASIS repetition compaction on write (#281) | DEAD: spec-named, KLayout's OASIS writer does shape-array detection publicly, and the benefit is file size (a cost, not a testable value) |
| repetition-aware booleans / offset (#191) | DEAD: uniform wrap (apply the repetition before every op) |
| skewed AREF read (#299, `library.cpp:1175` drops v1.y/v2.x when unrotated) | real F2P gap on base, ~5 lines |

Verdict: no authorable lane. gdstk is a mature, well-factored API whose tracker is bug reports; the
star count is moot. The user offered to star it to reach 500; declined, since self-starring to clear
the eligibility floor games the rule.

---

# PART 2 — softened hunt (user: "continue until authorable, soften the restrictions a little")

## What was softened, and what was not

Softened (workspace heuristics only): a maintainer who builds with AI (`CLAUDE.md`/`AGENTS.md`,
historic `copilot-swe-agent` PRs) is a NOTE unless the AI work touches the lane; fast maintainer
feature velocity is a lane-volatility RISK to re-check at submit, not a reject; an outsider-nameable
capability with no public implementation and no tracker magnet is MEDIUM and mitigated in meta.md.

Kept hard: licence incl. vendored, >= 500 stars, 12-month code commits, test CI green on the default
branch, no public implementation of the core (repo, forks, sibling tools), no famous language-surface
feature, >= 250 eff sketch. A softened re-triage of the cached band (`cand_soft_0918.txt`,
`cand_hi_0918.txt`: rows previously dropped only for AI marks / <6 issues / >6000 stars) was mostly
LLM/TTS repos and produced nothing.

## RANK 1 — hanruihua/ir-sim (Python, MIT) ★1130 — declarative scenario events in the step loop

The 09-17 SIM agent's conditional survivor (`worktrees/_hunt/agents/sim.md`), re-verified today at
HEAD `e4a60f9` (2026-09-12).

- **Mechanics:** MIT (LICENSE read), pure Python (numpy, scipy, shapely, matplotlib, pyyaml, loguru;
  `pyrvo` optional, has wheels). CI `Test with python versions` + `Ruff lint` green on main. 248
  commits/12mo (126 maintainer code commits). 0 open issues, 0 open PRs. Quota 0/6.
- **Competitors:** none. Outside PR authors `waxz` (2015 account, 352 repos, real footprint) and
  `omnilink-tech` (org account); no signature hits. Maintainer builds with Claude (`CLAUDE.md`,
  `AGENTS.md`, 3 AI-marked commits) but nothing in the stream touches events (softened rule).
- **Baseline:** `pytest -o addopts=""` = **995 passed, 45 skipped, identical 3x**, 139-162 s. Needs
  `pytest-cov` (pyproject `addopts`) or the addopts override. Headless via `display=False` + Agg.
- **Roadmap check:** commit `7c086d9` "release schedule" is a monthly release cadence, not a feature
  roadmap.
- **Exclusivity:** PR/issue search (event, trigger, spawn, scenario) in the canonical repo: nothing
  but #61 (install). Code search for irsim + events/spawn: empty. The one diverged fork
  (`Ethereal1024/ir-simX`, 98 commits ahead) has no event/trigger/scenario commits or files. No
  sibling tool implements ir-sim's model (CARLA scenario_runner / OpenSCENARIO are a different model;
  nothing portable).
- **Self-collision:** no ir-sim or robot-simulator pick in approved/problems/rejected.

### Verified F2P gap (base `e4a60f9`)

- An `events:` top-level section is refused: `Invalid key: 'events' ... Valid keys: custom, gui,
  obstacle, robot, world` -> `KeyError` (`env_config.py:61-68`).
- The coupling seam: an obstacle added at runtime via `create_obstacle` + `add_object` SURVIVES
  `env.reset()` with its id (`[('robot_0', 0), ('obstacle_1', 1)]` before and after), because
  `_reset_all` only calls `obj.reset()` on the current list (`env_base.py:857-906`). An events feature
  whose contract is "reset restores the authored scene and re-arms events" must fight that path,
  while `reset(random=True)` and `reload()` rebuild from the parse (`_rebuild_from_cached_parse`).
- Probes: session scratchpad `probe.py`, `probe2.py`, `ev.yaml`.

### Missing machinery (Stage 3b)

Nothing in `irsim/` evaluates conditions over simulation state or schedules actions: no hook in
`step()` (`env_base.py:320-400`), no condition language, no firing state, no spawn-from-template.
The algorithm the repo lacks: **a per-tick condition evaluator with firing state (once / repeat with
cooldown / delay) whose actions mutate the object set, kept consistent with ids, names, the collision
tree, status and the three reset paths.** Nearest sibling (`custom` section, #359) is ~10 lines, so
this is a new subsystem, not a missing arm.

| Piece | eff |
|---|---|
| `events:` parse + validation (unknown condition/action keys, bad targets) | 40-50 |
| condition evaluator: time/step, region enter/leave (edge-triggered), distance, arrive/collision, all/any/not | 70-90 |
| firing modes: once, repeat + cooldown, delay; deterministic firing log | 35-45 |
| actions: spawn from template (name numbering, id policy), delete by name/group, set goal/behavior, pause, stop | 60-80 |
| env wiring: step order (after `_status_step`), pause/debug/external `step_mode`, `done()` with spawned robots | 30-40 |
| reset / reset(random) / reload: remove spawned, restore deleted, re-arm | 30-40 |
| public API (`env.add_event`, `env.events`, log accessor) | 20-25 |
| **total** | **~285-370 eff, >= 4 files** (`env_config.py`, `env_base.py`, new `env_events.py`, `object_factory.py`) |

### Trap seams

| Pattern | Present | Evidence |
|---|---|---|
| F-9 origin variant (two reset paths) | yes | `reset()` iterates current objects; `reset(random=True)`/`reload()` rebuild from the cached parse. Re-arming and restoring must work through both, and they share no code |
| F-15 arming vs firing | yes | region enter/leave must be EDGE-triggered (fires on the transition, not every tick inside); "repeat with cooldown" is the one-event fixture |
| F-35 ordering | yes | the world clock advances in `_world.step` before `_status_step`; a `time >= t` condition evaluated before vs after the status step is off by one tick, and arrive/collision are only fresh after it |
| F-25 id/placeholder | yes | ids come from a per-env counter (`object_base.py:275`); a spawned robot gets an id above the obstacles, breaking the documented "robots are 0..n-1" rule that `action_id` relies on (`env_base.py:346`) |
| F-10 cross-product | yes | condition kind x action kind x firing mode x step_mode (internal/external) x reset kind |
| F-14 declared terminal state | yes | a `stop` action vs `done()` derived from arrive/collision |
| F-34-like aliasing | likely | spawn templates are dicts from the parse; instantiating without a deep copy makes repeat spawns share state (check at authoring) |

### Phase-3 death-class guard

1. **Shared kernel:** one evaluator inside `step()` drives spawn/delete/goal/pause/stop, and every action
   feeds ids, names, the STRtree, status and the reset paths. Fixing spawn by appending breaks
   `robot_list`/`action_id`; fixing reset by rebuilding breaks the non-random reset contract.
2. **Interdependent:** step-order choice changes which ticks conditions see; the id policy for spawned
   robots changes what `action_id`/`done()` mean; reset re-arming depends on how spawned objects are
   tracked.
3. **Standalone new file?** The evaluator can live in a new file, but ~40% of the work and most traps
   are in the wiring (step order, ids, reset paths). Not a post-pass over a public stream.
4. **TOO-EASY guards:** not a language feature, not a port, no tracker magnet (0 issues).

### Risks

- **Lane volatility (the softened rule):** the maintainer ships a feature about weekly and builds with
  AI. Re-run the commit/PR check at every authoring round and at submit.
- **Design freedom / fairness load:** every semantic (evaluation point in the step, edge vs level
  triggering, spawned-robot id policy, what each reset path restores) must be stated in meta.md. Budget
  the 500-word cap early; keep the condition/action set to what the description can pin.
- **Philosophy signal:** the `custom` section comment ("values a user's own code needs") hints that
  scenario logic lives in user code. Not a decline, but phrase the feature as extending the YAML model.
- **Derivative MEDIUM:** "scenario event triggers for a robot simulator" is outsider-nameable. Mitigate
  on ir-sim's own nouns (objects/groups/behaviors, `step_mode`, the three reset paths, id ordering).
- **Requirement 0:** check ir-sim in the platform repository picker before designing.

Clone kept at `worktrees/ir-sim` (HEAD `e4a60f9`); venv `/tmp/claude-1000/irsim-venv` (disposable).
