# Verification - OpenEXR multipart Image I/O

Verdict: `immutable revision v17 exact gates pass; calibration 0/10`.

Artifact identity: `meta 926a2b88`, `test 4974070a`, `solution 55307ae4`,
`Dockerfile fc0ce006`, mutation script `9d2d3eef`.

Revision v17 rejects a replacement name that exists only on an unsupported
source part. The prompt, reference, solution, and Dockerfile are unchanged.

## Revision v17 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The randomized hidden source has 2,327 declared and actual added lines.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, artifact checksums, and Docker-hosted
  `clang-format --dry-run --Werror` pass.
- The unknown-type fixture proves a unique equal-width source value and uses no
  exception-message or participant-layout oracle.
- The harness retains 14 stable identities and writes JUnit for the expected
  pristine missing-API build failure and successful reference execution.

## Revision v17 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with 14-node JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Run-8 solution 1 exact replay | 4/4 existing; 13/14 focused |
| Run-8 solution 2 exact replay | 4/4 existing; 14/14 focused |
| Run-8 near solution 3 exact replay | 4/4 existing; 12/14 focused |
| Run-8 broad solution 5 exact replay | 4/4 existing; 6/14 focused |
| Production mutation audit | 76 total; 75 incorrect killed; one equivalent delegation survivor |
| Unsupported-source name-match mutant | killed by `RewriteValidation` |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 380.09 s |

The fresh no-cache environment gate passes offline as UID/GID 10001. One
unconfigured mutation batch was quarantined and rerun after reference build
initialization; no result from it is counted. Exact gap, fairness, and
false-positive audits pass. Calibration is 0/10.

Revision v16 applies matching replacements to named typeless ordinary flat
single-part sources while retaining exact raw preservation for untouched
typeless sources. The prompt and Dockerfile are unchanged.

## Revision v16 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The randomized hidden source has 2,285 declared and actual added lines.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, artifact checksums, and Docker-hosted
  `clang-format --dry-run --Werror` pass.
- The expected replacement header comes from public `saveImages()` behavior;
  no byte representation or internal writer is inspected.
- The harness retains 14 stable identities and writes JUnit on setup,
  compilation, and CTest failures.

## Revision v16 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with 14-node JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Run-8 solution 1 exact replay | 4/4 existing; 13/14 focused |
| Run-8 solution 2 exact replay | 4/4 existing; 14/14 focused |
| Run-8 near solution 3 exact replay | 4/4 existing; 12/14 focused |
| Run-8 broad solution 5 exact replay | 4/4 existing; 6/14 focused |
| Production mutation audit | 75 total; 74 incorrect killed; one equivalent delegation survivor |
| Reported raw-copy shortcut mutant | killed by `SinglePartLoad` |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 328.64 s |

The fresh no-cache environment gate passes offline as UID/GID 10001. Invalid
initialization, stale-pattern, and pre-format audit batches were quarantined;
all results above use the final immutable hashes. Exact gap, fairness, and
false-positive audits pass. Calibration is 0/10.

## Historical revision v15 verification

Revision v15 removes the unfair requirement that a loaded legacy typeless file
return `MultiPartInputFile`'s synthesized `type`. The prompt, reference, and
Dockerfile are unchanged.

## Revision v15 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The randomized hidden source has 2,222 declared and actual added lines.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, and Docker-hosted
  `clang-format --dry-run --Werror` pass on the final composed sources.
- Load-result comparison ignores only optional `type`; exact raw rewrite
  outputs still compare every header attribute and the decoded image.
- The harness retains 14 stable identities and writes JUnit on setup,
  compilation, and CTest failures.

## Revision v15 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Legitimate raw-return-header architecture | 14/14 focused |
| Run-8 solution 2 exact replay | 14/14 focused |
| Run-8 solution 1 exact replay | 13/14 focused; untouched rewrite remains typeless failure |
| Representative run-8 near replay | 12/14 focused |
| Representative run-8 broad replay | 6/14 focused |
| Production mutation audit | 74 total; 73 incorrect killed; one equivalent delegation survivor |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 320.70 s |

The fresh no-cache environment gate passes offline as UID/GID 10001. A stale
intermediate hunk count was quarantined before behavior was assessed, then all
gates restarted for the final hash. Exact gap, fairness, and false-positive
audits pass. Calibration is 0/10.

## Historical revision v14 verification

Revision v14 closes successful replacement cardinality and exact typeless
single-part rewrite preservation without changing the public description or
Dockerfile.

