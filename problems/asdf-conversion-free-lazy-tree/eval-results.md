# asdf-conversion-free-lazy-tree - eval results

No platform batch yet.

## Local validation (SLICE, 2026-09-26)

Image `factory-asdf-conversion-free-lazy-tree` built from a fresh clone at BASE (with .git) in
~65 s (base image cached). Clean room: `git apply test.patch`, run, `git apply solution.patch`, run;
`--network none`.

| uid | tree | mode | rc | cases | failed | skipped |
|---|---|---|---|---|---|---|
| 1000 | base + test.patch | base | 0 | 2196 | 0 | 2 |
| 1000 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 1000 | + solution.patch | base | 0 | 2196 | 0 | 2 |
| 1000 | + solution.patch | new | 0 | 11 | 0 | 0 |
| 0 | base + test.patch | base | 0 | 2196 | 0 | 3 |
| 0 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 0 | + solution.patch | base | 0 | 2196 | 0 | 3 |
| 0 | + solution.patch | new | 0 | 11 | 0 | 0 |
| 4242 | base + test.patch | base | 0 | 2196 | 0 | 2 |
| 4242 | base + test.patch | new | 1 | 11 | 11 | 0 |
| 4242 | + solution.patch | base | 0 | 2196 | 0 | 2 |
| 4242 | + solution.patch | new | 0 | 11 | 0 | 0 |

(skipped = 2 xfail, plus one root-only permission skip in `test_api.py` when running as root.)

- Both patch orders apply and reverse-apply cleanly; test.sh is `new file mode 100755`.
- JUnit: no `::` in ids, no duplicate ids (2196 base, 11 new).
- LOC hook: human-effective 367, raw 443, padding-floor 300, 6 files.
- Repo lint (ruff 0.16.0 check + format, codespell, flynt) clean on every changed file.
- Mutant M1 (search/info convert outside the tree): killed by 3 tests
  (`test_filter_only_sees_nodes_the_key_accepts`, `test_edit_made_through_a_search_result_is_written`,
  `test_alias_reached_through_search_stays_one_object`).
- Flakiness 3x: not run in the slice (owed in FINISH). Local base suite ran 5 times identical
  (2194 passed / 2 xfailed).
