NEXT (human): re-run Task Prompt Quality + length on meta.md (397 words; reopen clause + 'Only the in-memory and SQLite persistence modules need to support cuts and forks.'), upload test.patch, then a FRESH batch (meta changed, no re-eval)

# feedback.md - eventsourcing-system-consistent-cut

## Status (2026-09-30, factory MODE=SLICE)
SLICE-READY. Core slice built and validated in a Docker clean room; stopped at author skill Step 4b
(no differentiating scope, no F-10 cross-product cells beyond the core, no LOC levers in the patch).

- Repo: pyeventsourcing/eventsourcing (canonical), branch 9.5, BASE 575d42c10a821828639b90178ed56703abe9c9f1.
- Lane: hunt #42 C* (consistent cut + fork of a System over a per-step processing ledger).
- Slice: `solution.patch` 286 raw / 234 hook human-effective / 5 files (persistence, popo, sqlite,
  postgres, system). `test.patch`: test.sh + 17 tests in `tests/system_tests/test_system_cut_fb30c2.py`.
- Local validation: F2P 17/17 fail without the solution, 17/17 pass with it; base 567 pass with and
  without the solution; 3x identical as uid 1000 `--network none`; also checked as uid 0 and 4242.

## MEASURE-FIRST result (orchestrator gate: >= 250 human-effective to proceed)
Spiked the full lane before tests or meta and measured with `.claude/hooks/effective_loc_check.py`:
- core (ledger in POPO/SQLite/Postgres atomic writes, cut solver, `get`, `fork`): 284 raw / **232**.
- full lane with two coupled levers (fork copies each aggregate's snapshots up to its cut version;
  `notification_log(cls)` presenting the log as at the cut): 331 raw / **269**, 5 files.
- Postgres parity is 67 of those (untestable here, no server). Hook padding-floor 172.
Proceeded on 269. Spike patches kept in `worktrees/eventsourcing-h42-scratch/{core_spike,full_spike}.patch`
(the full one is what FINISH starts from). The slice patch is the core only (dedupe matches on the core).

## Gates run (this session)
- Exclusivity PR-DIFF (canonical org resolved first): 16 feature-class searches, all states. Only
  #145 (2018 v7 causal dependencies, `application/process.py`, gone since v9, wait-for-dependency, not a
  cut), #247 (tests only), #93 (2017). No diff with a ledger, cut solver or fork.
- Fork-branch scan: Zahgon/eventsourcing `commit0_all` re-checked with `gh api compare`: 1 commit that
  replaces bodies with `pass` in 18 files (commit0 benchmark stub); no added line mentions
  cut/fork/step/ledger/as_of. Out of lane.
- SIX-CHECK: names/namespace/philosophy/closed-implemented clean (#311, #293, #281, #140 read with
  comments; nothing declines cuts or forks). Base..9.5 empty; 10.0 alpha has no cut/fork/steps.
  Functional: base has no `Runner.cut` (every new test fails with AttributeError).
- PICK-FILTER: G1 behavioural gap (no API, history absent), G5 cold (system.py 2 commits / 12 mo,
  popo/sqlite 0, maintainer lanes are DCB + v10), G6 reproduced (hunt probe + F2P), G7 dedup clean
  (no eventsourcing problem in problems/, rejected/, approved-problems/), G7b clean, G8 no maintainer
  objection, G9 base health below, G10 quota 0 subs.

## Gate 9 base health (owed item, done)
Image installs the test extras (pycryptodome, cryptography, psycopg[binary,pool], pydantic, msgspec,
orjson, pytest). Base mode = `tests` + `examples` via pytest, 567 cases, 5 clean runs before the
solution existed and 3 identical runs with it.

Excluded from base mode (reasons kept here, not in test.sh):
- anything named Postgres/postgres, `tests/docs_tests` (README/docs snippets connect to Postgres),
  `tests/dcb_tests/test_dcb.py` (benchmarks against Postgres), `examples/ftsprojection` (Postgres):
  need a database server, `couldn't get a connection after 5.00 sec` offline.
