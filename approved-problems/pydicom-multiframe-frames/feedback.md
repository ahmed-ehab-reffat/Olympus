# feedback — pydicom-multiframe-frames

Tier: Olympus. Shape: O-Algorithm-correctness (new capability with a subtle,
globally coupled correctness kernel).

Repo: https://github.com/pydicom/pydicom — MIT, 2193 stars, pure Python with no
runtime dependencies, 143k LOC, last source commit 2026-08-02.
BASE_COMMIT 0e98c4aeecce7c3ae537e3fbe9133d3fbc005796.

## Assumptions and decisions logged during the autonomous run

- The user did not name a repo or tier, so the standing preference recorded in
  memory was applied: a repo never touched locally, a new hard feature, Olympus.
  pydicom appears in none of `worktrees/` (311 clones), `problems/`, `rejected/`
  or `Instructions/Aprroved/`.
- Repo ranking. rdflib, pydicom, oxigraph, gopcua, pyomo, logica, malloy,
  vega-lite, sipgo, spade and construct were screened. rdflib was cloned and
  dropped: every large gap in it is either a W3C specification (transcription, a
  dead class here) or already covered by a sibling package (owlrl, pyshacl,
  rdflib-canon), and its one big invented option, rewriting the SPARQL algebra
  back to query text, is pointwise decoupled per algebra node and self
  verifiable against the in-repo parser, which is the gimli reader-is-an-oracle
  failure. pydicom won on: unmined domain, pure Python with zero runtime
  dependencies (trivial offline image), a rich domain model, and a real gap.
- Feature invented rather than taken from an issue. pydicom has no functional
  group support at all: `grep -rn "PerFrameFunctionalGroups" src/` matches only
  the data dictionary.
- meta.md is 498 words, over the 200 word guidance but under the 500 word hard
  cap. Every sentence maps to at least one test; nothing was cut to hit 200
  (`olympus-meta-word-cap-conflict`).

## Gates run

- Licence: MIT, single licence file.
- Stars/activity: 2193, source commits through 2026-08-02.
- Saturation: not in `SATURATED-REPOS.md`; niche 2.2k star domain library, not
  the author-obvious host for a whole tooling category.
- Dedup: the only DICOM artefact anywhere locally is
  `rejected/dicom-rs-palette-color` (different repo, language and subsystem).
- Exclusivity (canonical org `pydicom/pydicom`): PR searches for "functional
  group", "multiframe", "multi-frame", "extract frames", "frame subset",
  "enhanced", "anonymi", "uid mapping", "referential", "remap", "deidentif".
  Nothing implements functional groups or frame subsetting. The two plausible
  hits were diffed: #1725 (closed) adds a lazy pixel `framereader.py`, #534
  (closed) touches the pixel handlers. Neither reaches the core files here.
- Flakiness: new suite 5 runs, base suite 3 runs, byte-identical counts every
  time. No clock, RNG, ordering, network or filesystem-time dependence. The only
  randomness is `generate_uid()`, and no test pins a generated UID.
- Environment quality: the vanilla suite needs two things the image now provides.
  `pyfakefs` is a dev dependency five tests need, and four test modules cannot
  even be collected without the external data files, so the Dockerfile installs
  the former and runs `fetch_data_files()` for the latter at build time. One test
  is left over, `tests/test_data_manager.py::test_fetch_data_files`, which
  deletes a cached file and downloads it again, so it needs github.com and cannot
  pass offline by any arrangement of the image. It is deselected in base mode
  with that reason in a comment in `test.sh`. Three other arrangements were built
  and measured first: pre-fetching alone leaves that one failure, installing the
  `pydicom-data` package alone leaves the four collection errors, and doing both
  plus a `file://` mirror of `urls.json` turns on three more external-source
  tests that then fail. The chosen image is the one with the smallest gap.
  Everything else is green offline as uid 1000: 2632 passed, 1730 skipped.

## Difficulty work

