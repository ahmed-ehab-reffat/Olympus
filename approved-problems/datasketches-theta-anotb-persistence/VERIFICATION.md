# Verification — stateful Theta A-not-B persistence

Status: `accepted and archived 2026-08-17; Level 3 exact gates pass`.

## Exact results

- Repository pin:
  `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`.
- Clarified `meta.md` hash:
  `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`.
- Final `test.patch` hash:
  `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132`.
- Final `solution.patch` hash:
  `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f`.
- `solution.patch` and `test.patch` apply cleanly in evaluator order.
- No-cache Docker build from an untouched clone: pass.
- Offline arbitrary UID/GID 10001 startup: pass.
- Platform-like cleared `JAVA_HOME` and `/usr/bin:/bin` PATH replay: base
  82/82 and reference focused 16/16 pass through absolute image tools.
- Pristine complete suite: 2,279/2,279 pass.
- Pristine base lane after `test.patch`: 82/82 pass.
- Pristine focused lane: 16 real TestNG methods, 16/16 fail behaviorally.
- Reference base lane: 82/82 pass.
- Reference focused lane: 16/16 pass.
- Baseline/reference focused testcase identities: exact match.
- Reference complete composed suite: 2,295/2,295 pass.
- Gap analysis: `pass`.
- Fairness analysis: `pass`.
- False-positive audit: `killed=19 survived=0 invalid=0 total=19`.
- Clarified null-reset mutant replay: 16 focused tests, exactly one failure in
  `nullSetAResetsDirectStateBeforeReportingTheArgumentError`.
- Six predecessor focused-suite survivors: 16/16 focused and 2,295/2,295
  complete before their final probes were admitted.
- Exact compatible-solver replay: Nova 2–5 pass both lanes; Nova 1 is 14/16,
  missing short-header normalization and duplicate-hash rejection; observed 4/5.
- Fresh calibration: 0/10.
- Platform disposition: user-confirmed acceptance on 2026-08-17.

## Audit corrections

The environment was restarted after missing cross-language fixtures, cache,
worktree, and report-discovery blockers. The hidden suite was restarted after
correcting the supported-family negative, removing representation-prescribing
serialization assertions, replacing package-private observations, extending
direct producer coverage, and finding a direct exact-empty persistence
survivor. The final artifact hashes are authoritative; no result was carried
across an artifact revision.

A complete-suite survivor run that crashed its Surefire fork during parallel
host contention was quarantined. The same immutable composition passed
2,295/2,295 alone. No environment blocker is counted as behavioral evidence.

Auto-review then found two prompt omissions. The clarified prompt now names the
existing public static `int getMaxAnotBResultBytes(int k)` sizing interface and
states the direct `setA(null)` reset-before-`SketchesArgumentException`
lifecycle. In that prompt-only revision, `test.patch`, `solution.patch`, and
`Dockerfile` were byte-identical to the prior revision. Phase A, Phase B, the
complete reference suite, and all downstream audits were repeated for the new
prompt hash; calibration is 0/10.

The subsequent platform baseline exposed an environment-only defect: the
derived runtime discarded the Dockerfile's custom `/opt` PATH, while the
harness called bare `mvn`. The repaired Dockerfile publishes Maven, Java, and
javac in `/usr/local/bin`, and `test.sh` now sets the image JDK and calls Maven,
the toolchain, and the offline cache by absolute path. Hidden Java assertions,
test identities, the public prompt, and reference behavior are unchanged. A
fresh Phase A, exact Phase B, 2,295-test reference suite, and downstream audits
all pass; calibration restarted and remains 0/10.

Level 3 then corrected the protected-test mismatch and malformed-state gap.
`test.patch` is now additive and its base lane omits the superseded direct
builder rejection. `solution.patch` contains the clean reference regression
update. M18 first survived because retained-hash checks masked a missing theta
check; the final zero-retained fixture isolates theta and kills M18. M19 omits
invalid/duplicate retained-hash validation and is also killed. Each final
mutant produces exactly one failure in the common validation method. The final
Phase A image manifest/config are
`sha256:123a18652b09ee386e431f13d398436db019c68ea4f0012e9725629c5384dc98`
and
`sha256:cf6dee77ae50a6f728bd9194bf2ff32379cb4538a268a2e3c51759d041944507`;
the final Phase B manifest/config are
`sha256:31cd533e7dd994741edf433133f7dc6a2097bfb0cbff8c5bc3f33d2ab8d7c396`
and
`sha256:b16f7bb3df4cd7024e3fbe3a8064df4e49dc13119122dfaa111ba42c1d35efaa`.

## Hardening outcome

Before Level 3 changed submission artifacts, the five Level 2 trajectories
predicted 4/5 compatible passes and approximately 7–9 successful fresh solvers
out of ten. The first figure was a compatibility replay estimate; the second
was a fresh-calibration expectation. Observed compatible replay is 4/5, exactly
matching the forecast. That validates compatibility but confirms the package
is too easy rather than successfully hardened. Fresh calibration remains 0/10
until a new exact-version batch is run after further fair hardening.
