# Levels and calibration history

No completed run counts toward the current immutable candidate. Every artifact
revision restarted calibration at 0/10; stored runs are trajectory evidence
only.

| Version | Outcome | Calibration |
|---|---|---:|
| 29 | 0/7 `agent-runs8`; retiring-writer release ownership dominated | abandoned |
| 30 | release protocol removed and prompt made outcome-only | 0/10 |
| 31 | hidden lock removed; exact source review passed, Docker blocked | 0/10 |
| 32 | status-triggered direct handoffs and BLE-first offline replay added; exact review passes, Docker blocked | 0/10 |
| 33 | BLE post-neutral output strengthened from fixture inequality to all-zero semantics; exact review passes, Docker blocked | 0/10 |
| 34 | “Add” feature-request framing and exact Plover interface assumptions made public; exact review passes, Docker blocked | 0/10 |
| 35 | absent-lock prerequisite removed; lock-free offline reference/pristine matrices pass exact review, Docker blocked | 0/10 |
| 36 | three release-only regressions superseded by the public no-release contract retired; run-10 replay yields two legitimate passes and three independent failures | 0/10 |
| 37 | fixed-yield stale sampling replaced by writer-progress observation; run-11 yields two clear legitimate passes, one evaluator-label ambiguity, and two independent failures | 0/10 |
| 38 | blocked-send old-route output observed directly; verifier owns and runs all three legacy contract updates; reference steno CCCD integration repaired | 0/10 |
| 39 | hidden verifier moved out of participant-owned files; run 13 produced three legitimate passes and two independent BLE failures with no environment blockers | abandoned at 3/5 |
| 40 | adds activation-aware blocked-send ABA coverage and a fresh offline async-send branch; all exact gates pass | 0/10; retrospective run-13 replay is 1/5 |
| 41 | removes the run-14 private-state verifier dependency, expands offline awaited sends to every family, and mirrors capacity-three stale disposal on old USB | 0/10 |
| 42 | composes fresh disconnected awaited sends with BLE as the first active host and exact all-family GATT replay | 0/10 |

The five run-12 reports remain environment-blocked evidence and do not count.
Run 13 is the first valid version-39 calibration evidence: Nova 1–3 solve, while
Nova 4 and Nova 5 fail distinct BLE writer/GATT requirements. Version 40 is a
new immutable problem version, so those runs are not calibration for it. Their
retrospective replay is useful difficulty evidence only: Nova 1 passes 12/12;
Nova 2 and Nova 3 fail the activation-aware blocked-send test; Nova 4 fails two
focused tests; and Nova 5 fails three. Version-40 calibration is 0/10.

Run 14 cannot count as calibration because Nova 1 hit a verifier compile
mismatch against its legitimate private state representation. After correction,
exact version-41 replay has Nova 1 and Nova 3 at 13/13, while Nova 2 compiles
and scores 10/13. These are trajectory/replay evidence. Version 41 starts a
fresh 0/10 batch; no cold solver was run.

Run 15 belongs to immutable version 41: Nova 2--5 solve it, while Nova 1 fails
four real writer/replay boundaries. Version 42 changes `test.patch`, so none of
those runs counts toward its calibration. Their patches are replay evidence;
Nova 2 passes the exact version-42 matrix and Nova 3--5 pass the changed BLE
phase. Version 42 starts at 0/10, with no cold solver run.