- `umadb` example tests: need a UmaDB server.
- `tests/benchmark`: benchmarks, not tests.
- `tests/persistence_tests/test_connection_pool.py` and every `*ConnectionPool*` class: timer/sleep
  based (`max_age=0.2`, `sleep(0.3)`); `TestSQLiteConnectionPoolWithFileDB.test_max_age` failed once
  in 8 runs under load. Unrelated to the feature (the solution does not touch pools).
- `test.sh` exports `PYTHONHASHSEED=0` (SingleThreadedRunner iterates a set of prompted names).

## Decisions log (unattended run; conservative choices)
- Clone: reused the hunt clone `worktrees/eventsourcing-h42` (HEAD = BASE). Docker context is a fresh
  local clone at BASE (`worktrees/eventsourcing-h42-clean`, with .git) so the image matches what the
  platform builds.
- Dockerfile: the repo's `.dockerignore` drops README.md (poetry-core needs it for `pip install -e .`)
  plus AUTHORS/dev/.github, so the Dockerfile runs `git checkout -- .` after COPY. Warm build 42 s.
- Docstrings: the repo docstrings public classes/methods in persistence.py and system.py, so the new
  public ones carry one short docstring each; no inline comments anywhere; tests have none.
- `ProcessRecorder.select_steps` is abstract (all three in-repo backends implement it). Third-party
  subclasses outside the repo would need it too; kept abstract to match the ABC style.
- The ledger API (`ProcessingStep`, `select_steps`) is NOT named in meta.md and no test calls it:
  storage is the agent's choice; only System-level behaviour is pinned (keeps the F-47 discovery).
- Tests drive `follow` + `pull_and_process` on unstarted runners wherever two leaders feed a
  follower; started runners are used only where one prompt is pending at a time.
- meta.md defines the cut exactly (steps incl. no-op steps and untracked saves, longest prefix,
  greatest cut for loops) and the fork (original ids, processed positions as tracking, cut agreement,
  continuation, non-empty target refused, SQLite reopen). 412 body words (trimmed 2026-10-03, see below).
- Disk: / had 7.2G free (below the generic 8G line) but every build lands on /var/lib/docker (28G
  free); the orchestrator's stop line for / is 2G. No pip install outside Docker.

## FINISH plan (after a clean precheck)
- Levers from the full spike: snapshots in the fork (a snapshot taken after the cut must not reach the
  fork), `notification_log(cls)` as at the cut; state both in meta.md.
- More F-10 cells: SQLite no-op step after reopen x follower bound; untracked save inside a loop x
  fixed point; fork continuation where processed < leader position on SQLite; `NewSingleThreadedRunner`
  fork keeps its class; created-after-cut aggregates on followers.
- Consider a guard for databases written before the ledger existed (L84 old-format probe).
- Mutation battery (per branch, base and new mode) + feature-stub + assertion-flip; FP audit of every
  meta sentence; replay-ready.

## meta.md trim (2026-10-03, length check: FAIL > 400)
Was 434 words (wc -w, 412 body), so it would FAIL the length check. Now 304 body words / 326 with
frontmatter (warn band 201-400, which passes). Old text kept at
`worktrees/eventsourcing-h42-scratch/meta.v1-434w.md`. Changes:
- Dropped the "today a follower only tracks..." preamble (current-state narration, also an AI-gate tell).
- `fork(env)` became `fork(env=None)`: the TestFork tests call `.fork()` with no argument, so the
  old signature left that call undocumented.
- "reducing positions only as far as the rules force" folded into "greatest cut that meets these rules".
- SQLite sentence and fork sentences compressed; register moved to "we"/explanatory.
- Pangram API still HTTP 402 (no credits), so not scored locally.

Rule checklist (one line per tested rule; verify again after any humanizer pass):
1. `cut(bounds=None)` on every runner; bounds = app name -> notification id.
2. Unknown name or negative id -> ValueError.
3. `positions`: EVERY app in the system -> id at the cut, 0 when none.
4. `processed`: every follower -> each leader -> highest processed id, 0 when none.
5. `get(cls, aggregate_id)` = aggregate as at the cut; AggregateNotFoundError if not yet created.
6. A processing step that records nothing is still a step; a save outside processing is a step.
7. Longest prefix of steps: no event above the app's own bound, no step processed above the leader's cut position.
8. App position = highest kept notification id.
9. Loops: greatest cut satisfying the rules.
10. `fork(env=None)`: new STARTED runner of the SAME class, built with env.
11. Fork holds kept events under ORIGINAL notification ids (copied, not reprocessed) and tracking = processed.
12. Cuts of the fork == cuts of the original with the fork's bounds added.
13. New events in the fork: processing continues from each follower's processed position.
14. fork raises ValueError if any target app already has events.
15. Reopened SQLite runner computes the same cuts.

