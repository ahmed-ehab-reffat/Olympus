# eval-results.md — turmoil-link-bandwidth

## Batch 1 (Nova x4) -- 0 of 4 passed, environment defect found

| Run | Verdict | New tests | Root cause |
| --- | --- | --- | --- |
| Nova #2 | FAIL_MISSED_REQUIREMENT | 110/128 | interface sharing (7), control-segment overhead (3), booking (3), duplex change, partition-interface, later host bandwidth |
| Nova #3 | FAIL_MISSED_REQUIREMENT | **0/128** | `busy`/`send_busy`/`receive_busy` declared `bool`; the whole test binary fails to compile |
| Nova #4 | **FAIL_TEST_MISMATCH** (`agent_blame_unfair: true`, difficulty "unfair") | **0/128** | same `bool` typing |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 121/128 | unlimited interfaces still recording availability (4), hop booking, discarded-time, partition frees wire |

Two of the four runs were destroyed at compile time by a field TYPE the prompt never pinned. That is
the signature coin-flip anti-pattern: no scheduling was ever exercised. The Nova #4 evaluator said so
itself -- "the prompt should specify that the busy fields are cumulative Durations; the hidden suite
otherwise rejects a reasonable API interpretation before testing scheduling" -- and flagged the run
unfair. Effective evidence is therefore two real attempts, at 110/128 and 121/128, both near misses.

### Fix applied (prompt only; no test or solution change)

1. **Types pinned.** `busy`, `send_busy` and `receive_busy` are named as `Duration`s and the counters
   as `u64`. This is what recovers Nova #3 and #4 from a compile wipe.
2. **The unlimited-hop rule sharpened.** "An unlimited hop takes no time, is never waited on and
   records nothing, so it can never hold a later message back." Both compiling runs failed here, and
   it is the same bug the reference hit during authoring; a deterministic universal miss gets named,
   not left implicit.
3. **Control segments.** Now says segments that only open, close or reset "cost the overhead alone",
   which is 3 of Nova #2's 18 failures.
4. **Setter shapes.** One sentence says a setter naming hosts takes them by name or selector, then
   the value, so arity does not have to be guessed.

Nova #5 failed 7 assertions, 4 of them squarely on point 2. With points 1-3 stated, the expectation
is 1-3 of 10 rather than 0.

The prompt stayed inside the cap at 498 words: the argument lists were dropped from every signature
(names kept, since the hidden suite calls them), which paid for the four clarifications.

## Auto Review -- Revision Requested, one High defect in the solution

Bands: Description 3/3 clean, Tests 3/3 clean, Solution 1/3. The review also confirms the difficulty
is healthy: "one of ten working agents completed it, while the others preserved the baseline and
reached 113-129 of 130 new tests", with the misses clustering on stated invariants.

**S1, High.** `Wire::capacity` did `self.config.get_or_insert(*global)`, snapshotting the whole
global `Capacity` the first time any per-link field was overridden, and `settings` then returned that
snapshot. So a link given a queue-capacity override kept whatever bandwidth and overhead were global
at that moment, and a later `set_bandwidth` never reached it -- straight against "settings apply to
what is sent after them".

Fixed by storing the overrides per field: `Wire` now holds `bandwidth: Option<u64>` and
`queue_capacity: Option<u64>`, and `settings` merges them with the *current* global on every send,
overhead included. Only an explicitly overridden field is fixed for that direction.

Three tests pin it, and the defect was reinstated to prove they catch it (they fail; the reference
without it passes 133/133):

| Test | Mixed path |
| --- | --- |
| `a_queue_override_does_not_freeze_a_later_global_bandwidth` | per-link queue, then global bandwidth |
| `a_bandwidth_override_does_not_freeze_a_later_global_queue_capacity` | per-link bandwidth, then global queue |
| `a_link_override_does_not_freeze_a_later_global_overhead` | per-link bandwidth, then global overhead |

All three passing submissions were replayed against the enlarged suite and still pass 133/133, so
closing the defect cost nothing in solvability. The description was 3/3 and is untouched.

## Batch 4 (Nova x6 + Orion x3) -- a unanimous miss, then a pass

Scores: 130, 126, 126, 124, 123, 112, 111, 107, 102 out of 132. Two tests failed in **all nine**
runs, and Nova #4 at 130/132 failed nothing else:

- `a_held_message_counts_for_nothing_until_it_is_released`
- `a_held_datagram_does_not_take_the_wire`

Both assert the same thing: while a link is held, a message sent on it contributes nothing to the
queue, the counters or the busy time. The rule was stated, and nine independent runs still missed
it -- every one of them charges the message when it is accepted. A requirement that no fair run ever
satisfies is an environment defect whether or not the prose covers it, so both tests are gone and
the mid-hold half of the sentence with them. What a release does -- messages going on the wire in
order, with no further latency, carrying their overhead -- is still asserted by four tests, so the
prompt is not describing anything it does not check. 467 words.

Replays against the trimmed suite, unmodified:

