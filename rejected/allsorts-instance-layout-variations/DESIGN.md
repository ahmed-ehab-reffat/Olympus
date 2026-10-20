# DESIGN.md - allsorts-instance-layout-variations

Repo yeslogic/allsorts (canonical slug confirmed via `gh api`), base `efab0fc769287f4ced68bbd723c328c9d9b89698`
(master HEAD, 2026-05-13). Rust, Apache-2.0, 801 stars. Lane from hunter #64
(`Instructions/repo-hunt-logs/REPO-HUNT-2026-10-14-B.md`).

## Phase 1 - Repo understanding

**Architecture (one paragraph).** allsorts is a font parser, shaping engine and subsetter. `binary/` holds a
zero-copy reader (`ReadScope`, `ReadCtxt`, `ReadBinary`/`ReadBinaryDep`) and a writer (`WriteContext`);
`tables/` parses the sfnt tables (head, hhea/hmtx, glyf/loca, cmap, OS/2, name, post) with a
`variable_fonts/` sub-tree (fvar/avar normalisation to an `OwnedTuple`, gvar, HVAR, MVAR, cvar, STAT, the
`ItemVariationStore` and its `owned` copy). `layout.rs` parses GDEF/GSUB/GPOS into `LayoutTable<T>`
(ScriptList, FeatureList, LookupList, FeatureVariations) and per-lookup structures with a cache;
`gsub.rs`/`gpos.rs` (plus `scripts/` per complex script) run the shaper, taking an optional variation
`Tuple` that selects FeatureVariations alternates and GPOS device deltas at run time. `font.rs` is the
`Font` facade (`shape`, `map_glyphs`, metrics). `subset.rs` holds `FontBuilder`, which `variations.rs` uses
to write a static instance: it rebuilds head/hhea/hmtx/maxp/name/OS2/post/cvt/glyf (or CFF2) at the
requested location and copies every other non-`*VAR` table verbatim.

**Five subsystems and boundaries.**
1. Binary read/write (`binary/`): no font semantics.
2. Table parsers (`tables/`, `tables/variable_fonts/`): parse only, no shaping.
3. Layout model (`layout.rs`): GSUB/GPOS/GDEF parsing, FeatureVariations matching, ValueRecord/Device parsing.
4. Shaper (`gsub.rs`, `gpos.rs`, `scripts/`, `glyph_position.rs`, `font.rs`): consumes the layout model + tuple.
5. Writers (`subset.rs` FontBuilder, `variations.rs` instancer, `cff/` CFF2 instancing).

**High-entanglement zones.**
- `variations::instance` (variations.rs:126-438): reads ~20 tables, applies gvar/HVAR/MVAR/cvar, writes through FontBuilder.
- The tuple path in the shaper: `LayoutTable::feature_variations` (layout.rs:925) used by every script shaper, `apply_rvrn` gated on `tuple.is_some()` (gsub.rs:1391), `Adjust::apply` delta logic (gpos.rs:547-571).
- The GSUB lookup cache (gsub.rs:1213): keyed on (script, lang, mask) only, NOT on the tuple, so one `Font` shaped at two tuples reuses the first tuple's lookups. Tests must use a fresh `Font` per shaping call.

**Test framework.** `cargo test --no-default-features --features flate2_rust` (default `flate2_zlib` pulls C
zlib). Unit tests inline (`#[cfg(test)] mod tests`, e.g. variations.rs:1062-1393), integration tests in
`tests/*.rs`. Template: `tests/shape.rs` / `tests/opentype.rs` (free functions + `#[test]`, no comments
in bodies). 777 tests + 37 ignored, ~3 min in debug, deterministic over 2 runs.

## Phase 2 - Existing-PR / publicly-solved check (run 2026-10-15)

- `gh api repos/yeslogic/allsorts -q .full_name` -> `yeslogic/allsorts` (not moved).
- PR search (all states): instance, instancing, FeatureVariations, "feature variations", "variable font", vmtx,
  VVAR, "GPOS variation", GDEF, rvrn, "static instance", "device delta", variation, variable: hits #76
  (caching, 2022), #121 (subset_and_map, files subset.rs + tests only), #99 (table tags), #85 (morx). None
  touches variations.rs or layout instancing. Diff of #121 read: subset.rs/examples/tests only.
