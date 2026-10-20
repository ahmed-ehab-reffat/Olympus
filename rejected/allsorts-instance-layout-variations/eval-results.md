# eval-results.md - allsorts-instance-layout-variations

No platform batch yet. Local validation numbers are logged below.

## Local validation

### 2026-10-15 SLICE, local host (cargo 1.98, --no-default-features --features flate2_rust)
- Gate 1 runtime probe (base): SourceSansVariable-Roman.abc.otf instanced at wght 900 and shaped with no
  tuple kerns "ba" at -16 (and "cc" at -16); the variable font shaped at the same tuple gives -10 and -30.
- Base suite on base: 777 passed / 0 failed / 37 ignored, run twice, identical counts.
- New tests on base: 8/8 FAIL (behavioural, they compile on base: only base API is used).
- New tests with solution: 8/8 pass. Full suite with solution: 785 passed / 0 failed.
- Mutations: rvrn gate reverted -> rvrn_substitution_survives_instancing fails alone; device offset not
  zeroed after baking -> kerning_subtable_shared_by_two_lookups fails alone.
- test.sh base mode locally: 814 testcases (doc tests then dropped from base: their ids carry line numbers),
  0 failures, no duplicate classname::name ids, no "::" left.
- effective_loc_check.py solution.patch: human-effective 300, raw 393, padding-floor 50, 5 files
  (layout/instance.rs 212, variations.rs 79, layout.rs 7, gsub.rs 1, tag.rs 1).
- After rustfmt + two vertical tests (vhea MVAR, phantom-point vmtx): 10 new tests, 10/10 FAIL on base,
  10/10 pass with solution; human-effective 308 (raw 405, padding-floor 50, 5 files).
- Feature stubs (solution applied, one part no-op'd): FeatureVariations bake stubbed -> 4 red (rvrn, liga,
  GPOS FV, drop-FV); delta baking stubbed -> 3 red (shared subtable, pair kern, Source Sans); vmtx stubbed
  -> 2 red (VVAR, phantom points). The MVAR vhea test is red on base.

### 2026-10-15 SLICE, Docker clean room (factory-allsorts-instance-layout-variations)
- Image built from a clean clone at BASE (with .git): RUN step 450 s on a loaded host (context load 191 s,
  export 638 s, 22 min wall, about 15 min of it queued behind other sessions' builds). Image 4.9 GB.
- `--network none`, uid 1000: base-on-base rc 0 (800 cases, 0 fail, 36 skipped); new-on-base rc 1 (10/10
  fail, after the cargo2junit exit-code fix in test.sh); solution applied (verified landed): base rc 0
  (800/0), new rc 0 (10/10 pass).
- `--network none`, root: base-on-base x3, new-on-base x3, base-on-solution x3, new-on-solution x3 - every
  run identical per (classname, name, verdict) (order-insensitive hash), no duplicate ids, no "::".
- uid 4242 (no passwd entry): new-on-base 10/10 fail, new-on-solution 10/10 pass.
- Broken build (syntax error appended to src/variations.rs) in new mode: fallback writes the same 10 real
  test ids as failures (classname "", same as cargo2junit's), rc 1.
- Patches apply in both orders on a clean clone and reverse cleanly.