The first suite was benchmarked against a deliberately diligent naive
implementation written from meta.md alone (subset the per-frame sequence, promote
what is common, prune and renumber dimensions, restack). It passed 110 of 111,
which is far into the too-easy band, so three independent architectural
discriminators were added and the naive implementation now fails 7 tests:

1. A macro the source stored in its shared groups must be re-derived, not
   edited. A frame that replaced it leaves a stale entry behind in the natural
   implementation.
2. A shared frame content macro has to be pushed down to the frames before
   in-stack positions and dimension indices can be renumbered per frame. An
   implementation that only touches the per-frame sequence never renumbers it.
3. A dimension that some frames do not reach is not "one value for every frame",
   so it survives; the natural set-based test drops it.

These are interdependent (all three run through the same macro-equality kernel,
and the renumbering must happen before the sharing decision) and misdirecting
(the failing assertion is about a stack position or a dimension label, not about
where a macro is stored). The pixel data behaviours (bit-packed frames crossing
byte boundaries, float and double float pixel data, re-encapsulation, dropping
the extended offset table) are further discriminators the naive benchmark could
not measure because it reused the reference's pixel module.

## Validation

| Check | Result |
| --- | --- |
| base + test.patch, base mode | 2632 passed, 2 deselected, 0 failed |
| base + test.patch, new mode | 301 failed, as 301 individual JUnit testcases |
| base + test.patch + solution.patch | 2632 base plus 301 new, 0 failed |
| solution.patch then test.patch | 2758 passed, 0 failed (host run, no deselect) |
| both patches unapply | clean |
| effective LOC (Counter 2) | 486 across 7 files |
| JUnit XML | 4362 testcases base, 301 new, 0 errors |

## Description Quality check — request_changes, and why the three HIGH items are not taken

The Description Quality checker asks to delete the error list, the whole
derived-instance rules paragraph, and the grouping/sorting/merge-compatibility
semantics, on the ground that "tests define" them. Taken literally that guts the
specification, and it is the exact opposite of what the Test Fairness gate has
demanded for sixteen consecutive rounds. Requesting a bypass on this check, per
`RULES.md`, which permits a justification for the automated description_clear and
test_quality checks.

The two checks disagree by construction:

- Test Fairness fails any test whose behaviour is not stated in the description.
  It has flagged 40+ tests across sixteen rounds for exactly that, and every fix
  was to state the rule. Deleting those sentences now recreates every one of
  those failures at once, and a hidden requirement is a hard reject, not a
  warning.
- Description Quality reads the same sentences as redundant with the tests.

Point by point:

1. **Error list.** Each clause maps to at least one test, and the mapping was
   built by the fairness gate itself. "no keys", "a key that is not an attribute
   name or tag", "a shared group sequence present but not holding one item" and
   "SOP class or instance UID" were all added *because* a fairness round or an
   agent run flagged their absence. Deleting the list turns roughly 60 validation
   tests into hidden requirements.
2. **Derived-instance paragraph.** This is not decoration, it is the feature. It
   states what "derive a new instance" means: the sharing rule, the order of
   renumbering, pixel rebuilding, identity, provenance, isolation. Without it a
   solver cannot know what to build, which fails the user's other requirement
   that the task be solvable. Orion run A failed 152 tests on one ambiguous
   clause; removing this paragraph would be that failure many times over.
3. **Grouping, sorting and merge compatibility.** Ordering rules are the
   contract. "In order of first appearance", "ties left as they were" and
   "missing after those that have it" are not inferable; an agent that guesses
   differently fails deterministically.

The MEDIUM items are declined on the same basis: the copy guarantee, the
single-frame empty result and the top-level reachability are each asserted by
tests, so removing the sentence creates a hidden requirement rather than removing
noise.

