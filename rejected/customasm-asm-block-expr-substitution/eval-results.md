# eval-results.md — customasm-asm-block-expr-substitution

No agent runs yet. Design phase; artifacts not built.

## Per-run table (fill after every batch)

| Batch | Run | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed test names | Failure reason | Approach note (architecture chosen) |
|---|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — | — | — |

## Capture protocol (HARDENING 3e — run while the platform run view is open)

1. Fill the row above for every run, including failed test NAMES and the one-line approach note.
   The approach note is what detects an architecture-jump without the diff.
2. Save every PASSING agent's solution diff to `agent-runs/<batch>-<run>.patch`, plus the 1-2
   most instructive failers. The differential harness, trap-proof, FP verification and
   leanest-passer LOC all require the actual patches and the run view is the only source.

## Watch items for batch 1

- **Trap 1 collapse.** Does any passer generalize `resolve_once`'s per-iteration label rebinding
  to substitutions without prompting? If most do, trap 1 is oracle-absorbed and the design leans
  on traps 2 and 3 only. Read the passing patches, not the rate.
- **Trap 2 detection point.** Do failers break `tests/expr_asm/ok_subrule_morph.asm` and only
  discover it by running the base suite? If every agent catches it, trap 2 is a thoroughness gate
  rather than a wall.
- **Trap 3 symptom.** Confirm failures surface as wrong bytes or spurious non-convergence, not as
  a self-revealing error naming the guess.
- **Solver median message count** must be >= 40 (sprint long-horizon floor).

## FP check (MANDATORY final gate, before submit)

For every passing agent, confirm it actually met all four description requirements rather than
merely passing tests. Specifically verify each passer:

1. preserves token splicing for single-name subruledef arguments (not just for the fixtures);
2. evaluates brace expressions in the enclosing rule's scope;
3. resolves labels declared later in the same block;
4. reports non-convergence instead of emitting a guessed value.

An FP flag means the tests and the description have diverged; fix by aligning them (strengthen
the missing discriminator or repair the ambiguous sentence), then re-run. Do not fix by patching
the agent's interpretation.

## Self-review outcome (olympus-review, no agent batch run)

Stage 0 precheck: GREEN. No em-dashes, meta.md ASCII, no banned markers, test.sh mode 100755,
patches ASCII, solution.patch touches src only, test.patch touches no src.

Stage 1 Pattern 22: GREEN. Canonical org confirmed, 44 PRs all states, no PR or issue implements
brace-expression substitution, no maintainer decline for the feature class (issue #52 shows the
maintainer engaging positively with macro-class capability). Check 6 existing-capability: base
binary rejects `{addr >> 8}` with "expected `}`", so the feature is genuinely absent.

Stage 4 description: PASS with one note. Word count 285 against the <=200 recommendation (hard cap
500). The overage is load-bearing: every sentence maps to a tested behavior.

Stage 5 tests: PASS after one fix. A6 alignment initially had a described-but-untested behavior
("an expression that produces something other than an integer is reported with the type it
produced"). Added `err_non_integer_value` to close it. 32 fixtures, 29 fail on base. The 3 that
pass on base are error-preservation guards (`err_empty_braces`, `err_trailing_tokens`,
`err_unknown_name`) which by design must behave identically before and after.

Stage 6 solution: PASS on quality, FAIL on floor. Zero compiler warnings (no dead code, A2 clean),
no scope creep (A10 clean, single file, no drive-by refactors), zero comments in added code
matching repo convention. Effective LOC 167 vs 200 floor and 1 file vs 2 floor.

Verdict: REQUEST CHANGE (not rejectable on quality; blocked on the long-horizon floor).
