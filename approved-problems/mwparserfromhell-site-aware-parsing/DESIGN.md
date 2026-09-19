# DESIGN.md — mwparserfromhell-site-aware-parsing

## 1. Title
Add site-aware parsing of linktrails, namespaces and recognised tags

## 2. Shape classification
- Shape: O-Composite-add (new feature spanning tokenizer(s) / builder / nodes / public API), with
  the S-I "per-flavour parity, each arm its own machinery" wall (two independent tokenizers that
  must agree). SHAPES.md § Pattern 11: "new feature spanning parser/compiler/VM/runtime".
- Pass rate target: 20-35% (measurable with Orion-only batches; ceiling 50%).
- Best agent: Orion (decisive C + Python work); Nova ships the Python arm and under-tests C.
- Dominant verdict: MISSED_REQUIREMENT (wiki-markup carve-out, colon polarity) + REGRESSION
  (profile-less behaviour, wiki-markup Tag nodes, lossless str()).
- Solver/our LOC ratio: ~1.3x.

## 3. Public API surface
- `mwparserfromhell.SiteInfo(linktrail="", namespaces=None, tags=None)` — immutable-by-convention
  profile. `linktrail`: a string, the characters allowed in a link trail. `namespaces`: a mapping of
  namespace name -> integer id (aliases map to the same id; 6 = file namespace, 14 = category
  namespace, as in MediaWiki). `tags`: an iterable of tag names the wiki recognises (extension tags
  AND the HTML tags it allows), or `None` meaning "every tag".
- `SiteInfo.linktrail`, `SiteInfo.namespaces` (dict), `SiteInfo.tags` (frozenset or None) — readers.
- `SiteInfo.namespace_of(title) -> int | None` — id of the plain-text prefix before the first colon
  (leading colon ignored), 0 when there is no recognised prefix, `None` when `namespaces` was not
  supplied. Name matching ignores case, surrounding whitespace, and treats spaces and underscores alike.
- `SiteInfo.is_tag(name) -> bool` — case-insensitive membership; always True when `tags is None`.
- `mwparserfromhell.parse(value, context=0, skip_style_tags=False, site=None)` and
  `Parser(site=None).parse(...)` / `parse_anything(..., site=None)` — the profile.
- `Wikilink.trail -> str` — the word-ending characters glued to the link ("" when none); settable.
- `Wikilink.namespace -> int | None` — see `namespace_of`; re-derived when `title` is reassigned.
- `str(Wikilink)` renders `[[title|text]]trail`; `Wikilink.__strip__` returns text (or title) plus
  trail; `Wikicode.strip_code`, `filter_wikilinks` and `str(Wikicode)` see the trail through the node.

## 4. Canonical output form
- A trail is the longest run of characters immediately after `]]` that all belong to `linktrail`;
  it stops at the first other character (space, newline, apostrophe, `<`, `{`, `[`, ...).
- No trail is ever attached when the link embeds a file (namespace 6, no leading colon) or assigns
  a category (namespace 14, no leading colon). A leading colon makes such a link ordinary again.
- Without a profile, or with an empty `linktrail`, no trail is attached and the characters remain
  ordinary text (byte-identical to today).
- `Wikilink.namespace` is `None` when parsed without namespace information, `0` for a title whose
  prefix is unknown (`[[Foo:Bar]]` with no `Foo` namespace), otherwise the id.
- Tag recognition: an XML-style tag whose name is not recognised is literal text, including its
  closing form; wiki markup that produces Tag nodes (`''`, `'''`, `*`, `#`, `;`, `:`, `----`, `{|`)
  is unaffected by `tags`.
- Round trip: `str(parse(text, site=...)) == text` for every input (lossless).
- Both tokenizers produce identical trees for every input and every profile.

