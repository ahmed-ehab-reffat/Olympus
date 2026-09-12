# feedback — neva-array-bypass-generalization

Olympus, O-Composite-add. Repo nevalang/neva (1076 stars, MIT). Authored 2026-07-27.

## What the problem is

Array-bypass (`[*]`) connects whole array ports slot by slot. On base it only works in one shape: the component's own array inport into a node's array inport, with both port names written out. Every other shape either fails to compile or builds a program that panics or hangs. The task is to make a bypass behave like any other connection.

## Category: feature-request

The platform classifier first read it as a bugfix, because the description led with what breaks today. Reframed as an addition, which is the honest reading: chained bypass, fan-out over bypass and the component-outport direction have never worked in any release, so this is capability that does not exist rather than behavior that regressed.

## Hard-reject clearance (re-verified 2026-07-27, both empirically)

**Already implemented (reason 7): NO.** Built the CLI from `origin/main` at `a0a5c5fe` (2 commits past base, both documentation) and ran all five test programs against it: outport direction panics `fan_out: port 'data' is not array`, self-port pass-through hangs, chained and fan-out are rejected with `Array-bypass requires [*] on both sides`, portless panics `fan_in: array port not found by name: data`. Zero of the feature scope works on current main.

**Maintainer-rejected (reason 2): NO, the opposite.** Issue #980, where emil14 designed the `[*]` syntax, states the intent verbatim: "Also this solves #579 because there's nothing to add support to. All connections are 'normal' and support everything out of the box" and "array-bypass is not connection type in AST, but type of sender and receiver". The syntax shipped in PR #1013; the compiler kept special-casing bypass in the analyzer and irgen, so the promised behavior never arrived, which is why #579 is still open with his comment that bypass "doesn't support chaining and portless". A decline-language scan (prefer not to / by design / won't add / not planned / declined) across every array, port and bypass issue returns empty. The Dec 2025 to Jan 2026 simplification drive (#963 and its sub-tasks) removed unary, binary, ternary, range and switch senders; issue #935 files FanIn/FanOut and ChainConnection under "Easy to Visualize", the keep list.

## Pick gates

| gate | result |
|---|---|
| behavioral f2p gap | base produces observably wrong behavior (panic / hang) in 9 of 10 cases |
| saturation | array-port slot propagation in a dataflow compiler, no reference implementation to recall |
| uniform wrap | no: analyzer gate, irgen expansion and chain flattening are separate edits in separate stages |
| LOC ceiling | 317 human-effective, 522 raw, 6 files across 4 subsystems |
| cold not live | irgen/network.go last logic change pre-2026-04; 3 commits in typesystem+desugarer+irgen in 90 days |
| reproduce on base | yes, with the built CLI, all five shapes |
| dedup | no neva submission in problems/, rejected/, diamond-problems/ or Olympus-Approved/ |
| exclusivity | no open or closed PR touches array-bypass since #1013 (syntax change, merged). Issue #579 documents the portless/chained gap with no solution in comments |
| defined behavior | slot semantics defined by the language book plus maintainer-acknowledged issue #579 |
| no flaky repo | baseline deterministic across runs |
| repo quota | 0 of 6 used |

## Design notes

Traps, in the order they are expected to bite:

1. Analyzer and irgen are two evaluators of the same model. Relaxing only the analyzer gate yields a program that compiles and then panics inside `fan_in`/`fan_out`, naming a stdlib port rather than the missing slot registration.
2. Sender-side and receiver-side slot counts come from opposite usage maps (`portsUsage.in` vs `.out`). One shared helper reading a single map passes the inport direction and silently emits nothing for the outport direction.
3. Fan-out over a bypass cannot reuse the desugarer's FanOut insertion, because slot counts are unknown until IR generation. It needs one synthetic call per slot.
4. Slots must be registered into the child node's `nodesPortsUsage` in the matching direction, or the child's func IO comes up short and the panic surfaces somewhere else.
5. Chains have to be flattened before the connection is analyzed, not after.

