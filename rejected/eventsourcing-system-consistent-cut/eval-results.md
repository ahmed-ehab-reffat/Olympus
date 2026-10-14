# eval-results.md - eventsourcing-system-consistent-cut

No platform batch yet.

## Local validation (2026-09-30, SLICE)

Image `factory-eventsourcing-system-consistent-cut` built from a fresh clone at BASE
575d42c10a821828639b90178ed56703abe9c9f1; patches applied inside the container; `--network none`.

| Run | uid | Mode | Solution | Cases | Failures | Exit |
|---|---|---|---|---|---|---|
| F2P | 1000 | new | no | 17 | 17 | 1 |
| P2P | 1000 | base | no | 567 | 0 | 0 |
| x3 | 1000 | base | yes | 567 | 0 | 0 (3/3 identical) |
| x3 | 1000 | new | yes | 17 | 0 | 0 (3/3 identical) |
| roles | 0, 4242 | new | no / yes | 17 | 17 / 0 | - |
| roles | 0, 4242 | base | no / yes | 567 | 0 / 0 | 0 |

Base-only flakiness sweep before the pool exclusion: 5 runs x 618 cases, 0 failures; one
`TestSQLiteConnectionPoolWithFileDB.test_max_age` timing failure seen in a run with the solution
applied (timer-based pool test, now excluded; see feedback.md).

JUnit: no duplicate ids, no `::` in classname/name.

LOC (hook): slice 286 raw / 234 human-effective / 5 files; full-lane spike 331 / 269.

## Local validation (2026-10-03, after Rebuild check fix)

Image built from a `git archive` snapshot at BASE (no `.git`, as the platform rebuild does) and from a
fresh clone at BASE; both build. Base mode now excludes MultiThreadedRunner + test_concurrent_no_conflicts
(timing-flaky, see feedback.md).

| Run | uid | Mode | Solution | Cases | Failures | Exit |
|---|---|---|---|---|---|---|
| F2P | 1000 | new | no | 17 | 17 | 1 |
| P2P | 1000 | base | no | 503 | 0 | 0 |
| x3 | 1000 | new | yes | 17 | 0 | 0 (3/3 identical) |
| x3 | 1000 | base | yes | 503 | 0 | 0 (3/3 identical) |
| roles | 0, 4242 | new | no / yes | 17 | 17 / 0 | 1 / 0 |
| stress x3 | 1000 | base | no | 502 | 0 | 0 (after excluding the hanging POPO subscribe test; --cpus=1 + 2 burners) |

## Local validation (2026-10-04, editable install restored)

Both contexts (git archive at BASE without .git, and fresh clone at BASE), uid 1000, --network none:
F2P new 17/17 fail without the solution; with it new 17/17 pass x3 and base 502/0 x3; base without it
502/0. `pip show eventsourcing`: Editable project location /app.

## Local validation (2026-10-04, reference reworked after Solution Quality, 25 tests)

| Run | uid | Mode | Solution | Cases | Failures | Exit |
|---|---|---|---|---|---|---|
| F2P | 1000 | new | no | 25 | 25 | 1 |
| P2P | 1000 | base | no | 502 | 0 | 0 |
| x3 | 1000 | new | yes | 25 | 0 | 0 (3/3 identical) |
| x3 | 1000 | base | yes | 502 | 0 | 0 (3/3 identical) |
| roles | 0, 4242 | new | no / yes | 25 | 25 / 0 | 1 / 0 |
| stress x10 | 1000 | new | yes | 25 | 0 | 0 (--cpus=1 + 2 burners) |
| stress x2 | 1000 | base | yes | 502 | 0 | 0 |

Postgres 16 (outside the grader): probe 46/46 (db functions off and on); repo Postgres suite 254 pass /
24 env failures, identical set on base and patched. Lint at lock pins: clean, same as base.

## Local validation (2026-10-04, round 5: split Dockerfile + recorder-kwargs restore, 26 tests)

