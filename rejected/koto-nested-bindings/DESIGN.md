# DESIGN.md — koto-nested-bindings

## 1. Title

Add nested and rest patterns to every binding site in Koto

Repo: `koto-lang/koto` (MIT, 882 stars, Rust, HEAD 2026-08-06). Base:
`c579dcd02f015e0855d9495d10c7a4479fb82b0c`. Verb: Add -> `feature-request`.

## 2. Shape classification

- Shape: **O-Composite-add** (SHAPES.md § Pattern 12: a language feature spanning parser,
  compiler, VM and runtime), with an O-Composite-extend flavour because the existing unpacking
  kernel (iterator-based, null-filling) has to be generalised rather than a new one added.
- Pass rate target: <= 40% cap, designed for 1-3/10.
- Best agent: Orion. Dominant verdict: MISSED_REQUIREMENT (the rest-with-trailing-targets cell,
  the temp-tuple path, the iterator-of-unknown-length case) and REGRESSION (parser snapshot
  tests, format tests, match ellipsis errors).
- Solver/our LOC ratio: ~1.4x (agents duplicate the unpack loop per site; the reference has one
  kernel).

## 3. Public API surface (language surface; no Rust API names)

Binding sites: plain assignment `x, (y, z) = ...`, `let`, `for ... in`, `catch`. Pattern forms
accepted at each: identifier, ignored `_name`, nested tuple pattern `( ... )` of patterns, map
pattern `{ ... }` (exists), rest capture `id...` / `...`, optional type hint on any identifier,
ignored id, or map pattern (`(a: Number, b), c = ...`).

Semantics (WHAT the tests assert):
- Unpacking is by iteration at every level: a tuple pattern takes the values of its value one by
  one; a missing value binds null; extra values are ignored unless a rest captures them.
- A rest captures the values not taken by its siblings into a tuple: at the end, everything
  after the preceding siblings; at the start or in the middle, everything except what the
  siblings after it need, those siblings then taking the last values in order (null when
  too few remain). At most one rest per tuple pattern; a second one is a compile error.
- A rest works on any iterable value, including a generator or an iterator of unknown length,
  never requiring the value to be indexable.
- Type hints on nested identifiers are checked when the identifier is bound; a failed check
  throws (assignment, `let`, `for`) or falls through to the next arm (`match`, unchanged).
- `export a, (b, c...) = ...` exports every identifier bound anywhere in the targets.
- `match` arm patterns and function arguments are UNCHANGED (the middle-rest lever there was
  built and then dropped: `compile_failures::match_ellipsis_out_of_position` asserts the middle
  position is an error, and superseding a repo test manufactures a cheat trap, L31). Middle rests
  exist in bindings only, where the iterator kernel gives them for free.
- Behaviour of existing flat forms is unchanged, including `koto_format` output for them.

Compile errors (existing kinds reused, exact messages not pinned): `UnexpectedEllipsis` for a
rest outside a binding pattern, `MultipleMatchEllipses` for two rests in a pattern,
`ExpectedAssignmentTarget` for a non-pattern inside a tuple target (e.g. `(f x, y) = ...`).

## 4. Canonical output form

- `a, (b, c), d = [1, [2, 3, 4], 5]` -> a=1, b=2, c=3, d=5.
- `(a, b), c = [[1], 2]` -> b=null. `a, b = 1..=3` -> 1, 2 (extra ignored).
- `a, rest... = 1..=5` -> a=1, rest=(2, 3, 4, 5). `a, rest... = [1]` -> rest=() (empty tuple).
- `first..., y, z = 1..=5` -> first=(1, 2, 3), y=4, z=5. `first..., y, z = [1]` -> first=(),
  y=1, z=null.
- `a, mid..., z = 1..=5` -> a=1, mid=(2, 3, 4), z=5. `a, mid..., z = [1, 2]` -> mid=(), z=2.
- `..., z = 1..=3` -> z=3; `a, ... = 1..=3` -> a=1.
- Rest values are Tuples (never lists), also when the source is a list or a string
  (`a, rest... = 'abc'` -> rest=('b', 'c')).
