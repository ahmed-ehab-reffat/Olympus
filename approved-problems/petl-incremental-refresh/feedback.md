# feedback.md — petl-incremental-refresh

## Summary

Olympus submission against `petl-developers/petl` at `aa03e269637d6b5abf21d71180cb37f687a2c7cb`.
Adds `petl.incremental`: an append-only `feed` source plus a materialized pipeline that updates
its output from newly appended rows only, with a delta record, per-node emission counts and a
plan listing.

## Pick record (autonomous discovery)

Repo is brand new to this corpus: `petl` appears in no `problems/`, `rejected/`, `_shelved/`,
`Aprroved/` or `worktrees/` entry. Candidates ranked and rejected before it, each on a gate:

| candidate | killed by |
| --- | --- |
| coin-or/pulp presolve + postsolve | repo is mid-migration to a Rust core (4.0.0a12, maturin build); moving target |
| msiemens/tinydb query index | exclusivity — closed PRs #607 and #611 publish B-tree index diffs |
| python-poetry/tomlkit style-preserving merge | maintainer declined deep merging in issue #330 ("We are not going to expose such helpers") |
| pyroomacoustics reflection attribution | test suite pulls mir_eval, sounddevice, python-sofa and downloads SOFA data; Env Quality is offline |
| pytransitions/transitions reachability report | last commit 2025-09; activity gate is borderline |
| PyBaMM | monorepo with a C++/CMake solver package; heavy image, slow suite |

## Pick gates

| Gate | Result |
| --- | --- |
| 1 behavioral F2P gap | PASS - petl re-derives every row on every iteration; nothing in the tree keeps state between evaluations |
| 2 saturation | PASS - no public sibling adds incremental maintenance to petl; the concept exists in databases, the contract here is petl's own row order |
| 3 uniform wrap | PASS - six traps, three of them funnelling through the same delta kernel |
| 4 LOC ceiling | PASS - the whole engine is missing, so the floor is not the binding constraint |
| 5 cold not live | PASS - open issues are CI and packaging; no commit touches evaluation strategy |
| 6 reproduce on base | n/a (additive capability) |
| 7 dedup | PASS - nearest neighbours are `ironcalc-incremental-recalc` (stub, scalar cell graph) and `rejected/differential-dataflow-topk-total` (one operator on an engine that already propagates deltas) |
| 7b exclusivity | PASS - canonical org is `petl-developers/petl`; PR and issue search for incremental, delta, refresh, materialize, streaming, change data capture returns nothing on this feature |
| 8 defined behavior | PASS - the contract is "equal to from-scratch evaluation", so every per-node semantic is petl's own |
| 9 no flaky repo | PASS - vanilla suite in the base image: 537 passed, 18 skipped, 2.9 s, offline |
| 10 repo quota | PASS - petl is new to the corpus |

## Assumptions logged

- Feeds are append-only. Deleting or updating rows is out of scope and not described.
- `head` is supported through `rowslice` with a single stop argument; other rowslice forms
  raise `IncrementalError`.
- Supported join forms are the inner join and the left outer join, both through `JoinView`.
- The incrementality requirement is stated behaviourally (rows read, callables applied), never
  as a complexity bound, so it stays mechanically checkable.

## Deviations to flag

- **meta.md is 601 body words**, over the nominal 200 word target. Every clause names a behaviour
  the tests assert, and the delivered precedents run 519 (pandapower) and 528 (pydicom). The
  contract itself is short - the refreshed output equals a from-scratch evaluation, so no per
  transform semantics are restated - but the API surface (feed, pipeline, refresh record,
  checkpoint, node ids, plan text) has to be named or the tests become hidden requirements.
- **The reference re-applies a node's own transform to already materialized child rows** rather
  than deriving positional deltas. That is what the contract asks for: no feed is read twice and no
  caller-supplied callable runs twice. The nodes that own user callables (select, addfield,
  convert, aggregate) and the two keyed nodes (join, aggregate) do keep real per-row and per-key
  state; ordering-only nodes (sort, distinct, head, cat) derive their output from their child's
  current rows.
- **Feed rows read by a refresh that later raises are counted twice.** Rollback restores the
  cursor, so the retry hands the rows out again, and `rows_read` counts rows handed out. The retry
  test pins this.

## Attempt history

### Round 1 (authoring)

- Designed, implemented and validated locally and in the image. Not yet evaluated by agents.
- 5 new files plus 2 modified, 518 human-effective LOC, 134 F2P tests.
- End to end replay of the platform order inside the image: base 555 pass, new 109 fail on base
  (each reported individually, no collection error), new 109 pass after the solution patch, base
  still 555 pass. Both patch orders apply and unapply.
