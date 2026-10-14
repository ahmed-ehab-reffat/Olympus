# DESIGN.md - healthchecks-lateness-ledger (SHELVED at the SLICE LOC spike)

Repo healthchecks/healthchecks, base 14008860208e7af95d8a4defb1094ac299902f60 (master HEAD 2026-09-28).
Verdict: DEAD, machinery-absorbed UNDER-FLOOR. The full-scope reference, with the coupled accounting
lever and every surface the hunt named, measures 194 hook human-effective (136 in hand-written Python,
the rest a generated migration and Django templates). The gates below all passed; size did not.

## 1. Title
Record late intervals in the flip history and downtime reports

## 2. Shape
O-Composite-add: a new recorded state carried through the status machine (`Check.ping`), the worker
(`sendalerts`), both view modules (API + web UI edits, pause, resume, clear events), the flip replay
(`downtimes_by_boundary`) and its surfaces (details page, email reports, Get Flips API).

## 3. Public API surface (as spiked)
- `Flip.new_status` / `old_status` may be `"late"`; flips into late and late -> up are created processed.
- `Check.late_after` (worker timer, schedule-only grace start) and `Check.late_since` (open interval start).
- `Check.going_late_after()`, `Check.record_late(when)`, `Check.end_late_if_rescheduled()`.
- `sendalerts.Command.handle_going_late()`, called first by `handle_going_down()`.
- `DowntimeRecord.late_count`, `.late_duration`, `.monitored`, `.uptime()`.
- Get Flips v3 dicts gain `late`; v1/v2 hide late flips and late -> up flips.

## 4. Canonical rules (the contract the tests would have pinned)
- The late moment is `get_grace_start(with_started=False)`: a start signal neither brings it forward
  nor pushes it back.
- The late flip's timestamp is exactly that moment, whether sendalerts or the next ping records it.
- A late interval ends with the next flip: success -> up (processed, never notified), failure or grace
  expiry -> down (notified as today, old_status "late"), pause -> paused, an edit that moves the grace
  start into the future -> up at the time of the edit.
- `late_count` counts intervals that BEGIN in a period (not segments); `late_duration` splits at
  boundaries; an open interval counts up to now.

## 5-6. Description draft
Not written: the pick died before the description stage.

## 7. File footprint (MEASURED on the spike, not sketched)
| File | raw | hook human-eff |
|---|---|---|
| hc/api/models.py | 118 | 82 |
| hc/api/management/commands/sendalerts.py | 50 | 21 |
| hc/api/views.py | 14 | 13 |
| hc/front/views.py | 15 | 15 |
| hc/accounts/models.py | 5 | 5 |
| hc/api/migrations/0124_check_late_after_late_since.py (generated) | 38 | 25 |
| templates (details_downtimes, report text/html/summary) | 33 | 33 |
| **Total** | **273** | **194** |

Hand-written Python: 136. Counter 1 (raw - blank - comment): ~232. The hunt sketched ~240 human-eff.

## 8. Why the sketch overshot (absorption, item by item)
| Hunt line item | Sketched | Measured | Absorbed by |
|---|---|---|---|
| late marker + clear at 8 reset sites | 25 | ~8 | `create_flip` is the one chokepoint every pause/edit/ping flip goes through |
| wake time = min over 2 events at 5 sites | 20 | ~12 | a second nullable timer column plus one worker method; min() is impossible anyway (below) |
| sendalerts records late at grace start | 30 | ~21 | the existing handle_going_down guard/update pattern |
| ping records the interval ping-first | 25 | ~6 | `get_grace_start(with_started=False)` already exists |
| flip semantics (select_channels, to_dict, down_duration) | 20 | ~8 | down_duration needs no change |
| replay: 4 kinds + marker seed + monitored denominator | 60 | ~25 | the replay loop already walks every segment |
| surfaces | 60 | ~45 | templates only; no view logic needed |

## 9-10. Test outline / forced bounds
Not reached. Harness notes for any later healthchecks lane: tests must run under `manage.py test`
(settings key test overrides off `sys.argv[1] == "test"`, so pytest-django breaks email tests); JUnit
via unittest-xml-reporting with a runtime DiscoverRunner shim; `time_machine` for a fixed clock.

## 11. Trap matrix (reproduced, still valid for a bigger lane on the same kernel)
| # | Trap | F-id | Evidence on base |
|---|---|---|---|
| 1 | Reusing `alert_after` as the wake timer | F-12 / S3 | 4 base tests pin `alert_after == going_down_after()` (test_ping, test_sendalerts, test_update_check, test_update_timeout); a second timer is forced |
| 2 | Recording late when marking down | F-12 | `test_it_creates_a_flip_when_check_goes_down` pins exactly ONE flip; backfilling a late flip at down time breaks it |
| 3 | Persisting `status="late"` | F-14 | `get_grace_start` branches on `status == "up"` (models.py:309 ff.): the check never goes down (probe C) |
| 4 | `with_started` default | F-15 | after `/start` at 12:10 the default grace start is 12:10, schedule-only is 13:00 (probe D) |
| 5 | sendalerts builds its down Flip by hand | F-9 | sendalerts.py:170-173 bypasses `create_flip`, so old_status "late" logic placed there misses the timeout path |
| 6 | Unprocessed late flip | A4 | `Flip.select_channels` raises NotImplementedError on an unknown new_status (models.py:1403) |
| 7 | Web UI edit-to-down test | F-20 | `update_timeout` flips down when `alert_after < now()`; a min-of-timers alert_after flips a merely late check down |
| 8 | Replay seed | F-10 | `downtimes_by_boundary` seeds from `self.status` (models.py:634); an open interval is invisible |

## 12-13. Tier / prediction
Olympus. Predicted 20-35% on traps 3-8, but the pick cannot clear the 200 human floor honestly.

## 14. Gates (all run, all passed except size)
- Gate 1: base records nothing (probe B), reproduced in Docker.
- Gate 5: sendalerts 5 maintenance commits in 12 months; nobody building the capability.
- Gate 6: probes B/C/D reproduced on base in the clean image.
- Gate 7b / exclusivity: PRs disabled (REST 404). Fork scan: 1014 forks, 209 pushed after forking,
  385 branch compares plus 13 by commit log; no lateness code anywhere. GitHub code search for
  `late_since`, `record_late`, `late_count` + `downtimes_by_boundary`: 0 hits.
- Gate 8 / SIX-CHECK: #377 declines late NOTIFICATIONS only ("keep Healthchecks lean"); the lane never
  notifies. #1171 declines per-level notifications. #874/#773 show the maintainer added uptime to the
  same replay. No issue asks for lateness history. Base == HEAD, so no post-base commits.
- Gate 4 / hunt-owed (b): FAILED, 194 < 250 target and < 200 floor (see section 7).
