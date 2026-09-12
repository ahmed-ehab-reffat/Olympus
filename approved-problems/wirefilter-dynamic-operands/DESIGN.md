# DESIGN — wirefilter-dynamic-operands

## 1. Title

Meta title: "Accept expressions where filters used to require literal values".

## 2. Repo + gates

- Repo: `cloudflare/wirefilter` (MIT, 1149 stars, last commit 2026-07-21, Rust, 19.8k LOC).
- BASE_COMMIT: `af1a1e960a8fdc44a1a154553470dfbb286afbe8`.
- Gate 1 BEHAVIORAL-F2P-GAP: PASS. Probe on base: every target form is a **parse error**
  (`http.host == http.referer`, `port > backend_port`, `http.host contains http.referer`,
  `hosts[*] == http.host`, `http.host in hosts`, `port & backend_port`). The right-hand side of
  every comparison is hard-wired to a compile-time literal (`RhsValue::lex_with`, `RhsValues`,
  `BytesExpr`, `i64`, `Regex`, `Wildcard`).
- Gate 2 SATURATION: PASS. Not a spec port. wirefilter's dialect is Cloudflare-specific; the
  shape/nil/pairing rules below are invented for this engine (no reference implementation to
  port, no external oracle needed or available).
- Gate 3 UNIFORM-WRAP: PASS. Four non-collapsing decisions (see § 5): the literal fast paths must
  survive, the four operand-shape cases need different compile paths, nil symmetry is a separate
  rule, and the visitor/`uses` subsystem is untouched by any of them.
- Gate 4 LOC-CEILING: target >= 450 human-effective; the feature multiplies out over
  {ordering x 6 ops} x {Int, Bytes, Ip} x {scalar, mapped} x {present, missing} plus
  `&`, `contains`, `in`, and the parse-time rejections. Scope lever held in reserve: dynamic
  index keys (`headers[key]`).
