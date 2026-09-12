# DIAMOND-PLAYBOOK — Castor Trap Taxonomy + Iteration Discipline

Evidence-based design + iteration guide derived from 7+ Diamond submissions (90+ Castor runs); 5 approved (cliffy-command-aliases, dasel-csv-options, rdb-sample-fraction, yaegi-channel-diagnostics, yaegi-generic-constraint-fidelity).

**Approved:** `cliffy-command-aliases` · `dasel-csv-options`
**In-flight (AI Reviewer PASS):** `cliffy-undo-history` · `yaegi-execution-tracer`
**In-flight (eval calibration):** `tengo-crypto`
**REJECTED at Stage 0 (maintainer philosophy):** `dasel-multi-file` — see § Section 9

**Why this file exists:** Diamond submissions cost ~$500 each but burn 25 Castor tokens/run × 10+ runs + Diamond Checks (50 tokens) + Failure-QA review rounds. Mean **8 eval rounds + 4-6 QA rounds + 12 total attempts** per approval. This playbook compresses the cycle.

> **Authoring path (clarified 2026-05-14):**
> - **Olympus already ACCEPTED → promotion CLOSED.** Cannot promote a shipped Olympus problem to Diamond.
> - **Olympus IN-FLIGHT (not yet accepted) → promotion OPEN.** Can harden in-flight Olympus draft for Diamond. Section 8.5 applies.
> - **No Olympus draft → greenfield.** Most expensive path.
>
> Section 8.5 retained as active strategy for in-flight Olympus drafts.

---

## Section 1 — The 16 Diamond-Quality Trap Categories

Ranked by hit-rate across 7 submissions (84+ Castor runs). **Cross-architectural** traps (caught Castor through 2+ distinct implementations) earn ★. Bake at least 3 stars into every Diamond design.

Categories 1-8 from cliffy/dasel/tengo/yaegi-execution-tracer. Categories 9-13 from yaegi-checkpoint-api. Categories 14-16 from yaegi-generic-constraint-fidelity (2026-05-27).

### 1. ★ Same-object-as-inherited (14 hits across 2 subs)

**Pattern:** "Global", "parent", "inherited" treated as strictly upward. Current node is both recorder AND inheritor — agents miss this.

