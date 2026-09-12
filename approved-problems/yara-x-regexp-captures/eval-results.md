# eval-results.md — yara-x-regexp-captures

## Batch 1 (Nova, 10 runs) — 9 of 10 passed, then hardened against the actual patches

The raw batch was 90 percent, far above the 40 percent cap. The run artifacts include every
solution patch, so the fix was driven by a differential harness over the real patches rather than
by guesswork.

### What the passers actually built

| Architecture | Runs | Note |
| --- | --- | --- |
| Real Pike VM capture slots | 2, 3, 4, 5, 8, 9, 10 | the intended implementation |
| Second regex engine, no VM change | 1, 6, 7 | pulls in `regex_automata`, re-matches the span |

Four runs never touched `lib/src/re/thompson/pikevm.rs`. They let the existing VM find the match
range, then ran an independent `regex_automata` engine anchored at the match start to recover the
group spans. That is the ARCHITECTURE-JUMP the playbook warns about: one alternative architecture
immunises an entire trap family, and every trap in the design lived in the VM.

### Divergences found by the harness

Each probe was run against all nine passing patches and compared with the reference.

| Family | Probe | Kills |
| --- | --- | --- |
| Look-around plus `wide` | `/\B(abc)/ wide` over wide `zabc` | 1, 6, 7 |
| Zero-width group at the atom boundary | `/(\|b)needle/` over `needle` | 1, 6, 10 |
| Group index in a `for .. of them` loop | `@[1][1]` in the loop form | 5 |

The look-around family works because the shortcut architecture rebuilds a de-interleaved buffer
that starts at the match, so an assertion at the match start loses the preceding byte that the
real VM sees through its `left` slice. The zero-width family catches capture positions recorded at
a boundary the backward run has to reach. The loop form exercises `PatternOffsetVar`, a separate
IR path from the named-pattern accessor.

### Result

Twenty tests covering those three families were added, all compositions of already-documented
rules, so `meta.md` needed no new sentence. Re-running the full suite against every passing patch:

| Run | Result |
| --- | --- |
| Nova 1 | FAIL, 9 tests |
| Nova 5 | FAIL, 4 tests |
| Nova 6 | FAIL, 7 tests |
| Nova 7 | FAIL, 4 tests |
| Nova 10 | FAIL, 8 tests |
| Nova 2, 3, 4, 9 | still pass |

Measured pass rate against this batch drops from 90 percent to **40 percent**, at the cap. Runs 2,
3, 4 and 9 implemented the feature correctly and survive 55 further probes covering compositions
of assertions, `wide`, `nocase`, `fullword`, anchors, bounded jumps, nested groups spanning the
atom, serialization round-trips, scanner reuse, block scanning and cross-rule pattern dedup.

### Original diagnosis, still true for the surviving four

Every Nova run solved it. That is far above the 40 percent cap, so the pick fails on difficulty
and the artifact cannot be submitted as it stands.

| Batch | Agent | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | Nova x N | all PASS | rate at or near 100 percent, cap is 40 |

Root cause, and it is a pick-level problem rather than a test-level one:

1. **The repo links to the recipe.** `lib/src/re/thompson/mod.rs`, the module the feature extends,
   cites Russ Cox's "Regular Expression Matching: the Virtual Machine Approach". That article is
   the canonical description of how to add capture slots to a Pike VM, which is the core of this
   feature. The implementation path is handed to the solver by the repo's own documentation.
2. **The capability is recallable.** Capture groups, their numbering, leftmost-first alternation
   and last-iteration repetition are standard across every mainstream regexp engine. Nothing here
   has to be derived.
3. **Every trap is self-revealing.** A mirrored backward span, an undoubled wide position or a
   fast-path shortcut all surface as a wrong number in the solver's own smoke test, so each is
   found and fixed on the first iteration. None of them satisfies CONTRACT-STATED/FIX-HIDDEN in
   practice, whatever the design predicted.

Test-only hardening cannot fix this. The suite already pins every rule with 132 tests, and Test
Fairness confirmed each maps to a sentence of the description, so Rule-7 de-enumeration is not
available either: removing a stated rule would make the tests that pin it unfair. The description
is at its fairness floor.



## Base-suite health (environment gate, base commit `be2a325`)

`cargo test -p yara-x --lib` on a clean clone: **326 passed / 0 failed / 0 ignored in 13.09s**.
The vanilla repo also builds and runs its suite inside `olympus-base-rust` offline as uid 1000,
which is what the Environment Quality gate checks: `./test.sh base` reports 368 cases and 0
failures on the unpatched tree.

## Reference-implementation health

