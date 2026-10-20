# DESIGN.md - csbindgen-const-expression-values

Repo: Cysharp/csbindgen (canonical, MIT, ~950 stars, Rust). Base `512344b9` (= HEAD, 0 commits since, same
base as our approved csbindgen-struct-layout-fidelity). Hunt #37 reserve row (dossier
`worktrees/_hunt/s_0929h37/dossier_csbindgen_h37.md`).

## Phase 1 - repo understanding

- **Architecture (one paragraph).** `Builder` (builder.rs) collects options and input file paths, then
  `lib.rs::generate` parses every input file with syn and, per file, runs the parser collectors
  (`collect_foreign_method` / `collect_extern_method`, `collect_type_alias`, `collect_struct`,
  `collect_enum`, `collect_const`) into flat vectors plus an `AliasMap`. After the loop it computes the
  set of types reachable from the collected methods, prunes structs and enums to that set
  (`reduce_struct` / `reduce_enum`, which SHADOW the unpruned vectors), and hands everything to
  `emitter.rs::emit_csharp`, which renders the NativeMethods class (dll name, consts, delegates,
  methods), then the structs, then the enums. `type_meta.rs` owns the type model (`RustType`,
  `TypeKind`) and the Rust->C# type mapping (`to_csharp_string`, alias resolution included).
- **Subsystems.** (1) builder/options (builder.rs); (2) parser/collectors (parser.rs); (3) type model +
  C# type mapping (type_meta.rs, alias_map.rs); (4) orchestration + pruning (lib.rs, field_map.rs);
  (5) emitters (emitter.rs: C# text and the Rust wrapper file).
- **High-entanglement zones.** (a) the per-file collection loop in `lib.rs::generate` (every collector,
  filter-gated `collect_const` inside it); (b) `to_csharp_string` (alias resolution x pointer/array/fn
  kinds, used by every emitter); (c) the reachability pruning (`collect_using_types`,
  `collect_field_types`, `reduce_*`) that decides which enums/structs exist in the output.
- **Tests.** Lib unit tests only (`lib.rs::tests::test` regenerates lz4 bindings in-tree,
  `update_package_version` no-op, `alias_map::test`). `csbindgen-tests` needs bindgen/libclang + a C
  compiler and is not run. New tests go in `csbindgen/tests/<name>_<hex>.rs` (integration test through
  the public `Builder`), same as the approved problem's `struct_layout_6cd9d4.rs`.
- **Template.** `approved-problems/csbindgen-struct-layout-fidelity/test.patch`
  (`csbindgen/tests/struct_layout_6cd9d4.rs`): `fixture!` macro that compiles Rust items AND
  `stringify!`s them for csbindgen, so rustc is the oracle.

## Phase 2 - exclusivity + six-check (run 2026-09-29, canonical `Cysharp/csbindgen`)

- PR searches (all states): const, constant, discriminant, expression, enum value, shift, bitflags,
  evaluate, u64, overflow, literal. Hits: #125 OPEN "Add support for negative const values", #133
  CLOSED "fix: negative constants are not included", #52 MERGED "enums with negative values", #48/#54/
  #114 unrelated options. **Diffs read:** #125 = `peel_expr` (paren/group) + `-Lit`/`-Float` arms in
  `collect_const` (+35/-25 parser.rs, a build.rs fixture, a .cs file); #133 = the same `-Lit` slice as
  a helper (+31/-26 parser.rs) + one lib test; #52 = the `-Lit` enum arm (+11). None has binary ops,
  casts, references, typing, a global table, enum discriminant expressions or emission changes. They
  are a SUBSET slice (negative literals), not the central capability. Mitigation: no test rests on
  a negative literal alone.
- Issues: #31 "Support constants?" (2023, closed by neuecc "Ver.1.7.4 supports generate const
  option"; the reporter's `1 << 0` example is still dropped at base = the capability is absent, no
  decline). #88 (cross-file struct lookup) is unrelated. No philosophy decline found (scan of const/
  enum issues). No "implemented" closure for expressions.