## 5. Blind-spot pre-empts
- Rule-resolution / sibling API: "Parsing without a profile keeps today's behaviour exactly."
- Unstated inverse: "Wiki markup ... is unaffected by `tags`" (carve-out stated as a principle).
- Format-noun extent: "namespace" = the plain-text prefix before the FIRST colon of the title.
- Codebase-inferable (the one allowed): the C tokenizer must be rebuilt for its changes to take
  effect; test.sh rebuilds it (stated in meta as "the compiled tokenizer is rebuilt from source
  before the tests run").

## 6. Description draft
See meta.md (written after the spike). ~230 words, four paragraphs: ask + profile; trails and
namespaces; tags + carve-out + lossless; both tokenizers + profile-less unchanged.

## 7. File footprint
| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| NEW | src/mwparserfromhell/siteinfo.py | — | +90 | 60 | SiteInfo, normalisation, namespace_of, is_tag, trail scan helper |
| MODIFY | src/mwparserfromhell/parser/tokenizer.py | 1596 | +70 | 50 | site on Tokenizer, tag gate at open/close/invalid-start, trail scan after `]]` |
| MODIFY | src/mwparserfromhell/parser/ctokenizer/tokenizer.c | 328 | +60 | 45 | init kwarg, store profile + trail set, dealloc |
| MODIFY | src/mwparserfromhell/parser/ctokenizer/tok_parse.c | 3119 | +150 | 110 | tag gate (3 sites), title reconstruction, eligibility call, UCS4 trail scan, WikilinkClose(trail=) emit |
| MODIFY | src/mwparserfromhell/parser/ctokenizer/common.h | — | +6 | 4 | struct fields |
| MODIFY | src/mwparserfromhell/parser/tokens.py | 107 | +0 | 0 | trail carried as a kwarg on the existing WikilinkClose token (a new token class leaked into test_tokens.py parametrization) |
| MODIFY | src/mwparserfromhell/parser/builder.py | 344 | +20 | 15 | attach trail, pass site to Wikilink |
| MODIFY | src/mwparserfromhell/parser/__init__.py | 86 | +15 | 10 | Parser(site=) plumbing |
| MODIFY | src/mwparserfromhell/utils.py + __init__.py | — | +20 | 12 | parse(site=), export |
| MODIFY | src/mwparserfromhell/nodes/wikilink.py | 110 | +60 | 45 | trail/namespace properties, str, strip, showtree |
TOTAL (measured, hook): 432 human-effective across 12 modified + 1 new (tok_parse.c 121+, siteinfo.py
146, tokenizer.py 31, tokenizer.c 31, wikilink.py 25, rest plumbing). Spike measured 400 before
tests were written.

## 8. Solution outline
- `SiteInfo._normalize(name)` -> casefold, strip, `_`->space, collapse spaces  (namespace matching rule)
- `SiteInfo.namespace_of(title)` -> strip leading colon, split at first colon, look up  (namespace rule)
- `SiteInfo.is_tag(name)` -> lowercase membership  (tag rule)
- `SiteInfo.trail_length(text, start)` -> count of leading chars in linktrail  (trail rule, Python arm)
- `SiteInfo.link_takes_trail(title)` -> not (ns in (6, 14) and no leading colon)  (eligibility)
- Tokenizer (py): `_handle_wikilink_end` reconstructs the title text from the stack up to the
  separator; if plain text and eligible, scans trail across regex segments, emits `WikilinkClose(trail=...)` instead of
  `WikilinkClose`. `_really_parse_tag` / `_handle_tag_open_close` / `_handle_invalid_tag_start`
  fail the route for unrecognised names.
- Tokenizer (C): same, with `PyUnicode_FindChar` over the linktrail string for membership so UCS1/2/4
  inputs behave identically; profile stored on the Tokenizer object, callbacks via the profile.
- Builder: `_handle_wikilink` reads `trail` off the `WikilinkClose` token; `Wikilink(title, text,
  trail=, site=)`.
- Node: `trail` str property, `namespace` property computed from `site`, str/strip/showtree.

## 9. Test file outline
Path: `tests/test_siteinfo_<hex>.py` (one file). Fixture `tokenizer` parametrized over
`("c", "py")` toggling `mwparserfromhell.parser.use_c`, asserting the C tokenizer is present.
Block 1 imports · Block 2 builders (`en()` profile, `ru()` profile, `tags_only()`, `ns_only()`,
`links(text, site)`, `kinds(text, site)`) · Block 3 assert helpers (`assert_roundtrip`,
`assert_nodes`) · Block 4 buckets:
- trail basics: attaches, longest run, stops at each stop class, empty linktrail, no profile
- trail x link form: plain / piped / pipe-trick / text with markup
- trail x namespace polarity: file/category with and without colon; unknown prefix; alias; case;
  underscore; whitespace; namespaces absent (File gets a trail)
- unicode trail set (Cyrillic) on both tokenizers, mixed-kind input
- tags gate: unknown open/close/self-closing become text; recognised parse; case-insensitive;
  unknown inside recognised parent; single-only `<br>` unknown; `tags=None`
- wiki-markup carve-out: `''i''`, lists, hr, tables still Tag nodes under a restrictive `tags`
- tags x headings: unclosed unknown tag no longer hides later headings (get_sections)
- node API: trail setter, namespace re-derived on title reassignment, str, strip_code, showtree
- profile-less parity: identical trees with and without `site=None` for a corpus of inputs
- both-tokenizer parity: same tree for a corpus of inputs under each profile
Target ~70 test functions, x2 tokenizers where parametrized.

## 10. Forced kwargs
`SiteInfo(linktrail: str = "", namespaces: Mapping[str, int] | None = None, tags: Iterable[str] | None = None)`;
`parse(..., site: SiteInfo | None = None)` keyword; `Wikilink(title, text=None, trail="", site=None)`.

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Two tokenizers, each its own machinery; C arm under-implemented or not rebuilt | S-I / F-12-like | A1 cross-section | implementation arm | all others (every cell x2) | agents patch tokenizer.py, run tests with the stale .so or skip C | "both the C and the pure-Python tokenizer" | every parametrized test under `c` |
| 2 | Wiki-markup Tag nodes must survive a restrictive `tags` | F-3 | S3 baseline via chokepoint | where the gate lives | 1 (C has its own tag sites) | gating in the builder / on tag name kills `''`, lists, tables | "wiki markup ... is unaffected by `tags`" | `italics_survive_restrictive_tags`, `list_markup_survives`, `table_survives` |
| 3 | Colon polarity x namespace kind x trail | F-10 | S2 composition | link form | 4 | eligibility keyed on prefix only; `[[:Category:X]]s` loses its trail | "A leading colon makes such a link ordinary" | off-diagonal cells |
| 4 | Namespace name normalisation + unknown prefix -> 0 | F-24 cousin / A8 | A8 | lookup rule | 3 | `Datei`/`datei`, `File_talk`, `[[ File :x]]`, `[[Foo:Bar]]` -> 0 not None | normalisation sentence | `namespace_lookup_*` |
| 5 | Non-Latin trail set in the C arm (UCS kinds) | A4 host-language | A4 | character model | 1 | byte/char comparisons in C | "characters" (contract already says it) | `cyrillic_trail_c` |
| 6 | Lossless rendering: trail must not be doubled as Text, str round-trips | F-17-like | S3 | tree shape | 3 | keep Text and set trail, or drop it | "the wikitext renders back unchanged" | `roundtrip_*`, `nodes_are_only_link` |
| 7 | Profile-less parity (old API unchanged) | F-20 | S3 | sibling API | 2 | gate default `tags=None` wrongly, trail on empty set | "without a profile keeps today's behaviour" | `no_profile_*` |
| 8 | Stray closing tag `</foo>` inside a recognised body must be gated too, or the recognised parent collapses to text | F-7 | S4 machinery-riding | close-form site | 2, 1 | agents gate only the open form; the mismatch path fails the whole enclosing route | "in both its opening and closing forms" | `unknown_tag_inside_recognized_tag_is_text` (kills 2 per arm when either gate is missing) |

## 11b. Cross-product matrix (trail x namespace polarity)
| | no colon | leading colon |
|---|---|---|
| main (`[[Foo]]`) | trail | trail |
| file (6) | NO trail (Text stays) | trail |
| category (14) | NO trail | trail |
| unknown prefix (`[[Foo:Bar]]`) | trail | trail |
| namespaces not supplied | trail even for File: | trail |
Times link form {plain, piped, pipe-trick} and tokenizer {C, Py}.

Scope audit: "namespace" = prefix before the FIRST colon only (`[[File:a:b]]` -> 6). Trail applies
per link, never across a following template/tag/link. Example audit: meta carries no worked example
of a profile beyond naming the three fields. Tolerance rules: none.

## 12. Tier + category
Olympus; feature-request ("Add ...").

## 13. Predicted pass rate
25-35% on an Orion mix. Levers: dual-arm C work (1), carve-out (2), colon cells (3), C Unicode (5),
lossless tree (6). Wrong Logic expected ~20%.

## 14. Quality-gate checklist
- [x] Phase 1 5/5 (hunt log + this file)
- [x] Phase 2 searches: `gh pr list/issue list -R earwig/mwparserfromhell --state all --search` for
      linktrail, "link trail", namespace, "recognized tags", "site config", word-ending; open PRs
      #301/#194/#335 are node-level File-link helpers (kept out of scope); issues #82, #305, #136
      read in full (no snippet implements this; #136 links PR #301 only).
- [x] Closest approved scaffold: `approved-problems/neva-array-bypass-generalization` (S-E generalisation) and
      `pulldown-cmark-gfm-autolinks` (parser feature in a markup parser)
- [x] Title verb-led; shape declared; API listed; canonical form; ≤1 codebase-inferable
- [x] Footprint sketched against real files; LOC buffer; helpers 1:1; test outline; kwargs
- [x] Traps: 7 rows, F-ids named, different axes, interdependence stated; § 11b filled
- [x] F-20 audit: profile-less path guarded both directions; F-21/F-24/F-25 considered (F-24 cousin = unknown prefix -> 0)
- [x] Representation pins: `trail` is a str, `namespace` an int or None, stated in meta
- [x] Category feature-request matches "Add"

## Why this is not a duplicate
`pulldown-cmark-gfm-autolinks` / `comrak-reference-style-links` are markdown SYNTAX extensions; this
is a configuration layer over a wikitext tokenizer pair with no syntax added. No workspace problem
touches wikitext. Sibling ecosystem (wikitextparser) documents the same gaps as unsupported.

## Predicted iteration cycles: 2
