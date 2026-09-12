# eval-results — pydicom-multiframe-frames

No agent batch has been run yet. This file holds the local validation matrix and
is where the per-agent table goes after the first batch.

## Local validation (2026-08-03)

| Check | Command | Result |
| --- | --- | --- |
| base tests, no solution | `./test.sh --output_path base.xml base` | 2632 passed, 1730 skipped, 2 deselected, 0 failed |
| new tests, no solution | `./test.sh --output_path new.xml new` | 318 failed, 0 passed |
| base tests, with solution | `./test.sh base` | 2632 passed, 0 failed |
| new tests, with solution | `./test.sh new` | 318 passed |
| reverse apply order | solution.patch then test.patch | 2758 passed, 0 failed |
| unapply | `git apply -R` both | clean |
| JUnit testcases | base / new | 4362 / 318, errors=0 |
| flakiness, new | 5 host runs plus 3 container runs | 318/318 every run |
| flakiness, base | 20 container runs: sequential, concurrent, and repeated inside one container | 4362 cases, 0 failures in every one, plus one unexplained run described below |
| effective LOC | `effective_loc_check.py` | 486 human-effective, 944 raw, 7 files |
| docker offline non-root | `--network none --user 1000:1000` | base 2632 passed / new 318 passed; with test.patch only, base 2632 passed and new 318 failed as 318 individual testcases |

## Naive-agent benchmark

A deliberately diligent implementation written from meta.md alone (subset the
per-frame sequence, promote the macros common to it, prune and renumber the
dimensions, restack) was run against the suite.

| Suite version | Naive result |
| --- | --- |
| first draft, 111 tests | 110 passed, 1 failed (too easy) |
| hardened, 318 tests | 310 passed, 8 failed |

The 7 failures fall into three independent families, listed in `feedback.md`:
re-deriving macros the source had shared, pushing a shared frame content macro
down before renumbering, and a dimension that not every frame reaches. The pixel
data behaviours are not measured by this benchmark because the naive
implementation reused the reference's pixel module; a real solver writes those
too.

## Test Fairness round 1 (2026-08-03)

Verdict FAIL, 20 of 125 unfair. Every cause fixed, none by weakening a behaviour:

| Cause | Tests | Fix |
| --- | --- | --- |
| error-message substring pinned | 14 | every `match=` removed from the suite; the exception type is the contract |
| empty result pinned to `set()` | 2 | assert falsiness, not the container type |
| `frame_attributes` deep copy unstated | 1 | meta now says what it returns is a copy |
| absent versus empty collapsed dimension | 2 | meta now says an emptied description or value list is removed, not left empty |
| `missing keys` ambiguous for grouping | 1 | meta now separates an empty key list, a key naming no attribute, and a frame carrying none of an attribute |

All five coverage suggestions were also taken: namespace exports (3 tests), unknown
and unusable keys (4), merge compatibility beyond Rows (5), validation through
merge/group/sort (5), encapsulated data through sort and group (3). Suite is now
145 tests. The `pydicom` top level also exports `MultiFrameError`, and a key that
names no attribute now raises `MultiFrameError` rather than a bare `ValueError`.

## One unexplained base run

The very first base run after one of the image rebuilds reported 64 failed and 70
errors in 48s. It has not recurred in 20 runs since: 6 sequential, 4 concurrent
(deliberately loading the host), 3 back to back inside one container, and the
later rounds, every one of them 4362 cases with zero failures and zero errors.
The image carries no test-order randomiser and no xdist (`pytest11` entry points
are only `fakefs` and `anyio`), so run-to-run order is fixed. The JUnit file for
that run was lost before it could be read.

A related trap was found while chasing it and is worth writing down: the host
directory being bind-mounted for the JUnit output held stale XML from an earlier,
unrelated session, so reading `<testcase>` counts out of it reported another
repository's tests. Always mount a freshly created output directory and read the
`<testsuite>` attributes, not a reused one. A clean single run reports exactly
`tests="4362" failures="0" errors="0"` for base and `tests="180"` for new.

If the anomaly recurs, the fix is to deselect `tests/test_data_manager.py` and
`tests/test_fileset.py` in base mode with that reason, the same way the network
test is handled. Recorded here rather than smoothed over, because a flaky
baseline is a mandatory reject and this is the only evidence either way.

## Test Fairness round 2 coverage suggestions (2026-08-03)

All four taken, with two implementation changes they implied:

| Suggestion | Response |
| --- | --- |
| validation consistent across every API | `validate` now also rejects a dataset with no pixel data, so all six entry points reject the same broken datasets; 16 tests walk the matrix explicitly, no `parametrize` |
| encapsulated merge | 3 tests: payload order, undefined length kept, both inputs' extended offset tables dropped |
| known key absent from every frame | 3 tests: one group, frame order kept, sorting leaves an all-tie order alone |
| more image pixel compatibility fields | `PlanarConfiguration` added to the compatibility set; 4 tests for BitsStored, HighBit, PixelRepresentation and PlanarConfiguration |

Suite is now 171 tests. The naive build fails 8 of them, one more than before.

## Test Fairness round 3 coverage suggestions (2026-08-03)

Both taken; the first found a real bug.

| Suggestion | Response |
| --- | --- |
| merge pixel element compatibility | `merge_frames` did not check which pixel data element each input carried, so merging an ordinary instance with a float one silently wrote float frames into `PixelData` at the wrong stride. The element kind is now part of the compatibility check and is named in the description; 4 tests, including the positive case of two matching float instances |
| multi-key missing value ordering | 5 tests over two keys with values present on some frames and missing on others, covering missing-last per key position, a missing second key breaking a tie, stability among frames missing everything, and the grouping counterpart |

Suite is now 180 tests, meta 492 words, effective LOC 454. The naive build fails
11, up from 8.

## Test Fairness round 4 coverage suggestions (2026-08-03)

All three taken; the first needed a real change.

| Suggestion | Response |
| --- | --- |
| short pixel data on the reading APIs | length validation only ran where frames were actually read, so `frame_attributes` and `varying_attributes` accepted an instance whose pixel data could not hold its frames while the description states that error dataset-wide. `validate` now measures it, so all six entry points agree; encapsulated data is exempt because a frame's size is only known once its fragments are read, and that exemption has its own test. 6 tests, including the exactly-long-enough boundary and the bit-packed case measured in bits |
| invalid keys on both operations | the malformed non-key form is now tested on `sort_frames` as well, a bad key in second position is rejected, and an unknown numeric tag is shown to be usable rather than rejected: it names an attribute no frame carries, so grouping gives one group and sorting leaves the order alone. 4 tests |
| merge compatibility metadata | 3 tests for an input whose `file_meta.MediaStorageSOPClassUID` disagrees with its own `SOPClassUID`: the dataset attribute decides, the merge succeeds, and the derived file meta is made consistent by both merge and extract |

Suite is now 193 tests, effective LOC 468. The naive build still fails 11.

## Test Fairness round 5 coverage suggestions (2026-08-03)

All four taken, plus a sweep of my own for behaviours the description states
generally but the suite had only exercised through `extract_frames`.

| Suggestion | Response |
| --- | --- |
| validation parity | `sort_frames` with no pixel data |
| derived provenance for group and sort | source instance and 1-based `ReferencedFrameNumber` asserted for a grouped result (per group) and for a sorted one, where the numbers come back in the new order |
| isolation for group and sort | frame items are copies, writing into a grouped or sorted result does not reach the source, and the source keeps its pixel data and its shared groups |
| dimension integration | first-seen renumbering and collapse asserted through sort, through merge across two inputs, and within one group |

Swept in addition, same reasoning (stated generally, tested only via extract):
one shared group on every derivation, the sharing rule through sort and group,
in-stack renumbering through sort and per group, a tag key on `sort_frames`,
even-length padding on merge, and the extended offset table dropped by grouping.

