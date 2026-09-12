# eval-results — gluon-format-comments

No agent batch has been run yet. Table schema to fill after the first 10-run batch.

| Batch | Run | Agent | Evaluator | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|---|

Passing-agent diffs go to `agent-runs/<batch>-<run>.patch` while the platform run view is open.

## Local validation log
| Check | Result |
|---|---|
| Base suite `cargo test -p gluon_format --test pretty_print` | 52 pass / 0 fail on base |
| Base mode (2 skipped, see test.sh) with solution | 50 pass / 0 fail |
| New tests with solution | 31 pass / 0 fail, identical across runs |
| New tests on base | 31 fail / 0 pass (Verify Solution gate) |
| Counter 2 human-effective | 294 across 4 files |
| Trap-proof M3 (naive own-line classification) | 16 kills |
| Trap-proof M2 (field name span) | 1 kill, the nested cross-product cell |
| Trap-proof M1 (doc comments scanned as ordinary) | 1 kill |

## Batch 1 (2026-08-06) — 0/12, REJECT-level, diagnosed

12 working runs (2 more link-only, no artifacts). Every run compiled and passed baseline; all 12
failed on the new suite. Verdict on all: FAIL_MISSED_REQUIREMENT. No environment failures, no
false positives, no leakage.

| Run | Fails | Failing tests |
|---|---|---|
| Nova 4 | 1 | consecutive_own_line_comments...blank_line |
| Nova 6 | 1 | consecutive_own_line_comments...blank_line |
| Orion 2 | 1 | own_line_comment_before_the_first_alternative_stays_in_the_match |
| Orion 3 | 1 | a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit |
| Nova 5 | 2 | blank_line + first_alternative |
| Nova 1 | 3 | three block-comment cases |
| Nova 10 | 3 | three block-comment cases |
| Nova 7 | 3 | doc_comment_on_record_field, record_base, blank_line |
| Orion 1 | 4 | four record-type cases |
| Nova 11 | 6 | block comments + record base + nesting |
| Nova 8 | 7 | block comments + own-line block + nesting |
| Nova 3 | 15 | broad |

### Kill counts (top)
| Kills | Test |
|---|---|
| 7 | consecutive_own_line_comments_keep_their_order_and_the_blank_line_between_them |
| 6 | a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit |
| 5 | a_block_comment_after_a_record_field_stays_on_its_line |
| 4 | a_block_comment_in_a_nested_match_does_not_escape_the_outer_record |
| 4 | own_line_comment_before_the_first_alternative_stays_in_the_match |
| 3 | comments_around_a_record_base_stay_inside_the_record |

### Reading
Failure diversity is healthy (L4): four distinct near-miss causes across the 1-fail runs, not one
shared tripwire. The problem is HARD in the right way. It is also, at 0/12, unshippable, and two of
the four near-miss causes trace to behaviour meta.md did not state.

## Batch 2 (pending) — projection

Shipping with the blank-line clarification only. Projected **2/12 = 17%**, computed by removing the
clarified test from each batch-1 run's failure set: Nova 4 and Nova 6 clear, everyone else keeps at
least one residual failure. Three runs sit at exactly one residual (Nova 5 and Orion 2 on the first
alternative, Orion 3 on the same-line block comment), so a small upward drift in agent capability
could take this to 5/12. Levers if the batch reads too hard are recorded in feedback.md A13.

## Batch 2 (2026-08-06) — 0 legitimate passes, 1 PASS_CHEATED

14 runs. Verdicts: 1 PASS_CHEATED, 10 FAIL_MISSED_REQUIREMENT, 2 FAIL_REGRESSION,
1 FAIL_EARLY_TERMINATION.

| Run | Fails | Note |
|---|---|---|
| Orion 2 | 0 | **PASS_CHEATED** — rewrote expectations in `format/tests/pretty_print.rs` |
| Nova 2 | 1 | a_doc_comment_on_a_record_field_is_not_repeated |
| Orion 4 | 2 | block-comment-breaks-record + first-alternative |
| Nova 5 | 6 | record-type cluster |
| Nova 7 | 7 | |
| Nova 1 / Orion 1 | 8 | record-type cluster |
| Orion 3 | 10 | |
| Nova 10 | 11 | |
| Nova 8 | 15 | regression |
| Nova 6 | 16 | |
| Nova 9 | 19 | regression |
| Nova 4 | 22 | |
| Nova 3 | 42 | early termination |

