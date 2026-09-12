# eval-results.md - awkward-sliding-windows

Base commit `cd90c720495366ea8b53be722c0624cb07004c97`, tier Olympus, category feature_request.

## Agent runs

| Run | Verdict | New tests | Failed | Msgs | Files | +LOC | Failure cluster |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Nova #1 | MISSED_REQUIREMENT | 172/181 | 9 | 5 | 5 | 987 | regularity 5, named-axis 2, typetracer 3 |
| Nova #2 | MISSED_REQUIREMENT | 167/181 | 14 | 5 | 5 | 898 | regularity 7, named-axis 5, typetracer 3 |
| Nova #3 | MISSED_REQUIREMENT | 175/181 | 6 | 6 | 6 | 1061 | regularity 3, named-axis 3, typetracer 1 |
| Nova #4 | MISSED_REQUIREMENT | 168/181 | 13 | 5 | 6 | 919 | regularity 4, named-axis 1, typetracer 10 |
| Nova #5 | MISSED_REQUIREMENT | 161/181 | 20 | 6 | 9 | 1132 | regularity 7, named-axis 5, typetracer 11 |
| Nova #6 | MISSED_REQUIREMENT | 174/181 | 7 | 5 | 5 | 1243 | regularity 5, named-axis 0, typetracer 3 |
| Nova #7 | MISSED_REQUIREMENT | 173/181 | 8 | 6 | 4 | 805 | regularity 5, named-axis 3, typetracer 2 |
| Nova #8 | MISSED_REQUIREMENT | 173/181 | 8 | 6 | 8 | 1465 | regularity 7, named-axis 0, typetracer 4 |
| Nova #9 | MISSED_REQUIREMENT | 170/181 | 11 | 5 | 5 | 839 | regularity 5, named-axis 0, typetracer 8 |
| Nova #10 | MISSED_REQUIREMENT | 169/181 | 12 | 5 | 5 | 800 | regularity 7, named-axis 5, typetracer 3 |

Every run built a working feature (161-175 of 181 passing, baseline green in all ten) and every run
failed. 0/10 is a reject, so the batch is a diagnosis, not a result.

### The decisive finding: the description was wrong, not the agents

Three tests failed in **all ten** runs, and they share one cause.

| Test | 10/10 failure |
| --- | --- |
| `missing_values_inside_a_list_survive_padding` | got `1 * 3 * 2 * ?int64`, expected `1 * var * 2 * ?int64` |
| `an_empty_array_of_lists_keeps_its_window_types` | got `0 * var * 2` or `0 * 0 * 2`, expected `0 * var * var`; the inner half of this pin was itself unfair, see below |
| `typetracer_records_match_the_concrete_form` | concrete `1 * 3 * 2 * ?{x: int64}` against traced `## * var * 2 * ?{x: int64}` |

The old clause read "the dimension holding the windows is itself fixed size when every list it came
from had the same length". Ten out of ten agents implemented exactly that, literally. Nova #3's code
is the clearest:

```python
same_source_length = len(source_lengths) != 0 and all(x == source_lengths[0] for x in source_lengths)
if same_source_length and all(x == counts[0] for x in counts):
    return ak.contents.RegularArray(inner, counts[0], ...)
```

That reading makes the OUTPUT TYPE DEPEND ON THE DATA, which is why their concrete and typetracer
forms disagreed: with no data, the counts are unknown, so the traced branch has to emit a variable
dimension while the concrete one emits a fixed size. Their own typetracer failures are a symptom of
my wording, and a single-list array made it bite everywhere, since one list trivially has "the same
length" as every other.

The reference tied regularity to the input dimension's own kind all along. The clause now says so:
"fixed size when the dimension it came from was fixed size and variable when that one was variable,
whatever lengths its lists happened to have."

Second cause, 3-5 of 10 runs: the named-axis map. The prompt said only that `axis` counts as it does
everywhere else, so nothing told an agent what happens to a name when a dimension appears or
disappears. Nova #3 even called `_remove_named_axis`, with `axis + 1` instead of `axis`. Now stated:
the inserted dimension is unnamed and the inverse drops the name of the one it removes, as
`ak.singletons` and `ak.firsts` do.

