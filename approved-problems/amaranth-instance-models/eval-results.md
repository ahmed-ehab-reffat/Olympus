# eval-results — amaranth-instance-models

Repo `amaranth-lang/amaranth`, base `fe524a11936222b2dd08751c68c66ef4b6d0bd22`.

## Local validation matrix

All cells run from pristine `git archive` extracts of the base commit, with the patches applied
by `git apply`, using Python 3.12 with `pyvcd`, `jschon`, `jinja2` and `pytest` installed.

| Cell | Tree | Mode | Result |
|------|------|------|--------|
| A | base + test.patch | new | **92 failed / 0 passed** (F2P: every new test fails on base) |
| B1 | base + test.patch + solution.patch | new | 92 passed |
| B1 | base + test.patch + solution.patch | base | **1146 passed, 0 failed, no exclusions** |
| B2 | base + solution.patch + test.patch | new | 92 passed (both apply orders clean) |
| base tree | base + test.patch | base | **1146 passed, 0 failed** (the Environment Quality condition) |

Flakiness gate (mandatory): `new` 3x and `base` 3x on cell B1, identical every run
(92 passed x3; 1146 passed x3). No timing, network, ordering or RNG dependence:
the pysim engine is deterministic and every test drives the simulation explicitly.

No test-suite exclusions: the image provisions the toolchain the repo's own tests need, so `base`
mode runs everything, including the formal-verification and example tests.

## Size

`python .claude/hooks/effective_loc_check.py solution.patch`:

- files: 7
- raw added: 505
- human-effective: **~305**
- padding-floor: 244

Per file: `_instance.py` 161, `_async.py` 57, `pysim.py` 51, `core.py` 20 (the rest is docstrings,
which count as zero), `_pyrtl.py` 6, `_base.py` 4, `__init__.py` 2.

## AI pre-check round 1 (2026-07-27)

