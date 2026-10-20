# Repo hunt 2026-10-16-D (hunter #71, CONSECUTIVE_MISSES=0)

**Result: CANDIDATE, wokwi/rp2040js, memory access faults (HardFault / lockup / MPU / DMA bus errors / GDB stub errors), written 237 human-effective.**

Scratch: `worktrees/_hunt/s_1016h71/` holds:
- the brief `AGENT_BRIEF_h71.md` (the h71 block on top of the h70 brief);
- the screener `mech_h71.sh` with outputs `mech_part_h71_0*.out`, plus the `_c_*` (12-month commits) and `_p_*` (PR scan) dumps;
- the topic sweeps `topic_raw_h71.tsv` / `topic_uniq_h71.tsv` and `topic2_raw_h71.tsv` / `topic2_uniq_h71.tsv`;
- dossiers `dossier_{rp2040js,opcua,python-snap7,go-feature-flag,open-oscar-server,leshan}_h71.md`;
- sketches `sketch_rp2040js_busfault_h71.patch` (237), `sketch_open-oscar-server_chatevil_h71.patch` (188), `sketch_leshan_regproc_h71.patch` (173), `sketch_python-snap7_protection_h71.patch` (87);
- the kept clone `rp2040js/` (reset to HEAD);
- backups `judged.bak_h71` and `sig_accounts.bak_h71`.

Disk `/` was at 8.0G free at the start and 7.7G at the end. No builds were run.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):**
  - LEDGER rows exclude only their own lane;
  - only repo-scope verdicts block a repo;
  - ~505 star margin;
  - the return bar is 220 written;
  - the Q3 waiver applies only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule, the AI-sweep, velocity and signature rules, and the 2026-10-13 tracker-named-lane rule.
