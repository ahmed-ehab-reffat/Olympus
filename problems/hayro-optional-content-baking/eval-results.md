# hayro-optional-content-baking — eval results

No platform batch yet. Local validation numbers are logged here as they are measured.

## Local validation (SLICE, 2026-09-23)

| Check | Result |
|---|---|
| test.sh base on base (uid 0 / 1000 / 4242, --network none) | 475 cases, 0 failures, rc 0 (all three uids) |
| test.sh new on base | 10 cases, 10 failures (runtime assertion "extracted page differs from the source page"), rc 1 |
| test.sh base with solution, 3 runs x 3 uids | 475 / 0 failures each run, identical |
| test.sh new with solution, 3 runs x 3 uids | 10 / 0 failures each run, identical |
| git status after both patches | only harness + solution files |
| effective_loc_check.py solution.patch | raw 244, human-effective 165, padding-floor 25, 3 files |
| Docker build (base image cached) | ~140 s |
