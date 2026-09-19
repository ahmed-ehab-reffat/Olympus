# DESIGN — scriggo: contextual autoescaping inside HTML attribute values

Repo: `open2b/scriggo` (BSD-3-Clause, 575 stars, Go)
Base commit: `2f437fb8222e48af03cf4087794b05a23316b07a`
Hunt dossier: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-16-C.md`

## 1. Title

Add CSS and JavaScript escaping contexts inside HTML attribute values

## 2. Shape classification

**O-Pipeline-hard.** A new context axis is threaded through an existing four-stage pipeline
(lexer context machine -> AST context constant -> emitter -> runtime show dispatch), and the
escaper composition at the end is an algorithm the repo does not already contain in any form. It
is not O-Composite-add: nothing new is added to the public API surface, the whole change lands
inside machinery that already exists and already has a correct sibling path.

Target band: 10-25% pass. Floor risk is low (the element path is a working oracle in-repo), ceiling
risk is controlled by the composition-order trap and the typed-value cross-stage drop.

## 3. The capability gap (verified on base at the commit above)

scriggo's autoescaper tracks 13 contexts in `internal/compiler/lexer.go` and dispatches one
`showIn*` function per context in `internal/runtime/renderer.go`. It enters CSS context inside a
`<style>` ELEMENT and JS context inside a `<script>` ELEMENT, tracks string sub-contexts in both,
and (merged PR #998) tracks JS comments. It has a developed URL lane keyed on attribute name via
`containsURL(tag, attr)`.

It has **no sub-format dispatch on attribute name.** Every non-URL attribute value becomes
`ContextQuotedAttr` or `ContextUnquotedAttr`, which applies HTML entity escaping only.

Measured live at base:

| Template | Value | Actual output |
|---|---|---|
| `<style>p{color: {{ v }} }</style>` | `red; background:url(x)` | `"red\3b  background\3aurl\28x\29 "` |
| `<p style="color: {{ v }}">` | `red; background:url(x)` | `red; background:url(x)` |
| `<button onclick="f('{{ v }}')">` | `'); alert(1); //` | `f('&#39;); alert(1); //')` |

Row 1 vs row 2 is a dual-path inconsistency: the same expression is CSS-escaped through the element
path and not through the attribute path. Row 3 is an injection, because the HTML parser decodes
`&#39;` back to `'` before the JS parser sees the handler body.

HTML comments are NOT a gap here (`-->` is already escaped to `--&gt;`), and are deliberately out
of scope.

## 4. Public API surface

No new exported function. Eight new `ast.Context` constants are appended AFTER
`ContextSpacesCodeBlock` (reference names `ContextCSSQuotedAttr`, `ContextCSSUnquotedAttr`,
`ContextCSSStringQuotedAttr`, `ContextCSSStringUnquotedAttr`, and the four JS twins). Tests never
name them: every assertion goes through `scriggo.BuildTemplate` + `Template.Run`, so an agent is free
to pick any representation (fewer contexts plus a flag bit is equally valid).

Why they must be APPENDED (measured in code, not stated in meta): contexts 0-5 ARE the `ast.Format`
values (`ast.Context(format)` in `lexer.go:43`, `ast.Format(ctx)` in `emitter_statements.go`), and the
parser/emitter reject `raw` / `macro` / `using` / optimized macro shows with `tok.ctx > ContextMarkdown`.

## 5. Canonical output form (MEASURED on the reference, byte-exact)

| Template | Value | Output |
|---|---|---|
| `<p style="color: {{ a }}">` | `red; x` | `<p style="color: &#34;red\3b  x&#34;">` |
| `<p style={{ a }}>` | `a b` | `<p style=&#34;a&#32;b&#34;>` |
| `<p style="font-family: '{{ a }}'">` | `x'y&` | `<p style="font-family: 'x\27y\26 '">` |
| `<a onclick="f({{ a }})">` | `a<b"c` | `<a onclick="f(&#34;a\u003cb\&#34;c&#34;)">` |
| `<a onclick="f('{{ a }}')">` | `'); alert(1); //` | `<a onclick="f('\u0027); alert(1); //')">` |
| `<a onclick="{{ a }}">` | `native.JS(g("x") && y)` | `<a onclick="g(&#34;x&#34;) &amp;&amp; y">` |
| `<a onclick="f(&quot;{{ a }}&quot;)">` | `x"y` | `<a onclick="f(&quot;x\&#34;y&quot;)">` |