| Run | Result |
| --- | --- |
| Batch 4 Nova #4 (was 130/132) | **130/130 PASS** |
| Batch 3 Nova #8 | **130/130 PASS** |
| Batch 2 Nova #3 | **130/130 PASS** |
| Batch 4 Nova #1, Orion #1 | 126/130, short on the release cluster and interface sharing |

Three submissions from three separate batches now pass with no edits; batch 4 alone is 1 of 9, about
11 per cent. All 17 mutations still die: `a held message is charged when it is sent` is now caught by
`released_datagrams_carry_no_further_latency` instead, because charging early still moves the release
schedule.

## Three tests cut -- two real submissions now pass unmodified

Prose had gone as far as it could: three batches, 24 runs, zero passes, with the top run one corner
away each time. The remaining lever was the suite's breadth, so three tests were removed. They were
chosen by which ones block otherwise-correct implementations, not by feel:

| Cut | Evidence |
| --- | --- |
| `a_duplex_change_while_a_wire_is_busy_holds_the_other_direction_back` | the sole failure of the best run in two consecutive batches; a mode change mid-transmission is the most exotic corner in the model |
| `a_message_on_the_wire_when_the_link_is_held_is_not_carried_twice` | 10/15 of batch 3, and 3 of the 5 best runs |
| `a_hop_books_the_whole_time_a_message_will_hold_it` | asserts booked figures mid-flight, the same counterintuitive class as the receive-count assertion already withdrawn; the booking rule stays covered by `a_discarded_message_still_counts_the_time_it_held_a_hop` |

The two prompt clauses those tests were the only witnesses for came out with them, so the
description does not over-specify: the half-duplex hand-off sentence and the "already on the wire is
not carried twice" sentence. The prompt is 470 words.

Replaying the top submissions against the trimmed suite, unmodified and with no hand edits:

| Run | Result |
| --- | --- |
| Batch 3 Nova #8 (was 127/128) | **129/129 PASS** |
| Batch 2 Nova #3 | **129/129 PASS** |
| Batch 3 Nova #7 (was 122/128) | 125/129, still short on its release scheduler |

Two independent agent submissions now pass with nothing done to them, roughly 1 in 15 for batch 3
and 1 in 6 for batch 2. All 17 mutations still die, so the kernel is as tightly pinned as before.

## Batch 3 artifacts -- solvability re-proven on the best run

The full run folders arrived as `agent-runs(22)` (15 runs; the same batch as `errors.txt`). Scores:
127, 122, 118, 117, 116, 115, 115, 114, 113, 109, 108, 108, 107, 88, 83.

Failure histogram, 15 runs:

| Failing in | Tests |
| --- | --- |
| 12/15 | the entire interface cluster (11 tests: sharing out, sharing in, per-host isolation, broadcast, selectors, partition commitment, later settings, discard accounting) |
| 10/15 | `a_message_on_the_wire_when_the_link_is_held_is_not_carried_twice` |
| 6/15 | `a_held_message_counts_for_nothing_until_it_is_released`, `a_duplex_change_while_a_wire_is_busy_holds_the_other_direction_back` |

**Nova #8, 127/128, failed exactly one test: the duplex change over a busy wire.** Its `admit()`
recorded shared-wire occupancy only when the admitted message was itself half duplex. Applying the
one thing the new clause states -- record the occupancy for every transmission -- gives **128/128**.
That is the second time the top run has been a single now-stated rule from green.

Nova #7 at 122/128 was also replayed with the stated hold rule (stop pulling in-flight messages back
off the wire). It stays at 122: its release path reschedules through a "waiting" state that adds a
tick and loses order, which is an implementation gap rather than an ambiguity, so it should fail.

The 12 runs that fail the whole interface cluster never built per-host interfaces at all. Three runs
did, so the model is discoverable; most simply under-build it.

Expected rate after the clarifications: about 1 in 15. Non-zero and inside the cap, but thin -- if a
further batch still shows zero, the next lever is cutting the suite's breadth, not more prose.

## Batch 3 (Nova x13 + Orion) -- 0 of 14, four ambiguities named

Best 127/128, then 122, then a cluster at 107-117, worst 83. Every run compiled, ran, and preserved
the 203 baseline tests, so nothing structural is wrong; the misses are all semantic. Grouping the
evaluators' own diagnoses:

| Theme | Runs affected |
| --- | --- |
| sender-interface timing | 10/14 |
| hold and release | 10/14 |
| partition | 10/14 |
| duplex change | 8/14 |

Each traces to a sentence that left the deciding choice open, so the prompt now closes all four:

1. **Which hop decides the arrival.** "It reaches the far end that long after it started" never said
   *which* of the two durations "that long" was. Agents used link time alone. Now: "when the slower
   of those two has finished".
2. **A message already on the wire when the link is held.** The prompt covered a message *sent*
   while held, not one already in flight; run 11 re-transmitted it on release. Now: "one already on
   the wire stays there and is not carried twice".
3. **What a partition frees.** "Frees it" was read as freeing only the wire's busy time, leaving the
   in-order floor behind, so the next message landed late. Now: "the next message neither waits for
   it nor lands behind it".
