# Errors and corrections — stateful Theta A-not-B persistence

## Quarantined environment attempts

- The platform's derived image did not retain the submitted `/opt` PATH, so the
  prior harness stopped both lanes at bare `mvn: command not found`. No build or
  test began. The harness now sets the image JDK and invokes Maven, the
  toolchain, and cache by absolute path; the Dockerfile also provides standard
  `/usr/local/bin` links for solver shells.
- One manual stripped-environment Phase A probe cleared `JAVA_HOME` without
  restoring `/opt/java` before invoking Maven directly. It stopped before
  tests, was quarantined, and the corrected arbitrary-UID run passed
  2,279/2,279.
- The pristine full suite initially reported 39 failures because required C++
  and Go serialization fixtures were absent. The image now provisions the
  fixtures from the pinned TCK commit; the failures were environment blockers,
  never solver evidence.
- Early local harness runs lacked cached Maven plugins/providers. The final
  Dockerfile preloads the exact offline dependency graph.
- A composed worktree's `.git` indirection was invalid inside Docker. Final
  Maven calls run from an isolated copy of a real exact clone.
- Early report collection assumed a fixed Surefire directory. The final
  harness discovers timestamped reports and emits real testcase XML.
- Parallel complete-suite mutation replays caused a Surefire fork crash under
  host contention. The affected run was quarantined and its composition passed
  2,295/2,295 when rerun alone.
- During clarified-version revalidation, running Maven directly in the image's
  dependency-warming copy failed before tests because that copy intentionally
  excludes `.git`; a login-shell retry also hid Maven from `PATH`. A later
  mounted-clone retry reproduced the known 39 failures because it had not yet
  copied the image-provisioned fixtures. The final Phase A used the absolute
  Maven/toolchain paths, a real exact clone, the provisioned fixtures, and a
  task-scoped Java `user.home`, then passed 2,279/2,279 before Phase B was rerun.
- The first complete-reference replay for the path repair copied the composed
  checkout but omitted the image's pinned cross-language fixtures, reproducing
  39 known fixture-read failures. The corrected isolated replay copied those
  fixtures and passed 2,295/2,295.

## Test and fairness corrections

- A wrong-family negative originally substituted the supported intersection
  family, which can be a valid generic image. It now uses unsupported
  `QUANTILES`.
- The old builder test required direct A-not-B to throw. A transitional
  verifier edit conditionally accepted that exception and included
  challenge-history framing; it was removed. `test.patch` is now additive,
  while `solution.patch` cleanly replaces the obsolete reference regression
  with an unconditional direct-builder resource assertion.
- The harness no longer overrides the process `HOME`; it passes a task-scoped
  Java user-home property and uses the image's explicit Maven cache.
- Byte-identical repeat serialization and minimal serialized length were
  removed as representation-prescribing assertions.
- Package-private cache/state observations were replaced with public result
  APIs and `HashIterator`.
- The first direct exact-empty assertion observed only canonicalized
  `getResult()` and allowed a corrupt persisted flag to survive. The final
  probe restores the serialized image and kills the isolated mutant.
- Auto-review correctly identified that the public prompt did not name the
  sizing-helper signature or the direct null-reset ordering. Both existing test
  contracts are now explicit in `meta.md`; no test or reference change was
  required.
- The Level 2 platform wrapper protected `SetOperationTest` as a pass-to-pass
  node, then restored its pristine expect-exception predicate after participant
  patches enabled direct A-not-B. Runs 3–5 passed all 16 focused behaviors but
  were classified test-broken. The batch was quarantined, the class was removed
  from the base lane, and verifier ownership of the file was eliminated.
- The first malformed-theta revision expected `SketchesArgumentException`.
  Canonical `checkThetaCorruption` throws `SketchesStateException`, so the
  reference gate correctly failed. The final oracle accepts the common
  `SketchesException` hierarchy and asserts no private subclass or message.
- The first nonpositive-theta fixture retained hashes. M18 removed the theta
  check but still passed 16/16 because hash-range validation masked the defect.
  The final fixture uses a public zero-retained nonempty estimation state; M18
  then fails exactly the common-state validation method.

No quarantined attempt is counted as a behavioral failure or calibration run.
