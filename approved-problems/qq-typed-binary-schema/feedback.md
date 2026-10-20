# qq-typed-binary-schema - feedback

NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

## Status
- 2026-10-13: factory SLICE run started. Repo JFryy/qq (740 stars, MIT, Go). Base = main HEAD 321eba7b1db4f42f7bd351e020f8e0fae6b0c354 (2026-10-12; the only commit after the hunt base 0c67cdf touches codec/env only).

## Decisions taken without a human (factory run)
- Base moved from the hunt's 0c67cdf to current main 321eba7 (only codec/env changed in between; the hunt sketch applied cleanly).
- Root disk had 6.0G free (< the 8G build gate) for the whole run, /var/lib/docker 30G+. Decision: no local Go build at all; every compile and test ran inside Docker (writes land on /var/lib/docker). The clone itself is 5M.
- Issue #67 (maintainer roadmap, OPEN) names ONE sub-part of this lane: "avro converts through float64 internally ... integers above 2^53 lose precision". Schema inference over all records, nested types, nullability, mixed kinds and everything parquet are not in any issue. Classified PARTIAL tracker overlap, MEDIUM risk, proceed to the core slice; the platform precheck decides. If precheck returns a derivative/overlap Blocker naming #67-style avro precision work, shelve per the tracker-named law.
- No new public API: tests call only codec.Marshal/Unmarshal with AVRO/PARQUET, plus hamba ocf and arrow pqarrow (both in go.mod) to read the written schema. No compile-wipe risk.
- Superseded assertions in codec/parquet/parquet_test.go (string values "1", "30", "true", "95.5", ID "1"/"1000", and the "single object must error" half of TestInvalidInputTypes) are deleted in test.patch; typed versions live in the new test file. The rest of parquet_test.go stays in base mode unchanged.
- base mode excludes the new file with `go test -overlay` (no `-skip`: a gate once raised a false ERROR on it, see memory verify-gate-language-claims-with-compiler). tests/test.sh is not run (needs jq and bin/qq, not in the image).
- Domain caps written into meta: nested objects always have at least one key (parquet cannot hold an empty struct), keys are valid avro names (base cannot handle other keys either).
- Repo comment convention: source has doc comments on some helpers, tests have a few inline ones. Default NONE kept for added code.

## Slice status (2026-10-13, Step 4b STOP)
- Core slice built: shape kernel (codec/util/shape.go) + typed avro writer/reader + typed parquet writer/reader. Hook: 354 human-effective / 3 files (padding-floor 25: numeric type-switch arms).
- Tests: 11 new (codec/binary_schema_641087_test.go), all fail on base (assertions, plus one base parquet panic on a non-object element), all pass with the solution. Base mode 280 testcases, 0 failures, with and without the solution.
- Clean room (image built from base incl. .git, patches applied inside, --network none): uid 1000, root and unmapped 4242 all green.
- Gate 1/6 reproduced on base through the real CLI: parquet returns "1"/"true"/"1.5" strings; avro null-first then 5 fails to encode; avro drops a key absent from record 0; avro nests as JSON text; 9007199254740993 comes back 9007199254740992; parquet rejects a single object.
- Trap reproduction (mutations of the reference, verified landed): no union wrapping -> "avro: cannot encode union map with multiple entries" on a nullable nested record (names nothing about nullability); avro reader without NormalizeNumbers -> every identity/value test still passes, only the jq query test fails ("invalid type: int64").
- List-element nullability is NOT asserted (meta does not state it; pqarrow also reads required list elements back as nullable). Element nulls are left to FINISH value tests.
- Image build took ~23 min on this loaded machine (other sessions building). L62 (cold build < 600 s) must be timed in FINISH on a quiet machine.
- FINISH scope (not built): F-10 cells (list nullable / list of nullable records / record in list in nullable record / merges at nested and element positions), same key at two depths (avro name uniqueness), one-key nested object vs union wrapper, mixed in list, 2.0-in-list, unwrap of foreign unions (MapSchema arm), several query results into one binary file (cli/qq.go lever), mutation + FP passes, flakiness 3x.