Suite is now 215 tests. The naive build still fails 11, so the added breadth did
not dilute the discriminators.

## Test Fairness round 6 (2026-08-03)

Verdict FAIL, 1 of 104 unfair, down from 20 in round 1.

The flagged test was `TestStacks.test_frames_without_a_stack_are_counted_together`,
which pinned what happens to a frame carrying `InStackPositionNumber` but no
`StackID`. The description says positions are renumbered "within each stack" and
never defines stack membership when the identifier is absent, and nothing in the
repository establishes a convention, so the test chose one of several defensible
policies. It was deleted rather than legitimised: the description is 492 words
against a 500 cap, the behaviour is an edge of malformed input, and the naive
build passed it anyway, so it carried no difficulty. No agent batch had run, so
no F2P test name was disturbed.

Both coverage suggestions taken, the first with a real change:

| Suggestion | Response |
| --- | --- |
| malformed encapsulated frame count | encapsulated data holding fewer frames than the instance declares raised a bare `ValueError` out of `encaps.get_frame`, which `MultiFrameError` does not catch even though it subclasses `ValueError`. The read is now wrapped, so "pixel data too short for them" means the same thing for encapsulated and native data. 4 tests over extract, merge and sort, plus the control that a frame which is present still comes out |
| input object isolation for merge | 5 tests: no input frame item or shared item is reused, and writing into the merged result's frames or its shared group does not reach the first or a later input |

Suite is now 223 tests, effective LOC 472. The naive build still fails 11.

## Test Fairness round 7 (2026-08-03)

Verdict FAIL, 1 of 223 unfair. The flagged test was
`TestEncapsulatedFrameCount.test_frames_that_are_present_still_come_out`, which
asserted that asking only for a frame the encapsulated data does hold succeeds
even though the instance declares more frames than it carries. The checker is
right that the description states "pixel data too short for them" without a
selected-frame exception.

It was not deleted; it exposed a real inconsistency. Native data was measured in
`validate`, so a short buffer was rejected whatever frame was asked for, while
encapsulated data only failed when the missing frame was actually read. The
encapsulated branch now checks that the last declared frame is reachable, so the
same instance is rejected by every entry point regardless of the selection, and
the test was rewritten to assert that. `test_encapsulated_data_is_not_measured`
still holds: encapsulated data is judged by whether its frames are reachable, not
by its byte length.

Both coverage suggestions taken:

| Suggestion | Response |
| --- | --- |
| missing Number of Frames element | absence is not one of the described errors, so it is accepted and the per-frame groups decide; 6 tests show reading, varying, extraction, the derived instance stating its own count, an out-of-range frame still failing, and short pixel data still measured |
| shared group sequence cardinality | a present sequence that is not exactly one item is now rejected, and the description names it; an absent sequence stays fine. 5 tests over two items, zero items, absent, one item, and a malformed later merge input |

Suite is now 236 tests, meta 497 words, effective LOC 480. The naive build still
fails 11.

## Test Fairness round 8 (2026-08-03)

Verdict FAIL, 3 of 236 unfair, all three in `TestFrameCountElement`. They required
a source with no `NumberOfFrames` element to be accepted, with the per-frame
group count standing in for it. That is unstated, and the checker found the repo
leans the other way: `pydicom/pixels/utils.py` `get_nr_frames` defaults a missing
count to one frame, not to the sequence length.

Rather than state the fallback, the case is now an error. That is the DICOM
reading (`Number of Frames` is type 1 in the enhanced IODs), it removes a policy
the repository contradicts, and it makes validation uniform: an instance either
says how many frames it has and agrees with its groups, or it is rejected. The
description now reads "a frame count absent or disagreeing with those groups",
one word longer, and the class was rewritten to assert rejection at all six entry
points with a control that the same instance is fine once it states its count.

The coverage suggestion was taken as well: `varying_attributes`, `group_frames`
and `sort_frames` now have direct shared-group cardinality checks for both the
two-item and the empty case, so all six entry points are covered rather than
three.

Suite is now 243 tests, meta 498 words, effective LOC 482. The naive build still
fails 11.

## Test Fairness round 9 coverage suggestions (2026-08-03)

Both taken; no implementation change was needed, both behaviours were already
correct and simply untested.

| Suggestion | Response |
| --- | --- |
| top-level deep-copy isolation | 5 tests reaching outside the functional groups: a multi-valued attribute, an unrelated top-level sequence, the file meta, the same through merge, and two groups of one source not writing through to each other |
| transfer syntax variety | 7 tests over implicit VR little endian, explicit VR big endian and deflated explicit VR little endian, covering frame slicing, the syntax being kept, the length check, merging two instances of one non-default syntax, and two differing uncompressed syntaxes still being refused |

Suite is now 255 tests. The naive build still fails 11.

⚠ Build note: the `fetch_data_files()` layer failed once with a network error
during this round, and because the build ran in a subshell the script carried on
and validated against the previous image. Caught by the new-mode count reading
243 where the base-only image read 255. Always compare the two images' counts
against each other, not just against zero failures.

## Test Fairness round 10 (2026-08-03)

Verdict FAIL, 5 of 100 unfair, all in `TestTopLevelIsolation` from the previous
round. They mutated `ImageType`, `ReferencedSeriesSequence` and
`ImplementationVersionName` on a derived instance and checked the source was
untouched. The isolation half is stated; the hidden half is not. Each assertion
first requires the derived instance to still HAVE that unrelated attribute, and
the description never promises retention of anything beyond what it names. The
merge case additionally assumed the first input is the template for such fields.
A solver who built a conforming result from only the required content would fail
all five.

Regrounded rather than deleted. The same guarantee is now shown on structures the
description does require the result to carry: its file meta, which must agree
with the new SOP instance UID, and the dimension index description, which the
description says survives with its surviving dimension. Five tests: the file meta
is not the source object, writing into it leaves the source, writing into the
surviving dimension description leaves the source, a merged file meta belongs to
no input, and two groups of one source do not share theirs. No retention of an
unrelated attribute is assumed anywhere.

Both coverage suggestions taken:

| Suggestion | Response |
| --- | --- |
| value equality for nested macros | 4 tests where macros are built as separate objects: equal nested sequences and equal multi-valued elements are shared, while a nested difference or a differing item count is not |
| provenance of already-derived inputs | 4 tests: merging two extracts names those two instances and not their common ancestor, gives one item per input, numbers frames within each input, and grouping a derived instance names that instance |

Suite is now 263 tests, effective LOC 482. The naive build still fails 11.

## Test Fairness round 11 (2026-08-03)

Verdict FAIL, 5 of 51 unfair, and this one mattered: three of the five were the
ragged-dimension tests, the strongest discriminator in the suite and the one that
beat the Orion run. Deleting them would have gutted the difficulty; keeping them
unstated would keep failing the gate. The rule was stated instead, in the general
form rather than as a list of ragged cases.

| Flagged | Response |
| --- | --- |
| `TestDimensions.test_frames_without_frame_content_are_left_alone`, both `TestRaggedDimensions` tests | the dimension sentence now opens "Among the frames that carry index values, a dimension all of them reach with one value is then dropped ... and from those frames". One clause states who takes part and when a dimension survives; the ragged instances follow from it and are not enumerated |
| `TestStacks.test_frames_without_a_position_are_left_alone` | the in-stack sentence now ends "among the frames that carry them" |
| `TestTopLevelIsolation` sibling `file_meta is not` assertion | deleted; sibling-to-sibling isolation is not promised, and the UID consistency assertion in the same test carries the point |

Paid for by trimming six words of motivation and phrasing elsewhere; meta is 499.
Both coverage suggestions taken: an invalid later sort key, and
`varying_attributes` under a shared macro overridden by one frame, including the
replacement that removes an inner attribute.