- Issue search: #51 Variable fonts (closed by 0.15 glyph instancing; no layout discussion), #114 (outlining
  glyf variations), #59 (vhea/vmtx SUBSETTING, adjacent, open, no PR), #64 (GSUB/GPOS subsetting), #116
  (COLR paint variations). No maintainer decline, no "by design".
- Branches ahead of master touching variations.rs/gsub.rs/gpos.rs/layout.rs: allsorts-0.14 (mark-to-mark),
  mikeday/fixes (clippy), wezm/subset-profile (subset tables). None in the lane.
- CHANGELOG: no "removed / no longer" for layout instancing; instancing added in 0.15 for glyphs only.
- Cross-repo: Rust code search for FeatureVariations instancing: fontations `skera` has explicit
  "TODO: support instancing" (gsub.rs:31, gpos.rs:39, lib.rs:873/1248) - not implemented; ttf-parser/harfrust
  read only. fontTools `varLib.instancer` (Python) implements the general algorithm: outsider-nameable,
  derivative MEDIUM. Mitigation: the contract is written on allsorts' own shaper (instance shaped with no
  tuple == variable font shaped at the tuple), the walls (rvrn gate, no layout writer, shaper quirks) are
  repo-specific. Platform precheck is the only instrument that sees rival pipeline submissions: OWED.
- Local dedup: no allsorts problem in approved-problems/, problems/, new-problems/, rejected/. Nearest class:
  fonttools-color-merge (different repo, merge of color tables).

SIX-CHECK: 1-4 clean (above). 5: base == master HEAD, `git log` for variations.rs shows no commit in the
last 12 months. 6: functional check reproduced the gap at runtime (below).

## Gate results (PICK-FILTER)

- **Gate 1 (behavioural F2P), runtime probe:** SourceSansVariable-Roman.abc.otf instanced at wght 900 and
  shaped with no tuple kerns "ba" -16 / "cc" -16; the variable font shaped at the same tuple gives -10 / -30.
  Base output is observably wrong through the public API.
- **Gate 5 (cold):** nobody is building the capability (no PR, branch, issue claim or recent commit).
- **Gate 6 (reproduce on base):** done through `variations::instance` + `Font::shape`.
- **Gate 7 / 7b (dedup, exclusivity):** clean (Phase 2).
- **Gate 8 (defined behaviour):** OpenType defines FeatureVariations, ItemVariationStore deltas, VVAR and
  MVAR; the oracle is allsorts' own shaper at the tuple. No maintainer statement against.
- **Gate 9 (flaky):** 777/0/37 twice, identical.
- **Gate 4 (LOC), measured on the written slice:** 300 human-effective (hook), 5 files.

## 1. Title

Add layout and vertical metric instancing to font variations

## 2. Shape classification

- Shape: O-Pipeline-hard flavour (existing pipeline `instance()` gains new stages that must agree with a
  second subsystem, the shaper), cross-subsystem: instancer + layout byte rewriting + shaper.
- Best agent (old data): Orion-alone for pipeline-hard. Under the 2026-10-09 gate: Nova 0/8 target, Orion 1/4.
- Dominant verdict expected: MISSED_REQUIREMENT on the rvrn gate and aliasing cells, REGRESSION on relocation.

## 3. Public API surface

No new public API. `allsorts::variations::instance(provider, user_instance) -> Result<(Vec<u8>, OwnedTuple), VariationError>`
changes behaviour. Tests also read the output through existing public API: `Font::shape`,
`Font::vertical_advance`, `LayoutTable<GSUB|GPOS>::opt_feature_variations`, `GDEFTable::opt_item_variation_store`,
`HheaTable`, `HmtxTable::metric`. Every test compiles on base (no compile-wipe risk).

## 4. Canonical output form

- Equality is on `(glyph_index, kerning, placement)` per output glyph from `Font::shape` with
  `FeatureMask::default_mask()`, `kerning = true`, lang DFLT, for scripts DFLT and latn.
- Rounding: deltas are rounded to the nearest integer (f32 `round`, as the shaper does) per field, then added.
- Vertical advance = vmtx + VVAR delta rounded, clamped to u16; vhea advance max = max of new advances.

## 5. Blind-spot pre-empts

- "for every script and language the font has" (rule-resolution: a substitution keyed by feature index,
  not by tag; aliasing cell).
- No sentence about rvrn, the lookup cache, shared subtables or offsets (Rule 7: these are the traps).

## 6. Description draft

