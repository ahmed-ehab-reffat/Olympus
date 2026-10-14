# DESIGN.md - pyocd-dwt-watchpoint-planner

Repo: pyocd/pyOCD (canonical slug confirmed via `gh api`, Apache-2.0, 1467 stars, Python)
Base: 3078bf177cb4d8afc78d4300a459f3c38c5ef238 (develop HEAD, 2026-09-24)
Hunt log: Instructions/repo-hunt-logs/REPO-HUNT-2026-09-29-C.md (Fallback 1)
Sibling: approved-problems/pyocd-sequence-expression-kernel (debug-sequence engine; this pick
touches none of its files).

## Phase 1 - Repo understanding

Architecture. pyOCD is a Python debugger for Arm Cortex-M. A `Session` owns a `Board` whose
`SoCTarget` holds `CoreTarget`s; for Cortex-M the core is `coresight/cortex_m.py:CortexM`
(`CortexM_v8M` for v8-M), built during CoreSight discovery, which also attaches child components
(`FPB`, `DWT`/`DWTv2`) through `CortexM.add_child`. Every register access goes through the
component's MEM-AP (`ap.read_memory` / `write_memory`, optional deferred `now=False` reads).
Front ends sit on top: the GDB remote server (`gdbserver/gdbserver.py` packet handlers +
`gdbserver/context_facade.py` GDB-specific encodings of a `DebugContext`), the commander
(`commands/commands.py` command classes executed by `commands/execution_context.py`) and the
Python API (`core/target.py`, `core/soc_target.py`).

Five subsystems: (1) probe/DAP/AP transport (`probe/`, `coresight/ap.py`, `dap.py`);
(2) CoreSight discovery + components (`coresight/discovery.py`, `rom_table.py`, `fpb.py`, `dwt.py`);
(3) core control (`coresight/cortex_m.py` run/halt/step/reset, DFSR decoding, register access);
(4) debug services (`debug/` breakpoints manager, contexts, caches, sequences, SVD, ELF);
(5) front ends (`gdbserver/`, `commands/`, `tools/`, `subcommands/`).

High-entanglement zones: (a) run-control in `cortex_m.py` (resume/step/halt/reset all touch DFSR,
DHCSR, run tokens, notifications and the breakpoint manager); (b) the GDB stop reply path
(`gdbserver.py` resume loop + `?` handler -> `context_facade.get_t_response` -> core halt state);
(c) the watchpoint API chain `Target/SoCTarget/CortexM.set_watchpoint` -> `DWT` -> commander
`watch/rmwatch/lswatch` which reads DWT internals (`dwt.get_watchpoints()`, `WATCH_TYPE_TO_FUNCT`).

Tests: pytest under `test/unit/` (1100 pass, 41 skip, ~4 s in the container, no hardware). Test
template: `test/unit/test_gdbserver.py` (plain pytest classes, no comments), `mockcore.py`
(hand-written fake core). There is NO unit coverage of DWT, watchpoints or stop replies.

## Phase 2 - Existing-PR / publicly-solved check (run 2026-09-29)

- `gh pr list -R pyocd/pyOCD --state all --search` for: watchpoint, DWT, comparator, rwatch,
  awatch, "stop reply", "stop reason", MATCHED, "watch range", "hardware watchpoint",
  "data watchpoint", DWTv2, "address range", mask. Hits: historic merged #81 (2014, original
  data breakpoints), #748 (2019 DWTv2), #1377 (2022 rmwatch args); open #430 (vector-catch thread
  in stop reply, rtos files), #453 (core thread provider), #2024 (RISC-V; context_facade diff only
  swaps the register list for RISC-V, its trigger module sets single triggers, no range chaining,
  no hit attribution, no `watch:` field; diff read). None implements planning or attribution.
- Issues: watchpoint/DWT searches are log-line noise; #80 (2014) is the original request, closed
  by #81. No decline, no "implemented" closure, no roadmap row.
