# REPO-HUNT-2026-09-29-E (hunt #39, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Scratch lives in `worktrees/_hunt/s_0929h39/`:
- `hi_tri1.tsv` and `hi_tri2.tsv`: triage of `band_hi.jsonl`, first by engine vocabulary, then with a junk filter.
- `hi_unjudged.tsv`: the 1,401 in-scope rows above 6000 stars that are missing from the judged set.
- `screen{1,2,3}_h39.txt`: mechanical screens from `screen_hi_h39.sh`, a copy of hunt #35's screener.
- `AGENT_BRIEF_h39.md` and `dossier_<repo>_h39.md`: seven lane audits, with their probes and raw evidence (`cp_*`, `md_probe*`, `hc_probe_lateness.py`, `rf_*`, `tw_*`, `en_*`).

## Standing inputs
- **Direction (orchestrator):** hunt #39. Keep hunting; no gate waivers (google/mangle Req 7 stays refused). Untried axes offered:
  - (1) second-lane re-mine of repos behind in-flight or CLAIMED rows;
  - (2) the band above 6000 stars;
  - (3) any other fresh axis.
- **Excluded:**
  - Every repo in flight in this factory run: Cwerg, MACS, pyOCD, pyfakefs, csbindgen, libspatialindex.
  - Every repo with a `problems/` folder (asdf-format, grmtools, hayro, ray-optics, riff and the six above).
  - Not repeated: the axes spent by #34 to #38.
- **Conflict noted:**
  - The standing worker prompt says every LEDGER repo is taken and forbids repos with a `problems/` folder.
  - The orchestrator's axis (1) names some of them. Resolution:
    - Repos with a `problems/` folder were skipped, as the worker prompt requires.
    - Ledger repos without a folder were checked on paper only (below).
- **Requirement 0 (platform picker):** cannot be checked here. OWED.
- **Softening:** misses=1 (< 2), so the 2026-09-09-B rules apply as written. No star or issue window was widened. Relaxations taken: none. The >6000-star band is a penalty band per Requirement 1, not a relaxation. Every finalist carries that penalty and it is recorded.
- **Disk:** 9.4G free at start, 9.0G at the end. No build was run by me. The subagents built only venvs and node_modules, and deleted them.

## Stage 0-bis: the proven pool
- Nothing new since hunt #37 (REPO-HUNT-2026-09-29-C). The only approvals since then are pict and macs-circular, both LEDGER rows.
- Axis (1), leftovers without a `problems/` folder:
  - **pict, teavm, piscsi, siliconcompiler, bayesopt:** already lane-audited by #37 (WEAK, WEAK, DEAD, DEAD, DEAD); verdicts unchanged.
  - **messageformat:** `rejected/messageformat-mf2-to-mf1` died on a 76.3% overlap against two older candidates, and TOO-EASY records the other converter directions as the same reverse-converter magnet. DEAD.
  - **oxipng:** `rejected/oxipng-apng-frame-optimization` died against two older submissions, and the repo is mined by other authors. DEAD.
- **Result:** the pool yields nothing this cycle.

## Cached index: the band above 6000 stars (the genuinely under-judged slice)
- `band_hi.jsonl` holds 3,381 in-scope rows. Only 1,029 of them appear in the judged set (`judged_h36.txt`).
- By contrast, 19,640 of 21,830 rows in the 500-6000 band are judged. So the high band is the least-read part of the cache.
- Earlier eye passes (09-16-B, 09-23-P) read only engine-keyword slices of it.
- I read all 1,401 unjudged rows that survived an AI/app junk filter, by eye, by language:
  - Nearly all are famous infrastructure, frameworks, SDKs, apps or spec implementations. The kill list's ">5000 with a famous spec" rule holds.
  - The rows with a real domain model were screened mechanically in three batches (37 repos).