Meta discipline: the description states the principle ("every form the network already supports must keep working") and names the two non-obvious capabilities (chaining, fan-out) because tests assert them. It does not name a file, a usage map, a helper, or the per-slot call.

## Decisions taken during authoring

- **Fan-in over bypass dropped.** It was implemented and worked, but a slot-wise merge emits two messages and neva has no order-free way to consume both deterministically without stream machinery. Rather than ship an untestable capability, bypass now requires a single sender, which is exactly the base behavior for that shape. Nothing in meta mentions fan-in.
- **Node-to-node bypass is a compile error, not a resolved case.** A bypass consumes a whole port, so two bypass connections can never share a port, which means slot count can never propagate between them. The propagation/fixpoint code that assumed otherwise was unreachable and was removed rather than shipped as dead code.
- **The "Non-array inport" message improvement was reverted.** No test reaches that branch, and shipping an untested behavior change is a coverage gap.
- **A single-sender error message was added and then removed.** It passed on base, so it added no fail-to-pass value and risked the pre-existing-test-passes reject.
- **`e2e.WithTimeout(20s)` removed.** It flaked under parallel cold-cache load. `test.sh` runs with `-p 1`.
- **`HOME` fallback in test.sh.** As user 1000 in the container, `HOME` resolves to `/` and the neva builder panics on `mkdir /neva`. test.sh falls back to `/tmp` when `HOME` is not writable.

## Requirement coverage matrix (rubric blocker 6)

| Description requirement | Solution | Test |
|---|---|---|
| links each used slot of the sender to the same numbered slot of every receiver | irgen `processArrayBypassSlot`, `arrayBypassSenderAddr`, `arrayBypassReceiverAddr` | all nine behavioral cases |
| a port name may be omitted wherever it may be omitted elsewhere | analyzer `analyzeArrayBypassConnection` resolves both sides and returns the normalized connection | array_bypass_portless_port (relied on by outport, self_ports, chained) |
| either side may be a port of the component or of a node, in any combination | irgen sender/receiver addr split on `in` / `out`, `resolveArrayBypassSlotCounts` reading both usage maps | array_bypass_portless_port (own-in to node-in), array_bypass_outport (node-out to own-out), array_bypass_self_ports (own-in to own-out) |
| may be written as a chain | analyzer `flattenArrayBypassChains` / `expandArrayBypassChain` | array_bypass_chained, array_bypass_nested_levels |
| may fan out to several receivers, each getting its numbered slot | irgen per-slot `fan_out` call; desugarer leaves bypass connections untouched | array_bypass_fan_out |
| slot count is whatever the parent used, per instantiation | irgen `resolveArrayBypassSlotCounts` + `countPortSlots` | array_bypass_single_slot (1), array_bypass_three_slots (3), array_bypass_shared_component (2 and 1 in one program) |
| a bypass between two nodes is a compile error at that connection | analyzer `analyzeArrayBypassAnchoring` | compiler_error_array_bypass_unanchored |
| a node standing in for an injected dependency is bypassed against the component the parent injects | analyzer port resolution + irgen slot registration on the DI'd node's ports | array_bypass_injected_dependency |
| `sync.WaitAll` takes an array inport of signals and emits one signal once every used slot delivered | `internal/runtime/funcs/wait_all.go` + registry + `std/sync/sync.neva` | wait_all_barrier, array_bypass_into_barrier, array_bypass_into_barrier_three |

No blank test column, and every test maps back to a sentence.

## Platform check fixes (round 1)

**Category classifier said bugfix.** Retitled to "Add chaining, fan-out and component-port support to array-bypass" and reframed the opening as an addition. `Category: feature-request` is now explicit in the frontmatter.

