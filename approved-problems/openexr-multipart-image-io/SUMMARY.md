# OpenEXR multipart high-level Image I/O

- Repository: `AcademySoftwareFoundation/openexr`
- Pin: `c101ab742a9e93c8c9c6f1781055e938cc160305`
- Language: C++
- Task type: feature request
- State: accepted and archived 2026-08-15; immutable revision v17
- Target: 1 to 5 solves in 10 completed runs

The user confirmed platform acceptance on 2026-08-15. Canonical artifacts and
compact verification records remain in this problem folder. Eight raw solver
bundles and the preliminary candidate dossier are preserved under
`archive/openexr-multipart-image-io/`. The final v17 artifact changed after the
historical two-of-five batch, so its fresh calibration remains recorded as
0/10 rather than being inferred from acceptance.

Revision v17 closes the unsupported-source replacement matching gap. A
replacement whose exact name exists only on an unsupported source part is now
unmatched and rejected through both filename and stream rewrites before either
destination changes. The hidden fixture self-checks its supported and unknown
type values and does not depend on exception text or an internal matching plan.

Exact v17 verification passes: fresh 285-target environment build, reference
4/4 existing and 14/14 focused, all 75 incorrect mutants killed in the 76-case
audit, and the equivalent survivor at 14/14 focused plus 127/127 pre-existing
in 380.09 seconds. Four run-8 controls all pass the new predicate and retain
13/14, 14/14, 12/14, and 6/14 focused scores. Calibration restarts at 0/10.

Revision v11 added windowed named loading beside the earlier multipart load,
save, and rewrite APIs. Filename and caller-owned stream overloads return an
exact intersection for any `ONE_LEVEL` flat/deep scanline/tiled part while
preserving complete header state, channels, sample counts, and samples. Storage
wholly outside that result is isolated, even when it is damaged.

The new discriminator covers all four independent reader families and both
transports, including deep sample-count reads, offset coordinates, sampled
channels, exact-case matching, UTF-8 paths, unsupported siblings, partial and
disjoint requests, and multiresolution rejection. Four self-checked corruption
fixtures distinguish bounded decoding from the eager complete-part architecture
used by every run-7 solution.

Exact verification passes: pristine 4/4 existing with the expected missing-API
feature failure, reference 4/4 existing and 14/14 focused, and all five run-7
patches retain 4/4 existing while failing the missing windowed overload. The
68-mutant audit kills 67 incorrect variants; the sole survivor delegates
duplicate-name rejection to OpenEXR and is behaviorally equivalent.

Run 8 solved v11.2 twice out of five attempts. The other implementations scored
12/14, 8/14, and 5/14, giving a useful barely-solvable historical signal.

Revision v12 fixes the remaining rewrite fidelity gap. `RewriteParts` now
compares each replacement's complete emitted header with the header produced
by `saveImages()` through both filename and stream rewrite overloads. A new
rewrite-only header-drop mutant is killed, while both legitimate run-8 passes
remain 14/14 on exact replay. The description was shortened into direct issue
prose and names the same observable header equivalence.

Exact v12 verification passes: fresh 285-target environment build, reference
4/4 existing and 14/14 focused, 68/68 incorrect mutants killed, and the sole
equivalent survivor at 14/14 focused plus 127/127 pre-existing in 316.57
seconds. Because v12 changes submission artifacts, calibration restarts at
0/10 despite the retained 2/5 historical signal.

Revision v13 closes three validation holes already covered by the public
contract. Identical input/output rewrite paths must now fail without changing
the source bytes; a disjoint replacement header/image window must fail before
either filename or stream output changes; and both windowed overloads must
reject a selected ripmap as well as a mipmap. The reference validates the
replacement intersection while building the rewrite plan, before output opens.

Exact v13 verification passes: the fresh environment and reference lanes are
unchanged at 285/285, 4/4, and 14/14; both legitimate run-8 architectures
remain 14/14; all 71 behaviorally incorrect mutants are killed in the 72-case
audit; and the equivalent survivor passes 14/14 focused plus 127/127
pre-existing in 315.24 seconds. Calibration restarts at 0/10.

Revision v14 closes two rewrite gaps. One successful call now carries two
distinct replacements through both transports and checks both emitted headers
and payloads. The legacy single-part fixture now reads its exact header through
`TiledInputFile`, proving that the `type` attribute is absent before and after
an untouched rewrite. The reference performs a validated singular raw copy for
that typeless flat source instead of publishing `MultiPartInputFile`'s
auto-added type.

Exact v14 verification passes: fresh 285-target environment build, reference
4/4 existing and 14/14 focused, one independent run-8 implementation at 14/14,
all 73 incorrect mutants killed in the 74-case audit, and the equivalent
survivor at 14/14 focused plus 127/127 pre-existing in 324.87 seconds. The
former second run-8 pass is now correctly exposed at 13/14. Calibration restarts
at 0/10.

Revision v15 corrects the fairness issue in that legacy fixture. A
`loadImages()` result may expose either the raw typeless header used by the
existing singular reader or the synthesized type-bearing multipart view. The
test erases only `type` before comparing the complete returned header. The
separate rewrite checks remain exact and still require both untouched outputs
to stay typeless with unchanged headers and images.

Exact v15 verification passes: fresh 285-target environment build, reference
4/4 existing and 14/14 focused, and a legitimate raw-return-header architecture
at 14/14. All 73 incorrect variants are killed in the 74-case mutation audit;
the equivalent survivor passes 14/14 focused and 127/127 pre-existing tests in
320.70 seconds. Historical replay remains discriminating at 14/14, 13/14,
12/14, and 6/14. Calibration restarts at 0/10.

Revision v16 closes the remaining legacy rewrite state gap. A named typeless
ordinary flat single-part source now receives its exact-name replacement
through filename and stream rewrites; the untouched form still preserves its
raw header. The verifier derives the complete expected replacement header from
public `saveImages()` behavior and compares the decoded payload.

Exact v16 verification passes: fresh 285-target environment build, reference
4/4 existing and 14/14 focused, and one independent run-8 implementation at
14/14. All 74 incorrect variants are killed in the 75-case audit; the sole
equivalent survivor passes 14/14 focused and 127/127 pre-existing tests in
328.64 seconds. Historical controls score 13/14, 14/14, 12/14, and 6/14.
Calibration restarts at 0/10.
