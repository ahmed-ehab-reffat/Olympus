# riff-unified-conflict-regions - eval results

No platform batch yet (slice awaiting the precheck).

## Local validation (2026-09-23, SLICE)

| Check | Result |
|---|---|
| Cold `docker build --no-cache` | 153 s (build step 79 s, export 41 s) |
| Clean room, uid 0 / 1000 / 4242, `--network none` | identical for all three |
| test.patch only: `test.sh base` | 62 testcases, 0 failures, exit 0 |
| test.patch only: `test.sh new` | 9 testcases, 9 failures (assertion diffs, not crashes), exit 101 |
| + solution.patch: `test.sh base` | 62 / 0, exit 0 |
| + solution.patch: `test.sh new` | 9 / 0, exit 0 |
| JUnit hygiene | 0 `::`, 0 duplicate (classname, name) |
| Flakiness, base + new x3 in container | identical fingerprints |
| Build-failure fallback | new: 9 named failing cases; base: 1 `compilation` case |
| effective_loc_check.py solution.patch | raw 640, human-effective 445, 6 files |
| cargo fmt --check, cargo clippy (default targets) | clean |

## Trap reproduction (mutations of the reference, new tests)

| Mutation | Tests failing |
|---|---|
| M1 resolved context line counted for its side only | resolved_kept_line_counts_for_its_side_and_the_resolution (fails on side 2's row) |
| M2 region ends at the closing marker | 5 of 9 |
| M3 open region flushed at hunk end | region_continues_across_hunks |
