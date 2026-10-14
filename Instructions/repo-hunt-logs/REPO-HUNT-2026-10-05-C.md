# REPO-HUNT-2026-10-05-C (hunter #51, CONSECUTIVE_MISSES=2)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1005h51/`:
- `eyed_all_h51.txt` (24,276 slugs): screened_h50 + eyed48 + eyed49 + eyed_h49 + eyed_all_h48 + deadlist_all. These are rows a hunter actually LOOKED AT, as opposed to `union_h50.txt`, which also holds every fetched cache row (`seen_any`).
- `eyed50_extra.txt` (3,342): the rows #50 eyeballed but never wrote into screened_h50 (`unscr_h50`, `dom_h50`, `h48eng`).
- `never_eyed_h51.json` (9,171): band + band_misc + band_noassert rows at 500-6000 stars, pushed after 2026-06-01 (as of the cache fetch), in a supported primary language, that are in neither list above.
- `hiband_keep_h51.txt`: the 6k-15k band read (522 rows).
- `fresh_eye_h51.txt` (331), `sweep1_sci_h51.txt` (397), `sweep2_app_h51.txt` (619): the three never-eyed cuts below.
- `screen_*_h51.txt`: mechanical screens (screen.sh) of 25 repos.
- `read_h51.txt` (1,869 slugs read by eye today) and `screened_h51.txt` (28,388, the union of everything eyeballed so far). **Use `screened_h51.txt`, not `union_h50.txt`, as the "already looked at" list.** The union is a fetched list; it hides 9k rows that nobody ever read.