- Differential oracle: 1200 randomly generated expressions (depth 1-5 over two feeds, including
  diamonds where one feed feeds both sides of a join or a cat) each refreshed several times and
  compared against a from-scratch evaluation of the same expression over static tables. Zero
  mismatches.
- Trap proof: 24 divergent implementations, all killed (see `eval-results.md`). One survived the
  first pass and was closed by strengthening the atomicity test rather than by adding a rule.
- Fairness sweep after the mutation round found two hidden requirements and fixed the description:
  `plan()` returning a string (a list of lines would also have satisfied "one line per node") and
  the checkpoint holding the plan text under `plan`.

### Round 2 (alignment review)

- The AI alignment check returned "problem and tests aligned" with two interface warnings, both
  genuine hidden requirements. Fixed in the description, never in the tests: the plan line joins
  child ids with a comma and a space, and `emitted` carries an entry for every node on every
  refresh, zero included. Mutants M20 and M21 now guard both sentences.
- All three coverage suggestions taken: `removed` ordering with duplicates in the previous output's
  order (M19 guards it), the physical read count of a feed reached by two branches, and a
  checkpoint carried across a pipeline holding cat, distinct, head, addfield, convert and leftjoin
  at once. 91 tests to 94; full matrix and flakiness re-run after the change.
### Round 18 (hint for the duplicate-order rule)

- The rule that four Nova runs died on now carries the clarification outright. It read "reports a
  row WHILE the new output still holds more copies of it than the old one did", which leans on
  "while" to carry a running surplus; a reader who ignored the neighbouring sentences could have
  reported every copy. It now reads: "`added` reports a row once for every copy the new output
  holds beyond the old one, taking those copies in the order the new output holds them, so the
  earliest copies are the ones reported and a later copy of a row already reported is passed over".
  Count, order and the skip are each stated on their own.
- Both wordings were checked against the code rather than eyeballed: each was implemented literally
  as a separate function and compared with `bag_difference` over 20000 random old/new pairs, zero
  mismatches for both. So the change removes a possible misreading without moving the contract.
- 588 to 601 words. No test or code changed, so both patches stand.

### Round 17 (sixth suggestion round)

- All three taken (131 to 134). Unlike the previous round's suggestions these cost NO new
  requirement: every one is a loss travelling through machinery the description already fixes, which
  is exactly where the difficulty now sits and where the last three defects came from.
  * A refresh that fails with BOTH a discard and an append pending: the retry has to carry the loss
    as well as the gain, and the exact emitted pair (2 at the feed, 2 at the select) is the proof.
  * Discarding one copy of a duplicated row under `distinct`: the output must not move while another
    equal copy survives (feed emits 1, distinct 0), and only the second discard removes the row.
  * Discarding a row on one side of an inner join: every Cartesian match of that row disappears,
    the survivors keep their order, and the join emits 2 for one dropped source row.
- Mutation stays at 29 of 29; these three pass against every existing mutant, so they widen coverage
  rather than duplicating a discriminator.

### Round 16 (solvability)

The batch is the only oracle, but the evidence in hand is worth writing down, because it cuts both
ways.

For solvability: three of the four Nova runs built the whole engine and passed 108 of 109 on the
suite of the day, with 6 to 10 million prompt tokens spent and 1067 to 1304 added lines, so neither
capacity nor architecture is the ceiling. Everything added since is an extension of machinery those
solutions already had rather than a new discipline: a discard is a loss in the same delta they
already computed for a head window, a leftjoin match and an aggregate group; a chained pipeline is
one more leaf kind; retiring a copy is one line in a cache they already keyed by copy. And the one
requirement that killed all four is now mechanical.

Against it: conjunction. The suite spans about eleven requirement clusters (plan and ids, build and
staleness, feed accounting, row-wise callables, ordering nodes, keyed nodes, deltas and emitted,
atomicity, checkpoint and resume, discards, chaining) and a miss in any one fails the run. That is
the honest risk, and it cannot be measured without another batch.

What was done about it, using the one lever that does not cost difficulty: the description now names
the three surfaces the newest tests probe, without naming an algorithm. A node holds copies rather
than values, so two equal rows each carry their own result and a copy that leaves takes its result
with it. A node's input can lose rows as well as gain them, from a discard, a sliding window, an
outer join whose match arrives, or an inner pipeline. A refresh that raises leaves the same gains
and losses waiting for the one after it. A solver can still get every one of these wrong in the
doing; it can no longer fail to know the surface is there. The body is 588 words, over the nominal
cap, which the author sanctioned for this purpose.

