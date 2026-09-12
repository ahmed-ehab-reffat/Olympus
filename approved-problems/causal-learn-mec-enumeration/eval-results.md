# eval-results — causal-learn-mec-enumeration

Base commit: 9de1d886b7ab45868819aec7132f79378990f0b6 (py-why/causal-learn)

## Local validation

| Check | Result |
|---|---|
| new tests with solution | 202 passed |
| new tests on base (modules removed) | 202 failed, each a named node, no collection error |
| base tests, 3 runs | identical every run |
| human-effective LOC | 490 (floor 430) |
| files changed | 3, all new, none edited |
| banned markers in test paths | none |
| test.sh mode in test.patch | 100755 |

## Repository baseline

`pytest tests` with default collection finds 4 tests and passes in 2.5s. The `Test*.py`
files are not collected by that default, and running them explicitly shows pre-existing
breakage: `TestPNL` and `TestDAG2PAG` need `torch`, `TestCAMUV` fails to import, `TestFAS`
asserts while importing a benchmark file, `TestEvaluation` and `TestBackgroundKnowledge`
raise `FileNotFoundError` from relative data paths, and `TestLocalScore` takes 82 seconds
and fails six of six. Base mode runs the green deterministic remainder closest to the
change: `TestGeneralGraphMethods`, `TestDagMethods`, `TestMECCHECK`, `TestSkeletonDiscovery`
and `TestGST`.

## Difficulty

Nova solved 6 of 10, over the 40 percent cap, so the scale clause was added: `compelled_edges`,
`essential_graph` and `is_cpdag` must answer for classes too large to list. The naive reading
of their definition, list every member and intersect, no longer terminates on the three new
fixtures. The intended route is Meek closure plus a consistent-extension test, both verified
against the old enumerating implementation over all 4096 four-node graphs.

## Cross-check invariants

The enumeration and the traversal are independent implementations of the same set, and the
tests assert they agree. Hand-checkable anchors: a three node chain has three members, a
triangle has six, a star with three leaves has four, a collider has one, and two separate
chains multiply to nine.

## Endpoint constants

The quality check raised a hypothetical: the tests name `Endpoint.STAR`, `TAIL_AND_ARROW` and
`ARROW_AND_ARROW`, which would break collection if the repository lacked them. It does not.
`git show <base>:causallearn/graph/Endpoint.py` lists all seven members, TAIL, NULL, ARROW,
CIRCLE, STAR, TAIL_AND_ARROW and ARROW_AND_ARROW, and a container run against a clean
checkout of the pinned commit confirms every one is present and the seven endpoint tests pass.
No change was made.

## Test Fairness round 1

FAIL, 1 of 115 unfair: `test_a_cyclic_graph_is_not_a_cpdag` pinned False while meta.md also
said every routine in that group refuses a graph with no member. The wording is fixed so only
the three that refuse are named. All five coverage suggestions were taken; two found real
defects, a traversal entry point that skipped validation and a shortest path that did not
honour the stated tie-break.

## Agent runs

None yet.

| Agent | Evaluator | Verdict | Messages | Files | LOC | Failed tests | Failure reason | Approach |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## FP check

Runs after the first agent batch.
