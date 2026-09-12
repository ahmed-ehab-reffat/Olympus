# eval-results - mtail-user-functions

## Batch history

No agent batch has been run yet. The table below is the template; fill one row per run, and save
each passing agent's diff to `agent-runs/<batch>-<run>.patch` while the platform run view is open
(the differential harness and trap-proof both need the actual patches later).

| Batch | Agent | Verdict | Msgs | LOC | Files | Failed test names | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| - | - | - | - | - | - | - | - | - |

## Local validation (2026-07-28)

Run in the submission image (`olympus-base-go`), offline (`--network none`), as uid 1000.

| Mode | Patches applied | Exit | Test cases | Failures |
|---|---|---|---|---|
| base | test only | 0 | 639 | 0 |
| new | test only | 1 | 97 | **97** |
| base | test + solution | 0 | 639 | 0 |
| new | test + solution | 0 | 97 | 0 |

- Both apply orders (test then solution, solution then test) apply cleanly.
- 3 consecutive runs of both modes produced identical counts.
- Vanilla repo (no patches) `go test ./...`: 21 packages ok, 0 failures, 3x identical offline.

## Predicted difficulty

10-25%. The reachable parts are the grammar, the frame plumbing and the type unification. The
predicted killers, in order:

1. Capture-group and matched-flag isolation across a call (`thread.matches` is keyed by the global
   regex index, so a callee matching the *same* pattern silently overwrites the caller's groups).
2. The timestamp register having to survive the same call that isolates match state - the natural
   fix for (1) breaks this.
3. Nested and expression-position calls, where stack discipline breaks first.
4. Monomorphic typing: the repo's own builtin path calls `types.FreshType`, which is the wrong
   policy for user functions and passes every single-call-site test.
5. `unparser.go` and `sexp.go` panic on unknown nodes, so the repo's own `mfmt` and `--dump_ast`
   crash unless the solver extends them.

## Watch items for the first batch

- If a passer implements calls by inlining the body at the AST level, check whether the recursion
  and depth-limit tests are what stopped it; that is the architecture-jump guard doing its job.
- If several agents fail on the same *single* assertion, check it is not an unfair pin before
  hardening anything (the mixed int/float call-site case was already dropped for this reason).

## Batch 1 (2026-07-28) - 0 of 7, UNSOLVABLE

| Run | Solver | Verdict | Msgs | Files | LOC | Failure cause |
|---|---|---|---|---|---|---|
| 1 | Nova | Missed Requirement | 145 | 18 | 846 | float zero for locals and fall-through results (95 of 97 passed) |
| 2 | Nova | Missed Requirement | 123 | 18 | 813 | undefined-function call crashes the checker; verifier also failed to merge test.patch |
| 3 | Nova | Missed Requirement | 141 | 18 | 670 | boolean call as condition; float zero values |
| 4 | Nova | Missed Requirement | 123 | 16 | 726 | undefined-function call crashes the checker |
| 5 | Orion | Missed Requirement | 179 | 19 | 1257 | rejects Int to String and Int to Float promotion at call and return boundaries |
| 6 | Nova | Missed Requirement | 178 | 19 | 899 | rejects coercive inference; boolean call as condition |
| 7 | Nova | Missed Requirement | 93 | 18 | 730 | boolean call as condition; contextually inferred float zeros treated as Int |

Median 141 messages, 18 files, 813 LOC. Long-horizon metrics are comfortably clear; the problem is
solvability, not scope.

### Cause tally

| Cause | Runs | Documented at batch time? |
|---|---|---|
| boolean call used as a condition | 3, 6, 7 | NO - never stated |
| float (and contextually inferred float) zero values | 1, 3, 7 | NO - enumeration removed the round before |
| coercive unification at call/return boundaries | 5, 6 | NO - sentence removed the round before |
| undefined-function call must be a compile error, not a crash | 1, 2, 4 | YES - fair |
