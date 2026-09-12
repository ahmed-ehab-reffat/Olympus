# gitql-json-functions - Strategic tracking

## Summary
**Repo:** AmrDeveloper/GQL (GitQL) - Rust, 3504 stars, MIT, pushed 2026-04, multi-crate
extensible SQL-over-git engine. Fresh: never used locally before this run.
BASE_COMMIT: 3a76cfee02a00ee6ce20eeac6447573b34f25d86.

**Feature:** Add a comprehensive JSON scalar function family to `gitql-std` (17 functions):
`json`, `json_pretty`, `json_valid`, `json_type`, `json_extract`, `json_array`, `json_object`,
`json_array_length`, `json_quote`, `json_set`, `json_insert`, `json_replace`, `json_remove`,
`json_patch`, `json_keys`, `json_contains`, `json_depth`. GitQL had no JSON functions
(datetime/text/number/array/regex/range/general only).

**Oracle:** SQLite JSON1 (python3 `sqlite3`, always available). The reference implementation was
differential-fuzzed against SQLite across 2400+ random (document, function, path) cases with
0 semantic mismatches; the 54 hidden-test expected values are oracle-derived (SQLite-backed cases
cross-checked; extensions - json_keys/contains/depth/pretty and the `#`/`$[#-1]` path forms -
are self-defined and documented in meta.md).

## Validation (all green)
- Effective LOC: human-effective **433** (>= 430), raw 652, 4 files (json/mod.rs new +
  standard.rs + lib.rs + Cargo.toml/lock). effective_loc_check.py: OK.
- Docker 4-cell, offline (`--network none`) + non-root (`--user 1000:1000`):
  - BASE image: `test.sh base` 14/0, `test.sh new` 47/47 fail (later 54/54) -> F2P.
  - SOLUTION image: `test.sh base` 14/0 (no regressions), `test.sh new` 54/0.
- Patches apply cleanly against BASE in both orders; test.sh is mode 100755; ASCII/LF.
- serde_json `preserve_order` needed for SQLite-matching object-key order; `indexmap` already in
  the vanilla lockfile, so the offline solution build needs no new crate download.

## Difficulty design (shape: comprehensive function family / O-Algorithm-coverage+correctness)
Discriminators built into the 54 tests, all documented in meta.md:
- object key order preserved (agents using default serde_json SORT keys -> fail).
- `$[#]` append / `$[#-n]` from-end path grammar (uncommon).
- set/insert/replace create-vs-overwrite matrix; `$` root replacement.
- json_patch RFC 7396 merge (null member removes; non-object patch replaces; scalar target -> object).
- json_contains recursion (candidate array subset; scalar-in-array).
- value-model rendering: scalars typed, containers minified text, invalid doc / missing path -> NULL,
  json_valid -> boolean.
Predicted pass band ~10-25% (must implement the whole family AND match exact rendering + traps).
Empirical Nova/Orion/Vega runs are the platform's step (not runnable here); see eval-results.md.

## Why this is not a duplicate
No approved/in-flight problem targets GitQL, or a JSON scalar function family in a SQL executor.
Closest SQL problems differ in FEATURE: sqlglot-string-functions (string funcs in a TRANSPILER, not
an evaluator), sqlglot-grouping-sets, risinglight-window-frames / risinglight-setops (window/setops,
not JSON), node-sql-parser-three-valued (NULL logic). ojg-json-patch is RFC 6902 JSON Patch in Go
ojg - distinct from this family's `json_patch`, which is the RFC 7396 merge (different RFC/algorithm,
different repo/language). jsonschema is validation. Repo is fresh; feature is a distinct evaluation
function family whose core is a JSON path engine + recursive merge/containment/depth algorithms.

## Run log
- Discovery: boa (base64 - too small at 361 eff LOC), Tera v2 (macros == existing "components"),
  mq/croner/pongo2 (complete) all rejected; per user direction ("SQL function family (GitQL)")
  pivoted here. GitQL is an EXTENSIBLE engine (designed for adding functions), so a comprehensive
  family is a natural 400+ LOC addition with a clean SQLite oracle.

## Revision round 1 (reviewer warnings addressed)
- Description AI-formatting (hardwrap): rewrote meta.md with single-line paragraphs (no manual
  mid-sentence line breaks); ASCII, 407 words, 0 em-dashes.
- test.sh exit code: now returns non-zero on failure - build failure in `new` mode exits 1, and
  both `new` and `base` modes exit 1 when any test fails (exit 0 only on all-pass). Re-validated:
  new(base) exit 1 / 64 fail; new(sol) exit 0 / 64 pass; base exit 0.
- Test coverage gaps (WARNING, added all suggested): json_remove '$' -> null; json_pretty exact
  two-space indent asserted for object and array via replace(json_pretty(x),'\n','|'); '$' root
  replacement for json_set (->42) and json_insert (no-op); invalid-JSON -> null for json_extract,
  json_array_length, json_keys, json_patch. Test count 55 -> 64.
- Re-validated full Docker 4-cell offline + non-root with the final artifacts: SOLUTION image
  base 14/0 (exit 0), new 64/0 (exit 0).

## Revision round 2 (Task Quality FAIL -> broadened to Olympus; user chose "Broaden")
The std-lib-only function family was judged Mars-tier (Self-Contained / Not-Trivial /
Long-Horizon FAILs). Broadened by adding native `->` and `->>` JSON access operators woven
through the whole expression pipeline, so the feature now spans FOUR subsystems across THREE crates:
- gitql-parser: token.rs (new `Arrow`/`LongArrow` tokens), tokenizer.rs (lex `->`/`->>`),
  parser.rs (new `parse_json_access_expression` precedence level, left-associative).
- gitql-ast: expression.rs (`ExprKind::JsonAccess` + `JsonAccessExpr`).
- gitql-engine: engine_evaluator.rs (dispatch + `evaluate_json_access`), depends on gitql-std.
- gitql-std: shared `evaluate_json_access` reused by the operator.
Semantics (SQLite -> / ->>): `->` returns JSON text, `->>` a typed value; right operand is an
object key (text), array index (integer), or full path (`$...`); left-associative chaining
re-parses; missing -> null. Differential-fuzzed vs SQLite: 360 operator cases, 0 mismatches on the
documented accessor forms (a SQLite numeric-text-as-index coercion is intentionally not replicated
and not tested).
Solution now: 11 files / 3 crates, raw 781 / human-effective 523 LOC. Tests 63 -> 72
(9 operator cases). Re-validated Docker 4-cell offline + non-root: SOLUTION base 14/0 exit 0,
new 72/0 exit 0; BASE new 72/72 exit 1 (F2P + non-zero exit).

## Revision round 1 fixes (recap)
- Description (necessary-info HIGH/MEDIUM/LOW): removed implementation/registration wording, the
  RFC label, the "in document order" duplication, and the path example. meta ~451 words, ASCII,
  single-line paragraphs.
- Test Fairness (5 unfair): documented json_valid=false-on-invalid and the scalar-in-array
  containment rule (keep); removed the ambiguous insert-at-root test and the two byte-exact
  json_pretty tests (overspecification). Added coverage: non-object patch, array_length missing path.
- test.sh: non-zero exit on any failure / build failure.