## Description Quality round (2026-10-15)
- Task Prompt Quality FAIL: ai_generated, fractionAi 1.0, 389 words (quote = the "We want ... hand those values back exactly" opener). Content review itself was clean ("states the tested schema and round-trip behavior").
- User ran the body through the humanizer. Adopted its wording, then repaired the sentences that drifted against the previous meta:
  - 2.0 rule INVERTED ("values qq recognizes as integers, including 2.0, become floating-point") -> "An integer here is a value qq recognizes as an integer, so the JSON literal 2.0 counts as a floating-point value."
  - "Each array or single object will be written as a row" -> each object in the array, or the single object, is a row; "The function" -> "The writers".
  - Error list collapsed into "array containing nonobject elements or other inputs" -> three separate cases again.
  - "Column names are inferred from the fields of objects" lost the union -> "the fields found in any of the input objects".
  - "nullable columns with null values" dropped "a missing key reads back as null" -> restored.
  - Nested record / list rules lost recursion and position ("types inferred from all values in object columns") -> "field types and nullability inferred by these same rules from all objects found in that position"; same for list elements over every array at that position.
  - "Columns with mixed types" would also cover int+float -> "any other mix of types, such as".
  - "object columns always have at least one key-value pair" narrowed the cap -> "nested objects" (covers objects inside lists).
  - Reader paragraph: "Integers in input are decoded" -> "When reading"; "Arrays and records ... into JSON objects and arrays" swapped the mapping -> records to objects, lists to arrays; restored "in jq expressions".
  - Background: "Both readers return values encoded as JSON" -> "pass values through JSON"; "in package qq" (x3) -> "in qq".
  - U+2024 / U+201A punctuation -> ASCII. 401 words, ASCII, one line per paragraph.
- Pre-humanizer meta kept at worktrees/qq-meta-pre-humanizer.md.
- NEXT: re-run Task Prompt Quality. If flagged again, do not reword; send the flagged paragraph back through the humanizer.

## Description Quality round 2 (2026-10-15)
- FAIL again: ai_generated, fractionAi 1.0, 401 words, quote = opener. Content review flagged a REAL conflict: "readers return those values without modification" vs the mixed-type fallback (mixed columns read back as JSON text). Dropped as a non-blocking item, fixed anyway.
- Second humanizer pass adopted, repairs:
  - Added "except for the mixed-type columns described below" to the round-trip sentence (content fix).
  - "single schema and value type" -> "single typed schema".
  - "an array or object" -> "an array of objects or a single object"; "written on a separate line" -> "as a separate row".
  - "and other invalid inputs" (ambiguous) -> "and any other input".
  - Nested record fields / list items: added "by these same rules" (recursion).
  - "Columns with mixed types" -> "any other mix of types" (int+float is double, not string).
  - Reader paragraph: dropped "passed to jq" (x3, the readers decode, jq does not); restored "When reading" and "exact" 64-bit.
  - U+2024 / U+201A -> ASCII.
- Round-1 meta kept at worktrees/qq-meta-humanizer-r1.md.

## Description Quality round 3 (2026-10-15): "Too many requirements"
- AI detector no longer the blocker; requirementCount FAILED at ~25 atomic rules / 435 words.
- Cut to ~13 rules / ~260 words, mostly by deletion and folding (no agent runs yet, so no kill counts to rank by; cut what nobody breaks unstated or a broader sentence already implies):
  - Dropped all four current-behavior sentences (background, not tested).
  - "Column types from all rows" folded into "single typed schema for all records".
  - Bool/string/int/float type sentences folded into one; int+float double kept; 2.0 kept as a "so" clause.
  - Nested record + list rules merged into one sentence ("fields and items typed by these same rules from all values at that position").
  - Error list folded to "Empty arrays and any other input" (nonobject elements are "any other input").
  - Dropped "nulls stay null" (implied by nullable), "exact 64-bit integers" (implied by "unchanged"), "doubles decode as floats" and "records to objects, lists to arrays" (implied by "unchanged" + the jq sentence), the mixed-type examples.
  - Added: readers return the rows "as an array" (single-object test reads back [obj]; "unchanged" alone contradicted it); "compact" JSON text (mixed test pins {"k":true}).
- Test change: TestBinarySchemaNullInFirstRecordDoesNotFixTheType no longer has the always-null column "w" (pinned "string?", never stated in any meta). Reference unchanged.
- Validated in olympus-base-go container (root): sol new 11/0 x3, sol base 280/0; nosol new 11/11 fail, nosol base 280/0.
- Backups: worktrees/qq-meta-humanizer-r2.md, worktrees/qq-test-pre-cut.patch. Container script: worktrees/qq-tools/verify-cut.sh (volume qq-gomod holds the module cache).
- NEXT: re-run Task Prompt Quality. If requirementCount fails, re-run the same text once (noisy). The deletions may re-trigger the AI detector (macs/csbindgen pattern); then humanize + drift repair again.