## Revision v14 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The hidden source remains collision-safe at
  `src/test/OpenEXRUtilTest/testMultipartImageIO_27b877.cpp`.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, and Docker-hosted
  `clang-format --dry-run --Werror` pass on the final composed sources.
- The new oracles compare public header/image state and do not inspect
  serialized bytes or private helpers.
- The harness retains 14 stable identities and requested JUnit on setup,
  compilation, and CTest failures.

## Revision v14 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Run-8 solution 2 exact replay | 4/4 existing; 14/14 focused |
| Former run-8 pass 1 exact replay | 4/4 existing; 13/14 focused, typeless-header failure |
| Representative run-8 near replay | 4/4 existing; 12/14 focused |
| Representative run-8 broad replay | 4/4 existing; 5/14 focused |
| Production mutation audit | 74 total; 73 incorrect killed; one equivalent delegation survivor |
| New cardinality/header mutants | 2/2 killed by their intended nodes |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 324.87 s |

The no-cache environment gate passes offline as UID/GID 10001. Exact gap,
fairness, and false-positive audits pass. Calibration is 0/10; historical run
results are evidence only for predecessor versions.

## Historical revision v13 verification

Revision v13 closes the same-path publication, disjoint replacement-window,
and ripmap-domain holes without changing the public description or Dockerfile.

## Revision v13 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The hidden source remains collision-safe at
  `src/test/OpenEXRUtilTest/testMultipartImageIO_27b877.cpp`.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, and Docker-hosted
  `clang-format --dry-run --Werror` pass on the final composed sources.
- Rejection checks observe public output state and public enum modes without
  matching exceptions or inspecting private implementation structure.
- The harness retains 14 stable identities and requested JUnit on setup,
  compilation, and CTest failures.

## Revision v13 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Legitimate run-8 pass 1 exact replay | 4/4 existing; 14/14 focused |
| Legitimate run-8 pass 2 exact replay | 4/4 existing; 14/14 focused |
| Representative run-8 near replay | 4/4 existing; 12/14 focused |
| Representative run-8 broad replay | 4/4 existing; 5/14 focused |
| Production mutation audit | 72 total; 71 incorrect killed; one equivalent delegation survivor |
| New destination/ripmap mutants | 3/3 killed by their intended nodes |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 315.24 s |

The no-cache environment gate passes offline as UID/GID 10001. Exact gap,
fairness, and false-positive audits pass. A final formatting-only artifact
change invalidated the prior provisional pass, so every exact-version gate was
rerun for the hashes above. Calibration is 0/10; run 8's original 2/5 result is
historical difficulty evidence for v11.2, not a v13 calibration batch.

## Historical revision v12 verification

Revision v12 strengthens `RewriteParts` so both rewrite overloads must emit the
same complete replacement header as `saveImages()`. It also rewrites the public
description as direct maintainer prose. The reference implementation and
Dockerfile are unchanged.

## Revision v12 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The hidden source remains collision-safe at
  `src/test/OpenEXRUtilTest/testMultipartImageIO_27b877.cpp`.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, and Docker-hosted
  `clang-format --dry-run --Werror` pass on the final composed sources.
- The replacement oracle compares complete public `Header` state against a
  public `saveImages()` result; it does not inspect file bytes or private
  implementation structure.
- The harness retains 14 stable identities and requested JUnit on setup,
  compilation, and CTest failures.

## Revision v12 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-API `Build` failure with JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Legitimate run-8 pass 1 exact replay | 4/4 existing; 14/14 focused |
| Legitimate run-8 pass 2 exact replay | 4/4 existing; 14/14 focused |
| Production mutation audit | 69 total; 68 incorrect killed; one equivalent delegation survivor |
| New replacement-header mutant | killed by `RewriteParts` |
| Equivalent survivor, focused | 14/14 |
| Equivalent survivor, pre-existing | 127/127 in 316.57 s |

The no-cache environment gate passes offline as UID/GID 10001. Exact gap,
fairness, and false-positive audits pass. Provisional stale-hunk and
shared-attribute fixtures were quarantined, corrected, and followed by complete
gate restarts. The final hashes above are the only approved version.

Run 8's original two-of-five result remains a useful historical difficulty
signal, and both legitimate passes survive the new discriminator. Because v12
changes `meta.md` and `test.patch`, fresh calibration nevertheless starts at
0/10.

## Historical revision v11.2 verification

Revision v11.2 is a description-only cleanup. The test, solution, Dockerfile,
harness, repository pin, and tested behavioral contract are unchanged. The
no-cache environment gate and complete mutation audit were repeated for the
new prompt hash and reproduce the v11 results. The sole equivalent survivor
also passes the full 127/127 pre-existing lane in 319.84 seconds.

