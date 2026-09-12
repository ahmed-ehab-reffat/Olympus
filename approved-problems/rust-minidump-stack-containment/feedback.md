# feedback.md — rust-minidump-stack-containment

Repo: rust-minidump/rust-minidump (MIT, 505 stars, Rust)
Base: `0155eaf70114f5ed3cbb172968eceaf6106940f7` (2026-07-27)
Tier: Olympus. Category: feature-request (changed round 8, see below).

## STATUS: all 5 deliverables complete, all auto-check findings resolved. Owes only the agent batch.

### Round 20 (wrapper identity, corroboration blind spot, positive JSON) + olympus-review

**The wrapper FAIL was a test-identity mismatch, not a set-membership one.** All 34 names appeared in
`failToPassTests`, yet the wrapper still reported them as belonging to neither set. Cause: cargo2junit
emits `classname=""` and suite `cargo test #0`, so ids are the bare test names; my build-failure
fallback emitted `classname="stack_containment_d57b13"`, producing `stack_containment_d57b13.<name>`
ids that matched nothing. The fallback now mirrors cargo2junit's shape exactly. Verified by diffing
the name sets from both states: identical, 35 each.

**Grading blind spot fixed (2/3 -> expected 3/3 on both axes).** The grader found that
`UnwindInfoProbe` only latched on `set_cfi_rules_start_address`, so a scanned frame landing on a
range covered *only* by an end-of-stack declaration was never promoted to `CfiScan`, even though such
a declaration is published unwind information too. The probe now latches on `set_end_of_stack` as
well. This was a genuine narrowness in the abstraction, not a test gap.

**Positive processed-output coverage added.** `a_thread_without_usable_stack_memory_reports_its_termination_in_the_processed_output`
builds a synth dump with a zero-length stack, so the walk terminates `NoStackMemory`, and asserts the
JSON carries `"termination": "no_stack_memory"`. That closes the "omission tested, presence not"
WARNING raised by two separate checks.

**Pre-submit olympus-review, all stages:**

| Stage | Result |
|---|---|
| 0 hard-block | clean: no em dashes, ASCII meta + patches, no banned markers, `test.sh` 100755, no smart quotes |
| 1 exclusivity | canonical org re-resolved; only open unwind PR is #1162, overlap still zero files |
| 2 cross-check | A1 clean: every symbol and token asserted in either test file appears in meta.md |
| 4 description | first body sentence reads as the ask; 466/500 words; 0 `##` headers; 0 AI-cadence hits |
| 5 flakiness | **5x base + new, identical every run**: base 255/0, new 35/0 |
| 6 solution | 0 debug statements, 0 TODO/FIXME, 9 files, 3 crates, **0 architecture files** |

**Post-round-20:** human-effective **313**, counter1 419, 35 new tests across 2 crates, 255 base.

### Round 19 (remaining coverage: amd64 + processed output)

**Non-x86 coverage.** `containment_applies_on_amd64_as_well` walks an amd64 fixture whose frame
escapes the region. Worth noting what it revealed: on amd64 that frame is recovered by *scanning*,
not the frame-pointer path, so the test also exercises trap 9 (already-weakest trust still marked)
on a second architecture rather than merely repeating the x86 case.

**Processed output.** `minidump-processor/tests/walk_output_d57b13.rs` builds a synthetic minidump
via `minidump-synth`, runs the real `process_minidump`, and asserts the JSON for a plain walk carries
no `termination`, `degraded_frame_count`, `trusted_prefix_len` or `degrade_reasons`, and no
per-frame `trust_degraded` / `claimed_trust` / `degrade_reason` while `trust` remains.

**Two f2p defects this surfaced, both fixed:**

1. The processor test initially **passed on base source** - an absence assertion is trivially true
   before the feature exists, so it could never be an f2p test. Fixed by anchoring it to
   `CallStack::termination`, an API that does not exist on base, so the target fails to compile there
   and the whole file lands in the f2p set legitimately.
2. The build-failure fallback enumerated only the unwind test file, so base-source `new` reported 33
   cases while the solution run produced 34 - the same "test in neither set" defect the wrapper
   flagged originally, reintroduced by adding a second test file. The fallback now reads both files.

**Verified:** base source `new` = **34 cases, 34 failures**; with solution `new` = **34 cases, 0
failures**. Sets match exactly. Base 255/0 in both states.

**Post-round-19:** 34 new tests across 2 crates, 255 base, human-effective 311, counter1 416,
flakiness 3x identical.

### Round 18 (fairness FAIL fixed at the root, wrapper f2p, grading 3/3, coverage)

**The fairness FAIL (8 of 29 tests unfair) had one root cause and it was mine.** I invented the
symbol token `.undefined`. The repo already ships `.undef`, documented at
`walker.rs:261` as "terminate execution, the output is explicitly unknown", implemented at
`walker.rs:706`, and already exercised by an existing base test
(`build_cfi_rules(".cfa: 8 .ra: .undef", ...)` at `walker.rs:1694`). Seven tests were therefore
pinned to an author-chosen spelling that **contradicts the repo's own token** - exactly the L19
fairness bug ("a wall that only stands because it contradicts the published book").

Fixed at the root by switching the feature to `.undef` rather than by documenting `.undefined` in
meta. That makes the syntax repo-discoverable instead of author-invented, and it lands the feature
on a token whose existing meaning ("no caller") is precisely what issue #1002 asks to honour. All
seven tests become fair with no meta change. Workspace stayed green, including the pre-existing
`.ra: .undef` unit test.

**Eighth unfair test: the frame limit.** Its fixture advanced ESP by 8 across a 32 KiB region, so
containment would fire after ~4096 frames - silently requiring the cap to be below that. Widened the
region to 1 MiB so any plausible cap fires first, removing the unstated upper bound.

**Wrapper f2p defect.** Without `solution.patch`, the build-failure fallback emitted a single
synthetic `cargo-test.compilation` case that belonged to neither the regression set nor the new-test
set. The fallback now enumerates the real test names from the test file and reports each as failed,
so the base-source run yields **32 failing cases with the same names** as the 32 that pass with the
solution.

**Grading feedback (2/3 on both axes) fixed.** The grader was right: `CallStack::print` only reported
termination for truncated walks, so `EndOfStack` and `NoStackMemory` were silent even though meta
requires surfacing "where there is something to say". The gate is now
`termination != Exhausted`. Also removed the unused public `declares_end_of_stack` helper the grader
flagged as unnecessary surface.

**Coverage suggestions added:** every `WalkTermination::description` is non-empty and distinct from
its token; an empty stack-memory range yields `NoStackMemory`/`Ok`/no degradation (previously only
`stack_memory = None` was covered); and a declared end is surfaced in printed output despite not
being a truncation - which is the regression test for the print fix above.

**Post-round-18:** 32 new tests, 255 base, human-effective 311, counter1 416, meta 466 words,
flakiness 3x identical, zero `.undefined` left anywhere.

### Round 17 (Docker fix #2 + the frame-limit threshold)

**`--locked` on `cargo install cargo2junit` was the second build failure, and my own memory note
caused it.** Reproduced locally rather than guessing:

| Invocation | Result |
|---|---|
| `cargo install cargo2junit --version 0.1.13 --locked` | **fails** - `error: could not compile time (lib)`, E0282 |
| `cargo install cargo2junit --version 0.1.13` | **installs cleanly** |

cargo2junit 0.1.13 ships a lockfile pinning an old `time` crate that no longer compiles on modern
rustc. `--locked` forces that lockfile; without it cargo resolves a `time` that builds. A prior note
in memory said "--locked pins pre-edition2024 deps; version alone is NOT enough" - that was for a
different failure mode on an older base image and is now actively wrong. Corrected there.

`--locked` is retained on `cargo fetch` and `cargo build` for the REPO, which is where `Cargo.lock`
is committed and where reproducibility actually matters. So the version-pinning warning stays
addressed.

**Frame-limit WARNING.** The test asserted `frames.len() > 1000` while meta deliberately leaves the
cap unspecified, so an implementer choosing 256 or 512 would fail a rule that was never stated. Fixed
by **relaxing the test** (it now asserts only `FrameLimit` termination and the truncated status), not
by putting a number in meta - a threshold there would be leaking a test detail into the description.

**Test-leak scan of meta.md: clean.** No test names, file names, assertions or fixture references.
Everything named is public API or an observable behaviour, which A1 requires.

### Round 16 (Docker BLOCKER + cargo2junit revert-trigger + review items)

**The Dockerfile did not build, and reading `DOCKER.md` showed two separate hard problems, both
mine.**

