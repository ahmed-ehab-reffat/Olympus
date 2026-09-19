# DESIGN.md — planetiler-custommap-schema-composition

## 1. Title
Add schema composition to the configurable YAML profile loader

## 2. Shape classification
- Shape: O-Composite-add + S-A second entry point. A new composition stage in front of the existing
  pipeline (`SchemaConfig.load` -> args fixpoint `Contexts.buildRootContext` -> `ConfiguredProfile`
  -> `SchemaValidator`), reached from two entry points (`extends` inside a file, a `--schema` list
  on the command line). SHAPES.md § Pattern 11.
- Pass rate target: 30-45% (config-merge feature; levers are the joint args fixpoint, the position
  rule, declaring-file path resolution, diamond/cycle, accessor-vs-raw).
- Best agent: Orion. Dominant verdict: MISSED_REQUIREMENT (position rule, accessor defaults,
  examples path), REGRESSION (single-file behaviour, validator CLI output).
- Solver/our LOC ratio: ~1.2x.

## 3. Public API surface
- `SchemaConfig` gains `extends` (YAML key; record component `parents`, one string or a list of
  file paths, relative to the declaring file) and the composed result reports an empty `parents`.
- `SchemaConfig.load(Path)` composes automatically (follows `extends` recursively).
- `SchemaConfig.load(List<Path>)` composes several files: later files are layered over earlier ones
  exactly as if the last file extended the earlier ones in order.
- `SchemaConfig.files(Path)` -> `List<Path>` the files that contribute, in contribution order
  (every file once, parents before children, the root last).
- `SchemaConfig.load(String)` unchanged for content without `extends`; relative `extends` in
  string-loaded content raises `ParseException` (no file to resolve against); absolute paths work.
- `FeatureLayer` gains `remove` (boolean YAML key) to drop an inherited layer.
- `--schema` on `ConfiguredMapMain` accepts a comma-separated list; `SchemaValidator` composes and
  watches every contributing file.
- Errors are `com.onthegomap.planetiler.custommap.expression.ParseException` with a message that
  names the offending file (cycle, missing parent, removal of an unknown layer, removal entry with
  other fields).

## 4. Canonical output form (merge rules — all stated in meta.md)
- Contribution order: depth-first, parents in their listed order before the child; a file reached
  more than once contributes once, at its first position; a cycle is an error naming the file.
- Scalars (`schema_name`, `schema_description`, `attribution`, `version`, `is_overlay`): the last
  file that SETS the field wins; an unset field does not erase an inherited value (so a parent's
  attribution survives a child that says nothing, even though the accessor defaults it).
- `sources`: by id; a later definition with the same id replaces the earlier one entirely.
- `tag_mappings`: by key; later wins per key.
- `args`: by name. A later mapping definition overrides only the keys it gives (`default`,
  `description`, `type`), keeping the rest; a later bare value replaces the default only. All
  arguments are settled together after composition, so a default may reference an argument
  defined in another file.
- `layers`: by id. A same-id layer keeps the position of the earlier one; its `features` are
  appended after the inherited ones; `buffer` and `tile_post_process` are taken from the later
  layer when set. New ids are appended in order. `remove: true` deletes the inherited layer (and
  its position); removing an id that was not inherited is an error; a removal entry with any
  other field besides `id` is an error.
- `examples`: concatenated in contribution order; a file's `examples: <path>` resolves relative to
  that file; the composed schema carries the examples inline.
- `definitions`: not inherited (YAML anchors are file-local); the composed value is the root's own.
- Single file without `extends`: byte-identical behaviour to today (`SchemaYAMLLoadTest`, samples,
  `SchemaValidatorTest` guard it).

## 5. Blind-spot pre-empts
- Rule resolution: "settled together after composition" (joint fixpoint).
- Ordering: "keeps the position of the earlier one" / "new ids are appended".
- Falsy-on-unset: "an unset field does not erase an inherited value".
- Codebase-inferable (the one): the error type is the module's existing `ParseException`.

