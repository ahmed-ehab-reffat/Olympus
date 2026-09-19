# feedback.md — mwparserfromhell-site-aware-parsing

## Summary
Site-aware parsing for mwparserfromhell: a `SiteInfo` profile (linktrail characters, namespace
names -> ids, recognised tag names) threaded through BOTH tokenizers (C + pure Python), the
builder and the `Wikilink` node. Picked by the 2026-09-13 hunt (README `Limitations` lane,
`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-13.md`).

## Gate 8 note (carry into every review round)
Issue #82 (2014): maintainer "uncomfortable about adding site-specific arguments" to `parse()`.
Counter-evidence: `skip_style_tags` later added to `parse()`, #305 (2023) asking for exactly this
left undeclined, README frames the three gaps as limitations. Mitigation used: the profile is ONE
data object (`SiteInfo`) with no per-site logic in the parser.

## Attempt history
- 2026-09-13 R0: DESIGN.md written. Thinnest end-to-end spike owed before scope-lock.
- 2026-09-14 R0 BUILT + VALIDATED (no batch yet).
  - Spike-first: thinnest end-to-end version measured 400 human-eff before tests; final
    solution.patch 432 human-eff (hook), 13 files (1 new). Comment lines added = licence header +
    repo-style function comments only.
  - Tests: tests/test_siteinfo_ea9bb1.py, 84 functions, 153 cases (most parametrized over the C
    and Python tokenizers through `mwparserfromhell.parser.use_c`; the `c` half asserts the C
    tokenizer is really in use, so a broken C build cannot pass by falling back).
  - Clean room (fresh clone at BASE): base+test.patch -> base 2006 pass, new 153 FAIL (per-test,
    tolerant import); +solution -> base 2007 pass, new 153 pass, 3x identical; reverse order
    clean; both patches unapply clean.
  - Docker (olympus-base-python, `--network none --user 1000:1000`): image with test.patch only ->
    base 2007/0, new 153 failed (expected); image with solution -> base pass, new 153 pass.
  - FP battery: 20 single-point mutations (10 Python, 5 C, 2 node, 1 builder, 2 stubs) all
    detected (min 2, max 74 kills); 118 equality assertions flipped one at a time, 0 decorative.
  - Design finding during the spike: a stray `</foo>` inside a recognised tag body must ALSO be
    gated (both arms) or the enclosing recognised tag collapses to text. Kept as an F-7 site;
    meta says "in both its opening and closing forms".
  - Owed next: platform PRECHECK (Step 4b core-slice dedupe) BEFORE any batch; then first batch.
- 2026-09-15 R1: platform PRECHECK feedback applied (no batch yet, so description edits are free).
  - "Tests focus on behavior" ERROR: dropped the private `_tokenizer` import and the
    `isinstance(Parser()._tokenizer, CTokenizer)` assertions. The C/py fixture now keys off the
    documented `mwparserfromhell.parser.use_c` (docs/index.rst; the repo's own test_parser.py
    toggles it) and a module-level `C_AVAILABLE = parser.use_c` captured at import. Verified the
    guard still discriminates: with the .so removed the c half fails (1 failed, 74 errors); with
    it present 153 pass 3x identical.
  - "No test leakage" WARNING: removed "the compiled tokenizer is rebuilt from source before the
    tests run" from meta.md.
  - "Only necessary information" suggestions: removed the no-profile/round-trip boilerplate
    sentence, "Every field ... acts on its own", and the "extension tags and allowed HTML tags
    together" fragment.
  - "Aligned" WARNING: meta now states SiteInfo is exported from the package top level, that
    `Wikilink` accepts a `trail` keyword, and that assigning None to trail stores "".
  - meta.md 333 words, ASCII. test.patch regenerated (test.sh 100755); solution.patch unchanged.
- 2026-09-15 R2: Verify Solution / Test Quality / Solution Quality precheck findings applied.
  - Verify Solution FAIL (`tests.test_tokens.test_issubclass[WikilinkTrail]` in neither set):
    the new token class extended the repo's `tokens.__all__` parametrization. Dropped the class;
    the trail now rides as a `trail` kwarg on the existing `WikilinkClose` token (same idiom as
    `ExternalLinkOpen(brackets=)` / `TagCloseSelfclose(padding=)`) in both tokenizers, builder
    reads `token.trail or ""`. Base set back to 2006 passed / 1 skipped, identical with and
    without the solution.
  - Test Quality FAIL (`test_get_tree_shows_trail` pins an undocumented get_tree format): removed.
  - Solution Quality FAIL (Python scanner stopped at regex marker segments, e.g. linktrail "a-b"
    on `[[x]]a-b` attached only "a"; C attached "a-b"): `_emit_wikilink_close` now walks
    successive segments until a character outside the set ends the run (partial last segment
    split into trail + text), matching the C code-point loop. Confirmed in Docker: the old
    single-segment scanner gives [Wikilink "[[x]]a", Text "-b-a c"] vs C "[[x]]a-b-a".
  - New tests (10 functions / 20 cases): marker-character trails (`a-b`, `-` only, run ending
    mid-word), unknown tags inside a template parameter / heading / wikilink text (advisory
    coverage suggestion), parity matrix extended with `tags=[]`, marker-linktrail profiles and
    the astral profile, plus a corpus line covering them. 163 cases total.
  - docs/limitations.rst updated: the three bullets now say what each SiteInfo field enables.
  - Clean room (fresh clone at BASE inside olympus-base-python, --network none): test.patch only
    -> new 163 failed; + solution.patch -> new 163 passed x3 identical, base 2006 passed/1 skipped.
    LOC hook: human-effective 363 (raw 503), 14 files (1 new).
- 2026-09-15 R3: Solution Quality PASS with two issues + one advisory coverage note, all applied.
  - C NUL sentinel: the trail loop used `!this` (Tokenizer_read returns 0 past the end) so a NUL
    that is a linktrail character read as EOF. Loop is now bounded by `self->text.length`.
    New `test_nul_trail_character` (`[[x]]\0z`, linktrail "\0") passes on both tokenizers. NOT
    added to PARITY_CORPUS: the base C tokenizer truncates everything at a NUL outside the trail
    ("a\0b" -> "a" on base), so a corpus line would fail on a pre-existing divergence.
  - README.rst: duplicated limitations block now mirrors docs/limitations.rst.
  - Advisory: 3 standalone unmatched-unknown-tag tests (`x<foo>y`, `x</foo>y`, lone tags between
    trailed links with mixed case).
  - 171 cases. Local new x3 identical, base 2006/1 skipped. Docker clean room from fresh clone at
    BASE: tests only 171 failed; + solution 171 passed x3, base 2006/1 skipped. Hook 372 human-eff,
    12 files (tokens.py/tokens.c/tokens.h no longer touched).
- 2026-09-15 R4: Solution Quality FAIL (C NUL-as-EOF, clang-format) + description note applied.
  - C EOF sentinel: `Tokenizer_read` / `Tokenizer_read_backwards` returned '\0' both for a
    source U+0000 and for out-of-range reads, so any NUL truncated the C parse (base bug, but
    the "identical trees" contract makes it ours). Added `END_OF_TEXT ((Py_UCS4) -1)` in
    common.h, both readers return it, the MARKERS table lists it instead of '\0', and the 18
    end-of-input checks in tok_parse.c (`!this`, `!last`, `!current_character`, the
    `Tokenizer_read(self, 2)` truthiness, the uri-end scan loop) compare against it. Verified
    C == Python on "[[x]]\0z" (linktrail "a"), "a\0b<ref>c\0</ref>{{t|\0}}\n== h\0 ==\n* \0".
    Deliberately NOT added to the test suite / parity corpus: it is a pre-existing C limitation
    outside the stated feature; forcing agents to find it would be an unstated wall.
  - clang-format: the 91-col PyUnicode_Substring line is split; new C lines are all <= 88. Ran
    clang-format 23 on the touched files and then rebuilt tok_parse.c from BASE + my hunks only,
    because that clang-format version realigns two base macro groups the pinned hook leaves
    alone (DIGITS block, MAX_BRACES). Remaining >88 line (tok_parse.c:33) is base code.
  - meta.md: dropped the "Today the parser ..." baseline sentence per the reviewer; body now
    starts at the SiteInfo ask. 292 words, ASCII.
  - Local new x3 identical (171), base 2006/1 skipped. Docker clean room from fresh clone at
    BASE: tests only 171 failed; + solution 171 passed x3, base 2006/1 skipped. Hook 400
    human-eff (raw 544), 14 files.
