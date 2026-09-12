# TESTS — How to Write test.patch + test.sh

> **Read first:** `PLAYBOOK.md` § Pattern 2 + Patterns 11–12 — test structure + shape-aware test count observations from 13 approved problems.

---

## The Golden Rules

1. **All new tests FAIL on base code** — if tests pass without the solution, they're not testing the bug/feature
2. **All new tests PASS with solution** — confirms the fix actually works
3. **All base tests still PASS** — no regressions introduced
4. **Match repo conventions** — same framework, directory, naming, comment style
5. **Every test traces to description** — no surprise behaviors
6. **Every described behavior has a test** — no gaps
7. **Tests run offline** — no internet (`--network none`)
8. **Patches don't conflict** — apply in either order
9. **★ NO FLAKY TESTS (MANDATORY check, admin 2026)** — every test 100% deterministic across runs + machines. NO timing (`sleep 0.1`), NO unseeded randomness, NO ordering assumptions, NO resource/CPU-dependent assertions. ALSO verify the REPO's existing tests aren't flaky (run base 2-3x at pick time). Flaky = mandatory reject.

### Flakiness gate (run before submit)
```bash
# New tests 3x — all 3 runs must be IDENTICAL
for i in 1 2 3; do ./test.sh --output_path /tmp/new$i.xml new; done
# Base 3x — flag any existing test that flips
for i in 1 2 3; do ./test.sh --output_path /tmp/base$i.xml base; done
```
Any test that flips across runs: fix it (fixed seed; wait-for-condition not sleep; `os.utime` for mtime; `GOMAXPROCS` pin for parallel determinism) OR exclude a pre-existing flaky repo test in base mode with a documented reason. See `§ Avoiding Flaky Tests`.

### Hard Reject (Unfixable)
- Test patch is **not a valid git patch** → hard reject
- Test patch contains **malicious code** → hard reject

Everything else (wrong framework, weak assertions, missing edge cases, solution code mixed in) → Request Change, not reject.

---

## Required Test File Structure (4-block layout)

Every approved Mars test file uses this exact top-to-bottom layout. Replicate it. Helpers up top → tests are 1-line each. Reviewers grep `#[test]` and verify each scenario in 5 seconds.

```rust
// 1. Imports — only what tests need
use pest_meta::ast::{Expr, Rule, RuleType};
use pest_meta::optimizer::{optimize, OptimizedExpr, OptimizedRule};

// 2. Tiny builder helpers — 10-30 of them, one-liners
fn str_s(s: &str) -> Expr { Expr::Str(s.to_owned()) }
fn seq(l: Expr, r: Expr) -> Expr { Expr::Seq(Box::new(l), Box::new(r)) }
fn choice(l: Expr, r: Expr) -> Expr { Expr::Choice(Box::new(l), Box::new(r)) }

// 3. Single-purpose assertion helpers — 1-3, substring-match for errors
fn expect_error(input: &str, expected_substring: &str) {
    let pairs = PestParser::parse(...).unwrap_or_else(|e| panic!(...));
    match consume_rules(pairs) {
        Err(errors) => assert!(
            errors.iter().any(|e| e.to_string().contains(expected_substring)),
            "expected error containing {:?}, got: {:?}", expected_substring, errors
        ),
        Ok(_) => panic!("expected error, but compiled cleanly"),
    }
}

// 4. Tests — granular, ONE scenario each, scenario-encoded snake_case names
#[test]
fn range_z_to_a_errors() {
    expect_error(r#"a = { 'z'..'a' }"#, "invalid range");
}

#[test]
fn range_digit_inverted_errors() {
    expect_error(r#"a = { '9'..'0' }"#, "invalid range");
}
```

**Required:**
- One new test file at conventional repo location (`<crate>/tests/<feature>_tests.rs` for Rust)
- Helper builders before assertion helpers before tests
- Scenario-encoded snake_case naming (`<input_shape>_<expected_outcome>`)
- Error tests use `.contains(substring)` with 1–3 stable keywords (never `==` on full message)
- Zero `//` comments inside test bodies
- One assertion per `#[test]` (or one `expect_*` helper call)

Approved precedent: open `Mars Approved V2/Feature Requests/pest-validator-hardening/test.patch` for the cleanest single-file example (39 tests, 290 lines, substring-match throughout).

---

## Test Coverage (Count-Agnostic)

**Coverage completeness is the target. Test count is the consequence.** Tests must cover:

| Coverage axis | What "complete" means |
|---|---|
| **Every described behavior** | For each sentence/bullet in `meta.md`, ≥1 test exercises it |

> **⚠️ Do this MECHANICALLY, not by reading.** Split meta.md into CLAUSES (not sentences — a
> sentence with a "so" or a "," often carries two independent contracts) and write the clause list
> out with the test name that covers each. A clause with no name next to it is a coverage gap.
> Measured miss on `rejected/lol-html-sibling-combinators`: the clause "Only elements separate
> elements, so text, comments and other content sitting between two elements do not affect whether
> they are siblings" sat inside a sentence whose FIRST half was well covered, and it shipped with
> zero tests — caught by the grader, not by me, despite this rule already being on the checklist.
> Eyeballing a description you wrote yourself does not work; you read the intent, not the text.


| **Every public API surface** | Every new function, method, error variant, config option has tests |
| **Every solution branch** | Every `if`, `match` arm, early return, recursive case reached by some test |
| **Edge case bank** | Empty / zero / single-element / boundary / unicode / recursion / null |
| **Stated inverse** | If "X happens when Y" matters and isn't symmetric, also test "X does NOT happen when Y is absent" |

The count is whatever those 5 axes demand — no minimum, no maximum.

### Correlated blind spot check (Principal Reviewer Rubric #6)

If solution AND tests both independently miss the same requirement, no test catches the gap — and the principal reviewer will. **Build a requirement-coverage matrix BEFORE submit:**

| Description requirement | Solution code (file:func) | Test that exercises it |
|---|---|---|
| <each behavioral ask> | <where implemented> | <which test> |

- Blank test column → correlated blind spot. Add a test.
- Solution AND test both vague on a row → requirement isn't really enforced. Tighten both.
- Don't just check "do tests pass." Check "do tests cover everything the problem asks for."

This is the ONLY way to catch a gap where the implementation skips a requirement AND no test would notice. Trace every meta.md sentence to both columns. See `PRINCIPAL-REVIEWER-RUBRIC.md § 6`.

### Approved test counts by shape (observational anchors, not targets)

| Shape | Tests | Density |
|---|---|---|
| Mars C (validator-hardening) | 39 | dense — 8 error classes × 4-5 substring tests |
| Mars A1 (lightningcss) | 68 | mid — recursion, dedup, double-negation |
| Mars A2 (factorizer) | 92 | mid — fixpoint scenarios |
| Mars D-change (extended-skip) | 102 | dense — Display, normalization, 4 SkipChoice variants |
| Mars D-new (error-recovery) | 126 | spread — 3 test files (meta + vm + derive) |
| Mars B (unused-rule-elim) | 160 | high — 13 public functions × 12 scenarios |
| Olympus (range) | 14–162 | varies by feature scope |

**Only count-related red flag: redundancy.** Two tests asserting the same behavior with cosmetic input variation → consolidate via parametrization.

### Test Distribution Heuristic

| Type | % of total |
|---|---|
| Core functionality | 40-50% |
| Edge cases | 30-40% |
| Integration | 10-20% |
| Error handling | 10-20% |

**Sweet spot: 15-35 tests** for typical features. Above 72 gets flagged as excessive (consolidate via parametrization). Approved Mars range observed: 39–160.

| Complexity | Test Count | Patch Lines | Example |
|---|---|---|---|
| Simple bug | 8-15 | 168-400 | attrs #734 (24 tests, 341 lines) |
| Moderate bug | 15-25 | 400-600 | elysia #1504 (18 tests, 546 lines) |
| Complex feature | 25-50 | 500-1000 | cron-parser DST (56 tests, 734 lines) |
| Large feature | 40-70 | 700-1500+ | dooit-completion (62 tests, 1522 lines) |

---

## Test Naming Convention

Scenario-encoded snake_case that reads as a sentence:

| Pattern | Examples |
|---|---|
| `<input_shape>_<expected_outcome>` | `range_z_to_a_errors`, `dedup_two_class_is`, `single_orphan_reported_as_unused` |
| `<context>_<input>_<outcome>` | `negpred_of_always_failing_choice_in_rep_errors`, `peek_slice_empty_in_choice_first_alt_errors` |
| `fixpoint_<scenario>` | `fixpoint_three_way_prefix_folds_completely`, `fixpoint_already_factored_is_stable` |

Drop generic names like `test_basic_stuff` — they don't tell the reader what scenario is exercised. Misleading test names also flagged: don't name "Deeply Nested" if it only has 2 levels.

### Test FILE Naming — Banned Markers + Random Hash (CRITICAL)

Test FILE names (not function names) MUST NOT contain `shipd` or `datacurve`. Predictable markers let implementer agents guess test filenames. Platform precheck hard-rejects (example: `"interp/goroutine_lifecycle_shipd_test.go" contains banned marker "shipd"`).

**Random hex suffix required** so filename can't be predicted:

```bash
HASH=$(openssl rand -hex 3)   # 6-char hex, e.g. a3f9b2
```

