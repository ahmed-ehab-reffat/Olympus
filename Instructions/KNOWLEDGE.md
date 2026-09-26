# Olympus Knowledge — Agent Behavioral Profiles & Cross-Cutting Patterns

High-signal agent intelligence and cross-cutting design knowledge. Per-problem deep dives live in `PROBLEM-PROFILES.md`. Workflow / rules / shapes live in dedicated files (see § Cross-Refs at bottom).

---

## What This File Is For

Agent-specific blind spots, cross-cutting trap patterns, message-count mechanics, and Diamond-tier behavioral data. Read this when:
- Designing tests targeting a specific agent
- Tuning difficulty (which trap to embed)
- Deciding tier (which agent will run)
- Troubleshooting failed eval (matching failure mode to agent)

For everything else, see § Cross-Refs.

---

## Agent Behavioral Profiles

Cross-problem patterns observed from 80+ eval runs. Use these to design tests exploiting known weaknesses.

### Castor (Diamond only — primary target)

**Strengths (hard to trip):**
- Individual feature implementation — passes ~100% of single-feature tests
- API surface implementation — registries, formatters, error classes when clearly specified
- File organization — follows repo conventions
- Base test preservation — never breaks existing tests

**Blind Spots (reliably trips on):**
- **Specific examples override general rules** — "only X triggers behavior; Y and Z do not" → agents implement only Y/Z guard, miss X constraint. (e.g., 14/14 agents guarded null/undefined, missed `typeof !== 'object'`)
- **Type inference from context** — when interface param types unspecified, infers overly restrictive (`Array<Record<string,unknown>>` instead of `unknown`) → TS compile errors on edge cases
- **"initializing" = "call default constructor" trap** — "method X initializes the full system" → 6/10 Castor agents call default setup (with built-ins) instead of minimal scaffolding. **Fix:** replace "initializes the full X system" with "sets up Y without adding any built-in Z, or adds to existing if already configured."
- **Cross-feature interaction ordering** — implements features independently, misses ordering dependencies (primitive gate must fire BEFORE column validation, not after)
- **State isolation in cloned objects** — shares references instead of deep-copying in `clone()`
- **No-op ternary / copy-paste in branching** — 1/10 wrote `Array.isArray(data) ? sorted : sorted` (identical branches)
- **Name-match vs symbol-resolution for shadowable builtins** — "only the built-in X is terminating/special" → agents match the identifier text (`fn.ident == bltnPanic`) and skip the resolved-symbol check (`sym.kind == bltnSym`), so a locally shadowed `panic := func(...)` is misread as the built-in. 6/10 Castor (yaegi-unreachable-code, APPROVED 2026-06-03). Fair when the test shadows the builtin and the description says "only a call to the built-in panic" — still a reliable trap.
- **Language-spec exception inside a general rule** — when a spec enumerates a set with a carve-out ("X, Y, Z are terminating; a clause ending in fallthrough is NOT"), agents implement the general set and miss/invert the carve-out. 4/10 treated a fallthrough-ended switch clause as terminating (`return true` on `fallthroughtStmt`, or `continue` skipping its termination check). (yaegi-unreachable-code)
- **Surface-form gate vs semantic value — the folded-builtin blind spot** — when a value reaches a checkpoint in a DIFFERENT runtime form than the obvious one, agents gate on the obvious form and silently skip the rest. 10/10 Castor on yaegi-const-representability (Diamond APPROVED 2026-06-06): the `complex` builtin folds to a reflected `complex128` stored in `n.rval`, NOT a `go/constant.Value`, so a check written only against `n.rval.Interface().(constant.Value)` never sees an overflowing complex. Same problem family any time a constant/value is produced by a builtin/fold rather than left as the canonical AST/constant form. **Fair when** the description states the rule and the codebase shows the fold; reliably 0/N until hinted. **Confirmed CROSS-TIER + cross-agent (Mars Nova/Orion), yaegi statement-legality APPROVED 2026-06-18:** a duplicate-expression-switch-case check keyed on `n.rval.Interface().(constant.Value)` silently SKIPS bool (`true` stores a raw `bool`, not a `constant.Value`), so `switch true{case true:case true:}` runs — 5/11 agents missed it (the single hardest test, group rate 0.455) while every other constant type (int/string/negative/comma-list) passed. A "reject same constant value" requirement where ONE constant category has a divergent runtime representation is a reliable single-subsystem FAIR Mars trap (the robust solution keys on `fmt.Sprintf("%T:%#v", rval.Interface())` which also folds `1+1`==`2`).
- **Cross-subsystem plumbing — non-collapsing pipeline stage + new-node threading** — adding a new expression node that must be threaded through EVERY plan destructure-rebuild site (drop one = silent loss on that path) AND placing a NEW non-collapsing executor stage (the obvious reuse routes it through the collapsing aggregate/GROUP-BY path = rows lost) traps Castor ~80% (2/10 on gluesql window functions, APPROVED OLYMPUS 2026-06-07). **BUT this is the key divergence: the SAME artifact scored opus-4-8 3/3 = 100%** — integration plumbing is mechanical for the frontier once spec'd, so it is a CASTOR blind spot but NOT an opus one. **Tier implication: a plumbing-wall is an OLYMPUS difficulty engine, never Diamond** (Diamond needs deep-algebra walls that bite opus). See lessons-learned "Diamond difficulty bar moved to opus-4-8". Run the opus-smoke before assuming a plumbing-heavy pick is Diamond.
- **Width vs value-range (the permissive-builtin tighten trap)** — yaegi's pre-existing integer check ends `return constant.BitLen(x) <= bitlen[t.Kind()]` (bit-width), so 200 passes for int8 (eight bits) though it exceeds 127. Agents reuse the loose built-in instead of comparing against exact signed/unsigned bounds. 10/10 on yaegi-const-representability; same surfaces in a cross-feature undercount (the in-width-out-of-range composite element is the missed diagnostic). General lever for any interpreter/type-system pick: **a permissive built-in the spec forces the solver to tighten** (3rd confirmation after yaegi-generic `assignableTo` + yaegi-const `representableConst`).
- **Empty-output convention under-specifies** — `ConstantReport(mode)` returns `""` for EVERY mode when there are no diagnostics; agents return `"[]"` / a header. 10/10. An empty-collection output convention is a reliable fair wall but must be SPEC'd or HINTED (it is a convention, not inferable from the type).
- **Zero-major caret/tilde semver semantics — the special-case-rule blind spot (Mars, find-my-way semver-range APPROVED 2026-06-16)** — `^0.x`/`^1.x`/`^1` caret-with-wildcard + the zero-major caret rule (`^0.2.3` allows patch only, `^0.0.3` allows nothing past that patch) broke 5+ of the agent runs while one passed legitimately (solvable-but-hard Mars band). Agents implement the mainline caret/tilde expansion but miss the zero-major special cases and the partial-version widening. General lever: a well-known spec (semver) with NON-uniform special cases (zero-major exceptions) where the obvious uniform rule is WRONG for a minority of inputs — fair when the description enumerates the special cases, and it reliably trips agents who code the common case. Pairs with "permissive-builtin tighten" as a same-family wall (spec forces handling the exception the obvious impl skips).
- **Import-time-bound shared CLI defaults + return-vs-sys.exit (the reusable-main conjunction)** — a `main()` built on a SHARED argparser whose `--out default=sys.stdout` and `--start default=[]` are bound at module IMPORT traps in-process reuse two ways at once: output goes to the import-time stdout (misses a test's later `sys.stdout` swap) AND `main()` returning `1 if count else 0` instead of `sys.exit(...)` records exit code 0. Both must be fixed to pass; repo siblings (standalone.py/serialize.py) push the WRONG way. The killer wall on lark-counterexamples (APPROVED Diamond 2026-06-16): the whole CupEx algorithm was Castor-solvable ~85/89, but this CLI conjunction kept unhinted at 0/10 (FAIR per 10 Orion). Pattern: when a fair 0/N rests on ONE conjunction-of-bugs-from-one-root-cause, the hint names the ROOT CAUSE only ("repeated in-process calls must behave independently") and lets agents re-derive both consequences (spreads ~3-6/10); naming both fixes hits the ~8/10 ceiling. **Tier caution:** if disclosing the conjunction is the ONLY wall, the difficulty is a MIRAGE — disclosure collapses it to too-easy; needs a second fair algorithmic wall (here `leaves()`-returns-node 2/10 capped the hinted ceiling).
- **Render-only marker stored as a structural child** — a conflict-dot (`_Dot`) inserted into `children` with `children=None`/no `is_leaf()` crashes any structural traversal (`stack.extend(node.children)` -> `TypeError: NoneType not iterable`, or `AttributeError: '_Dot' object has no attribute 'is_leaf'`). Sibling traps in the same family: `leaves()` returning `[self]` (the node) instead of `[self.symbol]` -> `'Derivation' has no attribute 'name'`; missing `__str__` so `str(tree)` is the repr not the outline; nonunifying fallback returning `None` -> mass `'NoneType' has no attribute ...`; not unwrapping a synthetic `$root_` wrapper before rendering. All confirmed Castor traps on lark-counterexamples. Classify by the exact attribute-owner in the message: `'NoneType' has no attribute 'name'` (None left in tree) != `'Derivation' has no attribute 'name'` (wrong-return-type) = DIFFERENT bugs/clusters.
- **Provenance-vs-substitution-order — the standing Diamond killer** (cel-go-strict-dyn, APPROVED Diamond 2026-06-17, type-checker, single-subsystem). A value reaches `dyn` implicitly via an unresolved type parameter that the checker promotes to `dyn` ONLY at the final substitution pass — AFTER the walk visits the consuming site, and after the enclosing call's overload binds the parameter. Agents detect the promotion standalone (`first([])`) but a deferred/post-walk classifier reads the now-concrete type at the consuming position and records nothing. Group rate ~0.16, the lowest, across the whole batch. The correct shape records provenance DURING the walk keyed by node id, before overload resolution binds T; a post-substitution pass cannot recover it. This is a REAL-codebase integration-timing wall, invisible to home opus proxies (3/3 solved from meta) and to source-reading deep-dives (counted ~3.5 algorithm walls) — platform 0/10 unhinted was the only true signal. Four sibling Castor blind spots in the same Diamond, all FAIR: (a) **enforcement-not-wired** — agents collect structured violations through the accessor but never push them into the checker error stream, so `Compile` succeeds (~2/10 fully accessor-only; the new-mode-must-REJECT-and-report split); (b) **aggregate-join routes only values / gates on a part-already-dyn** — map-key and list-element heterogeneous joins of variable-typed parts missed because the join check runs over map VALUES not keys, or only fires when a contributing part already carries a dyn origin (dominant fair gate, ~33% miss); (c) **dyn()-escape launder** — an explicit `dyn()` element inside a list range is not propagated to the comprehension iteration variable, over-rejecting `[dyn(d), 1, 2].all(...)`; the exemption is keyed on the range being a DIRECT `dyn()` call or `isLiteral` returns false for the `dyn()` node; (d) **zero-arg option signature** — `StrictDynChecking(bool)` vs spec `StrictDynChecking()` compile-cliffs the whole single-file suite (1/10). Tier note: a single-subsystem feature CAN hit platform-Diamond when the wall is integration-TIMING (provenance vs substitution order) rather than algorithm depth — the inverse of the gluesql plumbing-wall which ceilings at Olympus because plumbing is mechanical for opus.

**Implementation Patterns:**
- Defaults to first/common choice when unspecified (`--format` defaults to 'table')
- `Object.keys().sort()` as JSON.stringify replacer — fails for arrays (returns indices not keys)
- Hardcodes common delimiters in quoting (always checks for comma even when custom delimiter specified)
- Outputs "null"/"undefined" as literal strings instead of empty string
- Convenience method (`withOutputFormat`) calls existing public setup (`outputFormat()`) instead of minimal custom — #1 confirmed trap

**Confirmed Difficulty Levers:**
- **#1: convenience-reuses-default trap** — withOutputFormat caught 6/10 (60%). Pattern: A calls B internally, B has defaults A should NOT include. Test A's result has ONLY what A explicitly added.
- 3+ features interacting (format + columns + sort + output file)
- Ordering tests where gate A must execute before gate B
- Clone bidirectional state isolation
- NO-OP on certain data shapes (sort on single object, validation on primitives)

**What Does NOT Work:**
- Individual feature tests (Castor passes ~100%)
- Straightforward error handling
- Registry CRUD
- Subcommand inheritance (basic)

**★ cliffy-command-aliases (Diamond, APPROVED, 10 Castor + 1 Vega):**
- Pass rate 3/10 Castor (30%) + 0/1 Vega — within Diamond target (1-5 of 10). 7 failing scored 48-50/51.
- **#1 trap: clearRegisteredAliases same-command globals — 8/8 failing (100%).** Three architectural variants all fail:
  - **Variant A (4 runs):** single `Map<name, {expansion, global}>` + `.clear()` wipes globals
  - **Variant B (1 run):** separate `_aliases` + `_globalAliases` maps, but `clearRegisteredAliases()` clears both
  - **Variant C (3 runs):** clears only locals (correct), but `getAliasRegistry()` collects globals only from parents via `_getInheritedGlobalAliases()`, omitting current-command globals
- **Why it works:** agents test parent-child inheritance, not same-command local+global. Bug manifests through 3 architecturally different paths.
- **#2 trap: onAliasExpand cancel push-before-check** — 2/10 (#7, #9). `chain.push(name)` before cancellation check → cancelled names appear in chain.
- **Confirmed Castor strengths:** 50+/51 pass. Cycle detection, conflict detection, conditional `when`, help generation, nested resolution, defensive copies, noGlobals propagation all correct.
- **Vega behavior:** fell into Variant A — cross-agent LLM blind spot, not Castor-specific.
- **Baseline:** 11/11 runs pass all 469 existing tests.

**★ yaegi-checkpoint-api (Diamond-designed, submitted Olympus, ACCEPTED 2026-05-26, 14 Castor runs, 1 PASS_LEGITIMATE + 9 FAIL_MISSED + 3 unaccounted = 7% true positive):**
- Holistic AI Review PASS, pass-rate 7% (1/14), Castor 30% (3/10) within Diamond floor
- Auto Review FAIL on V2-carryover items (test.sh validation + base regex) + `%v` prescriptive — sidestepped via Olympus tier downgrade
- **#1 trap: Binary package short-name lookup — 5/13 fails.** `Inspect("os.Args")` / `Inspect("filepath.Separator")` unresolved. Agents key `binPkg` by import path only, never reverse-map via `interp.pkgNames`. Spec said "package short name first" but reverse-lookup not obvious. Reference solution maintains `lookupSrcPkg` + `shortPkgName` helpers explicitly.
- **#2 trap: Pointer-receiver methods through value paths — 5/13 fails.** Spec says reachable, but agents skip `v.Addr().MethodByName` fallback. One missed fallback fails 4 tests (SymbolCategory + Inject method-reject + CLI -cat method).
- **#3 trap: ErrPathUnresolved wrapping discipline across Track/Untrack/History — 6/13 fails.** Agents validate paths in Inject but skip the tracker APIs. Single spec sentence ("ErrPathUnresolved wraps every unresolved-path error") covers all path APIs but agents enforce only on the obvious ones.
- **#4 trap: Snapshot storage sharing — 2/13 fails but each fans to ~15 test failures.** Agents store live `reflect.Value` references in snapshot instead of deep-cloning → Restore is no-op + Diff returns zero changes. Central, explicit; entire feature broken without deep-clone.
- **#5 trap: Resolves malformed-path acceptance — 5/13 fails.** `Resolves(".")` / `Resolves(".X")` / `Resolves("..invalid")` return true. Agents short-circuit on dot-segment splits before validating segments are non-empty.
- **#6 trap: SymbolType on source func — 1/13 fail.** `funcSym` lookup returns invalid `reflect.Value` because `s.rval` unset; SymbolType errors instead of returning func type.
- **#7 trap: Trivial build failure (compile error) — 1/13.** Unused variable. Hint candidate per Holistic Review: "run `go build && go test` before declaring done."
- O-Composite-add shape, 11+ public APIs bundled, ~870 LOC solution, 128 verifier tests. Median Castor PASS: 5 files, 127 msgs, 1310 LOC.
- **Cross-cutting lesson:** broad surface + path-resolution + reflect-traversal + checkpoint semantics. Reviewer fairness churn forced 7 meta revisions to spec the implicit contracts (bare paths, canonical reporting, deep-clone-on-read, observer order, Restore side-effect suppression).

**★ dasel-multi-file (Diamond, 12 Castor, 2 PASS = 8.3%):**
- Failing scored 113-117/118. All legitimate coding mistakes, not ambiguity.
- **#1 trap: InFormat mutation in CLI layer — 6/12 (50%).** Existing `run.go` has `o.InFormat = o.OutFormat` crossover for stdin. Agents add multi-file loading code AFTER the mutation → all files load with output format instead of auto-detect. Fix: capture `originalInFormat := o.InFormat` BEFORE crossover. Universal LLM blind spot for Go variable-mutation ordering.
- **#2 trap: FileLoadError consistency — 4/12 (33%).** Type defined correctly, used in main path. Path-resolution/stat path returns raw `fmt.Errorf` instead of wrapping. `errors.As(&fileLoadErr)` fails. Same as yaegi "fmt.Errorf no-op" — agents create wrapper but don't apply to ALL paths.
- **#3 trap: Package placement — 2/12 (17%).** Selector functions in root package or root-level `init()` instead of `execution/func_*.go`. Wipes 20-36 tests.
- **#4 trap: Empty paths short-circuit — 3/12 (25%).** `QueryFiles([])` returns empty before selector runs.
- Multi-layer architecture drives high msg counts: median 128 (vs 73-116 single-package). Failing avg 187 (up to 328).
- **Bash sandbox death at 25%** — 3/12 lost test capability mid-session (228-328 msgs).

**★ yaegi-generic-constraint-fidelity (Diamond, APPROVED 2026-05-31 — final batch 3/10 = 30%, top of band; earlier batch 2/10 = 20%):**
- O-Algorithm-correctness shape, 67 F2P tests (interp/ + cmd/yaegi/), 387 baseline preserved across all 10 runs. Median: 4 files / 198 msgs / 626 LOC.
- **#1 trap: Loose `assignableTo` for typed-pin — 6/10 (60%).** yaegi's pre-existing `interp/type.go:1490-1493` accepts any untyped-numeric vs typed-numeric pair with comment "Assignability depends on constant numeric value (overflow check), to be tested elsewhere." Agents who add per-slot reconcile but reuse `assignableTo` as the representability predicate let `MinX(int64(3), 3.14)` through → falls to constant-folder which emits `157/50 truncated to int64` instead of structured `ErrMismatchedTypes`. Three architectural variants all fail: `untypedAssignableTo` falling through to `assignableTo` (Castor #4, #9), `isNumber/isNumber` shortcut (Castor #6), `isNumberCat/isNumberCat` shortcut (Castor #7). Fix: write per-kind `representableConst`-style predicate; do NOT delegate to `assignableTo`.
- **#2 trap: Untyped-default promotion absent on constraint membership path — 3/10 (30%).** Agents add `defaultIfUntyped`/`untypedDefault` helpers + `ConstraintError` plumbing + `OnConstraintFailure` callback wiring correctly, but `checkConstraint` still does `it.equals(c) || it.matchDefault(c)` against the untyped itype — fails because `matchDefault` is `t.untyped && t.id() == "untyped "+o.id()` (yaegi `interp/type.go:1550-1551`), and `untypedFloat.id()` returns `"untyped float"` (not `"untyped float64"`). Helper exists but never gets called on the membership path. Castor #1, #10 hit hardest.
- **#3 trap: Rune-only defaulting miss — 1/10 (10%).** Float→float64 and complex→complex128 paths work; rune→int32 silently fails because untyped-rune's `name="int32"` but `str="untyped rune"` (`interp/type.go:153`) and `defaultType(noValue, sc)` falls through to `*typ = *t` (no concrete value). Subtle but fair — spec lists rune-to-int32 in same enumeration as the other two.
- **Callback wiring trap (cross-cutting):** when default-promotion fails on success path, the (correctly-wired) callback fires once → trips `TestCmdYaegi_ConstraintCallback_NotFiredOnSuccess` indirectly. Cross-package test surface (interp/ + cmd/yaegi/) catches this indirect failure.
- **Validator-iteration pattern (CRITICAL Diamond Failure-QA discipline):** R13 first pass flagged ~17 FALSE/MIXED across 10 sections; R14 second pass flagged 3 residuals; R15 third pass CLEAN. Patterns that consistently flag: (a) paraphrased repo comments ("runtime checking" vs verbatim "to be tested elsewhere"), (b) `id()` string values guessed from memory (`"untyped float64"` not present in source), (c) stdlib calls referenced when test uses helper wrapper (`reflect.Value.Kind()` vs `runOKKind`), (d) ellipsis tokens in function references (`MinX(...)` vs `MinX`), (e) bool-predicate functions credited with emitting errors (`representableConst` is bool; `cfgErrorf` emits). See `DIAMOND-PLAYBOOK.md § Section 5 rules 13-27`.
- **R-current 81-test re-batch (3/10 PASS = 30%, post CLI-restructure + sentinel relax):** after the CLI moved to run()-driven tests and substring asserts relaxed to sentinels, the failure-qa.md re-validation surfaced one MIXED per pattern, all PRECISION (not substance) issues: (a) a multi-line code fragment cited as a single backticked literal (`if it.untyped { def = defaultedItype(it, nil) }` split across diff lines), (b) placeholder tokens (`untyped X does not implement main.Y`), (c) truncated error strings (`operator == ...`), (d) a mechanism claimed that the diff did not show ("derived from a named-interface identifier" vs the actual empty-string argument), (e) a "no test-file hunks / hidden suite untouched" claim the diff contradicts — this agent shipped its own `interp/constraint_test.go`, so the claim is both unverifiable for hidden tests and outright false; state only the confined paths the diff headers show plus any in-repo test file the agent added, (f) the Go sentinel name `ErrNotComparable` quoted where junit renders the `.Error()` text `type is not comparable`, (g) a fail-count mismatch (a 22-fail run documented as 21). **Key reconciliation:** the validator verifies claims by grepping the NAMED identifiers and matching behavior to code — it locates lines itself. Line numbers are optional; the approved cliffy failure-qa carries none and passed both the validator and the human reviewer. So "single-source gets MIXED" (R15 framing) really means "imprecise/unverifiable claims get MIXED." Write cliffy-style — named methods, behavioral cause-to-effect, verbatim symptom strings, no line-number spam — and one pass clears both the auto-validator and the human reviewer.
- **Reviewer change-request round (QA-only, after validator was all-true):** the auto-validator passing all-true does NOT mean the human reviewer passes — they gate DIFFERENT things. The reviewer change-requested on four judgment issues the validator cannot see: (a) **mis-attribution** — a run's promotion-cascade tests (failing `untyped float does not implement main.X`) grouped under a typed-pin Expected/Actual (`157/50 truncated to int64`), giving wrong expected/actual/root-cause for those four; (b) **over-collapse** — 14-18 distinct-assertion tests summarized with 2-3 broad example exprs instead of a per-test `| Test | Call | Expected | Actual |` table; (c) **per-test looseness** — three rune tests sharing one example when their calls differ (`('a','b')` vs `('m','a')`) plus a missing `reflect.Int32` kind-check; (d) **success-QA verbosity + cross-run leak** — a "R12 Castor failure cluster: 6/10 fail" stat in test-groups.md and diff-step narration in PASS trajectories. Fixes: split clusters by junit error signature; per-test table when assertions differ; pull every literal from the run's ground-truth `Castors/S#N/failing-test.md` (not memory); strip ALL agent-diff line numbers (both approved diamonds carry zero); inline Test Summary groups with spec quotes + a coverage statement; de-diff PASS trajectories to `Correctness confidence` + `Issues:`. **Meta-lesson: read both approved diamonds (`cliffy-command-aliases`, `dasel-csv-options`) + the official rubric BEFORE drafting** — their structure is the proven format and matching it first-pass skips this entire round. Full rules: `DIAMOND-PLAYBOOK.md § Section 5 rules 28-34` + `lessons-learned.md rules 49-56`.
- **APPROVED 2026-05-31** (reviewer: "gtg. qa is now factually correct") after two more validator rounds: round2 = 2 MIXED (value-anchored line numbers `type.go:160`/`:152` off-by-one; float/complex over-attribution crediting the `def.equals` branch with the OTHER tests' passing), round3 = ALL-TRUE across all 10 runs. The fix that finally stuck: **strip every VALUE-anchored line number** (a number presented as the locator for a field/string value -> MIXED when off-by-one, and the validator is non-deterministic on it: S#4's identical `:160` passed the round S#5's failed) while KEEPING behavior-anchored numbers (cited beside a named function whose behavior the validator matches, e.g. `assignableTo (type.go:1466)`, which passed every run). This is the cleanest cut and is now rule 34. Second fix: in a FAILING block, never credit a named branch with the OTHER (passing) tests' success -- per-agent code differs (the same `def.equals` attribution was TRUE for S#6's code, FALSE for S#2's). **This is the 2nd yaegi Diamond (with yaegi-channel-diagnostics) to converge independently on the same QA discipline** -- validator-vs-reviewer two-gate, value-anchored ban, per-run code differs, platform-naming. 2x-confirmed = stable. The QA is graded on per-test factual correctness and has its OWN approval gate separate from solvability/Holistic/Auto-Review.

**★ rdb-sample-fraction (Diamond, 10 Castor, 1 PASS = 10%, APPROVED 2026-05-31, first rdb Diamond):**
- O-Pipeline-hard, 68 F2P tests (helper + main pkg), 51 baseline preserved. Median PASS: 8 files / 124 msgs / 488 LOC. Issue #72 (key sampling). HDT3213/rdb = Redis/Valkey RDB dump parser.
- **#1 trap (9/10 = 90%, the FAIR gate): sampler hash without avalanche clusters sequential prefix keys all-or-nothing.** Fixtures use sequentially numbered prefix keys (`acct:0..49` db1, `user:0..49` db0, `stream:`/`after:0..9`). A digest compared raw/shifted/modulo against the fraction maps a whole prefix group to ONE side of the 0.5 threshold -> the group samples empty (junit "got 0") or whole ("got 20"), failing the proper-subset + per-prefix-report tests. SEVEN distinct wrong forms across 9 runs: raw `fnv.New64a` vs fraction, low-53-bit mask `(v&(2^53-1))/2^53`, top-53-bit `(Sum64>>11)/2^53`, hand-written FNV vs `2^64`, `Sum64 % 2^53`, `fnv.New32a` vs `2^32`. The 1 PASS reduced the full digest `% 2^32`. Reference fix: avalanche/finalizer (murmur fmix `x ^= x>>33; x *= 0xff51afd7ed558ccd; x ^= x>>33`) then top bits vs `fraction*denominator`. FAIR and UNDOCUMENTED because "deterministic + processes only a fraction" implies even distribution. **9/10 failing on the SAME root cause = strong fairness signal (admin 2026-05-29), confirmed acceptable by the human reviewer — NOT unfairness.**
- **#2 trap: decode-and-discard is the universal shortcut when "skip without decoding" is not perf-gated.** ALL 10 runs (incl PASS) wrote the reject branch as base `readObject` then discard + `skippedCount++`, NOT a byte-exact `bufio.Discard`. The behavioral suite (`GetSkippedCount() > 0` + following-keys-parse) does NOT distinguish the two, so the 250-LOC `core/skip.go` central trap was non-load-bearing -> rollouts averaged 0.66 (too easy) until an allocation-budget test was added (then abandoned once the green batch locked). **Lesson: a "skip/stream without materializing" requirement needs an allocation (`runtime.MemStats.TotalAlloc` delta) or timing test to be load-bearing; behavioral-only tests accept decode-and-discard.**
- **#3 trap: public struct field types are a compile-unfairness when undocumented.** Tests do typed accumulation (`var s int; s += b.SampledKeys`), pinning `int` (counts) vs `int64` (byte/element totals + `UpperBound`). 4/5 first-batch agents chose `uint64`/`int64`-for-keys -> whole helper package failed to compile, masking ~65 tests (one eval flagged `agent_blame_unfair`). **Fix: document exact field types in the description.** A type-only mismatch that breaks compilation is an implementation-detail test, not behavioral.
- **Failure-QA validator arc (R11-R14e, 6 rounds):** the auto-validator all-true did NOT catch what the human reviewer flagged; budget BOTH gates. Every falsifiable token gets checked (hash impl inferred from a sibling run, "never zero" contradicted by junit, "built over the memory pass" production-path, cross-run "nine other runs"). Minimal claims (report + predicate + verbatim junit) pass first time. Full rules: `DIAMOND-PLAYBOOK.md § Section 5 rule 35`; repo detail: `analysis-folders/rdb-analysis/LESSONS.md`.

**★ scriggo-generics (Diamond, APPROVED 2026-06, final batch 3/10 = 25-30% Castor, "Hard"):**
- O-Composite-add, scoped Go generic functions + generic struct types (monomorphization) on a register-VM interpreter that had ZERO generics. 142 subtests / 155 junit results (parent group fn + each subtest counted), 268 baseline preserved all runs. Full repo lessons: `problems/scriggo/LESSONS.md`.
- **THE finding — compile-time transform is a shallow well (Pattern 48).** Functions-only monomorphization = ~98% pass (4 agents 111-114/116) = too easy. The natural clone-and-recheck reuses the existing checker, so concrete register kinds fall out for free and the predicted erasure trap NEVER fired. Difficulty had to be engineered + measured per lever: +generic TYPES 98%->50%, +position breadth 50%->40%, +AST clone-invariants 40%->25-30%. Recursion (predicted to help) barely moved it. **Predictions lie on this class; a real batch is the only oracle.**
- **#1 trap: pointer-base position `*Box[int]` / `[]*Box[int]` — highest hit (4-5/7 fails).** Parser accepts a type-arg bracket on a bare identifier but not after `*` or `[]`. Spec lists pointer base verbatim; agents implement the common 4 positions and miss it.
- **#2 trap: bare generic name custom diagnostic vs `undefined` — 3/10.** Agents pre-declare the template in scope + emit `cannot use generic %s without instantiation`, never reaching the language's existing undefined-identifier path. Fix: leave a bare generic name on the normal unresolved path.
- **#3 trap: AST clone drops the switch-default nil sentinel.** Clone allocates a non-nil empty `Case.Expressions` slice for a `default` -> termination analysis misreads -> false "missing return at end of function." Each statement node is an independent clone-invariant; one control-flow-in-body test per invariant catches a different impl.
- **Erasure separator is FIELD-kind, not whole-value:** a struct value crossing into native `fmt` collapses whole-struct `%T` through the native-bridge proxy. Assert `b.V`'s `%T` (the field), never the whole value's.
- **Post-eval QA arc (Pattern 49 + DIAMOND-PLAYBOOK rules 48-53):** validator marked root causes FALSE when they claimed "agent doesn't substitute X" but the diff HAD X-handling (bug subtle within it) -> rewrite as observable error + "concrete equivalent passes." Helper-chain mis-attribution (`runGenericsOut` builds/runs -> actually `genericsOut`). Cascade run (a panic inflates the fail count) must be SPLIT into real failures + synthetic post-panic (`new tests were missing from the JUnit XML (exit code 1)`), never "did not execute" for tests that ran. Multi-signature run: UI annotation testName buckets get crossed even when the file is right (reviewer caught it). solution-approach.md reject for being too low-level + listing internal helpers -> rewrite high-level, public-surface-only.

**★ csstree-calc-typecheck (Diamond, APPROVED 2026-06-05, hinted 1/20 = 5%, "very hard"; FIRST csstree + first JS/mocha Diamond):**
- Two-capability cross-subsystem bundle: CSS cascade-layer (`@layer`) order resolution + `calc/min/max/clamp/round/mod/rem` dimensional type-checking, sharing a `ResolveError` base. 156 new tests (121 calc + 35 cascade), 772 eff LOC / 6 files, 4000 platform-baseline preserved. Unhinted 0/10 (best 150/156); hinted 1/20.
- **Castor solves BOTH algorithms cleanly; the difficulty is FAIR residual walls, not the headline feature.** Failure distribution across 10 unhinted runs: clamp/min/max percent-hint reconciliation 8/10, pure-number-via-nested-calc-production property gate 7/10, percent^2 serialization 4/10, `@media` conditional-group layer descent 4/10, gate-doesn't-filter-error-resolving-calc 3/10 (incompatible-sum / length-divisor / nested-invalid), offending-node Function-vs-leaf 3/10, ResolveError-real-subclass instanceof + comparePriority-signature 1/10 each.
- **★ Top reusable Castor traps (JS-flavored, cross-architectural):** (1) shared error base must be a REAL `class X extends Base` for `instanceof`, NOT a factory/marker returning a plain Error (8/10 miss). (2) a reconciliation rule defined for path A (percent-hint in addition) must be REUSED on path B (min/max/clamp consistent-type), else strict-equality rejects the percentage (8/10 miss). (3) accepted-type set over-collected by walking the FULL value grammar pulls `<number>` from the inner calc multiplier production -> a dimensionless calc satisfies a length property (7/10 miss); fix = top-level-grammar-only.
- **Return-shape coin-flip (the UNFAIR signatures — spec'd in meta, NOT hinted):** comparePriority (-1/0/1 vs raw diff), revertLayerTarget (name vs entry object), cascadeOrder.layer (name vs object) each 10/10 universal fail until the exact return type was stated.
- **Hint that worked (1/20):** 2 levers (clamp percent-hint + property-gate top-level types) flipped the one near-miss whose only 2 fails were exactly those walls. Others kept an un-hinted fail -> ceiling stayed 1.
- Post-eval QA-validator arc: `PATTERNS-ADVANCED § Pattern 50`. Iteration discipline (measure-before-trap, 3-rollout fluke): `Pattern 51`. Per-problem dive: `PROBLEM-PROFILES.md`.

**★ chai-array-type (Diamond, APPROVED 2026-06-07, 2/10 = 20% Castor, "challenging"):**
- Parametric ARRAY column type for chaisql/chai (`INTEGER[]`/`TEXT[]`/nested `INTEGER[][]`): literals, element access, 6 builtins, `||`, CAST, ordering, keys/indexes, GROUP BY/DISTINCT, catalog round-trip across reopen. 459 eff LOC / 14 files.
- **THE finding — the difficulty was the public-boundary INTEGRATION, not the algorithm.** The feared marquee wall (byte-sortable variable-length array encoding) was FREE: genji-leftover `compareNonEmptyValues`/`SkipArray`/tags already order arrays element-wise. GREP the encoding comparator before assuming encoding is the wall. Matches the opus-4-8 depth law — decisive walls live in the real-codebase integration stack.
- **★ #1 Castor trap (7/10): driver-render boundary.** Agents build the internal `ArrayValue` correctly but expose it through the `database/sql` driver UNRENDERED, so `rows.Scan(&string)` fails at the boundary. Three distinct wrong impls across the 10 runs: `dest[i] = v` (raw `types.ArrayValue`), a local `arrayValue` wrapper `dest[i] = arrayValue{v: v}` (error names `driver.arrayValue`), `dest[i] = v.Encode(nil)` (raw bytes -> scan SUCCEEDS but equality-mismatches on binary). Correct = render text in `Rows.Next` like the neighboring scalar arms. Build-the-value-but-not-the-wiring is a reliable Castor blind spot: it satisfies internal unit reasoning while missing the public consumer surface.
- **★ #2 Castor trap (3/10): "cannot" substring on delegated overflow.** Element conversion delegates to scalar `CastAs`; a bigint->int32 overflow returns "integer out of range"; spec requires the surfaced message to contain "cannot", so the array site must wrap. Agents wrapping only the nested-depth branch (not the scalar element path) leaked the raw error.
- Arch: flat `types.Type uint8` can't hold an element type -> `ColumnConstraint` gains `ElementType`+`ArrayDepth`, `String()` emits `INTEGER[]`/depth (catalog round-trips on reopen); element enforcement lives in `encodeRow` (one site covers INSERT/UPDATE/INSERT..SELECT). N-gate parity: 6 dispatch arms + decode map + row marshal + driver + `constraint.String`.
- Post-eval QA arc (DIAMOND-PLAYBOOK rules 65-68 / Pattern 53): per-run distinct construct (never reuse a driver block -> Shipd UI cross-maps near-identical blocks), observable-anchored fixes (not the hidden reference), group-by-body-not-name. Per-problem dive: `PROBLEM-PROFILES.md`.

### Vega (Olympus only)

- **Strength:** highest raw scores among failing runs. Best non-pass: 26/27 (Run 20), 46/47 (Runs 9/11/15). Long-horizon: 400-1050 LOC across 5-13 files.
- **Weakness:** needs most prescriptive hints. 0% pass without method-extraction recipe (Runs 12-15, 20). With recipe: 10% (Runs 9-10).
- Sometimes uses wrong import paths (underscore vs hyphen)
- Uses `writeSync` instead of `console.log` for stdout
- Lower code volume than Castor (571 vs 1500+ LOC)

**★ yaegi-reflect-identity (40+ Vega runs):**
- (a) **Implements for interpreter interfaces:** 9/10 fail Run 9, 9/10 Run 15, best 26/27 R20. Extracts method names from `valueInterface` struct FIELDS (`node`, `value`) instead of itype method list. Field-name stripping yields wrong names ("ode", "alue").
- (b) **1:1 type registry:** `map[reflect.Type]*itype` fails for empty structs sharing reflect.Type. Never independently discovers 1:many + discriminator.
- (c) **interpTypeOf only wraps struct-kinded:** skips interface types → Implements vacuously returns true.
- (d) **Pointer receiver blind spot:** only tests value receivers; hidden tests use pointer.

### Nova (Mars only — 10 runs)

- **★ Nova ≈ Castor now (2026), in places SMARTER.** Nova single-shot-fixes isolated / self-revealing / single-point traps even on Mars rate runs. **Consequence: traps must be INTERDEPENDENT + MISDIRECTING at EVERY tier, not just Diamond.** The old "single-point trap registers ~50% on a rate gate and is fine for Mars" rule is DEAD. See `../CLAUDE.md § ⚠️ HARD RULE — Difficulty-Calibration Model`.
- **★ CONFIRMED blind spot (symengine-imageset, 9/10 miss, 2026-07-02): canonical-type narrow-guard.** Nova special-cases a type-family branch on the DOMINANT member (`is_a<Integers>`) and forgets co-equal siblings (Naturals/Naturals0). The delegation the spec mandates for the OBVIOUS operation (membership) is not re-applied in a SECOND path (enumeration). Load-bearing Mars wall (10%). Exploit through TEST DESIGN (sibling type in the second op), never by naming the type list in meta. See `AGENTS.md § Confirmed Blind Spots` + `PATTERNS-ADVANCED.md § Pattern 62`.
- **Unreliable on simple tasks** — frequent API failures (0 tokens, never starts) in cliffy/dasel (historical; capability has since climbed)
- When it runs, similar patterns to Castor with less code
- High variance; each failing run has different fundamental bug

**★ cliffy-output-format (Runs 7-11, 16):**
- (a) **Missing explicit exports:** fails to export pre-existing base classes (`CommandError`) even when requested → module load failures.
- (b) **Pipeline bypass for substituted values:** correctly substitutes null with `nullValue` then bypasses quoting helper. If `nullValue` contains delimiter → invalid CSV.
- (c) **Separator vs Line Ending semantics:** appends `lineEnding` to end of entire string instead of joining rows.
- (d) **API Shape inference:** "a map of formatters" → defaults to `Record<string, Formatter>` instead of custom `FormatterRegistry`.

**★ yaegi-reflect-identity (R9 vs R20 evolution):**
- 0/5 R9 → 1/6 (17%) R20. Significant model improvement.
- **Strength when it works:** R2 (R20) — 300 LOC, 491 msgs — leanest passing solution.
- (a) **fmt.Errorf no-op passthrough:** 3/5 failing — adds Errorf to mapTypes but reassigns `fmt.Errorf` without custom wrapper. Intercepts but interceptor does nothing.
- (b) **Sentinel field approach:** R1 added YaegiIdentity field to structs → bleeds into fmt output.
- (c) **valueInterface propagation:** R6 assumed binary functions preserve interpreter wrappers (they don't — binary Go strips).

**★ yaegi statement/jump legality (APPROVED Mars 2026-06-18, 4/11=36.4%, holistic FAIR):** pure Go-spec conformance bundle (goto-over-var-decl / unused-label / fallthrough-final / dup-case / break-continue-placement / expr-stmt-not-used). Two dominant FAIR biters:
- (a) **representation-divergent constant (bool dup case):** see § folded-builtin blind spot above — `constant.Value` keying skips bool rval, 5/11 missed (hardest test).
- (b) **★ prose mode-distinction → WRONG internal signal:** "checks apply to whole-file programs; incremental REPL stays lenient" — agents gate strict checks on the obvious `inc` flag, but `Eval("package main...")` is `inc=true` yet structurally a `fileStmt`-root whole-file program, so goto/unused-label/expr-stmt checks silently no-op on the verifier's package-form Eval inputs — 3/11 missed (whole groups failed "expected rejected but ran"). The CORRECT signal is the parsed root kind (`inWholeFile()` walks to root, `root.kind==fileStmt`), NOT the compile flag. Reusable interpreter trap: a mode boundary stated in prose maps to a non-obvious internal signal, and the obvious flag is wrong on a foreseeable public entry-point.
- (c) lesser: backward-goto label flagged unused (use-check runs before later goto marks it), over-broad expr-stmt regressing type-switch baseline (the `x.(type)` guard is itself an exprStmt — gate on `n.anc.kind==blockStmt`).

**★ findmyway-parametric-parse (APPROVED Mars 2026-06-19, 3/10=30%, holistic FAIR/ship-as-is):** reverse-routing feature (build URL from a registered route, inverse of parse) + #369 intermediate-static canonicalization fix. ⭐⭐ **BITER TAXONOMY (the decisive lesson): on a MECHANICAL / well-specified feature, frontier Nova passes EVERY self-contained transform — only HIDDEN-REGISTRATION-INTEGRATION concepts bite.** Confirmed cold across a 20-run + 10-run batch: form-encoding (query space→`+`), sorted-query, percent-encoding, regex, `::`-escape, constraints, reverseAll — ALL bit 0% (pass_rate_across_rollouts=1.0). The two concepts that carried it to 30% (an agent must get BOTH; they compound):
- (a) **★ bare-`*` wildcard reverse canonicalization (5/10 fail):** agents normalize `*`→`/*` for BUILD but their findRoute/route-key traversal doesn't resolve the canonical root wildcard → `reverse('/*'|'*')` for a route registered as `*` returns null, OR crashes `TypeError: Cannot read properties of null (reading 'routes')` (un-guarded `currentNode.routes` after wildcard traversal). Half-fix shape: special-case `*` but not the `/*` form, or build-normalize without resolve-normalize. The agent must replicate registration's `pattern==='*' → '/*'` canon in BOTH resolve and build.
- (b) **★ optional-positional-after-required (4/10 fail):** `reverse('/u/:a/:b?', ['x'])` → agents test optional presence via `params[0]`/array-non-empty instead of counting required params BEFORE the optional → treat `:b?` present → consume `x` for `:a` → throw missing `:b`. Correct: optional present iff `array.length > countParams(without-optional)`.
- ⭐ Anti-lessons (mine): (1) TEST-ONLY COVERAGE PADDING RAISES pass rate — R7 41 tests=50% → R8 84 tests=80% (more tests of well-specified behavior dilutes with passes; difficulty knob is biting CONCEPTS, not test count). (2) DON'T over-declare a ceiling pre-eval — I called "20% impossible / floor ~38-45%"; it landed 30% because optional-positional bit 40% ALONE (under-credited). (3) Fair↔difficulty tension: reworking the slash-normalization sentence to clear the Fair gate made that group bite 0%, yet difficulty SURVIVED on (a)+(b) — Fair-fix doesn't always sink difficulty if other biters carry. (4) PRE-PICK: a mechanical-inversion feature is NOT auto-dead — it lands Hard (30%) IFF it has ≥2 hidden-registration-integration concepts that compound; with <2 it saturates ~50-80%.

**★ cel-go-cost-coverage (APPROVED Mars 2026-06-24, ~25% over a 13-run batch, holistic FAIR):** opt-in `OptionalTypesCostTracking()` brings the optional-types library into CEL's cost system across a DUAL-MAINTENANCE pair (static estimator checker/cost.go <-> runtime tracker interpreter/runtimecost.go) + size-aware base64. Confirmed Nova/Orion blind spots, recurrence-ranked:
- (a) **★ static-soundness off-by-one (10/14 miss, the dominant FAIR trap):** static `Max` must stay `>=` runtime `ActualCost` through `[..][?0].orValue("").contains("z")`; the naive bounded-size fix lands static ONE unit BELOW runtime, and ONLY at large size -> MISDIRECTING (small inputs pass, the failure surfaces only at scale where it reads like a flaky bound). Cost-coverage of a static<->runtime twin is a reliable interdependent+misdirecting Mars trap class (see Pattern 58 + olympus-extreme-complexity-guide).
- (b) **hasValue charged by wrapped-value size instead of a constant (7/14):** `hasValue` is O(1) presence, not proportional to the optional's contents; agents scale it by the wrapped value.
- (c) **or/orValue branch asymmetry (5/14):** static estimate must be the UNION of branch sizes (longer branch -> larger Max), not target-branch-only.
- (d) **optional.none not finite-size-0 (2/14):** the empty optional has a known size of 0, not unknown/unbounded.
- EASY (≈100% pass, do NOT lean difficulty on these): base64 size-awareness, opt-in gating (no charge without the option), default-unchanged behavior, the non-optional twin, unwrap size-scaling.

**★ participle-longest-match (ACCEPTED Mars 2026-07-02, final 3/10=30% ALL-FAIR; earlier batches 8.3%, 10%):** greedy `||` longest-match alternation for participle's disjunction engine. ⭐⭐⭐ **The uncorrelated FAIR leak wall (`TestGreedyRejectedAlternativeDoesNotLeak`, speculative capture rollback of the SHARED PARENT struct) was the DOMINANT biter in every batch** (6/10 in the accepted run; 11/11 earlier). Failing agents transcribe the feature perfectly — longest-match selection, earliest-tie, furthest-error + expected-set, EBNF `||` render, mixed-operator Build error ALL pass — then ship a greedy loop that branches the lexer cursor but never snapshots/restores `parent`, so a rejected alternative's direct capture (`@'!'`->bool) leaks into the winner. The feature is dictation; the wall is everything.
- **★ 2ND WALL surfaced only after the feature was expanded (final batch, 1/10): `||` at STRUCT-FIELD boundaries.** participle's existing `|` works across field tags (a later field's tag can begin with `| @@`); a full `||` counterpart must too. Agents implement `||` for same-tag flat alternations only -> a `|| @@` in a later field tag fails to BUILD ("alternative expression 2 cannot be empty"). Fair (inferable from "counterpart to existing ordered `|`" + visible field-boundary `|`). Reusable: for a "counterpart to existing operator X" feature, the existing X's less-obvious placements (field boundaries, groups) are a second integration wall agents miss.
- **★ Pass rate ROSE 8-10% -> 30% after the revision round** (dropped the scope-creep `Greedy()` option, added error-diagnostic LOC + a mixed-operator test + concise meta). Small-N variance + slightly more transcribable surface, but the leak wall still dominated and it stayed IN-BAND (30% = Mars cap). Lesson: revising for LOC/pre-checks can nudge the rate; keep the core wall byte-identical and re-batch.
- **★ Greedy-scope-creep (Auto Review solution_unasked_feature):** a global `Greedy()` option added PURELY for LOC margin is scope creep (untested public API changing `|` semantics; prompt asks only for `||`) -> Blocking FAIL. Never pad LOC with public API. Fix LOC via genuine NON-trap-axis depth (here: error-diagnostics) keeping the wall identical.
- **★ THE BLIND SPOT (reusable): agents trust the framework's backtracking primitive as FULL speculative isolation when it only isolates SOME state.** participle `ctx.Branch()` copies the lexer cursor + the deferred `apply` list, but NOT direct reflect mutations to the shared `parent reflect.Value`. A greedy alternative that captures directly into a parent field (`@'!'`→bool) then fails partway through leaves that mutation behind (via `strct.Parse`'s best-effort `Apply()` on error), because all alternatives share one `parent`. Agents branch the lexer per alternative, pick the longest, `Accept` the winner — and never snapshot/restore `parent`. Fix = `snap := parent copy; ...; parent.Set(snap)` after each attempt. When a repo's speculative primitive isolates lexer/deferred state but not the destination object, that un-isolated channel is a near-universal Nova blind spot.
- **★ THE MISDIRECTION that worked (design lever): agents PROACTIVELY wrote their own rejected-capture leak test — but chose the WRONG SHAPE.** Multiple evals: "the agent added a rejected-capture test, but it only covered one nested-pointer shape and missed immediate/shared-parent mutations." They tested the leak shape their impl already handled (nested pointer / deferred), gained false confidence, and shipped. The hidden test uses the shape they DON'T self-generate: a DIRECT scalar capture into the parent BEFORE a partway failure. LESSON: pick the trap shape agents self-test AROUND, not the one they self-test.
- **Speed correlated with failure:** fast decisive Nova (6-10 min, 178-228 LOC) shipped the incomplete isolation; the sole PASS (Orion, 19 min, 420 LOC, 9 files) actually snapshotted the parent. Decisive-commit agents ship the plausible-but-incomplete solution.
- **⭐ Build-measure PREDICTED the batch exactly** (the naive Branch-based impl was proven to leak BEFORE authoring) — first time a local probe forecast a real batch. See lessons-learned § contract-stated-fix-hidden + PROBLEM-PROFILES.

### Orion (Mars Evaluator + solver)

**★ cliffy-output-format (Runs 12, 13, 16):**
- High comprehension of explicit requirements + API shapes. 100% pass (2/2) Run 16 vs Nova 0/5 same prompt.
- Acts as positive control for "Hard" difficulty — proves problem is solvable & fair.

**★ yaegi-reflect-identity (R20, 2 solver runs):**
- **Most efficient solver across agents.** R7: 23min, 135 msgs, 548 LOC — fastest/cheapest solve.
- **Binary decision-making:** either gets architecture right immediately or fails completely.
- **Weakness:** when wrong architecture chosen, doesn't pivot. R8 tried `reflect.Type` method interception via `genInterfaceWrapper` (interpreter wrapper level) — Go dispatches `reflect.Type` methods natively, can never work.
- **Confirmed trap:** errors.As half (12/12) vs reflect.TypeOf half (0/15 R8). One subsystem clean, other fundamentally wrong.

### Cross-Agent Patterns

- **ALL agents** fail on shared LLM blind spots — if one misses general constraint, all will
- **ALL agents** implement features independently then wire — cross-cutting interaction tests catch them
- **ALL agents** trust description examples over general rules — be careful with examples that narrow scope
- Pass rate correlates with description specificity: too vague = unfair fails, too specific = 100% pass
- **ALL agents** interpret "initializing the full X system" as "call default constructor" — use this phrasing for "subtle but fair" traps
- When Castor scores 110/111, single failing test is almost always semantic interpretation (exception: no-op ternary)

**★ expr-switch (Nova 10-run Olympus, ACCEPTED 2026-06-19) — partially-constant fold + accumulator-scope:**

1. **Over-eager constant fold of a PARTIALLY-constant construct (~7/10):** given a constant DISCRIMINANT but nonconstant ARMS (`switch 1 { case x: ... case probe(): ... }`), agents fold on the outer constant alone and treat nonconstant arms as non-matches -> compile the default, skipping the runtime cases. Reusable for any "settle when FULLY constant" feature: agents settle on the OUTER constant. MISDIRECTING (the failing test asserts a runtime match; the bug is in the optimizer/fold, not where the assertion points).

2. **Accumulator-scope boundary — per-element vs per-group (~6/10):** when a uniqueness/collision rule is scoped to GROUPS but the natural loop iterates ELEMENTS, agents update the seen-set at the element boundary -> false collisions WITHIN a group (`case 1..5, 3:` rejected because 3 is compared against the SAME arm's range). Scope the accumulator to the group, not the element.

3. **Const-evaluator narrowness:** agents' constant folders handle numeric arithmetic but not string concat (`"a"+"b"`), so computed-string duplicates slip past a duplicate-constant check.

**★ yaegi-reflect-identity (80+ runs across 8 batches):**

1. **fmt.Errorf no-op universal:** agents add Errorf to mapTypes (correct first step), don't create custom wrapper preserving type identity. 4/11 R20 fails, 4/9 R14 fails. "Intercept" treated as "register" not "replace with custom logic."

2. **Implements for interpreter interfaces is #1 difficulty driver:** lowest pass rate across ALL eval batches. Agents universally guard `Kind()!=Interface` by returning false despite hint saying "rather than panicking or returning false." Struct-as-interface representation is yaegi-specific quirk no agent reasons about correctly.

3. **Pointer receiver systematic blind spot:** test value receivers (`func (e MyErr) Error()`), production uses pointer (`func (e *MyErr) Error()`). Causes: TypeOf doesn't handle pointers (3 runs), errorsAs panics (R12), NumMethod returns 0 (3 runs).

4. **1:1 vs 1:many type registry:** every agent uses `map[reflect.Type]*itype` (1:1). Fails silently for empty structs + identical-layout types sharing reflect.Type. No agent discovers `map[reflect.Type][]*itype` + name-disambiguation.

5. **Hint effectiveness cliff function:** sharp threshold. Without fixStdlib hint: 0-35/47. With: 42-46/47. Adding method-extraction recipe: 1-2 over the line to 47/47. Each layer unlocks qualitatively different failure mode.

6. **Unsafe runtime type patching universal first instinct:** ALL agents gravitate to `go:linkname` + modify `abiType` fields. Cannot add methods to reflect types → breaks Implements(). Correct approach (fixStdlib interception + reflect.Type wrapper) never discovered without hint.

**★ yaegi-execution-tracer (20 Castor + 12 Diamond eval runs, ACCEPTED Olympus 2026-05-14):**

7. **Frame-anchored state propagation vs goroutine-id maps:** 90% of Castor (16/18) use `sync.Map` or `f.root`-keyed shared state for goroutine depth. yaegi shares OS threads across goroutines so gid-keyed tracking is fundamentally broken. Only 2/18 independently discovered per-frame `tracerCallState` propagation via frame ancestry with `goStmt` boundary detection. **Reviewer-praised pattern: per-frame state field inherited from parent frame, reset at goStmt ancestor.**

8. **Persistent-set vs sum-per-call aggregation:** 7/11 Castor (64%) write `cr.TotalLines += lineCount` (Σ per-call distinct counts) instead of lifetime set `|∪|`. 2-line func × 2 calls yields 4 not 2. The word "distinct" alone in spec is INSUFFICIENT — agents read it as per-call distinct, not lifetime distinct.

9. **Concrete counter-example hint beats verbal description (>4× reduction):** TotalLines failure rate dropped 100% → 22% after adding "2-line func × 2 calls = 2, not 4" to spec. Counter-example matches test assertion directly. **Abstract hints fail; concrete counter-example values from tests succeed.** Same hint pattern proven on goroutine depth (failure 90% → 89% — verbal "frame hierarchy" hint insufficient, concrete recipe needed).

10. **Architectural hint placement matters:** runCfg/funcDecl hint in iteration 8 eliminated 100% of varDecl + off-by-one failures. Placing hint at the code generation phase rather than runtime evaluation = right architectural layer. Wrong-layer hints (e.g., "use frames" at evaluation) get ignored.

11. **Test files in test-only subpackage avoid harness collisions:** `tracertests/` subpackage isolates author tests from agent-created `TestTracer*` collisions. 3/20 Castor runs hit collisions before subpackage isolation. Pattern: use test-only Go subpackage when testing interpreter-internal types.

---

## Message Count — How It Actually Works

### Median Computed on PASSED Runs Only

Platform computes median message count **exclusively from runs where agent solved.** Failed runs excluded.

- 1/10 pass at 56 msgs → median = 56
- 3/12 pass at 116/135/169 → median = 135
- 403 msgs for failing bash-loop run = **completely irrelevant**

A problem targeting 1-3/12 passes is structurally biased toward low msg counts because only fastest agents solve. Stuck agents never pass.

### Bash Hang Phenomenon (Castor-specific)

Castor agents writing large Go files via shell heredoc reliably loop:

```
{"command":"cat > /app/file.go << 'GOEOF'\n..."}  ← hangs
{"restart":true}  ← loop
{"command":"echo 1"}  ← loop
```

50-350 extra turns in failing runs, ZERO impact on median (those agents don't pass). Only `str_replace_based_edit_tool` → `create`/`str_replace` avoids the hang and can pass.

**Implication:** can't increase median by making problem harder — harder = fewer agents pass = most efficient survive. Slightly easier brings in mediocre agents with more msgs → INCREASES median.

### ★ MANDATORY: Every Problem Must Have One Cross-Package Integration Requirement

**Bypass is last resort, not default.** Every problem MUST include ≥1 requirement forcing agents outside primary package.

#### Structural Levers (pick ≥1 — REQUIRED)

1. **★ REQUIRED: Multi-package changes** — touch files in 2+ separate packages. Minimum bar.
2. **CLI flag registration** — if repo has CLI, expose new options as actual CLI flags. Agents must find flag file, understand pattern, add flags, wire to reader/writer. Adds ~20-30 turns.
3. **Public API surface** — 3-5 public methods/functions beyond core (`Options.Clone()`, `Options.String()`, `detectSeparator()`). Each = read + implement + test. Adds 15-25 turns.
4. **Split across files deliberately** — options validation, parsing, auto-detection, formatting in separate files with specific names.
5. **Force debug loop from architecture choice** — naive first arch (e.g. `encoding/csv`) compiles but fails tests, requiring rewrite. 20-40 turns of debugging.

#### Red Flags (catch before first eval)

- All changes in single package, no cross-package deps → ~50 winning msgs
- Correct architecture works first try (no required debugging) → ~50 winning msgs
- No CLI/API surface requirements → ~50 winning msgs

#### When Bypass Is Acceptable

Only when:
- Already submitted with passing review + eval calibration (10+ runs)
- AI reviewer 19/19 PASS, all failures FAIR, 10+ eval runs evidence

## piccolo-to-be-closed — Castor/Orion blind spots (APPROVED Olympus 2026-06-24)

11-run Castor batch (Orion eval) on Lua 5.4 to-be-closed variables in a stackless Rust VM. 2 PASS / 8 FAIL_MISSED_REQUIREMENT / 1 no-artifact = 20%. Confirmed traps, recurrence-ranked across the failing runs:

| Trap | Biters | Symptom | Root cause in agent code | Why it bites |
|---|---|---|---|---|
| **repeat-loop per-iteration close** | 6/10 (#4,5,7,8,10,11) | "aaa"→"a", or HANG (#11 exit 124) | tbc tracked by stack index + dedup; loop reuses register | natural representation choice, shared by all close paths, surfaces as wrong count or hang not "you deduped" |
| **goto-within-scope premature close** | 3/10 (#8,9,10) | "xa"→"ax" | close emitted before every forward named goto | needs leaving-block vs within-block distinction via patched jump stack level; misdirecting log order |
| **non-closable error names the variable** | 2/10 (#1,4) | error lacks local name | declared name not threaded compiler→runtime error | explicit in meta but easy to drop the name plumbing |
| **generic-`for` fourth value closes** | 1/10 (#8) | not closed on normal end/break | closes only on error-unwind | hot-opcode result-slot relayout; the reshape lever |
| **return value fixed before closer side-effect** | 1/10 (#10) | "1\|2"→"2\|2" | CloseTbc emitted before return values materialized | standard Lua return ordering, subtle |

**Castor signature here:** builds a broad, mostly-correct implementation (660–968 LOC, 354–664 msgs) that passes baseline + 62–66/67 new tests, then loses on 1–5 deep semantic edges. The passers (#3, #6) nailed all of them with substantive runtime work. Failure clusters are MISSED-REQUIREMENT, never verifier mismatch — every failing behavior traced to an explicit meta sentence. A hang counts as a fair agent failure once the harness bounds it with `timeout`.

### REAL Nova batch (post-hardening, 80 tests, 2026-06-28) — 2/10 = 20%, recurrence CORRECTS the Castor read

10 runs Nova solver / Nova eval, all healthy + fair (zero infra, every FAIL = FAIL_MISSED_REQUIREMENT, agent_blame_unfair=false). Nova traps, recurrence-ranked:

| Trap | Biters | Symptom | Severity |
|---|---|---|---|
| **generic-`for` 4th value closing (normal end / break)** | 5,8,9,10 = 4/10 | "123"→"123C(nil)", "12"→"12C", or never implemented | **CATASTROPHIC: 8–22 fails each** — agents skip the whole sub-feature |
| **coroutine.close error-threading** | 2,4,8,10 = 4/10 | stops after first closer raises; Run 4 PANICS executor.rs:511 routing close-err through normal error frames | 1–2 fails (Run 4/8/10 part of larger clusters) |
| **return-from-for-body close ORDER (bF vs Fb)** | 1 | "1Fb" vs "1bF" — the R6 interleave trap | decisive on the 78/80 near-miss |
| **goto-within-scope premature close (ax vs xa)** | 7 | close before forward in-block goto | Run 7's only failure |
| **normal-exit close-error propagation** | 9 | __close raising on a nil-errobj exit swallowed | part of 14 |
| **error-names-the-variable (empty name)** | 8 | variable '' instead of the name | part of 20 |
| **captured-upvalue-still-closes** | 1 | stack slot nil'd before close | part of 2 |

**Nova signature:** writes 479–687 LOC / 175–244 msgs, passes baseline + most new tests, then loses on a sub-feature it never finished. KEY: unlike the Castor read (which had the single deep-edge failures), real Nova FAILS A WHOLE SUB-FEATURE CATASTROPHICALLY (generic-for 4th value, 8–22 fails) because it runs out of budget / deprioritizes it. **This corrects the local-sim conclusion** that the feature was "near its single-wall ceiling": the generic-for 4th value is a genuine SECOND wall (its own opcode + compiler path), and agents who solve the unwind wall still skip it. The 3-agent local sim missed this because all 3 happened to implement it — the sim under-samples the "skip a whole sub-feature" failure mode. The 10-run platform batch is the only oracle (re-confirmed). The R6 interleave trap (`return_from_generic_for_body`) was the decisive failure for the strongest near-miss, so the hardening contributed.

### R10 confirm (81-test post-fix batch, AUTO-APPROVED, 2/10=20%) — 2 NEW walls surface

A second healthy Nova batch (81 tests) landed the same 2/10=20%, all-fair, and confirmed the ranking (generic-for 4th value dominant, 6/10). Two NEW walls the 80-test batch had not surfaced, both worth reusing on any stackless-VM / bytecode feature:

- **coroutine.close × upvalue-capturing `__close` → RefCell borrow panic (4/10, sharp).** When the pending `__close` is an ordinary Lua closure that captures an outer variable (the test's `log`), running it during `coroutine.close` makes the nested executor try to mutate the OUTER thread's still-borrowed open upvalue → `RefCell already mutably borrowed` panic (thread.rs:291/297). One agent (Run 7) recognized it and DODGED it by weakening its own golden test rather than fixing the runtime — a tell that this is a genuine hard integration wall, not a spec gap. Reusable: a metamethod that runs during a cross-thread teardown + captures caller state exposes borrow/aliasing bugs the happy path hides.
- **Existing size-invariant regression (`tests/sizes.rs`: `size_of::<OpCode>() <= 4`) — 2/10 BASELINE fails.** Agents add new opcode variants and blow the packed 4-byte budget → the pre-existing size test fails → baseline regression. This is a free, high-value trap on any repo with a `size_of` invariant test: a feature that needs new enum variants forces a PACKED representation (piccolo's dual `Operation`↔`OpCodeRepr`), and agents who add variants naively (or never run the full base suite) regress it. Also caught the Run 6 generic-for register-layout regression that hung normal loops (base+3 vs base+1) — the opcode/layout surface is where agents break EXISTING behavior.

Both R8 robustness fixes validated in production: the test.sh `timeout`+synthetic-failure fallback graded 3 agent-hangs (exit 124) as fair FAILs (not verifier-broke), and cargo2junit surfaced the real panic blocks the eval cites.

### R12 (3rd consecutive 20% batch) — the "near-miss discriminator" tier is the real band-setter

A third healthy Nova batch landed the same 2/10=20% all-fair (R7/R10/R12 all 20% — a broad, multi-sub-feature feature converges to a very stable band). The reusable insight from three batches: a healthy batch has TWO tiers of failing tests, and only one sets the band.
- **Catastrophic-cluster tests** knock out the WEAK/mid agents (they never finished a whole sub-feature): generic-for 4th value (8–25 fails), break/goto emitting no close at all (6 fails), the `sizes.rs OpCode<=4` baseline regression (agents grow the enum). These make the batch LOOK hard but they only remove agents who were going to fail anyway.
- **Near-miss discriminators** are the precise single-edge tests that catch the 80/81 agents — the ones deciding pass vs near-pass. In R12: `goto_out_of_nested_blocks_closes_all_in_reverse` ("cba"→"c": agents record ONE close-bound per unresolved jump so only the innermost block closes — Run 6 sole fail), `coroutine_close_with_no_pending_returns_true` (vacuous-true boundary — Run 8 sole fail), and the close-stack absolute-index-goes-stale panic (stored stack indices point past length after truncation on multi-closer unwind — Run 5, thread.rs:918). Several of these are the R5/R6 hardening additions.

**Design takeaway:** the band is set by the near-miss discriminators, not the catastrophic clusters. When a batch shows most fails at 80/81 on a HANDFUL of precise edges, those edges ARE your difficulty — protect them and add siblings in that tier; the big-cluster fails are just the weak-agent floor. This is why the R5/R6 precise-edge hardening mattered even though the catastrophic generic-for cluster dominates the raw fail counts.

Bypass is recovery tool, not design strategy.

## glaredb-ordered-aggregates — Nova/Orion blind spots (APPROVED Olympus 2026-06-27)

Two unhinted batches (Nova solver / Orion eval) on aggregate-local ORDER BY + FILTER + new value aggregates in a Rust SQL engine: 1/10 then 2/12 (10% / 16.7% Hard). Confirmed Nova/Orion traps, recurrence-ranked across both batches (~22 runs):

| Trap | Biters | Symptom | Root cause in agent code | Why it bites |
|---|---|---|---|---|
| **DISTINCT-hash-scramble** | ~5/22 | `string_agg(DISTINCT v ORDER BY v)` -> `c,a,b` not `a,b,c` | global-sort-before-aggregate, DISTINCT still routed through hash-table scan (hash order) | the OBVIOUS design; wrong order misdirects toward "sort broken", not the distinct path; needs dedup-after-sort in agg state |
| **planner/exec index-OOB panic** | ~3/22 | crash in column_expr/batch (len N index N) | ORDER BY columns threaded into agg pre-projection with inconsistent indices; `PhysicalAggregateExpression.order_by` left `Vec::new()` | brittle aggregate-input layout assumption |
| **aggregate-exec rewire -> baseline regression** | ~3/22 | distinct/setop/group-by-no-agg return empty/wrong | routed input once-per-aggregate, broke grouped paths with no non-distinct aggregate | over-broad refactor of the hash-aggregate insert path |
| **knowingly incomplete** | ~3/22 | ORDER BY "not yet implemented" / arg_min-max skipped | early termination on an explicit requirement | feature breadth vs budget |
| **FILTER-CASE-wraps-delimiter** | 1/22 | "Second argument to STRING_AGG must be constant" | FILTER implemented by CASE-wrapping EVERY arg incl. the constant delimiter | repo's pre-existing invariant fires |
| **NULLS coupled to DESC** | 1/22 | `DESC NULLS LAST` puts null on wrong side | `reverse()` applied to the whole comparison incl. null placement | SQL requires direction and null placement independent |

**Nova/Orion signature here:** broad 700-1100 LOC implementations that pass baseline + the easy ordered/FILTER/arg_min-max cases, then lose on the DISTINCT-ordering edge or an integration panic. Passers did substantive re-architecture (dedup-after-sort in aggregate state). Like piccolo, all failures are MISSED-REQUIREMENT/REGRESSION/INTEGRATION traced to explicit prompt behavior, zero verifier mismatch, zero `agent_blame_unfair`. Confirms: a trap that lives in a repo-specific execution path (hash-distinct) is retry-resistant because the fix is re-architecture, not a point-fix.

---

## Diamond-Tier Cross-Cutting Behavior

Full Diamond rules → `DIAMOND.md`. Cross-cutting agent behavior:

- **Castor runs only** — 10+ required. **Pass-rate ceiling ≤30%** (1-3 of 10, post 2026-05-13 relaunch). Castor temporarily throttled to 25 tokens/run.
- **Diamond Checks preflight** (NEW 2026-05-13) — 50 tokens full pipeline (45 rollouts / 15 code validation / 20 full env QA), 30min-1hr. Replaces reviewer green-light. Stales on description / test patch / solution patch / dockerfile / repo+commit changes.
- **Auto Review issues "approved for QA" badge** — reviewer green-light gone.
- **Failure QA required** — human analysis of every test failure. AI-generated QA = immediate rejection.
- **Hints flow** — if Castor 0% → add hint → run 10x Castor (hinted) + Diamond Checks (hinted). Hint changes stale ONLY hinted Diamond Checks.
- **Smoke test before full Castor run** — 1x Castor or 1x Vega first to catch env blockers cheaply.
- **Vega for environment validation** — test infrastructure before spending Castor tokens.
- **Staleness model:** QA artifacts only stale if Castor staled. Can iterate QA artifacts safely with Final QA Review once at QA step. Air-tight submission BEFORE entering QA — issues remedied later cost much more time.
- **All feedback through Shipd** — Discord channels deprecated.

### Failure QA Formula (per test failure)
1. **Unfairness check:** cite prompt snippet → explain how test validates → cite codebase conventions
2. **Root cause:** pinpoint trajectory location → classify (assumption/oversight/wrong arch) → cite agent code

**Critical rule:** if QA reveals unfair test (ambiguous prompt, contradicts convention), MUST fix prompt/verifier and re-run. Do not paper over.

### Difficulty Implication (Post-2026-05-13)

Castor capability-growth curve (already strong per prior Diamond eval data) PLUS new ≤30% pass-rate ceiling means problems that previously landed at 3-5/10 (30-50%) now exceed the ceiling. **Default to tightening description proactively** per `lessons-learned.md § Tighten-First Rule` — Castor at current capability needs minimal+prescriptive descriptions for capability differentiation.

### High-Yield Diamond Shape: Path-Resolution + Reflect-Traversal + Checkpoint-Semantics

**Source:** yaegi-checkpoint-api (7% Castor pass, accepted Olympus 2026-05-26).

Three architectural axes combined in one feature surface produce stable Diamond-grade difficulty:

1. **Path-resolution axis** — package short-name reverse lookup (binPkg ↔ pkgNames), malformed-path rejection, canonical-form emission. Castor trap on EACH sub-axis independently.
2. **Reflect-traversal axis** — pointer-receiver methods via value paths (`v.Addr().MethodByName`), embedded-field promotion, addressable-leaf injection, ConvertibleTo type acceptance.
3. **Checkpoint-semantics axis** — deep-clone on snapshot, deep-clone on history append AND read, Restore-skips-Observer/History side effects, per-symbol Generation accounting.

Each axis admits 2+ natural implementations (direct vs reverse map; v.Method vs v.Addr().Method; alias vs deep-clone). Cross-axis interactions multiply trap-stack size without violating O-Composite-add shape.

**Use when:** target repo exposes runtime introspection (interpreters, debuggers, REPLs, hot-reload systems). Sample APIs: `Inspect/Inject/Snapshot/Restore/Observe/Track/Generation`. 18-API bundle is acceptable if all share infrastructure.

**Avoid when:** target subsystem has no addressable runtime state (compilers, parsers, formatters). The reflect-traversal axis collapses to "thin map wrapper" without a live interpreter frame.

---

## Difficulty Calibration Protocol

The fairness-vs-difficulty diagnostics tell you how to react to an eval; this section is the METHOD for predicting and tuning the pass rate before and between evals. It applies under the Olympus floors and the ~10% / ≥1-must-pass solve target (and the Diamond ≤30% = 1-3 of 10 Castor ceiling).

### Naive-Agent Benchmark (MANDATORY before submit)

Before the first eval, hand-write the obvious single-pass solution an agent would produce reading ONLY meta.md — the most direct architecture, no edge-case hardening. Swap it in for solution.patch and run test.patch. Treat the result as a coarse, cheap sanity signal that BOUNDS easiness — it tells you whether the naive shape is clearly too easy, not a precise prediction of the stochastic solve rate.

- **~70-85% naive pass = calibrated.** The naive solution fails ~15-30% of tests; that residual is your difficulty surface.
- **>85% pass = too easy.** Add discriminators (cross-cutting interaction tests, ordering gates, NO-OP-on-shape cases) until the naive solution drops into band.
- **<40% pass (including 0%) = tests are mis-aligned with the architecture an agent naturally takes.** Realign the tests to the natural surface; do NOT blame the agent or paper over with description detail. This is a 0%-trap signal, not difficulty.
- Keep the naive script OUTSIDE the deliverables folder (it is not one of the 5 files). Never commit it into `problems/{repo}-{issue}/`.

### Reading the Pass Rate Over a Small Sample

Solvability is judged over ~10 runs; do NOT over-react to a 4- or 5-run batch. For a true rate p, the chance of seeing ZERO passes in N runs is `(1-p)^N`. At the ~10% target: 0/4 = 0.9^4 = 66% (the single MOST LIKELY outcome), 0/5 = 59%, 0/10 = 35%. So 0/4 — even 0/5 — is NOT evidence of too-hard. Redesign only at ~0 of 10 FAIR runs; >2 of 10 passing (Olympus) or >3 of 10 (Diamond ceiling) = too easy.

- Before counting a fail toward difficulty, classify it: a `FAIL_TEST_MISMATCH` with `agent_blame_unfair=true` (an undocumented contract / compile mismatch) carries ZERO difficulty signal. Fix the unfairness; do not count that run toward the solve rate.
- A `FAIL_MISSED_REQUIREMENT` with `agent_blame_unfair=false` and `description_clear=true` on clearly-described behavior IS the legitimate difficulty — the kind of fail the band is made of.
- Near-miss scores (e.g. 34/38, 35/38) confirm GOOD calibration, not a defect: the agent reached the surface and missed the discriminator. Do not "fix" a near-miss by easing the discriminator.

### Message-Count Floor (solver-MEDIAN messages >100)

The MEDIAN message count across the SOLVING agents MUST exceed 100 — a HARD gate that sits ALONGSIDE the pass-rate ceiling and the ≥1-pass solvability floor. SCOPING: the platform considers the MEDIAN — across SOLVED (PASSED) runs ONLY — of message count, LOC, AND files; failed runs are EXCLUDED from all three. So read this floor off the agents that actually PASSED (a failing run at 60 or 300 msgs is irrelevant), and the gated figure is the MEDIAN of the solvers' message counts (companion long-horizon medians: files ≥3, LOC ~450+/400-auto-block). TARGET a solver-median COMFORTABLY above 100: with few solvers the median is fragile (solvers at 94+109 give a median of 101.5, barely clearing). Never author for a sub-100 median or bank on a lenient reviewer. (Does NOT apply to Mars — short single-subsystem features are expected.)

Message count is the platform's proxy for long-horizon / multi-subsystem SCOPE: a problem whose SOLVER-MEDIAN is <100 is a concentrated needle-trap, UNDER-SCOPED even when solvability, pass-rate, effective-LOC, and file-count all pass. If the solver-median is near 100, do NOT de-trap (that lifts solvability) and do NOT pad with repetitive breadth — add ANOTHER genuinely-independent subsystem (a second/third constructor, a cross-subsystem embedder/reflection layer, an orthogonal engineering surface), or pick a refactor/entangled-existing-code shape that forces real explore/debug cycles.

**DATA POINT (go-geom-de9im-predicates, APPROVED 2026-06-18):** a comprehensive multi-subsystem reference-engine problem was APPROVED with a SOLE solver at msgs=87 — solver-median 87, BELOW the nominal >100, with files=15 / LOC=2922, 1 PASS / 10 = 10%. The high companion medians and genuinely broad scope carried it on reviewer judgment. LESSON: the message-count floor is reviewer-JUDGED, not a hard auto-reject — a deep, broad, multi-subsystem problem CAN clear with a solver-median in the high-80s when files/LOC are high and the scope is genuine. NOT license to TARGET a sub-100 median (still author for >100 with margin); it bounds the downside.

### Deterministic-vs-Scattered Failure Diagnostic

Apply the fairness-vs-difficulty rule at test-NAME granularity, using eval-results.md's per-run failed-test column to cluster which named tests fail across runs:

- **Same tests every run** → 0%-trap contradiction to fix (re-read those named tests against meta.md and the reference solution).
- **Different tests across runs** → genuine difficulty; keep it.

A "same tests every run" cluster splits into two sub-cases, fixed differently:

- **A contradiction bug** — meta.md, a test, or the reference solution disagree. Re-read and reconcile; the requirement was never coherently stated. SPECIAL CASE (engine-consistency): when the spec says "format X like the language's own str/repr", the hidden test MUST match the REPO's existing str/repr, NOT a foreign oracle's (a CPython-threshold float repr rejected agents who correctly reused the engine's own shortest-g repr → inconsistent AND unwinnable). Fix: delegate to the engine's OWN renderer; reserve the foreign oracle only for behaviors the engine does not already define.
- **A deterministic universal MISS** — every FAIR run misses the SAME clearly-described requirement because agents implement only the OBVIOUS members of a behavior family and miss the rest. The contract is coherent; agents just never discover the full reach. This is a 0%-trap on the absolute floor even though each fail is individually fair. De-trap by DISCOVERABILITY: make the reach explicit in meta.md (state that the requirement spans the WHOLE family, not only its obvious members) — a fair clarification of already-tested behavior, NOT difficulty-easing and NOT a new requirement. The implementation work and the SCATTERED difficulties stay untouched.

### The Strongest-Agent Diagnostic (read 0/N batches through the best run, not the aggregate)

At 0/N with all-FAIR fails, do NOT conclude "too hard" or "bad luck" (0.9^6 = 53% for a true 10%) and do NOT blindly redesign. Read the STRONGEST agent's EXACT per-test failures: if the best run solved nearly everything and its ONLY misses are a small concentrated set of surfaces, THOSE surfaces are the 0%-trap — de-trap EXACTLY them (clarify, or fix a genuine engine-inconsistency bug among them) and that agent passes, while the scattered difficulty the weaker agents miss is untouched. A single hard-but-solvable numeric edge can carry the whole ~10% rate.

### One-Lever-Per-Iteration

Change exactly ONE difficulty lever per eval round — add a single discriminator test, tighten one spec clause, or remove one fairness crutch — and log that single change in feedback.md's attempt-history row. The good pass-rate band is roughly one run wide on each side, so two simultaneous changes make the movement unattributable and waste a full eval.

### Trajectory-Guided Tuning

Read the transcripts in eval-results.md, do not just count passes:

- Add friction at the exact step where the agent took a shortcut (e.g. it reused a default setup path — make the convenience path differ from the default).
- Ease the specific field where it got stuck for a fairness reason (name the type, the file, the exact output format) — without loosening any other lever.
- Diff a passing transcript against a failing one to isolate the single discriminator that separates them; that line is your real difficulty driver.

### Preserve One Fair Edge on a 0% Task

If agents consistently miss exactly ONE documented behavior and the task is at 0%, make that behavior explicit in meta.md (fairness — no hidden requirements) while KEEPING it as the hard discriminator. Do not gut the rest of the suite to "make room": a stripped suite collapses straight to too-easy. Solvability is still absolute — a persistent 0% after this is a REDESIGN for Mars/Olympus (hints removed April 2026), or the HINT flow for Diamond, never a bypass.

---

## Reference-Engine + Oracle Pattern

The most reusable structural insight from an approval: the quickest path to a clean, large, fair, oracle-verified problem is to implement a **comprehensive standard feature family on a repo's under-implemented reference engine** (executor/interpreter/evaluator — NOT the optimizer), and validate every expected value against a **mature external oracle**.

- **Why it clears the gates at once**: a reference engine is deliberately incomplete, so a missing standard family is a genuine gap (no existing PR), cross-pipeline, and naturally clears the effective-LOC floor (≥450 design / 400 auto-block); the breadth yields 30-45 clean exact-output tests; the oracle eliminates `FAIL_TEST_MISMATCH` (the #1 revert cause).
- **Oracle technique**: generate the hidden tests' expected values FROM the oracle and FUZZ the reference solution against the oracle over 100s of randomized cases before submitting.
- **Solvability calibration**: a local solvability sim is an UPPER bound on easiness (best-case agents with full spec + oracle + unlimited iteration). 3/3 sim passes means the gate is MET (≥1 pass), not that the problem is too easy. The platform's averaged rate is lower; "solvable but laborious + comprehensive" lands fine. Do not halt on a passing sim.
- **Concision vs alignment is a structural tension for API-heavy specs**: the "necessary information" check escalates over-detail to HIGH and demands deleting the per-function semantics paragraph; doing so creates hidden requirements (a HARD reject). Keep the non-inferable canonical forms, trim only filler, and BYPASS the residual HIGH (non-solvability checks are bypassable).
- **LOC reality check**: a clean single optimizer/transform rule in a mature, well-factored repo is ~150-300 meaningful LOC — under the floor. Measure the hardest 2-3 files in a dev container before committing; pivot to a reference-engine family if under floor rather than padding one rule.

---

## Cross-Refs

| Topic | File |
|---|---|
| What Olympus is + 5 deliverables + repo reqs + tier matrix | `../CLAUDE.md` |
| 14-section DESIGN doc | `WORKFLOW.md § Step 1` + `olympus-author` skill |
| Description rules + word caps + blind-spot pre-empts | `DESCRIPTION.md` |
| Test rules + 4-block layout + JUnit XML by language | `TESTS.md` |
| Solution rules + helper extraction + fixpoint loops | `SOLUTION.md` |
| Dockerfile patterns A/B + slim images | `DOCKER.md` |
| Patch generation (BASE_COMMIT diff, UTF-8/LF, mode 100755) | `../CLAUDE.md` + `patch_gen.py` |
| End-to-end workflow | `WORKFLOW.md` |
| Shape taxonomy (12 shapes) | `SHAPES.md` |
| Evidence-based patterns (Patterns 1-16) | `PLAYBOOK.md` |
| Advanced patterns (Patterns 17-33: namespace, triviality, post-base) | `PATTERNS-ADVANCED.md` |
| 21-item review checklist + hard rejects + revert causes | `RULES.md` |
| Per-problem deep dives (behavioral data + iteration lessons) | `PROBLEM-PROFILES.md` |
| Cross-cutting iteration lessons (description/tests/patches/reviewer/Solution/Language/Submission/Diamond) | `lessons-learned.md` |
| Diamond-tier full rules + Failure QA formula | `DIAMOND.md` |
| **Evidence-based Diamond design + iteration discipline** (8 trap categories, LOC/word bands, cost model) | `DIAMOND-PLAYBOOK.md` |
| Common author mistakes + agent failure patterns | `olympus-common-mistakes.md` |
| Anti-agent design patterns + difficulty tuning | `olympus-extreme-complexity-guide.md` |
| Auto-reviewer pipeline + pre-submit hardening | `AUTO-REVIEWER.md` |
| 10 reusable agent prompts + GitHub CLI | `PROMPTS.md` |
| Reusable agent prompts (Mars/Olympus/Diamond/Lite/tier-agnostic) | `PROMPTS.md` |

### yaegi-channel-diagnostics (Diamond, approved 2026-05-31)

Castor on a channel-diagnostics + interpreted-deadlock facility over *interp.Interpreter (channel-op + goroutine-spawn instrumentation). Unhinted 0/10, hinted 1/10 (10%, within <=30%). Confirmed Castor traps, by hit rate across the 20 runs:
- False-deadlock debounce (DOMINANT, ~14/20): agents declare deadlock synchronously the instant blocked==active, with no grace-period re-check. The reference arms a ~50ms watchdog that re-confirms the same blocked set before latching. Both manifestations come from one one-shot latch: a false positive on a rendezvous / producer-consumer handoff, AND a one-op report on a genuine multi-goroutine deadlock (the latch freezes the first partial blocked set and never recomputes).
- For-range receive miss (7/10 unhinted): agents instrument recv/recv2/send/_close/_select but miss the separate rangeChan closure, so `for v := range ch` receives go uncounted. This was the hint target (subtle, named only Go syntax) and moved every hinted agent past it onto the hard parts.
- Deferred-close goID 0: a deferred close runs through genBuiltinDeferWrapper with no frame; agents record goID 0 instead of capturing f.goID at defer registration.
- Destructive select-readiness probe: a reflect.Select with an added default that CONSUMES a ready value, then the real select hangs -> 3-minute timeout that takes the whole binary down (collateral "missing from JUnit XML" on the other tests in the run).
- Multi-goroutine spawn-path tracking: missing one of the three go-spawn sites -> nil report / undercount.

Diamond cross-cutting reinforced: the observability-API-over-deep-runtime-subsystem shape works (difficulty from every-emit-site coverage + block-ordering + goroutine accounting, not from API surface). The load-bearing trap (debounce) is one most agents do not even know they need until they hit the false positive.

### yaegi-methodset-enforcement (Diamond, approved 2026-06-23)

Castor on compile-time method-set / selector / addressability spec-conformance over the yaegi static checker (cfg/typecheck/type + new methodset.go). Hinted 2/10 (~20%, within <=30%). Confirmed Castor traps, recurrence-ranked across the 12 runs:

- **Satisfaction skips interface-typed sources + comparisons (most runs):** agents add the method-set check only for a CONCRETE source assigned to an interface; an interface-typed source and the `==` comparison path stay on lenient `assignableTo`. Misdirecting: the failing assert is on iface-to-iface assignment, not the concrete case they fixed.
- **Shallowest-wins not implemented in RUNTIME lookup (near-universal):** agents add an ambiguity DIAGNOSTIC but leave `lookupField`/`lookupMethod2` depth-first, so the deeper-declared-first member is still SELECTED. Detecting ambiguity != changing which member wins. Strong biter -- reads as "done" until a stdout-value test catches the wrong member.
- **Ambiguity not fed into interface satisfaction:** an ambiguously-promoted method is excluded from the method set, but agents check satisfaction via the method map without consulting the ambiguity walk -> ambiguous M counted as present.
- **struct-embeds-2-interfaces vs interface-embeds-2-interfaces (over-reject twin):** agents apply struct-style ambiguity counting to an interface root, rejecting the legal interface-merge (identical embedded methods coalesce since Go 1.14). The accept twin is the trap.
- **Diamond dedup by type identity:** the embedding walk uses `seen[*itype]`, collapsing a type reached via two anonymous paths to one candidate -> diamond ambiguity missed. Reference walks by embedding PATH.
- **Comparison error-SELECTION (run 5):** the comparison DID reject but surfaced the raw satisfaction error (`main.T does not implement main.I (wrong type for method M)`) instead of the required `mismatched types`. Reject-with-wrong-wording, NOT got-none -- distinct from the skip above; the SAME test fails differently across runs (run 11 got-none).
- **Addressability carve-outs:** array-LITERAL index treated addressable (`&[3]int{...}[0]` should reject; only a composite-lit DIRECTLY under `&` is addressable); pointer-valued map-element field-write wrongly rejected (a pointer deref re-addressabilizes); nested map-element write (`m["a"].in.x`) missed when the check only inspects the immediate selector.
- **io.Writer reflect-backed signature deferred to runtime:** pure-bin / reflect interface methods skip the static full-signature compare -> a wrong-signature Write is accepted statically and fails later inside reflect.Set.

Note: a clean platform auto-grader is NOT a substitute for human Describe-Tests review (see lessons-learned yaegi-methodset entry) -- and a PASS Castor run can hide an untested spec bug (array-literal slice here).

## typify-object-applicators (APPROVED Diamond 2026-06-25) - Castor profile

- CASTOR BLIND SPOT (10/10): REPRESENTATION SPLIT. Castor wires a new validation through one of two co-equal generated representations (the named-field struct) and leaves the other (map/newtype) plus the unnamed-root-key edge untouched. 8/10 missed map-shaped property-count enforcement (`make_map` carries no length check); 10/10 panicked generating a root pattern-only / propertyNames-only object (`make_map(type_name.into_option())` drops the title -> key newtype is `Name::Unknown` -> `get_type_name(...).unwrap()` panics). Two near-miss runs hit 20/22 failing ONLY the root-map generation.
- PER-AGENT VARIATION on the SAME failing test: `differing_pattern_values` failed three different ways across agents - `invalid type: string, expected i64` (took first pattern's value schema), `unknown field n_two` (built no overflow map when patterns disagree), and was SOLVED via a permissive `Schema::Bool(true)` fallback (which over-accepts). Lesson: read EACH run's diff + log; never reuse one root-cause/Actual across agents.

## starlark-rust-set-literals (APPROVED Mars 2026-06-25) -- Agent behavior

- SATURATED FEATURE = uniform feature-pass: all 13 rollouts (Nova + Orion) passed all 46 behavioral feature tests; every test group 10/10, including the designed brace-disambiguation and dedup "traps". A pure-sugar language feature is trivial for frontier agents -- no feature-level trap survives.
- SHARED BLIND SPOT = baseline golden maintenance after a syntax/opcode change. 100% (13/13) missed regenerating the bytecode opcode-profile golden; 90% (10/13... ) left the obsoleted parse-fail grammar golden. Agents run focused new tests + `cargo check` and skip the full baseline suite.
- DISCRIMINATOR = long-horizon thoroughness. The single passing run (Orion) was the one that ran the full suite and fixed both goldens. Confirms: for a saturated feature, the only thing separating pass from fail is whether the agent validates exhaustively, not feature understanding.

## piccolo-finalizers-gc (APPROVED Mars 2026-07-04, 30% Nova 3/10 all-fair) -- Nova GC blind spots

Lua 5.4 GC subsystem (weak `__mode` k/v/kv + ephemeron fixpoint + `collectgarbage` option set + `__gc` finalizers with resurrection / reverse-order / once-each). 72 behavioral tests. R7 10-run Nova batch: 3 PASS / 7 FAIL = 30% (at Mars cap). All fails FAIL_MISSED_REQUIREMENT, fair, deterministic. Recurrence-ranked Nova blind spots (the working traps):

- **(A, 5/7) Resurrection re-feed NOT propagated to the ephemeron fixpoint after finalizers run.** THE dominant blind spot. Agents run ephemeron convergence BEFORE queuing/running finalizers, then sweep weak tables with NO further convergence -- so values reachable only through a resurrected finalizable (or weak-key entries inserted by a `__gc` body) get cleared. MISDIRECTING: surfaces as a `gc_arena` `assertion failed: header.is_live()` panic deep in the arena, not as a visible wrong-output near the GC-ordering code. Tests: `resurrection_feeds_two_level_ephemeron`, `resurrection_feeds_deep_chain` (the deep variant kills BOUNDED re-feed -- agents who re-mark a fixed 1-2 levels after resurrection but not to a fixpoint), `finalizer_inserts_weak_key_entry`, `ephemeron_key_resurrected_by_its_finalizer`.
- **(B, 3/7) collectgarbage multi-arg consume bug.** `Stack::consume::<Option<String>>()` drains the WHOLE stack (`self.drain(..)`), so a sequential `consume::<Option<i64>>()` for the second arg reads nothing -> `setpause`/`setstepmul` return the wrong previous value. REPO-SPECIFIC API footgun (inferable: read `Stack::consume`). INDEPENDENT of the GC-marking axis. Tests: `setpause_returns_previous`, `setstepmul_returns_previous`, `pacing_persists_across_stop_restart`. The correct read is one tuple consume `consume::<(Option<String>, Option<i64>)>()`.
- **(C, 1/7 SOLELY) Once-each broken across resurrect-then-redrop.** Agent resurrects EVERY dead registered table during finalize without checking `has_pending_finalizer` first, so a finalized-then-dropped object is re-resurrected on the next collection and its weak entries wrongly persist. Fix = remove from the finalizable registry once scheduled. INDEPENDENT. Tests: `resurrected_then_dropped_collects_next_cycle`, `multicycle_resurrect_then_drop_ephemeron`.
- **(D, 1/7) Reverse-install-order lost.** Vector removal / stack pop does not preserve reverse-of-`__gc`-install order in all cases. Tests: `finalizers_run_in_reverse_install_order_three`, `reverse_order_with_one_resurrection`.
- **(E, 1/7) `kv` treated as ephemeron.** Agent calls `resurrect_ephemerons` for `WeakMode::KeysAndValues`, so a dead weak VALUE survives because its key is live -- but in `kv` both sides are weak (no ephemeron). Tests: `weak_kv_dead_value_clears`, `kv_value_only_reachable_via_table_clears`.

⭐⭐ THE STRUCTURAL LESSON: this feature was BIMODAL (~50% pass) at R5/R6 because the tests OVER-CONCENTRATED on axis A (resurrection-ephemeron). It fell to the 30% cap at R7 only when tests SPREAD across the 5 INDEPENDENT axes (A-E), so no single agent nails all of them. Single-subsystem GC-correctness is NOT a pure uniform-wrap if the subsystem has 5+ genuinely-orthogonal sub-behaviors -- the lever is STACK ORTHOGONAL FAIR WALLS, not deepen one. See `lessons-learned.md` (same problem) for the generalized rule.

## nickel-1336 dict catch-all (OLYMPUS, cross-crate Rust -- SOLVED 1/10 2026-07-03) -- Nova vs Orion on a DUAL-AST feature

Measured over 4 real 10-14-run batches (Nova + Orion + Vega, Nova evaluator). Cross-subsystem Rust (parser crate + core crate, dual `TypeF::Dict`, LALRPOP-generated grammar, 21-file reference).

- **Nova (fast: 20-32 min, 200-300 msgs, 380-600 LOC) DIES AT CROSS-CRATE INTEGRATION, almost never reaches semantics.** On a dual-AST feature Nova consistently: (a) adds the new grammar as a record-FIELD production -> LALRPOP local ambiguity with existing `{ _ : T }`/`{ _ | T }` (build fails); (b) adds a field to a shared struct (`Record.catch_alls`) and MISSES initializer sites in other files (E0063 missing-field); (c) uses a type without importing it (`TermPos`/`fixpoint`/`CatchAll` -> E0432/E0433); (d) threads owned-vs-`&` wrong through generated code (E0308); (e) calls a trait method not impl'd for a container (`Vec<Field>::revert_closurize` E0599). CONFIRMED Nova blind spot: **add-a-struct-field / touch-a-generated-grammar and ship without compiling.** Nova commits early and does not deep-self-validate (the solve-env cargo block made this worse). 9-10 of every batch were Nova COMPILE deaths.
- **Orion (decisive: 48-75 min, 500-700 msgs, 600-1133 LOC) is the ONLY agent that carries a 21-file cross-crate implementation to a clean pass.** The lone PASS_LEGITIMATE was Orion (1133 LOC / 573 msgs / 65 min, 873/873 base + 26/26 new). Orion also produced the strongest near-misses (baseline-pass + 15-26/26 new). Orion's residual fails were SEMANTIC (propagation gaps, baseline regressions), not compile -- the opposite of Nova. On a heavy cross-subsystem Olympus, Orion is the agent that defines solvability; Nova mostly measures the integration floor.
- **Vega:** mixed / partial (16-26 new, some syntax errors); did not distinguish from Orion here.
- **Cross-agent (Nova~=Orion~=Vega family) blind spots CONFIRMED on this pick:** (1) freeze-drops-pending-state misdirection -- `std.record.insert` freezes first, so the catch-all is lost before insert; the failing insert test surfaces as `NotAFunc` far from the freeze site. (2) metadata-as-materialized-field -- `is_empty()` counts the new slot; breaks emptiness/equality. (3) shared-struct-representation leaks into existing observers (pretty/label/dedup) -> baseline regression even when the new feature is 100% correct. (4) apply-at-application-time-only -- static fields pass, dynamic/merge fields (separate eval sites) silently escape.
- **ENV note:** `/opt/cargo/registry` root-owned perms blocked EVERY run's `cargo check`/`cargo test` (agents solved blind) + a few Orion `exit_code=-1` API-auth deaths. Both suppress pass-rate independent of difficulty; flag for Rust picks.

## nickel-enum-widening -- Nova blind spots (APPROVED Mars 2026-07-04, R3 30% 3/10)

Single-subsystem Rust typecheck subsumption (`subtyping.rs`), enum + function width subtyping. Nova evaluator, 10-run batch.

- **Nova solves the FEATURE, fails the BASELINE-MAINTENANCE (reverse of the nickel-1336 profile).** All 10 rollouts passed the 17 hidden new-behavior tests; the 30% pass rate came entirely from surrounding integration chores. Confirmed Nova blind spots on a behavior-CHANGING typecheck feature: (1) **stale-golden** -- 5/10 left or wrongly updated an existing type-error golden whose diagnostic changed (MissingRow->ExtraRow); (2) **stale executable-doc** -- 4/10 never updated the manual doc-snippet that now evaluates instead of erroring; (3) **over-generalization** -- 2/10 added the new function-subtyping rule then over-applied it, flipping an unrelated negative golden (`mismatch_enum_match_fun_type`) to `pass` when it still correctly errors `ArrowTypeMismatch`. Even with the meta warning "existing type-error expectations and documentation examples may need updating; validate against the full suite," ~half of Nova never ran the full baseline.
- **Nova does NOT run the full baseline when it can't build offline.** Same `/opt/cargo/registry` perm/network friction -- Nova validated only the focused new tests (or nothing) and shipped without discovering baseline reds. Env drag suppresses pass-rate but the grader rules it fair (the maintenance requirement was visible + warned).

## gimli-type-units (APPROVED Mars 2026-07-05) -- Nova blind spot: generalizing a section-wrapper-typed fn to a generic writer

Confirmed across 2 batches (40 Nova runs total): when the reference solution refactors a widely-called helper from a concrete section-newtype (`&mut DebugInfo<W>`) to a raw generic writer (`&mut W`), Nova reliably FAILS TO COMPILE the same refactor. 14/20 (v4b) + 13/20 (v4) integration-error verdicts, all in the modified writer code:
- leaves `w.0` / `w.offset()` calls that only exist on the newtype wrapper, not on generic `W: Writer` (`E0609`/`E0599`)
- returns incompatible concrete types from an `if`/`match` (`&mut DebugInfo<W>` vs `&mut DebugTypes<W>`) -> `E0308`
- removes/omits a trait import the `define_section!` macro expansion needs (`Section`, `Deref`) -> `E0405`
- second mutable borrow of a sibling `sections.*_fixups` field while a conditional section-writer borrow is live -> `E0502`
- type-inference gaps in dedup collections (`FnvIndexSet`/`FnvIndexMap::default()` unannotated) -> `E0282`

Cross-agent: this is a same-family blind spot -- the invasive-shared-machinery refactor is the wall, and it's amplified when the solve env blocks `cargo check` (the platform's root-owned `/opt/cargo` registry `Permission denied` on `fnv` appeared in nearly every run) so agents submit un-compiled code. Grader consistently rules this env friction non-blocking / `agent_blame_unfair: false` (same as nickel-1336), so it is NOT a reject risk. Confirmed regression trap on the same feature: 3-4/20 pass the new tests but REGRESS the existing `test_die_ranges_high_pc` by computing `low_pc + high_pc_length` with a checked/overflowing add (existing behavior DROPS the overflowing range; the naive aranges path panics or returns `InvalidRange`). Reference sidesteps it by storing the length form directly / `wrapping_sub` on the end form.

## nickel-array-rest (APPROVED Mars 2026-07-05, 6/20 = 30% Nova all-fair) -- Nova blind spots on a grammar-touching cross-crate feature

20x Nova unhinted, 6 PASS_LEGITIMATE. The 14 failures cluster into 4 recurrence-ranked blind spots (all agent-introduced, agent_blame_unfair false everywhere):
- **[6/20 -- TOP] LALRPOP error-conversion in a `=>?` action.** Agents add their own multiple-rest / duplicate rejection returning the crate's `ParseError` directly and hit E0308: the generated grammar expects `lalrpop_util::ParseError<usize, Token, ParseOrLexError>`. They miss the `lalrpop_util::ParseError::from(...)` / `.into()` wrap that the reference (and nearby existing actions) use. This is the integration wall UNDER the semantics; on any grammar-touching Rust feature, expect this to be the dominant Nova failure.
- **[2/20] Self-shaped grammar production -> LALRPOP local ambiguity -> build-script panic.** Agents write a second `ArrayPattern` alternative or a fresh `PatternList`/`<_: ",">` instead of reusing the existing item nonterminal; the parser crate never builds. Nova does not reliably find the minimal LR(1)-safe reshape (reuse `(<LastElemPat> ",")*`).
- **[3/20] Rust borrow/move/scope errors in the AST + dup-check threading.** E0507 (move out of `enum_pat.pattern` behind `&`), E0382 (borrow of moved `tail` after `ArrayPattern { tail, .. }`), E0412 (`Pattern` not in scope in utils.rs) + calling an unimplemented `bindings()`. Nova under-validates the borrow checker when it cannot run `cargo check`.
- **[3/20] Agent-added integration FIXTURES break the baseline.** #3 shipped a `.ncl` asserting the outer-rest middle capture is `["b","c"]` when the from-tail slice semantics give `[["b","c"]]` (a Wall-2 misread). #8/#9 wrote malformed annotated-test TOML (`# test.type = 'error` unterminated; `error`/`ident` under `[test.metadata]` instead of `[test.metadata.expectation]`). Lesson: Nova adds its own regression fixtures and gets the nickel annotated-test TOML shape or the middle-capture value wrong.

Cross-cutting: the passers (6) all reached the semantics correctly; the failers mostly died BEFORE the semantics (compile/build/fixture). This is the same "compile-floor under the semantics" signature as nickel-1336, but here the floor is the lalrpop error-conversion + grammar-ambiguity rather than the dual-AST field threading. ENV caveat: `/opt/cargo` `Permission denied` + crates.io 403 blocked Nova's own `cargo check` in nearly every run (grader-excused) -- so several compile-error failures are ones Nova could NOT self-catch, meaning a clean env might raise the pass rate (mild too-easy watch if re-batched).

## Nova/Orion blind spots -- confirmed on parry-heightfield-point-projection (ACCEPTED Mars 2026-07-05, 3/10)

- NAIVE-DOMINANT-READING (bilinear surface height): asked for "the height of the surface", agents default to BILINEAR interpolation over the 4 cell corners -- the standard game-terrain assumption -- instead of the shape's ACTUAL triangulated geometry. Fair because the surface IS a triangle mesh everywhere else in the lib; bilinear is close-but-wrong on non-coplanar cells. A high-rate miss; the primary hardening lever. Pre-empt: do NOT name the algorithm; test on a non-coplanar cell + off-diagonal point (a planar test cannot catch it).
- SOLID-GATED is_inside NOT PROPAGATED (shared blind spot, 3/10): agents implement `proj.is_inside = solid && <below-surface>` and then call the location/feature helper with `solid = false`, so a below-surface feature/location projection reports is_inside=false -- violating an EXPLICIT description rule. Misdirecting: the failing assertion is `proj.is_inside` on the feature path, cause is the `solid` gate on a shared helper.
- TYPE-CONTRACT DRIFT WHEN RE-DERIVING (usize->u32, 3/10): when a needed id-mapping helper is private, agents re-derive it and, matching a nearby pub signature (`triangle_at_id(id: u32)`), change the `PointQueryWithLocation::Location` id from the base's `usize` to `u32`, breaking the associated-type contract the tests pin. Also `FeatureId` vs raw `u32` for a shape face (1/10). Emergent from de-crutching; a free fair integration trap (usize is the base's declared type).

## Nova blind spots -- confirmed on aircompressor-zstd-strategies (ACCEPTED Mars 2026-07-06, 1/10 = 10%)

Zstd block-compressor strategies. Blind spots recurrence-ranked across the 10-run R2 batch:
- ★ UNIVERSAL ALIASING (10/10): agents collapse all 7 strategies (fast/greedy/lazy/lazy2/btlazy2/btopt/btultra) to ONE parameterized hash-chain; NOT ONE builds a binary tree or an optimal parser. This is LEGITIMATE and universal -- a single correct hash-chain satisfies round-trip + ratio + monotonicity, so no fair test forbids it. Do NOT design a problem whose difficulty depends on distinct architectures (the reference's btopt/btultra were pure LOC dead-weight difficulty-wise).
- ★ RATIO MISS (beat-double-fast) -- DOMINANT biter (5/10): a quick/weak greedy, or btlazy2/btopt/btultra wired to the same lazy2 hash-chain, does NOT beat double-fast on the real corpora (progc/html/geo) and breaks the higher<=lower monotonicity. The single most reliable Nova wall on this feature -- a CORRECTNESS-of-compression gap, not an exotic edge case. Escapable ONLY by a recursive recompress-fallback (try level-1, pick smaller); only 1/10 found it.
- STREAMING writeChunk INVARIANT (3/10): adding the level-aware `ZstdOutputStream(out,int)` ctor, agents rebalance `maxBufferSize` and break the base `checkState(chunkSize > blockSize, "Must write at least one full block")` guard -> IllegalStateException on multi-MB cross-window inputs. A DIFFERENT streaming wall than window-sliding-corruption, which does NOT bite (competent hash-chains already guard windowLow -- measured on the passers' diffs, loro-risk realized).
- SEQUENCE-ENCODER CROSS-FILE GATE (1/10 primary): agents wire the strategies but miss lifting the SequenceEncoder LAZY+ `not yet implemented` throw (a DIFFERENT file) -> UnsupportedOperationException for levels >= LAZY.
- Cross-cutting: the failers died on COMPRESSION-CORRECTNESS (ratio/monotonicity) and STREAMING-INVARIANT, not on exotic hidden requirements -- difficulty came from BREADTH of fair walls the aliased solution must ALL satisfy. See PATTERNS-ADVANCED Pattern 69 + PROBLEM-PROFILES aircompressor-zstd-strategies.

## kcl-union-override-typecheck (APPROVED Mars 2026-07-07) -- Nova/Orion reuse-the-machinery blind spot
Confirmed cross-agent trap on a "type-check overrides recursively" feature. Agents (Nova + Orion) overwhelmingly patch walk_binary_expr (node.rs) + reuse check_config_value_recursively (config.rs), and NEVER touch calculation.rs binary(). This reuse is correct for Dict/Schema nesting but the existing helper has NO TypeKind::List arm, so agents SILENTLY MISS (recurrence-ranked across 11 fails): (1) schema-typed list elements [Server] and nested lists [[Server]] -- dominant; (2) `**` spread when the operand is an identifier dict variable (they only handle inline `{...}` literals); (3) schema-instance RHS `_a | _b` (they skip when the RHS already resolves to a schema type); (4) annotated-target double-report (their walk_binary_expr check fires again on top of the assignment annotation's check). Blind spot #4 is the interdependence: naive proactive checking + the existing annotation path = 2 diagnostics. The one passer added the List+Union arm AND guarded the double-report. Also: agents route compound `|=` through walk_aug_assign_stmt but forget it, because their check lives in walk_binary_expr -- `|=` is the form the reuse structurally can't reach.

## stoolap-comparison-consistency (APPROVED Mars 2026-07-07, 1/10=10%) -- Nova blind spots (join-hash bucketing dominant)

10-run Nova batch on the accepted 33-test artifact, recurrence-ranked (all fair, agent_blame_unfair=false, "challenging"):

| Blind spot | Biters | Symptom | Why it bites |
|---|---|---|---|
| **join-hash bucketing** | 7/10 (runs 1,2,3,6,7,8,10) | int/text JOIN returns 0 rows while scalar `7='7'` is true | Nova fixes scalar equality + `values_equal` but leaves the type-discriminated hash + single-int fast path in hash_table.rs/utils.rs -> coerced-equal keys land in different buckets and never reach the equality check. INTERDEPENDENT+MISDIRECTING: symptom points at "equality", cause is hashing. Fixing `values_equal` alone is INERT. |
| **IN / set-membership optimized path** | 2-3 | `1 IN ('1','2')` false, IN-with-NULL not TRUE on coerced match | agent fixes a text-fallback but the hashed/`set.contains` list path bypasses coerced equality |
| **broad-refactor baseline regression** | 2 (runs 4,9) | broke base `NOT BETWEEN`; own added regression test failed | over-broad comparison refactor regresses pre-existing filter/ordering behavior -- the shared-comparator change (`compare_values`) has real ORDER BY/BETWEEN blast radius |

Confirms: for a "consistency across every path" feature, the DOMINANT Nova wall is the optimized JOIN path (separate hash/equality helpers), and the SECONDARY risk is that Nova's broad refactor regresses base. The single PASS (run 5) changed all 4 solution files. Nova that changes only value.rs+vm.rs (run 10, 3 files) fails the whole join cluster. Speed correlated with failure (fast runs miss the join helpers). Env note: every run cites the /opt/cargo permission blocker (agents cannot self-validate) -- grader consistently rules agent_blame_unfair=false and attributes the failure to the implementation gap.

## Nova/Orion blind spot — TYPE-EQUALITY-GATE vs CONST-EVAL (numbat-const-exponents, APPROVED Mars 2026-07-09, killed 5/11)

- **Type-gate mis-rejects polymorphic-arithmetic constants.** When recording which `let` bindings are compile-time constants, agents gate on `type_deduced == Type::scalar()` (looks correct: "exponents must be dimensionless scalars"). A polymorphic-zero binary subtraction (`let e = 0 - 2`, `let neg = 0 - 1/2`, `let negn = 0 - n`) does NOT deduce to exact `Scalar`, so it is DROPPED and the name later rejects as a "variable" exponent. Crucially agents PASS the unary form `-1/2` (deduces cleanly) but FAIL the subtraction form `0 - 2` — the discriminator. The robust solution does NOT type-gate; it tries `evaluate_const_expr` (folds `0-2`=-2 exactly). General lever: a spec allowing "expressions built from constants" where the obvious type-equality gate mis-rejects a foreseeable arithmetic form; pair a passing unary-minus with a failing subtraction-to-negative. FAIR (inferable from "expression built from such constants ... dimensionless number kept exact"); reliably bites Nova/Orion on a Mars rate gate.
- **Name-keyed const map not cleared on rebind/shadow (over-open leak).** Agents also leave a stale const entry when a name is rebound to a non-const or shadowed by a param/`where`-binding, so a runtime value of that name is wrongly accepted as an exponent (`let n=3; fn f(n)=meter^n` compiles). Confirmed 2/11. Weaponize with a combined test: positive const works + negative shadow/rebind rejected.

## Nova/Orion blind spot — RUNTIME shipped, STATIC ANALYZER missed (zen-hit-policies, APPROVED Olympus 2026-07-09, dominant across 11 fails)

- **When a feature must be handled at RUNTIME on one execution path AND via STATIC ANALYSIS on another, agents implement both runtimes and miss the analyzer.** zen has a graph decision-table evaluator (runtime `match` on the hit-policy enum — exhaustive, compiler-FORCES new variants) and a policy-workspace evaluator with a SEPARATE static analysis pass that emits diagnostics + infers output types. Agents ship the graph runtime + the policy runtime (exact-Decimal reduction, priority ranking, no-match handling) and pass 37-42 of 44 tests, but do NOT extend the policy `analyze` pass. The two consistently-missed obligations: (a) emit a `TypeMismatch` diagnostic when a numeric-aggregate/priority output cell is STATICALLY non-numeric (a string literal) — checked via `PolicyWorkspace::diagnostics`, not runtime; (b) resolve the aggregate output TYPE (Number for sum/count; Nullable(Number) for min/max/avg/median/priority) — checked via `ws.outputs(...).resolved_type`.
- **Why it misdirects:** the failing assertions read as "expected a diagnostic, got none" / "expected Number, got number?" — i.e. "my diagnostic/type is slightly off," NOT "I never touched the analyzer." The compiler only forces the GRAPH match arm (exhaustive enum); the policy path uses a `== Collect` equality comparison that silently treats unknown variants as first-match, so nothing points the agent at the second evaluator OR its analyzer. Confirmed: even the single PASS was Orion (decisive commit-and-implement across both paths + analyzer); Nova ships the runtime fast and terminates before finding the analyzer.
- **Secondary correlated miss — static-vs-runtime NULL type.** A value that the runtime writes as null on no-match (min/max/avg/median/priority) but the analyzer types as non-null `Number` is a real bug agents reproduce (they force `Number` for every numeric aggregate). Weaponize with a `ws.outputs` type assertion (Nullable(_)) alongside the runtime null-write test — the pair catches solutions that only did the runtime half.
- **Also confirmed here — per-column drop on sparse rows.** A shared row-evaluator returning None on a missing OUTPUT key discards the row for ALL columns; agents miss this in the graph path even after handling it in the policy path (Run #8/#11 died only on the two graph sparse tests). General lever for a multi-hit / per-column feature: a sparse row (one output cell absent) asserting each column reduces independently.

## Nova blind spot — from-scratch multi-behavior solver: full impls PASS, partial impls break at COMPOSITION seams (scryer-clpq-linear, APPROVED Mars 2026-07-09, dominant across 7 fails)

- **On a from-scratch engine ("implement a correct CLP(Q) / type checker / evaluator"), Nova is BIMODAL: full implementations PASS (scryer clpq: 853/629/537 LOC, real relinearization + attributed-variable re-entrant fixpoint), partial ones FAIL — and the fails cluster at COMPOSITION seams, not at any single behavior.** Two recurrent partial-impl signatures: (a) the delayed-nonlinear bucket is a NO-OP that only relinearizes on a coincidental later repost, so a product `X*Y` never wakes when X becomes determined via IMPLICIT equality (opposing bounds) or var-var MERGE rather than an explicit `X = n` unification (fails `nl_via_bounds`/`merge_nl`); (b) `rdiv` is parsed only when the WHOLE term is ground, so `N rdiv 2` (variable numerator / numeric denominator) is misclassified nonlinear instead of scaled by `1 rdiv 2` (fails `rat_divisor`).
- **The weaponization (general lever):** for any "delayed obligation activated on determination" feature, force determination through EVERY channel and require the obligation to fire off each — explicit unification, equality-system Gaussian collapse, implicit-equality-from-opposing-bounds, and var-var merge. A partial impl wires the wake to only ONE channel (usually explicit unification). This turned an isolation-passing solver into a composition-failing one and moved the band 40% → 30% (Pattern 75).
- **Difficulty is bimodal here, so the knob is seam COUNT, not depth:** the passers did everything; catching the marginal passer needs a seam where a local fix to behavior A regresses behavior B (shared determination chokepoint). Isolated behavior tests only measure completion probability (~coin flip), which is why the un-seamed batch sat at 40%.

## Nova blind spots -- NEW-OPERATOR pick: precedence-boundary + paren-preservation + shared-path regression (erg-chained-comparison, APPROVED Mars 2026-07-10, 30%, 5 designed seams across 7 fails)
- star PRECEDENCE BOUNDARY (dominant, 3/7): Nova scopes a new construct too narrowly -- builds the chain only when the next token is another comparison, missing that a run terminated by a lower-precedence `and`/`or` must still form the chain FIRST. `1<3<2 and 4<5` -> True (wrong). Nova's own smoke tests use pure chains, so it never sees the boundary bug. Universal: add tests adjacent to existing lower-precedence operators.
- PAREN PRESERVATION (1/7): Nova adds a `paren` flag but a later desugar pass rebuilds the node via a constructor that resets it, silently dropping the distinction. Nova conceptually KNEW the requirement; the implementation lost it through the pipeline. Blind spot = metadata not surviving a re-construction pass.
- SHARED-PATH REGRESSION (1/7): touching the shared `in`/`notin` handling for chaining regressed LONE membership (`1 in 1..2`), because Nova validated with cargo check + a focused new file and did NOT run the full baseline. Nova reliably under-runs the base suite -> fix-one-regresses-another traps on shared code paths land.
- SINGLE-EVAL x EFFECT SYSTEM (1/7): a lambda-based desugar put side-effecting `f!()` operands into a non-procedural context, tripping the effect checker (Error#0420). Nova validates pure operands only.

## Nova blind spot -- ABSENCE / typed-domain omitted from REACHABILITY (only wired into completeness) (zen-table-verification, APPROVED Olympus 2026-07-10, SOLE killer across 19 runs)

When a feature has two checks that should share a domain model (here: unreachable-rule detection and incomplete-coverage detection over decision-table cells), Nova implements them as SEPARATE passes and wires the subtle domain dimension (declared type + optional/null absence) into only ONE of them -- the one where it is most obviously needed (completeness). The other check (reachability) is left on the naive value-space model. Concretely, agents wrote unreachability as cell-set subtraction where an empty/wildcard cell is an unbounded `Any` and `Any minus <typed region> = Any`, so a non-nullable numeric catch-all row after `< 100` + `>= 100` is never reported unreachable even though the declared column domain is fully tiled; and symmetrically they flag a NULLABLE wildcard row as unreachable because they omit the absence dimension that keeps it reachable (it uniquely matches null). Across 19 runs this single interaction was the dominant/sole failure: batch3 5/8 fails, batch4 9/9 fails, all on `policy_non_nullable_number_wildcard_row_is_unreachable` and/or `policy_nullable_*_wildcard_row_stays_reachable` / `policy_nullable_*_catch_all_covers_absence`. Weaponization (Pattern 77): route BOTH checks through one `column_domain -> Domain{region,nullable}` chokepoint and build effective rows = domain-substituted wildcards + an appended presence-dimension per optional column, then run the SAME N-D subtraction. The graph consumer (no data model) passes all-None domains and stays conservative -- a clean dual-path asymmetry. This is the greenfield-analyzer analogue of the zen-hit-policies "runtime shipped, static analyzer missed" blind spot: agents complete the obvious surface and miss the check that must reuse the same model.

## go-geom-polygonize (APPROVED OLYMPUS 30% 2026-07-13) — agent blind spots (Nova, recurrence-ranked)

- **Non-representable intersection coords (recurred 3 FP batches).** Weak Nova impls node line crossings by recomputing the split per-segment and keying endpoints by exact float bits. They pass clean/representable crossings but fail when the crossing is not exactly representable (x=1/3; bowtie 60/11). The robust reference nodes once via `res.Intersection()` and reuses that coord consistently. This is the single most reliable Nova blind spot on geometry problems.
- **Face-merging via naive connectivity.** Nova traces rings by walking connected edges rather than the immediately-CW half-edge (`cur.sym.next = prev`), merging two faces that share an edge into one polygon. Only a SHARED-edge input exposes it; single square / bridge cases pass with the wrong linkage (misdirecting).
- **First-containing-shell vs smallest-containing-shell.** Nova assigns a hole to the first/outermost containing shell; 3-4 level nesting requires the SMALLEST containing shell, so a hole must attach to the middle ring, not the outer.
- **Output winding convention.** Nova assumes math-standard sign; go-geom inverts (SignedArea(CCW) = -1), so orientation assertions catch impls that never normalize winding.

### Nova blind spots — truck-mass-properties (APPROVED Mars 2026-07-10, 2/10=20%), recurrence-ranked
- **★ Numerical stability: accumulate-about-origin (textbook Mirtich).** 8/10 Nova. On a rigid-body / second-moment feature Nova writes the canonical formula that accumulates second moments in ABSOLUTE coordinates about the origin, then subtracts `volume*centroid outer centroid` to centralize. This cancels catastrophically for geometry far from the origin (a box at 1e5 gives a spurious off-diagonal of -1 where 0 is required). The robust fix (accumulate relative to a near reference vertex) is standard geometry-lib practice but Nova rarely reaches for it. Exploit as a documented TRANSLATION-INVARIANCE test ("...wherever it sits in space") -> fair FAIL_MISSED_REQUIREMENT. This is INDEPENDENT of the algorithmic-insight blind spot below, which is why it broke the ceiling (Pattern 80).
- **★ Convenience-method delegation on an open sub-object.** ~50% Nova (high variance). When a closed-volume operation must be extended to an aggregate (Solid) whose parts are OPEN (per-face surfaces with zero enclosed volume), Nova delegates per-part to the closed-volume convenience method (`face.surface().inertia_tensor_about(pt)`) and sums -> divide-by-zero NaN. The correct path accumulates raw signed moments across parts THEN assembles once. Misdirecting because the existing linear `volume()`/`center_of_gravity()` per-face pattern makes delegation look right (volume IS per-part-linear; second moments are not, across the centroid shift). Only DIRECT-aggregate tests surface it (the mesh path passes).
- **Correlated (does NOT stack): right-handedness.** An agent that clears both above also produces right-handed principal axes; a `det=+1` (vs `|det|=1`) wall is fair but CORRELATED with thoroughness and moves the mean ~0. See `PATTERNS-ADVANCED.md § Pattern 80` (correlated-vs-independent wall law).

### Nova/Orion blind spots — scryer-clpq-linear (APPROVED OLYMPUS 2026-07-16, 1/10=10%), recurrence-ranked across 13 unhinted runs
- **★ dump canonicalization (7/10 substantive fails — the dominant wall).** NewVars-position pair ordering (not standard sort), first-pair magnitude-one scaling, opposing-bounds-merge-to-eq, determined-target `con(eq,[1-New],v)`. Agents build a working projection then ship store-order/unnormalized residuals even though the meta states every rule. Fully-spec'd but IMPLEMENTATION-hard = fair + durable (every eval `was_mentioned=true`).
- **★ full-store entailment (6/10).** `entailed/1` consulted only inequalities or only query-var constraints: stored disequalities (`{X =\= 3}, entailed(X =\= 3)`), strict-bound-implied diseq (`X>3 -> X =\= 3`), ground/rational equalities all miss. One Nova's negative-entailment path HUNG (see behavior note).
- **exact-rational arithmetic (3/10).** Syntactic-only `A rdiv B` acceptance (evaluated rationals rejected at unify), lowest-terms, rational optimization, const-expr divisors.
- **io_rat render (killed a 120/121 near-miss).** Positive LEADING rational coefficient `1 rdiv 2*x =:= 5` — agents smoke-test integer and negative-following-rational cases, skip positive-leading. Cheapest highest-leverage render trap.
- **From-scratch 3-module scale itself gates ~23%:** 3/13 runs died at the 5400s wall-clock still debugging core propagation (early-term).
- **Behavior note (Nova): deletes its own failing local test instead of fixing.** Run #4 saw its negative-entailment check hang locally, REMOVED the assertion, shipped the hang -> verifier 1800s timeout. Non-terminating paths in agent solvers surface as full-suite timeouts, not assertion fails.

## neva-array-bypass-generalization (APPROVED Olympus 2026-08-01) — agent behaviour

**Batch: 2/10. Orion 1/1, Nova 1/9 (11%).** Third problem in a row where Orion is load-bearing; a batch without it reads lower than the truth.

**Confirmed blind spot — resolution dropped at a stage boundary (6 of 10 runs, identical 10-test block).** Agents resolve an elidable name in the VALIDATING stage and then return the original object, so the EMITTING stage in another package never sees it. The evaluator on one run named it exactly: *"analyzeArrayBypassConnection obtains resolvedSender and resolvedReceiver but analyzeConnection returns the original conn"*. The agents did the work and threw it away. Fair because the repo re-resolves the same thing at the later stage for the ordinary path, so both placements look reasonable.

**Confirmed blind spot — capability cross-product cell (8 of 10, incl. both near-misses).** Agents build a case analysis per stated axis, pass every single-axis test, and never construct the intersection. Failure mode is OVER-firing (`20\n20\n` instead of `20\n`), not a missing feature, so it reads as a routing bug rather than a missing combination.

**Misdirection profile.** Not one failure named the responsible stage. 7 of 10 failing tests panicked inside unrelated stdlib runtime funcs (`fan_in: array port not found by name`, `fan_out: port 'data' is not array`), 3 hung to a 60s timeout with empty stdout AND stderr.

**Long horizon.** Passing patches 610-693 added lines across 15-19 files; failures still ran 14-16 files and 5.9-14M prompt tokens. `trajectory.json` `steps` is a truncated summary (6 entries) and is NOT a message count — use prompt tokens as the effort proxy.


## customasm-ruledef-disassembly (APPROVED 2026-08-03) — agent blind spots

Measured over 10 runs (1 pass, 1 env-fail excluded):

- **Global instead of local selection scope (9/10, F-11).** Given a recursive choice metric, agents
  maximise it over the whole explanation, letting a later sibling's score pay for an earlier
  sibling's worse local choice. Sole failure of all five near-miss runs. Needs two consecutive
  variable sub-parts to surface.
- **Syntactic forms of "the same thing" (4/10).** Agents accepted a bare parameter but rejected the
  same parameter written with an explicit width, treating the width suffix as a computed
  expression. Cost: a whole cluster of nested tests, because those forms also bound nested fields.
- **Arbitrary recursion caps (3/10).** Agents invent a depth limit not present in the contract and
  fail valid finite nesting. Pairs with the opposite bug in the reference (no guard at all -> stack
  overflow on cyclic input), so the axis cuts both ways.
- **Agent split:** Orion 1/4 pass, Nova 0/6. Orion again the only passer, consistent with prior
  problems.


## numbat-parse-unit-expressions (APPROVED 2026-08-04) — agent blind spots

- **Deleting orphaned repo tests is near-universal.** 7 of 8 agents across two rounds removed a
  private helper (`parse_quantity_ast`) and, forced by the compiler, deleted the inline test module
  that called it. Their own `cargo test` went green; only p2p identity grading caught it. Both
  eventual passers surgically revised the module instead.
- **Outer-vs-inner sign placement in a rational exponent is a real blind spot.** 3 of 10 accepted
  `m^(-(1/2))` but rejected `m^-(1/2)` (or the reverse), even with the meta stating the sign may sit
  on either side of the parentheses.
- **Round-trip contracts are tested shallowly.** Agents verify `unit_name`/`unit_from` on simple
  units, which round-trip fine, and never probe an exponent >= 10 or 0 — precisely where the
  tokenizer cannot read its own printer's output. Classic self-test-shadow.
- **Nova and Orion differ on repo-test discipline, not capability.** Orion was structurally blocked
  by the F-12 axis in every batch it appeared in while passing 85/88 features.

## rust-minidump-stack-containment (APPROVED Olympus 2026-08-06) — Nova blind spots

Single-agent batch: **Nova 2/10**. No Orion, no Vega. Effort was substantial across the board —
9-26 files, 439-685 added LOC, 9.2M-20.3M prompt tokens per run — so these are not
give-up failures. Eight of ten runs implemented nearly the whole feature and lost on semantics.

**Confirmed Nova blind spots, recurrence-ranked:**

1. **Discard granularity — 6/10 (F-13).** Told that a contradictory *record* is discarded, Nova
   discards the *row* it was parsing and keeps the enclosing record live. Verbatim (Nova 8):
   "parses each additional line into line_exprs and simply omits exprs.extend(line_exprs) when that
   line conflicts, leaving the INIT rules active." Three runs failed on this ALONE at 48/49. Nova
   consistently prefers the more local, more "graceful" error recovery.
2. **Arming vs firing on a tolerance rule — 4/10 (F-15).** "Stop before recording a second X" is
   implemented as "stop at the first X". Nova treats detection as the trigger. It also then marks
   the walk truncated, so the error propagates into aggregate status.
3. **Declared vs derived terminal state — 3/10 (F-14).** Given a new stop reason meaning "someone
   declared this", Nova wires it to every pre-existing giving-up site — across SIX architecture
   files in one run — because those sites are where "we're done" is already computed. One run then
   merged the two states in the output rule as well, turning one wrong idea into 6 failing tests.

**What Nova got right, unanimously (do not spend rounds hardening these):**

- **Conditional output omission: 10/10.** Zero baseline failures in every run. The
  "don't change existing output unless there is something to report" contract, which cost me two
  authoring rounds to legitimise, discriminated nothing.
- Boundary/token/enum-shape work: every `as_str` token, `is_truncated` polarity, half-open region
  boundary, and multi-architecture integration test passed in all 10 runs.

**Read-through:** Nova's failures cluster on *semantic scope* questions — which unit does this
rule apply to, which event triggers it, which provenance does this state carry — and never on
mechanical surface. Target scope ambiguity, not API breadth.

## Agent Behavioral Profiles — lyon-fill-internal-vertices (Nova x30 across 3 batches)

New / confirmed blind spots:

- **Zero-argument builder inference (NEW, 4/10).** Given "add a public boolean field plus a `with_*`
  builder that sets it", 4 of 10 Nova runs emitted `with_x(mut self) -> Self` with no parameter, and
  died on `error[E0061]` across the whole hidden crate. The single passer emitted
  `(mut self, eliminate: bool)`. Nova reads "sets it / turns it on" as an imperative enabler unless
  the parameter is named or the repo convention is directly adjacent.
- **Convergent architecture is near-total.** All 30 runs across 3 batches independently chose the
  same design: buffer the mesh, classify vertices, remove-and-retriangulate per vertex via one-ring
  ear-clipping. Its three structural failure modes (bails on non-manifold links, fans non-convex
  cavities, non-interleaved two-phase removal) accounted for essentially every fair failure.
- **Effort does not predict correctness.** Failing runs added 650-753 LOC; the one passing run added
  the LEAST (625). Prompt tokens 7-15M with no correlation to outcome.
- **Nova will satisfy a structural proxy rather than the stated property.** Where the contract said
  "the filled region covers a full neighborhood" and the natural check was topological, multiple runs
  implemented a manifold-gated classifier that is correct under the proxy and wrong under the
  contract.


## gluon-format-comments (APPROVED 2026-08-07) — agent blind spots

- **Token-form parity (F-18).** Agents implement a rule for the SALIENT lexical form and apply the
  other form only where they first met it. Block-comment cases took 22 of 37 kills while their
  line-comment twins at identical positions killed 0-1 each. This is not a comprehension failure —
  the contract stated the forms are equivalent — it is an incomplete case analysis that the agent
  never revisits because the rule "already works".
- **Nova, formatter/layout work.** 11 runs, 605-915 added lines, 19-50M prompt tokens, and only one
  general model of the problem among them. The passing run built a gap abstraction; every failing
  run wrote placement per-construct and left a position or a form uncovered. On layout tasks, expect
  agents to generalise late or not at all.
- **Own-reference parity check.** Four reference bugs, all found by probing reviewer coverage
  findings rather than by the suite: doc comments double-printed, a span keyed on the wrong end so
  output GREW on each format pass, a doubled break, and own-line comments glued to the previous line
  when their gap had no trailing comment.

## vrp-tsplib-edge-weight-types (APPROVED Olympus 2026-09-02) — Nova blind spots

Batch 12 was Nova x10 (3 solves, 30%). Across four measured batches (52 runs) on this artifact:

- **Output-channel blindness is Nova's most durable blind spot measured so far.** Asked to make an
  existing CLI command "return this JSON output", Nova wires the command to the library's ordinary
  entry point — the correct engineering call — and never notices that entry point's logger writes
  an informational line to the same stdout. 36 of 52 runs, never below a 50% kill rate in any
  batch. Nova's own serializer was correct in every single case; only the channel was dirty. The
  failure surfaces as a JSON parse error at column 1, in code Nova did not write, which is why it
  survives: Nova audits the serializer and finds nothing.
- **Nova reliably implements a stated canonical form.** Given "returned in ascending node-number
  order", all 10 runs sorted numerically, including at DIMENSION 12 where the zero-based ids are
  STRINGS and a lexicographic sort visibly breaks past node 9. Do not count a stated ordering,
  sort, or dedup rule as difficulty against Nova.
- **Nova converges architecturally on this shape.** All 10 batch-12 patches landed 6-8 files and
  497-649 added LOC (median 7.5 files / 600 LOC) with the same trait-plus-serializer decomposition.
  Median prompt-token spend 7.4M, ranging 5.3M-12.1M — the three solves were NOT the high-spend
  runs, so token burn does not predict success here.
- **Nova does not attempt subprocess-level self-verification.** No run tested its own CLI end to
  end; every run validated the serializer in-process, which is exactly the assertion that cannot
  see the contamination.

## Agent Behavioral Profiles — go-workflows-channel-drain (APPROVED 2026-09-04, Nova x10)

**New confirmed Nova blind spot — sibling-API contamination (8/10, highest measured on this
problem).** Given a NEW entry point that is a variant of an existing one (`SelectAll` beside
`Select`) with a deliberately different rule, 8 of 10 Nova runs factored both onto a shared helper
and applied the new rule to the OLD api. They graded `FAIL_REGRESSION` — the only regression
verdicts in the batch — and it was the SOLE failure of both 100/102 near-misses. Nova does not
re-verify untouched public behaviour after a refactor, and a green baseline suite actively
reinforces the mistake when the old behaviour has no test.

**Confirmed: Nova under-propagates scheduler progress.** Across batches 6-11, the largest recurring
cluster was "the coroutine my operation just unblocked never runs again". Nova implements the state
change and omits the progress/wake notification the cooperative scheduler needs. It stayed at 5/5
kills until the contract said WHEN the resumption must happen ("before the scheduler run that
drained them finishes"), then fell to 1-2/10 — so the blind spot is about TIMING semantics, not the
requirement itself.

**Cross-product cells still discriminate (F-10, 4/10 here).** Each axis alone worked; the
intersection (parked receive-like select case) x (unbuffered channel + nonblocking send) dropped the
value. Same signature as neva.

**Effort profile (10 graded runs):** median 11 files touched, 1026 added LOC, 11.2M prompt tokens.
`trajectory.json` `steps` was 4 with `compacted: true` — NOT a message count; use prompt tokens.

## datafixerupper-ordered-alternatives (APPROVED 2026-09-08) — Nova blind spots (10x Nova, 5/10)

No Orion in the batch. All ten Nova runs implemented the decode side correctly; the entire band was
decided on the `MapCodec.encode` builder boundary.

- **Downcasting to the repo's abstract base to read state the interface does not expose.** Nova_4 and
  Nova_6 INDEPENDENTLY wrote `if (builder instanceof RecordBuilder.AbstractBuilder<?, ?>)` to decide
  whether an encode failure carried a partial. Correct for every builder the repo hands out, wrong for
  any conforming implementation outside that hierarchy. This is now **F-21**, the top killer (5/10) and
  the sole failure of the closest near-miss (Nova_6 at 172/173).
- **Skipping the wrapper entirely.** Nova_2 and Nova_9 returned `codecs.get(0).encode(...)` unchanged —
  no `mapError`, no lifecycle normalisation — and failed the IDENTICAL 17-test set. Two runs, one
  omission, byte-identical failure lists.
- **The lifecycle rule is written but never runs.** Nova_7's failures all read "expected Stable but
  was Experimental" even though its code contained a correct normalisation — guarded behind a
  condition the fixture's builder did not satisfy. The failing assertion names the lifecycle, never
  the guard, so self-review does not find it.
- **What Nova got right, unanimously:** ordered scanning, earliest-partial retention, partial-only
  lifecycle folding, aggregated diagnostics, covariant `ClassCastException` handling, duplicate-
  preserving `keys`, identity equality. Covariance killed 5/10 in batch 8 and **0/10** in batch 9 —
  the same axis, one description revision apart.


## customasm-derived-bank-layout (APPROVED 2026-09-09) — agent behavioural profile

**Nova is 1 for 24 on this problem; Orion was 1 for 2.** Orion passed on its only two appearances
while Nova needed four fairness relaxations before a single run cleared. A Nova-only batch read 0/5
twice on artifacts that Orion-containing batches passed, so **a batch without Orion reads lower than
the truth** on fixed-point work.

**Confirmed blind spot — the joint fixed point (F-22).** 8 of 9 failing runs in the accepted batch
built a settling pass for the NEW quantity alone. Evaluator wording, unprompted and repeated:
"dependencies do not settle transitively", "guessed intermediate values are converted too early",
"do not reliably converge through later banks, constants, labels, and settling instruction sizes".
Direct one-hop chains passed in every run; only chains routed through a function, a constant, or a
forward reference discriminated.

**Second blind spot — high-water vs current cursor.** 2 runs computed a measured extent from the
cursor at the end of the traversal instead of the maximum reached during it. Cheap to author,
smaller yield than the fixed point.

All ten runs scored `was_mentioned_in_description: true` on every failure — zero fairness flags.

## rocketpy-propellant-slosh (APPROVED Olympus 2026-09-10) — agent blind spots

Four batches, 36 solver runs, Nova + Orion. Three blind spots, ranked by recurrence.

**1. Delegating a stated contract to the repo's own container (6/10, and Orion twice).** Every agent that reached for RocketPy's `Function` to hold a scalar-or-callable parameter inherited its signature introspection, which counts a defaulted or keyword-only parameter as an extra domain dimension and rejects the value. Nova and Orion both did it; Orion did it in two separate batches, consistent with its decisive-commit-no-pivot profile. The blind spot is not carelessness — using the repo's own abstraction is the instinct that is right everywhere else, and the `ValueError` surfaces from a base-repo file the agent never opened.

**2. A suppression rule applied to the obvious context but not the one that superficially has the quantity (3/10).** The contract said a phase resolving no lateral body-frame force uses a zero drive. Every agent suppressed correctly on the rail — no rail test killed anyone — and three fed parachute drag into the drive, because the parachute phase visibly carries a force. Agents exempt what obviously lacks the quantity and miss what merely does not RESOLVE it.

**3. Returning a bare scalar where the repo's API is uniformly Function-valued (1/10, and 1/6 in batch 1).** This one was OUR defect, not theirs — `meta.md` only promised the value, not the type. Recorded here because the same shape will recur: an agent asked for "reports zero" will return `0`.

**Evaluator behaviour worth knowing.** Across 20 failing runs in two batches, every judge returned `description_clear: true`, `tests_deterministic: true`, `was_mentioned_in_description: true` and difficulty "challenging", and several volunteered an unprompted rebuttal of the unfair reading. Convergent failure is NOT read as unfairness when the contract sentence genuinely covers the case — Auto Review scored Description 3/3 Clean over a 6/10 convergent cluster twice.

**FP panel.** One judge filed a solo `false_positive`; the adjudicator overruled at high confidence, citing our own tolerant test helper as proof the probe was not prompt-grounded. Panel dissent is survivable when the suite's own helpers document the permitted domain.


## datafixerupper-derived-recursion (APPROVED Olympus 2026-09-11) — Nova blind spots

Two full 10-run Nova batches, four levers apart, both 1/10, with the IDENTICAL dominant cluster.
Ranked by recurrence:

1. **Replacing an existing hard failure with a sentinel to keep a new analysis total — 8/10, twice.**
   Asked to derive a reference graph, Nova invents `UnknownType` / `MissingRef` so the pass is a
   total function, then carries it into construction: a lookup that threw on base now succeeds.
   Every evaluator marked the requirement BOTH stated in the description AND inferable from the
   codebase, and it still killed 8/10 in both batches. **The strongest and most reproducible Nova
   blind spot measured to date.** Four runs failed ONLY this pair, at 85/87.
2. **Scoping a deferred placeholder to its own analysis pass — 4/10 + 4/10.** Nova gates the
   placeholder on a phase flag ("Schema references are only valid while collecting") and throws
   from `hmap`/`applyO` afterwards, or resolves it against a mutable "current group" that has
   already been cleared. Any value the CALLER retained across the boundary breaks. Nova does not
   consider that a public API handing back an unresolved handle has the caller's lifetime, not the
   pass's.
3. **Dropping an untested identity wrapper when rewriting an assembly path — 3/10.** Base wraps
   every registered template in `DSL.named`; Nova (and the reference) rebuilt the path without it,
   making structurally identical types indistinguishable to rule matching. No base test covered it.
4. **Recursive-family lifecycle through runtime rewriting — 2/10 in both batches.** Placeholders
   wired into `hmap`/DataFix traversal overflow or throw at fix time, long after construction
   looked correct.

**Not a blind spot:** the feature itself. Nine of ten runs implemented reference collection across
nine template forms, SCC grouping, registration-order indices, dependency build order and the
inhabitation fixed point correctly. Effort spent hardening THAT bought nothing.

**Long-horizon (batch 2, 10 Nova):** median 4 files, median +594 raw LOC, median 6.2M prompt
tokens. `trajectory.json.steps` is a truncated summary (4 entries here) and is NOT a message count.


## ray-optics-formula-conditionals (APPROVED Olympus 2026-09-14) — Nova and Vega blind spots

Three batches: 10 Nova + 1 Vega (0/11), 10 Nova (1/10, FP-flagged), 9 Nova + 1 Vega (1/10, Vega).
Batch 3, ranked by recurrence:

1. **Identical operands estimated as independent intervals — 7/10** (5/10 and 5/11 in the earlier
   batches, under different descriptions). Nova extends the interval estimator by combining two operand
   ranges and never checks whether both sides are the same node, so `x < x` keeps a branch it can never
   select. Every evaluator marked it described AND inferable. (F-26)
2. **`or` narrowing copied from `and` — 6/10, up from 3/11.** Nova narrows the `or` TRUE branch with
   the operands' restrictions. A clearer sentence made it worse, not better. (F-27)
3. **Raw lowering over a wrapped operand — 6/10, and the sole failure of the 94/96 near-miss.** A valid
   comparison lowered to plain f32 reads a maybe-invalid operand without `.value`. Several runs had
   written an `asF32` helper in the same patch and did not call it on the new node. (F-10)
4. **Repo equality idiom via subtraction — 3/10.** Nova tests equality as a nonzero guard on `a - b`,
   which overflows for far-apart finite operands. The reference made the same mistake. (F-23 family)
5. **Variadic call arguments keep the old parse production — 2/10.** `max`/`min` arguments still parse
   at the additive level after the fixed-arity path was updated.

**Literal grammar reading (batch 1, 11/11 including Vega).** When a qualifier can attach to two
clauses, both Nova and Vega attach it to the nearest one.

**Vega vs Nova.** Vega produced the only legitimate pass in 31 runs: 12 files, +713 raw LOC, on 2.9M
prompt tokens, under half of Nova's batch-3 median (7 files, +531, 6.2M). Nova's one pass (batch 2)
was a false positive. On a spec made of many small asymmetric rules, the heavier multi-file
implementation cleared all four seams; no Nova run cleared more than three.

**Not a blind spot:** parser precedence, the statement splitter, arity rejects, JS codegen, WGSL
agreement and the derivative chain rule. 86 of 96 tests killed nothing.

## worldengine-orographic-precipitation (APPROVED Olympus 2026-09-16) — Nova blind spots

Two batches, 20 Nova runs: batch 1 1/10 by the grader with no clean pass, batch 2 2/10. Ranked by
recurrence:

1. **A two-part concept split into sibling container keys — 11/20 (7/10 in batch 2).** Nova stores
   `wind_direction` and `wind_strength` as separate `layers` entries although the meta says "a wind
   layer" and the repo has `LayerWithThresholds`. Values survive serialisation, the key does not, and
   the failure surfaces as `KeyError: 'wind'` in round-trip tests. (F-28)
2. **Placement prose read as a statement about existing steps — 10/10 in batch 1,** 0/10 once one
   sentence stated the existing stages are kept. (L57)
3. **Exact band-centre strength — 5/10 in batch 1** returned 0.9999999999999993: a test defect, not a
   blind spot, fixed with a tolerance. (L59)
4. **Whole-layer arrays written as cell-taking methods — 4/20,** 11-14 tests at once, graded
   INTEGRATION_ERROR. (F-16 accessor variant)
5. **Applicability guard written but not called — 3/20.** `is_applicable` is correct, `execute` stays
   unconditional like the eight sibling simulations, so a supplied wind is overwritten. (F-29)

**Not a blind spot:** latitude-band geometry, the closed-form steady state, wrap seams, warmth scaling,
drawing, CLI output. The 24 transport tests killed 0 of 20 runs.

**Effort (batch 2).** 11-12 files, +324 to +441 raw LOC, 3.5M-6.5M prompt tokens, 44-71 tool calls.

## cwerg-bcopy-bzero-lowering (APPROVED Olympus 2026-09-16) — Nova and Vega blind spots

Five solved batches, 50 runs (46 Nova, 3 Vega, 1 Orion). Accepted batch 6: Nova 2/9, Vega 1/1. Ranked
by recurrence:

1. **A new full-width consumer after an existing width pass — 10/10, 8/11, 7/10, 3/9, 2/10.** Nova
   lowers `bzero`/`bcopy` correctly and never opens `FunRegWidthWidening`, so a U8 length that wrapped
   to 0 is 256 once the optimizer widens it; the optimized C executable segfaults. Stating the rule in
   meta.md lowered the rate but never removed it. (F-30)
2. **C++ CFG edits that only the text renderer rejects — 9/10 (sentence missing), then 3/11, 2/10,
   2/10.** Segfault in `-mode normal` on the large program, `-mode binary` fine. Graded
   INTEGRATION_ERROR. (F-32)
3. **Twin constant folders left alone — 2/10 in batch 6, identical 5 tests.** Nova changes lowering
   and the C backend but not `eval.py`/`eval.cc`, so a folded S32 wrap prints `4294967294` in C++ and
   `-2` in Python. (F-31)
4. **`bcopy` derived from `bzero` advances only the destination — 1 run in each of batches 4, 5, 6.**
   Copies the bug into both twins. (F-27 variant)
5. **`bbl.inss.remove(ins)` against an identity-asserting `__eq__` — 2 of the first 5 in batch 1, 1/10
   in batch 4.** (F-4)

**Not a blind spot:** byte-order semantics for positive, zero and negative lengths, overlap order, all
eight integer kinds on the native targets, plain C output. **Effort (batch 6):** 12-31 files, +784 to
+1214 raw LOC, 23M-42M prompt tokens; the Vega pass was the cheapest run at 23M.

## tippecanoe-tile-join-size-recourses (APPROVED Olympus 2026-09-16) — Nova blind spots

One batch, 10 Nova, 1 pass. Seven failing runs never had their source exercised (stale binaries), so
this ranking comes from the evaluators' static reviews:

1. **Restoring tracked build outputs after the last build — 9/10 runs.** Nova treats `.o` files and
   binaries in `git status` as noise and `git restore`s them before finishing, which leaves the
   workspace's binary older than its source. 7 were graded against the baseline binary. The one run
   that never restored committed its objects instead, and was the pass. (L63)
2. **Recording on the attempt, not the effect — 4/10** (plus one mirror run). An oversized tile with a
   single feature cannot shed anything, yet `tile_size_desired` was written the moment the tile was
   over the limit. (F-15)
3. **Leaving the input reader's operator alone — 3/10.** Inherited `tile_size_desired` still summed in
   `handle_strategies` while the new per-tile path took a maximum. (F-33)
4. **A regression in the ordinary join path — 1/10** (segfaults, `mvt_type -13`).
5. **One-feature-at-a-time shedding with a full re-encode — 1/10**, timed out at 1785 s on the
   90,000-feature fixture.

**The pass** used the least effort in the batch: 9.6M prompt tokens against a failing median of
15.1M, 5 source files.

**Not a blind spot (no attribution in 10 runs):** extent ranking for points, lines and polygons,
merge-order ties, attribute-pool compaction, the output-only tilestats/zoom/bounds booking, compressed
vs uncompressed measurement, and extent rescaling. Treat that with the static-review caveat above.

## sfepy-adaptive-stepping-accounting (APPROVED Olympus 2026-09-16) — Nova, Orion and Vega blind spots

- **Nova (0/11 with a result) saves a rollback snapshot by assignment.** `initial_vec = vec0` before a
  solve that writes into `vec0`: 8 of the 9 Nova runs with per-test data (F-34), including both 116/117
  runs. Neither passer made this mistake; both called `.copy()`.
- **Nova clamps with `min()` where the contract is strict.** 6 of 9 let a hostile `adapt_fun` produce a
  retry equal to the rejected attempt (F-10 hook cell). 6 of the 8 F-34 runs missed this too, so the
  two misses travel together.
- **Nova breaks a repo example while clearing the new suite.** The only Nova run at 117/117 drove
  `linear_elastic_damping.py` through 439 retries to a singular factor (F-12).
- **Vega (1/3) rewinds the step index with the state (F-35) and trusts a hook's final time.** One run
  failed all three stop-before-advancing tests at 114/117, another let a hook end the run at 9.0 against
  a final time of 4.0 at 116/117. No Vega run aliased the snapshot.
- **Orion (1/1) is slow and complete.** 28.9M prompt tokens, more than twice any other run in the pool,
  and a clean pass.

## mwparserfromhell-site-aware-parsing (APPROVED Olympus 2026-09-18) — Nova, Orion and Vega blind spots

- **Nova (2/13) takes the delegation shortcut and wins with it.** Both passes, and 4 of the 11 failing
  Nova runs, forwarded C tokenization to the Python tokenizer when a site was given. The shortcut saves
  the C arm but not the Python scanner: 9 of the 11 failing Nova runs failed the seeded parity corpus
  (F-36), several by slicing the unread remainder back into the shared segment list.
- **Vega (0/5) implements the C arm natively (4 of 5) and misses the setter path.** All 5 returned namespace 0
  for `node.title = ":File:Foo.png"` while handling the colon on parsed links (F-10 two-path cell), and
  3 of 5 kept `'\0'` as end of input in the C reader (F-37). Vega patches were the largest (526-626
  added lines) at 3.9-8.2M prompt tokens, against Nova's 3.7-14.9M.
- **Orion (0/1) mutates shared state and repairs in the builder.** It sliced `self._text` while scanning
  the trail and returned `[link, Text(trail)]` for file and category links, losing characters on
  backtrack and splitting text nodes (F-36, both branches).
- **Nobody paired tag names by case folding.** 19 of 20 in batch 1 kept the base `lower()` pairing, which
  is why that test was unfair rather than hard (L66).

## kira-loop-crossfade (APPROVED Olympus 2026-09-18) — Nova blind spots

- **Nova transcribes a fully stated audio contract.** 10 of 10 Nova runs built the public type, both
  settings and handles, static and streaming blends, reverse mirror, seek wrapping, slices, easing, rate
  parity, stereo, decoder seek budgets and baking: 13-14 source files, 276-412 effective lines, mean
  54.3/55 tests.
- **Streaming schedulers split three ways on buffering.** Several runs prepare the tail and head frames
  of a fade before enqueueing (47 frames queued from 60 decoder calls against the reference's 48), one
  queued 24. All preserved what they had buffered. A test that assumes one queue depth reads these as
  failures (L69/L70).
- **The one genuine miss: wrap arithmetic under a live region change** (1/10). After switching to a loop
  that ends before the playhead, the run subtracted the full loop once and added the fade once, leaving
  the position past the new end. The reference steps by (loop - fade) until inside. F-10 live-change cell.
- **Nothing killed on the streaming decoder discipline.** At most one extra startup seek, one seek per
  wrap and forward-only head decoding were all met by 10 of 10.

## planetiler-custommap-schema-composition (APPROVED Olympus 2026-09-18) — Nova blind spots

- **Nova validates a per-input rule against the running accumulator (F-38).** 7 of 10 runs checked
  "removing an id the earlier files did not contribute" with `map.containsKey(id)` on the map they were
  already mutating, so a layer added and removed in the same file passed. Three of them failed nothing
  else out of 83.
- **Nova drops a resource origin at the second consumer (F-9).** 3 of 10 resolved a standalone bundled
  schema correctly in the loader, then re-resolved its `examples` string against a filesystem path in
  the validator.
- **"X returns ..." becomes an accessor.** With no static/instance stated, 8 of 8 made `files` an
  instance method, 7 of them as a new record component on `SchemaConfig` (L72).
- **Nova runs installs.** One run executed `mvn -o -pl planetiler-core -DskipTests install` without the
  flatten profile and broke the offline verifier (L73).
- **Passers wrote more than the reference.** The three passers measured 454-499 human-effective lines
  against the reference's 316: none delegated or took a shortcut, and all added their own tests.
- **Nothing killed on the stated merge rules.** Args settled after composition, layer positions,
  raw-vs-accessor scalar inheritance, diamond dedup, cycle naming and depth-first order: 0 of 10.

## featurevisor-minimal-rebucketing (APPROVED Olympus 2026-09-19) — agent blind spots

- **Nova builds per-key records on plain objects (F-40).** 7 of 8 Nova runs lost the variation
  `__proto__` from `getAllocationChanges`; six failed nothing else. Neither passer (Orion, Vega) did.
- **Agents reuse the repo helper that sounds right (F-39).** Three independent runs, two Nova and one
  Vega, refilled free space with `getUpdatedAvailableRangesAfterFilling`, which drops later ranges when
  an earlier one is used up exactly.
- **Stated algorithms are transcribed.** Lowest-first retention, declared-order refill, region cuts,
  sort-and-merge and idempotent rebuilds were right in 11 of 11 runs.
- **Representation varies when the prose allows it.** Five batch-1 runs returned a joined string or
  took one change per call in `formatRebucketing`; both satisfied "one line each".
- **Split:** Orion 1/1, Vega 1/2, Nova 0/8. Orion used the most prompt tokens (9.1M).


## ir-sim-scenario-events (APPROVED Olympus 2026-09-19) — agent blind spots

- **Runtime objects inherit constructor defaults the loader would have overridden (F-41).** 10 of 11
  runs spawned a robot through the factory with ir-sim's default `group=0`, so a group-behavior-only
  robot sat still. The loader gives every YAML entry its own group. Only Nova #3 rebuilt groups AND
  gave the spawn its own.
- **Lifecycle paths named in the prompt are handled.** All 11 re-armed events in `reset()`,
  `reset(random=True)` and `reload()`, rewound ids for replay, kept the shared object list intact, and
  tracked enter/leave every check once the description said so.
- **Agents over-rewind ids exactly as the reference first did.** 11/11 reset the id counter to one
  past the live objects, reissuing ids held by created-but-unadded objects (L76, untested).
- **Agents refresh derived views eagerly.** 11/11 updated sensors right after a spawn, which is what
  the reviewer later required; the early test pinned the opposite (L8).
- **Epsilon habits leak into closed intervals.** 2 runs padded the region by 1e-12 and logged a leave
  one step late on a trajectory that landed within float noise of the edge (L75).
- **Split:** Nova 1/10, Vega 0/1, no Orion. The passer used the most prompt tokens (19.4M of a
  9.3M-19.4M range).

## featurevisor-target-specialization (APPROVED Olympus 2026-09-19)

- **Nova rewrites the helper it finds, even when the task names another entry point.** 7 of 20 runs moved
  three-valued logic into the repo's exported two-valued helpers and broke their specs, after passing every
  new test. Reviewers called it a benign shared architectural blind spot, not ambiguity.
- **Hand-written recursive evaluators drop implicit containers** (a bare list meaning AND under
  `and`/`or`/`not`): 3/20 runs. Invisible to hand-written fixtures; visible to a seeded corpus.
- **Stated per-kind match rules are transcribed.** "Judge each kind of entry by the rule the SDK uses"
  gave force OR, global AND, rule-override precedence and requiredFeatures gating: 1 kill in 20 runs.
- Agent split: Nova only, 2/10 then 3/10 legitimate; passers 61-91 messages.

## csbindgen-struct-layout-fidelity (APPROVED Olympus 2026-09-21)

- **Nova composes two type rewrites in the wrong order (F-44).** Alias resolution applied at the outer
  name, then the array renderer runs on the target: `fixed byte* p`, lost or doubled pointer levels.
  6/16 and 7/10; every direct form passed.
- **Nova reuses the scalar emission path for aggregates (F-45).** `[MarshalAs(UnmanagedType.U1)]` stayed
  on `fixed bool` buffers: 3/16 and 3/10. Auto Review called it a shared blind spot and kept the test.
- **Nova computes the target-side model from source-side data (F-46).** Nested C# alignment/size taken
  from Rust, so containers were over-promoted to Explicit: 5/16 and 2/10.
- **Nova reads an enumerated list as exhaustive (L81).** With four 8-byte C scalars named, 7/16 gave
  `c_float`/`c_double` no layout.
- **Nova over-delivers when the task stops short.** 5/16 resolved const names and evaluated `4 + 4` in
  array lengths the contract said fall back; one run recursed into a stack overflow.
- Agent split: batch 4 Nova-only 1/10; Vega (batch 3) 0/1; passing patch 974 human-eff over 5 files.

## libspatialindex-tpr-temporal-knn (APPROVED Olympus 2026-09-21)

- **Stated geometry kernels are transcribed.** 7/10 Nova passed a pure interval-geometry contract, and a
  57-cell probe found zero behavioural difference between the passers and the reference. The convergent
  architecture: a private shape normaliser plus private meet/contain/distance predicates over
  extrapolated coordinates, bypassing the repo's own `MovingRegion` machinery entirely.
- **Agents do the local maths and drop state across storage and bounds (F-47).** With a per-entry end of
  motion, 4/12 lost it somewhere: node-bound pruning on deep trees, finite end times lost on insert, or an
  unversioned page. Point evaluation stayed right in every one.
- **5 of 6 clean solutions widened the page with no layout marker.** The evaluator failed one 73/73 run
  for it; FP judges probed four more and were over-ruled as out of scope.
- **Agents keep an existing method's legacy convenience when the contract narrows it (F-48).**
  `pointLocationQuery` kept answering a plain `Point`: 3/12, Orion included.
- One-run failures, not promoted: a nearest-distance optimiser that fixes the gap branch at a segment
  midpoint and misses a branch switch; a singleton interval left at `DBL_MAX`; a self-join that returns
  false after the first infeasible motion piece.
- Agent split, accepted pool: Nova 4/10, Orion 1/2. Passing patches 504-658 added lines over 5-8 files.

## siliconcompiler-flist-roundtrip (APPROVED Olympus 2026-09-23)

Cross-agent blind spots measured on a 10-Nova batch (plus 1 Vega in batch 1).

- **Re-parenting a deserialized graph onto the root (7/10).** Reading a flat record list whose edges
  live inside the records, seven independent runs registered every parsed node as a direct dependency
  of the object `read_fileset` was called on, in addition to the correct nested edge. Five shipped it
  as their only defect at 56/57. The convergence is architectural, not careless: a flat serialized
  form has no nesting to imitate, and the surrounding contract sentences all name the reading design.
- **Marker-only records not materialised (2/10).** A record with a marker and no content must still
  create the thing it names; two runs created it lazily from content and raised when a later reference
  needed it.
- **One run (1/10) implemented a comment-line marker as two lines** — the wire format is a place a
  single agent can diverge wholesale, failing 28/57 with everything else sound.
- **Wording moves a blind spot measurably.** The same pre-existing-data-root test killed 6/11 when the
  contract said "a root registered earlier" and 0/10 once the sentence named both readings.
- Effort: median ~7M prompt tokens per run; both passers wrote ~500 raw added lines in ONE source file.

## pyfakefs-block-inode-accounting (APPROVED Olympus 2026-09-23)

Cross-agent blind spots, 10-Nova accepted batch (plus 12 Nova/Vega in batch 2).

- **A repo helper that already routes through the changed primitive (F-20, 3/10).** `add_real_directory`
  builds its parents with `create_dir`. Once `create_dir` was made all-or-nothing, three runs' imports
  rolled back parents the contract kept, with no agent refactor at all. Agents change the primitive and
  never grep its callers.
- **"Unlimited" reported as a number, then enforced (F-50, 2/10).** To report `f_files` for an
  unlimited inode count, agents derived a figure from the block count and then refused allocations
  past it, or lost the usage when a bounded mount was set back to unlimited.
- **A platform-branched size getter used as stored size (F-51, 1/10 here; 3/11 and 5/12 earlier).**
  pyfakefs zeroes `st_size` for Windows symlinks. Agents sized the symlink by `stat` and charged
  nothing for its path.
- **Recursive removal releasing only in the non-recursive branch (1/10, candidate C-6).** Directory
  inodes leaked through `rmtree`; one run failed four tests on it and everything else was sound.
- **Wording blind spots measured:** a one-sided carve-out moved five tests 0/11 to 10/12, and a
  distant pronoun killed 10/11. Both went to 0/10 once rewritten.
- Effort: median ~14.6M prompt tokens per run. Passers wrote 487-689 raw added lines over 3-4 files.

## pyocd-sequence-expression-kernel (APPROVED Olympus 2026-09-24)

Cross-agent blind spots, 10-Nova accepted batch (plus 10 Nova + 1 Vega in batch 1).

- **Two stacked boundaries collapsed onto the nearer one (F-52, 2/10).** "A sequence function receives
  the unsigned form of every value" and "Write32 reduces the word it writes to 32 bits" were both
  implemented in the interpreter's call path, so the delegate got `0xffffffff`. Both runs were 146/150
  with nothing else failing. Agents edit where they already are.
- **A sibling argument normalised with the rule (F-20, 3/10).** Width masking on JTAG's sent bits
  spread to the `tms` argument, which the CMSIS-DAP layer itself masks with `& 1`. Partly an artefact
  of a test value outside the documented range (L92).
- **Twin evaluators fixed on one side only (F-31, 2/10).** Value semantics moved into the interpreter
  while the constant folder kept `x || 0 -> x` and `0 - x -> x`, the identities the repo's own fold
  table encoded.
- **What stopped killing once stated concretely:** unsigned scope storage 6/11 -> 0/10, argument
  reduction 7/11 -> 0/10, JTAG byte responses (unstated) -> 0/10.
- **A rule added in review killed 8/11 in batch 1:** "a control predicate must produce a value". Agents
  treat a predicate as a statement list, not a value position.
- Effort: 4.9M-8.6M prompt tokens per run. Passers wrote 232-296 non-blank added source lines over 3-4
  files.

## teavm-method-summaries (APPROVED Olympus 2026-09-24)

Cross-agent blind spots, 10-Nova accepted batch (4/10).

- **Least instead of greatest fixed point for an all-paths fact (F-53, 4/10).** Agents start
  never-null at false and promote a method only after its callees are proven, so a jointly never-null
  cycle never bootstraps. Three runs at 25/26 failed only this. The contract said "recursion and
  mutual recursion lose nothing" in so many words.
- **Improving the legacy path the contract freezes (F-54, 2/10).** The new `initClass` handler in
  RepeatedFieldReadElimination forgot every read even with null summaries; base keeps them. One run
  failed only this.
- **An "all instances" sentinel sent through the per-instance path (F-55, 2/10).** `-2` reached
  `AliasAnalysis.affectsEverything` and threw `ArrayIndexOutOfBoundsException`. The passers used the
  same `-2` and branched on it first.
- **What every agent got right:** SPECIAL vs VIRTUAL dispatch, absent classes and natives as unknown,
  `<clinit>` effects, invokedynamic, arrays, both TeaVM pipelines. All ten runs touched exactly the
  reference's nine source files.
- Effort: 9.5M-20.4M prompt tokens per run; passers 12.9M-20.4M. Passing production diffs ~425
  effective lines (reference 298). Auto Review counted 116-158 messages.

## bayesopt-search-space-migration (APPROVED Olympus 2026-09-25)

- **A rule applied to the registry but not to a second holder of points (F-10, 6/10).** Every run
  deduplicated registered points after a change; six carried ConstantLiar's pending points with the
  duplicates kept. Both 84/85 near-misses failed only this. Evaluators: described and inferable.
- **Learned collaborator state rebuilt instead of carried (F-56, 5/10).** Agents called the domain
  reduction transformer's `initialize()` or recomputed its contraction radius from the clipped window;
  everything stayed in range, only the later course changed. Always compounded with the F-10 miss.
- **Type test for a value rule (F-57, 2/10).** `isinstance(x, Real)` or a NaN-only guard let infinity
  or NaN through the "real number" rule.
- **Unanimous alternative design when a choice is only implied.** 11/11 (10 Nova, 1 Orion) dropped all
  GPHedge candidates when one could not be carried, several explaining why in comments. Stated: 0/10.
- **What every agent got right (batch 2):** value-based carry of points through add/remove/retype,
  queue migration, GPHedge per-candidate scoring once stated, the out-of-bounds random fallback,
  integer rounding ties, complex categories, transactional failure.
- Effort: median 82 model requests (batch 2), 79 (batch 1); passing diffs +529 to +656 raw lines,
  ~430 effective (reference 242). Batch 2 all Nova: 3/10.

## piscsi-image-reservation-identity (APPROVED Olympus 2026-09-26)

- **Identity re-derived from the name (F-59, 8 runs over two batches).** Agents captured device and
  inode, then rebuilt them from the name map on the dry-run snapshot restore, or fell back to the name
  when the queried path had no identity. Rename-then-reuse made the old holder "hold" the new file.
- **Staging with the object's own identity before it is registered (F-58, 5 runs).** Dry-run
  reservations recorded `GetId()` of a device not yet attached, so conflict messages named `-1:0`.
  Sole failure of a 65/66 near-miss. This was designed with zero description words.
- **Whole-path resolution in a containment check (F-60, 5 runs).** `filesystem::relative`/`canonical`
  on the full path judged an in-folder symlink image by its target and refused it.
- **Library API success-with-null (F-39, 9 runs).** `getpwuid_r` returning 0 with a null result was
  read as found; one run used `SUDO_GID` instead. Still 3/10 after the rule was stated.
- **Refusal leaving side effects (F-61, 2/10 batch 1).** A refused INSERT left the medium loaded because
  the read-only check had to open it first.
- **Unanimous miss of an implied extension (L100).** All 10 batch-1 solutions looked up a device's own
  holders by its stored name; none carried the rename rule into reporting.
- **What every agent got right:** alias identity through dot segments, `..`, symlinks and hard links,
  reader/writer sharing, per-holder release, protobuf holder fields, scsictl text.
- Effort: Nova only; passing diffs +354, +499, +575 raw lines against the reference's 294 (Counter 1).
