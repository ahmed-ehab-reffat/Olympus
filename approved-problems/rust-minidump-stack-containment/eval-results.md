# eval-results.md — rust-minidump-stack-containment

**No agent batch run yet.** All 5 deliverables are complete and locally validated after round 4.
The batch is the only remaining step, and it is the only real difficulty oracle.

Alignment gate (round 5) is clean: every test assertion traces to a `meta.md` sentence and every
described behavior has at least one discriminator. Three defects were found and fixed, including two
enum variants that were unreachable until purpose-built fixtures were written for them.

⚠ Pass-rate risk raised in round 8: naming the full public surface in meta.md (required to clear the
A1 interface-information ERROR) makes more of the task transcribable. The traps live in the ORDERING
(corroboration before containment, declared-end before both) and in the propagation plumbing, none of
which the surface list reveals, but expect the rate to sit higher than it would have. If the batch
comes back over 40%, harden by composition at the axis interaction points, not by removing names from
meta.md - the names are a fairness requirement.

Predicted pass rate: **15-30%** after round 8 (was 10-25% before the surface was named). Three orthogonal axes now, each with a stated precedence rule against the others. Lower confidence than I would like. The honest read is that two
orthogonal axes with a stated precedence rule is a weaker trap structure than the 3+ stacked the
design aimed for, and 213 effective LOC clears the 200 floor by only 13. If the batch comes back
over 40%, the first lever is composition-first re-hardening (test-only) at the axes' interaction
point, not new mechanisms.

## Local verification (reference solution)

| Check | Result |
|---|---|
| Workspace suite, base + new | 290 pass, 0 fail (255 base + 35 new across 2 crates) |
| Base regressions | none |
| insta snapshot churn | none (new JSON keys omitted when there is nothing to report) |
| Determinism | **5x base + new under the reviewer gate, identical every run** |
| Network | not required, runs offline |
| Runtime | ~6s |
| Counter 2 (human-effective) | **313** (floor 200) |
| Counter 1 (auto-block) | 419 |
| Files changed | 9 (1 new, 8 modified), 3 crates |
| Local grading sim | **not run** — user instruction |

## Trap matrix vs HARDENING.md arsenal (round 11, trap-proofed by mutation)

Each trap was checked by mutating the reference into the natural-but-wrong implementation and
re-running the suite. A mutation that still passes means the trap is not discriminated.

| # | Trap | Arsenal class | Catching test | Mutation-proofed |
|---|---|---|---|---|
| 1 | Corroboration must be settled BEFORE containment, and `claimed_trust` records the raised value | **S2** composition of documented rules | `corroboration_does_not_rescue_a_frame_that_left_the_region` | **YES** - moving `degrade_frame` before `promote_frame` fails it (`left: Scan, right: CfiScan`) |
| 2 | A declared end outranks containment, and is checked before the frame is accepted | **S2** | `a_declared_end_outranks_a_frame_that_left_the_region` + 3 more | **YES** - moving the check after acceptance fails 4 tests |
| 3 | The declaration is parsed data, not a rule to evaluate | **S4** machinery-riding (nom parsers, `into_rangemap_safe`, `corruptions_discarded`) | `a_declaration_replaces_the_return_address_rule_rather_than_joining_it` | **YES** - reverting to the naive string-compare design fails it |
| 4 | The answer must survive the CFI strategy being abandoned (`AtomicBool` out through `GetCallerFrameArgs`) | **A7** determination-channel seam | `an_undefined_return_address_ends_the_walk` + 3 more | **YES** - honouring it only when no strategy produced a frame fails 4 tests |
| 5 | Only scanned frames are corroboration candidates | **A6** second-op narrow guard | `only_scanned_frames_are_candidates_for_corroboration` | **NO - UNPROVEN.** Dropping the `Scan` guard still passes 26/26, even after a dedicated fixture that puts a frame-pointer frame on an address carrying CFI. Treat this as decoration until a discriminating fixture exists |
| 7 | `WalkTruncated` is set ONLY for a cut-short walk, so a walk that merely reduced a frame, ended at a declaration, or had no stack memory stays `Ok` | **A8** polarity/boundary inversion | `degradation_is_summarised_over_the_whole_walk` + 3 more assert `Ok` | **YES** - marking truncated whenever anything degraded fails it |
| 8 | The processed output is unchanged for a walk with nothing to report | **S3** baseline-preservation | **11 EXISTING base tests** (`test_json*`, `test_evil_json`, `test_linux_json_pretty`, `test_unloaded`, snapshot suite) | **YES** - emitting the fields unconditionally reds all 11. First trap in the build that reds an existing test |
| 9 | A frame already at the weakest trust is still marked reduced when it leaves the region | **A8** boundary inversion | `a_frame_already_at_the_weakest_trust_is_still_marked_when_it_leaves_the_region` | **YES** - gating the marking on the rank actually dropping fails it |
| ~~6~~ | ~~Adjacency vs total count for consecutive degrades~~ | ~~S2~~ | none | **NO - trap was never real** |

