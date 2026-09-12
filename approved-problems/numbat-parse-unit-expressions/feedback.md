# feedback.md

## Round 8 (2026-08-04) - baseline defect went pool-wide; ONE lever applied

**Runs: 0/6.** Two separate problems, and only one of them is difficulty.

**1. The baseline defect is no longer Orion-specific.** 5 of 6 NOVA runs removed
`parse_quantity_ast` and never re-added it, so the 12 inline tests that call it cannot compile and
must go. Only Nova_3 kept the function, and only Nova_3 scored 225/225. Across rounds 7-8 that is
7 of 8 agents. When 87% of the pool does the same thing, it is the environment.

The cause is structural: `parse_quantity_ast` is a PRIVATE helper whose unit tests live inline in the
one file the task forces you to rewrite. Renaming or absorbing it is a normal refactor; node-identity
grading treats the consequent test deletion as a regression. Whether a run passes turns on an
arbitrary naming choice, not on feature quality - Orion_1 was 85/88 on features and scored zero.

**Re-skipped `parse_quantity::tests`, and this time the T1 answer is evidenced rather than asserted.**
I mapped all 14 tests: 12 have behavioural equivalents already in the new suite through the PUBLIC
api (scalar/integer/negative/unit/double+triple negation/explicit multiplication/addition/variable/
empty/scalar-times-scalar), and 2 are obsolete because the feature inverts them. So no regression
coverage is lost - it is relocated to assertions that survive an internal rename. That is what T1
actually wants; the previous narrow skip satisfied its letter while making the problem unsolvable.

**2. ONE difficulty lever, chosen by arithmetic.** Kill table: superscript pair 6/6, chained
reciprocal pair 4/6, everything else <=1. The candidate repairs and their consequences:
- Disclose the superscript root cause ONLY -> Nova_5 and Nova_6 (whose ONLY failures are that pair)
  pass; Nova_2/3/4 still die on chained reciprocals; Nova_1 still dies on five more. **2/6 = 33%.**
- Disclose BOTH -> Nova_2/3/4 also pass. **5/6 = 83%, too easy.**
- Disclose chained only -> nobody passes, since all six still fail superscripts. **0/6.**

So exactly one lever, per 3c-bis step 5. The chained-reciprocal wall stays standing deliberately -
it is the thing keeping this off the too-easy edge.

**The lever (3c-bis step 3, name the ROOT CAUSE not the FIX):** the round-trip sentence becomes
"whatever `unit_name` prints for a unit reads back as that same unit, including printed forms the
language itself would not parse." That says WHERE the difficulty lives - the printed form is not
necessarily valid source - and never says Unicode, superscript, tokenizer, digit, or normalise.
Verified: none of those words appear anywhere in the body.

**Predicted 2/6 = 33%**, in band. Risks named honestly: if the disclosure still does not land it is
0/6 again, and the next notch would have to be sharper wording; if agents that clear superscripts
also happen to clear chained reciprocals, it goes to 5/6 and is too easy. The chained-reciprocal
cell is the load-bearing one now.

Now: 88 tests, base 213, human-effective 385, 3 files, meta 469 words.

## Round 7 (2026-08-04) - Auto Review APPROVED; 0/7 solvability repaired per HARDENING 3c-bis

**Auto Review: APPROVED** (Description 3/3, Tests 2/3, Solution 3/3). Only a Low T4 on numeric
spellings, now closed.

**Runs (agent-runs 7): 0/7.** Applied § 3c-bis by the book.

*Step 1, failure SIGNATURE:* not convergent. Two runs sit at 87/88, each failing a DIFFERENT single
test - Nova_3 only `a_negated_parenthesised_ratio_exponent_parses`, Nova_5 only
`unit_from_requires_a_concrete_annotation_like_parse_does`. That is the fair-but-hard near-miss
profile, not flailing.

*Step 2, classify each blocker with the fairness table:*
- **Nova_5's blocker = HIDDEN REQUIREMENT.** The meta never said an unannotated `unit_from` call
  fails. I had flagged this myself two rounds ago as the single codebase-inferable item and the
  weakest trace in the suite. Repaired with one explicit sentence: "It needs a concrete annotation to
  know which dimension to produce, and fails without one."
- **Nova_3's blocker = AMBIGUOUS SPEC.** The meta said a ratio exponent is parenthesised and may be
  negative, but never where the sign sits relative to the parentheses, which is exactly the
  distinction between `m^(-(1/2))` and `m^-(1/2)`. Repaired by naming WHERE the difficulty lives, not
  the fix: "a minus sign may sit on either side of those parentheses." It does not say to recurse
  through the negation before dispatching on the division.

Both are fairness repairs (restoring statement and discoverability), not difficulty cuts, which is
what 3c-bis authorises. Neither test was deleted and no wall was removed.

*T4 Low closed:* compound-unit cases added for binary, positive and negative infinity, and NaN
spellings. All already worked, so this is FP-surface coverage, not a lever.

**A measurement I CANNOT make, stated plainly:** meta easing cannot be validated by replaying old
agent patches - those agents never saw the new wording, so their code fails identically either way.
The effect of both repairs is only observable in a FRESH batch. I attempted a replay, found it
meaningless for meta changes, and am not reporting a number from it.