All four coverage suggestions from this round were DECLINED, and the reason is the same in each
case: every one of them adds requirements, and conjunction is now the binding constraint.

| suggestion | why declined |
| --- | --- |
| option variants (`lkey`/`rkey`, addfield `index`, select `complement`, distinct `count`, aggregate `key=None`, cat `header`/`missing`) | a solution that rebuilds petl's own view classes inherits all of these for free, so the tests would only punish a solution that hand-rolls semantics, and would add six more ways to fail |
| malformed checkpoint validation | needs error semantics the description does not define; stating and testing them adds a cluster |
| discard index validation | the reference already raises `ArgumentError` for a position holding no row; testing it would make an unstated rule binding |
| resume against divergent feed contents | needs a source-identity contract the description does not have, and inventing one late is how unfair rules get born |

### Round 15 (fifth suggestion round)

- Both taken (129 to 131), and both land where deletions and composition meet, which is where the
  last three defects came from.
  * A checkpoint taken AFTER a discard: the resumed pipeline keeps the hole, reads nothing, and
    then takes a further append and a further discard correctly. This pins that the position map,
    not just the row list, survives the round trip.
  * An outer pipeline whose callable raises while taking in an inner gain: the outer output and
    checkpoint roll back, and the retry reports `pipeline#1: 1`, which is the proof that the failed
    attempt did not consume the inner delta.

### Round 14 (FP check: a passing agent that was not correct)

- The FP adjudicator confirmed a functional false positive against a PASSING candidate (its file is
  `petl/incremental.py`, so it is an agent solution, not the reference). Its per-occurrence result
  map keys by a token, and when ONE shared node feeds BOTH sides of a `cat`, the two branches carry
  the same token, so the later copy's result overwrites the earlier one. On an idle refresh its
  output silently changed from `[('a',1,1), ('a',1,2)]` to `[('a',1,2), ('a',1,2)]` and it reported
  spurious added and removed rows.
- That is the environment's fault, not the agent's: the suite had no shared-node-into-cat topology
  under a callable that distinguishes copies, so 127 tests could not see it. Two tests now cover it,
  exactly the panel's probe: an idle refresh over `addfield(cat(shared, shared))` must leave the
  output alone and report zero everywhere, and the same plan must keep both copies apart as the feed
  grows.
- M30 reproduces the defect (copies collapse to the last result) and is killed by those two tests
  and nothing else, which is the proof the gap was real and is now closed.
- The fuzzer gained the general form of the invariant: after every refresh it now runs a second,
  idle refresh and requires the output to be unchanged with every count zero. 500 seeds clean.

### Round 13 (retraction and callables)

- Two tests asserted an EMPTY callable trace when rows are retracted, and the description only said
  callables reach the rows a refresh touched, which a solver can read as including a dropped row.
  Fixed in the description, keeping the assertions: a callable "reaches only the copies a refresh
  gained, each copy once, and an aggregation runs for each group the refresh changed". The second
  clause is load bearing, because a group that only LOSES rows still has to be recomputed, which
  `test_a_discard_shrinks_an_aggregate_group` pins.
- The word budget paid for it by dropping "an aggregation" from the callable list in that sentence
  (it is named in the clause that follows) and shortening the plan-line tail to "for a leaf". 499.
- Of the three coverage suggestions, only the free one was taken: `tail` is now rejected too, which
  shows the rejection is generic rather than keyed to the two classes already tested. The other two
  ask for semantics the description does not define (discard index validation, malformed
  checkpoints); the solution raises `ArgumentError` for a position that holds no row, but testing
  that would make it a hidden requirement, and there is no word budget left to state it.

### Round 12 (Solution Quality: two real defects, both fixed)

- Solution Quality passed but scored 2 of 3 twice, both times on the row-wise cache. The criticism
  was right and the defect was worse than reported.
  * Cached results were keyed by row value and occurrence rank and were never retired, so a copy
    added after an equal copy had been discarded reused the earlier result instead of being worked
    out. `RowWiseOperator._retire` now drops results past the copies a node currently holds, which
    also settles the ambiguity round 11 left open: each copy is worked out once, which is what the
    multiset language says. The description now says "each copy of a row once".
  * The same review flagged `Feed.discard` for not enforcing its precondition. Chasing that found a
    silent correctness bug rather than a missing guard: discarding a position the pipeline had not
    read yet left the cursor short, and the NEXT appended row was never taken in at all. The feed
    operator now advances over discarded positions in the unread tail, and `discard` raises
    `ArgumentError` for a position that does not hold a row.
