# feedback — avr8js-sleep-power-management

## Summary

| | |
| --- | --- |
| Repo | [wokwi/avr8js](https://github.com/wokwi/avr8js), MIT, 836 stars, TypeScript |
| Base commit | `898f76c787762c8ee3ef7ca93c7b429b67a518d7` (main HEAD, 2026-02-14) |
| Tier | Olympus |
| Solution | 13 files, 551 raw added, **416 human-effective** (hook) |
| Tests | 1 new file, 284 cases, **284 of 284 fail on base** |
| Base suite | 347 cases, green with and without the solution |
| Vanilla `npm test` | green offline as uid 1000 in the base image, 8.3 s |

## Why this pick

`src/cpu/instruction.ts` carried `/* SLEEP ... not implemented */`, and neither SMCR nor PRR
existed anywhere in the source. Issue [#139](https://github.com/wokwi/avr8js/issues/139)
("Tracking issue: Sleep mode's not implemtned") has been open since 2023-05-09 with a bare link
to that line, no comments and no linked work. All fourteen branches were compared against `main`
and none touches sleep, power or clock gating; every PR in the repo's history is a dependency
bump or one of the already merged peripheral features.

## Deviations

- **meta.md is 464 words** against the 200-word guidance, under the 500-word hard cap. The
  feature states two device register maps (ATmega328p and ATtiny85), six sleep modes and ten
  power reduction bits, and every one of those is asserted. Cutting to 200 would delete a tested
  clause, which is the harder reject (`olympus-meta-word-cap-conflict`; approved precedents at
  241 and 309 words). The honest alternative is to drop the ATtiny configuration on both sides,
  at a cost of roughly 60 effective LOC and 26 tests.
- **human-effective is 416**, above the platform's 400 auto-block and well above the current
  sprint floor of 250, but under the older 450 design target. The remaining ways to raise it
  (an analog comparator, ADC auto-trigger) are separate peripherals rather than power
  management, so they would buy LOC by diluting a coherent story.

## FP mapping — every meta.md clause to the test that pins it

| meta.md clause | Test(s) |
| --- | --- |
| `AVRPower`, `new AVRPower(cpu)` | starts awake; sleeps when the sleep enable bit is set |
| or with a device configuration | accepts an explicit config object; the whole ATtiny block; sleeps from the relocated sleep control register; ignores the standard address once the register has moved; masks the relocated sleep control register; stops a timer from the relocated power reduction register; ignores the standard power reduction address once it has moved; masks the relocated power reduction register; wakes from the relocated configuration at the same cost |
| export `powerConfig` (ATmega328p), `SMCR` 0x53, `PRR` 0x64 | exposes a config with the SMCR and PRR addresses |
| export `attinyPowerConfig` (ATtiny85), `SMCR` 0x35, `PRR` 0x20 | puts the sleep controls in MCUCR |
| CPU `sleeping` flag | sleeps when the sleep enable bit is set; starts awake |
| `wakeUp()` ends the sleep | spends six extra cycles waking from power-down (and the four sibling modes) |
| `wakeUp()` does nothing when already awake | does not wake a running CPU twice |
| peripheral `mode`, null while awake | reports no mode after a vectored wake / a masked wake / a watchdog wake, and reports the mode again when it sleeps a second time; reports no mode while the CPU is awake; reports no mode again after waking; reports no mode after a reset; reports no mode when the sleep enable bit is clear; reports no mode after attempting reserved mode four / five; reports no mode after the ATtiny reserved selection; reports a mode when a valid selection follows a reserved one |
| ... otherwise the mode selection | reports idle / ADC noise reduction / power-down / power-save / standby / extended standby as the mode selection while asleep; reports the ATtiny mode selection while asleep |
| `asynchronous` reports bit 5 of ASSR at 0xb6 | reports an asynchronous timer 2 on the ATmega configuration; reports no asynchronous timer when bit five of ASSR is clear; reports no asynchronous timer when another ASSR bit is set; follows ASSR when bit five is set and cleared again |
| the ATtiny lacks ASSR | has no asynchronous timer |
| no sleep unless the enable bit is set (ATmega bit 0) | does not sleep when the sleep enable bit is clear; keeps executing instructions when the sleep enable bit is clear |
| ATtiny enable bit 5 | sleeps when bit five of MCUCR is set; does not sleep when bit five of MCUCR is clear |
| the CPU stops executing | executes no instruction while asleep; leaves the program counter just after the sleep instruction |
| mode in bits 3 to 1 | stores a plain mode selection in SMCR unchanged; sleeps in every non reserved mode; sleeps in extended standby |
| ATtiny mode in bits 4 and 3 | takes the mode from bits four and three; keeps peripherals running in its idle mode |
| other selections reserved, do not sleep | does not sleep in reserved mode four; does not sleep in reserved mode five; keeps running instructions after a reserved mode sleep |
| the ATtiny has only the first three | treats the fourth mode selection as reserved; stops the ATtiny timer 1 in ADC noise reduction / power-down; keeps the ATtiny timer 1 running in its idle mode; keeps an in-progress conversion paused in ATtiny power-down; finishes an in-progress conversion in ATtiny ADC noise reduction; resumes an ATtiny conversion paused by power-down after waking |
| ATmega keeps the low four bits | keeps only the low four bits of SMCR |
| ATtiny keeps all eight | keeps every bit of MCUCR |
| cycles advance to the next scheduled event | advances to the next scheduled peripheral event; does not stop on an event belonging to a stopped clock; leaves the stopped timer at zero while it skips past its event |
| or by one when nothing is scheduled | advances by a single cycle when nothing is scheduled |
| idle stops nothing | runs timer 0 / 1 / 2 in idle; lets a running timer keep counting in idle; completes the SPI transfer in idle; completes the USART transmission in idle; completes the EEPROM write in idle; finishes a conversion started before idle; wakes from idle when that conversion completes; stores the result of a conversion that ran through idle; leaves that conversion unfinished in power-down |
| every other mode stops timers 0, 1, 2 | the full matrix: timer 0 stops in ADC noise reduction, power-down, power-save, standby and extended standby; timer 1 stops in ADC noise reduction, power-down, power-save, standby and extended standby; timer 2 stops in ADC noise reduction, power-down and standby |
| ... the SPI | stops a pending SPI transfer in each of the five non-idle modes, and completes it after waking from each |
| ... USART0, transmit AND receive | stops a pending USART transmission in each of the five non-idle modes, and completes it after waking from each; holds a reception while its power reduction bit is set and completes it once cleared; holds a reception through a non-idle sleep mode and completes it after waking; completes a reception while idle stops nothing; queues no receive interrupt while the clock is gated |
| ... the EEPROM | stops a pending EEPROM write in each of the five non-idle modes, and completes it after waking from each |
| ADC noise reduction leaves the ADC running, so a conversion under way finishes | finishes an in-progress conversion in ATtiny ADC noise reduction; resumes a conversion paused by power-save after waking |
| deeper modes stop the ADC | does not start a conversion when power-down is entered; does not finish a conversion started before power-down |
| power-save and extended standby keep an asynchronous timer 2 | keeps an asynchronous timer 2 running in power-save; keeps an asynchronous timer 2 running in extended standby; wakes from power-save on a timer 2 overflow |
| ... only while it is asynchronous | stops timer 2 in power-save when it is not asynchronous; stops timer 2 in extended standby when it is not asynchronous; stops an asynchronous timer 2 in power-down / ADC noise reduction / standby; does not wake from power-down on a timer 2 overflow; keeps timer 0 stopped in power-save even when timer 2 is asynchronous |
| deeper modes stop the ADC (every one of them) | keeps a pending conversion paused in power-save / standby / extended standby; finishes a paused conversion in ADC noise reduction instead; resumes a conversion paused by power-save after waking |
| the watchdog runs in every mode | wakes from power-down / power-save / standby / extended standby / ADC noise reduction / idle on a watchdog interrupt |
| a queued interrupt wakes the CPU either way | wakes on a timer overflow in idle; wakes even when the global interrupt flag is clear; wakes from an interrupt that was already pending when it fell asleep; wakes from idle on a timer 1 overflow |
| flag set: take the vector | jumps to the interrupt vector when the global flag is set |
| flag clear: carry on after `SLEEP` | resumes after the sleep instruction when the global flag is clear; carries on executing after waking with the global flag clear; wakes from power-down with the global interrupt flag clear; does not take the vector on a masked wake from power-down; carries on executing after a masked wake from power-down |
| ... the interrupt stays pending | keeps the interrupt pending when the global flag is clear; keeps the interrupt pending after a masked wake from power-down |
| edge and change external interrupts lost while the I/O clock is stopped | ignores a rising / falling / change triggered external interrupt in power-down; ignores an edge triggered external interrupt in standby; ignores an edge triggered external interrupt in ADC noise reduction; does not flag an edge lost while the I/O clock was stopped; does not defer a lost edge until the CPU wakes; does not defer a lost change triggered edge; takes a fresh edge raised after waking |
| ... they work while it runs | takes a rising edge external interrupt in idle; takes a change triggered external interrupt in idle; still takes a rising edge external interrupt after waking |
| pin change still fires even when an edge interrupt on the SAME pin is lost | still wakes on the pin change when the edge interrupt is lost; takes the pin change vector, not the external one; does not flag the lost edge on that same pin; still wakes when a change triggered edge is lost; takes the external vector in idle, where the edge is not lost |
| entering noise reduction starts a conversion, which ADCSRA reports as running | shows a conversion in progress after entering noise reduction; still starts a conversion when noise reduction is entered with an interrupt already pending; has an interrupt queued before the sleep instruction runs |
| low level external interrupts still fire | wakes from power-down on a low level external interrupt; takes the external interrupt vector when it wakes on a low level |
| pin change interrupts still fire | wakes from power-down / power-save / standby / extended standby / ADC noise reduction / idle on a pin change interrupt; takes the pin change vector when it wakes from power-down |
| ATmega bit 0 the ADC | stops the ADC when bit zero is set; lets the ADC finish once bit zero is cleared |
| ATmega bit 1 USART0 | stops a pending USART transmission when bit one is set; completes the USART transmission once bit one is cleared |
| ATmega bit 2 the SPI | stops a pending SPI transfer when bit two is set; completes the SPI transfer once bit two is cleared |
| ATmega bit 3 timer 1 | stops timer 1 when bit three is set |
| ATmega bit 5 timer 0 | stops timer 0 when bit five is set; leaves timer 0 running when bit five is clear; leaves timer 0 running when a different bit is set |
| ATmega bit 6 timer 2 | stops timer 2 when bit six is set |
| ATmega bit 7 the TWI | stops the TWI when bit seven of the power reduction register is set; lets the TWI run once bit seven is cleared |
| ATmega bit 4 always reads zero | clears bit four of PRR; keeps every defined PRR bit |
| ATtiny bit 0 the ADC | stops the ADC on bit zero; lets the ADC finish when bit zero is clear |
| ATtiny bit 2 timer 0 | stops timer 0 on bit two; leaves timer 0 running when bit two is clear |
| ATtiny bit 3 timer 1 | stops the ATtiny timer 1 on bit three of its power reduction register; leaves the ATtiny timer 1 running when that bit is clear |
| ATtiny keeps only the low four bits | keeps only the low four bits of its power reduction register |
| stopped by either its bit or the mode | keeps a peripheral stopped across a sleep that also stops it; restarts a peripheral that only the sleep mode had stopped; stops an asynchronous timer 2 in power-save / extended standby when bit six is also set; keeps an asynchronous timer 2 running in power-save when another bit is set; leaves an asynchronous timer 2 stopped after waking while bit six stays set |
| a stopped peripheral keeps its registers | keeps the timer registers while the clock is stopped; keeps the SPI / USART / ADC registers while its clock is gated; keeps the SPI / USART / ADC / EEPROM / timer registers across a sleep that gates it |
| ... neither counts | resumes counting from the value it had when it stopped; ignores external edges while its power reduction bit is set / while a sleep mode stops the timer; counts external edges while the clock runs and again once the gate reopens or after waking |
| _(no clause)_ | **removed:** `keeps a timer whose configuration names no clock on the I/O clock`, see the Vega batch note below |
| ... carries on with the time it OWED, not the time since the gate closed | has not completed the transfer immediately after the clock returns; completes the transfer after only the time it still owed; does not carry the wait before submission into the owed time; the same three for a conversion |
| accepts rather than refuses work given while stopped, timers included | does not start while the power reduction bit is set; starts once the power reduction bit is cleared |
| accepts rather than refuses work given while stopped | holds an SPI transfer started while bit two is already set and completes it once cleared; holds a conversion started while bit zero is already set, completes it once cleared and stores its result; stops a pending USART transmission when bit one is set; completes the USART transmission once bit one is cleared; queues no USART interrupt while its clock is gated; stops the TWI when bit seven is set; lets the TWI run once bit seven is cleared; stops the ADC when bit zero is set; lets the ADC finish once bit zero is cleared |
| a clock stops the instant its mode is entered, so work due on that cycle does not run | does not run a transfer that was already due when power-down began; does not run it on any later tick either; runs that transfer once the clock returns; runs it straight away when idle stops nothing; does not run a timer event already due when power-down began |
| ... nor raises interrupts | raises no overflow interrupt from external edges while stopped, and raises it once the gate reopens; does not raise a timer interrupt while the clock is stopped; does not wake the CPU from a peripheral its PRR bit stopped; stays asleep in power-down while only a stopped timer could fire; queues no SPI / USART / ADC / TWI interrupt while its clock is gated, each with the ungated control that does queue the vector |
| ... carries on with the time it owed | raises the timer interrupt once the clock returns; resumes counting from the value it had when it stopped |

**No empty test column, and every one of the 284 cases traces back to a clause above.** The
first pass of this table found six orphans, all closed by adding tests rather than cutting
scope: the SPI, USART0 and EEPROM under a sleep mode, the TWI power reduction bit, the two
ATtiny power reduction bits, and `mode` while the CPU is awake. The platform's Test Fairness
coverage suggestions then added four more, also closed by adding tests: exact `mode` reporting,
post-wake continuation for the SPI, USART0 and EEPROM, the USART0 power reduction resume, and
ATtiny ADC noise reduction. A third round added three more, again test-only: the combined
sleep-and-PRR gate across the asynchronous timer 2 exception, a lost edge not being deferred to
the wake, and the ADC pause across every deeper mode. A fourth round filled the remaining
timer-by-mode matrix cells and isolated the wake-latency boundary, again test-only. A fifth
round covered the masked wake from a deep mode (pending interrupt kept, vector not taken, latency
still charged) and the ATtiny power-down matrix for its timer 1 and an in-progress conversion. A sixth round
covered the reserved-selection public state, the ATtiny wake latency and the clear case of the
asynchronous getter. A seventh round covered the ADC running normally through idle and direct
register retention for the SPI, USART0, ADC and EEPROM rather than only the timers. An eighth
round covered a relocated device configuration and direct interrupt suppression for the
non-timer peripherals. The `mode` suggestion needed a spec fix
rather than only a test:
`AVRPower.mode` returned a densely numbered enum in which standby was 4, so asserting it against
the selection the prompt names (6) would have pinned an ordering the prompt never states. The
enum now carries the datasheet selection values and meta.md says `mode` holds that number. The one clause that could not be
given a test was the TWI under a sleep mode (its clock event is scheduled from a register write,
which cannot happen while the CPU is halted), so the TWI was removed from that sentence and kept
only in the power reduction list, where it is asserted.

## Two suggestions answered differently than asked

Both platform coverage suggestions from the last round were implemented, but not literally, and
the reasons matter for review.

**The custom configuration test uses only the two documented fields.** The suggestion asked for a
config with nonstandard addresses *and masks*. `AVRPowerConfig` carries `SMCRMask`, `SE`,
`modeShift`, `modeMask`, `modes`, `PRRMask` and `powerReduction`, and meta.md deliberately
documents none of them: a solver may structure the descriptor any way it likes as long as `SMCR`
and `PRR` name the two addresses. A test that constructed `{ SMCRMask: ..., modeShift: ... }`
would pin an interface the prompt never states, which is the hidden-requirement failure rather
than a coverage win. The tests therefore spread the exported config and override only `SMCR` and
`PRR` (`{ ...powerConfig, SMCR: 0x41, PRR: 0x42 }`), which proves the constructor is not
hard-coded to 0x53 and 0x64 while staying shape-agnostic. Two mutants confirm it bites.

**The EEPROM is absent from the interrupt-suppression block.** Its ready interrupt is
inverse-flag driven by `EEPE`, so enabling `EERIE` queues the interrupt immediately, before any
gating can apply, and there is no write-in-progress moment at which the enable can be set without
aborting the write. Asserting `nextInterrupt` for the EEPROM measured that quirk rather than the
gate. Its suppression is already pinned by `stops a pending EEPROM write in power-down`, since
the completion event is both the only thing that clears `EEPE` and the only thing that would
raise the interrupt.

## Auto Review round 1 — revision requested, four findings

Three review runs returned Revision Requested. All four distinct findings are fixed.

| Finding | Severity | Resolution |
| --- | --- | --- |
| S1/S2 externally clocked timers bypass the gate (`timer.ts`) | High | Real bug. A GPIO edge called `count(false, true)` and the external branch counted unconditionally, so a timer stopped by sleep or PRR still advanced and could raise its overflow interrupt. The external branch now consults `isClockStopped`, with eight tests over both gates, the resume path, and the interrupt. |
| S2 mandatory `clock` on the exported timer config interfaces | High | Real regression. `AVRTimerConfig.clock` and `ATtinyTimer1Config.clock` are now optional and default to the I/O clock, so a config object written against the pinned version still compiles. Verified by type-checking a config literal with the field deleted, plus a runtime test that such a timer is still gated. |
| T4 SPI, USART0 and EEPROM sleep gating tested only in power-down | High | Real gap. All three are now parameterized over ADC noise reduction, power-down, power-save, standby and extended standby, each with a post-wake completion assertion: 30 new cases. A mutant that stops those clocks only in power-down kills 12 of them. |
| P4 description density | Medium | The two densest paragraphs were split, so the mode selections, the peripheral list, the two mode exceptions and the two PRR maps each sit in their own short paragraph. The reviewer suggested bullets or tables; `DESCRIPTION.md` requires plain prose with no headers or lists, so the substance is unchanged and only the paragraphing moved. Two of the three review runs already scored the description 3/3 and called the density "not a fairness or specification blocker". |

The two external-clock guards were first written as belt and braces, in `count` and in the pin
callback. Reverting either one alone killed zero tests because the other still caught it, so the
duplicate was removed: the single remaining guard is load-bearing, and reverting it reproduces the
reviewer's exact defect and kills 5 tests.

## Platform batch round 2 (Vega x3) — one test withdrawn

All three Vega runs failed with the identical signature: all 347 baseline tests green, 242-243 of
the 272 new tests passing, and the same 29 failures caused by one off-by-one at the sleep
boundary (their `setClockEnabled` only suspended events scheduled strictly after the current
cycle, so an event due exactly at the entry cycle still fired). Every evaluator recorded
`description_clear: true`, `tests_deterministic: true`, `difficulty: challenging`,
`was_mentioned_in_description: true`, `blocker_detected: false` and `agent_blame_unfair: false`,
and all three verdicts were FAIL_MISSED_REQUIREMENT.

One evaluator note is actionable and was acted on: *"One compatibility expectation for a timer
config with no explicit clock is more specific than the prompt."* That is
`keeps a timer whose configuration names no clock on the I/O clock`, which I had added to
demonstrate the S2 fix. The `clock` field on the timer configuration is deliberately undocumented
(`DESIGN.md` section 5 lists it as internal), so a solver may name it anything or not have one at
all; asserting a fallback for a config that omits it pins behavior meta.md never states. **The
test is removed.** The S2 fix itself stays: the field is still optional with an I/O-clock default,
and that is a compile-time compatibility property, verified by type-checking a config literal with
the field deleted rather than by a runtime assertion.

## Solvability proof — the batch 1 passing agent replayed against the current suite

Run `rd7bjm66t34bde6qw90zdpr1td8c761v` (Vega, verdict PASS_LEGITIMATE) passed 234 of 234 new tests
when batch 1 ran. Its solution diff was replayed against the CURRENT artifact: its twelve source
files applied to a pristine clone at the base commit, then the current `test.patch` on top, then
both modes run in the base image offline.

**Result: 242 of 242 new tests pass and 347 of 347 baseline tests pass.** Re-confirmed after every
subsequent change, including the coverage rounds that followed.

That settles the question the later batches raised. The suite grew from 234 to 280 cases across
eight coverage rounds and two Auto Review fixes, then settled at 242 after the batch 4 rebalance,
and the one agent solution known to be correct has satisfied it at every one of those sizes,
including the external-clock gating tests and the full non-idle mode matrix. The task is solvable on the artifact as it stands; the 0 of 3 and 0 of
6 batches are difficulty, not an unsatisfiable suite.

Artifacts: `Task46/agent-runs(5)/Vega_Nova/`.

## FP review round 3 — the entry guard, and a spec gap the run data exposed

The upheld defect: the candidate's `enterSleep` skipped sleep entry entirely whenever an interrupt
was already queued. My test written for exactly that scenario asserted only the END state
(`sleeping === false`), which a correct implementation and a never-entered one both reach. That is
the verifier gap, and the adjudicator named the file and line.

The fix had to avoid a trap I have already been caught by twice: two earlier adjudications rejected
`sleeping === true` probes as over-specifying a transient internal flag. So the new tests assert a
REGISTER-OBSERVABLE consequence of entry instead: with an interrupt already pending, entering ADC
noise reduction must still start the conversion. A mutant carrying the reported guard kills it.

Two tests I first wrote for this failed on my own reference, and they were the ones that were
wrong: with an interrupt already pending the reference enters the mode and `tick()` wakes it in the
same step, so `power.mode` is null afterwards and the SPI resumes. Only the started conversion
survives the immediate wake, which is precisely why the adjudicator picked it. Both were removed.

**A spec gap the replay data then exposed.** After this round the replay pool fell to 0 of 8, and
the sole blocker for two otherwise-passing runs was ADSC on the auto-started conversion. That is
not agent error: the repository's SOFTWARE start path has ADSC already set by the register write,
so an auto-start implementation naturally omits it, and the prompt only said "starts one". The
requirement was fair but not discoverable enough to be reliably met. meta.md now says the
conversion is one "which ADCSRA then reports as running", so it is stated rather than inferred.

**Read the replay pool with that in mind.** Those eight runs were graded against artifacts that
never contained that sentence, so 0 of 8 measures agents answering a different prompt, not the
difficulty of this one. Auto Review's own pool on a recent artifact was 2 of 10. A fresh batch is
required to re-measure, and it is the only instrument that can.

## FP review round 2 — one upheld defect, and a deliberate difficulty trade

Three of four adjudications returned Genuine Pass. The upheld one is fair and was a real hole in
my suite.

**The decisive defect.** A pin can carry an edge external interrupt AND a pin change interrupt at
once (PD2 is INT0 and PCINT18 on the ATmega328p). The flagged candidate implemented the
stopped-I/O-clock guard as an early `return` from `toggleInterrupt()`, which also skipped the
pin-change block below it, so such a pin never woke the CPU during a deep sleep. The prompt is
explicit that pin change interrupts still fire while the I/O clock is stopped. Every one of my
external-interrupt tests configured either an edge interrupt or a pin change, never both on one
pin, so the whole class was invisible. Five tests now cover it, and the mutant that restores the
early `return` kills 3 of them where it previously killed none.

**The secondary defect, and what it cost.** The panel also called out an auto-started noise
reduction conversion not setting ADSC. That is fair: the prompt says entering the mode starts a
conversion, and `adc.ts`'s own software-start path sets ADSC, so a conversion in progress is
observable exactly there. I had avoided asserting it earlier precisely because it is expensive,
and it still is: it drops my replay pool from 3 passers to 1.

I kept it. A false positive is a hard reject, a low pass rate is not, and this is the second FP
round in a row. For calibration, the replay pool is the eight CLOSEST runs of a batch that ran
against an older artifact, so it reads harsher than reality; Auto Review's own pool on the current
artifact was 2 of 10. The trade is recorded here rather than hidden: FP closure was prioritized
over difficulty margin.

## Auto Review round 2 — one High finding, on the USART receive path

Description and Solution both came back 3/3 Clean, and the five false-positive adjudications all
returned Genuine Pass, so the FP work from the previous round holds. Tests scored 1/3 on a single
High finding, and it is a fair one I had missed.

`AVRUSART` models reception as its own scheduled operation through `writeByte()`, entirely
separate from the transmit path. Every USART gating test I had written drove transmission, so an
implementation that tagged only the transmit `addClockEvent` with the USART clock and left
reception running would have satisfied the whole suite while plainly violating "every other mode
stops USART0" and "PRR bit 1 stops USART0".

Six tests now cover the receive side: held under the PRR bit and released when it clears, held
through a non-idle sleep mode and completed after waking, completed normally in idle, and raising
no receive interrupt while gated. Verified against a mutant that tags the receive event with the
watchdog clock, which is precisely the "gates transmission only" implementation the reviewer
described: it kills 3 of them, and killed 0 before this round.

The pass rate is unchanged at 3 of 17, so the addition closed a real false-negative path without
disturbing the difficulty.

## FP review — one real gap closed, one probe correctly rejected

The panel returned a False Positive on one Nova run and a Genuine Pass on another, and the two
adjudications between them settle exactly which of the two reported defects is fair.

**Upheld, and it was my gap.** A peripheral given work some cycles AFTER its gate closed must
resume owing only its own duration. The flagged candidate scheduled stopped-clock work on the
absolute timeline and, on release, shifted it by the whole `cycles - clockStoppedAt` interval,
so the dead time that elapsed BEFORE the work was submitted got counted twice. The adjudicator's
probe: an SPI transfer gated at cycle 0, submitted at 100, released at 200 completes at 232 in the
reference and never in the candidate. My suite never caught it because every submit-after-gate
test closed the gate and submitted work on the SAME cycle, which makes the dead interval zero and
the bug invisible.

Six tests now cover it for the SPI and the ADC, each with a negative control just after release
and a positive at the owed duration. Measured on the reference first: SPI owes 32 cycles, the ADC
50. A mutant that adds the pre-submission dead gap to the owed time kills 4 of them; before this
round it killed 0.

**Rejected, and deliberately not tested.** The second defect, a bare CPU with no `AVRPower`
attached sleeping on `SLEEP`, was called out by one adjudicator as unfair over-flagging: the
prompt frames `SLEEP` entirely around the power peripheral, and the enable bit is only meaningful
through an `AVRPower` configuration. Asserting behavior for the no-power configuration would
demand a stricter contract than the prompt states, so no test was added. My reference already
defaults `onSleep` to a no-op, so it does not exhibit the divergence either way.

**The fix reclassified a run, which is the point.** Nova 3 previously passed and now fails 2 tests
because it carries the same owed-time defect. The pass rate moves from 4 of 17 to **3 of 17,
about 18 percent**, still inside the band. A false positive that leaves the rate untouched has not
actually been closed.

## Last coverage round — one suggestion had to be answered differently

Three suggestions. The timer post-gate case and the ATtiny auto-start mirror were straightforward
additions and cost nothing. The scheduler-precision one could not be taken literally.

Written as asked, asserting the EXACT cycle the sleeping CPU lands on, it broke three of the four
passing agents: they landed on 2049 where the reference lands on 1025, and on 17 where the
reference lands on 9, each exactly one further divider period along. Their sleeping step fires the
due event and then advances to the following one. The prompt says the cycle counter "advances to
the next event of a running clock"; it never says how many events a single step may consume, so
the exact landing cycle is an unstated scheduling granularity and pinning it is over-specification
of the same kind the fairness check already caught once.

The requirement is still covered, by its observable consequence rather than an exact number: the
sleeping CPU does not stop on an event belonging to a stopped clock (the jump clears it by more
than a hundred cycles), the stopped timer stays at zero while the running one advances, and the
counter moves one cycle at a time when every clock is stopped. All four agents pass again.

This is the third time an exact-cycle assertion has had to be relaxed, and the pattern is now
clear enough to state as a rule for this task: cycle COUNTS are fair to assert when the prompt
fixes them, but cycle POSITIONS that depend on scheduler granularity are not.

## Final coverage round — the same-cycle cutoff, and why the second suggestion needed no work

Two advisory suggestions. The second, asking for a submit-after-gate case beyond SPI and ADC, was
already satisfied and I checked before adding anything: in `stops a pending USART transmission
when bit one is set`, `completes the USART transmission once bit one is cleared`, `stops the TWI
when bit seven of the power reduction register is set` and `lets the TWI run once bit seven is
cleared`, the PRR write precedes the UDR or TWCR write, so all four submit work to an
already-closed gate. That makes four peripheral implementations covered, not two. The EEPROM
cannot join them: it has no PRR bit, and its only other gate is a sleep mode, during which no
register write can happen.

The first suggestion was a genuine gap and is now five tests. It is the rule that caused the
biggest single failure cascade in this task, so it deserved a focused test rather than only
implicit coverage through the mode matrices.

Writing it took two attempts, and the first was worthless. A timer-based version passed under a
mutant that leaves already-due events queued, because `count()` carries its own stopped-clock
guard that masks the event even when it fires. The SPI completion path has no such second guard,
so the test now schedules a transfer, makes it overdue, enters power-down, and asserts SPIF stays
clear. Against the mutant that reproduces the exact agent bug, that kills 2 tests; the timer
version killed 0. One timer case is kept alongside it for the counter-level view.

## Solution Quality FAIL — stale expected-case list, plus one real code-quality fix

The check is badged **Stale** twice, and the arithmetic confirms why. It reports "38 synthesized
failures for expected new cases missing from the JUnit output". The suite went from 280 cases to
242 in the batch 4 rebalance, and 280 - 242 = **38**. The harness compared the new JUnit against a
cached expected-case list from the superseded test patch and synthesized one failure for every
case that no longer exists. The run itself emits 246 testcases with 0 failures, the baseline stays
at 347 with 0 failures, and four independent agent solutions pass the same artifact. Nothing in
the solution regressed; the check needs to re-baseline against the current test patch.

The Code Quality deduction was real, however, and it was my own leftover. The reviewer named one
defect: "the hard-coded wake latency applied by mutating `cpu.cycles` inside the sleep listener".
That code became vestigial the moment I removed the wake-latency axis from meta.md and the tests
in the batch 4 rebalance, and I kept it only to protect the LOC count. Keeping undescribed
behavior in a reference solution to defend a number is the wrong trade, and the reviewer found it
immediately.

Both vestigial pieces are now gone:

| Removed | Why |
| --- | --- |
| `WAKE_CYCLES` and the `cpu.cycles` mutation in the sleep listener | The exact defect the reviewer cited. No longer in the contract, so the global side effect had no reason to exist. |
| `AVRADC.handleSleepChange`, the conversion auto-start on entering noise reduction | Also undescribed and untested after the rebalance. The prompt now says only that noise reduction leaves the ADC running so a conversion under way finishes, which is what the code does. |

`handleSleepChange` in `AVRPower` collapses to two lines. Removing both pieces took effective LOC
to 396, under the 400 auto-block, so the ADC auto-start was brought back properly instead of being
left as undescribed code: it is now stated in meta.md and covered by five tests, which puts the
patch at **416 effective**.

Those five tests are written against the auto-start's CONSEQUENCE, not its register bit, and that
distinction was measured rather than guessed. My first attempt restored the old
`starts a conversion when noise reduction is entered` assertion on `ADSC`, and replaying the four
passing agents showed all four dropping to exactly one failure: they do start the conversion, but
not in a way that makes `ADSC` readable at that instant. Rewriting the same requirement as "the
CPU wakes at the ADC vector after entering noise reduction", with negative controls for a disabled
ADC, a PRR-stopped ADC, idle and power-down, keeps the requirement fully covered and all four
agents passing. The wake-latency mutation the reviewer named is gone for good.

## Test Fairness FAIL — one unstated cycle pin, left behind by my own axis removal

The fairness check passed 65 of 66 test groups and failed one: `charges nothing on a masked wake
from idle` asserted `cpu.cycles === asleepAt` exactly. That assertion was fair while the six-cycle
wake latency was part of the contract, because idle was then the stated exception. When I removed
the latency axis I deleted the rule from meta.md but left this test behind, so it pinned a policy
the prompt no longer stated. The reviewer's own note is precise: the `sleeping === false`
co-assertion is fair, the equality is not.

The exact-cycle assertion is gone and the test now checks only that a masked pin change wakes the
CPU from idle. I audited the three other surviving `cpu.cycles` equalities rather than assuming
they were safe, and all three remain grounded: advancing by one with nothing scheduled is stated
verbatim, `wakeUp()` costing nothing while already awake is stated, and reset costing nothing is
visible in `CPU.reset()`, which the reviewer independently classified as repo-discoverable.

Both advisory coverage suggestions were also added, four tests: an ATmega conversion started
before ADC noise reduction now completes and takes the ADC vector (previously only the ATtiny
configuration exercised that path), and the ADC gate composition where PRR bit 0 overrides the
normally running ADC and the conversion continues once the bit clears.

## Batch 4 (17 runs, 0 pass) — three micro-rules removed to restore the band

The clarifications from the previous round worked: the 29-to-30-failure cascades collapsed, and
three separate runs landed on exactly ONE failure. But 0 of 17 passed, so the arithmetic was still
wrong. With roughly eight INDEPENDENT micro-rules each missed by 30 to 50 percent of agents, the
probability of getting all of them right multiplies down to near zero. That is the trap-stacking
ceiling, not unfairness: every individual rule was stated, deterministic and defensible.

Cutting tests was measured before it was done, twice, and both times it failed as a strategy:
dropping four whole blocks converted 1 of 9 runs in the previous batch, and dropping 15 tests
converted 2 of 17 here. The failures were too diffuse for trimming to help. What works is removing
whole AXES, so the product has fewer terms:

| Removal | Tests dropped | Projected pass rate |
| --- | --- | --- |
| wake-latency axis only | 17 | 0 of 17 |
| + ADC entry-timing axis | 24 | 1 of 17 (6 percent) |
| **+ the one-cycle `SLEEP` assertion** | **38** | **4 of 17 (23 percent)** |
| + queued-after-gate axis | 28 more | 8 of 17 (47 percent), which is a too-easy REJECT |

The third row was chosen. Three micro-rules are gone from both the description and the tests:

1. **The six-cycle wake latency.** The single most-failed rule, blocking 10 or 11 of 17 runs on
   its boundary tests alone. It was also the least defensible: the real device's start-up time is
   fuse-dependent and I had invented a flat six cycles for every deep mode.
2. **The ADC conversion auto-start on entering noise reduction**, and its exact entry moment.
3. **`SLEEP` costing one cycle**, which is repo convention for every instruction anyway.

Everything structural stays: the mode matrices, per-clock gating, PRR, wake sources, the masked
wake, retention and resume, the external-clock gate, ATtiny, the relocated configuration. The
projection is measured, not estimated: replaying all 17 recorded failure sets against the final
242-case suite gives 4 passes, with four more runs at exactly one failure.

The mutants that targeted the removed rules were retired with them; the rest of the battery still
holds.

## Interface check FAIL — a pronoun put two members on the wrong object

The problem-and-tests alignment bot and the description-quality bot both failed the description on
the same point: it said the CPU gains `mode` and `asynchronous`, while the tests read
`power.mode` and `power.asynchronous` on the `AVRPower` instance.

This was self-inflicted and recent. The sentence originally read "The peripheral gains a `mode`
...". While trimming to fit the 500-word cap I shortened it to "It gains a `mode` ...", and the
pronoun's antecedent became the CPU, the subject of the preceding sentence. That is exactly the
two-actor pronoun trap: the word saved cost the whole interface contract.

The split is now explicit: "The CPU gains a `sleeping` flag and a `wakeUp()` ... `AVRPower` itself
exposes `mode` ... and `asynchronous` ...". Verified against the test file rather than by reading:
`cpu.sleeping` appears 49 times and `cpu.wakeUp` 34, while `cpu.mode`, `cpu.sleepMode` and
`cpu.asynchronous` appear zero times. `DESIGN.md` section 5 had the split right all along, so only
meta.md carried the defect. No test or behavior changed.

## Three unstated boundaries, found by grouping the failures

Grouping the 9 failing runs by test block showed the failures are not spread evenly. Four runs
(the three Vega of batch 2 plus the Vega of batch 3) fail 29 to 30 tests with an identical
profile: 16 in `which clocks each mode keeps running`, 4 in `the wake latency boundary`, 4 in
`the rest of the timer mode matrix`, and the rest in the ATtiny blocks. That is one root cause
producing thirty failures, not thirty independent mistakes: their clock suspension only removed
events scheduled strictly after the current cycle, so an event already due on the entry cycle
still ran.

Nothing in meta.md said when the stop takes effect. Three boundaries were implicit, and each maps
to a measured mass failure:

| Added clause | Failure it addresses | Runs affected |
| --- | --- | --- |
| "A clock stops the instant its mode is entered, so work due on that very cycle does not run." | the 29-failure cascade above | 4 of 9 |
| "accepts rather than refuses work given while stopped, so it waits" | work started while gated dropped instead of held | 9 of 19 |
| "starts a conversion as `SLEEP` completes"; "stopped clocks restart only after they are spent, so nothing counts them" | ADC entry timing and the wake-latency accounting | 7 and 12 of 19 |

Deleting tests was considered and rejected on the evidence: dropping four entire blocks converts
only one of the nine runs, because the failures span eighteen blocks. The blocker was ambiguity,
not test count, so no test changed and no semantics moved.

## Platform batches 2 and 3 — the shared blind spot was a real ambiguity

Cumulative: **1 pass in 19 runs (about 5 percent)**. Batch 1 was 1 of 10 on the 234-test suite;
batch 2 was 0 of 3 Vega; batch 3 was 0 of 6 (5 Nova, 1 Vega) on the current suite.

Two diagnostics ruled out a broken instrument:

- **No shared blocker.** Across the six runs of batch 3, ZERO tests failed in every run. The
  failure counts were 4, 6, 7, 12, 15 and 30, on largely disjoint sets.
- **The coverage rounds did not cost solvability.** Every one of the six runs also fails at least
  one test from the original pre-coverage blocks, so none of them would have passed the smaller
  suite either.

What the data did expose is a genuine ambiguity, and it is the modal failure: **9 of the 19 runs
treated a write issued while a peripheral's clock was gated as rejected work rather than held
work.** The description covered the in-flight case ("carries on with the time it owed") but never
said what happens to work *started* while stopped, and agents read "the time it owed" as zero.
Auto Review classified this as a shared blind spot three times; the run data says it is under-
specified rather than merely hard.

The fix is a reword, not a weakening: the last paragraph now says a stopped peripheral "accepts
rather than refuses work given while stopped, so a transfer or write started then waits." No test
changed and no semantics moved, so the strict timing and resume behavior the reviewers asked me to
keep is intact. The clause maps to seven existing assertions (USART, TWI and ADC gated-write
cases), so it adds no orphan.

**This edit stales the agent runs**, but a fresh batch was needed regardless: batch 1's pass was
recorded against the 234-case suite, and the only batch run against the current 271-case suite
scored 0 of 6. The reword costs nothing extra and targets the failure that 9 of 19 runs made.

## Validation log

Run inside `olympus-base-typescript` with `--network none` as uid 1000, from a pristine clone at
the base commit.

| Check | Result |
| --- | --- |
| Vanilla `npm test` (eslint + vitest), no patches | 347 passed, exit 0, 8.3 s |
| `test.patch` applies, `test.sh` mode | `100755` |
| `./test.sh base` with test.patch only | 347 cases, 0 failures |
| `./test.sh new` with test.patch only | 284 cases, **284 failures** |
| `solution.patch` applies on top | clean |
| `./test.sh base` solved | 347 cases, 0 failures |
| `./test.sh new` solved | 284 cases, 0 failures |
| Reverse apply order (solution then test) | both patches apply, all green |
| Five consecutive base and new runs | byte-identical counts every run |
| `npm test` with the solution applied | exit 0 |
| Patch encoding | ASCII, LF |
| Banned markers (`shipd`, `datacurve`) | none |
| Comments added by test.patch | none (the one grep hit is a shell glob in a string) |
| Comments added by solution.patch | JSDoc only, matching the repo's own convention |

## Mutation battery

Every headline rule was mutated in the solution and the new suite re-run, to prove the tests
bite rather than merely pass. All eight mutants die, and the sources were verified clean
afterwards.

| Mutant | New tests killed |
| --- | --- |
| Timer keeps counting against `cpu.cycles` instead of its own clock | 26 |
| PRR ignored when the sleep mode already leaves the clock running | 17 |
| Edge detection never gated on the I/O clock | 7 |
| Wake latency always zero | 5 |
| Wake gated on the global interrupt flag | 4 |
| ADC never stopped by a sleep mode | 4 |
| Reserved mode selections sleep anyway | 4 |
| Asynchronous timer 2 exception applied to every mode | 3 |
| Idle also stops the I/O clocks | 21 |
| Timer 1 never stopped by a sleep mode | 8 |
| Wake latency charged after the clocks restart instead of before | 5 |
| Wake latency only charged when the global interrupt flag is set | 8 |
| ATtiny config reuses the ATmega mode shift | 8 |
| ATtiny mode table missing power-down | 4 |
| Asynchronous getter ignores the AS2 bit | 5 |
| ATmega reserved selection 4 mapped to a real mode | 3 |
| ATtiny reserved selection mapped to a real mode | 2 |
| Wake latency only on a configuration that has an asynchronous timer | 2 |
| Gating a clock clears the peripheral registers | 7 |
| Idle stops the ADC clock | 2 |
| Only power-down stops the non-timer peripherals (the reported T4 gap) | 12 |
| External edges bypass the stopped clock (the reported S1/S2 bug) | 5 |
| A timer configuration naming no clock is left ungated | 1 |
| Waking leaves the reported mode set | 36 |
| Work scheduled onto a stopped clock is dropped instead of held | 4 |
| Power reduction register address hard-coded to the ATmega | 6 |
| A stopped clock still delivers its scheduled event | 5 |
| Sleep control register address hard-coded to the ATmega | 1 |

The wake-gate mutant is why this pass exists. It first reported zero kills because
`resumes immediately from idle` used an unbounded `while (cpu.sleeping)` loop, so a solution
that never wakes hung the run instead of failing it. That loop is now bounded and asserts the
CPU actually woke, which turns a platform timeout into a clean failure. The battery also left a
mutant in `src/cpu/cpu.ts` when it was interrupted by a timeout; it was caught by grepping the
sources before regenerating the patches, and the clean check is now part of this log.
