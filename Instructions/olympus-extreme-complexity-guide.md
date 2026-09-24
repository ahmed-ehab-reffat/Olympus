# Olympus Extreme Complexity Guide

This is the companion to olympus-common-mistakes.md. Every Olympus challenge must be genuinely hard -- not pattern-followable, not trivially copyable from existing code. SOTA AI agents should rarely pass. Target: at most 1-3 out of 12 agent runs should solve the challenge.

---

## What "Hard" Actually Means for Olympus

### NOT Hard (Reject These Ideas Immediately)

- "Add another keyword to an existing AST pipeline" -- agents copy filter/map/sortBy and adapt (100% pass, proven)
- "Add a new format parser that mirrors an existing one" -- agents copy JSON codec template (60-90% pass, proven)
- "Add a simple CRUD method to an existing class" -- agents find the pattern and replicate
- "Fix a bug that requires changing one line" -- under the Olympus floor (≥450 design, 400 auto-block), under 3 files
- "Add a configuration option that maps 1:1 to a behavior" -- agents implement explicit instructions perfectly

### Actually Hard (What Olympus Challenges Must Be)

Problems that require agents to:
- Design novel architecture that doesn't exist in the codebase
- Implement cross-cutting concerns that interact with multiple existing subsystems
- Handle subtle ordering and state management that survives superficial testing
- Navigate multiple packages and wire integrations correctly
- Make design decisions where the obvious/naive first approach fails tests

---

## Anti-Agent Design Patterns (Proven in Live Evaluations)

### 1. Cross-Cutting Concern Interaction

Two independently correct features that must interact through a shared pipeline. Agents implement each feature as an isolated concern and miss the interaction.

**Proven example (45% failure rate)**: dasel-csv-options -- null substitution and quoting. Agents implement null-to-string substitution as a special early-return path that bypasses the quoting pipeline. If the null string contains the delimiter, it must be quoted. But the isNull guard returns before quoting logic runs. The fix is to substitute first, then pass through the same pipeline as regular values.

**How to design this pattern**:
1. Feature A transforms a value (substitution, formatting, normalization)
2. Feature B validates or decorates values (quoting, escaping, validation)
3. The correct implementation routes A's output through B's pipeline
4. The obvious implementation gives A a shortcut that bypasses B
5. Test with a value where A's output triggers B's behavior

### 2. Same-Object Edge Cases

Agents always test the parent-child or cross-entity case. They never test the same-object case where two properties of the same entity interact.

**Proven example (100% failure rate)**: cliffy-command-aliases -- register a local alias AND a global alias on the SAME command, call clearRegisteredAliases(), assert the global survives. 8/8 failing agents across THREE different architectural variants all failed. Variant A: shared map with .clear(). Variant B: separate maps but clears both. Variant C: separate maps, preserves globals correctly, but getAliasRegistry() only walks parents for inherited globals, omitting own-command globals.

**How to design this pattern**:
1. Feature X and feature Y normally apply to different entities
2. Create a test where X and Y apply to the SAME entity
3. The obvious parent-child test passes; the same-entity test catches subtler bugs
4. Verify your test catches 2-3 architecturally distinct wrong implementations

### 3. Convenience Method vs Default Constructor

A convenience method needs to initialize a subsystem, but calling the existing public setup method includes defaults the convenience method should NOT include.

**Proven example (60% failure rate)**: cliffy-output-format -- withOutputFormat() needs to set up the output formatting system. Agents call outputFormat() (the public setup method) which registers built-in formatters. But withOutputFormat() should only set up CLI options without adding built-ins. Test: call withOutputFormat() with one custom formatter, assert ONLY that formatter is registered.

**How to design this pattern**:
1. Public method A sets up a subsystem with sensible defaults (built-ins, initial state)
2. Convenience method B needs the same subsystem but with different initial state
3. The obvious implementation: B calls A internally
4. Test that B's result has ONLY what B explicitly added, not A's defaults

### 4. Pipeline Ordering Traps

Features must execute in a specific order, but agents implement them as independent passes or in the wrong sequence.

**Proven example (25-50% failure rate)**: dasel-csv-options -- trim-before-null-matching on read, trim-before-quoting on write, strict-validation-after-null-substitution. Agents implement null substitution as a separate early-return branch, so strict validation runs on the pre-substitution empty string instead of the post-substitution null string. 3/11 Diamond failures.

**How to design this pattern**:
1. Feature A transforms data (trim, substitute, normalize)
2. Feature B validates or formats data (strict check, quoting, escaping)
3. The correct order: A then B (transform first, validate/format the result)
4. Test with data where A's output changes B's behavior
5. The trap: agents implement B before A, or give A a bypass that skips B

### 5. Pre-existing Code Mutation (Go/CLI Integration)

New code must interact with existing code that mutates shared state. Agents place their code AFTER the mutation instead of BEFORE.

**Proven example (50% failure rate)**: dasel-multi-file -- existing run.go has o.InFormat = o.OutFormat crossover logic for stdin. Agents add file-loading code that reads o.InFormat AFTER this mutation, so all files are loaded with the output format instead of auto-detecting from extension. The fix: capture originalInFormat := o.InFormat before the crossover block.

**How to design this pattern**:
1. Existing code has a state mutation in a function agents will modify
2. New feature code needs the PRE-mutation value
3. The mutation is legitimate for its original purpose (stdin handling)
4. Agents read the existing code, understand it, but compose their code AFTER it
5. Test with input where the mutation changes behavior (different in/out formats)

### 6. Shared LLM Blind Spots

When a general constraint is followed by specific examples, ALL agents implement only the specific examples.

**Proven example (100% failure rate)**: cliffy-output-format -- "only the returned object or array triggers formatting. If the action returns undefined or null, no formatting occurs." 14/14 agents guarded only null/undefined, missing the broader "only object or array" constraint.

**How to design this pattern**:
1. State a GENERAL rule: "only X triggers behavior"
2. Follow with SPECIFIC examples: "Y and Z do not trigger it"
3. Test with a case NOT in the specific examples (strings, numbers, booleans)
4. Agents will guard only Y and Z, missing the general rule
5. Fix: remove the specific examples or restructure so the general rule stands alone

### 7. Symmetric Read/Write Operations

When a feature has a read path and a write path, agents implement the read side correctly but miss the write-side symmetry.

**Proven example (45% failure rate)**: dasel-csv-options -- null substitution on read (string "NA" becomes model null) works. But on write, agents add an isNull check that returns the null string directly, bypassing quoting. If the null string contains the delimiter or quote character, the output is invalid CSV.

**How to design this pattern**:
1. Feature has a reader side (parse input, transform values)
2. Feature has a writer side (format output, reverse-transform values)
3. Both sides must route through the same validation/formatting pipeline
4. Test the writer side with values that trigger pipeline behaviors (quoting, escaping)
5. The trap: agents implement the writer as a simple reverse lookup, not a full pipeline participant

### 8. Dead-Code Tautological Checks

Agents write validation code that is structurally impossible to trigger.

**Proven example (45% failure rate)**: dasel-csv-options -- agents build a values list by iterating over a headers list, then check len(values) against len(headers). The check is always true because values was built FROM headers. The correct approach: separately query the actual row's key count via row.MapKeys().

**How to design this pattern**:
1. Require a validation check (e.g., row has correct number of columns)
2. The data is accessed through an iterator that inherently produces the right count
3. The correct implementation queries the raw data source independently
4. Test with actual ragged data where the raw source has different counts

### 9. Cross-File Thoroughness

Agents update one file but miss a second file with the same pattern.

**Proven example (36% failure rate)**: dasel-csv-options Diamond -- description says "update CLI help text in existing commands." Agents find and update query.go but fail to grep for all occurrences in interactive.go. Reflection-based test (inspecting struct tags on BOTH QueryCmd AND InteractiveCmd) catches the gap.

**How to design this pattern**:
1. Require updating a pattern that appears in 2+ files
2. Test with reflection or introspection that verifies ALL instances were updated
3. Don't enumerate the files in the description -- say "existing commands" (plural)
4. The first file is easy to find; the second requires grepping

### 10. Error Type Consistency Across Code Paths

Agents define the correct error type and use it in the main path, but separate code paths return raw errors.

**Proven example (33% failure rate)**: dasel-multi-file -- FileLoadError defined correctly, used in file-loading path. But path resolution/stat returns raw fmt.Errorf errors without wrapping in FileLoadError. Test uses errors.As(&fileLoadErr) and fails on the unwrapped path.

**How to design this pattern**:
1. Define a typed error for a feature
2. The main code path uses it correctly
3. Secondary code paths (validation, initialization, cleanup) return raw errors
4. Test with errors.As/errors.Is on ALL code paths, not just the primary one

---

## Complexity Scoring Rubric for Olympus

Before submitting, rate your challenge on these dimensions:

| Dimension | Score 1 (Too Easy) | Score 3 (Olympus target) | Score 5 (Diamond target) |
|-----------|-------------------|------------------|-----------------------------|
| **Architecture Novelty** | Copy existing pattern | New integration pattern | No codebase precedent |
| **Cross-Package Scope** | Single package | 2-3 packages | 5+ packages with complex wiring |
| **Feature Interactions** | Independent features | 2-3 features interact | 5+ interacting features |
| **State Management** | Stateless | Ordered pipeline | Multi-phase state machine |
| **Edge Cases** | None tested | 3-5 same-object/ordering cases | Edge cases dominate tests |
| **Design Decisions** | One obvious approach | 2-3 valid approaches, only 1 matches tests | No obvious correct approach |

**Bias toward maximum difficulty down to the solvability floor.** Score 3-4 is the Olympus band; a score-5 design across dimensions is the Diamond TARGET, not an unfair one — route a near-0-pass design to Diamond + hints rather than dialing complexity down. Fairness does NOT come from capping difficulty; it comes from documenting every tested behavior in meta.md (≤1 codebase-inferable requirement). Score 1 in any dimension means the challenge is pattern-followable.

---

## Complexity Progression Examples

### Level 1 (TOO EASY -- Reject)
"Add a new format parser following the existing JSON/YAML/TOML pattern in the parsing/ directory."
- Pattern-followable. Agents copy and adapt. 100% pass rate.

### Level 2 (STILL TOO EASY -- Reject)
"Add a new subcommand with 3 options that modify output behavior."
- Single package, independent features, obvious implementation. 80%+ pass rate.

### Level 3 (GETTING THERE -- Needs More)
"Add a new feature that requires a new file and modifications to 2 existing files with public API surface."
- Meets LOC/file requirements but lacks cross-cutting interactions. 40-60% pass rate.

### Level 4 (ACCEPTABLE -- Minimum Bar)
"Add a feature with read/write symmetry that must integrate with the CLI layer, requires pipeline ordering between 3 subsystems, and includes same-object edge cases."
- Cross-package, cross-cutting concerns, ordering traps. Historically 20-35% pass rate; the upper end (>20%) is now too easy and must be hardened to <=20%.

### Level 5 (IDEAL TARGET)
"Add a multi-subsystem feature (wizard/config/middleware/formatting) with stateful callbacks, cross-cutting validation that must interact with existing subsystems, same-object edge cases, pipeline ordering dependencies, and convenience methods that must NOT include defaults."
- Multiple proven trap patterns combined. Novel architecture required. 8-20% pass rate.

---

## The Explicitness-Difficulty Spectrum (Olympus-Specific)

### Description Explicitness Controls Difficulty

From real evaluations:

| What's in meta.md | Pass Rate | Notes |
|-------------------|-----------|-------|
| Full API signatures + implementation hints | 100% | dasel-reduce (pattern copy) |
| Full API signatures + behavioral descriptions | 30-60% | Standard problems |
| Prose signatures + behavioral framing | 15-30% | Approved problems |
| Prose signatures + minimal behavioral framing | 8-17% | Hard approved problems |
| Tightened description + cross-cutting tests | 2/11 (18%) | Diamond approved |

### What to Include (Fairness Requirements)
1. **Exported type/field names** when tests construct them by name
2. **Return types** when different from existing patterns
3. **Parameter ordering** when tests depend on it
4. **Sync vs async** for all public methods
5. **Pre-existing exports** that tests import
6. **Error conditions** that tests verify

### What to Withhold (Difficulty Levers)
1. **Which file to put code in** -- say "from the command module" not "in command/output.ts"
2. **Implementation patterns** -- say "self-registers" not "uses init() with blank import"
3. **Pipeline ordering** -- describe features independently, let agents figure out ordering
4. **Default behavior for unspecified paths** -- if a feature should be a no-op for certain types, don't list every excluded type
5. **Cross-file locations** -- say "update help text in existing commands" not "update query.go and interactive.go"

### The Three Description Traps (Use Deliberately)

1. **General rule + specific examples** -- agents implement only the specific examples
2. **Same-object vs cross-entity** -- agents test only parent-child, never same-object
3. **Convenience method phrasing** -- "initializing" is read as "call the default constructor"

---

## Recipe for Approved Olympus Challenge (7/7 or DIAMOND)

1. **Repository**: Niche repo with 500+ stars, permissive license, recent activity. Niche frameworks (cliffy, dasel, yaegi) beat popular ones.

2. **Feature selection**: Must require NOVEL architecture, not pattern-followable. Check: "If I remove all new code, can an agent recreate it by copying an existing similar feature?" If yes, skip it.

3. **Cross-package scope**: Touch 2+ packages minimum. Include CLI flag registration or public API surface that forces multi-package navigation.

4. **Test design**: 15-35 tests. Include at least:
   - 3-5 cross-feature interaction tests (2-3 features combined)
   - 1-2 same-object edge case tests
   - 1-2 pipeline ordering tests
   - Error path coverage
   - Tests that compile and FAIL on base code

5. **Description**: Prose signatures (not Go types or TS interfaces). Every testable behavior mentioned. No implementation hints. Tighten until only top-tier models can decode exactly what's needed.

6. **Solution**: ≥450 LOC design floor (400 = platform auto-block), 3+ files, matching repo style exactly. Comments match repo convention (default NONE), no dead code, no scope creep.

7. **Patch generation**: Python subprocess, UTF-8, LF line endings. Diff against BASE_COMMIT.

8. **Validation cycle**:
   ```
   git checkout $BASE_COMMIT && git clean -fd
   git apply test.patch
   ./test.sh base    # PASS
   ./test.sh new     # FAIL
   git apply solution.patch
   ./test.sh base    # PASS (no regressions)
   ./test.sh new     # PASS
   ```

9. **Iteration**: Expect 3-20 rounds. Change ONE thing per iteration. Track in feedback.md.

10. **Evaluation analysis**: 
    - ALL agents fail same test = description gap (fix meta.md)
    - Agents fail DIFFERENT tests = genuine difficulty (keep it)
    - 1-2 tests away from passing = add fairness fix + compensating difficulty test

---

## What Makes a Challenge Hard (Proven Hierarchy)

### Tier 1: Nuclear Traps (60-100% failure rate)
- Shared LLM blind spots (general rule + specific examples)
- Same-object interaction edge cases
- Pre-existing class export omission
- Convenience method reusing defaults
- **Public-boundary wiring gap — build the value, miss the consumer arm (70% failure, chai-array-type Diamond)**

### Tier 2: Strong Traps (30-60% failure rate)
- Cross-cutting pipeline ordering
- Writer-side symmetry bypass
- Pre-existing code mutation ordering
- Error type consistency across code paths
- Dead-code tautological checks
- **Implied requirement via flag existence (82% failure, nmap-scan -- Tier 1 strength)**

### Tier 3: Moderate Traps (15-30% failure rate)
- Cross-file thoroughness gaps
- Cancelled operation push-before-check ordering
- Package placement errors
- Cobra RunE stderr contamination (18% failure, nmap-scan)
- Invalid type validation exit 2 (27% failure, nmap-scan)
- Existing repo constant vs spec name mismatch (18% failure, nmap-scan -- `md` vs `markdown`)

### Tier 4: Weak/Busted Traps (0-10% failure rate)
- Pattern-followable features (BUSTED -- 0% difficulty)
- Individual feature tests (agents pass ~100%)
- Straightforward error handling (agents implement correctly)
- Registry CRUD operations (agents handle perfectly)
- Subcommand inheritance basic cases (agents traverse parents correctly)
- Multi-format output implementation (text/json/csv/html -- agents handle competently, Lite tier only)
- Lexicographic vs numeric sort semantics (9% failure, nmap-scan)
- Port format int vs combined string (9% failure, nmap-scan)

### Key Insight
Difficulty comes from INTERACTIONS between features, not from individual feature complexity. A single feature can be arbitrarily complex and agents will still implement it correctly if it doesn't interact with other features. The moment two features must share a pipeline, state, or ordering constraint, agents fail.

---

## Final Reminder

Every time you design an Olympus challenge, ask yourself:

1. **"Can an agent copy an existing pattern to solve this?"** -- If yes, the challenge is pattern-followable and will have 80-100% pass rate regardless of test count.

2. **"Do any two features need to interact through a shared pipeline?"** -- If no, agents will implement them independently and pass. Add a cross-cutting interaction.

3. **"Does the description accidentally give away the implementation?"** -- Read every sentence and ask if removing it would increase difficulty without being unfair. If so, remove it.

4. **"Does the test suite include same-object edge cases?"** -- If only parent-child tests exist, add at least one same-object test.

The goal is not to trick AI agents with ambiguity. The goal is to present genuinely complex integration challenges where getting the architecture right requires deep understanding of the codebase, careful handling of cross-cutting concerns, and correct pipeline ordering -- skills that current AI agents consistently lack.

---

## Confirmed Anti-Agent Pattern: Tokenizer Completeness (node-minify/node-macros)

**Pattern**: Require exclusion of multiple syntactic contexts (strings, comments, template literals, AND regex literals). Agents reliably handle 3 out of 4 but miss the fourth.

**Why it works**: Agent mental models categorize "things to skip in source code" as strings and comments. Template literals are a stretch. Regex literals are a third category that requires intentional effort. 2/12 agents missed regex despite it being explicitly listed in the description.

**Difficulty lever**: Each additional exclusion category compounds the tokenizer complexity. For higher difficulty, add more categories: JSX expressions, tagged template literals, heredocs, etc.

**Confirmed data**: node-minify Lite tier, 42% pass rate. The 2 regex-literal failures and 3 underscore-boundary failures account for 5/7 total failures.

## Confirmed Anti-Agent Pattern: Framework Mode Switches (node-minify CLI integration)

**Pattern**: The target framework has a mode switch (e.g., `settings.content` activates "in-memory mode" which skips file output). Agents integrate by setting the obvious property without tracing the downstream effect.

**Why it works**: Agents read the immediate API surface but don't trace through multi-package call chains. Setting `settings.content` looks like the right way to provide transformed input, but it actually disables output file writing.

**Difficulty lever**: The deeper the call chain (more packages to trace), the more likely agents fail. node-minify has a 3-package chain: cli -> core/setup -> utils/run.

**Confirmed data**: 2/12 agents hit this trap. Both set settings.content and got "File does not exist" errors.

## Confirmed Anti-Agent Pattern: Implied Requirement via Flag Existence (nmap-formatter diff)

**Pattern**: A CLI flag's stated purpose logically implies an underlying behavior that is never listed as an explicit feature. Agents implement the flag plumbing (metadata field, CLI registration) but never implement the behavior the flag is supposed to control.

**Why it works**: Agents process the explicit change-type enumeration (hostname, os_detection, port_state, etc.) as their feature checklist. They implement `--ignore-timestamps` as a metadata boolean but never ask "what does this flag actually suppress?" Timestamp comparison is not listed alongside the eight named change types, so it falls into a cognitive blind spot -- agents implement the flag's form but not its function.

**Example**: nmap-formatter diff subcommand. Description says `--ignore-timestamps flag to suppress timestamp-only differences`. This implies that WITHOUT the flag, timestamp differences must be detected and cause exit code 1. 9/11 agents (82%) plumbed the flag into metadata and CLI but never compared any timestamp fields (nmaprun.start, host starttime/endtime). The flag was a no-op because the underlying detection was never built.

**How to design this pattern**:
1. Add a flag that "suppresses" or "disables" a specific behavior
2. Do NOT list the suppressed behavior as an explicit feature/change-type
3. The flag's purpose only makes sense if the behavior exists by default
4. Test that without the flag, the behavior is active (exit code, output, state)
5. Agents will implement the flag plumbing (config struct, CLI binding) but skip the underlying logic

**Difficulty lever**: The more indirectly the requirement is stated, the higher the failure rate. Explicit: "compare timestamps" (low failure). Implicit via flag: "flag to suppress timestamp differences" (82% failure). The flag creates a false sense of completion -- agents think they handled timestamps because they wired the flag.

**Confirmed data**: nmap-formatter Olympus tier, 9% pass rate (1/11). Timestamp detection is the dominant trap at 82% failure. All verdicts are FAIL_MISSED_REQUIREMENT (fair, inferable). AI reviewer confirmed: "the flag name and its purpose only make sense if timestamps participate in difference detection."

## Confirmed Anti-Agent Pattern: Byte-as-Rune UTF-8 Corruption (foundational Go knowledge gap)

**Pattern**: A decoder iterates input bytes via `r := rune(input[pos])` then writes via `sb.WriteRune(r)`. For ASCII the round-trip is fine, but any byte ≥ 0x80 is interpreted as a Latin-1 codepoint and re-encoded as multi-byte UTF-8, corrupting the original UTF-8 sequence.

**Why it works**: Agents reach for byte iteration "fast" without thinking about UTF-8 semantics. The bug is invisible until input contains a non-ASCII byte, so prior tests using ASCII content all pass. The canonical Go patterns — `for i, r := range s` or `utf8.DecodeRune(input[pos:])` — are foundational language knowledge, but agents who do not consciously think about byte vs rune semantics reach for the wrong primitive. This is FAIL_KNOWLEDGE_GAP territory: not a missed requirement, not unfair, not Wrong Logic — a fundamental misuse of a standard language feature.

**Example**: ferret-csv-codec attempt 4. Test `TestCSV_Decode_TrimLeadingSpace_OnlySpaceAndTab_NotOtherWhitespace` decodes input `col\n<NBSP>value\n` with TrimLeadingSpace=true. NBSP (U+00A0) UTF-8-encodes to 0xC2 0xA0. Failing agents emit two separate runes — U+00C2 (Â) and U+00A0 (NBSP) — which UTF-8-encode to 4 bytes giving `Â<NBSP>value` instead of `<NBSP>value`. Reference solution uses `peekRune`/`advance` and slices the original byte range. 2/12 Nova agents (17%) failed exactly this way; both verdicts FAIL_KNOWLEDGE_GAP.

**How to design this pattern**:
1. Build a parser/decoder/lexer where byte iteration is plausible (CSV reader, INI parser, TSV decoder, log scanner, regex tokenizer, etc.)
2. Include at least one test that exercises a multi-byte UTF-8 codepoint inside a "raw scan" path — typically an unquoted field, a comment, an identifier, or any region where the parser passes content through verbatim
3. Pick a codepoint with bytes ≥ 0x80 and ≥ 2 bytes long: NBSP (0xC2 0xA0), em-dash (0xE2 0x80 0x94), accented Latin (0xC3 0xA9 = é), CJK (0xE4 0xB8 0xAD = 中)
4. Assert exact round-trip: `assert val.String() == "<NBSP>value"`
5. The reference solution slices original bytes (`return string(data[start:pos])`) or uses `utf8.DecodeRune` to advance one full codepoint

**Difficulty lever**: Tier 2 (15-30% failure rate range). The trap is universal — any decoder where the agent might reach for byte-by-byte iteration is exposed. Compounds with: leading-trim rules ("only ASCII space and tab"), case-sensitivity rules, "preserve content verbatim" rules. Each compounding rule that constrains the surface text near the multi-byte codepoint forces the agent to confront the UTF-8 boundary.

**Anti-traps (do not use these)**:
- Putting the multi-byte codepoint inside a quoted field where the decoder copies bytes wholesale — most agents handle this correctly because quoted-field parsing typically works in byte-mode
- Asking for "Unicode-aware" trimming (e.g., trim all `unicode.IsSpace`) — that flips the trap: agents using `unicode.IsSpace` are now correct, agents using only ASCII space/tab fail
- Mentioning UTF-8 in the description in a way that primes the agent to use `utf8.DecodeRune` — keep UTF-8 implicit (only mention BOM stripping) so the trap surfaces

**Confirmed data**: ferret-csv-codec Mars Solid, 50% pass rate (6/12). NBSP byte-as-rune corruption is the single most cost-effective hardening test from attempt 4 — caught 2/12 Nova agents who otherwise would have passed. All other 13 hardening tests in attempt 4 served as fairness coverage but did not drive failures in this run.

**Transferability**: any Go problem whose solution involves a parser, decoder, scanner, or string processor that reads input byte-by-byte. Especially strong combined with a description rule that says "only ASCII X" (NBSP-style trim trap) or "preserve content verbatim" (round-trip trap).

## Confirmed Anti-Agent Pattern: Cross-Execute Live State Binding (yaegi-eval-in-package)

**Pattern**: A new API extends an existing Compile + Execute pair (or any compile-once, execute-many pair) to operate against an arbitrary previously-loaded scope. The new code must keep symbol identity between the compiled artifact and the live scope's storage. Agents subtly break this identity by re-registering scope metadata, gating wrapped-main appendage on the original `pkgName == mainID` check, or creating fresh global storage during compilation. The existing API (no new code) reads live values; the new API silently captures snapshots.

**Why it works**: The live-state contract is implicit in the existing Compile/Execute pipeline. Agents read the existing code, understand it works, and extend it -- but the extension introduces one of three precision-of-wiring mistakes:
1. Keeping a conditional that gates wrapped-main appendage on `pkgName == mainID`. Non-main packages skip the append, the wrapped body never runs on Execute, mutations silently no-op.
2. Re-registering `srcPkg[pkgID]` or `pkgNames[pkgID]` on every compile call. Each compile creates a fresh symbol identity, so the previously-compiled `*Program` reads from storage that subsequent compiles overwrote.
3. Renaming the parser wrapper (e.g. `func main()` to `func _()`) which both creates fresh closure storage AND breaks every position-reporting baseline test in the codebase via character offset.

The symptom is identical across all three: a `*Program` compiled before a mutation, re-Executed after the mutation, returns the pre-mutation value. The test asserts `expected 99, got 41` (or similar pre/post-mutation pair).

**Example**: yaegi-eval-in-package, `TestCompileInPackage_program_reads_live_package_state_after_in_pkg_mutation`. The test compiles `Counter` against package `foo`, executes it (gets 41), runs `EvalInPackage("foo", "func() { Counter = 99 }()")` to mutate the package var, then re-executes the same `*Program` (must return 99). 11 of 12 failing agents flunked this single test the same way despite diverging on every other dimension. 1 of 13 runs passed by using the reference shape (shared `compilePipeline` helper, always append `gs.sym[mainID]`, reuse existing package scope without re-registering).

**How to design this pattern**:
1. Pick a codebase with an existing Compile + Execute pair (or any "compile-once, execute-many" infrastructure) where the existing API already reads live state at runtime.
2. Add a new API that extends Compile to operate against a non-default scope (different package, different namespace, different module).
3. The naive extension copies the existing CompileAST flow but threads a different scope name through. The bug surfaces because the original flow has scope-registration logic gated on the default case.
4. Test with: compile against the new scope, execute (snapshot value A), mutate via a sibling API call, re-execute the SAME compiled artifact (must read mutated value B). Tests asserting A != B are passable; tests asserting B == mutated_value catch the trap.
5. Verify the trap catches at least 2-3 architecturally distinct wrong implementations -- here we observed (a) gating-conditional retention, (b) srcPkg re-registration, (c) wrapper-rename closure-fresh storage.

**Difficulty lever**: Tier 1 (60-100% failure rate). Confirmed at 85% in 13 runs. The trap is a single test that catches a single wiring mistake, but the wiring mistake has three architecturally-distinct flavors so agents converge on it from different directions. The trap requires NO new test category -- it lives inside the same API surface agents are already implementing, which makes it cost-efficient (one test = ~10x difficulty multiplier).

**Anti-traps (do not use these)**:
- Pairing this trap with a runtime-panic-via-IIFE test (e.g. `func() { panic("x") }()`) -- the IIFE-via-retry parser path is its own trap and stacks failures rather than focusing them. Removing the IIFE runtime tests in yaegi-eval-in-package was correct.
- Asserting exact panic message text or stack frame -- live-state binding is the only fairness-clean form of this trap.
- Requiring the test to detect the mutation via reflection on the `*Program` -- behavior must be observable through public API only.

**Confirmed data**: yaegi-eval-in-package Mars Solid, 7.7% pass rate (1/13). Single-test dominance: 11 of 13 runs hit only this one test. One agent (run 11) used the reference pattern and passed cleanly. Pass-rate landed inside the Mars ≤30% band (0% = reject, >30% = too easy); it also sits squarely in the Olympus ~10% target.

**Transferability**: any Go problem extending an existing compile/execute API to operate against an arbitrary scope. Strong fits: any tree-walking interpreter (yaegi, goja, tengo), any module-system extension, any namespace-isolated evaluation. The trap also transfers to non-Go: any TypeScript problem extending `vm.Script` + `vm.Context`, any Python problem extending `compile()` + `exec()` against a custom `globals` dict, any Rust problem extending an existing query plan + execute pair.

## Confirmed Anti-Agent Pattern: Internal-Key vs Canonical-Name Dual Map (yaegi-completion)

**Pattern**: The codebase exposes BOTH a raw lookup map (with internal/file-suffixed keys) AND a separate canonical-name map. The user-facing API requires the canonical name. Agents iterate the obvious raw map first and emit internal keys as user-facing values.

**Why it works**: Agent's natural research path is to find the most direct symbol map and iterate it. The canonical-name map is in a separate field with a different name and lives one indirection away (path -> name lookup). Without explicit hint, agents never realize the dual representation exists. Even WITH the hint "report under conventional short names, not the file-suffixed keys", 5 of 12 agents still emitted the internal keys -- the trap is so structurally natural that symptom hints alone don't catch all agents.

**Example**: yaegi-completion. Imported packages stored in `interp.scopes[mainID].sym` under keys like `fmt/_.go` (synthetic source-file keys), but canonical short name lives in `interp.pkgNames[pkgPath]` (separate map). Reference solution iterates `interp.binPkg`/`interp.srcPkg` directly using `pkgNames[pkgPath]` for short-name lookup. 5 of 12 Olympus eval runs emitted `fmt/_.go` as the package name despite explicit hint.

**How to design this pattern**:
1. Identify a target codebase that maintains parallel maps: one for internal tracking, one for user-facing names
2. Make the user-facing tests assert the canonical name
3. Spec the requirement behaviorally ("under their conventional short names") without naming the canonical map
4. The bait: the obvious scope/symbol iteration produces the internal key
5. The fix: agent must read multiple files (use.go, gta.go, etc.) to find the canonical mapping

**Difficulty lever**: Tier 1 (40-50% failure rate). Cross-file research requirement compounds the trap. Even "symptom hints" (e.g., "not the file-suffixed keys") only flip ~30% of failing agents because the natural iteration path is too tempting.

**Confirmed data**: yaegi-completion Olympus tier, 8.3% pass rate (1/12). Internal-key trap accounts for 5/11 failures, consistently across multiple agent variants.

**Transferability**: any feature where the codebase maintains "tracking metadata" (file paths, source positions, internal IDs) parallel to a public name registry. Common in interpreters, compilers, plugin systems, and serialization libraries.

## Confirmed Anti-Agent Pattern: Mutex Coverage Gap (untracked compile path)

**Pattern**: Existing code holds a public mutex (e.g., `interp.mutex`) at SOME entry points but NOT at internal compile/transform passes that mutate shared state. Agents naturally lock new concurrent-API code with the SAME mutex, assuming the existing code path honors it. The race detector catches this universally.

**Why it works**: Agents grep for the existing mutex, see it's the synchronization primitive, and reuse it. They don't trace the compile pipeline deep enough to discover that gta/cfg/transform passes don't acquire it. The bug is invisible without -race detector.

**Example**: yaegi-completion. `Eval -> compileSrc -> CompileAST -> gtaRetry -> gta -> cfg` writes to `scope.sym` and `interp.universe.sym` at multiple call sites without taking `interp.mutex`. Reference solution introduces a SEPARATE `completeMu` RWMutex with `eval()` taking RLock at top and Complete taking Lock. Multiple Evals share RLock; Complete waits for any in-flight compile.

**How to design this pattern**:
1. Pick a codebase with an existing public mutex used incompletely
2. Add a new concurrent-API surface (e.g., Complete/Inspect/Snapshot) that races against compile-time mutations
3. Test with concurrent-Eval-during-compile assertion under -race detector
4. The trap: agents reuse the existing mutex; compile passes still mutate without it
5. The fix: introduce a NEW mutex; modify the compile entry point to take it

**Strong required hint**: "synchronization must extend across Eval's compilation phase, since locking only inside Complete leaves compilation-time scope writes unprotected." Without this hint, 100% of agents fail. Description-quality bot consistently flags it as over-spec; load-bearing for pass rate.

**Difficulty lever**: Tier 1 (90-100% failure without hint, 30-40% failure even with full hint). The reentrancy follow-up trap (RWMutex re-acquired in nested compile steps deadlocks behind a pending writer) catches additional agents.

**Confirmed data**: yaegi-completion Olympus tier. Pre-hint cycles: 0% pass on TestCompleteConcurrentEval. Post-hint: 2 of 12 still raced (Complete-only lock pattern).