See `meta.md` (slice draft). Human-voice register, one long line per paragraph, ASCII.

## 7. File footprint (measured, slice)

| Action | Path | Raw | Human-eff |
|---|---|---|---|
| NEW | src/layout/instance.rs | 285 | 212 |
| MODIFY | src/variations.rs | 95 | 79 |
| MODIFY | src/layout.rs | 10 | 7 |
| MODIFY | src/gsub.rs | 1 | 1 |
| MODIFY | src/tag.rs | 2 | 1 |
| TOTAL | 5 files | 393 | 300 |

FINISH levers (genuine scope, not padding), each a behaviour change:
- Anchor deltas (hunter lift lever, ~+100-120): make the shaper honour format-3 anchor VariationIndex
  devices at a tuple (gpos.rs + layout.rs Anchor model), and bake them in the instance (format 3 -> 1 in
  place). Turns the lane into shaper + instancer, closes the "allsorts ignores anchor deltas" oracle quirk
  instead of stating it.
- Device-only value records (format has XAdvDevice without XAdvance): today the reference skips them
  (delta lost). Rebuild the subtable with a widened ValueFormat, or swap device bit for value bit in place.
- Relocation robustness: offsets past 64K (rewrite unsubstituted feature tables into the new FeatureList
  when the original is out of 16-bit reach).

## 8. Solution outline (as built)

- `layout::instance::instance_layout::<T>(data, tuple)`: match FeatureVariations with the repo's
  `FeatureVariationsOwned::matches`, rebuild the FeatureList right after a v1.0 header (alternate tables
  written inline, unsubstituted records pointing into the relocated original body), relocate ScriptList and
  LookupList offsets, drop FeatureVariations.
- `layout::instance::instance_gpos(data, tuple, store)`: the above, then walk every lookup (following
  Extension type 9), SinglePos fmt1/2 and PairPos fmt1 (devices relative to the PairSet) / fmt2 (relative
  to the subtable), add the rounded VariationIndex delta to its value field and zero the device offset so
  shared subtables are baked once. Mirrors `Adjust::apply`: placement deltas only when a base placement is
  non-zero, nothing when y_advance is non-zero.
- `layout::instance::drop_gdef_variation_store`: zero the GDEF 1.3 store offset.
- `gsub::apply`: run `rvrn` when the table has an rvrn feature even without a tuple
  (`LayoutTable::has_feature`).
- `variations::instance`: read VVAR, `create_vmtx_table` (VVAR deltas, else gvar phantom points 3/4,
  tsb from VVAR tsb mapping or pp3 - yMax), MVAR into vhea, write vhea/vmtx, GSUB/GPOS/GDEF.

## 9. Test outline

`tests/instance_layout_6ffe2c.rs` (one new file). Block 2 builders: a byte-level `Layout` builder for
GSUB/GPOS v1.1 (ScriptList, FeatureList with shareable tables, LookupList with shareable subtables,
FeatureVariations with condition sets), `single_subst`, `pair_kern` (PairPos fmt1 + VariationIndex
device), `var_store`, `gdef_with_store`, VVAR/vhea/vmtx bytes, and `font_with` which re-assembles an sfnt
from a repo font with tables replaced. Assertions: relational (`instance` shaped with no tuple ==
variable shaped at the tuple) plus a non-vacuity guard (variable at the tuple != variable at default) and
absolute values where the rule is stated (vertical advances, alternate liga output).

Slice tests (8): real CFF2 font kerning at 300/650/900; rvrn substitution; alternate liga with more
lookups than the default; PairPos fmt1 device delta; subtable shared by two lookups; FeatureVariations and
GDEF store dropped; GPOS FeatureVariations swapping kern lookups; VVAR vertical advances.

FINISH additions (F-10 / trap cells): feature table shared by two scripts with a substitution for one
index only (alias cell); alternates under DFLT vs latn; two FeatureVariations records (first match wins)
at a tuple matching both; a two-axis condition set on Inter (wght x slnt); Extension-wrapped PairPos and
SingleSubst; PairPos fmt2 and SinglePos fmt1/fmt2 with devices; a PairSet shared by two first glyphs; a
lookup reachable only through an alternate feature; a GSUB larger than 64 KB (relocation); GPOS
FeatureVariations x device deltas in the alternate lookup (cross-product cell); phantom-point vmtx (no
VVAR); vhea MVAR; CFF2 + VVAR; mark positioning through a GDEF whose classes must survive.

