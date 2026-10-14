# REPO-HUNT-2026-10-03-B (hunter #48, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **CANDIDATE**, tortoise/aerich (migration-history squash with an observational-equivalence contract).

Scratch: `worktrees/_hunt/s_1003h48/`:
- `rem_h48.py` / `rem_h48.tsv`: cached-index rows not in `dead_h47.txt`, the ledger, or our corpus.
- `eyed_all_h48.txt`: the union of every earlier `sel*/eyed*/rank*/scored*/cand*` file (15,139 slugs).
- `fresh_h48.tsv` (13,437 never-selected rows) and `fresh_eng_h48.tsv` (1,746 engine-shaped rows).
- `screen1_h48.txt`: the screen of the 9 cache-triage picks.
- `forkscan_aerich_h48.txt`: clean.
- `probe_aerich_w1_h48.sh`: the W1 reproduction (see the dossier).

## Standing inputs
- **Direction:** hunt #47's NEXT_HUNT_HINT.
  - Re-verify the un-ledgered `## Fallbacks` entries in recent hunt logs before any fresh sweep.
  - Fix `screen.sh`'s relative `sig_accounts.txt` path.
- **Excluded:**
  - every LEDGER repo, in every status;
  - every `problems/` folder;
  - gonum/plot (queued) and Athou/commafeed, plus its reserved fallbacks cloudflare/pint, cenkalti/rain and naggie/dstask;
  - SATURATED-REPOS, `rejected/` and `approved-problems/`.
- **Softening:** misses = 0, so no relaxation was taken. The 2026-09-09-B softenings already written into the skill were applied as written. **Relaxations: none.** No star or issue window was widened.
- **Requirement 0 (platform picker):** OWED for every candidate.
- **Disk:**
  - `/` read 8.0G at the start, then 7.6G, so no build ran.
  - Two small throwaway venvs (48M and 74M, pip `--no-cache-dir`, under `s_1003h48/`) were used to run the two finalists' pure-Python suites. Both were deleted after measurement.
  - The end reading was 8.6G.

## Tooling fix (hint #2)
`worktrees/_hunt/screen.sh` line 16 now reads `/home/ahmed/Olympus/worktrees/_hunt/sig_accounts.txt` by absolute path. Before the fix, running it from a tag dir silently printed an empty SIGNATURE line. Verified: the aerich screen now reports `SIGNATURE HITS: 1 RitiGrover`. The per-hunt copies `s_09*/screen_h*.sh` already used an absolute `SIG=` path.

## Stage 0-bis: the proven pool
No approvals have arrived since hunt #46's full pool kill table. The last approvals (grmtools, macs-circular, riff, ray-optics-sp) are all LEDGER rows. I did not re-screen. **Result:** nothing new.

## The un-ledgered fallback reserve (hint #1), re-verified today

