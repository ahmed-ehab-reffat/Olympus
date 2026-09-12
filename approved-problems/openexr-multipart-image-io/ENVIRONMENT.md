# Environment gate - OpenEXR multipart Image I/O

Verdict: `pass for immutable revision v17`.

Repository: `AcademySoftwareFoundation/openexr` at `c101ab742a9e93c8c9c6f1781055e938cc160305`.

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `926a2b88ecda0bef5f6dc2ae93e88a74b290e560d72720bb601f0bee232e940f` |
| `test.patch` | `4974070a9c5250e5a53bc1f1470b44eaf6cf404ce69110d13951a34db6fbf444` |
| `solution.patch` | `55307ae4ff12f707973655c5cb26ce5f4ad4b51ebaa617164734725e2d9ce440` |
| `Dockerfile` | `fc0ce0068f5fa65c94986532de4a5c74bfb40e7305ac821e572e7c0be96a1d80` |

## Revision v17 Phase A

The exact fail-fast gate rebuilt all 285 generated targets in a fresh no-cache
image. It started offline as UID/GID 10001 with participant source read-only
and a separate writable results mount. The untouched existing lane passed 4/4.

## Revision v17 Phase B

Composition followed the evaluator order: clean pin, participant/reference
patch when present, then the exact hidden patch. The pristine focused lane
produced the expected missing-API `Build` failure with all 14 JUnit identities.
The reference passed 4/4 existing and 14/14 focused, with matching focused
JUnit identities.

Source-only run-8 solutions 1, 2, 3, and 5 composed cleanly, passed 4/4
existing, and scored 13/14, 14/14, 12/14, and 6/14 focused. All four pass the
new unsupported-source replacement predicate, including implementations with
different rewrite planning structures.

The first v17 mutation attempt used an unconfigured results root and reported
only invalid compile results. It was quarantined without counting any outcome.
After the required reference initialization, the exact 76-variant audit and
survivor escalation passed. No submission artifact changed after this gate.

## Revision v16 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image
from base digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
It started and ran offline as UID/GID 10001 with participant source read-only
and results on a separate writable mount. The untouched existing lane passed
4/4.

## Revision v16 Phase B

Composition used the clean pin, participant patch when present, then the exact
`test.patch`. The pristine focused lane produced the expected missing-API
Build failure with a real 14-node JUnit report. The reference passed 4/4
existing and 14/14 focused, and the focused testcase identities matched.

Source-only run-8 solutions 1, 2, 3, and 5 all composed cleanly and passed 4/4
existing. Their focused scores were 13/14, 14/14, 12/14, and 6/14. The sole
legitimate pass uses a materially different rewrite structure; the other
outcomes are behavioral rather than environment failures.

Several provisional mutation batches were quarantined: one referenced a
temporary image after cleanup, one used an unconfigured result root, and one
contained a stale mutation pattern. A later complete result was invalidated
when formatting changed `test.patch`. The environment, mutation, survivor, and
replay gates were then restarted for the hashes above. No provisional result
is counted. Any submission-artifact change invalidates this verdict.

## Revision v15 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image
from base digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
Startup and evaluator execution succeeded with networking disabled, UID/GID
10001, read-only participant source, and a separate writable result volume.
The untouched repository passes the 4/4 existing lane.

## Revision v15 Phase B

Composition used clean pin, participant patch when present, then the exact
`test.patch`. The pristine composition passes 4/4 existing tests and produces
the expected missing-API focused `Build` failure with a real 14-node JUnit
report. The reference passes 4/4 existing and 14/14 focused tests, and both
reports expose the same focused testcase identities.

A legitimate architecture that returns the raw typeless singular header while
using the normalized multipart header only for dispatch passes 14/14. Exact
run-8 focused replays score 14/14, 13/14, 12/14, and 6/14; the first, near, and
broad participant trees retain their previously established 4/4 base result.
No patch conflict or startup failure is counted as behavior.

An intermediate `test.patch` had a stale added-file hunk count and truncated
the injected source. The gate stopped at composition, quarantined that version,
fixed the packaging metadata, and restarted from zero. Any subsequent
submission-artifact change invalidates this verdict.

## Revision v14 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image from
base digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
Startup and evaluator execution succeeded with networking disabled, UID/GID
10001, read-only participant source, and a separate writable result volume. The
untouched repository passes the 4/4 existing lane.

## Revision v14 Phase B

Composition used clean pin, participant patch when present, then the exact
`test.patch`. The pristine composition passes 4/4 existing tests and produces
the expected missing-API focused `Build` failure with JUnit. The reference
passes 4/4 existing and 14/14 focused tests. Pristine and reference reports
expose the same 14 focused testcase identities.

Source-only run-8 replays inject without overlap. `Nova_Nova_2` passes 4/4
existing and 14/14 focused as a materially different valid implementation.
`Nova_Nova_1` passes 4/4 and 13/14, failing only the new public typeless-header
assertion; it is reclassified as behaviorally incomplete rather than an
environment mismatch. The representative near and broad implementations pass
4/4 existing and retain 12/14 and 5/14 focused results. No patch conflict,
startup failure, or missing report is counted as behavior.

Any subsequent submission-artifact change invalidates this verdict.

## Revision v13 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image from
the pinned untouched checkout. Startup and evaluator execution succeeded with
networking disabled, UID/GID 10001, read-only participant source, and a
separate writable result volume. The untouched repository passes the 4/4
existing lane.

## Revision v13 Phase B

Composition used the clean pin, participant patch when present, then the exact
`test.patch`. The pristine composition passes 4/4 existing tests and produces
the expected missing-API focused `Build` failure with JUnit. The reference
passes 4/4 existing and 14/14 focused tests, and the pristine/reference focused
reports expose the same 14 testcase identities.

