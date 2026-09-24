---
Repository: https://github.com/reinterpretcat/vrp
Issue: N/A
Commit: e49bee0eccb9d732d0e020d7f9bbbb378e2de2bc
Language: Rust
Category: feature-request
Title: Add vicinity clustering support to pragmatic initial solutions
---

# Add vicinity clustering support to pragmatic initial solutions

Add support for initial solutions to pragmatic problems that use vicinity clustering (`plan.clustering`). Right now the initial solution reader refuses any solution the solver wrote for such a problem ("commute property in initial solution is not supported"), and an initial solution without clustered stops is accepted, but the solver then never forms clusters from it, so the result comes back with every job in its own stop.

`read_init_solution` has to read every solution `write_pragmatic` writes for the same problem, including stops with parking and activities with commute, as the solution that was written: passing what it returns straight back to `write_pragmatic`, without solving, reproduces the original output. This holds for vehicles with and without a shift end.

When the problem is clustered, an initial solution given to the solver (through `with_init_solutions` on the solver configuration, which is also what the CLI's `--init-solution` uses) is taken in terms of the clusters the solver builds, and those clusters are exactly the ones it builds when no initial solution is given. A cluster whose jobs one tour of the initial solution serves one after another, in any order and with no other job in between, is served at that place in the tour as that cluster, visiting its jobs the way the cluster does. A cluster whose jobs are not served like that (spread over tours, interrupted by another job, or with any of its jobs unassigned) starts out unassigned in that initial solution, and all of its jobs are taken out of the tours that served them. Jobs that belong to no cluster keep their place.

So with no generations to run and no other initial solutions (`max_generations` 0 and an initial size of 1), solving from a solution the solver wrote for the problem writes that same solution back, and solving from an unclustered solution writes the clustered stops these rules give.
