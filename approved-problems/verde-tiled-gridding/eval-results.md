# eval-results — verde-tiled-gridding

Repo: fatiando/verde @ `19e67c6b570384d2380c7d78cd08a85983b34d0c`
Tier: Olympus · Shape: O-Composite-add with an O-Algorithm-correctness core

## Local validation matrix

| Check | Command | Result |
| --- | --- | --- |
| base on base (vanilla tree, in image) | `pytest verde` offline, uid 1000 | 182 passed, 4 skipped |
| new on base (test.patch only) | `./test.sh --output_path … new` | **121 failed, 0 error, 121 testcase nodes** |
| base with solution | `./test.sh … base` in container | 182 passed, 4 skipped |
| new with solution | `./test.sh … new` in container | 121 passed |
| apply order test then solution | `git apply` both | clean |
| apply order solution then test | `git apply` both | clean |
| unapply both | `git apply -R` | clean |
| determinism, base | 3 runs | 182/4 every run |
| determinism, new | 3 runs in the container | 121 every run |
| offline | `docker run --network none --user 1000:1000` | both modes pass |

## Size

| Metric | Value |
| --- | --- |
| raw added (solution) | 787 |
| human-effective (hook) | **323** (floor 250) |
| padding-floor | 240 |
| files changed | 3 (`verde/tiling.py` new, `verde/coordinates.py`, `verde/__init__.py`) |
| new tests | 121 |
| base testcase nodes | 186 |

## Mutation battery (18 mutations, reference broken on purpose)

| Mutation | Verdict | Tests that fail |
| --- | --- | --- |
| band width halved | KILLED | 1 |
| taper factors combined with min instead of product | KILLED | 3 |
| taper ignores the region boundary | KILLED | 8 |
| min_data uses `<=` | KILLED | 1 |
| split threshold uses `>=` | KILLED | 1 |
| max_depth off by one | KILLED | 1 |
| tile order west before south | KILLED | 1 |
| spacing rounds down | KILLED | 2 |
| adjust="region" pads one side | KILLED | 1 |
| overlap grows every edge | KILLED | 7 |
| blend without renormalising | KILLED | 1 |
| uncovered points give zero | KILLED | 2 |
| estimator reused instead of cloned | KILLED | 6 |
| data weights dropped | KILLED | 3 |
| nearest ties go to the later tile | KILLED | 1 |
| merge without the plain-average fallback | KILLED | 2 |
| merge margin is the full grid size | KILLED | 1 |
| merge counts missing values | KILLED | 1 |

Survivors: none.

## False-positive audit

- Every transformation the description names (tile extension, taper, blend, merge) has a test whose
  input is not a fixed point of it: exact tile bounds catch a double extension, the four-tile corner
  catches a wrong combination rule, and the dropped-tile case catches a missing renormalisation.
- Both readings of every rule that could go either way are pinned in the description: which edges
  taper, the width of the band, the counting rule for splitting versus dropping, tie breaking in
  `nearest`, and the fallback when every merge weight is zero.
- The reporting API (`tile_report`) is asserted on a case where a tile is dropped, not only on the
  happy path.
- Each discriminator was proven by breaking the reference and watching exactly the intended tests
  fail (table above).

## Agent runs

None yet — pending the platform batch.

| Agent | Verdict | Messages | Files | LOC | Failed tests | Approach |
| --- | --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — | — |
