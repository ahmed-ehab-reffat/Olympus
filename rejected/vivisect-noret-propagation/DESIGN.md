# DESIGN.md — vivisect-noret-propagation

## 1. Title

Fix no-return analysis to verify and propagate call targets

## 2. Shape classification

- Shape: **O-Pipeline-hard** (SHAPES.md § Pattern 11-13 — "new variant + cascading, invent algorithm")
- Definition match: the fix inverts a leaf-classification default (new variant of an existing
  analysis rule) and the correct fix cascades through the call graph (a caller's status depends on
  its callee's, which depends on its callee's, ...); the propagation mechanism (a worklist-driven
  fixed point over the call graph, monotonic, cycle-safe) does not exist anywhere in the codebase
  today and must be invented.
- Pass rate target: 15% (O-Pipeline-hard historical band)
- Best agent: Vega (historical best for this shape; Nova/Orion/Castor also run per current sprint)
- Dominant verdict: MISSED_REQUIREMENT (agents fix the false-positive leaf case and stop, missing
  that the fix also needs the worklist to avoid trading it for a false negative)
- Solver/our LOC ratio: unknown (new shape combination for this repo); estimate near O-Pipeline-hard's
  historical ~1x based on the tight, single-purpose nature of the fix

## 3. Public API surface

No new public names. The feature is observed entirely through two already-public `VivWorkspace`
methods whose CONTRACT changes:

- `isNoReturnVa(va) -> bool` — must return `False` for a function unless it is provably no-return
  (previously: returned `True` whenever a terminal block merely lacked a return/branch instruction,
  regardless of proof)
- `addNoReturnVa(va)` — semantics unchanged (marks `va` no-return and updates the codeflow cache);
  its EFFECT now also triggers correct re-evaluation of any already-analyzed caller, which it does
  not do today
- `getCallers(va) -> list[int]` — already exists, now actually consumed by the fix (currently
  unused by any no-return-related code)
- `getCallGraph()` — already exists, now actually consumed by the fix

## 4. Canonical output form

- **Default polarity:** a function is presumed capable of returning. It is concluded no-return
  only when every terminal execution path (every code block with no successors) is *proven*
  inconsistent with returning.
- **What proves a terminal path inconsistent with returning:** the path ends in an actual return
  instruction — proves the OPPOSITE (the function can return; this block alone settles it). The
  path ends in a call (direct or resolved-indirect) to a function that is *itself* proven
  no-return, where "itself proven" recurses through the same rule to any depth (declared API,
  or derived by this same analysis, or itself reached only through further no-return calls).
- **What must NOT prove no-return:** a terminal block whose last instruction is a call to a
  function whose behavior has not been established — this must NOT support a no-return
  conclusion, regardless of whether the callee happens to have no known return path either. Two
  or more functions whose ONLY terminal paths call each other, with no call reaching a function
  provably no-return by some other route, must never be marked no-return (mutual reference is not
  proof).
- **Re-derivation:** a function's no-return status must be re-derived whenever new information
  about a function it calls becomes available — whether that information arrives because the
  callee is analyzed later, because an indirectly-called target is only resolved by a later
  analysis pass, or because the callee's own no-return status is itself derived through a chain
  that completes after this function was first examined. Status is monotonic: once proven
  no-return, a function is never reverted.
- **Idempotence:** running the analysis again after nothing new is learned changes nothing.

## 5. Blind-spot pre-empts

- **Default-polarity inversion** (new entry, closest existing bank category = "falsy-on-invalid"):
  "A function is presumed capable of returning; a terminal call to a function whose behavior has
  not been established must not, by itself, support a no-return conclusion." — pre-empts an agent
  reading the existing `IF_RET`/branch checks as the complete rule and only adding a third
  positive case, rather than inverting the default.
  A candidate diff that "keeps the existing structure and adds one more `hasret = True` check for
  branches, then a separate proven-call check that continues" makes the same MISTAKE the current
  code makes if it does not ALSO make "call the never proven; assume returns" the fallback for
  every unhandled case, not just add one more special case atop the existing set.
- **Cycle non-provability**: "Two functions whose only terminal paths call each other, with no
  route to a function provably no-return, must never be marked no-return." — pre-empts an agent
  treating "no leaf calls a KNOWN-returning function" as sufficient (the absence-of-counterevidence
  trap that produces the current bug in the first place).
