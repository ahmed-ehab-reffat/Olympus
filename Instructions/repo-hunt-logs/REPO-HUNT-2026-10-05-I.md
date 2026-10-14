# REPO-HUNT-2026-10-05-I (hunter #57, CONSECUTIVE_MISSES=3)

Worker: olympus-hunter (unattended). Result: **CANDIDATE bufbuild/protobuf-es, `.proto` source printer.**

Scratch: `worktrees/_hunt/s_1005h57/` (seeder script, written spike patch). Clone: `worktrees/protobuf-es-h57/`
at c3a71a86 (16M, no node_modules, no build output; the spike sits there uncommitted).

## Standing inputs and defaults taken
- **Rules changed today (user decision 2026-10-05), applied as written:**
  - a LEDGER row or earlier problem excludes only its own lane;
  - only written verdicts block a repo, and lane verdicts expire after 60 days;
  - Requirement 7 kills only when a failing test workflow touches the lane;
  - the star margin is ~505;
  - the return bar is 220 human-eff, written or spiked;
  - Stage 6 Q3 is waived above ~300 when the wall is internal to the repo;
  - the per-repo count is reported, never gated.
- **Not relaxed:** the roadmap-magnet rule; the AI-sweep, velocity and signature-account rules; licence, language, activity, exclusivity; the 500-star floor.
- **Softening (misses 3):** the 2026-09-09-B rules apply. No star or issue window was used, because the candidate came out of the proven pool.
- **Requirement 0 (platform picker):** OWED, since the hunter cannot check it.
- **Excluded:**
  - in flight: ray-optics module inlining (SLICING);
  - HANDOFF: gonum/plot, commafeed, aptly publish history;
  - dead today: teavm fact reuse, pyOCD deferred writes, aerich squash, sqlalchemy-continuum squash.
- **Disk:** `/` was at 7.4-7.5G free, under the 8G build gate. Nothing was built, and no npm install was run.

## First task: `worktrees/_hunt/judged.tsv` seeded
- **Seeder:** `s_1005h57/seed_judged_h57.py`. Re-run it to rebuild the file. Rows are `slug lane scope reason date`.
- **Rows from SATURATED-REPOS A0/A/C/D/E** are `scope=repo`. The A "platform reuse warnings" table is excluded on purpose, because sfepy is still eligible.
- **`lic_out.txt` COPYLEFT rows** are `scope=flag`, not `repo`. That file is a heuristic: it flags CLI11, ulikunitz/xz, yt and patsy, which carry permissive licences. A flag never blocks; the screen re-reads LICENSE.
- **Corpus rows** (approved-problems/, problems/, rejected/, LEDGER) are `scope=lane`, one per problem slug.
- **Hunt-log rows:**
  - A line counts only if it carries a verdict word and names a known slug (from the index, the corpus or a github URL).
  - The row is `scope=repo` only when the line gives a repo-level reason: copyleft licence, RECENCY-DEAD/corpse, "0 commits in 12 months", reserved, plain-C language.
  - Everything else is `scope=lane` with the log date, so it expires after 60 days.
- **Result:**
  - 716 rows: 36 repo, 567 lane, 113 flag.
  - The repo rows cover 33 slugs: risor, sqlglot, opa, goja, cue, rhai, scriggo, mtail, roto, truck, the C-section corpses, and the hunt-log licence/corpse kills (pubgrub MPL, obspy LGPL, synthea vendored LGPL, yapf, avsc, Bytecoder, iced, stateright, dragonboat, tremor, ...).
- **What changes for sweeps:**
  - The skill's dead-list awk (`$3=="repo"`) now yields 33 slugs instead of the 74.6k-slug mention list.
  - Hunt #57 appended 3 verdict rows (below).

## Stage 0-bis: proven pool, the protobuf-es printer lead
The orchestrator named bufbuild/protobuf-es as a lead. Under today's waiver, its `.proto` source printer was killed only by Stage 6 Q3.

