---
name: olympus-harden
description: Use when an in-flight Olympus problem is (or is predicted to be) too easy — a batch came back above the 40% ceiling, a wall was removed for fairness, or the design rests on one trap. Diagnoses WHY from the actual evidence (agent runs first, mutations only as a fallback), picks the fair re-hardening lever the diagnosis implies rather than the one that is easiest to write, and verifies the result with trap-proof plus full clean-room validation. Triggers on "too easy", "harden this", "make it harder", "raise difficulty", "pass rate too high", ">40%", "add a trap", or after a batch reads soft. Source of truth: Olympus/Instructions/HARDENING.md (doctrine + arsenal), Olympus/failure-patterns.md (measured patterns + laws), Olympus/Instructions/TOO-EASY.md (death classes).
---

# Olympus Harden — raise difficulty without buying it unfairly

Two rules govern everything below.

1. **The knob is trap COUNT and STRENGTH, not LOC.** A 900-line uniform wrap is still a uniform
   wrap. Adding files moves scope and payout; it does not move pass rate.
2. **Difficulty bought by hiding something is not difficulty.** Every trap must be
   CONTRACT-STATED / FIX-HIDDEN (`HARDENING.md § 1`): the meta states the behaviour, and the
   statement does not hand the fix. A trap that only works because the spec omits something dies
   at Test Fairness, and the round you spend defending it is a round you do not get back.

---

## Stage 1 — Get evidence before touching anything

**Agent runs are the only oracle.** Mutations tell you what your tests can DETECT; only a batch
tells you what agents get WRONG (L15 — on neva an entire runtime subsystem was added over three
hardening rounds on mutation evidence and killed 0 of 10 agents).

```bash
ls -d problems/<name>/agent-runs* 2>/dev/null
```

**If runs exist** — mine them with the Stage-1 recipe in `olympus-finalize` (ElementTree, never
regex: the platform's flat testsuite with self-closing `<testcase/>` will mis-attribute failures
under a regex parse). You need: pass rate, per-test kill counts, failure clusters, the near-miss
runs' SOLE failure, and which tests killed nothing.

**If no runs exist** — you are predicting, not measuring. Say so explicitly in `feedback.md`,
use the trap-proof harness (Stage 4) as a weak proxy, and prefer levers that are structurally
sound rather than ones tuned to a mutation.

---

## Stage 2 — Diagnose (the diagnosis picks the lever, not your preference)

| Evidence | Diagnosis | Lever |
|---|---|---|
| Failures are **scattered singletons**, no dominant cause | The domain is SEPARABLE. Stacking more traps will not help (L3) | Find what the convergent architecture structurally cannot do (**F-1**). Read the PASSING patches — you cannot guess it |
| Several agents at **20/21 or 19/21**, each failing a different single test | Near the ceiling. The set is fair but the walls are low | Fill the empty **F-10** cross-product cells. Cheapest lever measured, zero description words |
| **Everyone passes**, few or no failures | One weak or self-revealing trap | Do NOT add wording. Add a second mechanism on a DIFFERENT axis, then re-check the composition cells |
| Every agent fails the **same** test and nobody passes | Likely UNFAIR, not hard | Stop hardening. Trace that test's assertions to a meta sentence. If none exists, the test is the bug |
| One dominant cause but **some agents cleared it** | Legitimate design wall (L18) | Keep it. Harden elsewhere — a second axis, or the cross-product cells |
| Pass rate fine, but the **contract enumerates N independent rules** | Checklist meta (L1) | Rule-7 de-enumerate: state the general principle, delete the instance list. Raises difficulty and shortens the meta |
| Pass rate **SWINGS** across batches (0/90/20/57) and every failing run fails the IDENTICAL test set | SINGLE SEAM: the rate is a coin flip, not a difficulty (L20). Do NOT re-tune wording | Add a lever whose failures are INDEPENDENT of that seam — if the seam is nested, harden FLAT. Confirm via a kill table showing two separated clusters |
| A **clarifying example** was appended to a general rule to clear a fairness flag, and the next batch jumped | The example narrowed the rule and disarmed the seam (L21) | Delete the example, keep the rule. Do not re-hide the rule — that re-creates the unfairness |
| Pass rate is **BIMODAL across batches** (0/70/0/0/70) and the artifact barely changed | The seam is in the HARNESS, not the feature — usually a base-mode skip toggling an axis on and off (**F-12**) | Fix the harness axis deliberately and re-read every prior batch against the setting it actually ran under. Do NOT compare rates across different skip settings |
| Runs pass **every feature test** but fail baseline | **F-12** repo-test preservation. This is real discrimination, not noise — it was half the band on numbat | Keep it. Skip only the tests the feature genuinely invalidates. Relocating them is blocked (test patches may not touch `src/`) and solution-side deletion breaks your own p2p |
| A review finding tells you to change behaviour | Verify against the repo FIRST (L23) | A finding can be factually wrong, or complying can make the solution inconsistent/unsolvable. Check, then comply, contest, or comply differently |
| The contract invalidates a **record / entry / block / section** and every fixture puts the violation in the header row | The format-noun extent is unstated, and both readings agree on your fixtures (L24) | Move the violation into an AMENDMENT row (**F-13**). Measured 6/10 on rust-minidump, 3 of them sole-failure near-misses. Keep the header twin as the fairness proof |
| A **tolerance rule** ("allow one, stop at the second") and only the AT-threshold fixture exists | The at-threshold fixture cannot discriminate — it passes under stop-at-first too (L25) | Author the **N-1** fixture asserting nothing happened (**F-15**). Measured 4/10; the N fixture killed 0 |
| The subsystem has several existing "cannot continue" exits and you added a **declared** stop reason | Agents will wire the new state to all of them (**F-14**) | Assert the ORDINARY terminal state positively on a clean run, and couple the output rule to it so a merge breaks output too. Measured 3/10 |
| You hardened a **baseline-preservation** axis on the evidence that it reds N existing tests | Mutation-grade evidence, not agent-grade (L15) | Keep it for FAIRNESS (unstated preservation is unfair) but do not count it as difficulty. rust-minidump: 0 baseline failures in 10/10 runs |