## Differential against the captured agent patch

Replaying `agent-runs/batch1-orion1/solution-patch.patch` against the final
318-test suite: **14 failures, 304 passes.**

| Cluster | Tests | Durable? |
| --- | --- | --- |
| key absent from every frame | 7 | no, the wording that misled it is fixed |
| ragged and missing dimension data | 3 | yes |
| missing SOP class or instance UID, reading APIs | 4 | yes |

So a 1319-line implementation from a strong solver still fails 7 tests that have
nothing to do with any wording since corrected. That is the evidence the
difficulty survives the fairness work, and it is why the ragged rule was restated
rather than removed. The identifier count rose from 2 to 4 when the parity matrix
was completed: its validation reaches the derivations but not `frame_attributes`
or `varying_attributes`, so completing the matrix found more of the same real
defect rather than inventing a new rule.

## Round 12 coverage suggestions (2026-08-03)

Both taken, tests only, no code or description change.

| Suggestion | Response |
| --- | --- |
| identifier validation parity | the matrix now walks both identifiers through all six entry points, 8 tests, written out rather than parameterized because bracketed node ids are scored as missing. Two of them turned out to be new discriminators against the captured agent patch |
| merge isolation of the dimension description | 3 tests: no surviving description item is an input's object, writing into the merged description reaches neither input, and the surviving dimension is the one that varies across the merge |

Suite is now 293 tests.

## Round 13 coverage suggestions (2026-08-03)

| Suggestion | Response |
| --- | --- |
| shared-first ordering in `frame_attributes` | not implementable as written, and not added in that form. `Dataset` iterates in TAG order, not insertion order: building one with SliceThickness `(0018,0050)` after PixelSpacing `(0028,0030)` still iterates the thickness first, so "shared written first" can never show up as element order. What the phrase does mean observably is precedence when a shared and a per-frame macro of DIFFERENT tags both carry the same attribute, which was untested. 4 tests: the frame's own macro wins the collision, a frame without its own keeps the shared value, an attribute only the shared macro has still survives, and the collision registers in `varying_attributes` |
| distinct identities among sibling groups | 4 tests: two groups take different instance UIDs, three groups give three distinct ones, each group's file meta names its own instance, and extracting twice from one source gives two instances |

Suite is now 301 tests. The captured agent patch still fails 14, unchanged, so
this round added coverage rather than discrimination.

## Test Fairness round 14 (2026-08-03)

Verdict FAIL, 1 of 54 unfair, and it was a container-protocol gap rather than a
behaviour one: many grouping tests use `len(groups)` and `groups[0]`, while the
description only promised groups "in order of first appearance", which an
iterator would satisfy. The description now says `group_frames` "returns a list
holding one instance per distinct combination", matching the signature, which
already read `-> list[Dataset]`. Paid for with four meaning-preserving trims;
meta stays at 499 words. No code or test change.

The suggestion also asked to pin `varying_attributes` to `set[BaseTag]`. Declined
on purpose: an earlier round flagged `== set()` as unfair over-specification, so
those tests were relaxed to emptiness and an integer-tag check. Pinning the
container now would re-introduce exactly what was removed.

The second coverage suggestion, merge inputs whose dimension descriptions differ,
was also declined, with the reason recorded rather than left implicit. The
current behaviour takes the first input's description. Making it an error would
contradict the description's enumerated compatibility list (SOP class, transfer
syntax, pixel data element, image pixel attributes), and documenting either
policy needs words the 500-word cap does not have. Untested and unstated is the
fair state; tested-but-unstated is what has failed this gate repeatedly.

## Why the captured Orion run should now pass

All 14 failures that patch shows against the current suite trace to contract that
was absent or ambiguous when it ran, and every one is now explicit:

| Cluster | Tests | Contract at run time | Contract now |
| --- | --- | --- | --- |
| key absent from every frame | 7 | "a key naming no attribute", read as "no frame carries it" | "a key that is not an attribute name or tag", plus grouping "even when that is every frame" |
| ragged and missing dimension data | 3 | silent on frames that carry no index values | "Among the frames that carry index values, a dimension all of them reach with one value is then dropped" |
| missing SOP class or instance UID | 4 | not listed as an error | listed in the error sentence |

Nothing in that patch fails a rule that was stated when it was written. That is
the case for re-running the same solver against this version rather than
redesigning: the failures were description gaps, and the descriptions are closed.

## Round 15 coverage suggestions (2026-08-03)

All four taken, tests only, no contract or code change. Every one was a parity
gap against a rule the description already states.

| Suggestion | Response |
| --- | --- |
| pixel element cardinality parity | two elements now rejected by `varying_attributes`, `group_frames` and `sort_frames` as well, 3 tests |
| malformed encapsulation parity | truncated encapsulation now exercised through `varying_attributes`, `group_frames` and `merge_frames`, 3 tests |
| merge compatibility with absent attributes | 5 tests: an image pixel attribute present on one input and absent on the other is a disagreement whichever side lacks it, and two inputs that both lack it still agree |
| shared sequence cardinality parity | the complementary cases, empty for `frame_attributes` and two items for `extract_frames` and `sort_frames`, 3 tests |

Suite is now 315 tests. The captured agent patch still fails 14, so this round is
coverage rather than discrimination.

Container revalidation was delayed, then completed. The Docker daemon on this
machine is shared with other sessions which had removed both images and were
running 13 concurrent builds; once they cleared, both images were rebuilt from
the regenerated patches and the full matrix ran clean:

| state | base mode | new mode |
| --- | --- | --- |
| base + test.patch | `tests="4362" failures="0" errors="0"` | `tests="315" failures="315"` |
| + solution.patch | `tests="4362" failures="0" errors="0"` | `tests="315" failures="0"` |

Three consecutive in-container new-mode runs: 315/315 each, no flips.

⚠ Note for future rounds: this Docker daemon is shared. Images can disappear
under a run and builds can queue behind other sessions. Always confirm the image
timestamp before trusting a container result, and never read a container verdict
without checking the two images agree on test count.

## Test Fairness round 16 (2026-08-04)

Verdict FAIL, 1 of 63 unfair: `int(item.ReferencedFrameNumber) == 1` on a
one-frame provenance item. `ReferencedFrameNumber` is VM 1-n, so a one-element
`MultiValue` and a scalar are both correct, and only the scalar survives `int()`.
Fixed by normalising: a `frame_numbers()` helper returns a list either way, and
every frame-number assertion in the suite now goes through it, so no test couples
to the representation.

Coverage suggestions, one taken and two declined on purpose:

| Suggestion | Response |
| --- | --- |
| native overlength / pad byte | taken, 3 tests. An even-length value holding an odd-length frame is accepted, survives a derivation, and one byte short is still rejected. Grounded in the stated even-length rule, and a naive `held != needed` check would fail it |
| selection index types | declined. `extract_frames` does `int(index)`, so a non-numeric string raises a bare `ValueError` and a float truncates silently. Both are unstated, and the description has no room to state them. Testing either would pin an unstated policy, which is the failure mode that has cost this task most of its fairness rounds |
| merge with disagreeing dimension descriptions | declined again, same reason as round 14. Behaviour is arbitrary when the descriptions differ in length, making it an error would contradict the enumerated compatibility list, and stating a policy needs words the 500-word cap does not have |

Suite is 318 tests. The captured agent patch still fails 14.

⚠ The checker also called the suite "substantially redundant in its
validation-parity matrices", which is fair and worth heeding: the validation
matrices are now the bulk of the growth and add coverage without discrimination.
Future rounds should decline parity-style suggestions unless a differential run
shows the gap catches something.

## Round 17 coverage suggestions (2026-08-04) — all three declined, with probes