### Mechanical (Stage 1)
| Check | Result |
|---|---|
| Stars / licence | ★1668, Apache-2.0 |
| Language | TypeScript, primary |
| Activity | 188 commits in 12 months (timostamm 50, ajeetdsouza 26, dependabot 86); last commit 2026-10-02 |
| Requirement 7 | `ci`, `bun` and `deno` all succeed on main 2026-10-02. The test workflow is `ci` (node 22/24/26 x bigint/fallback, conformance, typescript-compat) |
| AI marks / trailers | 0 / 0 |
| Signature hits | 0. PR authors in the last 40 are dependabot, timostamm, anuraaga, ajeetdsouza and three one-offs |
| Open PRs | 12, each enumerated with its files: 7 dependabot, plus TS6 fixes, sizeDelimitedDecodeStream, the JSON finite-float option, buf.validate.oneof, registry type inference. None touches protoplugin or any printer |
| Our submission count | 1 (approved-problems/protobuf-es-serialization). Reported as a warning only |
| Docker | Pattern B, `olympus-base-typescript`. The accepted protobuf-es-serialization Dockerfile already solves the protoc + test-proto-include warm-up (`npm run build --workspace upstream-protobuf`) |

### Dedup, magnet and exclusivity (Stage 2, 2b, 2c, 2d)
- **Self-collision:** none.
  - Our accepted task is SerializationError + Path across the codecs (`from-/to-binary`, `-json`, `txtpb`, `merge`, `reflect/path.ts`, `size-delimited`).
  - The printer is a new module in `packages/protoplugin/src/`. It shares no file and no capability with that task.
- **Exclusivity:**
  - PR searches returned nothing relevant: "proto source", "print descriptor", "source file from descriptor", "protoprint", "printer", "to proto".
  - No open PR touches the lane.
  - `git log` on protoplugin/src since January holds only plugin-option and import work: map_imports, import_extension, elide_plugin_version, exactOptionalPropertyTypes, protobuf v34.
