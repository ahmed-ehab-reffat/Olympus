# aerich-migration-squash: eval results

No platform batch. Shelved before any precheck.

## Local measurements (2026-10-05)

| What | Result |
|---|---|
| Base suite in image (uid 1000, --network none) | 70 passed / 10 skipped, 137 s |
| Full-scope spike, effective_loc_check.py | 157 human-effective, 175 raw, 3 files |
| Spike end-to-end probe | correct on mid-range squash, next migrate, downgrade -1 / -v 2, heads, partial upgrade |
