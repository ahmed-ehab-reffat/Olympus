# DESIGN.md — comrak-reference-style-links

Base commit: `835e68ea438868fdd2ee8e53683b26cd73d5f67d` (kivikakk/comrak, 2026-08-04)

## 1. Title

**Add reference-style link and image output to the CommonMark renderer**

## 2. Shape classification

- **Shape:** O-Composite-add (new capability spanning renderer + options + CLI), with an
  O-Algorithm-correctness core (the label sequence is a document-global assignment).
- **Pass rate target:** <=40% ceiling, designing for the 10-25% band.
- **Best agent:** mixed; expect the lone passer to be a long-horizon Orion (SPEED-CORRELATES-WITH-FAILURE).
- **Dominant verdict predicted:** MISSED_REQUIREMENT (exclusion-before-numbering), then REGRESSION
  (prefix/width machinery).
- **Span:** `src/cm.rs` (streaming renderer) + `src/parser/options.rs` (option surface) + `src/main.rs`
  (CLI). Cross-subsystem within the crate: the collection pass is a NEW document-level phase in a
  renderer that has never had one.

## 3. Public API surface

- `options.render.reference_links: bool` — when true, the CommonMark renderer emits reference-style
  links/images plus a definition block. Default false.
- `--reference-links` — CLI flag selecting the same behaviour.
- No new public types. The capability is observable entirely through `format_commonmark` /
  `markdown_to_commonmark` output.

## 4. Canonical output form (INVENTED — not taken from issue #740, which is only evidence the
maintainer welcomes the lane)

1. **Label alphabet:** decimal integers starting at `1`, no padding.
2. **Assignment order:** first appearance in document order of each distinct *target*.
3. **Target identity:** destination AND title compared byte-for-byte. Same destination with a
   different title is a DIFFERENT target and gets its own label.
4. **Sharing:** links and images draw from ONE shared numbering sequence. A link and an image with
   an identical target share a label.
5. **Participation (evaluated BEFORE a label is assigned):** autolinks (`<https://x>`) and any link
   or image whose destination is empty do NOT participate; they render inline exactly as today and
   consume no label.
6. **Reference syntax:** `[text][N]` for links, `![alt][N]` for images.
7. **Definition block:** emitted after all document content, one definition per line, ascending label
   order, `[N]: destination` with ` "title"` appended when the title is non-empty.
8. **Definition block layout:** always at column zero with no container prefix, and never wrapped,
   regardless of `render.width` or the container the link appeared in.
9. **Empty document / no participating links:** no definition block, and no trailing blank line
   beyond what is emitted today.
10. **Option off:** output byte-identical to today.

## 5. Blind-spot pre-empts

- Ordering/dedup: canonical form items 2-4 are stated as prose in meta.md.
- Result ordering: item 7 ("ascending label order").
- Falsy-on-invalid: item 5 (empty destination stays inline).
- Pipeline placement: item 5's "before a label is assigned" is the ONE sentence that makes the lead
  trap fair without handing the fix (see § 11).

## 6. Description draft

See `meta.md` (written after this design is approved). Target <=200 words, plain prose, the ten
canonical-form rules compressed into 3 paragraphs. Rule-7 discipline: state the participation
PRINCIPLE, never enumerate the interaction cases (image-vs-link sharing, blockquote definitions,
width interaction) — those are derived consequences and stay untested-by-description, tested-by-suite.

## 7. File footprint (sketched against real source)

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | `src/cm.rs` | 1394 | +210 | ~150 | collection pre-pass, label table, reference emission in `format_link`/`format_image`, definition block writer that bypasses prefix+wrap |
| MODIFY | `src/parser/options.rs` | 1400+ | +45 | ~20 | `reference_links` option + doc-comment doctest (repo convention) |
| MODIFY | `src/main.rs` | — | +12 | ~10 | CLI flag wiring |
| NEW | `src/cm/refs.rs` (if extraction reads cleaner) | — | +120 | ~90 | label table, target identity, participation predicate as pure functions |
TOTAL: ~+387 raw / ~270 meaningful across 3 modified + 1 new.

Clears the >=200 meaningful floor with buffer; >=2 files satisfied. **Risk flagged:** if the label
table collapses into ~40 lines inside `cm.rs`, this lands near 200 and needs a genuine scope lever
(most likely: `--reference-links` round-trip stability under `width`), NOT padding.

## 8. Solution outline — pure-function helpers

- `participates(node, nl) -> bool` — item 5's predicate; the ONLY place exclusions are decided.
- `target_key(nl) -> (&str, &str)` — item 3's identity.
- `LabelTable::assign(&mut self, key) -> usize` — first-appearance numbering, item 2.
- `collect_labels(root) -> LabelTable` — the new document-level pre-pass, walking in document order.
- `write_definitions(&mut self, table)` — item 7/8, writes direct to output bypassing prefix + wrap.

The pre-pass is the architectural change: the renderer is a streaming walker with `entering`/exiting
callbacks and no whole-document phase. Labels cannot be assigned during the stream because a
definition block requires knowing every target before the first `[text][N]` is written.

## 9. Test file outline

Path: `src/tests/reference_links_<hex>.rs` (repo convention: `src/tests/*.rs`, registered in
`src/tests.rs`). Harness: the repo's existing `html_opts!`-style macros plus
`commonmark(input, expected, options)`.

Buckets:
- numbering + first-appearance order (incl. a target first seen inside a nested container)
- dedup: same dest+title shares; same dest different title splits
- link/image shared sequence
- participation: autolink and empty-destination excluded AND consuming no label ⭐ (the lead
  discriminator: a doc where an autolink precedes two normal links; wrong impls emit 2,3)
- definition block: placement after footnote definitions, column zero from inside a blockquote,
  unwrapped at `width = 20`