**Trap 6 was removed, and the finding matters.** A mutation replacing adjacency with a running count
passed all 26 tests. The cause is structural, not a missing test: there is one degrade cause
(`OutsideStackRegion`) and stack pointers advance monotonically, so a frame cannot go outside the
region, back inside, and outside again. Non-adjacent degrades are **unreachable**, which made
"consecutive means immediately preceding" dead spec that no test could ever discriminate. The clause
was removed from meta.md and the test renamed to `a_second_reduced_frame_ends_the_walk`.

**Score: 5 of 7 traps mutation-proofed real (1, 2, 3, 4, 7), 1 removed as never real (6), 1 unproven (5).**

Trap 7 arrived by accident and is worth recording as method. A description auto-check called
"leave it `Ok` otherwise" an obvious default and asked for its removal. Deleting the sentence alone
would have orphaned three `CallStackInfo::Ok` assertions, so instead the rule was **restated as a
non-obvious one**: `WalkTruncated` is set ONLY for a cut-short walk, which means a reduced frame, a
declared ending, and missing stack memory all stay `Ok`. Those are three cases an implementer could
each plausibly treat as not-`Ok`. A fourth assertion was added for the reduced-but-not-truncated
case, and the rule now mutation-proofs. **An "obvious default" complaint is often a signal to
sharpen the rule into a discriminating one, not to delete it.** Mutation-proofing is cheap and found two fake traps that
reasoning alone endorsed. Run it on every trap before every batch.

**GAP CLOSED (round 14): trap 8 is the baseline-preservation trap.** It reds 8 existing snapshot
tests. It was already firing before round 14 but was UNDOCUMENTED, which made it a fairness bug
rather than a trap; stating the preservation requirement in meta.md legitimises it.

⚠ **All kill counts on this page are MUTATION counts, not agent kills.** No batch has run. Mutations
measure what the tests can detect, not what agents get wrong (the neva precedent: three hardening
rounds on mutation evidence killed 0 of 10 agents). Treat the whole matrix as a prediction until a
batch closes the loop.

## Round 28 - ARM64 backend coverage (Description 3/3, Solution 3/3 held)

**LAW: a test does not guard YOUR design, it constrains the space of designs that can pass.** I
almost skipped the ARM64 request because containment sits in `walk_stack` AFTER the architecture
returns, making arch-gating structurally impossible IN THE REFERENCE. That reasoning is right about
my code and irrelevant to the task: a solver may put the check inside each backend's
`get_caller_frame`, which passes every x86 and amd64 test and does nothing on ARM. **Whenever the
justification for skipping coverage is "my implementation cannot get that wrong", the coverage is
needed - a different-but-plausible implementation can.**

Added `Arm64Fixture` + `containment_applies_on_arm64_as_well` (frame-pointer chain, caller sp lands
exactly on the region end). **The `claimed_trust` value is the payoff: `FramePointer` on arm64 vs
`Scan` on amd64**, because amd64 reaches that frame by scanning and arm64 by the fp chain. Three
backends now enter the same containment rule by three different provenance paths, and arm64 is the
only one where `claimed_trust` visibly differs from the reduced trust. I guessed `CallFrameInfo`,
probed, and corrected - **probe the value, never guess it into an assertion.**

Declined again with reasons recorded: scan corroboration on a second backend (same shared-loop
position, now 3-backend covered), `FrameTrust` ordering (private `trust_rank`, no public `Ord` -
fourth refusal on identical grounds), and a real `.ra: .undef` walk through the processor (needs a
module + matching symbol file inside the synth dump; flagged as the likeliest item to return).

Verification: base 255/0, new **49**/0, 5x flakiness identical, f2p both directions with identical
name sets, human-effective 327.

## Round 27 - Solution 3/3 held; JSON prefix edge + description density