Per-language convention:

| Language | Pattern | Example |
|---|---|---|
| Python | `test_{name}_{HASH}.py` | `test_goroutine_lifecycle_a3f9b2.py` |
| TypeScript/Deno | `{name}.{HASH}.test.ts` or `{name}_{HASH}_test.ts` | `goroutine_lifecycle.4c8e1f.test.ts` |
| Go | `{name}_{HASH}_test.go` | `goroutine_lifecycle_9d2c7e_test.go` |
| Rust | `{name}_{HASH}.rs` | `goroutine_lifecycle_7e3d12.rs` |
| Bun | `{name}.{HASH}.test.ts` | `goroutine_lifecycle.2b8a4f.test.ts` |

Pre-submit guard:
```bash
grep -rEl "shipd|datacurve" tests/ test.sh   # must return nothing
```

Generate the hash ONCE per problem and reuse across all new test files in that submission (consistency aids reviewer + cross-file traceability).

---

## Assertion Style

**Strong:**
```rust
assert_eq!(find_unused_rules(&rules), v(&["orphan"]));         // exact list
assert_eq!(optimize_single(RuleType::Normal, input), expected); // exact tree
simplify_test(":is(.a, .a) { color: red }", ".a{color:red}");   // exact CSS
expect_error(r#"a = { "x"{5,3} }"#, "invalid repetition");      // substring on errors
```

**Weak (gets flagged):**
```rust
assert!(result.is_ok());                  // doesn't check value
assert!(!output.is_empty());              // doesn't check content
assert_eq!(err.to_string(), "exact ...");  // brittle
```

### Assertion Style Rules (From Admin Feedback)

Real patterns that got flagged in admin reviews:

| Bad | Problem | Fix |
|---|---|---|
| `expect(fn).toThrow("Expected 2 arguments but got 1")` | Exact string breaks if message changes | `expect(fn).toThrow(TypeError)` or `expect(fn).toThrow(/2 arguments/)` |
| `expect(result).rejects.toBeDefined()` | Weak — any error passes | `expect(result).rejects.toThrow(SpecificError)` |
| `expect(result).toEqual([])` when `[]` is wrong | Empty still passes | `expect(result).toContainEqual(expected)` |
| `expect(order[1]).toBe("high")` | Asserts exact interleaving order | Assert non-preemption behavior instead |
| Timing assertions with tight bounds + random jitter | Flaky on CI | Mock timers or widen tolerances significantly |
| `assert mtime2 > mtime1` with `time.sleep(0.1)` | Filesystem granularity issues | Use `time.sleep(2.0)` or explicit `os.utime()` |
| `_ = value` (Go) | Silences unused var without asserting | `require.NoError(t, err)` |
| `assert len(result) > 0` | Passes with wrong content | Assert specific items and values |

**Substring keywords (Mars-approved):** `"cannot fail"`, `"following choices"`, `"invalid repetition"`, `"invalid range"`, `"contradictory"`, `"alternative"`, `"negative predicate"`, `"recurs"`. Pick 1–3 stable keywords per error class.

---

## Comments Inside Tests

**Zero `//` comments inside test bodies.** Function names carry the meaning.

| Allowed | Forbidden |
|---|---|
| File-header doc comment if repo's other test files have one | Category headers (`// CATEGORY 1: Basic Cases`) |
| `#[track_caller]` on assertion helpers | Numbered steps (`// Step 1: Setup`) |
| Match repo's existing test convention exactly | Comments restating the test name |
| | `NOTE:` / `TODO:` markers |
| | Comments when nearby repo files have none |

### AI Comment Detection (Reviewer Flags)

Reviewers specifically flag AI-generated patterns in tests:

| AI Signal | Example | Why It's Flagged |
|---|---|---|
| Category headers | `// CATEGORY 1: Basic Circular References (5 tests)` | Real devs don't categorize tests like this |
| Explanatory comments | `// Test that the function returns expected result` | Comment restates the test name |
| Behavior mismatched with comment | Comment says "behavior may vary" in deterministic test | Tests must be deterministic |
| Comments when nearby files have none | Test file has comments but `existing_test.ts` next to it has none | AI indicator — repo convention is no comments |
| Numbered comment blocks | `// Step 1: Setup... // Step 2: Act... // Step 3: Assert` | Real tests don't narrate themselves |

**Key admin rule:** *"If comments are present in a test file, nearby files should also have comments. Otherwise, it may indicate AI usage. Always follow repository conventions."*

---

## test.sh Structure

Must accept `--output_path <path>` and produce JUnit XML. Position-independent arg parsing.

**CRITICAL**: The platform invokes test.sh as `./test.sh --output_path <path> base` — the `--output_path` flag comes BEFORE the mode argument. NEVER assume `$1` is the mode.

```bash
#!/bin/bash
set -e

OUTPUT_PATH=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
MODE="${ARGS[0]}"

case "$MODE" in
  base) {run ALL existing tests, write JUnit XML} ;;
  new)  {run ONLY new test files, write JUnit XML} ;;
  *) echo "Usage: ./test.sh --output_path <path> {base|new}"; exit 1 ;;
esac
```

### Base mode rules