- option off: byte-identical baseline
- round-trip: re-parsing the output yields the same HTML as the original

## 10. Forced bounds

None unusual. The pre-pass borrows the arena-allocated `Node<'a>` tree immutably while the renderer
holds `&mut self` — the label table must be built BEFORE the walk begins, not lazily during it. That
borrow shape is itself part of the difficulty and needs no description support.

## 11. Trap matrix — ALL REPRODUCED against the real renderer (2026-08-05)

Each row was built as the natural-but-wrong implementation and run; the symptom column is measured
output, not a prediction.

| # | Trap | Axis | F-id / Arsenal | Measured wrong output | Misdirection |
|---|---|---|---|---|---|
| **A** | **Exclude-before-number.** Autolinks and empty destinations must be filtered BEFORE numbering | WHICH links participate | F-9 / A8 precedence inversion | `<http://z.com> then [a][2] then [b][3]` + a stray `[1]: http://z.com` | The failing assertion is on ORDINARY links (`[a][2]`), nowhere near the autolink rule that caused it |
| **B** | **Document-order numbering.** Labels are assigned in document (pre-)order, so an outer link outranks an image nested in its own text | WHEN labels are assigned | F-1 / S4 | `[![alt][1]][2]` instead of `[![alt][2]][1]` | Every FLAT document still passes; only nesting reveals it (P3 self-test-shadow) |
| **C** | **Title participates in target identity.** Same destination, different title = different targets | target IDENTITY | F-10 / S2 | one label for two distinct targets | "same url = same link" is the dominant reading |
| **D** | **One shared sequence for links and images.** Separate tables give an identical target two labels | table SCOPE | F-10 / S2 | `![alt][1] and [a][2]` instead of both `[1]` | Images render through a different function; two tables is the natural structure |
| **E** | **The definition block must bypass the wrapping writer.** Written with `write!(self, ..)` it re-enters `output()` | OUTPUT PATH | F-9 / S4 | `[a][1] more\n[a][1] more\n\n\n[1]: ...` — a DUPLICATED paragraph line and stray blank lines | Reads as a corrupted paragraph, not as a definition-emission bug |
| **F** | **Option off = byte-identical.** A collection pass that mutates nodes changes HTML output too | BASELINE | S3 | — (guarded by the full 649-test base suite) | Failure appears in unrelated existing tests |

**Orthogonality:** A, B, C, D, E, F sit on six different axes — which links count, when they are
numbered, what makes two targets equal, how many sequences exist, how the block reaches the output,
and whether the old path still holds.

⭐ **Interdependence (a genuine cycle, measured):** the natural way to avoid a second traversal is to
assign labels lazily during the emission walk — which is also the easiest way to satisfy E. That
architecture produces post-order numbering and causes **B**. Fixing B requires re-introducing the
document-order pre-pass, and the participation filter has to be re-applied inside it, which is
exactly where **A** is lost. So E-the-easy-way causes B, and fixing B re-exposes A.

**Correction from reproduction:** the design originally claimed the definition block would inherit a
blockquote's `> ` prefix. It does NOT — the prefix stack is empty by end-of-walk, so that claim was a
guess and is withdrawn. The reproduced form of E is wrap-buffer corruption at `width > 0`, which is
strictly better misdirection anyway.

## 11b. Cross-product matrix (F-10)

| | unique target | duplicate target |
|---|---|---|
| **link** | baseline numbering | dedup to one label |
| **image** | `![alt][N]` | ← off-diagonal: image duplicating a LINK's target shares that label |
| **autolink** | excluded, no label | ← off-diagonal: autolink whose URL equals a later link's dest — the link still gets its own label |

Both off-diagonal cells get tests; both fail by over-firing (an extra label), the misdirecting shape.

## 12. Tier + category

- **Tier:** Olympus.
- **Category:** `feature-request` (title verb is Add; net-new public option).

## 13. Predicted pass rate

10-25%. Reasoning: trap #1 is a single ordering insight that a thorough agent CAN get, keeping it
solvable; traps #2-4 are independent discriminators that a passing run must also clear. The maintainer
independently rates the capability's edge cases as hard, which is corroborating evidence, not proof.

## 14. Quality gate

- [x] Repo understanding: architecture, 3 renderers over one AST, tests in `src/tests/`, template
      test file identified
- [x] Phase 2 run: no PR implements reference-style rendering (searched `reference link`,
      `footnote-style`, `wrap`, `line width`, `commonmark render`, all states); issue #740 carries a
      maintainer comment WELCOMING the feature with no published design
- [x] Maintainer philosophy: explicitly positive, Gate 8 clear
- [x] Canonical form fully specified (10 rules)
- [x] Traps on different axes, 1-3 interdependent, lead trap misdirecting
- [x] Cross-product matrix filled, both off-diagonal cells tested
- [x] LOC clears the floor with buffer (~270 meaningful vs 200 floor)
- [ ] **OWED:** trap reproduction (write the natural-but-wrong impl, confirm the misdirecting symptom)
- [ ] **OWED:** naive-agent benchmark + skeleton probe
- [ ] **OWED:** Docker validation — NO local Docker on this workstation; static check only, carried to
      the platform run

## Why this is not a duplicate

Closest prior art is our accepted `pulldown-cmark-gfm-autolinks` and in-flight
`pulldown-cmark-abbreviations`. Both are PARSING extensions that add syntax recognition to a Rust
CommonMark parser. This is a RENDERING capability with no parser change at all: it adds a
document-global output phase to a streaming writer. Different subsystem, different trap family
(sequence assignment + output-path machinery vs parse-time architecture), different repo. The
markdown-domain overlap is real and is the reason the renderer surface was chosen over comrak's
extension surface, which WOULD have been derivative.

Predicted iteration cycles: 2-3.