**LAW: a summary field asserted only at its IDENTITY value (0, empty, None) is not tested.** Every
processed-output fixture degraded frame 0, so `trusted_prefix_len` was only ever serialized as 0 - a
serializer hard-coding `json!(0)` passed everything. `trusted_prefix_len()` DID have nonzero coverage
on the core API, and that is precisely why the JSON gap survived: **coverage of a helper does not
carry across a serialization boundary.** Added
`the_processed_output_counts_the_trusted_frames_before_the_reduced_one` (clone the context frame so
an undegraded frame precedes the reduced one). Mutation-proofed: `json!(0)` fails exactly it.

Same family as the round-26 finding, different mechanism: R26 was two conditions coupled in one
fixture, R27 is one field pinned at one value across every fixture. Both let a wrong implementation
through. **Sweep: for each field, list the distinct VALUES any test asserts. One distinct value at
the identity is a gap.**

P4 density: meta restructured from 7 dense paragraphs to 13 single-topic ones. Word count unchanged
(523), all 37 named symbols/tokens verified still present by script, 0 headers, ASCII. No bullets or
headers added - the reviewer offered a flat list, but headers are banned and the approved set is
plain prose, so shorter paragraphs deliver the same scannability without risking the format rules.

Verification: base 255/0, new **48**/0, 5x flakiness identical, f2p both directions with identical
name sets, human-effective 327.

## Round 26 - Description 3/3, Solution 3/3, two test branches added

Tests 1/3 on two verified High gaps. No source change needed; the reference already did the right
thing in both cases, but nothing tested it.

| Gap | Wrong impl that would have passed | New test |
|---|---|---|
| Contradiction tested only as `.undef` then computed | a parser that rejects only undefined-first | `a_row_that_computes_before_declaring_is_discarded_too` |
| Reduction text tested only on a `LeftStackRegion` walk | printing reduction only inside `termination != Exhausted` | `a_reduced_frame_is_surfaced_even_when_the_walk_ended_plainly` |

Both mutation-proofed against exactly those implementations; each fails its own test and nothing else.

**LAW: a test that exercises two conditions at once cannot show they are INDEPENDENT.** Both gaps
have the same shape - the interesting property travelled with a second property in the only fixture
covering it, so a coupled implementation passed. **When a rule says X happens regardless of Y, one
test needs X with Y and another needs X without Y.** The JSON surface already had that pair (round 25
added reduced-but-Exhausted); the text surface did not, and neither did the parser's token order.
Check every "regardless of" and "independently of" clause in meta for its second fixture.

Running count of what automated review has found that mutation testing did not: a machinery-riding
semantics bug (R23), a whole-record-vs-per-address model error (R24), a root-only harness (R24), two
undiscriminated spec divergences (R24, R25), and now two coupled-fixture blind spots (R26). Mutation
testing only probes code paths the tests already reach; it cannot see a branch no fixture creates.

Verification: base 255/0, new **47**/0, 5x flakiness identical, f2p both directions with identical
name sets, human-effective 327.

## Round 25 - grader PASS, fairness closed by STATING not deleting

Grader: **PASS**, code quality **3/3**, comprehensiveness 2/3. Fairness: FAIL on 1 of 43.

**The one unfair test was `walk_result_is_deterministic_across_repeated_walks`, and I nearly deleted
it.** An earlier reviewer had called it shallow, which made deletion feel justified. It was not:
determinism is a WHAT, so it belongs in meta like every other contract, and deleting an assertion is
also the option that quietly lowers difficulty. Added one sentence, restored the test unchanged.

**LAW (now three-for-three on this build): an unfair assertion is a MISSING DESCRIPTION SENTENCE.**
R18 the repo already named the thing (`.undef`) so the TEST changed; R21 and R25 nothing named it so
META changed. Deletion has still never been the right answer here. A prior "shallow" note from a
different reviewer is not a licence to drop a test that a description sentence would make fair.

**Comprehensiveness 2/3 - frame-limit boundary.** The cap was checked BEFORE the push, so
`FrameLimit` only fired when a 1025th frame was attempted; a walk exhausting exactly at 1024 reported
`Exhausted`. Moved the check after the push. **Not discriminated by any test** (both orderings give
`frames.len() == 1024` + `FrameLimit` on the looping fixture) - same category as the round-24 degrade
latch: spec-conformance with zero new discrimination.

**Two undiscriminated spec fixes in two rounds is worth noticing.** Reviewers find divergences
between the description and the reference that NO test can see. They are still worth fixing (a solver
reading the spec could implement the other behaviour and be judged wrong), but they must not be
logged as traps.

Interface WARNING closed by naming what `CallStack::print` puts in the text (reason token + claimed
trust description) and noting the processed threads ARE these call stacks.

Coverage: +2 tests (43 -> 45) - reduced-but-not-truncated processed output, and the same-row
contradiction on a DELTA row rather than INIT.

