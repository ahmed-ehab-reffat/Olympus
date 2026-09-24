# PLAYBOOK — Evidence-Based Patterns from 13 Approved Problems

Forensic synthesis of approved Mars + Olympus problems with full agent-run data. Every claim cites a specific approved problem.

> **⭐ RUN `PICK-FILTER.md` FIRST** — the 8 pre-pick gates (behavioral-f2p-gap [decisive] · saturation · uniform-wrap · LOC-ceiling · cold-not-live · reproduce-on-base · dedup-all-dirs+judge-verdict · defined-behavior) + Query-10 codebase-brainstorm sourcing. A candidate that fails any gate is dead — do not author it. build-measure + reproduce-trap are NECESSARY-NOT-SUFFICIENT; the 10-run Nova/Orion/Castor BATCH is the ONLY difficulty oracle.

## Mars Solid Approveds (5)

| # | Problem | Files | +LOC | Tests | Desc Words | Pass Rate | Shape |
|---|---|---|---|---|---|---|---|
| 1 | pest-extended-skip | 8 | 340 | 102 | 183 | **43.8%** | D-change |
| 2 | pest-factorizer-fixpoint | 3 | 220 | 92 | 137 | **25.0%** | A2 |
| 3 | pest-unused-rule-elim | 3 (2 new) | 377 | 160 | 241 | **53.8%** | B |
| 4 | pest-validator-hardening | 1 | 358 | 39 | 91 | **23.5%** | C |
| 5 | lightningcss-selector-simplify-fixpoint | 3 | 167 | 68 | 107 | **10.5%** | A1 |

**Median Mars Solid:** 3 files, 340 LOC, 92 tests, 137 description words. Pass rate range: 10.5–53.8%.

## Olympus Approveds (9) — with agent run data

| # | Problem | Files | +LOC | Tests | Pass Rate | Best Agent | Shape |
|---|---|---|---|---|---|---|---|
| 6 | dagster-dep-health | 9+ | ~600 | 162 | 30%* (hinted) | Orion (2/2) | O-Composite-extend |
| 7 | pest-error-recovery | 15 (4 crates) | ~400 | 126 | 21.4% | Orion-alone (2/2) | D-new |
| 8 | pest-seq-rewriter | 4 | ~413 | 103 | 15.4% | Vega (2/6) | O-Pipeline-hard |
| 9 | pest-dispatch | 6 | ~532 | 62 | **8.3%** | Mixed | O-Algorithm-correctness |
| 10 | pest-charclass | 5 | ~433 | 104 | 25.0% | Vega (3/5) | O-Pipeline-easy |
| 11 | pest-normalizer | 4 | ~414 | 57 | **0%** (bypass) | None | O-Trap (historical) |
| 12 | pest-inliner | 4 | ~379 | 68 | 10.0% | Orion-alone (1/1) | O-Algorithm-coverage |
| 13 | goja-using-declarations | 12 | ~366 | 73 | 16.7% | Vega (3/5) | O-Composite-add |
| 14 | yaegi-execution-tracer | 5 | ~441 | 54 | 10% (2/20 Castor at Diamond eval → tier-downgraded to Olympus) | Mixed | O-Composite-add |
| 15 | yaegi-checkpoint-api | 8 | ~870 | 145 (128 interp + 17 cmd/yaegi) | 7% (1/14 Castor at Diamond eval → tier-downgraded to Olympus) | Castor (1/14) | O-Composite-add |

When this playbook contradicts an older guide, **this playbook wins**.

---

## TL;DR — The 10 Things That Got Them Approved

1. **Action-verb title**, 5–10 words, names specific subsystem ("Extend …", "Iterate …", "Add …", "Rewrite …").
2. **Plain prose meta.md, 90–240 words.** No markdown headers, no formulaic labels, no numbered lists.
3. **Backticks for new public API names only.** Never internal types or struct fields.
4. **Spell out canonical form** (sort order, associativity, dedup strategy) when tests use `assert_eq!` on structures. Kills 60% of fairness rejections.
5. **State new public API names explicitly.** Fairness > naturalness — if tests expect `validate_unused_rules`, name it.
6. **One new test file** with builder helpers + assertion helpers + scenario-encoded `#[test]` functions. **Cover every described behavior, every public API, every solution branch, every edge case.** No count target.
7. **Substring-match for error tests.** `expect_error(input, "alternative")`. Never `==` on full message.
8. **Solution: 170–380 LOC, 1–8 files, pure-function helpers extracted** (`is_always_failing`, `flatten`, `compute_reachable`).
9. **Dockerfile**: Python/JS/Go submissions ALWAYS use `olympus-base` (Pattern B). Rust workspaces use Pattern A (`mars-base` + chmod/symlink workaround) ONLY because olympus-base has a documented `/app/target` permission bug for multi-crate cargo builds.
10. **test.sh accepts `--output_path`** and emits JUnit XML with build-failure fallback. Runs full workspace base (`./...` for Go, `--workspace` for Rust); runs only new test file in `new` mode. **Strictly reject missing/multiple/unknown modes with exit 2** (Pattern 39) — silent defaults trigger Auto Review FAIL on V2-carryover.

---

## Pattern 1 — Description Anatomy

### Title

Every approved title starts with a verb in imperative mood, 5–10 words, names the specific subsystem.

| Approved Title | Verb |
|---|---|
| Extend Skip Recognition to Case-Insensitive and Range Delimiters | Extend |
| Iterate the Choice Factorizer with Suffix Folding and Nullable Guards | Iterate |
| Add Unused-Rule Detection and Dependency Queries to the Optimizer | Add |
| Extend Grammar Validator with Additional Classifications and Checks | Extend |
| Iterate Selector Simplification to a Fixpoint | Iterate |

**Anti-titles:** "Bug fix for issue #1380", "Fix the parser", "How to better handle XYZ", "PEST Validator".

### Body shape

Two micro-patterns:

**Pattern A — Single paragraph + dash bullets** (factorizer-fixpoint, lightningcss):
```
# [Title]
[2-3 sentences context + dash-list of rules / behavior bullets, all in one block.]
```

**Pattern B — Multi-paragraph staged** (extended-skip, unused-rule-elim, validator-hardening):
```
# [Title]
[Para 1: WHAT is added — names new types, enum variants, methods]
[Para 2: Behavior rules / normalization / sort order]
[Para 3: Edge cases or supplementary API]
```

### MUST include

1. **New public API names** — `SkipChoice`, `find_unused_rules`, `simplify_selectors_fixpoint`. Tests assert these exact names.
2. **Enum variants in plain meaning** — "with `Literal(String)`, `CaseInsensitive(String)`, and `CharRange(String, String)` variants". Describe the variant; don't declare its type.
3. **Canonical output form** — "Emit `Choice` subtrees in right-associated form" (factorizer). "Order Literal values lexicographically, then CaseInsensitive values by ASCII lowercase, then CharRange values by start codepoint" (extended-skip).
4. **Resolution / lookup rules** — "Resolve rule references through the grammar's rule map when checking non-failing or nullable" (factorizer).
5. **Edge case definitions** — "Single-character `CharRange` values degenerate to `Literal`" (extended-skip).
6. **Parallel APIs** — "Parallel `find_unused_optimized_rules`, … operate on `&[OptimizedRule]` with the same semantics" (unused-rule-elim).

### MUST NOT include

- `##` headers. Plain prose only.
- `Box<...>` type wrappers. Approved phrasing: "an `Expr::Skip(Vec<SkipChoice>)` variant" — yes. `Box<Expr>` wrapping — flagged.
- Code-instead-of-prose. Write "the rate is a decimal number," not `(float64)`.
- "tests verify that …" or any test framework / file name reference.
- Vague language ("properly", "correctly", "as expected").
- Snappy bullet list of instructions. Should flow naturally.
- External framing ("Pest is a parser library that …"). Drop the reader directly into the change.

### Blind-spot pre-empt sentence bank

Add the matching sentence to `meta.md` when applicable:

| Blind Spot | Pre-empt sentence |
|---|---|
| Rule-reference resolution | "Resolve rule references through the grammar's rule map when checking …" (factorizer) |
| Sort order ambiguity | "Order Literal values lexicographically, then CaseInsensitive values by ASCII lowercase, then CharRange values by start codepoint" (extended-skip) |
| Adjacent vs all-positions | "working on adjacent positions only so author-supplied alternative ordering is preserved" (lightningcss) |
| First/last-occurrence dedup | "deduplicated using ASCII case-insensitive comparison, keeping the first occurrence" (extended-skip) |
| Iteration termination | "iterates until no rewrites apply" (lightningcss); "iterate to a fixpoint" (factorizer) |
| Order of result list | "Results preserve the order rules appear in `rules`" (unused-rule-elim) |
| Parallel optimized API | "Parallel `find_unused_optimized_rules`, … operate on `&[OptimizedRule]` with the same semantics" (unused-rule-elim) |
| Compound order preservation | "Compound-selector component order is preserved exactly: `.x:is(.a)` stays `.x:is(.a)`" (lightningcss) |

### Word budget

| Tier | Sweet spot | Recommended cap | Hard cap (both tiers) | Notes |
|---|---|---|---|---|
| **Mars Solid** | 90–160 | **240** | **500** | 5 approved range: 91–241 (median 137). Above 240 still allowed if dense API surface |
| **Mars Strong** | 130–200 | 240 | 500 | OK higher when ≥6 distinct API surfaces |
| **Olympus** | ≤150 | **200** | **500** | AI checker enforces tighter trim, but absolute fail only at 500+ |

The 241-word `pest-unused-rule-elim` got approved because every word names an API surface (13 functions across 3 paragraphs).

---

## Pattern 2 — Test Anatomy

### File layout (one new test file at conventional location)

| Problem | New test file |
|---|---|
| pest-extended-skip | `meta/tests/extended_skip_tests.rs` |
| pest-factorizer-fixpoint | `meta/tests/factorizer_tests.rs` |
| pest-unused-rule-elim | `meta/tests/unused_rules_tests.rs` |
| pest-validator-hardening | `meta/tests/validator_hardening_tests.rs` |
| lightningcss-selector-simplify-fixpoint | `tests/selector_simplify_tests.rs` |

### Required 4-block structure (top-to-bottom)

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
```

### Coverage (count-agnostic)

Tests must cover, with no count target:

1. Every described behavior in `meta.md` (≥1 test per sentence/bullet)
2. Every new public API surface (function, method, error variant, config option)
3. Every solution branch (every `if`, `match` arm, early return, recursive case)
4. Standard edge cases (empty / zero / single-element / boundary / unicode / recursion / null)
5. Stated inverse if it matters and isn't symmetric

**Approved Mars (observational, not a target):** 39, 68, 92, 102, 160 tests. The 39-test case densely covers one subsystem (8 error classes × 4–5 substring-match tests each). The 160-test case covers 13 public functions × ~12 scenarios each.

### Test naming convention

Scenario-encoded snake_case that reads as a sentence:

| Pattern | Approved examples |
|---|---|
| `<input_shape>_<expected_outcome>` | `range_z_to_a_errors`, `dedup_two_class_is`, `single_orphan_reported_as_unused` |
| `<context>_<input>_<outcome>` | `negpred_of_always_failing_choice_in_rep_errors`, `peek_slice_empty_in_choice_first_alt_errors` |
| `fixpoint_<scenario>` | `fixpoint_three_way_prefix_folds_completely`, `fixpoint_already_factored_is_stable` |

### Assertion style

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

**Substring keywords from approved Mars:** `"cannot fail"`, `"following choices"`, `"invalid repetition"`, `"invalid range"`, `"contradictory"`, `"alternative"`, `"negative predicate"`, `"recurs"`. Pick 1–3 stable keywords per error class.

### Comments inside tests

**Zero `//` comments inside test bodies.** Verified across all 5 approved files. Function names carry the meaning. Only allowed:
- File-header doc comment if repo's other test files have one
- `#[track_caller]` on assertion helpers using `assert_eq!` inside (lightningcss does this)

### test.sh layout (Mars Rust default)

```bash
#!/usr/bin/env bash
set -uo pipefail
export PATH="/root/.cargo/bin:$PATH"

MODE=""; OUTPUT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    base|new) MODE="$1"; shift ;;
    *) echo "Usage: ..."; exit 1 ;;
  esac
done

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
  base) run_and_produce_junit "$OUTPUT_PATH" cargo test --workspace --lib --test calculator --test json --test grammar --test grammar_inline --test implicit --test lists --test oneormore --test opt --test reporting --test surround --test http --test sql --test toml -- --skip quote ;;
  new)  run_and_produce_junit "$OUTPUT_PATH" cargo test -p pest_meta --test <new_feature_tests> ;;
esac
```

The build-failure fallback is non-negotiable. Without it, JUnit XML is empty when cargo crashes and the platform reports "No test suite results were found."

**`--skip quote` for pest** is justified — pre-existing flaky test. Combined with the `sed -i '1s/^/#![cfg(feature = "grammar-extras")]\n/' vm/tests/surround.rs` Dockerfile patch, it works on every approved Mars submission.

### test.sh strict arg validation (NEW — required for all tiers post 2026-05-26)

V2-carryover reviewer feedback (yaegi-checkpoint-api Auto Review R24, 2026-05-06 origin) requires test.sh to reject silent defaults and multi-mode invocations. Apply this validation block on top of the Mars Rust default OR the Go default below:

```sh
usage() {
  echo "usage: $0 [--output_path <path>] base|new" >&2
  exit 2
}

MODE=""; MODE_COUNT=0
OUTPUT_PATH=""; HAVE_OUTPUT=0

while [ $# -gt 0 ]; do
  case "$1" in
    base|new) MODE="$1"; MODE_COUNT=$((MODE_COUNT + 1)); shift ;;
    --output_path) shift; [ $# -lt 1 ] && { echo "missing value for --output_path" >&2; usage; }; OUTPUT_PATH="$1"; HAVE_OUTPUT=1; shift ;;
    --output_path=*) OUTPUT_PATH="${1#--output_path=}"; HAVE_OUTPUT=1; shift ;;
    *) echo "unknown argument: $1" >&2; usage ;;
  esac
done

[ "$MODE_COUNT" -eq 0 ] && { echo "missing mode (base or new)" >&2; usage; }
[ "$MODE_COUNT" -gt 1 ] && { echo "only one of base or new may be specified" >&2; usage; }
```

**Reject patterns the V2 reviewer named verbatim:**
- `MODE="${MODE:-base}"` — silent default to base (lets `./test.sh --output_path X` silently run base)
- case-statement overwrite of `MODE="$1"` on second `base|new` match (lets `./test.sh base new` silently run `new`)
- catchall `*)` that just shifts and continues (silently ignores typos)