- Run ALL existing tests; exclude new test files with `--ignore` or `--exclude`
- **Every base-mode exclusion needs a REAL reason** (Principal Reviewer Rubric #8). Valid reasons: "needs a browser that's not in the Docker image", "needs network access", "pre-existing flaky test", "pre-existing broken on this commit". Document each exclusion inline in test.sh with its reason.
- **The rule is about WHY you skip, not whether you can** (Elabyad clarification 2026-04-12). Skipping is NOT absolute-forbidden:
  - **Legit skip:** fixing a bug the base tests were expecting — base tests asserted the OLD buggy behavior, so they now correctly fail. Modifying/skipping those is the right thing.
  - **New behaviors/features → make opt-in** instead of changing base behavior, so existing tests keep passing unmodified. Reach for the non-breaking approach first.
  - **NEVER skip to hide regressions or solution issues.** If a hidden solution issue still passes the tests → the tests are either not fully correct OR missing cases. The skip isn't the crime; masking a broken solution with it is.
- **Don't skip base tests in areas your solution touches** unless you have a real reason per above. Running them can surface issues your new tests don't catch, OR reveal your new tests aren't covering what they should.
- `--deselect` specific tests OK only when:
  - Solution changes shared files break specific existing tests (httpx deselects 33 tests)
  - Pre-existing flaky/broken tests don't pass in Docker
- **Reviewers count tests** — if repo has 41 and you run 28, gets flagged
- Never reduce base test count to hide regressions

### New mode rules

- Run ONLY new test files
- Default: single test file (12/14 approved use this)
- Multi-target only when feature crosses ≥3 crates that each have their own test target

### Cross-verification (IMPORTANT)

Always run **both** modes and verify the actual test counts. Test configurations (especially TypeScript) can be deceptive and may run the wrong tests. The Shipd bot doesn't always catch this either.

### test.sh Anti-Patterns

- Base tests must run **actual tests**, not just check if binary/module exists
- test.sh **switching behavior between modes** is suspicious → flag it
- No build tags that exclude tests after solution is applied (e.g., `//go:build base`)
- test.sh must run the SAME tests before and after solution in each mode

---

## Verify Solution: P2P and F2P Node IDs

The platform's Verify Solution step enforces strict **P2P** (pass-to-pass) and **F2P** (fail-to-pass) node ID checks. Both sets are derived from the JUnit XML output of `./test.sh base` and `./test.sh new`.

| Term | Meaning | Source |
|---|---|---|
| **P2P** (pass-to-pass) | Tests that must pass both without and with the solution patch | `./test.sh base` passing tests |
| **F2P** (fail-to-pass) | Tests that must fail (or not be collected) without the patch and pass after | `./test.sh new` target tests |

Rules:

1. **P2P node IDs must be non-empty** — `./test.sh base` must collect and pass at least one test.
2. **F2P node IDs must be non-empty** — `./test.sh new` must collect and pass at least one test after the solution is applied.
3. **P2P and F2P must not overlap** — a test node ID cannot appear in both sets. A new test must not already pass on the base commit.
4. **Without solution patch:** all P2P tests pass; all F2P tests fail or are not collected.
5. **With solution patch:** all P2P tests pass (no regressions); all F2P tests pass.

What this means in practice:

- Your new test file must be **excluded from base mode** (via `--ignore`, `--exclude`, or build tags). If `./test.sh base` collects and passes your new tests, those tests become P2P — they will never be F2P, and the F2P set will be empty, so Verify Solution fails.
- Your new tests must **fail for the right reason** on base (missing feature, not import error or syntax error). A collection failure (e.g., syntax error) counts as "not collected" and satisfies rule 4, but import errors that crash the entire suite can wipe out P2P tests too.
- Every test in `./test.sh new` output that passes post-solution becomes an F2P node. Every test in `./test.sh base` output that passes is P2P. Overlap (same node ID in both) is a hard fail.

Quick validation:

```bash
# Run base (no patches applied yet)
./test.sh --output_path /tmp/base.xml base
# P2P = all <testcase> nodes with no <failure>/<error> child — must be > 0

# Apply test.patch only (no solution), run new mode
git apply test.patch
./test.sh --output_path /tmp/new_nosol.xml new
# F2P candidates — all must FAIL or not appear here

# Apply solution.patch too, run new mode
git apply solution.patch
./test.sh --output_path /tmp/new_sol.xml new
# F2P = all passing <testcase> nodes — must be > 0, must not overlap with P2P set
```

### Harbor oracle ("Harbor oracle did not pass")

The Verify step's Harbor oracle reconciles the P2P/F2P node IDs and can report `harbor_oracle_failed` even when `baselinePassed` AND `newTestsPassed` are both true. Two causes seen on a Go submission (sh-printf-formats, mvdan/sh):

- Duplicate node IDs. Identically named tests in different packages (e.g. Go's `Example`) collapse to one node ID when the JUnit `classname` is a fixed string, so the oracle cannot map P2P/F2P. Make node IDs unique by qualifying them with the test's package (Go: `go test -json`, emit `classname=<package>`).
- Too many P2P tests. Running the whole module in base mode produced ~17900 P2P node IDs; the platform caps/truncates the list (~8000) and cannot reconcile it. Scope base mode to the changed package and its importers, not the entire module (`go build ./...` already compile-checks the rest).

Diagnose from the raw JSON: `harborOraclePassed`, `failedAssertion`, and the `passToPassTests` / `failToPassTests` lists (size, truncation, duplicates, and P2P-vs-F2P overlap).

---

## test.sh must NOT early-exit (the #1 mechanics mistake)

**A failing test command must not kill test.sh before the XML is written.** This is the single most common test.sh bug and it silently breaks p2p/f2p.

- **DON'T use `set -e`.** With `set -e`, the FIRST failing test command (or the first non-zero exit — which is EXPECTED in `new` mode and on any real base failure) aborts the script, so every later test group never runs and its cases never reach the JUnit XML. The platform then sees missing p2p/f2p nodes and rejects. Use **`set -uo pipefail`** (no `-e`), run EVERY test group, capture each group's status (`${PIPESTATUS[0]}` after a `| go-junit-report`/`| tee` pipe), keep the worst status in a `STATUS` variable, emit the XML at the END, then `exit "$STATUS"`. This is the approved frostdb pattern.
- **No fail-fast flags on the runner either** (`-x`/`--exitfirst`/`--failfast`/`-failfast`) — the platform needs EVERY test result, not just the first failure.
- **The exit code still matters:** run all tests, but return non-zero if any failed (so `new` mode fails on base, `base` mode passes). Compute it from the captured statuses, not from `set -e`.
- **Green-in-JUnit-but-shouldn't-be:** if a test crashes/errs in a way the runner swallows, or a `|| true` masks a real failure, the XML can read all-pass when it isn't. Only mask a command's exit for the XML-conversion step (`go-junit-report ... || true`), never for the test run itself; make a genuine failure surface as a `<failure>` in the XML.
- **Compile / integration failure (statically typed langs):** when the target does not compile (e.g. `new` on base references new symbols), the runner emits ONE `[build failed]` node or an empty suite → the per-test names never appear → p2p/f2p can't reconcile. You MUST synthesize a JUnit `<testcase>` FAILURE for EACH expected test function (same `classname`, same names) so every f2p/p2p node id is present. See § build-failure fallback + § Verify Solution P2P/F2P above.

Skeleton (the safe shape):
```sh
set -uo pipefail
STATUS=0
run() { "$@" 2>&1 | tee -a "$LOG"; s=${PIPESTATUS[0]}; [ "$s" -ne 0 ] && STATUS=$s; }
run <test group 1>
run <test group 2>          # still runs even if group 1 failed
# ... convert $LOG to JUnit XML at $OUTPUT_PATH here (|| true only on the conversion) ...
exit "$STATUS"
```

---

## test.sh Templates by Language

### Python (pytest)

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"
[ -f .venv/bin/activate ] && source .venv/bin/activate

OUTPUT_PATH=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
MODE="${ARGS[0]}"

JUNIT_FLAG=""
[ -n "$OUTPUT_PATH" ] && JUNIT_FLAG="--junitxml=$OUTPUT_PATH"

case "$MODE" in
  base)
    python -m pytest tests/test_functional.py tests/test_dunders.py tests/test_slots.py tests/test_make.py -v $JUNIT_FLAG
    ;;
  new)
    python -m pytest tests/test_new_feature.py -v $JUNIT_FLAG
    ;;
  *)
    echo "Usage: ./test.sh {base|new}"
    exit 1
    ;;
esac
```

### TypeScript/Bun (single files)

```bash
#!/bin/bash
set -e

case "$1" in
  base)
    bun test test/lifecycle/after-handle.test.ts \
             test/lifecycle/before-handle.test.ts \
             test/lifecycle/derive.test.ts \
             test/lifecycle/error.test.ts \
             test/core/handle-error.test.ts \
             test/core/compose.test.ts
    ;;
  new)
    bun test test/lifecycle/new-feature.test.ts
    ;;
  *)
    echo "Usage: ./test.sh {base|new}"
    exit 1
    ;;
esac
```

### TypeScript/Bun (directory mode)

```bash
#!/bin/bash
set -e

case "$1" in
  base)
    bun test test/lifecycle/ test/core/ test/cookie/ \
             test/validator/body.test.ts \
             test/validator/query.test.ts
    ;;
  new)
    bun test test/mount/stream-handling.test.ts
    ;;
  *)
    echo "Usage: ./test.sh {base|new}"
    exit 1
    ;;
esac
```

### TypeScript/npm (monorepo)

```bash
#!/bin/bash
set -e

case "$1" in
  base)
    cd packages/happy-dom
    npm run test -- test/nodes/html-element/HTMLElement.test.ts
    ;;
  new)
    cd packages/happy-dom
    npm run test -- test/nodes/document/DocumentNewFeature.test.ts
    ;;
  *)
    echo "Usage: ./test.sh {base|new}"
    exit 1
    ;;
esac
```

### Go (build tags — CRITICAL)

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

case "$1" in
  base)
    go test -v ./...
    ;;
  new)
    go test -v -tags=featurename -run '^TestFeature' ./...
    ;;
  *)
    echo "Usage: ./test.sh {base|new}"
    exit 1
    ;;
esac
```

Go base mode uses `go test ./...` which automatically excludes files with build tags. New mode explicitly includes the tag.

### Rust — `cargo2junit` (DEFAULT since 2026-07 reviewer directive)

**A reviewer rejected the bash-regex placeholder (`<failure message="test failed"/>`, discards the libtest panic block) and directed "just use cargo2junit".** Use it for ALL new Rust subs. It also fixes a real bug in the bash-regex: grep-`test ... ok/FAILED` MISCOUNTS across multiple test binaries (one binary exiting early makes later tests report as phantom failures). Source: APPROVED nickel-1336. Full Docker + rationale: `DOCKER.md § ⚠️ Rust JUnit = cargo2junit`.

Dockerfile adds `cargo install cargo2junit` (lands in `/root/.cargo/bin`, on PATH for the agent, no chmod). test.sh:
```bash
#!/usr/bin/env bash
set -uo pipefail
export PATH="/root/.cargo/bin:$PATH"; export CARGO_INCREMENTAL=0; export RUSTC_BOOTSTRAP=1
MODE=""; OUTPUT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output_path=*) OUTPUT_PATH="${1#--output_path=}"; shift ;;
    --output_path)   OUTPUT_PATH="$2"; shift 2 ;;
    base|new)        MODE="$1"; shift ;;
    *)               shift ;;
  esac
done
MODE="${MODE:-base}"
TEST_JSON="$(mktemp)"; TEST_ERR="$(mktemp)"; STATUS=0
case "$MODE" in
  base) cargo test -p <crate> <existing-affected-targets> -- -Z unstable-options --format json --report-time --skip <new_test_mod> > "$TEST_JSON" 2> "$TEST_ERR"; STATUS=$? ;;
  new)  cargo test -p <crate> --test <new_target> <new_test_mod>  -- -Z unstable-options --format json --report-time                 > "$TEST_JSON" 2> "$TEST_ERR"; STATUS=$? ;;
esac
cat "$TEST_ERR" >&2
if [ -n "$OUTPUT_PATH" ]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  cargo2junit < "$TEST_JSON" > "$OUTPUT_PATH" 2>/dev/null || true
  if ! grep -q '<testcase' "$OUTPUT_PATH" 2>/dev/null; then
    sanitized=$( { cat "$TEST_ERR"; cat "$TEST_JSON"; } | tail -c 4000 | sed -e 's/]]>/]]]]><![CDATA[>/g')
    cat > "$OUTPUT_PATH" <<XMLEOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="cargo-test" tests="1" failures="1" errors="0">
    <testcase name="compilation" classname="cargo-test"><failure message="build failed"><![CDATA[${sanitized}]]></failure></testcase>
  </testsuite>
</testsuites>
XMLEOF
  fi
fi
exit $STATUS
```
Three load-bearing details: (1) `RUSTC_BOOTSTRAP=1` unlocks libtest `--format json` on the pinned stable compiler (nightly-only otherwise); (2) split streams — JSON to stdout for cargo2junit, progress to stderr (it chokes on non-JSON), exit code from cargo not the pipe (cargo2junit exits 1 on any fail but writes complete XML first); (3) build-fail fallback keeps the platform's "missing XML = unscored run" rule satisfied. NEVER `chmod -R a+rX /root` (breaks solve-time cargo perms).