- `for (a, b), c in ((1, 2), 3), ((4, 5), 6)` iterates twice; `for a, rest... in ...` gives a
  tuple rest per iteration.
- `catch (kind, rest...)` on a thrown tuple binds kind and the remainder; on a thrown string binds
  the first character and the remaining characters (a thrown value is unpacked by iteration).
- Middle rest in `match`: `(a, mid..., z)` matches containers of size >= 2; `mid` is the slice
  between; `(first..., last)` and `(first, rest...)` unchanged.
- Middle rest in function args: `|(a, mid..., z)|` slices the same way; a container with fewer
  than 2 elements throws (existing size-check error).
- Ordering of exports: unchanged (each identifier exported once, in binding order).

## 5. Blind-spot pre-empts

- Iteration semantics: "Unpacking works by iteration at every level ... a missing value binds
  null" (unstated inverse: extra values are ignored).
- Parallel API: "at every place a value is bound: assignment, `let`, `for` and `catch`".
- Rest with unknown length: "any iterable value, including ... an iterator of unknown length".
- Rest value type: "captured into a tuple".
- Middle rest: "at most one rest per pattern".
Codebase-inferable (<= 1): that `koto_format` round-trips the new forms (formatter renders
tuple and packed-id nodes generically today; no meta sentence beyond "existing forms format
unchanged").

## 6. Description draft (meta.md, ~300 words)

Add nested tuple patterns and rest captures to every place Koto binds a value: plain
assignment, `let`, `for` arguments and `catch` arguments. Today only function arguments and
`match` arms accept `(a, (b, c), rest...)` shapes; an assignment such as `(a, b), c = x` or
`a, rest... = x` is a syntax error, and `for (a, b), c in ...` is rejected.

A binding pattern is an identifier, an ignored name, a map pattern, or a parenthesised tuple of
patterns, any identifier or map pattern carrying an optional type hint, and a tuple may contain
one rest written `name...` or `...`. Unpacking works by iteration at every level: a tuple pattern
takes the values of its value one at a time, a missing value binds null and extra values are
ignored. A rest captures into a tuple the values its siblings do not take: at the end everything
that remains, at the start or in the middle everything except what the siblings after it need,
those siblings taking the last values in order and binding null when too few remain. A rest works
on any iterable value, including a generator or an iterator whose length is unknown, and never
requires the value to be indexable. A second rest in the same tuple is a compile error, as is a
rest outside a binding pattern. Type hints on nested identifiers are checked as the identifier
is bound. An exported assignment exports every identifier bound anywhere in its targets.

`match` arm patterns and function arguments also gain a rest in the middle of a tuple pattern,
`(first, mid..., last)`, where the container must hold at least as many values as there are
non-rest patterns; two rests there remain an error. Every existing flat form keeps its behaviour
and its formatting under `koto_format`.

## 7. File footprint (sketched against real source)

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | crates/parser/src/parser.rs | 4312 | +70 / -5 | ~50 | `parse_binding` gains `RoundOpen` (recursive) and `Ellipsis` / `id...` arms; `parse_expressions` converts `id...` in an expression list into `PackedId` and drives the assignment; `parse_assign_expression` validates tuple targets recursively and registers nested ids |
| MODIFY | crates/bytecode/src/compiler.rs | 4980 | +150 / -60 | ~110 | one iterator-based kernel `compile_unpack_binding` (Id / Ignored / Chain / MapPattern / Tuple / PackedId, type hints, exports) used by multi-assign, single tuple assign, `for` args, `catch` args; temp-tuple RHS path routes tuple elements through it; `local_registers_for_assign_target` flattens nested ids; middle-rest in match and function args via `SliceFrom` + `SliceTo` and a `>=` size check |
| MODIFY | crates/bytecode/src/op.rs | 800 | +8 | ~2 | `IterUnpackRest` op doc + variant |
| MODIFY | crates/bytecode/src/instruction.rs | 1034 | +14 | ~10 | variant + Display |
| MODIFY | crates/bytecode/src/instruction_reader.rs | 740 | +8 | ~7 | decode |
| MODIFY | crates/runtime/src/vm.rs | 4380 | +45 | ~38 | `run_iter_unpack_rest`: drain the iterator (temporary tuple/range/string or Iterator), keep the last `keep` values as a new temporary iterable in the iterator register, bind the rest tuple |
| MODIFY | crates/format/src/format.rs | 1200 | 0-10 | 0-8 | only if a new node shape renders wrongly (tuple targets and packed ids already render) |
| MODIFY | crates/cli/docs/language_guide.md | — | +40 | 0 | doc, not counted |

TOTAL: ~300 raw / ~220-240 meaningful across 6-7 files, 3-4 crates. Floor clears; buffer thin,
so the kernel is written once and reused (no per-site duplication) and the match/args middle-rest
lever stays in scope.

## 8. Solution outline — helpers

- `Parser::parse_binding` arms: `RoundOpen` -> parse comma-separated bindings recursively into
  `Node::Tuple { parentheses: true }`; `Ellipsis` -> `PackedId(None)`; `Id` followed by
  `Ellipsis` -> `PackedId(Some(id))` (registers the id as assigned) <- "one rest written
  `name...` or `...`"
- `Parser::parse_expressions`: after an expression in a comma list, an `Ellipsis` on an `Id` /
  `Ignored` node becomes `PackedId`; then `parse_assign_expression` is attempted so
  `a, rest... = x` parses <- plain-assignment rest
- `Parser::parse_assign_expression`: `Node::Tuple` targets validated by `validate_binding_target`
  (recursive; Ids registered as assigned; anything else -> `ExpectedAssignmentTarget`);
  `PackedId` accepted (id registered)
- `Compiler::local_registers_for_assign_target`: `Tuple` -> concat of children; `PackedId(Some)`
  -> one reserved register
- `Compiler::compile_unpack_binding(target, iterator_register, registers: &mut Iter<u8>, ctx,
  export)`: the kernel. `Id` -> `IterUnpack` into reserved register, commit, assert type, export;
  `Ignored` -> `IterUnpack` into temp (+ type) or `IterNextQuiet`; `Chain` -> `IterUnpack` temp +
  `compile_chain`; `MapPattern` -> `IterUnpack` temp + `compile_assign_to_map_finish`; `Tuple` ->
  `IterUnpack` temp, `MakeIterator` on it, recurse; `PackedId` -> `IterUnpackRest` with
  `keep = number of following siblings`, commit/export the rest id (or use a temp for `...`)
  <- every sentence of the semantics paragraph
- `compile_multi_assign`: temp-tuple RHS keeps `TempIndex` per element; a `Tuple`/`PackedId`
  target on that path: tuple -> `TempIndex` element into temp, `MakeIterator`, kernel; packed ->
  build the tuple of the remaining temp-tuple elements via `SequenceStart`/`SequencePush`/
  `SequenceToTuple` (index arithmetic on the fixed count) <- consistency between the two paths
- `compile_assign` with a `Tuple` target: `MakeIterator` on the value, kernel
- `compile_for` multi-arg and single-arg `Tuple`: kernel over `output_register`
- `compile_try_expression` catch arg `Tuple`: `MakeIterator` on `catch_register`, kernel
- `compile_match_arm_patterns` / `compile_nested_match_arm_patterns`: a `PackedId` in the middle
  sets `index_from_end`, slices with `SliceFrom` then `SliceTo(-(remaining))`; size check uses
  `>=` with `patterns_len - 1` whenever any pattern is a rest; `MultipleMatchEllipses` counts
  all positions
- `compile_unpack_nested_args_of_tuple` (function args): same middle-position handling, size
  check `CheckSizeMin` when a rest is present anywhere
- VM `run_iter_unpack_rest(rest, iterator, keep)`: collect remaining outputs into a Vec (pairs
  become 2-tuples, as `IterNext` does for non-temporary output); split off the last `keep`;
  `rest` register <- Tuple(front); iterator register <- Tuple(tail) (a temporary iterable the
  following `IterUnpack`s drain, null-filling) <- "those siblings taking the last values in order
  and binding null when too few remain"

## 9. Test file outline

Path: `crates/runtime/tests/nested_bindings_<hex>.rs` using `koto_test_utils::check_script_output`
and a local `check_script_fails` (mirrors `runtime_failures.rs`). Rust integration tests, no
comments in bodies, one `#[test]` per scenario; script snippets with `assert_eq`-style final
expression values so `check_script_output` compares a single value (tuples for multi-checks).

Block 1 imports; Block 2 helpers: `tuple(&[..])`, `check(script, expected)`,
`check_fails(script)`; Block 3 buckets:
- assignment nested: 2-level, 3-level, map inside tuple, tuple inside map value? (no: map
  entries stay ids), ignored inside tuple, type hint inside tuple (pass + throw), null-fill,
  extra ignored, single tuple target `(a, b) = x`
- assignment rest: trailing, leading, middle, bare `...` at each position, empty rest, rest on a
  generator, rest on a lazily infinite iterator with `.take`, rest from a string, rest inside a
  nested tuple, rest with type-hinted siblings, two rests -> compile error, rest outside a
  pattern (`x... `) -> compile error, `rest...` as a call argument still packs (unchanged)
- temp-tuple RHS (`a, (b, c) = 1, (2, 3)` and `a, rest... = 1, 2, 3`): both paths agree with the
  iterable RHS results
- let: nested with type hints, rest, `let (a: Number, b), c = ...` throw on mismatch
- for: nested args, rest args, single tuple arg, nested with type hint, over a map (`for (k, v),
  i in m.enumerate()`? -> `for i, (k, v) in m.enumerate()`), body sees values, export of loop ids
  at top level unchanged
- catch: `catch (kind, detail...)` on thrown tuples/strings, nested, typed nested
- export: `export a, (b, c...) = ...` then `import` sees all three (via module string / `koto`
  crate? use `export` inside a script and read back via the vm's exports: `check_script_output`
  cannot; use `koto` crate `Koto::compile_and_run` + `exports().get(...)`)
- match middle rest: `(a, mid..., z)` sizes 2, 3, 5; falls through on size 1; with alternatives
  `or`; two rests -> compile error; function-arg middle rest sizes 2 and 5; size 1 throws
- baseline: flat multi-assign, flat for, flat catch, existing ellipsis-at-end/start in match and
  args, formatter round-trip of `a, (b, c...) = x` and `for (a, b), c in x`

Atom decomposition of "at the start or in the middle everything except what the siblings after it
need, those siblings taking the last values in order and binding null when too few remain":
enough values (3 cells), exactly enough, too few (rest empty + trailing null), way too few (all
trailing null), and the leading-rest vs middle-rest twins of each.

Test count anchor: ~70-90.

## 10. Forced bounds / kwargs

None new; Rust test helpers call `check_script_output(&str, impl Into<KValue>)`. Tuple
expectations built with `KValue::Tuple(KTuple::from(vec![...]))`; nulls with `KValue::Null`.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Two unpack paths: the temp-tuple RHS (`a, (b, c) = 1, (2, 3)`, `TempIndex`) and the iterable RHS (`MakeIterator`+`IterUnpack`) must both support nesting and rests and agree | F-9 / S5 | S5 | RHS form | #2, #3 | agents implement nesting on the iterator path and leave the fast path returning `UnexpectedNode`, or vice versa | "Unpacking works by iteration at every level" (no path named) | temp-tuple twins of every nested/rest test |
| 2 | Rest on an iterator of unknown length: index-based slicing (the function-arg machinery agents reuse) needs `size`; generators and `iterator.repeat(x).take(n)` have none | F-10 (form axis: source kind) | A3 | source indexability | #1, #4 | the repo's only rest implementation is index-based (`SliceFrom`/`SliceTo`) and is the obvious thing to reuse | "any iterable value, including a generator or an iterator whose length is unknown, and never requires the value to be indexable" | generator rest, `take` rest, string rest |
| 3 | Leading / middle rest with trailing siblings under iteration: values must be collected before the trailing targets can be assigned, and the null-fill rule interacts with "last values" | A9 exact-fit | A9 | count arithmetic | #2 | agents self-test with exactly enough values; the too-few case is where "last values" and null-fill compose | the "binding null when too few remain" clause | too-few / way-too-few fixtures (N-1, L25) |
| 4 | Register reservation before RHS compilation: nested ids must be reserved BEFORE the RHS is compiled (so `a, (b, c) = c, (a, b)` reads old values), then committed after; `PackedId` needs a register too | S3 baseline through the chokepoint | S3 | compiler register discipline | #1 | the reservation code enumerates target kinds; a new kind that is not reserved produces stale or clobbered registers, visible only in swap-shaped tests | none (repo-internal) | swap tests `a, (b, c) = c, (a, b)`; `x, rest... = rest, x` |
| 5 | Export and type-hint plumbing over nested leaves (`export`, `let (a: Number, b)`, top-level `for` export) | F-3 second axis | A6 | binding-time side effects | #1 | agents wire the value flow and forget the per-leaf side effects at depth | "Type hints on nested identifiers are checked as the identifier is bound. An exported assignment exports every identifier bound anywhere" | typed nested throw; export then import |
| 6 | Middle rest in match/args: `index_from_end` must switch at the rest, size check must become `>=` with count-1, `MultipleMatchEllipses` must count all positions; the args path duplicates this logic in `compile_unpack_nested_args_of_tuple` | F-10 (site axis) x F-20 (sibling rule leak) | S2 | pattern position x site | #3 | two copies of the index-from-end logic; fixing match and not args (or the reverse) | "match arm patterns and function arguments also gain a rest in the middle" | middle-rest tests on both sites, size-1 fall-through vs throw |
| 7 | Plain-assignment parsing: the LHS is parsed as an EXPRESSION list, so `rest...` has to be recognised there and `(a, b)` arrives as a `Tuple` expression node that must be validated as a pattern (a call inside must be rejected, ids must be registered as assigned for capture analysis) | F-1-ish (architecture) | A11 | parser architecture | #4 | `parse_binding` is the obvious place and covers `let`/`for`/`catch` only; plain assignment silently keeps failing or, worse, captures wrongly because ids were not registered | "plain assignment, `let`, `for` arguments and `catch` arguments" | plain-assignment tests + closure capture test (`f = || a` after `a, (b, c) = ...`) |

Scope audit: "at most one rest per tuple pattern" (per level); "extra values are ignored" applies per level. Example audit: the meta has one pattern example `(first, mid..., last)` naming the middle form, no worked semantics example. Format-noun audit: "tuple pattern" = the parenthesised group; "sibling" = pattern at the same level. Tolerance fixture: n/a. Wrong Logic prediction: ~20%.

## 11b. Cross-product matrix (F-10)

Axes: binding site {assignment, let, for, catch} x pattern form {nested tuple, trailing rest,
leading rest, middle rest, typed leaf} x RHS kind {temp tuple, tuple/list, range, string,
generator}.

| | nested | trailing rest | leading rest | middle rest | typed leaf |
|---|---|---|---|---|---|
| **assignment** | list, temp tuple | list, generator, temp tuple | range, too few | range, too few | throw + pass |
| **let** | list | list | list | — | throw + pass |
| **for** | list of lists | generator of tuples | range of ranges | — | throw |
| **catch** | thrown tuple | thrown string | — | — | typed nested |
| **match / args (index path)** | existing | existing | existing | NEW sizes 1,2,5 | existing |

Off-diagonal cells shipped: assignment x middle rest x too-few; for x trailing rest x generator;
catch x trailing rest x string; assignment x nested x temp tuple; let x leading rest.

## 12. Tier + category

Olympus, Good. Category: **feature-request** ("Add ...").

## 13. Predicted Nova pass rate

20-35%. The parser and the happy-path kernel are derivable; the band is held by the two-path
consistency (S5), the unknown-length rest (A3), the too-few arithmetic (A9), register
reservation (S3, invisible until a swap test) and the plain-assignment parsing architecture.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (below)
- [x] PR/issue search 0 hits (below)
- [x] Closest approved opened: `gluon-format-comments` (Rust language tooling) and
      `neva-array-bypass-generalization` (the "every form X supports works for Y" shape)
- [x] Title verb-led · shape declared · API surface = language surface · canonical forms
- [x] <= 1 codebase-inferable (formatter round-trip)
- [x] Description ~300 words, plain prose
- [x] Footprint against real files, ~220-240 meaningful, 6-7 files
- [x] Helpers 1:1 with sentences; kernel written once
- [x] Test outline, 5-axis, per-atom decomposition, N-1 fixtures for the too-few rule
- [x] 7 traps, distinct axes, interdependent through the kernel
- [x] § 11b filled with off-diagonals
- [x] F-20 audit: the middle-rest rule is scoped to "match arm patterns and function arguments";
      the OLD end/start forms are guarded by existing tests (`compile_failures.rs`,
      `vm_tests.rs`) and by new baseline tests both directions
- [x] F-21 n/a · unbounded-promise n/a · F-18 n/a (`name...` and `...` are one form with an
      optional name; both tested at every position)
- [x] Stated nouns: assignment, let, for, catch, identifier, ignored name, map pattern, tuple
      pattern, rest, type hint, iteration, null, generator, iterator, indexable, compile error,
      export, match arm, function argument, size, `koto_format`
- [x] Wrong Logic < 25% · pass <= 40% · category matches · not pattern-followable

## Phase 1 — repo understanding

Architecture: `koto_lexer` -> `koto_parser` (AST with `Node` enum; `BindingContext` for
`let`/`for`/`catch`/args; assignment LHS parsed as expressions then validated in
`parse_assign_expression`; `Frame` tracks ids assigned/accessed for capture analysis) ->
`koto_bytecode` (register-allocating compiler: `reserve_local_register` before RHS,
`commit_local_register` after; unpacking ops `IterUnpack`, `TempIndex`, `SliceFrom`/`SliceTo`;
match arms with `index_from_end`) -> `koto_runtime` (VM: `run_iterator_next` handles temporary
iterables (Range/Tuple/Str/TemporaryTuple) by popping in place and `Iterator` values via `next`)
-> `koto_format` (renders nodes generically; `MultiAssign`, `Tuple`, `PackedId` exist) ->
`koto` (engine, exports). Five subsystems: parser, bytecode, runtime, format, cli/koto engine.
Entanglement zones: (1) the LHS-as-expression parse feeding `Frame` capture analysis; (2) the
two unpack paths (temp tuple vs iterator) in `compile_multi_assign`/`compile_for`; (3)
`index_from_end` logic duplicated between match arms and nested function args. Tests: Rust
integration tests per crate (`crates/runtime/tests/vm_tests.rs` with
`check_script_output`, `runtime_failures.rs` with `check_script_fails`, parser snapshot tests
in `crates/parser/tests/snapshots`, `crates/format/tests/format_tests.rs`). Template:
`crates/runtime/tests/vm_tests.rs`.

## Phase 2 — searches (2026-09-09/10)

`gh pr list`/`gh issue list -R koto-lang/koto --state all --search` for: nested, destructuring,
unpacking, rest, ellipsis, pattern, "multi assign", spread. Hits: #475 map destructuring (closed,
shipped by `bluurryy` 2025-11, flat map patterns only), #418 packed call args (shipped), #396
"should unpacking a single value be supported" (closed, answered yes: `x, y, z = 42`). No PR or
issue mentions nested tuple targets, rest captures in bindings, or middle-position rests; the
guide documents ellipsis only "at the start or end of a container" for function args and match.

## Why this is not a duplicate

Closest: `neva-array-bypass-generalization` (Go; "every connection form works for the bypass")
shares the generalisation SHAPE but a different repo/domain; `numbat-parse-unit-expressions`
touches a Rust parser but for units. No corpus entry touches Koto or binding patterns.

Predicted iteration cycles: 2.
