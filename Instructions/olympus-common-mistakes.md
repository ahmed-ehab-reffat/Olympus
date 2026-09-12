# Olympus Common Mistakes

Catalog of mistakes to avoid when creating Olympus challenges. Each mistake includes what goes wrong, why it matters, and how to fix it.

---

## Agent failure instincts to design against (generative defaults — weaponize FAIRLY)

> Generative-model defaults that fire BEFORE the agent reads the spec carefully. Each is fair ONLY if you DOCUMENT the discriminating contract in meta.md (Olympus has no hidden requirements — a planted distractor must be disconfirmable from an authoritative agent-visible artifact, never knowable only from the hidden test). Weaponize the instinct into a documented discriminator, then test it. (Same-object + pipeline-ordering instincts live in `olympus-extreme-complexity-guide.md` §2/§4; banker's-rounding in `TESTS.md`.)

- **Default/catch-all fallback** — agents close a switch/match with `else -> "default"/"unknown"` so nothing crashes. WEAPONIZE: document a CLOSED vocabulary of codes with NO catch-all; an out-of-set input is a hard error, not a default. TEST: assert every emitted code is a member of the documented set + a case the agent would have funneled to fallback now hits the explicit path.
- **Single uniform error regime** — agents apply one response everywhere (all raise, or all swallow). WEAPONIZE: document NON-uniform handling (malformed manifest aborts the batch; malformed row is quarantined with a recorded reason, batch continues). TEST: bad-manifest aborts (no partial output) + bad-row quarantined (siblings still processed).
- **Doc-trusting over the real contract** — agents trust a README/CHANGELOG/sample over the live type/schema. WEAPONIZE: place a plausible-but-STALE artifact at BASE that the authoritative schema/type DISCONFIRMS (fair distractor — the agent can read the real contract). TEST: assert the behavior the authoritative contract dictates (contradicting the stale artifact).
- **Good-enough stop-at-80%** — agents implement the headline cases, see green, stop; the long tail is unhandled. WEAPONIZE: document a BROAD family (all members enumerated in meta) so an 80% impl still fails ~20% of edge tests (also clears the eff-LOC floor honestly). TEST: cover the full enumerated family, not just headline members.
- **basename-vs-absolute-path** — agents key/compare on `basename` and collide two paths sharing a leaf. Document that the full normalized path is the identity key; test two distinct dirs sharing a filename.
- **surface-identical-record** — agents dedup/compare on visible fields and miss a discriminator carried elsewhere (id, source, ordinal). Document the true identity tuple; test two records that look identical but are distinct.

---

## Top Proven Agent Failure Patterns (Design Around These)

> **Quick reference of highest-impact traps, ranked by failure rate. Full details in numbered entries below.**

| Pattern | Failure Rate | Challenge |
|---------|-------------|-----------|
| Shared LLM blind spot: specific examples override general rules | 100% (14/14) | cliffy-output-format |
| "Initializing the full X system" = call default constructor | 60% (6/10) | cliffy-output-format |
| Convenience method reuses default setup | 60% (6/10) | cliffy-output-format |
| Pre-existing class not exported (TS2305) | 90% (9/10) | cliffy-output-format |
| clearRegisteredAliases same-command globals | 100% (8/8 failing) | cliffy-command-aliases |
| InFormat mutation ordering in CLI layer | 50% (6/12) | dasel-multi-file |
| Writer null quoting pipeline bypass | 45% (5/11) | dasel-csv-options |
| Writer ragged-row dead code (tautological check) | 45% (5/11) | dasel-csv-options |
| Cross-file help text update incomplete | 36% (4/11) | dasel-csv-options |
| FileLoadError consistency across code paths | 33% (4/12) | dasel-multi-file |
| Stateful callback counter semantics | 100% (10/10 Orion) | cliffy-prompt-wizard |
| Type injection bypass (Nova-specific) | 80% (4/5) | cliffy-prompt-wizard |
| fmt.Errorf no-op passthrough (Go) | 36% (4/11) | yaegi-reflect-identity |
| Implements for interpreter interfaces (Go) | 95%+ | yaegi-reflect-identity |
| Go Options struct field naming mismatch | 70% (7/10) | ferret-csv-codec |
| Vague output format in description (regex enforced) | 100% (10/10) | nmap-scan |
| Implied requirement via flag existence | 82% (9/11) | nmap-scan |
| Invalid type exit 2 (permissive switch default) | 27% (3/11) | nmap-scan |
| Cobra RunE stderr contamination | 18% (2/11) | nmap-scan |
| Existing repo constant vs spec name | 18% (2/11) | nmap-scan |
| Pattern-followable features (BUSTED -- too easy) | 0% failure | dasel-reduce-takewhile |
| Two-sentence naming spec inversion (T.M vs M) | 64% (7/11) | yaegi-callstack-postmortem |
| Capture-before-recover-defer ordering | 36% (4/11) | yaegi-callstack-postmortem |
| Frame walker missing kind guard (phantom outer frame) | 45% (5/11) | yaegi-callstack-postmortem |
| Public API split: enum in `expr` vs `conf` package | 25% (3/12) | expr-licm-predicates |
| Iter-pointer set incomplete (`#index`/`#count`/`#acc` missed) | 17% (2/12) | expr-licm-predicates |
| Cross-body shared-binding substitution incomplete | 8% (1/12) | expr-licm-predicates |
| Trap-stacking ceiling at Mars C / B-shape | binary 0%↔100% | dasel-collection-funcs, expr-licm-predicates |

---

## The 12 Commandments of Olympus (Proven Across 11+ Approved Submissions)

### 1. Description Tightening > Adding Tests
When a problem is too easy, tighten the description BEFORE adding more tests. Adding tests with the same description gives agents more surface area to infer from. Only add tests after description tightening fails to move the needle.
**Evidence**: cliffy-command-aliases -- community Diamond submitter confirmed. dasel-csv-options -- 87 vs 108 tests didn't change difficulty; description tightening and behavioral requirements were decisive.

### 2. Every Testable Behavior MUST Be in meta.md
The #1 review criterion. Every test assertion must trace to a description sentence. "Surprise tests" (testing undocumented behavior) get flagged as unfair. Agents near-passing (47/49) who fail on undocumented tests get FAIL_UNDOCUMENTED verdicts.
**Evidence**: cliffy-undo-history Run 5 -- 3 near-passes marked FAIL_UNDOCUMENTED because record() throwing at runtime wasn't in description.

### 3. WHAT Not HOW -- Behavioral Descriptions Only
Describe outcomes, not implementation. No code examples, no vague language. But DO include exact API names, return types, and parameter shapes when tests depend on them.
**Evidence**: All 11 approved submissions use this pattern. dasel-multi-file description went through 5 iterations to convert Go type signatures into prose while preserving alignment.

### 4. Never Remove Eval-Proven Description Elements Based on AI Suggestions
The AI description quality checker and alignment checker directly conflict. Quality says "too detailed." Alignment says "tests depend on this." When eval data proves an element is critical (agents fail without it), keep it and accept the quality warning.
**Evidence**: cliffy-output-format Run 15 -- AI HIGH suggestion removed CommandError export mention. 9/10 agents got TS2305 compile error. Human reviewer approved with hint restored.

### 5. Cross-Package Integration Is Mandatory
Every problem MUST require agents to touch files in 2+ separate packages. Without this, agents solve in ~50 messages and median message count fails the long-horizon requirement.
**Evidence**: dasel-csv-options Diamond -- adding internal/cli tests boosted median from ~60 to 141 messages. cliffy-output-format -- Deno import graph naturally forces cross-package changes.

### 6. Pattern-Followable Features Are Unsalvageable
If the codebase already has 3+ examples of the exact same structural pattern, no amount of tests will make it hard. Agents copy-paste and adapt.
**Evidence**: dasel-reduce-takewhile -- 100% pass rate (10/10) despite 97 tests. Same AST pipeline as existing filter/map/sortBy.

### 7. Expect 3-20 Iterations
Complex features take 4-10 description attempts. Diamond problems take 17-26 total iterations. Track everything in feedback.md. Change ONE thing per iteration.
**Evidence**: dasel-csv-options: 26 iterations. yaegi-reflect-identity: 20 attempts. cliffy-output-format: 24 attempts.

### 8. Windows Patch Encoding Will Break You
PowerShell redirect produces UTF-16LE with BOM. Windows git produces CRLF. Both cause silent failures. Always generate patches via Python subprocess with explicit LF.
**Evidence**: Every single submission has encountered this. Platform git apply silently fails on CRLF patches.

### 9. Cross-Feature Interaction Tests Are the Best Difficulty Lever
Single-feature tests are too easy. Tests combining 2-3 features (middleware + abort + onion unwinding, null + strict + newline, format + columns + sort) catch implementation mistakes that simple tests miss.
**Evidence**: cliffy-middleware Run 5 (100% pass) vs Run 6 (30% pass) -- adding 7 cross-feature tests was the critical change. dasel-csv-options -- null-through-pipeline was the #1 blind spot across 30+ runs.

### 10. Same-Object Interaction Tests Are the #1 Diamond Trap
Agents always test the parent-child case. They never test the same-object edge case. Design at least one test per feature that exercises same-object behavior.
**Evidence**: cliffy-command-aliases -- 8/8 failing runs (100%) fell for same-command local+global clearing across 3 different architectural variants.

### 11. One Dominant Trap Test Is Enough
Multiple medium-difficulty tests don't add up to one genuinely hard cross-cutting test. A single well-designed trap test can cause 100% of failures.
**Evidence**: cliffy-command-aliases approved with 51 tests but 1 test caused 100% of failures. cliffy-output-format -- 2 tests out of 143 were the only difficulty lever.

### 12. Symmetric Read/Write Operations Create Natural Traps
When a feature has a read side and a write side, agents implement the read side correctly but miss write-side symmetry. The write side requires routing values through the same pipeline.
**Evidence**: dasel-csv-options -- 5-6/12 failing agents in every run had isNull guards bypassing the quoting pipeline on write.

---

## Description Mistakes

### 1. Walls of Text
**What**: Bundling all requirements into a single dense paragraph for complex multi-subsystem features.
**Example**: cliffy-command-scaffold single-paragraph version got immediate formatting rejection (0/12 agents).
**Fix**: Use ## section headers with bullet lists per subsystem for 4+ subsystem features. Use flat paragraphs for single-API features. Use bullet lists for 10+ distinct options. Every sentence earns its place.

### 2. Missing Pre-existing Type Exports
**What**: Tests import a class that already exists in the repo, but description only mentions "the error classes are exported" without naming the pre-existing base class.
**Example**: cliffy-output-format -- 9/10 agents failed with TS2305 because CommandError wasn't listed by name. Agents only exported the 3 NEW error classes.
**Fix**: Explicitly enumerate every exported symbol by name, including base classes and pre-existing types that tests depend on. "The X classes" is ambiguous when some are new and some pre-existing.

### 3. Overlapping General + Specific Constraints
**What**: When a general constraint is followed by specific examples in the same sentence, ALL agents implement only the specific examples and skip the general rule.
**Example**: "Only the returned object or array triggers formatting. If the action returns undefined or null, no formatting occurs." 14/14 agents guarded only null/undefined, missing the broader "only object or array" constraint.
**Fix**: Remove the specific examples entirely (let agents reason about the general rule). Or restructure: "only a returned object or array triggers formatting and any non-object return value is silently ignored." NEVER list every excluded type explicitly -- that pushes pass rate to 100%.

### 4. Getter vs Method Ambiguity
**What**: Description says "size" without clarifying if it's a property getter or a method call. Tests expect one or the other.
**Example**: cliffy-command-aliases -- AliasRegistry.size was ambiguous. cliffy-undo-history -- hasHistory() needed explicit "as a method" qualifier.
**Fix**: Always write "as a method" or use `name(): returnType` notation. For TypeScript, distinguish getters (no parens) from methods (parens).

### 5. Return Type Not Specified When Different from Parent
**What**: New method returns a different type than similar existing methods, but description doesn't state the return type.
**Example**: cliffy-undo-history -- listCheckpoints() returns string[] instead of parent's CheckpointData[]. 1 compile failure from wrong return type.
**Fix**: If a new function returns a type different from similar existing functions, say so explicitly. Agents infer return types from existing patterns.

### 6. Sync vs Async Not Stated
**What**: Description doesn't specify whether methods are synchronous or asynchronous. Agents add async/await unnecessarily.
**Example**: cliffy-undo-history -- 6/10 agents declared undo()/redo() as async. First assertThrows() produced unhandled promise rejection that aborted the entire Deno test file.
**Fix**: Add "All methods are synchronous" or "undo() and redo() execute synchronously/inline." One sentence prevents catastrophic test runner crashes.

### 7. "Initializing the Full X System" Phrasing
**What**: Agents interpret "initializing the full X system" as "call the default constructor" which includes built-in defaults.
**Example**: cliffy-output-format Run 11 -- 2 FAIL_AMBIGUOUS_TASK because "initializing the full output format system" was read as calling outputFormat() which includes built-in formatters.
**Fix**: Replace "initializing the full X system [if needed]" with "sets up Y without adding any built-in Z, or adds to existing if already configured."

### 8. Non-ASCII Characters
**What**: Em dashes, curly quotes, or other non-ASCII in meta.md.
**Fix**: Platform hard-rejects with non_ascii_character before any human review. Use -- instead of em dashes. Run byte-level check before submitting.

### 9. Runtime Validation Not Documented
**What**: A function throws at runtime for invalid input, but description doesn't mention it.
**Example**: cliffy-undo-history Run 5 -- 3 near-passes (71/72) marked FAIL_UNDOCUMENTED because record() threw for invalid type strings. Agents assume TS compile-time safety is sufficient.
**Fix**: If a function throws, document it. "record() throws TypeError for invalid type strings."

### 10. Description Hints Cause Catastrophic Solve-Rate Increases
**What**: Adding one explanatory sentence to satisfy AI checkers makes the problem trivially easy.
**Example**: cliffy-middleware -- adding one sentence about ancestor ordering caused pass rate to jump from 17% to 100%. cliffy-output-format -- two sentences about guarantee formula = +40% pass rate.
**Fix**: Never add implementation hints to satisfy AI checkers. Remove the test instead of adding the hint.

### 11. Two-Sentence Naming Spec Inversion
**What**: Description states a naming convention across two sentences where sentence 2 implies a wider field set than sentence 1 mentions. Agents read sequentially, anchor to sentence 1, produce names that satisfy it but fail sentence 2's logical implication.
**Example**: yaegi-callstack-postmortem -- "Names are unqualified: top-level functions appear as `f`, not `pkg.f`. Pointer-receiver methods and value-receiver methods share the same frame name; the leading `*` is never included." Sentence 1 anchors "no qualifier ever". Sentence 2 mentions stripping `*`, which is meaningful only if the receiver type IS in the name. 7/11 failing runs (64%) returned `M` instead of `T.M`. Both Orion-as-policy runs hit it.
**Fix**: Ship one concrete example (`bar`, `T.M` literal) BEFORE the naming-rule sentences. Description-quality bot may flag as over-spec; defend with empirical pass-rate data per Commandment #12 (Don't remove eval-proven elements based on AI suggestions).

### 12. Capture-Before-Recover-Defer Ordering
**What**: Existing infrastructure has a deferred recover handler that runs user-defined defers, then checks `if recovered != nil`. New feature observing the recovered state must run BEFORE user defers, otherwise a user `defer recover()` in the same frame consumes the value and the new feature's guard sees nothing.
**Example**: yaegi-callstack-postmortem `runCfg` defer at `interp/run.go:209`. Reference places `captureStack(f, oNode)` IMMEDIATELY after `f.recovered = recover()`, BEFORE the `for _, val := range f.deferred` loop. 4/11 failing runs placed it AFTER; goroutine `defer recover()` killed `f.recovered` first. Bug invisible in multi-level chain tests; surfaces only for goroutine-recovers-its-own-panic-in-same-frame.
**Fix**: When adding a feature that observes transient state inside an existing defer chain, place new logic BEFORE existing user-callback dispatch. Confirm with a test where user callback runs in the SAME frame as the observed event.

### 13. Frame Walker Termination Missing Kind Guard
**What**: Walking interpreter frame chain via `for cur != nil` reaches synthetic outer frames (fileStmt, root frame) and emits phantom Name="" entries. Walker requires dual guard: `cur != nil && cur.funcNode != nil` PLUS break on `kind != funcDecl/funcLit`.
**Example**: yaegi-callstack-postmortem -- 5/11 failing runs (45%) emitted `[main, ""]` or `[bar, foo, main, main]` because their walker stopped only on `cur == nil`. Reference uses dual guard.
**Fix**: When walking interpreter frame chains, document "interpreted-frame call stack" semantics behaviorally AND ship a hint about non-function frames OR a test asserting no `<unknown>` frame exists in normal panic chains.

### 14. Vague Output Format When Tests Enforce Exact Regex
**What**: Description says "final line is summary with counts of X, Y, Z" but test enforces `^\d+ added, \d+ removed, \d+ changed$`. Agents add label prefixes like "Summary:", "Added:", etc.
**Example**: nmap-scan -- 10/10 agents in Run 1 failed because they added a "Summary:" prefix. 8/10 flagged as FAIL_TEST_MISMATCH (unfair).
**Fix**: When a test uses a regex or exact string match on output, the description MUST show the exact format with a literal example: `Final line must be exactly in the format N added, N removed, N changed (e.g., 3 added, 1 removed, 2 changed).`

---

## Test Mistakes

### 1. Using Internal Symbols
**What**: Tests import unexported functions, types, or package constants.
**Example**: dasel-multi-file -- tests in internal/fileutil/fileutil_test.go enforcing code location caused 100% FAIL_TEST_MISMATCH. 
**Fix**: Test through PUBLIC interfaces only. Use parsing.Format("ndjson") not internal constants. Import from mod.ts not internal paths.

### 2. Test Helper Doesn't Test the Real Behavior
**What**: A test helper calls functions separately instead of testing the multi-argument behavior.
**Example**: dasel-multi-file -- helper execFiles(t, a, b) called files("a") then files("b") in separate invocations, not the multi-arg files("a", "b") call.
**Fix**: Build a single selector invocation that tests the actual behavior agents must implement.

### 3. Generic Test Function Names (Go)
**What**: Test functions use names like TestReadBasic that agents might also create, causing compilation failures.
**Fix**: Always use a unique prefix: TestKDL, TestNDJSON, TestCSV, TestAggregation. Prevents name collisions with agent-created tests.

### 4. Weak Assertions
**What**: strings.Contains with common substrings, rejects.toBeDefined(), or assertions that pass with empty output.
**Fix**: Assert specific content, not just shape. Pair negative assertions ("doesn't contain X") with positive ones ("contains Y"). Use assertEquals on exact values.

### 5. --bail Flag
**What**: test.sh uses --bail, stopping on first failure.
**Fix**: Never use --bail. All tests must run even if one fails. Reviewers need complete test results.

### 6. Not Running ALL Base Tests
**What**: test.sh base mode only runs a subset of existing tests.
**Example**: If repo has 200 tests across 15 files and test.sh only runs 5 files with 40 tests, reviewers flag it.
**Fix**: Run ALL existing tests in base mode. Reviewers count them.

### 7. test.sh Not Executable
**What**: test.sh doesn't have execute permission in the patch.
**Fix**: git update-index --chmod=+x test.sh before generating patch. Mode must be 100755.

### 8. test.sh Argument Parsing Assumes Position
**What**: MODE=$1 breaks when platform passes --output_path as first argument.
**Example**: Caused 4 consecutive BASELINE_ERRORs on cliffy-output-format.
**Fix**: Use position-independent argument parsing. Platform invokes as ./test.sh --output_path <path> base.

### 9. Tests Using Solution-Specific Helpers
**What**: Tests call helper functions that only exist in the solution, not in the base code.
**Fix**: Tests must compile and run (failing) against base code. Use only existing public APIs or self-contained test utilities.

### 10. Misleading Test Names
**What**: Test name says "validation runs after parsing" but assertions don't verify that ordering.
**Fix**: Test names must match what the assertions actually verify. Remove unused variables.

---

## Solution Mistakes

### 1. Irrelevant Whitespace Changes
**What**: Solution patch includes blank lines added to existing functions, trailing newlines in pre-existing files, or other whitespace-only mutations.
**Example**: cliffy-output-format final review -- extra blank line in FormatterRegistry class body and double blank line after OutputFormatSettings interface blocked approval.
**Fix**: Always scrub solution.patch for pure-whitespace mutations in pre-existing files before submission.

### 2. Build Tags in Solution Files (Go)
**What**: Solution files use build tags unique to the submission, but no other repo file uses that tag.
**Example**: dasel -- if no other file uses //go:build kdl, the solution files won't compile in normal go build.
**Fix**: Match existing conventions. Other dasel parsers have NO build tag -- they are always compiled in.

### 3. Dead Code
**What**: Unused exports, validation code never called, duplicate implementations.
**Example**: dasel-multi-file -- ReasonRead constant defined but never used. cliffy-config-file -- flattenNestedConfig, unflattenConfig, duplicate kebabToCamelCase.
**Fix**: Reviewers scan for unused exports. Remove all dead constants, functions, and variables.

### 4. Comments That Break Repo Convention
**What**: Comments in solution or test code that the target repo's own source does not use.
**Fix**: Match the target repo's comment convention; default NONE. Add comments only where the repo's existing source already does, and then only in that exact style. Off-convention comments (and banned markers like `// TODO/FIXME/NOTE`) are a strong AI tell.

### 5. Scope Creep
**What**: Implementing features beyond what meta.md describes.
**Fix**: Only implement what's described. Unrequired code inflates LOC and causes Quality Score penalties.

### 6. Missing Blank Import (Go Self-Registering Parsers)
**What**: New parser uses init() for self-registration but the blank import isn't added to cmd/main.go.
**Example**: dasel -- parser exists but is never loaded without _ "github.com/.../parsing/kdl" in main.go.
**Fix**: Add blank import alongside new package. The init() triggers registration only when imported.

### 7. Regex-Based Parsing for Complex Language Syntax
**What**: Solution uses manual regex scanning to detect strings, comments, regex literals, or optional chaining in JavaScript/TypeScript, instead of AST-based parsing. Fundamentally unreliable and will break on real-world edge cases.
**Example**: node-macros -- buildProtectedRegions used manual character scanning that cannot handle full JS syntax. hasOptionalChainBefore used substring regex checks that fail with varied formatting. Principal reviewer capped solution quality at 5/7.
**Fix**: When implementing text transformations on languages with complex syntax (JS, TS, Python), prefer AST-based approaches (Babel, TypeScript compiler API, acorn). If regex is the only option (e.g., repo doesn't have an AST dependency), acknowledge the quality ceiling and document known limitations.

### 8. AI Slop in Internal Reasoning and Feedback
**What**: Internal reasoning, feedback documents, and analysis artifacts read like AI-generated text -- formulaic patterns, numbered lists with identical structure, robotic phrasing, excessive hedging.
**Example**: node-macros -- principal reviewer flagged internal reasoning as "AI slop." Said "try writing internal reasoning yourself."
**Fix**: Write all feedback, analysis, and internal docs in your own natural voice. Vary sentence structure. Avoid templated patterns. Reviewers read these documents and judge authenticity.

---

## Patch Generation Mistakes

### 1. UTF-16LE Encoding (Windows)
**What**: PowerShell > redirect produces UTF-16LE with BOM -- null bytes between every ASCII character.
**Fix**: Always generate patches via Python subprocess. Never use PowerShell redirect for patches.

### 2. CRLF Line Endings (Windows)
**What**: Windows git produces CRLF. Platform git apply on Linux rejects CRLF patches.
**Fix**: Use subprocess with p.stdout.replace(b'\r\n', b'\n') or open with newline='\n'.

### 3. Wrong Diff Base
**What**: Using git diff HEAD, git diff, or git diff origin/main instead of diffing against BASE_COMMIT.
**Fix**: Always use git diff $BASE_COMMIT -- <source files>. Save BASE_COMMIT immediately after clone.

### 4. Missing Untracked Files
**What**: New files not showing in git diff because they're untracked.
**Example**: dasel-multi-file -- internal/cli/multifile.go missing from solution.patch for 2 rounds.
**Fix**: Check git status --porcelain for ?? files. git add them explicitly before generating patch.

### 5. Test Files in Solution Patch
**What**: solution.patch includes test files, or test.patch includes source files.
**Fix**: solution.patch = source files ONLY. test.patch = test files + test.sh ONLY. Always specify explicit file lists in the diff command.

---

## Dockerfile Mistakes

### 1. Deno Not Pre-installed
**What**: Assuming Deno is in olympus-base.
**Fix**: Install via curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh -s v2.0.0

### 2. go-junit-report Not on PATH
**What**: go install puts binaries in $GOPATH/bin which isn't on $PATH by default.
**Fix**: Use GOBIN=/usr/local/bin go install to install directly to system PATH. Or add ENV PATH="/root/go/bin:${PATH}".

### 3. Missing Dependency Caching
**What**: Not caching all dependencies during Docker build. Container runs with --network none.
**Fix**: Cache ALL deps: go mod download, deno cache (all source + test imports), npm install, pip install.

### 4. Using ENTRYPOINT Instead of CMD
**What**: Using ENTRYPOINT instead of CMD ["/bin/bash"].
**Fix**: Always use CMD ["/bin/bash"]. Never ENTRYPOINT.

---

## Agent Failure Patterns -- Proven Traps (Across All Challenges)

Design challenges around these patterns. Each has been proven in live evaluations.

| # | Pattern | Failure Rate | Challenge |
|---|---------|-------------|-----------|
| 1 | **Specific examples override general constraint** -- agents implement only the listed examples, skip the broader rule | 100% (14/14) | cliffy-output-format |
| 2 | **Same-command local+global clearing** -- 3 architecturally distinct wrong implementations all fail | 100% (8/8 failing) | cliffy-command-aliases |
| 3 | **Pre-existing class export omission** -- agents export new classes but not the existing base class | 90% (9/10) | cliffy-output-format |
| 4 | **Convenience method calls default constructor** -- method A calls method B which has defaults A shouldn't include | 60% (6/10) | cliffy-output-format |
| 5 | **InFormat mutation ordering** -- agents read o.InFormat AFTER it's been overwritten by crossover logic | 50% (6/12) | dasel-multi-file |
| 6 | **Writer null quoting pipeline bypass** -- isNull guard bypasses quoting/escaping on write side | 45% (5/11) | dasel-csv-options |
| 7 | **Ragged-row dead code** -- len(values) from headers iteration always equals len(headers) | 45% (5/11) | dasel-csv-options |
| 8 | **Cross-file help text update incomplete** -- agents update one file but miss second with same pattern | 36% (4/11) | dasel-csv-options |
| 9 | **FileLoadError inconsistency** -- type defined correctly but not used in ALL error paths | 33% (4/12) | dasel-multi-file |
| 10 | **Cancelled operation push-before-check** -- state pushed to array before cancellation callback checked | 20% (2/10) | cliffy-command-aliases |
| 11 | **Stateful callback counter semantics** -- onProgress(executed, executed) instead of (current, total) | 100% Orion | cliffy-prompt-wizard |
| 12 | **Type injection bypass** -- injected values skip prompt type conversion pipeline | 80% Nova | cliffy-prompt-wizard |
| 13 | **fmt.Errorf no-op passthrough** -- agents intercept function but interceptor does nothing | 36% (4/11) | yaegi-reflect-identity |
| 14 | **Implements for interpreter interfaces** -- agents return false for struct-kinded interface types | 95%+ | yaegi-reflect-identity |
| 15 | **1:1 type registry** -- map[reflect.Type]*itype fails for identical-layout structs | 100% | yaegi-reflect-identity |
| 16 | **Go Options field naming mismatch** -- Delimiter vs Comma vs Separator, bool vs *bool | 70% (7/10) | ferret-csv-codec |
| 17 | **Pattern-followable features (BUSTED)** -- 3+ existing examples of same pattern = 100% pass | 0% difficulty | dasel-reduce-takewhile |

---

## Difficulty Tuning Rules (Proven Across 11+ Submissions)

| # | Rule | Evidence |
|---|------|----------|
| 1 | **Tighten description before adding tests** | dasel-csv-options: 87 vs 108 tests didn't change difficulty |
| 2 | **Cross-feature interaction tests > single-feature tests** | cliffy-middleware: adding 7 cross-feature tests = 100% to 30% pass |
| 3 | **One description hint = catastrophic pass rate increase** | cliffy-middleware: +1 sentence = 17% to 100% pass |
| 4 | **Same-object tests > parent-child tests** | cliffy-command-aliases: 100% of failures from same-object trap |
| 5 | **Novel architecture > pattern-followable** | dasel-reduce: pattern-followable = 100% pass regardless of test count |
| 6 | **Symmetric read/write = natural trap** | dasel-csv-options: 5-6/12 failures from write-side bypass |
| 7 | **Cross-package requirement = message count lever** | dasel-csv-options Diamond: ~60 to 141 median messages |
| 8 | **Ordering traps (push-before-check)** | cliffy-command-aliases: 2/10 Castor failed |
| 9 | **Dead-code tautological checks** | dasel-csv-options: 5/11 Diamond failures |
| 10 | **Pipeline ordering (trim vs null vs strict)** | dasel-csv-options: 3/11 Diamond failures |

---

## Pre-Submission Checklist

Run through ALL of these before every submission. Each item was added because a past challenge failed on it.

```
[ ] Every test assertion traces to a meta.md sentence
[ ] Every meta.md behavior has at least one test
[ ] meta.md is ASCII-only (no em dashes, no curly quotes)
[ ] All exported types/fields/methods named explicitly in meta.md
[ ] Return types stated when different from existing patterns
[ ] Sync vs async explicitly stated for all public methods
[ ] Pre-existing classes named in export lists
[ ] solution.patch: source files ONLY, no whitespace-only changes
[ ] test.patch: test files + test.sh ONLY
[ ] test.sh: executable (mode 100755), position-independent args
[ ] test.sh: produces JUnit XML when --output_path provided
[ ] test.sh: runs ALL existing tests in base mode
[ ] Flakiness verification (MANDATORY Core Dev check): the target repo's existing tests AND the new tests must be non-flaky -- run base+new at least 3-5x and confirm deterministic, identical pass/fail every run; no timing/ordering(map-set-iteration,parallel-race)/unseeded-RNG/network/clock/filesystem-time dependence; a flaky repo baseline or flaky new test = reject.
[ ] Patches: UTF-8 no BOM, LF line endings (verified via Python)
[ ] Net LOC >= 450 design floor (400 = platform auto-block), files touched >= 3
[ ] At least one cross-package integration requirement
[ ] Comments match repo convention (default NONE) in tests + solution
[ ] No dead code, unused exports, or scope creep
[ ] No build tags unique to solution (Go)
[ ] feedback.md + eval-results.md exist and are current
[ ] Dockerfile: uses olympus-base, installs deps, CMD ["/bin/bash"]
```

---

## Agent Failure Patterns: node-minify/node-macros (TypeScript, Lite)

### Regex Literal Omission (2/12 agents)
**What**: Agents build skip-pattern tokenizers for strings/comments/templates but forget regex literal `/…/` branches.
**Why it works**: Agents mentally categorize "things to skip" as strings and comments. Regex literals are a third category that requires explicit attention.
**Detection**: Test `const r = /process.env.DEBUG/;` should remain unchanged.
**Mitigation**: Explicitly state "regex patterns" in the exclusion list in the description. Fair trap.

### Underscore Boundary Failure (3/12 agents)
**What**: `__KEY__` regex matches inside `___KEY___` (3 underscores) because agents don't use negative lookbehind/lookahead.
**Why it works**: Simple regex `__KEY__` is the obvious first approach. Boundary assertions require extra thought.
**Detection**: Test `const x = ___DEBUG___;` should remain unchanged.

### Framework In-Memory Mode (2/12 agents)
**What**: Setting `settings.content` activates node-minify's in-memory mode which skips writing the output file.
**Why it works**: Agents assume setting `.content` is equivalent to providing input via a different channel, not realizing it's a mode switch.
**Detection**: CLI integration tests that read the output file fail with "File does not exist".

### Hand-Written Tokenizer Greedy Consumption (2/12 Orion)
**What**: Orion's `consumeIdentifier` treats `_` as an identifier character, greedily consuming trailing `__` from `__KEY__`.
**Why it works**: Orion prefers parser-based approaches over regex. `_` IS a valid identifier character in JS, so the tokenizer is "correct" but incompatible with the `__KEY__` pattern.
**Detection**: All 5 `__KEY__` replacement tests fail.

---

## Agent Failure Patterns: nmap-formatter/nmap-scan (Go, Olympus)

### Implied Requirement via Flag Existence (9/11 agents, 82%)
**What**: Description says `--ignore-timestamps flag to suppress timestamp-only differences`. Agents implement the flag (CLI binding, metadata boolean) but never implement timestamp comparison. The flag is a no-op.
**Why it works**: Agents read the explicit change-type list (hostname, os_detection, port_state, etc.) as their feature checklist. Timestamps are not listed. The flag's purpose ("suppress X") implies X exists, but agents don't make that inference. The flag creates a false sense of completion -- they feel "done" after wiring the config.
**Detection**: `TestDiffTimestampOnlyDifferenceExit1` -- two scans differing only in timestamps return exit 0 instead of 1.
**Reusability**: Any CLI feature with a flag that "suppresses" or "disables" a behavior. The behavior must exist by default for the flag to make sense. Do NOT list the behavior as an explicit feature.

### Cobra RunE Stderr Contamination (2/11 agents, 18%)
**What**: Agent returns a non-nil error from cobra's `RunE` to signal exit code 1. Cobra prints `Error: <msg>` to stderr by default. Tests use `cmd.CombinedOutput()` which captures both streams, so JSON output is followed by `Error:` and breaks `json.Unmarshal`.
**Why it works**: Agents know RunE should return an error for non-zero exit, but don't trace cobra's internal error-printing behavior. The reference solution uses `os.Exit(1)` directly.
**Detection**: Any test that parses JSON/structured output from CombinedOutput fails with "invalid character 'E' after top-level value".
**Mitigation**: Set `SilenceErrors: true` and `SilenceUsage: true` on the cobra command, or use `os.Exit()` directly.

### Invalid Type Permissive Default (3/11 agents, 27%)
**What**: Agent's output-type switch has a `default: formatText()` case instead of treating unknown types as errors (exit 2).
**Why it works**: Agents assume defensive defaults are good practice. Spec says "exit 2 on errors" but agents don't classify an unsupported format as an error condition.
**Detection**: `TestDiffInvalidTypeExit2` -- `-t yaml` should exit 2, not silently produce text.

### Existing Repo Constant vs Spec Name (2/11 agents, 18%)
**What**: Agent's format switch uses the repo's `MarkdownOutput` constant (value `"md"`) instead of the spec's explicit `markdown`. Tests pass `-t markdown`.
**Why it works**: Agents trust existing code over the spec when both are available. The repo constant is "more authoritative" in the agent's mental model.
**Detection**: All 5 markdown tests fail -- output is text format instead of markdown.

---

## dasel-collection-funcs (Olympus reframe shipped Mars-tier, 41.7% pass) — Confirmed Mistakes

### Strategy Field Discriminator Missed (3/12 agents, 25%)
**What**: Spec defines `*CollectionFuncError` with `Strategy` field. Spec says "The Strategy field is set to the strategy in effect when the error originated, or empty otherwise." Agents always populate Strategy with resolved/default strategy, even on structural pre-check errors that fire BEFORE strategy logic runs.
**Why it works**: The "or empty otherwise" clause is subtle. Agents who resolve the strategy first and pass it into a generic error builder forget to differentiate strategy-bearing errors from non-strategy errors.
**Detection**: `TestStructuredError/Strategy_field_empty_for_non_strategy_errors` — invokes `mergeDeep({"a":1})` on `42`. Asserts `cfErr.Strategy == ""`. Agent's error has `Strategy="overwrite"`.
**Pattern**: When defining a struct field that is conditionally populated, name the empty case explicitly with a discriminator clause. Agents need both populated AND empty cases spelled out.

### Top-Level Shape Mismatch Dispatched to Strategy (3/12 agents, 25%)
**What**: Spec says "Both must be same shape (both maps or both slices). When two maps share a key whose values are both maps, the function recurses; otherwise it applies the conflict strategy." Agents collapse the top-level shape check into the per-leaf "otherwise" branch, so `mergeDeep([1,2,3])` on a map pipeline silently dispatches to "overwrite" and returns the slice instead of erroring.
**Why it works**: The "otherwise" clause is adjacent to the recursion clause. Agents read the whole sentence as a single dispatcher, missing the precondition is structurally separate.
**Detection**: `TestMergeDeep_TypeMismatch/*` — 14–16 tests fail per affected agent with "expected CollectionFuncError, got nil".
**Pattern**: Precondition checks need structural separation from main algorithm. Use "The call FAILS WITH X if not [precondition]" rather than relying on adjacent recursion language.

### Concat Strategy Nested-Slice Handling (1/12 agents, 8%)
**What**: Spec says concat is "slice append, string concat, type-mismatched leaves error". Agent implements concat correctly at top-level slice-vs-slice, but in maps-merge path dispatches non-map matching values to a leaf-only `applyStrategy` that errors on slice-vs-slice. So `mergeDeep({"items": [3,4]}, "concat")` on `{"items": [1,2]}` errors instead of producing `{"items": [1,2,3,4]}`.
**Why it works**: Agent splits merge into "map merge", "slice merge", "leaf strategy". The dispatch from map-merge for non-map values goes directly to leaf-strategy, skipping slice-merge. Agent doesn't recognize slice values nested in maps still need slice-merge.
**Detection**: `TestMergeDeep_StrategyConcat/concat_appends_nested_slice_in_map`.

### Kong Enum Tag Breaks Error-String Contract (1/12 agents, 8%)
**What**: Spec says "Any value other than the four supported strategies errors with `unknown conflict strategy`". Agent declares CLI flag with `kong:"enum:keep,overwrite,concat,error"` tag. Kong validates during `kong.Parse()` and on invalid value calls `os.Exit(1)` with its own error format. Spec-required error string never returned.
**Why it works**: Kong's `enum:` tag is idiomatic Go-CLI pattern. Agents reach for it as the "right way" to validate. They don't notice Kong's validation flow doesn't allow custom error messages.
**Detection**: `TestCLI_DefaultConflictFlag_InvalidValue` errors with "No test result found" because test binary itself exits via Kong's validator.
**Pattern**: When spec mandates a specific error string, validate in code path that returns errors, not in declarative validators.

### Invalid-Strategy Error Not Wrapped (1/12 agents, 8%)
**What**: Spec says "Every error from these two functions wraps a pointer to an exported `CollectionFuncError`". Agent returns `fmt.Errorf("unknown conflict strategy: %s", strategy)`. `errors.As(err, &cfErr)` fails because the error chain has only `*fmt.wrapError`.
**Why it works**: Validation errors feel categorically different from "real" runtime errors. Agents treat input-validation as preliminary and use Go's standard `fmt.Errorf` rather than the structured error type.
**Detection**: `TestStructuredError/mergeDeep_invalid_strategy_wraps`.
**Pattern**: When spec says "every error", ensure spec language has no implicit categorical exception.

### Package Placement of New Error Type (1/12 in early eval, fixed via spec qualifier)
**What**: Spec said "exported `CollectionFuncError` struct" without naming a package. Agent placed type in `model/` package matching dasel's existing error convention (`model.ErrIncompatibleTypes` etc.). Reflection-based test check for `*execution.CollectionFuncError` failed.
**Why it works**: Existing repo convention is the strongest signal. Agents follow it without re-reading spec for package guidance.
**Detection**: All 47 type-assertion checks fail with same message.
**Fix**: Spec must explicitly name the package: "in the `execution` package".
**Pattern**: When a new exported type's package placement matters (because tests use reflection on `*pkg.Type` string), the spec must explicitly name the package.

### Trap Stacking on Pure-Function Shape Hits Ceiling (META-MISTAKE)
**What**: Author stacks 6 Tier 1/2 traps onto pure-function map/slice ops or pure-function optimizer pass. Each round adds another trap, expects pass rate to drop. Rate stays at 100%.
**Why it works**: B-shape / Mars C pure-function additive features have no integration surface. Traps that target receiver style, error wrapping, polymorphic dispatch, etc. all fire mechanically once specced — agents read spec, implement to the letter, pass cleanly. No subtle integration where missed wiring causes silent failure.
**Detection**: 4 successive rounds of trap addition with no pass-rate movement. R10 → 100%. R12 → 100%. R14 → 100%. R16 → 100%.
**Fix**: Reframe shape entirely. Move from pure-function additive (B-shape) to recursive operation with multi-package wiring (Olympus O-Composite-add) OR enum-dispatched strategy with public API split (D-new hybrid). Same trap categories applied to new shape: 33-42% pass.
**Pattern**: Trap-effectiveness depends on integration surface, not trap count. If your problem has no cross-package wiring, no recursive algorithmic body, no conditional struct fields, no enum dispatching — traps will not fire. Reframe shape instead of stacking. **18 rounds wasted on dasel-collection-funcs; 27 rounds wasted on expr-licm-predicates before reshape.**

### Spec-Compression Seesaw at Ceiling (META-MISTAKE — confirmed expr-licm-predicates rounds 25→26→27)
**What**: At trap-stacking ceiling, author oscillates spec word count to "calibrate". Round N drops a hint, empirical crashes to 0%. Round N+1 re-adds as parenthetical, empirical jumps to 90-100%. Round N+2 drops different hint, crashes again.
**Why it works (anti-pattern)**: Spec at ceiling is a binary recall switch, not a difficulty knob. Each hint either fires or doesn't fire as a single bit. There is no "intermediate hint level" because underlying algorithm is mechanical. Adding/removing one sentence flips ALL agents the same direction.
**Detection**: 3 consecutive rounds with binary 0%↔100% empirical flips. Triple binary signature is strongest reshape signal.
**Fix**: STOP spec edits. Reshape per Pattern 17. Time saved on seesaw rounds funds the reshape directly.
**Pattern**: If round 25 = 100%, round 26 = 0%, round 27 = 100%, you are NOT calibrating. You are oscillating at the ceiling. The cost of one more spec edit is now larger than the cost of reshape.

### Parenthetical Operator List Nullifies Trap (CONFIRMED expr-licm-predicates R26→R27)
**What**: Author drops "and/or treated identically to &&/||" rule sentence, then adds back as parenthetical operator list `(\`&&\`, \`||\`, \`and\`, \`or\`)`. Empirical jumps from 0% to ~100% in one edit.
**Why it works (anti-pattern)**: Parenthetical operator lists are scanned by agents BEFORE prose. Listing all four forms in parentheses is functionally equivalent to the explicit rule sentence — no friction added.
**Detection**: Round-over-round empirical 0% → 100% on a parenthetical addition.
**Fix**: If you must hint operator parity, use codebase pointer ("see `parser/operator/operator.go`") or behavioral phrasing ("regardless of which spelling the program uses"). Avoid parenthetical enumeration.
**Pattern**: parentheticals are NOT softer hints than rule sentences. They are equally effective at disabling the trap.

### Public API Split as Integration Trap (CONFIRMED expr-licm-predicates v29 — 25% catch rate)
**What**: Author defines new enum + constants in internal `conf/` package only. Hidden tests import from public root `expr.LICMStrategy`. Agents follow local convention, put types in `conf`, fail at compile time before behavioral tests run.
**Why it works**: Agents under-export to "minimize surface" (production code reflex). They follow the layer where existing related struct lives (`conf.Config`). Public root often has only Option *functions*, not types — agents miss that types belong there too.
**Detection**: 3/12 = 25% FAIL_INTEGRATION_ERROR with build error stating undefined `expr.X` symbol.
**Fix (designer side)**: Define enum in public root file (`expr.go`), mirror `int` field on internal Config struct, ensure tests import from public root.
**Fix (agent side, if you're solving)**: When adding a new public Option function, check if its argument type is also part of the public API. If yes, define type + constants in same package as Option function, NOT in internal config package.

### Iter-Pointer Set Incomplete (CONFIRMED expr-licm-predicates v29 — 17% catch rate)
**What**: Spec enumerates four iter-pointer references (`#`, `#index`, `#count`, `#acc`) as variables to block. Agents handle bare `#` and miss the three named variants.
**Why it works**: Bare `#` is the most common; agents scaffold against it first. Named variants (`#index`, `#count`, `#acc`) appear only in specific builtin contexts (reduce, indexed iteration). Agents skip these checks because their initial test cases don't exercise them.
**Detection**: 2/12 = 17% FAIL_MISSED_REQUIREMENT with hoisted output containing `#index > 5` or `#acc + len(env)`.
**Fix (designer side)**: Enumerate ALL iter-pointer variants explicitly in spec. Test EACH variant separately (`pound_index_dependency_blocks_hoist`, `pound_count_dependency_blocks_hoist`, `pound_acc_dependency_blocks_hoist`).
**Fix (agent side)**: When spec enumerates variables to block, walk PointerNode AST and check ALL `Name` field values against the enumerated set, not just the unnamed/empty case.

### Namespace Expansion of Existing Function (CRITICAL — Immediate Rejection)
**What (CONFIRMED REJECT on dasel-collection-funcs R17d)**: Author adds `mergeDeep` to a repo that already has `FuncMerge` (shallow merge). Reviewer flags as "feature partially present in the repository", invokes Immediate Rejection Rule. GitHub issue #169 also has maintainer comment against merge-namespace expansion: "I'd prefer not to add a shortcut as I don't want to pollute the namespace with uncommon/convoluted shortcuts."
**Why it works (anti-pattern)**: Author Phase 2 PR check searched for literal name (`mergeDeep` absent from master). Did NOT search broader namespace (`merge`) or scan issues for maintainer philosophy. Architecture grep showed `FuncMerge` but author classified it as "different function" (shallow vs deep) rather than "same namespace, would conflict".
**Detection**: Reviewer post-eval rejection citing existing function + maintainer comment.
**Cost**: 18 rounds of authoring + 12-run eval + cannot resubmit same scope.
**Pattern**: At EVERY scope change run all four mandatory checks:

```bash
gh pr list   -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace-prefix>"
gh issue list -R OWNER/REPO --state all --search "<namespace>" --json number,title,comments
```

Search maintainer philosophy markers: "I'd prefer not to", "philosophical", "namespace", "pollute", "by design". A new function name sharing prefix or suffix with existing function is namespace expansion. Treat ANY function described as "deep / smart / advanced / extended <existing>" as immediate-reject candidate until you confirm with broad namespace search + maintainer-issue scan.

---

## dasel-assign-path-creation (Mars Solid, 5/9 = 55.6%, approved May 2026) -- Confirmed Mistakes

A2 shape. Adds opt-in `WithAssignCreatePaths()` execution option. Auto-reviewer FAIL on R0; approved on R1 after spec tightening.

### Mistake 1: Spec uses generic "scalar" without enumerating null

R0 spec: "Type collision through a scalar errors regardless of the option." Tests asserted error when walking through null in slice. Run #4 (Nova→Orion) FAIL_MISSED_REQUIREMENT — agent's reasonable interpretation excluded null. Null is a scalar in dasel's value model but agents default to JS/Python null-as-absent disposition.

**Fix**: add `(including null)` parenthetical. R1 spec: "This applies to any scalar value (including null) and to kind mismatches..."

### Mistake 2: Tests assert one error substring across multiple collision dimensions; spec only names one

R0 spec named only scalar collision. Tests asserted `cannot assign through scalar` for THREE collision dimensions: scalar values, property-name-on-slice mismatch, integer-index-on-map mismatch. Auto-reviewer flagged contradiction.

**Fix**: enumerate every collision dimension that uses the substring in ONE spec sentence. Solution emits same wording for all three.

### Mistake 3: Test patch line count under approved-folder floor on R0 submit

R0 test.patch was 410 lines. Approved dasel test.patch range: 831-2892. Add ~50 tests covering proven PLAYBOOK Pattern 17 trap categories from day one (deep nesting, mixed-path container choice, type collision per scalar kind, slice grow extreme cases, sibling preservation, idempotent reassign). Final R1: 889 lines.

### Mistake 4: Multi-statement non-variable assigns assumed to chain through root

R0 had 12 tests like `a = 1; b = 2`. Empirical CLI confirmation: dasel chains semicolon-separated expressions through the RESULT of each statement, not back to root. So `b = 2` runs against the integer `1` (result of `a = 1`) and errors. Variables (`$x`) ARE supported in multi-statement.

**Fix**: drop all multi-statement non-variable assign tests. Build CLI and test empirically before writing tests for syntactic constructs.

### Mistake 5: Test file references solution-only API without build-tag isolation

Test file imports `execution.WithAssignCreatePaths`. Auto-reviewer pre-flight applies test.patch alone to base; without isolation, base compile fails.

**Fix**: gate test file with `//go:build dasel_assign_path_creation`. Approved precedent: `dasel-frontmatter-format/test.patch` ships `//go:build frontmatter`. test.sh new-mode runs with `-tags=<tag>`; base-mode runs without (file excluded cleanly).

### Mistake 6: Description over-spec via redundant clauses

R0 description had 5 redundant clauses flagged by description-conciseness bot. Pre-trim before R0 submit per AUTO-REVIEWER §10 #1 (target 162-180 words). Apply all 5 conciseness rules in one pass: drop default-expectation sentences, drop redundant trailing clauses, drop adjective phrases that repeat earlier context, drop "exported"/"public" qualifiers, drop example clauses after general rules. R0 235 → R1 161 words.

### Mistake 7: Env-blocker false claim from one of N runs

Run #9 verifier reported `blocker_type: verifier, confidence: medium` because agent's own `go test ./...` was cancelled at 5 minutes during baseline. Five other runs on the SAME submission cleared baseline cleanly in normal runtime.

**Pattern**: env-blocker with `confidence: medium` AND only one of N runs affected = contest. `confidence: high` AND most/all runs affected = real env issue (file separately, do not contest). Contest message format: cite specific agent paths that passed cleanly, mention shared Dockerfile/test.sh/package across runs, note that timeout is reproducible only against this agent's solution patch.

---

## Auto-Review Verdicts ≠ Final Approval (yaegi-repl-doc, 2026-05-02)

**Source**: yaegi-repl-doc shipped APPROVED despite 4 cumulative auto-review FAILs. Final human reviewer overrode advisory FAILs.

**Mistake**: panic-fixing on every auto-review FAIL. Burns 3-5 architecture pivots before locking submission.

**The right move**:
1. LAYER 1 CI failure (test.sh base/new can't pass) = HARD reject. Fix.
2. LAYER 2/3 advisory FAIL = check `Instructions/AUTO-REVIEWER.md § 2 vs § 3`:
   - § 2 Stable criteria → fix
   - § 3 Flaky criteria → contest with approved-precedent citation
3. Final human reviewer respects precedent. Don't pivot architecture chasing reviewer rotation.

**Cost evidence (yaegi-repl-doc)**:
- v1: subpackage placement → auto-review FAIL "subpackage hides tests" → panicked, reverted to package_test
- v2: package_test broke test-patch-only base → fixed via build tag
- v3: build tag → auto-review FAIL "tag is non-standard" → considered reverting again
- v4: would have re-reverted to subpackage but stopped, kept v3, shipped → APPROVED

**Lesson**: pivot ONCE per axis, cite precedent, ship. Don't re-pivot when auto-reviewers contradict each other.

---

## Description Trim Required Cumulatively (yaegi-repl-doc, 2026-05-02)

**Mistake**: shipping initial description at full word budget. Description-quality bot demands 3-5 trim rounds, each removing more.

**Source**: yaegi-repl-doc trim gradient (per AUTO-REVIEWER.md §5):

| Round | Words | What was dropped |
|---|---|---|
| Initial | 215 | — |
| R1 | 198 | "captured at compile time" hint |
| R2 | 179 | early "empty string when no doc is recorded" redundancy |
| R3 | 168 | ":doc " literal → "isn't a :doc command" |
| R4 | 162 | "public" qualifier + shadowing example clause |

**Pre-trim list** (apply BEFORE first submit):
- Drop ALL implementation hints ("captured at compile time", "all entry points must parse", "internally / when source is loaded")
- Drop "public" / "exported" qualifiers (Go capitalization implies)
- Drop redundant clauses (any rule stated twice)
- Drop example clauses after general rules unless they pre-empt a Tier-1 trap
- Drop "and never returns an error" if the method signature's return type already excludes error

Hit final-shipped word count (typically 150-180 for Mars C, 200-280 for Mars Solid B/D shapes) BEFORE first submit. Saves 3 review rounds.

---

## Dockerfile Path Mistakes (yaegi-repl-doc, dasel)

### Wrong: `cp /root/go/bin/<tool> /usr/local/bin/<tool>`

When `ENV GOPATH=/go` is set, `go install` places binaries at `/go/bin/<tool>`, NOT `/root/go/bin/<tool>`. The `cp` fails with "no such file or directory" during docker build.

### Right: `mv "$(go env GOPATH)/bin/<tool>" /usr/local/bin/<tool>`

Portable. Resolves correct GOPATH at build time.

### When to install vs use base-image bin
- olympus-base preinstalls `go-junit-report` per docs, BUT runtime container may strip the PATH
- yaegi-eval-in-package failed with `go-junit-report: not found` (exit 127) because preinstalled binary's PATH wasn't applied at test.sh runtime
- Two safe options: (a) install + `mv` to /usr/local/bin (always-in-PATH), (b) ship `internal/junitconv/main.go` self-contained (no PATH dependency)

---

## Test Prefix Collision With BASE_RUN Regex

**Mistake**: naming new tests with prefix that matches BASE_RUN regex causes them to run in base mode too, breaking the contract.

**Source**: yaegi-repl-doc almost shipped with `^TestEval` prefix that would have collided with existing `TestEval*` baseline tests in BASE_RUN.

**Strategy**:
- Audit BASE_RUN regex BEFORE choosing new test prefix
- Pick prefix that's unambiguously distinct (e.g. `TestEvalResult` not `TestEval` when base regex includes `TestE`)
- OR use subpackage isolation (separate compile target — base regex never sees new tests)

**Safe prefixes for yaegi**:
- `TestDoc*` (not in any BASE_RUN regex variant)
- `TestStackTrace*`, `TestFrame_*` (yaegi-callstack-postmortem)
- `TestComplete*` (yaegi-completion)

**Unsafe prefixes**:
- `TestEval*`, `TestRun*`, `TestSym*` (overlap with TestE / TestRu / TestSy in BASE_RUN)
- Any prefix shorter than 4 chars (high collision risk)

---

## Agent Failure Patterns: yaegi-repl-doc (Go, Mars Solid — 3/14 = 21.4% pass)

| Trap | Hits | Tier | Description |
|---|---|---|---|
| `package main;` → `package main\n` parser-wrap newline reflex | 6/14 = **43%** | **Tier 1** | Agents flip ParseComments AND add newline reflexively. 11-12 baseline pos failures. Reference: lift ParseComments unconditionally, KEEP `package main;` (no newline). |
| GenDecl ValueSpec/TypeSpec walking missed | 3/14 = 21% | Tier 2 | Agents capture FuncDecl.Doc only; miss `*ast.GenDecl` walking var/const/type specs. Need declDoc fall-back. |
| REPL output buffer routing (stderr instead of stdout) | 3/14 = 21% | Tier 2 | Agents write usage to `errs` instead of REPL stdout. REPL meta-commands belong on `out` writer. |
| Self-package qualified lookup miss | 1/14 = 7% | Tier 3 | `Doc("main.Greet")` only matched imported-pkg qualifiers, never current pkg's own importPath. Reference: `["main."+name, name]` candidate keys. |
| `itype.getMethod` recursion no cycle guard | 1/14 = 7% | Tier 3 | Agent extends getMethod to recurse `t.val`/`t.ptr` without cycle detection → stack overflow. Don't touch getMethod; capture receiver names at AST walk. |

Verdict mix: 6 FAIL_REGRESSION (all parser-wrap) + 2 FAIL_MISSED_REQUIREMENT (GenDecl + REPL routing) + 1 FAIL_WRONG_LOGIC (self-qualifier) + 2 FAIL_EARLY_TERMINATION (budget-bound) + 3 PASS.

**Agent path effectiveness**:
- Pure Orion: 1/1 PASS (n=1)
- Nova → Orion: 2/13 PASS = 15.4%

Orion-alone trends better when present. Pattern matches yaegi-callstack-postmortem.