Images built from 4 contexts (archive without .git, fresh clone at BASE, archive + both patches, clone
with emptied .git/objects). Full runs on the clone image (agents' build) and the archive image, uid 1000,
--network none:

| Image | F2P new (no sol) | base (no sol) | new x3 (sol) | base x3 (sol) |
|---|---|---|---|---|
| clone | 26/26 fail | 502/0 | 26/0 x3 | 502/0 x3 |
| archive | 26/26 fail | 502/0 | 26/0 x3 | 502/0 x3 |

uid 0 and 4242: 26 fail / 0 fail. Stressed (--cpus=1 + 2 burners) new x5: 26/0. Postgres FTS fork probe
3/3; 46-check Postgres probe 0 failures. Lint clean.

## Local validation (2026-10-05, round 7: recorder-owned JSON step state, 29 tests)

Clone image (agents' build), uid 1000, --network none: F2P 29/29 fail; base 502/0 without the solution;
with it new 29/0 x3 and base 502/0 x3; git status shows only harness + solution files. uid 0 and 4242:
29 fail / 0 fail. Stressed (--cpus=1 + 2 burners) new x5: 29/0. Postgres probes: follower FTS 3/3, FTS
app 2/2, searchable timestamps 3/3, 46-check probe 0 failures. Full make-lint scope clean (pyright's 6
missing-optional-package errors identical on base). Repo Postgres suite last run on round-6 code.

## Batch 1 (2026-10-05): 10 Nova -> 0/10
Every run passes base and 26/29 new tests. All 10 fail the same 3 recorder-state fork tests
(follower FTS, FtsContentManagement, SearchableTimestamps); Nova_1 also fails
test_fork_into_new_databases (SQLite decoded a no-event step as id 0). Unanimous same-cause failure on
a rule meta only implied ("holds exactly the state at the cut") = fairness gap, not difficulty.
Without those 3 tests the batch would be ~9-10/10 (too easy).

## Batch 2 (2026-10-08): 11 Nova -> 3 graded passes, all 3 voided by the FP panel (0 real)
Graded fails: 5 runs on test_fork_ignores_keyword_arguments_the_recorder_does_not_keep only, 1 run 16
fails, 1 run on recorder state. FP holes and fixes:
- reopen + fork with a per-save-state recorder (kwargs kept in memory only) -> new
  TestReopenedRecorderState (SearchableTimestamps on file SQLite, reopen, fork). Kills Nova_Nova_1.
- reopen, record more, cut (in-memory step cache dropped the persisted prefix) -> new
  TestSQLite.test_reopened_runner_keeps_cutting_after_new_events. Kills Nova_Nova_11.
- Postgres-only gaps / 63-char table name (Nova_Nova_4) -> untestable offline; meta now scopes cuts and
  forks to the in-memory and SQLite modules.
Nova_Nova_8 (evaluator fail, 0 test fails) replays saves via app._record, so it only loses state for
recorders whose kwargs the app cannot recompute (FTS), and the FTS example cannot reopen; left as is.
32 tests; 32/32 fail on base, pass with the reference.

## Batch 3 (2026-10-08): 10 Nova + 1 Vega -> 0/11
8 runs (incl. Vega) fail ONLY test_fork_ignores_keyword_arguments_the_recorder_does_not_keep: they pickle
every save kwarg, so `save(agg, unused=lambda: None)` crashes ("Can't get local object"). 3 runs miss the
recorder-state rule (follower + application FTS tests). The lambda rule is unstated in meta: shared-cause
failure = fairness risk; stating it likely puts the pass rate at 6-8/11 (over the ceiling). User is running
more agents before deciding.

## Batch 4 (2026-10-11, NEW-MODEL GATE): 4 Nova -> 1/4 pass (gate needs Nova 0/8) = TOO EASY
Nova_1 passes 32/32 legitimately (all baseline too). Nova_4 fails only the lambda-kwargs test. Nova_2/3
fail all 32 (follower steps never recorded in a SQLiteProcessRecorder override; fork re-inserts with new
rowids). Sequence length (final_metrics.extra.sequence_length): 486k, 674k, 586k, 591k, avg ~584k (>256k OK).
Per the admin calibration order, a Nova pass means stop and harden before any Orion/Vega runs.