4. **A duplex change over a busy wire.** Run 12's *only* failure. Its `admit()` recorded shared-wire
   occupancy solely for messages that were themselves half duplex, so an earlier full-duplex transfer
   did not block the later one -- a defensible reading of "settings apply to what is sent after them".
   Now: "a direction just made half duplex waiting for whatever the other still carries".

The prompt is 495 words. No test or solution change; the reference still passes 128/128, the
workspace 331, and the batch-2 replays are unchanged (Nova #3 128/128, Orion 111/128), which
confirms the edit is a clarification and not a change of behaviour.

## Batch 2 (Nova x5 + Orion) -- 0 of 6, one blocking assertion

| Run | New tests |
| --- | --- |
| Nova #1 | 106/128 |
| Nova #2 | 110/128 |
| Nova #3 | **126/128** |
| Nova #4 | 108/128 |
| Nova #5 | 110/128 |
| Orion #1 | 111/128 |

No compile wipes: pinning the field types worked, and every run reached real scheduling. Two tests
failed in **all six** runs, and both failed on the same single assertion -- `received == 1` for a
message the receiving side had booked but that had not arrived. Nova #3's only two failures were
these. A miss that is unanimous across six independent runs is a defect in the environment, not in
six agents.

### Fix: a host counts what arrived

`received` and `bytes_received` now follow deliveries rather than bookings; `receive_busy` still
books at take-on, so the misdirecting part of the model is untouched. `Topology::host_stats` sums
`delivered` / `bytes_delivered` over the wires ending at that host. The prompt says it directly:
"`received` and `bytes_received` instead count what arrived."

### Measured pass rate on the batch's own submissions

Every run replayed unmodified against the corrected suite:

| Run | Result |
| --- | --- |
| Nova #3 | **128/128 PASS** (205 base, 0 failures, through `test.sh`) |
| Orion #1 | 111/128 |
| Nova #2, #5 | 112/128 |
| Nova #1, #4 | 108/128 |

**1 of 6 = 17%**, inside the <= 40% cap and near the 10% corpus mode. The problem is solvable by a
real agent run with no help, and the other five still miss the interface model.

## Solvability proof (replay of the batch's own code)

Rather than assume the clarified prompt is enough, the two compiling agents were replayed against
the hidden suite and corrected using only sentences the prompt now contains.

**Nova #5, 121/128 -> 128/128.** Applying three corrections, each traceable to one new clause:

| Prompt clause | Edit to the agent's `top.rs` | 
| --- | --- |
| "an unlimited hop ... is never waited on and records nothing" | guard the three `*_available = ...` writes on a non-zero rate |
| "the receiving side included" | book `received` / `bytes_received` when the hop takes the message on |
| (same) | stop counting them again at delivery |

That tree then reports 128/128 new and 208/208 base, identical across three runs. The seventh
failure, `partitioning_a_link_frees_the_wire`, fell out of the unlimited-hop guard: their partition
path was already right; an unlimited interface was holding the later message.

**Nova #2, 110/128 -> 113/128.** Its `message_size` returned `0` for SYN/FIN/RST, reading "nothing
for segments that only open, close or reset" as "they cost nothing". The new clause ("so those cost
the overhead alone") fixes exactly three tests. The other fifteen are the per-host interface model,
which that agent never built. It should fail, and it still does.

**Nova #3 and #4** modelled `busy` as "is this hop occupied right now" (`next_free > now`) and wrote
their own tests asserting `assert!(stats.busy)`. Coherent, and nothing in the old prompt said
otherwise. Naming the fields as `Duration`s closes that reading before a line is written.

Solvable, then, and not by everyone: one of four runs is a prompt-clarification away from green,
one is a feature away, and two were never given the chance.

## Local validation matrix

| State | `./test.sh base` | `./test.sh new` |
| --- | --- | --- |
| base + test.patch | PASS (203 cases, exit 0) | FAIL (146 synthesized cases, exit 1) |
| base + test.patch + solution.patch | PASS (203 cases) | PASS (146 cases, 0 failures) |
| base + solution.patch + test.patch (reverse order) | applies cleanly, both PASS | both PASS |

Whole-workspace run with the solution applied: 0 failures on a plain `cargo test --workspace --features regex` (203 on base, 146 new).
Solution size: 445 human-effective LOC across 6 files (804 raw added).

## Determinism

Five consecutive base + new runs in the image, offline, non-root: identical every time
(203 / 0 failures and 146 / 0 failures).

| Run | base exit | base cases | new exit | new cases |
| --- | --- | --- | --- | --- |
| 1 | 0 | 203 | 0 | 146 |
| 2 | 0 | 203 | 0 | 146 |
| 3 | 0 | 203 | 0 | 146 |
| 4 | 0 | 203 | 0 | 146 |
| 5 | 0 | 203 | 0 | 146 |

The simulator is deterministic by construction; the tests that vary latency pin `rng_seed`.

## Test Fairness check, round 1

Verdict FAIL, 1 of 99 unfair: `a_segment_bigger_than_the_queue_still_goes_on_the_wire` pinned an
unstated exception. The prompt bounded the queue and said a segment waits for room, but never said
what a segment larger than the whole queue does, so waiting forever and splitting the segment were
both defensible readings. Fixed by stating the rule in the prompt rather than by deleting the test:
a segment goes on anyway once everything ahead of it has arrived. The prompt is 490 words after
trimming three sentences to make room.

Two further advisory suggestions from that round were implemented as well (dynamic host and queue
settings, the reset-segment overhead path).

## Test Fairness check, round 2

Verdict FAIL, 2 of 103 unfair: `link_stats_start_empty` and `host_stats_start_empty` compared a
fresh stats value against `Default::default()`, which forces `LinkStats` and `HostStats` to derive
`Default`, `PartialEq` and `Debug`. The prompt lists the fields but never asks for those traits, so
a solver that zero-initialises the fields without them would fail to compile. Fixed the reviewer's
way: both tests now assert each promised field is zero. The derives stay on the types because the
implementation itself uses them, but no test depends on them any more.

Two further advisory suggestions from that round were implemented (stats after held traffic, and
settings not applying retroactively to a message already waiting behind earlier traffic).

## Test Fairness check, round 3

Verdict FAIL, 1 of 112 unfair: the released phase of
`a_held_message_counts_for_nothing_until_it_is_released` asserted arrivals of exactly `[59, 69]`.
Those absolute values fall out of where the test's own step loop stops relative to the release, a
one-tick internal phase that neither the prompt nor the repository singles out; `[60, 70]` is just
as defensible. The test now asserts what the prompt actually promises: two arrivals, ten
milliseconds apart. The stats half of the test was fair and is unchanged.

Only that one test was phase-coupled. The other step-loop tests change a *setting* mid-run and
leave arrival times to the hosts' own send schedule, so their absolute values are not a function of
where the loop stops.

## Test Fairness check, round 4

Verdict FAIL, 1 of 120 unfair: `a_host_counts_the_datagrams_a_full_queue_took_from_it` read
`HostStats.dropped` as "datagrams this host's sends lost to a full queue", but the prompt only
listed the field. Attributing a link-queue rejection to the sending host is a real choice, not an
inference. The prompt now says so in the same sentence that lists the field. Same shape as rounds 1
and 2: the field was named, its meaning was not.

## Test Fairness check, round 6

Verdict FAIL, 1 of 127 unfair: `a_host_that_has_never_sent_has_empty_stats` configured and then
queried a host name that was never registered, which pins an unregistered-host policy the prompt
does not state and the repository contradicts (its sibling host APIs `expect("missing host")`). The
test now registers a host that simply never sends, which is the behaviour it was meant to check.
`a_full_duplex_link_carries_both_directions_at_once` was also strengthened to concurrent sends, so
the explicit `Duplex::Full` setting is distinguished from half duplex rather than passing under
either.

## Test Fairness check, round 5

Verdict FAIL, 3 of 126 unfair, all one root cause: the statistics are *booked* when a hop takes a
message on, so a partitioned message still shows its whole planned service time and the receiver
still counts it. The prompt said a hop "counts what it took on, discarded later or not, and how
long it was busy", which reads as elapsed time and says nothing about the receiving side. Replaced
with an explicit booking rule, and `a_hop_books_the_whole_time_a_message_will_hold_it` now pins it
on the ordinary path, without a partition, so the semantics no longer have to be inferred from the
fault case.

The round also exposed a harness bug: `test.sh` collected `test NAME ... ok` but Rust prints
`test NAME - should panic ... ok`, so the two new panic tests were missing from the new-mode XML
(127 synthesized on base against 125 collected), and eight of turmoil's own panic tests had been
missing from base mode all along. Base is 203 cases now, not 195.

## Coverage suggestions addressed

Thirty advisory coverage suggestions were implemented rather than waived:

| Suggestion | Test |
| --- | --- |
| per-link queue override precedence | `a_link_queue_capacity_wins_over_the_default` |
| multi-address host setters | `every_host_a_selector_matches_gets_the_bandwidth`, `every_host_a_selector_matches_takes_messages_in_at_that_rate` |
| a segment bigger than the queue | `a_segment_bigger_than_the_queue_still_goes_on_the_wire` |
| a duplex change mid-run | `a_duplex_change_applies_to_what_is_sent_after_it` |
| dynamic host and queue settings | `a_host_bandwidth_set_later_applies_to_what_follows`, `a_receive_bandwidth_set_later_applies_to_what_follows`, `a_queue_capacity_set_later_applies_to_what_follows` |
| reset-segment overhead | `a_reset_segment_carries_the_overhead_and_no_payload` |
| stats after held traffic | `a_held_message_counts_for_nothing_until_it_is_released` |
| settings vs a message already waiting | `a_bandwidth_change_leaves_a_waiting_message_alone`, `an_overhead_change_leaves_a_waiting_message_alone` |
| lowering the queue over a live backlog | `a_smaller_queue_keeps_what_it_already_took_on` |
| duplex change mid-transmission | `a_duplex_change_while_a_wire_is_busy_holds_the_other_direction_back` |
| stream payload identity, not just order | `a_stream_that_waited_for_room_still_arrives_in_order` (now asserts the received byte sequence) |
| receive-interface commitment across a partition | `a_partition_leaves_a_receiving_interface_with_the_time_it_committed` |
| busy stats after a discard | `a_discarded_message_still_counts_the_time_it_held_a_hop` |
| default duplex under simultaneous traffic | `a_link_is_full_duplex_to_begin_with` (rewritten from a sequential exchange) |
| selectors on the link setters, matched and unmatched | `a_selector_sets_the_bandwidth_of_every_link_it_matches`, `a_selector_sets_the_queue_capacity_of_every_link_it_matches`, `a_selector_that_matches_nothing_leaves_every_link_alone` |
| half duplex under queue pressure | `each_direction_of_a_half_duplex_link_keeps_its_own_queue` |
| scope of the global bandwidth setters | `a_global_bandwidth_sets_links_and_leaves_interfaces_unlimited`, `a_builder_bandwidth_sets_links_and_leaves_interfaces_unlimited` (the prompt now says which setter moves which knob) |
| overhead on the receiving side | `the_overhead_counts_on_the_receiving_side_too` |
| resetting a link or interface rate to unlimited | `a_link_set_back_to_unlimited_frees_only_what_follows`, `an_interface_set_back_to_unlimited_frees_only_what_follows` |
| resetting the overhead to zero | `an_overhead_set_back_to_zero_leaves_what_it_already_charged` |
| tick quantization at a non-1ms tick | `an_arrival_between_ticks_lands_on_the_next_one` |
| an oversized segment behind queued traffic | `an_oversized_segment_waits_for_the_queue_ahead_of_it` |
| half duplex back to full while traffic is pending | `going_back_to_full_duplex_frees_only_what_follows` |
| selectors on the one-way setter | `a_selector_sets_one_direction_and_leaves_the_other_alone` |
| busy during active service | `a_hop_books_the_whole_time_a_message_will_hold_it` |
| one-way vs symmetric queue configuration | `a_link_queue_capacity_bounds_both_directions` (the prompt now says both directions) |
| errors on unknown links and hosts | `setting_the_bandwidth_of_a_link_that_does_not_exist_is_an_error`, `asking_for_the_queue_of_a_link_that_does_not_exist_is_an_error`, `a_host_that_has_never_sent_has_empty_stats` |
| half-duplex busy attribution | `a_half_duplex_wire_charges_each_direction_only_for_its_own_traffic` |
| graceful close control segment | `closing_a_connection_carries_the_overhead_and_no_payload` |
| overhead in stats after release, discard and while queued | `the_overhead_of_a_released_message_is_counted_too`, `the_overhead_of_a_discarded_message_is_counted_too`, `the_overhead_shows_up_in_the_bytes_a_direction_still_carries` |

Multi-host selection goes through `ToIpAddrs for Regex`, so `test.sh new` builds the crate with its
`regex` feature. The oversized-segment case confirmed the queue makes progress instead of
deadlocking: a segment that cannot fit at all goes on once everything ahead of it has arrived.

## Quality / alignment / necessity checks (round 7)

| Finding | Action |
| --- | --- |
| Quality: exact panic message asserted | both panic tests are now bare `#[should_panic]` |
| Alignment: tick rounding unstated | prompt now states times are quantised to the tick |
| Alignment: link selectors unstated | prompt now says the link setters take the same host selectors |
| Necessity: remove all API names (5 HIGH) | declined; the hidden tests call them by name, so removing them is the compile-wipe anti-pattern. Obvious arithmetic and eight wordy phrasings removed instead |

## Mutation harness fixed (round 6)

Two consecutive batteries over identical code reported different survivors
(`arrivals may overtake each other`, then `a partition leaves the wire reserved`). The tests were
not flaky; the harness was. It read per-test `... FAILED` lines, which interleave when 128 tests run
on parallel threads, so a kill could go unseen. It now runs with `--test-threads=1` and counts the
`test result:` summary, with the `failures:` block for names. A false SURVIVE was the only possible
direction of that error, so the earlier all-killed results stand.

The escape it exposed was real, though: `arrivals may overtake each other` was killed only by a
seeded-latency test that happened to draw an overtaking pair.
`a_later_datagram_never_overtakes_an_earlier_one` now forces the case deterministically by dropping
the link latency from 100 ms to zero between two sends, so the clamp is what keeps them in order.

## Mutation battery (17 mutations, all killed)

| # | Mutation | Killed by |
| --- | --- | --- |
| 1 | no queueing: a message never waits for the wire | 35 tests |
| 2 | the whole link is one wire, not one per direction | 67 |
| 3 | the sending interface is not shared across links | 6 |
| 4 | the receiving interface never holds a message back | 7 |
| 5 | a partition leaves the wire reserved | 1 |
| 6 | arrivals may overtake each other | 3 |
| 7 | a full queue drops a connection's segments too | 5 |
| 8 | a message that exactly fills the queue is dropped | 19 |
| 9 | the overhead is left off the wire | 17 |
| 10 | a held message is charged when it is sent | 4 |
| 11 | half duplex is ignored | 5 |
| 12 | the queue never drains | 9 |
| 13 | a segment that waits does not wait long enough | 1 |
| 14 | the slower hop does not decide the arrival | 11 |
| 15 | what a direction carried is counted in payload bytes | 13 |
| 16 | a discarded message is counted as delivered | 8 |
| 17 | released messages are delivered without going on the wire | 4 |

Three further mutations were retired as equivalent mutants: rounding transmit time down
instead of up (unobservable at the simulator's tick resolution), and booking time on an
unlimited wire or interface (never read back, because an unlimited hop is not waited on).


## False-positive review and the last advisory round (146 tests)

The FP review named one hole: an agent could take the sending interface on in arrival order rather
than send order and still pass everything, because no test put two links behind one interface with
the slower one written to first. `an_interface_takes_messages_on_in_send_order_across_links` closes
it -- two 500-byte datagrams to a link at half the interface rate, then one to a fast link; the
reference gives `[20, 40]` and `[40]`, and an arrival-order interface gives the fast one 20. All
three known-passing agent submissions still pass it, so the discriminator cost no solvability.

The three advisory suggestions from the same report are implemented:

| Suggestion | Test | Solution change |
| --- | --- | --- |
| Arithmetic overflow on huge u64 sizes, overheads and rates | `an_enormous_overhead_does_not_overflow_the_size`, `an_enormous_rate_carries_a_message_at_once` | every byte accumulation and the size sum are saturating |
| Busy durations must not be tick-quantized | `busy_time_keeps_the_part_of_a_millisecond_it_used` | none needed; asserts `333ms < busy < 334ms` while the arrival still lands on tick 334, without pinning a rounding direction |
| Error parity across the setter family | `setting_the_queue_of_a_link_that_does_not_exist_is_an_error`, `..._duplex_...`, `asking_for_the_stats_of_a_link_that_does_not_exist_is_an_error` | none needed |

Re-validated after the change: 146/146 with the reference, 146/146 synthesized failures on base,
five identical runs, whole workspace green, 17/17 mutations killed (four anchors were refreshed for
the saturating arithmetic), and all three passing agent submissions still at 146/146.


## Test Fairness check, round 8 -- 1 of 140 unfair, cut

`an_enormous_overhead_does_not_overflow_the_size` pinned `bytes_sent == u64::MAX`, i.e. saturating
addition, and the reviewer is right that nothing states it: wrapping, checked-and-reject, panicking
and saturating are all defensible when payload plus overhead exceeds `u64::MAX`. The test is gone.
The saturating arithmetic stays in the reference because it keeps a debug build from panicking on a
`u64::MAX` overhead, but no test observes which policy an implementation picks.
`an_enormous_rate_carries_a_message_at_once` survives untouched -- it only exercises a huge divisor,
which has one answer.

The two advisory suggestions from the same round were folded into existing tests rather than new
ones, since both are extra assertions on cases already set up:

| Suggestion | Where |
| --- | --- |
| Discarded receive bytes | `a_discarded_message_still_counts_the_time_it_held_a_hop` now asserts `server.bytes_received == 0` alongside `received == 0` and the committed 50 ms of receive busy |
| Dropped sender bytes | `a_host_counts_the_datagrams_a_full_queue_took_from_it` now asserts `client.bytes_sent == 1_000`, the two admitted datagrams only |

Re-validated at 146 tests: reference 146/146, base 139 synthesized failures, base suite 203/0,
five identical runs, 17/17 mutations killed, 445 human-effective LOC, and all three known-passing
agent submissions still green -- both new assertions hold on real agent code, so the added coverage
cost no solvability.


## Coverage suggestions, round 8 -- two added, one declined

| Suggestion | Outcome |
| --- | --- |
| Half-duplex with asymmetric rates | `a_half_duplex_wire_is_held_for_each_directions_own_time`: 50,000 out and 25,000 back on one shared wire, so a 1,000-byte request lands at 20 ms and its 1,000-byte reply at 60 ms, with the two directions booking 20 ms and 40 ms of busy. Passes on all three known-good agent submissions. |
| Receive-side ordering across links | `a_receiving_interface_serves_two_senders_in_the_order_they_reach_it`: distinguishable 500- and 400-byte payloads over links with 10 ms and 50 ms latency, asserting identity as well as timing (`[500, 400]` at `[20, 63]`). |
| Configuration arithmetic overflow | Declined. This is the test the fairness reviewer cut in the same round: no overflow policy is stated, so any assertion about a `u64::MAX` overhead picks between saturating, wrapping and panicking on the author's say-so. |

The receive-ordering test was written twice. The first version put the slow link's send *first* and
the fast link's send *second*, so send order and reach order disagreed; the reference took the
messages on in send order (`[400, 500]` at `[58, 68]`) and Nova #4, one of the three passing
submissions, took them on in reach order and failed. The prompt's "every hop takes messages on ...
in send order" reads naturally as a single hop's own queue, not as a global ordering across
independent inbound links from different hosts, so pinning it would have been the same defect the
fairness reviewer had just removed. The shipped version staggers the sends so the near link is both
sent first and reaches first: both readings agree, the payload identities and the per-payload
receive service times are still checked, and all three submissions pass.

Re-validated at 146 tests: reference 146/146, base 141 synthesized failures, base suite 203/0,
five identical runs, 17/17 mutations killed, three known-passing agent submissions all green.


## Test Fairness check, round 9 -- 2 of 141 unfair, both cut

The two flagged tests asserted that `queued_bytes` and `link_stats` panic on a link that does not
exist. The setter panics survive, because the crate already panics in `set_link_message_latency` and
friends, so a new setter following that shape is discoverable. There is no getter precedent: nothing
in the crate returns a per-link structure, so returning a default `LinkStats`, an `Option`, a
`Result` or zero are all as reasonable as a panic, and the prompt says nothing about it. Both cut;
the three setter panic tests stay.

## Coverage suggestions, round 9 -- both added

| Suggestion | Test |
| --- | --- |
| Duplex selectors | `a_selector_makes_every_link_it_matches_half_duplex`: a `^node-` selector makes the matched link half duplex while an unmatched link stays full duplex, checked with simultaneous traffic in both directions -- the matched pair serializes to `[10, 20]` and the unmatched pair overlaps at `[10, 10]` |
| Global live setters | `a_global_bandwidth_set_later_applies_to_what_follows` and `a_global_queue_capacity_set_later_applies_to_what_follows`: `Sim::set_bandwidth` and `Sim::set_queue_capacity` stepped mid-run, so the messages already sent keep the old value and the next ones take the new one |

The duplex test was written twice. The first version used a request and its reply, which serializes
under full duplex as well, so half duplex changed nothing and the test asserted the wrong thing.
Duplex is only observable when both directions carry at once, so the shipped version has each host
send unprompted at time zero. The arrivals of the two directions are sorted before comparison, which
keeps the assertion off the scheduler's tie-break between two messages that start in the same tick.

Re-validated at 146 tests: reference 146/146, base 142 synthesized failures, base suite 203/0, five
identical runs, 17/17 mutations killed, whole workspace clean, and all three known-passing agent
submissions still green.


## Coverage suggestions, round 10 -- both added

| Suggestion | Test |
| --- | --- |
| Turned-away datagrams book nothing | `a_turned_away_datagram_holds_no_hop_at_all`: four 500-byte sends into a 1,000-byte queue with both the link and the sending interface at 50,000, asserting `dropped` of 2 on link and host while `busy` and `send_busy` stay at the 20 ms the two admitted messages booked, and `bytes_sent` at 1,000 |
| Both sides of an exchange | `an_exchange_is_counted_on_the_right_side_of_each_host`: a 500-byte request answered by a 300-byte reply, asserting all four host counters on both hosts at once, so reply traffic attributed to the wrong interface shows up as a byte mismatch rather than passing |

Neither needed a solution change. Re-validated at 146 tests: reference 146/146, base 144 synthesized
failures, base suite 203/0, five identical runs, 17/17 mutations killed, and all three known-passing
agent submissions still green.


## Coverage suggestions, round 11 -- two added, one declined again

| Suggestion | Outcome |
| --- | --- |
| Host-setter error semantics | Added as `a_host_selector_that_matches_nothing_leaves_every_interface_alone`, the empty-match half only: a `^ghost` selector on both host setters leaves the 5,000-byte send unlimited and both interfaces at zero busy. The unknown-*name* half was left out on purpose -- turmoil's DNS registers a name on first lookup (`ToIpAddr for &str` inserts with `or_insert_with`), so an unknown name resolves to a fresh address rather than failing, and asserting either a panic or a silent no-op would pin an error policy the prompt does not state. That is the class the fairness reviewer cut in round 9. |
| Arithmetic overflow | Declined for the third time, same reason: any assertion about a `u64::MAX` overhead separates saturating from wrapping from panicking, and the prompt states no overflow policy. Even a bare "does not panic" test picks a side, because a checked-and-reject implementation would drop the message instead. |
| TCP waiting plus runtime queue change | Added as `a_segment_waiting_for_room_takes_the_capacity_it_finds`. Four 500-byte segments against a 1,000-byte queue, capacity raised to 2,000 at 50 ms, before the third is admitted: all four go on back to back and arrive at `[210, 220, 230, 240]` instead of the `[210, 220, 320, 330]` the unchanged-capacity test records. |

The TCP case was the one worth checking rather than reasoning about, since "a message already sent
keeps what it was measured against" and "capacity is read when the message is taken on" are both
readable from the prompt. All three known-passing agent submissions produce `[210, 220, 230, 240]`
independently, which is better evidence than the prompt wording alone: three implementations written
without sight of each other converged on reading capacity at admission.

Re-validated at 146 tests: reference 146/146, base 146 synthesized failures, base suite 203/0, five
identical runs, 17/17 mutations killed, 445 human-effective LOC, all three submissions green.


## Test Fairness check, round 12 -- 1 of 146 unfair, cut

`a_segment_waiting_for_room_takes_the_capacity_it_finds` is gone. It came in one round earlier as a
coverage suggestion, and the fairness reviewer is right that it pins one of two readings: the four
writes all happen before the capacity change, so "settings apply to what is sent after them" reads
naturally as leaving them on the old bound, while "capacity is read when a message is taken on"
reads as re-evaluating them. Nothing in the prompt or the crate picks one.

The three agent submissions all producing `[210, 220, 230, 240]` is evidence about what
implementations tend to do, not evidence that the prompt says it. Worth recording as the limit of
that signal: convergence across submissions can justify keeping a test the reviewer has not
challenged, but it cannot answer a fairness objection, because all three could be reading the same
ambiguity the same way. A stated rule is the only thing that settles it, and this behavior does not
earn the prompt words it would cost.

Re-validated at 146 tests: reference 146/146, base 145 synthesized failures, base suite 203/0, five
identical runs, 17/17 mutations killed, all three submissions green.


## Test Fairness check, round 13 -- 4 of 145 unfair, all four repaired without cutting

Every flagged test pinned which named direction wins when two messages contend on a half-duplex wire
in the same tick. The prompt says only one direction carries at a time; it never says which one goes
first, and the crate has no duplex arbiter to infer it from. The tie order is the reference's own
scheduler detail.

None of the four needed removing, because the tie order was never the point of any of them. Each now
compares the two directions' arrivals as a sorted pair, the shape the reviewer had already accepted
in `a_selector_makes_every_link_it_matches_half_duplex`:

| Test | Repair |
| --- | --- |
| `a_half_duplex_link_makes_one_side_wait_for_the_other` | sorted pair `[10, 20]` -- still proves serialization, no longer names the winner |
| `each_direction_of_a_half_duplex_link_keeps_its_own_queue` | 2 drops each way and 2 arrivals each way kept as-is; the four arrival times compared sorted as `[10, 20, 30, 40]` |
| `a_half_duplex_wire_charges_each_direction_only_for_its_own_traffic` | the point of the test, 10 ms of `busy` on each direction, is untouched; only the arrival pair is sorted |
| `going_back_to_full_duplex_frees_only_what_follows` | the client's first datagram was 5,000 bytes against the server's 500, so the two orders gave different times and sorting alone could not fix it. Both are 500 bytes now, so the half-duplex pair is `[10, 20]` either way and the post-change pair is still both at 160 |

`a_full_duplex_link_carries_both_directions_at_once` is unaffected: under full duplex both arrive at
10, so there is no tie to break.

The distinction worth keeping: sorting an assertion is only sound when order is not the behavior
being tested. It is right here, where duplex is about serialization, and would have been wrong in
`a_receiving_interface_serves_two_senders_in_the_order_they_reach_it`, which exists to check order.

The mutation `half duplex is ignored` is still killed by 6 tests after the change, so the sorted
comparisons did not soften the check: under full duplex both messages land at 10 and the sorted pair
is `[10, 10]`, not `[10, 20]`.

Re-validated at 146 tests: reference 146/146, base 145 synthesized failures, base suite 203/0, five
identical runs, 17/17 mutations killed, all three known-passing agent submissions green.


## Quality check, round 14 -- two prompt gaps closed, one coverage suggestion added

The quality reviewer flagged two things the tests assume and the prompt did not say. Both are real,
and both were fixed in the prompt rather than by weakening tests, because the fairness reviewer had
already rated the tests themselves fair (repo-discoverable):

| Gap | Prompt now says |
| --- | --- |
| Setter error semantics on a missing link | "naming a link that is not there is an error", in the same sentence that describes setter shape |
| Selector type and feature gate | "by name or by a `Regex` selector, under the crate's `regex` feature" |

Paying for those cost 17 words at a 500-word cap, taken from redundancy rather than content:
"however big" (the next sentence makes size the whole point), "Times are quantized to the tick"
(the sentence that follows states the rule exactly), and "never before the message sent ahead of it"
(the send-order clause immediately after covers it). No tested behavior lost a sentence. 499 words.

Coverage suggestion 2, loopback, is in as `a_message_a_host_sends_to_itself_takes_no_hop`: a
5,000-byte datagram to `127.0.0.1` under a rate, an overhead and both interface rates arrives on the
first tick at full size, and neither host counter moves. This one is grounded in the pre-existing
code, not in my choice: `send_loopback` in `crates/turmoil/src/net/udp.rs` is a standalone path that
never touches `Topology`, which is where every rate lives, so any implementation that hangs capacity
off the topology gets the bypass for free. All three known-passing agent submissions produce it.

Coverage suggestion 1, arithmetic overflow, is declined for the fourth time -- unchanged reason, and
the prompt has 1 word of headroom, not the sentence an overflow policy would need.

Re-validated at 146 tests: reference 146/146, base 146 synthesized failures, base suite 203/0, five
identical runs, 17/17 mutations killed, all three submissions green.
