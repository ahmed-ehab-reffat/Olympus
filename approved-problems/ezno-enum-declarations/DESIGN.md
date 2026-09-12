# DESIGN.md — ezno-enum-declarations

## 1. Title

Check enum declarations in the TypeScript checker

Verb-led, names the subsystem (the checker's declaration/type layer).

## 2. Shape classification

- Shape: **O-Composite-add** (a new language construct spanning hoisting, synthesis, the type store, subtyping, property access, printing and diagnostics).
- Pass rate target: <=40% cap; design target 1/10 (the corpus mode).
- Best agent: Vega / Orion (long-horizon, multi-file).
- Dominant verdict expected: MISSED_REQUIREMENT (assignability composition) and REGRESSION (shared property/subtyping chokepoints).

## 3. Public API surface

**No new Rust API.** The whole feature is observed through the existing entry point
`ezno_checker::check_project::<_, synthesis::EznoParser>(...) -> ... .diagnostics`, so the new
tests compile against the base tree and fail on assertions, not on missing symbols.

Behavioural surface (what tests assert):

- `enum E { ... }` introduces a value `E` and a type `E` of the same name.
- `E.A` — member access, yields the member type.
- `E[n]` — reverse lookup on a numeric member, yields `string`.
- `const enum E { ... }` — member access only.
- Diagnostic texts (new, exact):
  - `Enum member must have initializer`
  - `Duplicate enum member 'A'`
  - `A const enum member can only be accessed using a string literal`
  - `'const' enums can only be used in property or index access expressions`
- Reused diagnostics (existing wording): `Type X is not assignable to type Y`,
  `Expected X, found Y` (`satisfies`), `No property 'x' on ...`.
- Printing: a member type prints `E.A`; the enum type prints `E`.

## 4. Canonical output form

- Member values: first member with no initializer is `0`; any later member with no initializer is
  the previous member's numeric value plus one.
- Constant initialiser expressions fold: numeric literals, references to members already declared
  (bare name inside the same enum, `Other.M` for another enum), unary `-` `+` `~`,
  binary `+ - * / % & | ^ << >> >>>`, parentheses.
- A member with no initializer after a string valued member or after a non constant initialiser is
  an error; that member has no value.
- Reverse entries exist for numeric members only, mapping the value to the member name.
- Duplicate member names: error on the second one; the first keeps its value.
- Assignability (the composition):
  - member type -> its own enum type: yes; member type -> `number` (numeric) or `string` (string): yes
  - `number` -> numeric enum type: yes; a numeric literal type -> numeric enum type: only when the
    literal equals one of the members' values
  - `string` or a string literal type -> string enum type: never
  - a member of a different enum -> this enum type: never (declaration identity, not value equality)
- `const enum` declares no value object.
- Empty enum: declares a type with no members and an empty object; nothing is assignable to it
  except itself.

## 5. Blind-spot pre-empts

- Sort/identity: "two enums with equal member values stay distinct" -> stated as declaration identity.
- Unstated inverse: the numeric-literal rule is stated together with the string-literal rule so the
  asymmetry is contract-stated (its fix is still hidden: it needs a value set AND an identity check).
- Iteration termination: constant folding only sees members already declared (no forward refs).
- Codebase-inferable count: 1 (the existing `ObjectBuilder` / `PropertyValue` conventions).

## 6. Description draft

See meta.md. One general principle ("reproduce what TypeScript does") plus the ezno-specific bits
that cannot be recalled: the four new diagnostic texts, how the types print, and the assignability
composition. No wall enumeration, no worked example of the folding algorithm.

## 7. File footprint (sketched against real source)

| Action | Path | Raw delta | Reason |
| --- | --- | --- | --- |
| MODIFY | checker/src/synthesis/hoisting.rs | +90 | declare the enum type + value in both namespaces, const enums |
| MODIFY | checker/src/synthesis/statements_and_declarations.rs | +170 | member value computation, constant folding, object + reverse entries |
| MODIFY | checker/src/types/store.rs | +60 | enum + member side tables, constructors |
| MODIFY | checker/src/types/subtyping.rs | +80 | the assignability composition |
| MODIFY | checker/src/types/properties/access.rs | +70 | const enum access rules, member/reverse lookup |
| MODIFY | checker/src/types/printing.rs | +35 | `E` and `E.A` |
| MODIFY | checker/src/diagnostics.rs | +45 | the four new errors |
| MODIFY | checker/src/synthesis/expressions.rs | +40 | bare `const enum` reference is an error |
| MODIFY | checker/src/types/mod.rs | +30 | enum info structs |

TOTAL sketch: ~620 raw / ~470 human-effective across 9 files. Clears the >=450 design floor.

## 8. Solution outline (pure-function helpers)

- `fold_enum_member_value(expr, already_declared, types) -> Option<EnumValue>` <- constant folding
- `next_auto_value(previous: Option<EnumValue>) -> Result<f64, MissingInitializer>` <- auto-increment
- `register_enum_type(name, is_const, types) -> TypeId` <- dual namespace
- `enum_member_type(enum_id, name, value, types) -> TypeId` <- nominal member types
- `reverse_entries(members) -> Vec<(PropertyKey, TypeId)>` <- numeric-only reverse map
- `enum_accepts(base_enum, argument, types) -> bool` <- the assignability composition
- `const_enum_access(enum_id, key) -> Result<TypeId, ConstEnumMisuse>` <- const enum rules

No fixpoint loop needed (members fold in declaration order, one pass).

## 9. Test file outline

Path: `checker/tests/enum_declarations_<hash>.rs` (a new cargo test target in the checker crate, so
base mode keeps running the repository's own targets).

Block 1 — imports (`ezno_checker::{check_project, synthesis, TypeCheckOptions}`)
Block 2 — one builder helper: `check(source) -> Vec<String>` (diagnostic reasons in order)
Block 3 — assertion helpers: `assert_clean(source)`, `assert_errors(source, &[&str])` (substring)
Block 4 — buckets:
- member values (auto increment, explicit, mixed, folding, forward reference) ~14
- missing initializer / duplicates ~8
- the enum object + reverse mapping (numeric only, heterogeneous) ~10
- assignability composition (number, numeric literal match/mismatch, string, cross-enum, member ->
  primitive, enum -> literal union) ~16
- const enums (member access, index access, bare reference, no object) ~8
- narrowing + `satisfies` printing ~8
- edge cases: empty enum, single member, negative and zero values, unicode member name, exported
  enum, enum inside a block ~12

Target ~75 tests.

## 10. Forced signatures

None new. Tests only touch `check_project`, `TypeCheckOptions::default()`, `Diagnostic::reason()`,
all of which exist on base (verified in `checker/tests/suggestions.rs`).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Contract sentence | Test |
| --- | --- | --- | --- | --- |
| 1 | Auto increment tracks the previous **value**, not the member index | base already numbers by index; the natural rewrite keeps `enumerate()` | "a member with no initializer takes the previous member's value plus one" | `explicit_then_auto_continues_from_value` |
| 2 | Reverse entries for numeric members only | the emitted-object mental model adds both directions uniformly | "numeric members are also reachable by their value" | `string_member_has_no_reverse_entry` |
| 3 | Nominal identity vs numeric literal membership | a union-of-constants model accepts another enum's member; an opaque nominal model rejects a plain `0` | both halves stated | `other_enum_member_not_assignable`, `matching_number_literal_assignable` |
| 4 | String enums invert trap 3 | the numeric rule is generalised to strings | stated | `string_literal_not_assignable_to_string_enum` |
| 5 | `const enum` shares the object build path | the natural fix builds the object then hides it, so index access still resolves | "a const enum declares no value" | `const_enum_index_access_errors` |

Traps 1, 2 and 3 are interdependent: the reverse map needs the values from trap 1, and the
assignability set needs both. Trap 5 rides the same object-building chokepoint as trap 2.

## 12. Tier + category

- Tier: Olympus. Category: feature-request (a new construct in the checker).

## 13. Predicted pass rate

10-30%. Levers stacked: one interdependent kernel (the enum type + its value object feeding
assignability, property access, printing and narrowing), an external oracle (tsc 5.6, used to derive
every pinned behaviour), 5 interdependent traps of which 3 are "the obvious code is wrong", a cold
bespoke host, and no new Rust signature to guess.

## 14. Quality gate

- [x] Repo understanding (workspace = parser + checker; synthesis -> types -> subtyping -> printing;
      entanglement zones: `types/subtyping.rs`, `types/properties/access.rs`, `synthesis/hoisting.rs`;
      tests live in `checker/tests/*.rs`, template `checker/tests/suggestions.rs`)
- [x] Exclusivity: `gh pr list -R kaleidawave/ezno --state all --search "enum"` -> no PR implements
      enum checking (PR #187 is a 2024 iteration/events branch, untouched since 2024-08-29);
      `gh issue list` -> none. Base reproduces the gap (`Unsupported: enum with value`).
- [x] Closest approved problems opened: `tinywasm-exception-handling` (spec-defined construct in a
      bespoke engine) and `cadence-default-arguments` (declaration-layer feature).
- [x] Corpus recipe: kernel + oracle + >=3 interdependent misdirecting traps + "obvious is wrong".
- [x] No new signatures to guess (fake-difficulty anti-pattern avoided).
- [x] LOC sketch >= 450 human-effective.
- [x] Not pattern-followable: no sibling construct in the checker has a value/type dual namespace with
      nominal members.

## Why this is not a duplicate

Closest siblings in `Instructions/Aprroved/`: `cadence-default-arguments` (Go, adds defaults to an
existing callable declaration - no new type kind, no assignability work) and
`tinywasm-exception-handling` (Rust, a runtime construct, no declaration or type layer). No approved
or rejected problem touches an enum construct, a nominal type kind, or a TypeScript checker.

Predicted iteration cycles: 2.