### Kill counts (top)
| Kills | Test |
|---|---|
| 10 | a_same_line_block_comment_on_a_record_type_field_stays_on_its_line |
| 10 | a_record_type_nested_in_a_record_type_keeps_both_comments |
| 10 | trailing_comment_on_the_last_record_type_field_stays_on_its_line |
| 8 | a_doc_comment_on_a_record_type_field_is_not_repeated |
| 8 | own_line_comment_before_the_first_alternative_stays_in_the_match |
| 8 | a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit |
| 7 | an_own_line_comment_before_a_later_record_type_field_belongs_to_that_field |
| 7 | own_line_comment_after_the_last_record_type_field_stays_inside |

### Reading
The RECORD-TYPE surface is now the dominant wall: seven tests, each killing 7-10 of 14. That is the
second axis added during hardening working far harder than intended, because the type printer lives
in a different file from the expression printer and agents do not find it.

### Counterfactual for batch 3
| Change | Legit passes |
|---|---|
| as batch 2 shipped (blank line only) | 0/14 |
| + first-item clause | 0/14 |
| + block-comment sentence | 0/14 |
| **+ both reverted clarifications** | **1/14 (Orion 4)** |
| drop the record-type tests entirely | 0/14 |
| tail rule to outer indent | 0/14 |

Only the PAIR converts anyone: Orion 4 needs both. Nova 2 is one failure away on the record-field
doc-comment rule, which meta.md already states explicitly, so it is fair difficulty and no lever
reaches it.

## Batch 3 (pending) — projection

Shipping with three clarifications (blank line, first item, same-line block comment) plus the
doc-comment wording, and 45 tests (3 blank-line surfaces added after batch 2).
Projected **2 of 14 legitimate passes (14%)**, confirmed by differential harness: Orion 4 scores
43/45 and Nova 2 scores 44/45 when their own patches are run against the current suite, each
failing only the tests their clarification addresses: Orion 4 (block comment +
first alternative) and Nova 2 (record-field doc comment). Counterfactual is apples-to-apples this
time, since the 42-test suite is byte-identical to the one batch 2 ran and only meta.md changed.
After these conversions no run sits at 1 residual failure, so the next band starts at 5.

## Batch 3 (2026-08-06) — 0 legitimate, 2 PASS_CHEATED. Record types dropped in response.

10 working runs against the 45-test artifact (all clarifications in place).

| Run | Fails | Failing |
|---|---|---|
| Orion 4 / Orion 5 | 0 | **PASS_CHEATED** (rewrote repo tests) |
| Orion 2 | 1 | first alternative |
| Nova 2 | 2 | both record-TYPE |
| Orion 3 | 2 | both record-TYPE |
| Orion 6 | 3 | 2 record-type + first alternative |
| Nova 1 | 7 | |
| Orion 1 | 8 | record-type heavy |
| Nova 3 | 12 | record-type heavy |
| Nova 4 | 31 | regression |

Record-type kills: nested-in-nested 6, trailing-on-last 6, doc-comment 3, blank-line 3,
same-line-block 3, own-line-before-later 3, own-line-after-last 3, trailing-on-field 3.

### Differential harness after dropping the record-type feature (37 tests)
Applied each near-miss run's own patch to a clean base checkout and ran the reduced suite:

| Run | Result |
|---|---|
| **Nova 2** | **37 / 37 PASS** |
| **Orion 3** | **37 / 37 PASS** |
| Orion 2 | 36 / 37, first alternative |
| Orion 6 | 36 / 37, first alternative |

**Measured pass rate for batch 4: 2 of 10 = 20%**, in band.

## Batch 4 (2026-08-07) — ACCEPTED, 1 PASS_LEGITIMATE / 11

| Run | Fails | Note |
|---|---|---|
| Nova 10 | 0 | **PASS_LEGITIMATE** (633 added lines / 2 files) |
| Nova 6 | 1 | a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit |
| Nova 9 | 1 | a_doc_comment_on_a_record_field_is_not_repeated (extra blank line) |
| Nova 3 | 2 | both block-comment record layout |
| Nova 8 | 3 | |
| Nova 1 | 4 | |
| Nova 4 / Nova 7 | 7 | |
| Nova 11 | 9 | |
| Nova 5 | 10 | |

All three near-misses: `description_clear: true`, `inferable_from_codebase: true`.

### Kill counts
| Kills | Test |
|---|---|
| 7 | a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit |
| 6 | a_block_comment_after_a_record_field_stays_on_its_line |
| 5 | a_trailing_block_comment_and_an_own_line_comment_in_one_gap_keep_their_order |
| 3 | a_doc_comment_on_a_record_field_is_not_repeated |
| 2 | block-in-nested-match / block-on-let-binding / identical-text / mixed-gap-order / record-in-match |

Block-comment cases: **22 of 37 total kills**. Their line-comment twins at identical positions: 0-1
each. **15 of 37 tests killed nothing**, mostly the ones authored in the original design.

Long-horizon: 605-915 added lines, 2-4 files, 19-50M prompt tokens per run.