## 6. Description draft
meta.md, ~320 words, five paragraphs: ask + entry points; contribution order and errors; merge
rules by field; examples/definitions; unchanged single-file behaviour.

## 7. File footprint
| Action | Path | Raw | Meaningful | Reason |
|---|---|---|---|---|
| NEW | custommap/SchemaComposer.java | +190 | 140 | file graph, cycle detection, path resolution, examples inlining, merge rules |
| MODIFY | configschema/SchemaConfig.java | +40 | 28 | `parents`, `load(List)`, `files`, delegate to composer |
| MODIFY | configschema/FeatureLayer.java | +6 | 4 | `remove` |
| MODIFY | ConfiguredMapMain.java | +14 | 10 | `--schema` list |
| MODIFY | validator/SchemaValidator.java | +12 | 9 | watch every contributing file, examples already inline |
TOTAL measured (hook): 259 human-effective across 5 files (SchemaComposer 95, SchemaConfig 107,
FeatureLayer 20, ConfiguredMapMain 15, SchemaValidator 1) after adding the bundled-sample parent
lever (`SchemaComposer.Ref`: file-or-classpath identity, sibling resolution, shadowing). The first
spike without it measured 237.

## 8. Solution outline
- `SchemaComposer.files(root)` -> ordered unique list via DFS with an on-stack set (cycle error).
- `SchemaComposer.load(root)` -> for each file in order: `YAML.load` raw map -> `SchemaConfig`;
  fold with `merge(base, next, nextPath)`.
- `merge`: scalars (`pick(next.raw, base.raw)`), sources map, tag mappings, args
  (`mergeArg(baseDef, nextDef)`), layers (`mergeLayers(baseList, nextList)` with position keep /
  append / remove), examples (`inlineExamples(config, path)` then concat), definitions = next's.
- `SchemaConfig.load(List<Path>)` -> fold the same `merge` over each path's composed config.
- `ConfiguredMapMain`: `arguments.getList("schema", ...)`, resolve each (file or bundled sample).
- `SchemaValidator.validate(pathsToWatch)`: `pathsToWatch.addAll(SchemaConfig.files(schemaPath))`,
  keep the `examples` string branch for the single-file case.

## 9. Test file outline
Path: `planetiler-custommap/src/test/java/com/onthegomap/planetiler/custommap/SchemaCompositionTest_<hex>.java`
(JUnit 5, `@TempDir`, helper `write(name, yaml)` and `load(name)`).
Buckets: contribution order (single parent, chain, two parents, diamond once, self/mutual cycle,
missing parent, relative paths across directories, absolute path, string-loaded content);
scalars (set/unset per field incl. attribution and is_overlay accessor traps); sources replace;
tag mappings; args (mapping override keeps description/type, bare value, cross-file reference
settled via `Contexts.buildRootContext`, CLI override still wins); layers (position keep, features
append, buffer/post-process override, new ids appended, remove, remove unknown error, remove with
fields error, two parents same id order); examples (parent path relative to parent dir, embedded
child, composed validation passes/fails through `SchemaValidator.validate`); definitions not
inherited; `load(List)` equivalence with `extends`; single-file unchanged (`parents` empty, examples
string kept, `files` = [root]); end-to-end `ConfiguredProfile` feature emission from a composed
schema (a feature only matched by the parent's layer, one by the child's appended feature).
Target ~55 tests.

