# healthchecks-lateness-ledger: feedback

Repo: healthchecks/healthchecks (BSD-3-Clause, 10.4k stars). Base 14008860208e7af95d8a4defb1094ac299902f60 (master HEAD, 2026-09-28).
Source: hunt #39 RANK 1 (Instructions/repo-hunt-logs/REPO-HUNT-2026-09-29-E.md). Factory MODE=SLICE, unattended.

## Status

SHELVED 2026-09-29 at the SLICE LOC spike (hunt-owed item b). DEAD, machinery-absorbed UNDER-FLOOR.
No tests, no meta.md, no batch. `solution.patch` here is the measured spike reference (base suite
1757/1757 green in the clean image), kept for reference only.

- Full-scope reference with the coupled accounting lever (monitored time + `uptime()`), the API v1/v2
  compatibility filter and every surface the hunt named: **194 hook human-effective** (273 raw,
  Counter 1 ~232). Of that, 25 is a generated migration and 33 is Django templates; hand-written
  Python is **136**. Target 250, floor 200: both missed.
- Hunt sketch was ~240. Item-by-item absorption table in DESIGN.md section 8.

## Unattended decisions log

- (a) #377 adjacency: cuu508 closed #377 ("Integration support for late checks", a webhook when a
  check enters grace) with "not planning to work on this ... keep Healthchecks lean and simple".
  Ruling: the lane stays on the ledger/accounting side and never notifies (late flips and late -> up
  flips are created processed; `select_channels` returns nothing for them). Conservative choice
  recorded; it did not decide the outcome.
- (b) LOC spike: done with the real kernel, not a sketch. Grew with the named coupled lever and the
  surfaces; 194 < 250 (and < 200). Reported DEAD per the orchestrator rule. No padding attempted.
- (c) Exclusivity with PRs disabled: scanned forks instead of PR diffs. 1014 forks listed, 209 pushed
  more than an hour after forking, 385 branches compared against master (added lines grepped for
  late/grace markers), 13 compare failures checked by commit log (PostHog benches, slug/cloak class
  projects, a 2020 repeat-alert branch, a 2026 full snapshot with no lateness code). No lane hit.
  GitHub code search for the lane's identifiers: 0 hits. Evidence: worktrees/healthchecks-lateness-scratch/.
- (d) SIX-CHECK: 15 feature-class issue searches (late, lateness, grace, flips, downtime, uptime,
  availability, SLA, overdue ...), maintainer comments read on #377, #1171, #915, #874, #773, #1069,
  #282, #227, #676, #1309, #1109, #1044, #451. Base == master HEAD, so no post-base commits. Functional
  check: base records nothing (probe B). Clean.
- Fallback (vega/vega) NOT attempted: the step-3 retry is offered for scope-lock gate deaths, and (b)
  says report DEAD. Its own dossier sketch (180-265, "low margin") carries the same overshoot risk
  measured here (240 sketched -> 136 Python measured).

## Reusable facts for any later healthchecks lane

- Base tests pin `alert_after == going_down_after()` in test_ping, test_sendalerts, test_update_check
  and test_update_timeout, and `test_it_creates_a_flip_when_check_goes_down` pins exactly one flip.
  Any feature that wants sendalerts to wake earlier needs its own timer column.
- `hc/settings.py` switches test settings on `sys.argv[1] == "test"`; pytest-django breaks the email
  tests. Use `manage.py test` with an xmlrunner DiscoverRunner shim for JUnit.
- Clean-room image: olympus-base-python + `requirements.txt` + `requirements-dev.txt` +
  unittest-xml-reporting 4.0.0, SQLite, 1757 tests in ~17-40 s, uid 1000, offline, deterministic.
