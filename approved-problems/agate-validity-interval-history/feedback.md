# feedback — agate-validity-interval-history

## Status
Auto Review round 2 fixed (row names). FP rounds 2-4 fixed (index-key resolution, interleaved-key join order, index-key fixture). Ready to resubmit.

## Summary
`wireservice/agate` at `7aa490cb`. New `agate/history.py` kernel plus eleven `Table` methods, a
`Coverage` aggregation and the matching `TableSet` proxies, all built around half-open validity
intervals. 1077 raw / 464 human-effective LOC over 17 files, 249 F2P tests.

## Gate results
| gate | result |
|---|---|
| stars / license / language | 1199, MIT, Python |
| activity | 9 source commits in trailing 12 months, HEAD is the base commit |
| exclusivity (PR diff, all states) | zero hits on temporal / interval / history / snapshot / validity |
| maintainer philosophy (closed issues) | nothing declined in this space |
| local dedup | no agate folder anywhere, no validity-interval feature in any repo |
| vanilla suite offline, uid 1000 | 396 passed, ~1.2 s |
| flakiness | base and new identical over 5 local and 3 container runs |
| both patch orders | clean |
| F2P | 187 of 187 JUnit nodes fail on base |
| effective LOC | 454 (hook `human-effective`) |
| comments in patches | none added; agate documents public functions with docstrings, which is what the new code carries |
| flake8 / isort | clean under the repo's own setup.cfg |

## False positive work
48 mutations of the reference were run through the new suite, one per stated rule, and every one
was killed. The battery is `mutate.py` at the task root. Two findings changed the artifact:

- `later_end` was dead. Its only caller checked for an overlap before the value could matter, so
  the mutation that inverted its null handling survived. The helper is gone and
  `validate_no_overlaps` now compares each row against the previous one directly.
- `history_overlaps` emitted pairs in enumeration order, which is not sorted by start once a key
  has four or more intervals, so the description's ordering rule would have been false in a case
  no test covered. The output is now sorted and a four-interval test pins it.

The description was then walked assertion by assertion. Four rules that tests enforced were
missing from it and have been added: the collision error for a column a method creates, the
exception classes for `to_history`'s effective column and for `join_history`'s key and type
mismatches, the null window start, and the fact that `coalesce_history` / `flatten_history` /
`split_history` / `clip_history` return the columns they were given unchanged. Two ordering rules
that were only implied (the `inner=False` remainder, the `history_events` moment) are now stated.

## Deviations
- meta.md is 850 words, over the nominal 500. Eleven entry points plus an aggregation each carry
  tested rules, and the alignment check errors on an unnamed API surface. Precedent:
  mido-timeline-editing shipped at 859 words for eleven entry points, dasel-aggregation-functions
  at 309. Cutting to 500 means dropping a described-and-tested behavior, which trades a length
  complaint for a Test Fairness failure. The alternative is cutting scope on all three sides at a
  cost of roughly 120 effective LOC.
- The Dockerfile installs things the base image lacks: `locales` with en_US, de_DE, fr_FR and
  ko_KR generated, `tzdata`, and `lxml` plus `cssselect`. All of them are needed by the repo's own
  suite, not by the new tests, and without them Environment Quality sees 8 failures and 36
  collection errors. Every pip package is pinned and apt runs non-interactively with a fixed TZ.
  There is no install or build step: agate imports from `/app` through `PYTHONPATH`, so
  `pip install -e .` is not used, and meta.md names the test command instead, since the two
  platform checks disagree here and the editable install is what broke the image rebuild.

## Test Fairness rounds

**Round 1 — FAIL, 10 of 176 unfair**, all one cause: `history_at` casts a string instant, and
meta.md promised that casting only for `split_history` and `clip_history`. The behavior was right
and the tests were right; the description was wrong. The casting rule is now stated once as a
shared convention covering every method that takes an instant, and the two per-method mentions are
gone. No test changed.