- 2026-09-15 R5: Auto Review "Revision Requested" (Tests 1/3 harness FN, Solution 2/3 casefold).
  - T1/T2/T8 harness: reproduced in Docker as `--user 1000:1000 --network none`: build_ext
    --inplace failed with "could not create build/...: Permission denied" (root-owned /app), and
    the old `|| cat` let pytest run on the stale/absent .so -> 86 C-side failures. Two fixes:
    Dockerfile now `git config --system safe.directory '*' && chmod -R a+rwX /app` after the
    editable install; test.sh treats a build failure as fatal: prints the log, writes a single
    JUnit <failure> (testcase c_tokenizer_extension_builds) carrying the compiler output when
    --output_path is set, exit 1. Exercised by touching tok_parse.c + CC=false: exit 1, XML
    well-formed, 941 chars of log inside <failure>.
  - S1: SiteInfo tag normalisation lower() -> casefold() on both sides. New
    `test_tag_recognition_folds_unicode_case` (tags=["Σ"], parses <ς/> and <Σ/> as Tag; still
    Text under tags=["x"]).
  - Advisory: `test_generated_corpus_tokenizer_parity` — seeded random.Random(20260915)
    compositions of 56 fragments (links, prefixes, tags, malformed delimiters, markup), 150
    texts x 4 profiles, C == Python shape + get_tree + round trip. Passes on the reference.
  - 174 cases. Local new x3 identical, base 2006/1 skipped. Docker clean room from fresh clone
    at BASE, --network none, as root AND as uid 1000: tests only 174 failed; + solution 174
    passed x3, base 2006/1 skipped. Hook 400 human-eff, 14 files. meta.md unchanged.
- 2026-09-16 R6: Solution Quality FAIL (paired Unicode tag names still lower()) + comment nit.
  - Opening/closing tag-name equality in BOTH tokenizers (base code: tokenizer.py
    `_handle_tag_close_close` x2, tok_parse.c `strip_tag_name`) now uses casefold(), matching
    SiteInfo.is_tag. New `test_recognized_tag_pair_folds_unicode_case`: tags=["ss"] parses
    `<ß>x</SS>` as one Tag with contents "x"; still Text under tags=["ref"]. definitions.py
    blacklist/single lookups left on lower(): those lists are ASCII-only and the C side
    ASCII-encodes them, so casefold could not change a result there.
  - tokenizer.c: "Deallocate the given tokenizer object." comment moved back above
    Tokenizer_dealloc; the site-loader comment sits alone above load_tokenizer_site.
  - 176 cases. Local new x3 identical, base 2006/1 skipped. Docker clean room from fresh clone
    at BASE, --network none, root AND uid 1000: tests only 176 failed; + solution 176 passed x3,
    base 2006/1 skipped. Hook 405 human-eff, 14 files. meta.md unchanged.
- 2026-09-16 R7: Auto Review "Revision Requested" (Tests 1/3: T3/T4 recursive parse branches).
  - Added `test_parse_readable_with_site` (io.StringIO) and `test_parse_iterable_with_site`
    (list of str/str/bytes + a generator; checks shape, trail and namespace per element). Mutation
    check: dropping `site=` from the readable and iterable recursive calls in utils.py fails all 4
    cases, reference passes them.
  - Medium/advisory "wherever it appears": `test_unknown_tag_inside_list_item_is_text`,
    `test_unknown_tag_inside_table_cell_is_text` (td contents), and
    `test_unknown_tag_inside_argument_and_external_link_is_text` (argument default + ext-link
    title). All assert the XML form is Text while the surrounding markup still parses.
  - 186 cases. Local new x3 identical, base 2006/1 skipped. Docker clean room from fresh clone at
    BASE, --network none, root AND uid 1000: tests only 186 failed; + solution 186 passed x3,
    base 2006/1 skipped. solution.patch, meta.md, Dockerfile unchanged this round.