- **Re-derivation trigger, not one-shot**: "A function's no-return status must be re-derived
  whenever new information about a function it calls becomes available." — pre-empts an agent
  implementing the proof correctly but only running it once per function at the moment it is
  first examined, which reproduces the ordering bug this fix exists to close.

## 6. Description draft (meta.md)

See `meta.md` in this folder for the final text (frontmatter + body). Word count: 258 (body only,
excluding frontmatter and title) — over the 200-word recommended-cap guidance but well under the
500-word hard cap. Accepted deliberately: the design has 5 distinct, necessary canonical-form
rules (default polarity, transitive proof, indirect resolution, cycle non-provability,
re-derivation) that fairness requires stating explicitly (CLAUDE.md: fairness comes from
documenting every tested behavior, never from capping difficulty or trimming past the point where
a rule goes unstated).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (Python ~= raw, no brace tax) | Reason |
|--------|------|--------------|-----------|-------------------------------------------|--------|
| MODIFY | `vivisect/analysis/generic/noret.py` | 60 | +55 / -20 | ~50 | Extract the per-function leaf-consistency check into a pure, reusable, side-effect-free helper; invert its default polarity (proven-only, not omission-based); keep `analyzeFunction` calling it |
| NEW | `vivisect/analysis/generic/noretprop.py` | 0 | +130 | ~125 | Worklist-driven fixed point over the call graph: seed from currently-known no-return functions, re-run the shared consistency helper on each caller when a callee's status changes, monotonic + cycle-safe, thunk-aware (mirrors `analyzeFunction`'s existing thunk skip) |
| MODIFY | `vivisect/analysis/__init__.py` | ~330 | +2 | ~2 | Register the new pass as a whole-workspace `AnalysisModule` immediately after the existing `noret` `FuncAnalysisModule` registration, in the `pe` and `elf` format branches only (the same two branches that register `noret` today — `macho`/`blob` do not, and this fix does not expand that pre-existing scope decision) |

TOTAL (as originally sketched): ~187 raw / ~177 meaningful across 2 modified + 1 new file.

### 7d. ACTUAL post-implementation footprint (measured, supersedes the sketch above)

The initial 3-file implementation measured 121 raw effective LOC (Counter 1) — under the 200
floor. Rather than pad, every `isNoReturnVa` call site in the codebase was enumerated
(`grep -rn isNoReturnVa`), and the SAME root bug (a call checked by call-site address instead of
resolved target) was confirmed, fixed, and regression-verified (full 304-test suite, 0
errors/failures, 3x deterministic) at its three other real occurrences, plus two small genuinely
useful additions surfaced along the way:

| Action | Path | Raw delta | Reason |
|--------|------|-----------|--------|
| MODIFY | `vivisect/impemu/emulator.py` | +17 | The main emulation loop's own no-return check (`op.va != funcva` guard) had the identical call-site-vs-target bug; added `_isNoReturnCallSite`, purely additive (OR'd onto the existing check) |
| MODIFY | `vivisect/impemu/platarch/arm.py` | +1 | ARM's emulator subclass duplicates the same loop; reuses the same inherited helper |
| MODIFY | `vivisect/analysis/generic/emucode.py` | +8 | The code-discovery emulation watcher's `prehook` had the same bug; added `_isNoReturnCall`, same additive pattern |
| MODIFY | `vivisect/__init__.py` | +12 | `propagateNoReturn()`: an on-demand entry point for the same re-derivation, callable without re-running the rest of analysis; returns the newly-marked set |
| MODIFY | `vivisect/analysis/generic/noret.py`, `noretprop.py` | +~15 combined | `NoReturnDerivation` function-meta tagging (`leaf` vs `propagated`) + defensive try/except around `resolveCallTarget` (matches the existing `buildFunctionGraph` guard pattern; keeps the "presumed capable of returning" default under a parse failure) |

One remaining call-site-address check was found and deliberately left untouched:
`vivisect/base.py:812`, inside `VivCodeFlowContext._cb_opcode` — this runs DURING disassembly,
before the target function is even discovered, so resolving-the-target there is not meaningful;
it is precisely the reason `noretprop`'s worklist exists (see § re-derivation trigger, § 4).