**Description checker: request_changes, 5 removals (2 high).** All five applied, 225 words down to 126. Removed: the sentence describing current panics and hangs; the port-name-omission sentence; the enumeration of which side may be a component port; the sentence naming chaining and fan-out; the three-slots-here-one-slot-there example clause. The general rule that carries all of them stays: "a bypass should be an ordinary connection, so every form the network already supports has to work for it too". The two capability names now live in the title instead of an enumerating body sentence, which keeps them fair without restating them as a checklist. This matches HARDENING Rule 7 de-enumeration, and it raises difficulty, since agents have to expand the general rule into instances themselves. **Watch on the first batch:** if the run comes back at 0 percent with agents implementing only the base direction, the fix is to name the root cause and not the fix, per HARDENING 3c-bis, not to restore the enumerations.

**Description checker round 2: request_changes, 3 suggestions (1 high).** All applied. Removed the current-behavior sentence ("Right now one only works between..."), the "Add the rest:" lead-in, and the "a bypass should be an ordinary connection" preface. Body is now 91 words and contains no description of existing behavior at all.

The two checker rounds pull in opposite directions: round 1 said remove the enumeration of forms, round 2 said remove the preface that implied them. What is left is one general rule plus the two hard rules (slot mapping, slot count, unanchored error), with the three added capabilities named in the title. That is the leanest wording that still gives every test a home, but it is thin: `portless_port` and `injected_dependency` now trace to the title plus the general rule rather than to a sentence of their own. **Watch on the first batch:** `description_clear: false` flags, or every agent missing the injected-dependency case, means the trim went one step too far, and the repair is one sentence naming the root cause without naming the fix.

**Category: classifier moved bugfix to enhancement.** Reworded again so the subject is the connection forms being added rather than the bypass mechanism being improved. If it still classifies as enhancement, take enhancement: RULES.md says pick the honest category, and fighting the classifier with reworded openings is fragile. Nothing downstream depends on which of the two it lands on.

**Test-filename collision check: failed.** The randomness was only in the directory suffix, and the checker matches basenames. Fixed both ways: the Go test file is now `e2e_a3d64e_test.go` in every case, and the hash moved to the front of each directory (`e2e/a3d64e_array_bypass_chained/`) so the predicted `e2e/array_bypass*` prefix cannot match either. `neva.yml` keeps its name because the neva toolchain requires it at the module root; per the checker's own guidance the randomized parent directory is the remedy for toolchain-mandated filenames.

**Stray files were in test.patch.** `e2e/io_bytes_roundtrip/bytes_roundtrip.txt` (written by an existing e2e test during a full-suite run) and four modified `e2e/cli/*/neva.yml` had been swept in by a blanket `git add e2e`. Patch generation now stages test.sh plus the ten case directories explicitly and asserts that nothing else is staged.

## Trap-proof (7 mutations, measured 2026-07-27)

Each row is a natural-but-wrong implementation written on top of the reference, built, and run against the 11 new tests. Kill counts are measured, not predicted.

| # | Wrong implementation | Subsystem | Killed by | Symptom the agent sees |
|---|---|---|---|---|
| V1 | irgen keeps the base assumption that a bypass receiver is always a node inport (`/in` path) | irgen | 7 of 11 | wrong values or hang, never an error naming the path |
| V7 | analyzer never resolves omitted port names on a bypass | analyzer | 6 of 11 | `panic: fan_in: array port not found by name: data` |
| V2 | one usage map for both sides (reads `portsUsage.in` only) | irgen | 4 of 11 | outport direction emits nothing, program hangs with no output |
| V3 | child slot usage registered on the wrong side (out written into in) | irgen | 3 of 11 | `panic: fan_out: port 'data' is not array` |
| V5 | chain flattening omitted | analyzer | 2 of 11 | `Array-bypass requires [*] on both sides` |
| V4 | fan-out wired without a per-slot call (every receiver mapped from one sender addr) | irgen | 2 of 11 | only the last receiver gets messages, wrong sum |
| V6 | desugarer bypass pass-through left at one receiver | desugarer | 2 of 11 | fan-out connection is desugared into a FanOut node, mis-wired downstream |

