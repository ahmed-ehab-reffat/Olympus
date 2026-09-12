# feedback.md — iwe-anchored-links

## Summary

- Repo: [iwe-org/iwe](https://github.com/iwe-org/iwe), Rust, Apache-2.0, 1344 stars, 81k source LOC, pure Rust with no system dependencies.
- BASE_COMMIT: `7d861a62c6d4a10237ba2a153005dd9122362b4e`
- Tier: Olympus. Category: feature-request. Shape: O-Composite-add.
- Feature: a link url fragment addresses a header inside the target document, and stays correct across extract / inline / rename refactors.
- Status: Auto Review revision round 1 answered. Description 3/3, Solution 3/3, Tests 1/3 on a single T5 (resolve_anchor return type) that is now fixed BOTH ways the reviewer allowed. Batch: 3 of 10 passed = 30%, inside the <=40% cap.

## Host selection log

The user asked for a fresh Rust repo, so every repo already present under `worktrees/`, `problems/`, `rejected/` or `Instructions/Aprroved/` was excluded (617 names). Candidates killed on hard gates:

| Candidate | Killed by |
| --- | --- |
| nical/lyon (corner rounding) | DEAD CLASS. Fully designed, then killed before authoring: a deterministic path transform maps onto three entries of the death-class taxonomy at once (recallable named algorithm + input-determined output, single-subsystem mechanical transform, difficulty-from-misdirection). The golang/geo trilemma applies: fair x hard x LOC-floor do not co-exist in mature geometry. |
| softdevteam/grmtools | beacon-saturated: every natural gap has an open maintainer issue (EBNF/rule macros #562, lex definitions #417/#465, ambiguities #612). |
| nkaz001/hftbacktest | environment: vanilla `cargo test --workspace` fails to compile four examples on the default branch. |
| pop-os/cosmic-text | environment: 7 tests need system fonts (`no default font found`); would need font provisioning and stays font-set dependent. |
| kyren/piccolo | CC0-1.0 (not in the allowed license list) and no source commit since 2025-07. |
| PRQL/prql, automerge, proptest, difftastic | author-obvious category hosts (SQL tooling, CRDT, property testing, structural diff) or beaconed feature gaps. |
| plotters | font-kit / system-font dependency in the default feature set plus slow maintenance. |

iwe was the only candidate clearing every gate: license, stars, real activity (80 source commits in 12 months, last commit the day before pick), zero-dependency offline build, and a vanilla suite that is green offline and deterministic.

## Why this feature

- Capability gap reproduced on base: `Key::from_rel_link_url` splits the fragment off and throws it away, so `[label](note#section)` is only ever a document link. A block link with a fragment includes the whole target document; link text normalization uses the document title; nothing reports a fragment that matches nothing.
- Exclusivity: `gh issue/pr list -R iwe-org/iwe --state all --search` over anchor / fragment / heading / section / transclusion / embed / block returns only fragment url normalization fixes (PR #284, #301) and the root-absolute path bug (#339, closed). No PR or issue resolves fragments to headers.
- Not a documented spec: the slug rules, the partial inclusion rule and the refactor retargeting are this engine's own semantics, not a portable standard.

## Design decisions logged

- The resolution kernel is deliberately a single chokepoint (`Graph::resolve_anchor` over `Graph::anchors`) that feeds four unrelated surfaces: inclusion expansion, link text normalization, the reporting APIs, and the refactor retargeting. A wrong slug rule surfaces in all four.
- Refactor retargeting follows header NODE IDENTITY, not slug strings: `AnchorRelocation` maps old (document, slug) to the header node, then that node to wherever the operation left it. This is what makes the renumbering cases fall out for free, and it is the part a slug-string implementation cannot get right.
- `slugify` was factored so the pre-existing `operations::util::string_to_slug` (used for file keys) delegates to it, rather than shipping a second slug algorithm. The anchor-only divergence (a header with no letter and no digit answers to `section`) lives in the numbering pass.
- The new tests are their own cargo test targets (`anchored_links_b18f6a` in liwe, `anchored_stats_b18f6a` in iwe), so base mode builds and runs only the repository's own targets. No `test.sh` trickery, no file moving. The two negative CLI assertions carry a broken-anchor canary in the same workspace, so no new test passes vacuously on base.
- Fixtures are markdown strings built with the repo's own `from_indoc` state helper. No binary fixtures.
- Test coverage was audited twice against the description and against every solution branch. The second pass added 19 tests for url forms (empty fragment, percent escapes, document extension, root-absolute, subdirectory-relative), an empty header, nested and self-referential anchored inclusion, quote-mode inline, table cell retargeting, wiki piped links, text preserved when normalization is off, unknown-document lookups, non-header nodes, and a dangling anchor left alone by extract. The CLI assertions are scoped to the Broken Anchors section, because a wiki link with a fragment is already reported as a Broken Link on base and made one assertion pass vacuously.

## Traps

1. Slug numbering is document-wide and counts the title, not per parent section. An implementation that numbers per level gets `notes-2` wrong exactly when a repeat sits at a different depth.
2. The trim between the two slug policies: `string_to_slug` already exists in the repo and returns an empty string for a punctuation-only header. Reusing it unchanged breaks the `section` fallback, and the failing test names a numbering result, not the helper.
3. Extract has to split its inbound anchors three ways (the extracted header itself loses its fragment, a header carried away with it keeps one under a possibly different slug, a header left behind renumbers). Doing the obvious thing (rewrite the key, keep the anchor text) fails only the renumbering case.
4. Inline renumbers anchors of the HOST document too, because the guest's headers are inserted into the host's numbering. A link that was never touched by the operation changes its slug.
5. Inline links live inside line inlines, block links are their own graph nodes. A reporting implementation that walks graph nodes only misses every anchored link inside a paragraph.
6. The document level edges must not change: an anchored link still counts as an inclusion or reference edge exactly as before, so the existing query and stats behavior is preserved.

Traps 1, 3 and 4 are interdependent: they all run through the same numbering pass, and fixing the numbering scope changes what extract and inline have to rewrite.

## Validation

| Check | Result |
| --- | --- |
| `human-effective` LOC (Counter 2) | 541 across 24 files (raw 803) |
| new tests | 176 (165 library, 11 CLI) |
| base tree + test.patch, base mode | PASS, 1871 cases, 0 failures |
| base tree + test.patch, new mode | FAIL, 176 cases, 176 failures (165 by build-failure synthesis, 11 by assertion) |
| + solution.patch, base mode | PASS, 1871 cases, 0 failures (no regressions) |
| + solution.patch, new mode | PASS, 176 cases, 0 failures |
| apply order solution then test | applies and unapplies cleanly, same results |
| determinism | base and new run 3x each, identical counts every run |
| container run | `--network none`, `--user 1000:1000`, all four cells reproduced in the built image |
| environment quality | vanilla `cargo test --workspace` inside the image: 1871 passed, 0 failed, offline |

## AI review round 1 (2026-08-02)

Three automated checks: tests-quality WARNING, description-necessity REQUEST_CHANGES (one HIGH), alignment WARNING. Two of them pulled opposite ways (cut redundancy vs. pin interface detail), so each point was resolved on the side that keeps the tests fair:

- HIGH, "document level edges stay exactly as they are today": the generic preserve-existing phrasing is gone. It is replaced by the feature-specific contract "An anchored link is still an edge to its document", because two tests assert exactly that and an implementer could reasonably have replaced the document edge with a section edge. Cutting the sentence outright would have turned those into hidden requirements.
- MEDIUM, restating that a link alone on a line includes its document: folded into the anchored rule, which now reads "A link alone on a line that carries a fragment includes only ...". The preservation test for unanchored inclusion stays; it can only fail if an implementation breaks base behavior.
- MEDIUM, `rename_header` cross-reference: trimmed to "returning `Changes`".
- LOW, "A list item is not a header": kept. It is the discriminator for one test, and the check marks low severity as optional.
- Alignment, `anchored_refs_in` shape and order: stated in the description (document key and anchor pair, in document order) rather than relaxing the test, since the order is a real contract.
- Alignment, lookups returning nothing: one clause added covering all four lookups.
- Tests-quality, `iwe stats` formatting: relaxed instead of specified. The section is now found by its label at any heading level and an entry is matched by source and target appearing on one line, so no test pins the report's layout. The description keeps only the section label.

## AI coverage suggestions round 1 (2026-08-02)

Four advisory suggestions, all taken (a coverage suggestion has surfaced a real reference bug before, so each was run rather than reasoned about). Nine tests added, none of which found a defect:

- `AnchoredHeader` payload: `anchors` is now asserted on the id and the text of every header, each id is checked to be the one `resolve_anchor` returns, and repeated headers are checked to keep distinct nodes.
- Exact-match semantics: a differently cased anchor, three punctuation variants, and a cased anchored inclusion that must stay a link.
- Backlink deduplication: a source document linking to one anchor three times is named once, and the sorted list still holds the second source.
- Empty fragments in the reporting APIs: `key#` is excluded from both `anchored_refs_in` and `dangling_anchors`, complementing the inclusion-side test.

The description gained three words so the backlink contract states deduplication ("sorted, each named once"), which is what the new test pins.

## AI coverage suggestions round 2 (2026-08-02) - one real bug

Four more suggestions, all taken. One of them found a genuine defect in the reference, which is exactly why these get run rather than reasoned about.

- **Rename-header wiki backlinks: BUG.** Retargeting a wiki link dropped its fragment: `[[2#part-one]]` came back as `[[2]]`. Root cause: the projector builds a wiki url from `display_url` alone, and the relocation clears `display_url` when it rewrites a reference, so the anchor was lost. The first fix (the inline arm of `resolve_inline`) was only half of it; block level references have their own url branch in `project_node` and needed the same treatment. Both arms now run the base through `Reference::anchored_url`, which was made fragment-aware so a Preserve-mode url that already carries the fragment is not double-suffixed. The same defect also hit plain export under `WikiLinkPath::Full` and `Short`, where `wiki_display` returns a bare key: two round-trip tests now pin that, on top of the plain and piped retarget tests.
- Cross-key dangling sort order: a case spanning two sources and two targets pins the full source, target, anchor ordering.
- Percent decoding in the reporting APIs: `anchored_refs_in` and `dangling_anchors` both report the decoded fragment, including one that stays dangling.
- Slug collision on a moved title: a guest title colliding with the host title on inline, and an extracted section colliding with a nested header of the same text, both keeping every inbound link on its own header.

## AI coverage suggestions round 3 (2026-08-02)

Four suggestions, all taken, nine tests added, no defect found this time.

- Malformed percent escapes: pinned only what the description supports. An invalid escape (`%zz`) and a truncated one (`%C3`) resolve to nothing and stay a link, which follows from exact slug matching; the decoded form of a malformed byte sequence is deliberately NOT asserted, since the description says escapes are decoded but says nothing about invalid input and pinning a replacement character would be a hidden requirement.
- `rename_header` self-links: an anchored link elsewhere in the renamed header's own document, and one inside the renamed section itself, both follow the rename.
- Formatting-heavy header text: code span, image description and nested link text all feed the slug through the repo's own plain-text notion.
- Stats deduplication: three identical broken anchored links in one document render one line, not only one `dangling_anchors()` record.

## Test Fairness round 1 (2026-08-02) - FAIL on 3 of 120, fixed

All three flagged tests pinned a representation the description left open. Each was fixed by stating the contract rather than weakening the test, because both are real contracts a solver needs anyway:

- `dangling_anchors_are_sorted_across_documents` pinned source, then target, then anchor precedence while the description only said "sorted". The description now says "deduplicated and sorted by source, then target, then anchor".
- `a_percent_escaped_fragment_is_reported_decoded` and `a_percent_escaped_fragment_dangles_decoded` required the decoded spelling from the reporting APIs while the description only mandated decoding "before matching". One word: escapes are now decoded "before matching and reporting".

Both edits cost 7 words and the opening sentence was tightened by 4 to keep headroom under the 500 cap (496 now). No test was relaxed.

Three advisory suggestions also taken, 8 tests added: the lookup-miss matrix (`anchor_text` for unknown slug and unknown document, `anchored_refs_in` for an unknown source), percent-encoded identity through `rename_header` and through extract (the rewrite emits the plain recalculated slug), and error atomicity for all three `rename_header` error classes (the workspace export is byte-identical after each).

## Test Fairness round 2 (2026-08-02) - FAIL on 3 of 128, fixed

The three flagged tests were the malformed and incomplete percent-escape cases, which the PREVIOUS round's coverage suggestions had asked for. The two checks genuinely disagree here, and the fairness gate is the blocking one, so it wins: an advisory request for more coverage does not license a test whose expected value the description never fixes.

- `a_malformed_percent_escape_stays_a_link` and `an_incomplete_percent_escape_stays_a_link` were deleted. They pinned one of several defensible malformed-input policies (preserve, reject, decode lossily, treat as unanchored), and the description states none of them. Adding the policy to the description would spend words at the 500 cap on an edge case that carries no feature value.
- `a_malformed_percent_escape_resolves_to_nothing` was rewritten as `an_anchor_holding_a_percent_sign_resolves_to_nothing`, keeping only the half the stated rules imply: a slug is built from letters and digits, so no slug can ever hold a percent sign, whatever the decode policy is. The dangling-count assertion, which is the part that pinned a policy, is gone.

Two quality flaws the same review raised were also fixed, both real:

- The CLI tests searched the filesystem for a prebuilt `iwe` binary (the convention in the repo's own `crates/iwe/tests/common.rs`), which risks running a stale binary. They now use `env!("CARGO_BIN_EXE_iwe")`, so cargo guarantees a fresh build, and the `cargo build -p iwe` line in `test.sh` new mode is no longer needed.
- The three `rename_header` atomicity tests resolved a NodeId against one graph and then rebuilt a second graph inside the helper, so two of them could have passed for "unknown id" rather than the intended error. The helper now takes the graph it was resolved from.

Three advisory suggestions taken, three tests added: an ASCII escape (`%2D` decoding to a dash so `part%2Done` resolves), `anchored_refs_in` returning a repeated link repeatedly in occurrence order, and a three-way rename collision renumbering to `other`, `notes`, `notes-2`.

## Test Fairness round 3 (2026-08-02) - FAIL on 8 of 129, fixed

- All seven CLI stats tests required the rendering `target#anchor` on one line. The description only names the Broken Anchors section, and the pre-existing Broken Links template only establishes `source -> target`, so the concatenation was mine. The tests now assert that a line in that section mentions the source, the target and the anchor in any layout, and the negative assertions became "no line in that section mentions X" instead of a whole-report substring. The sorting test compares line positions rather than character offsets of a combined token. Nothing about what is reported was weakened; only the layout coupling is gone.
- `an_anchor_holding_a_percent_sign_resolves_to_nothing` also asserted that `resolve_anchor("part%2Done")` is None. "Escapes are decoded before matching" can fairly be read as applying to a direct lookup argument too, so that assertion was ambiguous and is removed. The remaining assertion (`part%zz`) holds under either reading, because a slug is built from letters and digits and can never contain a percent sign.

## Solvability audit (2026-08-02)

No agent batch has run, so the pass rate is still unmeasured. What was verified mechanically is the failure mode that produces a fake 0% on a statically typed host: a test binary that cannot compile against a CORRECT implementation.

- The tests never import `AnchoredHeader` or `DanglingAnchor` by path. They only call methods and read fields, so an implementer may place those types in any module.
- The eight new `Graph` lookups are called on a `Graph` value with `GraphContext` in scope, so they compile whether an implementer makes them inherent methods or trait methods on `&Graph`.
- Two real risks were found and closed in the description: the tests import `rename_header` from `liwe::operations` (now written `operations::rename_header`), and they compare `resolve_anchor` against a header id (the description now says it gives "the header's node"). Either mismatch would have compile-wiped all 132 library tests regardless of skill.
- Every field name the tests read is pinned in the description: `AnchoredHeader { id, slug, text }` and `DanglingAnchor { source_key, target_key, anchor }`.

The remaining unmeasured risk is difficulty, not fairness. A local imitator simulation (several Sonnet solvers given only meta.md and the repo) is the cheap pre-platform oracle and has not been run.

## AI coverage suggestions round 4 (2026-08-02) - second real bug

Two wiki-syntax suggestions, both taken, four tests added. One found a genuine defect.

- **Fragment-only wiki links: BUG.** `[[#part-one]]` on its own line became an anchored reference to the EMPTY key, contradicting the description's rule that a url which is only a fragment is not a document link. Two causes: the guard in `document.rs` tested the RAW url with `starts_with('#')`, which percent-encoding in the wiki path defeats, and a lone link on a line never reaches that guard at all - `DocumentBlock::is_ref` decides block references and only checked `is_ref_url`, so `sections_builder` resolved the key directly. Both now go through a new `model::is_fragment_only_url`, which decodes before testing. The markdown form was already correct because its url is not percent-encoded, so only the wiki form was broken.
- Percent-decoded wiki fragments: `[[2#stra%C3%9Fe]]` resolves to the `Straße` header and is reported decoded when dangling, confirming the decoding rule is syntax-independent.

## AI coverage suggestions round 5 (2026-08-02) - third real bug

Three suggestions, all taken, three tests added. One found a defect, and it was the reference contradicting its OWN description.

- **`anchor_backlinks` on an unanswered anchor: BUG.** The description says every lookup yields nothing when no header answers, and `anchor_backlinks` is in that list, but the implementation scanned links by string and returned the linking documents even when the anchor resolved to nothing. A workspace with a dangling `2#missing` link got `["1"]` back instead of an empty list. It now returns empty unless the anchor resolves, which also keeps a clean split of duties: `anchor_backlinks` answers for real headers, `dangling_anchors` answers for the unresolved ones.
- `rename_header` over a percent-escaped wiki link passed as written: `[[2#stra%C3%9Fe]]` becomes `[[2#other]]`, so decoded identity tracking and wiki serialization compose.
- CLI cross-document ordering passed as written: four documents produce Broken Anchors lines ordered by source, then target, then anchor, checked by line position so no layout is pinned.

## First Nova run (2026-08-02) - FAIL_TEST_MISMATCH, my bug

Verdict: baseline green, new test target did not COMPILE. The evaluator's finding is correct and I confirmed it directly, so this is not contestable as an environment defect.

- Cause: the description said `resolve_anchor(key, anchor)` gives "the header's node". The repo already has `GraphContext::node(id) -> impl NodePointer` (`crates/liwe/src/graph.rs:862`), so in THIS codebase "node" reads as a pointer. The agent implemented `Option<impl NodePointer>`; the tests compare against a `NodeId`; the target failed to build and all 138 library tests reported as failures. The agent's reading was at least as natural as mine.
- This is the exact failure class my own solvability audit two rounds earlier had flagged and thought it had closed by adding the words "the header's node". Prose was not enough: on a statically typed host the signature has to be written out.
- Fix: every new signature is now spelled in the description, not described. `anchors(key) -> Vec<AnchoredHeader>` with `AnchoredHeader { id: NodeId, slug: String, text: String }`, `resolve_anchor -> Option<NodeId>`, `anchor_text -> Option<String>`, `anchor_of(id: NodeId) -> Option<String>`, `anchored_markdown -> Option<String>`, `anchor_backlinks -> Vec<Key>`, `anchored_refs_in -> Vec<(Key, String)>`, `dangling_anchors() -> Vec<DanglingAnchor>` with `DanglingAnchor { source_key: Key, target_key: Key, anchor: String }`, and `rename_header` returning `Result<Changes, OperationError>` rather than "returning `Changes`". Cross-checked against the reference: all nine match.
- The description stayed at 496 words by tightening prose elsewhere. No test changed, so the patches are unchanged.
- The run itself is void as a difficulty datapoint: it measured the ambiguity, not the solver. Pass rate remains unmeasured.

## Auto Review revision round 1 (2026-08-02) - T5 closed both ways

The single blocking finding was the `resolve_anchor` return type: the description said "the header's node" and the test helper hard-coded `NodeId`, so an implementation returning `Option<impl NodePointer>` could not compile the target and synthesized 138 failures. The reviewer allowed either remedy; both are now in place, because a type mismatch anywhere in a Rust test file wipes the whole target and cannot be contained by moving the coupling around.

1. The contract is written out, not described. All nine new signatures are spelled in the description: `anchors(key) -> Vec<AnchoredHeader>` with `AnchoredHeader { id: NodeId, slug: String, text: String }`, `resolve_anchor(key, anchor) -> Option<NodeId>`, `anchor_text(key, anchor) -> Option<String>`, `anchor_of(id: NodeId) -> Option<String>`, `anchored_markdown(key, anchor) -> Option<String>`, `anchor_backlinks(key, anchor) -> Vec<Key>`, `anchored_refs_in(key) -> Vec<(Key, String)>`, `dangling_anchors() -> Vec<DanglingAnchor>` with `DanglingAnchor { source_key: Key, target_key: Key, anchor: String }`, and `operations::rename_header(...) -> Result<Changes, OperationError>`. Cross-checked against the reference: all nine match.
2. The tests no longer require the representation. `header_id` now takes the node from `AnchoredHeader.id`, whose type the description pins, instead of from `resolve_anchor`. Every remaining `resolve_anchor` assertion is `.is_some()` / `.is_none()`, so the return type is never constrained by the suite.

Proof rather than assertion: the exact rejected design was reimplemented (`resolve_anchor<'g>(&'g self, ...) -> Option<impl NodePointer<'g>>`, with an internal id helper for the callers) and it compiles and passes all 138 library tests against the revised suite. The reference was then restored and re-verified.

Answer to the upstream-ahead advisory: `2a15d99` rewrites `Key::to_rel_link_url` so a link to a hub in a parent directory keeps its file name. `git show 2a15d99 | grep -c anchor|fragment` is 0, and its test changes are in delete/normalize/rename CLI tests about path spelling. It neither implements nor supersedes fragment resolution, so the post-base commit is unrelated to this fix. Rebasing was rejected on purpose: it would stale the batch that produced the 3 passes, for no correctness gain.

Difficulty, from the batch: 3 of 10 passed (30%), inside the cap. The seven failures all preserved the 1871-test baseline and clustered on wiki-link paths, five of them passing 143-145 of 146. That is the interdependent-trap behavior this problem was designed around, and it is the same trap that caught the reference twice during authoring.

## AI coverage suggestions round 6 (2026-08-02)

Two of three taken, four tests added, no defect found in the reference.

- Formatted header text: `AnchoredHeader.text` and `anchor_text` both return `some bold code text` for `## some *bold* \`code\` text`, so the plain-text rule that governs the slug also governs the reported text.
- Duplicate-anchor identity: taken, but deliberately NOT through `resolve_anchor`. Asserting that `notes-2` resolves to the second NodeId would re-pin the return type the Auto Review just failed this submission over. The same fact is asserted with pinned types instead: `anchor_of` round-trips the second and third headers to `notes-2` and `notes-3`, and `anchored_markdown("notes-2")` returns the SECOND section's body. That proves resolution reaches the right node without constraining its representation.
- Malformed escape reporting: SKIPPED on purpose, and the suggestion itself is conditional ("if malformed percent escapes have a stable intended policy"). They do not. Round 3 suggested these tests, round 4's Test Fairness gate failed the submission for them because preserve / reject / decode-lossily / treat-as-unanchored are all defensible and the description fixes none, and they were removed. Re-adding them would re-open a fairness FAIL to satisfy an advisory note.

One test defect of my own was caught while writing these: the first draft rebuilt the graph inside a map, so `anchor_of` received node ids from a different Graph instance and returned None. That is the same cross-instance flaw the earlier fairness review found in the atomicity helper. Fixed, and the suite was grepped for other instances of the pattern (none).

## AI coverage suggestions round 7 (2026-08-02)

Three suggestions, all taken, three tests added, no defect found.

- Backlink sorting is now distinguished from traversal order: four documents keyed `zulu`, `middle`, `alpha`, `target` are inserted in that order and the backlinks come back `alpha`, `middle`, `zulu`.
- CLI empty-fragment behaviour: a workspace holding both `two#` and `two#missing` renders exactly one Broken Anchors line, and it is the `missing` one. The genuinely broken anchor is the canary, so the test cannot pass vacuously on base the way a bare "not listed" assertion would.
- `anchored_refs_in` on a resolved percent-escaped wiki fragment returns `("2", "straße")`, closing the last gap in the percent-escape matrix (expansion, dangling report and now the reference listing, for both markdown and wiki syntax).

## AI coverage suggestions round 8 (2026-08-02)

Three suggestions, all taken, four tests added, no defect found.

- CLI decoded-fragment reporting: a dangling `two#stra%C3%9Fe` prints under Broken Anchors as `straße`, and the whole report is asserted to hold no `%C3`, so the decoding rule is verified through the renderer and not only at the Graph level.
- Backlinks across syntaxes: `anchor_backlinks` counts a wiki block link in one document and a table-cell inline link in another, returning both sources sorted. That reaches the API with the two forms the description calls out (wiki links carry fragments the same way, block level and inline links both count).
- Unknown node id: `rename_header` with `NodeId::MAX`, a node that exists nowhere in the graph, errors and leaves the workspace export byte-identical. This is distinct from the paragraph-node and wrong-document cases already covered.

## Test Fairness round 4 (2026-08-02) - FAIL on 1 of 157, fixed

Flagged: `a_self_anchored_inclusion_terminates`, for pinning "an exact two-copy cycle cutoff at squash depth 8".

The mechanics in that reading are wrong, and it was worth checking before changing anything: the fixture has the link at document level and the `deep` section it addresses contains no link, so nothing recurses. Squashing at depths 1, 2, 4, 8 and 16 gives byte-identical output, so no cutoff is being pinned. The expected value is the stated inclusion rule applied once (the link becomes the addressed section, nested at the link's position) plus the original section, which no rule removes.

What WAS wrong is mine: the test name said "terminates", which framed a plain in-document inclusion as a cycle-termination guarantee and invited exactly that misreading. Renamed to `an_anchored_inclusion_of_the_same_document_expands_in_place`; the assertion is unchanged because it was already the mechanical consequence of a stated rule. Cycle termination itself is pre-existing squash behavior with its own visible test at `crates/liwe/tests/squash_test.rs:251-281`, and this suite makes no claim about it.

Coverage suggestions this round:

- Empty lookup argument: taken. `resolve_anchor`, `anchor_text`, `anchor_markdown` and `anchor_backlinks` all answer nothing for `""`. This is derivable rather than new policy: the `section` fallback means a slug is never empty, so `""` can never answer, and the description already says every lookup yields nothing when no header answers.
- Direct escaped lookup arguments: SKIPPED for the third time, on the same grounds. Whether decoding applies to a lookup ARGUMENT (as opposed to a link fragment) is genuinely unspecified, and a test either way is what Test Fairness round 2 failed this submission over when it rejected `resolve_anchor("part%2Done")`. It is also harmless to leave open: no test constrains it, so an implementation that decodes its arguments and one that does not both pass.

## AI coverage suggestions round 9 (2026-08-02) - fourth real bug

- **Slug suffix collision: BUG, and a silent one.** Headers `notes`, `notes`, `notes-2` produced slugs `notes`, `notes-2`, `notes-2`: two headers answered to the same anchor and the third was UNADDRESSABLE, with `anchored_markdown("notes-2")` returning the second header's body. That contradicts the description's own rule, since `notes-2` was already taken when the third header claimed it. The counter was keyed on the base slug only, so a written suffix could never see a generated one. `number_anchor_slugs` now keeps the set of emitted slugs and keeps incrementing until the candidate is free, which is the standard slugger rule and matches the description as written. The fixture now yields `notes`, `notes-2`, `notes-2-2`, and three tests pin it: the slug list, both colliding headers staying separately addressable, and a rename that frees `notes-2` renumbering an inbound `notes-2-2` link down to it. No description change was needed - the fix made the code match the prose.
- Dangling anchors in tables: added. A dangling table-cell link is reported with its source, target and anchor, completing the table coverage next to the resolved-cell cases for `anchored_refs_in`, backlinks and rename retargeting.
- Direct escaped lookup APIs: SKIPPED for the fourth time. This is now a settled decision, not an oversight. Whether a caller-supplied lookup argument is decoded is unspecified, Test Fairness round 2 failed this submission for a test that pinned it, and leaving it open costs nothing because no test constrains it, so implementations that decode arguments and implementations that do not both pass. Closing it would mean spending description budget to add a convention with no feature value and a new way to fail, which is the fake-difficulty anti-pattern.

One test-authoring slip caught in the process: the first draft of the rename fixture omitted a duplicate header, so its inbound link was dangling before the rename and the expectation was unreachable. Fixed.

## AI coverage suggestions round 10 (2026-08-02)

Three suggestions, all taken, five tests added, no defect found.

- Fragment-only block inclusion: a standalone `[label](#part-one)` line and a standalone `[[#part-one]]` line both survive squash as links instead of expanding. These exercise the `DocumentBlock::is_ref` guard added when the fragment-only wiki bug was fixed, from the block-inclusion side rather than the query side.
- Refactors with wiki links: extract and inline now have wiki inbound links, plain and piped. Extract turns `[[1#part-two]]` into `[[extracted]]` and `[[1#deep|label]]` into `[[extracted#deep|label]]`; inline turns `[[2#part-one]]` into `[[1#part-one-2]]` and keeps the pipe label. Both passed first time, which is the useful result: the wiki path had produced three of the four bugs found in this cycle, and the projector fix covers extract and inline as well as rename.
- Unknown node id lookup: `anchor_of(NodeId::MAX)` is None rather than a panic, so an out-of-range id is handled at the lookup surface and not only through `rename_header`.

## AI coverage suggestions round 11 (2026-08-03)

- Node identity consistency: taken, but NOT the way it was phrased. The suggestion was to assert `resolve_anchor(key, slug) == Some(header.id)`, which is verbatim the assertion removed to close the blocking T5. The description now pins `-> Option<NodeId>`, so that form would be fair today, but re-adding it would give back the second half of the two-part fix and restore a compile-wipe vector that already cost one scratched run. The same fact is proven behaviorally instead: `both_lookup_directions_reach_the_same_header` renames each header BY ITS NODE ID and checks that the document then answers to the renamed slug, so slug lookup and node id are shown to reach the same header through an operation, with no dependency on the return representation.
- Error taxonomy: skipped, as the suggestion itself allows ("The current suite correctly checks only `Err`, matching the prompt"). The description says only that those cases are errors; asserting specific `OperationError` variants would pin an unstated contract.

A local infrastructure note, not a submission defect: this round's first validation pass reported 0 test cases after applying solution.patch. The cause was the authoring machine reaching 100 percent disk (67 MB free), so `cc` died with `ld terminated with signal 7 [Bus error]` during linking. After pruning docker and the scratch clones, the same patches rebuilt and revalidated clean. Worth recording because an empty JUnit file looks exactly like a broken artifact.

## Test patch sanity check (2026-08-03) - exit status fixed

Warning: in new mode, if cargo succeeded but discovered zero tests, `test.sh` synthesized JUnit failures while `STATUS` stayed 0, so the script could exit 0 with a report full of failures. Correct and worth fixing: an evaluator that trusts the exit code would read that run as a pass.

- `synthesize_failures` now sets `STATUS=1`. Synthesizing is by definition a failing report, so the exit code has to agree with the XML.
- Base mode now also fails when it discovers zero tests at all. That case was not in the warning, but it is the same class and it is exactly what the disk-full incident produced one round earlier: an empty JUnit file written with exit 0. A base run that finds no tests is a broken environment, not a pass.

Both were verified by forcing the degenerate cases rather than by reading the script. Substituting a command that succeeds silently for the new-mode cargo invocation gives exit 1 with 168 synthesized cases; doing the same for all three base invocations gives exit 1 with an empty report. The real runs are unaffected: new mode exits 0 with 168 passing cases, base mode exits 0 with 1871.

Every other item in the check was already clean: valid git diff, both modes present, executable bit 100755, no solution code (`grep -c "tests/" solution.patch` is 0), no package installs, no Dockerfile changes.

## Solution Quality FAIL (2026-08-03) - my rename broke the expected-test manifest

Verdict FAIL, marked Stale, on one line: the merged JUnit still carried a synthesized failure for `a_self_anchored_inclusion_terminates`. Nothing was wrong with the solution. That test EXISTED when the batch snapshot was taken, and I renamed it to `an_anchored_inclusion_of_the_same_document_expands_in_place` in the Test Fairness round. A name in the expected set that no longer exists is synthesized as a failure, so every evaluation fails until the name comes back.

This is a rule already recorded in project memory as `olympus-f2p-testname-immutable`: never rename or delete a test FUNCTION once a batch has run. I broke it while fixing something else, which is exactly how that rule gets broken.

- The name is restored. The assertion is unchanged in substance and now runs at depths 1, 2 and 8 with the same expected output, which also settles the fairness objection that produced the rename: the claim was an "exact two-copy cycle cutoff at squash depth 8", and a test that asserts the identical result at three depths cannot be pinning a depth cutoff.
- Manifest alignment verified rather than assumed. The evaluator saw 158 library and 10 CLI tests with exactly ONE missing name, which places the snapshot after the malformed-escape removals of Test Fairness round 2 and before this rename. Current counts are 158 library and 10 CLI with the name present, so the sets line up exactly. The restored name appears passing in the post-solution JUnit: `name="a_self_anchored_inclusion_terminates"` with no failure child.
- The reviewer's secondary remark, that anchored expansion leans on depth reduction rather than explicit cycle detection, is deliberately NOT changed. Depth reduction is the repository's own cycle policy for inclusion and has its own visible test at `crates/liwe/tests/squash_test.rs:251-281`. Adding cycle detection to the anchored path alone would make the two inclusion paths disagree, and adding it to both would regress that existing test. The reviewer framed it as a suggestion arising from the failing case; with the case passing, the inference no longer stands.

Standing rule for the rest of this submission: test function names are frozen. Fairness feedback about a test gets fixed in the assertion or the description, never by renaming.

## FP check (2026-08-03) - false positive confirmed, discriminator added

The adjudicator found a passing candidate that double-decodes percent escapes: `model::split_reference_url` decodes once at ingestion, then its `resolve_anchor` decodes AGAIN. A singly-escaped fragment is idempotent under the second decode, so all 168 tests passed, but `[](2#foo%252Dbar)` against a header `## Foo bar` decoded twice to `foo-bar` and falsely RESOLVED, silently dropping a genuinely broken anchor from `dangling_anchors()` and from the `iwe stats` Broken Anchors report.

Per the FP doctrine this is an environment defect, not an agent defect: a pass without meeting a requirement means the tests or the description are wrong. The reference was already correct here (decodes once to `foo%2Dbar`, no slug answers, reported dangling), so the gap was purely missing coverage: every escape test in the suite used a SINGLY escaped fragment, which cannot discriminate.

- Five tests added, all routed through PARSED LINKS rather than lookup arguments, so they do not touch the still-open question of whether a caller-supplied argument is decoded: `anchored_refs_in` reports the once-decoded `foo%2Dbar`; `dangling_anchors` reports it with source and target; the block link stays a link instead of expanding; neither the decoded nor the once-decoded spelling produces backlinks; and `iwe stats` lists it under Broken Anchors.
- The discriminator was PROVEN, not assumed. Reproducing the candidate's bug (an extra `percent_decode_str` inside `resolve_anchor`) makes exactly three of the new tests fail while the other 159 still pass, which is the signature of a probe that isolates this defect and nothing else. The reference was then restored and reverified.
- The description now says escapes are decoded "once" before matching and reporting (+1 word, 497). The old wording plus "resolution matches the slug exactly" already implied it, since a slug holds only letters, digits and dashes and can never equal a string containing a percent sign, but the FP shows that implication was too indirect to rely on.
- Singly-escaped coverage is retained, so the contract is now pinned from both sides: `stra%C3%9Fe` resolving proves decoding happens at least once, and `foo%252Dbar` dangling proves it happens at most once.

## Test Fairness round 5 (2026-08-03) - the same test, resolved without renaming

`a_self_anchored_inclusion_terminates` was flagged a second time, now for pinning "exactly one duplicated section and identical output at depths 1, 2, and 8". Last time I answered by renaming, and Solution Quality then failed because the name is locked in the expected-test manifest. So the two gates constrain different things and both can be satisfied: the manifest tracks the NAME, fairness tracks the ASSERTION.

The name stays. The assertion no longer pins any cycle policy: the test now checks that the addressed section appears in the output and that the line is no longer a link. Both follow directly from the one stated rule, that a link alone on a line carrying a fragment includes the addressed header and everything under it. The copy count and the depth loop are gone, so there is nothing left for a cycle-policy objection to attach to. What the test still catches is real: an implementation that fails to expand a same-document anchor, or that leaves the link in place, fails it.

The `squashed_at` helper existed only to argue the depth point and was folded back into `squashed`.

Coverage suggestions, both taken:

- Extraction and inlining with inbound links inside table cells. Extract rewrites a cell link to `[label](extracted)`, inline rewrites it to `[label](1#part-one-2)`. Tables were already covered for reporting and header rename, so this closes the refactor half.
- Unicode combining marks. `# cafe\u{301} and \u{00e9}clair` slugs to `cafe-and-éclair`: the combining acute is not a letter or a digit, so it joins the following run and collapses to one dash, while the precomposed `é` is a letter and survives. That is the stated rule applied to marks, and it makes the letter-or-digit test observable for a character class that is easy to get wrong.

## FP check round 2 (2026-08-03) - genuine pass, reference wording tightened

Verdict: genuine pass, unanimous, high confidence. The adjudicator materialized the verifier worktree and
independently reproduced 165 + 11 + 450 tests with zero failures.

One note in that report is worth acting on even though it did not change the verdict: two judges observed the
candidate is MORE spec-correct than the reference, because it percent-decodes the `resolve_anchor` argument
while the reference does not. That is the lookup-argument ambiguity I chose to leave open across five
coverage rounds on the reasoning that both readings pass, so it was harmless. It was not harmless: it turned
into a reviewer judging the pinned reference the weaker artifact.

The two readings are also mutually exclusive, which the earlier FP round had already proven. `dangling_anchors`
resolves each link's stored anchor, which is ALREADY once-decoded, so decoding again inside `resolve_anchor`
re-creates precisely the double-decode that let a candidate silently drop broken anchors. The reference's
behavior is the correct one; the description was simply not explicit about it.

Fixed by saying where and how often decoding happens: "Percent escapes in a fragment are decoded once, when
the link is read, an empty fragment carries no anchor, and a lookup matches the slug exactly as given." That
removes the "before matching" phrasing a judge read as covering API arguments, and makes the reference
unambiguously the spec-correct implementation. No code and no tests changed, so the patches are unchanged;
the description stays at 496 words after trimming two phrases elsewhere.

Lessons recorded outside this problem, so the next problem does not repeat them:
`.claude/skills/olympus-author/SKILL.md` gained an "FP-proofing the test suite" section (the fixed-point
trap, the silent-omission shape of reporting APIs, pinning ambiguous readings, and proving each
discriminator by breaking the reference on purpose), plus a memory entry `olympus-fp-fixed-point-trap`.

## Open items

- No agent batch has been run. Predicted pass rate 10-25%; if a batch lands over 40%, the first lever is to stop stating the renumbering rule so explicitly and instead let it follow from the numbering sentence (fairness stays, discoverability drops).
- Platform submission count for iwe is unknown (only the platform page shows it). The repo is not in `SATURATED-REPOS.md` and is not an author-obvious category host, but confirm before submitting.