Third, my own over-pinning: eleven typetracer tests compared `layout.form` exactly, so an agent whose
concrete path built a `ListArray` where its traced path built a `ListOffsetArray` failed on
representation rather than behaviour. Those now compare `type.content`, which is the contract. Two
earlier reviewers had flagged this coupling as advisory; the batch turned it into a real cost.

### Solvability, verified against the batch's own code

Replaying all ten patches against the revised suite still fails, which is expected: rewording a prompt
cannot change code that is already written. So solvability was demonstrated on the best run instead.
Nova #3, at 6 failures, needed exactly three edits, and the corrected description dictates every one:

| Edit to Nova #3's own code | Clause that now requires it |
| --- | --- |
| `_remove_named_axis(named_axis, axis + 1, ...)` -> `axis` | the inverse drops the name of the dimension it removes |
| `fixed = all(x == size for x in lengths)` -> `fixed = incomplete in ("drop", "pad")` | cut off windows are variable length, the others fixed |
| count dimension gated on `isinstance(layout, RegularArray)` rather than on the observed counts | fixed size when the dimension it came from was fixed size |

With those three edits and nothing else, Nova #3's implementation passes **181/181 new tests and 4608
baseline tests**. The problem is solvable: the best agent was three prompt-stated details from green,
and all three were details the prompt failed to state.

### One further unfair pin, found in the same pass

`an_empty_array_of_lists_keeps_its_window_types` asserted the entire type of a keep-mode result on an
empty array. The window-holding dimension is fixed by the corrected clause, but the window lists' kind
is not: with zero windows, "windows that all hold exactly `size` elements are fixed size lists" is
vacuously true, and "cut off ones are variable length" has no instances, so both `var` and `2` are
defensible readings, and the batch took both. It is now
`an_empty_array_of_lists_keeps_its_window_dimension` and asserts only the determined part, no windows
and a variable window-holding dimension. The drop-mode sibling keeps its full pin, since both readings
agree there. Unmodified Nova #3 goes from 6 failures to 5.

### What was changed, and what was deliberately not

Changed: the regularity clause (reworded), the named-axis convention (added), and the eleven form
comparisons (relaxed to types). meta.md is 596 words.

Not changed: the geometry, the option handling, the parameter placement, the `ValueError` and
`AxisError` contracts, and the empty-array and typetracer tests. Those failures were real
implementation misses against a clause that already said what it meant, including one agent crashing
with `operands could not be broadcast together with shapes (2,) (0,)` on a length-zero array and one
copying the string parameter onto the windows, which is a planted mutation. The next batch should
land in band rather than at zero, and the traps that did the work are untouched.

## Local validation (pre-batch)

| Run | Mode | Command | Result |
| --- | --- | --- | --- |
| 1 | base, base commit only | `./test.sh --output_path /tmp/base.xml base` | 4608 passed / 176 skipped |
| 2 | new, base + test.patch | `./test.sh --output_path /tmp/new.xml new` | 223 failed (all of them) |
| 3 | new, base + test.patch + solution.patch | `./test.sh --output_path /tmp/new2.xml new` | 223 passed |
| 4 | base, base + test.patch + solution.patch | `./test.sh --output_path /tmp/base2.xml base` | 4608 passed / 176 skipped |
| 5-9 | new, solution applied, five repeats | as run 3 | 223 passed every time |
| 10-14 | base, solution applied, five repeats | as run 4 | 4608 passed / 176 skipped every time |
| 15 | apply order: test.patch then solution.patch | `git apply --check` both | clean |
| 16 | apply order: solution.patch then test.patch | `git apply --check` both | clean |

Environment: `public.ecr.aws/d3j8x8q7/olympus-base-python:latest`, `--network none`, uid 1000.

## Oracle agreement

An independent model of the contract, written from `meta.md` prose alone:

| Battery | Cases | Mismatches |
| --- | --- | --- |
| random ragged arrays, all six mode/alignment combinations | 3205 | 0 |
| fixed-size (regular) inputs | 600 | 0 |
| structural validity, packing, buffer round-trip | 400 | 0 |
| typetracer form equals concrete form | 200 | 0 |

## Mutation battery

19 mutations of the reference, each a plausible wrong implementation. Every mutation must be caught
by at least one new test. The battery was re-run against the revised solution after the
Solution Quality round, so it reflects the shipped code.

