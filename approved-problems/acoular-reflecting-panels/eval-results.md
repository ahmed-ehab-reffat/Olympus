# eval-results.md — acoular-reflecting-panels

Repo: `acoular/acoular` @ `b5a20cdbff51bb0ec7b281fc9b02192ad1516b0b`
Tier: Olympus · Shape: O-Algorithm-correctness (composite span) · Category: feature-request

## Local validation matrix

All runs `docker run --network none --user 1000:1000`, no `HOME` override, on a worktree freshly
checked out at the base commit.

| State | Command | Exit | Result |
| --- | --- | --- | --- |
| base + test.patch | `./test.sh base` | 0 | 1291 passed, 141 skipped, 120 xfailed, 3 xpassed (identical to the vanilla suite) |
| base + test.patch | `./test.sh new` | 1 | **265 failed**, 265 `<testcase>` nodes in the JUnit XML |
| + solution.patch | `./test.sh base` | 0 | 1291 passed, 141 skipped, 120 xfailed, 3 xpassed, 8 deselected, no regressions |
| + solution.patch | `./test.sh new` | 0 | 273 passed |

Base mode returns the identical 1291 in both states.

**Set partition, checked by collection diff rather than by eye.** Collecting `tests/` whole gives
1828 node ids; base mode selects 1555, new mode selects 273; 1555 + 273 = 1828 with an empty
intersection. Nothing the repo collects falls outside the two sets and nothing is in both. The 8
tests new mode owns beyond the 265 authored ones are the ones the repo generates for any new class
(`test_classes.py` `test_instancing` / `test_set_traits` / `test_trait_dependencies` and
`test_pickle.py` `test_load`, two each for `ReflectingPlane` and `ReflectiveEnvironment`), routed by
the `-k` filters in `test.sh`.

Patch hygiene: both patches apply on a clean base in either order, and both unapply with
`git apply -R` leaving `git status` empty, on the native tree and on an LF-normalising checkout.
acoular stores **mixed** line endings, so the patches are generated from byte output rather than
text output, and the solution deliberately touches only the LF-stored files (see feedback.md).
`test.patch` carries exactly two files: `test.sh` at mode 100755 and the hash-suffixed test module.
No test file name contains a banned marker or a predictable path.

**The two `pytest-regtest` baselines were removed.** They were shipped to stop an agent that exports
the classes from hitting a "snapshot not recorded" failure it cannot legitimately fix - two agents in
batch 16 suppressed that test and were graded PASS_CHEATED. The naming check flagged their paths as
predictable, and they cannot be randomised because `pytest-regtest` derives the path from the test
node id. Removing them is free for both modes (nothing either selects consumes them, verified), and
the cheat trigger is now removed at source by a description sentence saying the classes need not be
added to the package's top-level exports.

Dockerfile: builds from the base image in 46 s and runs the suite offline as uid 1000.

## Solution size

| File | raw | human-effective |
| --- | --- | --- |
| `acoular/environments.py` | 664 | 241 |
| `acoular/sources.py` | 96 | 78 |
| `acoular/tfastfuncs.py` | 55 | 31 |
| `acoular/fbeamform.py` | 22 | 20 |
| `acoular/tbeamform.py` | 20 | 20 |
| **total** | **900** | **438** |

Five files, 438 human-effective, against the 2026-07 sprint floor of >=250 effective and >=2 files.
(The repo hook still warns at its pre-sprint 430 threshold; that number is superseded.)

New tests: 265 in `tests/unittests/test_reflection_paths_955a39.py`.

## Oracle cross-check

Independent Fermat-principle minimisation over reflection points constrained to the panels,
300 random two panel geometries at second order.

| Metric | Value |
| --- | --- |
| Path checks | 702 |
| Paths with a realizable specular point | 44 |
| Mismatches (length, points, validity) | **0** |

## Determinism

Three consecutive runs of each mode on the solution state, same container, no reordering plugin,
no RNG without a fixed seed, no timing or network dependence.

| Run | base | new |
| --- | --- | --- |
| 1 | 1291 passed, 141 skipped, 120 xfailed, 3 xpassed, 8 deselected | 273 passed |
| 2 | 1291 passed, 141 skipped, 120 xfailed, 3 xpassed, 8 deselected | 273 passed |
| 3 | 1291 passed, 141 skipped, 120 xfailed, 3 xpassed, 8 deselected | 273 passed |

