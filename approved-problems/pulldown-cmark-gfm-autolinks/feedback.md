# feedback.md - pulldown-cmark-gfm-autolinks

Olympus. Harder of the two pulldown features (multi-rule composition + S3 baseline + merge integration).

## Review round 1 (2026-07-21) - fixed
Verify-Solution FAIL: new tests referenced Options::ENABLE_BARE_URL_AUTOLINKS -> compile-error on
base -> orphan "compilation" testcase (neither p2p nor f2p). FIX: tests build the option via
Options::from_bits_truncate(1 << 18) -> compiles on base, truncates to empty -> real named tests
FAIL at runtime. Verified: new-on-base = 25 cases, 18 fail / 7 pass, NO compilation orphan.

Description-Quality request_changes: trimmed redundant prose (opt-in restatement, "text only"
preface, "flow through event stream ... like any other link", GFM ref, "trimming rules interact"
explanatory). Reworded internal Autolink/Email variant names into prose.

Over-specification FAIL: instead of deleting real rules, PINNED them with tests (kept difficulty):
full trailing-punctuation list, not-ending-in-hyphen, image-description exclusion, iterative-trim
interaction. Removed effectively-dead entity-trimming code (pulldown pre-decodes &amp;->&) and its
meta claim -> meta<->test<->solution aligned.

## Status
- Tests: 25 new. Solution 1349 total green (1324 base + 25 new), 0 regressions.
- FP pre-check (light bulb): every test -> meta sentence; every meta rule -> test. Aligned both ways.
- Docker grading: BLOCKED by sandbox (no network to pull olympus-base-rust from ECR). Dockerfile is
  the standard verified cargo2junit pattern. Equivalent grading validated on host: base 1318/0,
  new 25/0, real cargo2junit JUnit XML.
- 3 opus solvers: died on session-limit API error (env, resets 12:40 Cairo) - NOT run. Re-run for
  the difficulty/pass-rate + full FP (every passing agent meets requirements) once quota resets.
- LOC: ~260 C1 / ~195 C2 (under the 250-C2 long-horizon floor - known, unchanged by this round).

## Review round 2 (2026-07-21) - fixed
Two reviewers flagged the from_bits_truncate(1 << 18) enabling as a magic-bit implementation-detail
dependency (ERROR), contradicting the named-option requirement. Accepted fix (both reviewers offered
it): DOCUMENT the bit as a Test Assumption. meta now states "Add this option as the next flag in the
Options bitset, occupying bit 1 << 18 (existing flags end at 1 << 17)." This keeps tests compiling on
base (real f2p, no orphan) AND makes the bit a fair, stated interface. Note: this is an interface
Test Assumption that overrides a possible Description-Quality over-spec nit (fairness > naturalness,
DESCRIPTION.md).
Coverage WARNING addressed: added email-domain-without-dot, email-domain-underscore-last-two, and
explicit url-in-link-destination tests. Now 28 new tests. Full suite 1352 green.
Enabling verified: solution 28/28 pass; base f2p 28 cases (18 fail / 10 pass), no compilation orphan.

## Review round 3 (2026-07-21) - fixed
Wrapper rule (stricter than assumed): EVERY new test must fail/error/skip on base, else it doesn't
require the solution. 10 negative/disabled tests passed on base (no autolink either way). FIX: gave
each negative test a POSITIVE autolink component that only appears with the solution (e.g. `code`
span kept AND a bare URL beside it linked), so the whole test fails on base while still verifying
the exclusion. Verified: base new = 30 cases, 30 FAIL, 0 pass, no orphan. Solution 30/30 pass.
Added non-conflicting coverage: enable_gfm_alone (GFM flag does not enable), underscore boundary,
existing angle-bracket autolink non-interference. Now 30 tests; full suite 1354 green.
Named-const coverage suggestion (Options::ENABLE_BARE_URL_AUTOLINKS == 1<<18) INTENTIONALLY OMITTED:
referencing the named const breaks base compilation for the whole file -> revives the compilation
orphan. The documented bit (meta) + from_bits_truncate cover the interface without the orphan.

## Review round 4 (2026-07-21) - fixed
Grader FAIL: two named tests (disabled_by_default, url_in_link_destination_is_not_autolinked) plus
the "every new test must fail on base" rule. FIX: restored both exact names with fail-on-base positive
components. CORRECTNESS FIX (reviewer flagged twice): boundary was decided from the start of each
text event (always treated valid) -> a URL directly after a code span wrongly linked. Now find_autolinks
takes the preceding source byte (parse.rs computes text[run_start-1]) so a run-start boundary is only
valid after real boundary chars. Verified: `code`http://x no longer links; `*x*`http://x still links.
Coverage suggestions all added: open-paren/tilde/tab boundaries, bare-URL in link text, URL as image
destination, www trailing-punct/unmatched-paren/invalid-domain, email trailing-punct. Now 41 tests.
Verified clean from base: patches apply, 1365 suite green, base 1318/0, new 41/0 no orphan, all 41
fail on base (f2p).

