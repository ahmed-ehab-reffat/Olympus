# DESIGN.md - cwerg-fe-address-constants

Repo robertmuth/Cwerg (Apache-2.0, 707 stars), base `3bc94f7c1c26834f98c614aef51b5aa7370615d9` (= master
HEAD, no later commits). Hunt #35 RANK 1 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-29.md`).

## Phase 1 - repo understanding

- **Architecture.** Cwerg is a compiler for a small C-like language with a Python reference and a C++
  port of every stage. The front end (FE/) parses `.cw` modules, expands macros, resolves symbols,
  types the AST (`typify`), partially evaluates it (`eval`, a fixpoint over the whole program that
  annotates nodes with `x_eval` values and checks `static_assert`), then lowers it in phases
  (`canonicalize*`: index to pointer arithmetic, implicit vec to span conversions, spans and unions
  to recs, large args), runs a small optimizer (`optimize`: inlining, copy propagation, peephole),
  hoists constant literals into generated globals (`GlobalConstantPool`) and emits textual Cwerg IR
  (`emit_ir`), including global data as `.data` / `.addr.mem size name offset` directives. The
  back end (BE/) turns IR into ELF executables for x64, a64 and a32 (Python and C++ codegen tools,
  C++ ELF writer `BE/Elf/elf_unit.h`).
- **Subsystems.** (1) FE parse/macro/symbolize, (2) typify + type corpus (target layout), (3) FE
  partial evaluator `FE/eval.{py,cc,h}`, (4) FE lowering `FE/canonicalize*.{py,cc}` + `optimize`,
  (5) FE IR emission `FE/emit_ir.{py,cc}`, (6) BE codegen + ELF writer.
- **Entanglement zones.** (a) `x_eval` values are produced by eval and consumed after several AST
  rewrites (canonicalize replaces ExprIndex, ExprFront-of-span and vec-to-span conversions with new
  nodes); (b) the constant pool runs after canonicalize and rewrites ValString/ValCompound into Ids of
  new globals; (c) py/cc parity: the repo's `assimilation_after_opt_tests` diffs Python and C++ IR.
- **Tests.** `FE/Makefile_py` (py FE, `*_test.cw` programs run under qemu, self-checking via
  `Lib/test.cw` macros), `FE/Makefile_cc` (`tests_meta`, assimilation py-vs-cc IR diff).
- **Template.** `FE/LangTest/consts_test.cw` (static_assert style) and `FE/TestData/sieve_test.cw`
  (runtime AssertEq style).

## Phase 2 - existing PR / publicly-solved check

CANON=`robertmuth/Cwerg` (unchanged). All 9 PRs ever read (typos, CI, docker, one Go FE stub #39):
none touches FE eval/emit. PR searches for "address constant", "addr.mem", "symbolic address",
"static_assert", "global initializer", "pointer", "offset", "eval", "constant pool", "ptr_inc": empty.
Issue searches: #49 (ref semantics, no position), #41 (const philosophy), #57 (unify FE/BE partial
eval, refactor), #40, #23: none is this capability, no declined/by-design language. Maintainer TODOs
invite it (`eval.py` "TODO maybe track symbolic addresses", "we do not track constant addresses yet").
`git log -S addr.mem -- FE/`: offset always 0, no removal record. base..origin/master: 0 commits.
Dedup: no `addr.mem` / address-constant pick in approved-problems/, problems/, rejected/.

## 1. Title
Add symbolic address constants to the Cwerg front end

## 2. Shape
O-Pipeline-hard (twin implementation, cross-stage). New value domain in the evaluator carried through
two lowering stages, the emitter and the ELF writer, under a py/cc identical-IR contract.
Dominant predicted verdict: INTEGRATION_ERROR / wrong value (parity and run failures).

## 3. Public API surface (language level, no new syntax)
- Address constants from `@g.f`, `@g[k]`, `@p^...`, `front(vec)` (incl. vec fields), `front(span)`,
  `ptr_inc(addr, k)`, Ids of immutable pointer globals.
- `==` / `!=` / `ptr_diff` on address constants at compile time (`static_assert`, folding).
- `p^`, `span[k]` folded when the pointee is in an immutable global.
- Emission in pointer globals, span globals, vec/rec literal elements; x64/a64/a32.
- Python (`FE/compiler.py`) and C++ (`build/compiler.exe`) identical IR.