| The batch reads **0%** and several runs share a failure whose assertion is an `AttributeError`, an import error, or a helper's line rather than a feature assertion | The VERIFIER is failing, not the agents (L85). A test helper is calling something only your reference defines | Regex every `.method(` in the test files and require a `def method(` in the BASE source. Then replay the saved patches against the repaired suite before concluding anything about difficulty. siliconcompiler-flist-roundtrip: a helper calling `get_filetypes()` masked 5-7 tests in 11/11 runs, and those tests PASSED once it used base API |
| The batch reads **0%** and N runs fail the identical test with the identical diff on a FORMAT detail (a separator, a case, a joining rule) | Ambiguity, not difficulty (L85). Unanimous identical output is the signature | Find the sentence and check it against its neighbours: a list of spellings written in one grammatical frame teaches the frame. State the odd one literally with an example. siliconcompiler: `-G` written like the spaced flags made 11/11 emit `-G NAME=v` |
| You must choose WHICH requirement to cut after a 0% batch | Intuition misprices this; the gap between "fair" and "too easy" is one sentence (L86) | Replay every saved patch against each candidate suite in the platform image and read the rate per option. siliconcompiler: unfair-only fixes 0/11, also cutting one wall 3/11, additionally clarifying the ownership sentence **9/11** — the last looked like the same class of fix and would have killed the problem |
| An axis kills a real fraction and the contract phrase behind it has **two readings** | Explicitness is a dial, not a switch (L87) | Decide deliberately which setting you want, then measure it. siliconcompiler: the same pre-existing-root test killed **6/11** under "a root registered earlier" and **0/10** once the sentence named both readings, with no code change |
| A mutation **survives your whole suite** | Not proof the behaviour is untestable — proof no fixture reaches it (L88, the converse of L15) | Build the fixture the mutation needs. siliconcompiler: the surviving "edges recorded on the reading design" mutation forced a three-level chain fixture, which became the **7/10** lead killer |
| The batch **collapsed to 0%** right after a description clause was softened for fairness, with the tests unchanged or easier | The PROMPT set solution quality, not the suite (L45). Agents built less because you asked for less | Replay the OLD batch's saved solutions against the CURRENT suite BEFORE touching a test. If they still pass, the suite is fine — restore pressure with a clause naming the surviving discriminators behaviourally, promising nothing about iteration counts or unbounded scale. customasm-derived-bank-layout: same 20 solutions, same suite, **5/10 under the unbounded clause vs 0/10 under the bounded one** |
| A review finding names a directive / padding category / output-stage edge that **meta.md never mentions**, and asks for a regression test | The reference fix is free; the FIXTURE is a gate on unstated behaviour (L46) | Fix the reference, decline the fixture in writing. Such a gate kills the whole population and, even when it changes no verdict, displaces the near-miss agent's blocker. customasm: removing two of them took batch 2 from **1/10 to 2/10** and produced the first Nova pass in 19 runs |
| The **FP panel voids every pass** while the wrapper reports a healthy rate | The suite cannot tell a real solution from a broken one; the wrapper rate is noise (L28) | Read FP CORRELATION first. Uncorrelated FPs (each pass failed a DIFFERENT probe) = close them one at a time, each costs one run. Correlated FPs (all failed the same probe) = closing it zeroes the batch, so relax the contract instead |
| Your test helper computes a **structural proxy** for a semantic/geometric contract | **F-17** proxy-metric drift — the suite is blind to exactly its own gap | Rewrite the helper in the contract's vocabulary; add one fixture where proxy and property provably diverge. Measured 8/10 |
| A batch reads **0%** and one cause accounts for most of the kills | Before planning to soften it, check whether that axis HAS a middle setting: read the junit files and ask how many runs fail EVERY cell of it. If they all fail every cell, dropping one cell flips nobody and dropping the axis flips them all (**F-23**) | Do not touch the trap. Look instead for a run whose sole failure is a REPRESENTATION pin — an assertion on the TYPE of a returned value meta.md only gave a VALUE for. Un-pin it with a tolerant reader, re-eval, and that one run flips. Measured on rocketpy: softening the lead trap was 0/10 -> 56% (over ceiling); un-pinning the representation was 0/10 -> **1/10, accepted** |
| The lever you are considering is **test-side only** (`test.patch`) | The platform's Re-eval regrades the same solution population for ~30% of a batch, and for a TEST-ONLY delta the local replay predicts it EXACTLY (L35's caveat applies to description deltas, not these) | Replay the saved `agent-runs/*/solution-patch.patch` on clean BASE_COMMIT checkouts first and record which runs flip; then re-eval and confirm. Measured on rocketpy: local replay said "Nova #8 flips to 146/146, Nova #2 unchanged at 6 failures" and the live re-eval returned exactly that |
| Your rule quantifies over the **outcome of a caller-supplied object** reached through an interface with no accessor, and every fixture uses the repo's own implementation | Agents will downcast to the repo's `Abstract*` base to read the field; the guard silently excludes every other conforming implementation (**F-21**) | Add ONE fixture on a conforming implementation OUTSIDE that base class, plus the clause "whatever `X` the caller supplies". Measured 5/10 on datafixerupper and the SOLE failure of the 172/173 near-miss; without it the batch reads 60%, over the ceiling |
| The feature adds an **analysis pass over a caller-populated namespace**, and the batch reads soft | The pass needs a total function; agents have not yet been forced to decide what a MISSING key means (**F-24**) | Find the repo resolver's missing-key throw, confirm the base suite passes with it deleted, then add ONE clause naming the semantic difference ("stays an unknown type rather than a type without a value") plus two tests — the bare missing reference and one under a REQUIRED field. Measured 8/10 in TWO independent batches on dfu-derived-recursion, and the sole failure of four 85/87 near-misses |
| Your feature forces a **deferred placeholder** returned through a public API | Agents scope the placeholder's validity to their own pass, so a value the CALLER retained across the boundary throws or resolves against stale phase state (**F-25**) | Add a test where the caller assigns the reference to a local and reuses it in a LATER registration, and one where the retained reference closes a cycle. 4/10 + 4/10, zero description words. Take the reference AFTER its target is registered |
| Auto Review found **defects in your own reference** and you fixed them | Each one is a free difficulty lever you have already paid for: the agents face the same design pressure you did (**L50**) | Turn each finding into a regression test, then replay the saved passers before shipping it (L40). On dfu-derived-recursion the three that got tests took 4, 4 and 3 of 10 runs — 11 of 32 kill events — while the 79 tests the DESIGN was about killed nothing. They will not move a rate already saturated by a dominant cluster; bank them as discrimination, not as band |
| Batch reads **0%**, the walls are gone once the description defects are removed, and the failing tests are a STACK of regression tests each added for one reviewer finding (30-60% each) | L50 over-applied: independent reviewer-finding traps multiply to zero (**L55**) | Re-grade the saved solutions locally with candidate subsets removed. Keep the findings that share a root cause with a designed trap, demote the rest to reference-only fixes. If no subset passes anyone, the SPEC is too dense (next row). ray-optics: both walls removed still read 0/11; after the redesign three kept tests carried 17 of 40 kill events at 1/10 |
| The only pass is **FP-flagged**, and probing the saved solutions shows EVERY agent violates some stated-but-untested sentence | The description, not the suite, is over-specified (**L53**). Testing each behaviour stacks the rate to 0; leaving it untested keeps the FP exposure | Build the probe table (PATTERNS-ADVANCED Pattern 89): one row per stated-but-untested sentence, count violators. Delete or scope the clauses with the most violators, then re-derive the tests. ray-optics: violators 10/10, 8/10, 7/10, three clauses deleted, batch 3 a clean 1/10, accepted |
| A review finding is about **precision** (floating-point width, completeness of a reachability analysis) rather than a wrong answer | Meeting it means emulating another numeric model or demanding a new analysis from every agent (**L54**) | Scope the promise in meta.md to what the base design delivers ("while every value is exactly representable as a 32-bit float", "other unreachable branches may still be included"). Keep the extra precision in the reference, untested. ray-optics: the feasibility test failed 14/21 saved solutions before it was scoped away |
| **Every failing run fails EVERY new test**, and evaluators say "stale", "restored" or "unbuilt" binary | The harness graded the baseline binary: agents `git restore`d tracked build outputs and a plain `make` skipped the rebuild (L63). Nothing about difficulty can be read from these JUnit files | Make test.sh rebuild what it tests regardless of timestamps (`make -B <targets>`), which is Re-eval eligible, or contest each flagged run with the trajectory call that restored the binaries. Diagnose difficulty from the evaluators' static findings meanwhile. tippecanoe: 7/10 stale, 2 ENV flags contested and upheld |
| A cluster fails the SAME test at the SAME index with a sentinel value (0.0, silence, empty, timeout) in every run, even with passes present and evaluators calling it fair | A harness boundary, not a trap (L69): the test throttled one resource and asserted on another, or waited past what the gate allows (L70). L18's checklist cannot see it | Replay each failing patch against the test with the boundary relaxed (clean base + agent patch + test.patch). If they pass, fix the test (Re-eval eligible) and read the band off the replay. kira-loop-crossfade: accepted at 3/10, 9/10 on the fair suite |
| Rate reads soft on a feature that adds a recourse (drop, skip, truncate) and reports what it did in metadata the tool already merges from its inputs | The accounting cells are unfilled | Add the degenerate attempt (one item the recourse cannot act on, with and without inherited records; **F-15**) and two inputs carrying distinct inherited values whose aggregate the contract redefines (**F-33**). 4/10 and 3/10 on tippecanoe, both first found as bugs in the reference |
| Rate reads soft on a feature whose algorithm the contract already states step by step (allocation, merge, normalisation), and the kernel tests killed nothing | A fully stated kernel is transcribed (L58); more kernel cells will not move the rate | Look where prose cannot reach: a repo helper the new regime drives into its lossy path (**F-39**, 3/11 on featurevisor) and, in TS/JS, a record keyed by user strings that must hold `__proto__` (**F-40**, 7/11). Both started as reference bugs. Keep F-40 beside a core killer or the review files the rate as overstated (L74) |
| Batch reads **0%** and ONE test failed in EVERY run, pinning the TIMING of a derived view (a sensor, cache or index) relative to the action under test | A timing pin the description never stated (L8), not a wall. ir-sim: 11/11 on "the sensor has NOT yet seen the spawn at the spawning check"; every agent refreshed immediately, and a later Solution Quality round required exactly that | Assert only what holds under both timings (seen by the next step), re-eval, then let the description or a reviewer choose the timing before pinning it. Replay said 1/11 and the re-eval returned 1/11 |
| A differential probe finds **zero divergence** among the passers, and every reviewer coverage suggestion replays at 0 new kills | The derivable surface is exhausted (L83); more cells will not move the rate | Stop adding cells. Grep the persistence and aggregate layers for state the repo discards (a commented-out read, a sentinel on load) and make the feature depend on it (**F-47**). A description delta, so pay for a batch. libspatialindex: 57 probes + 16 tests = 0 kills; the discarded end-of-motion field took 7/10 to 5/12 |
| Batch reads **0%** and most failures are the repo's own self-check (`isIndexValid()`) asserted in YOUR test | A representation pin, not a wall (L82) | Delete the assertion, keep the oracle comparisons, and replay. libspatialindex: 9 of 10 blockers; the same solutions replayed 0/10 -> 5/10 |
| Rate reads soft on a feature that creates objects at runtime in an engine whose loader injects a per-entry attribute | The runtime-object integration cell is unfilled | Add one object that depends ONLY on the loader-injected key (a group-behavior-only robot): **F-41**, 10/11 on ir-sim, sole failure of six near-misses. Do not spend rounds on lifecycle paths the prompt names (three reset paths, id rewind, list aliasing, lazy tracking: 0/11 there) |
| A reviewer asks for a regression test of a reference bug, and the local replay shows EVERY agent (and every passer) has the same bug | L76: the test zeroes the batch, and a description that says the opposite makes it hidden | Keep the reference fix, ship no test, write the contest note. ir-sim: id rewind vs created-but-unadded objects, 11/11 in the replay; the FP adjudicator later ruled the same probe unfair |
| Rate reads soft on an expression-language feature whose IR feeds both a static analysis and a code generator | The analysis's exception cases are unfilled | Add **F-26** (identical operands through the estimator), **F-27** (the dual combinator's polarity) and the **F-10** lowering cell (valid node over a maybe-invalid operand). Zero description words each; 7/10, 6/10 and 6/10 on ray-optics |
| A reviewer-found reference bug is shared by EVERY run, and the contract already implies the behaviour | Re-eval with its test reads 0/N; shipping without the test leaves the passers as provable false positives | State the root cause in one meta.md clause and pay for a fresh batch (**L77**). featurevisor-target-specialization: the scalar-JSON parser gap was 10/10 in the replay; one clause took it to 0/10 kills and the batch read 3/10 on the other walls |
| You **deleted a contract clause** because nothing could implement it soundly (L41) | Correct for soundness, but the clause was carrying band, and its tests went with it (L44) | Budget an orthogonal lever in the SAME round, exactly as for a fairness disclosure (L34). datafixerupper: deleting the supplied-builder contract plus 9 tests took the batch from **2/10 to 5/10**, +30 points, and no reviewer mentioned the loss |

