# eval-results — avr8js-sleep-power-management

No platform agent batch has been run yet. This file records the local validation that gates the
batch, and is where the per-agent table goes once the runs come back.

## Local gate results

| Gate | Result |
| --- | --- |
| Behavioral f2p gap | `SLEEP` is `/* not implemented */` on base; SMCR and PRR absent |
| Effective LOC (hook `human-effective`) | 416 across 13 files, 551 raw |
| New tests | 284 cases, 284 fail on base, 0 fail solved |
| Base regressions | none (347 cases green both ways) |
| Flakiness | five consecutive base and new runs identical |
| Both apply orders | clean |
| Environment Quality proxy | vanilla `npm test` green offline, 8.3 s |
| FP mapping | complete in both directions (see feedback.md) |
| Mutation battery | 28 of 28 mutants killed (see feedback.md) |

## Solvability proof

The batch 1 passing run was replayed against the current artifact: agent solution + current
`test.patch` on a pristine clone, offline in the base image.

| Replay of `rd7bjm66t34bde6qw90zdpr1td8c761v` | Result |
| --- | --- |
| New tests | **242 of 242 pass** |
| Baseline tests | **347 of 347 pass** |

The seven coverage rounds and two Auto Review fixes that grew the suite from 234 to 271 cases did
not cost solvability. Artifacts in `Task46/agent-runs(5)/Vega_Nova/`.

## Per-agent table

| Agent | Evaluator | Verdict | Messages | Files touched | LOC | Failed test names | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Nova 3 / 6 / 8 / 10 (batch 4) | replay | **PASS** on the final 246-case suite | - | - | - | none | - | Confirmed by replaying their solution patches in the base image |
| Nova 1 / 2 / 9 / 11 (batch 4) | replay | 1 failure each | - | - | - | one each | - | Just short: ATtiny asynchronous getter, gated-SPI resume, pending-interrupt wake, ADC gate |
| Vega (batch 1) | Nova | **PASS_LEGITIMATE** | 39 | 13 | 784 | none | - | Central peripheral-clock model; still passes the current 271-case suite on replay |
| Vega x3 (batch 2) | Nova | FAIL_MISSED_REQUIREMENT | - | - | - | same 29, timer gating | events due at the sleep-entry cycle still fired | off-by-one at the suspend boundary |
| Nova x5 + Vega (batch 3) | Nova | FAIL_MISSED_REQUIREMENT | - | - | - | 4 to 30, disjoint | work started while gated dropped; wake boundary; ADC entry | no shared blocker across the six |

## Platform batch, round 1

10 runs, **1 pass** (10%), inside the <=40% band. Every run passed all 347 baseline tests and the
nine failures passed 194-231 of the 234 new tests, at 659-804 added lines across 13-14 files and
53-88 messages. The reviewer's own read: "a difficult but coherent cross-cutting task", with no
leakage, duplication, environment blocker or false-positive pass.

| Failure mode | Runs | Reviewer classification |
| --- | --- | --- |
| Missed the exact sleep-entry or six-cycle wake boundary | 6 | subtle but fair |
| Treated a USART write made while PRR-gated as rejected rather than paused work | 5 | shared blind spot |
| Got ADC noise reduction entry gating or timing wrong | 3-4 | subtle but fair |

All three reviewers explicitly declined to treat the USART convergence as a specification gap,
since the description already says a stopped peripheral keeps its state and carries on with the
time it owed. The wording stays as it is.

## Platform batch, round 2 (Vega x3)

0 of 3 passed, all FAIL_MISSED_REQUIREMENT, all 347 baseline tests green in every run and
242-243 of 272 new tests passing. All three failed on the same off-by-one: events due exactly at
the sleep-entry cycle were still allowed to fire, so stopped timers gained a cycle.

Cumulative across both batches: **1 pass in 13 runs, about 8 percent**. Solvable (one legitimate
full pass) and well inside the 40 percent ceiling.

| Evaluator field | Vega 1 | Vega 2 | Vega 3 |
| --- | --- | --- | --- |
| description_clear | true | true | true |
| tests_deterministic | true | true | true |
| difficulty | challenging | challenging | challenging |
| was_mentioned_in_description | true | true | true |
| blocker_detected | false | false | false |
| agent_blame_unfair | false | false | false |

One test was withdrawn as a result of this batch: see feedback.md.

## Platform batch, round 3 (5 Nova + 1 Vega)

0 of 6 passed, all FAIL_MISSED_REQUIREMENT, all 347 baseline tests green in every run. Failure
counts 4, 6, 7, 12, 15 and 30 out of 271. Every evaluator again recorded description_clear,
tests_deterministic, difficulty challenging, was_mentioned_in_description, and no blocker.

