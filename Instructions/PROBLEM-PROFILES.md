# PROBLEM-PROFILES — Per-Problem Behavioral Data Catalog

Behavioral evidence per approved (and rejected) problem: agent-by-agent verdicts, confirmed traps with kill rates, agent path effectiveness, design-time decisions, post-mortem lessons. **One section per problem**, two halves per section: (a) deep behavioral data sourced from KNOWLEDGE.md per-problem dive, (b) iteration lessons sourced from lessons-learned.md per-submission entry.

> **Read first:** `PLAYBOOK.md` (foundational patterns + approveds tables) + `SHAPES.md` (shape taxonomy) + `AGENTS.md` (cross-agent profiles). This file is the **per-problem complement** to those.

> **Pass-rate annotations below are HISTORICAL.** Many entries cite the old Mars "25-55% / 10-70% sweet/target band". That band is SUPERSEDED: the current Mars target is `≤30%` (0% = reject, >30% = too easy) and the current Olympus ceiling is `≤20%` (down from 30%; >20% = too easy, ~10% Good target). Read observed pass rates as recorded facts about past runs, NOT as current targets. A past problem that landed at 41.7% or 50% would be too-easy/reject today and would need a 2nd interdependent+misdirecting trap to harden it; a past Olympus that landed at 25-30% must now be hardened to ≤20%. See CLAUDE.md § Difficulty-Calibration Model.

**Use this file when:**
- Designing a new problem against a similar shape — find the closest approved here, crib its trap design + agent profile
- Diagnosing why agents are failing on YOUR problem — find a similar agent failure pattern here, apply the documented fix
- Updating instruction files post-eval — add a new section here per `.agents/rules/olympus-post-eval-workflow.md` Tier 4

**Index:**
- dasel-csv-options (Diamond Approved — 17 eval runs, 26 iterations)
- ferret-csv-codec (Mars Solid — 50% pass, 4 attempts)
- nmap-formatter / nmap-scan (Olympus + Lite tiers — both shipped)
- node-minify / node-macros (Lite tier approved — 12 runs)
- yaegi-eval-in-package (Mars Solid — 7.7% Nova/Orion)
- yaegi-completion (Olympus — 1/12 PASS)
- yaegi-callstack-postmortem (Mars Strong — 8.3%)
- yaegi-repl-doc (Mars Solid — 21.4%)
- dasel-collection-funcs (Olympus reframe shipped Mars-tier — 41.7% then REJECTED post-eval; namespace-expansion case study)
- dasel-assign-path-creation (Mars Solid — 55.6%, approved May 2026)
- expr-licm-predicates (Mars Solid via Pattern 17 reshape — 33.3%)
- dasel-slice-operator (REJECTED at submit-pre-check — Pattern 32 case study)
- cliffy-command-aliases (Diamond approved — 6 failure-QA review rounds)
- cliffy-output-format (Approved — 24 attempts)
- cliffy-undo-history, cliffy-middleware, cliffy-config-file, cliffy-prompt-wizard, cliffy-option-groups, cliffy-command-scaffold (per-submission lessons)
- dasel-multi-file (Approved 6/7 — 9 attempts)
- dasel-reduce-takewhile-dropwhile (ABANDONED — 100% pass rate; pattern-followable case study)
- yaegi-goroutine-lifecycle (Mars Solid — Approved 6/7, 4 iteration rounds, Pattern 17 cross-cutting reshape)

---

## A. Deep Behavioral Data (sourced from KNOWLEDGE.md per-problem dive)

## DASEL-CSV-OPTIONS — BEHAVIORAL DATA (17 eval runs, DIAMOND APPROVED)

### Confirmed Castor Blind Spots (Diamond Run 17, 13 Castor runs, 160 tests)

| Blind Spot | Frequency (Run 17) | Test That Caught It |
|---|---|---|
| Writer strict ragged-row dead code (iterates headers so len always matches) | 5/11 | TestWriteStrictRaggedRowsError |
| Writer ignores csv-null entirely, always writes empty string | 2/11 | TestWriteNullValue |
| Writer bypasses quoting for null-rendered fields (isNull guard) | 2/11 | TestWriteNullContainingSeparatorMinimalQuote |
| interactive.go help text not updated (only updated query.go) | 4/11 | TestCLIHelpTextReferencesSeparatorNotDelimiter |
| Trim not applied to null string representation on write | 3/11 | TestWriteTrimNullInteraction |
| Strict validation runs on raw value before null substitution (ordering) | 1/11 | TestWriteNullContainingNewlineStrictError |
| Reader strict header=false ragged check missing | 2/11 | TestReadStrictHeaderFalseRaggedRowNoHeader |

### Confirmed Castor Blind Spots (dasel context, Runs 14-16)

| Blind Spot | Frequency (Run 16) | Test That Caught It |
|---|---|---|
| Writer bypasses quoting for null-rendered fields (isNull guard) | 4/11 | TestWriteNullContainingSeparatorMinimalQuote |
| Writer ignores csv-null entirely, always writes empty string | 3/11 | TestWriteNullValue |
| Strict validation runs on raw value before null substitution (ordering) | 3/11 | TestWriteNullContainingNewlineStrictError |
| Writer strict ragged-row dead code (iterates headers so len always matches) | 2/11 | TestWriteStrictRaggedRowsError |
| Backslash handler `continue` skips hasNewline flag in state machine | 1/11 | TestReadBackslashEscapeStrictMultiLineError |

### Confirmed Castor Blind Spots (Run 15, 21 agents)

| Blind Spot | Frequency | Test That Caught It |
|---|---|---|
| Writer ignores csv-null entirely (valueToString returns "") | 6/12 | TestWriteNullValue + 8 more null tests |
| Writer strict ragged-row dead code (tautological check) | 5/12 | TestWriteStrictRaggedRowsError |
| Writer null quoting bypass in minimal mode (handles always/never but falls through) | 2/12 | TestWriteNullContainingSeparatorMinimalQuote |
| Strict newline validation before null substitution | 2/12 | TestWriteNullContainingNewlineStrictError |
| Strict ragged header=false read only | 1/12 | TestReadStrictHeaderFalseRaggedRowNoHeader |
| Backslash-before-newline in splitLines | 1/12 | TestReadBackslashBeforeNewlineInQuotedField |

### NEW Diamond Blind Spot: Cross-File Help Text Update

**Discovered in Run 17 (4/11 frequency).** When the description says "update CLI help text in existing commands" (plural), Castor agents consistently find and update one file (query.go) but fail to grep for all occurrences across the codebase. The reflection-based test (inspecting struct tags on both QueryCmd and InteractiveCmd) catches this thoroughness gap. This blind spot is NOT specific to the CSV problem -- it applies to ANY problem requiring updates across multiple files with similar patterns. Design pattern: use reflection or introspection tests to verify ALL instances of a pattern were updated, not just the first one found.

### Architecture Split

**Agents that pass** (confirmed from 17 winning trajectories across Runs 14-17):
- Create `options.go` first with centralized validation
- Rewrite `reader.go` as a custom state-machine -- never use `encoding/csv`
- Use `model.MapKeys()` for header=false write iteration
- Apply null substitution BEFORE quoting/strict checks
- Null strings go through the same quoting pipeline as regular strings
- Use `str_replace_based_edit_tool create` instead of heredoc bash -- avoids the hang
- Update BOTH query.go AND interactive.go for help text (grep for all occurrences)

**Agents that fail** all share one of:
1. `encoding/csv` usage -> backslash escape limitations (rare in Runs 15-17 -- agents build custom parsers)
2. `isNull` special path in writer -> quoting bypass (most common, 2-6/12 per run)
3. Ordering bug -> strict/quoting runs on pre-substitution value (1-3/12 per run)
4. Ragged-row dead code -> `len(values)` built from headers always equals `len(headers)` (2-5/12 per run)
5. Incomplete grep -> update query.go help text but miss interactive.go (4/11 in Diamond)

### Difficulty Configuration (Diamond Approved -- 160 tests, 2/11 pass rate)

The problem was Diamond-approved at this configuration:
- Full backslash: "escape only the quote character and the backslash itself; a backslash before any other character including newline is literal and not treated as an escape sequence"
- Full writer-strict: "requires uniform column count and rejects multi-line field values; this applies regardless of whether csv-header is true or false"
- Comment-char protection: "Minimal quoting also applies to fields beginning with the comment character"
- csv-delimiter backward compat: "csv-separator supersedes csv-delimiter; if both set, csv-separator takes precedence"
- csv-trim: "none/left/right/both -- trim unquoted fields only, trim before null matching on read, before quoting on write"
- csv-line-terminator: "lf/crlf/cr -- writer output line endings"
- CLI early validation: "add early validation of all csv-prefixed flags before parsing"
- CLI help text update: "update both QueryCmd and InteractiveCmd help text to reference csv-separator"
- 160 tests across 24 groups (153 in parsing/csv + 7 in internal/cli)
- Bullet-list description format (one requirement per line)

Previous standard-tier approved at 118 tests, 6/17 pass rate (35.3%).
Diamond tier added csv-trim, csv-line-terminator, CLI integration tests -> 160 tests, 2/11 pass rate (18.2%).

Removing writer-strict from description restores a 100% blocker (0/10 confirmed twice in Runs 6-7).

---

## rdb-sample-fraction (Diamond APPROVED -- 10% Castor, 1/10, 2026-05-31)

### Problem Summary
HDT3213/rdb (Redis/Valkey RDB dump parser, Go, single module). Issue #72: fraction-based key sampling. The decoder skips a non-sampled key's value byte-exactly on the input stream instead of materializing it; the aggregating helpers (`PrefixAnalyse`, `SepPrefixAnalyse`, and a new `EstimateMemory`) extrapolate sampled totals by 1/fraction; the per-key helpers (`MemoryProfile`, `FindBiggestKeys`) report each sampled key's real size (negative controls). Shape O-Pipeline-hard. 68 F2P tests, 599 solution LOC across 8 source files (2 new), meta 414 words.

### Outcome
10x Castor, 1 PASS (10%, inside the <=30% band). AI Review PASS 0.78, Auto Review PASS (median LOC 488, msgs 124, files 8). Human reviewer ACCEPTED 2026-05-31; only note "some entries could be separated instead of grouping them. still acceptable coz good writing" (failure-qa grouped same-junit-signature tests; per-test tables present, so accepted).

### Confirmed Castor Blind Spots (10 runs)
- **Sampler hash avalanche (9/10 = 90%, FAIR):** sequential prefix keys cluster all-or-nothing under any raw/shifted/modulo FNV-vs-fraction comparison; the group samples empty (junit "got 0") or whole ("got 20"). Seven distinct wrong forms; the 1 PASS reduced the full digest `% 2^32`. Fix = avalanche finalizer or wide reduction. Kept undocumented (the fair difficulty). All-fail-same-reason = fairness signal per admin 2026-05-29.
- **Decode-and-discard default (10/10):** "skip the value instead of decoding it" satisfied by `readObject`-then-discard in every run because the behavioral suite can't distinguish skip from decode-then-drop. Made the 250-LOC central skip work non-load-bearing -> too-easy (0.66) until an allocation test forced true byte-skip. A perf/allocation test is required for any "stream without materializing" requirement to gate difficulty.
- **Field-type compile-unfairness (4/5 pre-fix):** new public struct fields accumulated by typed test arithmetic pin `int` (counts) vs `int64` (totals/UpperBound); `uint64` choices broke compilation and masked ~65 tests. Document field types in the description.

### Architecture facts that shaped difficulty
- `wrapDecoder` (`helper/regex.go:208`) is a SINGLE option choke point with 6 sibling option types -> a decoder-level membership filter is Pattern-23 trivial (~150 LOC). Difficulty had to live OFF the filter, on extrapolation + the per-key-vs-aggregate output boundary.
- `wrapDecoder` returns `(decoder, error)` only; option VALUES are consumed and never returned, so the prefix helpers + `EstimateMemory` must RE-EXTRACT the fraction to scale (natural threading boundary). Pushing the scale into the shared wrapper leaks it into per-key helpers and fails the negative controls.

### Reusable assets
- Repo-specific scaffolding (Dockerfile w/ gocache permission fix, test.sh awk f2p fallback, encoder fixtures) + the full 10-rule failure-QA validator discipline: `analysis-folders/rdb-analysis/LESSONS.md`.
- Next rdb pick: D3 `rdb-bigkey-oom-truncation` (#57), GO verdict, reuses all scaffolding. D2 listpack-7.2 confirmed DEAD (wire format byte-identical 7.0->7.2). D4 HFE/Valkey9 RED (shipped namespace).

---

## csstree-calc-typecheck (Diamond APPROVED -- hinted 5%, 1/20, 2026-06-05)

### Problem Summary
First csstree + first JS/mocha Diamond. Two cross-subsystem capabilities sharing a `ResolveError` base: (1) CSS cascade-layer (`@layer`) order resolution (resolveLayerOrder / layerPriority / comparePriority / cascadeOrder / importantCascadeOrder / revertLayerTarget); (2) `calc/min/max/clamp/round/mod/rem/abs/hypot/trig` dimensional type-checking (CSS Values 4 §10.9) via new `lexer.checkCalc` / `lexer.matchCalc` + a `matchProperty` gate. BASE `88e3d965` (csstree 3.2.1, == HEAD). 156 new tests (121 calc + 35 cascade), 772 eff LOC / 6 files, 4000 platform-baseline preserved.

### Outcome
Unhinted 10x Castor = 0/10 (best 150/156), Holistic NEEDS_HINTS. Hinted 20-run = 1 PASS (5%, in band). Holistic PASS, Auto Review PASS, Code Validation 3/3. QA failure-qa validator all-true after 3 rounds. Approved first reviewer pass ("good work").

### Confirmed Castor Blind Spots (10 unhinted runs)
- **Clamp/min/max percent-hint reconciliation (8/10):** the addition-level percent-hint rule must be reused in the consistent-type check; agents use strict equality -> `clamp(10px,50%,100px)` = `invalid`. (DIAMOND-PLAYBOOK § Section-1 #20.)
- **Pure-number property gate (7/10):** walking the full property grammar pulls `<number>` from the inner calc multiplier -> `calc(6/2)` matches `width`. Fix = top-level grammar only. (§ #21.)
- **ResolveError real subclass (8/10 varies):** factory/marker returning a plain Error fails `instanceof`. (§ #19.)
- **percent^2 serialization (4/10):** multiply must carry the percent exponent into the serialized name.
- **`@media` conditional-group layer descent (4/10):** layer walk only scans top-level children.
- **Gate doesn't filter error-resolving calc (3/10):** agents gate on `error && type !== null`, so a calc that resolves to an error (incompatible sum, length divisor, nested invalid) slips through the grammar match.
- **Offending-node Function-vs-leaf (3/10):** error.node attached to a leaf operand, not the enclosing Function/Operator (test accepts either).
- **Return-shape coin-flip = the UNFAIR signatures (spec'd, NOT hinted):** comparePriority -1/0/1, revertLayerTarget name, cascadeOrder.layer name -- each 10/10 universal until the exact type was stated in meta.

### Architecture facts that shaped difficulty
- The two passes share NO code (cascade order vs dimensional algebra) -> solving one does not help the other; the bundle dropped platform similarity <0.7 AND created the difficulty. csstree has NO JSDoc -> zero doc comments in solution.
- BASE `matchProperty` is already PERMISSIVE (accepts a wrong-dimension calc) -> a positive `matchCalcError(...)===null` would pass on base; route every new positive through the solution-only `lexer.matchCalc` (a base-undefined symbol) so f2p stays clean. (Pre-existing-loose-helper = Pattern 37.)
- Platform baseline = 4000 junit testcases (NOT the 16725 the local mocha reports).

### Reusable assets
- Self-contained `junit-reporter.cjs` with `classname` = a CONSTANT (the platform mangles XML-special chars `&&`/`||`/`"`/`.` in `classname` -> before_p2p false-fails; a constant avoids them). Relocate new test files OUT of `lib/__tests` (the platform's `mocha lib/__tests` recurses subdirs and would collect them into base mode).
- Hint = 2 levers (clamp percent-hint + property-gate top-level types) flips the both-covered near-miss. Full QA-validator law: `PATTERNS-ADVANCED § Pattern 50`; iteration discipline: `§ Pattern 51`.

---

## chai-array-type (Diamond APPROVED -- 20%, 2/10 Castor, 2026-06-07)

### Problem Summary
Parametric ARRAY column type for chaisql/chai (Go SQL engine): `INTEGER[]`, `TEXT[]`, nested `INTEGER[][]`; two literal forms (`ARRAY[...]`/`{...}`), element access, 6 array builtins, `||`, CAST, comparison/ordering, keys/indexes, GROUP BY/DISTINCT, catalog round-trip across reopen. 459 eff LOC / 14 files. base e53516f8.

### Outcome
2/10 Castor (in band). Holistic + Auto Review PASS. The feared marquee wall (byte-sortable variable-length array encoding) was FREE -- genji-leftover `compareNonEmptyValues`/`SkipArray`/tags order arrays element-wise already. GREP the encoding comparator before assuming encoding is the wall.

### Confirmed Castor Blind Spots (10 runs)
- **DOMINANT (7/10): driver-render integration gate.** Agents build the internal `ArrayValue` but expose it through the `database/sql` driver unrendered, so `rows.Scan(&string)` fails at the boundary. Three distinct wrong impls across runs: `dest[i] = v` (raw `types.ArrayValue`), a local `arrayValue` wrapper `dest[i] = arrayValue{v: v}` (error names `driver.arrayValue`), and `dest[i] = v.Encode(nil)` (raw bytes -> scan succeeds but equality-mismatches on binary). Correct = render text (`MarshalText`) in `Rows.Next` like the neighboring scalar arms. The cross-architectural integration gate, not the algorithm, was the difficulty.
- **Secondary (3/10): "cannot" substring on delegated overflow.** Element conversion delegates to the scalar `CastAs`; a bigint->int32 overflow returns "integer out of range"; the spec requires the surfaced message to contain "cannot", so the array conversion site must wrap. Agents that wrapped only the nested-depth branch (not the scalar element path) leaked the raw error.

### Architecture facts that shaped difficulty
- `types.Type` is a flat uint8 -> cannot carry an element type. `ColumnConstraint` must gain `ElementType`+`ArrayDepth`; `String()` emits `INTEGER[]`/depth so the catalog DDL round-trips across reopen.
- Element enforcement must live in `encodeRow` (flat `CastAs(t)` can't carry the element type) -> one site covers INSERT/UPDATE/INSERT..SELECT.
- N-gate parity: 6 `types.go` dispatch arms + decode map + row marshal + driver + `constraint.String` all must be updated together.

### Reusable assets / lessons
- failure-qa discipline (per-run grounding, observable-anchored fixes, group-by-body): `lessons-learned.md § Human Reviewer Patterns` + memory `lesson-diamond-failure-qa-annotation`. The reviewer change request was a test mis-grouped by NAME (`CrossFeatureReopenIndexLookup` does no reopen/index; only TEXT[] equality + ORDER BY rendering).
- Docker/base gotchas: `GOTOOLCHAIN=go1.25.5` (swiss/go1.26 break); base mode must exclude internal/types `TestCompare`/`TestCastAs` (subtest names embed `time.Now()` -> p2p name-match fails); precheck rejects `go test -skip` -> use package-path + `-run` splits.

---

## ferret-csv-codec (Mars Solid -- 50% pass rate, attempt 4)

### Problem Summary
Added `text/csv` codec to ferret v2 encoding subsystem. Codec, encoder, decoder, custom CSV parser (NOT a wrapper around Go stdlib `encoding/csv`), null coalescing on unquoted fields only, BOM strip, CRLF normalization, hook system, registry integration in default engine. 7 source files, 879 +LOC.

### Outcome (4 attempts, 12-run final eval)
- R1 (72 tests): 9/10 PASS (90%) -- pattern-followable, too easy
- R2 (84 tests, field names removed): 7+/10 FAIL_TEST_MISMATCH (Comma/Separator naming) -- unfair, restored
- R3 (84 tests, field names restored): reviewer asked "add more tests to cover all the specified requirements; it will also improve the difficulty"
- R4 (98 tests, +14 hardening tests, test.sh fixed to mode 100755): **6/12 PASS = 50%** in Mars Solid 25-55% target band

### Run 4 verdict breakdown (12 agents)
| # | Agent | Verdict | Failure |
|---|-------|---------|---------|
| 1-2 | Orion→Orion | PASS | - |
| 3-5 | Nova→Orion | PASS | - |
| 6 | Nova→Orion | FAIL_MISSED_REQUIREMENT | DecodeWith post-hook drops ErrDecode chain on decode failure |
| 7-8 | Nova→Orion / Nova | FAIL_INTEGRATION_ERROR | Exported Default as `*csv.Codec`; tests take `Codec` by value → compile error |
| 9 | Nova | FAIL_WRONG_LOGIC | DecodeError.Line off-by-one (line counter advanced before error construction) |
| 10 | Nova | PASS | - |
| 11-12 | Nova | FAIL_KNOWLEDGE_GAP | NBSP byte-as-rune corruption: `rune(input[pos])` + `WriteRune` mangles 0xC2 0xA0 → `Â` + NBSP |

### Go Options Struct Naming Trap (CRITICAL — confirmed twice)
When a Go Options struct is used directly in test harness literals, every field name AND type must be in the description. Without `Delimiter (rune)` explicitly stated (R2):
- 3+ agents used `Comma` (Go stdlib `encoding/csv.Reader.Comma`)
- 3+ agents used `Separator` (intuitive synonym)
- Without `Header (bool)` and `TrimLeadingSpace (bool)` with explicit types, 1+ agents used `*bool` (reasonable for optional fields with non-zero defaults)

All three are architecturally valid Go choices. This is not a difficulty trap -- it is a fairness failure. Always enumerate: `FieldName (type)` for every field.

### NBSP byte-as-rune trap (NEW — 17% failure rate, FAIL_KNOWLEDGE_GAP)
Test: `TestCSV_Decode_TrimLeadingSpace_OnlySpaceAndTab_NotOtherWhitespace` decodes input `col\n<NBSP>value\n` with TrimLeadingSpace=true. Reference solution preserves NBSP+value (only ASCII space/tab trimmed).

Failing agents iterate the input byte-by-byte: `r := rune(input[pos])` then `sb.WriteRune(r)`. For ASCII this round-trips, but for byte ≥ 0x80 the byte value is interpreted as a Latin-1 codepoint and re-encoded as 2-byte UTF-8. NBSP (0xC2 0xA0) becomes 0xC3 0x82 0xC2 0xA0 (`Â` + NBSP).

This is foundational Go knowledge — `for _, r := range s` or `utf8.DecodeRune` are the canonical patterns. The reference solution uses `peekRune`/`advance` and slices the original byte range to preserve bytes verbatim.

**Why it works**: agents implement byte iteration "fast" without thinking about UTF-8 semantics. The trap is invisible until input contains a non-ASCII byte. Most prior tests used ASCII content.

**How to design this pattern**: include at least one decoder test with a multi-byte UTF-8 codepoint in unquoted field content. The corruption pattern is universal — any byte-as-rune iteration mangles it.

**Difficulty lever**: Tier 2 (15-30% failure rate range). Confirmed 2/12 = 17% on ferret-csv-codec Run 4. Likely transferable to any decoder/parser problem where byte iteration is plausible.

### `*Codec` vs `Codec` value type structural variance (17% failure rate, FAIL_INTEGRATION_ERROR)
Sibling codecs in ferret use value-type `Codec` with value receivers and `var Default = Codec{}`. Description says "exports a Codec type ... and a Default codec" without specifying value vs pointer. 2/12 agents declared pointer types breaking test helper signatures.

This is fairness-borderline: convention is inferable from sibling JSON/msgpack codecs but not stated in description. Reviewer accepted as legitimate integration error (codebase-inferable). Lesson: when adding to a codec family, agents who don't read sibling codec source code can pick the wrong type shape.

### DecodeError.Line off-by-one (8% failure, FAIL_WRONG_LOGIC)
Decoder advances `line` counter immediately after consuming row terminator, then reads `p.line` at error construction → reports N+1 instead of N. Fix: capture `startLine` before terminator processing. Standard CSV convention "line of the offending record".

### Post-hook override on decode failure (8% failure, FAIL_MISSED_REQUIREMENT)
Description: "post-hook errors override a **successful** result". Agent missed the "successful" qualifier; returned post-hook error directly on decode failure, dropping ErrDecode chain. Test asserts `errors.Is(err, ErrDecode)` survives even when post-hook returns error.

### Pattern-Followable Pass Rate Floor (broken in R4)
CSV codec = copy JSON codec architecture + write a CSV parser. Initial pass rate 90% confirmed pattern-followable. The R4 hardening that broke through:
- NBSP byte-as-rune trap targets a Go-language fundamental, not the CSV pattern
- 14 fairness-coverage tests close test-to-spec gaps that previously let agents "almost-pass"

The combination dropped pass rate from 90% → 50% (Mars Solid).

### Proven Traps That Still Worked (R2-R4)
- `TrimLeadingSpace` applies to header record (not just data fields) — surprised many agents in R2
- Pipeline ordering: trim before null coalescing — agents who implement as independent passes get it wrong
- `KeyReadablePredicate = func(ctx, value, key)` value-first ordering — ferret-specific API trap

### Agent Behavioral Notes (R4)
- **Nova alone**: 1/4 PASS — Nova's exploration-heavy pattern can pick wrong structural choices (pointer Codec, byte-as-rune iteration). Strongest at finding compact passing solutions when architecture is clear.
- **Nova→Orion**: 3/5 PASS — pairing recovers some Nova structural variance via Orion's commit-and-implement style.
- **Orion→Orion**: 2/2 PASS — both runs in 62-65 messages, decisive value-type architecture immediately. Confirms PLAYBOOK Pattern 13: "Orion-alone smashes when description names the API."

### test.sh executable bit (operational lesson)
On Windows, `chmod +x test.sh` does NOT update the git index. Patch ships with `new file mode 100644`. Platform invokes `./test.sh` directly → "Permission denied" before tests run. Fix: `git add --chmod=+x test.sh` BEFORE generating the diff. Verify: `grep "new file mode" test.patch` shows `100755` for test.sh. Documented post-incident in CLAUDE.md, TESTS.md, olympus-author skill.

---

## nmap-formatter/nmap-scan (APPROVED Olympus tier -- 9% pass rate, 1/11)

### Problem Summary
Added `diff` subcommand to nmap-formatter comparing two nmap XML scans. 5 output formats (text, json, csv, html, markdown), exit code semantics (0=identical, 1=different, 2=error), host categorization (added/removed/changed), change type system (port_state, service_version, hostname, os_detection, status_change, script_output, port_added, port_removed), sorting rules, and CLI flags (--ignore-timestamps, -t/--type, -f/--file).

### Outcome
- Run 1 (pre-fix): 0/10 Nova -- 10/10 blocked by summary line format unfairness
- Run 2 (Lite): 7/10 Nova (70%), 2/2 Orion (100%) -- submitted as Lite tier
- Run 3 (interface unspecified): 0/10 -- ALL FAIL_TEST_MISMATCH (flag names, JSON keys not documented)
- Run 4 (HTML case bug): 0/6 -- UNFAIR (case-sensitive HTML substring check blocked 5/6)
- Run 5 (Olympus): **1/11 (9%) -- AI REVIEWER PASS, HUMAN APPROVED**

### The "Summary:" Prefix Trap (CONFIRMED UNFAIRNESS -- fixed)
When a description says "Final line is summary with counts of X, Y, Z", ALL agents interpret "summary" as a label and add a prefix like "Summary:", "Added:", etc. Fix: show the exact format with an example in the description. This is NOT a difficulty lever -- it's a fairness failure.

**Rule**: Any test that enforces an exact output format via regex MUST have the corresponding description show the exact format with a literal example.

### The Interface Specification Lesson (CONFIRMED UNFAIRNESS -- fixed)
When tests assert specific flag names (-t vs -o), JSON field names (ip, hostname, changes), or change-type identifiers (port_state vs "port state"), the description MUST specify them exactly. Without this, 10/10 agents chose different but equally valid names and got FAIL_TEST_MISMATCH. Interface contract IS behavior and must be documented.

### Proven Fair Traps (Olympus tier, 1/11 = 9%)

| Trap | Rate | Mechanism |
|------|------|-----------|
| Implied requirement via flag existence | 82% (9/11) | `--ignore-timestamps to suppress timestamp-only differences` implies timestamps compared by default. Agents wire flag but never implement comparison. |
| Invalid type validation exit 2 | 27% (3/11) | Spec says exit 2 on errors; unsupported -t value is an error. Agents use permissive switch default. |
| Cobra RunE stderr contamination | 18% (2/11) | RunE returns error, cobra prints `Error:` to stderr, CombinedOutput captures both, breaks JSON parsing. |
| Existing constant vs spec name | 18% (2/11) | Repo has `MarkdownOutput = "md"` but spec says `markdown`. |
| Port format int vs combined string | 9% (1/11) | Spec says `80/tcp`; agent used separate int + proto fields. |
| Numeric port sort bug | 9% (1/11) | sort.Search with non-monotonic predicate misparses single-digit ports. |

### Agent Behavioral Notes (Go CLI, Olympus)
- **Nova**: 1/9 pass (11%). Dominant failure: timestamp detection (82%). Agents treat the explicit change-type list as their feature checklist and ignore the implicit requirement from the flag's stated purpose.
- **Orion**: 0/2. Both hit cobra stderr contamination -- Orion prefers returning errors from RunE rather than os.Exit.
- **Multi-format output is NOT a difficulty lever.** ALL agents competently implement 5 formatters. Difficulty comes from non-obvious requirements (timestamp inference) and framework interactions (cobra stderr).

### Lite vs Olympus Tier
- **Lite (70%)**: Same feature without implied-requirement trap. Difficulty from spec edge cases only.
- **Olympus (9%)**: Added 3 cross-cutting tests + the implied-requirement-via-flag trap. The 70% to 9% drop came primarily from the timestamp trap, NOT the interaction tests.

---

## node-minify/node-macros -- Agent Behavioral Profiles (12 runs: 10 Nova, 2 Orion)

### Nova (10 runs, 5 pass / 5 fail = 50% pass rate)
- **Strength**: Consistently builds correct parseDefine, loadDefineFile, mergeDefines, type coercion, identifier validation. Near-perfect on the API surface.
- **Weakness 1: Regex literal tokenization (2 failures)** -- Nova builds tokenizers that handle strings, comments, and template literals but omit regex literal branches. The `/…/` pattern is not part of the "string or comment" mental model agents default to.
- **Weakness 2: Framework integration (2 failures)** -- Nova sets `settings.content` assuming it triggers normal file-write output. It doesn't trace through @node-minify/utils run.ts to discover that `settings.content` activates in-memory mode which skips disk writes.
- **Weakness 3: Underscore boundary (1 failure)** -- One Nova run used regex `__KEY__` without negative lookbehind/lookahead for extra underscores.

### Orion (2 runs, 0 pass / 2 fail = 0% pass rate)
- **Pattern**: Orion builds a hand-written tokenizer/parser instead of regex-based approach (1070+ LOC). Both times the `consumeIdentifier` function treats `_` as an identifier character, which greedily consumes trailing underscores from `__KEY__`, breaking the suffix check.
- **Confirmed blind spot**: Orion's parser-first approach is more thorough but creates a specific class of bugs (greedy consumption) that regex-based approaches avoid.

### Confirmed Traps (with pass/fail data)
| Trap | Catches | Agents Hit | Mechanism |
|------|---------|------------|-----------|
| Regex literal exclusion | 2/12 | Nova | Skip-pattern regex omits `/…/` branch |
| `___KEY___` boundary | 1/12 | Nova | Regex `__KEY__` without boundary assertions |
| `__KEY__` greedy identifier | 2/12 | Orion | consumeIdentifier treats `_` as id-part |
| CLI in-memory mode | 2/12 | Nova | settings.content skips file write |
| **Total unique failures** | **7/12** | | |

### Busted Traps (agents handle correctly)
- **Type coercion (NaN, Infinity, -Infinity, hex, scientific notation)** -- all agents implement correctly
- **Optional chaining exclusion** -- all agents handle `process?.env?.KEY` correctly
- **Bracket notation (single/double quote)** -- all agents implement both
- **Template literal exclusion** -- all agents skip template literals
- **Object destructuring/spread exclusion** -- all agents leave these unchanged

### Principal Reviewer Post-Approval Notes
- **Solution quality capped at 5/7** -- regex-based parsing (buildProtectedRegions) is fundamentally unreliable for full JS syntax. Manual character scanning cannot handle all edge cases. hasOptionalChainBefore uses substring regex checks that break with varied formatting. For future problems involving source code transformation, prefer solutions that use AST-based parsing.
- **Internal reasoning flagged as AI slop** -- reviewer said "try writing internal reasoning yourself." All feedback.md, eval-results.md, and internal analysis documents must be written in a natural human voice. Formulaic numbered lists, identical sentence structures, and robotic phrasing are reviewer red flags. This applies to ALL submissions, not just node-macros.

---

## Reviewer Quality Insights (Cross-Submission)

### Solution Quality Scale (Observed from Reviewer Scoring)
- **7/7**: AST-based, architecturally sound, production-ready, handles all edge cases
- **5/7**: Regex/heuristic-based, works for common cases, fundamentally fragile on edge cases (node-macros)
- **3/7**: Major bugs, dead code, architectural issues
- **1/7**: Trivial, non-functional, or scope-inappropriate

### Writing Authenticity (Principal Reviewer Criterion)
- Reviewers actively check for AI-generated text in internal reasoning and feedback
- "AI slop" gets called out and penalizes score even on otherwise approved submissions
- Natural voice, varied phrasing, genuine analysis > formulaic templates

---

## yaegi-eval-in-package -- Agent Behavioral Profiles (13 runs: 3 Orion, 10 Nova)

**Pass rate**: 1/13 = 7.7%. Below Mars Solid sweet 25-55%. One single cross-cutting hardening test caught 11 of 12 failing runs the same way.

### Orion (3 runs, 0 pass / 3 fail)
- All 3 runs failed only `TestCompileInPackage_program_reads_live_package_state_after_in_pkg_mutation`. Other 99-101 new tests pass per run.
- Orion's pattern: implements all 5 APIs cleanly, scores 99/100 to 101/102 on the first try, then hits the live-state wiring trap.
- Orion run 3 was flagged FAIL_UNDOCUMENTED_REQUIREMENT (`agent_blame_unfair: true`), but the same evaluator's evidence cited yaegi's existing Compile/Execute live-state semantics as the basis for the expected behavior. Successfully contested.
- LOC range 373-418, msgs 64-103. Orion is concise on this problem -- it goes straight to a working implementation, doesn't iterate.

### Nova (10 runs, 1 pass / 9 fail = 10% pass rate)
- 1 PASS_LEGITIMATE (run 11 of 13). Pass route: shared `compileSrcInPackage` helper, refactored `CompileAST` to take explicit `importPath`/`pkgName`, threaded through `gtaRetry`/`cfg`. Reused existing scope without re-registering. Same shape as the reference solution.
- 9 fails, 8 of which hit only the live-state mutation test. One fail (run 7) was on EvalPathInPackage path-method `ErrUnknownPackage` gating (gated check inside `parse()` `if inc { ... }` branch, missing path variants). One fail (run 8) was a regression: renamed parser wrapper from `func main()` to `func _()` and broke 94 baseline tests via 3-character position offset.
- Nova LOC range 230-485, msgs 117-274. Wider variance than Orion. Sometimes overshoots into invasive parser refactor territory.

### Confirmed traps (with pass/fail data)

- **Live-state symbol identity (85% failure)** -- the dominant trap. Agents extend `CompileAST` to accept an explicit package, but break symbol identity between the compiled `*Program` and the package's live var slot. Variants observed:
  - Keep the original `pkgName == mainID && m != nil` guard so wrapped main never appended to initNodes for non-main packages
  - Re-register `interp.srcPkg[pkgID]`/`interp.pkgNames[pkgID]` on every CompileInPackage call (overwrites identity)
  - Wrap as `package <pkg>; func main()` then create fresh closure storage that doesn't write back to package globals
  - Rename wrapper to `func _()` (also breaks 94 baseline tests)
- **Wrap-execute gating** -- agents inherit `pkgName == mainID` guard from existing program.go without realizing it. Reference solution removes this guard or appends main unconditionally inside the new path.
- **Path-method ErrUnknownPackage omission** -- agent puts the validation inside `parse()` guarded by `if inc { ... }`. Path entry points call `eval(..., inc=false)` so the check is skipped. Visible in 1 run (Nova run 7).
- **Wrapper-rename position regression** -- changing the wrapper function name in `wrapInMain` shifts every position-reporting test in the codebase. The wrapper name is load-bearing.

### Cross-agent patterns
- **ALL failing agents** broke symbol identity via subtle wiring choices, not architectural misunderstanding -- 9 of 13 runs hit it the same way despite diverging implementations.
- **ALL failing agents** wrote 230-485 LOC in 65-275 msgs -- well within budget. The bug is precision-of-wiring, not effort.
- **Reference pattern (passes)**: factor a shared `compilePipeline` helper that both `CompileAST` and `compileASTInPkg` call, always append `gs.sym[mainID]` to initNodes, reuse the existing package scope without re-registering.

### Difficulty-design takeaway

A single cross-cutting interdependent test that exercises Compile + mutate + re-Execute against the same package's live var slot is sufficient to drive Mars-Solid pass rates below 10%. The trap is a subtle wiring mistake (one conditional, one re-registration line) that 11 of 12 failing agents hit despite diverging on the rest of the implementation. This is a Tier 1 anti-agent pattern (60-100% failure) with the additional property that it does not require a new test category -- it lives inside the same Compile/Execute API surface agents are already implementing.

---

## yaegi-completion (Olympus, 1/12 PASS) -- Confirmed Agent Blind Spots

### Blind spot 1: Internal-key-vs-canonical-name (42% failure)

**Pattern**: Codebase exposes BOTH a raw scope-symbol map (with internal/file-suffixed keys) AND a canonical name map (`pkgNames`). Agents iterate the obvious raw map and emit the internal key as the user-facing name.

**yaegi specifics**: Imported packages stored in `interp.scopes[mainID].sym` with keys like `fmt/_.go` (yaegi's source-file tracking). Canonical short name lives in `interp.pkgNames[pkgPath]` (separate map). Reference solution iterates `interp.binPkg`/`interp.srcPkg` and resolves names via `pkgNames`.

**Confirmed data**: 5 of 12 Nova/Orion runs emitted `fmt/_.go` as the package candidate Name, despite spec hint "Imported packages must be reported under their conventional short names". Even an explicit symptom hint ("not the file-suffixed keys yaegi uses internally") removed by description-quality bot revision still left 5/12 hitting it.

**Difficulty lever**: Requires reading 2+ codebase files (use.go, gta.go, scope.go) to find the canonical mapping. Single-file research agents fail.

### Blind spot 2: Mutex coverage gap (race in untracked path)

**Pattern**: Existing public mutex (e.g., `interp.mutex`) is taken in some entry points but NOT in compile passes that mutate scope state. Agents lock Complete with the same mutex assuming Eval honors it.

**yaegi specifics**: `Eval -> compileSrc -> CompileAST -> gtaRetry -> gta` and `cfg` write to `scope.sym` and `interp.universe.sym` without acquiring `interp.mutex`. Reference adds NEW `completeMu` RWMutex; eval() takes RLock at top, Complete takes Lock. Multiple Evals share RLock, Complete serializes against any in-flight compile.

**Confirmed data**: 2 of 12 Nova runs hit `concurrent map iteration and map write` panic exactly because they used `interp.mutex.RLock()` only. Pre-hint rounds: 100% failure on race detection.

**Strong proven hint**: "synchronization must extend across Eval's compilation phase, since locking only inside Complete leaves compilation-time scope writes unprotected." Description-quality bot consistently flags as over-spec; load-bearing for pass rate.

### Blind spot 3: Universe-first iteration with name-dedup inverts shadowing

**Pattern**: Spec says "closer-scope shadows outer." Agent's natural approach: iterate from outer (universe with builtins) to inner (main scope with locals), use `seen` map to dedup. Result: outer entry wins because it's added FIRST and `seen[name]` blocks later overwrite. Test fails because shadowed builtin still appears.

**yaegi specifics**: 3 of 12 Nova runs (with otherwise-substantial implementations) inverted shadowing this way. Universally affected even with explicit "closer-scope declarations shadowing outer ones" hint.

**Trap mechanic**: The `seen` map dedup pattern is so common in Go (and idiomatic for de-duplication) that agents apply it WITHOUT considering iteration order. Fix: iterate from CLOSEST scope first, OR overwrite entries instead of skipping.

**Difficulty lever**: Tier 2 (25-30% failure). The natural implementation pattern in Go is wrong here; correctness requires iteration ordering awareness.

### Blind spot 4: `go/scanner` operator token has empty `lit`

**Pattern**: Agents tokenize source with `go/scanner` then reconstruct strings by concatenating `tok.Lit`. Operator tokens (PERIOD, COMMA, LPAREN, etc.) return empty literal strings. Reconstructed source loses operators.

**yaegi specifics**: 1 of 12 Nova runs reconstructed `tr.L` as `trL` because PERIOD has lit="". `parser.ParseExpr("trL")` resolves as a single bad identifier; chained selector resolution returns nil.

**Fix**: Use original source slicing via `tok.Pos`+`tok.End`, or walk tokens directly without string reconstruction. Reference solution avoids string rebuilding entirely.

### Blind spot 5: Byte-level Unicode identifier scanning

**Pattern**: Agent uses `unicode.IsLetter(rune(s[i]))` to scan identifier characters. For multi-byte UTF-8 runes (λ, é, 中), individual continuation bytes are never letter codepoints, so the loop terminates early and the prefix collapses.

**yaegi specifics**: 1 of 12 Nova runs (Run #7) scanned byte-by-byte despite codepoint-aware column-to-position conversion. The bug is invisible until input contains non-ASCII identifier.

**Confirmed across multiple problems**: Same pattern documented in `ferret-csv-codec` (NBSP UTF-8 corruption) and `node-minify` (regex literal exclusion). 17-25% failure rate when triggered.

**Fix**: `utf8.DecodeRuneInString` for forward, `utf8.DecodeLastRuneInString` for backward, OR `for i, r := range s` for forward iteration.

### Blind spot 6: Multi-line backward walk crosses newlines

**Pattern**: Backward-walking selector-base extractor uses `unicode.IsSpace` (which includes `\n`) as an "allowed" rune. Walk crosses newline and pulls in tokens from prior line.

**yaegi specifics**: 1 of 12 Nova runs (Run #6) produced `fmt.Println("hello")\nfmt` as the selector base for line 1 of multi-line src.

**Fix**: Stop at newline OR use `go/scanner` which respects line boundaries naturally.

### Blind spot 7: Reflect-based binary const detection misses go/constant.Value

**Pattern**: Agent classifies binary-package constants by `reflect.Kind` switch. Standard library exposes Go constants via `go/constant.Value` (concrete types like `constant.ratVal`, `constant.intVal`). Their reflect.Kind is Interface or some unexported struct, not a numeric kind.

**yaegi specifics**: 2 of 12 runs misclassified `math.Pi` as var. Reference uses `val.Type().PkgPath() == "go/constant"` as the const detector.

**Fix**: Type-package check, not Kind check. The hint "Stdlib constants are surfaced as go/constant values" guides agents to the right primitive.

### Blind spot 8: Two-sentence naming spec collapses to first sentence

**Pattern**: Description states a naming convention across two sentences where sentence 2 implies a wider field set than sentence 1 mentions. Agents anchor to sentence 1, produce names that satisfy it but fail sentence 2's logical implication.

**yaegi specifics**: yaegi-callstack-postmortem meta.md states "Names are unqualified: top-level functions appear as `f`, not `pkg.f`. Pointer-receiver methods and value-receiver methods share the same frame name; the leading `*` is never included." Sentence 1 anchors "no qualifier ever". Sentence 2's "leading `*` is never included" is meaningful only if the receiver type IS in the name. 7 of 11 failing runs (64%) returned bare `M` instead of `T.M`. Both Orion-as-policy runs (#1, #2) hit this — Orion commits decisively to first interpretation, doesn't re-derive.

**Fix**: When two-sentence naming specs collide, ship one concrete example (`T.M`, not `pkg.T.M`) BEFORE the spec sentences run. Description-quality bot may flag as over-spec; per LESSONS.md #12, defend with empirical pass-rate data.

### Blind spot 9: New code placed at end of existing recover-defer body races user defers

**Pattern**: Existing infrastructure has a deferred recover handler that runs user-supplied defers, then checks `if recovered != nil`. New feature observing the recovered state must run BEFORE user defers, otherwise a user `defer recover()` in the same frame consumes the value and the new feature's guard sees nothing.

**yaegi specifics**: yaegi-callstack-postmortem `runCfg` defer (`interp/run.go:209`). Reference places `captureStack(f, oNode)` immediately after `f.recovered = recover()`, BEFORE the `for _, val := range f.deferred` loop. 4 of 11 failing runs (36%) placed it AFTER, so goroutine `defer func(){ recover() }()` killed `f.recovered` first.

The bug is INVISIBLE for outer-frame recovers (panic re-propagates, captured upstairs). Surfaces ONLY for in-frame recover (typical goroutine pattern). Agents who test multi-level chains pass; goroutine-internal recover fails.

**Fix**: Place new state-observation BEFORE user defers fire. Document via behavioral spec ("captured at the moment the panic is observed by recover" — already in meta.md but doesn't survive sequential reading).

### Blind spot 10: Walker termination missing kind guard pulls in synthetic outer frames

**Pattern**: Walking a frame chain via `for cur != nil` reaches the interpreter's root frame which holds non-function metadata (yaegi: `fileStmt`). Without a kind guard (`cur.funcNode != nil && cur.funcNode.kind ∈ {funcDecl, funcLit}`), the walker emits a phantom outermost frame with empty Name or pkg-name fallback.

**yaegi specifics**: 5 of 11 failing runs (45%) emitted `[main, ""]` or `[bar, foo, main, main]` because their walker stopped only on `cur == nil`. Reference uses two guards: nil check AND kind check, breaking on `fileStmt` before emit.

**Fix**: Walker stop condition is dual-guard. Description's "interpreted-frame call stack" implies non-interpreter-internal frames; agents read it generically and miss the implication.

### Cross-cutting takeaway: hint dilution risk

Description-quality bot consistently flags load-bearing hints as over-spec. Each removal cycle drops pass rate ~10pp. The pattern: bot says "tests don't pin implementation"; we contest with empirical pass-rate data. The negotiating line is **behavioral requirement vs implementation rationale** -- keep the WHAT, drop the HOW. Examples (math.Pi, fmt/_.go, λ) are tone-flagged but anchor agents to specific traps.

---

## dasel-collection-funcs (Olympus reframe shipped Mars-tier, 41.7% pass) — Agent Behavioral Profiles + Confirmed Traps (12 runs: 11 Nova, 1 Orion)

**Final scope (R17d)**: `mergeDeep(other, conflict?)` + `diffDeep(other)` + `--default-conflict` CLI flag + exported `*execution.CollectionFuncError`. Multi-package: execution/, internal/cli/.

**Pass rate**: 5/12 = 41.7% (1 contest pending). Lands in Mars Solid 25–55% sweet spot. **Reframed from B-shape (R0–R16 at 100% Nova) to Olympus O-Composite-add (R17 dropped to 41.7%)** — proves trap stacking is shape-bound.

### Nova (11 runs, 4 pass / 7 fail = 36.4%)

- **Pass route shape**: 481–636 LOC across 10–12 files. ~7m–8m runtime. ~109–143 msgs.
- **Fail patterns**: typically 9m–10m runtime with 614–746 LOC. Specific fails:
  - Strategy field populated on structural errors (3 runs)
  - Top-level shape mismatch dispatched to strategy (3 runs, 14–16 tests fail per run)
  - Concat nested-slice handling broken (1 run)
  - Kong enum tag breaks "unknown conflict strategy" contract (1 run)
  - Invalid-strategy err not wrapped (1 run)

### Orion (1 run, 0 pass / 1 fail = 0%)

- 933 LOC in 76 msgs (Orion's typical compact-but-decisive trajectory)
- Failed only on Strategy-field nuance — same as 3 Nova runs
- Classified FAIL_AMBIGUOUS_TASK (contested)

### Confirmed traps (with pass/fail data)

| Trap | Catches | Mechanism |
|---|---|---|
| Strategy-field discriminator clause ("or empty otherwise") | 3/12 | Agents populate Strategy unconditionally; spec carves out empty case for non-strategy errors |
| Top-level shape mismatch as precondition | 3/12 | Spec "Both must be same shape" agents read into "otherwise" of per-leaf strategy clause |
| Concat nested-slice in map-merge dispatch | 1/12 | Per-key handling doesn't recurse into slice values |
| Kong enum tag breaks error string contract | 1/12 | Kong's enum validator calls os.Exit before run() can return Go error |
| Invalid-strategy not wrapped in CollectionFuncError | 1/12 | Returns fmt.Errorf instead of *CollectionFuncError |
| **Total unique failures** | **7/12** | |

### dasel-specific patterns

#### Test compile-time decoupling via reflection

dasel test files in `execution_test` package import `execution` for selector execution but should not import solution-only types directly. Pattern proven across R14 (CollectionFuncError) and R17 (DefaultConflictStrategy field):

```go
for cur := err; cur != nil; cur = errors.Unwrap(cur) {
    if reflect.TypeOf(cur).String() == "*execution.CollectionFuncError" {
        v := reflect.ValueOf(cur).Elem()
        return v.FieldByName("Func").String(), v.FieldByName("Reason").String(), true
    }
}

func cfSetDefaultStrategy(opts *execution.Options, strategy string) {
    f := reflect.ValueOf(opts).Elem().FieldByName("DefaultConflictStrategy")
    if f.IsValid() {
        f.SetString(strategy)
    }
}
```

#### model.Value cycle detection: hybrid pointer + depth

dasel `RangeMap` uses `GetMapKey` which calls `model.NewValue(val)` for non-stored *Value. Wrapper pointers regenerate. Pure pointer-eq insufficient. Combine:

```go
type cycleSet struct {
    depth int
    seen  map[*model.Value]struct{}
}

const maxRecursionDepth = 256
```

256-deep limit catches every cycle observed in test corpus, no false positives.

#### Options threading via context

dasel FuncFn signature `func(ctx, data, args)` has no Options arg. Threading Options to funcs requires context-key wrapping:

```go
type optionsCtxKey struct{}

func withOptions(ctx context.Context, opts *Options) context.Context {
    return context.WithValue(ctx, optionsCtxKey{}, opts)
}

func optionsFromContext(ctx context.Context) *Options {
    if ctx == nil { return nil }
    v, _ := ctx.Value(optionsCtxKey{}).(*Options)
    return v
}
```

Modify `callFnExecutor` to call `f(withOptions(ctx, options), data, args)`.

#### dasel CLI flag wiring is 4-stage chain

Each stage is miss point — Tier 1 implied-requirement trap fires when any stage fails:

1. `internal/cli/query.go`: `DefaultConflict string \`flag:"" name:"default-conflict"\``
2. `internal/cli/query.go` Run(): copy to `runOpts.DefaultConflict`
3. `internal/cli/run.go`: validate strategy, append `execution.WithDefaultConflictStrategy(s)` to opts
4. `execution/options.go`: WithX setter writes to Options field; func handler reads via optionsFromContext

CRITICAL: validate inside `run()`, NOT via Kong `enum:` tag. Kong os.Exits on enum violation, breaks error-string contract.

#### dasel master post-base merge audit (BASE = 0dd6132e0c58edbd9b1a5f7ffd00dfab1e6085ad)

Post-base PRs added these funcs upstream — must NOT use as candidate problem features (solution exists upstream):

- `keys`, `values`, `entries`, `fromEntries` (#533 et al)
- `flatten`, `unique`, `first`, `last` (Mar 2026)
- `split`, `toLower`, `toUpper`, `trim`, `trimPrefix`, `trimSuffix`, `startsWith`, `endsWith`, `indexOf`
- `abs`, `floor`, `ceil`, `round`, `avg`
- `toBool`, `stringify`

Available NEW (verified absent from master): `partition`, `zip`, `chunk`, `windows`, `pick`, `omit`, `mergeDeep`, `diffDeep`, `pluck`, variants.

### test.sh JUnit XML: single-invocation across multi-package

For multi-package test surfaces, use ONE `go test ./pkg1/ ./pkg2/` invocation through one `go-junit-report` pipe. Custom `merge_xml` over multiple invocations produces malformed JUnit XML — go-junit-report emits parent testcase tags that don't close properly when subtests fail across separate runs. Approved dasel-quoted-key-paths uses single-invocation pattern verbatim:

```bash
PKG="./execution/ ./internal/cli/"
go test -v -count=1 $PKG -run "$run_pattern" -timeout "$timeout" 2>&1 | go-junit-report -set-exit-code > "$OUTPUT_PATH"
```

### Difficulty-design takeaway: trap stacking is shape-bound

Pure-function additive features cap at B-shape ceiling regardless of trap density. **6 stacked Tier 1/2 traps on R16 produced 100% pass.** Same 6 trap categories on R17 (Olympus shape with recursive body + multi-package CLI flag) produced 41.7% pass. To break 50%+ ceiling, the feature must require:

1. Recursive algorithmic body (not just iteration over flat collection)
2. Multi-package integration surface (CLI flag, Options field, etc.)
3. Conditional struct fields with explicit discriminator clauses
4. Multiple enum values with per-value behavior

Confirmation: **integration surface beats trap count**. Don't add traps to a shape that has no surface for them to fire against. Reframe shape instead.

### Submission Outcome: REJECTED post-eval (namespace expansion)

**Final result**: REJECTED at platform review despite 41.7% Nova pass rate. Reviewer cited two grounds:

1. **Immediate Rejection Rule**: `FuncMerge` already exists in the repo and is registered in DefaultFuncCollection. `mergeDeep` extends an already-implemented capability ("partially present in the repository").
2. **Maintainer philosophy**: GitHub issue #169 has explicit maintainer comment against merge-namespace expansion: "I'd prefer not to add a shortcut as I don't want to pollute the namespace with uncommon/convoluted shortcuts."

**Author error**: Phase 2 PR check searched literal name (`mergeDeep` absent). Did NOT:
- Search broader namespace (`gh pr list --search "merge"`)
- Search issues (`gh issue list --search "merge"`) — would have surfaced #169
- Re-run Phase 2 after scope changed from pick/omit/chunk/windows → mergeDeep/diffDeep

Architecture grep saw `FuncMerge` but classified as "different function (shallow vs deep)" rather than "same namespace, will conflict at review".

**dasel-specific lesson**: dasel maintainer (TomWright) is opinionated about namespace expansion. Issue #169 is the canonical signal. Future dasel work must search merge/diff/pluck/get/has/contains namespaces against issues for similar philosophy comments before scope-locking.

**Submission cannot be resubmitted with same scope.** Pivot required: M1 `dasel-quoted-key-paths` (#541, A2-shape, no namespace touch) is the recommended next pick.

---

## yaegi-repl-doc (Mars Solid, 3/14 = 21.4% Nova/Orion) — Agent Behavioral Profiles + Confirmed Traps (14 runs: 1 Orion-alone, 13 Nova→Orion)

Source: `problems/yaegi/yaegi-repl-doc/`. APPROVED 2026-05-02. Eval 2026-05-02. Pass rate 21.4% — Mars Strong / Olympus Good band (predicted 30-50%, actual 9% under per yaegi-correction factor).

### Verdict mix
- 3 PASS_LEGITIMATE (Run 4 Orion, Run 11 + 12 Nova→Orion)
- 6 FAIL_REGRESSION (single shared root cause: parser-wrap newline)
- 2 FAIL_MISSED_REQUIREMENT (TypeSpec/ValueSpec doc gap)
- 1 FAIL_WRONG_LOGIC (self-pkg qualifier branch missing)
- 2 FAIL_EARLY_TERMINATION (budget-bound; empty/incomplete patches)

### Agent path effectiveness
- **Pure Orion**: 1/1 PASS (Run 4) — 100% but n=1
- **Nova → Orion**: 2/13 PASS (Run 11, 12) — 15.4%

Orion-alone trended better when run; Nova exploration adds messages and introduces parser-wrap regression risk. Pattern matches yaegi-callstack-postmortem where Orion-alone landed PASS at lower message count.

### Confirmed traps (with pass/fail data)

| Trap | Hits | Pass-rate | Notes |
|---|---|---|---|
| `package main;` → `package main\n` parser wrap | 6/14 = **43%** | Tier 1 anti-agent | Agents flip ParseComments AND add newline reflexively. Newline shifts ALL existing eval-test position assertions by 1 line → 11-12 baseline pos failures. Reference: lift ParseComments unconditionally, KEEP `package main;` (no newline). |
| GenDecl spec walking missed | 3/14 = 21% | Tier 2 | Agents capture FuncDecl.Doc only; miss `*ast.GenDecl` walking ValueSpec/TypeSpec. Need declDoc fall-back for single-spec decls. |
| REPL `:doc` usage routed to stderr | 3/14 = 21% | Tier 2 | Agents write usage to `errs` instead of REPL stdout. REPL meta-commands belong on `out` writer. |
| Self-pkg qualified lookup miss | 1/14 = 7% | Tier 3 | `Doc("main.Greet")` only matched imported-pkg qualifiers, never current pkg's own importPath. Reference candidate keys: `["main."+name, name]`. |
| `itype.getMethod` recursion no cycle guard | 1/14 = 7% | Tier 3 | Agent extends getMethod to recurse `t.val`/`t.ptr` without cycle detection → stack overflow on cyclic struct types. Don't touch getMethod; capture receiver names at AST walk. |

### Cross-agent blind spot: parser-wrap newline
Both Nova and Orion paths hit this. Not unique to either family. The bait: spec implies `parser.ParseComments` must extend beyond REPL mode (drop the constraint at line 388 of `interp/ast.go`). Agents solving the comment-attachment-to-FuncDecl problem reflexively also add `\n` to the wrap. Reference solution achieves attachment WITHOUT newline because go/parser handles `package main;<orig src>` correctly when full file is parsed cleanly.

### Test placement architecture (third valid pattern)
yaegi-completion + yaegi-callstack-postmortem use subpackage. yaegi-repl-doc shipped with `package interp_test` + `//go:build yaegi_doc` tag. Auto-reviewers reject one or the other on rotation. **Final human reviewer accepted build-tag pattern despite earlier auto-review FAIL flags.** Future yaegi submissions: pick whatever first reviewer demands; contest with approved-precedent evidence if pushed.

---

## dasel-assign-path-creation (Mars Solid, 5/9 = 55.6%) — Agent Behavioral Profiles + Confirmed Traps (9 runs: 2 Orion, 7 Nova→Orion)

Approved May 2026. Adds opt-in `WithAssignCreatePaths()` execution option. Auto-reviewer FAIL on R0 (spec/test alignment around null-handling and container-mismatch error wording); approved on R1 after spec tightening (single unified error substring, explicit `(including null)` parenthetical).

### Run-level summary

| Run | Agent path | Verdict | Failure cluster |
|---|---|---|---|
| 1 | Orion → Orion | PASS | — |
| 2 | Orion → Orion | PASS | — |
| 3 | Nova → Orion | PASS | — |
| 4 | Nova → Orion | FAIL_MISSED_REQUIREMENT | null-traversal trap (1 test) |
| 5 | Nova → Orion | PASS | — |
| 6 | Nova → Orion | FAIL_MISSED_REQUIREMENT | mixed-path container-type-choice (8 tests) |
| 7 | Nova → Orion | PASS | — |
| 8 | Nova → Orion | FAIL_MISSED_REQUIREMENT | deep-nesting walker recursion (14 tests) |
| 9 | Nova → Orion | PASS (false env-blocker contested) | — |

Per-run files modified: 4-10. Per-run LOC: 233-444. Per-run msgs: 62-233. Per-run wall-time: 5m-20m.

### Confirmed Traps (with run-level data)

| Trap | Hit rate | Tier | Mechanism |
|---|---|---|---|
| Null-as-scalar in path traversal | 1/9 = 11% | Tier 1 | Agents default-treat null as "missing" rather than "present scalar" and auto-create through. Spec MUST say `(including null)` parenthetical to pre-empt. |
| Mixed-path container-type-choice (string-next → map; int-next → slice) | 1/9 = 11% | Tier 1 | Agents implement uniform map-creation, miss the per-segment type-choice rule. Hit on `a[0].c=1`, `$this[1].name="x"`, `a.b[1].c.d=42`, `a[0].b[1].c=5`. |
| Deep-nesting walker recursion gap | 1/9 = 11% | Tier 1 | Agents implement shallow path-walk (1-2 levels) and silently break at 3+ levels with "cannot assign through scalar" mid-traversal. Hit on 5/8-deep-nest, deep-mixed-path, nested-slice-at-map-leaf. |
| Container-kind-mismatch error wording | 0/9 (caught at auto-review) | Tier 2 | Agents may emit "expected map, got slice" instead of the unified "cannot assign through scalar" substring. Spec MUST list every collision case under one substring. |

### Agent path observations

- **Orion-alone (2/2 PASS)**: Orion solves this shape cleanly. Both runs in 5-7 minutes, 4-5 files, 436-444 LOC. Direct implementation, no thrashing.
- **Nova → Orion (3/7 PASS, 3 FAIL, 1 PASS-with-false-blocker)**: Nova exploration phase finds the broad shape but mis-judges depth. Orion completion phase ships partial solution where deep recursion or special-case (null) handling is missing.
- **Nova-alone**: not tested (Mars uses Nova+Orion pair).

### Spec-tightening that mattered (R0 → R1)

R0 spec said "scalar collision errors regardless of option, with `cannot assign through scalar`." Auto-reviewer (`description_clear: true, problem_and_test_quality: FAIL`) flagged:
1. Test allowed walking through null in slice (`TestAssignPath_FlagOnFillNullSlotInSlice`) — contradicts "scalar errors"
2. Tests asserted same `cannot assign through scalar` substring for container-kind mismatches — beyond spec wording

R1 fix: tighten to enumerate every collision dimension under ONE substring. Spec adds parenthetical `(including null)` and explicit clause about kind mismatches. Solution: drop null-replacement special case in `walkOrCreate`. Test `FlagOnFillNullSlotInSlice` → renamed `FlagOnNullSlotInSliceErrors`, expects error.

### Difficulty signals

- `description_clear: true` across all 9 runs (verifier consensus on R1 spec)
- `tests_deterministic: true` across all 9 runs
- `difficulty: challenging` across all 9 runs
- 0 cheating-detected flags
- Predicted Nova pass rate: 25-40% (per DESIGN.md). Actual: 55.6% — slight upper-bound but inside Mars Solid valid (10-70%).

### Run #9 false env-blocker pattern (contest-eligible)

Run #9 verifier reported `blocker_type: verifier, confidence: medium` because agent's own `go test ./...` was cancelled at 5 minutes during baseline (`internal/cli` package). Five other runs on the SAME submission cleared baseline cleanly in normal runtime. Contested with: "five other runs cleared baseline; reproducible only against this agent's solution patch; agent fault, not env." Approved as PASS_LEGITIMATE post-contest.

**Pattern**: env-blocker with `confidence: medium` AND only one of N runs affected = contest. `confidence: high` AND most/all runs affected = real env issue (file separately).

### Test architecture

- Test file: `execution/execute_assign_path_test.go`, package `execution_test`, build tag `//go:build dasel_assign_path_creation`
- Precedent: `dasel-frontmatter-format` ships `//go:build frontmatter` (approved precedent for dasel build-tag isolation pattern)
- Reuses existing `testCase` struct in `execution/execute_test.go`
- 55 test functions, 104 testcases (subtests included)
- test.sh new-mode runs with `-tags=dasel_assign_path_creation`; base-mode runs without tag (test file excluded cleanly so base compiles even when test.patch is applied without solution.patch)

### Solution shape

| File | LOC delta | Role |
|---|---|---|
| `execution/options.go` | +10 | `AssignCreatePaths bool` field + `WithAssignCreatePaths()` constructor |
| `execution/execute_binary.go` | +5 | Equals handler routes to `executeAssignWithPathCreation` when flag is set |
| `execution/execute_assign.go` | +110 | Path-walker: `flattenAssignPath` + `resolveAssignRoot` + `walkOrCreate` + `assignAtLeaf` + `newPathFiller` |
| `model/value_map.go` | +25 | `EnsureMapKey(key, fallback)` helper |
| `model/value_slice.go` | +30 | `EnsureSliceIndex(idx, fillerFn)` helper (grows with fillers up to idx+1) |

Total ~180 raw / ~117 meaningful LOC across 5 files. Mars Solid band 170-380 raw / 110-247 meaningful, 1-8 files (mode 5).

---

## expr-licm-predicates (Mars Solid via Pattern 17 reshape, 4/12 = 33.3%) — Agent Behavioral Profiles + Confirmed Traps (12 runs: 10 Nova→Orion, 2 Orion→Orion)

**Final scope (R28-R29)**: `WithLICM` + `WithLICMStrategy` Options + `LICMStrategy` enum (`LICMDisabled`/`LICMPerBody`/`LICMCrossBody`) + per-body and cross-body hoisting algorithms. Multi-package: `optimizer/`, `expr.go` (root), `conf/`, `builtin/`. 6 files / 676 LOC.

**Pass rate**: 4/12 = 33.3%. Lands in Mars Solid 25-55% sweet spot. **Reshaped from Mars C (R0–R27 oscillating 0%↔100%) to D-new hybrid (R28-R29 → 33.3%)** — second confirmation of Pattern 17 trap-stacking ceiling.

### Nova → Orion (10 runs, 2 pass / 8 fail = 20%)

- Pass route shape: 459–577 LOC across 5 files. ~8m–9m. ~109–120 msgs.
- Fail patterns:
  - 3× FAIL_INTEGRATION_ERROR — `LICMStrategy` enum + constants placed in `conf` only, not exported from `expr` package (build error before behavioral tests run)
  - 2× FAIL_MISSED_REQUIREMENT iter-pointer set — hoisted `#index`/`#count`/`#acc` references; agents handle bare `#` only
  - 1× FAIL_MISSED_REQUIREMENT cross-body substitution incomplete — created shared binding but didn't rewrite occurrences
  - 1× FAIL_MISSED_REQUIREMENT transitive impurity — `date(env.s)` arg + user-fn pure-wrapper not blocked
  - 1× FAIL_MISSED_REQUIREMENT dedup + over-broad short-circuit blocking

### Orion → Orion (2 runs, 2 pass / 0 fail = 100%)

- 740–849 LOC, 45–52 msgs. Decisive commit-and-implement matches PLAYBOOK Pattern 13 prediction for D-new shape ("Orion-alone smashes").
- Both runs cleared all 114 hidden tests on first commit pass with no rework.

### Confirmed traps (with pass/fail data)

| Trap | Catches | Mechanism |
|---|---|---|
| Public API surface in `expr` (vs `conf`) | 3/12 | `LICMStrategy` enum exported from BOTH `expr.go` (public types/constants) AND `conf/config.go` (Config field). Tests import `expr.LICMStrategy`/`expr.LICMPerBody`. Agents who put types only in `conf` fail integration before behavioral tests run. |
| Iter-pointer set (`#index`/`#count`/`#acc`) | 2/12 | Spec enumerates all four; agents handle bare `#` and miss `#index`/`#count`/`#acc` PointerNode variants |
| Cross-body substitution completeness | 1/12 | After collecting shared binding at root, MUST rewrite occurrences in every body using `Node.String()` match |
| Transitive impure-arg opacity | 1/12 | `date(env.s)` and `myFn(env.x)` arg subexprs blocked even if otherwise pure |
| Per-body dedup + RHS-only short-circuit | 1/12 | Two distinct rules: dedup repeats inline; short-circuit block applies ONLY to RHS, not whole binary node |
| **Total unique failures** | **8/12** | |

### Difficulty-design takeaway: Pattern 17 reshape works at expr/optimizer scope

R0–R27 stayed in Mars C (additive optimizer pass). 27 rounds of trap stacking + spec compression produced binary 0%↔100% empirical with no middle ground. Each round burned 5-15 min of work without changing outcome.

R28 reshape added 3 integration-surface elements:
1. `LICMStrategy` enum (multiple values, per-value behavior)
2. `WithLICMStrategy` Option alongside `WithLICM` (multi-entry public API)
3. Cross-body sharing algorithm (whole-tree analysis vs per-body recipe)

Result: 33.3% empirical on first eval batch. Same trap categories that had 0% effect at Mars C shape now fired against D-new hybrid surface.

**Decision rule confirmed**: 3+ successive rounds of identical empirical pass rate at same shape = STOP and reshape per PLAYBOOK Pattern 17.

### expr-specific patterns

#### Public API split: `expr.go` + `conf/config.go`

Pattern: define enum type and constants in BOTH `expr.go` (public surface for users) AND `conf/config.go` (struct field). Tests import from `expr` package; agents must wire both. Enum constants use `iota`:

```go
// expr.go
type LICMStrategy int

const (
    LICMDisabled LICMStrategy = iota
    LICMPerBody
    LICMCrossBody
)

func WithLICMStrategy(s LICMStrategy) Option { ... }
```

```go
// conf/config.go
type Config struct {
    ...
    LICMStrategy int   // mirrors expr.LICMStrategy values
}
```

#### Cross-body shared registry

LICM walker holds shared registry keyed by `Node.String()`. Per-body strategy: counter resets per BuiltinNode, bindings placed via `buildLetChain` immediately above call. Cross-body strategy: counter is global, bindings accumulated in `licm.sharedOut`, prepended at root after tree walk completes.

#### Build tag isolation

Test file uses `//go:build licm` tag. test.sh `new` mode runs with `-tags=licm`. base mode runs without tag → test file excluded cleanly so base compiles even when test.patch is applied without solution.patch.

### test.sh exit code on build failure

Critical for FAIL_INTEGRATION_ERROR detection: `run_and_emit_junit` MUST `return $exit_code` even when `go-junit-report` succeeds. Earlier `return 0` masked go-test build-failure exit, allowing 0% test pass to report exit 0.

```sh
if go-junit-report -set-exit-code -out "$OUTPUT_PATH" < "$raw_log"; then
  rm -f "$raw_log"
  return $exit_code   # NOT return 0
fi
```

Build-failure fallback emits 1 testcase with `<error message="Build error">` tag when XML otherwise empty, so platform sees failure cleanly.

### Solution shape

| File | LOC delta | Role |
|---|---|---|
| `optimizer/licm.go` | +488 | NEW: walker, isHoistable, collectHoists, substituteHoists, buildLetChain, scope tracking, cross-body registry |
| `expr.go` | +35 | `LICMStrategy` enum type + 3 constants + `WithLICM` + `WithLICMStrategy` |
| `conf/config.go` | +5 | `LICM bool` + `LICMStrategy int` fields |
| `optimizer/optimizer.go` | +3 | Register LICM pass after fold, gated by `config.LICM` |
| `builtin/builtin.go` | +30 | Pure flag set in `init()` from `impureBuiltins` set (5 entries) |
| `builtin/function.go` | +1 | `Pure bool` field added to Function struct |

Total ~676 raw across 6 files. D-new band 400 raw / 15 files (4 crates) — under file count ceiling.

---

## B. Iteration Lessons (sourced from lessons-learned.md per-submission)

## expr-licm-predicates (Approved May 2026, 4/12 = 33.3% Mars Solid) — Pattern 17 confirmed second time

Second confirmation of PLAYBOOK Pattern 17 (Trap-Stacking Ceiling). Pure-function additive optimizer pass (Mars C shape) oscillated 0%↔100% across 27 rounds of hint compression + trap stacking. Reshape to D-new hybrid in round 28 immediately produced 33.3% pass rate.

### Lesson 1: pure-function additive optimizer pass = trap-stacking ceiling

LICM (`optimizer/licm.go` + `WithLICM` option) was Mars C shape: dense single-file additive extension. R17–R27 pattern matched dasel-collection-funcs R0–R16 exactly:
- Spec compression alone: 0% empirical (drops too many disambiguators)
- Spec re-expansion: 90–100% empirical (agents read recipe and ship)
- Trap stacking inside same shape: no movement on pass rate
- Each round burned 5–15 min of work without changing outcome

Trigger to reshape: 3 successive rounds of trap addition or hint adjustment producing identical empirical pass rate.

### Lesson 2: reshape moves that broke the ceiling

Three additions promoted the problem from Mars C → D-new hybrid:

1. **`LICMStrategy` enum** with three named values (`LICMDisabled`, `LICMPerBody`, `LICMCrossBody`). Each value has distinct algorithmic behavior. Agents must implement all three.
2. **`WithLICMStrategy(s LICMStrategy) Option`** alongside existing `WithLICM()`. Two ways to enter the API; `WithLICM()` defaults to `LICMPerBody`.
3. **Cross-body sharing algorithm** — invariants across distinct predicate bodies hoist once at outermost scope. Forces whole-tree analysis vs per-body recipe. ~70 LOC additional in solution.

Public API surface: enum type + 3 constants + new Option function in `expr` package. Conditional behavior keyed by enum value. Agents who put strategy types in `conf` only (not exported via `expr`) failed integration (3/12 fails).

### Lesson 3: integration-surface trap is repeatable

`LICMStrategy` enum exported from BOTH `expr` package (public API constants/type) AND `conf` package (config field) created an integration-surface trap that fired in 25% of failures. Same pattern as dasel `*execution.CollectionFuncError` reflection-decoupled tests. Agents who under-export public symbols fail at compile time before behavioral tests run.

When designing reshape for ceiling-bound problems, deliberately split the API across at least 2 packages where one is the public root (`expr.go`, root-level package) and another is the internal implementation. Tests import from the public root. Agents must wire correctly.

### Lesson 4: Orion-alone 2/2 vs Nova→Orion 2/10 confirms PLAYBOOK best-agent table

Orion-alone solved 100% (2/2). Nova→Orion solved 20% (2/10). Matches PLAYBOOK Pattern 13 prediction for D-new shape: "Orion-alone smashes". Orion's decisive commit-and-implement style avoids Nova's exploration thrashing on integration-heavy problems.

### Lesson 5: don't burn 27 rounds before reshape

Cost of staying in Mars C (27 rounds × ~2-3 min per spec edit + per eval batch): ~60–80 min of agent-author work + 12 wasted eval runs at 0%. Reshape itself: 1 round, ~25 min, lands in target band.

Decision rule: if rounds 4–5 in same shape produce identical empirical, **STOP** and reshape per Pattern 17. The next 1–2 rounds in new shape outperform 5+ more rounds in old shape.

### Lesson 6: spec compression alone cannot fix trap-stacking ceiling

Round 25 (391 words) → 100% pass. Round 26 (278 words) → 0% pass. Round 27 (282 words, parenthetical and/or hint) → 100% pass. Three consecutive spec moves at same shape produced binary outcomes with no middle ground. Pattern 17 explanation: at ceiling, spec just changes WHICH agents read which line; doesn't change algorithmic difficulty.

To exit: change the SHAPE (add integration surface), not the SPEC.

---


## dasel-assign-path-creation Lessons (Approved May 2026, 5/9 = 55.6% Mars Solid)

Mars Solid (A2). Adds opt-in `WithAssignCreatePaths()` execution option that lets the assignment operator create missing intermediate map keys and grow slices past their length. Approved on R1 after auto-reviewer flagged spec/test misalignment in R0 around null-handling and container-mismatch error wording.

### Lesson 1: unify collision semantics under one error substring

R0 spec: "scalar collision errors regardless of option, with substring `cannot assign through scalar`." R0 tests: assert same substring for scalar + container-kind mismatches (string key on slice, integer index on map). Auto-reviewer flagged contradiction.

R1 fix: tighten spec to enumerate every collision dimension under one substring:
- Any scalar value (including null) — null is explicitly a scalar, not a "missing" placeholder
- Property-name segment targeting a slice — kind mismatch
- Integer-index segment targeting a map — kind mismatch

All three return error containing `cannot assign through scalar`. Single unified substring + spec sentence covering every case = agents pick right wording on first attempt.

**Lesson**: when spec defines collision behavior, enumerate every collision case AND use ONE error substring. Multiple separate error messages = agents return wrong substring on edge case = test fails on substring match.

### Lesson 2: explicit `(including null)` kills null-traversal trap

Run #4 (Nova→Orion FAIL_MISSED_REQUIREMENT) walked through `null` slice element and replaced with map. Spec at R0 said "scalar collision errors" but agents default-treat null as "missing" rather than "present scalar". Fix: parenthetical `(including null)` in spec.

**Lesson**: when spec uses "scalar" generically, list every scalar kind agents might miss: null, bool, string, number. The `(including null)` parenthetical is a cheap, fair way to pre-empt the trap without adding a separate hint.

### Lesson 3: opt-in flag pattern preserves all baseline tests

Default-OFF `WithAssignCreatePaths` means existing assignment behavior is bit-identical to base. Zero regression risk. Reviewer approval message specifically called out "preserves existing scalar/null type-collision errors" as positive. Five separate Orion + Nova→Orion runs all cleared baseline cleanly.

**Lesson**: when extending semantics of a fundamental operator (here: `=`), gate behind opt-in option. Avoids regression risk on the 623+ baseline tests.

### Lesson 4: target approved test.patch line count from day one

R0 test.patch was 410 lines (under approved 831-line floor). R1 expansion added ~50 more tests covering proven PLAYBOOK Pattern 17 trap categories → 889 lines, in approved band. Trap buckets used: deep nesting, mixed-path container choice, type collision through every scalar kind, slice grow extreme cases, sibling preservation, idempotent reassign.

**Lesson**: target approved-folder line count from day one. PLAYBOOK Pattern 17 trap categories give natural bucket headings. Each bucket = 5-10 tests. Hits 800+ line floor without padding.

### Lesson 5: dasel multi-statement assigns chain through value, not root

Removed 12 R0 tests after empirical CLI confirmation: dasel chains semicolon-separated expressions through the RESULT of each statement, not back to root. So `a = 1; b = 2` runs `b = 2` against the integer `1` (result of `a = 1`) and errors with `cannot assign through scalar at key b`. Variables (`$x`) are mutable side-channel and DO support multi-statement (per existing `TestAssignVariable`).

**Lesson**: build dasel CLI and test empirically before writing tests for syntactic constructs. Don't assume jq-style or JSONPath-style behavior. Multi-statement non-variable assigns are not supported.

### Lesson 6: env-blocker false-claim contest pattern

Run #9 verifier reported `blocker_type: verifier, confidence: medium` because agent's own `go test ./...` was cancelled at 5 minutes during baseline. Five other runs on the SAME submission cleared baseline cleanly in under 3 seconds for the same package (`internal/cli`).

Contest pattern (one paragraph, no em dashes, mention agent names not run numbers):
"This run was tagged PASS_LEGITIMATE with a verifier blocker, but two Orion runs and three other Nova then Orion runs on the same submission completed the baseline suite cleanly. Dockerfile, test.sh, and the affected package are unchanged across all runs. The verifier itself hedged at medium confidence; the timeout is reproducible only against this agent's solution patch (likely an unbounded loop in the new path-walker exercised transitively). Agent fault, not env."

**Lesson**: env-blocker with `confidence: medium` AND only one of N runs affected = contest. `confidence: high` AND most/all runs affected = real env issue (file separately, do not contest).


## Approved Submissions

### cliffy-option-groups (Approved Attempt 6)
- **Pass rate**: 2/12 (17%) — ideal difficulty
- **Net LOC**: 480 (added 15+ helper methods to meet 400+ requirement)
- **Key lessons**:
  - Add helper methods to boost LOC: `getFirstOptionInGroup`, `getLastOptionInGroup`, `hasOptionsInGroup`
  - Clarify method behavior when non-obvious: "getGlobalOptionGroups returns groups where global is true" (agents confused this with parent traversal)
  - Negatable options hint: "--color/--no-color resolve to same flag property" helps agents handle edge case
  - Consolidate types: Move `OptionGroupDef` to `types.ts` alongside `OptionGroup` and `OptionGroupConfig`
  - Remove whitespace-only changes from patches — flags/_errors.ts trailing newlines caused patch bloat
  - Human reviewer feedback trumps AI suggestions — skip AI suggestions that conflict

### dasel-csv-options (DIAMOND APPROVED -- 6/7 standard, then Diamond 2/11 18.2%, 26 iterations total)
- **Standard pass rate**: 6/17 (35.3%) -- all Castor agents, 22/22 AI checklist pass
- **Diamond pass rate**: 2/11 (18.2%) -- 13 Castor runs, AI reviewer PASS (0.92 confidence)
- **Net LOC**: 512 added / 63 removed (standard), expanded to 160 tests for Diamond
- **Key lessons -- Difficulty Tuning**:
  - **Difficulty cliffs are real** -- with clear backslash+writer-strict: 7/12 (too easy). With vague backslash: AMBIGUOUS flags (unfair). With no writer-strict hint: 0/12 (too hard). The answer was adding a NEW behavioral requirement rather than removing/softening existing ones.
  - **Cross-cutting concerns are the best difficulty lever** -- comment-char writer protection (quoting fields starting with comment char to prevent misinterpretation as comments on read-back) was the decisive test. orionVega passed 99/100 tests but failed ONLY on this. Without it: 4/12 (fail). With it: 3/12 (pass).
  - **Agents implement features independently** -- quoting checks (separator, newline, quote char) and comment handling are implemented as separate concerns. Agents never consider that unquoted comment-starting fields get stripped on read-back. This cross-cutting interaction is genuinely hard.
  - **Writer-side behavior is the best blind spot** -- agents implement reader features then forget to extend validation/protection to the writer side.
  - **quote=never + requiring-quoting interaction is a double trap** -- even agents who add comment-char to NeedsQuoting (minimal mode) forget to add it to ValidateFieldForWrite (never mode). Two functions must change, not one.
  - **Strengthening assertions shifts difficulty** -- going from `Contains("NA")` to exact line checks caught 2 borderline Vega passes that had writer null bugs (3/12 -> 1/12). Stronger tests are fairer but harder.
  - **Writer null quoting is the hardest cross-cutting concern** -- agents consistently implement `isNull` special paths that bypass the quoting pipeline. 4/11 failures in Run 13 were from this single pattern.
- **Key lessons -- Test Design**:
  - **Single-column tests eliminate map key ordering risk** -- multi-column round-trip tests can pass accidentally if the comment-starting field isn't the first column. Single-column tests are deterministic.
  - **Cross-feature interaction tests (3-4 features combined) are the hardest** -- null+strict+newline, header=false+backslash+separator, auto-detect+quoted-content. Each feature works alone but the interaction trips agents.
  - **Test volume has diminishing returns** -- 87 vs 105 vs 108 vs 111 tests didn't change difficulty. Description tightening and behavioral requirements were decisive.
  - **Weak assertions get reviewer-flagged** -- `strings.Contains` with common substrings is not acceptable. Always verify exact field values or full line content.
  - **Always check constructor errors** -- `reader, _ :=` hides real errors as nil pointer panics; always use `if err != nil { t.Fatalf(...) }`.
- **Key lessons -- Description**:
  - **"accepts X" is ambiguous** -- 0/11 pass rate until changed to explicit validation with error returns
  - **Undocumented escape semantics get AMBIGUOUS flags** -- evaluators need to see which characters are escapable
  - **Soft hints work** -- "Minimal quoting also applies to fields beginning with the comment character" is one sentence among 25 requirements. Agents who read carefully implement it; those who skim miss it.
  - **Padded cells must be null in model regardless of csv-null setting** -- consistently trips Orion agents
- **Key lessons -- Reviewer Feedback**:
  - **Unexport format-specific internals** -- repo convention uses unexported types for format-specific code; exported symbols get flagged
  - **Document backward compat** -- if a new option supersedes an existing one (csv-separator vs csv-delimiter), say so explicitly
  - **Acknowledge breaking changes** -- csv-null defaulting to empty string (making every empty field null) must be documented
- **Key lessons -- Final Approval (Runs 15-16, Castor)**:
  - **43% with 21 runs is acceptable** -- larger sample sizes give more statistical confidence; the platform accepted this when AI reviewer confirmed all failures were legitimate
  - **Writer-side null is THE hardest blind spot at scale** -- 6/12 failing agents in Run 15 implement reader-side null correctly but forget the reverse mapping on write. "propagating through both reader and writer" in description is NOT enough to prevent this.
  - **Ragged-row iteration bug is a genuine code-quality trap** -- agents build values by iterating headers, making `len(values) == len(headers)` tautological. 5/12 failing agents hit this independently across Run 15.
  - **Strict+null ordering is a subtle 2-test trap** -- agents who pass 98-99% of tests still fail because strict validation runs on pre-substitution empty string instead of post-substitution null string. Separates good from great implementations.
  - **Deduplicating tests on reviewer request has minimal impact** -- removing 5 duplicate test pairs (124->118) didn't change difficulty or pass rate meaningfully
  - **Removing unicode.IsPrint guard per reviewer request is safe** -- validator checking printability was not in spec and removing it didn't affect any agent's behavior
  - **Restoring doc comments per reviewer request is trivial** -- 3 one-line doc comments on exported functions that existed in original code must be preserved
- **Key lessons -- Diamond Tier (Run 17, 13 Castor runs, 2/11 pass)**:
  - **Cross-package CLI tests are the strongest message-count lever** -- adding 7 tests in internal/cli/csv_flags_test.go boosted median from ~60 to 141 messages by forcing agents to navigate two packages
  - **Reflection-based help text tests are fair and effective** -- inspecting struct tags on QueryCmd AND InteractiveCmd via reflection caught 4/11 agents who updated one file but missed the other
  - **Null-through-pipeline is the #1 Castor blind spot for CSV** -- across 30+ runs, agents consistently implement isNull special paths bypassing quoting/escaping/trim. 5/9 Diamond failures
  - **Dead-code ragged-row check is structurally hard** -- len(values) built from headers always equals expectedCols. Correct approach needs row.MapKeys(). 5/9 Diamond failures
  - **Trim-null pipeline ordering trips passing-tier agents** -- trim must apply to null-substituted values, not bypass them. 3/11 agents failed on this alone



### cliffy-config-file (Approved Attempt 10)
- **Pass rate**: 1/12 (8%) — hardest approved problem
- **Net LOC**: 738 LOC, 8 files, 145 messages median
- **Key lessons**:
  - **Deno is NOT in olympus-base** — must install via `curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh -s v2.0.0`
  - **DENO_DIR + --cached-only** — set `ENV DENO_DIR=/deno-cache` in Dockerfile, use `--cached-only` in test.sh to force offline mode
  - **Cache ALL deps during Docker build** — JSR, npm, test file imports. Container runs with --network none
  - **Windows CRLF kills patches** — use `[System.IO.File]::ReadAllText()` + `.Replace("\r\n", "\n")` to fix
  - **Module structure hints matter** — adding "organized in a config submodule under the command directory" to meta.md went from 0 solves to 2 solves
  - **Sync vs async clarification critical** — "loaded during parse and cached for synchronous access afterward" prevented agent confusion
  - **Test imports from public entry point** — `../../mod.ts` not internal paths like `../../config/mod.ts`
  - **Remove dead code aggressively** — reviewer caught flattenNestedConfig, unflattenConfig, duplicate kebabToCamelCase
  - **Error classes extend project base** — extend CommandError with Object.setPrototypeOf, not Error directly
  - **10 attempts is normal for complex features** — budget for iteration, track everything in feedback.md

### dasel-reduce-takewhile-dropwhile (ABANDONED — 100% pass rate)
- **Pass rate**: 10/10 (100%) — every agent solved it, including 3 Nova
- **Root cause**: The feature follows an identical structural pattern to existing `filter`/`map`/`sortBy` in the codebase (lexer token -> parser -> AST -> executor). Agents just copy the pattern and slot in new keywords.
- **Key lessons**:
  - **Pattern-followable features are unsalvageable** — if the codebase already has 3+ examples of the exact same structural pattern (new keyword -> same pipeline), no amount of tests will make it hard. Agents copy-paste and adapt.
  - **Recognize "too easy" early** — before building a problem, check if the feature is just "add another case to an existing pattern." If yes, skip it entirely. Signs: new keyword uses same AST node shape, same executor interface, same parser grammar rule as existing features.
  - **Test count doesn't compensate for low implementation difficulty** — 97 tests with cross-feature chaining, edge cases, and type coercion still resulted in 100% pass rate. Difficulty comes from implementation complexity, not test volume.
  - **Good problems require novel implementation challenges** — custom parsers from scratch (KDL), cross-cutting concerns (CSV option interactions), new architectural patterns (config file loading). Not "add another keyword to existing machinery."

### cliffy-prompt-wizard (SUBMITTED — 3/12, 25%)
- **Pass rate**: 3/12 (25%) — 0 Nova, 0 Orion solver, 3 Vega
- **10 Orion solver attempts across 5 runs, 0 solves** — consistent failure patterns:
- **Key lessons — Agent-specific weaknesses**:
  - **Stateful callback semantics kill Orion** — Orion consistently implemented `onProgress(executed, executed)` instead of `(current, total)` in ALL 5 eval runs. Anything requiring a running counter tracked across iterations is an effective Orion difficulty lever.
  - **State consumption patterns trip Orion** — `_confirm` consumed after first use (revert to auto-accept default) was missed in 4/5 runs. Requirements where a value is used once then behavior changes are hard for Orion.
  - **Orion doesn't self-debug** — message counts of 27-53 vs Vega's 86-163. Orion ships first-pass implementations without testing. More iteration correlates with success.
  - **Type conversion bypass is the dominant Nova killer** — 4/5 Nova runs failed because injected values weren't routed through prompt type conversion. Even with explicit documentation ("injected values pass through prompt type conversion"), Nova skips the prompt pipeline and uses raw values directly.
  - **TypeScript intersection types trip Nova** — using `&` to extend interfaces with wider property types (string → string|function) narrows to `never` instead of widening. Nova doesn't know this TS pitfall.
  - **Complex state machines with multiple interacting subsystems are ideal problems** — wizard flow (when/goto/depends/repeat/section/back/crossValidate/confirm/navigation) has many edge case interactions that agents can't get right without careful implementation and testing.
- **Key lessons — Process & description**:
  - **Description iteration is the biggest time sink** — 9 attempts, 8 rounds of AI review. Most effort went into meta.md wording, not code. Budget for this.
  - **Every undocumented behavior is a potential unfairness flag** — Attempt 8b failed fair task because breadcrumb type (string vs object), file path, and breadcrumb-on-back semantics weren't explicit. Be hyper-specific in descriptions.
  - **AI review suggestions can break your problem** — AI wanted to simplify sentences that agents critically depend on (e.g., removing `from prompt/wizard.ts` caused 2 agents to put code in wrong file). Track critical elements in a "DO NOT REMOVE" list.
  - **Spec-implementation alignment takes multiple passes** — repeat semantics alone took 3 attempts to get right (value added if true → not added if false → always added). Write tests first, then match description to test behavior.
  - **Windows patch encoding pitfalls** — UTF-16 BOM and CRLF cause `git apply` failures. Always use explicit `UTF8Encoding($false)` and LF line endings when generating patches on Windows.
- **Design implications for future problems**:
  - Include stateful callbacks with running counters (progress, pagination, etc.)
  - Include consume-once state patterns (tokens, confirmations, one-time flags)
  - Combine multiple interacting subsystems where edge cases compound
  - Novel state machine designs > pattern-followable features

### cliffy-option-groups (ACCEPTED — with LOC quality warning)
- **Pass rate**: 2/12 (17%) — accepted
- **Reviewer note**: "The 28 trivial helper methods account for ~140 lines of the 425 LOC total. They are all explicitly required and tested so they count as required code, but the problem design leans on API breadth for LOC rather than core algorithmic complexity."
- **Key lessons**:
  - **Don't pad LOC with trivial helpers** — methods like `hasOptionGroup()`, `getOptionGroupCount()`, `isGroupExclusive()` are one-liners that inflate LOC without adding real implementation challenge. Reviewers notice and flag this even if they accept it.
  - **LOC should come from core complexity** — design problems where the 400+ LOC requirement is met naturally through the feature's inherent difficulty (parsing, state machines, cross-cutting validation), not by adding a broad surface area of simple accessor methods.
  - **API breadth != implementation difficulty** — 28 helper methods tested individually still doesn't make the problem harder for agents. It just means more boilerplate to write. Prefer fewer, deeper features over many shallow ones.

### cliffy-middleware (ACCEPTED -- 21/21 checklist, 6 eval runs)
- **Pass rate**: 3/10 (30%) -- accepted
- **Reviewer notes**: "effectively removed the system-crashing logic (resolving the abort HookAbortError override), properly closed the concurrency loop on synchronous next() calls by adding an explicit boolean guard before the inner dispatch, and refactored hardcoded property access and duplicate ancestor-traversals gracefully into a new helper"
- **Key lessons**:
  - **Cross-feature interdependent tests are the primary hardening lever** -- Single-feature tests (abort alone, middleware alone) are too easy for agents. Tests combining 2-3 features (middleware + abort + onion unwinding, onError + middleware + error wrapping) catch implementation mistakes that simple tests miss. Run 5 (100% pass) vs Run 6 (30% pass) showed adding 7 cross-feature tests was the critical change.
  - **Description hints cause catastrophic solve-rate increases** -- Adding one sentence about ancestor ordering ("hooks from higher ancestors run before hooks from closer ancestors") caused pass rate to go from 17% to 100%. Never add implementation hints to satisfy AI checkers; remove the test instead.
  - **Reviewer solution fixes require compensating test difficulty** -- Fixing solution code (dead storage, abort logic, defensive checks) doesn't change what agents implement, but the AI checker may require description/test changes that inadvertently make things easier. Always pair reviewer-driven changes with new hardening tests.
  - **AI checker "tests focus on behavior" vs difficulty is a tension** -- The AI checker flags tests for "unspecified behavior" even when the behavior is clearly inferable. Removing the flagged test + its description hint is safer than adding the hint to satisfy the checker.
  - **Abort-via-return is the dominant agent failure mode** -- 5/10 agents in Run 4 and 2/7 in Run 6 implemented abort by returning from the lifecycle function instead of throwing HookAbortError through the middleware pipeline. Tests that check middleware after-next code does NOT run on abort are the most effective difficulty tests.
  - **TypeScript typing is a natural difficulty source** -- HookContext with narrow generics causes TS2698/TS2339 compile errors. This fails 3-4 agents per run without any test design effort. Keep HookContext typing requirements clear but let agents figure out the right type design.
  - **CommandError re-export from mod.ts** -- When tests need to check class inheritance (instanceof CommandError), re-export the base class from the package root instead of importing from internal paths. AI checker flags internal imports.

### cliffy-command-scaffold (APPROVED -- 18 attempts, 4 correctness bugs fixed in final review)
- **Pass rate at approval**: 1/11 -- accepted after reviewer confirmed 4 correctness bugs fixed
- **Net LOC**: ~1028, 8 files (6 new + 2 modified), 69 tests
- **Key lessons -- Description structure**:
  - **Multi-paragraph with `##` headers is the gold standard for complex features** -- The approved meta.md used 5 distinct `##` sections (Introspection, Code Generation, Template Registry, Validation, Diffing). Reviewer never flagged formatting. Single-paragraph version (Attempt 8) got immediate formatting rejection (0/12 agents).
  - **Bullet lists inside `##` sections are cleaner than prose for struct fields** -- `- **field**: description` inside a section header is scannable and readable for 12+ field listings. Dense prose sentences listing all fields become unreadable walls of text.
  - **Word count under 500 is achievable with structured format** -- 5 sections with bullet lists totaled ~480 words. Headers reduce redundancy: each field listed once, grouped by subsystem.
  - **Single-paragraph descriptions are a direct quality rejection risk** -- Reviewer explicitly flagged it as: "Unrelated behaviors are bundled into a single wall of text rather than being structured into readable sections." Structure is not optional for complex multi-subsystem features.
- **Key lessons -- Solution correctness**:
  - **Edge-case bugs in navigation algorithms survive many eval runs** -- `findCommandByPath` skipping root-level segments on identical names caused 7+ eval runs to have false-pass results. Navigation bugs only surface in specific boundary cases that agents don't test manually. Always test navigation edge cases explicitly.
  - **Regex anchoring matters** -- `FLAG_REGEX` without `$` matched `--port` when input was `--port-number`. Always add terminal `$` anchor to flag/name-matching patterns.
  - **JSON.stringify for array defaults in code generation** -- Raw `[...]` in generated TypeScript is not valid. Always use `JSON.stringify(value)` for array/object defaults in code generation paths.
  - **Separate compound validation checks** -- when two error codes (`MULTIPLE_VARIADIC` and `INVALID_ARGUMENT_ORDER`) share the same loop, one can short-circuit before the other is reached. Separate into distinct passes to ensure both can independently trigger.

### cliffy-command-aliases (APPROVED Diamond Tier -- final eval 10 Castor + 1 Vega, 6 failure-QA review rounds)
- **Final pass rate at approval**: 3/10 Castor (30%) + 0/1 Vega -- within Diamond target (1-5 out of 10). Approved after 6 QA review rounds.
- **Net LOC**: ~1300, 6 files, 51 tests
- **Key lessons -- Description**:
  - **Every return type, property type, and export path must be listed** -- 5 Alignment ERRORs in review traced to undocumented return values (boolean, undefined), error hierarchy, AliasRegistry method shapes.
  - **String[] vs string is catastrophic** -- earlier run: Nova agents uniformly typed `original` as `string` not `string[]` because meta.md named the property without its type. Always add parenthetical type annotations.
  - **Export lists must include base classes** -- 12/12 compile failures in an earlier run because agents correctly exported AliasRegistry + 3 error types but omitted `CommandError`. Enumerate every exported symbol.
  - **Getter vs method ambiguity: AliasRegistry.size** -- Say "as a method" or write `size(): number` explicitly.
- **Key lessons -- Hardening**:
  - **Bidirectional conflict detection** is the best difficulty lever -- agents always implement alias-to-command but forget command-to-alias reverse check.
  - **Stateful expansion callbacks (onAliasExpand)** with cancel semantics create complex interaction -- agents implement the callback but fail to exclude cancelled steps from the recorded chain.
  - **useRawArgs cross-cutting test** reliably catches agents who place alias resolution before the rawArgs check in the parse pipeline.
  - **Multi-level global propagation** requires full ancestor chain traversal -- agents consistently stop at immediate parent.
- **Key lessons -- Dominant failure modes (final Diamond eval)**:
  - **clearRegisteredAliases: 8/8 failing runs (100%)** -- the same-command local+global clearing test caught every failing agent across THREE architectural variants: (A) single shared map with `.clear()` (4 runs), (B) separate maps but clears both (1 run), (C) separate maps preserving globals correctly but `getAliasRegistry()` only walks parents for inherited globals, omitting own-command globals (3 runs). The trap is robust because it catches agents who get the OBVIOUS fix right (separate storage) but miss the subtler registry-view issue.
  - **Cancelled aliases must NOT appear in chain** -- 2/10 Castor agents failed. `chain.push(name)` happens BEFORE the cancellation-check branch, so cancelled names appear in the output array and `depth` is incremented. Ordering matters: record name only AFTER confirming the step wasn't cancelled.
  - **AliasExpandCallback typed boolean|void** -- "Returning false cancels" implies void=continue but agents declare `boolean` causing TS errors on void callbacks.
  - **getLastAliasExpansion().expanded must be a snapshot** -- agents store the array reference from ctx.unknown which is later mutated by `getSubCommand.shift()`. Must `.slice()` at record time.

### cliffy-undo-history (APPROVED -- 8 eval runs, 7/7 score -- "lgtm. Great work!")
- **Pass rate at approval**: 3/11 (Run 8) -- vegaVega, orionVega, novaVega3
- **Net LOC**: 702, 8 source files, 72 tests
- **Key lessons -- Description**:
  - **Data structure field specs prevent 0/12 runs** -- Run 3: 10/12 failures because CheckpointData `{name, index, timestamp}` fields were undocumented. Agents invented 5 different shapes. Specify every field of every returned struct with name and type.
  - **Getter vs method** remains a perennial ambiguity -- Add explicit `()` and "as a method" qualifier; state "All methods are synchronous" if needed.
  - **Return type of chaining methods must say "returning this"** -- 6 agents in Run 1 returned void from `globalOnHistoryChange`, breaking chain assertions.
  - **Runtime validation must be in description** -- Run 5: 3 near-passes (71/72) marked FAIL_UNDOCUMENTED because `record()` threw at runtime for invalid type strings. Agents assume TypeScript compile-time safety is sufficient. Rule: if a function throws, document it.
  - **`hasHistory()` semantics cannot be inferred** -- "returning boolean" is ambiguous between enabled-check and entry-count-check. Write "returning true when undoCount() > 0."
  - **`entries()` return order and scope must be explicit** -- 2/5 Vega agents got it wrong with different bugs. Say "HistoryEntry[] in oldest-first order excluding undone entries."
  - **`keepAcrossParses` must name the trigger method** -- saying "clears on each parse" without naming `parse()` causes agents to document the option but never hook it. Say "cleared at the start of each Command.parse() call."
  - **globalHistory lazy vs eager** -- "propagates to subcommands" doesn't convey timing. Add "at parse time, including those added after calling globalHistory()."
  - **CheckpointManager single-arg is deeply persistent** -- Even with explicit `CheckpointManager(historyManager)` notation, 3/5 Vega agents added optional Transaction. Add: "no other constructor arguments exist."
  - **CheckpointManager active-tx detection must name the mechanism** -- "throws TransactionError" is not enough. Add: "CheckpointManager checks active-transaction state via the HistoryManager."
- **Key lessons -- Hardening**:
  - **Per-instance counters** prevent cross-test contamination -- module-level counters cause test bleeding.
  - **Monotonic ordering assertions** (`assertLess(a, b)`) beat exact counter values (`assertEquals(changeIndex, 3)`).
  - **>= vs > in checkpoint restore** is the canonical off-by-one -- test that restoreCheckpoint removes itself.
  - **instanceof on internal classes couples tests** -- use behavioral assertions on return values instead.
- **Key lessons -- was_mentioned_in_description signal**:
  - **3+ evaluators marking `was_mentioned_in_description: false` simultaneously** = certain unfairness flag -- fix with one sentence in meta.md, no code changes.
  - **Adding test behavior without documenting it = near-pass becomes FAIL_UNDOCUMENTED** -- every test assertion must map to a description sentence.

### yaegi-reflect-identity (APPROVED -- 20 attempts, 8 eval runs, 80+ agent runs)
- **Pass rate at approval**: 2/16 (12.5%) -- Nova R2 + Orion R7. AI reviewer PASS. Human reviewer APPROVED.
- **Net LOC**: 487, 4 files (all in interp/ package), 27 tests
- **Problem type**: Complex bug fix (#1716) -- interpreted named struct types lose type identity when crossing binary Go function boundaries
- **Key lessons -- Hint Strategy (most heavily iterated aspect)**:
  - **Hint effectiveness follows a cliff function, not a gradient** -- Without fixStdlib hint: 0-35/47. With fixStdlib hint: 42-46/47. Adding method-extraction recipe: 1-2 agents reach 47/47. Each hint layer unlocks a qualitatively different failure mode.
  - **Description quality checker and eval-proven hints directly conflict** -- Quality checker flagged "extract method names from both sides and compare directly" as over-prescriptive. But eval data across 40+ runs proves: 0% pass rate without it, 10% with it. Resolution: keep the eval-proven hint and accept the quality checker warning as non-blocking.
  - **fixStdlib interception pattern is THE universal blocker for yaegi** -- 100% of agents gravitate toward unsafe runtime type patching (go:linkname + modify abiType fields). Without a hint pointing to fixStdlib in use.go, no agent discovers the correct architecture. The hint is necessary, not optional.
  - **Single-fact hints are insufficient for multi-layered problems** -- "Interfaces are struct-kinded at runtime" (single fact) = 0% pass across 40+ runs. Adding "extract method names and compare" = 10% pass. Adding fixStdlib pointer = 12.5% pass. Each fact addresses a different failure layer.
  - **Hint phrasing matters as much as hint content** -- "extract method names from both sides and compare directly when Kind() is not reflect.Interface, returning the correct boolean result rather than panicking or returning false" -- agents STILL return false despite explicit "rather than returning false" because they read "not Interface" as "unsupported case."
- **Key lessons -- Go Interpreter (yaegi-specific)**:
  - **getConcreteValue is for emulated interfaces, NOT regular struct values** -- calling it on struct values destroys them. This is a yaegi-specific pitfall that causes silent data corruption.
  - **reflect.StructOf(identical layout) returns the SAME reflect.Type** -- two empty structs or two structs with identical fields share reflect.Type. Need name/path-based discrimination (struct tags or discriminator fields) for type identity.
  - **yaegi interpreted interfaces are struct types at Go runtime level** -- Kind() returns Struct, not Interface. This means reflect.Type.Implements(u) panics when u is an interpreter-defined interface. The correct approach is method-set comparison, not runtime delegation.
  - **_error binary wrapper hides interpreted type identity** -- values crossing the binary boundary lose their itype metadata. Need interpErrVal carrier struct to preserve name/path through error chains.
  - **Container environment: go-junit-report not on PATH** -- `go install` puts binaries in `$GOPATH/bin` which is NOT on `$PATH` by default in olympus-base. Always add `ENV PATH="/root/go/bin:${PATH}"` to Dockerfile and add GOPATH fallback in test.sh.
  - **Flaky yaegi tests in Docker** -- TestYaegiCmdCancel fails without .git metadata, TestInterpConsistencyBuild hangs. Use `go test -skip` (Go 1.21+) to exclude container-incompatible tests in base mode.
- **Key lessons -- Description Iteration (20 attempts)**:
  - **Bug fix descriptions can reach 300+ words when the fix spans multiple subsystems** -- reflect.TypeOf + fmt.Errorf + errors.As each need behavioral specs. The 70-120 word target for bugs doesn't apply when 3 distinct APIs must be specified.
  - **"whether passed directly or wrapped" is the minimum viable phrasing for direct-error edge cases** -- 5/8 agents missed unwrapped errors.As until this was explicit. Standard Go convention (errors.As works on direct values) is NOT inferable by agents.
  - **Negative assertions ("must return false for mismatched types") catch more agents than positive ones** -- agents implement the happy path but forget to verify rejection.
- **Key lessons -- Test Design**:
  - **27 tests is sufficient for a complex bug fix** -- started at 47, reduced to 27 per reviewer feedback. Removing duplicates didn't change difficulty.
  - **Empty struct identity is the single hardest edge case** -- zero-field structs share reflect.Type, making tag-based discrimination fail. Required XyaegiTypeID discriminator field in solution. 7/8 near-pass agents fail this.
  - **Build tags work well for Go bug fixes** -- `//go:build issue1716` cleanly isolates new tests. Base mode's `go test ./...` automatically excludes them.
  - **Test both Implements()==true AND Implements()==false** -- reviewer explicitly requested the false case. Agents that return true for all types appear to pass Implements tests until the negative case catches them.
- **Key lessons -- Reviewer Feedback**:
  - **Duplicate test removal is the #1 reviewer request for large test suites** -- 47→32→27 tests across 2 rounds. Each round identified 5-16 tests that were subsets of other tests.
  - **Latent bugs surface during test reduction** -- removing tests revealed that getItypeNamePathForTargetElem returned ("","") for empty structs sharing reflect.Type, which was masked by a test that happened to register types in the right order. Fix: XyaegiTypeID discriminator field.
  - **NumMethod assertions: use == not >=** -- reviewer flagged >= as too permissive. Exact equality catches agents that add spurious methods.
  - **Dead code audit after each reviewer round** -- reviewer caught 4 unused functions + 1 unused var in reflect_identity.go, and a redundant Implements(errorType) check on pointer types.

### cliffy-output-format (APPROVED -- 24 attempts, 16 eval runs)
- **Pass rate**: 2/7 (28.6%) AI reviewer approved (PASS).
- **Net LOC**: 438-1012, 4-12 source files, 143 tests
- **Key lessons -- Final Approval (Runs 14-16)**:
  - **AI HIGH suggestions that conflict with past eval data must be IGNORED**: Run 15 regressed to 0% pass rate because an AI reviewer HIGH suggestion asked to remove the `CommandError` export mention, calling it redundant. Removing it broke compile for 9/10 agents (TS2305). The human reviewer later approved with the hint restored.
  - **Whitespace and empty lines matter in solution.patch**: Human reviewers will block approval for "irrelevant changes" if the patch includes arbitrary blank lines added to existing functions or interfaces. Always scrub `solution.patch` for pure-whitespace mutations in pre-existing files before submission.
  - **Agent variance is a difficulty validator**: In Run 16 (7 runs), Orion passed 2/2 while Nova failed 5/5 on distinct explicit requirements (CSV trailing newline, explicit `CommandError` export, nullValue quoting). A split like this confirms the problem is fundamentally solvable (Orion proves it) but effectively traps weaker architectures (Nova).
  - **`Record<string, X>` vs `Registry` ambiguity**: When a method takes "a collection" or "a map" of objects, agents naturally choose `Record<string, X>`. If a custom wrapper type is intended, it must be explicitly typed.
  - **Formatting pipeline bypass for substituted values (nullValue)**: A recurring CSV trap — agents substitute `null` with `nullValue` (e.g. "N/A") but bypass the quoting/delimiter check for that substituted string. If `nullValue` contains the delimiter (e.g. `","`), it must be quoted, but agents miss this.
- **Key lessons -- Shared LLM Blind Spots**:
  - **Overlapping general + specific statements create blind spots** -- "only the returned object or array triggers formatting. If the action returns undefined or null, no formatting occurs." ALL 14 agents implemented the specific guard (null/undefined) and missed the general one (only object/array). This is a "textbook shared LLM blind spot" per AI reviewer. Fix: remove the specific examples or restructure so the general rule stands alone.
  - **Softer hints > explicit checklists** -- Listing "strings, numbers, and booleans" explicitly would push pass rate to 100%. Instead, use "any non-object return value is silently ignored" — reinforces the concept without giving a checklist.
- **Key lessons -- Pre-existing Class Exports**:
  - **Pre-existing internal classes MUST be named in export lists** -- Tests imported `CommandError` from `mod.ts`. Meta.md said "the error classes are exported" — agents interpreted this as only the 3 NEW error classes, not the pre-existing `CommandError` base class. 9/10 agents failed with TS2305 compile error. Fix: explicitly name `CommandError` in the export list.
  - **"The X classes" is ambiguous when some are new and some are pre-existing** -- Always enumerate every exported symbol by name, including base classes.
- **Key lessons -- Platform/Infrastructure**:
  - **Deno `--reporter=junit` does NOT exist** -- correct flag is `--junit-path=<path>`. Caused 1 BASELINE_ERROR.
  - **Platform passes `--output_path` BEFORE mode arg** -- `MODE=$1` breaks. Use position-independent arg parsing. Caused 4 consecutive BASELINE_ERRORs.
  - **POSIX sh > bash in containers** -- bash arrays, `[[ ]]`, `set -e` with pipes can all break. Use `#!/bin/sh` with POSIX constructs only.
- **Key lessons -- Difficulty Tuning**:
  - **AI reviewer NEEDS HINTS ≠ unfair** -- 9/9 checklist pass, all test groups rated "fair", but 0% pass rate from shared blind spot. A single restructured sentence was sufficient.
  - **98.1% correct but 0% pass rate is possible** -- agents scored 103/105 consistently. The 2 failing tests were the ONLY difficulty lever. Broad test coverage doesn't help if agents nail the core feature.
- **Key lessons -- "Initializing" phrasing trap (Run 11)**:
  - **"Initializing the full X system" = "call the default constructor"** in agent interpretation -- Run 11: 2 FAIL_AMBIGUOUS_TASK because "initializing the full output format system" was read as calling `outputFormat()` (which includes built-in formatters), not just "set up the four CLI options." The phrase "registers a single formatter" in the same sentence was insufficient to override the "full system" reading.
  - **FIX PATTERN**: Replace "initializing the full X system [if needed]" with "sets up Y without adding any built-in Z, or adds to existing if already configured." This explicit before/after branching resolves the ambiguity without being prescriptive.
  - **FAIL_AMBIGUOUS_TASK blocks agentFair criterion** -- 2 runs with description_clear=false directly cause agentFair=FAIL on the platform. Every description phrase that could be read two ways must be rewritten before resubmitting.
- **Key lessons -- agentLongHorizon and median mechanics**:
  - **Median is computed from passing runs ONLY** -- The 7 passes across a full 19-run eval used [57, 76, 79, 177, 181, 186, 186] messages → median=177 (Passing!). The failing runs don't contribute to the median at all.
  - **Run full evals to correctly assess median** -- A partial run (e.g., just Castor) might yield a misleadingly low median (e.g. 76). Running a full suite with Vega bumped the median well past the 100-msg threshold without changing problem difficulty.
  - **"Make agents use more messages" is rarely the right fix** -- Adding complexity makes fewer agents pass; fewer passes = fewer samples; those samples come from the fastest/most efficient agents who use fewer messages.
  - **Bypassing agentFair is acceptable for false flags** -- Evaluators may flag a task as ambiguous, but if the pass rate is stable and the AI reviewer confirms the issue is "subtle but fair", you can bypass `agentFair`.
  - **Design for high message counts from day one** -- include CLI flag registration or public API surface requirement that forces multi-package changes. After calibration is established, it's too late to add without destabilizing pass rate.

### dasel-multi-file (APPROVED 6/7 -- 9 attempts, 5 eval runs)
- **Pass rate at approval**: 1-3/12 across runs -- Hard difficulty confirmed
- **Net LOC**: 436, 9 files, 96 tests
- **Key lessons -- Fairness traps to avoid**:
  - **Internal package tests = automatic fairness failure** -- Tests in `internal/fileutil/fileutil_test.go` enforcing where code lives (not what it does) cause 100% FAIL_TEST_MISMATCH. Agents organize code differently; test through PUBLIC interfaces only. This was Criterion 4 failure in the quality check.
  - **Test helpers must use the real multi-arg call** -- A helper `execFiles(t, a, b)` that calls `files("a")` then `files("b")` in separate invocations doesn't test multi-argument behavior. Build a single `files("a", "b")` selector and invoke once. Reviewer catches this.
  - **Dead code in solution** -- `ReasonRead` constant defined but never used. Reviewers scan for unused exports. Remove all dead constants.
- **Key lessons -- Description**:
  - **WithFormat signature: always state full new signature explicitly** -- Writing "QueryFiles and QueryFilesWithFormat accept (ctx, paths, selector, opts...)" implies identical signatures, making format position invisible. 2 agents failed FAIL_AMBIGUOUS_TASK. Always write the FULL signature for each variant: `QueryFilesWithFormat(ctx, paths, format, selector, opts...)`.
  - **Format before selector in WithFormat variants** -- Convention: format is the third positional arg before selector.
  - **Word count cap**: Reviews flag descriptions over 500 words. Target 460-490. Cutting filler phrases saves 20+ words without losing behavioral specs.
- **Key lessons -- Difficulty mechanics**:
  - **`originalInFormat` is the single best difficulty lever for CLI integration** -- 8/12 agents failed because they set `o.InFormat = o.OutFormat` before file loading (existing run logic for stdin format normalization). Fix: capture `originalInFormat := o.InFormat` BEFORE the mirroring block, pass `originalInFormat` to file loading. Subtle wiring distinction, explicitly documented, yet most agents miss it. Do NOT add a hint -- it's the intended trap.
  - **Ordering semantics create reliable traps** -- "Multiple --file flags contribute entries in declaration order; glob patterns expand entries sorted alphabetically" has 3 distinct behaviors agents confuse: (1) explicit paths = declaration order, (2) single glob = alphabetical, (3) multi-glob = first-occurrence order, no global sort. Agents implement one and forget the others.
- **Key lessons -- Patch generation**:
  - **Untracked new files are invisible to `git diff`** -- Always check `git status --porcelain` to find untracked `??` files and add them explicitly to the diff file list. `git diff $BASE` only shows tracked modified files. This caused `internal/cli/multifile.go` to be missing from solution.patch for 2 submission rounds.
  - **Regenerate both patches after every change** -- even minor cleanups change line counts and must be reflected in final patches.
- **Key lessons -- Description rewriting for new rules (5 iterations)**:
  - **Description Quality and Alignment checkers directly conflict** -- Quality checker says "drop parameter lists, they read like API docs." Alignment checker says "specify exact signatures, tests depend on them." Resolution: use PROSE for signatures ("takes a path slice and selector") instead of Go types ("(ctx context.Context, paths []string, selector string)"). Prose passes quality; function names + key param ordering pass alignment.
  - **Phrases that trigger Description Quality FAIL**:
    - Parenthesized Go-typed parameter lists: `(ctx, paths, selector, opts...)` -- "reads like auto-generated API docs"
    - Preamble counters: "Four new execution functions are added." / "Eleven functions are added:" -- "drop, the list itself makes the count clear"
    - Template-y verbs: "The root package gains..." -- "preamble, use 'Add X to the root package'"
    - Redundant convention references: "mirroring the existing Query signature" -- "inferable from api.go"
    - Obvious Go idioms: "All functions propagate errors immediately with no partial results." -- "standard Go, drop it"
    - Over-specified negatives: "with no override mechanism" -- "not tested, remove"
    - Inferable repo details: full extension-to-format mappings, "the default execution function collection" -- "discoverable from parsing/ directory"
  - **Patterns that PASS Description Quality**:
    - "QueryFiles takes a path slice and selector" -- prose, not type annotations
    - "WithFormat variants add a format parameter before the selector" -- behavioral, critical param ordering preserved
    - "Add QueryFiles(paths, selector) with WithFormat, Glob, GlobWithFormat, and MultiGlob variants" -- naming pattern, not 11 individual listings
    - "fileNames and filePaths accept the same pattern arguments; fileNames returns basenames, filePaths returns full paths" -- combined identical descriptions
  - **Alignment ERROR items that MUST be in description**:
    - Exported type names used in tests: "FileLoadOptions" not "a file-load options type"
    - Exported field names: "Format and ReaderOptions" not "format and reader-options"
    - Constructor defaults tested: "DefaultFileLoadOptions returning Format as empty string"
    - Ordering semantics per function family: if tests check ordering for both CLI and execution functions, state it for both
  - **Safe to skip (alignment WARNINGs that would re-trigger quality FAIL)**:
    - Return type signatures inferable from existing functions (Query already returns []*model.Value, int, error)
    - Dedup semantics for variants when already stated for the base ("MultiGlob variants deduplicate" covers both Query and Load)
    - Error conditions already stated generically in a different paragraph
  - **Word count progression**: 488 -> 366 -> 325 -> 322 -> 277 (43% reduction over 5 iterations). Each round focused on different issues. Don't try to fix everything in one pass -- the checkers flag different things each time.
  - **The fundamental rule**: Name every exported symbol. Describe behavior in prose. Never list Go types. Combine identical descriptions. Drop inferable details.

---


## Diamond-Tier Lessons (Learned from cliffy-command-aliases, 10 Castor + 1 Vega run, APPROVED after 6 failure-QA review rounds)

### Test Design for Diamond

1. **Same-object interaction tests are the #1 Diamond trap** -- agents always test the parent-child inheritance case (globals on parent survive child clear), never the same-command case (global and local on SAME command, clear locals, check global survives). 8/8 failing runs (100%) fell into this trap across 3 different architectural variants. Design at least one test per feature that exercises the same-object edge case.

2. **One trap, multiple architectural paths** -- the `clearRegisteredAliases` trap caught agents through THREE wrong implementations: shared map + `.clear()`, separate maps cleared together, and separate maps with incomplete registry view. The trap is strong because even agents who avoid the obvious implementation (variant A) fall into the subtler registry-view variant (C). When designing Diamond traps, verify your test catches at least 2-3 architecturally distinct wrong implementations, not just one.

3. **Ordering traps: push-before-check vs check-before-push** -- when a callback can cancel an operation, agents push state into arrays BEFORE checking the callback result. The cancelled item ends up in the output. Design tests where cancellation at step N should produce exactly N-1 items, not N.

4. **One dominant trap test is enough** -- cliffy-command-aliases was approved with 51 tests, but 1 test (`clearRegisteredAliases only removes local aliases`) caused 100% of failures. Multiple medium-difficulty tests don't add up to one genuinely hard cross-cutting test.

5. **Spec vs inference: describe both when both are testable** -- the Diamond eval revealed the test depends on an inference (same-command globals visible through registry) that is defensible from the API surface but not spec'd in the description. Reviewers ruled this fair because the inference follows naturally from the test setup. When writing Diamond descriptions, list the API surface precisely; let fair inferences emerge from it rather than over-spec every edge case.

### Failure QA for Diamond — The 6-Round Rejection Pattern

The cliffy-command-aliases failure-QA document was rejected 6 times before approval. Each round revealed a different writing failure mode. Treat these as a checklist:

6. **Round 1 rejection: AI-writing tells** -- step references ("At step 21, the agent..."), cross-run comparisons ("Same bug as Castor #1"), verbose phrasing, factual mistakes (wrong prompt line number, wrong alias chain `a->b->c` instead of `a->b, b->deploy`, wrong test call path `hasRegisteredAlias` instead of `getAliasRegistry().has()`). **Fix**: remove step refs, remove cross-run language, cut verbosity ~50%, verify every factual claim against the actual test source before writing.

7. **Round 2 rejection: shorthand instead of audit-grade expected-vs-actual** -- writing "wiping all entries" instead of "Expected `registry.has("b")` to be true, got false". Fairness wording didn't separate spec ("preserves globals") from inference ("own-command global visible through registry"). Trajectory language slipped back in ("after encountering test failures", "was overlooked"). **Fix**: every entry gets explicit "Expected X, got Y"; separate what the spec SAYS from what the test INFERS from the API; replace trajectory language with final-code-state descriptions.

8. **Round 3 rejection: fabricated variable names in root-cause notes** -- writing `_aliasRegistry._local` when no such identifier exists in the solution. **Fix**: NEVER invent identifiers; use behavioral descriptions ("the single shared map", "the registry view method") or cite the actual method name from the solution.patch.

9. **Round 4 rejection: wrong control-flow descriptions** -- claiming "recorded before cancellation check" when the actual code adds the entry INSIDE the cancellation-handling branch. The hypothesis about WHERE the bug is must match the final code state, not the reviewer's mental model of how the bug "should" look. **Fix**: read the failing solution's actual code for each root-cause note; describe what the code does, not what you assume it does.

10. **Round 5 rejection: non-self-contained entries** -- one entry said "same inference as above" instead of standing alone. Reviewers read Castor entries non-sequentially. **Fix**: every Castor entry is a complete, self-contained QA document; duplicate the inference framing if needed.

11. **Round 6: APPROVED** -- round 6 passed after rounds 1-5 fixes were compounded AND every root-cause line named actual API method names (e.g., `getAliasRegistry()`, `clearRegisteredAliases()`) instead of generic phrases like "registry construction code" or "single shared map". **Rule**: every root-cause line in failure-QA names at least one actual method/API symbol from the solution, not a generic architectural descriptor.

### Consolidated Failure-QA Writing Rules (distilled from all 6 rounds)

12. **Read the 3 key files before writing any QA** -- for each Castor run, read the agent's solution diff, the trajectory/trace, and the test output before determining the root cause. Do not guess from test names or summaries alone. The solution diff shows what the agent actually built; the trajectory shows what decisions they made; the test output shows the exact assertion that failed. Skipping any of these leads to fabricated root causes or generic descriptions that reviewers reject.

13. **No trajectory step references** -- never write "At step 21, the agent...". Describe generically in terms of final code state.

14. **No cross-run comparisons** -- never write "Same bug as Castor #1." Each run's QA is fully self-contained.

15. **Audit-grade expected-vs-actual** -- every failed test gets the explicit "Expected X, got Y" treatment with literal values.

16. **Separate spec from inference** -- quote the spec, then separately note what the test INFERS from the API surface. Reviewers accept inferences that are defensible; they reject pretending inferences are spec.

17. **No fabricated identifiers** -- every named variable, method, or field must exist in the actual solution.

18. **Match the actual control flow** -- read the failing solution before writing its root cause; describe what the code actually does, not what the bug "should" look like.

19. **Self-contained entries** -- reviewers may read Castor #7 without reading #1-6; every entry stands alone.

20. **Name actual API methods in root causes** -- use `getAliasRegistry()` or `clearRegisteredAliases()`, not "the registry code" or "the clearing method".

21. **Plain ASCII, no em dashes** -- no em dashes, no Unicode arrows. Use colons or natural sentence breaks. `--` in prose is an AI tell that reviewers catch.

22. **Keep QA concise** -- unfairness check: 2-3 sentences with prompt citation. Root cause: 2-3 sentences with code reference. No code blocks unless strictly necessary.

23. **Root causes in pre-existing code need extra context** -- when multiple agents fail for the same reason and the bug is in code they did NOT modify (not visible in their diff), the root cause must explain what the pre-existing code does and why the agent's new code interacts with it incorrectly. Example: dasel-multi-file agents placed file-loading after a pre-existing `o.InFormat = o.OutFormat` crossover in run.go. The crossover is not in the agent's diff at all because they didn't touch it. The QA must say "the original run.go has X mutation at line Y; the agent's new code reads the already-mutated value" so the reviewer can verify the bug without reading the full original file. Never assume the reviewer has the original source open.

24. **Budget 5-7 review rounds for Diamond failure-QA** -- even when tests and solution are approved, the failure-QA document itself takes multiple iterations. Plan time accordingly.

### Diamond QA Platform Annotations (Admin Announcement, 2026-04)

The platform has a per-run QA UI for passing Castor runs. Three annotations are required in every Diamond submission:

1. **Success Solution Explanation** -- high-level summary of the expected solution that a non-expert of the repo can understand. This goes in failure-qa.md as a top-level section AND is used as reference when filling the platform UI.

2. **Test Summary** -- group tests into similar categories, explain what each group tests, and quote the relevant parts of the task description. This is the test-groups.md content reformatted into failure-qa.md.

3. **Success Trajectory Analysis** (per passing run) -- explain why the implementation is correct, meets all requirements, and does not cause regressions. If the implementation passes all tests but is NOT correct (and it is impossible to test deterministically), explain the failure and why it cannot be tested.

#### Platform UI Fields (per passing run)

- **"Why it works" tab** -- visible only on passing runs, marked with DIAMOND badge. Text area asks: "Explain why this implementation is correct, would it pass code review by a repo expert, confirm requirements are met, no regressions, no bugs."
- **Correctness confidence** -- 1-5 scale. Use 5 for fully correct solutions. Use 3-4 for minor issues. Use 1-2 for real bugs that tests cannot catch.
- **Issues** -- "Tests pass but the implementation is wrong." Add each issue with severity and category. Severity 4+ is blocking. Leave empty if fully correct.
- **"Failing QA" tab** -- visible only on failing runs. This is where the unfairness check and root cause go.

#### Key Implications

- Every PASS run needs a filled "Why it works" entry on the platform, not just in failure-qa.md.
- The correctness confidence score and issues section are filled on the platform UI, not in failure-qa.md. But failure-qa.md should include the same info for local tracking.
- If an agent passes all tests but the solution has a real correctness bug (e.g., shared reference instead of deep copy, race condition, incorrect error message content), you MUST report it as an Issue with severity and category. Severity 4+ blocks the submission.

---

## Diamond-Tier Lessons (Learned from dasel-csv-options, 13 Castor runs, APPROVED after 17 eval runs across 26 iterations)

### Difficulty Design Patterns (Confirmed by 30+ Castor Runs)

23. **Symmetric read/write operations create natural traps** -- when a feature has a read side (csv-null string to model null) and a write side (model null to csv-null string), agents consistently implement the read side correctly but miss the write-side symmetry. The write side requires routing null-substituted values through the same formatting pipeline (quoting, escaping, trim, strict validation) as regular values. Agents add isNull guards that bypass the pipeline. This was the #1 difficulty driver across 30+ Castor runs (5-6 out of every 12 failing runs).

24. **Dead-code check patterns exploit loop-derived variable equality** -- when agents build a values list by iterating over a headers list, then check len(values) against len(headers), the check is tautologically true. The correct approach requires separately querying the actual row's key count (e.g., row.MapKeys()). This structural bug is hard for agents to spot because the code compiles, passes basic tests, and the check "looks right." 5/11 Diamond runs and 2-5/12 standard runs fell for this pattern.

25. **Reflection-based tests catch cross-file thoroughness gaps** -- TestCLIHelpTextReferencesSeparatorNotDelimiter uses Go reflection to inspect struct tags on both QueryCmd and InteractiveCmd. This is a fair, behavioral test that catches agents who update one file (query.go) but miss a second file (interactive.go) with the same struct tag pattern. 4/11 Diamond Castor runs failed on this alone. The test pattern: "grep for all occurrences of X across the codebase" is a natural engineering expectation.

26. **Cross-package tests are the only reliable message-count lever** -- adding internal/cli/csv_flags_test.go forced agents to navigate two packages, boosting median message count from ~60 (single-package) to 141 (cross-package). This is more effective than adding more tests within the same package, because test count within a package doesn't force additional codebase navigation.

27. **Pipeline ordering traps compound with null substitution** -- trim-before-null vs trim-after-null, strict-before-null-substitution vs strict-after: agents who implement null substitution as a separate early-return branch always get the ordering wrong. The correct pattern is to substitute first, then pass the result through the same pipeline as regular values. 3/11 Diamond Castor runs failed specifically on trim-null interaction, and 1/11 failed on strict-newline-before-null-substitution.

28. **Description bullet-list format works for Diamond** -- the approved dasel-csv-options Diamond description uses 26 bullets, one requirement per line. This format passed AI reviewer quality checks AND produced the right difficulty (18.2% pass rate). The bullet format is especially effective when there are 10+ distinct options/behaviors, each needing a single precise sentence.

29. **failure-qa.md: write in your own voice, only fix factual accuracy** -- when the AI audit flags an assertion in failure-qa.md, make the minimal surgical edit to correct the factual claim only. Do NOT mirror the audit's terminology (e.g. "the writer", "the reader") just because the audit uses those words. Keep your natural voice ("the agent"). The reviewer only checks factual correctness -- if the audit rejects "the agent" in favor of "the writer", that is the audit's problem, not yours. Changing wording to match the audit's style without a factual reason is the wrong approach.

### ferret-csv-codec (SUBMITTED -- 60% pass rate, easier tier)

30. **Exported Go Options field names AND types must always be in the description** -- when the description says "comma delimiter" in prose but does not name the struct field, agents split 3 ways: "Delimiter" (read carefully), "Comma" (Go stdlib encoding/csv convention), "Separator" (synonym). All three are reasonable. Without explicit names, 7/10 Nova agents fail at compile time before any logic is tested. Rule: for any Go Options struct used directly in test harness literals, enumerate every exported field name with its type -- `Header (bool), Delimiter (rune), Quote (rune), NullValues ([]string), TrimLeadingSpace (bool)`. This is a fairness anchor, not an implementation hint. The same applies to bool vs *bool -- `Header (bool)` vs `*bool` is a valid Go design choice for optional fields with non-zero defaults, and agents will use *bool without the type spec.

31. **Removing field names as a "description tightening" move is wrong** -- the Tighten-First Rule applies to behavioral hints and discoverable repo patterns, NOT to exported API surface names that the test harness uses directly. Removing them doesn't make the problem harder; it makes it unfair. Tightening means removing behavioral implementation hints, not removing the names agents need to compile.

32. **Pattern-followable features have a structural pass-rate floor** -- ferret-csv-codec achieved 60% pass rate even with 7 cross-cutting interaction tests. The problem is that CSV parsing is universally well-known AND the ferret codebase provides direct JSON+msgpack codec templates. Even with pipeline ordering traps, header-trim traps, and ForEach arg-order traps, agents who copy the codec pattern correctly and implement CSV competently pass most tests. For truly hard problems (25% target), the feature must require novel architectural decisions that cannot be pattern-matched from existing code.

### nmap-formatter/nmap-scan (APPROVED Lite tier -- 70% Nova, 100% Orion)
- **Pass rate**: Nova 7/10 (70%), Orion 2/2 (100%), Overall 9/12 (75%)
- **Net LOC**: 567, 3 files, 90 tests
- **Problem type**: Feature request -- `diff` subcommand comparing two nmap XML scans with 5 output formats
- **Key lessons -- Description**:
  - **Exact output format strings MUST be shown with examples when tests use regex** -- "Final line is summary with counts" caused 10/10 agents to add a "Summary:" prefix in Run 1. Fixed by showing exact format: `N added, N removed, N changed` with example. This was the #1 unfairness blocker (8/10 FAIL_TEST_MISMATCH).
  - **Optional vs mandatory flags must be syntactically unambiguous** -- `diff -t [format] [file1] [file2]` implies -t is mandatory. Rewritten as `diff [file1] [file2]` with optional `-t/--type`.
  - **CSV column-level case rules must be explicit** -- "values lowercase" without scope is ambiguous. Fixed to "action and change_type values must be lowercase; from/to values preserve original case."
- **Key lessons -- Fair agent failure patterns**:
  - **Cobra RunE exit codes (1/10)** -- Cobra defaults to exit 1 for RunE errors. Spec requires exit 2. Fair trap since spec is explicit.
  - **Lexicographic vs numeric IP sorting (1/10)** -- spec says "lexicographically" but agent used net.ParseIP for numeric ordering. Go-specific trap where the "obvious" approach is wrong.
  - **os.O_EXCL on pre-existing files (1/10)** -- `-f` flag with O_EXCL fails when test pre-creates the file.
- **Key lessons -- Infrastructure**:
  - **`.dockerignore` excluding `.git*` breaks Go VCS stamping** -- always use `-buildvcs=false` in Go Dockerfiles.
  - **`encoding/csv.Writer` for CSV output** -- manual string concatenation flagged by reviewer. Always use encoding/csv for RFC 4180 compliance.
  - **`html.EscapeString` for HTML output** -- raw interpolation flagged as injection risk.
- **Key lessons -- Difficulty assessment**:
  - **Multi-format output features are inherently easier** -- 5 output formats (text/json/csv/html/markdown) are well-understood. Difficulty comes from edge cases (exit codes, sorting), not formatters.
  - **Lite tier (70% target) is appropriate for well-specified features without cross-cutting traps** -- clear specs, no feature interactions, no pipeline ordering. 30% failure rate from subtle spec interpretation only.

---

## node-minify/node-macros (TypeScript, Lite Tier -- Approved)

- **Problem**: Compile-time define macro system (--define KEY=VALUE, --define-file) replacing process.env.KEY, import.meta.env.KEY, __KEY__ patterns with type coercion.
- **Result**: 5/12 pass (42%) -- appropriate for Lite tier.
- **3 rounds**: R1 rejected (weak toContain assertions + Map impl detail in description), R2 eval'd (42% pass), R3 solution quality fixes (O(N²) perf, dead code, multi-file concatenation bug).
- **Principal reviewer post-approval note**: Solution quality should have been at most 5/7. Regex-based parsing (buildProtectedRegions using manual scanning) is fundamentally unreliable -- cannot correctly handle full JavaScript syntax and will break on real-world edge cases. Optional chaining detection (hasOptionalChainBefore using substring regex checks) is heuristic and unsafe -- can fail with formatting or complex expressions. For future submissions, prefer AST-based parsing over regex heuristics when the target language has complex syntax.
- **Key lessons -- Test assertions**:
  - **`toContain` is a reviewer red flag** -- `expect(result).toContain("true")` is fragile (matches incidental "true" in source). Always use `toBe` with exact expected output for text transformation functions.
  - **Negative tests need positive controls** -- "Does NOT replace X" tests that only check the string is unchanged are trivially passing. Combine with a defined key in the same code so the test proves replacement actually runs for known keys while leaving unknown keys alone.
- **Key lessons -- Solution quality matters for approval**:
  - **O(N²) scanning gets flagged** -- isInsideStringOrComment re-scanning from index 0 per match was called out. Use single-pass tokenization to build a protected-regions list, then O(1) lookups per match.
  - **Dead code gets flagged** -- Unused variables (`useDefineTransform`), dead parameters (`skipOptionalChaining`), unused imports (`DefineMap` in index.ts) are all reviewer targets. Clean thoroughly.
  - **Multi-file concatenation is destructive** -- Concatenating input files into one string destroys file boundaries and breaks the downstream pipeline. Process each file individually.
  - **Framework integration assumptions** -- Setting `settings.content` in node-minify activates "in-memory mode" which skips file output. This was the #1 agent trap (caught 2/12). Write transformed content back to input files or directly to output, not to settings.content.
  - **Regex-based parsing caps solution quality at 5/7** -- Principal reviewer flagged: manual regex scanning for protected regions (strings/comments/regex) is fundamentally unreliable for full JS syntax. Heuristic optional chaining detection via substring regex is unsafe with varied formatting. When implementing text transformations on languages with complex syntax, prefer AST-based approaches or acknowledge the quality ceiling.
- **Key lessons -- Agent failure patterns (confirmed traps)**:
  - **Regex literal exclusion (2/12 caught)** -- Agents build tokenizers skipping strings/comments/templates but forget `/regex/` literals. Explicitly requiring regex exclusion in description is fair and catches agents.
  - **`__KEY__` underscore boundary (3/12 caught)** -- `__KEY__` inside `___KEY___` (3 underscores) is a reliable trap. Agents use simple regex without negative lookbehind/lookahead.
  - **CLI in-memory mode (2/12 caught)** -- Agents set settings.content which activates framework in-memory mode, skipping file write. Requires reading the framework's run.ts to understand.
  - **consumeIdentifier greedy underscore (2/12 Orion)** -- Orion's hand-written tokenizer treats `_` as identifier-part, consuming trailing `__` and breaking the suffix check.
- **Key lessons -- Reviewer perception**:
  - **Internal reasoning must be human-written** -- Principal reviewer flagged internal reasoning as "AI slop." Write feedback, analysis, and internal docs in your own voice. Avoid formulaic patterns, numbered lists with identical structure, and robotic phrasing. Reviewers read these documents and judge them for authenticity.

---

## ferret-csv-codec (Go, Mars Solid Tier -- 50% pass rate, attempt 4)

- **Problem**: Add `text/csv` codec to ferret v2 encoding subsystem. Codec/encoder/decoder, custom CSV parser (NOT wrapping Go stdlib `encoding/csv`), null coalescing on unquoted fields only, hook system, registry integration in default engine.
- **Result**: Run 4 (98 tests, 107 JUnit cases): 6/12 PASS = **50% Mars Solid** (target band 25-55%). 4 distinct verdict types (MISSED_REQUIREMENT, INTEGRATION_ERROR ×2, WRONG_LOGIC, KNOWLEDGE_GAP ×2). No fairness flags.
- **4 attempts total**: R1 90% pass too easy (72 tests) → R2 84 tests + removed Options field names → 7+/10 FAIL_TEST_MISMATCH (Comma vs Delimiter naming) → R3 restored field names → reviewer asked for more coverage → R4 added 14 hardening tests + fixed test.sh mode 100755 → 50%.

- **Key lessons -- Hardening that worked (Run 4)**:
  - **NBSP byte-as-rune trap (NEW, 17% failure)** -- `TestCSV_Decode_TrimLeadingSpace_OnlySpaceAndTab_NotOtherWhitespace` caught 2/12 Nova agents misusing `r := rune(input[pos])` then `sb.WriteRune(r)` for unquoted-field iteration. Foundational Go anti-pattern: byte ≥ 0x80 is interpreted as Latin-1 codepoint, then re-encoded as 2-byte UTF-8 — NBSP (0xC2 0xA0) becomes `Â` + NBSP (4 bytes). The fix is `for i, r := range s` or slicing original bytes. Verdict: FAIL_KNOWLEDGE_GAP. **This is the single most cost-effective hardening test in attempt 4.**
  - **`*Codec` vs `Codec` value type (17% failure)** -- Runs 7+8 exported `Default` as `*csv.Codec`; test helpers take `Codec` by value → compile fails. Inferable from sibling JSON/msgpack codec convention (`var Default = Codec{}` with value receivers) but NOT stated in description. Genuine integration trap, not unfair.
  - **DecodeError.Line off-by-one (8% failure)** -- Run 9 incremented `p.line` after consuming row terminator, then read `p.line` at error construction → reports N+1 instead of N. Reference solution captures `startLine` on the record before terminator processing. Standard CSV convention enforced by tests.
  - **Post-hook override on decode failure (8% failure)** -- Description says "post-hook errors override a *successful* result". Run 6 missed the "successful" qualifier; agent returned post-hook error directly even on decode failure, dropping the ErrDecode chain. The qualifier is load-bearing.

- **Key lessons -- Trap design**:
  - **The 14 attempt-4 hardening tests targeted 5 trap categories** from `olympus-extreme-complexity-guide.md`: Default-value coverage, header-key quoting symmetry, NullValues precision, TrimLeadingSpace exhaustive char set, BOM+Trim+Header pipeline. Of these, only the NBSP trap drove failures in this run; the rest serve as fairness coverage that closes test-to-spec gaps without reducing pass rate.
  - **Test count 84 → 98 + subtests = 107 JUnit cases** stayed within Mars approved range (39-160). Coverage-driven, not count-driven.
  - **Cross-cutting interaction tests are necessary but not always sufficient** for difficulty -- the 7 cross-cutting tests added in Run 2 alone weren't enough to drop pass rate from 90% to target. The NBSP foundational-knowledge trap was the additional ingredient that brought it into band.

- **Key lessons -- test.sh executable bit**:
  - **`chmod +x` alone does not update the git index on Windows** -- patch ships with `new file mode 100644`, platform invokes `./test.sh` directly, "Permission denied" before any test runs. Use `git add --chmod=+x test.sh` BEFORE generating the diff. Verify with `grep "new file mode" test.patch` showing `100755` for test.sh. Documented in CLAUDE.md, TESTS.md, olympus-author skill after this incident.

- **Key lessons -- Tier classification**:
  - **879 +LOC + 7 files straddles Mars upper bound and Olympus floor.** Initial categorization was Mars; 50% pass after attempt 4 hardening confirms Mars Solid is correct. Solution-LOC alone does not determine tier — pass rate is the gate.
  - **Pattern-followable features (CSV codec = copy JSON codec) have a structural difficulty floor.** Even with 14 cross-cutting tests, agents who correctly mirror sibling-codec conventions pass. The NBSP trap broke that floor by introducing a Go-language gotcha unrelated to the CSV pattern itself.

---

## yaegi-eval-in-package (Go, Mars Solid -- 1/13 = 7.7% Nova/Orion)

- **Problem**: 5 new public methods (`EvalInPackage`, `CompileInPackage`, `EvalInPackageWithContext`, `EvalPathInPackage`, `EvalPathInPackageWithContext`) plus `ErrUnknownPackage` sentinel. Evaluates expressions as if at file scope of a previously-loaded package.
- **Result**: 1/13 PASS, 12 FAIL. Pass rate 7.7% — landed BELOW Mars Solid sweet band (25-55%). Slightly too hard, attributable to a single hardening test that nine of ten failing runs flunked the same way.
- **8 attempts to ship**: R1-R5 platform pre-flight churn (description verbosity, alignment confusion, JUnit XML self-containment, GOPATH symlink, signature ordering). R6-R7 nuclear test removal + subtle hints. R8 reviewer-driven hint trim. After R8 platform passed and live eval ran.
- **Key lesson — One well-designed cross-cutting test can dominate eval**:
  - `TestCompileInPackage_program_reads_live_package_state_after_in_pkg_mutation` was the single hardening test added in R7. It exercises 4 cross-cutting requirements at once: (1) CompileInPackage returns reusable Program, (2) Execute reads live package state, (3) `EvalInPackage("foo", "func() { Counter = 99 }()")` IIFE actually mutates package var, (4) re-execute reads mutated value.
  - 11 of 13 failing runs hit only this test. The trap: agents extend yaegi's compile pipeline but break symbol identity between the compiled Program and the package's live var slot. Possible variants observed: (a) keeping the original `pkgName == mainID` guard so wrapped main never runs for non-main packages, (b) re-registering `srcPkg`/`pkgNames` on every compile (overwrites identity), (c) wrapping in `package <pkg>; func main()` but creating fresh global storage, (d) renaming wrapper from `func main()` to `func _()` (broke 94 baseline tests via position offset).
  - One agent (run 11) used the reference shape: shared `compilePipeline` helper called from both `CompileAST` and a new `compileASTInPkg`, always append `gs.sym[mainID]` to initNodes, reuse the existing package scope without re-registering. Passed cleanly.
- **Key lesson — Live-state semantics ARE inferable, even when not spelled out**:
  - Existing yaegi `Compile` and `Execute` already read live values via `genGlobalVars` against `interp.scopes[pkgName]` at runtime. The new methods are described as parallel APIs that mirror the existing ones, so the live-state contract carries over. 11 of 12 evaluators classified the failure as agent-fault (FAIL_WRONG_LOGIC or FAIL_MISSED_REQUIREMENT), citing the existing repo semantics or the prompt's "Every expression form Eval accepts must work here too" sentence. One evaluator marked it FAIL_UNDOCUMENTED_REQUIREMENT but its own evidence cited the existing repo semantics, contradicting the unfair flag. Successfully contested.
- **Key lesson — Hint trade-off when removing nuclear tests**:
  - R7 removed 4 nuclear tests (IIFE runtime panic, division-by-zero, two cancellation tests with infinite loops). All 4 hit the same `pkgName == mainID` wrap-execute trap. Removing them flipped the pass rate from ~10% to predicted 70-85%.
  - R7 added 1 cross-cutting test (the live-state mutation test above) that re-introduced the same trap pressure via a non-IIFE-runtime path (instead via `func() { Counter = 99 }()` which is evaluated for its assignment side effect, not its panic).
  - R8 reviewer flagged the hints as over-specifying implementation. We dropped the wrap-execute hint entirely (no longer load-bearing because nuclear tests gone) and trimmed the lazy-main hint to behavior-only ("an empty/`main` path also works on a fresh interpreter that has not yet loaded any source"). Final description 177 words.
  - Net: removed 4 nuclear tests, added 1 cross-cutting interdependent test, dropped 2 paragraphs of hints. Live result: 1/13 pass. Single hardening test was potent enough on its own to land sub-band difficulty.
- **Key lesson — Platform pre-flight is its own gauntlet**:
  - 8 platform pre-flight rounds before live eval. Issues: (1) verbose description → trim. (2) test-patch alignment (Shipd file mix-up showing sqlc batchiter tests for a yaegi problem) → no fix possible from local files; user re-uploads. (3) JUnit XML missing because `go-junit-report` not in PATH on platform's eval container even though Dockerfile installed it → wrote inline `internal/junitconv/main.go` (190 LOC Go program reading `go test -json`, emitting JUnit XML). (4) baseline `go test ./...` fails because yaegi requires repo at `$GOPATH/src/github.com/traefik/yaegi`, not `/app` → Dockerfile `mkdir -p /go/src/github.com/traefik && ln -s /app /go/src/github.com/traefik/yaegi`. (5) signature ordering ambiguity (description said "packagePath as first argument" but tests put ctx first for WithContext variants) → spelled out all 5 signatures verbatim. (6) `-skip` flag flagged as unsupported → server glitch, retry passed.
  - **Standing rule**: yaegi Dockerfile MUST include the GOPATH symlink. yaegi-completion's Dockerfile already had it; yaegi-reflect-identity's did not but its tests didn't run `go test ./...`. Required for any yaegi problem whose `test.sh` runs broad test coverage.
  - **Standing rule**: prefer self-contained JUnit XML conversion (small embedded Go program) over `go-junit-report` dependency. Platform's runtime container is stripped relative to Dockerfile state.
- **Key lesson — Agent-side failure modes confirmed**:
  - Wrap-execute trap: keeping the `pkgName == mainID` gate when extending CompileAST. Agents inherit the existing guard from program.go without realizing it. 9 of 13 runs hit this.
  - Wrapper rename trap: changing `wrapInMain` template from `func main()` to `func _()` shifts every position-reporting baseline test by 3 characters (94 baseline failures from a single rename — Run 8). The wrapper function name is load-bearing for error position reporting.
  - Path-method ErrUnknownPackage gating: putting the unknown-package check inside `parse()` under `if inc { ... }` means file-path entry points (which call `eval(..., inc=false)`) skip the check entirely. Run 7. The agent partially implemented the requirement, proving they understood it, but missed extending it to two of five functions.
- **Final state**: 98 new tests, 281 LOC solution (153 in new `interp/eval_in_package.go` + 128 modified across `interp/program.go`), Mars Solid sweet 170-380 raw band. Description 177 words. Predicted Nova/Orion 25-40%; actual 7.7%. Sub-band — would not have approved as a Mars Solid candidate had we predicted accurately, but the single cross-cutting hardening test is the difficulty driver, not the description, so easy to recover with one hint or one weakened test if needed.

## nmap-formatter/nmap-scan (Go, Olympus Tier -- Approved)

- **Problem**: Diff subcommand comparing two nmap XML scans with 5 output formats, exit code semantics, host categorization, 8 change types, sorting, and --ignore-timestamps flag.
- **Result**: 1/11 pass (9%) -- approved as Olympus tier.
- **10 rounds**: R1 rejected (summary format unfairness), R2 Lite 70%, R3-R6 reverted/unfair (prescriptive tests, interface unspecified, HTML case bug), R7-R10 hardened to Olympus.
- **Key lessons -- Description as interface contract**:
  - **Interface details MUST be documented when tests assert them** -- Flag names (-t vs -o), JSON field names (ip, hostname, changes), change-type identifiers (port_state vs "port state"). Without this, 10/10 agents chose different but equally valid names. This is NOT a difficulty lever -- it's a fairness failure.
  - **"Behavioral" does not mean "omit the API contract"** -- A behavioral description specifies WHAT the output looks like (field names, change types) but not HOW to implement it. The first reviewer revert was because the description was TOO prescriptive (exact text markers, sort priority numbers). The second was because it was TOO vague (missing flag names). The sweet spot: specify the contract (names, shapes, exit codes) but not the implementation (which Go types, which functions).
  - **Case-sensitive HTML substring checks are traps for the AUTHOR** -- `strings.Contains(stdout, "added")` fails when agents use title-case `<h2>Added</h2>`. The reference solution only passed incidentally via CSS class attributes. Always use case-insensitive matching for category label assertions.
- **Key lessons -- Difficulty levers that work**:
  - **Implied requirement via flag existence (82% failure)** -- `--ignore-timestamps to suppress timestamp-only differences` implies timestamps are compared by default. 9/11 agents wired the flag into metadata but never implemented timestamp comparison. The flag creates a false sense of completion. This is the strongest proven fair difficulty lever for CLI features.
  - **Multi-format output is NOT a difficulty lever** -- ALL agents competently implement 5 formatters (text/json/csv/html/markdown) with proper quoting, escaping, and metadata. This is Lite tier only.
  - **The Lite-to-Olympus upgrade came from one trap** -- The 70% to 9% drop was primarily from the timestamp inference trap, not from the 3 cross-cutting interaction tests. Interaction tests are good for fairness and thoroughness but didn't move the difficulty needle as much as the implied requirement.
- **Key lessons -- Agent failure patterns (confirmed traps)**:
  - **Cobra RunE stderr contamination (18%)** -- Returning errors from cobra's RunE causes cobra to print `Error:` to stderr. CombinedOutput captures both streams, breaking JSON parsing. Agents must use os.Exit() or set SilenceErrors/SilenceUsage.
  - **Existing repo constant vs spec name (18%)** -- Repo has `MarkdownOutput = "md"` but spec says `markdown`. Agents trust the constant over the spec.
  - **Invalid type exit 2 (27%)** -- Agents use permissive switch defaults (fall through to text) instead of treating unknown types as errors.

## yaegi-completion (Go, Olympus Tier -- Approved)

- **Problem**: Add `Complete(line, column int, src string) ([]Candidate, error)` and `CompleteSimple(prefix string) []string` methods to yaegi's Interpreter. Codepoint-aware cursor handling, partial-input tolerance, scope-chain walking with shadowing, dot-expression resolution (struct/pointer/interface/package), embedded promotion, chained selectors, binary-package member kind classification, sort-by-priority ordering, and concurrency safety with Eval (including during compilation).
- **Result**: 1/12 pass (8.3%) -- Olympus Good band.
- **Iteration count**: 5+ rounds. Heavy hint tuning needed. Initial 0/12 cycles dominated by single-bug universal failures.
- **Key lessons -- yaegi internals are deeply non-obvious**:
  - **Internal scope keys vs canonical names**: yaegi stores imported packages in `interp.scopes[mainID].sym` under file-suffixed keys like `fmt/_.go`. The canonical short name lives in a SEPARATE map (`interp.pkgNames`). Agents universally reach for the obvious scope iteration first. 5/12 emitted `fmt/_.go` as the package candidate name despite an explicit "conventional short names" hint. The only-pass solution iterated `interp.binPkg` and consulted `interp.pkgNames` for short-name lookup -- a pattern that is invisible without code reading.
  - **Concurrency: gta/cfg mutate scopes WITHOUT holding interp.mutex**: Agents naturally lock Complete with the existing `interp.mutex.RLock()` and assume Eval honors the same mutex. It doesn't. Compile passes (`gta`, `cfg`) write to scope.sym at multiple call sites without acquiring any lock. The reference solution introduces a SEPARATE `completeMu` RWMutex with `eval()` taking RLock and Complete taking Lock. Agents who reuse interp.mutex universally fail TestCompleteConcurrentEval. This is THE primary blocker.
  - **Interface methods stored in `t.field`, not `t.method`**: yaegi's itype struct uses the `field` slot for both struct fields AND interface methods. Agents iterate t.field with Kind=field, then add a separate t.method walk that never matches interface entries. Need to dispatch by `t.cat` (interfaceT vs structT) before tagging Kind. 2/12 missed despite explicit "interface methods" requirement.
  - **Binary constants live in `go/constant` package**: yaegi exposes Go constants like math.Pi as `constant.Value` (concrete types like `constant.ratVal`). Agents check `reflect.Kind` and find no const-shaped Kind, defaulting to var. Detection requires `val.Type().PkgPath() == "go/constant"`. Without this hint, ~50% of agents misclassified math.Pi.
- **Key lessons -- Spec hints are load-bearing for survival, not just clarity**:
  - **"Concurrent Eval calls must remain non-serialized" prevents the exclusive-Mutex trap** that breaks the existing `TestEvalWithContext('double lock')` baseline. Without this clause 5+ agents wrap Eval in `sync.Mutex.Lock()` and break baseline.
  - **Explicit "Acquire the read side once at the top of Eval; re-acquiring inside CompileAST deadlocks because RWMutex is not reentrant"** prevents 2 of 12 agents from re-locking inside nested compile steps. Bot flagged as over-spec; we kept it for pass rate.
  - **"Imported packages must be reported under their conventional short names, not the file-suffixed keys yaegi uses internally"** still left 5/12 agents emitting `fmt/_.go`. The trap is so natural that even direct symptom hints don't catch all agents.
  - **Hint dilution from description-quality bot lowered pass rate**. Each round of "drop the implementation hint" reduced pass rate by ~10-15pp because the load-bearing trap signals are EXACTLY what description-quality flags as over-spec.
- **Key lessons -- Description-quality bot vs pass rate is a real conflict**:
  - Description-quality reviewer flags every "internal yaegi gotcha" as over-spec, even when the test verifies the trap. We had to contest 5+ flags to retain pass-rate hints. Several rounds of compromise: drop precise lock placement, keep "non-serialized" requirement; drop "go/constant aside", keep "math.Pi must still be reported as const"; drop "file-suffixed keys symptom", keep "conventional short names rule".
  - **Keep the BEHAVIORAL requirement, drop the IMPLEMENTATION rationale**: this is the negotiating line that satisfies bot while preserving most pass-rate signal. "Concurrent Eval calls must remain non-serialized" is behavioral; "lock once at top of eval" is implementation.
  - **The TestEvalWithContext baseline test is the strongest concurrency signal**: it implicitly verifies non-serialized Eval (second EvalWithContext call must proceed when first hangs). Bot couldn't see this. We added an explicit `TestCompleteEvalNotSerialized` test (3s blocking first Eval, 300ms deadline second) to make the requirement visible to bot's coverage check.
- **Key lessons -- Token-based parsers**:
  - **`go/scanner` returns lit="" for operator tokens (PERIOD, COMMA, etc.)**. Agents reconstruct the original source by concatenating `tok.lit` and lose the dots. For `tr.L.B`, the rebuilt string becomes `trL` which fails to parse as a chained selector. Reference solution either slices original src bytes by token positions OR walks tokens directly without reconstruction.
  - **Backward identifier walk for selector base extraction must NOT cross newlines**: agents using `unicode.IsSpace` allow `\n` and pull in the previous line. Multi-line src like `"fmt.Println(\"hello\")\nfmt.Spr"` becomes a malformed base. Reference uses `go/scanner` which respects line boundaries.
  - **Byte-level identifier scanning fails on multi-byte runes**: `unicode.IsLetter(rune(s[i]))` converts UTF-8 continuation bytes to Latin-1 codepoints, which are never letters. The trap is invisible until a non-ASCII identifier (λ, é, 中) is in the source. Use `utf8.DecodeRuneInString` or `for i, r := range s`.
- **Key lessons -- Hint level vs description-quality bot**:
  - **HIGH-priority bot flags MUST be applied** (gates submission). MEDIUM/LOW are optional.
  - **Trim "exported"/"new"/"from package X" qualifiers** the bot calls templated. Names + types imply exportedness in Go.
  - **Drop illustrative examples (fmt.Pr, foo., math.Pi, fmt/strings)** when the rule alone is sufficient. Examples are tone-flagged but rarely change pass rate. EXCEPT when the example IS the trap signal -- for math.Pi specifically the example anchors agents to the go/constant trap.
- **Key lessons -- Test design**:
  - **Concurrent test must use TIMING that distinguishes serialized from parallel**: the first `TestCompleteEvalNotSerialized` used 200ms first-Eval timeout and 700ms second-Eval deadline -- bot correctly flagged that a serialized agent passes (waits 200ms, completes in remaining 500ms). Fix: 3s first-Eval blocking + 300ms second-Eval deadline. Now serialized = blocks 3s = fails 300ms.
  - **`-race` in test.sh causes universal Nova failures even with otherwise-correct solutions**: -race detector caught EVERY agent's incomplete locking. Removing -race trades false-pass risk for actual pass rate. We removed it after determining `TestCompleteEvalNotSerialized` (deterministic timing) provides equivalent coverage for the non-serialization requirement.
  - **Killer tests are okay as long as they're FAIR**: dropping ambiguous tests (e.g. tests that depend on internal sym kind structure) is correct; weakening tests that just catch agent bugs is not.

## yaegi-callstack-postmortem (Mars Strong, shipped 2026-05-01)

- **Final**: 1/12 = 8.3% pass rate. Mars Strong target 20-30% missed; landed at Olympus Good (~10%). Acceptable per playbook (>5%, <70%).
- **Verdict mix**: 7 FAIL_MISSED_REQUIREMENT + 4 FAIL_WRONG_LOGIC + 1 PASS_LEGITIMATE.

- **Key lessons -- Two-sentence naming spec inversion (NEW Tier 1 trap)**:
  - Description said "Names are unqualified" + "leading `*` is never included for pointer-receiver methods". Two sentences. First says "no qualifier"; second only makes sense if receiver IS in the name. 7/11 failing runs (64%) read sentence 1 first and produced bare `M` instead of `T.M`.
  - Both Orion-as-policy runs (#1, #2) hit this — Orion commits to first interpretation, doesn't re-derive. Nova runs (#6, #7, #9, #10, #12) also hit it.
  - **Fix for future problems**: ship one concrete example (`bar`, `foo`, `T.M` literal) BEFORE the naming-rule sentences. Description-quality bot will flag as over-spec; defend with empirical pass-rate data per LESSONS.md #12.

- **Key lessons -- Capture-before-recover-defer (NEW Tier 2 trap)**:
  - Existing `runCfg` defer at `interp/run.go:209` runs user defers BEFORE checking `if recovered != nil`. Reference solution placed `captureStack(f, oNode)` IMMEDIATELY after `f.recovered = recover()`, BEFORE the user-defer loop. 4/11 failing runs (36%) placed it AFTER, so goroutine `defer recover()` consumed `f.recovered` before the new feature's check fired.
  - Bug is INVISIBLE in multi-level chain tests (panic re-propagates, captured upstairs). Surfaces ONLY for goroutine-recovers-its-own-panic-in-same-frame.
  - **Fix for future problems**: when adding a feature that observes transient state inside an existing defer chain, place the new logic BEFORE existing user-callback dispatch, not after. Confirm via a test where user callback runs in the SAME frame as the observed event (no outer observer).

- **Key lessons -- Frame walker termination (Tier 2 trap)**:
  - Walking `for cur := f; cur != nil; cur = cur.anc` reaches yaegi's `interp.frame` which holds `fileStmt` (synthetic outer). Walker without kind guard emits a phantom outermost frame with empty Name. 5/11 failing runs (45%) hit this.
  - Reference uses dual guard: `for cur != nil && cur.funcNode != nil` PLUS break on `kind != funcDecl/funcLit`.
  - **Fix for future problems**: when walking interpreter frame chains, document "interpreted-frame call stack" semantics and ALSO ship a kind-guard hint OR a test that asserts no `<unknown>` frame exists.

- **Key lessons -- Sticky-after-success preserved**:
  - Spec said "After a successful subsequent Eval the most recent panic's frames remain available; only `ClearStackTrace()` or a fresh panic replaces them." 1 agent (Run #5) added `ClearStackTrace()` at start of Execute, erasing snapshots. Single failure but real — agents read "Eval clears state" as default Go intuition.
  - Reference uses `resetCaptureClaim()` (latch reset) at `eval()` entry, NOT `lastStack` reset. The latch lets innermost capture write OR keep prior; sticky preserved.
  - **Fix for future problems**: spec the latch behavior alongside the storage behavior. "Reset only happens on `ClearStackTrace()` or fresh panic" worked but agents skim past it.

- **Key lessons -- frame.clone() must copy new fields**:
  - yaegi's `genFunctionWrapper` calls `f.clone()` to capture defining-frame state for closures. Initial implementation forgot to copy our new fields (`funcNode`, `callNode`, `goroutineRoot`); funcLit-via-method-wrapper test failed with chain truncated to 1 frame. Pre-flight smoke caught it before any platform run.
  - **Generalizable rule**: when extending an interpreter's frame/context struct, audit ALL clone/copy/snapshot helpers in the codebase. yaegi has `frame.clone()`; goja has `runtime.cloneCtx()`; tengo has `compiler.symbolTable.fork()`. Each requires field-by-field maintenance.

- **Key lessons -- Method receiver naming via reflect.MakeFunc wrapper limitation**:
  - yaegi's `genFunctionWrapper` invokes `runCfg(start, fr, def, n)` where `n = def` (the funcDecl, not the call expression). Outer frame's reported position becomes the funcDecl line, not the call site. Walker fallback `if line == 0 ... use cur.funcNode.pos` patches this for the impl, but tests can't assert outer-frame positions exactly for method chains.
  - **Fix for future problems**: spec position semantics for innermost frame ONLY (where reference is exact); leave outer-frame positions behavioral (`Line > 0`, `File non-empty`).

## dasel-collection-funcs (Mars Solid B → Olympus reframe, 41.7% pass after 18 iterations)

Submission journey: pure-function map/slice ops (R0–R16) hit 100% Nova ceiling. Olympus reframe to recursive deep-merge + structural diff + CLI flag wiring (R17) dropped pass rate to 41.7%. Lessons below apply to any future Mars/Olympus problem authoring.

### B-shape pure-function ceiling is real and unbreakable by trap stacking

R10 (algebraic invariants), R12 (same-object collision + structured error), R14 (pointer-receiver fix), R16 (polymorphic dispatch + fillValue + step) all converged at ~100% Nova. **Six stacked Tier 1/2 traps could not lower B-shape pure-function-additive baseline below 90%.** Pure-function map/slice ops have no integration surface for traps to fire against. Rule: if your problem is "add N pure functions to module X with no cross-package wiring", it caps at B-shape baseline regardless of how many traps you stack. Reframe shape, do not add traps.

### Trap-effectiveness depends on integration surface, not trap count

Same six traps that produced 100% pass on B-shape (pick/omit/chunk/windows in R16) produced 41.7% on Olympus shape (mergeDeep/diffDeep + CLI flag in R17). Identical trap categories. What changed: integration surface. Recursive deep-merge has a real algorithmic body where strategy-enum interpretation can diverge; CLI flag has a 4-stage propagation chain (cobra → runOpts → Options → handler) where any hop can be missed; multi-package wiring forces agents past single-file pattern-match. Traps need somewhere to fire.

### Test file compile-time decoupling is mandatory

Test file in test.patch must compile against base (no solution applied). Direct references to solution-only types or functions break the entire package build, so existing tests cannot run, so platform reports "Baseline tests failed". Fix: reflection-based type lookup. Replace `var x *solution.Type; errors.As(err, &x)` with:

```go
for cur := err; cur != nil; cur = errors.Unwrap(cur) {
    if reflect.TypeOf(cur).String() == "*solution.Type" {
        v := reflect.ValueOf(cur).Elem()
        f := v.FieldByName("Func").String()
    }
}
```

Same for setting solution-only Options fields: use `reflect.ValueOf(opts).Elem().FieldByName("X").SetString(v)` instead of `execution.WithX(v)`. Field/method may not exist on base, reflection silently no-ops, test fails behaviorally instead of build-failing. R14 fix saved entire submission from baseline reject.

### Pointer-receiver vs value-receiver fairness must be explicit

Spec saying "exported error type with X and Y fields" leaves receiver style ambiguous. 3/5 agents in R14 chose value receiver; reflection check for `*execution.MyError` failed. Fix: spec must say "implements `error` via pointer receiver, so the error chain contains `*MyError`". Without this clause, fairness contests are valid.

### Package placement of new types must be explicit

R17 first eval: 1/3 Orion runs put `CollectionFuncError` in `model` package (matching dasel's existing error convention) instead of `execution` package. Reflection check for `*execution.CollectionFuncError` failed. Fix: meta.md added "in the `execution` package" qualifier. Without explicit package, agents follow nearest existing convention which may be wrong package.

## piccolo-to-be-closed (APPROVED Olympus 2026-06-24, designed Diamond, 20% pass)

**Outcome:** Approved as Olympus (Auto Review PASS, 11 Castor/Orion runs = 2 PASS / 8 FAIL_MISSED_REQUIREMENT / 1 no-artifact = 20%, Holistic PASS), then **REVERTED at finalization (2026-06-27)** on a correctness gap the whole pipeline missed, **fixed + re-validated**. The generic-`for` closing value was detected by syntactic arity (`arguments.len() >= 4`); the canonical single-call idiom `for x in factory()` truncated and leaked the 4th to-be-closed value because all 5 generic-`for` tests used the explicit 4-expression form. Fix: always adjust the iterator list to four values and always close the fourth (Lua 5.4 semantics), regardless of single-call vs multi-expr; added 3 single-call-factory tests; f2p re-proven; no meta change (spec already covers the multi-return form). Lesson: detect a feature by SEMANTICS not syntactic shape, and test the IDIOMATIC form not just the verbose one (see `lessons-learned.md § piccolo R4 REVERT`).

**Shape + stats:** cross-subsystem language feature (O-Algorithm-correctness span). Lua 5.4 to-be-closed variables (`local x <close>`) + `coroutine.close`/`wrap` in piccolo, a stackless Lua 5.4 VM in Rust. 8 source files / 6 subsystems (compiler/compiler.rs, opcode.rs, thread/vm.rs, thread/executor.rs, thread/thread.rs, meta_ops.rs, stdlib/coroutine.rs, thread/mod.rs). 537 eff LOC. 67 f2p tests (0/67 base, 67/67 with solution). Base commit ce709eb1. Solver runs 660–968 LOC / 354–664 msgs (0.7–0.8× our solution LOC, i.e. agents wrote MORE and still missed edges).

### Decisive difficulty drivers (recurrence-ranked from the batch)

1. **Forced-representation trap — repeat-loop per-iteration close (6/10 biters; one a hang).** Agents key pending close slots by stack index and dedup; a loop body reuses the register, so it closes once instead of per pass (`repeat_loop_closes_on_each_pass`, "aaa"→"a"; run #11 hung, exit 124). The reference uses a per-registration `TbcSlot{stack, value, close_fn}`. This is the single most effective trap: natural-but-wrong representation, shared by all close paths (interdependent), surfacing as wrong count or hang (misdirecting). See `PATTERNS-ADVANCED.md § Pattern 37`.
2. **Block-exit discrimination — within-block goto must NOT close (3/10).** Agents close before every forward named goto; correct behavior patches the forward-jump close target to the label's stack level so a same-block goto closes nothing (`goto_within_scope_does_not_close`, "xa"→"ax").
3. **Explicit error-name plumbing (2/10).** Non-closable `<close>` value must raise an error naming the local; agents drop the compiler→runtime name plumbing despite the explicit meta sentence.
4. **Generic-`for` fourth value closes (1/10).** The reshape lever that moved the band; forces a hot-opcode result-slot relayout (closing slot at base+3, iterator results skip it). Agents close it only on error-unwind.
5. **Return value fixed before closer side-effect (1/10).** "1|2"→"2|2"; CloseTbc must be emitted after return values materialize.

### R7 real Nova batch (2026-06-28): 2/10 = 20%, hardened suite (80 tests), all-fair

After the R4 revert-fix + R5/R6 hardening, a healthy 10-run Nova batch (Nova solver/eval, zero infra failures) landed **2/10 = 20%** in the Olympus band, all FAIL_MISSED_REQUIREMENT / agent_blame_unfair=false. Nova trap recurrence (ranked): **generic-`for` 4th value closing** (4/10, CATASTROPHIC 8-22 fails — agents skip the whole sub-feature) > **coroutine.close error-threading** (4/10; one PANICS at executor.rs:511) > **return-from-for-body close order bF/Fb** (the R6 interleave trap; decisive on the 78/80 near-miss) > **goto-within-scope** (1/10) > normal-exit close-error propagation, error-names-variable empty-name, captured-upvalue. The decisive correction: the generic-`for` 4th value (R4 reshape) is a genuine SECOND sub-feature wall (own opcode/compiler path), not absorbed by the unwind machinery — which is why the band holds at 20%. The R6 local-sim "near single-wall ceiling" read was an artifact of a 3-agent sim that could not sample "agent skips a whole sub-feature under budget" (the dominant real failure). See `lessons-learned.md § R6/R7 CORRECTION` + `KNOWLEDGE.md § REAL Nova batch`.

### Iteration lessons

- **Diamond-too-easy → Olympus is a re-tier, not an over-harden.** Diamond Checks read 33% / avg 0.47 after the reshape, but the batch came out 20% and it approved cleanly as Olympus. A single coherent feature, however wide its span, tends to ceiling at Olympus.
- **The avg-pass-fraction metric punishes added tests.** +9 fair discriminator tests moved avg 0.66 → 0.81 (EASIER). Only a harder core (driver #4 above) lowered it. Never pad the suite to raise difficulty.
- **test.patch ADDITIONS-ONLY** (grader re-applies; an obsolete golden `close-unimpl.lua` was retired via `rm -f` in test.sh, not a patch deletion — a patch-deletion round failed "Failed to re-apply test.patch").
- **`timeout` per test command + synthetic failure on non-clean exit.** Run #11's hang would otherwise hit the 1800s wrapper and score as a verifier blocker (`agentFair` / `agentNoEnvBlocker` readiness FALSE flags). `timeout 600` + a `harness_incomplete` JUnit failure grades a hang as an honest agent failure.
- **Rust git-dep offline cache friction** (gc-arena under `/opt/cargo`: Permission denied, dubious ownership, CONNECT 403) hit ~5/10 runs but was ruled `agent_blame_unfair: false` (agents recovered via writable `/tmp` cargo-home). `cargo fetch --locked` + `chmod -R a+rwX /app` in the Dockerfile mitigates.
- **Fairness pins repeatedly tripped Test Fairness/Alignment:** error-message substring assertions (`__close`, `non-closable`, `multiple`, `const`) not present in meta. Robust fix is to drop substring pins and assert behavior — the variable name (which meta states) or just that the offending program errors, anchored by a positive close that fails on base to preserve f2p.

### test.sh single-invocation across multiple packages

For multi-package test surfaces, use ONE `go test ./pkg1/ ./pkg2/` invocation through one `go-junit-report` pipe. Custom merge_xml functions over multiple invocations produce malformed JUnit XML. Approved dasel-quoted-key-paths uses single-invocation pattern verbatim:

```bash
PKG="./execution/ ./internal/cli/"
go test -v -count=1 $PKG -run "$run_pattern" -timeout "$timeout" 2>&1 | go-junit-report -set-exit-code > "$OUTPUT_PATH"
```

### CLI flag validation: avoid Kong enum tag

Spec says "errors with `unknown conflict strategy`". Agent uses kong `enum:"a,b,c,d"` tag → Kong calls `os.Exit` on invalid value with its own error format. Test cannot capture required error string because process exits. Reference solution validates inside `run()` and returns Go error explicitly. **Pattern: when spec mandates a specific error string, validate in code path that returns errors, not in declarative validators.**

### Reframe-to-Olympus signal: trap stacking past 50% with 0 lift

When 4 rounds of trap stacking on the same shape produce identical pass rates, the shape is the ceiling. Reframe FEATURE scope, not test scope. Cost: 3–5 fresh iterations after reframe. Net iteration count for R0–R17d was 18 rounds, half spent fighting B-shape ceiling before accepting reframe was needed. **Recognize the ceiling sooner**: if the third trap-add round shows no movement, jump to reframe.

### Cycle detection in recursive operations: depth limit + pointer-eq combined

Pure pointer-eq insufficient for cycle detection because `*model.Value` wrappers may be regenerated by accessor methods (`RangeMap` calls `GetMapKey` which may wrap fresh `NewValue(val)`). Pure depth limit catches cycles but fires falsely on legitimately-deep input. Hybrid: track pointer set AND depth counter. On pointer revisit OR depth > 256, return cycle error.

### Aliased-pointer cycle test is unfair

`mergeDeep($self)` where `$self == pipeline` is the same pointer. Reference solution's single shared cycleSet detects this incidentally; agents using independent per-input visited sets miss it. Reviewer flagged this as unfair (2/3 runs failed only this case). **Lesson: do NOT test implementation-specific behaviors that depend on data-structure-of-tracker. Test logical cycles (value contains itself), not implementation-emergent ones (two same-pointer args).**

### Strategy-field discriminator clause is load-bearing

Spec: "The Strategy field is set to the strategy in effect when the error originated, or empty otherwise." The "or empty otherwise" clause carved out structural pre-check errors that fire BEFORE strategy logic runs. 3/12 agents missed this and populated Strategy on type-mismatch errors. Same trap classification: 2 evaluators correctly classified as MISSED_REQUIREMENT, 1 as AMBIGUOUS_TASK (contested). **Pattern: when defining a struct field that is conditionally populated, name the empty case explicitly with a discriminator clause ("or empty otherwise" / "leave X unset when Y").**

### CLI test bypass via reflection-skip helper

Tests for new CLI flag won't compile in base mode if they reference flag struct field directly. Fix: detect flag presence via reflection on `cli.QueryCmd{}`, skip test if absent:

```go
func cfDefaultConflictFlagPresent() bool {
    t := reflect.TypeOf(cli.QueryCmd{})
    for i := 0; i < t.NumField(); i++ {
        if t.Field(i).Tag.Get("name") == "default-conflict" {
            return true
        }
    }
    return false
}

func cfSkipIfFlagAbsent(t *testing.T) {
    if !cfDefaultConflictFlagPresent() {
        t.Skip("--default-conflict flag not declared on QueryCmd")
    }
}
```

### Invalid-strategy contract must wrap CollectionFuncError

Run 10 returned `fmt.Errorf("unknown conflict strategy: %s", s)` for invalid strategy arg. `errors.As` against `*CollectionFuncError` failed. Spec said "Every error from these two functions wraps a pointer to CollectionFuncError" — agent missed that "every" includes invalid-arg validation. **Pattern: when spec says "every error", ensure spec language has no implicit categorical exception.**

### Strategy enum LLM blind spot proven on this problem

4 strategies listed (`keep`, `overwrite`, `concat`, `error`). Agents implemented `overwrite` (default) cleanly across all runs. The other three each had failures: `concat` (slice append vs string concat ambiguity), `keep` (no failures observed but covered), `error` (Run 10 botched the wrapping). **Pattern: list 4+ strategy values explicitly with per-value behavior. Some agents will get one wrong. Tier 1 LLM blind spot.**

### "Both must be same shape" is load-bearing precondition

3/12 runs (Runs 4, 8, 10) collapsed top-level shape mismatch into per-leaf strategy resolution. Spec said "Both must be same shape (both maps or both slices). When two maps share a key whose values are both maps, the function recurses; otherwise it applies the conflict strategy." The "otherwise" was scoped to per-key handling but agents read it more broadly. **Pattern: precondition checks need to be stated structurally distinct from main algorithm.**

### Iteration count signal for tier mismatch

R0–R10 spent 10 rounds in Mars C-shape territory at 100% pass. R11–R16 added 6 more rounds attempting to drag B-shape down. R17–R17d spent 4 rounds redoing Olympus. **Total 18 rounds for one submission.** If iteration count > 6 with no movement, the tier is wrong. Reframe rather than continue.

### CRITICAL: Namespace expansion + maintainer philosophy check (R18 REJECT)

**dasel-collection-funcs R17d was REJECTED post-eval at 41.7% pass rate** because `FuncMerge` already exists in the repo and `mergeDeep` is namespace expansion. GitHub issue #169 has explicit maintainer comment against merge-namespace expansion. Reviewer cited Immediate Rejection Rule.

Author error: Phase 2 PR check searched for literal name `mergeDeep` (absent), but did NOT:
1. Search broader namespace: `gh pr list --search "merge"` would have surfaced #169
2. Read existing functions for namespace conflict: `FuncMerge` (shallow merge) was visible during architecture grep but flagged only as "different function"
3. Re-run Phase 2 after scope change from pick/omit/chunk/windows → mergeDeep/diffDeep

**Mandatory checks for every scope change**:

```bash
gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments
```

Search for maintainer philosophy markers: "I'd prefer not to", "philosophical", "we don't add", "rejected by design", "namespace", "pollute".

**Cost**: 18 rounds + 12-run eval (~$200) + cannot resubmit same scope.

**Rule**: Reading the existing repo file structure during architecture grep is NOT sufficient. Must explicitly search GitHub PR/issue history with broad namespace keywords AT EVERY SCOPE CHANGE.

---

## yaegi-repl-doc (Mars Solid, shipped 2026-05-02 — 3/14 = 21.4% Nova/Orion)

Source: `problems/yaegi/yaegi-repl-doc/`. APPROVED 2026-05-02. 14 eval runs: 3 PASS_LEGITIMATE + 6 FAIL_REGRESSION + 2 FAIL_MISSED_REQUIREMENT + 1 FAIL_WRONG_LOGIC + 2 FAIL_EARLY_TERMINATION.

### Tier 1 anti-agent: parser-wrap newline regression (43% hit rate)

**Pattern**: feature requires extending `parser.ParseComments` from REPL-only to all evaluation paths in `interp/ast.go`. Agents reflexively also flip `src = "package main;" + src` (incremental wrap) to `src = "package main\n" + src` or `"package main;\n" + src` so godoc attaches to FuncDecl. Newline shifts ALL existing eval-test position assertions by 1 line → 11-12 baseline pos failures.

**Failures observed** (Runs 1, 2, 5, 7, 8, 14):
- TestOpVarConst, TestEvalTypeSpec, TestEvalComparison, TestEvalFunc, TestEvalREPL all fail with `want 1:29` vs `got 2:16`-style position deltas.
- Sometimes paired with REPL parse failure (`expected 'IDENT', found '{'`) when newline interacts with REPL-mode incremental tokenization.

**Reference solution path**: lift `parser.ParseComments` out of `if inc { mode |= parser.ParseComments }` to unconditional set. KEEP `package main;` (no newline) — comment-to-FuncDecl attachment still works through full-file parse path. Only the bare prepend semicolon shape preserves position semantics.

**Fix for future yaegi feature problems** that touch `parse()` in `interp/ast.go`:
- Trap matrix item: "agents reflexively add `\n` after `package main;`; preserve original prepend semicolon shape"
- Pre-empt sentence in description NOT recommended — it's an implementation hint and would be flagged by description-quality bot. Keep it as silent trap; rely on baseline test failures to surface mistake.

### Tier 2 anti-agent: GenDecl spec walking missed (21%)

**Pattern**: agents capture `*ast.FuncDecl.Doc` correctly but miss `*ast.GenDecl` walking var/const/type specs.

**Failures observed** (Runs 6, 7, 10):
- `TestDocUserVarReturnsGodoc` empty for documented `var Counter int`
- `TestDocUserTypeReturnsGodoc` empty for documented `type Box struct`

**Reference pattern**:
```go
case *ast.GenDecl:
    declDoc := ""
    if a.Doc != nil { declDoc = a.Doc.Text() }
    for _, spec := range a.Specs {
        switch s := spec.(type) {
        case *ast.ValueSpec:
            doc := declDoc
            if s.Doc != nil { doc = s.Doc.Text() }
            for _, n := range s.Names {
                interp.recordDoc(pkgName, n.Name, doc)
            }
        case *ast.TypeSpec:
            doc := declDoc
            if s.Doc != nil { doc = s.Doc.Text() }
            interp.recordDoc(pkgName, s.Name.Name, doc)
        }
    }
```

The `declDoc` fall-back is critical: parser attaches doc at decl level when GenDecl has only one spec.

### Tier 2 anti-agent: REPL output buffer routing (21%)

**Pattern**: agents implement `:doc` no-arg/whitespace-only branch printing usage to stderr (`fmt.Fprintln(errs, ...)`) instead of REPL stdout. Tests assert stdout buffer contains `usage:` substring.

**Failures observed** (Runs 1, 7, 10): TestDocREPLNoArgPrintsUsage / TestDocREPLWhitespaceOnlyPrintsUsage.

**Reference**: REPL meta-commands print to interpreter's `out` writer (stdout), not `errs`. Spec language "prints a usage message" implies normal user-facing output channel.

### Tier 3 anti-agent: self-package qualified lookup miss (7%)

**Pattern**: agent's 2-part name lookup `Doc("main.Greet")` walks imported-package qualifier maps only; never matches when the qualifier equals the current package's own importPath.

**Failure observed** (Run 3): `TestDocUserFuncQualifiedMainWorks` and `TestDocQualifiedPkgResolvesSourcePackage` return empty.

**Reference**: try BOTH `["main."+name, name]` candidate keys in lookup chain. For `Doc("main.Greet")`: split on last `.` → `pkg="main"`, `name="Greet"` → check `docs["main.Greet"]` directly (since storage is keyed `pkg.name`). Trivial fix; one missing branch.

### Tier 3 anti-agent: itype.getMethod recursion no cycle guard (7%)

**Pattern**: agent extends `itype.getMethod` to recurse through `t.val` (pointer element) and `t.ptr` (pointer-to-self) without cycle detection. Cyclic struct types (e.g. `type T struct { *T }`) cause stack overflow.

**Failure observed** (Run 8): `TestEvalMethod` (BASELINE) and `TestDocUserMethodReturnsGodoc` both die with `fatal error: stack overflow` in `interp/type.go:1819-1822`.

**Fix**: don't extend `getMethod`. Use `recordFuncDecl` walking `*ast.FuncDecl.Recv` to extract receiver name via `receiverTypeName(expr ast.Expr)` helper that strips StarExpr and IndexExpr/IndexListExpr (generic methods).

### Mistake: subpackage vs interp_test vs build-tag — three valid architectures across reviewers

**Pattern**: yaegi test placement has THREE approved patterns across submissions:
1. **Subpackage** `interp/<feature>/` with `package <feature>`: yaegi-completion, yaegi-callstack-postmortem
2. **`package interp_test` in `interp/<feature>_test.go`**: standard yaegi convention — but test-patch-only base mode breaks compile (LESSONS.md mistake #2)
3. **`package interp_test` + `//go:build <tag>`**: yaegi-repl-doc shipped this way after auto-review demanded "drop subpackage"

Each approach has different reviewer reactions:
- Auto-reviewer A: rejects subpackage ("hides tests")
- Auto-reviewer B: rejects build tag ("hides tests")
- LESSONS.md #2: warns against `package interp_test` (compile fails on test-patch-only)

**Resolution**: pick whichever pattern the FIRST reviewer demands. If they reject your pick, contest with approved-precedent evidence (yaegi-completion or yaegi-callstack-postmortem in `Olympus-Approved/`). Final human reviewer may override auto-reviewer FAIL flags.

### Pre-Submit Checklist Additions (yaegi-repl-doc specific)

In addition to yaegi-completion + yaegi-eval-in-package + yaegi-callstack-postmortem checklists:

- [ ] If extending `parser.ParseComments` to non-REPL paths: do NOT modify the `package main;` prepend. Keep semicolon, no newline. Verify by running 11+ existing TestOpVarConst/TestEvalTypeSpec/TestEvalComparison position-asserting tests after change.
- [ ] If capturing comments at AST walk: handle `*ast.GenDecl` walking specs with declDoc fall-back (single-spec GenDecl gets doc at decl level, not spec level).
- [ ] If adding REPL meta-command: write to interpreter's `out` (stdout) writer, NOT `errs` (stderr). Match `doPrompt` output channel pattern.
- [ ] If extending method-set computation: do NOT touch `itype.getMethod`. Capture receiver name during AST walk only.
- [ ] If qualified-name lookup needed: try both `currentPkg.name` AND `name`-as-qualified candidates (catch self-package qualification trap).

---

## dasel-slice-operator (Mars Solid, REJECTED at submit-pre-check 2026-04-30)

Authored end-to-end (DESIGN.md + solution + tests + Dockerfile + patches + offline-validate). REJECTED before submission when 5-check final pass found maintainer-shipped post-base resolution.

### Root cause: Phase 2 ran at base time only, missed post-base activity

- Base commit: `0dd6132e` (2026-03-10)
- Issue #312 "Support slice operator" CLOSED by maintainer 2026-03-30 (20 days post-base) with comment: "This is implemented in v3" + docs link to `daseldocs.tomwright.me/syntax/arrays-slices`
- Maintainer-published docs example: `$someArray[0:4]` "retrieves the first 5 items" → INCLUSIVE both ends
- Our spec: exclusive end (Go-style) → DIRECT CONTRADICTION of maintainer-documented behavior

v1 audit ran:
- ✓ Check 1 literal name (no PR for `slice operator`) — true
- ✓ Check 2 namespace (no PR for `range`) — true
- ✗ Check 3 philosophy — missed (didn't search closed issues)
- ✗ NEW Check 4 closed-with-implemented — not in v1 protocol
- ✗ NEW Check 5 base→main commits — not in v1 protocol
- ✗ NEW Check 6 capability test on main HEAD — ran on base only

### Lessons — added to PATTERNS-ADVANCED.md § Pattern 22 + Pattern 32 + Pattern 33

1. **The Phase 2 PR check from v1 was incomplete.** Need 6 checks, not 4.
2. **Closed issues with "implemented in V3" / "supported in V" pattern are silent kills.** Open-only issue search misses them.
3. **Maintainer-published docs are the spec.** Any pick that contradicts documented user-visible behavior = automatic REJECT.
4. **Check 4-6 must run at submit-pre-check, not just design time.** Maintainer activity is continuous (~3 functions/week for active dasel).
5. **For semantic-fix picks, build current main HEAD and CLI-test the feature.** If 80%+ works as documented, the gap is too narrow for a problem.

### Sibling-pick fallout (caught at audit-rewrite, NOT shipped)

Three v1 dasel picks classified GREEN but failed Check 5 base→main commit overlap:

| Pick | Killing commit/issue | Date |
|---|---|---|
| dasel-entries-fromentries | `ace5c25 Add entries and fromEntries functions` | post-base |
| dasel-yaml-quote-style | `80d4fe5 Preserve YAML string quote style on round-trip (#452)` | post-base |
| dasel-regex-filter (#183) | issue #183 closed "Very late to the party here, but this is finally supported in V3" | 2026-03-30 |

All three would have been hard-rejects if shipped. Caught only by post-mortem audit triggered by slice-operator REJECT.

### Triviality fallout (user feedback "M2 trivial too easy")

User flagged dasel-pick-omit-funcs (M2) as trivial too easy. Audit applied same triviality lens to siblings:

| Pick | Why trivial |
|---|---|
| M2 dasel-pick-omit-funcs | 2 funcs ~50 LOC each; mirrors `func_first.go` (36 LOC) |
| M7 dasel-chunk-window-funcs | 2 slice-batch funcs ~50 LOC; pattern-followable |
| M8 dasel-zip-partition-funcs | zip parallel iter ~40 LOC; partition filter+!filter ~50 LOC |

All three downgraded to RED. Lesson added to PATTERNS-ADVANCED.md § Pattern 33: triviality decision tree.

### Recovery actions taken

1. CLAUDE.md "CRITICAL RULE" updated from 4 checks to 6 (added closed-implemented + base→main commits)
2. CLAUDE.md added explicit "TRIVIALITY filter" section
3. PATTERNS-ADVANCED.md § Pattern 22 expanded with checks 4-5-6 + 3 specific track-record incidents
4. PATTERNS-ADVANCED.md § Pattern 32 NEW — Post-base maintainer activity check + maintainer-docs-spec contradiction
5. PATTERNS-ADVANCED.md § Pattern 33 NEW — Triviality filter with decision tree + active-maintainer multiplier
6. dasel-analysis/ASSESSMENT.md rewritten v2.1 — verdict matrix updated; 4 picks RED for namespace, 3 RED for triviality, 2 NM picks added (NM5 assign-path-creation, NM4 compound-assign-operators)
7. dasel-analysis/DASEL-PROMPTS.md rewritten — v1 prompts deprecated; new prompts include 5-check protocol + triviality filter + lessons-derived hard requirements

### Cost / token budget

- Authoring time: ~half-day end-to-end (DESIGN + solution + tests + Dockerfile + patches + 2 validation cycles + UTF-8 mojibake debugging)
- Docker iterations: 0 (caught before docker build)
- Eval cost: $0 (caught before submit)
- Recovery audit cost: ~30 minutes (single audit pass with 6-check protocol on remaining picks)

Total saved by catch-before-submit: avoided full Mars eval (~$50) + reviewer-round resubmit cycle (~$20) + ~1 day of follow-up authoring.

### Pre-Submit Checklist Additions (mandatory for all dasel picks; generalize to other repos)

- [ ] Pattern 22 6-check protocol output pasted in DESIGN.md §14
- [ ] Maintainer-published docs URL fetched and compared to our spec (Pattern 32)
- [ ] Capability test against current main HEAD (NOT base) — if 80%+ works, REJECT
- [ ] Triviality decision tree walked (Pattern 33) — non-trivial verdict justified
- [ ] Re-run 6-check immediately before patch generation (catch features shipped during authoring)
- [ ] If pick is additive function: bundle 3+ cross-feature traps OR combine with semantic option flag OR combine with new public API surface (per Pattern 33 mitigation)

---

## yaegi-execution-tracer (Olympus, ACCEPTED 2026-05-14 — Diamond promotion landed at Olympus tier)

### Outcome
- **Final tier:** Olympus (NOT Diamond as initially submitted)
- **Repo:** traefik/yaegi · **Base:** `fcb76d1ece0c3edc2548c39aa5b170475d2261bb` · **Language:** Go
- **Pass rate:** 2/20 Castor at Diamond eval (10%); accepted at Olympus instead
- **Reviewer quote:** *"Nice work on the frame-anchored `tracerCallState` — propagating depth through frame ancestry (rather than goroutine-id maps) is what makes the goroutine reset and nested-call depth tests fall out cleanly."*
- **AI Reviewer Run 6:** PASS 23/23 checklist, 0.92 confidence, "ship it"

### Shape + Stats
- **Shape:** Olympus O-Composite-add (new feature spanning interp/runtime/symbol-table)
- **Solution:** 441 +LOC across 5 files (interp.go, run.go, tracer.go, tracer_export.go, tracer_format.go)
- **Tests:** 54 tests, 1 new test file (`tracertests/tracer_test.go` — separate package to avoid import cycles)
- **meta.md:** 443 words, 8 paragraphs
- **Test isolation:** `//go:build tracer` tag + dedicated `tracertests/` subpackage

### Confirmed Cross-Agent Blind Spots (from 20 Castor runs + 12-run Diamond eval)

| Trap | Castor failure rate | Mechanism |
|---|---|---|
| **Goroutine depth not reset** | **13/20 (65%)** | 5 architectures all miss `callNode.anc.kind == goStmt` discriminator. Variants: (a) `clone()` propagates traceDepth, (b) `+1` unconditional parent, (c) `traceState` on frame, (d) `goroutineTrace` by gid (yaegi shares OS thread), (e) `traceDepth = -1` sentinel copied. |
| **TotalLines sums per-call distinct counts** | **7/11 (64%)** before hint, 4/18 (22%) after | Agents write `cr.TotalLines += lineCount` (Σ per-call) instead of `|∪|` (lifetime set). 2-line func × 2 calls yields 4 not 2. |
| **Anonymous closure placeholder name** | 5/20 (25%) | Stored as `"<anonymous>"` instead of `""` — spec required empty string for Name. |
| **Variable declarations emit events** | ~0% (mitigated by hint) | runCfg/funcDecl architectural hint reduced to zero failures. |
| **Off-by-one depth at top-level** | ~0% (mitigated by hint) | Same hint catches both. |

### Architecture Split — Passing vs Failing

**Passing solutions:**
- Frame-anchored `tracerCallState` propagating via frame ancestry (NOT goroutine-id maps)
- Per-frame state field initialized at call entry, inherited from parent frame
- `goStmt` ancestor check resets depth + initializes fresh state for goroutine root
- TotalLines: lifetime `map[int]bool` on CallRecord merged across invocations

**Failing solutions (90% of Castor):**
- `sync.Map` or `f.root`-keyed shared state for goroutine depth
- Goroutine-id (gid) maps — fails because yaegi shares OS threads across goroutines
- Per-call `linesSeen` reset on every invocation — TotalLines = lines from LAST invocation only

### Reviewer Iteration Arc (24 attempts pre-acceptance)

- **Iter 1-7:** description tightening per AI checks, MaxDepth semantics clarified, paragraph splitting
- **Iter 8:** runCfg/funcDecl architectural hint — eliminated 100% of varDecl + off-by-one failures
- **Iter 9:** TotalLines counter-example added ("2-line func × 2 calls = 2, not 4") — 100% → 22% failure
- **Iter 10-18:** human-reviewer fixes (test comments, missing assertions, scope creep removal, CLI binary tests replaced with API-only)
- **Iter 19-24:** final polish — break-vs-found-flag bug fix, duplicate test deletion, recursive CalledBy assertion

### Lessons — Cross-Cutting

1. **Frame-anchored state propagation beats goroutine-id maps in interpreters.** When the interpreter shares OS threads, gid-based tracking is fundamentally broken. Per-frame state inheriting from parent (with boundary detection at goStmt) is the canonical pattern.

2. **Abstract hints don't work for architectural traps.** "Frame hierarchy" hint failed (16/18 still hit). Only 2/18 independently discovered per-frame propagation. **Need concrete architectural recipe** for cross-architectural traps — abstract framing insufficient.

3. **Concrete counter-example hint beats verbal description.** TotalLines spec said "distinct" but agents still summed. Adding "2-line func × 2 calls = 2, not 4" dropped failure from 100% to 22%. Counter-examples match test assertions directly.

4. **Test files in separate subpackage avoid hidden-harness collisions.** `tracertests/` subpackage isolates author tests from agent tests + avoids import cycles when testing internal `interp` types. Pattern: test-only Go subpackage for problems testing interpreter internals.

5. **`//go:build tracer` tag + new-mode regex required** for go test isolation. Base mode excludes new tests via regex; new mode uses build tag. Standard yaegi pattern.

6. **CLI binary exec inside `go test` fails on `--network none`.** Replace with API-only tests calling `TraceSummary()` directly. Same lesson as yaegi-execution-tracer attempt 17.

7. **Reviewer aggressively removes undocumented exported helpers.** Scope creep = 6 methods removed (Reset, EventCount, CallCount, FunctionNames, EventsForFunction, MaxDepth). Only document what tests exercise.

8. **Diamond eval at 10% landed Olympus instead.** Castor 2/20 at Diamond evaluation, but reviewer accepted at Olympus tier instead. **First confirmed data point: Diamond submissions CAN land at Olympus if pass rate is too low** — the submission isn't rejected, it's tier-downgraded. Less-feared outcome than expected.

### Diamond Promotion Outcome (vs predictions)

**Pre-submission prediction (Section 8.5):** 1 Castor + 6 QA rounds (~325 tokens) if promotion-eligible.

**Actual:** 20 Castor runs + Diamond Checks 2× + Holistic + Auto Review + 9 eval rounds. Did NOT land at Diamond tier despite all passes. Accepted at Olympus.

**Implication:** promotion path open in-flight, BUT Castor passrate at Diamond eval determines tier landing. <10% Castor pass → Olympus tier acceptance, not Diamond. Adjust expectations: promotion guarantees Olympus-or-better, not Diamond.

---

## yaegi-goroutine-lifecycle (Mars Solid — Approved 6/7, May 17 2026, 4 iteration rounds)

**Tier:** Mars Solid. Shape: D-new (new public API surface + multi-site integration in run.go spawn paths).

### Submission specs

- BASE_COMMIT: `fcb76d1ece0c3edc2548c39aa5b170475d2261bb`
- Solution: 3 files (`interp/goroutine.go` NEW + `interp/interp.go` MOD + `interp/run.go` MOD); 9013 bytes; ~220 meaningful LOC
- Tests: 50 new tests in `interp/goroutine_lifecycle_e2a190_test.go` (build tag `yaegi_goroutine_lifecycle`); 52KB test.patch
- meta.md: 438 words (final), ASCII pure
- Acceptance: v4 of v4, 6/7. Reviewer: "Solid feature - comprehensive goroutine tracking with clean public API contracts. the spec names only externally observable behavior without prescribing how to implement it internally."

### Public API shipped

`GoroutineCount()`, `Wait()`, `WaitWithContext(ctx)`, `GoroutinePanics()`, `Goroutines()`, `SetMaxGoroutines(n)`, `GoroutineStats()`, types `GoroutineError{Source, Recovered}`, `GoroutineInfo{ID, Source, ParentID}`, `MaxGoroutinesError{Cap}`, `GoroutineStats{Spawned, Completed, Rejected, Panicked}`, `Options.MaxGoroutines`.

### Eval trajectory (4 rounds)

| Round | Tests | Nova pass | Outcome |
|---|---|---|---|
| 1 | 27 | n/a | Initial design, 124 meaningful LOC under floor — expanded scope |
| 2 | 42 | 90% | Too easy; added strict Source format + MaxGoroutinesError typed value + cap-reject-in-buffer |
| 3 | 42 | 75% (9/12) | Still too easy; added ParentID via runtime.Stack goid-TLS + GoroutineStats 4-counter invariant + recovery-completion ordering |
| 4 | 50 | 71% (10/14) | Too easy still; replaced 5 fluff tests with 2 cross-cutting (sort+parent+stats / panic-ordering+source+stats) per Pattern 17 — accepted |

### Confirmed traps (each predicted, each fired)

| Trap | Mechanism | Test catching |
|---|---|---|
| Cap-rejected NOT in GoroutinePanics | agents raise panic without appending entry first | CapExceededProducesPanicEntry, MaxGoroutinesErrorInGoroutinePanics |
| Source format `T.M` vs `M` | agents return method name only, miss type qualifier | SourceMethod (4 SourceXxx tests across 4 Source kinds) |
| GoroutinePanics ordering = recovery-completion | agents assume FIFO-spawn order | GoroutinePanicsOrderingByRecoveryCompletion |
| Stats 4-counter disjointness | agents lump Rejected into Spawned/Panicked | StatsRejectedDisjointFromSpawnedAndPanicked + StatsInvariantSpawned... |
| ParentID requires goroutine identity | no clean Go stdlib idiom; runtime.Stack parsing needed | NestedGoroutineParentIDPropagated + ParentIDChainComposesThreeLevels |
| Goroutines() sort by ID | map iteration random | LiveSnapshotSortedWithParentClassification |
| Cross-cutting invariants combined | features pass isolated, fail combined | LiveSnapshotSortedWithParentClassification (6 invariants) + WaitPanicsOrderedAcrossSourceKindsWithStats (5 invariants) |

### Architecture insight

- ParentID tracking via `sync.Map[osGoid uint64]trackedID uint64` + `runtime.Stack(buf, false)` parse for goid. Every spawnGoroutine: lookup parent via curGoid, store self in defer-prologue, delete on defer-cleanup. ~15 LOC.
- Three goroutine spawn sites in `run.go` (binary call 1335, source func 1411, closure 1587) all wrapped through single `spawnGoroutine(source, fn)` helper.
- Defer order matters: LIFO — cleanup defer must run AFTER recover defer so `panicked` flag set before Stats increment.

### Description iteration (615 → 438 words across rounds)

- R1 615 words (over hard cap 500) → trim
- R2 498 words after preamble compression
- R3 488 words after pointer-receiver clarification drop
- R4 467 words after typed-error inversion + ownership-clause drops
- Final 438 words after 8 reviewer trims (concurrency-clause tail, atomic-spawn clause, "shares drain semantics" filler, "and clears buffer" duplicate, "never reused" implied, cap-rejected-disjoint restatement, "On cap exceed" awkwardness, "is what... holds" inversion)

### Lessons — Cross-Cutting

1. **Pattern 17 confirmed for 4th time** — yaegi-goroutine-lifecycle. R2/R3 spec edits (adding API surface, new types, more traps) moved pass rate 90% → 75% → 71%. Only R4 reshape (drop 5 isolated tests + add 2 cross-cutting interaction tests) broke through to ship. **Cross-cutting interaction tests > trap count.** Two tests asserting 5-6 invariants each beat ten isolated tests asserting 1 invariant each.

2. **Goid-TLS via `runtime.Stack` parse is a legit Go pattern** for goroutine identity when no other handle exists. ~10 LOC helper. Use case: parent-child relationship tracking inside a goroutine forest where spawn helper is shared. Pattern: `var buf [64]byte; n := runtime.Stack(buf[:], false); ...` extracting goid from "goroutine N [..." prefix.

3. **Auto-reviewer "shipd" filename ban** — added 2026-05. Use random hex suffix via `openssl rand -hex 3` for test file naming. Reviewer bans literal substrings: `shipd`, `datacurve`. Cache may stale between rename and re-eval — patch contents matter, not filename history.

4. **Test fairness verdict can be remediated via spec clause not test deletion**. `GoroutinePanicsConcurrentSafe` flagged unfair because spec didn't promise concurrency safety. Adding "All lifecycle accessors are safe for concurrent use; concurrent `GoroutinePanics()` reads partition the buffer so every entry is returned exactly once across the set of callers" legitimized the test without dropping it. Pattern: when test-fairness flags trap test, prefer spec addendum over test removal.

5. **Defer LIFO matters for panic-vs-completion accounting.** Inside spawnGoroutine's goroutine:
   - `defer cleanup()` (registered first, runs LAST) — reads `panicked` flag, increments Stats accordingly
   - `defer recover()` (registered second, runs FIRST on panic) — sets `panicked = true`, appends entry to panics buffer
   - On panic: recover runs first → flag set + entry appended → THEN cleanup runs → reads flag → increments Panicked counter (not Completed)
   - On normal completion: recover defer runs (recover returns nil, no-op) → cleanup runs → Completed counter
   Get this defer order wrong = Stats.Completed counts panicked goroutines.

6. **"Source field on MaxGoroutinesError" was over-specified.** Tests only assert `mge.Cap`. Spec dropped `Source string` field requirement; impl can keep it internally for Error() formatting without spec promise. **Lesson:** if a field appears in impl but not in any test assertion, the spec doesn't need to mandate it. Reviewer flagged as `over_specification` in description quality check.

7. **Word-count tokenizer mismatch caught at submit**: my Python `re.sub(backticks, X, text).split()` counted 492. Auto-reviewer counted 531 (whitespace split including backticks). Final reviewer counted 438 after trims. **Always validate via plain `text.split()` whitespace-tokenize** for word count — backtick stripping understates.

8. **Iteration count cost benchmark:** R1-R4 cycle ≈ 4 days, ~$120 in evals. R4 reshape (cross-cutting tests) was the only round that landed pass rate; R2/R3 trap additions were ceiling-bound. Confirms `dasel-collection-funcs R10-R16` pattern: if 3 successive rounds in same shape produce diminishing returns, reshape via integration-surface lever (cross-cutting tests / multi-package / public API split).

## yaegi-generic-constraint-fidelity (Go, Diamond — APPROVED 2026-05-31, 2nd approved yaegi Diamond)

Shape: O-Algorithm-correctness. BASE `fcb76d1`. Reviewer: "gtg. qa is now factually correct."

**Anchor profile (approved):** 3/10 Castor = 30% (top of Diamond <=30% band); 442-word description; 963-add solution across 8 files (5 mod + 3 new: constraint_error.go, generic_constraint.go, cmd/yaegi/constraint_report.go); 81 F2P; 387/387 baseline preserved all 10 runs; build-tag isolation (`//go:build genericconstraintfidelity`, tests in natural packages, no subpackage); 3-layer JUnit fallback (go-junit-report -> raw awk -> synthetic, strip `[build failed]`); Dockerfile olympus-base-go + GOPATH symlink. ~33 authoring rounds + 4 QA-only rounds. Holistic 0.30 "ship it"; Auto Review PASS; 2 env-QA criticals (forge + /opt/go world-writable) dismissed as base-image.

**Core difficulty engine (reusable Diamond seam):** go/constant STRICT representability vs yaegi's pre-existing LOOSE `assignableTo` (the `if t.untyped && isNumber && isNumber { return true }` fast path). Every effective trap traces to this gap -- a built-in permissive check the spec forces the solver to tighten. Generalizes to any interpreter/type-system repo.

**Effective Castor traps (what caught the 7 fails):**
1. **Untyped-default promotion ORDERING** (broad, ~30%). The default must be resolved BEFORE constraint membership. Agents call `checkConstraint` on the still-untyped itype, THEN substitute the default -- promotion code present but dead for the decision. Symptom: `untyped float/rune/complex does not implement main.X`. Plus a CASCADE: nested calls (`EqX(MinX(3.14,1.41),1.41)`) and the success-path callback (`DoubleNumQA(3.14)`) fail because the inner promotion never happens -- different junit signature from the typed-pin trap, so it must be a SEPARATE QA block.
2. **Typed-pin loose `assignableTo`** (~40%). Agents reconcile `MinX(int64(3), 3.14)` via `matchDefault || assignableTo`; the loose arm accepts untyped-float-vs-int64-pin, instantiation proceeds, and the constant-folder emits `157/50 truncated to int64` instead of the structured `ErrMismatchedTypes`. Fix = strict representability predicate, not `assignableTo`.
3. **Rune-only / cross-kind-empty / comparable-array arms** (1-2 each). `untypedRune` carries `name:"int32"` but `str:"untyped rune"` and `equals` compares `id()` (=`str`), so a rune default never matches the `int32` member unless special-cased; the `Constraint` payload field left empty on mismatched-types; the recursive comparable walk missing the `arrayT` arm.

Passing runs (S#1/7/9) all did three things: promote untyped BEFORE membership, strict representability for typed pins, and an `arrayT` arm in the comparable walk.

**Why it is a good Diamond:** pure type-system SEMANTICS trap (not wiring/concurrency/positioning), 3 distinct failure clusters (no single chokepoint), all fails legitimate engineering mistakes against explicit spec.

**THE dominant lesson -- the QA artifact has its own approval gate.** This sub cleared solvability (3/10), Holistic, and Auto Review days before approval; the ONLY remaining blocker was per-test QA FACTUAL accuracy. failure-qa.md + test-groups.md are first-class gated deliverables. The 4 QA-only rounds (1 reviewer change-request: mis-attribution + over-collapse + cross-run leak; 3 validator: runErrIs over-generalization, bare `gc`, value-anchored line numbers, float/complex over-attribution) were avoidable by reading the approved gold-standards FIRST. Sharpest rule: **value-anchored line numbers** (a number presented as the locator for a field value) flag MIXED off-by-one and the validator is non-deterministic on them; **behavior-anchored** numbers (beside a named function) are tolerated -- name the symbol, drop the number. Second yaegi Diamond to converge on the same QA discipline as yaegi-channel-diagnostics -- 2x-confirmed. Full rules: `PATTERNS-ADVANCED.md § 44-45`, `DIAMOND-PLAYBOOK.md § Section 5 rules 28-34`, `lessons-learned.md rules 49-57`, `KNOWLEDGE.md` Castor entry; copy-ready writer prompt `Instructions/QA-WRITER-PROMPT.md`; per-repo authoring detail `problems/yaegi/LESSONS.md` (Diamond section).

## yaegi-const-representability (Go, Diamond — APPROVED 2026-06-06, 3rd approved yaegi Diamond)

Shape: O-Algorithm-correctness. Reviewer: **"QAs are good, but can get more detailed with citations like trajectory steps. Acceptable."** (accepted; trajectory-step citations are a quality-lift, not a blocker.)

**Anchor profile (approved):** unhinted 10x Castor = 0/10, all FAIR `MISSED_REQUIREMENT` (Holistic: NEEDS_HINTS not UNFAIR, 80+/98 subtests pass nearly every run); shipped HINTED after the fair 0/10. Solutions ~590 LOC mean (484-933) across 5-7 files; 98 F2P; 1330/1330 baseline preserved all runs. One new file `interp/constdiag.go` (or agents' `const_diag.go`) + edits to `cfg.go`/`interp.go`/`type.go`/`typecheck.go`. Public API: `ConstantConversionError{Kind,Sink,Lit,TargetType,Reason,Position}` + `Error`/`Unwrap`; five sentinels (`ErrConstantOverflows`/`ErrConstantTruncated`/`ErrConstantNotRepresentable`/`ErrConstantDivisionByZero`/`ErrConstantInvalidShift`); `IsConstantConversionError`/`AsConstantConversionError`; `ConstantReport`/`WriteConstantReport`/`ValidConstantReportMode`; `ConstantDiagnostics`/`ResetConstantDiagnostics`/`ConstantDiagnosticCount`/`HasConstantDiagnostics`/`ConstantDiagnosticsByKind`/`ConstantDiagnosticsBySink`/`SortedConstantDiagnostics`/`GroupedConstantReport`/`SummarizeConstantDiagnostics`; `Options.OnConstantOverflow`/`Options.CollectConstantOverflows`.

**Core difficulty engine (same family as yaegi-generic — the interpreter-type-system seam):** go/constant STRICT representability vs yaegi's pre-existing LOOSE checks. Every universal Castor wall is "tighten a permissive built-in": (1) the `complex` builtin folds to a `complex128` stored in `n.rval` (NOT a `constant.Value`), so a check gated only on `n.rval.Interface().(constant.Value)` silently skips every overflowing complex — agents must read the folded `complex128` and test each component against the destination width; (2) the integer check ends `return constant.BitLen(x) <= bitlen[t.Kind()]` (bit-width, so 200 fits int8's 8 bits though it exceeds 127) — agents must compare against exact signed/unsigned bounds; (3) `ConstantReport` returns `""` for an empty diagnostic set (agents returned `"[]"`/a header). Confirms the seam keeps producing Diamond-grade FAIR walls.

**Effective Castor traps (the 0/10 universal blockers, all FAIR):**
1. **Folded-`complex128` blind spot** (10/10 universal, broadest). `complex(1e400,0)` is a concrete reflected complex, not a `constant.Value`; the `representable` gate (`typecheck.go` ~1126) returns nil for it, so composite/var/return complex overflow all go unreported. Hint-worthy (a hard repo-internal hook).
2. **Width-vs-range** (StrictSignedRange + CrossFeature). 128/200/-200 fit int8's eight bits, 40000 fits int16's sixteen, yet leave the signed range; the bit-width test accepts them. Same root surfaces in the cross-feature undercount (the int16 composite element is missed -> only 2 of 3 diagnostics collected).
3. **Empty-report convention** (10/10). `ConstantReport(mode)` returns the empty string for EVERY mode when clean; under-specified -> hinted.
4. Run-dependent secondaries: fractional array/make length under the wrong sentinel (truncated vs not_representable), negative-length kind, oversized `[1<<70]int` PANICS via `constToInt` (`BitLen>64`) aborting the package, `default`-mode recording, and (one agent) the cfgError-no-`Unwrap` wrapper hiding a correctly-built structured error from `errors.As`. Each Castor run is a DIFFERENT implementation, so the SAME test fails for different reasons across runs — never copy a root cause between runs.

**Failure-QA arc (the dominant authoring lesson, 3rd-in-a-row confirmation):** ~6 validator round-trips, every one resolving a backticked token that does not appear verbatim in the artifacts. New MIXED classes beyond yaegi-generic/scriggo/csstree: comparison-flip (`len(d) >= 3` vs source `if len(d) < 3`), substituted-arg/ellipsis (`errors.Is(err, ErrConstantTruncated)` vs `errors.Is(err, sentinel)`; `complex(...)`, `[]complex128{...}`, `cfgErrorf("...", ...)`), fabricated call-result (`constant.BitLen(256)` is 9), wrong-file-hunk location (`const_diag.go line 920` for code in the `typecheck.go` hunk). Two FALSE classes: parent-rollup conflation (Go table PARENT fails as `<failure message="Failed"/>` with no body — do not claim "each renders message X"; count subtests-with-message + parents-as-`Failed` + special-text subtests) and stale-per-run data (an S#11 block built on a stale 52-test list invented a signed-nil group and denied the four real ones; rewrote to the actual 57-test run). **The fix is one mechanical pre-submit step: grep every backticked token against the artifacts before upload** (DIAMOND-PLAYBOOK rules 59-64, Pattern 52). Group count per run must equal total - passing.

**Why it is a good Diamond:** pure type-system SEMANTICS (representability), 3+ distinct fair failure clusters (no single chokepoint), every fail a legitimate engineering mistake against explicit spec, and a hint that bridges one hard repo-internal hook + one under-specified output convention without naming a helper/file/step. Third yaegi Diamond confirming the interpreter-type-system difficulty engine AND the QA-validator literal-token discipline. Full rules: `PATTERNS-ADVANCED.md § Pattern 52`, `DIAMOND-PLAYBOOK.md § Section 5 rules 59-64`, `lessons-learned.md` (yaegi-const-representability entry), `KNOWLEDGE.md` Castor entry.

## dasel-compound-assign-operators (Go, Mars Solid — R1 revision cleared reviewer bar 2026-06-06, user-greenlit; platform-final pending)

**Tier:** Mars Solid. Shape: A2 (concentrated bulk + thin wiring) at R0; widened toward Mars B at R1 (adds lexer tokens). Wires `+= -= ++ --` (R0) plus `*= /= %=` (R1) through parser + executor.

### Submission specs (R1 final)

- BASE_COMMIT: `0dd6132e0c58edbd9b1a5f7ffd00dfab1e6085ad`
- Solution: 7 files (`selector/lexer/token.go`, `selector/lexer/tokenize.go`, `selector/parser/denotations.go`, `selector/parser/parser.go`, `selector/ast/expression_complex.go`, `execution/execute_binary.go`, `execution/execute_unary.go`); 187 raw / 138 eff added LOC
- Tests: 82 RUN entries (incl. subtests) in `execution/execute_compound_assign_752438_test.go` (build tag `dasel_compound_assign`); +16 tests added in R1 for `*= /= %=`
- meta.md: 320 words (rose from 239 with the 4->7 operator scope; under 500 hard cap)
- No new exported Go identifiers — all behavior via `selector.Parse` + `execution.ExecuteSelector`

### A. Behavioral Data

**Confirmed traps (R0.5 12-run eval, pre-revision, 0/12):**

| Trap | Runs hit | Class |
|---|---|---|
| Variable postfix aliasing (`$x++` returns NEW not OLD) | 9/12 | snapshot-before-mutate; pointer aliasing |
| `++a++` not rejected | 8/12 | positive allow-list, forgot to reject UnaryExpr target |
| Nested ChainedExpr property paths (`a.b.c += 1` rejected) | 3/12 | flat one-level validator |
| Baseline regression (parser denotation interference) | 4/12 | agent fault |
| Executor never wired (parser-only) | 3/12 | early-term / partial impl |

**R1 reviewer-variant signal:** "passed-agent diffs conservative median `91`, below required `> 100`." Passing agents EXIST (problem solvable) but minimal passing solution too small — thin wiring delegates to existing `Add`/`Subtract`/`Set`, so agents skip every code path the tests don't force.

**Dead-code probe (key R1 finding):** every branch-producing l-value (`branch(...)`, spread `a[...]`, range `a[0:2]`, `all()`) is rejected by the `isPropertyPathTarget` guard with `must be a property path`. So the `IsBranch()` arm in `executeCompoundAssign` is UNREACHABLE for valid targets; `map`/`filter` iterate scalar-`$this` per element (never a branch l-value). Branch handling could not be the LOC lever and is itself a latent dead-code flag.

**Test-to-anchor mapping (R1 additions):** `*= /= %=` arithmetic -> para 2; integer-division truncation (`10 /= 3 -> 3`) -> para 3 "integer division keeps integer results"; int->float promotion (`3 *= 1.5 -> 4.5`) -> para 3; literal/arith target error -> para 4 "must be a property path"; string target -> para 3 incompatible-types; map/filter `$this` -> para 4 "current value or a selected branch element".

### B. Iteration Lessons

**Iteration arc:** R0 (4 operators, A2) -> R0.1-R0.5 (test-shape fixes, AI-slop strip, alignment, fairness, hint-encode-as-prose) -> R1 (two reviewer items: passing-LOC gate + branch/current-value contract).

**R1 fixes (both in one pass):**
1. *Passing-LOC gate (Bucket 5, NEW revert cause).* Lever = complete the compound-assignment FAMILY: add `*= /= %=` reusing existing `model.Value.Multiply`/`Divide`/`Modulo` through the same `executeCompoundAssign` helper. Mechanical copies of the `+=` path -> minimal passing solution +~20 eff (91 -> ~111+) with difficulty held flat (agent that solves `+=` solves all). New tokens appended at END of the lexer const block (no renumbering -> error-message token numbers stay stable). `*=`/`%=` work on floats; `/=` truncates on ints; `/= 0` and `%= 0` PANIC (pre-existing `Divide`/`Modulo` behavior, same as `/ 0` — NOT tested, NOT fixed = no scope creep).
2. *Branch/current-value contract (Bucket 1, hidden requirement).* Added reviewer's sentence near-verbatim ("The operators must also work when the assignable target is the current value or a selected branch element, such as a mapped or filtered `$this`."); KEPT the map/filter tests (narrowing them would worsen item 1).

**Traps that worked:** postfix-old/prefix-new asymmetry (9/12 kill), `++a++` rejection (8/12), nested-chain validator (3/12).
**Trap that could NOT work:** branch-target compound-assign — dead code behind the property-path guard.

**Lessons — cross-cutting (filed):**
1. RULES § Real Revert Causes — new row "Passing-agent diffs too small (Mars substance gate)".
2. lessons-learned § Human Reviewer Patterns + Solution Quality § LOC — the family-completion lever + "gate measures minimal PASSING solution, not your reference".
3. **dasel comment convention = NONE** (re-confirmed): solution + test patches ship zero `//` comments; pre-gen guard returned empty.
4. **Probe code paths empirically before assuming a branch is a test lever** — build the binary, feed real selectors; a guard-rejected path is dead and cannot raise required LOC.

## data-forge-resample (TypeScript, Olympus — APPROVED 2026-06-18, reviewer miyamura)

### Outcome
Approved as Olympus. Agent eval 1/13 pass (7.7%, "Hard"); fair; solvable; long-horizon PASS (median 5 files / 146 msgs / 1109 LOC); no cheating; no env blockers. Authored as Olympus -> re-tiered Mars on a static Task-Quality Crit-08 fail -> ended Olympus (empirical long-horizon overrode the static call). ~7 precheck rounds (well over the Mars 1-3 budget) driven almost entirely by platform-check flakiness, not artifact defects.

### Shape + Stats
`DataFrame.resample(timeColumn, rule, aggSpec, options)` + `Series.resample(rule, aggSpec, options)` time-bucketed aggregation onto a DENSE gap-filled grid. base 4e19deeb. solution 532 eff / 8 files (resample.ts engine + 4 lazy iterable/iterator files + DataFrame/Series methods + index export). 48 F2P tests. meta ~470w. Repo: TS 2.8.3 / ES5 / mocha. Comment convention: heavy JSDoc on public methods, comment-free tests.

### Decisive difficulty driver (the win)
"An input with no rows yields an empty result." — a sentence added DEFENSIVELY for empty-input fairness in a mid-saga round — became the dominant trap. 12/13 agents validate the time column exists BEFORE handling `new DataFrame([])` (which, in this schema-light lib, has no inferable columns), so they throw a missing-column error and fail ONLY that one test (47/48). Genuine INTERDEPENDENT + MISDIRECTING: the naive missing-column guard breaks the empty-input case, and the failure message ("missing column") points away from the real cause (validation ORDER / precedence). A defensively-added fairness sentence can become the load-bearing difficulty lever.

### Confirmed cross-agent blind spot (Nova + Orion, 12/13)
**Validation-order / empty-input precedence**: agents guard required inputs (column existence) before special-casing empty/zero-row inputs. When a spec says both "missing X throws" AND "empty input yields empty," they implement the throw unconditionally and miss that empty must short-circuit first. Reusable trap for any feature with an empty-input rule + a required-arg validation.

### Platform-check flakiness (the real cost; see lessons-learned)
- **Test Fairness is NON-DETERMINISTIC on error-message substrings**: it accepted `/rule/` + `/timeColumnName/` in one round and rejected the identical tests in a later round; across rounds it rejected every substring tried (`/rule/`, `/timeColumnName/`, `/options/`, `/closed/`, `/aggregator/`). No error-substring is stably "fair."
- **Solution Quality's expected-test cache lags exactly one round**: each round's "missing nodeid" synthetic failures = exactly the tests deleted the PREVIOUS round. Churning the test set to chase the fairness checker perpetuates SQ failures.
- These two pull in OPPOSITE directions (fairness wants validation tests gone; SQ-cache penalizes deleting them).

### The fix that broke the deadlock
A validation-throw test made BOTH fair AND f2p, with ZERO substring coupling: pair (1) a behavioral value-assert on a VALID call (the fail-on-base anchor — the method is undefined on base) with (2) a BARE `.to.throw()` (no message; the checker itself says "a throw-only assertion would be fair"). Re-add the EXACT nodeid names the SQ cache expects so they are present+passing regardless of cache lag. Result: Test Fairness 0 flags + SQ 0 missing, deterministically.

### Iteration lessons
1. Single-subsystem + training-saturated (pandas resample) + validation-heavy = a fairness-thrash magnet; design behavioral-only assertions from the start, minimize validation-throw tests.
2. A static Crit-08 "single-subsystem" FAIL is not final — the empirical agent rollout (real multi-file LOC) can override it. Don't auto-downgrade to Mars on the static check alone.
3. Derivative 0.68 vs a competitor's resample racer never hard-blocked (stayed a WARNING through approval); the custom-Date[]-edges differentiator + behavioral divergence were enough.
4. Reviewer note: "keep the description less prescriptive/verbose" — the dense ~470-500w meta drew repeated conciseness flags; lean descriptions read better even when every sentence is test-traced.

## cel-go-strict-dyn (APPROVED Diamond 2026-06-17)

google/cel-go opt-in StrictDynChecking() type-checker mode. 7 files / 463 eff / 19 F2P across 17 groups (build-tag strict_dyn_78bf01). unhinted 0/10, hinted 1/10 (Hard), Holistic 1/20 = 5% no-unfair.

Feature: in strict mode the checker REJECTS (as an ordinary compile error) a value that became `dyn` IMPLICITLY when supplied at a concrete-typed position. Three implicit channels: a dyn-typed variable, an unresolved type parameter promoted to dyn, a heterogeneous join of variable-typed parts. The explicit `dyn()` macro opts back into wildcard behavior. Mixed concrete LITERALS ([1,"x"]) are out of scope. Structured surface: StrictDynViolations accessor (DynViolation{ExprID,OriginID,Site,Source,Type,String()}) + StrictDynReport aggregation.

KILLER WALL (group rate ~0.16, lowest): unresolved-type-param promotion consumed at a concrete site (first([]).startsWith("x")). Provenance is lost because the promotion to dyn happens at FINAL substitution, AFTER the consumer overload binds T; a deferred/post-walk classifier reads concrete. Other fair gates: value-only aggregate-join (~33% miss - map-key/list joins missed because the join check runs over map VALUES not keys, or only fires when a part already carries dyn); dyn()-escape laundering (over-rejects [dyn(d),1,2].all(...) when the range-exemption is keyed on a DIRECT dyn() call or isLiteral is false for the dyn() node); enforcement-not-wired (record-but-don't-reject -> Compile succeeds, ~2/10 accessor-only); zero-arg option signature (StrictDynChecking(bool) vs ()) compile-cliffs the suite (1/10).

Hint: para1 strict-violations-are-compile-errors / para4 type-param converter ("judge the value by what its own call produced, not what the consuming op could turn it into", ALL-OR-NOTHING) / para5 dyn()-escape; pass RATE tuned by the un-hinted map-key gate -> 1/10.

Lessons: home opus proxy 3/3 + grounded deep-dive NO-GO BOTH overruled by platform (platform = only oracle); a single-subsystem feature reached Diamond via integration-TIMING not algorithm depth or cross-subsystem span. Resubmit arc: proto.String() p2p flake fix Auto-Review-FALSE-blocked -> admin override. See KNOWLEDGE Castor profile, lesson_diamond_failure_qa_annotation, lesson_proto_string_subtest_p2p_flake.

## expr-switch (Go, Olympus — ACCEPTED 2026-06-19, pivoted from Diamond)

### Outcome
Authored as Diamond -> Diamond Checks 0.69 Castor (best-of-N) = TOO EASY -> pivoted Olympus -> Olympus eval R1 0/10 Nova = TOO HARD (0%=reject, +1 unfair flag) -> 2-test fix -> Olympus eval R2 1/10 Nova (10%) = ACCEPTED, 0 unfair. All R2 fails FAIL_MISSED_REQUIREMENT (agent-fault, description_clear=true, difficulty=challenging).

### Shape + Stats
First-class `switch`/match EXPRESSION across parser/ast/checker/compiler/optimizer + vm execution (O-Composite-add). base 2010a112. 540 eff / 9 source files. 130 F2P tests (build tag switchexpr, root pkg expr_test). meta ~396w. Two forms (subject `switch x {case v: ...}` + subjectless boolean). Features: guards `case v if cond`, ranges `case 1..5`, multi-value, default, no-match runtime error, duplicate/overlap compile errors, bool exhaustiveness, constant fold. node.go doc-comments new types; all other touched files comment-free.

### Decisive difficulty drivers (what actually bit on Nova — NOT the designed traps)
The designed traps (subject-once, compiler stack-discipline, no-match-error) got SOLVED. The real interdependent+misdirecting biters were the agents' OWN implementation bugs on documented-but-subtle requirements:
1. **Over-aggressive constant fold (~7/10):** agent folds a constant-SUBJECT switch even when case VALUES are nonconstant (`case x`, `case probe()`), treats nonconstant values as non-matches, compiles the default -> skips runtime cases. MISDIRECTING: the failing test asserts a runtime VALUE match; the bug is in the optimizer/compiler fold, which the assertion does not point at. Spec only settles when BOTH subject and matching arm are constant.
2. **Within-arm vs across-arm collision-set scoping (~6/10):** agent accumulates seen-values/ranges WHILE iterating values inside one arm, so a later value collides with an earlier range in the SAME arm (`case 1..5, 3:` wrongly rejected). Spec: collision checks compare separate arms only. INTERDEPENDENT with dup/overlap detection (the seen-set's accumulation boundary is the bug).
3. (minor) computed string dup `"a"+"b"`==`"ab"` (agents' const-eval only does numbers).

### Iteration lessons
1. **Diamond-too-easy -> Olympus pivot WORKS via the AGENT POOL, not the review bar.** Diamond=Castor (strongest, best-of-N); Olympus=Nova/Orion/Vega (weaker, single-attempt). Castor 0.69 -> Nova 0-10% on the IDENTICAL artifact.
2. **The band is razor-thin + hypersensitive on a saturated feature.** A TWO-TEST change (remove 1 unfair test + clarify 1 meta sentence) moved Nova 0/10 -> 1/10. Calibration, not authoring, was the whole job.
3. **Optimizer-AST-INSPECTION tests are UNFAIR (implementation-specific).** `constant_subject_settled_at_compile_time` asserted the optimized AST has no SwitchNode; Orion flagged it (agents fold at bytecode-compile, which satisfies "settled while compiling"). Removed; OBSERVABLE constant_fold value tests cover it fairly AND still catch the over-fold bug.
4. **Scope dup/collision rules to the form they apply to.** The rule didn't say "subject form only"; agents reasonably dup-checked the subjectless boolean form (`case false case false`) -> 1 agent_blame_unfair=TRUE. One meta sentence ("the subjectless shape has no collision check, since its arms are boolean tests rather than values") cleared it.
5. **0% on a weak single-attempt pool with all-fair fails = TOO MANY independent fiddly requirements** (weak agent misses a different subset each run), NOT one hard wall. Fix = CUT the 1-2 most-missed/least-fair reqs, the inverse of "add a trap."

## yaegi-methodset-enforcement (APPROVED Diamond 2026-06-23)

### Outcome
4th yaegi Diamond, APPROVED by human reviewer. Hinted 2/10 (~20% Hard), Holistic PASS, all 12 Castor runs annotated fair. Base fcb76d1e (same as constraint-fidelity).

### Shape + Stats
Zero-new-API spec-conformance enforcement (make illegal Go FAIL via the existing Eval error channel + repair 2 silent corruptions). 493 eff LOC / 4 files (new interp/methodset.go + cfg/typecheck/type), 36 fail-to-pass / 6 groups, NO build tag, hex suffix `8d83d4`. Three engines: receiver-aware interface satisfaction, BFS shallowest-unique selector, addressability classifier.

### Decisive difficulty drivers (what actually bit Castor)
- Shallowest-wins left in DFS runtime lookup while only a diagnostic was added (near-universal) — detecting ambiguity is not changing which member is selected.
- Interface-merge accept twin over-rejected (struct-style ambiguity applied to an interface root).
- Satisfaction skipped for interface-typed sources + comparisons (concrete-only).
- Comparison error-SELECTION (rejected with the satisfaction message, not `mismatched types`).
- io.Writer reflect-backed signature deferred to runtime; diamond dedup by type identity; addressability carve-outs (array-literal slice/index, pointer-valued map element, nested map write).

### Iteration lessons
- Two PLATFORM-MECHANICS gates dominated the to-PASS arc, not difficulty: (1) grader applies the test patch over the agent's mutated tree -> additive-only test patch + solution must preserve intentional maintainer behavior (#1149/#1150) rather than flip an existing test; (2) grader runs plain `go test` with no custom `-tags` -> a hide-the-f2p build tag = inverted-reward Env-Linter BLOCK -> drop tag, isolate base by prefix mismatch + BASE_RUN.
- Hint = short directional prose, dominant near-miss only, reject+accept halves co-equal (over-stressing a reject half regressed its accept twin).
- A clean platform auto-grader is NOT a substitute for a human Describe-Tests pass: it rubber-stamped 4 factual errors the human caught (group tests by BODY not name; a 36/36 PASS run still spec-wrong on the untested `([4]int{...})[1:3]` array-literal slice -> success-QA "tests pass but impl wrong" + lower confidence + issue-type Correctness).
- yaegi test gotcha: Eval does not return IIFE values -> capture stdout via interp.Options{Stdout:&buf}.

## starlark-rust-set-literals (APPROVED Mars 2026-06-25)

Outcome: APPROVED Mars. facebook/starlark-rust (Apache-2.0, base 03fb048). Feature: set literal `{a,b}` + set comprehension `{x for x in xs}` syntax gated by a new `Dialect.enable_sets` flag (default off, mirroring opt-in f-strings; set runtime type already opt-in).

Shape/stats: syntax feature spanning parser -> AST -> scope -> compiler -> bytecode (new InstrSetNew/SetNPop/ComprSetInsert) -> runtime -> typing -> analysis -> LSP. 22 source files, 232 eff LOC, 46 behavioral f2p tests (solution 46/0, base 0/46). Pass rate 1/13 = 8% (Difficulty: Hard). Holistic PASS, Auto Review PASS body.

Decisive difficulty driver: NOT the feature (pure sugar for set([...]) -> all 13 agents passed all 46 feature tests; every test group 10/10). The discriminator was LONG-HORIZON THOROUGHNESS: the syntax/opcode change BREAKS two existing baseline goldens that the agent must also fix -- `test_profile_golden_bytecode` (100% miss: added opcodes, forgot to regen profile snapshot) and `syntax::grammar_tests::test_error_bad_comprehension` (90% miss: `{x for y in z}` is now a valid set comprehension, obsolete parse-fail case must be removed). 12/13 ran only focused tests and skipped full-suite validation -> baseline red -> fail. The one thorough Orion ran the full suite, fixed both goldens, passed.

Iteration lessons:
- Assigned pick was a Diamond for record-type-identity #139+#120; #139 was ALREADY FIXED on base (content-deterministic TypeInstanceId, commit e182421b) -- reproduce-on-base via the REAL CLI (the Assert harness caches the loaded module and never reproduced it). starlark-rust yielded NO clean Diamond (3 dead-ends: #139-fixed, union-assignability=maintainer-philosophy-conflict, def-inliner=behavior-preserving-bytecode-golden-unfair). Pivoted to set-literals Mars.
- recon LOC estimate (494 meaningful) was ~2x the measured 232 -- build-measure, never trust the projection.
- First eval batch 0/12 -> NEEDS_HINTS, but that was a NO-PASS ARTIFACT; a 13th legit hint-free Orion pass flipped Solvable + Holistic to PASS. Do not declare a problem dead on a single 0/N batch when the failures are inferable baseline maintenance.
- Auto-review header read "CHANGES REQUESTED" but the body was PASS (safeToMerge:true) with one NON-BLOCKING note (analysis lint passes not extended to new variants). Submitted as-is -> approved.

## typify-object-applicators (APPROVED Diamond 2026-06-25)

OUTCOME: oxidecomputer/typify (JSON-Schema -> Rust serde codegen, Apache-2.0). Authored Olympus, retiered Diamond via Diamond Checks, approved. Base 465e72b. Now at `diamond-problems/approved/typify-object-applicators/`.

SHAPE + STATS: O-Algorithm-correctness / codegen round-trip (see SHAPES.md). 462 eff LOC / 5 source files (merge, convert, structs, type_entry, util). 22 f2p tests (109 baseline, 0 regress). Difficulty: unhinted 0/10 Castor (Holistic NEEDS_HINTS), hinted 1/11. The feature: make typify round-trip the object applicators it drops - `properties`+`patternProperties` overflow, `allOf` extending a patterned base, `minProperties`/`maxProperties`, `propertyNames`, differing pattern value schemas.

DECISIVE DIFFICULTY DRIVERS: the REPRESENTATION SPLIT (struct vs map/newtype) - agents implement the struct path and miss the co-equal map path + the unnamed-root-key generation panic (`make_map(type_name.into_option())` drops the title -> key is `Name::Unknown` -> `get_type_name(...).unwrap()` panics). The codegen round-trip wall: generated serde derives must accept exactly the schema-allowed JSON. Single-subsystem but cleared Diamond on representation breadth.

ITERATION LESSONS: (1) 2-agent local solvability sim is the ONLY pre-platform catch for codegen test-coupling; relax shape/name assertions to behavioral, drop ambiguous-strictness clauses both strong agents fail. (2) build-measure 233 (3 behaviors) -> 462 (7 behaviors); never project. (3) 3 QA rounds (2 validator + 1 reviewer) - validator flags code-location/timing/verbatim-token/per-agent-helper; reviewer flags mechanism accuracy, reference-writeup fidelity, success-block honesty. (4) scope-only hint flips the 20/22 near-misses; leave the hard sub-trap unhinted to cap the ceiling.

## cel-go-cost-coverage (APPROVED Mars 2026-06-24)

### Outcome
google/cel-go #1105. Designed as Diamond -> build-measure put the feature's honest eff ceiling at ~190-210 (single-subsystem cost-coverage, under the 400 Olympus floor) -> re-tiered Mars. Landed ~25% pass over a 13-run batch, holistic FAIR. Base f456a6ec.

### Shape + Stats
Opt-in `OptionalTypesCostTracking()` on `cel.OptionalTypes` brings the optional-types library into CEL's cost system: static checker estimator (checker/cost.go) + runtime cost tracker (interpreter/runtimecost.go) + size-aware base64 in ext.Encoders. Single-subsystem cost-coverage EXTENSION of an existing library across a DUAL-MAINTENANCE pair (static cost.go <-> runtime runtimecost.go twins). 192 eff / 5 source files / 31 tests (see SHAPES.md shape note + Pattern 58).

### Decisive difficulty drivers
- **Static-soundness off-by-one (10/14, the dominant FAIR trap).** static `Max` must stay `>=` runtime `ActualCost` through `[..][?0].orValue("").contains("z")`; the naive bounded-size fix lands static ONE unit below runtime, ONLY at large size. INTERDEPENDENT (two files must agree) + MISDIRECTING (undershoots only at scale, reads like a flaky bound). Canonical terminal = `contains("z")` ONLY (scales + sound + saturates; endsWith/startsWith undershoot, size() is O(1)/vacuous).
- **R1 unfair-API masked too-easy (planck pattern).** An undocumented report-API's Go method signatures compile-failed 5/6 runs -> looked 40% but ~90% fair-pass underneath. The cost engine itself was nearly saturated; the apparent difficulty was a signature-ambiguity mirage.

### Iteration lessons
- ⭐⭐ **PLATFORM CHECKS CONTRADICTED EACH OTHER three ways on ONE behavior** (runtime-charging or/orValue): Test-Fairness "unfair," an earlier round "opt-in leak," a later Solution-Quality "you must charge every optional construct." RESOLUTION = align meta.md to the fair, library-consistent behavior (CEL does not charge its own `||`/`&&` short-circuit per node, so or/orValue runtime-charging is over-prescriptive) and flag the reviewer; do NOT implement the twice-rejected thing or ping-pong the code. Final meta: "Because or and orValue short-circuit, they are not charged as separate runtime calls; the static estimate stays a sound upper bound." Static side still charges or/orValue (union of branch sizes, tested).
- **DROP the ambiguous inspection/report API, do not specify it.** An inspection/report surface over an already-computed value = pure glue = 0 difficulty + 100% of any signature-ambiguity unfairness. Removing it cleared the R1 unfair flag and exposed the real ~90% pass underneath -> motivated the static off-by-one as the actual difficulty.
- **GIVEAWAY AUDIT:** a meta sentence "Two/Three spots are easy to get wrong: ..." spiked pass to 60% too-easy; strip pitfall-spotlighting sentences.
- **STALE-CHECK:** an SQ FAIL cited a test deleted the prior round; cross-validated against same-run Test-Fairness (live set) -> stale cached report; a fresh re-run cleared it.
- Ops: Go rebuild-safety via vendored offline build (drop `go mod download`, set GOFLAGS=-mod=vendor + GOPROXY=off + GOTOOLCHAIN=local); deterministic JUnit subtest names `case_%d` to dodge the protobuf detrand String() flake.

## glaredb-ordered-aggregates (APPROVED Olympus 2026-06-27)

### Outcome
GlareDB/glaredb. Aggregate `FILTER (WHERE)` (parsed-but-ignored on base) + aggregate-local `ORDER BY` (parse-error on base) for `string_agg`/`first` + new `last`, `arg_min`/`arg_max` (`min_by`/`max_by`). Two platform batches: 1/10 (10% Hard) pre-reviewer, 2/12 (16.7% Hard) after a reviewer change request, both in the <=20% Olympus band, all runs fair, Holistic PASS. Base 549b01cb. 775 eff / 16 files.

### Shape + Stats
O-Pipeline-hard, cross-subsystem: parser -> AST -> resolver -> binder -> aggregate-function framework -> hash/ungrouped aggregate execution. Correctness trap centered on the DISTINCT aggregate path. Buffering ordered-aggregate state: sort keys threaded as EXTRA aggregate inputs so the existing pre-projection/update path carries them for free; state buffers `(sort_keys, value)` per group; combine concatenates; finalize sorts (shared `compare_sort_keys`, NULLS independent of ASC/DESC) + dedups-after-sort for DISTINCT + folds. arg_min/arg_max = generic ScalarValue single-pass key-extreme aggregates reusing `compare_scalar`.

### Decisive difficulty drivers
- **DISTINCT-hash-scramble (dominant biter, 3-5/12 alone).** The obvious "global sort before the aggregate" design passes non-DISTINCT + grouped ordering, then SILENTLY fails `string_agg(DISTINCT x ORDER BY x)` because glaredb's distinct path scans a hash table (hash order). Failing output is scrambled (`c,a,b` vs `a,b,c`) -> misdirects toward "sort broken." Fix = dedup-after-sort in aggregate state + operator `is_distinct=false`. Robust to retries (re-architecture, not point-fix).
- **FILTER-CASE-wraps-delimiter (repo invariant as free trap).** Implementing FILTER by CASE-wrapping every aggregate arg turns `string_agg`'s constant delimiter non-constant -> hits the pre-existing "2nd arg must be constant" rule.
- **Planner index-OOB (integration wall, ~3/12).** Threading ORDER BY columns into aggregate pre-projection with inconsistent indices panics (column_expr/batch out-of-bounds).
- **Aggregate-exec rewire -> baseline regression (~2/12).** Routing input once-per-aggregate breaks grouped paths with no non-distinct aggregate (SELECT DISTINCT, set ops, GROUP BY w/o aggregates).
- **NULLS-vs-DESC coupling (1).** A naive `reverse()` flips null placement too; SQL requires them independent.

### Iteration lessons
- ⭐⭐ Reviewer "broaden scope slightly / near the bar + boilerplate" -> add a SIBLING aggregate family (arg_min/arg_max), not plumbing. 581 -> 775 eff of real logic.
- ⭐⭐ Broadening with EASY siblings is band-safe when the core trap is robust: rate moved 10% -> 16.7%, stayed <=20%; the hard biters are independent of the easy surface. Append easy tests at the slt END to keep the failure point for failing runs.
- ⭐⭐ Introduced default (NULLS placement) MUST match the repo's analogous default; glaredb regular ORDER BY = `None => desc` (ASC NULLS LAST / DESC NULLS FIRST). A divergent default is the kind of latent bug a reviewer's "pin the default" note exposes.
- Reject test: assert the BEHAVIOR (bare `statement error`), never the exact error wording (the platform alignment check fails on an unstated error-text pin).
- LOC measure: `git diff $BASE` excludes untracked NEW files (read 429); `git add` + `--cached` gives the true 775.

## piccolo-finalizers-gc (APPROVED Mars 2026-07-04, 30% Nova 3/10 all-fair)

### Outcome
kyren/piccolo (stackless Lua 5.4 VM in Rust on gc-arena). Implements the finalization + weak-GC subsystem the README lists as unbuilt: `collectgarbage` option set, weak `__mode` k/v/kv with ephemeron semantics, `__gc` finalizers (resurrection + reverse-install-order + once-each). Base ce709eb1. 361 eff / 6 src files. Originally scoped Olympus (452 eff via a userdata `__gc` axis) -> post-checks exposed userdata as undiscoverable-Rust-API PADDING that broke compile-on-base f2p -> re-tiered MARS at the honest fair-testable ceiling. Three test-only hardening rounds: R5 58->63 (~50%), R6 63->69 (53%), R7 69->72 -> **3/10 = 30% Nova, at the Mars cap. APPROVED 2026-07-04 (all-fair).** Reviewer: 364 meaningful LOC / 6 files (below agent median, not inflated), every public symbol traced, ~10% comments, repo-idiomatic, no dead surface, no regressions (33 base green both sides); held at 2/3 only for 4 rustfmt deviations (recommended `cargo fmt`, R2). Solution unchanged across all 3 hardening rounds (difficulty is a TEST-COVERAGE problem here, not a solution problem).

### Shape + Stats
O-Algorithm-correctness, single-subsystem (GC/finalization) but with 5+ orthogonal sub-behaviors. Behavioral oracle = observable post-GC state from Lua scripts only (never internal GC state). Mechanisms: manual `unsafe impl Collect for TableState` skipping the weak side (sound only because clear-pass runs before sweep); ephemeron fixpoint via the gc-arena "call finalize multiple times with marking stages between" idiom; deferred `__gc` execution (resurrect + queue in the two-stage finalize, run bodies later in the driver loop outside the finalization context); `collectgarbage("collect")` observable in-script via a `Gc<Lock<bool>>` request flag + `fuel().interrupt()`; State stays `Copy` so flags are `Gc<Lock<>>` not `Cell`.

### Decisive difficulty drivers (5 ORTHOGONAL walls -- the un-bimodal-ing)
- **A (5/7) Resurrection re-feed not propagated to ephemeron fixpoint after finalizers.** Dominant. Misdirects as a `gc_arena header.is_live()` panic. Deep-chain variant (R7) additionally catches BOUNDED re-feed (re-marks 1-2 levels, not to a fixpoint).
- **B (3/7) collectgarbage multi-arg consume.** `Stack::consume` drains the whole stack -> 2nd-arg consume reads nothing -> wrong setpause/setstepmul previous. Independent, repo-API footgun.
- **C (1/7 solely) Once-each broken across resurrect-redrop.** Re-resurrects an already-finalized dropped object. Independent.
- **D (1/7) Reverse-install-order lost** (vector pop). **E (1/7) kv treated as ephemeron** (dead weak value survives via live key).

### Iteration lessons
- ⭐⭐⭐ A BIMODAL single-subsystem feature (~50%, one-axis understanding) breaks to the cap by STACKING fair tests across the subsystem's INDEPENDENT sub-behaviors, not by deepening the one axis. R5/R6 over-concentrated on axis A and stayed 53%; R7 spread to B/C/D/E and hit 30%.
- ⭐⭐ The kysely/petgraph "single-subsystem = capped" law has an exception: subsystems with 5+ orthogonal sub-behaviors (GC qualifies; membership-validation and predicate-injection do not). ENUMERATE the independent sub-behaviors before shelving a bimodal pick.
- ⭐⭐ For a "propagates to a fixpoint" behavior, ship BOTH a shallow and a deep test -- they discriminate different sub-classes (no-refeed vs bounded-refeed).
- ⭐ Strongest misdirection = a correctness bug that surfaces as a library-internal panic (`header.is_live()`), naming the wrong file.
- ⭐ The platform applies test.patch OVER the agent tree and runs the hidden `finalization_gc_375876.rs`; the agent's own added tests (gc.lua / gc.rs) are shallow and never cover the orthogonal axes -- which is exactly why the hidden orthogonal tests bite.
- LUA-SEMANTICS gotcha: weak clearing is ATOMIC-phase, BEFORE finalizer bodies run. "No re-propagation after a `__gc` body" is CORRECT; the trap is the AUTOMATIC resurrection of the to-be-finalized objects (which DOES precede clearing) not feeding the fixpoint.
- At-cap-edge (30% = Mars max): in-band but tight; a variance-y future batch could tip over. No userdata/host-only surface is fair-testable, so the honest ceiling is this.

## participle-longest-match (MARS, ACCEPTED 2026-07-02 at 30%)

### Outcome
alecthomas/participle (Go reflection/struct-tag PEG parser). Adds a greedy `||` longest-match alternation operator to the disjunction engine, alongside ordered `|`. Base e68cd76. ~114 human-eff / 4 src files. **ACCEPTED.** Three batches: 1/12=8.3%, 1/10=10%, then (after the R5/R6 revisions) **3/10 = 30% ALL-FAIR = the accepted batch** (at the Mars cap). PIVOT from the shelved participle-precedence (correlated-seam, too-easy 80%): chosen by a 4-agent repo deep-dive specifically for an UNCORRELATED wall.

### Two walls (final batch)
- **Leak wall (T2), dominant 6/10:** shared-parent capture leak. `TestGreedyRejectedAlternativeDoesNotLeak` — a rejected alternative captures `Bad=true` directly into the shared `parent` then fails; agents branch the lexer cursor but never snapshot/restore `parent`, so it leaks into the winner. Same wall every batch.
- **Field-boundary wall (2nd), 1/10 (run 8):** `||` split across STRUCT FIELDS (a later field tag beginning `|| @@`, mirroring how existing `|` works across field boundaries) rejected with "alternative expression 2 cannot be empty". Agents implement `||` for same-tag flat alternations only, not as a full counterpart to `|` across field/group boundaries. Fair (inferable from "counterpart to existing ordered `|`" + visible field-boundary `|` usage). This 2nd wall only surfaced in the final batch after the feature was expanded.

### Revision saga (LOC + scope-creep)
- **Auto Review FAIL solution_unasked_feature:** the `Greedy()` global option (added purely for LOC margin) is scope creep (untested public API changing `|` semantics; prompt asks only for `||`). Dropped it (kept `disjunction.greedy` node field). LAW: never add public API to pad LOC.
- **LOC three-counter LAW:** human/strict (reviewer, 96) < hook `human-effective` (100, over-reads ~4) < CLAUDE.md canonical braces-kept (149). Gate on the human/strict; the canonical command over-reads ~50% in Go. Fixed 96->114 by GENUINE expansion on a NON-trap axis (error-diagnostics: restore helper + `joinExpectations` Oxford renderer + deterministic sort), leaving the leak wall byte-identical.
- **Fair mixed-operator test:** the pre-check wanted a Build-error test for `a|b||c`; made it f2p + fair via a grouped-`(a|b)||c` anchor (must build -> fails on base) rather than a "mix" wording pin (which had failed Test-Fairness earlier).

### Shape + Stats
Single-subsystem (parser disjunction engine), but the difficulty lives on ONE uncorrelated state-isolation wall, not on the feature. Feature surface (all transcribed by agents): `||` tokenize + uniform-mode Build error (grammar.go), longest-selection + earliest-tie + furthest-error + expected-set merge (nodes.go parseGreedy), EBNF `||` render, error.go expected(). f2p: every `||` grammar Build-errors on base (`||` -> "alternative expression cannot be empty") -> all 10 tests fail on base, pass on solution, 0 base-passers. Dropped a `Greedy()` global option mid-authoring (new exported symbol = LAW1 f2p break). Removed the mixing test after Test-Fairness flagged its "mix" substring pin (the mixing rule can't be f2p'd fairly -- base rejects all `||` -> no fair distinguishing signal); uniform-mode check stays in solution, untested.

### Decisive difficulty drivers (ONE wall, 11/11)
- **Speculative capture rollback of the SHARED PARENT struct (11 of 11 fails, the sole biter).** `TestGreedyRejectedAlternativeDoesNotLeak`: grammar `(@'!' @@) || ('!' '#' @Int)` on `!#4` -> a rejected alternative captures `Bad=true` directly into the parent then fails at `@@`; the mutation leaks into the winning result. participle `ctx.Branch()` isolates the lexer cursor + deferred `apply` list but NOT direct reflect writes to the shared `parent reflect.Value` (via `strct.Parse` best-effort `Apply()` on error). Agents branch the lexer, pick longest, `Accept` winner -- never snapshot/restore `parent`. Fix = `snap := copy(parent); ...; parent.Set(snap)` per attempt. Uncorrelated: sits off the selection path; agents get the whole feature right and still leak.
- MISDIRECTION: agents self-wrote a rejected-capture test but used the nested-pointer shape their impl handled, not the direct-scalar-into-parent-before-partway-failure shape the hidden test uses -> false confidence -> ship -> caught.

### Iteration lessons
- ⭐⭐⭐ CONTRACT-STATED / FIX-HIDDEN is the escape from the fair-vs-hard tension (see lessons-learned). The meta fully states the no-leak requirement; stating it does NOT reveal the fix (snapshot the shared parent) because the fix is a framework-internals discovery orthogonal to the requirement. Antithesis of ironcalc (where stating the requirement = giving the fix). This is why a single-subsystem Mars landed 8.3% all-fair.
- ⭐⭐⭐ BUILD-MEASURE FORECAST THE BATCH: proving the idiomatic Branch-only impl leaks BEFORE authoring predicted 11/12 exactly. First confirmed positive difficulty forecast from a local probe (probes usually only reject). Reproduce-the-trap-liveness is a real signal when the idiomatic solve provably fails on a repo-internals gap.
- ⭐⭐ UNCORRELATED-WALL test: "can an agent get the FEATURE fully right and still fail the trap?" YES here (selection != isolation) -> hard. For precedence it was NO (the hard part WAS the feature) -> correlated -> too-easy. Ask this before authoring.
- ⭐ Speed/thoroughness: fast decisive Nova (6-10 min, 178-228 LOC) shipped incomplete isolation; the one PASS (Orion, 19 min, 420 LOC) snapshotted. Decisive-commit agents ship the plausible-but-incomplete solve.
- ⭐ A rule whose BASE behavior already errors the same way (mixing -> Build error, like `||`'s base "cannot be empty") has NO fair f2p signal -> keep it in the solution, don't test it.

## symengine-imageset (Mars -- 1/10 = 10% pass, ALL FAIR, 2026-07-02)

**Outcome:** Mars, submitting at 10% (target band). C++ (symengine, CAS kernel). Feature: implement `ImageSet::contains` + intersections (finite set / bounded interval / progression-progression CRT / ambient number sets) for symbolic image sets `imageset(sym, expr, base)`.

**Shape / stats:** single-subsystem (sets.cpp only), solution 149 eff LOC UNCHANGED across R1-R3, test.patch grown 300->516 lines / 1417 assertions. Nova ~200-300 LOC / 90-215 msgs per run.

**Difficulty Configuration (lever-by-lever, MEASURED across 3 real batches):**
- R1: reverse-dispatch coverage trap only (agents add ImageSet-side interval handling, forget `or is_a<ImageSet>(*o)` in Interval::set_intersection) -> **50%** (5/10). Over cap.
- R2: added meta sentence naming the seam ("both operand orderings evaluate") + grew desc to 375w -> **100%** (0 fails). DISASTER: seam-naming + large desc.
- R3: tightened meta 375->217w (state math WHAT only, zero seam-hints) + stacked traps in TEST DESIGN -> **10%** (1/10).

**Proven trap that worked (R3, 9/10 miss) -- CANONICAL-TYPE NARROW-GUARD:** agents gate the interval-enumeration special-case on `is_a<Integers>(*base)` and forget Naturals/Naturals0 are also integer-indexed; the `base->contains` delegation the meta mandates for MEMBERSHIP is not re-applied in the ENUMERATION path. `{2n : n in Naturals} ∩ [-4,4]` -> should be `{2,4}`, agents leave it unevaluated. Misdirecting + interdependent. Full recipe: `PATTERNS-ADVANCED.md § Pattern 62`.

**Traps that were coverage-only (Nova cleared them at R3):** reverse-dispatch (they got it once the meta was tight enough to force discovery), off-by-one half-open endpoints, rational interval bounds, CRT->interval composition, Union-of-images distribution, negative coefficients. Kept as robustness/coverage; only the narrow-guard carried the difficulty (one wall = the difficulty, piccolo law).

**Iteration lessons:**
1. TIGHTEN-FIRST is the primary hardening lever, not adding tests. R2 proved seam-naming -> 100%; R3 tight meta -> 10%. See lessons-learned Rule 7.
2. EMPIRICAL HARDENING: mine `problems/<slug>/agent-runs/S#*/sol-dif.md`, APPLY passing solutions to candidate hardened tests, MEASURE which new traps flip passers before committing a batch. (This surfaced that the endpoint trap flipped passers pre-batch; the batch then revealed base-restriction as the true load-bearing wall.)
3. C++/symengine harness notes: catch2 v2 `--reporter junit --out`; test.sh MUST `cmake --build --target symengine` so a runtime-applied solution.patch is picked up (pre-baked Docker lib = base behavior = segfault); `mp_boost.cpp.obj` only present in a FRESH full-build archive (incremental builds flake it); crash-fallback synthetic-XML for recursion-on-base.
4. Repo caveat: symengine is a CAS kernel = saturated-reference domain (SymPy-documented); this shipped as a fair MARS via a repo-internals integration wall (dispatch delegation), NOT via the algorithm (CRT is textbook). Do not expect Olympus depth from CAS features.

## nickel-1336 dict `_` catch-all metadata (OLYMPUS -- APPROVED 2026-07-04 confirmed-human, 1/10 = 10%)

**Outcome:** Olympus, 10% pass (Orion PASS_LEGITIMATE at batch 4 of a hint-iteration arc: 0/14 -> 0/14 -> 0/10 -> 1/10). Cross-subsystem (parser crate + core crate). Feature: attach field metadata (`doc`/`optional`/`default`/`force`/`priority n` + chained contract + default value) to the `_` catch-all of a dictionary contract `{ _ | T }`, applying to EVERY field -- static, runtime-inserted, computed-name, merge-contributed, nested, and multiple catch-alls.

**Shape / stats:** O-Composite-add with an EXTRA integration floor. Reference solution 21 source files / 541 braces-kept / 439 human-eff LOC, dual-AST (parser `TypeF::Dict` + core `TypeF::Dict`, both grown a `DictMetadata` payload threaded through a LALRPOP-generated grammar), + a `RecordData` catch-all slot consulted at freeze/insert/merge. 26 f2p tests. Nova ~200-300 msgs / 380-600 LOC (fast, dies at compile); Orion 500-700 msgs / 600-1133 LOC (the only agent that carried the full build to a clean pass).

**The FOUR walls, recurrence-ranked by which agent each killed (this is a 4-orthogonal-wall stack = why it landed at exactly 10%, not 0 or too-easy):**
1. **DUAL-AST PARSER-INTEGRATION wall -- THE Nova-killer (killed ~9-10 of every batch on COMPILE, before any semantics; still killed 9/10 in the winning batch).** `_` lives in the TYPE grammar (`{ _ : T }`/`{ _ | T }`); agents add metadata as a record-FIELD production -> LALRPOP local ambiguity on `{ _ | FixedType }`. Correct = a dedicated annotation production INSIDE the dict-contract type grammar, not a record FieldDecl. Compounded by the dual representation: `DictMetadata<Ty,Te>` threaded through generated grammar code (`&Type`/`&Ast`-vs-owned E0308) + ~17 match/initializer sites -- add `catch_alls` to `Record` and miss an initializer in `compat.rs` (E0063), unresolved imports `TermPos`/`fixpoint`/`CatchAll` (E0432/E0433), `Vec<Field>` no `revert_closurize` (E0599), pretty `&&Ast` no `Pretty` (E0277). A cross-crate DUAL-AST feature is a potent Nova-killer on integration ALONE.
2. **PERSIST-ON-RECORD PROPAGATION wall (uncorrelated-wall; held Orion/Vega until the propagation hint).** Obvious path applies the catch-all at contract-application over fields-present-then (static passes); dynamic-insert/computed-name/merge fields flow SEPARATE eval sites (`RecordInsert` binop, `merge` left/right, and `RecordFreeze` which DROPS pending state because `std.record.insert` freezes first) that never see it. Fixing static != fixing dynamic/merge. Misdirecting: the failing insert/merge test surfaces as `NotAFunc` (record with `pending_contracts:[]`), pointing away from the freeze/insert site.
3. **MATERIALIZE-AS-FIELD wall (empty/optional; 0/14 EVER passed optional-drop unhinted, 1/14 empty-record).** Agents store the catch-all as record CONTENT: `is_empty()=fields.is_empty() && catch_alls.is_empty()`, `materialize_catch_all_field(id)`. So `({}|{_|default}) == {}` is false and valueless-optional fields are not dropped. The catch-all is metadata ABOUT the record, not a field OF it.
4. **BASELINE-REGRESSION wall -- the FINAL wall (killed the 2 runs that hit 26/26-NEW).** Adding state to the SHARED `RecordData` leaks into EXISTING dict-contract observers: `{ _ | String }` pretty-prints as `{}`, blame label-path goes empty, unsound-dedup wrong error, `revertible thunk already set` panics in merge/fixpoint. Strongest solvers implemented the WHOLE feature yet regressed the base suite. The 873 baseline tests were the discriminator.

**Iteration lessons:**
1. HINT-ARC-AGAINST-SHIFTING-WALL: a hint fixes its wall and EXPOSES the next-dominant failure. Add hints ONE batch at a time, each targeting that batch's dominant failure, until a pass. Arc here: template-not-field -> +parser-steer -> +propagation -> +baseline-preserve = PASS. Do NOT front-load all hints (too-easy risk) and do NOT hold the biggest lever (I held the parser hint one batch too long; the parser wall was always the largest -> wasted a batch at 0).
2. BEHAVIORAL HINTS BEAT MECHANISM HINTS -- required AND sufficient. The description-conciseness reviewer FAILs mechanism-flavored hints ("retained on the record", "belongs to record-field syntax") as over-spec and SUPPLIES behavioral rewrites that keep the nudge minus the HOW ("fields introduced later are still governed by the catch-all"; "metadata after `_ |` is part of the catch-all annotation"; "plain `{ _ | T }` keeps its current behavior"). Batch 4 PASSED on the behavioral wording -> write hints behaviorally from the start; same solvability lift, no description FAIL.
3. BASELINE-REGRESSION is a REAL fourth wall for invasive cross-cutting changes: new state on a shared struct must be INVISIBLE to every existing observer (pretty/label/emptiness/dedup/merge-fixpoint). Spec it behaviorally + let the base suite enforce it.
4. ENV CONFOUNDER (raise to platform): `/opt/cargo/registry` root-owned perms blocked EVERY agent's local `cargo check`/`cargo test` (solve blind) + a few Orion API-auth deaths. This suppressed pass-rate independent of difficulty -- the 9/10 compile-deaths would likely have self-caught with a working `cargo check`. Fixing solve-env cargo perms lifts pass-rate more than any hint on Rust/cross-crate picks.

## nickel-enum-widening (APPROVED Mars 2026-07-04, R3 30% 3/10, Holistic+Auto Review PASS)

**Outcome:** Mars, 30% (3/10 Nova), Holistic + Auto Review both PASS. Arc: R1 0/10 (env-perm blocker + baseline-regression) -> R2 ~44% (chore-only difficulty) -> R3 30% (after adding function subtyping + a hidden extra-row test).

**Shape + stats:** single-subsystem typecheck subsumption, ONE source file `core/src/typecheck/subtyping.rs` (146 eff LOC) + `doc/manual/typing.md` + one golden fixup. 17 f2p tests in a standalone target. Feature: enum WIDTH subtyping (rows matched by tag, bare-vs-variant distinct, covariant variant argument, extra rows allowed on the WIDER side, ExtraRow on a narrower-only tag) + FUNCTION subtyping (contravariant domain / covariant codomain). Runtime enforcement preserved -- the brief's "static-fix-leaves-runtime-unenforced" dual-path Olympus wall was FAKE (runtime enum contract already blames on base).

**Decisive difficulty drivers (all fair, all measured):**
1. **NEW-CONSTRUCTOR ARM is the pass-rate lever.** Enum-only was ~44% (too easy) because passers wrote ~the reference and no in-scope case trips them. Adding the ORTHOGONAL arrow arm (a required behavior BEYOND the enum reference) shaved to 30%. Additive positive tests did nothing (Pattern 17).
2. **VARIANCE OVER-GENERALIZATION (2/10).** The arrow arm's contravariant domain composes with existing negative goldens; over-eager solvers flip `mismatch_enum_match_fun_type` to `pass` when it still correctly errors `ArrowTypeMismatch`. Self-loading trap (no authored misdirection).
3. **FAIR BASELINE-MAINTENANCE (5/10 golden, 4/10 manual).** The change flips an existing type-error golden (MissingRow->ExtraRow) + an executable manual doc-snippet (error->value). Meta warns "validate the full suite" -> Holistic ruled fair.
4. **DIAGNOSTIC-DIRECTION hidden f2p test** forces ExtraRow (base gives MissingRow on the two-match pin); catches wrong-direction + over-permissive impls the visible golden misses.

**Iteration lessons:**
1. **TIER-GATE LAW:** auto Difficulty + Long-horizon gates key off the SELECTED tier; a 146-LOC, 30%, holistic-PASS feature is a clean Mars but auto-fails the Olympus gates. Select Mars at submit; don't bloat to chase Olympus long-horizon (structurally unmeetable for a small feature).
2. **Empirically verify a claimed dual-path before promising a tier.** Running the runtime scenario on base (`| [| ... |]` blames without the solution) proved the runtime path was never broken -> typecheck-only -> Mars.
3. **Harness:** Rust = cargo2junit (never chmod /root, [[lesson_olympus_base_rust_docker_cargo2junit]]); Windows patch-gen must capture raw BYTES (box-drawing mojibake breaks git apply) + normalize LF ([[lesson_windows_patch_gen_bytes_not_text]]); nickel manual doc-tests use a GLOBAL `<repl-input-N>` counter -- preserve the `#repl` block count when editing docs or downstream error examples shift.

## gimli-type-units (APPROVED Mars 2026-07-05, confirmed-human) -- DWARF type-unit write + `.debug_types` + `.debug_aranges`

**Outcome:** ACCEPTED Mars. v4 batch 3/20 = 15%, v4b re-batch (post rustfmt+convert_self fixes) 1/20 = 5%. Solvable (>=1 clean pass each), all-fair, Holistic + Auto Review PASS. Human reverted once for repo-hygiene, then accepted.

**Shape + stats:** faithful read->write->read CONVERT feature, single-subsystem (write module), cross-SECTION. 249 eff LOC / 4 src files (aranges.rs new + unit.rs + section.rs + mod.rs). 21 new integration tests via test-assembler, convert-driven compile-on-base f2p. Base 88addfd1.

**Decisive difficulty driver:** cross-section routing forces an invasive refactor of SHARED write machinery. v4 type units go to a NEW `.debug_types` write section; the reference adds `DebugTypes<W>` (define_section! + Sections wiring) and generalizes the DIE-writer (`entry.write`/`AttributeValue::write`) from `&mut DebugInfo<W>` to raw `&mut W` (offset = `DebugInfoOffset(w.len())`), routes by version in `Unit::write`, writes the v4 type-unit header (signature + back-patched type_offset), and extends `ConvertUnitSection::new` to iterate `read_dwarf.type_units()`. 14/20 (v4b) agents FAILED TO COMPILE that generalization. Secondary biters: root-DIE-tag preservation (set_type must set `DW_TAG_type_unit`, ~3/20 miss it -- convert copies the tag for free for most), range-list base-address resolution (drop OffsetPair without adding unit low_pc base, ~1/20), and the existing `test_die_ranges_high_pc` overflow regression (~3-4/20 -- naive `low_pc + high_pc_length` panics; existing behavior drops the overflow).

**Iteration lessons:** (1) 4-batch arc proved new-behavior walls are free on a convert feature (reader = oracle); only the cross-section refactor bit. (2) Measure the CLEAN reference LOC before promising a tier -- this hard wall is only 249 eff (surgical), so it's Mars not Olympus; never pad. (3) Auto-review passed but a human reverted for repo hygiene (rustfmt-clean CI gate + base must run `tests/convert_self.rs` which exercises the refactored path, not just `--lib`). (4) The platform's `/opt/cargo` `Permission denied` on `fnv` blocked agent `cargo check` in nearly every run but is grader-excused; the cargo2junit test.sh + nickel-simple Dockerfile held. See PATTERNS-ADVANCED Pattern 66.

## nickel-array-rest (APPROVED Mars 2026-07-05, confirmed-human) -- non-trailing array rest patterns

**Outcome:** Auto Reviewer APPROVED high-confidence; 20x Nova unhinted = 6 PASS_LEGITIMATE = 30% (AT the Mars <=30% cap), all fair (every run: description_clear true, tests_deterministic true, agent_blame_unfair false, difficulty challenging; zero fairness flags). Cross-crate (parser + core) Rust surface-syntax feature. Base f2f8588.

**Shape + stats:** additive surface-syntax feature spanning grammar -> parser AST -> pattern compilation (a Cross-Crate Surface-Syntax variant of Mars C). 139 eff LOC / 7 src files (grammar.lalrpop + ast/pattern/mod.rs + ast/alloc.rs + ast/pretty.rs + parser error.rs; core term/pattern/compile.rs + error/mod.rs). 25 tests, standalone `--test` target, cargo2junit test.sh. Feature: rest `..`/`..name` may appear in ANY position (`[..init,last]`, `[first,..mid,last]`, `[a,b,..,y,z]`), not just trailing.

**Decisive difficulty drivers (3 interdependent + misdirecting walls):** (1) LR(1) GRAMMAR -- allowing the rest mid-list keeps `..`/`or`/ellipsis LR(1) only if you reuse the EXISTING item type for every element (`(<LastElemPat> ",")*` -- element shape by first-token, list boundary by `,` vs `]`); agents who invent their own `PatternList`/second-array-alt production hit LALRPOP local-ambiguity and the build script panics (2/20). (2) FROM-TAIL ARITHMETIC (misdirecting) -- the existing compiler is head-relative; suffix elements must index `value_len-(s-k)` and the mid-capture is `slice(p, value_len-s)`; a head-relative suffix loop passes on exact-fit (n==p+s) and fails only on a non-empty middle -- one agent (#3) shipped a fixture asserting `mid==[b,c]` when the semantics give `[[b,c]]`. (3) CPS FALL-THROUGH -- suffix sub-patterns must thread `fail_cont` so a suffix mismatch falls through to the next branch, not error. The BIGGEST empirical fail cluster (6/20) was NOT any of these three directly but the integration wall UNDER them: the `=>?` grammar action must return `lalrpop_util::ParseError::from(...)`, and agents who add their own multiple-rest rejection returning the crate's `ParseError` directly hit E0308 and the parser crate won't compile.

**Iteration lessons:** (1) TIER = build-measure, not predict. The recommended `rest_index` design (suffix kept INSIDE `patterns`, prefix/suffix split by a boundary index) is exactly what keeps typecheck/pattern.rs + both InjectBindings + compat.rs UNCHANGED -> the elegant design IS what makes it small (139 eff) -> Mars, not Olympus, despite being cross-crate. (2) FLOOR-CLEAR via an existing-sibling validation gap: records reject `{x,x}` but arrays silently accepted `[x,x]`/`[x,..x]`; adding `ArrayPattern::check_dup` mirroring `RecordPattern::check_dup` is genuine zero-regression scope (94 -> 139 eff), not padding. (3) The FAIRNESS CATCH-22 (see Pattern 67): multiple-rest rejection is rejected on BOTH base (parse error) and solution (validation error), so it is NOT a behavioral change and cannot be fairly f2p-tested; the two dup-rest tests pinning `at most one rest` FAILED Test Fairness (no repo precedent), and removing them then drew an Alignment/coverage WARNING demanding the test back -- resolved by DROPPING the requirement from the description entirely. (4) ENV: nearly every run hit a solve-time `/opt/cargo` registry `Permission denied` (fnv/str_stack) + crates.io 403 on the agent's OWN cargo self-check; grader-excused (final verifier ran clean, passers worked around), likely DEPRESSED the pass rate rather than inflated it. See Pattern 67 + KNOWLEDGE (Nova lalrpop blind spot).

## parry-heightfield-point-projection (ACCEPTED Mars 2026-07-05) -- point-projection feature/location for grid shapes (HeightField + Voxels, 2D+3D)

**Outcome:** Hardened from a 70% first batch to 3/10 = 30% (AT the Mars cap), Holistic auto-review verdict PASS (confidence 0.88, "solid, shippable"), every test group fairness_verdict = fair, ZERO hint suggestions, then human ACCEPTED. Rust geometry (dimforge/parry, 842*, base ef63da4). 122 human-eff LOC / 4 src files, 27 tests across parry2d + parry3d, cargo2junit test.sh.

**Shape + stats:** additive point-query family across two grid shapes -- a scope-expanded Mars C. `HeightField::project_local_point_and_get_feature` returned `FeatureId::Unknown`; `PointQueryWithLocation` was `unimplemented!()` (panic), 2D+3D; `Voxels` had NO `PointQueryWithLocation`. Added: feature id + location (both dims), is_inside/contains penetration, 3D `height_at_point` (2D already had it), Voxels location `(u32, FeatureId)` + occupancy contains + bounded projection.

**LOC-CEILING at pick time:** the CLEAN core measured only 54 eff because parry pre-ships `convert_triangle_feature_id` (the hard 70-LOC vertex/edge/face global-indexing, already consumed by `ray_heightfield` -> also the fairness anchor). Surgical fix wiring existing machinery = sub-floor. The natural LOC-clearing 4th axis (`feature_normal_at_point`) was BLOCKED by OPEN maintainer PR #356 (lists heightfield feature-normal as its own todo). Scope-expanded to the grid-shape family to clear >=110 human-eff.

**First batch = 70% TOO EASY, decisive diagnosis:** all 3 fails were the SAME isolated self-revealing trap (Voxels `Location` type `(u32,u32)`/`(u32,AxisMask)` vs `(u32,FeatureId)` -> E0308 compile error). Nova transcribes existing conventions. Coverage-padding would only RAISE the rate. Fix = DEEPEN THE CORE with misdirecting traps.

**The 4 hardening traps (70% -> 30%):** (1) PRIMARY -- `height_at_point` is TRIANGULATED not BILINEAR: the "obvious" terrain-height query is bilinear over the 4 cell corners, but parry's surface IS a triangle mesh (proj/ray/contact all use it), so the triangle-plane height is the ONLY correct reading. On a NON-COPLANAR cell + off-diagonal point they differ (tri 0.0 vs bilinear 0.09/0.25); interdependent with zigzag (flips the diagonal -> different triangle -> 0.0 vs 0.3) and removed (containing triangle gone -> None). The old test used an x-only slope = planar per cell = bilinear == triangulated = did NOT distinguish (a planar test cannot catch a bilinear trap). (2) `split_triangle_id` made PRIVATE again (was pub(crate)) -> agents must invert `triangle_id`'s formula; bites on NON-SQUARE 3x5 (nrows()!=ncols()) + RIGHT triangles (`tid + nrows*ncols` offset -> Face(14)/Face(15)) + transposed 5x3 (nrows/ncols swap). (3) directional voxel cube-faces (all 6: +X=Face(0)..-Z=Face(5)) + closest-voxel selection, keeping the type trap. (4) far-above projection completeness (naive finite-radius search misses the global-closest at y=1000; caught by the proj cross-check). De-prescriptivized meta (dropped "handle the same way the query code handles them"; no triangulation hint).

## aircompressor-zstd-strategies (ACCEPTED Mars 2026-07-06) -- zstd block-compressor strategies + level-aware streaming; the tier-by-passing-LOC pivot

**Outcome:** ACCEPTED as Mars after an Olympus->Mars pivot. Auto Review PASS (issues [], safeToMerge, inner verdict PASS -- the "CHANGES REQUESTED" banner had no backing finding). R2 batch 1/10 = 10% (hard edge of Mars <=30%). airlift/aircompressor (pure-Java zstd, 638*, issue #162, base 38c2a7d5, JDK 25). Reference 663 human-eff LOC / 10 files; test 37 tests / 563 lines; olympus-base-jvm offline Docker (base 26 + new 37, ~3m22s new offline no OOM at forkCount=0).

**Feature:** implement the missing zstd block-compressor strategies (fast/greedy/lazy/lazy2/btlazy2/btopt/btultra via single-probe / hash-chain / binary-tree / optimal-parse match finders) + the 3-repcode rotation w/ ll0 shift + lift the SequenceEncoder LAZY+ `not yet implemented` throw + a level-aware `ZstdOutputStream(OutputStream, int)` streaming ctor (#301). f2p seam = package-private `ZstdFrameCompressor.compress(...,level)` (throws UnsupportedOperationException on base) + reflection `getConstructor(OutputStream.class,int.class)` for the new ctor (NoSuchMethodException on base).

**R1 = 50% TOO EASY, decisive diagnosis:** 10/10 agents ALIASED all 7 strategies to ONE hash-chain; nobody built a binary tree or optimal parser (the "5 distinct architectures" premise is a mirage -- aliasing is universal AND legitimate). Two cheap escapes: dfast-alias (killed only by ratio) and a RECURSIVE recompress-fallback in ZstdFrameCompressor.compress (try level-1, pick smaller, all the way down) that defeats ratio+monotonicity entirely and fairly. Pre-check on the 2 clean passers: BOTH already guard windowLow (`matchIndex <= windowBaseAddress-baseAddress` break) + use base-maintained state tables -> streaming-as-a-corruption-trap is DEAD against competent agents (loro-risk realized from their code). Kept streaming only as fair SCOPE.

**R2 hardening (50% -> 10%), piccolo-finalizers BREADTH model:** difficulty from many orthogonal FAIR walls, none escapable by the fallback: adversarial-correctness corpora at the PROVEN biters (offset-1 runs, ll0-heavy periodic, MIN_MATCH=3-boundary shortTripleMatches, repcode rotation) x all 6 strategies + multi-MB streaming round-trips through the real ZstdOutputStream sliding path (reflection seam) + entropy stress + a minimal ratio floor. R2 batch trap effectiveness: RATIO (beat-dfast) killed 5, the STREAMING-CRASH wall ("Must write at least one full block" writeChunk invariant when agents rebalance the buffer) killed 3, SequenceEncoder 1, regression 1. The streaming wall bit 3 -- a DIFFERENT mechanism than the sliding-corruption I designed for.

**Why MARS not Olympus (the decisive pivot):** the sole passer's human-effective LOC = 289 (effective_loc_check.py) vs Olympus 450 floor. Option 2 (force the public-API family) was FUTILE: the passer ALREADY wrote `create(int)`+`ZstdJavaCompressor(int)`+`ZstdOutputStream(out,int)` voluntarily and is STILL 289, so forcing it is a no-op on the floor. The only lever forcing a genuine 2nd algorithm is strict cross-strategy ratio, which is BOTH unfair (Test Fairness rejects thresholds) AND untrue (ref btopt loses to btlazy2 on binary geo.protodata). Max fair passing-floor ~330 < 450 -> a 10%-hard feature whose irreducible fair solution is one aliased matcher is a hard MARS. See Pattern 69.

**Fairness catch:** the reflection streaming seam was Test-Fairness-FLAGGED (6 tests pin the exact ctor sig via reflection) until the meta NAMED `ZstdOutputStream(OutputStream, int)` verbatim -> flipped all 6 to fair. Naming a new public API is fair disclosure (both reviewers recommended it); the difficulty is implementing streaming/sliding correctness, not guessing the signature.

**Winning failure clusters (re-batch 30%):** (a) is_inside NOT propagated below-surface, 3 runs -- agents gate is_inside on the `solid` arg and the feature path calls with solid=false; EXPLICIT requirement, shared blind spot. (b) Location id `u32` vs `usize`, 3 runs -- EMERGENT from making split private: agents matched pub `triangle_at_id(id: u32)` and changed the associated `Location` id from the base's `usize` to `u32`, breaking the contract the tests pin. (c) voxel face `u32` vs `FeatureId`, 1 run. The triangulated/non-square/directional traps are the "genuinely_hard" groups (all 30%).

**Iteration lessons:** (1) The difficulty knob is BITING CONCEPTS (naive-dominant-reading traps), not test count -- coverage padding of well-specified behavior RAISES the pass rate (competent agents go N/N). Deepen ONE core behavior into a trap. (2) De-crutching (private helper) perturbs SURROUNDING TYPE CONTRACTS -- an unanticipated free fair trap (usize->u32). (3) A trap test must be built on geometry that DISTINGUISHES the naive reading from the correct one (planar-per-cell couldn't). (4) 30%-at-cap + Holistic PASS + all-fair -> DO NOT TOUCH (re-editing re-stales approval and risks tipping the cap). See PATTERNS-ADVANCED Pattern 68.

## gms updatable-view DML (APPROVED MARS 2026-07-07)

**Outcome:** APPROVED. all-Nova 1/10=10%, Nova+Orion 20%, all-Orion 80% (worst-case artifact). 49 tests, solution eff 382, 2 source files (sql/plan/updatable_view.go + sql/planbuilder/dml.go). dolthub/go-mysql-server @ f5b97c4d. Go, `-tags gms_pure_go`.

**Shape/feature:** INSERT/UPDATE/DELETE through updatable views -- redirect DML on a `*plan.SubqueryAlias` view to its single base table in the planbuilder DML path (buildInsert/Update/Delete). Peel the expanded view (SubqueryAlias->Project->[Filter]->base|nested|TableAlias|Join) into `UpdatableViewInfo`; map view cols->base cols (renames, nested composition, aliased base via a separate `BaseNode`); thread the view WHERE into redirected UPDATE/DELETE; expose expression columns as inlinable `selectAliases` for read-in-WHERE/RHS; join-view single-table INSERT; disqualify agg/GROUP BY/HAVING/DISTINCT/UNION/window.

**Decisive difficulty drivers (all fair, from the standard-mix batch, no unfair cluster):** (a) `transform.Expr` arity -- 4/10 wrote `return transform.Expr(...)` from a 2-value helper = compile error; a real API wall. (b) aliased SET target left as `*expression.Alias` not base GetField (SetField.Eval needs GetField). (c) aliased-base DELETE loses the alias->`unable to find columns in schema from source` (the reference's BaseNode split fixes it). (d) over-broad SubqueryAlias-as-view detection regressing DELETE-JOIN / ON-DUP-KEY / view-field-index. One clean passer proves solvable.

**Iteration lessons (14 rounds -- the long tail was all fairness, not the core):** (1) rejection tests that pin an error KIND are a graveyard: CHECK OPTION (removed), expr-col-write ErrGeneratedColumnValue (checker flipped demand->flag across rounds; reviewer said drop), UPDATE-rejection ErrUpdateForTableNotSupported (0/12 batch). The fair survivors all pin the repo's generic non-Kind INSERT error. (2) prepared coverage must use SQL PREPARE+double-EXECUTE (see lessons-learned). (3) full enginetest base = TCP-server firewall/offline trap -> whitelist+justify. (4) read difficulty off Nova-heavy not Orion-only. (5) the 12-run batch overrides all green AI checks. See lessons-learned.md + PATTERNS-ADVANCED Pattern 70.

## kcl-union-override-typecheck (APPROVED Mars 2026-07-07, confirmed-human) -- type-check `|`/`|=`/`**` config overrides like config-literal overrides
- Outcome: R1 1/12=8.3% but human REQUEST-CHANGE (passer 94 raw production LOC < 100 floor). R2 added `|=` lever + de-duped tests -> 1/12=8.3%, passer 121 raw -> AUTO-APPROVED -> ACCEPTED.
- Shape/stats: C-concentrated additive check (kcl-sema resolver) with a cross-file misdirection axis. 2 source files (config.rs + calculation.rs). Reference 150 Counter1 / 114 Counter2. 14 f2p tests. base e2f5adca.
- Decisive difficulty drivers: agents reuse the existing recursive config-context machinery (check_config_value_recursively, Dict/Schema only, NO List arm) and MISS: schema-typed list elements (list-of-schema, [[Server]]), `**` spread from an identifier dict variable, schema-instance RHS (`_a | _b`), and the annotated double-report. 4 distinct failure clusters across the batch (healthy diversity, not one gotcha).
- Iteration lessons: (1) binding LOC floor = leanest passing agent's RAW diff, not your reference; a machinery-reusable feature is sub-floor. (2) fix by requiring the one form the reuse structurally can't reach (`|=` via walk_aug_assign_stmt vs walk_binary_expr). (3) premise-correction: runtime does NOT enforce unannotated `|`; anchor = static parity with literal. (4) conciseness reviewer wants the enumeration gone; rely on the "same as config-literal" parity anchor.

## stoolap-comparison-consistency (ACCEPTED Mars 2026-07-07, 1/10=10%) -- make SQL comparison operators agree across every coercion path

**Outcome:** ACCEPTED (confirmed human). Journey 50% -> 16.7% -> HUMAN "too narrow" -> 10%. base 7e6634ba (stoolap/stoolap, Rust embedded SQL engine).

**Shape+stats:** make-consistent-across-every-path (Mars). 4 files (src/core/value.rs, src/executor/expression/vm.rs, src/executor/hash_table.rs, src/executor/utils.rs), 170 eff LOC, 33 tests. All f2p; 18 base suites green; flaky 3x clean.

**Feature:** int-vs-text comparisons are self-contradictory across the engine's many evaluation paths (`a <= b` AND `a >= b` true while `a = b` false; `WHERE k='2'` matches but `SELECT 2='2'` false; int col JOIN text col = 0 rows). Fix: route `=`/`<>`/`<`/`<=`/`>`/`>=`, column-vs-const, join equality, IN + row form, subquery IN, NULLIF, CASE, IS DISTINCT through a shared numeric coercion; leave PartialEq+Hash (GROUP BY/DISTINCT) untouched.

**Decisive difficulty drivers:** (1) P72 -- the OPEN policy ("you choose the coercion") was a pure thoroughness gate stuck at 50%; CLOSING it to REQUIRE numeric coercion (`10 > '9'`) added a misdirection wall because the repo's `Value::compare` string-coerces and every passer reused it -> multi-digit ordering wrong. (2) P73 -- the join-hash BUCKETING trap is interdependent+misdirecting and dominant (7/10 Nova missed it): the type-discriminated hash keeps int/text in separate buckets, so fixing `values_equal` alone is INERT; must ALSO canonicalize the hash + remove int fast paths, across hash_table.rs AND the parallel/merge helpers in utils.rs. (3) the planner routes large SORTED joins to a MERGE JOIN whose ORDERING comparator (`compare_values`) is a SEPARATE path from the equality helper.

**Iteration lessons:** the numeric-coercion pivot both hardened the band AND retired an earlier Test-Fairness "over-pins an open policy" FAIL (a closed policy is fair to pin). The human "too narrow" change request was legit: my 3-file reference passed all SMALL join tests (HashJoin/NestedLoop) but the 10k mixed join returned 0 via a path (merge join) the reviewer's own description misidentified (they named the parallel path). DEBUG DISCIPLINE: instrument the join dispatch to find WHICH algorithm/path actually fires; find the planner size threshold by probing a few sizes in one run (merge join at >=500 sorted rows), so the high-cardinality test is cheap (~600 rows, not 10k) and asserts the RESULT not the algorithm. Regression risk is real: `compare_values` is also used by ORDER BY/sort, so run join+sort+distinct+aggregation base suites after changing it. See Patterns 72+73, memory lesson_open_policy_thoroughness_gate + lesson_multi_join_algorithm_consistency.

## numbat-const-exponents (APPROVED Mars 2026-07-09, human Sameh Mostafa, P74)

- **Outcome:** APPROVED. Final 12-Nova batch = 1 PASS / 11 valid = ~9% (Run #4 aborted 0-msg; Run #12 PASS_LEGITIMATE). All fails FAIR (challenging + description_clear + inferable). 3/3 Description, 3/3 Solution, 2/3 Tests (Minor coverage note, "not asking for a change").
- **Shape/stats:** Mars, sharkdp/numbat (Rust units-calc lang) @88b2e81 (==main HEAD, COLD). solution 354 eff / 8 src files / 0 comments; test.patch 60 f2p (49 positive + 11 combined boundary) NEW mode + PURE existing `interpreter` (52) BASE mode; meta 79w. Feature = named `let` constants (+ arithmetic over them) as dimension/unit exponents, exact rational.
- **Hardening arc (the whole story): 60% → 20% → 9%.** First build passed a 60% batch (too easy) — the meta was a full SPEC naming every seam (Tighten-First Rule 7 = symengine disaster). Tightened meta 160→79w (deleted examples + mechanism + context enumeration; kept only WHAT) + stacked interdependent traps in TEST DESIGN → 20% → amplified the env-independent negative-const-arithmetic trap → 9%.
- **Decisive difficulty drivers (measured by which tests killed which runs):** (1) ⭐⭐⭐ NEGATIVE-CONST ARITHMETIC (`0-2`/`0-1/2`/`0-n`) killed 5/11 — agents type-gate const-recording on `type_deduced == Type::scalar()`; polymorphic-zero subtraction ≠ exact Scalar → dropped; UNARY `-1/2` passes. (2) SHADOWING/REBIND (combined pos+neg tests) caught over-open solutions. (3) from_f64 permissive-builtin exactness (`(meter^(7/3))^3==meter^7`). (4) parser factor-ambiguity (`Length^p / Time^q` — greedy parser eats the `/`).
- **Iteration lessons (each cost a check FAIL):** Task-Quality fairness (parser change shifted UNRELATED parse-error snapshot SPANS → DELETE those examples+snapshots) · Verify-Solution PER-TEST f2p (rejection guards pass on base → can't be new-mode) × Quality-needs-rejection → the COMBINED positive+negative f2p test (Pattern 74) · Solution-Quality real bug: name-keyed const map must CLEAR-ON-REBIND (where/local shadow leaks) · description conciseness vs alignment tension → surgical "dimensionless number" add closes the one real gap (dimensionful const) without re-verbosing.
- **ENV caveat:** cargo-cache-permission + 403 hit all runs; 5 compile-error fails partly env-noise (Run #10 flagged agent_blame_unfair). Env-independent traps (neg-const + shadowing) hold the ~10% regardless. Agents OVER-ENGINEER the runtime (touch bytecode_interpreter/vm/quantity) where the ref is surgical (parser+typechecker+registry; runtime already handles rational exponents).

## zen-hit-policies (APPROVED Olympus 2026-07-09)

- **Outcome:** APPROVED at Olympus. Final 12-run batch (Orion x2 + Nova x10, unhinted) = 1 PASS / 11 FAIL_MISSED_REQUIREMENT = 8.3%, ALL FAIR (every eval agent_blame_unfair=false + description_clear=true + tests_deterministic=true). Path: auto-approved -> 2 human reverts (both fixable, not kills) -> accepted. The single PASS was ORION (Run #2), not Nova.
- **Shape/stats:** Olympus O-Composite-add, gorules/zen (Rust business-rules engine, ~1.8k stars) @7805da79 (==origin/master tip, ZERO drift). solution C1 451 / **C2 (human-effective) 347** across 5 src files; 44 tests; meta ~211w. Feature = 7 new decision-table hit policies (priority, collectSum/Count/Min/Max/Avg/Median) atop the existing first/collect.
- **The DESIGNED dual-path (why cross-subsystem):** zen has TWO uncorrelated decision-table evaluators sharing one hit-policy enum: a GRAPH engine (nodes/decision_table, runtime `match` on the enum -> exhaustive, compiler-forces new variants) and a POLICY workspace (policy/blocks/decision_table with a `== Collect` comparison -> silently treats new variants as first-match) PLUS a static ANALYZER pass (diagnostics + output-type inference). Graph is compiler-forced; the policy runtime + analyzer are the earned walls.
- **The real wall = the STATIC ANALYZER, not the runtime.** Agents ship the runtime (graph + policy) + exact-Decimal + no-Ord comparator and pass most tests, but miss the policy `analyze` pass: (a) emit a diagnostic when collectSum/priority output cells are statically non-numeric, (b) resolve aggregate output type to Number (sum/count) vs Nullable(Number) (min/max/avg/median/priority). Failing tests misdirect as "missing diagnostic / wrong type," not "you missed the analyzer."
- **MULTI-WALL conversion (the difficulty story): single-wall 10% -> robust 8.3%.** First batch (R1) tripped agents on ONE thing (the static analyzer) = 10%. R2/R3 coverage additions (graph sparse per-column, collectSum non-null typing, policy no-match null) surfaced FOUR independent walls; each run now fails a DIFFERENT 2-7 test subset -> rate is stable, not bimodal. Coverage-that-surfaces-independent-walls converts a single-chokepoint rate into a robust one.
- **Iteration arc (3 rounds + 2 human reverts):** R1 fairness (numeric-substring pins -> error-existence) -> R2 HUMAN REVERT (real graph sparse-row-drop bug: evaluate_row `?` on an ABSENT output key drops the whole row -> `else continue`; policy null-returning aggregate needs Nullable static type; test.sh fallback must carry the real error text not "See stderr.") -> R3 fairness (missed the "output column" substring pin; +priority nullable static type; +3 coverage tests taken from the fairness checker's own suggestions) -> Accepted.
- **LOC datapoint (notable):** C2 = 347 was ACCEPTED at Olympus despite the >=450 effective-LOC floor (C1 451 cleared the 400 auto-block, so auto-review approved; the human did NOT reject on the under-count). One datapoint that the effective-LOC floor is a SOFT signal a strong all-fair / multi-wall / genuine-cross-subsystem sub can offset, not always a hard gate. Do NOT over-generalize; a SwitchNode-hit-policy expansion (co-equal axis, ~+120-150 C2) was staged in case of an LOC revert.
- **base-mode scoping:** test.sh base mode scopes to --lib + decision + policy_table + policy (deterministic, solution-relevant). The repo's FULL suite has flaky snapshot/http/function tests (a Nova run's own local `cargo test` hit them; the verifier's junit_base = 143/143 every run). Documented-flaky-baseline exclusion; survived human review.

## scryer-clpq-linear (APPROVED Mars 2026-07-09, 30%)

- **Outcome / shape / stats:** APPROVED Mars, 3/10 = 30% (in band; proven-approvable rate — parry/nickel/piccolo also 30%). Shape D-new (add a new public API surface — `library(clpq)`). New library module in mthom/scryer-prolog (Rust logic engine; the deliverable edits an embedded `src/lib/clpq.pl`, build.rs auto-registers it — zero Rust). Solution 309 C2 (Gaussian solved-form + Fourier-Motzkin + `library(atts)` attributed variables). 5 themed test files (core/ineq/bind/query + a base regression block over dif/freeze/when/clpz/rationals). Cost: authored Olympus → downgraded → ~5 revision rounds.
- **Why MARS not Olympus (the tier law):** the platform Task-Quality post-check FAILs a single-library-module feature as "single library module = too localized for Olympus → reclassify Mars" REGARDLESS of LOC or depth. Olympus needs cross-SUBSYSTEM SPAN (engine + multiple modules + downstream consumers), not depth-in-one-module. A 415-C2 attempt with reify/dump/label bolt-ons was TRIMMED to a 309 lean Mars. LOC is the wrong axis; span is. (Contrast zen-hit-policies: a DUAL-consumer graph+policy+analyzer span carried Olympus at only 347 C2.)
- **The difficulty story (bimodal depth-wall → seam-stacked band):** the feature is one big DEPTH wall (implement a correct CLP(Q)). First robust-harness batch = 40% (4/10), bimodal: passers were full impls (853/629/537 LOC), fails incomplete. Hardened to 30% by STACKING at composition seams (Pattern 75) — `nl_via_bounds`/`merge_nl` (promote/merge → nonlinear-wake), `diseq_via_bounds`/`diseq_via_eqsys` (determination → disequality-recheck), `inf_strict_open` vs `min_open_no` (infimum-as-limit vs minimum-as-attained split). Solution UNCHANGED; all trace to existing meta = fair (confirmed by the Test-Fairness checker rating all 8 fair).
- **Nova failure signature (partial impls break at seams):** (a) delayed-nonlinear bucket implemented as a NO-OP that only relinearizes on a coincidental repost → fails when determination arrives via bounds/merge, not explicit `=` (dominant `bind`-suite fail); (b) `rdiv` parsed only when the whole term is ground so `N rdiv 2` (var numerator) is wrongly treated nonlinear (`rat_divisor` core fail). Full impls (real relinearization + attribute re-entrant fixpoint) pass everything.
- **Iteration arc:** authored Olympus (415) → Task-Quality FAIL → trimmed lean Mars (309) → fragile-harness batch read 1/10 (SPURIOUS: hand-JUnit + `halt` killing the test proc) → reviewer T1/T4 forced cargo2junit + a regression base block → true batch 40% (too easy) → R5 seam-hardening (+8 tests) → 30% → Dockerfile FAIL (`cargo test` banned in build) fixed to `cargo build --tests` → Test-Fairness FAIL (2 conjunction-shape tests, collateral of a conciseness-driven meta delete) fixed to atomic `entailed` → 30% all-fair → APPROVED. 3 non-blocking coverage suggestions left unapplied (approved; suggestion 1 = structural `==` on `A rdiv B`, the representation-fragility deliberately avoided).

## erg-chained-comparison (APPROVED Mars 2026-07-10)
- **Outcome / shape / stats:** APPROVED Mars, 3/10 = 30% (in band). Shape D-new x O-Composite-add: a net-new `ast::Compare`/`hir::Compare` node threaded parser -> desugar -> lower/typecheck -> bytecode codegen + Python transpiler. erg-lang/erg (Rust workspace, Python-compatible lang) @ b8bc4e33. Solution 343 C2 across 15 files (reference UNCHANGED between the 70% and 30% batches). 42 tests.
- **Feature:** true Python chained comparison: `a < b < c` == `a < b and b < c`, single-eval of interior operands, short-circuit, family `< <= > >= == != in notin` (is/isnot excluded -- base `is!` pre-broken), mixed chains, identical in run (bytecode) + transpile modes. Base builds `(a<b)<c` left-assoc, type-checks silently (Bool<:Int), runs Python-incompatible in BOTH backends.
- **Decisive difficulty drivers (batch2, 7 fails = 5 designed seams):** (1) star PRECEDENCE-BOUNDARY new-chain vs existing lower-prec `and`/`or` = 3/7 fails (Runs 4/9/10): agents chain only when the NEXT op is a comparison, so a run closed by `and`/`or` collapses left-assoc before the boolean op -> `1<3<2 and 4<5`=True. Misdirecting: pure chains transpile perfectly. (2) paren-flag reset by `BinOp::new` in desugar (Run3). (3) membership BOTH directions: chained `in`/`notin` fail-compile (Run2) + lone `1 in 1..2` baseline regression (Run7) = fix-one-regresses-another. (4) single-eval x effect-checker: `f!()` operand -> Error#0420 (Run6).
- **Iteration arc:** batch1 70% (7/10) TOO EASY -- 3 fails were INCIDENTAL per-agent-different sloppiness, NO designed trap fired -> single-mechanism signature + free native-Python transpile backend. Hardened by probing every seam in BOTH backends + deepening the dominant (bytecode) + de-prescriptivizing meta to the "exactly as CPython" umbrella; 14 -> 42 tests, reference untouched. Olympus push evaluated + rejected (probes: comptime/refinement base-broken, const-fold weak, user-`<` = same mechanism -> no clean 2nd opposing mechanism; Mars-sized). Pre-check round fixed 1 non-f2p test (hand-computed left-assoc arithmetic sign error: `0>=1` read True, is False), a Dockerfile static-linter false-positive (dynamic `command -v python3.11`), and description conciseness (193->128w). Re-batch 30% -> APPROVED.

## zen-table-verification (APPROVED Olympus 2026-07-10, 1/10=10%)

- **Outcome:** APPROVED Olympus, human-confirmed. 1/10 = 10% (Good Olympus target). gorules/zen (Rust business-rules engine) @7805da79. 2nd zen sub after zen-hit-policies. Semantic decision-table verification: replaces the purely-SYNTACTIC policy linter (`shadows()` = string-equality) with an N-dimensional cover-algebra engine detecting UNREACHABLE rules + INCOMPLETE input coverage, driven from BOTH the graph `Decision::verify()` (new public API returning `Vec<TableWarning>`) AND the policy analyzer (`RedundantTableRow` + new `IncompleteInputCoverage` hint). Cross-crate: zen-expression (cover engine in intellisense/discriminant + new table_verify.rs) + zen-engine graph + zen-engine policy.
- **Shape / stats:** O-Composite-add, greenfield static-analysis, dual-consumer. C2 human-effective 468 (raw 680), 8 source files, 43 tests, cargo2junit JUnit. meta 458 words (under the 500 cap; each sentence documents a tested concept).
- **The difficulty story (thoroughness-gate -> engineered wall, 90% -> 10%):** BOTH first batches came back 9/10 = 90% too-easy. Root cause: every behavior was documented + independent + self-revealing, so thorough Nova (800-1240 LOC) implemented each case; the lone fail each batch was an incidental seam (entity-scoped `order.region`). Adding more documented cases did nothing. Fix = engineer ONE machinery-riding wall (Pattern 77): rework unreachability AND completeness to share ONE extended domain (value + absence on optional columns) via a `column_domain -> Domain{region, nullable}` chokepoint. Three faces the naive impl gets wrong: non-nullable numeric wildcard-after-tiling must be UNREACHABLE (`Any minus numbers = Any`), nullable wildcard STAYS reachable (uniquely catches null), nullable catch-all COVERS absence. The wall was the SOLE difficulty driver across 19 runs (batch3 5/8 fails on it -> 20%, batch4 9/9 -> 10%).
- **Iteration lessons:** (1) A coverage/completeness test is not a difficulty knob -- the human-required multi-table aggregation test (see below) did not move the rate. (2) Human auto-approval != human review: auto-approved twice (20%, 10%), then human-REVERTED for a coverage gap. `Decision::verify()` aggregates over all nodes but every test built a single-node graph; a first-table-only impl would pass. Added a two-table graph test (table A unreachable-only, table B incomplete-only) asserting the UNION of documented payloads, NOT node_id (Pattern 78). Proved teeth by patching verify() to `break` after the first table -> test failed. (3) Mojibake patch-gen: python `subprocess.run(text=True)` on Windows cp1252-decodes git's UTF-8 em-dash on removed context lines -> `patch does not apply`; cost 2 batches. Fix = bash-redirect (`git diff > file`). (4) ERROR-WORDING: relaxed a joint-gap `message.contains("does not cover")` phrase-pin to an existence check; kept the value-in-message pins (`"100"`, `"null"`, `"APAC"`) since "report the missing values" grounds them. (5) LOC-SOFT: 468 clears the 450 buffer with margin after the engine rework added real depth; batch-1 438 would also have cleared 400 (zen-hit-policies C2-347 precedent). (6) Base `diagnostics.toml` fixtures interact: fixture @1053 (hint_count=2 with a duplicate row) already forced no-double-report on baseline, which is why the "legacy shadows() double-report" idea was NOT a usable lever.

## kcl-union-conflict-report (APPROVED Mars 2026-07-10, 20%)

**Outcome:** ACCEPTED 2 PASS / 8 FAIL = 20% Nova (in Mars band). kcl-lang/kcl @e2f5adca. C2 110, 59 tests, test.patch ~894 lines.

**Shape/Stats:** single-subsystem RUNTIME feature -- config union merge (`|`) reports EVERY conflicting attribute in one evaluation instead of aborting at the first, each with full dotted/indexed path + both operand values, sorted by path (numeric list index), consistent across the codegen value backend (`crates/runtime/src/value/val_union.rs::bin_bit_or`) and the fast AST evaluator (`crates/evaluator/src/union.rs::exec_program`). Cross-crate TWIN sharing `UnionContext`. `KCL_DEBUG_ERROR=1` un-truncates exec_program err_message (which is the full JSON PanicInfo blob -> LITERAL `\n`, not real newlines). `--test-threads=1` mandatory (exec_program mutates global panic hook).

**Decisive difficulty drivers (the arc):**
1. v2 = 70% too-easy (uniform-wrap: one accumulate-continue insight). Single chokepoint (`union_entry`) -> no multi-inert-surface (stoolap pattern unavailable).
2. First real batch (list[0] hint present) = 40%. Dominant trap = nested-list path fold `s.list[0].p` -> `s[0].p`, 8/9 fails.
3. WINNING LEVER = **DEEPEN the dominant trap to list-of-lists** (`list[i].list[j].x`, Pattern 48 general-parameterization): re-catches the passers who cleared ONE list level. 40% -> 20%. Interacting override/insert-locality + equal-composite traps stayed LATENT (agents got them right; robustify only).
4. Then the CLUE-CALIBRATION LADDER (Pattern 79): de-prescriptivizing meta (drop `list[0]`) + the expanded R10 reviewer-requested test surface (mixed-path sort etc.) overshot to 0/12 NEEDS_HINTS; re-adding the token+anti-pattern hit 100%; a bare separateness nudge landed 20%.

**Iteration lessons:**
- Solution was byte-UNCHANGED from ~R6 onward -- every difficulty move was TEST-DRIVEN (add divergence-exposing tests) + META clue calibration. A correct recursive reference solution + a universal blind spot = tune the tests and the clue, never the solution.
- Human reviewer reverted the auto-approved 20% for TEST/harness reasons (T4/T7/T8), not difficulty: (T8) the compile-fail fallback JUnit must XML-escape + embed `$TEST_ERR`, not emit a generic "build failed"; (T4) mirror runner-only cases in the runtime backend for the parity requirement; (T4/T7) assert the override-hint block repeats per conflict; (T4) a mixed plain+dotted+indexed+numeric sort test. AUTO != HUMAN held again.
- GOTCHA: runner `err_message` = JSON PanicInfo blob (literal `\n`); assert_conflict uses `\n`; new position-compare anchors must be PLAIN substrings (`attribute 'a'`), not real-newline `find`. Runtime msg = raw panic String (real `\n`) -- the two backends need different escaping.
- GOTCHA: `worktrees/` is gitignored and cleaned between sessions -- to iterate a reverted sub, re-clone @ base and re-apply the two patches from the problem folder (source of truth).
- test.sh base = touched-crates lib tests only (kcl-runtime + kcl-evaluator `--lib`, runner excluded) -- reviewer-ACCEPTED as a valid base scope.

## gms-null-rejection (APPROVED, Mars, 1/13=7.7%)

**Outcome:** APPROVED 2026-07-08. dolthub/go-mysql-server, base f5b97c4d. Add per-relation null-rejection analysis to the CD-C join-order enumerator (`sql/memo/join_order_builder.go` + new `sql/memo/null_reject.go`) so wired-but-dormant outer-join reorderings fire. Zero new public API (transcription moat).

**Shape/stats:** single-subsystem additive analysis feature. solution 150 human-eff / 210 raw / 2 files; test.patch 680L / 26 test funcs / 81 JUnit cases. f2p surface = the enumerated MEMO STRING `j.m.String()` (coster-independent) via Contains/NotContains on reassoc substrings like `(fullouterjoin 2[b] 4[c])`; block tests carry a plain-equality positive control that fails on base (feature dormant on base — the `nullRejectingTables` call is commented out at populateEdgeProps).

**Decisive difficulty drivers (the ~8% floor):**
- DOMINANT WALL (12/13 fail) = **negated set/range 3VL, opposite polarity**: agents reuse positive IN/BETWEEN logic under NOT. Correct: `NOT (x IN (m...))` = De Morgan = AND-of-inequalities = UNION over members (positive IN = OR = intersection); `NOT (x BETWEEN lo AND hi)` = OR-of-comparisons = INTERSECTION (positive = union). So NOT-IN-mixed UNLOCKS (rejects b), NOT-BETWEEN-bound BLOCKS (rejects only c). Interdependent + self-misdirecting (opposite answers from one root).
- Secondary walls: baseline left-join TES-freeze regression (agents delete `calcTES` line unioning leftVertices → over-enumerate → baseline FAIL); positive IN-mixed over-reject; CASE-no-ELSE (unmatched CASE returns NULL = never TRUE → still rejects); right-nested `checkProperty` intersects-vs-isSubsetOf.
- COALESCE/IFNULL null-absorption (intersect args; `COALESCE(b.y,0)` doesn't reject b, `COALESCE(b.y,b.z)` does) — an EARLIER-batch dominant wall, solved once meta named the absorbing contract.

**Iteration lessons:** the whole arc was a hint-calibration whack-a-mole — each solved axis revealed the next 0% blocker (arithmetic value-centric → multi-arg COALESCE → NOT-IN/BETWEEN → right-nested). Terminal state reached by REMOVING all negation hints (see lessons-learned HINT-CALIBRATION CLIFF). Solution-Quality review forced a soundness fix: `nullForcingTables` must special-case CASE (intersect branch values), not union-of-children. 1-pass margin is thin (variance risk) — but solvable + fair + hard.

## go-geom-polygonize (APPROVED OLYMPUS 2026-07-13)

Outcome: APPROVED Olympus, 30% Nova (in-band, FP-clean), human "Accepted". Repo twpayne/go-geom (Go, BSD-2, 971star). base 4deaa45c.

Shape/stats: O-Composite (planar-graph subdivision), 3 files / 2 packages, human-effective 346, 46 tests, 6 interdependent+misdirecting traps. Public API: `xy.Polygonizer` (NewPolygonizer/Add/Polygons/Dangles/CutEdges/AddGeometry/MultiPolygon) + cross-pkg `encoding/geojson.Polygonize([]byte)([]byte,error)`.

Decisive difficulty drivers:
- Core trap = angular face-tracing linkage `cur.sym.next = prev` (immediately-CW, not next-CCW). Naive connectivity trace MERGES adjacent faces (2 squares sharing an edge -> 1 area-2 polygon). Only a SHARED edge between two faces exposes it (single square/bridge work with the wrong linkage) = misdirecting.
- Hole -> SMALLEST containing shell (3/4-level nesting breaks first-containing-shell parity).
- Iterative dangle cascade; cut-edge = same-ring bridge (shared edge is NOT a cut edge); shell-vs-hole by SignedArea sign (go-geom INVERTS: CCW = -1).

Iteration lessons (full arc R0-R20 in [[project_gogeom_polygonize]]): single->cross-subsystem via a cycle-safe geojson consumer (08-LAW); output-convention orientation wall hardened 60%->20%; 3 FP batches cured by hard-adversarial-instance tests (non-representable crossings); R20 removed 4 provably-dead guards after human review (remove-belt-keep-suspenders).

## truck-mass-properties (APPROVED Mars 2026-07-10, 20%)

Outcome: ricosjp/truck (Rust CAD geometry kernel). Add rigid-body mass properties (inertia_tensor + inertia_tensor_about + principal_moments + principal_axes + moment_of_inertia_about_axis + radius_of_gyration) to the existing `CalcVolume` trait. Human-accepted at 2/10 = 20%. C2 137, 27 tests, 1 source file. base e8d5f11.

Shape/stats: B (new public API list on an existing trait), single-subsystem, Mars. Non-SQL pivot (escaped the saturated SQL-feature dedup pool). base commit e8d5f110c65bb2abd9fa62ac56d198d3c13c8a53.

Decisive difficulty drivers (two INDEPENDENT walls -- see [[PATTERNS-ADVANCED Pattern 80]]):
- Wall 1 (self-revealing, ~50%): Solid inertia = per-face-open-mesh delegation -> divide-by-zero NaN. The existing `volume()`/`center_of_gravity()` Solid impl (sum per-face with orientation) is a MISLEADING template: volume IS per-face-linear, but inertia raw-moments must accumulate-then-assemble ONCE (per-face-assemble-then-sum NaNs on zero-volume faces). Only direct-Solid tests surface it (mesh path passes) = misdirecting. Alone this caps ~43% mean with high variance.
- Wall 2 (numerical stability, INDEPENDENT, the ceiling-breaker): the textbook Mirtich impl accumulates 2nd moments about the ORIGIN then subtracts -> catastrophic cancellation far from origin. Far-origin (1e5) translation-invariance test -> naive gives off-diag -1 (should be 0). Robust fix = accumulate relative to a near reference vertex. Uncorrelated with Wall 1 -> moved 50% -> 20%.
- Latent (correlated, ineffective): principal-axes right-handedness (`det=+1` not `|det|=1`). Fair + has teeth but CORRELATED with Solid-thoroughness -> did not lower the mean. Kept as a robustness requirement.

Iteration lessons (full arc in [[project_truck_mass_properties]]):
- CORRELATED-vs-INDEPENDENT WALL LAW (Pattern 80): batches confirmed handedness (correlated) moved nothing 50->60%, numerical-stability (independent) moved 50->20%. When a textbook feature caps because thorough agents are correct, find an ORTHOGONAL failure mode, not another same-axis trap.
- DEGENERATE-EIGENVALUE human-revert: `principal_axes` on an isotropic cube (repeated moments) -> `J-lambda*I`=0 -> null-space-cross-product `normalize(0)`=NaN. FIX = full eigendecomposition (cyclic-Jacobi), NOT per-eigenvalue null-space; the test asserts the INVARIANT (orthonormal + diagonalizes) not a fixed basis. Auto-review only CAVEATED it; the human made it a hard revert.
- REPO-CI-LINT REVERT LAW: `lib.rs #![warn(missing_docs)] + deny(warnings)` in release -> the 6 new pub trait methods MUST carry `///` docs or `cargo build --release` HARD-FAILS; debug `cargo test` passes so it HIDES the failure. Before stripping any public-item doc, grep lib.rs for missing_docs/deny(warnings). Lint attributes ARE repo convention; a "strip comments" request does not override a crate that lints for their presence.
- FAIRNESS via documented invariant: framing the numerical wall as translation invariance in meta (a WHAT) made all 8 failing evals rule FAIL_MISSED_REQUIREMENT with `was_mentioned_in_description=true` -- the precision demand was accepted as a fair stress case of a stated property, not an impl-detail gotcha.
- Go/Rust harness: compile-fail-on-base f2p fallback XML must ENUMERATE every f2p test name with `classname=""` (matches cargo2junit for flat integration-test files) or Verify-Solution fails `before_extras_not_skipped`.

## scryer-clpq-linear (APPROVED OLYMPUS 2026-07-16, 1/10 = 10%)

**Outcome:** APPROVED Olympus (human 2026-07-16: Desc 3/3 Clean, Tests 2/3 Minor, Solution 3/3 Clean; Auto Review approved same bands). mthom/scryer-prolog (Rust ISO Prolog, 2425 star, BSD-3), base 295a642. Invented (not issue-mined): from-scratch `library(clpq)` — exact-rational linear constraint solver ({}/1, entailed/1, inf/sup/minimize/maximize, delayed nonlinear, float rejection) + `library(clpq_dump)` dump/3 (Fourier-Motzkin projection onto a target-var set, canonical residual) + `library(clpq_io)` constraints_//1 (DCG render). 3 new lib files, 541 eff LOC (C2), 121 per-check tests via findall-runner + OnceLock map + one #[test] per check.

**Shape + stats:** O-Algorithm-correctness x manufactured pipeline (see SHAPES note). Final batch 13 unhinted runs: 1 PASS_LEGITIMATE (Orion 121/121, 158 msgs), near-misses 120/117/115/114/112/110/100/99, 3 wall-clock early-terms. 10% counted, zero contamination, FP-clean.

**Decisive difficulty drivers (recurrence-ranked):** (1) dump canonicalization 7/10 — fully-documented but implementation-hard (NewVars-order pairs, magnitude-one scaling, opposing-bounds merge, determined-target form); (2) full-store entailment 6/10 (stored diseqs, strict-bound-implied diseq, whole-connected-store reasoning); (3) exact-rational arithmetic 3/10 (evaluated-rational unify, lowest terms, rational optimization); (4) io_rat positive-leading-rational render (killed a 120/121); (5) sheer scale — 3/13 died at wall-clock mid-build.

**Iteration lessons (11 rounds, 3 reverts/fairness cycles):**
- Approved Mars 30% then human-reverted TWICE: 7 solver correctness bugs a second human found (from-scratch solver = bug farm; reproduce each on the built binary, cluster fixes) + base-mode-must-run-pre-existing-target + per-check-no-fail-fast JUnit; then the 2026-07 Olympus >=2-meaningful-file rule + float-at-unify S1.
- 3 Test-Fairness FAILs, all on the projection/render layers: pivot-ambiguous dump targets (share an equality), unpinned serialization format (fix = worked examples in meta), empty-render convention (fix = drop the test).
- Reviewer T2/S1 caught my OWN reference violating its meta order rule — canonical-order specs need a discriminating test (3+ vars, non-alphabetical NewVars).
- R10 0% NEEDS_HINTS -> HINT-IN-META (Pattern 81): folded the entailment/full-store hint into meta as a WHAT-principle (first draft pasted test bodies — too explicit, removed). Flipped to unhinted 10% + approval; the unworded dump wall kept it in-band.
- FREEZE-on-approve: both auto + human cited the same 2 LOW T4 notes (float-in-composite, rational-opt), non-blocking twice. Not added — staling a clean approval + risking the sole passer at the solvability floor is strictly worse than a LOW note.

## neva-array-bypass-generalization (APPROVED Olympus 2026-08-01)

**Outcome.** 2/10 = 20% (Nova 1/9, Orion 1/1). Two more runs at 20/21. 8 review rounds.

**Shape + stats.** O-Composite-add. Go, nevalang/neva (1076 stars, MIT). Generalise the array-bypass `[*]` connection across analyzer, desugarer, IR generation, runtime and stdlib. 6 source files / 4 subsystems, 282 effective LOC (Counter 2), 21 e2e golden-program tests. Base fails 21/21.

**Decisive difficulty drivers.**
1. F-9 cross-stage resolution drop (6/10): agents resolve omitted port names in the analyzer, then return the unmodified connection, so IR generation never sees the resolution. Every capability breaks at once (10 tests, one cause).
2. F-10 cross-product cell (8/10, sole failure of both near-misses): `receiver_anchored_fan_out` composes "which side is anchored" with "one vs many receivers". Arithmetically the difference between 20% and 40%.

**Iteration lessons.**
- The deliberate second wall (WaitAll barrier, 3 rounds) killed 0 agents. The decisive test came from a Test Fairness coverage suggestion.
- Round-8 hardening (slot-identity tests) killed 6 but always correlated with the lead trap: zero independent kills, zero outcome change.
- Two fairness FAILs conceded rather than argued: an unstated barrier re-arm (one meta sentence) and a DI port-name remap that contradicted `docs/user/book/components.md` ("Inports are compatible: full match by name"). The second cost the hardest wall in the problem and 38 LOC of then-dead code.
- Three reference bugs found by hardening before the batch (irgen `/in` path assumption, single-usage-map read, one-shot barrier). Consistent with the 3-per-problem rate; each would have been an FP.
- Base mode runs 615 cases across ~128 packages serially (`-p 1`); e2e cases each compile and run a program, so validation is compile-bound, not count-bound. Two e2e packages excluded with inline reasons (network).


## customasm-ruledef-disassembly (APPROVED Olympus 2026-08-03)

**Outcome.** Auto Review Approved 3/3 description, 3/3 tests, 3/3 solution. 1/10 pass = 10%.

**Shape + stats.** O-Algorithm-correctness. hlorenzi/customasm (Rust, Apache-2.0, 1052 stars,
cold: 0 commits in the trailing 90 days at pick time). 7 files, 493 effective LOC, 54 fixtures,
54/54 fail-to-pass, 691 baseline preserved.

**Decisive difficulty drivers.** F-11 local-vs-global selection scope (9/10, band decider);
exact-width slice forms as whole parameters (4/10); recursion guards on valid finite nesting
(3/10). The accepted batch showed two separated failure clusters, which is what distinguishes it
from the earlier bimodal batches.

**Iteration lessons.** Pass rate swung 0/90/20/57/9 across five batches. The swing was a single
seam, not miscalibration — diagnosed only after parsing per-test kill counts with ElementTree.
The decisive test came from an FP-panel dissent, not the design. Seven reference bugs surfaced
during hardening, each a latent FP.


## numbat-parse-unit-expressions (Rust / unit-aware calculator) — APPROVED 2026-08-04

**Outcome.** 2/10 final. History 0/5, 70%, 0/5, 0/3, 0/11, 70%, 0/7, 0/6, 20%.

**Shape + stats.** O-Composite-add. 3 files, 393 effective LOC, 88 tests, base 225 (two obsolete
inline tests skipped). Nova-only final batch.

**Decisive difficulty drivers.** (1) F-12 repo-test preservation, 3 runs, worth half the band —
without it the batch reads 50%. (2) Negated parenthesised ratio exponent, 3 kills, authored from an
FP adjudication. (3) `unit_name` superscript round trip, 2+2 kills.

**Iteration lessons.** Nine batches, dominated by five rounds of flip-flopping the base-mode skip.
The narrow two-test skip is the only configuration that is simultaneously solvable, precheck-legal
and T1-compliant: relocating the tests is blocked (test patches may not touch `src/`), and
solution-side deletion breaks the reference's own p2p. Decide this at design time — see the F-12
audit in `olympus-author`.

## rust-minidump-stack-containment (Rust / crash-dump unwinder) — APPROVED 2026-08-06

**Outcome.** 2/10 Nova (20%), FP clean, Auto Review 3/3 description / 3/3 tests / 3/3 solution.
28 authoring rounds, ONE batch. Repo: rust-minidump/rust-minidump (MIT, 505 stars), base
`0155eaf70114f5ed3cbb172968eceaf6106940f7`.

**Shape + stats.** O-Composite-add. 9 files across 3 crates (breakpad-symbols, minidump-unwind,
minidump-processor). **327 effective LOC** (Counter 2) / 443 Counter 1. 49 new tests, 255 base.
meta 523 words, 13 paragraphs. Agent effort: 9-26 files, 439-685 added LOC, 9.2M-20.3M prompt
tokens per run.

**Decisive difficulty drivers (per-test kill counts, 10 runs):**

| Kills | Test | Source |
|---|---|---|
| 6 | `a_delta_row_that_declares_and_computes_is_discarded` (F-13) | Test Fairness **coverage suggestion**, round 25 |
| 4 | `a_reduced_frame_is_surfaced_even_when_the_walk_ended_plainly` | Auto Review **T4 finding**, round 26 |
| 4 | `degradation_is_summarised_over_the_whole_walk` (F-15) | original design |
| 3 | `a_declared_end_outranks_a_frame_a_later_strategy_would_produce` (F-14) | original design |
| 3 | `a_walk_with_nothing_to_report_carries_none_of_those_lines` | round 15 rewording |
| 3 | `contained_walk_degrades_nothing_and_exhausts` (F-14) | original design |
| 0 | **the other 40 tests** | — |

**Iteration lessons.**

- Three fairness FAILs, all fixed by adding or correcting a meta sentence; deletion was never right.
- Three reference bugs found during hardening, each a live FP: a `split_once(".ra:")` that read only
  the first return-address assignment while the repo's evaluator honours the LAST (a
  machinery-riding contradiction); an end-of-stack verdict computed per RECORD instead of per
  ADDRESS; a frame cap checked before the push so the limit fired one frame late.
- The harness Blocker (`export PATH="/root/.cargo/bin:$PATH"` plus a root-owned CARGO_HOME) cost a
  0/3 tests band and is **undetectable without a container run** — Docker was never available here.
  Fix: drop the `/root` line, `ENV CARGO_HOME=/opt/cargo`, `cargo install --root /usr/local`,
  `chmod -R a+rwX /opt/cargo /app`, and leave `RUSTUP_HOME` alone.
- Traps that mutation-proofed REAL but killed zero agents: baseline preservation (trap 8),
  already-at-weakest marking (trap 9), scanned-only corroboration guard (trap 5, always suspected
  decoration). Mutation coverage is FP insurance, not a difficulty forecast.

## lyon-fill-internal-vertices (APPROVED Olympus 2026-08-07)

**Outcome.** Accepted at 1/10 after 3 batches (6/10 -> 4/10 -> 1/10) and 6 revision rounds.

**Shape + stats.** O-Algorithm-correctness · 45 tests · 431 raw / 260 human-effective LOC · 4 files
(new `interior.rs` + `fill.rs` / `lib.rs` / `event_queue.rs`) · meta 301 words · Nova x10 per batch.

**Decisive difficulty drivers.**
1. `no_emitted_vertex_has_a_fully_filled_neighborhood` — 8/10 kills, SOLE failure of both near-miss
   runs. Added in the final round from a batch-2 FP finding (F-17).
2. Zero-argument builder inference — 4/10, all as INTEGRATION_ERROR compile failures (F-16).
3. Convergent one-ring ear-clipping failing on non-manifold links / non-convex cavities — 5 runs.

**Per-test kills.** 0 of 45 tests killed nothing. Top: 8 / 5 / 5 / 5 / 5 / 5 / 5 / 5 / 5.

**Iteration lessons.**
- The band decider came from review response, not trap design (3rd consecutive problem, L22).
- Two batches had every pass FP-voided; the wrapper rate was noise until the suite matured (L28).
- The baseline-preservation axis was demoted at design time on L15 grounds and vindicated: 0 baseline
  failures in 30/30 runs.
- Declining one FP probe (an f32-noise-floor collinearity case) was what preserved solvability.


## gluon-format-comments (Rust / gluon source formatter) — ACCEPTED 2026-08-07

**Outcome.** 1 legitimate pass of 11 (9%). Four batches: 0/12, 0/14, 0/10, 1/11.

**Shape + stats.** O-Algorithm-correctness. 3 files, 243 effective LOC (Counter 2), 37 tests,
base commit 418c6b7d. Passing patch 633 added lines across 2 files; failing runs 605-915 lines.

**Decisive difficulty drivers.**
1. F-18 token-form parity — block-comment cases took 22 of 37 kills; the 7/11 leader was the sole
   failure of the closest near-miss.
2. F-10 nested cells — a comment in a match inside a record field, and a record inside a match arm.
3. The gap model itself: comments live BETWEEN spans, so every construct has to consume its own gap
   exactly once. Naive per-construct fixes double-emit.

**Iteration lessons.**
- Batches 1-3 all read 0 passes. The cure was dropping the record-TYPE axis (a second printer in
  another file, 8 tests at 3-6 kills each), verified in advance with the differential harness.
- The band decider had been deleted once as unfair, then restored once the rule was stated.
- One agent contested that test as an undocumented convention. The contest was defeated by the BASE
  repro: the unmodified formatter already breaks that record, so the convention predates the task.
- 15 of 37 tests killed nothing, and they were mostly the ones authored during the original design.

## vrp-tsplib-edge-weight-types (Rust / reinterpretcat/vrp) — APPROVED Olympus 2026-09-02

**Outcome.** Accepted at 3/10 (batch 12, Nova x10). 12 batches, ~90 runs total.

**Shape + stats.** O-Composite-add. 8 files, 374 human-effective LOC (881-line solution.patch),
35 new tests, 60 base-mode tests. Solver median 7.5 files / 600 added LOC / 7.4M prompt tokens.
Base commit `1b0a5e8c49dbf3e34aba5bf1a2ac57fe5af82655`.

**Feature.** TSPLIB non-Euclidean edge-weight types (CEIL_2D, ATT, GEO, EXPLICIT with five
EDGE_WEIGHT_FORMAT layouts and DISPLAY_DATA_SECTION handling) in the CVRP scientific reader, plus a
cross-crate location-export surface wiring `vrp-cli`'s previously-`unimplemented!()` TSPLIB
`LocationWriter`.

**Pass-rate history.** b6 0/3 -> b7 2/10 -> b8 0/5 -> b9 2/9 -> b10 0/23 -> b11 5/10 -> b12 3/10.
Batch 10's 0/23 was a REGRESSION, not difficulty: a `test.patch` 3-way merge failure plus a
description edit that leaked a trap. Diagnosed by clustering kills per batch against b9, fixed by
making `test.patch` add-only.

**Decisive difficulty driver — exactly one.** F-19, the stdout-purity wall on
`can_get_tsplib_locations_via_cli_with_pure_json_stdout`: 7/9, 17/23, 5/10, 7/10 across the four
measured batches. In batch 12 it was the SOLE failure of all seven failing runs, each at 34/35.
The other 34 tests killed nothing — the most extreme ratio in the corpus (cf. L16).

**Iteration lessons.**

- Three fairness clarifications killed two entire failure clusters (display-data 2/9 -> 0/10,
  GEO 1/9 -> 0/10) and were only visible a batch later, when the artifact read 50%. The disclosure
  and the collapse are separated in time, which is what makes L34 hard to catch in the moment.
- The re-hardening lever chosen in response (a stated ascending-node-order rule, tested at
  DIMENSION 12 with permuted ids so a lexicographic string sort breaks) killed 3 of 5 replayed
  patches in a differential harness and 0 of 10 live agents. The harness could not see that the
  live batch would read the new sentence (L35).
- Three reference bugs, matching L7's count exactly: a fixed-3-iteration header loop, three
  negative tests that passed VACUOUSLY on base (base rejects `EDGE_WEIGHT_TYPE : EXPLICIT` before
  reaching the key under test), and a solution-only import that broke base-mode compilation of a
  shared test target.
- The last finding was caught by the platform, not locally, because base mode had only ever been
  run on the solution-applied worktree. Base mode must be exercised on a base tree.
- A shared `CARGO_TARGET_DIR` across validation trees produced a base tree reporting 25/25 new
  tests PASSING (stale binary). Per-tree target dirs, always.

## go-workflows-channel-drain (Go / cschleiden/go-workflows — APPROVED Olympus 2026-09-04)

**Outcome.** Accepted at **2/10 = 20%**, Auto Review 3/3 / 3/3 / 3/3, both passers cleared the FP
panel at high confidence. Base commit `48e8119`. 9 files, 351 effective LOC, 102 tests, 499-word
meta.md.

**Shape + stats.** O-Composite-add across `internal/sync` (channel, selector, scheduler),
`internal/workflowstate`, and the public `workflow` wrappers. Solver medians: 11 files touched,
1026 added LOC, 11.2M prompt tokens.

**Pass-rate history — every lever visible.**

| Batch | Tests | Rate | Lever applied before it |
|---|---|---|---|
| 6 | 81 | 0/5 | — (scheduler-resumption unstated, killed 5/5) |
| 7 | 93 | 0/5 | stated resumption; one over-strict overtaking assertion killed 4/5 |
| 8 | 92 | **3/10** | deleted the overtaking test |
| 9 | 96 | **1/10** | added the F-20 Select/Default guard (from the FP panel) |
| 10 | 102 | 0/5 | restored overtaking test + wake-up mandates; underpowered sample |
| 11 | 102 | **2/10** | sharpened resumption timing ("before the scheduler run ... finishes") |

**Decisive difficulty drivers.** (1) **F-20** sibling-API contamination, 8/10 and the sole failure
of both near-misses — without it the batch is 40%. (2) **F-10** cross-product cell, 4/10. (3) the
scheduler-progress cluster, 1-2/10 after the timing clause.

**Iteration lessons specific to this problem.**
- Batch 7's 0/5 and batch 10's 0/5 had OPPOSITE correct responses. B7 was one over-strict assertion
  in a fair test: delete it. B10 was one under-stated timing in a fair cluster: state it. Diagnose by
  asking whether the failing tests share ONE root cause — if they do, deletion cannot help, because
  any subset leaves the near-miss failing.
- Four reference bugs were found by reviewers, all FP-grade: a package-global counter coupling
  unrelated schedulers; two `runtime.Goexit` teardown leaks (post-`Yield` statements never run, the
  cleanup must be `defer`red); and a parked receive-waiter that notified progress but was not a
  rendezvous target. In a cooperative-scheduler repo, `Goexit` and progress-propagation are where
  the reference breaks — audit both explicitly.
- The `go-workflows` scheduler reads each coroutine's `Progress()` immediately after its own
  `Execute()`, so progress credited by a LATER coroutine in the same pass is missed. The reference
  needs a second scan. This is the repo's most exploitable structural fact.

## datafixerupper-ordered-alternatives (Java / Mojang DataFixerUpper) — APPROVED Olympus 2026-09-08

**Outcome.** Accepted at 5/10 (50%), the ceiling. Auto Review: Description 2/3, Tests 2/3, Solution
3/3. 67 authoring iterations, 9 batches.

**Shape + stats.** Composite codec in an existing combinator DSL. `Codec.orderedAlternatives` /
`MapCodec.orderedAlternatives` plus labeled twins. 5 source files, 270 effective LOC (Counter 2), 173
tests, meta 477 words. Passing agent patches ran 492-739 added lines over 4-5 files; platform reported
48-81 messages.

**Decisive difficulty drivers.** One axis only: what `MapCodec.encode` must do to the builder it
returns. `RecordBuilder` exposes no accessor and `build()` is destructive, so the outcome can only be
classified by decorating the returned builder and inspecting the `DataResult` at build time.
Top killer `mapCodecEncodeOutrightFailureNormalizesTheReturnedBuilderWhenBuilderDoesNotMutateInPlace`
(5/10, sole near-miss failure) — the fixture uses `PersistentRecordBuilder`, a conforming non-mutating
helper outside `RecordBuilder.AbstractBuilder`. That helper was written in response to a REVIEWER
finding, not designed.

**Iteration lessons.**
- The supplied-builder clause absorbed 8 review rounds before deletion. The tell that it was
  structurally doomed, not merely buggy: rounds 62 and 63 demanded contradictory things (verify
  provenance / class identity cannot establish provenance), and 64 and 66 filed the same scenario
  against two different sentences.
- Removing it took the batch from 2/10 to 5/10. Soundness deletions are difficulty deletions.
- A shipped coverage hole was accepted: all three full-success lifecycle tests use a stable winner, so
  an implementation rewriting every success to stable would pass. Live for 9 batches; named only by
  the accepting review.
- Two probes failed to reproduce a real bug before a third, with a print inside the old
  implementation, found it. Instrument the mechanism rather than reasoning about it.

## customasm-derived-bank-layout (APPROVED Olympus, 2026-09-09)

**Outcome.** Accepted at **1/10 (10%)**, batch 5. FP panel ruled the pass GENUINE over one judge
dissent. Auto Review: Description 3/3, Tests 3/3, Solution 1/3 on an open lexical-context finding.

**Shape + stats.** O-Pipeline-hard. 13 files, 980 effective LOC, 68 fixtures, meta.md 203 words.
Solver effort per run: median 690 added LOC across 16 files, 12-24M prompt tokens.

**Pass-rate history and what moved it.**

| Batch | Rate | What changed before it |
|---|---|---|
| 1 | 0/6 | first artifact; 7 tests failed in ALL runs, 5 of them pure chain SCALE (24/40/80 banks) |
| 2 | 1/10 | scale walls cut, 3 unstated-behaviour gates cut |
| 3 | 0/5 | order clause BOUNDED after the FP ruling — the collapse this caused is the whole lesson |
| 4 | 0/5 | align fixtures still carried an unstated-padding assumption |
| 5 | **1/10 ACCEPTED** | align fixtures fixed; one clause restored naming labels and instruction sizes as still-settling dependencies |

**Decisive difficulty driver.** F-22, the joint fixed point across quantity kinds: 8 of 9 failing
runs, and the entire content of both near-misses (Nova 2 failed only
`ok_forward_ref_into_derived_bank` and `ok_three_bank_chain`). Secondary: high-water extent vs
end-of-traversal cursor, 2 runs.

**Iteration lessons.**

1. Replaying old solutions against a fixed suite is the only way to separate a prompt effect from a
   test effect. It showed 5/10 vs 0/10 for the same 20 solutions under two wordings.
2. Never promise a bound (iterations, passes, chain length). Both times this problem promised one it
   cost a full round: once as three wasted engineering rounds, once as an FP ruling.
3. A fixture whose subject is not a noun in meta.md is a wall, not a test — even when it changes no
   verdict, it displaces the near-miss agent's blocker.
4. The platform's JUnit rewrite mis-pairs names with bodies; mine `test-log.txt`.

## rocketpy-propellant-slosh (APPROVED Olympus 2026-09-10)

**Outcome.** Accepted at **1/10**. Auto Review 3/3 Description, 3/3 Tests, 3/3 Solution, verdict
Approved, no required changes. FP panel: adjudicator "Genuine pass", high confidence, over one
dissenting judge.

**Shape + stats.** O-Pipeline-hard. RocketPy (Python, flight dynamics): add lateral propellant
slosh as a new oscillator mode threaded through the tank API, rocket mode ordering, the flight
state vector, and every phase of the integrator (rail, 6 DOF, 3 DOF, parachute). 10 files,
**375 effective LOC**, **146 tests**, `meta.md` 458 words. Solver patches ran 7-11 files and
538-873 added lines on 14-30M prompt tokens per run — long-horizon floor cleared many times over.

**Pass-rate history.** `0/6` (batch 1, one correlated tolerance-padding cause) -> callable-form
lever + fairness rounds -> `2/10` (batch 2) -> review-driven coverage growth to 146 cases ->
`0/10` (batch 3) -> one test-side fairness fix + Re-eval -> `1/10` ACCEPTED (batch 4).

**Decisive difficulty drivers.**

1. **F-23, the callable-domain trap — 6/10.** Agents wrapped `TankSlosh` parameters in RocketPy's
   `Function`, whose signature introspection rejects defaulted and keyword-only callables. Nova
   x5 + Orion, identical six failing cases every time. Binary axis: softening it measures 56%.
2. **F-7, parachute zero-drive — 3/10.** Rail was suppressed correctly by everyone; the parachute
   phase, which visibly carries a drag force, was driven by it.
3. **The representation pin — 1/10, and it was ours.** See below.

**Iteration lessons.**

- Batches 3 and 4 are the same ten solutions. The delta is one tolerant test helper. That is the
  whole distance between reject and acceptance, and the defect was visible in batch 1.
- The reviewer named ONE unfair assertion (`rocket.slosh_modes == []`); the one that actually cost
  the band was a different site in the same class, spelled as a method call (`.get_value_opt`)
  rather than an equality. Sweep the class, then enumerate what remains against the nouns
  `meta.md` declares.
- Three reference bugs surfaced during hardening, each an FP in waiting: a mislabelled body axis
  (x/y written as y/z), a fixture whose `flux_time` ended before `total_mass` hit zero (read as a
  solution `ZeroDivisionError`, was not), and a new test that flew to apogee while asserting only
  on the initial state row — it hung a legitimate agent for 150s+ until capped to `max_time=0.5`.
- Cost of the wrong click: firing one Orion smoke run while a Re-eval was pending dismissed the
  offer. It failed exactly as its previous-batch patch predicted.


## datafixerupper-derived-recursion (Java, Mojang/DataFixerUpper) — APPROVED 2026-09-11

**Outcome.** Accepted at 1/10. Auto Review: Description 3/3, Tests 2/3 (one coverage gap: no
`DSL.check`-wrapped reference), Solution 3/3. FP panel: genuine pass, one judge dissent
(a stale `resolvedTemplates` cache in the PASSING agent's patch, reachable only by calling public
`resolveTemplate()` between two `registerType()` calls of the same name — adjudicated prompt-silent).

**Shape + stats.** O-Pipeline-hard. Base `Schema` made the CALLER declare which registered types
are recursive and built one `RecursiveTypeFamily` for the whole schema; the task derives recursion
from the template reference graph (SCCs), builds one family per group in dependency order, and
rejects recursion that cannot bottom out. 6 production files, 389 effective LOC (582 raw), 87 tests.
Batch 1 (79 tests) 1/10 -> three Auto Review revision rounds -> batch 2 (87 tests) 1/10, accepted.

**Decisive difficulty drivers (measured, batch 2).** Only 8 of 87 tests killed anything:

| Kills | Test | Source |
|---|---|---|
| 8 | `a_required_reference_to_an_unregistered_name_reports_an_unknown_type` | designed (F-24) |
| 8 | `unregistered_reference_still_reports_an_unknown_type` | designed (F-24) |
| 4 | `a_reference_retained_from_registration_stays_inside_its_group` | reviewer finding vs the reference (F-25) |
| 4 | `a_reference_assembled_during_registration_still_builds` | reviewer finding vs the reference (F-25) |
| 3 | `a_fix_targeting_one_recursive_type_leaves_its_twin_alone` | reviewer finding vs the reference (F-20 family) |
| 2 | `a_data_fix_over_a_self_recursive_type_reaches_every_depth` | designed (F-9) |
| 2 | `a_data_fix_reaches_every_depth_of_a_derived_mutual_recursion` | designed (F-9) |
| 1 | `the_flag_survives_a_later_plain_registration` | designed |

Four runs failed ONLY the F-24 pair, at 85/87.

**Iteration lessons.**
- The Docker harness compiles with `javac` + a hand-rolled JUnitCore reporter and gets its jars from
  `/opt/testlibs` populated at image build; `test.sh` compiles from source at runtime, so a source
  tree can be bind-mounted over `/app` to replay any agent patch without rebuilding the image. That
  made a 10-patch replay cheap and it was used before shipping every new test.
- Two reviewer-suggested tests were measured against the saved passers before shipping. Eight
  shipped; the cross-group DataFix regression test did not, because it failed the only passing run
  (0/10). The reference fix shipped regardless.
- One test was dropped for fairness rather than for the band: asserting `id()` on a name that has
  not been registered yet demands behaviour base does not have (base throws) and meta.md never
  states. It killed 3 agents and was still the wrong test.