## 4. Canonical output form
Emission `.addr.mem <ptrsize> <global> <byte offset>`; offsets follow target layout (`aligned_size`
strides, `x_offset` fields). No order/dedup choices exposed.

## 5. Blind-spot pre-empts
- "equal only when both the global and the offset match" (identity).
- "left to run time when it lies in a mutable (`global!`) one" (mutability).
- "whether it was made with `make_span` or converted from a vec, including a vec field" (span sources).

## 6. Description draft
See `meta.md` (draft, ~250 words).

## 7. File footprint (measured on the slice, hook human-effective)
| File | human-eff |
|---|---|
| FE/eval.py | 90 |
| FE/eval.cc | 105 |
| FE/eval.h | 13 |
| FE/emit_ir.py / .cc | 10 / 14 |
| FE/canonicalize.py / .cc | 4 / 7 |
| FE/canonicalize_span.py / .cc | 3 / 4 |
| BE/Elf/elf_unit.h | 1 |
| **Total (slice)** | **251** (padding-floor 133, twins) |

FINISH target >= 280-320 with genuine extras (see section 15).

## 8. Solution outline
- `AddressOfPlace(node)` (py + cc): Id -> symbol address; ExprDeref -> operand value; ExprField ->
  container address + field `x_offset`; ExprIndex -> front(container) + k * element `aligned_size`.
- `_EvalFront` / `EvalFront`: vec -> AddressOfPlace; span -> span pointer + offset.
- `_GetValAtOffset` / `GetValAtOffset`: resolve a byte offset inside an evaluated vec/rec value down to
  the requested type (the "read through" kernel), `_EvalDeref` uses the global's own `x_eval` (None for
  `global!`).
- `EvalSpan` carries a pointer offset; content only when the span covers a whole vec value.
- ExprPointer INCP, ExprDeref, PDELTA, EQ/NE on address values; vec-to-span conversion keeps pointer.
- C++: `GLOBAL_ADDR` becomes an interned `{sym, offset}` in `ConstPool` (handle equality = value
  equality); every `ConstGetGlobalAddr` consumer keeps working.
- canonicalize: implicit vec-to-span conversion computes the pointer via `AddressOfPlace`;
  span elimination keeps the front's value on the replacement `ExprField`.
- emit_ir: pointer-typed initializers (`ExprFront`, `ExprAddrOf`, `ExprPointer`, `ExprField`) emit from
  the value; falls back to the Id (constant-pool strings are rewritten after canonicalize).
- BE C++ ELF writer: pass the `.addr.mem` addend to the relocation (was `ASSERT(addend == 0, "NYI")`).

## 9. Test outline
New dir `FE/AddrTest/`, self-checking `.cw` programs (hex suffix 2c16e3). Each program is compiled
with the py and the cc FE for x64, a64, a32, built with the C++ BE, run under qemu (exit 0 + `OK`),
and the py/cc IR is diffed per target. Slice: 4 programs x 9 cases = 36 cases.
- `globals`: field, element, nested field element, front of vec field, ptr_inc, chain through a
  pointer global.
- `tables`: vec of pointers, span global into the middle of a vec, front(span global), rec with span
  and pointer fields.
- `static`: `!=` across offsets, `==` with a pointer global, ptr_inc chain equality, ptr_diff, deref
  folding (vec, rec field, nested vec in rec), offset span indexing, front(span) identity.
- `runtime`: local address compare not folded, deref of a `global!` element observed after a store.
Base mode: every existing `*_test.cw` (py+cc FE, C++ BE, x64+a64, a32 list from Makefile_py) and the
repo's assimilation parity on all non-generic sources (x64). 330 cases.

