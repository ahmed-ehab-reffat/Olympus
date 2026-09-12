# eval-results.md - gluon-match-guards

## Local validation (no platform agents run)

| Check | Result |
|---|---|
| new mode + solution | 55 pass / 0 fail |
| new mode on base (no solution) | 44 fail / 11 pass (discriminating tests fail; 11 syntax-reject tests pass both) |
| base mode (pattern_match+row_polymorphism) on base | 21 pass |
| base mode with solution | 21 pass (no regression) |
| exhaustiveness vs std (broad sweep: error/metadata/de/safety/api/limits/debug/tutorial) | 43 pass, 0 regression |
| flakiness 3x (new) | identical 55/55 each run |
| patches apply both orders + reverse | clean |

## Fingerprint
sol=solution.patch (14 files, 335 raw + / ~228 eff) test=test.patch (test.sh + match_guards_c0da3a.rs, 55 tests)

## Pending
- Platform Nova/Orion batch (10 runs) for pass-rate + solvability + message-count.