Identical every run; no test flips.

## Agent runs

### Batch 1 (Nova x4, 2026-08-07) — VOID as a difficulty measurement

| Agent | Verdict | Base | New failed | of which `path_sequences` | Residual | Evaluator call |
| --- | --- | --- | --- | --- | --- | --- |
| Nova_Nova_1 | FAIL_REGRESSION | FAIL (8) | 32 | 14 | 18 | challenging, clear |
| Nova_Nova_2 | FAIL_TEST_MISMATCH | pass | 18 | 14 | 4 | **unfair, not clear** |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | pass | 20 | 14 | 6 | challenging, clear |
| Nova_Nova_4 | FAIL_INTEGRATION_ERROR | pass | 20 | 14 | 6 | challenging, clear |

0 of 4, but the batch cannot be read as a pass rate: **all four agents implemented `path_sequences`
as a traits `Property` returning a list**, so 14 tests in every run died on
`TypeError: 'list' object is not callable`. Nova_Nova_2's evaluator flagged it directly
(`was_mentioned_in_description: false`, `was_inferable_from_codebase_excluding_tests: false`,
difficulty "unfair"). The description said "`path_sequences` lists the sequences sound may follow"
while every other API in it carries parentheses, and acoular is traits-heavy, so a property is the
idiomatic guess. Now written `path_sequences()` in all three places.

Two further pins the runs exposed as unfair, both relaxed:

- `test_transfer_matches_the_plain_environment_without_panels` compared two environments at
  `rtol=1e-12`. Nova_Nova_3 missed by **1.9e-7**, which is exactly acoular's own
  `_transferCoreFunc` casting its phase argument to `float32`. Demanding bit equality forced an
  implementation to reuse that quirk rather than compute the transfer correctly. Four transfer
  comparisons moved to `rtol=1e-6`, which still separates every behaviour they guard.
- `test_moving_source_echo_appears_only_while_the_panel_is_hit` treated anything above `1e-12` as
  echo, but the quantity is the difference of two independent simulations and carries float dust at
  `1e-11`.

Three further changes came out of the batch, listed with what each cost:

- **Moving sources dropped from scope.** All four runs produced no reflected moving-source signal at
  all (residual ~1e-11), so the surface was being skimmed rather than attempted. Rather than hint
  around it, `MovingPointSource` is out of the description, the `MovingPointSource.result` change is
  reverted, and its 13 tests are gone. Cost: 38 effective LOC.
- **`test_plain_image_rejects_a_negative_panel_index` removed.** A plain `Environment` has no panels,
  so the index rule the description states for `ReflectiveEnvironment` was being read onto a class
  the description does not discuss.
- **Two `digest` round-trip assertions removed.** See the fairness note below.

### Replay measurement (solvability)

The batch above cannot answer solvability because one shared, now-fixed wording bug dominated every
run. So each agent's `solution-patch.patch` was replayed on a clean base worktree with a mechanical
rewrite turning its `path_sequences` Property into a method, which is what the corrected description
now asks for, and then run against the final test suite.

| Agent | new mode | base mode | Outcome |
| --- | --- | --- | --- |
| Nova_Nova_2 | **232 passed, exit 0** | **1291 passed, exit 0** | **PASS** |
| Nova_Nova_3 | 2 failed, 230 passed | — | fail |
| Nova_Nova_4 | 5 failed, 227 passed | — | fail |
| Nova_Nova_1 | 10 failed, 222 passed | — | fail |

**Solvability is demonstrated: 1 of 4, 25%, inside the <=40% cap**, with the next two agents two and
five tests short. Nova_Nova_3's residual is its own beamformer crash plus the negative panel index;
Nova_Nova_4's is three autopower tests, one sequence test and the dipole mask; Nova_Nova_1 never got
occlusion or the impulse response working.

Re-measured after the dipole masking test was added. It moved Nova_Nova_4 from four failures to five
and left the other three unchanged, which is independent confirmation that it discriminates on real
implementations and not only against a hand-written mutation.