Cross-subsystem interdependence is demonstrated by V1/V7 (analyzer and irgen must move together, and fixing either alone leaves a program that builds and misbehaves) and by V6 (opening the analyzer gate for fan-out without generalizing the desugarer pass-through actively mis-desugars the connection rather than merely leaving it unhandled).

**Correction: there is no baseline-preservation pressure (HARDENING S3), measured 2026-07-27.** I claimed it earlier and it is wrong. Running the V6 mutation against base mode gives 615 cases and 0 failures, and the reason is structural: the repo has **zero** existing e2e programs using `[*]` (grep over `e2e/`, `examples/`, `std/` returns nothing outside this submission) and one parser unit test that merely references the token. No wrong bypass implementation can break an existing test, so every kill in the table above comes from the new tests, never from a regression. S3 is absent from this problem, not partial.

Every symptom is misdirecting: no failure message names slot registration, the usage map, or the missing per-slot call.

## Hardening round 2: the injected-dependency wall (added 2026-07-27)

The first trap set was all wiring, which is the fundsp DERIVABLE-WIRING profile. Probing for a place where the obvious implementation is actively WRONG found one, in a fourth subsystem.

neva matches an injected dependency against its interface structurally, so the component the parent injects may name its ports differently from the interface the network refers to. The normal connection path handles this by re-resolving the port name at IR generation, when the argument is finally known (`processSender` / `processReceiver` both do it). The natural fix for omitted port names on a bypass is to resolve them in the analyzer, where the whole normalization already lives. That fix is correct for every ordinary node and WRONG for an injected one: the analyzer only knows the interface, so it bakes the interface's name and the runtime looks for a port the injected component does not have.

My own reference had this bug until the probe found it. It was fixed in irgen (`injectedArrayPortName`, removed in round 7, see below) and covered by `a3d64e_array_bypass_injected_dependency`, which bypasses through a DI'd component whose ports are named `data`/`res` against an interface naming them `items`/`out`, chained, two slots, both directions.

Trap-proof of the new wall:

| # | Wrong implementation | Killed by | Symptom |
|---|---|---|---|
| V8 | irgen does not re-resolve the injected component's port name | 1 of 12 (the DI case) | program hangs with no output and no error |
| V9 | analyzer bakes the interface name instead of deferring | **0 of 12** | none |

V9 returning zero is the useful half of the result: the analyzer-side deferral I had written was NOT load-bearing, because the irgen resolution repairs it either way. It was removed rather than shipped as dead weight, so one mechanism in one place carries the wall.

## Hardening round 3: the array-port barrier (added 2026-07-27)

Four candidate second-walls were probed. Three fizzled and are recorded so they are not re-probed: `GraphReduction` in the Go backend already handles per-slot chains correctly; `pkg/view` projects port addresses generically and is not wired into the CLI; a slot-count mismatch across a both-own-ports bypass is an ill-formed program whose repair would need a user-facing error channel in IR generation that the feature does not otherwise require.

The fourth landed. `fan_in` selects any-of, so a wrong slot arity is invisible to it: selecting from one channel when two were intended still produces output. A barrier makes arity observable. Mutation V10, which registers every bypass receiver slot as slot 0, **passed all twelve tests** of the previous round and yet hangs a barrier program. That was a real coverage hole, not a hypothetical one.

`sync.WaitAll` (array inport of signals, one signal out, emitted once every used slot has delivered) is now part of the solution, backed by a new runtime func over the existing `ArrayInport.ReceiveAll` primitive. It is maintainer-requested in issue #890, which proposes this exact shape and carries no solution in its comments.

Why it is a second wall rather than more surface:

- It adds the **runtime** as a fourth subsystem to the solution, alongside analyzer, desugarer and IR generation.
- Its arity is the slot count the IR registers, so it is a **second, independent observer of the same invariant** the bypass machinery produces. The first observer is pure wiring, which tolerates arity errors; the barrier does not.
- The failure mode is a hang with no output and no error.

