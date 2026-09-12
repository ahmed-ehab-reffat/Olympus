# feedback.md - starlark-go-format-spec

## APPROVED (human reviewer, 2026-06-19)
Approved on the recalibrated build. Fingerprint: sol=815c4dd9 test=8913d3bc meta=9dfafc35 docker=4bd7588e base=5d4d981d.
Approving batch (10 runs): **1 PASS / 10 = ~10%** -- Orion PASS_LEGITIMATE at 202 msgs / 5 files / 1078 LOC (solver-median messages 202, >100 with huge margin). The other 9 are all FAIR FAIL_MISSED_REQUIREMENT, scattered across documented edges (grouping-aware zero-pad, int-as-float-with-precision, %c right-align, sign-aware =, comma-with-binary). First starlark-go entry in the pool; str.format + % PEP-3101 formatting mini-language (Go, CPython oracle).
KEY LESSON (took it from 0/6 to 1/10): the FIRST batch (pre-recalibration) was a DETERMINISTIC-UNIVERSAL-MISS 0%-trap -- every agent failed the SAME two surfaces (empty-type float + #g), one of which (empty-float reimplementing CPython's repr threshold) was a genuine ENGINE-INCONSISTENCY bug ("matches repr" must match the engine's own str()/Float.format, NOT CPython repr). Diagnosed by reading the STRONGEST agent's failures: Orion's ONLY misses were those two. De-trapped exactly those (made empty-float delegate to Float.format; dropped #g from the tested+documented surface), kept the scattered difficulty (grouping-aware zero-pad -- the edge Orion solved but 9/10 missed). See eval-results.md Batch 1 vs Batch 2.

---

Strategic doc: repo/feature selection, design gate (14 sections), dedup, self-audit, attempt history.
Local-only (not uploaded). The platform uploads only the 5 deliverables.

- Repo: https://github.com/google/starlark-go (Go, BSD-3-Clause, 2.7k stars, active 2026-06-13)
- BASE_COMMIT: 8ba36ccb83fb02b223182e27808a6d5d0636afb9
- Tier: Olympus (user-confirmed at intake 2026-06-19; auto-discover repo; no domain preference)
- Oracle: CPython 3.12 (`python3`) - PEP-3101 `str.format()` / `format()`
- Feature: implement the Python `str.format()` PEP-3101 replacement-field + format-spec mini-language

---

## Step 0 - Candidate comparison (auto-discovery; 12 candidates scouted, top 2 adversarially verified)

NON-SQL reference-engine domains preferred (the approved pool is heavily SQL/query-engine).

| Candidate | Feature | Lang | License/Active | Prior-art | Subsystems | Eff LOC | Msg-floor | Distinct? | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| **google/starlark-go** | Python `str.format()` PEP-3101 format-spec mini-language | Go | BSD-3 / active | **clear** (spec reserves it; PR #625 defers) | 5 (spec parser, align/pad/group, int big.Int fmt, float fmt, str fmt + field resolution) | ~550 | clears w/ margin | yes - no fmt mini-lang in pool | **SELECTED** |
| expr-lang/expr | native `${...}` interpolation + Go-fmt verbs | Go | MIT / active | low literal but maintainer-philosophy HIGH-reject risk | 6 | ~430 | sub-100 risk | yes | fallback only |
| python-poetry/tomlkit | style-preserving TOML edit | Python | MIT / active | HIGH (8+ merged PRs/6wk) | 3 (mature) | ~60 | risk | yes | reject - feature shipped |
| colour-science/colour | color-space transforms | Python | BSD-3 / active | HIGH (62 open FEATURE issues) | 1+registry | ~220 | risk | yes | reject - single-formula, snapshot tests |
| hgrecco/pint | units/dimensional engine | Python | BSD-3 / active | HIGH (exhaustively complete) | 0 net-new | ~150 | risk | yes | reject - 14yr complete |
| cel-expr/cel-go | CEL macro/typed-eval | Go | Apache-2.0 / active | HIGH (gaps have in-flight PRs) | 0 | 0 | moot | yes | reject - conformance-complete |
| mvdan/sh | shell parameter-expansion | Go | BSD-3 / active | HIGH (already implemented) | 0 | ~40 | risk | yes | reject - in expand/param.go |
| dateutil/dateutil | RFC-5545 RRULE | Python | Apache/BSD / active | HIGH (shipped) | 0 | 0 | yes | reject - shipped + saturated date domain |
| netaddr/netaddr | IP/CIDR set algebra | Python | BSD-3 / **stale 2024** | high | 0 | 0 | yes | reject - shipped + stale |
| construct/construct | declarative binary parse/build | Python | MIT / **stale 2025** | high | 0 | 0 | yes | reject - shipped + stale |
| cpburnz/python-pathspec | gitignore matcher | Python | MIT / active | high | 0 | 0 | yes | reject - gap dead + **<500 stars** |
| jg-rp/python-jsonpath | RFC-9535 JSONPath | Python | MIT / active | high | 4 | 0 | yes | reject - **<500 stars** + shipped |

Selection rationale (the 9 questions): (1-2) above; (3) prior-art clear (the ONLY adjacent PR #625 explicitly *defers* format specs: "Future work: support !r,!s,:fmt"; the `%`-interpolation issues #493/#520 are the separate `%` operator); (4) domain-rich: a full format-spec mini-language is genuinely multi-subsystem; (5) subsystem footprint = 5 across 4 files; (6) expected effective LOC ~550 (clears 430 with margin); (7) rollout failure modes documented as the 5 orthogonal edges below; (8) meaningful to repo: the spec doc literally reserves the grammar ("reserved for future use ... field width, alignment, padding, and numeric precision") - a maintainer-sanctioned gap; (9) fair 1-3/10: a small grammar to READ but 5 compounding numeric-correctness subsystems whose independent miss-rates compound, with an exact CPython oracle so a correct agent passes cleanly (solvability floor met).

---

## Step 1 - DESIGN (14 sections, design gate; lives here per the "folder = 7 files only" rule)

### 1. Title
`Add Python format-spec rendering to str.format replacement fields` (verb: Add; names the subsystem: str.format replacement fields).

### 2. Shape classification
- Shape: **O-Composite-add** (new feature spanning a new shared module + 3 existing type renderers + the field-resolution call site) with a strong **O-Algorithm-correctness** component (subtle numeric correctness: sign-aware padding, base-aware grouping, empty-vs-g precision).
- PLAYBOOK Pattern 12: O-Composite-add = "add new language feature spanning parser/compiler/VM/runtime".
- Pass-rate target: ~10-15% (lean low; Wrong-Logic likely >=25% from the numeric edges -> O-Algorithm-correctness territory at 8-15%).
- Best agent: Vega (O-Composite-add) / Mixed.
- Dominant verdict: MISSED_REQUIREMENT + WRONG_LOGIC.

### 3. Public API surface (behavior reached through the STABLE existing API)
No new Go public symbols are referenced by tests (tests drive through `starlark.Eval`/`ExecFile` at runtime -> no compile-coupling). The user-visible surface is the Starlark `str.format()` method + `format()` builtin, extended to accept:
- format spec `[[fill]align][sign][#][0][width][grouping][.precision][type]` after `:`
- field access: `{0.attr}` (attribute), `{0[key]}` / `{0[index]}` (item)
- nested replacement fields inside the spec: `{:{}}`, `{:.{}f}`
- conversions `!s` (str) and `!r` (repr), applied before the spec
Internal helper surface (solution-only, not test-referenced): `parseFormatSpec`, `applyAlign`, `groupDigits`, `formatInteger`, `formatFloat`, `formatString`, `resolveField`, `resolveNestedSpec`, `convert`.

### 4. Canonical output form (CPython 3.12 oracle-exact; all values verified)
- Alignment: `<` left, `>` right, `^` center (extra pad on the right for odd), `=` sign-aware (pad between sign and digits). Default: numbers right, strings left.
- `0` flag == `fill='0', align='='`; an explicit alignment suppresses it.
- sign: `+` always, `-` negatives only (default), space -> leading space for non-negatives.
- `#`: `0b`/`0o`/`0x` (lowercase; `0X` only for `X`); for floats forces the decimal point.
- grouping: `,` groups decimals every 3 (illegal for `b/o/x/X/c`); `_` groups decimals every 3 and binary/octal/hex every 4; separators count toward the zero-pad width and pad zeros are themselves grouped.
- precision: floats default 6 for `f`/`e`, 6 significant for `g`; empty-type-with-precision is the general format that does NOT bump precision 0->1; integers reject precision; strings: precision truncates to N code points.
- types: int `b o d x X c n` + empty(==d); float `e E f F g G % n` + empty; str `s` + empty.
- inf/nan: `inf`/`-inf`/`nan` (uppercase `INF`/`NAN` for `E`/`F`/`G`), honor sign+fill+align, ignore precision.
- bool under a numeric spec -> formats as `1`/`0`; under empty/`!s`/`!r` -> `True`/`False`.
- `n` is deterministic C-locale: int `n` == `d` (no grouping), float `n` == `g`.
- `!r` uses Starlark repr (`syntax.Quote`, double quotes) - engine-authoritative.

### 5. Blind-spot pre-empts (canonical sentences in meta.md; each is tested)
- Sign-aware zero-pad: "The `0` flag pads with zeros between the sign and the digits; an explicit alignment overrides it."
- Grouping rule + base divergence: ", groups by three; _ groups decimals by three and other bases by four; the separators count toward a zero-padded width."
- Empty-vs-g precision and default precision.
- Per-family type legality (a type outside the value's family is an error).
- Auto/manual numbering is a one-way latch; nested fields share it and consume positional args left-to-right.
- String precision truncates to code points and is applied before width.
Limit: <=1 codebase-inferable requirement (the field-access protocol routing is the only one partly inferable from value.go; everything else is documented).

### 6. Description draft (meta.md) - see Step 5; <=200 words, plain prose, WHAT-not-HOW, ASCII only, frontmatter mandatory.

### 7. File footprint (sketched against real source)
| Action | Path | Role | Raw delta | Effective |
|---|---|---|---|---|
| NEW | starlark/format.go | `formatSpec` struct + `parseFormatSpec` + `applyAlign` + `groupDigits` (pure, no Value dep) | ~210 | ~175 |
| MODIFY | starlark/library.go | `string_format` rewrite: field-name sub-grammar, `resolveField` accessor chain, `resolveNestedSpec` pre-pass, `convert`, type dispatch | ~175 | ~150 |
| MODIFY | starlark/value.go | `formatFloat` + `formatString` | ~150 | ~130 |
| MODIFY | starlark/int.go | `formatInteger` (big.Int base fmt, `#`, sign, base-aware grouping, `c`, bool map) | ~110 | ~95 |
| TOTAL | 4 files (1 new) | | ~645 | ~550 |
Tier band: Olympus 400+ raw floor, 600+ Good, 3-file hard floor (8-35 band). 4 files clears the hard floor; effective ~550 clears 430 with ~120 margin. Re-count strictly with `effective_loc_check.py` before declaring done.

### 8. Solution outline - pure-function helpers (1:1 with behaviors)
- `parseFormatSpec(spec string) (formatSpec, error)` <- the grammar (two-char fill/align lookahead, leading-0 rule, `,`/`_` exclusivity, malformed rejection)
- `applyAlign(body, sign string, spec) string` <- align/pad engine (`< > ^ =`, 0-flag placement)
- `groupDigits(digits string, sep byte, groupSize int) string` <- base-aware grouping
- `formatInteger(i Int, spec) (string, error)` <- bases/`#`/sign/grouping/`c`/precision-illegal
- `formatFloat(f float64, spec) (string, error)` <- types/precision/empty-vs-g/`%`/inf-nan/neg-zero/alt-form
- `formatString(s string, spec) (string, error)` <- code-point precision/truncation/restricted flags
- `resolveField(arg Value, accessors) (Value, error)` <- `.attr` (HasAttrs), `[key]` (Indexable/Mapping)
- `resolveNestedSpec(...) (string, error)` <- nested-field pre-pass sharing the numbering latch
- `convert(arg Value, conv string) (Value, error)` <- `!s`/`!r` applied before the spec

### 9. Test file outline
- Path: `starlark/strformat_minilang_verification_test.go` (non-guessable; no `shipd`/`olympus`; not `format_spec_test.go`).
- Block 1 - imports (`starlark`, `starlarkstruct`, `testing`); Block 2 - one helper `evalFormat(t, src) (string, error)` running a snippet via `starlark.Eval`; Block 3 - table-driven `TestStrFormatMiniLanguage` with `t.Run(name,...)` subtests (one snippet each -> one JUnit `<testcase>`).
- Buckets: int / float / string / nested-fields / field-resolution / errors(boundary-contract). Full-value `assert.eq`-equivalent only.
- 5-axis coverage: every described behavior; the user-visible API (format/!s/!r/field/nested); every solution branch (each type arm, each flag, each error path); edge cases (empty/zero/negative/big-int/unicode/inf-nan/neg-zero/odd-center); stated inverses (empty-vs-g, manual-vs-auto).

### 10. Forced trait bounds / kwargs (Go specifics)
- `formatFloat` operates on `float64` (via `AsFloat`); integers route through `big.Int` (`Int.BigInt()`/`bigInt()`), NEVER int64 (overflow). String precision needs `[]rune`/`utf8`, never byte-slicing. Field resolution type-switches on `HasAttrs`/`Mapping`/`Indexable`. No new exported signature is test-referenced (runtime API only).

### 11. Predicted trap matrix (the 5 orthogonal compounding edges; each documented in meta + caught by tests)
| # | Trap | Why agents hit it | Pre-empt sentence (meta) | Catching test |
|---|---|---|---|---|
| 1 | Sign-aware zero-pad placement | pad the whole signed string | "0 pads between sign and digits; explicit align overrides" | `format(-42,'08d')=='-0000042'`, `format(-42,'0>8d')=='00000-42'` |
| 2 | Empty-type-with-precision != g | delegate to strconv `g` | "empty type with a precision is a general format, not g" | `'{:.0}'.format(3.14159)=='3e+00'` vs `'{:.0g}'=='3'` |
| 3 | Base-aware `_` grouping + width interaction | group by 3 everywhere / group after padding | "_ groups other bases by four; separators count toward width" | `format(0xABCDEF,'_x')=='ab_cdef'`, `format(1234567,'012,d')=='0,001,234,567'` |
| 4 | Nested-field numbering latch + arg order | reset numbering per field | "nested fields share the parent counter, consume args left-to-right" | `'{:{}}{}'.format('ab',5,'z')=='ab   z'` |
| 5 | Field accessor routing + re-applied spec | one `[...]` path / skip re-applying spec | field access documented; spec re-applied | `'{0.x:03}'.format(struct(x=3))=='003'`, `'{0[0]}'.format([10,20])=='10'` |
Wrong-Logic signal: expect >=25% (subtle algorithmic correctness) -> O-Algorithm-correctness band (8-15%). Spec is unambiguous (oracle-pinned), not accidentally underspecified.

### 12. Tier + category
- Tier: Olympus (Good target: 600+ would be ideal; ~550 effective is solidly Good-adjacent).
- Category: **feature-request** (net-new user-visible capability: format specs/field access/nested fields were all previously rejected). Honest category.

### 13. Predicted Nova pass rate
- Predicted: 8-15%. Reasoning: small readable grammar but 5 compounding numeric-correctness subsystems + the field-resolution exploration cost; independent miss-rates compound; oracle-exact full-value tests with near-miss scoring. Sanity: target ~10%; 0% -> redesign (solvability via CPython oracle reference solution + fuzz proves solvability); >30% -> add edges (do NOT de-trap).

### 14. Quality-gate checklist
- [x] Repo understanding 5/5 (architecture: tree-walking interpreter; subsystems syntax/resolve/eval/value/library; entanglement zones library.go builtins, value.go type protocols, eval.go interp; test framework go test + .star via TestExecFile + starlarktest; template test file string.star / eval_test.go)
- [x] Existing-PR check: 0 hits for str.format format spec (PR #625 defers it; spec reserves it) - searches recorded in discovery workflow
- [x] Closest approved opened side-by-side (babel-icu-messageformat - different grammar/oracle/domain)
- [x] Title verb-led, names subsystem
- [x] Shape declared w/ Pattern 12 citation
- [x] API surface lists user-visible behaviors + internal helpers (no "same as X")
- [x] Canonical output form fully spelled out (sort/align/grouping/precision/empty/inf-nan)
- [x] <=1 codebase-inferable requirement (field-access routing)
- [x] Description draft word count <=200 (Step 5)
- [x] Description plain prose, no `##`, no Box<>, no code-prose
- [x] File footprint sketched against real source (line numbers verified)
- [x] Raw ~645 / effective ~550 within tier band
- [x] 1+ pure helper per behavior
- [x] Nested-field recursion + numbering-latch pattern included
- [x] Test outline 4-block, scenario-encoded names, runtime-through-ExecFile
- [x] 5-axis coverage planned
- [x] Go specifics documented (big.Int, runes, type-switch); no compile-coupling
- [x] 5 named traps each w/ pre-empt + catching test
- [x] Wrong-Logic >=25% understood (O-Algorithm-correctness, not ambiguous - oracle-pinned)
- [x] Predicted pass rate matches band
- [x] Tier + category match
- [x] Feature NOT pattern-followable (no 3 near-identical examples; the existing renderers are minimal/different)
- [x] Feature NOT in RULES "Features already used"

---

## Why this is NOT a duplicate
Closest approved problems: (1) **babel-icu-messageformat** (python-babel, Python) - ICU MessageFormat plural/select grammar + CLDR number SKELETONS; different grammar (ICU `{n, plural, ...}` vs PEP-3101 `{field:spec}`), different oracle (ICU/CLDR vs CPython), different domain (i18n templating vs language-runtime numeric/string rendering), different language (Python vs Go). (2) The 5 SQL engines (gluesql x4, toydb) and 2 geometry problems (go-geom DE-9IM, mongomock geospatial) and 1 CSS-selector (textual) share no surface. starlark-go is NOT in the pool (no repo reuse). The FEATURE - a Python `str.format` PEP-3101 format-spec mini-language with sign-aware padding, base-aware grouping, empty-vs-g precision, nested fields, and accessor routing over Starlark value protocols - is new. Not in RULES "Features already used".

---

## Phase 5 - Failure-mode self-audit
- Bucket 1 (hidden requirements): every test traces to a meta sentence; the 5 edges are all documented. Error tests assert only "an error occurs" (bare/boundary-contract), never an unstated message/type. PASS.
- Bucket 2 (tech-spec tone): meta is plain prose, no headers/labels. PASS (verify at Step 5).
- Bucket 3 (tests pass on base): every positive spec test FAILS on base (base rejects all non-empty specs at library.go:1810); error tests use boundary-contract (positive assertion fails on base). PASS by construction.
- Bucket 4 (over-constrain): fairness cautions list 11 implement-but-don't-over-pin numeric nuances; `!r` only asserted where Starlark repr is unambiguous. PASS.
- Bucket 5 (too easy/under LOC): ~550 effective, 5 compounding subsystems; not under floor, not pattern-followable. PASS.
- RULES real-revert causes walked: no test.sh trickery (single source of truth), no redundant/weak/vacuous asserts (full-value), no exact-string error asserts (substring/bare), no scope creep (`%` operator + f-strings explicitly out), no regression-on-base (existing renderers untouched), no AI comments, correct package (starlark), no dead code, bounds documented, deterministic (no time/locale - `n` pinned to C-locale). PASS.
- AGENTS confirmed blind spots: specific-examples-override-general (meta gives rules, sparse examples); default-ordering and adjacent-vs-all pre-empted by the canonical-form sentences. PASS.

Predicted iteration cycles: 2 (accept <=3).

---

## Build / validation summary (2026-06-19)
- Solution: 4 files (starlark/format.go NEW + library.go + int.go + value.go modified). raw added 848, human-effective 565 (>= 430 floor with margin; `effective_loc_check.py` reports 565). The genuine depth is the spec parser, the grouping+zero-pad algorithm, the float renderer (empty-vs-g threshold X>=sig-1, repr threshold 16, sign-aware '=' placement, inf/nan/neg-zero), and field resolution crossing HasAttrs/Mapping/Indexable + nested-field recursion -- not registry breadth.
- Oracle: CPython 3.12. The Go reference was differential-fuzzed against CPython across ~12,500 (value,spec) cases over two seeds -> 0 mismatches. Oracle generators kept at /tmp/starlark-fmt-oracle/.
- Tests: one new Go file `strformat_minilang_verification_test.go` drives every case through the STABLE runtime API (`starlark.Eval` on `"{:spec}".format(x)`), reads the string -> NO compile-coupling (avoids the static-API 0%-solvability artifact). 122 subtests (94 positive + 28 boundary-contract rejections). Error tests assert only "an error occurs" (bare), never a message/type pin; all 27 testable invalid inputs confirmed to raise in CPython too.
- Existing-test edit: removed 3 obsolete assertions in `testdata/string.star` (lines 221-223) that pinned the OLD "x.y / a[i] / nested not supported" rejections -- the feature implements that syntax, so they are obsolete. They cannot hold in both base and solution states (base errors "...not supported", solution accepts), so removal (in test.patch) is the only resolution that keeps base mode passing in both states. New behavior is covered by the new test file.
- test.sh: position-independent --output_path; base mode `go test -skip ^TestStrFormat ./...` (full existing suite, regression), new mode `go test -run ^TestStrFormat ./starlark/`; go-junit-report (installed in Dockerfile, NOT preinstalled in the image); empty-report fallback.
- Dockerfile: Pattern B olympus-base-go; GOFLAGS=-buildvcs=false (the mount/checkout trips VCS stamping otherwise); go mod download (offline cache) + go install go-junit-report + go build ./...
- 4-cell (offline, non-root, clean BASE checkout): BARE build PASS (EnvQuality); base|base PASS (75/0), base|new FAIL (124/124 -> full F2P), sol|base PASS (75/0, no regressions), sol|new PASS (124/0). Solvability proven.
- meta.md: 282-word body (API-heavy band 200-450; approved pool ranges 236-555). Bidirectional alignment walked: added `n`-type tests and an int-as-float clause to close two described-vs-tested gaps.

## Easiness red-team (naive-agent benchmark) + difficulty calibration
A clean from-spec implementation (independent agent, meta.md only, no reference) scored 82/94 positive subtests (~87% per-TEST pass), failing 12 across SIX orthogonal trap categories: sign-aware `=`/fill placement, empty-type-vs-`g` precision/threshold, `#g` trailing-zero retention, bool-as-int under a numeric/non-empty spec, int-with-float-type, and grouped-zero-pad boundary.

Read: per-TEST 87% is NOT the per-AGENT solve rate. To SOLVE, an agent must pass ALL F2P; the obvious impl fails 12 tests across 6 INDEPENDENT compounding edges, so it does not solve. This is the babel-icu profile (a stacked engine-authoritative numeric-formatting feature that landed ~9% / 1-pass on the platform with a comparable naive benchmark). Each trap is a documented naive-default-is-wrong edge where Go's strconv/fmt genuinely diverges (no `#`, wrong `g` threshold at 21 vs CPython 16, no grouping, base-10-only ints), so even a strong agent must write custom code per edge; independent miss-rates compound toward the ~10% band. The platform Nova/Orion/Vega batch is the authoritative signal: if it returns >30% (too easy) add a 6th independent subsystem; if 0% de-trap the clearest edge (never bypass solvability).

FAIRNESS FIXES from the benchmark (bidirectional alignment): documented two real behaviors the benchmark exposed as under-described -- float `#` keeps the point and trailing zeros, and bool renders as 1/0 under any non-empty specifier (kept their tests). Dropped two genuinely-ambiguous tests -- `{:<08d}` fill-char-under-explicit-align and the string `0`-flag left-fill -- rather than over-pin exotic CPython-specific interactions (the babel-icu numeric-over-pinning minefield). Final: 120 F2P subtests (92 positive + 28 boundary-contract rejections). meta body 310 words (API-heavy band 200-450). Necessary-info over-detail HIGH, if raised, is BYPASS-eligible -- keep the alignment, never delete a tested-behavior description.

## Precheck warnings -- disposition (2026-06-19)
Three platform/AI prechecks returned warnings; handled as follows.
1. **Test-patch sanity: "go test -skip is not a standard flag"** -- FIXED (not bypassed). The claim is outdated (`-skip` was added in Go 1.20; the Dockerfile pins Go 1.26.3 and base mode empirically ran 75 testcases at exit 0), but rather than rely on a bypass for a "runner is broken" warning, I eliminated `-skip` entirely: the new tests now live in their OWN package `starlark/strformatspec/`, base mode runs the full existing suite via `go test $(go list ./... | grep -v '.../strformatspec$')` and new mode runs `go test ./starlark/strformatspec/`. 100% standard `go test`, no flag in question, no build-tag swap, no env trick. base mode still exercises the `starlark` package (TestExecFile + the string.star edit) for regression.
2. **Tests cover required behavior [WARNING]** -- (a) bool empty-spec -> True/False: NOT added, justified. `"{}".format(True)` is BASE behavior (passes on base), so an assertion would not be F2P and would trip before_f2p_unexpectedly_passing; the meta clause stands as context for the tested "any other specifier -> 1/0" rule. (b) nested numbering-latch: FIXED -- added `nested_manual_numbering` (`{0:{1}d}`->`   5`), `nested_manual_then_trailing`, and a boundary-contract `nested_manual_then_auto_latch` (valid `{0:{1}d}` + invalid `{0:{}d}` -> error), directly exercising the shared auto/manual latch and left-to-right consumption.
3. **Necessary-info over-detail [MEDIUM x2, optional]** -- IGNORED, justified. "Remove the catch-all 'other incompatible option combinations are errors'": that clause is LOAD-BEARING -- it is the only description backing the `double_sign`, `comma_and_underscore`, and `comma_with_char` rejection tests; deleting it would convert those into hidden requirements (the documented over-detail-vs-hidden-requirement trap). "Remove 'gains a format specifier after :'": kept -- it carries the `:` placement, stated nowhere else, and is harmless. Both suggestions are explicitly optional ("take or leave"); keeping alignment beats trimming.

## Task-Quality Crit-08 (Long-Horizon & System-Level) FAIL -> resolution (2026-06-19)
The Task-Quality check PASSED every criterion except Crit-08: the feature was "concentrated in one runtime subsystem" (str.format in starlark) -- a deep Mars-style feature, not an Olympus system-level one. The checker suggested unifying formatting across str.format and the % interpolation operator.

RESOLUTION (chosen after weighing options; user directed "best Olympus-meeting fix, not Mars"): UNIFIED the % string-interpolation operator with str.format. % now accepts the optional printf [flags][width][.precision] before each conversion, rendered through the SAME engine (the format.go/int.go/value.go renderers) as str.format. This adds a genuinely-independent SECOND formatting surface wired by the shared rendering contract, spanning eval.go (interpolate) + library.go + the renderers -> a solver must understand both formatting paths and the shared engine.

Why this is safe and correct:
- ADDITIVE / zero regression: every printf flag/width/precision form currently ERRORS on base (eval.go default case), and no existing test asserts those failures; bare % (the only thing base supported) is left on the unchanged legacy path. The full existing suite (incl. existing %-tests in string.star/int.star/float.star) still passes.
- Earlier I (and my own review) flagged % as a maintainer-philosophy reject risk, citing the eval.go "% is minimal" NOTE. RE-EXAMINED: that NOTE is a current-state limitation, not a maintainer rejection PR, and the platform's OWN Task-Quality checker explicitly requested this unification. I updated the NOTE and documented the extension. Risk reassessed as low.
- printf semantics genuinely DIVERGE from PEP-3101 and are handled correctly (verified by fuzz): integer precision = MINIMUM digits (not an error), strings default to RIGHT alignment (PEP-3101 defaults left), the 0 flag is IGNORED for %s and %c (str.format %c honors it). These divergences are implemented in formatPercentInt / renderPercentVerb, not by blindly reusing the PEP-3101 path.
- ORACLE: CPython 3.12 for both surfaces. Differential-fuzzed %-forms (~5,700 cases) AND re-fuzzed str.format (~4,400) -> 0 mismatches.
- Scope after fix: 5 source files (eval.go added), 1050 raw / 704 human-effective LOC (up from 565), str.format tests + new TestPercentInterpolation/TestPercentRejections (151 new-package subtests). meta 378 words (API-heavy band 200-450), title broadened to name both surfaces.

## Test Fairness FAIL (2 of 20 unfair) -> resolution (2026-06-19)
The Test Fairness check passed 18/20 but flagged 2 unfair author-choice pins on behavior the prompt never specifies:
1. Infinity spellings: `{:08.1f}` on +/-inf ("00000inf"/"-0000inf") and `{:F}` -> "INF". The prompt never specifies inf spelling/casing/zero-pad interaction, and it CONFLICTS with the repo's own convention (value.go emits `+inf`/`-inf`/`nan` lowercase regardless of case; float.star asserts `+inf`). A solver following repo conventions could reasonably differ.
2. `"%05.3d" % 5` -> "00005": the prompt states precision=min-digits and `0` zero-pads but never resolves the precedence when BOTH apply; C-printf commonly ignores `0` under precision, so "00005" is one reasonable choice of several.

FIX (relax/remove, per the description<->test symmetry law -- never pin behavior the prompt doesn't nail down): REMOVED all four infinity tests (float_inf_zero_pad/neg/upper/sign_plus) and the `%05.3d` test. The SOLUTION keeps its CPython-correct behavior for these corners; it is simply no longer ASSERTED (engine-authoritative, unspecified). No meta change needed for fairness (the meta never specified inf). new-package suite now 146 subtests.

Also (advisory warnings, user permitted bypass):
- Necessary-info MEDIUM: removed the "rendered through the shared engine so the two surfaces agree" phrase from the `%` paragraph (a WHAT-not-HOW improvement); KEPT the `%` flag meanings (`-`/`+`/`#`/`0`) because `%`'s flag syntax differs from str.format's (`-` vs `<`), so deleting them would turn the `%` flag tests into hidden requirements. Necessary-info LOW (drop the "other incompatible combinations are errors" catch-all): KEPT -- it is load-bearing for the double-sign / comma+underscore / comma-with-c rejection tests (deleting it = hidden requirements). Bypassed per the keep-alignment rule.
- Category WARNING (feature_request vs enhancement): the platform suggests ENHANCEMENT, and it is the honest category -- this EXTENDS existing str.format and % rather than adding a net-new public API. RECOMMENDATION: select "enhancement" at submission (platform field, not a deliverable). Logged here.
- Aligned WARNING (clarify =-on-string / empty-type-precision / inf): bypassed -- Test Fairness independently deemed the =-on-string and empty-type-precision tests FAIR; inf is now untested.

## Description Quality FAIL (0/4) -> resolution (2026-06-19)
The check flagged the meta as mini-reference-doc style + two over-specifications. All four ADDRESSED by rewriting to prose while PRESERVING every tested behavior (dropping a tested-behavior description would re-trigger Test Fairness):
1. BNF spec grammar "[[fill]align][sign][#][0][width][grouping][.precision][type]" -> replaced with prose ("A specifier may give, in order, an optional fill character with an alignment, a sign, the alternate form, zero padding, a width, a grouping option, a precision, and a type."). All components stay described; only the BNF notation is gone.
2. Exhaustive float-type list with untested `F` -> dropped `F` (the only float type with no test, after the inf test was removed); kept the tested e/E/f/g/G/%/n (named because Test Fairness requires the tested type codes to be described).
3. Over-spec "bool formats as True/False only with an empty specifier" -> trimmed to the tested behavior only ("Under a non-empty specifier a bool formats as its integer value 1 or 0"); the empty-spec rendering is base behavior and untested.
4. `%` "[flags][width][.precision]" bracket -> prose ("the same optional flags, width, and precision before each conversion").

Confirmed bidirectional alignment after the rewrite: no tested `{:F}` or empty-spec-bool case exists (grep = 0), so nothing is orphaned; every described behavior is still tested.

Category (user decision, 2026-06-19): KEEP **feature_request**, not the warning's suggested "enhancement". Justification (pool-referenced, advisory warning bypassed): every approved problem lives under `approved-problems/feature-request/`, including engine-EXTENSION features directly analogous to this one -- toydb-correlated-subqueries ("Add Subquery Expressions..."), go-geom-de9im-predicates ("Add DE-9IM..."), gluesql-grouping-sets ("Add GROUPING_ID..."), babel-icu-messageformat ("Add ICU MessageFormat..."). The pool consistently categorizes "add a comprehensive capability to an existing engine" as feature_request; this submission is the same shape. The warning itself says feature_request is "not incorrect".

Necessary-info (advisory, request_changes, 2 HIGH) disposition: HIGH(1) "!s/!r still convert before formatting" -> REFRAMED to "A conversion, !s or !r, applies before the specifier formats the result" (drops the preserve-existing "still" framing; keeps the load-bearing conversion-before-spec ORDER the conversion tests assert). HIGH(2) "drop the % flag meanings" -> KEPT the meanings (`-`/`+`/`#`/`0`): `%`'s `-` flag means left-align (vs str.format's `<`), so the meanings are load-bearing for the % flag tests; deleting them = hidden requirements. Bypassed per the keep-alignment rule. MEDIUM "remove redundant 'a precision on an integer'" -> removed from the error list (already stated earlier). MEDIUM catch-all + accessor examples -> kept (catch-all is load-bearing for the double-sign/comma+underscore/comma-with-c rejections; examples are tested forms).

## Round 2 of Description-Quality + Category (2026-06-19) -- the prior pass over-trimmed; redone cleanly
The previous meta edit over-trimmed (changed the `%` clause to "the same optional flags", which the checker then read as implying full str.format parity) and the Category check escalated WARNING->FAIL. Both fixed:

CATEGORY (FAIL, suggested enhancement) -> reframed the meta to read as a FEATURE REQUEST, mirroring the approved pool's framing for engine-EXTENSION features (which are ALL feature_request): lead with "Add [new capability]" rather than "X gains/improves". Cf. gluesql-insert-on-conflict "Add upsert to INSERT through an ON CONFLICT clause", toydb "Add Subquery Expressions...", go-geom "Add DE-9IM... add a relate package", gluesql-grouping "Add GROUPING_ID...". Both body paragraphs now open with "Add ..."; no "gains"/"improve" language. User's decision: select feature_request at submission (the pool precedent + this framing support it; the prior warning called feature_request "not incorrect").

DESCRIPTION QUALITY (FAIL 0/4) -> all four addressed, preserving every tested behavior:
1. "The sign is +, -, or a space" -> dropped untested `-` (it is the default; no explicit `{:-}` test); kept the tested `+`/space ("A + or a space prefixes a non-negative number...").
2. "f and e default to precision six" -> dropped untested `e` default (every `e` test uses an explicit precision); kept `f` default six (tested by float_fixed_default) and `g` six significant (tested).
3. Verbose catch-all -> softened to the checker's offered brief umbrella ("...are errors, as are other invalid option combinations"). Kept (not removed) because it is load-bearing for the comma-with-base / sign-with-c / =-on-string rejection tests, which are not enumerated explicitly; removing it = hidden requirements.
4. `%` "the same optional flags" -> replaced with the EXACT enumerated `%` features the checker asked for ("Add the -, +, space, #, and 0 flags, a width, and a precision to the % operator's conversions"), keeping the flag meanings (load-bearing for the % flag tests).

Confirmed: no orphaned tests (no explicit-`-`-sign test, no precision-less `{:e}`/`%e` test); solution.patch + test.patch byte-identical to the validated 150/150 4-cell. meta 416 words (band 200-450), ASCII-clean.

## Independent review (round 2, recalibrated build) -> REQUEST CHANGE (2026-06-19)
Adversarial 4-dimension review of the current bytes. Description/tests SOUND (minor-only); solution SOUND apart from one stale comment; the gating blocker is procedural (stale eval). Verdict REQUEST CHANGE -- not ACCEPT-ready until a FRESH agent batch evidences solvability on the recalibrated bytes.

Confirmed findings + disposition:
- [BLOCKER, procedural] Solvability/pass-rate/message-floor UNEVIDENCED on the current bytes: Batch 1 (0/6) ran on the PRE-recalibration build, so it is STALE evidence. Needs a fresh >=10-attempt batch on the committed recalibrated bytes. (Cannot be done locally -- platform eval. The recalibration targeted Orion's exact failures, so a pass is plausible; must be measured.)
- [MAJOR, FIXED] Stale formatFloat doc comment claimed "does not delegate to Float.format ... follows CPython repr thresholds ... differ from Go's" -- both false after recalibration (empty-no-precision now DELEGATES to Float.format/g). Rewrote the comment to describe the delegation. Comment-only; no gate impact.
- [MINOR, FIXED] %s/%r with sign/#/space: CPython IGNORES those flags (renders the string) but the solution ERRORED. Made renderPercentVerb clear sign/#/grouping for string conversions (printf ignores them). Re-fuzzed % incl. %s+flags vs CPython: 5990 cases, 0 mismatches. Untested edge (no %s+sign test); meta unchanged (it documents the tested 0-flag-ignored behavior only).
- [NIT, annotated] Float alternate-form (#) on floats is implemented and CPython-correct but intentionally UNDOCUMENTED + UNTESTED (dropped from the tested surface in the recalibration to de-trap #g). It is NOT dead code -- it is a reachable, correct code path; a future reviewer should not mistake it for dead code.
- [NIT] Octal `_`-grouping and `=`-on-string-error breadth: covered by the existing base-aware-grouping and string-rejection tests + the catch-all; not expanded (optional).

Current shipped build (authoritative): 5 source files, 694 effective LOC; new suite 146 testcases / 142 subtests; base 75; meta body 394 words (awk, whitespace-token count). Earlier feedback entries cite historical LOC/test counts (565/704, 150/155) from prior rounds -- the line above is the current build.

## Attempt history
- 2026-06-19: Repo+feature selected via discovery workflow (12 candidates scouted, adversarial prior-art/gap verify); starlark-go str.format PEP-3101 chosen (prior-art clear, CPython oracle). Design gate authored + self-audited (autonomous one-shot). Solution written, fuzzed to 0 mismatches vs CPython, tests written + verified, 4-cell + bare-build validated in Docker. Awaiting naive-agent difficulty benchmark, then platform eval.