This is a replay, not a fresh batch: it holds each agent's code fixed and only removes the wording
bug. It is strong evidence and it is what the next real batch has to confirm.

The one fairness item the replay surfaced: Nova_Nova_2's **only** failure was
`assert restored.digest == env.digest` after a pickle round trip. The description says a digest
"changes with their traits", which is a sensitivity claim, not a promise of stability across
processes, and acoular's own `MergeGrid` builds its digest from member object addresses and so
fails the same assertion. The repo convention pointed the opposite way from the test, so both
cross-process digest assertions were removed. The reference still keeps an address-free digest; the
trait, sequence and `paths` round-trip assertions all stay.

### False positives

**None possible this round.** No agent passed the batch as run, so there is no passing
implementation to re-check against the requirements. Nova_Nova_2's replay pass is a controlled
rerun of its own code, not an agent run, and it was inspected by hand: it enumerates sequences,
mirrors in encounter order, walks reflection points backwards, tests occlusion against strict
interior crossings, and applies per-panel factors, so it meets the requirements rather than merely
matching the assertions. The FP gate is still formally owed on the next real batch.

## Batch 2 (Nova x5, 2026-08-07) — solvable, measured on a real batch

| Agent | Verdict | Base | New failed | Residual cause |
| --- | --- | --- | --- | --- |
| Nova_Nova_4 | FAIL_TEST_MISMATCH | pass | 1 | **author-side**: `rtol=1e-12` on a plain-vs-reflective transfer comparison |
| Nova_Nova_1 | FAIL_MISSED_REQUIREMENT | pass | 1 | negative `max_order` accepted (traits init path) |
| Nova_Nova_5 | FAIL_MISSED_REQUIREMENT | pass | 2 | `IndexError` on a blocked direct path + the transfer tolerance |
| Nova_Nova_2 | FAIL_MISSED_REQUIREMENT | pass | 13 | `out[b, m] +=` outside the path/microphone loops |
| Nova_Nova_3 | FAIL_MISSED_REQUIREMENT | pass | 28 | each output block restarts from the first sample index |

Nova_Nova_4's evaluator flagged the author-side failure directly: `agent_blame_unfair: true`,
`blocker_type: verifier`, difficulty "unfair". The tolerance was a regression of the round-31 float32
lesson; the fix and its justification are in feedback.md. All five baselines passed.

### Replay after the tolerance fix

| Agent | new mode | base mode | Outcome |
| --- | --- | --- | --- |
| Nova_Nova_4 | **232 passed, exit 0** | **1291 passed, exit 0** | **PASS** |
| Nova_Nova_1 | 1 failed, 231 passed | - | fail |
| Nova_Nova_5 | 1 failed, 231 passed | - | fail |
| Nova_Nova_2 | 12 failed, 220 passed | - | fail |
| Nova_Nova_3 | 28 failed, 204 passed | - | fail |

**1 of 5, 20%, inside the <=40% cap**, on a real batch rather than batch 1's rewrite-assisted replay.

## FP check — CLEAN

Run on Nova_Nova_4, the only passer.

| Check | Result |
| --- | --- |
| Hidden tests modified | none; one line added to `tests/cases/test_environments_cases.py` skip list, a consequence of exporting the class so the repo regtest wants an impossible snapshot |
| Hardcoded expected values / fixture constants | none in the diff |
| Algorithm present | lexicographic `product` + adjacency filter, encounter-order mirroring, backward walk with prefix-image recomputation, `crossed & contains` occlusion, `|dot|/|v|` incidence |
| Differential vs reference, 40 random off-axis geometries | distance 0/1044 differ, amplitude 0/1044, reflection points 0/3420, incidence 0/1140 |
| Validity | 9/1044 differ, all one direction (passer over-blocks), all first-order |

The validity gap is a floating-point robustness difference, not a missed requirement: the passer's
`crossing` uses an exact sign test, so a reflection point sitting on its own panel at a signed
distance of ~1e-17 self-blocks, where the reference allows `_REFLECTION_TOL = 1e-9`. Every panel in
the suite is axis-aligned with round coordinates, so that signed distance is exactly zero and the
fragility is invisible - an author blind spot in fixture design. No test is added for it: the
description specifies no tolerance, so a discriminating test would pin unstated numerical policy and
would take the batch to 0 of 5. No existing test depends on the tolerance either.

