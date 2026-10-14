# sqlalchemy-continuum-transaction-squash: eval results

No platform batch. Shelved before any precheck.

## Local measurements (2026-10-05)

| What | Result |
|---|---|
| Base suite in image (uid 1000, --network none, multithreaded module deselected) | 856 passed / 15 skipped, 72 s |
| Full-scope spike, effective_loc_check.py | 146 human-effective, 182 raw, 7 files |
| Spike probe (2 scenarios x 8 setting variants) | 16/16 pass; repo test_vacuum.py 2/2 |
