# PATTERNS-ADVANCED — Specialized Evidence-Based Patterns (17–44)

Continuation of `PLAYBOOK.md`. Foundational patterns 1–10 (anatomy + process), 11–13 (shape taxonomy → see `SHAPES.md`), 14–16 (verdicts) live in `PLAYBOOK.md`. This file holds specialized patterns extracted from harder approveds (post-April 2026) — trap-stacking ceiling, integration-surface diagnostics, namespace philosophy, post-base activity audits.

> **Read first:** `PLAYBOOK.md` (foundational patterns + approveds tables + 10-thing TL;DR). This file references those by number.

**Pattern index:**
- Pattern 17 — Trap-Stacking Ceiling: Shape > Trap Count
- Pattern 18 — Test File Compile-Time Decoupling
- Pattern 19 — JUnit XML for Multi-Package Test Surfaces
- Pattern 20 — Spec Qualifiers That Eliminate Fairness Contests
- Pattern 21 — Kong CLI Flag Validation Anti-Pattern
- Pattern 22 — Namespace Expansion + Maintainer Philosophy Check (CRITICAL — #1 reject cause)
- Pattern 23 — Public API Split as Repeatable Integration Trap
- Pattern 24 — Spec-Compression Seesaw as Ceiling Diagnostic
- Pattern 25 — Opt-In Flag Pattern for Safe Semantic Extension
- Pattern 26 — Unified Error Substring Across Multiple Collision Dimensions
- Pattern 27 — Build-Tag Isolation for Test Files Referencing Solution-Only API
- Pattern 28 — `(including null)` Parenthetical to Pre-Empt Null-as-Missing Trap
- Pattern 29 — Parser-Flag-Elevation Regression Trap
- Pattern 30 — Test Architecture: 3 Valid Patterns + Reviewer-Rotation Strategy
- Pattern 31 — Auto-Review Verdict ≠ Final Approval (Contestation Hierarchy)
- Pattern 32 — Post-Base Maintainer Activity (catches "feature shipped between design and submit")
- Pattern 33 — Triviality Filter for Additive-Function Picks
- Pattern 34 — Concrete Counter-Example Hint (Architectural Trap Disambiguation)
- Pattern 35 — Implicit-Contract Audit (Pre-Submit Fairness-Round Pre-Empt)
- Pattern 36 — Failure-QA Citation Triangulation Discipline (Diamond-only)
- Pattern 37 — Pre-existing Loose Helper as Stricter-Predicate Trap (★★★★)
- Pattern 38 — Helper-Defined-But-Not-Wired Trap (★★★)
- Pattern 39 — Strict test.sh Argument Validation (V2-carryover defense)
- Pattern 40 — Representation-Type Pin as Compile-Unfairness (ANTI-PATTERN)
- Pattern 41 — Cost-Test-or-Decorative: difficulty erodes without a perf assertion
- Pattern 42 — Choke-Point Triviality: push difficulty to the consumed-and-discarded value
- Pattern 43 — Distribution/Determinism Hash Trap
- Pattern 44 — Diamond failure-QA validator grouping-binding
- Pattern 45 — Diamond QA two-gate: value-anchored vs behavior-anchored citation
- Pattern 46 — Concept-similarity collision on a same-repo introspection-API family
- Pattern 47 — External-test-package exact-type import is an API-shape compile-collapse
- Pattern 48 — Compile-Time-Transform Shallow Well: engineer + MEASURE difficulty per lever (★★★★)
- Pattern 49 — Failure-QA root cause must be artifact-grounded; cascade-split; re-verify UI buckets

---

## Pattern 17 — Trap-Stacking Ceiling: Shape > Trap Count

**Confirmed empirically TWICE — dasel-collection-funcs (R0–R17d, 18 iterations) and expr-licm-predicates (R0–R29, 30 iterations):**

### dasel-collection-funcs

| Round | Shape | Trap stack | Nova pass rate |
|---|---|---|---|
| R10 | Mars C (pure-function pick/omit/chunk/windows) | 9 categories incl. algebraic invariants | **100%** |
| R12 | Mars C + same-object collision + structured error | 10 categories | **100%** |
| R14 | Same + reflection-based test decoupling fixed | 10 categories | **100%** |
| R16 | Same + polymorphic dispatch + fillValue + step | 5 stacked Tier 1/2 traps | **100%** |
| R17 | **Olympus O-Composite-add (mergeDeep + diffDeep + CLI flag, multi-package)** | Same 6 trap categories | **41.7%** |

### expr-licm-predicates

| Round | Shape | Spec/trap stack | Nova pass rate |
|---|---|---|---|
| R11–R13 | Mars C (pure-function LICM optimizer pass) | 6 categories incl. impure-set, short-circuit, dedup, scope | **62.5–87.5%** |
| R17 | Mars C + impure-5 enum dropped | Same 6 categories | **0%** (unfair miss on impure classification) |
| R18–R20 | Mars C + impure-5 re-added + concrete example hint | 8 categories incl. let-scope, fold-after, optimize-gate | **62.5–87.5%** |
| R21 | Mars C + 7 strong compound traps | 9 categories | empirical not stable in band |
| R23 | Mars C + let-scope correctness fix (round 22 reviewer flagged unfair) | 10 categories | empirical varied |
| R24–R25 | Mars C + nuclear test pack (let.Value descent, pre-order direction) | 11 categories | back to high range |
| R26 | Mars C + spec compression (391→278 words) | Same | **0%** (and/or trap dropped) |
| R27 | Mars C + parenthetical and/or hint | Same | **~100%** (parenthetical too explicit) |
| R28-R29 | **D-new hybrid (`LICMStrategy` enum + `WithLICMStrategy` Option + cross-body algorithm + multi-package public API)** | Same trap categories | **33.3%** |

**Both confirmations: trap-effectiveness depends on integration surface, not trap count.**

**Pattern 17 oscillation signature** (expr-licm-predicates rounds 25→26→27 in a row): `100% → 0% → 100%` across consecutive spec moves at same shape. No middle ground exists. Spec edits flip WHICH agents read which line; do not change algorithmic difficulty. Triple binary flip = strongest reshape signal.

### Diagnostic signals — when you've hit the ceiling

- 3+ successive rounds of trap addition produce identical pass rates → shape is the ceiling
- Agent trajectories converge on equivalent algorithmic solutions → no semantic depth remains
- Same-object/collision/structured-error/polymorphic traps all fire mechanically → agents read spec, implement to the letter, pass cleanly

### What "integration surface" means

A problem has integration surface if it requires:

1. **Recursive algorithmic body** (not just iteration over flat collection). Recursion creates state-management points where agents diverge.
2. **Multi-package wiring** (CLI flag → runOpts → Options → handler). Each hop is a potential miss.
3. **Conditional struct fields with discriminator clauses** ("populated when X, empty otherwise"). Agents collapse to uniform population.
4. **Multiple enum values with per-value behavior** (4+ strategies). Agents implement default cleanly, miss one of the others.

Pure-function additive features lack ALL FOUR. They cap at B-shape baseline regardless of trap density.

### Cost-benefit

- **R0–R16 (16 rounds in B-shape territory):** 100% pass, problem unshippable
- **R17–R17d (4 rounds in Olympus reframe):** 41.7% pass, shipped

If you find yourself adding traps in round 4+ of the same shape, **stop and reframe**. The next 3–4 rounds in a new shape will outperform 10 more rounds in the old one.

### How to reframe

Replace pure-function scope with feature requiring at least 2 of:

- **Recursive operation** (deep-merge, structural-diff, fold, recursive-flatten with branching)
- **Stateful pipeline** (multi-stage transformation with intermediate state)
- **Multi-package CLI wiring** (new global flag propagating through Options struct)
- **Conditional struct field semantics** (error type with populated/empty discriminator)

Same trap categories you already designed will fire against the new shape because the new shape has surface for them.

---

## Pattern 18 — Test File Compile-Time Decoupling (Mandatory for Solution-Type Tests)

When tests reference solution-only types (e.g., new error types) directly, the test package fails to build on base (test.patch applied without solution.patch). Platform reports "Baseline tests failed" because zero tests can run.

**Fix: reflection-based type lookup.** Replace direct type references with runtime string comparison.

```go
// Compile-couples to solution (BREAKS BASELINE)
var cfErr *execution.CollectionFuncError
if errors.As(err, &cfErr) { ... }

// Compiles on base, fails behaviorally
for cur := err; cur != nil; cur = errors.Unwrap(cur) {
    rt := reflect.TypeOf(cur)
    if rt != nil && rt.String() == "*execution.CollectionFuncError" {
        v := reflect.ValueOf(cur).Elem()
        funcName := v.FieldByName("Func").String()
    }
}
```

**Same pattern for solution-only Options fields:**

```go
// BREAKS BASELINE
opts := execution.NewOptions(execution.WithDefaultConflictStrategy("keep"))

// Compiles on base
func cfSetDefaultStrategy(opts *execution.Options, strategy string) {
    f := reflect.ValueOf(opts).Elem().FieldByName("DefaultConflictStrategy")
    if f.IsValid() {
        f.SetString(strategy)
    }
}
```

**Same pattern for CLI flag tests:** detect flag presence via reflection on `cli.QueryCmd{}`, skip test if absent. Behavioral tests that invoke flag via runDasel fail behaviorally on base; type/field-direct tests skip cleanly.

This pattern saved dasel-collection-funcs R14 from baseline-fail rejection.

---

## Pattern 19 — JUnit XML for Multi-Package Test Surfaces

For multi-package test surfaces (e.g., execution + cli), use ONE `go test` invocation across all packages through ONE `go-junit-report` pipe:

```bash
PKG="./execution/ ./internal/cli/"
go test -v -count=1 $PKG -run "$run_pattern" -timeout "$timeout" 2>&1 | go-junit-report -set-exit-code > "$OUTPUT_PATH"
```

**DO NOT** run `go test` separately per package and merge XMLs. Custom `merge_xml` produces malformed JUnit because go-junit-report emits parent testcase tags that don't close properly when subtests fail across separate invocations. Platform validator rejects malformed XML with "mismatched tag" error.

Approved dasel-quoted-key-paths uses single-invocation pattern verbatim. Mirror it.

---

## Pattern 20 — Spec Qualifiers That Eliminate Fairness Contests

When tests use reflection on type strings or struct fields, the spec must qualify the implementation surface explicitly. Three confirmed-load-bearing qualifiers from dasel-collection-funcs:

| Qualifier | Why needed | Without it |
|---|---|---|
| **"in the `<package>` package"** | Tests check `reflect.TypeOf(cur).String() == "*pkg.Type"` | Agent follows existing convention (e.g., places error in `model/`); reflection check fails |
| **"implements `error` via pointer receiver, so the error chain contains `*MyError`"** | Tests assume pointer-typed instance in chain | 3/5 agents use value receiver; `errors.As` fails |
| **"or empty otherwise" / "leave X unset when Y"** | Conditional struct field discriminator | Agents populate uniformly, lose distinction |

**Pattern**: Any test assertion that depends on package, receiver style, or empty-vs-populated state needs an explicit spec qualifier. Without it, fairness contests are valid.

---

## Pattern 21 — Kong CLI Flag Validation Anti-Pattern

When spec mandates a specific error string for invalid CLI flag values, validate INSIDE the run path that returns errors, NOT via Kong's `enum:` tag.

```go
// BREAKS error-string contract — Kong os.Exits with its own format
type QueryCmd struct {
    DefaultConflict string `flag:"" name:"default-conflict" enum:"keep,overwrite,concat,error"`
}

// Returns Go error containing required substring
type QueryCmd struct {
    DefaultConflict string `flag:"" name:"default-conflict" help:"..."`
}
// In run():
if o.DefaultConflict != "" {
    switch o.DefaultConflict {
    case "keep", "overwrite", "concat", "error":
        // ok
    default:
        return nil, fmt.Errorf("unknown conflict strategy %q (valid: keep, overwrite, concat, error)", o.DefaultConflict)
    }
}
```

Kong's `enum:` validates during `kong.Parse()` and calls `os.Exit(1)` on violation with format "must be one of ...". Tests that capture the spec-required substring (`unknown conflict strategy`) will fail with "No test result found" because the test binary itself exits via Kong's validator.

Confirmed on dasel-collection-funcs Run 12: agent used `enum:` tag, lost the contract.

---

## Pattern 22 — Namespace Expansion + Maintainer Philosophy Check (CRITICAL — #1 reject cause)

**dasel-collection-funcs (R17d) was REJECTED post-eval despite 41.7% pass rate** because:

1. `FuncMerge` already exists in repo. `mergeDeep` is namespace-expansion of an already-implemented capability → satisfies platform's Immediate Rejection Rule.
2. GitHub issue #169 has explicit maintainer comment against merge-namespace expansion: "I'd prefer not to add a shortcut as I don't want to pollute the namespace with uncommon/convoluted shortcuts."

Author Phase 2 PR check found `mergeDeep` literal name absent from master. **Did not search broader namespace** (`merge`, `diff`, `pluck`) and **did not check issues** (`gh issue list --search "merge"`).

### Mandatory pre-author checks (UPDATED 2026-04-30 — SIX checks now; every scope change AND every submit-pre-check requires re-run)

```bash
# 1. Existing function check (literal name)
gh pr list   -R OWNER/REPO --state all --search "<exact-func-name>"
gh issue list -R OWNER/REPO --state all --search "<exact-func-name>"

# 2. Namespace expansion check (broad keywords)
gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"

# 3. Maintainer philosophy check
gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("prefer not to") or contains("don'\''t want") or contains("by design") or contains("namespace") or contains("pollute") or contains("won'\''t add"))'

# 4. Closed-with-implemented scan (NEW — added after dasel-slice-operator REJECT)
gh issue list -R OWNER/REPO --state closed --search "<feature-keyword>" --json number,title,comments \
  | jq '.[] | select(.comments[]?.body | contains("implemented") or contains("supported in V") or contains("This is in v"))'

# 5. Base→main commit overlap (NEW — catches feature shipped post-base)
cd /tmp/<repo>-main && git log --oneline <BASE_COMMIT>..HEAD -- <relevant-source-files>
git log --oneline <BASE_COMMIT>..HEAD --diff-filter=A -- <relevant-package>/

# 6. Existing-capability functional check (build current main; CLI-test the feature)
cd /tmp/<repo>-main && go build -o <repo>.exe ./cmd/<repo>
echo '<test input>' | ./<repo>.exe <feature invocation>
# If 80%+ of feature scope already works in main HEAD, REJECT
```

### Specific signals that trigger reject

**Namespace signals (checks 1-3):**
- New function name shares prefix or suffix with existing function (`merge` → `mergeDeep`)
- Feature description starts with "extend" / "deep" / "smart" / "advanced" version of existing
- Maintainer issue comment uses "philosophical" / "preference" / "namespace" / "pollute"
- Existing function provides 80%+ of the new function's value

**Post-base signals (checks 4-6 — NEW):**
- Issue closed by maintainer with "This is implemented in V3" / "supported in V3" + docs link
- Maintainer-published docs (typically `<repo>docs.<maintainer>.me`) document **current** behavior that **contradicts** our spec
- Commit between base and current main HEAD adds the same function/feature/fix we propose
- Active rework: maintainer comment "I am in the middle of reworking the X subsystem"

### Scope-change rule (CRITICAL — every reframe AND every submit requires fresh search)

If problem scope changes mid-author (e.g., R16 pick/omit/chunk/windows → R17 mergeDeep/diffDeep), **re-run all six checks above with the NEW keywords**. The original Phase 2 search no longer applies.

**Track record of skipping** (cost of misses):

1. **dasel-collection-funcs R17d** — Phase 2 missed namespace + philosophy → REJECT after 18 rounds + 12-run eval. ~$200 wasted.
2. **dasel-slice-operator** (2026-04-30) — Phase 2 ran at base time (Mar 10), missed issue #312 closed by maintainer Mar 30 with "implemented in v3" + docs spec contradicting ours. REJECT at submit-pre-check. ~half-day of authoring lost.
3. **dasel-entries-fromentries / dasel-yaml-quote-style / dasel-regex-filter** (caught at audit-rewrite, not shipped) — v1 GREEN; commit search base→main found maintainer shipped equivalents post-base. Three near-misses.
4. **dasel-multi-file** (2026-05-14, Diamond tier) — Phase 2 never ran at design or submit-pre-check. 14 authoring rounds + Castor 7× + AI Reviewer PASS 0.92 + Failure QA 12/12 all green. Discovered at olympus-review Stage 0: [#357 "Support multiple files"](https://github.com/TomWright/dasel/issues/357) CLOSED by TomWright 2025-12-10 (4 months pre-base) with "with dasel V3 you can do this with one of: env vars, readFile function, file→variable" — three V3 alternatives shipped, multi-file-as-primitive declined. Original [#24 "Multiple file flags"](https://github.com/TomWright/dasel/issues/24) CLOSED 2020 "mostly resolved by multi-selectors" — same class twice rejected. Submission discontinued pre-submit. Sunk cost ~14 iterations + Castor 50tk × 7 + QA cycle. **Confirms: Auto Review + Diamond QA do NOT validate maintainer philosophy.** Auto Review checks artifact mechanics + AI calibration; QA checks failure trajectories; neither checks scope vs maintainer position.

**At every submit-pre-check, re-run checks 4-5-6.** Maintainer ships features between design and submission. **Auto Review / QA passing does not satisfy Phase 2.**

### Reference: dasel post-base shipping audit (snapshot 2026-04-30, MUST refresh per pick)

Between dasel base `0dd6132e` (2026-03-10) and current main `00c1f70` (2026-04-30) — 50 days — maintainer @TomWright shipped:

- 23 new selector functions: `keys`, `values`, `entries`, `fromEntries`, `first`, `last`, `unique`, `flatten`, `avg`, `round`, `ceil`, `floor`, `abs`, `indexOf`, `startsWith`, `endsWith`, `trim`, `trimPrefix`, `trimSuffix`, `toLower`, `toUpper`, `split`, `stringify`, `toBool`
- 4 new expressions: ternary `? :`, `count`, `all`, `any`
- yaml quote-style fix (#452), deep-merge default, `--compact` flag, shell completion, XML name validation, base-N number parsing fix, regex filter (#183 closed)

**Pace: ~3 functions/week.** Any additive-function pick has 1-2 week half-life before maintainer ships it.

**STILL ABSENT in main HEAD as of snapshot date** (verify per pick before authoring): `pick`, `omit`, `chunk`, `windows`, `zip`, `partition`, `pluck`. **Bug-fix gaps still open**: M10 put-path-creation (`a.b.c = 1` on `{}` errors), NM4 compound-assign (`+=`/`-=`/`++`/`--` tokens defined in lexer:36-40 but unused).

**Bug fixes age slower than additive features.** When triviality risk is high (per Pattern 33), prefer bug fixes.

---

## Pattern 23 — Public API Split as Repeatable Integration Trap

**Confirmed at expr-licm-predicates v29 (3/12 = 25% catch rate, dominant single failure mode).**

When reshaping a ceiling-bound problem to add integration surface (per Pattern 17), deliberately split the new public API across two layers:

| Layer | Contains |
|---|---|
| **Public root package** (`expr.go`, top-level `<repo>/<repo>.go`) | Exported enum types, exported constants, Option functions |
| **Internal config package** (`conf/config.go`, `internal/...`) | Struct fields, validation, plumbing |

Hidden tests import from the public root: `expr.LICMStrategy`, `expr.LICMPerBody`. Agents who put the enum + constants only in the internal `conf` package fail at compile time before any behavioral test runs. Reported as `FAIL_INTEGRATION_ERROR` with build error stating undefined `expr.X` symbol.

### Why this trap fires repeatably

- Agents follow the local convention they encounter first. If `Config` struct lives in `conf/`, they put types there.
- Agents under-export to "minimize surface" — instinct from production code reviews.
- Public root often has only Option *functions*, not types. Agents miss that types belong there too.

### How to design the trap

1. Define the enum in the public root file (`expr.go`).
2. Add a mirroring `int` field on the internal `Config` struct.
3. Constants are public package-level (`LICMPerBody`, not `conf.LICMPerBody`).
4. Tests use the public root names: `expr.LICMStrategy(0)`, `expr.WithLICMStrategy(expr.LICMCrossBody)`.

### Catch rate evidence

- 3/12 = 25% of expr-licm-predicates v29 failures were exactly this miss
- Each fail compiled OK locally for the agent (test file under build tag `licm` has different import requirements than agent's own test file)
- Agents discovered the miss only when verifier ran `go test -tags=licm` against hidden tests

### When to use

- Reshape from Mars C / B-shape to D-new with new public type/enum
- Existing `Config` struct already exists in internal package — natural temptation for agent to add field there
- Tests can plausibly import from either package — if you can rationalize using internal package only, agents will too

---

## Pattern 24 — Spec-Compression Seesaw as Ceiling Diagnostic

**Confirmed at expr-licm-predicates rounds 25→26→27 (binary flip pattern).**

When at trap-stacking ceiling, spec edits produce **binary outcomes** rather than gradual movement:

| Round | Spec move | Empirical |
|---|---|---|
| R25 | Full spec, all hints (391 words) | ~100% pass |
| R26 | Aggressive compression, drop and/or parity (278 words) | **0% pass** (10/10 missed and/or trap) |
| R27 | Re-add and/or as parenthetical operator list (282 words) | **~100% pass** (parenthetical too explicit) |

**Three consecutive rounds, two binary flips, no middle ground.** This pattern is the strongest empirical signal that the problem is at Pattern 17 ceiling.

### Why binary outcomes happen at ceiling

At ceiling, agents pre-converge on one canonical algorithm shape (read PLAYBOOK Pattern 11–12 + their training data). Spec compression / expansion just changes whether agents recall the and/or pair, the iter-pointer set, the impure list — not the algorithm structure itself. Either ALL pass that decoration (full spec) or ALL fail it (compressed spec).

There is no "intermediate hint level" because the underlying algorithm is mechanical. Adding/removing a single sentence flips a binary recall.

### Diagnostic signature

- Round N: empirical 60–100%
- Round N+1 (drop 1–2 hints): empirical 0–10%
- Round N+2 (re-add as parenthetical or codebase pointer): empirical 70–100%
- Total rounds spent: 3+
- Total movement on actual difficulty: zero

When this signature appears, **STOP spec editing**. Reshape per Pattern 17. Use the time saved to design integration-surface dimensions instead.

### Distinguishing seesaw from genuine difficulty calibration

If pass rates are 35% → 25% → 40% → 30% across 4 rounds, that's calibration, keep going. If pass rates are 80% → 0% → 90% → 0%, that's seesaw, reshape.

### Cost evidence

- expr-licm-predicates R0–R27 in Mars C: 27 rounds × ~3 min spec edits × 12-run eval batches = ~80 min author time + many wasted eval runs at 0% or 100%
- R28 reshape: 1 round, ~25 min, lands at 33.3%

If you see 3 binary flips, you've already spent more than the reshape would cost. Stop.

---

## Pattern 25 — Opt-In Flag Pattern for Safe Semantic Extension of Fundamental Operators

**Confirmed empirically on dasel-assign-path-creation (Mars Solid, 5/9 = 55.6% PASS, approved May 2026).**

When extending the semantics of a fundamental operator (assignment `=`, equality `==`, sort comparator, type coercion), add a default-OFF execution option that gates the new behavior. Existing tests stay bit-identical to base; new behavior only triggers when the option is set.

### The pattern

```
Options struct {
    ...existing fields...
    NewBehaviorEnabled bool   // default false
}

func WithNewBehavior() ExecuteOptionFn { return func(o *Options) { o.NewBehaviorEnabled = true } }

// In handler:
if options.NewBehaviorEnabled {
    return newPathCode(ctx, expr, value, options)
}
return existingCode(ctx, expr, value, options)
```

### Why it works

1. **Zero baseline regression risk.** All N+ existing tests remain identical because flag-OFF path is unchanged. Reviewer trust scales with baseline-preserved test count (dasel-assign-path-creation: 623 baseline tests, 0 regressions).
2. **Reviewer approval signals positive.** "Preserves existing scalar/null type-collision errors" was called out in approval message as a positive, not just a non-issue.
3. **Test surface is parallelizable.** `flag_off_*` bucket = regression guard; `flag_on_*` bucket = new behavior coverage. Easy to write tests that prove the option is the gate.
4. **Spec is naturally bipartite.** Description has clean structure: paragraph 1 = what flag does, paragraph 2 = what flag does NOT do (and what stays the same). Easier to keep under word cap.

### Difficulty calibration

The opt-in flag pattern by itself is NOT enough for Mars Solid difficulty — agents implement the flag check trivially. Difficulty comes from the SEMANTIC depth of the new behavior:
- dasel-assign-path-creation: walker recursion through arbitrary path depth + filler-type choice based on next segment + null-as-scalar handling + container-kind-mismatch unification
- These four trap dimensions together produced 4 distinct failure clusters across 9 runs

Without those, opt-in flag is a Mars C palate cleanser at best.

### When to use

- Operator semantic extension that would break existing tests if applied unconditionally
- Behavior that some users want but others don't (e.g. strict vs lenient modes)
- New error path that didn't exist before (e.g. null-traversal collision)

### When NOT to use

- Pure-additive features (new function, new format) — opt-in flag is unnecessary; just register the new symbol
- Bug fixes where existing tests are wrong — fix unconditionally and update existing tests
- Behavior that EVERY user wants (no semantic disagreement) — gate adds noise without value

### Approved-precedent file paths

- `problems/dasel/dasel-assign-path-creation/` — `WithAssignCreatePaths()` (Mars Solid, 5/9 = 55.6%)
- `problems/dasel/dasel-csv-options/` — Ext-flag round-trip pattern (different shape but similar principle: caller opts into new behavior via reader/writer options)

---

## Pattern 26 — Unified Error Substring Across Multiple Collision Dimensions

**Confirmed empirically on dasel-assign-path-creation R0 → R1 (auto-reviewer flagged spec/test misalignment).**

When a feature defines collision/error behavior across multiple dimensions (scalar collision + container kind-mismatch + null traversal), use ONE error substring that covers every case. Multiple separate error messages = agents return wrong substring on edge cases = test fails on substring match.

### Anti-pattern (R0 spec)

```
Type collision through a scalar errors with `cannot assign through scalar`.
```

Only the scalar dimension is named. Tests assert `cannot assign through scalar` for THREE collision dimensions:
1. Walking through scalar value (string, number, bool, null)
2. Property-name segment targeting a slice (kind mismatch)
3. Integer-index segment targeting a map (kind mismatch)

Auto-reviewer flagged this as test/spec misalignment. Either spec must enumerate every case OR tests must use distinct substrings per dimension.

### Pattern (R1 spec)

```
Type collision errors regardless of the option, with a message containing `cannot assign through scalar`.
This applies to any scalar value (including null) and to kind mismatches such as a property-name
segment targeting a slice or an integer-index segment targeting a map.
```

One substring, three explicitly enumerated cases. Solution emits same wording for all three. Agents pick right substring on first attempt.

### Why it works

1. **Substring assertions are strong but unforgiving.** `strings.Contains(err.Error(), "cannot assign through scalar")` is a clean test, but if solution says `kind mismatch: expected map` for one case and `cannot assign through scalar` for another, the substring test fails on case mismatch.
2. **Single substring scales reviewer's mental model.** Reviewer reads spec once and predicts every test outcome. Multiple substrings = reviewer must read every test to know which message applies where.
3. **Solution simplifies.** One unified error helper instead of N error sites.

### Spec-writing rule

If your tests assert ONE substring across N collision dimensions, your spec MUST enumerate all N dimensions in one clause and tie them to that substring. Bad: "scalar collision errors with X". Good: "Collision errors with X. This applies to scalars (A, B, C, D) and to kind mismatches (E, F)."

### Approved-precedent file paths

- `problems/dasel/dasel-assign-path-creation/meta.md` — single-substring + enumerated-cases sentence

---

## Pattern 27 — Build-Tag Isolation for Test Files Referencing Solution-Only API

**Confirmed empirically on dasel-frontmatter-format (approved April 2026) and dasel-assign-path-creation (approved May 2026).**

When the test file references public API that exists ONLY in solution.patch, applying test.patch alone to base fails compile. Solution: gate the test file with a build tag. test.sh new-mode runs with `-tags=<tag>`; base-mode runs without the tag (test file excluded cleanly).

### The pattern

Test file header:
```go
//go:build dasel_assign_path_creation

package execution_test

import (
    ...
    "github.com/tomwright/dasel/v3/execution"
    ...
)
```

test.sh:
```bash
if [ "$MODE" = "new" ]; then
  go test -tags=dasel_assign_path_creation $PKG -run "^TestAssignPath" ...
elif [ "$MODE" = "base" ]; then
  # No tag — test file excluded; base-mode tests find existing tests only.
  go test $PKG -run "$EXISTING_REGEX" ...
fi
```

### Why it matters (LESSONS #2 trap)

Auto-reviewer pre-flight applies test.patch alone to base and runs `./test.sh base`. Without the build tag:
- Test file compiles into base mode
- References `execution.WithAssignCreatePaths` which doesn't exist on base
- Compile error: `undefined: execution.WithAssignCreatePaths`
- `go test` exits non-zero with `[build failed]` testcase
- Auto-reviewer reports baseline broken

With the build tag:
- Test file is gated by `//go:build dasel_assign_path_creation`
- Base mode runs without the tag — file is excluded from compilation cleanly
- Existing tests compile and pass
- Auto-reviewer reports baseline green

### Distinction from "build tags on solution files" anti-pattern

Build tags on SOLUTION files are a known anti-pattern (LESSONS #11; reviewer flag): solution code wouldn't compile under normal `go build` because the tag is unique. THIS pattern is different — only the TEST file is tagged, and the test runner activates the tag explicitly via `-tags=<tag>` in new mode.

### Naming convention

Tag name = `<repo>_<feature_slug>` with underscores: `dasel_assign_path_creation`, `frontmatter`, etc. Matches existing dasel approveds.

### Approved-precedent file paths

- `problems/dasel/dasel-frontmatter-format/test.patch` — `//go:build frontmatter`
- `problems/dasel/dasel-assign-path-creation/test.patch` — `//go:build dasel_assign_path_creation`

---

## Pattern 28 — `(including null)` Parenthetical to Pre-Empt Null-as-Missing Trap

**Confirmed empirically on dasel-assign-path-creation Run #4 (Nova→Orion FAIL_MISSED_REQUIREMENT).**

When spec uses generic "scalar" or "primitive" terminology, agents default-treat `null` as "missing" rather than "present scalar value". The auto-traversal trap: agent's path-walker auto-creates through null intermediate values when the spec said scalar collisions should error.

### Pattern (cheap pre-empt)

Spec says: `This applies to any scalar value (including null) ...`

The `(including null)` parenthetical is a cheap, fair pre-empt. Doesn't add a separate sentence. Doesn't add a hint. Doesn't break Mars 240-word cap. Pre-empts the trap reliably.

### Why agents miss null

1. JavaScript / Python / similar languages treat null/None as "absent" in many contexts (default-arg fallback, `||`, `or`, optional chaining)
2. JSON tools (jq, dasel itself in some contexts) treat null as path terminator rather than scalar
3. Agents trained on these patterns default to "null = missing" disposition

### Pattern (anti-pattern — DON'T do this)

Spec says: `Scalar collisions error.`

Agents reasonably interpret this as "string/number/bool collision errors; null is something else". Run #4 traversed null without error. Failed test.

### When to use

- Spec asserts a rule about scalars
- One of the values inhabiting that rule is null
- Tests rely on null being treated as scalar

### When NOT to use

- Spec is about typed values where null is genuinely separate (e.g. "non-nil pointer required")
- Null behavior is special-cased away from scalars (rare, document separately)

### Approved-precedent file paths

- `problems/dasel/dasel-assign-path-creation/meta.md` — `This applies to any scalar value (including null) ...`

---

## Pattern 29 — Parser-Flag-Elevation Regression Trap (Tier-1 anti-agent for interpreter/parser repos)

**Source**: yaegi-repl-doc 6/14 = 43% hit rate. Confirmed Tier-1 anti-agent.

**Pattern**: feature requires lifting a parser flag from a narrow path (REPL/incremental mode) to all evaluation paths. Existing source has guarded `mode |= parser.SomeFlag` inside `if inc { ... }`. Agents reflexively also tweak surrounding wrap shape (e.g. flip `"package main;" + src` to `"package main\n" + src`) so the new feature works end-to-end.

The wrap-shape tweak shifts existing diagnostic positions by ±1 line. Every existing position-asserting test fails:
- `want 1:29` vs `got 2:16`
- `expected 'IDENT', found '{'` (incremental tokenizer interaction)

**Why it's Tier-1**:
- Spec implies the flag-elevation requirement (silently). Agents solve the headline problem and reflexively also "clean up" the wrap.
- Reference solution achieves the same end-to-end behavior WITHOUT touching the wrap. Comment-attachment / position-tracking still works through full-file parse path because go/parser tolerates the existing wrap shape.
- Pre-empt sentence in spec defuses trap. Silence preserves it.

**Trap engineering for future problems**:
- Identify any narrow-mode parser flag in the target repo (`if inc {}`, `if repl {}`, `case CommentMode:`).
- Author a feature whose spec language requires the flag in all paths.
- Do NOT pre-empt the wrap-shape reflex in the description.
- Include 5+ position-asserting baseline tests in BASE_RUN regex (TestOpVarConst, TestEvalTypeSpec, TestEvalComparison, TestEvalFunc, TestEvalREPL on yaegi).

**Cost**: 6 of 14 yaegi-repl-doc runs failed REGRESSION. Single regression cluster — same root cause across all 6.

**Generalization**: applies to ANY interpreter/parser repo with a "narrow vs wide parse mode" split. Lua, Python emulators, JS interpreters, query parsers — all have analogous shapes.

---

## Pattern 30 — Test Architecture: 3 Valid Patterns + Reviewer-Rotation Strategy

**Source**: yaegi 5 submissions; 3 distinct test placement patterns; ALL approved across rotations.

**The three patterns** (yaegi examples):
1. **Subpackage** — `interp/<feature>/` with `package <feature>`. yaegi-completion + yaegi-callstack-postmortem use this.
2. **Plain `_test.go` in package_test** — `interp/<feature>_test.go` with `package interp_test`. Standard yaegi convention but breaks test-patch-only base mode (LESSONS.md mistake #2).
3. **Build tag + package_test** — `interp/<feature>_test.go` with `//go:build <tag>` + `package interp_test`. yaegi-repl-doc shipped this.

**Reviewer rotation observed**:
- Auto-reviewer A rejects subpackage ("hides tests from `go test ./interp/`")
- Auto-reviewer B rejects build tag ("no other file uses custom tag")
- Both reviewers want `package interp_test` directly in `interp/` — but this breaks LESSONS.md #2

**Strategy**:
1. Ship whichever pattern the FIRST reviewer demands.
2. If FIRST demand contradicts LESSONS.md #2 risk (test-patch-only base build fails), pick the architecture that matches the closest approved-precedent folder.
3. If contested by a SECOND reviewer, cite approved-precedent in `feedback.md` (e.g. `Olympus-Approved/Feature-Requests/yaegi/yaegi-callstack-postmortem/`).
4. Final human reviewer respects precedent. Don't pivot architecture to chase auto-reviewer rotation; pivot once, cite, ship.

**Reference rule**: `Olympus-Approved/Feature-Requests/<repo>/<closest-shape>/test.patch` is the highest-authority precedent for test placement. Any auto-reviewer demand contradicting it is overrideable.

**Cost evidence**: yaegi-repl-doc absorbed 5 architecture pivots before locking final shape (~$60 in API). Lesson: cite precedent earlier, save 3 rounds.

---

## Pattern 31 — Auto-Review Verdict ≠ Final Approval (Contestation Hierarchy)

**Source**: yaegi-repl-doc shipped APPROVED despite 4 auto-review FAILs on build tag and other architecture points. Final human reviewer overrode advisory FAILs.

**The hierarchy** (from `Instructions/AUTO-REVIEWER.md § 1`):

```
LAYER 1 — Pre-flight CI runner       (HARD: must pass test.sh base + new)
LAYER 2 — Quality bots in parallel   (advisory, cluster of 6 bots)
LAYER 3 — Synthesis auto-reviewer    (advisory, may FAIL with blocking flag)
LAYER 4 — Human/admin reviewer       (FINAL, may override LAYER 3 FAILs)
```

**Contestation criteria**:
- LAYER 1 failure = hard reject. Fix BEFORE resubmit.
- LAYER 2/3 failures = advisory. Decide whether to fix or contest:
  - **Fix when**: the issue is in `AUTO-REVIEWER.md § 2 Stable Criteria` (ASCII, mode 100755, no AI comments, etc.)
  - **Contest when**: the issue is in `AUTO-REVIEWER.md § 3 Flaky Criteria` AND there's an approved-precedent folder

**Contestation in practice**:
1. Cite approved-precedent folder in `feedback.md`
2. Note explicit auto-reviewer demand history in case the same reviewer flips on rerun
3. Submit current state — final human reviewer respects precedent
4. If 2+ auto-reviews persistently FAIL on same axis, pivot to whichever pattern they don't reject (don't burn rounds chasing both)

**Don't panic-fix on every auto-FAIL**. `AUTO-REVIEWER.md §3-4` lists which issues are flaky. Read it before rebuilding architecture.

**Anti-pattern**: rebuilding architecture in response to each auto-FAIL pings $30-60 in API + 3-5 review rounds. yaegi-repl-doc burned 4 architecture flips this way before locking. Pivot ONCE, cite precedent, ship.

---

## Pattern 32 — Post-Base Maintainer Activity (catches "feature shipped between design and submit")

**Triggered by dasel-slice-operator REJECT (2026-04-30)** — issue #312 closed by maintainer 2026-03-30 with "This is implemented in v3" 20 days AFTER our base commit. v1 audit ran Phase 2 at base time + missed the post-base closure. Spec contradicted maintainer's docs. REJECT.

### When to apply

For any pick on an actively-maintained repo (≥1 commit/week). The risk is highest when:

- Pick targets a feature with a related OPEN issue (maintainer might close+ship at any time)
- Pick targets a feature for which the repo has existing-but-incomplete implementation (semantic-fix picks)
- Time between base commit and current authoring date >2 weeks
- Maintainer comments mention "I'll look at this in next release" or similar

### The 3 sub-checks (from Pattern 22 checks 4-6)

**Sub-check A — Closed issues with "implemented" pattern:**
```bash
gh issue list -R OWNER/REPO --state closed --search "<keyword>" --json number,title,comments,closedAt \
  | jq '.[] | select(.comments[]?.body | contains("implemented") or contains("supported in") or contains("This is in v"))'
```

**Sub-check B — Base→main commit overlap on relevant files:**
```bash
cd /tmp/<repo>-main && git log --oneline <BASE_COMMIT>..HEAD -- <relevant-source-files>
git log --oneline <BASE_COMMIT>..HEAD --diff-filter=A -- <relevant-package>/   # new files added
```

**Sub-check C — Capability test on current main HEAD (NOT base):**
```bash
cd /tmp/<repo>-main && go build -o <repo>.exe ./cmd/<repo>
echo '<test input>' | ./<repo>.exe <feature invocation>
# If 80%+ of feature scope works in main, REJECT regardless of base behavior
```

### Maintainer-published docs check (added 2026-04-30 from slice-operator post-mortem)

For any pick that touches **existing user-visible syntax**, fetch the maintainer's published docs:

```
WebFetch <maintainer-docs-URL>/<feature-page>
```

Compare maintainer's documented spec to our spec. If our spec **contradicts** documented behavior → automatic REJECT. Cannot ship a problem that asks the agent to **change** the maintainer's documented behavior.

Example (slice-operator): maintainer docs example `[0:4]` "retrieves the first 5 items" → inclusive both ends. Our spec: exclusive end. REJECT.

### Re-check timing

Run Pattern 32 sub-checks at:
- Initial scope decision
- Every scope reframe
- **Submit-pre-check** (immediately before generating final patches) — required because maintainer activity is continuous
- Before any reviewer-round resubmit (if previous round took >1 week)

Cost of skipping: half-day to full-day of authoring lost per missed signal.

---

## Pattern 33 — Triviality Filter for Additive-Function Picks

**Triggered by user feedback "M2 was trivial too easy" (2026-04-30)** — pick/omit (50 LOC each) classified GREEN in v1; user flagged as trivial. Pattern-followable from `func_first.go` (36 LOC) shape. Audit caught chunk/windows + zip/partition with same triviality profile.

### When a pick is TRIVIAL (auto-RED)

A pick is TRIVIAL if it satisfies ANY of:

| Criterion | Detection |
|---|---|
| Pattern-followable | `ls <package> \| wc -l` of similar files ≥3; agent copies template |
| Pure additive ≤50 LOC | `wc -l` of closest-shape existing file <50; new pick mirrors shape |
| Stdlib-equivalent | feature is `each`/`map`/`filter`/`sum`/`pick`/`omit`/`chunk`/`zip`/`partition`/`first`/`last`/`reverse`/`len` semantic clone |
| "Add N functions" | description is "Add A, B, and C" where each is independently solvable |
| Format wrapper | feature wraps a stdlib already supporting it (JSON-comments, YAML-1.1, etc.) |

### Decision tree

```
1. Is there ≥1 existing file in the same folder matching the proposed pick's shape?
   YES → check next; NO → proceed (pick is non-pattern)

2. Is the proposed solution ≤50 raw LOC across the new file(s)?
   YES → check next; NO → proceed

3. Are the new public API names independently solvable (each function on its own)?
   YES → TRIVIAL (auto-RED); NO → proceed

4. Does the feature require ≥3 cross-cutting interactions with existing systems
   (type system, scope chain, error handling, AST, executor pipeline)?
   YES → non-trivial; NO → still trivial

5. Could the proposed feature ship in <50 messages of agent work?
   YES → TRIVIAL; NO → ship-ready
```

### Diamond addendum — breadth is NOT difficulty; require an invent-a-mechanism hard core (rdb-maxkeysize-truncation, 2026-06-01)

Step 4 above ("≥3 cross-cutting interactions → non-trivial") gives a FALSE NEGATIVE for Diamond. `rdb-maxkeysize-truncation` touched 5 systems (decoder + model + helper reports + CLI + quicklist paging), shipped **699 LOC across 14 files**, passed every gate (Pattern 22 clean, Solution Quality PASS, Description Quality PASS) — and still scored **5/5, then 7/10, then ~all-pass across three FAIR Castor batches**. Castor (the strongest agent) absorbs any number of mechanically-obvious cross-cutting requirements, no matter the LOC or file count.

What makes a feature Diamond-hard (Castor ≤30%) is NOT breadth or LOC. It is an **invent-a-mechanism hard core**: a non-obvious algorithm / race / fixpoint the agent must DISCOVER, not merely wire up. `yaegi-channel-diagnostics` had one (a 50ms watchdog debounce for transient-rendezvous false-deadlock — 7/10 Castor failed it *even hinted*). `rdb-truncation` had none: "stop at a byte limit, skip the rest, report it" is mechanically obvious once specified, however many readers it threads through. Adding quicklist node-truncation, exact-vs-projection sizing, and Largest tie-break determinism each got absorbed.

**Design-time Diamond gate (run BEFORE authoring, alongside Section 9):** name the single hardest STEP an agent must INVENT. If the best you can name is "thread X through N places" or "read the spec carefully and sum/skip/wire" — that is breadth, not a hard core → **NOT a Diamond** (likely too easy for Olympus too; size it as Mars). A real hard core is a mechanism a competent engineer would NOT reach on first reading: a debounce/grace window, a fixpoint loop to convergence, a non-obvious traversal order, a race-correct protocol, a subtle invariant. Deterministic parsing / reporting / additive-API features almost never have one regardless of how many subsystems they span.

Cost of skipping this gate: rdb-truncation burned ~7 authoring rounds + 3 Castor batches + full Solution/Description-quality cycles before the triviality was conclusive and the pick was abandoned. The gate is one question asked at design time. Also confirms the hinted-flow rescue (Pattern: yaegi) needs a FAIR 0/10 — a tractable feature's 0/10 is always unfair (gotchas), and admin forbids hinting unfair problems, so there is no hint path back.

### Active-maintainer multiplier

If the repo is actively maintained (≥1 commit/week), additive function picks have a **1-2 week half-life** before:
- Maintainer ships the same function (your pick becomes Pattern 22 conflict)
- Reviewer flags the pick as pattern-followable

dasel example: maintainer shipped 23 selector functions in 50 days (~3/week). At that rate, every additive function pick proposed today has ~30% chance of being shipped by maintainer within 2 weeks.

### Mitigation strategies

When forced to ship an additive pick:

1. **Bundle 3+ functions with cross-feature traps** — `dasel-aggregation-functions` precedent (count/avg/groupBy/unique/flatten with insertion-order traps + deep-equality + flatten-depth)
2. **Combine with semantic option flag** — `dasel-csv-options` shipped CSV functions WITH separator auto-detect (Pattern 7 Symmetric R/W trap)
3. **Combine with new public API surface** — `dasel-ndjson-format` shipped NDJSON WITH `DetectFormat` / `RegisterDetector` API

### Prefer bug fixes when triviality risk is high

If your pick passes Pattern 22 but smells trivial via Pattern 33, pivot to a bug fix. Bug fixes:
- Don't ship from maintainer copy-paste templates
- Have natural cross-cutting requirements
- Age slowly (maintainer must understand the bug before shipping; takes longer than copy-pasting a function)

Cost of submitting a trivial pick: review round flags it; revise scope by adding cross-cutting trap; OR maintainer ships the trivial version meanwhile and pick becomes namespace conflict. Both paths cost 2-4 review rounds + token spend.

---

## Pattern 34 — Concrete Counter-Example Hint (Architectural Trap Disambiguation)

**Confirmed: yaegi-execution-tracer 2026-05-14, dasel-csv-options 2026-03 (precedent).**

### The Pattern

When agents universally miss an architectural distinction (sum-per-call vs persistent set, frame-anchored vs goroutine-id-keyed, A-without-B vs A-with-B), **verbal description alone fails**. The word "distinct" / "persistent" / "lifetime" / "per-instance" is INSUFFICIENT — agents read it as their default mental model.

**Fix:** add a concrete counter-example with **literal values matching the test assertion** to the spec sentence. The counter-example forces the agent to recognize their default is wrong.

### Confirmed examples

| Trap | Verbal spec (failed) | Counter-example added (succeeded) | Failure delta |
|---|---|---|---|
| **TotalLines sum-vs-set** (yaegi) | "distinct source lines executed across all invocations" | "**a two-line function called twice yields TotalLines=2, not 4**" | 100% → 22% (4× reduction) |
| **Loop-line dedup** (yaegi) | "deduplicate within a single invocation" | "**a line in a loop counts once per call, not per iteration — so N separate calls to the same function yield hit count N, not 1**" | 0% (test now baseline-passes) |
| **Null-write substitution** (dasel-csv) | "csv-null maps null model values to null string on write" | "**a null value with `csv-null=NA` writes 'NA' through the same quoting pipeline as any other field**" | enabled write-side trap symmetry |

### When to use

- 3+ Castor / 5+ Nova-Orion runs all fail on the SAME spec sentence
- The failure has 1-2 architectural variants (not 5+)
- The agent's wrong mental model has a clearly-different concrete value than the right model
- Adding the counter-example doesn't make the problem trivially decoded (counter-example matches test, but agent still has to implement the architecture correctly)

### When NOT to use

- Failure has 5+ architectural variants → no single counter-example helps (use cross-architectural test instead per `DIAMOND-PLAYBOOK § Section 1` ★ trap categories)
- Adding the counter-example would leak implementation HOW not WHAT (e.g., "use a sync.Map" — too prescriptive)
- The trap is a single-architecture off-by-one → counter-example fixes it in one round but the problem becomes too easy

### Hint hierarchy (from least → most directive)

1. **Behavioral verbal description** ("distinct lines"). Default attempt. Fails on universal blind spots.
2. **Concrete counter-example** ("2-line func × 2 calls = 2, not 4"). Pattern 34. Highest hit rate.
3. **Architectural recipe** ("per-frame state propagation, reset at goStmt"). Used for goroutine-depth trap — only 2/18 success without it.
4. **Code-shape hint** ("use the existing X function as scaffold"). Crosses HOW-not-WHAT line — reviewer-flagged.

Try level 1 → eval → level 2 → eval → level 3 if still 0%. Each level unlocks a qualitatively different failure mode but increases description specificity (Tighten-First inverse).

### Anti-pattern: abstract hint

- "Use a frame hierarchy approach" — yaegi 89%→90% failure (no improvement)
- "Implement N→N+1 dimension extension symmetrically" — dagster failed without prescriptive list

Abstract hints fail because they restate the spec in different words without changing the agent's mental model. Concrete counter-examples force model update.

### Description footprint

Pattern 34 hint sentences add **one short clause** to the spec. Examples above are 10-20 words. They fit naturally in shape-appropriate word budgets without triggering Quality "wall of text" or "code-instead-of-prose" flags.

### Relationship to Pattern 17 (Trap-Stacking Ceiling)

When stuck at a ceiling for 3+ rounds without movement, **Pattern 34 is the first lever to try** before reshaping. If a single counter-example moves the pass rate ≥10pp, the ceiling was a hint problem, not a shape problem. If pass rate doesn't move, reshape per Pattern 17.

---

## Pattern 35 — Implicit-Contract Audit (Pre-Submit Fairness-Round Pre-Empt)

**Confirmed: yaegi-checkpoint-api 2026-05-26 (7 fairness FAILs over R17-R23, 8 spec sentences added cumulatively).**

Every behavior a test asserts that the spec does NOT name → future fairness flag. Fairness reviewer reads meta + test names + assertion text; ANY behavior asserted but not stated = unfair flag. Each flag costs 1 revision round (~30-60 min) and ~10-30 meta words.

### The Audit (run before EVERY submission, especially Diamond)

For every new public API in meta, check three sub-cases have explicit spec coverage:

| Sub-case | Example (yaegi-checkpoint-api) | Missing → fairness flag |
|---|---|---|
| (a) Success path | "Inject writes the value" | Tests pin canonical form / sort order / aliasing not spec'd |
| (b) Malformed-input path | "ErrPathUnresolved wraps every unresolved-path error" | Tests pin Track/Untrack/History wrap not enumerated |
| (c) Cross-feature interaction | "Restore does not fire observers or append History" | Tests assert side-effect suppression not spec'd |

If ANY of (a-c) is unstated AND a test asserts it → either add 1 spec sentence OR drop the test.

### yaegi-checkpoint-api Round-by-Round Cost

| Round | Fairness flag | Spec sentence added | Word cost |
|---|---|---|---|
| R17 | bare `X` ≡ `main.X` aliasing | "A bare identifier with no dot resolves against the `main` package..." | +14 |
| R17 | Per-symbol Generation on Restore | "...once per restored symbol on `Restore`" | +6 |
| R17 | Observer registration order | "...in registration order across multiple observers..." | +7 |
| R17 | Nil callback rejection | "A nil callback returns an error." | +6 |
| R17 | History defensive copy on retrieval | "...returns a slice independent of later recording" | +6 |
| R18 | Canonical reporting in Snapshot.Symbols / Tracked / Diff | "Reporting APIs (`Snapshot.Symbols`, `Tracked`, `Diff` paths) emit the canonical dotted form" | +13 |
| R18 | CLI `-cat` lowercase strings | "Its `String()` returns the lower-case form (`unknown`, `var`, `const`, ...)" | +12 |
| R20 | History on resolved-untracked returns empty | "`History` on a resolved but untracked path returns an empty slice with no error." | +14 |
| R21 | History returned slice element-deep-cloned | "fresh, independently deep-cloned slice so mutating a returned `reflect.Value` does not affect later reads" | +15 |
| R23 | Restore-skips-Observer / History | "`Restore` does not fire observers or append `History` entries." | +8 |

**Cumulative:** meta 330 → 497 words (+167 words / 8 spec sentences / 7 revision rounds). All preventable with pre-submit audit.

### Audit Procedure

```bash
# 1. Extract every test name in the new suite
grep -E "^func Test" tests/*.go | sed -E 's/^.*func (Test\w+).*/\1/' > /tmp/tests.txt

# 2. For each test, write 1-line behavioral summary
# 3. For each summary, grep meta for explicit coverage
# 4. Flag uncovered summaries as candidate spec additions
```

### Anti-pattern: skipping audit because tests are "obvious"

Reviewer fairness reads literally. "History returns a fresh slice" does NOT cover "elements of that slice are themselves deep-cloned on every read." "Generation advances on Restore" does NOT cover "delta equals number of restored symbols."

### Relationship to Pattern 22 (Namespace Audit) + Pattern 32 (Post-Base)

Pattern 22/32 = pre-design audits (don't pick this feature).
Pattern 35 = pre-submission audit (this feature is fine, but spec is incomplete).
Run Pattern 35 at design time AND at submission time. Cost: 15 min audit prevents 4-7 fairness rounds (≈4 hours).

---

## Pattern 36 — Failure-QA Citation Triangulation Discipline (Diamond-only, validator-iteration cost reducer)

**Confirmed: yaegi-generic-constraint-fidelity 2026-05-27 (R13 → R14 → R15, ~17 FALSE/MIXED → 3 → 0 across 10 Castor sections).**

Diamond failure-QA validator literal-greps every cited line, every verbatim quote, every identifier. Memory-paraphrased citations FAIL byte-level matching even when conceptually correct. Without discipline, expect 3 validator passes (~30-45 min each = ~90-135 min wasted). With discipline, reduce to 1 pass.

### The Triangulation Rule (mandatory for every root cause)

Cite THREE sources per root cause:

| Source | What it proves | Example |
|---|---|---|
| `agent_solution_patch:LINE` | What agent built | `untypedAssignableTo` defined at lines 511-520 |
| `repo_file:LINE` | Pre-existing mechanism agent's code interacts with | `interp/type.go:1490-1493` shows loose-numeric `assignableTo` fallback |
| `junit_new_xml:LINE` | Observed failure symptom | `157/50 truncated to int64` at lines 21-23 |

Single-cite or dual-cite claims get MIXED. Triple-cite passes.

### The Verbatim Rule (no paraphrasing repo internals)

Validator is byte-level grep. Common paraphrase failures:

| Paraphrase that fails | Verbatim that passes | Source |
|---|---|---|
| "runtime constant-folder" | `representableConst` check | `interp/typecheck.go:1131-1143` |
| "defers overflow to runtime checking" | "to be tested elsewhere" | `interp/type.go:1491-1494` comment |
| `"untyped float64"` | `"untyped float"` | `untypedFloat.str` in `interp/type.go:160-162` |
| `reflect.Value.Kind()` (when test wraps it) | `runOKKind` helper | `test_patch:334` |
| `MinX(...)` (ellipsis token) | `MinX` (bare identifier) | function name in test_patch |

### The Predicate-vs-Emit-Site Rule

Bool predicates (`representableConst`, `isFoo`, `matches`) return true/false and never emit error text. The surrounding `if !pred { return cfgErrorf(...) }` emits the diagnostic. Cite the **emit site**, not the predicate, when attributing diagnostic text.

### The Workflow Reversal (3-pass → 1-pass)

Default failure mode: write plausible-sounding prose, hope citations match. Validator pass 1 flags ~15-20 FALSE/MIXED per 10 sections.

Reversed workflow:
1. Open `sol-dif.md`, find the relevant hunk, COPY line numbers into draft
2. Open `repo_file` at the cited line, COPY verbatim comment/code into draft
3. Open `junit_new_xml`, COPY exact symptom string
4. THEN write prose around the 3 anchored citations

Read repo source ONCE per problem and reuse cited lines across sections (yaegi: `interp/type.go:1490-1493` cited correctly in 6/10 sections after one verification).

### Interpretive Claims Need Explicit Framing

Validator accepts "interpretive but well-grounded" judgments for fairness calls and classifications IF paired with concrete code citations. Tag explicitly:

- `Unfairness check: Fair.` — followed by quoted spec sentence
- `Classification: incorrect assumption / missed requirement / missed edge case / wrong architecture` — followed by which code path is broken

Bare interpretive claims with no code anchor → MIXED.

### When This Pattern Applies

- **Diamond submissions** (failure-qa.md): mandatory. Validator gates submission.
- **Olympus submissions**: not validator-checked, but applying Pattern 36 shaves AI Reviewer / Auto Reviewer / Holistic Review feedback cycles.
- **Mars submissions**: feedback.md notes use this pattern when documenting iteration history (helps future authoring agents).

### Cost-Benefit

- Authoring discipline: +20-30 min per failure-qa section (read source first, copy lines, then write)
- Avoided rework: 2-3 validator rounds × ~30-45 min = 60-135 min saved per submission
- Net: ~30-90 min saved + cleaner reviewer experience

### Relationship to Pattern 35

Pattern 35 = pre-submit spec audit (does meta cover what tests assert?).
Pattern 36 = post-eval QA audit (does failure-qa cite real code/output?).

---

## Pattern 37 — Forced-Representation Trap (the natural internal key is not unique under re-entry)

**Confirmed: piccolo-to-be-closed, Olympus APPROVED 2026-06-24, 6/10 Castor biters (one a hang) — the single most effective trap in a 20%-pass cross-subsystem feature.**

The strongest trap was not a marquee algorithm. It was a forced choice of INTERNAL REPRESENTATION whose natural key is not unique across the dynamic executions the spec cares about.

### The mechanism

A feature needs internal bookkeeping (here: pending to-be-closed slots). The obvious key is a "natural identity" — a stack slot / register / variable name / pointer — and dedup on that key looks like a sound invariant. It is correct for straight-line code and a single pass, so it clears the happy-path tests (reverse order, return, break, error unwind). It is WRONG the instant the key RE-ENTERS: a `<close>` local in a loop body reuses the same register every iteration, so a register-keyed + deduped store registers and closes it once instead of once per pass. The correct representation is per-dynamic-registration (`{stack, value, close_fn}`), no key dedup.

### Why it defeats opus-4-8 / Castor specifically

- **The wrong choice is the natural first choice.** Nothing in the happy path punishes the register key.
- **Interdependent by construction.** One shared store backs every exit path (normal, return, break, goto, error, coroutine.close). A local fix to any single path cannot surface the bug — only changing the representation does. This is precisely the single-point-fix that smart solvers reach for and that fails here.
- **Misdirecting.** It surfaces as a wrong observable count ("aaa"→"a") or a non-terminating HANG, never as a diagnostic naming the cause.

### How to design it

1. Pick a feature needing lifetime/identity bookkeeping with a "natural key" (stack slot, register, name, pointer, node).
2. Confirm the key is NOT unique across a construct the spec requires (loop body, recursion, shadowing, re-declaration, re-entry).
3. Drive happy-path tests so the natural key passes (don't over-hint the trap).
4. Add ONE behavioral test that re-enters the same key; only a per-instance representation passes. Keep it observable (order/count), not an internal-state assertion.
5. Stack a second, independent subtlety on a different axis (piccolo: within-block goto must NOT close, via patched jump stack level) so a single representation fix does not clear the whole suite.

### Where to look (transferability)

Any internal bookkeeping with a re-enterable key: scope/close tracking, symbol tables keyed by name vs binding, memo caches keyed by node vs node-instance, optimizer-pass dedup sets, register/slot allocators, visitor "seen" sets across recursion. GREP the spec for any construct that re-enters the same key — that is where the natural representation breaks and where the decisive test belongs.

### Relationship to other patterns

Pattern 17 (trap-stacking ceiling): this is a high-yield trap to stack because it is interdependent, not additive. Pattern 37 trap + one orthogonal block-exit subtlety held an Olympus band where +9 additive tests had only made the problem easier (avg-pass-fraction rises with passable tests; see `PLAYBOOK.md` + `lessons-learned.md § piccolo-to-be-closed`).
Both apply at submit-time. Pattern 35 stops fairness flags; Pattern 36 stops validator FALSE/MIXED churn.

See also `DIAMOND-PLAYBOOK.md § Section 5 rules 13-20` (20 failure-QA writing rules) and `lessons-learned.md § Consolidated Failure-QA Writing Rules` (40 rules + flagged-phrase blacklist).

---

## Pattern 37 — Pre-existing Loose Helper as Stricter-Predicate Trap (cross-architectural ★★★★)

**Confirmed: yaegi-generic-constraint-fidelity 2026-05-27 (6/10 Castor hits = 60% — 3 distinct architectural variants).**

When spec requires a STRICT version of a check that the repo ALREADY has a LOOSE version of, Castor reuses the loose helper. The reuse looks reasonable (right name, right signature, right repo idiom), but the helper's hedging comment ("overflow check deferred", "tested elsewhere", "approximate") is exactly the gap the spec demands the new code close.

### The Trap Mechanism

1. Repo has pre-existing helper `existingPred(a, b) bool` with comment hedging strictness
2. Spec at new call site demands strict version: "X is valid only if Y holds" (Go-spec representability, Rust trait-bound coherence, TypeScript narrow-vs-wide, etc.)
3. Castor adds new gate at new call site, DELEGATES the predicate to `existingPred`
4. Loose check passes → spec violation slips through → DOWNSTREAM legacy code emits non-structured error → test fails on error TYPE / TEXT / SENTINEL, not on existence

### Architectural Variants (same trap, 3+ shapes)

yaegi-generic-constraint-fidelity surfaced three variants in 10 runs:

| Variant | Pattern | Why it fails |
|---|---|---|
| (a) Fall-through | New `wrapper(u, v)` returns true on early case, else `return existingPred(u, v)` | Existing loose path still reached |
| (b) Direct shortcut | `if isNumber(u) && isNumber(v) { return true }` (skip strict check entirely) | Bypasses representability |
| (c) Category shortcut | `if u.cat == numericCat && v.cat == numericCat { return true }` | Same as (b) at category level |

All three pass the new gate, all three fail tests that probe via structured-error wrapping.

### Design Recipe (use as Diamond trap source)

- Repo has pre-existing loose helper with hedging comment
- Spec demands strict version at NEW call site
- Test triangulates: (1) error text substring, (2) sentinel unwrap (`errors.Is`), (3) structured-error type assertion (`AsX(err) != nil`)
- Triple-probe catches every architectural variant

### Pre-empt Sentence Pattern

State the strict rule + name what loose helpers do NOT suffice:

> "Representability is Go-spec strict: `untyped float` is representable as `int64` only if the constant's value fits, not merely if both kinds are numeric. Existing assignability rules in the interpreter are not sufficient — they defer overflow checking."

Naming the existing rule's gap forces Castor to write the strict predicate from scratch.

### Where This Appears in Repos

- **Type systems** — assignability vs representability, conversion vs coercion, narrowing vs widening
- **Permission systems** — authorize-any vs authorize-strict, role-contains vs role-equals
- **Path/URL parsers** — segment-acceptance vs RFC-compliance, lexical-validity vs filesystem-existence
- **Crypto primitives** — verify-signature vs verify-and-check-domain, decrypt-OK vs decrypt-and-AAD-match
- **Concurrency primitives** — happens-before-loose vs happens-before-strict, isolated-read vs serialized-read

Anywhere the repo has a public helper named `<verb>able` or `<verb>OK` or `is<state>`, check its docstring for hedging — if hedged, it's a Pattern 37 trap candidate.

### Relationship to Pattern 17 (Trap-Stacking)

Pattern 17 = bundle multiple traps in one problem to raise difficulty.
Pattern 37 = ONE trap that admits 3+ architectural variants — counts as a "deep" trap that holds 2-3 trap-stacking slots on its own.

Stack Pattern 37 with one orthogonal trap (e.g. callback wiring, helper-never-called) for Diamond. Do NOT stack 3 Pattern-37 traps — too narrow.

---

## Pattern 38 — Helper-Defined-But-Not-Wired Trap (cross-architectural ★★★)

**Confirmed: yaegi-generic-constraint-fidelity 2026-05-27 (3/10 Castor hits = 30%) + yaegi-checkpoint-api Snapshot deep-clone trap.**

Castor writes a helper function that matches the spec name + signature, AND adds the public error type / callback / API surface, AND the file structure looks complete. But the helper is never invoked at the critical call site. Pre-existing code at the decision point unchanged.

### The Trap Mechanism

1. Spec requires a transformation T on input X before decision D
2. Repo's natural place to add T is `path/A.go`
3. Pre-existing decision D lives at `path/B.go` (different file)
4. Castor adds `func T(x)` in A.go correctly. Tests for T pass.
5. Pre-existing B.go still reads raw X at decision D. Tests at D fail.

### Why Castor Trips Through This

- Patch diff LOOKS comprehensive (new helper + new types + new tests' interfaces all satisfied)
- Diff reviewer skim sees the helper exists, assumes it's wired
- Only running tests proves the helper is dead code
- Castor's confidence-driven model declares "done" before tracing full call graph

### Diagnostic Signal

If failing tests have failure messages that look identical to the BEFORE-PATCH baseline (e.g. `untyped float does not implement main.OrderedX` — pre-existing yaegi error, not new structured error) → strong signal that new code exists in a parallel universe to the decision path.

### Design Recipe

- Spec a transformation that must run at a SPECIFIC stage
- Use temporal words in spec: "BEFORE", "DURING", "AFTER", "AT INSTANTIATION TIME", "AT CALL TIME"
- Pre-existing code reads the un-transformed value at a different stage
- Test asserts the transformed-stage behavior

### Pre-empt Sentence Pattern

Spec the stage explicitly:

> "Default-type promotion runs BEFORE constraint membership testing, not after. The constraint check sees the promoted type, not the untyped form."

The word "BEFORE" is the discriminator. Without it, Castor may add T post-check (which is too late) or T at a parallel site (which is dead code).

### Test Discipline

Tests must assert NEW behavior at the EXISTING failure path:
- Test for transformation T applied (positive)
- Test for legacy error message ABSENT (negative — `runNotInErr(..., "old error text")`)
- Test for structured error PRESENT (`AsX(err) != nil`)

Triple probe catches dead-code helpers.

### Relationship to Pattern 37

Pattern 37 = wrong predicate at right call site.
Pattern 38 = right helper at wrong call site (or not wired).
Stackable: yaegi-generic-constraint-fidelity stacked Pattern 37 (loose `assignableTo`) + Pattern 38 (`defaultIfUntyped` never called by `checkConstraint`) + small Pattern (rune-only asymmetric miss). 2/10 pass — Diamond sweet spot.

---

## Pattern 39 — Strict test.sh Argument Validation (V2-carryover defense)

**Confirmed: yaegi-checkpoint-api Auto Review R24 [High], 2026-05-06 V2 reviewer origin.**

V2 reviewer feedback verbatim: "Do not default missing mode to base. Reject multiple modes, unknown arguments, missing output path value, or missing mode with a non-zero usage error." Diamond Auto Review weighs prior-revision reviewer feedback (ground #4 in contributor guidelines). Silent defaults / overwriting case-loop reach later submissions and trigger FAIL on grounds the V2 reviewer named explicitly.

### Reject patterns

| Anti-pattern | Effect |
|---|---|
| `MODE="${MODE:-base}"` | Silent default — `./test.sh --output_path X` runs base without flagging |
| `base\|new) MODE="$1"; shift ;;` with no count tracking | `./test.sh base new` silently runs `new` (later wins) |
| `*) shift ;;` catchall in case-loop | Silently ignores typos like `--ouput_path` |
| `--output_path) OUTPUT_PATH="$2"; shift 2 ;;` | Crashes on `--output_path` as last arg instead of exit 2 |

### Required validation block

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

### Verification

```bash
./test.sh                           # → exit 2 "missing mode"
./test.sh --output_path /tmp/x.xml  # → exit 2 "missing mode" (NOT silent base)
./test.sh base new                  # → exit 2 "only one of base or new"
./test.sh --typo                    # → exit 2 "unknown argument: --typo"
./test.sh --output_path             # → exit 2 "missing value for --output_path"
./test.sh base                      # → exit 0, runs base
./test.sh --output_path /tmp/x.xml base  # → exit 0, runs base, writes XML
```

### Cost

Adds ~10 lines to test.sh. Prevents one Auto Review FAIL round at Diamond (~30-60 min iteration) and removes a recurring V2-reviewer flag pattern.

---

## Pattern 40 — Representation-Type Pin as Compile-Unfairness (ANTI-PATTERN — tier-agnostic)

**Source:** rdb-sample-fraction (Diamond APPROVED 2026-05-31), first Castor batch.

When a new public struct's fields are consumed by **typed test arithmetic** (`var sum int; sum += est.SampledKeys`, `int64(math.Round(x)) != est.EstimatedBytes`), the test PINS each field to a specific Go integer type. An agent who picks a different-but-reasonable type (`uint64` for a count, `int64` for a key count) makes the whole package **fail to compile**, which masks every downstream test in that package. In rdb this took out ~65 tests at once; one evaluator flagged `agent_blame_unfair: true`, `description_clear: false`.

**Why it is unfair:** field integer type is a representation choice with no behavioral meaning. A test that breaks on `uint64` vs `int` is an implementation-detail test, not a behavioral one — it fails a correct solution for a cosmetic reason and hides the real signal behind a compile error.

**Two fixes (pick one):**
- **Document the exact types in the description** (what rdb did): "the key counts (`SampledKeys`, `EstimatedKeys`) are int and the byte and element totals (...) together with each `UpperBound` are int64." One sentence unblocked 4/5 agents on the next batch.
- **Relax the tests to behavioral checks** that accept any integer type (compare via a cast, assert the value not the type).

**Pre-empt rule:** any Mars/Olympus/Diamond pick that adds public structs the tests accumulate into MUST either name the field types in the description or relax the assertions. Treat this like Pattern 18 (compile-time decoupling): a compile break masks all behavioral signal, so it is never acceptable collateral.

---

## Pattern 41 — Cost-Test-or-Decorative: difficulty erodes without a perf assertion (tier-agnostic difficulty design)

**Source:** rdb-sample-fraction — the central `core/skip.go` (250 LOC byte-exact stream skip) was non-load-bearing for the first nine Castor batches.

When a requirement is "do X **without** materializing / decoding / allocating / re-traversing" (lazy eval, streaming, skip-on-the-wire, single-pass, zero-copy), a **behavioral** test suite usually CANNOT distinguish the faithful implementation from the lazy shortcut, because the observable output is identical. rdb's "skip the value on the stream instead of decoding it" was satisfied by `readObject`-then-discard in ALL 10 runs (including the PASS): `GetSkippedCount() > 0` and "following keys still parse" both hold whether you byte-skip or decode-and-drop. Result: the hardest 250 LOC were optional, rollouts averaged 0.66 (too easy), and the difficulty came entirely from an unrelated trap.

**The rule:** if the difficulty of a pick rests on a "do X without Y" requirement, you MUST add a **cost test** that fails the shortcut:
- Allocation budget: `runtime.MemStats.TotalAlloc` (Go) / `tracemalloc` (Python) delta across the operation, fail if above a threshold the faithful path stays under and the shortcut blows. (rdb: a 48MB rejected value, fail if >16MB allocated — true skip stays under, decode-and-discard allocates the full 48MB.)
- Timing/complexity: assert O(1)/O(log n) wall-clock on a large input the O(n) shortcut cannot meet (use a generous margin to avoid flakiness).
- Side-effect counter: a spy/hook that counts decode calls, parser invocations, or DB round-trips.

**If you cannot write a cost test, the no-materialize requirement is decorative** — drop it from the difficulty budget and find the difficulty elsewhere, or the pick lands too-easy. Diagnostic signal: agents pass with far fewer LOC than the reference and the "expensive" file is absent from their diffs.

---

## Pattern 42 — Choke-Point Triviality: push difficulty to the consumed-and-discarded value (extends Pattern 23/33, tier-agnostic scoping)

**Source:** rdb-sample-fraction architecture correction (the membership filter alone was Pattern-23 trivial).

Many repos route every consumer through ONE option/middleware **choke point** with N sibling options already present: rdb's `wrapDecoder(dec, options...)` at `helper/regex.go:208` (6 sibling option types), Express/Koa middleware stacks, a `Visitor`/`Pipeline.use()`, a `cobra`/`kong` flag registry, a webpack/rollup plugin array. Adding ONE more option/filter/middleware to such a choke point is **Pattern-23/33 trivial** (~150 LOC: copy a sibling, swap the predicate). Castor/Nova solves it in <50 messages.

**Where the real difficulty lives (two reusable boundaries):**
1. **The consumed-and-discarded value.** A choke point that returns only the wrapped object (rdb's `wrapDecoder` returns `(decoder, error)` — the option VALUES are consumed and never returned) forces any downstream stage that needs the value to **re-extract** it independently. An agent who edits only the choke point gets the filter wired but never reaches the re-extraction sites. This admits 3 architectures (re-extract from options / change the choke-point return signature / stash in a package var — the last breaks under concurrency), and missing one site is the dominant failure.
2. **The per-item-vs-aggregate output boundary.** When the new option changes how results are summarized, only SOME outputs transform (rdb: prefix/estimate aggregates scale by 1/fraction) while others must NOT (per-key listings report real sizes — **negative controls**). Pushing the transform into the shared choke point leaks it into the negative-control outputs and fails them. The correct design transforms only the divergent stages.

**Scoping rule:** before scoping an option/filter/middleware pick, find the choke point and count the siblings. If a new sibling is the whole pick → trivial, REJECT or redesign. Move the difficulty onto the re-extraction boundary + the transform-vs-negative-control split. Catch tests: assert the value reaches every divergent site (forgot-a-site) AND assert the negative-control outputs are unchanged (scale-leak).

---

## Pattern 43 — Distribution/Determinism Hash Trap (tier-agnostic anti-agent trap for sampling/bucketing/shard features)

**Source:** rdb-sample-fraction — 9/10 Castor failed this single FAIR trap (the solvability gate).

For any feature that **deterministically selects, buckets, shards, or partitions** by hashing a key ("sample a fraction", "consistent-hash to N shards", "bucket by key", "stable dedup"), the spec phrase "deterministic and reproducible" + "processes only a fraction / distributes evenly" **implies a well-distributed hash** without stating it. Agents reach for the cheapest digest and compare it raw/shifted/modulo against the threshold:
- raw `fnv.New64a()` vs `fraction`, `(Sum64 >> 11)/2^53 < fraction`, `(Sum64 & mask)/2^53 < fraction`, `Sum64 % denom < fraction*denom`, `fnv.New32a` vs `fraction*2^32`, hand-rolled FNV vs `fraction*2^64`.

None of these avalanche. **The trap fires only when the test fixture uses sequentially numbered keys sharing a prefix** (`acct:0..49`, `user:0..49`, `stream:0..9`): an unmixed digest maps a whole prefix group to ONE side of the threshold, so the group is selected **all-or-nothing**. At fraction 0.5 the group comes back empty (got 0) or whole (got N) instead of a proper subset. rdb saw SEVEN distinct wrong forms across 9 runs; the 1 PASS reduced the full digest `% 2^32` (wide enough to distribute).

**Reference correct implementation:** FNV-1a then a finalizer (murmur3 fmix `x ^= x>>33; x *= 0xff51afd7ed558ccd; x ^= x>>33`) or a wide reduction, then compare top bits vs `fraction * denominator`.

**How to build the trap:**
- Fixture: sequential prefix keys (the clustering only shows on near-identical inputs). Random keys hide it.
- Catch test: assert a STRICT subset at fraction 0.5 — `0 < n < total` — plus per-prefix-group presence (the group must contribute to its aggregate report). This catches both tails (empty AND whole).
- Keep the distribution requirement **UNDOCUMENTED** — it is the fair difficulty; "deterministic + processes only a fraction" is enough for a competent engineer to infer even distribution. If 0/N, the distribution hint goes in the separate hint section, never the description.

**Fairness note (tier-agnostic):** when 9/10 agents fail for the SAME reason on a trap like this, that is the admin 2026-05-29 **fairness signal** (analyze the shared cause, then accept if a competent engineer reading description + repo would infer it), NOT an unfairness flag. rdb's human reviewer confirmed acceptance.


## Pattern 44 — Diamond failure-QA validator grouping-binding (yaegi-channel-diagnostics, approved 2026-05-31)

The Diamond failure-QA auto-validator binds each claim to the PLATFORM's behavioral grouping of the failing tests (the test-file group, observed as a name prefix: non-Cross vs Cross), then matches the claim against the tests bound to that block. It does NOT honor a writer's own clustering. Consequences, all learned across a 6-round convergence (14 -> 7 -> 2 -> 0 flags, then a reviewer QA change-request, then a stale-verdict + grep-variance pass):

1. Align failure-qa blocks to the platform's grouping. Never regroup blocks along a symptom axis (e.g. genuine-deadlock vs false-positive) that cuts ACROSS the platform groups - even when a human reviewer explicitly asks you to "split" the symptoms. A pure-genuine block bound to a symptom-MIXED platform group makes "each of these builds a genuine deadlock" FALSE for the progress tests in that group. Resolution: keep the behavioral-group block (e.g. "Single-feature deadlock detection" = the non-Cross tests, "Cross-feature deadlock detection" = the Cross tests) and split the genuine-vs-false-positive distinction INSIDE the block (prose + the Expected column), with a both-manifestations root cause true for every test.
2. A whole-group claim ("each of these ...") must hold for EVERY test the platform binds to the block. If the group is symptom-mixed, write a both-manifestations claim, not a single-symptom sweep.
3. Per-run agent code differs. A causal mechanism (e.g. "report frozen while only the top-level goroutine is blocked") verified TRUE for one run can be FALSE for another that shows the same junit symptom but different code. State only what THAT run's diff supports; when the causal timing is not in the diff, fall back to the verified predicate + the junit observable.
4. A bare backticked repo identifier the validator must grep (e.g. `rangeChan`) is grep-variance-prone: TRUE in runs where the grep target resolves, MIXED in runs where it does not, for the same token. Anchor path-miss / range-miss claims on the agent's own recording helper + the behavior + the junit symptom, not a standalone repo function name.
5. Cite the helper that HOLDS the logic, not a wrapper that delegates to it (e.g. `recordChanOp` delegates to `recordChanOpBlocked` - name the latter for the `Recvs++` arm). No struct-literal tokens (`GoID: 0`) the diff does not literally contain. No value-anchored line numbers on field values.
6. Stale-verdict guard: a validator verdict can score a pre-edit upload. Before re-editing on FALSE/MIXED, grep the flagged strings in the current file; if absent, the verdict is stale on those claims - re-upload, do not re-edit.

Adjacent reviewer-judgment lessons from the same arc: test-groups.md grouping must match a test's ACTUAL assertions, not its name or list adjacency (a test named *Enable* that asserts enabled-recording counts belongs in the event-recording group, not the off-state group). The Diamond Env Description is 2-3 sentences / one paragraph with NO markdown `#` title (a heading is read as the title, leaving the body as a single sentence), framed as the engineering challenge and not an implementation recipe (mutex / frame-keying / watchdog detail belongs in solution-approach.md). Env Description + failure-qa.md + test-groups.md are QA-tier and do not stale Castor / Diamond Checks / Auto Review; both QA artifacts are platform-uploaded (keep them free of local workspace filenames).

## Pattern 45 — Diamond QA is a two-gate factual-correctness deliverable; cite value-anchored vs behavior-anchored (yaegi-generic-constraint-fidelity, approved 2026-05-31 — 2nd independent confirmation of Pattern 44)

yaegi-generic-constraint-fidelity (approved, reviewer "gtg. qa is now factually correct") converged on the SAME QA discipline as yaegi-channel-diagnostics (Pattern 44) by a different path. Two independent arcs hitting the identical rule-set promotes these from one-off to stable law. The new/sharpened angles:

1. **The QA artifact has its own approval gate, separate from solvability.** This sub cleared Castor solvability (3/10), Holistic (0.30), and Auto Review days before approval; the ONLY remaining blocker was per-test QA factual accuracy. failure-qa.md + test-groups.md are gated deliverables graded on "right test bound to right Expected/Actual to right root cause", not prose. Budget QA as a first-class phase, not a write-up.

2. **Two gates, different checks.** The auto-validator greps named identifiers and matches behavior to code (returns true/MIXED/false per claim). The human reviewer judges grouping fairness, per-test completeness, attribution accuracy, and platform naming. ALL-TRUE on the validator does NOT mean the reviewer passes (and vice-versa). Pass both by copying the approved gold-standard shape on the FIRST draft (the Zeroth Rule); skipping that read cost 4 avoidable QA-only rounds here and 6 validator rounds on channel-diagnostics.

3. **Value-anchored vs behavior-anchored citation (the sharpest transferable rule, tier-agnostic for any validator/reviewer-cited claim).** A VALUE-anchored line number presents the line as the locator for a specific field/string value (`str is "untyped float", type.go:160`) -- it goes MIXED when off-by-one, and the validator is NON-DETERMINISTIC on it (the identical `:160` token passed in one run, MIXED in another the same round). A BEHAVIOR-anchored line number sits beside a named function whose behavior the validator matches (`the loose assignableTo (type.go:1466), which accepts an untyped float`) -- tolerated, because the function name carries the match. Rule: never attach a line number to a field/string VALUE unless you read that exact line this session; name the field instead. Gold-standards carry zero line numbers and pass.

4. **Two distinct grouping errors** (extends Pattern 44's grouping-binding): (a) OVER-COLLAPSE -- summarizing N distinct-assertion tests with 2-3 broad examples; fix = per-test `| Test | Call | Expected | Actual |` table, one shared root cause below. (b) OVER-ATTRIBUTION -- crediting a named branch with the OTHER (passing) tests' success inside a failing block; per-run agent code differs, so that cross-test causal claim is usually unverifiable (the same `def.equals` attribution was TRUE for one agent's code, FALSE for another's). Explain only why THOSE tests fail.

5. **Platform naming.** The artifact is read by a reviewer who never sees the workspace: quote "from the description" (NEVER "meta.md" / "the prompt" / any local filename), and never name local files (test.patch, solution.patch, Castors/, sol-dif.md) in the text. Use platform-facing terms (the description, the tests, the agent's submission, the reference solution). `quoted from meta.md` is a recurring agent mistake and is auto-unacceptable.

Reusable difficulty-engine note: the core trap here (go/constant STRICT representability vs the interpreter's LOOSE `assignableTo`) is a confirmed, approvable Diamond seam for any interpreter/type-system repo -- a built-in permissive check the spec forces the solver to tighten. Pairs with build-tag test isolation (3rd clean yaegi ship) + 3-layer JUnit fallback.

Copy-ready writer prompt for both QA artifacts: `Instructions/QA-WRITER-PROMPT.md`.

## Pattern 46 — Concept-similarity collision on a same-repo introspection-API family (yaegi-unreachable-code, approved 2026-06-03; extends Pattern 22)

The platform similarity gate is concept+domain embedded (threshold 0.9) and is INDEPENDENT of the Pattern 22 GitHub-namespace + maintainer audit. A pick can be GREEN on all six Pattern 22 checks (no PR/issue, no maintainer-philosophy block, feature absent) and still collide with an OLDER problem authored on the same repo, by concept.

**Track record:** `yaegi-closure-introspection` was built end-to-end (DESIGN + solution + 73 tests + Docker + patches, both orders validated) and scored **0.81** against an older same-repo "Closure-capture introspection API (AnalyzeCaptures)" — a concept match, not wording. Reframing inside the closures idea (renaming the API, adding fields) cannot move a concept embedding, so the folder was discontinued. The escape was a DIFFERENT CONCEPT AXIS: control-flow reachability (Go-spec terminating statements) instead of data-flow capture. The reworked pick `yaegi-unreachable-code` scored **0.683** and shipped.

**Why:** active repos accumulate an authored "X-introspection-API" family (capture, channels, generics, checkpoint, tracer). A new introspection/diagnostics pick on the same repo is a near-neighbor of the whole family even when its exact API names are novel.

**How to apply:**
- For any same-repo introspection/diagnostics pick, assume an authored family may exist; pick a concept axis distinct from prior picks (control-flow vs data-flow vs type-flow vs concurrency vs reflection).
- Similarity CANNOT be measured locally — treat the platform recheck as a real gate; do not sink full authoring into a near-neighbor pick without a fallback in mind.
- Fallback when collided: a behavioral variant (a strict compile option that ERRORS instead of an observe-only reporter changes the shape), or a different yaegi-equivalent repo (scriggo / engine262 / anko).

Pattern 22 audits GitHub history + maintainer philosophy; Pattern 46 is the orthogonal platform-similarity axis. BOTH must pass — a clean Pattern 22 does not imply similarity clearance.

## Pattern 47 — External-test-package exact-type import is an API-shape compile-collapse (yaegi-unreachable-code, approved 2026-06-03; extends Pattern 40)

When the hidden test file lives in an EXTERNAL package and imports the new API by exact Go type, the public return-type SHAPE becomes load-bearing in a way a single brittle test never is: a plausible-but-different shape fails the WHOLE file to COMPILE, zero-scoring every test at once.

**Track record:** unreachable-code R1 (5 smoke Castor): the external `interp/unreach_4eacbc` package does `dead(...) []interp.UnreachableStmt` and `parsePos(d[0].Position)` (string split on ":"). 4/5 agents chose a reasonable-but-different shape — 3 returned `[]*UnreachableStmt`, 1 made `Position` a `token.Position` — and the package would not compile, so all 75 interp tests synthesized as "API missing" (0.02 reward). The 5th guessed the shape and hit 76/78. Holistic verdict NEEDS_HINTS, but the cause was API-shape AMBIGUITY, not analysis difficulty.

**Fix (admin "ambiguous spec -> reword, not hint"):** pin the public return types in the description — value vs pointer slice (`returns a []UnreachableStmt`), pointer-or-nil (`returns a *UnreachableStmt ... or nil`), field string-vs-struct (`Position ... as a line:col string`). Return types are the public contract (WHAT, not HOW), so this is spec-completion, not a leak. After the pin, 10x Castor went 2/10 (20%, band) with failures only on the genuine edge-case traps, and the sub approved.

**Distinction from Pattern 40:** Pattern 40 is the AUTHOR weaponizing a type-pin (e.g. `int` vs `uint64` struct field) as a deliberate compile-trap — flagged anti-pattern. Pattern 47 is the inverse: an UNINTENDED shape ambiguity that nukes the external test file and reads as unfairness; the fix is to REMOVE it by documenting the contract. Rule of thumb: a value-vs-pointer or string-vs-struct API SHAPE is contract, document it; a numeric WIDTH that only matters for typed test arithmetic is the Pattern 40 anti-pattern, avoid it.

**Companion test.sh discipline (tier-agnostic):** validate JUnit XML with a PARSER, never grep. unreachable-code's curated base run hit a yaegi subtest named `TestIssue1623/pkg.S_=_"bar"`; the test.sh awk emitted the name raw into `name="..."` and the embedded `"` broke the attribute. `grep -c '<testcase'` counted lines fine; the platform's real parser rejected it ("not well-formed"). Fix = an `xmlesc` awk function escaping `& < > "` at every PASS/FAIL/SKIP emit site, verified locally with `xml.etree` or `xmllint`.

---

## Pattern 48 — Compile-Time-Transform Shallow Well: engineer + MEASURE difficulty per lever (scriggo-generics, Diamond approved 2026-06; cross-architectural ★★★★; extends Pattern 17)

A pure compile-time transform over a language subset (monomorphization, desugaring, a new declaration form on an interpreter/compiler) is a SHALLOW difficulty well: an agent that "knows the language" clears the common path on the first try, because the natural implementation reuses the existing checker/emitter and the concrete result falls out for free. **Difficulty must be ENGINEERED and MEASURED per lever, never predicted.**

**Track record:** scriggo-generics shipped functions-only monomorphization first and scored ~98% Castor pass (4 eval agents 111-114/116) = too easy. The predicted erasure trap (box `T` as `interface{}`) never fired: on a register VM the natural clone-and-recheck yields concrete register kinds automatically, so the only thing under 100% was unfair error wording (a fairness bug, not difficulty). Each lever below was added and re-measured with a fresh Castor batch:
1. **Functions -> generic TYPES** (struct types): 98% -> 50%. The single biggest lever. Monomorphizing a TYPE through the type system + reflect/native bridge is genuinely hard: distinct instantiations must be distinct identities, nested resolves inner-first, field reads must carry concrete kind. For any additive compiler/interpreter pick, prefer types over functions.
2. **Position breadth**: 50% -> 40%. ~8 positions (variable, field, parameter, result, slice element, pointer base, map key, map value). Pointer-base `*Box[int]` was the highest-hit miss across the final batch.
3. **AST clone-invariant traps**: 40% -> 25-30% (band). Each statement node is an INDEPENDENT invariant a clone-and-substitute can corrupt (switch-default nil sentinel lost -> false "missing return at end of function"). One control-flow-in-body test per invariant catches a different implementation. Densest source of cheap, fair, independent traps.

**Rules:**
- Do NOT ship functions-only or a single-axis compile-time transform at Diamond. Lead with types and stack >=2 levers.
- Do NOT trust a difficulty prediction for this class. scriggo R9 predicted "recursion -> <=30%"; recursion barely moved the needle. A real Castor batch is the only oracle; budget one measurement batch per lever.
- The erasure/boxing trap is WEAK for the value path on a register VM (concreteness is free) and real only for the TYPE path via FIELD-kind assertions: the whole-struct `%T` collapses through the native-bridge proxy, so assert `b.V`'s `%T` (the field), never the whole value's. Full lever list + the native-bridge quirk: `problems/scriggo/LESSONS.md` (headline section).

---

## Pattern 49 — Failure-QA root cause must be artifact-grounded; cascade-split; re-verify UI buckets (scriggo-generics, Diamond approved 2026-06; extends Pattern 36/44/45)

The Diamond QA validator (greps named identifiers / verbatim strings -> true/mixed/false) AND the human reviewer both gate failure-qa.md. Four FALSE/MIXED triggers proven on scriggo's post-eval arc, each with the fix:

1. **Mechanism-speculation root cause = FALSE.** Asserting "the agent does not substitute X / does not handle Y" is marked false when the agent's diff actually CONTAINS X/Y handling (the bug is subtle within it). scriggo fails: "substitution does not rewrite the composite in a `:=` left-hand context" (source had it on the RIGHT; agent had assignment substitution) and "the for-range append leaves an unsubstituted node" (agent had ForRange handling). Fix: write the OBSERVABLE — verbatim error/panic + "the concrete equivalent (`b := Box[int]{V: 5}`) checks cleanly in the passing runs, so the defect is in how THIS agent specializes it." Symptom + counterfactual, not a missing-line claim the diff contradicts.
2. **Helper-chain mis-attribution = FALSE.** "`runGenericsOut` builds and runs each program" — false, it only loops and delegates; the real build/run is in `genericsOut`. Name the function that does the work (Pattern 38 sibling).
3. **Citation drift = MIXED.** Exact token (`cas.Expressions`, not `Case.Expressions`); real format string (`cannot use generic %s without instantiation`, not placeholder `X`); per-run diff match — agents differ (one touches the emitter, another uses a pre-check expand pass), so a phrase true for one run is false for another. Re-check each run's diff; never reuse a block verbatim.
4. **Cascade collapse + UI bucket swap.** A panic that inflates the JUnit fail count must be SPLIT, not one repeated paragraph over all N: one box per REAL failure (its leaf + verbatim error/panic + its parent group row, which executed), and one box for the synthetic remainder reported by the exact marker `new tests were missing from the JUnit XML (exit code 1)`. Never say "did not execute" for a test that ran; every box including the cascade box gets Root cause + Type of error. Separately, for a multi-signature run the Shipd UI annotation testName buckets get CROSSED even when the file prose is right (pointer test filed under the bare-name explanation and vice versa) — expand each UI group and confirm testNames 1:1 with their explanation; the reviewer catches the swap.

**Reviewer principle (logged, applies to every wording mismatch):** difficulty must come from real engineering, never substring grammar — error substrings exist only for fail-on-base. Contest a wording mismatch on repo convention (the diagnostic the codebase already uses, e.g. scriggo's `X redeclared in this block` + its `redeclaredInThisBlock` helper), not "the agent chose it." Give honest pass-rate numbers; do not overstate "loosening = too easy" (scriggo: broadening flipped only ~1-2 runs, ~40-50%, not a clear cross of the line). Conceding the overstatement to the reviewer is what closed the contest and got the approval.

---

## Pattern 50 — QA validator anchors on PER-RUN observables, not mechanisms; 5 proven rules (csstree-calc-typecheck, Diamond approved 2026-06-05; 3rd confirmation, extends Pattern 36/44/45/49)

Third independent failure-QA validator arc (after yaegi-channel 44, yaegi-generic 45, scriggo 49). 3 validator rounds (~10 mixed/false -> 3 -> 1 -> 0) to all-true across 11 runs (1 PASS trajectory + 50 test-failure claims). Five rules, each a proven MIXED/FALSE trigger + fix:

1. **Baseline test count = the PLATFORM junit number, not the local runner's.** csstree mocha reports 16725 locally; grading `junit_baseline_xml` reports `tests="4000"`. Every "all 16725 baseline tests pass" was MIXED. Read `junit_baseline_xml` / `test_log` "baseline_passed (N/N)" and cite that; never the local figure.
2. **Never assert a code MECHANISM that varies per agent.** "gate not routed back through matchProperty", "`<number>` is in the accepted-type set", "rejects a wrong dimension" were FALSE for the flagged runs (those agents DID route calc back / did NOT have `<number>` in the set / DID reject wrong dimensions). Anchor on the OBSERVABLE — verbatim junit Actual + the behavior shared by EVERY run in the group ("a dimensionless result is not rejected, so `calc(6/2)` matches width"; "a calc that resolves to an ERROR is not filtered before the grammar match"). The validator greps each run's own diff; a mechanism true for run A is false for run B with the same symptom.
3. **The platform's failing-test GROUPING is GIVEN in the response `testNames` arrays — align blocks to it.** 10 of 11 runs matched my symptom-blocks; only Orion_3 diverged (platform grouped clamp WITH the four gate tests, incompatible-sum ALONE). Read the testNames sets from the FIRST validator response and re-cluster; for a merged group write a both-manifestations root cause true for every bound test. (Pattern 44 confirmed — the arrays hand you the grouping directly.)
4. **Quote backticked CALLS verbatim from the test source — variable vs inline form matters.** I wrote `comparePriority(parse('@layer a, b;'), 'b', 'a')`; the test assigns `const ast = parse(...)` then calls `comparePriority(ast, 'b', 'a')` -> grep miss -> MIXED. The sibling `'a','a'` call DID use inline `parse(...)` and was fine. Copy each call exactly as written.
5. **Soften absolutes.** "a leaf operand or a missing node is the ONLY failing choice" -> MIXED ("any other node type also fails"). Write "a node that is neither, such as a leaf operand or a missing node, fails the assertion."

**Junit quirk (cite verbatim):** `assert.ok(falsy)` makes Node re-parse the source to build its message and trips csstree's `lib/__tests/helpers/setup.js` prototype-pollution guard, so the rendered junit is `Attempted to read a non-own property`, NOT `false == true`. Use that exact string as the Actual for offending-node / missing-error / instanceof misses.

---

## Pattern 51 — Measure before trapping; the 3-rollout fluke; unstated-convention -> spec not hint; reactive 2-lever hint (csstree-calc-typecheck, Diamond approved 2026-06-05; extends Pattern 48)

Four iteration-discipline lessons (cost: ~3 wasted rounds before the data corrected course):

1. **Do NOT add difficulty to an unmeasured problem.** After fixing fairness I assumed "agents solved the algorithm, only missed signatures -> too easy" and added 2 logic traps. A real 10-Castor batch then showed the artifact was ALREADY 0/10 (best run 150/156), held there by FAIR residual walls independent of the unfair signatures. Reverted both traps. **A 0/10 NEEDS_HINTS problem needs a fairness-fix + a hint on the fair walls, NEVER more traps.** Pattern 48 (measure each lever) applied to the WHOLE problem before any trap.
2. **A 3-rollout Diamond Check can fluke a 1.00.** csstree's 3-rollout preflight returned avg 0.66 with a lone 1.00 (looked solvable); the rigorous 10x returned 0/10. **Small samples lie — run >=10 before trusting "solvable."** A single high rollout in a 3-batch is noise.
3. **Difficulty from an UNSTATED convention = UNFAIR; spec it in META, don't hint it.** The fairness judge flagged the cascade API signatures / return shapes as the universal failure. Those are real public contracts -> state them in meta (AST-first signatures, `comparePriority` -1/0/1, `revertLayerTarget` returns the name). Hints HIDE the unfairness; they don't fix it. Reserve the hint for a genuinely-hard-but-fair wall.
4. **Reactive 2-lever hint design.** Read the Holistic `hint_suggestions` + ground-truth the per-run failing-tests; pick the 2 levers that flip a both-covered near-miss. csstree's hint (clamp percent-hint reconciliation + property-gate top-level-types) targeted the run whose ONLY two fails were those two walls -> flipped it to 156/156 -> 1/20 hinted, in band. Verify a near-miss run's BOTH fails are the hinted walls before committing the 10-batch; the other near-misses keep an un-hinted fail so the ceiling stays low.

**Return-shape coin-flip (watch on any introspection/resolution API):** `comparePriority` (-1/0/1 vs raw diff), `revertLayerTarget` (name string vs entry object), `cascadeOrder.layer` (name vs object) were each a 10/10 universal fail until the exact return type was stated. **Spec every return field's exact type in meta from the first draft.**

5. **The 3-rollout fluke cuts BOTH ways — a 1.00 is NOT a downgrade verdict (js-joda-parse-resolver, Diamond Checks 0.49 PASS, 2026-06-17).** A 3-rollout Diamond Check returned 1.00/1.00/1.00; the rollouts show `attempt 1/2/3`, i.e. the harness RETRIES the frontier model to green = **best-of-N**, not single-shot. A real 10-run Nova+Castor single-attempt batch on the SAME artifact showed **~44%** with all fails fair + agent-fault. The 1.00 was best-of-N inflation + 3-sample noise, NOT proof of triviality. **Get a real single-attempt batch before downgrading or abandoning; ~40% with fair agent-fault fails = HARDENABLE.** Single-point numeric/off-by-one traps are useless against best-of-N (fixed on attempt 2) — harden with INTERACTING levers (one shared chokepoint so fixing surface A regresses B), a MISDIRECTING-error trap (the failing test surfaces as a different error class so it does not reveal the fix), and a GENERAL-parameterization test (defeats hardcoded special-cases, per Pattern 48). That took the 3-rollout 1.00 -> 0.49 in one hardening round, even on a training-saturated domain (java.time). Full recipe: `lessons-learned.md` "Don't reflexively downgrade a too-easy Diamond — HARDEN with INTERACTING levers."

---

## Pattern 52 — Failure-QA literal-token grep gate; parent-rollup-Failed; per-run-actual-data; trajectory-step quality-lift (yaegi-const-representability, Diamond approved 2026-06-06; 4th validator confirmation, extends Pattern 44/45/49/50)

Fourth independent Diamond failure-QA validator arc. The submission was solvability-and-Holistic-clean and went to QA with 11 run blocks (1 PASS trajectory + 10 FAIL); ~6 validator round-trips, every one resolving the SAME root cause — a backticked token that does not appear verbatim in the artifacts. Reviewer approval: **"QAs are good, but can get more detailed with citations like trajectory steps. Acceptable."** Five proven MIXED/FALSE classes + one quality-lift, all net-new beyond the prior arcs:

1. **The backticked-token grep gate is the whole game — run it before upload.** The validator greps each backticked token literally; a zero-match token is MIXED almost regardless of how correct the surrounding prose is. Pre-submit: extract every `` `...` `` token from failure-qa.md and grep each against test.patch + the run's agent diff + repo source. One mechanical pass kills the entire 6-round attrition. This generalizes DIAMOND-PLAYBOOK rules 13-26 into a single gate (now rule 59).
2. **Comparison/threshold flip = MIXED.** `` `len(d) >= 3` `` matched nothing; the test source is `if len(d) < 3 {` (it asserts the failure guard). Cite the actual comparator; put "at least three" in prose. (Rule 60.)
3. **Substituted-arg / ellipsis-in-backtick = MIXED.** `` `errors.Is(err, ErrConstantTruncated)` `` (test uses `errors.Is(err, sentinel)`), `` `complex(...)` ``, `` `[]complex128{...}` ``, `` `n.cfgErrorf("...", ...)` ``. Quote the variable/full literal the test actually has, or drop the backticks. (Rule 61.)
4. **Fabricated call-result literal / unsupported figure = MIXED.** `` `constant.BitLen(256)` is 9 `` (no `BitLen(256)` call in any artifact), "seventeen bits" (256 needs nine). State the fact in prose; never invent a call token to carry a number. (Rule 62.)
5. **Wrong-file-hunk location = MIXED; FALSE classes specific to Go table suites.** Citing `const_diag.go line 920` for code in the `typecheck.go` `diff --git` hunk — name the function, not a wrong-file line (rule 63). And two FALSE classes (rule 64): (a) **parent-rollup conflation** — a Go table-driven PARENT fails as `<failure message="Failed"/>` with no body, so "each of N renders message X" is FALSE; count K-subtests-with-message + M-parents-as-`Failed` + special-text subtests (`As_fields` -> `not a ConstantConversionError`); (b) **stale-per-run data** — an S#11 block authored from a stale 52-test list invented a signed-nil group that did not exist and claimed "no signed-range nil failure" when there were four; rewritten to the real 57-test run. Pull each run's ACTUAL failing-test dump (count + leaf names + verbatim Actual) before writing; group count must equal total - passing.

**Quality-lift (forward bar, not a blocker):** the QA was approved WITHOUT trajectory-step citations, but the reviewer wants more evidentiary depth. This does not reverse "no step narration in the root cause" (DIAMOND-PLAYBOOK rule 2) — keep final-state root causes, but optionally add a Failure-Point-Analysis pivot from the run's trajectory ("the agent's own trace gates only the `constant.Value` path and never adds a `complex128` branch") as supporting evidence. Accepted-without-it, stronger-with-it.

**Difficulty engine (reusable, same family as Pattern 45 / yaegi-generic):** go/constant STRICT representability vs yaegi's pre-existing LOOSE checks (`representableConst` bit-width test; `assignableTo` untyped fast path). The universal Castor walls were all "tighten a permissive built-in": the folded `complex(...)` builtin yields a `complex128` not a `constant.Value` (every agent gated only the constant.Value path -> complex overflow unreported), and `ConstantReport` returns `""` for an empty diagnostic set (agents returned `"[]"`/a header). Both shipped as the hint after a fair 0/10. Confirms the interpreter-type-system seam keeps producing Diamond-grade fair walls.

## Pattern 53 — Failure-QA: observable-anchored fixes, per-run distinct construct, group-by-body; difficulty from public-boundary integration (chai-array-type, Diamond approved 2026-06-07; 5th validator confirmation, extends Pattern 50/52 + DIAMOND-PLAYBOOK rules 65-68)

Fifth Diamond failure-QA arc. Solvability + Holistic + Auto Review clean; 2/10 Castor (20%). The validator passed all claims, but the HUMAN reviewer drove two more rounds on style + a test-grouping error. Four net-new lessons beyond the token-grep gate (Pattern 52):

1. **Anchor the FIX clause to observable artifacts, NOT the hidden reference solution.** Every driver-fix sentence read "the reference calls `v.MarshalText()` and assigns `dest[i] = string(t)`." The auto-validator marked these "true" (it greps `reference_solution_patch`), but the reviewer flagged them poor: "leans on the hidden reference solution instead of staying anchored to the observable test expectations, failure output, and agent patch." Rewrite the fix from observables: the test's scan expectation + the repo's neighboring scalar arms + the description requirement ("render the bracketed text the tests scan and assign that `string` or `[]byte`, as the neighboring scalar arms convert their values"). The ROOT CAUSE already cites the agent diff; only the FIX clause was reference-leaning. Validator-true is necessary but not sufficient — the reviewer additionally gates evidentiary provenance.

2. **Per-run distinct construct; never reuse a block (UI cross-maps near-identical blocks).** Same surface bug (selected array not rendered through the `database/sql` driver) failed three ways across 10 runs: `dest[i] = v` (raw `types.ArrayValue`), local-wrapper `dest[i] = arrayValue{v: v}` (error names `driver.arrayValue`), and `dest[i] = v.Encode(nil)` (raw bytes -> scan SUCCEEDS but value mismatches: `Error: Not equal, expected "[3, 1, 2]" actual "n\x03312"`). My uniform driver block (same intro/table/root-cause) was both inaccurate AND got CROSS-MAPPED in the Shipd UI annotations — S#9's annotation picked up S#10's wrapper text, S#10's driver annotation picked up the cannot-block text — flagged MIXED/FALSE despite each block's prose being individually fine in the file. Fix: ground each run's root cause in THAT run's verbatim construct (grep its own solution-patch.patch); distinct per-run text is copy-proof. Sibling: read each run's junit Actual — a scan-error run and an equality-mismatch run are different failure MODES; do not assert "the quoted Scan error" for a `Not equal` run.

3. **Group tests by BODY assertions, not NAME.** Reviewer change request: `TestArrayTypeCrossFeatureReopenIndexLookup` was filed under "Reopen Persistence," but its body uses in-memory `arrOpen`, creates no index, and never reopens — it only checks TEXT[] equality (`WHERE tags = {'x', 'y'}`) and ORDER BY rendering. A test name can lie; read the body before assigning the behavioral group (in BOTH test-groups.md and the failure-qa Test Summary). QA-only edits like this do not stale Castor / Diamond Checks.

4. **`Encode` is the VALUE encoding, not "key-encoding."** Describing `v.Encode(nil)` bytes as "the array's key-encoding bytes" was MIXED — `EncodeAsKey` is the ordering/key form and the two differ for some element types. Name the method; do not infer a role the method does not have.

**Difficulty engine / where the wall actually was:** the feared marquee wall (byte-sortable variable-length array encoding) was FREE — genji-leftover `compareNonEmptyValues`/`SkipArray`/tags already order arrays element-wise. The real difficulty was the public-boundary INTEGRATION: agents build the internal `ArrayValue` correctly but fail to render it through the `database/sql` driver (7/10), plus the "cannot" substring on delegated overflow (3/10). Build-the-value-but-not-the-wiring is a reliable Castor blind spot — it satisfies internal unit reasoning while missing the public consumer surface. Reinforces the opus-4-8 depth law: decisive walls live in the real-codebase integration stack, not the headline algorithm. For a value-type pick: GREP the encoding comparator first (encoding may be pre-built), and put the wall at the public consumer boundary (driver/render/scan), not the storage layer.

## Pattern: LOC-rescue + signature-pinning + harness-determinism (cel-go-strict-dyn, APPROVED Diamond 2026-06-17)

Three reusable advanced patterns from this approval:

1. LOC-RESCUE under the 400 platform auto-block (Olympus/Diamond): add an ADDITIVE, fully-tested READ-ONLY aggregation/reporting API over the structured output solvers already produce (here StrictDynReport over the violations). Zero core change -> no solvability shift, pass rate held; +96 eff. Platform eff = raw - blank - //comment, braces KEPT (compute it yourself; patch_gen prints the inverse: strips braces, keeps comments).

2. SIGNATURE-PINNING beats conciseness: when a public-API method/field return type is left under-specified, competent agents SPLIT on the representation and compile-cliff a single-file hidden suite (CountBySource: (string)int vs ()map[string]int, 2/3 rollouts). PIN public-API field TYPES + method SIGNATURES in meta. FAIRNESS/SOLVABILITY OUTRANKS the Description-Quality conciseness suggestion; an ambiguous public surface is a HIDDEN REQUIREMENT (top reject). Extends the opt-in-flag pattern: an opt-in additive mode that mirrors an already-shipped flag is NOT a maintainer-philosophy violation.

3. proto.String() / non-deterministic subtest names break the platform's NAME-based p2p matching -> rename to a stable index (case_%d) in test.patch. It is a HARNESS-DETERMINISM fix, NOT an "unrelated test edit." If a reviewer/Auto Review flags it, justify with the protobuf-go detrand evidence (the empty-proto case gets stable #00 and passes; the non-empty proto-named cases flake). If Auto Review FALSE-blocks (tests the wrong justification, offers only unsafe remedies), escalate to admin with the Verify-Solution evidence + the cleaner automated check that already cleared it. Companion: lesson_proto_string_subtest_p2p_flake; full mechanism in CLAUDE.md test-naming rules.

## Pattern 54 — Diamond-too-easy → Olympus via the agent pool; the real traps are agents' own implementation bugs on documented-subtle reqs (expr-switch, ACCEPTED Olympus 2026-06-19)

A new SYNTAX feature (`switch`/match expression, O-Composite-add, 5 packages), too easy for Diamond (Castor best-of-N 0.69), shipped as Olympus at 1/10 Nova (10%). Reusable patterns:

1. **Tier-pivot on the SOLVER pool, not the review bar.** Diamond Checks = Castor (strongest, best-of-N retry); Olympus = Nova/Orion/Vega (weaker, single-attempt). Identical artifact: Castor 0.69 -> Nova 0-10%. A genuinely cross-subsystem + fair feature that Castor finds too easy is an Olympus candidate; re-tier and run the weaker pool BEFORE rebuilding traps. The band is razor-thin (a 2-test change moved Nova 0%->10%).

2. **The designed semantic traps are NOT the biters — the agents' own implementation bugs on documented-SUBTLE requirements are.** subject-once, stack-discipline, no-match-error all got solved. The walls that held: over-aggressive constant fold (fold a constant-DISCRIMINANT construct past its NONCONSTANT arms -> wrong default; ~7/10, misdirecting because the failing assertion is a runtime value while the bug is in the optimizer) and accumulator-scope boundary (per-element seen-set on a per-group uniqueness rule; ~6/10, interdependent). Design FAIR-but-HARD = a documented requirement with a NON-OBVIOUS correct implementation where the natural code is subtly wrong, NOT a hidden requirement.

3. **Optimizer-AST-inspection tests are implementation-specific = unfair; test the requirement observably.** Asserting the optimized AST lost its node type over-constrains HOW the agent satisfies "settled while compiling" (bytecode-fold also satisfies it). The observable value test is fair and still catches the over-fold bug.

4. **0% on a weak single-attempt pool with all-fair fails = TOO MANY independent fiddly requirements**, not one hard wall. The fix is to CUT the 1-2 most-missed/least-fair requirements (lift toward the band) — the inverse of the usual "add a trap."

5. **Scope collision/uniqueness rules to the construct form** (subject vs subjectless) explicitly, or a reasonable broader reading earns an agent_blame_unfair flag. See PROBLEM-PROFILES expr-switch + KNOWLEDGE expr-switch blind spots + lessons-learned "Diamond-too-easy -> Olympus pivot via the AGENT POOL."

## Pattern 55 - Grader applies the test patch over the agent's MUTATED tree, and runs plain `go test` with no custom flags (yaegi-methodset-enforcement, APPROVED Diamond 2026-06-23)

Two platform-mechanics gates that block PASS before any difficulty question. Both bit during the to-approval arc; both are env-correctness, not solvability.

1. **Additive-only test patch.** The grader does NOT restore test files to base before applying your test patch — it applies the patch over the tree the AGENT mutated. If your test patch MODIFIES an existing repo test file, the agent's own edits to that file make `git apply patch.diff` fail (`patch does not apply` at the file, "failed to create QA version", Diamond Checks crash). RULE: every new test goes in a NEW file with a random hex suffix; never edit an existing test file in test.patch. Corollary: if your feature would flip an existing repo test's expectation, re-scope the SOLUTION to PRESERVE that documented behavior (yaegi kept #1149/#1150 ptr-method-on-composite-literal legal via a shared `isCompositeLit` carve-out and asserted the legality additively) rather than changing the existing test.

2. **No build tag for f2p isolation.** The grader invokes the suite with plain `go test` and does not pass your custom `-tags`. A build tag intended to gate the f2p file means that file is never compiled in the grader's base AND new runs, so the f2p set "passes" on base -> Env Linter BLOCKING for inverted reward ("f2p N/M-pass"). RULE: no build tag; isolate the base regression run by PREFIX MISMATCH (the curated base test list does not match `^Test<Name><hex>`) plus a BASE_RUN variable, and select the new run with `-run ^Test<Name><hex>`. Supersedes "isolate via build tag" (reference_go_testsh_skip_flag corrected same cycle). The banned-marker hex suffix requirement already forces unpredictable names; reuse that prefix for the `-run` selector.

3. **Human Describe-Tests + success-QA pass after the validator is green.** The auto-grader marked all 12 runs "true"; a human reviewer still caught 4 factual errors: group/describe each test by its BODY not its name/theme, and a PASS run (36/36) can be spec-wrong on an UNTESTED corner (`([4]int{...})[1:3]`) -> success-QA must say "tests pass but impl wrong", lower confidence, issue-type Correctness. Budget a human review round even when the validator passes (extends Pattern 50/53).

## Pattern 56 - Representation-Split Trap + Diamond QA 3-round discipline (typify-object-applicators, APPROVED Diamond 2026-06-25)

TRAP: in a subsystem that lowers one concept into two co-equal representations (codegen struct vs map/newtype, AST-vs-tokens, value-vs-reference), require a new behavior in BOTH and add a degenerate edge only the second hits. Interdependent (shared lowering path -> single-representation fix fails the other's tests) + misdirecting (the second representation fails as a panic/assert that reads like a different bug class). Confirmed 10/10 Castor miss; two near-misses at 20/22 failed ONLY the second-representation generation. A scope-level hint ("works as repr A OR repr B; both must honor the keyword, incl the root edge") flips near-misses without naming the fix, and leaving the genuinely-hard sub-trap unhinted caps the ceiling.

QA SUB-DISCIPLINE (Diamond failure-qa): budget 3 rounds. Validator (greps named ids, true/MIXED/false) passes interpretive fairness + type-of-error reliably; recurring MIXED = assertion-location, pipeline-timing, ungreppable CONSTRUCTED tokens (cite repo-exact form), per-run-code-differs, grouping-binding, per-agent-helper (don't cite a helper an agent's diff lacks). Then a human reviewer catches plausible-but-wrong mechanism, reference-writeup naming nonexistent functions, success-block selling an over-accepting fallback as a feature, false asymmetry, imprecise counts. See `diamond-problems/approved/typify-object-applicators/failure-qa.md` for the worked artifact.

## Pattern 57 — Long-horizon-thoroughness trap via baseline-golden breakage (saturated feature rescue)

Source: starlark-rust-set-literals (APPROVED Mars 2026-06-25, 1/13 = 8% Hard).

When a feature is SATURATED (pure sugar; frontier agents implement it trivially and pass every behavioral test -> no feature-level pass-rate lever), you can still land an in-band Mars by sourcing the difficulty from LONG-HORIZON THOROUGHNESS rather than the feature:

1. Pick a cross-subsystem syntax/opcode change that NECESSARILY breaks fair EXISTING baselines -- e.g. an obsoleted negative test (a parse-fail case the new syntax makes valid) and a generated snapshot golden (the bytecode opcode-profile, which any new opcode mechanically changes).
2. The trap is "did the agent run the full suite and fix what its change broke." 90-100% of agents run only focused new tests and leave the baselines red -> fail. The thorough agent passes. ~8% band.

Two hard mechanics this pattern depends on:
- PLATFORM: the regression-after-solution run applies solution.patch to a CLEAN base and IGNORES test.patch edits to EXISTING files. So the existing-test/golden fixup the REFERENCE solution needs MUST go in solution.patch (test.patch edits to existing files are not honored for the baseline gate). Existing-golden updates in solution.patch are expected for any syntax/opcode change.
- MARS LONG-HORIZON GATE is file-count + message-count (sustained multi-file work), NOT raw LOC volume. A ~230-eff feature spanning 22-25 files (exhaustive enum-variant fan-out) clears it. Do not apply Olympus LOC-volume intuition.

Limits: the difficulty is SHALLOW (process thoroughness, not an interdependent+misdirecting algorithmic trap). It is fair and shippable at Mars (no hints; thoroughness-as-difficulty is acceptable, and the failure output names the broken baselines). It does NOT scale to Diamond -- a saturated sugar feature at sub-450 eff with no feature-level trap will be flagged by Diamond review as weak. Use this only as a Mars rescue when a pick turns out saturated; prefer a real feature-level trap (depth-law domain) when one exists.

## Pattern 58 - Platform checks can contradict: reframe the spec, do not implement the rejected behavior

Source: cel-go-cost-coverage (APPROVED Mars 2026-06-24, ~25% over a 13-run batch).

The platform's AI checks are independent and can DEMAND OPPOSITE things about the same behavior across rounds. Pinging the code between them burns rounds and ships a worse artifact. The fix is to find the principled, library-consistent behavior, ALIGN the meta.md spec to it, and flag the human reviewer, not to keep implementing whichever check spoke last.

**The 3-way rejection (one behavior, three contradictory verdicts):** charging the short-circuit `or`/`orValue` operators at RUNTIME was rejected three different ways:
1. **Test-Fairness:** ruled the runtime charge UNFAIR ("a reasonable impl could tie them").
2. **An earlier round:** called the unconditional `InterpretableCall` an OPT-IN LEAK (base call-cost charged even without the opt-in option set).
3. **A later Solution-Quality FAIL:** demanded the OPPOSITE -- you must charge EVERY optional construct at runtime.

**Resolution rule:** when two checks genuinely contradict, do NOT obey the most recent one. Find the behavior the host library itself follows and make THAT the spec. Basis here: CEL does not charge its own `||`/`&&` short-circuit operators per node, so requiring or/orValue to be charged at runtime is over-prescriptive. Final meta aligned to it: "Because or and orValue short-circuit, they are not charged as separate runtime calls; the static estimate stays a sound upper bound." The STATIC side still charges or/orValue (union of branch sizes, tested); the contradiction was only about the RUNTIME charge. Then flag the reviewer that two checks disagreed and you held the library-consistent reframe. General test: when an SQ "incomplete" flag fires on behavior the code performs CORRECTLY, the bug is in the meta wording (it promised more than the correct code does), not the code -- fix the meta.

**Companion note -- STALE-CHECK cross-validation (do not fix a ghost).** A Solution-Quality FAIL cited `TestOptionalCostOrValueChargedAtRuntime` as "still failing" after it had been DELETED the prior round; SQ was running on a cached merged report. Cross-checked against the SAME-RUN Test-Fairness output, which enumerates the LIVE test set (deleted test absent, new test present) -> confirmed stale, a fresh re-run cleared it. RULE: when any check cites a test/symbol you removed, cross-validate against another fresh check that enumerates the live set (Verify Tests / Test Fairness) BEFORE re-fixing -- re-fixing a ghost reintroduces the very thing you cut.

**Companion note -- drop the ambiguous inspection surface (don't specify it).** The same submission's R1 looked 40% pass but an undocumented report-API's Go method signatures compile-failed 5/6 runs -> ~90% fair-pass underneath (planck unfair-trivia pattern). An inspection/report API over an already-computed value is pure glue: 0 difficulty + 100% of any signature-ambiguity unfairness. DROP it; source the real difficulty from the static<->runtime soundness invariant instead (see olympus-extreme-complexity-guide + SHAPES.md cost-coverage shape note).

---

## Pattern 59 — Nested-crate, external-toolchain repo: three platform gates need Dockerfile + test.sh surgery, NOT patch changes (quint-temporal-eval, Olympus approved 2026-06-15)

The target crate is NESTED (`/app/evaluator`, no repository-root `Cargo.toml`) and the repo's existing integration tests SHELL OUT to a TypeScript `quint` binary absent in the offline sandbox. Three separate platform gates fire on this shape; all three are fixed in the Dockerfile / test.sh (build + harness), never in solution.patch / test.patch:

1. **Environment Quality FAIL** — the checker runs plain `cargo build` + `cargo test` at `/app`. Two failures: `/app` has no `Cargo.toml` (crate is nested), and `cargo test` (whole crate) fails because the toolchain-dependent tests shell out to the missing binary. Fix (pomsky-style strip + workspace shim): in the Dockerfile, `rm` the toolchain-dependent test files (`evaluation_tests.rs`/`simulator_tests.rs`/etc.) and `printf '[workspace]\nmembers = ["evaluator"]\nresolver = "2"\n' > Cargo.toml` + `cp evaluator/Cargo.lock Cargo.lock`. Then `cargo build`/`cargo test` at `/app` are green offline. The removed tests are NOT in the platform's p2p set (p2p here = only the offline-runnable lib + fixture-loading tests), so stripping them costs zero tracked coverage. Confirm the real p2p set from a Verify-Solution run before deciding what `base` must cover.

2. **Dockerfile FAIL — no `cargo test` during build, even `cargo test --no-run`.** The rubric forbids ANY `cargo test` invocation in the build step. Use `cargo build --workspace --tests` to pre-compile test binaries for cache (also satisfies the "prefer workspace build" warning). Never pre-build the NEW test target (injected post-build, references missing API -> would break the base-context build); scope the pre-build to targets that compile in both base and new contexts.

3. **Verify Solution FAIL `before_extras_not_skipped`** — the Rust build-failure JUnit fallback must emit the EXPECTED test names, not a generic `<testcase name="compilation">`. The platform matches every emitted testcase to its p2p/f2p set; a `compilation` placeholder matches neither -> "extra (failed)". On new-mode compile failure (base, no solution), extract the `#[test]` fn names from the test file and emit each as FAILING so the f2p names match: `awk '/#\[test\]/{want=1;next} want&&/fn /{s=$0;sub(/.*fn /,"",s);sub(/\(.*/,"",s);print s;want=0}' "$file"`. Keep the generic `compilation` block only as the last-resort fallback when no test-name source is available.

**Authoring corollary — verify operator signatures against the repo's OWN definitions, not the design sketch.** Read the repo's real definitions + probe-compile small specs and dump the IR before locking the spec; empirical operator shapes are more faithful than any design doc, and a reviewer reading the repo will reject a sketch that contradicts them. Reviewer note: name the crate-root export path for new types the tests import ("re-exported from the crate root"), and when an AI conciseness checker says to drop the new type/variant names, REFUSE — the tests import them, so removing them is a 0% compile-collapse, not a trim.

## Pattern 60 — Obvious-design-works-but-a-repo-specific-path-silently-breaks-it (the durable Olympus correctness trap) (glaredb-ordered-aggregates, Olympus approved 2026-06-27)

The highest-yield, retry-resistant Olympus trap is a feature where the INTUITIVE implementation is correct for the easy cases and a real, non-obvious repo internal silently breaks the hard case. Agents converge on the obvious design, pass the easy tests, and ship — the hard case fails with output that points AWAY from the cause.

Worked example: aggregate-local `ORDER BY`. Obvious design = insert a global sort before the aggregate. It passes `string_agg(x ORDER BY y)` and the grouped case. It SILENTLY fails `string_agg(DISTINCT x ORDER BY x)` because glaredb's DISTINCT path collects inputs into a HASH TABLE and scans them in hash order, destroying the sort. The failing test shows `c,a,b` vs `a,b,c` -> reads as "sort broken" (misdirecting), not "the distinct table re-ordered." Correct fix = dedup-after-sort inside the aggregate state + operator `is_distinct=false`. This one trap sank 3-5 of 12 agents on its own and survived retries (it forces re-architecture, not a point-fix).

How to FIND one at pick time:
- The feature has an OBVIOUS pipeline design that is correct for the linear/simple case.
- The repo has a DISTINCT execution path (hash-distinct, partitioned merge, a separate optimized branch, a cached/short-circuit path) that the obvious design routes through and that does not preserve the property the feature needs (order, identity, multiplicity).
- The breakage is OBSERVABLE but MISDIRECTING (wrong order/value, not a crash naming the cause).
Verify it EXISTS by building the obvious design and running the hard case before committing (build-measure / reproduce-trap).

Two companion sub-patterns from the same submission:
- **Repo's existing strict invariant = free trap.** A new clause implemented by a uniform rewrite of aggregate inputs (CASE-wrap every arg for FILTER) collides with a pre-existing rule ("STRING_AGG 2nd arg must be constant"). No extra spec; the repo's own rule does the work.
- **Broaden for the LOC bar with EASY siblings, band-safe.** Adding arg_min/arg_max to clear a "near the size bar" reviewer note moved the rate only 10% -> 16.7% (still <=20%) because the gating trap is independent of the easy surface. Put easy new tests at the END of the file so failing runs (stop at first earlier failure) keep their failure point.
- **Introduced defaults must match the repo's analogous default** (NULLS placement = glaredb regular ORDER BY `None => desc`); a divergent default is a latent bug reviewers probe.

## Pattern 61 — Uncorrelated state-isolation wall / CONTRACT-STATED, FIX-HIDDEN (the best single-subsystem Mars class) (participle-longest-match, Mars 1/12=8.3% all-fair, auto-approved 2026-07-01)

The escape from the ironcalc/kysely/petgraph "fair single-subsystem features are always too-easy" law. Those die because stating the requirement hands the agent the fix. The exception, and the strongest single-subsystem Mars found: **a feature whose correctness requires a speculative STATE-ISOLATION decision that (a) sits OFF the feature's implementation path and (b) has a FIX that is a repo-internals discovery distinct from the stated REQUIREMENT.** You can then state the contract fully-fair and it still does not reveal the mechanism.

Worked example: greedy `||` longest-match alternation in participle. The FEATURE (try all alternatives, pick the one consuming the most tokens, ties to earliest, report the furthest error) is pure transcription — all 12 agents got it. The WALL: a rejected alternative that captures directly into the shared `parent` struct then fails partway must leave no trace. participle's `ctx.Branch()` isolates the lexer cursor and the deferred `apply` list but NOT direct reflect writes to the shared `parent reflect.Value` (done by `strct.Parse`'s best-effort `Apply()` on error). The fix is `snap := copy(parent); ...; parent.Set(snap)` per attempt. 11/12 agents branched the lexer, picked the longest, accepted the winner, and never snapshotted `parent`. The meta states the requirement in full ("captures from a rejected alternative must not appear; leaves no trace even when it captures then fails partway") and it does NOT leak the fix, because the fix is "which state does Branch() actually isolate" — a framework-internals fact. 8.3% pass, every fail flagged fair.

How to FIND / VERIFY one:
- **Uncorrelated-wall test (pick time):** "Can an agent implement the FEATURE 100% correctly and STILL fail the trap?" YES -> uncorrelated -> hard (the wall is a separate decision). NO -> the hard part IS the feature -> correlated -> collapses to too-easy (this is exactly why participle-precedence failed: its synthesized-node injection WAS the feature).
- **Contract-stated / fix-hidden test:** can you state the observable requirement fully without the statement implying the mechanism? If stating it = giving the fix (ironcalc displacement rule) -> dead. If the fix is a distinct repo-internals discovery (which state a primitive isolates, a hash path's ordering, a cache's staleness) -> keep.
- **Build-measure forecast:** implement the IDIOMATIC solve and run the trap. If the idiomatic solve provably fails on the repo-internals gap, the batch will too (here it forecast 11/12 exactly). Framework primitives that isolate SOME state but not all (cursor yes, destination-object no) are the reliable source.
- **Trap-shape = the shape agents self-test AROUND.** Agents proactively write their own edge test but under-sample the shape space (they tested nested-pointer leaks, missed direct-scalar-into-parent-before-partway-failure). Choose the shape adjacent to the one they will self-generate, so their own test gives false confidence.

Note: pass rate here was Olympus-grade (8.3%) but scope/LOC (113 eff, single-subsystem) fixes the tier at Mars. A low pass rate does not upgrade the tier; scope does.

---

## Pattern 62 — Canonical-Type Narrow-Guard (delegate-through-the-predicate; put the sibling type only in tests) (symengine-imageset, Mars 1/10=10% ALL-FAIR, 2026-07-02)

**Measured 9/10 Nova miss, single load-bearing wall.** When a feature branches on a family of types where ONE member is the canonical/dominant instance (Integers among {Integers, Naturals, Naturals0}; the base class among its subclasses; the common case among the enum), agents special-case the branch on the dominant type via `is_a<Canonical>(x)` and FORGET the co-equal siblings that also satisfy the real predicate. Here agents gated ImageSet interval-enumeration on `is_a<Integers>(*base)`, so `{2n : n in Naturals} ∩ [-4,4]` never enumerated -> failed `{2,4}`. The one passer filtered each candidate through `base->contains(index)` (the general predicate).

**Why it is FAIR + hard (both):**
- The spec states the DELEGATION, never the type list: "ask the base set whether it contains that index" / "belongs to the base set". That is the fair contract. It does NOT name Naturals/Naturals0 -> stating the sibling types would give the fix away (Pattern 20 / the ironcalc law).
- INTERDEPENDENT: the same delegation is mandated in TWO code paths (membership `contains` AND enumeration). Agents implement it in the obvious path (contains) and hardcode the dominant type in the second (enumeration). The inconsistency is the bug.
- MISDIRECTING: "integer-indexed" / "the integer case" reads to the agent as "== the canonical type." The failing test ("restricts indices to the base") points at base handling, but the agent believes they already handled "the integer case."

**Design recipe:**
1. Feature dispatches on a type family with one dominant member.
2. Spec states the DELEGATION-through-the-predicate once, for the OBVIOUS operation only (membership). Never enumerate the sibling types.
3. Hidden test exercises a SIBLING type (Naturals/Naturals0) in the SECOND operation (enumeration/intersection), where agents forget to re-apply the delegation.
4. Reference filters every candidate through the predicate (`base->contains`), consistently across both paths.

**Tighten-first companion lesson (this problem's R2 disaster):** the OPPOSITE mistake killed an earlier round. R1 gated 50% on a reverse-dispatch coverage trap; R2 "hardening" ADDED a meta sentence naming the seam ("make sure both operand orderings evaluate") + a larger description -> **100% pass**. Naming the implementation seam in the description hands agents the fix; a larger description compresses the capability gap (weak agents coast). R3 tightened meta 375->217 words, removed every seam-hint, moved all traps into TEST DESIGN -> 10%. LAW: harden by TIGHTENING the description and moving traps into tests, NEVER by describing the mechanism. Of 7 stacked R3 traps, only the narrow-guard carried the difficulty; the rest were coverage/robustness. One genuine wall the agent reliably misses = the difficulty (Pattern 61 / piccolo law).

## Pattern 63 — Hint-Arc-Against-Shifting-Wall + the Dual-AST compile-floor (nickel-1336, Olympus 1/10=10% ALL-FAIR, SOLVED 2026-07-03)

**Two reusable patterns from a cross-crate Rust Olympus that went 0/14 -> 1/10 across four hinted batches.**

**(A) HINT-ARC-AGAINST-SHIFTING-WALL -- the standard recovery for a FAIR problem stuck 0-pass (NEEDS_HINTS).** A multi-wall feature fails 0-pass because SEVERAL walls kill in parallel; the batch's failure distribution shows you which wall is DOMINANT. Add ONE hint for that wall, re-run: the fixed wall clears and the NEXT-most-common failure surfaces. Repeat until a pass. Here the dominant failure moved every batch -- unhinted (parser+propagation+materialize together) -> [+template-not-field] parser-ambiguity became 10/14 -> [+parser-steer +propagation] 2 runs hit 26/26-NEW, baseline-regression became the sole blocker -> [+baseline-preserve] PASS. Rules: (1) hint the batch's TOP wall, not your favorite; do not hold your biggest lever (holding the parser hint one batch wasted a full 0-batch -- the parser wall was always largest). (2) Do NOT front-load all hints in one shot -- over-hinting risks a too-easy reject; add the minimum per batch. (3) STOP when a pass lands; further hints only lower difficulty.

**(B) BEHAVIORAL-HINT rewrite -- fair AND still effective.** The description-conciseness reviewer HARD-FAILs mechanism-flavored hints as over-specification and hands you the behavioral rewrite: "the catch-all is retained on the record and re-applied" -> "fields introduced later are still governed by the catch-all"; "its annotations belong to the `{ _ | ... }` contract syntax, not to record-field syntax" -> "the metadata after `_ |` is part of the catch-all annotation"; "drops out rather than remaining as an empty entry or raising a missing-field error" -> "is omitted from the record". The behavioral form conveys the SAME nudge (observable requirement) minus the HOW, is fair, and the winning batch passed on it. LAW: author every hint as an observable-behavior sentence from the start -> same solvability lift, no description FAIL. A hint that survives the conciseness reviewer == a hint stating an observable requirement == what fairness wants.

**(C) The DUAL-AST compile-floor (why this pick was hard for the RIGHT reasons -- a design lever, not just this problem).** A cross-crate feature whose new surface syntax (i) OVERLAPS an existing grammar production (`_` in the TYPE grammar; naive metadata parsing collides -> LALRPOP local ambiguity) and (ii) must thread a payload through BOTH a surface AST and a core AST + LALRPOP-generated code (`&T`-vs-owned E0308) + ~15 match/initializer sites (add a field to a shared struct -> miss an initializer E0063; unresolved import E0432/E0433; container missing a trait method E0599) stacks a COMPILE/INTEGRATION wall UNDERNEATH the semantic walls. Fast agents (Nova) die at compile before reaching semantics; only the heavy agent (Orion) carries the full build. Combine with a SHARED-STRUCT-REPRESENTATION-LEAK (new state on a struct many legacy paths observe -> baseline regression that survives after the feature is 100% done) and you have a natural 4-orthogonal-wall Olympus (compile / propagate / materialize / regression) that lands ~10% with zero misdirecting-trap gimmick -- each wall catches a different agent (piccolo "5+ orthogonal walls" law, confirmed at Olympus on a cross-subsystem feature).

## Pattern 64 — Harden a too-easy single-arm relation-extension with a SECOND orthogonal arm + the tier-gate law (nickel-enum-widening, Mars 30% APPROVED 2026-07-04)

**Three reusable patterns from a single-subsystem typecheck feature hardened 0/10 -> ~44% -> 30% and shipped Mars.**

**(A) SECOND-ARM HARDENING — the pass-rate lever for a compact relation-extension.** When a feature EXTENDS an existing relation (subtyping/subsumption, unification, coercion, a visitor) by adding a MISSING constructor arm, the reference is a mirror of an existing arm -> passers just write it -> ~40-50% too-easy, and ADDITIVE positive tests only raise avg-pass-fraction (Pattern 17). The lever is a SECOND, orthogonal arm (here enum WIDTH + FUNCTION variance) that reference-only solvers never write. Strongest when the new arm COMPOSES with the subsystem's existing NEGATIVE goldens: the arrow arm's contravariant domain made 2/10 over-generalize and flip an existing "should stay error" golden (`mismatch_enum_match_fun_type`) to `pass` when it still correctly errors -- a self-loading trap you get for free, no authored misdirection. LAW: to lower pass rate you must require behavior BEYOND the minimal reference; a co-equal orthogonal axis does it, more tests do not.

**(B) FORCE-DIAGNOSTIC-DIRECTION as a hidden f2p test.** For a behavior-changing typecheck feature, find a program base and the solution BOTH reject but with DIFFERENT error KINDS (base MissingRow(blo), solution ExtraRow(bli) on a two-match pin). Assert the solution's substring ("extra row") in a hidden test: it is f2p (base's substring differs), and it catches BOTH wrong-direction impls AND over-permissive impls (which produce a value, no error) that the visible golden alone misses. Document the direction in meta ("reported as an extra row") to stay fair. Companion: a behavior-CHANGE that flips an existing type-error golden + an executable doc-snippet is FAIR difficulty only when the meta says "validate the full existing suite" (Holistic ruled fair on exactly that sentence).

**(C) TIER-GATE LAW — the platform's auto Difficulty + Long-horizon gates key off the SELECTED tier, not the content.** A 146-eff-LOC feature landed 30% (3/10) with Holistic + Auto Review both PASS, yet `agentDifficulty(30%)` + `agentLongHorizon` FAILED because it defaulted to Olympus judging (<=20% + long-horizon). Selecting MARS clears both (Mars cap <=30%; long-horizon is Olympus-only). A small feature at 30%+holistic-PASS is a clean Mars; the Olympus long-horizon bar is STRUCTURALLY unmeetable for a compact single-subsystem feature -- pick the tier the feature's SIZE supports, do not bloat to chase it. Also: EMPIRICALLY verify any claimed dual-path/second-subsystem wall before promising a tier (here the brief's "runtime unenforced" wall was FAKE -- the runtime contract already blames on base -> typecheck-only -> Mars).

## Pattern 65 — Un-bimodal a single-subsystem correctness feature by stacking ORTHOGONAL sub-behavior walls (the kysely/petgraph cap EXCEPTION) (piccolo-finalizers-gc, APPROVED Mars 2026-07-04, 30% 3/10 all-fair)

**Context.** A well-specified single-subsystem CORRECTNESS feature (here the Lua 5.4 GC/finalization subsystem: weak `__mode` k/v/kv + ephemeron fixpoint + `collectgarbage` option set + `__gc` resurrection/reverse-order/once-each) often lands BIMODAL: agents either understand the core mechanism (correct two-stage finalize) and pass ~everything, or they don't and fail a cluster -- a ~50% pass rate that resists hardening. Two prior picks in this class (kysely predicate-injection, petgraph membership-validation) were SHELVED as uniform-wrap-capped. This one shipped. The difference is the pattern.

**(A) THE EXCEPTION TO "single-subsystem = uniform-wrap-capped."** A uniform-wrap is ONE concept applied at N sites (one `node_identifiers().any()` guard, one predicate-injection transform) -> mastering the concept clears all N -> intrinsically ~100% or bimodal, un-hardenable. But some single subsystems contain 5+ GENUINELY-ORTHOGONAL sub-behaviors that fail INDEPENDENTLY. GC qualifies: ephemeron marking, finalizer-ordering bookkeeping, argument-consumption plumbing, weak-mode distinction, and once-each cleanup are separate code paths. DIAGNOSTIC at pick/harden time: enumerate the subsystem's independent sub-behaviors; **5+ orthogonal => hardenable to the cap by stacking a fair wall on each; <3 => a true uniform-wrap that will stay too-easy.**

**(B) THE LEVER: spread tests across ALL orthogonal axes, do NOT deepen the one everything concentrates on.** R5/R6 added tests only on the resurrection x ephemeron axis and stayed 53% (deepening a bimodal axis moves nothing -- the agents who pass it pass all of it; cf. Pattern 17). R7 added/activated tests on 4 OTHER axes and hit 30%. The five working walls, with the fraction of the fail-batch each caught: (A) resurrection re-feed not propagated to the ephemeron fixpoint [5/7; misdirects as a `gc_arena header.is_live()` panic; ship BOTH a shallow `..._two_level` and a DEEP `..._deep_chain` variant -- they catch no-refeed vs BOUNDED-refeed, two sub-classes], (B) `collectgarbage` multi-arg consume [`Stack::consume` drains the whole stack -> 2nd consume empty -> wrong setpause/setstepmul previous; repo-API footgun, orthogonal to domain logic, 3/7], (C) once-each across resurrect-then-redrop [re-resurrects a finalized-dropped object -> weak entry wrongly persists; 1/7 SOLELY], (D) reverse-install-order [vector pop loses order], (E) kv treated as ephemeron [dead weak value survives via live key]. Math: bimodal one-wall ~= 50%; five independent walls each missed by ~15-30% of would-be-passers compound to ~30%. No single agent has all five blind spots.

**(C) DIFFICULTY = TEST COVERAGE, NOT SOLUTION.** The reference solution was BYTE-IDENTICAL across all three hardening rounds; every round only ADDED fair tests (each traces to a meta sentence, each f2p, each deterministic, each verified to pass the reference before wiring). Strongest fair misdirection in the set = a correctness bug that surfaces as a library-internal PANIC (`header.is_live()`), naming the wrong file. CAVEAT: 30% is the Mars MAXIMUM -- landing exactly at the cap risks a variance-y future batch tipping over; prefer 15-25% when the orthogonal walls allow. Cross-refs: KNOWLEDGE (Nova GC blind spots), PLAYBOOK, SHAPES (single-subsystem-with-orthogonal-walls note), lessons-learned. Contrast: [[project_kysely_row_level_scope]] + [[project_petgraph_node_validation]] (true uniform-wraps, correctly shelved).

## Pattern 66 -- The Cross-Section Refactor Wall (harden a faithful-convert feature) (gimli-type-units, APPROVED Mars 2026-07-05)

**When:** a single-subsystem feature is a faithful read->write->read CONVERT (or any transform where the READER/spec is the oracle the agent can mirror). New-behavior walls (offset math, canonical ordering, form-disambiguation, base-address resolution) do NOT harden it -- competent compiling agents copy the reader's logic for free. Proven on gimli-type-units: 3 batches of stacked new-behavior walls landed ~100/47/70% pass.

**The wall:** make the writer emit to a NEW output section, chosen by a version/kind discriminant, such that supporting it forces generalizing a SHARED, concretely-typed helper that every unit/element flows through. gimli: v4 type units belong in `.debug_types` (v5 in `.debug_info`), so the reference must (a) add a `DebugTypes<W>` write section, (b) generalize the DIE-writer `entry.write`/`AttributeValue::write` from `&mut DebugInfo<W>` to raw `&mut W` (offset becomes `DebugInfoOffset(w.len())`), (c) route by version in the unit writer, (d) extend convert to iterate the second section (`read_dwarf.type_units()`). Because the generalized helper is load-bearing for ALL units, a wrong refactor fails to compile or regresses the whole baseline.

**Why it bites (interdependent + misdirecting by construction):** the refactor touches every unit at once (interdependent -- can't half-do it), and the failure surfaces as a compile error / baseline regression far from the type-unit logic (misdirecting). 14/20 Nova runs could not compile the generalization: stray `w.0`/`w.offset()` on generic `W` (E0609/E0599), incompatible `if`/`match` section-branch types (E0308), dropped `Section`/`Deref` trait imports the `define_section!` macro needs (E0405), sibling-field borrow conflict (E0502), unannotated dedup-collection inference (E0282). Result: 5-15% pass, all-fair, ACCEPTED.

**Design rules:**
- Keep the reference generalization MINIMAL (gimli: 2 signatures + ~5 offset sites). The wall is that agents can't find the clean version -- the median PASSING agent wrote 2.5x the LOC. A verbose reference leaks the shape.
- Exploit self-contained-ness to stay solvable: gimli type units reference each other by SIGNATURE (no cross-unit offset fixups) + intra-unit refs are unit-relative (section-agnostic), so a type unit's bytes drop into `.debug_types` with the same machinery. Pick a routing where the moved element needs NO new cross-section reference plumbing (else 0% risk).
- Difficulty != volume. This wall is 249 eff LOC = MARS, not Olympus. Measure the CLEAN reference before promising a tier; NEVER pad to the 450 floor (see the LOC-vs-difficulty note in lessons-learned).
- Pre-submit hygiene (human reverts on these even when auto-review passes): run the repo's OWN CI gate (`cargo fmt --all -- --check`), and make `test.sh` base run the `tests/` integration target that exercises the refactored shared path (`--lib --test <name>`), not just `--lib`. Optionally `--no-fail-fast` so both base binaries always report.

## Pattern 67 -- A negative case rejected on BOTH base and solution is NOT fairly f2p-testable: drop it from the description (nickel-array-rest, APPROVED Mars 2026-07-05)

**The trap.** When your feature adds new VALID syntax, there is usually an adjacent INVALID form that both the old and new code reject -- for nickel non-trailing rest, that is a second rest (`[.., a, ..]` / `[a, ..m, ..n]`): base rejects it as a PARSE error, the solution rejects it as a VALIDATION error. It is tempting to describe it ("an array pattern may contain at most one rest, a second `..` is rejected") and test it. Both are mistakes, and they set off a checker loop.

**Why the test is unfair AND un-f2p-able.** The case is rejected identically from a black-box view (both error), so it is NOT a behavioral change. Any test either (a) asserts only "an error is raised" -> passes on base -> not fail-on-base -> a useless test, or (b) asserts the solution's error message substring -> but that message is a BRAND-NEW error class with no repo precedent, so the fairness checker greps the repo for the substring, finds zero hits, and flags it unfair (Test Fairness FAIL). Contrast the FAIR duplicate-binding tests, which assert `duplicated binding` -- that phrase already exists in the repo (`core/src/error/mod.rs` + a snapshot), so a solver can discover it. The reviewer's instinct ("mirror the duplicated-binding tests") does not transfer: the mirror breaks precisely because the model wording is discoverable and yours is not.

**Why keeping it in the description keeps drawing flags.** Remove the unfair test and an Alignment/coverage reviewer immediately flags the described-but-untested requirement and asks for the test back -- an impossible loop, because no fair test exists.

**The fix.** DROP the requirement from the description. Describe only OBSERVABLE FEATURE behavior; a pre-existing invalid-syntax constraint (the old grammar also could not hold two rests) is an implementation detail, not a stated requirement. KEEP the internal validation in the solution (nickel: `MultipleRestPatterns`, necessary so a second rest does not silently overwrite `rest_index` and mis-parse) -- it is reachable + rendered, not dead code, just now undescribed + untested. Undescribed defensive validation is normal in real code; described-untested is what reviewers flag.

**General rule.** When a HARD gate (Test Fairness) forbids the test a SOFT gate (Alignment/coverage) demands, and the behavior is genuinely not fairly f2p-testable, resolve by removing the requirement from the spec -- do NOT add an unfair test, and do NOT accept endless advisory friction by leaving a described-untested requirement. Pre-empt at authoring time: for every negative/rejection sentence you write, ask "does BASE already reject this, and is my error wording in the repo?" If base rejects it too and the wording is novel, it does not belong in the description.

## Pattern 68 -- Deepen the core with a naive-dominant-reading trap (a too-easy convenience-wiring feature) (parry-heightfield-point-projection, ACCEPTED Mars 2026-07-05)

**When:** a feature is "wire up the point-query/convenience surface that other shapes already have" -- the correct behavior is inferable by transcribing existing repo conventions (a `convert_*` helper, an established `FeatureId`/location type). First Nova batch lands too easy (parry: 70%, 7/10) and EVERY failure is the SAME isolated self-revealing trap (a compile-time type mismatch, e.g. Voxels `Location = (u32,u32)` vs `(u32,FeatureId)` -> E0308). Nova single-shot-fixes isolated/self-revealing traps; test-only coverage padding of well-specified behavior only RAISES the rate (competent agents go N/N).

**The move:** DEEPEN one core behavior into a MISDIRECTING semantic trap where the naive/dominant reading is subtly wrong (à la symengine canonical-type-narrow-guard, data-forge validation-order). For parry the killer was a NEW query, `height_at_point`: the "obvious" terrain-height is BILINEAR over the 4 cell corners, but the shape's actual geometry is a TRIANGLE MESH (every other query uses it), so the triangle-plane height is the only correct reading. On a NON-COPLANAR cell + off-diagonal point they diverge (tri 0.0 vs bilinear 0.09/0.25); it is interdependent with the cell's zigzag flag (flips the diagonal -> different containing triangle -> different height) and removed flag (-> None). Requirements: (a) pick geometry that DISTINGUISHES the naive reading (a planar-per-cell / axis-only slope makes bilinear == triangulated and catches nothing -- the original too-easy test's exact flaw); (b) do NOT name the correct algorithm in the description ("the height of the surface" -- the surface-is-triangulated is discoverable, bilinear is the agent's unsupported assumption); (c) stack orthogonal near-misses on the same core (zigzag diagonal, removed -> None, non-square row/col orientation).

**De-crutch to add a second wall + a free emergent one:** a pub(crate)/pub internal helper that maps ids KILLS a trap (agents just call it). Make it PRIVATE so agents must re-derive the inversion (parry: `split_triangle_id`; the tid->(i,j,left) split with the `+ nrows*ncols` right-triangle offset -- bites hard on a NON-SQUARE grid where `nrows()!=ncols()` and on RIGHT triangles). EMERGENT free trap: removing the crutch perturbed a surrounding TYPE CONTRACT -- agents restructured to call the pub `triangle_at_id(id: u32)` and changed the associated `Location` id from the base's `usize` to `u32`, breaking the contract the hidden tests pin (3/10 failed on this alone). De-crutching does not just add the intended trap; it stresses adjacent public types.

**Result:** 70% -> 30% (at the Mars cap), Holistic PASS, all groups fair, zero hint suggestions, human ACCEPTED. Fail clusters at re-batch: triangulated-not-bilinear + non-square-split + directional-voxel (the genuinely_hard groups), the emergent usize/u32 contract break, and an EXPLICIT shared blind spot (is_inside not propagated below-surface because agents gate it on the `solid` arg while the feature path calls solid=false). The solution's core algorithm was largely UNCHANGED from the too-easy version -- difficulty came from the height_at_point deepening + de-crutching + de-prescriptivized meta, not from new mechanism. See PROBLEM-PROFILES parry-heightfield-point-projection.

## Pattern 69 -- Tier by the passer's irreducible LOC, not by difficulty; option-2-futility (aircompressor-zstd-strategies, ACCEPTED Mars 2026-07-06)

**When:** a capability-add whose described behaviors (round-trip, ratio, streaming) are ALL satisfiable by one compact implementation that AGENTS ALIAS to (aircompressor: 10/10 agents wired all 7 zstd strategies to ONE hash-chain; nobody built the binary tree or optimal parser the "5 distinct architectures" framing implied). You hardened difficulty successfully (50% -> 10% via breadth of fair walls) but the sole PASSING agent's human-effective LOC (289) sits far under the Olympus 450 floor. The reference being 663 does NOT save it -- the binding gate (reviewer Nandish, SOLUTION.md:84) re-counts the PASSING AGENT's diff, and aliasing makes that diff small.

**The two laws:**
1. **TIER BY IRREDUCIBLE PASSING LOC, NOT DIFFICULTY.** Difficulty and irreducible-solution-size are INDEPENDENT axes. A genuinely hard (10%) single-subsystem feature is a hard MARS when its fair minimal solution is small (289 is in the Mars 170-380 sweet spot; 10% is the hard edge of Mars <=30%). Do not chase the Olympus LABEL when the passing floor is Mars-sized -- ship it as the strong Mars it is.
2. **OPTION-2-FUTILITY.** To raise the passing floor you must force code the measured passer LACKS. Forcing a public-API FAMILY the passer ALREADY writes voluntarily (create(int)+JavaCompressor(int)+OutputStream(out,int), all present at 289) is a NO-OP on the floor. When the only code that WOULD raise it is unfair -- here strict cross-strategy ratio (forbid aliasing), which is BOTH unfair (Test Fairness rejects exact thresholds) AND untrue (the reference's own btopt loses to btlazy2 on binary geo.protodata) -- the floor cannot move. That impossibility IS the Mars-pivot signal; reason it out from the passer's diff instead of burning a batch to confirm.

**The hardening that DID work (for the difficulty axis, reusable):** breadth of orthogonal FAIR walls (piccolo-finalizers model), none escapable by the recursive recompress-fallback: adversarial-correctness corpora at the PROVEN R1 biters (repcode/ll0, MIN_MATCH=3 boundary) x every strategy + a streaming-crash wall + a minimal ratio floor. R2 batch: ratio killed 5/10, the ZstdOutputStream writeChunk "Must write at least one full block" buffer invariant killed 3/10. Correctness walls are unescapable by the fallback; ratio/monotonicity are not.

**Reflection f2p for the new public API:** `getConstructor(OutputStream.class,int.class)` compiles on base (no compile-time dep) + throws NoSuchMethodException at runtime = f2p that forces the ctor. FAIR ONLY once the meta NAMES the exact signature verbatim (Test Fairness flagged all 6 streaming tests until then). See PROBLEM-PROFILES aircompressor-zstd-strategies + lessons-learned. Counters the temptation to bolt sub-features to force Olympus (lessons-learned.md:322).

## Pattern 70 -- Rejection tests pin the NATURAL kind, and prepared writes need double-EXECUTE (gms updatable-view DML, APPROVED MARS 2026-07-07)

Two reusable, hard-won rules from a 14-round fairness tail on a planbuilder DML feature.

**70a -- A rejection test's pinned error KIND must be the kind a NATURAL correct solution produces, not the kind your reference threads.** If the base engine already rejects the operation with a specific `errors.Kind`, agents inherit that generic kind and your reference's different (more-specific) kind becomes a 0-pass gotcha; simultaneously, asserting the natural kind == base kind = not f2p. This makes such a rejection UNTESTABLE-fairly. Decision test: does base throw a `Kind` or a bare `fmt.Errorf` for this rejection?
- Bare non-Kind error on base (e.g. INSERT into a view: "expected insert destination...") -> pinning the repo's real Kind (ErrInsertIntoNotSupported) is BOTH f2p (base != that Kind) AND reachable by a natural solution = FAIR.
- Base already returns a Kind (e.g. UPDATE into a view -> GetUpdatable(*SubqueryAlias) = ErrUpdateNotSupported) -> the fair kind == base kind = not f2p, and any other kind is 0-pass = REMOVE the test. The disqualification analysis is usually shared, so a sibling fair rejection (INSERT) already covers it.
- Only the 12-run Holistic batch reveals this: the sub passed Auto Review + Test Fairness (0 unfair) + dedupe, then went 0/12 on the UPDATE-rejection kind. All green AI checks < one real batch.

**70b -- To test a PREPARED write, use SQL `PREPARE p FROM '...'; EXECUTE p USING @a,@b` executed TWICE.** `TestScriptPrepared` runs `SetUpScript` NON-prepared and only prepares Assertion queries; a write in SetUp has zero prepared coverage, and a single write-as-assertion is one prepare+execute that misses re-bind bugs. The 2nd EXECUTE re-binds the cached AST -- the only shape that catches an in-place AST mutation (the classic planbuilder bug: never mutate i.Columns/statement fields; gms caches + re-binds the *ast pointer for prepared queries; thread a local).

**70c -- corollaries.** Full enginetest base run pulls in TCP-server tests (firewall + `--network none` fail) -> whitelist in-memory suites + justify the server exclusion. An existing repo test the feature FLIPS is f2p -> update its assertion in test.patch and run it in NEW mode (base would fail baseline_before_solution). Read difficulty off the Nova-heavy standard mix, never an all-Orion batch (Orion=worst-case-easy).

## Pattern 71 -- The passer-LOC gate + the structural-lever fix for machinery-backed features (kcl-union-override-typecheck, APPROVED MARS 2026-07-07)

The binding Mars 100-LOC floor is measured on the **LEANEST PASSING AGENT's raw production diff**, not on your reference. A feature the target repo's existing recursive machinery can service is intrinsically sub-floor no matter how much you write.

**71a -- Tier by the leanest passer, and the human counts RAW production lines.** My reference was 150 Counter1 / 114 Counter2, but the sole passer solved it in 94 RAW production LOC and the human reviewer rejected on that. The reviewer said "94 counting generously" for a diff whose strict brace/import-stripped count was 69, so **the human floor = RAW added production lines (braces kept, blanks/comments stripped)**, roughly Counter1 with braces. Estimate the leanest plausible passer's RAW count and design so IT clears 100, not your own solution.

**71b -- Machinery-reuse = floor collapse.** The feature was "check `|`/`**` config overrides the same way as a config-literal override." KCL already had recursive config-context checking (check_config_value_recursively + config_expr_context switching). The passer added only a List+Union arm to that helper and got ALL nesting recursion for free (~40 LOC minimal). Probing the passer's patch, it handled every nesting shape (chained, nested, spread-of-instance, list-of-dict-of-schema, dict-of-list). **Any feature framed "do X the same way the existing Y checker does it" is a floor-collapse risk -- agents reuse Y.** Screen at pick time: locate Y's checker, ask "reusable in <100 LOC?" If yes, pick differently or pre-plan a lever.

**71c -- The structural-lever fix.** Find the ONE form the reusable machinery structurally CANNOT reach, and require it (described + tested). `|=` compound assignment routes through walk_aug_assign_stmt -> binary() (calculation.rs), NOT walk_binary_expr where every agent put the check, so the reused helper never sees `|=`. A `|=` test family (flat/undefined/nested/list) broke the shortcut and forced the passer +27 LOC (94 -> 121 raw) -> cleared 100 -> ACCEPTED. The reference handled `|=` free because it checks in binary() (covers `|` and `|=`). Recipe: enumerate sibling forms that bypass the reuse hook (aug-assign vs binary-expr, spread-from-variable vs inline-literal, schema-instance-RHS vs dict-literal-RHS); each one the reuse can't cover raises LOC AND adds a fair, described failure cluster (this gave 4 diverse clusters at 8.3% pass).

## Pattern 72 -- Open-policy = thoroughness gate; CLOSE the policy for a misdirection wall (stoolap-comparison-consistency, APPROVED Mars 2026-07-07)

A "make X consistent, you choose the rule" feature is a PURE THOROUGHNESS gate: every passer does the SAME shared-helper + find-all-sites refactor, so it is bimodal at ~50% and MORE duplicated sites CANNOT lower it (empirically 23 tests -> 50%, 28 -> 50%). No misdirection is possible because a thorough agent can only be INCOMPLETE, never WRONG. FIX: CLOSE the policy to a specific rule that CONTRADICTS the codebase's existing tempting helper. stoolap open spec said "you choose how 10 compares with '9'"; CLOSED to "compare as numbers" (`10 > '9'`). The repo's own `Value::compare` string-coerces (`'10' < '9'`) and every passer reused it, so multi-digit ordering is now WRONG for them -> even thorough agents fail. 50% -> 16.7%. Bonus: closing an open policy makes the behavior PIN-ABLE in tests, retiring an earlier Test-Fairness "over-pins an open policy" FAIL. Also enlarges the solution (the ordering ops now must be routed too), so the fast agents run out of budget before finishing. Detail: memory lesson_open_policy_thoroughness_gate.

## Pattern 73 -- Multi-join-algorithm consistency: fix EVERY join algo (planner routes by size+sortedness) (stoolap-comparison-consistency, APPROVED Mars 2026-07-07)

A "make every equality/ordering path agree" feature in a real SQL engine has a WIDE, easy-to-under-cover join surface. The query planner picks among join ALGORITHMS by input SIZE and SORTEDNESS: small -> HashJoin (hash_table.rs), large-UNSORTED build (>=10k) -> parallel HashJoin (utils.rs hash_composite_key/values_equal), large-SORTED -> MERGE JOIN (utils.rs `compare_values` ORDERING, NOT the equality helper), tiny -> NestedLoop (inherits the scalar `=` fix for free). A narrow fix (scalar + the one obvious hash join) passes every SMALL test but SILENTLY fails high-cardinality tests. The MERGE-JOIN sub-trap: merge join walks the sorted streams with the ORDERING comparator (`compare_values -> Ordering`, treats `Equal` as a match); if its cross-type arm falls to a type-code ordering (Integer=2 < Text=4 -> int always sorts before text) then coerced-equal pairs are NEVER `Equal` -> 0 matches, even though scalar `=` and the hash join were fixed. DEBUG DISCIPLINE (cost ~8 expensive high-cardinality runs): instrument the dispatch (eprintln at each join executor + hash fn + the algorithm-selection match) and run the failing size ONCE; the reviewer's NAMED file (utils parallel) was NOT the failing path -- the merge join was, chosen because the test's build side was sorted. Find the planner threshold cheaply by probing a few sizes in one run (merge join kicked in at >=500 sorted rows here, so the f2p test needs ~600 rows, not 10k). This was the DOMINANT wall (7/10 Nova missed the join-hash bucketing): un-fixable by scalar equality alone because the type-discriminated hash keeps int/text in SEPARATE BUCKETS (interdependent+misdirecting: symptom = 0 join rows, cause = bucketing not equality). Detail: memory lesson_multi_join_algorithm_consistency.

## Pattern 74 — COMBINED positive+negative f2p test (resolve per-test-f2p × quality-needs-rejection) + name-keyed-map clear-on-rebind (numbat-const-exponents, APPROVED Mars 2026-07-09, 1/11=9%)

- **THE CONFLICT (two hard checks pull opposite ways):** Verify-Solution enforces PER-TEST f2p (every new-mode test must fail on base, NOT suite-level). The "problem-and-tests quality" check demands new mode ENFORCE the rejection requirement (else an over-open solution passes). A bare rejection guard (`expect_error`) PASSES on base (the rejection is base-existing behavior) so it satisfies NEITHER: it can't be new-mode (per-test f2p) and if it's base-mode the quality check says new-mode doesn't enforce rejection.
- **THE RESOLUTION — one `#[test]` that does BOTH:** assert a POSITIVE feature case works (`meter^n`) — FAILS on base → satisfies per-test f2p; AND assert the bad form is REJECTED (`fn f(x)=meter^x`, dimensionful const, div-by-zero, function-call) — runs in new mode → satisfies quality + catches an over-open solution. On base the positive assertion errors → whole test fails (f2p); on an over-open solution the negative assertion fails → caught. This ALSO frees base mode to be PURE pre-existing (reviewer's clean base/new split). Rejection/boundary tests can NEVER be standalone new-mode f2p — always pair them with a base-failing positive.
- **NAME-KEYED CONST MAP MUST CLEAR-ON-REBIND (the Solution-Quality bug a reviewer WILL catch):** a `HashMap<name, value>` tracking compile-time constants that only INSERTS on success + only removes function params LEAKS a stale entry when a name is rebound to a non-const (`let n=3; let n=sin(0); meter^n` wrongly accepted) or shadowed by a `where`/local binding. FIX: the `let`-elaboration must REMOVE the name on non-const RHS (else-arm). In numbat this covered ALL paths free because `where`/local bindings ARE `local_variables` run through the SAME elaborate-define-variable, and function save/restore scopes them. LAW: any name-keyed const/value map needs insert-on-valid AND remove-on-invalid, or a shadowing runtime value of that name leaks through.
- **DOMINANT FAIR TRAP = TYPE-GATE vs CONST-EVAL on negative arithmetic (killed 5/11):** agents record a `let` as const only when `type_deduced == Type::scalar()`. A polymorphic-zero binary subtraction (`let e = 0 - 2`, `let neg = 0 - 1/2`, `let negn = 0 - n`) does NOT deduce to exact `Scalar`, so the Scalar-gate DROPS it — while UNARY `-1/2` deduces cleanly and passes. The reference does NOT type-gate; it just tries `evaluate_const_expr` (which folds `0-2` = -2 exactly). Reusable Nova/Orion blind spot: a spec allowing "expressions built from constants" where the OBVIOUS type-equality gate mis-rejects a foreseeable arithmetic form. Pair a unary-minus (passes) with a subtraction-to-negative (fails) to make it bite.

## Pattern 75 — Composition-seam stacking (turn isolation-passing into composition-failing) (scryer-clpq-linear, APPROVED Mars 2026-07-09, 3/10=30%)

- **THE PROBLEM (bimodal depth-wall):** a DEPTH feature ("implement a correct X" — a CLP(Q) solver, a type checker, an evaluator) whose tests probe each behavior in ISOLATION is a coin-flip ~50%. A thorough agent completes each behavior independently and passes; a rushed one does not. LOC does not move this. The fails are all "incomplete impl," the passes all "full impl" — bimodal, and the band sits at the completion probability (~40-50%), too easy for Mars (<=30%). scryer clpq's first robust-harness batch = 40% for exactly this reason (passers were 853/629/537-LOC full impls).
- **THE LEVER — stack tests at the COMPOSITION SEAMS:** add tests that force a value to become determined through ONE channel and then require ALL downstream consumers to re-fire off that determination. A partial impl that wires the wake/recheck to only the OBVIOUS channel (explicit unification) but not the others (implicit-equality-from-bounds, Gaussian collapse, var-var merge) passes each behavior alone but breaks composed. scryer seams: promote(opposing bounds)→nonlinear-wake (`nl_via_bounds`), merge→promote→nonlinear (`merge_nl`), promote→disequality-recheck (`diseq_via_bounds`), Gaussian-determination→disequality-recheck (`diseq_via_eqsys`), and inf-as-LIMIT vs minimize-as-ATTAINED on the SAME open bound (`inf_strict_open` + `min_open_no` split). Batch1 40% → batch2 30%; the bind-seam traps caught exactly the marginal passers whose delayed-nonlinear bucket was a no-op on non-unification determination.
- **SOLUTION UNCHANGED + FAIR:** a CORRECT reference already composes (determination goes through real unification, so the attribute hook re-fires every consumer via a re-entrant fixpoint) — so the seam-tests need ZERO solution change and pass the reference (solvability preserved). Every seam-test traces to an EXISTING description sentence (the behaviors were always required; you only test their COMPOSITION now), so Test-Fairness rates them fair. This is the cheapest fair hardening lever when a batch shows bimodal "full-pass / partial-fail."
- **vs Pattern 48 (deepen ONE dominant trap):** P48 general-parameterizes the SAME trap deeper (one nesting level → two). P75 COMPOSES several INDEPENDENT behaviors so a single local fix to one regresses another — the interdependence is ACROSS different behaviors sharing a determination chokepoint, not one behavior scaled up. Use P75 when the feature is a multi-behavior engine and the passers are "did everything, in isolation."

## Pattern 76 -- Precedence-boundary trap: the strongest lever for a NEW-OPERATOR / new-precedence pick (erg-chained-comparison, APPROVED Mars 2026-07-10, 3/10=30%)
When a pick adds a new operator/construct with its own precedence, the boundary between the NEW construct and the EXISTING lower-precedence operators around it is the highest-yield, most-misdirecting trap. In erg-chained-comparison the single dominant killer (3 of 7 batch fails) was `1 < 3 < 2 and 4 < 5`: agents build the comparison chain only when the NEXT token is also a comparison operator, so a run terminated by a lower-precedence boolean (`and`/`or`) falls back to the base left-associative `(a<b)<c` BEFORE the boolean applies, yielding truthy where CPython gives False. Why it lands: (a) MISDIRECTING -- pure chains transpile/run perfectly, so the agent's own smoke tests all pass; the bug only surfaces at the boundary the agent never thought to test. (b) INTERDEPENDENT with the flatten logic -- fixing the boundary re-decides WHERE a run ends, which interacts with paren handling and the in->contains rewrite. Design rule: for any new-operator pick, always add tests placing the new construct ADJACENT to existing lower-precedence operators (and/or/ternary/assignment) and as a sub-expression of if/assert/return. Cheap to write, catches the ~50% of agents who scope the new construct too narrowly. Companion diagnosis: if a too-easy batch's fails are all DIFFERENT incidental bugs with no shared seam, the problem is single-mechanism -- harden by probing every seam in BOTH code paths, not by adding more of the same test.

## Pattern 77 -- Engineer a machinery-riding WALL to harden a GREENFIELD thoroughness-gate (zen-table-verification, APPROVED Olympus 2026-07-10, 1/10=10%)

A net-new feature whose every tested behavior is DOCUMENTED + INDEPENDENT + SELF-REVEALING is a THOROUGHNESS gate, not a trap gate: thorough agents (Nova wrote 800-1240 LOC here) implement each documented case one by one, so adding MORE documented cases does not move the pass rate. zen-table-verification (semantic decision-table verification: unreachable rules + incomplete coverage over a shared cover-algebra engine, driven from BOTH the graph `Decision::verify()` and the policy analyzer) sat at 90% (9/10) across TWO batches of documented-independent traps (nullable-completeness, bare-global, entity-scope, joint enum x number). Greenfield static-analysis is the classic offender because the agent builds the whole thing clean and never rides the trap-laden EXISTING machinery that makes hard problems hard (contrast the approved zen-hit-policies: no-Ord compile wall + exact-Decimal + silent dual-path + shared short-circuit).

**The lever:** engineer ONE wall that is (a) obvious-impl-wrong, (b) interdependent (routed through a chokepoint the agent already had to touch), (c) misdirecting (the failing assertion points away from the cause). For zen-table-verification: the completeness check already substituted the declared column domain for wildcard cells AND bolted on a nullable-absence check, but UNREACHABILITY did neither. Reworking BOTH checks to run over ONE extended domain (value space + an absence point on optional columns) via a single `column_domain -> Domain{region, nullable}` chokepoint created a wall with three faces the naive impl gets wrong: a non-nullable numeric wildcard-after-tiling must be UNREACHABLE (agents write `Any minus numbers = Any` so tiling never covers it); a nullable wildcard must STAY reachable (it uniquely catches null; agents omit absence from reachability); a nullable catch-all must COVER absence. Implementation: `unreachable_rows(rows, col_domains)` builds effective rows = domain-substituted wildcards + an appended presence-dimension (Bools{present[,absent]}) per optional column, then runs the SAME N-D box subtraction; the graph path passes all-None domains so it stays conservative and unchanged.

**Measured:** the one wall dropped 90% -> 20% -> 10% across two hardened batches and was the SOLE difficulty driver over 19 runs (batch 3 = 5/8 fails on it, batch 4 = 9/9). Its interdependence made it ripple into 3-4 adjacent behaviors (multi-column Cartesian coverage, nullable catch-all absence, covered_by union attribution) so a retry cannot single-point-fix it.

**Corollary (confirmed):** a coverage/completeness test is NOT a difficulty knob. The human reviewer required adding a multi-table aggregation test between batches 3 and 4; it did not move the rate. Budget test-writing accordingly: coverage tests for fairness/completeness, ONE engineered wall for difficulty. See `lesson_greenfield_static_analysis_thoroughness_gate` in auto-memory. vs Pattern 48 (deepen ONE dominant trap): P48 scales the same trap deeper; P77 REARCHITECTS two separate checks to share one domain model so the obvious separate-checks structure is wrong. vs Pattern 75 (composition-seam stacking): P75 composes independent behaviors sharing a chokepoint; P77 is specifically for greenfield/thoroughness-gate features where NO existing machinery supplies a wall, so you must build the chokepoint yourself.

## Pattern 78 -- COLLECTION-AGGREGATING API needs a >=2-element UNION test (zen-table-verification human revert, 2026-07-10)

When an API is specified to aggregate over a COLLECTION (all graph nodes, all rules, all files, all matches), at least one test MUST build 2+ elements each carrying a DISTINCT defect and assert the UNION of results -- a single-element harness silently permits a first-element-only implementation and passes. zen-table-verification was auto-approved then HUMAN-REVERTED because `Decision::verify()` returns warnings for a WHOLE graph decision (iterates every decision-table node) but every test built a single-node graph (the builder hardcoded one node id `dt`). Fix: a two-table graph where table A is unreachable-only + complete and table B is incomplete-only, asserting the returned warning SET contains both payloads. Two rules for such a test: (1) each element's defect must be UNIQUE to it (so a first-only impl provably misses the others), and (2) assert on the DOCUMENTED payload fields (row/covered_by, column/missing_values), NOT on an identifier the spec does not require (node_id here) -- pinning an undocumented field is over-spec. Verify teeth by temporarily patching the reference to process only the first element and confirming the test FAILS.

## Pattern 79 -- CLUE-CALIBRATION LADDER: a universal-blind-spot convention's meta-clue specificity sets pass rate (kcl-union-conflict-report APPROVED Mars 2026-07-10, 20%)

When the whole difficulty of a problem rests on ONE codebase-inferable convention that is ALSO a universal agent blind spot, the pass rate becomes almost a pure function of how explicitly meta names that convention -- and the sensitivity is binary-ish, so you MUST measure each clue rung (Pattern 48; predict nothing).

kcl multi-conflict union report: the sole fair difficulty is that a merged-list element gets a SEPARATE `list[index]` path segment (the repo pushes `format!("list[{idx}]")`), but every agent FOLDS the index into the enclosing key -> `s[0].p` instead of `s.list[0].p`. Group data proved it universal: every NON-list test group passed 11/12 while every list-path group passed 0/12 when the clue was too weak. Three consecutive batches on the SAME solution+tests, meta clue the only variable:

| meta clue for the list-element path | Nova pass rate |
|---|---|
| "uses an indexed path segment" (no token, no separateness) | **0%** (universal fold; reads as unfair-hard) |
| "a `list[index]` path segment that stays a segment of its own rather than folding into the enclosing attribute" (literal token + the exact anti-pattern) | **100%** (trivial) |
| "adds its own indexed segment to the path" (SEPARATENESS nudge, NO literal `list` token, NO fold anti-pattern) | **20%** (in band) |

Laws:
- **Naming the literal token OR spelling the anti-pattern trivializes** the trap (100%). A bare restatement of the requirement without the disambiguator = 0% (nobody discovers it). The in-band rung is a **separateness nudge**: tell the agent the index is its OWN segment, while leaving the exact spelling (`list`) to <=1 repo-inference.
- **Iterate the clue by ONE specificity notch per batch.** 0% -> add a separateness nudge; 100% -> remove the literal token/anti-pattern, keep the nudge. Never jump two notches.
- The clue only sets WHERE on the 0-100 curve the trap lands; the **difficulty LEVER itself** was the list-of-lists DEEPENING (Pattern 48 general-parameterization, which took the token-present variant 40% -> 20%). Clue calibration and trap-depth are orthogonal knobs -- tune depth for the SHAPE, tune the clue for the BAND.
- Distinct from Pattern 51 sec3 (spec an UNSTATED convention in meta): here the convention IS repo-inferable, so it stays the allowed <=1 codebase-inferable; the calibration is about how much of the disambiguator to surface, not about fixing unfairness.

## Pattern: Hint-Calibration CLIFF on opposite-polarity subcases (gms-null-rejection, 2026-07-08)

When a hinted axis's failing subcases share a ROOT but have OPPOSITE correct answers, in-meta hint calibration is a CLIFF, not a smooth dial — and the only stable landing is to REMOVE the hint entirely.

**Diagnosis:** `NOT (x IN (m1,1))` should UNLOCK a reorder (rejects the shared relation) while `NOT (x BETWEEN b AND 9)` should BLOCK it (doesn't). Both are "negated range/membership." Any hint concrete enough to resolve ONE (e.g. "a relation in only one bound/alternative can still be TRUE") mis-resolves the OTHER. The only hint that resolves both correctly is the full De Morgan mechanism (NOT-IN=union, NOT-BETWEEN=intersection) — which trivializes it (~100% pass).

**Measured curve (same problem, in-meta, Mars):** explicit De Morgan expansions ~100% · "boolean-combination + apply AND/OR rules" 60% · name-both-shapes + truth-table method 55% · softer-shape 50% · definition-pointer only 0% · hint fully removed 8% (in-band).

**Rule:** don't try to find the middle rung on an opposite-polarity axis — there isn't one. Keep the fairness-clause (states the forms are in scope, prevents an UNFAIR blind spot) + the bare definition ("a negated predicate rejects whatever forces it away from TRUE"), and let the opposite-polarity 3VL wall be the natural floor. Corollary (HINT-REMOVAL-NOT-DIAL): once a hinted axis shows 0 failures while other axes fail, the hint is pure giveaway — remove wholesale.

**Companion — CONCISENESS-trim-lowers-difficulty:** a precheck conciseness pass that removes PREFACES / anti-pattern restatements ("never as one set over all referenced tables", "depends on the value as a whole") simultaneously de-spoon-feeds the union-agent / arithmetic traps. Apply those trims: the gate and the difficulty both move the right way.

## Pattern 34 — Cross-subsystem via a cycle-safe consumer (Task-Quality 08) + FP-bleed cure (from go-geom-polygonize, APPROVED Olympus 2026-07-13)

**34a — 08 gates on the SOLUTION DIFF spanning >=2 packages.** Cross-package TEST imports do NOT satisfy Task-Quality 05/06/08; the solution itself must touch a second package. To lift a single-subsystem feature to Olympus, add a thin real consumer in a second package (here `encoding/geojson.Polygonize([]byte)([]byte,error)` wrapping the core `xy.Polygonizer`). MAP THE IMPORT CYCLE FIRST: the core's own dependencies (transform/sorting/wkt for xy) cannot be the consumer; pick a package that already depends on the core (geojson/xyz depend on xy). This adds genuine LOC + a second f2p test surface, not padding.

**34b — FP-bleed cure = one HARD adversarial instance per requirement.** The mandatory FP check inspects every passing agent and finds the weak impl that passes a CLEAN/representable instance of a requirement but fails a HARDER instance of the SAME requirement (recompute-per-segment + exact-float-bit keying fails at non-representable crossing coords x=1/3, 30/11; a keyhole channel is a cut edge a per-exterior-bridge impl misses). Three FP batches in a row until each requirement was tested on its hardest instance. RULE: for every requirement, add a test on the hardest instance and probe the reference on it BEFORE shipping; a single clean case per requirement leaks FPs.

**34c — Remove-belt-keep-suspenders (dead-guard removal on human review).** When review flags a guard as dead, the burden is to PROVE unreachability by naming the invariant-enforcer that already covers it (dedup-at-noding, pairwise marking, ring-labeling totality), then delete. An absolute-epsilon guard in an unspecified unit is a latent unit-bug, not merely dead. Confirm with go vet + full suite, not argument.

## Pattern 80 — CORRELATED-vs-INDEPENDENT WALL LAW: a 2nd trap lowers the pass-rate mean ONLY if uncorrelated with the 1st (truck-mass-properties, APPROVED Mars 2026-07-10, 20%)

**Context.** A textbook computation (rigid-body inertia tensor) whose CORRECT approach (raw-moments accumulate-then-assemble) is robust, so ~half of thorough agents simply get it right. One self-revealing failure mode (Solid per-face-open-mesh delegation -> divide-by-zero NaN) capped the pass rate at ~43% mean (batches 30/60/30/50) -- above the Mars <=30% gate with high variance.

**80a -- Adding a CORRELATED trap does nothing.** First hardening added a right-handedness `det=+1` wall (Jacobi accumulates rotations = det+1, but sorting eigenvectors ascending flips det on odd permutations; tests checked `|det|` so it was misdirecting). It was fair and had teeth (flip-off -> 3 tests fail), BUT it did NOT lower the mean, because it is a CORRELATED blind spot: an agent thorough enough to get the Solid-aggregation right ALSO produces right-handed axes. Correlated "thoroughness markers" (Solid-math + handedness + sign + parallel-axis + normalization) all fall to the same competent agent -- they do not STACK. Batch stayed at 50-60%.

**80b -- The independent wall breaks the ceiling.** Second hardening added NUMERICAL STABILITY, uncorrelated with the algorithmic insight: the textbook Mirtich impl accumulates second moments about the ORIGIN then subtracts `volume*centroid outer centroid` -> catastrophic cancellation for geometry far from the origin. The robust fix (standard geometry-lib practice) accumulates relative to a NEAR REFERENCE vertex (translate-first). An agent can get the Solid math perfectly right yet still accumulate about origin -> a DIFFERENT sub-population fails. Result: 50% -> 20%, with the far-origin test the new dominant wall (8/10 fail it); 5 runs fail it ONLY, 3 fail it + Solid, 2 pass. Two INDEPENDENT walls -> robust 20% (not the 30% edge).

**Design rule.** When a feature caps because thorough agents are simply correct (Pattern-17 ceiling), do NOT stack another trap on the SAME axis of competence -- it will be correlated and move nothing. Find an ORTHOGONAL failure mode a correct-but-naive implementation trips independently. For numeric/geometry features, NUMERICAL STABILITY (far-from-origin catastrophic cancellation, exercised as a translation-invariance test) is a reliably independent axis. Frame it as a documented invariant (a WHAT: "translating the geometry does not change it, wherever it sits in space") so it is a fair MISSED_REQUIREMENT, not a hidden precision gotcha -- confirmed by unanimous eval `was_mentioned_in_description=true`.

**Cost note.** Solution change is real (2-pass / reference-relative accumulation), which also lifts effective LOC (C2 121 -> 137). The correct impl becomes genuinely more robust -- the trap and the code-quality improvement are the same edit.

## Pattern 81 — HINT-IN-META: converting an Olympus NEEDS_HINTS into an unhinted pass (scryer-clpq-linear, APPROVED Olympus 2026-07-16, 0% -> 10%)

Olympus has NO separate hint field (Diamond-only). When a batch lands 0% with a holistic NEEDS_HINTS verdict AND the failures are fair (no unfair flags, prior solvability evidence exists), the fix is folding the hint INTO the meta as a WHAT-principle — a behavioral clarification of already-required behavior — then re-batching unhinted.

**Procedure:**
1. Find the near-miss population's SHARED gap (clpq: a 120/123 run failed only ent_sum/ent_diseq/sup_2var = entailment/bounds over the full connected store).
2. State the gap as a PRINCIPLE, not an example: "These queries reason over the whole accumulated store reachable from the query's variables, not only the variables written in the query." Plus the minimal noun-phrase widening ("disequalities the store implies").
3. **NOT-TOO-EXPLICIT guard:** never paste test-case bodies or worked instances of the gap (first draft pasted the ent_sum/sup_2var goals verbatim = spoon-feed = >40% risk). A principle lifts agents who built the machinery but scoped it wrong; an example lets everyone pattern-match.
4. **Clarify only UNDERSPEC'D walls.** An implementation-hard wall (dump's FM projection — fully documented, execution-hard) gets NO new wording: easing it means giving the algorithm (prescriptive) and collapses the band.

**Why it works:** the two wall types partition the population. The clarification flips the near-miss top (0% -> >=1 pass = solvable); the untouched implementation-hard wall holds the middle (rate stays in-band). clpq: 0% -> exactly 1/10, then auto + human approval.

**Distinguish from the Diamond hint flow:** Diamond hints live in a separate UI section with success-QA-only on hinted runs. Olympus hint-in-meta changes the artifact (meta edit stales the batch) — budget one full re-batch for it.

---

## Pattern 60 — Inverse-subsystem tasks + philosophy-fit grading with QUOTED scope evidence (community-hardened 2026-07; refines Pattern 22 / R3-R4)

**The inverse-subsystem shape: build the missing OPPOSITE direction of a deliberately one-directional library** — a WRITER for a read-only parser, a READER/decoder for a write-only encoder/renderer. This is an ESTABLISHED, often STRONGEST task shape, and our maintainer-philosophy gate can OVER-REJECT it if applied naively:

- The "contradicts the repo's read-only/write-only philosophy" objection is a CATEGORY ERROR for an Olympus task: the task is an agent-EVALUATION harness, never a merged contribution — "would the maintainer merge this" is not the governing bar.
- Why the shape is strong: the existing direction is a perfect self-contained ROUND-TRIP ORACLE (write → read back → compare); the repo hands you all the domain types/enums to reuse; there is no reference implementation to plagiarize. Shipped precedents (other authors): decoder for an encode-only barcode lib, PostScript reader for a PS-writer, DWARF writer for a read-only ELF/DWARF parser.
- **DISCRIMINATOR — an inverse task must clear BOTH:** (a) **NO HARD ARCHITECTURAL VETO** — "this direction is wrong in principle / breaks our design / we will never do this" = automatic reject; but a SOFT decline ("no time", "not a priority", "I don't plan to add this myself") does NOT disqualify; AND (b) the positive-fit test below. No-hard-veto alone is NOT sufficient — a soft decline plus a FOREIGN feature is still a reject.
- **Pre-empt at build time:** record in the problem folder the precedent list + the soft-decline evidence (issue/PR link + quote showing it is time/priority, not architecture) + the positive-fit verdict, so a late "contradicts the philosophy" review is answerable immediately.

**Philosophy-fit grading (R4 is NOT "no hard veto") — grade STRONG / MODERATE / WEAK, grounded in a QUOTE:**

Before grading, READ the repo's full scope surface and QUOTE the sentence(s) stating PURPOSE / SCOPE / NON-GOALS: README body (incl. Scope/Goals/Non-goals/Design/FAQ/Limitations sections), CONTRIBUTING, docs intro, package docstring, intent-declaring module comments. grep for `scope`, `non-goal`, `not a`, `only`, `won't`, `do not support`. The grade must cite a real quote, not a vibe. Two cases:
- README states a PURPOSE the task plausibly extends → supports STRONG/MODERATE. A README that merely describes the CURRENT direction ("a library for PARSING X") is NOT a non-goal — that is the EXPECTED inverse-subsystem situation, not a reject.
- README/docs carry an EXPLICIT non-goal or architectural boundary matching the task ("not a X", "X is out of scope", a Non-goals section excluding it) → HARD-VETO signal → WEAK → reject.

| Grade | Meaning | Action |
|---|---|---|
| **STRONG** | Natural extension of the core purpose OR a symmetric DIRECTION-FLIP of an existing subsystem, on the repo's own types/engine, with a positive belonging signal (docs/tests/issues treat it as in-scope/wanted) | Build |
| **MODERATE** | Reuses the repo's own machinery, plausible extension, but a ROLE change (server for a client-only lib) or no demand signal | Build ONLY with a written one-sentence positive-fit justification (which abstractions it reuses, why a maintainer would call it in-scope) + the soft-decline evidence recorded |
| **WEAK** | Foreign to the repo — doesn't reuse its abstractions, a maintainer would call it a different project, or "fits" only by absence of a ban | REJECT; a green "no veto" does not rescue it |

Preference order when choosing between candidates: direction-flip (writer-for-reader) > role change (server-for-client), all else equal. This pattern does not bypass the SIX-CHECK (Pattern 22) — it corrects how its RESULT is interpreted for inverse-direction picks.

## Pattern 82 — CAPABILITY CROSS-PRODUCT CELL: test the intersection, not the axes (neva-array-bypass-generalization, APPROVED Olympus 2026-08-01, 20%)

**The pattern.** When a contract says "X must work for all forms of Y", write the forms as a MATRIX before writing tests. One axis usually carries multiplicity (one/many receivers, single/repeated rounds); the other carries polarity (in/out, which side is anchored, sender/receiver). Agents build a case analysis per axis, pass every single-axis test, and never construct the cell where two axes meet.

**Measured.** `array_bypass_receiver_anchored_fan_out` (anchoring x fan-out): 8 of 10 kills, and the SOLE failure of both runs that scored 20/21. Without that one test the batch reads 4/10 = 40%, at the ceiling; with it, 2/10 = 20%.

**Why it is misdirecting.** The agent's own case analysis looks complete — it handled every capability the prompt named. The composition failure OVER-fires (duplicate emission, `20\n20\n` instead of `20\n`) because both axes' code paths run, so it reads as a message-routing bug two subsystems away rather than a missing combination.

**Why it is free.** No new description words. A contract that states both axes covers their composition by construction — both evaluators marked the failure `was_mentioned_in_description: true`. Cost is ~20 lines of test.

**How to apply.** In DESIGN.md, fill a literal cross-product table (see `olympus-author` § 11b) and require a test in every off-diagonal cell. Treat an empty off-diagonal as a defect in the test plan, not a design choice. This is now the first lever to reach for when a batch reads near the ceiling — cheaper and better-measured than adding a second mechanism.

**Companion pattern (same problem).** F-9 cross-stage resolution drop: require an elidable form (an omittable name, an implicit default) in a repo whose emitting stage already re-resolves what the validating stage could resolve, and never say WHERE to resolve it. One root cause then breaks every capability at once — trap interdependence for free, 6 of 10 on neva. Full write-ups: `failure-patterns.md` F-9 / F-10.

## Pattern 83 — CONDITIONAL OUTPUT KEYS: adding fields to a snapshot-tested emitter with zero churn (rust-minidump-stack-containment, APPROVED Olympus 2026-08-06, 20%)

**Problem.** The feature must surface new information in a processor's JSON, but the crate has ~10
insta snapshot tests over that exact output. Emitting the new keys unconditionally reds all of them,
and a snapshot-churn diff draws a scope finding in review.

**Move.** Build the ordinary `json!` value first, then insert the new keys conditionally:

```rust
let mut value = json!({ /* the existing shape, untouched */ });
if frame.trust_degraded {
    if let Some(object) = value.as_object_mut() {
        object.insert("trust_degraded".to_string(), json!(true));
    }
}
```

Keys are **omitted, not null**, when there is nothing to report. All 10 snapshots stayed
byte-identical; the solution scored 3/3 on scope with "preserves ordinary output shape" cited.

**The fairness half, which is not optional.** A solution that silently preserves existing output is
relying on an UNSTATED requirement — agents can be killed by base tests for a rule the description
never gave. State it: "each only where there is something to say: a walk that ended plainly and
reduced nothing carries neither." That converts an unfair trap into a legitimate S3.

**Measured caveat (do not oversell this as difficulty).** The batch produced **0 baseline failures
in 10/10 runs**. Every agent got conditional omission right. This pattern buys REVIEW SAFETY and
FAIRNESS, not pass-rate. Budget it as hygiene.

---

## Pattern 84 — ANSWER THROUGH AN EXISTING API to dissolve an exclusivity collision (rust-minidump-stack-containment, APPROVED Olympus 2026-08-06)

**Problem.** The design needed to ask "does the module publish unwind info covering this address?"
The natural implementation is a new `SymbolProvider::has_unwind_info` trait method — which was the
same SHAPE as an open upstream PR's `unwind_strategy()`, putting the pick at exclusivity risk
(CLAUDE.md's bright-line test: overlay the hit's changed-file list on your solution footprint).

**Move.** Do not add the method. Find an existing API that already computes the answer as a side
effect and drive it with a probe. Here `SymbolFile::walk_frame` reports the covered range via
`set_cfi_rules_start_address` BEFORE applying rules, so a `FrameWalker` implementation that supplies
no registers learns coverage without needing evaluation to succeed.

**Result:** file overlap with the upstream PR 2 → 1, new trait methods 1 → 0, files 8 → 6, and
Counter-2 LOC went **UP** 248 → 265, because the probe implementation is real code.

**Two traps in the move itself:**
1. The walker CLEARS the range again when done ("reset even on failure so the address cannot leak"),
   so the probe must **latch** (`self.covered |= addr.is_some()`), never read the final value.
2. Every channel that means "there is published unwind information here" must latch, not just the
   obvious one. Missing the end-of-stack callback cost a grading point: a scanned frame landing on a
   range covered ONLY by a declaration was never promoted.

**Generalises to:** any time a shape-collision or namespace-expansion worry appears. Asking the
question through machinery the repo already has usually removes the risk AND adds honest LOC.

## Pattern 85 — SUBPROCESS-ASSERTED OUTPUT CHANNEL: the only way to test (or trap) stdout purity (vrp-tsplib-edge-weight-types, APPROVED Olympus 2026-09-02, 30%)

**When it applies.** The task adds or wires a CLI command that must emit machine-readable output
(JSON, CSV, a blob) on stdout, and the repo's library layer already writes prose to that same
channel — a bare `println!` logger, a package-level writer, an ambient sink reached without
injection.

**The pattern.** Assert the command's output from a SUBPROCESS test that parses the process's
entire stdout, never from an in-process call to the serializer.

```rust
let output = std::process::Command::new(env!("CARGO_BIN_EXE_vrp-cli"))
    .args(["solve", "tsplib", "../examples/data/.../explicit-display.vrp", "--get-locations"])
    .output()
    .expect("failed to run vrp-cli");
assert!(output.status.success());
let stdout = String::from_utf8(output.stdout).expect("stdout must be valid utf8");
assert_eq!(in_order(&stdout), expected_ordered_locations());   // parses the WHOLE stream
```

`env!("CARGO_BIN_EXE_<name>")` is a Cargo-provided path to the built binary and needs no extra
dependency or build script; Go has `os/exec` against a `go build` artifact, Node has
`child_process.execFile`.

**Why it matters in both directions.**

- *As a trap (F-19).* An in-process assertion CANNOT see channel contamination — it never touches
  stdout. Author the test in-process and the wall silently evaporates: your reference passes, every
  agent passes, and you learn nothing. This one construction was worth a 69% kill rate across 52
  runs and four batches.
- *As correctness.* A command documented to "return JSON" is broken if its stdout is not parseable,
  and no unit test of the serializer can detect that. This is a real coverage gap in most CLI
  repos, which is exactly why it is fair.

**Pair it.** Ship the subprocess test alongside an in-process test on identical data. A failure in
the subprocess test with the in-process one green localises the defect to the CHANNEL rather than
the content, which keeps the failure fair without naming the fix. Add a third variant that routes
through a `--out-result <file>` flag if the CLI has one: it exercises the same serializer on a
clean channel, and its passing while stdout fails is the clearest possible signal.

**Cost.** Three tests, no description words beyond the one clause that says the command returns the
output. Cheapest durable lever measured.

## Pattern 34 — Guard the adjacent untouched API (sibling-API contamination)

**When it applies.** Your feature adds an entry point that is a VARIANT of one the repo already
exposes (`SelectAll` beside `Select`, a batch form beside the single form, `try_x` beside `x`), and
the new one must follow a rule the original must NOT.

**The trap.** Agents factor the pair onto a shared helper and the new rule leaks onto the old API.
Measured 8/10 on go-workflows-channel-drain, graded `FAIL_REGRESSION`, and the sole failure of both
near-miss runs — it moved that batch from 40% to 20% by itself.

**Precondition (verify, do not assume).** The old behaviour must be documented in prose (guide,
README, doc comment) and NOT covered by the repo's own tests. Break it locally and confirm the base
suite still passes. If the base suite catches it, the seam is already guarded and this pattern is
unavailable — the agent would fail base mode and never reach your new tests.

**How to author it.**
1. In meta.md, scope the new rule by naming ONLY the new API. Do not write "this does not change
   `Select`" — that hands over the trap, and the scoping is already unambiguous.
2. Write TWO tests of the OLD api: the discriminating direction (earlier `Default` beats a later
   ready case) and the opposite (an earlier ready case beats a later `Default`). The second proves
   the rule is positional rather than "Default always wins", which is what keeps the pair fair.
3. Mirror at the public-wrapper level if the API is exposed there — it cost one extra test and
   doubled the kill signal.

**Fairness basis.** No description sentence is needed: not breaking untouched documented behaviour
is a standing rubric requirement ("no regressions"), the behaviour is in the repo's own docs, and
base passes the test. This is the exception to "every tested behaviour must be described" — the
description enumerates what you ADD, not the entire existing API you must not break.

**Cost.** ~40 test lines, zero description words. Highest measured value-per-line in the corpus.

## Pattern 86 — THE STRUCTURALLY DOOMED CLAUSE: recognise it by round two, not round eight (datafixerupper-ordered-alternatives, APPROVED Olympus 2026-09-08)

A contract sentence can be unfixable rather than buggy, and review findings cannot tell you which,
because each one arrives as an ordinary, correct, locally-repairable defect.

**The shape.** The clause promises an OBSERVABLE EFFECT on an object the implementation does not own,
reached through an interface that exposes no way to read that object's state. Every conforming
implementation of that interface is a separate corner, so the clause has an unbounded tail. Closing
the corner a reviewer names is always possible and never sufficient.

**Measured cost.** `datafixerupper-ordered-alternatives` spent **eight consecutive Solution Quality
rounds** (iterations 56, 58, 60, 61, 62, 63, 64, 66) on one clause: the MapCodec supplied-builder
marking. Each round closed the named corner; the next found another.

**The three tells, in the order they appear.**
1. **The clause needs a new sub-condition every round.** By round three its stated conditions had
   grown from one to five.
2. **Two findings demand contradictory things.** Round 62 required provenance checking; round 63
   ruled the only checkable proxy (class identity) unsound. When both are right, no implementation
   exists — that is the proof, and it arrives long before round eight.
3. **The same scenario is filed against different sentences.** Rounds 64 and 66 were one probe quoted
   against two clauses. At that point you are scoping sentences, not fixing a defect.

**The move.** Delete the clause and put the general guarantee on the value you RETURN (L41). Then pay
for it: deletion removed 9 tests and took the batch from **2/10 to 5/10** — +30 points, no reviewer
mentioned the loss (L44). Budget an orthogonal trap in the same round, exactly as for a fairness
disclosure (L34).

**Corollary — verify before complying.** The review that finally forced the deletion filed two S1
Highs. One reproduced exactly; the other could not be reproduced at all, its premise being false
(`JsonOps.getStringValue` accepts numeric keys when `compressed`, so the mismatch it described cannot
arise). Both were closed by the same structural fix, so compliance was correct — but say in the
response which was which, with the probe output. That is the part a reviewer can check.

## Pattern 87 — Before softening a trap, measure whether it HAS a middle setting

**When it applies.** A batch reads 0% (or far below band) and one cause accounts for most of the
kills. The instinct is to soften that cause. Check first whether softening it is even a graded
move — some axes flip every run or none, and there is nothing in between.

**The measurement, and it needs no replay.** The saved `junit-new.xml` per run already names every
failing case. For the candidate axis, ask: how many of the runs that die to it fail EVERY cell of
it?

```bash
cd problems/<name>/agent-runs/<batch>
python3 - <<'PY'
import glob, xml.etree.ElementTree as ET
AXIS = {'test_x[defaulted]', 'test_x[keyword_only]'}     # the cells you would drop
for d in sorted(glob.glob('*/')):
    bad = {tc.get('name') for tc in ET.parse(d+'junit-new.xml').iter('testcase')
           if tc.find('failure') is not None or tc.find('error') is not None}
    if bad & AXIS:
        print(d.strip('/'), 'axis cells failed:', len(bad & AXIS), 'of', len(AXIS),
              '| other failures:', len(bad - AXIS))
PY
```

- **`other failures: 0` on every such run** = the axis is BINARY. Dropping one cell flips nobody
  (they fail the others); dropping the axis flips them all at once. Do not plan to tune it.
- **Runs with other failures, or partial cell coverage** = the axis is graded and can be trimmed.

**Measured.** rocketpy-propellant-slosh: six runs died to the callable-domain axis, every one
failing both killing cells and nothing else. The counterfactual for softening was `0/10 -> 5/9 =
56%`, over the ceiling, while dropping a single cell was worth zero. The lever that actually
worked was somewhere else entirely — a representation pin whose removal flipped exactly one run,
taking the batch to `1/10` and an acceptance.

**The corollary.** When the dominant trap is binary and the batch reads 0%, look for a near-miss
whose SOLE failure is a fairness defect rather than the trap. That run is your solvability floor
and it costs nothing to release, because a requirement `meta.md` never stated was never difficulty
in the first place.


## Pattern 88 — Bind-mount replay: measure a candidate test against every saved agent patch before shipping it

**When.** Any round after the first batch, whenever you are about to add a test — your own idea, a
reviewer's coverage suggestion, or a regression for a defect found in your reference. L40 says
replay it; this is how to replay it cheaply enough that you always do.

**The mechanic.** Build the problem's Docker image ONCE. Write `test.sh` so it compiles from source
at runtime (the DFU harness runs `javac` over `src/main/java` + the new test file, taking jars from
`/opt/testlibs` baked into the image). Then every replay is a bind-mount, not a rebuild:

```bash
# one image, built once
docker build -t <prob>:latest .

# per agent patch: pristine base + test.patch + that agent's solution
for d in problems/<name>/agent-runs/<batch>/*/; do
  rm -rf $S/r && cp -r $S/pristine $S/r
  (cd $S/r && git apply --exclude='src/test/*' $d/solution-patch.patch)
  docker run --rm --network none -v $S/r:/app -v $S:/out -w /app <prob>:latest \
    bash -lc './test.sh --output_path /out/r.xml new'
  # parse r.xml with ElementTree, print pass count + failing names
done
```

`--exclude='src/test/*'` is load-bearing: agent patches carry their own test files, and applying
them overwrites the suite you are trying to measure.

**What it buys.** On datafixerupper-derived-recursion this ran four times across the review cycle
(79 -> 83 -> 84 -> 86 -> 87 tests) and answered the only question that matters before shipping a
test: *does the passing run survive it?* Nine suggested tests shipped on that evidence; ONE did not
— the Blocker's cross-group DataFix regression test failed the sole passer, i.e. 0/10. It also
proved the four ordinary-`Sum` tests were free (they killed nobody) and that three
reviewer-finding tests killed 4, 4 and 3 runs.

**Prerequisite.** A `test.sh` that compiles at runtime rather than relying on build output baked
into the image. Design for this from the first Dockerfile; retrofitting it after a batch is far
more expensive than writing it that way.


## Pattern 89 — Stated-but-untested probe battery (triage before an FP-driven redesign)

**When.** The FP check flags a pass, or a batch reads 0% and you suspect the description, not the
tests. Also before shipping a test a reviewer suggested.

**Procedure.**
1. List every behaviour sentence in meta.md. Mark each as tested (name the test) or stated-only.
2. For each stated-only sentence write a probe: one input, one expected value, a few lines.
3. Run every probe against every saved agent solution: fresh clone at BASE_COMMIT, apply that run's
   `solution-patch.patch` to source files only, run a throwaway probe file.
4. Count violators per sentence.

```bash
for d in agent-runs/<batch>/*/; do
  rm -rf $S/r && git clone -q $CLONE $S/r && git -C $S/r checkout -q $BASE
  git -C $S/r apply --include='src/*' "$d/solution-patch.patch"
  cp probes.test.js $S/r/test/ && (cd $S/r && npx jest test/probes.test.js --json --outputFile=$S/$(basename $d).json)
done
# then tabulate failures per probe across runs
```

**Reading the table.** A sentence most agents violate is either a trap you must test (and pay for in
the rate) or a clause to delete or scope. If NO agent is clean on every row, no clean pass exists
under that description: delete clauses until at least one saved solution is clean on every
remaining row, then re-derive the tests from the shorter spec.

**Measured.** ray-optics-formula-conditionals batch 2 (lone pass FP-flagged): order-independent
`and` narrowing 10/10 violators, nested-`if` value over-guard 8/10, invalid-only truth value 7/10,
identity range 4/10, five other sentences 0/10. The redesign deleted the three worst clauses, and
batch 3 produced a clean, accepted 1/10. The same battery priced a reviewer-suggested feasibility
test at 14/21 failing and 0/21 clean, so it became a scoped sentence instead (L54).

## Pattern 90 — Re-run "fails on base" after every fairness rewrite

**Problem.** A fairness finding asks you to drop an assertion that pins something unstated. What is
left often checks behaviour the repo already had, and the test goes green without the solution. The
platform then counts a new test that passes on base, and reviewers read it as coverage that is not
there.

**Procedure.** After any edit that removes or loosens an assertion, apply `test.patch` alone to a clean
base checkout and run new mode. Every new test must fail. For each one that passes, add one
feature-only observable the contract states (the new layer exists, the new accessor returns the
stated value), never a re-tightening of the assertion you just removed.

**Measured.** worldengine-orographic-precipitation, two separate rounds: a calm-wind test pinned only
pre-change precipitation values (added the all-zero `rainfall` layer check), and a humidity test lost
its post-erosion inequality and kept only `humidity == (precipitation - 3*irrigation)/4`, base
behaviour (added "the finished world carries a non-empty `rainfall` layer"). Both were caught by the
clean-room run's `61 failed, 1 passed` / `64 failed, 1 passed` line, not by review.

## Pattern 91 — One bind-mount RUN layer for a C++ build that must fit the environment start timeout

**Problem.** The platform's environment start (600 s, two attempts) includes building the image. A
C++ Dockerfile that does `COPY . /app`, builds tools, then `chmod -R a+rwX /app` pays an overlayfs
copy-up of the whole tree on the chmod, because every file lives in a lower layer. Local runs use a
cached image and never see it. Verify Solution fails with `EnvironmentStartTimeoutError`.

**Procedure.**
1. Time `docker build --no-cache` before the first batch. Anything near 600 s is a failure.
2. ~~One `RUN --mount=type=bind` layer~~ **SUPERSEDED 2026-09-23: the platform's "Dockerfile
   guidelines" check now FAILS any Dockerfile that brings the repo in through a bind mount + `cp`
   ("does NOT copy repository files using Docker COPY ... requires BuildKit"). Use a real COPY and
   avoid the copy-up instead:**
   ```dockerfile
   COPY --chown=1000:1000 . .
   RUN <build> \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
   ```
   Only directories (metadata-only copy-up) and the root-owned build outputs (same layer, no
   copy-up) get chmodded. Files stay owned by 1000 with their git modes, so root and uid 1000 edit in
   place, and an unmapped uid (4242) can still `git apply`, because git writes a temp file and renames
   it over the original. Never `COPY --chmod`: it also needs BuildKit and rewrites git modes.
3. Verify the resulting `/app` is identical to the old image (hash every file plus its mode) so the
   change is environment-neutral for the solvers, and run the clean room as 0:0, 1000:1000 and 4242.

**Measured.** cwerg-bcopy-bzero-lowering: 704 s cold (chmod alone 261 s) to 413 s with the bind mount,
`/app` identical across 3080 files, and the next batch built in all nine runs. (L62)
teavm-method-summaries (69 MB repo, gradle): bind mount 474 s, rejected by the Dockerfile check;
`COPY --chown` + full `chmod -R /app` 816 s; `COPY --chown` + dirs/root-owned chmod 431 s, clean room
identical as 0:0, 1000:1000, 4242:4242 and 4242:0.

## Pattern 92 — Timestamp-proof build in test.sh for compiled repos

**When.** Any repo whose Dockerfile runs `make`/`cmake --build` into `/app`. The platform commits `/app`
after the image build, so every object file and binary is a TRACKED file in the solver's sandbox.

**Failure it prevents.** Agents `git restore` those outputs to keep their diff source-only. The restore
gives them a newer mtime than the sources the agent edited, so the incremental `make` in test.sh
rebuilds nothing, and the new suite runs the BASELINE binary: every new test fails, the evaluator
flags a verifier blocker, and no per-test data survives.

**Procedure.**
```bash
# test.sh, before any test runs: rebuild exactly what the tests execute, ignoring timestamps
make -B -j"$(nproc)" tile-join tippecanoe tippecanoe-decode unit >/tmp/build.log 2>&1
# or: rm -f tile-join tile-join.o mvt.o && make -j"$(nproc)"
```
Keep the existing build-failure fallback (a failing JUnit testcase carrying the build log tail).
Confirm by restoring the tracked outputs after applying the solution and checking the new tests still
exercise it.

**Measured.** tippecanoe-tile-join-size-recourses: 9 of 10 trajectories restored build outputs, 7 runs
were graded against a stale or unlinked binary, and 2 ENV-blocked flags had to be contested. The only
run that never restored was the only pass (L63).

## Pattern 93 — Probe the observation surface before relaxing a near-universal stated wall

When most runs fail one test that a meta sentence plainly states, there are two stories: the agents
violate the sentence, or the test reads a different surface than the sentence promises (the returned
value vs a live object, a file vs an API). Only the second is unfair. Tell them apart with one probe on
the saved near-miss patches before touching the suite.

```python
# clean container: base + a saved near-miss solution-patch + test.patch, then
ret = pb.solve(status=status)            # the surface the contract promises: what the run returns
live = pb.get_variables()['t']()         # the surface the test reads
# pull the state vector out of ret, then compare both surfaces with each other and with the expectation
```

If the two surfaces are the same object and both are wrong, the wall is fair: keep it and move the rate
with agent mix (L65) or another lever. If they disagree, the test reads the wrong surface; retarget the
assertion (tests-only, so re-eval eligible). On sfepy-adaptive-stepping-accounting both near-miss
patches returned the solved state through both surfaces, the requirement stayed, and the problem was
accepted at 2/15 without cutting it.

## Pattern 94 — Project a tests-only re-eval by replaying the batch's own patches

A re-eval re-grades the last batch's solutions against the edited `test.patch` / `solution.patch`. You
already hold those solutions (`agent-runs/<batch>/*/solution-patch.patch`), so the re-eval can be
computed locally before you pay for it.

```bash
# fresh clone at BASE, the submission Dockerfile, the NEW test.patch, and every saved agent patch
docker build -q -t replay .
for r in runs/*.patch; do
  docker run --rm --network none --user 1000:1000 replay bash -c \
    "cd /app && git apply test.patch && git apply $r && ./test.sh --output_path /tmp/n.xml new | tail -1"
done
```

Run the reference twice as uid 1000 and once as root in the same loop. Do not delete the image until
the loop exits: removing it under a live `--rm` container turns the background command's exit status red.
On mwparserfromhell-site-aware-parsing the replay matched the platform's failure count on all 19 runs the pool kept (L68). The pool
dropped one projected passer, so state the projection as "N passes if the pool keeps every run". Use it
only for tests-only changes; a meta.md edit changes what agents write, and no replay can measure that
(L35).

## Pattern 95 — Deterministic harness for a producer running on its own thread

**When.** The feature's contract talks about a background producer (a decoder thread, a prefetcher, a
worker pool): how often it seeks, what it has buffered when a command arrives, what it does at start.
Quality reviews reject event-order assertions and internal constants (buffer sizes), and wall-clock
settle loops read as flaky.

**Build.**
1. A fake producer that logs every call into a `Mutex<Vec<Event>>` plus a `Condvar`, so tests wait for
   a condition ("at least N decodes", "a Blocked event") with a long timeout only as a failsafe.
2. A gate with a CALL budget that blocks calls from any thread except the one that built the fake, and
   logs `Blocked` when it stops. Budget 0 isolates work done synchronously inside construction/`play()`
   (the startup seek budget); a small budget freezes the backlog while a command is sent.
3. Compare, do not count: measure seeks against a plain configuration whose wraps land on the same
   output frames, so buffer size cancels out. Check order only inside a window between two events that
   every correct implementation must emit (one seek, then increasing decode positions, per pass).

**The trap in the harness (L70).** The gate bounds producer CALLS, not OUTPUT. Any assertion on output
behind the gate must stay under the worst-case yield of the budget, or render until the first gap.
kira asserted 48 frames behind a 60-call gate, the reference's own ratio, and failed six correct runs.

**Evidence.** kira-loop-crossfade: replaced two failed quality-review assertions (event order, a 16384
buffer constant); stable across 3 plain runs and 5 runs under 2x CPU oversubscription; its startup test
caught the reference's own double seek at start 3.

## Pattern 96 — Shim counterfactual: read a compile-wiped batch before paying for another

**When.** A batch reads 0% because every run fails ALL new tests with the same compile error on a symbol
the solution adds (a static vs instance method, a parameter type, an enum payload). The batch measured
nothing about difficulty, and the description fix that follows is solver-visible, so the next batch is
full price with no re-eval.

**Build.**
1. Fresh clone at BASE per run: apply the agent's saved `solution-patch.patch`, then your `test.patch`.
2. Insert a one-line adapter into the agent's code that maps the tested shape onto theirs, for example
   `public static List<Path> files(Path p) { return load(p).files(); }`. Skip runs that already have
   the tested shape.
3. Run the new suite and record per-test failures with an XML parser, never a regex.

**Read it as.** An upper-bound estimate of the next batch's rate and kill table. It cannot see what
agents would write once the description changes (L35), and an adapter can hide a real semantic gap, so
check each killer's failure message before trusting the table. Classify each killer as fair or
under-specified while the description is still open, and fix every under-specified one in the same
paid round.

**Evidence.** planetiler-custommap-schema-composition: batch 1 0/8 on `files(Path)`. Shim replay: 2/8,
top killer `remove_of_layer_added_by_the_same_file_is_an_error` 5/8, plus two under-specified cells
(absolute `extends` in a string schema, a missing LAST list entry) fixed in meta before paying. Batch 2:
3/10, same top killer 7/10, accepted.

## Pattern 97 — Keep Verify Solution's test sets clean when the feature changes existing expectations

**When.** The feature deliberately changes behaviour that existing repo tests pin, so some of those
tests need new expectations; or the repo's test titles contain characters the grader uses in IDs.

**Build.**
1. Do not edit the existing spec file in place. Delete the superseded cases from it and re-create them,
   with their new expectations, in your new spec file. The original file then stays in base mode,
   where its untouched cases pass with and without the solution.
2. Make every new-mode test fail on base. Rebuild any case where today's behaviour happens to produce
   the new answer (reorder the declared variations, start from an interleaved allocation).
3. `grep -c "::"` the generated JUnit. If repo titles contain it, normalise in test.sh after the runner
   and confirm there are no duplicate `(classname, name)` pairs.
4. Assert on the rendered output wherever the prose leaves the return shape open.

**Evidence.** featurevisor-minimal-rebucketing: Verify Solution failed on 18 base-passing new-mode tests
(10 of them untouched `traffic.spec.ts` cases), then on 314 phantom extras from `describe("... :: ...")`
titles, then the Auto Review flagged a formatter return-shape pin that had cost 7 kill events. After
all four fixes: 34/34 new tests failing on base, clean sets, approved.


## Pattern 98 — When two review checkers contradict each other, let the description decide

**When.** One checker (Solution Quality) demands a behaviour and a test for it; another (Test Quality)
then rules that test unfair because the description does not state it. Deleting the test fails the
first; keeping it fails the second.

**Build.**
1. Check whether the behaviour is a reasonable reading of the existing contract. If it is, add the
   missing noun or clause to the ONE sentence that already covers the family (here: "an unknown key
   in an event, condition, action or spawned object's mapping").
2. Keep the test and the reference behaviour unchanged.
3. Make the edit before the first batch, or accept that it forfeits re-eval for that round.

**Evidence.** ir-sim-scenario-events: round 2 Solution Quality required creation-time `ValueError` for
unknown spawn-template keys (the base only warns when the object is built); round 4 Test Quality ruled
the test unfair. One added noun in meta.md cleared both; the final Auto Review scored the description
3/3.

## Pattern 99 — Seeded equivalence corpus against the repo's own evaluator

**When.** The feature transforms something the repo can also evaluate (a datafile the SDK reads, an IR the
interpreter runs, a query the engine executes), and the contract is "evaluates the same after the
transformation".

**How.**
1. A deterministic PRNG (mulberry32 with fixed seeds) generates small but deep inputs: every operator,
   empty containers, containers nested under operators, decided and undecided leaves.
2. For each input and each of a few fixed partial contexts, compare the repo's evaluator on the original
   (with the context merged) against the evaluator on the transformed output, over a small context grid.
3. Group seeds into batches of about five and check that EVERY batch fails on base; a single seed can be
   base-equivalent by chance.
4. Keep hand-written shape tests beside it for what equivalence cannot see (what was removed).

**Evidence.** featurevisor-target-specialization: 8 batches of 5 seeds. They caught the nested-list arm in 3
of 20 runs and a `not` over a decided-false child, while twenty hand-written structural cells killed one run.
The FP panels re-ran their own broader fuzzers and upheld every pass.

## Pattern 100 — Dual-runtime ABI oracle for code generators

**When.** The feature makes a generator emit code for a second language whose runtime must agree with the
first (FFI bindings, schema-to-struct generators, serializers). The contract is "same size and offsets".

**How.**
1. Put each fixture in the test file through a `fixture!` macro that both COMPILES the items (so the
   source compiler's `size_of`/`offset_of!` are the oracle) and `stringify!`s them as generator input.
   No expected offset is ever typed by hand.
2. Assert the emitted layout attribute, every `FieldOffset`, and the Size against that oracle.
3. Outside the suite, compile the generated target-language file on the real target runtime and compare
   its `sizeof` per type against the oracle. Run it after every solution change; regenerate first (a
   stale generated file once "failed" to compile).
4. Keep a programmatic audit that every generated fixture is asserted (L79).

**Evidence.** csbindgen-struct-layout-fidelity: 85 fixtures, identical on Rust and .NET 8 at every round.
The runtime check settled two reviewer claims (C# `Int128` alignment 16 on .NET 8 vs 8 before it;
`MarshalAs` on `fixed bool` makes `Marshal.SizeOf` throw).

## Pattern 101 — Convergence triage before a description delta

**When.** A batch reads over the ceiling and you are about to spend a round on more test cells.

**How.**
1. Build a replay image from a pristine BASE clone plus the Dockerfile. For each saved run, keep only the
   `diff --git a/(src|include)/` blocks of `solution-patch.patch`, apply them and the candidate
   `test.patch`, and run new mode. Check it reproduces the batch exactly before trusting it: for a
   tests-only delta it then predicts the re-eval (L40).
2. Write a probe program that prints one canonical `name=value` line per contract cell (boundaries,
   validation, every shape kind, instants, reload) and wrap each cell in a catch-all so an exception is a
   value. Build it against every saved solution and the reference; diff.
3. If the passers agree with the reference on every cell, stop adding cells (L83). Grep the persistence
   and aggregate layers for state the repo discards and design one behavioural sentence around it
   (F-47). That is a description delta: pay for a batch.

**Evidence.** libspatialindex-tpr-temporal-knn: the replay reproduced batch 1 run for run; 57 probes x 7
passers showed 0 divergences and 16 candidate tests 0 new kills; the discarded end-of-motion field moved
the rate 7/10 -> 5/12, accepted. The same replay later showed batch 2's 0/10 was an assertion of mine
(0/10 -> 5/10 with it removed).

## Pattern 102

**Repair a 0% batch by replay, not by redesign.** When a batch reads 0% and the saved solution
patches exist, every candidate repair has a measurable rate: apply each agent's patch to base plus a
CANDIDATE test suite in the platform image and count passes. This prices the options against each
other before any of them is committed.

Measured on siliconcompiler-flist-roundtrip (batch 1, 0/11, 11 saved patches):

| Candidate repair | Replayed rate |
|---|---|
| fix the helper's reference-only API call + the ambiguous spelling sentence | 0/11 |
| ... also cut the `file://` data-root case | 3/11 |
| ... also clarify the edge-ownership sentence | **9/11** |

The third row is the point. All three edits look like the same class of fairness repair; only the
replay shows that one of them removes the problem's only real trap. Live batch 2 then measured 2/10
against the 3/11 projection.

Two caveats. The replay measures a TEST delta, so a repair that changes the DESCRIPTION (here, the
spelling sentence) can only be modelled by excusing the tests it governs — L35's discount applies in
reverse. And cut a requirement in all three places at once (tests, contract sentence, reference), or
the next review scores the coverage gap the description still promises.

## Pattern 103 — Boundary table for a two-class contract

When the contract splits calls into two behaviour classes (atomic vs stepwise, validated vs raw,
charged vs exempt), build a table before writing meta.md:

1. List every public entry point that reaches the primitive the rule changes, including the repo's own
   helpers: `grep -rn "self\.create_dir(" pkg/`.
2. Place each one in a class, and name at least one member of EACH class in meta.md. Every call a test
   exercises must be placed by name.
3. For each repo helper routed through the primitive but placed in the other class, write the test
   that tells the classes apart. That is the F-20 repo-helper cell and it costs no description words.

Measured on pyfakefs-block-inode-accounting. Naming only the stepwise class moved five unchanged
`create_dir`/`create_file` rollback tests from 0/11 to 9-10/12 kills; naming both sides took them to
0/10. The helper cell (`add_real_directory` builds parents via `create_dir`, contract keeps them)
killed 3/10 in the accepted batch and was the sole failure of one near-miss.

## Pattern 104 — Replay gate for review-requested tests

**When.** A batch has run and its solution patches are saved, and a review round asks for a new test.

**How.** Replay the saved patches against the suite WITH the candidate test before shipping it (keep
each patch's source hunks only, apply the candidate `test.patch`, run new mode). Then:

| Replay result | Action |
|---|---|
| Kills only runs that already fail | Ship it |
| Kills the near-misses, and meta.md does NOT state the requirement | The replay is measuring an undocumented rule. State it literally with one example, then ship the test |
| Kills the near-misses, and the requirement IS stated | Cut it in the tests, the contract sentence and the reference together, or keep it and accept the rate |
| Kills runs through an argument the rule does not govern | An accidental trap (L92): fix the fixture value |

Read the assertion diff for every kill before choosing a row; a test name only says which rule the test
was for.

**Evidence.** pyocd-sequence-expression-kernel, eight review rounds after batch 1: most candidates cost
nothing; JTAG byte responses, `DAP_WriteABORT` and a string-returning statement each replayed at
0/11. The byte test, once stated in meta.md with an example, killed 0/10 in the accepted batch. The
replay projected 2/11 for the final suite and batch 2 read 5/10, which is the L35 discount for the
description changes made along the way.

## Pattern 105 — Stub-backend end-to-end test for driver wiring

**Problem.** A contract says the driver (compiler, build tool, pipeline runner) builds the feature and
hands it to every unit it processes. Unit tests of the feature cannot see the wiring, reviewers flag
the sentence "untested", and Solution Quality checks every mode of the driver, not the one you wired.

**Procedure.**
1. Find the driver's backend SPI (TeaVM: `TeaVMTarget`) and stub it: empty transformers, listeners and
   extensions; the output hook (`emit`) records the processed program of the units under test.
2. Build the smallest class/source set the driver accepts. For TeaVM: `java.lang.Object` with
   `setParent(null)` (the default parent is itself, and dependency analysis spins), `java.lang.String`,
   and an entry class with `main(String[])`.
3. Pick a fixture only the feature can change: a virtual call with two implementations, so no
   devirtualization or inlining removes the null check first. Confirm base leaves it at every level.
4. Loop over EVERY mode, level or pipeline enum value. Use a second unit in another class, kept out of
   inlining by the stub's filter, so "every unit" means more than the entry point.
5. Do not assert frequency or timing ("once per build"); drop such words from the contract (L96).

**Measured.** teavm-method-summaries: the loop over `TeaVMOptimizationLevel.values()` caught the
unwired `SIMPLE` lazy pipeline that Solution Quality found, runs in 37 s, and killed 0/10 in the
accepted batch. It is non-regression insurance, not difficulty.