1. **Wrong pattern.** My Dockerfile carried the legacy `mars-base` Pattern A (ENV block, `chmod -R
   a+rX /root`, symlink loop). `DOCKER.md` says in bold: **NEVER `chmod -R a+rX /root` on
   `olympus-base-rust`** - it leaves registry files root-owned and breaks the platform's solve-time
   user remap, which took `nickel-enum-widening` to 0/10 as a permissions blocker. The symlink loop
   is what produced the observed `rustup could not choose a version of cargo to run`. Replaced with
   the canonical four-line recipe: no ENV, no chmod, no symlinks.

2. **`test.sh` was using the documented hard-revert trigger.** My hand-rolled JUnit emitter wrote
   `<failure message="test failed">`, which is the exact placeholder that got **two** Rust
   submissions reverted, one of them after a clean 20% batch. `DOCKER.md`: "a passing eval does NOT
   save it." The bash/regex approach also miscounts across multiple test binaries, and base mode
   here runs four targets. Rewritten to `cargo2junit` fed from libtest json
   (`RUSTC_BOOTSTRAP=1` + `-Z unstable-options --format json`), exit code taken from cargo rather
   than the pipe, build-failure fallback retained.

   Verified locally, no Docker needed (`cargo2junit` was already installed): forcing a failure now
   emits per-test names and the real assertion text, not the placeholder.

3. **Version-pinning warning** was a false positive - `Cargo.lock` is committed. Added `--locked` to
   `cargo install`, `fetch`, `build` and `test` anyway so reproducibility is explicit rather than
   incidental. `cargo2junit` pinned to `0.1.13 --locked` because later versions need `edition2024`,
   which the base image's cargo does not have.

**Review items:** the internal-API prescription (`FrameWalker::set_end_of_stack`) and the
`MAX_WALK_FRAMES` constant name were removed from meta.md, with the frame-limit test changed to stop
referencing the constant. The redundant half of the corroboration sentence was trimmed, keeping only
the non-obvious discriminator. The print-string WARNING (raised by two separate checks) was fixed by
**loosening the tests** rather than pinning prose: they now assert on `outside_stack_region` and on
`WalkTermination::description`, both specified in meta, instead of English phrases like "Trust
reduced from". `WalkTermination::description` had to be named in meta - A1 biting a fourth time.

**I did not remove "in the processed output"** (the LOW suggestion). That phrase is trap 8's
contract; without it the 11 base-test kills become an unstated rule, which is the round-14 fairness
bug all over again. Keeping it is a deliberate, recorded decision.

**Post-round-16:** human-effective **315**, counter1 422, 29 new tests, 255 base, meta 466 words,
flakiness 3x identical, f2p correct both directions under the new runner (base source: base 255/0,
new 1 case `compilation` failure).

### Round 15 (coverage WARNING + description request_changes + differentiation)

**The two reviews conflicted, and resolving the conflict was the whole round.** The description
check (HIGH) wanted "leave that output exactly as it is today for a walk that has neither" deleted
as a generic don't-break directive. But that sentence is what makes trap 8 fair - without it agents
die on 11 base tests for an unstated rule. The coverage check pointed at the real problem: the
requirement was **stated but never tested**.

Resolved by making it specific and verified rather than deleting it:
- Reworded from a preservation directive to a positive output contract: the termination and the
  per-frame reduction appear "each only where there is something to say: a walk that ended plainly
  and reduced nothing carries neither."
- Added two tests that actually exercise the surfacing channel:
  `a_reduced_frame_and_a_cut_short_walk_are_both_surfaced` and
  `a_walk_with_nothing_to_report_carries_none_of_those_lines`.
- Trap 8 re-verified after the rewording: the unconditional-emission mutation still kills **11**
  base tests (the earlier count of 8 was my `head -8` truncating the list, not a real number).

