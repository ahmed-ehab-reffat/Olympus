# DESIGN.md - protobuf-es-proto-source-printer

Factory SLICE, 2026-10-06. Hunt #57 RANK 1 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-10-05-I.md`).
Repo bufbuild/protobuf-es (1668 stars, Apache-2.0, TypeScript), base `c3a71a86` (= origin/main on
2026-10-06, zero commits after base). Second lane on this repo; disjoint from
`approved-problems/protobuf-es-serialization` (codecs + SerializationError, packages/protobuf only).

## Phase 1 - repo understanding

- **Architecture.** `@bufbuild/protobuf` is the runtime: descriptor model (`DescFile`/`DescMessage`/...
  built by `createFileRegistry` in `registry.ts` from `FileDescriptorProto`s), reflection
  (`reflect/`), codecs (binary/JSON/`txtpb`), extensions (`getExtension` decodes unknown fields).
  `@bufbuild/protoplugin` is the plugin framework on top: schema, generated-file printer, import
  tracking, names, JSDoc built from `source-code-info.ts` (`getComments`, `getDeclarationString`).
  `upstream-protobuf` wraps a pinned protoc (36.2) and the upstream test protos; the test suites
  compile inline `.proto` text through it.
- **Subsystems.** (1) descriptor registry + edition feature resolution (`protobuf/src/registry.ts`),
  (2) reflection + extensions (`reflect/`, `extensions.ts`), (3) text format (`txtpb/`),
  (4) protoplugin source-info + JSDoc (`source-code-info.ts`, `jsdoc.ts`), (5) protoplugin
  generation/import machinery (`generated-file.ts`, `names.ts`, `import-*.ts`).
- **High-entanglement zones.** `registry.ts` (every edition rule: delimited, legacy required, map
  entries), `source-code-info.ts` (comment paths + the declaration string pinned by tests and used
  in every generated JSDoc), the options messages (`*Options` carry custom options only as
  `$unknown`, decodable only through a registry).
- **Tests.** `node:test` via `tsx --test`, files `packages/*-test/src/*.test.ts`. Template:
  `packages/protoplugin-test/src/source-code-info.test.ts` (compiles inline proto with protoc,
  asserts on `getComments`).

## Phase 2 - existing PR / publicly solved

- Canonical org `bufbuild/protobuf-es` (no move). PR searches (all states): "proto source",
  "print proto", "protoprint", "printer", "to proto", "descriptor to proto", "getProtoSource",
  "proto file from descriptor", "toProto", "reconstruct", "source file", "textual": no printer,
  no PR touching `protoplugin/src` for this capability. Issues: #440 (Message#toProto, closed by the
  requester 2023; timostamm: "possible, but not trivial", names element order, custom options in
  text format, formatting), #1319 (source info in embedded descriptors, unrelated).
- `git log c3a71a86..origin/main`: empty.
- No existing capability: `grep -rn "getProtoSource\|DebugString\|protoprint" packages` = none.
- **Cross-repo prior art (recorded risk, not a gate I can settle locally):** protobufjs
  `cli/targets/proto.js` prints proto2/proto3 from protobufjs reflection (no editions, skips
  `features`, no comments); jhump/protoreflect `protoprint` (Go) and protobuf C++
  `FileDescriptor::DebugString()` print descriptors to source. TOO-EASY's "sibling-ecosystem tool"
  row (rspirv vs SPIRV-Tools) killed a cross-language case at the scope gate. Mitigation: the test
  weight sits on the round trip through the repo's own descriptor model (unknown-field custom
  options via the repo registry + txtpb, editions 2023/2024 cells, nested-type order, comment
  attribution), none of which proto.js covers. The platform precheck on this slice is the
  instrument that decides it.

## 1. Title

Add a Protobuf source printer to protoplugin

## 2. Shape

