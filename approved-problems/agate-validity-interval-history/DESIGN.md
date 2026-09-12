# DESIGN — agate validity interval histories

## 1. Title
Add validity interval histories to Table.

## 2. Repo / base
- `wireservice/agate` — MIT, 1199 stars, pure Python, deps Babel / isodate / leather /
  parsedatetime / python-slugify / pytimeparse. Our first agate submission.
- BASE_COMMIT `7aa490cbc3d965e0a950dd904ea1f9cf5ced013c` (2026-07-23, repo HEAD at pick time, so
  there is no post-base activity to reconcile).
- Activity: 9 source commits in the trailing 12 months, all real bug fixes (Mode naming,
  PercentileRank nulls, Rank null ordering, from_fixed, distinct key sequences).
- Vanilla suite: 396 passed in ~1.2 s, offline, as uid 1000, deterministic over 5 runs.
- Env: `olympus-base-python` plus `locales` (en_US, de_DE, fr_FR, ko_KR — `tests/__init__.py`
  calls `locale.setlocale(LC_ALL, 'en_US.UTF-8')` at import, and three data-type tests parse
  German, French and Korean month names), `tzdata` (a DateTime test resolves `US/Pacific`), and
  `lxml` + `cssselect` (leather's `testcase` imports lxml to parse the SVG the charting tests
  produce). Without those four the vanilla suite is not green, and Environment Quality runs the
  whole tree. Nothing is installed or built from the repo itself: `PYTHONPATH=/app` makes
  `import agate` resolve, so the image needs no editable install, and every pip package is pinned.

## 3. Shape
O-Composite-add — a new subsystem (`agate/history.py`) feeding eleven `Table` methods, one
`Aggregation`, and the `TableSet` proxy surface.

## 4. Exclusivity
- `gh pr list -R wireservice/agate --state all --search ...` for temporal / interval / as of /
  history / snapshot / timeline / validity / effective / bitemporal: zero hits. The whole PR
  stream is bug fixes and dependabot bumps.
- Issue search over the same keywords: nothing about intervals or histories.
- Local dedup: no `agate-*` folder in any `Task*/problems`, `problems/`, `rejected/` or
  `Olympus/approved-problems`, and no prior submission on validity intervals in any repo.
- The feature is invented, not issue mined.

## 5. Public API
```python
Table.to_history(key, effective, start_column_name='valid_from', end_column_name='valid_to')
Table.coalesce_history(key, start_column_name, end_column_name)
Table.flatten_history(key, start_column_name, end_column_name)
Table.split_history(key, boundaries, start_column_name, end_column_name)
Table.clip_history(key, start, end=None, start_column_name, end_column_name)
Table.history_at(instant, start_column_name, end_column_name)
Table.history_gaps(key, start_column_name, end_column_name)
Table.history_overlaps(key, start_column_name, end_column_name)
Table.history_spans(key, start_column_name, end_column_name, duration_column_name='duration')
Table.history_events(key, effective_column_name='effective', start_column_name, end_column_name)
Table.join_history(right_table, key, inner=True, start_column_name, end_column_name)
agate.Coverage(start_column_name='valid_from', end_column_name='valid_to')
```
All eleven methods are also proxied onto `TableSet`.

## 6. Semantics (every rule is in meta.md, every rule has a killing mutation)
1. Intervals are half open `[start, end)`; a null end is unbounded. Comparisons go through
   `ends_after`, so a null end is later than every instant.
2. Interval columns must both be `Date` or both `DateTime` (`DataTypeError`); a null start or an
   end at or before its start is a `ValueError`; a new column name that already exists is a
   `ValueError`. The same validation runs from every entry point.
3. Keys group in first-appearance order; rows within a key come out by interval start, except
   `history_at` (input order) and `join_history` (left order, then right).
4. Values compare as the tuple of non-key non-interval columns, with null equal to null.
5. `to_history`: sort by `effective`, resolve ties last-wins, then collapse repeats, then close on
   an all-null observation. The three steps are ordered and each one is separately observable.
6. `coalesce_history` merges only when `previous end == next start`; a gap always blocks.
7. `flatten_history` applies rows in input order and subtracts, so containment yields two pieces.
8. `join_history` intersects with `max(start)` and the earlier end, drops zero-length results, and
   with `inner=False` subtracts every paired stretch from the left interval.
9. `history_spans` sums interval lengths; an open end makes both the end and the duration null.
10. `Coverage` is the only place overlaps are allowed: it unions before summing.

## 7. File footprint (measured)
| file | raw | human-effective |
|---|---|---|
| agate/history.py (new) | 225 | 80 |
| agate/table/join_history.py (new) | 107 | 50 |
| agate/table/to_history.py (new) | 87 | 45 |
| agate/aggregations/coverage.py (new) | 59 | 34 |
| agate/table/history_spans.py (new) | 60 | 27 |
| agate/table/history_events.py (new) | 59 | 23 |
| agate/table/coalesce_history.py (new) | 52 | 22 |
| agate/tableset/proxy_methods.py | 77 | 22 |
| agate/table/history_overlaps.py (new) | 50 | 21 |
| agate/table/clip_history.py (new) | 56 | 21 |
| agate/table/__init__.py | 22 | 22 |
| agate/table/flatten_history.py (new) | 47 | 19 |
| agate/table/history_gaps.py (new) | 45 | 18 |
| agate/table/split_history.py (new) | 49 | 18 |
| agate/tableset/__init__.py | 16 | 16 |
| agate/table/history_at.py (new) | 38 | 15 |
| agate/aggregations/__init__.py | 1 | 1 |
| total | 1077 | 464 |

## 8. Traps (interdependent + misdirecting)
- T1 a null end is unbounded, not missing. Sorting or `min()` over ends without the special case
  either crashes or silently truncates; the damage shows up in `join_history` and `flatten_history`
  rather than in the helper.
- T2 `coalesce_history` compares values, not whole rows; comparing rows never merges anything, and
  the failure reads as "coalesce does nothing".
- T3 a gap must block coalescing. Collapsing consecutive equal values swallows the gap, and the
  wrong answer surfaces in `history_at` at an instant inside it, not in the coalesce test.
- T4 `flatten_history` splits a covered middle into two rows. Truncation-only implementations lose
  the tail, which only appears when a later interval sits strictly inside an earlier one.
- T5 `to_history` must resolve duplicate instants before collapsing repeats. The reverse order
  collapses a row that a duplicate was about to shadow.
- T6 `join_history` drops zero-length intersections, so touching intervals contribute nothing.
- T7 `inner=False` subtracts each paired stretch as it goes, so one left row can leave two or three
  remainders; subtracting only the last match, or the union computed up front, both diverge.
- T8 an all-null observation closes an interval instead of opening one, which is what makes
  `history_events` and `to_history` inverses.

## 9. Tests
`tests/test_history_c7f4aa.py`, 249 tests in thirteen classes: one per entry point, the `TableSet` proxies, and two that sweep the
shared validation across every method. The module imports only names that exist on base, so it collects on the base
commit and every one of the 249 JUnit nodes fails there individually (verified in the image).
Assertions use `assertColumnNames` / `assertColumnTypes` / `assertRows` plus an explicit row count
on every `assertRows`, and exceptions are matched by class only, never by message.

## 10. Verification
- 48 mutations of the reference, every one killed by at least one test, zero survivors.
- Base 396 / new 249 green offline as uid 1000, both patch orders, three container runs each.
- flake8 and isort clean under the repo's own `setup.cfg`.

## 11. Tier
Olympus. 17 files, 464 human-effective LOC, 249 F2P tests, deterministic and offline.