### Rust — bash-regex (LEGACY — do NOT use for new subs)

> ⚠️ SUPERSEDED by cargo2junit above (reviewer-rejected the placeholder; also miscounts multi-binary). Kept only for reading / re-verifying the 4 historical Mars approveds that shipped it.

4 of 5 approved Mars problems used this. Copy verbatim, swap the new-mode test target.

```bash
#!/usr/bin/env bash
set -uo pipefail
export PATH="/root/.cargo/bin:$PATH"

MODE=""; OUTPUT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    base|new) MODE="$1"; shift ;;
    *) echo "Usage: ./test.sh [--output_path <path>] {base|new}"; exit 1 ;;
  esac
done
[ -z "$MODE" ] && { echo "Usage: ..."; exit 1; }

run_and_produce_junit() {
    local output_path="$1"; shift
    local test_output exit_code=0
    test_output=$("$@" 2>&1) || exit_code=$?
    echo "$test_output"
    local passed=0 failed=0 testcases=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^test\ (.+)\ \.\.\.\ ok ]]; then
            testcases+="    <testcase name=\"${BASH_REMATCH[1]}\" classname=\"cargo-test\" />"$'\n'
            ((passed++)) || true
        elif [[ "$line" =~ ^test\ (.+)\ \.\.\.\ FAILED ]]; then
            testcases+="    <testcase name=\"${BASH_REMATCH[1]}\" classname=\"cargo-test\"><failure message=\"test failed\"/></testcase>"$'\n'
            ((failed++)) || true
        fi
    done <<< "$test_output"
    # CRITICAL: build-failure fallback — fires when cargo crashes before any test runs
    if [ $((passed + failed)) -eq 0 ] && [ $exit_code -ne 0 ]; then
        local sanitized
        sanitized=$(printf '%s' "$test_output" | tail -c 4000 | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g')
        testcases="    <testcase name=\"compilation\" classname=\"cargo-test\"><failure message=\"build failed\"><![CDATA[${sanitized}]]></failure></testcase>"$'\n'
        failed=1
    fi
    mkdir -p "$(dirname "$output_path")"
    cat > "$output_path" <<XMLEOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="cargo-test" tests="$((passed + failed))" failures="${failed}" errors="0">
${testcases}  </testsuite>
</testsuites>
XMLEOF
    return $exit_code
}

case "$MODE" in
  base)
    run_and_produce_junit "$OUTPUT_PATH" cargo test --workspace \
      --lib --test calculator --test json --test grammar --test grammar_inline \
      --test implicit --test lists --test oneormore --test opt --test reporting \
      --test surround --test http --test sql --test toml \
      -- --skip quote
    ;;
  new)
    run_and_produce_junit "$OUTPUT_PATH" cargo test -p pest_meta --test <new_feature_tests>
    ;;
esac
```

**The build-failure fallback is non-negotiable.** Without it, when `cargo` crashes before tests run, JUnit XML is empty and the platform reports "No test suite results were found."

**`--skip quote` for pest** — pre-existing flaky test, justified. Combined with the `sed -i '1s/^/#![cfg(feature = "grammar-extras")]\n/' vm/tests/surround.rs` Dockerfile patch, works on every approved Mars problem.

### Deno

```bash
deno test tests/ --junit-path="$OUTPUT_PATH"
```
Note: `--reporter=junit` does NOT exist (only `pretty`, `dot`, `tap`).

For Deno, when tests fail due to missing exports on base commit, Deno produces empty JUnit XML (0 test cases) which the platform rejects. Fix: after deno exits non-zero, check if XML has no `<testcase>` entries and write synthetic failure XML (see `CLAUDE.md § Deno new-mode JUnit fallback`).

---

## JUnit XML by Language — Quick Reference

### Python (pytest) — built-in

```bash
python -m pytest tests/ -v --junitxml="$OUTPUT_PATH"
```

### TypeScript

**vitest** — built-in:
```bash
vitest run tests/ --reporter=junit --outputFile="$OUTPUT_PATH"
```

**jest** — install `jest-junit` in Dockerfile:
```bash
JEST_JUNIT_OUTPUT_DIR="$(dirname "$OUTPUT_PATH")" \
JEST_JUNIT_OUTPUT_NAME="$(basename "$OUTPUT_PATH")" \
  npx jest tests/ --reporters=jest-junit
```

**bun**:
```bash
bun test test/file.test.ts --reporter=junit 2>"$OUTPUT_PATH"
```

### Go — install `go-junit-report` in Dockerfile

```bash
RUN GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0
```

```bash
go test -v -count=1 ./pkg/... -timeout 10m 2>&1 \
  | go-junit-report -set-exit-code > "$OUTPUT_PATH"
```

The `-v` flag is required. Capture exit code separately to avoid pipe masking:
```bash
go test -v ... > /tmp/test_out.txt 2>&1
TEST_EXIT=$?
cat /tmp/test_out.txt | go-junit-report > "$OUTPUT_PATH"
exit $TEST_EXIT
```

**Build-failure fallback for compiled new tests (F2P node alignment).** In a statically typed language a new test that references new symbols will NOT compile on base (the symbols do not exist yet), so `go test new` exits with a *build* error before any test runs. `go-junit-report` then emits a single `[build failed]` node (or empties the suite), so the per-test node IDs never appear in base mode — and the platform takes the F2P set as the intersection of named nodes across base and solution, leaving it EMPTY, so Verify Solution fails. test.sh `new` must, when the build fails on base, synthesize a JUnit `<testcase>` FAILURE for EACH expected new test function, using the SAME `classname` (the `<package>` the report would emit post-solution) and the SAME test names, so every F2P node id present in the solution run is also present (as a failure) in the base run and the two sets align. This applies to Rust too — **⚠️ CORRECTED 2026-07-30 (lyon-arcs-join, platform "Verify Solution" rejection):** the single-node `compilation` placeholder (`run_and_produce_junit`, below) is NOT sufficient even for Rust. A real platform run failed with `"these tests are not in the regression set (p2p) or the new test set (f2p), and they're not skipped: cargo-test.compilation (failed)"` — the wrapper cross-checks the no-solution run's test-name set against the f2p list from the with-solution run, and a single synthetic `compilation` node does not match any real f2p name. Fix: in `new` mode specifically, when `cargo2junit` produces no `<testcase>` (build failed), synthesize one FAILURE `<testcase>` per actual `#[test]` function name from the new test file, with `classname=""` (matching cargo2junit's real output format for a Rust integration test binary — verified empirically, NOT `classname="cargo-test"`), each carrying the same captured error output. Hardcode the name list in test.sh (extracted via `grep -B1 '^fn ' <file> | grep -A1 '#\[test\]' | grep -oP '^fn \K\w+'`) since the script cannot discover test names dynamically before a successful compile. Keep the old single-node fallback for `base` mode only (a base-mode build failure is not expected in normal operation and does not need f2p-set alignment).

### Without JUnit XML at the given path
ALL agents get BASELINE_ERROR before any solve attempt. Required for ALL problems.

### Use built-in reporters, NOT custom XML (Principal Reviewer Rubric #2)

The platform depends on the XML for ALL per-test analysis. If builds fail or tests crash and no XML appears → blocker.

- **Use the framework's built-in reporter:** `pytest --junitxml`, `go-junit-report`, `jest-junit`, `vitest --reporter=junit`. NEVER roll your own XML-generation script — custom scripts silently miss build failures and produce misleading all-pass results.
- **Test it by deliberately breaking the build.** Introduce a compile error / syntax error in a source file, run test.sh, confirm the XML STILL appears with the failure recorded (not an empty file, not a missing file). A reporter that produces no XML on build crash = guaranteed BASELINE_ERROR on the platform.
- Rust: use `cargo2junit` (2026-07 reviewer directive; see `§ Rust — cargo2junit`). It parses libtest json into accurate per-test JUnit and preserves each failure block. Still emit a synthetic failure XML on cargo crash (the build-fail fallback in the snippet). The legacy bash-regex `run_and_produce_junit` is superseded — a reviewer rejected its placeholder and it miscounts multi-binary runs.

**The "one run missing XML" diagnostic (Elabyad 2026-04-12):** if ONE agent run reports "JUnit XML not found" but other runs have it correctly, **your test.sh doesn't handle crashes — it's the harness, not the platform.** That agent's solution did something that crashed the test phase before XML was written. Fix:
- Check the test log + that agent's solution diff: what crashed, why no XML?
- **Add guards in test.sh** — capture exit codes, and write a synthetic failure XML if the real one is absent after the test run. OR add **try-catch blocks in the tests** so a critical failure still lets the reporter flush XML.
- A build failure / crash / critical failure must STILL produce XML with the failure recorded — never a missing file. A missing XML = that run is unscored = reads as a harness defect.

---

## JUnit XML Crash Resilience

The platform requires JUnit XML for ALL per-test analysis. If builds fail or tests crash and no XML appears, every agent run fails with `test.sh did not produce JUnit XML`.