Three of the four coverage suggestions were taken. The Coverage-on-an-empty-table case was not: it
would pin a zero-versus-null choice the description does not make, which is the same class of
unstated pin that caused the failure. Added key-by-index and empty-table schema on
`coalesce_history` and `history_gaps`, plus `TableSet` proxy tests for `history_gaps`,
`history_overlaps`, `history_spans`, `history_events` and `join_history`. 167 tests became 176.

**Round 2 — PASS**, three coverage suggestions, all taken, and one of them found a real defect. The
suggestion asked for a `join_history` test asserting a `ValueError` when the right table uses
different interval column names. It did not: the right table's column lookup raised `KeyError` from
agate's own `MappedSequence`. The presence check now covers the interval columns as well as the key
columns, so the error the description promises is the error that comes out, and meta.md folds both
into one clause. The other two were pure coverage: DateTime string boundaries for `split_history`
and `clip_history` plus a DateTime union for `Coverage`, and the `Coverage` validation edges (null
start, empty interval, mismatched Date/DateTime bounds). 176 tests became 183 and the mutation
battery grew to 42.

**Round 3 — PASS**, three coverage suggestions, all taken, no artifact change needed. `join_history`
now has a case where the overlapping right rows are deliberately out of chronological order, so the
left-then-right ordering rule is tested on its own rather than riding on chronological input. The
`inner=False` path has a case where two right rows overlap each other, pinning that each pair still
emits its own row while the remainders subtract the union, leaving one piece on each side with no
duplicate or reversed fragment. `clip_history` gained a shuffled column order with custom interval
names, and `history_events` a DateTime case with custom names on all three columns. 183 tests
became 187.

**Round 4 — PASS**, three coverage suggestions, all taken. Two were coverage of stated rules: a new
`TestIntervalValidation` class asserts every entry point rejects Number bounds and mismatched
Date/DateTime bounds, rather than leaning on `coalesce_history` and `Coverage` to stand in for the
rest, and `to_history` now has collision tests for the default `valid_to` name and for custom
start/end names. The third asked for `Coverage` on an empty table to be specified as well as
tested, so meta.md now says it is zero, matching what agate's own `Sum` does with an empty column.
187 tests became 199.

**Round 5 — PASS**, three coverage suggestions, all taken, all coverage of stated rules with no
artifact change. `join_history` gained a successful DateTime pair plus a DateTime `inner=False`
case that pins the exact intersection and both remainder timestamps, and a numeric key index.
`history_gaps`, `history_overlaps`, `history_spans` and `split_history` each gained a custom
`start_column_name`/`end_column_name` case, so every method that takes the pair is now exercised
with non-default names. 199 tests became 206.

**Round 6 — PASS**, three coverage suggestions, all taken, all coverage of stated rules with no
artifact change. A new `TestIntervalValueValidation` class runs a null start, an empty interval and
a backwards interval through every entry point including both sides of `join_history` and
`Coverage`, so the globally stated value validation is checked uniformly instead of at two methods.
Empty-table schema and type checks were added for `flatten_history`, `split_history`,
`clip_history`, `history_at`, `history_overlaps`, `history_spans`, `history_events` and
`join_history`. `history_events` gained a three-value-column case pinning that a closing event
nulls every value column and keeps their order. 206 tests became 227.

**Round 7 — PASS**, three coverage suggestions, all taken, all coverage of stated rules with no
artifact change. `flatten_history` gained a custom `opened`/`closed` case, `history_at` gained one
where two same-key intervals both cover the queried instant and both come back in input order, and
`history_gaps` and `history_overlaps` each gained a DateTime case pinning sub-day precision in
their output bounds. 227 tests became 249.

## Batch 1 and the round-8 fix

0 of 6. Every run cleared the 396 baseline tests, and all six evaluators returned
`description_clear: true`, `tests_deterministic: true`, `difficulty: challenging`, so nothing was
flagged as ambiguous. The failure table is in eval-results.md. Two causes carried the batch and
both were mine.

