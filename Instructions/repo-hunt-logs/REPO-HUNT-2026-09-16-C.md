# Repo hunt 2026-09-16-C — recast killed on maintainer philosophy; scriggo template escaping locked

Continues 2026-09-16 and -16-B. Standing directive: find a NEW authorable problem, do not stop.

## 1. benjamn/recast — KILLED (maintainer-declined lane)

recast cleared every mechanical and competitive gate:

| Gate | Result |
|---|---|
| Licence / stars / language | MIT, 5252, TypeScript |
| Activity | 53 commits/12mo, latest 2026-08-21 |
| Capability commits | ZERO — `fix:` / `perf:` / release chores only |
| Open PRs | dependabot + two features that miss the kernel |
| Competitor accounts | none |
| Dependencies | pure JS (`ast-types`, `esprima`, `source-map`, `tiny-invariant`) |
| Baseline suite | `npm run build && npm run mocha` -> **792 passing, 0 failing, 1 pending, ~3s, identical on 3 runs** |
| Corpus collision | none |

The verified capability gap was in `lib/patcher.ts`: `findArrayReprints` matches array children
strictly by index and returns `false` outright when the length changed, so inserting, removing or
reordering one element reprints the whole enclosing array and destroys formatting for every
untouched sibling. No alignment machinery exists anywhere in `lib/`.

