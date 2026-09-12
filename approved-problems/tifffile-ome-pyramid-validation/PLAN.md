# Plan - tifffile OME pyramid validation

Status: `Level 13 verified; exact-version false-positive audit complete;
calibration is 0/10 after the optional-codec fixture fairness repair`.

Repository: `cgohlke/tifffile`

Pin: `940f7630df48edf8e13913962035ed80b408b5f4`

Production language: Python

Task type: feature request

1. [complete] Freeze the upstream pin and record repository health, license,
   provenance, ownership, and local-similarity evidence.
2. [complete] Remove the original normalization half of the seed. Repairing or
   rewriting malformed pyramids would require private policy not supplied by
   OME or tifffile.
3. [complete] Demonstrate the validation gap with small generated OME-TIFFs and
   identify independent standard-backed topology boundaries.
4. [complete] Read the required local history and representative raw solver
   trajectories, then record the resulting discriminator ledger in
   `DESIGN.md`.
5. [complete] Verify a bounded repository test lane and the adjacent SubIFD
   writer tests in an official Python image with networking disabled.
6. [complete] Freeze
   `TiffFile.validate_ome_pyramid(*, strict=False, assert_=True)` and separate
   required OME storage rules from recommendation-only strict checks.
7. [complete] Run and record the repository-grounded false-positive audit for
   the exact artifacts. One meaningful survivor caused the addition of the
   direct tag-330 reachability discriminator; the initial 20-mutant set had no
   focused survivor.
8. [complete] Create the participant prompt, synthetic black-box tests,
   architecture-neutral reference, solution approach, and Dockerfile. Verify
   pristine, test-only, solution-only, test-then-solution, and
   solution-then-test states offline.
9. [complete] Read `CALIBRATION_STRATEGY.md` and record L1 as immutable and
   uncalibrated at 0/10. No run from a future revised artifact set may count
   toward this level.
10. [complete] Replace the unsupported Python-specific base with the permitted
    `public.ecr.aws/d3j8x8q7/olympus-base:latest`, rebuild with `--pull`, and
    repeat the exact patch-state and 20-mutant audits offline.
11. [complete] Reflow the four participant-facing description paragraphs
    without semantic changes, update the immutable `meta.md` hash, and repeat
    the patch-state and 20-mutant audits offline.
12. [complete] Remove three redundant prompt phrases, generate the random test
    suffix `a0d7bb` with `openssl rand -hex 3`, rename every harness reference,
    and repeat the exact patch-state and 20-mutant audits offline.
13. [complete] Close the fairness review by explicitly prohibiting every
    `OmeXml.validate` call and replacing the PlaneCount mutation with a genuine
    mapped reference to missing primary IFD 2. Repeat the patch-state and
    20-mutant audits offline.
14. [complete] Refresh the design gate for the S1/T4 review, materialize every
    mapped primary IFD for base-shape checks, add nonzero unreadable-offset and
    combined-bit probes, and repeat the 21-case matrix and 23-mutant audit.
15. [complete] Refresh the design and false-positive gates for multi-file OME,
    add an offline two-companion fixture with valid and secondary-only invalid
    topology, preserve closed companion lifecycle, and repeat the 24-case
    matrix and 27-mutant audit.
16. [complete] Remove the redundant owning-file summary, preserve the explicit
    companion lifecycle and precise structural rules, and repeat the 24-case
    matrix and 27-mutant audit for the new prompt hash.
17. [complete] Refresh the trajectory-informed design and false-positive gates
    for strict-shape isolation, split axes from nonspatial-size fixtures, and
    repeat the 25-case matrix and 29-mutant audit offline.
18. [complete] Repair the platform environment by exporting tifffile's six
    repository-supported resource and external-data controls from the
    Dockerfile. Rebuild with `--pull`, verify direct build and pytest quality
    commands, and repeat the exact matrix and 29-mutant audit.
19. [complete] Refresh the trajectory-informed design and false-positive gates
    for companion-state symmetry, make prior open/closed restoration explicit,
    add the already-open case, and repeat the 26-case matrix and 30-mutant audit.
20. [complete] Inspect all five raw Level 1 solver bundles, record the
    trajectory-informed gate and revised discriminator ledger, close strict
    area-order, independent-axis, equal-level-count, mixed-layout, and
    companion failure-lifecycle gaps, and replay every saved solver patch.
21. [complete] Refreeze as Level 2 at 0/10, repeat the 36-case four-state matrix
    in both patch orders, kill all 40 isolated mutants, and verify direct build
    and pytest on ARM64 and AMD64 without launching a cold solver.
22. [complete] Refresh the mandatory design gate for an unreopenable mapped
    companion, add black-box return/raise coverage using a moved closed
    companion path, isolate the reopen-I/O mutant, and refreeze as Level 3.
23. [complete] Repeat the 38-case four-state matrix in both patch orders, kill
    all 41 mutants, replay all five saved patches, and verify direct build and
    pytest on ARM64 and AMD64 without launching a cold solver.