- Use the framework's **built-in** JUnit reporter (pytest `--junitxml`, vitest `--reporter=junit`, etc.). Custom shell parsers silently miss build failures.
- **Verify locally:** deliberately break the build, run `test.sh --output_path /tmp/x.xml new`, confirm XML has ≥1 `<testcase>` with a failure.
- **Exit non-zero on any test failure** — reviewers run `./test.sh <mode>; echo $?` expecting 0 on full-pass.
- Use `set -o pipefail` so piped runs propagate the first non-zero exit.
- Capture exit BEFORE post-pipe fallback: `code=$?` then `exit $code` at the end.
- **Rust:** the `cargo2junit` test.sh (above) handles all of this — including the build-failure fallback. Use it (NOT the legacy bash-regex).

---

## Multi-Target test.sh (Cross-Crate Features)

Plan multiple new test files from day one if any of these triggers fire:

1. Feature adds a new enum variant consumed by VM and code generator (Rust workspace)
2. Feature changes a generator function signature
3. Feature touches the runtime state machine
4. Feature crosses ≥3 crates that each have their own test target

**Approved Rust pest workspace pattern (3-target):**
| Test file | Catches |
|---|---|
| `meta/tests/<feature>_tests.rs` | AST/optimizer/validator unit logic |
| `vm/tests/<feature>.rs` (+ `.pest` grammar fixture) | VM interpreter parity |
| `derive/tests/<feature>.rs` (+ `.pest` grammar fixture) | Code-generator end-to-end |

References: pest-seq-rewriter, pest-error-recovery (both 3 test targets).

---

## Go Build Tags (Critical for Go Projects)

Go tests use build tags to separate new tests from existing ones. This is how `test.sh base` (running `go test ./...`) automatically excludes new tests.

### Test file header
```go
//go:build featurename

package mypackage
```

### test.sh new command
```bash
go test -v -tags=featurename -run '^TestFeature' ./...
```

### Why it works
- `go test ./...` without `-tags` skips files with build tags
- `-tags=featurename` includes only files with that tag
- `-run '^TestFeature'` further filters to specific test functions
- Clean isolation without modifying any existing files

---

## Test-First Helpers — Discover Forced Trait Bounds

**Write the test helper signatures BEFORE the spec.** The test helpers are the *real spec* — agents compile against them.

Example: pest-error-recovery's design proposed `recover()` could be `FnOnce + Clone` OR `Fn`. The test helper actually does:

```rust
fn parse_recover<F1, F2>(input: &str, primary: F1, mut sync: F2) -> ...
where F1: FnOnce(...) -> ..., F2: FnMut(...) -> ...
{
    state.recover(rule, |s| primary(s), |s| sync(s))
    //                                   ^^^^^^^^^ captures &mut sync → must be FnMut
}
```

**40% of agent runs (4/10) died on this trap.** Process:
1. Sketch test helper signatures first
2. Walk through what bounds those helpers force on the API under test
3. Write the spec to match the bounds the helpers force
4. List "agent picks wrong trait bound" as a real trap if forced but not obvious

Apply to: every Rust problem with closures, every TS problem with generics, every Python problem with `__init__` signatures or dataclass kwargs.

---

## Test-Description Alignment (#1 Review Criterion)

**Every test must trace back to the description. Every described behavior must be tested.**

- For each test → behavior must be in the description
- For each described behavior → there must be a test
- Tests must use EXACT API names from description
- 0–1 codebase-inferable requirements acceptable (visible in code, not in description)

### Examples

| Description says | Test does |
|---|---|
| `Subquery`, `OuterRef`, `Exists` (ormar) | `test_subquery_import_exists()`, etc. |
| "SchedulingDecision event must fire" (h2) | `test_scheduling_decision_event_emitted` checks `isinstance(e, h2.events.SchedulingDecision)` |
| "retry_allowed_methods" (httpx) | Tests POST retried when in set AND not retried when absent |
| "reject corruption" (canopy) | `TestSnapshotImport_RejectsCorruption` flips a byte, asserts error |

### What Gets Flagged

| Problem | Example | Fix |
|---|---|---|
| Surprise tests | Test checks CLI format not in description | Either add to description or remove test |
| Hidden requirements | Tests verify multiple backends but description mentions one | Add backends to description |
| Untested behaviors | Description says "cascading" but no cascade test | Add cascade test |
| Exact string matching | Test checks `"expected 2 arguments"` | Use error type check instead |

### How to Align

1. Write description first (or at least a draft)
2. For each sentence in description → plan at least 1-2 tests
3. After writing tests → re-read description, check every test has a home
4. If you find yourself writing a test for something not in description → either add to description or don't write the test

---

## FP Check (False-Positive Check) — MANDATORY final gate (admin 2026-07 sprint)

**Run it at the very END, after all agent runs, before submit. A clean FP check is required to submit.** The FP check inspects EVERY passing agent and confirms each one REALLY solved the task — i.e. actually met all the requirements, not just made the tests go green.

**The exact mechanism (Leonard, Shipd team):** your prompt says the agent must do A, B, and C — but your tests only test A and B. A passing agent meets A and B but not C → shows as a pass, but it didn't meet the prompt's requirements. That's what the FP check catches. **The guarantee: if you can map EVERYTHING in your prompt to a test, it will never flag.** So the FP check is the description→test direction of alignment, mechanically enforced:
- **test → description** (T5 / fairness): no test asserts anything the description doesn't state — no hidden requirements.
- **description → test** (FP check): no description requirement lacks a test — no untested requirements.
Build the requirement-coverage matrix BOTH ways before running anything (every description sentence → ≥1 test; every test → a description sentence) and the FP check passes by construction.

- **An FP flag = an agent passed your tests WITHOUT meeting a requirement.** That is NOT an agent problem; it is **a GAP IN YOUR TESTS.** Your tests were permissive enough (weak T3) to let an incomplete / wrong-but-plausible solution through.
- **Fix by STRENGTHENING the tests**, never by loosening the spec: add the discriminator assertion that the false-positive solution would fail (the exact requirement it skipped), then re-run. This is the T3 "strong tests" rule enforced automatically on the passing set.
- **Why it exists:** a passing agent that didn't truly solve the task means the problem is under-verified — a reviewer (or the reference-vs-agent divergence) would catch it later and revert. The FP check surfaces it before submit.
- **How to pre-empt it while writing tests (so the FP check passes first try):**
  - For every documented requirement, have at least one test that FAILS on a solution that omits ONLY that requirement (per-requirement discriminator). If no test isolates a requirement, an agent can skip it and still pass = future FP flag.
  - Assert on OUTPUT / STATE / raised exceptions, not on happy-path-only cases. Pair each behavior with a discriminator that a partial solution fails (see § Test design for difficulty).
  - Anti-cheat: hardcoded / stubbed / echo-the-example outputs must FAIL (generate expected values from the oracle over many + fuzzed inputs; never echo an expected row in the description).
  - Precedence via `not in`: where two rules could collide, assert the correct outcome appears AND the tempting-wrong one does NOT.
- **Token note:** the platform grants extra tokens to run the FP check; run it once at the end on a clean, final artifact (editing after any check marks it stale). If it flags, close the test gap and re-run.
- **Cost asymmetry between the two fix directions (2026-09-03).** Strengthening the test is a `test.patch` edit, so the batch re-grades through **Re-eval** at ~30% of batch price. Fixing the ambiguous description sentence is a `meta.md` edit, which invalidates the agents' solving work and needs a full fresh batch — roughly 3.3x the cost. **Take the fix the flag actually calls for, never the cheaper one:** an unintended requirement still gets deleted from the description, and a genuinely ambiguous sentence still gets rewritten. Do use the asymmetry for SEQUENCING — settle every description-side change in one round before paying for the batch, then iterate discriminators against re-eval. UNCONFIRMED on first use: whether the FP panel itself re-runs under a re-eval; check and record it in `CLAUDE.md § RULE UPDATE 2026-09-03`.

Relationship to the rest: FP check = the automated enforcement of T3 (strong tests) + S1 (solution must meet all requirements) against the AGENTS that passed. If your tests already pin every requirement with a discriminator, a clean FP check is automatic.

**Why an FP invalidates the WHOLE submission, not just that run (Shipd team, 2026-07):** the DATA POINT is the submission environment — prompt + tests + repo. Agent runs only VALIDATE that the environment is correct and difficult/learnable. A passing agent that isn't a "real" pass means the VERIFIERS (your tests) **or the PROMPT (your description)** are wrong — so the whole datapoint is invalid. There is no "scratch that one run" path; the fix is always to ALIGN tests ↔ description:
- Weak test → add the discriminator the false pass exploited (strengthen T3).
- Ambiguous/misaligned description → a divergent-but-passing interpretation means the prompt allowed it; fix the sentence so the spec admits one reading (P4), don't only patch the test.
- **Catch it EARLY with the Test Fairness "light bulb" (💡) pre-check** — it matches the prompt against the tests and flags potential coverage gaps BEFORE any agent runs. **Filter its output: some suggestions are noise, some are TRUE gaps** — add tests only for the true gaps. Doing this triage early saves the much slower agent-runs + FP-panel iterations. The FP check is the final confirmation on real completed passes.
- **The fix direction is TWO-WAY (Leonard):** an FP flag means a gap in the TESTS (requirement C untested → add the discriminator) **OR a gap in the PROMPT (requirement C was never really intended → REMOVE it from the description).** Don't reflexively add tests for a requirement you don't actually want — deleting the unintended sentence is an equally valid fix and keeps the exam honest.
- **The exam mindset:** you are writing an exam for the LLM AND grading it. A good exam has tough problems AND a fair, complete way to validate that a passing student really met the goals. The skill that minimizes iterations = matching prompt to tests completely, both directions.
- **Cross-check against your own solution too**: walk the requirement-coverage matrix (description requirement → solution code → test). Breaking the solution into requirement-chunks exposes both test gaps AND unstated requirements — closes FP gaps and pre-empts unfairness flags in one pass (same matrix as the correlated-blind-spot check).
- The FP check is **mechanical and deterministic** (unlike the subjective checks): tests+prompt aligned = it passes. Getting FP-flagged repeatedly = a process problem, not bad luck.