Two materially different legitimate run-8 production patches were recomposed
source-only and followed by the final verifier. Both pass 4/4 existing and
14/14 focused tests. Representative non-passing controls also remain
behavioral: the near implementation passes 4/4 and 12/14, while the broad
failure passes 4/4 and 5/14. No patch conflict, startup failure, or missing
report was counted as a solution result.

A formatting-only change to the hidden source changed the immutable test hash
after an earlier behavioral pass. That provisional evidence was invalidated,
and the complete no-cache environment gate, exact replays, mutation audit, and
survivor escalation were restarted for the hashes above. Any subsequent
submission-artifact change invalidates this verdict.

## Revision v12 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image
from base digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
Startup and evaluator execution succeeded with networking disabled, UID/GID
10001, read-only participant source, and a separate writable result volume.
The untouched repository passes the 4/4 existing lane.

## Revision v12 Phase B

Composition used clean pin, participant patch when present, then the exact
`test.patch`. The pristine composition passes 4/4 existing tests and produces
the expected missing-API `Build` failure with JUnit. The reference passes 4/4
existing and 14/14 focused tests. Pristine and reference reports expose the
same 14 focused testcase identities.

The two legitimate run-8 solutions were separately recomposed with only their
participant-owned production changes followed by the final verifier. Both pass
4/4 existing and 14/14 focused tests. This replay covers two materially
different valid implementations of the strengthened replacement-header rule.

Two provisional attempts were quarantined before any verdict: one stale
new-file hunk count truncated the injected source, and one replacement fixture
conflicted on a multipart-shared pixel aspect ratio. A later valid run was
manually interrupted while distinguishing the expected pristine compile
failure from a verifier failure, so it was also discarded. The complete gate
then restarted and passed for the hashes above. No result from an interrupted
or invalid composition was counted.

Any subsequent submission-artifact change invalidates this verdict.

## Historical revision v11.2 Phase A

The exact gate rebuilt all 285 generated targets in a fresh no-cache image from
base digest
`sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`.
Startup and evaluator execution succeeded with networking disabled, UID/GID
10001, read-only participant source, and a separate writable result volume. The
untouched repository passed the 4/4 existing lane.

## Historical revision v11.2 Phase B

Evaluator composition used clean pin, participant patch when present, then the
exact `test.patch`. The pristine composition passed 4/4 existing tests and
produced the expected missing-overload `Build` failure with native JUnit. The
reference composition passed 4/4 existing and 14/14 focused tests. Pristine and
reference reports exposed the same 14 testcase identities.

Revision v11.2 changes only the wording of `meta.md`. The complete gate was
nevertheless rebuilt and rerun for the new prompt hash; test, solution,
Dockerfile, harness, repository pin, and evaluator composition are unchanged.

All filtered historical source patches accepted by the gate composed without
owned-path overlap. A separate exact replay of run-7 solutions 1--5 confirmed
4/4 existing tests for every patch and a focused build failure for every patch
because the new three-argument filename and stream overloads are absent.

One attempted replay batch was quarantined before execution because archived
run 4 also contained generated `build-bootstrap` deletions that do not belong
to the evaluator source patch. The replay was restarted from five clean clones
with only participant-owned `src/lib/OpenEXRUtil/**` and `testIO.cpp` changes,
which is the evaluator-compatible composition already accepted by Phase B. No
outcome from the aborted batch was counted.

The final formatting pass changed `test.patch` and `solution.patch`, invalidated
the preceding provisional verdict, and triggered this complete no-cache gate
again. A later fairness audit made channel-sampling incompatibility explicit in
the prompt and verifier; that change invalidated the formatting-era verdict and
triggered one more complete gate. The result above is for the final exact
hashes only. Any subsequent submission-artifact change invalidates it.

## Historical revision v9.1 Phase A

The v9.1 gate rebuilt the untouched pin in a fresh no-cache image from base digest `sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321`. All 285 generated targets built. Evaluator startup and execution succeeded offline as UID/GID 10001 with read-only participant source and a separate writable result volume.

The pristine focused lane passed all four selected OpenEXRUtil tests. The equivalent duplicate-validation survivor was rebuilt against the exact v9.1 verifier and passed the complete 127-case pre-existing suite in 318.06 seconds in the same offline arbitrary-UID environment.

## Historical revision v9.1 Phase B

Evaluator composition followed the exact order: clean pin, participant implementation when present, then `test.patch`.

| Composition | Existing lane | Feature lane | Result |
|---|---:|---:|---|
| pristine + `test.patch` | 4/4 | 0/13 | expected missing-API build failure with native JUnit |
| `solution.patch` + `test.patch` | 4/4 | 13/13 | pass |
| each filtered `agent-runs6` patch + `test.patch` | injection only | not scored | clean composition, no owned-path overlap |

Pristine and reference reports expose the same 13 feature testcase identities. The five run-6 patches are v8 solutions and lack the v9 rewrite API, so they are compatibility injections rather than known-good v9 replays.

The historical v9 replay attempt was quarantined before behavior because the platform patches included generated `build-bootstrap` files absent from the exact clean checkout. Source-only replay patches under `verify/replays-v9/` preserve participant-owned changes and apply cleanly.

The first v9.1 attempt was likewise quarantined before execution when `git apply` found a stale unified-diff hunk count after the assertion removal. The patch header was repaired, patch applicability was checked against the exact pin, and the complete no-cache gate restarted from zero. Neither aborted attempt was assigned a behavioral outcome.

The `test.sh` hunk is byte-identical to v9. Its controlled configuration and base-target compilation probes therefore remain harness evidence rather than a changed execution surface: both return status 1, do not reach CTest, and produce parseable requested JUnit. Normal v9.1 reference execution retained native CTest XML.

Any submission-artifact change invalidates this verdict.