**Zero tests failed in all six runs**, and every run also failed at least one original-block test,
so there is no shared blocker and the coverage rounds did not reduce solvability. The closest run
(Nova #3, 4 failures) died entirely on one concept: work issued while a clock was gated.

Cumulative over three batches: **1 pass in 19 runs, about 5 percent**. Solvable, inside the 40
percent ceiling, at the hard edge of the band.

| Modal failure | Runs (of 19) |
| --- | --- |
| Work started while gated treated as rejected rather than held | 9 |
| Sleep-entry or six-cycle wake boundary off by one | 12 |
| ADC noise reduction entry gating or timing | 7 |

All three were reworded in meta.md after this batch, each as a clarification of an implicit
boundary rather than a change of behavior; see feedback.md. Test count and semantics unchanged,
and both the reference solution and the batch 1 winning agent still pass 271 of 271.

## Platform batch, round 5 (Auto Review pool)

Auto Review reports **2 of 10 passed (20 percent)**, all runs preserving the full baseline suite,
failures reaching 254-263 of 264 new tests across 13-15 files and 616-806 added lines. Its own
read: "a genuinely hard but fair task", with no leakage, trivial solve or test manipulation. The
recurring failure remains work submitted after a gate closed and its owed time, which is the
requirement the FP round hardened.

## Platform batch, round 4 (14 Nova + 3 Vega) and the rebalance

0 of 17 passed, every run green on all 347 baseline tests. The previous round's clarifications
worked: the 29-to-30-failure cascades were gone and three runs finished on a single failure. But
the distribution showed roughly eight independent micro-rules, each missed by a third to a half of
agents, so the joint probability of a pass was near zero.

Three axes were removed from both description and tests: the six-cycle wake latency, the ADC
auto-start on entering noise reduction, and the one-cycle `SLEEP` assertion. Measured against the
17 recorded failure sets, the final 242-case suite yields:

| | |
| --- | --- |
| Would pass | **4 of 17, 23.5 percent**, confirmed by replaying the agent solutions themselves |
| At exactly 1 remaining failure | 4 more |
| Ceiling check | 23 percent is inside the 40 percent cap; keeping the queued-after-gate axis matters, since dropping it too would have given 47 percent and a too-easy reject |

## Predicted difficulty

Target band is at or under 40% pass. The traps that should carry it, in the order they are
expected to bite:

1. **Timebase rebase.** Suspending a clock event is the obvious half of the fix; re-basing the
   timer's elapsed-cycle arithmetic onto a clock that freezes is the half that is easy to miss,
   and without it every stopped timer jumps forward the moment it restarts. Expected to be the
   most common failure.
2. **Wake with the global interrupt flag clear.** `tick()` only ever dispatched interrupts when
   `interruptsEnabled`, so hanging the wake off that same branch is the natural edit and leaves
   the CPU asleep forever whenever `I` is clear.
3. **Asynchronous timer 2.** Power-save reads as "power-down plus timer 2"; the ASSR condition
   is one clause further on.
4. **Wake latency ordering.** Six cycles is easy; spending them before the clocks come back is
   what the cycle-exact assertions pin.
5. **Edge versus level external interrupts.** A uniform "interrupts still wake the chip" rule
   passes the pin change tests and fails the edge ones.

## Iteration history

| Round | Change | Result |
| --- | --- | --- |
| 1 | First implementation, 105 tests | 4 test-authoring errors, all in the tests |
| 2 | Fixed the four tests | 111 pass, 369 human-effective (under floor) |
| 3 | Added the ATtiny configuration and the ASSR asynchronous rule | 471 pass, 412 human-effective |
| 4 | Reset while asleep must not charge the wake latency (real bug in the first cut) | 474 pass, 416 human-effective |
| 5 | FP mapping pass, six orphan clauses closed with tests | 141 new cases, no orphans either direction |
| 6 | Platform coverage suggestions: renumbered `AVRSleepMode` to the datasheet selection values so exact `mode` assertions do not pin an unstated ordering, plus post-wake continuation, USART PRR resume and ATtiny ADC noise reduction | 157 new cases, 417 human-effective |
| 7 | Second coverage round (combined sleep/PRR gate on the asynchronous timer 2, lost edges not deferred, ADC paused in every deeper mode) plus a mutation battery; bounded an unbounded `while (cpu.sleeping)` loop that hung under a wrong solution | 170 new cases, 8 of 8 mutants killed |
| 8 | Third coverage round: remaining timer-by-mode matrix cells and an isolated wake-latency boundary (the six cycles are charged, the stopped timer accrues none of them, counting starts on the next cycle) | 183 new cases, 11 of 11 mutants killed |
| 9 | Fourth coverage round: masked wake from a deep mode (interrupt stays pending, vector not taken, latency still charged) and the ATtiny power-down matrix for its timer 1 and an in-progress conversion | 195 new cases, 14 of 14 mutants killed |
| 10 | Fifth coverage round: `mode` stays null through a reserved selection, the ATtiny wake latency, and the clear case of the asynchronous getter | 207 new cases, 18 of 18 mutants killed |
| 11 | Sixth coverage round: a conversion started before idle runs to completion and wakes, and direct register retention for the SPI, USART0, ADC and EEPROM under both gates | 219 new cases, 20 of 20 mutants killed |
| 12 | Seventh coverage round: a relocated device configuration (documented fields only) and direct interrupt suppression for the SPI, USART0, ADC and TWI; the EEPROM was left out with a written reason | 234 new cases, 23 of 23 mutants killed |
| 27 | FP review round 3: closed the sleep-entry guard defect with a register-observable assertion (mutant-verified); dropped 2 self-authored tests that contradicted the reference's immediate-wake behavior; stated the ADSC visibility of the auto-started conversion in meta.md after replay showed it blocking 2 otherwise-passing runs | 284 tests, meta 484 words, fresh batch needed to re-measure |
| 26 | FP review round 2 (1 upheld of 4): covered a pin carrying both an edge and a pin change interrupt while the I/O clock is stopped (5 tests, mutant kills 3); also asserted ADSC on the auto-started conversion, which costs 2 of 3 replay passers but closes a fair FP vector | 282 tests, replay pool 3/17 -> 1/17, Auto Review pool was 2/10 |
| 25 | Auto Review round 2: Description 3/3, Solution 3/3, all five FP adjudications Genuine Pass; closed the one High test finding by covering the separate USART receive path (6 tests, mutant-verified 3 kills) | 276 tests, pass rate held at 3/17 |
| 24 | FP review: closed the upheld defect (work submitted after the gate closed must owe only its own duration, not the dead time before submission) with 6 SPI/ADC tests, mutant-verified 4 kills; declined the bare-CPU probe as unfair per the second adjudication | 270 tests, pass rate 4/17 -> 3/17 as Nova 3 was correctly reclassified |
| 23 | Last coverage round: timer post-gate submission and the ATtiny auto-start mirror added as asked; the scheduler-precision suggestion re-expressed as a consequence, because the literal exact-cycle form broke 3 of the 4 passing agents on an unstated scheduling granularity | 264 tests, 4/17 restored |
| 22 | Final coverage round: focused same-cycle gate-cutoff tests (SPI-based, since the timer's own guard made a timer version non-discriminating); the submit-after-gate suggestion was already covered by USART and TWI | 256 tests, 4/17 held |
| 21 | Restored the ADC auto-start (LOC fell to 396 without it) as a stated, tested behavior; assertions rewritten against the wake consequence after replay showed the old `ADSC` bit assertion broke all four passing agents | 251 tests, 416 human-effective, 4/17 confirmed by replay |
| 20 | Solution Quality FAIL: diagnosed as stale (38 synthesized failures == the 38 tests deleted in the rebalance, 280-242); removed the two vestigial code paths the rebalance orphaned, including the wake-latency `cpu.cycles` mutation the reviewer cited | 422 human-effective, 246 tests unchanged |
| 19 | Test Fairness FAIL (1 of 66): removed the exact-cycle pin from the masked idle wake, left behind when the wake-latency axis was deleted; added both coverage suggestions (ATmega ADC noise-reduction completion, ADC sleep/PRR composition); verified by replay that all four passing agents still pass | 246 new cases, 4/17 measured |
| 18 | Batch 4 (0/17): removed the wake-latency, ADC-entry and one-cycle-SLEEP axes from description and tests after measuring that axis removal, not test trimming, is what moves the rate; projected 4/17 = 23% | 242 new cases, meta 464 words |
| 17 | Eighth coverage round: work submitted after a PRR gate has already closed (SPI and ADC) held then completed on release, and `mode` cleared on every interrupt wake path | 280 new cases, 28 of 28 mutants killed |
| 16 | Interface check FAIL: `mode` and `asynchronous` were attributed to the CPU after a word-saving trim turned "The peripheral" into "It"; the CPU / `AVRPower` split is now explicit and verified against the test file | meta.md 494 words, tests unchanged |
| 15 | Batch 3 (0/6): confirmed no shared blocker and no solvability loss from the coverage rounds, then reworded the one genuine ambiguity (work started while a clock is gated is held, not refused) | meta.md 489 words, tests unchanged, runs staled |
| 14 | Vega batch (0/3, same off-by-one in all three): withdrew `keeps a timer whose configuration names no clock on the I/O clock` after an evaluator flagged it as more specific than the prompt | 271 new cases, all other findings unchanged |
| 13 | Auto Review round 1 (revision requested): fixed the external-clock gating bug and the mandatory `clock` field regression in the solution, parameterized SPI / USART0 / EEPROM gating over all five non-idle modes, and split the two densest description paragraphs | 272 new cases, 26 of 26 mutants killed, 423 human-effective |