What I do accept from the check is the diagnosis behind it: the validation
surface is over-grown. The checker called the parity matrices "substantially
redundant" and this check calls the resulting prose noisy; both are symptoms of
the same thing. That growth came from taking coverage suggestions in rounds 12 to
15. It is recorded here as the lesson rather than fixed by deleting the
specification, because deleting prose that tests depend on trades a soft warning
for a hard reject.

## Attempt history

- 2026-08-03 — authored. Design, solution, 125 tests, Dockerfile, patches, all
  local gates green.
- 2026-08-03 — Test Fairness FAIL, 20 of 125. All twenty fixed and all five
  coverage suggestions taken; suite now 145 tests, meta 489 words. Nothing was
  weakened: the 7 architectural discriminators still fail the naive build, base is
  still 2632 green, and effective LOC went 438 to 445. Detail in
  `eval-results.md`.
- 2026-08-03 — round 2 coverage suggestions all taken; suite now 171 tests,
  effective LOC 448. `validate` now rejects a dataset with no pixel data so every
  entry point checks the same things, and `PlanarConfiguration` joined the merge
  compatibility set. One base run out of 14 reported 64 failed / 70 errors and has
  not recurred in 13 runs since; recorded in `eval-results.md` rather than
  smoothed over.
- 2026-08-03 — round 3 coverage suggestions taken. The merge one found a real
  bug: the pixel data element kind was never compared, so an ordinary and a float
  instance merged silently at the wrong stride. Now checked and stated. Suite 180
  tests, effective LOC 454, naive build fails 11. Three more base/new rounds in
  the container, all clean. Not yet submitted to an agent batch.
- 2026-08-04 — Test Fairness FAIL, 5 of 66. All five were the same finding: the
  tests pin the order of provenance, both the order of the items in
  *Source Image Sequence* and the order of the values inside
  *Referenced Frame Number*, and the description only said "one item per input"
  and "the 1-based numbers of frames taken from it". The checker is right that
  neither order was stated and that the repository has no producer convention to
  infer it from; only the dictionary entries exist. Fixed in the description, not
  in the tests: items are named "in input order" and the frame numbers "in result
  order". Six words, paid for by trimming eight elsewhere, so meta is 499 of 500.
  No test changed, no code changed, so the round 18 container matrix still stands.
  The five assertions are now exact statements of a stated rule instead of an
  unstated one, which is what fairness wants and what keeps them strong.

## Round 19 coverage suggestions — all three declined, with reasons

Unlike rounds 2, 3 and 12 to 15, these three cannot be taken without first
writing new description sentences, and the description is at the 500 word cap. A
test that asserts behaviour the description does not state is a hidden
requirement, which is a hard reject, so adding the tests alone would be strictly
worse than leaving the edge untested. None of the three is a hidden requirement
today, because no test touches it.

- **Merge dimension compatibility.** When inputs carry different
  *Dimension Index Sequence* descriptions, `organise` prunes and renumbers the
  values but leaves the description alone, because it only rewrites the
  description when its length matches the width of the value vectors. That guard
  is deliberate and nothing leaks: no `IndexError`, no `AttributeError`. Whether
  the right answer is that guard or an `uncombinable inputs` error is a genuine
  design question the description does not answer, and answering it costs a
  sentence I do not have room for.
- **Excess pixel data.** `check_length` rejects short data and tolerates long
  data, so trailing bytes beyond the frames are dropped when the pixel data is
  rebuilt. But the description lists "pixel data too short or malformed" as an
  error, and unexplained trailing bytes are readable as malformed. Both answers
  are defensible from the description as written, so a test in either direction
  would be the unfair kind.
- **Invalid argument types.** A non-integer index or a non-iterable `datasets`
  raises an ordinary `TypeError`. The description says nothing about normalising
  Python type errors into `MultiFrameError`, and claiming it would widen the
  validation surface that this same check has twice called over-grown.