| **0 passes across repeated batches, and one axis carries most kills** | The problem is UNSOLVABLE, not hard. An axis is acting as a wall nobody reaches | **DROP that feature** — its tests, its contract sentences AND its half of the solution. Verify BEFORE the batch with the differential harness: apply the near-miss runs' own patches to the reduced suite and count who now passes (L32). gluon went 0/12, 0/14, 0/10 to an accepted 1/11 by dropping one printer axis |
| A run of **fairness clarifications** landed, and the next batch reads soft with the disclosed traps at 0 kills | Each disclosure was a difficulty DEBIT that settled a batch later (L34) | Do NOT just re-hide the rule. Add an orthogonal trap in the SAME round as any future disclosure. Diagnose by clustering kills per batch: a cluster that went n/m to 0/m is a trap you disclosed. vrp-tsplib: display-data 2/9 to 0/10 and GEO 1/9 to 0/10 across three rounds, leaving one trap and a 50% batch |
| The batch reads **0%** and ONE cluster of tests failed in every run | Compute the binomial before redesigning (L38). Pool with prior batches: at a true 10% rate **P(0 of 5) = 0.9^5 = 59%**, so 0/5 is weak evidence of unsolvability | If the cluster is ONE root cause and the contract already states the behaviour, agents are missing WHEN it must hold, not THAT it must. Restate the timing inside the existing sentence, naming no API. go-workflows: 5/5 kills to **1-2/10** from one clause, and the batch passed. Deleting was impossible — all 5 tests were one insight, so any subset left the near-miss failing |
| An **FP panel** flags a passing agent's defect | That defect is a live discriminator, not just fairness debt (L37) | Write the guard as a test — and re-read EVERY passer's diff for the same defect CLASS first. The panel names the instance it can see. go-workflows: the panel flagged 1 of 3 passers; the identical defect was in a second passer it cleared, and the guard became F-20, the band decider |
| The **differential harness** predicts a healthy kill count for a lever that also added a meta.md sentence | The harness measured a TEST delta, not a DESCRIPTION delta (L35) | Treat the count as an UPPER BOUND and discount hard. Replayed agents never read the new sentence; the next batch will. vrp-tsplib: 3 of 5 replayed patches killed, **0 of 10** live agents. Trust the harness only for tests-only changes. When the description delta is a DELETION the harness is close to uninformative: datafixerupper replayed both batch-8 passers against the reduced suite, both failed, projecting **0/10 = unsolvable-reject**, and the batch returned **5/10**. Since 2026-09-03 the platform decides this FOR you: a tests-only lever gets a **Re-eval** button (real grading over the last batch's solutions, ~30% price), and a lever that touched meta.md gets no button at all |
| The candidate lever states a rule with exactly **one reasonable implementation primitive** (a sort order, a canonical form, a well-known normalisation) | Stating it hands the fix. Subtlety of the WRONG version is irrelevant | Reject the lever. vrp-tsplib stated "ascending node-number order" and tested at DIMENSION 12 with permuted input so a lexicographic sort of the id STRINGS breaks past node 9 — every one of 10 agents sorted numerically. Spend the round on an intersection nothing tests instead |
| A clarification is proposed to convert near-misses | Wording is a rate lever with a PRICE | Price each candidate against the run artifacts before adding it. On gluon three candidates priced at 7/12, 4/12 and 2/12 passes; only the one fairness actually required was kept |
| Every run **changed an existing behaviour the feature never asked to change** (a step, flag set or default "repaired" to match the new prose), and a graded PASS carries it | The description's placement prose described the old behaviour as something else (**L57**). The suite never pinned it, so this is an FP seam, not difficulty | One clause saying the existing behaviour is kept, plus one end-to-end test pinning it. worldengine: `Step.plates` stripped in **10/10** runs after "a winds step between plates and precipitations"; the sentence and test took it to **0/10** |
| The rate reads soft and the kill table shows the **numerical kernel tests at 0** while integration tests carry every kill | The formulas are fully stated and were transcribed (**L58**); more kernel cases buy nothing | Harden the integration shape: the concept's container representation (**F-28**), accessor form (**F-16**), lifecycle guards (**F-29**). worldengine: 24 transport tests 0 of 20 runs; three round-trip tests 23 of 46 kill events |
| A batch reads **0%** right after you added tests for **pre-existing divergences between twin implementations** (a Python spec vs its C++ port, both found by Solution Quality) | Parity imported bugs the feature never touches; each test is a fresh wall (**L60**, a twin-shaped L55) | Keep every fix in the reference, drop the tests the feature's own inputs cannot reach, and replay the saved solutions in Docker over candidate suites before re-eval. cwerg: strict **0/9**, suite without float-DIV parity and narrow DIV/REM chains **3/9** in replay, accepted batch **3/10**; the FP adjudicator overruled every DIV-parity dissent as pre-existing |
| One test **kills everyone** and it was added for coverage breadth, not for a designed trap | It may be reaching a pre-existing bug outside the feature (**L61**) | Apply the near-miss run's own patch and bisect the test program before editing meta.md. cwerg: the parity-only `bulkshapes` program killed 11/11 through callee-parameter widening; dropping it took the re-eval to 1/11 |
| Rate reads soft on a compiler feature in a repo with a width/promotion pass or Python + C++ twins | The pipelines the feature does not run through are untested | Run the same golden program through every pipeline the repo already has: optimized first (**F-30**), folded constants compared across twins (**F-31**), many occurrences through the strict text renderer (**F-32**). 10/10 → 2/10, 2/10 and 2/10 on cwerg |
| Batch reads **0%**, mostly Nova, near-misses at N-1 or N-2 fail STATED sentences, and a probe on their patches confirms they truly violate them | Agent mix, not solvability (**L65**) | Do not cut or soften. Append Orion or Vega runs to the pool: on sfepy four appended runs turned 0/12 into 2/15. Dedupe the pool before mining it (**L64**) |
| The top killer is a **rollback returning the wrong state**, and the failing patches have a correct-looking rollback branch | **F-34**: the snapshot aliases a buffer the solver mutates in place | Keep it if a passer copied. Check the fixture's rejected solve actually MOVES the iterate, or the test sees nothing |
| Most runs fail one test a meta sentence plainly states, and you suspect the test reads a different surface | Unfair only if the surfaces disagree | Probe the near-miss patches first (Pattern 93): same object and both wrong means the wall is fair |
| Batch reads **0%** and ONE test fails in nearly every run for the identical reason, and that test was added for a reviewer finding about **pre-existing** behaviour meta.md never states | A hidden requirement, not difficulty (**L66**) | Drop the test, keep the reference fix, and replay the saved patches in Docker to project the re-eval (**L68**). mwparserfromhell: `<ß>x</SS>` pairing 19/20, dropped, projection 3/20, re-eval **2/19**, accepted |
| Batch reads **0%** and EVERY run fails ALL new tests with the same compile error on a symbol the solution adds | The description never stated its call shape (**L72**); the batch measured nothing | Do not harden or soften. Replay each saved patch with a one-line adapter to the tested shape to read the real rate, then state the shape in meta.md (a description delta: full batch). planetiler: shim 2/8, paid batch **3/10** |
| One run's grading fails before any test with a dependency-resolution error the other runs do not show | The agent broke the local artifact repo inside the grading container (**L73**) | Make test.sh detect the signature and repair offline; reproduce with the agent's exact command from its trajectory. planetiler: unflattened `${revision}` POM |
| Rate reads soft on a layered-config or overlay feature | Every merge rule is stated, so it is transcribed (L58) | Add the provenance cell (**F-38**: one input adds then removes the same id) and the origin cell (**F-9**: a second consumer re-resolves a reference from a bundled root). planetiler: 7/10 and 3/10 |
| Rate reads soft on a twin-implementation parity feature and the passers are small | They forward one arm to the other (**L67**); the second arm is not a wall | Harden the SHARED arm instead: the run-consumption invariants (**F-36**) and the reader's in-band sentinel (**F-37**), then a seeded parity corpus. mwparserfromhell: 11/19 and 7/19 |
| Batch reads **0%** right after a carve-out sentence was added, and the killed tests exercise calls the carve-out never names | A one-sided carve-out (**L89**): naming only the exception class leaves every unnamed call on the wrong side for some readers | Name members of BOTH classes and place every tested call by name. A description delta: pay for the batch. pyfakefs-block-inode-accounting: five unchanged tests went 0/11 to **10/12** kills under the one-sided sentence and back to **0/10** once both sides were named |
| Rate reads soft on a resource-accounting feature and the designed walls (moves under a reserve, resize through an unlinked descriptor) killed nothing | Those walls were stated and transcribed; the unstated derivations are where agents diverge | Add the boundary just past an unlimited mode's REPORTED figure (**F-50**, 2/10) and the non-default OS branch of the size getter (**F-51**, 3/11, 5/12, 1/10). pyfakefs: reserve renames and unlinked-fd resize fell to 0/10 in the accepted batch; 108 of 117 tests killed nothing |
| Each Solution Quality round finds another reference bug and asks for its test, and the batches keep reading **0%** | L91: the gate ratchets requirements into the suite; each test is fair alone, the stack is unsolvable | Fix every bug in the reference, but add a test only where a saved-patch probe shows passers already split on it. pyfakefs: 27 reference bugs across rounds; the accepted batch's three near-miss killers were all probe-backed ones (L90) |

| Batch reads **0%** and the tests for ONE rule a review round added are the sole failure of every near-miss | The rule, not the problem (**L85**) | Cut it from contract, solution and tests together, priced by replaying the saved patches (**L86**). pyocd: a predicate-must-be-a-value rule killed 8/11; the replay projected 2/11 and the next batch read 5/10 |
| A reviewer-requested test replays at **0/N** and meta.md does not state its requirement | The replay is measuring an UNDOCUMENTED requirement (**L35**) | Do not simply withhold it: state the requirement literally with an example, then ship the test. pyocd JTAG byte responses: 0/11 on replay, **0/10** kills once stated |
| A kill is attributed to a rule from the TEST NAME, or a near-miss dies on an argument the rule does not govern | An accidental trap (**L92**) | Read the assertion diff before diagnosing. If a non-governed argument got an out-of-range value, fix the fixture (a test-only change, re-eval eligible). pyocd: `tms=3` vs documented 0/1, 3/10 |
| Rate reads soft on a whole-program analysis feature and the passers all solved the recursion tests | The all-paths fact has no cycle that ONLY an optimistic start proves | Add a jointly never-null cycle with one anchored exit (**F-53**, 4/10 on teavm) and an unanchored pure cycle; state "most precise facts for all methods at once" |
| Every gate-requested test replays or reads at **0 kills** | L95: gates find the author's mistakes, not implementers' | Keep them as insurance; for difficulty, look for behaviour agents have a reason to CHANGE, such as a legacy off path the contract preserves (**F-54**, 2/10) |
| Batch reads **0%**, ONE test kills every run, and every failing patch made the same alternative design choice, several explaining it in comments | A gate-demanded CHOICE the prompt only implied (**L97**) | State the choice in one sentence (a description delta: pay for the batch). Do not cut the test. bayesopt: GPHedge per-candidate scoring 11/11 → **0/10** once stated; the accepted batch read 3/10 |
| Rate reads soft on a reconfiguration feature (change a space, schema or topology of a live object) | The rule holders and collaborators were each tested alone | Extend one stated rule to every secondary holder of points (**F-10 holder cell**, 6/10) and test collaborator state with a change-then-undo twin (**F-56**, 5/10). bayesopt |
| A review-requested test replays at **10/10 failing** (the only passer too) although the rule it extends IS stated | An implied EXTENSION missed unanimously (**L100**, refining L97); a re-eval would read 0% | State the extension in one sentence and pay for a fresh batch; do not re-eval. piscsi device report after name reuse: 10/10 on replay → **2/10** once stated, accepted at 3/10 |
| Rate reads soft on an identity feature (paths, inodes, handles) and every alias test passes | Aliases are the easy half; nothing tests an identity that outlives its NAME | Rename the held object away and create a new one under the old name (**F-59**, 8 runs over two piscsi batches); add a later-vs-earlier conflict inside one staged command (**F-58**, 5 runs) |

**Before writing anything, check `TOO-EASY.md` death classes.** If the whole pick is a uniform
wrap, a pointwise-decoupled rule set, or a memorised spec port, hardening will not save it —
that is a redesign or a shelve, and saying so early is cheaper than three more rounds.

---

## Stage 3 — Pick the lever, in this order

1. **F-10 cross-product cells.** Write the axes as a matrix (`olympus-author` DESIGN.md § 11b).
   One axis with multiplicity (one/many, single/repeated), one with polarity (in/out, which side
   is anchored). Every off-diagonal cell needs a test. Measured as the sole failure of both
   near-miss runs on neva — the difference between a 20% and a 40% batch. Costs ~20 test lines
   and NO new description words, because a contract stating both axes already covers their
   composition.
   Also measured as RULE x RULE on csbindgen: two independently stated type rewrites (alias
   following x pointer-to-array lowering) composed in one cell family killed 7/10 while every
   direct form killed nobody (F-44).
2. **F-9 cross-stage resolution drop.** If the repo has a validating stage and an emitting stage
   in different packages, require an elidable form (an omittable name, an implicit default) and
   never say where to resolve it. One root cause then breaks every capability at once, which is
   interdependence for free.
3. **F-1 convergent-architecture wall.** Largest lever measured (+27 points) but you must read
   passing patches first, and it can overshoot to 0%. Mitigate by naming the ROOT CAUSE in the
   meta (HARDENING 3c-bis) without naming the fix.
4. **A second orthogonal mechanism.** Only if 1-3 do not apply. It must be measured on a
   DIFFERENT axis from the existing traps — a trap sharing an axis dies with its neighbour the
   moment review forces a disclosure on that axis (lyon: the named-algorithm trap and an
   independent-oracle test covering the same behaviour were mutually exclusive).

**What not to reach for**, all measured as ineffective:

- More instances of an already-covered axis (neva round 8: 2 new tests, 6 kills, all correlated
  with the existing lead trap, zero outcome change).
- More LOC, more files, more requirements — those move scope, not pass rate.
- Tricky wording on a small problem.
- Anything justified only by a mutation kill count.
- Breadth of independently stated rules. csbindgen shipped 70 F2P cells over ~30 stated rules
  (Int128 alignment, zero-size fields, unions, bitfields, pack/align, transitive promotion); 63 of
  them killed NOBODY in the accepted batch. Difficulty came from three composition / model-reuse
  cell families (F-44/45/46).
- **Not a hardening case: a 0% batch.** If agents are one cell short across the board, the lever is
  the reverse (L77 / L81: name the combination or the missing list member in one clause). csbindgen
  measured it: 8/16 -> 0/10 and 7/16 -> 1/10.

---

## Stage 4 — Fairness guard (run BEFORE writing the test)

Every candidate trap must clear all five:

- [ ] **Contract-stated.** Quote the exact meta.md sentence the test traces to. If you have to
      add a sentence, add it — the trap survives statement or it was never a trap.
- [ ] **Fix-hidden.** The sentence states WHAT, not HOW. It does not name a file, a helper, a
      usage map, or an algorithm step.
- [ ] **Not contradicting the repo's own docs (L19).** A wall that only stands because the
      analyzer is laxer than the published book is a fairness bug that happens to be hard. Grep
      the repo's docs for the rule you are relying on before you build on it.
- [ ] **Not re-adding a wall fairness review already removed.** Rebuilding it with different
      wording burns reviewer credibility and the round.
- [ ] **Deterministic.** No timing, no unseeded randomness, no ordering assumption, no network.
      If the only way to discriminate is a race, the trap is not shippable — record why and drop it.

---

## Stage 5 — Verify

**The mutation harness serves TWO masters — run it for both.** For DIFFICULTY it answers "does this
lever kill anyone" (and L15 warns the answer does not predict agent kills). For FP SAFETY it answers
"is this branch tested at all", which mutation evidence DOES settle. Never skip it just because L15
says mutation kills are weak difficulty evidence — they are strong coverage evidence.

**After any hole-closing round, re-run fairness on the NEW assertions only (L29).** Tightening and
fairness pull opposite ways; the assertions you just added are the ones nobody has checked.

**★ Close a tests-only round with RE-EVAL, not a fresh batch (2026-09-03).** If the round touched
only `test.patch` / `solution.patch`, the platform offers a **Re-eval** button that re-grades the
LAST batch's agent solutions for ~30% of batch price. That is the differential harness you were
approximating locally, run by the real grader on the real solutions — so it, not your local kill
count, is the number for the round. Two rules: (1) never fire a smoke run while a re-eval is
pending, any fresh run dismisses the offer; (2) a re-eval is PAIRED on one fixed solution set, so it
steers the lever but does not re-roll batch variance — confirm the submitted number with a fresh
batch. If the button is absent, your lever added a description delta: pay full price (see L35 row).

**Trap-proof the new lever.** Write the natural-but-wrong implementation on top of your
reference, build it, and count kills across the whole suite. A lever that kills nothing is not a
lever. Keep the harness — restore the file from a pristine copy between mutations and assert the
patch applied, because a silently-no-op string replace produces a confident, wrong "kills
nothing" result.

**Then full clean-room validation, every time:**

```bash
# fresh clone at BASE_COMMIT, test.patch only
./test.sh --output_path /tmp/b1.xml base   # must be green
./test.sh --output_path /tmp/n0.xml new    # EVERY new test must fail
# apply solution.patch
for i in 1 2 3; do ./test.sh --output_path /tmp/n$i.xml new; done   # identical 3x
./test.sh --output_path /tmp/b2.xml base   # still green, no regressions
```

**Counter-2 (`human-effective`) check.** `CLAUDE.md` still points at
`.claude/hooks/effective_loc_check.py`, which **does not exist in this workspace**. Use this
inline equivalent — it strips blanks, comments, brace/punctuation-only lines, package/import
lines and trivial no-ops, the way the human reviewer does:

```bash
python3 - <<'EOF'
import re
lines = [l[1:] for l in open('solution.patch') if l.startswith('+') and not l.startswith('+++')]
def keep(l):
    s = l.strip()
    if not s or s.startswith(('//', '/*', '*')): return False
    if re.fullmatch(r'[\{\}\(\)\[\],;]+', s): return False
    if s.startswith(('package ', 'import ')) or re.fullmatch(r'"[^"]+"', s): return False
    return s not in ('return', 'continue', 'break')
raw = len(lines)
blank = sum(1 for l in lines if not l.strip())
com = sum(1 for l in lines if l.strip().startswith(('//', '/*', '*')))
print(f"raw={raw} counter1={raw-blank-com} human-effective={len([l for l in lines if keep(l)])}")
EOF
```

Gate on `human-effective` >= 200 (design to 250-300 so a later removal does not dip under).
`counter1` is the looser platform auto-block measure and clears automatically once Counter 2 does.

Regenerate BOTH patches after any source change, and re-check `human-effective` — removing a
now-dead helper can drop it more than you expect.

---

## Stage 6 — Record honestly

In `feedback.md`, for the round: the diagnosis, the lever, the MEASURED kill counts, and the
predicted effect on pass rate. If the lever is expected to be marginal, say so. If you removed a
wall for fairness, state the difficulty cost in plain terms rather than implying the replacement
covers it — the next batch will find out anyway, and the record is what makes the next problem
better.

Append the round to `eval-results.md` with the full validation table.

---

## Anti-patterns

- **Hardening without a diagnosis.** Adding a trap because it is writable, not because the
  evidence points at it, is how three rounds produce zero kills.
- **Treating a mutation kill as a difficulty measurement.** It is a test-coverage measurement.
- **Buying difficulty by removing a sentence.** That is a fairness failure with extra steps
  (`TOO-EASY.md`: difficulty-from-misdirection cannot survive full fair specification).
- **Declining a reviewer's coverage suggestion to protect a trap.** Those suggestions have
  measured out as free difficulty (L17); the one taken on neva decided the batch.
- **Stopping at "it now kills more mutations."** Only real grading closes the loop — a re-eval for a
  tests-only round, a fresh batch for anything that touched the description.
- **Burning a full batch on a tests-only round.** Since 2026-09-03 that round re-grades at ~30%.
  Check for the Re-eval button before paying for solving you already own.
