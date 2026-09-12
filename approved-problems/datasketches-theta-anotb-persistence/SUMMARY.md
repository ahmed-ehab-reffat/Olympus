# Summary — stateful Theta A-not-B persistence

Status: `accepted and archived 2026-08-17; exact Level 3 gates pass`.

- Repository: `apache/datasketches-java`
- Pin: `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`
- Production language: Java
- Task type: feature request
- Pre-acceptance forecast: 4/5 compatible replay and approximately 7–9/10 fresh solvers

## Current Level 3 result

The Level 2 test mismatch was real. `test.patch` modified
`SetOperationTest.checkBuilderAnotB_noSeg`, while the platform's pass-to-pass
wrapper protected and restored the pristine method that requires direct
A-not-B construction to throw. Three production-correct patches were therefore
reported as test-broken. Level 3 keeps `test.patch` additive, removes that class
from the 82-method base lane, and moves the clean obsolete-regression update to
the reference-only `solution.patch`.

Malformed-state coverage now independently checks nonpositive theta with a
zero-retained estimation image and checks zero, out-of-theta, and duplicate
retained hashes when the implementation uses a locatable standard payload.
M18 demonstrated that the earlier retained-hash fixture could mask a missing
theta validator; the isolated final probe kills it. The final audit kills
19/19 compile-valid mutants.

Exact final results are pristine 82/82 base with 16/16 focused behavioral
failures, reference 82/82 and 16/16, pristine complete 2,279/2,279, and
reference complete 2,295/2,295. Nova 2–5 all pass both final lanes; Nova 1 is
14/16, missing short-header normalization and duplicate-hash validation. Observed compatible replay
is 4/5, exactly matching the pre-change forecast. This fixes environment,
fairness, and false-positive coverage. The user subsequently confirmed platform
acceptance on 2026-08-17. That external disposition closes the package even
though the preserved fresh-calibration count remains 0/10 and the compatible
replay was outside the intended difficulty band.

## Historical package context

The task adds direct construction, serialization, heapification, and wrapping
for stateful Theta A-not-B operations. The public contract spans all logical
Theta states, exact and estimation continuation, heap versus wrapped ownership,
live synchronization, read-only resources, capacity atomicity, configured
seeds, reset/reuse, stateless independence, and common image validation without
prescribing a private state representation.

The clarified public contract explicitly names the existing public static
`int ThetaSetOperation.getMaxAnotBResultBytes(int k)` sizing interface and
requires writable direct `setA(null)` to persist an empty, zero-retained reset
before throwing `SketchesArgumentException`.

The predecessor package passed its required gates. Pristine was 102/102 on the base
lane and fails all 16 focused methods; the reference passes both lanes and the
complete 2,295-test composed suite. The untouched repository passes
2,279/2,279 offline as UID/GID 10001. Gap and fairness audits pass, and all 17
compile-valid false-positive mutants are killed. Six demonstrated predecessor
survivors passed their old focused suite and 2,295/2,295 complete tests before
their probes were admitted.

The clarified prompt hash is
`959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`.
All exact gates were repeated; a rebuilt null-reset mutant failed exactly its
target method, while the executable submission artifacts remained unchanged in
that prompt-only revision.

The platform later showed that its derived runtime discarded the image's
custom `/opt` PATH, causing both lanes to stop at `mvn: command not found`.
Level 2 makes the harness use the submitted JDK, Maven, toolchain, and offline
cache by absolute path and adds standard tool links in the image. A replay with
blank inherited `JAVA_HOME` and `PATH=/usr/bin:/bin` passes pristine base
102/102 and reference focused 16/16; fresh exact Phase A, Phase B, and the
2,295-test complete reference suite also pass. Hidden behavioral tests and the
reference implementation are unchanged.

Those Level 2 statements are historical. Exact solver patches are now available
and replayed above. The accepted immutable package remains canonical here; raw
runs, preliminary records, and recovery evidence are under
`archive/datasketches-theta-anotb-persistence/`.