O-Pipeline-hard-ish new module: one new file (`packages/protoplugin/src/proto-source.ts`) plus the
export in `index.ts`, integrating registry, reflect, extensions, txtpb and source-code-info. Dominant
verdict predicted: MISSED_REQUIREMENT on composition cells (order, comments, editions).

## 3. Public API

- `getProtoSource(file: DescFile, options?: ProtoSourceOptions): string` (exported from
  `@bufbuild/protoplugin`).
- `ProtoSourceOptions { registry?: Registry }` (type export).

## 4. Canonical output form

Free formatting. The only pinned observables are (a) recompiling the text with protoc yields the
same `FileDescriptorProto` (compared semantically through `toJson` with the compiled registry, source
code info cleared), and (b) `getComments` on every element of the recompiled file matches the
original. No string assertions on the printed text.

## 5. Blind-spot pre-empts

"only the source code info is allowed to differ" (scope of equality); "every element that
`getComments` can describe" (comment scope); "the input files only ever use `//` comments" (domain
cap: block comments would need exact whitespace reproduction); "you can assume every option in the
file can be found" (domain cap for unresolvable unknown fields).

## 6. Description draft

See meta.md (197 words incl. title).

## 7. File footprint

| Action | Path | Raw | Human-eff (hook) |
|---|---|---|---|
| NEW | packages/protoplugin/src/proto-source.ts | 643 | 457 |
| MODIFY | packages/protoplugin/src/index.ts | 2 | 2 |
| TOTAL | 2 files | 645 | 459 |

Slice reference already at 459 human-effective (floor 200). FINISH adds no padding; extra cells are
tests.

## 8. Solution outline