## 10. Forced kwargs
`SchemaConfig(..., @JsonProperty("extends") @JsonFormat(ACCEPT_SINGLE_VALUE_AS_ARRAY) List<String> parents)`;
`FeatureLayer(..., Boolean remove)`; `SchemaConfig.load(List<Path>)`; `SchemaConfig.files(Path)`.

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Accessor defaults leak: `attribution()`/`isOverlay()`/`args()` return defaults for unset fields, so "child wins" via accessors erases inherited values | F-3 | S3 | field read | 3 | records hide null behind accessors | "an unset field does not erase an inherited value" | `attribution_inherited_when_child_silent`, `overlay_flag_inherited` |
| 2 | Position rule: same-id layer keeps the earlier position, features appended | A8 | A8 | ordering | 5 | natural code concatenates or replaces | "keeps the position of the earlier one" | `same_id_layer_keeps_position_and_appends` |
| 3 | Joint args settle across files | F-22 | S2 | evaluation scope | 1, 4 | settling per file leaves parent defaults unable to see child args | "settled together after composition" | `parent_default_references_child_arg` |
| 4 | Arg definition merge: mapping overrides only given keys, bare value replaces default only | A8 | S2 | merge granularity | 3 | whole-entry replacement drops description/type | stated | `arg_override_keeps_description_and_type` |
| 5 | Diamond once + first position | F-25 | S1 | graph | 2 | naive DFS includes D twice, duplicating features | "contributes once, at its first position" | `diamond_parent_contributes_once` |
| 6 | Examples path relative to declaring file, inlined | F-9 | S4 | path resolution | — | resolving against the root or CWD | "resolves relative to that file" | `parent_examples_path_resolves_against_parent` |
| 7 | Single-file parity (F-20) | F-20 | S3 | sibling API | 6 | inlining examples or emptying definitions for single files changes validator CLI output | "byte-identical" | existing `SchemaValidatorTest`, `single_file_unchanged` |

## 11b. Cross-product matrix
| | override (same id) | remove | new id |
|---|---|---|---|
| one parent | position kept, features appended | dropped | appended |
| chain (A->B->C) | C's position, B then A features | dropped at any level; re-add later = new id at end | appended |
| two parents [P1,P2] | P1 position, P1 then P2 then child features | P2 may remove P1's layer | appended in P1, P2, child order |
| CLI list | identical to chain | identical | identical |
Every off-diagonal cell gets a test.

## 12. Tier + category
Olympus; feature-request ("Add ...").

## 13. Predicted pass rate
30-45% Orion. Wrong Logic ~15%.

## 14. Quality-gate checklist
- [x] Phase 1: architecture read (loader, fixpoint, profile, validator, CLI); test conventions cited (`ConfiguredFeatureTest`, `SchemaValidatorTest`)
- [x] Phase 2: `gh issue/pr list --search` extends|inherit|include|combine|import|multiple schema|merge profiles -> only #1148 (open, no PR, no design)
- [x] Scaffold: `approved-problems/customasm-derived-bank-layout` (F-22 joint settle), `datafixerupper-derived-recursion` (Java, F-24/F-25)
- [x] Title verb-led; API listed; canonical merge rules; ≤1 codebase-inferable
- [x] Footprint sketched; LOC spike owed
- [x] Traps on different axes, 1-3-4 and 2-5 interdependent; § 11b filled
- [x] F-20 audit done (single-file parity guarded by existing tests + new); F-21 n/a; F-24: missing parent file / unknown removal are hard errors (stated); F-25 diamond/cycle
- [x] Category feature-request

## Why this is not a duplicate
No workspace problem touches planetiler or YAML profile composition; tippecanoe (in flight) is a
different repo/language and a tile-size capability. Dedup sentence needs planetiler nouns
(`SchemaConfig`, sources, `tag_mappings`, args settling, layers, examples, `SchemaValidator`).

## Predicted iteration cycles: 2

## R1 revision (2026-09-16) — review-driven changes

Platform pre-batch review returned FAIL on Test Quality (9 over-specified assertions) and FAIL on
Solution Quality (4 semantic bugs + missing docs). No agent batch had run, so the solver-visible
surface (meta.md, Dockerfile, base commit) was still free to edit.

Solution changes:
- `load(List<Path>)` now builds ONE depth-first contribution list across all roots with a shared
  parse cache, then folds it once. The old code folded each root independently and merged the
  already-folded results, which duplicated a shared parent's features and lost a removal made by a
  later root.