The standing note from round 16 says decline parity-style suggestions unless a
differential shows the gap catches something. Two of these alleged leaking
exceptions, which would be a real defect, so each was probed against the
implementation before deciding. None of the three found one.

| Suggestion | Probe result | Decision |
| --- | --- | --- |
| malformed scalar metadata | a non-numeric `NumberOfFrames` cannot be assigned at all: pydicom's own `IS` conversion raises before the module sees it. An unsupported `BitsAllocated` of 12 already raises `MultiFrameError`. Zero or negative `NumberOfFrames` simply disagrees with the group count, which is already an error. The only live case is zero geometry, which is accepted and yields empty frames | declined. The one reachable case is degenerate rather than wrong, and nothing in the description constrains geometry, so a test either way pins unstated policy |
| encapsulated excess frames | accepted, extra payloads ignored, no leak: extracting from three encapsulated frames declared as two keeps `[aaaa, bbbb]` | declined. Neither acceptance nor rejection is stated, and no words remain to state one |
| comparison failure parity | no asymmetry and no leak. Both `group_frames` and `sort_frames` handle a sequence-valued key without error, so grouping already canonicalises what sorting compares | declined. There is nothing to fix and nothing unstated to pin |

No code, description or test change this round. Suite stays at 318 tests, and the
captured agent patch still fails 14. Recording the probes rather than the tests is
the point: the questions were worth answering, the answers did not justify
growing a suite the checker has already called redundant.

## Round 18 (2026-08-04) — coverage taken, description check bypassed

Both coverage suggestions taken, 7 tests, no description change: bit-packed
sorting, grouping and merging repack across byte boundaries rather than moving
whole bytes, and float and double float elements survive grouping and sorting
with the right sample width. Expected packed bytes were computed with an
independent unpack rather than by hand, which caught three wrong constants
before they shipped.

Suite is 325 tests. **Orion run C's patch passes all 325**, including the new
ones, so the solvability evidence holds after this round.

The Description Quality check returned request_changes with three HIGH items
asking to delete the error list, the derived-instance rules and the
grouping/sorting semantics. Not taken; the reasoning and the bypass request are
in `feedback.md`. In short, those sentences exist because the Test Fairness gate
demanded them, and deleting them converts roughly 60 tests into hidden
requirements, which is a hard reject rather than a warning.

## Per-agent results

### Batch 2 (2026-08-04) — Orion run C, and SOLVABILITY DEMONSTRATED

| Agent | Evaluator | Verdict | Failed | Failure reason |
| --- | --- | --- | --- | --- |
| Orion run C | Nova | FAIL_MISSED_REQUIREMENT | 5 of 318 | native pixel validation too strict: float width from `BitsAllocated`, exact-length rejection, mandatory image pixel attributes |

Artifacts in `agent-runs (7)/Orion_Nova/`. Baseline 2632 green, 313 of 318 new
passed, evaluator rated `description_clear: True`, `tests_deterministic: True`,
difficulty `challenging`. It cleared the ragged-dimension and identifier traps
that run A missed, which is the clarified description working.

**Four of the five failures were my fixtures, not the agent.** The evaluator had
already flagged one as "somewhat debatable"; the rest are worse than debatable:

| Fixture | Was | Why wrong | Now |
| --- | --- | --- | --- |
| float and double float pixel tests | `BitsAllocated` 8 with `FloatPixelData` | DICOM says OF is 32-bit and OD 64-bit. The agent applied the standard and was penalised for it | 32 and 64 |
| one-element and compatibility fixtures | 4 bytes for a 1-byte frame | surplus bytes, so the tests silently required accepting them | exact length |
| padded fixtures | `b"ab"` | DICOM pads with a null byte; `b"b"` is not a pad | `b"a\x00"` |
| both-absent merge agreement | both inputs missing `PhotometricInterpretation` | that attribute is type 1; the test required accepting a non-conformant dataset | `PlanarConfiguration`, genuinely conditional at `SamplesPerPixel` 1 |

This is the fake-difficulty anti-pattern: a solver punished for applying real
domain knowledge. Removing it is right whatever it costs in pass rate.

**Replaying both captured patches against the corrected suite:**

| Patch | Result |
| --- | --- |
| run A (written against the ambiguous description) | 14 failed, 304 passed |
| run C (written against the current description) | **318 passed** |

That is the solvability evidence. A real agent's own patch clears the whole
suite, so the task is reachable, not merely reachable in principle by the
reference. Run A still fails, so the artifact is not trivially passable either.

⚠ Difficulty caveat, stated plainly: both runs FAILED as actually run. Run C
passes only after four fixture corrections it never saw. The honest reading is
that the current-artifact pass rate is unmeasured, and that removing the fake
difficulty has probably raised it. The naive build now fails 8 rather than 11,
for the same reason. A real batch is the only way to settle it.

### Batch 1 (2026-08-03) — 2 Orion runs

| Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed | Failure reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Orion run A | Nova | FAIL_AMBIGUOUS_TASK | 65 | 3 | 1049 | 152/263 | rejected any input with no Shared Functional Groups Sequence |
| Orion run B | Nova | FAIL_MISSED_REQUIREMENT | - | 3 | 1319 added | 10/263 | 7 from rejecting a key no frame carries, 3 from dimension normalisation |

Run B is the informative one; artifacts in `agent-runs/batch1-orion1/`. Baseline
2632/2632 green, 253 of 263 new tests passed. The evaluator rated the task
`description_clear: True`, `tests_deterministic: True`, difficulty `challenging`,
and confirmed the reference solution shows it is solvable. Both failure clusters
were judged mentioned in the description, so the verdict is a legitimate miss,
not an unfair one.

**Cluster 1, 7 tests, wording (fixed).** The error list said "a key naming no
attribute". The agent implemented that as "no frame carries it" and raised for a
valid key that no frame happens to have, which the positive rules say should give
one missing-value group and stable ties. The evaluator called the phrase a "minor
ambiguity" while still rating the tested behaviour knowable. It is now "a key
that is not an attribute name or tag", which can only describe the key itself,
and the grouping rule ends "even when that is every frame". Accidental
difficulty, removed.

**Cluster 2, 3 tests, the designed trap (kept).** `_normalise_dimensions` gates
the whole pass on `DimensionIndexSequence` being present, so an instance carrying
index values but no description is never renumbered, and it raises whenever a
frame has no frame content macro or a shorter vector. The description makes the
index values the subject and never requires the description to exist, so this is
the values-driven versus description-driven split the ragged-dimension tests were
built for. It bit a 1319-line implementation from a strong solver. Kept as is.

Nothing was added to compensate for cluster 1. The doctrine on a near-pass is to
add an orthogonal trap or nothing, never more tests on the axis that already
bites, and no new rule is worth the ambiguity risk that has now cost two runs.
The next batch decides: at or under 40% the artifact stands, above it the lever
is a composition pass against the captured patch, not new prose.

⚠ Standing lesson for this problem: every failure so far, from ten fairness
rounds and now two agent runs, has been an input-shape or key policy read two
ways, never the behavioural core. The error list is the repeat offender. Any
phrase in it must say plainly whether it describes the argument or the data, and
what absence means.

## Batch 2, run 1 - Orion, evaluated by Nova (2026-08-04)

| field | value |
| --- | --- |
| solver / evaluator | Orion / Nova |
| verdict | FAIL_MISSED_REQUIREMENT |
| baseline | 2632 passed, exit 0 |
| new tests | 308 of 325 passed, 17 failed |
| difficulty rating | challenging |
| description_clear | true |
| tests_deterministic | true |
| environment blocker | none (an isolated solve-time TLS failure on one unrelated data-download test) |
| artifacts | `agent-runs/batch2-orion1/` |