**Orion is structurally blocked and it is our harness, not their code.** Both Orion runs fail the
same 12 baseline tests - the `parse_quantity::tests` module un-skipped in round 6 to close T1 (flagged
High three times). Orion deletes that module while rewriting; every Nova run preserves it (225/225).
So Orion cannot pass regardless of feature work. Re-skipping the module would unblock Orion but
reopens a High finding that took four rounds to close and that Auto Review has just accepted. Left as
is deliberately; if the pool stays Orion-heavy this is the first thing to revisit.

**Prediction: 1-3 of 10, and 0 remains possible.** The two repairs each convert one known near-miss,
but only for agents that read the new wording. Superscript (5/7) and negated-ratio-exponent (4/7)
remain the dominant walls.

Now: 88 tests, base 225, human-effective 385, 3 files, meta 460 words.

## Round 6 (2026-08-04) - 7/10 too easy -> superscript round-trip trap (measured 7/7 kill)

**Diagnosis (agent-runs 6).** 7/10 passed; **81 of 83 tests killed nothing**. Only
`unit_from_requires_a_concrete_annotation_like_parse_does` (3) and
`a_negated_parenthesised_ratio_exponent_parses` (1) discriminated. Stage-2 table: "everyone passes"
-> add a mechanism on a DIFFERENT axis.

**The lever came from the FP panel, and every flag said "reference also fails".** Those were not
agent divergences, they were gaps in MY solution:
- `unit_from(unit_name(1 m^10))` fails. `unit_name` prints `m` with a Unicode superscript run, and
  numbat's tokenizer (`tokenizer.rs:174`) accepts only SINGLE digits one through nine - no zero, no
  multi-digit. So the repo cannot read back its own printed units, and my meta claims `unit_from` is
  the inverse of `unit_name`. Confirmed at BASE: `1 m^10` -> prints `m` superscript-one-zero, and
  feeding that back is a parse error.
- `value_in` inherited `Quantity::convert_to`'s zero exemption, so `value_in(0 s, "m")` returned 0
  and `value_in(0 m, "°C")` returned -273.15 for a Length. That is the S1 HIGH that scored Solution
  0/3 - and it is the same zero shortcut I had built a TRAP on, which then bit my own reference.

**Fixes.** `normalize_superscripts` rewrites superscript runs into `^(...)` at the owned-string entry
points (lifetimes forbid doing it inside `single_expression`). `convert_checked` compares base-unit
representations before conversion, so a mismatched dimension is rejected whatever the magnitude,
on both the ordinary and the offset-temperature path.

**Trap-proof by REPLAY, not mutation** - all 7 round-6 passers rebuilt from their own patches and run
against the final 88-test suite:

| Trap | Kills |
|---|---|
| `unit_from_reads_back_what_unit_name_prints` | **7/7** |
| `superscript_exponents_are_accepted_by_both_builtins` | **7/7** |
| `value_in_rejects_a_mismatched_dimension_even_for_zero` | **4/7** |

**Orthogonality.** The superscript trap is a character-set / round-trip-with-the-printer axis that no
other cell touches. The zero cell is a POLARITY cell against a rule already in the meta (`parse`
exempts zero from annotation checks; `value_in` must not exempt it from dimension checks) and it
separates - 4 of 7 failed it, 3 did not.

**Auto Review verdicts addressed:** S1 (Solution 0/3) fixed as above. T1 (base mode skipping the whole
`parse_quantity::tests` module, flagged High three times) narrowed to the two obsolete tests - base is
back to 225 and the reference passes all of them. T4 (value_in never tested against live user-defined
units) closed with `unit hop: Length = 3 m; value_in(6 m, "hop") == 2`. Coverage suggestion on legacy
number spellings added (scientific, underscore, hex, negative exponent) - all already worked, so it is
FP-surface coverage rather than a lever, and I am not counting it as difficulty.

**Honest risk: this now overshoots, not undershoots.** 7/7 sampled passers die and the 3 prior
failures still fail, which projects 0/10 = unsolvable reject. Mitigated with the disclosure lever
(HARDENING 3c.3 / Stage 3 §4): the contract now reads "whatever `unit_name` prints for a unit reads
back as that same unit, whatever its exponents" - it steers the probe toward exponent variety without
naming Unicode, superscripts, or the tokenizer. If the next batch still reads 0, the next notch is to
name the root cause (the printed form uses a spelling the source grammar does not accept), still
without the fix.

Now: 88 tests, base 225, human-effective 385, 3 files, meta 435 words.

## Round 5c (2026-08-04) - flip REVERTED, disclosure lever applied instead

**The flip in 5b was wrong and the user caught it.** `HARDENING.md § 3c.3` is explicit: "The
disclosure lever: name the ROOT CAUSE, never the FIX ... A fair 0/N resting on one hard step moves to
~3-6/10 when the meta names the root cause only ... Prefer a meta REWORD (make the contract concrete)
over a hint." That is the canonical documented move for exactly this situation, and its measured
outcome is the band we want.

Two things were wrong with accepting `2 (m/s)`:
1. It abandoned a legitimate wall instead of fairly disclosing it, which is the opposite of the
   documented lever.