## Standing inputs
- **Direction:** hunt #50's NEXT_HUNT_HINT. Option (a) was to read the 6k-15k band in `band_hi.jsonl`. Option (b) was to spike the best WEAK row, but only tylax/pokerkit once their stars clear ~520, or wfdb-python outside multi-segment writing.
- **Excluded:**
  - every LEDGER repo, in every status;
  - every `problems/` folder;
  - the queue: tortoise/aerich (with sqlalchemy-continuum and aptly reserved), Athou/commafeed (with cloudflare/pint, cenkalti/rain and naggie/dstask reserved), gonum/plot;
  - SATURATED-REPOS, `rejected/`, `approved-problems/`, per-repo quota;
  - the turmoil clock lane (#22) and mapproxy level-scoped coverage.
- **Softening (misses = 2):** the 2026-09-09-B softened rules apply. Relaxations taken and recorded:
  1. **Star window widened upward.** The 6,000-15,000 penalty band was read in full (option (a)). The 500 floor was not touched.
  2. **Issue window:** none to widen. The issue count is a ranking signal and gates nothing.
  3. **Fresh sweeps were run over never-eyeballed cache rows** instead of new GitHub queries, because every GitHub axis now returns fetched rows.
  - Not relaxed: licence, language, activity, live upstream, Requirement 7 (`failure` on the default branch), the signature-account threshold.
- **Requirement 0 (platform picker):** OWED (no candidate).
- **Disk:**
  - `/` read 8.1G free at the start and 8.1G at the end.
  - No build, venv or Docker.
  - One clone, `worktrees/lektor-h51` (6.4M), was made and deleted after the verdict.
  - Per the orchestrator note, `worktrees/pokerkit-h50` (8.6M, no build) was deleted.
  - Scratch is 4.6M.

## Stage 0-bis: proven pool
Nothing new. Every recently approved or in-flight repo is a LEDGER row. The 87 pool repos at 1-2 subs are covered by #46's kill table. The WEAK reserve was re-read:
- **luna:** lane A spiked at 217 / ~125 and failed guard Q5 (#32).
- **capa / vega / healthchecks:** spiked DEAD.
- **markdoc:** its specializer half collides with our accepted featurevisor-target-specialization.
- **ipyflow, piccolo, wsgidav, adguardhome-sync, devpi, bazel-remote, purgecss, lebab, mdq, MetPy, rust-minidump XSTATE:** each WEAK, all under 250 or carrying a named-spec/collision note.
- **dstask:** reserved as a commafeed fallback.

None is returnable.

**Option (b) is blocked by its own preconditions:**
- scipenai/tylax: still ★501.
- uoftcprg/pokerkit: still ★502.
- MIT-LCP/wfdb-python: the GitHub primary language is Jupyter Notebook, Python is 18% of bytes, and the project is in maintenance mode.

## Cached index 1: the 6k-15k band (option (a)): 0 viable
- **The cut:** 2,150 `band_hi.jsonl` rows at 6k-15k. 1,697 of them are not in screened_h50, but #39 already eyeballed 1,401 rows above 6k. A negative app/AI/infra filter left 522 rows (`hiband_keep_h51.txt`), all read by eye. Almost every row is a famous library (magnet).
- **Screened (`screen_hiband_h51.txt`):**

| Repo | Verdict |
|---|---|
| evcc-io/evcc (Go 7.3k) | DEAD. A Claude issue/PR agent runs in the maintainers' own workflows, 13 AI co-author trailers, and andig ships 132 commits/12mo across the optimizer and loadpoint lanes |
| google/wireit (TS 6.4k) | WEAK. aomarks is building the cache lane now. The integration suite spawns real processes (flakiness risk). `rootkiller6788` (see below) visits |
| jlfwong/speedscope (TS 6.8k) | DEAD. Dormancy magnet: 15 commits/12mo with public open PRs for diff mode, search filtering, Perfetto import and callgrind fixes |
| hydra-ecosystem/hydra (Py 10.7k) | DEAD. omry ships 196 commits/12mo (Hydra 1.4, override parsing, run modes) with AI trailers. The ANTLR jar is a Docker cost |
| fujiapple852/trippy (Rust 8k) | DEAD on Requirement 7. CI `failure` on master for 4 consecutive days. It is also a raw-socket tool |
| facebookresearch/Kats (Py 6.5k) | DEAD. Meta-internal bot commits, intermittent `Build` failures on main, and a textbook-method catalogue |
| pdfcpu/pdfcpu (Go 8.9k) | DEAD. Two signature accounts (SAY-5 x2, Yanhu007), and hhrutter's 234-commit validation firehose |
| automerge/automerge (6.6k) | DEAD. Rust core team consuming the batch/patch lanes. Famous CRDT |
| deepstreamIO/deepstream.io (TS 7.2k) | DEAD on Requirement 7 (latest default-branch run `failure`). 3 issues |
| webpro-nl/knip (TS 12.4k) | DEAD. A 300-commit firehose with many outside surgical PRs |

## Cached index 2: never-eyeballed residual of the 500-6000 band: 0 viable
- **What it is:** 9,171 live rows that no log, dossier or screen file names. Every topic sweep since #44 dropped them as "seen", because the dead-list was the fetched union.
- **Cut 1 (engine vocabulary minus app/AI noise):** 825 rows, of which 331 were not read by #50 (`fresh_eye_h51.txt`). All were read.
- **Screened (`screen_fresh_h51.txt`), plus log greps that found earlier verdicts recorded under short names:**

| Repo | Verdict |
|---|---|
| danielhrisca/asammdf (Py 810) | DEAD. LGPL (NOASSERTION), and the `tests` workflow ends in `failure` on master. It was a 09-23-G survivor that was never adjudicated |
| Psy-Fer/kuva (Rust 876) | WEAK. A solo 300-commit plotting catalogue, with an outside contributor filing five numeric-stability PRs |
| google/trillian (Go 3.8k) | DEAD. Maintenance mode (dependabot), govulncheck `failure`, and `rootkiller6788` visits |
| stepchowfun/typical (Rust 767) | DEAD. A schema language (language surface), solo with AI trailers, 6 issues |
| Samsung/rlottie (C++ 1.4k) | DEAD. NOASSERTION mixed licence with vendored code, no workflows, and a named format |
| remkop/picocli (Java 5.4k) | DEAD. A mature CLI framework (framework-maturity law, cliffy class) |
| nibabel, jimfs, deepdiff, style-dictionary, TypeScriptToLua, pyelftools, ag-psd | Already judged (sibling-workspace `CANDIDATES.md` and 09-23-E/F/G): size-dead at 42-81 strict eff, or claimed. TypeScriptToLua was promoted in the sibling workspace |

## Fresh sweep 1 of 2: science/engineering vocabulary over the never-eyed residual: 0 viable
- **The cut:** 397 rows not shown in cut 1 (`sweep1_sci_h51.txt`). The regex's "wind" matched "Windows", so about half of them are noise.
- **Screened (`screen_sweep1_h51.txt`):**

| Repo | Verdict |
|---|---|
| dockview/dockview (TS 3.5k, moved from mathuo) | DEAD. 69 of the last 100 commits carry Claude co-author trailers (maintainer AI sweep), and the layout-priority work is in flight |
| sirixdb/sirix (Java 1.2k) | DEAD. A solo 300-commit firehose across every lane (indexes, diffs, valid-time slices) |
| tumaer/JAXFLUIDS (Py 650) | DEAD. Relicensed GPL-3 ("gpl3" commit 2026-08-26), and it has no workflows |
| Azure/Azurite (TS 2.3k) | DEAD. `app/copilot-swe-agent` PRs are closing correctness gaps in the blob lane, and a public blob-versioning PR exists (magnet) |
| eclipsesource/jsonforms (TS 2.7k) | WEAK. A renderer framework. Core lanes are small, and the contributing guide has AI guidelines |
| openrocket (GPL), lattigo/kymatio (textbook crypto/wavelets), slatedb/arroyo/cornerstone3D (company firehoses), dicom-rs/ical4j/dnsjava (named specs) | DEAD on sight |

## Fresh sweep 2 of 2: "self-hosted product with a state machine" vocabulary (the #39 winning profile) over the never-eyed residual: 0 viable
- **The cut:** 619 rows (`sweep2_app_h51.txt`).
- **Screened (`screen_sweep2_h51.txt`, plus stdout screens):**

| Repo | Verdict |
|---|---|
| lektor/lektor (Py 3.9k, BSD-3) | WEAK/DEAD. Gate-clean: solo dairiki maintenance, CI green, 0 AI marks, no signature accounts. But the builder already records query, directory and datamodel dependencies (`db.py:1027-1041`, `db.py:1493-1512`). The open lanes are tracker magnets (#1034/#1035 model inheritance with removal, #1092 cross-alt query dependency), and #1235 "Project status" says the project is winding down. Hunt 09-30-C skipped it for the same build-state reason |
| jovandeginste/workout-tracker (Go 1.2k, MIT "except where otherwise stated") | WEAK. A solo 211-commit firehose plus Copilot commits. It is an app (templ + frontend) |
| micromdm/micromdm (Go 2.7k) | DEAD on Requirement 6. 6 commits/12mo, all docs/CI (the successor is nanomdm) |
| NuSkooler/enigma-bbs (JS 668) | DEAD. 99 of the last 100 commits carry AI co-author trailers |
| arp242/goatcounter | DEAD. Modified EUPL |
| pretix, tropy | DEAD. AGPL (NOASSERTION) |
| metricflow, config-rs, martin, opendal, rauthy, rpgp, feedparser, Openfire | company firehoses or named specs |

## Stage 6
Not run. No candidate reached a dossier.

## Tooling
- `rootkiller6788` was appended to `worktrees/_hunt/sig_accounts.txt`. The account was created 2025-07, has 829 repos, and its bio reads "Autonomous Infrastructure for self-evolving AI". It is an autonomous PR agent filing surgical fixes across Google, Apache, d3 and idaholab repos (wireit, trillian, workbox, spark, moose, ...). Treat one of its PRs in your lane like a maintainer AI sweep.

## Fallbacks
None returnable. Lektor and kuva are WEAK and should not be built without an invented, non-tracker lane that sizes above 250.

## What the next hunt should change
1. **The fetched-but-never-read residual is now read on three vocabularies** (engine, science, self-hosted product). About 7.8k never-eyed rows remain, and they match none of those vocabularies: apps, bindings, SDKs, UI kits. A fourth cut is very unlikely to pay.
2. **The star-floor WEAK rows are the cheapest remaining move.** Re-check tylax (★501) and pokerkit (★502) at the next hunt and spike only once one clears ~520.
3. **Otherwise the honest next step is to wait for drift, or to ask the human for new anchor repos or domains.** Discovery has been exhausted on every axis: band cache, residual, topics, maintainer issues, sister repos, revivals, secondary languages and the 6k+ band. A miss count of 3 should not trigger another sweep. It should trigger either a two-week pause on discovery (re-fetching the band for new 500-star crossers and fresh pushes) or human-supplied anchors.
4. Use `s_1005h51/screened_h51.txt` as the "looked at" list and `s_1005h50/dead_h50.txt` plus today's kills as the dead list.
