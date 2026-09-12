# eval-results.md - ezdxf-attribute-sync

Base commit `b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`, image `olympus-base-python`.

## Local validation (before any agent run)

| Run | Mode | Tree | Result |
| --- | --- | --- | --- |
| L1 | new | base | 131 tests, 131 failures, 0 errors |
| L2 | base | base | 7424 passed, 76 skipped, 1 xfailed |
| L3 | new | base + test.patch + solution.patch | 131 passed |
| L4 | base | base + test.patch + solution.patch | 7424 passed, 76 skipped, 1 xfailed |
| L5 | new x3 | patched | 131 passed each run, identical |
| L6 | base x3 | patched | 7424 passed each run, identical |
| L7 | apply order | test.patch then solution.patch | both apply clean |
| L8 | apply order | solution.patch then test.patch | both apply clean |

All runs offline (`--network none`) as uid 1000.

## Agent runs

### Batch 1 (2026-08-03) - 1 run, VOIDED by a prompt defect (superseded by batch 2)

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Orion | Nova | FAIL_TEST_MISMATCH | 51 | 8 | 573 | 27 of 109, all report-shaped | Built the full synchronization feature and kept the baseline green; modelled the report fields as lists of the affected entities instead of counts |

The evaluator flagged an environment blocker of type `verifier` with `agentBlameUnfair: true` and
high confidence: "Hidden verifier enforces an undocumented integer-count report API and an
ambiguous no-change reference-count convention." That reading is correct, so this run does not
count as a difficulty datapoint - see feedback.md for the two description fixes. The run is
otherwise encouraging on shape: 51 messages (over the 40 floor), 8 files, baseline green, and 82 of
109 hidden tests passing on everything that was unambiguously stated.

Re-batch after the wording fix before drawing any conclusion about the pass rate.

## Watch items for the first batch

1. Placement under transformation: expect failures in
   `test_attrib_placement_follows_rotation_and_scaling`, `..._mirroring`, `..._the_extrusion` and
   `test_aligned_definition_keeps_its_alignment` from implementations that copy the definition's
   location instead of transforming it.
2. Idempotence: `test_second_sync_reports_no_change` and
   `test_second_sync_leaves_the_document_unchanged` catch implementations that rewrite
   unconditionally or that transform the existing attribute again on every run.
3. Traversal: `test_block_sync_covers_references_inside_block_definitions` catches
   `doc.modelspace().query("INSERT")`.
4. Multiline: `test_multiline_definition_creates_a_multiline_attrib` catches a raw copy of the
   definition's DXF attributes (`attribute_type` 4 instead of 2).
5. Multiline content: `test_multiline_content_of_an_attrib_is_kept_in_full` catches an
   implementation that carries the value over from the single line `text` field of a multiline
   attribute (the bug the coverage suggestions found in the reference).
6. Position lock: `test_locked_attrib_stays_locked` catches an implementation that takes
   `lock_position` from the definition, which unlocks a user-locked attribute and moves it on the
   next run.
7. Multiline defaults: `test_added_multiline_attrib_carries_the_full_default` catches a solution
   that reuses `add_auto_attribs` verbatim, which truncates a multiline default to its first line.
8. Identity: `test_existing_attrib_stays_the_same_entity` and
   `test_extended_data_of_an_existing_attrib_survives` catch delete-and-recreate.

If a batch lands above 40%, the first hardening lever is composition rather than more breadth:
locked position on a mirrored reference with a multiline definition, and a rename on a reference
whose stale attribute differs only in the case of its tag. Capture every passing agent's diff into
`agent-runs/` before touching the artifact.

### Batch 2 (2026-08-03) - 5 runs, 80% pass, TOO EASY - hardening in progress

| Agent | Evaluator | Verdict | Failed tests | Approach note |
| --- | --- | --- | --- | --- |
| Nova | Nova | PASS_LEGITIMATE | 0 of 113 | own attsync module + methods on the three classes |
| Nova | Nova | PASS_LEGITIMATE | 0 of 113 | same shape, 568 patch lines |
| Nova | Nova | PASS_LEGITIMATE | 0 of 113 | same shape, untyped signatures |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 4 of 113 | 381 patch lines, skipped the lock flag on new attributes, paperspace membership and the block flag with no references |
| Orion | Nova | PASS_LEGITIMATE | 0 of 113 | free functions plus thin methods, 880 patch lines - the closest to the reference |

**4 of 5 pass = 80%, cap 40%. The artifact needs a harder feature, not more tests.**

Post-batch forensics, before shelving:

1. Differential harness - the four passing patches replayed against the current 113-test suite,
   which gained the duplicate-definition churn tests after the batch ran: all four pass 113/113.
   Every test added after the batch has zero discriminating power.
2. Six composition probes across the reference and all four passers (locked x multiline x mirrored,
   rename onto a case-only stale duplicate, self-referencing block, MINSERT, empty-tag attribute,
   reorder with duplicate definitions): five of six byte-identical everywhere. The single
   divergence is a validation corner that would have to be stated to be fair.

No seam remains WITHIN the current scope: no test over these behaviours can discriminate, because
five independent correct implementations agree. The lever is therefore SCOPE - add capability whose
difficulty lives in DOING rather than in knowing the contract - not more cases over the same
behaviours. Hardening axes are in DESIGN.md section 15: the placement engine (graph walk, composed transforms,
MINSERT grids, layout reachability, cycle safety) and the version-dependent multiline form.

Replay after hardening: the four batch-1 passers now score **115 passed, 16 failed** each against
the 131-test suite. Re-batch to measure the new rate.