**Transferability**: any interpreter/compiler/plugin system where a public API needs to coexist with internal mutate-during-compile passes. Especially strong in Go projects with `sync.RWMutex` because the reentrancy trap is unique to RWMutex semantics.

## Confirmed Anti-Agent Pattern: Universe-First Iteration with Name-Dedup Inverts Shadowing

**Pattern**: Spec requires inner-scope-shadows-outer semantics. Agents iterate scope chain from OUTER (universe/builtins) to INNER (locals), use a `seen` map keyed by name to dedup. Result: outer entries win because they're added FIRST and the dedup blocks later overwrites. Shadowed builtins still appear in completion.

**Why it works**: The `seen` map dedup pattern is universally idiomatic in Go for collection deduplication. Agents apply it instinctively without considering iteration order. The spec says "inner shadows outer" but doesn't dictate iteration direction; agents pick the natural top-down walk.

**Example**: yaegi-completion. 3 of 12 Nova runs (otherwise-substantial implementations) iterated `interp.universe.sym` first, then `interp.scopes[mainID].sym`, with name-keyed dedup. After `len := "shadowed"`, the builtin entry is added first and the var is suppressed. The test sees `[{Name:len Kind:builtin}]` with no var.

**How to design this pattern**:
1. Spec a feature that requires shadowing semantics (closer-scope wins)
2. Provide multiple symbol sources (universe, package scope, local scope)
3. Test with same-name shadow case (e.g., `len := "x"` shadows builtin)
4. The trap: agents iterate outer-to-inner with seen-map dedup
5. The fix: iterate INNER-FIRST, OR overwrite entries instead of skipping

**Difficulty lever**: Tier 2 (25-30% failure). Affects even agents who otherwise pass 44/45 tests. The fix is one-line (reverse iteration order) but invisible to agents who don't construct an explicit shadow test mentally.

**Confirmed data**: yaegi-completion. Three independent runs (different LOC, different message counts, different overall verdicts) all converged on the same shadowing inversion bug.

**Transferability**: any feature with scope chain semantics: completion APIs, name resolution, type lookup, configuration overrides, plugin precedence. The trap surfaces whenever "X overrides Y" semantics meets natural iteration order.

## Confirmed Anti-Agent Pattern: Two-Sentence Naming Spec Inversion (yaegi-callstack-postmortem)

**Pattern**: Description states a naming rule across two sentences where the SECOND sentence implicitly contradicts the FIRST. Agents read sequentially, latch onto the first rule, and produce names that satisfy sentence 1 but fail sentence 2's logical implication.

**Example**: yaegi-callstack-postmortem meta.md says "Names are unqualified: top-level functions appear as `f`, not `pkg.f`. Pointer-receiver methods and value-receiver methods share the same frame name; the leading `*` is never included." Sentence 1 anchors agents to "no qualifier ever". Sentence 2 mentions stripping `*` from pointer receivers, which is meaningful ONLY if the receiver type IS in the name. 7 of 11 failing runs (64%) returned `M` instead of `T.M` for method frames.

**Why it works**: Agents read top-down and apply the first concrete rule encountered. The second sentence's deeper implication ("`*` is stripped" → "the type is preserved without `*`") requires inference; sequential agent reasoning grabs the surface rule and discards the context. Multiple Orion runs (Run #1, #2, both Orion→Orion) hit this — Orion is decisive but commits to the first interpretation it finds.

**How to design this pattern**:
1. State a general rule: "X is Y"
2. Follow with a refinement that only makes sense if X is NOT fully Y
3. The refinement uses normalization language ("strip", "drop", "remove") that requires the underlying field to exist
4. Test asserts the refined behavior (`T.M` not `M`)
5. Trap survives even with one corrective example because agents skim for the high-level rule

**Difficulty lever**: Tier 1 (60-70% failure rate). Confirmed at 64% across 11 failing runs. The trap is harder to defuse than a single-sentence ambiguity because EITHER sentence alone is consistent with a wrong implementation; only their combination requires the right one.

**Anti-traps (do not use these)**:
- Pairing the naming spec with a fully concrete example (`T.M` literal) — destroys the trap; pass rate jumps
- Splitting the two sentences across separate paragraphs — agents handle paragraphs as independent units, so the conflict never surfaces
- Asking for matching against a regex — turns into FAIL_TEST_MISMATCH (unfair)

**Confirmed data**: yaegi-callstack-postmortem Mars Strong, 8.3% pass rate (1/12). Method-name trap caught 7/11 fails. Single PASS run produced names with receiver prefix on first try.

**Transferability**: any feature with structured naming conventions where a general "no qualifier" rule meets a specific "strip part X" rule. Common in: stack-trace APIs, debugger frame APIs, error-string formatters, log-format generators.

## Confirmed Anti-Agent Pattern: Capture-Before-Recover-Defer Ordering (yaegi-callstack-postmortem)

**Pattern**: Existing recover-defer infrastructure runs user-defined deferred handlers BEFORE the new feature's capture logic. When user defers contain `recover()`, the recovered value is consumed and the new feature's downstream guard (`if recovered != nil`) sees nothing. Agents who naturally place new code at the END of the existing defer body trigger this.

**Example**: yaegi-callstack-postmortem `runCfg` defer at `interp/run.go:209`. Reference solution places `captureStack(f, oNode)` IMMEDIATELY after `f.recovered = recover()`, BEFORE the `for _, val := range f.deferred { val[0].Call(val[1:]) }` loop. 4 of 11 failing runs (36%) placed captureStack AFTER the deferred-loop, so a goroutine's `defer func() { recover() }()` consumed `f.recovered` first; the subsequent `if f.recovered != nil` check in those runs was always false for goroutine panics that recover internally, leaving 0 captured frames.

**Why it works**: Two competing intuitions defeat agents:
1. "Run user defers first, observe state second" — natural for non-recover-aware logic
2. "Recover only fires if outer frame has recover()" — agents reason about top-level Eval recovery, not in-frame goroutine recovery

The bug is INVISIBLE for the common case (panic propagates up to outer frame, outer's recover gets it, inner's `f.recovered` is preserved via re-panic). It surfaces ONLY for the goroutine-recovers-its-own-panic-in-same-frame pattern. Agents test their solution with multi-level panic chains, see the chains work, and never test the goroutine-internal-recover case.

**How to design this pattern**:
1. Pick a feature requiring observation of transient state (panic value, signal, lock state) inside an existing defer chain
2. Existing defer chain calls user-supplied callbacks (defers, signal handlers, finally clauses) that may consume the state
3. New feature must observe the state BEFORE user callbacks run
4. Test with a case where user callback consumes the state in the same frame (no outer observer)
5. The trap: agents place new logic at end of existing defer body; user callback wins the race

**Difficulty lever**: Tier 2 (30-50% failure rate). Confirmed at 36% across 11 failing runs. Compounds with goroutine-independence requirement — agents who pass the multi-level chain tests still fail goroutine tests because the bug is invisible without that specific scenario.

**Anti-traps (do not use these)**:
- Adding `Stack:` field to existing `Panic{}` struct — agents would extend the existing recover-error path which fires AFTER user defers anyway
- Spec hint "capture before user defers run" — load-bearing, but description-quality bot will flag as implementation prescription per LESSONS.md #12