## Description Quality round 4 (2026-10-15)
- requirementCount PASSED on the ~13-rule cut (verdictBasis lists only aiDetectionBlocking). AI detector FAILED (fractionAi 1.0, 258 words, quote = opener), as predicted after deletions.
- Third humanizer pass adopted, repairs:
  - "according to a single typed schema" lost "for all records" -> "that covers all input records" (top-level types-from-all-rows rule lives here now).
  - "provide copies of output records as arrays" (reads as each record an array) -> "return the written records unchanged as one array".
  - "behave similarly to" -> "behave the same as".
  - "a list or single input object" -> "a list of objects or a single input object".
  - "other types of input" (could exclude lists of nonobjects) -> "any other input".
  - "can also be null in outputs; other missing fields ... produce null" -> "are nullable in outputs, and a missing field produces a null value".
  - Two comma splices in rule sentences -> "so" (2.0 clause, "x" example).
  - Kept humanizer's "objects always have at least one key-value pair" (broader than "nested", still true of every test input).
  - U+2024 / U+201A -> ASCII.
- Backup of round-3 text: worktrees/qq-meta-cut-r3.md. No test/solution change this round.

## Batch 1 (2026-10-15): Nova 2/2 PASS, seq avg 223k -> too easy AND too short
- Both Nova passed 11/11 legitimately on the passed meta. Details + probe tables in eval-results.md.
- 101-cell differential probe: zero divergence between Nova2 and the reference on every stated axis. Nova1 differs only on avro nullable lists (union wrapper kept). Tests-only levers cannot reach Nova 0/8.
- Scope signal: the only place every solution breaks is OUTSIDE the "keys are valid avro identifiers" cap. Lifting that cap ("any key string, comes back unchanged") is a one-clause swap (requirement count roughly flat), contract-stated and fix-hidden (sanitize to unique avro names per record AND remember the original key, e.g. a field property, then restore on read), and widens the reading surface (avro naming rules, hamba schema props) for the sequence gate. Needs reference work and a description delta (full batch).
- Bank regardless: the nullable-list cells (list_of_nullable_lists, nullable_list) as tests.

## Harden round 1 (2026-10-15): lift the avro-name cap (user choice)
- Lever: "all keys are valid avro identifiers" cap replaced by "Keys can be any string. When avro does not accept a key as a field name, the file must still be valid avro and the readers must still return the original key." Paid for it by folding the "qq would treat as integers / 2.0" sentence into the type sentence ("with the JSON value 2.0 counting as floating-point"). Body 296 words. DESCRIPTION DELTA: full batch, no re-eval.
- Reference (codec/avro/avro.go): fieldNames() keeps valid keys, sanitizes the rest ([A-Za-z0-9_], "_" prefix for empty/digit start), uniquifies with _2, _3... against every name in the record (valid keys reserved first); renamed fields carry a "qqKey" schema property; the reader restores from field.Prop. Per-record name maps cached on recordNames, not recomputed per row.
- Found while building: hamba's OCF encoder writes the CANONICAL schema by default, which drops custom properties. ocf.WithSchemaMarshaler(ocf.FullSchemaMarshaler) keeps them. A fix that stores the original key in the schema silently loses it without this; metadata or doc-based fixes also work. Likely the hidden half of the trap.
- hamba has a global avro.SkipNameValidation; an agent flipping it would write invalid avro. Meta says the file must stay valid; columns641087 now sets SkipNameValidation=false before ocf.NewDecoder, so every schema-reading test checks validity.
- Tests (+5, 16 total): AnyKeyComesBack (hyphen, digit start, "", accented; 5 columns, "ok" keeps its name), RenamedKeysDoNotCollide ("a b"/"a-b"/"a_b"/"a_b_2"/"a.b" + nested "x y"/"x_y"), OddKeysInsideNestedValues (odd keys in records in lists in nullable records, late odd column, jq on restored keys), MixedColumnKeepsOriginalKeys (JSON text keeps "a-b", column "v-1"), NullableLists (banked from the probe: Nova1 kept the {"array": ...} wrapper).
- Replay of batch-1 solutions (they never saw the clause, upper bound only): Nova1 fails 5 (4 key + nullable lists), Nova2 fails the 4 key tests.
- Validation: clean room from the patch files, uid 1000: nosol new 16/16 fail, base 280/0; sol new 16/0 (x3 identical in the staged run), sol base 280/0; go vet ok, gofmt clean. human-effective 402 (hook), 3 files. No added comments, no banned markers, test.sh 100755.
- Backups: worktrees/qq-meta-batch1.md, worktrees/qq-tools/solution.pre-names.patch, official_test.go.pre-names, avro.go.pre-names.
- NEXT: Task Prompt Quality on the new meta (expect the AI flag again: humanize + drift repair; requirement count should hold, one rule swapped for one). Then upload meta + both patches, 1 Nova smoke run. If Nova passes, read its trajectory before anything else. Watch the sequence length: the target is avg > 256k.