`Coverage()` had no default column names in 5 of 6 runs, which cost 15 tests each with a
`TypeError` at construction before a single interval was compared. The shared-conventions
paragraph gave the defaults, but the aggregation was then written as
`Coverage(start_column_name, end_column_name)`, and five agents read that signature as two
required arguments. It is now written with the defaults inline, the way `clip_history(key, start,
end=None)` and `join_history(right_table, key, inner=True)` already appear.

The `inner=False` remainder ordering was wrong in 5 of 6 runs, 5 to 7 tests each, and every one of
them made the same mistake: sorting the whole result by interval start. "Follows the rows it paired
with, in time order" reads as a rule about the output rather than about one row's leftovers. It now
says each row of this table contributes its pairs first and then its leftovers in time order.

Neither change touches a trap. The first is a signature shape that teaches nothing about intervals,
and the second is a sentence five agents read the same wrong way, which is the definition of a
prompt bug rather than difficulty. `solution.patch` and `test.patch` are unchanged.

The fix was verified by replay rather than by argument: Nova_Nova_1 and Vega_Nova, the two runs
whose only failures were Coverage, were rebuilt on the base commit with the unchanged 249-test
suite and one edit to their own code, default arguments on their `Coverage.__init__`. Both went to
249 passed. That puts the batch at 2 of 6, 33 percent, with the duplicate-instant rule, source
column order and the `ValueError`-not-`KeyError` contract still separating the rest.

## Round 8 coverage suggestions

Two suggestions, one taken in part and one taken whole. 231 tests became 249.

`history_events` gained a composite-key case where one key's interval ends exactly where its own
next interval begins while another key's ends with nothing following, proving the close event is
suppressed per key and instant rather than globally.

The join suffix suggestion asked for a chain case: a left table already holding both a name and its
"2" variant. That case is not tested and the code is unchanged, deliberately. agate's own
`Table.join` produces the identical result, a table whose column names get deduplicated to
`plan2_2` while the `Row` keys still read `plan2` twice. Pinning it would either freeze a
repo-inherited quirk as if it were this feature's contract, or force `join_history` to diverge from
the `join` whose "2" suffix convention the description borrows. The half of the suggestion that
does match the stated rule was taken: a case where two right value columns collide at once, giving
`plan2` and `tier2` alongside an uncolliding `region`.

## Round 9 coverage suggestions

Two of three taken; 233 tests became 249. `history_events` gained a DateTime round trip across a
gap, which exercises the close event, the sub-day boundaries and `to_history`'s casting in one
assertion pair. The `TableSet` class gained a malformed group, confirming a proxied
`history_gaps` and `flatten_history` raise rather than returning the groups that happened to be
well formed.

The join suffix escalation was declined for the second time, same reasoning as round 8: `join_history`
matches `Table.join` exactly here, so defining the chain means either freezing a repo-inherited
quirk or diverging from the method whose convention the description borrows. It is also the wrong
moment to add a discriminator. Batch 1 projects 2 of 6 after the meta fix, and every agent builds
its output rows from its own name list, so a uniqueness requirement would be a fresh shared failure
rather than a fair test of interval logic. The clause stays scoped to the single suffix, which is
true for every case the suite covers.

## Round 10 coverage suggestions

Two of three taken; 235 tests became 249. The better one asks what happens when a shared effective
instant carries both a real observation and an all-null one. `to_history` resolves the tie first
and only then decides whether the survivor closes or opens, so the two orderings give different
answers: a trailing null closes the running interval, and a trailing value keeps it open. Both
directions are now pinned. The `TableSet` class also forwards custom start, end, effective and
duration names through the proxies.

The join suffix chain was declined a third time on the reasoning already recorded above. Nothing
about it has changed: `join_history` matches `Table.join`, the case is unreachable through the
described API without a table that already carries a name and its "2" variant, and adding a
uniqueness rule now would introduce exactly the kind of shared failure that cost batch 1.

## Round 11 coverage suggestions