- **Killed at the screen, reasons:**
  - **Maintainer firehose / capability-consuming:**
    - gb-studio: chrismaltby ships arrays, RPN codegen and rom usage weekly. The cold sound lane is a GBDK vgm2data port.
    - gridstack.js, quicktype (schani's dozens-per-day fix sweep across renderers), Turf (plus `dylanpulver`), hurl, OpenCC, librosa (bmcfee plus copilot), apache/casbin (17 copilot-swe-agent PRs).
  - **Signature accounts:**
    - yq: `arbelonson-source`, `CAOShurong`, `jakezwang`.
    - beets: `CAOShurong`.
    - manim: `dylanpulver`, `SAY-5`.
    - infinigen: `SAY-5`.
    - alertmanager: `MaxFreedomPollard`, plus 73 open PRs.
    - draco: `carrerasdarren-cell`.
    - vavr: `jakezwang`.
  - **Corpse or dormant:** grex, motion-canvas, nunjucks, featuretools, Surprise, go-datastructures, gopher-lua, annoy, obsidian-dataview (0 commits in 12 months, red CI, successor `datacore` is author-owned).
  - **Other:**
    - javascript-obfuscator: CLAUDE.md, a July "Fixed ..." sweep over every transform, and a commercial Pro tier that reserves the deep lanes.
    - zotero-better-bibtex: tests need a Zotero binary.
    - Valetudo: locked tracker, no outside PRs.
    - JoltPhysics: already killed 09-23-E.

## Lane audits: 7 repos by parallel subagent (brief `AGENT_BRIEF_h39.md`, gates 0-9 plus the Stage 6 guard)

| Repo | Stars | Verdict | Best lane / killer |
|---|---|---|---|
| **healthchecks/healthchecks** | 10370 | **VIABLE, RANK 1** | Lateness ledger. Dossier below |
| **vega/vega** | 12003 | VIABLE (low margin), fallback 1 | Keyed dataset reconciliation across the five whole-dataset replacement paths (180-265 eff, 5-6 packages). Walls:<br>- `ChangeSet.js:84-85` add/remove cancel (F-47);<br>- Relay never deletes a field (`Relay.js:46-47`, F-39);<br>- Collect/SortedList keeps retained tuples in their old slots (identity vs order);<br>- Load's own `op.value` holder bites on the second reload (F-58).<br>Risks:<br>- v2.6.5 had an `upsert` trigger, which is partial prior art (removal-rule adjacency);<br>- React/D3 keyed reconciliation is outsider-nameable (MEDIUM);<br>- stay far from #641 (animated transitions);<br>- Docker needs node 24 plus node-canvas. |
| **mandiant/capa** | 6206 | VIABLE, fallback 2 | Process-tree dynamic scope (~250 eff, 4 subsystems). Walls:<br>- per-process features discarded (`dynamic.py:268`);<br>- process matches never indexed (`:260`);<br>- ancestor re-match vs minimal-subtree reporting, which surfaces as a `from_capa` KeyError;<br>- layout drops processes without call matches (`loader.py:727`, `verbose.py:96` crash).<br>**Requirement 7 caveat:** the `CI` workflow on master concluded `failure` on every 2026-09-08 push. Only the licensed Binary Ninja jobs fail; the 12 core test jobs, Ghidra and IDA are green. Base must come from the green 2026-08-28 push, or the human rules on it.<br>The test data submodule holds malware samples, so base mode must be scoped to data-free tests. |
| markdoc/markdoc | 8491 | WEAK | Partial-scope static model (specializer plus partial-aware validation, ~300). The specializer half is the same feature class as our accepted featurevisor-target-specialization and is a standalone post-pass on its own. The validation half alone is ~160 and sits in the maintainers' live validator lane. |
| skypjack/entt | 13153 | DEAD | A solo maintainer made 792 of the last 800 commits. The TODO roadmap claims entity io, the groups replacement, the organizer rework and the scheduler; meta is live on a `wip` branch. The cold lanes were all under 150 eff: flow provenance (a post-pass) and cross-type dispatcher order (single-subsystem). Continuous-loader remapping hits a removal record plus snapshot/clone magnets. |
| robotframework/robotframework | 11918 | DEAD | The best seam was an unused-import ledger (discarded duplicate import sites): magnet #1936 (2015, high priority), closed PR #2026, and Robocop IMP05/IMP06 ship it. Rebot merge history is ~175 and single-subsystem. Listener replay was declined in #5065. The v8.0 roadmap covers namespace/visibility. One signature account (`Sanjays2402`, out of lane). |
| GothenburgBitFactory/taskwarrior | 6089 | DEAD | Selective undo: ~180, and TaskChampion #427 publishes the inverse-operation design in an external crate. Calendar durations: #3826 has a published design. Recurrence, rules, DOM and workweek have RFC docs. Dependency lanes are ashprice's live work. Time tracking was removed on philosophy grounds. Docker is heavy: CMake + Rust >= 1.94.1 + 331 crates. |

## RANK 1 dossier: healthchecks/healthchecks, lateness ledger
Full dossier: `worktrees/_hunt/s_0929h39/dossier_healthchecks_h39.md`. Probe: `hc_probe_lateness.py`. Clone: `worktrees/hc-h39` (shallow, HEAD `14008860208e7af95d8a4defb1094ac299902f60`, 2026-09-28, clean).

### Repo facts
- **URL / stars:** https://github.com/healthchecks/healthchecks, ★10370. This is the 5000+ penalty band; there is no famous spec, and the capability is repo-internal.
- **Language:** Python 66% (Django 6.1). The rest is templates, Less and vendored JS.
- **Dependencies:** pycurl ships a manylinux wheel, so no system libcurl is needed.
- **License:** BSD-3-Clause (LICENSE read). Vendored JS is MIT or Apache; DOMPurify is Apache-2.0 OR MPL-2.0, so take Apache.
- **Activity and CI:** 512 commits in 12 months (507 by cuu508). Tests, Mypy, Coverage and CodeQL are green on master (09-02, 09-19, 09-28).
- **Open issues:** 54, mostly integration requests.
- **Pull requests are disabled** on the repo because of AI-generated spam (CONTRIBUTING.md). So there is no public PR-diff surface, and no competitor PR stream to profile.
- **Tests:** Django TestCase through the public model, views and management commands, plus time-machine.
  - `manage.py test hc.api hc.front hc.accounts --parallel 1` gave 1026 OK, identical across 3 runs, ~8.6 s.
  - `requirements-dev.txt` is required, or 2 modules fail to import.
- **Docker:** Pattern B, olympus-base-python (3.12.13), SQLite, offline. Easy.
- **Quota / self-collision:** 0 subs; no `approved-problems/`, `problems/` or `rejected/` entry. The nearest feature class in our corpus is none. There is no scheduler/monitoring pick.

### The lane
- **Capability:** a check that is up and passes its schedule-derived grace start gets a late transition, recorded as a flip at exactly that time. It is never notified.
- **How the late interval closes:**
  - late -> up on a success ping (not notified);
  - late -> down on a fail ping or grace expiry (notified as today, `old_status` "late");
  - pause, resume and schedule edits end it.
- **Reporting:** late time and late counts per period go next to downtime, using the same flip replay, in the details page, the monthly/weekly/daily reports and the Get Flips API.
- **Unchanged:** `status`, `get_status` and badges.
- **Files:**
  - `hc/api/models.py`: `Check.ping`, `get_grace_start`, `going_down_after`, Flip semantics, `downtimes_by_boundary` and the downtime recorder;
  - `hc/api/management/commands/sendalerts.py`;
  - `hc/api/views.py` and `hc/front/views.py` (pause/resume/schedule update exist in both);
  - report and details templates.

### Missing machinery
- Lateness is only ever computed: `get_status` returns "grace", and the badge maps use it.
- Nothing persists it. `STATUSES` is up/down/new/paused.
- Pings are pruned at `ping_log_limit`, so lateness can never be rebuilt afterwards (F-47 class).

**Algorithm the repo lacks:** a second pending timer (schedule-only grace start next to going-down), plus a four-kind segment replay seeded from a persisted marker.

### Effort sketch (~240 eff, per decision point)

| Decision point | Eff-LOC |
|---|---|
| Late marker plus clearing it at 8 reset sites | 25 |
| Wake time as a min over two pending events, at 5 `alert_after` sites | 20 |
| sendalerts records late at the exact grace start | 30 |
| `ping()` records the interval when the worker has not fired yet | 25 |
| Flip semantics (`select_channels` raises on an unknown status at `models.py:1404`; `to_dict` `up`; `down_duration`) | 20 |
| Replay with 4 segment kinds, seeded from the marker, with a monitored-time denominator | 60 |
| Surfaces | 60 |

This is in the 150-250 band. The coupled second lever is the accounting replay (late plus monitored time), not padding.

### Trap seams

| Pattern | Present | Evidence |
|---|---|---|
| F-14 declared vs derived state | yes | Persisting `status="late"` (the obvious copy of the down path) makes `get_grace_start` and `going_down_after` return None, because both branch on `status == "up"` (`models.py:309` ff., 355 ff.). The check then never goes down. Probe C reproduced it. The failing test says "never went down", not "don't persist" |
| F-15 arming vs firing (two timers) | yes | After `/start` at 12:10, `get_grace_start()` = 12:10 while `with_started=False` = 13:00, and `alert_after` = 12:40 (probe D). Lateness must use the schedule-only start while going-down keeps the started-run path (`models.py:334`). `alert_after` becomes a min of two events at `models.py:541`, `api/views.py:398`, `front/views.py:636` and `sendalerts.py:155` |
| F-9 / F-41 two holders of "was late" | yes | The worker sets the marker, but a ping that arrives during grace before the worker fires must still record the interval. sendalerts builds its Flip by hand (`sendalerts.py:170-171`), bypassing `create_flip` |
| F-10 cross-product | yes | Replay seed reads `self.status` (`models.py:634`), so an ongoing late segment is invisible unless seeded from the marker, which couples to F-14. Cells: {simple, cron, oncalendar} x {started, idle} x {worker-first, ping-first} x {paused, manual_resume} |
| F-31-style twin sites | yes | Pause/resume are duplicated in `api/views.py:547-592` and `front/views.py:820-865`. The schedule edit creates a down flip at now() in front (`front/views.py:638-652`) but not in the API (`api/views.py:398`) |
| F-1, F-2, F-3, F-4, F-5, F-8, F-13 | no | Not a pipeline, parser or famous spec |

Pairwise interdependence:
- F-14 with F-10, through the replay seed.
- F-15 with F-9, through `alert_after`.
- F-9 with F-14, through the marker.

### Other gates
- **Capability-lane density (Stage 2c):** late/grace appear in 2 of 512 commit subjects, neither a feature. sendalerts had 5 maintenance commits in 12 months. No branch families, no AI-sweep marks, no roadmap.
- **Maintainer-welcomed lanes (Stage 2d):** none found.
- **Philosophy (YELLOW):**
  - #377 "Integration support for late checks" was closed by cuu508 on 2025-11-19: "not planning to work on this ... keep Healthchecks lean and simple ... too niche". It declines late *notifications*. The lane must never notify on lateness, and meta.md must say so.
  - #282 ("the meaning of late is murkier" with /start) supports stating T2's rule.
  - #268 declines concurrent runs, and #923/#1346/#279/#367 decline other ideas; none is this lane.
- **Magnet / derivative:** no issue asks for lateness history. The outsider sentence needs repo nouns ("record grace entries as flips and account late time in the downtime replay"). MEDIUM-LOW, weighted up by the star band.
  - Do not touch the true magnets: #910 (start-signal grace) and #451 (snooze, scouted by `kelbic`, a one-follower account created 2026-04 that quoted models.py; a NOTE, out of lane).
- **Removal / port / sibling:** no removal record, not a port, no previous major version with it, no sibling to crib from. Schedule parsing lives in the author-owned `cronsim`/`oncalendar`, which the lane does not need to touch.

### Stage 6 death-class guard (run by me on RANK 1): PASS, with flagged risks
1. **One shared kernel feeding several surfaces?** Yes. The late marker plus the two-timer wake feeds `ping()`, sendalerts, pause/resume/edit in both view modules, the replay and the reports/API.
2. **Interdependent traps?** Yes, pairwise as above. The obvious single-point fix for T1 (persist status) breaks going-down. The obvious fix for T2 (reuse `alert_after`) makes every `/start` an instant late interval or stops stuck runs from going down. The fix for T3 (derive from pings) double-records worker-recorded intervals.
3. **Standalone new file with minimal wiring?** No. The status machine, the worker and both view modules need edits. A post-pass over pings cannot work because pings are pruned.
4. **TOO-EASY Pre-Pick Guard 1-5:**
   - #1: not one rule at N sites; there is a second mechanism (the timer and the replay).
   - #2: not single-subsystem; it spans web, worker and reporting.
   - #3: T1/T2 walls survive a meta that states "status and badges unchanged; a run in progress is not late; the late timestamp is the grace start".
   - #4: not a port.
   - #5: survives full spelling.
- **Flagged risks:**
  - LOC margin is ~240; spike the replay kernel early.
  - The ir-sim lesson: lifecycle paths killed 0/11 once named. Here the difficulty must sit in T1/T2/T3, whose fixes hide in code the prompt cannot name, not in the reset sites.
  - There is unmeasurable platform saturation at 10k stars.

### Best Olympus feature types (for the builder)
1. The lateness ledger as above (primary).
2. A coupled lever if LOC runs short: a monitored-time denominator in the replay, so paused and new time are excluded from availability per period. It uses the same kernel, and it fixes the week/day NB note at `models.py:162`.

- **Estimated complexity:** 220-280 eff across 5-7 files in 3 subsystems (models/worker/views plus reports).
- **Why it matches:** a stateful domain model (the pyfakefs/piscsi/bayesopt shape that has been accepted repeatedly). The capability is defined by healthchecks' own nouns (flips, grace, alert_after, downtime replay). There is no public PR surface, the tracker never names it, and the solo maintainer is in maintenance mode on this code.
- **Risks carried forward:**
  - Requirement 0 picker;
  - #377 adjacency;
  - the LOC margin;
  - the star band;
  - a fork-branch scan over the 1014 forks was not done;
  - re-run the six-check at submit.

## Fallbacks
1. **vega/vega, keyed dataset reconciliation** (dossier_vega_h39.md). Stronger cross-package span (5-6 packages). Before authoring:
   - judge whether the v2 `upsert` trigger counts as removal-rule prior art; the whole-replacement reconciliation is different, but the match-then-modify core overlaps;
   - keep D2/D3/D5 or the lane falls under 200.
2. **mandiant/capa, process-tree dynamic scope** (dossier_capa_h39.md). The Requirement 7 conclusion on master is `failure` (Binary Ninja jobs only), so the human must rule on it or the base must come from the green 08-28 push. The span-of-calls PR #2532 is a public template for the plumbing.

## Clones and scratch
- **Kept:**
  - `worktrees/hc-h39` (23M, RANK 1);
  - `worktrees/vega-h39-vg` (110M, no node_modules);
  - `worktrees/capa-h39-cp` (53M, submodules not fetched);
  - `worktrees/markdoc-h39-md` (1.5M).
- **Deleted:** entt, robotframework and taskwarrior clones, and the gb-studio clone. No build output remains.

## What the next hunt should change
- The >6000-star band now has its 1,401 unjudged rows read by eye. Seven of them were lane-audited, and three were VIABLE. That is a better hit rate than any metadata axis since 09-23.
- **The winning profile:** a mature, solo- or small-team-maintained product with a stateful domain model, low PR traffic (or PRs disabled), and a tracker full of integration asks. The core model sits in maintenance.
- **Suggested next axis:** the same profile in the 500-6000 band's judged-but-never-lane-audited rows, selecting on "self-hosted app/tool with a state machine" rather than "engine" vocabulary. Earlier triage filtered with engine words, so these were read and dropped as apps.

## Result: CANDIDATE, healthchecks/healthchecks, lateness ledger