- 2026-09-16 R8: Auto Review "Revision Requested" (Tests 1/3: recognized-tag-with-attributes,
  Unicode namespace case). Both behaviors already correct in the reference; only tests added.
  - `test_recognized_tag_with_attributes_is_parsed` (`<ref name="x">a</ref>` stays a Tag, asserts
    tag name, the attribute and the contents) and
    `test_recognized_self_closing_tag_with_attributes_is_parsed` (`<ref name=foo/>`, `<span id=a>`).
    Mutation: gating on the whole opening payload (name + attributes) instead of the name token
    kills exactly these 2, nothing else.
  - `test_namespace_folds_unicode_case` (namespaces {"Σ":6,"Тема":1}; `[[ς:x]]s` -> ns 6 with the
    trail suppressed, `[[ТЕМА:y]]s` -> ns 1 with the trail attached). Mutation: `_normalize`
    casefold() -> lower() kills exactly this 1 (both tokenizer params), nothing else.
  - 192 cases. Local new x3 identical, base 2006/1 skipped. Docker clean room from fresh clone at
    BASE (clone root asserted), --network none, root AND uid 1000: tests only 192 failed;
    + solution 192 passed x3, base 2006/1 skipped. solution.patch byte-identical to R7 (mutation
    restores verified by cmp), meta.md + Dockerfile unchanged.
- 2026-09-17 Batch 1 (20 runs: 14 Nova, 1 Orion, 5 Vega): 0/20. Full table in eval-results.md.
  - Unfairness signal: `test_recognized_tag_pair_folds_unicode_case` (added R6 at a Solution Quality reviewer's
    request) kills 19/20 for the same reason: `<ß>x</SS>` stays Text. meta.md says recognition is compared without
    regard to case; it never says opening and closing names PAIR by case folding, and that pairing is base code
    using lower(). Hidden requirement. Without it: Nova 7/9/13 pass (replayed in Docker as uid 1000, 190/192 + base).
  - Other clusters judged fair: generated parity corpus (trail chars lost on backtracking, or C/Python divergence),
    title reassignment with leading colon (all 5 Vega; meta states both halves), NUL trail on C (never sole killer).
  - Shortcut finding: all 3 would-be passers delegate from the C tokenizer to the Python tokenizer when a site is
    given, so "identical trees" holds trivially and none touch tok_parse.c. meta.md only requires identical trees,
    so this is not an FP against the stated contract, but it bypasses the C half of the work.
  - Recommended next step (not applied, needs a decision): drop the tag-pair test (tests-only, re-eval eligible,
    solution keeps casefold). Expected re-eval ~3/20. Requiring native C in meta.md would be solver-visible (full
    batch) and prescriptive, and no native run is currently one fix from passing on a single class except Nova 4/12
    (parity corpus) and Vega 5 (reassignment).
- 2026-09-17 R9: option 1 applied. Removed `test_recognized_tag_pair_folds_unicode_case` (hidden pairing
  requirement, 19/20 same-reason kills). solution.patch unchanged (still casefolds pairs), meta.md + Dockerfile
  unchanged, so re-eval eligible.
  - Suite now 190 cases. Local new x3 identical (190 passed), base 2006/1 skipped.
  - Clean room from fresh clone at BASE, --network none: tests only 190 failed (uid 1000); reference 190 passed
    twice as uid 1000 and once as root, base green each time.
  - Local re-eval preview, all 20 batch-1 patches replayed in that image as uid 1000 (log in
    agent-runs/replay-r9.txt): 3/20 pass (Nova 7, 9, 13), 17 fail, every baseline green. Expected re-eval ~15%.
    All three passes delegate C tokenization to the Python tokenizer when a site is given.
  - Next: run Re-eval on batch 1 (do NOT fire any fresh run first, it dismisses the offer); then FP Check.
- 2026-09-18 ACCEPTED at 2/19 (re-eval of batch 1). Auto Review Approved (3/3/3). FP panels upheld both
  passes. Finalized: F-36, F-37, L66-L68, Pattern 94 written back; archived to approved-problems/.