(Rows 4, 5 and 7 contain literal backslash escapes. The previous version of this table lost them in a
tool round-trip; verify with `cat -A` after any edit.)

Composition = element escaper writes through a streaming attribute-escaping writer
(`attributeEscape(..., escapeEntities=true, quoted)`). Reverse order is observable: attribute-first
turns `"` into `&#34;` and the JS escaper then rewrites `&` to `&`.

## 6. Requirements stated in meta.md

1. `style` -> CSS; `on` + >=1 char -> JS; case-insensitive; every other attribute unchanged.
2. Inner escaping identical to the element at the same point, then ordinary attribute escaping
   (quoted/unquoted).
3. `native.CSS` / `native.JS` and their stringers skip only the inner step; `native.HTML` is not
   trusted (it is shown as a CSS/JS string).
4. Types not showable in the element are not showable in the attribute: BUILD fails.
5. Quotes open/close string sub-contexts; quote character references (`&quot;`, `&apos;`, decimal,
   hex) count as quotes; backslash-quote keeps the string open; JS comments skipped; the attribute's
   own delimiter always ends the attribute.
6. HTML and Markdown templates.

Codebase-inferable: none beyond "same as the element", which is the stated oracle.

## 7. File footprint (core slice, measured)

| File | Raw | human-effective |
|---|---|---|
| `internal/compiler/lexer.go` | 188 | 134 |
| `ast/ast.go` | 24 | 24 |
| `internal/runtime/escapers.go` | 30 | 16 |
| `internal/runtime/renderer.go` | 13 | 13 |
| `internal/compiler/checker_statements.go` | 7 | 7 |
| `internal/compiler/builder.go` (+ runtime decode) | 1 | 1 |
| **Total** | **263** | **195** |

195 is BELOW the 250-300 design target. Deliberate: Step 4b core-slice precheck first. Depth to add
only after a clean dedupe verdict, see section 16.

## 8. Solution outline (as built)

- `attributeContext(attr, quoted)` - name -> context dispatch.
- `scanAttrQuote(src)` - literal or character-reference quote, returns quote + byte length.
- `isQuotedAttrContext`, `stringAttrContext`, `unstringAttrContext` - state transitions.
- Lexer: one new `case` group; attribute end is checked FIRST, including from inside a string.
- `attributeWriter` (escapers.go) - `strWriter` that attribute-escapes everything written through it;
  the renderer runs the unchanged `showInCSS` / `showInCSSString` / `showInJS` / `showInJSString`
  over it, which gives typed-value bypass for free.
- `checkShow`: CSS attr contexts join the CSS arm, JS attr contexts the JS arm, string attr contexts
  the string arm, with the `[]byte` exception extended to the CSS-string attribute contexts only.
- Context mask widened from `0b00001111` to `0b00111111` in BOTH `compiler/builder.go` and
  `runtime/renderer.go`.

## 9. Tests (core slice)

`test/misc/attribute_contexts_ed8cbb_test.go`, build tag `attrctx_ed8cbb`, 6 functions, all F2P on
base, all through the public API: style, event handler (incl. `on` / `data-onclick` / `data-style`
guards and element-path guards folded in so no function passes on base), quote character
references, string state (backslash, JS comment, attribute ending inside a string, unquoted
handler followed by another attribute), Markdown, show types (base64 `[]byte` allowed in CSS string
attr and JS attr; build error for chan in CSS/JS attr and `[]byte` in JS string attr).

## 10. Trap matrix (revised against the real code)

| # | Trap | F-id / class | Axis | Interdependent with | Evidence |
|---|---|---|---|---|---|
| T1 | 4-bit context mask: contexts >= 16 silently wrap (JS attr contexts decode as `ContextCSS`, `ContextJS`...) | F-9 cross-stage drop, S4 machinery-riding | runtime encoding | T3 (more contexts = more wrap) | Reverting the mask on the reference: onclick output becomes `f("a\3c b\22c")`, CSS-escaped. No panic, no error, points at the escapers. Two copies of the decoder ("Keep in sync"). |
| T2 | Context ordering: constants inserted next to their element siblings shift the Format==Context identity and the `> ContextMarkdown` gates | S3 baseline-preservation through shared chokepoint | declaration order | T1 | Base suite breaks broadly; a smart agent recovers, so a message-count driver more than a kill. |
| T3 | String sub-context vs attribute delimiter, incl. entity-encoded quotes | A-tier determination-channel seam | lexer state | T4 | `onclick="f(&quot;{{v}}&quot;)"` and `f('x" title="{{b}}"` rows. |
| T4 | checkShow parity (`[]byte` allowed in CSS string, not JS string) | F-10 cross-product cell | static types | T3 (which arm depends on string state) | Grouping the four string attr contexts with the CSS-string exception or without it fails one side. |
| T5 | Unquoted variant escape set | exact-fit | quoting | - | `style={{a}}` -> `&#32;`. |