| # | Mutation | Verdict |
| --- | --- | --- |
| 1 | right alignment ignored, left geometry used for both | KILLED |
| 2 | drop count without the short-list guard | RETIRED (equivalent: `maximum((n - size) // stride + 1, 0)` equals the guarded count for every `stride >= 1`) |
| 3 | keep counts computed with the drop rule | KILLED |
| 4 | keep does not clip window stops to the list end | KILLED |
| 5 | keep does not clip window starts to zero | KILLED |
| 6 | pad clamps outside positions instead of masking them | KILLED |
| 7 | pad only masks past the end, never before the start | KILLED |
| 8 | fixed-size windows built as variable-length lists | KILLED |
| 9 | window parameters left on the new outer dimension | KILLED |
| 10 | fixed-size input loses its fixed-size window dimension | KILLED |
| 11 | missing lists projected away instead of carried | KILLED |
| 12 | out-of-order `ListArray` starts read straight from the content | KILLED |
| 13 | typetracer falls through to the concrete arithmetic | KILLED |
| 14 | inverse ignores what the previous window already reached | KILLED |
| 15 | inverse does not restart the overlap at each list | KILLED |
| 16 | inverse places every window at the same spot | KILLED |
| 17 | inverse gives the rebuilt lists the outer parameters | KILLED |
| 18 | inverse accepts a non-list dimension inside `axis` | KILLED |
| 19 | windows at the outermost depth copy the array's own parameters | KILLED |

18 killed, 1 retired as equivalent. The tree was restored and re-verified clean (173 passed at that
point) after the battery. The tests added in the two coverage rounds since then cover named axes,
dispatch, empty arrays and low-level metadata, none of which the mutations targeted.

## Test Fairness round

The platform check returned FAIL on 2 of 141 assertions: both typetracer touch tests asserted
`"node0" in report.shape_touched`, which pins an internal access path rather than behaviour. Both
assertions were removed; the tests keep their public type assertion and the data-touch bound, which
the check rated fair. The three advisory suggestions were taken as far as they are correct:
non-integer `size`/`stride` now covers strings and None as well as floats (5 tests), and the
inverse's `ValueError` for non-list contents is now also exercised through a union branch and
through a mask (2 tests). The suggestion to assert `len(report.data_touched) == 0` was not taken:
the repository reports a data dependency for buffers an operation will consume (`_local_index` and
every other structural operation call `_touch_data` on the typetracer path), so zero touches is not
achievable by a correct implementation. The description clause was reworded instead, from "nothing
about the data may be read" to "the data is unknown, so no value may be looked at", which is what
the tests enforce and what the library actually guarantees.

## Scope

| Measure | Value |
| --- | --- |
| human-effective LOC | 584 |
| raw added LOC | 890 |
| files touched by solution.patch | 20 |
| new tests | 223 (all fail on base) |
| meta.md | 728 words |

## Second coverage round

The check passed with four advisory suggestions; all four were taken, 144 -> 156 tests.

| Suggestion | What was done |
| --- | --- |
| typetracer value access: distinguish metadata from primitive data | The two whitelist assertions were replaced. Rearranging whole lists (`axis=0` for both operations) cannot need the values, and the tests now assert that the leaf buffer's key, read off the form rather than hard-coded, is absent from `report.data_touched`. That is the "no value may be looked at" clause, stated as a negative rather than as a permissive bound. |
| negative unwindows axes | `axis=-2` and `axis=-3` equivalences against their positive counterparts, plus `axis=-5` raising `AxisError`. |
| axis validation | A fractional axis on both operations. The repository raises `ValueError` from `regularize_axis`, not `TypeError`, so that is what the tests assert. |
| integer-like inputs | numpy integer scalars accepted for `size` and both `stride` arguments; booleans rejected with `TypeError`, matching `is_integer` at `src/awkward/_regularize.py:21-39`. |

## Third fairness round

FAIL on 3 of 156. Two were the fractional-axis tests, flagged for pinning `ValueError` where
`regularize_axis` raises `TypeError`. Measured instead of argued: `ak.num`, `ak.local_index` and
`ak.pad_none` all raise `ValueError` for `axis=1.5`, because `_named_axis_to_positional_axis` runs
first and rejects a float before `regularize_axis` is ever reached, so these operations already match
their siblings exactly. The class is genuinely ambiguous to a reader, though, so both tests were
deleted rather than defended; the axis contract stays covered by the negative-axis equivalences and
the `AxisError` depth tests.

