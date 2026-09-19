# eval-results.md — ir-sim-scenario-events

## Batch 1 (2026-09-19) — 10 Nova + 1 Vega, suite of 88 tests: 0/11 pass

Saved runs: `agent-runs/1/*` (eval-result.json, junit, solution-patch, trajectory).

| Run | Agent | Verdict | New tests | +lines | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|
| Nova #10 | Nova | fail | 86/88 | 707 | group_behavior_moves, lidar_sees_spawned | spawned group-behavior robot left in default group 0; sensors refreshed right after spawn | EventManager + mutation refresh incl. sensor step |
| Nova #9 | Nova | fail | 85/88 | 747 | group_behavior_moves, lidar_sees_spawned, reset_removes_..._in_place | + restore order | |
| Nova #8 | Nova | fail | 86/88 | 757 | group_behavior_moves, lidar_sees_spawned | as above | |
| Nova #7 | Nova | fail | 86/88 | 686 | group_behavior_moves, lidar_sees_spawned | as above | |
| Nova #6 | Nova | fail | 85/88 | 797 | enter_and_leave_crossings, group_behavior_moves, lidar_sees_spawned | + region crossing | |
| Nova #5 | Nova | fail | 85/88 | 819 | enter_and_leave_crossings, group_behavior_moves, lidar_sees_spawned | + region crossing | |
| Nova #4 | Nova | fail | 85/88 | 700 | group_behavior_moves, lidar_sees_spawned, reset_removes_..._in_place | + restore order | |
| Nova #3 | Nova | fail | 87/88 | 716 | lidar_sees_spawned | only the (unfair) sensor-timing pin | rebuilds groups from objects, spawn gets its own group |
| Nova #2 | Nova | fail | 86/88 | 689 | group_behavior_moves, lidar_sees_spawned | as above | |
| Nova #1 | Nova | fail | 86/88 | 698 | group_behavior_moves, lidar_sees_spawned | as above | |
| Vega #1 | Vega | fail | 86/88 | 970 | group_behavior_moves, lidar_sees_spawned | as above | |

Kill counts: lidar_sees_spawned 11, group_behavior_moves 10, reset in place 2, enter/leave crossings 2.

## Local replay after round-5 test changes (L68 predictor of re-eval)

`worktrees/_probe/irsim_replay.sh agent-runs/1` against the 90-test suite: **1/11** (Nova #3 passes 90/90;
10 fail `test_spawned_robot_with_group_behavior_moves`, 2 also reset-in-place, 2 also enter/leave crossings).

## Batch 2 = re-eval of batch 1 (2026-09-19), 90 tests: **1/11 — ACCEPTED**

Same 11 solutions (prompt-token fingerprints identical to batch 1). Nova #3 passes 90/90; every other run
fails `test_spawned_robot_with_group_behavior_moves` (F-41), plus reset-in-place for Nova #9/#4 (F-42)
and enter/leave crossings for Nova #6/#5 (1e-12 epsilon, L75). 87 of 90 tests killed nothing. Exactly
the local replay's prediction. FP panel: the pass upheld (judge #2 dissent on created-but-unadded ids,
ruled unfair by the adjudicator). Auto Review: Approved (description 3/3, tests 2/3, solution 3/3).