- **cliffy-command-aliases `clearRegisteredAliases`** — 6/10 (60%). Caught (a) same-map storage [#1,#3,#6,#8], (b) separate maps + accessor walks parents only [#2,#7,#9]. Same test, two designs.
- **cliffy-undo-history checkpoint-during-tx** — 8/10 (80%). Caught (a) no wiring [#2,#10], (b) hardcoded `() => false` [#1,#4], (c) wired on wrong instance, (d) method defined but never called [#9,#11]. Four designs, one test.

**Design recipe:**
- Spec a feature where local + global state live on the SAME entity
- Test asserts "the current command's global state survives the local clear"
- Agents bias toward "global = comes from elsewhere" — this trips them

### 2. ★ Pipeline ordering / pre-mutation read (14 hits)

**Pattern:** Agent reads state at the wrong pipeline stage. Earlier handler already mutated it.

- **dasel-multi-file `o.InFormat = o.OutFormat` crossover** — 7/14 (50%). `run.go` has stdin-format crossover that fires BEFORE file-loading reads `o.InFormat`. Agents add multi-file code AFTER the mutation → all files load with output format. Fix: capture `originalInFormat` BEFORE crossover.
- **dasel-csv-options trim-null ordering** — 3/10. Trim runs on raw value before null-substitution. `if !colV.IsNull()` guards skip strict-newline scan before null applies.

**Design recipe:**
- Pre-existing code has an EARLY mutation of a field
- Spec requires reading the ORIGINAL value
- Agents add code adjacent to mutation site, read mutated field

### 3. ★ Convenience-method default-leak (12 hits)

**Pattern:** Method A calls method B internally. B has defaults A should NOT include.

- **dasel-csv-options null-write substitution** — 12 across 4 architectures:
  - (a) total miss of substitution [#7]
  - (b) partial in `quote=always` only
  - (c) `!IsNull` guard skips strict-newline [#9]
  - (d) substitute but skip trim [#5,#10]
  - (e) empty string passed to trim instead of null-string [#8]
- **cliffy-output-format `withOutputFormat`** (historic) — 6/10 (60%). Convenience reuses default setup including built-ins.

**Design recipe:**
- Spec a convenience method (`withX`) that should add ONLY what's named
- Castor will call the existing public setup which adds defaults
- Test asserts A's result has ONLY what A explicitly added

### 4. ★ Boundary detection in concurrency (13 hits in 1 sub)

**Pattern:** Frame-clone propagation in interpreter loses the boundary discriminator.

- **yaegi-execution-tracer goroutine depth** — 13/20 (65%). Five architectures:
  - (a) `clone()` propagates traceDepth
  - (b) `+1` unconditional parent
  - (c) `traceState` on frame
  - (d) `goroutineTrace` by gid but yaegi shares OS thread
  - (e) `traceDepth = -1` sentinel copied
- All miss the `callNode.anc.kind == goStmt` discriminator.

**Design recipe:**
- Concurrency feature where state must RESET at boundary
- Boundary detection requires ancestor inspection
- Agents copy/propagate the field, miss the kind check

### 5. ★ Wrapper-bypass / authentication coverage (8 hits)

**Pattern:** Add bytes/padding/wrapper to satisfy ONE constraint without passing it through the protective mechanism (AAD, FileLoadError, error chain).

- **tengo-crypto seal padding-not-in-AAD** — 5/13 (38%). Four padding placements:
  - (a) 1-byte version prefix unauthenticated [#5]
  - (b) 20-byte prefix [#7]
  - (c) 24-byte middle padding [#9,#12]
  - (d) 24-byte leading padding [#11]
- **dasel-multi-file FileLoadError** — 3/14 (21%). Three emit sites bypass the wrapper: stat path, glob no-match path, default path return raw `fmt.Errorf` instead of `FileLoadError`.

**Design recipe:**
- Spec a protective wrapper that must cover ALL emit sites
- Multiple natural emit sites (stat, glob, default) exist
- Test asserts `errors.As(&Wrapper)` at every site

### 6. Off-by-one slice/splice (7 hits in 1 sub)

**Pattern:** `splice(idx)` removes target, `splice(idx+1)` preserves it.

- **cliffy-undo-history `Transaction.rollbackTo()`** — 7/10 (70%). Splice from target index inclusive instead of `+1`. Single one-line bug, extremely repeatable. `hasSavepoint("sp1")` returns false after rollback when it should be true.

**Design recipe:**
- Spec a rollback/restore operation with named target
- Target itself must survive operation
- Agents write `splice(idx)` not `splice(idx+1)`

### 7. ★ Null/empty short-circuit (12 hits, see #3 — overlapping pattern)

See category 3. Same mechanism.

### 8. ★ Sibling-struct duplicate update (4 hits in 1 sub)

**Pattern:** Same struct-tag/field/help-text exists in 2+ files. Agent greps, finds ONE, patches it, never searches for siblings.

- **dasel-csv-options `interactive.go` help text** — 4/10 (40%). Updated `query.go` flag help, missed `interactive.go` with same struct tag.

**Design recipe:**
- Repo has 2+ files with similar struct/field patterns
- Spec requires updating ALL instances
- Use **reflection-based test** to verify all instances updated (proven by `TestCLIHelpTextReferencesSeparatorNotDelimiter`)

### Other confirmed patterns

- **Placeholder-key transformation** — yaegi anonymous closure stored under `<anonymous>` instead of `""`. 5/20 (25%).
- **Aggregation: sum-per-call vs persistent set** — yaegi `TotalLines` Σ(per-call distinct) instead of `|∪|`. 4/20 (20%).
- **Code-organization / wrong-package registration** — dasel-multi-file selector functions in root instead of `execution/`. Wipes 20-36 tests.
- **Bash sandbox death** — 25% of multi-layer Go runs lose test capability mid-session (228-328 msgs).
- **go.mod version bump regression** — tengo-crypto 4/10 (40%). Castor bumps go.mod for new stdlib import, dismisses self-caused regressions as "pre-existing."

### 9. ★★★ Package-short-name reverse lookup for slashed imports (5/14 hits = 36%)

**Source:** yaegi-checkpoint-api 14 Castor runs.

When spec says "paths use the package short name first" and imports include slashed forms like `path/filepath`, agents key the binary-package map by import path only. `os.Args` works (`binPkg["os"]`); `filepath.Separator` fails because the map holds `"path/filepath"` not `"filepath"`. Fix requires reverse-mapping via the interpreter's existing `pkgNames` ({import-path → short-name}).

**Trap quality:** ★★★ — admits 2 architectures (direct vs reverse map); boundary (slashed vs single-segment imports); specific test value (`Separator` must resolve). Single missed reverse-lookup fails 2+ tests across `Inspect`/`SymbolCategory`/`SymbolType`.

**Pre-empt sentence:** "Imports under slashed paths (e.g. `path/filepath`) resolve by their short name (`filepath`) across all path-taking APIs."

### 10. ★★★★ Cross-API error-sentinel wrap discipline (6/14 hits = 43%)

**Source:** yaegi-checkpoint-api.

Spec says "ErrPathUnresolved wraps every unresolved-path error." Agents enforce on `Inject`/`Inspect` (obvious entry points) but skip the tracker APIs (`Track`/`Untrack`/`History`). Malformed paths return `nil` instead of wrapping the sentinel.

**Trap quality:** ★★★★ — single spec sentence covers N APIs; agents naturally implement discipline only on the entry points they wrote first. Fans to 6+ tests when each path API has a malformed-path test.

**Pre-empt sentence pattern:** "ErrPathUnresolved wraps every unresolved-path error from `<API1>`, `<API2>`, ..., `<APIn>`." Enumerate every path-taking API even if the discipline is uniform — agents skip what isn't named.

### 11. ★★★ Method reachability fallback on value paths (5/14 hits = 36%)

**Source:** yaegi-checkpoint-api.

When spec says "Methods with pointer receivers are reachable through value paths," agents use `v.MethodByName(name)` only and miss the `v.Addr().MethodByName(name)` fallback. One missed fallback fails 4+ tests across SymbolCategory + Inject method-reject + CLI -cat method paths. Cross-feature radiation = high test-stack value.

**Trap quality:** ★★★ — universal Go-reflect blind spot; cross-feature radiation; behavioral pin already exists in spec but Castor implements only the value-receiver path.

**Pre-empt verification:** test BOTH receiver kinds explicitly. `bytes.Buffer.Write` (pointer receiver) reached from value path is the canonical probe; `time.Time.Unix` (value receiver) is the control.

### 12. ★★★★ Snapshot reference vs deep-clone (2/14 hits but ~15 fails each = trap-stack fanout)

**Source:** yaegi-checkpoint-api.

When checkpoint/snapshot APIs are spec'd as "independent of later mutation," agents store live `reflect.Value` references instead of deep-cloning. Restore becomes no-op; Diff returns zero changes after Inject. Single mistake fans to 10-15 test failures in one architectural bucket.

**Trap quality:** ★★★★ — central feature broken; high fanout makes it visible across the entire snapshot test cluster. Boundary: agents who naively `cp := v` (reflect.Value is a struct, semantics surprise) vs agents who explicitly recurse the kind tree.

**Pre-empt sentence:** "Snapshot captures source-package variables independently of later mutation" + "snapshot storage does not alias live storage." Both clauses needed — first describes intent, second describes implementation invariant that test asserts.

### 13. ★★ Malformed-path acceptance in boolean predicate (4/14 hits = 29%)

**Source:** yaegi-checkpoint-api `Resolves`.

When a boolean predicate (`Resolves(path) bool`) wraps a path-validating impl, agents short-circuit on dot-segment splits without rejecting empty segments. `Resolves(".")`, `Resolves(".X")`, `Resolves("..invalid")` return true.

**Trap quality:** ★★ — single fix possible (check segment non-emptiness), but probes 4 distinct malformed forms. Single-architecture trap on its own; bundles well with cross-API wrapping trap above.

**Pre-empt verification:** include exact malformed forms tested: `Resolves("")`, `Resolves(".")`, `Resolves(".X")`, `Resolves("main.")`, `Resolves("main..X")`, `Resolves(" main.X")` — agents miss the form they don't think to write a guard for.

### 14. ★★★★ Pre-existing loose helper reused as new strict predicate (6/10 hits = 60%)

**Source:** yaegi-generic-constraint-fidelity 2026-05-27.

Spec demands strict Go-style representability check (`untyped float not representable as int64 → mismatched_types`). Repo already has a loose helper (`assignableTo`) with comment `// Assignability depends on constant numeric value (overflow check), to be tested elsewhere.` Agents add a per-slot reconciliation gate, but DELEGATE the predicate to the loose helper or shortcut to `isNumber/isNumber` / `isNumberCat/isNumberCat`. Three architectural variants all fail:
- (a) `untypedAssignableTo` falls through to `u.assignableTo(v)` [Castor #4, #9]
- (b) `if isNumber(tu) && isNumber(tt) { return true }` shortcut [Castor #6]
- (c) `isNumberCat(src.cat) && isNumberCat(dst.cat)` shortcut [Castor #7]

All let untyped-float-vs-int64 through → falls to legacy constant-folder → emits `157/50 truncated to int64` instead of structured `ErrMismatchedTypes`. Castor agents trust the existing helper's name and skip the comment that says "to be tested elsewhere."

**Trap quality:** ★★★★ — admits 3+ architectures (fallback / direct shortcut / category shortcut); pre-existing comment in source is the obvious tell agents miss; cross-test fanout (4+ typed-pin tests share the same root cause).

**Design recipe:**
- Repo has a loose helper with a hedging comment like "overflow check deferred"
- Spec requires the strict version of that check at a NEW call site
- Test asserts both error TEXT (`mismatched types`) AND sentinel (`errors.Is(err, ErrMismatchedTypes)`) AND structured type (`AsConstraintError(err) != nil`)
- Triple-cite test catches every architectural variant: text-only or sentinel-only lets agents who use loose helper slip through different probes

**Pre-empt sentence pattern:** "Representability is Go-spec strict: `untyped X` is representable as `Y` only if the constant's value fits, not merely if the kinds are both numeric." Plus enumerate at least one negative example in spec text.

### 15. ★★★ Helper defined but not called on critical path (3/10 hits = 30%)

**Source:** yaegi-generic-constraint-fidelity 2026-05-27.

Castor adds new helper functions (`defaultIfUntyped`, `untypedDefault`, `reconcileInferred`) AND the structured error type AND the public callback wiring — patch looks comprehensive. But the helper is never invoked on the critical path. Pre-existing `checkConstraint` still does `it.equals(c) || it.matchDefault(c)` against the un-promoted untyped itype. New helper sits dormant.

**Trap quality:** ★★★ — visually convincing patch (right symbols, right names), but membership-check call site unchanged. Validator + reviewer who skim the diff and see `defaultIfUntyped` in the patch may assume coverage; only running tests proves it.

**Design recipe:**
- Spec requires a transformation (promotion / normalization / wrapping) on input X
- Pre-existing code reads X at a DIFFERENT site than the natural place to add the transformation
- Test asserts the transformed behavior at the pre-existing call site
- Agents add the helper at the natural site, never wire it to the actual decision point

**Pre-empt sentence pattern:** "Promotion runs BEFORE constraint membership testing, not after." Word "before" is the discriminator — `before` vs `during` vs `after` changes which call site needs the wiring.

### 16. ★★ Asymmetric enumeration miss (1/10 hits = 10%, low-volume probe value)

**Source:** yaegi-generic-constraint-fidelity 2026-05-27 (Castor #8).

Spec enumerates 3 default-type mappings: `rune → int32`, `float → float64`, `complex → complex128`. Castor implements 2 cleanly; the 3rd silently drops. In yaegi case, untyped-rune has surprising `name: "int32"` but `str: "untyped rune"` (`interp/type.go:153`); `defaultType(noValue, sc)` falls through to `*typ = *t` without flipping `untyped: false`. Float and complex paths work because their `name` and `str` are symmetric (`float64` vs `untyped float`).

**Trap quality:** ★★ — low hit-rate but cheap to bundle. Probes one specific repo quirk; 1 in 10 agents trip when they implement the symmetric cases and don't double-check the asymmetric one.

**Design recipe:**
- Spec enumerates 3+ symmetric-looking cases
- Pre-existing repo data structure has ONE asymmetric case (e.g. `name` vs `str` disagree, or constant table missing entry)
- Test all 3 cases independently; do NOT lump them into "all numeric literals work"

**Pre-empt:** include all 3 mappings as separate test names (`untyped_rune_satisfies_int32`, `untyped_float_satisfies_float64`, `untyped_complex_satisfies_complex128`). Castor implements 2/3 then ships, hoping the 3rd is symmetric. Test names force visibility.

---

### 17. ★★★★ Builtin-shadow name-vs-symbol resolution (6/10 hits = 60%)

**Source:** yaegi-unreachable-code 2026-06-03 (APPROVED, Castor 6/10).

Spec: "Only a call to the built-in `panic` is terminating; ordinary calls, including os.Exit, are not." A test shadows the predeclared identifier with a local: `panic := func(s string){ _ = s }; panic("x"); println("a")`. Agents detect the builtin by identifier text (`fn.ident == bltnPanic`) and skip the resolved-symbol check (`fn.sym.kind == bltnSym`), so the shadowed local call is misread as the builtin and the next statement is flagged unreachable. The 2 passing runs checked the symbol kind; 6 of 8 failing runs matched by name only.

**Trap quality:** ★★★★ — 60% hit, one sentence to state, generalizes to any language with shadowable predeclared identifiers (Go builtins, Python builtins). The discriminator (the resolved symbol) is already in the repo's AST.

**Design recipe:** a "only the built-in X is special" rule + a test that shadows X with an ordinary local of the same name. The repo must expose resolved symbols (an interpreter always does).

**Pre-empt:** "Only a call to the built-in panic is terminating; ordinary calls, including os.Exit, are not." Fair because the symbol table records the shadow; still trips 60%.

### 18. ★★★ Language-spec exception inside a general rule (4/10 hits = 40%)

**Source:** yaegi-unreachable-code 2026-06-03 (APPROVED, Castor 4/10).

Spec enumerates a set with a carve-out: terminating statements include if/switch/select/block/labeled, BUT "Break, continue, and fallthrough are not themselves terminating," so a switch clause ending in `fallthrough` is not terminating. Agents implement the general set and miss or invert the exception: `clauseBodyTerminates` returns true on a trailing `fallthroughtStmt`, or `switchTerminates` runs `continue` on a fallthrough clause and skips its check. Both mark the post-switch statement unreachable.

**Trap quality:** ★★★ — 40% hit. The carve-out is one sentence; agents who internalize the general rule forget the exception even when it is stated verbatim.

**Design recipe:** a rule of the form "X, Y, Z do A; but the W case does NOT," with a distinct test exercising the W case. The test name forces visibility.

**Pre-empt:** "Break, continue, and fallthrough are not themselves terminating." Stated verbatim, still trips 40%.

---

### 19. ★★★★ Shared error base must be a REAL subclass for `instanceof` (csstree-calc-typecheck, 8/10 hits = 80%)

**Source:** csstree-calc-typecheck 2026-06-05 (APPROVED). Spec: "two resolution passes whose errors share a `ResolveError` base." Test: `assert.ok(layerError instanceof ResolveError)`. Agents build the hierarchy as a factory/marker (`function LayerOrderError(){ return ResolveError(...) }` via `Object.create(SyntaxError.prototype)`) -> the `.name` check passes, `instanceof` fails. The agent must reach `class ResolveError extends SyntaxError` + `class LayerOrderError extends ResolveError`. JS-flavored but cross-architectural (any "shared base / sentinel hierarchy" requirement). 8/10 miss it though the requirement is verbatim.

### 20. ★★★★ Reconciliation rule defined for path A must be REUSED on path B (csstree-calc-typecheck, 8/10 = 80%)

A combining rule stated once ("a percentage with a dimension takes it as a percent hint") must apply on EVERY consumer. Agents implement it in addition (`addTypes`) but the consistent-type check for `min`/`max`/`clamp`/`abs`/`hypot` uses strict equality and rejects the percentage -> `clamp(10px, 50%, 100px)` = `invalid` instead of `length (percent-hint: length)`. **Recipe:** state a combining/normalization rule, then test it through a SECOND consumer (a comparison/aggregate function) where the naive impl forgets to reuse it. Sibling of #15, but the helper IS called on path A — the miss is not reusing it on path B.

### 21. ★★★ Accepted-type set over-collected via nested productions (csstree-calc-typecheck, 7/10 = 70%)

A property's value grammar reaches `<number>` THROUGH the inner `calc` multiplier production. An agent that collects accepted types by walking the FULL grammar pulls in `<number>` and admits a dimensionless `calc(6 / 2)` for a length property. **Fix:** collect from the property's TOP-LEVEL grammar only; do not recurse into function-notation types. Same family: the gate must reject a calc that resolves to an ERROR (incompatible sum, length divisor, nested invalid), not only a valid-but-wrong type — agents gate on `error && type !== null` and let `type: null` errors slip through (3/10).

---

## Section 2 — What Diamond-Quality Trap Looks Like

A trap earns ≤30% Castor pass rate when ALL of these hold:

1. **Admits 2+ natural implementations** — storage layouts, pipeline orderings, padding placements. Single-architecture traps get patched in one round.
2. **Description states two facts whose COMBINATION forces constraint** — seal>=80 derived from "open rejects <80"; own-command global from "local AND inherited"; goroutine depth from "reset to 0 independently."
3. **Operates on a BOUNDARY** — call boundary, storage boundary, scope boundary, AAD boundary. Agents focus on typical case, miss boundary.
4. **Test asserts SPECIFIC structural value** — `count == 2 not 4`, `cg[""]` exists, `errors.As(&FileLoadError)` true. Not "doesn't crash."

**Anti-quality signals (single-architecture traps):**
- Off-by-one (one fix lands it)
- `strings.ToUpper(algo)` literal (one grep finds it)
- Single missed export (one line)

These need stacking — bundle 3+ in one test or surround with cross-feature interactions.

---

## Section 3 — Design-Time Recipe (the 10-point checklist)

Based on side-by-side comparison of 2 approved vs 4 in-flight:

| Dimension | Approved band (N=2) | Hard rule |
|---|---|---|
| meta.md word count | **observed 453, 577** but NO Diamond-specific floor | Follow `DESCRIPTION.md § Word Count` shape-based targets; hard cap 500 (Tighten-First Rule favors tighter). N=2 sample drove API count, not Diamond requirement. |
| Solution +LOC | **400-650** observed, **NO upper ceiling** | **≥400 EFFECTIVE LOC HARD FLOOR (auto-review triggers)**; high LOC OK if genuine complexity, not scaffold. Auto-reviewer formula = raw − blank − comment-only (BRACES KEPT, comments NOT counted). |
| Test count | **50-160** observed, **NO upper ceiling** | Coverage-driven |
| Tests per group | **≥6 avg** | — |
| Public API surface (exported names) | **9-22** observed | high count OK if every name appears in tests + meta; avoid declaration-list feel |
| Packages touched | **1 deep OR 2 in pipeline** observed | 3+ adds risk (dilution + maintainer-philosophy surface) but not banned |
| Test files | **1 per package** | — |
| Pre-empt sentences in meta | **≥5 verbatim** | — |
| Cross-feature test ratio | **20-25%** | — |
| `##` headers in meta | **0** | 0 enforced |
| Title verb | **"Add"** (6/6 subs) | — |
| **Castor pass rate (the REAL ceiling)** | **≤30%** | **HARD: >30% = too easy, redesign** |

### LOC ceiling is a myth — the real ceiling is pass rate

N=2 approved (410 + 628 LOC) gave my earlier "650 hard ceiling." That's sample bias. **LOC is a correlate of complexity, not a constraint on it.**

Genuine evidence:
- tengo-crypto: **925 +LOC, 4/10 Castor pass (40% on target)** — high LOC, valid surface (20 stdlib funcs + hasher object), not scaffold
- yaegi-execution-tracer: 391 +LOC, ~10% Castor pass — low LOC, hits target via boundary traps
- Pass rate ≤30% is what matters; LOC is incidental

**When high LOC is GOOD:**
- Every LOC adds genuine surface (multi-API stdlib module, multi-layer architecture, cross-package integration)
- Cross-architectural traps (Section 1 ★) embedded
- Castor pass rate ≤30% confirms difficulty

**When high LOC is BAD:**
- Pattern-followable scaffold (3+ existing funcs match shape) — `PATTERNS-ADVANCED § Pattern 23`
- Same trap repeated N times in different methods (no architectural diversity)
- Declaration-list feel (long API surface, no behavioral richness)
- Reviewer can rewrite at half the LOC without losing requirements (scope creep)

### Reject signals — recalibrated

| Sub | Over-band metric | Actual risk | Verdict |
|---|---|---|---|
| tengo-crypto | 925 +LOC | Only risk = scope creep (pattern-followable funcs). Castor 4/10 confirms difficulty real. | LOC alone NOT a problem — pass rate validates |
| cliffy-undo-history | 30+ exported names | Description list-feel risk; meta needs every name traceable to tests | If all names tested → fine |
| dasel-multi-file | 3 packages | Dilution + maintainer-philosophy surface (turned out RED — § Section 9) | 3 packages didn't kill it; #357 closed by maintainer did |

yaegi-execution-tracer (391 LOC, 17 API, 1 package, 54 tests) sits at the LOW end of approved bands — equally valid as high-LOC variants.

### What actually kills Diamond submissions

Ranked from real reject data (not LOC):

1. **Maintainer-philosophy violation** (`dasel-multi-file` — § Section 9). Hard reject regardless of all other metrics.
2. **Pattern-followable / triviality** (`PATTERNS-ADVANCED § Pattern 23`). 3+ existing matching funcs → agent copy-pastes → Castor passes too easily.
3. **Castor pass rate >30%** (too easy). Triggers "redesign or downgrade."
4. **Castor pass rate <10% without hint approval** (too hard / unfair). Triggers hint flow or unfairness review.
5. **Spec contradicts maintainer docs** (current-syntax overlap).
6. **Post-base maintainer-shipped feature** (`PATTERNS-ADVANCED § Pattern 32`).
7. **Platform similarity collision** (concept+domain embedded, threshold 0.9). A same-repo introspection/diagnostics-API family collides even with a clean GitHub namespace (Pattern 22 GREEN). `yaegi-closure-introspection` scored 0.81 vs an older same-repo capture-introspection problem and was discontinued; the escape was a different concept axis (control-flow reachability vs data-flow capture, which landed 0.683). Cannot be measured locally. See `PATTERNS-ADVANCED § Pattern 46`.

**LOC ceiling is NOT in this list.** Big LOC is fine when traps + pass rate validate.

### The 10 Design Rules

1. **Pick 1-2 packages.** 1 package with 5-9 files of within-package depth beats 3 packages of shallow work. dasel-csv (2 packages, pipeline cut) is the only multi-package approved.
2. **Write meta.md per `DESCRIPTION.md § Word Count` shape-based targets.** No Diamond-specific floor — sample of 2 approved (453 + 577 words) reflected API-enumeration density, not a Diamond minimum. Hard cap 500 still applies. **Tighten-First Rule (lessons-learned) favors SHORTER descriptions** — they remove inference surface that helps weak agents fake their way through. 220 words can be Diamond-quality if every sentence ties to a test assertion + 5+ pre-empt sentences fit naturally. Plain prose, no `##` headers.
3. **Target 410-630 +LOC.** Above 650 risks "too much surface area."
4. **Cap exported API at ~20.** When you exceed 22, description becomes declaration list.
5. **Build a dedicated cross-feature group** of 7-15 tests stacking 2-4 features per test. **Single biggest separator** between approved + in-flight:
   - dasel-csv Group 20 (15 tests stacking null × quote × escape × strict)
   - cliffy-aliases Group 7 (7 tests stacking callbacks × cancellation × global × noGlobals)
6. **Average ≥6 tests per group.** Sparse 2-3-test groups = in-flight pattern.
7. **Name traps explicitly in solution-approach.md** with kill-rate estimates ("56% Castor failure rate"). Approved subs lacked these — they shipped before this instrumentation. In-flight should add.
8. **Use action verb "Add"** in title (6/6).
9. **Mirror test files to packages.** 1 test file per source package. Use `tests/` sub-package only for cyclic-import avoidance (yaegi pattern).
10. **Every named trap in solution-approach has a verbatim pre-empt sentence in meta.md.** Pre-empts are LITERAL, never euphemistic.
11. **Pin public return types when the hidden test package imports the API by exact type.** An external test package doing `[]interp.UnreachableStmt = i.UnreachableStmts()` and `parsePos(d[0].Position)` makes the value-vs-pointer slice and string-vs-struct field shapes load-bearing: a plausible-but-different choice fails the whole file to COMPILE, zero-scoring every test at once (yaegi-unreachable-code R1: 4/5 runs lost 75/78 by choosing `[]*T` or `token.Position`). Return types are the public contract (WHAT, not HOW), so naming them in meta is spec-completion, not a leak — the admin "ambiguous spec -> reword, not hint" path. See PATTERNS-ADVANCED § Pattern 47.

### Pre-empt sentence pattern (verbatim from approved)

| Trap | Pre-empt sentence (verbatim) |
|---|---|
| Wiping globals on clear | "`clearRegisteredAliases()` removes only local aliases, preserving all global aliases." (cliffy-aliases L14) |
| Reference storage instead of copy | "Mutating the original array after registration does not affect the stored alias." (cliffy-aliases L4) |
| Trimming quoted fields | "Trim applies to unquoted fields only; quoted fields are never trimmed." (dasel-csv L12) |
| Wrong evaluation order | "Comment line stripping has priority over null-string matching. Comment detection operates on the raw parsed value before any trim is applied." (dasel-csv L17) |
| Universal null match | "Only unquoted fields matching csv-null map to null; quoted fields matching csv-null remain strings." (dasel-csv L18) |
| Hex-vs-raw confusion | "`digest()` returns the current raw digest as bytes without resetting state" (tengo L5) |
| Goroutine inherits depth | "Goroutine-launched functions reset to depth 0 independently." (yaegi L11) |
| Sum instead of union | "a two-line function called twice yields TotalLines=2, not 4" (yaegi L15) |

Pattern: **EXACT mechanism + EXACT counter-example value** (count=2, not 4).

---

## Section 4 — Iteration Discipline (cost reduction)

### Fairness analysis before any iteration (admin 2026-05-29) — applies to ALL Castor batches

Before adding hints, adding clarifications (in prompt or hint section), or running more Castor / Diamond Checks runs, **stop and analyze WHY existing agents failed.** Brute-forcing pass rate via re-runs without analysis wastes tokens, produces low-quality submissions, and risks revert downstream even when Castor eventually clears.

**Workflow:** run a small batch first (1-3 Castor), then check why they passed or failed. Only then decide between (a) ship as-is, (b) fairness fix, (c) hint flow, (d) redesign.

**Tests should check behavioral requirements regardless of the approach the agent takes.** If a specific approach is truly needed, the prompt must say so up front — agents should not have to guess.

**Strong unfairness signal:** all or most agents fail for the same exact reason. Diagnosis table:

| Pattern | Diagnosis | Action |
|---|---|---|
| All agents emit a reasonable-but-different implementation that tests reject | Tests check implementation detail, not behavior | Relax to sentinel / `Kind` / structural assertion; drop substring-on-text where sentinel suffices |
| All agents miss a requirement that isn't actually stated | Meta has hidden requirement | Add the requirement to meta as one explicit sentence |
| All agents miss a requirement that IS stated but ambiguously (multiple reasonable approaches; only one passes tests) | Meta is ambiguous | Reword to disambiguate. Hint is the wrong response — adding a hint to disambiguate the unhinted prompt is hiding the problem |
| All agents fail at one genuinely hard step | Real difficulty (acceptable for Diamond) | Leave it; hint flow legitimate if still 0/10 after analysis |

**Be honest with yourself:** would a competent engineer reading only the description + repo arrive at the same implementation the agents pick? If yes, tests must accept that implementation. If you find yourself wanting to add a hint to make Castor reach a specific implementation, that's the signal the unhinted prompt is under-specified — fix the prompt instead.

**Hints on unfair problems hide unfairness, they don't fix it.** A submission that passes via hints but is fundamentally ambiguous still gets reverted at human review.

### Mean cost per Diamond

| Submission | Eval rounds | QA rounds | Total attempts | Outcome |
|---|---|---|---|---|
| cliffy-command-aliases | 1 | **6** | 7 | APPROVED |
| dasel-csv-options | 17+ | (mixed) | **26** | APPROVED (~half-cycle) |
| cliffy-undo-history | 11 | — | 8 | AI PASS |
| dasel-multi-file | 7 | **4** | 15 | AI PASS |
| tengo-crypto | 4 | — | 8 | Castor 4/10 |
| yaegi-execution-tracer | 9 | — | 9 | NEEDS_HINTS |
| yaegi-checkpoint-api | **8 fairness rounds + 24 total** | — | **24** | APPROVED (tier-downgraded Olympus, Castor 1/14 = 7%) |
| **Mean** | **10.6** | **4-6** | **13.9** | — |

**Mean total cost: ~12 iterations / ~5000 tokens for greenfield.** Goal of this playbook: compress greenfield cycle via aggressive Section 3 design discipline + Section 5 failure-QA rule adherence. **Promotion path (§ Section 8.5) still OPEN for in-flight Olympus drafts** — closed only for already-accepted Olympus problems. Prefer promotion when eligible (~15× cheaper).

### Highest-leverage interventions (proven >15pp pass-rate delta)

| Intervention | Submission | Delta | Use when |
|---|---|---|---|
| **Cross-package integration test** (`internal/cli/csv_flags_test.go`) | dasel-csv | median msgs 60→141, pass rate stabilized | Median msg below 100 |
| **Add NEW behavioral requirement** instead of removing | dasel-csv Iter 17 | 58%→25% | Too easy, need scope addition |
| **`was_mentioned_in_description: false` → 1-sentence meta fix** | cliffy-undo R3-R8 | +9-17pp per fix, 4 in a row | 3+ evaluators raise it |
| **Explicit per-function API signatures** | dasel-multi-file R2→R4 | 0%→17% | FAIL_TEST_MISMATCH cluster from invented names |
| **Documenting one trap (description tightening)** | dasel-csv Iter 8→9 | +25pp | Pass rate <10% with no QA flag |
| **Opaque seal/open description** | tengo R2→R3 | 70%→30% | Pattern-followable too easy |
| **Architectural hint (runCfg)** | yaegi A8→A9 | 100% elim of target failure | Single-trap dominant |
| **Top-down hint pruning** (max-spec → prune one-by-one) | Method-level | ~50% token savings on hinted batch | When at hint stage (0% unhinted) and want single-batch convergence (avoid ping-pong) |

### Failure-Point Analysis Procedure (community method, Shipd Discord 2026-05-29)

Use BEFORE drafting hints OR writing failure-QA OR diagnosing eval regressions. Maps test → spec → trajectory in 3 steps:

1. **Open new-test XML** (`junit_new.xml` or `/var/artifacts/junit_new.xml`). Find the FAILED `<testcase>` entries. Note exact test names + failure messages.
2. **Map each failing test back to its meta.md anchor.** Which sentence / clause in description does this test verify? If no clear anchor → description is under-specified for this test (Bucket 1: Hidden Requirements — fix description first).
3. **Search trajectory** (Castors/{run_id}/trajectory.jsonl or .log) for where the agent discusses that part of the description. Find:
   - Did the agent READ the relevant meta clause? (grep trajectory for keywords from the clause)
   - WHERE in the trajectory did the agent's interpretation diverge?
   - WHAT code did the agent ship that violates the test? (cite the exact lines)

**Why this works:** "even after telling the AI it messes up, because the concept is complex and so is the repo, that problem is a good problem." Failures happen at concept-vs-spec mismatch, not at literacy. The trajectory shows the misinterpretation moment.

**Apply this procedure when:**
- Writing failure-qa.md for a failing Castor run
- Drafting hints (Top-Down Pruning Step 1 + 2 use this exact method)
- Diagnosing why iteration N+1 has different failure mode than iteration N
- Checking if a YELLOW Auto-Review fairness flag is real or contestable

**Output a failure map per failing run before writing QA:**
```
Run X (Castor #N) — FAILED 2/118
  Test: TestWriteNullValueWithSeparator
    meta anchor: meta.md L18 "Only unquoted fields matching csv-null map to null"
    trajectory pivot: msg 47 — agent decided "isNull guard bypasses quoting pipeline"
    shipped code: writer.go:234 — early-return on IsNull() skips strict-newline check
    root cause: convenience-method default-leak (Section 1 #3)
```

### Hint authoring discipline — Top-Down Pruning

When unhinted Castor = 0% and you need hints, **do NOT trial-and-error** (add → 10x → strip → 10x → re-add). Use top-down pruning to land hint in ONE 10x batch:

1. **Read 3-4 top failing runs using Failure-Point Analysis Procedure** (above) — for each: test XML → meta.md anchor → trajectory pivot → shipped code. Find cascading failures (early failures hide downstream traps).
2. **Analyze upstream gates vs downstream consequences** — hints unlock agents past initial blocker, may expose 1-2 new traps invisible before
3. **Draft MAXIMUM hint** — over-spec'd, guaranteed 8-10/10 pass (this is your ceiling reference)
4. **Map hint sentences to meta.md** — for each, find originating meta sentence
5. **Prune ONE-BY-ONE** — remove most-obviously-derivable first, test with 1 Castor probe, restore if pass rate drops
6. **Final 10x Castor batch** with pruned hint — single calibration round

**Token cost comparison:**
- Trial-and-error: 3 rounds × 250 tokens = 750 wasted before convergence
- Top-down pruning: max sketch (free) + ~5 × 1-Castor probes (125 tokens) + final 10x (250 tokens) = 375 total

**Pruning anti-patterns:**
- Removing trap-disambiguation sentence (matches Section 1 trap category) → pass rate collapses
- Removing spec-bridge sentence (links meta.md to test's expected value) → ambiguity returns
- Removing multiple at once → can't isolate load-bearing sentence

See `DIAMOND.md § Hint Authoring Discipline — Top-Down Pruning` for full step-by-step.

### Wasted-iteration patterns (avoid)

1. **Difficulty oscillation** (dasel-csv Iter 7-15): 7 rounds bouncing 50%↔0%. **Diagnostic: any iteration that ONLY tweaks description without changing structural difficulty just shifts pass rate 8-25pp without converging.** Fix: add structural requirement (new behavior, cross-package, new feature).
2. **Reversion churn** (3 subs): "approved then reverted at rerun" cost 3+ extra rounds each. **Pattern: borderline (3-4/12) approvals have ~50% variance-revert risk.** Harden to 1-2/12 with documented justification.
3. **Strengthening assertions caught borderline passes** (dasel-csv Iter 19): 3/12 → 1/12 by catching previously-passing agents with hidden bugs. Plan for this.
4. **Documenting one trap surfaces next dominant** (yaegi R8→R9): runCfg hint achieved 100% on target but exposed TotalLines (100%) + goroutine depth (90%) as new dominants. **Each clarification surfaces next-strongest blind spot.**
5. **LOC-driven scope expansion regresses pass rate** (yaegi A7→A8): adding +3 tests for LOC threshold caused 18%→0%. Don't expand scope for LOC alone.
6. **Fairness-round churn from implicit-contract leakage** (yaegi-checkpoint-api R17-R23): 7 successive fairness FAILs each revealing one unstated reviewer expectation (bare-path canonicalization, observer registration order, History defensive copy, Restore-skips-Observer, per-symbol Generation, nil callback rejection, malformed-path rejection in Resolves). **Each adds ~10-30 words to meta + 0-2 spec sentences.** Cumulative meta growth 330 → 497 words over 8 rounds. **Pre-empt at design time:** before submission, list every behavior a test asserts that the spec does NOT name. Add a single sentence per behavior, or remove the test if the behavior is over-specific. Tracker rule: every backticked NEW public API needs spec sentence for (a) success case, (b) malformed-path case, (c) side-effect interaction with snapshot/restore/observer if applicable. Missing any of (a-c) = future fairness flag.
7. **Diamond Auto Review weighs V2-carryover; Olympus does not** (yaegi-checkpoint-api R24). Once Auto Review FAILs on a prior-round flagged item, the only paths are (i) apply the V2 fix, (ii) tier-downgrade. Re-running Diamond Auto Review without addressing the flag will FAIL again. Tier-downgrade is ~12 iterations cheaper than continuing Diamond cycle when iteration history has contradictory reviewer waves.

### Stale-on-edit tax (reversion cost)

| Submission | Reversion events | Extra eval rounds |
|---|---|---|
| dasel-csv | 3 reverts | ~5-7 extra runs |
| cliffy-undo-history | 1 | 3+ |
| dasel-multi-file | 1 | 2+ |

**Lesson: aim for 1-2/12 hardened, not 3-4/12 borderline.** Reversion cost > variance gain.

### Iteration round-allocation budget (target ≤6 rounds)

Optimal Diamond cycle:

1. **R0 — Smoke test** (1x Castor or Vega): env blocker insurance. Catch Docker/JUnit failures BEFORE spending 10x.
2. **R1 — Initial 10x Castor + Diamond Checks**: should land 0-3/10. >5/10 = too easy.
3. **R2 — Difficulty tuning** (one intervention only): if 0% → add hint OR document trap; if >30% → add NEW behavioral requirement (don't remove).
4. **R3 — Re-run 10x Castor**: target 1-3/10.
5. **R4 — Hardening pass**: strengthen assertions (expect -10pp), add cross-package test if median msgs <100.
6. **R5 — Auto Review + Holistic Review**.
7. **R6 — QA artifacts**.
8. **R7-R12 — Failure-QA rounds** (separately budgeted, see § 5).

**Skip rounds 4-5 only if R3 lands 1-2/10 cleanly with median msgs ≥100.**

---

## Section 5 — Failure-QA Discipline (4-6 round attrition)

Mean QA rounds when reached: **4-6**. Each round fixes 1-2 annotations from "acceptable" → "good" while a DIFFERENT annotation becomes the weakest.

### The 6-round rejection pattern (cliffy-command-aliases)

| Round | What was rejected | Fix applied |
|---|---|---|
| R1 | Step references, verbose AI tone, factual mistakes (wrong call paths) | Cut verbosity ~54%, removed step refs, verified facts |
| R2 | Shorthand instead of audit-grade "Expected X, got Y"; fairness conflated spec + inference | Explicit expected-vs-actual for every entry; separated spec from inference |
| R3 | Fabricated variable names (`_aliasRegistry._local`) | Removed all fabricated identifiers; behavioral descriptions only |
| R4 | Wrong control-flow descriptions ("recorded before cancellation check" — actually INSIDE cancel branch) | Read failing solution's actual code; describe what code does |
| R5 | Non-self-contained entries ("same as above") + generic phrases instead of API names | Every entry self-contained; cite actual API method names |
| R6 | **APPROVED** | — |

**7th distinct failure pattern (yaegi-generic-constraint-fidelity reviewer change-request, QA-only round):** even after the validator passed all-true, the human reviewer change-requested on (a) **mis-attribution** — a run's cascade tests grouped under a typed-pin Expected/Actual giving wrong expected/actual/root-cause (rule 29), (b) **over-collapse** — 14-18 distinct-assertion tests summarized with 2-3 broad example exprs instead of per-test mapping (rule 28), (c) **per-test looseness** — three rune tests sharing one example when their calls/assertions differ (`('a','b')` vs `('m','a')`, plus a `reflect.Int32` kind check) (rules 28/30), and (d) **success-QA verbosity + cross-run leakage** — a "R12 Castor failure cluster" stat in test-groups.md and diff-step narration in PASS trajectories (rules 31/32). None of these are validator-flaggable (the validator checks identifier substance, not grouping fairness or per-test completeness) — they are reviewer-only judgment, which is exactly why reading the approved gold-standards first (Zeroth Rule) is the cheap fix. Fixing cost: one QA-only round, no Castor stale.

### 33 failure-QA writing rules (rules 1-12 from 6 subs + cliffy-command-aliases; 13-20 from yaegi-generic-constraint-fidelity R13-R15; 21-27 from yaegi R-current 81-test validator arc; 28-33 from yaegi reviewer change-request round + the two approved-diamond gold-standards + official rubric)

> **Overarching principle (read before the list):** the auto-validator and the human reviewer reward the SAME thing — claims grounded in the real method/helper names, accurate final-state behavior, and verbatim error strings. Line numbers are optional scaffolding. The approved cliffy failure-qa is the gold standard: short declarative sentences, named API methods, behavioral cause-to-effect, zero line numbers, zero AI cadence. Write that way and you satisfy both gates in one pass.

> **⭐ ZEROTH RULE — read the gold-standards + rubric BEFORE drafting.** Before writing any Diamond QA, open the two approved failure-qa.md files (`diamond-problems/approved/cliffy-command-aliases/failure-qa.md`, `diamond-problems/approved/dasel-csv-options/failure-qa.md`) and the official Diamond-Tier Task Guide rubric. They are the proven format — copy their shape (Success Solution Explanation + inlined Test Summary with spec quotes + per-run Success Trajectory Analysis with `Correctness confidence` + `Issues:` + per-failure Unfairness/Root-cause). cliffy's 6-round rejection arc IS your pre-write checklist; matching their structure on the first draft is what avoids the reviewer change-request round entirely. Skipping this is the single biggest cause of QA iteration. **2x-CONFIRMED (both 2026-05-31 yaegi approvals):** yaegi-generic-constraint-fidelity burned 4 avoidable QA-only rounds and yaegi-channel-diagnostics 6 validator rounds, both because the gold-standard read happened AFTER the first draft instead of before. Both reviewers approved only once the QA was per-test factually correct ("gtg. qa is now factually correct"). The QA has its OWN approval gate independent of solvability/Holistic/Auto-Review -- a submission that already passed all three can still be change-requested purely on QA accuracy. Treat failure-qa.md + test-groups.md as gated deliverables, written gold-standard-shaped on the first pass.

1. **Read 3 files before writing any QA**: agent's solution diff + trajectory/trace + test output. Skipping any → fabricated root causes.
2. **No trajectory step references.** Never "At step 21, the agent...". Describe final code state.
3. **No cross-run comparisons.** Never "Same bug as Castor #1." Self-contained.
4. **Audit-grade expected-vs-actual.** Every failed test gets explicit "Expected X, got Y" with LITERAL values.
5. **Separate spec from inference.** Quote spec verbatim, THEN note what test INFERS from API surface.
6. **No fabricated identifiers.** Every named variable/method/field exists in actual solution.
7. **Match actual control flow.** Read failing solution before writing root cause.
8. **Self-contained entries.** Reviewers read non-sequentially.
9. **Name actual API methods.** `getAliasRegistry()` not "the registry code." `clearRegisteredAliases()` not "the clearing method."
10. **Plain ASCII.** No em dashes, no Unicode arrows. `--` in prose is AI tell.
11. **Concise.** Unfairness check: 2-3 sentences with prompt citation. Root cause: 2-3 sentences with code reference.
12. **Pre-existing code root causes need extra context.** When bug is in code agent didn't modify (not in diff), QA must explain pre-existing code AND why agent's new code interacts incorrectly. Example: dasel-multi-file's pre-existing `o.InFormat = o.OutFormat` crossover is NOT in agent's diff; QA must say "original `run.go` has X mutation at line Y; agent's new code reads already-mutated value."
13. **Triangulate by NAME, not by line number.** (yaegi-generic-constraint-fidelity R15 + R-current 81-test arc.) The validator independently locates the lines itself; it earns a `true` verdict by grepping the named identifiers you cite and matching the behavior against the code. **Line numbers are optional aids, NOT what passes the check** — the cliffy-command-aliases approved failure-qa carries ZERO line numbers and passed both the auto-validator and the human reviewer. Anchor each root cause on three NAMES: the agent's helper/method (what it did), the repo mechanism by function name (why it misfires), and the verbatim error string (observed symptom). Example: typed-pin root cause names (a) the reconciler's `matchDefault || assignableTo` guard, (b) yaegi's loose `assignableTo`, (c) the `157/50 truncated to int64` symptom. What actually triggers MIXED is an imprecise or unverifiable claim (rules 21-27), never the absence of a line number.
14. **Verbatim repo citations, not paraphrases.** (yaegi R14.) Validator literal-greps byte-level. `"runtime checking"` paraphrase fails when source says `"to be tested elsewhere"`. `untyped float` `id()` is `"untyped float"`, NOT `"untyped float64"`. Read the actual repo line before writing the citation; do not paraphrase yaegi/repo internals from memory.
15. **Quote prompt language verbatim, backticks preserved.** (yaegi R15.) When citing meta.md sentences as the controlling spec, include backticks: `` `Kind` `` not `Kind`. `` `mismatched types` `` not `mismatched types`. Validator string-searches the description for verbatim match.
16. **Bool predicates ≠ error-emit sites.** (yaegi R13 Lesson 9.) When attributing diagnostic text, find the actual `cfgErrorf`/`fmt.Errorf` call site. Bool predicates (`isFoo`, `matches`, `representableConst`) return true/false and never emit error strings; the surrounding `if !pred {...}` is where text is formatted. Cite the emit site.
17. **Test token references must exist in test_patch.** (yaegi R13 Lesson 10.) Validator literal-searches test_patch. Reference functions by exact identifier (`MinX`, `EqX`, `AddCX`) not with ellipsis (`MinX(...)`, `EqX(...)`). Reference helpers that actually exist (`runOKKind` at `test_patch:334`) not stdlib calls the test doesn't make (`reflect.Value.Kind()`).
18. **Interpretive framing accepted when grounded.** (yaegi R15 Lesson 14.) Tag fairness calls and classifications explicitly ("Unfairness check: Fair", "Classification: incorrect assumption"). Validator accepts "interpretive but well-grounded" when paired with concrete code citations. Bare interpretive claims with no code-anchor get MIXED.
19. **Causal chains pass when every step names a real identifier.** (yaegi R15 + R-current.) Multi-step explanations like "the guard accepts the untyped float, instantiation continues, the type checker's float-to-int conversion emits `cfgErrorf`" pass when each step names the actual function/predicate and the behavior matches the code. A skipped or hand-waved step gets MIXED even when the conclusion is right. Line numbers optional; named identifiers are mandatory.
20. **trajectory_feedback annotations = same audit rigor as test_failure.** (yaegi R15 Lesson 19.) PASS-run trajectory commentaries get validated the same way: named identifiers, exact quotes, distinguish predicates from emit sites. Do not treat PASS sections as low-stakes prose.

21. **A multi-line code fragment cannot be cited as a single backticked literal.** (yaegi R-current S#9.) The validator literal-greps backticked tokens; `` `if it.untyped { def = defaultedItype(it, nil) }` `` was MIXED because in the diff that code spans three lines (873-875), so the one-line literal matched nothing. Fix: either cite the pieces as separate tokens (`` `if it.untyped` `` and `` `def = defaultedItype(it, nil)` ``) or, preferred, describe the behavior and name the function (`defaultedItype`). Never embed a composed multi-line code block as one backticked string.
22. **No placeholder tokens in cited strings.** (yaegi R-current S#4.) `` `untyped X does not implement main.Y` `` was MIXED — the `X`/`Y` placeholders match nothing. Cite a concrete instance that appears verbatim in junit: `untyped float does not implement main.OrderedX`.
23. **No truncated error strings.** (yaegi R-current S#4.) `` `operator == ...` `` and `` `untyped float does not implement ...` `` get MIXED. Quote the full verbatim string: `invalid operation: operator == not defined on main.ASX`. (Exception: a genuine format string with `%s` verbs is fine — that IS the literal in the source.)
24. **Claim only the mechanism the diff actually shows.** (yaegi R-current S#8.) Root cause said the constraint name "is derived from a named-interface identifier" — MIXED, because the diff merely passes an empty string literal `""` at the call sites; the derivation mechanism was never in the patch. State what the diff shows (empty-string argument at the named call sites), not an inferred mechanism you did not see.
25. **Don't claim "hidden suite untouched" OR a blanket "no test-file hunks" without checking the diff headers per run.** (yaegi R-current S#7/S#9.) "Hidden suite untouched" is unverifiable (hidden tests are not in the agent patch). "No test-file hunks" is FALSE whenever the agent adds its own in-repo test file: S#9 added `interp/constraint_test.go` so that claim went MIXED, while S#7 genuinely had none. State only what the diff headers show, per run: name the confined paths AND any in-repo test file the agent added (e.g. "confined to `cmd/yaegi/run.go` and the `interp` sources, including a new `interp/constraint_test.go`"). Read the diff headers before writing this sentence.
26. **Match the symptom string junit actually renders, not the Go identifier.** (yaegi R-current S#4.) junit shows `errors.Is(err, type is not comparable)` (the sentinel's `.Error()` text), not `errors.Is(err, ErrNotComparable)`. When quoting the Actual line, mirror the rendered text; name the Go sentinel separately in prose if needed.
27. **Enumerate every failing test; the count must equal (total - passing).** (yaegi R-current S#10.) "Representative" lists and ranges like "15-21/22" undercount. A 22-fail run must name 22 tests. After writing each FAIL section, verify the listed-test count equals `total - passing` for that run.

28. **Group ONLY tests that share the same failure signature AND assertion shape; map each test when they differ.** (yaegi reviewer change-request, S#4/S#5/S#10.) Rule 16's "combine same-root-cause failures into one entry" applies only when the grouped tests assert the SAME shape (dasel's 16 null-write tests all assert "model null -> csv-null string", so one Expected/Actual covers them). When each test in the cluster has a DISTINCT call, value, or kind (`MinX(2*1.5, 1.0)` -> `1.0` vs `DoubleX(3.5)` -> `7.0`/`Float64` vs `WideX(3.14, 2.71)` -> `2.71`), a single broad example is "over-collapse" and gets change-requested for "not mapping each exact test assertion." Map each test with a per-test row — `| Test | Call | Expected | Actual |` — then write the shared root cause ONCE below the table. The table delivers per-test exactness; the single root cause avoids repetition. Both demands are satisfiable at once.
29. **Never put two tests under one Expected/Actual unless they produce the same junit error class.** (yaegi reviewer change-request, S#10 — the most damaging miss.) S#10 lumped four promotion-cascade tests (`nested_eq_of_min`, `nested_eq_of_add`, `double_chain`, `ConstraintCallback_NotFiredOnSuccess`, all failing `untyped float does not implement main.X`) under a typed-pin Expected/Actual (`MinX(int64(3), 3.14)` -> `157/50 truncated to int64`). That gave the wrong expected, wrong actual, AND wrong root cause for those four — the reviewer called it "not just generic grouping; it gives the wrong expected behavior, wrong actual behavior, and wrong root cause." Before grouping, confirm every test in the block emits the SAME junit error string class. A cascade failure (inner call rejected during promotion) is a different signature from a typed-pin truncation even when the two clusters sit adjacent in the same run — split them into separate `### Failed Tests` blocks with separate root causes (one cites the promotion-ordering defect, the other the loose `assignableTo`).
30. **Pull every call/value/kind/error from the run's ground-truth `failing-test.md`, never from memory.** (yaegi reviewer change-request.) The reviewer caught `char_lit_satisfies_constraint_with_int32` written as `MinRuneX('a','b')` when the test actually calls `MinRuneX('m','a')`, and `min_with_untyped_rune_returns_int32_kind` missing its `reflect.Int32` assertion. Each Castor folder's `Castors/S#N/failing-test.md` carries the junit error line AND the verbatim test body — copy the call expression, expected value, any kind assertion, and the error string straight from there. Reconstructing from memory across near-identical tests reliably swaps literals.
31. **Strip agent-diff line numbers entirely; keep only stable base-repo anchors, sparingly.** (yaegi reviewer change-request + both approved diamonds.) `(diff line 491)` points into the FAILING AGENT's run diff, which the validator cannot grep (it greps the submission + repo, not the agent's per-run diff) and the reviewer reads as fabricated precision. BOTH approved diamonds carry zero line numbers anywhere. Name the construct instead: "the `matchDefault || assignableTo` disjunct", "`newConstraintError` called with an empty `constraint` argument", "`checkConstraintAt` runs before `resolveUntypedForConstraint`". Base-REPO anchors that are stable across runs (e.g. `interp/type.go:1466` for the loose `assignableTo`, `interp/typecheck.go:1142-1143` for the truncation emit) are acceptable because they are greppable in the repo — declare them once in a header sentence and reuse — but the gold-standards omit even these, so lean on names.
32. **Test Summary inlines every group with a verbatim spec quote and closes with a coverage statement.** (official rubric + both approved diamonds.) cliffy (8 groups) and dasel (22 groups) both inline the grouped summary directly in failure-qa.md, each group as `**Group N: title (M tests).** <one line of what it tests>. From the description: "<verbatim quote>"`. The rubric requires a closing line: "ensure that every requirement in the prompt is tested by at least one test group" — write that mapping explicitly. test-groups.md remains the detailed companion (and must NOT carry cross-run stats like "R12 cluster: 6/10 fail" — keep it run-independent). **Attribute quotes to "the description"** (the platform's name for the task text) — NEVER "quoted from meta.md" / "from the prompt" / any local filename. `quoted from meta.md` is a recurring agent mistake and is not acceptable: meta.md is only the local filename for what the platform shows as the description. More broadly, no local workspace filename (meta.md, test.patch, solution.patch, Dockerfile, Castors/, sol-dif.md) may appear anywhere in the artifact text — use platform-facing terms (the description, the tests / hidden test suite, the agent's submission, the reference solution). A concrete repo SOURCE path is fine only when it is part of the agent's own diff (a test file the agent added).
33. **Unfairness check names the test's assertion mechanism, not only the spec quote.** (official rubric: "explain how the test case code correctly validates that requirement.") After the verbatim prompt quote, state the assertion helper and what it checks: "`runErrIs` asserts the error unwraps via `errors.Is` to `interp.ErrMismatchedTypes`", "`runOKKind` asserts the returned value AND its `reflect.Kind`". The quote alone is insufficient; the reviewer wants the prompt-to-test linkage shown, and the rubric's GOOD example cites the exact test setup snippet. **Two validator traps in this clause (yaegi post-rewrite re-run, 2 MIXED of ~140 claims):** (a) when a cluster's tests use DIFFERENT helpers, name each -- do NOT generalize `runErrIs` across a test that actually uses `runStructuredErr` + a manual `errors.Is` (S#2 went MIXED on "the tests assert ... through `runErrIs`" because `typed_pin_mismatch_is_constraint_error` uses `runStructuredErr`); say "three assert via `runErrIs`; the fourth uses `runStructuredErr` then `errors.Is`". (b) A fairness rationale that asserts an EXTERNAL fact the validator cannot grep (e.g. "compiles under `gc`") must be framed interpretively or dropped: a bare "Each call compiles and runs under `gc`" went MIXED because the token `gc` is absent from test_patch (S#5), while the SAME point with interpretive framing -- "...so a seasoned engineer would expect instantiation" (S#4) or "valid Go calls a seasoned engineer would expect to instantiate" -- passes. Rule of thumb: if a clause states a fact the validator would try to grep and fail, either anchor it to a real identifier or convert it to an explicit "a seasoned engineer would expect..." judgment (rule 18).

34. **Value-anchored line numbers are MIXED bait; describe the field by name. And never cross-attribute the passing tests' success inside a failing block.** (yaegi post-rewrite re-run #2 — 2 more MIXED, both this class.) Two sub-rules:
    - **(a) Line numbers come in two flavors, and only one is safe.** A *value-anchored* line number presents the line AS the locator for a specific field/string value: `` `str` is `"untyped float"`, `interp/type.go:160` ``. The validator greps line 160 for that string, finds it at 161, and the cited line now CONTRADICTS the value -> MIXED. A *behavior-anchored* line number is incidental to a named-function behavioral claim: "the loose numeric check `assignableTo` (`interp/type.go:1466`), which accepts an untyped float against an `int64` target" — here the validator matches the BEHAVIOR via the function name and tolerates an off-by-N line. **The validator is non-deterministic on value-anchored lines** (S#4 carried the identical `:160` token and passed `true` the same round S#5's `:160` went MIXED), so the only stable fix is to delete them: write `name: "int32"`, `str: "untyped rune"` with NO line number. Keep at most the behavior-anchored ones, and only when you have read the exact line this session. Never quote a field value from memory with a line number attached.
    - **(b) A failing-test block explains only why THOSE tests fail.** Do not causally attribute the OTHER (passing) tests' success to a named branch — "that `def.equals(c)` branch resolves the untyped float and complex cases" went MIXED because, for that agent's code, `defaultType(reflect.Value{}, sc)` with a zero Value does not actually promote, so the cross-test causal claim was unverifiable (it happened to hold for a different agent's code in another run). Per-agent implementations differ; a passing test in the same run may pass by a different mechanism than the one you are describing. Ground the rune block on the rune failure mechanism alone (`equals` compares `id()`, which returns `str`; the rune's `str` is `"untyped rune"`, not the `int32` member, so `def.equals(c)` is false).

35. **Every falsifiable TOKEN is checked, not just line numbers and code citations — write the MINIMAL claim.** (rdb-sample-fraction reviewer-then-validator arc, R11-R14e, six rounds, APPROVED 2026-05-31.) Beyond rules 13-34, five more token classes flag:
    - **(a) Per-run impl facts come from THAT run's ground-truth sol-dif, never inferred from a sibling run.** rdb S#4's sampler was a hand-written FNV (`offset64`/`prime64`); written as "stdlib `fnv.New64a`" because S#7/8/9 used stdlib -> MIXED. Read all N sol-difs; each agent's hash/algorithm is its own.
    - **(b) Quote code as the patch splits it.** A single token `score := float64(h.Sum64()>>11) / ...` MIXEDs when the diff writes `v := h.Sum64() >> 11` then `score := float64(v) / ...`. Cite the two lines, or name the function and describe (restates rule 21 for non-yaegi repos).
    - **(c) No absolute claim the artifacts contradict.** "must leave a non-empty subset, never zero" went FALSE because the junit shows zero DID occur (the agent's bad hash); "so a count of zero is a coding fault rather than a test artifact" went FALSE because the description does not mandate per-subgroup non-emptiness. Use the bare interpretive shape that passes: "A 0.5 fraction over an ordinary 50-key group must keep a non-empty subset" — no "never zero", no "coding fault".
    - **(d) Name the REPORT each assertion reads, not how it is produced.** "the separator-prefix rows built over the sampled memory pass" MIXEDs — those rows come from `SepPrefixAnalyse`, not a memory pass. Say "from a separator-prefix row." And reserve "reads directly off the sampled aggregate" for a genuine direct field read; a path through an intermediate aggregation FALSEs the word "directly."
    - **(e) No cross-run comparison inside a single run's entry, including PASS trajectories.** "where the nine other runs sampled an entire group empty or whole" MIXEDs — this run's artifacts cannot evidence other runs (restates rule 3/8, but it recurred under a `trajectory_feedback` PASS block, so it bites those too).
    The deterministic shape for empty/full-sample failures: state the accept predicate verbatim (`(sampleHash % denom) < threshold`), cite the verbatim junit string, conclude "landed at or above/below the cutoff." Use prefix forms (`acct:`), never literal `:N` (fixtures build keys with `+strconv.Itoa(i)`, so `acct:0` is in no artifact). For a PASS run that diverges from an instruction the hidden tests do NOT enforce (rdb decode-and-discard vs byte-skip): do not call it "fully correct" — flag the divergence in `Issues:` only, at honest severity (4, not a throwaway 2), and cap `Correctness confidence` (<=4). **Meta-lesson: the auto-validator passing all-true (rdb R13) did NOT catch the overclaims the HUMAN reviewer flagged (R14); the reviewer flagged them, then the validator nitpicked every qualifier added fixing them (R14b-e). Each round added one more falsifiable token. Write the minimal claim — report + predicate + verbatim junit, nothing more.** Repo-specific scaffolding + the full arc: `analysis-folders/rdb-analysis/LESSONS.md`.

    **Grouping refinement (approved data point, refines rules 28/29):** rdb grouped 2-4 SAME-junit-signature tests per block (two acct tests, four-report runs, expiry+stream) and the human reviewer ACCEPTED with "some entries could be separated instead of grouping them. still acceptable coz good writing." So grouping BY JUNIT SIGNATURE is fine (not change-requested) PROVIDED each block carries a per-test `| Test | Call | Expected | Actual |` table + one shared root cause + clean prose. Per-test separation is marginally preferred but NOT required. (Rules 28/29 still forbid grouping tests with DIFFERENT signatures — that gives wrong expected/actual/root-cause.)

### Grouping-binding rules 41-47 (yaegi-channel-diagnostics arc; full prose in DIAMOND.md 41-47)

41. Validator binds claims to the PLATFORM's behavioral grouping (test-file group prefix), not your symptom split. Align blocks to it; never regroup along a symptom axis that cuts across it, even on reviewer request - split symptoms INSIDE the bound block.
42. A whole-group claim must hold for EVERY test the platform binds there; symptom-mixed group -> both-manifestations claim, not a single-symptom sweep.
43. Per-run agent code differs: a mechanism TRUE in one run can be FALSE in another with the same symptom. State only what THAT run's diff supports.
44. A bare backticked repo identifier the validator greps (e.g. `rangeChan`) is grep-variance-prone. Anchor path-miss claims on the agent helper + behavior + junit symptom.
45. Cite the helper holding the switch, not the wrapper that delegates. No struct-literal tokens the diff lacks.
46. Fairness check: name only the bound group's members or stay generic-to-contract; don't cite other tests' scenarios.
47. Stale-verdict guard: grep flagged strings in the current file before re-editing; a verdict can score a pre-edit upload.

Also: test-groups.md grouping must match a test's ACTUAL assertions not its name/adjacency. Env Description = 2-3 sentences, no `#` title, neutral challenge framing (recipe detail belongs in solution-approach.md). Env Description + both QA artifacts are QA-tier (do not stale Castor / Diamond Checks).

### Post-eval rules 48-53 (scriggo-generics arc, approved 2026-06; full prose in Pattern 49 + DIAMOND.md § failure-qa.md Structure)

48. **Artifact-grounded root cause, NOT mechanism-speculation.** "The agent does not handle X" validates FALSE when the diff HAS X-handling (the bug is subtle within it). Write the observable error/panic + "the concrete equivalent passes in other runs, so the defect is how THIS agent specializes it." scriggo dropped "doesn't substitute the composite in a `:=` left-hand context" and "leaves an unsubstituted node in the for-range" after both validated FALSE (agent had assignment + ForRange substitution).
49. **Helper-chain attribution** (= rule 45 sibling): name the function that does the work. "`runGenericsOut` builds and runs" FALSE -> "`genericsOut` builds and runs; `runGenericsOut` iterates through `assertGenericsOut`."
50. **Cascade run (a panic inflates the JUnit fail count): split, do not collapse.** One box per real failure (+ its parent group row, which executed) + one box for the synthetic remainder reported by the exact marker `new tests were missing from the JUnit XML (exit code 1)`. Never "did not execute" for a test that ran. Every box, incl. the cascade box, gets Root cause + Type of error.
51. **Multi-signature run: re-verify the UI annotation testName buckets.** They get CROSSED (pointer test filed under the bare-name box, and vice versa) even when the failure-qa.md prose is correct. Expand each Shipd group; confirm testNames 1:1 with their explanation. The reviewer catches the swap.
52. **Wording-mismatch contest:** rest on repo convention (the diagnostic the codebase already uses + its helper, e.g. scriggo `X redeclared in this block` + `redeclaredInThisBlock`), not "the agent chose it." Give honest pass-rate numbers; do not overstate "loosening = too easy." Difficulty never comes from substring grammar; substrings exist only for fail-on-base.
53. **solution-approach.md = high-level, non-expert, public/observable surface only.** ZERO internal private helpers, file paths, or line refs (scriggo reviewer reject). Calibrate to the two approved shapes by feature type (see Section 6.3).

### Post-eval rules 54-58 (csstree-calc-typecheck arc, approved 2026-06-05; 3rd validator confirmation; full prose Pattern 50)

54. **Baseline count = the PLATFORM junit number, not the local runner.** Cite `junit_baseline_xml tests="N"` / `test_log` "baseline_passed (N/N)" (csstree: 4000, NOT local mocha 16725). "all 16725 baseline pass" validated MIXED.
55. **No per-agent MECHANISM claim** (rule 48 for a 3rd repo): "gate not routed back", "`<number>` in the accepted set", "rejects a wrong dimension" were each FALSE for the flagged runs. Anchor on the junit Actual + the behavior shared by EVERY run in the testNames group.
56. **The platform GROUPING is GIVEN in the response `testNames` arrays — align blocks to it** (rule 44/51 confirmed): 10/11 csstree runs matched my blocks; 1 diverged (clamp grouped with the gate tests) -> re-cluster with a both-manifestations root cause. Read the arrays from the FIRST validator response, don't guess.
57. **Quote backticked CALLS verbatim from test source** — variable vs inline: `comparePriority(ast, 'b', 'a')` not `comparePriority(parse(...), 'b', 'a')` when the test assigned `const ast = parse(...)`. A paraphrased-equivalent call greps to MIXED.
58. **Soften absolutes + know the junit quirk.** "the only failing choice" -> "a node that is neither ... fails the assertion". `assert.ok(falsy)` in csstree renders `Attempted to read a non-own property` (setup.js proto-guard), not `false == true` — cite verbatim.

**Iteration note (csstree):** the FALSE/MIXED count dropping ~10 -> 3 -> 1 -> 0 over 3 rounds matches the yaegi-generic pattern below. The expensive avoidable round was trap-stacking on an UNMEASURED artifact (added 2 traps assuming "too easy"; a real 10-Castor showed it was already 0/10, reverted) — see Pattern 51. Also: a 3-rollout Diamond Check fluked a lone 1.00; the 10x showed 0/10. Run >=10 before trusting solvable.

### Post-eval rules 59-64 (yaegi-const-representability arc, Diamond approved 2026-06-06; 4th validator confirmation; full prose Pattern 52)

59. **Run a backticked-token grep gate BEFORE upload — the single highest-leverage pre-submit check.** Extract every backticked token in failure-qa.md and grep each against test.patch + the run's agent diff + the repo source; any token with zero matches is a MIXED candidate. This cycle burned ~6 validator round-trips on tokens one grep would have caught. Consolidates rules 13-26 into one mechanical gate; run it the way the validator does (literal substring), not by eye.
60. **Comparison-operator / threshold flips MIXED.** `` `len(d) >= 3` `` greps to nothing when the source is `if len(d) < 3 {` (the test asserts the FAILURE guard, not the success threshold). Cite the source's actual comparator verbatim; put the requirement ("at least three") in prose, never as an inverted code literal.
61. **Substituted-argument / ellipsis-abbreviation forms MIXED; cite the variable the test passes.** `` `errors.Is(err, ErrConstantTruncated)` `` greps to nothing when the helper calls `errors.Is(err, sentinel)` (a loop variable) — quote `errors.Is(err, sentinel)` and name the concrete sentinel in prose ("`sentinel` is `ErrConstantTruncated`"). Same class: `complex(...)`, `[]complex128{...}`, `n.cfgErrorf("...", ...)`, `constToInt(constant.ToInt(...))` — any `...` inside backticks. Either cite the full literal or drop the backticks and describe (rule 17/21/22 generalized to the argument list, not just the call name).
62. **Fabricated call-result literals MIXED.** `` `constant.BitLen(256)` is 9 `` — the call `BitLen(256)` appears in no artifact. State the fact in prose ("256 needs nine bits, exceeding the eight-bit uint8 width"), no fake call token. (Rule 24 sibling: claim only what the artifact shows.) Likewise unsupported figures ("seventeen bits") -> compute it right or omit.
63. **Name the function/hunk the code is actually in, never a wrong-file line.** Citing `const_diag.go line 920` for code that lives in the `typecheck.go` `diff --git` hunk is MIXED — an agent's NEW file and its EDITED files are different hunks; read the hunk header above the code before naming a file. Preferred (rule 31): name the function and skip file+line.
64. **Two FALSE/over-claim classes specific to Go table-driven suites.** (a) **Parent-rollup conflation.** A table-driven PARENT testcase fails as `<failure message="Failed"/>` (empty body) whenever any subtest fails — it carries NO rendered message. "Each of the N renders message X" is FALSE; count precisely (K subtests carry the message + M parents are generic `Failed` rollups + any subtest with its own assertion text, e.g. `As_fields` -> `not a ConstantConversionError`). (b) **Stale-per-run data.** Author each block from THAT run's actual failing-test dump (count + leaf names + verbatim Actual), never from another run or memory: this arc shipped an S#11 block built on a stale 52-test list (invented a signed-nil group that did not exist; asserted "no signed-range nil failure" when there were four) and was fully rewritten to the real 57-test run. Group count must equal total - passing (rule 27 at the group level).

**Quality-lift (from the approval verdict "QAs are good, but can get more detailed with citations like trajectory steps. Acceptable"):** the Failure-QA was ACCEPTED without trajectory-step citations, but the reviewer wants more evidentiary depth. This does NOT reverse rule 2 (no "At step 21..." narration in the root cause). Keep the final-state root cause; OPTIONALLY strengthen each block with a Failure-Point-Analysis pivot drawn from the run's trajectory ("the agent's own trace gates only the `constant.Value` path and never adds a `complex128` branch"), framed as supporting evidence, not step narration. Accepted-without-it, stronger-with-it.

### Post-eval rules 65-68 (chai-array-type arc, Diamond approved 2026-06-07; 5th validator confirmation; full prose memory `lesson-diamond-failure-qa-annotation` + Pattern 53)

65. **Anchor the FIX to observable artifacts, not the hidden reference solution.** The auto-validator marks `the reference calls v.MarshalText()` "true" (it can grep `reference_solution_patch`), but the HUMAN reviewer flagged it poor: "leans on the hidden reference instead of staying anchored to the observable test expectations, failure output, and agent patch." Write the fix from what is observable: the test's scan expectation, the repo's neighboring arms, the description requirement. Replace "the reference assigns X" with "render the bracketed text the tests scan and assign that `string` (or `[]byte`), as the neighboring scalar arms convert their values." (Root cause stays grounded in the agent diff; only the FIX clause was reference-leaning.)
66. **Per-run distinct construct + UI cross-mapping.** Reinforces yaegi "each Castor run a different impl." Same surface bug failed three ways: `dest[i] = v` (raw `types.ArrayValue`), `dest[i] = arrayValue{v: v}` local wrapper (error `driver.arrayValue`), `dest[i] = v.Encode(nil)` raw bytes (EQUALITY mismatch, not a scan error). Ground each run's root cause in THAT run's verbatim construct (grep its own solution-patch). Never reuse one driver block across runs: near-identical blocks (same intro/table) get CROSS-MAPPED in the Shipd UI annotations (one run's annotation picked up another run's root-cause text; both flagged MIXED/FALSE even though the file prose for each was individually fine). Distinct per-run construct = copy-proof. (Rule 51 sibling: re-verify UI testName buckets 1:1.)
66b. **Same surface bug, two failure MODES.** One agent's wrong driver path produced a scan error (`unsupported Scan, storing driver.Value type X into *string`); another produced raw encoded bytes that scan FINE into a string but mismatch on value (`Error: Not equal, expected "[3, 1, 2]" actual "n\x03312"`). Do not assert "the quoted Scan error" for a run whose junit shows `Not equal`. Read each run's junit Actual before writing the block.
67. **Group tests by BODY assertions, not NAME.** Reviewer rejected `TestArrayTypeCrossFeatureReopenIndexLookup` filed under "Reopen Persistence" — name says reopen+index, body is in-memory `arrOpen`, no `CREATE INDEX`, no reopen; only TEXT[] equality + ORDER BY rendering. Read each test body before assigning its behavioral group; a misleading name is a reviewer change-request. (test-groups.md AND the failure-qa Test Summary both carry the grouping.)
68. **`Encode` output is the VALUE encoding, not "key-encoding."** Calling `v.Encode(nil)` bytes "the array's key-encoding bytes" is MIXED — `EncodeAsKey` is the ordering/key form; `Encode` is the value form, and the two can differ (e.g. doubles). Name the method, not an inferred role.

### Validator-iteration cost reduction (yaegi-generic-constraint-fidelity arc)

**Three validator passes typical when QA is written from memory:** R13 first pass flags ~15-20 FALSE/MIXED across 10 Castor sections; R14 second pass flags 2-4 residuals (typically subtle citations); R15 third pass clean. Cost: ~30-45 min per round.

**Reduce to ONE pass by:**
1. **Read repo source file ONCE, extract cited lines, REUSE across sections.** yaegi R15: same `interp/type.go:1490-1493` (assignableTo numeric shortcut) cited correctly across 6 sections after first verification. Same `interp/typecheck.go:1141-1143` (truncation emit site) cited in 5 sections. Verify once → propagate.
2. **Pre-write a flagged-phrase blacklist before drafting.** Common validator-flag patterns:
   - "runtime constant-folder" / "constant-folder" — yaegi has no such component
   - "constant overflow check" without verbatim "to be tested elsewhere" comment
   - "matches untyped X against typedY" without checking actual `id()` string values
   - "reflect.Value.Kind()" when test uses helper wrapper
   - Ellipsis tokens (`MinX(...)`) when validator searches function names
3. **Extract the real identifiers from `sol-dif.md` BEFORE writing prose.** Open the diff, find the hunk, note the actual helper/method names and the exact decision (`matchDefault || assignableTo`, empty-string argument, missing `arrayT` arm), THEN write the sentence around those names. Reverses the failure mode of "writing plausible-sounding prose, hoping the identifiers match." (Line numbers, if you add them, come from the same pass — but they are optional; the names are mandatory.)
4. **For each test failure, anchor three NAMES.** the agent helper (what), the repo mechanism by function name (why), the verbatim error string (symptom). If you cannot find one of the three, the attribution is incomplete. Do not pad with line numbers in place of a missing name.

### Per-passing-run QA artifacts (platform UI)

- **"Why it works" tab** (passing runs only, DIAMOND badge): explain correctness, code-review readiness, requirement coverage, no regressions, no bugs
- **Correctness confidence**: 1-5 scale. 5 = fully correct. 3-4 = minor issues. 1-2 = real bugs tests can't catch
- **Issues**: "Tests pass but implementation wrong." Severity 4+ blocks. Empty if fully correct
- **"Failing QA" tab** (failing runs only): unfairness check + root cause

### Top-level QA artifacts (per submission)

1. **Success Solution Explanation** — high-level summary understandable by non-expert
2. **Test Summary** — test groups + spec quotes per group (test-groups.md content reformatted)
3. **Success Trajectory Analysis** — per passing run, why correct + no regressions

### Failure-QA writing tone (from approved templates)

- Every "Fair." followed by quoted description text
- **Final-STATE framing, present tense** ("The reconciler accepts the untyped float", "checkConstraint rejects it before defaulting") — never trajectory-sequence ("after the agent saw failures it patched..."). The submission is judged on final code, not the development sequence.
- **Do NOT mechanically open every paragraph with "In the final code, the agent...".** That repetition is itself an AI tell. The approved cliffy failure-qa varies openers ("The agent stored both maps...", "The failure is in getAliasRegistry():", "The agent correctly separated storage, but...") and several entries drop the prefix entirely. "In the final code" is one optional way to signal final-state, not a required opener.
- **Match the approved cliffy root-cause shape:** 2-3 short declarative sentences, naming the real method, stating cause then effect. Example: "The agent stored both addAlias and globalAddAlias entries in the same map. clearRegisteredAliases() clears that entire map, removing `b` along with `d`." No inline `(diff lines X)` spam, no compound multi-clause sentences.
- Inference defense: when a test relies on inference, note "this is an inference from combining two explicit statements" or "a defensible one given the test setup".

### Hinted-runs QA discipline (admin Leonard 2026-05-28)

When the unhinted Castor batch lands 0/10 and the problem is fair, the admin path is hint-augmented runs. QA load is REDUCED for the hinted half:

| Run set | Failure QA | Success QA |
|---|---|---|
| 10 unhinted runs | required per failing run | required per passing run |
| 10 hinted runs | NOT required | required per passing run only |

Net: hinted failures skip the audit-grade "Expected X, got Y" + multi-cite triangulation that unhinted failures get. Saves several hours per problem.

**Hint authoring rules (stricter than legacy):**

- Hint is valid only if a human expert with access to description + repo could infer it. The hint just makes implicit universals explicit (e.g. "Constraint field populated for every Kind", "representability is Go-spec strict").
- Hint is invalid when it leaks implementation: helper names, file paths, algorithm steps, library functions to call.
- Library/version specifics are fair (behavioral, not prescriptive).
- Every hint MUST include a "why inferrable" justification — one or two sentences pointing to the spec text or repo evidence the hint follows from.

**Cost model for hint path:** 1-2 Castor cheap-test before committing 10. If the test pair shows no movement, the hint is wrong; iterate before burning the rest. 10 hinted total = ~125 tokens (post-throttle halving).

**Ceiling sanity:** if all 10 hinted pass, unhinted meta is too ambiguous or under-spec'd. Re-examine before submitting.

### Hint-writing craft (yaegi-channel-diagnostics, approved 2026-05-31 — hint moved 0/10 -> 1/10)

The legacy rules above say what a hint may CONTAIN. These say how to WRITE one that lifts the pass rate into the band without over-solving. Source: a single for-range hint that took unhinted 0/10 to hinted 1/10 (10%, within <=30%), with ZERO hinted runs failing on the hinted axis.

1. **Hint the WIDEST near-miss axis, not the hardest trap.** Pick the single failure mode that blocks the most otherwise-strong runs at the cheapest cost. yaegi-channel-diagnostics: 4 of 10 unhinted runs were 45/46 blocked ONLY by the for-range miss, and 7/10 missed it overall - hinting that one axis moved every one of those agents forward onto the genuinely-hard parts. Do NOT hint the load-bearing trap (the false-deadlock debounce); that is the difficulty you are keeping.
2. **A good hint REDIRECTS attention; it does not SOLVE.** The shipped hint pointed at "a `for v := range ch` loop receives on every iteration, record it like any other receive" and deliberately left the 4 hard parts (50ms debounce, spawn-path tracking, deferred-close goID, non-destructive select probe) untouched. Result: runs failing on those still failed, so the ceiling stayed well under 10/10. If your hint plausibly unblocks the hard part too, it is over-solving - narrow it.
3. **Predict the hinted ceiling BEFORE running, from the unhinted failure histogram.** Count how many runs fail ONLY on the hinted axis (those convert to passes) vs how many also fail a non-hinted hard part (those stay failing). yaegi: 4 range-only near-misses + 6 also-fail-hard-parts predicted ~4/10 ceiling; actual 1/10 (the hard parts bit harder than predicted, which is fine - under the ceiling is the goal). If your histogram predicts >7/10 convert, the hint is too broad OR the unhinted meta is under-spec'd; fix the meta, do not ship the hint.
4. **Ship the hint as a 4-part structured block, not a bare sentence:** (a) a one-line failure-histogram rationale (X/10 miss this axis, Y are near-misses blocked only by it), (b) the hint text itself, (c) the "why inferrable" justification pointing at the exact spec sentence the hint makes explicit, (d) a "why it does not over-solve" paragraph naming the hard parts left untouched. Parts (c) and (d) are what a reviewer checks; writing them forces you to confirm the hint is fair AND non-solving before you spend tokens. (The shipped `hint.md` is the template.)
5. **The hint text names only language-level / spec-level vocabulary.** "a `for v := range ch` loop" is Go syntax (allowed); "call `noteRecv` in `rangeChan`" is a helper + file (leak). The test: could a competent engineer who never saw the solution write this sentence from the description + the language spec alone? If yes, fair.
6. **Cheap-test the prediction, not just the mechanics.** Run 1-2 hinted Castor and confirm BOTH: the hinted axis now passes (hint works) AND the hard parts still fail (hint did not over-solve). A hint that flips the cheap-test pair to full passes is over-solving even if it looked narrow on paper - re-narrow before the full 10.

---

## Section 6 — Cross-Cutting Diamond-Specific Behavior

### Castor agent profile (cross-submission patterns)

- **Pass-rate ceiling: 30%** post-relaunch 2026-05-13. >30% = TOO EASY, redesign.
- **Token throttle: 25 tokens/run** (temporary). Each 10x run = 250 tokens.
- **Median msg counts**: passing 60-141, failing 187-328. >100 median signals adequate complexity.
- **Bash sandbox death rate: ~25%** on multi-layer Go problems (228-328 msgs).
- **Go.mod version bump**: Castor dismisses self-caused regressions as "pre-existing" — 40% trip rate in tengo-crypto.
- **Equals() override**: Castor 90% pass vs Nova 12.5% — different blind spots, not "Nova in disguise."
- **Compile-time transform = shallow well**: Castor aces a pure compile-time transform over a language subset on the common path. scriggo functions-only monomorphization = ~98% pass (4 agents 111-114/116); the predicted erasure trap never fired because the natural clone-and-recheck yields concrete kinds for free. Difficulty must be engineered + measured per lever (Pattern 48): types > functions, position breadth, AST clone-invariants. Predictions lie here — only a real batch is the oracle.

### Cross-architecturally-robust traps (the gold standard)

A trap is **Diamond-grade** when one test catches Castor through 2+ distinct implementations:

| Trap | Architectures observed | Submission |
|---|---|---|
| `clearRegisteredAliases` same-command global | 4: same-map / flag-tagged / separate-but-walk-parents-only / separate-but-no-current-walk | cliffy-aliases |
| Checkpoint-during-tx wiring | 4: no wiring / hardcoded false / wrong instance / never called | cliffy-undo-history |
| Null-write substitution | 5: total miss / partial / `!IsNull` guard / skip-trim / empty-to-trim | dasel-csv |
| FileLoadError wrapping | 3: stat path / glob path / default | dasel-multi-file |
| Seal padding-not-AAD | 4: version prefix / random prefix / middle padding / trailing | tengo-crypto |
| Goroutine depth reset | 5: clone-propagation / parent+1 / traceState / goroutineTrace-by-gid / sentinel-copy | yaegi |
| InFormat mutation-before-read | Single arch but 7/14 hit rate (50%) | dasel-multi-file |
| Generic-type position breadth (`*Box[int]` pointer-base / `[]*Box[int]`) | parser accepts bracket on bare ident but not after `*`/`[]` | scriggo-generics |
| AST clone drops switch-default nil sentinel | clone allocates non-nil empty slice -> false "missing return" | scriggo-generics |
| Bare generic name custom diagnostic vs `undefined` | pre-declares template in scope -> custom msg, never hits undefined path | scriggo-generics |

**Implication**: when designing a trap, mentally walk through 2-3 natural implementations. If one test catches all, it's Diamond-grade. If only one implementation is plausible, stack with another trap.

### What does NOT work

- Single-feature isolated tests — Castor passes ~100%
- Error-class CRUD — Castor implements correctly
- Registry CRUD — Castor handles
- Basic subcommand inheritance — Castor traverses parent correctly
- Documenting every excluded type explicitly — pushes pass rate to 100%
- Functions-only / single-axis compile-time transform (monomorphize one func, desugar one form) — Castor ~98%; lead with TYPES and stack >=2 levers (Pattern 48)

### Pattern 8 Bucket frequency at Diamond tier

Across all 6 subs:

| Bucket | Hit count | Top reviewer flags |
|---|---|---|
| 1 — Description quality/structure/redundancy | 12+ | "Wall of text", "inline lists", "mechanical tone", "infer from existing code" |
| 2 — Spec contradiction | 5 | "printable ASCII vs tab"; "accepts X vs must error" |
| 3 — Fairness (`was_mentioned_in_description: false`) | 10+ | CheckpointData fields, entries() return type, runtime validation |
| 4 — Test quality | 11+ | internal-package tests, weak `Contains` assertions, duplicates |
| 5 — Solution cleanliness | 8+ | dead code, scope creep, undocumented exports |

Pattern 3 fairness flags = 1-sentence fix yielding +9-17pp. Bucket 5 cleanliness = automatic reject if scope creep.

---

## Section 6.3 — Diamond-Required Artifacts (solution-approach + test-groups + failure-qa + env description)

Diamond submissions REQUIRE these artifacts beyond the 5 standard deliverables. Each has a perfect-style template derived from approved subs.

### solution-approach.md (HIGH-LEVEL summary; full rules in DIAMOND.md § solution-approach.md Structure)

**Purpose:** a HIGH-LEVEL summary a non-expert of the repo can understand, used as context for reading solution.patch. NOT an implementation walkthrough. The old "walks the algorithm step-by-step / names every invariant" framing was reject-cause on scriggo-generics (reviewer 2026-06: "too low level design ... you've got internal helper names listed").

**Style:**
- 200-500 words; 1 dense paragraph (library) to 3 short paragraphs (compiler/language). Plain prose, no headers, no bullets, ASCII, human voice, no em-dash.
- NAME only the public/observable surface: library -> public API methods + error classes; language/compiler-internal feature -> the user-visible syntax + error conditions. Stage names (parser, type checker, emitter) OK.
- NEVER name internal private helpers (scriggo reject: `checkType`, `DefinedOf`, `substituteExpr`, `IndexList`), NEVER cite file paths/line numbers, NEVER discuss test substrings.
- State the strategy in plain words + the one property separating a correct solution from a plausible-but-wrong one (scriggo: concrete real types vs catch-all `any`).
- Close: behavior is the requirement; named approach is the reference; any implementation delivering it is valid.

**Calibrate by feature type (two approved shapes):**
- Library WITH public API -> `diamond-problems/approved/cliffy-command-aliases/solution-approach.md` (1 dense para; public methods + error classes ARE the observable surface).
- Compiler/language, no public API -> `diamond-problems/scriggo-generics/solution-approach.md` (3 paras; syntax + behavior + strategy only; zero internals/paths/lines).

### test-groups.md (style: see DIAMOND.md § test-groups.md Structure)

Group tests by behavioral category. Per group: list test function names + quote relevant description requirement.

### failure-qa.md (style: see DIAMOND.md § Failure QA Guide + § Section 5)

Per failed test per failing run: unfairness check (with prompt citation) + root cause (with code reference).

### Environment Description (Shipd UI, NOT a file)

**Length:** ≥300 chars (hard, ~2026-05-21 enforcement). Target 350-500.

**Style:** 1 paragraph, plain ASCII, human voice, 3 elements (what teaches + typical task + successful vs failing trajectory).

**Template:**
```
[Repo + domain]. The task: [behavior to fix] guided by [test mechanism].
A successful trajectory makes [target] green with [scoping discipline].
A failing one looks almost right -- most tests pass -- but trips on one thing:
[specific blind spot using Section 1 trap-category vocabulary].
Teaches [generalized lesson].
```

**Reference examples in `DIAMOND.md § Environment Description`** (Emily 352-char approved + cliffy-aliases 460-char style match).

**Failing-trajectory sentence is the heart.** Name the specific Section 1 trap-category blind spot. Pattern:
- Same-object-as-inherited → "wipes own-command globals" / "current scope counts as inherited"
- Pipeline ordering → "reads X after Y already mutated it"
- Convenience-method default-leak → "convenience method calls public setup which adds defaults"
- Wrapper-bypass → "adds bytes that bypass the protective mechanism"
- Boundary detection → "propagates state across the boundary instead of resetting"

---

## Section 6.4 — Human-Voice Writing Rules (Diamond Scope Reminder)

> **Canonical source: `DESCRIPTION.md § Human-Voice + ASCII Rules`.** Rules apply to ALL tiers (Mars / Olympus / Diamond / Lite) — AI-slop detector fires universally. This section retains Diamond-specific application + tooling.

Diamond extends the universal ruleset to additional artifacts unique to this tier: `failure-qa.md`, `solution-approach.md`, `test-groups.md`, env description (Shipd UI ≥300 chars).

### The 9 cross-artifact writing rules

1. **No em dashes** (U+2014 `—`) — anywhere. Em-dash is the #1 AI tell reviewers detect. Use colons, commas, parens, or sentence breaks. The platform also hard-rejects on `non_ascii_character` for em-dashes in meta.md.

2. **No `--` as pseudo-em-dash in prose** — `--` reads as AI shorthand for em-dash. Same rejection signal. Code/CLI flag/diff contexts OK (e.g., `--output_path`); prose is not.

3. **No Unicode arrows / smart quotes / curly punctuation** — keep all text plain ASCII. `→`, `←`, `↑`, `↓`, `«»`, `""`, `''` all flagged.

4. **Human voice, not AI cadence** — avoid:
   - "Sure! / Certainly! / Of course! / I'd be happy to..."
   - "It's important to note that..."
   - "In essence / At its core / Fundamentally / Notably / Specifically"
   - Tricolon ("X, Y, and Z" stacking when only X matters)
   - Symmetrical paired clauses ("not only X but also Y")
   - "This approach..." / "This solution..." / "This implementation..."

5. **Final code state, not trajectory** — describe what code DOES, not what agent DID. "The function returns false" beats "the agent wrote a function that returns false."

6. **No fabricated identifiers** — every named variable/method/field exists in actual code. Verify via grep before citing.

7. **Concrete values over abstractions** — `Expected 'NA', got ''` beats "expected null representation, got empty." Same for chars, paths, error message substrings.

8. **No trajectory step references** — "At step 21..." / "After encountering test failures..." / "Subsequently the agent..." all AI-cadence. Describe final code only.

9. **No cross-run comparisons** — every QA entry stands alone. No "same as Castor #1", "as noted above", "see entry 3."

### Pre-submit guard commands

```bash
# Em-dash + Unicode dash check (must return empty for ALL Diamond text artifacts)
rg '[\xE2][\x80][\x90-\xAB]' meta.md failure-qa.md solution-approach.md test-groups.md feedback.md

# Smart quotes check
rg '[\xE2][\x80][\x98-\x9D]' meta.md failure-qa.md solution-approach.md test-groups.md feedback.md

# Pseudo-em-dash in prose (allow only in code blocks + CLI flags — manual review)
rg ' -- | --$' meta.md failure-qa.md solution-approach.md test-groups.md
```

Better one-shot: `file <each-file>` must say "ASCII text" (NOT "UTF-8 Unicode text"). UTF-8 detection means non-ASCII present somewhere.

### Why this elevates from failure-QA-only

Reviewer feedback now consistently flags em-dash + AI cadence in:
- meta.md (description)
- env description on Shipd UI
- test-groups.md group explanations
- solution-approach.md trap descriptions

Treating failure-QA as the only "human-voice" zone leaves multiple submission artifacts vulnerable. From this point on, **apply human-voice + ASCII rules to all Diamond text outputs**.

### What stays as-is

Internal instruction/playbook files (`Instructions/*.md`, `.agents/*.md`, this file) are working documents for the author — em dashes acceptable here. The rule applies to **submission-bound text** only.

---

## Section 6.5 — Environment Description (NEW gate, ~2026-05-21 enforcement)

Diamond submissions require **Environment Description ≥300 chars** entered directly in Shipd UI. Under-spec rejects new problem runs (from ~2026-05-21).

### Required 3 elements (per Shipd ops 2026-05-14)
1. **What env teaches model** — domain + concept + concrete trap class
2. **Typical task shape** — failing test fixed by scoped change
3. **Setup mechanics** — successful vs failing trajectory description

### Approved template (352 chars, copy + fill)

```
[Repo + domain]. [Concrete trap concept agent must master]. The task:
[behavior to fix] guided by [test mechanism]. A successful trajectory makes [target]
green with [scoping discipline]. A failing one looks almost right — [most-of-tests pass
indicator] — but trips on one thing: [specific blind spot]. Teaches [generalized lesson].
```

### Authoring discipline

- Draft at design time (after DESIGN.md, before submit)
- Paste into `feedback.md § Env Description` for source-of-truth
- Paste into Shipd UI at submit
- Verify char count ≥300 (count without markdown formatting since UI is plain text)
- For pre-existing in-flight subs: retroactive update needed before next problem run

See `DIAMOND.md § Environment Description` for full spec + approved example + enforcement timeline.

---

## Section 7 — Diamond Pipeline Cost Model

### Token costs (post-relaunch 2026-05-13)

| Operation | Cost | Notes |
|---|---|---|
| Castor run (single) | 25 tokens | Throttled temporarily |
| 10x Castor run | 250 tokens | Standard eval batch |
| Diamond Checks (full pipeline) | 50 tokens | 30min-1hr |
| Diamond Checks Rollouts | 45 tokens × 3 jobs | Per rollout |
| Diamond Checks Code Validation | 15 tokens | Sub-step |
| Diamond Checks Full Env QA | 20 tokens | Sub-step |
| Hinted run (additional) | 250 tokens (10x) + 50 (Diamond Checks again) | Twice — unhinted + hinted |

### Stale conditions (forces re-run)

Diamond Checks stales on:
- Description change
- Test patch change
- Solution patch change
- Dockerfile change
- GitHub repo / commit hash change

Hint stales **only hinted** Diamond Checks.

QA artifacts stale **only if Castor staled** — iterating QA artifacts via Final QA Review is SAFE.

### Optimal cost path (target)

| Round | Cost | Cumulative |
|---|---|---|
| R0 smoke (1x Castor) | 25 | 25 |
| R1 10x + Diamond Checks | 300 | 325 |
| R2 fix → R3 10x + Diamond Checks | 300 | 625 |
| R4 fix → R5 10x + Diamond Checks | 300 | 925 |
| Auto Review | 0 | 925 |
| QA iter (4-6 rounds) | 0 (no Castor stale) | 925 |

**Target token spend: ~900-1000 tokens per Diamond approval.** Compare actual: dasel-csv-options ran 17+ eval rounds = ~5000+ tokens.

### Reward

- $500 USD per accepted Diamond submission
- Diamond queue PRIORITY (minutes to few hours review turnaround)
- Increased token drips + cap
- Diamond programme lock-in benefits

---

## Section 8 — Bottom-Line Decision Rules

1. **Promote in-flight Olympus drafts when possible** (§ Section 8.5, ~15× cheaper than greenfield). Closed only for ALREADY-ACCEPTED Olympus problems. If no Olympus draft → greenfield (~5000 tokens + 12-17 eval rounds).
2. **Plan 6-8 eval rounds + 4-6 QA rounds + 12 total attempts.** Budget time + tokens accordingly. dasel-csv-options precedent = upper bound (26 attempts, 17 eval rounds, ~5000 tokens). Aim below this floor via disciplined design.
3. **Aim 1-2/12 hardened, NOT 3-4/12 borderline.** Reversion variance kills borderline approvals.
4. **Cross-package tests are the ONLY reliable median-msg lever.** In-package complexity doesn't lift msg count for passing agents.
5. **`was_mentioned_in_description: false` from 3+ evaluators = 1-sentence fix yielding +9-17pp.** Don't over-engineer.
6. **Failure-QA polish is iterative attrition.** Don't aim for all 12 perfect in one round.
7. **Documenting one trap typically yields +25pp.** Use sparingly — only after confirming current pass rate <10%.
8. **Adding NEW behavioral requirement is safer than removing a trap** when reducing pass rate from too-easy.
9. **Quote spec verbatim in QA fairness.** "Resolved files are assembled into a slice" beats "empty paths is valid input."
10. **Name exact code locations in QA root causes.** `fmt.Errorf("file not found: %s", path) at the os.Stat check` beats "returns plain error."
11. **Reversion costs 2-7 extra eval runs each.** Strengthen patches BEFORE first submission.
12. **Test file names use random hex suffix** to avoid `shipd`/`datacurve` precheck rejects + test-collision hazards.
13. **Castor is NOT Nova.** Different blind spots. Don't assume cross-agent learnings apply.
14. **LOC is a correlate, not a constraint.** The real Diamond ceiling is **Castor pass rate ≤30%**, not raw LOC. tengo-crypto's 925 +LOC + 4/10 pass = valid. Pass-rate validates difficulty regardless of LOC size. **Bigger LOC is GOOD when** it adds genuine surface (multi-API, cross-package, multi-layer) + cross-architectural traps. **Bigger LOC is BAD only when** scaffold pattern-followable or scope creep makes it trimable without losing requirements. See Section 3 § "LOC ceiling is a myth."
15. **No Diamond word-count floor.** Follow `DESCRIPTION.md § Word Count` shape-based targets (Mars C ~91 / A2 ~137 / B ~241 / Olympus ≤200). Tighten-First Rule favors shorter — smaller inference surface = harder problem. 220-word Diamond is valid if every sentence ties to a test assertion + 5+ pre-empt sentences fit. The 453 + 577 words observed in 2 approved reflected API-enumeration density, not a Diamond minimum. Hard cap 500 still applies.
16. **GATE ON COUNTER 2 (`human-effective`) ≥ 450 — the reviewer's meaningful count is the BINDING floor (400 = the looser platform auto-block).** Counter 2 strips blanks, comments, no-ops, generated files, TEST files, package/imports (+ closing `)`/`}`), braces/punctuation-only lines, and boilerplate. Sub-floor = guaranteed reject = wasted Castor + Diamond Checks tokens (250+ per round). Verify pre-submit (PRIMARY = the hook):
    ```bash
    python .claude/hooks/effective_loc_check.py solution.patch   # PRIMARY: `human-effective` line, target >= 450
    # SECONDARY (Counter 1 auto-block, braces + imports kept) — confirm-only, clears once Counter 2 >= 450:
    f=solution.patch; raw=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|wc -l); blank=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*$'); comment=$(grep -E '^\+' "$f"|grep -vE '^\+\+\+'|grep -cE '^\+\s*(///|//|/\*|\*)'); echo $((raw-blank-comment))
    ```
    If Counter 2 < 450 → expand scope BEFORE submitting with real implementing logic (helpers, public API surface, cross-package integration); under 400 Counter 1 is an outright auto-block. Do NOT pad with dead code, comments, braces, or imports — they count ZERO for Counter 2. `raw × 0.65` is a rough sketch-time estimate ONLY.
17. **Hint authoring = top-down pruning, NOT trial-and-error.** Read 3-4 failing runs, find failure point + cascading downstream traps, draft MAXIMUM hint (over-spec ceiling reference), map sentences to meta.md, prune one-by-one with 1-Castor probes between each removal, run final 10x once. Saves ~50% of hinted-batch tokens vs ping-pong cycle (add → 10x → strip → 10x → re-add = 750 wasted before converging). See § Section 4 "Hint authoring discipline" + DIAMOND.md § Hint Authoring Discipline.

---

## Section 8.5 — The Diamond Promotion Pattern (CONDITIONAL — In-Flight Olympus Only)

> **Eligibility (clarified 2026-05-14):**
> - Olympus **ACCEPTED** → CLOSED (cannot promote)
> - Olympus **IN-FLIGHT / not yet accepted** → OPEN (can promote, this section applies)

> **NEW outcome data (2026-05-14): TIER-DOWNGRADE IS A SOFT LANDING.** `yaegi-execution-tracer` submitted at Diamond with Castor 2/20 (10%) — reviewer **accepted at Olympus tier** instead of rejecting. Submission NOT lost. Confirms: Diamond eval at <10% Castor pass = Olympus-tier acceptance, not rejection. Promotion guarantees Olympus-or-better, not Diamond.

**3 of 4 in-flight Diamond submissions were Olympus → Diamond promotions** — cheapest path when prior Olympus draft exists. 1 of 3 landed at Olympus tier (yaegi-execution-tracer). Promotion path still worth it given soft-landing safety net.

### The 3 promotion case studies

| Sub | Prior Olympus state | Promotion changes |
|---|---|---|
| **cliffy-undo-history** | APPROVED 7/7 ("lgtm. Great work!") 2026-04-04, 8 attempts at Olympus | meta 433→450 words, test.patch 1229→1266 (+37 lines = 2-3 new tests), solution.patch UNCHANGED (784 LOC) |
| **yaegi-execution-tracer** | Prior Olympus, reviewer-trained, AI Reviewer PASS (previous) | meta + test.patch **byte-identical** to Olympus version. Promoted via Failure-QA artifacts only. |
| **tengo-crypto** | APPROVED Olympus 4 attempts, Nova 1/10 PASS | meta hardened (descriptions tightened), test.patch expanded with seal/open + crypto-hasher cross-cutting traps |

### Why promotion beats greenfield

- **Calibration done**: pass-rate band proven at Olympus 10-20%
- **AI Reviewer baseline established**: 21/21 already cleared
- **Spec battle-tested**: 3-9 iteration rounds of description tightening already absorbed
- **Solution battle-tested**: helpers + fixpoint loops + edge cases proven correct
- **Trap design proven**: cross-architectural traps confirmed by 10+ Olympus agent runs

### Cost comparison

| Path | Eval rounds to approval | Tokens | Time |
|---|---|---|---|
| Greenfield Diamond (`dasel-csv-options` precedent) | 17 eval rounds, 26 attempts | ~5000 tokens | ~half-cycle |
| Promotion (`cliffy-command-aliases` precedent) | 1 Castor + 6 QA rounds | ~325 tokens | ~1 week |

**Promotion is ~15× cheaper than greenfield.**

### The Promotion Recipe (5 steps)

1. **Pick an APPROVED Olympus problem at 10-20% pass rate.** Below 10% = redesign needed at Olympus first. Above 20% = need difficulty additions before Diamond.

2. **Add 2-3 cross-feature interaction tests** targeting Section 1 trap categories (★ cross-architectural):
   - Same-object-as-inherited (current scope counts as "inherited")
   - Pipeline ordering / pre-mutation read
   - Convenience-method default-leak
   - Wrapper-bypass / authentication coverage

3. **Strengthen 1-2 assertions** to catch previously-passing-but-buggy implementations (dasel-csv-options Iter 19 precedent: 3/12 → 1/12).

4. **Add Failure-QA artifacts** (test-groups.md + solution-approach.md + failure-qa.md):
   - test-groups.md: group tests by trap category + cite description verbatim
   - solution-approach.md: name traps + cite kill-rate estimates
   - failure-qa.md: ready for per-run analysis post-Castor 10x

5. **Smoke test (1x Castor or Vega) → Castor 10x + Diamond Checks → QA iteration.**

### Promotion-Specific Pitfalls

- **Don't change solution.patch unless necessary.** cliffy-undo-history kept solution byte-identical. yaegi-execution-tracer kept test.patch byte-identical. Less surface = less stale-risk.
- **Adding NEW behavioral requirements lowers pass rate sharply** (dasel-csv-options Iter 17: 58%→25%). Use ONLY if Olympus pass rate was 20%+ at promotion time.
- **Strengthening assertions can drop 3/12 → 1/12.** Plan for this in iteration budget.
- **Failure-QA rounds remain 4-6 even on promotions** (cliffy-command-aliases: 1 eval round + 6 QA rounds).

### When NOT to promote (apply to in-flight Olympus drafts)

- Olympus problem had <10% pass rate (too hard for Castor too)
- Olympus problem was 0/12 with hint (Diamond removed hints April 2026)
- Maintainer-philosophy uncovered between Olympus draft + Diamond submission (`dasel-multi-file` precedent — see § Section 9)
- Solution touches deprecated/unstable repo paths
- **Olympus already accepted** (path closed for shipped Olympus problems)

### Authoring decision tree (2026-05-14 — clarified)

```
Do you have a target Olympus problem?
├── ACCEPTED already                             → CLOSED (cannot promote). Pick different feature → greenfield (~5000 tokens)
├── IN-FLIGHT, not yet accepted                  → PROMOTION OPEN
│   ├── Olympus drafting / pre-eval              → harden for Diamond, submit at Diamond tier directly (cheapest)
│   ├── Olympus 10-20% pass rate in eval         → PROMOTE (Section 8.5 recipe)
│   ├── Olympus >20% pass rate                   → tighten first, then promote
│   └── Olympus <10% pass rate                   → fix Olympus first or redesign (too hard for Castor)
└── No Olympus draft                             → greenfield (~5000 tokens, 17 eval rounds)
```

**When promotion is available, use it.** When closed (Olympus already accepted), discipline matters more:
- Section 1 trap categories (bake 3+ ★ cross-architectural into design)
- Section 2 quality bar (admits 2+ implementations, boundary-operating, specific-value asserts)
- Section 3 scope bands (word count: DESCRIPTION.md shape-based, hard cap 500; LOC: ≥400 floor, no upper ceiling; tests: 50+ floor; API: traceable to tests + meta; packages: 1-2 deep)
- Section 5 failure-QA discipline (12 rules, 4-6 round attrition expected)
- Section 9 maintainer-philosophy gate (run Pattern 22 at THREE points)

Sloppy greenfield = ~5000 tokens + ~half-cycle wasted. Disciplined greenfield = compress toward `dasel-csv-options` levels.

---

## Section 9 — Pre-Submit Maintainer-Philosophy Gate (CRITICAL — Diamond-Specific Reject Lesson)

**dasel-multi-file** (Diamond, 2026-05-14) was AI Reviewer PASS 0.92 + Failure QA 12/12 GREEN + Castor 7× successful → **REJECTED at olympus-review Stage 0** for maintainer-philosophy violation. Cost: 14 authoring rounds + 7× Castor (250+ tokens) + Diamond Checks + full QA cycle.

### What was missed

- [#357 "Support multiple files"](https://github.com/TomWright/dasel/issues/357) — CLOSED by TomWright 2025-12-10 (4 months pre-base). Maintainer comment lists THREE V3 alternatives (env vars, `readFile` function, file→variable in CLI), explicitly declines multi-file primitive.
- [#24 "Multiple file flags"](https://github.com/TomWright/dasel/issues/24) — CLOSED 2020 "mostly resolved by multi-selectors". Same feature class **twice rejected** by same maintainer.
- Phase 2 (namespace + maintainer philosophy check from `CLAUDE.md § CRITICAL RULE`) never ran at design OR submit-pre-check.

### Why Auto Review + Diamond QA missed it

**Both are blind to repo politics.** Auto Review checks technical correctness; Diamond QA checks failure analysis quality. Neither queries GitHub for maintainer-rejected feature classes.

### The Diamond-Specific Pre-Submit Gate

**Before submitting ANY Diamond:**

```bash
# Search closed issues by feature CLASS (not just API name)
gh issue list -R OWNER/REPO --state closed --search "<feature-class-keywords>"

# Read top 3-5 closure comments for maintainer language:
gh issue view <num> -R OWNER/REPO --comments
# Look for: "use X instead", "by design", "prefer not to", "out of scope",
# "won't add", "rejected", "doesn't fit", "alternative approach"
```

**Apply to feature CLASS keywords, not just exact API name.** dasel-multi-file searched "multi-file" → 0 hits. Should have searched "multiple files", "multi-document", "file flag", etc. — would have hit #24 and #357 immediately.

### Diamond-specific addition to Pattern 22

Every Diamond submission must pass these 6 checks AT THREE POINTS:
1. **At design phase** (before DESIGN.md)
2. **At first Castor eval** (after smoke test, before 10x batch)
3. **At submit-pre-check** (after Auto Review + Failure QA)

**Auto Review PASS + Failure QA 12/12 GREEN do NOT substitute for Phase 2.** Run the 6-check protocol yourself before submitting.

### Cost of skipping

| Phase | Tokens lost | Time lost |
|---|---|---|
| dasel-multi-file: 14 rounds + 7× Castor + Diamond Checks 2× + Failure QA cycle | ~700 tokens | ~half-week of work |

### Added to track record

This is **incident #4** in `CLAUDE.md § CRITICAL RULE`. Track record now lists 4 maintainer-philosophy/post-base-activity misses. **Confirms: Auto Review + Diamond QA do NOT check maintainer philosophy.**

---

## Cross-Refs

| Topic | File |
|---|---|
| Full Diamond pipeline + staleness rules | `DIAMOND.md` |
| Per-submission iteration deep dives | `PROBLEM-PROFILES.md` (look up cliffy-command-aliases, dasel-csv-options sections) |
| Castor behavioral profile + blind spots | `KNOWLEDGE.md § Castor` |
| Trap-stacking ceiling pattern | `PATTERNS-ADVANCED.md § Pattern 17` |
| Triviality filter (pattern-followable rejection) | `PATTERNS-ADVANCED.md § Pattern 23` |
| Failure-QA writing rules (full 12 + 6-round pattern) | `lessons-learned.md § Diamond-Tier Lessons` |
| Diamond agent prompt (Query 7) | `PROMPTS.md § Query 7` |
| Shape taxonomy (Olympus shapes — Diamond builds on these) | `SHAPES.md § Pattern 12` |
| Post-eval workflow Tier 4 (Diamond approval updates) | `.agents/rules/olympus-post-eval-workflow.md` |

## cel-go-strict-dyn (APPROVED 2026-06-17) - design + iteration discipline

- INTEGRATION-TIMING is a valid Diamond engine for a SINGLE-subsystem feature. Killer wall = provenance recorded DURING the check walk vs an unresolved type parameter promoted to dyn only at the FINAL substitution (after the consuming site is visited and the enclosing overload binds T). 0/10 unhinted FAIR, group rate ~0.16. Home opus proxies solved 3/3 from meta and a source-reading deep-dive counted ~3.5 algorithm walls - both blind to the timing wall. Platform Diamond Checks = the only oracle; never greenlight/kill on home analysis.
- LOC-RESCUE (cleared 367 eff < 400 floor with NO solvability shift): add an ADDITIVE, fully-tested READ-ONLY aggregation/reporting API over the structured output solvers already produce (StrictDynReport over the violations) -> +96 eff, zero checker change, pass rate held. Platform eff = raw - blank - //comment, braces KEPT; _patch_gen.py prints the inverse so compute it yourself.
- FAIRNESS/SOLVABILITY > description-conciseness. Stripping public-API method signatures for conciseness made CountBySource ambiguous ((string)int vs ()map[string]int) and compile-cliffed the single-file suite in 2/3 rollouts. PIN public-API field TYPES + method SIGNATURES in meta. An under-specified surface competent agents split on is a HIDDEN REQUIREMENT = top reject.
- HINT: a compressed root-cause-converter sentence can be ALL-OR-NOTHING (every solver one-cluster-from-passing). Tune pass RATE via a DIFFERENT fair gate left un-hinted (map-key join), never by rewording the all-or-nothing sentence. Hint wording can SEED the failure it warns about. Behavioral-checklist hint overshoots (6/6).
- FAILURE-QA: the validator disputes ONLY root-cause MECHANISM sentences (fairness/spec-quote/helper/junit pass first try). When a run DOES the right thing yet still fails (subtle interaction, suppressor NOT in the diff), STOP guessing - state the verified guard + junit observable + "the diff does not localize it to a single construct." Human-QA is a SEPARATE later gate (framing/precision, QA-only no-staleness): verbatim Site strings (gold's member-target Site is "method target" not "target"), rejection-SITE precision (size([i,s]) rejects at the list-literal CONSTRUCTION not the consuming size() arg), derivations as author's-reading-not-test-verified, drop unevidenced motivation.

## yaegi-methodset-enforcement (APPROVED Diamond 2026-06-23) - design + iteration discipline

Bands (confirmed approved): 493 eff / 4 files (1 new), 36 fail-to-pass tests / 6 groups, hinted 2/10 (~20% Hard) + Holistic PASS, NO build tag.

- **DEDUP MOAT = ZERO new public API.** All 14 prior yaegi siblings are additive-API features; this one makes already-illegal Go FAIL through the EXISTING Eval/EvalPath error channel and repairs two silent corruptions. A spec-conformance-enforcement pick (tighten an interpreter's static checks to language-spec fidelity) is structurally distinct from "add function/mode X" and clears similarity checks against an additive-API sibling cluster. Pre-pick lever when a repo's approved siblings are all additive.
- **NARROW site-wiring beat the central-intercept.** Wired the new `satisfies` check at the specific sites (assignment/comparison/conversion/return) rather than intercepting `assignableTo`; the intercept path runs inside `check.conversion`->`convertibleTo`->`assignableTo` and emits a generic "cannot convert" BEFORE the reasoned site, losing the does-not-implement message + breaking dynamic/generic consumers. Lesson: for a cross-cutting check, wire at the leaf decision sites, not the shared predicate everyone calls.
- **Cross-subsystem span (Diamond-required):** cfg.go + typecheck.go + type.go + new methodset.go, three independent engines (receiver-aware satisfaction / BFS shallowest selector / addressability classifier) that share state so a local fix to one regresses another (interdependent).
- **2 grader-mechanics gates** (see DIAMOND.md entry): additive-only test patch (grader applies patch over the agent's mutated tree) + no build tag (grader runs plain `go test`).
- **Iteration cost:** the to-PASS arc was dominated by those 2 mechanics gates + hint calibration, NOT difficulty tuning — the difficulty landed first-try once the env was correct. Check env-mechanics (patch applies cleanly over a mutated tree, base/new isolation works without custom flags) BEFORE spending Castor batches.

## typify-object-applicators (APPROVED Diamond 2026-06-25) - design + iteration bands

- OLYMPUS->DIAMOND RETIER via Diamond Checks: a coherent single-repo codegen feature authored as Olympus cleared the Diamond difficulty band. Unhinted 10x Castor = 0/10 FAIL_MISSED_REQUIREMENT, Holistic NEEDS_HINTS; hinted = 1/11 pass. That 0/10-unhinted -> small-hint -> nonzero is the canonical Diamond difficulty signature.
- SCOPE-HINT DESIGN: target the universal blind spot (representation split: object schemas generate as struct OR map/newtype incl root pattern-only/propertyNames-only) at SCOPE level only - name no helper/file/algorithm step (admin-valid). It flips the 20/22 near-miss runs (which already solved cardinality + differing) to a pass while leaving the genuinely-hard trap (differing-pattern value union + the unnamed-root naming fix) UNHINTED, which caps the hinted ceiling under 5.
- DESIGN RISK (codegen): asserting on generated SHAPE over-couples to the reference; gate with a 2-agent local solvability sim before platform. BUILD-MEASURE the eff LOC (233 for 3 behaviors -> 7 behaviors = 462); never project.