- 2026-08-04 — Orion batch 2, run 1: FAIL, 308 of 325 new tests passed, baseline
  2632 green. All 17 failures were one miss, the two reading APIs skipping the
  full instance validation the four deriving APIs perform. Evaluator rated the
  description clear, the tests deterministic, the difficulty "challenging" and
  found no environment blocker. Fixed by stating the parity outright: "All six
  check what they are given the same way first." Meta 495 of 500 after trimming
  fifteen words. No test and no source changed. Detail in `eval-results.md`;
  artifacts in `agent-runs/batch2-orion1/`.
- 2026-08-04 — Description Quality warning on the re-export: tests assert
  `getattr(pydicom, name) is getattr(pydicom.multiframe, name)` while the
  description only said the names were "also reachable". Taken, not waived: "its
  names also reachable from `pydicom`" is now "the same objects also reachable
  from `pydicom`", which states identity outright. One word, meta 496 of 500. The
  test itself stays as it is; Test Fairness had already rated it
  repo-discoverable, since pydicom's own `__init__.py` re-exports Dataset,
  dcmread and the rest by direct import. The behaviours half of the check came
  back OK with no contradictions.
- 2026-08-04 — Test Fairness FAIL, 3 of 58, all three taken in the description.
  Two were the same gap: the reachability sentence enumerated only the six
  functions, so `pydicom.MultiFrameError` and its identity with
  `pydicom.multiframe.MultiFrameError` were unstated, and the checker confirmed
  the repo has no convention of re-exporting exceptions from `__init__.py` to
  infer it from. The error is now listed among the objects reachable from
  `pydicom`, and "All six" became "All six functions" so the parity sentence
  still means the functions. The third was `merge_frames` accepting a single
  input, which is a real API choice the prompt never made; it now says "all its
  inputs, one or more". Five words added, three trimmed, meta 497 of 500. No test
  and no source changed. The two loop tests were left alone rather than split,
  since renaming or deleting F2P test functions across revisions is not safe.
- 2026-08-04 — both coverage suggestions declined again, same reason as round 19.
  Incompatible `DimensionIndexSequence` schemas on merge and a present but
  non-numeric `NumberOfFrames` are both undecided by the description, so a test
  either way would assert an unstated rule. Neither is a hidden requirement
  today. Worth noting for a future round: a non-numeric frame count currently
  surfaces as a bare `ValueError` from `int()` rather than a `MultiFrameError`.
  That is defensible while untested, since `MultiFrameError` is a `ValueError`,
  but it would need both a sentence and a test to become a real behaviour.
- 2026-08-04 — round 21 coverage: two of three taken, suite 325 to 336 tests.
  `TestEmptyFrameSequence` (7) covers a present but empty
  `PerFrameFunctionalGroupsSequence` across all six entry points plus a positive
  control, and `TestKeyObjects` (4) covers `object()` and `None` as keys. Both
  are already stated: "no per-frame groups" covers an empty sequence, and "a key
  that is not an attribute name or tag" covers a non-key object. I checked the
  suggestion's other example before writing it: pydicom's `Tag` accepts a
  two-item list as a (group, element) pair and a float as a tag number, so a list
  key is a VALID tag, not an error, and asserting otherwise would have been the
  wrong test. Reference already handled all eleven cases; no source change.
  Revalidated: new 336/336, base 4362 with 0 failures, new-on-base 336 of 336
  failing, base-on-base clean, three identical new runs, effective LOC 486, meta
  497 words.
- 2026-08-04 — native excess data declined for the third time. It needs a
  description sentence to be testable either way, and the sentence would add a
  validation rule with no architectural value. Validation scope is exactly what
  cost the batch 2 run 17 tests; growing it further works against solvability,
  which is the current priority. Untested means unpinned, so an agent that
  accepts or rejects trailing bytes is unaffected either way.