### test.sh layout (Go default — Pattern B)

```sh
#!/bin/sh
set -u
export PATH=/usr/local/bin:/go/bin:/usr/local/sbin:/usr/bin:/bin

# Resolve toolchains by absolute path (avoids PATH-shim attacks during grading)
if [ -x /usr/local/bin/go ]; then GO=/usr/local/bin/go
elif [ -x /usr/local/go/bin/go ]; then GO=/usr/local/go/bin/go
else GO=$(command -v go); fi
if [ -x /go/bin/go-junit-report ]; then JUNIT_REPORT=/go/bin/go-junit-report
else JUNIT_REPORT=$(command -v go-junit-report); fi

# Strict arg validation (see above)
# ... usage() + MODE_COUNT + while-loop here ...

run_junit() {
  OUT="$1"; shift
  TESTOUT="${TMPDIR:-/tmp}/test-$$.out"
  "$GO" test -v -count=1 "$@" > "$TESTOUT" 2>&1
  RET=$?
  if grep -q "\[build failed\]" "$TESTOUT"; then rm -f "$TESTOUT"; return 1; fi
  "$JUNIT_REPORT" -set-exit-code < "$TESTOUT" > "$OUT"
  JR=$?
  rm -f "$TESTOUT"
  [ "$RET" -ne 0 ] || [ "$JR" -ne 0 ] && return 1
  return 0
}

EXIT=0
case "$MODE" in
  base) [ "$HAVE_OUTPUT" -eq 1 ] && run_junit "$OUTPUT_PATH" ./... -timeout 600s || "$GO" test -count=1 ./... -timeout 600s; EXIT=$? ;;
  new)  [ "$HAVE_OUTPUT" -eq 1 ] && run_junit "$OUTPUT_PATH" -tags=<problem-tag> -run "^<TestPrefix>" ./<pkg>/ -timeout 180s || "$GO" test -count=1 -tags=<problem-tag> -run "^<TestPrefix>" ./<pkg>/ -timeout 180s; EXIT=$? ;;
esac
exit $EXIT
```

**Go base mode = full regression `./...`** (not a handpicked regex). V2 reviewer (yaegi-checkpoint-api, 2026-05-06) explicitly confirmed `go test ./...` is stable in the container. Handpicked regex like `^(Test_|TestB|TestCa|...)` hides regressions in unmatched prefixes (TestA*, TestD*, TestF*) and entire packages (`cmd/yaegi/`, `stdlib/`). **Only use a handpicked regex if specific packages are known-broken in container AND each exclusion is documented inline with a concrete sandbox blocker.**

**Build-tag isolation** (Pattern 27) — new mode uses `-tags=<problem-specific>` to gate new test files. Base mode omits the tag so new files are excluded from the regression suite. Sample: yaegi-checkpoint-api uses `-tags=checkpoint`.

**Toolchain absolute paths** — yaegi-checkpoint-api precedent: `GO=/usr/local/bin/go` + `JUNIT_REPORT=/go/bin/go-junit-report` with fallback. Prevents PATH-shim grading attacks where a planted `/opt/go/bin/go` overrides the real binary.

**Prefer `go-junit-report`; if you hand-roll an awk/sed JUnit emitter, XML-escape test names.** `go-junit-report` escapes correctly. A self-contained awk synthesizer that emits a name raw into `name="..."` breaks the file when a base subtest name contains `"` `<` `>` `&` — yaegi's `TestIssue1623/pkg.S_=_"bar"` made the platform parser reject the baseline run ("not well-formed"), and `grep -c '<testcase'` hid it locally. Add an `xmlesc` awk function escaping `& < > "` at every emit site, and validate the output with `xml.etree`/`xmllint`, never grep. (yaegi-unreachable-code 2026-06-03; DIAMOND.md Pitfall 9.)

---

## Pattern 3 — Solution Anatomy

### File footprint

| Problem | Files | New | Modified | +LOC | -LOC |
|---|---|---|---|---|---|
| pest-extended-skip | 8 | 0 | 8 | 340 | 58 |
| pest-factorizer-fixpoint | 3 | 0 | 3 | 220 | 37 |
| pest-unused-rule-elim | 3 | 2 | 1 | 377 | 0 |
| pest-validator-hardening | 1 | 0 | 1 | 358 | 30 |
| lightningcss-selector-simplify-fixpoint | 3 | 0 | 3 | 167 | 1 |

**Targets:** 3 files is mode. 170–380 +LOC. Single-file fine when dense (validator-hardening). 8-file fine when crossing crates (extended-skip).

### Helper extraction is universal

Every approved solution extracts ≥1 pure-function helper at module scope:

| Problem | Notable helpers |
|---|---|
| extended-skip | `try_flatten_str_seq`, `normalize_skip_choices` |
| factorizer | `flatten`, `rebuild`, `factor_choice`, `merge_alternatives` |
| unused-rule-elim | `compute_reachable`, `referenced_idents`, `build_rule_map` |
| validator-hardening | `is_always_failing`, `validate_repminmax_bounds`, `validate_invalid_ranges`, `validate_contradictory_predicates`, `validate_push_inside_negpred`, `validate_always_failing_alternative` |
| lightningcss | `simplify_selector`, `simplify_component_in_place`, `try_unwrap_double_negation_single` |

Each helper = a unit of behavior the description names. The 1:1 mapping (description requirement ↔ helper function) is what makes solutions readable and tests deterministic.

### Fixpoint loops are explicit

When the description says "iterate to a fixpoint" / "until no rewrites apply", use this exact shape:

```rust
// factorizer
let mut current = expr;
loop {
    let next = current.clone().map_top_down(|e| factor_choice(e, ty, rules));
    if next == current { break; }
    current = next;
}

// lightningcss
loop {
    let mut changed = false;
    for selector in list.0.iter_mut() {
        if simplify_selector(selector) { changed = true; }
    }
    if !changed { break; }
}
```

### Recursive AST traversal with cycle-trace

Standard pattern when traversing potentially-recursive references:

```rust
fn is_always_failing<'i>(expr: &ParserExpr<'i>, rules: &..., trace: &mut Vec<String>) -> bool {
    match *expr {
        ParserExpr::Ident(ref ident) => {
            if !trace.contains(ident) {
                if let Some(node) = rules.get(ident) {
                    trace.push(ident.clone());
                    let result = is_always_failing(&node.expr, rules, trace);
                    trace.pop().unwrap();
                    return result;
                }
            }
            false
        }
        // ...
    }
}
```

### Doc comments

Match the repo. pest source uses `///`; pest-unused-rule-elim's solution does too:
```rust
/// Returns the names of rules that are not reachable from the entry rule
/// (the first rule in `rules`) or from the `WHITESPACE` and `COMMENT`
/// implicit roots when defined. Results preserve the order rules appear in
/// `rules`.
pub fn find_unused_rules(rules: &[Rule]) -> Vec<String> { ... }
```

lightningcss source uses minimal doc comments; lightningcss solution does the same.

**Inside-function comments: zero.**

### Code that did NOT get flagged (allowed)

- ✅ `expect("...")` panics on builder helpers (test/build invariants)
- ✅ `unwrap()` after `let Some(...) = ...` short-circuit when correctness is local
- ✅ Cloning in fixpoint loops (`current.clone()`)
- ✅ `std::mem::take` to avoid borrows
- ✅ `HashMap` vs `BTreeMap` when description doesn't constrain order
- ✅ Module-private helpers without `pub`

### Code that WOULD be flagged (avoid)

- ❌ `// TODO`, `// FIXME`, `// NOTE` markers anywhere
- ❌ `println!`, `eprintln!`, `dbg!`, `console.log`
- ❌ Commented-out alternative implementations
- ❌ Obvious AI restatement comments (`// Loop through items`)
- ❌ Speculative extra-feature code not asked for
- ❌ Unrelated refactors (style tweaks, import reordering in unrelated files)
- ❌ Breaking existing function signatures when an additive overload would work

---

## Pattern 4 — Dockerfile

### Pattern A — Rust on `mars-base` (4 of 5 approveds)

```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest

ENV RUSTUP_HOME="/root/.rustup"
ENV CARGO_HOME="/root/.cargo"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY . .

RUN chmod -R a+rX /root \
    && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && sed -i '1s/^/#![cfg(feature = "grammar-extras")]\n/' vm/tests/surround.rs \
    && cargo fetch && cargo build --workspace

CMD ["/bin/bash"]
```

> ⚠️ **LEGACY `mars-base` block (do NOT reuse on `olympus-base-rust`).** The canonical Rust Dockerfile is now `RUN cargo install cargo2junit && cargo fetch && cargo build --workspace` with NO ENV block, NO chmod, NO symlink. The `chmod -R a+rX /root` below actively breaks solve-time cargo perms on `olympus-base-rust` (nickel-enum-widening R1 0/10). See `DOCKER.md § ⚠️ Rust JUnit = cargo2junit`.

Three parts of the legacy `mars-base` pattern (historical re-verify only):
1. `chmod -R a+rX /root` — non-root reads `/root/.cargo/*` (harmful on `olympus-base-rust` — do NOT use there)
2. `ln -sf /root/.cargo/bin/* /usr/local/bin/` — non-root finds cargo on PATH
3. `cargo fetch && cargo build --workspace` — pre-warm offline cache

The repo-specific `sed` patch is shown for pest's `grammar-extras` feature gate. **Rust JUnit = `cargo2junit` (2026-07 reviewer directive):** add `cargo install cargo2junit` to the Dockerfile and pipe libtest json through it in test.sh — see `DOCKER.md § ⚠️ Rust JUnit = cargo2junit` + `TESTS.md § Rust — cargo2junit`. The old bash-regex placeholder is superseded (reviewer-rejected + miscounts multi-binary).

### Pattern B — Bare `olympus-base` (1 of 5: lightningcss)

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

WORKDIR /app
COPY . .
RUN cargo fetch && cargo build

CMD ["/bin/bash"]
```

Worked for lightningcss because the touch surface is tiny (3 files, 167 LOC, no `--all-features` workspace build at Docker-build time). Multi-crate Rust workspaces hit the `/app/target` permission bug — default to Pattern A unless verified non-root with `--user 1000:1000`.

### Verification step

```bash
docker build -t my-mars-problem . \
  && docker run --rm --network none --user 1000:1000 -v /tmp/mars-out:/out my-mars-problem \
       bash -c "/app/test.sh --output_path /out/base.xml base && /app/test.sh --output_path /out/new.xml new"
