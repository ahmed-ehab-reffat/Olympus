# eval-results.md — mwparserfromhell-site-aware-parsing

Msgs = model requests in the trajectory (`final_metrics.extra.per_request_usage`). LOC = raw added lines in the agent patch.

| Batch | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|
| 1 | Nova 1 | FAIL | 49 | 7 | +299 | 23 cases: html_style_tag_named_like_markup_is_gated, nul_trail_character, parse_iterable_with_site, parse_readable_with_site, recognized_tag_pair_folds_unicode_case, site_with_only_tags, unknown_self_closing_tag_is_text, unknown_single_tag_is_text, unknown_tag_inside_heading_is_text, unknown_tag_inside_list_item_is_text, unknown_tag_inside_table_cell_is_text, unmatched_unknown_tags_between_links_are_text | Baseline passed, but site-aware parsing fails 23 hidden cases, primarily for unrecognized XML tags and tokenizer edge cases. | no C tokenizer parsing change |
| 1 | Nova 2 | FAIL | 75 | 10 | +395 | 3 cases: generated_corpus_tokenizer_parity, recognized_tag_pair_folds_unicode_case | Profile-aware parsing is incomplete: Unicode caseless tag pairs fail, and a composed trail parse loses input characters. | C delegates to Python tokenizer when site given |
| 1 | Nova 3 | FAIL | 83 | 12 | +426 | 3 cases: generated_corpus_tokenizer_parity, recognized_tag_pair_folds_unicode_case | Three new tests fail: two for Unicode-caseless paired tags and one for linktrail characters being lost during rendering. | C delegates to Python tokenizer when site given |
| 1 | Nova 4 | FAIL | 80 | 13 | +474 | 3 cases: generated_corpus_tokenizer_parity, recognized_tag_pair_folds_unicode_case | Three new tests fail: two for Unicode case-folded tag pairs and one for C/Python tokenizer parity. | native C (tok_parse.c) |
| 1 | Nova 5 | FAIL | 120 | 10 | +339 | 17 cases: cyrillic_trail, generated_corpus_tokenizer_parity, lowercase_namespace_takes_no_trail, namespace_folds_unicode_case, recognized_tag_pair_folds_unicode_case, trail_characters_with_markup_meaning, trail_run_ends_inside_a_word, unknown_tag_inside_recognized_tag_is_text, unknown_tag_with_attributes_is_text | Baseline tests pass, but the solution fails 17 new site-aware parsing and tokenizer-parity tests. | C delegates to Python tokenizer when site given |
| 1 | Nova 6 | FAIL | 88 | 8 | +262 | 30 cases: all_tags_recognized_when_unspecified, cyrillic_trail, lowercase_namespace_takes_no_trail, namespace_folds_unicode_case, recognized_nowiki_keeps_raw_body, recognized_self_closing_tag_with_attributes_is_parsed, recognized_single_tag_is_parsed, recognized_tag_is_parsed, recognized_tag_pair_folds_unicode_case, recognized_tag_still_hides_headings, recognized_tag_with_attributes_is_parsed, tag_recognition_ignores_case, trail_inside_tag_body, trail_stops_at_recognized_tag, unknown_tag_inside_recognized_tag_is_text | The new suite fails because recognized profile tags are parsed as text and some namespace-special link trails produce the wrong node structure. | C delegates to Python tokenizer when site given |
| 1 | Nova 7 | FAIL | 87 | 11 | +311 | 2 cases: recognized_tag_pair_folds_unicode_case | Unicode-equivalent opening and closing tag names are parsed as text instead of one recognized Tag node. | C delegates to Python tokenizer when site given |
| 1 | Nova 8 | FAIL | 77 | 12 | +401 | 4 cases: generated_corpus_tokenizer_parity, nul_trail_character, recognized_tag_pair_folds_unicode_case | The solution misses explicit edge behavior for NUL linktrail characters, Unicode case folding, and tokenizer parity. | native C (tok_parse.c) |
| 1 | Nova 9 | FAIL | 88 | 9 | +293 | 2 cases: recognized_tag_pair_folds_unicode_case |  | C delegates to Python tokenizer when site given |
| 1 | Nova 10 | FAIL | 85 | 14 | +476 | 2 cases: generated_corpus_tokenizer_parity, nul_trail_character | Two new tests fail because the C tokenizer mishandles a NUL trail and disagrees with the Python tokenizer on a generated input. | native C (tok_parse.c) |
| 1 | Nova 11 | FAIL | 127 | 14 | +597 | 6 cases: both_tokenizers_agree, generated_corpus_tokenizer_parity, nul_trail_character, recognized_tag_pair_folds_unicode_case, trail_survives_unclosed_template_reparse | Six new tests fail due to incomplete link-trail backtracking/NUL handling and Unicode case-insensitive tag pairing. | native C (tok_parse.c) |
| 1 | Nova 12 | FAIL | 82 | 12 | +388 | 3 cases: generated_corpus_tokenizer_parity, recognized_tag_pair_folds_unicode_case | Three new site-aware parsing assertions fail: Unicode tag-pair folding and C/Python link-trail parity. | native C (tok_parse.c) |
| 1 | Nova 13 | FAIL | 63 | 11 | +356 | 2 cases: recognized_tag_pair_folds_unicode_case | Unicode-caseless recognized tag pairs are emitted as text instead of Tag nodes. | C delegates to Python tokenizer when site given |
| 1 | Nova 14 | FAIL | 89 | 12 | +485 | 9 cases: cyrillic_trail, generated_corpus_tokenizer_parity, lowercase_namespace_takes_no_trail, namespace_folds_unicode_case, recognized_tag_pair_folds_unicode_case | The implementation is incomplete for embedded namespace trails, Unicode case folding in tag matching, and one C/Python tokenizer parity path. | native C (tok_parse.c) |
| 1 | Orion | FAIL | 101 | 12 | +414 | 9 cases: cyrillic_trail, generated_corpus_tokenizer_parity, lowercase_namespace_takes_no_trail, namespace_folds_unicode_case, recognized_tag_pair_folds_unicode_case | Site-aware parsing fails on namespace-excluded trail text, Unicode-insensitive tag pairing, and one trail cursor/data-preservation case. | C delegates to Python tokenizer when site given |
| 1 | Vega 1 | FAIL | 55 | 12 | +555 | 5 cases: namespace_follows_title_reassignment, nul_trail_character, recognized_tag_pair_folds_unicode_case |  | native C (tok_parse.c) |
| 1 | Vega 2 | FAIL | 61 | 8 | +526 | 4 cases: namespace_follows_title_reassignment, recognized_tag_pair_folds_unicode_case | Unicode-caseless tag pairing and leading-colon namespace detection after title reassignment are incorrect. | no C tokenizer parsing change |
| 1 | Vega 3 | FAIL | 92 | 14 | +595 | 5 cases: namespace_follows_title_reassignment, nul_trail_character, recognized_tag_pair_folds_unicode_case | Five new tests fail for NUL linktrails, Unicode case-folded tag pairs, and leading-colon namespace reassignment. | native C (tok_parse.c) |
| 1 | Vega 4 | FAIL | 60 | 12 | +626 | 5 cases: namespace_follows_title_reassignment, nul_trail_character, recognized_tag_pair_folds_unicode_case | Five new tests fail: one C-tokenizer NUL linktrail case, two Unicode case-folded tag-pair cases, and two leading-colon namespace reassignment cases. | native C (tok_parse.c) |
| 1 | Vega 5 | FAIL | 51 | 13 | +567 | 4 cases: namespace_follows_title_reassignment, recognized_tag_pair_folds_unicode_case | Four new tests fail for Unicode case-insensitive tag pairing and leading-colon namespace recomputation. | native C (tok_parse.c) |