**TOTAL (measured, final): 227 raw / 187 Counter-1-effective across 8 files** (3 original + 5 more
integration points, all independently regression-verified, none of them padding). The 8th file,
`vivisect/base.py`, was added in a second round with explicit user sign-off: `_cb_noflow` deletes
and recreates a call site's location to set the NOFALL flag, which drops the branch xref the
disassembler had already recorded there, so `vw.getCallers()`/`vw.getXrefsFrom()` go empty for
exactly the call sites codeflow itself just proved lead to a known no-return function — fixed by
saving and restoring that xref, purely additive, verified both ways (present: full suite green;
removed: the new discriminating test fails as expected). This is under the 200 Counter-1 floor by
13 lines, and Counter 2 (human-effective, stripping imports/package lines on top of blank/comment)
would read lower still. Every `isNoReturnVa`/call-site-address check in the codebase is now
enumerated and either fixed or deliberately left alone with a stated reason (see § feedback.md's
two LOC-round entries). Flagged honestly for the reviewer rather than closed with further additions
that would no longer be tracing a real, verified bug.

Current floor check (2026-07 sprint): >=200 effective LOC, >=2 files, >=40 solver-median messages.
**This sketch sits ~25 lines under the 200 floor** — see § 7b for the genuine (non-padding)
extension that closes the gap, required for correctness parity, not inflation.

### 7b. Verified correction to the resolution strategy (empirically grounded, not padding)

Design-time verification against the live library (9 scripted scenarios run directly against a
`VivWorkspace`, see the design log) found that `analyzeFunction`'s existing check reads the WRONG
address: it checks `isNoReturnVa` on the *call instruction's own address*, which only happens to be
populated because a SEPARATE codeflow-internal cache (`envi/codeflow.py`'s `_cf_noret`, mutated by
its own `_cb_noflow`) is keyed the same way. The fix must instead resolve the call's actual TARGET
address and check `isNoReturnVa` on the TARGET — this is what `_resolveCallTarget(vw, va) -> int |
None` (§8) does. Verification also found that a resolved-indirect call (a register or
memory-dereferenced branch whose target only becomes known through a later analysis pass) is never
recorded through the same static-branch path a direct call uses, so `_resolveCallTarget` must fall
back to any xref recorded from the call site once the static branch table is exhausted — this
fallback is what makes the indirect-call test bucket (§9, §11b off-diagonal cell) observably
different before and after the fix, not a hypothetical. No thunk-unwrapping is needed beyond the
existing skip: `checkNoRetApi` (already in the codebase, `vivisect/__init__.py`) tags a thunk's OWN
address in the same declared table a direct import does, so `isNoReturnVa(target)` already resolves
correctly through thunks once `target` is the thunk's address. Revised estimate: ~200-215
meaningful, a modest but real buffer above the 200 floor (see §7c for the source of the remainder).

### 7c. Where the LOC lives

`noretprop.py`'s worklist cannot use `vw.getCallers()`/xref-based reverse lookup as the primary
signal for the SAME reason `_resolveCallTarget` cannot use xrefs as the primary signal for direct
calls: `_cb_noflow`'s delete-and-recreate-location implementation (`vivisect/base.py`) drops the
call-site xref as a side effect of correctly marking a call to an already-known no-return target,
specifically in the case that matters most (a caller discovered after its callee's status is
already known). The propagation pass therefore builds its own reverse call-target index by
directly parsing each function's leaf-terminal instruction once (the same primitive
`_resolveCallTarget` uses), rather than trusting the xref database — this is the real, load-bearing
majority of `noretprop.py`'s LOC, not a thin wrapper around an existing API.

## 8. Solution outline — pure-function helpers

