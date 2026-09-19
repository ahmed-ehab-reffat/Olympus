# DESIGN.md — cwerg-bcopy-bzero-lowering

Base: robertmuth/Cwerg @ 3bc94f7c1c26834f98c614aef51b5aa7370615d9 (2026-06-18). Clone: `worktrees/Cwerg`.
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-09.md § PASS 3`. Docker recipe verified:
`Instructions/repo-hunt-logs/artifacts/cwerg-build-VERIFIED.Dockerfile`.

## 0. Phase 1 — repo understanding (gate)

**Architecture (one paragraph).** Cwerg is a small compiler in two mirrored implementations, Python
(the spec/reference) and C++ (a port that must produce byte-identical output, enforced by the
suite's own `codegen_parity` targets). A textual IR (`IR/opcode_tab.py` defines ~170 opcodes with
operand kinds and type constraints; `BE/Base/ir.py` + `serialize.py` parse it into `Unit/Fun/Bbl/Ins`
with mutable, non-SSA registers) flows through target-independent passes in `BE/Base` (`cfg.py`,
`lowering.py`, `liveness.py`, `reg_alloc.py`, `optimize.py`, `sanity.py`) and then into one of three
backends `BE/CodeGen{A32,A64,X64}`, each with `legalize.py` (a `PhaseLegalization` that sequences the
Base lowerings with target kinds, then `optimize.FunCfgExit`, immediate rewriting and a
`sanity.FunCheck(check_cfg=True)`), a table-driven `isel_tab.py` (patterns -> CPU instructions; an
opcode with no pattern dies with `could not find pattern` / `could not match opcode`), `regs.py`
(calling convention + allocatable sets) and `codegen.py` (driver: `-mode normal|legalize|...|binary`,
ELF emission via `BE/Elf`). A frontend `FE/` compiles the Cwerg language to this IR; it is out of scope
(its C++ half needs GCC 13 `<format>`, absent from `olympus-base-cpp`).

**Five subsystems + boundaries.** (1) `IR/` opcode table + generated C++ enums — the language of
record; (2) `BE/Base` — parse/serialize, CFG, target-independent lowering, liveness/regalloc, optimize,
sanity; (3) `BE/CodeGen{A32,A64,X64}` — legalization sequencing, isel, regs, codegen driver; (4)
`BE/Cpu{A32,A64,X64}` + `BE/Elf` — instruction encoders and object emission; (5) `BE/StdLib` +
`BE/TestData` — the runtime and the golden-output test corpus, compiled by each backend and run under
`qemu-*`.

**Three high-entanglement zones.** (a) `BE/Base/lowering.py` <-> each `PhaseLegalization`: every
lowering is parameterised by target kinds (`base_kind`, `offset_kind`) and its position relative to
`canonicalize`, `FunCfgExit` (adds unconditional branches), `_FunRewriteOutOfBoundsImmediates` and the
CFG sanity check decides whether the next stage can consume its output. (b) The Python/C++ mirror:
`lowering.py` <-> `lowering.cc` + `legalize.py` <-> `legalize.cc` per target, with `codegen_parity`
diffing textual `-mode normal` output. (c) Operand kinds across stages: the parser infers the
narrowest constant kind (`OffsetConst`: `16` -> `U8`, `-8` -> `S8`), A32/A64 widen sub-32-bit regs in
legalization, X64 does not, and every isel pattern is keyed on exact kinds.

**Test framework.** Golden-output integration tests driven by make: `BE/CodeGen<T>/Makefile_py` and
`Makefile_cc` list `TESTS` (`.asm` programs under `BE/TestData`), compile each with the Python or C++
codegen (`codegen.py -mode binary <stdlib> <prog> <exe>`), run it under `qemu-armhf|aarch64|x86_64`, and
`diff` stdout against `<prog>.golden`. Plus per-target `isel_test`, `codegen_parity` (py vs cc textual
asm), `BE/Base` unit + regression tests, `BE/Cpu*` assembler tests, `BE/Elf` tests, and the FE
language tests. Formatting template for a new program: `BE/TestData/memaddr.64.asm` (`.mem` data,
`lea.mem`, `ld`/`st`, `print_ln`) and `int_op.asm` (loops with `ble`, `print_x_x_x_ln`).

**Baseline (3 fresh containers, identical):** BE py 94 targets pass, FE py 102 pass, BE cc through
`[OK C++ Elf]` pass incl. all `codegen_parity`; `ApiDemo`/`BindingsC` need an ARM cross-compiler and
`FE` C++ needs GCC 13 -> both scoped out of base mode with those reasons. Thread tests are already
commented out of every `TESTS` list upstream (#17).

## 1. Title
Add bcopy and bzero lowering to the Cwerg backends

## 2. Shape classification
- Shape: **O-Composite-add** (SHAPES.md § Pattern 12) — a new capability spanning the IR table, the
  target-independent lowering layer, three backends, and the mandatory C++ mirror. Confirmed outside
  compiler stacks by go-workflows (2/10); here it IS a compiler stack.
- Pass-rate target: 15-30% (design to the affordable middle: only Orion is unlocked; a ~10% design is
  indistinguishable from 0% in a 10-run batch).
- Best agent: Orion / Vega (long-horizon; the C++ port is mechanical but large). Nova would likely
  ship Python-only.
- Dominant verdict: MISSED_REQUIREMENT (the C++ half, the downward direction for register lengths) and
  INTEGRATION_ERROR (sanity assert / `could not find pattern` from placement or kind mismatch).
- Solver/our LOC ratio: ~1.3-2.0x (agents write two loops where one parameterised loop suffices).

## 3. Public API surface
There is no new host-language API. The surface is the IR:
- `bzero addr len` — writes `|len|` zero bytes at/below `addr` per the direction rule below.
- `bcopy dst src len` — copies `|len|` bytes from `src` to `dst` per the direction rule.
- `len` is a byte count: a constant or a register of any integer kind (`S8..S64`, `U8..U64` as the
  parser/target allows). `addr`/`dst`/`src` are address registers of the target's address kind
  (`A32` on a32, `A64` on a64/x64).
- Observable through: the program's stdout under qemu on all three targets, from BOTH the Python and
  the C++ codegen, and the textual `-mode normal` assembly which must be identical between the two.

## 4. Canonical output form
- Direction: length >= 0 handles byte 0 first, then byte 1, ... upward from the given addresses.
  length < 0 handles the byte just BELOW the given addresses first, then the next below, until |len|
  bytes are done. The sign is read from the VALUE, whether constant or register; an unsigned register
  is never negative.
- Overlap: the result is exactly what reading and writing one byte at a time in that order produces
  (so a forward copy over an overlapping higher destination smears; a downward copy is the memmove-safe
  direction for it).
- Zero length: nothing is read or written.
- Empty/none: n/a. Unicode: n/a. Alignment: none assumed; any address, any length.
- Both implementations emit the same textual assembly for the same program.

## 5. Blind-spot pre-empts (from the DESCRIPTION.md bank)
- Iteration/order: "as if each byte were read and written one at a time in that order" (order rule).
- Falsy-on-zero: "a zero length touches nothing".
- Parallel implementation: "the Python and the C++ backends emit identical assembly text for such a
  program, as the parity tests require of everything else" (dual-path parity).
- Pipeline placement: deliberately NOT stated (this is the single codebase-inferable requirement —
  see § 11 trap 3).

## 6. Description draft (meta.md body — plain prose, ~185 words)

Add support for the `bzero` and `bcopy` IR instructions to the Cwerg backends so that programs using them compile and run on a32, a64 and x64. The IR already defines both instructions and accepts them in a program, but every backend then fails to select an instruction for them.

`bzero` takes an address and a length and writes that many zero bytes; `bcopy` takes a destination address, a source address and a length and copies that many bytes. The length is a byte count and may be a constant or a register of any integer kind. A length of zero or more works upward from the given addresses, byte 0 first, then byte 1 and so on. A negative length works downward: the byte just below the given addresses is handled first, then the one below that, until the magnitude of the length is exhausted. The sign is read from the value, whether it is a constant or held in a register, and an unsigned register is never negative. The result is exactly what reading and writing one byte at a time in that order produces, so overlapping source and destination ranges end up as that order dictates, and a zero length touches nothing.

Both instructions work wherever they appear, in any function, however many times, and everything else in the program keeps behaving as before. The Python and the C++ backends must emit identical assembly text for a program that uses them, as the parity tests already require of every other instruction.

Category: feature-request (Add). Title verb: Add.

## 7. File footprint (sketched against the real tree)
| Action | Path | Current LOC | Raw delta | Meaningful (x0.8 py / x0.75 cc) | Reason |
|---|---|---|---|---|---|
| MODIFY | BE/Base/lowering.py | 711 | +150 | +120 | `FunEliminateBulkMem(fun, base_kind, offset_kind)`: normalise length kind, sign dispatch (static for consts, runtime for regs), build byte loop(s) with `cfg.BblSplitBeforeFixEdges` + new bbls + edges, both opcodes |
| MODIFY | BE/Base/lowering.cc | ~820 | +190 | +145 | mirror, identical instruction stream and scratch/bbl names |
| MODIFY | BE/Base/lowering.h | ~40 | +4 | +3 | declaration |
| MODIFY | BE/CodeGenA32/legalize.py | ~470 | +3 | +3 | call before `FunCfgExit` |
| MODIFY | BE/CodeGenA64/legalize.py | ~450 | +3 | +3 | same |
| MODIFY | BE/CodeGenX64/legalize.py | ~430 | +3 | +3 | same |
| MODIFY | BE/CodeGenA32/legalize.cc | ~330 | +3 | +3 | mirror |
| MODIFY | BE/CodeGenA64/legalize.cc | ~320 | +3 | +3 | mirror |
| MODIFY | BE/CodeGenX64/legalize.cc | ~300 | +3 | +3 | mirror |
| MODIFY | IR/opcode_tab.py | 1050 | +18/-12 | +7 | genus TBD -> BASE (the C++ generator skips non-BASE opcodes) + real docstrings |
| MODIFY | IR/opcode_gen.cc + .h | generated | +318 | 0 (generated) | regenerated through `IR/Makefile`; the C++ table is indexed by opcode number and now reaches 0xba |
| MODIFY | BE/CodeGenC/codegen.py | 526 | +14 | +11 | `Handle_BULK`: C byte loops for both directions, unsigned lengths get the upward loop only; dispatch entries |
TOTAL measured 2026-09-09 (hook, excluding the generated table): py 87 + cc 106 + C backend 11 + table 7 + wiring 7 = ~218 human-effective across 13 modified files (>= 2 files; clears 200 with a thin buffer — the C++ mirror is the size, the byte-loop kernel is compact by nature).
LOC discipline: the two hard files are sketched in real code below (§ 8); the C++ side is the size lever
and it is genuine (the repo mandates it), never padding. If the reference lands under 250 effective,
the honest scope lever is NOT the FE (unbuildable) — it is per-target width selection for constant
lengths, which is a HOW and would not be contract-stated; prefer to accept ~250-290.

## 8. Solution outline — helpers (1+ per contract sentence)
Python (`BE/Base/lowering.py`), mirrored in C++:
- `_LenToOffsetKind(len_op, offset_kind, fun, out) -> Reg|Const` <- "a constant or a register of any
  integer kind": a constant is re-typed to `offset_kind` (value preserved, sign preserved); a register
  of another kind gets a `conv` into a scratch of `offset_kind` (unsigned wide-to-signed is fine for
  the test magnitudes; the contract says unsigned is never negative).
- `_IsStaticallyNegative(len_op) -> bool` <- "the sign is read from the value" (constants).
- `_EmitByteLoop(fun, bbl, ins, dst, src|None, count, step, offset_kind, addr_kind)` <- "one byte at a
  time in that order": splits `bbl` before `ins` (cfg.BblSplitBeforeFixEdges), creates `loop` bbl:
  `ld b:U8 src 0` (bcopy only) / `st dst 0 b|0:U8`, `lea src src step`, `lea dst dst step`,
  `sub cnt cnt 1`, `bne cnt 0 loop`; guard bbl: `beq cnt 0 exit` <- "a zero length touches nothing".
  Downward variant pre-decrements (step -1, `ld b src -1`... i.e. `lea` first then access at 0).
- `_InsEliminateBulkMem(ins, bbl, fun, ...)` <- dispatch: const sign -> one loop; register -> runtime
  sign test `blt len 0 down` selecting the downward loop (count = 0 - len) or upward loop.
- `FunEliminateBulkMem(fun, base_kind, offset_kind) -> int` <- "wherever they appear, however many
  times": iterate over a COPY of `fun.bbls` and of each `bbl.inss` (the repo's own `FunEliminateCmp`
  idiom) so splitting does not skip the second instruction in a block.
- Wiring in each `PhaseLegalization` after `FunEliminateMemLoadStore` and before
  `canonicalize.FunCanonicalize` / `optimize.FunCfgExit` / immediate rewriting (so the new consts and
  branches are legalised and the CFG check sees complete edges) — this placement is the single
  codebase-inferable requirement.
No fixpoint loop (single pass). No recursion.

## 9. Test file outline
Path: `BE/TestData/bulkmem.32.asm` + `BE/TestData/bulkmem.64.asm` (+ `.golden` each), one program
per address width, run by the harness on every target and both implementations, plus parity.
Random-hex suffix in the file names to avoid predictability (`bulkmem_<hex>.32.asm`), no `shipd`/
`datacurve` markers anywhere.
- Block 1 — data: RO source patterns (`.mem` with `.data` bytes), RW scratch buffers, a `.stk` slot.
- Block 2 — helpers (in asm): `dump n addr` prints `n` bytes as hex via `print_x_ln`/`print_ln`.
- Block 3 — cases (each prints a line; the golden is generated by an independent Python byte model,
  never by the reference):
  bzero: const 16 / const 7 / const 0 / const -5 (bytes below) / reg U32 9 / reg S32 -6 / reg S32 0.
  bcopy: const forward disjoint / const odd length unaligned / const -N downward disjoint /
  overlapping forward higher dst (smear, upward rule) / overlapping with negative length (memmove
  result) / overlapping forward lower dst (memmove result upward) / reg positive / reg negative at
  runtime / reg zero / two ops in one bbl / op inside a counted loop / stack slot dest via `lea.stk` /
  RO global source into stack / pointer computed with `lea` offset.
- Block 4 — harness testcases (test.sh): per (impl x target) `bulkmem` run vs golden = 6 cases;
  parity py-vs-cc textual asm for the program on 3 targets = 3 cases; C backend direct + after
  `optimize.py` = 2 cases (the optimizer path is covered by the repo's own `.opt.exe` rule shape); C++ FE excluded; base mode =
  every existing make target as its own testcase.
Atoms -> tests: upward rule (const, reg), downward rule (const, reg), sign-from-value (reg negative),
unsigned-never-negative (U32 reg), byte-order/overlap (3 cells), zero (const, reg), "wherever" (2 in a
bbl, in a loop, stack, global, computed), "everything else keeps working" (base mode), parity (3).

## 10. Forced bounds / kwargs
None in host-language terms. IR-level: the length may arrive as `U8`/`S8`/`U32`/`S32`/`U64`/`S64`
(constant kinds from `OffsetConst`, register kinds as declared); the loop's counter/step/branch
operands must share ONE kind, and the pointer steps must be `lea` with a `TC.OFFSET` operand — on x64
the isel accepts small constant offsets but a `U8` register as a `lea` offset has no pattern.

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence (§6) | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | Register length negative at RUNTIME must go downward | F-10 (const/reg x up/down) | S2 / A8 polarity | direction source | #2, #6 | agents branch on `isinstance(len, Const) and value < 0` and emit one upward loop for registers; a negative register then counts down from 2^32 (hang) or copies the wrong bytes | "The sign is read from the value, whether it is a constant or held in a register" | `bcopy_reg_negative_runtime`, `bzero_reg_negative_runtime` |
| 2 | Overlap outcome fixed by byte order (no memmove auto-direction, no wide-unit copies over overlap) | S2 composition (candidate new pattern) | S2 + P2 over-eagerness | memory-order semantics | #1 | the helpful implementation picks the safe direction itself, or unrolls constant lengths with 4/8-byte loads | "exactly what reading and writing one byte at a time in that order produces" | `bcopy_overlap_forward_smears`, `bcopy_overlap_negative_moves`, odd-length unaligned cases |
| 3 | Placement inside `PhaseLegalization` (before `FunCfgExit`, before immediate rewriting, before the CFG sanity check) | F-6 ordering / S3 chokepoint | S3 | pipeline placement (the one codebase-inferable req.) | #4, #5 | a lowering appended at the end of the phase leaves new consts un-legalised (`could not find pattern` on an instruction the agent never wrote) or fails `sanity.FunCheckCFG` on edges | none (codebase-inferable) | every end-to-end case on a32 (immediates) and all targets (CFG) |
| 4 | Python/C++ identical assembly text | F-12-adjacent repo-test axis / A1 | A1 cross-section | dual implementation | #3 | agents ship Python only, or port with different scratch-reg names/bbl order; the C++ codegen then either crashes on the opcode or emits a different (still correct) stream | "The Python and the C++ backends must emit identical assembly text ... as the parity tests already require" | `parity_bulkmem_{a32,a64,x64}` + the cc runtime cases |
| 5 | The C++ opcode table omits every opcode whose genus is not `BASE`; both instructions are `TBD`, so the C++ PARSER rejects them (`not enough operands for bzero`) before any lowering runs. The fix is in the Python table (genus + regenerating the checked-in `IR/opcode_gen.*` through `IR/Makefile`) | F-9 (table -> generator -> parser) | S6 two evaluators (Python parser accepts, C++ parser rejects) | generated-table provenance | #4 | the symptom reads as a syntax error in the test program, two stages away from the generator; agents patch `serialize.cc` or the C++ table by hand | "the C++ backend does not get that far because it rejects the instructions while parsing" | every `bulkmem.cc.*` and `bulkmem.parity.*` case |
| 6 | Per-target kind reconciliation (x64 keeps `U8`/`S8` consts, a32/a64 widen regs to 32-bit; `lea` offset / `bne` operand kinds must match) | F-9-adjacent (cross-stage kind drop) | A12 type-gate | operand kinds | #1 | the parser hands `16:U8`; using it directly as counter/offset matches on one target and dies on another with a misdirecting isel assert | "a constant or a register of any integer kind" | the same cases on all three targets; `bzero_const_7` (U8), `bzero_reg_u32` |

Axes differ per row (direction source / memory order / placement / dual impl / generated-table provenance /
kinds). REPRODUCED 2026-09-09 on x64 with natural-but-wrong Python variants: #1 segfault at run time, #2 three wrong goldens, zero-guard omission segfault, #3 (after `FunCfgExit`) segfault, #6 `bad reg operand S32 S32 expected: SAME_AS_PREV in [INS beq]` at codegen. The original row 5 (iterating `fun.bbls` while mutating) did NOT bite in Python (list snapshot semantics) and was replaced by the measured C++ table omission. Interdependence: 1<->2<->6 share the length-normalisation code path; 3<->4<->5 share the block
surgery, which must be mirrored in C++.
CONTRACT-STATED/FIX-HIDDEN check per row: the sentences state WHAT (direction, order, both
implementations agree); none names lowering, loops, block splitting, kinds, or phase order.
Rule-7 audit: no instance lists in §6 (the "wherever" sentence is one principle; the cases are tests).
Owed before tests (HARDENING 3a.4): reproduce traps 1, 3, 5, 6 with natural-but-wrong implementations
and confirm the misdirecting symptom; probe P3 self-test shadow (agents will test aligned, positive,
constant lengths — every discriminator above sits off that shape).

## 11b. Capability cross-product (F-10)
| | length >= 0 | length < 0 |
|---|---|---|
| **constant** | bzero 16/7/0, bcopy fwd | bzero -5, bcopy -N (off-diagonal for agents who special-case) |
| **register** | bzero U32 9, bcopy reg | **bzero S32 -6, bcopy reg negative** <- off-diagonal, runtime sign |
Second matrix: overlap {none, dst above src, dst below src} x direction {up, down} -> the two
memmove-safe cells and the two smear cells all have fixtures; results derived from the byte model.
Scope audit: "length" = byte count (stated); "the given addresses" = the operands as passed (stated:
downward starts just below them). Format-noun audit: none. Tolerance rules: none. Example audit: §6
contains no worked example.

## 12. Tier + category
- Tier: Olympus. Sub-rank target: Good (cross-subsystem + dual implementation + composition traps).
- Category: **feature-request** (title verb Add; net-new backend capability; the IR names existed but
  nothing implemented them).

## 13. Predicted pass rate
- Predicted: 15-30% on a Nova/Orion mix; 25-35% on an all-Orion batch.
- Reasoning: one shared kernel (length normalisation + block surgery) feeds 3 targets x 2
  implementations; F-10 off-diagonal (runtime negative register) plus an overlap composition cell; the
  C++ mirror is a genuine long-horizon wall that Nova tends to skip; placement is the only
  codebase-inferable requirement. Risk toward 0%: agents who never build the C++ half; mitigated by
  stating it plainly in §6 (it is the repo's own rule) and by the mechanical precedent (`InsEliminateCmp`
  exists in both files).
- Sanity: <= 40% ceiling; > 0%.

## 14. Quality-gate checklist
- [x] Repo understanding 5/5 (§0)
- [x] Existing PR check: `gh pr list -R robertmuth/Cwerg --state all --search {bcopy,bzero,memcpy,memset,"bulk memory","block copy"}` -> 0 each; issues -> only #45/#29 (maintainer's own, 0 comments, no design). Corpus grep (approved/problems/rejected) for bcopy|bzero|memcpy|memset|lowering -> empty.
- [x] Closest approved opened as scaffolding: avo-register-spilling (backend, Go), neva (F-9/F-10 shape), calyx (compiler pass)
- [x] Title verb-led, 8 words, names the subsystem
- [x] Shape declared with SHAPES.md citation
- [x] Public surface listed (IR instructions + observables)
- [x] Canonical form spelled out (direction, overlap, zero, parity)
- [x] 0-1 codebase-inferable requirements (exactly one: placement)
- [x] Description ~185 words, plain prose, no headers/labels/code-prose
- [x] Footprint sketched against real files; ~290 meaningful across 10 files
- [x] Helpers 1:1 with sentences; no fixpoint needed
- [x] Test outline: golden programs + harness cases; scenario names
- [x] 5-axis coverage planned (atoms listed in §9)
- [x] Forced kinds documented (§10)
- [x] 6 traps, each with F-id, distinct axes, interdependence marked
- [x] § 11b filled; off-diagonal cells have fixtures
- [x] Sibling-API audit (F-20): no sibling API; n/a
- [x] Unobservable-interface audit (F-21): n/a
- [x] Form-parity audit (F-18): constant vs register length is the two-spellings axis; tested at every position
- [x] Format-noun extents stated; no tolerance rules
- [x] Wrong Logic predicted < 25% (the dominant failures are missed-half and integration, not algorithmic)
- [x] Predicted pass <= 40%
- [x] Category matches (feature-request / Add)
- [x] Not pattern-followable (the two block-surgery precedents are forward-branch only and X64-only; no loop-emitting lowering exists)
- [x] Not in RULES § Features already used

## Why this is not a duplicate
Closest approved: **avo-register-spilling** (backend register allocator degradation, Go) and
**calyx-unused-port-elimination** (whole-program compiler pass, Rust). This pick is a lowering of two
bulk-memory IR instructions into control flow across three backends with a mandatory second
implementation; different subsystem class (legalization/lowering, not allocation or analysis),
different language pair (Python + C++), different trap axes (direction/overlap composition, dual-impl
parity). Derivative sentence: "lowers Cwerg's bcopy/bzero IR opcodes through the target-independent
legalizer into byte loops for the a32/a64/x64 backends with Python/C++ parity" — not intelligible
without repo nouns. Residual derivative risk MEDIUM (an outsider can say "memcpy/memset codegen");
mitigated by the repo's obscurity (9 PRs in its lifetime, zero swarm signature).

## Predicted iteration cycles: 2
(one fairness round on the direction/overlap wording is likely; the C++-parity sentence may draw a
"prescriptive" flag and needs the repo-rule justification ready.)
