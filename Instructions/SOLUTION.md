# SOLUTION — How to Write solution.patch

Match the repo's style exactly — as if submitting a PR to the project.

> **Read first:** `PLAYBOOK.md` § Pattern 3 + Patterns 11–13 — helper extraction, fixpoint loop shapes, recursive AST traversal patterns, shape-specific solution structures from 13 approved problems.

---

## The Golden Rule

> Write code as if submitting a PR to a real open-source project — match the repo's style exactly.

Reviewers compare your code side-by-side with existing repo files. If your solution "looks different," it gets flagged.

### Hard Reject (Unfixable)

- Solution patch is **not a valid git patch** → hard reject
- Solution contains **malicious code** → hard reject
- Solution is **trivial one-liner** (too easy — verify with AI checks) → hard reject

Everything else (bugs, debug code, unrelated changes, API breaks, code quality) → **Request Change**, not reject.

---

## Core Rules

1. **Solve exactly what the description asks** — no more, no less
2. **Match repo conventions** — naming, patterns, error handling, comments
3. **No new internet dependencies** — solution must work offline
4. **solution.patch has ONLY source files** — no tests, no Dockerfile, no docs
5. **No conflict with test.patch** — apply in either order
6. **Address root cause** — not workarounds that just make tests pass
7. **No test gaming** — no hardcoded test-specific values

---

## Code Style