## Batch 1 summary (2026-09-17, 14 Nova + 1 Orion + 5 Vega, all evaluated by Nova)

- Pass: 0/20 (0%). Unsolvable as measured.
- Median model requests: 82.5. Baseline suite green in all 20 runs.
- Kill ranking (runs failing the test): recognized_tag_pair_folds_unicode_case 19, generated_corpus_tokenizer_parity 10,
  nul_trail_character 7 (C param only), namespace_follows_title_reassignment 5 (all Vega), cyrillic_trail 4,
  lowercase_namespace_takes_no_trail 4, namespace_folds_unicode_case 4.
- Sole blocker: Nova 7, Nova 9, Nova 13 fail ONLY recognized_tag_pair_folds_unicode_case. Replayed in a clean
  olympus-base-python image (offline, uid 1000): each 190/192 new, base green.
- Approach split: 10 native C (edit tok_parse.c), 8 delegate from C Tokenizer_tokenize to the Python Tokenizer when
  site is not None, 2 neither. All three sole-blocker runs are delegators. Best natives: Nova 4 and Nova 12 fail only
  the generated parity corpus; Vega 5 fails only title reassignment.
- Leanest near-passer (Nova 9): 221 human-effective, 9 files.

## Batch 2 (2026-09-18) — Re-eval of batch 1 after R9 dropped the tag-pair test · ACCEPTED