**Every one of the 17 failures is a single miss.** The implementation split
validation into `_validate_structure` and `_prepare_dataset`, and the two reading
entry points call only the first. So `frame_attributes` and `varying_attributes`
never check transfer syntax, SOP class or instance UID, pixel element
cardinality, or pixel data length and encapsulation, while the four deriving
entry points check all of it:

TestFrameAttributes::test_no_transfer_syntax_raises ·
TestValidationMatrix::{test_frame_attributes_checks_pixel_data,
test_varying_attributes_checks_pixel_data,
test_varying_attributes_checks_transfer_syntax} ·
TestShortPixelDataEverywhere::{test_frame_attributes_rejects_short_pixel_data,
test_varying_attributes_rejects_short_pixel_data} ·
TestEncapsulatedFrameCount::test_reading_attributes_rejects_it_too ·
TestTransferSyntaxVariety::test_short_data_is_measured_under_any_native_syntax ·
TestPixelElementCardinality::test_reading_rejects_two_elements ·
TestSourceIdentifiers::{test_reading_rejects_a_missing_sop_class,
test_reading_rejects_a_missing_instance_uid} ·
TestMalformedEncapsulation::test_truncated_data_is_rejected_when_reading ·
TestIdentifierParity::{test_varying_attributes_wants_the_sop_class,
test_varying_attributes_wants_the_instance_uid} ·
TestMalformedInputParity::{test_varying_attributes_rejects_two_elements,
test_varying_attributes_rejects_truncated_data} ·
TestNativeLengthBoundary::test_one_byte_short_is_still_rejected

**Everything else passed**, including every architectural discriminator: the
expand-then-normalise sharing recalculation, restack-before-collapse ordering,
ragged dimension survival, pixel rebuild across native, bit-packed, float and
encapsulated forms, provenance, and deep isolation. This is a near-pass on the
core of the problem, failing on one policy question about scope.

**Fix: one sentence, in the description.** The error list opened with
"`MultiFrameError` ... is raised for a dataset with ...", which names the
conditions but never says the reading APIs check the same things as the deriving
ones. Reading it as "the readers only need per-frame groups" is defensible. The
list is now preceded by "All six check what they are given the same way first."
Eleven words, paid for by trimming fifteen elsewhere; meta is 495 of 500.

No test and no source changed. This is the de-trap-one-universal-miss step, not a
difficulty reduction: the 308 tests this run already passed are untouched, and the
miss it removes was a scope ambiguity rather than an architectural insight.

**Solvability standing.** Two independent lines of evidence now: batch 1 run C's
captured patch passes all 325 tests as the suite stands, and this run passed 308
of 325 with a single, now-stated policy gap. The next batch measures the rate.

## Fairness round 20 (2026-08-04) - 3 of 58 unfair, all fixed in the description

| flagged | why it was unfair | fix |
| --- | --- | --- |
| `TestNamespace.test_reachable_from_pydicom` (MultiFrameError co-assertion) | the reachability sentence enumerated only the six functions | the error joins the list of objects reachable from `pydicom` |
| `TestNamespace.test_same_objects` (MultiFrameError co-assertion) | same gap, plus no repo convention of re-exporting exceptions | same sentence now covers it, and "the same objects" already states identity |
| `TestMerge.test_single_input` | whether a merge accepts one input is a genuine API choice | `merge_frames` now takes "all its inputs, one or more" |

The checker rated everything else prompt-stated, repo-discoverable or standard
DICOM semantics, and explicitly endorsed the validation parity matrix that the
batch 2 Orion run failed: "highly redundant across methods, but the parity
requirement makes the matrix legitimate". That is the sentence added after batch
2 doing its job - the same tests that read as an unstated requirement one round
ago now read as a stated one.

Meta is 497 of 500 words. No test and no source changed, so the container matrix
and the 325-test F2P set stand as validated in round 18.

## Round 21 coverage (2026-08-04) - 336 tests

| suggestion | verdict | why |
| --- | --- | --- |
| empty per-frame sequence | taken, 7 tests | "no per-frame groups" already covers an empty sequence; reference rejects it from all six |
| invalid key object types | taken, 4 tests | "a key that is not an attribute name or tag" already covers it |
| native excess data | declined, third time | undecided by the description; a sentence would grow the validation surface that already cost a run |

The key suggestion named "a list" as an invalid key. It is not: `Tag([1, 2])`
returns `(0001,0002)` and `Tag(3.5)` returns `(0000,0003)`, so both are valid tag
forms in pydicom, and only `object()`, `None`, `dict` and `bytes` fail with a
`TypeError` that `_resolve_keys` converts. Tested the four that genuinely fail.

Full matrix after the change: new 336/336 pass, base 4362 with 0 failures,
new-on-base 336 of 336 fail (F2P complete), base-on-base 4362 with 0 failures,
three consecutive identical new runs, effective LOC 486, meta 497 words.

## Round 22 coverage (2026-08-04) - 342 tests

| suggestion | verdict | why |
| --- | --- | --- |
| arbitrary top-level deep copy | taken, 6 tests | "share nothing with the result" is unqualified, so it covers any top-level structure |
| malformed native excess data | declined, 4th ask | still undecided by the description; both readings defensible |
| merge dimension-description compatibility | declined, 3rd ask | the merge agreement list is a closed enumeration; a case outside it is not a requirement |

The isolation tests are the first orthogonal discriminator added in several
rounds. Everything else recently has been validation breadth, which is what the
batch 2 run stumbled on. This one separates architectures instead: build the
output by deep-copying the input and it passes, assemble a fresh dataset from
the parts you know about and every other test still passes while these six fail.

Matrix: new 342/342, base 4362 with 0 failures, new-on-base 342 of 342 failing,
base-on-base 4362 clean, three consecutive identical new runs, no warnings.

## Solvability replay against the 342-test suite (2026-08-04)

Both captured agent patches rebuilt from BASE and run against the current
artifact, not against the suite they originally faced.

| implementation | result on 342 tests |
| --- | --- |
| batch 1 run C (Orion) | **342 / 342 pass, unmodified** |
| batch 2 run 1 (Orion) | 17 fail, the same 17 as its own run |
| batch 2 run 1 + one change | **342 / 342 pass** |

The one change is literally one call added to each of the two reading entry
points, routing them through `_prepare_dataset` (the full validation) instead of
`_validate_structure` (the structural subset). Nothing else was touched. So the
17 failures were never 17 problems; they were one policy decision with 17
witnesses, and that policy is now stated outright in the description.

Two facts follow. First, a real agent implementation passes the current suite
with no help at all, so the task is reachable. Second, the 24 tests added in
rounds 19 to 22 introduced no new failures for either agent (batch 2 failed 17 of
325 before and 17 of 342 after), so the coverage work has not been quietly
raising difficulty; it has been pinning behaviour both implementations already
had right.

What is still unmeasured is the pass RATE. Two implementations is not a batch.

## Round 23 (2026-08-04) - 347 tests

Fairness FAIL 6 of 70 was stale: every one of the six flagged tests is answered
by the sentence added the round before, "Whatever else it carries comes from the
first input, copied." Preservation, the deep copy and the first-input merge
policy are all named there. No artifact change.

Coverage: encapsulated fragmentation taken (5 tests), dimension schema
compatibility on merge declined for the third time, top-level metadata policy
already stated.

A test-authoring bug was caught by the matrix and not by the earlier probe:
`generate_frames` takes `number_of_frames` keyword-only, and the helper passed it
positionally, so all five new tests raised `TypeError` on the reference. The
probe had used the keyword form, so it passed while the test did not. Fixed and
rebuilt. The lesson is that a probe written separately from the test does not
validate the test; only the matrix does.

| run | result |
| --- | --- |
| new on solution | 347 / 347 pass |
| base on solution | 4362 tests, 0 failures |
| new on base | 347 of 347 fail (F2P complete) |
| base on base | 4362 tests, 0 failures |
| new, three consecutive runs | 347 / 0 each time |
| batch 1 run C agent patch | **347 / 347 pass, unmodified** |

