---
Repository: https://github.com/sfepy/sfepy
Issue: N/A
Commit: e652fdc6114155cfe14f6dd6f60fa2d6bbaa9b86
Language: Python
Category: feature-request
Title: Add step accounting and declared termination to adaptive time stepping
---

# Add step accounting and declared termination to adaptive time stepping

Add a record of what the time stepping solvers actually did.

`ts.simple`, `ts.adaptive` and the elastodynamics solvers report `step_log`, `n_rejected` and `termination` on the solve status. The log is a sequence holding one `StepRecord` per attempt at a step, rejected attempts included, so a rejection precedes its retry and every attempt at one step shares its step index. A record carries that index as `step`, the time the attempt aimed at, the `dt` it used, its `result` of `'accept'` or `'reject'`, the controller's `emax` where there is one and `None` otherwise, and the solver's `condition` and `n_iter`. On both first order paths an attempt is rejected exactly when the nonlinear solver reports a nonzero `condition`. `ts.adaptive` retries a rejected attempt with a smaller step, so it refuses any `dt_red_factor` at or outside zero and one; `ts.simple` records the outcome and carries on. A quasistatic run's initial solve is an attempt at step 0, never retried; a run that is not quasistatic has no attempt there at all.

`termination` is `'completed'` when the run reaches the final time, `'step_floor'` when the step size falls below `dt_min` or past the reduction floor, and `'max_rejections'` when one step is rejected more times in a row than `max_rejections` allows. The count restarts at each step. Where both apply on one attempt, `'max_rejections'` is the reason given. A run that stops for either reason does so before advancing, records that attempt as a rejection, and returns the last state it accepted; one that accepted nothing returns the state it held before its first solve. A non-positive `dt_min` imposes no limit.

`StepLog` and `StepRecord` live in `sfepy.solvers.ts_solvers`. Its queries are methods: `accepted`, `rejected` and `for_step` each return a list of records, `dts` a list of the accepted step sizes, `attempts_per_step` a dictionary of counts keyed by step index, and `summary` a `Struct` whose `n_attempt`, `n_accepted` and `n_rejected` count records, `n_step` the distinct step indices they cover and `max_attempts` the most attempts one step took, each zero for an empty log. `to_arrays` converts a log into a dictionary of arrays, one per attempt, that the static `from_arrays` converts back; `truncate_from` drops the attempts at a step and after it.

On the `ts.adaptive` path no attempt aims further than the final time, and no retry is larger than the attempt it replaces, whatever `adapt_fun` sets. An elastodynamics run's first step does not pass it either. Every attempt at one step starts from the time the previous step was accepted at.

Every controller answers `get_state` with a dictionary of its adaptation state and takes it back through `set_state` as keyword arguments; one that keeps nothing between steps returns an empty dictionary. `save_restart` and `load_restart` carry that state and the log, so a resumed run continues that log and takes the same step sizes as an uninterrupted one.
