# customasm-for-directive — eval results

## Batch 1 (81-test version, v17) — 10x Nova/Nova
Pass rate: 7/10 PASS = **70% (TOO EASY, >40% cap)**. All 3 fails identical cause.

| Run | Verdict | Msgs | LOC | Failed tests | Approach note |
| --- | ------- | ---- | --- | ------------ | ------------- |
| 1 | PASS | 87 | 587 | — | synthetic per-iteration scope (correct) |
| 2 | FAIL_MISSED_REQ | 76 | 766 | 5 local-label scope | suffix-rename local names, NO per-iteration parent scope |
| 3 | PASS | 86 | 600 | — | synthetic scope |
| 4 | PASS | 78 | 740 | — | synthetic scope |
| 5 | PASS | 79 | 647 | — | synthetic scope |
| 6 | PASS | 108 | 845 | — | synthetic scope |
| 7 | FAIL_MISSED_REQ | 90 | 766 | 5 local-label scope | renamed local ids, no per-iteration parent label |
| 8 | PASS | 95 | 932 | — | synthetic scope |
| 9 | FAIL_MISSED_REQ | 81 | 753 | 5 local-label scope | renamed hierarchy-lvl-1 syms, no scope-establishing parent |
| 10 | PASS | 70 | 653 | — | synthetic scope |

**Diagnosis (doctrine 3c):** the per-iteration local-label scoping IS the discriminating wall (30% kill).
The failure is BINARY: agents who pick the TEMPTING suffix-rename approach (S1/S5 tempting-wrong) fail the
no-preceding-global local-label case; agents who discover the synthetic-scope approach pass everything.
Every fail self-tested with a `root:` global before the loop (self-test-shadow, P3), masking the miss.
Rate ~= % who pick synthetic vs suffix. All 3 fails are FAIR (behavior explicitly stated; the evals rate
the problem "challenging", description_clear, deterministic, agent_blame_unfair=false).

## Re-harden (v18, test-only) — composition-first, +8 scoping-facet discriminators (81 -> 89)
Targets facets an INCOMPLETE synthetic impl misses (each verified on the reference, each fair under the
documented per-iteration-scope rule):
- nested loops both using local labels; local CONSTANT (not just label) per iteration; deferred-bound loop
  with a local label; local label composed with the loop var in one expr; TWO loops reusing the same
  `.loc` (globally-unique scope naming); a deferred 2nd loop reusing `.loc` (uniqueness ACROSS passes);
  local label in an INSTRUCTION operand per iteration; nested local label composed with the outer var.
These kill suffix impls on more axes AND catch synthetic impls that scope only labels / only one level /
by per-loop index. NOT yet re-batched.

## Re-harden (v19) — SECOND cross-subsystem wall: address-dependent loop bounds (89 -> 94)
Batch 1's 7 passers all handle scoping facets, so facet-stacking ceilings. Added a wall the CORRECT
solvers ALSO fail: bounds/step may reference LABEL ADDRESSES, resolved through the address fixpoint (not
constant-folding). All 10 batch agents expanded in the pre-pass (eval_simple, constant-only) -> every one
FAILS address-dependent bounds. Reference integrates expansion with resolve_iteratively via a meta-loop
(common path byte-identical; base 691 untouched + deterministic). 5 hard-tier tests added. Effective LOC
590 (Good). CONTRACT-STATED/FIX-HIDDEN; composes with scoping (double wall). 0%-risk: hard architectural
discovery, batch on the STANDARD mix (Orion is the deep solver); ease if 0% (reference proves solvable).

## Ceiling note (honest)
This is a mirror-`#if` splice feature; the doctrine flags such as separable/ceiling-prone. The one coupled
sub-feature (per-iteration scoping) yields ~30% kill. The behaviors the CORRECT synthetic approach itself
fails (post-loop scope restoration; referencing an outer local after an inner loop) are also failed by the
reference, so they are untestable-fairly. Facet-stacking is the available fair lever; if batch 2 is still
>40%, the realistic options are accept a Mars-band ceiling or a fundamentally different harder core.