2. It made `parse` accept a form **base numbat itself rejects** ("This expression has type 'Scalar'
   and can not be called as a function"), i.e. inventing grammar the issue never asked for - an A10
   "would the maintainer merge this?" risk, and the mirror of the L19 mistake.

**Reverted.** `normalize_juxtaposed_group` removed, the rejection restored and tested, and the
contract now names the ROOT CAUSE without the fix: "Writing two unit names next to each other
multiplies them, but the language reads a parenthesised group written directly after a number as a
call rather than a product, so that is not a quantity literal." It says WHERE the difficulty lives
(the host grammar's reading of that juxtaposition) and never says what to do about it - no mention of
normalising, rewriting, or which node to inspect. Rule-7 respected: it is one general principle, not
an enumeration of rejected spellings.

**FP status is unchanged and clean:** the rule is stated AND tested, so an agent that accepts
`2 (m/s)` fails the discriminator rather than passing with an undocumented divergence. The FP hole
only existed in the window where the test was removed but the reference still rejected.

**Projection.** The documented lever puts a disclosed 0/N at ~3-6/10 on its own. `value_in` then
takes failures off the top - none of the 11 previous runs implemented it, and its affine inverse plus
the absolute-zero cell are the discriminators (4 mutations, all kill). Expect the low end of that
range, roughly 1-4 of 10. This is a projection from the doctrine plus the mutation evidence, NOT a
measurement - the batch is the only oracle.

Now: 83 tests, base 213, human-effective 354, 3 files, meta 421 words.

## Round 5b (2026-08-04) - FP surface closed by flipping the juxtaposition boundary

**Decision: the reference now ACCEPTS `parse("2 (m/s)")`** instead of rejecting it, and the
behaviour is tested. Rationale: dropping the tripwire test left an untested divergence (reference
rejected, 9 of 11 agents accepted), and round-4 Auto Review had already ruled the boundary real - so
a passing agent that accepted it would have been FP-flagged. The two FP-clean options were to test
the rejection (back to the 0% dead end) or to make the reference match the majority reading. Flipped,
because inside a quantity-literal string a number cannot be callable, so a product is the only
reading - which is exactly the rationale Nova 1 wrote in its own comment.

Implementation: `normalize_juxtaposed_group` rewrites `<scalar>(group)` into multiplication, with a
separate arm for `Power{<scalar>(group), e}` -> `Mul(scalar, Power(group, e))` so `2 (m/s)^2` is
2 m²/s² and not 4. `sin(1)`, `from_celsius(20)`, `2 (3)` and `2 (3 m)` stay rejected (the callable is
an identifier, or the group carries a second number). Contract: "Writing two unit names next to each
other multiplies them, and so does writing a number or a unit name next to a parenthesised group."

Trap-proof: M15 (no normalization - what the 2 strict agents did) kills; M16 (normalize but lose the
power restructure, giving 4x) kills.

**Three coverage suggestions taken, all of them genuine FP holes:**
- **Unparenthesised ratio exponents.** `parse("2 m^1/2")` is REJECTED, because `^` binds tighter than
  `/` so it means `(m^1)/2` - a division by a number. The meta said "may be parenthesised", which
  reads as optional. That was a shipped fairness gap. Reworded to state the boundary, and pinned for
  both builtins.
- **User-defined DERIVED units.** The old test used `unit jump: Length` (scale 1), so a solution that
  dropped the scale passed. Now `unit hop: Length = 3 m` with `parse("2 hop/s")` = 6 m/s.
- **Chained reciprocal parity.** `parse("2 /s/m")` added alongside `unit_from("/s/m")`; the meta
  claims parity and only one side was covered.

Also tightened `value_in`'s contract to say the target carries no number - the weakest trace in the
FP audit.

**FP trace: all 83 tests map to a meta sentence, and the one known divergence is now gone.**

Now: 83 tests, base 213, human-effective **392**, 3 files, meta 410 words.

## Round 5 (2026-08-04) - plateau diagnosed, scope added: `value_in`

**Runs (agent-runs 5): 0/11.** Orion_Nova_3 is a real working run (1046-line patch) whose
implementation is simply broken, so it counts. Kills: `a_number_juxtaposed_with_a_grouped_expression_is_rejected`
9, `a_negated_parenthesised_ratio_exponent_parses` 3, `a_power_applies_to_a_grouped_compound_expression` 3,
temperature signs 1, negative compound 1, repeated signs 1, paren numerator 1.

**The decisive measurement: 5 of 11 runs failed ONLY the `2 (m/s)` tripwire.** Removing it gives
5/11 = 45%, not 10/10. So the two available states were 0% (unsolvable reject) and 45% (too-easy
reject) - no middle.

**I tried to find a third state and failed honestly.** Built all 5 clean runs from their patches and
ran 25 adversarial probes against each: nested and grouped powers, negated parenthesised ratios on
grouped bases (`(m/s)^(-(1/2))`), chained reciprocals, prefixed groups, `(km/h)^(1/2)`, partial
cancellation (`m s/s`, `kg m/kg`), binary prefixes under powers, `m^2^3`, `--2 * (km/h)^2`. **Every
probe matched the reference exactly on all five runs.** Those implementations are genuinely correct;
there is no blind spot left to exploit, and adding more edge cells would be tuning coverage rather
than difficulty.

**Conclusion: the problem had plateaued.** What separated pass from fail was no longer "can you
build this" - five agents built it - but one rejection boundary Auto Review twice called "a
peripheral grammar tripwire". So the tripwire test was REMOVED and new scope added instead.

**New capability: `value_in<T: Dim>(quantity: T, target: String) -> Scalar`,** the inverse of
`parse`. It reuses the whole unit-expression grammar for the target, so it composes with every
existing cell, and the `Scalar` return type is what makes offset temperature targets expressible
(converting to `°C` yields a number, not a Temperature - numbat models `°C` as a function
`Temperature -> Scalar`, not a unit).

Why it should discriminate where the old cells could not:
- The affine inverse is a genuinely separate code path from parsing `20 °C`, and temperature is
  already where runs stumble (2 of 11 died on sign/temperature cells).
- **numbat's own `Quantity::convert_to` short-circuits zero** (`|| self.unsafe_value().to_f64().is_zero()`),
  which is correct for multiplicative units and WRONG for an offset scale. `value_in(0 K, "°C")` must
  be -273.15, not 0. An agent mirroring the repo's own shortcut gets it wrong - the repo hands them
  the bug.

Trap-proof, 4 mutations, all kill: M11 zero short-circuit in the affine path (1), M12 no offset
handling (2), M13 Fahrenheit using the Celsius offset (1), M14 prefix dropped on the conversion
target (4).

Contract: one new meta paragraph stating WHAT (returns the plain number, offset applies so absolute
zero is not zero on that scale, dimension mismatch rejected) and never HOW.

Now: 79 tests, base 213, human-effective **354** (up from 284), 3 files, meta 380 words.

## Round 4 (2026-08-03) - S1 bug fixed (my own clause caused it), sign cells added

**Runs (agent-runs 4): 0/3, baseline CLEAN (0 failures).** The module skip fixed the environment
defect - that is settled. Kills: `a_number_juxtaposed_with_a_grouped_expression_is_rejected` 3/3,
`a_negated_parenthesised_ratio_exponent_parses` 1/3. The F-1 wall is now the SOLE decider, which is
why the reviewer calls 0/3 "a peripheral grammar tripwire".

**S1 (Solution 0/3) was a real bug, and I caused it last round.** Adding "the sign in front of it
may be repeated" to meta.md without checking it held for affine temperatures. Verified on the
reference: `parse("--5 °C")` returned **-268.15 K** instead of 278.15 K. numbat's prefix transformer
rewrites only a negation whose immediate child is the degree multiplication, so `--5 °C` became
`-(from_celsius(-5))` - the outer sign lands AFTER the offset conversion. Fixed with
`collapse_leading_signs`, folding nested negations before the transformer runs. Now `--5 °C` =
278.15 K, `---5 °C` = 268.15 K, `--5 °F` = 258.15 K, and `---2 km` / `--42` unchanged. Fix lives in
`parse_quantity.rs`, not in the repo's transformer.

**This makes the problem HARDER, not easier.** M9 (drop the collapsing - the natural implementation
every agent writes) kills `repeated_signs_resolve_before_a_degree_temperature_converts`. Sign parity
x affine conversion is a genuine composition cell: agents handle repeated signs for ordinary
quantities because nested negations just evaluate, and nothing points at the offset conversion.
That is a second decider alongside the `2 (m/s)` wall, on a different axis.

**All three coverage suggestions taken.** Unary-plus and mixed signs (`++2 m`, `-+-36 km/h`) folded
into the existing sign test; `unit_from("°C")` / `("°F")` rejection given an explicit contract
sentence (it closes an FP hole - an agent could accept it); zero-denominator exponent parity
`unit_from("m^(1/0)")`.

**T1 (base skip) held, and I am not moving again.** This is the fourth position on it. Narrowing to
two skips is what produced round 3's 5/5 baseline failures - every agent deletes that module because
it asserts internal AST snapshots via a test-only `pp` helper and Nova 5 removed `parse_quantity_ast`
outright. Round 4 baseline is 0 failures with the skip. The reviewer downgraded T1 to Medium and
concedes the new suite "duplicates most of those behaviours"; every one of the 12 is now covered
through the public API. Trading a Medium ding for a working batch is the right side of that.

**Adjacency flag: soft, not actionable.** The cited prior art adds a Quantity type to a different VM
with free-form string tags, no registry, no prefixes, whole-number exponents only, no temperature
syntax, and it rejects leading `/`. The report's own conclusion is "different core lessons". Our
differentiators (prefix algebra, exact rational exponents, affine temperature, dimension-vs-unit
annotation, `unit_from` as the inverse of `unit_name`) are all heavily tested already. Not
redesigning on this signal.

Now: 73 tests, base 213, human-effective 284, meta 308 words.

## Hardening round 2 (2026-08-03) - baseline defect fixed + F-1 wall found in a passing patch

**Diagnosis (agent-runs 3).** Feature-only rate 2/5 = 40%, in band, and the round-1 cells worked
(negated-ratio exponent 2 kills, grouped power 2 kills, chained reciprocal 1, negative compound 1,
paren numerator 1). But **5/5 runs failed the SAME 12 baseline tests** - the whole
`parse_quantity::tests` module. 100% of agents failing 100% of a module is an environment defect,
not agent error.

Cause: that module asserts INTERNAL AST Debug output with byte spans via a test-only `pp` helper,
and depends on `is_valid_quantity_literal` / `extract_scalar` / `extract_unit`. Every agent removed
those while rewriting. Nova 5 removed `parse_quantity_ast` itself, so keeping the tests was
impossible - they could not compile. Nova 1 wrote its OWN replacement tests and still scored zero.
Two of five implemented the whole feature (66/66) and were graded 0 purely on this.

**Fix:** base mode skips `parse_quantity::tests` again, and the coverage Auto Review actually wanted
is re-expressed through the PUBLIC api as a true f2p test -
`repeated_leading_signs_are_preserved_on_compound_quantities` pins `--36 km/h` (fails on base),
`--42` and `---2 km` (baseline behaviour preserved). Nothing escapes the gate; agents are no longer
graded on internal test identity. This is the third position I have taken on this skip; it is the
first one that satisfies both the reviewer's concern and the agents' reality.

**★ F-1 convergent-architecture wall, read off a PASSING patch (Stage 3 lever 3).** Both passers
converge on the same design: wrap the input as a STRING and reuse the quantity path. Nova 1:
`let wrapped = if input.starts_with('/') { format!("1 {input}") } else { format!("1 * {input}") }`.
Nova 5 does the same for the reciprocal case. My own reference shares the trick for leading `/`,
which is why that cell stopped killing.

The blind spot: reusing the language parser forces them to cope with numbat reading `1 (m/s)` as a
FUNCTION CALL, so Nova 1 added `normalize_parenthesized_unit_after_magnitude`, which rewrites any
`<scalar>(group)` node into multiplication - and it runs in the `parse` path. So Nova 1 ACCEPTS
`parse("2 (m/s)")`, which base numbat itself rejects ("This expression has type 'Scalar' and can
not be called as a function"). Their architecture over-accepts by EXTENDING the language.
`a_number_juxtaposed_with_a_grouped_expression_is_rejected` pins the repo-consistent behaviour.
Trap-proof M7 reproduces Nova 1's normalizer exactly and the test kills it. This cell kills a
current 66/66 passer.

Fairness: "Writing two unit names next to each other multiplies them" scopes juxtaposition to unit
NAMES (`2` is not one), and "inputs that are not quantity literals stay rejected, including any that
combine or compute quantities" covers a call node. Repo-consistent (L19): base numbat rejects it, so
the test defends existing behaviour rather than inventing a rule. Zero new description words.

**Both coverage suggestions taken (L17).** `binary_prefixes_compose_under_powers_and_denominators`
(`MiB^2/s`, `m/KiB`) and `unit_from_requires_a_concrete_annotation_like_parse_does`. Honest note:
the binary-prefix cell is coverage COMPLETENESS, not a measured lever - M8 (drop the prefix) kills
33 tests, so nothing there is uniquely discriminating. I am not counting it toward difficulty.

**Measured levers after this round:** M1 negated-ratio exponent, M2 grouped-power base, M4 chained
reciprocal, M6 temperature-fn leak, M3+M5 computed exponent, M7 scalar-call normalizer. Six
mutations, six distinct single kills.

**Prediction.** Feature-only was 2/5. M7 kills at least one of the two passers, so 1/5-2/5 is the
expectation, with the baseline noise gone so the headline rate finally equals the feature rate.
Do NOT re-batch on Orion to test this - a stronger model restructures harder and would have hit the
same baseline defect.

Now: 70 tests, base 213, human-effective 262, 3 files, meta 282 words unchanged.

## Hardening round 1 (2026-08-03) - 7/10 too easy -> five orthogonal cells added

**Diagnosis (agent-runs 2, ElementTree).** 7/10 passed. The three failures were scattered
singletons on three DIFFERENT tests (`parentheses_group_a_product_in_the_numerator` x2,
`negative_quantities_parse_including_compound_ones`, `explicit_multiplication_parses_in_compound_expressions`),
and **55 of 61 tests killed nothing**. `unit_from_takes_a_leading_reciprocal`, the wall that
decided the previous batch 0/5, killed ZERO here - the solvability wording worked, and the problem
lost its only decisive lever at the same time. Stage-2 table: "near the ceiling, walls are low"
-> fill F-10 cross-product cells, not new wording.

**Lever: the FP panel's own discriminators.** Four adjudicated false positives among the seven
passes each named a prompt-grounded defect the hidden suite could not see. Each is a composition
of already-stated rules, so all five cells cost ZERO new description words (F-10 economics).

| Cell | Axes crossed | Source | Mutation kill |
|---|---|---|---|
| `m^(-(1/2))`, `m^-(1/2)` | exponent sign x ratio-vs-integer x parenthesisation | Nova 6 + Nova 2 FP | M1 kills 1 |
| `from_celsius(20)` rejected | temperature sugar x computed-input rejection = pre- vs post-transform validation | Nova 4 FP | M6 kills 1 |
| `unit_from("/s/m")` | leading reciprocal x chaining | Nova 1 FP | M4 kills 1 |
| `(m/s)^2`, `(kg)^2` | parentheses x power | Auto Review High | M2 kills 1 |
| `m^(1+1)`, `m^(2*3)` rejected | exponent literal-ness x computed expression | Auto Review High | M3+M5 kills 1 |

The temperature cell is the valuable one: it is the F-1 convergent-architecture wall, observed
rather than guessed. Agents must handle `°C`, which only exists in the POST-transform AST, so the
convergent design pattern-matches the transformed tree - and that design structurally leaks
`from_celsius` / `from_fahrenheit` as literals. The reference validates the RAW pre-transform AST.
Nova 4 passed all 61 tests with this hole.

**Base-mode skip narrowed from the whole `parse_quantity::tests` module to the two obsolete
tests.** This was Auto Review T1 (High, twice) AND the mechanism that hid real regressions: three
FP adjudications found candidates deleting `test_parse_double_negation` /
`test_parse_triple_negation_with_unit` and regressing `--42` / `---2 km`, ungraded because the
whole module was skipped. Base is back to 225 and multi-negation is graded again. That is a sixth
wall, on the baseline-preservation axis, for free.

**Trap-proof (pristine-copy harness, each mutation asserted applied).** M1 negate-arm integer-only
= 1 kill. M2 power base must be a bare unit name = 1 kill. M4 leading reciprocal only when
top-level = 1 kill. M6 whitelist temperature fns as literals = 1 kill. M3 alone and M5 alone were
NO-OPS (computed exponents are doubly guarded in the reference); only the combined over-permissive
form slips through, and that is caught = 1 kill.

**Fairness (Stage 4, all five):** every cell traces to an existing meta sentence - the exponent
grammar sentence covers `-(1/2)` and `m^(1+1)`; "built from unit names, multiplication, division,
parentheses and powers" covers `(m/s)^2` by composition; "accepts exactly the unit expressions a
quantity literal may carry" covers `/s/m`; "Temperatures written with a degree sign are accepted"
plus "inputs that are not quantity literals stay rejected, including any that combine or compute
quantities" covers the `from_celsius` rejection (the adjudicator ruled it prompt-grounded
independently). No new sentence was needed and none was added. Nothing contradicts the repo docs.
All deterministic.

**Predicted effect: honest uncertainty.** Five cells x roughly one-in-three miss each should pull
7/10 well down, but these are near-miss cells rather than architecture walls, and capable agents
may clear several at once. The temperature cell is the one I expect to carry the batch. If the
next run still reads above 40%, the lever is NOT more cells - it is the F-1 wall read off the new
passing patches.

Now: 66 tests, base 225, human-effective 262, 3 files, meta 282 words unchanged.

— numbat-parse-unit-expressions

## Status
Built and clean-room validated. All four pre-check warnings addressed (2026-08-03). The Docker
image cannot be built locally (disk); the Dockerfile was fixed by matching the approved pattern.

## Auto Review round 1 (2026-08-03) - Revision Requested (3/3 desc, 1/3 tests, 0/3 solution)

**S1 HIGH "remove the zero bypass" CANNOT be done as asked.** `numbat/tests/interpreter.rs:1191`
at BASE pins `expect_output("let x: Length = parse(\"0 kg\"); x", "0")` under the maintainer's
comment "Zero is compatible with any type". Removing the bypass fails that base test = a p2p
regression = the exact blocker that stopped two earlier rounds. Resolved the other way: meta.md now
states the exemption ("A zero keeps the exemption it has today and satisfies any annotation") and
`a_zero_satisfies_any_annotation_but_a_nonzero_mismatch_does_not` pins it. It is documented,
repo-consistent behaviour, not an unmet requirement. This is the same wall conceded at build time
for the same reason (L19).

**T4 HIGH (unit_from never tested against + / -): valid, fixed.** Added
`unit_from_rejects_computed_expressions`. Real false-negative hole.

**T4 Low (parenthesised numerator): the suggested test is not valid numbat.** `parse("2 (kg m)/s^2")`
parses as a FUNCTION CALL - `2 (x)` is call syntax, and numbat itself errors "This expression has
type 'Scalar' and can not be called as a function". Rejecting it is correct. Covered the real gap
with `unit_from("(kg m)/s^2")` and `parse("2 * (kg m)/s^2")` instead.

**Baseline blind spot, 5/5 runs: environment, not agents.** Every agent baseline failure was inside
`parse_quantity::tests` - snapshot tests asserting the OLD AST shape, which any legitimate
re-implementation perturbs. 213/225 in the reviewer's own log is exactly that module excluded. Base
mode now skips `parse_quantity::tests` wholesale, replacing the two individual skips. 5/5 agents go
baseline-clean.

**Solvability knife edge.** 0/5, and all five died on `unit_from_takes_a_leading_reciprocal` - a test
added LAST round in response to the previous AI reviewer. Runs 1/2/5 failed on nothing else, so
deleting it gives 3/5 = 60% (too easy) while keeping it silent gives 0% (unsolvable). Fixed by
stating the contract, not the fix: "A leading division is one of those forms, so a reciprocal unit
may be written on its own." The HOW stays hard (numbat cannot parse `/s` standalone, so a workaround
is still required). Expect this to land in band rather than at either extreme.

Also took the conciseness HIGH (dropped the "Today `parse` takes..." sentence). Held the three
mediums/lows - each backs tests.

Now: 61 tests, base 213, human-effective 264, meta 282 words.

## olympus-review self-review (2026-08-03) - REQUEST CHANGE, blocking item fixed

Stage 0 clean. Stage 1 Pattern 22 clean: canonical org is still `sharkdp/numbat` (no move), BASE ==
remote HEAD on `main` so there is zero post-base drift, and no issue or PR exists for `unit_from` or
for compound-unit `parse`. Open PR #836 "Complex number support" does touch `parse_quantity.rs`, but
the diff is snapshot-string churn inside the inline `mod tests` (`Number(1.5)` -> `Number { re, im }`)
with no production code, so exclusivity holds. #847 / #802 / #755 touch `ffi/functions.rs` and
`quantities.nbt` by a line or two each and implement nothing in this capability.

**Blocking (A6/A8, self-inflicted):** `unit_from_rejects_a_mismatched_dimension` asserts a Type
mismatch, and I had deleted "Its dimension must match the annotation too." from meta.md on the
pre-check's MEDIUM suggestion. The remaining dimension sentence sits in the quantity-literal
paragraph and does not reach `unit_from`. This is exactly the A8 pattern (AI suggestions to delete
description sentences are proven regressors). Restored as "Its dimension is checked against the
annotation the same way."

Two further undocumented behaviours found by the same trace, both now stated: whitespace trimming
(`"  100 km/h  "`) and `context_is_not_polluted_by_a_failed_parse`. With the temperature conversion
values that was 3 codebase-inferable requirements against a cap of 1; now 1. meta.md is 317 words.

**LOC correction: 259 human-effective, not 280.** `solution.patch` adds 4 `#[test]` functions inside
`parse_quantity.rs`'s existing inline `mod tests` (17 effective lines). That matches repo convention
and a maintainer would want them, but a reviewer strips test code, so the honest production figure
is 259 across 3 files. Still clears the 200 floor by 30%.

**A5 tension worth naming:** the pre-check pushed the rejection assertions down to bare `is_err`,
which is the WEAK-REJECT pattern the reviewer rubric flags in the other direction. The paired
positive assertion in each test is what keeps them discriminating. `context_is_not_polluted_by_a_
failed_parse` is the weakest test in the file (`is_err` + `is_ok` only).

No dead code: every new function has multiple call sites and the build is warning-free.

## Pre-check round 1 fixes (2026-08-03)
1. **Docker build failed: "rustup could not choose a version of cargo".** Self-inflicted - my
   Dockerfile carried an `ENV RUSTUP_HOME/CARGO_HOME/PATH` block pointing at `/root/.rustup`,
   which is not where `olympus-base-rust` keeps its toolchain, so rustup saw no toolchains and no
   default. `DOCKER.md` states the canonical Rust pattern is "NO ENV block, NO chmod, NO symlink".
   Dockerfile now matches `approved-problems/calyx-unused-port-elimination/Dockerfile` byte-for-byte
   in structure, plus lyon's `chmod -R a+rwX /app` (permitted - only a `/root` chmod breaks the
   solve-time user remap).