## Precheck round 1 (2026-10-03): scope gate PASSED, problem claimed; Rebuild check FAILED
Platform: "The image failed to rebuild from your committed source (at `RUN git config --system --add
safe.directory /app`)". Reproduced locally by building from a `git archive` snapshot (no `.git` in the
context): `git checkout -- .` exits 128, "not a git repository". So the platform's rebuild context
has no `.git`, and the old Dockerfile depended on it twice: the checkout, and `pip install -e .`
(poetry-core needs README.md, which the repo's `.dockerignore` drops).
Fix (Dockerfile only; old copy in `worktrees/eventsourcing-h42-scratch/Dockerfile.v1`):
- `if [ -d .git ]; then git checkout -- .; fi` keeps the clean `git status` when `.git` is there.
- No package install: `ENV PYTHONPATH=/app` plus the deps installed directly (typing_extensions and the
  test extras), pinned to the versions that resolved on 2026-10-03. test.sh already runs
  `python -m pytest` from /app.
- safe.directory '*' instead of /app.
Validated both contexts (no-git snapshot and fresh clone at BASE), uid 1000, --network none.

Flakiness found during that validation (machine loaded by 4 other sessions' containers): base mode
failed 4/1/2/0 runs in the no-git image and 1/0/0/0 in the git one. Names, from 5 normal + 4 stressed
runs (`--cpus=1` plus two CPU burners):
- `test_concurrent_no_conflicts` (SQLite recorders): "Timed out waiting for connection pool semaphore".
- `TestMultiThreadedRunnerWithSQLiteFileBased::{test_catches_up_with_outstanding_notifications,
  test_system_with_one_edge, test_system_with_two_edges}`: every MultiThreadedRunner test waits for
  its threads with a fixed `sleep(0.3)` (`wait_for_runner`), so all variants share the mechanism.
Excluded in base mode with `-k "... and not MultiThreadedRunner and not test_concurrent_no_conflicts"`.
A stressed re-check then HUNG (18 min, pytest at 9 s CPU) in
`TestPOPOApplicationRecorder::test_subscribe_concurrent_reading_and_writing`: writer + subscription
reader on two threads, the reader blocks forever under starvation (lost wakeup in the POPO
subscription, base code, no solution applied). A hang gives the grader no XML, so it is excluded too
(`and not test_subscribe_concurrent_reading_and_writing`). After that: 3 stressed runs, 502 cases,
0 failures, identical.
Base mode is now 502 cases (was 567). The feature is exercised through SingleThreadedRunner, which
stays in. test.patch regenerated from `git diff --cached` (test.sh index 0328132a); old copy in
`worktrees/eventsourcing-h42-scratch/test.patch.v1`.
Final (no-git image): F2P 17/17 fail without the solution; with it new 17/17 pass x3, base 503 pass
x3 (also 503/0 without it); after the subscribe exclusion, stressed base 502/0 x3; uid 0 and 4242 new mode 17 fail / 0 fail.

## Precheck round 2 (2026-10-04): "Python installs are editable or test invocation is documented" FAILED
Raw Output `installMode: deps_only`, `testInvocationDocumented: false`. The round-1 fix (deps + PYTHONPATH,
no package install) tripped this new check. Fixed in the Dockerfile, not meta.md (keeps the word count):
editable install is back as `pip install --no-deps -e .` after the pinned deps, preceded by
`if [ ! -f README.md ]; then touch README.md; fi` (poetry-core needs the readme; `.dockerignore` drops it
and the no-.git rebuild cannot restore it). PYTHONPATH removed. Both contexts build; `pip show` reports
`Editable project location: /app`, import from /tmp resolves to /app; `git status` in the .git context
shows only harness files (the checkout restores the real README, so the guard does nothing there).
Old Dockerfile: `worktrees/eventsourcing-h42-scratch/Dockerfile.v2`.

## Precheck round 3 (2026-10-04): Task Prompt Quality FAIL, ai_generated (fractionAi 1.0, wordCount 294)
Flagged window: the first sentence. `verdictBasis.dropped` exempted "Every runner will get a cut(bounds=None)
method" as test-pinned. User ran the body through the humanizer; I diffed it against the 15-rule
checklist, kept its wording elsewhere, fixed U+201A/U+2024 look-alike punctuation to ASCII, restored
backticks on API names. Drifted sentences repaired:
- Opening: "fork off a new instance ... configured the same way as another system" (wrong: the fork holds
  the state at the cut, and "read" was lost) -> consistent cuts to read or fork as at one point.
- positions lost its "0 if none" (only "also" hinted) -> restored (rule 3).
- processed: "all adjacent followers ... each adjacent leader" -> every follower / each of its leaders,
  plus "at the cut" (rule 4).
- get: "if no such aggregate exists" (reads as now) -> "did not exist yet at the cut" (rule 5); also
  said which object has get.
- steps: "other state transitions outside the leader processing" -> each save of new events outside
  leader processing (rule 6).
- prefix: "no event affecting the application state has a higher cutoff" -> no recorded event above the
  app's bound; leader side -> above the leader's own position in the cut (rule 7).
- INVERTED: "cutoff is the highest id of any processed leader event" -> highest notification id among
  the events the app keeps (rule 8).
- fork: "started" was dropped (test asserts is_started) -> restored; "same notification ID as an event
  in the original cut" -> every kept event under its original notification ID (rules 10, 11).
- continuation: "where they left off in the original runner" -> where the cut left them (rule 13).
- non-empty target: added "already" (rule 14).
Then trimmed 402 -> ~379 body words (over the 400 FAIL line otherwise), cutting my repair phrases
first; dropped "We model application state transitions as steps." Old text:
`worktrees/eventsourcing-h42-scratch/meta.v2-304w-flagged.md`.

## Precheck round 4 (2026-10-04): Task Prompt Quality PASSED; Solution Quality FAILED (1/3 comprehensiveness, 2/3 code quality)
Reviewer issues (all real, all fixed in the reference; meta.md unchanged):
1. Ordinary saves split into steps: SystemCut faked one step per notification for non-process
   recorders, so `save(a, b)` with a bound between its ids kept half the save. FIX: the step ledger
   moved from ProcessRecorder to ApplicationRecorder (`select_steps`, plus `restore_step`, both
   abstract on ApplicationRecorder; RecordedStep replaces ProcessingStep). POPO/SQLite/Postgres record a
   step for every insert that has events or tracking. Steps store the exact id list (SQLite TEXT,
   Postgres bigint[]), not a first..last range (the Postgres db function does not lock, so ids in one
   save need not be contiguous).
2. Postgres POSTGRES_ENABLE_DB_FUNCTIONS path skipped steps AND tracking (tracking loss is a base bug
   on that path). FIX: that branch now runs in one transaction: lock table, `_insert_events` (tracking for
   process recorders), the function, `_insert_step`.
3. Fork assigned fresh ids, so a Postgres source with sequence gaps forked to 1,2 instead of 1,3. FIX:
   `restore_step` inserts at explicit ids (SQLite rowid, Postgres notification_id + setval on the serial
   sequence, POPO pads gaps with None placeholders that select_notifications skips) and refuses ids at
   or below the current maximum.
Also: Postgres steps table name = events table name truncated to 57 + "_steps" (a 63-char events table
name in the repo's own tests overflowed the identifier limit; Postgres would truncate it back onto the
events table name).

Advisory coverage suggestions, all added as tests (25 now, was 17): multi-event save with a bound
inside it (leader and follower step), fork of a save, fork-cut equivalence on the cyclic Ping/Pong
system, a target env where exactly one app has events, NewSingleThreadedRunner cut+fork,
MultiThreadedRunner/NewMultiThreadedRunner cut + fork class/started (no thread-timing assertions).
Test domain now uses explicit frozen event classes + generics so the repo's mypy/pyright stay clean.

Validation this round:
- Repo lint at poetry.lock pins (black 26.5.1, ruff 0.16.3, isort 8.0.1, mypy 2.3.1, pyright 1.1.411):
  base clean; patched clean on all five (incl. the test file).
- Postgres 16 in Docker (`--network container:es-pg`): probe of cuts/processed/get/fork/continuation,
  multi-event save, loop, gapped-source fork into Postgres and into POPO (ids 1,2,4 then next 5), with
  db functions off and on: 46/46. With db functions every app needs its own schema (base limitation:
  one `es_insert_events_<type>` function per schema, CREATE OR REPLACE by the last app wins).
- Repo Postgres suite (`-k postgres`, dcb excluded, pytest-timeout 60 s), base vs patched: both 254 passed /
  24 failed with the IDENTICAL failure set (LISTEN/NOTIFY subscription and projection tests time out in
  this container, plus test_get_password_func; all fail on base too). No regression.
- Platform-style (no-git image, uid 1000, --network none): F2P 25/25; base 502/0 and new 25/0 x3 with the
  solution; uid 0 and 4242 25 fail / 0 fail; stressed (--cpus=1 + 2 burners) new x10 and base x2 clean.
LOC: 344 human-effective (was 234), padding-floor 186; 5 files.

## Precheck round 5 (2026-10-04): Rebuild check FAILED again; Solution Quality FAILED (custom recorder state)
Rebuild: "failed to rebuild ... (at `RUN git config --system --add safe.directory '*' \`)" with the
round-2 Dockerfile (guarded `if [ -d .git ]; then git checkout -- .; fi` inside one chained RUN).
Diagnosis by reproduction: a context whose `.git` is present but INCOMPLETE (objects missing, e.g. a
partial clone) makes `git checkout -- .` rewrite every file (COPY changed the stat info), unlink each
one and then fail to read its blob: pyproject.toml is deleted and `pip install -e .` fails. That
explains both rebuild failures (round 1 unguarded, round 2 guarded). Fix (old file in
`worktrees/eventsourcing-h42-scratch/Dockerfile.v3`):
- Separate RUN steps, so the next platform error names the exact step.
- All network installs (pinned deps + poetry-core 2.5.0) BEFORE `COPY`; after COPY nothing needs the
  network (`pip install --no-deps --no-build-isolation -e .`).
- Restore only MISSING tracked files: `git ls-files --deleted -z | xargs -0 -r git checkout -- || true`;
  present files are never rewritten. README guard kept.
Built OK from 4 contexts: git archive (no .git), fresh clone at BASE (git status shows only the
Dockerfile; real README/AUTHORS restored), archive + both patches, clone with an emptied objects dir
(tree intact, editable install works). Editable location /app in all four.

Solution Quality: fork restored events + tracking only, so a follower whose recorder keeps extra state
from save kwargs (examples/ftsprocess FtsProcess + SQLiteFtsProcessRecorder: `insert_pages` /
`update_pages`) lost its FTS rows; the fork's search differed and a later Page.BodyUpdated failed in
select_page. FIX: `restore_step(step, stored_events, **kwargs)` passes kwargs through to each backend's
`_insert_events` (custom recorders read them there), and SystemCut.fork recomputes them: for a step with
tracking on a Follower it re-runs the follower's policy in the fork (every earlier step already
restored) on the original leader event decoded with the leader's mapper, and keeps only
`processing_event.saved_kwargs`; the events written are still the original stored events at their
original ids. New test `TestForkOfFollowerRecorderState` (ContentManagementSystem, SQLite FTS recorder):
fork search equals the cut, a later page not indexed, a body update after the fork is processed.
Mutation: with the replay disabled the test fails (`[] != [UUID(...)]`). Postgres FTS recorder fork
probe 3/3; earlier 46-check Postgres probe still 0 failures. Lint (5 tools at lock pins) clean.
LOC 377 human-effective. meta.md unchanged (fork "holds exactly the state at the cut" covers it).

## Precheck round 6 (2026-10-05): Solution Quality FAILED (1/3; code quality now 3/3)
Issue: fork dropped auxiliary recorder state from ORDINARY saves (only follower policy replay existed):
FtsContentManagement in a one-node System loses its FTS rows; SearchableTimestampsApplication's SQLite
recorder raises KeyError on `event_timestamps_data` during restore. The reviewer also called policy
replay deterministic-only.
FIX (persisted step metadata, the option the reviewer named):
- RecordedStep gains `kwargs` (dict, or None when they could not be kept). Every backend stores each
  step's recorder keyword arguments minus `tracking`/`notification_ids`: POPO keeps the dict, SQLite a
  `kwargs BLOB`, Postgres `kwargs bytea`, via `encode_step_kwargs`/`decode_step_kwargs` in
  persistence.py (pickle; NULL when there are none; b"" when unpicklable -> None). `pickle.loads`
  carries `# noqa: S301` (the repo's ruff selects ALL; it uses noqa 19x, incl. S311).