## Solvability of the hardened version, established by graft

The moving-source requirement was added after batch 3, so no agent run has ever seen it and no batch
measures it. Solvability was established directly instead.

Each batch-3 implementation was taken as-is and given ONE addition: a 50-line rewrite of
`MovingPointSource.result` that loops over `path_sequences()`, solves the emission time against the
image of the trajectory, and weights each path by `paths_at`. It uses only APIs the description
specifies, at the `(3, N)` shapes the description states, and touches nothing else in their code.

| Agent | before the graft | after the same 50-line graft |
| --- | --- | --- |
| Nova_Nova_1 | 10 failed | **271 passed** |
| Nova_Nova_2 | 10 failed | **271 passed** |
| Nova_Nova_3 | 10 failed | **271 passed** |
| Nova_Nova_4 | 10 failed | **271 passed** |

Base mode on a grafted tree: 1291 passed, no regressions.

The requirement is therefore additive, portable across four independently written implementations,
and reachable from the documented API alone - while still costing every one of those agents 5 tests
when absent. A first attempt written against a single implementation's broadcasting did NOT port
(8 and 6 failures on two other trees); only the version that respects the documented `(3, N)` shapes
works everywhere, which is a fair distinction because the description states those shapes per method.

This is strong evidence, not a batch. A fresh run is still the measurement of record.

## Solvability, verified on the CURRENT artifacts

Not projected and not a graft: `Orion_Nova_1`'s own patch from batch 34, replayed against the
artifacts exactly as they now stand, after the onset-threshold fix and the added exclusion sentence.

| mode | result | exit |
| --- | --- | --- |
| `./test.sh new` | **267 passed** | 0 |
| `./test.sh base` | **1291 passed**, 141 skipped, 120 xfailed, 3 xpassed | 0 |

Batch 34 stands at **1 of 13, 7.7 percent**, with three further agents one test short. That batch ran
the current tests, confirmed two ways: no traceback contains the retired `max_order=0` form, and
Nova_Nova_1's moving-source failures are 0.63 and 1.10 rather than the 9.32e-11 noise seen in batch
33, so both of the previous round's tolerance fixes took effect.

## Mutation proof

Each defect implemented in the reference on its own and reverted; the baseline suite is clean at
219 passed. Re-measured against the final suite.

| Mutation | Tests killed |
| --- | --- |
| crossing uses a closed interval | 53 |
| consecutive panel repeats kept in the enumeration | 13 |
| no occlusion test | 9 |
| spreading loss taken from the direct distance | 6 |
| impulse response rounds the delay | 4 |
| autopower accumulated per path instead of per microphone | 3 |
| mirror chain applied in reverse order | 2 |
| `image_velocity` mirrors like a position | 2 |
| amplitude zeroed for invalid paths | 2 |
| only the last reflection point checked | 1 |
| blocked direct path kept in the transfer | 1 |
| dipole validity mask applied globally instead of per microphone | 1 |
| moving source mirrors its trajectory velocity with `image` instead of `image_velocity` | 1 |
| `conv_amp` applied only to the direct path | 2 |
| moving-source gain applied globally instead of per microphone | 3 |
| moving dipole monopoles not mirrored about the sequence | 1 |
| moving dipole velocity mirrored as a position | 1 |
| moving dipole ignores path validity | 2 |
| moving dipole gain not applied per microphone | 3 |
| moving dipole factor frozen at the path start | 2 |
| receiver side of a pair API not validated | 1 |
| degenerate coplanar path forced to zero amplitude | 3 |
| endpoint touch counted as a crossing in the backward walk | 61 |
| receiving time not advanced between blocks | 3 |
| path amplitude frozen per block instead of per emission position | 1 |
| transfer masks a missing path by multiplication instead of selection | 1 |

No mutation survives.

## Local replay after the FP probes (suite = 271 new tests)

Replays of the two batch-36 agents that passed the previous suite, against the tightened one.

