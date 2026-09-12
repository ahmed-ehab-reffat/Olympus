# LEVELS - go-astisub merge collisions

Target band: 1-5 solves in 10. Long-horizon target: successful median at least
2 production files, 20 platform-reported messages, and 200 effective LOC.

| Level | Behavioral lever | Tests | Reference files / LOC | Solver median | Platform | Verdict |
|---|---|---:|---:|---|---|---|
| L1 | Complete collision namespace, ownership, closure, determinism, compatibility | 7 focused entities | 2 files / 182 added LOC | 14.5 messages / 169 effective LOC | abandoned 4/4 all-pass version; revised 0/10 | correct but too easy |

Any artifact change after calibration begins creates a new immutable level and
restarts at 0/10.

Terminal verdict: archived too easy on 2026-08-01. No further level is planned.
