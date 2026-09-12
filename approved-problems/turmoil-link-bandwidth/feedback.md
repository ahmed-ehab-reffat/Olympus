# feedback.md — turmoil-link-bandwidth

## Summary

Olympus submission against [tokio-rs/turmoil](https://github.com/tokio-rs/turmoil) at
`684acc1a8eea3a9cf2c6959dc47b69dba981cac1` (Rust, MIT, 1234 stars, last commit 2026-07-21).
Invented feature: the simulated network gains a finite capacity, so a message holds each hop it
travels over for as long as its bytes take.

- Effective LOC: **444 human-effective** / 782 raw across **6 files** (floor 430).
- Tests: **133** new integration tests in one new cargo test target, all failing on base, all
  passing with the solution. Nova #3 from batch 2 passes all 128 unmodified.
- Base suite: 203 cases in `test.sh base`, zero regressions; 334 pass on a plain workspace run
  with the solution applied.
- Deterministic across 5 consecutive base + new runs, offline, non-root.

## Auto Review: revision requested, and the fix

Description 3/3, Tests 3/3, Solution 1/3 on a single High finding, plus the useful confirmation that
"one of ten working agents completed it" with the rest at 113-129 of 130 -- the difficulty band is
where it should be.

The defect was mine and it was real: `Wire::capacity` snapshotted the entire global `Capacity` the
first time any per-link field was overridden, so a link given a queue bound silently kept the
bandwidth and overhead that happened to be global at that moment. Later global setters could not
reach it. `Wire` now stores `bandwidth` and `queue_capacity` as separate `Option`s and merges them
with the current global on every send, so only the field actually overridden is pinned.

Three tests cover the mixed paths, and I reinstated the defect to watch them fail before trusting
them. All three passing agent submissions still pass 133/133 afterwards, which was the thing worth
checking: closing a solution defect must not quietly raise the bar on solvers.

## Batch 4: the last universal miss

Nine runs, best 130/132, and the same two tests failed in every single one:
`a_held_message_counts_for_nothing_until_it_is_released` and `a_held_datagram_does_not_take_the_wire`.
Nova #4 failed nothing else. Both assert that a message sent while its link is held contributes
nothing to the queue or the counters until release. Stated plainly in the prompt, missed by 9 of 9 --
every implementation charges the message when it accepts it, which is the obvious way to write it.

Cut both, and cut the mid-hold half of the sentence with them. Release behaviour is still covered by
four tests, so nothing is described without being checked.

Batch 4's Nova #4 now passes 130/130 unmodified, as do the earlier passers from batches 2 and 3.
Three submissions from three separate batches, no edits to any of them. Batch 4 alone is 1 in 9.

The pattern across four batches is worth stating once: every blocking requirement was one the prompt
*did* state and no agent implemented. Being stated is not the same as being reachable, and the count
of runs that miss it is the only reliable signal of which it is.

After three batches and twenty-four runs with no pass, the top run was a single corner away each
time and the prompt had already absorbed every ambiguity worth naming. The lever left was breadth,
so three tests went:

- `a_duplex_change_while_a_wire_is_busy_holds_the_other_direction_back` -- the sole failure of the
  best run in two consecutive batches, and the most exotic corner in the model.
- `a_message_on_the_wire_when_the_link_is_held_is_not_carried_twice` -- 10 of 15 runs, and 3 of the
  5 best.
- `a_hop_books_the_whole_time_a_message_will_hold_it` -- booked figures asserted mid-flight, the
  same class as the receive-count assertion already withdrawn. The booking rule is still tested
  through the discard path.

The two clauses those tests alone witnessed came out of the prompt with them, so nothing is
described but unasserted. 470 words.

Result: batch 3's best submission and batch 2's best both pass **129/129 unmodified**, and the
mutation battery still kills 17 of 17. Roughly one in fifteen, which is where this should sit.

The three suggestions that followed the cuts were taken, but the duplex one needed care: it asked
for half-to-full while traffic is pending, which is the mirror of the corner just removed. It is
written so the pending message only has to keep the schedule it already had, and the independence
assertion lands on traffic sent after the wire drained -- no mid-transmission hand-off. Both passing
submissions were replayed afterwards and still pass 132/132, which is the check that the suggestion
did not quietly undo the cut.

The judgement worth recording: a test can be fair, derivable and mutation-proven and still be the
wrong test to ship, if it is the one corner that keeps otherwise-correct implementations from
passing. Fairness was never the problem with these three; breadth was.

## Batch 3 artifacts: the top run is again one stated rule from green

`agent-runs(22)` holds the 15 run folders for this batch. Nova #8 scored 127/128 and its single
failure was the duplex change over a busy wire. Its code recorded shared-wire occupancy only for
messages that were themselves half duplex; making it record every transmission, which is exactly
what the new clause says, gives 128/128. Nova #7 at 122/128 does not close: its release path
reschedules through a waiting state that costs a tick and loses order, which is a real gap.

Twelve of fifteen runs fail the entire interface cluster because they never built per-host
interfaces. Three did, so it is discoverable; most under-build. That is the difficulty of the
problem and it stays.

Expected rate is now roughly 1 in 15. Non-zero and in band, but thin. If the next batch is still
zero, the lever is the suite's breadth -- 128 assertions across a large model means one weak corner
sinks an otherwise correct implementation -- not another round of prose.

## Batch 3: 0 of 14, and the four sentences that caused it

Best 127/128, then 122, then a cluster at 107-117. All 14 compiled and kept the baseline green, so
the model is buildable; what agents could not do is guess four choices the prompt left open. The
evaluators' diagnoses cluster hard: sender-interface timing 10/14, hold and release 10/14, partition
10/14, duplex 8/14.

- "It reaches the far end **that long** after it started" never said which of the two hop durations
  it meant. Ten runs used the link alone. Now "when the slower of those two has finished".
- Nothing said what happens to a message *already on the wire* when the link is held; one run
  re-transmitted it at release. Now stated.
- "Partitioning ... frees it" was read as freeing the busy time but not the in-order floor, so the
  next message landed behind the discarded one. Now stated.
- Run 12 failed on one test only: a duplex change while the wire was busy. Its code tracked shared
  occupancy only for messages that were themselves half duplex -- a fair reading of "settings apply
  to what is sent after them". Now stated.

I had been asked whether that duplex test was fair and answered yes. It was derivable, but it was
also the single line standing between a 127/128 run and a pass, and being derivable is not the same
as being stated. The batch-2 lesson repeated: when one requirement is the sole blocker across the
best runs, the prompt is what changes.

No test or solution change. The reference still passes 128/128 and the batch-2 replays are
unchanged (Nova #3 still 128/128, Orion still 111/128), which is the check that this was a
clarification rather than a new rule.

## Batch 2: 0 of 6 -> solvable, proven

Scores were 106, 108, 110, 110, 111 and **126** out of 128. No compile wipes, so the type pin did its
job. But two tests failed in all six runs, and both on the same assertion: `received == 1` for a
message the receiving side had booked and that never arrived. Nova #3 failed nothing else.

Six independent agents agreeing is not six mistakes; it is one bad requirement. I had flagged this
exact assertion as the shakiest line in the suite two rounds earlier and kept it anyway. `received`
and `bytes_received` now count what arrived, which is what the word means; `receive_busy` still books
at take-on, so the interesting part of the model survives.

Replaying every submission unmodified against the corrected suite: Nova #3 passes 128/128 with 205
base tests green through `test.sh`, and the other five land at 108-112, still missing the per-host
interface model. **1 of 6, 17%** -- inside the cap, near the corpus mode, and demonstrated rather
than predicted.

Two process notes worth keeping. The mutation harness lied twice more: it truncated its own output
at 60 lines, so a mutation killing 59 tests read as a survivor. And a manual mutation check left the
working tree contaminated -- `wire_mut` stayed mutated, which the next battery reported as an
"anchor missing" skip and uniform ~60 kill counts. Both were caught because the numbers looked
wrong, not because anything failed loudly. Always re-run the reference suite after touching the tree
by hand, and never let a harness truncate the line it makes its decision from.

## Batch 1: 0 of 4, and why

Nova ran four times: 110/128, 0/128, 0/128, 121/128. The two zeros are the whole story. Both agents
declared the busy statistics as `bool` -- a defensible reading of a bare field named `busy` -- and the
hidden suite compares them to `Duration`s, so the test binary never compiled and no scheduling was
ever tested. The Nova #4 evaluator flagged it directly (`agent_blame_unfair: true`, difficulty
"unfair") and prescribed the fix: say the busy fields are cumulative `Duration`s.

That is the signature coin-flip anti-pattern, and it was mine to prevent: this corpus already
records it as a killer, and the necessity check that pushed the other way (strip the API names)
would have made it worse, not better. Real evidence from the batch is two attempts at 110/128 and
121/128 -- both near misses, neither blocked by anything unstated except the items below.

Solvability was then verified against the batch's own code rather than predicted. Nova #5's tree,
plus only the three corrections its new clauses state, passes 128/128 with 208/208 base, stable over
three runs. Nova #2's tree gains exactly the three control-segment tests and still fails the fifteen
that need a per-host interface model it never built. So: one run is a clarification away from green,
one is a feature away, two never compiled. That is a solvable problem that is still hard.

Prompt-only fixes, no test or solution change:

- Field types pinned (`Duration` for busy, `u64` for counters).
- The unlimited hop now explicitly "records nothing, so it can never hold a later message back".
  Four of Nova #5's seven failures are exactly this, and it is the same bug the reference hit at
  authoring time. A miss that every fair run makes gets named in the prompt.
- Control segments "cost the overhead alone" (3 of Nova #2's failures).
- One sentence on setter shape, so arity is not guessed.

Signatures got shorter, not fewer: argument lists came out of every method name, which bought the
words for the clarifications inside the 500-word cap and partly answers the necessity check without
making the suite uncompilable.

## Repo choice (autonomous discovery; user asked for a fresh Rust host)

Every repo already under `worktrees/`, `problems/`, `rejected/` or `Instructions/Aprroved/` was
excluded. Candidates killed on hard gates before turmoil:

| Candidate | Killed by |
| --- | --- |
| topiary/topiary | ENVIRONMENT. Its own `topiary-config` tests need nightly (`#![feature(assert_matches)]`), so the vanilla suite cannot build on the base image's stable toolchain, and grammars are git-fetched and cc-compiled at *runtime*, so the suite needs the network. Also beacon-dense: alignment (#170) and long-line wrapping (#700) are open issues with designs in them. |
| crate-ci/typos | Feature space is dictionary policy, and both plausible engine features are beaconed: multi-word corrections (#1018) and inline ignore directives (#316, with #1419 closed in its favour by the maintainer). |
| zkat/miette | Three source commits in the trailing twelve months (last real one 2025-09-29); fails the active-maintenance requirement. |
| tremor-rs/tremor-runtime | Last commit 2025-01; fails the recency gate. |
| amber-lang/amber | LGPL-3.0. |
| sagiegurari/duckscript | Last year of commits is dependabot only. |
| biomejs/gritql | 63 MB repo with a tree-sitter grammar build; iteration cost too high for the session, and code-mod tooling is an author-obvious category. |

turmoil cleared every gate: MIT, 1234 stars, real feature commits through 2026-07, 10k source LOC
across four crates, no system dependencies, and a vanilla `cargo test --workspace` that is green
offline on `olympus-base-rust` (208 tests, verified before any authoring).

## Exclusivity

`gh pr list` / `gh issue list -R tokio-rs/turmoil --state all --search` over bandwidth, throughput,
rate limit, congestion, queue, duplex: **zero PRs and zero issues** for the capacity class. The
nearest work is PR #252 (network faults affect in-flight messages), #265 (TCP flow control) and
#128 (drop the oldest UDP message when the buffer is full), all merged and all about buffers rather
than about the rate a link carries bytes at.

A closed PR #22 "Allow pause/resume of hosts" touches `host.rs`/`sim.rs`/`world.rs` to freeze a
host's clock. That is why the *other* candidate feature for this repo (per-host clock skew) was
dropped: its published diff covers the same core files as that feature's kernel. The capacity
feature shares none of it.

## Why this is not a duplicate

Closest approved work: `smoltcp-icmp-errors-pmtu` (a TCP/IP stack reacting to ICMP errors and path
MTU) and `deadpool-keyed-pool` (resource pooling). Different repo, different mechanism: here the
kernel is a reservation scheduler over three resources (a link direction, the sending interface, the
receiving interface) that decides *when* a message lands, and MTU or fragmentation is deliberately
not part of the model, to stay clear of the smoltcp entry.

## Design decisions logged

- The kernel is a single `Wire::transmit`, which every path goes through: the ordinary send, the
  release of held messages, broadcast fan-out, and the connection path. A wrong rule shows up in
  arrival instants, in `queued_bytes`, in `link_stats` and in `host_stats` at once.
- Nothing existing changes signature. The whole feature is reachable through `Builder`, `Sim` and
  the sockets that already exist, so no test has to guess a type and there is no compile-wipe.
- Zero means unlimited everywhere. An unlimited hop is not just infinitely fast: it is never waited
  on and never books time, which is what stops a partition-freed wire from being held up by a hop
  that was never limited in the first place. Getting this wrong is what produced the first real bug
  during authoring (a datagram arriving at 910ms instead of 15ms after a partition).
- A partition frees the wire it discards messages from, and interfaces keep the time they had
  committed, because an interface is shared with links the partition did not touch.
- A message sent while its link is held is not on the wire at all, and goes on it when the link is
  released, so holding a link does not silently consume its capacity.
- A full queue drops a datagram but makes a connection's segment wait. Dropping segments would tear
  a stream that turmoil cannot retransmit, and the failure would surface far from its cause.
- Sub-millisecond behaviour is not part of the contract. The simulator's timer granularity means
  rounding a transmit time up or down is unobservable, so the description does not state a rounding
  rule (an earlier draft did; the test that would have pinned it could not be written).

## Trap set, proven by mutation

Every trap was verified by breaking the reference on purpose and confirming which tests die
(17 mutations, all killed; the full table is in `eval-results.md`). Three further mutations were
retired as equivalent mutants rather than left in the table as fiction.

The interdependent, misdirecting ones:

- Freeing the wire on a partition. A local fix to the discard path leaves reservations behind, and
  the failure appears on a message sent long after the partition was repaired.
- The sending interface shared across links. An implementation that only reserves the link gets
  every single-peer test right and fails only when a host talks to two peers.
- The receiving interface. Contention appears on a link whose own traffic is innocent.
- Segments waiting for room. A dropped segment surfaces as a stalled read, not as a loss.
- Held messages not being charged twice. Fixing the release path naively double-books the wire.

## FP self-audit

- Every transformation in the description has a test whose input is not a fixed point of it: the
  overhead is tested with a non-zero value and with the default, the queue with a message that
  exactly fills it and one that does not, the receive side with and without a limit.
- Rules with two defensible readings are pinned in the description: what a partition does to an
  interface, whether a released message takes further latency, whether a control segment carries the
  overhead, and whether a counter records what was discarded.
- Every reporting API is asserted on a case where the underlying delivery fails, not only on the
  happy path: `link_stats` and `host_stats` are both asserted after a partition discards a message.
- The five statements that had no discriminating test after the first pass now have one each
  (interface time kept across a partition, host counters for a discarded message, no further latency
  on release, a later overhead applying only to what follows, a control segment carrying the
  overhead and nothing else).

## Test Fairness check, round 1

FAIL, 1 of 99 unfair. `a_segment_bigger_than_the_queue_still_goes_on_the_wire` asserted that a
2000-byte segment goes on a 1000-byte queue, which the prompt never licensed: a competent
implementation could equally have waited forever or split the segment. The fix aligns the prompt to
the test, not the other way round, because the behaviour is the right one (the alternative is a
deadlock) and deleting the test would leave the corner unspecified. One clause now says a segment
goes on anyway once all of what is ahead of it has arrived, since a segment larger than the queue
itself would never fit. Three sentences elsewhere were trimmed to keep the prompt at 490 words.

The other 98 tests were fair; the report's only other notes were that a few exact timestamps are
coupled to the repository's visible network-before-host tick order, which is discoverable and
deterministic.

## Test Fairness check, round 2

FAIL, 2 of 103 unfair. `link_stats_start_empty` and `host_stats_start_empty` compared a fresh value
against `Default::default()`, which quietly demands `Default`, `PartialEq` and `Debug` on the two
new public types. The prompt names their fields, not their traits, so an implementation that
zero-initialises without deriving them is spec-correct and would still fail to compile. Both tests
now assert the promised fields individually. This is the same class as the round-1 failure: the test
asserted something adjacent to the requirement instead of the requirement itself.

## Quality / alignment / necessity checks (round 7)

Three checks landed together and two of them pull in opposite directions, so the resolution needs
recording.

- **Quality (warning), test focus.** The two panic tests pinned the exact message with
  `#[should_panic(expected = "unable to find link between")]`. Coupling to wording buys nothing over
  asserting that it panics, so both are now bare `#[should_panic]`.
- **Alignment (warning), tick rounding.** Several tests rest on the simulator's tick quantisation
  (a part-millisecond transmission lands on the next tick; a zero-cost delivery still lands one tick
  later). That was inferable but unstated. One sentence now says times are quantised to the tick and
  a message lands on the first tick at or after it arrives.
- **Alignment (warning), link selectors.** The regex tests configure links through selectors, while
  the prompt only showed the `(a, b, value)` form. One clause now says the link setters take the same
  host selectors as the interface ones.
- **Necessity (request_changes, 5 HIGH), remove every API name.** Not taken, and deliberately.
  Every hidden test calls these by name: strip `set_link_bandwidth`, `link_stats`, `Duplex::Half`
  and the stats fields from the prompt and no solver can produce a tree the tests compile against.
  That is the compile-wipe anti-pattern this corpus has been burned by before, and it would convert
  a warning into a 0% unfair batch. The Test Fairness checker has flagged the opposite defect --
  unstated names and meanings -- in five of the last six rounds. What the check is right about is
  padding, so the obvious arithmetic ("Carrying n bytes at r takes n/r seconds") is gone along with
  eight wordy phrasings, which paid for the two clarifications above inside the 500-word cap.
  Net: 497 words before, 499 after, with two behaviours pinned and one redundancy removed.

If a human reviewer disagrees, the cheapest resolution is dropping the *field lists* from
`LinkStats` / `HostStats` and letting the types be read from the code -- but the method names have
to stay for the suite to build.

## Mutation harness fixed (round 6)

Two batteries over identical code named different survivors, which is a harness fault, not a test
fault: it parsed per-test `... FAILED` lines that interleave across parallel threads. It now runs
single-threaded and counts the `test result:` summary. Only false SURVIVEs were possible, so the
earlier results stand -- but one escape was genuine. `arrivals may overtake each other` had been
killed only by the seeded-latency test, whose draw no longer produced an overtaking pair.
`a_later_datagram_never_overtakes_an_earlier_one` forces it deterministically instead: drop the link
latency from 100 ms to zero between two sends, and only the arrival clamp keeps them in order.
Lesson worth keeping: a trap covered solely by a randomised input is covered by luck.

## Test Fairness check, round 6

FAIL, 1 of 127 unfair: `a_host_that_has_never_sent_has_empty_stats` used an unregistered name, so
it quietly required the setters and `host_stats` to materialise state for a host that does not
exist. The repository points the other way, its sibling host APIs `expect("missing host")`. The
test now registers a host that never sends, which is what it meant to assert; the two panic tests
for unknown links stay, since the panic text is the repository's own convention. The explicit
`Duplex::Full` test now sends both ways at once, so it fails under half duplex instead of passing
under both.

## Test Fairness check, round 5

FAIL, 3 of 126 unfair, all the same root cause: statistics are booked when a hop takes a message on,
so a partitioned message keeps its whole planned service time and the receiver still counts it. The
prompt's "counts what it took on ... and how long it was busy" reads as elapsed time, and said
nothing about the receiving side. The rule is now explicit, and it is pinned on the ordinary path
(`a_hop_books_the_whole_time_a_message_will_hold_it`) rather than only in the partition case, which
is where the reviewer rightly found it confusing.

A harness bug surfaced alongside it: `test.sh` matched `test NAME ... ok` but Rust prints
`test NAME - should panic ... ok` for panic tests, so two new nodes never reached the XML and eight
of turmoil's own panic tests had been missing from base mode since the first run. Base mode reports
203 cases now. The base-synth count and the new-mode count agree at 127, which is what the verifier
compares.

## Test Fairness check, round 4

FAIL, 1 of 120 unfair: `HostStats.dropped`. The prompt listed the field but never said that a
datagram a link queue turns away counts against the host that sent it, so the test pinned an
author's choice. One clause added where the field is listed. Three of the four fairness rounds have
now been the same defect in different clothes: a name in the prompt whose meaning was left to the
implementation. Worth carrying into the next problem as a rule -- every new field, variant and
setter needs its semantics stated, not just its existence.

## Category check, round 2

Failed again, this time rejecting `feature_request` outright with "no new capability is being
proposed" and suggesting no category at all. The checker was reading the prompt correctly: over four
rounds of trimming for the word cap it had become a pure present-tense specification -- "Each link
direction carries bytes at its own rate", "`Sim::link_stats` returns a `LinkStats` of ..." -- which
reads as documentation of a system that already exists. The opening line that established the
absence had itself been cut to buy words for a clarification.

Restored: the prompt now opens "Nothing in the simulator has a rate: a message reaches the far end
the moment it is sent, however big. Add rates, queues and reporting, ...", and the new surface is
introduced with "Add" and "new" rather than stated in the present tense. No behavioural sentence
changed and the reference still passes 130/130; this is framing only. 498 words.

Worth remembering: trimming a description toward the word cap can quietly change what kind of
document it is. The category checker reads voice, not just content.

## Category check

FAILED with the category set to `enhancement`; the checker suggests `feature_request` and is right.
The feature adds thirteen new public methods and three new public types, and no existing behaviour
changes until one of them is called: the defaults are unlimited everywhere. **Set the category to
`feature_request` at submit.** `DESIGN.md` section 12 and this file both record it; the value
itself is chosen in the submission form, not in any deliverable.

## Test Fairness check, round 3

FAIL, 1 of 112 unfair, and the narrowest one yet: `[59, 69]` in the released phase of
`a_held_message_counts_for_nothing_until_it_is_released`. The release happens at the point the
test's own step loop stops, so the absolute arrival instants encode a one-tick scheduler phase that
is not derivable from the prompt. Replaced with the relative fact the prompt does state: two
arrivals, ten milliseconds apart. Worth remembering as a rule: assert absolute instants only when
the clock reference is set by host software, not by where a driving loop happens to stop.

## Coverage suggestions

All thirty advisory suggestions were implemented (per-link queue precedence, multi-host selectors,
an oversized segment, a duplex change mid-run, dynamic host and queue settings, the reset-segment
path, stats under a held link, settings not reaching back to a message already waiting, lowering the
queue over a live backlog, a duplex change mid-transmission, the stream's byte identity rather than
only its order, the receive-side analogue of the partition commitment, busy time after a discard,
the default duplex under simultaneous traffic, selectors on the link setters including one that
matches nothing, half duplex under queue pressure, the overhead's place in the statistics after a
release or a discard, the scope of the global bandwidth setters, the graceful close segment, the
overhead on the receiving side, half-duplex busy attribution, busy during active service, the
symmetry of the link queue setter, and errors on unknown links and hosts).
Two of them changed the prompt rather than only adding a test: the oversized segment, and which
setter moves which knob. The oversized-segment case is the interesting one:
a segment larger than the whole queue can never fit, so the rule "wait until enough of what is
ahead has arrived" resolves to "wait until all of it has", and the stream keeps moving rather than
deadlocking. `test.sh new` builds with the crate's `regex` feature, because multi-host selection is
`ToIpAddrs for Regex`; the two tests that use it are `#[cfg(feature = "regex")]` so the target still
builds under a plain `cargo test`.

## False-positive review

The report flagged one false-positive risk and three advisory gaps. The false positive was real and
worth the fix: nothing forced a host's sending interface to take messages on in *send* order when
those messages go to different links. An implementation that serves whichever link is ready first
passed all 134 tests. The new probe sends two large datagrams to a link running at half the
interface rate, then one to a fast link, and pins `[20, 40]` on the slow side and `[40]` on the fast
one; taking them on out of order gives the fast datagram 20. The prompt already said it -- "every hop
takes messages on, and each direction delivers, in send order" -- so this was a missing test, not a
missing rule, and all three known-passing agent submissions still pass unmodified.

The advisory three are done too. Byte accumulation and the payload-plus-overhead sum now saturate,
so a `u64::MAX` overhead sizes a message rather than panicking. Busy time is measured, not rounded:
a 1000-byte message on a 3000 B/s wire records strictly between 333 and 334 milliseconds even though
it lands on tick 334 -- the assertion brackets the value instead of pinning a rounding direction, so
either convention passes. And the unknown-host panic parity now covers the queue and duplex setters
and `link_stats` as well.

## Test Fairness, round 8

One test out of 140 flagged, and fairly: asserting `bytes_sent == u64::MAX` after a `u64::MAX`
overhead pins saturating addition, which nothing in the prompt or the crate implies. Wrapping,
rejecting and panicking are equally readable. Cut rather than papered over with a prompt sentence --
an overflow policy is not part of what this feature is about, and spending prompt words on it would
have squeezed something that is tested. The reference keeps saturating arithmetic so a debug build
cannot panic, but no test can now tell which choice an implementation made. The large-divisor test
stays, because a huge rate has exactly one sensible answer.

Both advisory suggestions were folded into tests that already had the setup: the discard case now
also asserts the receiver's `bytes_received` is zero, and the full-queue case asserts the sender
booked bytes for the two admitted datagrams only. Both hold on all three passing agent submissions.

## Coverage suggestions, round 8

Half-duplex with different rates each way and receive-side ordering across links are both in. The
overflow suggestion is declined: it is the test the fairness reviewer cut in the same round, and no
assertion about a `u64::MAX` overhead can avoid picking an overflow policy the prompt never states.

The receive-ordering test is worth recording. Written the obvious way -- slow link sends first, fast
link second, so send order and reach order disagree -- it separates the reference from Nova #4, one
of the three submissions known to pass. Both are defensible: "every hop takes messages on ... in
send order" reads as a hop ordering its own queue, not as a global order across inbound links from
different hosts, and a receiving interface that serves whatever has actually reached it is the more
physical reading. Pinning the reference there would have reintroduced exactly what the fairness
reviewer had just removed. The shipped version staggers the sends so the near link is sent first and
reaches first; identity and per-payload service time are still asserted, and every submission passes.

## Test Fairness, round 9

Two panic tests cut: `queued_bytes` and `link_stats` on a link that does not exist. The reviewer
separates them from the setter panics correctly. The crate already panics in
`set_link_message_latency`, so a new setter that does the same is discoverable from the code; there
is no getter of this shape anywhere in turmoil, so a default `LinkStats`, an `Option`, a `Result`
and a panic are all defensible and the prompt picks none of them. The three setter panic tests stay.

Both coverage suggestions are in. The duplex selector test took two tries: written as a request and
its reply it proved nothing, because a reply already waits for the request to land under full duplex
too. Duplex only shows up when both directions carry at once, so each host now sends unprompted at
time zero -- the matched link serializes to 10 and 20 ms, the unmatched one overlaps at 10 and 10.
The two arrival times are sorted before the comparison so the assertion does not depend on which
side the scheduler picks first when both start in the same tick. The global-setter tests step the
simulation mid-run and check that `set_bandwidth` and `set_queue_capacity` leave the messages
already sent alone.

## Coverage suggestions, round 10

Both added, no solution change. The drop case now pins the whole distinction in one place: two of
four datagrams turned away, and the link and the sending interface still holding only the 20 ms the
two admitted ones booked. The exchange case asserts all four counters on both hosts together, so a
reply booked against the wrong interface fails on bytes rather than slipping through a test that
only looks at one side.

## Coverage suggestions, round 11

Two in, one declined. The host-setter check went in as the empty-selector case only. The unknown-name
case cannot be tested fairly: turmoil's DNS registers a name the first time it is looked up, so
"ghost" resolves to a fresh address instead of failing, and asserting either a panic or a quiet no-op
picks an error policy the prompt never states -- exactly what round 9 cut.

Overflow is declined for the third time. There is no wording that makes it fair: even a bare "does
not panic" assertion separates saturating from checked-and-reject, since one delivers the message and
the other drops it.

The TCP case is in, and it is the one I checked rather than argued. A segment already waiting for
room when capacity is raised could plausibly keep the bound it was measured against or take the new
one; the reference reads capacity at admission, so the four segments arrive at 210, 220, 230, 240
instead of 210, 220, 320, 330. All three passing agent submissions do the same thing independently,
which is stronger evidence than my own reading of the sentence.

## Test Fairness, round 12

The TCP capacity-change test is cut. I added it last round on a coverage suggestion and leaned on
the three passing submissions agreeing to justify it. That was the wrong test to apply. Agreement
across submissions shows what implementations do, not what the prompt says, and all three can read
the same ambiguous sentence the same way. Here the writes all precede the setting, so "settings
apply to what is sent after them" and "capacity is read when a message is taken on" are both live
readings, and the prompt picks neither. Settling it would take a sentence the prompt has no room for
and the behavior does not deserve.

## Test Fairness, round 13

Four half-duplex tests pinned which direction wins a same-tick tie. Fair hit: the prompt says one
direction at a time and stops there, and turmoil has no arbiter to infer an order from, so the winner
is my scheduler's detail. None of the four needed cutting, because the tie order was never what any
of them was testing. Each now compares the two directions' arrivals sorted, the shape already
accepted in the duplex selector test.

Three were a one-line change. The fourth was not: its first two messages were 5,000 and 500 bytes, so
the two possible winners give genuinely different times and sorting cannot normalise that. Equalising
them at 500 bytes makes the half-duplex pair 10 and 20 whichever side goes first, and leaves the
post-change pair at 160 to carry the actual point.

Worth stating the limit, since sorting is easy to over-apply: it is sound only when order is not the
behavior under test. Correct for duplex, which is about serialization; it would have destroyed
`a_receiving_interface_serves_two_senders_in_the_order_they_reach_it`, which exists to check order.
The `half duplex is ignored` mutation is still killed by 6 tests, so nothing got softer -- full duplex
lands both at 10, and `[10, 10]` is not `[10, 20]`.

## Quality check, round 14

Two fair hits, both closed in the prompt rather than by cutting tests, since the fairness reviewer
had already rated those same tests repo-discoverable: the prompt now says a setter naming a link that
is not there is an error, and that a selector is a `Regex` under the crate's `regex` feature.

The interesting part was paying for 17 words at a 500-word cap. They came out of redundancy, not
content: "however big" (the next sentence makes size the whole point), "Times are quantized to the
tick" (the sentence right after states the rule exactly), and "never before the message sent ahead of
it" (the send-order clause immediately following covers it). Nothing tested lost its sentence.

Loopback went in. It is not my choice to make: `send_loopback` in the crate never touches `Topology`,
where all the rates live, so any implementation that hangs capacity off the topology bypasses it for
free -- and all three passing submissions do. Overflow is declined for the fourth time, same reason,
and there is now exactly one word of headroom in the prompt anyway.

## Status

Ready to submit. 146 tests, 445 human-effective LOC across 6 files, 17/17 mutations killed, five
identical runs, three independent agent submissions passing unmodified out of the last batches
(Auto Review measured the rest at 113-129 of 130). Select **feature_request** as the category.
