# feedback — amaranth-instance-models

## What this is

Olympus submission against `amaranth-lang/amaranth` (BSD-2-Clause, 2056 stars, Python), base
`fe524a11936222b2dd08751c68c66ef4b6d0bd22`. The simulator learns to let Python code stand in for
an `Instance` of an external module, or for a submodule with a signature. Built end to end and
validated locally; no agent batch has run yet, so there is no difficulty datapoint.

## Pick history for this slot (two picks died at the gates first)

1. **open2b/scriggo, runtime-selected template rendering** - DEAD at Gate 8
   (maintainer-philosophy). Issue [#958](https://github.com/open2b/scriggo/issues/958) is closed
   with gazerro stating "The `render` operator takes a constant string as its argument, not
   a string variable. This is the intended behavior and not a bug", and pointing at a builtin
   function as the correct workaround. Same class as `taplo-reorder-comment-preservation`:
   a maintainer calling the current behavior correct makes the feature off-scope, and the reject is
   not contestable. Caught before a line of code was written, by reading the closing comment of the
   issue the feature would have been built on.
2. **slatedb/slatedb, secondary indexes maintained through compaction** - DEAD at Gate 5
   (cold-not-live). The default branch takes commits daily and the open PR list is full of
   RFC implementations landing in the core (`RFC 0031` block cache policy, `RFC 0029` L0 SST
   allocation, multi_get). An RFC-driven young storage engine has no cold core.

Both kills are the gates working as designed: the expensive failure is authoring first and
discovering the gate later.

## Why this pick clears the gates

- **F2P (Gate 1), reproduced on base:** a design containing `Instance("MY_PRIM", i_A=..., o_Y=...)`
  simulates without complaint and the output stays at 0 forever. There is no way to give it
  behavior.
- **Maintainer-desired but undesigned (Gate 8):** issue
  [#392](https://github.com/amaranth-lang/amaranth/issues/392), open since 2020-05-28, whitequark:
  "Yep, this is planned with the next round of simulator improvements... but I'm not sure what the
  API would look like." Planned, unclaimed for six years, and explicitly not designed, so the
  semantics are invented here and pinned by the description. That is the shape that survives both
  the exclusivity and the derivative checks.
- **Cold (Gate 5):** `amaranth/sim/` has 5 commits since 2025-01-01, all minor.
- **Exclusivity (Gate 7b):** no PR in the canonical org touches instance simulation, and no RFC in
  `amaranth-lang/rfcs` covers it. Note that most other amaranth features are RFC-governed, and
  several attractive ones are already taken that way: `lib.fixed` has PR #1578 implementing RFC 41,
  which is why fixed-point was dropped as a candidate.
- **Dedup (Gate 7):** the corpus has no simulator or black-box-modeling pick. Our one prior
  amaranth submission (`amaranth-stream-width-converter`) touches `amaranth/lib/stream.py` and
  shares no file with this one.
- **Not a documented spec, not a famous paradigm:** cocotb and Verilator solve a related problem
  with a completely different architecture (foreign-language cosimulation); there is nothing to
  port and no reference to transcribe.

## Design decisions worth recording

- **Models are design processes, not testbenches.** This is the load-bearing decision and the lead
  trap. A model needs `ctx.get`, and the only pre-existing context that offers it is
  `TestbenchContext` - which runs after the design has converged and calls `step_design()` on every
  write. Reusing it puts model output one delta or one clock edge behind, which surfaces as wrong
  values in the chained-model and clocked-model tests rather than as an error. The solution adds
  `InstanceModelContext`: `get` allowed, `set` restricted to what the target drives, no stepping.
- **Replacing a submodule means suppressing its subtree.** `_FragmentCompiler` now records which
  processes and which combinationally driven signals belong to each fragment, so a replaced
  submodule's own processes can be dropped and its outputs released. Clearing `is_comb` was
  necessary: without it `eval_assign` refuses the model's writes with "Combinationally driven
  signals cannot be overriden by testbenches", which is a genuinely misdirecting symptom.
- **Value-change triggers.** `ctx.changed()` only accepts bare signals, so a model of an instance
  whose port is connected to an expression (`i_A=Cat(a, b)`) could not react to it at all. The
  model context now builds a `ValueChangedTrigger` for such ports; pysim wakes on every underlying
  signal and samples the expression. Four sites in `_PyTriggerState` had to learn the new kind, and
  forgetting `initial_eligible` silently costs models their initial evaluation at time 0.
- **Binding precedence** (path beats type) is resolved on every add by rebuilding the model
  process set, so the result does not depend on the order in which models were added. Superseded
  coroutines are closed to avoid "coroutine was never awaited" noise.
- **Error kinds are all repo-precedented:** `NameError` for a selector matching nothing (as
  `add_clock` does for a missing domain), `DriverConflict` for two drivers (as `add_clock` does),
  `RuntimeError` for adding to a running simulation, `ValueError` and `TypeError` for bad
  arguments. Nothing invented, per the error-kind natural-solution law.

## Size

human-effective ~305 across 7 files (505 raw), clearing the 250 sprint floor but under the 430
aspiration. The core instance-model feature alone measured 191, which is the mature-and-
well-factored-codebase compression the playbook warns about; the submodule-replacement axis and
the value-change triggers are genuine capability from the same user story (issue #392 asks for
both black-box ports and behavioral substitution), not padding. If more scope is wanted, the
untaken axis is `io_` ports, which needs IO-net state in pysim and is a much bigger change.

## Review rounds

**R1 (AI pre-checks, 2026-07-27).** Description quality returned request_changes on two HIGH items,
both current-behavior narration ("an `Instance` ... outputs sit at 0 for the whole run" and
"anything left unmodeled keeps behaving exactly as it does now"); both removed, along with the
MEDIUM (`io_` ports) and both LOW suggestions. Test quality returned a WARNING that the tests pin
paths rooted at `top` without the description saying so; the convention is now stated. Two named
coverage gaps closed with tests (non-async submodule constructor, submodule model restarted on
reset), taking the suite to 54. The `io_` gap was closed by dropping the claim instead of testing
it, so the description no longer asserts anything the tests do not check. Solution unchanged; only
meta.md and test.patch moved.

## R2 — Environment Quality: FAIL, then FIXED

The platform's Environment Quality check runs the REPOSITORY'S OWN suite (`python -m pytest` and
`python -m unittest discover -t . -s tests -v`) and requires it to come clean. `test.sh` exclusions
are invisible to it. It returned FAIL: "the offline baseline environment is missing the `sby` tool
and the example subprocess tests cannot import `amaranth`".

Both causes were in the Dockerfile, not in the repo:

- `tests/test_lib_fifo.py::FIFOFormalCase` runs real formal verification and needs `sby`, `yices2`
  and yosys >= 0.40 (amaranth's CI installs `yices2` from an Ubuntu PPA).
- `tests/test_examples.py` spawns `python examples/*.py` as subprocesses, so amaranth has to be
  installed rather than merely importable from the working directory.

**Fix:** install the official YosysHQ **oss-cad-suite** tarball into `/opt` and put its `bin` on
`PATH`, and `pip install .` with `PDM_BUILD_SCM_VERSION=0.5.6` (amaranth's PDM config takes the
version from SCM, which a `git archive` extract does not have, so a plain `pip install .` fails on
metadata generation). With that, the WHOLE suite passes with no exclusions at all:
**1146 passed / 0 failed in 21s**, offline, as uid 1000. `test.sh` no longer excludes anything.

**A hand-rolled toolchain is not good enough, and this is the trap worth remembering.** My first
attempt substituted wasm `yowasp-yosys` (symlinked as `yosys`), `sby` built from git and standalone
`yices 2.7.0` binaries. Everything resolved on PATH, the tests ran, and they still failed:
8 formal failures in 201s and 12 example failures in 273s. I nearly concluded from that evidence
that amaranth was structurally unusable for this platform. The official prebuilt suite passes the
same tests in 6.3s and 2.9s. **Do not infer that a repo is env-dead from a substitute toolchain
failing — install the toolchain the project documents.**

**The original process error stands:** I ran the vanilla suite locally at build time, saw the 20
failures, and treated them as "exclude in `test.sh` with a documented reason" instead of as an
Environment Quality problem to solve in the Dockerfile. The check belongs at PICK time, and the
first response to a non-green vanilla suite is to provision the documented toolchain.

## R3 — Test Fairness: FAIL (3 of 59), fixed

- Two tests pinned a conflict rule in the reverse order from the one the description stated. The
  description said a model on a target inside one that is already replaced conflicts, which covers
  ancestor-then-descendant but not descendant-then-ancestor; the tests asserted both. The
  implementation was already symmetric, so the fix is one clause in the description: "two models
  whose targets contain one another whichever of the two is added first". All four containment
  tests now trace to it.
- The VCD test asserted the raw token `b111` in the file text, which couples the assertion to an
  external writer's formatting. It now parses the dump: it finds the `$var` identifier for the
  8-bit signal and decodes the value-change lines for that identifier, asserting 7 is among them.
- Three advisory coverage suggestions: two added as tests (a coroutine object and an
  async-generator function both raising `TypeError`; an instance selector rejecting a submodule
  path and a submodule selector rejecting an instance path, both `NameError`). The third,
  enumeration after replacement, was deliberately NOT taken: pinning it would need a new
  description sentence about what `instances()`/`submodules()` report once a target is replaced,
  and the description-quality gate has already asked twice for fewer sentences. Untested and
  unstated is the fair combination; the advisory is non-blocking.

Suite is now 61 tests. Solution unchanged.

## R4 — Test Fairness: pass, 2 advisory suggestions taken

No unfair tests this round. Both advisory items added, since each traces to a sentence the
description already carries: submodule-model constructor validation parity (wrong arity, an
already-created coroutine object, an async-generator function, all `TypeError`), and a submodule
model attempting to drive a signal outside its target (`DriverConflict`). Suite 61 -> 64.
Solution unchanged.

## R5 — 3 advisory suggestions: 1 taken, 2 declined with reasons

- **Mixed-depth instance listing order: TAKEN.** New fixture with a shallow instance declared
  before a submodule that contains a deeper one, asserting
  `[("ADDER", "top.u_shallow"), ("INV", "top.u_holder.u_inv")]`. The fixture is deliberately
  arranged so depth-first and breadth-first traversal give the SAME answer, so the test pins the
  documented top-down ordering without pinning a traversal strategy the description does not state.
  Suite 64 -> 65.
- **Submodule-model clock conflict: DECLINED, not constructible.** An instance can have a port
  connected directly to `ClockSignal(...)`, which is why the instance-side rule is testable. A
  submodule's outputs are its signature members, which are its own signals; a clock domain's `clk`
  is never a signature member. The nearest construction has the parent drive `clk` combinationally
  from the member, and adding a clock there raises amaranth's pre-existing "already driven by
  combinational logic" error, which tests amaranth rather than this feature.
- **Immediate registration lifecycle: DECLINED, already covered.** Calling an async function
  produces a coroutine without executing its body, so the only observable proof that the
  constructor is invoked during `add_*_model` is an exception raised by the call itself. That is
  exactly what the wrong-arity tests assert, for both APIs: they expect `TypeError` out of
  `add_instance_model` / `add_submodule_model`, before the simulation ever advances. A test
  asserting body side effects at add time would assert something untrue.

Solution unchanged.

## R6 — 3 advisory suggestions, all taken

- **Plain Elaboratable filtering.** The reviewer was right that `test_submodules_omits_plain_elaboratables`
  did not test what its name claimed: it used a plain `Elaboratable` as the TOP, which is never a
  submodule regardless. It now nests a plain `Elaboratable` next to a signature-bearing component
  and asserts `submodules()` lists only the component.
- **Sibling submodule enumeration order.** Two sibling components, asserting their order, matching
  the sibling ordering check that already existed for `instances()`.
- **Partial output connections.** Two instances whose outputs are connected to the low and high
  nibbles of one signal; each model drives its own slice and the packed value comes out correct
  for two different inputs. Width truncation was deliberately NOT asserted: nothing in the
  description says what an over-wide write does, so pinning amaranth's masking behaviour would be
  the same unstated-policy mistake that failed R3.

Suite 65 -> 67. Solution unchanged.

## R7 — 3 advisory suggestions: 2 taken, 1 declined again

- **Sibling enumeration order: TAKEN, and it needed a description change first.** The reviewer was
  right that `u_first`/`u_second` satisfy both lexical and declaration order, so the existing tests
  did not establish which is intended. Verified the implementation walks the design in declaration
  order, then stated it: the enumeration sentence now ends "and, among siblings, in the order the
  design adds them". The new test uses deliberately reverse-lexical names (`u_zebra` before
  `u_alpha`, `u_yankee` before `u_bravo`) so it can only pass on declaration order. Testing this
  without the description clause would have been the R3 mistake again.
- **Nonzero initial values: TAKEN.** An input signal with `init=0x5a`; the model records what it
  observes, and the test asserts `0x5a` both on the first run and after `reset()`.
- **Submodule model versus clock conflict: DECLINED again, with the sharper reason.** A submodule's
  outputs are its signature members, which are signals the component owns; a clock domain's `clk`
  is never a signature member, so the situation cannot be built. The nearest legal construction has
  the parent drive `clk` combinationally from a member, where `add_clock` already raises amaranth's
  own "already driven by combinational logic" error. Forcing it would mean overwriting a member
  attribute with `ClockSignal(...)`, which violates `Signature.is_compliant` and would pin
  behaviour on a malformed interface object. The description's rule is stated for models generally
  and is true; it is simply vacuous for the submodule kind.

Suite 67 -> 69. Solution unchanged.

## R8 — Test Fairness: FAIL (3 of 69) on sibling ordering, fixed by removing the claim

All three flagged tests pinned the order of SAME-DEPTH SIBLINGS in `instances()` / `submodules()`.
The verdict quoted the prompt as specifying only top-down hierarchy order, i.e. it was evaluated
against the description WITHOUT the sibling clause added in R7. Rather than depend on which
description version is in play, the claim was dropped on both sides:

- The R7 clause "and, among siblings, in the order the design adds them" was REVERTED, so the
  description states only top-down ordering again.
- `test_instances_lists_type_and_path` and the sibling submodule test now compare sorted lists, so
  they assert contents without asserting sibling order.
- The declaration-order test was replaced by `test_enumeration_lists_shallower_targets_before_deeper_ones`
  over a two-branch fixture. It asserts contents order-insensitively plus the one relation the
  description does support: an ancestor appears before its descendant (`top.u_right` before
  `top.u_right.u_deep`). No cross-branch or sibling order is assumed.

Audited every other enumeration assertion: what remains is singletons and one ancestor-before-
descendant pair, both fair. Two renames (`test_submodules_lists_siblings_in_order` ->
`test_submodules_lists_sibling_paths`, and the declaration-order test) are safe here because no
agent batch has run yet; once a batch exists, test function names are frozen.

Advisory items this round: **Running lifecycle boundary TAKEN** (both APIs now reject a model added
after a single `advance()`, not only after a completed `run()`). **Constructor timing DECLINED** -
calling an async function creates a coroutine without executing its body, so "constructed at add
time" has no observable effect beyond the exception the call itself raises, which the wrong-arity
tests already assert; the only other signal is a garbage-collection RuntimeWarning, which is not a
sound assertion. **Top-down ordering across branches** is what the new test above provides.
**Submodule clock conflict DECLINED** for the third time, same structural reason: a component's
outputs are its signature members, a domain clock never is one, and forcing it requires violating
`Signature.is_compliant`.

Suite 69 -> 71. Solution unchanged.

## R9 — 3 advisory suggestions, all taken; I was wrong about the clock one

- **Clock conflict for submodule outputs: TAKEN, after three wrong declines.** I had argued this
  was not constructible because a component's outputs are its own signature members and a domain
  clock never is one. That reasoning assumed "submodule with a signature" means
  `wiring.Component`. It does not: the implementation accepts any elaboratable carrying
  a `signature`, and such an object can legitimately expose an externally owned signal as an `Out`
  member. A `ClockSource` elaboratable holding the domain's `clk` as its member is compliant, is
  enumerated by `submodules()`, and produces the conflict in both registration orders. Three tests
  added: both orders plus a submodule model actually driving a clock domain (five slow-domain
  edges over ten microseconds). Lesson: when a reviewer repeats a suggestion, build the case
  before re-asserting the argument.
- **Model addition after reset: TAKEN.** `advance()` then `reset()` returns the simulator to the
  configurable state, so a model added afterwards works; asserted for both APIs.
- **Submodule selector signature requirement: TAKEN.** Omitting the required `path` raises
  `TypeError`, and a signature-bearing top-level object is not enumerated by `submodules()` and is
  not selectable by `path="top"`.

**Solution changed this round** (first time in six): the clock-conflict message said "already
driven by a model of an instance", which is wrong now that submodule models can hit the same rule.
It reads "already driven by a model". No test asserts messages, so this is cosmetic, but the full
matrix was re-run because the solution moved.

Suite 71 -> 78. Effective LOC unchanged at 303 across 7 files.

## R10 — two checks in direct conflict; contract kept, wording tightened

- **Problem description contains only necessary information: request_changes, 4 HIGH.** Every HIGH
  item asks to delete a whole contract paragraph (the API and selection rules, the constructor and
  handle contract, the runtime semantics, the conflict and error list) on the rationale that "the
  tests define these".
- **Problem and tests are aligned: WARNING.** The same round asks for MORE precision: state that
  "running" covers any state after a single `advance()` until reset, and that a constructor must be
  an async function of exactly two parameters rather than a coroutine object or an async generator.

These pull in opposite directions, and the solver never sees the tests. Deleting the four
paragraphs would leave roughly 60 of the 78 hidden tests asserting behavior the prompt never
states, which is precisely the failure mode that produced two Test Fairness FAILs earlier in this
cycle (sibling ordering, reverse-order conflicts). Test Fairness is the gate that decides whether
the problem is fair and solvable; description length is style. The approved corpus agrees: the
`wirefilter-dynamic-operands` description is a comparable size and is likewise a list of
behavioral rules.

So the contract stays, and instead:
- the prose was tightened (redundant connectives removed) while every tested behavior stays stated,
- both alignment clarifications were taken: "Once the simulation has advanced, adding a model
  raises `RuntimeError` until `reset()` makes the simulator configurable again" (which also states
  the behavior the two new post-reset tests assert), and "an async function of exactly two
  parameters ... a coroutine object, an async generator function or anything else raises
  `TypeError`".

Net effect on length is nil (339 -> 341 words) because the tightening paid for the clarifications.
If a human reviewer later insists on the cuts, the honest fix is to delete the corresponding tests
in the same edit, not to leave them asserting unstated behavior.

Tests and solution unchanged this round.

## R11 — 2 advisory suggestions taken; the first exposed an over-claim in my own description

- **Constructor arity variants: TAKEN, and it corrected the description.** R10's alignment check
  had asked me to say "exactly two parameters", and I did. Probing the implementation before
  writing the tests showed that is not what happens: too few or too many REQUIRED parameters raise
  `TypeError` at call time, but variadic (`*args`) and defaulted (`ctx, instance, scale=2`)
  signatures are accepted, because they can be called with two arguments. Accepting them is the
  right behavior (it is what makes `functools.partial` and callable objects usable), so the
  description was corrected to match: "an async function, called with the simulator context and
  a handle; a coroutine object, an async generator function, or a function that cannot be called
  with those two arguments raises `TypeError`". Four tests now pin all of it: too few, too many,
  variadic accepted and working, defaulted accepted and working.
- **Type selection with a path override across reset: TAKEN.** The mixed type-wide plus
  path-specific binding is asserted during the initial run and the simulation is then reset and
  re-run, so the per-target selection is shown to survive reset rather than only holding once.

Had I written the arity tests from the description instead of from a probe, I would have asserted
`TypeError` for variadic constructors and shipped a test the reference implementation fails. Probe
first, then assert.

Suite 78 -> 82. Solution unchanged.

## R12 — submodule signature parity and partial path overrides

- **Accepted submodule constructor signatures: TAKEN.** The variadic and defaulted-parameter
  acceptance tests that existed for `add_instance_model` are mirrored for `add_submodule_model`.
- **Type selector with partial path overrides: TAKEN.** A three-instance fixture where a type-wide
  model covers every `ADDER` and one path override replaces the middle one; the test asserts all
  three outputs, one constructor per target, and the same selection after `reset()`.

(This round was interrupted: the machine's disk filled during the Docker matrix, which blocked every
tool until it was cleared. The tests were written and passing locally; the matrix was re-run in R13
below. Process note: reuse one validation cell and prune images between rounds - roughly ten images
each layering on a 699 MB toolchain is what filled the disk.)

## R13 — Test Fairness: FAIL (6 of 85), container type over-specified

All six flagged tests asserted the enumeration APIs by concrete `list` equality, or called
`.index()` on the returned object. The description only promises reported contents in top-down
order, so a tuple or an ordered generator would satisfy it and fail those tests. Fixed exactly as
the reviewer proposed: every enumeration assertion now normalizes with `list(sim.instances())` /
`list(sim.submodules())` before comparing or indexing, so any ordered iterable passes. Contents and
the ancestor-before-descendant relation are still asserted.

This is the same failure family as R3 and R8: an assertion that pins something the description
never promised. Earlier rounds pinned sibling order and reverse-order conflicts; this one pinned the
return container.

Advisories: **submodule constructor arity symmetry TAKEN** (a submodule constructor requiring three
non-default arguments raises `TypeError`, matching the instance-side test). **Registration-time
construction DECLINED for the third time**, with the reasoning restated: calling an async function
creates a coroutine without running its body, so "one coroutine per target at add time" has no
observable consequence beyond the exception the call itself raises. The add-time half is already
asserted by the wrong-arity tests on both APIs, and the per-target half by the constructor-count
test; their conjunction adds no new observable, and the only remaining signal is a
garbage-collection `RuntimeWarning`, which is not a sound assertion.

Suite 82 -> 86. Solution unchanged.

## R14 — hardening pass (test-only; solution untouched)

The suite was fair but the difficulty was mostly "thread the feature through", which caps the band.
Added four composition walls that a natural-but-wrong implementation fails, each riding a principle
the description already states or now states in one clause:

1. **Replace means suppress, not override.** A replaced submodule's internal synchronous state must
   not advance, and a memory inside it must not update. The shortcut of letting the model write
   over the outputs while the RTL keeps running gives the right output and the wrong state; the
   internal counter and the memory read expose it. Rides "the logic of that submodule and of
   everything below it is then not evaluated".
2. **Models are simulation-only.** `rtlil.convert` output must be byte-identical with and without
   models attached, for both APIs. This forbids the obvious implementation of submodule
   replacement, rewriting the fragment tree, and the failure surfaces in conversion rather than in
   anything the model API points at. Needed one new clause: "Models exist only while simulating, so
   converting a design is unaffected by them".
3. **Settling with feedback.** A model whose output returns to its own input through combinational
   logic, and two models sharing one loop, must both reach a fixpoint. Testbench-scheduled models
   or models evaluated once per time step hang or read stale values. The existing delta-cycle
   sentence was extended by two words ("and to itself").
4. **Machinery-riding stated as one principle**, not an enumeration (Rule 7): "everything the
   simulator already does keeps working with what a model drives".

Every wall was probed against the reference before the tests were written, and each discriminates:
the reference gives internal=0 with count=99, byte-identical conversion, and fixpoints at 5 and 6.

Cost in description: two sentences, one of them two words. Suite 86 -> 92. Solution unchanged, which
is the point: this is a composition-first re-harden, not new surface.

## R15 — description-quality request_changes (4 HIGH) declined again, with a compression pass

Same four HIGH items as R10, same stated rationale: "the tests fully specify usage, error
conditions, and ordering; solver can discover API names and behavior from the test suite and
codebase". That premise is false on this platform - the hidden tests are not visible to the solver.
Those four paragraphs are the only place that carries:

- the API names and signatures (`add_instance_model`, `add_submodule_model`, `instances`,
  `submodules`), which cannot be guessed,
- the handle attribute names (`path`, `inputs`, `outputs`, `type`, `parameters`, `attributes`) and
  their key format,
- the exception types the tests assert (`ValueError`, `NameError`, `TypeError`, `DriverConflict`,
  `RuntimeError`),
- the semantics the hardening walls ride (same-delta visibility, subtree suppression,
  conversion immutability).

Deleting them would leave about 90 of the 92 tests asserting behavior the prompt never states.
That exact failure mode has already produced three Test Fairness FAILs in this cycle (R3
reverse-order conflicts, R8 sibling ordering, R13 enumeration container type), each for a far
smaller omission than a whole paragraph. Test Fairness decides whether the task is solvable at all;
description length is style, and the approved `wirefilter-dynamic-operands` description is
comparable in size and likewise a list of behavioral rules.

What was done instead: a genuine compression pass, same facts in fewer words (375 -> 348), by
merging clauses and dropping filler ("attaches a model to instances, selected by..." rather than
restating the selector twice, "goes unevaluated" for "is then not evaluated", and the conflict list
led by the exception rather than by each case).

The alternative, if a human reviewer insists on the cuts, is to delete the contract AND the tests
that depend on it in the same edit. That is a different, much smaller problem: it would remove the
error-taxonomy, handle-contract, precedence, enumeration and conversion-immutability tests, roughly
40 of 92, and with them most of the difficulty. That trade is the reviewer's call to make, not
something to absorb silently.

Tests and solution unchanged; meta.md is not part of either patch, so no revalidation was needed.

## R16 — surgical trims: 4 taken, 1 partial, 1 declined on documented fairness grounds

This round the check moved from "delete the contract" to specific phrases, most of which are safe.

- **[HIGH] "and everything the simulator already does keeps working with what a model drives":
  REMOVED.** It was the Rule-7 machinery-riding principle, but the concrete clauses that precede it
  ("A model is part of the design", "what it drives is visible to the design") already carry the
  tests that rode it, and a vague catch-all is a liability in front of a fairness checker too.
- **[LOW] "report what can be selected": REMOVED.** Return shapes and ordering say it.
- **[LOW] "They exist only while simulating": REMOVED**, conversion guarantee kept.
- **[MEDIUM] example list after the `TypeError` rule: PARTIALLY taken.** "a coroutine object" was
  dropped, since a coroutine object is not callable and the general rule covers it. "an async
  generator function" was KEPT and moved to the front: an async generator function CAN be called
  with two arguments (it returns an async generator), so the general rule does NOT cover it, and
  the two tests that assert `TypeError` for it would be asserting unstated behavior.
- **[LOW] "whichever is added first": DECLINED.** This phrase exists because Test Fairness FAILED
  on exactly this point in R3: `test_submodule_model_conflicts_with_nested_submodule_model` and
  `test_submodule_model_conflicts_with_instance_model_inside_it` assert the conflict in the reverse
  registration order, and the verdict then was that the description covered only one direction.
  The current suggestion calls order-independence "implied"; the earlier fairness check explicitly
  did not read it that way. Removing four words to re-fail a blocking gate is a bad trade.

375 -> 348 -> 321 words across the two rounds, with every fairness-load-bearing fact intact. Tests
and solution unchanged.

## Validation

See `eval-results.md`. Summary: F2P 92/92 fail on base; 92/92 pass with the solution; the full
repo suite is 1146 passed / 0 failed with and without the solution and with no exclusions; both
patch apply orders clean; 3x deterministic; whole matrix run inside the built image with
`--network none` as uid 1000.

## R15 - hardening after batch 1 (4/6 = 67% pass, cap is 40%)

Batch 1 came back too easy. Every run graded the description clear, the tests deterministic, the
difficulty challenging and the environment clean, and both failures were fair
(FAIL_MISSED_REQUIREMENT, `agent_blame_unfair: false`). So nothing was broken - the problem was
simply transcribable. Full table and diagnosis in `eval-results.md`.

The two failures were fine print inside already-stated rules, not missing capabilities: run 3 missed
per-bit ownership of a partially-connected output, run 6 resolved selector precedence at add time so
type-then-path raised instead of overriding. Nova builds the entire architecture in 80-156 messages
without trouble, so the lever is composition of the stated rules, and the two blind spots that each
already killed a run are the ones worth multiplying.

Diagnosing run 3 turned up a real defect in the reference. `_Model._driven` was a `SignalSet` built
from `_rhs_signals()`, making `_check_driven` signal-granular: a model connected to `packed[0:4]`
could drive `packed[4:8]`, which belongs to a sibling instance. That contradicts the meta's own
"driving anything the target does not drive raises DriverConflict". Fixed by collecting per-bit
masks with the repo's own `LHSMaskCollector` and testing `mask & ~owned`. Probed all four
directions afterwards: disjoint slices coexist, a sibling's bits are refused, the whole
partly-owned signal is refused, own bits still write.

That fix is what makes the trap interdependent rather than single-point. Only one direction was
tested before (disjoint slices must coexist), so an agent could pass by dropping the check
entirely. Both directions are now tested, and no single-point fix satisfies both: signal-granular
logic fails the disjoint case, no-check logic fails the foreign-bit case, only mask arithmetic
passes both. It is also misdirecting - the foreign-bit failure is a missing exception in a test that
reads like an ordinary duplicate-driver test.

Seven tests added (92 -> 99), all composition of already-stated rules:

- `test_model_cannot_drive_bits_owned_by_a_sibling_instance`
- `test_model_cannot_drive_whole_signal_it_partly_owns`
- `test_one_type_model_drives_disjoint_slices_per_instance` - one type, two instances, so the mask
  must be per instance rather than cached per type or per constructor
- `test_shared_type_model_cannot_drive_another_instances_bits` - same, refusing direction
- `test_submodule_model_conflicts_with_path_selected_model_inside_it` - containment composed with
  path selection rather than type selection
- `test_path_selected_model_conflicts_with_submodule_model_around_it` - reverse order
- `test_path_override_applies_to_type_model_added_after_reset` - order-independent precedence
  composed with the reset lifecycle

meta.md gained one generic clause rather than an enumeration, keeping the contract stated while the
fix stays hidden: "What a target drives is tracked per bit, so models connected to disjoint parts of
one signal coexist and each may drive only its own part", and "driving anything" became "driving any
bit". 348 words, under the 500 cap, ASCII clean. Fairness backing is strong - the evaluator on run 3
independently ruled per-bit ownership inferable from `LHSMaskCollector`, `Module._add_statement` and
the pre-existing `test_multiple_modules`, which drives `b[0:2]`, `b[4:6]`, `b[2:4]` and `b[6:8]` from
separate submodules.

Two hardening candidates were rejected as engine invariants rather than fair game, both recorded in
`eval-results.md`: a signal driven half by a model and half by design comb logic (`is_comb` is a
per-slot flag and `_eval_assign_inner` refuses any write to a comb slot - bit-granularity there is a
base-engine redesign), and oscillation detection for model loops (`step_design()` has no iteration
limit, so a comb oscillation hangs in vanilla amaranth too).

Validation after R15: 99/99 new pass with the solution, 99/99 fail on base source, identical across
3 runs. Full suite 1245 tests with 20 errors, all of them `test_examples` and
`FIFOFormalCase` failing on a missing Yosys binary in the local venv - the Dockerfile ships
oss-cad-suite, and 1146 baseline + 99 new = 1245 matches the platform's own baseline count exactly.
Patches regenerated ASCII/LF, test.sh still `100755`, no banned comments or markers.

Long-horizon floor after R15: 7 files, 306 human-effective LOC, 513 raw, solver median 113 messages
- clears the 2 files / 250 effective / 40 messages sprint minimums. The `effective_loc_check.py`
warning still cites the superseded 430 figure.

## R16 - Auto Review revision (3 reviews, all "Revision Requested")

Difficulty is now settled: **4 of 10 passed = 40%**, at the cap, and all three reviews independently
called it healthy. Review 3: "the low full-pass rate reflects healthy difficulty rather than
unfairness"; no leakage, no test manipulation, no upstream-shipped fix, no overlap signal. The R15
hardening did its job (67% -> 40%), so nothing in this round touches difficulty.

The three recurring agent misses are all fair consequences of stated contract, and all three are
already pinned by the suite, so they stay exactly as they are: path-over-type precedence in either
registration order and across reset (3 runs), deriving submodule ownership from internal fragment
drivers instead of signature flow so clock-connected outputs are missed (2 runs), and rejecting a
constant-connected input instead of delivering its initial sample (1 run).

Four findings fixed:

**T3/T4 High - `test_replaced_submodule_memory_does_not_update` proved nothing** (flagged by all
three reviews). It asserted only `ctx.get(dut.sub.out) == 0xee`, which is the model's own constant,
so an implementation that suppressed ordinary statements but left the nested memory write process
running would still pass. `Store.elaborate` now stashes its `memory.Memory`, `StoreWrapper` gained a
second identical but unmodeled `Store`, and the test asserts both halves: the modeled submodule's
row stays `0x00` while the unmodeled sibling's row holds `0x77`. The sibling is what stops the
assertion being vacuous - it proves the write machinery genuinely works and that suppression is what
silenced it.

**T4 - model self-observation was untested, and the description was overclaiming.** Reviews 1 and 2
both asked for a model that calls `ctx.set` on an owned output and immediately reads it back with
`ctx.get`. I wrote that test and it FAILED against my own reference: it returned 10, not 15.
Models write `next` and read `curr` like every other design process, so immediate read-back is not
what the engine does, and implementing it would give models semantics no other amaranth process has.
The description was the defect - "visible ... to itself in the same delta cycle" reads as promising
read-back, which is why two reviewers asked for it. Reworded to the guarantee that actually holds
and is HDL-correct: a model waiting on its own output runs again in that same delta cycle until
values settle. New `test_model_observes_its_own_drive_in_same_delta` pins it, asserting the model
sees `[0, 1, 2, 3]` and the design settles at 3. Review 3 had already dropped this finding.

**S2 - registration was not transactional** (reviews 1 and 2). `ModelBindings.add_*` recorded the
binding before `_check_no_replaced_instance_models()`, and `_rebuild_models()` could raise a
clock conflict after the binding was committed, with no rollback. Added `snapshot()`/`restore()` to
`ModelBindings` and wrapped both engine entry points in `_add_model`, which restores the bindings and
`_model_driven` and rebuilds on any exception. `test_rejected_model_leaves_the_simulation_unchanged`
proves it, and I verified it discriminates: with the rollback removed, the stale PLL binding
resurfaces on the next rebuild and makes a subsequent *valid* ADDER registration fail with the PLL's
clock conflict - exactly the "retained failed bindings cause surprising later behavior" the reviewer
described. Meta gained one clause: "An addition that raises leaves the simulation unchanged."

**P4 - clunky suppression sentence** (all three reviews). "and that submodule's logic, and everything
below it, then goes unevaluated" became "The submodule's own logic and all logic below it are then
left unevaluated."

Solution band moved 2/3 -> 3/3 Clean between reviews 1 and 3 with no artifact change, so the bands
carry some run-to-run noise; I fixed S2 anyway because two of three reviews verified it.

Validation after R16: 101 tests, 101/101 pass with the solution, 101/101 fail on base, identical
across 3 runs. Full suite 1247 = 1146 baseline + 101 new, with the same 20 Yosys-missing errors that
the Dockerfile's oss-cad-suite resolves. 7 files, 323 human-effective / 535 raw LOC. meta 373 words,
ASCII, no smart punctuation. Patches ASCII/LF, test.sh `100755`, no banned comments or markers.

## R17 - second hardening pass (40% was at the cap, pushing for the low edge)

40% is approvable but it is the ceiling, and difficulty drives payout, so this round pushes toward
the 10-20% edge. Seven tests added (101 -> 108). Solution untouched: every one of these behaviors
was probed against the reference first and already held, so this pass costs zero regression risk and
discriminates on architecture quality rather than adding grind. That is also the argument against
overshooting to 0%: a correct design gets all seven for free, which is exactly why the reference
needed no change to satisfy them.

The lead trap re-uses the measured blind spot instead of inventing a new one. Two of ten runs
derived submodule ownership from internal fragment drivers rather than signature flow, and the suite
only tested the direction where that architecture omits a clock-connected output. The complement was
untested: **can a submodule model drive an internal signal the replaced logic drove?** Probed the
reference - refused, because ownership is exactly the outward signature members. An internal-driver
implementation ALLOWS it. So the two directions now pin the architecture from both sides, and the
naive fix for one breaks the other: widening ownership to internal drivers passes the omission case
and fails the internal-drive case, narrowing it does the reverse. Only signature-flow ownership
passes both.

The rest, each probed as already-holding before being written:

- `test_model_tick_follows_a_clock_driven_by_another_model` - model A drives domain `gen`'s clock,
  model B awaits `ctx.tick("gen")`. Composition of two separately stated features that nobody
  exercises by accident; a broken trigger path leaves B silently never firing.
- `test_delayed_model_alone_does_not_keep_run_advancing` and
  `test_delayed_model_fires_while_a_testbench_runs` - the two halves of background scheduling for a
  time-consuming model. Passing one and failing the other is the likely outcome for a naive
  background flag.
- `test_model_wait_in_progress_is_discarded_by_reset` - a delay armed before `reset()` must not fire
  afterwards; the constructor restarts instead. Verified the log is
  `["start", "start", "late"]`, not a stale early fire.
- `test_model_waiting_only_on_a_constant_input_wakes_once` - complement of the blind spot that killed
  one run; the constant fires its initial sample exactly once and never again.
- `test_exception_in_a_model_propagates_out_of_run`.

meta gained one generic clause rather than seven enumerated ones: a model "may also wait for time to
pass or for a clock edge, as any process can; a wait still in progress is discarded by `reset()`, and
an exception raised in a model propagates out of `run()`", plus "or a constant" in the existing
input-waiting sentence. 413 words, still under the 500 cap.

Validation: 108 tests, 108/108 pass with the solution, 108/108 fail on base, identical across 3 runs.
Full suite 1254 = 1146 baseline + 108 new, same 20 Yosys-missing errors. solution.patch unchanged at
323 human-effective / 535 raw across 7 files.

Whether this actually lands at 10-20% is unknown until a batch runs - the batch is the only
difficulty oracle, and my prediction is not evidence. If it overshoots to 0%, the first thing to
relax is the tick-follows-model-driven-clock composition, since it is the only one requiring two
model-specific mechanisms to be correct simultaneously.

## R18 - Auto Review round 2 (Description now 3/3, Solution Quality PASS)

Good movement: **Problem Description reached 3/3 Clean** in both reviews (the R16 P4 rewrite worked),
and the separate **Solution Quality check returned PASS** with 3/3 Comprehensiveness. Two blockers
left, and both reviews plus both advisory Coverage Suggestions named the same two.

**T4 High - atomic rollback coverage was incomplete.** `test_rejected_model_leaves_the_simulation_unchanged`
used a single-target type selector and never reset after the rejection, so it could not catch partial
registration across several type-matched targets, nor a rejected binding retained only in restart
bookkeeping. Added both cases:

- `test_failed_multi_target_addition_attaches_no_models` - new `TwoGens` fixture with two instances of
  type `GEN`, one driving a plain signal and one driving a clocked domain's `ClockSignal`, plus an
  `ADDER`. The `GEN` addition fails on the clock conflict and neither `GEN` may end up attached.
- `test_rejected_addition_is_not_restored_by_reset` - after the rejection, add a valid model, run,
  `reset()`, run again, and confirm the rejected constructor never starts.

**The first version of the multi-target test did not discriminate** - it passed with the rollback
removed. Same trap as R16: `_rebuild_models()` raises in the clock-conflict scan before `self._models`
is reassigned, so no model process is ever built and "no model attached" is trivially true. Fixed by
adding the `ADDER` instance and registering a valid model after the rejection, which forces a later
rebuild where a retained binding resurfaces. Verified all three atomicity tests now fail with the
rollback removed and pass with it.

**S2/S4 - 14 unawaited-coroutine RuntimeWarnings.** First established this is **pre-existing repo
behavior, not something the feature introduced**: `AsyncProcess.reset()` builds the coroutine eagerly,
so vanilla amaranth emits the identical warning for `add_process()` without `run()` (probed on a clean
tree). Rather than contest a Low finding, took the reviewer's own first option - do not construct
until needed. Model processes now build their coroutine on first `run()` behind a `started` flag,
leaving non-model processes on the existing eager path so scheduling semantics stay identical.

That broke the four constructor-arity tests, because deferring the call also defers the `TypeError`
past registration, and the contract requires it at add time. Resolved by validating arity without
calling: `_check_model_arity` binds `inspect.signature(constructor)` against two placeholders next to
the existing async-function check. Variadic and defaulted constructors still pass, as their tests
confirm. The last two warnings came from tests that deliberately build a coroutine object to check it
is rejected - the test owns that object, so the tests now close it.

Result: **14 warnings -> 0 from this feature.** The single warning left in the whole 1256-test suite is
`test_sim.py::SimulatorIntegrationTestCase::test_add_testbench_wrong_coroutine`, a pre-existing repo
test.

Validation: 110 tests, 110/110 pass with the solution, 110/110 fail on base, identical across 3 runs.
Full suite 1256 = 1146 baseline + 110 new, same 20 Yosys-missing errors. 7 files, 337 human-effective
/ 550 raw. meta unchanged at 413 words.

## R19 - diagnosis: my own fairness fixes de-trapped the problem

Reported outcome: **all Nova runs solved it**, down from 4/10. That is a regression I caused, and the
cause is worth recording because it is structural, not accidental.

Each Auto Review round asked for more explicit wording, and I complied every time. Look at what the
meta gained across R16-R18, and what each clause cost:

| Clause added | Review that asked for it | Blind spot it killed |
|---|---|---|
| "a model waiting on its own output runs again in that same delta cycle until values settle" | T4 self-observation | "initial awakening for a model waiting on its own output" - a listed recurring miss |
| "or a constant" in the input-waiting sentence | run analysis | constant-connected input trigger - killed 1 run |
| "An addition that raises leaves the simulation unchanged" | S2 atomicity | rollback bookkeeping |

Every one of those was a genuine fairness fix and I would make the same call again on each in
isolation. But the aggregate turned the description into a complete implementation checklist, and
Problem Description going 2/3 -> **3/3 Clean** is the same event as the pass rate going 40% -> 100%.
A fully explicit contract is a transcribable one. This is the documented-traps-are-implementable-traps
law biting through the fairness ratchet.

The fix is NOT to delete documentation, which would just re-earn the fairness findings. It is to add
requirements where **stating the contract does not tell you how to implement it**.

## R19 hardening - two axes chosen for hidden fixes, not hidden contracts

Both probed against the reference first and already held, so no solution change and no regression
risk. 110 -> 115 tests.

**Axis A - `ctx.critical()` inside a model (3 tests).** amaranth already lets a process elevate itself
to critical for a bus transaction it must finish. Composed with models, the two halves pull against
each other:

- `test_model_in_a_critical_section_keeps_run_advancing` - a critical model's transaction completes;
  `run()` may not return first.
- `test_model_leaving_a_critical_section_stops_keeping_run_advancing` - after the `with` block a
  further delay is abandoned. Log is `["inside"]`, never `["inside", "outside"]`.
- `test_reset_restarts_a_model_inside_a_critical_section`.

Why this resists transcription: the obvious way to satisfy the long-standing "models alone never keep
`run()` advancing" rule is to drop models out of the critical accounting entirely, which passes the
existing test and fails the first new one. The obvious way to satisfy the new rule is to treat models
like testbenches, which passes the new one and fails the existing one. Only wiring models correctly
into the existing background/critical machinery satisfies both, and no amount of contract wording
reveals where that wiring lives.

**Axis B - shape-castable signature members (2 tests).** A `data.StructLayout` member must reach the
model as a `View`, not a bare `Value`:

- `test_submodule_handle_exposes_shape_castable_members` - `ctx.set(outputs["pkt"], {"kind": 2,
  "payload": 5})` yields 0x16.
- `test_submodule_model_drives_one_field_of_a_shape_castable_member` - drives `outputs["pkt"].payload`
  alone and leaves `kind` and a sibling member at 0.

Why it resists transcription: per-bit ownership internally needs `Value.cast` of every member, so the
natural implementation stores the cast value in the handle and silently loses the view. The same
object must be cast for ownership accounting and preserved as a view for exposure. The contract says
what the model sees; it does not say the two representations must be kept separately.

meta gained two clauses, 413 -> 450 words, still under the 500 cap.

**Worktree loss.** The amaranth clone under `worktrees/` was reaped mid-round (root device also
changed, `nvme0n1p5` -> `nvme1n1p5`). All five deliverables were intact, so I re-cloned at
BASE_COMMIT, re-applied both patches clean, and confirmed 110/110 before continuing. The patches are
the real artifact; the worktree is disposable.

Validation: 115 tests, 115/115 pass with the solution, 115/115 fail on base, identical across 3 runs.
Full suite 1261 = 1146 baseline + 115 new, same 20 Yosys-missing errors. Zero unawaited-coroutine
warnings from the feature. 7 files, 337 human-effective / 550 raw.

Batch 3 is owed and is the only thing that will say whether this recovers the band. If it lands back
near 40% rather than under it, the next move is another hidden-fix axis, not more wording - and the
wording must not be relaxed to buy difficulty back.

## R20 - 3/4 Nova (75%). Diagnosis: my hardening method was selecting for FREE behaviors

R19 barely moved the rate, and checking why exposed the flaw in the method I had been using since
R17. "Probe the reference, find behaviors it already exhibits, pin them with tests" sounds efficient,
but it selects for behaviors that come **free from riding the existing machinery** - and any agent
that also rides the machinery gets them free too. Two confirmations:

- `ctx.critical()` is implemented as `self._process.critical = True` on the shared `AsyncProcess`.
  Every implementation that reuses `AsyncProcess`, which is most of them, inherits it. My R19 Axis A
  could only ever kill agents who built a parallel execution path.
- The same holds for delays, tick, exception propagation, and most of R17.

So those rounds added coverage, not difficulty. The rule going forward: **a trap only discriminates
if a correct machinery-riding implementation still has to do deliberate extra work.** Probe for what
the reference gets WRONG or does not do, not for what it already does.

## R20 hardening - deterministic model evaluation order (a NON-free requirement)

Probing in that direction immediately found one. `PySimEngine._processes` is a **`set`**, and
`_rebuild_models()` merged models into it, so model evaluation order was whatever set iteration
produced. Across `PYTHONHASHSEED` values the start order came out `[u3, u0, u2, u1]`,
`[u0, u3, u2, u1]`, `[u2, u1, u0, u3]`.

This is the shape I needed:

- **Not free.** The obvious implementation - put models in the process set with every other process -
  produces arbitrary order. Verified: with models merged back into the set, the new test fails on
  4 of 4 seeds; with the ordered list it passes on 4 of 4. Deterministic discriminator, not a flaky one.
- **Not a drive-by.** `_testbenches` is already a separate ordered list in the same engine, so giving
  `_models` the same treatment mirrors existing structure. Models now live only in `self._models`,
  with `reset()`, the eval loop (`itertools.chain(self._models, self._processes)`), and the
  critical-accounting scan updated to include them.
- **Fair and already half-stated.** The description had said `instances()` and `submodules()` are
  "ordered from the top of the hierarchy down" since the first draft; the new clause extends that same
  order to when models run, rather than introducing a new concept.

Three tests: hierarchy order for a multi-target type selector, one shared order across instance and
submodule models, and order preserved across `reset()`. 115 -> 118.

Also worth recording: this was a latent **flakiness** defect in the submission, not only a difficulty
gap. Nothing in the suite depended on model order, so it never flaked, but a nondeterministic
evaluation order in a submission that must pass a mandatory flakiness gate was a live risk. I had not
been varying `PYTHONHASHSEED` in the 3x flakiness runs; now doing so.

meta 450 -> 460 words. Solution 337 -> 339 human-effective.

Validation: 118 tests, 118/118 pass, 118/118 fail on base, identical across 3 runs and across hash
seeds 0/1/2. Full suite 1264 = 1146 baseline + 118 new, same 20 Yosys-missing errors.

## Honest read on the ceiling

Three hardening rounds have moved this 40% -> 100% -> 75%. The core of the feature is "wire models
into `AsyncProcess`", and Nova does that reliably; edge cases around it keep being either free or
one-line fixes. Ordering is the first genuinely non-free requirement I have found, and there are only
so many of those left at this architecture.

If the next batch does not land under 40%, the remaining honest lever is scope, not more edge cases:
`io_` ports for instance models, which needs IO-net state that pysim does not have today. That is a
real architecture extension rather than another rule, it is squarely inside issue #392's ask, and it
would raise the LOC floor at the same time. It is also several hours of work with real risk. I would
rather propose it than keep adding tests that do not move the rate.

## R21 - second non-free trap: enumeration must reflect suppression

Applying R20's corrected method (probe for what the reference gets WRONG, not what it already does)
found a real inconsistency. `Simulator.instances()` called `collect_instances(self._design)`
directly, consulting no binding state at all, so after `top.u_sub` was replaced it still reported
`top.u_sub.u_deep` - an instance whose logic is suppressed and which can never be given a model,
since selecting it raises `DriverConflict`. The listing advertised a target that does not exist any
more.

Fixed by giving `ModelBindings` two views: `live_instances()` and `live_submodules()` drop what a
replaced submodule swallowed, keeping the replaced submodule itself, and the public API now routes
through the engine instead of re-walking the design.

**Why this discriminates, and why it is interdependent.** The selector still resolves against the
FULL hierarchy, so naming a swallowed target keeps reporting `DriverConflict` rather than
`NameError`. That asymmetry is the trap:

- filter the shared `_instances` list, the obvious one-line fix, and enumeration becomes right while
  the selector starts raising `NameError` - the asymmetry test fails;
- leave enumeration alone and the listing test fails;
- only keeping two distinct views of the hierarchy passes both.

It is also misdirecting: the failure surfaces as a wrong exception class, which reads like a selector
bug rather than an enumeration one.

Three tests: instances swallowed by a replaced submodule disappear, `submodules()` keeps the replaced
submodule but drops its contents, and selecting a swallowed instance by path or by type still
conflicts. 118 -> 121.

meta gained one clause tied to the sentence that already described listing order, 460 -> 486 words.
**That is 486 of the 500 hard cap** - any further requirement needs wording trimmed elsewhere first,
which is a real constraint on how much more can be added this way.

Validation: 121 tests, 121/121 pass, 121/121 fail on base, identical across 3 runs and hash seeds
0/1/2. Full suite 1267 = 1146 baseline + 121 new, same 20 Yosys-missing errors. 7 files,
**356 human-effective** / 578 raw, up from 339/552.

## Where this stands

Two non-free traps found in two rounds using the corrected method, and both also fixed genuine
defects in the reference (nondeterministic model order, enumeration ignoring suppression). That is
the healthy pattern: the hardening and the correctness work are the same work.

The word cap is now the binding constraint on adding further rules, and I still do not know whether
R20 and R21 moved the rate - both landed after the last batch. The next batch measures three rounds
at once (R19 critical/shape-castable, R20 ordering, R21 enumeration). If it still sits above 40%, I
would stop adding rules and take the `io_` ports scope extension instead, which needs IO-net state
pysim lacks: it raises effective LOC toward the 430 aspiration at the same time, and it is the axis
issue #392 actually asks for.

## R22 - FALSE POSITIVE closed: IOValue-connected instance ports

The FP panel flagged a passing run (adjudicator, high confidence, verdict changed by panel evidence -
judges 1 and 2 said genuine pass, judge 3 found the discriminator). The candidate eagerly computed
drive masks for every `Instance` output in `Simulator.__init__`, so `Value.cast()` raised `TypeError`
on any instance output connected to an `IOValue`. Plain `Simulator(design)` construction failed
before any model API was touched, and the prompt-required `Simulator.instances()` became unreachable
for such a design.

Per the FP rule this is a fault in the environment, not in that run: the hidden suite simply never
built a design with an IO-connected instance port, so the pass was undeserved and every other run is
suspect on the same axis. The construct is legal and repo-tested -
`Instance("t", i_i=io[0], o_o=io[1], io_io=io[2])` at `tests/test_hdl_ir.py:351`.

Probing the reference across all four surfaces found it partly right and partly undefined:

| surface | before |
|---|---|
| `Simulator(dut)` construction | OK |
| `instances()` lists the IO instance | OK |
| a model on a normal instance in the same design | OK |
| **a model on the IO-connected instance** | **raw `TypeError` from `Value.cast` internals** |

So the reference leaked an internal amaranth error for a case the description never covered. Rather
than hard-failing such instances, handles now omit ports connected to an `IOValue` and expose the
value-connected ones, which keeps a mixed instance modelable. Real IO-net simulation stays out of
scope, since pysim has no IO-net state.

Two tests close the gap, both verified load-bearing (removing the filter fails both):

- `test_simulator_accepts_an_instance_with_io_connected_ports` - the direct FP discriminator:
  constructs the simulator, enumerates both instances, and models the mixed one. A candidate that
  casts eagerly dies at `Simulator(dut)`, exactly where the flagged run died.
- `test_instance_handle_omits_io_connected_ports` - a mixed instance exposes `A`/`Y` and omits
  `o_PIN`; the all-IO instance gets empty mappings.

meta gained "Ports connected to an `IOValue` are left out of a handle." I was at 486 of the 500 cap,
so I trimmed the constructor sentence ("an async generator function, or anything that cannot be
called that way" -> "anything else", which the existing arity/async-generator/coroutine-object tests
still cover) to pay for it. Now 487.

Validation: 123 tests, 123/123 pass, 123/123 fail on base, identical across 3 runs and hash seeds
0/1/2. Full suite 1269 = 1146 baseline + 123 new. 7 files, **358 human-effective** / 580 raw.

Lesson recorded: the FP panel probes the BASE simulator surface, not only the new API. Every new
eager computation in a constructor is a regression risk against legal constructs the hidden suite
never builds - `IOValue` ports, zero-width signals, and memory rows are the obvious ones, and I
should sweep for those directly rather than wait for a panel to find them.

## R23 - coverage advisories closed (2), with a fairness trace

Both advisories were advisory-only, but per the standing rule a named coverage suggestion always gets
the test it names. 123 -> 127. Solution untouched.

**Advisory 1 - synchronous generator constructors.** The suite covered lambdas, coroutine objects and
async generator functions, but not the legacy `def model(...): yield ...` form. Probed first: both
APIs already raise `TypeError` for it, and no `DeprecationWarning` leaks from `_check_function` on
this path. Two tests, one per API.

**Advisory 2 - submodule-add rollback.** Rollback was exercised almost entirely through instance-model
additions. Added both submodule failure paths, which are genuinely different code:

- containment (`_check_no_replaced_instance_models`, which raises *after* `_submodules[path]` is set)
- clock conflict (`_rebuild_models`, which raises after the binding is committed)

The containment test has real teeth: if the stale binding survived, the holder subtree would be
suppressed and the `INV` instance model would silently stop running, so it asserts `z == 0xf0` as well
as the enumeration being unchanged.

**The clock-conflict test passed vacuously on the first attempt** - it survived with the rollback
removed. Same failure mode I have now hit four times: the conflict raises before `self._models` is
reassigned, so "no constructor started" is trivially true unless something forces a later rebuild.
Fixed with a new `ClockSourceAndAdder` fixture so a valid `ADDER` model can be registered after the
rejection. All four rollback tests now fail with the rollback removed and pass with it - verified
together, not one at a time.

**Fairness trace.** Every new assertion maps to an existing description sentence; no new wording was
needed, which matters at 487 of the 500 cap:

| assertion | description sentence |
|---|---|
| sync generator rejected, both APIs | "A constructor is an async function called with the simulator context and a handle; anything else raises `TypeError`." |
| containment rejection | "...for two models whose targets contain one another whichever is added first..." |
| clock rejection | "...and for a clock and a model driving the same signal." |
| listings and simulation unchanged after a rejection | "An addition that raises leaves the simulation unchanged." |
| rejected constructor never starts | "It runs once per target when the model is added, and again on reset." |
| `instances()` content after the rollback | "Replacing a submodule drops what it swallowed from both listings..." |

Validation: 127 tests, 127/127 pass, 127/127 fail on base, identical across 3 runs and hash seeds
0/1/2. Full suite 1273 = 1146 baseline + 127 new, same 20 Yosys-missing errors. Zero unawaited-coroutine
warnings, zero comments in added test lines. 7 files, 358 human-effective / 580 raw. meta unchanged at
487/500.

## R24 - 5/10 (50%). Non-drivable output bits: a two-sided trap found by the defect sweep

50% is progress from 75% but still over the 40% cap. Ran the FP-risk sweep promised in R22 (probe
legal constructs the hidden suite never builds) and it paid off twice: one real defect, and a trap
where both plausible fixes are wrong in opposite directions.

**Swept:** zero-width output port (fine), signed output driven with a negative value (fine, reads
back -3), and an output connected to a `Const` - which raised a **bare `AssertionError` with no
message**, straight out of `LHSMaskCollector`'s `assert False` for a non-assignable leaf. Not a base
regression, since lazy handle construction means a design like that still constructs and simulates
untouched; but attaching a model to such an instance leaked an internal amaranth assertion.

The first fix (skip non-assignable parts when computing ownership) stopped the assertion but made
`_check_driven` pass **vacuously** - an empty mask means no bit is foreign, so the write sailed
through to `eval_assign` and surfaced as a raw `ValueError: Value (const 8'd5) cannot be assigned`.
The real fix is bit-precise: `_assignable()` now returns the mask of bits of a value that are
drivable at all, and a write is refused unless every bit it touches is both drivable and owned.

**Why this is a good trap, not just a bug fix.** The two plausible implementations fail on opposite
sides, verified by patching each in and running both tests:

| implementation | const-only output | drivable slice of a mixed output |
|---|---|---|
| whole connection owned, no drivability check | fails | fails |
| any const-containing output treated as undrivable | passes | fails |
| bit-precise drivability | passes | passes |

So an agent that notices the const case and blanket-refuses those outputs still fails, because
`Cat(low, Const(0xa, 4))` must still accept a write to `outputs["Y"][0:4]`. Only tracking drivability
per bit satisfies both, and the failure is misdirecting in the first row: a wrong exception class
from deep inside `_pyeval`, not from the model API.

**Fairness: no new description wording.** Both tests fall out of the sentence already there -
"`DriverConflict` is raised for driving any bit the target does not drive". A constant is driven by
nothing, so its bits are not bits the target drives. That matters at 487 of the 500 cap, where any
new clause would have to be paid for by trimming another.

Two tests, 127 -> 129:

- `test_model_reads_but_cannot_drive_a_const_connected_output` - reads 5 through the handle, write
  refused.
- `test_model_drives_only_the_connected_part_of_a_mixed_output` - whole-value write refused, slice
  write lands, `low == 7`.

Solution 358 -> **382 human-effective** (613 raw), the largest single-round gain so far, because the
drivability walk is genuine distinct logic rather than another rule.

Validation: 129 tests, 129/129 pass, 129/129 fail on base, identical across 3 runs and hash seeds
0/1/2. Full suite 1275 = 1146 baseline + 129 new. Zero unawaited-coroutine warnings.

The sweep is worth repeating rather than treating as done: it has now produced the IOValue FP fix and
this one, both from the same question - what legal construct does the hidden suite never build?

## R25 - Solution Quality PASS 2/3+2/3: real ordering defect fixed, 2 advisories closed

The check passed (1146 baseline both ways, 129/129 new after, 129 failing before) but scored 2/3 on
both Comprehensiveness and Code Quality, and the reason was a genuine defect in my own reference,
not a nitpick.

**The defect: ordering was only per-kind.** `ModelBindings.resolve()` appended every resolved
instance model first and every submodule model second, so instance and submodule models were never
merged into one hierarchy sequence. The description says models "are started and evaluated in that
same order", meaning the single top-down order `instances()` and `submodules()` report. The reviewer
called it exactly right: my mixed-order test "happens to satisfy the tested mixed case" because its
fixture puts the instance first in the hierarchy anyway, so grouping by kind and ordering by
hierarchy give the same answer.

Fixed by indexing every target against one hierarchy walk - `self._order` maps each fragment to its
position in `design.fragments`, which both collectors already derive from - and sorting the resolved
list by it. New `SubmoduleFirst` fixture puts the component **before** the instance, and
`test_a_submodule_model_ahead_of_an_instance_model_runs_first` pins it. Verified discriminating:
without the sort the order comes out `['top.u_beta', 'top.u_alpha']` instead of
`['top.u_alpha', 'top.u_beta']`.

That is the third round running where a reviewer or panel found a real defect my own tests let
through, and all three were the same shape: a stated guarantee that only one of several plausible
implementations satisfies, with my fixture accidentally sitting on the easy side.

**Hygiene:** removed the dead `from ._instance import collect_instances, collect_components` in
`core.py`, dead since R21 routed enumeration through the engine, and dropped `Part` and `SwitchValue`
from `_instance.py`, unused since the R24 drivability walk stopped needing their branches. `pyflakes`
now reports no unused imports in any file this submission touches.

**Advisory 1 - structured member sampling.** `test_model_samples_a_shape_castable_member_as_a_whole`
reads a whole `data.StructLayout` member with `ctx.get` and asserts the structured form
(`sampled.kind == 2`, `sampled.payload == 5`), complementing the existing whole-value and
single-field drive tests. Probing first mattered here: `ctx.get` returns a `data.Const` carrying the
layout, but reading straight after `ctx.set` in the same activation yields the pre-commit value,
exactly the write-`next`/read-`curr` behavior established in R16, so the test samples on a later wake.

**Advisory 2 - rollback after selector errors.** `test_rejected_selector_errors_leave_the_simulation_unchanged`
drives both `ValueError` forms (no selector, both selectors) and three `NameError` forms (unknown
type, unknown instance path, unknown submodule path), then adds two valid models and runs them.

Being precise about what that test does and does not catch, since I checked rather than assumed: a
binding left behind by a `NameError` is inherently unobservable, because the selector matched nothing
by definition, so no implementation difference shows. The observable case is a `ValueError` raised
*after* a matching type was recorded - emulated that and the test fails with "Instances of type
'ADDER' already have a model attached to them", and passes once rollback restores the snapshot. So it
is a real guard against validate-after-mutate, not a discriminator against the rollback path itself.

**Fairness: no new wording, still 487/500.** Structured sampling traces to "a member with a
shape-castable type keeping that type" plus "A model may sample values with `ctx.get`". Selector
errors trace to "exactly one selector is required, otherwise `ValueError`", "A selector matching
nothing raises `NameError`", and "An addition that raises leaves the simulation unchanged".

129 -> 132 tests. Solution 382 -> **384 human-effective** (615 raw).

Validation: 132/132 pass, 132/132 fail on base, identical across 3 runs and hash seeds 0/1/2. Full
suite 1278 = 1146 baseline + 132 new, same 20 Yosys-missing errors.

## R26 - description-quality check: 2 of 5 applied, 3 declined with cause

The check returned request_changes on 5 suggestions (1 HIGH, 3 MEDIUM, 1 LOW), explicitly
"AI-generated suggestions, not hard rules", with only HIGH blocking. Three of the five would have
deleted documentation for behavior the suite asserts, which is the fairness failure that actually
sinks submissions, so each was checked against the tests rather than applied on sight.

**Applied - no test depends on either:**

- [MEDIUM] dropped the "A model is part of the design:" lead-in. Vague framing, and the following
  clause already states the concrete semantics. Had to repair the dangling pronoun: "what it drives"
  became "What a model drives".
- [LOW] dropped "as any process can;" - comparative filler; the requirement is that models may wait
  on time or a clock edge.

**Reframed rather than deleted - [HIGH] "Converting a design is unaffected by them."** The rationale
was that it is an obvious default adding no actionable guidance. It is not obvious: suppressing a
replaced submodule's subtree is the one place an implementation could plausibly mutate the design to
get the effect, and two tests pin it (`test_instance_model_does_not_change_conversion`,
`test_submodule_model_does_not_change_conversion`). Deleting the sentence would leave both asserting
undocumented behavior. Rewritten as a constraint on the implementation rather than a property of the
feature: **"Models never alter the design itself, so converting one is unaffected."** Same coverage,
one word shorter, and it now reads as guidance about what not to do.

**Declined - [MEDIUM] "and models are started and evaluated in that same order."** Four tests depend
on it. The stated rationale, that evaluation order is "implied by the stated ordering and scheduler",
is factually wrong for this engine: `PySimEngine._processes` is a `set`, so the natural implementation
produces arbitrary order, which is exactly why R20 added the clause and the ordered `_models` list.
Verified again in R25 - without the merge sort the order comes out `['top.u_beta', 'top.u_alpha']`.
Removing the clause would orphan four tests and delete a demonstrated non-free trap.

**Declined - [MEDIUM] "rooted at the top-level elaboratable, `top`".** 68 path arguments in the suite
are `top.`-rooted. This clause exists *because* an earlier Test-quality check warned that the tests
pin paths rooted at `top` without the description saying so (R1). The two automated checks contradict
each other here, and the fairness one wins: a root name that must be guessed is an undocumented
requirement.

Net: meta 487 -> **481 words**, six back under the 500 cap. Suite unchanged at 132/132; meta.md is a
standalone deliverable, so no patch regeneration was needed.

Worth noting for future rounds: description-trim checks and test-fairness checks pull in opposite
directions on this submission, and every trim now has to be checked against the assertion it
supports. The generic-clause style already adopted - one sentence covering several tested surfaces -
is what keeps both satisfiable.

## R27 - 0/9 UNSOLVABLE. Minimal relaxation of the one requirement every run missed

Batch 3 came back **0 of 9** (3 Orion, 6 Nova). That is reject-level: the rule is at least one agent
must pass, and difficulty above that floor is worthless if nothing clears it. Four hardening rounds
took this 50% -> 0%.

The diagnosis was unambiguous once the failures were ranked (full table in `eval-results.md`): the
**const / mixed-constant output requirement added in R24 is cited by 9 of 9 runs**. Run #2 passed
**131 of 132** with that as its only failure.

The evaluator still graded it fair - `was_mentioned_in_description: true`, "the underlying requirement
was already knowable from the prompt and visible collector semantics; this is not an undocumented
expectation". So this is the admin rule's "one genuinely hard step", not a hidden requirement. But 0%
is an automatic reject whether or not the step is fair, so it had to come down.

**Minimal cut, chosen to preserve every other trap.** Rather than delete the test - test function
names stay stable across revisions - I relaxed its body. It previously required bit-precise
drivability through `Cat(signal, Const)`: the whole-value write refused **and** a write to the owned
`[0:4]` slice still landing. It now requires only that the whole-value write is refused. The
implementation an agent actually wrote (treat any constant-containing output as wholly undrivable)
now passes, while an implementation that treats such an output as fully drivable still fails, so the
trap survives in its one-sided form.

Verified by emulating run #2's exact defect against the full suite: 132/132 pass. That converts run
#2 from FAIL to PASS on its own, so the expected landing is at least 1/9, in band and solvable.

**Second margin, no test removed.** Added one clause making the constant case explicit: "A port may
also be connected to a constant, which nothing drives." Runs 3, 8 and 9 failed by treating
constant-connected output bits as assignable, and that sentence addresses them directly without
weakening any assertion. meta 481 -> **493/500**.

**Deliberately kept:** the swallowed-instance-by-type requirement (6/9) and hierarchy ordering (5/9).
Both are explicitly documented, both are non-free traps proven to discriminate, and both are fair
difficulty rather than unfairness. If batch 4 is still 0%, swallowed-by-type is the next to relax,
since it is the larger cluster.

The reference solution keeps its bit-precise drivability - strictly more capable than the tests now
demand - so the R24 defect fix (a bare `AssertionError` leaking out of `LHSMaskCollector`) stays
fixed.

Validation: 132 tests, 132/132 pass, 132/132 fail on base, identical across 3 runs and hash seeds
0/1/2. Full suite 1278 = 1146 baseline + 132 new. 7 files, 384 human-effective / 615 raw.

**Lesson: I hardened four rounds deep without a batch in between.** R19, R20, R21, R22 and R24 all
landed on a single unmeasured artifact, so a 50% -> 0% overshoot was invisible until nine runs were
spent. Measure after every one or two hardening rounds, not after four.

## R28 - coverage advisories: 2 of 3 added, 1 declined on measured solvability evidence

**Declined - "Partial constant-connected outputs".** The suggestion is to add a positive test that
sets only the model-owned slice of a mixed `Cat(signal, Const)` output and checks the constant part is
unchanged. That is precisely the assertion R27 removed one round ago, and the removal was not a
style call: **9 of 9 runs in batch 3 failed on it and the batch scored 0%**, which is an automatic
reject. Run #2 passed 131 of 132 with that single assertion as its only failure, and emulating its
implementation against the relaxed suite gives 132/132.

The advisory is explicitly "advisory only - these don't affect the check result", while a 0% batch is
a hard gate, so the gate wins. Re-adding it would knowingly return the submission to unsolvable. The
reference still implements bit-precise drivability, so the capability exists and can be re-pinned the
moment a batch shows headroom; what is gone is the *requirement* that every solver reproduce it. If a
future batch lands well under 40% with margin, this is the first assertion to restore.

**Added - "Submodule exception propagation".** `test_exception_in_a_submodule_model_propagates_out_of_run`
mirrors the instance-model case, confirming the rule is model-kind independent. Probed first: it
already holds.

**Added - "Reset of non-delay waits".** `test_reset_discards_a_clock_edge_wait` and
`test_reset_discards_a_changed_wait` cover the two wait kinds the suite was missing; only `delay()`
was exercised before. Both use the existing `Register` fixture, which carries a sync domain and a DFF
instance. Verified load-bearing: dropping the `for model in self._models: model.reset()` loop from
`PySimEngine.reset()` fails both new tests plus `test_reset_restarts_models`.

**Fairness - no new wording, still 493/500.** Both additions trace to sentences already present, and
both are generic in exactly the way the advisory assumes:

| assertion | description sentence |
|---|---|
| submodule model exception propagates | "an exception raised in a model propagates out of `run()`" - "a model", not an instance model |
| clock-edge and `changed()` waits discarded by reset | "a wait still in progress is discarded by `reset()`" - "a wait", not a delay |

132 -> 135 tests. Solution unchanged at 384 human-effective / 615 raw.

Validation: 135/135 pass, 135/135 fail on base, identical across 3 runs and hash seeds 0/1/2. Full
suite 1281 = 1146 baseline + 135 new. Zero unawaited-coroutine warnings.

Batch 4 is the next thing owed, and nothing further should change before it runs - R27 and R28 are
both unmeasured, and the last time four rounds stacked up without a batch the result was a 0%.

## Open items before submit

- Re-run Environment Quality with the new Dockerfile to confirm the fix.
- Run batch 2 and confirm the rate is at or under 40%. If it is still over, the next lever is
  another composition of the same two demonstrated blind spots, not a new mechanism - the
  architecture itself is not what Nova finds hard here.
- Save every passing agent diff to `agent-runs/` this time. Batch 1 closed without them, so the
  R15 kill analysis is inferred from evaluator narratives rather than measured against real patches.
- Re-run the Gate 7b exclusivity search and the maintainer-philosophy scan immediately before
  submitting; issue #392 is six years old but the simulator is the area whitequark said would be
  revisited.
- FP check after the batch: confirm every passing agent actually met the contract rather than
  passing the tests.