| # | Wrong implementation | Killed before | Killed now |
|---|---|---|---|
| V10 | every bypass receiver slot registered as slot 0 | **0 of 12** | 2 of 15 |

## Auto Review round 1 response (2026-07-30)

**S1 sparse slots (HIGH, solution): REBUTTED with evidence, no code change.** The finding says a parent using only slot 2 would wire slot 0, because expansion iterates a dense `0..count-1` range. That program cannot be written. The analyzer's pre-existing hole check rejects it on both sides, verified by probe: using only `pass[2]` gives `array inport 'pass:data' is used incorrectly: slot 0 is missing`, and reading only `pass[1]` gives the same for `array outport 'pass:res'`. Both rules are covered by the pre-existing `array_inport_holes` and `array_outport_holes` e2e cases. Used slots are therefore always dense, which makes count-based and index-based expansion identical by construction. Carrying indices would add an unreachable branch, which is itself a review flag.

The finding's root cause was mine: a **stale comment** on `processArrayBypassLinks` still claimed links inherit counts from a shared anchored link, left over from the propagation code removed earlier. The same review flagged that inconsistency under Code Quality. Comment corrected to state the density invariant the code actually relies on.

**T3/T4 WaitAll coverage (HIGH, tests): closed, with a measured caveat.** Added `a3d64e_wait_all_distinct_slots`, where slot 0 receives two messages through an explicit fan-in while slot 1 receives one, arriving later on a causal chain. Trap-proof against the exact implementation the review described, one that consumes `Len()` total arrivals rather than one per distinct slot: correct implementation passes 3 of 3 runs, the counting implementation fails 2 of 3. It discriminates but not cleanly, because the two paths differ only in *when* the barrier releases, and the fan-out that delivers the second slot-0 message races the next print. A clean kill would need either a clock or a starved-slot fixture whose flakiness lands on the wrong implementation instead, so neither is acceptable under the flakiness gate. Recorded rather than papered over.

**Code quality notes, both applied.** `WaitAll` now emits `emptyStruct()` like `waitGroup` instead of forwarding the last payload. `injectedArrayPortName` no longer falls back to "the first array port": it resolves only when the injected component has exactly one array port of that direction, and otherwise keeps the written name so a mismatch surfaces loudly instead of misrouting.

## Pre-check round response (2026-07-30)

**Alignment WARNING, WaitAll port names: fixed.** Tests write `wait:sig[0]` while the description only said "an array inport of signals". An agent naming the port `data` fails every barrier case at compile time. This is the A1 pattern (top reviewer flag) and the `CommandError` precedent that cost 9 of 10 agents, so fairness wins over brevity. The description now states the array inport `sig` and the single `sig` outport, matching `pub def WaitAll([sig] any) (sig any)`.

**Conciseness HIGH, "whichever side of it is a port of the component itself": complied in substance, not by deletion.** The Test Fairness panel rated `array_bypass_outport` fair by quoting that exact clause ("the prompt explicitly says the feature must work whichever side is the enclosing component port"). Deleting it would remove the fairness anchor from a test a higher-authority gate already blessed. The bot's real complaint was duplication, so the direction is now folded into the anchoring sentence ("Either side of it may be the component's own array port, and the slot count comes from whatever the parent used for that port") and stated once instead of twice.

**MEDIUM "has no such count": dropped.** Pure redundancy, anchors no test.

**LOW "reported at that connection": kept deliberately.** Test Fairness cited it verbatim to justify the `main/main.neva:8` location assertion. Removing it converts that assertion into a hidden requirement. LOW is explicitly non-blocking.

**GitHub compliance WARNING: no action.** API rate limit at check time, not a repo problem. neva is 1076 stars, MIT, last commit 2026-07-26.

Body is now 109 words. meta.md is not part of either patch, so no re-validation was required.

## Test Fairness round 2 (2026-07-30): PASS, 0 unfair of 18