Solvability re-confirmed against the grown suite, not just the one it was first
measured on.

## Round 24 (2026-08-04) - 361 tests, and every captured Orion failure accounted for

All three coverage suggestions taken: `TestMissingFileMeta` (6, the whole
`file_meta` container absent rather than just the syntax), `TestMultiSampleNative`
(4, RGB frames where a frame is Rows x Columns x 3 bytes, extraction, sorting and
the short-data boundary), `TestMergeRemainder` (4, conflicting unrelated
top-level content on later inputs). Reference already correct on all fourteen.

### The three captured Orion runs replayed against the current 361-test suite

| run | result | what its failures are now |
| --- | --- | --- |
| batch 1 run C | **361 / 361 pass** | nothing |
| batch 2 run 1 | 17 fail | one stated gap, passes 361/361 with the single call added |
| batch 1 run A | 15 fail | 11 already stated since, 4 the designed trap |

Run A's 15 break into four groups:

- **7 tests, "A key names no frame attribute".** Run A raised whenever a key was
  a valid keyword or tag that no frame carried. The description now says the
  opposite outright: only a key that is not an attribute name or tag is an error,
  and "frames carrying none of an attribute grouping together even when that is
  every frame". Stated in an early fairness round, after run A.
- **4 tests, SOP class and instance UID unchecked by the two readers.** The same
  parity gap batch 2 hit, now covered by "All six functions check what they are
  given the same way first".
- **3 tests, ragged dimension vectors rejected as uncombinable.** This is the
  designed trap, and it is discoverable: "a dimension all of them reach with one
  value" only means anything if some frames do not reach every dimension. Run C
  got it right, so it is hard, not unfair.
- **1 test, a frame carrying values not renumbered because a sibling lacks the
  macro.** Same trap family, same sentence.

So of 32 failures across the two failing runs, 28 are behaviours the description
now states, and 4 are the one trap the problem is built on. No failure mode from
any captured run is both undiscoverable and unaddressed.

Matrix: new 361/361, base 4362 with 0 failures, new-on-base 361 of 361 failing,
base-on-base 4362 clean, three identical new runs, meta 499 words.

## BATCH 3 (2026-08-04) - 5 runs, 0 passed, every run a near miss

| run | solver | verdict | baseline | new | failed | difficulty | desc_clear | blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| batch3/Orion_Nova | Orion | FAIL_MISSED_REQUIREMENT | 2632 pass | 356/361 | **5** | challenging | true | env (friction) |
| batch3/Nova_Nova_3 | Nova | FAIL_MISSED_REQUIREMENT | 2632 pass | 355/361 | 6 | challenging | true | env (friction) |
| batch3/Nova_Nova_4 | Nova | FAIL_MISSED_REQUIREMENT | 2632 pass | 352/361 | 9 | challenging | true | none |
| batch3/Nova_Nova_2 | Nova | FAIL_MISSED_REQUIREMENT | 2632 pass | 349/361 | 12 | challenging | true | env (friction) |
| batch3/Nova_Nova_1 | Nova | FAIL_MISSED_REQUIREMENT | 2632 pass | 339/361 | 22 | challenging | true | none |

0 of 5 is a reject. Every evaluator rated the description clear, the tests
deterministic and the difficulty challenging, and none blamed the environment
(`agent_blame_unfair` false everywhere).

### Shared-failure analysis - the only thing that matters here

36 distinct tests failed across the batch. Ranked by how many runs failed each:

| runs | test | reading |
| --- | --- | --- |
| **5/5** | TestRaggedDimensions::test_position_no_frame_shares_is_kept | **prompt bug** |
| 3/5 | TestFileMetaDisagreement::test_extract_repairs_the_file_meta | **prompt gap** |
| 3/5 | TestFileMetaDisagreement::test_derived_file_meta_is_made_consistent | **prompt gap** |
| 3/5 | TestDimensions::test_frames_without_frame_content_are_left_alone | same cluster |
| 3/5 | TestDimensions::test_every_dimension_collapsed_removes_description | same cluster |
| 3/5 | TestDimensions::test_collapse_can_make_frames_alike | same cluster |
| 3/5 | TestValueEquality::test_a_macro_with_more_items_is_not_shared | fair, kept |
| 2/5 | TestRaggedDimensions::test_description_keeps_the_surviving_dimension | same cluster |
| 1/5 x28 | sorting (13), bit-packing (6), encapsulation (5), misc | per-agent bugs |

The 1/5 tail is not a pattern: one run had a broken sort comparison and another
broken bit-packing. Those are ordinary implementation defects.

**The 5/5 test is a wording bug, not difficulty.** "a dimension all of them reach
with one value is then dropped" parses two ways: as "a dimension that all of them
reach, and that has one value" (correct) or as "a dimension whose value is the
same across all that reach it" (wrong, drops a dimension only one frame reaches).
Both are natural English and the second is the one five of five agents took.
Rewritten to say the kept case outright: "a dimension every one of them reaches
with one value is then dropped, from the dimension index description and from
those frames; one they do not all reach is kept. An emptied one is removed,
description included, not left empty." Same rule, one reading. "description
included" also settles the total-collapse case that 3 of 5 missed.

**The file-meta gap was real.** The description said the derived instance takes a
new SOP instance UID "its file meta agrees with" and never mentioned the SOP
class, while the tests require the class to be repaired too. Now: "It takes a new
SOP instance UID, its file meta naming that and its SOP class".

**Why this should convert the top run.** Orion's five failures are exactly three
dimension tests and two file-meta tests, nothing else. Nova #3's six are the same
five plus the macro-item-count comparison. Both clusters are now stated outright.
This is a projection, not a measurement; only the next batch settles it.

Kept as fair difficulty: the macro item-count comparison (3/5) and the
undefined-length encapsulation tests (1-2/5). Value equality of a sequence
includes its item count, and undefined length is what DICOM requires of
encapsulated pixel data; the fairness checker rated both grounded.

Environment: three runs flagged the repo's own network test
(`tests/test_data_manager.py::test_fetch_data_files`, invalid certifi CA path)
limiting the agents' own full-suite runs. `test.sh` already deselects it in base
mode so grading is unaffected, and every evaluator judged the failures
agent-caused. Recorded, not acted on.

Meta 497 words after the rewrite. No test and no source change, so the 361-test
matrix from round 24 stands.

## BATCH 4 (2026-08-04) - 5 runs, 0 passed, but the cause finally isolated

| run | failed of 361 | verdict |
| --- | --- | --- |
| Nova #2 | **5** | FAIL_MISSED_REQUIREMENT |
| Nova #3 | **5** | FAIL_MISSED_REQUIREMENT |
| Nova #4 | 8 | FAIL_MISSED_REQUIREMENT |
| Nova #1 | 16 | FAIL_MISSED_REQUIREMENT |
| Orion | 20 | FAIL_MISSED_REQUIREMENT |

All five: description clear, deterministic, difficulty challenging.

**Batch 3's file-meta fix worked.** Both file-meta tests failed 3 of 5 in batch 3
and 0 of 5 here. That clause is settled.

**What is left is one root cause, and the failure MESSAGES gave it away where the
test names did not.** Four of the five shared failures raise
`AttributeError: 'Dataset' object has no attribute 'FrameContentSequence'` or
assert the macro is missing from the shared group. The agents DELETE the
`FrameContentSequence` macro when its `DimensionIndexValues` empties. The
reference keeps the macro and removes only the values element.

They are doing what the description told them. My batch 3 wording, "An emptied
one is removed, description included, not left empty", says emptied things get
removed, so removing the emptied macro is the obedient reading. The tests require
the opposite. This is an author-made contradiction, not agent error, and it
explains 5/5 on `test_frames_without_frame_content_are_left_alone`, 4/5 on
`test_position_no_frame_shares_is_kept`, 4/5 on
`test_every_dimension_collapsed_removes_description` and 4/5 on
`test_collapse_can_make_frames_alike`.

