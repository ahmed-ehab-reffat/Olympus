# pianoplayer-performed-order-timeline - eval results

No platform batch yet (slice awaiting the precheck).

## Local validation (2026-10-06, SLICE)

Image `factory-pianoplayer-performed-order-timeline`, cold `--no-cache` build 29 s. Fresh clone at
BASE + test.patch, `--network none`. Solution applied inside a container from the same image.

| user | solution | base mode | new mode |
|---|---|---|---|
| 1000:1000 | no | 46/46 pass, exit 0 | 13/13 fail, exit 1 |
| 1000:1000 | yes | 46/46 pass, exit 0 | 13/13 pass, exit 0 |
| 0:0 | no | 46/46 pass, exit 0 | 13/13 fail, exit 1 |
| 0:0 | yes | 46/46 pass, exit 0 | 13/13 pass, exit 0 |
| 4242:4242 (no passwd entry) | no | 46/46 pass, exit 0 | 13/13 fail, exit 1 |
| 4242:4242 (no passwd entry) | yes | 46/46 pass, exit 0 | 13/13 pass, exit 0 |

New-mode failures without the solution are all feature-missing: 11x `reader() got an unexpected
keyword argument 'unfold_repeats'`, 1x the same for `run_annotate`, 1x argparse SystemExit 2 on
`--unfold-repeats`. New mode with the solution, 3 runs in one container: identical testcase ids
(md5 of names equal), 0 failures each.

Also built from a `git archive` context (no `.git`) with test.patch applied by `patch -p1`: builds,
new mode 13 testcases, exit 1.

Repo baseline flakiness at pick time: 3 local runs of the 46-test suite, identical (46 passed).

LOC: `effective_loc_check.py solution.patch` -> human-effective 207, raw 225, padding-floor 156,
6 files.

Mutation spot checks (new tests, reference with one change reverted):
- `Hand.generate` window back to `break`: kills `test_hand_window_fingers_every_pass`.
- annotator back to the index walk: kills `test_annotate_writes_first_pass_fingering`.
- tempo reset to 120 when a pass restarts at measure 1: kills `test_tempo_mark_applies_where_it_is_played`.
- hunter sketch's pass-counter reset: kills `test_first_and_second_endings`.
