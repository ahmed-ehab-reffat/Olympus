# DESIGN — yara-x-aggregate-expressions

## 1. Title

Meta title: "Add aggregate expressions over iterables to rule conditions".

## 2. Repo + gates

- Repo: `VirusTotal/yara-x` (BSD-3-Clause, 1229 stars, last commit 2026-07-27, Rust, edition 2024,
  MSRV 1.91, ~137k LOC in `lib` alone).
- BASE_COMMIT: `aae0a1ea73e8bad84d9237cff2073351f2d2a88d`.
- Gate 1 BEHAVIORAL-F2P-GAP: PASS. Probed on base with `yara_x::compile`:
  `rule t { condition: count i in (0..3) : ( i > 1 ) > 1 }` and the `sum` form both fail with
  `error[E001]: syntax error`, while `for any i in (0..3) : ( i > 1 )` and
  `with x = 1 : ( x == 1 )` compile. There is no way to obtain a count, a total, or an extremum
  over an iterable today: the whole `for` family returns a boolean.
- Gate 2 SATURATION: PASS. Neither YARA nor YARA-X has any aggregation construct, and there is no
  reference implementation to transcribe. The semantics below (undefined-skip, empty-iterable
  results, static result typing) are invented for this engine.
- Gate 3 UNIFORM-WRAP: PASS. Four non-collapsing decisions (see § 5): where the aggregate name is
  allowed to be special without breaking `math.min`, how the shared loop emitter is split so a
  non-boolean accumulator can ride it without changing the six existing lowerings, how the IR's
  result type stops being hardcoded to bool, and what an undefined body does per operator.
- Gate 4 LOC-CEILING: target >= 450 human-effective. The feature multiplies over
  {4 operators} x {range, expression tuple, array, map} x {integer, float body} plus the parser,
  the IR type rules, the emitter and the undefined/empty cases. Scope lever held in reserve:
  an `avg` operator and aggregate-as-quantifier (`for (for count ...) i in ...`).