The zero-value-column suggestion found a real bug in the reference. `to_history` decided that an
observation closes the running interval with `all(value is None for value in values)`, and with no
value columns that is vacuously true for every observation, so a table of nothing but a key and an
effective column came back completely empty. The guard is now `payload_names and all(...)`. It is a
one-line change and a no-op for all 249 tests, since every one of them has at least one value
column.

No test was added for it, deliberately. The naive `all(...)` over an empty tuple is the version
most solvers would write, so pinning it would create a fresh shared failure across the field, and
batch 1 already showed what one of those costs. That was a hypothesis when it was written; the
suggestion repeated, so it was measured instead. Nova_Nova_1 wrote
`bool(observation_values) and all(...)` and returns the interval; Vega_Nova wrote the bare
`all(...)` and returns an empty table. The two runs that pass after the meta fix split exactly on
this case, so pinning it takes the batch from 2 of 6 to 1 of 6. Still solvable and still inside the
band, but a single passer is fragile, and the trade buys a corner nobody reaches for half the
margin. The description says a history has "any number of
value columns" and does not spell out what an observation with no values at all means, so nothing
is described-but-untested. The fix stands on its own as correctness: a legal input should not
silently produce an empty table. If a later batch lands with headroom under the ceiling, this is
the first discriminator worth adding.

The join suffix chain was declined a fourth time; the reasoning above is unchanged.

## Auto Review round 1 and the FP report

Revision Requested on one blocking item, plus a minor description note. Tests scored 3/3 in three
of the four passes. The batch was 3 of 10 with every failure inside the feature and the baseline
green in all ten, which the reviewers read as difficulty rather than unfairness.

**S1, the blocker: added-column collision validation checked a subset of the schema.** The
description says a method raises `ValueError` when given a name for a column it adds that the table
already uses. The reference validated against only the columns it kept, so
`to_history(start_column_name='effective')`, `history_events(effective_column_name='valid_from')`
and `history_spans(duration_column_name='plan')` were all accepted. Reproduced all three, then
fixed: every call site now validates against `self._column_names`, and the shared helper also
rejects two added names that collide with each other. Three regression tests were added and three
mutations cover the old subsets.

Adding those tests was safe rather than a guess. Both replayed agent patches already rejected all
three collisions before the fix, because validating against the whole schema is the obvious reading
and the subset version was the odd one out. Both still pass the full 249-test suite after the
change.

**P4, the description note: the motivational opener.** All four passes quoted the same sentence.
Trimmed; the file now opens on the request itself. The test-command sentence stays, since a
separate platform check requires either an editable install or a documented invocation, and the
editable install is what broke the image rebuild.

**The FP report reversed the zero-value-column decision.** Both adjudicators ruled the passes
genuine and both landed on the same point: the reference's `if payload_names and all(...)` guard is
an unstated special case, while the candidates' empty result follows the stated rule literally,
since `all([])` is True. Their condition was explicit: if the reference behavior is intended, the
prompt and the suite have to state and cover it. The cheaper resolution is to stop intending it, so
the round-11 guard is reverted and `to_history` now follows the rule as written. The reference and
the flagged candidates agree on the probe, so the dissent has nothing left to flag, no spec text is
added to a description already marked verbose, and the pass rate is untouched. This also closes the
one Medium T4 note without pinning a contested reading: the zero-value-column case is now an
ordinary consequence of the all-null rule rather than a special case.

## Round 12 coverage suggestions

Three taken, all coverage of stated rules, no artifact change. 242 tests became 249. `to_history`
now has an observation whose two value columns are both null, so the all-null close is proved on
more than one column rather than inferred from the single-value close plus the partial-null case.
`join_history` rejects a right table that renames one member of a composite key and one that drops
it. `Coverage` is exercised through a grouped aggregate where one group never ends, which pins the
`TimeDelta` column type on a null-valued group rather than only on populated finite ones.

Both replayed agent patches still pass at 249, so the additions cost no pass rate.

## Round 13 coverage suggestions