- **Softening:** none (misses = 0).
- **Requirement 0 (platform picker):** OWED for wokwi/rp2040js.
- **Excluded lanes:** every CLAIMED / HANDOFF / SLICING / HUNTED row in `pipeline/LEDGER.md`, in particular redis-smq single active consumer (#70), pitaya session resume (#69), micasa, allsorts and Cwerg.
- **Cross-repo dead classes added to the brief:**
  - sleep/power modes in an MCU emulator (our accepted avr8js lane, same wokwi org);
  - GDB watchpoints (our accepted pyocd-dwt lane);
  - flag rebucketing and target specialization (our accepted featurevisor lanes).
- **Lane audits were run by six parallel agents.** The hunter screened the repos, ran the sweeps, re-measured the RANK 1 sketch and checked its base claims.

## Stage 0-bis: proven pool
- **No acceptance since #70.** REVERT-RECALIBRATION shows csbindgen and micasa (10-15) as the latest, and both were already re-audited by #65-#67. mirrorbits' second lanes were re-judged 10-15. qq is spent.
- **No pool lane verdict has expired.** lifelines expires on 10-19. pulldown-cmark is repo-dead.
- **neva:** park until 10-20, as before.
- **pyOCD** (pool, two accepted lanes): the gdbserver/DAP side was covered by h63 on 10-14 (TZ, breakpoints, SVD, TCP pipelining, DAP planning all dead). It was not re-opened.
- **The pool produced nothing.**

## Cached index: go-feature-flag re-audit (#70 hint)
- The #70 auditor died on an API session limit. Re-run, verdict **DEAD** (12 lanes):
  - exporter retry is the maintainer's open PR #6129;
  - the collector service (#3912) and central state (#2889) are maintainer-authored roadmap issues;
  - SSE replay sits under ChrisJr404 #5903 (in-lane signature);
  - flag prerequisites are PR #5583;
  - relay chaining and per-retriever fallback are cribbed by flagd;
  - the Python provider's stream refresh was removed in provider 1.0;
  - the flag CRUD API is #5671/#5809.
- **The two-process lens does not fit:** the in-repo providers are Python/Kotlin/Ruby/PHP/Swift, so no single Go test drives both sides.

## Fresh sweep 1 (of 2): niche two-process topics (#70 hint)
- **Topics (53):** debug-adapter-protocol, dap, gdb, gdbserver, gdb-stub, debugger, remote-debugging, scpi, instrument-control, lab-automation, laboratory-automation, pyvisa, test-equipment, oscilloscope, logic-analyzer, sigrok, daq, data-acquisition, co-simulation, fmi, fmu, hardware-in-the-loop, opc-ua, modbus, canbus, can-bus, j1939, uds, obd2, rosbridge, mavlink, ground-control-station, ascom, alpaca, indi, telescope, octoprint, cnc, grbl, plc, sdr, jtag, swd, openocd, bootloader, firmware-update, ota, serial-port, ground-station, verilator, qemu, language-server, profiler.
- **Funnel:** 111 rows at 500-8000 stars, permissive, in-scope language, pushed within 12 months; 95 after the repo-dead list.
- **Dropped by eye:** LLM/alpaca name collisions, apps, k8s/IoT platforms, firmware.
- **Hand-added** from the same domains (direct API lookups): pymodbus, pymeasure, FMPy, rp2040js, PyLabRobot, gopcua, tokio-modbus, puffin, tokio-console, mavlink-router, instro, plus eclipse-leshan from #70's never-judged cut.

| Repo | Screen reading |
|---|---|
| pymodbus-dev/pymodbus (Py 2782) | **repo-dead:** 5 distinct signature accounts (binggao1230, ChrisJr404, dylanpulver, wanjinhao1, youdie006) |
| pymeasure/pymeasure (Py 788) | **repo-dead:** 3 signature accounts (binggao1230, CAOShurong, dylanpulver); 100 open PRs |
| mavlink-router (C++ 622) | **repo-dead:** Req 7, Build and Test red on master; 1 commit in 12 months |
| CATIA-Systems/FMPy (Py 597) | clean (t-sommer solo, 38 commits), but Python 60 / C 18 / Rust 14 with prebuilt solver/FMU binaries, and tests need FMU assets. Not audited (Docker cost); no verdict |
| PyLabRobot (Py 573) | MaxFreedomPollard x2, 86 AI trailers, a v1 rewrite in flight ("v1 STAR heads", "AI Slop Cleanup") across the whole backend. Not audited; no verdict |
| nominal-io/instro (Py 722) | 149 AI trailers, claude-review workflow, MaxFreedomPollard x2. Not audited |
| EmbarkStudios/puffin (Rust 1750) | CI red on all 6 default-branch runs, 18 commits. Not audited |
| tokio-rs/console (Rust 4608) | 8 maintenance commits in 12 months beside 23 open PRs (dormancy magnet). Not audited |
| slowtec/tokio-modbus (Rust 567) | 13 commits; the 09-19-B note (open PRs cover core files) stands. Not audited |
| **wokwi/rp2040js (TS 531)** | urish solo (25/29), CI green, avionicharshit-byte x1 (PWM #159). **Audited** |
| **gopcua/opcua (Go 1070)** | cpruijsen x2 (session restore, DateTime). **Audited** |
| **gijzelaerr/python-snap7 (Py 857)** | Poseidonas x2, 34 AI trailers (maintainer's lean-s7 sweep). **Audited** |
| **eclipse-leshan/leshan (Java 694)** | sbernard31 solo, no signature accounts, tests on PR CI. **Audited** |

## Fresh sweep 2 (of 2): emulator / simulation topics
- **Topics (31):** cmsis-dap, rtt, semihosting, gameboy, game-boy, nes, chip-8, 6502, z80, risc-v, riscv, arm-emulator, cpu-emulator, c64, zx-spectrum, retrocomputing, emulation, discrete-event-simulation, digital-twin, logic-simulator, spice, circuit-simulation, network-simulator, traffic-simulation, sumo, robotics-simulation, gameboy-emulator, nes-emulator, x86-emulator, virtual-machine.
- **Funnel:** 66 rows after the dead list. Most are AI-VM sandboxes, single-process console emulators, GPU/robotics stacks, or already-judged rows:
  - rgbds: lane density, 10-05;
  - enigma-bbs: AI-authored, 10-05;
  - libriscv: spec-named, 09-10;
  - pathsim: 09-19;
  - trice: many logs.
- **One new two-process engine was screened:** **mk6i/open-oscar-server** (Go 1582). mk6i 193 of 209 commits, 0 AI trailers, no signature accounts, CI green. **Audited.**

## Audit results

| Repo | Verdict | Best lane / killing gates |
|---|---|---|
| **wokwi/rp2040js** | **VIABLE, RANK 1** | Memory access faults, **written 237**. Other lanes: core1 is PR #112, PIO clkdiv PR #117, DMA sniffer PR #91, SSI flash PR #156 (all exclusivity); timer pause #33 and UART pacing #115 are tracker-named; NVIC preemption already exists; snapshot/restore is absorbed (~120-160); GDB watchpoints self-collide with pyocd-dwt; sleep is the avr8js class |
| gopcua/opcua | **DEAD (repo)** | Signature accounts: cpruijsen x2, **freedom-winds burst** (#891-#893 on 2026-08-10, scattershot across libcoap/redis-rs/nghttp3/openmls/hyper), sankalpsthakur #902. Lanes were also dead: notification queues PR #916; Republish/TransferSubscriptions is maintainer issue #910; deadband/triggering/events/history are cribbed by awcullen/opcua; Method Call is draft #838's diff; node management fails Q3 |
| gijzelaerr/python-snap7 | DEAD | Server protection levels **written 87** (one `_process_request` chokepoint). The block directory is under the maintainer's October sweep (#903/#904/#941). Cyclic data is cribbed by the same author's s7commplus. Partner segmentation is a native-snap7 port. The maintainer's lean-s7 audit reports (a Lean 4 model with a differential harness) list the remaining gaps, so treat them as magnets |
| thomaspoignant/go-feature-flag | DEAD | See the cached-index section |
| mk6i/open-oscar-server | DEAD | Chat-room warnings **written 188** (F-39 deadlock on the 1-slot warning channel, F-9 twin ChatService for OSCAR/TOC, F-10 rate classes), with no authentic second lever (TOC1 doc: "chat evil is not turned on"). Other lanes: feedbag limits, ignore list, ChatNav and account cascade are <100 on paper; ARS #179/#65, filters #59, push #208 and warning rules #41 are tracker-named; chat history #77 was declined as inauthentic |
| eclipse-leshan/leshan | DEAD | Server-object connection resources **written 173**. The queue-mode request queue was removed in 1.0 (#633/#427, removal record). epmin/epmax #1026, offline notifications #596, observe restore #1216, transactional bootstrap #968 and multi-server #600 are tracker-named. Gateway is in flight on gateway_server2 (#1750). Bootstrap reconcile fails Q3 |

## RANK 1 dossier: wokwi/rp2040js, memory access faults across core, DMA and GDB stub

**Repo facts**
- **Repo:** MIT (LICENSE read, no vendored dirs), TypeScript 99%, ★531 (> 505 margin). Raspberry Pi RP2040 emulator: Cortex-M0+ core, peripherals, GDB remote stub. Used by Wokwi.
- **HEAD:** a304c7486f329dae64be5f65baf28795d62ceb95 (main, 2026-09-25, v1.4.0).
- **Activity:** 29 commits/12mo, urish 25 (solo). Last 90 days: clocks derived from the PLL/CLOCKS registers, PWM fix, DMA off-by-one. None touch fault handling. 0 AI trailers.
- **Requirement 7:** Test and Lint, Pico SDK and MicroPython workflows all green on main.
- **Signature accounts:** avionicharshit-byte x1 (#159 PWM), outside the lane: a note.
- **Open PRs:** 7 (#156 SSI flash, #155 GPIO pulls, #152 PIO FIFO join, #146 CLI, #129 UART events, #112 core1, #91 DMA sniffing). None carries fault, MPU or bus-error code (diffs grepped).
- **Submissions (ours):** 0. The same org's avr8js has our accepted sleep/power lane; this lane is a different capability class.

**Exclusivity and tracker**
- Issues and PRs (all states) were searched for HardFault, hard fault, fault, unaligned, bus error, lockup, invalid memory address, AHB_ERROR, READ_ERROR, undefined instruction, MPU, memory protection, privilege and unprivileged. None names the capability; the nearest hits are #88, #139 (an unaligned access crash trace), #8 and #44.
- **Seam visible to rivals:** a 2021 maintainer TODO "raise HardFault exception" in `onBreak` (rp2040.ts:196). It is not an issue or a roadmap item. Wokwi hooks BKPT through `onBreak`, so the contract must leave BKPT/UDF -> onBreak unchanged; the sketch does.
- No CHANGELOG; git log has no fault/MPU/lockup subjects (no removal record).
- **Sibling crib:** there is no other TS/JS RP2040 emulator. The rp2040py Python port has no MPU or HardFault code, and GitHub code search for RASR/HardFault in TS/JS finds only docs.

**Outsider summary (dedupe sentence):** "Make the rp2040js Cortex-M0+ take a HardFault (or lock up) on bus errors, unaligned accesses and MPU violations, set the DMA channel's bus-error flags instead of copying 0xFF, and have the GDB stub answer bad addresses and lockups with errors."
- **Outsider-nameable: MEDIUM** (ARMv6-M fault and MPU rules are architecture spec).
- No long-open issue asks for it, and it is not a port.
- **Mitigation:** phrase meta.md on the emulator's own model ("an access the emulator answers with its invalid-address warning"), and put the weight on the repo-internal walls (traps 1-4).

**Sketch:** `s_1016h71/sketch_rp2040js_busfault_h71.patch`
- 7 files, raw 296, **human-effective 237** (re-measured by the hunter), padding-floor 85. The breadth is the MPU/DFSR/DEMCR register cases.
- Per file: cortex-m0-core.ts 99, ppb.ts 81, dma.ts 31, gdb-server.ts 19, rp2040.ts 4, gdb-connection.ts 2, simulator.ts 1.
- **Pieces:**
  - a `busError` signal at the two existing invalid-address warning sites;
  - the core's six bus wrappers become a checker (alignment, privilege + MPU, attributed bus error);
  - precise abort through a per-instruction context snapshot, so the stacked PC is the faulting instruction;
  - HardFault entry, or lockup at 0xFFFFFFFE when HardFault/NMI faults (HFNMIENA aware);
  - MPU_TYPE/CTRL/RNR/RBAR/RASR (8 regions, highest region wins, subregion disable, XN, PRIVDEFENA);
  - DEMCR.VC_HARDERR vector catch with DFSR.VCATCH;
  - one DMA copy routine with READ_ERROR/WRITE_ERROR/AHB_ERROR (no write after a read error, channel stops, IRQ raised, no chain);
  - GDB `m`/`M` answer `E01` on bad addresses, and a lockup halts the stub and the Simulator loop.
- **Levers:** without the vector-catch lever ~220; without the MPU ~150, so the MPU is load-bearing. The vector catch shares DFSR with our accepted pyocd-dwt (DWTTRAP). If the builder drops it to avoid overlap, the lane sits at ~220.
- **Unchecked:** syntax-checked per file with `node --experimental-strip-types --check`; NOT built, NOT run (no-build rule). The builder's spike must still clear 200, and instructions.spec.ts must stay green under the checker. The per-instruction context copy costs speed.

**Traps (base file:line)**
1. **One bus-error signal, three requesters (F-19, F-20).** The rp2040 read/write helpers are shared by the core wrappers (cortex-m0-core.ts:193-215), by DMA transfers that run inside `clock.tick` alarm callbacks between instructions (dma.ts:164-190), and by the GDB `m`/`M` loops (gdb-server.ts:232-256). A sticky flag or a throw placed in rp2040.ts leaks a spurious HardFault into the core, or crashes DMA/GDB.
2. **Precise abort in this interpreter (F-34, F-35).**
   - LDMIA/POP write registers inside their loop before a later word can fault (:819-828).
   - PUSH writes memory before it updates SP.
   - exceptionEntry moves SP before stacking (:250-271), and exceptionReturn switches mode/stack before unstacking (:290-330).
   - PC is already advanced at :599, but the stacked PC must be the faulting instruction.
3. **A second exception-entry path (F-41, F-67).** `setInterrupt` (:414-421) takes interrupts from inside peripheral callbacks while the core sits in WFI, outside `executeInstruction`. A lockup must also stop the Simulator loop (simulator.ts:18-28) or it spins.
4. **Sub-word bus paths (F-39).**
   - readUint8/16 fall back to readUint32, and writeUint8/16 do a read-modify-write through readUint32 + writeUint32 (rp2040.ts:306-410). One byte store to an unmapped address therefore fires both the read and the write warning: DMA must call it a WRITE error, and must not write after a READ error.
   - The flash fast paths and writeUint32 cover only the first 16 MB XIP alias, while readUint32 maps all four (rp2040.ts:306-322 vs :227).
5. **MPU on this core (F-52, F-87).**
   - The highest-numbered region wins, and a disabled subregion falls through to lower regions.
   - XN applies to fetches only, but fetches share the readUint16 path with loads.
   - Stacking uses the interrupted context's privilege.
   - HFNMIENA decides fault vs lockup inside HardFault/NMI.
- **Interlock:**
  - traps 1 and 3 meet in the same tick (a DMA bus error raised from a callback while the core is in WFI);
  - trap 2's restore must also restore the privilege that trap 5's check reads;
  - trap 5 decides HardFault vs lockup, which trap 3's loop must honour.

**Gate 1** (argued from code and the base lines quoted above; runtime probe OWED):
- An LDR from unmapped 0x30000000 only warns and returns 0xFFFFFFFF (rp2040.ts:253, read by the hunter).
- An unaligned LDR reaches `logger.error`, which throws a JS Error out of the emulator (rp2040.ts:217-220; #139 shows the trace).
- DMA from an unmapped source copies 0xFFFFFFFF and completes normally.
- GDB `m30000000,4` returns `ffffffff`.
- MPU_TYPE reads 0xFFFFFFFF and nothing is protected.
- The new behaviours are observable through registers, the stacked frame, the DMA CTRL flags and GDB replies.

**Stage 6 guard (run by the hunter on this RANK 1)**
- **Q1, shared kernel:** YES. The core's access checker feeds HardFault entry, lockup, the WFI interrupt path and stacking/unstacking. The rp2040 error signal feeds the core, the DMA flags and the GDB stub.
- **Q2, interdependent traps:** YES (interlock above).
- **Q3, standalone file:** NO. It edits seven existing files, and the core interpreter's instruction semantics must change. No waiver needed.
- **Q4, TOO-EASY Pre-Pick Guard:**
  1. Detection sits at one chokepoint (the bus wrappers), but the fix-insights are distinct: abort/restore, the second entry path, DMA attribution, MPU region semantics. This is not "pass X everywhere". Watch the go-mysql-server surface-diversity law in the builder's smoke run.
  2. Multi-subsystem: core, PPB, DMA, GDB stub, simulator loop.
  3. The walls survive being stated: the meta can promise "faults are precise" and "DMA errors stop the channel" without naming the LDMIA loop, WFI path or RMW byte path.
  4. RISK: the ARMv6-M fault/MPU rules are spec the models know; mitigated as above.
  5. There is no in-repo correct sibling to copy.
- **Verdict: PASS, with the Guard-4 risk recorded.**

**Tests and Docker**
- vitest (`npm test` = `vitest run`, src/**/*.spec.ts).
- One in-process spec file can drive all three sides:
  - the core through `RP2040` plus assembled opcodes (as instructions.spec.ts does);
  - DMA through register writes plus `clock.tick`;
  - GDB through `new GDBConnection(new GDBServer(target), cb)` and `feedData`.
- No network or services. Docker: `olympus-base-typescript`, `npm ci` offline-cacheable.
- **Reading surface:** ~3.5 KLOC of the 10.9 KLOC src (core 1.3K, rp2040 0.44K, dma 0.55K, ppb 0.25K, gdb 0.44K, simulator/clock, test drivers).
- **Nova sequence-length risk:** the surface is smaller than micasa/csbindgen. The builder should keep the GDB and DMA halves, so Nova must read the peripheral and stub code too.

## Fallbacks
- No new returnable fallback this hunt. The written near-misses are open-oscar chat warnings 188 and leshan connection resources 173 (both DEAD).
- Earlier fallbacks still on record:
  - anycable/anycable per-identifier session cap (written 230, #70);
  - tork concurrency groups 256, olric tombstones 229, saq job streams 226 (#69).

## Side findings
- **Signature accounts added to `sig_accounts.txt`:** freedom-winds (3-PR burst on gopcua 08-10, scattershot over libcoap/redis-rs/nghttp3/openmls/hyper) and sankalpsthakur (about 10 repos on 10-07, plus pymodbus, nanomq, node-red). Backup: `s_1016h71/sig_accounts.bak_h71`.
- **The scattershot wave has reached industrial-protocol libraries:** pymodbus has 5 accounts, gopcua 3+, pymeasure 3. Expect repo-level signature deaths across modbus/OPC UA/PLC/instrument libraries.
- **python-snap7's maintainer runs a formal model** (gijzelaerr/lean-s7, Lean 4 plus a native-snap7 differential harness) and files dated audit reports. Any gap it lists is public and pre-sized.
- **Protocol servers that chase authenticity** (open-oscar-server) decline "inauthentic" features, and their unshipped protocol corners are small dispatch arms. That lens does not reach 220.

## Submission counts (warning only)
rp2040js 0, gopcua 0, python-snap7 0, go-feature-flag 0, open-oscar-server 0, leshan 0, and 0 on every other screened repo.

## Verdict rows
- `judged.tsv`: 9 rows appended (backup `s_1016h71/judged.bak_h71`).
- **Repo-scope (4):** gopcua (signature accounts + burst), pymodbus (5 signature accounts), pymeasure (3 signature accounts), mavlink-router (Req 7).
- **Lane-scope (5):** rp2040js (candidate), python-snap7, go-feature-flag, open-oscar-server, leshan.
- **No verdict written** (screen notes only): FMPy, PyLabRobot, instro, puffin, tokio-console, tokio-modbus.
- `used_topics.txt`: 84 topics added (the file is now sorted).

## What the next hunt should change
1. **The emulator-with-a-stub lens produced the lane.** Cross-cutting fault/abort semantics in an interpreter (precise abort, a second exception-entry path, peripheral bus masters sharing the bus) gave walls that come from the repo's own loop structure. Try the same capability class in OTHER emulators with peripherals and a debugger stub: AVR/ESP32/STM32 simulators, wokwi's other cores, retro machines with DMA/blitters. Avoid our accepted sleep/power and watchpoint classes.
2. **Industrial-protocol client/server libraries are now signature-swept** (pymodbus, gopcua, pymeasure). Do not spend audits there without a screen first.
3. **FMPy is unaudited** (clean screen, Docker cost from its C/Rust binaries and FMU assets). It is the only co-simulation repo left in the band if a hunt wants one.
4. **Re-check neva after 2026-10-20,** and re-audit any proven repo on the day its in-flight lane is accepted.