24. [complete] Bind all ten `agent-runs2` bundles to the exact Level 3 prompt
    and hidden-test contents, inspect the raw pass, near-pass, and broad-failure
    trajectories, and record the completed 4/10 batch.
25. [complete] Replay all ten patches offline, classify every failing assertion
    against the public contract, confirm all baselines and environment
    assessments, and run audit-only value-5 and private-tag probes without
    changing the frozen artifacts.
26. [complete] Apply the requested review fixes despite the calibration reset:
    remove the ambiguous unrelated-tag promise and add an independent legal
    `NewSubFileType=5` strict-positive case.
27. [complete] Refreeze as Level 4, repeat both patch orders and the complete
    offline matrix, kill all 42 mutants, replay all ten saved L3 patches, and
    reset calibration to 0/10.
28. [complete] Record the mixed-layout direction review in the design gate and
    parametrize the existing positive across tiled-base/stripped-child and
    stripped-base/tiled-child storage.
29. [complete] Refreeze as Level 5, repeat the complete offline matrix, kill
    all 43 mutants including an isolated directional-layout mutant, and replay
    all ten saved patches.
30. [complete] Isolate the homogeneous-children survivor, record the sibling
    storage-independence gate, and add a mixed tiled/stripped child parameter.
31. [complete] Refreeze as Level 6, repeat the complete offline matrix, kill
    all 44 mutants, and replay all ten saved patches.
32. [complete] Refresh the trajectory-informed gate for strict assertion
    routing, cross-series ownership, empty OME-series vacuity, independent
    tile sizes, and unit-axis ceiling division; add one isolated probe for
    each public boundary.
33. [complete] Refreeze as Level 7, repeat both patch orders and the complete
    ARM64/AMD64 offline matrix, kill all 49 mutants, and replay all ten saved
    Level 3 patches without launching a cold solver.
34. [complete] Accept the fairness finding and remove the undefined empty-series
    result instead of expanding the prompt. Refresh the trajectory-informed
    gate for universal later-child checks, storage allowlists, alternate pixel
    decoding, and full-resolution Y agreement.
35. [complete] Refreeze as Level 8, repeat both patch orders and the complete
    ARM64/AMD64 offline matrix, kill all 57 actionable mutants, withdraw the
    empty-series mutant, and replay all ten saved patches without a cold solver.
36. [complete] Audit every delivered `agent-runs3` bundle, record the ten
    substantive Level 8 evaluations as 5/10, measure the one-file/360-line
    successful median, and classify the two empty-patch runs as agent early
    terminations rather than environment crashes.
37. [complete] Refresh the mandatory design gate for global odd-factor
    candidate retention and non-I/O metadata exception normalization, then add
    one isolated public probe for each demonstrated survivor.
38. [complete] Refreeze as Level 9, repeat both patch orders and the complete
    ARM64/AMD64 matrix, run all 60 mutants through focused and pre-existing
    lanes, and replay all ten Level 3 patches plus all fourteen run-3 bundles
    without a cold solver.
39. [complete] Refresh the mandatory gate for the description-internal wording
    and small-parent factor-domain review, then add one isolated public positive
    and correct the reference candidate bound.
40. [complete] Refreeze as Level 10, repeat both patch orders and the complete
    ARM64/AMD64 matrix, run all 61 mutants through focused and pre-existing
    lanes, and replay every Level 3 and run-3 patch without a cold solver.
41. [complete] Accept the fairness finding, withdraw the even small-parent
    factor positive, restore the repository-aligned reference bound, and retain
    only the observable companion lifecycle wording cleanup.
42. [complete] Refreeze as Level 11, repeat both patch orders, the full
    ARM64/AMD64 quality matrix, all 60 retained mutation trees, and every saved
    replay without launching a cold solver.
43. [complete] Repeat the trajectory-informed gate for companion primary-chain
    coverage and strict factor performance; extend the existing mapping
    discriminator without adding a timing oracle.
44. [complete] Refreeze as Level 12, repeat both patch orders, the full
    ARM64/AMD64 quality matrix, all 61 retained mutation trees, arithmetic
    equivalence checks, and every saved replay without a cold solver.
45. [complete] Accept the optional-codec fairness finding, record the Level 13
    trajectory gate, and guard only the PackBits/LZW/ZSTD writer fixture using
    the repository's Imagecodecs availability policy.
46. [complete] Refreeze as Level 13, repeat both patch orders, normal and
    no-codec ARM64/AMD64 focused runs, all retained mutants and saved replays,
    the bounded lane, and the complete quality matrix without a cold solver.
47. [pending] Launch a fresh ten-run calibration batch only if Level 13 is to
    be retained despite the demonstrated one-production-file horizon.

The initial 80-150 production-line estimate was a forecast, not a rejection
condition; the current reference has 196 strict-effective additions. Five
successful Level 8 solvers had a 360-line median but touched only one production
file, and the platform message metric was unavailable. Those runs remain
architecture and fairness evidence but cannot count toward L12 after the hidden
suite changed, or toward Level 13 after the verifier's optional-codec fairness
repair.
