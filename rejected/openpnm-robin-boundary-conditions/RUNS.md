# Runs - OpenPNM Robin boundary conditions

Only local pre-filter runs were performed. No platform run was spent.

| Run | Immutable version | Result | Focused | Base | Production files / raw churn |
|---|---|---|---:|---:|---:|
| `estimate_trajectories/run_gpt-5.6-sol_1` | v2 | solve | 15/15 | 39/39 | 2 / 101 |
| `estimate_trajectories/run_gpt-5.6-sol_2` | v2 | solve | 15/15 | 37/37 | 2 / 82 |

Run 1 added 41 solver-authored test lines, which are excluded from production
scope. Its base lane consequently collected 39 instead of the canonical 37
tests. Run 2 changed production only. Both were graded after the solver exited
by applying the exact v2 `test.patch` in the isolated worktree and running the
digest-pinned image with networking disabled.

The first attempted grading command named the focused file incorrectly and ran
zero tests. It is explicitly discarded; `new-tests.log` and `base-tests.log`
contain the canonical scoreable runs.