- 2026-08-04 — round 22 coverage: the deep-copy one taken, suite 336 to 342.
  `TestUnrelatedSequenceIsolation` (6) puts a nested
  `ReferencedSeriesSequence` outside the functional groups and checks it survives
  extraction, sorting, grouping and merging, that neither the outer item nor the
  nested one is a source object, and that writing through the copy leaves the
  input alone. "Inputs are left unchanged and share nothing with the result" is
  unqualified, so this is stated, and it is a genuinely orthogonal discriminator:
  an implementation that builds the output from scratch instead of copying the
  input keeps every other test green and fails these. Reference already correct,
  no source change. Revalidated: new 342/342, base 4362 with 0 failures,
  new-on-base 342 of 342 failing, base-on-base clean, three identical new runs.
- 2026-08-04 — the other two declined, as before. Native excess data is now the
  fourth ask and merge dimension-description compatibility the third. The merge
  one has a firmer reason than "unstated": the description enumerates what merge
  inputs must agree on, SOP class, transfer syntax, pixel data element and image
  pixel attributes, and a closed enumeration means a case outside it is not a
  requirement. Adding a dimension-description check would contradict the list
  rather than fill a gap in it, and the current guard (keep the description when
  its length matches the value width, prune values regardless) leaks nothing.
- 2026-08-04 — solvability replayed against the 342-test suite rather than
  asserted. Batch 1 run C's patch passes all 342 unmodified. Batch 2's patch
  fails the same 17 it failed originally, and passes all 342 once the two reading
  entry points call the full validation, a single change now stated in the
  description. The 24 tests added since round 18 caused no new failures for
  either agent. Detail in `eval-results.md`.
- 2026-08-04 — Description Quality warning, both items taken. They named exactly
  the two behaviours rounds 21 and 22 added tests for, which is the expected
  order: a coverage suggestion produces a test, the alignment check then asks for
  the sentence behind it. Added "empty counting as none" to the per-frame groups
  error, and "Whatever else it carries comes from the first input, copied."
  before the isolation sentence, which covers both the carry-over and the merge
  taking it from the first input. Fifteen words added, fourteen trimmed from
  connective prose, meta 499 of 500. Nothing tested was cut: "frames missing an
  attribute after those that have it" became "missing values last" and
  "keeps the frames named by `indices` in the order given" became "keeps the
  frames `indices` names, in that order", both the same rule in fewer words.
  Behaviours half came back OK with no contradictions. No test or source change.
- 2026-08-04 — Test Fairness FAIL, 6 of 70, all six in
  `TestUnrelatedSequenceIsolation`, all saying the same thing: no rule chooses
  the top-level metadata policy. The check is labelled Stale and it is: the
  sentence it asks for, "Whatever else it carries comes from the first input,
  copied.", went into the description in the previous round, in answer to the
  Description Quality check that flagged exactly this gap. That sentence names
  preservation, the copy, and the merge policy the six tests pin, including
  "take it from the first input", which the checker called the strongest of the
  six. No change made and none needed; a rerun against the current meta should
  clear all six.
- 2026-08-04 — round 23 coverage: encapsulated fragmentation taken, suite 342 to
  347. `TestFragmentedEncapsulation` (5) builds frames split over two fragments
  with a populated basic offset table and asserts semantic payload order through
  extraction, sorting, grouping and merging, plus that the rebuilt data is still
  encapsulation the reader accepts. Assertions are on decoded payloads, not raw
  bytes, as the suggestion asked. Dimension schema compatibility on merge
  declined again for the enumeration reason. The top-level metadata policy
  suggestion was already done last round.
- 2026-08-04 — round 24: all three coverage suggestions taken, suite 347 to 361.
  Then replayed all three captured Orion runs against the new suite to answer
  "will Orion solve it" with evidence instead of hope. Run C passes 361/361. Run
  A, the very first run, fails 15, and 11 of those are behaviours the description
  has since been made to state; the other 4 are the ragged-dimension trap, which
  run C solved. Batch 2's 17 are one stated gap. Every failure mode any captured
  run had is now either stated or a fair trap at least one agent cleared. Detail
  in `eval-results.md`.