- Tree + side branches (cortex-a, feature/debug_sequences, feature/freertos_10): no MATCHED use,
  no rwatch/awatch. dwt.py last touched 2022-04-28.
- Sibling ecosystem (noted risk, not a hit on the core): OpenOCD `cortex_m_hit_watchpoint` and
  Black Magic Probe `cortexm_check_watch` read MATCHED for SINGLE power-of-two comparators; neither
  plans arbitrary ranges over several comparators, links v8-M pairs, or keeps the answer across a
  re-query. GDB's aarch64/x86 native code splits unaligned ranges for their own debug registers.
  The split kernel is textbook (L58, counted as LOC, not band).

## Phase 3 - Candidates

| Candidate | One-line behavior | Verdict |
|---|---|---|
| A. DWT range planner + hit attribution (this) | any-length watch planned over comparators, all-or-nothing, request identity through remove/list/stop reply, MATCHED lifecycle | PICK |
| B. Planner only | arbitrary ranges on DWT | dead: kernel-only, textbook split, ~110 eff |
| C. Stop reply `watch:` only | read MATCHED, add field | dead: ~40 eff, OpenOCD/BMP shape |
| D. FPB range breakpoints | FPB has no ranges on v7-M | dead: hardware cannot |
| E. Data-value watch (DATAVADDR) | v7-M value matching | dead: spec sheet, no integration |

Step A (TOO-EASY guard) on A: (1) not one rule at many sites: planner, allocation transaction,
request/comparator identity, halt-answer lifecycle are separate mechanisms; (2) spans DWT, core
run-control, GDB facade and commander; (3) every rule is stated, walls are code-side; (4) MEDIUM:
Arm DWT and GDB RSP are public, so meta states the three register behaviours (MASK readback,
MATCHED clear-on-read, sticky DWTTRAP) and the v2 pair rule; (5) survives spelling out: the
lifecycle (drain on EVERY run path, cache per halt) and identity walls remain after statement.
Missing-arm check: new content (an allocator + a per-halt attribution state), not a new case.

Step B arsenal: lead S4 machinery-riding (the halt answer must ride every run path the core has:
resume, step; the MATCHED flags are a read-destructive channel), S2 composition (pair rule x
first-set tiebreak x pair flag position), A6/F-39 (base assign-before-validate leaves phantom
slots; base `remove_watchpoint` matches per comparator).

## 1. Title

Add range watchpoints and hit reporting to the Cortex-M DWT

Verb Add, names the subsystem (Cortex-M DWT). 9 words. Category feature-request.

## 2. Shape

- O-Pipeline-hard (new machinery cascading through existing stages: DWT programming, core
  run-control, GDB stop reply, commander).
- Pass target 20-35% (ceiling 40%).
- Dominant verdict predicted: MISSED_REQUIREMENT surfacing as a missing/stale stop-reply field.

## 3. Public API surface (names tests call; all exist on base)

- `CortexM.set_watchpoint(addr, size, type) -> bool` (via `CortexM.add_child(DWT/DWTv2)`)
- `CortexM.remove_watchpoint(addr, size=None, type=None)`
- `CortexM.resume()`, `CortexM.step()`
- `DWT(ap, None, 0xE0001000)`, `DWTv2(ap, None, 0xE0001000)` constructors (base signature)
- `GDBDebugContextFacade(DebugContext(core)).get_t_response()` -> bytes
- commander: `watch ADDR [r|w|rw] [SIZE]`, `rmwatch`, `lswatch` via `CommandExecutionContext`
- `Target.WatchpointType.{READ,WRITE,READ_WRITE}`

No new public name is imported by tests (L72 inverted): a solution naming its helpers
differently still runs. Internal names (reference only): `WatchpointRequest`, `DWT._plan`,
`DWT.clear_hits()`, `DWT.get_hit()`, `CortexM.get_watchpoint_hit()`.

## 4. Canonical output form

