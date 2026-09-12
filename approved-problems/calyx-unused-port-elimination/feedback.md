# feedback — calyx-unused-port-elimination

Tier: Olympus. Shape: O-Composite-add with O-Algorithm-correctness traps.
Repo: calyxir/calyx @ cb25dcb8e5074915887048e2780e2c7bedcba4e8 (MIT, 607 stars, 120 commits/12mo).

## Status

Built and locally validated. No agent batch run yet, so difficulty is UNMEASURED.
The 10-run Nova/Orion batch is the only oracle; every number below is a prediction.

## Pick gates

| Gate | Result |
|---|---|
| 1 behavioral gap | PASS. Base keeps every port of a component nothing reads. Verified on `tests/passes/dead-cell-removal.futil`. |
| 2 saturation | PASS. No upstream reference to memorize. |
| 3 uniform-wrap | PASS. Under-delete fails new tests, over-delete breaks the golden suite. Opposing pressures. |
| 4 LOC ceiling | PASS. 451 human-effective / 613 auto across 7 files in 3 crates. |
| 5 cold | PASS. Issue #1200 open and untouched since 2022-10. No commits in the area. |
| 7 dedup | PASS. No liveness / dead-code / unused-port hit in problems, rejected, or the approved pool. |
| 7b exclusivity | PASS. Canonical org confirmed (no move). PR search over `dead code`, `liveness`, `unused port`, `dead port`, `interprocedural`, all states: no PR implements whole-program port removal. |
| 8 defined behavior | PASS. Issue #1200 is maintainer-authored; rachitnigam confirms in-thread it is a whole-program analysis. |
| 9 flakiness | PASS. 3 runs of each mode, identical every time. |
| 10 quota | PASS. 0 of our submissions on calyx; 607 stars, niche. |

## Validation

| Step | Result |
|---|---|
| base, test.patch only | exit 0, 254 cases, 0 failures |
| new, test.patch only | exit 101, 29 cases, 29 failures, all `Unknown pass: dead-port-elimination` |
| base, both patches | exit 0, 254 cases, 0 failures |
| new, both patches | exit 0, 29 cases, 0 failures |
| reverse-order apply | clean |
| docker build + offline run | both modes green under `--network none` |

Base mode replays the repository's own `[core] passes` golden suite (236 files, matched
byte for byte against the `.expect` files the way `runt.toml` drives them) plus the 18
library unit tests in calyx-utils and calyx-frontend.

## Mutation results (trap-proof / FP hunt)

Every stated rule AND every plausible partial implementation was disabled in turn to
confirm a test discriminates it. Round 1 found one vacuous rule; round 2 found four
implementations that were wrong but still passed.

| Behavior disabled | Fails, round 1 | Fails, final |
|---|---|---|
| control-program reads | 6 | 6 |
| guard operand reads | 2 | 2 |
| fixpoint (single round only) | 2 | 2 |
| interface ports always kept | 1 | 1 |
| `@fixed_signature` | 2 | 2 |
| entrypoint signature preserved | 1 | 1 |
| invoke ref bindings pruned | 2 | 2 |
| ref / `@external` cells are roots | **0 (vacuous)** | rule deleted |
| instance cell ports pruned | **0 (FP hole)** | 1 |
| group assignments pruned | **0 (FP hole)** | 2 |
| static group assignments pruned | **0 (FP hole)** | 1 |
| comb group assignments pruned | **0 (FP hole)** | 1 |
| continuous assignments pruned | 4 | 4 |

Round 1 defect: the ref / `@external` root rule was stated in meta.md, implemented as an
`escapes` helper, and discriminated by nothing. Removed from meta, solution and tests; the
one fully vacuous test was deleted and the surviving ref test retightened.

Round 2 defect (the serious one): every "write to a removed port" in the suite lived in a
*continuous* assignment, so an implementation that pruned only continuous assignments and
skipped groups, static groups and comb groups passed all 29 tests. Instance-cell port
pruning was likewise unobservable through printed IR. Fixed by adding five tests
(group write, static group write, comb group write, a component writing its own removed
output, and an invariant test asserting every instance carries exactly the ports its
component still declares) and one meta clause covering the instance invariant. Suite is
now 34 tests.

## Round 3: external review response

Two automated reviews were run against the artifacts.