`cargo test --workspace` on the patched tree: every result group ok, 0 failures. The base
`yara-x` lib suite stays at 326 passed / 0 failed after 19 bytecode goldens and 12 IR goldenfiles
were regenerated to follow the new VM instruction and the new IR field.

## Validation matrix

Run inside the image, `--network none`, `--user 1000:1000`, in the order the platform uses: the
image is built from the vanilla repo and the patches are applied at run time.

| Cell | Command | Expected | Result |
| --- | --- | --- | --- |
| base state, base tests | `./test.sh base` | PASS | **PASS** — 368 cases, 0 failures, exit 0 |
| base state, new tests | `./test.sh new` | FAIL | **FAIL** — 132 cases, 132 failures, exit 101 |
| solution state, base tests | `./test.sh base` | PASS | **PASS** — 368 cases, 0 failures, exit 0 |
| solution state, new tests | `./test.sh new` | PASS | **PASS** — 132 cases, 0 failures, exit 0 |

Re-validated after every round. Rounds 4, 6, 7 and 8 took the suite to 132 tests and all four cells stayed
green, with every new test still failing on base.

Every one of the 183 new tests fails on base, so there is no test that passes before the solution.
Seven of them passed on base in the first draft (six baseline-preservation tests that never used
the new syntax, plus one error test whose assertion matched the base syntax error); all seven were
rewritten to assert the new surface.

Both patches apply in either order and both reverse-apply cleanly, leaving the tree at the base
commit with an empty `git status`.

## Flakiness

Five consecutive runs of each mode on the patched tree:

| Mode | Cases | Failures per run |
| --- | --- | --- |
| new | 183, 183, 183 | 0, 0, 0 |
| base | 368, 368, 368, 368, 368 | 0, 0, 0, 0, 0 (five runs; new mode re-run three times at 107) |

Identical every run. The tests carry no timing, randomness, ordering, network or filesystem-time
dependence; `test.sh` also runs cargo with `--test-threads=1`.

## Mutation proof

Seven defects were injected into the reference one at a time, each reverted before the next. Every
one is killed by at least one test.

| Mutation | Tests killed |
| --- | --- |
| M6 backward code emits the save instructions in forward order | 65 |
| M7 group numbering off by one | 64 |
| M5 exact atoms kept, so the regexp engine never runs | 40 |
| M4 `LiteralWithMask` shortcut restored for patterns with groups | 34 |
| M1 positions recorded by the backward run ignored | 7 |
| M2 `wide` positions not doubled | 3 |
| M3 thread dedup keeps the last arrival instead of the first | 1 |

A second battery covering the round-4 additions:

| Mutation | Tests killed |
| --- | --- |
| M9 a group that took no part reports offset 0 instead of undefined | 15 |
| M8 a group that took no part reports length 0 instead of undefined | 11 |
| M10 a group name resolves to the first group whatever the name | 3 |
| M11 the grammar accepts a third index | 2 |

A third battery for the round-6 additions:

| Mutation | Tests killed |
| --- | --- |
| M12 wide doubling applied to every match, not only wide ones | 59 |
| M13 an out-of-range group number clamps instead of being undefined | 7 |

Round 7 added a fourth battery and re-measured the weakest trap:

| Mutation | Tests killed |
| --- | --- |
| M14 thread slots shared instead of copied on split | 126 |
| M3 dedup keeps the last arrival, re-measured after round 7 | 4 (was 1) |

Round 8 re-measured two more:

| Mutation | Tests killed |
| --- | --- |
| M13 an out-of-range group number clamps, re-measured after round 8 | 9 (was 7) |
| M15 a name resolved against the rule's first pattern instead of its own | 2 |

M8 is the one that mattered: before round 4 the undefined cases were asserted almost entirely on
`@a[i][g]`, so an implementation that returned 0 from `!a[i][g]` for a group that took no part
would have passed. That was a live false-positive hole, not just missing coverage.

M3 was the thinnest at a single kill until round 7. The dedup order only shows up when two
alternatives reach the same instruction at the same position, which no fixture forced; three
tests built on `/(a)|a/`, `/(a)|(a)/` and `/(a)b|(ab)/` now force exactly that, taking M3 to 4
kills. The backtracking tests added in the same round do not touch dedup order, because an
abandoned thread simply dies rather than racing the winner to an instruction: they are killed by
M14 instead, which is the per-thread slot isolation they actually verify.
After the battery both patches still reverse-apply cleanly, confirming no mutant was left behind.

## Per-agent results

| Batch | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — | — | — | — | — |

Passing-agent diffs will be saved under `agent-runs/<batch>-<run>.patch` at batch time, per
`HARDENING.md` section 3e.