---

## Test Quality Rules

### MUST do
- Descriptive test names (self-documenting, replace comments)
- Test via **public APIs** — never test internal methods or private state
- Tests run independently in any order (no shared state)
- Deterministic results (no timing deps, no randomness)
- Follow project's existing test conventions
- Use same test framework as repo
- Put tests in correct directory (match repo structure)
- Make test.sh executable (`chmod +x`, mode 100755 in patch — Windows: `git add --chmod=+x test.sh` BEFORE diff; verify `grep "new file mode" test.patch` shows `100755`)
- **Test error paths**, not just happy paths
- Split tests into **focused files** per package/module (match repo's test organization)
- **A correct but different implementation would still pass** all your tests

### MUST NOT do
- Comments anywhere (biggest AI flag — if repo tests have no comments, yours shouldn't either)
- Debug statements (`console.log`, `print`, `fmt.Println`)
- `--bail` flag (all tests must run even if one fails)
- Exact error message matching (use error types instead)
- Magic numbers without context
- Hardcoded expected values for dynamic behavior
- Tests that depend on execution order
- Tests that check implementation details
- Exact interleaving/ordering assertions unless spec requires it
- Weak assertions that pass with empty/wrong results
- Assertions that only check **"no crash"** without verifying output
- **Unused code or dead test helpers** — remove any helper functions not called by tests
- Tests using **solution-specific helpers** (methods/functions added by solution that don't exist in base code)
- **Test patch containing solution code** — test.patch must ONLY have test files, never solution files
- **Misleading test names** — test name must match what it actually tests
- **Implementation-specific tests** — tests should not be tied to one specific implementation approach

> **Note on mocks:** Mocks with many stub methods are acceptable if needed to satisfy an interface requirement. Not a red flag.

---

## Test Patterns by Language

### Python (pytest)

```python
import pickle
import pytest
import attr


@attr.s(auto_exc=True, kw_only=True)
class KwOnlyException(Exception):
    field: int = attr.ib()


class TestPicklingKwOnlyExceptions:
    def test_roundtrip_basic(self):
        exc = KwOnlyException(field=42)
        restored = pickle.loads(pickle.dumps(exc))
        assert restored.field == 42

    def test_roundtrip_preserves_type(self):
        exc = KwOnlyException(field=1)
        restored = pickle.loads(pickle.dumps(exc))
        assert type(restored) is KwOnlyException

    def test_empty_field_roundtrip(self):
        exc = KwOnlyException(field=0)
        restored = pickle.loads(pickle.dumps(exc))
        assert restored.field == 0
```

**Key patterns:**
- No comments
- Descriptive method names replace comments
- Test classes group related tests
- setUp/tearDown for resource management
- Use project's own fixtures/helpers

### TypeScript/Bun (describe/it)

```typescript
import { describe, expect, it } from 'bun:test'
import { Elysia } from '../../src'

describe('mount() with ReadableStream handling', () => {
    it('Should handle POST request with JSON body in mount()', async () => {
        const app = new Elysia({ aot: false })
            .mount('/api', async (request: Request) => {
                const body = await request.json()
                return new Response(JSON.stringify(body))
            })

        const res = await app.handle(
            new Request('http://localhost/api', {
                method: 'POST',
                body: JSON.stringify({ test: 'data' }),
                headers: { 'Content-Type': 'application/json' }
            })
        )

        expect(res.status).toBe(200)
        const data = await res.json()
        expect(data).toEqual({ test: 'data' })
    })
})
```

### TypeScript (Async API + Events)

```typescript
it('dispatches change event on set', async () => {
    const listener = vi.fn();
    window.cookieStore.addEventListener('change', listener);
    await window.cookieStore.set('test', 'value');
    expect(listener).toHaveBeenCalledTimes(1);
    const event = listener.mock.calls[0][0];
    expect(event.changed).toHaveLength(1);
    expect(event.deleted).toHaveLength(0);
})
```

### TypeScript (Strict Type Assertions)

```typescript
it('domain property is always string type', async () => {
    await window.cookieStore.set('typeCookie', 'val');
    const cookie = await window.cookieStore.get('typeCookie');
    expect(typeof cookie.domain).toBe('string');
    expect(cookie.domain).not.toBeNull();
})
```

### Go (build tags + JavaScript VM)

```go
//go:build weakref

package goja_test

import (
    "testing"
    "github.com/dop251/goja"
)

func TestWeakRef_BasicDeref(t *testing.T) {
    vm := goja.New()
    _, err := vm.RunString(`
        var obj = {name: "test"};
        var ref = new WeakRef(obj);
        if (ref.deref() !== obj) {
            throw new Error("WeakRef.deref() should return the target");
        }
    `)
    if err != nil {
        t.Fatal(err)
    }
}

func TestWeakRef_RequiresObject(t *testing.T) {
    vm := goja.New()
    _, err := vm.RunString(`
        try {
            new WeakRef(42);
            throw new Error("Should have thrown TypeError");
        } catch (e) {
            if (!(e instanceof TypeError)) {
                throw new Error("Expected TypeError, got " + e);
            }
        }
    `)
    if err != nil {
        t.Fatal(err)
    }
}
```

**Key Go patterns:**
- Build tag on first line (`//go:build featurename`)
- Test in `_test.go` file in correct package
- Use `t.Fatal(err)` for errors, `t.Fatalf()` for mismatches
- No comments (even in JS string literals — use descriptive error messages)

### Go (Hook/Lifecycle)

```go
//go:build featurename

package mypackage

func TestFeature_BasicBehavior(t *testing.T) {
    result, err := executeFeature(input)
    if err != nil {
        t.Fatal(err)
    }
    if result != expected {
        t.Fatalf("expected %v, got %v", expected, result)
    }
}
```

### Algorithm Edge Cases

```typescript
it('intersection should be commutative', () => {
    const expr1 = CronExpressionParser.parse('*/10 9-17 * * 1-5');
    const expr2 = CronExpressionParser.parse('0,30 10-14 * * 2-4');
    const result1 = expr1.intersection(expr2);
    const result2 = expr2.intersection(expr1);
    expect(result1).not.toBeNull();
    expect(result2).not.toBeNull();
    const testDates = [new Date(2024, 0, 2, 10, 0, 0)];
    for (const date of testDates) {
        expect(result1.includesDate(date)).toBe(result2.includesDate(date));
    }
})
```

---

## DO / DON'T Quick Reference

**DO:**
- Test via public APIs only (never internal methods/state)
- Tests run independently in any order (no shared state)
- Deterministic (no timing, no randomness, fixed seeds if needed)
- Test error paths AND happy paths
- A correct but different implementation would still pass

**DON'T:**
- Debug statements (`console.log`, `print`, `fmt.Println`)
- `--bail` flag
- Exact error message matching (use error types or substring)
- Weak assertions (`rejects.toBeDefined()`, `len > 0`, `is_ok()`)
- Vacuously true assertions (precondition never fires)
- Discarded results (`_ = value` in Go)
- Tests using solution-specific helpers (methods that don't exist in base)
- Test patch with solution code
- Bypass real entry point (test through CLI flag / API endpoint, not internal constructor)
- Correlated blind spots between solution and tests (trace each requirement to BOTH)
- Missing negative tests for guard conditions ("only when X" → test both fires AND doesn't fire)

---

## Avoiding Flaky Tests

| Pattern | Fix |
|---|---|
| Time-based with short delays | Use `sleep(2.0)` or explicit `os.utime()`, not `sleep(0.1)` |
| Async assumes immediate completion | Wait for conditions explicitly |
| Random values | Use fixed seeds |
| External state (network, FS outside repo, env vars) | Mock or set in Dockerfile |
| Ordering-dependent (map/set iteration, parallel races) | Sort before asserting; remove inter-test shared state |

### Time-based tests

```python
# BAD: too short, filesystem granularity issues
time.sleep(0.1)
assert mtime2 > mtime1

# GOOD: generous delay
time.sleep(2.0)
assert mtime2 > mtime1

# BETTER: explicit timestamps
os.utime(file1, (time.time() - 100, time.time() - 100))
os.utime(file2, (time.time(), time.time()))
```

### Async tests

```typescript
// BAD: race condition
const result = await asyncFunction()
expect(result.ready).toBe(true)

// GOOD: wait for condition
await Bun.sleep(100)
const result = await asyncFunction()
expect(result.ready).toBe(true)
```

### Random values

```python
# BAD: non-deterministic
import random
values = [random.randint(1, 100) for _ in range(10)]

# GOOD: fixed seed
import random
random.seed(42)
values = [random.randint(1, 100) for _ in range(10)]
```

---

## Excessive Test Count + Parametrization

Reviewers flag excessive test counts. Watch for:

| Sign | Problem | Fix |
|---|---|---|
| 72+ tests for one feature | Likely redundant or too granular | Consolidate to 25-50 |
| 7 tests for each string escape char | Repeated pattern | Use parameterized tests |
| New test file is 5x longer than repo's test files | Mismatched style | Match repo's test density |
| Many tests verifying same assertion differently | Redundant | Keep the best one |

### Use parametrization when possible

**Python:**
```python
@pytest.mark.parametrize("input,expected", [
    ("a", "A"),
    ("hello", "HELLO"),
    ("", ""),
])
def test_uppercase(input, expected):
    assert uppercase(input) == expected
```

**TypeScript (Bun/Jest):**
```typescript
it.each([
    ['a', 'A'],
    ['hello', 'HELLO'],
    ['', ''],
])('uppercases %s to %s', (input, expected) => {
    expect(uppercase(input)).toBe(expected)
})
```

---

## Test Patch Rules

1. Valid git patch — applies cleanly to base commit
2. ONLY contains test files + test.sh — no solution code
3. Doesn't conflict with solution.patch (apply in either order)

`solution.patch` CAN include test changes if old tests were broken and need fixing — but those edits go in `solution.patch`, not `test.patch`.

12 of 14 approved test.patches contain exactly 2 files (test.sh + one test file). Multi-target Rust pest problems contain 4+ files because they span meta + vm + derive crates.

---

## Helper Functions / Test Infrastructure

All approved patches use helper functions. Examples by language:

| Language | Approved helpers |
|---|---|
| Rust | `expect_expr()`, `expect_error(input, substring)`, structural comparison helpers, builder builders |
| Python | Fixtures, factory functions (`AssetDependencyHealthState.from_upstream_statuses()`), inline mock transports |
| Go | `testStore()`, `flipOneByteCopy()`, table-driven `for _, tc := range testCases` |
| TS | `initRepo()`, `runBump()`, mock transports, `setupWorkspaces()` |

**Models/schemas:** Define directly in the test file. Tests must be self-contained.

**Guard clauses (optional):** Fail clearly on base when testing a new export:
```python
Retry = getattr(httpx, "Retry", None)
if Retry is None:
    pytest.fail("httpx.Retry is not implemented")
```

**Assertion messages (Rust):** Put messages on every assert: `assert_eq!(count, 1, "Should have exactly one gradient after merging");`

---

## Real Approved Stats

Data from approved test patches:

### Bug Patches
| Problem | Tests | Patch Lines |
|---|---|---|
| elysia-1486 | 19 | 895 |
| elysia-1618 | 22 | 605 |
| opentelemetry-6190 | 8 | 584 |
| elysia-1474 | 22 | 575 |
| elysia-1504 | 18 | 546 |
| elysia-1445 | 19 | 542 |
| khal-1406 | 11 | 493 |
| attrs-734 | 24 | 341 |
| happy-dom-1283 | 16 | 168 |

### Feature Request Patches
| Problem | Tests | Patch Lines |
|---|---|---|
| dooit-completion | 62 | 1522 |
| sh-1165 | 57 | 1375 |
| sh-diff | 69 | 929 |
| cron-parser-dst | 56 | 734 |
| goja-weakref | 44 | 765 |
| goja-iterator-helpers | 42 | 681 |
| happy-dom-namespace | 61 | 483 |
| happy-dom-closewatcher | 35 | 468 |
| wazero-callgraph | 21 | 877 |
| wazero-debug | 20 | 536 |

**Observations:**
- Bug patches average **~18 tests, ~490 lines**
- Feature request patches average **~35 tests, ~750 lines**
- Feature requests need more tests because they define new API surface
- Test patches are consistently larger than solution patches

---

## Near-Miss Test Design (The Sweet Spot)

The best problems have agents passing 90%+ of tests but failing on 1–2 edge cases:

| Problem | Typical Score | What Catches Them |
|---|---|---|
| bumpp | 105–106/107 | Merge subject text filtering, BREAKING CHANGE body parsing |
| canopy | 13/14 (×4 agents) | Version 0 validation — same single test caught 4 agents |
| httpx | 84/91 (×4 agents) | All trio async tests — agents used `asyncio.sleep()` directly |
| ormar | 38/39 | Unbounded keyword filter path |
| oxvg | 19–20/21 | Mixed href/xlink:href equivalence |
| pest-inliner | 67/68 (best) | count_references missing InlinedRule in multi-pass |
| pest-seq-rewriter | 84/85 | Opt(x) treated as non-Opt copy |

Gold standard: agents consistently get 19/21 or 105/107.

---

## Agent-Proven Test Strategies

> Agents self-author tests that give false confidence. Your hidden test harness is what separates pass from fail.

### Don't Test Display When Repo Patterns Conflict

When adding new enum variants that resemble existing ones, agents copy the existing Display format. If your tests expect a different format, agents who follow the repo pattern get punished unfairly.

**Approved precedent**: pest-normalizer adds `NormalizedSeq` — similar to `Seq` — but specifies NO Display format and has ZERO Display tests.

**Rule**: If a new variant's natural Display format would conflict with an existing variant's pattern, either match the existing pattern or don't test Display at all.

### Baseline Regression Traps

Existing test suites catch careless integration. Include ALL existing tests in `test.sh base`:

| Problem | Baseline Trap | Agents Caught |
|---|---|---|
| httpx | `test_exported_members` checks `__all__` consistency | 2 agents leaked imports from `from ._retry import *` |
| ormar | `FilterQuery.__init__` callers in delete paths | 1 agent changed signature without checking callers |

### Why Agent Self-Authored Tests Mask Gaps

Every failing agent wrote their own test file and validated against it. Their tests:
- Never covered the hidden edge cases (trio, version 0, merge subjects)
- Gave false confidence that the implementation was complete
- Tested the happy path but not the discriminating edge cases

Your hidden test harness MUST include tests that agents wouldn't think to write.

### Test design for difficulty (discriminators, not variants)

> **⭐ WHICH traps still bite the current agent cohort (with kill counts) + the fair re-hardening method: `HARDENING.md`.** This section covers test MECHANICS; HARDENING.md covers trap SELECTION (S/A/B arsenal, DEAD list) and the CONTRACT-STATED/FIX-HIDDEN axiom.

Difficulty comes from tests that an obvious implementation passes on the happy path but FAILS under real conditions — not from 30 near-identical variants of one transform (those are all solved together by one fix, so they add count without adding discrimination). Measured: test-count padding RAISES pass rate (findmyway 41→84 tests = 50%→80%; scryer +17 value-cases cost agents nothing).

**Compound, interacting tests over orthogonal axes.** Each test should force several documented behaviors to hold at once, so partial solutions break:

| Compound axis | What the test exercises together |
|---|---|
| Legacy + new format in one run | parser dispatches both, emits unified output |
| Valid + quarantined rows + summary counts | rows route correctly AND the count fields reconcile |
| Ordering by timestamp, not file order | sort key is the field, not arrival order |
| Rollback after a fatal failure | partial work is undone; no half-written state survives |
| Duplicate-ID first-valid-wins | dedup precedence is the documented one |
| Output mixing business + provenance fields | both field families present in the same record |

**Two tests per difficulty surface:** one the obvious impl passes (happy path) plus one DISCRIMINATOR it fails under real conditions (interaction, ordering, rollback, collision). Both tests MUST still FAIL on clean BASE (the feature is absent) — the "happy-path" one is the one a wrong-but-plausible solution passes, never the one that already passes on base. The discriminator is where the pass-rate band lives.

**Don't let the whole breadth suite hinge on ONE undiscoverable surface (deterministic-universal-miss = 0%-trap).** If EVERY fair run misses the SAME requirement (typically a breadth requirement where agents implement the obvious members of a behavior family and miss the rest), the absolute solvability floor is at risk even though each fail is "fair". Scattered difficulty (different agents fail different tests) is healthy; a suite where every fair run misses the same requirement risks 0%. De-trap by making that surface DISCOVERABLE in meta (name that the whole family, not only the obvious members, must observe the behavior) — a fair clarification of already-tested behavior, NOT difficulty-easing and NOT a new requirement; the implementation work and the scattered difficulties stay. Pair every breadth/exactness test family with a meta that names the surface the family hinges on.

**Assert on behavior, never on source text.** Assert outputs, state, raised exceptions — never whether the source contains a function name, an import, or a call. A correct-but-differently-structured solution MUST still pass; asserting on source structure ties the test to one implementation and breaks the solvability guarantee (at least one agent must pass). Apply this to every discriminator.

**Precedence via `not in`.** Where two documented rules could collide, assert BOTH that the correct outcome appears AND that the tempting-but-wrong one does NOT (`assert wrong not in result`, or `assert_eq!` on the resolved value plus a negative on the loser). The precedence itself must be documented in meta.md, or it is a hidden requirement.

**Closed-vocabulary + cheap invariant guards** so a partial solution fails MORE tests, tightening the score band toward the near-miss sweet spot:
- Schema / key-order assertions (exact field set, stable key order)
- Sort-order invariants (output monotonic on the documented key)
- Enum membership (every status value is in the documented closed set)

Each guard must still trace to a documented behavior — guards add discrimination, never hidden requirements.

**Anti-cheat.** A fabricated or stubbed output (empty file, hardcoded plausible value, echoing the meta.md example) MUST fail the suite:
- Keep hidden inputs and expected values inside `test.patch` — never echo a row of expected output in `meta.md`.
- Generate expected values from the external oracle over many inputs (including fuzzed) so a solution that hardcodes the single meta.md example fails on the unseen cases.

**Decimal half-up trap.** If the feature rounds, seed a half-way value where the spec's half-up diverges from Python/IEEE banker's (half-even) rounding. Use a value that genuinely discriminates: `2.5 -> 3` (half-up) vs `2` (half-even), or `0.125 -> 0.13` (half-up) vs `0.12` (half-even) at 2 dp. Do NOT use `2.675`: as an IEEE float it is `2.67499...`, so half-up and half-even AGREE on it and it catches no one. PRE-VERIFY any half-way seed discriminates — run both rounding modes locally and confirm they produce different outputs BEFORE committing the test.

These discriminators ride on top of the existing fail-on-base / no-regression contract (see "The Golden Rules" above and "Fail Rate Requirements" below): new-feature tests still fail on clean BASE for the right reason, write only to temp dirs, and leak no cross-run state.

---

## Fail Rate Requirements

- **New tests should fail on base code** — most new tests must fail on base commit
- Tests must fail for the **right reason** (missing feature, not unrelated errors)
- If tests pass without solution → they're not testing the bug
- If tests fail due to `undefined function` instead of wrong behavior → wrong reason

**Partial failure acceptable:** Some tests passing in `./test.sh new` mode without the solution is OK if those passing tests are backwards-compatibility/regression tests. But if most tests pass pre-solution, reviewers will flag: *"Only 2 of 22 new tests fail at base commit. Tests should demonstrate the bug more clearly."*

### How to verify
```bash
# On base code (before solution)
./test.sh base    # PASS — environment works
./test.sh new     # FAIL — all new tests fail (expected)

# After applying solution
./test.sh base    # PASS — no regressions
./test.sh new     # PASS — solution fixes everything
```

---

## Validate

```bash
# Before solution
./test.sh --output_path /tmp/base.xml base    # PASS
./test.sh --output_path /tmp/new.xml new      # FAIL (expected)

# After solution
./test.sh --output_path /tmp/base.xml base    # PASS (no regressions)
./test.sh --output_path /tmp/new.xml new      # PASS

# Both XMLs must have <testcase> count > 1
grep -c '<testcase' /tmp/base.xml /tmp/new.xml
```

---

## Review Checklist (Items 8–15 of 21)

Reviewers evaluate tests against these exact criteria:

| # | Criterion | Pass | Fail |
|---|---|---|---|
| 8 | Tests highlight missing/incorrect behavior | Fail on base, pass after fix | Already pass without changes |
| 9 | Tests are deterministic | Stable across runs | Depend on timing/randomness |
| 10 | Assertions verify correct output | Check precise outcomes | Only weak conditions |
| 11 | Tests validate behavior, not internals | Assert via public APIs | Inspect private state |
| 12 | Tests follow repo structure | Match naming/folder conventions | Random folders or different framework |
| 13 | Tests cover behavior and edge cases | Success and failure paths | Only happy path |
| 14 | Test suite is concise | Focused and non-redundant | Bloated or repetitive |
| 15 | Tests don't check unspecified behavior | Map to problem spec | Extra expectations not in spec |

---

## Common Mistakes (BAD/GOOD Code)

### Comments in tests
```python
# BAD — biggest AI flag
def test_basic_case(self):
    # Test that the function returns the expected result
    result = function(input)
    assert result == expected

# GOOD — descriptive name replaces comment
def test_function_returns_expected_for_valid_input(self):
    result = function(input)
    assert result == expected
```

### Testing implementation instead of behavior
```typescript
// BAD — tests internal structure
expect(result._internalMap.size).toBe(3)
expect(result.__proto__.constructor.name).toBe('MyClass')

// GOOD — tests observable behavior
expect(result.getAll()).toHaveLength(3)
expect(result instanceof MyClass).toBe(true)
```

### Hardcoded error messages
```typescript
// BAD — fragile, breaks if message changes
expect(fn).toThrow("Expected 2 arguments but got 1")

// GOOD — tests error type
expect(fn).toThrow(TypeError)
// OK — tests partial message if description specifies it
expect(fn).toThrow(/2 arguments/)
```

### Wrong test framework
```
BAD: Using bun test when repo uses jest
BAD: Using vitest when repo uses mocha
BAD: Using unittest when repo uses pytest
GOOD: Match repo's existing test framework exactly
```

### Wrong test directory
```
BAD: Creating test/ when repo uses __tests__/
BAD: Creating tests/ when repo uses test/
BAD: Creating spec/ when repo uses test/
GOOD: Check repo's existing test location and match exactly
```

---

## Pre-Submission Checklist

**test.sh:**
- [ ] `#!/bin/bash` or `#!/usr/bin/env bash`
- [ ] **`set -uo pipefail` (NOT `set -e`)** — `set -e` early-exits on the first failing test command, so remaining tests never run and never reach the XML (missing p2p/f2p nodes). Capture exit codes, run EVERY test group, emit XML at the END, then `exit $STATUS`. See § test.sh must not early-exit.
- [ ] Position-independent arg parsing (case loop, not `$1` for mode)
- [ ] Accepts `--output_path <path>`
- [ ] Produces JUnit XML at given path
- [ ] Has `base` and `new` modes
- [ ] Mode `base` runs ALL existing tests
- [ ] Mode `new` runs ONLY new test files
- [ ] Build-failure fallback present (Rust)
- [ ] `mkdir -p "$(dirname "$OUTPUT_PATH")"` present
- [ ] Exit code propagates correctly (no pipe masking)
- [ ] No AI comments
- [ ] Executable (mode 100755 in patch — Windows: `git add --chmod=+x test.sh` BEFORE diff; verify `grep "new file mode" test.patch` shows `100755` for test.sh)

**test.patch:**
- [ ] Valid git patch — applies cleanly to base commit
- [ ] Contains only test.sh + test file(s) — no solution code
- [ ] Doesn't conflict with solution.patch (apply in either order)
- [ ] test.sh entry has `new file mode 100755` (NOT 100644) — platform invokes `./test.sh` directly

**Test file:**
- [ ] Same framework as repo
- [ ] Conventional repo location
- [ ] 4-block layout: imports → builders → assertion helpers → tests
- [ ] Scenario-encoded snake_case names
- [ ] All new tests FAIL on base for the right reason
- [ ] All new tests PASS with solution
- [ ] All base tests PASS (no regressions)
- [ ] Comment style matches repo convention
- [ ] No AI-generated comments
- [ ] No debug statements
- [ ] No shared state between tests
- [ ] Every test maps to description
- [ ] Every described behavior has a test
- [ ] Public APIs only (no internal state inspection)
- [ ] Substring-match for errors (not exact-match on full message)
- [ ] No redundant tests (parametrize repeated patterns)
- [ ] No `--bail` flag
- [ ] Tests run offline
- [ ] No discarded results (`_ = value` in Go)
- [ ] Coverage complete: every behavior, every public API, every solution branch, every edge case


## ⚠️ PRE-SUBMIT — golden-file fixtures: ERROR cases must carry NO expected-output file

Added 2026-07-30 after a platform precheck FAIL on `customasm-ruledef-disassembly`
(test_patch_alignment ERROR). Costs nothing to check; invisible to a green local suite.

**The failure mode.** In golden-file harnesses (customasm's `; command:` / `; output:` fixtures,
and any harness that compares a generated file against a committed one), an ERROR fixture declares
`; error: ...` and the harness then IGNORES any expected-output file in that directory. So a stale
`out.txt` left over from an earlier run sits there forever: the local suite stays green and never
reads it.

The platform's alignment checker DOES read it, as a stated expectation. On customasm it found
`err_ambiguous_decoding/out.txt` containing `0000: one` while the description said "a genuine tie
is reported rather than guessed" and flagged a direct contradiction between tests and prompt.

**Where stale goldens come from:** running the binary by hand to inspect behavior BEFORE the final
semantics exist, then implementing the real behavior and never deleting the artifact.

**Pre-submit check (run for any golden-file harness):**

```bash
# every fixture dir that declares an error must contain no expected-output file
for d in tests/<suite>/*/; do
  if grep -q '; error:' "$d"/*.asm 2>/dev/null; then
    found=$(ls "$d" | grep -vE '\.asm$')
    [ -n "$found" ] && echo "STALE GOLDEN in $d: $found"
  fi
done
```

Generalizes to any language: an expectation file inside a directory whose test expects a failure is
either dead weight or a contradiction. Delete it.

**Related, same submission:** randomizing only the TOP test directory is NOT enough for the
predictable-names precheck. `tests/<random>/ok_flat/main.asm` still fails, because the checker
predicts the full path and `ok_flat/main.asm` is guessable. Randomize the per-fixture directory AND
the leaf filenames (`m_<hex>.asm`, `o_<hex>.txt`), rewriting any in-file command line that names
them.