## 10. Forced bounds
None (no new API signatures; language-level feature). C++ `EvalSpan`/`EvalGlobalAddr` are interned
by bytes: every field must be initialized (no padding) - agents that add an `int64` next to a
32-bit handle get nondeterministic interning (pad bytes) - a real host-language wall (A4).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Value computed in eval is lost when canonicalize rebuilds the node (vec-to-span conversion of a vec FIELD, `front(span global)` -> ExprField, constant-pool strings rewritten after canonicalize) | F-9 | S6/S3 | stage | #2 (span pointer representation), #4 | the crash names emit_ir; the natural fix reads `x_eval` in the emitter, which is None on rebuilt nodes; removing the Id fallback breaks base programs with string fields in rec literals | "A span keeps its constant pointer whether it was made with `make_span` or converted from a vec, including a vec field" | tables (`front(middle)`, `v.items`), globals (`front(pr.v)`), base consts_test |
| 2 | Span content assumed to start at element 0 once the pointer carries an offset | new (S2 composition) | S2 | value | #1 | `EvalSpan.content` is the whole vec; an offset span reusing the global's content indexes from the wrong element silently | "Reading through an address constant (... indexing a constant span) gives a constant" | static (`sub[0] == 20`) |
| 3 | Read-through of a `global!` folded from its initializer | new | P2 over-eagerness | mutability | #2 (same kernel) | the initializer's value is right there; folding makes the store invisible | "left to run time when it lies in a mutable (`global!`) one" | runtime (`p_counter^` after store) |
| 4 | Twin parity: C++ `Const` handle holds only a symbol index; offset must be interned (handle equality); C++ emitter/ELF writer; C++ BE addend NYI reached only through the C++ back end | F-31 / F-32 family | S5 + A4 | implementation | #1 (same rebuilt nodes in cc) | Python passes first; C++ `GLOBAL_ADDR` consumers silently decode garbage if re-encoded partially; ELF writer aborts | "Python and C++ front ends must keep emitting identical IR ... build with the C++ back ends" | every `cc.*` and `parity.*` case |
| 5 | Identity: `__eq__` / handle compare on symbol only | F-2 | A8 | identity | #4 | existing `EvalGlobalAddr.__eq__` compares `sym`; C++ equality comes free only if interned | "equal only when both the global and the offset match" | static (`@arr[1] != @arr[2]`), runtime (`a == b` branch) |

## 11b. Cross-product (F-10)
| | pointer global | vec table element | rec field | span global |
|---|---|---|---|---|
| field `@g.f` | globals | - | - | - |
| element `@g[k]` | globals | tables | tables (`last`) | - |
| front(vec field) | globals | - | - | tables via rec span field |
| ptr_inc / chain | globals | tables | - | tables (`middle`) |
| front(span) | tables | - | - | - |
Every cell x {py, cc} x {x64, a64, a32} + parity. FINISH adds: union-widened pointer, rec-in-vec
tables with padding, a32-only layout shift cells, string (EvalBytes) read-through, pointer-to-pointer.

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
25-45% on the slice suite. Guard #1 risk (single insight "carry an offset") is real: a strong agent
that implements AddressOfPlace in both twins and reads values in the emitter clears traps 4/5
together. The walls that one insight does not discharge are #1 (rebuilt nodes, needs the Id
fallback kept), #2 and #3 (read-through kernel semantics) and the C++ interning + ELF addend. Take a
smoke batch early; harden with F-10 cells and read-through composition in FINISH.

## 14. Quality gates
- [x] Phase 1 5/5, Phase 2 clean (commands above), closest approved read (cwerg-bcopy-bzero-lowering)
- [x] Title verb-led; shape declared; API listed; canonical form stated
- [x] File footprint measured (251 human-eff slice)
- [x] Traps on different axes, #1-#2-#3 interdependent through the span/read-through kernel
- [x] No new API signatures (no compile-wipe risk)
- [x] Twin-parity scope (L60): pre-existing divergences found so far - `ExprBitCast` of an address
      (cc returns the address, py None), cc `ValueConstKind` ignores rec compounds, cc static_assert
      message on unevaluable conditions, pre-existing x64 C++ BE failures on expr_test/expr_sint_test.
      No new-mode fixture reaches any of them.
- [x] Cold build 4m22s (< 600 s)

## 15. FINISH scope candidates (not built in the slice)
- Constant-pool hoisting of local vec literals whose elements are address constants (classifier in
  both twins + peephole keeps the value) - parity-visible only.
- Read-through of strings (EvalBytes) and of pointer-to-pointer globals (`pp^^`).
- Union-widened pointer initializers (`ExprWiden` over an address constant).
- a32-specific layout cells (rec of pointers, span recs are 8 bytes on a32).
- Ordering compares (`<`) on same-global addresses.

## Why this is not a duplicate
- cwerg-bcopy-bzero-lowering (approved): BE IR opcodes + lowering/legalize/isel. This pick touches FE
  eval/canonicalize/emit and a one-line BE ELF addend; no opcode, no lowering file.
- cwerg-memory-passed-parameters (rejected): BE calling convention. Unrelated.
- The Cwerg issue roadmap does not contain this capability (invented lane from source-tree TODOs).

Predicted iteration cycles: 3.