2. **Unpinned `cargo install`.** Now `--version 0.1.15 --locked`, with `--locked` on fetch and
   build too. `Cargo.lock` is committed at BASE and clean, so `--locked` is safe. numbat has no
   `rust-toolchain.toml`, so the image default stable is used (repo needs >=1.88, edition 2024).
3. **Over-specific error assertions.** All shape-rejection tests moved from `expect_failure(code,
   "Invalid pattern")` / `"Empty input"` to a new `expect_error(code)` that asserts only that
   interpretation fails. Dimension mismatches keep `"Type mismatch"` (the description states the
   dimension rule) but no longer pin the pretty-printed types (`Length2`, `Length / Time`).
   15 assertions relaxed, 6 message pins left.
4. **`NEW_TESTS` in test.sh was stale** - it listed pre-rename names, so the build-failure fallback
   XML would have reported tests that do not exist. Regenerated from the actual `#[test]` functions
   and diffed to confirm an exact 46-name match.

**Relaxing the assertions cost f2p on 4 tests** and had to be repaired: `3 m^2.5`,
`100 unknown_unit/h`, `unit_from("sin(1)")` and `unit_from("5 km/h")` all fail on base anyway, so a
bare `is_err` passed there. Each was paired (Pattern 74) with a positive assertion on the same
theme - a rational exponent accepted, `100 km/h` converting, `unit_from("m/s^2")`,
`unit_from("km/h")`. Re-verified 46/46 fail on base.