- 2026-08-04 — BATCH 3: 5 runs, 0 passed, failures 5 / 6 / 9 / 12 / 22 of 361.
  A reject as it stands, but the shape is good: every evaluator called the
  description clear, the tests deterministic and the difficulty challenging, and
  the misses concentrate. One test failed 5 of 5 and six more failed 3 of 5, which
  is the prompt-bug signature, not difficulty. Two fixes, both wording: the
  dimension-drop sentence had two readings and every agent took the wrong one, so
  the kept case is now stated outright; and the derived file meta had to name the
  SOP class, which the description never said. The top run's five failures are
  exactly those two clusters. Full analysis in `eval-results.md`; runs filed under
  `agent-runs/batch3/`.

## Description Quality FAIL (2026-08-04) - two taken, one contested

**Taken: the background opening.** "An enhanced multi-frame instance describes
each frame with functional groups, shared or per frame." is gone. Every term it
introduced is a real DICOM element name used later in the text, so nothing was
lost, and the description now opens on the task.

**Taken: the validation sentence.** "All six functions check what they are given
the same way first." is now "All six reject the same malformed instances." The
checker is right that no test pins the ORDER of validation, only that all six
reject the same inputs. The parity requirement is what matters here, since it is
what a whole run missed in batch 2, and it survives the rewording intact.

Meta is 478 words after both.

