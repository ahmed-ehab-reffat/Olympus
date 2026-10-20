SHELVED 2026-10-18: DERIVATIVE at the core-slice precheck. Overlap Blocker 170/372 = 45.7% (older layout-instancing task) and set-level Blocker 233/372 = 62.6% together with an older vertical-metrics task (that one alone Medium, 16.9%); a VVAR-tag precursor at 0% (Low). Not resubmittable. Entry: Instructions/TOO-EASY.md.

# feedback.md - allsorts-instance-layout-variations

Repo: yeslogic/allsorts @ efab0fc769287f4ced68bbd723c328c9d9b89698 (Rust, Apache-2.0, 801 stars)
Lane (hunter #64, REPO-HUNT-2026-10-14-B): `variations::instance` also instances GSUB/GPOS
FeatureVariations, GPOS variation deltas, the GDEF variation store and vhea/vmtx, so the static
instance shapes like the variable font at that tuple.

## Status (SLICE, 2026-10-15)

- Core slice built: 5 files, human-effective 308 (hook), 10 new tests, all compile on base (base API
  only) and fail there behaviourally; all pass with the solution; full suite 777 + 10 green.
- Gates run before any code: Gate 1 runtime probe (instance kerns "ba" -16, variable font at the same
  tuple -10), Gates 5/6/7/7b/8/9, SIX-CHECK 1-6, canonical-org PR-DIFF exclusivity: all clean. Details in
  DESIGN.md.
- Docker clean room passed (uid 1000 / root / 4242, `--network none`): base 800/0 with and without the
  solution, new 10/10 fail on base and 10/10 pass with it; base and new each run 3x as root, identical.
  test.sh fix during validation: cargo2junit exits non-zero when any test fails, so the XML is now
  accepted on content (parses, has testcases), not on cargo2junit's exit code.
- OWED (human): picker check (Requirement 0) and the platform precheck (dedupe against rival pipeline
  submissions; fontTools' instancer makes the capability outsider-nameable, derivative MEDIUM).

## Decisions taken unattended (conservative choices)

- Read in full: CLAUDE.md, olympus-author SKILL.md, HARDENING.md, TOO-EASY.md taxonomy + pre-pick guard +
  difficulty-rigor protocol, failure-patterns.md targeting table (section 5) and catalogue headings. The
  full 600 KB failure-patterns.md body was not read line by line (context budget); FINISH should consult
  the F-8, F-9, F-67 and F-80 entries in full before adding cells.
- Tests use only base API (no new public items), so a missing method can never wipe the suite at compile
  time. The VVAR tag is spelled with `tag!(b"VVAR")` in the test for that reason.
- test.sh base mode runs `--lib` plus every integration test except the new one and `common`. Doc tests
  are NOT in base mode: their JUnit ids carry source line numbers ("apply (line 1300)"), which shift as soon
  as an agent edits gsub.rs or layout.rs above them.
- The reference mirrors allsorts' `Adjust::apply`: placement deltas are baked only when a base placement
  is non-zero, and records with a non-zero y_advance are left alone. No slice test pins those quirks (the
  contract is relational, so a solver that fixes the shaper instead also passes). FINISH must decide
  whether to state them, cap them, or leave them untested.
- A value record that has a VariationIndex device but not the value field it adjusts is skipped by the
  reference (the delta is lost). No test covers it. FINISH: widen the record or cap the domain in meta.
- Every new test builds a fresh `Font` per shaping call: the base GSUB lookup cache (gsub.rs:1213) keys on
  script/lang/mask only, so one `Font` shaped at two tuples returns the first tuple's lookups.

## FINISH plan (from DESIGN.md section 9 / 11b)

Alias cells (feature table shared by two scripts, substitution for one index; PairSet shared by two first
glyphs), two FeatureVariations records at a tuple matching both, two-axis condition on Inter, Extension
lookups (GSUB 7, GPOS 9), PairPos fmt2 and SinglePos with devices, a lookup reachable only through an
alternate feature with device deltas inside (F-10 cell), a GSUB over 64 KB (relocation), VVAR tsb
mapping, CFF2 + VVAR, mark positioning with GDEF classes kept. Stated in meta.md but not yet tested (FP exposure, close in
FINISH): VVAR tsb mapping, CFF2 without VVAR keeping its vertical metrics, vhea line gap and caret MVAR
deltas. Cold image build measured 450 s for the RUN step on a loaded host: re-time on FINISH (L62
limit 600 s). Anchor lever (+100-120 eff): shaper honours
format-3 anchor deltas at a tuple and the instancer bakes them.

## Attempt history

- 2026-10-15 SLICE: built and validated locally; patches generated against BASE_COMMIT.
- 2026-10-18 core-slice precheck: REJECTED, derivative (see top). Shelved to rejected/.
