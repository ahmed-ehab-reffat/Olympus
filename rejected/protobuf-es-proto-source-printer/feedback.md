NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

# feedback.md - protobuf-es-proto-source-printer

## Status (2026-10-06, factory MODE=SLICE)

SLICE-READY. Core slice built and validated; no differentiating scope yet (Step 4b gate).

- Lane: `getProtoSource(file: DescFile, options?)` in a new `packages/protoplugin/src/proto-source.ts`,
  exported from `@bufbuild/protoplugin`. Contract = round trip: compiling the printed text with protoc
  reproduces the `FileDescriptorProto` (source info aside), comments stay on their elements, custom
  options decoded through `options.registry` or the file and its imports.
- Base `c3a71a8679b06b07a4ebb3bd6f5b02d68759a179` (= origin/main today, 0 commits after).
- Reference: 459 human-effective (hook), 645 raw, 2 files. Above the 200 floor without any FINISH
  scope.
- Tests (slice): 9 in `packages/protoplugin-test/src/proto-source.8e6d1f.test.ts`. All 9 fail on base
  (per-test TypeError, real test ids in the JUnit), all 9 pass with the solution.
- test.sh: rebuilds `@bufbuild/protobuf` and `@bufbuild/protoplugin` in both modes (the plugin test
  package imports protoplugin's `dist`), base = every `protobuf-test` + `protoplugin-test` test file
  except the new one (3405 testcases, 0 failures, 1 repo skip), new = the new file. JUnit fallback
  embeds the build log.

## Clean-room validation (built image, `--network none`, test.patch then solution.patch)

| uid | base no-sol | new no-sol | base sol | new sol |
|---|---|---|---|---|
| 1000:1000 | exit 0, 3405/0 fail | exit 1, 9/9 fail | exit 0, 3405/0 fail | exit 0, 9/0 fail |
| 0:0 | exit 0, 3405/0 | exit 1, 9/9 | exit 0, 3405/0 | exit 0, 9/0 |
| 4242:4242 | exit 0, 3405/0 | exit 1, 9/9 | exit 0, 3405/0 | exit 0, 9/0 |

(A first 4242 run read exit 1 everywhere; that was my harness: the bind-mounted output dir sat under a
0700 scratchpad parent. Rerun with a container-local output dir is the row above.)

Flakiness 3x not run yet (FINISH gate); base mode returned identical counts in all twelve base runs
across two images and three uids.

**Dockerfile / cold build.** The first draft copied the accepted protobuf-es-serialization Dockerfile
(final `USER root` + `RUN chmod -R a+rwX /app`). Cold `--no-cache` build: **980 s**, ~850 s of it the
overlayfs copy-up of node_modules in the separate chmod layer, over the 600 s environment-start limit
(L62). Moved the chmod into the uid-1000 build RUN (same layer that creates node_modules, so no
copy-up): **225 s** cold, clean room re-run on that image for uid 1000 / 0 / 4242, identical results.

## Trap reproduction on the slice (owed by the hunt)

- **T1 editions DELIMITED encoding:** protoc 36.2 writes an editions delimited field as
  `TYPE_MESSAGE` + `features.message_encoding = DELIMITED`, and a LEGACY_REQUIRED field as
  `LABEL_OPTIONAL` + the feature. So TYPE_GROUP only exists in proto2. The live trap is the resolved
  view: `DescField.delimitedEncoding` is true for that editions field, and a printer that keys group
  syntax on it fails the editions test (mutant M5).
- **Hunter spike run as-is: 4/9.** It type-checked, but (a) `findDep` matched `DescFile.name`, which
  has no `.proto` suffix, so every file with an import crashed in `createFileRegistry`; (b) printing
  fields before nested messages reorders `nested_type` when a map field sits between nested messages
  (protoc order A, MEntry, B); (c) trailing comments printed on the next line attach to the next
  element (message trailing comment lost); (d) `import option` feature extensions dropped.
- **T5 on base:** `getDeclarationString` prints `default = "say \"hi" and "bye""` (only the first
  quote escaped), `a.b.Target` without the leading dot, and a proto2 group as `optional a.b.Holder.G g`.
- Mutants on the reference: M1 (no custom-option decoding) fails 2 tests, M5 (group syntax from
  `delimitedEncoding`) fails the editions test, M6 (bytes option decoded as UTF-8) fails the custom
  options test, no-leading-dot fails the shadowing test.

## Gates run (scope-lock)

- PICK-FILTER 1 / 5 / 6 / 7b / 8: pass (DESIGN.md section 14).
- SIX-CHECK 1-6: clean. Canonical org unchanged, no PR or issue builds a printer, #440 is a
  requester-closed question with a maintainer "possible but not trivial", base..main empty, no
  printer on main.
- Exclusivity PR-DIFF: no PR touches the capability; nothing to diff.

## Recorded risks for the human (decide at precheck)

1. **Sibling-ecosystem prior art.** protobufjs `cli/targets/proto.js` (proto2/proto3, no editions, no
   comments), Go `protoprint`, and protobuf C++ `FileDescriptor::DebugString()` all print descriptors
   back to source. TOO-EASY "sibling-ecosystem tool" row killed rspirv at the scope gate across
   languages. I kept going because the user's 2026-10-05 ruling names this lane and the precheck is the
   only instrument that can rule on it; the test weight is on repo-model cells (unknown-field options
   through the protobuf-es registry, editions 2023/2024, nested-type order, comment attribution).
2. **Outsider-nameable feature** ("print descriptors back to .proto"): MEDIUM magnet per 09-09-B,
   mitigated by phrasing meta on the repo's own model. A rival submission would be visible only to
   the platform dedupe.
3. **Recogniser/post-pass class** (TOO-EASY): a printer is a standalone module over the public
   descriptor model. Q3 was waived for this lane by the user ruling; noted here so the precheck result
   is read against it.

## Conservative choices made unattended

- Comment domain capped to `//` comments in meta (block comments need exact whitespace
  reproduction, which is a formatting gamble, not a fair contract).
- `import option` files are not reachable from a `DescFile`, so the meta makes `options.registry`
  the documented way to supply them and promises only "every option can be found that way"; the
  2024 test passes the compiled registry.
- Equality is semantic (`toJson` with the compiled registry, source info cleared), not byte equality,
  so the order protoc stores unknown option fields in is not a hidden requirement.
- failure-patterns.md was read at catalogue and laws level (sections 1 headers, 3, the F-ids the
  hunt named); the 2,200 lines of per-problem dossiers in section 2 were skimmed, not read line by line.

## Owed in FINISH

F-10 cells listed in DESIGN.md section 9, flakiness 3x, mutation / feature-stub / assertion-flip
sweep, `::` and duplicate JUnit id check on the full base XML (no `::` seen in the slice runs), SIX-CHECK + exclusivity re-run before final patch generation.

## REJECTED 2026-10-12 at platform review: DERIVATIVE overlap Blocker (shelved to rejected/)

Verdict, verbatim: "Drop: an older protobuf-es task already delivers the same descriptor-to-.proto
printing engine; comments and registry selection do not make this a distinct core task." Overlap
`Blocker`: 373/559 discounted subject solution lines (66.7%) correspond to the older printer's core,
also 373/515 of its authored lines (72.4%). "The older corpus task already requires and implements the
main descriptor-to-source round-trip engine; added comment preservation and registry selection sit
around that engine."

The older task is another author's; nothing in this workspace (approved-problems/protobuf-es-serialization
is the error-reporting pick, unrelated). Every GitHub instrument was clean (no PR, #440 a question), so
the platform dedupe was the only place the rival lived. Risk 2 above ("outsider-nameable feature, a
rival submission would be visible only to the platform dedupe") is exactly what happened. Not
contestable: 66.7% / 72.4% on both sides, and the cited differentiators are the two bolt-ons.

No batch was spent under the 2026-10-09 gate (row was "reverted, not re-measured"). Salvage: none. The
T5 base bugs in `getDeclarationString` (quote escaping, missing leading dot, proto2 group printed as a
field) are a ~20-line fix inside the consumed lane. Reference + tests remain uncommitted in
worktrees/protobuf-es-h57 (16M) until reclaimed.
