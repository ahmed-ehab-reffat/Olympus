# healthchecks-lateness-ledger: eval results

No platform batch. Shelved at the SLICE LOC spike.

## Local validation log

| Run | Image | Result |
|---|---|---|
| base suite, base tree | factory image, uid 1000, --network none | 1757 OK (Django runner) |
| hunter probe (Gate 1 + traps C, D) | same | reproduced: no late record; persisted status disables going down; `/start` moves the default grace start |
| base suite, spike reference applied | same | 1757 OK |
| spike behaviour probe (worker-first, ping-first fail, timeout down, started run, edit) | same | as designed |

## LOC measurement (hook, full-scope spike)

| File | raw | human-eff |
|---|---|---|
| hc/api/models.py | 118 | 82 |
| hc/api/management/commands/sendalerts.py | 50 | 21 |
| hc/api/views.py | 14 | 13 |
| hc/front/views.py | 15 | 15 |
| hc/accounts/models.py | 5 | 5 |
| migration (generated) | 38 | 25 |
| templates (4 files) | 33 | 33 |
| total | 273 | 194 |