- Gate 5 COLD-NOT-LIVE: PASS. Recent maintainer work is modules, perf and the language server
  (PRs #625, #626, #627, #678, #684). No PR in any state touches loop lowering, the quantifier
  grammar or the `for` IR. Issue #611 asks for a membership operator and issue #15 for hex bit
  masks; neither overlaps.
- Gate 6 REPRODUCE-ON-BASE: done (probe above).
- Gate 7 DEDUP: no yara/yara-x pick anywhere in `problems/`, `rejected/`, `Aprroved/`,
  `Olympus/`, `_shelved/`, `Task1..6`, `Hagora`. The corpus does hold SQL-style aggregate picks
  (risinglight statistical aggregates, tantivy pipeline aggregations, gluesql/turso window
  functions); those share the word but not the core: there is no relation, no grouping and no
  planner here. The core is loop lowering into WebAssembly plus undefined propagation.
- Gate 7b EXCLUSIVITY: canonical org resolved (`VirusTotal/yara-x`, no redirect). PR search over
  all states for `aggregate`, `sum`, `count expression`, `min max`, `for loop`, `quantifier`
  returns only perf and module PRs; none touches `emit_for`, the quantifier grammar or the IR.
- Gate 8 DEFINED-BEHAVIOR: nothing here is declined anywhere. The construct is a natural
  extension of the existing `for` family and is spelled out by this design.
- Gate 9 NO-FLAKY-REPO: `cargo test -p yara-x` on base is green offline (322 + 20 + 0 passed,
  0 failed) in ~12s, and `cargo test --workspace --no-run` builds every member. No timing,
  network or ordering dependence in the blast radius. Re-run 3x before submit.
- Gate 10 REPO-QUOTA: first submission against this repo; 1229 stars, an obscure niche
  (malware rule matching) rather than a household-name VM or SQL tool.
- Env Quality: the workspace builds and its tests pass offline; deps are heavy (480 crates,
  wasmtime + cranelift) but `Cargo.lock` is committed, so a single `cargo fetch` at image build
  time is enough. Debug build of `lib` plus tests takes ~2 min and 2.9 GB.

## 3. Shape

O-Composite-extend: extend an existing language surface (the `for` family) through tokenizing,
parsing, the concrete and abstract syntax trees, IR construction, static typing, WebAssembly
emission and the runtime. No new public Rust API: everything is observable through
`yara_x::compile` and `Scanner::scan`.

## 4. Behaviors (the contract; each maps to tests)

R1. A condition may contain an aggregate expression `for <agg> <var> in <iterable> : ( <body> )`
    where `<agg>` is `count`, `sum`, `min` or `max`. It is an expression, not a boolean: it can be
    compared, used in arithmetic, nested in another loop's body and wrapped in `defined`.
R2. `count` takes a boolean body and yields the number of iterations whose body is true.
R3. `sum`, `min` and `max` take an integer or float body. The result is an integer when the body
    is an integer and a float when the body is a float; a non-numeric body does not compile.
R4. An iteration whose body value is undefined contributes nothing, exactly as an undefined body
    counts as false in `for any`.
R5. Over an iterable with no iterations, or when every iteration contributed nothing, `count` and
    `sum` are 0 while `min` and `max` are undefined.
R6. Integer results wrap on overflow, as the `+` operator already does.
R7. The iterables are the ones the `for` family already accepts: ranges, parenthesized expression
    tuples, and module arrays and maps, with the same rules about how many loop variables each
    one binds.
R8. `count`, `sum`, `min` and `max` keep working as ordinary identifiers everywhere else, so
    `math.min`, `math.max` and `math.count` and a rule named `sum` are unaffected.
R9. Quantified `for` and `of` expressions keep their existing results, warnings and error
    messages, including the warning about a loop over a potentially very large range.

## 5. Trap matrix (arsenal mapping)

| # | Trap | Class | Mechanism | Misdirection |
|---|------|-------|-----------|--------------|
| T1 | The aggregate name must be special in exactly one position | S3 baseline preservation | the tokenizer is a `logos` derive where every keyword is a global `#[token("...")]`; reserving `min`/`max`/`count` steals them from the field-access path and breaks `math.min`, `math.max` and `math.count` | failures land in the math module's own tests, nowhere near the feature |
| T2 | The shared loop emitter is boolean-shaped | A1 invasive refactor | `emit_for` fuses iteration with quantifier bookkeeping, returns i32 and stops as soon as the quantifier is decided; it has six callers. An aggregate must visit every iteration and carry a typed accumulator | a naive reuse returns a partial total that is right whenever the first items already settle the quantifier, so simple tests pass |
| T3 | Loop variable slots | S5 dual-path | `VarStack::FOR_IN_FRAME_SIZE` is a fixed frame size shared by every loop; an accumulator needs another slot, and `E047` accounting is computed from the same constant | a slot collision surfaces as a wrong value or a WebAssembly validation failure, not as a compile error |
| T4 | The IR hardcodes the result type | S6 two evaluators | `Expr::ForIn`'s `ty()` and `type_value()` return bool unconditionally, and the emitter trusts them; the aggregate's type has to come from its body, and float promotion in a surrounding comparison depends on it | a wrong type is not reported, it produces a WebAssembly type mismatch far from the aggregate |
| T5 | Undefined per operator | S2 composition | the existing body goes through `emit_bool_expr`, which swallows undefined into false; skipping an undefined item is right for all four operators, but "nothing contributed" then has to mean 0 for two of them and undefined for the other two | only visible when a module field is missing or a division by zero happens inside the body |
| T7 | An aggregate nested in another loop's header | S3 baseline preservation + A1 | `ast2ir` allocates a loop's frame AFTER building its quantifier and iterable, and releases it on the way out, so a sibling expression reuses the same slots. An aggregate evaluated while an outer loop's frame is live therefore overwrites that loop's `n`, `i` or accumulator. Fixing it needs the aggregate's frame reserved before its iterable is built AND the shared emitter to evaluate the quantifier before the loop variables are set up | the loop silently produces a wrong count or a wrong total; nothing errors, no existing test covers it, and the whole repo suite stays green while it is broken |
| T6 | Warnings and iteration budgets | machinery-riding | `loop_iteration_multiplier`, `TooManyIterations` and `PotentiallySlowLoop` are threaded by the `for` builder; an aggregate that does not thread them silently drops the warnings | nothing in "add an aggregate" points at the warning subsystem |

CONTRACT-STATED / FIX-HIDDEN check: R1-R9 describe what a rule author observes. None of them names
the tokenizer, `emit_for`, `ForVars`, `FOR_IN_FRAME_SIZE`, `emit_bool_expr` or the IR's `ty()`.
R8 states that `math.min` must keep working without saying that the fix is to keep the aggregate
names out of the token set and recognize them positionally.

## 6. Files (planned footprint)

| File | Change |
|------|--------|
| `parser/src/tokenizer/mod.rs` | nothing reserved globally; the aggregate names stay identifiers |
| `parser/src/parser/mod.rs` | recognize an aggregate name in the quantifier position and build the new CST node |
| `parser/src/cst/mod.rs` | new syntax kind for the aggregate expression |
| `parser/src/ast/mod.rs` | `Expr::ForAgg` plus its span and ascii-tree rendering |
| `lib/src/compiler/ir/mod.rs` | `Expr::ForAgg`, its type rules, traversal and variable-frame size |
| `lib/src/compiler/ir/ast2ir.rs` | body typing per operator, loop variable scoping, iteration budget threading |
| `lib/src/compiler/emit.rs` | split the iteration scaffolding out of `emit_for` and add the accumulator lowering per operator and per iterable |
| `lib/src/compiler/errors.rs` | the error raised for a non-numeric aggregate body |

## 7. Tests (outline, hidden file `lib/tests/aggregate_<hex>.rs`)

Blocks: (a) helpers that compile and scan; (b) `count` over ranges, tuples, arrays and maps;
(c) `sum`, `min`, `max` on integer and on float bodies; (d) empty and fully undefined iterables
per operator; (e) undefined items mixed with defined ones; (f) integer wrapping; (g) aggregates
inside arithmetic, comparisons, `defined`, another loop's body and a `with`; (h) aggregates used
as a `for` quantifier; (i) rejections: non-numeric body, boolean body for `sum`, wrong number of
loop variables; (j) regressions: `math.min`, `math.max`, `math.count`, a rule named `sum`, and the
unchanged results and warnings of quantified `for` and `of`.

## 8. Solvability

The reference implementation is built against this design; every behavior above is reachable
through `yara_x::compile` and `Scanner::scan`, so no Rust signature has to be guessed and no
compile-wipe hazard exists.

## 9. Decisions taken during implementation

- Final footprint: 11 files across 2 crates, 951 raw / 613 human-effective LOC, 41 new tests.
- The aggregate names are recognized positionally rather than reserved, because reserving them
  breaks `math.min`, `math.max` and `math.count` (trap T1, which bit for real).
- `Expr::ForAgg` is the last variant of the IR enum on purpose: the `Hash` impl uses
  `discriminant`, so inserting it anywhere else changes the hash of every later variant and
  breaks the `5.ir` goldenfile.
- An aggregate nested in another loop's header was broken in the first reference and is now the
  lead trap; see the hardening round in feedback.md.

## 10. Open items

- Docker image not yet built; the 4-cell was run on the host, not offline inside
  `olympus-base-rust`.
- FP check and platform batch not yet run.