The third was the stride-gap case, which pinned an unstated policy. That one was a real description
gap: `meta.md` now says a stride wider than the preceding window leaves a gap that nothing fills and
that the rebuilt list holds what the windows contributed and nothing else. The test stays, and a
second one was added for a stride that clears the window entirely.

Advisory suggestions taken: `incomplete` and `align` rejected for None and for numeric values (4
tests), and a negative `stride` for both operations (2 tests). 156 -> 161 tests.

## Fourth coverage round

The check passed; all three advisory suggestions were taken, 161 -> 170 tests.

| Suggestion | What was done |
| --- | --- |
| empty outer arrays | A length-zero array with a known form (`0 * var * int64`) for both operations, asserting values and the exact result types, plus typetracer form parity for each. |
| nested typetracer access reporting | The no-value-read assertion repeated at a nonzero axis: windowing at `axis=1` of a three-deep array and rebuilding at `axis=1` of a four-deep array both rearrange whole lists, and the leaf buffer's key is absent from `report.data_touched` in each. |
| metadata with low-level output | `behavior` and `attrs` passed alongside `highlevel=False` for both operations: the result is a `Content` and the values are unaffected, since metadata only attaches to a high-level array. |

## Solution Quality round

PASS with 2/3 on both axes. Three points were raised; two were real and are fixed, one was a
misreading that is now pinned by tests.

| Point | Resolution |
| --- | --- |
| named axes dropped wholesale rather than adjusted | Fixed. `ak.windows` now calls `_add_named_axis` for the dimension it inserts and `ak.unwindows` calls `_remove_named_axis` for the one it removes, matching `ak.singletons` and `ak.firsts`. Verified: windowing an array named `("outer", "inner")` returns `{'outer': 0, 'inner': 1}` and the inverse returns `{'outer': 0}`. |
| `_touch_data` on the typetracer path where shape reasoning would do | Fixed. The explicit call was redundant: `_carry` already declares exactly the dependency, and the touch reports are byte-identical without it (flat `axis=0` still reports its one buffer, the nested cases still leave the leaf untouched). Removed from both unknown-data branches. |
| `merge_windows` given a `parameters` argument it never uses, so `axis=0` looked like it dropped them | Fixed by removing the dead argument. The behaviour was already right: at `axis=0` the rebuilt elements keep whatever the windows carried, now asserted by `unwindows_at_the_outermost_depth_keeps_the_windows_parameters`. |
| `_windows_axis0` passing `None` for window parameters | Not a defect, and now proven. At the outermost depth there is no list node to take parameters from, and copying the array's own would tag each window with them: windows of strings would themselves be strings. `meta.md` states this, two tests pin it, and mutation 19 (copying `self._parameters` there) is killed. |

## Problem-and-tests quality round

Two warnings, both taken.

| Warning | Resolution |
| --- | --- |
| tests reaching into private internals | The one genuine private reference was `ak._nplikes.shape.unknown_length`. `awkward.typetracer` re-exports that name in its own `__all__`, so the test uses `ak.typetracer.unknown_length` now, and no `ak._`-prefixed module is referenced anywhere in the suite. The other flagged idioms are the repository's own: `str(array.type)` appears in 51 of its test files, `layout.form ==` in 13, and `typetracer_with_report` is public API. They also carry the contract here, since fixed-size versus variable-length results are a stated requirement, so they stay. |
| a boolean could read as an integer for `size` and `stride` | `meta.md` now says "a boolean not counting as one", matching `is_integer` at `src/awkward/_regularize.py:21-39` and the three tests that pin it. |

## Fifth coverage round

Both advisory suggestions taken, 173 -> 181 tests, written in the repository's own idioms rather than
invented ones.