- Gate 5 COLD-NOT-LIVE: PASS. Recent maintainer work is refactor/perf (PRs #162-#185); no
  language-surface work on comparison operands.
- Gate 6 REPRODUCE-ON-BASE: done (probe above).
- Gate 7 DEDUP: no `wirefilter` and no filter-expression-operand pick in `problems/`,
  `rejected/`, `Aprroved/`, `Olympus/`.
- Gate 7b EXCLUSIVITY: canonical org resolved (`cloudflare/wirefilter`, no redirect). PR search
  across all states for `field comparison`, `rhs field`, `dynamic`, `compare two fields`,
  `field reference`, `index`, `arithmetic`: no PR touches the comparison operand surface.
  Issue #62 ("Full syntax support for Cloudflare Firewall Rules language") is open and generic.
- Gate 8 DEFINED-BEHAVIOR: the capability is maintainer-desired in spirit (#62) and the semantics
  are pinned by this design; nothing here is declined anywhere.
- Gate 9 NO-FLAKY-REPO: `cargo test --workspace` on base = 120 + 13 + 23 + 2 green in < 2s, no
  timing/network/ordering dependence. Re-run 3x before submit.
- Gate 10 REPO-QUOTA: first submission against this repo; 1149 stars, niche.
- Env Quality: `cargo check --workspace --all-targets` on the vanilla tree succeeds (all members
  incl. `wasm`, `ffi`, `fuzz/*`); deps are light. The repo's `rust-toolchain.toml` asks for
  `channel = "stable"`, which the offline image does not have installed, so the Dockerfile removes
  the file and cargo uses the image's default 1.95.0 toolchain.

## 3. Shape

O-Composite-extend: extend an existing language surface (comparison operands) through the parse,
type-check, compile and visitor stages of an expression engine. No new public API: everything is
observable through `Scheme::parse`, `FilterAst::compile`, `Filter::execute` and `FilterAst::uses`.

## 4. Behaviors (the contract; each maps to tests)

R1. The right operand of an ordering comparison (`eq`/`==`, `ne`/`!=`, `ge`/`>=`, `le`/`<=`,
    `gt`/`>`, `lt`/`<`) may be an expression instead of a literal: a field, an indexed access
    (`a[0]`, `m["k"]`, `a[*]`), or a function call. Both sides must have the same type after
    map-each indexing, otherwise the filter does not parse.
R2. `&` / `bitwise_and` accepts an expression right operand of type Int; it matches when the
    bitwise and of the two values is non-zero.
R3. `contains` accepts an expression right operand of type Bytes and matches when the left value
    contains the right value as a substring.
R4. `in` accepts an expression right operand of type `Array(T)` when the left operand has type
    `T`, and matches when the left value equals one of the array's elements. A Map right operand
    does not parse.
R5. `matches` / `~`, `wildcard` and `strict wildcard` keep requiring a literal pattern; an
    expression right operand does not parse.
R6. Shapes: when exactly one side maps over an array, the other side's single value is compared
    against every element and the comparison produces one boolean per element. When both sides
    map, elements are paired by position and the comparison produces one boolean per pair,
    stopping at the shorter side. Boolean arrays feed `any(...)` / `all(...)` as before.
R7. Missing values: when either operand has no value the comparison does not match, except `!=`,
    which matches (subject to the scheme's existing nil-not-equal behavior). When a mapped side
    has no value the comparison produces an empty boolean array.
R8. `FilterAst::uses` / `Filter::uses` report fields referenced by right operands too.
R9. Literal right operands keep their existing behavior, error messages and serialization.

## 5. Trap matrix (arsenal mapping)

| # | Trap | Class | Mechanism | Misdirection |
|---|------|-------|-----------|--------------|
| T1 | Literal fast paths must survive a second operand path | S3 baseline preservation | comparisons compile through per-op/per-type `Compare` specializations plus precompiled substring searchers, int/ip ranges and serde shapes; rerouting everything through one generic dynamic path regresses base tests | failures land in existing tests (serde output, error spans), not in the new feature |
| T2 | Four operand shapes need three compile paths | S5 dual-path consistency | `IndexExpr::compile_with` picks One/Vec from the **left** side's map-each count only; mapped-right and both-mapped need paths built from value expressions and a positional zip | scalar tests pass, mapped tests return the wrong length or the wrong side's shape |
| T3 | Nil symmetry | S2 composition | the existing default only covers a missing **left** operand (`Compare` never sees the right side); a missing right operand must follow the same rule, including the `!=` inversion | a wrong result is only visible when a field is deliberately unset, and the natural code returns plain `false` |
| T4 | `uses` / visitor | machinery-riding, hidden subsystem | `walk`/`walk_mut` must descend into the right operand or `uses` under-reports | nothing in "compare two fields" points at the visitor |
| T5 | Parse-time typing and rejections | S6 two evaluators | the parser type-checks against the scheme; mismatched types, Map operands for `in`, and expression patterns for `matches`/`wildcard` must be rejected at parse time, not at execution | an implementation that only handles compilation accepts them and then misbehaves at runtime |
| T6 | Invasive threading in Rust | A1 | `Compare` is a static-dispatch trait used by macro-generated per-op code inside a 3.3k-line file | compile failures rather than assertion failures |

CONTRACT-STATED / FIX-HIDDEN check: R1-R9 state the observable contract without naming
`Compare`, `compile_with`, `compile_with_compiler`, the visitor, or where the shape decision
lives. Stating "one boolean per pair" does not reveal that the left side alone drives the
existing compile path.

## 6. Files (planned footprint)

| File | Change |
|------|--------|
| `engine/src/ast/field_expr.rs` | new `ComparisonOpExpr` variants for expression operands, operand lexing + type checks, compile paths, serde, walk |
| `engine/src/ast/index_expr.rs` | value-expression compile helpers, positional pairing / broadcast vec paths |
| `engine/src/ast/operand.rs` | new module: value-to-value comparison, operand lexing and type checks, shape compile paths, `contains` sets |
| `engine/src/scheme.rs`, `engine/src/types.rs`, `engine/src/ast/mod.rs`, `engine/src/lib.rs` | `FieldIndex::Dynamic` variant and the matches it forces open |

## 7. Tests (outline, hidden file `engine/tests/operand_expr_7972d7.rs`)

Blocks: (a) scheme + helpers; (b) ordering per type incl. symbolic and word forms;
(c) `&`, `contains`, `in`; (d) shapes: mapped-left, mapped-right, both-mapped equal and unequal
lengths, nested map-each, inside `any`/`all` and `not`; (e) nil: each side unset, `!=` inversion,
mapped with unset array; (f) function-call operands and indexed operands; (g) parse rejections:
type mismatch, Map for `in`, expression pattern for `matches`/`wildcard`; (h) `uses` reporting;
(i) literal-path regressions (old forms still behave).

## 8. Solvability

Reference implementation proves it. No hidden API: tests exercise only `parse`, `compile`,
`execute`, `uses`, so no signature guessing can zero a run (avoids the compile-wipe hazard).

## 9. Decisions taken during implementation

- The comparison-operand core alone measured 203 human-effective LOC, so all three planned scope
  levers were built: computed index keys (`headers[key]`, `hosts[i]`, 354), boolean operands plus
  whole array/map equality (411), and the `contains {...}` set form (503). Each is a distinct
  subsystem under the same one-sentence principle, not padding.
- A computed index may not be combined with `[*]` in the same access. That keeps the map-each
  iterator machinery out of scope, and the rule is stated in the description.
- Serde shape for the new AST variants is deliberately not asserted by tests, so no invented JSON
  shape is pinned; existing serde tests stay untouched and pass.
- Final footprint: 7 files, 768 raw / 503 human-effective LOC, 101 new tests.