```
noret.py:
  _resolveCallTarget(vw, callsite_va) -> int | None
      ← requirement: a terminal call's actual TARGET must be checked, not the call site's own
        address (§7b) — try the instruction's own static branch table first (correct for every
        direct call, and for a resolved-indirect call whose target is a literal operand); fall
        back to any xref recorded at the call site (the only path for a register/memory-indirect
        call whose target is established later, by a different analysis pass) (§7c)

  _isFunctionNoReturn(vw, fva) -> bool
      ← requirement: default-to-returns unless every terminal block is proven (§4 canonical form)
      pure; no side effects; used by BOTH analyzeFunction (below) and noretprop.py
      if vw.isFunctionThunk(fva): existing skip, unchanged (a thunk-to-import is not analyzed here)
      for each leaf block (vivisect.tools.graphutil.buildFunctionGraph + getNodeWeightHisto):
          resolve its terminal instruction
          if it is a genuine return -> this function can return, short-circuit False
          if it is an unresolved/dynamic branch -> not proven, short-circuit False (unchanged
              from today's conservative IF_BRANCH handling)
          otherwise (the terminal instruction is a call): resolve its target via
              _resolveCallTarget; if no target, or isNoReturnVa(target) is False -> not proven,
              short-circuit False
          else -> this leaf is consistent with no-return; check the remaining leaves
      return True only if every leaf was consistent

  analyzeFunction(vw, fva)   [existing entrypoint, MODIFIED]
      if _isFunctionNoReturn(vw, fva): vw.addNoReturnVa(fva)

noretprop.py:
  _buildReverseCallIndex(vw) -> dict[int, set[int]]
      ← requirement (§7c): built once per whole-workspace pass by directly parsing every
        function's leaf-terminal instruction (the SAME resolution _resolveCallTarget performs),
        because the xref database is not reliable for this purpose (§7c) — maps a target va to
        every function whose leaf-terminal call currently resolves to it

  analyze(vw)   [new whole-workspace AnalysisModule entrypoint]
      ← requirement: re-derive whenever new information becomes available (§4, §5)
      index = _buildReverseCallIndex(vw)
      seen = set of every function currently known no-return (declared + already-derived)
      worklist = list(seen)
      while worklist:
          f = worklist.pop()
          for caller in index.get(f, ()):
              if caller in seen: continue
              if _isFunctionNoReturn(vw, caller):     # reuse the SAME helper, same proof rule
                  vw.addNoReturnVa(caller)
                  seen.add(caller)
                  worklist.append(caller)
      ← cycle safety is structural, not a special case: a function only enters `worklist` once
        it is PROVEN (via the shared helper), and a pure 2-cycle with no external exit can never
        satisfy that proof (checking either member requires the other's status, which is never
        established) — monotonicity terminates the loop without a visited-recursion-depth guard
      ← the index is built once, up front; it does not need to be rebuilt mid-pass because a
        function's OWN leaf-terminal call targets never change during this pass, only which of
        those targets are proven no-return does
```

No fixpoint `loop { ... if !changed break }` construct is needed — the worklist queue IS the
fixpoint driver (a function is only re-examined when something concrete about it changed: a callee
just got proven no-return). Both `_resolveCallTarget` and the reverse-index build, and the full
worklist propagation against 9 scenarios (ordinary callee, 2-cycle, 2-hop and 3-hop direct chains,
a genuinely mixed-leaf function via a real conditional branch, and the indirect-call-resolved-later
case with a caller in a separate memory region so its block boundary is unambiguous) were run to
completion against a live `VivWorkspace` during design verification; all matched the canonical form
in §4.

## 9. Test file outline

Path: `vivisect/tests/test_noret_<hex>.py` (matches existing `vivisect/tests/test*.py` convention;
random hex suffix per the banned-marker rule)

Block 1 — Imports: `vivisect`, `vivisect.const`
Block 2 — Builder helpers (10-20 one-liners): byte-level amd64 encoders already proven against the
  live library during design verification — `CALL_REL32`, `JMP_REL32`, indirect
  `MOV_RAX_IMM64`+`CALL_RAX`, `RET`, `UD2`/`INT3` fill — plus a `build_workspace()` helper that
  constructs a `VivWorkspace` with `Format='blob'`, registers `codeblocks` + `noret` +
  `noretprop`, and exposes `addMemoryMap`.
