---
Repository: https://github.com/sfepy/sfepy
Issue: N/A
Commit: 307e51ecf3b57fc364104630e62ae1fa8ed88c55
Language: Python
Category: feature-request
Title: Add arc-length path following to quasistatic time stepping
---

# Add arc-length path following to quasistatic time stepping

Add a `ts.arc_length` time stepping solver that follows a quasistatic solution path through limit points. Today `ts.simple` and `ts.adaptive` drive the time forward only, so when the load a problem can carry peaks and falls, they stop converging or jump to another branch.

The new solver, `ArcLengthSolver` in `sfepy.solvers.ts_solvers`, treats the time as a load factor. Everything in the problem that depends on time follows it, and the time may go down as well as up. The path starts with a nonlinear solve at `t0`, which is step 0, and heads towards `t1`. Every later step moves an arc length `ds` from the last accepted point, measured as the square root of the squared norm of the change in the vector the nonlinear solver works on, plus `psi` squared times the squared change of the load factor. An attempt is accepted when the residual norm is at most `eps_a` within `i_max` corrector iterations. The first step heads towards `t1`. After that, each predictor keeps a non-negative inner product, weighted the same way, with the previous accepted change, and each corrector root is the one that keeps the change most aligned with the change it corrects.

A failed attempt multiplies `ds` by `ds_red_factor` and retries from the last accepted point, and the run stops with `'step_floor'` once `ds` falls below `ds_min`. After an accepted step that took at most `ds_inc_on_iter` corrector iterations, `ds` grows by `ds_inc_factor`, up to `ds_max`, which defaults to `ds`. When a corrected point reaches or passes `t1`, the solver solves at exactly `t1` instead and stops with `'completed'`. That last step's `ds` is the actual distance moved. A point below `t_min` or above `t_max` is not accepted and stops the run with `'out_of_range'`, and more than `max_steps` steps after step 0 stops it with `'max_steps'`.

Every accepted point, including step 0, is passed on as a new time step at its load factor, so a step hook sees it with that time. The solve status gets `path`, a list with one record per accepted point carrying `step`, `time`, `ds` and `n_iter`, where step 0 has a `ds` and `n_iter` of zero. It also gets `limit_points`, the steps whose load factor is a turning point of the path, and `termination`. The solver returns the last accepted state. Raise `ValueError` for a `ds` that is not positive or a `t1` equal to `t0`.