Two of three taken, both coverage of stated rules, no artifact change. 245 tests became 249.
`coalesce_history` now has three adjacent intervals where only the second value column changes,
which proves the merge compares the whole value tuple: the first pair stays split and the second
pair merges. The `TableSet` class gained an `inner=False` join, so keyword forwarding and per-group
remainders with null right-hand values are checked together rather than separately.

The join suffix chain was declined a sixth time. Both replayed agent patches still pass at 249.

## Round 14 coverage suggestions

None taken. All four ask for a decision on behavior the description does not state, and every one
was measured before answering rather than argued.

- Join collision escalation, the seventh ask for the suffix chain. Unchanged: `join_history`
  matches `Table.join` here, so defining it means freezing a repo quirk or diverging from the
  method whose convention the description borrows.
- Key type compatibility in `join_history`. Same-named key columns of different types produce zero
  matched rows and no error. The description requires the two tables to name their key columns the
  same way and says nothing about types, so either rejecting or quietly not matching is defensible.
- A null element in `boundaries`. It is dropped and the remaining boundaries still cut. The
  description resolves nulls for `history_at`'s instant and `clip_history`'s window, both of which
  raise, but says nothing for `split_history`, where a null is simply not an instant that falls
  strictly inside anything.
- `Coverage` with a missing bound column raises `KeyError`, which is exactly what agate's own `Sum`
  raises for a missing column. That is repo behavior, not this feature's contract, and an
  implementation that validated and raised `ValueError` instead would be reading the description no
  less faithfully.

The precedent for declining comes from the review itself. The Tests sub-reviewer scored the suite
3/3 in three of four passes and said in as many words that pinning an underspecified edge "would
not be a fair hidden-test addition". The FP adjudicators then flagged the one place where the
reference had resolved an ambiguity on its own, the zero-value-column guard, and that guard has
since been removed. Adding four more tests on four more unstated corners would recreate exactly the
defect that was just cleared, and each one costs pass rate on a batch already at 3 of 10.

Every behavior above is left as it is. If any of them should become a requirement, it needs a
sentence in the description first, and the description is already carrying a verbosity flag.

## Auto Review round 2 and the row-name fix

Description 3/3, Tests 3/3, Solution 1/3. The Tests reviewer also confirmed the round-14 refusals
were right: adding those four "would risk violating T5/T7 rather than close a material contract
hole". One blocking item.

**S2: `_fork` inherits row names.** `Table._fork` copies `self._row_names` when the argument is
omitted, and every history method omitted it, so reshaped output kept the source names. Both of the
reviewer's cases reproduce exactly. A two-row table named `('ended', 'active')` passed through
`history_at` returns one row still carrying both names, and that row answers to `ended` while the
name `active` addresses nothing. `split_history` on a single interval named `('one',)` returns two
rows and one name, so the second row is unreachable.

The fix follows what the repo already does. `history_at` is a filter that keeps input order, so it
now carries names across for the rows it keeps, exactly like `where`. The other ten change row
identity or cardinality, so they clear with `row_names=[]`, the same call and for the same reason as
`homogenize`. Verified across all eleven: `history_at` returns `('active',)` and the row answers to
`active`, every other method returns `None`, and a source without names still produces output
without names.

No tests were added for this, and that is the same judgement the Tests reviewer just endorsed. Row
names are not mentioned anywhere in the description, so a test would pin unstated behavior. It would
also be the heaviest discriminator in the suite: the naive `self._fork(rows)` is precisely what the
reference did, so nearly every agent would fail it and a batch at 3 of 10 would likely go to zero.
The defect is a real one worth fixing in the reference; it is not a fair thing to grade on.

**P4 Low: the test-running sentence.** Left in place. It scored band 3 and the reviewer called it
optional, and removing it re-breaks the separate platform check that demands either an editable
install or a documented invocation, which is what the sentence is there to satisfy.

The batch evidence was missing this round (`runs` was empty), so the 3 of 10 from batch 2 is still
the most recent pass-rate signal.

## FP panel round 2: the index-key join

