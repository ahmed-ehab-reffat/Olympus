# eval-results.md - starlark-go-generators

Repo: google/starlark-go - BASE_COMMIT 5395d018f003e2a08bfbca6dcb2562acee700f62 - Language: Go

## Local validation matrix (Docker, --network none, --user 1000:1000, image built from a fresh
`git archive BASE` + the deliverable Dockerfile)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (exit 0, 83 testcases, 0 failures) | FAIL (exit 1, 91 testcases, 91 failures) |
| BASE + test.patch + solution.patch | PASS (exit 0, 83 testcases, 0 failures) | PASS (exit 0, 91 testcases, 0 failures) |

F2P: 91 identical (classname, name) node ids across the base-fail and solution-pass runs, verified by
parsing both JUnit files. On base the test package cannot compile (the `Generators` option does not
exist), so `test.sh` synthesizes one named failing node per test node rather than emitting an empty
report.

P2P: the repository's own suite runs in base mode in both states (`go list ./...` minus the new test
package): 83 testcases, 0 failures.

## Determinism

| Check | Runs | Result |
| ----- | ---- | ------ |
| `test.sh new` on the solution state | 3 | 91/0 every run |
| `test.sh base` on the solution state | 3 | 83/0 every run, exit 0 |
| Vanilla tree `go build ./... && go test ./...` offline, non-root | 1 | all packages ok |

No clock, network, randomness, parallelism or map-ordering dependence in the new tests; every assertion
compares a Starlark value's `String()` or checks that an error occurred.

## Effective LOC

| Counter | Value |
| ------- | ----- |
| human-effective (hook, primary) | 356 |
| raw added | 601 |
| files touched by solution.patch | 12 |
| padding-floor | 110 |

Sprint floor is 250 effective / 2 files. The count is carried by distinct logic: the resumable frame
state and its suspend/resume path (`interp.go` 58), the generator value and its iterator
(`generator.go` 91), the iterator-error plumbing across the built-ins (`library.go` 66), the generator
expression desugaring (`resolve.go` 45), the opcode plus serialization (`compile.go` 36 + `serial.go` 3),
and the syntax and option surface (`parse.go`/`syntax.go`/`walk.go`/`options.go` 34).

## Test surface

128 nodes across 10 test functions: construction and laziness, iteration and statefulness, `yield from`
delegation, seventeen consumers of an iterable, error propagation through twelve of them, mutation locks
held across a suspension and released on exhaustion or close, re-entrancy, freeze after module
execution, the static errors, generator expressions, `next` and `close`, bytecode round trip, and step
accounting.

## Solvability / difficulty signal

Reference solution passes 91/91 and leaves the repository's 83 existing test nodes untouched, so the
solvability floor is met. No imitator batch and no platform batch have been run yet.

## Pre-check round 1 re-validation (after the file rename, meta trims and substring relaxation)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (91 cases, 91 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (91/0) every run |

F2P node parity re-confirmed: 91 identical (classname, name) pairs. Node names are unchanged by the
rename, so the synthesized fallback list in `test.sh` still matches exactly.

## Pre-check round 2 re-validation (after relaxing three error-wording assertions)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (91 cases, 91 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (91/0) every run |

F2P parity 91 identical (classname, name) pairs; node names unchanged.

## Test Fairness round re-validation (2 unfair tests removed, 3 coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (92 cases, 92 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (92/0) every run |

Test surface is now 92 nodes; F2P parity 92 identical (classname, name) pairs.

## Test Fairness round 2 re-validation (two advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (94 cases, 94 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (94/0) every run |

Test surface is now 94 nodes; F2P parity 94 identical (classname, name) pairs.

## Test Fairness round 3 re-validation (three advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (97 cases, 97 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (97/0) every run |

Test surface is now 97 nodes; F2P parity 97 identical (classname, name) pairs.

## Test Fairness round 4 re-validation (two advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (100 cases, 100 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (100/0) every run |

Test surface is now 100 nodes; F2P parity 100 identical (classname, name) pairs.

## Test Fairness round 5 re-validation (two advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (102 cases, 102 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (102/0) every run |

Test surface is now 102 nodes; F2P parity 102 identical (classname, name) pairs.

## Test Fairness round 6 re-validation (three coverage tests added, meta states close idempotence)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (105 cases, 105 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (105/0) every run |

Test surface is now 105 nodes; F2P parity 105 identical (classname, name) pairs.

## Test Fairness round 7 re-validation (two advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (107 cases, 107 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (107/0) every run |

Test surface is now 107 nodes; F2P parity 107 identical (classname, name) pairs.

## Test Fairness round 8 re-validation (three advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (110 cases, 110 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (110/0) every run |

Test surface is now 110 nodes; F2P parity 110 identical (classname, name) pairs.

## Test Fairness round 9 re-validation (four advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (114 cases, 114 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (114/0) every run |

Test surface is now 114 nodes; F2P parity 114 identical (classname, name) pairs.

## Test Fairness round 10 re-validation (1 unfair assertion removed, 3 coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (117 cases, 117 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (117/0) every run |

Test surface is now 117 nodes; F2P parity 117 identical (classname, name) pairs.

## Test Fairness round 11 re-validation (four advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (121 cases, 121 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (121/0) every run |

Test surface is now 121 nodes; F2P parity 121 identical (classname, name) pairs.

## Dockerfile fix re-validation (compile-only cache warming, no GOPROXY pin)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (121 cases, 121 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (121/0) every run |

Environment quality re-confirmed on the rebuilt image: the vanilla tree builds and `go test ./...`
passes offline as UID 1000.

## Test Fairness round 12 re-validation (display test removed, 2 coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (122 cases, 122 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (122/0) every run |

Test surface is now 122 nodes; F2P parity 122 identical (classname, name) pairs.

## Test Fairness round 13 re-validation (three advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (125 cases, 125 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (125/0) every run |

Test surface is now 125 nodes; F2P parity 125 identical (classname, name) pairs.

## Test Fairness round 14 re-validation (close contract widened, 2 coverage additions)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (126 cases, 126 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (126/0) every run |

Test surface is now 126 nodes; F2P parity 126 identical (classname, name) pairs.

## Test Fairness round 15 re-validation (two advisory coverage tests added)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (128 cases, 128 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (128/0) every run |

Test surface is now 128 nodes; F2P parity 128 identical (classname, name) pairs.

## Test Fairness round 16 re-validation (post-failure state documented; tests unchanged)

| State | `test.sh base` | `test.sh new` |
| ----- | -------------- | ------------- |
| BASE + test.patch | PASS (83/0) | FAIL (128 cases, 128 failures) |
| BASE + test.patch + solution.patch, 3 runs | PASS (83/0) every run | PASS (128/0) every run |

F2P parity 128 identical (classname, name) pairs. Only meta.md changed this round.

## Platform batches

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
| ----- | ----- | --------- | ------- | ---- | ----- | --- | ------------ | ------------- |
| pending | | | | | | | | |
