# DESIGN — pulldown-cmark-gfm-autolinks

## Pick (gate record, 2026-07-21)
GFM extended autolinks (bare `www.`/`http(s)://`/email URLs), behind a new `ENABLE_BARE_URL_AUTOLINKS`
option. Repo pulldown-cmark @ 68afb08, MIT, 2.7k star, active, 36k LOC, not saturated, 0 subs.
- Exclusivity (7b): CLEAN. No open PR; all autolink PRs are CLOSED bug-fixes for the existing
  `<...>` syntax. Issue #695 requests it; maintainers confirm "pulldown_cmark does not support
  bare URLs ... should be a new feature behind a flag." DEFINED + blessed, not declined.
- Cold (5): unimplemented, no churn. F2P (1): base renders bare URLs as literal text.
- Defined (8): GFM spec section 6.9 fully specifies the algorithm.

## HARDENING analysis (why this is hard-yet-fair, per HARDENING.md)
Difficulty lives in DOING (integration), not KNOWING (the spec rules are stated). Lead + support traps:
- **S3 (lead) baseline preservation through a shared chokepoint:** the natural impl scans ALL text
  and autolinks inside code spans / existing links / autolinks / image alt / link destinations,
  regressing the 1324-test baseline. The failing tests are BASE tests (misdirecting away from the
  feature). Fix = suppress detection inside those contexts (a discovery about the event stream,
  not stated as a fix). Base mode runs the full suite = the shared-path integration test.
- **S4 machinery-riding:** autolinks must survive EVERY context the engine supports (lists,
  blockquotes, tables cells, nested emphasis, after entities) yet NOT fire in code/links.
- **S2 / A2 orthogonal composition walls (each a DIFFERENT GFM rule; one sentence each, fair):**
  1. trailing punctuation trim (`?!.,:*_~` at end excluded, interior kept)
  2. closing-paren balancing (trailing `)` excluded only when unbalanced vs `(` in the link)
  3. entity-trailing (`&...;` at end excluded)
  4. boundary rule (autolink only after start / whitespace / one of `*_~(`)
  5. `www.` gets `http://` prepended in href but not in the visible text
  6. email domain validity + trailing `-`/`_`/`.` backtracking
  Each rule is documented; their INTERACTION (e.g. `(https://ex.com/a_b).` -> trim `.` then
  balance `)`) is the composition the agent must derive. No single guard clears all.
- **A8 boundary/precedence inversions:** the boundary-before rule + the trailing-trim ordering.
- Contract-stated/fix-hidden: stating the GFM rules (fair) does not reveal the INTEGRATION fix
  (where in the event stream to run it, which contexts to exclude, the trim ORDER).

## Architecture (reuses the proven post-pass shape; NO new enum variants)
Emits existing `Tag::Link { link_type: Autolink|Email, dest_url, .. }` -> renders `<a href>` with
zero html/lib Tag changes. Whole feature:
- lib.rs: `Options::ENABLE_BARE_URL_AUTOLINKS` (1 line + flag).
- autolink.rs (NEW): the detection + trailing-trim + paren/entity + email/domain algorithm ->
  `find_autolinks(text, range) -> Option<Vec<(Event, Range)>>`. ~250-320 eff (the multi-rule core).
- parse.rs: ParserInner post-pass in `next_event_range` (pop pending; track code-block + in-link
  suppression; split Text runs via find_autolinks). ~60 eff.

## Files + LOC estimate
| File | eff ~ | what |
|---|---|---|
| pulldown-cmark/src/autolink.rs (NEW) | 280 | scheme/domain/email matchers + trailing trim + paren balance + entity trailing + split |
| pulldown-cmark/src/parse.rs | 60 | ParserInner fields + next_event_range post-pass + exclusion tracking |
| pulldown-cmark/src/lib.rs | 10 | Options flag + `mod autolink;` |
Estimate ~350 eff (Counter1), comfortably over the 250 long-horizon floor with genuine multi-rule logic.

## Trap reproduction plan (HARDENING 3a.4 — prove each bites before authoring tests)
- Naive "scan text, wrap every www./http match" -> regresses base tests (code spans, links) = S3 confirmed.
- Naive "trim all trailing punctuation incl `)`" -> breaks `(https://en.wikipedia.org/wiki/Ruby_(gem))` = paren wall.
- Naive "no entity check" -> `https://ex.com?a=1&amp;b` wrongly keeps `;`... etc.

## Docker/tests/flakiness
Rust cargo2junit (olympus-base-rust, no chmod). Integration tests in tests/ via html::push_html,
deterministic. Base mode runs full suite (S3 shared-path). Naive-benchmark target 70-85%.

## OUTCOME (2026-07-21)
Implemented + verified: 9/10 canonical GFM cases correct (entity-at-end diverges due to pulldown
pre-decoding &amp;->&, scoped out). 1324 base tests green (S3 baseline preserved; opt-in). Merge of
consecutive Text events was REQUIRED (pulldown pre-splits URLs at `_`/`*`) — real integration difficulty.
Final size: 245 Counter-1 / ~181 Counter-2 eff, 3 files. BELOW the 250-C2 long-horizon floor.
This is the 4th consecutive clean feature under 250-C2 (trustfall-prefix 64, abbreviations 163,
gfm-autolinks 181). Conclusion: single clean inline/query extensions in well-factored libraries
do not reach 250-C2; the floor needs a genuinely larger multi-behavior subsystem or a coupled 2nd axis.

## Source-span axis added (2026-07-21)
Added per-piece source-range mapping (SourceMap: merged-offset -> source range) so into_offset_iter
reports correct spans across the Text-merge (verified: http://example.com/x_y split into 3 segments
by pulldown still maps to the exact source span; trailing . gets its own range). 1324 base green.
Final: 269 Counter-1 / ~199 Counter-2, 3 files. STILL under 250-C2 by ~50. The feature, fully built
with every genuine axis, is ~200 C2. Conclusion stands: this feature class caps ~200 C2.