## Revision round 3 (harden toward ~10% pass; Solution Quality PASSED but too solvable)
Goal: raise difficulty to ~1/10 while staying fair (every tested behavior documented) and solvable
(reference passes all). Tests 72 -> 101.
- Restored the 3 test names the wrapper flagged as missing (insert_root_is_noop,
  pretty_object_two_space, pretty_array_two_space) per the immutable-test-name rule (the set only
  grows); they are now documented and fair (insert-at-root no-op is inferable from the set/replace
  root rule; json_pretty's exact two-space layout is documented, making the byte-exact test fair).
- Fixed the `->>` static type from TextType to AnyType (reviewer's soft spot): honest, since `->>`
  yields the value's own type; no base regression. (Full arithmetic composability needs a broad
  numeric-type-rule change with real regression risk, so it is intentionally not required/tested.)
- Added ~25 hard, documented discriminators, each an independent surface an agent can miss (and any
  single miss fails the suite): exact json_pretty layout; edits act at an existing parent
  (set/insert parent-missing -> no-op); malformed path -> null; json_object non-text key -> null;
  json_keys non-object -> null; multi-path json_extract with missing slots -> [.,null]; `->` JSON
  text vs `->>` typed value; index-out-of-range / non-object-then-key -> null; `#`/`#-n` path edges;
  containment recursion (array subset within an object member, nested objects); json_type real vs
  false at a path; json_depth of objects/scalars; json_quote of number/bool; json_valid of bare
  number/string. All SQLite-backed additions cross-check the oracle (0 diffs); the one subtype
  divergence (json_array of a json() result) is intentionally not tested.
- The dominant traps most agents miss: serde_json preserve_order (default sorts object keys),
  the exact json_pretty format, the `#`/`#-n` grammar, `->` JSON-text vs `->>` typed value, and
  RFC 7396 patch (null removes / scalar target -> object). Needing all 101 correct compounds these.
- Re-validated Docker 4-cell offline + non-root: SOLUTION base 14/0 exit 0, new 101/0 exit 0;
  BASE new 101/101 exit 1. Solution 11 files / 3 crates, raw 788 / human-effective 527 LOC.

## Revision round 4 (necessary-info HIGH + fairness + coverage + consistency)
- Necessary-info (HIGH): consolidated the repeated missing-path/null clauses into one global rule
  ("A missing or malformed path, and a missing operator target, yield null"); removed "both are
  left associative", the redundant "minified" in json_extract, and the operator intro sentence.
  meta now 447 words.
- Test Fairness (1 unfair: pretty_nested_two_space over-pinned the nested layout): relaxed to a
  fair round-trip body `json(json_pretty('{"a":[1,2]}')) = {"a":[1,2]}` while keeping the name
  (immutable-test-name rule); the two SIMPLE pretty cases were judged fair and kept.
- Solution consistency (flagged by two Solution Quality reviews): json_set/insert/replace and
  json_remove now return null on a malformed/non-text path or a dangling path/value argument,
  instead of silently skipping. A well-formed path whose parent is absent stays a no-op (distinct
  from malformed). Verified no base regression.
- Coverage suggestions added (per request): mixed_operator_chain (`-> ... ->>`), patch_array_replaces,
  patch_null_replaces, set_malformed_path_null, remove_malformed_path_null. Tests 101 -> 106.
- Re-validated Docker 4-cell offline + non-root: SOLUTION base 14/0 exit 0, new 106/0 exit 0;
  BASE new 106/106 exit 1. Solution 11 files / 3 crates, human-effective 531 LOC.

## Revision round 5 (Description Quality FAIL + Test Fairness pretty over-pinning)
- Description Quality FAIL (2 comments):
  1. Scoped the invalid-JSON->null rule to document-consuming functions; json_array/json_object/
     json_quote take arbitrary values (they were wrongly covered by the blanket rule).
  2. json_depth "empty containers" was untested -> added depth_empty_array / depth_empty_object.
- Test Fairness FAIL (both simple json_pretty exact-format tests judged over-pinning): stopped
  pinning json_pretty's exact bytes entirely. Relaxed pretty_object_two_space and
  pretty_array_two_space to round-trips (json(json_pretty(x))=json(x)), keeping the immutable names;
  softened meta ("json_pretty reserialises it in indented form", dropping the exact layout);
  added deterministic pretty_empty_object / pretty_empty_array. json_pretty is now covered only by
  fair, layout-agnostic checks.
- Coverage suggestions added: replace_parent_missing_noop, insert_append_hash (confirms `[#]`
  appends for insert too; meta generalized so `[#]` append applies to set/insert/replace).
- Necessary-info HIGH already resolved in round 4 (single global missing/malformed-path null rule;
  removed left-associativity, the redundant "minified", and the operator intro sentence).
- Tests 106 -> 114. meta 435 words. Re-validated Docker 4-cell offline + non-root: SOLUTION base
  14/0 exit 0, new 114/0 exit 0; BASE new 114/114 exit 1. Solution unchanged (11 files / 3 crates,
  human-effective 531 LOC).

## Revision round 6 (all-WARNING polish; no FAIL remaining)
All checks now pass at WARNING/minor level. Addressed the advisory items:
- Test quality (json_pretty indentation not directly asserted): added `pretty_adds_whitespace`
  (`len(json_pretty(x)) > len(json(x))`) which verifies pretty output is indented WITHOUT pinning
  an exact layout (fair). Added the two suggested minor cases: `json_minify_invalid_null`
  (`json('nope')` -> Null) and `array_length_path_nonarray_zero`.
- Alignment (implicit interface details): meta now states json_type/json_array_length take an
  optional path, that `->>` returns containers as JSON text, that json_insert at `$` leaves the
  document unchanged, and reworded the null rule ("A malformed path, or a lookup that resolves to
  no value, yields null; a mutation whose parent is absent leaves the document unchanged") to
  disambiguate malformed-path-null vs missing-parent-no-op.
- Necessary-info (2 medium): removed the redundant opening sentence and the duplicate
  "json_valid returns true/false" restatement.
- Tests 114 -> 117; meta 449 words. Solution byte-identical to the Docker-validated build
  (offline + non-root, F2P, exit codes verified in prior rounds); local 117-case 4-cell confirms
  new(base) 117/117 fail, new(sol) 117/0 exit 0, base(sol) 14/0.

## Revision round 7 (category: feature_request)
The category check failed (suggested "enhancement") because round 6 had removed the "Add ..."
framing (per an advisory necessary-info trim), so the body read as describing existing functions.
Restored explicit net-new framing: "Add a new family of JSON scalar functions and two new JSON
access operators; none exist yet. The new functions that consume a JSON document ...". This makes
the category feature_request (net-new public API family + operators), which is the honest category
since GitQL had no JSON functions or `->`/`->>` operators before this patch. meta 450 words; tests
and solution unchanged (117 tests, 11 files / 3 crates, validated).

## Revision round 8 (necessary-info HIGH + fairness re-check)
Meta trims (behaviors remain documented, so no fairness regression):
- [HIGH] removed "and `[#]` appends to an array" - append is implied by the path grammar
  ("`[#]` the position past the last element" + set/insert write); the reviewer itself noted the
  implication, and Test Fairness had already marked set_append_hash as prompt-stated.
- [MEDIUM] removed "and act at an existing parent" (covered by "a mutation with an absent parent
  leaves the document unchanged").
- [MEDIUM] removed the "json_array/json_object/json_quote take arbitrary values" summary; the
  scoping "functions that consume a JSON document" excludes them from the null rule and each is
  described per-function later.
- [MEDIUM] removed the redundant "minifies" (kept `json` named as "reparses a document"; the
  closing "output is minified except for `json_pretty`" supplies the minified output).
- [LOW] kept "none exist yet" - it protects the feature_request category (blocking) which outranks
  a LOW style note.

Fairness re-check (user request):
- Solution vs SQLite oracle: 0/450 mismatches across 3 seeds (functions) - the reference is
  oracle-grounded, so exact expected values are fair.
- Traceability: all 117 tests map to the 17 functions + 2 operators, all of which are documented
  in meta; the trimmed clauses' behaviors remain documented via the general path/null/order rules
  and per-function descriptions. The only prior-unfair test (pretty_nested_two_space) is now a
  layout-agnostic round-trip, and no test pins json_pretty's exact bytes.
meta 432 words. Tests and solution unchanged (117 tests, 11 files / 3 crates, validated).

## Revision round 9 (Test Fairness: pretty-empty over-pin + advisory coverage)
- Test Fairness FAIL (pretty_empty_object / pretty_empty_array pinned exact `{}`/`[]`): reviewers
  disagree on empty-container layout, so removed ALL exact-byte json_pretty pinning. Relaxed both
  to round-trips (`json(json_pretty('{}')) = {}`), keeping the immutable names. json_pretty is now
  covered only by round-trip + `len(pretty)>len(minified)` + `json_valid(json_pretty(...))`.
- Advisory coverage suggestions added (per request): patch_invalid_patch_null
  (`json_patch('{}','nope')` -> Null, both args obey invalid->null), extract_quoted_key_dotted
  (`$."a.b"` quoted key containing punctuation), set_multi_pair_order
  (`json_set('[1,2]','$[#]',3,'$[#]',4)` -> [1,2,3,4], order-sensitive left-to-right).
- Documented left-to-right pair/path application in meta so set_multi_pair_order and
  remove_multi_path_reindex are prompt-stated rather than standard-external.
- Tests 117 -> 120; meta 439 words. Re-validated: 4-cell new(base) 120/120 fail, and Docker
  solution image offline + non-root base 14/0 exit 0, new 120/0 exit 0. Solution unchanged.

## Revision round 10 (Test Fairness: operator integer index base + advisory coverage + stdin-drain bug)
- Test Fairness FAIL (op_arrow_array_index / op_longarrow_array_index: `'[10,20,30]' -> 1` -> 20):
  the integer-index base was under-specified and GitQL's NATIVE array indexing is 1-based
  (crates/gitql-core/src/values/array.rs), so 0-based `-> 1` was not prompt-stated. Fix (immutable
  names kept; documented, not relaxed): meta path grammar now reads "`[n]` the array element at
  zero-based index `n`", and the operator paragraph ties the integer operand to that element
  ("the array element `[n]` when the integer `n`"). This also upgrades several previously
  standard-external tests (extract_nested_index, arrow/longarrow index cases, from-end forms) to
  prompt-stated.
- Advisory coverage suggestions added (per standing request):
  - set_invalid_doc_null / insert_invalid_doc_null / replace_invalid_doc_null / remove_invalid_doc_null
    (`json_set('nope','$.a',1)` -> Null): all four mutators obey invalid-document -> null.
  - op_arrow_malformed_path_null / op_longarrow_malformed_path_null (`'{"a":1}' -> '$['` -> Null):
    operator RHS malformed `$`-path yields null (mirrors extract_malformed_path_null for operators).
  - array_embeds_json_string / object_embeds_json_string (`json_array('{"x":1}')` -> `["{\"x\":1}"]`):
    JSON-looking text arguments are embedded as JSON strings, NOT reparsed (already documented:
    "text arguments are embedded as JSON strings").
- BUG FOUND + FIXED (test.sh, docker-only stdin drain): in `new` mode the `while read ... done < TSV`
  loop shared FD 0 with the gitql child; under Docker the child advanced the loop's descriptor, so
  only 47 of 128 cases ran (still 0 failures -> silently under-tested). Host runs were unaffected,
  so it hid on local runs. Fixed by reading the loop on a private FD (`read ... <&3` / `done 3< TSV`)
  and adding `</dev/null` to the gitql call. Re-verified in Docker: all 128 execute.
- Tests 120 -> 128; meta 439 -> 415 words (ASCII, 0 non-ASCII). Solution unchanged (11 files /
  3 crates). test.sh + test.patch regenerated.
- Test-Quality WARNING (len()/CSV "Null" formatting) and necessary-info MEDIUM suggestions
  (drop "none exist yet" / "missing target null"): left as-is. "none exist yet" protects the
  feature_request category (blocking); the operator "missing target null" clause keeps the
  operator-miss tests (op_arrow_missing_null, longarrow_missing_null) prompt-stated and is only
  partly covered by the path-lookup rule. Both suggestions are optional/non-blocking.

## Revision round 11 (HARDENING - platform data showed too-easy, 5/6 Nova pass)
Discovered real platform eval data (was in a stray eval-platform.txt, now folded into
eval-results.md): 6 Nova runs, 5 PASS_LEGITIMATE / 1 FAIL_MISSED_REQUIREMENT (~83% pass) on the
72-test revision. That is far above the ~10% ceiling (>2/10 = harden). Only the json_patch
member-order-on-update trap (patch_merges) discriminated (1/6). User directive: "harden now, I pick
traps." Approach: stack ORTHOGONAL subtle-correctness discriminators - all already documented by
the general meta rules, all SQLite-oracle-validated (0/17 mismatches), all already implemented
correctly by the reference (so NO solution change; solvability intact - Nova provably implements
them). Test-only expansion; names only grow.
Four orthogonal trap families (naive-wrong answer in parens):
1. Update-in-place ordering (patch/set/replace/nested update keeps a member's position):
   set_update_keeps_pos, replace_update_keeps_pos, patch_update_first_keeps_pos,
   set_nested_update_keeps_pos. Naive shift_remove+insert moves the key to the end.
2. json_remove sequential left-to-right reindex (each path applied to the ALREADY-mutated array):
   remove_two_indices_sequential (`$[1]`,`$[2]` on [10,20,30,40] -> [10,30], naive [10,40]),
   remove_same_index_twice ([1,2,3] `$[0]`x2 -> [3]), remove_index_then_key.
3. json_extract single-path-bare vs multi-path-wrapped, and result order follows the PATHS:
   extract_single_array_bare, extract_single_obj_bare (bare, not wrapped -> naive always-wrap fails),
   extract_multi_paths_order (`$.b`,`$.a` -> [2,1], not doc order [1,2]).
4. Operator typed-vs-text + JSON null:
   longarrow_jsonnull_is_sql_null (`->>` JSON null -> SQL null, naive text "null"),
   arrow_jsonnull_is_text_null (`->` -> JSON text null), arrow_keeps_string_quotes (`->` keeps `"hi"`).
Meta: added two short fair clarifications (paid within the 450 cap): "an updated member keeps its
position" and "`->>` ... a JSON null as SQL null". meta 428 words, ASCII.
Tests 128 -> 141. Re-validated fresh-build 4-cell (offline + non-root): BASE base 14/0 exit0 /
new 141/141 fail exit1; SOL base 14/0 exit0 / new 141/0 exit0. Solution unchanged (11 files /
3 crates / 531 effective LOC). Predicted: orthogonal miss-rates now compound (patch-order ~17% +
remove-sequential + extract-wrap/order + arrow-null, mostly uncorrelated) -> target ~10% band;
re-measure on next platform batch. If still >2/10, add another orthogonal family (e.g. json_type at
path edge values, json_contains deep subset, duplicate-key last-wins).

## Revision round 12 (necessary-info request_changes + advisory coverage)
Description necessary-info verdict request_changes (1 HIGH blocking + 3 MEDIUM optional):
- [HIGH, addressed] Removed "; none exist yet" - kept "Add a new family of JSON scalar functions
  and two new JSON access operators" so the feature_request CATEGORY signal is preserved (dropping
  only the trailing meta-status clause, not the net-new opening that a prior round proved
  category-load-bearing).
- [MEDIUM, addressed] Removed the "Paths follow SQLite:" preface; the path grammar ($, .key,
  ."quoted key", [n] zero-based, [#], [#-n]) is fully defined in-text, so solvability/discoverability
  is unchanged (5/6 Nova already solved these forms).
- [MEDIUM, addressed] Removed "and a missing target null" from the operator paragraph; operator
  key/index misses are covered by the global "a lookup with no value yields null" rule, so
  op_arrow_missing_null / longarrow_missing_null stay prompt-stated.
- [MEDIUM, DECLINED w/ rationale] Kept "`json_pretty` reserialises it in indented form": it is the
  primary description of a TESTED behavior (the pretty round-trip tests assert content preservation).
  Removing it would risk a BLOCKING Test-Fairness under-spec on those tests - worse than an
  unaddressed OPTIONAL medium. The later "minified except for json_pretty" alone is weaker coverage.
Advisory coverage suggestions (added per standing rule to always address them):
- pretty_invalid_null (`json_pretty('nope')` -> Null): invalid-document rule applies to json_pretty.
- type_malformed_path (`json_type('{"a":1}','$[')` -> Null): malformed-path handling for json_type
  (oracle-matched to SQLite), not just extract/mutators.
- contains_invalid_target_null / contains_invalid_candidate_null (`json_contains('nope','1')` and
  `json_contains('[1,2]','nope')` -> Null): invalid JSON in EITHER json_contains arg yields null.
- [DECLINED w/ rationale] "pretty formatting specifics" (assert exact json_pretty indentation width):
  NOT added. Pinning json_pretty's exact bytes is the precise unfairness reviewers rejected across
  rounds 5/8/9 (layout is reviewer-contested); indentation width is deliberately unspecified in meta,
  so an exact-width assertion would be a hidden requirement. json_pretty stays covered fairly by
  round-trip + len(pretty)>len(minified) + json_valid(json_pretty(...)).
meta 421 words (ASCII). Tests 141 -> 145. Solution unchanged. Re-validated 4-cell (offline +
non-root): BASE base 14/0 e0 / new 145/145 fail e1; SOL base 14/0 e0 / new 145/0 e0.

## Revision round 13 (MAJOR HARDENING - non-SQLite recursive path engine json_query)
Platform batch on the 141-test revision (user-provided, in eval-results.md): 6 Nova runs,
4 PASS / 2 FAIL (~67%). Both FAILs fair (FAIL_MISSED_REQUIREMENT: malformed mutation path not ->null;
json_array_length missing-path returned 0 not null). Still far above the ~10% ceiling. Root cause
confirmed: the whole family mirrors SQLite JSON1, which Nova knows from training - every
SQLite-conformant "trap" is something it gets right for free (see [olympus-classic-algorithms-too-trained]:
more documented spec bullets raise reading load, not difficulty). Fair + massively over-solvable
(4/6) = huge headroom to harden without risking the floor.
Fix (user chose "path engine + divergent rules"; Explore confirmed aggregates are NOT
deterministically testable under the empty-temp-repo harness - no VALUES/generate_series, single
empty commit, volatile commit_id/datetime - so a scalar path engine is the right lever):
added json_query, a NON-SQLite recursive-descent / wildcard path engine. This breaks the SQLite
prior because SQLite JSON1 has NO wildcards or recursive descent, and json_query deliberately
DIVERGES from json_extract:
- ALWAYS returns a JSON array (even 0 or 1 match): `$.a`->[5], `$.z`->[] (json_extract returns bare
  5 / null). An agent unifying the two wrapping rules fails.
- recursive descent `..key` is PRE-ORDER INCLUDING self-then-descend: `{"a":{"b":{"b":9}}}` `$..b`
  -> [{"b":9},9] (matches outer b, THEN descends into it and matches inner b). Agents dedup / skip
  nested-in-matched / mis-order.
- `..*` = every value pre-order; `.*` = each member value or array element; `[*]` = each array
  element; duplicates KEPT (no dedup); the `[#]`/`[#-n]` forms are REJECTED (unlike the family).
- invalid document or malformed pattern -> null.
Validation: implemented purely in crates/gitql-std/src/json/mod.rs (QueryStep enum, parse_query,
read_query_key, descend, apply_step, query_collect, json_query; +signature/registration) - no
parser/aggregation wiring. Differential-fuzzed gitql json_query vs a Python reference of the exact
semantics: 1500 random (doc,pattern) cases, 0 mismatches (custom oracle, since SQLite can't express
this). 18 new json_query tests, all oracle-derived. json_query is SOLVABLE (reference passes; the
semantics are fully documented) but NON-TRAINED (agents must build a real multi-match traversal from
the spec) - so it compounds hard with the existing family.
Effective LOC 531 -> 642 (added genuine recursive DEPTH, not registry breadth; padding-floor 316).
meta 449 words (added a json_query sentence; trimmed redundancy incl. the json_pretty "indented form"
clause - now covered by "minified except for json_pretty", which also closes the last necessary-info
MEDIUM). Tests 145 -> 163. Solution.patch + test.patch regenerated. Predicted: json_query's
always-array/pre-order/no-dedup divergences are exactly the kind of non-SQLite surface Nova cannot
pattern-match, so combined with the family the joint pass rate should drop toward the ~10% band or
below; re-measure on next platform batch.

## Revision round 14 (description AI-formatting: wall-of-text)
Description-formatting heuristic flagged 2 paragraphs at 150+ words (wall_of_text). Split the two
long function-listing paragraphs into shorter ones by topic (accessors/queries | builders;
mutations | keys/contains/depth) - 6 paragraphs now, max 101 words each, no paragraph >= 150.
Chose paragraph breaks over bullets to avoid adding `-` word-tokens (stays 449 words, under the 450
cap). ASCII, 0 em-dashes. No content/semantics change; meta.md is a standalone deliverable so no
patch/4-cell revalidation needed.

## Revision round 15 (Test Fairness: 1 unfair quoted-descent + 3 advisory coverage)
Test Fairness FAIL 1/56: jq_quoted_descent_key pinned `$.."a b"` (quoted key in recursive descent);
meta named `..key` and `."quoted key"` separately but not the combined `.."quoted"` form.
Fixed by DISCOVERABILITY (keep the immutable test; document the form) not deletion: changed the
json_query clause token `..key` -> ``..key`/`.."key"`` (one whitespace-word, so meta stays 449 -
zero word-budget cost). Now prompt-stated.
Advisory coverage suggestions added (per standing rule - always add them):
- jq_hash_from_end_rejected (`json_query('[1,2,3]','$[#-1]')` -> Null): the `[#-n]` from-end form is
  rejected by json_query, not just plain `[#]`.
- set_quoted_key_path / replace_quoted_key_path / remove_quoted_key_path: mutators accept quoted-key
  paths (`$."a b"`, `$."a.b"`) - the same quoted-key path grammar (para 1) already tested for
  extract/query, now exercised on the mutators (`{"a b":9}`, `{"c":2}`).
- patch_nested_array_replaced (`json_patch('{"a":[1,2]}','{"a":[9]}')` -> {"a":[9]}): RFC 7396 edge -
  an array member is replaced wholesale, not merged elementwise (cross-checked vs SQLite oracle).
Tests 163 -> 168. Solution UNCHANGED (quoted descent + quoted mutator paths + array-replace already
implemented correctly). meta 449 words (ASCII). test.patch regenerated. Re-validated: BASE new
168/168 fail e1; SOL new 168/0 e0; SOL base 14/0 e0 (offline + non-root).

## Revision round 16 (Test Fairness FALSE-POSITIVE + 3 advisory coverage)
Test Fairness verdict FAIL 1/27, but it is a REVIEWER GLITCH, not a real unfairness: the single
flagged row (keys_of_object) has evidence="placeholder" and qualityCheck="placeholder", and the
reviewer's own `overall` states verbatim: "I found no genuinely unfair hidden test behaviors in the
supplied patch" and "One entry in the draft schema above was left incomplete." keys_of_object asserts
json_keys('{"x":1,"y":2}') = ["x","y"], which is prompt-stated ("json_keys returns an object's member
names as a JSON array") with document order ("member order follows the document") - maximally fair,
nothing to relax. 26/27 rows explicitly rated Prompt-stated / Repo-discoverable / Standard-external.
Handling: bypass-eligible (Test Fairness is not solvability/tier/deliverable). BYPASS PARAGRAPH below.
Advisory coverage suggestions added (per standing rule - always add):
- object_empty_object (`json_object()` -> {}): mirrors array_empty (oracle-matched to SQLite).
- set_late_malformed_path_null (`json_set('{"a":1}','$.b',2,'$[',3)` -> Null): pins that a LATE
  malformed path makes the whole mutator return null (atomic; no partial commit) - prompt-stated
  ("a malformed path yields null" applies to the function result).
- jq_dot_star_on_array (`$.*` on [1,2,3] -> [1,2,3]) and jq_path_dot_star_array (`$.a.*` on an array
  member -> [1,2]): `.*` iterates array elements, not just object members.
Tests 168 -> 172. Solution UNCHANGED (all behaviors already implemented). meta unchanged (449 words).
Re-validated: BASE new 172/172 fail e1; SOL new 172/0 e0; SOL base 14/0 e0 (offline + non-root).

### BYPASS PARAGRAPH (Test Fairness) - paste at submission
Test Fairness fired FAIL on 1 of 27 tests, but this is a false positive from an incomplete reviewer
schema entry, not a real finding: the single flagged row, keys_of_object, carries evidence
"placeholder" and quality "placeholder", and the review's own overall verdict states verbatim "I
found no genuinely unfair hidden test behaviors in the supplied patch." keys_of_object asserts
json_keys('{"x":1,"y":2}') returns the minified JSON array ["x","y"], which is directly prompt-stated
("json_keys returns an object's member names as a JSON array") with order fixed by the documented
rule "member order follows the document"; the exact CSV rendering is repo-discoverable via
Value::literal()/CSVPrinter, exactly as the reviewer rated the other 26 of 27 rows (all Prompt-stated,
Repo-discoverable, or Standard-external, 0 substantively unfair). Every tested behavior is described
in meta and every described behavior is tested, so keys_of_object introduces no hidden requirement.
The dominant and only "failure" is a draft-schema artifact the reviewer itself disowns, so the suite
is fair and the submission should proceed.

## Revision round 17 (HUMAN reviewer Zeyad Nasef - Revision Requested: Tests 1/3, Solution 1/3)
Description Clean (3/3). Addressed ALL six required points (no bypass - human review).

SOLUTION & CODE:
- S1 (typed-extraction composability + operator precedence): `->>` and single-path json_extract
  returned AnyType, which has NO arithmetic/comparison capability, so `json_extract(...)+1` and
  `(doc ->> 'k')+1` failed as `Any+Int` while the reversed operand worked (IntType.equals accepts
  is_any/is_variant_with). And the access operator sat ABOVE arithmetic in the precedence ladder, so
  `doc ->> 'k' + 1` mis-grouped as `doc ->> ('k'+1)`. Fixes: (a) typed extraction now returns
  VariantType[Int,Float,Text,Bool] (expression.rs JsonAccessExpr::expr_type for `->>`; json/mod.rs
  json_extract signature); (b) gave VariantType real capability overrides (add/sub/mul/div/rem +
  result types, and eq/bang_eq/gt/gte/lt/lte) that union its members' capabilities, so it composes as
  a LEFT operand too; (c) moved parse_json_access_expression DOWN the precedence ladder so access
  binds tighter than *,/,+,-,<<,>> (contained_by->bitwise_shift->term->factor->json_access->like),
  preserving left-assoc chaining. Now `json_extract(...)+1`, `(doc->>'k')+1`, `doc ->> 'k' + 1`,
  left-operand comparisons, and `json_quote(doc -> 'n')` ("5"/"true", JSON text) vs
  `json_quote(doc ->> 'n')` (5/true, typed) all work.
- S2 (edit_at append conflation): out-of-range `[n]` and underflowing `[#-n]` were both collapsed
  into the `[#]` append path when create was on (`json_set('[1,2]','$[9]',3)` and `'$[#-3]'` both
  gave `[1,2,3]`). Rewrote edit_at: only `[#]` (FromEnd offset 0) appends; an out-of-range Index or a
  from-end index before the front leaves the document unchanged (set AND insert).
- S3 (docs): added docs/functions/json.md (operators, path syntax incl. json_query extended forms,
  full 18-function table, mutation semantics) and linked it from mkdocs.yml nav and
  docs/functions/index.md, matching how array/cardinality/window are documented.

TESTS:
- T1 (test.sh base green-on-broken): base mode discarded `cargo test --workspace` exit status and
  only counted `test ... ok/FAILED` lines, so a compile/doctest/runner error with no FAILED line
  reported 0 failures (and 0 matches even fabricated a passing `workspace_tests` case). Now captures
  `cargo_status=$?`, and on any nonzero exit emits a failing `workspace_regression` JUnit case
  embedding the captured output (CDATA) and exits 1. Verified: healthy base 14/0 exit0; a simulated
  cargo exit 101 (fake cargo via CARGO_HOME) -> 1 failure, exit 1, output captured.
- T2 (operator typing): added left-operand arithmetic/comparison (extract_left_arithmetic,
  longarrow_left_arithmetic, extract_left_comparison, longarrow_left_comparison), unparenthesized
  operator (longarrow_unparenthesized_arith), and json_quote `->` vs `->>` for numbers AND booleans
  (quote_arrow_number_text "5" vs quote_longarrow_number_typed 5; quote_arrow_boolean_text "true" vs
  quote_longarrow_boolean_typed true).
- T3 (mutator indices): set_existing_index, set_valid_from_end, replace_valid_from_end, plus the
  distinctions set_index_beyond_end_noop / insert_index_beyond_end_noop / set_from_end_underflow_noop
  (out-of-range and before-front targets do NOT become `[#]`).
- T4 (negative contains): contains_wrong_value_false (existing key, different scalar) and
  contains_nested_wrong_value_false (nested wrong value).

Tests 172 -> 189. Solution.patch 15 files (adds variant.rs, docs/functions/json.md, index.md,
mkdocs.yml). Effective LOC 642 -> 757. json_query untouched (byte-identical). Re-validated locally
(new 189/0, base 14/0); Docker 4-cell pending fresh rebuild.

## Revision round 18 (Test Fairness: 2 unfair undocumented pins + 2 advisory coverage)
Test Fairness FAIL 2/31 - both behaviors the HUMAN reviewer (round 17) required/accepted but that
were not yet documented; fixed by DISCOVERABILITY (document them), not by relaxing (the human
mandated the precedence + the unparenthesized test):
- longarrow_unparenthesized_arith (`'{"a":2}' ->> 'a' + 1` -> 3): `->>` precedence over `+` was
  unstated. Added to the operator paragraph: "The operators chain left to right and bind tighter
  than arithmetic." (matches the round-17 parser precedence fix and the human's "ordinary
  unparenthesized operator use" requirement).
- patch_scalar_target_becomes_object (`json_patch('5','{"a":1}')` -> {"a":1}): the object-patch /
  non-object-target RFC 7396 corner was unstated. Added: "an object patch treats a non-object
  target as `{}`."
Also documented (preempting the aligned-tests WARNING #2, though the fairness check already ruled
those tests fair): "only `[#]` appends, so an out-of-range index is a no-op" (covers
set_index_beyond_end_noop / set_from_end_underflow_noop / insert_index_beyond_end_noop).
Paid for the additions by tightening redundancy (json_type type list -> slash-joined literals is the
big win; contains/query/array phrasing): meta 449 -> 447 words, ASCII, 6 paras all < 150.
Advisory coverage suggestions added (per standing rule - always add):
- set_pair_uses_prior_append (`json_set('{"a":[1]}','$.a[#]',2,'$.a[1]',9)` -> {"a":[1,9]}): an
  earlier pair appends a[1] that a later pair then traverses/edits - the left-to-right rule beyond
  repeated appends.
- extract_from_pretty (`json_extract(json_pretty('{"a":{"b":7}}'),'$.a.b')` -> 7): reads a nested
  field back out of json_pretty, checking semantic preservation directly.
Tests 189 -> 191. Solution UNCHANGED (behaviors already implemented in round 17). test.patch
regenerated. Re-validated: BASE new 191/191 fail e1; SOL new 191/0 e0; SOL base 14/0 e0 (offline +
non-root).

## SOLVABILITY CONFIRMED (round 18)
Orion solved correctly (PASS_LEGITIMATE). Solvability floor MET. Nova 0/10 but every fail is fair
(agent_blame_unfair=false, documented) and a near-miss (2-14 of 191). This is the target hard band:
a strong agent passes legitimately, the weak agent scatters short. No redesign needed - the earlier
0/10-Nova was NOT unsolvability, just Nova thrashing on a ~757-LOC cross-subsystem task, as predicted.
Status: all human-reviewer (Zeyad, round 17) revision items addressed + Test Fairness rounds resolved
(round 18 documented the last 2 pins) + Description Clean (3/3) + solvability proven. Ready to resubmit.

## Revision round 19 (HUMAN reviewer Zeyad, v2->v3: Tests 1/3, Solution 1/3; Description Clean 3/3)
Addressed all points (human review - no bypass). Description unchanged (447 words) - all points were
solution/test; "only `[#]` appends" was already documented (reviewer even cited it).

SOLUTION & CODE:
- S-A (Variant result collapse): VariantType::delegated_result returned the FIRST matching member, so
  two Variant operands (both runtime Floats) typed the first sum as `Int`, and a following Float op or
  `> 3.0` was rejected. Now it PRESERVES every possible result type: collects each capable member's
  result into a VariantType (1 -> that type, N -> Variant[..]). So `extract(1.5)+extract(2.5)+0.5`
  and the `->>` equivalent, then `> 3.0`, all type-check.
- S-B (native capabilities): VariantType only delegated arithmetic + comparison. Added the members'
  other native ops so a typed JSON value exposes them - caret, bitwise or/and/xor, shl/shr, and
  crucially logical or/and/xor (Boolean). So `(doc ->> 'flag') AND true` works.
- S-C (multi-path text): json_extract's static Variant return meant multi-path (always JSON array
  text) wasn't usable in text ops. Switched json_extract's return to a DynamicType resolver:
  several paths -> TextType, one path -> the typed-scalar Variant. So `CONCAT(json_extract(..,p1,p2),
  '!','?')` and text equality work, while single-path arithmetic still composes.
- S-D (`[#]` vs `[#-0]`): both parsed to FromEnd(0) and edit_at appended on every zero offset, so
  `json_set/json_insert('[1,2]','$[#-0]',3)` wrongly appended. Split PathSegment: added a dedicated
  `Append` for the literal `[#]`; `[#-N]` stays `FromEnd(N)`. `[#-0]` now resolves to the length
  (out of range) -> no-op; only `[#]` appends. resolve/resolve_mut/json_remove handle Append via the
  existing catch-alls (null / no-op).

TESTS (+21, 191 -> 212):
- T1 typed composition: extract_two_operands_reused, longarrow_two_operands_reused,
  extract_sum_then_compare (`> 3.0`), longarrow_bool_left_and, extract_bool_left_and,
  multi_extract_text_concat.
- T2 per-mutator index coverage: insert_existing_index_noop, insert_valid_from_end_noop,
  replace_ordinary_index, replace_hash_append_noop, replace_index_beyond_noop,
  replace_from_end_underflow_noop, remove_from_end_index, set_hash_zero_noop, insert_hash_zero_noop,
  extract_hash_zero_null.
- T3 pretty structural (fair, no full-string pin): pretty_has_line_break
  (`charindex(CHAR(10), json_pretty(...)) > 0`), pretty_line_indented (newline+space via
  `charindex(CONCAT(CHAR(10),' ',''), ...) > 0`).
- T4 null/error branches: type_resolved_json_null (`json_type('{"a":null}','$.a')` -> `null` tag, not
  missing), array_length_malformed_path_null, depth_invalid_doc_null.
Effective LOC 757 -> 813. Solution.patch 15 files. Local new 212/0, base 14/0. Docker 4-cell pending
fresh rebuild.

## Revision round 20 (aligned-tests WARNING: json_pretty formatting undocumented)
Non-blocking alignment WARNING: T3 pretty tests (pretty_has_line_break, pretty_line_indented - added
for Zeyad in round 19) assert a newline + space indentation, but meta only said "minified except
json_pretty". Documented it: closing sentence now reads "...output is minified except `json_pretty`,
which is space-indented and multi-line." States multi-line + space-indentation (not tabs) WITHOUT
pinning the exact width or full string, so it stays fair (earlier rounds rejected exact-byte pretty)
and makes the T3 tests prompt-stated. Paid for it by tightening "an updated member keeps its position"
-> "updates keep position" (still covers set/replace/patch update-position tests). meta 447 -> 448
words, ASCII, all paras < 150.
META-ONLY change: solution.patch and test.patch UNCHANGED, so all of Zeyad's v1/v2/v3 solution+test
points remain intact (verified prior documented clauses still present: bind-tighter-than-arithmetic,
only-`[#]`-appends, non-object-target-as-`{}`). No rebuild/4-cell needed (meta is not in the patches).

## Revision round 21 (Test Fairness: [#-0] under-specified + 3 advisory coverage)
Test Fairness FAIL 1/41: the three `[#-0]` tests (extract_hash_zero_null, set_hash_zero_noop,
insert_hash_zero_noop) - `n=0` not singled out in the prompt (could read as `[#]` or out-of-range).
CRITICAL: these tests + the `[#]`/`[#-0]` solution distinction were REQUIRED by Zeyad in round 19,
so per the user's "do not break Zeyad's points" instruction, did NOT remove/relax them. Instead
DE-TRAPPED by documenting: path grammar now reads "`[#-n]` the element `n` from the end, so `[#-0]`
is past-the-end and never appends." Now prompt-stated. META-ONLY change - solution.patch and
test.patch (behavior) unchanged, so every Zeyad point stays intact. Paid for the words by tightening
(select object members->select members, array element->element, moved "only [#] appends" into para 1
as "[#] the appending position", "the [#] forms are rejected"->"[#] forms rejected", "from its
arguments"->"from arguments"). meta 450 words (at cap), ASCII, all paras < 150. Prior clauses intact
(bind-tighter-than-arithmetic, out-of-range no-op, non-object-target-as-{}, space-indented-multi-line).
Advisory coverage suggestions added (per standing rule):
- arrow_text_literal_key / arrow_space_literal_key: a text RHS (`'a.b'`, `'a b'`) on `->` selects a
  literal member name, not a path parse (`'{"a.b":5}' -> 'a.b'` -> 5).
- contains_duplicate_candidate (`json_contains('[2]','[2,2]')` -> true): containment is set-like,
  not multiplicity-sensitive.
- pretty_deeper_indent (`charindex(CONCAT(CHAR(10),'  ',''), json_pretty('{"a":{"b":1}}')) > 0` ->
  true): a nested level is indented deeper (>= 2 spaces after a newline) - fair, width-agnostic
  (holds for any indent width >= 1 on a 2-level doc), addresses the deeper-nesting suggestion.
Tests 212 -> 216. Solution UNCHANGED. Re-validated: BASE new 216/216 fail e1; SOL new 216/0 e0;
SOL base 14/0 e0 (offline + non-root).

## Revision round 22 (Test-Quality WARNING: harness/CLI assumptions - INTENTIONALLY NOT ACTIONED)
Test Quality check PASSED overall (no-leakage OK, covers-behavior OK, focuses-on-behavior OK); the
only item is a NON-BLOCKING Sanity WARNING suggesting the meta declare the harness binary name
(gitql), CLI flags (-r/-q/-o csv), CSV handling, and helper functions (len/CONCAT/charindex).
DECISION: ignore - complying would HARM the submission:
- meta.md is a WHAT-description; naming the binary/flags/CSV harness = forbidden test-framework
  reference -> would fail the necessary-info (over-specification) and no-test-leakage checks (trading
  a non-blocking WARNING for a blocking FAIL).
- len/CONCAT/charindex/CHAR are PRE-EXISTING repo stdlib (docs/functions/string.md), not part of this
  JSON feature; this same fairness pass rated them "repo-discoverable". A JSON-feature description
  should not enumerate unrelated existing string functions.
- meta is at the 450-word cap; a Test-Assumptions section would blow it and force cutting real
  behavior docs.
Matches the earlier handling of this exact warning (user: "ignore"). No files changed - 216/0
validated state, all Zeyad solution/test points, and all fairness fixes stand.

## Revision round 23 (FALSE-POSITIVE PANEL: json_query pre-order gap in TEST COVERAGE)
Panel flagged the Orion pass as a false positive: Orion's collect_recursive_member pushed an object's
OWN matching member before recursing into earlier-positioned child subtrees, violating document
pre-order - json_query('{"a":{"b":1},"b":2}','$..b') gave [2,1] instead of [1,2]. The 216-case suite
missed it because the only descent case with an own+nested match ('{"a":{"b":{"b":9}}}') has the own
match BEFORE its nested child in document order, so the buggy order and pre-order agree there.
KEY: this is a TEST-COVERAGE gap, NOT a solution bug. The reference solution is CORRECT (interleaved
pre-order: for each member in document order, emit-if-match then recurse) - verified it returns [1,2]
/ [1,2,3] and the Python oracle agrees. So solution.patch is unchanged; test.patch adds the missing
discriminators.
Added 4 hidden cases where a match sits in an EARLIER sibling subtree and the parent has its OWN
later matching key (the class the panel named):
- jq_descent_earlier_sibling_preorder ('{"a":{"b":1},"b":2}' $..b -> [1,2]; buggy [2,1])
- jq_descent_multi_sibling_preorder ('{"a":{"b":1},"c":{"b":2},"b":3}' $..b -> [1,2,3]; buggy [3,1,2])
- jq_descent_own_between_siblings ('{"a":{"b":1},"b":2,"c":{"b":3}}' $..b -> [1,2,3]; buggy [2,1,3])
- jq_descent_star_earlier_sibling ('{"a":{"x":1},"b":2}' $..* -> [{"x":1},1,2])
Each discriminates the own-member-before-earlier-sibling-subtree bug. Tests 216 -> 220. Solution
UNCHANGED (correct + fuzz-validated). Meta unchanged ("in pre-order" already documented; panel
confirmed prompt-grounded). Re-validated: BASE new 220/220 fail e1; SOL new 220/0 e0; SOL base 14/0 e0.

## Revision round 24 (Test-Quality WARNING: pretty indent-width over-specification - relaxed)
Non-blocking WARNING (check PASSED overall): pretty_deeper_indent pinned newline + TWO spaces
(`CONCAT(CHAR(10),'  ','')`), reading as a 2-space indent-width mandate that meta doesn't state
(meta: "space-indented and multi-line", intentionally width-free since earlier rounds rejected
exact-byte pretty). Relaxed the needle to newline + ONE space (`CONCAT(CHAR(10),' ','')`) - still
verifies a nested doc is space-indented and multi-line, now width-agnostic (matches any indent >= 1).
Kept the immutable name (pretty_deeper_indent is in the submitted 216-set) - relaxed body only.
No other pretty test pins a width (the *_two_space names are round-trip checks, not byte pins;
confirmed grep 0). Pre-emptive: pretty width has been escalated advisory->unfair before, so relaxed
now rather than risk a future blocking FAIL. TEST-ONLY 1-char change; solution + meta unchanged;
no Zeyad point touched. Still 220 tests. Re-validated: BASE new 220/220 fail e1; SOL new 220/0 e0.

## Revision round 25 (HUMAN reviewer Zeyad, v3->v4: Tests 1/3, Solution 1/3; Description Clean 3/3)
Addressed all points (human review). Description unchanged (450 words).

SOLUTION & CODE:
- S1 (engine->gitql-std coupling): engine_evaluator called gitql_std::json::evaluate_json_access
  directly, adding gitql-std to gitql-engine's deps and bypassing the SDK's injectable std boundary.
  Fixed by ROUTING THROUGH THE ENVIRONMENT: added JsonAccessFunction type (gitql-core/signature.rs)
  + Environment.json_access_function field + with_json_access_function builder; the assembly
  (src/gitql/mod.rs) injects gitql_std::json::evaluate_json_access; the engine calls
  env.json_access_function (errors if unset). Removed gitql-std from gitql-engine/Cargo.toml (net-zero
  vs BASE - engine is decoupled again, so std can be swapped without pulling it back in).
- S2 (undocumented arities): json_keys/json_contains signatures accepted an optional path arg not in
  the task or the public function table. Removed the optional from BOTH signatures AND impls
  (json_keys now (X) only; json_contains (target, candidate) only). Verified the extra arity is now
  a signature error ("expects 1/2 arguments").

TESTS (+7, 220 -> 227):
- T1 (pretty false-positive path CLOSED): the newline/newline+space checks could be satisfied by
  "minified + trailing \n ". Added pretty_indent_before_member and pretty_indent_before_nested:
  charindex(newline+space) < charindex('"a"'/'"b"') - the indentation must come BEFORE a real
  serialized member, which the trailing-whitespace hack fails (verified hack -> false). Width-agnostic
  (any indent >= 1).
- T2a multi_extract_like: (json_extract(..,p1,p2)) LIKE '%2]' - proves a multi-path result supports a
  NATIVE text op (LIKE requires Text, unlike CONCAT which takes Any).
- T2b jq_descent_then_key: '$..b.x' - a step AFTER recursive descent ([1,2]).
- T2c set_boundary_index_noop / insert_boundary_index_noop: $[2] on a 2-elem array (exact past-end
  boundary) is a no-op, NOT append.
- T2d insert_multi_pair_append: json_insert('[1]','$[#]',2,'$[#]',3) -> [1,2,3] (left-to-right,
  dependent pair, outside json_set).
Effective LOC 813 -> 802 (json_keys/contains simplified; +env decoupling). Solution.patch 17 files
(+environment.rs, signature.rs, src/gitql/mod.rs). Local new 227/0, base 14/0. Docker 4-cell pending.

## Revision round 26 (Test-Quality WARNING: harness/CLI assumptions - RECURRENCE, still ignored)
Same non-blocking Sanity WARNING as round 22 (gitql binary/flags, CSV "Null" rendering,
CONCAT/CHARINDEX/LEN). All 3 required checks OK; overall "good quality". Reviewer explicitly praised
the round-25 pretty anchoring ("len/charindex-based ... without enforcing an exact whitespace schema,
which is appropriate"). Decision unchanged from round 22: IGNORE - documenting the harness in meta =
forbidden test-framework reference (would fail necessary-info/no-test-leakage, blocking); the helper
fns are pre-existing repo stdlib, not this feature; meta at 450-word cap. No files changed; 227/0 v4
state stands.

## Revision round 27 (Test Fairness: contains multiplicity under-specified + 2 advisory coverage)
Test Fairness FAIL 1/228: contains_duplicate_candidate (json_contains('[2]','[2,2]') -> true) - the
prompt said "each candidate element or member must be contained" without specifying multiplicity;
a multiset reading would return false. IRONY: this exact test was ADDED in round 21 at a PRIOR
fairness reviewer's advisory suggestion ("pin whether containment is set-like or multiplicity-
sensitive"). Not a Zeyad point. De-trapped by DISCOVERABILITY (document my set-like choice, keep the
immutable test): changed "must be contained" -> "must be present regardless of count". Now prompt-
stated. Paid for the words by trimming ("which is space-indented"->"space-indented"; "the nesting
depth"->"nesting depth"). meta 450 (at cap), ASCII, key clauses intact.
Advisory coverage suggestions added (per standing rule):
- op_arrow_invalid_doc_null / op_longarrow_invalid_doc_null ('nope' -> 'a' / ->> 'a' -> Null):
  operators follow the same null-on-invalid-document rule as the functions.
- insert_late_malformed_path_null / replace_late_malformed_path_null: a LATE malformed path forces a
  null result for json_insert/json_replace too (mirrors set_late_malformed_path_null across all three
  mutators).
Tests 227 -> 231. Solution UNCHANGED (behaviors already implemented; set-like containment was
already the impl). Re-validated: BASE new 231/231 fail e1; SOL new 231/0 e0; SOL base 14/0 e0.

## Revision round 28 (Test Fairness: operator null-on-invalid + 2 advisory coverage)
Test Fairness FAIL 1/47: op_arrow_invalid_doc_null / op_longarrow_invalid_doc_null ('nope' -> 'a' /
->> 'a' -> Null) - prompt assigned null-on-invalid to FUNCTIONS, not operators. IRONY (again): these
two tests were added last round (27) at the PRIOR fairness reviewer's advisory suggestion ("operator
invalid-document handling"). Reviewer-vs-reviewer. Not a Zeyad point. De-trapped by DISCOVERABILITY:
para 1 now reads "Functions AND OPERATORS consuming a JSON document return null when invalid" (+2
words, offset by trimming "a `$` path" -> "`$`"). Now prompt-stated; kept the tests. meta 450 (at cap).
Advisory coverage suggestions added (per standing rule):
- quote_escapes_quote (json_quote('a"b') -> "a\"b") and quote_escapes_backslash (json_quote('a\b') ->
  "a\\b"): json_quote escapes embedded quotes/backslashes, not just simple primitives.
- pretty_preserves_escaped_string (json(json_pretty(json_object('a','x"y'))) -> {"a":"x\"y"}): a
  pretty round-trip preserves escaped string content (built via json_object since GitQL's SQL lexer
  consumes a literal backslash-quote, so escaped content is constructed, not written as a literal).
Tests 231 -> 234. Solution UNCHANGED (operators already returned null on invalid input; behaviors
already implemented). Re-validated: BASE new 234/234 fail e1; SOL new 234/0 e0; SOL base 14/0 e0.

## Revision round 29 (DE-TRAP: 0/12 batch (3 Orion + 9 Nova) -> lift solvability, keep everything)
Platform batch on 234-test v4 = 0/12, ALL fair (agent_blame_unfair=false), near-misses (219-231/234,
missing 3-15). Reference passes all 234. Over-hardened by 28 reviewer rounds; solvability floor at
risk. Two dominant miss surfaces: (1) typed composition (VariantType integration), (2) json_query
recursive-descent ORDER. The descent discriminators (added rds 23/25 to close the panel's Orion
false-positive) are why Orion now fails - its descent order was wrong; now caught.
DE-TRAP LEVER = discoverability (the ONLY fair lever: agents fail these surfaces all-or-none, so
thinning tests doesn't lift the rate; and reducing a requirement would break Zeyad/panel). META-ONLY
change - no test/solution edits, so ALL Zeyad points (v1-v3 of v4), panel discriminators, and fairness
fixes stay intact. Made the json_query descent rules PRECISELY discoverable, targeting the exact
observed bugs:
- "includes root for `..*`" (Orion Run 3): "..* (every value)" -> "..* (every descendant value)"
  (root excluded).
- "wrong sibling order": "in pre-order" -> "in pre-order (earlier members before later)" - states the
  document-order-of-members rule agents miss (earlier member's subtree before a later member's match).
Paid for the words by trimming parentheticals ("member values or array elements"->"members or
elements"; "that member at any depth"->"at any depth"; "the integer `n`"->"integer `n`"). meta 450
(at cap), ASCII. Did NOT add a typed-composition hint: that surface is implementation-hard, not a
discoverability gap (agents know the requirement, can't build the type integration), so a hint costs
scarce words without moving the rate.
NEXT: re-run agents. Expect the descent-clarity to flip descent-failing near-misses (e.g. Orion Run 3,
226/234) toward legitimate passes. If still ~0 after a fair batch, the only remaining lever is
reducing typed-composition BREADTH (Zeyad's mandate) - needs explicit user approval.
No test/solution change; 234/0 v4 state unchanged (meta not in patches).

## Revision round 30 (FALSE-POSITIVE PANEL: json_contains f64 equality gap in TEST COVERAGE)
The de-trap (rd 29) worked: batch = 1/10, Orion PASS_LEGITIMATE (234/234). But the false-positive
panel flagged that Orion pass: its scalar_json_equals compares JSON numbers via
`l.as_f64() == r.as_f64()`, which collapses integers above 2^53, so
json_contains('9007199254740993','9007199254740992') wrongly returns TRUE. The 234-suite only tested
contains equality with small values, letting the f64 bug through.
KEY: TEST-COVERAGE gap, NOT a solution bug. The reference (my solution) uses STRUCTURAL equality -
contains() bottoms out at `target == candidate` (serde_json compares i64 exactly), so it returns
false for distinct large ints (verified: reference false, f64-bug true). solution.patch UNCHANGED;
test.patch adds the missing discriminators the panel named:
- contains_large_int_distinct_false (json_contains('9007199254740993','9007199254740992') -> false;
  f64-bug -> true) - the panel's exact case.
- contains_large_int_equal_true (equal large ints -> true) - control so the test isn't trivially false.
- contains_large_int_array_false / contains_large_int_array_true - the array-nested variant the panel
  said "discriminates the same way".
Each catches the f64-round-trip equality bug on in-domain i64 input. Tests 234 -> 238. Solution
UNCHANGED (structural == already correct). meta unchanged (450). Re-validated: BASE new 238/238 fail
e1; SOL new 238/0 e0; SOL base 14/0 e0.
NEXT: re-run agents. The de-trap keeps it solvable (~1/10); this discriminator only rejects the
specific f64-equality false positive, so a correct structural-equality solution (like the reference
and, likely, a careful Orion retry) still passes.

## Revision round 31 (HUMAN reviewer Zeyad, v4 of v5: Tests 1/3, Solution MINOR 2/3, Desc Clean)
Solution improved to 2/3 (Minor). Addressed all 4 test holes + the SDK gap.

SOLUTION (S-A, Minor):
- The injected JSON access callback wasn't in the documented SDK setup: Environment inits
  json_access_function=None, with_standard_functions doesn't install it, and the SDK assembly guide
  only registered the std/aggregation maps -> a consumer following the guide got every json_* function
  but `->`/`->>` failed at runtime. Since gitql-core cannot depend on gitql-std (that's the whole point
  of the round-25 decoupling), took the reviewer's second option: DOCUMENT + REGISTER the callback in
  the SDK assembly path (docs/sdk/assemble.md now shows
  `env.with_json_access_function(gitql_std::json::evaluate_json_access);` with a note that the
  operators fail at runtime without it).

TESTS (+13, 238 -> 251) - closed 4 contract-breaking verifier holes:
- T-A (null holes): every null case only compared the rendered cell `Null`, which the CSV printer
  renders identically to a TEXT "Null" - so an impl returning text for every invalid/missing result
  passed all 238. Added IS NULL controls: longarrow_jsonnull_is_sql_null_ctrl (`->>` on JSON null),
  extract_invalid/missing, set_invalid_doc, remove_malformed, plus extract_present_is_not_null_ctrl
  (false control). Text "Null" now fails IS NULL.
- T-B (pretty holes): the position checks reused the FIRST newline-space, so `{\n "a":{"b":1}}` passed
  while the nested object stayed minified, and no row required a nonempty array to be formatted.
  Added newline-COUNT structure checks (width-agnostic): pretty_nested_multiline (>2 newlines; the
  hack has 1) and pretty_array_elements_multiline (>2; forces each element onto its own line), plus
  pretty_array_element_indented (indentation anchored to an actual array element). Verified both
  reviewer hacks now FAIL.
- T-C: insert_multi_pair_append only checked output order. Added insert_repeated_target_first_wins
  (json_insert('{}','$.a',1,'$.a',2) -> {"a":1}): an impl testing presence against the ORIGINAL doc
  inserts 2 and fails; later pairs must observe earlier mutations.
- T-D: single-path text typing was only printed. Added extract_text_through_len,
  longarrow_text_through_len, longarrow_text_through_lower - passing single-path json_extract/`->>`
  through TEXT-typed consumers, so dropping Text from the declared variants now fails (the existing
  LIKE row covered only multi-path).
Effective LOC 803. Solution.patch 18 files (+docs/sdk/assemble.md). meta unchanged (450). Local new
251/0, base 14/0. Docker 4-cell pending rebuild.

## Revision round 32 (Test Fairness: pretty newline-COUNT over-specified + 2 advisory coverage)
Test Fairness FAIL 2/251: pretty_nested_multiline + pretty_array_elements_multiline (newline count
> 2). Reviewer: prompt only said "space-indented and multi-line", so pinning a line-break COUNT
over-specifies a formatting strategy. These are the tests I added LAST round to close ZEYAD's v4
pretty false-positive hole ({\n "a":{"b":1}} passing with the nested object minified). Classic
oscillation: Zeyad demands the hole closed, fairness calls the closure over-specified.
FIX satisfies BOTH, permanently:
1. RELAXED the two tests (immutable names kept, bodies changed) from a COUNT to a STRUCTURAL property:
   assert a newline exists BETWEEN the two members ("a".."b") / BETWEEN the two array elements (1..2)
   - i.e. each member/element is on its own line. No count, no width, no exact string pinned.
   Verified both of Zeyad's hacks still FAIL (nested-minified -> false; trailing-\n-space -> false),
   so his hole stays closed.
2. DOCUMENTED the layout so the assertion is prompt-stated: "...minified except `json_pretty`,
   space-indented with each member and element on its own line." Now fair by discoverability.
Advisory coverage added - and DOCUMENTED so they cannot be flagged next round (the recurring trap):
- op_arrow_bool_rhs_null / op_longarrow_float_rhs_null: a non-text/non-integer/non-`$` RHS yields
  null. Documented: operator RHS now reads "...or a path beginning with `$`, any other operand
  yielding null".
- remove_late_root_null / remove_late_malformed_null: json_remove with a LATER `$` or malformed path
  nulls the whole call even after earlier valid removals. Already prompt-stated ("null when a path is
  `$`" + malformed-path rule).
Paid for the +11 words by trimming (valueless lookup; returns it as; reports containment; past the
end; null when a path; null for a non-object). meta 450 (at cap), ASCII.
Tests 251 -> 255. Solution UNCHANGED. Re-validated: BASE new 255/255 fail e1; SOL new 255/0 e0;
SOL base 14/0 e0.

## Revision round 33 (HUMAN reviewer Zeyad, v5 of v5: Tests 1/3, Solution Minor 2/3)

TESTS (T3) - REAL LOGIC BUG I INTRODUCED, he is exactly right:
`charindex` returns 0 when the pattern is ABSENT, so `charindex(needle) < charindex(anchor)` is
0 < pos = TRUE. The three position rows therefore PASSED on output with NO indentation at all.
He proved it by replacing the reference formatter with arrays as `[\n1,\n2\n]` (elements on their own
lines, unindented) - all 255 stayed green. pretty_array_element_indented was the only row checking
indentation inside an array, so nothing caught it; the two object rows (pretty_indent_before_member,
pretty_indent_before_nested) had the same weakness and were only saved by the separate
newline-exists rows.
FIX: require the needle to be PRESENT in the SAME row that checks its position, for BOTH the array
and the object documents, so a zero cannot satisfy the comparison:
  charindex(NL+sp, D) > 0 AND charindex(NL+sp, D) < charindex(anchor, D)
Applied to pretty_array_element_indented, pretty_indent_before_member, pretty_indent_before_nested
(immutable names kept; bodies guarded). VERIFIED against his exact counterexample: the unindented
array has charindex(NL+sp)=0 -> old row TRUE (the bug), new guarded row FALSE (now caught). Reference
still passes all three.

SOLUTION (S2, Minor) - patch failed the repo's own CI (.github/workflows/ci.yaml):
1. `cargo fmt --all -- --check` (20 diffs) -> ran `cargo fmt --all`; now CLEAN.
2. `cargo clippy -- -D warnings` -> fixed following the repo's own precedent
   (gitql-ast/src/types/dynamic.rs, gitql-parser/src/type_checker.rs):
   - variant.rs: factored the closure types into public type aliases (CapabilityFunction,
     ResultFunction) to kill `type_complexity`, and added `#[allow(clippy::borrowed_box)]` on
     delegated_result (same as the repo does for `&Box<dyn DataType>` params).
   - json/mod.rs: `map_or(true, ..)` -> `is_none_or(..)`; `#[allow(clippy::borrowed_box)]` on
     value_to_json / parse_doc / evaluate_json_access (the `&Box<dyn Value>` params).
   Now CLEAN.
VERIFIED ON A FRESH `git archive BASE` + solution.patch TREE (what the reviewer runs):
  cargo fmt --all -- --check  : CLEAN
  cargo clippy -- -D warnings : CLEAN
(rustfmt/clippy were not installed locally; added via `rustup component add rustfmt clippy`.)

Tests still 255 (3 rows guarded, none added/removed). Effective LOC 829. meta unchanged (450).
Local new 255/0, base 14/0. Docker 4-cell pending rebuild.