## 10. Forced bounds

None: no generics or signatures in tests beyond base API.

## 11. Trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | Shaper runs `rvrn` only when a tuple is passed (gsub.rs:1391); a correct bake of rvrn still loses the substitution because the instance is shaped with no tuple | F-9 / F-67 (second engine path) | S4 machinery-riding | which shaper path runs the baked feature | #2 (the bake must be right before the gate shows) | the failing glyph points at the bake, which is correct | "shaped with Font::shape and no variation tuple, same glyphs" | rvrn_substitution_survives_instancing |
| 2 | FeatureList rebuild: alternate has more lookups than the default (rvrn default is empty) so in-place edit is impossible; 16-bit relocation of ScriptList/LookupList; > 64 KB tables | F-1 | A1 cross-section write | byte layout | #1, #3 | agents append or edit in place on small fixtures | none (Rule 7) | heavy_instance_applies_alternate_liga_lookups (+ FINISH 64 KB cell) |
| 3 | Shared structures (subtable shared by two lookups, PairSet shared, feature table shared by two feature records) get baked twice or substituted for both | F-80 alias analogue | S2 composition | sharing | #2 | a per-lookup walk without zeroing doubles the delta; an offset->table map substitutes both aliases | "for every script and language the font has" | kerning_subtable_shared_by_two_lookups (+ FINISH alias cells) |
| 4 | Oracle semantics: allsorts drops placement deltas when both base placements are 0 and ignores records with y_advance; PairPos fmt1 devices are relative to the PairSet | F-8 (oracle) | A5 naive-dominant reading | value-record semantics | - | spec-faithful baking diverges from the repo shaper | relational contract only; FINISH decides whether to state or cap | pair_kerning_delta_is_baked (+ FINISH fmt2/SinglePos cells) |
| 5 | Vertical metrics: VVAR vs phantom points, tsb from pp3 - yMax, vhea via MVAR (base passes `&mut None`) | F-39-ish (helper fed a new regime) | A3 reuse missing arm | metrics | - | agents reuse `apply_hvar` whose lsb fallback reads pp1.x | stated in full | vertical_metrics_follow_vvar (+ FINISH phantom / MVAR) |

## 11b. Cross-product matrix (F-10)

| | GSUB FeatureVariations | GPOS FeatureVariations | GPOS device deltas |
|---|---|---|---|
| default FeatureList feature | liga alternate (slice) | kern alternate (slice) | PairPos fmt1 (slice) |
| rvrn | rvrn (slice) | n/a | n/a |
| alternate-only lookup | FINISH | FINISH | FINISH: device delta inside a lookup only the alternate kern feature reaches |
| shared table / subtable | FINISH alias | FINISH alias | shared subtable (slice) |
| Extension-wrapped | FINISH | FINISH | FINISH |

## 12. Tier + category

Olympus, feature-request ("Add ..."), Issue N/A.

## 13. Predicted per-agent result

Nova 0/8: rvrn gate + aliasing + PairPos-fmt1 parent offsets + relocation, each a separate cross-file
discovery. Orion ~1/4 once FINISH cells land. Reading surface: variations.rs 1400, layout.rs 3600, gsub.rs
1870, gpos.rs 1000, variable_fonts ~2400, subset.rs 1900, font.rs 1580 lines plus OpenType byte layouts
reconstructed by hand: Nova should work long (>256k average expected).

## 14. Quality-gate checklist (slice state)

- [x] Repo understanding 5/5. [x] Phase 2 clean (commands above). [x] Title verb-led.
- [x] No new public API; every test compiles on base. [x] Canonical form stated.
- [x] File footprint measured: 300 human-eff / 5 files.
- [x] Traps on different axes, #1-#2-#3 interdependent.
- [ ] FINISH: alias cells, 64 KB relocation, Extension, fmt2/SinglePos, F-10 alternate-only lookup cell,
      phantom-point vmtx, vhea MVAR, anchor lever.
- [ ] Platform precheck (dedupe vs rival pipeline): OWED (human).

## Why this is not a duplicate

No approved or in-flight problem on allsorts or on font instancing. fonttools-color-merge merges color
tables in a different repo and language. The capability (fontTools instancer) is outsider-nameable, so the
precheck is the real test.

Predicted iteration cycles: 3.
