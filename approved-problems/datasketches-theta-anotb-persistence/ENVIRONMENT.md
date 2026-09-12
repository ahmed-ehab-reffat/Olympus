# Environment viability — stateful Theta A-not-B persistence

Verdict: `pass` for the immutable artifacts identified in `ARTIFACTS.sha256`.

Clarified prompt hash:
`959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`.

## Immutable environment

- Repository pin: `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`
- Approved base image digest:
  `public.ecr.aws/d3j8x8q7/olympus-base@sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`
- Exact retained Phase A image manifest ID:
  `sha256:123a18652b09ee386e431f13d398436db019c68ea4f0012e9725629c5384dc98`
- Exact retained Phase A image config:
  `sha256:cf6dee77ae50a6f728bd9194bf2ff32379cb4538a268a2e3c51759d041944507`
- Exact retained Phase A image manifest list:
  `sha256:8234303b8df1706309489418fd2271de633458036f48c41cc04811fbaabc602e`
- Final clean Phase B gate image manifest ID:
  `sha256:31cd533e7dd994741edf433133f7dc6a2097bfb0cbff8c5bc3f33d2ab8d7c396`
- Final clean Phase B gate image config:
  `sha256:b16f7bb3df4cd7024e3fbe3a8064df4e49dc13119122dfaa111ba42c1d35efaa`
- Final clean Phase B gate image manifest list:
  `sha256:3aab83eccbcaa1bd8fb6b0ae47ce6bafadbb73e135539973022078d8be7f31a2`
- Runtime: networking disabled, UID/GID 10001, read-only composed source
  copied to an isolated writable directory by the harness.
- Evaluator order: untouched pin, optional implementation patch, then
  `test.patch`.

The Dockerfile checksum-pins Temurin JDK 25.0.4+7 for both supported Docker
architectures and Apache Maven 3.9.12, installs an explicit JDK toolchain, and
preloads the exact lifecycle/test-provider dependency graph. It also exposes
the image-owned Maven, Java, and javac through `/usr/local/bin`. The harness
sets `JAVA_HOME` and invokes `/opt/maven/bin/mvn`, its toolchain, and its cache
explicitly, so evaluator PATH rewriting cannot select or hide a host tool.
Build-time network access provisions 223 C++ and 251 Go cross-language
snapshots from
`apache/datasketches-tck` commit
`d363b12d293b395d90abb42677f9ea63178dbc0d`; runtime is fully offline.

## Exact Phase A

The path-repaired version's no-cache image was built from a clean clone with `.git`
excluded from the Docker context. The untouched repository was mounted
read-only, copied to task-scoped writable storage with the image-provisioned
cross-language fixtures, and then ran offline as UID/GID 10001 with a
task-scoped Java `user.home`:

```text
Tests run: 2279, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

The image starts and Maven resolves entirely from its preloaded cache. No
network, privilege, writable host home, host JDK/Maven, or pre-existing target
tree is used.

A platform-like replay then set inherited `PATH` to `/usr/bin:/bin` and cleared
`JAVA_HOME`. The composed pristine `test.sh base` still selected the absolute
image tools and passed 82/82. An independent container probe with
`PATH=/usr/local/bin:/usr/bin:/bin` resolved all three compatibility links and
reported Maven 3.9.12 and Java 25.0.4.

## Exact Phase B

After Phase A passed, `scripts/environment_gate.sh` rebuilt with
`--pull --no-cache`, composed each tree in exact evaluator order, and produced:

| Composition | Base lane | Focused lane |
|---|---:|---:|
| pristine + `test.patch` | 82/82 pass | 16 real TestNG methods; 16/16 behavioral failures |
| `solution.patch` + `test.patch` | 82/82 pass | 16/16 pass |

Baseline/reference focused testcase identities match exactly. There were no
patch conflicts, unmerged paths, missing test nodes, startup JUnit errors,
network resolution, permission failures, or synthetic pass reports. The final
gate printed `environment gate: PASS`.

The composed reference independently passed the complete suite:

```text
Tests run: 2295, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

All six predecessor focused-suite survivors admitted by the gap audit also
passed 2,295/2,295 before their new discriminators were applied. The four
mandatory Level 2 compatible patches (`Nova_Nova_2` through `Nova_Nova_5`)
each pass 82/82 base and 16/16 focused tests on the final composition.

## Quarantined attempts

The following attempts were stopped or excluded from behavioral evidence:

- clarified-version probes that ran only the dependency-warming `/app` copy or
  used a login shell that hid Maven from `PATH`; both stopped before tests;
- the reported platform derived-image run where both lanes stopped at bare
  `mvn: command not found`; it motivated the path repair and contains no
  behavioral result;
- the Level 2 five-run batch whose node wrapper protected the verifier-modified
  `SetOperationTest` and restored its obsolete expect-exception predicate;
  merge resets/hybrid baseline trees make that batch non-countable calibration
  evidence, although the production patches remain usable compatibility input;
- the first Level 3 validation draft, which required
  `SketchesArgumentException` for zero theta even though the repository's
  canonical theta validator throws `SketchesStateException`; the gate stopped,
  the oracle was widened to `SketchesException`, and all exact checks restarted;
- the first Level 3 complete-reference replay after removing the verifier test
  edit, which isolated the obsolete pristine direct-builder regression as its
  sole failure; the clean replacement was moved to `solution.patch`, keeping
  `test.patch` additive, and the gates restarted;
- one manual stripped-environment Phase A command that cleared `JAVA_HOME`
  without restoring the absolute image setting before calling Maven; it
  stopped before tests and was rerun correctly;
- a clarified-version mounted-clone probe that omitted the image-provisioned
  cross-language fixtures and reproduced the same 39 fixture failures;
- one path-repair complete-reference probe that likewise omitted those pinned
  fixtures; the corrected isolated replay passed 2,295/2,295;
- 39 pristine failures caused by absent cross-language snapshot fixtures;
- local offline startup failures caused by uncached Maven plugins/providers;
- a copied worktree with an invalid container-visible `.git` indirection;
- early fixed-path Surefire aggregation that missed timestamped reports;
- absolute script anchoring that selected the image's `/app` instead of the
  composed verifier tree; and
- a Surefire fork crash during parallel complete-suite survivor replay under
  host contention. The affected composition passed 2,295/2,295 alone.

Every blocker was corrected and the exact-version gate restarted. None is
counted as a failed solution or mutation.

## Level 3 final composition

The final `test.patch` adds only the unpredictable lifecycle class and
`test.sh`; it does not edit any existing repository test. The reference-only
`solution.patch` replaces the obsolete direct-builder expect-exception method
with an unconditional resource-identity regression, without challenge-history
framing or legacy fallback. Exact patch application is clean in baseline,
reference, all four mandatory compatible replays, and the near-pass injection.

The final Phase A and Phase B results are the 82/16/2,295 counts above. The
four mandatory Level 2 solution patches each pass both evaluator lanes, giving
an observed compatibility replay of 4/5 when Nova 1's final 14/16 result is
included. This matches the pre-change 4/5 forecast. Fresh Level 3 calibration
remains 0/10.