Local verification: base 255/0, new 45/0, **5x flakiness identical**, f2p both directions with
identical name sets, human-effective **327**, meta exactly **500/500** words.

## Auto Review round 24 - harness Blocker + two semantic bugs

Bands: Description **3/3**, Tests 0/3 (Blocker), Solution 1/3. All addressed.

**Blocker (T6): the harness only ran as root.** `test.sh` prepended `/root/.cargo/bin` and the
Dockerfile left cargo2junit and the registry cache in root's home. The grading sandbox is offline and
non-root, and cargo needs WRITE access to `CARGO_HOME` for its package lock even with `--offline`.
Fixed by dropping the `/root` line, setting `CARGO_HOME=/opt/cargo`, installing cargo2junit with
`--root /usr/local`, and `chmod -R a+rwX /opt/cargo /app`. `RUSTUP_HOME` untouched - moving it is the
legacy mars-base pattern with a documented 0/10 permissions failure. **Owed to the platform run.**

**S1 (real bug): end-of-stack was a WHOLE-RECORD verdict, not per-address.** INIT `.ra: .undef` plus
any later delta with a return address was discarded as malformed, when the description says a later
record REPLACES an earlier rule. Rewritten as `end_of_stack_ranges`, walking rows in address order
and emitting declared ranges only for spans where `.undef` is still in force. Mutation-proofed by 2
tests.

**LAW: a test that passes through a FALLBACK path is not testing the primary path.** The existing
replacement test passed for the wrong reason for five rounds - its fixture left frame-pointer data,
so after the record was discarded, fallback unwinding produced a caller and satisfied
`frames.len() > 1`. The assertion was too weak to notice the record had been thrown away. Fixed the
fixture so the CFI rule must compute the answer, and pinned `trust == CallFrameInfo` so no fallback
can ever satisfy it. **When a feature adds a strategy to a CASCADE, assert the TRUST/provenance, not
just the result - otherwise a lower strategy silently covers for the broken one.**

**S1 (spec conformance, NOT observable): degrade latch.** `DegradeRun` reset on a contained frame;
the description says stop before a second reduced frame anywhere. Changed to a non-clearing latch.
**Mutating it back to adjacency still passes all 43** - confirming the round-11 finding that
non-adjacent degrades are structurally unreachable (one degrade cause, monotonic stack pointers).
Correct against the spec, zero discrimination gained.

Tests 39 -> 43: later-`.undef` replacement, entering before the replacement address, and positive
`CallStack::print` text for `FrameLimit` and `NoStackMemory`.

Local verification: base 255/0, new 43/0, **5x flakiness identical**, f2p verified in both directions
with identical name sets, human-effective **327**.

## Auto Review round 23 - first real CODE defect

Bands were Description 2/3, Tests 1/3, Solution 1/3. All three addressed; verified locally.

**S1 (High, real bug):** `classify_end_of_stack` read only the FIRST `.ra:` in a rules row via
`split_once`, so `.ra: .undef .ra: .cfa 4 - ^` was accepted as a clean declaration instead of
discarded as contradictory. The repo's own evaluator honours the LAST assignment when a register is
assigned twice, so the classifier contradicted the machinery it rides. Fixed by collecting every
return-address assignment.

**LAW: a bug in the half of a feature that RIDES existing machinery survives every fairness and
coverage check.** Five rounds of automated review passed this. Fairness checks ask whether the tests
match the description; coverage checks ask whether the description is tested. Neither asks whether
the implementation matches the REPO SEMANTICS it is reusing. When a design deliberately rides an
existing mechanism (S4 machinery-riding), diff your semantics against that mechanism's own rules by
hand, at design time.

**Suite 35 -> 39 new tests**, closing 4 High false-negative gaps: exact 1024-frame cap, same-row
contradiction, delta-to-delta return-address replacement, positive degraded JSON, and the three
non-default termination tokens in processed output.

| New mutation proof | Result |
|---|---|
| Drop the same-row contradiction check | `a_record_that_declares_and_computes_in_one_row_is_discarded` fails, nothing else |
| `MAX_WALK_FRAMES` 1024 -> 1000 | `a_walk_that_never_ends_is_stopped_at_the_frame_limit` fails |

**test.sh enumerator: the helper DENYLIST failed a second time.** Renaming one helper and adding
another put the fallback count at 41 vs 39 real tests, reproducing the round-19 wrapper defect.
Replaced with attribute-based detection (`grep -A 1` on `#[test]`/`#[tokio::test]`). A denylist of
helper names is not maintainable; enumerate by the test attribute instead.

