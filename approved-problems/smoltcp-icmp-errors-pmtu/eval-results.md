# eval-results — smoltcp-icmp-errors-pmtu

No platform batch has been run yet. Local validation only.

## Local validation

| Check | Command | Result |
|---|---|---|
| Base suite, reference tree | `./test.sh --output_path X base` | 672 cases, 0 failures |
| New suite, reference tree | `./test.sh --output_path X new` | 81 cases, 0 failures |
| Base suite, base commit + test.patch | same | 672 cases, 0 failures |
| F2P, base commit + test.patch | `./test.sh --output_path X new` | 81 cases, 81 failures |
| Patch apply | `git apply --check` both, in order | clean |
| Flakiness | 3 runs of each mode, in the container | identical counts and bytes |
| Docker | build from clean base context, then `--network none --user 1000:1000` | image builds; 81/81 new, 672 base, 81/81 F2P |
| LOC | `effective_loc_check.py solution.patch` | 675 raw / 383 human-effective / 10 files |
| Counter 1 | raw minus blank minus comment | 495 |
| Banned markers | `grep -rEl "shipd\|datacurve" tests/ test.sh` | none |

## Per-agent runs

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|---|---|---|---|---|---|---|---|
| _pending_ | | | | | | | |

Capture every passing agent's diff into `agent-runs/<batch>-<run>.patch` while the run view is open.