| Probe | Orion_Nova_1 | Orion_Nova_3 |
| --- | --- | --- |
| test_time_beamformer_drops_a_blocked_direct_path_without_reflections | FAIL | pass |
| test_time_beamformer_sq_drops_a_blocked_direct_path_without_reflections | FAIL | pass |
| test_rotated_neighbouring_panel_does_not_block_the_reflection | pass | pass |
| test_contains_rejects_an_off_plane_point_far_from_the_origin | pass | pass |
| test_editing_an_edge_to_be_invalid_is_rejected (de-pinned, see below) | pass | pass |
| test_dipole_masks_the_echo_per_microphone | pass | FAIL |
| totals | 2 failed / 269 passed | 1 failed / 270 passed |

Root cause per agent, both confirmed by direct measurement rather than inference:

- Orion_Nova_1: tbeamform takes the reflection-aware branch only when len(path_sequences()) > 1, so a
  blocked direct path at max_order 0 is still emitted. This is the Nova 1 FP report verbatim.
- Orion_Nova_3: PointSourceDipole yields (1, 512, 2) blocks under a reflective environment against the
  reference (512, 2). Measured side by side in both worktrees.

Verified passers: 0. Both prior passers are false positives. The next batch is the only remaining oracle
for solvability; the mitigation shipped is three contract sentences in meta.md, not a weaker suite.

The edge-mutation probe was unfair in its first form: it asserted rejection on next use, while
Orion_Nova_1 validates eagerly in __setattr__ and raises at the assignment. Rewritten to accept either
timing; it now passes both agents and is still killed by the revalidation mutation.

### Solvability evidence after the FP round

Raw verified passers: 0. Both prior passers carry genuine defects, each local and each fixable in a few
lines:

| Agent | Remaining failures | Defect |
| --- | --- | --- |
| Orion_Nova_1 | 2 | tbeamform guards the reflection branch on len(path_sequences()) > 1, so a blocked direct path at max_order 0 is still emitted |
| Orion_Nova_3 | 1 | apparent_r result kept its (1, num_mics) shape, so center_distance[np.newaxis] broadcast the dipole block to (1, 512, 2) |

Grafting the single line

    center_distance = np.asarray(self.env.apparent_r(loc, mpos)).reshape(-1)

onto Orion_Nova_3 takes it to 271/271. An independent implementation satisfies the whole tightened suite
after one broadcasting fix, so the suite is not over-fitted to the reference. A fresh batch remains the
only real measure of pass rate.

## Batch 43 (11 Nova runs, PRE-FP artifacts) and its replay on the fixed suite

As run, against the 265-test suite (no FP probes present): 3 PASS_LEGITIMATE of 10 scored = 30%, in band.
Nova_Nova_4 produced no eval-result. Failure spread 4/5/8/8/9/31/273, no dominating cluster; the largest was
test_missing_middle_point_propagates_through_a_third_order_path at 5 of 7 failers, and that rule is stated.

Replay of the three passers against the current 271-test suite:

| Agent | Failed | Which |
| --- | --- | --- |
| Nova_Nova_1 | 4 | both max_order 0 beamformer probes, rotated neighbour, contains far from origin |
| Nova_Nova_5 | 4 | same four |
| Nova_Nova_7 | 2 | rotated neighbour, contains far from origin |

0 of 3 survive. The decisive finding is the intersection: BOTH numerical-robustness probes fail on ALL THREE
passers. That is a fully correlated failure and is the single largest risk to solvability.

Root cause is the same habit in each: a magnitude-scaled on-plane tolerance. Nova_Nova_5 writes

    scale = np.maximum(1.0, np.max(np.abs(pos), axis=0))
    on_plane = np.abs(self.signed_distance(pos)) <= 1e-10 * scale

At 1e10 coordinates that tolerance is 1.0, so a point half a unit off the plane reads as on it. Three
independent agents chose it, so it is a natural-looking numerical habit that is wrong here rather than one
agent's slip. It was undocumented when these runs happened and is now stated explicitly.

Two of the four failure modes are already solved somewhere in this batch: Nova_Nova_7 passes both max_order 0
beamformer probes, and Nova_Nova_5 contains the same dipole reshape the reference needs. Nova_Nova_7 is two
tests away, and both of those are now documented.

