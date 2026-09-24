# DESIGN.md — csbindgen-struct-layout-fidelity

Sources: hunt dossier `worktrees/_hunt/agents/csbindgen-0919.md`, spike addendum
`worktrees/_hunt/agents/csbindgen-SPIKE-0919.md`, .NET check `worktrees/_tools/csbindgen-netcheck/`.

## Phase 1 — repo understanding
- **Architecture:** `csbindgen` reads Rust source (`extern "C"` fns or bindgen output) with `syn`
  (`parser.rs`) into its own model (`type_meta.rs`: `RustType`/`TypeKind`, `RustStruct`, `RustEnum`,
  `ExternMethod`), resolves aliases (`alias_map.rs`), prunes to used types (`field_map.rs` +
  `lib.rs::reduce_struct`), then writes C# P/Invoke text (`emitter.rs`, type strings in
  `RustType::to_csharp_string`) and optionally a Rust wrapper (`to_rust_string`). No stage computes a
  size, alignment or offset.
- **Subsystems:** parser (syn -> model) / type model + C# type mapping / alias map / field map +
  reduction / emitter. Builder (`builder.rs`) is the public API.
- **Entanglement zones:** `TypeKind::FixedArray` (parser, both type-string emitters, emitter's
  `[0]`->`[1]` hack, alias arrays); struct emission in `emit_csharp`; alias resolution
  (`get_mapped_value` walks only one layer and drops `[Handle;2]` when `Handle` is a pointer alias).
- **Tests:** `cargo test -p csbindgen` = 3 lib unit tests (`alias_map_test`, `tests::test`
  regenerating lz4 bindings, `update_package_version` no-op). `csbindgen-tests` needs libclang + cc and
  is out of scope. Template: the spike's `csbindgen/tests/layout_probe.rs` (integration test through
  `Builder::input_extern_file(..).generate_csharp_file(..)`).

## Phase 2 — prior art (run 2026-09-19, again at submit)
- Canonical `Cysharp/csbindgen`. PR/issue search (array, fixed, packed, align, layout, padding, repr,
  offset, size_of, InlineArray, FieldOffset): no PR in any state. Issues #91 (non-maintainer proposal
  to expand `[T;2]`, closed-stale, no code), #100 (padding, user-closed), #74 (fielded enums, declined,
  different lane). Base 512344b = origin/main (2026-08-26).
- Forks: only `xander-maljaars-centric/csbindgen` touches the lane (16-line nested-primitive-array
  flatten). interoptopus ships packed -> `Pack = 1`, declares `align` UNSUPPORTED. ClangSharp emits
  `_e__FixedBuffer` for non-primitive C arrays. Neither computes transitive layout promotion.
- No removal record (full history, `git log -S` packed/align/Pack =/offset in `csbindgen/src`).