**Residual risk from the relaxation:** a solution that rejects a shape for the wrong reason now
passes those assertions. The paired positive in each test keeps it discriminating, but the FP check
after the first batch should look specifically at the rejection paths.

## Final artifact
- Re-validated 2026-08-03 after the pre-check fixes: base-on-base 227 green, new-on-base 46/46 fail,
  with solution base 229 green + new 46 green, 3x flakiness identical both modes, both patches
  unapply clean back to BASE.
- solution.patch: 3 source files (`numbat/src/parse_quantity.rs`, `numbat/src/ffi/functions.rs`,
  `numbat/modules/core/quantities.nbt`). **human-effective (Counter 2) = 259 production (280 including the inline test module)**, counter1 = 342,
  raw = 439. Clears the 200 floor with a 39% buffer and the >=2 file floor.
- test.patch: `test.sh` (mode 100755) + `numbat/tests/unit_expressions_c41868.rs`, 46 tests.
- Clean room, fresh checkout at BASE:
  base-on-base 227 cases green; **new-on-base 46 cases / 46 failures (per-test f2p aligned)**;
  with solution: base 229 green, new 46 green; both patches apply and unapply in either order.
- Flakiness gate: new mode 3x identical (46/46), base mode 3x identical (0 failures). Deterministic.