- The precondition wording went with it: "a row the feed has already handed out" was wrong, because
  resuming from a checkpoint and then discarding is a legitimate flow that my own test uses.
- The other check's warning was taken too: `emitted` now reads "the number of rows".
- 124 tests to 126, 503 to 518 effective LOC. M28 (copies never retired) guards the first fix.
  M29 (cursor ignores discarded positions) was written for the second and is an EQUIVALENT mutant:
  `rows_from` skips discarded positions anyway, so a lagging cursor cannot change what any node
  sees. It was dropped rather than chased with a contorted test.

### Round 11 (fairness of the discard battery)

- Two of the new discard tests were flagged and both flags were right.
  * `discards()` was pinned to a tuple by `eq_((0,), ...)`. The description says only that it gives
    the positions dropped so far, so the test now normalises with `list(...)`.
  * The bigger one: after discarding a row the test appended an EQUAL row and required the select
    predicate NOT to run. That contradicts `test_select_visits_each_duplicate_row`, where each new
    equal occurrence IS visited, and the description settles neither way. The assertion is gone; the
    test now keeps the part that is stated (a discard alone runs no callable) and checks that a
    genuinely new row is still visited.
- The ambiguity itself is left open on purpose: whether a row equal to a discarded one reuses the
  earlier result or is worked out again is invisible in the output, so no test can be an FP on it.
  The reference reuses the result. If the word budget ever allows, the sentence to add is that a
  node keeps the result it worked out for each copy of a row.

### Round 10 (first Nova batch, and the hardening it forced)

- 4 Nova runs, 0 passes, but the shape of the failures matters more than the rate: three of four
  passed 108 of 109 and all four failed the SAME assertion, the duplicate-order rule, each having
  chosen the other reading. Round 9 had already made that rule mechanical, so those four become
  passes and the rate would jump to roughly 100 percent. The engine is not hard for Nova: their
  patches run 1067 to 1304 added lines and get plan, deltas, callables, rollback, checkpoint,
  resume and every transform right.
- So difficulty was added where the batch proves there was none, without touching fairness:
  * `Feed.discard(index)` and `Feed.discards()`. A feed can now lose a row it has handed out, which
    breaks the append-only cursor every one of those four solutions is built on: occurrence caches,
    aggregate groups, join blocks and head windows all have to handle an input that shrinks.
  * A pipeline may stand where a feed does, as a leaf node of kind `pipeline`. That is the only way
    an outer plan sees an input that both gains and loses rows, and it is where a "children only
    grow" engine breaks.
- The two best traps this opens are not restatements of a rule: discarding a row below a `head`
  window makes a row the source never touched APPEAR in the output, and discarding the right row of
  a `leftjoin` brings the padded placeholder BACK. Both are reported as ordinary added rows.
- `to_dict()` was dropped to pay for the words; it was the one piece of pure sugar in the surface.
- 109 tests to 124, solution 478 to 503 effective LOC, mutation 25 to 27, all killed.

### Round 9 (author review of the earliest-occurrence rule)

- Asked to defend `test_added_takes_the_earliest_occurrence_of_a_repeated_row`, the honest answer
  was that it was solvable but not cleanly fair. Old output `[A]`, new output `[A, B, A]`: the
  phrase "taking the earliest occurrences" reads both as "the earliest copies are the ones
  reported" (giving `[A, B]`) and as "the earliest copies match the old rows, so the later ones are
  what was gained" (giving `[B, A]`). Same rows either way, different order, and nothing in the
  description settled it.
- Fixed in the description, not by dropping the test: `added` now "walks the new output in order and
  reports a row while the new output still holds more copies of it than the old one did, so the
  copies reported are the earliest ones", and `removed` walks the previous output the same way.
- Mutant M25 implements the other reading (scan from the end) and is killed by exactly that one
  test, which proves the test discriminates the rule the description now pins. The `removed` test is
  insensitive to the ambiguity, so it stays as it is.
- Body 479 to 499 words, still under the 500 cap; no code or test changed, so both patches stand.

### Round 8 (fourth suggestion round)

- Both taken (106 to 109). Rollback now has a failing aggregation and a failing converter beside
  the existing failing predicate, each asserting the checkpoint is byte-equal across the failure
  and that the retry produces the right rows and counts. Resume now has a checkpoint taken after
  two idle refreshes, resumed with zero replay and then grown.