- `fileRegistry(file)` - registry over the file + transitive deps (keyed by `proto.name`; the
  hunter's spike keyed by `DescFile.name`, which drops `.proto`, and crashed on every import).
- `SourcePrinter.declare` - one comment kernel for every element kind: blank line before detached
  blocks, leading block directly above, trailing block on the following lines plus a blank line
  (protoc attaches a comment that starts on the next line and is followed by a blank line to the
  previous token; the `{` of a message is that token for its trailing comment).
- `printScope` - merges three ordered streams (fields/oneofs, extensions, nested_type list) so map
  entries and group types land at their original nested_type index; extensions print as runs of
  consecutive same-extendee blocks.
- `optionList` - one options kernel for 9 option messages: built-in fields by reflection,
  `features.*` as nested paths incl. extension features `features.(pb.cpp).string_type`, custom
  options from `$unknown` through `registry.getExtensionFor` + `getExtension`, message values via
  `txtpb.toText`, bytes octal-escaped, repeated values as repeated statements.
- Labels by edition from the RAW descriptor (never `DescField.presence`/`delimitedEncoding`), group
  syntax only for proto2 `TYPE_GROUP`, reserved names quoted up to proto3 and bare in editions,
  message ranges end-exclusive vs enum ranges inclusive, `max` per kind, defaults (string escaped,
  bytes kept C-escaped, `inf`/`nan`), `json_name` only when it differs from `protoCamelCase`,
  type names with the leading dot.

## 9. Test outline

One file `packages/protoplugin-test/src/proto-source.8e6d1f.test.ts`, helpers inside (compile set
with source info + options, round trip, descriptor JSON, comment comparison). The import uses a
namespace import so base fails per test (TypeError), not as a link error. Slice: 9 tests (proto3
basics, proto2 groups/defaults/required/extensions, editions 2023 delimited + legacy required,
edition 2024 visibility + reserved identifiers + `import option` feature extension, custom options on
every element kind, nested-type order around map fields, shadowed type names, string defaults with
two quotes + backslash, comments on messages/fields/enums/values).

FINISH cells (F-10): group extension at file scope interleaved with top-level messages; group in a
oneof; group extension inside a message scope next to untied nested messages; interleaved extendees
(`extend A; extend B; extend A`); comments x {oneof, service, rpc with options, extension, group
field, detached before the first member after `{`, multi-line trailing}; custom options x
{extension range, repeated message-valued, nested aggregate with extension inside, feature
extension on enum/field in 2024}; edition 2023 x {proto3 file features, closed enum}; enum
reserved `max` vs message reserved `max`; extension ranges with options in separate statements;
float/double option values; `json_name` explicit-but-default; weak/public imports; `option
(x).sub = ...` path form merged; registry argument override vs default; proto2 required in oneof
group; `map_entry` never printed; services with streaming + idempotency_level.

## 10. Forced shapes

Named import of `getProtoSource` from the package root; options object with `registry`. The meta
names both.

## 11. Trap matrix

| # | Trap | F-id | Class | Axis | Interdependent | Reproduced on slice |
|---|---|---|---|---|---|---|
| T1 | nested_type order: map entries and group types are tied to their field's position; printing fields then nested messages reorders `nested_type` | F-10 (composition) / new candidate | S2 | declaration order | T3 (groups) | hunter spike fails the order test |
| T2 | comment attribution: trailing comment placed on the next line is taken as the NEXT element's leading; detached block after a token without a blank line becomes the previous trailing; message trailing lives after `{` | new candidate (P3 self-test shadow) | S2 | comment placement | T1 (blank-line formatting of every declaration) | spike loses M's trailing comment |
| T3 | edition axis: `DescField.delimitedEncoding` / resolved presence say "group"/"required" in editions, but editions source has neither keyword (protoc writes TYPE_MESSAGE + DELIMITED, LABEL_OPTIONAL + LEGACY_REQUIRED) | F-12-adjacent (repo helper view) | A8 | edition x label | T1 | mutant M5 (delimitedEncoding) fails editions test |
| T4 | options kernel: custom options only as `$unknown`; option-only imports (`import option`) are not in `DescFile.dependencies`; bytes values must be escaped bytes, not decoded text | F-9 (registry drop) | S4 | option decoding | all element kinds share the kernel | spike: `Unable to resolve` on every import; M1/M6 mutants fail |
| T5 | `getDeclarationString` reuse: escapes only the first `"`, no leading dot, prints a group as a message field; fixing it breaks pinned tests in `source-code-info.test.ts` and every generated JSDoc | F-39 + F-12 exported | S3 | inherited helper | T6 | base probe: `default = "say \"hi" and "bye""`, `a.b.Target`, `a.b.Holder.G g = 3` |
| T6 | name shadowing: a type name without the leading dot resolves to a nested scope | - | A9 | name resolution | T5 | no-leading-dot mutant fails the shadow test |

## 11b. Cross-product matrix (F-10)

Edition {proto2, proto3, 2023, 2024} x element kind {message, field, group, oneof, enum, value,
extension, range, service, method} for options and comments; scope {file, message} x tied kind
{map entry, group field, group extension}. Off-diagonal cells listed in section 9 FINISH.

## 12. Tier + category

Olympus, feature-request ("Add").

## 13. Predicted pass rate

20-35%. Agents can self-test with the repo's protoc helper, so isolated cells get fixed; the band
rests on cells their own probes skip (order around map/group ties, comment attribution, option-only
imports, aggregate options with extensions inside).

## 14. Quality gates (slice)

- [x] Phase 1 5/5, Phase 2 clean (commands above)
- [x] PICK-FILTER 1 (no capability on base, 9/9 new tests fail with TypeError), 5 (no commit/PR in
      the lane), 6 (traps reproduced in the built image), 7b (canonical-org PR-DIFF clean), 8
      (behaviour defined by protoc; maintainer called it possible, never declined)
- [x] SIX-CHECK 1-6 (6: no printer on main)
- [x] Docker clean room uid 1000 / 0 / 4242, `--network none`
- [ ] FINISH: flakiness 3x, mutation sweep, FP self-check, comments audit, F-10 cells

Why not a duplicate: closest approved same-repo pick is protobuf-es-serialization (codec errors +
paths in packages/protobuf); this lane adds a new protoplugin module and shares no file or
capability. Predicted iteration cycles: 2.