grep -c '<testcase' /tmp/mars-out/base.xml /tmp/mars-out/new.xml
```

Both counts > 1 → ✅. Either count is 0 or 1 → permissions broken; switch to Pattern A.

---

## Pattern 5 — File Inventory at Submit

```
problem-folder/
├── BASE_COMMIT.txt        ← 41-char commit hash
├── Dockerfile             ← Pattern A or Pattern B
├── meta.md                ← Plain-prose description, action-verb title
├── solution.patch         ← src/* changes only
├── test.patch             ← test.sh + new test file(s) only
└── (optional) Agent Runs.md, Checks Run.md — local report files
```

**Do NOT include in submission:** repo clone (`/bootstrap`, `/derive`, `/generator`, etc.), `.cargo/`, `.github/`, `Cargo.toml`/`Cargo.lock`, `CONTRIBUTING.md`/`README.md`, AI-generated `*_PLAN.md`/`*_SUMMARY.md`/`*_READY.md`.

The `Mars Approved V2/Feature Requests/` folders show this exact 5-file (sometimes +1-2 report files) structure.

---

## Pattern 6 — How Approval Looked

From `pest-extended-skip/checks runs.md`:

```
Problem and tests are good quality (AI, up to 1 min)
Warning ← yes, approved problems can have warnings

1. No test leakage [OK]
2. Tests cover required behavior [OK]
3. Tests focus on behavior [WARNING]
4. Sanity check [OK]
```

**The bar: 3 of 4 OKs + 1 WARNING is approvable.** Don't burn revision cycles converting `tests focus on behavior` WARNING to OK if it's advisory.

Critical OKs that MUST be green:
- **No test leakage** — description doesn't reference test files/functions
- **Tests cover required behavior** — every described behavior has ≥1 test
- **Sanity check** — patches apply cleanly, test.sh structure correct

---

## Pattern 7 — Pre-Submit Checklist

### Description
- [ ] Title starts with imperative verb, 5–10 words, names specific subsystem
- [ ] Plain prose, no `##` headers, no formulaic labels
- [ ] Word count in tier band (Mars ≤240 recommended, Olympus ≤200 recommended; hard cap both: 500)
- [ ] Every test traces to a description sentence; every described behavior has a test
- [ ] Backticks only on new public API names
- [ ] No `Box<...>` type wrappers — describe variants in prose
- [ ] No code-instead-of-prose
- [ ] Canonical output form spelled out if tests use `assert_eq!` on structures
- [ ] First-occurrence/last-occurrence dedup rule stated
- [ ] Sort order stated if results are ordered
- [ ] Resolution rule stated if rule references / lookups happen

### Tests
- [ ] One new test file at conventional repo location
- [ ] 4-block layout: imports → builders → assertion helpers → tests
- [ ] Scenario-encoded snake_case test names
- [ ] One assertion per `#[test]`
- [ ] Error tests use `.contains(substring)` with stable keywords
- [ ] Zero `//` comments inside test bodies
- [ ] No weak `is_ok()` / `length > 0` / `toBeDefined()` assertions
- [ ] No private-field probing, no reflection
- [ ] Coverage complete: every behavior, API, branch, edge case
- [ ] `./test.sh new` FAILS pre-solution
- [ ] `./test.sh base` PASSES pre-solution
- [ ] Both XMLs have `<testcase>` count > 1
- [ ] Flakiness verification (MANDATORY Core Dev check): the target repo's existing tests AND the new tests must be non-flaky — run base+new at least 3-5x and confirm deterministic, identical pass/fail every run; no timing/ordering(map-set-iteration, parallel-race)/unseeded-RNG/network/clock/filesystem-time dependence; a flaky repo baseline or flaky new test = reject.

### Solution
- [ ] +LOC clears tier floor (Mars ≥100, ≥150 pref, 170–380 is a non-binding observed sweet spot — never a cap; Olympus/Diamond ≥450 design floor, 400 = platform auto-block)
- [ ] Files modified in tier band (Mars 1–8, Olympus 8–35)
- [ ] Pure-function helpers extracted (1+ per behavior)
- [ ] Fixpoint loops use `loop { … if !changed { break; } }` shape when description says "iterate"
- [ ] Doc comments on new public functions iff repo uses doc comments
- [ ] Zero inline `//` comments inside function bodies
- [ ] Zero `// TODO/FIXME/NOTE` markers
- [ ] Zero `println!`/`dbg!`/`eprintln!`
- [ ] No commented-out alternative implementations
- [ ] No new external dependencies
- [ ] No drive-by refactors of unrelated files
- [ ] No breaking changes to existing public function signatures
- [ ] `./test.sh new` PASSES post-solution
- [ ] `./test.sh base` PASSES post-solution

### Docker
- [ ] Rust (2026-07): `olympus-base-rust` + `RUN cargo install cargo2junit && cargo fetch && cargo build --workspace` — NO ENV block, NO chmod, NO symlink (chmod -R /root breaks solve-time cargo perms). Legacy `mars-base` chmod Pattern A is historical re-verify ONLY.
- [ ] Pattern B (`olympus-base` bare) ALWAYS for Python/JS/Go
- [ ] test.sh Rust JUnit via `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit` (NOT the bash-regex placeholder)
- [ ] Repo-specific `sed` patch present if needed
- [ ] `cargo fetch && cargo build --workspace` runs at build time
- [ ] Verified locally with `docker run --user 1000:1000 --network none …`

### Submit Folder
- [ ] Exactly 5 deliverable files
- [ ] No repo-clone directories at top level
- [ ] No `Cargo.toml`/`Cargo.lock` at top level
- [ ] No `CONTRIBUTING.md`/`README.md` from the repo
- [ ] No AI-generated `*_PLAN.md`/`*_SUMMARY.md`/`*_READY.md`
- [ ] BASE_COMMIT.txt is a 40-char commit hash, not a tag

### GitHub
- [ ] `gh pr list --repo <owner>/<repo> --search "<keyword>"` shows no existing PR
- [ ] No related closed/rejected issue from maintainer
- [ ] Repo has ≥500 stars, commit in last 12 months, permissive license

---

## Pattern 8 — Stuck in Revision Cycles

5 buckets — match yours and apply the documented fix:

### Bucket 1 — "Description has hidden requirements"
**Symptom:** Alignment check FAILED; reviewer says "tests enforce X but description doesn't mention X"
**Fix:** Add ONE sentence naming the canonical form / sort order / resolution rule. Surgical addition, not rewrite.
**Example:** factorizer added "Resolve rule references through the grammar's rule map when checking non-failing or nullable" to fix the rule-map blind-spot.

### Bucket 2 — "Description sounds like a tech spec"
**Symptom:** Description quality WARNING — robotic phrasing, formulaic structure
**Fix:** Strip all `## Problem`, `Acceptance Criteria:`, `Requirements:` headers. Convert to 2–6 plain paragraphs. Verb-led title.

### Bucket 3 — "Tests pass on base"
**Symptom:** `./test.sh new` (pre-solution) returns 0 failing tests
**Fix:** Re-check that tests actually use the new public API. Common causes: wrong module path; missing `use`; test only triggers on cfg(feature) that's already on.

### Bucket 4 — "AI checker says tests over-constrain"
**Symptom:** WARNING on `Tests focus on behavior` — tests assert internal optimizer policies
**Fix:** Either loosen the test to assert observable behavior only, OR add a description sentence acknowledging the policy. Both paths work; (b) is faster.

### Bucket 5 — "Problem too easy"
**Symptom:** Difficulty WARNING, agent pass rate **>30% Mars / >20% Olympus / >30% Diamond**
**Fix:** The knob is TRAP COUNT/STRENGTH, not LOC. **Nova ≈ Castor now — traps must be INTERDEPENDENT (one fix regresses/surfaces another) + MISDIRECTING (failing test hides the fix), even for Mars/Nova.** Add a 2nd interdependent trap with a misdirecting failure, OR strengthen one to >60% miss. An isolated/self-revealing/single-point trap gets single-shot-fixed (1 trap ≈50%, 2 independent ≈25%, 3 stacked ≈12%). A uniform-wrap (one local rule solving all walls) is too easy at every tier. Add a *new interdependent trap dimension*, not just LOC or restated requirements. See `../CLAUDE.md § ⚠️ HARD RULE — Difficulty-Calibration Model`.

---

## Pattern 9 — Sketching a Fresh Mars Submission

8-step pre-code sketch (BEFORE writing any code):

1. **Pick a verb-led title.** Constrain to 5–10 words. If you can't pick a verb (Fix/Add/Implement/Extend/Iterate/Rewrite), the problem is too vague.
2. **List the public API surface in 5–15 names.** Function names, enum variants, parameter names, error keywords. These go in the description verbatim.
3. **Sketch the canonical output form.** What ordering? What associativity? What dedup rule? Write 3–5 short bullet sentences.
4. **Write the description.** 2–6 paragraphs, 90–200 words, fold in the API surface and canonical form. No headers.
5. **Sketch the test file outline.** Helper builders at top (~15–25), groups of `#[test]` functions per requirement bucket.
6. **Sketch the solution outline.** Identify 3–6 pure-function helpers at module scope. Each helper = one description requirement. Total LOC target 200–380.
7. **Run GitHub PR existence check.** `gh pr list --repo <repo> --search "<keyword>" --state all` — if PR exists, abandon.
8. **Estimate Nova pass rate.** If the feature is a literal pattern-match copy of existing repo code, agents solve in 1 message and you're at 70%+. Pick something requiring at least one non-obvious decision.

If steps 1–3 take >30 minutes, the candidate is wrong. Drop and pick another.

---

## Pattern 10 — 5-Minute Sanity Check Before Submitting

```bash
# 1. Apply patches against a clean checkout to confirm no conflicts
git clone <repo-url> /tmp/sanity && cd /tmp/sanity \
  && git checkout $(cat /path/to/problem/BASE_COMMIT.txt) \
  && git apply /path/to/problem/test.patch \
  && git apply /path/to/problem/solution.patch

# 2. Build Docker image and run BOTH modes as non-root
docker build -t sanity /path/to/problem
docker run --rm --network none --user 1000:1000 -v /tmp/sanity-out:/out sanity \
  bash -c "/app/test.sh --output_path /out/base.xml base"
docker run --rm --network none --user 1000:1000 -v /tmp/sanity-out:/out sanity \
  bash -c "/app/test.sh --output_path /out/new.xml new"

# 3. Confirm both XMLs are non-trivial
grep -c '<testcase' /tmp/sanity-out/base.xml   # >> 1
grep -c '<testcase' /tmp/sanity-out/new.xml    # coverage-complete

# 4. Confirm test.patch FAILS on base (without solution)
cd /tmp/sanity && git checkout -- . && git apply /path/to/problem/test.patch
docker build -t sanity-base . && docker run --rm --network none sanity-base \
  bash -c "/app/test.sh --output_path /tmp/x.xml new || echo 'EXPECTED FAILURE'"
```

## Lowering pass rate: deepen a behavior, do not add tests (piccolo-to-be-closed, Olympus 2026-06-24)

When an Olympus/Diamond reads "too easy," the instinct to add discriminator tests backfires on the avg-pass-fraction metric: competent agents pass the new tests and the average rises (measured 0.66 → 0.81 = easier). The pass-rate knob is the difficulty of the CORE, not the test count. piccolo landed in-band (20%) only after reshaping one behavior into a deeper trap (the generic-`for` fourth-value closing, which forces a hot-opcode result-slot relayout), not after the +9 tests.

The most durable trap shape there was a **forced representation choice** (`PATTERNS-ADVANCED.md § Pattern 37`): the natural internal representation (to-be-closed slots keyed by stack index, deduped) is wrong for loop bodies that reuse a register, so it closes once instead of per-iteration. It bit 6/10 agents, is shared across every close path (interdependent), and surfaces as a wrong count or a hang (misdirecting). Pair it with a second behavior that needs leaving-block-vs-within-block discrimination (goto close-level), and the two-trap stack holds an Olympus band on opus-4-8-class solvers.

Operational must-dos confirmed: test.patch ADDITIONS-ONLY (the grader re-applies it; retire goldens via `rm -f` in test.sh, not a patch deletion), and wrap each test command in `timeout` + emit a synthetic failure on any non-clean exit so an agent hang grades as an honest FAIL rather than a verifier-blocker readiness flag.

If any step diverges, fix locally — don't submit.

---

## Pattern 11–13 — Shape Taxonomy + Best Agent by Shape

**Moved to dedicated file:** `SHAPES.md` (245 lines)

- Pattern 11: Mars Solid Shape Taxonomy (6 shapes: A1, A2, B, C, D-new, D-change) — pass-rate band, files, dominant verdict, solver/our LOC ratio, best agent per shape
- Pattern 12: Olympus Shape Taxonomy (4 active shapes + O-Trap historical) — O-Composite-extend, O-Composite-add, O-Pipeline-easy, O-Pipeline-hard, O-Algorithm-coverage, O-Algorithm-correctness
- Pattern 13: Best Agent by Shape — Mars + Olympus decision matrices + Vega's specific profile

Read `SHAPES.md` BEFORE picking a shape for any new problem.

---


---

## Pattern 14 — The Canonical Bypass Message Format

The pest-normalizer bypass (Mar 15, 2026) is the canonical 6-element format. **Bypass approval requires every element.**

> "All 12 runs produce agent-fault verdicts (MISSED_REQUIREMENT or WRONG_LOGIC) with no fairness flags. The best agent scored 56/57, failing only on sub-expression NormalizedChoice conversion within mixed choices — a behavior explicitly stated in the description ('Any choice chain or sub-expression'). Three agents scored 54+/57. The dominant failure pattern is agents placing normalization after the unroller (where RepOnce is already expanded), despite the description explicitly stating to normalize 'grammar rule expressions (Expr) before they are converted to optimized expressions.' All requirements are explicitly documented, all test expectations align with stated rules, and the reference solution demonstrates full solvability. The problem is legitimately challenging — requiring correct pipeline placement, context-sensitive empty-string handling, and two-phase architecture — but all information needed is available in the description and codebase."

### 6 Elements Mapping

| # | Element | Example phrase from above |
|---|---|---|
| 1 | What check failed | "All 12 runs produce agent-fault verdicts" (implies solvability) |
| 2 | Why you believe it's wrong | "with no fairness flags" |
| 3 | Evidence with numbers | "Best agent scored 56/57, three agents 54+/57" |
| 4 | Dominant failure pattern | "Placing normalization after the unroller, despite description stating to normalize before optimization" |
| 5 | Alignment claim | "All requirements explicitly documented, all test expectations align with stated rules, reference solution demonstrates solvability" |
| 6 | Conclusion | "Problem is legitimately challenging but all info available" |

### Bypass Eligibility Criteria (HISTORICAL — post-April-2026 the 0% Mars near-miss path is DEAD; not a live approvable path)

The criteria below documented the now-retired 0%-pass-with-near-miss-evidence bypass. They are kept for historical reference only — do NOT present this as a live route to approval for a 0% Mars or Olympus submission (near-0 belongs at Diamond, which keeps its hint flow). A bypass was once approvable ONLY when ALL of these held:
1. ✅ All failures are agent-fault (Missed Requirement, Wrong Logic, Execution Error, Early Termination)
2. ✅ Zero infrastructure verdicts (no Integration Error, no Regression, no Syntax Error)
3. ✅ Near-miss evidence: ≥1 agent at 90%+ test score
4. ✅ Multiple distinct failure modes (not all agents fail identically)
5. ✅ Reference solution demonstrably works (we built it)
6. ✅ Specific failure pattern is named and traced to description text

### Diamond failure-QA gates (cross-ref — full rules in DIAMOND.md 41-47, PATTERNS-ADVANCED Pattern 44)

Diamond `failure-qa.md` faces TWO independent gates: an auto-validator that greps named identifiers and returns true/MIXED/false per claim, and a human reviewer judging grouping + completeness + tone. All-true on the validator does NOT mean the reviewer passes. QA-tier artifacts (failure-qa.md + test-groups.md + Env Description) do not stale Castor / Diamond Checks / Auto Review. **Single highest-leverage pre-submit check (Pattern 52):** the validator greps every backticked token LITERALLY — before upload, extract every `` `...` `` token and grep each against test.patch + the run's agent diff + repo source; any zero-match is MIXED. One mechanical pass collapses the usual 4-6 validator rounds to ~1. Watch comparison flips (`len(d) >= 3` vs `if len(d) < 3`), substituted args / ellipsis-in-backtick, fabricated call-results, wrong-file-hunk line refs; and two FALSE classes in Go table suites: parent-rollup-Failed (a table PARENT renders no message) and stale-per-run data (author each block from THAT run's actual failing-test dump; count = total - passing).

Critical (yaegi-channel-diagnostics, 6-round convergence): the validator binds each claim to the PLATFORM's behavioral grouping (the test-file group, e.g. name prefix), not to your symptom split. Never regroup blocks along a symptom axis that cuts across it, even when a reviewer asks to split — split symptoms INSIDE the bound block, and make a both-manifestations claim if the group is symptom-mixed (a whole-group claim must hold for every test bound there). Per-run agent code differs, so a mechanism TRUE for one run can be FALSE for another with the same symptom. A bare backticked repo identifier the validator greps (e.g. `rangeChan`) is grep-variance-prone; anchor on the agent helper + behavior + junit symptom. Before re-editing on a FALSE/MIXED verdict, grep the flagged text in the current file — the verdict may have scored a stale pre-edit upload.

### Post-April 2026 Restrictions

- **Olympus solvability cannot be bypassed** — at least 1 agent must pass
- **Hints removed for Mars + Olympus** — no longer an option to unlock solvability at those tiers. **Diamond KEEPS the hint flow** (near-0 Castor → add hint, re-run).
- **O-Trap shape problems are no longer viable** — must redesign

The bypass message format above is still useful for:
- Bypassing non-solvability checks (description_clear, etc.)
- Mars submissions where 1+ Nova agents pass

---

## Pattern 15 — New Verdict Types (Olympus-Era)

Two verdict types appear only in Olympus / hard Mars problems. Recognize them:

### Execution Error
- **Definition:** Agent's code crashes at runtime (panics, segfaults, undefined behavior)
- **Distinct from Integration Error:** Integration = compile error. Execution = runtime crash.
- **Frequency:** ~1 of 24 in pest-dispatch (4%)
- **Signal:** Agent's code passed compilation but produced invalid runtime state
- **Often correlates with:** Wrong Logic (agent committed to broken algorithm)

### Early Termination
- **Definition:** Agent stops without completing
- **Two patterns:**
  - **Long-horizon exhaustion:** 1000+ messages, agent runs out of context (Nova's thrashing on goja-using: 64m, 1073 msgs, no solve)
  - **Premature commit:** Agent thinks it's done after minimal work (Vega→Orion on goja-using: 9m, 1 file, 153 LOC, 211 msgs, no solve)
- **Frequency:** ~17% on hardest problems (goja-using, 2/12)
- **Signal:** Problem too long-horizon for the agent OR agent picked wrong simple architecture

These verdicts only appear at the hardest Olympus problems. If your Mars submission triggers Early Termination or Execution Error, it's signaling Olympus-scale complexity.

---

## Pattern 16 — Wrong Logic % as Difficulty Signal

Wrong Logic % across the 13 problems correlates with how subtle the algorithmic correctness requirement is:

| Problem | Wrong Logic % | Pass | Why |
|---|---|---|---|
| inliner | **40%** | 10% | Multi-pass coverage trap |
| normalizer | **33%** | 0% (bypass) | Pipeline placement trap |
| dispatch | **25%** | 8% | Fallback re-dispatch trap |
| goja-using | **25%** | 17% | SuppressedError ordering, async dispose |
| seq-rewriter | 8% | 15% | Mostly Missed Req — clearer spec |
| factorizer | 6% | 25% | Fixpoint convergence subtle |
| All other approveds | 0% | varies | No subtle algorithm trap |

**Rule of thumb: Wrong Logic ≥ 25% indicates a subtle algorithmic/semantic correctness trap.** Such problems sit at 0–10% pass rate. They are the hardest. Designers should consciously decide whether to introduce one — they make problems Olympus-grade.

### Difficulty-design quick rules (tier-agnostic, from rdb-sample-fraction APPROVED 2026-05-31)

Three reusable heuristics for where difficulty lives and where it leaks away. Full write-ups in `PATTERNS-ADVANCED.md § 40–43`.

- **Cost-test-or-decorative (Pattern 41).** If a pick's difficulty rests on "do X *without* materializing / decoding / allocating / re-traversing" (lazy, streaming, skip-on-the-wire, single-pass), a behavioral test usually can't tell the faithful path from the lazy shortcut — output is identical. Add an allocation-budget (`MemStats.TotalAlloc` delta), timing, or decode-counter test, or the requirement is decorative and the pick lands too-easy. Signal: agents pass with far fewer LOC than the reference and the "expensive" file is absent from their diffs.
- **Choke-point triviality (Pattern 42).** When a repo routes every consumer through ONE option/middleware choke point with N sibling options (rdb `wrapDecoder`, Express middleware, a flag registry, a plugin array), adding one more sibling is Pattern-23/33 trivial. Push difficulty onto (a) the value the choke point consumes-and-discards (forces independent re-extraction at divergent sites — forgot-a-site is the dominant fail) and (b) the per-item-vs-aggregate output boundary (which outputs transform vs negative controls that must NOT). Catch tests: value reaches every site + negative controls unchanged.
- **Distribution/determinism hash trap (Pattern 43).** For sampling/bucketing/shard/dedup features, "deterministic + processes only a fraction / distributes evenly" implies a well-distributed hash without saying so. Agents compare a raw/shifted/modulo digest to the threshold; on sequentially numbered prefix keys it clusters all-or-nothing (empty or whole group at 0.5). Fixture MUST use sequential prefix keys; catch test asserts a strict subset `0 < n < total`. Keep the distribution UNDOCUMENTED (it is the fair difficulty). 9/10 failing the same way = fairness signal, not unfairness.

Plus one fairness ANTI-pattern: **representation-type pin (Pattern 40)** — when tests do typed arithmetic into a new public struct, the field's Go integer type is pinned; an agent's reasonable `uint64`-vs-`int` choice breaks compilation and masks every downstream test (unfair). Document field types in the description, or relax the assertions.

### Reviewer-graded text artifacts — match the approved exemplar FIRST (tier-agnostic, from two yaegi Diamond QA arcs APPROVED 2026-05-31)

Any artifact a reviewer or an auto-validator grades as TEXT (Diamond failure-qa.md / test-groups.md, but the same discipline pays off for meta.md, bypass messages, feedback shown on-platform) follows two laws learned the expensive way (4 QA-only rounds on yaegi-generic-constraint-fidelity, 6 on yaegi-channel-diagnostics — both collapsible to ~1). Full Diamond detail in `PATTERNS-ADVANCED.md § 44–45` + `DIAMOND-PLAYBOOK.md § Section 5`; copy-ready Diamond-QA prompt in `Instructions/QA-WRITER-PROMPT.md`.

- **Read the closest APPROVED exemplar and copy its shape before drafting.** Do not invent a format and iterate it against the reviewer; the approved files ARE the spec. For Diamond QA the gold-standards are `diamond-problems/approved/cliffy-command-aliases` + `dasel-csv-options`; for a Mars/Olympus meta.md it is the closest-shape approved description.
- **Cite by named identifier + behavior, never by value-anchored line number.** A line number presented as the locator for a specific value (`str is "untyped float", type.go:160`) flags when off-by-one and an auto-validator is non-deterministic on it; a behavior-anchored number beside a named function is tolerated. Name the symbol; drop the number unless you read that exact line this session. (Diamond QA is graded on per-test FACTUAL correctness — right test → right expected/actual → right cause — and has its own approval gate independent of solvability.)

---

## Appendix A — Which Approved Problem Matches Your Use Case?

| Your situation | Closest approved | What to crib |
|---|---|---|
| Adding new public functions/APIs to existing module | unused-rule-elim | Module split (reachability.rs + unused_rules.rs), parallel optimized API |
| Rewriting an existing pass with new semantics | factorizer-fixpoint | Fixpoint loop, helper extraction (`flatten`, `rebuild`), description structure |
| Adding new enum + variants spanning multiple files | extended-skip | Display formatting rules, normalization rules, multi-file integration |
| Strengthening a validator / adding new diagnostics | validator-hardening | Single-file dense changes, substring-match error tests, classifier helpers |
| Iterating a transformation to a fixpoint over CSS/AST | lightningcss-selector-simplify-fixpoint | `loop { changed = false; … }`, in-place mutation, "adjacent only" rule |

---

## Appendix B — Anti-Patterns That Got Reverted

1. Existing PR on GitHub → instant reject. Always check first.
2. Tests pass on base → useless tests. Revert.
3. Description over-prescriptive → tech-spec tone. Convert to plain prose.
4. AI-style comments (`// Step 1:`, `// Loop through items`) → flagged.
5. Surprise tests — testing behavior not in description. Add to description or remove.
6. Wrong test framework — using `bun test` when repo uses jest. Match the repo.
7. Base tests subset — running fewer tests than full suite. Run the full base list.
8. test.sh switches build tags — different tests in base vs new. Single source of truth.
9. Solution bugs in unhandled edge cases → manual edge-case test before submit.
10. Unrelated changes in solution.patch → drive-by refactors. Strip them.
11. Breaking API changes → modify additively (overload / new method).
12. Description tests an unstated inverse — "X happens when Y not configured" doesn't imply "X must NOT happen when Y IS configured." State both or test only one.
13. Hidden requirements (all AI agents fail) — description must mention all tested behaviors.
14. Solution under 100 LOC for Mars → too easy; expand scope or pick another candidate.
15. Description uses inline code where prose works — `(float64)` should be "the rate is a decimal number."

---

## Appendix C — File-by-File Crib Sheet

```
Mars Approved V2/Feature Requests/
├── pest/
│   ├── pest-extended-skip/           ← multi-file Rust, public API + enum, JUnit-via-bash
│   ├── pest-factorizer-fixpoint/     ← single-pass rewrite, fixpoint loop, JUnit-via-bash
│   ├── pest-unused-rule-elim/        ← new modules + parallel APIs, JUnit-via-bash
│   └── pest-validator-hardening/     ← single-file diagnostics, substring error tests, JUnit-via-bash
└── lightningcss/
    └── lightningcss-selector-simplify-fixpoint/  ← olympus-base, fixpoint over CSS, JUnit-via-bash
```

Each folder has the canonical 5 deliverables. Open the closest match in a side-by-side editor and use it as scaffolding.

---

## Patterns 17–51 — Specialized Patterns

**Moved to dedicated file:** `PATTERNS-ADVANCED.md`

- Pattern 17 — Trap-Stacking Ceiling: Shape > Trap Count
- Pattern 18 — Test File Compile-Time Decoupling
- Pattern 19 — JUnit XML for Multi-Package Test Surfaces
- Pattern 20 — Spec Qualifiers That Eliminate Fairness Contests
- Pattern 21 — Kong CLI Flag Validation Anti-Pattern
- Pattern 22 — Namespace Expansion + Maintainer Philosophy Check (**CRITICAL — #1 reject cause**)
- Pattern 23 — Public API Split as Repeatable Integration Trap
- Pattern 24 — Spec-Compression Seesaw as Ceiling Diagnostic
- Pattern 25 — Opt-In Flag Pattern for Safe Semantic Extension
- Pattern 26 — Unified Error Substring Across Multiple Collision Dimensions
- Pattern 27 — Build-Tag Isolation for Test Files Referencing Solution-Only API
- Pattern 28 — `(including null)` Parenthetical to Pre-Empt Null-as-Missing Trap
- Pattern 29 — Parser-Flag-Elevation Regression Trap
- Pattern 30 — Test Architecture: 3 Valid Patterns + Reviewer-Rotation Strategy
- Pattern 31 — Auto-Review Verdict ≠ Final Approval (Contestation Hierarchy)
- Pattern 32 — Post-Base Maintainer Activity
- Pattern 33 — Triviality Filter for Additive-Function Picks
- Pattern 34 — Concrete Counter-Example Hint (Architectural Trap Disambiguation)
- Pattern 35 — Implicit-Contract Audit (Pre-Submit Fairness-Round Pre-Empt)
- Pattern 36 — Failure-QA Citation Triangulation Discipline (Diamond validator-iteration cost reducer)
- Pattern 37 — Pre-existing Loose Helper as Stricter-Predicate Trap (★★★★ Diamond trap source)
- Pattern 38 — Helper-Defined-But-Not-Wired Trap (★★★ Diamond trap source, stacks with 37)
- Pattern 39 — Strict test.sh Argument Validation (V2-carryover defense)
- Pattern 40 — Representation-Type Pin as Compile-Unfairness (**ANTI-PATTERN — tier-agnostic fairness**)
- Pattern 41 — Cost-Test-or-Decorative: difficulty erodes without a perf assertion (tier-agnostic difficulty design)
- Pattern 42 — Choke-Point Triviality: push difficulty to the consumed-and-discarded value (extends 23/33)
- Pattern 43 — Distribution/Determinism Hash Trap (tier-agnostic anti-agent trap for sampling/bucketing/shard)
- Pattern 44 — Diamond failure-QA validator grouping-binding
- Pattern 45 — Diamond QA two-gate: value-anchored vs behavior-anchored citation
- Pattern 46 — Concept-similarity collision on a same-repo introspection-API family
- Pattern 47 — External-test-package exact-type import is an API-shape compile-collapse
- Pattern 48 — Compile-Time-Transform Shallow Well: engineer + MEASURE difficulty per lever (**★★★★ — compiler/interpreter picks**)
- Pattern 49 — Failure-QA root cause must be artifact-grounded; cascade-split; re-verify UI buckets
- Pattern 50 — QA validator anchors on PER-RUN observables, not mechanisms (csstree; 3rd validator confirmation: baseline=platform-count, testNames-arrays-give-grouping, verbatim-call-form)
- Pattern 51 — Measure before trapping; 3-rollout fluke; unstated-convention → spec not hint; reactive 2-lever hint (csstree)
- Pattern 52 — Failure-QA backticked-token grep gate; parent-rollup-Failed; per-run-actual-data; trajectory-step quality-lift (yaegi-const-representability; 4th validator confirmation)

Read `PATTERNS-ADVANCED.md` for namespace check (Pattern 22, every scope change), trap-ceiling diagnostics (Pattern 17 + 24), post-base activity audit (Pattern 32), pre-submit fairness audit (Pattern 35), Diamond failure-QA triangulation + two-gate discipline (Patterns 36 + 44 + 45 + 49 + 50 + 52), Diamond trap sources (Patterns 37 + 38), tier-agnostic difficulty-design + fairness traps (Patterns 40–43), and — for any compiler / interpreter / language-feature pick — the shallow-well difficulty-engineering + measure-before-trapping rule (Pattern 48 + 51, lead with types + measure each lever before adding more).

## starlark-rust-set-literals (APPROVED Mars 2026-06-25)

Reusable Mars pattern: a SATURATED / pure-sugar syntax feature (set literals = sugar for set([...]), no native-vs-desugar divergence, no fair feature-level trap) CAN still ship as Mars when the difficulty comes from LONG-HORIZON THOROUGHNESS, not the feature. Mechanism: a cross-subsystem syntax/opcode change that necessarily BREAKS existing baseline goldens (an obsoleted parse-fail case + the bytecode opcode-profile snapshot). Most agents run only focused new tests and skip full-suite validation -> baseline red -> fail; the thorough agent that runs everything and fixes the goldens passes. Landed 1/13 = 8% (Hard). When you have a saturated feature with no feature-level trap, check whether the cross-subsystem change breaks fair existing baselines -- that thoroughness gap is itself an in-band Mars trap.

MARS LONG-HORIZON GATE: measured on AGENT sustained effort = FILE COUNT + MESSAGE COUNT, NOT raw LOC volume. 25 files / 301 msgs / 343 LOC PASSED Mars long-horizon. Do NOT apply the Olympus LOC-volume intuition (Olympus weights LOC; data-forge passed at ~1100). A ~230-eff feature that spans 22-25 files (exhaustive enum-variant fan-out) is a legitimate Mars long-horizon task.

## cel-go-cost-coverage (APPROVED Mars 2026-06-24)

google/cel-go #1105 opt-in `OptionalTypesCostTracking()` -- optional-types library brought into CEL's cost system (static estimator + runtime tracker + size-aware base64). 192 eff / 5 files / 31 tests, ~25% pass (13-run). Designed Diamond, re-tiered Mars (honest eff ceiling ~190-210, under the 400 Olympus floor).

- ⭐ **Platform checks can CONTRADICT each other.** Same behavior (runtime-charging or/orValue) rejected 3 ways (Test-Fairness unfair / earlier round opt-in-leak / later SQ demands the opposite). Resolution = align meta.md to the fair, library-consistent behavior and flag the reviewer; do NOT implement the twice-rejected thing or ping-pong the code. See Pattern 58.
- ⭐ **STALE-CHECK: cross-validate before fixing a ghost.** An SQ FAIL cited a test deleted the prior round ("still failing"); the same-run Test-Fairness output enumerated the LIVE set (test absent) -> SQ ran on a cached merged report. When a check names a removed test/symbol, cross-check another fresh check before re-fixing.
- ⭐ **GIVEAWAY AUDIT (too-easy lever).** A meta sentence "Two/Three spots are easy to get wrong: ..." that NAMES the pitfalls spiked pass to 60% too-easy. Strip any sentence that spotlights WHICH requirements are the hard ones; state each plainly and let the trap stay silent.
- ⭐ **UNFAIR-API MASKS too-easy (planck pattern).** R1 looked 40% but an undocumented report-API's Go method signatures compile-failed 5/6 runs -> ~90% fair-pass underneath. FIX = DROP the ambiguous inspection surface, do not specify it -- an inspection/report API over an already-computed value = pure glue = 0 difficulty + 100% of any signature-ambiguity unfairness. Canonical string terminal in cost tests = `contains("z")` ONLY (it scales + stays a sound upper bound + saturates the size; endsWith/startsWith undershoot, size() is O(1)/vacuous).

## glaredb-ordered-aggregates (APPROVED Olympus 2026-06-27)

GlareDB/glaredb. Aggregate `FILTER (WHERE)` + aggregate-local `ORDER BY` for `string_agg`/`first` + new `last`, `arg_min`/`arg_max` (`min_by`/`max_by`). 775 eff / 16 files, cross-subsystem (parser->resolver->binder->aggregate framework->execution). Two batches in band: 1/10 (10% Hard) then 2/12 (16.7%) after a reviewer change request; all fair, Holistic PASS. Base 549b01cb.

- ⭐⭐ **The durable Olympus trap = obvious design works, repo-specific path silently breaks it.** Global-sort-before-aggregate passes non-DISTINCT + grouped ordering, SILENTLY fails `string_agg(DISTINCT x ORDER BY x)` (glaredb's distinct path hash-scans -> scrambles order; output `c,a,b` misdirects toward "sort broken"). Fix = dedup-after-sort in aggregate state + operator `is_distinct=false`. Sank 3-5/12 alone, retry-resistant. See Pattern 60.
- ⭐⭐ **Reviewer "broaden scope / near the size bar + boilerplate" = add a SIBLING aggregate family, not plumbing.** arg_min/arg_max reused the comparator/state helpers (581 -> 775 eff real logic). Broadening with EASY siblings is band-safe (10% -> 16.7%, still <=20%) when the gating trap is independent of the easy surface; put easy new tests at the slt END so failing runs keep their failure point.
- ⭐ **Introduced defaults MUST match the repo's analogous default.** Aggregate ORDER BY NULLS default had to mirror glaredb's regular ORDER BY (`None => desc`: ASC NULLS LAST / DESC NULLS FIRST). A divergent default is the latent bug a reviewer's "pin the default" note exposes.
- ⭐ **Free trap from a repo invariant:** FILTER implemented by CASE-wrapping every aggregate arg turns string_agg's constant delimiter non-constant -> hits the pre-existing "2nd arg must be constant" rule. Reject test asserts the BEHAVIOR (bare `statement error`), never the exact wording.

## symengine-imageset (APPROVED Mars 2026-07-02, 10% Nova 1/10)

C++ CAS (symengine), single-subsystem (sets.cpp), 149 eff LOC solution. Feature: `ImageSet::contains` + intersections (finite / bounded-interval / progression-CRT / ambient number-sets).

- **Difficulty came from ONE wall, not the algorithm.** CRT is textbook; the fair-hard part was a repo-internals integration wall: the canonical-type NARROW-GUARD (agents gate interval-enumeration on `is_a<Integers>(*base)`, forget Naturals/Naturals0 are also integer-indexed; the `base->contains` delegation the meta mandates for MEMBERSHIP is not re-applied in ENUMERATION). 9/10 Nova missed it. See `PATTERNS-ADVANCED.md § Pattern 62` + `AGENTS.md`.
- **The tighten-first swing is the transferable lesson (3 measured batches):** R1 50% (one coverage trap) -> R2 **100%** after I ADDED a meta sentence naming the seam ("both orderings evaluate") + grew the desc to 375w -> R3 **10%** after tightening meta to 217w (math WHAT only, zero seam-hints) and moving every trap into TEST DESIGN. Solution.patch UNCHANGED across all three; only meta + tests moved the number. Harden by TIGHTENING description, never by naming the mechanism.
- **Repo caveat:** CAS kernels are saturated-reference (SymPy-documented); shipped as fair Mars via the integration wall, not the math. Do not expect Olympus depth from CAS features. C++ harness: catch2-v2 junit + crash-fallback XML; test.sh must `cmake --build` so runtime-applied solution.patch takes effect.

## nickel-enum-widening (APPROVED Mars 2026-07-04, R3 30% 3/10, Holistic+Auto Review PASS)

Rust typecheck subsumption (single file `subtyping.rs`), enum + FUNCTION width subtyping. 146 eff LOC, 17 f2p tests. Arc: R1 0/10 -> R2 ~44% -> R3 30%.

- **HARDEN a too-easy single-subsystem feature by adding a SECOND, orthogonal subtyping-constructor arm -- NOT more tests.** R2's ~44% was chore-only (update a golden + a manual doc = coin-flip). The lever that shaved 44->30 was adding FUNCTION (arrow) subtyping next to the enum arm: a new REQUIRED behavior reference-only solvers never wrote, whose contravariant-domain rule is a self-loading over-generalization trap (2/10 flipped a negative golden to pass). Additive positive tests moved nothing (Pattern 17); a new co-equal axis did. Law: passers wrote ~the reference -> to lower pass rate, require behavior BEYOND it.
- **TIER-GATE LAW (submit-time): the auto Difficulty + Long-horizon gates key off the SELECTED tier.** 30% + Holistic PASS + Auto PASS, but `agentDifficulty`+`agentLongHorizon` FAIL under Olympus judging; select MARS and both clear (Mars cap <=30%; long-horizon is Olympus-only). Pick the tier the feature SIZE supports; don't bloat a 146-LOC feature to chase an Olympus long-horizon bar it can't honestly meet.
- **A behavior-CHANGING typecheck feature needs a meta "validate the full existing suite" sentence.** The change flips an existing type-error golden (MissingRow->ExtraRow) + an executable manual doc-snippet (error->value). Without the warning it reads as unfair hidden-baseline; WITH it, it's fair discoverable maintenance (Holistic ruled fair on exactly that sentence). Rust harness = cargo2junit, never chmod /root ([[lesson_olympus_base_rust_docker_cargo2junit]]).

## nickel-1336 dict `_` catch-all metadata (APPROVED Olympus 2026-07-04, 1/10 = 10%)

Rust dual-crate feature (parser `nickel-lang-parser` + core `nickel-lang-core`): attach field metadata (`doc`/`optional`/`default`/`force`/`priority n` + chained contract + default value) to the `_` catch-all of a dict contract `{ _ | T }`, applying to every field -- static, runtime-inserted, computed-name, merged, nested, multiple catch-alls. 21 files, 541 braces / 439 human-eff LOC, 26 tests. Full repo playbook: `problems/nickel/LESSONS.md`.

- **★★★ A DUAL-AST (parser + core) feature stacks a COMPILE-FLOOR under the semantic walls -- this is how a single-language Rust feature reaches Olympus.** `_` lives in the TYPE grammar; agents who add catch-all metadata as an ordinary record-field production hit a LALRPOP ambiguity and the crate never compiles (10/14 died here). A new field on the shared `TypeF::Dict` struct then forces missing-initializer fixes (E0063) in the OTHER crate + `ast/compat.rs` bridge. Weak/fast agents (Nova) never reach the semantics; only decisive full-build agents (Orion/Vega) do. Route a Rust Olympus through the parser->core seam; a core-only feature ceilings at Mars (cf. nickel-enum-widening).
- **★★★ HINT-ARC-AGAINST-SHIFTING-WALL (reusable NEEDS_HINTS recovery): a hint fixes its wall and EXPOSES the next.** Add ONE hint per batch, each targeting that batch's DOMINANT failure, until a pass. The 4 walls surfaced in order across 0/14 -> 0/14 -> 0/10 -> 1/10: (1) COMPILE (grammar ambiguity), (2) PROPAGATE (catch-all not re-applied to later insert/merge fields -- `RecordFreeze` DROPS pending state; `std.record.insert` freezes first), (3) MATERIALIZE (agents count the catch-all in `is_empty`/`fields` -> phantom field breaks `== {}` + optional-drop; it's a template, not a field), (4) BASELINE-REGRESS (2 near-sols hit 26/26 new but regressed label-paths/dedup/merge/pretty on plain `{ _ | T }` -- a shared-struct representation leak).
- **★★ Four ORTHOGONAL walls compound to 10%** (piccolo's "5+ orthogonal sub-behaviors" law, confirmed at Olympus): no single agent clears compile + propagate + materialize + baseline-preserve. Solution byte-identical across all 4 batches -- difficulty was 100% test-coverage + hint-wording, never solution depth.
- **★★ Behavioral hints beat mechanism hints on BOTH fairness and effectiveness.** The description-conciseness reviewer FAILs mechanism wording as over-spec ("retained on the record", "record-field syntax", `is_empty`) and SUPPLIES a behavioral rewrite that keeps the nudge minus the HOW ("a catch-all is a template ... not itself a field"). Behavioral = fair (no internal symbol) AND still flips agents (batch 4 passed on it). Keep WHAT, drop HOW. Rust harness = cargo2junit, never chmod /root ([[lesson_olympus_base_rust_docker_cargo2junit]]).

## piccolo-finalizers-gc (APPROVED Mars 2026-07-04, 30% Nova 3/10 all-fair)

Lua 5.4 GC subsystem (weak `__mode` k/v/kv + ephemeron fixpoint + `collectgarbage` option set + `__gc` finalizers w/ resurrection/reverse-order/once-each). 361/364 eff, 6 src files, 72 behavioral tests (Lua-observable oracle only). Three TEST-ONLY hardening rounds (solution unchanged): ~50% -> 53% -> 30%.

- **★★★ BREAK A BIMODAL SINGLE-SUBSYSTEM FEATURE BY STACKING ORTHOGONAL SUB-BEHAVIOR WALLS, not by deepening the one axis.** This pick sat at 53% through R5/R6 because every added test hit the SAME axis (resurrection x ephemeron fixpoint) -> agents who grasped that one mechanism passed all of them (monolithic understanding = bimodal ~50%). R7 spread tests across 4 OTHER orthogonal axes and the rate fell to the 30% cap because no single agent nails all five: (A) resurrection re-feed not propagated to the ephemeron fixpoint [5/7, misdirects as a `gc_arena header.is_live()` panic], (B) `collectgarbage` multi-arg consume [`Stack::consume` drains the whole stack -> 2nd consume empty -> wrong setpause/setstepmul prev, 3/7], (C) once-each broken across resurrect-then-redrop [re-resurrects a finalized-dropped object, 1/7 SOLELY], (D) reverse-install-order lost, (E) kv treated as ephemeron. Bimodal one-wall ~= 50%; five independent walls compound to ~30%.
- **★★ The kysely/petgraph "single-subsystem = uniform-wrap-capped" law has an EXCEPTION: a subsystem with 5+ GENUINELY-ORTHOGONAL sub-behaviors** (GC qualifies; membership-validation and predicate-injection do NOT -- those are one concept at N sites). Before shelving a bimodal single-subsystem pick, ENUMERATE its independent sub-behaviors; if 5+, stack a fair wall on EACH first. This is the difference between piccolo-finalizers (shipped) and kysely/petgraph (shelved).
- **★★ For a "propagates to a fixpoint" behavior, ship BOTH a shallow and a DEEP test.** `resurrection_feeds_two_level` caught no-refeed agents; `resurrection_feeds_deep_chain` (6-link) additionally caught BOUNDED-refeed agents (re-mark 1-2 levels, not to a fixpoint) -- a distinct sub-class. Two discriminators, not one.
- **★ Strongest misdirection = a correctness bug that surfaces as a library-internal PANIC** (`gc_arena: assertion failed: header.is_live()`), naming the wrong file rather than "you cleared a weak entry too early." Difficulty was 100% a test-COVERAGE problem here (solution byte-identical across all 3 rounds). At-cap-edge (30% = Mars max) so a variance-y future batch could tip over -- prefer 15-25% when the orthogonal walls allow. See Pattern 65 + PROBLEM-PROFILES + KNOWLEDGE (Nova GC blind spots).

## gimli-type-units (APPROVED Mars 2026-07-05) -- cross-section routing as the difficulty lever for a convert feature

When a single-subsystem feature is a faithful read->write->read CONVERT (the reader is the oracle), stacking new-behavior walls does NOT harden it -- agents mirror the reader for free (proven: 3 batches at ~100/47/70%). The lever that works: make the writer emit to a NEW section, forcing an invasive refactor of the SHARED write pipeline. Concretely here: DWARF v4 type units belong in `.debug_types` (not `.debug_info`), so the reference adds a `DebugTypes<W>` write section + generalizes the shared DIE-writer (`entry.write`/`AttributeValue::write`) off `DebugInfo<W>` to raw `&mut W` + routes by version + extends convert to iterate `read_dwarf.type_units()`. That cross-cutting refactor is what agents botch (14/20 compile-fail), landing 5-15% at Mars with 249 surgical eff LOC. Design note: keep the reference's generalization MINIMAL (2 signatures + ~5 offset sites) -- the wall is that agents can't find the clean version, and the median passing agent wrote 2.5x the LOC. Do NOT pad to reach the Olympus floor; a hard cross-subsystem wall can be legitimately sub-450 -> ship the honest tier (Mars). Pre-submit: run the repo's OWN CI gates (`cargo fmt --all -- --check` for gimli) and make `test.sh` base run the `tests/` integration target that exercises the refactored shared path (e.g. `--lib --test convert_self`), not just `--lib`.

## nickel-array-rest (APPROVED Mars 2026-07-05, 6/20 = 30% Nova all-fair)

Cross-crate (parser + core) Rust surface-syntax feature: extend array patterns so the rest `..`/`..name` may appear in ANY position, not just trailing. 139 eff LOC, 7 src files, 25 tests, base f2f8588. Auto Reviewer APPROVED high-confidence; 20x Nova unhinted = 30% (AT the Mars cap), all fair, diverse failure clusters.

Reusable takeaways for Mars authoring:
- **Build-measure the tier before promising it.** Cross-crate span did NOT make this Olympus -- a position-agnostic AST representation (a boundary index that keeps new elements inside the existing slice) left typecheck + binding passes + the parser->core bridge unchanged, so the whole feature is 139 eff = Mars. Do not pad a well-factored feature to the 450 floor.
- **Clear the Mars 100 floor with a real adjacent gap, not padding.** The core rest feature was 94 eff; adding duplicate-binding validation that MIRRORS an existing sibling (records reject `{x,x}`, arrays did not) lifted it to 139 with a genuine, fairly-testable requirement and zero base regression.
- **For rejection sentences, check base FIRST.** If base already rejects the invalid form (parse error) and your solution's error wording is new/undiscoverable, the case is not fairly f2p-testable -- do not describe or test it; keep the internal validation only. This one detail caused a 3-reviewer loop; see PATTERNS-ADVANCED Pattern 67.
- **30%-at-cap = do not touch after approval.** Any edit re-stales the Auto Reviewer approval + the batch and re-triggers every gate.

## parry-heightfield-point-projection (APPROVED Mars 2026-07-05, 3/10 = 30% Holistic-PASS all-fair)

Rust geometry (dimforge/parry). Point-projection feature/location for grid shapes (HeightField + Voxels, 2D+3D). 122 human-eff / 4 src files / 27 tests / cargo2junit. Hardened 70% -> 30% by DEEPENING THE CORE (Pattern 68), not padding: primary trap `height_at_point` TRIANGULATED-not-BILINEAR (naive-dominant-reading), plus private `split_triangle_id` re-derivation (non-square grid), directional voxel cube-faces, far-above projection completeness, de-prescriptivized meta. Emergent free trap: de-crutching a private helper broke a `usize`->`u32` type contract. LOC-ceiling at pick (clean core 54 eff bc `convert_triangle_feature_id` pre-shipped + ray-consumed) -> scope-expanded to the grid-shape family; `feature_normal_at_point` 4th axis blocked by open PR #356.

## aircompressor-zstd-strategies (ACCEPTED Mars 2026-07-06, R2 1/10 = 10%, Auto Review PASS)

Java pure-zstd (airlift/aircompressor, #162). Implement the missing block-compressor strategies (fast/greedy/lazy/lazy2/btlazy2/btopt/btultra) + 3-repcode + lift the SequenceEncoder LAZY+ throw + level-aware `ZstdOutputStream(OutputStream, int)`. 663 human-eff ref / 10 files / 37 tests / olympus-base-jvm offline. **TIER-BY-PASSING-LOC pivot (Pattern 69):** authored/hardened for Olympus (50% -> 10% via breadth of fair walls) but the sole passer's human-eff = 289 (aliases all 7 strategies to ONE hash-chain) << Olympus 450 -> shipped as a hard MARS (289 in the 170-380 sweet spot, 10% = hard edge of <=30%). Option-2 (force the public-API family) was futile -- the passer already wrote it at 289. Difficulty from adversarial-correctness corpora (repcode/ll0, MIN_MATCH=3) + a streaming writeChunk-invariant crash wall (killed 3/10) + a ratio floor (killed 5/10). New-public-API f2p via reflection `getConstructor` -- fair only once the meta NAMED the exact ctor signature.

## kcl-union-override-typecheck (APPROVED Mars 2026-07-07) -- the passer-LOC gate + machinery-reuse pick screen
- THE LOC FLOOR IS THE LEANEST PASSING AGENT'S RAW DIFF, NOT YOUR REFERENCE. Human reviewer rejected R1 because the sole passer solved it in 94 raw production LOC (my ref was 114 Counter2). Reviewer counts RAW added production lines (called 94 "generous" for a diff whose strict count was 69). Estimate the LEANEST passer and design so IT clears 100 raw.
- PICK-TIME SCREEN for "check X the same way as existing Y" features: locate Y's checker. If an agent can reuse it in <100 LOC, the passer floor collapses no matter how much you write. KCL's config-context recursion machinery let the passer add ~40 LOC and get all nesting for free. Either pick a different feature or pre-plan a structural lever.
- STRUCTURAL-LEVER FIX: require the one form the reusable machinery structurally can't reach. Here `|=` compound assignment routes through walk_aug_assign_stmt->binary(), not walk_binary_expr where agents put the check, so the reused helper never sees it. A `|=` test family forced the passer +27 LOC (94->121 raw) -> cleared 100. Cross-ref Pattern 71.

## stoolap-comparison-consistency (APPROVED Mars 2026-07-07, 1/10=10%) -- open-policy pivot + multi-join-algorithm completeness

Make SQL comparison operators (`=`/`<>`/`<`/`<=`/`>`/`>=`, column-vs-const, join, IN + row form, subquery IN, NULLIF, CASE, IS DISTINCT) mutually consistent across every coercion path in a Rust embedded SQL engine. 4-file solution (value.rs/vm.rs/hash_table.rs/utils.rs), 170 eff LOC, 33 tests. Journey: 50% (P72 open-policy thoroughness gate, un-lowerable by breadth) -> numeric-coercion PIVOT (P72 close-policy misdirection: `10 > '9'`, repo `Value::compare` string-coerces so every passer's reuse is WRONG) -> 16.7% auto-approved -> HUMAN "solution too narrow" -> P73 multi-join-algorithm completion (fix the MERGE JOIN `compare_values` ordering, not just the parallel path the reviewer named) -> 1/10 = 10% re-approved + accepted. Dominant wall = the join-hash bucketing (interdependent+misdirecting: scalar equality passes but the type-discriminated hash keeps int/text in separate buckets -> 0 join rows). Two reusable Patterns: 72 (close an open policy for a misdirection wall) + 73 (a consistency feature must cover EVERY join algorithm the planner can pick, routed by size+sortedness). CLOSING an open policy also made ordering PIN-ABLE (retired a Test-Fairness over-pin FAIL).

## numbat-const-exponents (APPROVED Mars 2026-07-09, 9%)

- Named `let` constants (+ arithmetic over them) as dimension/unit exponents, exact rational; sharkdp/numbat Rust units-lang. Hardened 60%→20%→9% via Tighten-First Rule 7 (meta 160→79w, seam-delete) + interdependent TEST DESIGN traps. Dominant trap = negative-const arithmetic type-gate (see PATTERNS-ADVANCED Pattern 74 / KNOWLEDGE Nova blind spot / PROBLEM-PROFILES P74). Reusable techniques: COMBINED positive+negative f2p test (resolves per-test-f2p × quality-needs-rejection); name-keyed const map clear-on-rebind; delete parser-span-shifted unrelated snapshots for Task-Quality fairness.

## scryer-clpq-linear (APPROVED Mars 2026-07-09, 30%)

New `library(clpq)` (linear rational CLP: `{}/1`, exact rationals, disequality, delayed nonlinear, `entailed`/`inf`/`sup`/`minimize`/`maximize`) added to mthom/scryer-prolog by editing an embedded `src/lib/*.pl` (build.rs auto-registers it - zero Rust changes). Reference = Gaussian solved-form + Fourier-Motzkin + attributed-variable store (`library(atts)`), 309 C2. NEW-LIBRARY-MODULE = MARS BY NATURE: the platform Task-Quality post-check FAILs a single-module feature as "too localized for Olympus" regardless of LOC/depth (SPAN, not depth, is the Olympus axis) - a 415-C2 attempt with reify/dump/label bolt-ons was trimmed to a lean 309 Mars. Hardened 40% (batch1) -> 30% (batch2) by SEAM-STACKING (PATTERNS-ADVANCED Pattern 75): tests that force determination through ONE channel to re-fire ALL consumers, catching partial impls that pass each behavior in isolation. Three reusable laws in lessons-learned: HARNESS-FIX-UNMASKS-TRUE-RATE (a fragile fail-inflating harness masked a too-easy 40% as 1/10), CHECK-COLLISION (a conciseness "delete redundant clause" orphaned a fairness-dependent test), Docker `cargo build --tests` not `cargo test` (rubric bans cargo test in build) to warm dev-deps.

## erg-chained-comparison (APPROVED Mars 2026-07-10, 30%)
Shape D-new x O-Composite-add (new `Compare` node parser->desugar->lower->bytecode+transpile), Mars by C2 (343, 15 files). WINNING LEVER: precedence-boundary between the NEW chain and EXISTING lower-precedence `and`/`or` = dominant trap (3/7 fails; `1<3<2 and 4<5`=True on a narrowly-scoped chain). Hardened 70%->30% by probing every seam in BOTH backends + de-prescriptivizing meta to the "exactly as CPython" external-spec umbrella; reference UNCHANGED. See Pattern 76 (precedence-boundary trap) + PROBLEM-PROFILES.

## zen-table-verification (APPROVED Olympus 2026-07-10, 1/10=10%)

2nd zen sub (after zen-hit-policies) on gorules/zen @7805da79. Greenfield SEMANTIC decision-table verification: replaces the syntactic policy linter (`shadows()` string-equality) with an N-D cover-algebra engine (extends the existing NumberCover/ArmTest intellisense machinery) detecting UNREACHABLE rules + INCOMPLETE input coverage, driven from BOTH the graph `Decision::verify() -> Vec<TableWarning>` AND the policy analyzer. O-Composite-add, cross-crate, C2 468, 43 tests. THE lesson: a greenfield analyzer is a THOROUGHNESS gate -- two batches at 90% (documented+independent+self-revealing traps get implemented one-by-one by thorough Nova). Hardened 90% -> 10% by ENGINEERING one machinery-riding wall (Pattern 77): rework unreachability AND completeness to share ONE extended (value+absence) domain via a `column_domain -> Domain{region,nullable}` chokepoint, so a non-nullable numeric wildcard-after-tiling must be unreachable while a nullable wildcard stays reachable. Sole difficulty driver across 19 runs. Two more laws: a coverage test is NOT a difficulty knob (Pattern 77 corollary), and a collection-aggregating API needs a >=2-element UNION test (Pattern 78, cost a human revert). Mojibake patch-gen (bash-redirect not python text=True) and ERROR-WORDING (assert missing VALUE not message phrasing) carried over from zen-hit-policies. Full repo authoring reference: `problems/zen/LESSONS.md`.

## go-geom-polygonize (APPROVED OLYMPUS 30% 2026-07-13)

Olympus, O-Composite planar-graph subdivision (JTS Polygonizer) in twpayne/go-geom. 3 files / 2 pkgs, human-effective 346, 46 tests, 6 interdependent+misdirecting traps. base 4deaa45c.

Key reusable takeaways (detail in Pattern 34 + PROBLEM-PROFILES):
- Lift single-subsystem -> Olympus by adding a cycle-safe consumer in a SECOND package (Task-Quality 08 gates the solution diff, not test imports). Map the import cycle first.
- Cure FP-bleed by testing each requirement on its HARDEST instance (non-representable crossing coords), not one clean case; probe the reference first.
- Output-convention lever: go-geom inverts SignedArea sign, so a winding assertion is a free misdirecting trap.
- On human review, remove provably-dead guards (name the invariant that makes each unreachable); an absolute-epsilon guard in an unspecified unit is a latent unit-bug.

## truck-mass-properties (APPROVED Mars 2026-07-10, 2/10 = 20%)
Non-SQL pivot (ricosjp/truck CAD kernel) -- add rigid-body mass properties to the `CalcVolume` trait. Textbook computation that capped ~43% mean (single self-revealing Solid-NaN wall). Broke the ceiling with an INDEPENDENT numerical-stability wall (far-from-origin translation invariance catches the textbook accumulate-about-origin impl) -> 20%. A correlated right-handedness `det=+1` wall moved nothing. Two human reverts survived: degenerate-eigenvalue NaN (cube -> Jacobi eigendecomp, assert the invariant not a basis) and release-build `missing_docs` (pub API needs `///` docs or `cargo build --release` fails while debug tests hide it). See `PATTERNS-ADVANCED.md § Pattern 80` + `PROBLEM-PROFILES.md § truck-mass-properties`.

## scryer-clpq-linear (APPROVED OLYMPUS 2026-07-16, 1/10 = 10%)
Invented from-scratch `library(clpq)` for mthom/scryer-prolog as a 3-file solve->project->render pipeline (clpq.pl solver + clpq_dump.pl dump/3 FM projection + clpq_io.pl DCG render). 541 eff LOC, 121 per-check tests, base 295a642. The longest journey in the set: Mars-approved 30% -> human-reverted twice (7 solver bugs + harness; then the Olympus >=2-meaningful-file rule) -> 3-file redesign -> 3 Test-Fairness FAILs (dump-pivot ambiguity, serialization format, empty-render) -> reviewer-caught latent dump pair-order bug in my own reference -> 0% NEEDS_HINTS -> HINT-IN-META (fold the holistic hint into meta as a WHAT-principle, Pattern 81) -> unhinted 10% + Auto Review approved -> human approved (Desc 3/3, Tests 2/3, Solution 3/3). Dominant walls: dump canonicalization (7/10), full-store entailment (6/10), io_rat rendering (killed a 120/121). Freeze-on-approve held: 2 LOW T4 notes cited by BOTH auto and human, non-blocking both times. See `PATTERNS-ADVANCED.md § Pattern 81` + `PROBLEM-PROFILES.md § scryer-clpq-linear (Olympus)`.

## neva-array-bypass-generalization (APPROVED Olympus 2026-08-01)

Go, dataflow-language compiler + runtime. O-Composite-add: generalise one connection form across analyzer, desugarer, IR generation, runtime and stdlib. 6 files / 4 subsystems, 282 effective LOC (Counter 2), 21 e2e tests, 2/10 = 20% across Nova+Orion.

Two traps on different axes carried it, and neither is a rule you can transcribe from the prompt:

1. **Cross-stage resolution drop** (`failure-patterns.md` F-9, 6/10) — the lead. One root cause breaks every capability at once, which is how you get trap INTERDEPENDENCE without bolting a second mechanism onto the design.
2. **Capability cross-product cell** (F-10, 8/10) — the decider. Test the intersection of two stated axes, not just each axis.

Everything else measured as noise: 11 of 21 tests killed nothing, and two deliberate hardening rounds produced zero independent kills. Effort spent adding more instances of a covered axis buys nothing; effort spent on an empty off-diagonal cell decided the band.


## numbat-parse-unit-expressions (APPROVED Olympus 2026-08-04)

Three builtins over one shared grammar (`parse` extended, `unit_from`, `value_in`) — O-Composite-add.
3 files, 393 effective LOC, 88 tests, final 2/10.

The transferable lesson is about WHERE the band came from: not the lead trap. Half of it came from
**F-12** (repo-test preservation) and the rest from small grammar cross-products. 81 of 88 tests
killed nothing. Budget hardening effort on un-tested intersections and on the harness axis, not on
suite breadth — this suite was roughly 3x the size of the approved median and the extra breadth
bought no discrimination.

## rust-minidump-stack-containment (APPROVED Olympus 2026-08-06)

Rust, crash-dump stack unwinder. 9 files / 3 crates, 327 effective LOC, 49 tests, meta 523 words.
**2/10 Nova**, FP clean, Auto Review 3/3 / 3/3 / 3/3. Shape: O-Composite-add.

**The pick.** Three orthogonal axes over one walk loop: containment (a frame whose stack pointer
leaves the thread's stack is kept but recorded at reduced trust), corroboration (a scanned guess
landing on published unwind info is raised to `CfiScan`), and a symbol-file declaration that a code
range has no caller. Each has a stated precedence against the others, which is where the difficulty
lives — not in any one mechanism.

**What made it work as a PLAYBOOK shape.** The feature spans a parser (breakpad-symbols), a control
loop (minidump-unwind) and two output surfaces (text + processed JSON) without adding a new
subsystem to any of them. That is why 327 effective LOC across 9 files cleared the floor while
staying reviewable, and why the reference solution scored 3/3 on scope — every change sits on an
existing extension point (`FrameWalker` default method, `StackFrame` fields, conditional JSON keys).

**Reusable moves:**

- **Conditional output via `as_object_mut().insert()`** so new JSON keys are OMITTED rather than
  null when there is nothing to report. Ten insta snapshots stayed byte-identical. This is the way
  to add output to a snapshot-tested processor without a churn review finding.
- **Answer a "does the machinery know about X?" question through an EXISTING API** rather than a new
  trait method. A probe implementing the repo's own `FrameWalker` and latching the range callback
  removed a shape collision with an open upstream PR, cut new trait methods 1 → 0, and ADDED honest
  LOC because the probe is real code.
- **Word budget is not the constraint; density is.** meta went 466 → 523 words across the run. The
  band-2 finding was *density*, fixed by splitting 7 long paragraphs into 13 single-topic ones at
  identical word count. Headers stay banned; shorter paragraphs buy the same scannability.

**Cost warning.** 28 rounds for one batch, almost all review response. Two of the top three killer
tests came out of those late rounds, so the cost bought difficulty — but budget for it.

## lyon-fill-internal-vertices (APPROVED Olympus 2026-08-07)

O-Algorithm-correctness. 45 tests, 260 human-effective LOC / 4 files, 1/10 accepted.

Playbook additions:

- **Write test helpers in the contract's vocabulary (F-17).** The helper is part of the contract
  surface. A topological `interior_vertex_count` proxying a geometric "full neighborhood" contract
  let a non-manifold interior vertex pass the entire suite; the direct geometric replacement became
  the top killer at 8/10 and the sole failure of both near-misses.
- **Opt-in is the right shape when the maintainer calls current behavior "by design".** lyon's owner
  invited an implementation on issue #871 while calling the existing output a byproduct of the
  algorithm. Default-off with byte-identical disabled output satisfied both, and all 30 runs passed
  185/185 baseline.
- **Prove the fixture bites before trusting it.** Three fixtures I named "hole_inside_overlap" were
  measuring the plain union: one clockwise subpath inside a depth-2 overlap takes winding 2 -> 1 and
  does NOT punch a hole. Two opposite-wound copies are needed. Always check the area arithmetic.


## gluon-format-comments (APPROVED Olympus 2026-08-07)

Formatter comment preservation in gluon. 3 files, 243 effective LOC, 37 tests, 1/11 accepted.

Reusable from this one:
- **F-18 token-form parity** is the cheapest band lever measured after F-10: one test per position
  per lexical form, zero description words beyond a single "both forms behave this way" sentence.
- **Unsolvable is a scope problem, not a wording problem.** Three consecutive 0-pass batches were
  fixed by dropping one axis, not by explaining it better. Wording moved the rate by 1-2 runs;
  dropping the axis moved it from 0 to a pass.
- **Formatter tasks come with a free idempotence assertion** if the repo's test macro formats twice.
  gluon's `test_format!` does, which made every case a round-trip check at no authoring cost.
- **Two pre-existing baseline defects** (`format/tests/std.rs` tokio features, `tests/vm.rs` trait
  bound) meant `cargo test` at workspace level never compiled on this commit. Scope test.sh to the
  targets that build and document why; expect solvers running a bare `cargo test` to burn messages.

## vrp-tsplib-edge-weight-types (APPROVED Olympus 2026-09-02)

Shape O-Composite-add: a new parser capability inside one crate (TSPLIB non-Euclidean edge-weight
types in `vrp-scientific`) plus a cross-crate export surface (`TsplibLocations` trait ->
`get_tsplib_locations_serialized` in `vrp-cli` -> the existing `solve tsplib --get-locations`
command). 8 files, 374 effective LOC, 35 new tests, 60 base. Accepted at 3/10.

**The lead trap is worth copying wholesale.** The cross-crate CLI surface was not scope padding —
it was the entire difficulty. When a repo's library entry point logs to stdout and you add a
command that must emit machine-readable output on the same stdout, you get a wall that no fairness
round can disclose away, because the fair sentence ("have the command return this JSON") is also
the sentence an agent reads as satisfied the moment its serializer is right. Four batches, never
below 50% kill, never flagged unfair. Registered as F-19.

**Two authoring rules this problem paid for:**

1. **Assert CLI output from a subprocess test.** `env!("CARGO_BIN_EXE_<name>")` + parse the whole
   of `output.stdout`. An in-process call to the serializer passes on a contaminated build and the
   trap evaporates silently — you will not notice, because your own reference is clean.
2. **Base mode must be validated on a base tree.** Every test file that base mode compiles must
   import base-only APIs. A solution-only symbol in a shared test target breaks the entire target
   on base, and running base mode on your solution-applied worktree cannot see it.

**Test-patch shape that survived agents editing the same files:** keep `test.patch` ADD-ONLY.
An earlier batch lost a run to `3-way test.patch merge failed (exit 1); resetting 6 test-patch
file(s) to base state`. New files in new targets merge cleanly; edits to shared test files do not.

**Batch economics:** 12 batches to acceptance, and the artifact was in band by batch 7. The eight
rounds after that were fairness review, not difficulty — and three of them cost difficulty (see
`failure-patterns.md` L34).

## go-workflows-channel-drain (APPROVED Olympus 2026-09-04)

**Shape:** O-Composite-add — a new capability surface spanning an internal channel/selector/scheduler
core and its public wrappers. 9 files, 351 effective LOC, 102 tests, meta.md 499 words, 2/10 pass.

**The reusable move: guard an adjacent untouched API (F-20).** When the feature adds a sibling to an
existing entry point and the sibling gets a rule the original must not have, scope the rule in the
description by naming ONLY the new API, then test the OLD api in both directions. Costs zero
description words. This was the highest-value 40 lines in the whole submission (8/10 kills, both
near-misses). Precondition: the old behaviour is documented in prose but has no repo test — verify
by breaking it locally and confirming the base suite still passes.

**Band arithmetic worth internalising.** Without that one test pair the batch reads 4/10 = 40%, at
the ceiling. With it, 2/10 = 20%. One cheap test moved the submission from marginal to comfortable.

**Test-effort distribution.** 43 of 102 tests killed nothing — the entire signal-backlog family, all
Peek variants, Cap/IsFull. They bought fairness and FP insurance, not difficulty. The difficulty
lived in ~12 tests across 3 clusters. Expect and accept this ratio; do not mistake breadth for
difficulty (the LOC hook's padding-floor warning says the same thing).

**Iteration cost.** 6 batches / 13 rounds. Six of those rounds edited meta.md, each forcing a
full-price batch. Settle the description before the first batch (L36) — it is the single largest
cost lever in the whole workflow.

## datafixerupper-ordered-alternatives (APPROVED Olympus 2026-09-08)

Shape: composite codec added to an existing combinator DSL (decode scan + encode scan + a builder
boundary). Java, 5 files, 270 effective LOC, 173 tests. Batch 8 2/10 -> batch 9 5/10.

- **90% of the suite bought no difficulty.** 156 of 173 tests killed nothing. 17 carried the band and
  all 17 sit on one subsystem. The strongest L16 instance measured — write the coverage for fairness
  and FP insurance, but do not mistake it for difficulty.
- **Every trap named in DESIGN.md killed zero.** The four designed traps (earliest-partial, lifecycle
  folding, aggregated messages, covariance) were all cleared unanimously. The difficulty that survived
  was found in review response, not design — third consecutive problem where that is true (L22).
- **A 50% batch is approvable but paid at the bottom of the band** and has zero margin against
  batch-to-batch variance. Ship at the low edge.
- **The differential harness projected 0/10 and the batch returned 5/10.** When the round DELETED
  contract clauses, replaying old passing patches measures how far they are from the new spec, not how
  hard the new spec is.


## customasm-derived-bank-layout (APPROVED Olympus 2026-09-09)

Shape: O-Pipeline-hard. The capability was NOT a new subsystem — it moved a quantity out of a
single-pass `eval_certain` pre-pass into the repo's existing fixed-point resolver, and added one
measured quantity read back through an existing value type. 13 files, 980 effective LOC, 68
fixtures, accepted at **1/10**.

Reusable move: **look for a wall EARLIER than the feature you first imagined.** The hunt proposed a
bank-placement solver; the real gap was that a bank field could not depend on anything the assembly
produced. Promoting an existing quantity into the fixpoint is denser than bolting a new subsystem
beside it, and it makes every capability interdependent for free.

Budget warning: 40 of the 68 fixtures killed nothing, and two composite fixtures authored
specifically as difficulty levers killed zero agents. Extent-semantics breadth is fairness and FP
insurance; it is not difficulty.

## rocketpy-propellant-slosh (APPROVED Olympus 2026-09-10)

Python / flight-dynamics. 10 files, 375 effective LOC, 146 tests, four batches.
`0/6 -> 2/10 -> 0/10 -> 1/10 ACCEPTED`.

**The process finding: Re-eval turned a reject into an acceptance for ~30% of a batch.** Batch 3
read 0/10 — unsolvable, a reject. One test-side fairness fix, then Re-eval over the SAME ten
solutions, and batch 4 read 1/10. Nothing solver-visible changed, so the button was offered; the
local differential replay predicted the live result exactly (the flipping run, and the unchanged
one). This is the `RULE UPDATE 2026-09-03` "reads unsolvable" play executed end to end.

Two sequencing rules earned the hard way this cycle:

- **Never fire a smoke run while a Re-eval is pending.** A single run dismisses the offer. It cost
  24 tokens here for an Orion that failed exactly as predicted from its previous batch's patch.
- **Choose the fix DIRECTION by Re-eval eligibility, then by quality.** The same fairness defect
  could be fixed test-side (tolerant reader) or description-side (declare the type in `meta.md`).
  Both are fair; the test-side one keeps the ~30% lane. Prefer the description-side fix only when
  you are already paying for a full batch — at which point description edits are free, so bundle
  every outstanding description change into that round.

**Auto Review now grades the near-miss DISTRIBUTION, not only the rate.** It filed a Medium
advisory that 1/10 "overstates effective difficulty because every failing implementation passed at
least 140 of 146 new tests and the failures were confined to two narrow edge patterns". Benign
here — it did not block acceptance and the patch sizes (7-11 files, 538-873 added lines, 14-30M
prompt tokens per run) rebutted a trivial-solve reading. But a band carried entirely by two edge
cells is now visible to the reviewer as such, so pair edge-cell levers with a wall that costs the
agent a design decision.


## datafixerupper-derived-recursion (APPROVED Olympus 2026-09-11)

Shape O-Pipeline-hard: replace a caller-declared flag with a DERIVED graph. 6 production files,
389 effective LOC, 87 tests, 1/10 across two independent batches.

**The reusable pick shape: "derive X from the existing declarations".** Take a subsystem where the
caller currently DECLARES a property (a `recursive` boolean, a priority, an ordering) and require it
to be worked out from what was registered. The design work is the graph; the DIFFICULTY is entirely
in three side effects the derivation creates, none of which you have to invent:

1. The pass must be total over a namespace with missing keys -> agents replace the repo's throw with
   a sentinel (**F-24**, 8/10 twice).
2. The pass cannot resolve references at write time -> a deferred placeholder escapes into caller
   code (**F-25**, 4/10 twice).
3. The assembly path gets rewritten -> untested behaviour the old path carried is dropped (F-20
   family, 3/10).

**Budget the review cycle, not just the authoring.** Four Auto Review rounds, seven reference
defects, four of them caused by the previous round's fix. A feature that forces deferred resolution
has a long tail of self-inflicted bugs; plan for it and prefer redesigns over guards.

**Pass-rate stability.** Two full batches, four levers apart, both exactly 1/10 with the same
dominant cluster — evidence that a band carried by a SEMANTIC distinction reproduces across
batches, unlike the numeric/ordering bands that swung 22%-vs-50% on vrp-tsplib.


## ray-optics-formula-conditionals (APPROVED Olympus 2026-09-14)

Shape O-Pipeline-hard: comparisons, `if`, `and`, `or`, `not` carried through all seven consumers of
one formula DAG. 7 files, 329 effective LOC, 96 tests. Batches 0/11, 1/10 (FP-flagged), 1/10 accepted.

**The reusable pick shape: "add a node family to an IR that a static analysis consumes".** Parser,
two evaluators, two code generators, a symbolic derivative and an interval estimator all read the
same DAG. The breadth is the LOC; the band came almost entirely from the ANALYSIS consumer's
exceptions (F-26 identical operands, F-27 `or` polarity: 24 of 40 kill events) and from the code
generator's per-node representation choice (F-10, 11 events). The parser and evaluators killed 2.

**Spend the description budget on consequences, not cases.** meta.md sat at the 500-word cap from
round 9 on. Every behaviour promise was either a stacked trap or FP exposure (L53), and the accepted
version promises LESS than the first: top-level-only switching sets, left-to-right `and`/`or`,
precision scoped to f32-representable values and to two stated pruning mechanisms.

**Cost profile.** 11 precheck rounds before batch 1, three full-price batches, five review rounds
between batches 2 and 3, 16 reference bugs. A route that only changed tests (Re-eval eligible) was
measured and blocked by the FP check, so plan for at least one description change after batch 1 on a
spec this dense.

## worldengine-orographic-precipitation (APPROVED Olympus 2026-09-16)

Shape O-Composite-add, Python (Mindwerks/worldengine): prevailing winds and a steady-state orographic
rainfall field joined into precipitation and carried through the world model, protobuf + HDF5,
equality, drawing, generation steps and CLI. 14 files, 251 effective LOC, 66 tests. Batches 1/10 (no
clean pass) and 2/10 accepted, Nova only.

**Reusable pick shape: a new physical layer in a simulation pipeline with a keyed world model.** The
simulation math is LOC and FP insurance (0 kills in 20 runs). The band came from data-model
integration: the container key (F-28, 23 of 46 kill events in batch 2), the accessor form (F-16) and a
lifecycle guard (F-29).

**Settle the solver-visible surface before batch 1.** About nine review rounds landed before the first
batch; batch 1 still exposed a description-induced regression (L57), so both batches were full price.

**Environment checklist that cost rounds here:** fixture fetches pinned by SHA, pip pins, generated
code regenerated at base's generator version and formatted with the repo's tool, a writable fixture
path for uid 1000.

## cwerg-bcopy-bzero-lowering (APPROVED Olympus 2026-09-16)

Shape O-Pipeline-hard, C++ + Python (robertmuth/Cwerg): two experimental IR opcodes lowered to byte
loops in both twins for a32/a64/x64 plus the C backend, under py/cc assembly and optimizer parity.
19 files, 690 human-effective LOC (≈375 without generated `opcode_gen.cc`), 23 golden cases, 122 base.
Batches 0/10, 0/11, re-eval 1/11, 1/10, 0/9, **3/10 accepted** (Nova 2/9, Vega 1/1).

**Reusable pick shape: a new instruction in a twin-implementation compiler.** The walls are in code
the agent did not write and are reached through one pipeline each: the optimizer's width pass (F-30),
the twins' constant folders (F-31), C++ CFG bookkeeping under the text renderer (F-32). One golden
program run through every pipeline the repo already runs is the whole test design.

**Budget the parity promise (L60).** It drew about nine pre-existing-divergence findings across 27
review rounds. Fix them in the reference; keep their tests out unless the feature reaches them.

**Environment checklist that cost rounds here:** cold build under the 600 s environment start (L62);
exclude base suites that need absent cross compilers or GCC 13 and say so in meta.md; `chmod -R
a+rwX /app` in the same layer as the build.

## tippecanoe-tile-join-size-recourses (APPROVED Olympus 2026-09-16)

Shape O-Composite-add in C++: `-M`/`--maximum-tile-bytes` and `--drop-smallest-as-needed` for
`tile-join`, plus tileset metadata that describes only what was written. 5 files, 294 effective LOC,
49 CLI tests, meta.md 362 words. One batch: 1/10, accepted.

**The reusable pick shape: "give a legacy tool a recourse, and keep its books honest".** The recourse
(rank, shed, compact) supplies the LOC and the reviewer surface. The band came from the accounting
beside it: recording a recourse that did not act (F-15) and a field the tool already merges from its
inputs whose aggregate the feature redefines (F-33). Look for both at pick time.

**Cost profile.** Two precheck rounds and four Auto Review revisions before the first batch, ten
reference bugs, three harness bugs, one full-price batch. Every round after the core slice changed
tests or the solution; meta.md changed in rounds 3, 4 and 8 only, all before the batch.

**Compiled-repo tax.** Budget a timestamp-proof rebuild in test.sh from day one (L63), a thread pin
if the repo's golden tests are parallel, and a check that any adapter over the repo's own test runner
maps every failure element.

## sfepy-adaptive-stepping-accounting (APPROVED Olympus 2026-09-16)

- **Outcome:** 2/15 after eleven batches (nine at 0%, one FP-flagged re-eval pass). 4 files,
  290 human-effective LOC, 117 tests, meta.md 444 words.
- **Decisive move 1, scope:** cut the restart lane (R60) once two batches in a row were walled by it
  and stating its base bugs had not helped.
- **Decisive move 2, agent mix:** at 0/12 with 116/117 near-misses on stated sentences, append Orion
  and Vega runs rather than drop the sentence (L65).
- **What carried the band:** F-34 aliased rollback snapshot (8/13), F-10 hostile-hook cell (7/13),
  F-35 index rewind (2/13). 87 of 117 tests killed nobody.
- **Procedure:** dedupe the cumulative pool before mining (L64); when a near-universal kill might be a
  surface issue, probe the saved near-miss patches before relaxing anything (Pattern 93).

## mwparserfromhell-site-aware-parsing (APPROVED Olympus 2026-09-18)

- **Outcome:** 2/19 on a tests-only re-eval of batch 1 (0/20). 14 files, 405 human-effective LOC,
  190 test cases, meta.md 292 words, 9 review rounds.
- **Decisive move:** drop the one reviewer-requested test on pre-existing behaviour that meta.md never
  stated (L66), keep the reference fix, re-eval instead of a fresh batch.
- **What carried the band:** F-36 segmented lookahead consumption (11/19), F-37 in-band EOF sentinel
  (7/19), the F-10 colon-on-reassignment cell (5/19, all Vega). 66 of 98 test functions killed nobody.
- **Procedure:** validate the Docker image as uid 1000 offline before the first precheck; replay saved
  patches to project any tests-only change (L68); expect twin-arm parity to be met by delegation (L67).

## kira-loop-crossfade (APPROVED Olympus 2026-09-18)

Rust audio engine, O-Composite-add across two playback paths, 11 files, 237 effective LOC, 55 tests,
meta.md 496 words. Accepted at 3/10 Nova; the fair suite reads 9/10 (see failure-patterns.md dossier).

- **Copy:** the decoder-thread test harness (Pattern 95): an event log with a condvar, a call-budget gate
  that logs when it blocks, a seek count taken inside `play()`, and seek budgets compared against a
  plain loop whose wraps land on the same output frames. It replaced two quality-review failures
  (event order, a 16384 buffer constant) with exact deterministic checks.
- **Do not copy:** the pick shape. Every rule fits in one 500-word description and each rule is local,
  so agents transcribe it (L1, L58). The only genuine kill was a composition cell (live region change
  x shortened wrap, F-10). Budget the trap design on such cells from day one.
- **Do not copy:** asserting a fixed backlog behind a gate (L70). It was the entire accepted band.

## planetiler-custommap-schema-composition (APPROVED Olympus 2026-09-18)

Java config-composition feature across loader, CLI and validator, 7 files, 316 effective LOC, 83 tests,
meta.md 485 words. Batch 1 0/8 measured nothing (compile-wipe); batch 2 accepted at 3/10 Nova.

- **Copy:** the provenance clause as a trap (F-38). "Removing an id that the earlier files did not
  contribute" plus one add-then-remove test carried 7 of 10 failures while every evaluator called it
  clear. Any layered-input format with a removal marker can carry it.
- **Copy:** the test.sh self-repair for an agent-poisoned local artifact repo (L73), and the non-root
  Docker checklist in DOCKER.md for Maven reactors.
- **Do not copy:** an unstated call shape for a new API (L72). It cost a full batch.
- **Do not copy:** a long rulebook of stated merge rules as the difficulty plan. It is 83 tests of FP
  insurance and zero kills; both kills were reviewer findings against the reference (L50).

## featurevisor-minimal-rebucketing (APPROVED Olympus 2026-09-19)

TypeScript builder feature across traffic, allocator, datafile build and CLI output, 4 files, 164
human-effective (207 platform), 34 new tests, meta.md 460 words. Batch 1 2/11; tests-only Auto Review
round; re-eval 2/11, approved.

- **Copy:** picking a capability defined by the repo's own model (range allocations, state file, slot
  ranges). It is the only kind that survives the sibling-library prior-art check.
- **Copy:** turning each reference bug into a test (L50). Both killers came from there.
- **Copy:** a shape-tolerant reader for any output the prose does not fix (`renderLines`).
- **Do not copy:** a band carried by one host-language edge. It was accepted, but the review filed the
  rate as overstated (L74); the independent helper cluster carried the case.
- **Do not copy:** editing an existing spec file in test.patch. Move superseded cases into your new
  spec file so new mode stays all-f2p (Pattern 97).


## ir-sim-scenario-events (APPROVED Olympus 2026-09-19)

- **Declarative config features are a live O-Composite-add lane in simulators.** A new YAML section
  checked in the step loop touches parsing, stepping, object lifecycle and reset paths, and cleared the
  scope gate with no prior art. Phrase the contract on the repo's own nouns (object groups, step modes,
  the three reset paths).
- **The band came from an integration default, not from the lifecycle design.** Three reset paths, an
  id rewind, list aliasing and short-circuit-safe edge tracking all read 0/11. The loader-injected
  group index read 10/11 (F-41). Look for what the loader does implicitly.
- **Pin derived-view timing only after someone decides it.** The first batch lost 11/11 to a sensor
  timing assertion the description never stated.
- **Use squares for exact boundaries.** Circle centroids are off by an ulp (L75).

## featurevisor-target-specialization (APPROVED Olympus 2026-09-19)

Second lane in a proven repo, accepted at 3/10 on its second batch. What to reuse:
1. **Pick a lane where the repo ships its own evaluator of the thing you transform.** "The output must
   evaluate exactly like the input" is a fair, one-sentence contract, and the evaluator is the test oracle.
2. **Put the new kernel in a new module and leave exported helpers alone.** Their spec files stay in base
   mode and become the batch's top killer (F-12 exported variant).
3. **Ship a seeded equivalence corpus** (fixed seeds, batched so every batch fails on base). It found every
   unsound fold the hand-written cells missed.
4. **Measure LOC by building, then pivot early.** The dinit lane before it looked like 315-340 eff on
   paper and was 105 built; this one was 231 on paper-free measurement and held.

## csbindgen-struct-layout-fidelity (APPROVED Olympus 2026-09-21)

Accepted at 1/10 on the fourth batch, after 25 review rounds. What to reuse:
1. **Use the source compiler as the test oracle.** Every layout assertion compares emitted output to
   Rust's own `size_of`/`offset_of!` on the same fixture tokens, so no expected value is hand-computed.
2. **Spot-check the target runtime outside the suite.** Compiling the generated C# on .NET 8 and
   comparing `sizeof` caught stale output and settled two disputed reviewer claims (Int128 alignment,
   `MarshalAs` on fixed buffers).
3. **Narrow the contract when review ratchets (L80).** Module scoping promised in one sentence cost 11
   rounds; cutting it ended the loop.
4. **Name every class member the tests use, or none (L81)**, and state two-sentence combinations in
   one clause when half the batch misses them (L77).

## libspatialindex-tpr-temporal-knn (APPROVED Olympus 2026-09-21)

Accepted at 5/12 on a re-eval of the third batch. What to reuse:
1. **Oracle every geometric assertion.** A `Mover` model with its own stop time, motion pieces and
   ambiguity margins (`EXPECT_GT(margin, 1e-6)`) produced expected sets for deep random trees, so no
   result was hand-computed and no fixture landed on a rounding edge.
2. **When the core is derivable maths, look for state the repo discards (F-47, L83).** The kernels alone
   read 7/10; one behavioural sentence about entry lifetime reached the storage and bound layers.
3. **Run each GoogleTest case in its own process** and merge the JUnit, so one crash fails one case.
4. **Do not assert the store's self-check (L82)**, and version a widened record per record (L84).

## siliconcompiler-flist-roundtrip (APPROVED Olympus 2026-09-23)

O-Composite-extend on a Python schema/serialisation subsystem. Accepted at 2/10.

The band came from one test. In a 57-test suite, exactly three tests killed anything outside a single
wire-format outlier: the graph-ownership test (7/10) and an empty-record pair (2/10 each). Budget
accordingly — breadth bought fairness and FP insurance, not difficulty.

Two process facts worth carrying:

- **Batch early.** This artifact passed eight static gate rounds before its first batch and then read
  0/11; most of that was repairable artifact defects that only a batch could reveal.
- **Price cuts by replay, not intuition.** With all batch-1 patches saved, each candidate repair had a
  measurable rate: unfair-only fixes 0/11, plus cutting one added wall 3/11, plus clarifying the
  ownership sentence 9/11. The third looked like the same class of fairness fix as the first two and
  would have pushed the problem over the too-easy ceiling.

## pyfakefs-block-inode-accounting (APPROVED Olympus 2026-09-23)

O-Composite-add on a Python fake-filesystem accounting model. Accepted at 5/10.

The band came from derivations the contract did not spell out, not from the stated rules. Of 117 tests,
9 killed anything: import rollback via a repo helper (3/10), the "unlimited" figure (2/10), the Windows
symlink size (1/10) and one run's recursive-removal leak. The walls the design was built around
(reserve-crossing renames, resize through an unlinked descriptor) killed 4/12 in batch 2 and 0/10 in
batch 3.

Process facts worth carrying:

- **Probe before you add.** Every test added after batch 2 was first run against all 14 saved agent
  patches. The FP fix (reset a bounded mount to unlimited) turned out 12/14 correct already, so it was
  a fair discriminator rather than a new wall.
- **Turn gate-found reference bugs into tests only when the probe backs them.** All three near-miss
  killers were reference bugs Solution Quality found first; many of the other 24 would have been walls.
- **Describe both sides of every split.** Most of batch 2's 0/12 was one carve-out sentence.

## pyocd-sequence-expression-kernel (APPROVED Olympus 2026-09-24)

Olympus, accepted 5/10 on batch 2 (batch 1 0/11). 4 files, 243 human-effective LOC, 150 test cases.

- **After the first batch, the saved patches are a free oracle for every test.** Replay each candidate
  before shipping it: ship if it costs nothing, state the requirement literally if it is undocumented,
  and cut it in tests, contract and reference if it is stated and still kills the near-misses (Pattern 104).
- **For a value-domain pick, state each boundary as its observable consequence** ("a variable set to a
  negative value reads back as its unsigned form"). Abstract phrasing killed 6-7/11; concrete phrasing 0/10.
- **Every argument a test passes that the rule doesn't govern gets an in-contract value.** One
  arbitrary `tms=3` became the only run-deciding trap nobody designed.
- **When coverage is finite, write the list, not the principle.** A general transfer rule kept
  generating reviewer findings; the closed list ended them.

## teavm-method-summaries (APPROVED Olympus 2026-09-24)

Olympus, accepted 4/10 on batch 1. 9 files, 298 human-effective LOC, 26 new tests, Java.

- **A whole-program analysis feeding existing per-method passes is a good Olympus lane.** The scope
  was obvious (every run touched the same nine files); the difficulty was one fixed-point decision
  (F-53) plus two integration cells (F-54, F-55).
- **Freeze meta.md before the first batch, then take every gate round on the reference and tests.**
  Four gate rounds changed meta.md twice; none of that cost a batch because no batch had run yet.
- **Wire and test every pipeline the driver has.** Loop the end-to-end test over all optimization
  levels with a stub backend (Pattern 105).
- **40% is accepted, with no margin.** Batch variance alone could have read 5/10.