| Suggestion | What was done |
| --- | --- |
| named axes | Four tests shaped like `test_named_axis_ak_singletons` and `test_named_axis_ak_firsts` in `tests/test_2596_named_axis.py`: positional axis against the same axis by name, then the resulting `named_axis` map, each with its negative-index pair. The maps match the neighbours exactly, `{"x": 0, "y": 2}` and `{"x": 0, "y": 1}` for the dimension `ak.windows` inserts, `{"y": 0}` and `{"x": 0}` for the one `ak.unwindows` removes, plus a round trip that recovers a named array. |
| dispatch integration | Two tests using the `types.SimpleNamespace` sentinel from `tests/test_4107_operations_batch.py`: each operation returns the interception and the sentinel appears in the `array_likes` offered to `__awkward_function__`. A third test passes plain Python lists, the `ak.to_layout` path both operations document. |

## Sixth fairness round

FAIL on 1 of 181, plus one advisory that mattered.

`a_union_keeps_its_union_type` asserted the rendered type starts with `2 * union[`. The prompt only
says both operations work on lists reached through a union; it never says the result must still be
represented as one, and an implementation that normalises to an equivalent layout would satisfy every
stated union behaviour. Deleted. The union contract stays covered by `a_union_of_list_types` on values
and by `unwindows_a_union_of_windows`.

The advisory was sharper than the FAIL. Every overlap example used matching values, so none of them
distinguished "each window contributes what the one before it did not reach" from an implementation
that overwrites, or one that validates and rejects. Two tests added with a later window that disagrees:
`[[[1, 2], [9, 3]]]` rebuilds to `[1, 2, 3]`, and `[[[1, 2, 3], [9, 9, 4], [9, 9, 5]]]` to
`[1, 2, 3, 4, 5]`, so the 9s must be ignored rather than written or refused. That is the inverse's
central clause, and until now nothing pinned it. 181 -> 182 tests.

Best-run position after this round: unmodified Nova #3 fails 5, all five prompt-determined.

## Seventh coverage round: an advisory found a real bug

The check passed, and one of the three suggestions exposed a defect in the reference.

Windowing a union whose branches have different list depths at a negative axis produced an INVALID
layout. `maybe_posaxis` returns None for such a union, so the old code fell through and recursed into
each branch with the negative axis, which each branch then resolved against its own depth: for the
shallower branch that meant its outermost depth, so windowing changed that branch's length. The result
was `union[2 * var * int64, var * 2 * var * int64]` with branch lengths `[0, 1]` under a union of
length 2, and `ak.validity_error` says `index[i] >= len(content[tags[i]]) at i=0`. `to_list` raised
`IndexError`, which is how it surfaced.

Sibling operations avoid this by accident rather than by design: `ak.local_index` at the same axis also
resolves per branch, but its axis-0 path preserves length, so the union stays valid. Any operation that
changes a dimension's length cannot resolve a negative axis per branch.

Fixed in `UnionArray._windows` and `_unwindows`: an axis the branches disagree about is an `AxisError`.
My own structural-soundness battery would have caught this if it had covered unions, so it now does.

Tests added, 182 -> 192: a mixed-depth union windowed at a shared axis (values and soundness), the
ambiguous negative axis and the past-the-shallowest-branch axis as `AxisError` for both operations,
unions through the soundness battery in all three modes, typetracer no-value-read through a mask and
through a record, and three unequal-window inverse cases with `stride > 1` to pin the previous-window
reach calculation (`[[1, 2, 3], [4, 5]]` at stride 2 rebuilds to `[1, 2, 3, 5]`).

## False-positive panel: a confirmed functional false positive

The panel found an agent that passed all 192 tests while breaking a documented rule, so the suite had a
real hole and the pass was undeserved.

The candidate's inverse inferred alignment from the window lengths: when the first window was shorter
than a later one it set `first_start = lengths[0] - window_size`, treating the pass as right aligned.
The prompt states the rule unconditionally, "window number `j` of a list sits `j` strides along it and
contributes only the elements the window before it did not reach", and `ak.unwindows` has no `align`
argument, so there is nothing to infer. The panel's probes: `ak.unwindows([[[1], [2, 3, 4]]])` returned
`[[1, 3, 4]]`, dropping an element, where the reference returns `[[1, 2, 3, 4]]`, and unwindowing a
right aligned keep pass recovered the original instead of applying the stride merge.

Why the suite missed it: every unequal-window fixture I had placed the LONGEST window first, so the
candidate's `first_start` stayed 0 and the branch never ran. A coverage gap of exactly the shape the FP
check exists to find.