Dropped from the old design: "typed-value bypass skips only the inner stage" (free once an agent
composes through a writer) and "`on` prefix naive reading" (`online` IS a handler under the stated rule).

## 11. F-10 cells

| | CSS attr | CSS string attr | JS attr | JS string attr |
|---|---|---|---|---|
| string | style row 1 | style row 3 | handler row 1 | handler row 2 |
| `[]byte` | (to add) | allowed, base64 | allowed, quoted base64 | build error |
| typed inner | `native.CSS` | (to add) | `native.JS` | (to add) |
| `native.HTML` | shown as CSS string | (to add) | (to add) | (to add) |
| unquoted | row 2 | (to add) | handler row 3 | string-state row 4 |

## 12. Tier and category

Olympus. Category `feature-request`. Language Go. Docker Pattern B on
`olympus-base-go`, `go mod download` warmed at build time so the container runs with
`--network none`.

## 13. Predicted pass rate

20-35% for the core slice. T1 is the likely decider: any agent adding >= 3 contexts crosses 16 and
must find the mask; agents who only run their CSS cases may never see it. Harden with section 16 depth
after the precheck, not before.

## 14. Quality gates

- [x] Baseline green and deterministic: `go test ./...` 3x identical, ~5s
- [x] Exclusivity: PR/issue search on `style attribute`, `event handler`, `onclick`, `escaping`,
      `autoescaping`, `attribute context`, `srcdoc` — nothing claims the lane; merged PR #998
      touches `lexer.go` but implements none of this machinery
- [x] Maintainer philosophy: no decline; issue #971 shows contexts are not even documented
- [x] Repo quota: 1 prior pick, under 6
- [x] Derivative: no corpus submission touches contextual escaping; the contested scriggo
      language-core lane is deliberately avoided
- [x] Absorption: `internal/compiler` is from-scratch; no stdlib does this composition
- [ ] Comment convention: scriggo DOES doc-comment its free functions concisely. Match that exact
      density, no inline body comments, no TODO/NOTE
- [ ] Effective LOC >= 200 via the hook on the final `solution.patch`
- [ ] test.sh mode 100755, JUnit via `go test -v | go-junit-report`
- [ ] 3x flakiness on base and new
- [ ] Mutation kill check: five mutations, each killed by >= 1 test
- [ ] Docker build + run as uid 1000 with `--network none`
- [ ] FP check after the batch

## 15. Known deviations, recorded

- **Requirement 7 (CI runs its own tests) is NOT met.** scriggo's only workflow is
  `run-go-releaser.yml`. The gate's rationale is a moving baseline; here `go.sum` hash-pins every
  dependency and the suite was measured green, deterministic and 5 seconds locally on three runs.
  Unlike causal-learn, there are no unpinned deps, no pre-existing failures in the target lane, and
  no long-running test.
- **Dormancy.** Last upstream commit 2026-03-17, inside the 12-month activity window but six months
  cold, against a 575-star count. Both are marginal signals for the platform's active-maintenance
  precheck.
- **⚠️ Responsible disclosure is an OPEN USER DECISION.** The `onclick` behaviour is an unreported
  XSS vector in a live template engine that ships a `SECURITY.md`. Reporting it upstream would very
  likely get it fixed and kill this pick. No report has been sent; this is the user's call.

## 16. Status and next steps (2026-09-17)

- Core slice built, patches generated, clean-room validated: base 1063 testcases / 0 failures x3,
  new 6 / 0 failures x3 with solution, 6 / 6 failing without. Existing suite untouched.
- Dockerfile needs `chmod -R a+rwX /app` + `safe.directory`: as uid 1000 the image was read-only and
  `test/compare` Test_errorcheck failed writing its built binary.
- **NEXT: Step 4b platform precheck on this slice.** Only after a clean dedupe verdict:
  fill the F-10 grid, add macro/`render` shows of CSS/JS formats inside attributes, and add depth to
  clear 250+ human-effective (candidate: a `srcdoc` HTML-in-attribute lane, which nests the attribute
  writer and stresses T1 further; decide after the verdict).