The panel's citations confirm two calls made against the conciseness bot. It rated `array_bypass_outport` fair by quoting "the self component port may be on either side", which is the restructured clause, and rated the unanchored location assertion fair by quoting "reported at that connection", the LOW-flagged phrase kept deliberately. Taking both suggestions verbatim would have stripped the anchor from two assertions.

One correction to the panel, in our favour to ignore but recorded anyway: it calls `wait_all_distinct_slots` an "excellent semantic test" that catches a counter-only WaitAll. Measured, it catches that mutation 2 runs in 3 (FAIL, FAIL, ok), because the two implementations differ only in release timing and the fan-out delivering the second slot-0 message races the next print. Deterministic for correct implementations, probabilistic against that particular wrong one.

## Auto Review round 2 response (2026-07-31)

**T3/T4 one-shot WaitAll (HIGH): closed with a deterministic kill.** The finding was correct and my earlier barrier tests all completed exactly one synchronization round, so an implementation that emits once and exits passed all 18. Added `a3d64e_wait_all_two_rounds`: both used slots receive two messages (round one from `p1:res`, round two from `p2:res`), every barrier emission is counted by a `sync.WaitGroup` with `count = 2`, and `:stop` is wired to that counter rather than to a print.

The counter is what makes the kill deterministic rather than probabilistic. A one-shot barrier can never produce the second signal, so the round counter never completes and the program deadlocks instead of merely printing less. Measured: one-shot mutation FAIL 3 of 3 (60s timeout), correct re-arming loop pass 3 of 3, and the other 18 tests still pass under the mutation, confirming this test is the only thing closing the hole. Contrast `wait_all_distinct_slots`, which catches its target only 2 runs in 3.

Output is `1\n7\n7\n7\n`: the three sevens are printed by different nodes but carry identical text, so concurrent ordering cannot change the string.

**P4 description repetition (Low): fixed.** The opening had come to state the request twice in consecutive clauses. Now one sentence naming the three forms once, 121 words total.

Solution unchanged at 320 human-effective LOC; this round is tests plus one description sentence.

## Fairness round 3 response (2026-07-31): two FAILs, both conceded

**Test Fairness FAIL, `wait_all_two_rounds` unfair: fixed in the description.** The panel was right. The prompt said `WaitAll` emits "one signal once every used input slot has delivered a message", which does not establish that the barrier re-arms; `WaitGroup`, the nearest repo primitive, documents a single countdown with no reusable rounds. Requiring two emissions was an unstated author choice. The contract now reads "emitting a signal once every used input slot has delivered a message, and again for each further round of messages", which makes the test fair while keeping the Auto Review one-shot gap closed. Task Quality suggested the same fix.

**Task Quality FAIL criterion 04, injected-dependency port names: conceded, test aligned, wall removed.** The DI case wired interface `IPass([items] int) ([out] int)` to implementation `Mirror([data] int) ([res] int)` and expected the compiler to remap. The repo book is explicit at `docs/user/book/components.md`: "Inports are compatible: **full match by name**". The analyzer does not enforce that rule, so my program compiled, but the documented contract says such an implementation does not satisfy the interface at all. My test was leaning on the gap between the docs and the analyzer.

The reviewer offered two fixes. I rejected the one that keeps the wall ("state that injected implementations may use different port names") because writing that into the description asserts semantics the repo's own documentation contradicts, which trades a fairness failure for a philosophy failure. Instead `Mirror` now declares `([items] int) ([out] int)`, matching the interface.

**Consequence, stated plainly: the injected-dependency wall is gone.** With names matching, `injectedArrayPortName` is never reached, proven by neutering it and watching all 19 tests still pass. Dead code cannot ship, so the helper and the `scope` threading that existed only to serve it were removed. That is the wall Auto Review reported all four failing agents missing and the single working agent's only failure, so expect the pass rate to rise. It was an unfair wall, and an unfair wall is not difficulty worth keeping.

Solution drops from 320 to **282 human-effective LOC** (465 raw, 365 platform counter), still comfortably over the 200 floor. The DI test stays, now exercising a bypass through an interface-typed injected node under the documented naming rule.