- **Magnet:**
  - #440 "Message#toProto" was CLOSED in 2023 by the requester.
  - In that thread maintainer timostamm wrote that reconstruction "is possible but not trivial". He named the hard parts: element order, custom options ("given in the protobuf text format, and I don't believe a JS implementation exists"), and option formatting. He pointed at Go's protoprint.
  - That is not a decline, not a roadmap issue and not a long-open uncommented ask. It is a difficulty signal.
  - The text-format blocker he cites has since been removed in the repo itself: txtpb landed 2026-06-26 (#1450).
- **Nameability:**
  - "print descriptors back to .proto" is outsider-nameable. Under 2026-09-09-B that is MEDIUM: mitigate it, do not reject on it.
  - The user ruling of 2026-10-05 names this exact lane as the example that qualifies for the Q3 waiver.
- **Removal records:** none. The repo never shipped a printer.
- **Sibling-library check (the main residual risk):**
  - protobufjs `cli/targets/proto.js` prints proto2/proto3 from protobufjs reflection: groups, reserved, extend consolidation, field options.
  - It has NO editions support (it skips `features`) and no SourceCodeInfo comments.
  - jhump/protoreflect `protoprint` is Go. monstrs-lab/protobuf-modules `descriptor-to-proto` is ★0 and protobufjs-based.
  - So the proto2/proto3 skeleton has a public JS crib on a different data model. The lane must take its traps and its test weight from editions, descriptor encodings, registry-decoded options and the repo's inherited helper, never from the proto2/proto3 skeleton. The builder should read `proto.js` before scoping the tests.

### Lane: `getProtoSource(file: DescFile, options?)`
The contract is a round trip: compiling the printed text with the repo's own protoc helper yields the same FileDescriptorProto, ignoring source info. Comments from SourceCodeInfo are printed in place.

**Missing machinery.** The repo has no source printer at all. What exists:
- `getDeclarationString` covers one field line, for JSDoc only;
- `getComments` / `getFeatureOptionStrings`;
- `txtpb.toText` for message values;
- the registry, for extension lookup.

**Written spike (mandatory measure):**
- File: `worktrees/_hunt/s_1005h57/sketch_protobuf-es_proto-printer_h57.patch`. It is leanest-correct, unrun and untyped-checked.
- Measured with `effective_loc_check.py`: **420 human-effective, raw 598, 2 files** (`proto-source.ts` 418 + an index export).
- Padding-floor reads 15. That is an artefact of the hook's bracket-depth collapse on code inside a TS class body; it is not breadth. The patch has no registry rows beyond a 9-entry options-schema table.
- The lane adds a new module, so the spike was not mandatory. It was written anyway because #56 had priced this lane on paper at ~350 (leanest ~200).
- What the spike covers:
  - syntax/edition, package, imports (public/weak), `import option` (2024);
  - file/message/field/oneof/enum/value/service/method/extension-range options through ONE options kernel: built-in fields by reflection, `features.*` as nested paths including custom feature extensions (`features.(pb.cpp).x`), custom options decoded from unknown fields through the registry, message values through `txtpb`;
  - messages with members in declaration order (synthetic oneofs never print), proto2 groups (field and extension, the nested type suppressed in the right scope), map fields;
  - nested enums/messages and `extend` blocks grouped by extendee;
  - extension ranges, reserved ranges (exclusive for messages, inclusive for enums, `max`), reserved names (quoted up to proto3, identifiers in editions);
  - `export`/`local` visibility (2024);
  - label keywords by edition, defaults (string escaping, bytes kept C-escaped, `inf`/`nan`), `json_name` only when it differs from `protoCamelCase`;
  - fully-qualified type names with a leading dot, streaming RPCs, and leading/trailing/detached comments.

**Trap thesis (all repo-internal, to be confirmed on base at slice):**
- **T1, group vs delimited.**
  - A proto2 group prints as `group Name = n { ... }` and its nested type must be suppressed in whichever scope declares it: message, file-level `extend`, nested `extend`, or oneof.
  - In editions, a DELIMITED field must never print as a group, and the registry treats `type == TYPE_GROUP` as delimited in every edition (`registry.ts:1287`).
  - The naive "TYPE_GROUP means group syntax" fix breaks editions, and per-message suppression double-prints file-level group extensions.
  - Interdependent with T3. To verify at slice: does protoc write TYPE_GROUP or TYPE_MESSAGE for an editions DELIMITED field? Either way the oracle catches it.
- **T2, one options kernel feeding 9 element kinds.**
  - Custom options exist only as unknown fields on the `*Options` message, so they need the registry. Message-valued options need txtpb aggregates.
  - Repeated options become repeated statements. Features become nested paths, including extension features.
  - The compact form (`[...]`) and the statement form must both come out of the same kernel.
  - A fix made for one element kind regresses the others unless it lives in the kernel.
- **T3, the edition axis.** It crosses fields (required/optional keywords, LEGACY_REQUIRED is LABEL_REQUIRED in the descriptor), reserved names, groups, `import option` and visibility keywords. This is an F-10 cross-product of edition x element kind.
- **T4, range conventions.** Message reserved and extension ranges are end-exclusive; enum reserved ranges are inclusive; `max` differs per kind.
- **T5, inherited helper (F-39, plus the F-12 exported-helper variant).**
  - `getDeclarationString` is the obvious thing to reuse. It is pinned by p2p tests (`protoplugin-test/src/source-code-info.test.ts:131-220`, e.g. `"map<int32, foo.M> int32_msg_field = 10"`) and it feeds the JSDoc of every generated file.
  - It prints type names without the leading dot, escapes only the first `"` of a string default (`replace('"', '\\"')`, `source-code-info.ts`), and prints groups as message fields.
  - Reusing it breaks the round trip; "fixing" it breaks the pinned tests and the generated JSDoc.
- **T6, name resolution.** A relative or package-relative type name can resolve to a shadowing nested scope. Only the leading-dot form is safe.

**Oracle and fairness.**
- The round trip through `compileFileDescriptorSet` / `compileFile` is a black-box contract that pins every cell without enumerating them. It already exists in `protobuf-test/src/helpers.ts` and `protoplugin-test/src/helpers.ts`.
- meta.md can state the contract in a few sentences ("compiling the result reproduces the descriptor, comments are kept, names are fully qualified"). Formatting can stay free, except for a small comments test.

### Stage 6 death-class guard on RANK 1
| Question | Answer |
|---|---|
| Q1 shared kernel feeding several surfaces | YES. The options kernel (T2) and the edition/group logic (T1/T3) feed every element kind |
| Q2 interdependent traps | YES. T1 x T3 share the edition axis (fixing groups breaks delimited), T2's kernel is shared by all elements, and T5 couples to every field line |
| Q3 standalone new file | WAIVED. The spike measures 420 (> ~300), and the wall is internal to the repo: the DescFile model, the registry's decoding of unknown-field options with txtpb aggregates, edition descriptor encodings (`registry.ts` delimited/required rules), and the pinned `getDeclarationString`. Per the user ruling this lane is the named example |
| Q4 / TOO-EASY guard 1 (uniform wrap) | No. Several mechanisms: options kernel, group scoping, edition axis, range conventions |
| Guard 2 (single-subsystem transform) | Risk accepted. It is a transform, but it spans protoplugin, protobuf (registry, reflect, txtpb) and the protoc oracle, with at least two hidden-integration walls (T2 registry decoding, T5 pinned helper) |
| Guard 3 (hardness needs an unstated rule) | No. The round-trip contract states everything |
| Guard 4 (port of a known spec) | MEDIUM risk. Models know proto2/proto3 syntax well, and protobufjs ships a proto2/3 printer. Mitigation: weight the tests toward editions 2023/2024 (features, delimited, `import option`, visibility, identifier reserved names), registry-decoded custom options and the T5 helper cells, where no public JS crib exists |
| Guard 5 (survives full spelling-out) | YES. Cross-subsystem integration and edition cross-product cells survive a full contract |

Verdict: **PASS with two recorded risks.** (a) Sibling-library crib for the proto2/proto3 skeleton. (b) Model familiarity with `.proto` syntax. Both are mitigated by where the tests put their weight.

## Cached index and fresh sweeps
- **Cached index:** not re-triaged. Hunts #50-#52 and #56 had read every engine row with 0 survivors, and the judged.tsv split (above) is the change that makes the next re-screen worth running.
- **Fresh sweeps:** one targeted check for fallbacks, looking for writer lanes where the repo parses a format but cannot write it.
  - cantools ARXML writer: DEAD. AUTOSAR is spec-named, and the sibling canmatrix ships an ARXML exporter (sibling-library rule). No tracker request exists.
  - Hunt-log grep for every lane killed by Stage 6 Q3 since 09-01: protobuf-es printer is the only one above 300. The rest sit at ~150-245 (lyon Hatcher ~200, cartopy Z 78, overpass-turbo, adguardhome-sync ~245, siliconcompiler criteria ~150-200, mwparserfromhell strip_code), so the waiver opens no other lane.

## Fallbacks (WEAK, spike before promoting)
- **bufbuild/protobuf-es, descriptor validator** (protoc-style linker checks over the registry). ~250 on paper. A standalone file, so Q3 applies under 300. Promote only after a written spike above 300.
- **LaurenzV/hayro, incremental-update revision history** in hayro-syntax (xref.rs/pdf.rs/page.rs, disjoint from the CLAIMED optional-content task). #54 sketched ~190 and expected 120-190. Below the bar unless a spike says otherwise.

## Verdict rows appended to `worktrees/_hunt/judged.tsv`
- bufbuild/protobuf-es `proto-source-printer`: lane, RANK 1 candidate.
- bufbuild/protobuf-es `descriptor-validator`: lane, WEAK.
- cantools/cantools `arxml-writer`: lane, dead (sibling canmatrix).

## OWED to the builder
- Requirement 0 picker check.
- Run the spike: `npm ci` plus the protoplugin tests. It was never compiled, and disk was under 8G.
- Confirm T1's editions encoding (TYPE_GROUP vs TYPE_MESSAGE for DELIMITED) and reproduce T2/T5 on base.
- Read protobufjs `cli/targets/proto.js` and keep the test weight off the cells it covers.
- Re-run the canonical-org PR-DIFF check at submit.
- Docker cold build (protoc + test-proto-include warm-up), uid 1000/0/4242.