- Watched set: exactly the bytes addr .. addr+size-1 for the access type; nothing outside.
- v1 plan: fewest aligned power-of-two blocks, each no larger than 2**max_mask (the minimal
  aligned tiling is unique; tests observe coverage, not comparator numbers).
- v2 plan: one comparator when size in {1,2,4} and addr aligned to size; else linked pair on
  even n / n+1 with inclusive last address.
- Stop reply field: `watch` (write) / `rwatch` (read) / `awatch` (access) `:<hex addr>;`, where
  addr is the address the watchpoint was set at; tests parse the hex and ignore field order.
- Several matched: the watchpoint set earliest.
- lswatch: one line per watchpoint, set order, base format `N: 0x%08x, %d bytes, <r|w|rw>`.
- Failure: `set_watchpoint` returns False; unit unchanged.

## 5. Blind-spot pre-empts

rule-resolution (which watchpoint when several matched: first set); iteration/lifecycle
("asking again while halted gives the same answer"; "only watchpoints that matched during the run
that ended in this halt"); parallel-API (every run path: resume and step both end a run).

## 6. Description draft

See meta.md (written at slice time). ~420 words.

## 7. File footprint

| Action | Path | Raw | Eff (est) | Reason |
|---|---|---|---|---|
| MODIFY | pyocd/coresight/dwt.py | +230 | ~150 | request model, v1/v2 planners, mask probe, all-or-nothing, remove/list, hit capture + drain |
| MODIFY | pyocd/coresight/cortex_m.py | +30 | ~20 | per-halt answer keyed by run token, drain on resume/step |
| MODIFY | pyocd/gdbserver/context_facade.py | +20 | ~14 | stop reply field |
| MODIFY | pyocd/commands/commands.py | +15 | ~10 | any length in watch/rmwatch, lswatch by request |
TOTAL slice measured 152 human-eff (hook, 5 files incl. core/target.py); FINISH target >= 250 across 4 files (F-10 cells, v6-M/v8-M PMU DFSR
variants, commander parity, find_watchpoint, remove-all on disconnect).

## 8. Solution outline

- `WatchpointRequest(addr, size, type, comparators)`.
- `DWT.init()`: enumerate comparators, disable all, probe max mask on comparator 0 (write 31,
  read back, restore 0).
- `DWT._plan(addr, size, free)` -> list of (comparator, COMP, MASK, FUNCTION) or None
  (v1 greedy aligned split; v2 single or even/odd pair).
- `DWT.set_watchpoint`: validate, dedupe, plan against free comparators, program all or nothing.
- `DWT.remove_watchpoint(addr, size, type)`: remove every matching REQUEST, disable all its
  comparators.
- `DWT.clear_hits()`: read FUNCTION of every comparator (drains MATCHED), called on resume/step.
- `DWT.get_hit()`: read FUNCTION of used comparators once, earliest-set request with a flag.
- `CortexM.get_watchpoint_hit()`: when DFSR.DWTTRAP set, capture `dwt.get_hit()` once per run
  token, return cached value on later calls.
- facade `get_t_response`: append `<kind>:<addr>;` when a hit is returned.

## 9. Test outline

`test/unit/test_dwt_watchpoints_26e946.py`: a fake MEM-AP that models the SCS debug registers
(DHCSR, DFSR sticky W1C, DCRSR/DCRDR, DEMCR) and a DWT whose comparators EVALUATE accesses per
the Arm semantics (v1 masked compare, v2 DATAVSIZE and linked pairs, MATCHED set on match and
cleared on read, MASK clamped to the unit's max). Tests drive accesses (`fake.access(addr, 'r')`)
and assert which bytes halt the core, so no comparator numbering is pinned.
Buckets: coverage sweeps (v1 aligned/unaligned/odd length/max-mask split, v2 single/pair),
all-or-nothing (no room, pair parity), duplicate, removal by request, lswatch, stop reply kind
and address, re-query, drain on resume, earliest-set tiebreak, pair flag on limit comparator.

## 10. Forced shapes

- The fake AP must satisfy `ap.read_memory(addr, transfer_size, now)` (callable when now=False)
  and `write_memory`, `read32`, `write32`; CortexM step/resume/register reads use deferred reads.
- CortexM built without `init()`; test adds register groups with the public
  `core_registers.add_group(...)` like MockCore.

## 11. Trap matrix

| # | Trap | F-id | Class | Axis | Interdep. | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | answer computed lazily from MATCHED; re-query loses it | F-15/F-9 family | S4 | read-destructive channel lifetime | #2 (same cache) | stop reply is the obvious place to read flags | "Asking again while the core stays halted gives the same answer" | stop_reply_repeated_query |
| 2 | stale flags from an unqueried halt attributed to the next | F-15 (arming vs firing) | S4 | run-path coverage | #1, #5 | caches invalidated on resume but flags never drained; step path forgotten | "names only a watchpoint that matched during the run that ended in this halt" | resume_without_query_then_other_hit, step variant |
| 3 | request vs comparator identity (report block address, remove one block) | F-13 | A3 | identity | #4 | comparator objects already carry addr/size | "followed by the address the watchpoint was set at" | multi_block_hit_reports_request_address |
| 4 | assign-before-validate phantom slots / partial programming | F-39 | A6 | allocation transaction | #3 | base loop assigns then validates | "either gets every comparator it needs or none ... leaves the unit exactly as it was" | no_room_leaves_unit_unchanged |
| 5 | pair MATCHED on limit comparator only | F-10 | S2 | pair flag position | #1 | agents read the base comparator | "may show on either comparator or both" | pair_hit_flagged_on_limit |
| 6 | lazy max-mask probe on an in-use comparator | F-39/S3 | S3 | preservation | #4 | probing where set_watchpoint programs | "never changes another watchpoint's comparators" | second_request_keeps_first_mask |

## 11b. Cross-product matrix

| | v1 | v2 |
|---|---|---|
| single comparator hit | test | test |
| multi-comparator / pair hit | test (middle block) | test (flag on limit) |
| re-query | test | FINISH |
| drain on resume | test | FINISH |
| drain on step | FINISH | FINISH |

## 11c. FINISH additions (2026-09-30)

| # | Trap / cell | F-id | Test |
|---|---|---|---|
| 7 | comparators with different MASK limits (probe each; widest free comparator gets the largest block) | F-39/F-10 | TestComparatorLimits (4) |
| 8 | v2 with no free even/odd pair -> single 1/2/4 pieces | F-10 (version x allocation) | TestV2Singles (4) |
| 9 | write failure partway -> written comparators disabled, exception re-raised | F-39 transaction | TestWriteFailure (2) |
| 10 | answer fixed at the halt across remove / comparator reuse | S4 | TestHaltAnswer remove/reuse cells |
| 11 | reset is a run path; PSoC6 overrides reset and bumps the token itself | F-9 / F-41 second path | reset + family reset cells |
| 12 | commander status / continue / step / lswatch / watch SYMBOL | S5 parity | TestCommanderReports |

Measured: 220 human-effective over 7 files, 49 tests, 22/22 mutants killed.

## 12. Tier: Olympus, feature-request.

## 13. Predicted pass: 25-40%. Traps 1/2 carry the band; 3-6 are cheap cells.

## 14. Quality gates

Phase 1 5/5; Phase 2 clean (commands above); closest approved: pyocd-sequence-expression-kernel
(Dockerfile/test.sh); no `##` in meta; canonical form above; one codebase-inferable item at most
(commander line format, which is base's own format); traps on distinct axes; F-10 matrix present.

Why not a duplicate: our pyocd-sequence-expression-kernel is the debug-sequence expression
engine; no approved/rejected/problems entry mentions watchpoints or DWT.
Predicted iteration cycles: 2.
