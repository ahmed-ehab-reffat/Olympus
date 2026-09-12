# eval-results.md — lol-html-sibling-combinators

No agent batch has been run yet.

## Local validation (clean-room worktree at BASE_COMMIT)

| Step | Command | Result |
|---|---|---|
| base, test.patch only | `./test.sh --output_path ... base` | exit 0, 185 cases, 0 failures |
| new, test.patch only | `./test.sh --output_path ... new` | exit 101, 66 cases, 66 failures (`UnsupportedCombinator('+')`) |
| new, + solution.patch, 3x | `./test.sh ... new` | exit 0, 66/66, identical 3x |
| base, + solution.patch, 3x | `./test.sh ... base` | exit 0, 185/185, identical 3x |
| reverse apply order | solution then test | both modes green |
| unapply both | `git apply -R` | clean tree |
| container, offline, non-root | `--network none --user 1000:1000` | base 185/0, new 66/0 |
| build-failure fallback | compile error injected | 66 synthetic `<testcase classname="">` failures, names match f2p set |
| flakiness gate (post-review) | 5x base + 5x new | identical every run: new 66/0, base 185/0 |
| patches on pristine base (post-review) | apply both orders, unapply both | clean, `git status` empty |
| compiler warnings | `cargo build --all-targets --features=_integration_test` | 0 |

## Trap reproduction (mutation harness)

| Mutation | Kills in new suite | Sole detectors | Breaks existing conformance fixtures |
|---|---|---|---|
| M1 arm onto own scope, not parent's | 3 | no | yes (2/3 suites) |
| M2 arm gated on `with_content` | 5 | **yes** (void-element tests) | no |
| M3 adjacent arms not spent by a non-match | 13 | no | yes (2/3 suites) |
| M4 arm only on the fast path | 36 | no | no |
| M5 no sibling resume after attribute bailout | 29 | no | no |
| M6 negation distributed over alternatives | 3 | **yes** (negated-`:is()` tests) | no |
| M7 `:is()` not treated as needing attributes | 14 | no | no |
| M8 no root sibling scope | 33 | no | no |

Reference is green under all suites before and after every mutation is reverted.

## Artifact metrics

| Metric | Value | Floor |
|---|---|---|
| human-effective LOC (Counter 2) | 292 | 200 |
| counter1 (platform auto-block) | 351 | - |
| raw added | 415 | - |
| files changed | 9 | 2 |
| new tests | 66 | - |
| meta.md words | 345 | cap 500 |
