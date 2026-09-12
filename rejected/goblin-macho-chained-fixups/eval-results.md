# eval-results.md — goblin-macho-chained-fixups

No platform evaluation runs yet — this session has no Nova/Orion/Vega/Castor access. The table
below is scaffolding for the first real batch.

| Agent | Evaluator | Verdict | Msg count | Files touched | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| (none run yet) | | | | | | | | |

## Local reference-solution results (not a platform run — see feedback.md)

The reference solution (this submission's own `solution.patch`) was validated locally, not through
the platform:

- `test.sh --output_path ... base` (solution applied): 0 failures, 180 test cases across
  `--lib` + `archive`/`compare_dyldinfos`/`elf`/`macho`/`pe`/`te`.
- `test.sh --output_path ... new` (solution applied): 0 failures, 17/17 test cases.
- `test.sh --output_path ... new` (test.patch only, base source): 15/17 fail (the intended F2P
  set), 2/17 pass by design (see feedback.md).
- 5x determinism check on both modes: identical every run.
- 3 targeted mutations (feature-stub, rebase/bind-discrimination flip, merge-vs-replace flip): each
  caught by exactly the test(s) designed for it, confirmed via raw `cargo test -- --format json`
  output (see feedback.md's `cargo2junit` caveat for why the raw stream was used as ground truth
  for the merge-vs-replace mutation specifically).