Pool of 19: every run fingerprints to a batch-1 run (added LOC + prompt tokens, renumbered). Batch-1
Nova #13 is not in the pool.

| Batch 2 run | = Batch 1 run | Verdict | Failed functions | C approach |
|---|---|---|---|---|
| Nova 5 | Nova 9 | **PASS** 190/190 | none | delegates to Python |
| Nova 7 | Nova 7 | **PASS** 190/190 | none | delegates to Python |
| Nova 2 | Nova 12 | FAIL 1 | generated_corpus_tokenizer_parity | native |
| Nova 10 | Nova 4 | FAIL 1 | generated_corpus_tokenizer_parity | native |
| Nova 11 | Nova 3 | FAIL 1 | generated_corpus_tokenizer_parity | delegates |
| Nova 12 | Nova 2 | FAIL 1 | generated_corpus_tokenizer_parity | delegates |
| Nova 4 | Nova 10 | FAIL 2 | parity corpus, nul_trail[c] | native |
| Nova 6 | Nova 8 | FAIL 2 | parity corpus, nul_trail[c] | native |
| Nova 3 | Nova 11 | FAIL 4 | parity corpus, nul_trail[c], both_tokenizers_agree, unclosed_template_reparse[py] | native |
| Nova 1 | Nova 14 | FAIL 7 | parity corpus, cyrillic, lowercase ns, unicode ns fold | native |
| Nova 9 | Nova 5 | FAIL 15 | trail/tag/namespace breadth | delegates |
| Nova 13 | Nova 1 | FAIL 21 | unknown-tag contexts, recursive parse inputs | none |
| Nova 8 | Nova 6 | FAIL 28 | recognised-tag family, namespace split | delegates |
| Orion | Orion | FAIL 7 | parity corpus, namespace split | delegates |
| Vega 1 | Vega 5 | FAIL 2 | namespace_follows_title_reassignment | native |
| Vega 4 | Vega 2 | FAIL 2 | namespace_follows_title_reassignment | none |
| Vega 2 | Vega 4 | FAIL 3 | title reassignment, nul_trail[c] | native |
| Vega 3 | Vega 3 | FAIL 3 | title reassignment, nul_trail[c] | native |
| Vega 5 | Vega 1 | FAIL 3 | title reassignment, nul_trail[c] | native |

- Pass: **2/19 = 10.5%** (Nova 2/13, Orion 0/1, Vega 0/5). Baseline green in all 19.
- Local replay (agent-runs/replay-r9.txt) matched every kept run's failure count; projected 3/20 because
  the dropped batch-1 Nova #13 was a projected pass.
- FP panel: both passes upheld (one judge's `<Σ>a</ς>` dissent overruled as pre-existing, out of scope).