### MUST do
- Match existing variable naming (short if repo is short, verbose if verbose)
- Match existing comment style (no comments if repo has none; docstrings if repo uses them)
- Match existing logic patterns (switch/case vs if-else, map lookups vs branches)
- Match existing error handling
- Match existing function length norms
- Reuse existing utility functions (don't reinvent)
- Place code in the correct file (match repo organization)
- Extend existing infrastructure (prototypes, intrinsics, base classes) — not replacements
- Use explicit variable names over inline expressions
- Handle edge cases and maintain backward compatibility
- Add doc comments on new exported types/functions iff repo pattern uses doc comments

### MUST NOT do
- Comments unless repo has comments (then match style)
- Debug statements (`console.log`, `print`, `fmt.Println`, `dbg!`, `eprintln!`)
- `// TODO:`, `// FIXME:`, `// NOTE:`, `// Pass 1:`, `// Step 2:` markers
- Leftover commented-out code or alternative implementations
- Unused variables or imports
- Dead code (unreachable paths, empty blocks, assigned-but-never-used variables)
- `as any` type casts (use proper types)
- AI slop (verbose boilerplate, over-commented, auto-generated patterns)
- Extra features beyond description (scope creep)
- Code duplication (extract helpers)
- Hardcoded test-specific values
- Workaround-only fixes (address root cause)
- Speculative defensive guards not required by spec
- Breaking existing function signatures (add optional params, don't modify required ones)
- Creating new replacements for existing constructors/prototypes/globals
- New internet dependencies — solution must not require fetching new packages at runtime

---

## Complexity Requirements

### Platform minimums (hard floor)

| Tier | LOC | Files | Agent steps |
|---|---|---|---|
| **Mars** | 100+ raw | 1+ | 1+ message |
| **Olympus** | **400 EFFECTIVE LOC (HARD — auto-review triggers below)** | 3+ | 100+ steps |
| **Diamond** | **400 EFFECTIVE LOC (HARD — same as Olympus)** | 3+ | 100+ steps |

**Auto-reviewer effective-LOC formula = raw added − blank − comment-only. BRACES ARE KEPT (counted); comments are NOT.** Verified against platform: cel-go `575 raw − 48 blank − 160 comment = 367`. `raw × 0.65` is a rough sketch-time estimate only — NOT the auto-reviewer's method. **This is our primary, canonical method — use it.**

**TWO gates, design to clear BOTH.** (1) the AUTO formula above (braces KEPT, imports/package KEPT, ≥400) = the platform auto-block. (2) the HUMAN reviewer's "meaningful LOC" is STRICTER and BINDING (reviewer Nandish 2026-07), measured on the PASSING AGENT's diff. It EXCLUDES: blank lines; comment-only lines; trivial no-ops (`pass`, `continue`, `break`, `return None`, `return nil`); generated files; TEST files; package declarations; imports (`using`/`use`/`namespace`/`from x import y`) + import-block contents + closing `)`/`}`; braces/punctuation-only lines (`{`, `}`, `);`, `,`); and package/import/brace-heavy boilerplate. Repetitive registry/match families amortize to ~the pattern. It rejects under 400; a green auto-gauge or an AI LOC waiver is NON-BINDING against it (sqlglot-window-functions: raw 547, AI waived, human re-counted under 400, NOT resubmittable; pomsky-conditionals 456 braces-kept → 373 stripped → Mars). The `.claude/hooks/effective_loc_check.py` Stop hook predicts THIS human re-count (its `human-effective` = strip method) AND flags breadth-padding (when its `padding-floor` << `human-effective` → add orthogonal DEPTH, not more breadth). **Design to ≥450 under Counter 2 (human-meaningful) so Counter 1 clears automatically** — never lean on repetitive breadth or brace/import boilerplate.

Pre-submit verify for Olympus/Diamond — PRIMARY = Counter 2 (the hook's `human-effective`), gate ≥ 450:
```bash
# PRIMARY (Counter 2 — the reviewer's meaningful count): gate on this >= 450
python .claude/hooks/effective_loc_check.py solution.patch   # read `human-effective:` line

# SECONDARY (Counter 1 auto-block, braces + imports kept) — confirm-only, clears once Counter 2 >= 450
f=solution.patch
raw=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | wc -l)
blank=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | grep -cE '^\+\s*$')
comment=$(grep -E '^\+' "$f" | grep -vE '^\+\+\+' | grep -cE '^\+\s*(///|//|/\*|\*)')
echo $((raw - blank - comment))   # >= 400 auto-block (by-product of Counter 2 >= 450)
```

**Comments count for ZERO** — heavy doc-commenting does NOT clear the floor. Real code + braces does.

Blank lines, artificial inflation, filler, or dead code to bump count → rejected (Real Revert Cause). Near-threshold accepted (e.g., 338 effective, 2 files for Olympus) **ONLY** if genuinely difficult AND auto-review tolerates — risk is real, prefer comfortable 450+ buffer.

### Mars Sweet Spot (April 2026, evidence-based)

The platform floor is 100 LOC; the sweet spot is **170–380 LOC across 1–8 files** (Mars file count ranges 1–15 if D-new shape).

| Mars Rank | Files | +LOC | Nova Pass |
|---|---|---|---|
| Entry | 1–3 | 100–200 | 50–70% |
| **Solid** (default) | **1–15 (mode 3)** | **170–380** | varies by shape (10-55%) |
| Strong | 6–12 | 400–600 | 10–30% |

### Solution structure by shape (evidence-based)

| Shape | Example | Files | +LOC | Solver/our LOC | Best agent | Pattern |
|---|---|---|---|---|---|---|
| Mars A1 (distributed) | lightningcss-selector-simplify-fixpoint | 3 dist | 167 | 2.07× | Nova→Orion (slow) | Modify pipeline files of similar weight |
| Mars A2 (concentrated + sig) | pest-factorizer-fixpoint | 3 conc | 220 | 1.71× | Nova→Orion (fast) | 1 main file + thin wiring + signature change |
| Mars B (new public API) | pest-unused-rule-elim | 3 (2 new) | 377 | 1.28× | Orion-alone | New module + thin wiring (additive) |
| Mars C (additive ext.) | pest-validator-hardening | 1 dense | 358 | 1.02× | Nova→Orion | Single file, additive functions |
| Mars D-new (new variant) | pest-error-recovery | 15 (4 crates) | 400 | 1.44× | Orion-alone | New variant + exhaustive matches |
| Mars D-change (sig change) | pest-extended-skip | 8 multi-crate | 340 | 1.07× | Nova→Orion + Vega | Existing variant signature change |
| Olympus O-Composite-extend | dagster-dep-health | 9+ | 600 | 0.98× | Orion (2/2) | Refactor across packages |
| Olympus O-Composite-add | goja-using-declarations | 12 | 366 | 2.13× | Vega | Cross-subsystem feature add |
| Olympus O-Pipeline-easy | pest-charclass | 5 | 433 | 1.81× | Vega | Pattern coalescing |
| Olympus O-Pipeline-hard | pest-seq-rewriter | 4 | 413 | 1.78× | Vega | Invent transformation |
| Olympus O-Algorithm-coverage | pest-inliner | 4 | 379 | 1.49× | Orion-alone | Coverage trap (multi-pass) |
| Olympus O-Algorithm-correctness | pest-dispatch | 6 | 532 | 1.27× | Mixed | Algorithmic correctness trap |

Median Mars: 340 LOC, 3 files. Single-file (validator-hardening, Shape C) approved when dense within one module. 15-file (error-recovery, Shape D-new) approved when crossing crates with thin per-file changes.

If sketched solution is <167 LOC → too small, expand scope or pick another shape. If >600 LOC across 10+ files → Olympus territory, upgrade tier.

### Olympus Ranks

| Rank | Files | +LOC | What It Looks Like |
|---|---|---|---|
| Okay | 3–10 | 400–600 | Touches one subsystem deeply |
| **Good** (target minimum) | 10–20 | 600+ | Spans multiple subsystems |
| **Excellent** (goal) | 20+ | 600+ (often 800–1500) | Deeply entangled cross-system |

> File counts and LOC NEVER include test files. Tests are written by the problem author, not the agent.

Agent metrics (messages, LOC, steps) are a **consequence** of problem design, not targets. Our solution is optimal/clean — agents write 2–3× more because they explore and backtrack.

### What this means
- If your solution is under 400 lines (Olympus) → the issue is probably too easy, pick a harder one
- Don't artificially inflate — genuinely complex problems produce long solutions naturally
- Feature requests naturally produce larger solutions than bug fixes
- **Near-threshold is accepted:** solutions slightly below thresholds (e.g., 338 lines or 2 files) have been approved if the challenge is genuinely difficult

### Proven solution structure
In approved Olympus problems, the most common pattern is:
- **1 new core file** containing the main feature implementation (e.g., `scheduler.py`, `_retry.py`, `subquery.py`, `snapshot.go`)
- **2-5 modified existing files** for integration (imports, exports, wiring, config)

This pattern naturally produces 400-1000+ lines across 3-6 files.

---

## Real Approved Solution Stats

### Bug Fixes
| Problem | Lines | Files | Language |
|---|---|---|---|
| elysia-1382 | 221 | 2 | TypeScript |
| elysia-1586 | 171 | 1 | TypeScript |
| elysia-1380 | 171 | 1 | TypeScript |
| elysia-1477 | 141 | 1 | TypeScript |
| happy-dom-1283 | 136 | 1 | TypeScript |
| elysia-1474 | 126 | 2 | TypeScript |
| elysia-1445 | 120 | 2 | TypeScript |
| elysia-1486 | 119 | 1 | TypeScript |
| elysia-1504 | 103 | 2 | TypeScript |
| khal-1406 | 95 | 2 | Python |
| opentelemetry-6190 | 92 | 2 | TypeScript |
| attrs-734 | 75 | 1 | Python |
| beets-6010 | 39 | 1 | Python |

**Bug fix average: ~108 lines, ~1.4 files**

### Feature Requests
| Problem | Lines | Files | Language |
|---|---|---|---|
| goja-iterator-helpers | 612 | 3 | Go |
| sh-diff | 529 | 1 | Go |
| sh-1165 | 413 | 1 | Go |
| cron-parser-dst | 401 | 2 | TypeScript |
| yaegi-1674 | 360 | 4 | Go |
| goja-weakref | 320 | 3 | Go |
| wazero-debug | 314 | 8 | Go |
| wazero-func-stats | 282 | 8 | Go |
| wazero-callgraph | 259 | 7 | Go |
| goja-memory-limit | 237 | 4 | Go |
| wazero-memory-trace | 234 | 4 | Go |
| goja-decorators | 206 | 7 | Go |
| dooit-115 | 189 | 5 | Python |
| wazero-fuel-metering | 180 | 7 | Go |
| bunster-131 | 180 | 2 | Go |
| goja-coverage | 111 | 3 | Go |
| bunster-285 | 93 | 4 | Go |
| goja-659 | 73 | 1 | Go |

**Feature request average: ~279 lines, ~4.1 files**

### Key observations
1. Feature requests are ~2.5x larger than bug fixes in lines
2. Feature requests touch ~3x more files
3. Go feature requests consistently touch 3-8 files (interfaces + implementations + registrations)
4. Bug fixes often touch just 1-2 files (the broken code + maybe one related file)

---

## Helper Extraction — Universal Pattern

Every approved Mars solution extracts ≥1 pure-function helper at module scope. Each helper = a unit of behavior the description names. The 1:1 mapping (description requirement ↔ helper function) is what makes solutions readable and tests deterministic.

| Approved | Notable helpers extracted |
|---|---|
| extended-skip | `try_flatten_str_seq`, `normalize_skip_choices` |
| factorizer | `flatten`, `rebuild`, `factor_choice`, `merge_alternatives` |
| unused-rule-elim | `compute_reachable`, `referenced_idents`, `build_rule_map` |
| validator-hardening | `is_always_failing`, `validate_repminmax_bounds`, `validate_invalid_ranges`, `validate_contradictory_predicates`, `validate_push_inside_negpred`, `validate_always_failing_alternative` |
| lightningcss | `simplify_selector`, `simplify_component_in_place`, `try_unwrap_double_negation_single` |

---

## Fixpoint Loops — Explicit Shape

When the description says "iterate to a fixpoint" or "until no rewrites apply":

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

---

## Recursive AST Traversal with Cycle Trace

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

---

## Wire Features End-to-End Through the Real Entry Point (Principal Reviewer Rubric #7)

If the description says a feature is a CLI flag, API endpoint, or config option, the solution MUST hook it up through the real entry point AND tests MUST exercise it through that entry point.

- **CLI flag** → register in the flag-parsing layer; test by invoking the CLI (`dasel -r csv --csv-separator=';' ...`), not by calling the internal handler
- **Config option** → wire into config load; test by loading config, not by setting the struct field directly
- **API endpoint** → wire into the route; test through the route, not the controller method
- **Self-registering parser** → add the blank import (`_ "github.com/.../parsing/kdl"`) to the entry point; the parser existing but never loaded is a correctness gap

Testing through internal constructors or bypassing the framework when the feature is user-facing = near-reject. The reviewer checks that the feature is reachable the way a real user would reach it. See `PRINCIPAL-REVIEWER-RUBRIC.md § 7`.

---

## Modified vs New Files — The Real Difficulty Lever

The modified-to-new ratio matters more than total file count. Creating new files is easy; modifying existing code requires understanding what's there and how changes propagate.

**Good Mars Solid pattern:** 0–2 new + 1–8 modified (median: 0 new + 3 modified).
**Good Olympus pattern:** 1–3 new + 8–35 modified (imports, wiring, integration hooks).
**Bad pattern (both tiers):** 5+ new standalone files with minimal modifications.

If an agent can solve by mainly creating new files without deeply modifying existing code, the problem is too easy.

| Files | Rank | New/Modified Ratio | Example | Pass Rate |
|---|---|---|---|---|
| 2-4 | Okay | 1 new + 1-4 modified | httpx-retry, pest problems, canopy | 8-30% |
| 6 | Okay | 1 new + 4-5 modified | ormar-subquery, pest-dispatch | 8-20% |
| 12 | Good | 2 new + 10 modified | goja-using | 25% |
| 17-23 | Excellent | modified dominant | FoalTS reference | 22% |

### Approved file patterns

| Patch | New files | Modified files |
|---|---|---|
| canopy | `store/snapshot.go` | `store/store.go` |
| h2 | `src/h2/scheduler.py` | `config.py`, `connection.py`, `events.py` |
| httpx | `httpx/_retry.py` | `__init__.py`, `_client.py` |
| ormar | `queryset/subquery.py` | `__init__.py` (×2), `filter_query.py`, `query.py`, `queryset.py` |
| oxvg | `jobs/merge_defs.rs`, `utils/resource_fingerprint.rs` | `jobs/mod.rs`, `utils/mod.rs` |
| bumpp | (none) | `normalize-options.ts`, `version-bump-options.ts`, `version-bump.ts` |
| pest-inliner | `optimizer/inliner.rs` | `optimizer/mod.rs`, `generator.rs`, `vm/lib.rs` |
| pest-charclass | `optimizer/coalescer.rs` | `optimizer/mod.rs`, `generator.rs`, `vm/lib.rs`, `grammars/lib.rs` |
| pest-error-recovery | `error_recovery.rs` | 14 files across 4 crates (parser_state, generator, vm, ast, optimizer, queueable_token, 4 iterator files, validator) |

---

## Code That Did NOT Get Flagged

- ✅ `expect("...")` panics on builder helpers (test/build invariants)
- ✅ `unwrap()` after `let Some(...) = ...` short-circuit when correctness is local
- ✅ Cloning in fixpoint loops (`current.clone()`)
- ✅ `std::mem::take` to avoid borrows
- ✅ `HashMap` vs `BTreeMap` when description doesn't constrain order
- ✅ Module-private helpers without `pub`

## Code That WOULD Be Flagged

- ❌ `// TODO`, `// FIXME`, `// NOTE` markers anywhere
- ❌ `println!`, `eprintln!`, `dbg!`, `console.log`
- ❌ Commented-out alternative implementations
- ❌ AI restatement comments (`// Loop through items`)
- ❌ Speculative extra-feature code not in description
- ❌ Unrelated refactors (style tweaks, import reordering in unrelated files)
- ❌ Breaking existing function signatures when overload would work

---

## Comment Convention — Match the Repo

Not a blanket ban. Approved patches by language:

| Repo / language | Comments? | Why |
|---|---|---|
| canopy (Go) | Yes — doc comments on exported functions | Repo convention |
| h2 (Python) | Yes — docstrings AND inline comments | Repo convention |
| oxvg (Rust) | Yes — `///` doc comments on structs | Repo convention |
| httpx (Python) | Yes — docstrings on functions | Repo convention |
| bumpp (TS) | No | Repo has none |
| ormar (Python) | Yes — docstrings on methods | Repo convention |
| pest (Rust) | Minimal — sparse style | Repo convention |
| goja (Go) | Yes — doc comments on exported symbols | Repo convention |

If repo source files have doc comments → yours must too. If they don't → yours don't.

**Always banned regardless of repo:**
- AI markers (`// NOTE:`, `// TODO:`, obvious restatements)
- Category headers (`// Phase 1: Setup`, `// Step 2: Process`)
- Comments when nearby repo files have none
- Verbose explanatory commentary

---

## LOC Estimation Discipline

**Estimate from a sketched solution, not from a worst-case file walk.** Walking each file and assuming maximum edits ("~110 LOC for parser_state.rs", "~45 for pairs.rs") consistently overshoots reality by 50–75%.

**Calibration data — pest-error-recovery (April 2026):** Design walked 15 files and estimated 705 LOC. Reality was 398 meaningful LOC. Modern languages catch missing match arms with `..` patterns; threading a parameter through 35 call sites costs ~5 lines, not ~35.

**Process:**
1. Sketch the actual reference solution for the 2–3 hardest files in real code
2. Count those files' real LOC
3. For the rest, multiply by file count with a 0.7 coefficient for boilerplate-heavy files
4. Round to nearest 50; don't claim precision you don't have
5. If you can't sketch the hardest file, you don't understand the problem well enough

**Report raw AND meaningful.** `git diff --numstat` raw additions is what reviewers quote; meaningful (raw minus license, blanks, lone braces, imports) is the real solving effort. Healthy Mars Solid: ~200–300 raw / 130–200 meaningful. If raw is in band but meaningful is under 100, the solution is LOC-padded with boilerplate.

---

## Matching Repo Style (Critical)

### Step 1: Analyze 2-3 existing source files

Before writing any code, open comparable files and note:
- **Variable names:** Short (`c`, `e`, `p`) or verbose (`candidate`, `element`)?
- **Comments:** None? Doc comments on functions? Inline comments?
- **Error handling:** Return error? Panic? Log and continue?
- **Function length:** 10 lines? 50? 200?
- **Logic patterns:** Switch/case? If-else? Map lookups? Table-driven?

### Step 2: Match exactly

| Repo style | Your solution |
|---|---|
| No comments | No comments |
| Doc comments on all exported types | Doc comments on all exported types |
| Short variable names (`c`, `e`) | Short variable names (`c`, `e`) |
| Uses `fnTable` map for dispatching | Add entry to `fnTable`, not if-else |
| Helper functions for repeated logic | Extract helpers, not inline |
| Error returns `fmt.Errorf("...")` | Error returns `fmt.Errorf("...")` |

### What gets flagged
- "Remove all comments from solution — repo files have none"
- "Repo uses short names (`c`, `e`, `p`) but solution uses verbose (`candidateCount`)"
- "Solution uses if-else chain but repo uses map lookups (see fnTable)"
- "Solution has explanatory comments when repo has none"

---

## Solution Patterns by Language

### Python — New feature module (httpx)

New `httpx/_retry.py` with `Retry` class. Add `from ._retry import *` to `__init__.py` (with `__all__` defined). Add `retry` param to `Client.__init__` and `Client.request`.

### Python — Extending existing ORM (ormar)

New `subquery.py` with `Subquery`, `OuterRef`, `Exists` classes. Modified `filter_query.py` to resolve subquery clauses. Wired through 4 existing `__init__.py` files. 6 files, 392 added lines.

### Python — Bug Fix (attrs, modify existing method)

```python
def _exc_reconstruct(cls, positional_args, state):
    kw_only_aliases = {
        a.alias for a in cls.__attrs_attrs__ if a.init and a.kw_only
    }
    kw_only_kwargs = {k: v for k, v in state.items() if k in kw_only_aliases}
    obj = cls(*positional_args, **kw_only_kwargs)
    for name, value in state.items():
        if name not in kw_only_aliases:
            _OBJ_SETATTR(obj, name, value)
    return obj
```

**Key patterns:**
- No comments
- Uses existing helpers (`_OBJ_SETATTR`)
- Explicit variable names (`kw_only_aliases`, `kw_only_kwargs`)
- Handles both cases (kw_only and non-init attrs)

### Python — Bug Fix (beets, extend existing logic)

```python
dest_syspath = util.syspath(dest)
if os.path.exists(dest_syspath):
    source_mtime = os.path.getmtime(util.syspath(original))
    dest_mtime = os.path.getmtime(dest_syspath)
    source_is_newer = source_mtime > dest_mtime

    if force:
        self._log.info(
            "Reconverting {.filepath} (force enabled)", item
        )
        if not pretend:
            util.remove(dest)
    elif source_is_newer:
        self._log.info(
            "Reconverting {.filepath} (source file modified)", item
        )
        if not pretend:
            util.remove(dest)
    else:
        self._log.info(
            "Skipping {.filepath} (target file exists)", item
        )
        continue
```

**Key patterns:**
- Uses repo's utilities (`util.syspath`, `util.remove`)
- Matches repo's logging style (`self._log.info`)
- Verbose explicit logic (not compact ternaries)
- Extends existing if-else block naturally

### TypeScript — Bug Fix (elysia, fix request handling)

```typescript
const handler: Handler = ({ request, path }) => {
    const clonedRequest = request.clone()
    const newUrl = replaceUrlPath(clonedRequest.url, path)
    const newRequest = new Request(newUrl, clonedRequest)
    return run(newRequest)
}
```

**Key patterns:**
- Replaced 15 lines of manual property copying with 3-line `request.clone()`
- Uses explicit intermediate variables (`clonedRequest`, `newUrl`, `newRequest`)
- Matches repo's existing handler pattern
- No comments needed — code is self-evident

### TypeScript — Bug Fix (elysia, add guard logic)

```typescript
const shouldSkipBodyParsing =
    hooks.parse?.length === 1 &&
    typeof hooks.parse[0].fn === 'string' &&
    hooks.parse[0].fn === 'none'

let body: string | Record<string, any> | undefined
if (request.method !== 'GET' && request.method !== 'HEAD') {
    if (content && !shouldSkipBodyParsing) {
```

**Key patterns:**
- Extracted condition to named boolean (`shouldSkipBodyParsing`)
- Applied the guard at every relevant point in the file
- Consistent with repo's existing guard patterns

### TypeScript — Extending existing code (bumpp)

No new files. Modified 3 existing: added `workspaceConventional` option type, normalization, main bump logic. Used repo's existing imports (`semver`, `tinyglobby`, `yaml`). 520 added lines.

### Go — New feature file (canopy)

`store/snapshot.go` (966 lines, new). Uses repo's error type (`lib.ErrorI`), existing store methods, naming conventions. Magic constants follow repo style.

### Go — Multi-file language feature (goja)

12 files. Two new (`builtin_suppressed_error.go`, `vm_using.go`). Extended compiler, parser, VM. Used existing intrinsic registration patterns, prototype chain builders, bytecode instruction format.

### Go — Feature (goja, new runtime type)

```go
type weakRefObject struct {
    baseObject
    m      weakRefMap
    target *Object
}

func (wr *weakRefObject) init() {
    wr.baseObject.init()
    wr.m = weakRefMap(wr.val.runtime.genId())
}

func (r *Runtime) weakRefProto_deref(call FunctionCall) Value {
    thisObj := r.toObject(call.This)
    wro, ok := thisObj.self.(*weakRefObject)
    if !ok {
        panic(r.NewTypeError("Method WeakRef.prototype.deref called on incompatible receiver %s",
            r.objectproto_toString(FunctionCall{This: thisObj})))
    }
    if wro.target == nil {
        return _undefined
    }
    return wro.target
}
```

**Key patterns:**
- Follows repo's existing type patterns (`baseObject` embedding)
- Uses repo's error pattern (`panic(r.NewTypeError(...))`)
- Uses repo's naming conventions (short names, `Proto_` prefix)
- New file follows same structure as existing builtin files

### Go — Feature (wazero, multi-file solution)

A typical Go feature request touches 7-8 files:

| File | Purpose |
|---|---|
| `api/debug.go` | New public API interface |
| `api/wasm.go` | Register new API in existing interfaces |
| `experimental/debug/debug.go` | Implementation package |
| `experimental/wazerotest/wazerotest.go` | Test utilities |
| `internal/engine/interpreter/interpreter.go` | Hook into interpreter |
| `internal/wasm/debug.go` | Internal implementation |
| `internal/wasm/module_instance.go` | Wire into module lifecycle |
| `internal/wasm/store.go` | Register in store |

This is the pattern for feature requests in well-structured Go projects — you add across all layers.

### Rust — Extending enum + traversals (pest)

Standard pest pattern: 4–5 files. New optimizer file (e.g., `coalescer.rs`) added to `optimizer/mod.rs` pipeline. Modified `generator.rs` and `vm/lib.rs` to handle new `OptimizedExpr` variants in exhaustive matches.

**Key integration points for any pest problem:**
- New `OptimizedExpr` variant → must add to all `match` arms in traversals (`map_top_down`, `map_bottom_up`, `iter_top_down`), Display impl, generator (both normal and atomic modes), and VM
- Register new pass in `optimizer/mod.rs` pipeline

---

## Patch Generation

```bash
BASE_COMMIT=$(cat problems/{reponame}-{issue}/BASE_COMMIT.txt)

# Source files only — NO test files
git diff $BASE_COMMIT -- src/file1.py src/file2.py > solution.patch

# For new (untracked) files
git add src/new_module.go
git diff --cached -- src/new_module.go >> solution.patch

# For mixed (modified + new files)
git add src/new_module.go  # stage new files
git diff $BASE_COMMIT -- src/existing.go > solution_part1.patch
git diff --cached -- src/new_module.go > solution_part2.patch
cat solution_part1.patch solution_part2.patch > solution.patch
```

### Rules
- Always diff against `$BASE_COMMIT` (never HEAD, never origin/main)
- Never include test files (test.sh, test/ directories go in test.patch only)
- Never include Dockerfile
- Specify exact files (don't use bare `git diff $BASE_COMMIT`)

**Exception (R5):** Solution patch CAN include test file changes if an existing test was genuinely broken AND fixing it is directly relevant to the problem. This is rare — applies when old test had a bug your solution exposes or that blocks your work.

### WRONG ways to generate patches
```bash
git diff HEAD -- files        # wrong base
git diff -- files             # wrong base
git diff --cached -- files    # wrong base (unless specifically staging new files)
git diff origin/main -- files # wrong base
git diff $BASE_COMMIT         # no files specified = everything
```

---

## Validation

```bash
git checkout $BASE_COMMIT && git clean -fd
git apply test.patch
./test.sh --output_path /tmp/base.xml base    # PASS
./test.sh --output_path /tmp/new.xml new      # FAIL (no solution yet)

git apply solution.patch
./test.sh --output_path /tmp/base.xml base    # PASS (no regressions)
./test.sh --output_path /tmp/new.xml new      # PASS (solution works)

# Reverse order
git checkout $BASE_COMMIT && git clean -fd
git apply solution.patch
git apply test.patch
./test.sh --output_path /tmp/base.xml base    # PASS
./test.sh --output_path /tmp/new.xml new      # PASS
```

---

## Reviewer Red Flags (from actual feedback)

| Issue | Example |
|---|---|
| Dead code | `_ = negate` assigned but never used; `_temp_steal` allocated but unused |
| Scope creep | `RedactEnv` not in description, untested |
| Wrong package | Errors in `shared/` should be `translatableerror/` |
| Silent errors | Non-map `env` silently not diffed |
| Empty catch | Swallows all errors silently — be specific |
| Magic strings | `"web"` — repo uses `constant.ProcessTypeWeb` |
| Duplicate logic | `validateCharClass` duplicates `matchCharClass` |
| Variable naming mismatch | Repo uses `c, e, p`; solution uses `candidateCount` |
| Reimplementation | Repo has libs for the feature — extend, don't rewrite |
| Proportional size | Existing builtins ~20–50 lines; 480-line solution is over-engineered |
| Breaking API | Changed function signature without justification |
| Workaround fix | Wrapper file + lazy requires instead of root-cause fix |

---

## Real Admin Feedback Patterns

Actual admin comments on solutions:

| Issue | Admin Quote | Fix |
|---|---|---|
| Dead code | "`_ = negate` — variable assigned but never used. Remove." | Remove all unused variables |
| Dead code | "`setFieldNames` defined but never called. Remove." | Remove unused struct fields |
| Wrong package | "Errors in `shared/` — should be `translatableerror/`. Move." | Follow repo's package organization |
| Missing validation | "Zero/negative power not rejected. Requests with `Power: 0` get allocated." | Validate inputs |
| Silent errors | "Non-map `env` silently not diffed. Return error." | Don't silently skip errors |
| Empty catch | "Silently swallows all errors. Be specific (e.g., catch TypeError only)." | Narrow exception types |
| Magic strings | "`\"web\"` — repo uses `constant.ProcessTypeWeb`. Use it." | Use repo's constants |
| Scope creep | "`RedactEnv` not in description, untested. Remove." | Don't add unrequested features |
| Duplicate logic | "`validateCharClass` duplicates logic from `matchCharClass`. Unnecessary duplication." | Extract shared helpers |
| Extra blank lines | "Extra blank line in merge_util.go after function declaration. Remove." | Match repo formatting exactly |
| Hardcoded error msgs | "`An error occurred during disposal` repeated multiple times. Extract to constant." | DRY error messages |
| Unused aliases | "`runExport` accepts `pwsh`/`ps1` aliases but description only specifies `powershell`. Remove undocumented aliases." | Only implement what's specified |

---

## Reviewer Mindset Check

Before submitting, review your solution as if you're a repo maintainer. Flag anything that:

- **Solution-description mismatch** — every behavior in the solution must be traceable to the description. If solution implements NaN handling, -0 conversion, validation rules, or ANY behavior not mentioned in the description → either add to description or remove from solution
- **Unrequested features** — solution adds retry queues, error metrics, callbacks, or other features not asked for → remove them
- **Loses information** — transforms that can't be reversed (round-trip data preservation must be intact)
- **Changes structure implicitly** — flattening, expanding, or normalizing without documenting
- **Hides real errors** — broad `except Exception: pass` or empty catch blocks
- **Depends on assumptions** not enforced by code or tests
- **Silently swallows errors** — optional operators suppressing errors they shouldn't
- **Recover/fallback that changes semantics** — e.g., `DeepCopy` returning original on error instead of erroring (subtle bug)
- **Format-specific logic errors** — output format must match selected target (e.g., YAML→TOML must produce TOML, not JSON); watch for missing branches where new formats fall back to defaults incorrectly
- **Assumptions about input type/structure** without validation — validate data shape before serialization
- **Crashes instead of graceful failure** — if an operation cannot be performed, return a clear user-facing error instead of crashing
- **Unrelated changes** — solution modifies things not related to the problem (e.g., changing global config when only specific logic needs it) → remove them

### Design Requirements
- **No global state issues** — don't introduce mutable global variables or singletons
- **Async/sync behavior preserved** — if function was sync, keep it sync (and vice versa)
- **No hidden side effects** — functions should not modify state beyond their documented purpose
- **No unhandled async chains** — every `.then()` needs a `.catch()`, every async validation must handle rejection
- **Don't reimplement from scratch** — if the repo already has code/libraries for the feature, use and extend them instead of reimplementing with a different approach and internal APIs
- **Proportional solution size** — if existing builtins average 20-50 lines, a 480-line solution for similar functionality is overly engineered and will be rejected

### Breaking API Changes
- Breaking API changes **MUST be justified** by the problem description
- Prefer backward-compatible fixes when possible
- Don't change function signatures unless absolutely necessary
- If API changes are required, ensure they're documented and intentional
- API contract changes without documentation = **breaking change** → flag it

### Problem Category
- Verify the problem category matches what's actually being done (bugfix vs enhancement vs feature)
- If code works correctly and "bugs" are just TODO comments = this is an enhancement, not a bugfix
- If the claimed bug/feature **already exists** in the codebase → reject

---

## Agent-Observed Integration Failures

> Agents build the core feature correctly but fail on integration. Failure modes from 170+ agent runs:

| Pattern | Example | Frequency |
|---|---|---|
| **Missing hook points** | h2: scheduler not hooked into `_begin_new_stream` (4/9 fails) | Very common |
| **Export leaks** | httpx: `from ._retry import *` broke `test_exported_members` (2/7 fails) | Common |
| **Signature changes** | ormar: `FilterQuery.__init__` change broke delete paths (1/8 fails) | Occasional |
| **Wrong config scope** | oxvg: `cleanupIds.mergeDefs` vs top-level `mergeDefs` | Rare |
| **Framework mismatch** | httpx: `asyncio.sleep()` instead of `anyio.sleep()` for trio (4/7 fails) | Very common |
| **Exhaustive match gaps** | pest: new variant missing in VM, generator, or traversals (4/12 fails) | Very common (Rust) |
| **Forced trait bounds** | pest-error-recovery: agent used `Fn` where helper forced `FnMut` | Common (Rust closures, TS generics, Python kwargs) |
| **Aggregation refactor missed** | dagster: `all(UNKNOWN or NOT_APPLICABLE)` needed symmetric refactor for 4th dimension | Very common when extending aggregations |

### Integration rules

1. Wire into ALL relevant code paths — not just the obvious entry point
2. Exports must be explicit — define `__all__` in new modules being star-imported
3. Never change existing function signatures — add optional params
4. Match framework patterns — if repo supports multiple async frameworks, solution must too
5. Handle exhaustive matches — new enum variants must appear in every `match`/`switch`
6. Sketch test helper signatures first — they're the real spec
7. When extending an aggregation dimension, refactor the existing combined check symmetrically — don't just append a branch

---

## Cross-Check: Solution vs Tests vs Description

Before submission, verify alignment across all three:

1. Every behavior in solution → covered by tests
2. Every test assertion → traces to description
3. Every described behavior → implemented in solution AND tested
4. No untested solution code (reviewers flag coverage gaps)
5. No extra solution behavior beyond what's described

Flag anything that is:
- Insufficiently tested (logic exists but no test covers it)
- Only implicitly verified (test passes by accident, not because it validates the behavior)
- Tested but not described (surprise test — add to description or remove test)

---

## Common Mistakes (BAD/GOOD Code)

### Scope creep
```python
# BAD — adding features not in the description
class ConvertPlugin:
    def convert(self, item):
        self.retry_queue.add(item)      # not requested
        self.metrics.track(item)         # not requested
        self._do_actual_conversion()     # this is what was requested

# GOOD — only what the description asks for
class ConvertPlugin:
    def convert(self, item):
        self._do_actual_conversion()
```

### Wrong variable naming
```go
// BAD — repo uses short names but you used verbose
candidateCount := len(candidates)
oneIndexedPosition := idx + 1
matchesCondition := checkReady(c)

// GOOD — match repo's existing style
cnt := len(candidates)
pos := idx + 1
ok := checkReady(c)
```

### Comments when repo has none
```typescript
// BAD — AI-style comments in a repo with no comments
// Clone the request to avoid consuming the body stream
const clonedRequest = request.clone()
// Create a new URL with the correct path
const newUrl = replaceUrlPath(clonedRequest.url, path)
// Create a new request with the correct URL
const newRequest = new Request(newUrl, clonedRequest)

// GOOD — no comments needed, code is clear
const clonedRequest = request.clone()
const newUrl = replaceUrlPath(clonedRequest.url, path)
const newRequest = new Request(newUrl, clonedRequest)
```

### Code duplication
```python
# BAD — same logic in two places
def parse_forward(tokens):
    idx = find_operator_index(tokens)
    left = tokens[:idx]
    right = tokens[idx+1:]
    return Operation(left, right)

def parse_reversed(tokens):
    idx = find_operator_index(tokens)  # same logic!
    left = tokens[:idx]
    right = tokens[idx+1:]
    return Operation(right, left)

# GOOD — extract shared logic
def _split_at_operator(tokens):
    idx = find_operator_index(tokens)
    return tokens[:idx], tokens[idx+1:]

def parse_forward(tokens):
    left, right = _split_at_operator(tokens)
    return Operation(left, right)

def parse_reversed(tokens):
    left, right = _split_at_operator(tokens)
    return Operation(right, left)
```

### Test files in solution patch
```bash
# BAD — test files leaked into solution.patch
git diff $BASE_COMMIT -- src/ test/ > solution.patch

# GOOD — only source files
git diff $BASE_COMMIT -- src/file1.py src/file2.py > solution.patch
```

### Imports inside functions
```python
# BAD — imports belong at top of file
def process_data(items):
    from collections import Counter
    counts = Counter(items)

# GOOD — imports at top per repo convention
from collections import Counter

def process_data(items):
    counts = Counter(items)
```

---

## Review Checklist (Items 16–21 of 21)

Reviewers evaluate solutions against these exact criteria:

| # | Criterion | Pass | Fail |
|---|---|---|---|
| 16 | Solution follows repo code style | Matches naming, patterns, comments | Looks different from repo |
| 17 | No comments (unless repo has them) | Clean code, self-documenting | AI-style explanatory comments |
| 18 | No debug statements | Clean production code | console.log, print, fmt.Println |
| 19 | No unused code | Every line serves a purpose | Dead code, unused vars/imports |
| 20 | Solution solves described problem | Fixes exact issue in description | Scope creep or partial fix |
| 21 | No code duplication | DRY, shared helpers | Same logic in multiple places |

---

## Pre-Submission Checklist

**Code quality:**
- [ ] Matches repo variable naming
- [ ] Matches repo comment convention
- [ ] Matches repo logic patterns
- [ ] Reuses existing utilities (not reinventing)
- [ ] Extends existing infrastructure (not creating replacements)
- [ ] Code in correct file(s) matching repo organization
- [ ] Pure-function helpers extracted (1+ per behavior)
- [ ] Fixpoint loops use `loop { … if !changed { break; } }` shape when description says "iterate"
- [ ] No debug statements
- [ ] No unused variables, imports, or dead code
- [ ] No `as any` casts
- [ ] No AI slop
- [ ] No scope creep
- [ ] No code duplication
- [ ] No magic strings (use repo constants)
- [ ] No breaking changes to existing function signatures
- [ ] No silent error swallowing
- [ ] Imports at top of file

**Patch:**
- [ ] Valid git patch against `$BASE_COMMIT`
- [ ] ONLY source files (no tests, no Dockerfile, no docs)
- [ ] Doesn't conflict with test.patch (apply in either order)
- [ ] No new internet dependencies

**Validation:**
- [ ] `./test.sh base` passes (no regressions, no `<testcase>` count drop)
- [ ] `./test.sh new` passes (solution works)
- [ ] **Mars**: ≥100 LOC (sweet spot 170–380), ≥1 file (sweet spot 1–8 mode 3)
- [ ] **Olympus**: ≥400 LOC meaningful (600+ for Good/Excellent), ≥3 files (10+ Good, 20+ Excellent)

**Alignment:**
- [ ] Every described behavior is implemented
- [ ] No extra behavior beyond description
- [ ] All solution code is covered by tests