## Coverage round (2026-07-21) - took 2 of 3 suggestions
Nothing failing; these were optional. ACCEPTED: (2) offset-iter span checks for www. + email with
trailing punctuation trimmed; (3) www./email in suppressed contexts (code span, link text). Now 45
tests, 1369 suite green, all 45 fail on base, no orphan.
DECLINED (1) named-constant test (Options::ENABLE_BARE_URL_AUTOLINKS == 1<<18): referencing the
named const breaks base compilation -> revives the compilation orphan that already caused a
Verify-Solution FAIL. Genuine cross-reviewer tension; the f2p mechanism forbids it. Bit is documented
in meta + behaviorally enforced by from_bits_truncate(1<<18). Residual minor FP (a differently-named
flag at bit 1<<18 would pass) is forbidden by the meta's explicit name requirement.

## Agent-run analysis + hardening (2026-07-21)
Platform agent-runs(1): Nova 6/10 PASS + Orion 2/2 PASS = 8/12 (67%) -> TOO EASY (cap 40%).
4 failures all FAIL_MISSED_REQUIREMENT, scattered: code-span boundary (2), code-block (1),
www-invalid-domain (2), trim-cascade panic (1). No dominant trap = HARDENING "separable domain"
signal -> trap-stacking is futile (HARDENING 3c-d).
All 12 agents used the SAME post-pass-on-Event::Text architecture (same as my reference).
THE LEVER (demonstrated): pulldown's inline parser turns `*b*` into EMPHASIS before any post-pass,
so http://example.com/a*b*c links only "http://example.com/a" under the post-pass (mine AND all
agents), while GFM must link the whole URL. This wall defeats the transcribable architecture-jump.
Exploiting it needs source-based/inline detection: a substantial rewrite, regression-risky (a naive
emphasis-reclaim breaks ALL word*em* emphasis; the safe version must reclaim ONLY when a URL reaches
the merge boundary, + handle entities). This is BOTH the difficulty lift (<40%) and the LOC lift.
Coverage suggestions all taken: #1 from_bits(1<<18).is_some() (proves flag defined at bit 18, f2p
clean, no orphan - solves the recurring named-const ask without breaking base compile); #2 event-level
Tag::Link type/dest assertions (www->Autolink+http:// dest, email->Email); #3 disallowed host char (%).
Now 48 tests, 1372 suite green, all 48 fail on base.

## HARDENING IMPLEMENTED (2026-07-21) - the *-wall
Implemented source-based reclaim: when the merge hits an inline-formatting construct (emphasis/strong/
etc.) that interrupts a URL reaching the merge boundary (url_reaches_end), consume that construct's
SOURCE via consume_inline_construct and fold it into the URL. So http://example.com/a*b*c links the
whole URL (GFM), which the post-pass approach ALL 12 agents used CANNOT do. Safe: reclaim only fires
when a real URL reaches the boundary, so word*em* still renders <em> (verified); base suite 1318/0.
Result: solution 267->333 C1 / 195->251 Counter-2 (CLEARS the 250 floor); 48->51 tests; 1375 suite
green; all 51 fail on base; no orphan. Meta documents the contract ("extends to next space, no inline
markup inside; * and _ are ordinary parts") = CONTRACT-STATED / FIX-HIDDEN (HARDENING ideal).
Also strengthened #1: named-const test now checks Debug output contains "ENABLE_BARE_URL_AUTOLINKS"
(verifies the actual NAME at bit 1<<18, compiles on base, f2p clean, no orphan).
CALIBRATION RISK: the *-wall likely drops pass-rate hard (all known agents' post-pass fails it) - could
approach 0%. Contract is fully stated (fair), root cause disclosed in meta, so an agent who does
source-based detection passes (my reference proves solvable). Needs an agent batch to confirm >0%;
if 0%, the meta already names the root cause (HARDENING 3c-bis) so no unfairness to fix.

## FP FIX (2026-07-21) - panel flagged false-positive
Batch: 4/10 pass (IN BAND). Adjudicator: FP + reference bug.
(1) HIDDEN-COVERAGE GAP: passing agents that scan raw source to next whitespace + drop sibling nodes
absorb protected content when a URL crosses INTO a code span / existing link. My reference already
handles this correctly (the code span / link is a separate event that terminates the merge). Closed
the gap: tests url_run_stops_at_a_crossing_code_span, url_run_stops_at_a_crossing_link -> PASS my
reference and FAIL the flawed agents (catch the FP).
(2) REFERENCE BUG: autolink_in_link was a bool -> cleared on an inner Image End, so a URL after an
image but still inside an outer link got autolinked (nested <a>). FIX: bool -> depth counter
(autolink_link_depth). Verified [![alt](img) http://x](/outer) no longer nests. Added
autolink_not_emitted_inside_nested_image_in_link.
Now 54 tests, 1378 suite green, all 54 fail on base, C1 335 / C2 252 (over floor), base 1318/0.

## Fairness fix (2026-07-21) - 2 tests flagged unfair
Reviewer: url_run_stops_at_a_crossing_code_span / _crossing_link require code-span/link PRECEDENCE
(URL stops at them, no space) which the meta under-specified ("extends to next space"). FIX: meta now
documents the precedence explicitly: "inline code spans and link/image syntax take precedence and end
the run early ... Emphasis does not take precedence" -> the tests are now contract-stated (fair).
Redundancy: removed url_in_link_destination_is_not_autolinked (byte-identical to
not_linked_inside_existing_link). Coverage added: works_alongside_strikethrough_extension (ENABLE_
STRIKETHROUGH + ~-boundary -> <del><a>), multiple_unmatched_closing_parens_are_excluded (foo()) )).
Now 55 tests, 1379 suite green, all 55 fail on base, no orphan. Meta 372 words (under 500 cap).

## FP + bug fix round (2026-07-21)
Panel flagged FP (entity/backslash in URL runs) + S1 (High reference bug) + T4 (missing crossing-image).
REFERENCE BUG S1: consume_inline_construct FLATTENED a code span/link/image nested inside an absorbed
emphasis into URL text (violating code/link/image precedence). FIX: buffer the construct + a text_only
flag; only fold emphasis into the URL when it contains ONLY text, else stop the URL before it and
re-emit the construct (preserving the nested code/link/image). Verified http://a/x*`code`*z keeps the
<code>. FP (my reference was already correct, agents truncate): added interior_html_entity_is_part_of_
the_url (http://...&amp;... links whole) + backslash_escaped_punctuation_is_part_of_the_url (a\*b -> a*b)
- catch agents that stop at entity/escape nodes. T4: added url_run_stops_at_a_crossing_image.
Now 59 tests, 1383 suite green, all 59 fail on base, no orphan, C1 350 / C2 265 (over floor), base 1318/0.

## Fairness + coverage round (2026-07-21)
Reviewer: backslash_escaped_punctuation test UNFAIR (depends on undocumented CommonMark backslash-
escape normalization). FIX: removed it (entity test stays - fair, still catches truncate-at-node agents).
Coverage added: autolink_after_a_literal_asterisk_boundary (x*http://... : literal * boundary, distinct
from emphasis); offset_iter_span_stops_at_a_crossing_code_span + _crossing_link (into_offset_iter spans
for precedence-cutoff runs, not just trailing trim). Fixed first_link_span helper to return the FIRST
link (was last). Now 61 tests, 1385 suite green, all 61 fail on base, no orphan.

## Fairness cleanup + stale-eval note (2026-07-21)
Reviewer: every test fair EXCEPT interior_html_entity_is_part_of_the_url (pins undocumented entity-
normalization). FIX: removed it (same class as the backslash test). Suite now has NO undocumented-
behavior tests -> fully fair. Also fixed the duplicated doc comment on consume_inline_construct (polish).
STALE-EVAL NOTE: the FAIL report cites backslash_escaped_punctuation_is_part_of_the_url still failing,
but that test was REMOVED the prior round; the eval ran against a stale test.patch. Current test.patch
= 60 tests, no backslash/entity test. A fresh eval on the current bytes clears it.
Now 60 tests, 1384 suite green, all 60 fail on base, no orphan, patches apply clean, C1 350 / C2 265.

## PASS achieved + 2 fair fixes (2026-07-21)
Eval verdict PASS (4/10-band solvable, all baseline preserved). Two fixes:
(1) UNFAIR TEST fixed (not removed, per reviewer): code_span_nested_in_emphasis used `*`code`*` where
the * placement vs the code span is ambiguous (prompt points both ways). Replaced with
link_nested_in_absorbed_emphasis_stops_the_url_run using http://a/x*a [t](/u) b*z -> a REAL <em>
containing a <a> (the * is a genuine structural emphasis marker, unambiguous), which actually exercises
the reclaim-abort (nested link preserved, not flattened).
(2) REFERENCE BUG (scan_email): trimmed trailing '-' before validation, so foo@example.com- linked as
foo@example.com though the domain ends in '-' (not a spec trim char). FIX: dropped '-' from the email
trailing trim (kept '_' '.', which ARE in the spec set). Added email_domain_ending_in_hyphen_is_not_linked.
Also removed a duplicated doc comment on consume_inline_construct.
Now 61 tests, 1385 suite green, all 61 fail on base, no orphan, patches apply clean, C1 350 / C2 265.

## Final fairness fix (2026-07-21)
Reviewer: link_nested_in_absorbed_emphasis_stops_the_url_run still unfair - it pinned the ambiguous
choice of WHERE the URL stops relative to the * that starts the emphasis. REMOVED it. Replaced with
nested_link_in_absorbed_emphasis_is_not_flattened, which catches the same corruption FAIRLY: it asserts
only the two UNAMBIGUOUS properties - the bare URL autolinks to a.example (contains "<a href=\"http://
a.example", f2p: fails on base) and the nested markdown link still renders (contains "<a href=\"/u\">
t</a>"). It does NOT pin the exact stop point, so no ambiguous choice is tested, yet if the S1 flatten
bug returned the nested-link assertion would fail. S1 code fix retained.
Now 61 tests, 1385 suite green, all 61 fail on base, no orphan, patches apply clean, C1 350 / C2 265.