## Hardening round 4: slot identity (added 2026-08-01)

Removing the DI wall left the set fair but likely too easy, so the replacement wall had to ride machinery that was already there rather than add a new requirement.

The gap: the description says a bypass "links each used slot of its sender to the same numbered slot of every receiver", and almost nothing in the 19 tests could observe it. Every program funnelled slots into `fan_in` or an adder, where slot identity and order both vanish. Measured proof of the hole: V13, which swaps receiver slots 0 and 1, killed only `shared_component` and `single_slot`; V14, the same swap on the sender side, killed 3. A permuting implementation is stated-wrong and was near-invisible.

Two cases close it, both asserting an exact value that only correct numbering can produce:

- `a3d64e_array_bypass_slot_identity`: a bypass from a component's own array inport into a node whose two slots feed `Sub:left` and `Sub:right`. 30 on slot 0, 4 on slot 1, output `26`. A permutation prints `-26`; a collapse to slot 0 starves slot 1 and hangs.
- `a3d64e_array_bypass_slot_identity_outport`: the same discriminator on the own-in to own-out direction, with the node's array outport read per slot into `Sub`.

`Sub` is the whole trick: it is the only cheap non-commutative sink in the repo, so ordering cannot launder a wrong slot map into a right answer. No timing, no clock, no starved-slot fixture, so the flakiness gate is clean.

Trap-proof, measured over 21 tests:

| # | Wrong implementation | Killed before | Killed now |
|---|---|---|---|
| V10 | every bypass receiver slot registered as slot 0 | 2 of 15 | **13 of 21** |
| V13 | receiver slots 0 and 1 swapped | 2 of 21 | **4 of 21**, both new cases among them |
| V14 | sender slots 0 and 1 swapped | 3 of 21 | **5 of 21**, both new cases among them |

Both cases fail on base (21 of 21 new tests fail without the solution) and pass 3 of 3 with it. No description words were added: the assertion is a verbatim restatement of a sentence meta.md already carries, which is the fairest anchor available.

Note this does not restore the difficulty the DI wall provided. It converts a class of wrong implementation from invisible to fatal, which raises the cost of a careless correct-architecture pass, but the root insight of the problem is unchanged. The batch is still the only oracle.

## Honest difficulty assessment (the fundsp risk)

TOO-EASY's DERIVABLE-WIRING law applies to this pick and I do not want it buried:

- **There is an in-repo oracle.** `processArrayBypassConnection` already expands the inport direction per slot. An agent reads it and generalizes.
- **The spec is close to "make X consistent with existing-correct Y"**, a named chokepoint class: the working direction is the answer key for the broken ones.
- **The seven walls may share one root insight.** "Treat a bypass as an ordinary connection: resolve names like any other, expand at IR generation from whichever side is the component's own port, give each receiver its slot." An agent who adopts that architecture up front plausibly gets directions, portless, chains and fan-out together, which is exactly CORRECT-ARCHITECTURE-ABSORBS-ALL-COMPOSITIONS (fundsp: 100/90/100/100 across four batches on that profile).

Mutation proofs certify that the tests discriminate against wrong implementations. They say nothing about whether an agent ever writes one. Only a batch answers that.

**Projected pass rate: 40 to 70 percent, above the 40 percent ceiling.** Mitigating factors that could pull it lower: the two-usage-map asymmetry (V2/V3, the only genuinely non-obvious step), and the fact that every failure surfaces as a panic in an unrelated stdlib func or as a silent hang. I would not spend a platform batch before running the mandatory smoke batch (3 to 5 cold solvers on meta plus repo), which per the Difficulty-Rigor Protocol can only reject, never approve.

## Open risks

- Human-effective LOC is 260 against a 250 floor. Thin. If a reviewer's strip is harsher, the honest fix is another genuine capability, not padding.
- Description is 234 words against a 200 recommendation.
- No agent batch has run. The 10-run Nova-heavy batch is the only difficulty oracle; everything above is a prediction.