**Other suggestions applied as given:** removed the current-behaviour sentence ("Today the walker
takes each unwinder's report at face value..."), removed "Build it over the existing strategies",
removed "derived from that stack memory".

**One addition the FP check forced:** the new tests call `CallStack::print`, a pre-existing public
method. Naming it in meta.md was required by the same A1 / `CommandError` rule that has now bitten
three times in this build. meta.md names it.

**Is Adjacent shippable? Yes, per the instructions - checked, not assumed.**
`PICK-FILTER.md` Gate 7 lists the verdict tiers as Duplicate-block / Derivative-near-reject /
**Adjacent-clears** / Clear, with `expr-switch` named as a pick that cleared as Adjacent. The same
file lists "moves dedup Derivative->Adjacent" as the goal of a scope-invent lever, so Adjacent is the
documented target state, not a warning. `CLAUDE.md`'s similarity HARD RULE is scoped to *derivative*
findings. Every kill in the record was a harder verdict: lol-html `duplicate` 0.80/0.91, orb
`derivative`, async-graphql `Derivative 88%` - and that last one ALSO carried a 78%
`similar_idea`/Adjacent candidate which was not the killer. Our Adjacent is the verdict-driver (five
candidates, nothing worse in the set) and the judge says the two "should coexist". **No further
differentiation work is required by the rules; stop here.**

**Differentiation status.** The dedup verdict improved materially: the earlier one listed three
shared APIs and three shared behaviours; the current one lists **one** shared API (the `walk_stack`
flow) and **zero** shared behaviours, and concludes the two "should coexist". Round 9's induced
difference did the work. The remaining overlap is structural and irreducible - any change to frame
acceptance has to touch `walk_stack`. Round 15's new tests also push further into the surfacing
channel, which the candidate does not touch at all (it changes arch scanners and adds
`walk_stack_with_memory_info`).

meta.md 454 words. 29 new tests + 255 base green, flakiness 3x identical, human-effective 312.

### Round 14 (olympus-harden: baseline-preservation trap, orthogonal trap, WHAT-not-HOW)

**Stage 1 evidence: there are NO agent runs.** Everything below is PREDICTED, not measured. Kill
counts are mutation counts, which measure what the tests can DETECT, not what agents get WRONG. The
skill is explicit that only a batch closes the loop, and the neva precedent (three hardening rounds
on mutation evidence, 0 of 10 agents killed) is the reason to say so plainly.

**Diagnosis: the baseline-preservation trap already existed and was UNFAIR.** Emitting the new
output fields unconditionally reds 8 existing snapshot tests
(`test_json`, `test_json_pretty`, `test_json_stable_all`, `test_json_unstable_all`, `test_evil_json`,
`test_json_symbols`, `test_linux_json_pretty`, `test_unloaded`). The reference already avoided this
by omitting keys when there is nothing to report, but **meta.md never stated the preservation
requirement**, so an agent could be killed by 8 base tests for a rule the description did not
contain. That is a fairness bug that happens to be hard, not a trap.

**Lever 1 (trap 8, S3 baseline-preservation).** Added the contract sentence: leave the processed
output "exactly as it is today for a walk that has neither". Now contract-stated, and the 8 base
kills are legitimate. This is the first trap in the whole build that reds an EXISTING test - the gap
flagged since round 2 is closed.

**Lever 2 (trap 9, orthogonal, A8 boundary).** A frame already at the weakest trust that leaves the
region must still be recorded as reduced, even though its trust value does not change. Different
axis from every existing trap: not ordering, not termination, not output. Contract sentence: "mark
it reduced even when it was already worth no more than that". Mutation-proofed - gating the marking
on the rank actually dropping fails
`a_frame_already_at_the_weakest_trust_is_still_marked_when_it_leaves_the_region`.

**WHAT-not-HOW pass.** Removed two prescriptions that named implementation steps rather than
behaviour, keeping the observable consequence each one implied:
- "recognise it when the file is read, keep it apart from the unwind rules, and answer it before any
  strategy is tried" -> deleted. The consequence ("a walk reaching one ends there even when another
  strategy could have produced a frame") already carries the discriminator for traps 2 and 4.
- "Corroboration is settled before the region is considered" -> deleted. The consequence ("a frame
  raised and then found off the stack is still reduced, and the raised value ... is what gets
  remembered as its claim") already carries trap 1's discriminator.

Both deletions were FP-rechecked: no assertion lost its sentence.

**Post-round-14:** human-effective **312**, counter1 419, 27 new tests, 255 base, meta 477 words,
flakiness 3x identical, clean-room f2p correct both directions, 0 architecture files touched.

**Trap scoreboard: 7 of 9 mutation-proofed real** (1, 2, 3, 4, 7, 8, 9), 1 removed as never real (6),
1 unproven (5).

### Round 13 (the `Ok` rule restated instead of deleted, and it became a real trap)

Round 12 obeyed the auto-check literally: it deleted "leave it `Ok` otherwise" and removed the three
`CallStackInfo::Ok` assertions that depended on it. That kept FP clean but threw away coverage.

Restated instead. The check's objection was that the sentence was an obvious default, and it was.
So the rule was sharpened into a non-obvious one: **`CallStackInfo::WalkTruncated` is set ONLY for a
cut-short walk, so a walk that merely reduced a frame, ended at a declaration, or never had stack
memory stays `Ok`.** Those are three outcomes an implementer could each plausibly treat as not-`Ok`,
which is precisely what makes the rule worth stating.

All three assertions are back, plus a fourth for the reduced-but-not-truncated case that was
previously untested. **The rule now mutation-proofs**: marking a walk truncated whenever anything
degraded fails `degradation_is_summarised_over_the_whole_walk`. It is logged as trap 7.

**Method note worth keeping: an "obvious default" complaint is often a signal to sharpen a rule into
a discriminating one, not to delete it.** Deleting cost coverage and gained nothing; restating cost
20 words and gained a mutation-proofed trap.

meta.md 486 words, still under the 500 hard cap. FP clean both directions, 26 new + 255 base green,
flakiness 3x identical, f2p correct both ways.

### Round 12 (test.sh exit-code bug + description request_changes)

**Real bug fixed in `test.sh`.** Base mode ran five `cargo test` invocations inside one brace group
and captured only `STATUS=$?` from the last, so a regression in any earlier command was silently
masked. Replaced with a loop that ORs each failure into `STATUS`. Proven, not assumed: breaking an
early target now exits 1 where it previously exited 0.

**Description review returned request_changes with 5 suggestions. Three applied as written, two
needed care because they collided with the FP check:**

| # | Suggestion | Action |
|---|---|---|
| HIGH | drop "without changing the scanning loops" and the trailing "decide everything from..." clause | applied. The kept memory-maps/page-permissions clause still carries the differentiation from the Adjacent candidate |
| HIGH | drop "The existing `FrameTrust` values keep their meaning," | applied, keeping "`CfiScan` sitting between `Scan` and `FramePointer`" - that clause is the only thing naming `FramePointer`, which two tests assert |
| MED | drop "omitting absent ones" | applied. With one `DegradeReason` variant this was unobservable anyway, the same dead-spec shape as the removed trap 6 |
| MED | drop "and leave it `Ok` otherwise" | applied **plus** removed the three `assert_eq!(s.info, CallStackInfo::Ok)` assertions. Dropping the sentence alone would have orphaned those assertions and re-broken FP direction one, which is exactly the gap round 10 fixed |
| LOW | drop "and leave that frame out of the result" | **reworded, not deleted**: "Stop the walk before recording a second reduced frame." `a_second_reduced_frame_ends_the_walk` asserts `frames.len() == 2`, so the exclusion has to stay described; the rewrite removes the redundancy the reviewer objected to while keeping the discriminator covered |

**meta.md is now 466 words, back under the 500 hard cap** - the earlier overage justification is no
longer needed. FP re-verified both directions after every edit. All 26 new tests and 255 base tests
green, flakiness 3x identical, f2p correct in both directions with the new base runner.

⚠ Environment note: a `cargo test` run failed mid-session with "failed to download addr2line" under
`--offline`. Not a code fault - a transient dependency-cache miss, cleared by `cargo fetch`. The
Dockerfile already runs `cargo fetch` at build time, so the graded environment cannot hit it.

### Round 10 (feature-request framing in the BODY + FP repair)

The description body, not the title, is what the category check reads. It previously opened with a
problem statement, which reads as `enhancement`. Rewritten so the first sentence is additive ("Add a
trust accounting layer to the stack unwinder, and a record of why each walk ended") and **6 of 7
body paragraphs now lead with `Add`**.

**The FP check caught three real gaps introduced while reworking the wording.** Worth recording,
because two were the pre-existing-symbol class that the `CommandError` lesson warns about:

| Gap | Class | Fix |
|---|---|---|
| `FrameTrust::FramePointer` asserted by two tests, never named in meta | pre-existing symbol the tests depend on (A1) | meta now states the existing `FrameTrust` values keep their meaning and places `CfiScan` between `Scan` and `FramePointer`, which also makes the ordering explicit rather than implied |
| `CallStackInfo::Ok` asserted by two tests, never named | same | meta now says leave it `Ok` otherwise |
| `"scan"` token asserted via `as_str()` | token this task does not define | assertion **removed** from the test rather than added to meta; the `FrameTrust::Scan` variant assertion stays. Pinning a pre-existing token is exactly the over-specific coupling the earlier check warned about |

Both FP directions re-verified mechanically after the change: every symbol and token asserted
anywhere in the test file appears in meta.md, and the two newly added sentences both have
discriminators (`only_scanned_frames_are_candidates_for_corroboration` and
`contained_walk_degrades_nothing_and_exhausts`).

**Word count is 524 against a documented 500-word HARD cap.** This is a deliberate, authorised
overage and the justification is: the description has to name the complete public surface, which is
reviewer pattern A1 and was already raised as an auto-check ERROR. Every word above the cap is
either an API name the tests assert or a behaviour sentence with a discriminator. Cutting to 500
would mean dropping either a named symbol (reintroducing the ERROR and breaking FP direction one) or
a behaviour sentence (breaking fairness). Pure motivation prose was trimmed twice first; what
remains is contract. If a reviewer pushes back, the lever is to shorten the opening context
sentence, not to remove names.

### Round 9 (D1: induced a real difference, per the similarity rule)

Round 8's meta.md rewording did NOT count as differentiation. `CLAUDE.md` lists "reword meta.md" and
"rename the API surface" as explicit ANTI-PATTERNS for a similarity finding; the rule asks for 1-2
**induced** differences. Round 9 induced one.

**The end-of-stack marker became a parsed, validated symbol-format construct** instead of a string
compare inside `walk_with_stack_cfi`. It is now recognised when the file is read
(`classify_end_of_stack` in `parser.rs`), stored apart from the unwind rules as
`SymbolFile::end_of_stack: RangeMap<u64, EndOfStack>`, answered by
`SymbolFile::declares_end_of_stack` before any strategy runs, and a self-contradicting record (one
that declares no caller AND computes a return address) is discarded through the repo's own
`corruptions_discarded` counter. The now-unreachable walker branch was deleted.

Why this is the right differentiator:
- It puts real weight in **breakpad-symbols**, a crate the Adjacent candidate does not touch at all
  (its territory is `MinidumpMemoryInfoList` / `LinuxMaps` inside the unwinder).
- It **rides existing repo machinery** (the nom `stack_cfi_init` parsers, `into_rangemap_safe`, the
  corruption counters), which is the S4 pattern rather than bolted-on surface.
- It **changes the trap shape** to symbol-format parsing and record validation, which has no
  counterpart in a runtime memory-map validator.
- Constraint respected: `StackInfoCfi` has 7 struct literals across the repo, so a field there would
  have broken base tests. The data went on `SymbolFile`, which has one construction site.

| | round 8 | round 9 |
|---|---|---|
| Counter 2 | 265 | **315** |
| Counter 1 | 356 | 419 |
| solution files | 6 | 9 |
| new tests | 24 | 26 |
| files overlapping #1162 | 1 | 1 (unchanged: `lib.rs`, one `use` line on their side) |

FP check re-run both directions after the change: the two new parse-time behaviours are documented
in meta.md (declaration answered before any rule; contradictory record discarded and the walk
unwinds normally) and both have discriminators. Every name asserted anywhere in the test file appears
in meta.md. meta.md is 499 words against the 500 cap, which is tight enough that any further edit
needs a trim first.

**D2 (dropping containment) is NOT recommended, now that D1 is measured.** Containment is what
*causes* degradation, so removing it would delete `DegradeReason`, `trust_degraded`, `claimed_trust`,
`degraded_frame_count`, `trusted_prefix_len` and `degrade_reason_counts` - that is the trust
accounting axis, which is precisely what the candidate has none of. It would remove our distinctive
half, not the shared half. The residual shared idea ("the walk is bounded by the thread's stack
extent") is shallow: the candidate *bounds the scan* to reject frames, we *bound nothing* and instead
record what a frame is now worth and why the walk stopped.

### Round 8 (auto-check findings + earlier differentiation attempt)

**ERROR fixed: insufficient public interface information.** The tests asserted a public surface the
description never named, which is reviewer pattern A1, the single most-flagged issue. meta.md now
names every symbol the tests touch: `StackRegion` with `new` and `contains`; `WalkTermination` and
all five variants with their `as_str` tokens and the `is_truncated` mapping; `DegradeReason` and its
token; `FrameTrust::CfiScan` and `cfi_scan`; the `trust_degraded` / `claimed_trust` / `degrade_reason`
frame fields; `CallStack::termination`, `is_truncated`, `degraded_frame_count`, `trusted_prefix_len`,
`degrade_reason_counts`; `CallStackInfo::WalkTruncated`; `MAX_WALK_FRAMES`; and
`FrameWalker::set_end_of_stack`. Verified mechanically: every name asserted anywhere in the test file
appears in meta.md. Still 451 words against the 500 cap.

**WARNING fixed: tests asserting exact token strings.** Resolved in the direction the check
preferred, by specifying the tokens rather than loosening the assertions. The tokens are the
machine-readable form that lands in the processed JSON, so they are public contract rather than an
implementation detail, and naming them makes the assertions legitimate.

**Category changed to `feature-request`.** The auto-check suggested `enhancement`. The deliverable is
net-new public surface (a new module, three new public types, a `FrameTrust` value never constructed
before, a new `FrameWalker` method, a new constant, new fields on two structs), which is the
criterion `CLAUDE.md` gives for `feature-request`. meta.md now leads with `Add` so description and
category agree.

**Differentiation from the Adjacent candidate.** The judge returned `similar_idea`, not duplicate,
and the differences are real. To keep them that way, meta.md now states the scope boundary
explicitly: this changes no scanning loop and consults neither process memory maps nor page
permissions. That is exactly the candidate's territory (`AddressSpace` from `MinidumpMemoryInfoList`
and `LinuxMaps`, executability and file-backing checks, a bounded scan range, rejecting
frame-pointer frames in non-executable memory, a separate `walk_stack_with_memory_info` entry point).

The central capability was also reframed. It now reads as **trust accounting and termination
reporting**, not as validation. The candidate is a validation pipeline that rejects implausible
frames before acceptance; this keeps every frame the unwinder produced, records what was claimed for
it versus what it is now worth, and reports why the walk ended. Nothing in the candidate degrades
trust, tracks a claimed value, tallies reasons, reports a termination, or handles a CFI-declared end
of stack. **Do not drift toward memory-map validation in any future round** - that is the one change
that would collapse this into the candidate.

### Round 6 (third axis + olympus-review + FP check)

**Third axis: corroborated scanning (`FrameTrust::CfiScan`).** That variant was declared in the enum
with display strings but never constructed by any unwinder. A scanned frame whose address lands
where the module publishes unwind information is now recorded as `CfiScan`, above a bare `Scan` and
below what the unwind tables produce. Reuses no architecture file; the query is a new default
`SymbolProvider::has_unwind_info` (default `false`, so no external impl breaks and an implementation
that cannot answer never over-credits a frame), backed by a `SymbolFile::cfi_stack_info` lookup.

**The precedence is where the difficulty lives.** Corroboration is settled BEFORE containment, so a
frame that is corroborated and then found off the stack is still reduced, and `claimed_trust` records
the *raised* value, not the unwinder's original. `corroboration_does_not_rescue_a_frame_that_left_the_region`
pins exactly that ordering; an implementation that runs containment first, or that records the
pre-promotion trust as the claim, passes every single-axis test and fails this one.

**olympus-review alignment gate + FP check, run both directions:**

| Direction | Result |
|---|---|
| every test -> a meta sentence | 24/24 trace. One did not (`inline_frames_are_never_degraded_on_their_own`, weak assertions and a name implying an undescribed rule) and was **removed** |
| every described behavior -> a discriminator | all covered. One sentence had none ("the reduced value is what the rest of the walk observes") and was **removed from meta.md** rather than left as an untested claim |

Stage 0 precheck clean: ASCII, no em dashes, `test.sh` mode `100755`, no banned markers, 451 words.
Solution audit clean: 0 debug statements, 0 TODO/FIXME, 0 test-body comments, **0 architecture files
touched**.

**Post-round-6 numbers:** Counter 2 **248** (was 209), Counter 1 329, 8 files, 3 crates, 24 new tests,
255 base, flakiness 3x identical.

**f2p gate, re-verified by swapping source files:**

| | base source | with solution |
|---|---|---|
| `./test.sh base` | exit 0, 255 cases, 0 failures | exit 0, 255 cases |
| `./test.sh new` | exit 1, 1 case, 1 failure (build-failure JUnit) | exit 0, 24 cases |

### Round 7 (exclusivity risk removed, per CLAUDE.md's own bright-line procedure)

Round 6 shipped the corroboration query as a new `SymbolProvider::has_unwind_info` method, which was
the same *shape* as PR #1162's `unwind_strategy()` addition. Rather than argue the distinction, I ran
the bright-line test the rule specifies (overlay the hit's changed-file list on the solution
footprint) and then removed the overlap.

| | before | after |
|---|---|---|
| files overlapping #1162 | 2 (`lib.rs`, `symbols/mod.rs`) | **1** (`lib.rs`) |
| new `SymbolProvider` methods | 1 | **0** |
| solution files | 8 | 6 |
| Counter 2 | 248 | **265** |

The replacement reuses the **existing** `SymbolProvider::walk_frame` API. `SymbolFile::walk_frame`
reports the range its CFI rules cover (`set_cfi_rules_start_address`) *before* trying to apply them,
so a probe walker that supplies no register values learns whether rules exist without needing them
to evaluate. That is the right question anyway: the address came from a guess, and there is no frame
to unwind from yet.

One subtlety the probe had to handle: the walker deliberately clears that address again after the
attempt ("Reset even on failure so the address cannot leak into another provider's evaluation"), so
the probe latches rather than reading the final value.

Removing the trait method left `SymbolFile::has_unwind_info` with no callers; it was deleted too.

**Residual overlap is now a single file, `minidump-unwind/src/lib.rs`, where #1162's entire change is
adding one name to a `use` list in `impl_prelude`.** It touches no logic there. Per the bright-line
test the pick is clear: #1162 implements none of the core machinery of this capability, and the
capability's core (`bounds.rs` plus the `walk_stack` loop) is disjoint from it.

**Post-round-7:** Counter 2 **265**, Counter 1 356, 6 files, 3 crates, 24 new tests, 255 base,
flakiness 3x identical, f2p re-verified both directions, 0 architecture files touched.

Round 4 finished the deliverables. Round 5 ran the pre-submit alignment gate and fixed what it found.

### Round 5 (olympus-review alignment gate)

Tracing every test assertion back to a `meta.md` sentence found three real defects. This is the
check the reviewer rubric says actually sinks submissions, and it was worth running.

| Defect | Class | Fix |
|---|---|---|
| `WalkTermination::FrameLimit` asserted by tests, **absent from meta.md**, and not reachable by any test | test enforces undocumented behavior + unreachable variant | wrote a register-based CFI fixture that genuinely runs to the cap, and documented the rule in meta.md without naming the number |
| `WalkTermination::LeftStackRegion` and `CallStackInfo::WalkTruncated` were **described but had no test at all** | described behavior with no discriminator | built a fixture with two consecutive out-of-region frames; both are now asserted |
| `StackRegion::len` / `is_empty` | dead accessors, used only by each other and by tests | removed from the solution and the tests |

The two new fixtures matter beyond coverage: they prove `LeftStackRegion` and `FrameLimit` are
actually reachable. Frames whose stack pointer sits outside the region normally cannot be followed,
because reads past the region fail, so reaching either needed CFI rules that derive the caller from
registers alone (`.cfa: $esp 8 + .ra: $edi`). Without that construction both variants would have
shipped unreachable.

Also added to meta.md: per-frame degrade reasons are recorded and tallyable, and a cut-short walk
says so in the thread's status. Both were asserted by tests and previously undocumented.

**Post-fix numbers:** Counter 2 **209** (was 213; the dead accessors came out), Counter 1 279,
22 new tests (was 20), base 255, flakiness 3x identical, f2p gate re-verified in both directions.

The reference implementation is built, complete and green across two orthogonal axes. Round 2
findings below are kept because they are why round 3 was necessary.

### Round 3 result (end-of-stack axis added)

| Check | Value | Floor | Verdict |
|---|---|---|---|
| Counter 2 (human-effective) | **209** after round 5 | 200 | pass, thin margin |
| Counter 1 (auto-block) | 285 | — | fine |
| Files changed | 6 | 2 | pass |
| Crates spanned | 3 (breakpad-symbols, minidump-unwind, minidump-processor) | — | real cross-crate |
| Suite | 266 base + 17 new, all green | — | pass |
| Fail-on-base | new tests fail to COMPILE on base source (missing API), base suite green | — | verified properly |
| Flakiness | full suite 3x, identical | — | pass |

### Round 4 (deliverables + composition tightening)

| Item | State |
|---|---|
| `meta.md` | written, 346 words (cap 500), ASCII, no em dashes, no `##` headers |
| `test.sh` | mode 100755 in patch, position-independent `--output_path`, JUnit emitter, build-failure fallback |
| `Dockerfile` | Pattern A, `olympus-base-rust`, offline `cargo fetch` + `cargo build --workspace --tests` |
| Tests | 22 after round 5; 3 composition tests plus 2 reachability fixtures |
| Local grading sim | **not run** (user instruction); the partial image pull was also erroring under disk pressure |

**f2p gate, verified in both directions by swapping the source files rather than by stashing:**

| | base source | with solution |
|---|---|---|
| `./test.sh base` | exit 0, 255 testcases, 0 failures | exit 0, 255 testcases, 0 failures |
| `./test.sh new` | exit 1, 1 testcase, 1 failure (valid JUnit from the build-failure fallback) | exit 0, 20 testcases, 0 failures |

`test.sh base` selects the pre-existing targets one by one instead of using `--workspace`, because
`--workspace` would also compile the new integration test, which cannot build until the feature
exists. That is a real constraint of this problem, not test.sh trickery, and is commented in the
script.

**Composition tightening (HARDENING 3c(b) shape: test-only, zero new meta sentences, solution byte-identical):**
- `a_declared_end_outranks_a_frame_that_left_the_region` — the fixture produces a frame that is BOTH
  outside the region AND at a declared end. Precedence must be the declared end, so `termination` is
  `EndOfStack` and `degraded_frame_count` is 0, not `LeftStackRegion` with a degrade.
- `a_declared_end_leaves_the_result_readable_at_face_value` — trusted prefix covers every frame and
  the reason map is empty.
- `containment_still_applies_when_no_end_is_declared` — the same fixture without the marker degrades.

An implementation that applies containment before checking for a declared end fails the first of
these while passing every single-axis test.

## Quality audit of the final patches

| Check | Result |
|---|---|
| test-body comments | 0 |
| banned markers (`TODO`/`FIXME`/`CATEGORY`/`Step N`) | 0 |
| debug statements (`println!`/`dbg!`/`eprintln!`) | 0 |
| doc comments in solution | 104 lines, matching the repo's own convention (its source doc-comments public items) |
| `shipd` / `datacurve` in test paths | none |
| patch encoding | ASCII, LF |
| `test.sh` mode in patch | `100755` |
| insta snapshot churn | none |

**The second axis: definitive end of stack.** A CFI record may now declare `.ra: .undefined`,
mirroring DWARF's undefined return address rule, which the Breakpad text format could not express.
`walk_with_stack_cfi` reports it through a new default `FrameWalker::set_end_of_stack` method; the
answer travels out on an `AtomicBool` shared through `GetCallerFrameArgs`, so it survives the CFI
strategy being abandoned, and `walk_stack` discards whatever a later strategy produced.

**Why it is genuinely orthogonal to containment:** a frame at the declared end is *inside* the stack
region and *undegraded*, so containment is perfectly happy to keep walking. Only the marker stops it.
And an implementation that treats a declared end as ordinary CFI failure falls through to scanning
and invents frames, which containment only catches after two consecutive degrades, so frames still
leak. Neither axis can substitute for the other. Test `a_declared_end_outranks_a_frame_a_later_strategy_would_produce`
pins exactly this: same fixture, `.undefined` gives 1 frame, a normal rule gives more.

**Zero architecture-file edits.** The `AtomicBool`-through-`GetCallerFrameArgs` design keeps the whole
footprint off PR #1162's changed-file set, which was a deliberate constraint, not a coincidence.

## Round 2 findings (kept — this is why round 3 was needed)

### 1. Under the LOC floor

| Counter | Measured | Floor | Verdict |
|---|---|---|---|
| Counter 2 (human-effective) | **192** | 200 | **FAIL** by 8 |
| Counter 1 (auto-block) | 260 | — | fine |
| Files changed | 4 | 2 | pass |

Design sketched 313 meaningful; reality is 192. This is the taffy / golang-geo
oracle-absorption law again: a well-factored codebase absorbs sketched line items. The sketch
was a lower bound and should have been treated as one.

### 2. The difficulty collapsed to a single mechanism

The R2 design carried four traps on orthogonal axes. Three did not survive contact with the
existing test suite:

- **Trap B (S5 corroboration policy) is DEAD.** Three formulations were built and measured:
  - corroborate every frame against symbols -> 8 base tests red (`arm64_unittest`,
    `x86_unittest::test_stack_win_frame_data_*`, `*_frame_pointer_barely_no_overflow`).
  - corroborate only scanned frames -> **unreachable dead code**, because `get_caller_by_scan`
    already refuses any candidate that `instruction_seems_valid_by_symbols` does not name. A
    scanned frame can never be contradicted.
  - corroborate by module membership instead of symbols -> still 5 base tests red; the existing
    fixtures deliberately unwind to addresses outside the fixture's module ranges.
  Every version is either dead code or a base regression. Removed.
- **Trap C (S3 leaf carve-out)** never fired, because the containment check sits in `walk_stack`
  after the architecture has returned, so the leaf determination channel never sees a degraded
  value. The trap I designed the architecture to avoid is the trap I designed to exploit; those
  were incompatible and I did not notice at design time.
- **Trap D** is bookkeeping (adjacency vs count), not an independent mechanism.

What remains is: derive a region, degrade a frame whose stack pointer is outside it, stop on the
second consecutive degrade, report the reason. **That is one local rule applied at one site, which
is the uniform-wrap death class in `TOO-EASY.md`.** Expected batch behaviour is well over the 40%
ceiling. Batching it now would burn a batch to learn what the death-class table already says.

## What is actually built and green

- `minidump-unwind/src/bounds.rs` (new): `StackRegion`, `WalkTermination` (4 variants),
  `DegradeReason`, `degrade_frame`, `trust_rank`, `DegradeRun`, `containment_reason`,
  `MAX_WALK_FRAMES`.
- `minidump-unwind/src/lib.rs`: `StackFrame::{claimed_trust, trust_degraded, degrade_reason}`,
  `CallStack::termination`, `CallStackInfo::WalkTruncated`, walk-loop integration, frame cap,
  `CallStack::{degraded_frame_count, trusted_prefix_len, degrade_reason_counts, is_truncated}`,
  human-readable output.
- `minidump-processor`: conditional JSON emission (keys omitted entirely when there is nothing to
  report, so **all 10 insta snapshots stay byte-identical** and no snapshot churn enters the diff)
  plus per-thread degradation aggregation.
- `minidump-unwind/tests/stack_containment_d57b13.rs`: 12 tests, all green, public API only, no
  source edits needed in `test.patch`.

**Suite: 266 base + 12 new = 278, zero failures, zero regressions, ~6s, offline.**
Patches saved (`solution.patch`, `test.patch`, ASCII, LF) so the work survives worktree cleanup.
`test.sh` and `Dockerfile` deliberately NOT written yet — pointless until the scope question is
settled.

## Recommended next step

Add the **end-of-stack marker** capability as a genuinely orthogonal second axis. This is issue
**#1002**, where maintainer `luser` asks for exactly it and `gabrielesvelto` says "I'd be game" to
extending the Breakpad sym format for it. It is a different mechanism in a different crate
(`breakpad-symbols` sym parsing -> CFI evaluation -> the walk), so it composes with containment
instead of collapsing into it:

- a walk that hits a definitive end marker must stop even though other strategies would happily
  continue, which is the inverse of containment (containment stops a walk that looks wrong; the
  marker stops a walk that looks fine)
- it lands in `breakpad-symbols`, giving the cross-crate span the current build lacks
- it plausibly carries 120-200 more meaningful LOC, clearing the floor with real margin
- the interdependency is genuine: a frame at the end marker is inside the region and undegraded,
  so an implementation that only consults containment walks straight past it

## Gate record (all still valid)

- Gate 5 cold-not-live: `minidump-unwind` 7 commits/12mo, `minidump-processor` 13. Cold.
- Gate 7b exclusivity: PR #1162 diff read in full, cascade-reordering plumbing only. Footprint
  contains no architecture file. PR #1164 edits `process_state.rs` / `processor.rs`; re-diff before
  submit.
- Gate 8: maintainer-blessed on #1002 / #918 / #739. Nothing declined.
- Gate 9 flakiness: suite run 3x pre-build and again post-build, identical, offline.
- Gate 10 quota: zero prior submissions on this repo.

## Environment

- Docker sim **not run**: 4.4G free, and `olympus-base-rust` plus an in-container workspace build
  needs roughly 5-6G. Re-attempt after freeing space, and only once the artifact is submittable.
- crates.io DNS is flaky inside the sandbox; cargo needs `dangerouslyDisableSandbox`.
- Cleared `worktrees/{hayagriva,customasm,lyon}/target` (regenerable) to make room; this took the
  disk from 4.2G to 5.5G free before the build consumed some again.

## Attempt history

| Round | What changed | Result |
|---|---|---|
| R1 design | containment guard in `walk_stack` | rejected by my own TOO-EASY audit: uniform-wrap + the fairness sentence handed the fix |
| R2 design | trust degradation observed by 5 silent consumers | 4 traps on orthogonal axes, looked sound |
| R2 build | reference implementation | 3 of 4 traps died on contact with the base suite; 192 eff LOC |

## Round 21 - fairness FAIL closed (1 unfair test)

The test-fairness check came back FAIL on exactly one assertion, and it was a real spec gap rather
than a bad test. `stack_containment_d57b13.rs:199` asserts that every unreduced frame's
`claimed_trust` equals its current `trust`. meta.md specified `claimed_trust` only for reduced
frames, and the repo has no prior field or default convention to infer it from, so an implementer
could just as reasonably have used `Option<FrameTrust>` populated only on reduction. The checker was
right: the assertion pinned a representation the prompt never asked for.

Fixed in meta.md, not in the tests, per the standing rule that an unfair assertion means the
description is missing a sentence:

  Every frame carries a `claimed_trust`, which is what its trust was before any reduction, so on a
  frame that was not reduced it reads the same as its current trust.

This makes the non-optional representation a stated requirement instead of an inferred one. It also
tightens the corroboration paragraph, since `promote_frame` sets both fields and the two readings
now agree. FP holds in both directions: the sentence is discriminated by the line-199 assertion, and
no other assertion changed.

meta.md is now 496 words against the 500 cap, still ASCII, still zero em dashes, still zero `##`
headers. Tests, solution and Dockerfile are byte-identical to round 20, so the 5x flakiness result
and the 313 human-effective count carry forward unchanged. No rebuild was required.

### Coverage suggestions NOT taken, and why

Three suggestions came back. None blocks, and none is a fairness issue.

1. **Processed JSON for an actual reduced frame.** This is the one worth doing and the only one
   raised twice. Today the processor tests cover the omission case and the `NoStackMemory`
   termination, so the presence of `trust_degraded` / `claimed_trust` / `degrade_reason` in JSON is
   asserted only at the unwind layer. Not added: producing an off-region frame from a synthetic dump
   means driving the frame-pointer chase past the end of the supplied stack memory, which is a
   fixture that needs several build-and-iterate cycles to land, and disk is at 7.4G free with no
   `target` directory. Adding a test I cannot run is how the 33-vs-34 fallback enumeration bug got
   in. Left for a round with room to build.
2. **ARM / ARM64 containment.** amd64 was added last round and the checker now credits it. The
   containment check sits in `walk_stack` after the architecture returns, so it is arch-independent
   by construction; ARM coverage would confirm rather than discriminate. Same build cost.
3. **Contradictory `.ra` inside one physical record.** The discard rule is already covered by the
   delta-rule test. A single-record variant exercises the same parser branch.

## Round 22 - interface ERROR + 2 unfair tests, all three fixed in meta

Three reports, three description gaps. Zero test changes, zero solution changes, no rebuild.

**1. Interface ERROR - the `.ra: .undef` token was never named.** meta said "a way for a symbol file
to declare that a range of code has no caller" without giving the syntax, while the tests write
`.ra: .undef`. This is the A1 pattern again, and it is the fourth time on this build. Round 18 had
already established that `.undef` is the repo's own token; I switched the tests to it then but never
put the token in meta, so the fairness checker passed those tests as Repo-discoverable while the
interface checker correctly failed the description. Now stated, with the precedence the report asked
for: a return address rule in a later record replaces the one an earlier record gave rather than
joining it, whether that earlier record was the INIT or another delta.

**2. Unfair - the frame cap was pinned by fixture size, not by the spec.** The test asserts
`FrameLimit` on an 8-byte-progressing loop over a 1 MiB stack, which only holds if the cap is under
roughly 131,072 frames. meta said "as many frames as the walk is willing to record", so a larger
finite cap was equally conformant and would have hit `LeftStackRegion` first. The fixture was
silently encoding a numeric policy. meta now states the cap: 1024 frames.

**3. Unfair - the processed-output summary keys were undocumented.** The plain-walk test asserts the
absence of `degraded_frame_count`, `trusted_prefix_len` and `degrade_reasons`. meta named the first
two only as `CallStack` APIs, never named `degrade_reasons` at all, and never said the three are
conditionally omitted from JSON. Now stated, including that the reason tally is spelled
`degrade_reasons` in the output while the API is `degrade_reason_counts`.

Word budget was the binding constraint: the three additions cost about 34 words against a 496-word
start. Offset by trimming prose that carried no assertion (the frame-limit rationale clause, "a
clean finish" to "clean", "for human-readable output" to "human-readable", and the `StackRegion`
boundary restatement). 499 of 500, still ASCII, zero em dashes, zero `##` headers. Every removed
word was checked against the test file first; no assertion lost its sentence.

### Cost note

Stating the cap makes the frame-limit rule fully transcribable, which is a small difficulty loss.
It is also the only fair option available: the alternative the report offered was rebuilding the
fixture so no allowed cap can reach the region boundary, which needs a build I cannot run.

## Round 23 - Auto Review "Revision Requested": a real solution bug, 4 test gaps, 1 description issue

First round with a genuine CODE defect. Everything below is verified locally (build, mutation,
5x flakiness, f2p both directions).

### S1 High - the classifier read only the first `.ra:` in a row (REAL BUG, fixed)

`return_address_expr` used `split_once(".ra:")` and `take_while(|t| !t.ends_with(':'))`, so for
`.cfa: $esp 4 + .ra: .undef .ra: .cfa 4 - ^` it saw `.undef`, stopped at the second `.ra:`, and
classified the record as a clean end-of-stack declaration. My own meta requires that record to be
discarded as contradictory. The repo's evaluator explicitly honours the LAST assignment when a
register is assigned twice (`walker.rs`), so reading only the first occurrence contradicted the
machinery I was riding.

Replaced with `return_address_exprs`, which walks the token stream and collects EVERY return-address
assignment. A row that both declares `.undef` and computes is now Malformed, matching the existing
INIT-plus-delta contradiction path. **Mutation-proofed:** dropping the new same-row check makes
`a_record_that_declares_and_computes_in_one_row_is_discarded` fail and nothing else.

This one is worth remembering: the bug was in the half of the feature that RIDES existing machinery,
and it was invisible to every fairness and coverage check for five rounds. Riding a repo mechanism
means matching its semantics exactly, not approximately.

### Tests - 4 High gaps closed, suite 35 -> 39

| Gap | Closed by |
|---|---|
| Frame cap not pinned | `assert_eq!(s.frames.len(), 1024)` added to the frame-limit test. **Mutation-proofed:** cap 1000 fails it |
| Same-row contradiction untested | `a_record_that_declares_and_computes_in_one_row_is_discarded` |
| Delta-to-delta replacement untested | `a_later_delta_replaces_an_earlier_delta_return_address_rule` (three rules, later one wins, asserts instruction + `CallFrameInfo`) |
| No positive degraded JSON | `a_reduced_walk_carries_its_degradation_in_the_processed_output` asserts all three per-frame fields and all three thread summaries with concrete values |
| Only NoStackMemory serialized | `every_cut_short_or_declared_ending_reaches_the_processed_output` covers EndOfStack, LeftStackRegion, FrameLimit |

The two processor tests drive the serializer from a constructed `ProcessState` rather than from a
synthetic dump that walks off its own stack. That is deliberate: producing an off-region frame
through `process_minidump` needs a module plus a symbol file in the dump, which is a large fixture
for no extra contract coverage. The fields are public and the JSON is the contract, so setting the
state and asserting the output tests exactly what the report asked for.

### test.sh - the enumerator denylist broke again, so it is gone

The build-failure fallback enumerated `^async fn|^fn` and subtracted a hardcoded list of helper
names. Renaming one helper (`processed_json` -> `plain_state`) and adding another (`to_json`) put the
count at 41 against 39 real tests, which is the exact wrapper defect from round 19. Replaced the
denylist with attribute-based detection (`grep -A 1` on `#[test]` / `#[tokio::test]`), so helpers can
never be counted again. Also removed the grader-facing comment the report flagged.

### P6 - the scope guard was prescriptive

"Do this without consulting process memory maps or page permissions" forbade data sources instead of
stating behavior, and no test enforced it. Replaced with the positive form: "The region comes from
the stack memory the walk was handed." That is observable, is what every containment test relies on,
and still fixes the design boundary that keeps this pick distinct from the adjacent candidate.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | 39 pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source `new` fails all 39; name sets from base and solution runs **identical**, `classname=""` both |
| Mutations | 2 new traps proofed (same-row contradiction, exact 1024) |
| human-effective | **317** (floor 200), counter1 428 |
| Disk | target cleared, 7.4G free |

## Round 24 - Blocker harness fix + two real semantic bugs

Tests scored 0/3 on a Blocker and Solution 1/3 on two High findings. Description held at 3/3.

### Blocker - the harness was root-only

`test.sh` opened with `export PATH="/root/.cargo/bin:$PATH"`, and the Dockerfile installed
cargo2junit and the registry cache into root's home. The grading sandbox runs offline under a
non-root UID, which cannot read `/root`, and cargo additionally needs WRITE access to `CARGO_HOME`
for its package lock even with `--offline`. So both modes failed there while passing locally as root.

Fixes: the `/root` line is gone from `test.sh` entirely, so cargo resolves from the image's own PATH.
The Dockerfile now sets `CARGO_HOME=/opt/cargo`, installs cargo2junit with `--root /usr/local` so the
binary lands on the system PATH, and ends with `chmod -R a+rwX /opt/cargo /app` so the non-root
client can read the cache and write `target/`.

`RUSTUP_HOME` and the toolchain location are deliberately untouched. Moving those is the legacy
mars-base pattern that produced "rustup could not choose a version of cargo" and is a documented
0/10 permissions blocker. Only the cargo package home moves, which does not affect toolchain
resolution.

**This is reasoned statically and remains OWED to the platform run - Docker cannot be exercised here.**

### S1 - a later CFI record must replace an earlier `.ra: .undef` (REAL BUG)

`classify_end_of_stack` gave a verdict for the whole record, so INIT `.undef` plus any later delta
carrying a return address was discarded wholesale as malformed. My own description says a later
record REPLACES an earlier rule, so the correct model is per-address.

Replaced with `end_of_stack_ranges`, which walks the rows in address order tracking the effective
return address and emits an end-of-stack range only for the spans where `.undef` is still in force.
The record itself is now always published to `cfi_stack_info` unless a single row contradicts itself.
**Mutation-proofed:** restoring the whole-record verdict fails two tests.

This exposed a second, subtler thing worth recording. The walker was already correct: it merges INIT
and delta rules into a map with later-wins semantics before reading `.ra`. The bug was entirely in
the parser publishing the wrong ranges. My own test had been passing for the wrong reason, because
its fixture left frame-pointer data that let fallback unwinding produce a caller after the record was
discarded. Rebuilt the fixture so the CFI rule itself must compute the return address, and added
`assert_eq!(s.frames[1].trust, FrameTrust::CallFrameInfo)` so fallback can never satisfy it again.

### S1 - second reduced frame anywhere, not just consecutive

`DegradeRun` tracked only whether the immediately previous frame was reduced, so an intervening
contained frame reset it. The description says stop before recording a second reduced frame, full
stop. Changed to a latch that never clears.

**Honest finding: this change is not observable by any test.** Mutating the latch back to adjacency
still passes all 43. That matches the round-11 result that non-adjacent degrades are structurally
unreachable here: there is one degrade cause and stack pointers advance monotonically, so a frame
cannot go outside, back inside, then outside again. The fix is correct against the spec and removes
the divergence, but it buys no discrimination.

### Tests - 39 to 43

| Added | Covers |
|---|---|
| `a_later_declaration_replaces_a_computed_return_address_rule` | INIT concrete `.ra`, later delta `.undef`, asserts `EndOfStack` and one frame |
| `an_earlier_declaration_still_ends_a_walk_that_lands_before_the_replacement` | the same record, entered BEFORE the replacement address, still ends |
| `a_walk_stopped_at_the_frame_limit_says_so_in_the_text` | `FrameLimit` description in `CallStack::print` |
| `a_walk_without_stack_memory_says_so_in_the_text` | `NoStackMemory` description in `CallStack::print` |

Not taken: the CfiScan ordering suggestion. `trust_rank` is private, so there is no public comparison
mechanism to assert against; ordering is only observable through promotion and degradation, which the
suite already covers.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | 43 pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source `new` fails all 43; solution passes all 43; name sets **identical** |
| Mutations | per-address CFI proofed (2 tests); degrade latch NOT discriminated (recorded above) |
| human-effective | **327** (floor 200), counter1 442 |
| Docker | **not run, owed** |

### Process note

The f2p check nearly destroyed work: `/tmp/srcfiles.txt` had been cleaned up between rounds, so
`git checkout $BASE -- $(cat missing-file)` degenerated into `git checkout $BASE` and detached HEAD
across the whole repo. Nothing was lost because git carries modified files across a checkout and base
equals main here, but the backup tar was also empty at that moment. Two rules from this: keep
verification backups in the scratchpad rather than `/tmp`, and check the file list is non-empty
before interpolating it into a git command. Also, `tar` restores old mtimes, so cargo skips the
rebuild and the next run silently tests the OLD binary; `touch` the restored files before re-running.

## Round 25 - fairness FAIL closed in meta (not by deletion), frame-limit boundary, 2 coverage adds

Grader verdict was PASS with code quality 3/3 and comprehensiveness 2/3. Fairness was FAIL on 1 of 43.

### The determinism test: stated, not deleted

My first instinct was to delete `walk_result_is_deterministic_across_repeated_walks`, since an
earlier reviewer had also called it shallow. That was wrong, and the correction came from the user:
determinism is a WHAT, not a HOW, so it belongs in the description like every other contract. Deleting
it would also have been the option that quietly lowers difficulty. meta now says:

  Walking a thread twice gives the same frames, termination and counts.

Test restored unchanged. **Rule reinforced: reach for the meta sentence first; deletion is the last
resort, and "a reviewer called it shallow" is not a reason to drop an assertion that is now fair.**

### Comprehensiveness 2/3 - the frame-limit boundary

The cap was checked BEFORE pushing, against the current length, so `FrameLimit` was only reported
when a 1025th frame was attempted. A walk that naturally ended right after recording its 1024th frame
reported `Exhausted`. meta says stop once it has recorded 1024 frames. Moved the check after the
push, so recording the 1024th frame is itself the stop.

**Not discriminated by any test**, same as the round-24 degrade latch: both orderings yield
`frames.len() == 1024` and `FrameLimit` on the looping fixture, and the divergent case needs a walk
that would exhaust at exactly 1024. Spec-conformant, zero new discrimination. Recording it honestly
rather than claiming a hardened trap.

### Interface WARNING - print content and the processed thread type

Two items. The tests assert specific substrings from `CallStack::print` (the reason token and the
frame's claimed-trust description) while meta only said "surface" it; and the processed-state thread
was assumed to expose a typed `termination`. Both stated now:

  The text names the reduction by its reason token and by the frame's claimed trust description.
  The processed output, whose threads are these call stacks, ...

The second clause is the cheap fix for the typed-field question: the threads ARE `CallStack`s, so
`CallStack::termination` is already the field the test reads.

### Coverage suggestions - both taken

- `a_reduced_walk_that_ended_plainly_reports_its_reduction_but_no_termination` - one reduced frame on
  an `Exhausted` walk: summaries present, `termination` omitted, info `Ok`, not truncated. This is the
  cell that separates "reduced" from "truncated" in the output, and nothing covered it.
- `a_delta_row_that_declares_and_computes_is_discarded` - the same-row contradiction on a DELTA row
  rather than an INIT row. Asserts fallback lands at `FramePointer`, so the record really was dropped.

### Word budget

The three additions cost about 30 words against a 500 cap that was already at 497. Bought back by
trimming prose carrying no assertion: the scanning "is a guess" framing, "Add a way for a symbol file
to declare" to "A symbol file declares", the doubled `FrameLimit` sentence, "not the unwinder's
original" to "not the original", and three single words. Landed at exactly 500. Every candidate was
checked against the test file first.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | **45** pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source fails all 45; solution passes all 45; name sets **identical** |
| human-effective | **327** (floor 200), counter1 443 |
| meta | **500/500 words**, ASCII, 0 headers, 0 em dashes |
| Docker | **not run, owed** |

## Round 25b - the 500-word cap is soft, so the compressions came back out

User: meta may go over 500 when the problem needs it, as long as it states WHAT not HOW.

Round 25 had squeezed meta to exactly 500 to pay for three required additions, and the squeeze cost
real readability. Restored, now **523 words**:

- "Stop it as well once it has recorded 1024 frames, and report that as `FrameLimit`" - the
  compressed form ("and once it has recorded 1024 frames, reported as `FrameLimit`") had lost its
  verb and read as broken English.
- "A frame found by scanning is a guess, so when its address falls where the module publishes unwind
  information..." - the rationale is what makes the scanned-only rule read as a feature request
  rather than a spec bullet. Rationale is WHAT, not HOW.
- "Add a way for a symbol file to declare..." - restores the additive opener. The category is judged
  on the body, and five of seven paragraphs now lead with `Add` again.
- Also back: "not the unwinder's original", "walk-wide summaries", "nothing about it counts as
  reduced trust", "reduction count".

Nothing that a test asserts was touched in either direction, so the FP check is unchanged. Still
zero `##` headers, ASCII, no em dashes, no HOW: no file paths, no helper names, no algorithm steps,
and no forbidden-data-source instruction (that last one was the P6 flag, already fixed in round 23).

meta-only change, so no rebuild: patches, the 45 tests, the 5x flakiness result and human-effective
327 all carry forward from round 25 unchanged.

**Lesson recorded to memory:** compressing to hit the word count damages exactly what the description
band grades. Add the sentence a fairness or interface check demands, and only buy words back from
prose that carries no assertion.

## Round 26 - two test branches, both mutation-proofed

Description **3/3**, Solution & Code **3/3**, Tests 1/3 on two verified High coverage gaps. No code
change needed this round; both findings were genuine holes in the suite.

### Gap 1 - contradiction was only tested in one token order

`a_record_that_declares_and_computes_in_one_row_is_discarded` puts `.ra: .undef` before the computed
`.ra`. An implementation that only rejects undefined-then-computed would pass while treating
computed-then-undefined as a clean `EndOfStack`. Added
`a_row_that_computes_before_declaring_is_discarded_too` with
`.cfa: $esp 4 + .ra: .cfa 4 - ^ .ra: .undef`.

**Mutation-proofed:** changing `row_return_address` to flag a contradiction only when the FIRST
assignment is `.undef` fails exactly the new test and nothing else. The current implementation was
already order-independent (it collects every assignment and checks for both kinds), so no source
change was required, but the branch was untested and an order-sensitive parser was a live way to pass.

### Gap 2 - reduction text was only tested on a cut-short walk

`a_reduced_frame_and_a_cut_short_walk_are_both_surfaced` prints a walk that is BOTH reduced and
`LeftStackRegion`, so an implementation that emits the reduction lines only inside a
`termination != Exhausted` branch would pass. meta requires per-frame reduction to be surfaced
independently of why the walk ended. Added `a_reduced_frame_is_surfaced_even_when_the_walk_ended_plainly`,
which reuses `escaping_walk` (one reduced frame, then ordinary exhaustion) and asserts the reason
token and the claimed-trust description ARE printed while the `Exhausted` description is NOT.

**Mutation-proofed:** gating the per-frame reduction block on `self.termination != Exhausted` fails
exactly the new test.

**Both gaps are the same shape and worth naming: a test that exercises two conditions at once cannot
show they are independent.** Each gap came from a fixture where the interesting property travelled
with a second property, so a coupled implementation passed. When a rule says X happens regardless of
Y, one test needs X with Y and another needs X without it. The JSON side already had this pair (round
25 added the reduced-but-Exhausted case); the text side did not, and neither did the parser's token
order.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | **47** pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source fails all 47; solution passes all 47; name sets **identical** |
| Mutations | both new tests proofed against the exact wrong implementation the report described |
| human-effective | **327** (floor 200), counter1 443 |
| meta | 523 words, ASCII, 0 headers, unchanged this round |
| Docker | **not run, owed** |

## Round 27 - JSON prefix edge + description density

Solution & Code held **3/3** and was untouched. Two Medium findings, both fixed.

### T4 - `trusted_prefix_len` was only ever serialized as zero

Every processed-output test degraded frame 0, so the JSON assertions only ever saw a prefix of zero.
A serializer that emitted all the degradation fields correctly but hard-coded `trusted_prefix_len`
to 0 would have passed. Added `the_processed_output_counts_the_trusted_frames_before_the_reduced_one`,
which clones the context frame so an undegraded frame sits ahead of the reduced one, then asserts the
serialized prefix is 1 and that frame 0 carries no reduction fields while frame 1 does.

**Mutation-proofed:** replacing `json!(thread.trusted_prefix_len())` with `json!(0)` fails exactly
the new test.

This is the round-26 lesson again from a different angle. There the fixture coupled two conditions;
here every fixture happened to pick the SAME value for a field, so the field's computation was never
exercised at the JSON boundary. **A summary field asserted only at its identity value (0, empty,
None) is not tested - it needs one fixture where the value is interesting.** `trusted_prefix_len()`
had nonzero coverage on the core API, which is exactly why the JSON gap was easy to miss: coverage
of a helper does not carry across a serialization boundary.

### P4 - the description was dense

Same content, same identifiers, restructured from 7 long paragraphs into 13 single-topic ones:
region, `StackRegion`, corroboration, the per-frame fields, the degradation rule, determinism, the
stopping rules, the CFI declaration syntax, declared-end precedence, `WalkTermination` and its
tokens, `CallStack::termination` and `WalkTruncated`, the `CallStack` summary accessors, and the two
output surfaces.

Verified nothing was lost: a scripted check confirms all 37 named symbols and tokens still appear,
and the word count is unchanged at 523. Still zero `##` headers, ASCII, no em dashes, and the first
body sentence still reads as the ask. No bullets or headers were introduced - the reviewer offered a
flat list as an option, but the approved set is plain prose throughout and headers are banned, so
shorter paragraphs are the safe way to get the same scannability.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | **48** pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source fails all 48; solution passes all 48; name sets **identical** |
| Mutation | `json!(0)` for the prefix fails exactly the new test |
| human-effective | **327** (floor 200), counter1 443 |
| meta | 523 words, 13 paragraphs, 0 headers, ASCII |
| Docker | **not run, owed** |

## Round 28 - ARM64 backend coverage

Description **3/3** and Solution & Code **3/3**, both untouched. One High test finding.

### The gap and why it is a real one

Containment was proven on x86 and amd64 only, while the repo ships separate `arm`, `arm64`,
`arm64_old` and `mips` unwind backends. My instinct was that this is unreachable by construction,
since the containment check sits in `walk_stack` AFTER the architecture returns a frame, so it cannot
be architecture-gated. That reasoning is right about the REFERENCE and wrong about the task.

A solver is free to put the check inside each architecture's `get_caller_frame` instead. That
implementation is entirely plausible, passes every x86 and amd64 test, and silently does nothing on
ARM. **The test does not guard my design; it constrains the space of designs that can pass.** That is
the point of a backend test, and it is why "the shared loop makes this impossible" was not a valid
reason to skip it.

Added `Arm64Fixture` and `containment_applies_on_arm64_as_well`: a frame-pointer chain whose caller
stack pointer lands exactly on the region end, asserting the frame is retained, `trust_degraded`,
reduced to `Scan`, reason `OutsideStackRegion`, degraded count 1 and trusted prefix 1.

The `claimed_trust` value is the interesting part. I guessed `CallFrameInfo`, probed, and it is
**`FramePointer`** - where the amd64 case records `Scan`, because amd64 recovers that frame by
scanning while arm64 recovers it through the frame-pointer chain. So the three backends now assert
three different provenance paths into the same containment rule, and the arm64 case is the strongest
of them: it shows `claimed_trust` preserving a value that genuinely differs from the reduced trust.

### Not taken

- **Scan corroboration on a second backend** (offered as "ideally"). Promotion runs in the same
  shared loop position as containment, which now has three-backend coverage. Making arm64 produce a
  scanned frame means defeating its frame-pointer chain first, which is a fixture rewrite for a
  narrower version of a gap already closed.
- **`FrameTrust` ordering assertion.** `trust_rank` is private and there is no public `Ord`, so
  ordering is only observable through promotion and degradation, which the suite covers. Declined for
  the fourth time on the same grounds.
- **Real `.ra: .undef` walk through the processor.** The serializer tests assign termination on a
  constructed `ProcessState`; an end-to-end version needs a module plus a matching symbol file inside
  the synthetic dump (debug id and all), which is a large fixture. The declaration behavior itself is
  covered end-to-end in `minidump-unwind`, and the serializer contract is covered in the processor.
  Flagging it as the most likely thing to come back.

### Verification

| Check | Result |
|---|---|
| base | 255 pass, 0 fail |
| new | **49** pass, 0 fail |
| Flakiness | **5x base + new, identical every run** |
| f2p | base-source fails all 49; solution passes all 49; name sets **identical** |
| human-effective | **327** (floor 200), counter1 443 |
| meta | 523 words, unchanged this round |
| Docker | **not run, owed** |
