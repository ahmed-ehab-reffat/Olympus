# pyfakefs-advisory-file-locks - eval results

No platform batch yet.

## Local validation - SLICE (2026-09-29)

| Check | Result |
|---|---|
| Clean room | git clone of the worktree at 796c48eb + test.patch, image `factory-pyfakefs-advisory-file-locks`, --network none, cold build 19 s |
| base, no solution | 1421 passed / 976 skipped / 5 deselected / 2 xfailed (uid 1000, 4242:4242, 4242:0); 1415 / 982 as root (0:0, 0:4242); 0 failed everywhere |
| base, with solution | identical counts, 0 failed |
| new, no solution | 12/12 failed (every uid) |
| new, with solution | 12/12 passed (every uid) |
| JUnit | 2399 base testcases, 0 duplicate ids, no `::`; new 12 |
| git status in image | only `test.sh` and `pyfakefs/tests/fake_file_lock_2b28e7_test.py` |
| LOC hook | 4 files, 317 raw, 273 human-effective, padding-floor 164 |
| Real-Linux oracle | 46 cells, 0 mismatches with the reference; base wrong on every lock/dup cell |
| Lint | ruff 0.16.7 format/check clean, pyupgrade --py310-plus clean, mypy only pre-existing pyarrow error |
| Flakiness | not run yet (FINISH) |
