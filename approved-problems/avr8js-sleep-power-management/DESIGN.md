# DESIGN — avr8js-sleep-power-management

## 1. Title

Implement sleep modes and power management for the AVR CPU

## 2. Target

- Repo: [wokwi/avr8js](https://github.com/wokwi/avr8js) (canonical slug confirmed, no redirect)
- Stars 836, SPDX `MIT`, primary language TypeScript (100% of the language bytes), latest source commit 2026-02-14
- BASE_COMMIT `898f76c787762c8ee3ef7ca93c7b429b67a518d7` (= `main` HEAD at pick time)
- Tier: Olympus

## 3. Shape classification

O-Pipeline-hard. The CPU already owns two pipelines that every peripheral rides on: a sorted
clock-event queue and an interrupt queue. The feature threads a third axis through both of them —
a per-peripheral clock that can be stopped and restarted — and then adds the instruction-level
entry point (`SLEEP`) and the wake path. A peripheral that is not re-based onto its own clock
keeps counting through the stall, so the shared mechanism is what carries the difficulty rather
than any single routine.

## 4. Why this pick clears the gates

| Gate | Evidence |
| --- | --- |
| behavioral f2p gap | `src/cpu/instruction.ts:664` is literally `/* SLEEP, 1001 0101 1000 1000 */ /* not implemented */`. Base executes straight past a `SLEEP` instruction, and neither SMCR (0x53) nor PRR (0x64) exists anywhere in the source. Nothing composes the behaviour from existing primitives. |
| saturation | The AVR datasheet defines the mode table, but no reference implementation of *this* engine exists: the wake path has to be expressed in terms of avr8js's own clock-event list and `pendingInterrupts` array, which no other emulator shares. |
| uniform wrap | Four independent mechanisms: (a) the SLEEP/SMCR entry decision, (b) per-clock stop/restart with preserved remaining time, (c) the per-mode clock table plus the asynchronous GPIO exception, (d) the wake path with its latency and the `I`-flag split. Fixing the clock table does not make the timebase rebase correct, and vice versa. |
| LOC ceiling | Genuinely missing core. Measured build: see § 7. |
| cold not live | Two source commits in the trailing twelve months, both on 2026-02-14 and both about the ATtiny timer. Issue #139 ("Tracking issue: Sleep mode's not implemtned") has been open since 2023-05-09 with a bare link to the unimplemented line, zero comments and zero linked work. |
| reproduce on base | `SLEEP` is a no-op on base and `AVRPower` does not exist, so every new test fails there. |
| dedup | Nothing under `Aprroved/`, `problems/`, `rejected/`, `_shelved/` or any `TaskN/problems/` touches an emulator, a microcontroller, or power/clock gating. The nearest name collision is `avro-json-encoding`, an unrelated serialisation problem. |
| exclusivity | All fourteen branches enumerated with `compare/main...<branch>`: `accurate-cycles` (cpu.ts, 1 commit), `adc`, `as-interop`, `compare-match-output`, `external-interrupts`, `interrupt-refactor` (0 ahead), `simpler-api`, `JOSS`-style asset branches and six dependabot branches. None mentions sleep, SMCR, PRR or clock gating. Every PR in the repo's history is either a dependency bump or one of the merged peripheral features listed in § 4 notes. Issue search for `sleep`, `power-down`, `SMCR`, `PRR`, `power reduction`, `standby`, `idle`: the only hit is #139 above. |
| defined behavior | ATmega328P datasheet chapter 10 (Power Management and Sleep Modes) fixes every rule, and the maintainer's own tracking issue asks for it. Nothing is declined. |
| no flaky repo | Vanilla `npm test` (eslint + 347 vitest cases) is green offline in 8.3 s, byte-identical across five runs. No RNG, no clock, no network anywhere in the suite. |
| repo quota | 0 prior submissions on this repo. 1 of 6. |

## 5. Public API surface

Deliberately tiny, because the contract is behavioural. Everything else is observed through
registers, `cpu.cycles`, `cpu.pc` and the existing peripherals.

- `AVRPower` — new peripheral class, `new AVRPower(cpu)` or `new AVRPower(cpu, config)`
- `powerConfig` — ATmega328p, `SMCR` 0x53 and `PRR` 0x64
- `attinyPowerConfig` — ATtiny85, `SMCR` 0x35 (MCUCR) and `PRR` 0x20
- `cpu.sleeping: boolean` and `cpu.wakeUp()`
- `power.mode` — null while awake, otherwise the mode selection value the prompt enumerates
- `power.asynchronous` — bit 5 of ASSR at 0xb6

`AVRTimerConfig.clock` and `ATtinyTimer1Config.clock` are OPTIONAL and default to the I/O clock.
Auto Review flagged the first cut, which made them required, as a compile-time regression for
downstream custom device configurations, since both interfaces are publicly exported.

`mode` returns the selection value, not a densely numbered enum. The first cut returned a dense
enum in which standby was 4, so an exact assertion against the selection the prompt names (6)
would have pinned an ordering the prompt never states; `AVRSleepMode` now carries the datasheet
values.

Internal (not part of the stated contract, so a solver may pick another structure):
`AVRPeripheralClock`, `cpu.clockCycles()`, `cpu.setClockStopped()`, `cpu.sleepListeners`,
`cpu.onSleep`, the third argument of `cpu.addClockEvent()`, and every `AVRPowerConfig` field
beyond `SMCR` and `PRR`.

## 6. Canonical output form

Everything is an exact integer. `cpu.cycles` after a wake is a fixed number, `cpu.pc` is a vector
address or the instruction after `SLEEP`, `TCNT` values are exact counter states, and register
reads are exact bytes. No floating point anywhere in the feature.

## 7. File footprint

Measured with `.claude/hooks/effective_loc_check.py` on the final `solution.patch`.

| File | Status | raw | human-effective |
| --- | --- | --- | --- |
| `src/peripherals/power.ts` | new | 206 | 149 |
| `src/cpu/cpu.ts` | modified | 181 | 137 |
| `src/peripherals/adc.ts` | modified | 37 | 29 |
| `src/peripherals/timer.ts` | modified | 26 | 20 |
| `src/peripherals/twi.ts` | modified | 24 | 21 |
| `src/peripherals/timer-attiny.ts` | modified | 22 | 16 |
| `src/peripherals/usart.ts` | modified | 17 | 13 |
| `src/peripherals/eeprom.ts` | modified | 15 | 11 |
| `src/peripherals/watchdog.ts` | modified | 11 | 9 |
| `src/peripherals/gpio.ts` | modified | 7 | 5 |
| `src/peripherals/spi.ts` | modified | 6 | 5 |
| `src/cpu/instruction.ts` | modified | 6 | 4 |
| `src/index.ts` | modified | 4 | 4 |
| **total** | 13 files | **551** | **416** |

## 8. Solution outline

1. `CPU` gains a per-peripheral clock identity on every clock event. `addClockEvent` takes an
   optional clock; `setClockStopped` lifts every event of that clock out of the sorted queue and
   remembers the cycles it still owed, and restores them on restart. `clockCycles(clock)` returns a
   timebase that freezes while the clock is stopped, which is what the timers count on.
2. `SLEEP` calls `cpu.onSleep()`. `AVRPower` installs that hook, reads SMCR, ignores the request
   when `SE` is clear or the mode is reserved, and otherwise calls `cpu.enterSleep(mode)`.
3. `avrInstruction` short-circuits while `cpu.sleeping`: no opcode runs, and the cycle counter
   jumps to the next event of a clock that is still running.
4. `cpu.tick()` wakes the CPU as soon as any interrupt is queued, whether or not `I` is set.
5. `AVRPower` listens for both transitions and recomputes, for every peripheral clock, whether the
   sleep mode or the PRR bit stops it.
6. `AVRIOPort` only reports edge and change external interrupts while the I/O clock runs; low level
   and pin change stay asynchronous.
8. The timer's external-clock branch consults `isClockStopped`, so a T0 or T1 pin edge cannot
   advance a timer that sleep or PRR has stopped, nor raise its overflow interrupt.

## 9. Test outline

One new file, `src/peripherals/sleep_<hash>.spec.ts`, built from the repo's own `asmProgram` /
`TestProgramRunner` helpers. Blocks: SLEEP entry, per-mode wake tables, wake latency and the `I`
flag, PRR gating and resumption, register masking, reset. The new symbols are resolved lazily out
of the package index so that every case fails individually on base rather than collapsing the file.

## 10. Predicted trap matrix

| Trap | Why it is missed | Interacts with |
| --- | --- | --- |
| Stopped clock must freeze the peripheral's timebase, not merely skip events | The obvious fix suspends the queue entry; the timer then computes a huge delta from `cpu.cycles` on resume and jumps forward | every PRR and deep-sleep test |
| Wake happens even when `I` is clear | `tick()` only ever dispatches interrupts when `interruptsEnabled` | the ISR-vs-resume assertions |
| Edge-triggered external interrupts stop, low level and pin change do not | Wants one uniform "interrupts wake the CPU" rule | power-down wake sources |
| Reserved modes 4 and 5 must not sleep | The mode field looks like a plain 0..7 index | SMCR handling |
| Timer 2 keeps its clock in power-save and extended standby | Wants power-save to equal power-down | mode table |

## 11. Tier + category

Olympus. Long-horizon: 13 files, well past the two-file floor; the clock rebase must land before
any wake assertion can pass, so the work is genuinely sequential.

## 11b. Trap proof

Mutation battery over twenty-six headline rules, run against the new suite, including the two
defects Auto Review reported (table in feedback.md). No mutant survives. One further mutant (recording the mode before the reserved
check) was discarded as equivalent: it also yields null for a reserved selection.

## 11c. Difficulty rebalance after batch 4

Four batches (36 runs) produced one pass. The failure distribution showed roughly eight
independent micro-rules rather than a few compounding traps, which multiplies to a near-zero pass
probability. Three axes were removed (six-cycle wake latency, ADC auto-start on entry, one-cycle
`SLEEP`), chosen by measuring the projected pass rate of each candidate removal against the 17
recorded failure sets: 0, then 6, then 23 percent, with a fourth removal overshooting to 47
percent and a too-easy reject. The clock-gating architecture that carries the feature is untouched.

## 12. Quality gates

- [x] `human-effective` 416: clears the 250 sprint floor and the 400 auto-block, under the older
      450 target (see feedback.md § Deviations)
- [x] every new test fails on base: 284 of 284
- [x] base suite green with the solution applied, both apply orders: 347 cases, 0 failures
- [x] five identical runs of base and new
- [x] meta.md clause table with no empty test column; six orphans plus eighteen platform coverage suggestions closed with tests