Five discriminators added, all off that shape:

| Test | Pins |
| --- | --- |
| `a_later_window_longer_than_the_first_contributes_all_it_reaches` | `[[[1], [2, 3, 4]]]` -> `[[1, 2, 3, 4]]` |
| `a_later_longer_window_after_a_single_element_window` | the panel's own fixture, `[[33, 11, 93]]` |
| `windows_of_growing_length_are_placed_by_stride_alone` | `[[[1], [2, 3], [4, 5, 6]]]` -> `[[1, 2, 3, 5, 6]]` |
| `a_later_longer_window_with_a_wider_stride` | the same shape with `stride=2` |
| `unwindowing_a_right_aligned_pass_places_windows_by_stride` | right aligned keep windows merge to `[[1, 1, 2, 2, 3, 4], [5, 5, 6]]`, not back to the original |

The last one is the direct answer to the inference: the prompt promises round-trip recovery only for a
left aligned pass, so unwindowing a right aligned one must produce the stride merge, duplicates and
all. Trap-proven: a mutation that computes each window's reach from the longest window rather than from
the preceding one fails all five and nothing else.

Advisories taken as well: axis-type rejection for a float, None and an unknown axis name on both
operations, asserted as `(TypeError, ValueError)` rather than a single class, because an earlier
fairness round flagged pinning one; and `typetracer_with_report` no-value-read checks for `keep`, `pad`
and right alignment, not only form equality. 192 -> 205 tests.

## Batch 2 and the Auto Review

The review reports **1 of 10 agents passed legitimately**, so after the description fix the problem is
solvable and sits at the low end of the band. The nine failures were substantial implementations
(609-889 raw added lines, 82-240 messages), all passed the 4608-test baseline, and most passed 169-191
of the 192 new tests before missing string or list parameters, named-axis shifts, typetracer forms,
empty layouts, union depth validation, or unequal-window reconstruction. The review classifies both
failure clusters as subtle but fair, and found no retrieval of an upstream answer (the GitHub lookups
in the trajectories returned 404/403).

Three findings, one of them blocking.

| Finding | Resolution |
| --- | --- |
| **S1, High** `incomplete="pad"` could not window a string or bytestring | Real bug, fixed. The pad path option-wrapped the character content and then built a `RegularArray` still carrying `__array__: "string"`, which the constructor rejects, so `ak.windows(ak.Array(["hi"]), 3, axis=1, incomplete="pad")` raised. A string cannot hold missing characters at all: the library's own `ak.pad_none` refuses the same combination with `IndexedOptionArray is not allowed to have parameters["__array__"] = "string"`. Padding now gives up the string or bytestring tag, and the characters give up theirs with it, so the result is a fixed size list of optional bytes. Stated in `meta.md` and covered by six new tests over both strings and bytestrings, including the soundness battery. |
| **T4, Medium** typetracer no-touch not asserted for keep, pad and right alignment | Already fixed before this review landed: the three `typetracer_with_report` tests for those modes went in with the false-positive round, which is why the review counts 192 tests and the suite now has 211. |
| **P4, Medium** rhetorical opening | Cut. `meta.md` now opens on the two operations instead of the motivation clause, which also paid for the new padding sentence: 593 words. |

214 tests, all failing on base, all passing with the reference, baseline unchanged, 584 human-effective
LOC.

## Eighth coverage round

Two symmetry gaps, both taken, 211 -> 214 tests. `ak.windows` rejected an unknown axis name but the
inverse had no such test; it does now. And the mask coverage was lopsided: `ak.windows` ran through both
byte and bit masks while `ak.unwindows` only ever saw a byte mask, so a bit-masked round trip and a
bit-masked soundness pass over all three modes were added.

## Solvability re-check at 214 tests

The suite grew from 192 to 214 after batch 2 (padded strings and bytestrings, the union axis guard, the
window-placement discriminators, bit-masked round trip, axis-type rejection), so solvability had to be
re-measured rather than assumed. Batch 2's passing patch is not in the local artifacts, so the check ran
against batch 1's best run again.

Nova #1 batch's best run, with only the three edits the corrected description dictates and nothing else,
now passes **214/214 new tests and 4608 baseline tests**. It satisfies every requirement added since
batch 2 with no further changes:

| Requirement added after batch 2 | That agent's unaided behaviour |
| --- | --- |
| padding gives up a string or bytestring tag | `2 * var * 3 * ?uint8`, the same as the reference |
| an axis a union's branches disagree about is an `AxisError` | raises `AxisError` |
| window `j` sits at `j * stride`, never inferred from lengths | `[[[1], [2, 3, 4]]]` rebuilds to `[[1, 2, 3, 4]]` |

That is worth more than the earlier check: the newly added rules were not written with this agent's code
in view, and an independent implementation satisfies all three from the description alone. The padded
string rule in particular is discoverable rather than exotic, since that agent had already stripped the
`__array__` tag when option-wrapping the characters, which is exactly the fix the Auto Review asked of
the reference.

Standing evidence for solvability: batch 2 passed 1 of 10 against the 192-test suite, and an independent
agent implementation passes the full 214-test suite today.

## Ninth coverage round, and what it cost solvability

Two suggestions, both taken, 214 -> 221 tests. The second is routine: numpy integer axes are accepted and
a boolean axis is rejected, matching how `size` and `stride` were already covered.

The first was not routine. It asked which reading of "did not reach" the contract takes, cumulative
covered extent or the window just before. The prose says "the window before it", so three tests now pin
it, and a mutation that measures against the running maximum instead fails eight tests including both new
ones.

The honest cost: the fixed batch-1 agent tree, which passed 214/214, fails exactly these three. It does
not use cumulative reach either; it derives the rebuilt length from the last window's placement and
truncates, so `[[[1, 2, 3], [4]]]` comes back as `[[1, 2]]`, dropping an element the first window
contributed. Every monotonic input agrees with the reference, which is why it survived 214 tests, and only
hand-built non-monotonic windows separate them. That is a real undetected defect class, so the tests stay,
and the description now states the rule outside the gap sentence where it was previously scoped: "every
element some window contributes is in the rebuilt list, in position order, and nothing else is ... and no
later window takes an element back." `meta.md` is 591 words.

### Solvability restored, and the reach tests earned their place

Rather than leave that hanging, the agent's failure was read instead of guessed. Its carry logic is
already right; only its length bookkeeping is wrong:

```python
skip = max(previous_length - stride, 0)
carry_values.extend(range(window_start + skip, window_stop))
group_length += window_length - skip      # negative when the window is shorter than the overlap
```

When a window is shorter than what the one before it already covered, `window_length - skip` goes
NEGATIVE, so the accumulator removes an element a previous window had contributed. The carry never
emits it twice; the length simply shrinks. One `max(..., 0)` fixes it, and that is exactly what the
clause now demands: no later window takes an element back.

With that fourth edit, all of them dictated by the description, the agent tree passes **221/221 new
tests and 4608 baseline tests**. So the reach tests do not demand a redesign, they catch an off-by-one
that costs one call to `max`, which is also why they are worth keeping: without them a negative
contribution count silently deletes data on any non-monotonic input, and every monotonic input hides it.

The platform's own batch-2 notes list "allowing negative contribution counts" among the observed failure
modes, so this defect was already occurring in the wild and going undetected.

Solvability evidence: batch 2 passed 1 of 10 at 192 tests, and an independent agent implementation
passes the full 221-test suite with four small clause-dictated edits.

## On hints

Hints do not exist at this tier: they were removed for Olympus in April 2026 and only Diamond retains a
hinted-run pipeline, so there is no hint field to fill. The equivalent lever is the description, which
still had a few words of budget.

They went to the weakest link in the false-positive mapping. Two tests required an `AxisError` when a
union's branches disagree about an axis, and the only sentence covering them said "a depth the array does
not have", which is a stretch for a union whose branches have depth 2 and depth 3: each branch does have
some depth, they merely disagree. The clause now names the case, "a depth the array does not have, or one
a union's branches disagree about, is an `AxisError`", paid for by dropping "and, to take them back,"
from the opening, since the inverse gets its own paragraph. 594 words.

Nothing else was softened. The remaining difficulty is where the batches showed it: parameter movement,
named-axis shifts, typetracer forms, empty layouts and the inverse's contribution arithmetic, all stated
and all landed by at least one real implementation.