- Two premises in the first draft of those tests were wrong and the repo corrected them, not the
  other way round: `rows_read` after a failed refresh is 3, not 2, because the rollback restores
  the cursor while the counter records rows actually handed out (already documented as a
  deviation); and petl's `convert` swallows a converter exception by default, so the test has to
  ask for `failonerror=True` to have anything to roll back.

### Round 7 (fairness re-run, stale verdict, and a real gap behind it)

- The Test Fairness re-run FAILED on the same checkpoint assertion that round 6 had already
  removed; it read the previous test.patch. The current patch carries only `assert held, saved`,
  which the same report lists as fair. Nothing to fix there, so nothing was changed for it.
- Its coverage note did find a real defect: the description says `select` is supported, but the
  field form `select(table, field, condition)` builds a `FieldSelectView`, which the plan walk did
  not know, so it raised `IncrementalError` on a transform the description promises. The solution
  now handles both select classes (+4 effective LOC), and the other flagged signatures were
  verified rather than assumed: reordered multi-field `cut`, mapping-form `convert`, compound join
  keys and a three-way `cat` already worked and now have from-scratch equivalence tests.
- Second suggestion taken as well: a resumed three-feed plan asserts all three replacement feeds
  start at `rows_read == 0` and that appending to one advances only that feed's tail.
- 100 tests to 106; solution 474 to 478 effective LOC. Fuzz re-run clean, mutation still 24 of 24.

### Round 6 (test quality)

- Test Quality passed with one warning: the checkpoint layout test asserted each node's state was a
  non-empty dict, which the description never promises. Those two value assertions are gone; the
  test now only requires that one mapping in the checkpoint carries every node id, which is exactly
  what "each node's state keyed by its node id" says and nothing more.
- M24 loses its kill at that test and still dies nine other ways (the scattered layout breaks
  resume), so the trap proof stays at 24 of 24.

### Round 5 (third suggestion round)

- All three taken (97 to 100): checkpoint node-state layout, a feed-only test across five append and
  refresh cycles, and a checkpoint compared across a failing refresh and its retry. Mutant M24
  (checkpoint scatters node state) guards the first.
- The layout assertion was deliberately written to find the mapping that holds every node id rather
  than to index a named container, because Description Quality had just ruled that naming the
  container is over-specification. Pinning it any harder would re-open that finding.

### Round 4 (description quality)

- Description Quality returned FAIL on three points, all taken as written. The scene-setting first
  sentence is gone, the description no longer names the pipeline or the refresh record as concrete
  classes (the tests use both behaviourally, so naming them was over-specification), and the
  checkpoint sentence now says what the tests actually check: the plan text under `plan`, each
  node's state keyed by its node id, and a JSON round trip that leaves it unchanged.
- `IncrementalError` keeps its name: the tests catch it by type, so that one is load bearing.
- Body 482 words to 479. No test changed, so both patches are untouched.

### Round 3 (test fairness)

- Test Fairness returned FAIL on 3 of 97: all three pin the checkpoint's representation, and the
  description only promised "plain lists and mappings". The contract is one worth having, so it
  went into the description rather than out of the tests: the checkpoint files each node's state
  under that node's id and survives a JSON round trip unchanged, every part being a list, a mapping
  with string keys, a string, a number, a boolean or nothing. The structure test now asserts that
  round trip by equality as well.
- Word budget: the added sentence pushed the body to 501, so four clauses were reworded (never cut)
  back to 482, under the 500 cap.
- The mutation run then exposed a harness artifact rather than a test gap: M8 (join blocks in
  discovery order) is only wrong when Python's per-process string hashing happens to order the key
  set wrongly, so it survived one run in three. The join key-order test now uses four keys fed in a
  non-sorted order, and three consecutive mutation runs kill all 23.

- Second suggestion round, all three taken (94 to 97): checkpoint structure asserted directly
  (every node id present, every nested value plain), a rollback test that fails at the top of a
  five node plan after two feeds, a join and an aggregate have already moved, and `rows_from`
  boundaries with their exact `rows_read` increments. Mutants M22 and M23 guard the first two.
- Open risk: the contract permits a solver to re-derive a node from its child's rows, so a lean
  passing solution could land well under the reference's LOC. The lever if the first batch comes
  back over the 40% cap is the reported surface (per node emission counts on deeper plans, more
  interleaved feed growth), not more transforms.
