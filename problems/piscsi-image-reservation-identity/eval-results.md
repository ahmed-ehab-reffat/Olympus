# eval-results — piscsi-image-reservation-identity

No platform batch yet. Local validation numbers are logged below as they are measured.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|

## Local validation — core slice, 2026-09-21

| Check | Result |
|---|---|
| Cold `docker build --no-cache` (platform order, pristine clone) | 4m59s (RUN 264s, export 24s) |
| base mode, no solution, uid 1000 / root | 316 pass / 0 fail, both |
| new mode, no solution | 14 of 14 fail, both uids |
| base mode, with solution | 316 / 0, both uids |
| new mode, with solution | 14 / 0, both uids |
| Baseline determinism (probe image, uid 1000) | 3 identical runs |
| human-effective LOC (hook) | 23 (slice only; floor 200 owed at FINISH) |

## Local validation — round 3 (27 tests), 2026-09-23

| Check | Result |
|---|---|
| Cold `docker build` (platform order, pristine clone) | 12m28s |
| base mode, no solution, uid 0 / 1000 | 316 pass / 0 fail, both |
| new mode, no solution | 27 of 27 fail, both uids |
| base mode, with solution, 3 runs | 316 / 0 each, both uids |
| new mode, with solution, 3 runs | 27 / 0 each, both uids |
| human-effective LOC (hook) | 54 (floor 200 still owed) |

## Local validation — round 4 (35 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 | 316 pass / 0 fail, both |
| new mode, no solution | 35 of 35 fail, both uids |
| base mode, with solution, 3 runs | 316 / 0 each, both uids |
| new mode, with solution, 3 runs | 35 / 0 each, both uids |
| human-effective LOC (hook) | 92 (floor 200 still owed) |

## Local validation — round 5 (sharing + holder report, 52 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | compile fallback, 1 failing case, all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 52 / 0 each, all three uids |
| Counter 1 / hook human-effective | 216 / 168 |

## Local validation — round 6 (unprotect + holder messages, 53 tests), 2026-09-23

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | compile fallback, 1 failing case, all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 53 / 0 each, all three uids |
| Counter 1 / hook human-effective | 217 / 169 |

## Local validation — round 7 (named fallback, 54 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 54 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 54 / 0 each, all three uids |

## Local validation — round 8 (dup ids, read-only disks, 57 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 57 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 57 / 0 each, all three uids |
| Counter 1 / hook human-effective | 227 / 175 |

## Local validation — round 9 (real creates, LUN holders, 58 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 58 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 58 / 0 each, all three uids |
| Counter 1 / hook human-effective | 228 / 176 |

## Local validation — round 10 (nopasswd create, external link, same-ID LUNs, 61 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 316 pass / 0 fail, all three |
| new mode, no solution | 61 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 316 / 0 each, all three uids |
| new mode, with solution, 3 runs | 61 / 0 each, all three uids |

## Local validation — round 11 (cwd precedence, batch holder message, ValidateFile back in base, 62 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 62 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 62 / 0 each, all three uids |

## Local validation — round 12 (per-holder identity with held descriptor, cwd device holders, 64 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 64 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 64 / 0 each, all three uids |
| Counter 1 / hook human-effective | 279 / 210 |

## Local validation — round 13 (`..` after folder links, 65 tests), 2026-09-24

| Check | Result |
|---|---|
| base mode, no solution, uid 0 / 1000 / 4242 | 317 pass / 0 fail, all three |
| new mode, no solution | 65 named failures (same ids as the solution run), all three |
| base mode, with solution, 3 runs | 317 / 0 each, all three uids |
| new mode, with solution, 3 runs | 65 / 0 each, all three uids |
| Counter 1 / hook human-effective | 281 / 212 |