- `restore_step(step, stored_events)` replays `step.kwargs` into `_insert_events`, so custom recorders
  rebuild their state exactly as written; the fork's own ledger keeps the kwargs (fork of a fork works).
- SQLite now records the step in an `insert_events` override, AFTER `_insert_events`, because subclass
  overrides consume their keyword-only kwargs (SQLiteFtsApplicationRecorder takes insert_pages before
  calling super). Postgres already recorded at the insert_events level.
- Policy replay removed. `fork` raises ProgrammingError before creating anything if a kept step's
  kwargs could not be stored.
Tests 26 -> 28: FtsContentManagement one-node fork (search at the cut, fork of the fork) and
SearchableTimestamps one-node fork (point-in-time reads at both kept timestamps, version 2). Mutation:
dropping stored kwargs fails all 3 recorder-state tests. Postgres: follower FTS 3/3, FTS app 2/2,
searchable timestamps 3/3; 46-check probe 0 failures. Repo Postgres suite: 252 pass / 26 fail = base's
24 plus 2 MultiThreadedRunnerWithPostgres tests (sleep(0.3) waits, run under load); both passed on 2
reruns, so treated as flaky. Lint clean. LOC 403 human-effective.


## Precheck round 7 (2026-10-05): Solution Quality FAILED (1/3 + code quality 1/3)
Issues: (1) pickle for step metadata is unsafe deserialization (and the reviewer says S403 fires; ruff
0.16.3 here reports that noqa as unused, so S403 does not fire, but pickle is gone anyway); (2) an
unpicklable but IGNORED kwarg (`app.save(agg, unused=lambda: None)` on SQLite) made fork raise
ProgrammingError, an undocumented failure for a valid save.
FIX (recorder-owned, safe step state):
- No pickle. `ApplicationRecorder` gets `encode_step_state(**kwargs) -> dict | None` (JSON-compatible
  state the recorder needs to restore a recording; base: None, so unknown kwargs are ignored exactly as
  the base recorders ignore them) and `decode_step_state(state) -> kwargs` (base: {}), plus
  `step_kwargs(step)` and JSON text helpers. RecordedStep.kwargs -> `state`. SQLite `state TEXT`,
  Postgres `state text`, POPO keeps the dict; all via json.