**Kill reason — SIX-CHECK item 3 (maintainer philosophy).**
[benjamn/recast#429 "Preserve Array Indentation"](https://github.com/benjamn/recast/issues/429) is
CLOSED by the maintainer with:

> This is working as designed, per my previous comment. Inserting new elements into a sequence like
> an `ArrayExpression` or `ObjectExpression` requires rerunning the pretty-printer for the parent
> node, since the parent is responsible for printing syntax like brackets, braces, and commas [...]
> There's no reasonable way to print just the inserted child plus a leading or trailing comma,
> without making the child's pretty-printer implementation partly responsible for the parent's
> syntax.

That is a by-design decline of the exact capability, with a pointer to #226 as the alternative.
Same class as `dasel-multi-file`. No redesign inside recast survives it either: the rest of the
repo is one large `genericPrintNoParens` dispatch (missing-arm death class) plus a sourcemap lane
the maintainer consumed in PR #1433 (2026-07).

**Method note (new).** The green-baseline gate and the zero-capability-commits filter both passed
on a repo whose only deep lane was already refused in the tracker. **Run the closed-issue
philosophy scan on the LANE before measuring the baseline**, not after — the baseline build cost
more than the two `gh issue view` calls that killed it.

## 2. Cold-band re-triage — five candidates, all dead or weak

| Repo | Verdict |
|---|---|
| ergogen/ergogen | Already in `SATURATED-REPOS.md` — single-maintainer capability stream |
| tywalch/electrodb | `anatolzak` shipping features continuously (abortSignal, returnOnConditionCheckFailure, client option) — capability-consuming |
| lusingander/serie | Solo maintainer mid-build on graph + search; `ChrisJr404` (recorded signature account) present; `Remove lib target` (#164) kills library-level testability |
| kriszyp/msgpackr | Solo maintainer actively rebuilding the struct/record lane |
| stripe/skycfg | 6 commits/12mo, 2 of them CI; thin binding over Starlark + protobuf reflection = absorption |
| felt/tippecanoe | Maintainer `e-n-f` holds 12 open PRs blanketing the feature space |
| Mojang/DataFixerUpper | 12 open PRs incl. feature diffs (TupleCodec, collector codecs, nullable fields) — stale-PR-blanketed |

## 3. open2b/scriggo — PICK (RANK 1)

Reached via Stage 0-bis (proven-repo pool), not a cold sweep.

| Gate | Result |
|---|---|
| Licence / stars / language | BSD-3-Clause, 575, Go |
| Activity | latest commit 2026-03-17 (within 12mo) |
| Capability commits, 12mo | **ZERO** — panic fixes, dep bumps, `cmd/scriggo` help text, CI pins |
| Open PRs | 3, all by maintainer `gazerro`, all small |
| Outside contributors | none in the window |
| Competitor accounts | none |
| Dependencies | pure Go; `go.sum`-pinned (goldmark, x/mod, x/tools, yaml.v3) |
| Absorption | `internal/compiler` is a from-scratch lexer/parser/checker/emitter + register VM; `go/parser` and `go/types` appear only in `cmd/scriggo` codegen |
| Baseline suite | `go test ./...` -> **green, ~5s, identical on 3 runs** |
| Repo quota | 1 prior pick (`rejected/scriggo-range-iterators`), well under 6 |

### 3a. The two gates scriggo does NOT clear cleanly, and the mitigation

- **Requirement 7 (CI runs its own tests).** scriggo's only workflow is `run-go-releaser.yml`.
  There is no test-running workflow. The gate's stated rationale is "the baseline is a moving
  target" — that rationale is answered here by `go.sum`, which hash-pins every dependency, and by
  a locally measured green, deterministic, 5-second suite. This is the causal-learn gate, but
  causal-learn ALSO had unpinned scientific deps, 5 deterministic failures inside the target lane,
  and a 600s test. scriggo has none of those. Proceeding, deviation recorded.
- **Dormancy + a 575-star count** are two marginal signals against the platform's
  active-maintenance precheck. 2026-03-17 is inside the 12-month window, so it passes as written.

### 3b. Lane selection — the language core is contested, the template engine is not

`SATURATED-REPOS.md` already records the platform's own derivative verdict on scriggo:

> Any missing-Go-language-feature pick in scriggo (interfaces/methods/generics next) is HIGH
> derivative risk [...] Scriggo's TEMPLATE engine (auto-escaping contexts / render-show pipeline /
> macro-render / markdown-conversion) is a DIFFERENT surface and may be open.

That is confirmed from the other direction by scriggo's own conformance skip list, which is a
**published gap matrix with issue numbers**:

| Skip reason | Count | Issue |
|---|---|---|
| method declaration / definition | 62 | #194, #458 |
| interface definition | 28 | #218 |
| import "unsafe" | 18 | #288 |
| import "runtime" | 8 | #524 |

Every deep language-core gap is publicly filed and maintainer-owned. The template engine has no
such list; issue #971 ("Write documentation about contexts in templates", OPEN, 0 comments) shows
the context behaviour is not even documented.

### 3c. The verified capability gap — attribute sub-contexts in the autoescaper

scriggo's contextual autoescaper tracks 13 contexts in the lexer and dispatches per-context
`showIn*` renderers. It correctly enters CSS context inside a `<style>` ELEMENT and JS context
inside a `<script>` ELEMENT, including a JS-string sub-context and (since merged PR #998) JS
comment tracking. It has a developed URL lane (path vs query escaping, `srcset` lists).

It has **no sub-format dispatch on attribute NAME**. Measured on a live render at base commit:

| Template | Value | Output |
|---|---|---|
| `<style>p{color: {{ v }} }</style>` | `red; background:url(x)` | `"red\3b  background\3aurl\28x\29 "` (correct) |
| `<p style="color: {{ v }}">` | `red; background:url(x)` | `red; background:url(x)` (raw, no CSS escaping) |
| `<button onclick="f('{{ v }}')">` | `'); alert(1); //` | `f('&#39;); alert(1); //')` |

The second row is a clean dual-path inconsistency: the same value is CSS-escaped through the
element path and not through the attribute path. The third row is a real injection, because the
HTML parser decodes `&#39;` back to `'` before the JS parser ever sees the handler body.

HTML comments are NOT a gap (`-->` is correctly escaped), so they stay out of scope.

**Why this carries an Olympus problem.** The fix is a three-level escaper composition that has no
precedent in the repo: inner format escaper (JS-string or CSS) -> attribute escaper (quoted or
unquoted) -> HTML entity rules. Only one composition order is correct, the failing assertion does
not name it, and a `native.JS` / `native.CSS` typed value must skip the INNER escaper while still
taking the OUTER one, which is an F-9 cross-stage drop riding every capability at once. The
element path is a live S5 dual-path oracle already in the repo. The trap surface is an F-10 cross
product of format types against the new contexts, quoted against unquoted.

Sketched footprint: `internal/compiler/lexer.go` ~140 raw, `ast/ast.go` ~40,
`internal/runtime/renderer.go` ~130, `internal/runtime/escapers.go` ~120,
parser/emitter context plumbing ~70. Roughly 500 raw / 330-360 human-effective across 5+ files,
clearing the 200 floor with margin.

### 3d. Exclusivity and philosophy — CLEAN

Searched PRs and issues, all states, for `style attribute`, `event handler`, `onclick`,
`escaping`, `autoescaping`, `attribute context`, `comment`, `srcdoc`. Nothing claims the lane.
The nearest hit is merged PR #998, which adds JS comment state inside `<script>` and touches
`lexer.go` but implements none of the attribute sub-context machinery. The prior declined scriggo
pick (`scriggo-dynamic-render`) is a different feature. No corpus submission anywhere touches
contextual escaping.

### 3e. ⚠️ Open question for the user — responsible disclosure

The `onclick` row above is an unreported XSS vector in a live 575-star template engine that ships
a `SECURITY.md`. Authoring a problem on it and disclosing it upstream pull in opposite directions:
a report would very likely get it fixed and kill the pick. This is the user's call, not the
author's, and no report has been sent.