## Historical revision v11 static checks

- `solution.patch` and `test.patch` apply in evaluator order to the exact pin.
- The hidden source remains collision-safe as
  `src/test/OpenEXRUtilTest/testMultipartImageIO_27b877.cpp`.
- Participant production paths and verifier-owned paths do not overlap.
- `git diff --check`, `bash -n`, and Docker-hosted
  `clang-format --dry-run --Werror` pass.
- The public description specifies result and outside-damage isolation, not a
  reader class, read count, helper, staging layout, chunk offset, or timing.
- The harness exposes 14 stable focused identities and preserves requested
  JUnit on configuration, build, and CTest failures.

## Historical revision v11 runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine focused lane | expected missing-overload `Build` failure with native JUnit |
| Reference existing lane | 4/4 |
| Reference focused lane | 14/14 |
| Run-7 solutions 1--5 existing lane | 4/4 each |
| Run-7 solutions 1--5 focused lane | 0/5 pass; each fails the missing three-argument overload with all 14 identities reported |
| Production mutation audit | 68 total; 67 incorrect killed, one equivalent delegation survivor |
| New v11 eager/window mutants | 8/8 killed |
| Reference pre-existing suite | 127/127 in 322.37 s |
| Equivalent duplicate-validation survivor, focused | 14/14 |
| Equivalent duplicate-validation survivor, pre-existing | 127/127 in 319.48 s |

The clean no-cache environment gate passed offline as UID/GID 10001. The exact
gap and fairness audits pass. The first windowed-test draft was strengthened
after a repository-grounded matrix review, then all checks were invalidated and
repeated after mechanical formatting changed the final test and solution
hashes. One replay setup contaminated by generated bootstrap deletions was
quarantined before execution and replaced by a clean participant-source batch.

Calibration is 0/10. The five historical failures are discriminator evidence,
not fresh solver runs, and do not establish that v11 has reached the target
1--5/10 solve band.

## Historical revision v9.1 verification

## Static checks

- `solution.patch` and `test.patch` apply to the exact pin in evaluator order.
- The hidden source remains collision-safe at `src/test/OpenEXRUtilTest/testMultipartImageIO_27b877.cpp`.
- Participant production paths and verifier-owned paths do not overlap.
- All five filtered run-6 compatibility patches apply before `test.patch` without unmerged paths.
- The public description states observable rewrite and isolation behavior without prescribing `copyPixels()`, helpers, staging, serialized bytes, or an operation sequence.
- The harness exposes 13 stable feature identities and always writes the requested JUnit, including pre-CTest failures.
- `git diff --check`, `clang-format`, shell syntax, artifact hash, and exact-pin patch checks pass.

## Runtime results

| Lane | Result |
|---|---:|
| Fresh untouched image build | 285/285 generated targets |
| Pristine existing lane | 4/4 |
| Pristine feature lane | expected missing-API build failure with native JUnit |
| Reference existing lane | 4/4 |
| Reference feature lane | 13/13 |
| Five filtered run-6 patches | clean verifier injection; no v9.1 score assigned |
| Equivalent duplicate-validation survivor, focused | 13/13 |
| Equivalent duplicate-validation survivor, pre-existing | 127/127 in 318.06 s |
| Forced configuration failure | status 1, valid fallback JUnit, CTest not reached |
| Forced base-build failure | status 1, valid fallback JUnit, CTest not reached |

Pristine and reference feature JUnit identities match. Normal reference execution preserves native CTest XML. The first v9.1 attempt was quarantined at patch application because the assertion removal left a stale unified-diff hunk count. After repairing patch syntax, the complete no-cache exact gate restarted from zero and passed. The earlier generated-`build-bootstrap` replay contamination remains quarantined through source-only compatibility patches.

## Audits

- Environment gate: pass from a clean no-cache image, offline and arbitrary-UID.
- Gap analysis: pass after closing rewrite-overload validation, exact-case matching, UTF-8 input/output, positive deep crop, and unknown-type stream gaps.
- Fairness analysis: pass after removing the unsupported invalid-save empty-stream predicate; every remaining predicate is public or repository-grounded.
- False-positive audit: 60 production mutants; 59 incorrect variants killed, one equivalent delegation survivor, zero actionable survivors.
- Reference source restoration after the mutation audit: pass.
- Full-suite escalation for the only survivor: pass.

The five run-6 implementations are trajectory and injection evidence for v8. They do not implement `rewriteImages()` and are not fresh v9.1 calibration results. Any submission-artifact change invalidates these exact-version records and restarts calibration at 0/10.
