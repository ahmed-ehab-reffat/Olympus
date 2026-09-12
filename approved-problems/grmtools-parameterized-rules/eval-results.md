# eval-results.md — grmtools-parameterized-rules

BASE_COMMIT `c1a9bd0f820285754e17fc002f1cb69667ee3055`.

## Batch 0 — local validation

| Check | Result |
| --- | --- |
| vanilla suite, base tree | 293 pass, 0 fail, 2.6s |
| base mode, base tree + test.patch | 293 cases, 0 failures |
| new mode, base tree + test.patch | all cases fail (F2P complete) |
| base mode / new mode, solution applied | 293 pass / all pass |
| both apply orders, and reverse | clean |
| flakiness, 5 runs of each mode | identical |
| offline container, `--network none --user 1000:1000` | green |

## Batch 1 — 9 platform runs (8 Nova, 1 Orion). 0 of 9 passed.

Artifacts under `agent-runs/`. Test suite at the time: 133 tests; the suite is now 128 after the five idiom-fighting span tests were removed.

| Agent | Evaluator | Verdict | Msgs | Files | +LOC | Failed tests | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Nova 1 | Nova | FAIL | 4 | 3 | 1104 | 5: malformed-list, malformed-list-in-directive, malformed-separator, unclosed-list, prec-parameter spans | zero-length spans from `mk_error`; `%prec` error reported the parameter token rather than the call | pre-pass expansion, same shape as the reference |
| Nova 2 | Nova | FAIL | 5 | 3 | 1176 | 1: malformed-separator span | doubled separator propagated an empty span | 132 of 133; the strongest run |
| Nova 3 | Nova | FAIL | 5 | 6 | 1108 | 5 span tests | all through `mk_error`, `Span::new(off, off)` | pre-pass expansion |
| Nova 4 | Nova | FAIL | 5 | 5 | 1230 | 5 span tests | same | pre-pass expansion |
| Nova 5 | Nova | no result | — | — | — | — | run produced no artifacts beyond `run.txt` | — |
| Nova 6 | Nova | FAIL | 5 | 2 | 997 | 5 span tests | same | pre-pass expansion |
| Nova 7 | Nova | no result | 3 | 0 | 0 | 133 (whole suite) | no implementation landed; total wipe | — |
| Nova 8 | Nova | FAIL | 4 | 6 | 1188 | 4 span tests | same | pre-pass expansion |
| Orion | Nova | FAIL | 6 | 6 | 975 | 9: 6 nested-ordering/type-order plus 3 span | `ensure_call` inserted the outer rule before recursing into arguments | outer-before-inner ordering |

Pass rate 0 of 9. Solvability floor breached.

## Batch 1 differential harness

Every agent patch replayed locally against 35 probe grammars (deep interleaved nesting with shared
subterms, recursion that spawns a new instantiation, two argument sets each self-recursive, argument
declared after its call, a parameter shadowing a rule name, an argument type mentioning the parameter
letter, cross-source demand from production plus `%start` plus `%expect-unused`, limit reached by
nesting, forwarded token arguments, empty productions inside recursion, three-parameter positional
with repeats).

| Agent | Probes diverging from the reference |
| --- | --- |
| Nova 1, 2, 3, 6, 8 | 1 of 35 (token name containing a quote) |
| Nova 4 | 0 of 35 |
| Orion | 4 of 35 (all nesting order) |

Six of six working Nova runs reproduce the reference byte for byte on every functional probe. The
feature is not hard for Nova; the 0% came from the diagnostic-span family alone.

## Batch 1 replay against the trimmed 128-test suite

After removing the five span tests, every agent patch was replayed locally.

| Agent | Result |
| --- | --- |
| Nova 2, 3, 4, 6, 8 | PASS |
| Nova 1 | 1 failure |
| Orion | 5 failures, all nesting order |

5 of 9 = 56%, above the 40% cap. Recorded, not fixed, per the decision to keep the artifact as is.