- The examples own their state: `FtsRecorder` (shared by the SQLite and Postgres FTS recorders, so a fork
  may change backend) encodes insert_pages/update_pages as string rows and decodes PageInfo;
  `SearchableTimestampsRecorder` encodes event_timestamps_data as [uuid, isoformat, version] (always,
  even empty, since its SQLite recorder requires the key).
- The fork's ProgrammingError path is removed.
Tests 28 -> 29: SQLite save with `unused=lambda: None`, fork holds the event. Full `make lint` scope
(eventsourcing tests examples): black/ruff/isort/mypy clean; pyright's 6 errors are missing optional
packages (pytest_benchmark, eventsourcing_umadb) and identical on base. Postgres: follower FTS 3/3, FTS
app 2/2, timestamps 3/3, 46-check probe 0 failures. LOC 414 human-effective, 7 files (5 library + 2
examples).

## Precheck round 8 (2026-10-05): Solution Quality FAILED on a FALSE claim (no code change)
Claim: Postgres `_insert_step` runs after `conn.transaction()` exits, so a no-op step's LOCK TABLE runs in
autocommit and fails. False: in solution.patch the call sits inside `with conn.pipeline() as pipeline,
conn.transaction():` (postgres.py ~704-725, indented under it). Real Postgres 16, db functions off:
`insert_events([], tracking=Tracking("Leader", 1))` twice -> max_tracking_id 2, select_steps returns both
tracking-only steps. Earlier 46-check probe also covered no-op steps. Contest with this evidence.