## Phase 3 — pick
Candidates considered in the hunt: negative constants (open PR #125, dead), field casing (open PR
#129, dead), generics (public closed PR #120, dead), tagged enums (declined #74, dead), callback alias
naming (~120 eff, magnet), **layout fidelity (open, 0 PRs)**. Picked the last.

Death-class guard: one shared kernel (Rust layout + C# layout model + promotion predicate) feeds every
struct, union, array and alias surface; a local fix to one (e.g. "align -> Explicit") regresses
another (the container that must stay Sequential, cells 6/19/21). Not a standalone file: the parser
must keep repr args and array element types, the emitter must consult the kernel per field. Not a
spec port: .NET's rule for explicit-struct alignment and csbindgen's own emission choices define the
predicate. Survives full specification: the rule is stated; the fix (compare the two computed layouts
using the C# alignment of what is actually emitted) is not.

## 1. Title
Add layout-faithful struct emission to csbindgen's C# output

## 2. Shape
O-Algorithm-correctness (new variant + subtle algorithmic correctness): new layout calculator plus a
keep-or-promote decision whose correctness is only visible on nested cases. Dominant verdict expected:
REGRESSION (over-promotion breaking byte-identical cells) and MISSED_REQUIREMENT (transitive cells).

## 3. Public API surface (tests assert only generated text)
- `Builder::input_extern_file(..).always_included_types([..]).generate_csharp_file(..)` (existing).
- Output forms: `[StructLayout(LayoutKind.Sequential, Pack = N)]`,
  `[StructLayout(LayoutKind.Explicit, Size = S)]` + `[FieldOffset(k)]` per emitted field, union
  `[StructLayout(LayoutKind.Explicit, Size = S)]`, expanded array fields `<name>_0 .. <name>_{n-1}`,
  flattened `fixed T name[total]`.

## 4. Canonical output form
- Attribute arg order: `LayoutKind.X` first, then `Size = S`, then `Pack = N`.
- Expanded arrays: row-major, `<field>_<i>` with i from 0 over the flattened element count.
- Explicit struct: every emitted field carries `[FieldOffset]`; zero-size fields are not emitted.
- Unchanged cases: byte-identical to base output.

## 5. Blind-spot pre-empts
Pipeline placement (decide per struct after nested types are known), stated inverse (what stays
Sequential), adjacent-vs-all (transitive through every nesting kind: field, array element, alias,
union).

## 6. Description
See `meta.md` (single source; ~370 words).

## 7. File footprint (spike-measured where marked)
| Action | Path | eff (Counter 2) |
|---|---|---|
| NEW | csbindgen/src/layout.rs | 144 measured core, +~35 array model |
| MOD | csbindgen/src/parser.rs | 36 measured |
| MOD | csbindgen/src/emitter.rs | 24 measured, +~35 array expansion |
| MOD | csbindgen/src/type_meta.rs | 5 measured, +~10 element string / Rust wrapper |
| MOD | csbindgen/src/lib.rs | 13 measured |
| MOD | csbindgen/src/alias_map.rs | 2 measured |
| **Total** | 6 files | 224 measured core -> ~300-320 with arrays |

## 8. Solution outline
`layout.rs::LayoutMap` (memoized, cycle-guarded): `rust_layout(ty)`, `csharp_layout(ty)` mirroring
the emitted text, `struct_layout(name)` -> {rust, csharp, fields, explicit}. Parser:
`parse_struct_repr`. Emitter: attribute args, per-field offsets, array expansion driven by an
`array_shape(ty)` helper (innermost element + total count). lib.rs builds the map over all structs
before reduction.

## 9. Tests
One file `csbindgen/tests/struct_layout_<hex>.rs`, modules by requirement (packed, aligned,
transitive, arrays, unions, zero_size, unchanged, bindgen). Oracle: a `fixture!{}` macro compiles the
Rust items AND `stringify!`s them as csbindgen input; assertions compare parsed `Size`/`FieldOffset`
against rustc `size_of`/`offset_of!` (x86_64 LP64), and exact text for unchanged structs.

## 10. Forced bounds
None (tests only read generated text).

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdep. | Test |
|---|---|---|---|---|---|---|
| 1 | Transitive promotion through fields, arrays, aliases, unions | F-5 | S3 | reachability | #2 | Outer, Wrap, RowS, AliasHolder, SU |
| 2 | Keep-or-promote uses C# alignment of the EMITTED nested struct, not "contains an explicit type" | F-20 | S5 two evaluators | predicate | #1, #3 | A8/Holder, HasObjArr, HasBits, U4 |
| 3 | Array expansion must be mirrored in the C# model (expanded arrays stop needing promotion) | F-9 | S6 | representation | #2 | ObjArr/Grid/Sizes stay Sequential; union array element offsets |
| 4 | Zero-size: marker omitted and forces Explicit, zero-size struct untouched | new (F-17-ish) | A | size-0 edge | #2 | Bits, HasBits, opaque handle |
| 5 | Alias through a pointer alias inside an array (`[Handle;2]`) | F-9 alias drop | A | resolution | #3 | alias pointer array cell |

## 11b. Cross-product
{Pack, align, plain} x {struct, union} x {direct, nested, array element, alias}: key off-diagonal
cells = packed nested in explicit (align = pack), align union nested in struct, array of over-aligned
struct via alias, expanded array inside a union (element offsets), expanded array inside an explicit
struct.

## 12. Tier/category
Olympus, feature-request ("Add ...").

## 13. Predicted pass
20-35%. Spike's strongest alternative design (~215 eff) failed 3 of 21 over-promotion cells; array
mirroring adds a fourth failure family.

## 14. Gate checklist
Phase 1/2 done; .NET rule verified (23/23 structs identical rustc vs .NET 8 runtime); LOC measured
224 core; core-slice precheck owed before array scope.

Why not a duplicate: no approved/in-flight FFI or codegen-layout problem in this workspace; closest
approved code generators (calyx, cwerg) are compilers, different subsystem class.
Predicted iteration cycles: 2.
