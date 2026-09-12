# DESIGN.md — awkward-sliding-windows

## 1. Title

Add sliding windows over the lists of an array

Host: [scikit-hep/awkward](https://github.com/scikit-hep/awkward), BSD-3-Clause, 973 stars, base
commit `cd90c720495366ea8b53be722c0624cb07004c97` (2026-07-27).

## 2. Shape classification

- Shape: **O-Composite-add** with an O-Algorithm-correctness core (`SHAPES.md` Pattern 12). Two new
  public operations that must be honoured by every layout node the library can build, plus a
  round-trip law between them.
- Pass rate: <= 40% cap, designed for the corpus mode of about 1 in 10.
- Best agent: mixed (Orion for the long-horizon integration, Nova for the geometry).
- Predicted dominant verdict: MISSED_REQUIREMENT (right alignment, the fixed-size result type,
  parameter placement, typetracer).

## 3. Public API surface

- `ak.windows(array, size, *, stride=1, incomplete="drop", align="left", axis=-1, highlevel=True,
  behavior=None, attrs=None)`
- `ak.unwindows(array, *, stride=1, axis=-2, highlevel=True, behavior=None, attrs=None)`

Nothing existing changes signature or behaviour, so the feature is reachable from the current
surface and every new test compiles and runs on the base commit (it fails at the attribute lookup).

## 4. Canonical form

- A window is `size` adjacent elements; consecutive windows begin `stride` apart; both >= 1.
- `align="left"` anchors the grid at the start of each list, `align="right"` at its end.
- `incomplete="drop"` keeps windows lying entirely inside the list; `"keep"` keeps every window
  holding at least one element, cut off at the edge; `"pad"` keeps the same windows as `"keep"` and
  fills them to `size` with None, after a left aligned window and before a right aligned one.
- Both alignments therefore yield the same window COUNT and different window POSITIONS.
- An empty list yields nothing in all three modes.
- `"drop"` and `"pad"` windows are `RegularArray(size)`; `"keep"` windows are variable length; the
  new window dimension is regular exactly when the windowed dimension was.
- The windowed lists' parameters move to the window lists; the new dimension carries none.
- A missing list stays missing; missing values inside a list are ordinary elements.
- `ak.unwindows` places window `j` at `j * stride` and takes only what the window before it did not
  reach; a gap left by a stride wider than the preceding window is not filled, so the rebuilt list is
  the windows' contributions and nothing else. It inverts a left aligned `"keep"` pass when
  `stride <= size`.
- Both operations work on typetracer arrays without reading data.

## 5. Blind-spot pre-empts

- Alignment: "laid out from its end, the last one ending after its last element".
- Result typing: "Windows that all hold exactly `size` elements are fixed size lists".
- Regular propagation: "fixed size when every list it came from had the same length".
- Parameter placement: "belong to the windows now, and the dimension holding the windows carries
  none".
- Falsy-on-empty: "an empty list gives none under any of the three".
- Unstated inverse: nothing says what `"pad"` does to a list shorter than `size` beyond the general
  rule, so the count follows from the grid, not from a special case.

Codebase-inferable requirements: 0. What used to lean on convention (`highlevel` / `behavior` /
`attrs`, interception, numpy integers, named axes, bytestrings) is now stated.

## 6. Description

`meta.md`, 728 words, ASCII, no headers. Over the guide by direction (hints added to protect
solvability, the tier having no hint field) and then by necessity (four convention-based requirements
stated so no test rests on convention alone).

## 7. File footprint (as shipped)

| Action | Path | Raw | Human-effective |
| --- | --- | --- | --- |
| ADD | src/awkward/_windowing.py | 257 | 182 |
| ADD | src/awkward/operations/ak_windows.py | 117 | 41 |
| ADD | src/awkward/operations/ak_unwindows.py | 96 | 30 |
| MODIFY | src/awkward/contents/content.py | 54 | 43 |
| MODIFY | src/awkward/contents/listoffsetarray.py | 60 | 50 |
| MODIFY | src/awkward/contents/regulararray.py | 47 | 39 |
| MODIFY | src/awkward/contents/listarray.py | 36 | 29 |
| MODIFY | src/awkward/contents/indexedoptionarray.py | 27 | 23 |
| MODIFY | src/awkward/contents/bytemaskedarray.py | 24 | 20 |
| MODIFY | src/awkward/contents/recordarray.py | 34 | 28 |
| MODIFY | src/awkward/contents/unionarray.py | 38 | 31 |
| MODIFY | src/awkward/contents/numpyarray.py | 22 | 18 |
| MODIFY | src/awkward/contents/unmaskedarray.py | 18 | 15 |
| MODIFY | src/awkward/contents/emptyarray.py | 12 | 9 |
| MODIFY | src/awkward/contents/bitmaskedarray.py | 8 | 5 |
| MODIFY | src/awkward/_do.py | 15 | 10 |
| MODIFY | src/awkward/operations/__init__.py, src/awkward/__init__.py | 3 | 3 |
| MODIFY | docs/reference/toctree.txt | 2 | 2 |

TOTAL: 890 raw / **584 human-effective** across 20 files (floor 430).

## 8. Solution outline

- `regularize_windows` / `regularize_unwindows` — argument validation and the error kinds.
- `padded_window` — a string cannot hold missing characters, so padding gives up the string or
  bytestring tag and the characters give up theirs with it; every other parameter still moves inward.
- `window_count` — the per-list window count, used to keep a regular dimension regular.
- `windows_of_offsets` — the kernel: counts, grid positions per alignment, clipping for `"keep"`,
  masking for `"pad"`, and the gathered result.
- `merge_windows` — the inverse kernel: per-window placement, the overlap already reached, and the
  rebuilt offsets.
- `Content._windows_axis0` / `_unwindows_axis0` — the outermost-depth path, shared by every node.
  There is no list node there, so the windows take no parameters. The inverse's rebuilt elements do
  carry whatever the windows had, which is a structural choice no clause fixes, so nothing asserts it.
- A union whose branches have different depths rejects an axis they disagree about, rather than
  resolving it per branch, which would window one branch at its own outermost depth, change that
  branch's length and leave the union invalid.
- `Content._windows` / `_unwindows` on all thirteen layout classes — option nodes carry their index,
  indexed nodes project, unions and records recurse per content, `ListArray` compacts, `RegularArray`
  keeps its regularity, `NumpyArray` regularises multidimensional data.
- Named axes are adjusted structurally rather than dropped: `_add_named_axis` for the dimension
  `ak.windows` inserts and `_remove_named_axis` for the one `ak.unwindows` removes, following
  `ak.singletons` and `ak.firsts`.
- No new C++ kernel: `awkward_cpp` is a pinned binary dependency, so all index arithmetic goes
  through `nplike`, which is also what makes the typetracer path work.

## 9. Test file

`tests/test_windows_541af3.py`, 223 tests: geometry for both alignments and all three incomplete
modes, stride wider than size and wider than the list, empty and short lists, result types,
regular-input propagation, every option layout, indexed, union, record and out-of-order `ListArray`,
string parameters, axis 0 / 1 / 2 and negative axes, AxisError and ValueError paths, structural
soundness (validity, packing, buffer round-trip), reduction and re-windowing of the result, eight
typetracer form checks, four typetracer touch-report checks proving the values are never looked at, at the
outermost and at a nested axis, length-zero arrays for both operations, explicit behavior and attrs
overrides for both operations, non-integer arguments of every kind (float, string, None, bool) and numpy integer
scalars, out-of-range axes for both operations, every rejected choice value, malformed inverse input through a
union branch and a mask, named axes positional against by-name with the negative variants, third-party dispatch through
`__awkward_function__`, and the full inverse surface including the round-trip law.

## 10. Oracle

An independent model written from the prose contract alone (`/tmp/oracle.py`, not shipped) agrees
with the implementation on 3205 random ragged inputs across all six mode/alignment combinations, on
a regular-input battery, on a structural-validity battery, and on a typetracer-form battery.

## 11. Trap matrix (mutation-proven)

| # | Trap | Why missed | Test that catches it |
| --- | --- | --- | --- |
| 1 | right alignment anchors the grid at the END | the left formula looks symmetric | right_aligned_keep_cuts_the_first_windows_off |
| 2 | right aligned padding goes at the FRONT | padding code is written once, for the tail | right_aligned_pad_fills_the_front |
| 3 | `"keep"` counts every window holding an element | the drop count is the natural one | keep_cuts_windows_off_at_the_end_of_the_list |
| 4 | `"drop"`/`"pad"` results are FIXED-size lists | offsets are the reflex for any new dimension | dropped_windows_are_fixed_size_lists |
| 5 | a regular input keeps a regular window dimension | the generic path returns offsets | fixed_size_lists_give_a_fixed_size_window_dimension |
| 6 | list parameters move INWARD to the windows | parameters are copied where the node is built | the_window_dimension_carries_no_parameters |
| 7 | missing lists must be carried, not projected | `project()` is what indexed nodes do | a_missing_list_stays_missing |
| 8 | `ListArray` starts may be out of order | the content looks flat already | lists_whose_starts_are_out_of_order |
| 9 | typetracer needs its own branch | the arithmetic reads lengths | typetracer_*_matches_the_concrete_form (8 tests) |
| 10 | the inverse must skip what the previous window reached | concatenating the windows is the reflex | unwindows_lays_overlapping_windows_over_one_another |
| 11 | the overlap restarts at every list | the running window index is global | unwindows_recovers_the_lists_it_was_given |
| 12 | the inverse gives the WINDOW parameters to the rebuilt lists | the outer node is the one being replaced | unwindows_gives_the_windows_parameters_to_the_lists |
| 13 | the inverse must place window `j` at `j * stride`, never infer geometry from the window lengths | a shorter first window looks right aligned | a_later_window_longer_than_the_first_contributes_all_it_reaches (+4) |
| 14 | reach is measured against the window just before, and nothing a window contributed is dropped later | deriving the total length from the last window agrees on every monotonic input | reach_is_measured_against_the_window_just_before (+2) |

19 mutations run, 18 killed, 1 retired as arithmetically equivalent
(`maximum((n - size) // stride + 1, 0)` equals the guarded count for every `stride >= 1`).

## 12. Tier + category

Olympus, **feature_request**. Both capabilities are net-new public surface; nothing existing changes
behaviour until one of them is called.

## 13. Predicted pass rate

10-30%. The geometry is easy to state and hard to get right in six combinations at once; the layout
recursion, the two type-level rules and the parameter rule are integration work that no single
insight discharges; a `to_list`-and-rebuild shortcut passes the value tests and dies on all eight
typetracer checks, because `ak.to_list` of a typetracer array raises.

## 14. Quality gate

- [x] Repo understanding: read the Content protocol, `_local_index` on all thirteen classes,
      `_slicing`/`_broadcasting` nplike idiom, the operation wrapper and named-axis convention
- [x] Existing PR/issue/branch check: zero hits for window, rolling, sliding, stride-as-window,
      moving average, consecutive, adjacent, overlapping, pairwise, n-grams. (`cumsum`/`cumprod`
      were rejected as a candidate on the same repo: PR #1786 and issue #2676 already own them.)
- [x] Vanilla suite green offline on the base image before authoring (4608 passed / 176 skipped, 53s)
- [x] human-effective 566 >= 430 across 20 files
- [x] 223 tests, all fail on base, all pass with the solution, base suite unchanged in both apply
      orders
- [x] Deterministic: base and new mode each run five times with identical results
- [x] Independent oracle agrees over 3205 random cases plus three targeted batteries
- [x] 19 mutations, 18 killed, 1 equivalent retired
- [x] False-positive mapping: every meta.md clause has a named test (see feedback.md)