| Repo (source log) | Today | Verdict |
|---|---|---|
| tortoise/aerich (09-30, hunt #42 fb 1) | `dev` still 6333068e (2026-08-24/25). Only open PR is #561 (RitiGrover, executor txn split, outside the lane). Fork scan clean. No squash-class issue or PR in any state (squash, combine, collapse, baseline, consolidate, merge/reset migrations, replaces); RFC #366 body and comments contain none. Suite run locally: **70 passed / 10 skipped** (PG/MySQL), identical over 5 runs; 2 env-only failures before `tomli-w` was installed were also identical 3/3 | **RANK 1** (dossier below). One dossier correction: W3 is dead |
| sqlalchemy-continuum (09-29-G, hunt #41 fb 1) | main still a84e828 (1.8.0). Open PRs unchanged (#397/#393/#391 touched 09-29, outside the lane). Suite run locally on SQLite (multithreaded file deselected): **856 passed / 15 skipped, identical 3/3**. T1 vacuum bug confirmed in source (`utils.py:239-248` appends only in the `else` branch; `naturally_equivalent` compares end_tx/op columns). The F-10 fan-out confirmed (`tests/__init__.py` `setting_variants`, 8 cells) | **FALLBACK 1.** Best trap thesis of the reserve, but the repriced size is ~180-230, and Stage 6 Q3 is borderline: a squash could live in one new module that reads the holders, with no existing read path forced to change |
| aptly-dev/aptly (09-30-B) | Last master commit 2026-07-01. Publish lane still warm (by-hash/S3 PRs, Daedaluz `claude/*` publish branches) | FALLBACK 2 (WEAK, ~220-240, needs a coupled lever) |
| devpi/devpi (09-30-B) | The `fschulze/devpi:server7` rewrite of both kernels is still unmerged (last 08-21). Main merged #1128 from `r3wretrhy`, a sig_accounts row | DEAD for now |
| ipyflow/ipyflow (09-30) | No core commit since 08-14. The staleness planner is the maintainer's AI-assisted lane | WEAK, unchanged |
| Stvad/CrowdAnki (09-29-G) | Active (export refactor 09-17/18) | Class collision with micasa (HANDOFF). Not returned |
| lebab, FullHuman/purgecss, yshavit/mdq, buchgr/bazel-remote | not re-opened | WEAK or do-not-return per their logs (no CI / named-spec magnet / L2 rule list / do-not-return) |

## Cached index (new cut, not a re-read of an old selection)
- **Input:** 34,746 cached rows (band, band_misc, band_noassert, band_hi), filtered to:
  - a permissive licence (or NOASSERTION for a manual read);
  - Go/Rust/Python/TS/JS/C++/Java;
  - pushed after 2025-12-01;
  - 500-15,000 stars;
  - not in `dead_h47.txt`, the ledger or our corpus.
  
  That left 22,630 rows. Minus every slug any earlier hunt's selection file ever showed, **13,437 rows had never been selected**. A junk filter plus an engine vocabulary left **1,746**.
- **Method:** I eyeballed every Rust, Go and Java row, the C++ rows under ★8000, and the Python and JS/TS rows minus UI/app noise.
- **Screened (9):**

| Repo | Verdict |
|---|---|
| posit-dev/ggsql (★558, Rust) | DEAD. Capability-consuming feature build: 300 commits/12mo from four Posit devs, 159 AI co-author trailers in the last 100 commits, 12 open feature PRs |
| naia-lib/naia (★1180, Rust) | DEAD. A solo-maintainer feature firehose (300/12mo, 85 AI co-author trailers); entity-replication lanes are his workstream |
| django-treebeard (★1224, Py) | DEAD. **Two distinct signature accounts** (binggao1230, SAY-5) on the repo, which is the softened reject threshold |
| mtth/avsc (★1388, JS) | DEAD. 0 commits in 12 months (Requirement 3/6) |
| assetgraph/assetgraph (★897, JS) | DEAD. A near-corpse: 2 commits in 12 months, a depfu-only PR queue |
| jqno/equalsverifier (★746, Java) | DEAD. A mature reflection framework with 0 issues and 0 PRs. Every extension point is absorbed (framework-maturity law) |
| Chlumsky/msdf-atlas-gen (★1335, C++) | DEAD. No workflows (Requirement 7) and 5 commits in 12 months |
| treasure-data/digdag (★1331, Java) | DEAD. 2 commits in 12 months, 44 dependabot PRs |
| cargo-public-api (★578, Rust) | DEAD. `app/copilot-swe-agent` PRs, and the Docker setup needs nightly rustdoc-JSON |

- **Result:** nothing from the cache.

## Fresh niche sweeps: 0 of 2 used
I checked untouched-looking niches first. Each one is already covered:
- Terminal emulators: `agents/term-0919G`. contour, vte, vt100-rust, avt, xterm.js and jediterm are all on the dead list.
- Plain-text accounting: `agents/ledger-0919D`. ledger/ledger is dead.
- Board games: `games-0919B`.
- Others: notation, formula, graph layout, transport, storage, physsci, embedded, dependency resolution, docvcs, textalgo, testtools, planning, linked data, optstat, fab and bio.
- Data formats and resolvers: zarr, fsspec, xarray, pdm, uv, pixi and resolvelib are all seen.

The seen union is now **36,323 slugs**. With a candidate surviving the Stage 6 guard, two more sweeps were judged low-yield, and I spent the budget on base measurement of the reserve instead.

## RANK 1 dossier: tortoise/aerich, ★1083

- **URL:** https://github.com/tortoise/aerich. The canonical slug is confirmed via `gh api` full_name.
  - Licence: Apache-2.0 (one LICENSE, nothing vendored).
  - Language: Python 99%.
  - Quota: 0 of our subs, and not in SATURATED-REPOS, the ledger, `problems/`, `rejected/` or `approved-problems/`. `rejected/alembic-acyclic-stitching` is a different capability (revision-graph splice) in a different repo.
- **BASE candidate:** `dev` HEAD `6333068e` (2026-08-25, "Bump version to 0.10.1"). Clone: `worktrees/aerich-h42` (blobless, 2.2M, clean `git status`, no build output). Pin the base before #561 merges, because #561 edits `aerich/__init__.py` (the executor).
- **Activity (Requirement 6):** 50 commits in 12 months (44 waketzheng), all real code: per-app migrations #500, offline migrate #441, rename model class #529, list applied #512, tortoise 1.0 support #528. Not a firehose and no AI marks.
- **CI (Requirement 7):** `ci.yml` runs on PRs to dev, so there are no default-branch rows. The latest PR runs are green; a `failure` on 09-18 is a dependabot uv job. Local measurement replaces the badge: **70 passed / 10 skipped, deterministic across 5 runs** (SQLite; PG/MySQL tests skip without servers).
  - Flake risk: `run_aerich` uses subprocess `timeout=2`, but runs took 95-169 s with no flip.
  - Deps are pinned in `uv.lock` (tortoise-orm 1.1.8).
  - The suite needs the `aerich` script on PATH (an editable install) and `tomli-w`.
- **Signature check (with the fixed screen.sh):** RitiGrover x1, OPEN #561, outside the lane. That is one account and one PR, so a note only. Fork scan: clean (`forkscan_aerich_h48.txt`).
- **Lane:** `Command.squash(A, B)` plus `aerich squash --from A --to B`. It folds the contiguous range A..B into one migration file and compacts the DB's `aerich` rows. Afterwards every command must behave as if the range had never been squashed:
  - `migrate`: the next diff baseline, and version numbering both online and `--offline`;
  - `upgrade` on a DB that recorded none, some or all of the members;
  - `downgrade -1`, `downgrade -v N` (N a member number), `--delete`;
  - `heads`, `list_applied` / `get_applied_migrations`;
  - `init-db` on a fresh DB with existing migration files (`__init__.py:280-290` replays every file);
  - per-app ledgers (#500): squashing app X never touches app Y's rows.

  `history` is the one stated exception.
- **Base gap:** no squash API or command exists (`grep -rniE "squash|collapse|consolidat" aerich/` = 0), so a call raises AttributeError.
- **Walls (file:line, verified today):**
  1. **W1, the ledger order is the pk and feeds the planner (REPRODUCED).**
     - Mechanism: `Aerich.Meta.ordering = ("-id",)` (`models.py:15`). `get_last_version` takes `.first()` and feeds `_last_version_content` (`migrate.py:118-128, 206-207`). `_get_last_version_num` numbers the next file from that row (`migrate.py:215-236`). `downgrade -v N` deletes by `pk__gte` (`__init__.py:159`).
     - **Probe (`probe_aerich_w1_h48.sh`):**
       - Setup: init + add_a/add_b/add_c, then a naive compaction of 1..2 (new row, member rows deleted).
       - The next `migrate --name add_d` produced `2_..._add_d.py` containing `ADD "d"` **and** `ADD "c"`. The baseline came from the new row, and the version number collides with the order of the existing `3_add_c`.
       - `aerich upgrade` then fails with `OperationalError: duplicate column name: c`, which is far from its cause. Misdirecting (F-58/F-47).
  2. **W2, two holders of "applied".**
     - `upgrade` checks `Aerich.exists(version=file)` (`__init__.py:130`), so a squashed file on a fully-applied DB re-runs. On a partial prefix, only the unrecorded members may run, so the file must keep per-member segments and the executor needs a resolver.
     - `downgrade` imports each row's file by name and uses `version__startswith=f"{N}_"` (`__init__.py:152, 166`), so member rows and member numbers must map into the squashed file.
     - The same resolver feeds `heads` and `init-db`. Pattern: F-9 / F-58.
  3. **W4, two origins of the baseline (F-9 origin variant).** Offline `init` reads the LAST FILE's `MODELS_STATE` and numbers from the last file (`migrate.py:193-205, 215-224`). Online reads the last ROW. A squash that is right for one origin is wrong for the other: the file must carry B's snapshot, and the ledger must leave the true last row last.
  4. **W5, mixed `RUN_IN_TRANSACTION` across members** (`__init__.py:136, 285`). This needs grouped execution.
  5. **F-10 cells:**
     - range position (baseline 0..k / mid / tail) × DB state (none / partial / all) × command;
     - per-app;
     - `init-db` replay;
     - downgrade across the squashed boundary.
  - **Dossier correction:** hunt #42's W3 (`_is_unique_constraint` mining the file history, "observable on SQLite") is **dead**. The function returns False unless `cls.dialect == "postgres"` (`migrate.py:637`), which an offline SQLite image cannot exercise.
- **Missing machinery:**
  - a squash writer: upgrade in member order, downgrade in reverse order, B's MODELS_STATE, per-member segment markers;
  - ledger compaction that keeps the last member's row and pk;
  - an applied-state resolver consumed by upgrade, downgrade, heads, init-db and list.

  None of this exists. The repo has no multi-version file concept anywhere.
- **Eff sketch:**

  | Part | eff |
  |---|---|
  | range validation | 30 |
  | segment extraction and nested flatten | 25 |
  | writer | 30 |
  | segment parse | 15 |
  | compaction | 30 |
  | resolver | 35 |
  | upgrade partial | 30 |
  | downgrade | 40 |
  | heads / list / init-db | 20 |
  | CLI | 20 |
  | **sketch** | **~275** |

  Repriced by the first-shared-operator law (the resolver collapses about 30 of the reader surfaces): **~240-250**. That sits in the 150-250 band, so the skill requires a named coupled lever. The lever is **the offline origin plus the init-db replay path (W4)**: a second, structurally different consumer of the squashed file and its snapshot, and not breadth. The builder must measure the full-scope spike first.
- **Exclusivity / six-check:**
  - 0 squash-class issues or PRs in any state (11 queries today plus hunt #42's dump of 338 issues and 219 PRs).
  - No removal record: CHANGELOG has no squash/removed hit for the lane.
  - Not a port.
  - **Sibling check:**
    - tortoise-orm native migrations (clone at 960b585, 2026-10-01) carry a `replaces` attribute (`migration.py:13,23`) and the writer can emit it (`writer.py:262-305`), but there is no squash command, and neither the loader nor the graph reads `replaces`. So there is nothing to crib. It is a weak signal that the sister repo may build Django-style squash later; re-check at submit.
    - Django `squashmigrations` is the famous sibling, but its model is different (a graph with `replaces`, no row ledger).
- **Docker:** pure Python on SQLite, `olympus-base-python`, pip from `uv.lock` at build time, offline test run. The editable install must put `aerich` on PATH for the CLI tests. Exclude the PG/MySQL tests (they skip). Drive the new tests in-process through `Command` to avoid the 2 s subprocess timeout.

### Stage 6 death-class guard (run on RANK 1)
1. **One shared kernel, several surfaces: YES.** The resolver and the compacted ledger feed upgrade, downgrade, heads, init-db, list and the planner baseline (online and offline).
2. **Interdependent: YES.**
   - W1 and W2 share the compaction rule: keeping the last member's row fixes the baseline but breaks the partial-prefix upgrade unless the resolver maps member rows.
   - W2 and W4 share the segment format.
   - W1 shows up as a later command's DDL error, not in squash.
3. **Standalone file: NO.** The executor's existence checks, downgrade lookup, init-db replay and the planner's numbering must all change, so a new module alone cannot pass the equivalence tests.
4. **TOO-EASY Pre-Pick Guard:**
   - G1: not a uniform wrap (writer, compaction, resolver and two origins are distinct mechanisms).
   - G2: not a single-subsystem transform (writer plus executor plus planner).
   - G3: the walls survive full statement of the equivalence contract, and the fix stays hidden in `-id` ordering and the offline origin.
   - G4: not a port (Django squash is a different model).
   - G5: yes.

**GUARD: PASS.**

### Risks (for the builder)
1. **Outsider-nameable** ("squash migrations", Django). There is no tracker magnet, but rivals may converge on it. Mitigation:
   - phrase meta.md on aerich's nouns (`aerich` rows, MODELS_STATE, version prefix, offline origin);
   - put the F-10 table in the tests;
   - run the PR-DIFF check at submit, and watch tortoise-orm for a squash command.
2. **LOC margin is the first risk** (~240-250 repriced). Measure the full-scope spike before the slice. If it lands under 220, fold in `downgrade --delete` and the nested-squash flatten before reaching for anything else.
3. **Strategic drift:** aerich recommends tortoise native migrations for tortoise>=1.0 (`cli.py:65`). The repo is maintained, but in maintenance mode. Re-check the activity precheck at submit.
4. **Fairness:** the contract must name every command that has to stay equivalent, the one exception (`history`), and that member numbers stay valid for `downgrade -v`. The tests must assert only DB schema, `aerich` rows and command results, never the squashed file's internal format.

## Fallbacks
1. **sqlalchemy-continuum/sqlalchemy-continuum**: transaction-range squash with restitch of the validity chain, op algebra and the plugin holders (TransactionChanges/Meta, Activity), plus the vacuum rebuild.
   - Strongest traps of the reserve: F-39 vacuum / `update_end_tx_column`, misdirecting op algebra, PK collisions at flush, the 8-cell F-10 fan-out.
   - Weaknesses: repriced ~180-230, and Stage 6 Q3 is borderline (needs an existing read path forced to change).
   - Base measured today: 856/15, identical 3/3. Clone `worktrees/sqlalchemy-continuum-h41`.
2. **aptly-dev/aptly**: publish history plus rollback (~220-240, needs a coupled lever; the publish lane is warm). Clone `worktrees/aptly-h43`.

## Clones and scratch
- **Kept** (no build output): `worktrees/aerich-h42`, `worktrees/sqlalchemy-continuum-h41`, `worktrees/aptly-h43`.
- **Deleted:** both venvs, the probe working dir and the temporary tortoise-orm clone. `s_1003h48/` holds only the tsv files and scripts (6.1M).

## What the next hunt should change
1. **The un-ledgered reserve is now spent.**
   - aerich is promoted.
   - continuum and aptly are the last two with any life, and both need a coupled lever.
   - devpi is blocked on server7, CrowdAnki on micasa.
2. **The cached index is exhausted at the engine end:** 13.4k never-selected rows yielded 9 screen-worthy picks, all dead. The seen union is 36k slugs, and every niche I could name had an `agents/*-0919*` sweep. A next hunt should not re-fetch the star band. Better sources:
   - the **sister repos of accepted or in-flight picks**, as tortoise-orm was here (same maintainers, same domain, often a younger capability surface);
   - or a **time-delta** re-screen of repos the dead list killed for activity reasons more than 60 days ago (near-corpses that have since revived).
3. **Run each finalist's suite in a throwaway pure-Python venv at hunt time when disk is under 8G.** It costs about 50-75M and two minutes. It caught a stale dossier claim today (aerich W3 is Postgres-only), which a static re-read had carried for three hunts.