## Batch 1 + meta change (2026-10-05)
0/10 Nova, all on the 3 recorder-state tests (see eval-results.md). meta.md gets one explicit sentence:
"Some recorders keep extra data beside the events, like a search index built from each save's keyword
arguments, and the fork holds that data as it was at the cut too." Trimmed the SQLite and agreement
sentences to stay at 395 words. Old text: worktrees/eventsourcing-h42-scratch/meta.v3-batch1.md.
Needs Task Prompt Quality again, then a full batch (description change, no re-eval).

## Auto Review (2026-10-06): Revision Requested, Tests 1/3 (description 3/3, solution 3/3)
T3/T4 High x2: the threaded-runner fork test only checked type + started, so an empty started
MultiThreadedRunner/NewMultiThreadedRunner fork would pass. FIX (tests only): assert Left/Right/Merge
notification prefixes and fork.cut().positions/processed == the source cut for both threaded runners
(the cut leaves no outstanding work, so the threaded forks have nothing to catch up on: deterministic).
Advisory added too: cut() without bounds + both ValueError cases on all four runner classes. 30 tests:
30/30 fail on base, pass x3, stressed (--cpus=1 + 2 burners) x3 clean, lint clean.

## Harden diagnosis (2026-10-11, after batch 4: Nova 1/4)
Differential fuzz (worktrees/_es_fuzz: random save/pull interleavings on FAN_IN/CHAIN/LOOP/SPAWN x
POPO/SQLite/reopened SQLite, ~4 random-bound cuts each, get() on every aggregate, fork with fork-cut vs
combined-bounds agreement, a post-fork event, cut of the fork): 87 scenarios, Nova_1 (passer) and
Nova_4 (lambda-only near-miss) diverge from the reference in 0. The stated surface is exhausted
(L83): no test on a stated rule can separate them. Nova's only current killer is the lambda-kwargs test,
which is an UNSTATED rule (8/11 in batch 3), so it cannot be kept as difficulty. Remaining levers are new
scope (fork carries snapshots up to the cut; notification log as at the cut), both transcribable and
untested against Nova. Recommendation: shelve unless the user wants one more paid round on new scope.