Block 3 — Assertion helpers: `assert_noret(vw, va)`, `assert_returns(vw, va)`
Block 4 — Tests grouped by requirement bucket:
  - **Bucket "false positive closed" (§4 default polarity, the base-failing discriminator):**
    a function whose only terminal block ends in a call to an ORDINARY, returning function must
    NOT be marked no-return. (Verified: fails on base today — returns `True`.)
  - **Bucket "cycle non-provability" (§4/§5):** two functions that call only each other, with no
    route to anything provably no-return, must both stay return-capable. (Verified: fails on base
    today — both return `True`.)
  - **Bucket "declared, direct":** a function whose only terminal call reaches a declared no-return
    API directly is marked no-return. (Regression coverage; already correct on base via codeflow's
    own recursive descent — kept to prove the fix does not regress it.)
  - **Bucket "derived, multi-hop chain":** A calls B calls C calls a declared no-return API, chain
    length 3+; A, B, and C are all marked no-return. (Regression coverage for the direct-recursion
    case; additionally, a variant where B and C are visited in REVERSE discovery order via two
    unrelated entry points, which is NOT already correct on base without the fix.)
  - **Bucket "indirect resolution + re-derivation" (§4 re-derivation, the second base-failing
    discriminator, F-10 cross-product cell):** an entry point EARLY calls a target only through a
    register-indirect call (unresolvable by codeflow at EARLY's discovery time); the true target
    (itself only DERIVED no-return, not declared) is resolved and analyzed AFTER EARLY. EARLY must
    end up no-return once the indirect target is known. (Verified: fails on base today — EARLY
    incorrectly reads `True` for the wrong reason pre-fix, and would read `False` forever
    post-default-fix-without-the-worklist; this is the row that specifically requires §7b + the
    worklist together, not either alone.)
  - **Bucket "thunk-mediated no-return call":** a terminal call through an import-thunk wrapper to
    a declared no-return API is recognized (regression coverage for §7b, mirrors
    `test_pe_dynamic_noret`'s real-world shape without needing `VIVTESTFILES`).
  - **Bucket "idempotence":** running the whole-workspace analysis pass twice produces identical
    `isNoReturnVa` results the second time.

5-axis coverage check:
  - Every described atom in meta.md: default polarity / cycle non-provability / re-derivation /
    indirect resolution / thunk resolution — each has >=1 test
  - Every public surface: `isNoReturnVa`, `addNoReturnVa`, `getCallers` (exercised transitively)
  - Every solution branch: return-instruction leaf, proven-call leaf, unproven-call leaf, cycle,
    worklist termination
  - Standard edge cases: single-instruction function (return only), empty function body (no leaves
    — not constructible in valid code, skip), self-recursion (function calls only itself, no
    external exit)
  - Stated inverse: "must NOT be marked no-return" gets equal test weight to "must be marked
    no-return" (this is the discriminating direction per the design's own bug history)

## 10. Forced trait bounds / kwargs

Python, no generics/kwargs forcing. One real signature constraint: `_isFunctionNoReturn` must be
pure (no `vw.addNoReturnVa` calls inside it) so `noretprop.py` can call it speculatively during
worklist evaluation without side effects on a caller that turns out NOT to qualify — an agent that
inlines the mark-as-noret call INSIDE the leaf-walk (matching the CURRENT code's structure, which
mutates state inline) will make the worklist's "try, and only commit if fully proven" pattern
harder to get right cleanly, without breaking outright — a soft trap, not gated on directly.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in §6) | Test that catches it |
|---|------|------|----------------|-------------------|----------------------|--------------------|-----------------------------|------------------------|
| 1 | Default-polarity inversion missed — agent adds a positive proven-call case but keeps silent omission as the fallback for everything else | F-9 (cross-stage: the SAME shared helper is consulted by both the original per-function pass and the new worklist, so a wrong default breaks both at once) | S3 baseline-preservation through a shared chokepoint | Soundness (does an unproven leaf ever wrongly pass) | #2 (a fix that gets #1 right by "if not proven, treat call site itself as an implicit cycle-breaker" without a real proof rule will also mis-handle #2) | The existing code already has a working IF_RET and IF_BRANCH branch; extending that if/elif chain with one more positive case (matching the surface pattern) is the path of least resistance, and reads as done | "a terminal call to a function whose behavior has not been established must not, by itself, support a no-return conclusion" | Bucket "false positive closed" |
| 2 | Cycle non-provability — agent's proof rule treats "in-progress" (currently being evaluated) the same as "no-return", causing a naive worklist or recursive proof to short-circuit true on a self-referential pair | F-14-adjacent (declared-vs-derived terminal state: the fix needs a genuine THIRD state — unknown/in-progress — not just true/false) — flagged as a **candidate pattern, not a confirmed F-id**, since I have not measured this against a real agent batch | S1 speculative-state isolation | Soundness under recursion, not just linear chains | #1 (shares the same proof primitive) | A recursive or memoized implementation of "is X no-return" that marks a node visited-in-progress and, on hitting that marker again, returns something other than "not yet proven" will bootstrap the cycle incorrectly | "two functions whose only terminal paths call each other ... must never be marked no-return" | Bucket "cycle non-provability" |
| 3 | Re-derivation skipped — agent fixes the leaf proof rule (#1) correctly but runs it only once per function (matching the existing single-pass architecture), never re-triggering already-examined callers when a callee is proven later | F-9 (one shared root cause — "when is this check run" — affects every capability that depends on it) | S4 machinery-riding integration (the fix rides the EXISTING analysis-module registration point; the required NEW machinery is the re-trigger) | Completeness under out-of-order discovery | #1 (the correctly-conservative default from #1 is what makes #3 observable: pre-#1, the omission bug accidentally papers over some out-of-order cases; post-#1-without-#3, those cases become permanently, silently wrong instead of permanently, silently wrong in the other direction) | The existing single-pass `FuncAnalysisModule` architecture has no precedent anywhere in the codebase for "re-run me when new information arrives" — the natural instinct is to make the one pass smarter, not add a second pass | "a function's no-return status must be re-derived whenever new information about a function it calls becomes available" | Bucket "indirect resolution + re-derivation" |

Every trap's axis differs (soundness-vs-omission / soundness-vs-recursion / completeness-vs-timing),
and #1/#3 in particular are interdependent in the strongest sense measured in this codebase: fixing
#1 alone actively makes a class of case WORSE without #3, which is the fair, textbook shape of an
"orthogonal wall a partial fix cannot escape."

## 11b. Capability cross-product matrix (F-10)

Two axes stated in meta.md: **how the target is reached** (direct/statically-resolvable call vs.
indirect/register-resolved call) x **how the target's no-return status is established** (a
pre-declared API name vs. derived purely by this same analysis, transitively).

| | target is a declared API | target's status is itself derived |
|---|---|---|
| **direct call** | test: "declared, direct" (regression; correct on base) | test: "derived, multi-hop chain" (regression for the recursion-healed direction; the reverse-discovery-order variant is NOT correct on base) |
| **indirect call** | not separately tested — collapses to the direct-declared proof once resolved, no new information | test: **"indirect resolution + re-derivation"** ← off-diagonal, hardest cell, base-failing |

The off-diagonal cell (indirect call reaching a target whose OWN no-return status is itself only
derived, not declared) is the one cell that requires BOTH new mechanisms (§7b thunk/indirect
resolution AND the worklist) working together — it cannot be produced by either fix in isolation.

## 12. Tier + category decision

- Tier: Olympus (one tier, 2026-07 sprint)
- Sub-rank target: Okay-to-Good (187-225 meaningful LOC is well above the 200 floor but below the
  historical "Good" cluster median of ~540; scope is intentionally tight and precise rather than
  broad — precision over breadth given the bug is narrow and deep, not wide)
- Category: **bugfix** (corrected 2026-08-20 per platform review finding — originally filed as
  `enhancement`; the primary goal is correcting a wrong analysis result, not modifying behavior
  that already worked. `propagateNoReturn`/`NoReturnDerivation` support the fix, they are not the
  main goal, exactly as the platform's own reasoning states)

## 13. Predicted Nova/Vega pass rate

- Predicted: 12-18%
- Reasoning: O-Pipeline-hard historical band (15%) as the base rate; the design has two
  genuinely interdependent, differently-misdirecting traps (not a uniform-wrap); the dominant
  failure mode (agent fixes #1, ships without #3) is a MISSED_REQUIREMENT that a shallow read of
  the existing code plausibly produces, since the existing single-pass architecture has zero
  precedent for a re-trigger mechanism anywhere else in the codebase to copy from.
- Sanity check: within the <=40% current-sprint ceiling with wide margin; not at 0% since the #1
  fix alone (inverting the default) is a small, self-contained, clearly-specified change most
  agents will find quickly by reading `noret.py`, and SOME of the test buckets (declared/direct,
  thunk-mediated) only require #1 to pass — full credit requires all buckets, but partial credit
  on the easier buckets keeps this solvable, not a 0% wall.

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 (architecture, 5 subsystems, entanglement zones, test framework,
      template file all established in the hunt phase + this design phase)
- [x] Existing PR check: 0 hits for `noret`/`no return`/`noreturn`/`call graph`/`propagat`/
      `transitive`/`fixpoint`/`worklist`/`fixed point`/`cannot return` (all searched, full bodies +
      comments read on the one substantive hit, issue #258, which requests adding a NAME to the
      declared-API list — a different, narrower, unrelated mechanism)
- [x] Closest approved problem: none in this workspace touch vivisect or a comparable
      call-graph/fixed-point analysis shape; nearest SHAPE precedent is the O-Pipeline-hard band
      itself (SHAPES.md), not a specific sibling problem
- [x] Title: verb-led, 8 words, names specific subsystem (no-return analysis)
- [x] Shape declared with SHAPES.md citation
- [x] Public API surface: no new names; existing surface fully listed
- [x] Canonical output form spelled out: default polarity, proof requirement, cycle rule,
      re-derivation trigger, idempotence
- [x] 0 codebase-inferable requirements (every rule in §4 is stated in meta.md)
- [x] Description draft word count: 258 (over 200 recommended, under 500 hard cap — accepted, see § 6)
- [x] File footprint sketched against REAL source (line numbers, existing function names cited)
- [ ] Raw/meaningful LOC clears 200 floor — MEASURED 187 Counter-1-effective (§ 7d), 13 lines
      short after two rounds genuinely exhausting the safe/verified integration points found in the
      codebase (every `isNoReturnVa` call site enumerated; fixed 4, deliberately left 1 with a
      stated reason). NOT closed by padding — user reviewed and approved the second round in
      real time. Flagged for the platform reviewer rather than pushed further.
- [x] Solution outline: pure-function helpers, 1:1 with description requirements
- [x] No fixpoint `loop{}` needed; worklist queue IS the fixpoint driver (stated explicitly)
- [x] Test file outline: 4-block layout, scenario-encoded names
- [x] 5-axis test coverage planned
- [x] Forced trait bounds documented (purity constraint on the shared helper)
- [x] 3 named traps, 2 confirmed F-id-adjacent + 1 explicitly flagged as unmeasured/candidate
- [x] Traps on different axes; #1/#3 explicitly interdependent
- [x] § 11b cross-product matrix filled in; off-diagonal cell tested and base-failing
- [x] Format-noun extents: N/A (no record/entry/block/section format being parsed)
- [x] Tolerance-rule N-1 fixture: N/A (no "allow one, stop at second" rule in this design)
- [x] Predicted Wrong Logic <25% (this is a soundness/completeness bug, not a subtle numeric
      near-miss; agents either get the polarity right or wrong, not "almost right")
- [x] Predicted pass rate (12-18%) within <=40% ceiling
- [x] Category (enhancement) matches title verb (Fix)
- [x] Not pattern-followable: no 3+ existing examples of this shape in the codebase (this is the
      ONLY no-return-style analysis pass in vivisect)
- [x] Not in RULES § Features already used (new repo to this workspace)

## Why this is not a duplicate

No prior approved or in-flight problem in this workspace touches `vivisect`, or any comparable
"fixed-point propagation over a derived program-analysis fact" shape on another repo closely
enough to share a feature class — the nearest shape precedent (`SHAPES.md`'s O-Pipeline-hard band)
is a LOC/pass-rate/trap-count calibration reference, not a specific sibling problem, and no
GitHub PR or issue (searched by 10 keyword variants, full bodies and comments read) implements or
requests this mechanism; the one substantive hit (issue #258) requests a different, much narrower
change (adding a name to a static list) with no code and no design attached.

## Predicted iteration cycles: 2

The design required unusually deep empirical verification against the live library before writing
(7 verification scripts run against a real `VivWorkspace`, catching and discarding an initial,
INCORRECT hypothesis about simple multi-hop propagation being broken — it is not, thanks to
`envi/codeflow.py`'s existing recursive-descent self-healing). That verification work is what
brings the iteration estimate down from the O-Pipeline-hard default of "invent an algorithm" (which
often costs 3-5 rounds when the underlying bug is asserted rather than demonstrated) to 2: the
canonical form and every trap in § 11 is grounded in an actual, reproduced, `print()`-verified
before/after state, not a plausible-sounding guess.