## Two design changes forced during the build
1. **The zero rule was conceded and removed.** The design's trap 2 made `parse("0 s")` fail a
   `Length` annotation. `numbat/tests/interpreter.rs:1191` pins the opposite under the comment
   "Zero is compatible with any type" (`parse("0 kg")` as `Length` returns 0). A wall that
   contradicts the repo's own committed behaviour is a fairness bug that happens to be hard
   (failure-patterns L19), so it was conceded rather than argued. The FFI file is now touched only
   by the `unit_from` registration.
2. **`unit_from` was added as the co-equal axis** staged in DESIGN.md section 12. Without it the
   solution measured 188 effective across 1 file, under both floors. It is the inverse of the
   repo's existing `unit_name`, shares all three walks, and its number rule is the exact mirror of
   `parse`'s: `parse` rejects a unit expression with no number, `unit_from` rejects one carrying a
   number. Both rules come out of the same `number_allowed` parameter, so a naive fix to one
   regresses the other.

Also reverted during the build: the unknown-unit error was going to become a NameResolutionError,
which broke `interpreter.rs`'s pinned "Expected unit identifier". Kept the base error surface.

## Test-fairness measures taken
- **Pattern 74 applied to all 12 tests that passed on base.** Seven rejection guards and five
  regression tests were each combined with a new-capability assertion on the same theme, so every
  one of the 46 tests is a true f2p. Verified: 46/46 fail on base.