## Hints in the description (by direction)

The tier has no hint field, so the hints went into `meta.md` as a closing paragraph. Each one targets a
cluster the batches actually failed on, and each is a behavioural principle rather than a recipe: no
helper, file or algorithm is named, so the implementation work is untouched.

| Hint | Cluster it addresses |
| --- | --- |
| the result's type never depends on the data, and an array with no lists types the same way | batch 1's 10/10 killer (data-dependent regularity) and batch 2's typetracer-form and empty-layout failures |
| a window reaching no further contributes nothing, never less than nothing, so the rebuilt list never loses an element it already held | the negative contribution count that cost both agent trees, and that the platform lists among batch 2's failure modes |
| the named axes that survive keep the dimensions they described | the named-axis shift cluster, 7 runs in batch 2 |

One thing was deliberately not written: the paragraph does not say these are the hard parts. The draft
opened "Three things are easy to get wrong" and that framing was cut, because spotlighting which
requirements are difficult is measured to erode pass rate hard, a comparable sentence having moved one
problem from about 40% to 60%. The three facts are stated plainly instead, so the information is intact
without advertising where to look.

`meta.md` is 665 words, past the 600 set earlier; that is the cost of the hints and it was a direction,
not a drift. 221 tests unchanged, all failing on base, all passing with the reference, baseline green.

## Tenth coverage round

Both suggestions taken, 221 -> 224 tests, and both needed the fixture shape worked out rather than guessed.

The typetracer-through-wrappers request took two attempts. A record whose field is only two deep fails the
no-touch claim honestly, because at that axis the merged elements ARE the values, so the data is genuinely
needed; the claim only holds where whole lists are rearranged. The test therefore uses a three-deep field,
where the leaf stays untouched. The union attempt first collapsed: concatenating two same-typed arrays
merges into a plain list type rather than a union, so the fixture had to be heterogeneous. With a union of
a number branch and a record branch, both branches' leaves stay untouched and both are now asserted.

The parameter suggestion was a direct probe of the padding fix, and it holds: a string array carrying a
custom `tag` keeps `{"tag": "z"}` on its padded windows while `__array__` is dropped, and keeps both under
`"keep"`. Worth having, since the fix strips a parameter by name and could easily have taken the rest with
it.

Solvability re-checked at 224: the agent tree with its four clause-dictated edits still passes 224/224.

## Alignment round: convention is not a contract

The check warned that four things the tests require were left to Awkward convention rather than written
down: `__awkward_function__` interception, `behavior` and `attrs` propagation with explicit overrides and
their absence from a low level result, numpy integers and named axis strings for `size`, `stride` and
`axis`, and bytestrings behaving like strings under padding.

Every one of those tests exists because an earlier round asked for it, so deleting them would undo that
work. They are now stated instead, in three sentences: metadata works as it does throughout the library
and an intercepting array decides for itself; the three integer arguments take any integer including
numpy's own, and `axis` also a name; a bytestring behaves like a string throughout.

That closes the last hidden-requirement risk in the mapping. The count of codebase-inferable requirements
is now zero rather than one, and `meta.md` is 728 words, the cost of two directions: hints for solvability
and this alignment. 224 tests unchanged, all failing on base, all passing with the reference, baseline
green.

## Eleventh fairness round

FAIL on 1 of 224, and the reasoning holds. `unwindows_at_the_outermost_depth_keeps_the_windows_parameters`
required the rebuilt result to carry `{"tag": "z"}` after `axis=0`. At that depth there is no rebuilt LIST
node to hold list parameters, so the implementation puts them on the element content, and no clause fixes
that placement. The asymmetry is with my own sentence for the forward direction, which says windows made at
the outermost depth carry no parameters at all: if the description declines to transfer parameters there for
one operation, it cannot silently require it for the other.

The test is deleted rather than the behaviour changed. The parameter-transfer clause is still covered by
`unwindows_gives_the_windows_parameters_to_the_lists` at an ordinary axis, which the check rates
prompt-stated, and `DESIGN.md` now records the axis-0 placement as an unasserted structural choice so a
later round does not re-add the pin.

223 tests, all failing on base, all passing with the reference, baseline green, and the agent tree still
passes 223/223.