Four panels, three genuine passes and one false positive, all four splitting on the same behavior:
`join_history(right, 0)` when the two tables put the key column at different indexes. The reference
resolved the key on the left and matched the right by name, so it joined. Three of the four sampled
candidates resolved the index in each table, saw different names, and raised. One adjudicator called
that a false positive because the prompt's contract reads by name; two called it an underspecified
edge and let the pass stand.

Both readings are defensible, which is the actual defect: the prompt never said how an index
resolves for the second table, and no test covered it. Checking agate itself did not settle it
either. `Table.join` resolves the index positionally in each table and then simply fails to match,
returning the left row with nulls rather than raising, so the repo supplies a third behavior and
neither candidate nor reference was copying it.

Resolved by picking the reading the field already implements, then stating and testing it. The key
is now resolved in each table on its own and a mismatch raises `ValueError`, which is what three of
the four candidates did; meta.md says so in one clause; and a test pins both halves, that an index
key is rejected when the columns are ordered differently and that the same join succeeds by name.
Mandating the old by-name behavior instead would have failed three of four sampled agents on a
batch already at 3 of 10, so the choice was made on measured behavior rather than on which reading
reads better.

249 tests, 48 mutations, and both replayed agent patches still pass.

## FP panel round 3: the interleaved-key join order

One false positive of four panels, high confidence, and unlike the last round it is the clean kind:
a rule the description states verbatim that no test discriminated. meta.md says "Rows follow this
table's row order and then the right table's". The candidate iterated the left table grouped by key,
so a left table holding a, b, a came out as a, a, b. The suite never caught it because the only
join-ordering test used a single key, where grouping and row order are the same thing.

Fixed by adding the discriminator rather than by touching the contract: a left table with
interleaved keys joined against matches for both, asserting the output follows the left rows. A
mutation that groups the left rows by key now reproduces the exact defect and is killed by that
test. Both replayed agent patches still pass at 249.

## FP panel round 4: a fixture that passed for the wrong reason

One false positive of three, high confidence, and this time the criticism was of the test rather
than the contract. `test_an_index_key_is_resolved_in_each_table` used a right table whose index 0
was `valid_from`, so an implementation that never compares the resolved key names still raised,
just for an unrelated reason. The rule under test was never exercised.

Verified by simulating the candidate shape, an implementation with no name comparison but with a
guard rejecting an interval column used as a key. Against the old fixture it raises "A key column
may not be an interval column" and the test passes with the bug intact; against a right table whose
index 0 is an ordinary value column it joins silently and the test fails. The fixture now uses the
second shape, and a mutation that compares key counts instead of names is killed by it.

The lesson is worth keeping separate from the fix: an `assertRaises` only tests what you think it
tests if the case cannot raise for any other reason. Two panels returned genuine passes this round,
their only notes being the `history_overlaps` tie-break among rows sharing a start instant, null
`split_history` boundaries, and zero-value-column `to_history`. All three stay unstated and
untested.

The other three panels returned genuine passes. Their only note was that the candidates drop
`row_names` in `history_at` while the reference preserved them, which both adjudicators dismissed as
not prompt-grounded. That divergence came from the round-2 fix, where preserving was one of three
options the Auto Review offered and clearing was another. `history_at` now clears like the other ten
methods: it satisfies the same finding, makes all eleven uniform, and removes a divergence two
panels spent effort on. The zero-value-column and null-boundary notes stay untested, as before.

## Open risks
- The 33 percent projection is a replay, not a batch. The two fixes should also convert some of the
  four runs that failed on more than Coverage, so a fresh batch could land higher than 33 percent.
  It has room before the 40 percent ceiling, but if it goes over, the lever is the `to_history`
  duplicate-instant sentence, which is the discriminator three runs already miss.
- Seven rounds of coverage suggestions grew the suite from 167 to 249 tests against a reference
  unchanged since round 2, and the mutation battery has found nothing new since round 1. Batch 1
  confirms the suite is not the weak point: the failures were all real, and the two that mattered
  were description defects the suggestions could not see.