Now: "A frame's values element goes when it empties, though its macro stays; the
description goes when nothing is left in it." Three containers, each named, no
inference.

**The fifth shared failure is an invented constraint.** 4 of 5 raised
`MultiFrameError` because a macro held two items ("must contain exactly one
item"). Nothing in the description says a macro is limited to one item; only the
shared group SEQUENCE is. The agents generalised the one rule to the other. Added:
"A macro may hold more than one item."

Both fixes are fairness clarifications. Neither changes a rule, neither removes
work: the comparison and collapse logic is untouched.

**Where this leaves solvability.** The two best runs failed exactly 5 tests each,
and all 5 are the two causes above. If the wording lands, those convert. Ten runs
across two batches have now produced 0 passes, so this is the last wording round
I would spend: if batch 5 is still 0, the collapse requirement itself is one step
too many and the fix is to cut it, not to describe it better.

The 1/5 tail (31 tests) stays ordinary agent breakage: one run's sort comparison,
another's bit-packing. No pattern, no action.

Meta 497 words. No test or source change.

## BATCH 5 (2026-08-04) - only ONE new run, and it validated the batch 4 fix

The export labelled `agent-runs(13)` held six runs, but five carry run IDs
identical to batch 4 (`rd77khrwa3fw...`, `rd71zeh3w11g...`, `rd7esqc5kv40...`,
`rd748v68z3gb...`, `rd77cajyxykm...`). They are the same runs re-exported, so
their failures were produced against the PRE-fix description and say nothing
about the batch 4 wording. Only `rd7dz1tbjcdszbz7mzcvvfgb6x8bvvyn` (Orion) is new;
filed as `agent-runs/batch5/Orion_new`.

**That one new run cleared the entire dimension and macro cluster.** Zero failures
in `TestDimensions`, `TestRaggedDimensions` or `TestValueEquality` - the five
tests that failed 4-5 of 5 in both previous batches. The batch 4 clarification
worked. Aggregating it with the stale five is what makes the shared-failure table
still look unchanged; it is an artifact of the duplicate export, not a result.

Its 23 failures are two causes, both new to the top of the list:

**1. Sorting multi-valued attributes (17 tests).** `sort_frames` compares
effective values with `<`. `ImagePositionPatient` is a pydicom `MultiValue`, which
supports equality and iteration but not ordering, so the comparison raises and the
agent classifies it as the "incomparable values" case the description explicitly
allows. That is an obedient reading: the description says incomparable values
raise, and a `MultiValue` looks incomparable. The reference converts to a tuple
first. Batch 3's Nova #1 lost 22 tests to exactly this. Added: "Multi-valued
attributes order value by value."

**2. Undefined length on re-encapsulated pixel data (5 tests).** The description
said "encapsulated again if it was" and never said the element keeps undefined
length, which DICOM requires of encapsulated Pixel Data. Two to three runs per
batch have lost tests to it. Added: "its length left undefined".

Both are clarifications of DICOM/pydicom plumbing an implementer cannot derive
from the prompt, not reductions in scope. Nothing was cut from the tests.

Meta 495 words. Also removed the transition sentence "The other four derive new
instances." per the Description Quality preamble comment.

**Standing count of genuinely new runs: batch 3 (5), batch 4 (5), batch 5 (1).**
Eleven runs, zero passes, but the causes have moved every time and each fix has
held: file meta fixed in batch 3, dimensions and macro items fixed in batch 4,
sorting and encapsulation addressed now. The best run has gone 5 failures -> 5 ->
23-but-all-in-two-new-clusters, so the earlier walls are down.

## Cause ledger across all 13 captured runs (2026-08-04)

Every distinct cause seen in any run, and whether the description now settles it.

| cause | runs hit | status |
| --- | --- | --- |
| key naming an attribute no frame carries treated as an error | run A | stated: frames carrying none group together |
| readers skipping the full validation | batch 2, run A | stated: all six reject the same malformed instances |
| derived file meta not naming the SOP class | 3 of 5, batch 3 | stated, and 0 of 5 in batch 4 |
| emptied frame-content macro deleted with its values | 4-5 of 5, batches 3-4 | stated: the values element goes, its macro stays |
| dimension only one frame reaches being dropped | 4-5 of 5, batches 3-4 | stated: one they do not all reach is kept |
| macro holding two items rejected outright | 4 of 5, batch 4 | stated: a macro may hold several items |
| `MultiValue` compared with `<`, reported as incomparable | batch 3 #1, batch 5 | stated: multi-valued attributes order value by value |
| re-encapsulated data losing undefined length | 2-3 per batch | stated: its length left undefined |
| one-bit frame length computed as rows x cols x bits / 8 | batch 3 #2, batch 4 #1 | **stated now: one-bit data packed and measured in bits, not bytes** |
| sequence equality ignoring item count | 3-4 of 5 | kept, genuine difficulty |
| ragged renumbering scoped to carriers | 3-5 of 5 | kept, the designed trap |

Nine causes stated, two kept. The nine were all DICOM or pydicom plumbing an
implementer cannot derive from the prompt, and every one of them surfaced as a
`MultiFrameError` on VALID input, which is the signature of a spec gap rather
than a hard problem: the agent was not failing to do the work, it was rejecting
input the description told it to accept.

The two kept are the actual difficulty and one agent has solved both: batch 1
run C's patch still passes the whole suite.

Meta 496 words. No test or source change at any point in this analysis.

## Proof that the wording changes are the difference (2026-08-04)

Question worth answering directly: is editing the description actually doing
anything, or is it just moving words? Measured, not argued.

Took `agent-runs/batch4/Nova_Nova_2`, the closest failing run (5 of 361), rebuilt
it from BASE, and applied ONLY the changes its author would make on re-reading
the current description. Nothing else. No test change, no reference code, no
hand-tuning toward the assertions.

| step | failures |
| --- | --- |
| the agent's patch as submitted | 5 |
| + "its macro stays" (stop deleting emptied macros) | still 5 |
| + "described or not" (normalise values with no dimension description) | |
| + "A macro may hold several items." | **0 of 361** |

Three edits, all of them literally what the new sentences say, and the run passes
the whole suite.

**What the exercise also caught, which reading alone did not.** My first attempt
removed one of THREE `_remove_empty_macros` call sites and broke nine
shared-group tests, because the agent used one helper for both the shared
sequence and the macros. The dimension tests still failed after it. Only then did
the real cause show up: the agent skips the whole normalisation pass when
`DimensionIndexSequence` is absent, so frames carrying index values were never
renumbered. The description was values-driven throughout and never said the pass
runs without a description. That is now "Among the frames carrying index values,
described or not".

This is the third time a guess about why agents failed was wrong and the replay
corrected it. Replay first, then write.

Meta 498 words. No test or source change.

## BATCH 6 (2026-08-04) - 6 new runs, 60-65 failures each, and the cause is mine

All six are genuinely new run IDs. Failures jumped from the 5-23 range to a flat
60-65, and 57 tests fail in EVERY run. A uniform cliff like that is never agent
skill; it is the artifact.

Cause: `frame_attributes` was returning MACRO SEQUENCES instead of the attributes
inside them. 32 failures read `AttributeError: 'Dataset' object has no attribute
'ImagePositionPatient'` and three more read `assert (0028,0030) in {(0028,9110)}`,
which is PixelSpacing expected, PixelMeasuresSequence delivered.

I caused it. The Description Quality check flagged the opening sentence as
preamble, I cut it, and in the same round shortened "the attributes inside the
macros" to "the attributes in the macros". Between them, nothing left in the
description said the result is FLATTENED. Every agent then returned the macros.

That sentence was load-bearing and the check could not know it, because the check
reads the description for style and never runs an agent against it. Restored as
"`frame_attributes` flattens the macros applying to one zero-based frame into the
attributes inside them", which states the flattening in the sentence itself
rather than relying on a preamble.

**This batch says nothing about the batch 4 and 5 fixes.** Those were validated
separately and by measurement: batch 4's closest run goes from 5 failures to
361/361 with only the changes the current wording asks for. The regression sits
in a different sentence entirely.

Meta 497 words. No test or source change.

**Lesson worth more than the batch: never take a style suggestion on a sentence
without checking what depends on it.** A description edit is a code change here.
The next wording round, if any, gets replayed against a captured agent patch
before it goes anywhere near a batch.

## Final cause coverage check (2026-08-04)

Every cause observed in any of the 14 captured runs, checked against the current
description phrase by phrase rather than from memory. All 15 present:

flattening · validation parity · emptied macro kept · dimension not all reach ·
values-driven pass · multi-item macro · macro equality whole · MultiValue
ordering · undefined length · one-bit measurement · file meta SOP class · empty
per-frame sequence · top-level carry-over · provenance order · re-export identity

Meta 506 words (cap raised to 550 by the author; 6 spent, 44 unspent). The
unspent budget is deliberate: the only thing still unexplained is the
ragged-dimension rule, which is the trap, not a gap. One agent has solved it and
its patch still passes all 361 tests.

Artifact at this point: reference 361/361, base 4362 with 0 failures, F2P
complete, effective LOC 486, test.sh mode 100755.

## Round 25 coverage (2026-08-04) - 374 tests

All three suggestions taken. Each one pins a clause added in the last few rounds,
which is exactly where the suite was thinnest: the wording was new and nothing
tested it.

- `TestMultiValueOrdering` (4): sorting falls through to the second and third
  components, a shorter value orders first, and grouping tells late-differing
  values apart. This pins "Multi-valued attributes order value by value", the
  clause that cost two runs 39 tests between them.
- `TestUndescribedDimensions` (5): index values with no `DimensionIndexSequence`
  are still collapsed and renumbered, through extraction and sorting, and no
  description is invented. This pins "described or not", the clause that fixed the
  5/5 failure.
- `TestEqualMultiItemMacros` (4): two equal two-item macros built apart are shared
  and keep both items, a differing second item is not shared, and merge behaves
  the same. This pins "sameness is the whole macro, items and all".

**One test passed on base and had to be fixed.**
`TestUndescribedDimensions::test_the_instance_has_no_description` only asserted a
property of its own fixture, so it passed without the solution and broke the rule
that every new test must fail on base. Body now also reads the values through
`frame_attributes`; the name is unchanged, since renaming an F2P test across
revisions is not safe. Caught by the matrix, not by review.

Matrix: new 374/374, base 4362 with 0 failures, new-on-base 374 of 374 failing,
base-on-base 4362 clean, three identical new runs, effective LOC 486, meta 506
words.

## HARDENING round (2026-08-04) - reported 3 of 4 Nova passing, so 75% and too easy

75% is a reject exactly like 0% is. The de-trapping across batches 3 to 6 removed
nine genuine spec gaps, and with all of them stated the remaining work was no
longer hard enough. The fix is a new requirement that is fully STATED but
architecturally demanding, not a hidden one; re-introducing ambiguity would just
walk back into the 0% era.

**New requirement: dimension indices are derived from the attribute they index.**
A DICOM dimension index description item may carry `DimensionIndexPointer`, the
attribute that dimension actually indexes. The derived instance must now take
that dimension's values FROM that attribute's effective value per frame, numbered
by first appearance in the result, rather than renumbering the integers the
source happened to store. A frame that does not carry the attribute does not
reach the dimension.

Why this is real difficulty rather than a puzzle:

- It forces the dimension pass to read EFFECTIVE frame attributes, so it now
  depends on the flattening machinery it previously ignored. Two subsystems that
  were independent are now coupled.
- It changes what "constant" means for collapse: the decision moves from stored
  numbers to indexed values, so a dimension can now collapse for a reason the
  stored vectors do not show.
- It is misdirecting: frame 3's number changes because frame 1's attribute
  differs, and the failing assertion is on frame 3.
- It is additive, so every existing test stays valid. A dimension with no pointer
  keeps the old behaviour, which is what `TestUndescribedDimensions` and
  `TestDimensions` already pin.

**Measured bite.** Batch 1 run C's agent patch, the implementation that passed
374 of 374 unmodified, now fails 10 of 388, all of them in
`TestPointedDimensions`. It fails nothing else, which is what an orthogonal trap
should look like: it does not disturb any behaviour that already worked.

Suite 374 -> 388. Effective LOC 486 -> 535. Meta 506 -> 528 words (within the 550
the author allowed).

Three of the new tests initially failed against the reference. The reference was
right and the tests were wrong: once a pointed dimension empties, the frame
content macro is identical in every frame, so the sharing rule moves it into the
SHARED group. The assertions looked for it per frame. Corrected to look where the
contract says it goes.

Matrix: new 388/388, base 4362 with 0 failures, new-on-base 388 of 388 failing,
base-on-base clean, three identical new runs.

## BATCH 7 (2026-08-04) - 5 Nova runs, 0 passed, and one flag that had to be fixed

| run | failed of 388 | verdict | unfair? |
| --- | --- | --- | --- |
| #2 | **1** | FAIL_TEST_MISMATCH | **yes** |
| #5 | **1** | FAIL_TEST_MISMATCH | **yes** |
| #3 | 4 | FAIL_MISSED_REQUIREMENT | no |
| #4 | 19 | FAIL_UNVERIFIED_ASSUMPTION | no |
| #1 | 22 | FAIL_MISSED_REQUIREMENT | no |

Two runs carried `agent_blame_unfair: true`, `blocker_type: verifier` and
`difficulty: unfair`, and both were 387 of 388. They were right and the fault was
mine.

**The contradiction.** The description says "one they do not all reach is kept".
When NO frame reaches a pointed dimension, the literal rule keeps it. My
reference had an `if not any(vectors)` branch that dropped it instead, and
`test_a_pointer_naming_nothing_present_drops_it` enforced the branch. Two
evaluators quoted the sentence back at me.

**Fixed in the reference, not the prompt.** The branch is gone, so the general
rule now covers the zero-reach case with no exception: the description stays, the
values go. The test is renamed `test_a_pointer_naming_nothing_present_is_kept`
and asserts the label survives. Adding an exception to the prompt would have been
the other option and it is the worse one; every exception is more surface for the
next batch to trip over, and this rule was already carrying two quantifiers.

**What the batch says about difficulty, which is the encouraging part.** The other
three runs failed on their own bugs, not on ambiguity, and the evaluators say so:

- #1 and #3: pixel validation too strict, requiring source data to already be
  even-padded, rejecting `b"abc"` and one-bit payloads that are long enough.
  `was_mentioned_in_description: true`.
- #4: assumed encapsulated input must already carry `is_undefined_length`, which
  pydicom's own `encapsulate()` does not set. 18 tests. `was_inferable: true`.
- #1, #3, #4 all also missed part of the pointed-dimension rule.

So the hardening is doing its job: the new requirement appears in three of five
runs' failures, and the remaining failures are genuine implementation errors on
stated behaviour rather than guesses about unstated rules.

**Projection.** With the contradiction removed, runs #2 and #5 pass. That is 2 of
5, 40%, at the ceiling but inside it, with the other three failing on real bugs.

Effective LOC 535 -> 529 (the dropped branch). Matrix: new 388/388, base 4362
with 0 failures, new-on-base 388 of 388 failing, base-on-base clean, three
identical runs. Meta unchanged at 528 words.