- **Problem and tests are good quality: WARNING.** Only flag: the tests pin paths starting at the
  root name `top`, which the description did not define. Fixed by naming the convention in the
  description ("one dotted hierarchy path that starts at the top-level elaboratable, which is named
  `top`"). Named coverage gaps closed by adding two tests: a non-async submodule model raising
  `TypeError`, and a submodule model being restarted by `reset()` (53 -> 54 tests). The third named
  gap, `io_` ports, was resolved the other way: the sentence was dropped from the description (see
  below), so nothing untested is claimed.
- **Problem description contains only necessary information: request_changes (2 HIGH).** Both HIGH
  items were current-behavior narration and were removed: the opening sentence describing what an
  unmodeled `Instance` does today, and the closing "anything left unmodeled keeps behaving exactly
  as it does now". The unmodeled-instance test still traces to the description through the
  selection rules, with the value 0 left as the single codebase-inferable requirement. The MEDIUM
  (`io_` ports) and both LOW suggestions were applied as well.
- Full matrix re-run after the edits: F2P 54/54, new 54/54, base 1126, 3x deterministic, all inside
  the image offline as uid 1000.

## Environment Quality (platform, R2): FAIL -> fixed

The gate runs the repo's own suite and requires it clean; `test.sh` exclusions do not apply. It
failed on a missing `sby` and on example subprocesses that could not import `amaranth`. Both were
Dockerfile gaps: the image now installs the official oss-cad-suite (yosys/sby/yices) and the
package itself (`PDM_BUILD_SCM_VERSION`, since amaranth's version comes from SCM). Whole suite with
NO exclusions: **1146 passed / 0 failed in 21s** offline as uid 1000, on the base tree and on the
patched tree alike.

A substitute toolchain (wasm yowasp-yosys + sby from git + standalone yices) ran but left 8 formal
failures in 201s; the official prebuilt suite passes the same tests in 6.3s. Do not judge a repo
env-dead on a substitute toolchain.

## Test Fairness (platform, R3): FAIL 3/59 -> fixed

Two tests pinned the reverse order of a containment conflict the description only stated one way;
fixed by making the description's rule explicitly order-independent (the implementation already
was). One test asserted a raw VCD token; it now parses the dump and decodes the value changes for
the signal's identifier. Suite 58 -> 61 with two of the three advisory suggestions added. R4: fairness clean, both
remaining advisory items taken, suite 61 -> 64. R5: mixed-depth ordering added (65); the
submodule clock-conflict and add-time-lifecycle suggestions declined with reasons in feedback.md.
R6: plain-Elaboratable filtering, sibling submodule order and partial output connections added (67).
R7: declaration-order enumeration (with a matching description clause) and nonzero-init observation
added (69); the submodule clock-conflict suggestion declined again, reason in feedback.md.
R8: fairness FAIL 3/69 on sibling ordering -> claim removed from both description and tests;
lifecycle-boundary advisory added (71). R9: submodule clock conflict (both orders, plus a model
driving a clock domain), post-reset addition and submodule selector checks added (78); one
cosmetic solution message fix, full matrix re-run. R10: description-quality (4 HIGH, delete the
contract) vs alignment (add precision) conflict; contract kept and tightened, both alignment
clarifications taken, tests and solution untouched. R11: constructor arity variants and
path-override-across-reset added (82); probing showed variadic/defaulted constructors are accepted,
so the R10 "exactly two parameters" wording was corrected. R12: submodule signature parity and
partial path overrides (85). R13: fairness FAIL 6/85 on enumeration container type -> all
enumeration assertions normalized through list(); submodule arity symmetry added (86).
R14: hardening pass, four composition walls (suppress-not-override, simulation-only/conversion
immutability, feedback settling, machinery-riding) added test-only (92); solution unchanged.

## Agent runs

### Batch 1 (Nova solver / Nova eval, 6 runs) - 4 PASS / 2 FAIL = 67% - TOO EASY

Cap is 40%. Over by a wide margin, so the batch is a reject-and-harden signal, not a datapoint to
keep. Every run graded `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`, `blocker_detected: false`; both failures were graded
FAIL_MISSED_REQUIREMENT with `agent_blame_unfair: false`. So the artifact is fair and the
environment is clean; it is simply transcribable.

| Run | Verdict | Msgs | Files | LOC | Failed tests | Approach note |
|-----|---------|------|-------|-----|--------------|---------------|
| 1 | PASS_LEGITIMATE | 104 | 9 | 633 | - | full impl across api/context/engine/hierarchy/conflicts |
| 2 | PASS_LEGITIMATE | 156 | 9 | 595 | - | same, plus eval/assign machinery changes |
| 3 | FAIL_MISSED_REQUIREMENT | 80 | 6 | 461 | partial-output connections (1/92) | computed `_output_masks` then ignored them; `if signal in self._model_drivers` |
| 4 | PASS_LEGITIMATE | 113 | 8 | 633 | - | full impl incl. fragment exclusion + engine rebuild |
| 5 | PASS_LEGITIMATE | 113 | 8 | 562 | - | full impl; subtree process suppression |
| 6 | FAIL_MISSED_REQUIREMENT | 120 | 8 | 498 | path-over-type precedence x3 (89/92) | precedence resolved at add time, so type-then-path raised DriverConflict |

Agent patches were NOT saved before the run view closed. Do this next batch - the differential
harness and trap-proof both need them, and without them the kill analysis below is inferred from
the evaluator narratives rather than measured.

### Batch 2 (post-R15 hardening, 10 runs) - 4 PASS / 10 = 40%

Reported through Auto Review rather than a raw run dump. At the cap and graded healthy by all three
reviews: "4 of 10 independent implementations passed completely, while the others reached 94-98 of
99 tests and failed in narrow requirement-related areas... these failures are subtle but follow from
the stated contract, so the low full-pass rate reflects healthy difficulty rather than unfairness."
Passing solutions were 465-625 added lines across 7-9 files. No leakage, hardcoding, test
manipulation, upstream-shipped fix, or overlap signal reported.

R15 hardening moved the rate 67% -> 40%. The three recurring misses, all already pinned by the suite:

| Miss | Runs | Grade |
|------|------|-------|
| path-over-type precedence in one registration order only, or treated as conflict | 3 | shared blind spot |
| submodule ownership derived from internal fragment drivers, so clock-connected signature outputs missed | 2 | subtle but fair |
| constant-connected input rejected as a trigger, losing its initial sample | 1 | subtle but fair |

### Batch 3 (post R19-R26, 9 runs: 3 Orion + 6 Nova) - 0 PASS / 9 = 0% - UNSOLVABLE, REJECT-LEVEL

Overshot. 50% -> 0% across four hardening rounds. Every run graded FAIL_MISSED_REQUIREMENT, baseline
1146/1146 green in all nine, implementations were substantial (450-1012 LOC, 91-160 msgs), and the
near-misses were very near: 131/132, 129/132, 128/132.

| Run | Solver | Failed | Msgs | LOC | Dominant cause |
|-----|--------|--------|------|-----|----------------|
| 1 | Orion | 9/132 | 160 | 863 | const bits, swallowed-by-type, clock/submodule, shape-castable |
| 2 | Orion | **1/132** | 150 | 1012 | **mixed const/signal output only** |
| 3 | Orion | 4/132 | 157 | 1005 | const bits, swallowed-by-type |
| 4 | Nova | 11/132 | 149 | 758 | ownership from internal drivers |
| 5 | Nova | 4/132 | 91 | 612 | const bits, swallowed-by-type |
| 6 | Nova | 3/132 | 155 | 636 | top-level listed, order, clock |
| 7 | Nova | 10/132 | 135 | 716 | binding + per-bit semantics |
| 8 | Nova | 6/132 | 95 | 450 | path-over-type, const bits |
| 9 | Nova | 9/132 | 109 | 539 | path-over-type, const bits |

Failure themes ranked by how many runs cite them:

| runs | theme | added in |
|---|---|---|
| **9/9** | **const / mixed-constant output bits** | **R24** |
| 6/9 | swallowed instance selected by type | R21 |
| 5/9 | hierarchy / evaluation order | R20, R25 |
| 3/9 | clock vs submodule output | earlier |
| 3/9 | path-over-type override | earlier |
| 2/9 | shape-castable member | R19 |
| 1/9 | top-level listed as submodule | earlier |

The 9/9 is the textbook unfairness signal from the admin rule - all agents failing for the same exact
reason. Notably the evaluator still graded it FAIR (`was_mentioned_in_description: true`, "not an
undocumented expectation"), so this is the "one genuinely hard step" case rather than a hidden
requirement. 0% is a reject regardless of fairness, so it had to come down.

### Diagnosis

Both failures are *fine print inside an already-stated rule*, not a missing capability. Nova builds
the whole architecture (hierarchy walk, handles, delta-cycle participation, suppression, reset)
without trouble in 80-156 messages; only composition of the stated rules trips it. That matches the
"documented-spec implementation is transcribable" law - the meta enumerates each rule, so each rule
gets implemented locally and correctly, and the only survivors are cases where two rules interact.

Both live blind spots are worth multiplying, because each already killed a run on its own:

- **Per-bit ownership** (killed run 3). Only one direction is currently tested: disjoint slices must
  coexist. The complement - a model driving bits of a signal it only partly owns must raise - is
  untested, and the reference itself gets it wrong (see below). Testing both directions is
  interdependent: signal-granular logic fails the first, no-check logic fails the second.
- **Order-independent resolution** (killed run 6). Precedence must be resolved at `resolve()` time,
  not at add time. Composing it with containment and with reset multiplies the same blind spot.

### Reference defect found while diagnosing

`_Model._driven` is a `SignalSet` built from `_rhs_signals()`, so `_check_driven` is signal-granular
and permits a model to drive bits of a connected signal that belong to a *sibling* target. Probed
directly: LOW connected to `packed[0:4]` successfully wrote `packed[4:8]` (HIGH's bits). The meta
says "driving anything the target does not drive raises DriverConflict", so the reference is looser
than its own contract. Fixed in R15 by switching to `LHSMaskCollector` masks.

### Rejected hardening candidates (engine invariants, not fair game)

- **Signal driven half by a model and half by design comb logic.** `is_comb` is a per-slot flag in
  `_PySignalState`, and `_pyeval._eval_assign_inner` refuses any write to a comb-driven slot. Making
  it bit-granular is a base-engine redesign well outside this feature.
- **Oscillating model loop must be detected.** `step_design()` has no iteration limit; a comb
  oscillation hangs in vanilla amaranth too. Requiring detection would invent new engine behavior.