**Test review, "brittle string matching".** The literal claim (invoke bindings "may not
occur as a standalone line") is wrong: the printer emits one binding per line and all 34
tests pass across repeated runs. The underlying concern is real though. Non-final bindings
carry a trailing comma, so `body_has` exact-line equality silently depended on a binding
happening to be printed last. A correct solution that rebuilt the binding list in another
order would have failed a positive assertion, and worse, a negative assertion
(`!body_has("b = x")`) would have gone vacuously true. Added a `binding_present` helper
that tolerates the trailing comma and moved the three binding assertions onto it.
Re-ran the mutation matrix afterwards to confirm both still discriminate.

Exact signature assertions were kept as they are. Port order comes from declaration order
and `retain`-style filtering preserves it; weakening these to substring checks would cost
real discrimination for a hazard that requires an implementation to deliberately reorder a
signature.

**Dead code the review did not find.** Chasing the same question further, seven more
branches turned out to be unreachable: `owner_removed` and all three of its call sites, the
invoke *output* binding pruning, and the local dead-ref binding retain. A port bound as an
invoke output is always read, so it can never be dead; a removed `ref` cell can never be
mentioned by a surviving construct, so its ports can never appear either. All removed. The
pass now compiles with zero warnings and every remaining branch is discriminated by a test.
This cost 27 effective LOC (451 -> 424), which is the correct trade: shipping unreachable
code to hold a LOC number is the padding anti-pattern.

**Dockerfile review.** Both warnings were legitimate and cheap. `cargo2junit` is now pinned
to 0.1.15 (the version the verified container runs actually resolved to) and `--locked` was
added to install, fetch and build. Each command was verified locally against the pristine
base commit, including that `target/debug/calyx` is produced. The full container rebuild was
NOT repeated after this change because disk headroom was insufficient; the preceding
container run used the same commands minus the pins.

## Round 4: comprehensiveness review response (two real soundness bugs)

An automated comprehensiveness review (verdict PASS, but "Partially Met" on both scored
axes) found two genuine soundness gaps that the test suite did not cover. Both reproduced
as broken IR, not just suboptimal output.

1. **Invoke output binding to a dead port.** `read_invoke` marked an invoked output live
   whenever an output binding existed, without checking that the caller-side destination
   survived; and `prune_invoke` never removed an output binding. Repro: `invoke p()(r = s.w)`
   where `s.w` is removed printed a binding referencing a nonexistent port AND falsely kept
   `producer.r` alive. Fixed on both sides: the analysis only counts the output binding as a
   read when `write_survives` holds, and the rewrite drops output bindings whose port was
   removed on either the caller or the callee side.
2. **Ref cell used only as an if/while condition.** `read_control` recorded the condition
   port as a read but not the ref cell owning it, so a ref cell touched only by
   `if flag.out` was wrongly deleted from the signature, leaving `flag.out` dangling. Fixed
   by adding `record_ref_cell_of` on the if, while and static-if condition ports.

Both were confirmed by building the exact repros through the CLI before the fix and
re-running them after. Five new mutation checks confirm the three new tests
(`invoke_output_binding_to_a_removed_port_is_dropped`,
`a_ref_cell_used_only_as_an_if_condition_survives`,
`a_ref_cell_used_only_as_a_while_condition_survives`) each discriminate a fix.

**Coverage suggestions (separate report).** Added
`a_toplevel_entrypoint_not_named_main_is_untouched` (entrypoint via `toplevel` attribute,
not the `main` fallback; mutation-verified against a hardcoded-`main` implementation),
`static_invoke_bindings_are_pruned` (static invoke pruning, mutation-verified against the
static-control arm), and extended the dump test to two ref cells so `ref_cells` sorting is
checked with more than one element.

**Not changed: default-flow registration.** The review suggested wiring the pass into the
`all` alias. Deliberately left opt-in (`-p dead-port-elimination`). The meta never claims
default-flow membership, no test depends on it, and forcing a signature-rewriting pass into
the default pipeline would change every component signature, break the golden suite and the
verilog backend, and defeat the `@fixed_signature` opt-out that maintainer issue #1200
requires. The pass is registered alongside the other opt-in passes. Base mode with the
solution stays at 0 failures, confirming default compilation is unchanged.

Suite is now 39 tests, solution 437 human-effective LOC, zero compiler warnings.

## Round 5: too-easy diagnosis + transitive-liveness hardening

First real agent batch: **2/2 Nova PASS_LEGITIMATE** (both wrote ~670-770 LOC full fixpoint
solutions, rated "challenging"). 100% = far too easy. Root cause per HARDENING §0
CHECKLIST-META: the spec enumerated every rule of a single uniform mechanism (mark-read ->
remove -> fixpoint), and both agents transcribed it. Both used **syntactic liveness**:
"a port read anywhere is live." That is the erodable shortcut.

**Repo verdict: NOT a dead end.** calyx is cold, exclusive, sound, multi-crate, unsaturated.
The framing was the problem, not the repo. Fix = make the FIX a discovery orthogonal to the
stated contract (HARDENING §1 CONTRACT-STATED/FIX-HIDDEN).

**Hardening: syntactic liveness -> transitive (dataflow) liveness.** A port is now live only
when its value can actually reach observable state (entrypoint outputs, register/memory
contents, ref/@external cells). A value forwarded only through combinational logic that
dead-ends is not observable, so the feeding port is removed even though it textually appears
as a read. This is a backward reachability fixpoint interleaved with the cross-component
signature fixpoint, and it is exactly what the syntactic approach both agents used gets
wrong (M1 below fails 3 tests).

**Interdependent opposing traps (fixing one breaks the other), FP-verified by mutation:**

| Mutation | Direction | Tests failed |
|---|---|---|
| M1 comb cells always sink (= the agents' syntactic approach) | under-removal | 3 |
| M2 stateful cells not a sink (over-aggressive) | over-removal | 21 |
| M3 control read does not mark comb cell live | over-removal | 1 |
| M4 assignment read does not mark comb cell live | over-removal | 2 |

Under-removal (syntactic) keeps combinationally-dead ports -> fails the "must remove" tests.
Over-removal drops ports whose value does reach a register/output -> produces malformed IR
that the repo's own `well-formed` pass rejects (the "breaks a real check" trap you asked
for; wired into the suite via the `stays_well_formed` helper on split-fanout and
comb-to-stateful). No single simple rule satisfies both directions; the agent must compute
the exact observable-reachability boundary.

**Soundness proof.** The removal is conservative by construction (stateful / ref / external
/ hole / control / invoke = sinks; only combinationally-dead ports are dropped). Verified by
running `dead-port-elimination` then `well-formed` over the whole corpus: **334 programs
clean, 0 malformed.**

**Fairness audit (your meta.md challenge).** First hardened meta enumerated the sink set and
stated the combinational-forwarding rule outright -- a Rule-7 wall-enumeration plus a
spelled-out FIX (GIVEAWAY). Rewrote to state only the CONTRACT (removal must not change
what the program computes: entrypoint values, register/memory contents, ref/@external
state) and withhold the algorithm. Leak audit confirms the meta contains none of
{combinational, transitive, backward, fixpoint, fanout, reachability, dataflow, sink}. This
also fixed a real contradiction: an earlier "observable = entrypoint + ref/external only"
wording made the "port reaching an internal register survives" test contradict the stated
contract (a stricter valid solution would have removed that port and failed). The contract
now names register/memory contents as observable state, matching the conservative
implementation.

Suite: 45 tests. Solution: 466 human-effective LOC, zero compiler warnings. Difficulty is
UNMEASURED at the new hardness -- needs a fresh Nova/Orion batch. If it lands 0%, the fair
easing lever (HARDENING §3c-bis) is to name the ROOT CAUSE ("a read that only feeds
combinational logic nobody observes does not keep a port alive") without naming the
backward-reachability fix.


## Round 6: further fair hardening (edge cases + guard-transitivity trap)

Added 5 edge cases within the same feature, all sound (334-program well-formed sweep still
0 malformed) and all fair consequences of the existing observable-behavior contract (zero
new meta sentences, composition-first):

- guard-only read feeding a DEAD combinational write -> removed (E1); the same guard feeding
  a LIVE register write -> kept (E2). This is the guard x transitivity x dead-destination
  seam. FP: a solver that marks guard ports live unconditionally (M5, a very common default)
  is uniquely caught by E1; the syntactic solver (M1) is now caught by 5 tests.
- a value reaching a `ref` cell THROUGH combinational logic -> kept (distinct sink through
  comb, guards an agent who treats only registers as sinks).
- reconvergent/diamond dataflow (a -> w1,w2 -> adder -> register) -> kept (fixpoint
  convergence, no double-count).
- a `comb component` (no @go/@done interface) loses its dead ports -> exercises the
  interface-less component path.

Suite: 50 tests. Solution unchanged (466 eff LOC). All still sound + deterministic.


## Round 7: second axis (constant-input elimination) - a coupled, different dimension

Added a genuinely different axis in the same feature: an input port that every
instantiation drives with the same constant carries no information, so it is removed and
its reads inside the component are replaced by that constant. This is value-uniformity
(interprocedural), NOT reachability - it removes constant-but-LIVE ports that the liveness
axis keeps. The two stack: an agent needs BOTH criteria (liveness-only keeps constant-live
ports; constant-only keeps unread ports), which is why disabling either axis fails tests.

Why not constant-OUTPUT (the more-coupled option): its cross-component read rewrite could
not be soundness-validated without an agent batch. Constant-INPUT has a LOCAL, sound rewrite
(inline the constant into the component's own body via the repo's `Rewriter`), so it is
fully verifiable here. Soundness re-proven: pass then well-formed over the corpus = 334
clean / 0 malformed (with both axes).

Edge cases (all fair consequences of the observable-behavior contract):
- uniform constant input (feeding a LIVE register) removed + inlined; a co-port that varies
  removed as dead; the output kept (one program, both axes + liveness).
- differing constants across instances -> kept.
- one non-constant instance -> kept.
- guarded constant write -> kept (a guarded drive is not an unconditional constant; this is
  the discovery, NOT stated in the meta).
- constant input read in a guard -> inlined into the guard.
- structurally-driven uniform constant (not via invoke) -> removed + inlined.

FP mutation (every rule discriminated, no vacuous test):
- disable constant axis (liveness-only, the original agents) -> 3 removal tests fail.
- ignore guard-disqualify -> only the guarded-constant keep-test fails.
- ignore cross-instance disagreement -> only the differing-constants keep-test fails.

Meta: added ONE contract sentence (constant-uniform input removed, readers use the constant,
disqualified by disagreement/non-constant/missing). Withheld the how: the structural+invoke
per-instance scan, the guard-disqualify subtlety, the inline rewrite, and the fixpoint
interaction. Leak audit clean (no combinational/transitive/fixpoint/inline/rewriter/guard
terms).

Suite: 56 tests. Solution: 609 human-effective LOC. All sound + deterministic. Difficulty at
this hardness still UNMEASURED - needs a fresh batch.


## Round 8: pre-check review response (Test Fairness PASS 0/56, Solution Quality PASS 2/3)

Both automated pre-checks passed. Test Fairness: 0 unfair of 56. Solution Quality: PASS but
2/3 on both scored axes, flagging two real defects in the constant-input sub-analysis. Both
fixed (these are fairness/polish checks, NOT the difficulty batch):

1. `visit_invokes` doc-comment claimed static-invoke support but the `Static` arm was empty
   (comment/impl mismatch + incompleteness). Implemented real static-invoke handling
   (`visit_static_invokes` over `StaticControl`), so a uniformly-constant input supplied
   through `static invoke` is now eliminated. Comment now matches.
2. `value_driven_to` hard-coded `writes == 1`, wrongly keeping an instance driven with the
   SAME constant at multiple sites. Relaxed to "all drivers must agree on one constant"
   (still disqualifies on disagreement, non-constant, guarded, read, or undriven).

Coverage suggestions from the fairness reviewer:
- @external-through-comb: skipped. `@external` is only legal in the entrypoint (whose ports
  are always kept), so the meaningful non-entrypoint case reduces to the ref-cell-through-comb
  test already present.
- missing-driver ("or nothing, the port stays"): ADDED. An input left undriven at one
  instance is kept (that instance reads 0, not the constant). Gap the reviewer correctly
  flagged (meta clause existed, no test).

New tests (3): static-invoke uniform constant removed; same-instance two-site constant
removed; undriven-at-one-instance kept. FP mutation confirms each:
- drop static-invoke handling -> only the static-const test fails.
- re-impose single-write -> only the two-site test fails.
- skip (not disqualify) undriven instances -> the undriven AND non-constant tests fail.

Redundancy note from the fairness reviewer (normal/static/comb-group placement variants):
kept deliberately - the mutation matrix shows each discriminates a distinct pruning branch
(skip group / static-group / comb-group each fails a different single test).

Suite: 59 tests. Solution: 632 human-effective LOC, zero warnings. Soundness re-proven:
pass then well-formed over the corpus = 334 clean / 0 malformed. All deterministic.


## Round 9: DEEPENED with a third, coupled axis - constant-output propagation

Per HARDENING (composition depth + cross-subsystem coupling beats trap count), added the
one axis that genuinely COUPLES rather than sitting orthogonal: constant-OUTPUT propagation.
An output a component always drives with one constant is given to every reader directly,
which makes the output unread, so the liveness axis then removes it. The three analyses
(transitive liveness, constant-input, constant-output) now run in a JOINT FIXPOINT: a
propagated constant output can make a reader's own output constant, cascading across
component levels (verified 2-level: dst.in = 32'd9 propagated through leaf -> mid -> main,
both outputs removed).

This is S3/S4 (feeds a shared chokepoint) and real interprocedural constant propagation - a
serious compiler analysis. Bounded for soundness: only outputs driven by a single
unconditional continuous constant (no group/other writer) whose instance-reads are all plain
assignment sources (no guards/control) are propagated; everything else is kept conservatively.

Soundness re-proven with all three axes + fixpoint: pass then well-formed over the corpus =
334 clean / 0 malformed. Value-correctness spot-checked (the propagated constant matches the
driver through multi-level cascades).

New tests (5): constant output propagated+removed; 2-level cascade; register-driven output
kept; group-driven (conditional) constant output kept; constant output read in a guard kept.
FP mutation:
- disable the constant-output axis -> the two removal tests fail.
- bypass the plain-source eligibility -> only the guard-read keep-test fails.
The keep-tests guard soundness (over-propagation would change behavior or dangle a port).

A real bug caught during implementation: `iter_assignments` includes continuous assignments,
so the first "other writer" check counted the single continuous constant driver itself as
disqualifying. Fixed to check only group / comb-group / static-group writes.

Meta: generalized the constant sentence to cover both input and output ("a non-interface
port that always carries the same constant is removed; for an input every instantiation
drives it, for an output the component drives it every cycle"). WHAT only - withheld the
continuous-vs-group detection, plain-source eligibility, cross-component inline, and the
joint fixpoint. The group-driven-constant-kept case traces to "every cycle" (a group drive
is not every cycle) as a fair discovery, not a stated rule.

Suite: 64 tests. Solution: 777 human-effective LOC, zero warnings. Three stacked axes, one
of them genuinely coupled through a joint fixpoint. Difficulty still UNMEASURED - the batch
is the only oracle; ease via root-cause disclosure (HARDENING 3c-bis) if 0%.


## Round 10: review response (description<->test ERROR + description-quality + coverage)

Three reviews. Two blocking, both fixed.

1. ERROR (real, mine): the meta said a constant output's "readers use that constant
   directly" (all readers), but a test kept the output when read in a guard. Genuine
   contradiction. Fixed by making the behavior match the meta: removed the artificial
   plain-source restriction so constant outputs now propagate to EVERY reader (assignment
   sources, guards, and control conditions) via the repo Rewriter. Verified sound: propagating
   into guards and if/while conditions stays well formed (334-program sweep still 0 malformed).
   The guard test now asserts propagation (`dst.in = 1'd1 ? 32'd5`), not survival.
2. Description-quality (request_changes): removed three obvious-default / rhetorical
   sentences the reviewer flagged: the instance-consistency + well-formedness sentence (both
   obvious consequences, codebase-verifiable), the "removals cascade" clause (implied
   fixpoint), and the "Some signatures survive regardless of use" lead-in. The corresponding
   tests (instance consistency, cascade, stays_well_formed) remain as fair obvious
   consequences. Meta dropped 313 -> 275 words.
3. Coverage WARNING (non-blocking): a discriminating "@external keeps a removable port" test
   is impossible in Calyx (@external is entrypoint-only; entrypoint ports are always kept).
   Added the moral equivalent: a non-entrypoint input reaching a genuine `@external` memory
   through a `ref` cell survives. Ref cells are how non-entrypoint code touches external state.

Removed now-dead code (`reads_are_plain_sources`, `guard_reads`) with the restriction; zero
warnings. Suite: 65 tests. Solution: 748 human-effective LOC. Soundness 334/0. FP re-confirmed
(disabling the constant-output axis fails 3 tests including the guard-propagation test).


## Round 11: Verifier Completeness Audit response (3 false-positive holes closed)

The audit found 3 broken-but-plausible implementations that passed all 65 tests while
violating requirements. Verified against the reference FIRST: the reference handles all
three correctly, so these are missing-test (FP) holes, not solution bugs. Added the 3
proposed tests; no solution change. Each was FP-confirmed against the exact broken impl:

1. Ref cell mentioned only as an assignment source (Crash/high). A mention scanner that
   records refs used as destinations/guards/conditions/bindings but not as an assignment
   SOURCE drops the ref + binding while an assignment still points at it -> dangling weak
   reference panic. Reference records refs on the source too (`record_ref_cell_of` on
   `assign.src`). Mutation removing that call fails ONLY the new test.
2. Direct write into an ordinary local memory (Wrong/high). A sink classifier that hard-codes
   `std_reg` as the only stateful sink removes an input that only writes a local `comb_mem`.
   Reference treats every non-comb, non-ref, non-external cell as a sink, so the memory write
   is pinned. The stateful-sink fallback is load-bearing (removing it fails 38 tests).
3. Conflicting constants at two invokes of the SAME instance (Wrong/high). A per-instance
   aggregator that keeps the first constant and ignores later ones wrongly eliminates a port
   driven p=5 then p=6. Reference collects every drive and disqualifies on any disagreement.
   Mutation (first-value-wins) fails ONLY the new test.

Suite: 68 tests. Solution unchanged (748 eff LOC, 0 warnings). Full cycle green; soundness
unaffected (reference was already correct on all three).


## Round 12: second Verifier Completeness Audit (6 gaps, investigated one by one)

Did not blindly accept. Ran every probe against the reference and checked validity.

Five were genuine missing-test holes (reference already correct, verified by running each
probe + well-formed):
1. constant INPUT used only as an if/while condition -> flag removed, `if flag` rewritten to
   `if 1'd1`. Reference correct because inlining goes through the repo Rewriter, which
   rewrites control conditions.
2. constant OUTPUT used only as an if/while condition -> same, via the Rewriter.
3. a GUARDED continuous constant output (`r = flag.out ? 32'd7`) is NOT constant every cycle
   -> reference keeps it (guard is not true -> value None). FP: ignoring the guard fails only
   this test.
4. attributed interface ports with non-standard names (`@go launch`, `@done finish`, ...) ->
   kept. `is_interface_port` checks attributes, not names. FP: a name-based check fails only
   this test.
6. an unused `ref` cell bound on a STATIC invoke -> pruned from signature and static binding.
   FP: leaving static `ref_cells` unpruned fails only this test.

One gap (5) was REJECTED as an invalid probe. It writes `@external` on a cell inside a
non-entrypoint component; `@external` is entrypoint-only in Calyx and `well-formed` rejects
it ("Malformed Str") for both `std_wire` and memory. So the proposed test exercises a
semantically-invalid program. External-state observability for a REMOVABLE port is only
reachable through a `ref` cell (already tested by
`a_port_reaching_an_external_memory_through_a_ref_survives`), because a direct `@external`
port lives in the entrypoint and is kept regardless. Confirmed the `@external` attribute
check in `write_survives` is unreachable for well-formed programs (removing it leaves all 68
tests and the 334-program soundness sweep clean); kept it as a one-line defensive mirror of
the meta's stated sink list rather than adding a malformed-program test.

Added 5 tests (73 total). Solution unchanged (748 eff LOC, 0 warnings). Full cycle green.


## Round 13: self-audit (mutation sweep) before waiting on another external audit

Ran my own completeness audit: a 3-batch mutation sweep over every meaningful branch of
both source files, treating any mutation that leaves all tests green as a hole. Findings:

REAL holes (reference correct, no test pinned them) - closed:
- caller-side invoke-output retain: an invoke output binding that writes to a caller
  signature port which then gets removed was left dangling by a broken impl, and well-formed
  does NOT catch it (only the printed IR shows `o = y` on a removed port). Added
  `invoke_output_binding_to_a_removed_caller_port_is_dropped`; FP-confirmed (removing the
  retain fails only it).
- input feeding only a dead callee input: added
  `a_caller_input_feeding_only_a_dead_callee_input_is_removed` as new whole-program cascade
  coverage. Note: the specific read_invoke gate is redundant with the outer fixpoint (removing
  it still converges to the same result in one extra round), so this test pins the behavior,
  not that single line.

Survivors that are NOT holes (defensive/unreachable, proven by construction):
- value_driven_to `read` disqualifier: reading an instance INPUT port is rejected by
  well-formed, so no valid program discriminates it. Defensive.
- constant-output `cont_writes == 1`: two continuous drivers of one port is rejected by
  well-formed. Defensive against a malformed double-drive.
- write_survives `is_hole()` short-circuit: redundant with the `else => true` fallback (a
  hole's parent is always a Group), so behaviorally identical. Left as self-documentation.

Fairness trace: mapped all 75 tests to the meta. Every test traces to a stated contract
sentence or a fair whole-program / obvious consequence. Codebase-inferable count stays low
(entrypoint = `toplevel` attribute; printer signature order data-then-interface) - both are
repo-standard and were rated fair by the two prior external audits. No test pins a
solution-internal detail (helpers, types, algorithm steps); all assertions are on printed IR
and the JSON report. Meta remains WHAT-not-HOW (leak audit clean).

Suite: 75 tests. Solution unchanged (748 eff LOC, 0 warnings). Full cycle green.


## Round 14: Test Fairness FAIL response (4 over-pinned tests) + 1 coverage add

Two Test Fairness runs conflicted (LLM-judged, nondeterministic): one PASS, one FAIL (4 of 75
unfair). Treated the FAIL as authoritative - it found a real defect the PASS missed.

The 4 flagged tests pinned the UNSIMPLIFIED printer form of a constant substitution
(`reg0.in = 1'd1 ? 32'd1;`, `dst.in = 1'd1 ? 32'd5;`, `if 1'd1`). The prompt only requires the
constant be propagated (semantic), not that the always-true guard / constant `if` survive - a
correct solver could fold `1'd1 ? x` -> `x` and `if 1'd1 { g }` -> `g`. Pinning the unfolded
form fails a correct-but-simplifying solution = unfair (and it is a WHAT-not-HOW violation at
the test level). This is the participle "unfair biter" pattern: fake difficulty that the
fairness gate removes.

Fix (form-agnostic, discrimination preserved):
- guard cases: assert the value assignment in EITHER form -
  `body_has("reg0.in = 1'd1 ? 32'd1;") || body_has("reg0.in = 32'd1;")`. A dangling `p ? 32'd1`
  (forgot to inline the guard) matches neither -> still caught.
- control-condition cases: assert `!out.contains("flag")` (the port is fully substituted, so a
  dangling `if flag` / `if l.flag` fails) AND `out.contains("g;")` (the group still runs).
  Accepts both `if 1'd1 { g; }` and the folded `g;`.

Added the one worthwhile coverage suggestion: `fixed_signature_component_keeps_a_constant_input`
- a `@fixed_signature` component does NOT constant-eliminate a uniformly-constant input.
FP-confirmed (removing the fixed-skip in `constant_input_ports` fails only it). Skipped the
other two suggestions: direct-`@external`-sink is malformed in Calyx (entrypoint-only; the ref
path is tested), interface-ports-in-report is low value.

Suite: 76 tests. Solution unchanged (748 eff LOC, 0 warnings). Full cycle green, deterministic.


## Round 15: 2nd Test Fairness FAIL (fixed_signature interaction over-pins) + proactive scan

A later Test Fairness run flagged 2 tests (both `@fixed_signature`). These are MORE clearly
unfair than round 14's form-pins: they pin an UNSTATED INTERACTION between two rules.
- `fixed_signature_component_keeps_every_port` asserted the invoke binding `b = src.out`
  survives. The prompt keeps the SIGNATURE (so `b` the port stays - fair), but never says a
  binding driving a dead-but-kept port must remain; Calyx allows undriven inputs, so an impl
  could drop it. Dropped the binding assertion; kept the signature assertions.
- `fixed_signature_component_keeps_a_constant_input` (which I had ADDED from round-14's own
  coverage suggestion - the irony that coverage suggestions probing rule-interactions breed
  unfairness) asserted the body stays `reg0.in = p;` (constant not inlined). An impl could
  keep `p` in the signature AND inline the constant internally. Dropped the body assertion;
  kept `signature contains "p: 32"` + well-formed.

Both still discriminate (FP-confirmed): removing the fixed-sig liveness protection fails
`keeps_every_port`; removing the fixed-skip in `constant_input_ports` fails
`keeps_a_constant_input`. No hardness stripped - the core transitive-liveness suite is
untouched.

Proactive scan of ALL positive survival assertions against a single principle: asserting a
binding/assignment SURVIVES is fair only when the thing is LOAD-BEARING (the port is live, so
dropping it changes computation) or REQUIRED by well-formed. Every other survival assertion
clears the bar (`a = src.out` etc. drive live ports; ref survivals are well-formed-required;
inlined-constant plain assignments have no simplification freedom). The 2 fixed_signature
tests were the only place a KEPT-but-DEAD port gave the impl freedom - which is exactly why
they were the outliers. No other over-pins found.

Suite: 76 tests. Solution unchanged (748 eff LOC, 0 warnings). Full cycle green, deterministic.


## Round 16: batch was 0/11 (unsolvable) -> eased to ~27% (empirically verified)

Second real batch (8 Nova + 3 Orion) came back 0/11 = unsolvable = reject. Root-cause per
failed-test clustering:
- 4 agents broadly failed (60-76 of 76) - never got the architecture working (early
  termination / wrong approach). Uninformative.
- 7 agents NEARLY solved it, all blocked by 1-2 multi-level CASCADE tests. Global blindspot =
  transitive cascade across component levels (agents nail single-level + the liveness fixpoint
  but miss propagating deadness/constants across a chain).

Two tests dominated:
- `ref_cell_unused_by_the_callee_is_dropped_along_the_whole_chain` - 11/11 (even Orion_1, who
  passed all 75 others, failed only this). This test is UNFAIR: the meta says "a ref cell its
  own component never mentions is dropped", but in the chain the intermediate DOES mention it
  (forwards it via `invoke i[mem = mem]`). By the stated syntactic rule the intermediate keeps
  it; the test demands transitive removal (forwarding is dead once the callee drops it) that
  the meta never states. Agents correctly implement the stated rule and fail. REMOVED (fixes
  the unfairness AND is the 0% gate). Single-level ref removal + forwarding-survival stay
  covered by two other tests.
- `a_constant_output_cascades_across_two_levels` - 8/11. Fair (stated rule at the outer
  fixpoint) but the second universal wall. REMOVED as the ease lever. Single-level
  constant-output stays tested, so the axis is still required.

Projected pass rate EMPIRICALLY VERIFIED by replaying the actual agent solutions against the
reduced 74-test suite: Orion_1, Nova_1, Nova_4 -> 0 failures (PASS); Nova_6 -> still 1
(guarded-constant); rest still fail. = 3/11 ~ 27%, safely <=40% with margin above 0 (removing
only the unfair ref-chain would have given a risky 1/11 ~ 9% that could fluke to 0). Core
transitive-liveness wall untouched - still fully defeats 4 agents and blocks the rest.

Suite: 74 tests. Solution unchanged (748 eff LOC). Base 254/0 both modes; new 74-fail->74-pass;
2x flakiness identical. Meta unchanged (removing the unfair ref-chain test restores consistency
with the stated "never mentions" rule).


## Round 17: batch-3 still 0/9 -> removed 2 more peripheral blockers -> 3/9 (~33%) verified

Batch 3 (8 Nova + 1 Orion) on the 74-test suite: 0/9. The universal blocker had SHIFTED to
`invoke_output_binding_to_a_removed_caller_port_is_dropped` (8/9) - a different test than
batch 2. Root structure: the problem stacks several INDEPENDENT hard integration points
(transitive-liveness cluster + caller-side invoke-output + report sorting); different agents
miss different ones, so no agent clears all -> 0% with high variance. Removing one blocker
just promotes the next (whack-a-mole).

Near-passers were each ONE test from passing, but on different tests:
- Nova_3: only invoke-output-caller
- Nova_4, Nova_7: invoke-output-caller + report_lists_..._sorted
- Nova_1: invoke-output-caller + guarded-constant

Removed BOTH `invoke_output_binding_to_a_removed_caller_port_is_dropped` and
`report_lists_removals_sorted_by_component_and_name` (both fair/prompt-stated but PERIPHERAL
integration points, not the core transitive-liveness wall). report_omits + report_is_empty
stay, so the dump feature is still tested (minus multi-component sorting). Removing only
invoke-output-caller would have given a risky 1/9 (~11%, near the 0% reject line); removing
both gives margin.

EMPIRICALLY VERIFIED by replaying all 9 batch-3 solutions against the final 72-test
deliverable: Nova_3, Nova_4, Nova_7 -> PASS = 3/9 ~ 33%. Core transitive-liveness cluster
untouched (still fails Orion + 4 others).

Suite: 72 tests. Solution unchanged (748 eff LOC). Base 254/0 both modes; new 72-fail->72-pass;
2x flakiness identical. Meta unchanged.


## Round 18: Olympus-only decision - restore all walls + subtle hints (no Diamond tier exists)

Corrected: there is no Diamond tier; Olympus only. Restored the full wall set (invoke-caller,
cascade, ref-chain, report-sorted, keep-rules) = 77 tests, and added SUBTLE hints in meta.md
for the walls that need them, so 1-2 strong agents can solve while the DOING stays hard:
- general fixed-point / whole-program principle (helps cascade + ref-chain transitivity)
- "at either end of an `invoke` binding" (nudge for the caller-side invoke-output wall, the
  89%-miss dominant blocker)
- "forwarding a `ref` cell keeps it only while the callee needs it" (makes ref-chain FAIR -
  the meta's syntactic "never mentions" rule otherwise contradicts it - and hints transitivity)
report-sorted kept (fair, prompt-stated, the moderate ~44%-miss wall).

Calibration data that drove this (pooled replay of batches 2+3+4 = 22 solutions, no-hint
lower bound):
- 72 core (walls stripped): 6/12 ~ 50% (too easy) - this is why agent-runs4 was 3/3
- 72 + report-sorted (moderate wall): 7/22 ~ 32%
- 72 + report + cascade (strong wall): 1/22 ~ 5%
- 77 all walls: 0/22 (binary killers crater it)
The walls are binary; there is no smooth Olympus middle, so difficulty is added via the
moderate report wall + subtle hints that let strong agents clear the binary walls.

PROJECTION: no-hint replay lower bound = 0/22. The 3 hints are the lever to lift the
invoke/ref/cascade-blocked near-passers (who solved the core) to ~1-3/10. The hint effect is
NOT locally verifiable (new agents behave differently with the meta hints), so the real rate
needs a batch; expected band ~10-35%, with genuine risk at both tails (0 if hints too subtle,
>40% if they one-shot). Core transitive-liveness cluster is the rate-holding wall.

Suite: 77 tests. Solution unchanged (748 eff LOC, 0 warnings). Base 254/0 both modes; new
77-fail->77-pass; 2x flakiness identical. Meta 334 words, ASCII.


## Round 19: FINAL Olympus config - agent-runs-2 walls minus unfair ref-chain + ONE general hint

Decision: keep the full hard wall set (invoke-caller, cascade, report-sorted, keep-rules + core),
DROP the unfair ref-chain (its fairness needed an enumerated transitive-ref hint = crush risk),
and use exactly ONE hint - a GENERAL fixed-point principle ("the pass reaches a fixed point over
the whole program"). Removed the two ENUMERATED hints (either-end-invoke, transitive-ref) because
per GATE-EROSION enumerated-wall hints get transcribed -> one-shot -> too easy.

Why this over "config B" (72 + report only): same ~27% ballpark but keeps invoke + cascade as
real walls (richer difficulty), fair, no enumerated hints.

Empirical (replay batches 2+3+4 vs this 76-config, no-hint lower bound): 1/22 (~5%).
- agent-runs2 Orion_1: PASS (ref-chain was its only block).
- agent-runs2 Nova_1, Nova_4: fail ONLY cascade - one test away.
The one general fixed-point hint is the lever to lift cascade-blocked near-passers like Nova_1/4
in a NEW batch (frozen replay solutions can't benefit). Projected with hint: ~27% (Orion-tier +
cascade near-passers). Subtle-bump regime, not crush: one general hint, no enumerated hints, no
unfair test. Hint effect needs a batch to confirm; honest band ~5-27%.

Suite: 76 tests. Solution unchanged (748 eff LOC, 0 warnings). Base 254/0 both modes; new
76-fail->76-pass; flakiness deterministic. Meta 311 words, ASCII.

## Known risks

- **Non-root run.** `docker run --user 1000:1000` fails with `Permission denied` because
  `/app/target` and `/root/.cargo` are root-owned. DOCKER.md forbids the legacy
  `chmod -R a+rX /root` on `olympus-base-rust` (it broke nickel-enum-widening at 0/10),
  and states the plain no-chmod pattern builds and solves fine because the platform
  remaps the solving user. Shipping the no-chmod pattern that matches approved
  nickel-1336. If a permission blocker shows up in the batch, the fix is to vendor
  dependencies under /app rather than to chmod /root.
- **Cargo.lock in test.patch.** The tests need `serde_json` as a dev-dependency of the
  root package to parse the report. Both Cargo.toml and Cargo.lock are in test.patch so
  the offline resolve does not have to rewrite the lock at test time.
- **Difficulty unmeasured.** Predicted 10-20%. The read-collection is partly served by
  the existing `ReadWriteSet` machinery, which makes the guard and control axes cheaper
  than they look; the load-bearing wall is expected to be the mutual fixpoint between
  port liveness and assignment retention, plus pruning the instance cells and the
  signature consistently.

## If the batch reads too easy (>40%)

Do not add tests. Deepen composition: the untested interaction is a port that is live
only through a chain that also passes through a removed `ref` binding. Build the
differential harness from the passing agents' patches first.

## If the batch reads 0%

Most likely cause would be the whole-program hook. The meta says the pass reasons about
the whole program but never names `Visitor::start_context`. If every agent dies writing a
per-component pass, name the root cause ("the analysis needs every component at once"),
never the fix.

## Round 20 (2026-07-26) - group-scoped constant-input soundness fix + 2 coverage tests

Solution Quality review flagged constant-input inference as too aggressive on
group-scoped writers. Confirmed the bug with a probe: an input driven `= 32'd5` only
inside a group (never continuously / never via an invoke binding) was wrongly treated as
an unconditional constant and removed, so the group's write vanished. A group write is
live only while the group runs, so it does not prove the port always carries that value.

Fix (mirrors the existing `constant_output_ports` behavior): `value_driven_to` now counts
only continuous assignments and invoke bindings as unconditional writes. A
group / comb-group / static-group write sets a `conditional_write` flag that disqualifies
the port; only reads and unconditional constant writes decide the result. Added free
generic `writes_port<T>` / `reads_port<T>` helpers (closures cannot be generic over
`Assignment<T>`).

Tests 76 -> 78:
- `an_input_driven_by_a_constant_only_inside_a_group_survives` - pins the fix (FP-checked:
  re-pushing group writes as constants fails only this test).
- `report_lists_removed_ref_cells_sorted` - a component losing both a port and >=2 ref
  cells (declared out of order) dumps sorted `ref_cells` alongside `ports` (FP-checked:
  omitting ref_cells fails only this test; un-sorting fails this + the existing sort test).
  Closes a report-coverage gap flagged by two reviews.

Skipped the second Test Fairness coverage suggestion (constant propagation through invoke
output bindings): the impl is deliberately conservative there (an invoke output read
disqualifies), so a test asserting propagation would be unfair to this impl and a test
asserting survival would be unfair to a more-complete one. Neither is a stated contract.

State: 78 tests, 0 build warnings, solution.patch 1043 counter-1 LOC (~680 counter-2,
well over the 450 floor), patches apply clean to pristine BASE, no banned markers, ASCII.

## Round 21 (2026-07-27) - agent-runs5: 3/10 pass but 2 were FALSE POSITIVES

Batch 5 (10x Nova): Nova_2, Nova_5, Nova_10 passed 76/76; the other seven failed.
The FP panel flagged two of the three passers. Built all three solutions and ran a
differential probe battery against the reference to identify exactly what each got wrong.

| passer  | guarded/group-scoped const input | ref cell via invoke binding | input unbound at 2nd invoke |
|---------|----------------------------------|-----------------------------|------------------------------|
| Nova_2  | ok (guarded) / WRONG (unguarded) | ok                          | ok                           |
| Nova_5  | ok                               | WRONG (panic + silent drop) | WRONG                        |
| Nova_10 | WRONG                            | ok                          | WRONG                        |

So the FPs were Nova_5 (drops a `ref` cell mentioned only through an `invoke` input source
or output destination - compiler panics on a dangling weak reference) and Nova_10 (treats a
guarded constant drive inside a group as an unconditional constant).

### Root cause was a PROMPT asymmetry, not just missing tests

The constant-port paragraph carried the "in every cycle" qualifier only on the OUTPUT side.
The input side just said "every instantiation drives it with that one constant", which reads
as satisfied by a group-scoped or guarded drive. That single missing qualifier produced both
the FP and Nova_2's failure on the group-const test added in round 20. Adding tests without
fixing the prompt would have been unfair (and would have left 0/10). Fixed by making the
requirement symmetric and spelling out the two disqualifying shapes, and by stating that an
`invoke` binding counts as mentioning a `ref` cell. Contract stated, fix still hidden.

### Third defect found in OUR OWN reference

Probe C: an input bound to a constant at one `invoke` of an instance and omitted at a second
`invoke` of the SAME instance was removed and inlined, though the second activation leaves it
undriven. The adjudicator had noted this as a shared spec gap (reference wrong too), so it was
not itself scored as an FP, but the prompt does say a port left undriven at some site stays.
Fixed: an omitted binding disqualifies unless a continuous assignment drives the port at all
times (`continuous_write` guard, so probe F - continuous const drive plus unbound invokes -
still correctly removes).

Tests 78 -> 82:
- `an_input_driven_by_a_guarded_constant_inside_a_group_survives`
- `an_input_unbound_at_a_second_invoke_of_one_instance_survives`
- `a_ref_cell_read_only_by_an_invoke_input_binding_survives`
- `a_ref_cell_written_only_by_an_invoke_output_binding_survives`

All four discriminate against real agent code, not just synthetic mutations: replayed against
the 82-test suite, Nova_2 fails 1, Nova_5 fails 4, Nova_10 fails 3.

### Adversarial soundness sweep on the reference (FP check)

Probed families where a divergent implementation could otherwise pass unnoticed. Reference
correct on all: continuous constant drive covering omitted invoke bindings (removes), binding
present in only one `if` branch (survives), ref cell via `static invoke` input binding
(survives), ref cell mentioned only inside a comb group (survives). Contract-to-test
traceability matrix has no stated requirement without a test and no test without prompt basis.

### Projected next batch

The three ex-passers each missed exactly one or two now-stated corners, and the seven failers
died on unrelated walls (invoke output binding cleanup killed Nova_7/8/9; fixed_signature ref
cells killed Nova_4/6/7). Deliberately did NOT add a hint for the invoke-output-binding wall:
Nova_8 failed on that test alone, so hinting it would likely add a fourth passer and push the
rate to ~40%, at the cap. Expect 1-3 of 10.

State: 82 tests, 0 warnings, base 254/0, new 82/0, deterministic over 3 runs each, patches
apply clean to pristine BASE, 82 fail on test-only base and 82 pass with solution,
solution.patch 1052 counter-1 LOC, meta 374 words ASCII.

## Round 22 (2026-07-27) - reviewer feedback 2/3 desc, 1/3 tests, 2/3 solution

agent-runs6 (8 Nova + 2 Orion) landed 1/10 = 10% pass. Orion_Nova_2 the sole passer;
three near-misses at 81/82, 81/82, 80/82. In band and solvable BEFORE this round's changes.

### P4 (description, minor) - FIXED

Opening led with motivation before the ask. Swapped the two clauses so the first sentence
is the ask: "Add a `dead-port-elimination` pass. Calyx keeps every port ...". No other
description text touched by this item.

### T3/T4 constant-output through an invoke output binding - REAL BUG IN OUR REFERENCE

The reviewer said an implementation could drop the binding, pass all 82 tests, and silently
lose the destination write. Probed it: OUR OWN reference did exactly that. `invoke l()(r = dst.in)`
where `leaf.r` is constantly `32'd7` produced an invoke with NO output binding and no write to
`dst.in` at all. The value is simply lost, which violates the prompt's core invariant.

Considered propagating the constant into the caller instead (the reviewer's literal wording).
Rejected: an invoke output binding writes the destination only WHILE the invoke runs, so the
only available rewrite is a continuous assignment that drives the destination at ALL times.
That is a different program, and it conflicts with any other driver of the same destination.
The sound behavior is that the port stays, which keeps the binding and therefore the write.
Fixed in `constant_output_ports`: a port bound at any `invoke` output is disqualified from
constant removal. Liveness already keeps such a port live, so the binding survives untouched.

### T4 ref-only removal in the report - FIXED

`report_lists_removed_ref_cells_sorted` removed a data port alongside the refs, so nothing
forced a ref-only component into the report. Added `report_lists_a_component_that_lost_only_ref_cells`
(all ports live, two unmentioned refs declared out of order) asserting `"ports": []` with the
sorted `ref_cells` list.

### S2 rustfmt - FIXED

Confirmed `cargo fmt --all -- --check` failed on 7 files, all of them ours. Verified the BASE
tree is fmt-clean first, so reformatting could not introduce unrelated changes, then ran
`cargo fmt --all`. Now 0 violations on the fully patched tree.

### Difficulty impact - the constant-output test needed a fairness sentence

Replayed the new 84-test suite against the batch-6 solutions:

| run | result vs 84 tests |
|---|---|
| Orion_Nova_2 (sole passer) | 83/84 - fails ONLY the new constant-output test |
| Nova_Nova_1 | 82/84 - new test + fixed_signature refs |
| Nova_Nova_5 | 82/84 - new test + fixed_signature refs |
| Nova_Nova_4 | 81/84 - new test + 2 invoke-binding tests |

The ref-only report test costs nothing: every agent passes it. But the constant-output test
fails EVERY agent including the only passer, which is the "all agents fail the same test"
signal AGENTS.md classifies as a description gap rather than difficulty. Left unaddressed it
would be 0/10 = unsolvable reject. Added one sentence stating the rule AND its reason so it is
learnable rather than arbitrary: "An output bound to a destination by an `invoke` also stays,
because dropping that binding would lose the write it performs." Those runs predate the
sentence. Orion_Nova_2 failed on this alone, so the sentence should recover its class.
Projected 1-2 of 10. Residual risk: if the sentence does not land, the batch is 0/10.

State: 84 tests, 0 warnings, 0 rustfmt violations, base 254/0, new 84/0, new fails 84/84 on
test-only base, deterministic over 3 runs each mode, patches apply clean to pristine BASE,
solution.patch 1110 counter-1 LOC, meta 392 words ASCII.

## Round 23 (2026-07-27) - reviewer v3: 3/3 desc (clean), 1/3 tests, 1/3 solution (FSM surface)

agent-runs7 (10x Nova) landed 1/10 = 10%. Nova_Nova_7 sole passer; two near-misses at 83/84.
P4 from round 22 is resolved (description now 3/3 Clean), so only the FSM items are live.

### The FSM gap is REAL and our reference was producing INVALID IR

First question was whether `Component::fsms` is even reachable from source at this base commit,
since FSMs are usually generated by lowering passes. It is: `syntax.pest:319` has an `fsm`
production and `connections` accepts `(wire | group | static_group | fsm)*`, so a source program
can declare one directly in the wires block.

Probed it. A component whose only reader of input `a` is an FSM state assignment came out with
`a` REMOVED from the signature while the FSM state still contained `reg0.in = a;` and the caller
binding was dropped. That is not a silent miscompile, it is structurally invalid IR referencing a
port that no longer exists.

Root cause is upstream of us: the repo's own `Component::iter_assignments` and
`Rewriter::rewrite` both cover groups / comb_groups / continuous but NOT `fsms`, and
`rewrite_control` treats `FSMEnable` as a no-op. Anything built on those helpers inherits the hole,
which is exactly why our pass and every agent missed it.

Fix, mirroring the existing group handling:
- `PortLiveness::round` now reads FSM state assignments and transition guards.
- `value_driven_to` treats an FSM state write as conditional (like a group) and an FSM
  assignment / transition guard read as a read.
- `constant_output_ports` counts an FSM write as another writer.
- `rewrite` prunes FSM state assignments mentioning removed ports.
- Added `rewrite_fsms` so constant inlining reaches FSM assignments and transition guards.
  Used the public `rewrite_assign` / `rewrite_guard` rather than patching the shared
  `Rewriter`, to avoid a drive-by change to infra other passes depend on.

Tests 84 -> 88, one per case the reviewer named:
- `an_input_read_only_by_an_fsm_assignment_survives`
- `an_input_read_only_by_an_fsm_transition_guard_survives`
- `an_input_driven_by_a_constant_only_inside_an_fsm_survives`
- `a_ref_cell_used_only_by_an_fsm_survives`

All four assert the live interface survives AND `stays_well_formed`, per the reviewer's
"transformed program remains valid". There is no source syntax for enabling an fsm from control
(FSMEnable is generated internally), so the wires-block declaration is the correct surface.

### Difficulty impact and why the meta sentence is load-bearing

Replayed the 88-test suite against batch-7 solutions:

| run | result |
|---|---|
| Nova_Nova_7 (sole passer) | 87/88 - fails ONLY the FSM transition-guard test |
| Nova_Nova_1 | 87/88 - fails only `invoke_output_binding_to_a_removed_port_is_dropped`; passes all 4 FSM tests |
| Nova_Nova_2 | 84/88 |

Nova_7 already handles FSM state assignments, FSM ref cells and FSM constants; it misses only the
transition guard. So the added meta sentence names both surfaces explicitly: "the assignments
inside its states and the guards on its transitions read and drive ports just like the assignments
in a group", plus "group or `fsm` state is active" on the constant rule.

Precedent that this works, measured: round 22 added
`a_constant_output_bound_to_an_invoke_destination_survives`, which failed ALL FOUR agents replayed
at the time including the sole passer. After one fairness sentence, EVERY agent in agent-runs7
passed it. A stated behavioral rule converts an all-fail test into a passed one. Expect 1-2 of 10.
Residual risk is the same as last round: if the sentence does not land, the batch is 0/10.

State: 88 tests, 0 warnings, 0 rustfmt violations, base 254/0, new 88/0, new fails 88/88 on
test-only base, deterministic over 3 runs each mode, patches apply clean to pristine BASE,
solution.patch 1189 counter-1 LOC, meta 427 words ASCII. Dockerfile untouched.

## Round 24 (2026-07-27) - FP report on agent-runs8 Orion_Nova_2

agent-runs8 (6 Nova + 2 Orion): 1/8 = 12.5%. Orion_Nova_2 sole passer, and it is the run the
FP panel flagged. Three near-misses at 86/88.

### Both defects verified: reference CORRECT, candidate wrong, suite blind

Checked our reference against both probes before trusting the adjudicator.

1. Primitive-invoke bindings. The candidate wrote its own `rewrite_invoke` that early-returns when
   the invoked cell is a primitive, so `invoke r(in = a)()` kept referencing `a` after the port was
   removed. Our reference delegates to the repo's `Rewriter::rewrite_invoke`, which rewrites every
   actual unconditionally with no primitive special-case. Probe: `a` removed and the binding
   correctly rewritten to `in = 32'd5`, well-formed 0 errors.
2. Interface-port drivers. The candidate never seeds `@go`/`@done`/`@clk`/`@reset` as live, so an
   input structurally driving a sub-instance's `@go` looked non-observable and was deleted,
   disabling the sub-instance. Our reference seeds instantiated components' interface ports live in
   `round`, so the write survives and the read of `trigger` is recorded. Probe: `trigger` survives,
   `l.go = trigger` preserved, well-formed 0 errors.

Tests 88 -> 90:
- `a_constant_input_read_by_a_primitive_invoke_binding_is_inlined`
- `an_input_driving_a_sub_instance_go_survives`

Both assert the observable outcome plus `stays_well_formed`.

### Solvability: this is the riskiest round so far

Replay against the 90-test suite:

| run | result |
|---|---|
| Orion_Nova_2 (sole passer) | 88/90 - fails EXACTLY the two new tests |
| Nova_Nova_2 | 87/90 - fails go-drive (PASSES primitive-invoke) |
| Nova_Nova_4 | 87/90 - fails primitive-invoke (PASSES go-drive) |
| Nova_Nova_6 | 86/90 - fails both |

The mitigating signal: each defect is ALREADY solved by some agent today without any hint.
Nova_2 gets primitive-invoke right, Nova_4 gets go-drive right. So neither is a universal blind
spot or a hidden requirement - they are genuine difficulty. What no agent manages is BOTH at once.

Because the sole passer fails both, both get a stated anchor:
- "wherever it lives and whatever kind of cell is being invoked" (targets the primitive special-case)
- "and whatever drives one of them on an instance is observable for the same reason" (targets the
  unseeded interface ports)

Neither says HOW. Both are minimal extensions of sentences that already existed.

Projection 0-2 of 10, more uncertain than prior rounds because the sole passer must recover on two
independent axes rather than one. Precedent is still favorable: rounds 22 and 23 each converted an
all-agents-fail test into a passed one with a single sentence. But leaving either test out is not an
option - the FP check invalidates the whole submission on one false pass, so both holes had to close.

State: 90 tests, 0 warnings, 0 rustfmt violations, base 254/0, new 90/0, new fails 90/90 on
test-only base, deterministic over 3 runs each mode, patches apply clean to pristine BASE,
meta 450 words ASCII. Dockerfile untouched.

### Round 24b - strengthened both sentences (meta only, no code change)

The first drafts of both anchors were abstract, which is the form this repo has measured as
failing (yaegi TotalLines: abstract framing left failure at 100%, a concrete counter-example
dropped it to 22%). Rewrote both to name the concrete thing:

- was: "wherever it lives and whatever kind of cell is being invoked"
  now: "wherever it lives; an `invoke` of a primitive cell counts exactly like an `invoke` of a
  component"
  The agents' actual failure is a primitive-target early return, and the earlier wording never
  said "primitive". Safe against the specific-examples-become-a-checklist trap because the family
  has exactly two members, so naming the missing one is exhaustive rather than partial.

- was: "and whatever drives one of them on an instance is observable for the same reason"
  now: "and a value that drives one of them on an instance is live: dropping it would stop that
  instance from ever running"
  "For the same reason" pointed at the signature-preservation rule, which is not the rule that was
  broken. The new form states the observable consequence instead. Deliberately kept the general
  four-port framing rather than naming `@go` alone: an implementation that seeded only `@go` would
  pass the new test while still being wrong on `@done`, which would be a fresh FP hole.

Neither says HOW. Code, tests and patches are unchanged and verified still in sync.

Word budget note: meta is now 463 of the 500 hard cap. Future rounds have ~37 words of headroom,
so any further clarifier needs a trim elsewhere.

## Round 25 (2026-07-28) - reviewer v5 of v6: 3/3 desc, 1/3 tests, 1/3 solution

agent-runs9 (8 Nova + 2 Orion): 2/10 = 20%, the BEST result so far and the first two-passer
batch. Nova_Nova_4 and Orion_Nova_2 both 90/90; two more at 89/90. Both round-24b
strengthened sentences landed, confirming the concrete-anchor rewrite was the right call.

### Both solution defects were REAL in our reference

S1a ref-primitive invoke target. `read_invoke` recorded bindings but never the target cell
itself, so for `invoke rr(...)` where `rr` is a ref primitive, `instance_of` returned None,
the ref declaration was dropped, and the outer `rr = m` binding went with it. Probe confirmed:
`outer` lost `ref rr` while `invoke rr(` still referenced it. One-line fix, and both the
dynamic (line 730) and static (line 775) call sites route through the same `read_invoke`, so
the reviewer's "dynamic and static" wording is fully covered by the single change. Added tests
for both forms anyway.

S1b go-activation. `value_driven_to` counted only invokes when judging constness, so an
instance ALSO started by `l.go = t.out` had its invoke-bound constant inlined even though the
structural activation never supplies it. Probe confirmed `p` removed and `reg0.in = 32'd5`
substituted while `l.go = t.out` remained. Added `go_driven_structurally` and disqualified
invoke-only constant propagation when a structural `@go` drive exists, unless a continuous
drive covers every activation (matching the reviewer's stated exception).

Both FSM test items turned out to be TEST-only gaps: probes showed the reference already
prunes FSM-state assignments to removed ports (transitions and unrelated wiring intact) and
already rewrites a constant-propagated port inside a transition guard to the literal.

Tests 90 -> 96.

### One reviewer/Auto-Review suggestion REJECTED with justification

The earlier Auto Review asked for "a non-entrypoint component whose input directly feeds an
`@external` memory write, rather than reaching external state through a ref binding". That
program is not valid Calyx: `well-formed` rejects `@external` in a non-entrypoint component
identically WITH and WITHOUT our pass, so the construct is pre-existing invalid and no test
can exercise it. The valid route to `@external` state from a sub-component is via a ref
binding, which `a_port_reaching_an_external_memory_through_a_ref_survives` already covers.
Recording this as a justification rather than an open item.

### Cross-check against ALL previous reviews (nothing regressed)

- v2 P4 meta opens with the ask: intact ("Add a `dead-port-elimination` pass.")
- v2 constant-output via invoke binding test: present
- v2 ref-only report test: present
- v2 S2 rustfmt: 0 violations on the full patched tree
- v3 four FSM tests: all present
- v3 fsms wired into liveness + both constant paths + rewrite: present
- v3 `read_control` FSMEnable no-op: JUSTIFIED, not a gap. `FSMEnable` carries only an
  `RRC<FSM>`; `round` traverses `comp.fsms` directly and `rewrite` prunes them directly, so
  every FSM is visited whether or not a control node enables it.
- v5 all five items: present (2 solution fixes + 5 tests)

### Difficulty

Replay against the final 96-test suite:

| run | result |
|---|---|
| Nova_Nova_4 | 94/96 - go-drive const + fsm-guard const |
| Orion_Nova_2 | 95/96 - fsm-guard const ONLY |
| Orion_Nova_1 | 95/96 - `fixed_signature` refs (unrelated wall) |
| Nova_Nova_7 | 93/96 |

The common blocker is `a_constant_port_read_in_an_fsm_transition_guard_is_replaced`, which is
exactly the branch the reviewer predicted ("an implementation can add FSM liveness while
omitting these rewrite paths"). It is a genuinely discriminating test on an already-stated
rule. Sharpened the constant-reader sentence to name the transition guard, since both passers
implemented FSM liveness but not FSM constant-rewrite.

The clk/reset-driver test was free: both passers already handle it (probed before adding).
Projected 1-2 of 10.

State: 96 tests, 0 warnings, 0 rustfmt violations, base 254/0, new 96/0, new fails 96/96 on
test-only base, deterministic over 3 runs each, patches apply clean to pristine BASE,
solution.patch 1243 counter-1 LOC, meta 483 words ASCII. Dockerfile untouched.

### Round 25b - pre-batch FP sweep found a hole in THIS round's new code (closed, free)

Before burning a batch, swept the two code paths added this round for unpinned adjacent
corners. The `go_driven_structurally` fix had one: the new test pinned only a CONTINUOUS
`l.go = t.out`, but the idiomatic Calyx way to start a component structurally is a GROUP
(`group start { l.go = 1'd1; ... }`). An implementation scanning only continuous assignments
would pass the suite and diverge. Same for an FSM-state go drive, and for an implementation
matching the port NAME "go" instead of the `@go` attribute.

Reference is correct on all three (probed: p kept in every case). Measured the cost before
committing:

| probe | Orion_Nova_2 | Nova_Nova_4 |
|---|---|---|
| group-scoped go drive | matches reference | diverges |
| FSM-state go drive | matches reference | diverges |
| renamed (attributed) go drive | matches reference | diverges |

Free to pin: the best passer handles all three, and Nova_4 is already blocked on that axis by
the continuous test. Added two tests for the two DISTINCT discriminators - scan breadth
(group-scoped) and attribute-vs-name (renamed `@go`). Skipped the FSM-state variant as
redundant with the group one (both are "non-continuous wiring"), to avoid a redundant-test flag.

Both trace to existing meta text: "neither does an instance that some wiring also starts
through its `@go`" ("some wiring" was deliberately general and now covers groups), and the
four-interface-port sentence plus the established attribute-not-name identity contract.

Tests 96 -> 98. base 254/0, new 98/0, new fails 98/98 on test-only base, deterministic 3x,
0 warnings, 0 rustfmt violations, patches apply clean, meta unchanged at 483 words.

## Round 26 (2026-07-28) - agent-runs10 FAIL_TEST_MISMATCH: WE WERE WRONG, fixed

Orion run: 254/254 baseline, 97/98 new, sole failure
`a_constant_port_read_in_an_fsm_transition_guard_is_replaced`. Eval flagged
`environmentBlocker.type=verifier`, `agentBlameUnfair=true`, `confidence=high`.

Checked it before deciding whether to contest. The agent was right and the test was brittle.

`calyx/ir/src/printer.rs:874` hardcodes `ir::Guard::True => "1'b1"`. Our reference replaces the
guard port with a reference to a constant CELL, so it prints through `port_to_str` as `1'd1`.
The agent instead recognised the propagated constant makes the guard unconditionally true and
folded it to `Guard::True`, which the repo's own printer emits as `1'b1`. Same semantics, and
the fold is arguably the more idiomatic compiler move. The rest of the agent's output was
exactly right: `leaf` lost `flag`, no `l.flag` reference remained, `default -> 0,` and the
unrelated `r0.in = 1'd1;` intact.

This was also an inconsistency inside our own suite. `a_constant_input_read_in_a_guard_is_inlined`
and `a_constant_output_read_in_a_guard_is_propagated` both already accept two rewrite forms, and
the Test Fairness check specifically praised that as "well-designed non-brittle allowance". I
wrote the FSM transition-guard test without the same allowance. Exact-string assertion on printer
text is a documented revert cause; it should never have shipped that way.

Fixed the whole class, not just the reported instance. Audited every assertion pinning a constant
in guard position and found the two sibling tests were ALSO missing the `1'b1` form (they allowed
`1'd1 ? X` and the fully-dropped `X`, but not an explicitly-kept `Guard::True`):

- `a_constant_input_read_in_a_guard_is_inlined`: added `reg0.in = 1'b1 ? 32'd1;`
- `a_constant_output_read_in_a_guard_is_propagated`: added `dst.in = 1'b1 ? 32'd5;`
- `a_constant_port_read_in_an_fsm_transition_guard_is_replaced`: added `1'b1 -> 1,`

Discrimination preserved: mutation removing `rewrite_fsms` from the constant-output path still
fails ONLY that test (97 passed / 1 failed), so the relaxation costs no trap strength. The
runs10 agent solution now scores 98/98 against the updated suite.

Test count unchanged at 98. solution.patch byte-identical (verified) - this was a test-only fix.
base 254/0, new 98/0, new fails 98/98 on test-only base, deterministic 3x, patches apply clean.

Lesson: assert semantic outcome plus a disjunction over legitimate printer forms, never a single
exact literal, whenever a guard can be constant-folded. Grep for `'d` inside asserted guard text
before shipping.

### Round 26b - full brittleness sweep after the `1'b1` mismatch

Audited the entire printer for other places a legitimate implementation could produce different
text, rather than fixing only the reported instance.

Findings, all verified against `calyx/ir/src/printer.rs`:
- The printer contains exactly TWO hardcoded output forms: line 874 `Guard::True => "1'b1"` and
  line 896 `format!("{}.{}", cell, port)`. Line 874 is the ONLY source of literal-form variation.
- Constant printing is `format!("{width}'d{val}")` at line 893. Decimal is FORCED; there is no
  radix choice for a constant-cell reference. So every `32'd5` / `reg0.in = 32'd8;` style
  assertion in the suite is safe - those are constant-cell references, not guards.
- Zero asserted guard strings use `&`, `|` or `!`, so there is no operator-precedence or
  parenthesization ambiguity to accommodate.
- `Cell::remove_ports` uses `retain()`, which is order preserving, so the exact-signature
  `assert_eq!`s are stable. Test Fairness had already rated those Repo-discoverable via
  `component.rs:21-26,74-86` + `printer.rs:192-218`.
- The one remaining guard assertion with a `?`, `l0.p = flag.out ? 32'd5;`, guards on a REGISTER
  output, not a constant, so no folding is possible. Safe as an exact match.

Conclusion: `Guard::True` was the only variable printed form in the repo, and it is now
accommodated in all three places it can surface. The class is closed, not just the instance.

Discrimination re-verified after loosening. Mutation disabling constant-input inlining fails 7
tests including both relaxed siblings (`a_constant_input_read_in_a_guard_is_inlined`,
`a_constant_input_read_by_a_primitive_invoke_binding_is_inlined`); mutation removing the FSM guard
rewrite fails only `a_constant_port_read_in_an_fsm_transition_guard_is_replaced`. No trap strength
was traded away for the fairness fix.

Fairness re-checked: all 17 requirement groups still map to at least one test. Gates: 0 warnings,
0 rustfmt violations, 98/98, meta 483 words ASCII, no banned markers, both patches ASCII.

### Round 26c - AI-slop "wall of text" warning (fixed, zero word change)

Submission-time heuristic flagged `wallOfText: 2` (two paragraphs at 150+ words). All other
signals were already clean: emdashes 0, hardwrappedParagraphs 0, blankLineRuns 0.

Note on the remedy: dash-bullets ARE permitted by DESCRIPTION.md (the Allowed column lists them;
what is banned is NUMBERED lists and `##` headers). Chose shorter paragraphs anyway, the other
remedy the warning itself offers, because bulleting risks Common Mistake #17 "turning the
description into a checklist" and the prose voice is what earned 3/3 Clean from the human
reviewer twice.

Split each long paragraph at its natural semantic seam:
- para on liveness: "what makes a port unused" | "what removal drags with it + fixed point"
- para on constants: "the general all-cycle rule" | "the per-side input/output specifics"

Result: 6 paragraphs -> 8, longest now 123 words, zero walls. Word count UNCHANGED at 483 (verified
by normalizing whitespace and confirming the prose is byte-identical across the two new breaks),
so the 500 cap headroom is untouched and no requirement wording moved. meta.md is a standalone
deliverable, so test.patch and solution.patch are unaffected.