**Confirmed data**: yaegi-callstack-postmortem Mars Strong, 8.3% pass rate (1/12). Capture-after-defer trap accounts for 4/11 failures (Runs #8, #9, #10, #12). All 4 failures concentrated on `TestStackTrace_goroutine_panic_stack_rooted_at_launched_function`.

**Transferability**: any host-language defer-aware feature where user callbacks may run before the new feature observes state. Strong fits: signal handlers, finalizers, async cancellation tokens, distributed-tracing span observers, allocator-tracking hooks.

## Confirmed Anti-Agent Pattern: `go/scanner` Operator Tokens Have Empty `lit`

**Pattern**: Agents tokenize source with `go/scanner` then reconstruct strings by concatenating `tok.Lit` for each token. Operator tokens (PERIOD, COMMA, LPAREN, RPAREN, etc.) return empty literal strings. The reconstructed source loses operators.

**Why it works**: `go/scanner` returns literal strings for IDENT, INT, FLOAT, STRING, CHAR. For operator tokens, `lit` is empty -- the operator's character is encoded in the `tok` field instead (token.PERIOD, token.COMMA, etc.). Agents who treat `lit` as "always the source text" lose dots and other operators silently.

**Example**: yaegi-completion. 1 of 12 Nova runs reconstructed selector base via `tok.Lit` concatenation. For tokens `[IDENT "tr", PERIOD, IDENT "L"]`, the rebuilt string was `trL` (PERIOD's empty lit dropped). `parser.ParseExpr("trL")` resolved as a single bad identifier; chained selector resolution returned nil.

**How to design this pattern**:
1. Require token-level source manipulation (selector base extraction, expression rewriting, etc.)
2. Test with multi-segment input that includes operators between identifiers (`a.b.c`, `f(x, y)`, `arr[i]`)
3. The trap: agents use `tok.Lit` reconstruction; operators silently drop
4. The fix: slice original source via `tok.Pos`/`tok.End`, OR walk tokens directly without string rebuilding

**Difficulty lever**: Tier 2 (8-12% failure). Less common than other traps because most agents avoid string reconstruction entirely, but catches the subset who try.

**Confirmed data**: yaegi-completion. 1 of 12 Nova runs failed exactly TestCompleteChainedSelector with "trL" reconstruction. All other tests passed.

**Transferability**: any feature requiring source-code manipulation via go/scanner, including: completion bases, refactoring tools, code generators, lint fixes. Less applicable for AST-level work (which uses go/parser directly).

## Meta-Pattern: Hint Dilution from Description-Quality Bot

**Meta-pattern**: Description-quality reviewer bot consistently flags load-bearing pass-rate hints as "over-specification" or "implementation prescription." Each removal round drops pass rate ~10-15pp. Authors face a real conflict between description-quality gate (must pass for submission) and pass-rate gate (must achieve 5%+ for Olympus Good).

**Why it matters**: The hints that catch the most agents (named internal traps, specific failure mode warnings) are EXACTLY what the bot flags. The bot's checklist:
- "Tests don't pin which mutex/where" -> bot drops mutex placement hint
- "Internal field names are agent's discovery" -> bot drops `interp.binPkg`/`pkgNames` mention
- "Implementation strategy not verified" -> bot drops "use go/scanner" recommendation

**Negotiating line that works**: keep the BEHAVIORAL requirement, drop the IMPLEMENTATION rationale.
- Keep: "Concurrent Eval calls must remain non-serialized."
- Drop: "Acquire RLock once at the top of Eval; reentrant locking deadlocks."
- Keep: "Imported packages must be reported under their conventional short names."
- Drop: "Use interp.pkgNames mapping; not the file-suffixed scope keys."

**HIGH-priority bot flags must be applied**; MEDIUM/LOW are optional. Contesting MEDIUM/LOW with empirical pass-rate data sometimes works ("dropping this clause cost us 4 of 10 runs") but HIGH always wins.

**When examples are load-bearing**: Bot frequently flags illustrative examples (math.Pi, fmt.Pr, foo.) as low-priority drops. Most are tone-only and dropping is fine. EXCEPTION: when the example anchors agents to a specific trap signal -- "math.Pi" specifically guides agents to the go/constant detection vector. Drop the example, lose the hint.

**Confirmed data**: yaegi-completion went through 5+ description revisions. Each cycle removing hints dropped pass rate proportionally. Final state: 8.3% pass with maximally-trimmed hints. Pre-trim peak (with all hints) was estimated 30-50% but blocked by description-quality FAIL.

## Confirmed Anti-Agent Pattern: Build-the-Value-but-Not-the-Wiring (Public Consumer Boundary)

**Pattern**: The agent implements a new value type / format / feature correctly in the INTERNAL layer (type, methods, storage, comparison) but fails to thread it out through the PUBLIC consumer boundary the tests actually observe — the SQL driver, the serializer, the CLI render path, the RPC codec. Internal unit reasoning is fully satisfied; the public surface arm is stubbed wrong or passes the raw internal value through.

**Why it works**: Agents reason locally and bottom-up — build the type and its storage, prove it in unit terms. The cross-architectural step (expose the value through the public API the consumer scans) is invisible to home/unit reasoning, so it gets a placeholder. It is the same class as cross-cutting interaction (the internal value and the public boundary are two subsystems that must agree), but the tell is sharper: most of the suite passes, only the observation-path tests fail, and they fail at the boundary before any value assertion runs.

**Example**: chai-array-type (Diamond). Agents built `ArrayValue`, byte encoding, element-wise comparison, the six array builtins — then returned the array RAW through the `database/sql` driver's `Rows.Next`, so `rows.Scan(&string)` fails with `unsupported Scan, storing driver.Value type types.ArrayValue into *string`. Three distinct wrong impls across 10 runs: `dest[i] = v` (raw value), a local wrapper `dest[i] = arrayValue{v: v}` (error names `driver.arrayValue`), and `dest[i] = v.Encode(nil)` (raw bytes — scan SUCCEEDS but the string is the binary encoding, so it equality-mismatches `"[3, 1, 2]"` vs `"n\x03312"`). Correct = render text in the driver arm exactly as the neighboring scalar arms do.

**How to design this pattern**:
1. Pick a feature whose result must cross a PUBLIC boundary to be observed (SQL driver / `Rows`, JSON or text serializer, CLI renderer, RPC codec, public report API).
2. Drive ALL tests through that boundary — scan into a plain `string`/parse the rendered output — and never assert internal structs. The boundary is the only observation path.
3. Leave the internal value type buildable from unit reasoning; the wiring arm is the trap.
4. Point at the neighboring scalar arms as the convention to mirror — this keeps it FAIR (a seasoned engineer follows the established driver/serializer pattern).
5. Spell out the canonical rendered form (sort order, quoting, brackets, separators) in the description so the boundary contract is documented, not inferred.

**Difficulty lever**: Tier 1 (60-100%; 70% measured). Dominant whenever the public boundary is the ONLY way the tests can see the feature. Compounds with a secondary delegated-error-wording trap (e.g. "the surfaced message must contain X" on a cast the boundary delegates).

**Anti-traps**: Do NOT also assert internal state in some tests — that hands agents a non-boundary path that passes and dilutes the trap. Watch the accidental-pass case: if the internal encoding happens to render as the expected text, the boundary bug hides; confirm the raw internal form is observably different from the rendered form (chai's `Encode` bytes are not the bracketed text, so even the scan-succeeds run still mismatched).

**Confirmed data**: chai-array-type, Diamond APPROVED 2026-06-07, 2/10 Castor (20%). 7/10 missed the driver-render boundary; 3/10 missed the "cannot" substring on the delegated overflow cast. The feared marquee wall (byte-sortable array encoding) was FREE — pre-built in the storage layer.

**Transferability**: any value-type / format / codec pick observed only through a public consumer API — SQL engines (driver/`Rows`/`Scan`), serializers (`MarshalText`/`String`/`MarshalJSON`), CLI renderers, type systems that surface through a public report, message codecs. **Design rule**: GREP the storage/encoding layer FIRST (it may be pre-built, like chai's comparator), then put the wall at the public consumer boundary, not the storage layer — that is where opus-4-8-class agents reliably stub instead of wire (reinforces the opus-4-8 depth law: decisive walls live in the real-codebase integration stack).

**Author strategy**:
1. Add ALL pass-rate hints first (don't optimize for bot)
2. Run pre-eval to identify which hints are flipping near-miss runs
3. When bot flags a hint, check if it's flipping any runs
4. If yes: contest with empirical data, accept compromise wording
5. If no: drop without protest

## Anti-agent pattern: the forced-representation trap (piccolo-to-be-closed, 6/10 biters, Olympus 2026-06-24)

The most effective single trap in piccolo's to-be-closed feature was not a marquee algorithm — it was a forced INTERNAL REPRESENTATION choice that is natural-but-wrong.

The feature requires tracking pending `<close>` slots. The obvious representation is a set/vector keyed by stack index (registers are the natural identity, and dedup looks like a sensible invariant). That representation is correct for straight-line code and even for a single loop pass, so it passes the simple reverse-order, return, break, and error tests. It is WRONG the moment a `<close>` local lives in a loop body: the loop reuses the same register every iteration, so a stack-index-keyed store registers the slot once and closes it once, when Lua closes it once per pass. The correct representation stores a slot per dynamic registration (`{stack, value, close_fn}`) with no register dedup.

Why this is a strong anti-agent trap:
- **The wrong choice is the natural first choice.** A competent engineer reaches for the register-keyed store; nothing in the happy-path tests punishes it.
- **It is shared, so it is interdependent.** The same store backs every close path (normal exit, return, break, goto, error unwind, coroutine.close). A local fix to any one path cannot surface the bug — only the representation change does. This defeats single-point patching, which is exactly the opus-4-8 / Castor failure mode.
- **It is misdirecting.** It surfaces as a wrong observable count ("aaa" vs "a"), and in one run as a non-terminating HANG, never as a message that names the actual cause.

**How to design this pattern**: pick a feature that needs internal bookkeeping with a "natural key" (stack slot, register, name, pointer) that is NOT unique across the dynamic executions the spec cares about (loop iterations, recursion, re-entry). Drive the happy-path tests so the natural key passes, then add ONE test that re-enters the same key (loop body, recursion) so only a per-instance representation passes. Keep the distinguishing test behavioral (observable order/count), not internal-state assertions. Combine with a second, independent block-exit subtlety (here: within-block goto must NOT close) so a single representation fix does not clear the whole suite.

**Confirmed data**: piccolo-to-be-closed, Olympus APPROVED 2026-06-24, 2/10 Castor (20%). Repeat-loop per-iteration close bit 6/10 (one as a hang); within-block goto bit 3/10. The two stacked, plus an explicit-error-name plumbing miss (2/10), held the band. The marquee-looking parts (error-unwind through a stackless executor, generic-`for` fourth value) were real but bit fewer agents than the quiet representation trap.

**Transferability**: any feature with internal lifetime/identity bookkeeping — scope/close tracking, symbol tables keyed by name vs binding, memo caches keyed by node vs node-instance, dedup sets in optimizer passes, register/slot allocators. GREP the spec for any construct that RE-ENTERS the same key (loops, recursion, shadowing, re-declaration); that is where the natural representation breaks and where the decisive test goes.

## Difficulty lever: a SECOND independent sub-feature beats behavioral compounds (piccolo-to-be-closed R7, Nova 2/10=20%, 2026-06-28)

When a feature reads too easy and you want to raise the band, the instinct is to add behavioral COMPOUNDS (interleavings of behaviors you already test). Confirmed twice now (piccolo R5 + R6): compounds the general machinery handles for free are ALSO free for a competent agent, so they catch only weak agents and on Castor's avg-fraction they make the problem EASIER. The lever that actually moves the band is a SECOND INDEPENDENT SUB-FEATURE — one with its own integration path (own opcode, own compiler hook, own stdlib entry) that does NOT fall out of the first sub-feature's machinery.

Evidence: piccolo's to-be-closed has a stackless-unwind wall (sub-feature 1). The real Nova batch failed CATASTROPHICALLY (8-22 of 80 tests per run, 4/10 runs) on the generic-`for` fourth-value closing — a SECOND sub-feature with its own opcode + compiler path. Agents who solved the unwind wall still skipped the second one under budget pressure. That second wall is what holds the band at 20%; the behavioral compounds added almost nothing. (The lone exception: ONE precise discriminator, the body-local-vs-for-4th close-ORDER test, was decisive on the single strongest near-miss — so keep a few precise discriminators for the near-misses, but rely on a second sub-feature for the catastrophic majority.)

**Design rule:** to raise a single-feature problem's band, add a co-equal sub-feature with a distinct integration path, not more interleavings of the first. **Measurement rule:** the 10-run platform batch is the only difficulty oracle. A 2-3 agent local clean-room sim is a fail-fast SOLVABILITY check only — it under-samples "agent skips a whole sub-feature under budget pressure" (the dominant catastrophic failure), so it systematically under-estimates difficulty for multi-sub-feature problems (and over-estimates when polluted by infra-death runs). Never tune the band off a sim.

### Free trap: an existing `size_of`/invariant test + a feature that needs new enum variants (piccolo-to-be-closed R10, 2/10 baseline regression)

If the target repo already has a test asserting a representation invariant — `assert!(size_of::<OpCode>() <= 4)`, a golden bytecode size, a struct-layout check — and your feature REQUIRES adding enum variants / fields, you get a high-value trap for free. Agents who add variants naively blow the size budget and REGRESS the pre-existing test (a baseline failure, not just a new-test miss), and agents who don't run the FULL base suite never see it. The correct implementation forces a PACKED representation (piccolo splits a rich `Operation` enum from a packed `OpCodeRepr` with explicit encode/decode). Confirmed: 2/10 Nova runs failed `tests/sizes.rs`'s `size_of::<OpCode>() <= 4` this way; a third regressed the adjacent register-layout and hung normal loops. To design it in: pick a feature needing new opcodes/variants in a repo that already pins the representation size, and do NOT relax that invariant in your solution — make your new variants fit it (the packing IS the hidden work).

**Related — a metamethod/callback that runs during a cross-thread or cross-frame teardown exposes borrow/aliasing bugs the happy path hides.** piccolo's `coroutine.close` running a pending `__close` that captures an outer upvalue triggered `RefCell already mutably borrowed` in 4/10 runs (the nested executor mutating the outer thread's open upvalue). If your feature has a teardown/finalizer path that can invoke arbitrary user code capturing caller state, add a test where the callback DOES capture and mutate outer state — it catches the aliasing bug a self-contained callback never surfaces.
6. The cost of fighting bot is iteration rounds; the cost of losing hints is pass-rate points

## Anti-Agent Design Pattern: Strategy-Enum Reshape (Confirmed expr-licm-predicates)

**Pattern**: When pure-function additive feature hits trap-stacking ceiling (PLAYBOOK Pattern 17), reshape by introducing a public strategy enum with multiple values, each carrying distinct algorithmic behavior. Pair with a public Option function that takes the enum.

**Anatomy**:

```go
// Public root file (expr.go, top-level package)
type LICMStrategy int

const (
    LICMDisabled LICMStrategy = iota
    LICMPerBody     // existing behavior, backward compat
    LICMCrossBody   // NEW algorithm requiring whole-tree analysis
)

func WithLICMStrategy(s LICMStrategy) Option { ... }
func WithLICM() Option { ... }   // shorthand for WithLICMStrategy(LICMPerBody)

// Internal config (conf/config.go)
type Config struct {
    ...
    LICMStrategy int  // mirrors public enum values
}
```

**Why this breaks the ceiling**:

1. **Multiple enum values with per-value behavior** (Pattern 17 element #4). `LICMDisabled` is no-op; `LICMPerBody` is canonical recipe; `LICMCrossBody` requires NEW algorithm.
2. **Public API split** (Pattern 23). Tests import enum from public root. Agents who put types in internal config fail integration. 25% catch rate.
3. **Whole-program analysis** for one of the strategies. Cross-body sharing forces agents to abandon per-body recipe. 50%+ catch rate alone.
4. **Backward-compatible entry point** (`WithLICM()` still works). Existing per-body tests continue to pass; agents can't trivially shortcut.

**Empirical impact**: expr-licm-predicates went from oscillating 0% to 100% across 27 rounds at Mars C, to 33.3% at first eval after R28 reshape. Same trap categories now fire because new shape has surface for them.

**Where to apply**:

- Optimizer pass with single-mode behavior, split into multiple strategies (per-body / global / hybrid)
- Validator with single rule set, split into named rule profiles (strict / loose / custom)
- Serializer with single format, split into named format variants (compact / indented / canonical)
- Cache with single eviction, split into named eviction strategies (LRU / LFU / FIFO)

**Cost**: 150 LOC additional in solution (algorithm branch + strategy registry); 50 words spec growth; 5-7 new tests per strategy. Total reshape work = 1 round vs 5+ rounds of trap-stacking that produced no movement.

## Anti-Agent Design Pattern: Cross-Body Shared-Binding Algorithm (Confirmed expr-licm-predicates)

**Pattern**: For features that operate per-scope (per-body, per-function, per-block), add a strategy that operates whole-program. Forces agents to abandon mechanical per-scope recipe.

**Concrete shape**:

- Per-body strategy: walker visits each body independently. Counter resets per body. Bindings placed locally (e.g., immediately above each builtin call).
- Cross-body strategy: walker visits all bodies, accumulates candidates in shared registry keyed by `Node.String()`. After walk completes, single binding emitted at outermost scope. Each body references shared binding name.

**Why it traps agents**:

- Agents trained on textbook LICM / loop optimization / CSE think per-loop or per-function. Whole-program is rarer in textbook treatments.
- Per-scope recipe maps cleanly to `for each body { collectHoists; emit; }` structure. Cross-scope requires 2-pass or accumulator pattern.
- Naming index allocation differs: per-body resets per scope; whole-program is monotonic global. Agents who naively reuse per-body counter generate name collisions.
- Substitution is harder: agents who hoist correctly may forget to rewrite occurrences in original bodies (1/12 catch rate at expr-licm-predicates).

**Tests must verify**:

1. Shared invariant across two bodies, single binding (count `let __X = `: 1)
2. Shared binding placed at outermost scope (positional check before first builtin call)
3. Distinct invariants per body, distinct bindings (`__licm_0`, `__licm_1`)
4. Single-body invariant under cross-body strategy still hoisted at outermost (not just shared ones)
5. Eval-equivalence: cross-body output evaluates same as base
6. Per-body counter resets; cross-body counter is global (separate test for each)

**Difficulty lever**: Tier 1 (50%+ failure rate). Highest-yield single addition for ceiling-bound problems.

---

## Confirmed Anti-Agent Pattern: Walker-Depth Gap (dasel-assign-path-creation)

**Confirmed empirically on dasel-assign-path-creation (Mars Solid, 5/9 = 55.6%, approved May 2026; 22 of 23 distinct test failures across 3 FAIL runs traced to this pattern).**

When the spec describes a path walker that must traverse arbitrary depth, agents reflexively implement a shallow walker (1-2 levels) and silently break at 3+ levels with a generic mid-traversal error. The spec doesn't have to say "depth-N" explicitly -- agents miss because their default loop structure stops short.

### Mechanism

Agent's naive walker handles `a` and maybe `b`, then mid-traversal `c` lookup hits an undefined-or-non-map error and the walker bails. Test fails with "cannot assign through scalar" or similar wherever the broken-walk happens.

### Run-level evidence

- Run #6 (Nova→Orion FAIL): 8 mixed-path tests failed at depth 2-4 (`a[0].c=1`, `$this[1].name="x"`, `a.b[1].c.d=42`, `a[0].b[1].c=5`)
- Run #8 (Nova→Orion FAIL): 14 deep-nesting tests failed (3-8 levels: `FlagOnCreatesThreeNestedKeys`, `FlagOnDeepMixedPath`, `FlagOnFiveDeepNesting`, `FlagOnEightDeepNesting`, `FlagOnNestedSliceAtMapLeaf`)
- Run #4: 1 test failed at depth 1 -- same shallow-walker mechanism, different cause (null-as-missing trap)

### Test design that catches it

Include explicit deep-nesting tests at 3, 5, 8 levels. Mixed-path tests `a[0].b[1].c=5` force per-segment type-choice at each level. Each bucket = 5+ scenarios at increasing depth. Approved test count: ~24 walker-depth-relevant tests.

### Spec wording that pre-empts

"creates **each** missing intermediate as an empty map" -- "each" pre-empts agents who treat as "the first one".

### Difficulty lever

**Tier 1**. The spec sentence is one word away from being trivial: "create the missing intermediate" → 100% pass; "create **each** missing intermediate" → 55.6% Mars Solid.

---

## Confirmed Anti-Agent Pattern: Per-Segment Container-Type Choice in Mixed Paths

**Confirmed empirically on dasel-assign-path-creation Run #6 (Nova→Orion FAIL, 8 tests).**

When mixed paths combine property-name and integer-index segments, the walker must choose intermediate container TYPE based on the NEXT segment, not on a default. Agent reflex: "every intermediate is a map" -- uniform creation. Spec demands non-uniform: string-next → empty map; int-next → empty slice.

### Mechanism

Agent uniform creation:
```go
filler := NewMapValue()   // always
for _, seg := range path[:len(path)-1] {
    EnsureMapKey(parent, seg.Key, filler)
}
```

Spec demands per-segment lookahead:
```go
next := path[i+1]
if isStringSegment(next) {
    filler = NewMapValue()
} else {
    filler = NewSliceValue()
}
```

### Run-level evidence

8 mixed-path tests in Run #6 errored "cannot assign through scalar ... expected map, got null" (agent created map for int-next segment instead of slice).

### Spec wording that pre-empts

"choose an empty map when the next segment is a property name and an empty slice when the next segment is an integer index"

### Difficulty lever

**Tier 1**. Forces walker lookahead by one segment. Without explicit per-segment-type rule, agents converge on uniform creation and fail.

---

## Confirmed Anti-Agent Pattern: Null-as-Missing-Value Disposition (Cross-Language Reflex)

**Confirmed empirically on dasel-assign-path-creation Run #4 (Nova→Orion FAIL, 1 test).**

Agents trained on JS/TS/Python default-treat `null` as "absent" rather than "present scalar value". When a path-walker encounters null, agents auto-create through it (same as missing intermediate) instead of erroring as scalar-collision.

### Cross-language origin

- JavaScript: null/undefined falsy; `??` and `?.` treat null as absent
- Python: None is "missing"; `or` short-circuits on None
- JSON tools (jq, dasel selectors in some contexts): null often acts as path terminator
- Go: `nil` typed-pointer is "absent"

Result: agents read "scalar" in spec and exclude null without realizing.

### Pre-empt cost

`(including null)` parenthetical = 2 words. Hits the trap reliably without separate test or hint.

### Run-level evidence

Run #4 walked through null in slice (`$this[1].x = 7` on `[1, null, null]`) and replaced null with map. Test expected error.

### Difficulty lever

**Tier 2** (catches some agents, not all). Non-negotiable when null appears in the spec's value model and tests assert null-collision.

---

## Confirmed Anti-Agent Pattern: Unified-Substring Across Multiple Collision Dimensions (Spec Discipline)

**Confirmed empirically on dasel-assign-path-creation R0 → R1 (auto-reviewer flagged at R0).**

When the feature defines collision behavior across multiple dimensions (scalar collision + container kind-mismatch + null traversal), agents emit DIFFERENT error wordings per dimension by default ("expected map, got slice" vs "scalar collision" vs "null encountered"). If tests assert ONE substring across all dimensions, agents fail substring-match on the cases where their wording differs.

### Pattern

Spec MUST enumerate every collision dimension that uses the substring in ONE clause:

> Type collision errors regardless of the option, with a message containing `cannot assign through scalar`. This applies to any scalar value (including null) and to kind mismatches such as a property-name segment targeting a slice or an integer-index segment targeting a map.

One substring, three explicitly enumerated cases. Agents pick right wording first attempt.

### Anti-pattern

> Type collision through a scalar errors with `cannot assign through scalar`.

Only the scalar dimension is named. Tests assert the substring for THREE dimensions. Auto-reviewer flags contradiction. Solution might emit different wording for kind-mismatch case → test fails.

### Difficulty lever

**Tier 2**. Without enumeration, the substring assertion fails on edge cases regardless of agent skill. WITH enumeration, agents converge on consistent wording. Spec discipline scales reviewer's mental model: read once, predict every test outcome.

---

## Authoring Anti-Pattern: Multi-Statement Chain-Through-Value (dasel-Specific)

**Confirmed empirically on dasel-assign-path-creation R0 (12 tests written, all empirically broken; removed before submit).**

dasel chains semicolon-separated expressions through the RESULT VALUE of each statement, not back to the root. Selector `a = 1; b = 2` runs `b = 2` against the integer value `1` (result of `a = 1`), not against the root map.

### Pre-empt: build CLI and test empirically before writing test scenarios

```bash
go build -o dasel.exe ./cmd/dasel
echo '{}' | ./dasel.exe -i json -o json 'a = 1; b = 2'
# errors with "cannot assign through scalar at key b"
```

5-minute empirical step prevents 12 tests from shipping broken. Variables (`$x`, `$this`) ARE supported in multi-statement context (per existing `TestAssignVariable` in dasel base) -- they're a mutable side-channel via `Options.Vars`.

### Lesson

This is an AUTHORING anti-pattern (not an agent trap). Document so future authors don't repeat. Empirical CLI verification of every syntactic construct before writing tests.


---

## Confirmed Anti-Agent Pattern: Parser-Wrap Newline Reflex (yaegi-repl-doc, 43% hit rate)

**Source**: yaegi-repl-doc 6/14 = 43% hit rate. Tier 1.

**Pattern**: feature spec implies a parser flag (e.g. `parser.ParseComments`) currently scoped to one mode must apply to all evaluation paths. Agents solving the headline problem reflexively reshape the surrounding wrap (`"package main;" + src` to `"package main\n" + src`) so comment-attachment works with the wrapped form.

The wrap reshape is silently broken: shifts every position-asserting baseline test by 1 line. 11-12 baseline tests fail with `want 1:29` vs `got 2:16`-style position deltas.

**Why it lands**:
- Spec implies the flag-elevation requirement without describing the wrap.
- Reference solution proves the headline behavior works WITHOUT touching the wrap (go/parser tolerates the existing `package main;<comment>\n<func>` shape via implicit-semicolon rules).
- Pre-empt sentence in description defuses trap. Silence preserves it.

**Difficulty lever**: Tier 1 (43% failure). Highest-yield single addition for any interpreter/parser-extension problem with a "narrow vs all-paths" parse-mode split.

**Trap engineering**:
- Identify a parser flag in target repo guarded by `if narrow_mode { mode |= flag }`
- Author feature whose spec language requires the flag in all paths
- Do NOT pre-empt the wrap-shape reflex in description
- Include 5+ position-asserting baseline tests in BASE_RUN regex

**Generalization**: any interpreter/parser repo with a "narrow vs wide parse mode" split — Lua, Python emulators, JS interpreters, query parsers all have analogous shapes.

---

## Confirmed Anti-Agent Pattern: GenDecl Spec Walking Missed (yaegi-repl-doc, 21% hit rate)

**Source**: yaegi-repl-doc 3/14 = 21% hit rate. Tier 2.

**Pattern**: feature requires walking AST and capturing metadata at multiple decl-shape sites. Agents capture the headline shape (`*ast.FuncDecl.Doc`) but miss `*ast.GenDecl` walking ValueSpec/TypeSpec because GenDecl wraps multiple specs and Doc-attachment-level varies (decl-level for single-spec block; spec-level for multi-spec block).

**Failures observed**:
- `Doc("Counter")` empty for documented `var Counter int`
- `Doc("Box")` empty for documented `type Box struct{ X int }`

**Trap engineering**:
- Spec lists 5+ declaration kinds (var/const/type/func/method) explicitly
- Reference walker MUST handle ValueSpec + TypeSpec inside GenDecl with declDoc fall-back
- Tests assert all 5 kinds independently

**Difficulty lever**: Tier 2 (21% failure). Pairs well with Tier-1 trap to push pass rate down.

---

## Confirmed Anti-Agent Pattern: REPL Output Buffer Routing (yaegi-repl-doc, 21% hit rate)

**Source**: yaegi-repl-doc 3/14 = 21% hit rate. Tier 2.

**Pattern**: spec adds REPL meta-command that "prints a message". Agents implement using `errs` (stderr) instead of `out` (stdout) because the message describes a fault condition (usage shown when arg missing).

**Failures observed**: TestDocREPLNoArgPrintsUsage / TestDocREPLWhitespaceOnlyPrintsUsage fail because tests assert REPL stdout buffer contains `usage:` substring; agent's output went to stderr.

**Why it lands**:
- "Prints" is ambiguous — Go convention is fault → stderr, normal → stdout, but REPL meta-commands are user-facing prompts (stdout territory)
- yaegi has both `out` and `errs` writers; agents pick wrong by reflex

**Trap engineering**:
- Spec uses neutral verb "prints" without specifying channel
- Reference uses `out` writer (matches REPL prompt context)
- Tests assert stdout, not stderr

**Difficulty lever**: Tier 2 (21% failure). Cheap to add — just neutral wording in spec.

---

## Meta-Pattern: Silent-Trap Preservation vs Spec-Pre-Empt Trade-off

**Source**: yaegi-repl-doc 5 description trim rounds confirm the trade-off.

**Observation**: each trim round removes implementation hints. Each removal raises one trap's hit rate by 10-20%.

| Round | Description trim | Trap exposed | Hit rate |
|---|---|---|---|
| Initial | Spelled out lookup chain ordering | Lookup-order trap defused | <5% |
| R1 | Removed "captured at compile time" | Parser-wrap reflex exposed | 43% |
| R2 | Removed "and never an error" | Error-tuple-signature trap exposed | (untested) |
| R3 | ":doc " to ":doc command" | Tab/whitespace separator trap defused | 0% |
| R4 | Dropped "public" + shadowing example | Shadowing trap exposed | (small) |

**Quantified trade-off**: each implementation hint dropped raises difficulty by 5-20% pass-rate points. Spec-quality bot demands ~3 hint drops per submission. Net effect: pass rate falls 15-30% across iteration cycles.

**Strategy**:
- Pre-trim aggressively to skip 3-5 rounds (per AUTO-REVIEWER.md §5)
- For Tier-1 traps you WANT to land: don't pre-empt them. Silence preserves the trap.
- For traps that WOULD make problem unfair: pre-empt with one behavioral pin (not implementation hint). Behavioral phrasing survives trim rounds.

**Anti-pattern**: pre-empting EVERY trap with implementation hint → bot drops them all → effective spec is shorter than intended → traps re-emerge stronger than designer expected.

**Calibration rule**: aim for 1-2 silent traps + 1-2 pre-empted traps per Mars Solid problem. Total 3-4 traps. yaegi-repl-doc landed 5 traps total (1 Tier-1 + 2 Tier-2 + 2 Tier-3) at 21.4% pass rate — Mars Strong band.

## Difficulty mechanism: record-during-walk vs reconstruct-after (provenance timing)

cel-go-strict-dyn (APPROVED Diamond 2026-06-17). A robustly anti-Castor AND anti-opus wall that needs NO cross-subsystem span: make correctness depend on recording provenance DURING the single forward walk, where the naive "inspect the final type at the point of use" is structurally too late. Here `dyn` is a shared singleton (explicit dyn() and implicit dyn are type-INDISTINGUISHABLE) AND an unresolved type parameter is promoted to dyn only at the final substitution pass - AFTER the walk visits the consumption site and after the enclosing call's overload binds the parameter. A deferred/post-walk classifier reads a now-concrete type and records nothing; only walk-time, node-id-keyed provenance survives. Confirmed 0/10 unhinted FAIR.

Generalize: a feature is Castor-hard (and opus-hard, unlike mechanical plumbing which is opus-trivial and ceilings at Olympus) when the SIGNAL the check needs is destroyed by a later UNAVOIDABLE phase of the same pipeline - substitution, constant-folding, canonicalization, overload binding, optimization. Pair the timing wall with a few fair INDEPENDENT gates (value-only aggregate-join, dyn()-escape laundering through aggregates/comprehensions, enforcement-wiring "record-but-don't-reject") so the pass rate lands in band; tune the rate via ONE un-hinted gate, never the timing wall (it is all-or-nothing - every solver is one-cluster-from-passing).

## Confirmed Anti-Agent Patterns: method-set / selector spec-conformance (yaegi-methodset-enforcement, APPROVED Diamond 2026-06-23)

Recurrence-ranked over 12 Castor runs. All are INTERDEPENDENT (share the checker's state) + MISDIRECTING (the failing assert points away from the fix the agent made).

- **Detecting != selecting (shallowest-wins, near-universal hit).** Agents add an ambiguity DIAGNOSTIC but leave the runtime `lookupField`/`lookupMethod2` depth-first, so the deeper-declared-first member is still SELECTED at run time. Reads as "done" until a stdout-VALUE test (not an error-substring test) catches the wrong member. Lever: require a behavioral value assertion on the resolved member, not just an error on the ambiguous case.
- **The accept-twin trap (over-reject).** struct-embeds-two-interfaces is ambiguous, but interface-embeds-two-interfaces COALESCES identical methods (legal since Go 1.14). Agents apply struct-style ambiguity counting to an interface root and reject the legal merge. Pairing a reject case with its near-identical legal accept twin in ONE test body is the highest-yield fairness+difficulty lever.
- **Error-SELECTION, not error-absence.** A comparison can REJECT the bad case yet surface the wrong diagnostic (raw `does not implement ... wrong type for method M` instead of the spec's `mismatched types`). A substring assertion on the REQUIRED wording catches this where a bare "expected an error" would pass. Same test fails differently across runs (reject-wrong-wording vs got-none).
- **ZERO-new-API as a difficulty + dedup lever.** Making illegal input FAIL through the existing error channel (no new surface) forces the agent to find every leak site rather than implement one named function; it also dodges the additive-API similarity cluster.
- **Carve-out edges agents over/under-apply:** array-LITERAL index is non-addressable (`&[3]int{...}[0]` rejects) but a composite-lit DIRECTLY under `&` is addressable; a pointer-valued map element re-addressabilizes (field write legal) while a value element does not; a nested chain (`m["a"].in.x`) must walk to the root, not stop at the immediate selector.

## typify-object-applicators (APPROVED Diamond 2026-06-25) - Representation-Split anti-agent pattern

REPRESENTATION-SPLIT TRAP (confirmed 10/10 Castor miss). When a subsystem lowers one logical concept into two co-equal representations (here a JSON-Schema object -> a named-field struct OR a property-less map/newtype), wire a NEW required behavior so it must hold in BOTH, and add an edge that only the second representation hits. Agents implement the obvious representation (struct) and ship; the second (map) silently fails and a degenerate case (unnamed root key) panics.

- INTERDEPENDENT: both representations share the key/lowering path, so a struct-only fix cannot satisfy the map tests.
- MISDIRECTING: the map-generation failure surfaces as an `Option::unwrap()` panic that looks like a naming bug, not a missing-feature bug; the cardinality failure surfaces as a test-assertion panic, not a deserialize error.
- The CODEGEN ROUND-TRIP WALL amplifies it: the generated serde derives must accept exactly the JSON the schema allows and reject the rest, so a representation that "compiles and looks right" still mis-accepts/mis-rejects at runtime.

## cel-go-cost-coverage (APPROVED Mars 2026-06-24) -- static<->runtime dual-maintenance soundness off-by-one

Confirmed anti-agent difficulty pattern for cost/budget/size-coverage features that span a STATIC estimator and a RUNTIME tracker maintained as twins (cel-go: checker/cost.go static `Max` <-> interpreter/runtimecost.go runtime `ActualCost`). The wall is a SOUNDNESS INVARIANT off-by-one: the static estimate must stay an upper bound (`Max >= ActualCost`) through a compound chain like `[..][?0].orValue("").contains("z")`. The naive bounded-size fix lands static exactly ONE unit BELOW runtime.

Why it bites (10/14 Nova/Orion missed it unhinted):
- INTERDEPENDENT: the static and runtime numbers come from two separate files that must agree; a local fix to the runtime charge (or to one static branch) silently breaks the cross-file invariant.
- MISDIRECTING: the violation undershoots ONLY at LARGE size -- small inputs pass, so the failing test reads like a flaky/edge bound rather than a wrong estimate. The agent has no signal pointing at the missing +1 in the static estimator.
- The fair canonical terminal that exercises it is `contains("z")` (scales with size, sound upper bound, saturates); `endsWith`/`startsWith` undershoot and `size()` is O(1) so it never stresses the bound.

General lever: any feature where a STATIC over-approximation must dominate a RUNTIME measurement of the same operation is a strong single-subsystem Mars trap -- route both numbers through one compound expression and let the obvious bounded-size fix land just under. Keep the giveaway out of the meta (a sentence naming "the static bound is the hard part" defuses it to ~60% too-easy).

## starlark-rust-set-literals (APPROVED Mars 2026-06-25) -- anti-agent pattern

Confirmed anti-agent mechanism for SATURATED features that have no feature-level trap: make the difficulty LONG-HORIZON THOROUGHNESS by choosing a cross-subsystem change that necessarily breaks fair existing baselines (an obsoleted negative test + a generated snapshot/profile golden). Frontier agents implement the saturated feature trivially and pass all behavioral tests, then 90-100% skip full-suite validation and leave the baselines red. Only the agent that exhaustively runs the suite and regenerates/updates the affected goldens passes -> ~8% Hard band. This is "process thoroughness" difficulty, distinct from algorithmic-trap difficulty; it is fair (the failures are inferable repo maintenance and the failure output names them) and shippable at Mars. Caveat: the difficulty is shallow -- it survives at Mars (no hints, thoroughness-as-difficulty acceptable) but the same feature could not be a Diamond (227-eff sugar; no interdependent+misdirecting feature trap).

## glaredb-ordered-aggregates (APPROVED Olympus 2026-06-27) -- anti-agent patterns

Two confirmed anti-agent mechanisms, both fair, that landed an Olympus at 10-17% Hard across two batches:

1. **The obvious design works for the simple case but a REPO-SPECIFIC PATH silently breaks it (interdependent + misdirecting).** Feature = aggregate-local ORDER BY. The intuitive design (insert a global sort before the aggregate) passes `string_agg(x ORDER BY y)` and the grouped case, then SILENTLY FAILS for `string_agg(DISTINCT x ORDER BY x)` because glaredb's DISTINCT path collects inputs into a hash table and scans them in hash order, destroying the sort. The failing test shows scrambled output (`c,a,b` vs `a,b,c`) -> reads as "sort broken," pointing AWAY from the real cause (the distinct table). Correct fix routes DISTINCT into the aggregate state (dedup AFTER sort) and disables operator-level distinct. This single trap sank 3-5 of every 12 agents on its own, and is robust to retries because the agent must re-architect, not point-fix. Design rule: pick a feature where the COMMON design is correct for the easy cases and a real, non-obvious repo internal (hash-distinct, partitioned merge, a separate execution path) breaks the hard case.

2. **A repo's EXISTING strict invariant is a FREE trap when a new clause tempts a uniform rewrite.** glaredb already enforces "STRING_AGG 2nd arg must be constant." An agent implementing the new FILTER clause by CASE-wrapping EVERY aggregate argument turns the constant delimiter into `CASE WHEN filter THEN ',' END` -> the pre-existing rule fires and rejects a valid query. No extra spec needed; the trap is the repo's own rule colliding with the lazy implementation of the new clause. Look for these when adding a clause that modifies aggregate inputs.

Difficulty-tuning note: broadening the solution to clear the LOC bar with EASY sibling aggregates (arg_min/arg_max) nudged the rate UP only marginally (10% -> 16.7%) and stayed in band, because both gating traps above are INDEPENDENT of the easy surface. Easy additions are safe for the band precisely when the hard trap does not depend on them.

## symengine-imageset (APPROVED Mars 2026-07-02) -- canonical-type narrow-guard + tighten-first anti-pattern

**Anti-agent pattern (9/10 Nova miss): canonical-type NARROW-GUARD.** A feature branches on a type-family with one dominant member (Integers among {Integers, Naturals, Naturals0}). Agents `is_a<Canonical>`-gate the special-case and forget the co-equal siblings that also satisfy the real predicate. Interdependent: the same delegation (`base->contains`) is mandated in two paths (membership + enumeration); agents apply it in the obvious one, hardcode the dominant type in the second. Misdirecting: "integer-indexed" reads as "== the canonical type". Fair because the spec states the DELEGATION, never the type list. Design recipe: state the predicate-delegation once for the obvious op; put the sibling type only in a hidden test for the second op.

**Difficulty-tuning anti-pattern learned here (do NOT repeat): naming the seam in meta = instant 100%.** Adding "make sure both operand orderings of a global set_intersection evaluate the same way" (a mechanism description) took a 50% problem to 100%. A larger description compresses the capability gap (weak agents coast). The fix that restored difficulty was to DELETE the seam sentence and tighten the meta (375->217 words), then move traps into test design. Corollary: adding tests to a mechanism-naming description does nothing; delete the sentence. Full: `PATTERNS-ADVANCED.md § Pattern 62`, `lessons-learned.md § Tighten-First Rule 7`.

## nickel-1336 dict catch-all (OLYMPUS 1/10=10% 2026-07-03) -- anti-agent patterns for a CROSS-CRATE DUAL-AST feature

Four anti-agent walls, each catching a DIFFERENT agent (a 4-orthogonal-wall stack -> exactly 10%, the piccolo "5+ orthogonal walls" law confirmed at Olympus tier on a cross-subsystem feature). Ranked by kill-count:

- **★ DUAL-AST INTEGRATION WALL (the Nova-killer, pure compile difficulty UNDER the semantics).** Pick a feature whose new surface syntax lives in a grammar production that OVERLAPS an existing one (here `_` is in the TYPE grammar; naive metadata parsing = a record-field production = LALRPOP local ambiguity), AND whose payload must thread through BOTH a surface AST and a core AST plus LALRPOP-generated code (`&T`-vs-owned type mismatches) and ~15+ match/initializer sites (add a field to a shared struct -> miss an initializer -> E0063; unresolved import -> E0432/E0433; container missing a trait method -> E0599). Effect: fast agents (Nova) die at COMPILE before touching semantics -- the feature stacks an integration floor beneath the behavioral walls, so weak agents never reach the interesting part and the pass-rate floor drops. This is the strongest use of a cross-crate feature: the dual representation IS a wall, not just plumbing.
- **★ SHARED-STRUCT-REPRESENTATION LEAK = BASELINE-REGRESSION WALL (catches the strongest solvers).** When the feature adds state to a struct that many EXISTING code paths observe (`RecordData` -> pretty-print, blame label-path, emptiness/equality, dedup, merge-fixpoint), the new representation leaks: agents that implement the WHOLE new feature (26/26 new tests) still regress the base suite (`{ _ | String }` pretty-prints `{}`; empty blame label-path; `revertible thunk already set` panic). The base suite is the discriminator. Design so the new state is INVISIBLE to every legacy observer, and let the (extensive) baseline tests enforce it -- this is a FOURTH wall that survives after the feature itself is done.
- **MATERIALIZE-AS-FIELD (the empty/optional trap; 0-pass without a hint).** Agents store metadata-about-the-record as record CONTENT -> `is_empty()` counts it, valueless-optional fields aren't dropped. The correct model (metadata is a template, NOT a field) is a genuine conceptual miss; universally failed until spelled behaviorally.
- **APPLY-AT-APPLICATION-TIME-ONLY + FREEZE-DROP misdirection (the propagation trap).** Obvious path applies the contract over fields present when it is checked; later-entering fields (insert/computed/merge) flow separate eval sites and a freeze that DROPS pending state, so they silently escape. The failing insert/merge test surfaces as a downstream `NotAFunc`, not at the freeze/insert site -- the symptom names the wrong location. Held against baseline-passing Orion runs.

**Design takeaway:** a cross-crate feature that (a) shares a grammar production with existing syntax and (b) adds state to a heavily-observed shared struct gives you a compile-floor wall + a baseline-regression wall for free, ON TOP of the semantic walls -- a natural 4-wall Olympus that lands ~10% without any misdirecting-trap gimmick.

## nickel-enum-widening (APPROVED Mars 2026-07-04, 30% 3/10) -- variance-composition over-generalization + force-diagnostic-direction

- **★ CONTRAVARIANT-DOMAIN OVER-GENERALIZATION (a self-loading trap from a rule that interacts with existing goldens).** Add a subtyping-CONSTRUCTOR arm (function `T1->T2 <: U1->U2` = contravariant domain + covariant codomain) whose new rule composes with EXISTING negative goldens in the same subsystem. Over-eager solvers, once they add the rule, over-apply it and flip an existing "should stay error" golden (`mismatch_enum_match_fun_type`) to `pass` -- but the program still correctly errors (`ArrowTypeMismatch`). The trap loads itself: you author no misdirecting test; the new rule + the pre-existing baseline goldens generate the over-generalization failure for free (2/10). Recipe: add the variance rule, keep the existing mismatch goldens untouched; solvers who broaden too far regress them.
- **FORCE-DIAGNOSTIC-DIRECTION AS A HIDDEN f2p TEST.** When base and solution reject the SAME program with DIFFERENT error KINDS, assert the solution's kind as a hidden test (base=MissingRow(blo), solution=ExtraRow(bli) on a two-match pin; assert substring "extra row"). f2p (base's substring differs), and it catches BOTH wrong-direction impls (MissingRow) AND over-permissive impls (a value, no error) that the visible golden alone misses. Keep fair by documenting the direction in meta ("reported as an extra row").
- **DON'T over-invest in a small feature to hit a lower band.** Enum+function subtyping is intrinsically ~150 eff LOC; the walls above cap it at ~30% (Mars-good), and the platform's Olympus long-horizon gate cannot be honestly met by a feature this small. Ship Mars; the difficulty is real and fair, the SIZE is the tier ceiling.

## piccolo-finalizers-gc (APPROVED Mars 2026-07-04, 30% 3/10) -- un-bimodal via orthogonal walls; panic-misdirection

- **★★★ 5 ORTHOGONAL FAIR WALLS beat a bimodal cap that deepening-one-axis could not.** A single-subsystem GC feature stuck at ~53% (bimodal: agents either implement correct two-stage finalize or not) fell to the 30% Mars cap ONLY when the test suite spread across 5 independent sub-behaviors, each missed by a DIFFERENT subset of agents: (A) resurrection re-feed not propagated to the ephemeron fixpoint [dominant, 5/7], (B) `collectgarbage` multi-arg consume on a draining-stack API [3/7], (C) once-each broken across resurrect-then-redrop [1/7 SOLELY], (D) reverse-install-order, (E) kv-treated-as-ephemeron. Anti-agent design lever: don't pile tests on the hardest ONE trap; ENUMERATE the subsystem's independent sub-behaviors and place a fair wall on each. No single agent has all five blind spots, so pass-rate = product of per-wall survival across a heterogeneous fleet.
- **★★ PANIC-MISDIRECTION is the strongest fair misdirection.** The dominant GC bug surfaces as a library-internal `gc_arena: assertion failed: header.is_live()` panic deep in the arena -- the failing signal names the GC LIBRARY, not the agent's collection-ordering code. A correctness bug whose symptom points at the wrong file survives more retries than a wrong-value assertion that points straight at the buggy line.
- **★ REPO-API FOOTGUN as an independent trap.** `Stack::consume` drains the entire stack, so reading two args with two sequential `consume` calls silently yields nothing on the second -> wrong `setpause`/`setstepmul` previous value. Orthogonal to the domain logic, inferable from the visible `Stack::consume` source (fair), and it catches the agent who nailed the hard GC then got lazy on the boring plumbing. Multi-arg builtins on a draining-stack API are reliable free independent walls.
- **★ SHALLOW + DEEP variants of a fixpoint behavior are two traps.** `resurrection_feeds_two_level` vs `resurrection_feeds_deep_chain` (6-link) discriminate no-refeed vs bounded-refeed -- ship both whenever the spec says "to a fixpoint." Difficulty here was 100% test-coverage: the reference solution was byte-identical across all three hardening rounds.

## Anti-agent pattern: invasive shared-machinery refactor (gimli-type-units, APPROVED Mars 2026-07-05)

The strongest agent-tripping wall for a faithful-convert feature is NOT clever new logic (agents mirror the reader oracle) -- it is forcing a refactor of a widely-shared, concretely-typed write helper. gimli's `DebuggingInformationEntry::write`/`AttributeValue::write` are typed `&mut DebugInfo<W>` and called on every unit + every attribute + recursively. Routing v4 type units to a second section (`.debug_types`) requires generalizing them to raw `&mut W`. Because that helper is load-bearing for ALL units, a wrong generalization (stray `.0`/`.offset()`, incompatible section branch types, dropped trait imports, borrow conflicts) either fails to compile or regresses the entire baseline. 14/20 Nova runs could not compile it. This is the "single load-bearing chokepoint you must refactor correctly or nothing builds" flavor of difficulty: interdependent by construction (the refactor touches all units at once) and misdirecting (the failure is a compile error far from the type-unit logic). Difficulty comes from the THREADING, not volume (249 eff LOC, 5-15% pass).

## nickel-array-rest (APPROVED Mars 2026-07-05, 30% 3-cluster) -- stack an integration wall UNDER the semantic walls; the fairness catch-22 on a rejection case

Anti-agent design that landed a fair 30% on a single-language Rust feature:
- **Put a compile/integration wall UNDERNEATH the interesting semantics so weak agents die before reaching them.** For a grammar-touching nickel feature the free integration wall is the LALRPOP `=>?` action error type: a custom rejection must return `lalrpop_util::ParseError::from(crate::ParseError::X)`; returning the crate error directly is E0308 and the parser crate never compiles. 6/20 Nova died here, never reaching the from-tail arithmetic or CPS fall-through. You do not design this wall -- it is inherent to the codebase -- but you EXPOSE it by requiring a new parse-time rejection/diagnostic, and it filters exactly the agents who cannot do a full build.
- **Reuse the existing grammar item type to keep the reshape LR(1) -- and let agents who don't hang themselves on ambiguity.** Generalizing `(<Pattern> ",")*` to `(<LastElemPat> ",")*` is the minimal LR(1)-safe move; agents who invent a second production or a `PatternList` trip LALRPOP local ambiguity -> build panic (2/20). The wall is that the clean shape is non-obvious, not that the feature is huge.
- **From-tail index arithmetic is a silent-wrong misdirection.** The existing compiler is head-relative; a suffix loop that stays head-relative passes on exact-fit (n==p+s) and fails only when the middle is non-empty. An agent shipped a fixture asserting the outer-rest middle capture is `[b,c]` when it is `[[b,c]]` -- the failing value points away from the index-origin bug.
- **Anti-pattern to AVOID (the fairness catch-22):** do NOT describe or test a rejection case that BASE already rejects. Multiple-rest (`[.., a, ..]`) errors on base (parse) and solution (validation) alike -- not a behavior change, not fairly f2p-testable, and pinning the new error wording fails the fairness checker (no repo precedent). Describing it draws a coverage reviewer demanding an impossible test. Drop it from the spec; keep the internal validation as robustness. See Pattern 67.

## Anti-agent pattern: naive-dominant-reading + de-crutch (parry-heightfield-point-projection, ACCEPTED Mars 2026-07-05)

When a feature is convenience-wiring an agent can transcribe from existing conventions (too easy, 70% first batch), the durable difficulty is NOT more tests (padding well-specified behavior raises the pass rate) -- it is DEEPENING one core behavior into a trap where the naive/dominant reading is subtly wrong AND fair. Killer here: `height_at_point` returns the TRIANGULATED surface height, but the obvious implementation is BILINEAR interpolation of the 4 cell corners -- they diverge on any non-coplanar cell, and the correct reading is forced by the shape's actual triangle-mesh geometry (used by every other query), so it is fair without naming the algorithm. Compound it: (1) interdependence with per-cell flags (zigzag flips the containing triangle; removed -> None); (2) de-crutch an internal id-mapping helper to private so agents must re-derive it -- which also stresses adjacent public TYPE contracts (agents drifted `Location` id usize->u32). Requirement: the trap TEST must use geometry that separates the naive from the correct reading (a planar/axis-only fixture makes bilinear == triangulated and catches nothing). Net: 70% -> 30%, all-fair, accepted; the solution's core algorithm barely changed.

## Anti-agent pattern: breadth of orthogonal FAIR correctness walls on a capability-add that agents alias (aircompressor-zstd-strategies, ACCEPTED Mars 2026-07-06)

When a capability-add is a FAMILY (implement zstd fast/greedy/lazy/lazy2/btlazy2/btopt/btultra) that agents will ALIAS to one implementation (they all do -- a single correct matcher satisfies every fair behavior), you CANNOT make difficulty come from forcing distinct architectures (strict cross-strategy ratio is unfair AND untrue on binary corpora), and window-sliding-corruption does NOT bite (competent matchers already guard windowLow -- verify on the passers' diffs first, loro-risk). The durable, fair difficulty is BREADTH of orthogonal CORRECTNESS walls the ONE aliased solution must ALL satisfy, targeted at the PROVEN biters from the first batch: (a) ratio (stronger levels beat double-fast + monotonic) -- the dominant Nova wall, unescapable except by a recompress-fallback; (b) adversarial repcode/ll0 corpora + a MIN_MATCH=3 boundary; (c) a streaming-INVARIANT wall (the `checkState(chunkSize > blockSize)` guard) reached by making agents add a level-aware `ZstdOutputStream(out,int)` ctor and rebalance the buffer. 50% -> 10%, all-fair. The trap is NOT one deadly misdirection (à la parry) -- it is many independent fair failure chances (piccolo-finalizers model). CAUTION: this raises the DIFFICULTY axis only; if the aliased passer's irreducible LOC is Mars-sized (289), it is a MARS regardless of the 10% -- do not chase Olympus (Pattern 69).

## kcl-union-override-typecheck (APPROVED Mars 2026-07-07) -- the structural-lever anti-agent pattern for machinery-backed features
When the target repo already has recursive checking machinery your feature can piggyback on, difficulty is EASY to get (agents reuse it) but LOC/scope collapses (the reuse is ~40 LOC). To keep the feature meaty AND hard, require the one form the reusable machinery structurally cannot reach:
- KCL config-override checking: the reusable helper (check_config_value_recursively) is driven from walk_binary_expr for `|`. But `|=` compound assignment routes through walk_aug_assign_stmt -> binary() (calculation.rs), a path the walk_binary_expr check never touches. Requiring `|=` (described + tested: flat/undefined/nested/list) forced every solution off the shortcut and up +27 production LOC.
- General recipe: (a) find where the reuse hooks in; (b) enumerate sibling forms/paths that bypass that hook (aug-assign vs binary-expr, spread-from-variable vs inline-literal, schema-instance-RHS vs dict-literal-RHS); (c) require the bypassing forms. Each one the reuse can't cover both raises LOC and adds a fair, described failure cluster. This gave 4 diverse clusters at 8.3% pass.
- Also confirmed: the LOC floor is the LEANEST passing agent's raw diff. A big reference means nothing if an agent passes lean. Screen reuse-ability at pick time.

## stoolap-comparison-consistency (APPROVED Mars 2026-07-07) -- anti-agent patterns confirmed

- **Close an open policy to manufacture a misdirection wall.** "You choose the coercion" is a pure thoroughness gate (all passers do the same refactor). REQUIRE a specific rule (numeric coercion) that the codebase's own tempting helper (`Value::compare`, string-coercing) gets WRONG -> reusing the obvious helper is now a correctness bug -> even thorough agents fail. The bait (`Value::compare`) is left string-coercing on purpose; the reference writes a separate numeric comparison.
- **Bucketing defeats an equality fix (interdependent+misdirecting).** A type-discriminated hash keeps coerced-equal values (int 1, text '1') in SEPARATE hash buckets, so fixing `values_equal` is INERT -- the join never compares them. Symptom = 0 join rows; cause = hashing, not equality. Dominant wall: 7/10 Nova fixed scalar equality but left the join hash type-strict.
- **Hide the difficulty in paths that do NOT route through the shared helper.** For a SQL engine, that is every join algorithm (hash/parallel-hash/merge/nested), selected by the planner via size+sortedness. Small tests route to the easy paths; the hard paths only fire at high cardinality / on sorted inputs. The merge join uses a distinct ORDERING comparator, a second hidden path.
- **Enlarge the solution to exhaust fast agents' budget.** Closing the open policy forced routing the generic ordering ops + numeric helper through more sites -> the fast Nova runs (12-20 min) run out of budget before reaching the join/merge helpers; only heavy thorough runs finish.

## numbat-const-exponents (APPROVED Mars 2026-07-09) — anti-agent patterns

- **Type-gate-vs-const-eval:** a "record const if `type == Scalar`" shortcut mis-rejects polymorphic-zero arithmetic (`0-2`) while passing unary `-1/2`. Force it by testing both forms.
- **Name-keyed const map without clear-on-rebind** leaks shadowed runtime values as constants — the robust design clears on non-const rebind (else-arm) and scopes via save/restore.
- **from_f64 permissive-builtin exactness:** an agent that reads a const's f64 VALUE + `from_f64` drifts on large-denominator rationals; the exact path evals the DEFINING EXPRESSION structurally. Test `(meter^(7/3))^3==meter^7`.
- **Parser factor-ambiguity:** arithmetic in a dimension exponent must be paren-restricted; a greedy exponent parser eats the factor-level `/` in `Length^p / Time^q` and breaks the prelude.

## scryer-clpq-linear (APPROVED Mars 2026-07-09) — anti-agent patterns

- **Composition-seam stacking (Pattern 75) is the anti-agent lever for a from-scratch engine.** A multi-behavior solver tested behavior-by-behavior in isolation is a bimodal coin-flip (~50%): a thorough agent completes each behavior independently. The defeat is to STACK tests at the seams where one determination must re-fire ALL downstream consumers — force a value determined via bounds-promotion / Gaussian-collapse / var-var merge (not just explicit unification) and require the delayed-nonlinear product to wake + the stored disequality to re-check + the derived bound to propagate off that SAME determination. A partial impl that wired the wake to only the explicit-unification channel passes every isolated test and dies on the composed one. Batch 40% → 30%, solution unchanged.
- **The no-op delayed bucket is the canonical partial-impl trap.** Agents store nonlinear constraints in a "delayed" list that is only re-examined on a coincidental repost, never actively woken when a participating variable becomes determined internally. Weaponize: determine the variable via a channel that does NOT repost the constraint (opposing bounds forcing an implicit equality) and assert the product activated.
- **Ground-only `rdiv` parse.** A linear-expression parser that treats `A rdiv B` as linear only when the whole term is ground misses `N rdiv 2` (variable numerator). Foreseeable-but-missed instance of a stated grammar; a single test (`{N rdiv 2 =:= 3}, N =:= 6`) catches it.
- **Meta-check collision as a hardening hazard:** a conciseness check telling you to delete a "redundant" clause can orphan a fairness-dependent test — resolve by dropping the unusual test INPUT SHAPE, not by fighting the meta (cross-ref lessons-learned CHECK-COLLISION).

## erg-chained-comparison (APPROVED Mars 2026-07-10) -- anti-agent patterns
- Precedence-boundary misdirection: place the new construct adjacent to existing lower-precedence operators (`chain and chain`, `chain or chain`). Pure-form tests all pass, so the agent's self-validation is green; only the boundary case fails. Highest-yield trap for a new-operator pick (3/7 fails).
- Metadata-survival trap: a distinguishing flag (paren) that a downstream re-construction pass silently resets. Agent gets the concept right, loses it in the pipeline.
- Shared-path regression as a co-trap: the same handler serves the new feature AND an existing lone case; a naive feature fix regresses the lone case (chained `in` fix breaks `1 in 1..2`). Catches agents who don't run the full base suite.
- Free-backend guard: if one backend (native-Python transpile) gives the feature for nearly free, difficulty must come from the OTHER backend (hand-emitted bytecode: DUP/rot/short-circuit stack cleanup) + cross-backend parity assertions, else pass rate floats ~70%.

## zen-table-verification (APPROVED Olympus 2026-07-10, 10%) -- anti-agent patterns

- **The anti-agent lever for a GREENFIELD analyzer is an engineered machinery-riding wall (Pattern 77), not more documented cases.** A net-new static-analysis feature is a thoroughness gate: thorough Nova (800-1240 LOC) implements every documented+independent behavior, so a design with many parallel documented traps ceilings at ~90% regardless of LOC or span. Defeat it by rearchitecting two of the feature's checks to share ONE domain-model chokepoint, so the obvious separate-checks implementation is subtly wrong on an interaction. Here: unreachability and completeness both had to run over one extended domain (value space + an absence point on optional columns). The naive impl does value-space unreachability + bolts absence only onto completeness -> gets three interaction faces wrong (non-nullable wildcard-after-tiling must be unreachable because `Any minus numbers = Any` in the naive model; nullable wildcard stays reachable; nullable catch-all covers absence). ONE such wall dropped 90% -> 10% and was the SOLE killer across 19 runs.
- **Misdirection comes for free from the chokepoint.** The failing test asserts wildcard reachability, but the agent's value-space subsumption LOOKS correct -- the bug is that the absence dimension they only wired into completeness must also govern reachability. The agent cannot single-point-fix it on retry because the fix is an architectural coupling (thread the nullable flag through the shared chokepoint), and it ripples into 3-4 adjacent behaviors.
- **Interdependence makes the wall retry-resistant.** Because the same `column_domain -> Domain{region,nullable}` chokepoint feeds both checks, a local fix to one regresses the other; a partial fix flips a different test. This is what keeps a best-of-N retry gate from clearing it.

## go-geom-polygonize (APPROVED OLYMPUS 30% 2026-07-13) — anti-agent / difficulty patterns

- **Shared-chokepoint interdependence.** Put every trap through one piece of mutable state (the half-edge `next` linkage + ring labels). Face-merging, hole assignment, cut-edge detection, and orientation all read/write it, so a single-point fix to one regresses another. This is what keeps the pass rate in band instead of letting a smart agent single-shot-fix an isolated trap.
- **Misdirection via plausible wrong output.** The naive-connectivity face trace yields a merged polygon that LOOKS valid (one area-2 rectangle instead of two area-1 squares); the failing assertion (area/count) points away from the linkage bug. Single-square and bridge cases pass with the wrong linkage, so the trap only fires on a shared-edge input.
- **Convention inversion.** Exploit a repo whose convention inverts the math intuition (go-geom SignedArea CCW = -1). An orientation requirement then costs zero solution complexity but adds a real trap because the obvious implementation is backwards.
- **Hard-adversarial test instances double as anti-FP hardening.** Non-representable crossing coordinates (x=1/3) separate the robust single-intersection-reuse impl from the per-segment recompute impl. Same tests that raise difficulty also close the FP gaps.

## scryer-clpq-linear (APPROVED OLYMPUS 2026-07-16, 10%) — anti-agent / difficulty patterns
- **Fully-spec'd but implementation-hard canonicalization = the durable wall.** The meta states EVERY dump rule (eliminate non-targets, NewVars-order pairs, magnitude-one first coeff, merge opposing bounds, drop trivial, sort) yet 7/10 substantive fails hit it — FM-projection-onto-a-set + canonical normal form is execution-hard, not underspec'd. Difficulty that survives full documentation is the ideal fair wall: every eval rules FAIL_MISSED_REQUIREMENT `was_mentioned=true`.
- **Hint-in-meta as a calibration LEVER (not a giveaway):** clarify only the wall that near-misses die on (full-store entailment, a 120/123 run's sole gap), leave the implementation-hard wall unworded. Result: 0% -> exactly 10%, in-band. The two walls partition the population: clarification lifts the top, execution-hardness holds the middle.
- **From-scratch exact-math solver compounds three orthogonal demand-axes:** semantic completeness (store/merge/propagate/nonlinear-wake), exact rational arithmetic (rdiv literals, lowest terms, evaluated-rational unify), and canonical output (projection + render). Nova populations fail each axis independently; only 1/13 cleared all three. Scale alone also gates: 3/13 wall-clock-died mid-build.
- **Render layer = cheap high-leverage trap, but a fairness magnet.** io_rat (positive leading rational coeff) killed a 120/121 run at zero solution cost — but three fairness FAILs (pivot/format/empty-case) prove the pretty-printer layer needs worked examples in meta + pivot-independent + non-empty test inputs.

## neva-array-bypass-generalization (APPROVED Olympus 2026-08-01) — confirmed anti-agent patterns

**Pattern that worked: make the failure surface in a subsystem the agent did not touch.** Every cluster-A failure appeared as a panic inside a stdlib runtime function or as a silent 60-second deadlock with empty stdout and stderr. The actual defect (an unresolved name dropped at a package boundary) is never named in any message, so the agent searches the runtime while the bug is in the analyzer.

**Pattern that worked: state capabilities as axes and test the product.** A contract reading "every form the network supports has to work here too, including chains, fan-out, and X" invites a per-axis case analysis. Agents complete every axis and never build the cell where two meet. The composition failure OVER-fires rather than under-fires, which reads as a routing bug.

**Pattern that did NOT work: adding a second subsystem to make an invariant observable.** A barrier component was added specifically so that wrong slot arity would deadlock instead of passing silently. It made a hand-written mutation detectable and killed zero real agents. Observability hardening is FP insurance, not difficulty.

**Calibration note.** 6 of 8 failures shared one root cause, which by the older "one shared cause = unfair" heuristic reads as a fairness problem. It was accepted because the wall was REACHABLE: 2 agents cleared it, 2 more reached 20/21, every evaluator recorded `description_clear: true`, and the FP panel was clean. The test is reachability, not failure diversity.


## Confirmed anti-agent pattern — printer/parser asymmetry (numbat, 2026-08-04)

A repo whose formatter emits a form its own tokenizer cannot read is a free, fair trap. numbat's
`unit_name` prints Unicode superscripts including multi-digit and zero (`m¹⁰`, `m⁰`), while
`tokenizer.rs` accepts only single digits `¹`-`⁹`. State the round trip as a contract
("whatever `unit_name` prints reads back as that same unit") and the discovery stays hidden: agents
probe simple units, which round-trip fine.

Precondition: any codebase with a canonical printer and a stricter parser. Grep the formatter's
output alphabet against the lexer's accepted set — the difference is the trap.

## rust-minidump-stack-containment (APPROVED 2026-08-06) — confirmed anti-agent patterns

Measured on 10 Nova runs, 2 passing. Every wall below is CONTRACT-STATED and FIX-HIDDEN: all ten
evaluators recorded `was_mentioned_in_description: True`, and the batch still read 20%.

**1. Make the unit of an invalidation rule ambiguous between the format's noun and English's
(F-13, 6/10).** State that a contradictory *record* is discarded, in a format where a record is a
header plus its later amendment rows, and put the contradiction in an amendment. Agents discard the
amendment and keep the record. Nothing in the sentence is wrong. The twin fixture with the
contradiction in the header killed zero, because there the two readings coincide — which is exactly
why the wall is invisible to the author's own fixtures.

**2. Write a tolerance rule in terms of the event that must NOT happen (F-15, 4/10).** "Stop before
recording a second X." The first X arms the rule; agents fire on it. **The discriminating fixture is
the one-event case that asserts nothing happened** — the two-event case, which the rule is literally
about, passes under both readings and killed zero.

**3. Add a terminal state whose meaning is provenance, not condition (F-14, 3/10).** A stop reason
meaning "a data file declared this" lands in a subsystem that already has many "we cannot continue"
exits. Those exits are the discoverable attachment points, and wiring them up passes every
declared-end test. One run propagated the merge into the output rule and lost 6 tests from one idea.

**Anti-pattern confirmed dead by this batch: baseline preservation as a difficulty lever.** The
contract that new output fields are omitted when there is nothing to report reds 11 existing tests
if implemented naively — and produced **zero baseline failures in 10/10 runs**. Keep such rules for
fairness (an unstated preservation requirement is unfair), but they buy no difficulty against
current agents. Mutation-grade evidence is not agent-grade evidence.

**Structural note.** The three walls are independent — the kill table shows a near-miss cluster
(1 failure, 48/49) and a deep cluster (4-6 failures) rather than one correlated set. That is what
kept the rate stable at 20% instead of swinging, per L20.

## Confirmed anti-agent patterns — lyon-fill-internal-vertices (2026-08-07)

- **Globally-coupled classification is the strongest single property.** Deciding whether a mesh
  vertex is interior requires the whole mesh, so no local fix converges. This produced a total
  architectural convergence (30/30 runs chose per-vertex one-ring ear-clipping) whose structural
  limits then supplied the difficulty for free.
- **Target the degenerate configurations of the convergent architecture, not more instances of the
  happy path.** The kills came from non-manifold one-rings, non-convex cavities, rotated/fractional
  intersections and self-crossing contours — every one of them a place where the agents' shared
  design bails out or fans wrongly.
- **A deferred-output contract creates a real architectural wall for free.** Because `FillVertex`
  borrows the tessellator's event queue, it cannot be buffered, which forces a second sweep and an
  event-queue snapshot. The borrow checker announces the wall without hinting at the fix.


## Token-form parity as an anti-agent pattern (gluon-format-comments, 2026-08-07)

When a domain spells one concept two ways, agents build the case analysis for the spelling they are
thinking about and treat the other as a variant of it. State the equivalence once in the contract,
then test the non-salient spelling at EVERY position the salient one is tested. Measured: 22 of 37
kills, and the sole failure of the closest near-miss, against 0-1 kills for the same positions in
the salient form.

The pattern is fair by construction — the contract states the forms are equivalent, so every failing
case is a stated requirement — and it is nearly free to author, which is the combination the
difficulty model asks for.

## Anti-agent pattern: the incidental side effect on a shared output channel

The strongest anti-agent constructions are the ones where the agent's code is right and its
DEPENDENCY is what violates the contract. Ordinary traps ask the agent to write something wrong.
This one lets the agent write everything correctly and still fail, because the defect is one call
site away in a component it was right to reuse.

The construction:

1. The repo has a shared entry point for some unit of work whose logger or writer targets a global
   channel — a bare `println!`, a package-level writer, an ambient `io.Writer` reached without an
   injected sink.
2. The task adds a command that must emit STRUCTURED output (JSON, CSV) on that same channel.
3. Reusing the shared entry point is the obviously correct choice on every other axis: it is the
   documented API, it handles all the parsing, and writing a second one would be duplication.

The contract states only the OUTPUT — "have the command return this JSON output". It never states
channel discipline, because stating it ("suppress the reader's log") would hand the fix. The
agent's serializer is correct, its bytes are correct, and they are simply no longer the first bytes
on the channel.

**Why it resists disclosure better than any other pattern measured.** The fairness axiom
(CONTRACT-STATED / FIX-HIDDEN) usually degrades under review pressure: each round of clarification
tends to leak more of the mechanism, and eventually the trap dies. This one does not degrade,
because the fair sentence is short, natural, and already reads as satisfied. Measured across four
batches and 52 runs on vrp-tsplib-edge-weight-types at a 69% kill rate, through three fairness
rounds, a Verify Solution round and an FP panel, never once ruled unfair.

**The authoring requirement that makes or breaks it:** assert from a SUBPROCESS test that parses
the process's entire stdout. An in-process call to the serializer passes on a contaminated build,
so the trap silently evaporates and you cannot tell from your own validation — your reference is
clean either way. Pair the subprocess test with an in-process one on identical data, so a failure
localises to the channel rather than to the content.

**The inverse lesson, from the same problem.** A rule with exactly one reasonable implementation
primitive is NOT an anti-agent construction, no matter how subtle the wrong version looks. Stating
"returned in ascending node-number order" and testing it at DIMENSION 12 with permuted input, where
sorting the zero-based id STRINGS puts "10" before "2", is a textbook index-space trap on paper.
All 10 agents sorted numerically. Uniqueness of the correct primitive, not subtlety of the
incorrect one, decides whether stating a rule spends your difficulty.

## Confirmed anti-agent pattern: sibling-API contamination (go-workflows, 8/10)

The strongest anti-agent property measured on this problem was not complexity — it was a REFACTOR
INVITATION. Ship two entry points that look like variants of each other and give them different
rules for the same construct. Good engineering instinct (factor onto a shared helper) is exactly
what breaks it, and the agent's own green baseline suite confirms the mistake because the old
behaviour is documented in prose and never tested.

Why it is hard to defend against, from the agent's side:
- Every new-feature test passes — the new rule was implemented correctly.
- The whole baseline suite passes — nothing covers the old behaviour.
- The failure appears in a test of an API the task never asked them to touch, so it reads as an
  unrelated regression rather than a consequence of the refactor.

**Difficulty tuning note.** This pattern is nearly free (zero description words, ~40 test lines) and
it discriminates precisely at the top of the band — it kills the agents who got everything else
right. Pair it with one deeper architectural trap; alone it would be a single-point fix.

**Second confirmed lever: WHEN-discoverability.** A requirement can be fully stated and still kill
100% because agents miss the moment it must hold. On this problem "both proceed on their own" ->
"both resume before the scheduler run that drained them finishes" took one cluster from 5/5 kills to
1-2/10 without adding a requirement. Timing clauses are a difficulty DIAL, not just clarity.

## Confirmed anti-agent pattern: type-check shortcut for an unobservable interface (datafixerupper, 5/10)

The strongest form of "the contract is over an abstraction you do not own".

Requirements: a public interface, an abstract base class in the repo implementing most of it and
holding the interesting state in a FIELD, and no accessor on the interface for the quantity your rule
quantifies over. Then state the rule over the interface and add a four-word concessive clause —
"whatever `X` the caller supplies" — and put exactly ONE fixture on a conforming implementation
outside that base class.

Why it defeats a careful agent: the honest implementation cannot inspect the object at all; it must
DECORATE the returned object and observe the outcome at the terminal operation. The cheap
implementation downcasts to the base and reads the field. The cheap one is right for every builder the
repo itself produces, so the agent's own exploration confirms it. When it fails, the assertion is
about a lifecycle or a diagnostic and never about the type test, so the misdirection is total.

Measured on `datafixerupper-ordered-alternatives` batch 9: 5 of 10 runs, the top killer, and the SOLE
failure of the 172/173 near-miss. Without that one test the batch reads 6/10 = 60%, over the ceiling.
Two runs reached the identical wrong guard independently, which is what makes it a pattern rather than
noise. Cost: a ~30-line test helper and zero description words.

Grep the interface for a getter before designing around this. If one exists the honest implementation
is a one-liner and the pattern is dead.


## Confirmed anti-agent pattern — joint fixed point across quantity kinds (customasm, 2026-09-09)

The hardest thing measured on this problem was not any single rule. It was requiring the new
quantity to converge TOGETHER with quantities the resolver already owned (labels, constants,
instruction sizes) whose values only refresh on a full traversal. A settling pass over the new
quantity alone passes every direct chain and fails every mixed one.

Build it with three fixtures and no others: a chain through a user function, a chain through a
constant, and a forward reference into a not-yet-placed unit. Direct A-to-B chains are free passes.

**Do not state an iteration bound.** "The number of iterations must not grow with the length of a
chain" survived three rounds of real engineering and still came back, then a bounded successor was
ruled a functional false positive when a correct-at-every-tested-size passer failed at 11 links.
Promise the capability; let the budget be the budget.

## Confirmed anti-agent pattern: let the repo's own abstraction narrow your contract (rocketpy, 2026-09-10)

The strongest measured trap on rocketpy-propellant-slosh cost zero description words and roughly
thirty test lines, and it killed 6 of 10 runs across two solver families and two separate batches.

**The construction.** Find the container the repo uses everywhere for "a number or a function of
X" — RocketPy's `Function`, or any `Supplier` / `Lazy` / `Provider` / coercion helper. Read its
constructor. If it validates by introspection (`inspect.signature`, `co_argcount`, an arity or
dimensionality check), it almost certainly accepts a NARROWER set of callables than an English
sentence describing the same idea. State the contract in ordinary language, never name the
container, and test the spellings the container refuses.

**Why it resists a local fix.** The exception is raised inside a base-repo file the agent never
edited, so it reads as misuse of the repo class rather than as evidence that the class is the
wrong home for the contract. And reaching for the repo's own abstraction is the instinct that
earns marks everywhere else — the trap punishes the behaviour good review rewards.

**Why it is fair.** The rejected inputs are ordinary callables that plainly receive the stated
argument. Six independent judges marked it `was_mentioned_in_description: true` and Auto Review
scored Description 3/3 Clean over it twice, with one judge writing that the hidden tests "merely
expose valid cases covered by the broad callable requirement".

**The cost model is unusual and matters: this trap is BINARY.** Every failing run failed EVERY
killing cell, so there is no partial setting. Measured counterfactual: dropping the two killing
cells takes the batch from 0/10 to 5/9 = 56%, over the ceiling; dropping one of them flips nobody.
Enumerate by what the VALIDATOR distinguishes, not by what looks varied — of seven callable
spellings shipped, `partial`, a callable instance and `*args` killed nothing because `Function`
accepts them; only `defaulted` and `keyword_only` bit.


## Confirmed anti-agent patterns — datafixerupper-derived-recursion (APPROVED 2026-09-11)

**Telegraphing a requirement does not defuse it when the alternative is a design reflex.** The
description said an unregistered name "stays an unknown type rather than a type without a value",
and the base repo threw `IllegalArgumentException("Unknown type: " + name)`. Every evaluator marked
the requirement BOTH described and code-inferable. It still killed 8 of 10 runs in two independent
batches, because "an analysis pass should be a total function" is a stronger pull than a sentence.
The generalisation: a trap survives disclosure when the wrong answer is what good engineering
instinct produces. Traps that rely on the agent not READING something are fragile; traps that rely
on the agent's own competence pulling the other way are durable.

**Difficulty concentrated in the side effects of the feature, not the feature.** 79 of 87 tests
killed nothing. Nine of ten runs implemented the whole designed mechanism — SCC grouping, ordered
construction, inhabitation fixed point — correctly. Everything that discriminated was a consequence
of the mechanism: what a missing key means, how long a placeholder lives, what a rewritten assembly
path drops. When estimating difficulty, stop scoring the algorithm and start scoring what the
algorithm forces the caller-facing surface to change.

**Adding discrimination to a saturated band is invisible.** Three more killing tests, 11 more kill
events, identical 1/10. Once one cluster takes 8/10, extra traps cannot show up in the rate. Judge
them as FP insurance and reviewer-proofing, not as band movement.


## Confirmed anti-agent patterns — ray-optics-formula-conditionals (APPROVED 2026-09-14)

**The strongest traps were single exceptions to rules the agents got right.** All four killers had
the same form: identical operands in an interval combine, the one asymmetric polarity of a dual
combinator, a valid node over an invalid operand, a repo idiom's numeric domain. Each needs no
description words beyond the general rule, and each looks like a bug somewhere else when it fails.

**Clarity did not defuse a symmetry trap.** F-27 rose from 3/11 to 6/10 after the redesign made the
`or` sentence shorter and more explicit. Like F-24, a trap whose wrong answer is a sound engineering
instinct (make `or` mirror `and`) survives disclosure.

**Stacking math is real at the low end.** About eight independent 30-60% traps from reviewer findings
gave 0/11 even with the unfair walls removed. Four correlated seams (every failing run failed at
least two killing tests) gave 1/10. Aim for three or four strong seams, not eight medium ones.

**The hard-looking design carried no difficulty.** Nested switching sets, selection-aware guard chains
and fixpoint narrowing cost five reference bugs and several review rounds. They were deleted, and the
problem was accepted without them.

## Confirmed anti-agent patterns — worldengine-orographic-precipitation (APPROVED 2026-09-16)

**A stated noun beat a stated formula.** "A wind layer with a direction and a strength per cell"
killed 7/10 (F-28); a fully stated steady-state transport killed 0/20 (L58). The wall that holds is the
one whose wrong answer still passes everything the agent checks: sibling keys round-trip their values
and fail only on the concept's name.

**A guard written correctly and never called.** When a framework declares a predicate its call path
ignores, agents implement the predicate and copy the unconditional sibling `execute` (F-29). The trap
needs one direct-call test and no extra prose.

**Misdirection can point at the wrong target.** Placement prose ("between plates and precipitations")
steered every batch-1 agent into rewriting an existing step (L57). That is FP exposure, not
difficulty: it was neutralised with one sentence, and the rate did not fall.

## Confirmed anti-agent patterns — cwerg-bcopy-bzero-lowering (APPROVED 2026-09-16)

**The strongest wall was an existing pass's weak invariant.** A width pass that only promises the
low bits killed 10/10 before the rule was stated and 2/10 after five batches (F-30). Telling agents
the result does not tell them where the fix lives, because the pass is not in any file the feature
names.

**Twins double the surface without doubling the prose.** One parity sentence made the constant
folders (F-31) and C++ CFG handling at scale (F-32) separate walls, each killing 2/10 with failures
that read as unrelated crashes (`could not find matching pattern for mov fw1@rdx 4294967294`, a bare
SIGSEGV).

**Parity also stacks unfair walls if you let it.** Each pre-existing divergence a reviewer finds looks
like a free trap (L50). Two of them, float DIV and narrow DIV/REM chains, took a batch to 0/9. Walls
the feature does not reach are not difficulty (L60).

## Confirmed anti-agent patterns — tippecanoe-tile-join-size-recourses (APPROVED 2026-09-16)

**The machinery was free; the accounting was not.** Cross-layer ranking with a stated tie-break,
attribute-pool compaction, extent rescaling and a booking restructure drew no failure attribution in
ten runs. Seven of nine failures were two accounting edge cells: a recourse that could not act still
recorded itself (F-15), and an inherited field kept the reader's old operator (F-33). Confirms L58 on a
second problem.

**The traps that worked were bugs in the reference first.** Both killers came out of reviewer findings
against my own solution (L50). The trap DESIGN.md led with, pool compaction, killed nobody.

**A harness artifact can hide every trap at once.** With 7 of 10 runs graded against a stale binary,
the JUnit files showed 49/49 failures for nearly every run. The batch was still accepted at 1/10, but
no per-test difficulty could be measured (L63).

## Confirmed anti-agent patterns — sfepy-adaptive-stepping-accounting (APPROVED 2026-09-16)

- **Aliased rollback over an in-place solver (F-34), 8/13.** The rollback branch is correct; the callee
  mutates the snapshot. Only the nothing-accepted fixture sees it.
- **Hostile user hook against a stated bound (F-10 cell), 7/13.** Three words of contract. A `min()`
  clamp satisfies "not larger" and fails "smaller".
- **Rollback over-reach to the index (F-35), 2/13.** Assert the relation between the last record and
  the stepper, once per stop kind.
- **Compounding:** 6 runs missed both F-34 and the hook cell. Both sit in the same stop and retry path,
  so a run that rushes one tends to rush the other.
- **Not a pattern: breadth.** 87 of 117 tests, including an elastodynamics rollback lane built over
  three review rounds, killed nobody.

## Confirmed anti-agent patterns — mwparserfromhell-site-aware-parsing (APPROVED 2026-09-18)

- **Lookahead run over a marker-split, backtracking stream (F-36), 11/19.** Four shortcuts, four
  symptoms: next-segment-only scan (C/Python divergence), slicing back into the shared list (lost
  characters after a failed route), re-splitting into single characters (tag names break), and the
  reject branch emitting peeked text (split text nodes). A seeded generated corpus with failed routes
  finds all four; the hand-written trail tests found none.
- **In-band EOF sentinel (F-37), 7/19.** The repo idiom `while ((this = read()))` is copied into the new
  loop; the fix belongs in the reader.
- **Two computation paths for one property (F-10 cell), 5/19.** The escape rule held at parse time and
  was dropped on reassignment.
- **Not patterns here: a second implementation arm (delegated, L67), a wiki-markup carve-out, namespace
  normalisation breadth and Unicode trail sets.** All killed nobody.

## Confirmed anti-agent patterns — kira-loop-crossfade (APPROVED 2026-09-18)

- **Worked (1/10):** F-10 live-change cell. A handle switches to a loop that ends before the playhead
  while the wrap is shortened by the crossfade. Two stated sentences meet there; one run broke the wrap.
- **Did not work (0/10 each):** stated decoder seek budgets (startup, per wrap), head frames kept for
  the pass, mirrored reverse fade, clamp to half the loop, easing curves, source-frame blending under
  non-unit rates, stereo, bake-equals-live, seconds conversion at other sample rates, eased and seek
  commands through live handles. Each was a precisely stated local rule.
- **Counterfeit difficulty:** a gated buffered-prefix test that encoded the reference's queue depth
  failed six correct runs (L69/L70). Never count such a cluster as a trap.

## Confirmed anti-agent patterns — planetiler-custommap-schema-composition (APPROVED 2026-09-18)

- **Worked (7/10):** F-38, validity against the pre-input snapshot. One input adds a layer and removes
  it again; the running-map check accepts it. Sole failure of three 82/83 runs.
- **Worked (3/10):** F-9 origin variant. The validator re-resolves a bundled root's relative examples
  reference as a filesystem path.
- **Did not work (0/10 each):** deferred argument settlement (the repo's fixed point already runs after
  the merge, so F-22 did not apply), layer position and feature append order, last-set scalars that
  survive accessor defaults, sources replaced by id, tag mappings per key, diamond dedup, cycle naming,
  depth-first order, relative and bundled parent resolution, comma-list CLI generation.
- **Counterfeit difficulty:** an unstated static signature, which failed 8/8 at compile time (L72).

## Confirmed anti-agent patterns — featurevisor-minimal-rebucketing (APPROVED 2026-09-19)

- **Worked (7/11):** F-40, a record keyed by user strings that must hold `__proto__`. Sole failure of
  six 33/34 runs.
- **Worked (3/11):** F-39, a repo helper whose lossy path only the new regime reaches. Independent of
  F-40, which kept the batch from reading as one special key.
- **Did not work (0/11 each):** the inclusive/prefix/half-open boundary mismatch the design was built
  on, lowest-first retention, declared-order refill, region cuts through later slots, sort-and-merge,
  idempotent rebuild, reuse by rule key, zero overrides, stored-ranges changes, disjoint accounting,
  build collection order and the two-environment print trace.
- **Counterfeit difficulty, removed:** formatter return-shape tests (7 kill events in batch 1, 0 after a
  tolerant reader, no pass moved).


## Confirmed anti-agent patterns — ir-sim-scenario-events (APPROVED 2026-09-19)

- **Loader-injected attribute (F-41), 10/11.** When the repo's batch loader assigns a per-entry key
  (group index) that the public constructor defaults, any runtime-created object silently joins an
  existing structure and loses the keyed dispatch. The only symptom is an object that does not move.
  Zero description words; the promise "runtime objects are ordinary members of everything the engine
  does" makes it fair.
- **Positional undo order (F-42), 2/11.** Two deletions restored by ascending saved index shift each
  other. One two-deletion fixture.
- **Not anti-agent any more:** multi-path lifecycle integration the prompt names (0/11 across eleven
  reproduced mutants). Agents now wire every named path.

## featurevisor-target-specialization (APPROVED Olympus 2026-09-19)

- **Equivalence-to-the-repo's-evaluator is a contract that stays hard when fully stated.** The rule is one
  sentence; the instance space (nested lists, empty containers, decided negations, per-list match rules) is
  combinatorial, and a seeded corpus probes it. This is P1 (algebraic-law contracts) confirmed.
- **Baseline preservation beats any authored wall when the natural home of the change is an exported,
  separately tested helper.** 7/20 kills, zero description words.
- **Do not count on stated per-kind rules.** Force OR vs global AND vs rule-override precedence read as a
  strong F-3/F-10 design and killed 1 of 20.

## csbindgen-struct-layout-fidelity (APPROVED Olympus 2026-09-21)

- **Composition beats breadth.** 70 F2P cells over ~30 stated rules; 63 killed nobody. The batch was
  decided by three families: rule x rule composition (F-44, 7/10), scalar-to-aggregate path reuse
  (F-45, 3/10) and source-model reuse on the target side (F-46, 2/10).
- **The difficult cell can be the one fairness forces you to keep.** F-44 was dropped for solvability,
  restored because its fixtures were FP traps, and became the lead trap.
- **A full host-language semantic in the contract is not difficulty, it is an unbounded review surface
  (L80).** It produced 11 FAIL rounds and zero measured passes; the accepted problem does not have it.

## libspatialindex-tpr-temporal-knn (APPROVED Olympus 2026-09-21)

- **A derivable core has no fair wall of its own.** Three fully stated geometry kernels read 7/10; 57
  probes, 16 reviewer-suggested tests and 4 composition cells killed zero passers. Coverage suggestions
  are free difficulty only while the passing population still diverges.
- **Discarded state is where prose cannot reach (F-47).** Entry expiry forced changes to the node page,
  node bounds and reload that no geometry reasoning implies. It moved the rate 70% to 42% and carried the
  lead wall (4/12). The piecewise kernels it also required killed 0/12.
- **Stack a cheap second wall on the same runs.** F-48 (legacy `Point` acceptance, 3/12) landed on runs
  that also failed F-47, so neither wall alone decided them.
- **An internal validator in your test is not a wall (L82).** It read as 0/10 and was nine-tenths my
  own assertion.

## siliconcompiler-flist-roundtrip (APPROVED Olympus 2026-09-23)

**Confirmed anti-agent pattern: flatten a graph on write, require it rebuilt on read.**

A serialized form that lists every node flat, with the parent/child relation carried inside each
record, defeats the natural reading loop. Agents walk the records and attach each named node to the
object the read was called on; every node and every field comes back correct, and the graph is still
wrong by one extra root edge per transitive child. Measured 7/10, and the sole failure of five runs at
56/57.

Two design requirements make it measurable, and neither is the edge rule itself:

1. **Three levels minimum.** On a root with siblings, re-parenting is indistinguishable from correct.
   The discriminating assertion is the MIDDLE node's own edge list.
2. **A separate rule for leftovers** ("a record nothing references attaches to the named fileset"), so
   that blanket attachment to the root is visibly not the rule.

State ownership once, plainly, and never name the repo's `add_dep`-equivalent. Do not clarify further:
measured by replay, spelling the ownership rule out took the batch to 9/11.

## pyfakefs-block-inode-accounting (APPROVED Olympus 2026-09-23)

**Confirmed anti-agent pattern: make the resource capable of "unlimited" and make it report a number.**

A stats call (`statvfs`) has to return finite `f_files` / `f_blocks` even when the mount is unlimited.
Agents compute that reporting figure once and reuse it as the allocation ceiling, or tie it to the
other axis ("no more inodes than blocks"). Every stated rule is met and a write just past the reported
figure is refused. Measured 2/10 as the sole failure of two near-misses (F-50).

It pairs with a second free one on any accounting pick: **account what is stored, where the repo's
getter reports something else on one platform.** pyfakefs reports `st_size == 0` for Windows symlinks,
and the repo's own test pins it; agents sized by `stat` (F-51, 3/11, 5/12, 1/10).

Design requirements: one test just past the reported figure on each axis (bytes, inodes,
reconfiguration back to unlimited), and one test on the non-default OS type asserting the stored
quantity in accounting and in every report.

## pyocd-sequence-expression-kernel (APPROVED Olympus 2026-09-24)

Confirmed on an expression engine with several consumers of one operator table:

- **F-52 — two stacked boundaries with different rules.** Put a full-domain rule at a delegate seam
  and a narrowing rule at the operation below it, in adjacent sentences, and observe the seam with a
  recording delegate. 2/10, both near-misses failing nothing else. It works only once the seam rule is
  concrete; stated abstractly, the same tests killed 7/11 by under-reducing.
- **F-31 without a second language.** A constant folder and an interpreter are twins. Agents fix the
  one the feature points at and keep the other's old rewrites (2/10), helped when the repo's own tests
  pin the old rewrites (F-12).
- **What did NOT add difficulty:** a static value-kind checker (strings, void calls, variadic
  arguments, conditional branches, string-returning calls), two literal-vs-variable matrices, AP/DP
  register widths and byte-response decoding all killed 0/10. Eleven review rounds of coverage bought
  none of the band.

## teavm-method-summaries (APPROVED Olympus 2026-09-24)

Confirmed on a compiler analysis consumed by several optimizer passes:

- **F-53 — the direction of a fixed point.** An all-paths fact (never returns null) over a recursive
  call graph must start optimistic. 4/10 started pessimistic, three as their only failure, with the
  requirement stated outright. Stating it did not defuse it (L94).
- **F-54 — a frozen legacy path next to a new handler.** When the new mode handles a case the base pass
  ignores, agents make the old path handle it too. One off-path test, 2/10.
- **F-55 — a wildcard key through a deferred path.** A pass that stores per-variable keys for a join
  replays them through the per-variable API; an "all instances" sentinel crashes there. Test the
  straight line and the join separately, 2/10.
- **What did NOT add difficulty:** dispatch resolution, unknown bodies, invokedynamic, array returns,
  `<clinit>` propagation and the end-to-end TeaVM wiring all killed 0/10. 21 of 26 tests killed nobody.
