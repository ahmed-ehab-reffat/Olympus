# feedback.md — ezno-enum-declarations

## Summary

- Repo: [kaleidawave/ezno](https://github.com/kaleidawave/ezno), Rust, MIT, 2731 stars, 57.8k source LOC, workspace = `parser` + `checker` + CLI, no system dependencies.
- BASE_COMMIT: `8a763a0a1e92317b4822a9ea1cfaaf150b036f12` (2025-10-25, the default branch head).
- Tier: Olympus. Category: feature-request. Shape: O-Composite-add.
- Feature: check `enum` declarations - member values, the value object with reverse entries, a nominal enum type with TypeScript's assignability rules, const enums, narrowing.
- Status: batch 2 (Orion) reached 190/203; the 13 failures were 11 unstated pins plus 2 parser-bug tests, all removed or relaxed. Replaying that agent's patch against the revised suite gives 198/199, the only miss being a stated requirement.

## Host selection log

The user asked for a fresh Rust repo, so every repo already present under `worktrees/`, `problems/`, `rejected/`, `Olympus/` or `Instructions/Aprroved/` was excluded (about 700 names). Candidates killed on hard gates:

| Candidate | Killed by |
| --- | --- |
| vortex-data/vortex (compute kernels across encodings) | 435k LOC, 40+ crates including CUDA / JNI / python / duckdb; the vanilla workspace suite cannot be green offline, and the scan planner is a live maintainer workstream (revert commits from this week). |
| algesten/str0m (sans-IO WebRTC) | env verified green (`cargo build --tests` clean, 108k LOC, pure Rust option), but every capability in the repo is an RFC or is already implemented by libwebrtc / pion / aiortc. External-reference-exists = publicly-solved signal; the open issues are either spec transcription (H.264 profile-level-id matching, already a known reference algorithm) or 30-line bug fixes. |
| josh-project/josh (git history filter DSL) | ideal shape (bespoke filter language, apply/unapply dual path) but 66 commits in 90 days on the filter engine itself, including new filters and optimizer laws landing this month. Cold-not-live gate. |
| trishume/syntect (sublime-syntax branch/fail) | exclusivity dead: `branch` / `fail` / branch-point machinery already exists and has open PRs refining it. |
| Automattic/harper, tobymao-class hosts | 14k stars, the obvious host for its category (presumed globally saturated). |
| stateright, tremor-runtime | last source commit older than 12 months (recency gate). |
| pcodec | 492 stars, under the 500 floor. |
| rustic, oxipng, fluent-rs, rumqtt, iggy, y-crdt | restic-compatible / PNG spec / Fluent spec / MQTT spec / Kafka-class / CRDT-class - either a documented reference exists or the capability class is already mined locally. |

ezno cleared every gate: MIT, 2731 stars, last commit 2025-10-25 (cold but inside the 12 month window), pure Rust with a 24 second full build and test cycle, deterministic (no clock, network, filesystem or ordering dependence in the checker), and no submission of ours has ever used it.

## Why this feature

- Capability gap reproduced on base. `./target/debug/ezno check` on

      enum Direction { Up = 1, Down, Left, Right }
      const bad: Direction = 7
      Direction[1] satisfies string

  reports `Unsupported: enum with value`, numbers the members `0,1,2,3` from their index, accepts `7` as a `Direction` (the type is aliased straight to `number` in `hoisting.rs`), and cannot resolve `Direction[1]`. Every one of those is observably wrong against tsc.
- Exclusivity: `gh pr list -R kaleidawave/ezno --state all --search "enum"` and the issue equivalent return nothing that implements enum checking. The only open PR (#187, iteration and events) has not moved since 2024-08-29 and does not touch the enum paths.
- Not a self-contained bolt-on: the enum type has to ride the existing subtyping, property access, printing and narrowing machinery, so a natural implementation can regress base behaviour.
- Oracle: TypeScript 5.6.3 (`tsc --noEmit --strict`), installed locally. Every pinned behaviour below was derived from it, not from memory.

## Oracle findings (tsc 5.6.3) that shape the traps

| Program | tsc |
| --- | --- |
| `enum F { A = 3, B }` | `F.B === 4` (previous value plus one, not the index) |
| `enum S { A = "x" } ; S["x"]` | error - string members get no reverse entry |
| `enum E { A = 0 } ; const x: E = 0` | accepted (a numeric literal equal to a member value) |
| `enum E { A = 0 } ; const x: E = 5` | `Type '5' is not assignable to type 'E'` |
| `declare let n: number ; const x: E = n` | accepted (plain `number` is assignable) |
| `enum S { A = "x" } ; const s: S = "x"` | `Type '"x"' is not assignable to type 'S'` |
| `enum E {A=0} enum G {A=0} ; const e: E = G.A` | `Type 'G.A' is not assignable to type 'E'` |
| `const enum C { X = 1 } ; C[1]` | `A const enum member can only be accessed using a string literal` |
| `const enum C { X = 1 } ; const c = C` | `'const' enums can only be used in property or index access expressions ...` |
| `enum B { A = "x", B }` | `Enum member must have initializer` |
| `enum Q { A = 1 << 2, B = A \| 1, C = 1 + 2 * 3 }` | `4`, `5`, `7` - constant folding over earlier members |

The decisive pair is rows 3, 5, 6 and 7: a union-of-constants model accepts `G.A` (wrong) while an opaque nominal model rejects `0` (also wrong). Only the composition - value-set membership for numeric literals, plus declaration identity for enum members, plus a blanket refusal for strings - satisfies all four.

## What the reference solution does

The declaration is processed in the hoisting stage rather than with the statements, because the
annotations of the declarations after it are resolved in that same stage and one of them can name a
member. Each member gets a nominal type (`Type::AliasTo` over the constant, named `E.A`, which is
what makes it print as `E.A`), the declaration's alias is updated to the union of those, and the
value is an object holding the members under their names plus, for numeric ones, under their value.
The member and declaration types are kept in an `EnumRegistry` on `TypeStore` that deliberately
serialises to nothing, because `checker/definitions/internal.ts.d.bin` is a committed binary of a
serialised `TypeStore` and adding a real field to it breaks every startup.

Assignability is intercepted at the top of `type_is_subtype_with_generics`, before the eager alias
unwrapping, since a member is an alias over its constant and would otherwise be compared by value.

Files: `checker/src/features/enums.rs` (new), `synthesis/{hoisting, statements_and_declarations,
expressions, type_annotations}.rs`, `types/{store, subtyping, printing, properties/assignment}.rs`,
`features/mod.rs`, `diagnostics.rs`, `lib.rs`, `events/application.rs`, and one parser fix so
`export const enum` and `declare enum` parse.

## Traps

1. Counting up follows the previous member's VALUE, not its position. The base implementation
   numbers by index, so the natural rewrite keeps `enumerate()` and gets every declaration with an
   explicit value wrong from the next member on.
2. Only numeric members are reachable by their value. The emitted-JavaScript mental model adds both
   directions uniformly, which makes a string member answer to its own text.
3. Nominal identity against value membership. A union-of-constants model accepts another
   declaration's member; an opaque nominal model rejects a plain `0`. Only the composition of
   "value is one of the members" for numbers and "same declaration" for members satisfies both, and
   strings inverts it again: the literal that a member holds is still not assignable.
4. A declaration where a member has no value, or which is empty, stands for numbers in general.
   This interacts with trap 3: the same code path decides both.
5. `const enum` shares the object-building path with everything else. Building the object and then
   hiding it leaves index access resolving; the declaration has to carry no value at all, which is
   also why reading it anywhere but a property access is an error.
6. A later declaration adds members but restarts counting at zero, so merging by appending to the
   member list and carrying on counting gets the first member of the second block wrong.

Traps 1, 2 and 3 are interdependent: the reverse entries need the values from trap 1 and the
assignable set needs both. Trap 6 rides trap 1's counter and trap 5 rides trap 2's object.

## Validation

| Check | Result |
| --- | --- |
| `human-effective` LOC (Counter 2) | 491 across 16 files (raw 790) |
| new tests | 193, all failing on base, all passing with the solution |
| base mode | 61 of the repository's own cases, green on both trees |
| offline, non-root, both apply orders, 3x determinism | all clean (see eval-results.md) |
| tsc 5.6.3 conformance | every pinned behaviour derived from it; remaining divergences are pre-existing ezno gaps and are not tested |

## Batch 1 read (0/3, de-trapped)

All three runs failed on the same unstated requirement: a member type being assignable to the
literal value it holds. 76 shared failures out of ~77. The description named the nominal half of the
member-type rule but not the value half, so every agent built exactly what was written and then
could not satisfy `E.A satisfies 1`. Fixed by naming it in the description; no test or solution
change. See eval-results.md for the per-run table and the mechanical classification.

## Difficulty read (before the batch)

The base implementation IS the naive one for the first trap (members numbered from their position),
and it fails all 89 tests. The risk is not that an agent writes nothing, it is that a thorough agent
writes all of it: TypeScript's enum semantics are recallable, so the difficulty has to live in the
integration - hoisting order (annotations of later declarations resolve in the same stage that has
to know the members), the serialised `TypeStore` that cannot take a new field, the eager alias
unwrapping in subtyping that has to be intercepted before it compares members by value, and the
shared object-building path that `const enum` must not use. Predicted 10-30%.

## Assumptions logged

- Autonomous one-shot mode; no pause at the design gate.
- Tests are Rust integration tests in the checker crate using the existing `check_project` entry point, so they compile on base and fail on assertions (no build-failure synthesis needed).
- Diagnostic wording for the four new errors is invented, therefore it is stated verbatim in meta.md; everything else reuses ezno's existing messages.