- A one-file list delegates to `load(Path)`, so a no-`extends` file in a singleton list keeps its
  `examples` string untouched.
- `remove` is validated against the ids inherited BEFORE the current file is applied: a file whose
  parents contribute no layers, and a file that adds an id and then removes it, are both errors.
  The fold now starts from an empty `SchemaConfig`, so the first contributor goes through the same
  merge path instead of being adopted whole.
- `examples` resolution is a separate `Ref.examples` resolver with no bundled-sample fallback: a
  disk schema resolves only its physical sibling, a bundled schema only its bundled sibling.
- `planetiler-custommap/README.md` and `planetiler.schema.json` document `extends` and layer
  `remove`, so the published configuration contract matches the runtime.

Test changes (fairness, per the review's 9 flagged assertions):
- Dropped: literal `cycle` wording, source/args map iteration order (3 assertions, now membership),
  the `remove()` accessor false-vs-null representation, and the unstated empty-list contract.
- Kept but now stated in meta.md: cycle message names every file in the cycle, invalid-remove
  errors are a `ParseException` naming the layer, `files` returns absolute normalized paths, list
  names resolve like `extends` names, a one-file list loads like that file.
- Added coverage the review called out as missing: the `--schema` comma-separated list end to end
  through `ConfiguredMapMain` (Monaco), the validator watch set over a composed graph with a
  bundled parent, and inheritance of all five scalars through two silent files.
- Added regression tests for each solution bug above (shared parent contributes once through the
  list overload, removal by a later root survives, singleton list keeps the examples reference,
  examples never fall back to a bundled sample, remove with no inherited layers, remove of a
  same-file addition).
- The test class moved to `com.onthegomap.planetiler.custommap.validator` so it can construct
  `SchemaValidator` and read `validateFromCli().paths()`. 70 tests total (was 62).

Measured after the revision: 282 human-effective LOC across 7 files, 70 new tests, base suite 431
pass.

### R1b addendum

A second-opinion trace audit removed five more unpinned assertions (the `parents()` accessor name
and representation, whole-record `SchemaConfig` equality, `remove: false` with another field, the
string-loaded bundled-name precedence, and the earlier-bare-arg promotion), each either dropped or
pinned by a meta.md rewording. Added tests for unset `tile_post_process` inheritance and a
three-file cycle. 71 tests; meta.md 485 body words.

### R2 addendum

Bundled-sample resolution no longer depends on `Path.toString()` keeping `/` separators, which broke
the `/samples/` prefixed form on Windows for the CLI, the list overload and string-loaded absolute
sample paths. Added the prefixed-path regression test plus two discrimination tests the reviewer
asked for (`tile_post_process` replacement versus deep merge, `remove` combined with `features`
rather than only `buffer`). 74 tests. meta.md reflowed to unwrapped lines and trimmed to 458 words.

### R3 addendum

Auto Review found the composition core sound but the integration edges incomplete. `SchemaValidator`
now parses `--schema` as a comma list and composes through the list overload, and examples-file
provenance survives inlining via a new `SchemaConfig.exampleFiles(Path)` so watch mode still tracks
external spec files. Tests gained the missing `SchemaConfig.files` canonicalization case: a nested
`../` graph with a second alias of the same parent, asserting exact normalized paths and single
contribution. 77 tests.

### R4 addendum

The validator now loads through `SchemaConfig.loadWithInlineExamples`, so a standalone bundled schema
resolves its examples from the bundle rather than the working directory. The CLI integration test
checks presence of both road classes across all tiles instead of per-zoom counts. Added list
missing-entry and remove-with-post-process coverage. 80 tests.

### R5 addendum

A relative parent in a string-loaded schema now resolves only as a bundled resource, so a working-directory file cannot shadow it. 81 tests.

### R6 addendum

Tests only: multi-root validator watch coverage, bundled alias dedup in one list, and a harness that fails when the JUnit report cannot be written. 83 tests.
