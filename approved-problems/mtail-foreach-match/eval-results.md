# eval-results.md — mtail-foreach-match

Platform Nova/Orion/Vega runs are executed on the Shipd platform (not available in this authoring env). This file tracks per-agent results once runs are available.

## Local validation matrix (target)

| Check | State | Result |
| --- | --- | --- |
| Docker image builds (offline after mod download, non-root) | ✅ | olympus-base-go, `go build ./...` clean |
| patches apply clean, both orders | ✅ | test->solution AND solution->test |
| `test.sh base` (existing tests) PASS on BASE | ✅ | 442 testcases, 0 fail |
| `test.sh new` on BASE → FAIL (F2P) | ✅ | exit 1, `foreach` parse error (right reason) |
| `test.sh base` after solution PASS | ✅ | 442 testcases, 0 fail |
| `test.sh new` after solution PASS | ✅ | 33 tests, 0 fail |
| new tests deterministic 3x | ✅ | 33 tests / 0 fail identical each run |
| effective LOC (human-effective) | ✅ | 442 (≥430); raw 559; 12 files (parser.go generated, excluded) |
| flakiness (time/RNG/network/order) | ✅ | none; explicit `sort` for all map iteration |
| Nova/Orion/Vega pass-rate | ⏳ | platform-only (not runnable in authoring env) |
| FP check across passers | ⏳ | platform-only; values-from-execution => no gaming path |

## Per-agent table (per platform run)

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _pending platform runs_ | | | | | | | | |