- **Two giveaways stripped from meta.md after a WHAT-not-HOW audit:** a worked example
  ("one square kilometer is a million square meters") that handed trap 3's answer outright, and a
  clause naming the `unit_from`/`parse` number rules as mirrors of each other, which spotlighted the
  interaction trap 2 depends on the agent deriving. Both rules are still stated separately, so the
  contract stays complete.
- **No test pins a message string this solution invented.** All rejection assertions were softened
  to the error kind ("Invalid pattern"). The only pinned strings are ones base already emits
  ("Empty input", "Type mismatch: expected `X`, got `Y`").

## Pick provenance
Invented from the architecture, not from the issue tracker. Sourced by mapping numbat's
parse -> prefix-transform -> typecheck -> bytecode -> vm pipeline and looking for a stage
boundary where two evaluators read the same model.

## Gate record
- Gate 1 BEHAVIORAL-F2P-GAP: PASS. On base `parse("100 km/h")`, `parse("3 m^2")`,
  `parse("2 kg m / s^2")`, `parse("5 /s")` all raise `Invalid pattern`; `parse("-5 °C")` and
  `parse("5 °C")` raise `Unexpected expression type` from the evaluator after passing validation.
- Gate 4 LOC-CEILING: PASS after the co-equal axis. Measured 188 without it (under floor), 278 with.
- Gate 5 COLD-NOT-LIVE: PASS with a caveat. `parse_quantity.rs` has 5 commits, all 2026-01-25
  (its creation, PRs #796 + #815), and nothing since. Repo-wide last commit 2026-03-13.
  Caveat: the maintainer's own doc comment names "compound units not supported" as a limitation,
  so this is a natural next PR upstream. Re-run the SIX-CHECK immediately before submit.
- Gate 6 REPRODUCE-ON-BASE: PASS, through the real CLI entrypoint (`./target/debug/numbat`).
- Gate 7 DEDUP: ADJACENT, not duplicate, vs our approved `numbat-const-exponents`
  (see DESIGN.md "Why this is not a duplicate").
- Gate 7b EXCLUSIVITY: PASS. `CANON=sharkdp/numbat` (no redirect). PR search across all states for
  "parse quantity" / "compound unit" / "parse function" / "quantity literal": the only hits are
  #796 and #815 (both MERGED, both the single-unit feature that IS the base) and unrelated PRs.
  All 29 open PRs enumerated at hunt time: none touches `parse_quantity.rs`. Contested files to
  avoid: `quantity.rs` (#877/#875/#874 rewrite `full_simplify`), `vm.rs` + `bytecode_interpreter.rs`
  (#750, #712).
- Gate 8 DEFINED-BEHAVIOR: PASS. Issue #813 "Allow `parse` to read in non-scalar quantities" was
  CLOSED as implemented by #815; zero comments, no declination. The unit-expression grammar is
  defined by the language's own existing grammar.
- Gate 9 NO-FLAKY-REPO: PASS. `cargo test --workspace` twice, identical. One deterministic failure,
  `prelude_and_examples::numbat_tests_are_executed_successfully`, caused by a missing tz database
  in the sandbox (`US/Eastern`). Not flaky. The Dockerfile must install tzdata, or base mode scopes
  that test out with the reason documented. Re-verify in-image.
- Gate 10 REPO-QUOTA: PASS. numbat holds 1 of our 6 (`numbat-const-exponents`, approved
  2026-07-09). Not in SATURATED-REPOS.md.

## Open risks
1. **Docker still unverified locally** (no disk). The ENV-block bug that broke the platform build
   is fixed and the file now matches an approved, known-good Rust Dockerfile, but the next platform
   build is the real check. If it fails again, suspect `--locked` (drop it first) or the workspace
   `--tests` build.
2. The three walks are structurally similar; a human reviewer may amortize repetitive breadth.
   Depth comes from the exponent/prefix algebra and the number-position rule, not from three
   parallel match statements, but the shape is a real review risk.
3. meta.md is 290 words, over the 200 recommendation and under the 500 cap. Every sentence
   documents a tested behaviour; trimming would create fairness gaps.
6. **Trap strength is the real open question, not fairness.** Trap 1 (the stage-boundary reshape)
   only fires on degree-sign temperatures, so it rides 3 tests rather than every capability the way
   F-9 did on neva. Trap 3 has a clean correct path: `Product::power` binds the prefix before the
   exponent automatically, so an agent composing through the repo's own algebra never meets it.
   Traps 3 and 4 are self-revealing once their test fails. Expect a first batch at or above 40%;
   if so, the lever is F-1 (what the convergent architecture cannot do), read off the passing
   patches, not more rules.
4. Architecture-jump: blocked structurally. `FfiContext` exposes only `lookup_unit` plus the
   context, so an agent cannot re-enter the interpreter to evaluate the string wholesale.
5. Trap 2 is gone, so the design now rests on trap 1 (transformer reshape), trap 3
   (prefix x exponent), trap 4 (leading division) and the mirrored number rule. If the first batch
   reads above 40%, the F-10 cell to reach for is prefix x exponent inside a denominator.

## Attempt history
(empty — no batch yet)