**Contested: the duplicated title.** The quoted text is the title repeated twice,
but `meta.md` contains it exactly once, as the `# ...` heading on line 1. That
heading is the required format (`CLAUDE.md`: "Title: `# <Action-verb behavioral
ask>`") and matches the approved corpus: afero-overlay-deletions,
amaranth-instance-models and amaranth-stream-width-converter all open with the
same single `#` heading and all passed review. The doubling therefore comes from
the submission form, where the title was entered in the title field AND left at
the top of the body. The fix is at paste time, not in the file: put the body in
without the heading line, or paste the file and let the title field take it,
whichever the form does. Deleting the heading from `meta.md` would break the
deliverable convention for a problem that does not exist in the file.
- 2026-08-04 — BATCH 4: 5 runs, 0 passed, failures 5 / 5 / 8 / 16 / 20. The batch 3
  file-meta fix worked (3/5 to 0/5). The remaining wall is one thing, and reading
  the failure MESSAGES rather than the test names found it: agents delete the
  `FrameContentSequence` macro when its index values empty, because my own batch 3
  sentence told them emptied things are removed. The tests require the macro kept
  and only the values element removed. Fixed by naming all three containers
  separately. A second cluster, 4 of 5, raised an error because a macro held two
  items, a constraint the description never stated; added that a macro may hold
  more than one. Both best runs failed exactly these 5 tests. If batch 5 is still
  0, cut the collapse requirement rather than reword it again. Runs in
  `agent-runs/batch4/`.
- 2026-08-04 — BATCH 5 was mostly a duplicate export: five of six run IDs match
  batch 4 exactly. The single new Orion run cleared the whole dimension and macro
  cluster, so the batch 4 wording fix worked. Its own 23 failures are two fresh
  causes: sorting compares pydicom `MultiValue` with `<`, which raises, so the
  agent reports it as the "incomparable values" error the prompt allows (17
  tests); and re-encapsulated pixel data lost its undefined length (5 tests).
  Both stated now. Meta 495 words. Detail in `eval-results.md`.
- 2026-08-04 — built a cause ledger over all 13 captured runs rather than reacting
  to one batch at a time. Eleven distinct causes; nine are now stated, two kept as
  the real difficulty. The last one stated: one-bit frame length was being computed
  as rows x columns x bits / 8, which is zero for `BitsAllocated=1`, so two runs
  rejected valid pixel data as inconsistent. Every stated cause had the same tell:
  a `MultiFrameError` raised on input the description says is valid. Meta 496 words.
- 2026-08-04 — answered "are the meta edits doing anything" by measuring instead of
  asserting. Rebuilt batch 4's closest run (5 failures) and applied only the
  changes its author would make from the current wording: keep the emptied macro,
  normalise index values with no description present, allow a macro to hold
  several items. Result 361/361. The middle one was new: agents tie the whole
  dimension pass to `DimensionIndexSequence` existing, and the description never
  said it is values-driven. Stated now. Meta 498 words.
- 2026-08-04 — BATCH 6: 6 new runs, 60-65 failures each, 57 shared. Self-inflicted.
  Cutting the opening sentence on the Description Quality check's advice, plus
  shortening "attributes inside the macros" to "in the macros", removed every
  signal that `frame_attributes` FLATTENS. All six runs returned macro sequences
  instead of attribute values. Restored by putting the flattening in the sentence
  itself. Says nothing about the batch 4/5 fixes, which were validated by replay
  (5 failures to 361/361). Meta 497 words.
- 2026-08-04 — hardened the flattening contract after the batch 6 regression:
  "flattens the macros applying to one zero-based frame into the attributes
  inside them, not the macro sequences". Six of six agents returned macros, so
  one word was not enough; the negative is now stated. Tried to validate by
  patching a batch 6 agent's `frame_attributes`, which went 62 to 85 failures
  because that agent uses the same function internally and its callers expect
  macros. The experiment is void, not the diagnosis: its own docstring says
  "Return the functional group macros applying to one frame". Meta 497 words,
  reference still 361/361.
- 2026-08-04 — word cap raised to 550 by the author, used 6 of the 50. Added only
  "and sameness is the whole macro, items and all", which covers the last shared
  failure that was not yet stated (3-4 of 5 runs shared a macro whose sequence had
  a different number of items). Meta 506 words. Deliberately did NOT spend the rest:
  the only remaining unstated thing is the ragged-dimension rule, and that is the
  designed difficulty rather than a gap, so explaining it further would trade the
  problem's whole trap for nothing. Note the documented platform cap is 500, so 506
  carries a small format risk the author accepted.
- 2026-08-04 — coverage sweep: all 15 causes ever seen across 14 captured runs are
  now stated in the description. Verified mechanically, phrase by phrase, not by
  memory.
- 2026-08-04 — round 25: all three coverage suggestions taken, suite 361 to 374.
  They land on the three newest clauses, which had wording but no tests. Also
  caught a rule break: one new test asserted only a fixture property and so
  passed on base. Fixed by having it read through `frame_attributes`, name
  unchanged. Full matrix green: 374/374, 4362 baseline, F2P complete, three
  identical runs.
- 2026-08-04 — HARDENING after a reported 3 of 4 Nova passing (75%, too easy).
  Added one stated but demanding requirement: a dimension whose
  `DimensionIndexPointer` names an attribute takes its values from that
  attribute, numbered by first appearance in the result, and a frame without the
  attribute does not reach it. This couples the dimension pass to the effective
  attribute machinery and changes what counts as constant for collapse. Measured:
  run C's patch, which passed 374/374, now fails exactly 10 of 388, all in the new
  class and nothing else. Suite 388, effective LOC 535, meta 528 words, full
  matrix green.
- 2026-08-04 — BATCH 7: 5 Nova, 0 passed, but two runs were 387/388 and flagged
  `agent_blame_unfair: true` on the same test. My reference contradicted my own
  sentence: "one they do not all reach is kept" must cover the case where NO frame
  reaches a pointed dimension, and I had a special branch dropping it. Removed the
  branch, renamed the test to `test_a_pointer_naming_nothing_present_is_kept`.
  Chose to delete the exception rather than document it, since exceptions are what
  the last six batches kept tripping on. The other three runs failed on their own
  bugs on stated behaviour (over-strict pixel padding, an invented
  `is_undefined_length` precondition), which is the difficulty working as intended.
  Full matrix green at 388/388, effective LOC 529.