- Base..HEAD: 0 commits (HEAD = base). Forks ahead (xander-maljaars-centric, SimendoBV) do not touch
  consts (hunter).
- Functional check at base (probe through `Builder::generate_csharp_file`, deleted): `SHIFTED = 1 << 3`,
  `NEG = -5`, `ALLONES: u32 = !0`, `REF = SHIFTED | 1`, `CASTED = 300u16 as u8`, `MAXU = u32::MAX`
  all dropped; `#[repr(u8)] enum Flags { A = 1 << 0, B = 1 << 1, C = SHIFTED as u8, D }` emitted as
  `A, B, C, D` (C# 0..3, Rust 1,2,8,9); `QUOTE = "a\"b\\c"` emitted as invalid `"a"b\c"`; `HUGE: f64 =
  1e20` emitted as the invalid integer literal `100000000000000000000`; `BIG: u64 =
  0xFFFF_FFFF_FFFF_FFF0` PANICS generation (parser.rs:400 `base10_parse::<i64>().unwrap()`).
- Sibling-ecosystem: cbindgen transpiles const expressions to C text (no evaluation, no C# typing);
  bindgen/cexpr evaluates C macros. No syn-based evaluator feeding a C# emitter found; generic syn AST
  handling (`syn::BinOp::Shl` code search) is ubiquitous and not a named algorithm.
- Dedup (problems/, rejected/, approved-problems/): no const-expression or discriminant feature class
  (ezno-enum-declarations is a TS type checker; cwerg-fe-address-constants is a different repo/class).
  Quota: 1/6 (the approved layout problem). Not in SATURATED-REPOS.
- Self-collision: the approved pick changed struct emission/layout (`layout.rs`, `collect_struct`,
  `collect_enum` repr parsing, struct emitter). This lane changes `collect_const`, enum DISCRIMINANT
  values, a new evaluator, the collection/emission split and const/enum value emission. Array lengths
  stay out (the approved meta pins them to literals).

## PICK-FILTER gates

| Gate | Result |
|---|---|
| 1 behavioral F2P gap | PASS - reproduced through the public Builder (above): silent renumbering, dropped consts, a panic |
| 5 cold-not-live | PASS - no const/enum commit since #52/#48 (2023); #125/#133 are the negative-literal slice only |
| 6 reproduce on base | PASS - real entry point, output captured |
| 7b exclusivity PR-DIFF | PASS - diffs of #125/#133/#52 read, subset slice, no evaluator/typing/table |
| 8 defined behavior | PASS - values are Rust's (rustc is the oracle); C# literal rules are the C# spec. Bitflags stay OUT: README L720-745 documents their passthrough form |

## TOO-EASY guard (Step A) and the flagged risk

- Uniform-wrap? No: collection scope, type resolution, enum continuation and emission are different
  mechanisms.
- Single-subsystem mechanical transform? No: parser collection, the lib.rs orchestration/pruning, the
  type model (aliases) and the emitter all change; the per-file filter-gated loop must be split.
- Hardness from the spec not stating something? No: every rule below is stated.
- Saturated port? The arithmetic IS knowable (Rust semantics). **This is the flagged risk
  ("compute the right value", jsondiff/mq).** Design answer: the band must come from the PIPELINE
  (what the table contains, which type a reference carries, which enums exist when a reference is
  resolved, what the existing emitter does to the value), not from arithmetic. Arithmetic cells are
  FP insurance and LOC, budgeted at ~0 kills (L58).
- Survives being fully spelled out? The table-scope walls do: stating "any const in any input file,
  filtered or not, any enum emitted or not" does not say where the repo discards them (per-file
  loop, filter at collection, `let enums = reduce_enum(...)` shadowing, AliasMap filled per file).

## 1. Title
Evaluate constant expressions in csbindgen's C# consts and enums

## 2. Shape
- O-Algorithm-correctness over a parser -> new evaluator/table -> emitter pipeline (closest: the
  approved csbindgen-struct-layout-fidelity, which landed 1/10 on composition cells).
- Dominant verdict predicted: MISSED_REQUIREMENT on composition cells (wrong value, dropped const).
- Category: feature-request (Add/Evaluate: new capability).

## 3. Public API surface
No new public API. The surface is the existing `Builder` (`input_extern_file`, `input_bindgen_file`,
`csharp_generate_const_filter`, `always_included_types`, `generate_csharp_file`) and the text it emits:
`<acc> const <T> NAME = <value>;` inside the class and `NAME = <value>,` inside `enum X : base`.
(Named in meta only by the filter option, which already exists.)

## 4. Canonical output form
- Integer values: any C# integer literal of the value (tests parse decimal or hex, optional
  `u`/`L`/`UL` suffix, and compare numerically) - no representation pin (L48/L49).
- float/double: any C# real literal (or an integer literal in u64 range) whose value round-trips to
  the exact Rust bits, `float.NaN`/`double.PositiveInfinity`/... for specials. Tests parse.
- string/char: any C# literal that DECODES (C# escape rules, including variable-length `\x`) to the
  Rust text. Tests decode.
- Enums: explicit variants carry their evaluated value; a variant without one may stay implicit or be
  written out - tests recompute C# values from the text (implicit = previous + 1).
- Const order = declaration order (unchanged); const C# type = the existing mapping (unchanged).
- 128-bit consts are not emitted (C# cannot declare them const) but can be referenced.
- Unsupported initializer: const skipped as today; enum with an unsupported explicit discriminant is
  not emitted.

## 5. Blind-spot pre-empts
- Pipeline placement: "whether or not the const passes `csharp_generate_const_filter` and whether or
  not the enum is emitted".
- Rule resolution: "a reference has the type its own declaration gives it, following type aliases".
- Iteration/order: "declared before or after it, in any input file of the same generation".
- Implicit successor stated for every variant without a discriminant.

## 6. Description draft (meta.md)
See `meta.md`. 324 words (body + title) after the 2026-10-03 length FAIL at 402. Plain prose, closed
list of expression forms ("any binary operator" is universal because the evaluator covers every
binary operator valid in a const). Rust semantics (`as`, f32) rest on "Values follow Rust".

## 7. File footprint (sketched against the real files; FINISH target)

| Action | Path | Raw | Human-eff | Reason |
|---|---|---|---|---|
| NEW | csbindgen/src/const_eval.rs | ~330 | ~230 | typed value model, literal decode, unary/binary/cast, int MAX/MIN, table + memo + cycle guard, enum tables with successors, C# literal rendering |
| MODIFY | csbindgen/src/parser.rs | ~40 | ~25 | `collect_const` collects every const (no filter, keeps the syn expr), `collect_enum` keeps discriminant exprs |
| MODIFY | csbindgen/src/lib.rs | ~30 | ~20 | collect all files first, evaluate after the loop against the full AliasMap and the UNPRUNED enum list, filter at emission |
| MODIFY | csbindgen/src/type_meta.rs | ~10 | ~6 | `RustConst`/`RustEnumVariant` carry the expression |
| MODIFY | csbindgen/src/emitter.rs | ~25 | ~15 | value emission (no blind `f` suffix on specials, skip 128-bit, string/char escaping) |
TOTAL ~435 raw / ~295 human-eff across 5 files (1 new). Honest range 240-330.

## 8. Solution outline (helpers)
- `IntTy { bits, signed }` from a primitive name (u8..u128, i8..i128, usize/isize = 64, c_* ints);
  `resolve_ty(name, aliases)` follows AliasMap chains to a primitive. <- "declared type, following aliases"
- `Value { Int(i128 wrapped / u128 bits, IntTy), F32(f32), F64(f64), Bool, Char, Str }`, `wrap(v, ty)`.
- `eval(expr, expected: Option<Ty>, ctx)`: Lit (suffix or expected, default i32/f64), Paren/Group,
  Unary Neg/Not, Binary (arith/bit/shift with independent rhs typing, comparisons -> bool, &&/||
  lazy), Cast (`as`: int<->int wrap, float->int saturating NaN=0, int->float, bool/char->int,
  u8->char), Path (const -> table lookup evaluated in ITS declared type; `T::MAX/MIN`), Path to enum
  variant (only under `as`).
- `ConstTable::value(name)`: memoized, evaluates on first use, cycle guard -> None.
- `enum_values(enum)`: explicit discriminants evaluated at the repr type (isize without repr / C),
  implicit = previous + 1, 0 first.
- `csharp_literal(value, csharp_type)`: ints decimal; f32 `{:?}`+`f`; f64 `{:?}`; specials
  `float.NaN`...; strings/chars escaped.
- Fixpoint: none; memoized recursion.

## 9. Test outline
`csbindgen/tests/const_values_<hex>.rs`. Block 1 imports; Block 2 `fixture!` macros (single file and
two-file) that compile the Rust items (rustc oracle) and stringify them; generate helper writing the
temp files and running `Builder` with a given filter + always-included types; Block 3 C# parsers
(const lines, enum blocks with implicit successors, integer/real/string/char literal decoders) and
`assert_int_const(cs, "NAME", fx::NAME as i128)` style assertions; Block 4 tests by bucket:
collection scope, type resolution, enum continuation, value model, emission validity, baseline
(literal consts unchanged, filter still gates emission, fielded enums still skipped).

## 10. Forced bounds
`csharp_generate_const_filter` takes a `fn` pointer: filters in tests are non-capturing closures.

## 11. Trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Catching tests |
|---|---|---|---|---|---|---|---|---|
| 1 | Table scope: const table built per file inside the filter-gated loop; enum table read from the pruned `enums` (lib.rs shadows it with `reduce_enum`) | F-47 (discarded state) / F-9 | S4 machinery-riding | what the table contains | #2 (types come from the same late table), #3 | the natural edit is inside `collect_const`, which already computes the value, per file, after the filter | "A reference can name any const or enum variant in the input files of the same generation, declared before or after it, in any file, whether or not the const passes `csharp_generate_const_filter` and whether or not the enum is emitted." | discriminant -> filtered-out const; const -> const in a LATER file; const -> variant of a never-emitted enum; enum -> const in another file |
| 2 | Reference typed by the referrer's context, and declared types not resolved through AliasMap (filled per file) | F-44 / F-46 | S2 composition | which type a value carries | #1 (alias from a later file) | an evaluator that pushes the expected type into a path, or masks at the end, gets `!A` of a u8 wrong; an alias-typed const needs the map complete | "each const is evaluated in its declared type, following type aliases, and a reference has the type its own declaration gives it" | `(!A) as u32` with `A: u8` = 15; `M: Mask = !0` with `type Mask = u16` in a later file; reference to an alias-typed const in a discriminant |
| 3 | Implicit successor only rendered by C#, never computed, so a reference to it is wrong or missing | F-10 cell | S2 | enum continuation | #1 (pruned enum) | agents emit explicit values only and let C# count | "A variant without an explicit discriminant has the previous variant's value plus one (0 for the first)." | `Other::Q as u32` where Q follows `P = 1 << 2`; successor after a negative; successor of a variant that is itself a reference |
| 4 | Existing emitter decoration leaks onto new values: the blind `f` suffix on `float` (breaks `float.NaN`), integer-looking doubles (`1e20` Display), unescaped strings | F-45 | A3 reuse wrong arm | emission | #5 | the emitter already appends `f` by type name; `format!("{}", f64)` is the repo precedent | "Each emitted value is a valid C# literal ... NaN and infinities use `float.NaN` ... strings and chars are escaped" | NaN/inf f32 and f64; 1e20 f64; 3e38 f32 via alias; string with quote/backslash/newline; char `'\''` |
| 5 | i128/f64 value model | (value model, FP insurance) | B | representation | #4 | an i64/i128 model breaks u64 > i64::MAX and u128::MAX; f64 model breaks f32 arithmetic | "`f32` arithmetic is done in `f32`", "Consts of 128-bit types are not emitted, but others may use them" | `BIG: u64 = 0xFFFF_FFFF_FFFF_FFF0`; `(u128::MAX >> 64) as u64`; `16777216.0 + 1.0 + 1.0` as f32 |

## 11b. Cross-product (F-10)
Axes: surface (const / enum discriminant) x reference origin (same file earlier / later file /
filtered-out const / never-emitted enum variant) x type route (primitive / alias / alias from another
file). Every off-diagonal cell gets one test: enum x filtered-out; enum x later-file alias-typed const;
const x pruned-enum implicit variant; const x alias from later file; enum x reference whose own type
differs from the repr (needs `as`).

## 11c. FINISH test map (2026-10-03, 16 F2P + 2 P2P)
- values: operators (+ `self::` path), position typing (`1 << 40`, `!0 >> 4` in u64, u8 shift amount,
  signed compare/shr/rem, bools), casts (saturation, NaN to 0, bool/char/u8-to-char, f64<->f32),
  declared-type references (`(!HIGH) as u32`, `(HIGH << 1) as u16`, unsigned division after a cast),
  u64 above i64::MAX, 128-bit consts used not emitted (incl. i128 arithmetic shift), float literals
  (1e20, 2.5e300, subnormal), NaN/inf named constants (trap #4: emitter `f` suffix), string escaping
  (quote, backslash, newline, raw string, U+2028, NUL before a hex letter, U+0085, DEL, astral text,
  string-const reference), char escaping + astral char used not emitted.
- scope: later-file refs and alias (+ `Small::MAX` alias from a later file), filtered consts in
  discriminants, variants of a pruned enum (+ `self::Mode::P`).
- enums: cross-file chain (alias-typed filtered const -> pruned i8 enum -> emitted u16 enum and
  sign-extending consts), no-repr / `repr(C)` isize discriminants incl. a pruned 2^40 variant,
  unsupported discriminant drops the enum and its references.
- unchanged (P2P): literal consts, literal and negative discriminants.
- Test oracles stay tolerant: integer literals in any base/suffix, C# real-literal grammar, C# string
  decoding (regular + verbatim, variable-length `\x`), NaN compared by class.

## 12. Tier/category
Olympus, feature-request.

## 13. Predicted pass rate
15-35% after FINISH (18 all-or-nothing tests; the escaping and position-typing cells add independent
ways to fail on top of the table-scope walls). Pre-FINISH estimate was 25-40%. The arithmetic kills nobody (L58). The band rests on #1-#3 compositions and #4 emission.
Risk of reading >40% is REAL (flagged law); first harden lever = more composition cells (F-10), then
the pruned-enum/constant-of-enum-type integration.

## 14. Quality gates
Checked at FINISH (fixture-assertion audit L79, enumeration audit L81, host-semantics audit L80: we do
NOT promise Rust name resolution - a path matches by last segment, stated).

## Why not a duplicate
Closest approved: csbindgen-struct-layout-fidelity (layout engine, struct emission). This lane is the
const/enum VALUE pipeline: a new evaluator, the collection/emission split and value emission. No
overlapping kernel file (layout.rs untouched; `collect_struct`/struct emitter untouched).

Predicted iteration cycles: 2-3.

## Step 4b SLICE scope
Evaluator for ints/floats/bool/char/str with references, the global table (all files, unfiltered,
unpruned enums, aliases), enum discriminants with successors, C# value emission. ~8 tests. Then STOP
for the Requirement 0 picker check and the platform precheck.