Local verification after the round: base 255/0, new 39/0, **5x flakiness identical**, f2p name sets
identical between base-source and solution runs, human-effective **317**.

## Fairness + interface gate (round 22)

Second fairness pass: **FAIL, 2 of 36 unfair**, plus an interface **ERROR**. All three were
description gaps. Zero test changes, zero solution changes.

| Report | Root cause | Fix |
|---|---|---|
| Interface ERROR | `.ra: .undef` asserted by tests, never named in meta. A1, fourth occurrence on this build | State the token + INIT/delta replacement precedence |
| Unfair: frame limit | Test pins the cap under ~131,072 via a 1 MiB fixture; meta said only "as many frames as the walk is willing to record" | State the cap: 1024 frames |
| Unfair: JSON summary keys | Plain-walk test asserts absence of `degraded_frame_count` / `trusted_prefix_len` / `degrade_reasons`; meta named two as APIs only and never named `degrade_reasons` | State the three output keys and their conditional omission |

**The frame-limit one is the reusable finding: a FIXTURE SIZE can silently encode a numeric policy
the description never states.** The test looked spec-driven because it asserts only the termination
variant, but the 1 MiB stack is what forces the cap under 131,072. Any test whose outcome depends on
a bound the description leaves open is unfair, even when no number appears in the assertion. Check
every fixture dimension against the spec for implied bounds.

**Difficulty cost, stated honestly:** naming the cap makes the frame-limit rule fully transcribable.
The only fair alternative was rebuilding the fixture so no permitted cap can reach the region
boundary, which needs a build. Traps 1, 2, 3, 4, 7, 8 and 9 are untouched.

## Fairness gate (round 21)

Test-fairness check: **FAIL, 1 of 35 tests unfair.** Fixed by adding a sentence to meta.md, not by
touching the test.

| | |
|---|---|
| Flagged | every unreduced frame's `claimed_trust` equals its current `trust` (`stack_containment_d57b13.rs:199`) |
| Why unfair | meta.md specified `claimed_trust` only for REDUCED frames. No prior repo field or default convention. `Option<FrameTrust>` populated only on reduction was an equally reasonable implementation, and the test pinned the non-optional one |
| Fix | meta.md now states that every frame carries a `claimed_trust` holding its pre-reduction trust, so an unreduced frame reads the same as its current trust |
| Cost | 0 test changes, 0 solution changes, +30 words (466 -> 496 of 500) |

The other 34 were rated Prompt-stated, Repo-discoverable, or standard external semantics. The
checker's summary also called the suite deterministic and free of brittle full-output snapshots.

**The lesson generalises: an unfair assertion is a missing description sentence far more often than
a bad test.** Both of this build's fairness failures resolved that way. The earlier one was the
opposite mistake in the same family: I had invented a `.ra: .undefined` token when the repo already
parsed `.undef`, and switching to the repo's own token turned 7 unfair tests fair with no meta
change. So the pair of rules is: if the repo already names it, use the repo's name; if nothing names
it, name it in meta.md. Deleting the assertion is the last resort, because it is also the option
that quietly lowers difficulty.

## Trap reproduction results (earlier rounds)

Reproducing traps against the real suite before batching is what caught all of this.

| Trap | Class | Designed effect | Measured | Verdict |
|---|---|---|---|---|
| A: degraded trust must be what the rest of the walk observes | S6 | narrows next frame's search | holds, but is the only surviving axis | alive, insufficient alone |
| B: corroboration policy on the repo's permissive helper | S5 | wrong policy degrades everything | v1 all-frames: 8 base tests red. v2 scanned-only: unreachable dead code, scan already refuses unnamed addresses. v3 module-membership: 5 base tests red | **DEAD, removed** |
| C: degraded value leaking into the leaf carve-outs | S3 | `arm64`/`arm` leaf tests go red | never fires; the check runs after the architecture returns, so the leaf channel never sees it | **DEAD by construction** |
| D: consecutive vs total degrade count | S2 | adjacency confusion | real but is bookkeeping, not a mechanism | weak |

The C result is the instructive one: placing the check after the architecture returns is what makes
the design correct and is also what makes trap C impossible. Those two goals were incompatible and
the R2 design did not notice.

## If the end-of-stack axis is added

Re-measure before batching:
- Counter 2 must clear 200 with margin (target 280+)
- full suite green, 3x, offline
- reproduce the new interdependency: a frame sitting at an end marker is inside the region and
  undegraded, so a containment-only implementation must be shown to walk straight past it
- only then spend a batch