## Attempt history
- 2026-09-30 SLICE: spike measured (232 core / 269 full), gates clean, slice validated. No batch.
- 2026-10-05: precheck 7: pickle replaced by recorder-owned JSON step state (examples implement it), no fork refusal for ignored kwargs; 29 tests.
- 2026-10-05: precheck 6: Solution Quality wanted ordinary-save recorder state on fork; step ledger now persists recorder kwargs and restore replays them; 28 tests.
- 2026-10-04: precheck 5: Rebuild failed again (incomplete .git + checkout deletes the tree), Dockerfile split + missing-files-only restore; Solution Quality: fork now recomputes follower recorder kwargs by policy replay, FTS regression test (26 tests).
- 2026-10-04: precheck 4: Task Prompt Quality passed; Solution Quality failed on 3 real gaps; reference reworked (ledger on every app recorder, db-function path, explicit-id restore), 8 tests added.
- 2026-10-04: precheck 3: Task Prompt Quality FAIL (ai_generated); humanizer text adopted with 10 drift repairs.
- 2026-10-04: precheck 2: editable-install check failed (deps_only); Dockerfile back to `pip install -e .` with a README guard.
- 2026-10-03: precheck 1: scope gate passed (claimed); Rebuild check failed (no .git in rebuild context). Dockerfile fixed, flaky base tests excluded.
- 2026-10-03: meta.md trimmed 434 -> 326 words (304 body) for the length check; `fork(env=None)` fixed. No batch.
